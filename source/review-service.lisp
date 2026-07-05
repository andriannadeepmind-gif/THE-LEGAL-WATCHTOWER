;;;; source/review-service.lisp
;;;; ============================================================================
;;;; REVIEW WEB SERVICE  (the lawyer's approval screen)
;;;; ============================================================================
;;;;
;;;; A small, AI-first-system-grade HTTP face over the human-in-the-loop review
;;;; queue (source/review-queue.lisp). The system keeps publishing the changes it
;;;; is sure about; everything uncertain lands here, and the lawyer sees a clean
;;;; page — one row per pending change, with its Greek summary and Έγκριση /
;;;; Απόρριψη buttons. A decision is recorded (who + when, audited) and the queue
;;;; is persisted immediately.
;;;;
;;;; Pure Common Lisp on the project's own HTTP server: actions are GET requests
;;;; with UTF-8 query params (the server already decodes those correctly), so no
;;;; request-body parsing is needed and the page works in any browser.
;;;;
;;;;   GET /                     the dashboard (pending + recently decided)
;;;;   GET /review.json          the same, machine-readable (AI / automation)
;;;;   GET /decide?id=&action=&by=   approve|reject, persist, re-render
;;;;
;;;; The queue is injected as LOAD-FN/SAVE-FN (same discipline as the scheduler
;;;; and the corpus service): the service performs no direct storage coupling and
;;;; always re-loads, so it reflects whatever the daemon has enqueued meanwhile.
;;;; ============================================================================

(defpackage :orchestrator.review-service
  (:use :cl)
  (:export #:review-service #:make-review-service #:review-service-handler
           #:render-dashboard #:review-json))

(in-package :orchestrator.review-service)

(defun %sym (name pkg) (find-symbol name pkg))
(defun %call (name pkg &rest args)
  (apply (find-symbol name pkg) args))

;;; ----------------------------------------------------------------------------
;;; service object
;;; ----------------------------------------------------------------------------

(defclass review-service ()
  ((load-fn :initarg :load-fn :accessor service-load-fn
            :documentation "Thunk returning the current (freshly loaded) review-queue.")
   (save-fn :initarg :save-fn :accessor service-save-fn :initform nil
            :documentation "Optional (queue) -> persist hook, called after a decision.")
   (title   :initarg :title :accessor service-title
            :initform "Σταυρόπουλος — Έλεγχος Κωδικοποίησης"))
  (:documentation "HTTP face over the human-in-the-loop review queue."))

(defun make-review-service (&key load-fn save-fn
                                 (title "Σταυρόπουλος — Έλεγχος Κωδικοποίησης"))
  "LOAD-FN: () -> review-queue (re-loaded each request). SAVE-FN: (queue) ->
   persist, called after every decision."
  (make-instance 'review-service
                 :load-fn (or load-fn (error "make-review-service: :load-fn required"))
                 :save-fn save-fn :title title))

(defun %queue (service) (funcall (service-load-fn service)))

;;; ----------------------------------------------------------------------------
;;; HTML helpers
;;; ----------------------------------------------------------------------------

(defun %esc (string)
  "Escape STRING for safe inclusion in HTML text/attributes."
  (let ((s (princ-to-string (or string ""))))
    (with-output-to-string (out)
      (loop for ch across s do
        (case ch
          (#\& (write-string "&amp;" out))
          (#\< (write-string "&lt;" out))
          (#\> (write-string "&gt;" out))
          (#\" (write-string "&quot;" out))
          (#\' (write-string "&#39;" out))
          (t (write-char ch out)))))))

(defun %url-encode (string)
  "Percent-encode STRING (UTF-8) for a query value."
  (let ((octets (babel:string-to-octets (princ-to-string (or string "")) :encoding :utf-8)))
    (with-output-to-string (out)
      (loop for b across octets
            for ch = (code-char b) do
        (if (or (alphanumericp ch) (member ch '(#\- #\_ #\. #\~)))
            (write-char ch out)
            (format out "%~2,'0X" b))))))

(defparameter +severity-color+
  '((:high . "#b00020") (:medium . "#9a6700") (:low . "#3a6e3a") (:generic . "#555")))

(defun %severity-color (sev)
  (or (cdr (assoc sev +severity-color+)) "#555"))

(defparameter +page-style+
  "*{box-sizing:border-box} body{font-family:'Segoe UI',system-ui,Arial,sans-serif;
margin:0;background:#f5f4f2;color:#1a1a1a;line-height:1.5}
header{background:#14213d;color:#fff;padding:22px 32px}
header h1{margin:0;font-size:20px;font-weight:600;letter-spacing:.2px}
header .sub{opacity:.8;font-size:13px;margin-top:4px}
main{max-width:1040px;margin:0 auto;padding:28px 24px}
.banner{padding:12px 16px;border-radius:8px;margin-bottom:20px;font-size:14px}
.banner.ok{background:#e7f4ea;color:#1e6b35;border:1px solid #b6e0c2}
.banner.warn{background:#fdeaea;color:#9b1c1c;border:1px solid #f3bcbc}
.count{font-size:14px;color:#555;margin-bottom:18px}
.card{background:#fff;border:1px solid #e3e1dd;border-radius:10px;padding:16px 18px;
margin-bottom:14px;box-shadow:0 1px 2px rgba(0,0,0,.03)}
.card .top{display:flex;align-items:center;gap:10px;margin-bottom:8px;flex-wrap:wrap}
.badge{font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;
color:#fff;padding:3px 9px;border-radius:999px}
.kind{font-size:12px;color:#666}
.summary{font-size:15px;margin:6px 0 4px}
.meta{font-size:12px;color:#888;font-family:ui-monospace,Menlo,Consolas,monospace}
.actions{margin-top:12px;display:flex;gap:10px;align-items:center}
.btn{border:0;border-radius:7px;padding:9px 18px;font-size:14px;font-weight:600;
cursor:pointer;text-decoration:none;display:inline-block}
.btn.approve{background:#1e7a3c;color:#fff}
.btn.reject{background:#fff;color:#b00020;border:1px solid #b00020}
.by{font-size:13px}.by input{padding:7px 9px;border:1px solid #ccc;border-radius:6px;font-size:13px}
.empty{background:#fff;border:1px dashed #cfcdc8;border-radius:10px;padding:34px;
text-align:center;color:#6a6a6a}
.decided h2{font-size:15px;color:#444;margin:28px 0 12px;border-top:1px solid #e3e1dd;padding-top:20px}
.decided .card{opacity:.72}
.status-approved{color:#1e7a3c;font-weight:600}.status-rejected{color:#b00020;font-weight:600}
footer{max-width:1040px;margin:10px auto 40px;padding:0 24px;color:#9a9a9a;font-size:12px}")

(defun %render-item-card (item &key pending)
  (let* ((sev (%call "ITEM-SEVERITY" :orchestrator.review item))
         (kind (%call "ITEM-KIND" :orchestrator.review item))
         (id (%call "ITEM-ID" :orchestrator.review item))
         (summary (%call "ITEM-SUMMARY" :orchestrator.review item))
         (status (%call "ITEM-STATUS" :orchestrator.review item))
         (by (%call "ITEM-DECIDED-BY" :orchestrator.review item))
         (at (%call "ITEM-DECIDED-AT" :orchestrator.review item)))
    (with-output-to-string (h)
      (format h "<div class=\"card\">")
      (format h "<div class=\"top\"><span class=\"badge\" style=\"background:~A\">~A</span>"
              (%severity-color sev) (%esc sev))
      (format h "<span class=\"kind\">~A</span></div>" (%esc kind))
      (format h "<div class=\"summary\">~A</div>" (%esc summary))
      (format h "<div class=\"meta\">id: ~A</div>" (%esc id))
      (if pending
          (progn
            ;; The "by" name is captured via a tiny JS hook so the lawyer signs once.
            (format h "<div class=\"actions\">")
            (format h "<a class=\"btn approve\" href=\"#\" data-decide data-id=\"~A\" data-action=\"approve\">Έγκριση</a>" (%esc id))
            (format h "<a class=\"btn reject\" href=\"#\" data-decide data-id=\"~A\" data-action=\"reject\">Απόρριψη</a>" (%esc id))
            (format h "</div>"))
          (format h "<div class=\"meta\">~A <span class=\"status-~(~A~)\">~A</span>~@[ — ~A~]~@[ @ ~A~]</div>"
                  "Απόφαση:" status (%esc status) (%esc by) (%esc at)))
      (format h "</div>"))))

(defun render-dashboard (service &key banner banner-class)
  "The full HTML approval page for the current queue."
  (let* ((q (%queue service))
         (items (%call "QUEUE-ITEMS" :orchestrator.review q))
         (pending (%call "PENDING-ITEMS" :orchestrator.review q))
         (decided (remove-if (lambda (i) (eq (%call "ITEM-STATUS" :orchestrator.review i) :pending))
                             items)))
    (with-output-to-string (h)
      (format h "<!DOCTYPE html><html lang=\"el\"><head><meta charset=\"utf-8\">")
      (format h "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">")
      (format h "<meta name=\"robots\" content=\"noindex\">")
      (format h "<title>~A</title><style>~A</style></head><body>"
              (%esc (service-title service)) +page-style+)
      (format h "<header><h1>~A</h1>" (%esc (service-title service)))
      (format h "<div class=\"sub\">Ανθρώπινος έλεγχος &amp; επικύρωση — μόνο τα αβέβαια φτάνουν εδώ· τα σίγουρα κωδικοποιούνται αυτόματα.</div></header>")
      (format h "<main>")
      (when banner
        (format h "<div class=\"banner ~A\">~A</div>" (or banner-class "ok") (%esc banner)))
      (format h "<div class=\"count\">Προς έλεγχο: <strong>~D</strong>~@[ · Αποφασισμένα: ~D~]</div>"
              (length pending) (when decided (length decided)))
      ;; signer field (used by the buttons via {BY} substitution)
      (format h "<div class=\"by\">Υπογραφή ελεγκτή: <input id=\"by\" placeholder=\"π.χ. Σ. Σταυρόπουλος\" value=\"\"></div><br>")
      (if (null pending)
          (format h "<div class=\"empty\">✓ Κανένα εκκρεμές. Το σύστημα κωδικοποίησε τα πάντα χωρίς αμφιβολία.</div>")
          (dolist (i pending) (write-string (%render-item-card i :pending t) h)))
      (when decided
        (format h "<div class=\"decided\"><h2>Πρόσφατες αποφάσεις</h2>")
        (dolist (i decided) (write-string (%render-item-card i :pending nil) h))
        (format h "</div>"))
      (format h "</main>")
      (format h "<footer>STAVROPOULOSLAWCORPUS · κωδικοποίηση ελληνικού δικαίου · ανθρώπινος έλεγχος στον βρόχο</footer>")
      ;; Sign-once: rewrite each action href's {BY} from the signer field at click.
      (format h "<script>var TOK=~S;document.querySelectorAll('a[data-decide]').forEach(function(a){a.addEventListener('click',function(e){e.preventDefault();var by=encodeURIComponent(document.getElementById('by').value||'lawyer');fetch('/decide?id='+encodeURIComponent(a.dataset.id)+'&action='+a.dataset.action+'&by='+by+'&token='+TOK,{method:'POST'}).then(function(){location.reload();});});});</script>" *decide-token*)
      (format h "</body></html>"))))

;;; ----------------------------------------------------------------------------
;;; JSON (machine-readable; same data, for automation / AI)
;;; ----------------------------------------------------------------------------

(defun %json-string (s)
  (with-output-to-string (out)
    (write-char #\" out)
    (loop for ch across (princ-to-string (or s "")) do
      (case ch
        (#\" (write-string "\\\"" out))
        (#\\ (write-string "\\\\" out))
        (#\Newline (write-string "\\n" out))
        (#\Return (write-string "\\r" out))
        (#\Tab (write-string "\\t" out))
        (#\Backspace (write-string "\\b" out))
        (#\Page (write-string "\\f" out))
        (t (if (< (char-code ch) #x20)
               (format out "\\u~4,'0x" (char-code ch))
               (write-char ch out)))))
    (write-char #\" out)))

(defun review-json (service)
  "The pending queue as a JSON array (machine-readable mirror of the page)."
  (let* ((q (%queue service))
         (pending (%call "PENDING-ITEMS" :orchestrator.review q)))
    (with-output-to-string (out)
      (write-string "{\"pending\":" out)
      (write-char #\[ out)
      (loop for i in pending for firstp = t then nil do
        (unless firstp (write-char #\, out))
        (format out "{\"id\":~A,\"kind\":~A,\"severity\":~A,\"confidence\":~A,~
\"source\":~A,\"target\":~A,\"summary\":~A}"
                (%json-string (%call "ITEM-ID" :orchestrator.review i))
                (%json-string (string-downcase (princ-to-string (%call "ITEM-KIND" :orchestrator.review i))))
                (%json-string (string-downcase (princ-to-string (%call "ITEM-SEVERITY" :orchestrator.review i))))
                (%json-string (string-downcase (princ-to-string (%call "ITEM-CONFIDENCE" :orchestrator.review i))))
                (%json-string (%call "ITEM-SOURCE" :orchestrator.review i))
                (%json-string (%call "ITEM-TARGET" :orchestrator.review i))
                (%json-string (%call "ITEM-SUMMARY" :orchestrator.review i))))
      (write-char #\] out)
      (format out ",\"count\":~D}" (length pending)))))

;;; ----------------------------------------------------------------------------
;;; HTTP handler
;;; ----------------------------------------------------------------------------

(defun %q (req name)
  (cdr (assoc name (%call "HTTP-REQUEST-QUERY" :orchestrator.http req) :test #'string=)))

(defvar *decide-token*
  (orchestrator.journal:sha256-hex
   (format nil "~A|~A" (get-universal-time) (random most-positive-fixnum
                                                    (make-random-state t))))
  "Token ανά διεργασία για ΚΑΘΕ μεταβολή (CSRF): μόνο η σελίδα που σερβίραμε
   μπορεί να εγκρίνει — όχι ένα τυχαίο GET από crawler ή ξένη σελίδα.")

(defvar *decide-lock* (sb-thread:make-mutex :name "review-decide")
  "Ένας κριτής τη φορά στο load→decide→save — τέλος τα lost updates (Φάση 0).")

(defun %resp (status body ct)
  (%call "MAKE-HTTP-RESPONSE" :orchestrator.http
         :status status :body body
         :headers (list (cons "Content-Type" ct)
                        (cons "Cache-Control" "no-store"))))

(defun %handle-decide (service req)
  "Η εφαρμογή μιας απόφασης έγκρισης/απόρριψης — καλείται ΜΟΝΟ υπό το
   *decide-lock*, από POST με έγκυρο token."
         (let* ((id (%q req "id"))
                (action (%q req "action"))
                (by (let ((b (%q req "by"))) (if (and b (plusp (length b))) b "lawyer")))
                (decision (cond ((equal action "approve") :approve)
                                ((equal action "reject") :reject)
                                (t nil))))
           (if (and id decision)
               (let* ((q (%queue service))
                      (item (%call "DECIDE" :orchestrator.review q id decision :by by)))
                 (when (and item (service-save-fn service))
                   (funcall (service-save-fn service) q))
                 (%resp 200
                        (render-dashboard
                         service
                         :banner (if item
                                     (format nil "~A: ~A (από ~A)"
                                             (if (eq decision :approve) "Εγκρίθηκε" "Απορρίφθηκε")
                                             id by)
                                     (format nil "Δεν βρέθηκε εκκρεμές με id=~A" id))
                         :banner-class (if item "ok" "warn"))
                        "text/html; charset=utf-8"))
               (%resp 400
                      (render-dashboard service
                                        :banner "Λείπει id ή έγκυρη ενέργεια (approve|reject)."
                                        :banner-class "warn")
                      "text/html; charset=utf-8"))))

(defun review-service-handler (service)
  "Return an orchestrator.http handler closure for SERVICE."
  (lambda (req)
    (let ((path (%call "HTTP-REQUEST-PATH" :orchestrator.http req))
          (method (%call "HTTP-REQUEST-METHOD" :orchestrator.http req)))
      (cond
        ;; ΜΕΤΑΒΟΛΗ: μόνο POST, μόνο με το token της σελίδας, ένας κριτής τη φορά
        ((string= path "/decide")
         (cond
           ;; Φάση 6: το αντίγραφο ανάγνωσης ΔΕΝ αποφασίζει — οι εγκρίσεις
           ;; ανήκουν στον έναν συγγραφέα-αυθεντία (καμία διχάλα αλήθειας)
           ((orchestrator.journal:replica-p)
            (%resp 403 "Αντίγραφο ανάγνωσης — οι αποφάσεις γίνονται στον συγγραφέα" "text/plain; charset=utf-8"))
           ((not (string= method "POST"))
            (%resp 405 "Οι αποφάσεις γίνονται μόνο με POST" "text/plain; charset=utf-8"))
           ((not (equal (%q req "token") *decide-token*))
            (%resp 403 "Άκυρο token" "text/plain; charset=utf-8"))
           (t (sb-thread:with-mutex (*decide-lock*)
                (%handle-decide service req)))))

        ((not (member method '("GET" "HEAD") :test #'string=))
         (%resp 405 "Method Not Allowed" "text/plain; charset=utf-8"))

        ((string= path "/review.json")
         (%resp 200 (review-json service) "application/json; charset=utf-8"))

((or (string= path "/") (string= path "") (string= path "/review"))
         (%resp 200 (render-dashboard service) "text/html; charset=utf-8"))

        (t (%resp 404 "<h1>404</h1>" "text/html; charset=utf-8"))))))
