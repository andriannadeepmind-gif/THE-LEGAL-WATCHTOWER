;;;; source/document-fetch.lisp
;;;; ============================================================================
;;;; DOCUMENT FETCH — pure-Lisp orchestration of an EXTERNAL network-edge fetcher
;;;; ============================================================================
;;;;
;;;; The official Greek gazette (ΦΕΚ / et.gr) has no public API and blocks plain
;;;; HTTP clients, so a document often has to be fetched the way a real browser
;;;; would. A headless browser is NOT Common Lisp; rather than pull a whole
;;;; browser runtime into the hermetic core, this module keeps the ORCHESTRATION
;;;; pure Lisp and treats the fetcher as an EXTERNAL TOOL at the network boundary —
;;;; exactly as libpoppler is the external tool at the PDF boundary.
;;;;
;;;; A FETCH COMMAND is any shell command that downloads the document and writes it
;;;; to a path; the literal {{out}} in the command is replaced with the destination
;;;; path. The Lisp side runs it, then VALIDATES that a real PDF (the %PDF magic)
;;;; actually landed — so an anti-bot HTML page returned instead of a PDF is a
;;;; failure, never silently ingested. The fetcher (e.g. a Playwright script) is
;;;; deployed and scheduled by the operator; the corpus then updates with zero
;;;; manual uploads.
;;;;
;;;; Deterministic and side-effect-honest: returns a status, never throws.
;;;; ============================================================================

(defpackage :orchestrator.document-fetch
  (:use :cl)
  (:export #:fetch-pdf #:run-fetch-command #:pdf-file-p #:docx-file-p #:%substitute-out
           #:fek-blob-url #:fetch-fek-blob #:fetch-url-pdf #:fetch-url-docx #:*fek-blob-base*
           #:fek-blob-exists-p #:enumerate-new-fek #:url-fetch-allowed-p
           #:*allow-loopback-fetch*
           #:content-magic-kind))

(in-package :orchestrator.document-fetch)

(defun %substitute-out (template out-path)
  "Replace every literal {{out}} in TEMPLATE with OUT-PATH (no regex; exact)."
  (let ((needle "{{out}}") (s (princ-to-string template)) (path (namestring out-path)))
    (with-output-to-string (o)
      (loop with start = 0
            for pos = (search needle s :start2 start)
            do (cond (pos (write-string (subseq s start pos) o)
                          (write-string path o)
                          (setf start (+ pos (length needle))))
                     (t (write-string (subseq s start) o)
                        (return)))))))

(defparameter *content-magics*
  '((:pdf  #x25 #x50 #x44 #x46 #x2D)   ; %PDF-
    (:zip  #x50 #x4B #x03 #x04)        ; PK\03\04 — κάθε .docx/.xlsx είναι ZIP
    (:gzip #x1F #x8B))                 ; gzip
  "The ONE table of binary magic numbers. Both the file predicates below and the
   octet-level CONTENT-MAGIC-KIND classify from here, so they can never diverge.")

(defun content-magic-kind (octets)
  "Classify a fetched body by its leading magic bytes: :PDF, :ZIP (a .docx is a
   ZIP), :GZIP — or NIL for anything that may legitimately be text. The guard a
   TEXT decode must consult first: decoding a Word document as UTF-8 is never a
   parse strategy, it is a category error and deserves a named status.
   Strings are vectors too in CL — an already-decoded body is by definition
   text, so it is excluded here rather than compared char-vs-integer."
  (when (and (vectorp octets) (not (stringp octets)) (plusp (length octets)))
    (loop for (kind . magic) in *content-magics*
          when (and (>= (length octets) (length magic))
                    (loop for i from 0 below (length magic)
                          always (= (aref octets i) (nth i magic))))
            return kind)))

(defun %magic-file-p (path magic)
  "True iff PATH exists and its leading bytes equal the MAGIC octet list. The single
   guard shared by PDF-FILE-P and DOCX-FILE-P, so the two can never diverge — an
   anti-bot HTML body fails every magic check identically."
  (ignore-errors
    (and (probe-file path)
         (let ((n (length magic)))
           (with-open-file (s path :element-type '(unsigned-byte 8))
             (and (>= (file-length s) n)
                  (let ((buf (make-array n :element-type '(unsigned-byte 8))))
                    (and (= n (read-sequence buf s))
                         (loop for i from 0 below n
                               always (= (aref buf i) (nth i magic)))))))))))

(defun pdf-file-p (path)
  "True iff PATH begins with the PDF magic number (%PDF-). Guards against an
   anti-bot HTML page being mistaken for a downloaded PDF."
  (%magic-file-p path (cdr (assoc :pdf *content-magics*))))

(defun docx-file-p (path)
  "True iff PATH begins with the ZIP local-file-header magic (PK\\03\\04). Every
   .docx (Office Open XML) is a ZIP, so this rejects an anti-bot HTML page returned
   in place of the Word document — exactly as PDF-FILE-P does for a PDF."
  (%magic-file-p path (cdr (assoc :zip *content-magics*))))

(defun run-fetch-command (command &key (timeout 600))
  "Run COMMAND (a string) through /bin/sh — the external network-edge fetcher.
   Returns (values exit-code stderr-string); never throws. TIMEOUT seconds is a
   hint passed to the fetcher via the FETCH_TIMEOUT env var (the fetcher decides
   how to honour it)."
  (handler-case
      (multiple-value-bind (out err code)
          (uiop:run-program (list "/bin/sh" "-c" command)
                            :output :string :error-output :string
                            :ignore-error-status t
                            :environment (append (list (format nil "FETCH_TIMEOUT=~D" timeout))
                                                 (sb-ext:posix-environ)))
        (declare (ignore out))
        (values code err))
    (error (e) (values -1 (princ-to-string e)))))

;;; ----------------------------------------------------------------------------
;;; ΦΕΚ direct-blob fetch (PURE LISP, drakma) — no browser, no anti-bot.
;;; search.et.gr's own download link is a deterministic PUBLIC Azure blob, so a
;;; ΦΕΚ PDF is just an HTTPS GET built from its τεύχος/αριθμός/έτος:
;;;   https://…/fek/<GG>/<YYYY>/<YYYY><GG><NNNNN>.pdf
;;; This runs inside the hermetic core (drakma is already vendored for RFC-3161),
;;; so --fetch-pdf works in Docker/cron with zero external tools.
;;; ----------------------------------------------------------------------------

(defparameter *fek-blob-base* "https://ia37rg02wpsa01.blob.core.windows.net/fek"
  "Base URL of the National Printing House's public ΦΕΚ blob store.")

(defun %fek-series->group (series)
  "Map a ΦΕΚ τεύχος to its 2-digit group code (Α=01 … Δ=04). Accepts Greek or
   Latin letters, or an already-numeric group."
  (cond ((member series '("Α" "A" "α" "a" "1" "01") :test #'equal) "01")
        ((member series '("Β" "B" "β" "b" "2" "02") :test #'equal) "02")
        ((member series '("Γ" "γ" "3" "03")          :test #'equal) "03")
        ((member series '("Δ" "δ" "4" "04")          :test #'equal) "04")
        (t (format nil "~2,'0D" (or (ignore-errors (parse-integer (princ-to-string series))) 1)))))

(defun fek-blob-url (series number year &key (base *fek-blob-base*))
  "Deterministic public-blob URL of ΦΕΚ <SERIES> <NUMBER>/<YEAR>."
  (format nil "~A/~A/~A/~A~A~5,'0D.pdf"
          base (%fek-series->group series) year year (%fek-series->group series) number))

(defun fetch-fek-blob (series number year out-path &key (base *fek-blob-base*) (timeout 180))
  "Download ΦΕΚ <SERIES> <NUMBER>/<YEAR> straight from the public blob to OUT-PATH
   (pure Lisp via drakma). Returns (values ok-p status):
     :ok | (:http CODE) | :not-a-pdf | (:fetch-failed MESSAGE).
   Validates the %PDF magic — an error/HTML body is rejected, never ingested."
  (handler-case
      (let ((url (fek-blob-url series number year :base base)))
        (multiple-value-bind (body status)
            (uiop:symbol-call :drakma :http-request url
                              :force-binary t :connection-timeout timeout
                              :user-agent "stavropouloslaw-corpus/1.0")
          (cond
            ((not (eql status 200)) (values nil (list :http status)))
            ((not (typep body '(simple-array (unsigned-byte 8) (*)))) (values nil :not-a-pdf))
            (t (ignore-errors (ensure-directories-exist out-path))
               (with-open-file (o out-path :direction :output :element-type '(unsigned-byte 8)
                                           :if-exists :supersede :if-does-not-exist :create)
                 (write-sequence body o))
               (if (pdf-file-p out-path) (values t :ok) (values nil :not-a-pdf))))))
    (error (e) (values nil (list :fetch-failed (princ-to-string e))))))

(defun fek-blob-exists-p (series number year &key (base *fek-blob-base*) (timeout 30))
  "Lightweight existence probe for ΦΕΚ <SERIES> <NUMBER>/<YEAR> WITHOUT downloading
   the whole PDF — a Range GET of the first four bytes (HEAD is rejected by the
   blob, so Range is the cheap reliable check). T when the gazette is published
   (HTTP 200/206 and a %PDF body), NIL otherwise. The discovery enumerator uses
   this to find new gazettes cheaply."
  (handler-case
      (let ((url (fek-blob-url series number year :base base)))
        (multiple-value-bind (body status)
            (uiop:symbol-call :drakma :http-request url
                              :force-binary t :connection-timeout timeout
                              :additional-headers '(("Range" . "bytes=0-3"))
                              :user-agent "stavropouloslaw-corpus/1.0")
          (and (member status '(200 206))
               (typep body '(array (unsigned-byte 8) (*)))
               (>= (length body) 4)
               (= (aref body 0) #x25) (= (aref body 1) #x50)   ; %P
               (= (aref body 2) #x44) (= (aref body 3) #x46)))) ; DF
    (error () nil)))

(defun enumerate-new-fek (series year &key (from 1) (max-gap 3) (limit 3000)
                                            (exists-fn #'fek-blob-exists-p))
  "DISCOVERY: find published ΦΕΚ of SERIES/YEAR by walking numbers FROM upward,
   probing each via EXISTS-FN, and stopping after MAX-GAP consecutive misses
   (tolerates small holes in the published sequence) or after LIMIT probes.
   Returns the ascending list of numbers that exist — i.e. every gazette at or
   after FROM, so a daemon passes FROM = last-seen+1 to get only the NEW ones.
   EXISTS-FN is (series number year) -> boolean, injectable so the enumeration
   logic is unit-tested without any network."
  (let ((found '()) (gap 0) (n from) (probes 0))
    (loop
      (when (or (>= gap max-gap) (>= probes limit)) (return))
      (if (funcall exists-fn series n year)
          (progn (push n found) (setf gap 0))
          (incf gap))
      (incf n) (incf probes))
    (nreverse found)))

;;; ----------------------------------------------------------------------------
;;; SSRF GUARD — every fetched URL (and every redirect hop) is validated so a
;;; document source, or an href pulled out of an attacker-controlled ΦΕΚ search
;;; page, cannot be turned into a request against the cloud metadata endpoint or
;;; any internal/loopback/link-local host.
;;; ----------------------------------------------------------------------------

(defun %ipv4-octets (host)
  "If HOST is a dotted-quad IPv4 literal, return its 4 octets as a list, else NIL."
  (let ((parts (uiop:split-string host :separator '(#\.))))
    (when (= (length parts) 4)
      (let ((os (mapcar (lambda (p) (ignore-errors (parse-integer p :junk-allowed nil))) parts)))
        (when (every (lambda (o) (and (integerp o) (<= 0 o 255))) os) os)))))

(defun %private-ipv4-p (octets)
  "True for loopback / private / link-local / metadata / unspecified IPv4 ranges."
  (destructuring-bind (a b &rest r) octets
    (declare (ignore r))
    (or (= a 127)                                  ; loopback 127/8
        (= a 10)                                   ; private 10/8
        (and (= a 172) (<= 16 b 31))               ; private 172.16/12
        (and (= a 192) (= b 168))                  ; private 192.168/16
        (and (= a 169) (= b 254))                  ; link-local 169.254/16 (incl. 169.254.169.254 metadata)
        (= a 0)                                     ; 0.0.0.0/8
        (>= a 224))))                               ; multicast / reserved

(defun %url-host (url)
  "Extract the lowercased host from an http(s) URL, or NIL if the scheme is not
   http/https or the URL is unparseable."
  (let ((s (string-trim " " (or url ""))))
    (multiple-value-bind (m groups)
        (uiop:symbol-call :cl-ppcre :scan-to-strings
                          "^(?i)(https?)://([^/:?#]+)" s)
      (when m (string-downcase (aref groups 1))))))

(defvar *allow-loopback-fetch* nil
  "ΜΟΝΟ για test harnesses που σηκώνουν ΤΟΠΙΚΟ test server (127.0.0.1): όταν
   δεθεί δυναμικά σε T, ο SSRF φρουρός επιτρέπει ΑΠΟΚΛΕΙΣΤΙΚΑ loopback (127/8,
   localhost) — τα private/link-local/metadata (10/8, 172.16/12, 192.168/16,
   169.254/16, 0/8, multicast) μένουν ΠΑΝΤΑ μπλοκαρισμένα. Default NIL: η
   παραγωγική πολιτική ΑΜΕΤΑΒΛΗΤΗ. Απόφαση δημιουργού [0036] Δ1: dynamic
   binding με εμβέλεια το test, ΟΧΙ env flag (δεν «ξεχνιέται» σε παραγωγή —
   ένα unwind και επανέρχεται NIL).")

(defun %loopback-host-p (host)
  "Το HOST είναι loopback; (localhost ή 127/8 literal)."
  (or (string= host "localhost")
      (let ((octets (%ipv4-octets host)))
        (and octets (= (first octets) 127)))))

(defun url-fetch-allowed-p (url)
  "Gate an outbound fetch URL: require http/https and reject internal/loopback/
   link-local/metadata hosts (by IP literal). A non-IP hostname is allowed (public
   DNS names are the normal case); the residual DNS-rebinding vector is out of scope
   for a batch fetcher but the obvious literal-IP SSRF payloads are blocked.
   Εξαίρεση ΜΟΝΟ υπό *allow-loopback-fetch* (test-scoped binding): loopback
   επιτρέπεται· κάθε ΑΛΛΟ private/metadata host μένει μπλοκαρισμένο."
  (let ((host (%url-host url)))
    (and host
         (plusp (length host))
         (if (%loopback-host-p host)
             (and *allow-loopback-fetch* t)
             (let ((octets (%ipv4-octets host)))
               (or (null octets) (not (%private-ipv4-p octets))))))))

(defun %fetch-url-to-file (url out-path validator not-a-status &key (timeout 180))
  "GET URL (pure Lisp drakma) and write the body to OUT-PATH, accepting it ONLY when
   VALIDATOR (a predicate on the written path) passes — so an anti-bot HTML body is
   rejected, never ingested. Redirects are followed MANUALLY (up to 5 hops) so every
   hop's host passes the SSRF guard; drakma's automatic :redirect is disabled because
   it would follow a 3xx to an internal host without a per-hop check. NOT-A-STATUS is
   the status for a non-binary/invalid body. Returns (values ok-p status):
   :ok | (:http CODE) | :blocked-host | NOT-A-STATUS | (:fetch-failed MESSAGE). Never throws."
  (handler-case
      (let ((current url) (hops 0))
        (loop
          (unless (url-fetch-allowed-p current)
            (return (values nil :blocked-host)))
          (multiple-value-bind (body status headers uri)
              (uiop:symbol-call :drakma :http-request current
                                :force-binary t :connection-timeout timeout :redirect nil
                                :user-agent "stavropouloslaw-corpus/1.0")
            (declare (ignore uri))
            (cond
              ;; follow a redirect ourselves, re-validating the target host each hop
              ((and (member status '(301 302 303 307 308)) (< hops 5))
               (let ((loc (cdr (assoc :location headers))))
                 (unless loc (return (values nil (list :http status))))
                 (setf current loc) (incf hops)))
              ((not (eql status 200)) (return (values nil (list :http status))))
              ((not (typep body '(simple-array (unsigned-byte 8) (*))))
               (return (values nil not-a-status)))
              (t (ignore-errors (ensure-directories-exist out-path))
                 (with-open-file (o out-path :direction :output :element-type '(unsigned-byte 8)
                                             :if-exists :supersede :if-does-not-exist :create)
                   (write-sequence body o))
                 (return (if (funcall validator out-path) (values t :ok)
                             (values nil not-a-status))))))))
    (error (e) (values nil (list :fetch-failed (princ-to-string e))))))

(defun fetch-url-pdf (url out-path &key (timeout 180))
  "Download a PDF directly from any URL to OUT-PATH (pure Lisp via drakma) — for
   codes whose authoritative source is a plain PDF link rather than the ΦΕΚ blob.
   Returns (values ok-p status): :ok | (:http CODE) | :not-a-pdf | (:fetch-failed M)."
  (%fetch-url-to-file url out-path #'pdf-file-p :not-a-pdf :timeout timeout))

(defun fetch-url-docx (url out-path &key (timeout 180))
  "Download an Office Open XML (.docx) directly from any URL to OUT-PATH (pure Lisp
   via drakma) — for codes whose authoritative STATE source is a Word document (e.g.
   the Ministry of Justice ΚΠολΔ), not a PDF or the ΦΕΚ blob. The ZIP magic is
   validated, so an anti-bot HTML page is rejected, never ingested. This closes the
   autonomous loop for .docx-only codes when run from a Greek network egress.
   Returns (values ok-p status): :ok | (:http CODE) | :not-a-docx | (:fetch-failed M)."
  (%fetch-url-to-file url out-path #'docx-file-p :not-a-docx :timeout timeout))

(defun fetch-pdf (fetch-command pdf-path &key (timeout 600))
  "Acquire a PDF to PDF-PATH by running FETCH-COMMAND (the external headless
   fetcher), with {{out}} replaced by PDF-PATH. Returns (values ok-p status):
     ok-p   T only when a real PDF landed at PDF-PATH.
     status :ok | (:fetch-failed code stderr) | :no-file-produced | :not-a-pdf
            | :no-command
   Validates the %PDF magic, so an anti-bot HTML response is rejected, not ingested."
  (if (or (null fetch-command) (zerop (length (string-trim " " (princ-to-string fetch-command)))))
      (values nil :no-command)
      (let ((cmd (%substitute-out fetch-command pdf-path)))
        (ignore-errors (ensure-directories-exist pdf-path))
        (multiple-value-bind (code err) (run-fetch-command cmd :timeout timeout)
          (cond ((not (eql code 0)) (values nil (list :fetch-failed code err)))
                ((not (probe-file pdf-path)) (values nil :no-file-produced))
                ((not (pdf-file-p pdf-path)) (values nil :not-a-pdf))
                (t (values t :ok)))))))
