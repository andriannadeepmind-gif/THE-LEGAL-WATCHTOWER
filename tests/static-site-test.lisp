;;;; tests/static-site-test.lisp
;;;; Cloudflare-Pages-ready static site generation from the consolidated corpus.
;;;; Human HTML + AI structured data. Deterministic.

(in-package :orchestrator.static-site)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(funcall (find-symbol "CONFIGURE-DETERMINISTIC-TIME" :orchestrator.time)
         :enabled t :fixed-time "2025-01-01T00:00:00Z")

(defun mp (&rest a) (apply (find-symbol "MAKE-PROVISION" :orchestrator.consolidation) a))
(defun md (&rest a) (apply (find-symbol "MAKE-LEGAL-DOCUMENT" :orchestrator.consolidation) a))
(defun ma (&rest a) (apply (find-symbol "MAKE-AMENDING-ACT" :orchestrator.consolidation) a))
(defun cons* (&rest a) (apply (find-symbol "CONSOLIDATE" :orchestrator.consolidation) a))

(defun build ()
  (cons* (md :id "demo" :title "Δοκιμαστικός Κώδικας" :language "el" :work-date "2020-01-01"
             :provisions (list (mp :eid "art_1" :kind :article :num "1" :heading "Σκοπός" :text "Αρχικό."
                                   :children (list (mp :eid "art_1__para_1" :kind :paragraph :num "1" :text "Πρώτη.")
                                                   (mp :eid "art_1__para_2" :kind :paragraph :num "2" :text "Δεύτερη.")))
                               (mp :eid "art_2" :kind :article :num "2" :heading "Β" :text "Δεύτερο.")
                               (mp :eid "art_3" :kind :article :num "3" :heading "Γ" :text "Τρίτο.")))
         (list (ma :id "Ν.4855/2021" :effective "2021-11-12"
                   :operations (list (list :op :replace-text :target "art_1" :text "Νέο κείμενο.")))
               (ma :id "Ν.4999/2022" :effective "2022-01-05"
                   :operations (list (list :op :repeal :target "art_3"))))
         :as-of-date "2025-01-01"))

(defun slurp (path) (with-open-file (s path :external-format :utf-8)
                      (let ((b (make-string (file-length s)))) (subseq b 0 (read-sequence b s)))))

(let* ((doc (build))
       (out "/tmp/site-test/")
       (base "https://stavropouloslaw.com/eli"))
  (emit-static-site (list (cons "demo" doc)) out :base-uri base)

  (format t "~%== Tree completeness ==~%")
  (dolist (rel '(".well-known/ai-corpus.json" "llms.txt" "robots.txt" "sitemap.xml" "index.html"
                 "demo/index.html" "demo/corpus.jsonl" "demo/catalog.jsonld"
                 "demo/consolidated.ttl" "demo/consolidated.akn.xml"
                 "demo/dataset.jsonl" "demo/provenance.ttl" "demo/eu-references.json"
                 "demo/article/art_1/index.html" "demo/article/art_1.jsonld"
                 "demo/article/art_3/index.html"))
    (check (format nil "exists: ~A" rel)
           (probe-file (merge-pathnames rel out))))

  (format t "~%== Human HTML (amended article) ==~%")
  (let ((h (slurp (merge-pathnames "demo/article/art_1/index.html" out))))
    (check "title shows article + heading" (search "<title>Άρθρο 1 - Σκοπός" h))
    (check "in-force badge" (search "badge in-force" h))
    (check "amendment note cites the act + date"
           (and (search "Τροποποιήθηκε από" h) (search "Ν.4855/2021" h) (search "2021-11-12" h)))
    (check "paragraphs rendered with RDFa" (search "property=\"schema:text\"" h))
    (check "embedded Legislation JSON-LD" (search "\"@type\": \"Legislation\"" h))
    (check "embedded breadcrumb JSON-LD" (search "BreadcrumbList" h))
    (check "publisher = firm (root authority)" (search "Stavropoulos Law®" h))
    (check "links to AI formats" (and (search "art_1.jsonld" h) (search "consolidated.ttl" h)))
    (check "no tracking beacon (privacy)" (null (search "sendBeacon" h))))

  (format t "~%== Repealed article reflects status ==~%")
  (let ((h (slurp (merge-pathnames "demo/article/art_3/index.html" out))))
    (check "repealed badge" (search "badge repealed" h))
    (check "JSON-LD legal force Repealed"
           (search "\"legislationLegalForce\": \"Repealed\""
                   (slurp (merge-pathnames "demo/article/art_3.jsonld" out)))))

  (format t "~%== Discovery / robots / sitemap (AI root authority) ==~%")
  (let ((disc (slurp (merge-pathnames ".well-known/ai-corpus.json" out)))
        (robots (slurp (merge-pathnames "robots.txt" out)))
        (sm (slurp (merge-pathnames "sitemap.xml" out))))
    (check "discovery declares ai_first + publisher"
           (and (search "\"ai_first\": true" disc) (search "Stavropoulos Law®" disc)))
    (check "discovery lists corpus bulk + dataset"
           (and (search "/demo/corpus.jsonl" disc) (search "/demo/dataset.jsonl" disc)))
    (check "robots welcomes GPTBot + ClaudeBot"
           (and (search "GPTBot" robots) (search "ClaudeBot" robots)))
    (check "robots points to sitemap" (search "Sitemap: https://stavropouloslaw.com/sitemap.xml" robots))
    (check "sitemap lists every article"
           (and (search "/demo/article/art_1" sm) (search "/demo/article/art_2" sm)
                (search "/demo/article/art_3" sm))))

  (format t "~%== Born-cited: every output points to its verifiable proof ==~%")
  (let ((jld (slurp (merge-pathnames "demo/article/art_1.jsonld" out)))
        (disc (slurp (merge-pathnames ".well-known/ai-corpus.json" out)))
        (llms (slurp (merge-pathnames "llms.txt" out))))
    (check "JSON-LD carries the canonical citation"
           (and (search "\"citation\":" jld) (search "Άρθρο 1" jld)))
    (check "JSON-LD names the PRIMARY official source (ΦΕΚ/et.gr) via isBasedOn"
           (and (search "\"isBasedOn\":" jld) (search "https://www.et.gr" jld)))
    (check "JSON-LD declares the open license per article"
           (search "https://creativecommons.org/licenses/by/4.0/" jld))
    (check "JSON-LD links the per-provision PCL proof"
           (and (search "Proof-Carrying Law proof (PCL-1)" jld)
                (search ".proof.json" jld)))
    (check "discovery advertises PCL-1 verification + verifier"
           (and (search "\"protocol\": \"PCL-1\"" disc)
                (search "\"verifier\":" disc)
                (search "corpus-proof.json" disc)))
    (check "llms.txt is the AI entrypoint with citation + verification"
           (and (search "# Stavropoulos Law®" llms)
                (search "How to cite" llms)
                (search "How to verify" llms)
                (search "PCL-1" llms)))
    (check "llms.txt lists the corpus" (search "/demo/" llms)))

  (format t "~%== The born-cited proof links actually RESOLVE and VERIFY ==~%")
  (let ((verify (find-symbol "VERIFY-PROOF-JSON" :orchestrator.proof-carrying))
        (art1   (first (%doc-provisions doc))))
    (check "per-article proof file exists where the JSON-LD points"
           (probe-file (merge-pathnames "demo/article/art_1.proof.json" out)))
    (check "corpus anchor exists" (probe-file (merge-pathnames "demo/corpus-proof.json" out)))
    (check "the proof verifies against the EXACT text the page published"
           (multiple-value-bind (ok)
               (funcall verify (%article-canonical-text art1)
                        (slurp (merge-pathnames "demo/article/art_1.proof.json" out)))
             ok))
    (check "a tampered text is rejected by the emitted proof"
           (not (funcall verify "ΑΛΛΟΙΩΜΕΝΟ"
                         (slurp (merge-pathnames "demo/article/art_1.proof.json" out)))))
    (check "every article in the corpus carries a proof beside it"
           (every (lambda (p) (probe-file (merge-pathnames
                                           (format nil "demo/article/~A.proof.json" (%p-eid p)) out)))
                  (%doc-provisions doc))))

  (format t "~%== Determinism ==~%")
  (let ((a (slurp (merge-pathnames "demo/article/art_1/index.html" out))))
    (emit-static-site (list (cons "demo" (build))) "/tmp/site-test2/" :base-uri base)
    (check "article HTML byte-identical across runs"
           (string= a (slurp (merge-pathnames "demo/article/art_1/index.html" "/tmp/site-test2/"))))))

(format t "~%========================================~%")
(format t "Static site tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
