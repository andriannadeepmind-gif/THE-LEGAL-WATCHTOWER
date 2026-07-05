;;;; source/corpus-sparql.lisp
;;;; ============================================================================
;;;; LIVE SPARQL OVER THE CONSOLIDATED CORPUS
;;;; ============================================================================
;;;;
;;;; Brings the real (but previously unwired) pure-Lisp SPARQL engine to life:
;;;; builds an rdfs-inference knowledge base of triples from a consolidated
;;;; legal-document and answers SPARQL SELECT queries against it. Wired into the
;;;; AI-first service as /<corpus>/sparql so an AI/tool can ask, e.g.,
;;;;   SELECT ?a WHERE { ?a eli:in_force "true" }
;;;;
;;;; Reuses orchestrator.sparql-endpoint (parser + evaluator) and
;;;; orchestrator.rdfs-inference (knowledge base) — no new query engine, no
;;;; duplication. The KB uses string terms, matching the engine's model.
;;;; ============================================================================

(defpackage :orchestrator.corpus-sparql
  (:use :cl)
  (:import-from :orchestrator.consolidation
                #:legal-document-provisions
                #:provision-eid #:provision-num #:provision-heading
                #:provision-text #:provision-children
                #:provision-status #:provision-source-act #:provision-source-date)
  (:export #:build-corpus-kb #:sparql-query #:+default-prefixes+))

(in-package :orchestrator.corpus-sparql)

(defparameter +rdf-type+ "http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
(defparameter +eli+ "http://data.europa.eu/eli/ontology#")
(defparameter +dct+ "http://purl.org/dc/terms/")

(defparameter +default-prefixes+
  '(("eli" . "http://data.europa.eu/eli/ontology#")
    ("dct" . "http://purl.org/dc/terms/")
    ("rdf" . "http://www.w3.org/1999/02/22-rdf-syntax-ns#"))
  "Built-in prefix map. Queries may use these prefixed names directly
   (e.g. eli:in_force); they are expanded to full IRIs before evaluation.")

(defun %pname-char-p (ch)
  (or (alphanumericp ch) (member ch '(#\_ #\- #\.))))

(defun %expand-one (q prefix ns)
  "Replace every PREFIX:local in Q with <NS local>."
  (let ((needle (concatenate 'string prefix ":"))
        (nl (1+ (length prefix))))
    (with-output-to-string (out)
      (let ((i 0) (n (length q)))
        (loop while (< i n) do
          (let ((pos (search needle q :start2 i)))
            (if (null pos)
                (progn (write-string (subseq q i) out) (setf i n))
                (progn
                  (write-string (subseq q i pos) out)
                  (let ((k (+ pos nl)))
                    (loop while (and (< k n) (%pname-char-p (char q k))) do (incf k))
                    (if (> k (+ pos nl))
                        (progn (format out "<~A~A>" ns (subseq q (+ pos nl) k))
                               (setf i k))
                        (progn (write-string needle out)
                               (setf i (+ pos nl)))))))))))))

(defun %expand-prefixes (query)
  "Expand known prefixed names (eli:foo) to full <IRI> and drop any PREFIX
   declaration lines (the engine matches on full IRIs)."
  (let ((q (cl-ppcre:regex-replace-all "(?i)PREFIX\\s+\\S+\\s+<[^>]*>\\s*" (or query "") "")))
    (dolist (pair +default-prefixes+ q)
      (setf q (%expand-one q (car pair) (cdr pair))))))

(defun build-corpus-kb (document base-uri)
  "Build an rdfs-inference knowledge base from DOCUMENT. Each provision yields
   triples for rdf:type, eli:in_force, eli:number, dct:title and (when amended)
   eli:amended_by, all keyed by the per-corpus resource URI base-uri/eId."
  (let ((kb (funcall (find-symbol "MAKE-KNOWLEDGE-BASE" :orchestrator.rdfs-inference)))
        (add (find-symbol "KB-ADD-TRIPLE" :orchestrator.rdfs-inference)))
    (labels ((emit (p)
               (let ((uri (format nil "~A/~A" base-uri (provision-eid p))))
                 (funcall add kb uri +rdf-type+ (concatenate 'string +eli+ "LegalResource"))
                 (funcall add kb uri (concatenate 'string +eli+ "in_force")
                          (if (eq (provision-status p) :repealed) "false" "true"))
                 (when (provision-num p)
                   (funcall add kb uri (concatenate 'string +eli+ "number") (provision-num p)))
                 (when (provision-heading p)
                   (funcall add kb uri (concatenate 'string +dct+ "title") (provision-heading p)))
                 (when (provision-source-date p)
                   (funcall add kb uri (concatenate 'string +eli+ "date_applicability")
                            (provision-source-date p)))
                 (when (provision-source-act p)
                   (funcall add kb uri (concatenate 'string +eli+ "amended_by")
                            (format nil "~A/act/~A" base-uri (provision-source-act p))))
                 (dolist (c (provision-children p)) (emit c)))))
      (dolist (article (legal-document-provisions document)) (emit article)))
    kb))

(defun sparql-query (document base-uri query-string)
  "Answer SPARQL QUERY-STRING against a KB built from DOCUMENT. Returns a
   SPARQL-results JSON string, or an error JSON object on a bad query."
  (handler-case
      (let ((kb (build-corpus-kb document base-uri))
            (q (%expand-prefixes (or query-string ""))))
        (funcall (find-symbol "RESULTS-TO-JSON" :orchestrator.sparql-endpoint)
                 (funcall (find-symbol "EXECUTE-SPARQL" :orchestrator.sparql-endpoint) q kb)))
    (error (e)
      (format nil "{\"error\":\"sparql\",\"message\":~S}"
              (substitute #\Space #\" (princ-to-string e))))))
