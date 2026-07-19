;;;; source/corpus-intelligence.lisp
;;;; ============================================================================
;;;; CORPUS INTELLIGENCE — one MOP-discovered suite over every analysis layer
;;;; ============================================================================
;;;;
;;;; Across the system there are several independent intelligence/verification
;;;; layers — the cross-reference integrity graph, extraction-anomaly detection,
;;;; the AST structural validators, citation centrality. Each was a capability in
;;;; its own package, none surfaced together. This module unifies them behind ONE
;;;; CLOS + MOP protocol: a CORPUS-CHECK runs over the served legal-document and
;;;; returns a FINDING; the suite DISCOVERS every check via the metaobject
;;;; protocol (class-direct-subclasses) and runs them generically. A new check is
;;;; added by subclassing — zero changes here — exactly the open extensibility the
;;;; rest of the system is built on.
;;;;
;;;;   define-corpus-check   declare a check (id + title + body → finding)
;;;;   corpus-checks         MOP discovery of all checks
;;;;   run-corpus-intelligence   run them all over a document → findings
;;;;   format-intelligence-report / intelligence-json   human (Greek) + AI output
;;;;
;;;; Each check calls its underlying module DEFENSIVELY (find-symbol), so a layer
;;;; that is absent yields a :skipped finding instead of breaking the suite.
;;;; Deterministic (findings sorted by check id). Pure CLOS.
;;;; ============================================================================

(defpackage :orchestrator.intelligence
  (:use :cl)
  (:export
   ;; protocol
   #:corpus-check-class #:corpus-check #:define-corpus-check #:corpus-checks
   #:check-id #:check-title #:run-check
   ;; finding
   #:finding #:make-finding #:finding-p #:finding-check #:finding-title
   #:finding-status #:finding-count #:finding-summary #:finding-details
   ;; suite
   #:run-corpus-intelligence #:report-clean-p
   #:format-intelligence-report #:intelligence-json))

(in-package :orchestrator.intelligence)

;;; ----------------------------------------------------------------------------
;;; MOP: a metaclass carrying each check's id + human title
;;; ----------------------------------------------------------------------------

(defclass corpus-check-class (standard-class)
  ((check-id :initform :generic :accessor class-check-id)
   (title    :initform ""       :accessor class-check-title)))

(defmethod closer-mop:validate-superclass
    ((class corpus-check-class) (super standard-class)) t)
(defmethod closer-mop:validate-superclass
    ((class standard-class) (super corpus-check-class)) t)

(defclass corpus-check ()
  ()
  (:metaclass corpus-check-class)
  (:documentation "An intelligence/verification check over the served corpus."))

(defgeneric check-id (check)
  (:method ((c corpus-check)) (class-check-id (class-of c))))
(defgeneric check-title (check)
  (:method ((c corpus-check)) (class-check-title (class-of c))))

;;; ----------------------------------------------------------------------------
;;; finding
;;; ----------------------------------------------------------------------------

(defstruct finding
  "The outcome of one check. STATUS: :ok | :advisory | :issues | :skipped."
  (check :generic) (title "") (status :ok) (count 0) (summary "") (details nil))

(defgeneric run-check (check doc)
  (:documentation "Run CHECK over the served legal-document DOC → a FINDING."))

(defmacro define-corpus-check (name (id title) (doc-var) &body body)
  "Declare corpus-check NAME (ID + TITLE on the metaclass). BODY, over DOC-VAR and
   the local constructor FINDING, must return a FINDING. Any error becomes a
   :skipped finding so one broken layer never breaks the suite."
  `(progn
     (defclass ,name (corpus-check) () (:metaclass corpus-check-class))
     (setf (class-check-id (find-class ',name)) ,id
           (class-check-title (find-class ',name)) ,title)
     (defmethod run-check ((check ,name) ,doc-var)
       (declare (ignorable ,doc-var))
       (flet ((finding (&key (status :ok) (count 0) (summary "") details)
                (make-finding :check ,id :title ,title :status status
                              :count count :summary summary :details details)))
         (declare (ignorable (function finding)))
         (handler-case (progn ,@body)
           (error (e)
             (make-finding :check ,id :title ,title :status :skipped
                           :summary (format nil "δεν εκτελέστηκε: ~A" e))))))
     ',name))

(defun corpus-checks ()
  "All registered corpus-check classes, discovered via the MOP."
  (closer-mop:class-direct-subclasses (find-class 'corpus-check)))

(defun %fn (package name)
  "The function symbol NAME exported by PACKAGE, or NIL — defensive cross-module call."
  (let ((p (find-package package)))
    (and p (let ((s (find-symbol name p))) (and s (fboundp s) s)))))

;;; ----------------------------------------------------------------------------
;;; the concrete checks (each wraps an existing module, defensively)
;;; ----------------------------------------------------------------------------

(define-corpus-check reference-integrity-check (:references "Ακεραιότητα παραπομπών")
    (doc)
  (let ((fn (%fn :orchestrator.references "VERIFY-REFERENCES")))
    (if (null fn)
        (finding :status :skipped :summary "module references μη διαθέσιμο")
        (multiple-value-bind (ok unresolved) (funcall fn doc)
          (if ok
              (finding :summary "κάθε εσωτερική παραπομπή δένει σε υπαρκτό άρθρο")
              (finding :status :advisory :count (length unresolved)
                       :summary (format nil "~D παραπομπή(ές) δεν δένουν εσωτερικά (πιθανώς άλλος νόμος/καταργημένο)"
                                        (length unresolved))
                       :details unresolved))))))

(define-corpus-check anomaly-check (:anomalies "Ανωμαλίες εξαγωγής")
    (doc)
  (let ((fn (%fn :orchestrator.anomaly "DETECT-ANOMALIES")))
    (if (null fn)
        (finding :status :skipped :summary "module anomaly μη διαθέσιμο")
        (multiple-value-bind (ok findings) (funcall fn doc)
          (if ok
              (finding :summary "κανένα άρθρο με υπογραφή λάθους εξαγωγής")
              (finding :status :issues :count (length findings)
                       :summary (format nil "~D άρθρο(α) με πιθανό λάθος εξαγωγής" (length findings))
                       :details findings))))))

(define-corpus-check structure-check (:structure "Δομική εγκυρότητα (AST)")
    (doc)
  (let ((fn (%fn :orchestrator.ast-gate "VALIDATE-CORPUS-STRUCTURE")))
    (if (null fn)
        (finding :status :skipped :summary "module ast-gate μη διαθέσιμο")
        (multiple-value-bind (valid result) (funcall fn doc)
          (let* ((issues-fn (%fn :orchestrator.validate-ast "RESULT-ISSUES"))
                 (issues (and issues-fn (funcall issues-fn result))))
            (if valid
                (finding :summary "δομή άρθρων έγκυρη (AST Layer-4)")
                (finding :status :issues :count (length issues)
                         :summary (format nil "~D δομικό(ά) πρόβλημα(τα) στον κώδικα" (length issues))
                         :details issues)))))))

(define-corpus-check centrality-check (:centrality "Κεντρικότητα (κόμβοι-άρθρα)")
    (doc)
  (let ((fn (%fn :orchestrator.legal-qa "MOST-REFERENCED")))
    (if (null fn)
        (finding :status :skipped :summary "module legal-qa μη διαθέσιμο")
        (let ((hubs (getf (funcall fn doc :limit 5) :ranking)))
          (finding :status :advisory :count (length hubs)
                   :summary (if hubs
                                (format nil "κορυφαία άρθρα-κόμβοι: ~{~A~^, ~}"
                                        (mapcar (lambda (h)
                                                  (if (consp h)
                                                      (format nil "~A(~A)" (car h) (cdr h))
                                                      (princ-to-string h)))
                                                hubs))
                                "καμία εσωτερική παραπομπή προς ιεράρχηση")
                   :details hubs)))))

;;; ----------------------------------------------------------------------------
;;; the suite
;;; ----------------------------------------------------------------------------

(defun run-corpus-intelligence (doc)
  "Run every registered corpus-check (MOP-discovered) over DOC, returning the list
   of findings sorted by check id (deterministic)."
  (sort (loop for class in (corpus-checks)
              collect (run-check (make-instance class) doc))
        #'string< :key (lambda (f) (string (finding-check f)))))

(defun report-clean-p (findings)
  "T when no finding reports real :issues (advisories / skips do not count)."
  (notany (lambda (f) (eq (finding-status f) :issues)) findings))

(defun %glyph (status)
  (ecase status (:ok "✓") (:advisory "ℹ") (:issues "✗") (:skipped "·")))

(defun format-intelligence-report (findings &optional (stream nil))
  "A human (Greek) summary of the intelligence FINDINGS."
  (format stream "═══ ΑΝΑΦΟΡΑ ΝΟΗΜΟΣΥΝΗΣ ΚΩΔΙΚΑ ═══~%~{~A~%~}~A"
          (loop for f in findings
                collect (format nil "  ~A ~A — ~A"
                                (%glyph (finding-status f))
                                (finding-title f) (finding-summary f)))
          (if (report-clean-p findings)
              "── καθαρός κώδικας (καμία δομική ανωμαλία) ──"
              "── υπάρχουν ζητήματα προς έλεγχο ──")))

;; [ΒΑΣΗ Β.2] Η τοπική %json-escape ΣΒΗΣΤΗΚΕ → ΜΙΑ έδρα orchestrator.spec:
;; json-string-escape (byte-identical). Μία είσοδος ανά λειτουργία.

(defun intelligence-json (findings)
  "An AI-consumable JSON array of the FINDINGS."
  (with-output-to-string (o)
    (write-string "[" o)
    (loop for f in findings for firstp = t then nil
          do (unless firstp (write-string "," o))
             (format o "{\"check\":\"~A\",\"status\":\"~A\",\"count\":~D,\"summary\":\"~A\"}"
                     (string-downcase (string (finding-check f)))
                     (string-downcase (string (finding-status f)))
                     (finding-count f)
                     (orchestrator.spec:json-string-escape (finding-summary f))))
    (write-string "]" o)))
