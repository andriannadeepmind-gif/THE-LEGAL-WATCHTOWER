;;;; tests/transparency-log-test.lisp
;;;; ============================================================================
;;;; L7-B — Transparency log των release roots + RFC 6962 §2.1.2 consistency
;;;; ============================================================================
;;;; Κλειδώνει: (α) τη μαθηματική έδρα consistency-proof/verify-consistency
;;;; (orchestrator.merkle — εξαντλητικά για κάθε 1 ≤ m ≤ n ≤ 20, με αρνητικά)·
;;;; (β) την έδρα log tlog-append-root!/tlog-verify (append-only, ιδεμποτές,
;;;; fail-closed σε ΚΑΘΕ διαφθορά αρχείου).

(in-package :orchestrator.epistemic)

(defvar *p* 0) (defvar *f* 0)
(defmacro ck (name form)
  `(handler-case (if ,form (progn (incf *p*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *f*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *f*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(format t "~%== [1] RFC 6962 §2.1.2 consistency — εξαντλητικά m≤n≤20 ==~%")
(let ((bad 0) (cases 0))
  (loop for n from 1 to 20 do
    (let ((leaves (loop for i below n
                        collect (orchestrator.merkle:hash-leaf-string
                                 (format nil "leaf-~D" i)))))
      (loop for m from 1 to n do
        (incf cases)
        (let* ((old (orchestrator.merkle:merkle-tree-hash (subseq leaves 0 m)))
               (new (orchestrator.merkle:merkle-tree-hash leaves))
               (proof (orchestrator.merkle:consistency-proof leaves m)))
          (unless (orchestrator.merkle:verify-consistency m n old new proof)
            (incf bad))
          (when (< m n)
            (when (orchestrator.merkle:verify-consistency
                   m n (orchestrator.merkle:hash-leaf-string "ξένο") new proof)
              (incf bad))
            (when (orchestrator.merkle:verify-consistency
                   m n old (orchestrator.merkle:hash-leaf-string "ξένο") proof)
              (incf bad))
            (when (and proof (orchestrator.merkle:verify-consistency
                              m n old new (rest proof)))
              (incf bad)))))))
  (ck (format nil "~D θετικές + 3× αρνητικές περιπτώσεις, 0 αποκλίσεις" cases)
      (zerop bad)))
(ck "υπερμήκες proof (έξτρα κόμβος στην ουρά) ⇒ NIL (εύρημα κριτή A0)"
    (let* ((leaves (loop for i below 7 collect
                         (orchestrator.merkle:hash-leaf-string (format nil "L~D" i))))
           (old (orchestrator.merkle:merkle-tree-hash (subseq leaves 0 3)))
           (new (orchestrator.merkle:merkle-tree-hash leaves))
           (proof (orchestrator.merkle:consistency-proof leaves 3)))
      (not (orchestrator.merkle:verify-consistency
            3 7 old new (append proof (list (orchestrator.merkle:hash-leaf-string "junk")))))))
(ck "κακοσχηματισμένο hash string στο proof ⇒ NIL, ΟΧΙ σφάλμα (εύρημα κριτή A5)"
    (let* ((leaves (list (orchestrator.merkle:hash-leaf-string "a")
                         (orchestrator.merkle:hash-leaf-string "b")))
           (new (orchestrator.merkle:merkle-tree-hash leaves)))
      (null (orchestrator.merkle:verify-consistency
             1 2 (first leaves) new (list "sha256:ΟΧΙ-hex")))))
(ck "m>n ⇒ NIL" (not (orchestrator.merkle:verify-consistency 5 3 "sha256:aa" "sha256:bb" '())))
(ck "m=n ⇒ μόνο ταυτότητα ριζών + κενό proof"
    (let* ((l (list (orchestrator.merkle:hash-leaf-string "a")))
           (r (orchestrator.merkle:merkle-tree-hash l)))
      (and (orchestrator.merkle:verify-consistency 1 1 r r '())
           (not (orchestrator.merkle:verify-consistency
                 1 1 r (orchestrator.merkle:hash-leaf-string "b") '())))))

(format t "~%== [2] tlog READER πάνω σε ΠΑΓΩΜΕΝΑ legacy bytes (Δ2) ==~%")
;; [Δ2] Ο δημιουργός: «Εξάλειψε %tlog-write* από production ASDF και χρησιμοποίησε
;; frozen legacy byte fixtures.» Ο παραγωγικός writer ΔΕΝ ΥΠΑΡΧΕΙ πλέον σε κανένα
;; ASDF system. Ένα test που τον ξαναέχτιζε (έστω «test-local») θα ήταν ανάσταση
;; της νεκρής έδρας. Εδώ ΔΕΝ κατασκευάζεται log: ΑΝΤΙΓΡΑΦΟΝΤΑΙ committed BYTES
;; με δεσμευμένο sha256 (authority-v2/fixtures/legacy-tlog/MANIFEST.json).
;; Ό,τι ελέγχεται είναι ο READER — που παραμένει χρήσιμος για evidence γένεσης.

(defun mk-root (i)
  (string-downcase (format nil "sha256:~64,'0X" i)))

(defparameter +tlog-fixture-dir+
  (merge-pathnames "authority-v2/fixtures/legacy-tlog/"
                   (uiop:ensure-directory-pathname
                    (or (uiop:getenv "LAWMAX_REPO") (uiop:getcwd)))))

(defun install-frozen-tlog! (rd n)
  "Αντιγράφει ΠΑΓΩΜΕΝΑ bytes legacy log (n entries) — καμία κατασκευή."
  (let ((src (merge-pathnames (format nil "tlog-n~D.json" n) +tlog-fixture-dir+))
        (dst (%tlog-path rd)))
    (unless (probe-file src) (error "ΑΠΟΝ frozen fixture ~A — fail-closed" src))
    (ensure-directories-exist dst)
    (with-open-file (in src :element-type '(unsigned-byte 8))
      (let ((buf (make-array (file-length in) :element-type '(unsigned-byte 8))))
        (read-sequence buf in)
        (with-open-file (out dst :direction :output :element-type '(unsigned-byte 8)
                                 :if-exists :supersede :if-does-not-exist :create)
          (write-sequence buf out))))
    dst))

(let ((rd (uiop:ensure-directory-pathname
           (merge-pathnames "tlog-test/" (uiop:temporary-directory)))))
  (uiop:delete-directory-tree rd :validate t :if-does-not-exist :ignore)
  (ensure-directories-exist rd)
  (ck "κενός κατάλογος ⇒ :absent (τίμιο, όχι σφάλμα)"
      (eq :absent (tlog-verify rd)))

  (install-frozen-tlog! rd 1)
  (multiple-value-bind (ok info) (tlog-verify rd)
    (ck "frozen n=1 ⇒ verify T, tree_size 1" (and (eq ok t) (= 1 (getf info :tree-size))))
    (ck "log_root n=1 = leaf(root1)"
        (string= (getf info :log-root) (orchestrator.merkle:hash-leaf-string (mk-root 1)))))

  (install-frozen-tlog! rd 3)
  (multiple-value-bind (ok info) (tlog-verify rd)
    (ck "frozen n=3 ⇒ verify T" (eq ok t))
    (ck "tree_size = 3" (= 3 (getf info :tree-size)))
    (ck "checkpoints = 2 (μεγέθη 1 και 2)" (= 2 (getf info :checkpoints))))

  (ck "tlog-append-root! ΚΑΤΑΡΓΗΘΗΚΕ ως authority seat (fail-closed, ΚΑΘΕ είσοδος)"
      (handler-case (progn (tlog-append-root! rd (mk-root 9)) nil)
        (orchestrator.epistemic:legacy-authority-seat-removed () t)
        (error () nil)))
  (ck "η άρνηση είναι ΚΑΘΟΛΙΚΗ — ακόμη και με έγκυρο root (όχι input validation)"
      (handler-case (progn (tlog-append-root! rd (mk-root 1)) nil)
        (orchestrator.epistemic:legacy-authority-seat-removed () t)
        (error () nil)))
  (ck "ΚΑΝΕΝΑΣ παραγωγικός writer: %tlog-write ΔΕΝ υπάρχει ως fbound σύμβολο"
      (let ((sym (find-symbol "%TLOG-WRITE" :orchestrator.epistemic)))
        (or (null sym) (not (fboundp sym)))))

  (format t "~%== [3] tlog: ΚΑΘΕ διαφθορά αρχείου ⇒ ΚΟΚΚΙΝΟ ==~%")
  (let* ((path (%tlog-path rd))
         (genuine (uiop:read-file-string path)))
    (alexandria:write-string-into-file
     (let ((pos (search (mk-root 1) genuine)))
       (concatenate 'string (subseq genuine 0 pos) (mk-root 9)
                    (subseq genuine (+ pos (length (mk-root 1))))))
     path :if-exists :supersede)
    (ck "αλλοιωμένο entry ⇒ ΣΦΑΛΜΑ"
        (handler-case (progn (tlog-verify rd) nil) (error () t)))
    (alexandria:write-string-into-file
     (let* ((pos (search "\"log_root\":\"sha256:" genuine)) (s (copy-seq genuine)))
       (setf (char s (+ pos 20)) (if (char= (char s (+ pos 20)) #\a) #\b #\a))
       s)
     path :if-exists :supersede)
    (ck "αλλοιωμένο log_root ⇒ ΣΦΑΛΜΑ"
        (handler-case (progn (tlog-verify rd) nil) (error () t)))
    (let ((pos (search "\"checkpoints\":[{\"size\":1,\"log_root\":\"sha256:" genuine)))
      (when pos
        (let* ((s2 (copy-seq genuine))
               (i (+ pos (length "\"checkpoints\":[{\"size\":1,\"log_root\":\"sha256:") 3)))
          (setf (char s2 i) (if (char= (char s2 i) #\f) #\e #\f))
          (alexandria:write-string-into-file s2 path :if-exists :supersede)))
      (ck "αλλοιωμένο checkpoint ⇒ ΣΦΑΛΜΑ"
          (or (null pos) (handler-case (progn (tlog-verify rd) nil) (error () t)))))
    (alexandria:write-string-into-file "όχι JSON" path :if-exists :supersede)
    (ck "άκυρο JSON ⇒ ΣΦΑΛΜΑ (ποτέ σιωπηλή επανεκκίνηση ιστορίας)"
        (handler-case (progn (tlog-verify rd) nil) (error () t)))
    ;; Επαναφορά ΠΑΓΩΜΕΝΩΝ bytes — η αλήθεια είναι τα committed fixtures.
    (install-frozen-tlog! rd 3)
    (multiple-value-bind (ok info) (tlog-verify rd)
      (ck "επαναφορά frozen bytes ⇒ n=3, 2 checkpoints, όλα συνεπή"
          (and (eq ok t) (= 3 (getf info :tree-size)) (= 2 (getf info :checkpoints)))))))

(format t "~%== [4] Εξωτερικός verifier: παλιό log_root ⊑ σημερινό (η ΟΥΣΙΑ) ==~%")
(let* ((roots (loop for i from 1 to 7 collect (mk-root i)))
       (leaves (mapcar (lambda (r) (orchestrator.merkle:hash-leaf-string r)) roots))
       (old-size 3)
       (old-root (orchestrator.merkle:merkle-tree-hash (subseq leaves 0 old-size)))
       (new-root (orchestrator.merkle:merkle-tree-hash leaves))
       (proof (orchestrator.merkle:consistency-proof leaves old-size)))
  (ck "verifier με ΜΟΝΟ (m, old_root) αποδεικνύει την επέκταση"
      (orchestrator.merkle:verify-consistency old-size 7 old-root new-root proof))
  (ck "rewrite ιστορίας (αλλαγμένο 2ο φύλλο) ⇒ ΔΕΝ αποδεικνύεται"
      (let* ((forged (append (list (first leaves)
                                   (orchestrator.merkle:hash-leaf-string "ΑΛΛΟ"))
                             (cddr leaves)))
             (froot (orchestrator.merkle:merkle-tree-hash forged))
             (fproof (orchestrator.merkle:consistency-proof forged old-size)))
        (not (orchestrator.merkle:verify-consistency
              old-size 7 old-root froot fproof)))))

(format t "~%========================================~%")
(format t "Transparency log tests: ~D passed, ~D failed~%" *p* *f*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *f*) 0 1))
