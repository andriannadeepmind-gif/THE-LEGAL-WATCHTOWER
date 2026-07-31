(require :asdf) (require :sb-posix)
(defvar cl-user::*root* (uiop:ensure-directory-pathname (or (uiop:getenv "LAWMAX_REPO") (uiop:getcwd))))
(setf asdf:*central-registry*
      (append (list cl-user::*root*) (directory (merge-pathnames "systems/*/" cl-user::*root*))))
(asdf:initialize-source-registry
 `(:source-registry (:tree ,(merge-pathnames "third-party/" cl-user::*root*)) :inherit-configuration))
(locally (declare (sb-ext:muffle-conditions sb-ext:compiler-note style-warning warning))
  (handler-bind ((warning #'muffle-warning))
    (asdf:load-system :alexandria) (asdf:load-system :log4cl)
    (asdf:load-system :orchestrator-epistemic)))
;; ⑤ CORRUPTION MUTANTS πάνω στα ΠΑΓΩΜΕΝΑ bytes: κάθε αλλοίωση ⇒ ο reader ΚΟΚΚΙΝΟΣ.
(let* ((fx (merge-pathnames "authority-v2/fixtures/legacy-tlog/tlog-n3.json" cl-user::*root*))
       (genuine (uiop:read-file-string fx))
       (rd (uiop:ensure-directory-pathname
            (merge-pathnames (format nil "l7mut-~D/" (random 100000000))
                             (uiop:temporary-directory))))
       (path (orchestrator.epistemic::%tlog-path rd))
       (killed 0) (total 0))
  (ensure-directories-exist rd)
  (flet ((try (mutant)
           (incf total)
           (alexandria:write-string-into-file mutant path :if-exists :supersede)
           (when (handler-case (progn (orchestrator.epistemic:tlog-verify rd) nil)
                   (error () t))
             (incf killed))))
    ;; (α) flip σε entry  (β) flip σε log_root  (γ) flip σε checkpoint
    ;; (δ) αποκοπή        (ε) σκουπίδι
    (let ((i (search "sha256:" genuine)))
      (try (let ((s (copy-seq genuine)))
             (setf (char s (+ i 10)) (if (char= (char s (+ i 10)) #\a) #\b #\a)) s)))
    (let ((i (search "\"log_root\":\"sha256:" genuine)))
      (try (let ((s (copy-seq genuine)))
             (setf (char s (+ i 22)) (if (char= (char s (+ i 22)) #\c) #\d #\c)) s)))
    ;; ΑΚΡΙΒΗΣ στόχος: το ΠΡΩΤΟ hex ψηφίο του log_root ΤΟΥ ΠΡΩΤΟΥ checkpoint.
    (let* ((cp (search "\"checkpoints\":[" genuine))
           (lr (search "\"log_root\":\"sha256:" genuine :start2 cp))
           (i (+ lr (length "\"log_root\":\"sha256:"))))
      (try (let ((s (copy-seq genuine)))
             (setf (char s i) (if (char= (char s i) #\0) #\1 #\0)) s)))
    (try (subseq genuine 0 (floor (length genuine) 2)))
    (try "όχι JSON"))
  ;; Θετικός μάρτυρας: τα ΓΝΗΣΙΑ bytes ΠΡΕΠΕΙ να περνούν — αλλιώς οι φόνοι
  ;; θα ήταν άσχετοι (θα σκότωνε τα πάντα ένας σπασμένος reader).
  (alexandria:write-string-into-file genuine path :if-exists :supersede)
  (let ((genuine-ok (handler-case (eq t (orchestrator.epistemic:tlog-verify rd))
                      (error () nil))))
    (ignore-errors (uiop:delete-directory-tree rd :validate (constantly t)))
    (format t "~A~%"
            (cond ((not genuine-ok) "GENUINE-REJECTED(ο μάρτυρας θα ήταν κενός)")
                  ((< killed total) (format nil "SURVIVED ~D/~D" (- total killed) total))
                  (t (format nil "MUTANTS-KILLED ~D/~D + γνήσια bytes ΔΕΚΤΑ" killed total))))))
(sb-ext:exit :code 0)
