;;;; source/ai-corpus-dump.lisp
;;;; ============================================================================
;;;; AI CORPUS DUMP
;;;; ============================================================================
;;;;
;;;; The consumption layer: emits the consolidated corpus in the forms an AI
;;;; system / crawler / RAG pipeline actually pulls.
;;;;
;;;;   corpus.jsonl   - one JSON object per article (eId, number, heading,
;;;;                    in_force, status, amending act, date, in-force text and
;;;;                    per-paragraph breakdown). A line-delimited, streamable
;;;;                    dataset — the natural bulk-ingest format for LLMs.
;;;;   catalog.jsonld - a DCAT dataset description listing the available
;;;;                    distributions (Akoma Ntoso XML, Turtle, JSONL, text), so
;;;;                    a machine can discover and fetch the whole corpus.
;;;;
;;;; Deterministic: provisions are emitted in document order with no wall-clock.
;;;; Pure Common Lisp (hand-written, escaped JSON).
;;;; ============================================================================

(defpackage :orchestrator.ai-dump
  (:use :cl)
  (:import-from :orchestrator.consolidation
                #:legal-document-id #:legal-document-title #:legal-document-language
                #:legal-document-provisions
                #:provision-eid #:provision-num #:provision-heading #:provision-text
                #:provision-children #:provision-status #:provision-source-act
                #:provision-source-date)
  (:export #:emit-corpus-jsonl #:emit-corpus-catalog
           ;; [0088] Φ3: η ΜΙΑ έδρα «πλήρες in-force κείμενο άρθρου» —
           ;; την καταναλώνει και ο version-graph importer/parity gate
           #:article-text))

(in-package :orchestrator.ai-dump)

;;; ============================================================================
;;; JSON WRITING (deterministic, escaped)
;;; ============================================================================

(defun json-escape (string)
  (with-output-to-string (s)
    (loop for ch across (or string "")
          do (cond
               ((char= ch #\") (write-string "\\\"" s))
               ((char= ch #\\) (write-string "\\\\" s))
               ((char= ch #\Newline) (write-string "\\n" s))
               ((char= ch #\Return) (write-string "\\r" s))
               ((char= ch #\Tab) (write-string "\\t" s))
               ((< (char-code ch) 32) (format s "\\u~4,'0X" (char-code ch)))
               (t (write-char ch s))))))

(defun jstr (x) (if x (format nil "\"~A\"" (json-escape x)) "null"))
(defun jbool (x) (if x "true" "false"))

(defun in-force-p (p) (not (eq (provision-status p) :repealed)))

(defun status-string (p)
  (case (provision-status p)
    (:original "original") (:amended "amended")
    (:inserted "inserted") (:repealed "repealed") (t "unknown")))

;;; ============================================================================
;;; JSONL — one object per article
;;; ============================================================================

(defun article-text (p)
  "In-force text of an article: its own text plus its non-repealed paragraphs,
   newline-joined. NIL for a repealed article."
  (when (in-force-p p)
    (let ((parts '()))
      (when (provision-text p) (push (provision-text p) parts))
      (dolist (c (provision-children p))
        (when (and (in-force-p c) (provision-text c))
          (push (provision-text c) parts)))
      (when parts
        (format nil "~{~A~^~%~}" (nreverse parts))))))

(defun write-paragraphs (s p)
  (let ((kids (provision-children p)))
    (if (null kids)
        (write-string "[]" s)
        (progn
          (write-string "[" s)
          (loop for c in kids for firstp = t then nil
                do (unless firstp (write-string "," s))
                   (format s "{\"eId\":~A,\"number\":~A,\"in_force\":~A,\"status\":~A,\"text\":~A}"
                           (jstr (provision-eid c)) (jstr (provision-num c))
                           (jbool (in-force-p c)) (jstr (status-string c))
                           (jstr (provision-text c))))
          (write-string "]" s)))))

(defun emit-corpus-jsonl (document &key (base-uri "https://stavropouloslaw.com/eli"))
  "Emit DOCUMENT as JSON Lines: one article per line. Deterministic."
  (with-output-to-string (s)
    (dolist (article (legal-document-provisions document))
      (format s "{\"@id\":~A,\"eId\":~A,\"number\":~A,\"heading\":~A,~
\"language\":~A,\"in_force\":~A,\"status\":~A,\"amended_by\":~A,~
\"date_applicability\":~A,\"text\":~A,\"paragraphs\":"
              (jstr (format nil "~A/~A" base-uri (provision-eid article)))
              (jstr (provision-eid article))
              (jstr (provision-num article))
              (jstr (provision-heading article))
              (jstr (legal-document-language document))
              (jbool (in-force-p article))
              (jstr (status-string article))
              (jstr (provision-source-act article))
              (jstr (provision-source-date article))
              (jstr (article-text article)))
      (write-paragraphs s article)
      (write-string "}" s)
      (terpri s))))

;;; ============================================================================
;;; DCAT catalog (JSON-LD)
;;; ============================================================================

(defun emit-corpus-catalog (document
                            &key (base-uri "https://stavropouloslaw.com/eli")
                                 (formats '(("application/akn+xml" . "consolidated.akn.xml")
                                            ("text/turtle" . "consolidated.ttl")
                                            ("application/jsonl" . "corpus.jsonl")
                                            ("text/plain" . "consolidated.txt"))))
  "Emit a DCAT dataset description (JSON-LD) advertising the corpus
   distributions for machine discovery. Deterministic."
  (let ((id (or (legal-document-id document) "corpus"))
        (n (length (legal-document-provisions document))))
    (with-output-to-string (s)
      (format s "{~%")
      (format s "  \"@context\": {~%")
      (format s "    \"dcat\": \"http://www.w3.org/ns/dcat#\",~%")
      (format s "    \"dct\": \"http://purl.org/dc/terms/\"~%")
      (format s "  },~%")
      (format s "  \"@id\": ~A,~%" (jstr (format nil "~A/~A/catalog" base-uri id)))
      (format s "  \"@type\": \"dcat:Dataset\",~%")
      (format s "  \"dct:title\": ~A,~%" (jstr (legal-document-title document)))
      (format s "  \"dct:identifier\": ~A,~%" (jstr id))
      (format s "  \"dct:language\": ~A,~%" (jstr (legal-document-language document)))
      (format s "  \"dcat:itemCount\": ~D,~%" n)
      (format s "  \"dcat:distribution\": [~%")
      (loop for (mediatype . file) in formats
            for firstp = t then nil
            do (unless firstp (format s ",~%"))
               (format s "    {\"@type\": \"dcat:Distribution\", ~
\"dcat:mediaType\": ~A, \"dcat:downloadURL\": ~A}"
                       (jstr mediatype)
                       (jstr (format nil "~A/~A/~A" base-uri id file))))
      (format s "~%  ]~%}~%"))))
