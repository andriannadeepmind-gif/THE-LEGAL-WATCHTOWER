;;;; source/government-source.lisp
;;;; ============================================================================
;;;; GOVERNMENT SOURCE FETCHER
;;;; ============================================================================
;;;;
;;;; Pulls each code's text from its official state source (κρατική πηγή) and
;;;; materializes the clean per-corpus JSON the rest of the system consumes.
;;;;
;;;; Each corpus config declares:
;;;;   source.url     - the official source URL (Hellenic Parliament, ΦΕΚ/et.gr,
;;;;                    Διαύγεια, e-nomothesia, ...)
;;;;   source.format  - "json" | "html" | "pdf"   (how to parse what comes back)
;;;;   source.json    - where to write the materialized clean JSON
;;;;
;;;; fetch-url downloads via Drakma (defensive: never throws, returns a status).
;;;; materialize-corpus downloads source.url, parses it by source.format into the
;;;; canonical [{title, content[]}] shape, and writes source.json — so a code
;;;; that was a placeholder becomes the real text once fetched, with no other
;;;; change to the pipeline or the service.
;;;;
;;;; Network access is required at runtime; this file performs no fetch at load
;;;; time and degrades gracefully when the source is unreachable.
;;;; ============================================================================

(defpackage :orchestrator.gov-source
  (:use :cl)
  (:export #:fetch-url #:materialize-corpus #:source-content->articles
           #:articles->json #:normalized-articles->json #:write-source-json
           #:make-feed-source
           #:make-fek-source #:*fek-search-url*
           #:make-diavgeia-source #:*diavgeia-search-url*
           #:html->text #:parse-fek-listing-html
           #:decode-cp1253))

(in-package :orchestrator.gov-source)

(defparameter *diavgeia-search-url* "https://diavgeia.gov.gr/opendata/search.json"
  "Διαύγεια opendata search endpoint.")

;;; ============================================================================
;;; WINDOWS-1253 (ελληνικά) — ο ΑΚΡΙΒΗΣ αποκωδικοποιητής
;;; ============================================================================
;;;
;;; babel δεν έχει cp1253, και η ISO-8859-7 (που έχει) διαφέρει στο 0x80–0x9F:
;;; εκεί το cp1253 έχει τα «έξυπνα» εισαγωγικά/παύλες/άνω τελεία (2018-2015)
;;; ενώ η 8859-7 έχει C1 controls. Τα δικαστικά κείμενα ΤΑ ΧΡΗΣΙΜΟΠΟΙΟΥΝ, οπότε
;;; για μηδέν λάθος χρειάζεται ο πραγματικός cp1253 πίνακας. Τα Ελληνικά γράμματα
;;; (0xC0–0xFF) ταυτίζονται με 8859-7· ο πίνακας κάτω είναι ο κανονικός Unicode
;;; χάρτης του cp1253, με #xFFFD στις 7 αόριστες θέσεις (0x81,88,8A,8C-8F,90,98,
;;; 9A,9C-9F,AA,D2,FF).

(defparameter +cp1253-high+
  (coerce
   #(#x20AC #xFFFD #x201A #x0192 #x201E #x2026 #x2020 #x2021   ; 80-87
     #xFFFD #x2030 #xFFFD #x2039 #xFFFD #xFFFD #xFFFD #xFFFD   ; 88-8F
     #xFFFD #x2018 #x2019 #x201C #x201D #x2022 #x2013 #x2014   ; 90-97
     #xFFFD #x2122 #xFFFD #x203A #xFFFD #xFFFD #xFFFD #xFFFD   ; 98-9F
     #x00A0 #x0385 #x0386 #x00A3 #x00A4 #x00A5 #x00A6 #x00A7   ; A0-A7
     #x00A8 #x00A9 #xFFFD #x00AB #x00AC #x00AD #x00AE #x2015   ; A8-AF
     #x00B0 #x00B1 #x00B2 #x00B3 #x0384 #x00B5 #x00B6 #x00B7   ; B0-B7
     #x0388 #x0389 #x038A #x00BB #x038C #x00BD #x038E #x038F   ; B8-BF
     #x0390 #x0391 #x0392 #x0393 #x0394 #x0395 #x0396 #x0397   ; C0-C7
     #x0398 #x0399 #x039A #x039B #x039C #x039D #x039E #x039F   ; C8-CF
     #x03A0 #x03A1 #xFFFD #x03A3 #x03A4 #x03A5 #x03A6 #x03A7   ; D0-D7
     #x03A8 #x03A9 #x03AA #x03AB #x03AC #x03AD #x03AE #x03AF   ; D8-DF
     #x03B0 #x03B1 #x03B2 #x03B3 #x03B4 #x03B5 #x03B6 #x03B7   ; E0-E7
     #x03B8 #x03B9 #x03BA #x03BB #x03BC #x03BD #x03BE #x03BF   ; E8-EF
     #x03C0 #x03C1 #x03C2 #x03C3 #x03C4 #x03C5 #x03C6 #x03C7   ; F0-F7
     #x03C8 #x03C9 #x03CA #x03CB #x03CC #x03CD #x03CE #xFFFD)  ; F8-FF
   '(simple-array (unsigned-byte 32) (128)))
  "Unicode code points for windows-1253 bytes 0x80–0xFF (index = byte − 128).")

(defun decode-cp1253 (octets)
  "Decode an OCTETS vector from windows-1253 (Greek) to a Lisp string. Bytes
   0x00–0x7F are ASCII; 0x80–0xFF map through +CP1253-HIGH+. Deterministic and
   total: an undefined byte becomes U+FFFD, never an error."
  (let ((s (make-string (length octets))))
    (dotimes (i (length octets) s)
      (let ((b (aref octets i)))
        (setf (char s i)
              (code-char (if (< b #x80) b (aref +cp1253-high+ (- b #x80)))))))))

;;; ============================================================================
;;; HTTP FETCH (defensive)
;;; ============================================================================

(defun %decode-body (body encoding)
  "Decode an octet BODY to a string per ENCODING (:utf-8 | :iso-8859-7 |
   :cp1253). cp1253 uses our exact table; the rest go through babel."
  (cond ((null body) nil)
        ((stringp body) body)
        ((eq encoding :cp1253) (decode-cp1253 body))
        (t (funcall (find-symbol "OCTETS-TO-STRING" :babel) body :encoding encoding))))

(defun fetch-url (url &key (timeout 60) binary parameters method (encoding :utf-8)
                          cookie-jar (user-agent "Mozilla/5.0"))
  "Fetch URL. Returns (values content status). CONTENT is a string decoded per
   ENCODING (or an octet vector when BINARY). METHOD defaults to :get, or :post
   when given — with PARAMETERS the form fields (drakma url-encodes them). A
   COOKIE-JAR (drakma:cookie-jar) threads session cookies across calls, which
   state search sites need when a result link carries a session-bound token.
   On any failure returns (values NIL <reason>); never throws, so a daemon can
   keep running."
  (handler-case
      (if (not (find-package :drakma))
          (values nil :no-http-client)
          ;; SSRF guard: reject internal/loopback/link-local/metadata hosts before
          ;; the request. Reuses the single guard in orchestrator.document-fetch
          ;; (no duplicate policy) via runtime FIND-SYMBOL — that package loads after
          ;; this file, so a package-qualified reference would break compilation.
          ;; hrefs pulled from an attacker-controlled ΦΕΚ search page flow through
          ;; here, so this is the choke point that matters.
          (if (let ((guard (find-symbol "URL-FETCH-ALLOWED-P" :orchestrator.document-fetch)))
                (and guard (not (funcall guard url))))
              (values nil :blocked-host)
          (multiple-value-bind (body status)
              (apply (find-symbol "HTTP-REQUEST" :drakma) url
                     :force-binary t          ; always octets; we decode below
                     :connection-timeout timeout
                     :redirect 5
                     :user-agent user-agent
                     (append
                      (when method (list :method method))
                      (when cookie-jar (list :cookie-jar cookie-jar))
                      (when parameters
                        (list :parameters parameters :external-format-out :utf-8))))
            ;; A TEXT request that got a BINARY body (docx/pdf/gzip — e.g. a
            ;; source.url pointing at the ministry's Word document) must never be
            ;; force-decoded as text: that is a category error, not a charset
            ;; issue. Classify by magic (the one table in orchestrator.document-fetch,
            ;; runtime lookup because that package loads after this file) and
            ;; return a named status the caller can act on.
            (let ((kind (and (not binary) (vectorp body)
                             (let ((k (find-symbol "CONTENT-MAGIC-KIND"
                                                   :orchestrator.document-fetch)))
                               (and k (funcall k body))))))
              (if kind
                  (values nil (list :binary-content kind))
                  (values (if binary body (%decode-body body encoding))
                          status))))))
    (error (e) (values nil (princ-to-string e)))))

;;; ============================================================================
;;; PARSE SOURCE CONTENT -> CANONICAL ARTICLES  [{title, content[]}]
;;; ============================================================================

(defun %json->articles (content)
  "Parse JSON source content into a list of article alists. Accepts either the
   canonical array [{title, content[]}] or an object {\"articles\": [...]}."
  (let ((parsed (funcall (find-symbol "PARSE" :jonathan) content :as :alist)))
    (cond
      ((null parsed) '())
      ;; An object (alist) — its first pair's car is the (string) key.
      ((and (consp (first parsed)) (stringp (car (first parsed))))
       (or (cdr (assoc "articles" parsed :test #'string=))
           (list parsed)))
      ;; Otherwise an array of article objects.
      (t parsed))))

(defun %html->articles (content &optional source-url)
  "Parse Hellenic-Parliament-style HTML into the canonical article maps via the
   parliament adapter. The adapter returns plists (:num :title :content …); map
   them to the {\"title\",\"content\"} alists the serializer expects, building the
   title as «Άρθρο N[ - heading]» to match the other corpora."
  (let ((fn (and (find-package :orchestrator.engine.sbcl)
                 (find-symbol "PARSE-PARLIAMENT-HTML" :orchestrator.engine.sbcl))))
    (unless (and fn (fboundp fn))
      (error "HTML source format requires the parliament adapter (parse-parliament-html)"))
    (loop for a in (funcall fn content source-url)
          for num = (getf a :num)
          for heading = (let ((h (getf a :title))) (and h (plusp (length h)) h))
          for body = (getf a :content)
          when (and num body (plusp (length (string-trim '(#\Space #\Tab #\Newline) body))))
            collect (list (cons "title" (format nil "Άρθρο ~A~@[ - ~A~]" num heading))
                          (cons "content" body)))))

(defun %url-base (url)
  "scheme://host of URL, for resolving relative sub-page links (no cl-ppcre dep)."
  (let* ((u (or url "")) (p (search "//" u)))
    (if p (let ((slash (position #\/ u :start (+ p 2))))
            (if slash (subseq u 0 slash) u))
        u)))

(defun %parliament-crawl->articles (index-html source-url)
  "Crawl the Σύνταγμα: feed the index HTML to the Lisp crawler, fetching each
   /…/syntagma/article-N/ sub-page (relative links resolved against SOURCE-URL's
   host). Returns the canonical {title,content[]} article maps."
  (let ((crawl (and (find-package :orchestrator.engine.sbcl)
                    (find-symbol "CRAWL-CONSTITUTION" :orchestrator.engine.sbcl)))
        (base (%url-base source-url)))
    (unless (and crawl (fboundp crawl))
      (error "parliament-crawl requires orchestrator.engine.sbcl:crawl-constitution"))
    (funcall crawl index-html
             (lambda (path)
               (let ((u (if (and (>= (length path) 4) (string-equal "http" (subseq path 0 4)))
                            path
                            (concatenate 'string base path))))
                 (fetch-url u))))))   ; first value (content) is what the crawler wants

(defun source-content->articles (content format &optional source-url)
  "Normalize fetched CONTENT (per FORMAT keyword) into the canonical article maps.
   SOURCE-URL is threaded to the HTML/crawler adapters.
     :json             — a clean-JSON array (or {articles:[…]})
     :html             — a single Parliament page (parse-parliament-html)
     :parliament-crawl — a Parliament INDEX page → crawl its article sub-pages
     :pdf              — runs through the PDF pipeline instead"
  (ecase format
    (:json (%json->articles content))
    (:html (%html->articles content source-url))
    (:parliament-crawl (%parliament-crawl->articles content source-url))
    (:pdf (error "PDF source materialization runs through the PDF pipeline; ~
                  configure source.pdf and run --run-pipeline for ~A" format))))

;;; ============================================================================
;;; SERIALIZE CANONICAL ARTICLES BACK TO CLEAN JSON
;;; ============================================================================

(defun articles->json (articles)
  "Serialize a list of article maps to the canonical clean-JSON string. Each map may
   carry an optional \"date\"; \"content\" may be a string or a list of paragraphs.
   Emits the same {title[,date],content[]} shape the Constitution uses."
  (with-output-to-string (s)
    (write-string "[" s)
    (loop for a in articles for firstp = t then nil
          do (unless firstp (write-string "," s))
             (let ((title (or (cdr (assoc "title" a :test #'string=)) ""))
                   (date (cdr (assoc "date" a :test #'string=)))
                   (content (or (cdr (assoc "content" a :test #'string=)) '())))
               (format s "{\"title\":~A~@[,\"date\":~A~],\"content\":[~A]}"
                       (jstr title)
                       (and date (plusp (length (princ-to-string date))) (jstr date))
                       (with-output-to-string (cs)
                         (loop for c in (if (listp content) content (list content))
                               for cf = t then nil
                               do (unless cf (write-string "," cs))
                                  (write-string (jstr (princ-to-string c)) cs))))))
    (write-string "]" s)))

(defun jstr (x)
  (with-output-to-string (s)
    (write-char #\" s)
    (loop for ch across (princ-to-string (or x ""))
          do (case ch
               (#\" (write-string "\\\"" s))
               (#\\ (write-string "\\\\" s))
               (#\Newline (write-string "\\n" s))
               (#\Return (write-string "\\r" s))
               (#\Tab (write-string "\\t" s))
               (t (write-char ch s))))
    (write-char #\" s)))

;;; ============================================================================
;;; MATERIALIZE FROM THE PDF  (the extracted code -> canonical source.json)
;;; ============================================================================
;;;
;;; A PDF-sourced code (ΦΕΚ) is parsed by the pipeline into normalized-article
;;; inputs (IIR). To make that REAL extracted text the corpus's source — so the
;;; consolidation, the intelligence suite and the served corpus all read the code
;;; the PDF produced, not a placeholder — we serialize the IIR list back to the
;;; canonical clean JSON [{title, content}] that corpus-spec reads as source.json.

(defun %model-accessor (name)
  "Resolve an orchestrator.model accessor by NAME, defensively (no hard package
   coupling / load-order dependency)."
  (let ((s (and (find-package :orchestrator.model)
                (find-symbol name :orchestrator.model))))
    (and s (fboundp s) s)))

(defun %normalize-date (date)
  "Normalize an ISO YYYY-MM-DD date to the DD/MM/YYYY display form the canonical
   JSON uses (matching the Constitution). Non-ISO input is returned unchanged."
  (let ((d (and date (string-trim '(#\Space) (princ-to-string date)))))
    (if (and d (= (length d) 10) (char= (char d 4) #\-) (char= (char d 7) #\-))
        (format nil "~A/~A/~A" (subseq d 8 10) (subseq d 5 7) (subseq d 0 4))
        d)))

(defun %split-paragraphs (content)
  "Split a joined article body into the canonical paragraph ARRAY (one element per
   line / numbered subsection), trimming and dropping empty lines — the same shape
   the Constitution's content uses. A list is returned as-is."
  (if (listp content)
      content
      (remove-if (lambda (s) (zerop (length s)))
                 (mapcar (lambda (l) (string-trim '(#\Space #\Tab #\Return) l))
                         (uiop:split-string (princ-to-string content)
                                            :separator '(#\Newline))))))

(defun normalized-articles->json (iir-list &optional date)
  "Serialize a list of normalized-article-input (IIR) to the canonical clean JSON
   [{title[, date], content[]}] — the SAME rich shape the Constitution uses:
   content is split into a paragraph array (not one raw blob) and, when DATE is
   given, every article carries it (normalized to DD/MM/YYYY)."
  (let ((title-fn (%model-accessor "ARTICLE-TITLE"))
        (content-fn (%model-accessor "ARTICLE-CONTENT"))
        (meta-fn (%model-accessor "SOURCE-METADATA"))
        (ndate (and date (plusp (length (string-trim " " (princ-to-string date))))
                    (%normalize-date date))))
    (articles->json
     (loop for iir in iir-list
           ;; the ARTICLE's own version date (source-recorded last modification)
           ;; wins over the corpus-wide date: point-in-time law needs per-article
           ;; granularity (tempus regit actum).
           for adate = (or (and meta-fn
                                (getf (funcall meta-fn iir) :last-modified))
                           ndate)
           collect (append
                    (list (cons "title" (or (and title-fn (funcall title-fn iir)) ""))
                          (cons "content"
                                (%split-paragraphs
                                 (or (and content-fn (funcall content-fn iir)) ""))))
                    (when adate (list (cons "date" adate))))))))

(defun write-source-json (iir-list json-path &optional date)
  "Write the IIR list as the canonical clean JSON to JSON-PATH (deterministic,
   UTF-8). DATE (the code's ΦΕΚ/publication date) is stamped on every article like
   the Constitution. Returns the number of articles written."
  (ensure-directories-exist json-path)
  (with-open-file (out json-path :direction :output :if-exists :supersede
                                 :if-does-not-exist :create :external-format :utf-8)
    (write-string (normalized-articles->json iir-list date) out))
  (length iir-list))

;;; ============================================================================
;;; MATERIALIZE  (fetch -> parse -> write clean JSON)
;;; ============================================================================

(defun materialize-corpus (&key url format json-path)
  "Fetch URL (the κρατική πηγή), parse it by FORMAT, and write the canonical
   clean JSON to JSON-PATH. Returns (values article-count :ok) on success or
   (values 0 reason) on failure (unreachable source, parse error, ...)."
  (unless (and url (plusp (length url)))
    (return-from materialize-corpus (values 0 :no-source-url)))
  (multiple-value-bind (content status) (fetch-url url)
    (if (or (null content) (and (integerp status) (>= status 400)))
        (values 0 (if (and (consp status) (eq (first status) :binary-content))
                      ;; Δυαδική πηγή (docx/pdf): δεν είναι text refresh — η
                      ;; ενημέρωσή της περνά από --fetch-pdf → --materialize-pdf.
                      (list :binary-source (second status)
                            :use "--fetch-pdf → --materialize-pdf")
                      (list :fetch-failed status)))
        (handler-case
            (let* ((articles (source-content->articles
                              (if (stringp content) content
                                  (map 'string #'code-char content))
                              format url))
                   (json (articles->json articles)))
              (ensure-directories-exist json-path)
              (with-open-file (out json-path :direction :output
                                             :if-exists :supersede
                                             :if-does-not-exist :create
                                             :external-format :utf-8)
                (write-string json out))
              (values (length articles) :ok))
          (error (e) (values 0 (list :parse-error (princ-to-string e))))))))

;;; ============================================================================
;;; GOVERNMENT FEED SOURCES  (ΦΕΚ laws / Διαύγεια decisions)
;;; ============================================================================
;;;
;;; A government feed is an orchestrator.ingestion source whose fetcher queries a
;;; state endpoint for items newer than the scheduler cursor and maps each to an
;;; ingest-item. The ONE generic core below is shared by every concrete feed
;;; (no duplication): it fetches, selects the items array, and for each item
;;; extracts the structured amendment record (the shape the consolidation feed
;;; consumes) from the item's text. Items whose text carries no amending formula
;;; keep their raw payload, so the feed ignores them instead of mis-consolidating.
;;;
;;; Field names differ per source (ΦΕΚ vs Διαύγεια), so they are parameters.

(defparameter *fek-search-url*
  "https://search.et.gr/el/"
  "ΦΕΚ (National Printing House) search page. The HTML of this page is read
   directly (no public JSON API). Override in deployment if needed.")

;;; ----------------------------------------------------------------------------
;;; HTML -> text / ΦΕΚ listing parsing  (regex-based, tolerant of messy HTML)
;;; ----------------------------------------------------------------------------

(defparameter +script-style+
  (cl-ppcre:create-scanner "<(script|style)[^>]*>.*?</\\1>"
                           :case-insensitive-mode t :single-line-mode t))
(defparameter +html-tag+ (cl-ppcre:create-scanner "<[^>]+>"))
(defparameter +ws-run+ (cl-ppcre:create-scanner "[ \\t\\r\\n]+"))

(defun %decode-entities (s)
  (let ((s s))
    (dolist (pair '(("&nbsp;?" . " ") ("&amp;" . "&") ("&lt;" . "<") ("&gt;" . ">")
                    ("&quot;" . "\"") ("&#39;" . "'") ("&apos;" . "'")
                    ("&laquo;" . "«") ("&raquo;" . "»") ("&#171;" . "«") ("&#187;" . "»")
                    ("&#8220;" . "«") ("&#8221;" . "»") ("&ldquo;" . "«") ("&rdquo;" . "»")))
      (setf s (cl-ppcre:regex-replace-all (car pair) s (cdr pair))))
    s))

(defun html->text (html)
  "Strip HTML to readable plain text: drop script/style, ΚΡΑΤΑ την δομή των
   παραγράφων (τα block tags — p/br/div/tr/li — γίνονται αλλαγές γραμμής ΠΡΙΝ
   αφαιρεθούν τα tags, ώστε μια απόφαση να διαβάζεται σαν απόφαση, όχι σαν μία
   ατέλειωτη γραμμή), remove tags, decode entities, collapse whitespace ΜΕΣΑ
   στην γραμμή μόνο."
  (let* ((s (or html ""))
         (s (cl-ppcre:regex-replace-all +script-style+ s " "))
         (s (cl-ppcre:regex-replace-all
             "(?i)</?(?:p|br|div|tr|li|h[1-6]|table)\\b[^>]*>" s (string #\Newline)))
         (s (cl-ppcre:regex-replace-all +html-tag+ s " "))
         (s (%decode-entities s))
         (s (cl-ppcre:regex-replace-all "[ \\t]+" s " "))          ; μέσα στη γραμμή
         (s (cl-ppcre:regex-replace-all " ?\\n ?" s (string #\Newline)))
         (s (cl-ppcre:regex-replace-all "\\n{3,}" s (format nil "~%~%"))))
    (string-trim '(#\Space #\Newline #\Tab #\Return) s)))

(defparameter +fek-anchor+
  (cl-ppcre:create-scanner "<a\\b[^>]*href=[\"']([^\"']+)[\"'][^>]*>(.*?)</a>"
                           :case-insensitive-mode t :single-line-mode t)
  "An HTML anchor. Reg 1 = href, Reg 2 = inner HTML.")

(defparameter +law-number+
  (cl-ppcre:create-scanner "(\\d{1,5})\\s*[/-]\\s*((?:19|20)\\d{2})")
  "A 'number/year' legislative reference. Reg 1 = number, Reg 2 = year.")

(defparameter +date-dmy+
  (cl-ppcre:create-scanner "(\\d{1,2})[/.\\-](\\d{1,2})[/.\\-]((?:19|20)\\d{2})")
  "A day/month/year date. Reg 1 = day, Reg 2 = month, Reg 3 = year.")

(defun %iso-date (text)
  "Find the first dd/mm/yyyy date in TEXT and return it as yyyy-mm-dd, or NIL."
  (cl-ppcre:register-groups-bind (d m y) (+date-dmy+ text)
    (format nil "~A-~2,'0D-~2,'0D" y (parse-integer m) (parse-integer d))))

(defun parse-fek-listing-html (html)
  "Extract ΦΕΚ/law entries from a search-results HTML page. Each entry is a
   string-keyed alist with keys 'number' 'publishDate' 'title' 'url'. Anchors
   that carry no number/year reference are ignored. Robust to unknown markup:
   it keys off the legislative reference pattern, not a fixed DOM structure."
  (let ((entries '()) (seen (make-hash-table :test 'equal)))
    (cl-ppcre:do-register-groups (href inner) (+fek-anchor+ (or html ""))
      (let ((text (html->text inner)))
        (cl-ppcre:register-groups-bind (num year) (+law-number+ text)
          (let ((number (format nil "~A/~A" num year)))
            (unless (gethash number seen)
              (setf (gethash number seen) t)
              (push (list (cons "number" number)
                          (cons "publishDate" (or (%iso-date text) (format nil "~A-01-01" year)))
                          (cons "title" text)
                          (cons "url" href))
                    entries))))))
    (nreverse entries)))

(defun %resolve-url (href base)
  "Resolve a possibly-relative HREF against BASE (scheme://host)."
  (cond ((null href) nil)
        ((or (null base) (and (>= (length href) 4) (string-equal (subseq href 0 4) "http"))) href)
        ((and (plusp (length href)) (char= (char href 0) #\/))
         (cl-ppcre:register-groups-bind (root) ("^(https?://[^/]+)" base)
           (concatenate 'string (or root base) href)))
        (t (concatenate 'string (string-right-trim "/" base) "/" href))))

(defun %sget (item key)
  "Read string KEY from a parsed item (string-keyed alist or hash-table)."
  (cond ((null key) nil)
        ((hash-table-p item) (gethash key item))
        ((and (listp item) (consp (first item)))
         (cdr (assoc key item :test #'equal)))
        (t nil)))

(defun %select-items (json items-path)
  "Select the items array from a parsed JSON response: the value under
   ITEMS-PATH, or JSON itself when it is already an array / ITEMS-PATH is NIL."
  (cond ((null items-path) json)
        (t (let ((v (%sget json items-path)))
             (or v
                 ;; A bare array response (first element is itself an item, not a
                 ;; string-keyed pair) is used as-is.
                 (and (listp json) json (not (and (consp (first json))
                                                  (stringp (car (first json)))))
                      json))))))

(defun %parse-json-items (content items-path)
  (%select-items (funcall (find-symbol "PARSE" :jonathan) content :as :alist)
                 items-path))

(defun %pdf-bytes-p (bytes)
  "True if BYTES begins with the PDF magic number (%PDF)."
  (and (typep bytes '(vector (unsigned-byte 8))) (>= (length bytes) 5)
       (= (aref bytes 0) 37) (= (aref bytes 1) 80)
       (= (aref bytes 2) 68) (= (aref bytes 3) 70)))

(defun %pdf->text (bytes)
  "Extract text from PDF BYTES via the project's PDF pipeline (poppler). Writes a
   transient temp file (the extractor takes a path) and removes it. Returns NIL
   when extraction is unavailable, so the daemon degrades gracefully."
  (let ((fn (and (find-package :orchestrator.pdf-authority)
                 (find-symbol "EXTRACT-PDF-TEXT" :orchestrator.pdf-authority))))
    (when (and fn (fboundp fn))
      (let ((tmp (format nil "/tmp/fek-doc-~A-~A.pdf"
                         (get-universal-time) (random 1000000))))
        (unwind-protect
             (progn
               (with-open-file (out tmp :direction :output :element-type '(unsigned-byte 8)
                                        :if-exists :supersede :if-does-not-exist :create)
                 (write-sequence bytes out))
               (ignore-errors (funcall fn tmp)))
          (ignore-errors (delete-file tmp)))))))

(defun %document-text (url)
  "Fetch URL as a legislative document and return its plain text. ΦΕΚ documents
   are PDF (routed through the PDF pipeline); an HTML document is stripped to
   text. Defensive: returns NIL on any failure."
  (multiple-value-bind (bytes st) (fetch-url url :binary t)
    (when (and bytes (not (and (integerp st) (>= st 400))))
      (if (%pdf-bytes-p bytes)
          (%pdf->text bytes)
          (html->text (funcall (find-symbol "OCTETS-TO-STRING" :babel)
                               (coerce bytes '(vector (unsigned-byte 8))) :encoding :utf-8))))))

(defun %item-text (it text-key title-key fetch-documents doc-key doc-base)
  "The amending text for an item: when FETCH-DOCUMENTS, fetch the linked
   document (PDF or HTML) and reduce it to text; otherwise use the item's
   text/title field."
  (or (when (and fetch-documents doc-key)
        (let ((u (%resolve-url (%sget it doc-key) doc-base)))
          (when u (%document-text u))))
      (%sget it text-key)
      (%sget it title-key)
      ""))

(defun make-feed-source (&key name url params items-path (format :json)
                              id-key date-key title-key doc-key text-key kind
                              fetch-documents doc-base)
  "Generic state legislation feed. Fetches URL (PARAMS UTF-8 encoded), parses the
   response (FORMAT :json with ITEMS-PATH, or :html via the ΦΕΚ listing parser),
   and maps each item to an ingest-item whose payload is the extracted amendment
   record (or the raw item). When FETCH-DOCUMENTS is true, each item's linked
   document is fetched and stripped to text for extraction (ΦΕΚ listings link to
   the law text rather than inlining it). Defensive: returns NIL on any failure."
  (funcall (find-symbol "MAKE-INGESTION-SOURCE" :orchestrator.ingestion)
   :name name
   :fetcher
   (lambda (since)
     (let ((qp (append params (when (and since date-key)
                                (list (cons "from_date" since))))))
       (multiple-value-bind (content status) (fetch-url url :parameters qp)
         (if (or (null content) (and (integerp status) (>= status 400)))
             nil
             (handler-case
                 (let ((items (ecase format
                                (:json (%parse-json-items content items-path))
                                (:html (parse-fek-listing-html content)))))
                   (loop for it in items
                         for text = (%item-text it text-key title-key
                                                fetch-documents doc-key doc-base)
                         ;; Only HIGH-confidence operations auto-apply; flagged
                         ;; ones (additions/new-articles/whole-law) ride along in
                         ;; "review" for human confirmation, never silently lost.
                         for record = (funcall (find-symbol "EXTRACT-AMENDMENT-RECORD"
                                                            :orchestrator.amendment-extractor)
                                               text
                                               :id (%sget it id-key)
                                               :date (%sget it date-key)
                                               :fek (or (%sget it "fek") (%sget it id-key)))
                         for usable = (or (cdr (assoc "operations" record :test #'equal))
                                          (cdr (assoc "review" record :test #'equal)))
                         collect (funcall (find-symbol "MAKE-INGEST-ITEM" :orchestrator.ingestion)
                                          :id (%sget it id-key)
                                          :title (%sget it title-key)
                                          :date (%sget it date-key)
                                          :source-uri (%resolve-url (%sget it doc-key) doc-base)
                                          :kind kind
                                          :payload (if usable record it))))
               (error () nil))))))))

(defun make-fek-source (&key (url *fek-search-url*) (fetch-documents t))
  "An ingestion source over the ΦΕΚ feed (Τεύχος Α' = laws). The initial
   production feed: the search-results HTML is read directly, each result's law
   document is fetched and its text parsed for the articles it amends.
   FETCH-DOCUMENTS nil restricts extraction to the listing text (for tests)."
  (make-feed-source
   :name "fek"
   :url url
   :format :html
   :fetch-documents fetch-documents
   :doc-base url
   :id-key "number" :date-key "publishDate" :title-key "title"
   :doc-key "url" :text-key "text" :kind "fek-law"))

(defun make-diavgeia-source (&key (types '("Δ.1")) (size 50))
  "An ingestion source over the Διαύγεια opendata feed (decisions). Retained for
   when decision-level ingestion is enabled; the ΦΕΚ feed is the initial source."
  (make-feed-source
   :name "diavgeia"
   :url *diavgeia-search-url*
   :params (append (list (cons "size" (princ-to-string size)))
                   (mapcar (lambda (ty) (cons "type" ty)) types))
   :items-path "decisions"
   :id-key "ada" :date-key "submissionTimestamp" :title-key "subject"
   :doc-key "documentUrl" :text-key "subject" :kind "diavgeia-decision"))
