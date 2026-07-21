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

(defun %gate-name->keyword (name)
  "«--advisor-gate» → :ADVISOR-GATE — strip leading dashes· keyword για data-only manifest."
  (intern (string-upcase (string-left-trim "-" name)) :keyword))

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
        ;; [κύκλος-2 #7] MACHINE-READABLE canonical verdict manifest (data-only, safe-read-able).
        ;; Τυπώνεται ΜΟΝΟ εδώ, ΜΕΤΑ από ΟΛΕΣ τις πύλες ⇒ το :completed t είναι θετική απόδειξη
        ;; ολοκλήρωσης: crash/OOM στη μέση ⇒ ΚΑΝΕΝΑ manifest ⇒ ο checker αποτυγχάνει (όχι
        ;; false-green). Ο assess-gate-manifest επιβάλλει exact set-equality με το canonical
        ;; gate-registry.sexp + κανένα duplicate + ακριβώς μία ετυμηγορία ανά πύλη.
        (let ((manifest (list :schema :gate-plenary/1
                              :completed t
                              :count (length results)
                              :results (mapcar (lambda (r)
                                                 (list (%gate-name->keyword (car r))
                                                       (if (eql 0 (cdr r)) :passed :failed)))
                                               results))))
          (format t "~%════ GATE-PLENARY-MANIFEST ════~%")
          ;; [κύκλος-3] ΜΙΑ έδρα data-only εγγραφής (data-to-string): συνέπεια με κάθε άλλο
          ;; writer + %data-only-p fail-closed (το manifest ΔΕΝ μπορεί να φέρει μη-data-only).
          (write-string (orchestrator.safe-read:data-to-string manifest))
          (format t "~%════ END-MANIFEST ════~%"))
        (if failed 1 0)))))

(register-command "--gates" (lambda (a) (declare (ignore a)) (run-all-gates)))
