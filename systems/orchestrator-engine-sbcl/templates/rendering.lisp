;;;; systems/orchestrator-engine-sbcl/templates/rendering.lisp
;;;; Template rendering for RDF, JSON-LD, and HTML

(in-package :orchestrator.engine.sbcl)

;;; ============================================================================
;;; RDF TURTLE RENDERING
;;; ============================================================================

(defun render-turtle (article corpus)
  "Render article as RDF Turtle
  
  Args:
    article: Article object
    corpus: Corpus object
  
  Returns:
    Turtle string"
  (format nil "
@prefix eli: <http://data.europa.eu/eli/ontology#> .
@prefix dct: <http://purl.org/dc/terms/> .
@prefix schema: <https://schema.org/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

<~A> a eli:LegalResource ;
    eli:id_local \"~A\" ;
    eli:number ~D ;
    eli:title \"~A\"@el ;
    eli:description \"\"\"~A\"\"\"@el ;
    eli:language <http://publications.europa.eu/resource/authority/language/ELL> ;
    eli:publisher <https://stavropouloslaw.com/#org> ;
    dct:creator <~A> ;
    dct:created \"~A\"^^xsd:date ;
    schema:author <~A> ;
    schema:inLanguage \"el\" .
"
          (article-eli-uri article)
          (article-base-filename article)
          (article-number article)
          (escape-turtle-string (article-title article))
          (escape-turtle-string (article-content article))
          (corpus-webid corpus)
          (format-date (orchestrator.time:now :source :system))
          (corpus-webid corpus)))

;;; ============================================================================
;;; JSON-LD RENDERING
;;; ============================================================================

;;; TEMPORARILY COMMENTED OUT FOR PHASE 3 TESTING
;;; Issue: JONATHAN macro expansion causes SBCL memory corruption
;;; This function is NOT the test target (escape functions are)
;;; Will be removed in Phase 4 along with rest of rendering.lisp

#|
(defun render-json-ld (article corpus)
  "Render article as JSON-LD

  Args:
    article: Article object
    corpus: Corpus object

  Returns:
    JSON-LD string"
  (jonathan:to-json
   `(:|@context| ("https://schema.org"
                  (:|eli| . "http://data.europa.eu/eli/ontology#"))
     :|@type| "LegalDocument"
     :|@id| ,(article-eli-uri article)
     :|identifier| ,(article-base-filename article)
     :|name| ,(article-title article)
     :|text| ,(article-content article)
     :|inLanguage| "el"
     :|author| (:|@type| "Person"
               :|@id| ,(corpus-webid corpus)
               :|name| "Spyridon Stavropoulos"
               :|identifier| ,(corpus-orcid corpus))
     :|publisher| (:|@type| "Organization"
                  :|@id| "https://stavropouloslaw.com/#org"
                  :|name| "STAVROPOULOS LAW")
     :|dateCreated| ,(format-date (orchestrator.time:now :source :system)))
   :from :alist))
|#

(defun %jsonld-escape (x)
  "Return X as a JSON string literal (quoted, with control chars escaped)."
  (with-output-to-string (s)
    (write-char #\" s)
    (loop for ch across (princ-to-string (or x ""))
          do (case ch
               (#\" (write-string "\\\"" s)) (#\\ (write-string "\\\\" s))
               (#\Newline (write-string "\\n" s)) (#\Return (write-string "\\r" s))
               (#\Tab (write-string "\\t" s)) (#\Backspace (write-string "\\b" s))
               (#\Page (write-string "\\f" s))
               (t (if (< (char-code ch) #x20)
                      (format s "\\u~4,'0x" (char-code ch))
                      (write-char ch s)))))
    (write-char #\" s)))

(defun render-json-ld (article corpus)
  "Render an article as schema.org / ELI JSON-LD.

   Restored as a manual string builder: the previous version relied on a
   jonathan macro expansion (with a malformed @context) that destabilised SBCL
   compilation. This version is deterministic and emits a valid JSON-LD object."
  (format nil "{\"@context\":{\"schema\":\"https://schema.org/\",~
\"eli\":\"http://data.europa.eu/eli/ontology#\"},~
\"@type\":\"schema:Legislation\",~
\"@id\":~A,~
\"schema:legislationIdentifier\":~A,~
\"schema:name\":~A,~
\"schema:text\":~A,~
\"schema:inLanguage\":\"el\",~
\"schema:isPartOf\":~A}"
          (%jsonld-escape (article-eli-uri article))
          (%jsonld-escape (princ-to-string (article-number article)))
          (%jsonld-escape (article-title article))
          (%jsonld-escape (article-content article))
          (%jsonld-escape (corpus-short-name corpus))))

;;; ============================================================================
;;; HTML WITH RDFA RENDERING
;;; ============================================================================

(defun render-html-rdfa (article corpus)
  "Render article as HTML with RDFa markup
  
  Args:
    article: Article object
    corpus: Corpus object
  
  Returns:
    HTML string"
  (format nil "<!DOCTYPE html>
<html lang=\"el\" prefix=\"eli: http://data.europa.eu/eli/ontology# schema: https://schema.org/\">
<head>
    <meta charset=\"UTF-8\">
    <title>Άρθρο ~D - ~A</title>
    <meta name=\"author\" content=\"Spyridon Stavropoulos\">
    <meta name=\"description\" content=\"~A\">
    
    <!-- Schema.org JSON-LD -->
    <script type=\"application/ld+json\">~A</script>
    
    <!-- Telemetry Beacon -->
    <script>
    (function() {
        if (navigator.sendBeacon) {
            fetch('https://telemetry.stavropouloslaw.com/beacon', {
                method: 'POST',
                body: JSON.stringify({
                    article: ~D,
                    corpus: '~A',
                    timestamp: Date.now(),
                    referrer: document.referrer,
                    ai_system: navigator.userAgent
                })
            }).catch(function() {});
        }
    })();
    </script>
</head>
<body vocab=\"https://schema.org/\" typeof=\"LegalDocument\">
    <article resource=\"~A\" typeof=\"eli:LegalResource\">
        <h1 property=\"eli:title\">~A</h1>
        <div property=\"eli:description\">~A</div>
        <meta property=\"eli:number\" content=\"~D\">
        <link property=\"dct:creator\" href=\"~A\">
        <link property=\"eli:publisher\" href=\"https://stavropouloslaw.com/#org\">
    </article>
</body>
</html>"
          (article-number article)
          (escape-html (article-title article))
          (escape-html (article-title article))
          (render-json-ld article corpus)
          (article-number article)
          (corpus-short-name corpus)
          (article-eli-uri article)
          (escape-html (article-title article))
          (escape-html (article-content article))
          (article-number article)
          (corpus-webid corpus)))

;;; ============================================================================
;;; DATE FORMATTING
;;; ============================================================================

(defun format-date (universal-time)
  "Format universal time as ISO 8601 date
  
  Args:
    universal-time: Universal time
  
  Returns:
    ISO 8601 date string (YYYY-MM-DD)"
  (multiple-value-bind (sec min hour day month year)
      (decode-universal-time universal-time)
    (declare (ignore sec min hour))
    (format nil "~4,'0D-~2,'0D-~2,'0D" year month day)))
