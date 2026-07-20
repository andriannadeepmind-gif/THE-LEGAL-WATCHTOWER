;;;; tests/audit-signature-failclosed-test.lisp
;;;; ============================================================================
;;;; REGRESSION LOCK — [Blocker#1] audit signature fail-CLOSED (no forgery)
;;;; ============================================================================
;;;; Κλειδώνει και τις δύο πλευρές που έκλεισαν το fail-open:
;;;;   (sign) configured crypto key + signing failure ⇒ ΣΗΜΑ, ΟΧΙ σιωπηλή
;;;;          υποβάθμιση σε forgeable "SIGNED:actor:hash".
;;;;   (verify) όταν public key configured, legacy "SIGNED:" ⇒ ΑΠΟΡΡΙΨΗ.
;;;;   (legacy) χωρίς key: legacy sign+verify δουλεύει (backwards-compat, αμετάβλητο).
;;;; Self-contained· exit 0/1.

(in-package :orchestrator.audit)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun %mk-entry (actor)
  ;; explicit LOCAL-TIME timestamp (compute-entry-hash formats it via
  ;; format-rfc3339-timestring); other slots via initform.
  (make-instance 'audit-entry
                 :timestamp (local-time:parse-timestring "2020-01-01T00:00:00Z")
                 :activity-type :test :actor actor :target "target"
                 :action "action" :result :ok :previous-hash "genesis"))

(format t "~%== [Blocker#1] audit signature fail-closed ==~%")

;; (legacy) πλήρως συμβατό όταν ΚΑΝΕΝΑ key δεν είναι configured
(let ((*signing-private-key-path* nil)
      (*signing-public-key-path* nil)
      (e (%mk-entry "alice")))
  (let ((sig (sign-entry e)))
    (check "legacy mode: sign → «SIGNED:» format" (and (stringp sig) (search "SIGNED:" sig)))
    (setf (entry-signature e) sig)
    (check "legacy mode: γνήσια legacy υπογραφή επαληθεύεται" (verify-signature e))
    ;; παραποίηση actor ⇒ δεν επαληθεύεται
    (setf (slot-value e 'actor) "mallory")
    (check "legacy mode: παραποιημένο περιεχόμενο ⇒ ΟΧΙ έγκυρο" (not (verify-signature e)))))

;; (sign fail-closed) configured crypto key + signing αποτυχία ⇒ ΣΗΜΑ (όχι forgeable)
(let ((*signing-private-key-path* "/nonexistent/definitely-not-a-key.pem")
      (e (%mk-entry "alice")))
  (check "crypto configured + signing fails ⇒ ΣΗΜΑ (καμία σιωπηλή υποβάθμιση)"
         (handler-case (progn (sign-entry e) nil)   ; αν επιστρέψει ⇒ FAIL (forgeable downgrade)
           (error () t))))

;; (verify fail-closed) όταν public key configured, forged legacy "SIGNED:" ⇒ ΑΠΟΡΡΙΨΗ
(let ((*signing-public-key-path* "/some/configured/pub.pem")
      (e (%mk-entry "attacker")))
  ;; ο επιτιθέμενος φτιάχνει το legacy string από ΔΗΜΟΣΙΑ πεδία
  (setf (entry-signature e) (format nil "SIGNED:~A:~A" (entry-actor e) (compute-entry-hash e)))
  (check "crypto configured: πλαστό legacy «SIGNED:» ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ (όχι ευλογία)"
         (not (verify-signature e))))

(format t "~%audit fail-closed tests: ~D passed, ~D failed~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
