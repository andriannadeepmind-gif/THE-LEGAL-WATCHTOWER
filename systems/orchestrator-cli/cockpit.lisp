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
;;;; Η επιφάνεια είναι ΔΟΜΙΚΑ trusted-only: κάθε /api κλήση περνά require-trust —
;;;; μια advisor δυνατότητα ΔΕΝ εκτελείται εδώ (403), δεν φτάνει καν στο :fn.
;;;;
;;;; Υβριδικό: COCKPIT_HOST=127.0.0.1 (τοπικά, default) ή 0.0.0.0 (όπου θες).
;;;; Auth: η ΜΙΑ έδρα %creator-request-authorised-p (ίδιο μοντέλο με /ask, /cmd).
;;;; CSRF: κάθε /api απαιτεί Host-allowlist (θάνατος DNS-rebinding) + custom header
;;;; X-LAWMAX-Cockpit (θάνατος simple-CORS CSRF από <img>/<form>/<script>).
;;;; ============================================================================

(in-package :orchestrator.cli)

;;; ── Δυνατότητες: ΜΙΑ δηλωτική έδρα (domain fns αυτούσιες, καμία διπλή λογική) ──

(orchestrator.capability:define-capability :ask
  :summary "Ντετερμινιστική νομική απάντηση με πηγές"
  :params ((:q :string t) (:session :string nil))
  :result :string :trust :trusted :proof t
  :fn (lambda (&key q session)
        ;; μνήμη ΑΝΑ συνεδρία· ακροατήριο :creator (η θύρα έχει ήδη πιστοποιηθεί
        ;; στον handler). Καμία κατάπνιξη σφάλματος: αποτυχία run-ask ⇒ διαφεύγει
        ;; ⇒ api-dispatch το γυρίζει 500 (fail-closed, ίδιο με κάθε δυνατότητα).
        (let ((*ask-memory* (if (and session (plusp (length session)))
                                (%session-memory session)
                                *ask-memory*)))
          (orchestrator.self-model:with-audience (:creator)
            (with-output-to-string (*standard-output*)
              (run-ask (list q)))))))

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
        ;; Το ΡΗΜΑ της πράξης (:approve|:reject) — ΑΚΡΙΒΩΣ ό,τι δέχεται η έδρα
        ;; orchestrator.review:decide (apply-decision: (ecase (:approve :approved)
        ;; (:reject :rejected))). read-modify-write υπό ΜΙΑ κλειδαριά (κανένα
        ;; lost-update μεταξύ ταυτόχρονων ανθρώπινων αποφάσεων).
        (let ((decision (cond ((string-equal action "approve") :approve)
                              ((string-equal action "reject")  :reject)
                              (t (error "action: approve ή reject")))))
          (with-review-queue-lock
            (let* ((q (load-review-queue))
                   (item (orchestrator.review:decide q id decision :by (or by "creator"))))
              (if item
                  (progn (save-review-queue q)
                         (format nil "~A → ~A" id
                                 (string-downcase (symbol-name (orchestrator.review:item-status item)))))
                  (format nil "δεν βρέθηκε εκκρεμές: ~A" id)))))))

(orchestrator.capability:define-capability :publish
  :summary "Δημοσίευση: παραγωγή στατικού site (human HTML + AI data + υπογεγραμμένες ρίζες)"
  :params ()
  :result :string :trust :trusted :proof t
  :fn (lambda ()
        ;; Καμία κατάπνιξη: αποτυχία emit-site ⇒ διαφεύγει ⇒ 500 (μια αποτυχημένη
        ;; δημοσίευση ΔΕΝ πρέπει ΠΟΤΕ να μοιάζει επιτυχία στον καταναλωτή).
        (with-output-to-string (*standard-output*)
          (emit-site))))

;;; ── Ελάχιστη σύνθεση JSON: scalars ΑΠΟΚΛΕΙΣΤΙΚΑ μέσω της ΜΙΑΣ έδρας %json-scalar ──

(defun %cockpit-json (x)
  "Σύνθεση JSON για το payload: t→true· plist→object· list→array· ΚΑΘΕ scalar
   (null/αριθμός/string/keyword) περνά από τη ΜΙΑ cli έδρα %json-scalar — καμία
   επανάληψη της scalar διάκρισης (νόμος «0 διπλά», [0070])."
  (cond
    ((eq x t) "true")
    ((keywordp x) (%json-scalar (string-downcase (symbol-name x))))
    ((and (consp x) (keywordp (car x)))                 ; plist → object
     (with-output-to-string (o)
       (write-char #\{ o)
       (loop for (k v) on x by #'cddr for first = t then nil
             do (unless first (write-char #\, o))
                (format o "~A:~A"
                        (%json-scalar (string-downcase (symbol-name k)))
                        (%cockpit-json v)))
       (write-char #\} o)))
    ((consp x) (format nil "[~{~A~^,~}]" (mapcar #'%cockpit-json x)))   ; list → array
    (t (%json-scalar x))))                              ; nil→null, αριθμός, string

;;; ── Η επαγγελματική σελίδα (self-contained· καλεί ΜΟΝΟ το /api/*) ──
;;; XSS-ασφαλής εκ κατασκευής: μηδέν innerHTML-string-interpolation δεδομένων.
;;; Κάθε τιμή μπαίνει με textContent/dataset· τα κουμπιά φέρουν data-id/data-action
;;; και ένα ΕΝΑ delegated listener — καμία inline onclick με παρεμβολή id.

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
    <div class=row><button id=askbtn>Ρώτα</button><span class=muted>ντετερμινιστική απάντηση με πηγές — καμία παραίσθηση</span></div>
    <div class=out id=ans></div>
  </section>
  <section class=view id=daemon>
    <div class=row><button class=ghost id=refbtn>Ανανέωση</button><span class=muted id=dcount></span></div>
    <div id=dlist></div>
  </section>
  <section class=view id=review>
    <div class=row><input id=by placeholder='όνομα εγκρίνοντος (προαιρετικό)'></div>
    <div class=row><button class=ghost id=refbtn2>Φόρτωσε εκκρεμή</button><span class=muted>εσύ αποφασίζεις — ένα κλικ</span></div>
    <div id=rlist></div>
  </section>
  <section class=view id=publish>
    <div class=row><button id=pubbtn>Δημοσίευση site</button><span class=muted>human HTML + AI data + υπογεγραμμένες ρίζες</span></div>
    <div class=out id=pout></div>
  </section>
</main>
<script>
var KEY=new URLSearchParams(location.search).get('key');
function k(){return KEY?('&key='+encodeURIComponent(KEY)):''}
// custom header ⇒ ένα <img>/<form> ΔΕΝ μπορεί να το θέσει· cross-origin fetch ⇒ preflight
function j(p){return fetch(p+(p.indexOf('?')<0?'?':'&')+'_=1'+k(),
  {headers:{'X-LAWMAX-Cockpit':'1'}}).then(function(r){return r.json()})}
function show(id){var el=document.getElementById(id);el.textContent='';return el}
function ask(){document.getElementById('ans').textContent='…';
  j('/api/ask?q='+encodeURIComponent(document.getElementById('q').value))
    .then(function(d){document.getElementById('ans').textContent=(d.result||d.error||'')})}
function publish(){document.getElementById('pout').textContent='…';
  j('/api/publish').then(function(d){document.getElementById('pout').textContent=(d.result||d.error||'')})}
function decide(id,a){var by=document.getElementById('by').value||'';
  j('/api/decide?id='+encodeURIComponent(id)+'&action='+encodeURIComponent(a)+'&by='+encodeURIComponent(by))
    .then(function(d){alert(d.result||d.error||'');loadPending()})}
function card(it){ // DOM δόμηση — καμία string-παρεμβολή ⇒ αδύνατο XSS εκ κατασκευής
  var c=document.createElement('div');c.className='card';
  var h=document.createElement('h4');h.textContent=it.summary||it.id;c.appendChild(h);
  var s=document.createElement('div');s.className='sev';s.textContent=(it.kind||'')+' · '+(it.severity||'');c.appendChild(s);
  var r=document.createElement('div');r.className='row';
  var ap=document.createElement('button');ap.textContent='Έγκριση';ap.dataset.id=it.id;ap.dataset.action='approve';
  var rj=document.createElement('button');rj.className='ghost';rj.textContent='Απόρριψη';rj.dataset.id=it.id;rj.dataset.action='reject';
  r.appendChild(ap);r.appendChild(rj);c.appendChild(r);return c}
function loadPending(){j('/api/pending').then(function(d){var xs=d.result||[];
  document.getElementById('dcount').textContent=xs.length+' εκκρεμή';
  ['dlist','rlist'].forEach(function(id){var el=show(id);
    if(!xs.length){var m=document.createElement('div');m.className='muted';
      m.textContent='κανένα εκκρεμές — ο δαίμονας δεν έφερε κάτι που να χρειάζεται απόφαση';el.appendChild(m);return}
    xs.forEach(function(it){el.appendChild(card(it))})})})}
document.querySelectorAll('.tab').forEach(function(t){t.onclick=function(){
  document.querySelectorAll('.tab').forEach(function(x){x.classList.remove('on')});t.classList.add('on');
  document.querySelectorAll('.view').forEach(function(v){v.classList.remove('on')});
  document.getElementById(t.dataset.v).classList.add('on');
  if(t.dataset.v=='daemon'||t.dataset.v=='review')loadPending()}});
document.getElementById('askbtn').onclick=ask;
document.getElementById('pubbtn').onclick=publish;
document.getElementById('refbtn').onclick=loadPending;
document.getElementById('refbtn2').onclick=loadPending;
document.addEventListener('click',function(e){var b=e.target.closest?e.target.closest('button[data-action]'):null;
  if(b){decide(b.dataset.id,b.dataset.action)}});
</script></body></html>"
  "Η self-contained επαγγελματική σελίδα του cockpit· καλεί ΜΟΝΟ το /api/*.")

;;; ── Φρουροί της επιφάνειας (fail-closed· η ΜΙΑ έδρα ταυτότητας για το key) ──

(defparameter +loopback-hosts+ '("127.0.0.1" "localhost" "::1"))

(defun %cockpit-host-only (req)
  "Το host χωρίς port (πεζά), με σωστό χειρισμό IPv6 literal «[::1]:port»."
  (let ((hdr (or (orchestrator.http:http-request-header req "host") "")))
    (string-downcase
     (cond
       ((zerop (length hdr)) "")
       ((char= (char hdr 0) #\[)                       ; [::1] ή [::1]:port
        (let ((rb (position #\] hdr))) (if rb (subseq hdr 1 rb) hdr)))
       (t (subseq hdr 0 (or (position #\: hdr) (length hdr))))))))

(defun %cockpit-allowed-hosts ()
  "COCKPIT_ALLOWED_HOSTS → λίστα (πεζά, ΚΕΝΕΣ καταχωρήσεις αγνοούνται — καμία
   σιωπηλή fail-open σε trailing/double comma)."
  (let ((raw (%non-blank (uiop:getenv "COCKPIT_ALLOWED_HOSTS"))))
    (when raw
      (remove "" (mapcar (lambda (s) (string-downcase (string-trim '(#\Space #\Tab) s)))
                         (uiop:split-string raw :separator '(#\,)))
              :test #'string=))))

(defun %cockpit-host-ok-p (req)
  "Host-guard — θάνατος DNS-rebinding + FAIL-CLOSED δημόσιο bind:
   · COCKPIT_ALLOWED_HOSTS ⇒ μόνο αυτά (κενές καταχωρήσεις αγνοούνται)·
   · loopback bind (default) ⇒ μόνο localhost/127.0.0.1/::1·
   · μη-loopback bind (0.0.0.0/δημόσιο) ΧΩΡΙΣ allowlist ⇒ επιτρέπεται ΜΟΝΟ αν
     υπάρχει LAWMAX_CREATOR_TOKEN (η αυθεντικοποίηση)· αλλιώς ΑΡΝΗΣΗ — καμία
     δημόσια θύρα χωρίς token ή allowlist (το custom header ΔΕΝ είναι auth:
     ένας μη-browser client το θέτει ελεύθερα)."
  (let ((host (%cockpit-host-only req))
        (allowed (%cockpit-allowed-hosts))
        (bind (or (%non-blank (uiop:getenv "COCKPIT_HOST")) "127.0.0.1")))
    (cond
      (allowed (and (member host allowed :test #'string=) t))
      ((member bind +loopback-hosts+ :test #'string=)
       (and (member host +loopback-hosts+ :test #'string=) t))
      ((%non-blank (uiop:getenv "LAWMAX_CREATOR_TOKEN")) t)
      (t nil))))

(defun %cockpit-csrf-ok-p (req)
  "Απαιτεί το custom header X-LAWMAX-Cockpit: ένα <img>/<form>/<script> ΔΕΝ μπορεί
   να το θέσει, και ένα cross-origin fetch που το θέτει πυροδοτεί preflight που δεν
   εγκρίνουμε ⇒ ο browser το φράζει. Θάνατος της κλάσης simple-CORS CSRF."
  (and (orchestrator.http:http-request-header req "x-lawmax-cockpit") t))

(defun %cockpit-authorised-p (req)
  "Ταυτότητα δημιουργού για το key — μέσω της ΜΙΑΣ έδρας (cli-util), καμία
   δεύτερη υλοποίηση του ελέγχου."
  (%creator-request-authorised-p
   (cdr (assoc "key" (orchestrator.http:http-request-query req) :test #'string=))))

(defun %cockpit-api-guard (req)
  "Fail-closed πύλη κάθε /api αιτήματος. Επιστρέφει (values nil nil) αν περνά,
   αλλιώς (values STATUS MSG). Σειρά: Host (rebinding) → header (CSRF) → key."
  (cond
    ((not (%cockpit-host-ok-p req))
     (values 403 "μη επιτρεπτό Host (πιθανό DNS-rebinding)"))
    ((not (%cockpit-csrf-ok-p req))
     (values 403 "λείπει X-LAWMAX-Cockpit (προστασία CSRF)"))
    ((not (%cockpit-authorised-p req))
     (values 403 "μόνο ο δημιουργός (λείπει/λάθος key)"))
    (t (values nil nil))))

;;; ── HTTP προβολή: /api/* → api-dispatch (require-trust)· / → σελίδα ──

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
       (multiple-value-bind (gstatus gmsg) (%cockpit-api-guard req)
         (if gstatus
             (%json-response gstatus (list :error gmsg))
             (if (string= path "/api/catalog")
                 (multiple-value-bind (st pl)
                     (orchestrator.capability-api:api-catalog :require-trust t)
                   (%json-response st pl))
                 (multiple-value-bind (st pl)
                     (orchestrator.capability-api:api-dispatch
                      path (orchestrator.http:http-request-query req) :require-trust t)
                   (if (eq st :not-api)
                       (%json-response 404 (list :error "άγνωστη διαδρομή"))
                       (%json-response st pl)))))))
      (t (orchestrator.http:respond 404 "not found"
                                    "Content-Type" "text/plain; charset=utf-8")))))

;;; ── run-cockpit + εγγραφή εντολής (μία είσοδος) ──

(defun %cockpit-ensure-corpus-artifacts (corpora)
  "Υβριδικό «όπου θες»: το /ask διαβάζει το ΕΚΔΟΜΕΝΟ output/<c>/corpus.jsonl (η
   golden-επαληθευμένη πηγή). Αν λείπει (π.χ. docker runtime image που δεν
   κουβαλά το output/), το ΓΡΑΦΟΥΜΕ από την ΙΔΙΑ έδρα που παράγει τα golden
   αρχεία (orchestrator.ai-dump:emit-corpus-jsonl), από τα ήδη-χτισμένα corpora.
   ΠΟΤΕ overwrite υπάρχοντος golden — μόνο συμπλήρωση όταν λείπει (καμία
   σιωπηλή «κανένα άρθρο» επειδή το artifact δεν ταξίδεψε με την εικόνα)."
  (dolist (pair corpora)
    (let* ((short (car pair))
           (path (merge-pathnames (format nil "output/~A/corpus.jsonl" (%corpus-outdir short))
                                  (orchestrator.paths:institution-root))))
      (unless (probe-file path)
        (handler-case
            (let ((doc (funcall (cdr pair))))
              (ensure-directories-exist path)
              (with-open-file (s path :direction :output :external-format :utf-8
                                      :if-exists :supersede :if-does-not-exist :create)
                (write-string (orchestrator.ai-dump:emit-corpus-jsonl doc) s))
              (format t "  ✎ corpus.jsonl → ~A~%" (namestring path)))
          (error (e) (format t "  ⚠ corpus.jsonl ~A: ~A~%" short e)))))))

(defun run-cockpit ()
  "Υβριδικό cockpit: ένας server, όλες οι δυνατότητες ως προβολές της registry.
   COCKPIT_HOST (default 127.0.0.1 = τοπικά· 0.0.0.0 = όπου θες), COCKPIT_PORT."
  (let ((port (let ((p (uiop:getenv "COCKPIT_PORT")))
                (or (and p (parse-integer p :junk-allowed t)) 8090)))
        (host (or (%non-blank (uiop:getenv "COCKPIT_HOST")) "127.0.0.1")))
    (format t "~%Building corpora for cockpit...~%")
    (handler-case
        (let ((corpora (build-all-corpora)))
          (%cockpit-ensure-corpus-artifacts corpora)   ; /ask δουλεύει όπου θες
          (%graph-ensure))
      (error (e) (format t "  ⚠ corpora/graph: ~A~%" e)))
    (format t "~%LAWMAX cockpit → http://~A:~D~%" host port)
    (format t "  Συνομιλία · Δαίμονας · Αμφισβήτηση · Δημοσίευση (άνθρωπος αποφασίζει)~%")
    (format t "  AI-plug (εκτός trusted path): --serve-mcp~%")
    (orchestrator.http:start-server #'%cockpit-handler :port port :host host)
    (loop (sleep 3600))))

(register-command "--cockpit" (lambda (a) (declare (ignore a)) (run-cockpit)))
