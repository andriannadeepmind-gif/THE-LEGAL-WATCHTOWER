;;;; systems/orchestrator-gr-syntagma/corpus.lisp
;;;; Generic corpus registration — driven by active config (select-corpus).
;;;; Supports any Greek law type: constitution, statutes, decrees, etc.

(in-package :orchestrator.gr-syntagma)

(defparameter *greek-constitution-corpus* nil
  "Cache for the active corpus instance (set by register-active-corpus).")

(defun make-active-corpus ()
  "Create a corpus instance from the active config (set by select-corpus).

   All fields are read from the loaded YAML:
     corpus.name            → display name
     corpus.short_name      → identifier keyword base
     corpus.eli_prefix      → ELI URI prefix
     corpus.publication.date → legal publication date
     corpus.document_type   → ELI type code ('const', 'l', 'pd', ...)
     corpus.article_count   → total articles (informational)

   No Constitution-specific defaults — every field must be in the config."
  (orchestrator.model:make-corpus
   :name (or (orchestrator.spec:config-get "corpus.name")
             (error "corpus.name not set in active config"))
   :short-name (or (orchestrator.spec:config-get "corpus.short_name")
                   (error "corpus.short_name not set in active config"))
   :eli-prefix (or (orchestrator.spec:config-get "corpus.eli_prefix")
                   (error "corpus.eli_prefix not set in active config"))
   ;; [0088 Φ6γ-Δ³] typed ταυτότητα σώματος από τη ΜΙΑ έδρα (config-δηλωμένη)
   :legal-body-id (orchestrator.identity:declared-body)
   :publication-date (or (orchestrator.spec:config-get "corpus.publication.date")
                         (error "corpus.publication.date not set in active config"))
   :language "el"
   :webid (orchestrator.spec:person-webid)
   :orcid (orchestrator.spec:config-get "identity.person.orcid" "")
   :metadata (list :document-type (orchestrator.spec:config-get "corpus.document_type")
                   :total-articles (orchestrator.spec:config-get "corpus.article_count"))))

(defun register-active-corpus ()
  "Register the active corpus (from config) under :gr-syntagma in the meta registry.

   The :gr-syntagma key is the pipeline's corpus reference key — kept stable
   so the pipeline definition does not need to change per corpus.
   The actual corpus data (name, URI, dates) comes entirely from config.

   Always creates a fresh corpus instance from the currently-loaded config so
   that select-corpus can switch corpora within the same process without the
   previous corpus instance leaking through the cache.

   Returns: corpus instance."
  (setf *greek-constitution-corpus* (make-active-corpus))
  (orchestrator.meta:register-corpus :gr-syntagma *greek-constitution-corpus*)
  *greek-constitution-corpus*)

(defun register-greek-constitution ()
  "Register corpus from active config. Name kept for backward compatibility."
  (register-active-corpus))
