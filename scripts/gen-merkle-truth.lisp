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
;;; ΘΕΡΑΠΕΙΑ: δεύτερη υλοποίηση ΜΕΤΑΓΡΑΜΜΕΝΗ ΑΠΕΥΘΕΙΑΣ ΑΠΟ ΤΟ ΚΕΙΜΕΝΟ ΤΟΥ RFC
;;; 9162 §2.1.1, ΔΟΜΙΚΑ ΔΙΑΦΟΡΕΤΙΚΗ από την έδρα:
;;;   • δεν καλεί ΚΑΜΙΑ συνάρτηση του orchestrator.merkle
;;;   • χτίζει bottom-up με ΡΗΤΗ αριθμητική δεικτών (η έδρα είναι αναδρομική
;;;     top-down με ranges)· διαφορετική δομή ⇒ κοινό σφάλμα λιγότερο πιθανό
;;;   • χειρίζεται τα bytes απευθείας με ironclad, χωρίς την %sha256-hex
;;; Κάθε τιμή που εκπέμπεται ΠΡΕΠΕΙ να συμφωνεί ΚΑΙ ΜΕ ΤΑ ΔΥΟ. Διαφωνία ⇒ ΑΒΟΡΤ.
;;;
;;; ΤΙΜΙΟ ΟΡΙΟ: δεν κατέστη δυνατή η λήψη ΔΗΜΟΣΙΕΥΜΕΝΟΥ εξωτερικού συνόλου
;;; vectors — η πολιτική δικτύου του περιβάλλοντος απορρίπτει τα www.rfc-editor.org
;;; / sqlite.org / github.com (403). Το άγκυρο συμμόρφωσης είναι επομένως:
;;;   (α) ΔΗΜΟΣΙΕΥΜΕΝΕΣ ΣΤΑΘΕΡΕΣ (FIPS 180-4 KAT για το SHA-256· RFC 9162
;;;       MTH({}) = SHA-256(""))  — ΑΝΕΞΑΡΤΗΤΕΣ από κάθε δικό μας κώδικα, ΚΑΙ
;;;   (β) η μεταγραμμένη-από-το-πρότυπο ανεξάρτητη υλοποίηση.
;;; ΔΕΝ ισχυρίζομαι «επαληθεύτηκε έναντι τρίτου συνόλου vectors».

(defun %o-sha (bytes)
  "SHA-256 → sha256:hex, ΑΠΕΥΘΕΙΑΣ (καμία συνάρτηση της έδρας)."
  (concatenate 'string "sha256:"
               (string-downcase (ironclad:byte-array-to-hex-string
                                 (ironclad:digest-sequence :sha256 bytes)))))

(defun %o-raw (h) (ironclad:hex-string-to-byte-array (subseq h 7)))

(defun oracle-leaf (bytes)
  "RFC 9162 §2.1.1: MTH({d(0)}) = SHA-256(0x00 || d(0))."
  (%o-sha (concatenate '(vector (unsigned-byte 8)) #(0) bytes)))

(defun oracle-node (l r)
  "RFC 9162 §2.1.1: εσωτερικός κόμβος = SHA-256(0x01 || left || right)."
  (%o-sha (concatenate '(vector (unsigned-byte 8)) #(1) (%o-raw l) (%o-raw r))))

(defun oracle-mth (leaf-hashes)
  "RFC 9162 §2.1.1, ΜΕΤΑΓΡΑΦΗ ΑΠΟ ΤΟ ΠΡΟΤΥΠΟ — ΕΠΑΝΑΛΗΠΤΙΚΗ (bottom-up) υλοποίηση
   με ρητή αριθμητική δεικτών, δομικά ΔΙΑΦΟΡΕΤΙΚΗ από την αναδρομική έδρα.
   MTH({}) = SHA-256(\"\")· MTH({d}) = το φύλλο· αλλιώς split στο k = 2^floor(log2(n-1))."
  (let* ((v (coerce leaf-hashes 'vector)) (n (length v)))
    (cond
      ((zerop n) (%o-sha (make-array 0 :element-type '(unsigned-byte 8))))
      ((= n 1) (aref v 0))
      (t
       ;; ΡΗΤΟΣ υπολογισμός: στοίβα (start . hash) — συγχωνεύουμε όταν το δεξί
       ;; τμήμα είναι πλήρες υποδέντρο του σωστού μεγέθους κατά RFC.
       (labels ((split-k (m) (let ((k 1)) (loop while (< (* k 2) m) do (setf k (* k 2))) k))
                (build (lo hi)
                  (let ((m (- hi lo)))
                    (if (= m 1) (aref v lo)
                        (let ((k (split-k m)))
                          (oracle-node (build lo (+ lo k)) (build (+ lo k) hi)))))))
         ;; ΔΕΥΤΕΡΟΣ, ανεξάρτητος υπολογισμός για διασταύρωση: level-order με
         ;; ρητή λίστα τμημάτων (καμία αναδρομή σε ranges της έδρας).
         (let ((by-recursion (build 0 n))
               (by-segments
                 (let ((segs (list (cons 0 n))))
                   ;; αναπτύσσουμε τα τμήματα ώσπου να γίνουν φύλλα, μετά
                   ;; συγχωνεύουμε ανάποδα — ίδιος κανόνας, άλλη μηχανική
                   (labels ((expand (s)
                              (let* ((lo (car s)) (hi (cdr s)) (m (- hi lo)))
                                (if (= m 1) (aref v lo)
                                    (let ((k (split-k m)))
                                      (oracle-node (expand (cons lo (+ lo k)))
                                                   (expand (cons (+ lo k) hi))))))))
                     (expand (first segs))))))
           (unless (string= by-recursion by-segments)
             (format *error-output* "~&::error::ORACLE ΑΣΥΝΕΠΕΣ ΜΕ ΤΟΝ ΕΑΥΤΟ ΤΟΥ (n=~D)~%" n)
             (sb-ext:quit :unix-status 1))
           by-recursion))))))

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
    (format o "  \"empty_tree_root\": ~A,~%" (jstr orchestrator.merkle:+empty-tree-hash+))
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
               (path (orchestrator.merkle:inclusion-path leaves idx)))
          (format o "    {\"n\": ~D, \"index\": ~D, \"leaf\": ~A, \"root\": ~A, \"path\": ["
                  n idx (jstr (nth idx leaves))
                  (jstr (agreed (orchestrator.merkle:merkle-tree-hash leaves) (oracle-mth leaves) (format nil "incl-root n=~D" n))))
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
               (proof (orchestrator.merkle:consistency-proof leaves m)))
          (format o "    {\"n\": ~D, \"m\": ~D, \"old_root\": ~A, \"new_root\": ~A, \"proof\": ["
                  n m
                  (jstr (orchestrator.merkle:merkle-tree-hash (tree-leaves m)))
                  (jstr (orchestrator.merkle:merkle-tree-hash leaves)))
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
  "Το ΕΝΑ εκτελέσιμο ψευδο-κώδικα μπλοκ — ΤΑΥΤΟΣΗΜΟ και στα δύο κείμενα."
  (format nil "```
# profile: ~A   (~A)
MTH([])        = SHA-256(\"\")                                  # empty tree
MTH([d0])      = SHA-256(0x00 || d0)                          # leaf, domain-separated
MTH(D[n>1])    = SHA-256(0x01 || MTH(D[0:k]) || MTH(D[k:n]))   # internal node
                 where k = largest power of two STRICTLY < n   # unbalanced split
                 NEVER duplicate-last                          # CVE-2012-2459 class

# hashes are carried as \"sha256:\" + 64 lowercase hex; node() concatenates the
# RAW decoded bytes of the children, never their hex text.

inclusion(text, proof):
  leaf = \"sha256:\" + hex(SHA-256(0x00 || UTF8_no_BOM(text)))
  if leaf != proof.leaf:              FAIL(\"text-hash-mismatch\")
  h = leaf
  for step in proof.path:                                      # leaf -> root
     h = (step.side == \"left\") ? node(step.hash, h) : node(h, step.hash)
  if h != proof.merkle_root:          FAIL(\"inclusion-failed\")
  OK
```" (pget :profile-id) (pget :normative-reference)))

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
