;;;; tests/jws-strict-grammar-test.lisp
;;;; ============================================================================
;;;; JWS STRICT COMPACT GRAMMAR + MANDATORY KID + RESERVED-HEADER PROTECTION
;;;; ============================================================================
;;;; Κλειδώνει τα 3 κλεισίματα της αντιπαλικής επιθεώρησης (κύκλος-2) στην έδρα
;;;; orchestrator.jws-authority:
;;;;   (1) verify-jws: ΑΚΡΙΒΩΣ 3 compact segments (header.payload.signature)· token με
;;;;       2 ή 4+ segments ⇒ invalid-signature (όχι σιωπηλή αποδοχή first/second/third).
;;;;   (2) mandatory ΜΗ-ΚΕΝΟ signed kid σε sign+verify· χωρίς kid ⇒ σφάλμα (η αποθηκευμένη
;;;;       ταυτότητα κλειδιού δεν γίνεται nil==nil σιωπηλή αποδοχή).
;;;;   (3) απαγόρευση duplicate reserved header (alg/typ/kid) στα extra-headers του sign-jws.
;;;; Gated: απαιτεί ironclad/babel/jonathan (full build). Self-contained key generation.

(in-package :orchestrator.jws-authority)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))
(defmacro check-signals (name condition-type form)
  `(check ,name (handler-case (progn ,form nil) (,condition-type () t))))

(format t "~%== JWS strict grammar + mandatory kid + reserved-header protection ==~%")

(let* ((kp (generate-rsa-keypair :bits 2048))
       (priv (getf kp :private-key))
       (pub (getf kp :public-key)))
  (let* ((payload "the-signed-statement")
         (signed (sign-jws payload priv :kid "signer-A"))
         (jws (getf signed :jws)))

    ;; ── baseline: γνήσιο detached JWS επαληθεύεται ──
    (check "baseline: γνήσιο detached JWS επαληθεύεται" (verify-jws jws payload pub))

    ;; ── (1) STRICT compact grammar: ακριβώς 3 segments ──
    (check-signals "2 segments (header.signature) ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" invalid-signature
                   (verify-jws (format nil "~A.~A" "aGVhZGVy" "c2ln") payload pub))
    (check-signals "4 segments ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ (κανένα trailing αγνοείται)" invalid-signature
                   (verify-jws (format nil "~A.extra" jws) payload pub))
    (check-signals "1 segment ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" invalid-signature
                   (verify-jws "onlyonesegment" payload pub))
    (check-signals "κενό header segment ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" invalid-signature
                   (verify-jws (format nil ".~A.~A" payload "c2ln") payload pub))
    (check-signals "κενό signature segment ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" invalid-signature
                   (verify-jws (format nil "~A.~A." "aGVhZGVy" payload) payload pub))

    ;; ── (2) mandatory μη-κενό signed kid ──
    ;; sign-jws χωρίς/κενό kid ⇒ jws-error
    (check-signals "sign-jws με κενό kid ⇒ jws-error" jws-error
                   (sign-jws payload priv :kid ""))
    (check-signals "sign-jws με nil kid ⇒ jws-error" jws-error
                   (sign-jws payload priv :kid nil))
    ;; ένα JWS με kid στο header επαληθεύεται· το jws-protected-kid το βγάζει
    (check "jws-protected-kid βγάζει το signed kid" (equal "signer-A" (jws-protected-kid jws)))

    ;; ── (3) απαγόρευση duplicate reserved fields στα extra-headers ──
    (check-signals "extra-header :|alg| ⇒ jws-error (reserved collision)" jws-error
                   (sign-jws payload priv :kid "x" :extra-headers '(:|alg| "HS256")))
    (check-signals "extra-header :|kid| ⇒ jws-error (reserved collision)" jws-error
                   (sign-jws payload priv :kid "x" :extra-headers '(:|kid| "other")))
    (check-signals "extra-header :|typ| ⇒ jws-error (reserved collision)" jws-error
                   (sign-jws payload priv :kid "x" :extra-headers '(:|typ| "JWT")))
    ;; μη-reserved extra header επιτρέπεται (δεν σπάει)
    (check "μη-reserved extra-header (:|cty|) επιτρέπεται"
           (let ((s (sign-jws payload priv :kid "x" :extra-headers '(:|cty| "application/json"))))
             (and (getf s :jws) (verify-jws (getf s :jws) payload pub))))))

(format t "~%jws-strict-grammar: ~D passed, ~D failed~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
