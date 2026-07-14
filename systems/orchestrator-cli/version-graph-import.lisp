;;;; systems/orchestrator-cli/version-graph-import.lisp
;;;; ============================================================================
;;;; [0088] Φ3 — IMPORT (M2/M3): τα 6 σώματα → γράφος εκδόσεων + τα text-less
;;;; συνταγματικά records → ΔΗΛΩΜΕΝΑ κενά γνώσης. Ο γράφος χτίζεται ΔΙΠΛΑ στο
;;;; τρέχον consolidated μονοπάτι με FOLD-PARITY GATE ανά σώμα (byte-ίδιο
;;;; κείμενο ανά άρθρο) — δηλωμένη μετάβαση M2-M5 του σχεδίου, cutover στη Φ5.
;;;;
;;;; ΤΙΜΙΟΤΗΤΑ ΧΡΟΝΟΥ (θάνατος της TEMP-04 αναπαραγωγής):
;;;; Το source.json δηλώνει «11/06/1975» σε ΟΛΑ τα άρθρα του Συντάγματος ενώ
;;;; το κείμενο είναι το ΙΣΧΥΟΝ (post-2019). Ο importer ΔΕΝ αναπαράγει το ψέμα:
;;;; για κάθε άρθρο που τα αναθεωρητικά records δηλώνουν τροποποιημένο, το
;;;; genesis valid-from = η ΤΕΛΕΥΤΑΙΑ αναθεώρηση που το άγγιξε (το κείμενο
;;;; αποδεδειγμένα ισχύει ΑΠΟ τότε), και οι προγενέστερες περίοδοι καλύπτονται
;;;; από knowledge-gaps ⇒ version-at σε προ-αναθεώρησης τομή = ΡΗΤΗ
;;;; temporal-uncertainty (πρώτη φορά που το σύστημα λέει την αλήθεια εδώ).

(in-package :orchestrator.cli)

(defun %iso<-greek-date (d)
  "«11/06/1975» → «1975-06-11»· ήδη ISO ⇒ ως έχει· αλλιώς NIL (τίμιο απόν)."
  (cond
    ((and (stringp d) (= 10 (length d)) (char= #\- (char d 4))) d)
    ((and (stringp d) (= 10 (length d)) (char= #\/ (char d 2)) (char= #\/ (char d 5)))
     (format nil "~A-~A-~A" (subseq d 6) (subseq d 3 5) (subseq d 0 2)))
    (t nil)))

(defun %graph-body-for (corpus-id)
  "Η typed ταυτότητα σώματος ανά corpus — ΔΗΛΩΜΕΝΗ στο config (body_identity:
   kind/year/number της κυρωτικής πράξης, δημόσια επαληθεύσιμα στοιχεία),
   ΠΟΤΕ παραγόμενη από publication dates (δύο κώδικες του 2019 συγκρούονταν).
   Το Σύνταγμα = :syntagma· απόν body_identity σε άλλο σώμα ⇒ ΣΦΑΛΜΑ."
  ;; [0088 Φ6γ-Δ³] Η αντιστοίχιση μετακόμισε στην έδρα ταυτότητας
  ;; (orchestrator.identity:declared-body) ώστε γράφος ΚΑΙ corpus μοντέλο
  ;; να καταναλώνουν ΤΗΝ ΙΔΙΑ — εδώ μένει μόνο η επιλογή ενεργού corpus.
  (orchestrator.spec:select-corpus corpus-id)
  (orchestrator.identity:declared-body))

(defun %amended-article-dates (corpus-id)
  "eid → ημερομηνία ΤΕΛΕΥΤΑΙΑΣ αναθεώρησης που τον άγγιξε + λίστα ΟΛΩΝ των
   (ημερομηνία act-ref) ανά eid — από τα text-less versioning.amendments."
  (orchestrator.spec:select-corpus corpus-id)
  (let ((last (make-hash-table :test 'equal))
        (all (make-hash-table :test 'equal)))
    (dolist (rec (orchestrator.spec:config-get "versioning.amendments"))
      (let* ((date (or (%iso<-greek-date
                        (or (%rec-field rec "date_applicability") (%rec-field rec "date")))
                       (error "amendment record χωρίς έγκυρη ημερομηνία: ~S" rec)))
             (fek (%rec-field rec "fek"))
             (arts (append (%rec-field rec "articles_amended")
                           (%rec-field rec "articles_repealed"))))
        (dolist (a arts)
          (let ((eid (format nil "art_~A" a)))
            (push (list date fek) (gethash eid all))
            (when (or (null (gethash eid last)) (string> date (gethash eid last)))
              (setf (gethash eid last) date))))))
    (values last all)))

(defun %rec-field (rec key)
  (cond ((hash-table-p rec) (gethash key rec))
        ((consp rec) (or (cdr (assoc key rec :test #'equalp))
                         (getf rec (intern (string-upcase key) :keyword))))))

(defun import-corpus->graph! (corpus-id)
  "M2/M3: χτίζει τον γράφο του σώματος από το ΣΗΜΕΡΙΝΟ consolidated μονοπάτι
   (ίδια απόδοση κειμένου με ό,τι σερβίρεται — parity by construction στη
   γένεση, ζωντανός ανιχνευτής απόκλισης μετά) + δηλώνει τα κενά γνώσης των
   text-less αναθεωρήσεων. Επιστρέφει (values graph report-plist).
   Fail-closed: υπάρχον journal σώματος ⇒ ΣΦΑΛΜΑ (καμία σιωπηλή διπλοεισαγωγή)."
  (let* ((body (%graph-body-for corpus-id))
         (body-string (orchestrator.identity:body-id-string body))
         (graph (orchestrator.version-graph:make-graph body-string)))
    (when (probe-file (orchestrator.version-graph::vg-path graph))
      (error "import ~A: υπάρχει ήδη journal γράφου (~A) — ρητό καθάρισμα πρώτα, ποτέ σιωπηλό append"
             corpus-id (orchestrator.version-graph::vg-path graph)))
    (multiple-value-bind (short doc) (build-consolidated-for corpus-id)
      (declare (ignore short))
      ;; ημερομηνίες πηγής ανά eid (από το provenance-gated source.json)
      (let ((src-dates (make-hash-table :test 'equal))
            (json-path (provenance-checked-json-source corpus-id)))
        (unless json-path
          (error "import ~A: source.json απορρίφθηκε από το O-3 gate" corpus-id))
        (dolist (o (jonathan:parse (uiop:read-file-string json-path :external-format :utf-8)
                                   :as :alist))
          (let ((aid (%parse-article-title (cdr (assoc "title" o :test #'string=)))))
            (when aid
              (setf (gethash (format nil "art_~A" aid) src-dates)
                    (%iso<-greek-date (cdr (assoc "date" o :test #'string=)))))))
        (multiple-value-bind (last-rev all-revs) (%amended-article-dates corpus-id)
          (let ((imported 0) (gaps 0) (skipped '()))
            (dolist (p (orchestrator.consolidation:legal-document-provisions doc))
              (let* ((eid (orchestrator.consolidation:provision-eid p))
                     (label (subseq eid 4))          ; "art_5Α" → "5Α"
                     (pid (orchestrator.identity:provision-id-string
                           (orchestrator.identity:article-provision-id body label)))
                     ;; ΠΛΗΡΕΣ in-force κείμενο άρθρου από τη ΜΙΑ έδρα απόδοσης
                     ;; (ai-dump:article-text — ίδια σύμβαση με το σερβιριζόμενο JSONL)·
                     ;; :repealed άρθρο ⇒ NIL κείμενο ⇒ tombstone με κενό κείμενο
                     (full-text (orchestrator.ai-dump:article-text p))
                     (repealed (eq :repealed (orchestrator.consolidation:provision-status p)))
                     (text (or full-text ""))
                     (heading (orchestrator.consolidation:provision-heading p))
                     ;; Lettered άρθρο εκτός records (π.χ. 5Α — τα records
                     ;; γράφουν μόνο βάσεις): κληρονομεί ΣΥΝΤΗΡΗΤΙΚΑ τις
                     ;; αναθεωρήσεις της ΒΑΣΗΣ του — ποτέ ψευδής ισχύς από
                     ;; το 1975 για διάταξη που εισήχθη σε αναθεώρηση.
                     (base-eid (let ((pos (position-if-not #'digit-char-p eid :start 4)))
                                 (if pos (subseq eid 0 pos) eid)))
                     (rev-date (or (gethash eid last-rev) (gethash base-eid last-rev)))
                     (src-date (gethash eid src-dates))
                     ;; ΤΙΜΙΟΣ χρόνος: τροποποιημένο ⇒ από την τελευταία
                     ;; αναθεώρηση· αλλιώς η ημερομηνία της πηγής
                     (valid-from (or rev-date src-date)))
                (cond
                  ((null valid-from)
                   (push eid skipped))
                  (t
                   (orchestrator.version-graph:submit-genesis!
                    graph
                    (orchestrator.version-graph:make-version-spec
                     :provision-id pid :text text :heading heading
                     :valid-from valid-from
                     :status (if repealed :repealed :in-force)
                     :assurance :extracted-verified)  ; όλα τα 6 prov stamps φέρουν source_digest
                    :derivation (format nil "bootstrap:~A" corpus-id))
                   (incf imported)
                   ;; κενά γνώσης: ΚΑΘΕ αναθεώρηση που άγγιξε το άρθρο —
                   ;; οι προγενέστερες εκδόσεις κειμένου ΔΕΝ ανακατασκευάζονται
                   (dolist (rev (or (gethash eid all-revs) (gethash base-eid all-revs)))
                     (orchestrator.version-graph:add-knowledge-gap!
                      graph :provision-id pid :act-ref (second rev)
                            :kind :unknown-text :effective (first rev))
                     (incf gaps))))))
            (values graph
                    (list :corpus corpus-id :body body-string
                          :imported imported :gaps gaps
                          :skipped skipped
                          :chain (orchestrator.version-graph::vg-chain graph)))))))))

(defun graph-parity-report (corpus-id graph)
  "FOLD-PARITY GATE (σχέδιο §3 θεραπεία 7): snapshot-at(σήμερα, known τώρα)
   ≡ το consolidated μονοπάτι — BYTE-ίδιο κείμενο ανά άρθρο, ίδιο πλήθος.
   Επιστρέφει (values divergences checked) — ΚΑΘΕ απόκλιση ονομαστική."
  (multiple-value-bind (short doc) (build-consolidated-for corpus-id)
    (declare (ignore short))
    (let* ((body (%graph-body-for corpus-id))
           (today (subseq (orchestrator.journal:iso-now) 0 10))
           (now "9999-12-31T23:59:59Z")
           (divergences '()) (checked 0))
      (dolist (p (orchestrator.consolidation:legal-document-provisions doc))
        (let* ((eid (orchestrator.consolidation:provision-eid p))
               (pid (orchestrator.identity:provision-id-string
                     (orchestrator.identity:article-provision-id body (subseq eid 4)))))
          (incf checked)
          (handler-case
              (multiple-value-bind (v basis)
                  (orchestrator.version-graph:version-at graph pid
                                                         :valid-at today :known-at now)
                (declare (ignore basis))
                (cond
                  ((null v) (push (list eid :missing-in-graph) divergences))
                  ((not (equal (orchestrator.version-graph:tv-text v)
                               (or (orchestrator.ai-dump:article-text p) "")))
                   (push (list eid :text-mismatch) divergences))))
            (orchestrator.version-graph:temporal-uncertainty ()
              (push (list eid :uncertain-today) divergences))
            (orchestrator.version-graph:unknown-provision ()
              (push (list eid :unknown-in-graph) divergences)))))
      (values divergences checked))))

(defun text-as-known (corpus-id article-label &key valid-at known-at)
  "«Τι ήξερε το LAWMAX κατά KNOWN-AT για το άρθρο ARTICLE-LABEL κατά VALID-AT;»
   — η διτεμπορική απάντηση ΑΠΟ ΤΟΝ ΓΡΑΦΟ (πλήρες replay από τον δίσκο, με
   επαλήθευση αλυσίδας). Επιστρέφει plist (:text :heading :valid-from
   :valid-until :assurance :basis) ή σηματοδοτεί temporal-uncertainty /
   unknown-provision — ποτέ σιωπηλό «τρέχον». Δηλωμένο επόμενο βήμα (Φ5-
   πλήρες): έκθεση ως HTTP endpoint /as-known?article=…&valid=…&known=…"
  (multiple-value-bind (graph body) (%ensure-graph corpus-id :if-missing :error)
    (let ((pid (orchestrator.identity:provision-id-string
                (orchestrator.identity:article-provision-id body article-label))))
    (multiple-value-bind (v basis note)
        (orchestrator.version-graph:version-at graph pid
                                               :valid-at valid-at :known-at known-at)
      ;; [Φ7 Π5] typed in_force/basis-kind: ο καταναλωτής ΔΕΝ μπορεί να
      ;; παρερμηνεύσει αναστολή/εκκρεμότητα ως ισχύον κείμενο (spec §6).
      (if (null v)
          (list :text nil :basis basis
                :in-force nil :basis-kind "no-version-in-force"
                :pending (when (and (consp note)
                                    (eq (first note) :not-yet-effective))
                           (list :condition-id (second note) :since (third note))))
          (list :text (orchestrator.version-graph:tv-text v)
                :heading (orchestrator.version-graph:tv-heading v)
                :valid-from (orchestrator.version-graph:tv-valid-from v)
                :valid-until (orchestrator.version-graph:tv-valid-until v)
                :assurance (orchestrator.version-graph:tv-assurance v)
                :basis basis
                :in-force (not (and (consp basis) (eq (first basis) :suspended)))
                :basis-kind (cond ((eq basis :complete) "complete")
                                  ((and (consp basis) (eq (first basis) :suspended))
                                   "suspended")
                                  ((and (consp basis) (eq (first basis) :not-yet-effective))
                                   "complete")
                                  (t "complete"))
                :pending (when (and (consp basis)
                                    (eq (first basis) :not-yet-effective))
                           (list :condition-id (second basis) :since (third basis)))
                :suspended-by (when (and (consp basis) (eq (first basis) :suspended))
                                (second basis))))))))

(defun %source-artifact-for (corpus-id)
  "Η ταυτότητα της πηγής ΜΕΣΑ στη δέσμευση (AUTH-02 ροή): content_sha256 +
   source_digest από το O-3-ελεγμένο prov stamp. Χωρίς έγκυρο stamp ⇒ ΣΦΑΛΜΑ."
  (let ((json-path (or (provenance-checked-json-source corpus-id)
                       (error "temporal-commitment ~A: source.json απορρίφθηκε από το O-3 gate"
                              corpus-id))))
    (let ((prov (jonathan:parse
                 (uiop:read-file-string (format nil "~A.prov.json" (namestring json-path))
                                        :external-format :utf-8) :as :alist)))
      (list (cons "content_sha256" (cdr (assoc "content_sha256" prov :test #'string=)))
            (cons "source_digest" (cdr (assoc "source_digest" prov :test #'string=)))))))

(defun %ensure-graph (corpus-id &key (if-missing :import))
  "Η ΜΙΑ ΕΙΣΟΔΟΣ «δώσε μου τον γράφο» — commitment/serving/reasoning τη
   μοιράζονται ΟΛΑ (κριτής Β 1.1: πριν, serving έγραφε inline load-graph).
   Επιστρέφει (values graph typed-body body-string). IF-MISSING:
     :import — απόν journal ⇒ import από την provenance-ελεγμένη πηγή (χτίσιμο)·
     :error  — απόν journal ⇒ ΣΦΑΛΜΑ (serving: δεν χτίζουμε ποτέ mid-serve).
   load-graph = πλήρες replay + payload/chain/semantic επαλήθευση κάθε γραμμής."
  (let* ((body (%graph-body-for corpus-id))
         (body-string (orchestrator.identity:body-id-string body))
         (probe (orchestrator.version-graph:make-graph body-string))
         (present (probe-file (orchestrator.version-graph::vg-path probe))))
    (values
     (cond
       (present (orchestrator.version-graph:load-graph body-string))
       ((eq if-missing :import) (import-corpus->graph! corpus-id))
       (t (error "graph ~A: απόν journal (~A) και if-missing=:error — δεν χτίζεται mid-serve"
                 corpus-id (orchestrator.version-graph::vg-path probe))))
     body body-string)))

(defun corpus-temporal-commitment (corpus-id)
  "[0088 Φ5] Η ΜΙΑ έδρα του temporal commitment ενός corpus — ό,τι δένεται στο
   census (census-2) ώστε το release root να δεσμεύει ΚΑΙ τη διτεμπορική
   ιστορία ΚΑΙ το σύνολο των LegalAuthorityReceipts (κλείσιμο PCL-02):
     graph_root        = κεφαλή της chain-hash αλυσίδας του journal (πλήρες
                         replay από τον δίσκο — verify-chain, ποτέ live μνήμη)
     receipt_set_root  = RFC-6962 MTH πάνω στα receipt-ids στη σημερινή τομή,
                         σε ντετερμινιστική σειρά provision-id
   FAIL-CLOSED: απόν journal ⇒ import από την provenance-ελεγμένη πηγή· κάθε
   receipt επανεπαληθεύεται (0 failures ή ΣΦΑΛΜΑ)· αβέβαιη διάταξη ΣΗΜΕΡΑ ⇒
   ΣΦΑΛΜΑ (δείχνει σφάλμα import, όχι αποδεκτή άγνοια). Επιστρέφει plist."
  (multiple-value-bind (graph body body-string) (%ensure-graph corpus-id)
    (multiple-value-bind (ok head n) (orchestrator.version-graph:verify-chain body-string)
      (unless (and ok (plusp n)
                   (equal head (orchestrator.version-graph:graph-chain-head graph)))
        (error "temporal-commitment ~A: verify-chain απέτυχε ή κεφαλή ≠ ζωντανής (~A ≠ ~A)"
               corpus-id head (orchestrator.version-graph:graph-chain-head graph)))
      (let ((valid-at (subseq (orchestrator.journal:iso-now) 0 10))
            (known-at "9999-12-31T23:59:59Z")
            (src (%source-artifact-for corpus-id)))
        (multiple-value-bind (receipts uncertain)
            (orchestrator.legal-receipt:build-receipts-for-graph
             graph :source-artifact src :valid-at valid-at :known-at known-at)
          (when uncertain
            (error "temporal-commitment ~A: ~D διατάξεις αβέβαιες ΣΤΗ ΣΗΜΕΡΙΝΗ τομή — σφάλμα import: ~S"
                   corpus-id (length uncertain) (subseq uncertain 0 (min 5 (length uncertain)))))
          (let ((failures '()))
            (dolist (r receipts)
              (multiple-value-bind (rok why)
                  (orchestrator.legal-receipt:verify-receipt graph r)
                (unless rok
                  (push (list (orchestrator.legal-receipt:lr-provision-id r) why) failures))))
            (when failures
              (error "temporal-commitment ~A: ~D receipt verification failures: ~S"
                     corpus-id (length failures) (subseq failures 0 (min 5 (length failures))))))
          (list :body body-string
                ;; in-memory extras (ΔΕΝ σειριοποιούνται στο census json — το
                ;; census->json διαβάζει μόνο τα scalar πεδία): για grounded
                ;; reasoning/επιθεώρηση χωρίς δεύτερη ανακατασκευή
                :typed-body body
                :graph graph
                :receipts receipts
                :graph-root head
                :graph-records n
                :receipt-set-root (orchestrator.merkle:merkle-root-of-strings
                                   (mapcar #'orchestrator.legal-receipt:lr-receipt-id receipts))
                :receipt-count (length receipts)
                :valid-at valid-at
                :known-at known-at))))))

(defun document-as-of (corpus-id as-of)
  "[0088 Φ5δ — ΤΟ CUTOVER ΤΟΥ ΣΕΡΒΙΡΙΣΜΑΤΟΣ] Ιστορικό ενοποιημένο έγγραφο
   ΑΠΟ ΤΟΝ ΔΙΤΕΜΠΟΡΙΚΟ ΓΡΑΦΟ (snapshot-at), ΟΧΙ από το παλιό text-less
   select-acts μονοπάτι (ο θάνατος της TEMP-03 αναπαραγωγής στο serving):
   το consolidate-corpus :as-of-date «εφάρμοζε» text-less amendments και
   επέστρεφε ΣΗΜΕΡΙΝΟ κείμενο ως ιστορικό με ψευδή βεβαιότητα.
   ΕΔΩ: κάθε διάταξη επιλύεται με version-at στην τομή (AS-OF, known τώρα)·
   ΟΠΟΙΑΔΗΠΟΤΕ διάταξη σε κενό γνώσης ⇒ temporal-uncertainty για ΟΛΟ το
   έγγραφο (ονομαστική λίστα) — μερικό «ιστορικό» έγγραφο δεν σερβίρεται.
   Διατάξεις χωρίς κάλυψη στην τομή (π.χ. δεν είχαν εισαχθεί ακόμη)
   παραλείπονται ΤΙΜΙΑ — δεν υπήρχαν τότε. Επιστρέφει legal-document."
  (let* ((graph (%ensure-graph corpus-id :if-missing :error))
         (short (or (orchestrator.spec:config-get "corpus.short_name") corpus-id))
         (title (orchestrator.spec:config-get "corpus.name")))
    (multiple-value-bind (snap uncertain)
        (orchestrator.version-graph:snapshot-at
         graph :valid-at as-of :known-at "9999-12-31T23:59:59Z")
      (when uncertain
        ;; ο provider σηματοδοτεί το boundary contract του service ΑΠΕΥΘΕΙΑΣ
        ;; (as-of-unavailable) — μερικό ιστορικό έγγραφο δεν σερβίρεται
        (error 'orchestrator.corpus-service:as-of-unavailable
               :date as-of
               :cause (format nil "κενά γνώσης σε ~D διατάξεις (πρώτες: ~{~A~^, ~}) — ιστορική ανασυγκρότηση ΔΕΝ σερβίρεται μερική"
                              (length uncertain)
                              (mapcar #'car (subseq uncertain 0 (min 5 (length uncertain)))))))
      (let ((rows
              (sort (mapcar (lambda (pair)
                              (let* ((pid (car pair)) (v (cdr pair))
                                     (label (subseq pid (1+ (position #\: pid)))))
                                (list (orchestrator.identity:parse-provision-designator pid)
                                      label v)))
                            snap)
                    #'orchestrator.identity:provision-id< :key #'first)))
        (orchestrator.consolidation:make-legal-document
         :id short :title title :language "el"
         :provisions
         (mapcar (lambda (row)
                   (destructuring-bind (id label v) row
                     (declare (ignore id))
                     (orchestrator.consolidation:make-provision
                      :eid (format nil "art_~A" label)
                      :kind :article :num label
                      :heading (orchestrator.version-graph:tv-heading v)
                      :text (orchestrator.version-graph:tv-text v)
                      :status (case (orchestrator.version-graph:tv-status v)
                                (:repealed :repealed)
                                (t (let ((cb (orchestrator.version-graph:tv-created-by v)))
                                     (if (and (stringp cb) (eql 0 (search "bootstrap" cb)))
                                         :original :amended))))
                      :source-date (orchestrator.version-graph:tv-valid-from v))))
                 rows))))))
