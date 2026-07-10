;;;; tests/corpus-identity-test.lisp
;;;; ============================================================================
;;;; P0 IDENTITY LOCK [0039]/[0041]: κανένα νομικό αντικείμενο χωρίς μοναδική
;;;; ταυτότητα — τα lettered άρθρα (5Α, 370ΣΤ, …) ΔΙΑΚΡΙΤΑ από τα βασικά,
;;;; σε ΚΑΘΕ corpus, σε doc / JSONL / AKN / fingerprint / γραμματική τίτλου.
;;;; ============================================================================
;;;; Ιστορικό: τα stale corpus.jsonl/AKN artifacts είχαν καταρρεύσει τα lettered
;;;; (constitution 124/120, poinikos 529/462 κ.λπ.). Ο ζωντανός κώδικας είναι
;;;; σωστός — αυτό το test ΚΛΕΙΔΩΝΕΙ ότι θα μείνει σωστός: κάθε μελλοντική
;;;; παλινδρόμηση ταυτότητας κοκκινίζει το gated standalone loop.
;;;; Τρέχει κάτω από docker/run-standalone-test.lisp (self-exit 0/1).

(in-package :orchestrator.cli)

(defvar *cit-pass* 0)
(defvar *cit-fail* 0)

(defmacro cit-check (name form)
  `(handler-case
       (if ,form
           (progn (incf *cit-pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *cit-fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e)
       (incf *cit-fail*)
       (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

(format t "~%── P0 IDENTITY LOCK: μοναδικότητα νομικών ταυτοτήτων ανά corpus ──~%")

;;; ① ΚΑΘΕ corpus: πλήθος>0 και eIds ΜΟΝΑΔΙΚΑ (η θεμελιώδης αναλλοίωτη)
(defparameter *cit-docs* '())
(dolist (cid '("syntagma" "poinikos" "kpoinikis" "astikos" "kpolitikis" "kdioikitikis"))
  (multiple-value-bind (short doc) (build-consolidated-for cid)
    (push (list cid short doc) *cit-docs*)
    (let* ((eids (mapcar #'orchestrator.consolidation:provision-eid
                         (orchestrator.consolidation:legal-document-provisions doc)))
           (uniq (remove-duplicates eids :test #'equal)))
      (cit-check (format nil "① ~A: ~D άρθρα, ΟΛΑ με μοναδικό eId" cid (length eids))
                 (and (plusp (length eids)) (= (length eids) (length uniq)))))))
(setf *cit-docs* (nreverse *cit-docs*))

;;; ② Σύνταγμα: τα 4 γνωστά lettered ΠΑΡΟΝΤΑ και τα βασικά τους ΕΠΙΣΗΣ παρόντα
;;;   (μοναδικότητα ① ⇒ διακριτά· εδώ κλειδώνουμε ότι ΥΠΑΡΧΟΥΝ και τα 8)
(let* ((doc (third (assoc "syntagma" *cit-docs* :test #'equal)))
       (eids (mapcar #'orchestrator.consolidation:provision-eid
                     (orchestrator.consolidation:legal-document-provisions doc))))
  (dolist (pair '(("art_5Α" "art_5") ("art_9Α" "art_9")
                  ("art_100Α" "art_100") ("art_101Α" "art_101")))
    (cit-check (format nil "② σύνταγμα: ~A ΚΑΙ ~A παρόντα (διακριτά)" (first pair) (second pair))
               (and (member (first pair) eids :test #'equal)
                    (member (second pair) eids :test #'equal)))))

;;; ③ Γενική αναλλοίωτη lettered: σε ΚΑΘΕ corpus, κάθε lettered eId έχει
;;;   ΔΙΑΦΟΡΕΤΙΚΟ string από το βασικό του — και όπου το βασικό υπάρχει,
;;;   συνυπάρχουν ως ΔΥΟ εγγραφές (καμία σιωπηλή κατάρρευση)
(dolist (entry *cit-docs*)
  (destructuring-bind (cid short doc) entry
    (declare (ignore short))
    (let* ((eids (mapcar #'orchestrator.consolidation:provision-eid
                         (orchestrator.consolidation:legal-document-provisions doc)))
           (lettered (remove-if-not
                      (lambda (e) (cl-ppcre:scan "^art_[0-9]+[Α-Ω]+$" e)) eids))
           (bad (loop for l in lettered
                      for base = (cl-ppcre:regex-replace "[Α-Ω]+$" l "")
                      when (and (member base eids :test #'equal)
                                (= (count l eids :test #'equal) 0))
                        collect l)))
      (cit-check (format nil "③ ~A: ~D lettered, κανένα δεν καταρρέει στο βασικό του"
                         cid (length lettered))
                 (null bad)))))

;;; ④ JSONL serialization (σύνταγμα): γραμμές = άρθρα · ids μοναδικά · art_5Α παρόν
(let* ((doc (third (assoc "syntagma" *cit-docs* :test #'equal)))
       (n (length (orchestrator.consolidation:legal-document-provisions doc)))
       (jsonl (funcall (find-symbol "EMIT-CORPUS-JSONL" :orchestrator.ai-dump) doc))
       (ids '()))
  ;; ΜΟΝΟ article-level eIds (κλειστό pattern με το quote) — τα paragraph
  ;; eIds (art_1__para_1) ΔΕΝ μετρούν στην αναλλοίωτη «μία γραμμή ανά άρθρο».
  (cl-ppcre:do-register-groups (id) ("\"eId\":\"(art_[0-9]+[Α-Ω]*)\"" jsonl)
    (push id ids))
  (cit-check "④ JSONL: μία γραμμή ανά άρθρο, eIds ΜΟΝΑΔΙΚΑ, art_5Α ΚΑΙ art_5 παρόντα"
             (and (= (length ids) n)
                  (= (length ids) (length (remove-duplicates ids :test #'equal)))
                  (member "art_5Α" ids :test #'equal)
                  (member "art_5" ids :test #'equal))))

;;; ⑤ AKN serialization (σύνταγμα): eId attributes άρθρων μοναδικά · art_5Α παρόν
(let* ((doc (third (assoc "syntagma" *cit-docs* :test #'equal)))
       (akn (funcall (find-symbol "EMIT-AKOMA-NTOSO" :orchestrator.akoma-ntoso) doc))
       (eids '()))
  (cl-ppcre:do-register-groups (e) ("eId=\"(art_[^\"_]+)\"" akn)
    (push e eids))
  (cit-check "⑤ AKN: eIds άρθρων ΜΟΝΑΔΙΚΑ, art_5Α ΚΑΙ art_5 παρόντα"
             (and (plusp (length eids))
                  (= (length eids) (length (remove-duplicates eids :test #'equal)))
                  (member "art_5Α" eids :test #'equal)
                  (member "art_5" eids :test #'equal))))

;;; ⑥ Γραμματική τίτλου (η ΜΙΑ είσοδος ταυτότητας): lettered/digraph/απλά/άκυρα
(multiple-value-bind (id heading) (%parse-article-title "Άρθρο 5Α - Δικαίωμα στην πληροφόρηση")
  (cit-check "⑥α «Άρθρο 5Α - …» ⇒ id=5Α + heading"
             (and (equal id "5Α") (equal heading "Δικαίωμα στην πληροφόρηση"))))
(multiple-value-bind (id heading) (%parse-article-title "Άρθρο 370ΣΤ - Ψηφιακά δεδομένα")
  (declare (ignore heading))
  (cit-check "⑥β δίγραφο επίθημα: «Άρθρο 370ΣΤ» ⇒ id=370ΣΤ" (equal id "370ΣΤ")))
(multiple-value-bind (id heading) (%parse-article-title "Άρθρο 5 - Ελεύθερη ανάπτυξη")
  (declare (ignore heading))
  (cit-check "⑥γ απλό: «Άρθρο 5 - …» ⇒ id=5 (ΟΧΙ 5Α)" (equal id "5")))
(multiple-value-bind (id heading) (%parse-article-title "Γενικές διατάξεις")
  (declare (ignore id))
  (cit-check "⑥δ τίτλος χωρίς αριθμό ⇒ NIL + πλήρης τίτλος (τίμιο fallback σήμα)"
             (equal heading "Γενικές διατάξεις")))

;;; ⑦ Fingerprint manifest: 005 και 005Α ⇒ ΔΥΟ διακριτές ταυτότητες art_5/art_5Α
(let ((dir (merge-pathnames (format nil "cit-fp-~D/" (get-universal-time))
                            (uiop:temporary-directory))))
  (ensure-directories-exist dir)
  (dolist (pair '(("005" "aaaa1111") ("005Α" "bbbb2222")))
    (with-open-file (o (merge-pathnames (format nil "article-~A.hash" (first pair)) dir)
                       :direction :output :if-exists :supersede :external-format :utf-8)
      (write-string (second pair) o)))
  (let* ((m (orchestrator.fingerprint:output-manifest dir :id "cit"))
         (eids (mapcar (lambda (r) (getf r :eid))
                       (orchestrator.fingerprint:manifest-articles m))))
    (cit-check "⑦ fingerprint: article-005 + article-005Α ⇒ art_5 ΚΑΙ art_5Α (διακριτά)"
               (and (= 2 (length eids))
                    (member "art_5" eids :test #'equal)
                    (member "art_5Α" eids :test #'equal))))
  (ignore-errors (uiop:delete-directory-tree dir :validate (constantly t))))

;;; ⑧ Latent seat ([0041] 1-line fix): article→normalized ΔΙΑΤΗΡΕΙ το label
(let* ((a (orchestrator.model:make-article :number 5 :title "x" :content "y")))
  (setf (orchestrator.model:article-label a) "5Α")
  (let ((n (orchestrator.model:article-to-normalized-input a :json "test.json")))
    (cit-check "⑧ article(label=5Α) → normalized: το label ΕΠΙΖΕΙ (όχι «5»)"
               (equal "5Α" (orchestrator.model:article-label n)))))
(let* ((a (orchestrator.model:make-article :number 7 :title "x" :content "y"))
       (n (orchestrator.model:article-to-normalized-input a :json "test.json")))
  (cit-check "⑧β χωρίς label ⇒ fallback στον αριθμό «7» (συμβατότητα)"
             (equal "7" (orchestrator.model:article-label n))))

;;; ⑨ P1b [0049]: filename ≡ identity — το όνομα αρχείου προκύπτει από το LABEL,
;;; ποτέ από τον εσωτερικό συνθετικό αριθμό αποσαφήνισης (5Α ⇒ number 5001).
(let ((a (orchestrator.model:make-article :number 5001 :title "Άρθρο 5Α - Χ" :content "y")))
  (setf (orchestrator.model:article-label a) "5Α")
  (cit-check "⑨ file-id lettered: label «5Α» + συνθετικό number 5001 ⇒ «005Α» (όχι «5001Α»)"
             (equal "005Α" (orchestrator.model:article-file-id a))))
(let ((b (orchestrator.model:make-article :number 70 :title "Άρθρο 70" :content "y")))
  (cit-check "⑨β file-id απλό: number 70 χωρίς label ⇒ «070»"
             (equal "070" (orchestrator.model:article-file-id b))))

;;; ⑩ P1b [0052]: ΝΟΜΟΘΕΤΙΚΗ σειρά επιθημάτων (Α..Ε,ΣΤ,Ζ..Θ,Ι,ΙΑ,…) — η ΜΙΑ
;;; έδρα article-suffix-ordinal· το λεξικογραφικό string< έστελνε το ΣΤ μετά
;;; το Ι, παραποιώντας τη νομική σειρά σε manifests/AKN/consolidation.
(cit-check "⑩ suffix-ordinal: \"\"<Α<Ε<ΣΤ<Ζ<Θ<Ι<ΙΑ<ΙΣΤ (νομική ακολουθία)"
           (let ((ord #'orchestrator.model:article-suffix-ordinal))
             (and (= 0 (funcall ord ""))
                  (= 1 (funcall ord "Α"))
                  (= 5 (funcall ord "Ε"))
                  (= 6 (funcall ord "ΣΤ"))
                  (= 7 (funcall ord "Ζ"))
                  (= 9 (funcall ord "Θ"))
                  (= 10 (funcall ord "Ι"))
                  (= 11 (funcall ord "ΙΑ"))
                  (= 16 (funcall ord "ΙΣΤ")))))
(cit-check "⑩β άκυρο επίθημα (λατινικό A/πεζό/ανάποδο) ⇒ ΣΦΑΛΜΑ, όχι σιωπηλή ψευδοταυτότητα"
           (and (handler-case (progn (orchestrator.model:article-suffix-ordinal "A") nil)
                  (error () t))
                (handler-case (progn (orchestrator.model:article-label-suffix "5α") nil)
                  (error () t))
                (handler-case (progn (orchestrator.model:article-label-suffix "Α5") nil)
                  (error () t))))
(cit-check "⑩γ article-identity<: 272Ε < 272ΣΤ < 272Ζ < 272Ι (ΟΧΙ ΣΤ τελευταίο)"
           (let* ((mk (lambda (n l) (let ((a (orchestrator.model:make-article
                                              :number n :title "x" :content "y")))
                                      (setf (orchestrator.model:article-label a) l)
                                      a)))
                  (e (funcall mk 272005 "272Ε"))
                  (st (funcall mk 272006 "272ΣΤ"))
                  (z (funcall mk 272007 "272Ζ"))
                  (i (funcall mk 272010 "272Ι"))
                  (sorted (orchestrator.model:articles-in-identity-order (list i z st e))))
             (equal '("272Ε" "272ΣΤ" "272Ζ" "272Ι")
                    (mapcar #'orchestrator.model:article-label sorted))))

;;; ⑪ P1b [0052]#Ε2/Α2: ΚΑΝΟΝΙΚΟΠΟΙΗΣΗ ΣΤΟ ΟΡΙΟ ΤΟΥ FRBR — constructors με
;;; ΣΥΝΘΕΤΙΚΗ είσοδο (5001, full label «5Α») αποδίδουν την ΑΛΗΘΙΝΗ ταυτότητα.
(let ((root (orchestrator.model:make-frbr-article-root
             :article-number 5001 :article-suffix "5Α" :article-title "Χ"
             :eli-prefix "https://x/eli/gr/const/1975"
             :document-type "const" :law-year "1975" :issued-date "1975-06-11")))
  (cit-check "⑪ frbr-article-root(5001,«5Α»): slots=(5,Α), URI art/5Α, eli-id art-005Α"
             (and (= 5 (orchestrator.model:article-number root))
                  (equal "Α" (orchestrator.model:article-letter-suffix root))
                  (search "/art/5Α" (orchestrator.model:resource-uri root))
                  (equal "gr-const-1975-art-005Α" (orchestrator.model:eli-identifier root))
                  (equal "5Α" (orchestrator.model:frbr-article-id root)))))
(let ((work (orchestrator.model:make-frbr-work
             :article-number 5001 :article-suffix "5Α"
             :eli-prefix "https://x/eli/gr/const/1975"
             :document-type "const" :law-year "1975" :issued-date "1975-06-11")))
  (cit-check "⑪β frbr-work(5001,«5Α»): slots=(5,Α), URI art/5Α/work, eli-id -005Α-work"
             (and (= 5 (orchestrator.model:article-number work))
                  (equal "Α" (orchestrator.model:article-letter-suffix work))
                  (search "/art/5Α/work" (orchestrator.model:resource-uri work))
                  (equal "gr-const-1975-art-005Α-work" (orchestrator.model:eli-identifier work)))))

;;; ⑫ P1b [0052]#Ε1: PROV activity με ΔΙΚΗ ΤΟΥ ταυτότητα ανά lettered άρθρο.
(let ((act (orchestrator.model:make-prov-activity
            :article-number 5 :article-suffix "Α" :corpus-name "constitution"
            :start-time "2026-07-09T00:00:00Z")))
  (cit-check "⑫ activity(5,Α): URI …/art-5Α/… (το 5Α ΔΕΝ μοιράζεται activity με το 5)"
             (search "/art-5Α/" (orchestrator.model:resource-uri act))))

;;; ⑬ P1b [0052]#Α6: ΤΟ ΚΛΕΙΔΩΜΑ ΤΗΣ ΚΛΑΣΗΣ — ο ΠΛΗΡΗΣ FRBR TTL από ΣΥΝΘΕΤΙΚΗ
;;; IIR είσοδο (number 5001, label «5Α») δεν περιέχει ΠΟΥΘΕΝΑ τον συνθετικό:
;;; αναίρεση του label-threading στο generate-rdf ή της κανονικοποίησης στο
;;; όριο κοκκινίζει ΕΔΩ (κανένα άλλο gate δεν το έπιανε).
(orchestrator.spec:select-corpus "syntagma")
(orchestrator.gr-syntagma:register-active-corpus)
(let ((yaml (orchestrator.spec:ensure-config-loaded)))
  (when yaml (orchestrator.uris:load-canonical-uris-from-config yaml)))
(defparameter *cit-frbr-ttl*
  (handler-case
      (orchestrator.engine.sbcl::generate-frbr-unified-from-iir
       (orchestrator.model:make-normalized-article-input
        :article-number 5001 :article-label "5Α"
        :article-title "Άρθρο 5Α - Δοκιμή" :article-content "1. Κείμενο."
        :source-type :json :source-path "test.json"))
    (error (e) (format nil "GENERATION-ERROR: ~A" e))))
(cit-check "⑬ FRBR TTL(IIR 5001/«5Α»): περιέχει art/5Α + art-005Α, ΚΑΝΕΝΑ «5001»"
           (and (search "/art/5Α" *cit-frbr-ttl*)
                (search "art-005Α" *cit-frbr-ttl*)
                (not (search "5001" *cit-frbr-ttl*))))
(cit-check "⑬β legislationIdentifier φέρει ART/5Α (όχι σκέτη βάση ART/5)"
           (search "ART/5Α" *cit-frbr-ttl*))
(cit-check "⑬γ banners: «Article 5Α», ποτέ σκέτο «Article 5 -»"
           (and (search "Article 5Α" *cit-frbr-ttl*)
                (not (search "# Article 5 -" *cit-frbr-ttl*))))

;;; ⑭ P1b [0052]#Ε3: provenance filename ≡ manifest provenance_url (μία έδρα).
(let ((a (orchestrator.model:make-article :number 5001 :label "5Α"
                                          :title "Άρθρο 5Α - Χ" :content "y")))
  (cit-check "⑭ article-provenance-file-name: «article-005Α-provenance» από τη μία έδρα"
             (equal "article-005Α-provenance"
                    (orchestrator.ai-core::article-provenance-file-name a))))

;;; ⑮ P1b [0052]#Α3: add-article — σύγκρουση κλειδιού ⇒ ΣΦΑΛΜΑ (όχι σιωπηλή
;;; αντικατάσταση)· επανακαταχώριση ΙΔΙΟΥ αντικειμένου ιδεμποτής.
(let ((c (orchestrator.model:make-corpus :name "Δοκιμή" :short-name "test"
                                         :eli-prefix "https://x/eli"))
      (a1 (orchestrator.model:make-article :number 7 :title "α" :content "x"))
      (a2 (orchestrator.model:make-article :number 7 :title "β" :content "y")))
  (orchestrator.spec:add-article c a1)
  (cit-check "⑮ add-article: ίδιο αντικείμενο ξανά = ΟΚ· ΑΛΛΟ άρθρο στο ίδιο κλειδί ⇒ σφάλμα"
             (and (orchestrator.spec:add-article c a1)
                  (handler-case (progn (orchestrator.spec:add-article c a2) nil)
                    (error () t)))))

;;; ⑯ P1b [0052]#Α7: clone-article διατηρεί το label (ταυτότητα δεν συμπτύσσεται).
(let* ((a (orchestrator.model:make-article :number 5001 :label "5Α"
                                           :title "τ" :content "κ"))
       (c (orchestrator.model::clone-article a)))
  (cit-check "⑯ clone-article: το label «5Α» ΕΠΙΖΕΙ στον κλώνο"
             (equal "5Α" (orchestrator.model:article-label c))))

;;; ⑰ P1b [0052]#Ε4: η αλυσίδα σταδίων του --cut-release παράγεται από τον
;;; ΟΡΙΣΜΟ του pipeline και καταλήγει στο hashing (καμία χειροκίνητη λίστα).
(cit-check "⑰ release-stage-chain: load-json→…→hash-artifacts, παράγωγη του defpipeline"
           (let ((names (mapcar (lambda (s)
                                  (symbol-name (orchestrator.spec:stage-name s)))
                                (orchestrator.cli::%release-stage-chain))))
             (and (equal "LOAD-JSON-SOURCE" (first names))
                  (equal "HASH-ARTIFACTS" (car (last names)))
                  (member "TEST-ESCAPING" names :test #'equal)
                  (member "VALIDATE-SHACL" names :test #'equal)
                  (member "GENERATE-RDF" names :test #'equal))))

;;; ⑱ P1b [0052]#Ε6: wikidata ΜΟΝΟ με ρητό qid — ποτέ δεσμός σε λάθος οντότητα.
(cit-check "⑱ syntagma (με qid): owl:sameAs → Q16519798, ΚΑΝΕΝΑ ψευδές Q41"
           (and (search "Q16519798" *cit-frbr-ttl*)
                (not (search "Q41#" *cit-frbr-ttl*))))
(orchestrator.spec:select-corpus "kpolitikis")
(orchestrator.gr-syntagma:register-active-corpus)
(let ((yaml (orchestrator.spec:ensure-config-loaded)))
  (when yaml (orchestrator.uris:load-canonical-uris-from-config yaml)))
(defparameter *cit-noqid-ttl*
  (handler-case
      (orchestrator.engine.sbcl::generate-frbr-unified-from-iir
       (orchestrator.model:make-normalized-article-input
        :article-number 7 :article-label "7"
        :article-title "Άρθρο 7 - Δοκιμή" :article-content "1. Κείμενο."
        :source-type :json :source-path "test.json"))
    (error (e) (format nil "GENERATION-ERROR: ~A" e))))
(cit-check "⑱β kpolitikis (ΧΩΡΙΣ qid): το owl:sameAs wikidata ΠΑΡΑΛΕΙΠΕΤΑΙ ολόκληρο"
           (not (search "wikidata.org" *cit-noqid-ttl*)))

;;; ⑲ P1b [0052]: manifest γραμμή = JSON OBJECT (όχι array εναλλασσόμενων
;;; keys/values — η κλάση P1-D) + provenance_url ≡ έδρα ονόματος.
(let* ((corpus (orchestrator.model:make-corpus
                :name "Δοκιμή" :short-name "test" :eli-prefix "https://x/eli"
                :publication-date "2000-01-01" :webid "https://x/id" :orcid "0"))
       (a (orchestrator.model:make-article :number 5001 :label "5Α"
                                           :title "Άρθρο 5Α - Χ" :content "κ"))
       (cfg (orchestrator.ai-core:make-ai-export-config))
       (line (orchestrator.ai-core:manifest-entry-to-json
              (orchestrator.ai-core:generate-article-manifest-entry-with-config
               a corpus cfg))))
  (cit-check "⑲ config-manifest entry: JSON object με «\"id\"» + provenance_url από την έδρα"
             (and (char= #\{ (char line 0))
                  (search "\"id\":" line)
                  (search "article-005Α-provenance.json" line)
                  (not (search "5001" line)))))

;;; ⑳ P1b [0052]#Ε7: deterministic export ΧΩΡΙΣ δηλωμένη αρχή χρόνου ⇒ ΣΦΑΛΜΑ.
(cit-check "⑳ effective-deterministic-timestamp: χωρίς fixed & χωρίς αρχή ⇒ σφάλμα· με fixed ⇒ τιμή"
           (let ((cfg (orchestrator.ai-core:make-ai-export-config)))
             (and (let ((orchestrator.time:*deterministic-mode* nil))
                    (handler-case
                        (progn (orchestrator.ai-core:effective-deterministic-timestamp cfg) nil)
                      (error () t)))
                  (progn (setf (orchestrator.ai-core:config-fixed-timestamp cfg) 12345)
                         (= 12345 (orchestrator.ai-core:effective-deterministic-timestamp cfg))))))

;;; ㉑ P1b [0052]#Α1: ΜΙΑ συμπεριφορά γραμματικής τίτλου και στα ΔΥΟ μονοπάτια —
;;; «5 Α» (κενό πριν το επίθημα) = ΑΚΥΡΟ ΠΑΝΤΟΥ, ποτέ σιωπηλή επανερμηνεία.
(cit-check "㉑ label «5 Α» ⇒ σφάλμα στην έδρα (όχι σιωπηλή κανονικοποίηση σε «Α»)"
           (handler-case (progn (orchestrator.model:article-label-suffix "5 Α") nil)
             (error () t)))
(cit-check "㉑β CLI τίτλος «Άρθρο 5Α - Τ» ⇒ id «5Α»· «Άρθρο 5 Α - Τ» ⇒ ΣΦΑΛΜΑ"
           (and (equal "5Α" (orchestrator.cli::%parse-article-title "Άρθρο 5Α - Τ"))
                (handler-case (progn (orchestrator.cli::%parse-article-title "Άρθρο 5 Α - Τ") nil)
                  (error () t))))
(cit-check "㉑γ json-adapter «Άρθρο 5 Α - Τ» ⇒ ΣΦΑΛΜΑ (όχι σιωπηλή ταυτότητα «5»)"
           (let ((h (make-hash-table :test 'equal)))
             (setf (gethash "title" h) "Άρθρο 5 Α - Τ"
                   (gethash "content" h) (list "1. Κ.")
                   (gethash "date" h) "2000-01-01")
             (handler-case
                 (progn (orchestrator.engine.sbcl::json-item->normalized-input h "t.json") nil)
               (error () t))))
(cit-check "㉑δ CLI αναγνωρίζει πολυγράμματο επίθημα: «Άρθρο 80ΙΓ - Τ» ⇒ «80ΙΓ»"
           (equal "80ΙΓ" (orchestrator.cli::%parse-article-title "Άρθρο 80ΙΓ - Τ")))

;;; ㉒ P1b [0052]#Ε10: το gr-syntagma split περνά από την έδρα ορίου —
;;; ενδοκειμενική αναφορά ΔΕΝ κόβεται, newline-αγκυρωμένη παράγραφος κόβεται.
(cit-check "㉒ split-into-paragraphs: «άρθρων 9, 9Α και 19.» δεν κόβεται· «\\n2. » κόβεται"
           (let ((parts (orchestrator.gr-syntagma:split-into-paragraphs
                         (format nil "1. Κατά τα άρθρων 9, 9Α και 19. Συνέχεια.~%2. Δεύτερη."))))
             (and (= 2 (length parts))
                  (search "άρθρων 9" (first parts))
                  (search "Συνέχεια" (first parts)))))

(format t "~%========================================~%")
(format t "Corpus identity tests: ~D passed, ~D failed~%" *cit-pass* *cit-fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *cit-fail*) 0 1))
