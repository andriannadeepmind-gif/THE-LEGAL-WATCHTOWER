;;;; systems/orchestrator-cli/advisor.lisp
;;;; ============================================================================
;;;; Ο ΣΥΜΒΟΥΛΟΣ (εκτός εμπιστοσύνης): LLM ως ΠΡΟΤΕΙΝΩΝ, ποτέ ως κριτής
;;;; ============================================================================
;;;;
;;;; Η υποδοχή *advisor* ΥΠΗΡΧΕ στο γνωσιακό μονοπάτι (στάδιο 1: όταν κανείς
;;;; συμβολικός ταξινομητής δεν πιάνει, ζητείται πρόταση) — εδώ συνδέεται:
;;;;   1. HTTP πελάτης (drakma) σε OpenAI-συμβατό endpoint (τοπικό DeepSeek/
;;;;      Ollama/vLLM) μέσω LAWMAX_ADVISOR_URL — καμία μεταβλητή ⇒ καθαρά
;;;;      συμβολική λειτουργία, μηδενική εξάρτηση.
;;;;   2. Η απάντηση διαβάζεται ΧΩΡΙΣ eval (*read-eval* nil, πακέτο :keyword)
;;;;      και περνά από ΛΕΥΚΟ ΚΑΤΑΛΟΓΟ πλαισίων + ΣΥΜΒΟΛΙΚΗ ΕΠΑΛΗΘΕΥΣΗ:
;;;;      corpus πρέπει να είναι εγγεγραμμένος κώδικας, έννοια πρέπει να
;;;;      γειώνεται σε διάταξη. Ό,τι δεν επαληθεύεται ⇒ nil (τίμια άγνοια).
;;;;   3. Ο σύμβουλος δεν γράφει ΠΟΤΕ απάντηση, γνώση ή κώδικα — μόνο
;;;;      προτείνει ΠΟΙΟ πλαίσιο ταιριάζει· η εκτέλεση μένει στο έμπιστο
;;;;      συμβολικό μονοπάτι (τα ίδια στάδια 2-5 με τους ταξινομητές).

(in-package :orchestrator.cli)

;;; ── Λευκός κατάλογος: ποια πλαίσια δικαιούται να προτείνει ──

(defun %advice-verify-article-lookup (spec input)
  (let* ((corpus (getf spec :corpus))
         (article (getf spec :article))
         (corpus (and (stringp corpus) (string-downcase corpus)))
         (tag (car (rassoc corpus orchestrator.decisions:+law-tag-corpus-map+
                           :test #'string=))))
    ;; ΕΠΑΛΗΘΕΥΣΗ: ο κώδικας πρέπει να είναι εγγεγραμμένος, το άρθρο αριθμός.
    (when (and tag (stringp article) (plusp (length article))
               (every #'digit-char-p article))
      (make-instance 'article-lookup-frame :input input
        :slots (list :corpus corpus :article article :tag tag)))))

(defun %advice-verify-corpus-info (spec input)
  (let* ((corpus (getf spec :corpus))
         (corpus (and (stringp corpus) (string-downcase corpus)))
         (tag (car (rassoc corpus orchestrator.decisions:+law-tag-corpus-map+
                           :test #'string=))))
    (when tag
      (make-instance 'corpus-info-frame :input input
        :slots (list :tag tag :corpus corpus)))))

(defun %advice-verify-definition (spec input)
  (let ((concept (getf spec :concept)))
    ;; ΕΠΑΛΗΘΕΥΣΗ: η έννοια πρέπει να γειώνεται σε διάταξη από τη ΔΙΚΗ μας
    ;; γνώση (%resolve-concept) — ο σύμβουλος δεν εφευρίσκει ορισμούς.
    (when (stringp concept)
      (let ((r (%resolve-concept concept)))
        (when r
          (destructuring-bind (c alts relation corpus article) r
            (declare (ignore alts))
            (make-instance 'definition-frame :input input
              :slots (list :concept c :relation relation
                           :corpus corpus :article article))))))))

(defparameter *advisable-frames*
  (list (cons :article-lookup #'%advice-verify-article-lookup)
        (cons :corpus-info    #'%advice-verify-corpus-info)
        (cons :definition     #'%advice-verify-definition))
  "Λευκός κατάλογος: κλειδί-πλαισίου → επαληθευτής (spec input)→frame|nil.
   Ό,τι δεν είναι εδώ, ΔΕΝ κατασκευάζεται από πρόταση συμβούλου.")

(defmethod orchestrator.cognition:build-frame-from-advice ((spec cons) input)
  "Η πρόταση του συμβούλου γίνεται frame ΜΟΝΟ αν περάσει τον λευκό κατάλογο
   και τη συμβολική επαλήθευση του επαληθευτή της. Αλλιώς nil — τίμια άγνοια."
  (and (eq (first spec) :frame)
       (let ((verifier (cdr (assoc (second spec) *advisable-frames*))))
         (and verifier
              (ignore-errors (funcall verifier (cddr spec) input))))))

;;; ── Ανάγνωση της απάντησης του συμβούλου: ΧΩΡΙΣ eval, με όρια ──

(defun %parse-advice (text)
  "Διάβασε την πρόταση του συμβούλου ως sexp: *read-eval* nil, πακέτο :keyword
   (κανένα intern εκτός keywords), όριο μεγέθους, αφαίρεση περιβλήματος ```.
   Οτιδήποτε στραβό ⇒ nil."
  (when (and (stringp text) (<= (length text) 2000))
    (let ((s (string-trim '(#\Space #\Newline #\Return #\Tab) text)))
      ;; αφαίρεσε τυχόν markdown περίβλημα ```…```
      (let ((start (search "(" s)) (end (position #\) s :from-end t)))
        (when (and start end (< start end))
          (handler-case
              (let ((*read-eval* nil)
                    (*package* (find-package :keyword)))
                (let ((form (read-from-string (subseq s start (1+ end)))))
                  (and (consp form) (eq (first form) :frame) form)))
            (error () nil)))))))

;;; ── Ο HTTP πελάτης (OpenAI-συμβατό chat completions) ──

(defparameter +advisor-instructions+
  "Είσαι βοηθητικός ταξινομητής προθέσεων για ελληνικό νομικό σύστημα. Απάντησε ΜΟΝΟ με μία λίστα Lisp, χωρίς σχόλια:
(:frame :article-lookup :corpus \"<κώδικας>\" :article \"<αριθμός>\") για ερώτηση περί συγκεκριμένου άρθρου,
(:frame :corpus-info :corpus \"<κώδικας>\") για ερώτηση περί κώδικα,
(:frame :definition :concept \"<έννοια>\") για ερώτηση ορισμού έννοιας,
NIL αν τίποτα δεν ταιριάζει. Κώδικες: poinikos, astikos, kpolitikis, kpoinikis, kdioikitikis, syntagma.")

(defparameter +dream-instructions+
  "Είσαι γλωσσολόγος ελληνικών νομικών κειμένων. Σου δίνεται ρηματικός τύπος από διάταξη νόμου και προτάσεις-παραδείγματα. Απάντησε ΜΟΝΟ με μία λίστα Lisp, χωρίς σχόλια:
(:dream :lemma \"<α' ενικό, -ω/-ώ/-μαι>\" :pred :<κατηγόρημα-γ'-ενικού> :forms (\"<μορφή1>\" \"<μορφή2>\" …))
Οι μορφές να είναι ΜΟΝΟ πραγματικοί τύποι του ρήματος που περιμένεις σε νομικά κείμενα (γ' ενικό/πληθυντικό, παθητικά). Παράδειγμα: (:dream :lemma \"προξενώ\" :pred :προξενεί :forms (\"προξενεί\" \"προξενούν\" \"προξενείται\"))."
  "Οδηγίες ονείρου: ο σύμβουλος προτείνει ΚΑΛΟΥΠΙ γραμματικής — ποτέ γνώση απευθείας.")

(defun %instructions-for (purpose)
  (case purpose
    (:dream-verb +dream-instructions+)
    (t +advisor-instructions+)))

(defun %parse-dream (text)
  "Διάβασε πρόταση-όνειρο: (:dream :lemma STR :pred KW :forms (STR…)) —
   *read-eval* nil, πακέτο :keyword, όριο μεγέθους. Οτιδήποτε άλλο ⇒ nil."
  (when (and (stringp text) (<= (length text) 2000))
    (let* ((str (string-trim '(#\Space #\Newline #\Return #\Tab) text))
           (start (search "(" str)) (end (position #\) str :from-end t)))
      (when (and start end (< start end))
        (handler-case
            (let ((*read-eval* nil)
                  (*package* (find-package :keyword)))
              (let ((form (read-from-string (subseq str start (1+ end)))))
                (and (consp form) (eq (first form) :dream) form)))
          (error () nil))))))

(defun validate-dream (verb-form dream)
  "Ο ΔΙΚΑΣΤΗΣ του ονείρου: σχήμα σωστό, λήμμα ρηματικό (-ω/-ώ/-μαι), κατηγόρημα
   καθαρό keyword, και — το κρίσιμο — ο ΠΑΡΑΤΗΡΗΜΕΝΟΣ τύπος (VERB-FORM, από τα
   ίδια τα κείμενα) ΠΡΕΠΕΙ να εξηγείται από τις μορφές. (values λήμμα pred
   μορφές) ή nil — το όνειρο δεν γίνεται ποτέ γνώση αν δεν εξηγεί τη μαρτυρία."
  (let ((lemma (getf (rest dream) :lemma))
        (pred (getf (rest dream) :pred))
        (forms (getf (rest dream) :forms)))
    (when (and (stringp lemma) (plusp (length lemma))
               ;; λήμμα = ΜΟΝΟ γράμματα (κανένα /, ., ψηφίο — εχθρικά payloads)
               (every #'alpha-char-p lemma)
               (let ((n (orchestrator.citation-authority:normalize-greek lemma)))
                 (or (char= #\ω (char n (1- (length n))))
                     (and (>= (length n) 3)
                          (string= "μαι" n :start2 (- (length n) 3)))))
               (keywordp pred)
               (every (lambda (c) (or (alpha-char-p c) (char= c #\-)))
                      (symbol-name pred))
               ;; μορφές = ΜΟΝΟ μη-κενές λέξεις από γράμματα — ποτέ κείμενο
               ;; εντολών/κελύφους μεταμφιεσμένο σε «μορφή» (επιθεώρηση 05-07-2026)
               (listp forms) forms
               (every (lambda (f) (and (stringp f) (plusp (length f))
                                       (every #'alpha-char-p f)))
                      forms)
               ;; η μαρτυρία: ο τύπος που ΕΙΔΑΜΕ στα κείμενα εξηγείται
               (member (orchestrator.citation-authority:normalize-greek verb-form)
                       (mapcar #'orchestrator.citation-authority:normalize-greek forms)
                       :test #'string=))
      (values lemma pred forms))))

(defun %advisor-http-call (endpoint model key purpose input)
  "Μία κλήση στον σύμβουλο. Επιστρέφει το κείμενο-περιεχόμενο ή nil. Κάθε
   αποτυχία (δίκτυο/μορφή) ⇒ nil — ο πυρήνας συνεχίζει συμβολικά."
  (declare (ignorable purpose))
  (handler-case
      (let* ((body (with-output-to-string (s)
                     (format s "{\"model\":~S,\"temperature\":0,\"messages\":[~
{\"role\":\"system\",\"content\":~S},~
{\"role\":\"user\",\"content\":~S}]}"
                             model
                             (%instructions-for purpose)
                             input)))
             (response (drakma:http-request
                        (format nil "~A/chat/completions" (string-right-trim "/" endpoint))
                        :method :post
                        :content-type "application/json"
                        :content (sb-ext:string-to-octets body :external-format :utf-8)
                        :additional-headers (when (and key (plusp (length key)))
                                              (list (cons "Authorization"
                                                          (format nil "Bearer ~A" key))))
                        :connection-timeout 10))
             (text (if (stringp response)
                       response
                       (sb-ext:octets-to-string response :external-format :utf-8)))
             (parsed (funcall (find-symbol "PARSE" :jonathan) text :as :alist))
             (choices (cdr (assoc "choices" parsed :test #'equal)))
             (msg (cdr (assoc "message" (first choices) :test #'equal))))
        (cdr (assoc "content" msg :test #'equal)))
    (error () nil)))

(defun install-advisor! ()
  "Σύνδεσε τον σύμβουλο ΑΝ έχει δηλωθεί LAWMAX_ADVISOR_URL — αλλιώς η υποδοχή
   μένει κενή (καθαρά συμβολική λειτουργία, καμία εξάρτηση). Επιστρέφει t/nil."
  (let ((endpoint (uiop:getenv "LAWMAX_ADVISOR_URL")))
    (if (and endpoint (plusp (length endpoint)))
        (let ((model (or (uiop:getenv "LAWMAX_ADVISOR_MODEL") "deepseek-chat"))
              (key (uiop:getenv "LAWMAX_ADVISOR_KEY")))
          (setf orchestrator.cognition:*advisor*
                (lambda (purpose input)
                  (let ((raw (%advisor-http-call endpoint model key purpose input)))
                    (case purpose
                      (:dream-verb (%parse-dream raw))
                      (t (%parse-advice raw))))))
          t)
        (progn (setf orchestrator.cognition:*advisor* nil) nil))))

(defun run-advisor-status ()
  "--advisor : η κατάσταση της υποδοχής συμβούλου — τίμια, ζωντανή."
  (let ((endpoint (uiop:getenv "LAWMAX_ADVISOR_URL")))
    (format t "~%── ΣΥΜΒΟΥΛΟΣ (εκτός εμπιστοσύνης) ──~%")
    (if orchestrator.cognition:*advisor*
        (format t "  ΣΥΝΔΕΔΕΜΕΝΟΣ: ~A (μοντέλο ~A)~%" endpoint
                (or (uiop:getenv "LAWMAX_ADVISOR_MODEL") "deepseek-chat"))
        (format t "  ΚΕΝΗ ΥΠΟΔΟΧΗ — καθαρά συμβολική λειτουργία (όρισε LAWMAX_ADVISOR_URL)~%"))
    (format t "  Ρόλος: προτείνει ΜΟΝΟ πλαίσιο κατανόησης όταν οι ~D συμβολικοί ταξινομητές δεν πιάνουν.~%"
            (length (orchestrator.cognition:classifiers)))
    (format t "  Λευκός κατάλογος (~D):~{ ~(~A~)~}~%"
            (length *advisable-frames*) (mapcar #'car *advisable-frames*))
    (format t "  Κάθε πρόταση επαληθεύεται συμβολικά· εκτελεί ΠΑΝΤΑ το έμπιστο μονοπάτι.~%")
    0))

(defun run-advisor-gate ()
  "--advisor-gate : η πύλη της υποδοχής συμβούλου — με ΨΕΥΔΟσύμβουλο (κανένα
   δίκτυο): ο λευκός κατάλογος και η επαλήθευση, κλειδωμένα."
  (let ((saved orchestrator.cognition:*advisor*)
        (fails '()) (total 0))
    (labels ((check (label ok)
               (incf total)
               (if ok (format t "  ✓ ~A~%" label)
                   (progn (push label fails) (format t "  ✗ ~A~%" label)))))
      (format t "~%── ΠΥΛΗ ΣΥΜΒΟΥΛΟΥ ──~%")
      (unwind-protect
           (let ((gibberish "ξζψωθ κρβνμ ασδφγ"))
             ;; 1 — κενή υποδοχή: άγνωστη είσοδος ⇒ ΤΙΜΙΑ ΑΓΝΟΙΑ (nil), όχι εφεύρεση
             (setf orchestrator.cognition:*advisor* nil)
             (check "κενή υποδοχή: ακατάληπτη είσοδος ⇒ κανένα πλαίσιο (τίμια άγνοια)"
                    (null (orchestrator.cognition:decompose gibberish)))
             ;; 2 — έγκυρη πρόταση λευκού καταλόγου ⇒ επαληθευμένο πλαίσιο
             (setf orchestrator.cognition:*advisor*
                   (lambda (p i) (declare (ignore p i))
                     '(:frame :article-lookup :corpus "poinikos" :article "299")))
             (let ((fr (orchestrator.cognition:decompose gibberish)))
               (check "έγκυρη πρόταση (άρθρο 299 ΠΚ) ⇒ επαληθευμένο πλαίσιο αναζήτησης άρθρου"
                      (and (typep fr 'article-lookup-frame)
                           (equal "poinikos" (orchestrator.cognition:frame-slot fr :corpus))
                           (equal "299" (orchestrator.cognition:frame-slot fr :article)))))
             ;; 3 — πλαίσιο ΕΚΤΟΣ λευκού καταλόγου ⇒ απορρίπτεται
             (setf orchestrator.cognition:*advisor*
                   (lambda (p i) (declare (ignore p i))
                     '(:frame :delete-everything :path "/")))
             (check "πλαίσιο εκτός λευκού καταλόγου ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ"
                    (null (orchestrator.cognition:decompose gibberish)))
             ;; 4 — άγνωστος «κώδικας» ⇒ η συμβολική επαλήθευση τον κόβει
             (setf orchestrator.cognition:*advisor*
                   (lambda (p i) (declare (ignore p i))
                     '(:frame :article-lookup :corpus "../../etc" :article "299")))
             (check "ανύπαρκτος κώδικας στην πρόταση ⇒ η επαλήθευση τον κόβει"
                    (null (orchestrator.cognition:decompose gibberish)))
             ;; 5 — μη-αριθμητικό «άρθρο» ⇒ κόβεται
             (setf orchestrator.cognition:*advisor*
                   (lambda (p i) (declare (ignore p i))
                     '(:frame :article-lookup :corpus "poinikos" :article "299; rm -rf")))
             (check "μη-αριθμητικό άρθρο ⇒ κόβεται"
                    (null (orchestrator.cognition:decompose gibberish)))
             ;; 6 — ο αναγνώστης ΔΕΝ εκτελεί: #.(…) ⇒ nil, χωρίς παρενέργεια
             (check "κείμενο με #.(εκτέλεση) ⇒ ΔΕΝ διαβάζεται (read χωρίς eval)"
                    (null (%parse-advice "(:frame :article-lookup :corpus #.(+ 1 2))")))
             ;; 7 — περίβλημα markdown ```…``` αφαιρείται, η πρόταση διαβάζεται
             (check "πρόταση μέσα σε ``` ⇒ διαβάζεται καθαρά"
                    (equal '(:frame :corpus-info :corpus "astikos")
                           (%parse-advice (format nil "```lisp~%(:frame :corpus-info :corpus \"astikos\")~%```"))))
             ;; ── Σ13α: Ο ΟΝΕΙΡΕΥΤΗΣ ΚΑΙ Ο ΔΙΚΑΣΤΗΣ (ψευδοσύμβουλος, χωρίς δίκτυο) ──
             (let ((tmp-prop (merge-pathnames (format nil "dreamgate-~D.sexp" (get-universal-time))
                                              (uiop:temporary-directory)))
                   (tmp-kdir (merge-pathnames (format nil "dreamgate-k-~D/" (get-universal-time))
                                              (uiop:temporary-directory))))
               (ensure-directories-exist tmp-kdir)
               (let ((orchestrator.proposals:*proposals-path* tmp-prop)
                     (orchestrator.knowledge-packs:*knowledge-dir* tmp-kdir))
                 ;; όνειρο που ΕΞΗΓΕΙ τη μαρτυρία ⇒ δικάζεται, προτείνεται, εγκρίνεται
                 (setf orchestrator.cognition:*advisor*
                       (lambda (p i) (declare (ignore p i))
                         '(:dream :lemma "προξενώ" :pred :προξενεί
                           :forms ("προξενεί" "προξενούν" "προξενείται"))))
                 (check "όνειρο συμβούλου που εξηγεί τη μαρτυρία ⇒ ΜΙΑ πρόταση καλουπιού (μετά πλήρη σκιώδη πύλη)"
                        (= 1 (dream-grammar '(("προξενει" . 5)))))
                 (let ((p (first (orchestrator.proposals:open-proposals))))
                   (check "έγκριση ονείρου ⇒ γράφονται ΚΑΙ τα δύο πακέτα (πλαίσιο+λήμμα) και το ρήμα διαβάζεται"
                          (progn
                            (orchestrator.proposals:approve! (orchestrator.proposals:proposal-id p))
                            (and (orchestrator.citation-authority:known-lemma "προξενεί")
                                 (multiple-value-bind (spec)
                                     (orchestrator.casegrammar:parse-provision
                                      "Όποιος προξενεί σε ξένο πράγμα βλάβη τιμωρείται με φυλάκιση"
                                      :heading "Άρθρο 999 - Δοκιμή")
                                   (and spec
                                        (search "ΠΡΟΞΕΝΕΊ" (format nil "~S" (getf spec :antecedent)))))))))
                 ;; όνειρο που ΔΕΝ εξηγεί τη μαρτυρία ⇒ ΚΑΜΙΑ πρόταση
                 (setf orchestrator.cognition:*advisor*
                       (lambda (p i) (declare (ignore p i))
                         '(:dream :lemma "τρέχω" :pred :τρέχει :forms ("τρέχει"))))
                 (check "όνειρο που ΔΕΝ εξηγεί τον παρατηρημένο τύπο ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ από τον δικαστή"
                        (zerop (dream-grammar '(("προξενει" . 5)))))
                 ;; κακόβουλο «λήμμα» (όχι ρηματικό) ⇒ κόβεται
                 (setf orchestrator.cognition:*advisor*
                       (lambda (p i) (declare (ignore p i))
                         '(:dream :lemma "../../etc" :pred :χ :forms ("προξενει"))))
                 (check "μη-ρηματικό/ύποπτο λήμμα ⇒ κόβεται από τον δικαστή"
                        (zerop (dream-grammar '(("προξενει" . 5)))))
                 ;; ── ΑΥΤΟΕΞΕΛΙΞΗ ΕΝΤΟΣ ΠΟΛΙΤΙΚΗΣ: ο δημιουργός δίνει την κλάση ΜΙΑ φορά ──
                 (let ((tmp-pol (merge-pathnames (format nil "dreampol-~D" (get-universal-time))
                                                 (uiop:temporary-directory))))
                   (let ((*policies-path* tmp-pol))
                     ;; το *policies-path* ορίζεται σε αρχείο που φορτώνει ΜΕΤΑ
                     ;; από τούτο — η δήλωση special κάνει τη δέσμευση ΔΥΝΑΜΙΚΗ
                     (declare (special *policies-path*))
                     (multiple-value-bind (c tot) (measured-evolution-precision :dream-frame)
                       (check (format nil "η κλάση :dream-frame έχει ΚΛΕΙΔΩΜΕΝΗ μετρημένη ακρίβεια ~D/~D πριν ζητηθεί πολιτική"
                                      (length +dream-precision-suite+) (length +dream-precision-suite+))
                              (and (= tot (length +dream-precision-suite+)) (= c tot))))
                     (setf orchestrator.cognition:*advisor*
                           (lambda (p i) (declare (ignore p i))
                             '(:dream :lemma "ενεργώ" :pred :ενεργεί
                               :forms ("ενεργεί" "ενεργούν"))))
                     ;; χωρίς πολιτική: η πρόταση ΠΕΡΙΜΕΝΕΙ τον δημιουργό
                     (dream-grammar '(("ενεργει" . 3)))
                     (check "ΧΩΡΙΣ πολιτική: το όνειρο μένει ΑΝΟΙΧΤΗ πρόταση — ο δημιουργός κυρίαρχος εξ ορισμού"
                            (= 1 (length (orchestrator.proposals:open-proposals))))
                     ;; ενεργοποίηση πολιτικής (με τη μετρημένη ακρίβεια) ⇒ αυτο-υιοθέτηση
                     (let ((*standard-output* (make-broadcast-stream)))
                       (run-policy-approve '("dream-frame")))
                     (check "ΜΕ πολιτική: η εκκρεμής εγκρίνεται και το ρήμα ΔΙΑΒΑΖΕΤΑΙ — αυτοεξέλιξη εντός ορίων"
                            (and (null (orchestrator.proposals:open-proposals))
                                 (orchestrator.citation-authority:known-lemma "ενεργούν")))
                     ;; ανάκληση ⇒ οι επόμενες ξαναπεριμένουν το χέρι του
                     (let ((*standard-output* (make-broadcast-stream)))
                       (run-policy-revoke '("dream-frame")))
                     (setf orchestrator.cognition:*advisor*
                           (lambda (p i) (declare (ignore p i))
                             '(:dream :lemma "προκαλώ" :pred :προκαλεί
                               :forms ("προκαλεί" "προκαλούν"))))
                     (dream-grammar '(("προκαλει" . 4)))
                     (check "ΜΕΤΑ την ανάκληση: το νέο όνειρο ξαναπεριμένει έγκριση — η εξουσία ανακαλείται"
                            (= 1 (length (orchestrator.proposals:open-proposals)))))
                   (ignore-errors (delete-file tmp-pol))))
               (ignore-errors (delete-file tmp-prop))
               (ignore-errors (uiop:delete-directory-tree tmp-kdir :validate t))))
        (setf orchestrator.cognition:*advisor* saved)))
    (format t "~%── ΠΥΛΗ ΣΥΜΒΟΥΛΟΥ: ~D/~D πέρασαν ──~%" (- total (length fails)) total)
    (if fails 1 0)))

(register-command "--advisor"      (lambda (a) (declare (ignore a)) (run-advisor-status)))
(register-command "--advisor-gate" (lambda (a) (declare (ignore a)) (run-advisor-gate)))

;;; Η σύνδεση γίνεται στη φόρτωση: αν υπάρχει LAWMAX_ADVISOR_URL, η υποδοχή
;;; γεμίζει· αλλιώς μένει ρητά κενή. Ποτέ σφάλμα εκκίνησης από τον σύμβουλο.
(ignore-errors (install-advisor!))

(orchestrator.self-model:declare-capability! "σύμβουλος"
 :description "LLM εκτός εμπιστοσύνης: ονειρεύεται προτάσεις, ο συμβολικός δικαστής κρίνει"
 :package :orchestrator.cli :functions '("validate-dream" "install-advisor!")
 :gate "--advisor-gate" :depends-on '("αυτοεπέκταση"))
