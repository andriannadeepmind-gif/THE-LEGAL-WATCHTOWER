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

(format t "~%== [2] tlog: γένεση, ιδεμποτές append, checkpoints ==~%")
(defun mk-root (i)
  ;; πεζά hex — ΙΔΙΑ μορφή με την παραγωγή (%sha256-hex)· εύρημα κριτή B1:
  ;; τα fixtures δεν αποκλίνουν ποτέ από το πραγματικό σχήμα.
  (string-downcase (format nil "sha256:~64,'0X" i)))
(let ((rd (uiop:ensure-directory-pathname
           (merge-pathnames "tlog-test/" (uiop:temporary-directory)))))
  (uiop:delete-directory-tree rd :validate t :if-does-not-exist :ignore)
  (ensure-directories-exist rd)
  (ck "κενός κατάλογος ⇒ :absent (τίμιο, όχι σφάλμα)"
      (eq :absent (tlog-verify rd)))
  (let ((r1 (tlog-append-root! rd (mk-root 1))))
    (ck "append #1 ⇒ log_root = leaf (n=1)"
        (string= r1 (orchestrator.merkle:hash-leaf-string (mk-root 1))))
    (ck "ιδεμποτές: ξανά ίδιο root ⇒ ίδιο log_root, χωρίς διπλογραφή"
        (string= (tlog-append-root! rd (mk-root 1)) r1)))
  (tlog-append-root! rd (mk-root 2))
  (tlog-append-root! rd (mk-root 3))
  (multiple-value-bind (ok info) (tlog-verify rd)
    (ck "verify μετά από 3 appends ⇒ T" (eq ok t))
    (ck "tree_size = 3" (= 3 (getf info :tree-size)))
    (ck "checkpoints = 2 (μεγέθη 1 και 2)" (= 2 (getf info :checkpoints))))
  (ck "άκυρο root string ⇒ ΣΦΑΛΜΑ (fail-closed)"
      (handler-case (progn (tlog-append-root! rd "sha256:κοντό") nil)
        (error () t)))
  (ck "μη-hex χαρακτήρες (σωστό μήκος) ⇒ ΣΦΑΛΜΑ (εύρημα κριτή A4)"
      (handler-case
          (progn (tlog-append-root!
                  rd (concatenate 'string "sha256:" (make-string 64 :initial-element #\g)))
                 nil)
        (error () t)))

  (format t "~%== [3] tlog: ΚΑΘΕ διαφθορά αρχείου ⇒ ΚΟΚΚΙΝΟ ==~%")
  (let* ((path (%tlog-path rd))
         (genuine (uiop:read-file-string path)))
    ;; (α) αλλοίωση entry (rewrite ιστορίας)
    (alexandria:write-string-into-file
     (let ((pos (search (mk-root 1) genuine)))
       (concatenate 'string (subseq genuine 0 pos) (mk-root 9)
                    (subseq genuine (+ pos (length (mk-root 1))))))
     path :if-exists :supersede)
    (ck "αλλοιωμένο entry ⇒ ΣΦΑΛΜΑ"
        (handler-case (progn (tlog-verify rd) nil) (error () t)))
    ;; (β) αλλοιωμένο log_root
    (alexandria:write-string-into-file
     (let* ((doc genuine)
            (pos (search "\"log_root\":\"sha256:" doc))
            (s (copy-seq doc)))
       (setf (char s (+ pos 20)) (if (char= (char s (+ pos 20)) #\a) #\b #\a))
       s)
     path :if-exists :supersede)
    (ck "αλλοιωμένο log_root ⇒ ΣΦΑΛΜΑ"
        (handler-case (progn (tlog-verify rd) nil) (error () t)))
    ;; (β2) αλλοιωμένο checkpoint root (εύρημα κριτή B2)
    (let ((pos (search "\"checkpoints\":[{\"size\":1,\"log_root\":\"sha256:" genuine)))
      (when pos
        (let* ((s2 (copy-seq genuine))
               (i (+ pos (length "\"checkpoints\":[{\"size\":1,\"log_root\":\"sha256:") 3)))
          (setf (char s2 i) (if (char= (char s2 i) #\f) #\e #\f))
          (alexandria:write-string-into-file s2 path :if-exists :supersede)))
      (ck "αλλοιωμένο checkpoint ⇒ ΣΦΑΛΜΑ"
          (or (null pos)
              (handler-case (progn (tlog-verify rd) nil) (error () t)))))
    ;; (γ) σκουπίδι
    (alexandria:write-string-into-file "όχι JSON" path :if-exists :supersede)
    (ck "άκυρο JSON ⇒ ΣΦΑΛΜΑ (ποτέ σιωπηλή επανεκκίνηση ιστορίας)"
        (handler-case (progn (tlog-verify rd) nil) (error () t)))
    (ck "append πάνω σε άκυρο log ⇒ ΣΦΑΛΜΑ (το log ΔΕΝ ξαναγεννιέται σιωπηλά)"
        (handler-case (progn (tlog-append-root! rd (mk-root 4)) nil)
          (error () t)))
    ;; επαναφορά γνήσιου + έλεγχος ότι η αλυσίδα συνεχίζει
    (alexandria:write-string-into-file genuine path :if-exists :supersede)
    (tlog-append-root! rd (mk-root 4))
    (multiple-value-bind (ok info) (tlog-verify rd)
      (ck "μετά την επαναφορά: n=4, 3 checkpoints, όλα συνεπή"
          (and (eq ok t) (= 4 (getf info :tree-size))
               (= 3 (getf info :checkpoints)))))))

(format t "~%== [3.5] Γένεση με bootstrap από census αλυσίδα (εύρημα κριτή A1/B3) ==~%")
(let* ((rd (uiop:ensure-directory-pathname
            (merge-pathnames "tlog-genesis-test/" (uiop:temporary-directory))))
       (r1 (mk-root 101)) (r2 (mk-root 102)) (r3 (mk-root 103)))
  (uiop:delete-directory-tree rd :validate t :if-does-not-exist :ignore)
  ;; Ψεύτικη census-era ιστορία στο δίσκο: r1 ← r2 ← r3 (prev chain)
  (flet ((mkrel (root prev)
           (let ((d (merge-pathnames (format nil "sha256-~A/" (subseq root 7)) rd)))
             (ensure-directories-exist d)
             (alexandria:write-string-into-file
              (format nil "{\"prev_release_root\":~A}"
                      (if prev (format nil "\"~A\"" prev) "null"))
              (merge-pathnames "census.json" d) :if-exists :supersede))))
    (mkrel r1 nil) (mkrel r2 r1) (mkrel r3 r2))
  (tlog-append-root! rd r3)
  (multiple-value-bind (ok info) (tlog-verify rd)
    (ck "γένεση με tip r3 ⇒ bootstrap ΟΛΗΣ της αλυσίδας (n=3, σειρά r1,r2,r3)"
        (and (eq ok t)
             (equal (getf info :entries) (list r1 r2 r3)))))
  ;; Επίθεση διαγραφής: σβήσε το log, ξανα-promote r3 ⇒ η αλυσίδα ΞΑΝΑΧΤΙΖΕΤΑΙ
  (delete-file (%tlog-path rd))
  (tlog-append-root! rd r3)
  (multiple-value-bind (ok info) (tlog-verify rd)
    (ck "διαγραφή log + αναγέννηση ⇒ ΠΛΗΡΗΣ αλυσίδα ξανά (όχι κολοβό n=1)"
        (and (eq ok t)
             (equal (getf info :entries) (list r1 r2 r3))))))

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
