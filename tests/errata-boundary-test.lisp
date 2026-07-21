;;;; tests/errata-boundary-test.lisp
;;;; ============================================================================
;;;; [Π7-U.1 Φ1γ / 0110] ΤΟ ΟΡΙΟ ΕΞΑΓΩΓΗΣ ΕΦΑΡΜΟΖΕΙ ΤΑ ERRATA — regression lock
;;;; ============================================================================
;;;; Η κλάση που κλειδώνεται νεκρή: ο pipeline PDF-mode (και ΚΑΘΕ μελλοντικός
;;;; καταναλωτής adapter) παρήγαγε IIR ΧΩΡΙΣ τα δηλωμένα errata — τα artifacts
;;;; ξαναγεννούσαν διορθωμένα ελαττώματα (ζωντανό εύρημα δημιουργού: άρθρο 4 Σ
;;;; ξανά «συμφέρον τα» στο docker output). Τώρα: pdf-adapter/docx-adapter
;;;; εφαρμόζουν ΟΙ ΙΔΙΟΙ τα errata (adapters/errata-boundary.lisp) — bypass
;;;; δομικά αδύνατος. Το τεστ τρέχει τον ΠΡΑΓΜΑΤΙΚΟ adapter στην ΠΡΑΓΜΑΤΙΚΗ
;;;; πηγή του Συντάγματος.

(in-package :orchestrator.cli)

(defvar *eb-pass* 0)
(defvar *eb-fail* 0)
(defmacro eb-check (name form)
  `(handler-case
       (if ,form (progn (incf *eb-pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *eb-fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *eb-fail*) (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

(format t "~%── [Π7-U.1 Φ1γ] ERRATA BOUNDARY: ο adapter εφαρμόζει τα δηλωμένα errata ──~%")

(orchestrator.spec:select-corpus "syntagma")
(orchestrator.gr-syntagma:register-active-corpus)

(defparameter *eb-pdf* (orchestrator.spec:resolve-config-path "source.pdf"))

(multiple-value-bind (iirs applied)
    (orchestrator.engine.sbcl:pdf-adapter *eb-pdf*)
  (eb-check "① 124 άρθρα από τον πραγματικό adapter"
            (= 124 (length iirs)))
  (eb-check "② τα 2 δηλωμένα errata ΕΦΑΡΜΟΣΤΗΚΑΝ ΜΕΣΑ στον adapter (2η τιμή)"
            (= 2 (length applied)))
  (let* ((content-fn (find-symbol "ARTICLE-CONTENT" :orchestrator.model))
         (label-fn (find-symbol "ARTICLE-LABEL" :orchestrator.model))
         (a4 (find "4" iirs :test #'string=
                   :key (lambda (x) (princ-to-string (funcall label-fn x)))))
         (txt (and a4 (funcall content-fn a4))))
    (eb-check "③ άρθρο 4: «εθνικά συμφέροντα» ΠΑΡΟΝ (η διόρθωση ρέει από το όριο)"
              (and txt (search "εθνικά συμφέροντα" txt)))
    (eb-check "④ άρθρο 4: «προβλέπει ειδικότερα» ΠΑΡΟΝ"
              (and txt (search "προβλέπει ειδικότερα" txt)))
    (eb-check "⑤ ΚΑΜΙΑ σπασμένη μορφή («συμφέρον τα»/«προβλέπειειδικότερα»)"
              (and txt
                   (not (search "συμφέρον τα" txt))
                   (not (search "προβλέπειειδικότερα" txt))))))

;;; Αρνητικό: χωρίς δηλωμένα errata ο μηχανισμός είναι no-op με ΤΙΜΙΑ 2η τιμή
(multiple-value-bind (iirs applied)
    (orchestrator.engine.sbcl::apply-declared-errata nil)
  (eb-check "⑥ κενά iirs ⇒ (values nil nil) — καμία ψευδο-εφαρμογή"
            (and (null iirs) (null applied))))

(format t "~%========================================~%")
(format t "ERRATA-BOUNDARY tests: ~D passed, ~D failed~%" *eb-pass* *eb-fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *eb-fail*) 0 1))
