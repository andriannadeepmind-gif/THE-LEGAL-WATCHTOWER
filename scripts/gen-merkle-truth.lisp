#!/usr/bin/env sbcl --script
;;;; scripts/gen-merkle-truth.lisp
;;;; ============================================================================
;;;; MERKLE-SINGLE-TRUTH — Ο ΓΕΝΝΗΤΟΡΑΣ ΤΗΣ ΜΙΑΣ ΑΛΗΘΕΙΑΣ
;;;; ============================================================================
;;;; Διαβάζει τη ΜΙΑ κανονική προδιαγραφή (deployment/verify/merkle-profile.sexp)
;;;; και ΠΑΡΑΓΕΙ:
;;;;   1. τη Merkle ενότητα του deployment/PROOF-CARRYING-LAW.md
;;;;   2. την αντίστοιχη ενότητα του deployment/verify/README.md
;;;;   3. τα κοινά golden vectors (deployment/verify/vectors/merkle/vectors.json)
;;;;
;;;; ΤΙ ΔΕΝ ΠΑΡΑΓΕΙ: κώδικα. Οι τρεις υλοποιήσεις (Lisp/Python/Node) μένουν
;;;; ΑΝΕΞΑΡΤΗΤΕΣ — κοινός implementation generator θα κατέργει την N-version
;;;; άμυνα. Κοινά είναι ΜΟΝΟ τα δεδομένα.
;;;;
;;;; ΙΔΙΟΠΑΘΕΙΑ (idempotence): δεύτερη εκτέλεση ⇒ byte-ταυτόσημη έξοδος. Το
;;;; build gate το επιβάλλει.
;;;;
;;;;   sbcl --script scripts/gen-merkle-truth.lisp [--check]
;;;;     (χωρίς σημαία) γράφει· --check αποτυγχάνει αν τα committed διαφέρουν.
;;;; ============================================================================

(require :asdf) (require :sb-posix)

(defvar *root* (uiop:getcwd))
(setf asdf:*central-registry*
      (append (list *root*) (directory (merge-pathnames "systems/*/" *root*))))
(asdf:initialize-source-registry
 `(:source-registry (:tree ,(merge-pathnames "third-party/" *root*)) :inherit-configuration))
(locally (declare (sb-ext:muffle-conditions sb-ext:compiler-note style-warning warning))
  (handler-bind ((warning #'muffle-warning))
    (asdf:load-system :alexandria)
    (asdf:load-system :log4cl)
    (asdf:load-system :orchestrator-core-runtime)))

(defpackage :merkle-truth (:use :cl))
(in-package :merkle-truth)

(defvar *check-only* (member "--check" (cdr sb-ext:*posix-argv*) :test #'string=))
(defvar *root* (symbol-value (intern "*ROOT*" :cl-user)))
(defun repo (rel) (merge-pathnames rel *root*))

(defvar *profile*
  (multiple-value-bind (form status)
      (orchestrator.safe-read:read-data-file (repo "deployment/verify/merkle-profile.sexp"))
    (unless (eq status :ok)
      (format *error-output* "~&::error::merkle-profile.sexp ΜΗ ΑΝΑΓΝΩΣΙΜΟ (~S)~%" status)
      (sb-ext:quit :unix-status 1))
    form)
  "Η ΜΙΑ κανονική πηγή — διαβασμένη από τη ΜΙΑ έδρα ασφαλούς ανάγνωσης, fail-closed.")

(defun pget (key) (getf (cdr *profile*) key))

(unless (eq (car *profile*) :lawmax-merkle-profile/1)
  (format *error-output* "~&::error::άγνωστο σχήμα profile: ~S~%" (car *profile*))
  (sb-ext:quit :unix-status 1))

;;; ── βοηθοί bytes/hex (η ΑΥΘΕΝΤΙΑ των vectors είναι τα hex bytes) ──
(defun hex->bytes (hex)
  (if (zerop (length hex))
      (make-array 0 :element-type '(unsigned-byte 8))
      (ironclad:hex-string-to-byte-array hex)))

(defun leaf-of-hex (hex) (orchestrator.merkle:hash-leaf-bytes (hex->bytes hex)))

(defun tree-leaf-hex (i)
  "Ο κανόνας του profile: δεδομένα φύλλου i = ASCII bytes του δεκαδικού i."
  (string-downcase
   (ironclad:byte-array-to-hex-string
    (babel:string-to-octets (format nil "~D" i) :encoding :utf-8))))

(defun tree-leaves (n) (loop for i below n collect (leaf-of-hex (tree-leaf-hex i))))

;;; ============================================================================
;;; 0. ΑΝΕΞΑΡΤΗΤΟ ORACLE — ΣΠΑΕΙ ΤΗΝ ΚΥΚΛΙΚΟΤΗΤΑ
;;; ============================================================================
;;; ΕΥΡΗΜΑ ΚΡΙΤΗ (ΚΡΙΣΙΜΟ): αν τα golden vectors παράγονται ΜΟΝΟ από την
;;; production έδρα, τότε αποδεικνύεται «Python ≡ Node ≡ σημερινή Lisp» και ΟΧΙ
;;; «Lisp ≡ RFC 9162». Κοινό σφάλμα της έδρας θα εγγραφόταν ως «χρυσή αλήθεια».
;;;
;;; ΕΥΡΗΜΑ ΚΡΙΤΗ #2 (η πρώτη θεραπεία ήταν ΑΝΕΠΑΡΚΗΣ): (α) το πρώτο oracle ήταν
;;; η ΙΔΙΑ top-down αναδρομή με το ίδιο split-k — δεύτερο ΑΝΤΙΓΡΑΦΟ, όχι δεύτερη
;;; υλοποίηση· (β) inclusion paths και consistency proofs έβγαιναν ΑΠΟΚΛΕΙΣΤΙΚΑ
;;; από την production έδρα — μόνο οι ρίζες διασταυρώνονταν· (γ) τα πεδία
;;; κρυπτογραφίας του profile (:leaf-prefix-byte κ.λπ.) ήταν ΑΔΡΑΝΗ — ο oracle
;;; hardcode-αρε 0x00/0x01/SHA-256, άρα profile drift δεν κοκκίνιζε τίποτα.
;;;
;;; ΘΕΡΑΠΕΙΑ (αυτή η μορφή):
;;;   • Ο oracle MTH είναι ΡΟΪΚΟΣ (streaming): στοίβα τέλειων υποδέντρων,
;;;     συγχώνευση ισομεγεθών, τελική δίπλωση από δεξιά. ΚΑΜΙΑ συνάρτηση split,
;;;     καμία αναδρομή σε ranges — δομικά ΞΕΝΟΣ προς την έδρα, μαθηματικά
;;;     ταυτόσημος με τον ορισμό MTH του RFC 9162 §2.1.1.
;;;   • PATH (RFC 9162 §2.1.3.1) και SUBPROOF (§2.1.4.1) ΜΕΤΑΓΡΑΦΟΝΤΑΙ από το
;;;     πρότυπο με δικά τους πρωτόγονα (oracle-node/oracle-mth, bit-αριθμητική
;;;     για το k αντί για τον βρόχο της έδρας)· ΚΑΘΕ εκπεμπόμενο path/proof
;;;     διασταυρώνεται ΣΤΟΙΧΕΙΟ-ΠΡΟΣ-ΣΤΟΙΧΕΙΟ, και κάθε path ΞΑΝΑΔΙΠΛΩΝΕΤΑΙ
;;;     ως τη ρίζα με τα πρωτόγονα του oracle.
;;;   • ΟΛΕΣ οι κρυπτο-παράμετροι (prefix bytes, αλγόριθμος, μορφή αναπαράστασης)
;;;     ΔΙΑΒΑΖΟΝΤΑΙ από το profile — και οι σταθερές της έδρας ΕΛΕΓΧΟΝΤΑΙ ρητά
;;;     απέναντί τους. Αλλαγή ΜΟΝΟ του profile ⇒ ασυμφωνία ⇒ ΑΒΟΡΤ, ποτέ
;;;     σιωπηλά πράσινο.
;;; Κάθε τιμή που εκπέμπεται ΠΡΕΠΕΙ να συμφωνεί ΚΑΙ ΜΕ ΤΑ ΔΥΟ. Διαφωνία ⇒ ΑΒΟΡΤ.
;;;
;;; ΤΙΜΙΟ ΟΡΙΟ (αμετάβλητο): δεν κατέστη δυνατή η λήψη ΔΗΜΟΣΙΕΥΜΕΝΟΥ εξωτερικού
;;; συνόλου vectors — η πολιτική δικτύου απορρίπτει τα www.rfc-editor.org κ.λπ.
;;; (403). Άγκυρα: (α) δημοσιευμένες σταθερές (FIPS 180-4 KAT· RFC 9162 MTH({}))
;;; και (β) η μεταγραφή του προτύπου. ΔΕΝ ισχυρίζομαι «τρίτο σύνολο vectors».
;;; Η μεταγραφή ΜΟΙΡΑΖΕΤΑΙ συγγραφέα με την έδρα — αυτό δεν αναιρείται με
;;; ισχυρισμούς, μόνο με πραγματικά εξωτερικό υλικό όταν υπάρξει δίκτυο.

;;; ── ΚΡΥΠΤΟ-ΠΑΡΑΜΕΤΡΟΙ: ΔΙΑΒΑΖΟΝΤΑΙ από το profile, ΔΕΝ hardcode-άρονται ──
(defun %profile-die (fmt &rest args)
  (format *error-output* "~&::error::~?~%" fmt args)
  (sb-ext:quit :unix-status 1))

(defun %parse-hex-byte (s what)
  (unless (and (stringp s) (= (length s) 4)
               (string= "0x" (subseq s 0 2)))
    (%profile-die "profile ~A: αναμενόταν \"0xNN\", βρέθηκε ~S" what s))
  (parse-integer s :start 2 :radix 16))

(defparameter *o-leaf-prefix-byte*
  (%parse-hex-byte (pget :leaf-prefix-byte) ":leaf-prefix-byte"))
(defparameter *o-node-prefix-byte*
  (%parse-hex-byte (pget :node-prefix-byte) ":node-prefix-byte"))
(defparameter *o-digest*
  (let ((alg (pget :hash-algorithm)))
    ;; ΜΟΝΟ ο δηλωμένος αλγόριθμος του profile v1. Άγνωστη τιμή = ΑΒΟΡΤ
    ;; (fail-closed), ΟΧΙ σιωπηλή συνέχεια με ό,τι έτυχε να είναι hardcoded.
    (cond ((equal alg "SHA-256") :sha256)
          (t (%profile-die "profile :hash-algorithm ~S ΔΕΝ υποστηρίζεται από τον generator — καμία σιωπηλή συνέχεια" alg)))))
(defparameter *o-hash-prefix*
  (let* ((rep (pget :hash-representation))
         (lt (and (stringp rep) (position #\< rep))))
    (unless lt (%profile-die "profile :hash-representation ~S: αναμενόταν \"prefix:<...>\"" rep))
    (subseq rep 0 lt)))          ; "sha256:"

(defun %o-sha (bytes)
  "digest → prefix:hex — ΟΛΑ από το profile (καμία συνάρτηση/σταθερά της έδρας)."
  (concatenate 'string *o-hash-prefix*
               (string-downcase (ironclad:byte-array-to-hex-string
                                 (ironclad:digest-sequence *o-digest* bytes)))))

(defun %o-raw (h) (ironclad:hex-string-to-byte-array (subseq h (length *o-hash-prefix*))))

(defun oracle-leaf (bytes)
  "RFC 9162 §2.1.1: MTH({d(0)}) = HASH(leaf-prefix || d(0)) — prefix από profile."
  (%o-sha (concatenate '(vector (unsigned-byte 8))
                       (vector *o-leaf-prefix-byte*) bytes)))

(defun oracle-node (l r)
  "RFC 9162 §2.1.1: εσωτερικός κόμβος = HASH(node-prefix || left || right)."
  (%o-sha (concatenate '(vector (unsigned-byte 8))
                       (vector *o-node-prefix-byte*) (%o-raw l) (%o-raw r))))

(defun oracle-mth (leaf-hashes)
  "RFC 9162 §2.1.1 MTH — ΡΟΪΚΗ υλοποίηση: κάθε φύλλο ωθείται σε στοίβα τέλειων
   υποδέντρων· δύο κορυφαία ΙΣΟΜΕΓΕΘΗ συγχωνεύονται αμέσως· στο τέλος τα
   εναπομείναντα διπλώνονται από δεξιά προς αριστερά. ΚΑΜΙΑ συνάρτηση split,
   καμία αναδρομή — δομικά ΞΕΝΗ προς την top-down έδρα. Η ισοδυναμία με τον
   ορισμό MTH: η στοίβα κρατά πάντα τη δυαδική ανάλυση του πλήθους που έχει
   διαβαστεί, που είναι ακριβώς τα υποδέντρα του unbalanced split."
  (let ((n (length leaf-hashes)))
    (if (zerop n)
        (%o-sha (make-array 0 :element-type '(unsigned-byte 8)))
        (let ((stack '()))               ; στοίβα (μέγεθος . hash), κορυφή = δεξιότερο
          (dolist (lh (coerce leaf-hashes 'list))
            (push (cons 1 lh) stack)
            (loop while (and (rest stack)
                             (= (car (first stack)) (car (second stack))))
                  do (let ((r (pop stack)) (l (pop stack)))
                       (push (cons (* 2 (car l)) (oracle-node (cdr l) (cdr r)))
                             stack))))
          (let ((acc (cdr (pop stack))))
            (loop while stack
                  do (setf acc (oracle-node (cdr (pop stack)) acc)))
            acc)))))

;;; ── PATH / SUBPROOF: μεταγραφή RFC 9162 §2.1.3.1 / §2.1.4.1 ──
(defun %o-k (n)
  "Η μεγαλύτερη δύναμη του 2 ΑΥΣΤΗΡΑ < n (n ≥ 2) — με bit-αριθμητική
   (integer-length), ΟΧΙ με τον πολλαπλασιαστικό βρόχο της έδρας."
  (ash 1 (1- (integer-length (1- n)))))

(defun %o-sub (v lo hi)
  (loop for i from lo below hi collect (aref v i)))

(defun oracle-path (leaves index)
  "RFC 9162 §2.1.3.1 PATH(m, D[n]) — μεταγραφή του ορισμού, φύλλο→ρίζα, με
   (side . hash) όπου side = η θέση του ΑΔΕΡΦΟΥ (ίδιο συμβόλαιο με την έδρα):
     m < k  ⇒ PATH(m, D[0:k]) : MTH(D[k:n])   — αδερφός ΔΕΞΙΑ
     m >= k ⇒ PATH(m-k, D[k:n]) : MTH(D[0:k]) — αδερφός ΑΡΙΣΤΕΡΑ"
  (let ((v (coerce leaves 'vector)))
    (labels ((path (m lo hi)
               (let ((n (- hi lo)))
                 (if (= n 1) '()
                     (let ((k (%o-k n)))
                       (if (< m k)
                           (append (path m lo (+ lo k))
                                   (list (cons :right (oracle-mth (%o-sub v (+ lo k) hi)))))
                           (append (path (- m k) (+ lo k) hi)
                                   (list (cons :left (oracle-mth (%o-sub v lo (+ lo k))))))))))))
      (path index 0 (length v)))))

(defun oracle-fold-path (leaf path)
  "Δίπλωση φύλλου→ρίζας με ΤΑ ΠΡΩΤΟΓΟΝΑ ΤΟΥ ORACLE — αποδεικνύει ότι το
   εκπεμπόμενο path πράγματι ΕΠΑΛΗΘΕΥΕΙ, όχι απλώς ότι δύο generators συμφωνούν."
  (let ((cur leaf))
    (dolist (step path cur)
      (setf cur (ecase (car step)
                  (:left  (oracle-node (cdr step) cur))
                  (:right (oracle-node cur (cdr step))))))))

(defun oracle-consistency (leaves m)
  "RFC 9162 §2.1.4.1 PROOF(m, D[n]) = SUBPROOF(m, D[n], true) — μεταγραφή:
     SUBPROOF(m, D[m], true)  = {}
     SUBPROOF(m, D[m], false) = {MTH(D[m])}
     m <= k ⇒ SUBPROOF(m, D[0:k], b) : MTH(D[k:n])
     m >  k ⇒ SUBPROOF(m-k, D[k:n], false) : MTH(D[0:k])"
  (let* ((v (coerce leaves 'vector)) (n (length v)))
    (labels ((mthr (lo hi) (oracle-mth (%o-sub v lo hi)))
             (subproof (m lo hi complete-p)
               (let ((n (- hi lo)))
                 (cond
                   ((and (= m n) complete-p) '())
                   ((= m n) (list (mthr lo hi)))
                   (t (let ((k (%o-k n)))
                        (if (<= m k)
                            (append (subproof m lo (+ lo k) complete-p)
                                    (list (mthr (+ lo k) hi)))
                            (append (subproof (- m k) (+ lo k) hi nil)
                                    (list (mthr lo (+ lo k)))))))))))
      (if (= m n) '() (subproof m 0 n t)))))

;;; ── Η ΕΔΡΑ ΕΛΕΓΧΕΤΑΙ ΑΠΕΝΑΝΤΙ ΣΤΟ PROFILE (τα πεδία ΔΕΝ είναι διακοσμητικά) ──
(defun assert-seat-matches-profile ()
  (unless (equalp orchestrator.merkle:+leaf-prefix+ (vector *o-leaf-prefix-byte*))
    (%profile-die "ΑΣΥΜΦΩΝΙΑ ΕΔΡΑΣ/PROFILE: +leaf-prefix+ ~S != profile 0x~2,'0X"
                  orchestrator.merkle:+leaf-prefix+ *o-leaf-prefix-byte*))
  (unless (equalp orchestrator.merkle:+node-prefix+ (vector *o-node-prefix-byte*))
    (%profile-die "ΑΣΥΜΦΩΝΙΑ ΕΔΡΑΣ/PROFILE: +node-prefix+ ~S != profile 0x~2,'0X"
                  orchestrator.merkle:+node-prefix+ *o-node-prefix-byte*))
  (let ((probe (orchestrator.merkle:hash-leaf-bytes
                (make-array 0 :element-type '(unsigned-byte 8)))))
    (unless (and (> (length probe) (length *o-hash-prefix*))
                 (string= *o-hash-prefix* probe :end2 (length *o-hash-prefix*)))
      (%profile-die "ΑΣΥΜΦΩΝΙΑ ΕΔΡΑΣ/PROFILE: αναπαράσταση hash ~S δεν αρχίζει με ~S"
                    probe *o-hash-prefix*)))
  (format t "  ✓ σταθερές έδρας ≡ profile (leaf 0x~2,'0X, node 0x~2,'0X, ~A)~%"
          *o-leaf-prefix-byte* *o-node-prefix-byte* (pget :hash-algorithm)))

;;; ── ΔΗΜΟΣΙΕΥΜΕΝΕΣ ΣΤΑΘΕΡΕΣ (ανεξάρτητες από κάθε δικό μας κώδικα) ──
(defparameter +fips-180-4-abc+
  "sha256:ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
  "FIPS 180-4 known-answer test: SHA-256(\"abc\"). Πιστοποιεί το ΙΔΙΟ το πρωτόγονο.")
(defparameter +rfc9162-empty-tree+
  "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  "RFC 9162 §2.1.1: MTH({}) = SHA-256(\"\") — δημοσιευμένη σταθερά.")

(defun assert-published-constants ()
  (let ((abc (%o-sha (babel:string-to-octets "abc" :encoding :utf-8))))
    (unless (string= abc +fips-180-4-abc+)
      (format *error-output* "~&::error::FIPS 180-4 KAT ΑΠΕΤΥΧΕ: ~A~%" abc)
      (sb-ext:quit :unix-status 1)))
  (unless (and (string= (oracle-mth '()) +rfc9162-empty-tree+)
               (string= (orchestrator.merkle:merkle-tree-hash '()) +rfc9162-empty-tree+))
    (format *error-output* "~&::error::MTH({}) != δημοσιευμένη σταθερά RFC 9162~%")
    (sb-ext:quit :unix-status 1))
  (format t "  ✓ δημοσιευμένες σταθερές: FIPS 180-4 SHA-256(\"abc\") + RFC 9162 MTH({})~%"))

(defvar *oracle-checks* 0)
(defun agreed (seat-value oracle-value what)
  "Κάθε εκπεμπόμενη τιμή περνά ΑΠΟ ΕΔΩ: έδρα ΚΑΙ ανεξάρτητο oracle ΠΡΕΠΕΙ να
   συμφωνούν. Διαφωνία = ΑΒΟΡΤ (ποτέ σιωπηλή εγγραφή «χρυσής» τιμής)."
  (incf *oracle-checks*)
  (unless (string= seat-value oracle-value)
    (format *error-output* "~&::error::ΔΙΑΦΩΝΙΑ ΕΔΡΑΣ/ORACLE στο ~A~%  έδρα:   ~A~%  oracle: ~A~%"
            what seat-value oracle-value)
    (sb-ext:quit :unix-status 1))
  seat-value)

(defun %path-repr (path)
  "Κανονική σειριοποίηση path για σύγκριση στοιχείο-προς-στοιχείο (side+hash)."
  (with-output-to-string (o)
    (dolist (s path) (format o "~(~A~)=~A;" (car s) (cdr s)))))

(defun %proof-repr (proof)
  (format nil "~{~A~^;~}" proof))

;;; ============================================================================
;;; 1. GOLDEN VECTORS  (τιμές υπολογισμένες από τη ΜΙΑ έδρα Lisp)
;;; ============================================================================

(defun jstr (s) (with-output-to-string (o)
                  (write-char #\" o)
                  (loop for c across s do
                    (case c (#\" (write-string "\\\"" o))
                            (#\\ (write-string "\\\\" o))
                            (#\Newline (write-string "\\n" o))
                            (t (write-char c o))))
                  (write-char #\" o)))

(defun build-vectors-json ()
  (with-output-to-string (o)
    (format o "{~%  \"profile\": ~A,~%" (jstr (pget :profile-id)))
    (format o "  \"normative_reference\": ~A,~%" (jstr (pget :normative-reference)))
    (format o "  \"generated_by\": \"scripts/gen-merkle-truth.lisp\",~%")
    (format o "  \"source_of_truth\": \"deployment/verify/merkle-profile.sexp\",~%")
    (format o "  \"tree_leaf_rule\": ~A,~%" (jstr (pget :tree-leaf-rule)))
    (format o "  \"empty_tree_root\": ~A,~%"
            (jstr (agreed orchestrator.merkle:+empty-tree-hash+ (oracle-mth '()) "empty-tree-root")))
    ;; ── φύλλα byte-exact ──
    (format o "  \"leaves\": [~%")
    (let ((items (pget :leaf-inputs)))
      (loop for it in items for i from 0 do
        (format o "    {\"id\": ~A, \"input_hex\": ~A, \"leaf\": ~A}~:[~;,~]~%"
                (jstr (getf it :id)) (jstr (getf it :hex))
                (jstr (agreed (leaf-of-hex (getf it :hex)) (oracle-leaf (hex->bytes (getf it :hex))) (format nil "leaf ~A" (getf it :id))))
                (< i (1- (length items))))))
    (format o "  ],~%")
    ;; ── ρίζες ανά μέγεθος ──
    (format o "  \"trees\": [~%")
    (let ((sizes (pget :tree-sizes)))
      (loop for n in sizes for i from 0 do
        (format o "    {\"n\": ~D, \"root\": ~A}~:[~;,~]~%"
                n (jstr (agreed (orchestrator.merkle:merkle-tree-hash (tree-leaves n)) (oracle-mth (tree-leaves n)) (format nil "root n=~D" n)))
                (< i (1- (length sizes))))))
    (format o "  ],~%")
    ;; ── inclusion ──
    (format o "  \"inclusion\": [~%")
    (let ((cases (pget :inclusion-cases)))
      (loop for c in cases for ci from 0 do
        (let* ((n (getf c :n)) (idx (getf c :index))
               (leaves (tree-leaves n))
               (path (orchestrator.merkle:inclusion-path leaves idx))
               (root (agreed (orchestrator.merkle:merkle-tree-hash leaves)
                             (oracle-mth leaves) (format nil "incl-root n=~D" n))))
          ;; [ΕΥΡΗΜΑ ΚΡΙΤΗ #2] Το path ΔΕΝ εκπέμπεται με μόνη πηγή την έδρα:
          ;; (α) διασταυρώνεται στοιχείο-προς-στοιχείο με τη μεταγραφή PATH του
          ;; RFC, (β) ΞΑΝΑΔΙΠΛΩΝΕΤΑΙ ως τη ρίζα με τα πρωτόγονα του oracle.
          (agreed (%path-repr path) (%path-repr (oracle-path leaves idx))
                  (format nil "incl-path n=~D i=~D" n idx))
          (agreed (oracle-fold-path (nth idx leaves) path) root
                  (format nil "incl-fold n=~D i=~D" n idx))
          (format o "    {\"n\": ~D, \"index\": ~D, \"leaf\": ~A, \"root\": ~A, \"path\": ["
                  n idx (jstr (nth idx leaves)) (jstr root))
          (loop for step in path for si from 0 do
            (format o "~:[~;, ~]{\"side\": ~A, \"hash\": ~A}" (plusp si)
                    (jstr (string-downcase (symbol-name (car step)))) (jstr (cdr step))))
          (format o "]}~:[~;,~]~%" (< ci (1- (length cases)))))))
    (format o "  ],~%")
    ;; ── consistency ──
    (format o "  \"consistency\": [~%")
    (let ((cases (pget :consistency-cases)))
      (loop for c in cases for ci from 0 do
        (let* ((n (getf c :n)) (m (getf c :m))
               (leaves (tree-leaves n))
               (proof (orchestrator.merkle:consistency-proof leaves m))
               ;; [ΕΥΡΗΜΑ ΚΡΙΤΗ #2] old/new roots ΚΑΙ το ίδιο το proof
               ;; διασταυρώνονται με τη μεταγραφή SUBPROOF του RFC — πριν, ΜΟΝΟ
               ;; οι ρίζες των δέντρων/differential περνούσαν από agreed.
               (old-root (agreed (orchestrator.merkle:merkle-tree-hash (tree-leaves m))
                                 (oracle-mth (tree-leaves m))
                                 (format nil "cons-old n=~D m=~D" n m)))
               (new-root (agreed (orchestrator.merkle:merkle-tree-hash leaves)
                                 (oracle-mth leaves)
                                 (format nil "cons-new n=~D m=~D" n m))))
          (agreed (%proof-repr proof) (%proof-repr (oracle-consistency leaves m))
                  (format nil "cons-proof n=~D m=~D" n m))
          (format o "    {\"n\": ~D, \"m\": ~D, \"old_root\": ~A, \"new_root\": ~A, \"proof\": ["
                  n m (jstr old-root) (jstr new-root))
          (loop for h in proof for si from 0 do
            (format o "~:[~;, ~]~A" (plusp si) (jstr h)))
          (format o "]}~:[~;,~]~%" (< ci (1- (length cases)))))))
    (format o "  ],~%")
    ;; ── differential: ρίζες για ΚΑΘΕ μέγεθος του εύρους ──
    (let* ((r (pget :differential-range))
           (from (getf r :from)) (to (getf r :to)))
      (format o "  \"differential\": {\"from\": ~D, \"to\": ~D, \"roots\": [~%" from to)
      (loop for n from from to to do
        (format o "    ~A~:[~;,~]~%"
                (jstr (agreed (orchestrator.merkle:merkle-tree-hash (tree-leaves n)) (oracle-mth (tree-leaves n)) (format nil "diff n=~D" n)))
                (< n to)))
      (format o "  ]}~%"))
    (format o "}~%")))

;;; ============================================================================
;;; 2. ΠΑΡΑΓΟΜΕΝΕΣ ΕΝΟΤΗΤΕΣ ΤΕΚΜΗΡΙΩΣΗΣ
;;; ============================================================================

(defun rules-md ()
  (with-output-to-string (o)
    (dolist (r (pget :rules))
      (format o "- **`~(~A~)`** — `~A`~%" (getf r :id) (getf r :statement))
      (when (getf r :rationale)
        (format o "  <br/>*~A*~%" (getf r :rationale))))))

(defun byte-encoding-md ()
  (with-output-to-string (o)
    (dolist (r (pget :byte-encoding))
      (format o "- **`~(~A~)`** — ~A~%" (getf r :id) (getf r :statement))
      (when (getf r :rationale) (format o "  <br/>*~A*~%" (getf r :rationale))))))

(defun policy-md ()
  (with-output-to-string (o)
    (dolist (r (pget :publication-policy))
      (format o "- **`~(~A~)`** — ~A~%" (getf r :id) (getf r :statement))
      (when (getf r :rationale) (format o "  <br/>*~A*~%" (getf r :rationale))))))

(defun algorithm-block ()
  "Το ΕΝΑ εκτελέσιμο ψευδο-κώδικα μπλοκ — ΤΑΥΤΟΣΗΜΟ και στα δύο κείμενα.
   [ΕΥΡΗΜΑ ΚΡΙΤΗ #2] Ο αλγόριθμος, τα prefix bytes και η αναπαράσταση hash
   ΠΑΡΑΓΟΝΤΑΙ από τα πεδία του profile — δεν υπάρχει δεύτερο, hardcoded
   αντίγραφο εδώ που θα επιβίωνε από αλλαγή του profile."
  (let ((alg (pget :hash-algorithm))
        (lp  (format nil "0x~2,'0X" *o-leaf-prefix-byte*))
        (np  (format nil "0x~2,'0X" *o-node-prefix-byte*)))
    (format nil "```
# profile: ~A   (~A)
MTH([])        = ~A(\"\")                                  # empty tree
MTH([d0])      = ~A(~A || d0)                          # leaf, domain-separated
MTH(D[n>1])    = ~A(~A || MTH(D[0:k]) || MTH(D[k:n]))   # internal node
                 where k = largest power of two STRICTLY < n   # unbalanced split
                 NEVER duplicate-last                          # CVE-2012-2459 class

# hashes are carried as \"~A\" + 64 lowercase hex; node() concatenates the
# RAW decoded bytes of the children, never their hex text.

inclusion(text, proof):
  leaf = \"~A\" + hex(~A(~A || UTF8_no_BOM(text)))
  if leaf != proof.leaf:              FAIL(\"text-hash-mismatch\")
  h = leaf
  for step in proof.path:                                      # leaf -> root
     h = (step.side == \"left\") ? node(step.hash, h) : node(h, step.hash)
  if h != proof.merkle_root:          FAIL(\"inclusion-failed\")
  OK
```" (pget :profile-id) (pget :normative-reference)
    alg alg lp alg np *o-hash-prefix* *o-hash-prefix* alg lp)))

(defparameter +begin+ "<!-- BEGIN GENERATED lawmax-merkle-sha256-v1 — DO NOT EDIT BY HAND -->")
(defparameter +end+   "<!-- END GENERATED lawmax-merkle-sha256-v1 -->")

(defun generated-warning ()
  (format nil "~A~%*Αυτή η ενότητα **ΠΑΡΑΓΕΤΑΙ** από τη μία κανονική πηγή
`deployment/verify/merkle-profile.sexp` μέσω `scripts/gen-merkle-truth.lisp`.
Χειροκίνητη επεξεργασία θα ανατραπεί και **κοκκινίζει το build**.*~%" +begin+))

(defun pcl-section ()
  (format nil "~A
## Merkle tree — canonical profile `~A`

Normative reference: [~A](~A).

### Rules

~A
### Byte-exact input

~A
### Publication policy (mechanism ≠ policy)

~A
### Algorithm

~A

Golden vectors shared by all three independent implementations:
`deployment/verify/vectors/merkle/vectors.json`.
~A"
          (generated-warning) (pget :profile-id)
          (pget :normative-reference) (pget :normative-url)
          (rules-md) (byte-encoding-md) (policy-md) (algorithm-block) +end+))

(defun readme-section ()
  (format nil "~A
## The algorithm (so you can re-implement it in any language)

Canonical profile **`~A`** — normative reference
[~A](~A).

~A

### Byte-exact input

~A
### Publication policy

~A
Every implementation in this directory is checked against the shared golden
vectors (`vectors/merkle/vectors.json`) by the build gate. A second, contradictory
description of this algorithm anywhere in the repository is a build failure.
~A"
          (generated-warning) (pget :profile-id)
          (pget :normative-reference) (pget :normative-url)
          (algorithm-block) (byte-encoding-md) (policy-md) +end+))

;;; ============================================================================
;;; ΕΓΓΡΑΦΗ / ΕΛΕΓΧΟΣ
;;; ============================================================================

(defun slurp (path)
  (with-open-file (s path :external-format :utf-8)
    (let ((buf (make-string (file-length s))))
      (subseq buf 0 (read-sequence buf s)))))

(defvar *dirty* nil)

(defun emit (path content what)
  (let ((existing (and (probe-file path) (slurp path))))
    (cond ((and existing (string= existing content))
           (format t "  = ~A (αμετάβλητο)~%" what))
          (*check-only*
           (setf *dirty* t)
           (format t "  ✗ ~A ΑΠΟΚΛΙΝΕΙ από το committed~%" what))
          (t (orchestrator.journal:write-file-atomic path content)
             (format t "  → ~A γράφτηκε~%" what)))))

(defun splice (path section what)
  "Αντικατέστησε ΜΟΝΟ τη ζώνη ανάμεσα στους δείκτες. Απούσα ζώνη = σφάλμα
   (ποτέ σιωπηλή παράλειψη παραγωγής)."
  (let* ((text (slurp path))
         (b (search +begin+ text))
         (e (search +end+ text)))
    (unless (and b e (< b e))
      (format *error-output* "~&::error::~A: απόντες/ανάποδοι δείκτες GENERATED~%" what)
      (sb-ext:quit :unix-status 1))
    (emit path (concatenate 'string (subseq text 0 b) section
                            (subseq text (+ e (length +end+))))
          what)))

(format t "~&MERKLE-SINGLE-TRUTH generator — profile ~A~%" (pget :profile-id))
(format t "~:[ΕΓΓΡΑΦΗ~;ΕΛΕΓΧΟΣ (--check)~]~%" *check-only*)
(assert-published-constants)
(assert-seat-matches-profile)

(ensure-directories-exist (repo "deployment/verify/vectors/merkle/"))
(emit (repo "deployment/verify/vectors/merkle/vectors.json") (build-vectors-json) "vectors.json")
(splice (repo "deployment/PROOF-CARRYING-LAW.md") (pcl-section) "PROOF-CARRYING-LAW.md")
(splice (repo "deployment/verify/README.md") (readme-section) "verify/README.md")

(when (and *check-only* *dirty*)
  (format *error-output*
          "~&::error::τα ΠΑΡΑΓΟΜΕΝΑ διαφέρουν από τα committed — τρέξε ~
           `sbcl --script scripts/gen-merkle-truth.lisp` και κάνε commit~%")
  (sb-ext:quit :unix-status 1))

(format t "~&ανεξάρτητο oracle: ~D τιμές διασταυρώθηκαν (έδρα ≡ RFC-μεταγραφή)~%" *oracle-checks*)
(format t "~&OK~%")
(sb-ext:quit :unix-status 0)
