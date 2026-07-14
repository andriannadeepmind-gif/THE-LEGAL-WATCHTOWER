;;;; tests/multi-corpus-service-test.lisp
;;;; Verifies the multi-corpus service: each κώδικας isolated under its prefix.

(in-package :orchestrator.corpus-service)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun doc (id title art5-heading art5-text)
  (let ((c (find-package :orchestrator.consolidation)))
    (funcall (find-symbol "MAKE-LEGAL-DOCUMENT" c)
             :id id :title title :language "el"
             :provisions
             (list (funcall (find-symbol "MAKE-PROVISION" c)
                            :eid "art_5" :kind :article :num "5"
                            :heading art5-heading :text art5-text)))))

(defun req (path) (funcall (find-symbol "MAKE-HTTP-REQUEST" :orchestrator.http) :path path))
(defun rstatus (r) (funcall (find-symbol "HTTP-RESPONSE-STATUS" :orchestrator.http) r))
(defun rbody (r) (funcall (find-symbol "HTTP-RESPONSE-BODY" :orchestrator.http) r))

(let* ((docP (doc "poinikos" "Ποινικός Κώδικας" "Εγκλήματα" "Εγκλήματα στην ημεδαπή."))
       (docS (doc "constitution" "Σύνταγμα" "Δικαίωμα" "Δικαίωμα στην πληροφόρηση."))
       (multi (make-multi-corpus-service
               (list (make-corpus-runtime :name "poinikos" :corpus-id "poinikos"
                                          :doc-provider (lambda () docP))
                     (make-corpus-runtime :name "constitution" :corpus-id "syntagma"
                                          :doc-provider (lambda () docS)))))
       (h (multi-service-handler multi)))

  (format t "~%== Top index / catalog ==~%")
  (check "/ -> dcat:Catalog listing corpora"
         (let ((b (rbody (funcall h (req "/")))))
           (and (search "dcat:Catalog" b) (search "poinikos" b) (search "constitution" b))))
  (check "/catalog.jsonld lists both corpora"
         (let ((b (rbody (funcall h (req "/catalog.jsonld")))))
           (and (search "poinikos" b) (search "constitution" b))))
  (check "/.well-known/ai-corpus.json lists corpora + ai_first"
         (let ((b (rbody (funcall h (req "/.well-known/ai-corpus.json")))))
           (and (search "ai_first" b) (search "poinikos" b))))

  (format t "~%== Per-corpus isolation ==~%")
  (check "/poinikos/corpus.jsonl -> Penal art_5 (Εγκλήματα)"
         (let ((b (rbody (funcall h (req "/poinikos/corpus.jsonl")))))
           (and (search "\"eId\":\"art_5\"" b) (search "Εγκλήματα" b)
                (null (search "πληροφόρηση" b)))))
  (check "/constitution/corpus.jsonl -> Constitution art_5 (πληροφόρηση)"
         (let ((b (rbody (funcall h (req "/constitution/corpus.jsonl")))))
           (and (search "πληροφόρηση" b) (null (search "Εγκλήματα" b)))))
  (check "/poinikos/article/art_5 -> Penal article JSON"
         (search "Εγκλήματα" (rbody (funcall h (req "/poinikos/article/art_5")))))
  (check "/constitution/article/art_5 -> Constitution article JSON"
         (search "πληροφόρηση" (rbody (funcall h (req "/constitution/article/art_5")))))
  (check "/poinikos/consolidated.akn.xml -> Akoma Ntoso"
         (search "<akomaNtoso" (rbody (funcall h (req "/poinikos/consolidated.akn.xml")))))
  (check "/poinikos/catalog.jsonld -> corpus-scoped catalog"
         (search "dcat:Dataset" (rbody (funcall h (req "/poinikos/catalog.jsonld")))))

  (format t "~%== Unknown corpus / robots ==~%")
  (check "/unknown/corpus.jsonl -> 404" (= 404 (rstatus (funcall h (req "/unknown/x")))))
  (check "/robots.txt welcomes ClaudeBot"
         (search "ClaudeBot" (rbody (funcall h (req "/robots.txt")))))
  (check "base URIs are per-corpus (no cross-link)"
         (let ((b (rbody (funcall h (req "/poinikos/corpus.jsonl")))))
           (and (search "/poinikos/art_5" b) (null (search "/constitution/art_5" b))))))

;;; [0088 Φ5-κριτής Μ] uniqueness gate: διπλό short name = ΣΦΑΛΜΑ κατασκευής
(check "[Μ] διπλά short names ⇒ ΣΦΑΛΜΑ (καμία σιωπηλή σκίαση route)"
       (handler-case
           (progn (make-multi-corpus-service
                   (list (make-corpus-runtime :name "x" :corpus-id "a" :doc-provider (lambda () nil))
                         (make-corpus-runtime :name "x" :corpus-id "b" :doc-provider (lambda () nil))))
                  nil)
         (error () t)))

(format t "~%========================================~%")
(format t "Multi-corpus service tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
