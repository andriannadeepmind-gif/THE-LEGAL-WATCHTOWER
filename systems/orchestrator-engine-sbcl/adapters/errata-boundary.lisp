;;;; systems/orchestrator-engine-sbcl/adapters/errata-boundary.lisp
;;;; ============================================================================
;;;; [Π7-U.1 Φ1γ / 0110] ΤΟ ΟΡΙΟ ΕΞΑΓΩΓΗΣ ΕΦΑΡΜΟΖΕΙ ΤΑ ΔΗΛΩΜΕΝΑ ERRATA — Η ΜΙΑ ΕΔΡΑ
;;;; ============================================================================
;;;; Η κλάση που σκοτώνεται: δύο μονοπάτια IIR από δυαδική πηγή (materialize vs
;;;; pipeline PDF-mode) όπου μόνο το ένα εφάρμοζε τα errata ⇒ τα artifacts του
;;;; pipeline ξανα-γεννούσαν τα διορθωμένα ελαττώματα (ζωντανό εύρημα δημιουργού:
;;;; άρθρο 4 Σ ξανά λάθος στο docker output ΠΑΡΑ τη διορθωμένη source.json).
;;;; ΔΟΜΙΚΗ λύση: τα errata εφαρμόζονται ΜΕΣΑ στους adapters (pdf/docx) — ΚΑΘΕ
;;;; καταναλωτής (materialize, pipeline, μελλοντικοί) τα κληρονομεί υποχρεωτικά.
;;;; Μεταφορά έδρας από orchestrator-cli/main.lisp (ίδια σημασιολογία:
;;;; ΑΚΡΙΒΩΣ-μία-φορά ταίριασμα, δυνατή αναφορά, stale ⇒ ΔΕΝ εφαρμόζεται/ΔΕΝ
;;;; μαντεύεται) — ΚΑΜΙΑ δεύτερη υλοποίηση δεν μένει πίσω.

(in-package :orchestrator.engine.sbcl)

(defun %erratum-field (e key)
  "Read KEY from erratum entry E, whatever shape the YAML loader produced."
  (cond ((hash-table-p e)
         (or (gethash key e)
             (gethash (intern (string-upcase key) :keyword) e)))
        ((consp e)
         (or (cdr (assoc key e :test #'equalp))
             (getf e (intern (string-upcase key) :keyword))))))

(defun %declared-errata ()
  "The declared errata of the ACTIVE corpus (config source.errata): entries
   {article, from, to, reason, page} — the gazette practice: documented
   editorial correction of a defect in the SOURCE's own text layer. NEVER a
   silent patch: each entry names article, exact text, justification, page,
   and is recorded in the provenance sidecar by materialize."
  (let ((v (ignore-errors (orchestrator.spec:config-get "source.errata"))))
    (when (listp v) v)))

(defun apply-declared-errata (iirs)
  "[Η ΜΙΑ ΕΔΡΑ — καλείται ΜΕΣΑ από τους adapters, ποτέ από καταναλωτές] Apply
   the ACTIVE corpus's declared errata to IIRS. Each entry must match its
   article and its FROM text EXACTLY ONCE — anything else is reported loudly
   and skipped (an erratum that no longer matches is stale and must be
   reviewed, not guessed). Returns (values IIRS applied-entries); the second
   value feeds the provenance sidecar at materialize."
  (let ((applied '())
        (corpus-id (or (ignore-errors (orchestrator.spec:config-get "corpus.short_name"))
                       "corpus"))
        (label-fn (find-symbol "ARTICLE-LABEL" :orchestrator.model))
        (content-fn (find-symbol "ARTICLE-CONTENT" :orchestrator.model)))
    (when iirs
      (dolist (e (%declared-errata))
        (let* ((art  (princ-to-string (or (%erratum-field e "article") "")))
               (from (princ-to-string (or (%erratum-field e "from") "")))
               (to   (princ-to-string (or (%erratum-field e "to") "")))
               (why  (princ-to-string (or (%erratum-field e "reason") "")))
               (iir  (find art iirs
                           :test #'string=
                           :key (lambda (x) (princ-to-string (funcall label-fn x))))))
          (cond
            ((null iir)
             (format t "  ✗ erratum ~A/~A: το άρθρο δεν βρέθηκε — ΔΕΝ εφαρμόστηκε~%"
                     corpus-id art))
            ((zerop (length from))
             (format t "  ✗ erratum ~A/~A: κενό 'from' — ΔΕΝ εφαρμόστηκε~%" corpus-id art))
            (t
             (let* ((body (funcall content-fn iir))
                    (hits (loop with start = 0 with n = 0
                                for pos = (search from body :start2 start)
                                while pos do (incf n) (setf start (1+ pos))
                                finally (return n))))
               (cond
                 ((/= hits 1)
                  (format t "  ✗ erratum ~A/~A: το 'from' βρέθηκε ~D φορές (απαιτείται ακριβώς 1) — ΔΕΝ εφαρμόστηκε~%"
                          corpus-id art hits))
                 (t
                  (let ((pos (search from body)))
                    (funcall (fdefinition (list 'setf content-fn))
                             (concatenate 'string
                                          (subseq body 0 pos) to
                                          (subseq body (+ pos (length from))))
                             iir))
                  (format t "  ✦ erratum ~A/~A εφαρμόστηκε: ~A~%" corpus-id art why)
                  (push (list (cons "article" art) (cons "from" from)
                              (cons "to" to) (cons "reason" why)
                              (cons "page" (princ-to-string (or (%erratum-field e "page") ""))))
                        applied))))))))
      )
    (values iirs (nreverse applied))))
