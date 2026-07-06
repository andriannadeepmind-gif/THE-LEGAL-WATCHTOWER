;;;; systems/orchestrator-cli/gates-runner.lisp
;;;; ============================================================================
;;;; Η ΟΛΟΜΕΛΕΙΑ ΤΩΝ ΠΥΛΩΝ: --gates — το 100% του συστήματος με ΜΙΑ εντολή
;;;; ============================================================================
;;;;
;;;; Παράγωγο από το μητρώο εντολών, ΟΧΙ χειρόγραφη λίστα: τρέχει ό,τι
;;;; λήγει σε «-gate», αλφαβητικά (ντετερμινιστικά). Νέα πύλη = αυτόματα
;;;; μέλος της ολομέλειας — καμία δεύτερη λίστα προς συντήρηση, κανένα
;;;; σημείο όπου μια πύλη «ξεχνιέται». Κόκκινο αν ΟΠΟΙΑΔΗΠΟΤΕ αποτύχει.

(in-package :orchestrator.cli)

(defun run-all-gates ()
  "--gates : όλες οι εγγεγραμμένες πύλες, μία-μία, με ενιαία ετυμηγορία."
  (let ((names '()))
    (maphash (lambda (k v)
               (declare (ignore v))
               (when (and (> (length k) 5)
                          (string= "-gate" k :start2 (- (length k) 5)))
                 (push k names)))
             *commands*)
    (setf names (sort names #'string<))
    (let ((results
            (mapcar (lambda (name)
                      (let ((rc (funcall (gethash name *commands*) nil)))
                        ;; ΙΧΝΟΣ ΠΥΛΗΣ: κάθε κρίση της ολομέλειας αφήνει προέλευση
                        (orchestrator.trace:emit! :gate
                         :symbol name :package "orchestrator.cli"
                         :source "systems/orchestrator-cli/gates-runner.lisp"
                         :data (list :gate name :exit rc
                                     :verdict (if (eql rc 0) :passed :failed)))
                        (cons name rc)))
                    names)))
      (format t "~%════ ΟΛΟΜΕΛΕΙΑ ΠΥΛΩΝ (~D) ════~%" (length results))
      (let ((failed nil))
        (dolist (r results)
          (let ((bad (not (eql 0 (cdr r)))))   ; ό,τι δεν είναι ρητό 0 = αποτυχία
            (when bad (setf failed t))
            (format t "  ~A: ~:[ΠΕΡΑΣΕ~;ΑΠΕΤΥΧΕ~]~%" (car r) bad)))
        (if failed 1 0)))))

(register-command "--gates" (lambda (a) (declare (ignore a)) (run-all-gates)))
