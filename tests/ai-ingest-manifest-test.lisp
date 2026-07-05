;;;; tests/ai-ingest-manifest-test.lisp
;;;; Real, deterministic AI ingestion manifest built from consolidated
;;;; provisions — no randomness, no fabricated metrics.

(in-package :orchestrator.ai-ingest)

;; Production builds run with deterministic time (SOURCE_DATE_EPOCH); enable it
;; here so the byte-identical guarantee is exercised exactly as it ships.
(funcall (find-symbol "CONFIGURE-DETERMINISTIC-TIME" :orchestrator.time)
         :enabled t :fixed-time "2025-01-01T00:00:00Z")

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun mp (&rest a) (apply (find-symbol "MAKE-PROVISION" :orchestrator.consolidation) a))
(defun md (&rest a) (apply (find-symbol "MAKE-LEGAL-DOCUMENT" :orchestrator.consolidation) a))

(defun demo ()
  (md :id "demo" :title "Demo" :language "el"
      :provisions
      (list (mp :eid "art_1" :kind :article :num "1" :heading "Σκοπός"
                :text "Σκοπός του παρόντος. Βλέπε άρθρο 2 και άρθρο 3 του νόμου.")
            (mp :eid "art_2" :kind :article :num "2" :heading "Ορισμοί"
                :text "Για τους σκοπούς του παρόντος ισχύει το άρθρο 3.")
            (mp :eid "art_3" :kind :article :num "3" :heading "Τελικά"
                :text "Τελικές διατάξεις χωρίς παραπομπές."))))

(format t "~%== Deterministic AI ingestion manifest ==~%")
(let* ((doc (demo))
       (m (build-corpus-manifest doc :base-uri "https://x/eli/demo"))
       (arts (manifest-articles-ordered m)))
  (check "3 articles in manifest" (= 3 (total-articles m)))
  (check "articles ordered by number"
         (equal (mapcar #'article-number arts) '(1 2 3)))
  (check "real token counts are positive for every article"
         (every (lambda (a) (> (token-count a) 0)) arts))
  (check "art_1 has 2 outgoing citations (άρθρο 2, άρθρο 3)"
         (= 2 (structured-citations (first arts))))
  (check "art_3 has no outgoing citations"
         (= 0 (structured-citations (third arts))))
  (check "art_3 has 2 backlinks (cited by art_1 and art_2)"
         (= 2 (backlink-count (third arts))))
  (check "art_2 backlinked once (by art_1)"
         (= 1 (backlink-count (second arts))))
  (check "every article served as json-ld + rdf"
         (every (lambda (a) (and (json-ld-present a) (rdfa-present a))) arts))
  (check "content is the real article text"
         (search "Σκοπός του παρόντος" (article-content (first arts))))
  (check "uri density = uris/tokens (no fabrication)"
         (let ((a (first arts)))
           (< (abs (- (uri-density a) (/ (uri-count a) (token-count a) 1.0))) 1e-6)))

  (format t "~%== Determinism ==~%")
  (let* ((m2 (build-corpus-manifest (demo) :base-uri "https://x/eli/demo"))
         (j1 (manifest->json-string m))
         (j2 (manifest->json-string m2)))
    (check "manifest JSON is byte-identical across runs" (string= j1 j2))
    (check "JSON carries real article text" (search "Σκοπός" j1))
    (check "JSON has no random embeddings (empty arrays only)"
           (null (search "0.123" j1))))

  (format t "~%== HuggingFace records ==~%")
  (let ((rec (article-to-huggingface-record (first arts))))
    (check "record article_id = eId" (string= (getf rec :|article_id|) "art_1"))
    (check "record carries status" (stringp (getf rec :|status|)))
    (check "record content non-empty" (plusp (length (getf rec :|content|)))))

  (format t "~%== RDF serialization ==~%")
  (let ((ttl (serialize-manifest-rdf m)))
    (check "RDF declares dct prefix" (search "@prefix dct:" ttl))
    (check "RDF lists article metadata" (search "ingest:ArticleMetadata" ttl))
    (check "RDF deterministic" (string= ttl (serialize-manifest-rdf m)))))

(format t "~%========================================~%")
(format t "AI ingest manifest tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
