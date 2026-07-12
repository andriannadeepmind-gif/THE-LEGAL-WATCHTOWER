;;;; systems/orchestrator-cli/cockpit.lisp
;;;; ============================================================================
;;;; COCKPIT — η ΕΝΟΠΟΙΗΜΕΝΗ επαγγελματική επιφάνεια (μία εντολή: --cockpit)
;;;; ============================================================================
;;;;
;;;; ΔΕΝ τυλίγει κανέναν handler και ΔΕΝ ξαναγράφει καμία λογική: οι δυνατότητες
;;;; ορίζονται ΜΙΑ φορά στην capability-registry (orchestrator.capability) και η
;;;; HTTP επιφάνεια είναι ΠΡΟΒΟΛΗ της μέσω orchestrator.capability-api:api-dispatch.
;;;; Ο ίδιος ορισμός τροφοδοτεί (μελλοντικά) MCP + CLI — τέλος στην τριπλή έδρα.
;;;;
;;;;   Συνομιλία   /api/ask       run-ask (ντετερμινιστική απάντηση με πηγές)
;;;;   Δαίμονας    /api/pending   ό,τι έφερε ο δαίμονας, εκκρεμές για έγκριση
;;;;   Αμφισβήτηση /api/decide    Η ΔΙΚΗ ΣΟΥ έγκριση/απόρριψη (άνθρωπος-αυθεντία)
;;;;   Δημοσίευση  /api/publish   emit-site
;;;;   /api/catalog αυτο-περιγραφή (για UI/MCP)
;;;;
;;;; Το AI (advisor) συνδέεται ΕΚΤΟΣ trusted path μέσω του υπάρχοντος --serve-mcp.
;;;; Υβριδικό: COCKPIT_HOST=127.0.0.1 (τοπικά, default) ή 0.0.0.0 (όπου θες).
;;;; Auth: με LAWMAX_CREATOR_TOKEN, κάθε /api θέλει ?key=…· χωρίς token (προσωπική
;;;; τοπική εγκατάσταση) η θύρα ΕΙΝΑΙ ο δημιουργός — ίδιο μοντέλο με το /ask.
;;;; ============================================================================

(in-package :orchestrator.cli)

;;; ── Δυνατότητες: ΜΙΑ δηλωτική έδρα (domain fns αυτούσιες, καμία διπλή λογική) ──

(orchestrator.capability:define-capability :ask
  :summary "Ντετερμινιστική νομική απάντηση με πηγές"
  :params ((:q :string t) (:session :string nil))
  :result :string :trust :trusted :proof t
  :fn (lambda (&key q session)
        (let ((*ask-memory* (if (and session (plusp (length session)))
                                (%session-memory session)
                                *ask-memory*)))
          (with-output-to-string (*standard-output*)
            (handler-case (run-ask (list q))
              (error (e) (format t "σφάλμα: ~A~%" e)))))))

(orchestrator.capability:define-capability :pending
  :summary "Τι έφερε ο δαίμονας: εκκρεμείς προτάσεις που περιμένουν την έγκρισή σου"
  :params ()
  :result :list :trust :trusted
  :fn (lambda ()
        (let ((q (load-review-queue)))
          (mapcar (lambda (it)
                    (list :id      (princ-to-string (orchestrator.review:item-id it))
                          :summary (orchestrator.review:item-summary it)
                          :kind     (string-downcase (princ-to-string (orchestrator.review:item-kind it)))
                          :severity (string-downcase (princ-to-string (orchestrator.review:item-severity it)))))
                  (orchestrator.review:pending-items q)))))

(orchestrator.capability:define-capability :decide
  :summary "Η ΔΙΚΗ ΣΟΥ απόφαση σε εκκρεμή πρόταση (approve|reject) — άνθρωπος-αυθεντία"
  :params ((:id :string t) (:action :string t) (:by :string nil))
  :result :string :trust :trusted
  :fn (lambda (&key id action by)
        (let ((decision (cond ((string-equal action "approve") :approved)
                              ((string-equal action "reject")  :rejected)
                              (t (error "action: approve ή reject")))))
          (let* ((q (load-review-queue))
                 (item (orchestrator.review:decide q id decision :by (or by "creator"))))
            (if item
                (progn (save-review-queue q)
                       (format nil "~A → ~A" id (string-downcase (symbol-name decision))))
                (format nil "δεν βρέθηκε εκκρεμές: ~A" id))))))

(orchestrator.capability:define-capability :publish
  :summary "Δημοσίευση: παραγωγή στατικού site (human HTML + AI data + υπογεγραμμένες ρίζες)"
  :params ()
  :result :string :trust :trusted :proof t
  :fn (lambda ()
        (with-output-to-string (*standard-output*)
          (handler-case (emit-site)
            (error (e) (format t "σφάλμα δημοσίευσης: ~A~%" e))))))

;;; ── Ελάχιστος ντετερμινιστικός JSON emitter για το payload (%json-escape=έδρα) ──

(defun %cockpit-json (x)
  (cond
    ((null x) "null")
    ((eq x t) "true")
    ((stringp x) (format nil "\"~A\"" (%json-escape x)))
    ((integerp x) (princ-to-string x))
    ((and (rationalp x) (not (integerp x))) (format nil "~,6F" (coerce x 'double-float)))
    ((realp x) (format nil "~,6F" x))
    ((keywordp x) (format nil "\"~A\"" (%json-escape (string-downcase (symbol-name x)))))
    ((and (consp x) (keywordp (car x)))                 ; plist → object
     (with-output-to-string (o)
       (write-char #\{ o)
       (loop for (k v) on x by #'cddr for first = t then nil
             do (unless first (write-char #\, o))
                (format o "\"~A\":~A"
                        (%json-escape (string-downcase (symbol-name k)))
                        (%cockpit-json v)))
       (write-char #\} o)))
    ((listp x) (format nil "[~{~A~^,~}]" (mapcar #'%cockpit-json x)))   ; list → array
    (t (format nil "\"~A\"" (%json-escape (princ-to-string x))))))

;;; ── Η επαγγελματική σελίδα (self-contained· καλεί το /api/*) ──

(defparameter +cockpit-page+
  "<!doctype html><html lang=el><head><meta charset=utf-8>
<meta name=viewport content='width=device-width,initial-scale=1'>
<title>LAWMAX — Cockpit</title><style>
:root{--bg:#0b0f14;--panel:#131a22;--edge:#22303d;--ink:#e7eef5;--dim:#8aa0b2;--accent:#3aa0ff;--ok:#2ecc71;--warn:#f1c40f}
*{box-sizing:border-box}body{margin:0;font:15px/1.5 -apple-system,Segoe UI,Roboto,sans-serif;background:var(--bg);color:var(--ink)}
header{padding:14px 20px;border-bottom:1px solid var(--edge);display:flex;align-items:center;gap:12px}
header b{font-size:17px;letter-spacing:.5px}header span{color:var(--dim);font-size:13px}
.tabs{display:flex;gap:6px;padding:10px 16px;border-bottom:1px solid var(--edge);flex-wrap:wrap}
.tab{padding:8px 14px;border:1px solid var(--edge);border-radius:8px;background:var(--panel);color:var(--dim);cursor:pointer}
.tab.on{color:var(--ink);border-color:var(--accent);box-shadow:0 0 0 1px var(--accent) inset}
main{padding:18px;max-width:980px;margin:0 auto}.view{display:none}.view.on{display:block}
textarea,input{width:100%;background:var(--panel);border:1px solid var(--edge);color:var(--ink);border-radius:8px;padding:10px;font:inherit}
textarea{min-height:80px;resize:vertical}button{background:var(--accent);color:#04121f;border:0;border-radius:8px;padding:10px 16px;font-weight:600;cursor:pointer}
button.ghost{background:var(--panel);color:var(--ink);border:1px solid var(--edge)}
.out{white-space:pre-wrap;background:var(--panel);border:1px solid var(--edge);border-radius:8px;padding:14px;margin-top:12px;min-height:40px}
.row{display:flex;gap:8px;align-items:center;margin:8px 0}.card{background:var(--panel);border:1px solid var(--edge);border-radius:10px;padding:12px;margin:10px 0}
.card h4{margin:0 0 4px}.sev{font-size:12px;color:var(--warn)}.muted{color:var(--dim);font-size:13px}
</style></head><body>
<header><b>LAWMAX</b><span>Cockpit — provably-correct source of truth · άνθρωπος αποφασίζει</span></header>
<div class=tabs>
  <div class='tab on' data-v=ask>Συνομιλία</div>
  <div class=tab data-v=daemon>Δαίμονας</div>
  <div class=tab data-v=review>Αμφισβήτηση</div>
  <div class=tab data-v=publish>Δημοσίευση</div>
</div>
<main>
  <section class='view on' id=ask>
    <textarea id=q placeholder='π.χ. τι λέει το άρθρο 299 του Ποινικού Κώδικα;'></textarea>
    <div class=row><button onclick=ask()>Ρώτα</button><span class=muted>ντετερμινιστική απάντηση με πηγές — καμία παραίσθηση</span></div>
    <div class=out id=ans></div>
  </section>
  <section class=view id=daemon>
    <div class=row><button class=ghost onclick=loadPending()>Ανανέωση</button><span class=muted id=dcount></span></div>
    <div id=dlist></div>
  </section>
  <section class=view id=review>
    <div class=row><input id=by placeholder='όνομα εγκρίνοντος (προαιρετικό)'></div>
    <div class=row><button class=ghost onclick=loadPending()>Φόρτωσε εκκρεμή</button><span class=muted>εσύ αποφασίζεις — ένα κλικ</span></div>
    <div id=rlist></div>
  </section>
  <section class=view id=publish>
    <div class=row><button onclick=publish()>Δημοσίευση site</button><span class=muted>human HTML + AI data + υπογεγραμμένες ρίζες</span></div>
    <div class=out id=pout></div>
  </section>
</main>
<script>
var KEY=new URLSearchParams(location.search).get('key');function k(){return KEY?('&key='+encodeURIComponent(KEY)):''}
function j(p){return fetch(p+(p.indexOf('?')<0?'?':'&')+'_=1'+k()).then(r=>r.json())}
document.querySelectorAll('.tab').forEach(t=>t.onclick=function(){
  document.querySelectorAll('.tab').forEach(x=>x.classList.remove('on'));t.classList.add('on');
  document.querySelectorAll('.view').forEach(v=>v.classList.remove('on'));
  document.getElementById(t.dataset.v).classList.add('on');
  if(t.dataset.v=='daemon'||t.dataset.v=='review')loadPending();});
function ask(){var q=document.getElementById('q').value;document.getElementById('ans').textContent='…';
  j('/api/ask?q='+encodeURIComponent(q)).then(d=>document.getElementById('ans').textContent=(d.result||d.error||''));}
function publish(){document.getElementById('pout').textContent='…';
  j('/api/publish').then(d=>document.getElementById('pout').textContent=(d.result||d.error||''));}
function loadPending(){j('/api/pending').then(d=>{var xs=d.result||[];
  document.getElementById('dcount').textContent=xs.length+' εκκρεμή';
  var html=xs.length?'':'<div class=muted>κανένα εκκρεμές — ο δαίμονας δεν έφερε κάτι που να χρειάζεται απόφαση</div>';
  xs.forEach(function(it){html+='<div class=card><h4>'+esc(it.summary||it.id)+'</h4>'+
    '<div class=sev>'+esc(it.kind||'')+' · '+esc(it.severity||'')+'</div>'+
    '<div class=row><button onclick=\"decide(\\''+esc(it.id)+'\\',\\'approve\\')\">Έγκριση</button>'+
    '<button class=ghost onclick=\"decide(\\''+esc(it.id)+'\\',\\'reject\\')\">Απόρριψη</button></div></div>';});
  document.getElementById('dlist').innerHTML=html;document.getElementById('rlist').innerHTML=html;});}
function decide(id,a){var by=encodeURIComponent(document.getElementById('by').value||'');
  j('/api/decide?id='+encodeURIComponent(id)+'&action='+a+'&by='+by).then(d=>{alert(d.result||d.error||'');loadPending();});}
function esc(s){return String(s).replace(/[&<>\"']/g,function(c){return{'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;',\"'\":'&#39;'}[c]})}
</script></body></html>"
  "Η self-contained επαγγελματική σελίδα του cockpit· καλεί ΜΟΝΟ το /api/*.")

;;; ── HTTP προβολή: /api/* → api-dispatch· / → σελίδα· auth ίδιο μοντέλο με /ask ──

(defun %cockpit-authorised-p (req)
  "Χωρίς LAWMAX_CREATOR_TOKEN (προσωπική τοπική εγκατάσταση): η θύρα ΕΙΝΑΙ ο
   δημιουργός. Με token: απαιτείται ?key=… που ταιριάζει."
  (let ((tok (%non-blank (uiop:getenv "LAWMAX_CREATOR_TOKEN"))))
    (or (null tok)
        (equal tok (cdr (assoc "key" (orchestrator.http:http-request-query req)
                               :test #'string=))))))

(defun %json-response (status payload)
  (orchestrator.http:respond (if (integerp status) status 200)
                             (%cockpit-json payload)
                             "Content-Type" "application/json; charset=utf-8"))

(defun %cockpit-handler (req)
  (let* ((path (orchestrator.http:http-request-path req))
         (pfx orchestrator.capability-api:*api-prefix*))
    (cond
      ((or (string= path "/") (string= path "/index.html"))
       (orchestrator.http:respond 200 +cockpit-page+
                                  "Content-Type" "text/html; charset=utf-8"))
      ((and (>= (length path) (length pfx)) (string= pfx path :end2 (length pfx)))
       (if (not (%cockpit-authorised-p req))
           (%json-response 403 (list :error "μόνο ο δημιουργός (λείπει/λάθος key)"))
           (if (string= path "/api/catalog")
               (multiple-value-bind (st pl) (orchestrator.capability-api:api-catalog)
                 (%json-response st pl))
               (multiple-value-bind (st pl)
                   (orchestrator.capability-api:api-dispatch
                    path (orchestrator.http:http-request-query req))
                 (if (eq st :not-api)
                     (%json-response 404 (list :error "άγνωστη διαδρομή"))
                     (%json-response st pl))))))
      (t (orchestrator.http:respond 404 "not found"
                                    "Content-Type" "text/plain; charset=utf-8")))))

;;; ── run-cockpit + εγγραφή εντολής (μία είσοδος) ──

(defun run-cockpit ()
  "Υβριδικό cockpit: ένας server, όλες οι δυνατότητες ως προβολές της registry.
   COCKPIT_HOST (default 127.0.0.1 = τοπικά· 0.0.0.0 = όπου θες), COCKPIT_PORT."
  (let ((port (let ((p (uiop:getenv "COCKPIT_PORT")))
                (or (and p (parse-integer p :junk-allowed t)) 8090)))
        (host (or (%non-blank (uiop:getenv "COCKPIT_HOST")) "127.0.0.1")))
    (format t "~%Building corpora for cockpit...~%")
    (handler-case (progn (build-all-corpora) (%graph-ensure))
      (error (e) (format t "  ⚠ corpora/graph: ~A~%" e)))
    (format t "~%LAWMAX cockpit → http://~A:~D~%" host port)
    (format t "  Συνομιλία · Δαίμονας · Αμφισβήτηση · Δημοσίευση (άνθρωπος αποφασίζει)~%")
    (format t "  AI-plug (εκτός trusted path): --serve-mcp~%")
    (orchestrator.http:start-server #'%cockpit-handler :port port :host host)
    (loop (sleep 3600))))

(register-command "--cockpit" (lambda (a) (declare (ignore a)) (run-cockpit)))
