;;;; systems/orchestrator-cli/release-authority.lisp
;;;; ============================================================================
;;;; P1R [0046] — CONTENT-ADDRESSED RELEASE AUTHORITY (παραγωγικές είσοδοι)
;;;; ============================================================================
;;;; --cut-release <corpus>    : κόβει release-commitment για τον κώδικα, ΧΩΡΙΣ
;;;;   per-article deploy και ΧΩΡΙΣ wipe — συνθέτει τις ΙΔΙΕΣ έδρες (provenance
;;;;   check → load-json-source stage → orchestrator.epistemic seat). Κανένα
;;;;   wrapper: δεν καλεί το --run-pipeline.
;;;; --attest-release <corpus> : επαληθεύει το commitment (recomputed root ≡
;;;;   ταυτότητα), προσαρτά RFC-3161 receipts APPEND-ONLY και προάγει το latest.
;;;; Η ταυτότητα release = sha256-<Merkle root> ⇒ overwrite δομικά αδύνατο.

(in-package :orchestrator.cli)

(defun %stage-reaches-p (stage-name target-string by-name &optional seen)
  "T όταν το STAGE-NAME φτάνει (μεταβατικά, μέσω εξαρτήσεων) το στάδιο με
   symbol-name TARGET-STRING. Σύγκριση με string= — τα ονόματα σταδίων είναι
   σύμβολα του πακέτου ορισμού του pipeline, όχι του καλούντος. Κύκλος στον
   ορισμό ⇒ ΣΦΑΛΜΑ (ποτέ σιωπηλή άρνηση/βρόχος)."
  (let ((key (symbol-name stage-name)))
    (when (member key seen :test #'string=)
      (error "cut-release: κύκλος εξαρτήσεων στον pipeline γύρω από το στάδιο ~A" key))
    (or (string= key target-string)
        (let ((stage (gethash key by-name)))
          (and stage
               (some (lambda (dep)
                       (%stage-reaches-p dep target-string by-name (cons key seen)))
                     (orchestrator.spec:stage-dependencies stage)))))))

(defun %release-stage-chain ()
  "P1b [0052]#Ε4/#Β1: η αλυσίδα σταδίων του release παράγεται από ΤΟΝ ΙΔΙΟ
   ορισμό pipeline (defpipeline greek-constitution) — ΟΧΙ χειροκίνητο
   αντίγραφο. Υπολογίζει το ΚΛΕΙΣΙΜΟ του υπο-DAG
     {S : hash-artifacts ⟶* S ΚΑΙ S ⟶* load-json-source}
   (ΟΛΑ τα στάδια πάνω σε ΟΠΟΙΟΔΗΠΟΤΕ μονοπάτι από την είσοδο json ως το
   hashing — όχι ένα μονοπάτι: ρόμβος στον ορισμό δεν αφήνει ΠΟΤΕ κλάδο
   σιωπηλά απ' έξω) και το διατάσσει τοπολογικά κατά τις εξαρτήσεις.
   Έτσι νέο ενδιάμεσο στάδιο του pipeline μπαίνει ΑΥΤΟΜΑΤΑ και στο
   --cut-release — τα δύο παραγωγικά μονοπάτια δεν μπορούν να αποκλίνουν
   σιωπηλά (η κλάση του «identityHash NIL» εξαλείφεται δομικά).
   Επιστρέφει λίστα stage objects σε σειρά εκτέλεσης."
  (let* ((pkg (or (find-package :orchestrator.gr-syntagma)
                  (error "cut-release: το πακέτο orchestrator.gr-syntagma δεν είναι φορτωμένο")))
         (pipeline-name (or (find-symbol "GREEK-CONSTITUTION" pkg)
                            (error "cut-release: ο pipeline greek-constitution δεν ορίζεται")))
         (pipeline (or (orchestrator.spec:find-pipeline pipeline-name)
                       (error "cut-release: ο pipeline greek-constitution δεν είναι καταχωρισμένος")))
         (stages (orchestrator.spec:pipeline-stages pipeline))
         (by-name (make-hash-table :test 'equal)))
    (dolist (s stages)
      (setf (gethash (symbol-name (orchestrator.spec:stage-name s)) by-name) s))
    (dolist (endpoint '("HASH-ARTIFACTS" "LOAD-JSON-SOURCE"))
      (unless (gethash endpoint by-name)
        (error "cut-release: το στάδιο ~A λείπει από τον pipeline" endpoint)))
    ;; Μέλη του υπο-DAG: S πάνω σε μονοπάτι load-json-source → … → hash-artifacts,
    ;; δηλ. S ⟶* load-json-source ΚΑΙ hash-artifacts ⟶* S.
    (let* ((hash-name (orchestrator.spec:stage-name (gethash "HASH-ARTIFACTS" by-name)))
           (in-subdag
             (remove-if-not
              (lambda (s)
                (let ((sname (orchestrator.spec:stage-name s)))
                  (and (%stage-reaches-p sname "LOAD-JSON-SOURCE" by-name)
                       (%stage-reaches-p hash-name (symbol-name sname) by-name))))
              stages))
           (member-names (mapcar (lambda (s)
                                   (symbol-name (orchestrator.spec:stage-name s)))
                                 in-subdag)))
      ;; Τοπολογική διάταξη ΜΕΣΑ στο υπο-DAG (Kahn πάνω στις εξαρτήσεις).
      (let ((ordered '())
            (pending (copy-list in-subdag)))
        (loop while pending do
          (let ((ready (find-if
                        (lambda (s)
                          (every (lambda (dep)
                                   (or (not (member (symbol-name dep) member-names
                                                    :test #'string=))
                                       (member (symbol-name dep)
                                               (mapcar (lambda (o)
                                                         (symbol-name (orchestrator.spec:stage-name o)))
                                                       ordered)
                                               :test #'string=)))
                                 (orchestrator.spec:stage-dependencies s)))
                        pending)))
            (unless ready
              (error "cut-release: αδύνατη τοπολογική διάταξη του release υπο-DAG — κύκλος στον ορισμό του pipeline;"))
            (push ready ordered)
            (setf pending (remove ready pending))))
        (nreverse ordered)))))

(defun %release-corpus-context (corpus-id)
  "Articles για release μέσω των παραγωγικών εδρών: select-corpus →
   provenance-checked source.json → load-json-source-stage. Επιστρέφει
   (values articles output-dir short-name)."
  (orchestrator.spec:select-corpus corpus-id)
  (orchestrator.gr-syntagma:register-active-corpus)
  ;; ίδια αρχικοποίηση canonical URIs με το source-normalize-stage
  (let ((yaml (orchestrator.spec:ensure-config-loaded)))
    (when yaml (orchestrator.uris:load-canonical-uris-from-config yaml)))
  (let* ((short (or (orchestrator.spec:config-get "corpus.short_name")
                    (error "cut-release: corpus.short_name not configured")))
         (output-dir (corpus-output-dir
                      (or (uiop:getenv "ORCHESTRATOR_OUTPUT_DIR")
                          (orchestrator.paths:institution-dir "output/"))))
         ;; B4 [0047]/[0049]: η ΙΔΙΑ έδρα provenance-checked πηγής με το pipeline
         (json-path (or (provenance-checked-json-source corpus-id)
                        (error "cut-release ~A: source.json ΧΩΡΙΣ έγκυρο provenance — δεν κόβεται release από μη επαληθευμένη πηγή" corpus-id)))
         (context (make-instance 'orchestrator.core:pipeline-context
                                 :pipeline nil :config nil)))
    (orchestrator.core:set-context-value
     context :sources (list (list :type :json :path json-path)))
    (orchestrator.core:set-context-value
     context :corpus (orchestrator.meta:get-corpus :gr-syntagma))
    ;; ΙΔΙΑ παραγωγικά stages ΚΑΙ πύλες με το pipeline μέχρι το hashing,
    ;; ΠΑΡΑΓΟΜΕΝΑ από τον ορισμό του pipeline (βλ. %release-stage-chain) —
    ;; όχι χειροκίνητο αντίγραφο. Χωρίς το hashing stage το lineage έγραφε
    ;; identityHash "NIL" και τα δύο μονοπάτια παρήγαγαν διαφορετική
    ;; ταυτότητα release. Μία ταυτότητα ανά περιεχόμενο, από όποιο μονοπάτι.
    (dolist (stage (%release-stage-chain))
      (funcall (orchestrator.spec:stage-function stage) context))
    (let ((articles (orchestrator.core:get-context-value context :articles)))
      (unless articles (error "cut-release ~A: καμία διάταξη από το source.json" corpus-id))
      (values articles output-dir short context))))

(defun run-cut-release (corpus-id)
  "--cut-release : κόψιμο content-addressed release-commitment για CORPUS-ID.
   Χρόνος metadata ΜΟΝΟ από δηλωμένη αρχή (require-deterministic-time)· TSA
   αποτυχία ⇒ τίμιο UNATTESTED commitment (latest ΔΕΝ προάγεται).
   P1b [0052]#Ε4: το deploy γίνεται μέσω της ΙΔΙΑΣ έδρας stage με τον
   pipeline (orchestrator.engine.sbcl:deploy-epistemic-stage) — μαζί με την
   επαλήθευση του execution proof του test-escaping· το release μονοπάτι δεν
   παρακάμπτει ΚΑΜΙΑ πύλη."
  (multiple-value-bind (articles output-dir short context)
      (%release-corpus-context corpus-id)
    (format t "~%── CUT-RELEASE ~A (~A): ~D διατάξεις ──~%" corpus-id short (length articles))
    (orchestrator.core:set-context-value context :output-dir output-dir)
    ;; [0088 Φ5/PCL-02]: το cut-release περνά από την ΙΔΙΑ πύλη — census-2
    ;; μόνο με δεσμευμένη διτεμπορική ιστορία από τη ΜΙΑ έδρα.
    (orchestrator.core:set-context-value
     context :temporal-commitment (corpus-temporal-commitment corpus-id))
    (orchestrator.engine.sbcl:deploy-epistemic-stage context)
    (let ((release-id (orchestrator.core:get-context-value context :epistemic-release-id))
          (attested (orchestrator.core:get-context-value context :epistemic-attested))
          (release-dir (orchestrator.core:get-context-value context :epistemic-release-dir)))
      (format t "~%RELEASE: ~A~%ATTESTED: ~A~%DIR: ~A~%"
              release-id
              (if attested "ΝΑΙ (legacy)" "ΟΧΙ — η attestation ζει πλέον στο authority-v2 admission kernel")
              release-dir)
      0)))

(defun run-attest-release (corpus-id &key (tsa-fn nil) (release-id-arg nil))
  "[Δ3 — ΚΑΤΑΡΓΗΜΕΝΗ ΕΔΡΑ] Η εντολή ΑΡΝΕΙΤΑΙ ΣΤΗΝ ΠΡΩΤΗ ΓΡΑΜΜΗ.

  ΕΥΡΗΜΑ ΔΗΜΙΟΥΡΓΟΥ: το ενεργό --attest-release έγραφε TSA receipts ΜΕΣΑ σε
  υπάρχον releases/<id>/temporal-proof/ και ΜΟΝΟ ΜΕΤΑ καλούσε το καταργημένο
  promote-latest!. Δηλαδή ΜΠΟΡΟΥΣΕ να μεταβάλει legacy evidence και κατόπιν να
  αποτύχει — μόνιμη αλλοίωση του παρελθόντος από εντολή που «δεν κάνει τίποτα».
  Η άρνηση μπαίνει ΠΡΙΝ από ΚΑΘΕ ενέργεια: πριν από config lookup, πριν από
  release discovery, πριν από κάθε TSA κλήση, πριν από κάθε byte.
  Η attestation είναι πλέον ΥΠΟΧΡΕΩΤΙΚΟ CONJUNCT του admission kernel.

  Ιστορική τεκμηρίωση της παλιάς διαδρομής:
  --attest-release <corpus> [release-id] : προσάρτηση χρονικής απόδειξης σε
   ΥΠΑΡΧΟΝ commitment. Η επιλογή στόχου είναι ΝΤΕΤΕΡΜΙΝΙΣΤΙΚΗ, ποτέ ευρετική:
   ρητό release-id, αλλιώς ο ΜΟΝΑΔΙΚΟΣ υποψήφιος· με πολλούς ⇒ ΣΦΑΛΜΑ με
   πλήρη λίστα (ο δημιουργός ονομάζει, το σύστημα δεν μαντεύει).
   ① επαλήθευση: recomputed root των 8 canonical ≡ ταυτότητα καταλόγου
   ② RFC-3161 receipts (append-only: υπάρχοντα receipts ΔΕΝ αγγίζονται)
   ③ προαγωγή latest (μόνο τότε). TSA-FN injectable ΜΟΝΟ για offline test."
  ;; ΠΡΩΤΗ ΕΝΤΟΛΗ — πριν από config lookup, πριν από release discovery, πριν
  ;; από κάθε TSA κλήση, πριν από κάθε byte. Καμία παρενέργεια δεν προηγείται.
  (error 'orchestrator.epistemic:legacy-authority-seat-removed
         :seat "--attest-release"
         :detail "ΚΑΤΑΡΓΗΜΕΝΗ ΕΔΡΑ: καμία εγγραφή στο legacy releases/ — η attestation είναι conjunct του admission kernel (authority-v2)")
  ;; ── ΑΠΡΟΣΙΤΟΣ ΚΩΔΙΚΑΣ (ιστορικό ίχνος της παλιάς διαδρομής) ──
  (orchestrator.spec:select-corpus corpus-id)
  (let* ((short (or (orchestrator.spec:config-get "corpus.short_name")
                    (error "attest-release: corpus.short_name not configured")))
         (output-dir (corpus-output-dir
                      (or (uiop:getenv "ORCHESTRATOR_OUTPUT_DIR")
                          (orchestrator.paths:institution-dir "output/"))))
         (releases-dir (merge-pathnames "releases/" (uiop:ensure-directory-pathname output-dir)))
         (candidates (remove-if-not
                      (lambda (d) (let ((leaf (car (last (pathname-directory d)))))
                                    (and (stringp leaf) (eql 0 (search "sha256-" leaf)))))
                      (uiop:subdirectories releases-dir))))
    (unless candidates
      (error "attest-release ~A: κανένα content-addressed release στο ~A" corpus-id releases-dir))
    (let* ((release-dir
             (cond
               (release-id-arg
                (or (find release-id-arg candidates
                          :key (lambda (d) (car (last (pathname-directory d))))
                          :test #'equal)
                    (error "attest-release ~A: ανύπαρκτο release ~A~%  υπαρκτά:~{~%  ~A~}"
                           corpus-id release-id-arg
                           (mapcar (lambda (d) (car (last (pathname-directory d)))) candidates))))
               ((null (rest candidates)) (first candidates))
               (t (error "attest-release ~A: ~D υποψήφια commitments — δώσε ΡΗΤΟ release-id:~{~%  ~A~}"
                         corpus-id (length candidates)
                         (mapcar (lambda (d) (car (last (pathname-directory d)))) candidates)))))
           (release-id (car (last (pathname-directory release-dir))))
           (fp (find-package :orchestrator.epistemic))
           (root (funcall (find-symbol "%RELEASE-RECOMPUTED-ROOT" fp) release-dir))
           (expected (funcall (find-symbol "%ROOT->RELEASE-ID" fp) root)))
      (format t "~%── ATTEST-RELEASE ~A: ~A ──~%" short release-id)
      (unless (equal expected release-id)
        (error "attest-release: ΔΙΑΦΘΟΡΑ — recomputed ~A ≠ ταυτότητα ~A" expected release-id))
      (format t "  ✓ ακεραιότητα: recomputed root ≡ ταυτότητα~%")
      (let* ((temporal-dir (merge-pathnames "temporal-proof/" release-dir))
             (tsr (merge-pathnames "timestamp.tsr" temporal-dir)))
        (if (probe-file tsr)
            (format t "  ✓ ήδη attested (τα υπάρχοντα receipts ΔΕΝ αγγίζονται)~%")
            (if tsa-fn
                (funcall tsa-fn root temporal-dir)
                (funcall (find-symbol "REQUEST-MULTI-TSA-TIMESTAMPS" fp) root temporal-dir)))
        (unless (probe-file tsr)
          (error "attest-release: καμία TSA δεν απέδωσε receipt — το commitment μένει unattested"))
        (funcall (find-symbol "PROMOTE-LATEST!" fp) output-dir release-id)
        (format t "  ✓ ATTESTED + latest → ~A~%" release-id)
        0))))

(register-command "--cut-release"
  (lambda (args) (run-cut-release (or (first args) (uiop:getenv "ORCHESTRATOR_CORPUS")))))
(register-command "--attest-release"
  (lambda (args) (run-attest-release (or (first args) (uiop:getenv "ORCHESTRATOR_CORPUS"))
                                     :release-id-arg (second args))))

(orchestrator.self-model:declare-capability! "εξουσία-εκδόσεων"
 :description "content-addressed release authority: ταυτότητα = Merkle root του περιεχομένου (overwrite δομικά αδύνατο)· χρόνος = append-only RFC-3161 attestation πάνω στο commitment· latest προάγεται ΜΟΝΟ σε attested· παραγωγικές είσοδοι --cut-release/--attest-release, κανένα wrapper"
 :package :orchestrator.cli
 :functions '("run-cut-release" "run-attest-release" "%release-corpus-context")
 :gate "--release-gate")

(orchestrator.contracts:defcontract "content-addressed-release" :protocol
 :package :orchestrator.cli :system "orchestrator-cli"
 :capability "εξουσία-εκδόσεων" :role "νομική-μνήμη"
 :purpose "κάθε δημοσιευμένη έκδοση είναι αμετάβλητη ΕΚ ΚΑΤΑΣΚΕΥΗΣ (όνομα = περιεχόμενο) και χρονικά αποδεδειγμένη ΠΡΙΝ γίνει η τρέχουσα — ποτέ σιωπηλό ρολόι, ποτέ αντικατάσταση ιστορικού"
 :inputs '("provenance-checked source.json" "SOURCE_DATE_EPOCH (δηλωμένη αρχή χρόνου)" "RFC-3161 TSAs")
 :outputs '("releases/sha256-<root>/ commitment" "append-only temporal attestations" "latest symlink + υπογεγραμμένος δείκτης latest.json")
 :preconditions '("deterministic mode ενεργό για output-bound χρόνο (αλλιώς ΣΦΑΛΜΑ)")
 :postconditions '("υπάρχον release ΠΟΤΕ δεν διαγράφεται/ξαναγράφεται"
                   "latest ⇒ πάντα attested release")
 :side-effects '("append-only εγγραφές κάτω από output/<corpus>/releases/")
 :legal-critical t :policy-level :φραγή
 :audit "release-id ≡ recomputed root ελέγξιμο από τον καθένα με το verify kit"
 :rollback "revert commit — κανένα υπάρχον release δεν έχει πειραχτεί"
 :tests '("--release-gate"))
