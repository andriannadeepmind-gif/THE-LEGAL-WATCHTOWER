;;;; ASDF RESOLUTION MANIFEST — system → ακριβές .asd → sha256 → registry authority
;;;;
;;;; ΓΙΑΤΙ: για να αποδειχθεί ότι ο evaluator runner ΔΕΝ επιλύει κανένα system
;;;; διαφορετικά από την παραγωγή, και ότι ΔΕΝ δημιουργήθηκε δεύτερη έδρα
;;;; εξαρτήσεων. Δεν φορτώνει· ΕΠΙΛΥΕΙ (find-system) — αυτό μετράει εδώ.
(require :asdf)
(require :sb-posix)

(setf asdf:*central-registry*
      (list #p"/app/" #p"/app/systems/orchestrator-spec/" #p"/app/systems/orchestrator-model/"
            #p"/app/systems/orchestrator-core/" #p"/app/systems/orchestrator-engine-sbcl/"
            #p"/app/systems/orchestrator-cli/" #p"/app/systems/orchestrator-meta/"
            #p"/app/systems/orchestrator-ai-core/" #p"/app/systems/orchestrator-infrastructure/"
            #p"/app/systems/orchestrator-omega-modules/" #p"/app/systems/orchestrator-epistemic/"
            #p"/app/systems/orchestrator-gr-syntagma/" #p"/app/tests/"))

(defun sha256-hex (path)
  (let ((p (sb-ext:run-program "/usr/bin/sha256sum" (list (namestring path))
                               :output :stream :search nil :wait t)))
    (let ((line (read-line (sb-ext:process-output p) nil "")))
      (subseq line 0 (position #\Space line)))))

(defun authority-of (path)
  (let ((s (namestring path)))
    (cond ((search "/app/third-party/" s)           :third-party-tree)
          ((search "/app/source/cl-dependencies/" s) :cl-dependencies-tree)
          ((search "/app/systems/" s)                :central-registry-systems)
          ((search "/app/tests/" s)                  :central-registry-tests)
          ((search "/app/" s)                        :central-registry-root)
          (t                                         :OUTSIDE-CORPUS))))

(defun closure (roots)
  (let ((seen (make-hash-table :test #'equal)) (out '()))
    (labels ((walk (name)
               (let ((key (string-downcase (string name))))
                 (unless (gethash key seen)
                   (setf (gethash key seen) t)
                   (let ((sys (ignore-errors (asdf:find-system name nil))))
                     (if (null sys)
                         (push (list key :UNRESOLVED nil nil) out)
                         (let ((f (asdf:system-source-file sys)))
                           (push (list key
                                       (if f (namestring f) :NO-SOURCE-FILE)
                                       (if f (sha256-hex f) nil)
                                       (if f (authority-of f) :BUILT-IN))
                                 out)
                           (dolist (d (ignore-errors (asdf:system-depends-on sys)))
                             (let ((n (typecase d (cons (second d)) (t d))))
                               (when (or (stringp n) (symbolp n)) (walk n)))))))))))
      (dolist (r roots) (walk r))
      (sort out #'string< :key #'first))))

(let* ((roots (or (cdr (member "--roots" sb-ext:*posix-argv* :test #'string=))
                  '("orchestrator" "orchestrator-cli" "orchestrator-tests"
                    "orchestrator-infrastructure" "orchestrator-epistemic"
                    "orchestrator-omega" "orchestrator-core" "orchestrator-model"
                    "orchestrator-spec" "orchestrator-meta" "orchestrator-ai-core"
                    "orchestrator-engine-sbcl" "orchestrator-gr-syntagma"
                    "orchestrator-core-runtime" "orchestrator-tests-runtime"
                    "orchestrator-tooling")))
       (rows (closure roots)))
  (format t "~&(:lawmax-asdf-resolution/1~%")
  (format t " :registry-conf ~S~%"
          (or (ignore-errors
                (with-open-file (in "/root/.config/common-lisp/source-registry.conf.d/10-third-party.conf")
                  (with-output-to-string (o)
                    (loop for l = (read-line in nil) while l do (format o "~a " l)))))
              "ΑΠΟΝ"))
  (format t " :roots ~D :resolved ~D~%" (length roots) (length rows))
  (format t " :systems~% (")
  (dolist (r rows)
    (format t "(:system ~S :asd ~S :sha256 ~S :authority ~S)~%  "
            (first r) (second r) (or (third r) "") (fourth r)))
  (format t "))~%"))
