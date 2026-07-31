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
                      ;; duplicate-last: επίπεδο-προς-επίπεδο, περιττό ⇒ ζευγάρι με εαυτό
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

(format t "~%== Ε. ΚΑΜΙΑ ΔΕΥΤΕΡΗ, ΑΝΤΙΦΑΤΙΚΗ ΠΕΡΙΓΡΑΦΗ ==~%")

;; Σάρωση των κειμένων για τη ΔΙΔΑΣΚΑΛΙΑ του duplicate-last. Ο έλεγχος είναι
;; σκόπιμα κειμενικός: το εύρημα ΗΤΑΝ κειμενικό (τα κείμενα δίδασκαν λάθος
;; αλγόριθμο ενώ ο κώδικας έκανε το σωστό).
(defun %teaches-duplicate-last-p (path)
  (let ((txt (string-downcase (%mst-slurp path))))
    (and (or (search "paired with itself" txt)
             (search "pairs with itself" txt)
             (search "duplicate-last" txt))
         ;; επιτρέπεται ΜΟΝΟ ως ΑΠΑΓΟΡΕΥΣΗ (never/forbidden/ΑΠΑΓΟΡΕΥΕΤΑΙ/CVE)
         (not (or (search "never duplicate-last" txt)
                  (search "forbidden" txt)
                  (search "cve-2012-2459" txt))))))

(dolist (doc '("deployment/PROOF-CARRYING-LAW.md" "deployment/verify/README.md"))
  (check (format nil "~A ΔΕΝ διδάσκει duplicate-last" doc)
         (not (%teaches-duplicate-last-p (%mst-repo doc)))))

(dolist (doc '("deployment/PROOF-CARRYING-LAW.md" "deployment/verify/README.md"))
  (let ((txt (%mst-slurp (%mst-repo doc))))
    (check (format nil "~A δηλώνει ΚΑΙ ΤΑ ΔΥΟ domain prefixes" doc)
           (and (search "0x00" txt) (search "0x01" txt)))
    (check (format nil "~A φέρει τον δείκτη GENERATED (μία πηγή)" doc)
           (search "BEGIN GENERATED lawmax-merkle-sha256-v1" txt))))

(format t "~%── merkle-single-truth: ~D passed, ~D failed ──~%" *pass* *fail*)
(sb-ext:exit :code (if (plusp *fail*) 1 0))
