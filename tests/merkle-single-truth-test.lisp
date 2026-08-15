;;;; tests/merkle-single-truth-test.lisp
;;;; ============================================================================
;;;; MERKLE-SINGLE-TRUTH — Η ΠΥΛΗ ΤΗΣ ΜΙΑΣ ΑΛΗΘΕΙΑΣ
;;;; ============================================================================
;;;; Κλειδώνει, ως εκτελέσιμη μη-παλινδρόμηση:
;;;;   Α. Ο πρωτόγονος συμμορφώνεται με το profile lawmax-merkle-sha256-v1
;;;;      (RFC 9162 §2.1.1), ΣΥΜΠΕΡΙΛΑΜΒΑΝΟΜΕΝΟΥ του κανονικού ΚΕΝΟΥ δέντρου.
;;;;   Β. ΧΩΡΙΣΤΑ: η ΠΟΛΙΤΙΚΗ δημοσίευσης απορρίπτει corpus με leaf_count = 0.
;;;;      (μηχανισμός != πολιτική — δύο ιδιότητες, δύο ανεξάρτητοι έλεγχοι)
;;;;   Γ. Η Lisp έδρα συμφωνεί με ΚΑΘΕ golden vector (τα ίδια που τρέχουν
;;;;      Python και Node — byte-for-byte κοινή αλήθεια).
;;;;   Δ. ΑΡΝΗΤΙΚΟΙ ΜΑΡΤΥΡΕΣ: duplicate-last, απουσία prefixes, λάθος split,
;;;;      swap left/right, Unicode normalization, CRLF normalization —
;;;;      ΚΑΘΕΝΑΣ πρέπει να παράγει ΔΙΑΦΟΡΕΤΙΚΗ ρίζα από την κανονική.
;;;;   Ε. Καμία δεύτερη, αντιφατική περιγραφή του αλγορίθμου στο repo.
;;;;
;;;; ΓΙΑΤΙ: το PROOF-CARRYING-LAW.md δίδασκε duplicate-last και το
;;;; verify/README.md παρέλειπε ΚΑΙ τα δύο domain prefixes — τρίτος που
;;;; ξανα-υλοποιούσε από τα κείμενα έπαιρνε ΔΙΑΦΟΡΕΤΙΚΗ ρίζα. RELEASE BLOCKER.

(in-package :cl-user)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun %mst-repo (rel)
  (merge-pathnames rel (merge-pathnames "../" (make-pathname
                                              :directory (pathname-directory
                                                          (or *load-truename* *load-pathname*))))))

(defun %mst-slurp (path)
  (with-open-file (s path :external-format :utf-8)
    (let ((buf (make-string (file-length s))))
      (subseq buf 0 (read-sequence buf s)))))

;;; ── ΕΛΑΧΙΣΤΟΣ JSON READER (μόνο ό,τι χρειάζονται τα vectors) ──
;;; Δεν εισάγουμε εξάρτηση· τα vectors είναι δικά μας, κανονικά παραγόμενα.
(defun %json-parse (text)
  (let ((i 0) (n (length text)))
    (labels ((ws () (loop while (and (< i n) (member (char text i) '(#\Space #\Tab #\Newline #\Return))) do (incf i)))
             (val ()
               (ws)
               (let ((c (char text i)))
                 (cond ((char= c #\{) (obj)) ((char= c #\[) (arr))
                       ((char= c #\") (str))
                       ((or (digit-char-p c) (char= c #\-)) (num))
                       ((and (<= (+ i 4) n) (string= "true" text :start2 i :end2 (+ i 4))) (incf i 4) t)
                       ((and (<= (+ i 5) n) (string= "false" text :start2 i :end2 (+ i 5))) (incf i 5) nil)
                       ((and (<= (+ i 4) n) (string= "null" text :start2 i :end2 (+ i 4))) (incf i 4) nil)
                       (t (error "json: απρόσμενο ~C στη θέση ~D" c i)))))
             (str () (incf i)
               (with-output-to-string (o)
                 (loop while (char/= (char text i) #\")
                       do (if (char= (char text i) #\\)
                              (progn (incf i)
                                     (write-char (case (char text i) (#\n #\Newline) (#\t #\Tab)
                                                   (#\r #\Return) (t (char text i))) o)
                                     (incf i))
                              (progn (write-char (char text i) o) (incf i))))
                 (incf i)))
             (num () (let ((s i))
                       (loop while (and (< i n) (or (digit-char-p (char text i))
                                                    (member (char text i) '(#\- #\+ #\. #\e #\E))))
                             do (incf i))
                       (parse-integer text :start s :end i :junk-allowed t)))
             (arr () (incf i) (ws)
               (if (char= (char text i) #\]) (progn (incf i) '())
                   (let ((acc '()))
                     (loop (push (val) acc) (ws)
                           (cond ((char= (char text i) #\,) (incf i))
                                 ((char= (char text i) #\]) (incf i) (return (nreverse acc)))
                                 (t (error "json array")))))))
             (obj () (incf i) (ws)
               (if (char= (char text i) #\}) (progn (incf i) '())
                   (let ((acc '()))
                     (loop (ws) (let ((k (str))) (ws) (incf i) ; ':'
                                     (push (cons k (val)) acc))
                           (ws)
                           (cond ((char= (char text i) #\,) (incf i))
                                 ((char= (char text i) #\}) (incf i) (return (nreverse acc)))
                                 (t (error "json object"))))))))
      (val))))

(defun jget (o k) (cdr (assoc k o :test #'string=)))

(defvar *vec* (%json-parse (%mst-slurp (%mst-repo "deployment/verify/vectors/merkle/vectors.json"))))

(defun %hex->bytes (hex)
  (if (zerop (length hex))
      (make-array 0 :element-type '(unsigned-byte 8))
      (ironclad:hex-string-to-byte-array hex)))

(defun %tree-leaves (n)
  (loop for i below n
        collect (orchestrator.merkle:hash-leaf-bytes
                 (babel:string-to-octets (format nil "~D" i) :encoding :utf-8))))

(format t "~%== Α. ΠΡΩΤΟΓΟΝΟΣ: συμμόρφωση profile (ΜΗΧΑΝΙΣΜΟΣ) ==~%")

(check "profile id στα vectors" (string= (jget *vec* "profile") "lawmax-merkle-sha256-v1"))
(check "ΚΕΝΟ δέντρο: MTH([]) = SHA-256(\"\")  (RFC 9162 §2.1.1)"
       (string= (orchestrator.merkle:merkle-tree-hash '())
                "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"))
(check "το κενό δέντρο συμφωνεί με τα vectors"
       (string= (orchestrator.merkle:merkle-tree-hash '()) (jget *vec* "empty_tree_root")))
(check "n=1 ⇒ το ΙΔΙΟ το φύλλο (κανένα re-hash)"
       (let ((l (orchestrator.merkle:hash-leaf-string "x")))
         (string= (orchestrator.merkle:merkle-tree-hash (list l)) l)))

(format t "~%== Β. ΠΟΛΙΤΙΚΗ ΔΗΜΟΣΙΕΥΣΗΣ (ΧΩΡΙΣΤΗ από τον μηχανισμό) ==~%")

(check "δημοσίευση corpus με leaf_count = 0 ⇒ EMPTY-CORPUS-PUBLICATION"
       (handler-case
           (progn (orchestrator.proof-carrying:write-provision-proofs
                   '() (merge-pathnames "lawmax-merkle-policy-test/" #p"/tmp/"))
                  nil)
         (orchestrator.proof-carrying:empty-corpus-publication () t)))
(check "η άρνηση συμβαίνει ΠΡΙΝ γραφτεί οτιδήποτε (κανένα corpus-proof.json)"
       (not (probe-file (merge-pathnames "lawmax-merkle-policy-test/corpus-proof.json" #p"/tmp/"))))
(check "μη-κενό corpus ΔΕΝ εμποδίζεται από την πολιτική"
       (multiple-value-bind (root count)
           (orchestrator.proof-carrying:write-provision-proofs
            (list (list :id "1" :text "α")) (merge-pathnames "lawmax-merkle-policy-ok/" #p"/tmp/"))
         (and (stringp root) (= count 1))))

(format t "~%== Γ. GOLDEN VECTORS: η Lisp έδρα ≡ Python ≡ Node ==~%")

(let ((bad 0))
  (dolist (lv (jget *vec* "leaves"))
    (unless (string= (orchestrator.merkle:hash-leaf-bytes (%hex->bytes (jget lv "input_hex")))
                     (jget lv "leaf"))
      (incf bad) (format t "    ✗ leaf ~A~%" (jget lv "id"))))
  (check (format nil "~D φύλλα byte-exact (hex είσοδος — κανένας string parser)"
                 (length (jget *vec* "leaves")))
         (zerop bad)))

(let ((bad 0))
  (dolist (tr (jget *vec* "trees"))
    (unless (string= (orchestrator.merkle:merkle-tree-hash (%tree-leaves (jget tr "n")))
                     (jget tr "root"))
      (incf bad) (format t "    ✗ root n=~D~%" (jget tr "n"))))
  (check (format nil "~D ρίζες (n=0..8,15,16,17)" (length (jget *vec* "trees"))) (zerop bad)))

(let ((bad 0))
  (dolist (inc (jget *vec* "inclusion"))
    (let* ((leaves (%tree-leaves (jget inc "n")))
           (path (mapcar (lambda (st)
                           (cons (if (string= (jget st "side") "left") :left :right)
                                 (jget st "hash")))
                         (jget inc "path"))))
      (unless (and (string= (nth (jget inc "index") leaves) (jget inc "leaf"))
                   (orchestrator.merkle:verify-inclusion (jget inc "leaf") path (jget inc "root")))
        (incf bad) (format t "    ✗ inclusion n=~D i=~D~%" (jget inc "n") (jget inc "index")))))
  (check (format nil "~D inclusion paths" (length (jget *vec* "inclusion"))) (zerop bad)))

(let ((bad 0))
  (dolist (c (jget *vec* "consistency"))
    (unless (orchestrator.merkle:verify-consistency
             (jget c "m") (jget c "n") (jget c "old_root") (jget c "new_root") (jget c "proof"))
      (incf bad) (format t "    ✗ consistency n=~D m=~D~%" (jget c "n") (jget c "m"))))
  (check (format nil "~D consistency proofs" (length (jget *vec* "consistency"))) (zerop bad)))

(let* ((d (jget *vec* "differential")) (from (jget d "from")) (bad 0))
  (loop for expected in (jget d "roots") for n from from do
    (unless (string= (orchestrator.merkle:merkle-tree-hash (%tree-leaves n)) expected)
      (incf bad) (format t "    ✗ differential n=~D~%" n)))
  (check (format nil "differential ~D..~D (~D μεγέθη)" from (jget d "to")
                 (length (jget d "roots")))
         (zerop bad)))

(format t "~%== Δ. ΑΡΝΗΤΙΚΟΙ ΜΑΡΤΥΡΕΣ: κάθε μετάλλαξη ΑΛΛΑΖΕΙ τη ρίζα ==~%")

;; Οι μεταλλάξεις υπολογίζονται ΕΔΩ ως ανεξάρτητες συναρτήσεις και συγκρίνονται
;; με την κανονική ρίζα. Αν κάποια δώσει ΙΔΙΑ ρίζα, η πύλη δεν διακρίνει το
;; λάθος από το σωστό — και ο μάρτυρας είναι κενός.
(defun %sha (bytes) (format nil "sha256:~(~{~2,'0x~}~)"
                            (coerce (ironclad:digest-sequence :sha256 bytes) 'list)))
(defun %cat (&rest vs) (apply #'concatenate '(vector (unsigned-byte 8)) vs))
(defun %raw (h) (ironclad:hex-string-to-byte-array (subseq h 7)))

(defun %mut-root (leaves &key dup-last no-node-prefix wrong-split swap)
  "Μεταλλαγμένος υπολογισμός ρίζας — ΟΧΙ η έδρα."
  (labels ((nd (l r) (let ((a (if swap r l)) (b (if swap l r)))
                       (%sha (if no-node-prefix (%cat (%raw a) (%raw b))
                                 (%cat #(1) (%raw a) (%raw b))))))
           (mth (v)
             (let ((n (length v)))
               (cond ((= n 1) (aref v 0))
                     (dup-last
                      ;; ΜΕΤΑΛΛΑΞΗ duplicate-last: επίπεδο-προς-επίπεδο, περιττό ⇒ ζευγάρι με εαυτό
                      (let ((cur (coerce v 'list)))
                        (loop while (> (length cur) 1) do
                          (when (oddp (length cur)) (setf cur (append cur (last cur))))
                          (setf cur (loop for (a b) on cur by #'cddr collect (nd a b))))
                        (first cur)))
                     (t (let ((k (if wrong-split (floor n 2)
                                     (let ((p 1)) (loop while (< (* p 2) n) do (setf p (* p 2))) p))))
                          (nd (mth (subseq v 0 k)) (mth (subseq v k)))))))))
    (mth (coerce leaves 'vector))))

(let* ((n 5) (leaves (%tree-leaves n))
       (canon (orchestrator.merkle:merkle-tree-hash leaves)))
  (check "Δ1 duplicate-last ⇒ ΔΙΑΦΟΡΕΤΙΚΗ ρίζα (CVE-2012-2459 διακρίνεται)"
         (not (string= canon (%mut-root leaves :dup-last t))))
  (check "Δ2 απουσία node prefix 0x01 ⇒ ΔΙΑΦΟΡΕΤΙΚΗ ρίζα"
         (not (string= canon (%mut-root leaves :no-node-prefix t))))
  (check "Δ3 λάθος split (floor n/2) ⇒ ΔΙΑΦΟΡΕΤΙΚΗ ρίζα"
         (not (string= canon (%mut-root leaves :wrong-split t))))
  (check "Δ4 swap left/right ⇒ ΔΙΑΦΟΡΕΤΙΚΗ ρίζα (order-sensitive)"
         (not (string= canon (%mut-root leaves :swap t)))))

(check "Δ5 απουσία leaf prefix 0x00 ⇒ ΔΙΑΦΟΡΕΤΙΚΟ φύλλο"
       (let ((data (babel:string-to-octets "α" :encoding :utf-8)))
         (not (string= (orchestrator.merkle:hash-leaf-bytes data) (%sha data)))))

;; Η ΚΡΙΣΙΜΗ ιδιότητα CVE-2012-2459: [a b c] και [a b c c] ΠΡΕΠΕΙ να διαφέρουν.
(check "Δ6 [0 1 2] != [0 1 2 2] (δύο σύνολα, ΔΥΟ ρίζες — ο πυρήνας του CVE)"
       (let* ((l3 (%tree-leaves 3))
              (l4 (append l3 (last l3))))
         (not (string= (orchestrator.merkle:merkle-tree-hash l3)
                       (orchestrator.merkle:merkle-tree-hash l4)))))

;; Byte-exact είσοδος: οπτικά ισοδύναμα ΔΕΝ είναι ίδια· CRLF != LF
(check "Δ7 Unicode NFC != NFD (καμία σιωπηλή κανονικοποίηση)"
       (let ((nfc (find "nfc-alpha-tonos" (jget *vec* "leaves")
                        :key (lambda (l) (jget l "id")) :test #'string=))
             (nfd (find "nfd-alpha-tonos" (jget *vec* "leaves")
                        :key (lambda (l) (jget l "id")) :test #'string=)))
         (and nfc nfd (not (string= (jget nfc "leaf") (jget nfd "leaf"))))))
(check "Δ8 CRLF != LF (καμία μετατροπή τερματισμού γραμμής)"
       (let ((lf (find "embedded-lf" (jget *vec* "leaves")
                       :key (lambda (l) (jget l "id")) :test #'string=))
             (crlf (find "embedded-crlf" (jget *vec* "leaves")
                         :key (lambda (l) (jget l "id")) :test #'string=)))
         (not (string= (jget lf "leaf") (jget crlf "leaf")))))
(check "Δ9 τελικό newline διατηρείται (α\\n != α)"
       (let ((a (find "trailing-lf" (jget *vec* "leaves")
                      :key (lambda (l) (jget l "id")) :test #'string=))
             (b (find "no-trailing-lf" (jget *vec* "leaves")
                      :key (lambda (l) (jget l "id")) :test #'string=)))
         (not (string= (jget a "leaf") (jget b "leaf")))))

(format t "~%== Ε. ΚΑΝΟΝΙΣΤΙΚΗ ΜΟΝΑΔΙΚΟΤΗΤΑ: tripwires + δέσμευση στο profile ==~%")

;; [ΔΙΟΡΘΩΣΗ ΚΡΙΤΗ #2/#3] Τρία διαδοχικά λάθη διορθώνονται εδώ.
;;
;;  (α) Πριν σαρώνονταν ΜΟΝΟ δύο markdown αρχεία — η διαβεβαίωση «καμία δεύτερη
;;      περιγραφή στο repo» ήταν ΕΥΡΥΤΕΡΗ από τον μηχανισμό. Τώρα σαρώνεται ΟΛΟ
;;      το authored δέντρο.
;;  (β) Η πρώτη διόρθωση έβαλε ΛΙΣΤΑ ΕΞΑΙΡΕΣΕΩΝ ΑΝΑ ΑΡΧΕΙΟ. Λάθος έδρα: ένα
;;      αρχείο δεν είναι «καθαρό» ή «βρόμικο» — η κάθε ΑΝΑΦΟΡΑ είναι. Λίστα
;;      αρχείων σημαίνει ότι ένα εξαιρεμένο αρχείο μπορεί αύριο να διδάξει τον
;;      μεταλλαγμένο αλγόριθμο ΑΤΙΜΩΡΗΤΑ, ενώ οκτώ αθώες ΑΠΑΓΟΡΕΥΣΕΙΣ
;;      («NEVER duplicate-last») καταγγέλλονταν ως παραβάσεις.
;;  (γ) Ο σαρωτής πολικότητας πιάνει ΜΟΝΟ την ΟΝΟΜΑΣΜΕΝΗ κλάση (duplicate-last)·
;;      μια ΝΕΑ λάθος περιγραφή — π.χ. χωρίς τα prefixes, η ΔΕΥΤΕΡΗ από τις
;;      τρεις αρχικές αστοχίες — δεν ονομάζει τίποτα και περνούσε. Προστέθηκε
;;      ΔΕΥΤΕΡΟΣ μηχανικός κανόνας (Ε2): κάθε αρχείο που ΓΡΑΦΕΙ φόρμουλα του
;;      αλγορίθμου δένεται ονομαστικά στο κανονικό profile.
;;
;; ΤΙΜΙΑ ΟΡΙΟΘΕΤΗΣΗ — ΤΙ ΔΕΝ ΑΠΟΔΕΙΚΝΥΕΙ ΤΟ Ε: κειμενικοί κανόνες ΔΕΝ
;; αποκλείουν σημασιολογικά λάθος περιγραφή σε ελεύθερη πρόζα που αποφεύγει
;; και τα δύο tripwires (ούτε ονομάζει τη μετάλλαξη ούτε γράφει φόρμουλα).
;; Η ΚΑΝΟΝΙΣΤΙΚΗ επιφάνεια του συστήματος είναι: το profile + οι GENERATED
;; ζώνες + τα golden vectors — ΟΛΑ byte-checked από τον generator. Το Ε είναι
;; tripwire ΠΑΝΩ από αυτή την επιφάνεια, όχι απόδειξη μη-ύπαρξης· ο ισχυρισμός
;; «καμία αντίφαση πουθενά» ΔΕΝ εκφέρεται από αυτή τη σουίτα.
;;
;; Η ΕΔΡΑ ΤΟΥ ΚΑΝΟΝΑ ΕΙΝΑΙ Η ΠΟΛΙΚΟΤΗΤΑ ΤΗΣ ΑΝΑΦΟΡΑΣ, ΟΧΙ Η ΤΑΥΤΟΤΗΤΑ ΤΟΥ
;; ΑΡΧΕΙΟΥ. Το όνομα του μεταλλαγμένου αλγορίθμου επιτρέπεται ΠΑΝΤΟΥ όταν —και
;; μόνο όταν— το παράθυρο ±3 γραμμών το τοποθετεί σε μία από τέσσερις νόμιμες
;; κατηγορίες: ΑΠΑΓΟΡΕΥΣΗ, ΙΣΤΟΡΙΚΟ, ΑΝΤΙΠΑΛΟΣ/ΜΕΤΑΛΛΑΞΗ, ΑΠΟΚΛΙΣΗ. Αναφορά
;; ΧΩΡΙΣ πολικότητα = ΠΡΟΣΤΑΚΤΙΚΗ ΔΙΔΑΣΚΑΛΙΑ = ΑΠΟΤΥΧΙΑ, σε ΟΠΟΙΟΔΗΠΟΤΕ αρχείο,
;; συμπεριλαμβανομένου ΑΥΤΟΥ. Καμία εξαίρεση αρχείου δεν υπάρχει πια.
;;
;; Ο ίδιος ο σαρωτής ΑΠΟΔΕΙΚΝΥΕΤΑΙ μη-κενός παρακάτω (Ε-ΜΑΡΤΥΡΕΣ): τρέχει πάνω
;; στο ΑΥΘΕΝΤΙΚΟ ελαττωματικό κείμενο που ζούσε στο PROOF-CARRYING-LAW.md και
;; ΠΡΕΠΕΙ να το καταγγείλει.

(defparameter +dup-phrases+           ; ΑΠΑΓΟΡΕΥΜΕΝΗ διδασκαλία — ονόματα-στόχοι
  '("paired with itself" "pairs with itself" "duplicate-last" "duplicate last"))

(defparameter +dup-window+ 3
  "Πόσες γραμμές εκατέρωθεν μετρούν ως «ίδιο σημασιολογικό παράθυρο».")

(defun %fold (s)
  "Πεζά + αφαίρεση τόνων/διαλυτικών + τελικό σίγμα ⇒ σ.
   ΓΙΑΤΙ: ο δείκτης πολικότητας ΔΕΝ επιτρέπεται να χαθεί επειδή το κείμενο
   γράφτηκε ΚΕΦΑΛΑΙΟ (ΟΧΙ, ΜΑΡΤΥΡΕΣ, ΑΠΑΓΟΡΕΥΕΤΑΙ — τα ελληνικά κεφαλαία
   γράφονται ΑΤΟΝΑ) ή τονισμένο (όχι, μάρτυρες). Χωρίς folding, ο σαρωτής θα
   καταδίκαζε ακριβώς τις πιο εμφατικές απαγορεύσεις του repo."
  (map 'string
       (lambda (c)
         (let ((d (char-downcase c)))
           (case d
             ((#\ά) #\α) ((#\έ) #\ε) ((#\ή) #\η)
             ((#\ί #\ϊ #\ΐ) #\ι) ((#\ό) #\ο)
             ((#\ύ #\ϋ #\ΰ) #\υ) ((#\ώ) #\ω)
             ((#\ς) #\σ)
             (t d))))
       s))

(defparameter +dup-polarity-markers+
  (mapcar #'%fold
          '(;; 1. ΑΠΑΓΟΡΕΥΣΗ / ΑΡΝΗΣΗ — «αυτό ΔΕΝ κάνουμε»
            ;; ΠΡΟΣΟΧΗ: «μη» ΜΟΝΟ με προπορευόμενο κενό — αλλιώς κάθε «γραμμή »
            ;; θα περνούσε ως άρνηση (ψευδο-άδεια).
            "οχι " "δεν " " μη " " μην " "απαγορ" "καμία" "χωρίς" "ανεπίτρεπτ"
            "never" "not " "no-duplicate" "must not" "forbid" "prohibit" "reject"
            "≠" "!="
            ;; 2. ΙΣΤΟΡΙΚΟ / ΥΠΕΡΚΕΡΑΣΗ — «αυτό κάναμε ΠΡΙΝ, καταργήθηκε»
            "προηγούμεν" "παλαι" "πριν" "ήταν" "έλεγε" "δίδασκε" "έκανε" "καταδικ"
            "legacy" "obsolete" "superseded" "used to"
            ;; 3. ΑΝΤΙΠΑΛΟΣ / ΜΕΤΑΛΛΑΞΗ — «αυτό είναι το μεταλλαγμένο σώμα υπό δοκιμή»
            "μεταλλαξ" "μεταλλαγ" "μεταλλάσ" "μάρτυρ" "μαρτυρα"
            "mutation" "mutant" "witness" "forged" "attack" "επίθεση" "cve-"
            ;; 4. ΑΠΟΚΛΙΣΗ / ΑΝΤΙΘΕΣΗ — «εδώ ακριβώς διαφέρει από το κανονικό»
            "αποκλιν" "diverge" "differs" "διαφορετικ" " vs ")))

(defun %dup-polarised-p (lines i)
  "Υπάρχει δείκτης πολικότητας στο παράθυρο ±+DUP-WINDOW+ γύρω από τη γραμμή I;"
  (loop for j from (max 0 (- i +dup-window+))
          to (min (1- (length lines)) (+ i +dup-window+))
        thereis (let ((l (aref lines j)))
                  (some (lambda (m) (search m l)) +dup-polarity-markers+))))

(defun %dup-mention-p (line)
  (some (lambda (ph) (search ph line)) +dup-phrases+))

(defun %dup-mention-lines (lines)
  "1-based γραμμές που ΟΝΟΜΑΖΟΥΝ τον μεταλλαγμένο αλγόριθμο (με ή χωρίς πολικότητα)."
  (loop for i below (length lines) when (%dup-mention-p (aref lines i)) collect (1+ i)))

(defun %dup-offending-lines (lines)
  "1-based γραμμές όπου το όνομα εμφανίζεται ΧΩΡΙΣ πολικότητα ⇒ διδάσκεται ως Ο
   αλγόριθμος. LINES = vector ΗΔΗ folded γραμμών (βλ. %FOLD)."
  (loop for i below (length lines)
        when (and (%dup-mention-p (aref lines i))
                  (not (%dup-polarised-p lines i)))
          collect (1+ i)))

(defun %mst-lines (path)
  (with-open-file (s path :external-format :utf-8)
    (coerce (loop for l = (read-line s nil) while l collect (%fold l)) 'vector)))

(defun %dup-offenders-in-file (path)
  (handler-case (%dup-offending-lines (%mst-lines path)) (error () nil)))

(defun %dup-mention-lines-in-file (path)
  (handler-case (%dup-mention-lines (%mst-lines path)) (error () nil)))

(defun %mst-authored-files ()
  "Κάθε authored αρχείο που θα μπορούσε να περιγράψει τον αλγόριθμο.
   ΕΞΑΙΡΟΥΝΤΑΙ τα append-only πρακτικά (deployment/collab/dialogue) — είναι
   ΙΣΤΟΡΙΚΟ αρχείο, όχι προδιαγραφή, και ΔΕΝ επιτρέπεται να ξαναγραφτεί."
  (remove-if
   (lambda (p) (search "/dialogue/" (namestring p)))
   (append
    (directory (%mst-repo "source/*.lisp"))
    (directory (%mst-repo "systems/*/*.lisp"))
    (directory (%mst-repo "scripts/*.*"))
    (directory (%mst-repo "docker/*.*"))
    (directory (%mst-repo "tests/merkle*.lisp"))
    (directory (%mst-repo "deployment/*.md"))
    (directory (%mst-repo "deployment/verify/*.*"))
    (directory (%mst-repo "*.md")))))

(let* ((files (%mst-authored-files))
       (mentions 0)
       (offenders '()))
  (dolist (f files)
    (let ((bad (%dup-offenders-in-file f)))
      (incf mentions (length (%dup-mention-lines-in-file f)))
      (when bad (push (cons (namestring f) bad) offenders))))
  (dolist (o offenders)
    (format t "    ✗ ΠΡΟΣΤΑΚΤΙΚΗ αναφορά χωρίς πολικότητα: ~A γραμμές ~{~D~^, ~}~%"
            (car o) (cdr o)))
  (check (format nil "καμία ΑΠΡΟΣΔΙΟΡΙΣΤΗ αναφορά (~D αναφορές σε ~D authored αρχεία, ΟΛΕΣ πολωμένες)"
                 mentions (length files))
         (null offenders)))

;; ── Ε-ΜΑΡΤΥΡΕΣ: ο σαρωτής ΔΕΝ επιτρέπεται να είναι κενός ──
;; Ένας κανόνας που δεν καταγγέλλει ΤΙΠΟΤΑ είναι ταυτολογία. Οι μάρτυρες
;; τρέχουν πάνω σε ΣΥΝΘΕΤΙΚΟ κείμενο (καθόλου I/O), ώστε ο έλεγχος να είναι
;; ντετερμινιστικός και ανεξάρτητος από την τρέχουσα κατάσταση του repo.
;; Μ1 είναι το ΑΥΘΕΝΤΙΚΟ ελαττωματικό κείμενο που ζούσε στο PROOF-CARRYING-LAW.md.
(defun %dup-fixture (&rest lines)
  (coerce (mapcar #'%fold lines) 'vector))

(macrolet ((witness (name expected &rest lines)
             `(check ,name (equal ,expected (%dup-offending-lines (%dup-fixture ,@lines))))))
  (witness "Ε-Μ1 το ΑΥΘΕΝΤΙΚΟ ελάττωμα («an odd node is paired with itself») ΚΑΤΑΓΓΕΛΛΕΤΑΙ" '(2)
           "## 2. The Merkle commitment"
           "The tree is built pairwise; an odd node is paired with itself."
           "The root is published in the corpus proof.")
  (witness "Ε-Μ2 ΠΡΟΣΤΑΚΤΙΚΗ διδασκαλία με το ίδιο το όνομα ΚΑΤΑΓΓΕΛΛΕΤΑΙ" '(2)
           "k = floor(n/2)"
           "if the level has an odd count, apply duplicate-last before hashing."
           "repeat until one hash remains.")
  (witness "Ε-Μ3 ΑΠΑΓΟΡΕΥΣΗ στην ίδια γραμμή ΔΕΝ καταγγέλλεται" '()
           "περιττός κόμβος: unbalanced split (RFC 9162), ΟΧΙ duplicate-last")
  (witness "Ε-Μ4 δείκτης ΜΕΤΑΛΛΑΞΗΣ στο παράθυρο ΔΕΝ καταγγέλλεται" '()
           ";; ΜΑΡΤΥΡΑΣ ΜΕΤΑΛΛΑΞΗΣ — μεταλλαγμένο σώμα υπό δοκιμή"
           "duplicate-last: περιττός ⇒ ζευγάρι με τον εαυτό του")
  (witness "Ε-Μ5 δείκτης στο ΟΡΙΟ του παραθύρου (±3) ΔΕΝ καταγγέλλεται" '()
           "ΑΠΑΓΟΡΕΥΕΤΑΙ ΑΠΟΛΥΤΩΣ:" "" ""
           "duplicate-last")
  (witness "Ε-Μ6 δείκτης ΕΞΩ από το παράθυρο (4 γραμμές) ΚΑΤΑΓΓΕΛΛΕΤΑΙ" '(6)
           "ΑΠΑΓΟΡΕΥΕΤΑΙ ΑΠΟΛΥΤΩΣ:" "" "" "" ""
           "duplicate-last is applied to the odd leaf")
  (witness "Ε-Μ7 ΠΟΛΛΑΠΛΕΣ παραβάσεις αναφέρονται ΟΛΕΣ, με ακριβή θέση" '(1 9)
           "duplicate last is the rule here" "" "" "" "" "" "" ""
           "an odd node pairs with itself")
  (witness "Ε-Μ8 ΚΕΦΑΛΑΙΑ ΑΤΟΝΑ ελληνικά μετρούν ως πολικότητα (folding)" '()
           "ΑΠΑΓΟΡΕΥΕΤΑΙ ΑΠΟΛΥΤΩΣ ΤΟ duplicate-last")
  (witness "Ε-Μ9 πεζά ΤΟΝΙΣΜΕΝΑ ελληνικά μετρούν ως πολικότητα (folding)" '()
           "μάρτυρας μετάλλαξης: duplicate-last"))

;; ── Ε2. ΚΑΘΕ ΑΡΧΕΙΟ ΜΕ ΦΟΡΜΟΥΛΑ ΤΟΥ ΑΛΓΟΡΙΘΜΟΥ ΔΕΝΕΤΑΙ ΣΤΟ ΚΑΝΟΝΙΚΟ PROFILE ──
;; Φόρμουλα = (i) MTH(-σημειογραφία του RFC, οπουδήποτε, ή (ii) hash-συνένωση
;; (‖ ή ||) με «sha» στην ΙΔΙΑ γραμμή, μέσα σε Merkle/RFC-6962/9162 συμφραζόμενα
;; (±3 γραμμές — αλλιώς π.χ. η αλυσίδα του journal, που ΔΕΝ είναι Merkle, θα
;; δενόταν λαθεμένα). Αρχείο με φόρμουλα ΧΩΡΙΣ το όνομα του profile = ΑΠΟΤΥΧΙΑ:
;; κάθε περιγραφή οφείλει να δείχνει στη ΜΙΑ πηγή, ώστε το drift να είναι
;; ελέγξιμο απέναντι στα byte-checked παραγόμενα.

(defparameter +profile-id-string+ "lawmax-merkle-sha256-v1")

(defun %e2-context-p (lines i)
  (loop for j from (max 0 (- i +dup-window+))
          to (min (1- (length lines)) (+ i +dup-window+))
        thereis (let ((l (aref lines j)))
                  (or (search "merkle" l) (search "mth" l)
                      (search "rfc 6962" l) (search "rfc-6962" l)
                      (search "rfc 9162" l) (search "rfc-9162" l)))))

(defun %e2-formula-lines (lines)
  "1-based γραμμές που ΓΡΑΦΟΥΝ φόρμουλα του αλγορίθμου (folded είσοδος)."
  (loop for i below (length lines)
        for l = (aref lines i)
        when (or (search "mth(" l)
                 (and (or (search "‖" l) (search "||" l))
                      (search "sha" l)
                      (%e2-context-p lines i)))
          collect (1+ i)))

(defun %e2-bound-p (lines)
  (loop for l across lines thereis (search +profile-id-string+ l)))

(let ((unbound '()) (bearing 0))
  (dolist (f (%mst-authored-files))
    (handler-case
        (let* ((lines (%mst-lines f))
               (fl (%e2-formula-lines lines)))
          (when fl
            (incf bearing)
            (unless (%e2-bound-p lines)
              (push (cons (namestring f) fl) unbound))))
      (error () nil)))
  (dolist (u unbound)
    (format t "    ✗ φόρμουλα ΧΩΡΙΣ δέσμευση στο profile: ~A γραμμές ~{~D~^, ~}~%"
            (car u) (cdr u)))
  (check (format nil "Ε2 κάθε formula-bearing αρχείο ονομάζει το προφίλ (~D αρχεία με φόρμουλα)"
                 bearing)
         (null unbound)))

;; Ε2-ΜΑΡΤΥΡΕΣ: ο κανόνας αποδεικνύεται μη-κενός σε συνθετικό κείμενο.
(macrolet ((fwitness (name expected &rest lines)
             `(check ,name (equal ,expected (%e2-formula-lines (%dup-fixture ,@lines))))))
  (fwitness "Ε2-Μ1 περιγραφή ΧΩΡΙΣ prefixes (η αυθεντική 2η αστοχία) ΑΝΙΧΝΕΥΕΤΑΙ" '(2 3)
            "## The Merkle commitment"
            "leaf = sha256( text )   and   node = sha256( l ‖ r )"
            "root = sha256( left ‖ right ) applied pairwise")
  (fwitness "Ε2-Μ3 αλυσίδα journal (ΟΧΙ Merkle) ΔΕΝ δένεται λαθεμένα" '()
            "journal: chained-append"
            "chain = sha256(prev ‖ 0x1f ‖ payload-hash)")
  (fwitness "Ε2-Μ4 σκέτη MTH( σημειογραφία πιάνεται ΠΑΝΤΟΥ" '(1)
            "mth(d[n]) = h(mth(d[0:k]) + mth(d[k:n]))"))
(check "Ε2-Μ2 η ονομαστική δέσμευση στο profile αίρει την καταγγελία"
       (%e2-bound-p (%dup-fixture "canonical profile lawmax-merkle-sha256-v1")))

;; ── Ε3. ΤΟ VERIFIER CENSUS ΚΑΡΦΩΝΕΤΑΙ ΑΝΕΞΑΡΤΗΤΑ (αντι-συρρίκνωση ratchet) ──
;; [ΕΥΡΗΜΑ ΚΡΙΤΗ #2] Το fixture του verify-proof-manifest δοκιμάζει ΣΥΝΘΕΤΙΚΑ
;; μητρώα· το ΠΡΑΓΜΑΤΙΚΟ docker/verifier-census.txt καρφώνεται ΕΔΩ, σε άλλη
;; σουίτα από τον verifier — «μικραίνω verifier και fixture μαζί» δεν αρκεί πια.
(let ((txt (handler-case (%mst-slurp (%mst-repo "docker/verifier-census.txt"))
             (error () ""))))
  (check "Ε3 verifier-census: δεσμεύει py+mjs Merkle verifiers, profile και vectors"
         (and (search "verify_merkle_py_sha256" txt)
              (search "deployment/verify/verify-merkle.py" txt)
              (search "verify_merkle_mjs_sha256" txt)
              (search "deployment/verify/verify-merkle.mjs" txt)
              (search "merkle_profile_sha256" txt)
              (search "deployment/verify/merkle-profile.sexp" txt)
              (search "merkle_vectors_sha256" txt)
              (search "deployment/verify/vectors/merkle/vectors.json" txt))))

(dolist (doc '("deployment/PROOF-CARRYING-LAW.md" "deployment/verify/README.md"))
  (let ((txt (%mst-slurp (%mst-repo doc))))
    (check (format nil "~A δηλώνει ΚΑΙ ΤΑ ΔΥΟ domain prefixes" doc)
           (and (search "0x00" txt) (search "0x01" txt)))
    (check (format nil "~A φέρει τον δείκτη GENERATED (μία πηγή)" doc)
           (search "BEGIN GENERATED lawmax-merkle-sha256-v1" txt))))

;; ── ΚΑΘΟΛΙΚΗ ΤΑΥΤΟΤΗΤΑ PROFILE ──
(check "το ΕΚΠΕΜΠΟΜΕΝΟ corpus-proof δηλώνει το ΚΑΝΟΝΙΚΟ profile (όχι rfc6962 alias)"
       (let ((src (%mst-slurp (%mst-repo "source/proof-carrying.lisp"))))
         (and (search "lawmax-merkle-sha256-v1" src)
              (not (search "sha256-merkle/rfc6962" src)))))

;; ── CENSUS ΠΑΡΑΓΩΓΩΝ ΡΙΖΩΝ: καμία αδήλωτη διαδρομή δημοσίευσης ──
;; [ΔΙΟΡΘΩΣΗ ΚΡΙΤΗ] Η αλλαγή του MTH([]) είναι ΚΑΘΟΛΙΚΗ· κάθε καλών του
;; πρωτόγονου πρέπει να είναι ΤΑΞΙΝΟΜΗΜΕΝΟΣ: είτε ΔΗΜΟΣΙΕΥΤΗΣ (οφείλει πύλη
;; κενού corpus) είτε ρητά ΕΣΩΤΕΡΙΚΟΣ. Αδήλωτος καλών = ΑΠΟΤΥΧΙΑ.
(defparameter +declared-root-callers+
  ;; (αρχείο . ρόλος) — ΚΑΘΕ παραγωγός Merkle ρίζας εκτός της έδρας.
  ;; :publisher = εκπέμπει δέσμευση προς τα έξω ⇒ ΟΦΕΙΛΕΙ άμυνα κενού συνόλου
  ;; :internal  = υπολογισμός/σύγκριση εντός συστήματος, καμία δημοσίευση
  '(("source/proof-carrying.lisp"                        :publisher "empty-corpus-publication")
    ("systems/orchestrator-epistemic/artifact-census.lisp" :publisher "κενό σύνολο άρθρων")
    ;; Ο legacy writer έχει αποσυρθεί μέσω %seat-removed. Το αρχείο παραμένει
    ;; μόνο reader/verifier παγωμένων logs και δεν δημοσιεύει πλέον ρίζες.
    ("systems/orchestrator-epistemic/transparency-log.lisp" :internal "")
    ("source/corpus-fingerprint.lisp"                    :internal "")
    ("source/legal-audit-system.lisp"                    :internal "")
    ("source/semantic-authority.lisp"                    :internal "")
    ("source/authority-proof-bundle.lisp"                :internal "")
    ("source/authority-evidence-replay.lisp"             :internal "")
    ("systems/orchestrator-epistemic/merkle-tree.lisp"   :internal "")
    ("systems/orchestrator-epistemic/release-spine.lisp" :internal "")
    ("systems/orchestrator-cli/version-graph-import.lisp" :internal "")))

(let* ((hits '()))
  (dolist (f (append (directory (%mst-repo "source/*.lisp"))
                     (directory (%mst-repo "systems/*/*.lisp"))))
    (let ((txt (handler-case (%mst-slurp f) (error () ""))))
      (when (and (or (search "merkle-root-of-strings" txt)
                     (search "merkle-root-of-files" txt)
                     (search "merkle-tree-hash" txt))
                 (not (search "merkle-authority.lisp" (namestring f))))
        (push (namestring f) hits))))
  (let* ((declared (mapcar #'first +declared-root-callers+))
         (undeclared (remove-if (lambda (h) (some (lambda (d) (search d h)) declared)) hits))
         (stale (remove-if (lambda (d) (some (lambda (h) (search d h)) hits)) declared)))
    (dolist (u undeclared) (format t "    ✗ ΑΔΗΛΩΤΟΣ παραγωγός ρίζας: ~A~%" u))
    (dolist (s stale) (format t "    ✗ stale δήλωση: ~A~%" s))
    (check (format nil "κάθε παραγωγός Merkle ρίζας ΤΑΞΙΝΟΜΗΜΕΝΟΣ (~D βρέθηκαν)" (length hits))
           (null undeclared))
    (check "καμία stale δήλωση στο μητρώο παραγωγών" (null stale))))

;; ΔΕΝ αρκεί η ΔΗΛΩΣΗ: για κάθε :publisher ΕΠΑΛΗΘΕΥΕΤΑΙ ότι η άμυνα κενού
;; συνόλου ΥΠΑΡΧΕΙ ΠΡΑΓΜΑΤΙΚΑ στο αρχείο του.
(dolist (entry +declared-root-callers+)
  (destructuring-bind (rel role marker) entry
    (when (eq role :publisher)
      (check (format nil "ΔΗΜΟΣΙΕΥΤΗΣ ~A φέρει άμυνα κενού συνόλου" rel)
             (let ((txt (handler-case (%mst-slurp (%mst-repo rel)) (error () ""))))
               (search marker txt))))))

(check "ο ΜΟΝΟΣ δηλωμένος ΔΗΜΟΣΙΕΥΤΗΣ φέρει την πύλη κενού corpus"
       (let ((src (%mst-slurp (%mst-repo "source/proof-carrying.lisp"))))
         (and (search "empty-corpus-publication" src)
              (search "(when (null provisions)" src))))

(format t "~%── merkle-single-truth: ~D passed, ~D failed ──~%" *pass* *fail*)
(sb-ext:exit :code (if (plusp *fail*) 1 0))
