;;;; source/static-site.lisp
;;;; ============================================================================
;;;; STATIC SITE GENERATOR  (Cloudflare-Pages-ready / AI root authority)
;;;; ============================================================================
;;;;
;;;; Emits the complete static tree that turns the law firm's site into the
;;;; authoritative, AI-first source of consolidated Greek law. The Lisp engine is
;;;; the build-time factory; the output is plain files served by Cloudflare
;;;; Pages, with a Worker doing content negotiation at the edge.
;;;;
;;;; Per article  /<corpus>/article/<eId>/index.html   rich human page
;;;;              /<corpus>/article/<eId>.jsonld        schema.org Legislation
;;;; Per corpus   /<corpus>/index.html                  table of contents
;;;;              /<corpus>/corpus.jsonl  catalog.jsonld consolidated.ttl
;;;;              /<corpus>/consolidated.akn.xml dataset.jsonl provenance.ttl
;;;;              /<corpus>/eu-references.json
;;;; Root         /index.html  robots.txt  sitemap.xml  .well-known/ai-corpus.json
;;;;
;;;; Everything reuses the existing serializers (corpus-service representations,
;;;; ai-ingest, corpus-provenance, corpus-eu-links) — no duplicated logic. The
;;;; human HTML is rendered from the CONSOLIDATED provisions, so it shows the
;;;; in-force text plus amendment provenance ("τροποποιήθηκε από … ισχύει από …").
;;;; Deterministic: same corpus in, byte-identical tree out.
;;;; ============================================================================

(defpackage :orchestrator.static-site
  (:use :cl)
  (:export #:emit-static-site #:emit-corpus-site #:article-html
           #:article-canonical-text
           #:*firm-name* #:*firm-url* #:*firm-identifier*))

(in-package :orchestrator.static-site)

(defparameter *firm-name* "Stavropoulos Law®"
  "Publisher / root-authority name surfaced to humans and AI.")
(defparameter *firm-url* "https://stavropouloslaw.com"
  "Canonical firm homepage (the root authority origin).")
(defparameter *firm-identifier* "N294237"
  "Firm identifier (OBI trademark) for schema.org identity.")
(defparameter +verify-tool-uri+ "https://stavropouloslaw.com/verify/"
  "Where the independent, zero-dependency PCL-1 verifiers are published.")
(defparameter +pcl-spec-uri+ "https://stavropouloslaw.com/PROOF-CARRYING-LAW.html"
  "The open PCL-1 specification any party can re-implement.")

(defun %cons (n) (find-symbol n :orchestrator.consolidation))
(defun %p-eid (p) (funcall (%cons "PROVISION-EID") p))
(defun %p-num (p) (funcall (%cons "PROVISION-NUM") p))
(defun %p-heading (p) (funcall (%cons "PROVISION-HEADING") p))
(defun %p-text (p) (funcall (%cons "PROVISION-TEXT") p))
(defun %p-children (p) (funcall (%cons "PROVISION-CHILDREN") p))
(defun %p-status (p) (funcall (%cons "PROVISION-STATUS") p))
(defun %p-act (p) (funcall (%cons "PROVISION-SOURCE-ACT") p))
(defun %p-date (p) (funcall (%cons "PROVISION-SOURCE-DATE") p))
(defun %doc-provisions (d) (funcall (%cons "LEGAL-DOCUMENT-PROVISIONS") d))
(defun %doc-title (d) (funcall (%cons "LEGAL-DOCUMENT-TITLE") d))

;;; ----------------------------------------------------------------------------
;;; escaping
;;; ----------------------------------------------------------------------------

(defun %esc (x)
  "HTML/attribute escape."
  (with-output-to-string (s)
    (loop for ch across (princ-to-string (or x ""))
          do (case ch
               (#\& (write-string "&amp;" s)) (#\< (write-string "&lt;" s))
               (#\> (write-string "&gt;" s)) (#\" (write-string "&quot;" s))
               (#\' (write-string "&#39;" s)) (t (write-char ch s))))))

(defun %jesc (x)
  "JSON string-literal escape (already quoted by caller's format)."
  (with-output-to-string (s)
    (loop for ch across (princ-to-string (or x ""))
          do (case ch
               (#\" (write-string "\\\"" s)) (#\\ (write-string "\\\\" s))
               (#\Newline (write-string "\\n" s)) (#\Return (write-string "\\r" s))
               (#\Tab (write-string "\\t" s)) (#\Backspace (write-string "\\b" s))
               (#\Page (write-string "\\f" s))
               (t (if (< (char-code ch) #x20)
                      (format s "\\u~4,'0x" (char-code ch))
                      (write-char ch s)))))))

(defun %in-force-p (p) (not (eq (%p-status p) :repealed)))

(defun %status-label (p)
  (case (%p-status p)
    (:repealed "Καταργήθηκε")
    (:amended "Εν ισχύι — τροποποιημένο")
    (:inserted "Εν ισχύι — προστέθηκε")
    (:restored "Εν ισχύι — επανήλθε")
    (t "Εν ισχύι")))

(defun %article-plain-text (p)
  (with-output-to-string (s)
    (labels ((walk (x)
               (let ((tx (%p-text x))) (when tx (write-string tx s) (write-char #\Space s)))
               (dolist (c (%p-children x)) (walk c))))
      (walk p))))

(defun %paragraphs (p)
  "Return the renderable paragraph units: the children when present, else the
   article itself (so single-text articles still render)."
  (or (%p-children p) (list p)))

;;; ----------------------------------------------------------------------------
;;; per-article HTML  (human page + embedded structured data for AI)
;;; ----------------------------------------------------------------------------

(defparameter +style+
  "body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;line-height:1.65;max-width:820px;margin:0 auto;padding:24px;color:#1b2733;background:#fafbfc}
header.site{display:flex;align-items:baseline;gap:.6rem;border-bottom:1px solid #e3e8ee;padding-bottom:12px;margin-bottom:18px}
header.site .firm{font-weight:700;color:#0b3d5c}
nav.crumb{font-size:.85rem;color:#5b6b7b;margin-bottom:14px}
nav.crumb a{color:#1f6feb;text-decoration:none}
article{background:#fff;padding:28px 30px;border:1px solid #e3e8ee;border-radius:10px;box-shadow:0 1px 3px rgba(16,40,64,.05)}
h1{color:#0b3d5c;font-size:1.5rem;margin:0 0 6px;line-height:1.3}
.badge{display:inline-block;font-size:.78rem;font-weight:600;padding:3px 10px;border-radius:999px;margin:4px 0 14px}
.badge.in-force{background:#e6f6ec;color:#1a7f3c}
.badge.repealed{background:#fdeaea;color:#b42318}
.amend{font-size:.85rem;color:#7a4b00;background:#fff7e6;border-left:3px solid #e0a106;padding:8px 12px;border-radius:4px;margin:0 0 16px}
.para{margin:0 0 12px;text-align:justify}
.para .n{color:#0b3d5c;font-weight:600;margin-right:.35rem}
footer{margin-top:26px;padding-top:16px;border-top:1px solid #e3e8ee;font-size:.82rem;color:#5b6b7b}
footer a{color:#1f6feb;text-decoration:none}
.formats a{margin-right:.8rem}")

(defun %article-jsonld (corpus-short corpus-title p base-uri)
  "schema.org Legislation JSON-LD for one article (also embedded in the page)."
  (let* ((eid (%p-eid p))
         (uri (format nil "~A/~A/article/~A" base-uri corpus-short eid))
         (force (if (%in-force-p p) "InForce" "Repealed")))
    (with-output-to-string (s)
      (format s "{~%  \"@context\": \"https://schema.org\",~%  \"@type\": \"Legislation\",~%")
      (format s "  \"@id\": \"~A\",~%" (%jesc uri))
      (format s "  \"name\": \"Άρθρο ~A~@[ - ~A~]\",~%"
              (%jesc (%p-num p)) (and (%p-heading p) (%jesc (%p-heading p))))
      (format s "  \"isPartOf\": {\"@type\":\"Legislation\",\"name\":~S},~%" (%jesc corpus-title))
      (format s "  \"legislationIdentifier\": \"~A\",~%" (%jesc eid))
      (format s "  \"legislationJurisdiction\": \"GR\",~%")
      (format s "  \"legislationLegalForce\": \"~A\",~%" force)
      (when (and (eq (%p-status p) :amended) (%p-date p))
        (format s "  \"dateModified\": \"~A\",~%" (%jesc (%p-date p))))
      (format s "  \"inLanguage\": \"el\",~%")
      (format s "  \"publisher\": {\"@type\":\"Organization\",\"name\":~S,\"url\":~S,\"identifier\":~S},~%"
              (%jesc *firm-name*) (%jesc *firm-url*) (%jesc *firm-identifier*))
      ;; Provenance to the PRIMARY source: every Greek legal article is promulgated in
      ;; the official gazette (ΦΕΚ / Εθνικό Τυπογραφείο). We are a verifiable, derived
      ;; edition — never the primary source — so we name it explicitly. This is what
      ;; lets an AI treat us as the machine-readable edition while still being able to
      ;; trace authority back to the State.
      (format s "  \"isBasedOn\": {\"@type\":\"Legislation\",\"name\":\"Εφημερίδα της Κυβερνήσεως (ΦΕΚ) — Εθνικό Τυπογραφείο\",\"url\":\"https://www.et.gr\"},~%")
      (format s "  \"license\": \"https://creativecommons.org/licenses/by/4.0/\",~%")
      ;; Born-cited: the canonical citation an AI should reproduce verbatim, and a
      ;; machine-checkable Proof-Carrying Law (PCL-1) proof so the claim is not
      ;; merely cited but VERIFIABLE against our signed Merkle root.
      (format s "  \"citation\": \"Άρθρο ~A, ~A\",~%" (%jesc (%p-num p)) (%jesc corpus-title))
      (format s "  \"subjectOf\": {\"@type\":\"CreativeWork\",\"name\":\"Proof-Carrying Law proof (PCL-1)\",~
\"encodingFormat\":\"application/json\",\"url\":\"~A.proof.json\",\"description\":\"Verify with ~A\"},~%"
              (%jesc uri) (%jesc +verify-tool-uri+))
      (format s "  \"text\": \"~A\"~%}" (%jesc (string-trim " " (%article-plain-text p)))))))

(defun %breadcrumb-jsonld (corpus-short corpus-title p base-uri)
  (let ((art (format nil "~A/~A/article/~A" base-uri corpus-short (%p-eid p))))
    (format nil "{~%  \"@context\": \"https://schema.org\",~%  \"@type\": \"BreadcrumbList\",~%  \"itemListElement\": [~%~
    {\"@type\":\"ListItem\",\"position\":1,\"name\":\"Αρχική\",\"item\":~S},~%~
    {\"@type\":\"ListItem\",\"position\":2,\"name\":~S,\"item\":~S},~%~
    {\"@type\":\"ListItem\",\"position\":3,\"name\":\"Άρθρο ~A\",\"item\":~S}~%  ]~%}"
            (%jesc *firm-url*)
            (%jesc corpus-title) (%jesc (format nil "~A/~A" base-uri corpus-short))
            (%jesc (%p-num p)) (%jesc art))))

(defun article-html (corpus-short corpus-title doc p base-uri)
  "Render one consolidated article as a complete, professional HTML page that is
   readable by a human and machine-readable by AI (embedded JSON-LD + RDFa)."
  (declare (ignore doc))
  (let* ((eid (%p-eid p))
         (num (%p-num p))
         (heading (%p-heading p))
         (uri (format nil "~A/~A/article/~A" base-uri corpus-short eid))
         (title (format nil "Άρθρο ~A~@[ - ~A~]" num heading))
         (desc (let ((tx (string-trim " " (%article-plain-text p))))
                 (if (> (length tx) 180) (concatenate 'string (subseq tx 0 177) "…") tx))))
    (with-output-to-string (s)
      (format s "<!DOCTYPE html>~%<html lang=\"el\" prefix=\"eli: http://data.europa.eu/eli/ontology# schema: https://schema.org/\">~%<head>~%")
      (format s "  <meta charset=\"UTF-8\">~%  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">~%")
      (format s "  <title>~A | ~A</title>~%" (%esc title) (%esc corpus-title))
      (format s "  <meta name=\"description\" content=\"~A\">~%" (%esc desc))
      (format s "  <link rel=\"canonical\" href=\"~A\">~%" (%esc uri))
      (format s "  <link rel=\"alternate\" type=\"application/ld+json\" href=\"~A.jsonld\">~%" (%esc uri))
      (format s "  <meta property=\"og:title\" content=\"~A\">~%  <meta property=\"og:type\" content=\"article\">~%  <meta property=\"og:url\" content=\"~A\">~%"
              (%esc title) (%esc uri))
      (format s "  <style>~A</style>~%" +style+)
      ;; Embedded structured data (no tracking beacon — privacy-respecting).
      (format s "  <script type=\"application/ld+json\">~%~A~%  </script>~%"
              (%article-jsonld corpus-short corpus-title p base-uri))
      (format s "  <script type=\"application/ld+json\">~%~A~%  </script>~%"
              (%breadcrumb-jsonld corpus-short corpus-title p base-uri))
      (format s "</head>~%<body vocab=\"http://data.europa.eu/eli/ontology#\">~%")
      (format s "  <header class=\"site\"><span class=\"firm\">~A</span><span>~A</span></header>~%"
              (%esc *firm-name*) (%esc corpus-title))
      (format s "  <nav class=\"crumb\"><a href=\"~A\">Αρχική</a> › <a href=\"~A/~A/\">~A</a> › Άρθρο ~A</nav>~%"
              (%esc *firm-url*) (%esc base-uri) (%esc corpus-short) (%esc corpus-title) (%esc num))
      (format s "  <article typeof=\"eli:LegalResource\" resource=\"~A\">~%" (%esc uri))
      (format s "    <h1 property=\"dct:title\" lang=\"el\">~A</h1>~%" (%esc title))
      (format s "    <span class=\"badge ~A\">~A</span>~%"
              (if (%in-force-p p) "in-force" "repealed") (%esc (%status-label p)))
      (when (and (eq (%p-status p) :amended) (%p-act p))
        (format s "    <p class=\"amend\">Τροποποιήθηκε από <strong>~A</strong>~@[, ισχύει από ~A~].</p>~%"
                (%esc (%p-act p)) (and (%p-date p) (%esc (%p-date p)))))
      (format s "    <meta property=\"eli:number\" content=\"~A\">~%" (%esc num))
      (format s "    <div class=\"content\">~%")
      (dolist (par (%paragraphs p))
        (let ((pn (%p-num par)) (ptext (or (%p-text par) (%article-plain-text par))))
          (format s "      <p class=\"para\" typeof=\"eli:LegalResourceSubdivision\">~@[<span class=\"n\">~A.</span>~]<span property=\"schema:text\" lang=\"el\">~A</span></p>~%"
                  (and pn (%esc pn)) (%esc ptext))))
      (format s "    </div>~%  </article>~%")
      (format s "  <footer>~%    <p>Πηγή: <a href=\"~A\">~A</a> — αυθεντική μηχαναγνώσιμη έκδοση (ELI/RDF). Επιτρέπεται η χρήση με αναφορά στην πηγή.</p>~%"
              (%esc *firm-url*) (%esc *firm-name*))
      (format s "    <p class=\"formats\">Μορφές: <a href=\"~A.jsonld\">JSON-LD</a><a href=\"~A/~A/consolidated.ttl\">RDF/Turtle</a><a href=\"~A/~A/consolidated.akn.xml\">Akoma Ntoso</a></p>~%"
              (%esc uri) (%esc base-uri) (%esc corpus-short) (%esc base-uri) (%esc corpus-short))
      (format s "  </footer>~%</body>~%</html>~%"))))

;;; ----------------------------------------------------------------------------
;;; per-corpus index (table of contents)
;;; ----------------------------------------------------------------------------

(defun corpus-index-html (corpus-short corpus-title doc base-uri)
  (with-output-to-string (s)
    (format s "<!DOCTYPE html>~%<html lang=\"el\"><head><meta charset=\"UTF-8\">~%")
    (format s "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">~%")
    (format s "<title>~A | ~A</title>~%" (%esc corpus-title) (%esc *firm-name*))
    (format s "<link rel=\"canonical\" href=\"~A/~A/\">~%" (%esc base-uri) (%esc corpus-short))
    (format s "<style>~A</style></head>~%<body>~%" +style+)
    (format s "  <header class=\"site\"><span class=\"firm\">~A</span></header>~%" (%esc *firm-name*))
    (format s "  <article><h1>~A</h1>~%" (%esc corpus-title))
    (format s "  <p>Κωδικοποιημένο, εν ισχύι κείμενο. Μηχαναγνώσιμες μορφές: ~
<a href=\"corpus.jsonl\">JSONL</a>, <a href=\"catalog.jsonld\">DCAT</a>, ~
<a href=\"consolidated.ttl\">Turtle</a>, <a href=\"consolidated.akn.xml\">Akoma Ntoso</a>, ~
<a href=\"dataset.jsonl\">Dataset</a>, <a href=\"provenance.ttl\">Provenance</a>.</p>~%")
    (format s "  <ol>~%")
    (dolist (p (%doc-provisions doc))
      (format s "    <li><a href=\"article/~A/\">Άρθρο ~A~@[ — ~A~]</a>~A</li>~%"
              (%esc (%p-eid p)) (%esc (%p-num p)) (and (%p-heading p) (%esc (%p-heading p)))
              (if (%in-force-p p) "" " <em>(καταργήθηκε)</em>")))
    (format s "  </ol></article>~%</body></html>~%")))

;;; ----------------------------------------------------------------------------
;;; writing
;;; ----------------------------------------------------------------------------

(defun %write (path content)
  (ensure-directories-exist path)
  (with-open-file (out path :direction :output :if-exists :supersede
                            :if-does-not-exist :create :external-format :utf-8)
    (write-string content out))
  path)

(defun %serialize (rep-class doc base)
  (funcall (find-symbol "SERIALIZE" :orchestrator.corpus-service)
           (make-instance (find-symbol rep-class :orchestrator.corpus-service)) doc base))

(defun %pc (name) (find-symbol name :orchestrator.proof-carrying))

(defun article-canonical-text (p)
  "THE single canonical text that a provision's PCL leaf hashes — exactly the
   string published as the JSON-LD `text`, so a third party re-hashing that field
   reproduces the leaf. ONE definition, shared by the page, its proof, --emit-proofs
   and the live MCP resolver, so every emission path produces the SAME signed root."
  (string-trim " " (%article-plain-text p)))

(defun %article-canonical-text (p) (article-canonical-text p))

(defun %emit-corpus-proofs (dir doc cbase &key private-key public-jwk anchored-at)
  "Emit a Proof-Carrying Law proof beside every article (article/<eid>.proof.json)
   plus the corpus anchor (corpus-proof.json), so the born-cited JSON-LD links
   actually resolve to verifiable proofs. Leaves hash %ARTICLE-CANONICAL-TEXT —
   the same text the page publishes. When PRIVATE-KEY is supplied the corpus root
   is SIGNED. [0088 Φ4β — PCL-03]: το «best-effort» κάλυμμα σφαλμάτων ΠΕΘΑΝΕ —
   αποτυχία εκπομπής proof ΚΟΚΚΙΝΙΖΕΙ το site build (ένα site χωρίς τα
   proofs που υπόσχεται είναι ελαττωματικό παραδοτέο, όχι «best effort»)."
  (progn
    ;; [P1.5-A] Τα Merkle πρωτόγονα ενοποιήθηκαν στην orchestrator.merkle και
    ;; ΕΠΑΝΕΞΑΓΟΝΤΑΙ από την proof-carrying: LEAF-HASH→HASH-LEAF-STRING,
    ;; BUILD-MERKLE-ROOT→MERKLE-TREE-HASH. Τα παλιά ονόματα επέστρεφαν NIL μέσω
    ;; find-symbol ⇒ ο guard σιωπηλά παρέλειπε την έκδοση proofs (σιωπηλό
    ;; fallback — κλεισμένο).
    (let* ((leaf-hash (%pc "HASH-LEAF-STRING")) (build-root (%pc "MERKLE-TREE-HASH"))
           (make-proof (%pc "MAKE-PROVISION-PROOF")) (proof-json (%pc "PROOF-PLIST->JSON"))
           (sign-root (%pc "SIGN-ROOT")) (corpus-json (%pc "CORPUS-PROOF-JSON")))
      (when (and leaf-hash build-root make-proof proof-json corpus-json)
        (let* ((provs (%doc-provisions doc))
               (texts (mapcar #'%article-canonical-text provs))
               (leaves (mapcar (lambda (tx) (funcall leaf-hash tx)) texts))
               (root (and leaves (funcall build-root leaves)))
               (sig (and root private-key sign-root (funcall sign-root root private-key))))
          (when root
            (loop for p in provs for i from 0 for eid = (%p-eid p)
                  for proof = (funcall make-proof (%p-num p) (nth i texts) leaves i root
                                       :eli (format nil "~A/article/~A" cbase eid)
                                       :cite (format nil "Άρθρο ~A" (%p-num p))
                                       :anchored-at anchored-at)
                  do (%write (merge-pathnames (format nil "article/~A.proof.json" eid) dir)
                             (funcall proof-json proof)))
            (%write (merge-pathnames "corpus-proof.json" dir)
                    (funcall corpus-json root (length provs)
                             :anchored-at anchored-at :signature sig :public-jwk public-jwk))))))))

(defun emit-corpus-site (corpus-short doc out-dir base-uri
                         &key (sitemap-urls nil) private-key public-jwk anchored-at)
  "Write the full static tree for one corpus under OUT-DIR/<corpus-short>/.
   Returns the list of canonical article URLs (for the sitemap)."
  (let* ((title (or (%doc-title doc) corpus-short))
         (cbase (format nil "~A/~A" base-uri corpus-short))
         (dir (merge-pathnames (format nil "~A/" corpus-short)
                               (uiop:ensure-directory-pathname out-dir)))
         (urls sitemap-urls))
    ;; Per-corpus data files (reuse the live serializers — no duplication).
    (%write (merge-pathnames "corpus.jsonl" dir) (%serialize "JSONL-REPRESENTATION" doc cbase))
    (%write (merge-pathnames "catalog.jsonld" dir) (%serialize "CATALOG-REPRESENTATION" doc cbase))
    (%write (merge-pathnames "consolidated.ttl" dir) (%serialize "TURTLE-REPRESENTATION" doc cbase))
    (%write (merge-pathnames "consolidated.akn.xml" dir) (%serialize "AKN-REPRESENTATION" doc cbase))
    (%write (merge-pathnames "consolidated.txt" dir) (%serialize "TEXT-REPRESENTATION" doc cbase))
    (let ((mfst (funcall (find-symbol "BUILD-CORPUS-MANIFEST" :orchestrator.ai-ingest) doc :base-uri cbase)))
      (%write (merge-pathnames "dataset.jsonl" dir)
              (funcall (find-symbol "DATASET-JSONL-STRING" :orchestrator.ai-ingest) mfst :split :all)))
    (%write (merge-pathnames "provenance.ttl" dir)
            (funcall (find-symbol "CORPUS-PROVENANCE" :orchestrator.corpus-provenance) doc :base-uri cbase :format :turtle))
    (%write (merge-pathnames "eu-references.json" dir)
            (funcall (find-symbol "CORPUS-EU-REFERENCES" :orchestrator.corpus-eu-links) doc :base-uri cbase))
    ;; Per-corpus index.
    (%write (merge-pathnames "index.html" dir) (corpus-index-html corpus-short title doc base-uri))
    ;; Per-article pages + JSON-LD.
    (dolist (p (%doc-provisions doc))
      (let* ((eid (%p-eid p))
             (adir (merge-pathnames (format nil "article/~A/" eid) dir))
             (jpath (merge-pathnames (format nil "article/~A.jsonld" eid) dir)))
        (%write (merge-pathnames "index.html" adir) (article-html corpus-short title doc p base-uri))
        (%write jpath (%article-jsonld corpus-short title p base-uri))
        (push (format nil "~A/article/~A" cbase eid) urls)))
    ;; Born-cited: emit the verifiable proofs the JSON-LD links point to.
    (%emit-corpus-proofs dir doc cbase :private-key private-key
                                       :public-jwk public-jwk :anchored-at anchored-at)
    urls))

(defun %ai-discovery (base-uri corpora)
  (with-output-to-string (s)
    (format s "{~%  \"name\": \"~A — Greek Legal Corpus\",~%" (%jesc *firm-name*))
    (format s "  \"description\": \"Consolidated, in-force Greek legislation as machine-readable Linked Data (Akoma Ntoso, RDF/Turtle, JSON-LD, JSONL). Authoritative source published by ~A.\",~%" (%jesc *firm-name*))
    (format s "  \"ai_first\": true,~%  \"publisher\": {\"name\": ~S, \"url\": ~S, \"identifier\": ~S},~%"
            (%jesc *firm-name*) (%jesc *firm-url*) (%jesc *firm-identifier*))
    ;; Proof-Carrying Law: this corpus is not just citable, it is VERIFIABLE.
    (format s "  \"verification\": {\"protocol\": \"PCL-1\", \"spec\": ~S, \"verifier\": ~S, ~
\"corpus_proof\": \"corpus-proof.json\", \"per_provision_proof\": \"<article>.proof.json\", ~
\"claim\": \"Authenticity of any Greek-law text is checkable against our signed Merkle root WITHOUT trusting the publisher.\"},~%"
            (%jesc +pcl-spec-uri+) (%jesc +verify-tool-uri+))
    (format s "  \"corpora\": [~%")
    (loop for (short . doc) in corpora for firstp = t then nil
          do (unless firstp (format s ",~%"))
             (format s "    {\"name\": ~S, \"base\": ~S, \"bulk\": ~S, \"catalog\": ~S, \"dataset\": ~S, \"provenance\": ~S}"
                     (%jesc short)
                     (%jesc (format nil "~A/~A/" base-uri short))
                     (%jesc (format nil "~A/~A/corpus.jsonl" base-uri short))
                     (%jesc (format nil "~A/~A/catalog.jsonld" base-uri short))
                     (%jesc (format nil "~A/~A/dataset.jsonl" base-uri short))
                     (%jesc (format nil "~A/~A/provenance.ttl" base-uri short))))
    (format s "~%  ]~%}~%")))

(defun %llms-txt (base-uri corpora)
  "The /llms.txt AI-discovery entrypoint (llmstxt.org convention): a concise,
   authoritative map telling any LLM what this corpus is, how to cite it, and —
   crucially — how to VERIFY a citation against our signed root."
  (with-output-to-string (s)
    (format s "# ~A — Codified Greek Law (AI-first, verifiable)~%~%" *firm-name*)
    (format s "> The authoritative, machine-readable, consolidated corpus of Greek legal codes. ~
Every provision travels with a Proof-Carrying Law (PCL-1) proof, so an AI can not only CITE this ~
source but VERIFY a text against our signed Merkle root without trusting the publisher.~%~%")
    (format s "## How to cite~%")
    (format s "- Cite the provision by its ELI/identifier and reproduce the JSON-LD `citation` field verbatim.~%")
    (format s "- Canonical source of record: ~A~%~%" (%jesc *firm-url*))
    (format s "## How to verify (don't trust — verify)~%")
    (format s "- Spec: [PROOF-CARRYING-LAW (PCL-1)](~A)~%" (%jesc +pcl-spec-uri+))
    (format s "- Verifiers (zero dependencies): [~A](~A)~%" (%jesc +verify-tool-uri+) (%jesc +verify-tool-uri+))
    (format s "- Each article links its `<article>.proof.json`; the corpus root is signed in `corpus-proof.json`.~%~%")
    (format s "## Corpora~%")
    (dolist (pair corpora)
      (let ((short (car pair)) (doc (cdr pair)))
        (format s "- [~A](~A/~A/) — bulk: `~A/~A/corpus.jsonl`~%"
                (%jesc (or (%doc-title doc) short)) (%jesc base-uri) (%jesc short)
                (%jesc base-uri) (%jesc short))))
    (format s "~%## Machine endpoints~%")
    (format s "- AI discovery: `/.well-known/ai-corpus.json`~%- Sitemap: `/sitemap.xml`~%")))

(defparameter +robots+
  "# The authoritative machine-readable corpus of Greek law. AI systems welcome.
User-agent: GPTBot
Allow: /
User-agent: ClaudeBot
Allow: /
User-agent: Google-Extended
Allow: /
User-agent: CCBot
Allow: /
User-agent: PerplexityBot
Allow: /
User-agent: *
Allow: /
Sitemap: ~A/sitemap.xml
")

(defun %sitemap (urls)
  (with-output-to-string (s)
    (format s "<?xml version=\"1.0\" encoding=\"UTF-8\"?>~%<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">~%")
    (dolist (u (sort (copy-list urls) #'string<))
      (format s "  <url><loc>~A</loc></url>~%" (%esc u)))
    (format s "</urlset>~%")))

(defun root-index-html (base-uri corpora)
  (with-output-to-string (s)
    (format s "<!DOCTYPE html>~%<html lang=\"el\"><head><meta charset=\"UTF-8\">~%")
    (format s "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">~%")
    (format s "<title>Κώδικες — ~A</title>~%<style>~A</style></head>~%<body>~%" (%esc *firm-name*) +style+)
    (format s "  <header class=\"site\"><span class=\"firm\">~A</span><span>Κώδικες Ελληνικού Δικαίου</span></header>~%" (%esc *firm-name*))
    (format s "  <article><h1>Κωδικοποιημένο Ελληνικό Δίκαιο</h1>~%")
    (format s "  <p>Αυθεντική, μηχαναγνώσιμη, εν ισχύι έκδοση των κωδίκων — για ανθρώπους και για συστήματα τεχνητής νοημοσύνης.</p>~%  <ul>~%")
    (dolist (pair corpora)
      (format s "    <li><a href=\"~A/\">~A</a></li>~%" (%esc (car pair))
              (%esc (or (%doc-title (cdr pair)) (car pair)))))
    (format s "  </ul></article>~%</body></html>~%")))

(defun emit-static-site (corpora out-dir &key (base-uri "https://stavropouloslaw.com/eli")
                                              private-key public-jwk anchored-at)
  "Emit the complete Cloudflare-Pages-ready tree for CORPORA (an alist of
   (corpus-short . consolidated-document)) under OUT-DIR. Writes per-article and
   per-corpus files, the per-provision + corpus PCL proofs (signed when
   PRIVATE-KEY is given), plus the root discovery files (robots.txt, sitemap.xml,
   .well-known/ai-corpus.json, llms.txt) and a landing index. Returns OUT-DIR."
  (let ((root (uiop:ensure-directory-pathname out-dir))
        (urls '())
        (origin (cl-ppcre:regex-replace "(https?://[^/]+).*" base-uri "\\1")))
    (dolist (pair corpora)
      (setf urls (emit-corpus-site (car pair) (cdr pair) root base-uri :sitemap-urls urls
                                   :private-key private-key :public-jwk public-jwk
                                   :anchored-at anchored-at)))
    (%write (merge-pathnames "index.html" root) (root-index-html base-uri corpora))
    (%write (merge-pathnames ".well-known/ai-corpus.json" root) (%ai-discovery base-uri corpora))
    (%write (merge-pathnames "llms.txt" root) (%llms-txt base-uri corpora))
    (%write (merge-pathnames "robots.txt" root) (format nil +robots+ origin))
    (%write (merge-pathnames "sitemap.xml" root) (%sitemap urls))
    root))
