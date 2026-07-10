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
         (json-path (orchestrator.spec:resolve-config-path "source.json"))
         (context (make-instance 'orchestrator.core:pipeline-context
                                 :pipeline nil :config nil)))
    (unless (or (%source-provenance-valid-p json-path)
                (uiop:getenvp "ORCHESTRATOR_ALLOW_UNVERIFIED_JSON"))
      (error "cut-release ~A: source.json ΧΩΡΙΣ έγκυρο provenance — δεν κόβεται release από μη επαληθευμένη πηγή" corpus-id))
    (orchestrator.core:set-context-value
     context :sources (list (list :type :json :path json-path)))
    (orchestrator.core:set-context-value
     context :corpus (orchestrator.meta:get-corpus :gr-syntagma))
    ;; ΙΔΙΑ παραγωγικά stages με το pipeline: IIR φόρτωση + IIR→article (FRBR)
    (orchestrator.engine.sbcl:load-json-source-stage context)
    (orchestrator.engine.sbcl:generate-rdf-stage context)
    (let ((articles (orchestrator.core:get-context-value context :articles)))
      (unless articles (error "cut-release ~A: καμία διάταξη από το source.json" corpus-id))
      (values articles output-dir short))))

(defun run-cut-release (corpus-id)
  "--cut-release : κόψιμο content-addressed release-commitment για CORPUS-ID.
   Χρόνος metadata ΜΟΝΟ από δηλωμένη αρχή (require-deterministic-time)· TSA
   αποτυχία ⇒ τίμιο UNATTESTED commitment (latest ΔΕΝ προάγεται)."
  (multiple-value-bind (articles output-dir short) (%release-corpus-context corpus-id)
    (format t "~%── CUT-RELEASE ~A (~A): ~D διατάξεις ──~%" corpus-id short (length articles))
    (let ((result (orchestrator.epistemic:deploy-epistemic-stage
                   articles output-dir
                   :timestamp (orchestrator.time:require-deterministic-time))))
      (format t "~%RELEASE: ~A~%ATTESTED: ~A~%DIR: ~A~%"
              (getf result :release-id)
              (if (getf result :attested) "ΝΑΙ (latest προήχθη)" "ΟΧΙ — χρήση --attest-release")
              (getf result :release-dir))
      0)))

(defun run-attest-release (corpus-id &key (tsa-fn nil))
  "--attest-release : προσάρτηση χρονικής απόδειξης σε ΥΠΑΡΧΟΝ commitment.
   ① επαλήθευση: recomputed root των 8 canonical ≡ ταυτότητα καταλόγου
   ② RFC-3161 receipts (append-only: υπάρχοντα receipts ΔΕΝ αγγίζονται)
   ③ προαγωγή latest (μόνο τότε). TSA-FN injectable ΜΟΝΟ για offline test."
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
    (let* ((release-dir (first (sort candidates #'> :key
                                     (lambda (d) (or (ignore-errors (file-write-date d)) 0)))))
           (release-id (car (last (pathname-directory release-dir))))
           (fp (find-package :orchestrator.epistemic))
           (canonical (funcall (find-symbol "COLLECT-EPISTEMIC-ARTIFACTS" fp) release-dir))
           (root (funcall (find-symbol "MERKLE-TREE-ROOT" fp)
                          (funcall (find-symbol "BUILD-MERKLE-TREE" fp) canonical)))
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
  (lambda (args) (run-attest-release (or (first args) (uiop:getenv "ORCHESTRATOR_CORPUS")))))

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
