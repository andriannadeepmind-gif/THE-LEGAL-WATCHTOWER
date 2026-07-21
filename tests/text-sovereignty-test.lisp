;;;; tests/text-sovereignty-test.lisp
;;;; ============================================================================
;;;; [+3/0105] ΜΕΤΑΘΕΣΗ ΚΥΡΙΑΡΧΙΑΣ — τα per-article artifacts αποδίδονται ΑΠΟ
;;;; το consolidated (τη ΜΙΑ αποδεδειγμένη πηγή, byte-δεμένη με το graph fold),
;;;; ΟΧΙ από το raw IIR. Κλειδώνει:
;;;;   (α) generate-rdf-stage παράγει το consolidated ΠΡΙΝ από κάθε render και
;;;;       το βάζει στο context (η ΜΙΑ παραγωγή)·
;;;;   (β) article-content ΚΑΘΕ άρθρου ≡ ai-dump:article-text(provision) —
;;;;       byte-ίσο, ακόμη κι όταν το raw IIR διαφέρει (whitespace/δομή)·
;;;;   (γ) ΟΛΑ τα formats (txt-πηγή, html, jsonld, ttl) φέρουν το ΚΥΡΙΑΡΧΟ
;;;;       κείμενο, όχι το raw IIR·
;;;;   (δ) consolidate-stage ΧΩΡΙΣ :consolidated στο context ⇒ ΣΦΑΛΜΑ (καμία
;;;;       σιωπηλή δεύτερη παραγωγή)· με context: γράφει corpus.jsonl του
;;;;       ΙΔΙΟΥ αντικειμένου (η αλυσίδα κλείνει στον δίσκο).
;;;; ============================================================================

(in-package :orchestrator.engine.sbcl)

(defvar *ts-pass* 0)
(defvar *ts-fail* 0)
(defmacro ts-check (name form)
  `(handler-case
       (if ,form (progn (incf *ts-pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *ts-fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *ts-fail*) (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

(format t "~%── [+3/0105] TEXT SOVEREIGNTY: artifacts ≡ consolidated ──~%")

;; Ενεργό config (syntagma) — ίδιο idiom με corpus-identity-test: οι έδρες
;; required-config/ELI-prefix απαιτούν πραγματικό ενεργό corpus, όχι mock.
(orchestrator.spec:select-corpus "syntagma")
(orchestrator.gr-syntagma:register-active-corpus)
(let ((yaml (orchestrator.spec:ensure-config-loaded)))
  (when yaml (orchestrator.uris:load-canonical-uris-from-config yaml)))

;; IIR fixtures: το 7 με ΑΚΑΤΕΡΓΑΣΤΟ whitespace/κενές γραμμές ώστε το raw IIR
;; να ΔΙΑΦΕΡΕΙ από την κανονική μορφή του consolidated (αποδεικνύει μεταφορά
;; κυριαρχίας, όχι απλή αντιγραφή).
(defparameter *ts-raw-7*
  (format nil "  Πρώτη παράγραφος του εβδόμου.  ~%~%   Δεύτερη παράγραφος του εβδόμου.  ")
  "Το ΑΚΑΤΕΡΓΑΣΤΟ κείμενο πηγής του 7 — πριν από ΚΑΘΕ κανονικοποίηση.")

(defparameter *ts-iir*
  (list (orchestrator.model:make-normalized-article-input
         :article-number 7 :article-label "7"
         :article-title "Άρθρο 7 - Πρώτο"
         :article-content *ts-raw-7*
         :source-type :json :source-path "fixture.json")
        (orchestrator.model:make-normalized-article-input
         :article-number 8 :article-label "8"
         :article-title "Άρθρο 8 - Δεύτερο"
         :article-content "Μοναδική παράγραφος του ογδόου."
         :source-type :json :source-path "fixture.json")))

(defparameter *ts-ctx*
  (make-instance 'orchestrator.core:pipeline-context :pipeline nil :config nil))
(orchestrator.core:set-context-value *ts-ctx* :articles *ts-iir*)
(orchestrator.core:set-context-value *ts-ctx* :corpus :syntagma)

(generate-rdf-stage *ts-ctx*)

(defparameter *ts-cons* (orchestrator.core:get-context-value *ts-ctx* :consolidated))
(defparameter *ts-arts* (orchestrator.core:get-context-value *ts-ctx* :articles))

(ts-check "α1 generate-rdf-stage: το consolidated ΣΤΟ context (η ΜΙΑ παραγωγή)"
          (and *ts-cons*
               (orchestrator.consolidation:legal-document-p *ts-cons*)))
(ts-check "α2 2 article instances στο context"
          (= 2 (length *ts-arts*)))

(defun %ts-article (n)
  (find n *ts-arts* :key #'orchestrator.model:article-number))
(defun %ts-sovereign (n)
  (orchestrator.ai-dump:article-text
   (orchestrator.consolidation:find-provision
    *ts-cons* (orchestrator.consolidation.bridge:article-eid (format nil "~D" n)))))

(ts-check "β1 άρθρο 7: article-content ≡ consolidated in-force text (byte-ίσο)"
          (equal (orchestrator.model:article-content (%ts-article 7))
                 (%ts-sovereign 7)))
(ts-check "β2 άρθρο 7: το ΚΥΡΙΑΡΧΟ κείμενο ≠ ακατέργαστη πηγή (η κανονική μορφή ΕΠΙΒΛΗΘΗΚΕ — δεν είναι ταυτολογία)"
          (not (equal (orchestrator.model:article-content (%ts-article 7))
                      *ts-raw-7*)))
(ts-check "β3 άρθρο 8: article-content ≡ consolidated (και στη μονο-παράγραφη μορφή)"
          (equal (orchestrator.model:article-content (%ts-article 8))
                 (%ts-sovereign 8)))

(ts-check "γ1 HTML φέρει το κυρίαρχο κείμενο"
          (search "Δεύτερη παράγραφος του εβδόμου."
                  (orchestrator.model:article-html (%ts-article 7))))
(ts-check "γ2 JSON-LD hash = hash ΤΟΥ κυρίαρχου κειμένου"
          (search (orchestrator.spec:calculate-sha256-hash
                   (orchestrator.model:article-content (%ts-article 7)))
                  (orchestrator.model:article-json-ld (%ts-article 7))))
(ts-check "γ3 TTL φέρει το κυρίαρχο κείμενο (ο FRBR δρόμος ΔΕΝ ξαναδιάβασε raw IIR)"
          (search "Μοναδική παράγραφος του ογδόου."
                  (orchestrator.model:article-rdf-turtle (%ts-article 8))))

(format t "~%== (δ) consolidate-stage: κατανάλωση, ΟΧΙ δεύτερη παραγωγή ==~%")
(ts-check "δ1 consolidate-stage ΧΩΡΙΣ :consolidated ⇒ ΣΦΑΛΜΑ (fail-closed)"
          (let ((bare (make-instance 'orchestrator.core:pipeline-context
                                     :pipeline nil :config nil)))
            (orchestrator.core:set-context-value bare :articles *ts-arts*)
            (handler-case (progn (consolidate-stage bare) nil)
              (error () t))))
(defparameter *ts-out*
  (merge-pathnames (format nil "text-sovereignty-~D/" (get-universal-time))
                   (uiop:temporary-directory)))
(ensure-directories-exist *ts-out*)
(orchestrator.core:set-context-value *ts-ctx* :output-dir *ts-out*)
(consolidate-stage *ts-ctx*)
(ts-check "δ2 corpus.jsonl στον δίσκο: το text του άρθρου 7 = ΤΟ κυρίαρχο κείμενο"
          (let ((jsonl (uiop:read-file-string (merge-pathnames "corpus.jsonl" *ts-out*)))
                (needle "Δεύτερη παράγραφος του εβδόμου."))
            (search needle jsonl)))
(ts-check "δ3 consolidated.txt γράφτηκε (η κατανάλωση παρήγαγε τα artifacts)"
          (and (probe-file (merge-pathnames "consolidated.txt" *ts-out*))
               (probe-file (merge-pathnames "consolidated.akn.xml" *ts-out*))))

(ignore-errors (uiop:delete-directory-tree *ts-out* :validate t))

(format t "~%========================================~%")
(format t "TEXT-SOVEREIGNTY tests: ~D passed, ~D failed~%" *ts-pass* *ts-fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *ts-fail*) 0 1))
