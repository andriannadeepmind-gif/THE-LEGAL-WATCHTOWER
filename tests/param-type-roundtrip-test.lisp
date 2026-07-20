;;;; tests/param-type-roundtrip-test.lisp
;;;; ============================================================================
;;;; RUNTIME ROUND-TRIP GATE: coerce∘type-ok ([re-review adv2-F2])
;;;; ============================================================================
;;;; Ο static tri-directional gate (param-type-coercion-test) συγκρίνει ΜΟΝΟ τα key-sets
;;;; των [A]+param-types+ / [B]%type-ok-p / [C]%coerce-one — ΤΑΥΤΟΛΟΓΙΑ ως προς τη
;;;; ΣΗΜΑΣΙΟΛΟΓΙΑ: δεν ελέγχει ότι η ΕΞΟΔΟΣ του %coerce-one για έναν τύπο ΙΚΑΝΟΠΟΙΕΙ το
;;;; %type-ok-p του ΙΔΙΟΥ τύπου. Ο κριτής βρήκε ότι :keyword coerce-άριζε σε STRING ενώ το
;;;; %type-ok-p απαιτούσε keywordp ⇒ ΚΑΘΕ :keyword param έβγαζε 400 στο HTTP surface.
;;;; Αυτό το gate ΤΡΕΧΕΙ τις πραγματικές συναρτήσεις: για ΚΑΘΕ type ∈ +param-types+,
;;;; %type-ok-p(type, %coerce-one(type, sample)) πρέπει να είναι T (round-trip κλειστό).
;;;; Νέος τύπος χωρίς sample/round-trip ⇒ ΚΟΚΚΙΝΟ (δομικά αδύνατη σιωπηλή divergence).
;;;; Self-contained: stub-άρει την orchestrator.paths (μόνο το seat-collision guard τη
;;;; χρησιμοποιεί) και φορτώνει τις 2 έδρες — καθαρή CL, χωρίς full build.

;; SKIP αν λείπουν οι έδρες (self-contained, fresh sbcl).
(let* ((here (or *load-truename* *load-pathname*))
       (dir  (pathname-directory here)))
  (unless (and (probe-file (merge-pathnames "../source/capability-registry.lisp"
                                            (make-pathname :directory dir)))
               (probe-file (merge-pathnames "../source/capability-api.lisp"
                                            (make-pathname :directory dir))))
    (format t "~%  SKIP — capability seats απόντες.~%") (sb-ext:exit :code 0)))

;; Stub orchestrator.paths (μόνο το seat-collision guard τη χρησιμοποιεί). Top-level
;; forms ⇒ ο reader τα βλέπει με τη σειρά· fresh sbcl ⇒ καμία σύγκρουση με το full build.
(defpackage :orchestrator.paths (:use :cl)
  (:export #:current-load-file #:load-site-attributable-p #:+anonymous-load-site+))
(in-package :orchestrator.paths)
(defparameter +anonymous-load-site+ "<runtime>")
(defun current-load-file () "roundtrip-test/seat")
(defun load-site-attributable-p (s) (and (stringp s) (string/= s +anonymous-load-site+)))
(in-package :cl-user)

(let* ((here (or *load-truename* *load-pathname*))
       (dir  (pathname-directory here)))
  (handler-bind ((warning #'muffle-warning))
    (load (merge-pathnames "../source/capability-registry.lisp" (make-pathname :directory dir)))
    (load (merge-pathnames "../source/capability-api.lisp" (make-pathname :directory dir)))))

(defpackage :param-type-roundtrip-test (:use :cl))
(in-package :param-type-roundtrip-test)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defvar *cap* (orchestrator.capability::%make-capability
               :name :probe :trust :trusted :fn (lambda (&rest _) (declare (ignore _)) nil)))

;; Δηλωμένα representative samples ανά τύπο· ΚΑΘΕ type ∈ +param-types+ ΠΡΕΠΕΙ να έχει ένα.
;; [κύκλος-2] Το :keyword sample είναι ΗΔΗ-ΥΠΑΡΧΟΝ keyword ("string" → :STRING, μέλος του
;; +param-types+): μετά τη find-symbol διόρθωση (θάνατος intern-DoS) μόνο υπαρκτά keywords
;; coerce-άρουν· άγνωστη τιμή = 400. Το round-trip δείγμα ΠΡΕΠΕΙ να είναι υπαρκτό.
(defparameter *samples* '((:string . "hello") (:keyword . "string") (:any . "x")
                          (:integer . "42") (:boolean . "true")))

(format t "~%── RUNTIME ROUND-TRIP: coerce∘type-ok για ΚΑΘΕ +param-types+ ──~%")
(let ((types orchestrator.capability:+param-types+))
  (check "κάθε type ∈ +param-types+ έχει declared sample (νέος τύπος ⇒ coverage υποχρεωτικό)"
         (every (lambda (ty) (assoc ty *samples*)) types))
  (dolist (ty types)
    (let* ((s (cdr (assoc ty *samples*)))
           (coerced (orchestrator.capability-api::%coerce-one *cap* :p ty s)))
      (check (format nil "round-trip ~A: %type-ok-p(coerce(~S))=~S" ty s coerced)
             (orchestrator.capability::%type-ok-p ty coerced)))))

;; Το ΑΚΡΙΒΕΣ κενό F2: :keyword coerce-άρει σε keyword (όχι string), invoke ⇒ 200 όχι 400.
(check ":keyword coerce → keyword (όχι string)"
       (keywordp (orchestrator.capability-api::%coerce-one *cap* :p :keyword "foo")))
(check ":keyword \"foo\" → :FOO (upcased όπως ο reader σε CLI/MCP)"
       (eq :foo (orchestrator.capability-api::%coerce-one *cap* :p :keyword "foo")))
(orchestrator.capability:define-capability :kwcap
  :params ((:mode :keyword t)) :result :any :trust :trusted
  :fn (lambda (&key mode) (list :got mode)))
(multiple-value-bind (st payload)
    (orchestrator.capability-api:api-dispatch "/api/kwcap" '(("mode" . "fast")) :require-trust t)
  (check ":keyword-typed param invoke ⇒ 200 (ΟΧΙ 400 — το κενό F2)" (eql st 200))
  (check ":keyword param έφτασε ως :FAST στο :fn" (eq :fast (getf (getf payload :result) :got))))

;; [κύκλος-2] SECURITY: θάνατος intern-DoS — μη-υπαρκτό keyword value ⇒ coercion-error (400),
;; ΚΑΝΕΝΑ intern πάνω σε μη-έμπιστη είσοδο. (String literal, ΟΧΙ keyword literal ⇒ μένει uninterned.)
(check ":keyword άγνωστη τιμή ⇒ coercion-error (find-symbol=nil, κανένα intern)"
       (handler-case
           (progn (orchestrator.capability-api::%coerce-one *cap* :p :keyword "zzq-unknown-kw-xyzzy") nil)
         (orchestrator.capability-api::coercion-error () t)))
(check ":keyword άγνωστη τιμή ΔΕΝ γέμισε το keyword package (παραμένει uninterned)"
       (null (find-symbol "ZZQ-UNKNOWN-KW-XYZZY" :keyword)))

(format t "~%param-type-roundtrip: ~D passed, ~D failed~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
