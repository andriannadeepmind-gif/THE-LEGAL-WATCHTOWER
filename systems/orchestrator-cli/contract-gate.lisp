;;;; systems/orchestrator-cli/contract-gate.lisp
;;;; ============================================================================
;;;; Η ΠΥΛΗ ΤΩΝ ΣΥΜΒΟΛΑΙΩΝ — η αστυνομία εγκυρότητας της αυτοπεριγραφής
;;;; ============================================================================
;;;;
;;;; Το contract layer (orchestrator.contracts) είναι η ΠΗΓΗ ΑΛΗΘΕΙΑΣ της
;;;; δεσμευτικής αυτοπεριγραφής· εδώ κλειδώνεται: (α) μηχανική επικύρωση όλου
;;;; του μητρώου με πλήρες πλαίσιο, (β) θεσμική ταυτότητα ως ΣΥΜΒΟΛΑΙΟ,
;;;; (γ) κάλυψη παρόχων ανά ικανότητα, (δ) το πρώτο θεμελιώδες συμβόλαιο
;;;; (article-identity-management) με ΕΚΤΕΛΕΣΙΜΑ τεστ ταυτότητας (100 ≠ 100Α),
;;;; (ε) ΑΡΝΗΤΙΚΑ τεστ: πλαστό συμβόλαιο πρέπει να ΑΠΟΡΡΙΠΤΕΤΑΙ — αλλιώς ο
;;;; επικυρωτής είναι διακοσμητικός. Νέα πύλη = αυτόματα μέλος της ολομέλειας.

(in-package :orchestrator.cli)

(defun run-contract-gate ()
  "--contract-gate : contract-governed αυτοεπίγνωση, κλειδωμένη — 100% ή κόκκινο."
  (let ((fails '()) (total 0))
    (labels ((check (label ok)
               (incf total)
               (if ok (format t "  ✓ ~A~%" label)
                   (progn (push label fails) (format t "  ✗ ~A~%" label)))))
      (format t "~%── ΠΥΛΗ ΣΥΜΒΟΛΑΙΩΝ: η αυτοπεριγραφή είναι δεσμευτική ──~%")
      ;; ① Ο επικυρωτής, με ΠΛΗΡΕΣ πλαίσιο (ικανότητες, ρόλοι, Ίδρυμα, εντολές):
      ;;    μηδέν παραβάσεις στο ζωντανό μητρώο.
      (let ((v (orchestrator.self-model:validate-all-contracts
                :test-exists-p #'find-command)))
        (check (format nil "① επικύρωση ΟΛΩΝ των συμβολαίων: ~D παραβάσεις" (length v))
               (null v))
        (dolist (msg v) (format t "      ✗ ~A~%" msg)))
      ;; ② Η θεσμική ταυτότητα είναι ΣΥΜΒΟΛΑΙΟ, όχι φράση: το Ίδρυμα υπάρχει,
      ;;    ο orchestrator είναι δηλωμένος ρόλος-όργανο ΔΙΑΚΡΙΤΟΣ από το όλον.
      (let ((inst (orchestrator.institution:the-institution))
            (idc (orchestrator.contracts:find-contract "institutional-identity")))
        (check "② Ίδρυμα LAWMAX δηλωμένο· μηχανή συντονισμού = ρόλος-όργανο ≠ ταυτότητα του όλου"
               (and inst
                    (search "LAWMAX" (orchestrator.institution:institution-name inst))
                    (orchestrator.institution:find-role
                     (orchestrator.institution:institution-coordination-engine inst))
                    (string/= (orchestrator.institution:institution-name inst)
                              (orchestrator.institution:institution-coordination-engine inst))))
        (check "③ το συμβόλαιο ταυτότητας υπάρχει (kind :institutional-identity, legal-critical, με τεστ)"
               (and idc
                    (eq (orchestrator.contracts:contract-kind idc) :institutional-identity)
                    (orchestrator.contracts:contract-legal-critical idc)
                    (orchestrator.contracts:contract-tests idc))))
      ;; ④ Κάθε ικανότητα ΜΕ ΠΥΛΗ έχει ≥1 συμβόλαιο-πάροχο.
      (let ((gated (remove-if-not #'orchestrator.self-model:capability-gate
                                  (orchestrator.self-model:all-capabilities))))
        (let ((naked (remove-if (lambda (cap)
                                  (orchestrator.contracts:contracts-for-capability
                                   (orchestrator.self-model:capability-name cap)))
                                gated)))
          (check (format nil "④ κάθε ικανότητα με πύλη έχει ≥1 συμβόλαιο-πάροχο (~D/~D)"
                         (- (length gated) (length naked)) (length gated))
                 (null naked))
          (dolist (c naked)
            (format t "      ✗ χωρίς συμβόλαιο: ~A~%"
                    (orchestrator.self-model:capability-name c)))))
      ;; ⑤ Ικανότητα με legal-critical συμβόλαιο ⇒ ΠΛΗΡΗΣ κάλυψη των κρίσιμων
      ;;    συναρτήσεών της — κρίσιμη συνάρτηση χωρίς συμβόλαιο ρίχνει την πύλη.
      (let* ((cov (orchestrator.self-model:contract-coverage))
             (critical-caps
               (remove-duplicates
                (loop for c in (orchestrator.contracts:all-contracts)
                      when (and (orchestrator.contracts:contract-legal-critical c)
                                (orchestrator.contracts:contract-capability c))
                        collect (orchestrator.contracts:contract-capability c))
                :test #'string-equal))
             (holes (remove-if-not
                     (lambda (u) (member (car u) critical-caps :test #'string-equal))
                     (getf cov :uncovered))))
        (check "⑤ καμία legal-critical ικανότητα με ακάλυπτη κρίσιμη συνάρτηση"
               (null holes))
        (dolist (h holes)
          (format t "      ✗ ~A: ~{~A~^, ~}~%" (car h) (cdr h)))
        ;; ⑥ κανένα ορφανό συμβόλαιο (δείχνει ανύπαρκτη ικανότητα)
        (check "⑥ κανένα ορφανό συμβόλαιο" (null (getf cov :orphans))))
      ;; ⑦-⑨ ΤΟ ΘΕΜΕΛΙΩΔΕΣ ΣΥΜΒΟΛΑΙΟ: article-identity-management
      (let ((c (orchestrator.contracts:find-contract "article-identity-management")))
        (check "⑦ article-identity: υπάρχει, legal-critical, ανθρώπινη-έγκριση, audit+rollback, ρόλος νομικής μνήμης"
               (and c (orchestrator.contracts:contract-legal-critical c)
                    (eq (orchestrator.contracts:contract-policy-level c) :ανθρώπινη-έγκριση)
                    (orchestrator.contracts:contract-audit c)
                    (orchestrator.contracts:contract-rollback c)
                    (string= (orchestrator.contracts:contract-role c) "νομική-μνήμη")))
        (check "⑧ article-identity: η επίπτωση δηλώνει corpus/normalized/ELI/URI/RDF/SHACL/citation/proof/temporal/gates"
               (and c (subsetp '(:corpus-keying :normalized-input :eli-uri
                                 :canonical-uri :rdf-subjects :shacl-validation
                                 :citation-resolver :proof-hashes
                                 :temporal-conclusions :regression-gates)
                               (orchestrator.contracts:contract-impact-tags c))))
        ;; ⑨ ο αιτιώδης γράφος τρέφεται από το ΣΥΜΒΟΛΑΙΟ (dependents), όχι μόνο
        ;;    από χειρόγραφα depends-on: υπαγωγή+παραδοτέο κληρονομούν, και το
        ;;    ελάχιστο regression περιέχει τις πύλες τους.
        (multiple-value-bind (caps gates)
            (orchestrator.self-model:capability-impact "ταυτότητα-άρθρων")
          (let ((names (mapcar #'orchestrator.self-model:capability-name caps)))
            (check "⑨ impact(ταυτότητα-άρθρων) ⊇ {υπαγωγή, παραδοτέο} μέσω contract dependents + πύλες τους"
                   (and (member "υπαγωγή" names :test #'string=)
                        (member "παραδοτέο" names :test #'string=)
                        (member "--subsumption-gate" gates :test #'string=)
                        (member "--draft-gate" gates :test #'string=))))))
      ;; ⑩-⑫ ΕΚΤΕΛΕΣΙΜΑ τεστ ταυτότητας — το συμβόλαιο ελέγχεται στην πράξη.
      ;;     Η βάση URI δένεται ΣΚΙΩΔΩΣ όταν το deployment δεν είναι
      ;;     ρυθμισμένο (δυναμική δέσμευση — καμία μόλυνση του ζωντανού config).
      (let ((orchestrator.uris:*canonical-config*
              (if (gethash "base_uri" orchestrator.uris:*canonical-config*)
                  orchestrator.uris:*canonical-config*
                  (let ((h (make-hash-table :test 'equal)))
                    (setf (gethash "base_uri" h) "https://gate.test")
                    h))))
        (check "⑩ 100 ≠ 100Α: διακριτά URIs — το επίθημα ΔΕΝ καταρρέει"
               (let ((u100  (orchestrator.uris:build-article-uri "100"))
                     (u100a (orchestrator.uris:build-article-uri "100Α")))
                 (and (stringp u100) (stringp u100a) (string/= u100 u100a)
                      (search "100Α" u100a))))
        (check "⑪ σταθερότητα: ίδια είσοδος ⇒ ίδιο URI σε κάθε κλήση (και με έκδοση)"
               (and (string= (orchestrator.uris:build-article-uri "299")
                             (orchestrator.uris:build-article-uri "299"))
                    (string= (orchestrator.uris:build-article-uri "299" "2")
                             (orchestrator.uris:build-article-uri "299" "2"))
                    (string/= (orchestrator.uris:build-article-uri "299")
                              (orchestrator.uris:build-article-uri "299" "2")))))
      (check "⑫ κανονικοποίηση κειμένου ΔΙΑΤΗΡΕΙ το επίθημα: normalize-greek(\"100Α\") ≠ normalize-greek(\"100\")"
             (string/= (orchestrator.legal-id:normalize-greek "100Α")
                       (orchestrator.legal-id:normalize-greek "100")))
      ;; ⑬-⑮ ΑΡΝΗΤΙΚΑ: ο επικυρωτής ΠΙΑΝΕΙ πλαστά συμβόλαια (σκιά μητρώου —
      ;;     δυναμική δέσμευση, το πραγματικό μητρώο ΔΕΝ αγγίζεται).
      (check "⑬ πλαστό συμβόλαιο με ΑΝΥΠΑΡΚΤΗ ικανότητα ⇒ παράβαση"
             (let ((orchestrator.contracts::*contracts*
                     (copy-list orchestrator.contracts::*contracts*)))
               (orchestrator.contracts:declare-contract! "fake-fn" :function
                :capability "ανύπαρκτη-ικανότητα" :role "έλεγχος")
               (some (lambda (m) (search "fake-fn" m))
                     (orchestrator.self-model:validate-all-contracts
                      :test-exists-p #'find-command))))
      (check "⑭ πλαστό legal-critical συμβόλαιο με ΑΝΥΠΑΡΚΤΟ τεστ ⇒ παράβαση"
             (let ((orchestrator.contracts::*contracts*
                     (copy-list orchestrator.contracts::*contracts*)))
               (orchestrator.contracts:declare-contract! "fake-fn2" :function
                :capability "υπαγωγή" :role "αποδείξεις" :legal-critical t
                :policy-level :φραγή :tests '("--gate-που-δεν-υπάρχει"))
               (some (lambda (m) (search "fake-fn2" m))
                     (orchestrator.self-model:validate-all-contracts
                      :test-exists-p #'find-command))))
      (check "⑮ legal-critical με παρενέργειες ΧΩΡΙΣ audit ή rollback ⇒ παράβαση"
             (let ((orchestrator.contracts::*contracts*
                     (copy-list orchestrator.contracts::*contracts*)))
               (orchestrator.contracts:declare-contract! "fake-fn3" :function
                :capability "υπαγωγή" :role "αποδείξεις" :legal-critical t
                :policy-level :φραγή :tests '("--subsumption-gate")
                :side-effects '("γράφει στο corpus"))
               (<= 2 (count-if (lambda (m) (search "fake-fn3" m))
                               (orchestrator.self-model:validate-all-contracts
                                :test-exists-p #'find-command)))))
      ;; ⑯ Queryability: το συμβόλαιο απαντά ΧΩΡΙΣ gap report — αυτόνομο μητρώο.
      (check "⑯ queryable: contract/impact/providers/tests/policy — όλα απαντούν δομημένα"
             (let ((c (orchestrator.contracts:find-contract "subsume")))
               (and c (orchestrator.contracts:contract-capability c)
                    (orchestrator.contracts:contract-role c)
                    (orchestrator.contracts:contract-policy-level c)
                    (orchestrator.contracts:contract-tests c)
                    (orchestrator.contracts:contracts-for-capability "υπαγωγή")
                    (orchestrator.contracts:contracts-for-role "αποδείξεις"))))
      ;; ⑰ Ο αναλυτής κενών ΚΑΤΑΝΑΛΩΝΕΙ τα συμβόλαια: προφίλ «legal-drafting»
      ;;    με ≥5 απαιτούμενα συμβόλαια, κανένα ακόμη στο μητρώο, απάντηση NIL.
      (check "⑰ gap(legal-drafting): δηλωμένο προφίλ ≥5 συμβολαίων, ΟΛΑ λείπουν, τίμιο NIL"
             (let ((profile (orchestrator.contracts:find-gap-profile "legal-drafting"))
                   (sink (make-broadcast-stream)))
               (and (>= (length profile) 5)
                    (every (lambda (n) (null (orchestrator.contracts:find-contract n)))
                           profile)
                    (not (orchestrator.self-model:capability-gap-report
                          "legal-drafting" sink))))))
    (format t "~%── ΠΥΛΗ ΣΥΜΒΟΛΑΙΩΝ: ~D/~D πέρασαν ──~%" (- total (length fails)) total)
    (if fails 1 0)))

(register-command "--contract-gate" (lambda (a) (declare (ignore a)) (run-contract-gate)))

(orchestrator.self-model:declare-capability! "συμβόλαια"
 :description "δεσμευτική αυτοπεριγραφή: μητρώο συμβολαίων, επικυρωτής, κάλυψη παρόχων, θεσμική ταυτότητα"
 :package :orchestrator.contracts
 :functions '("declare-contract!" "validate-contracts" "contract-dependent-names")
 :gate "--contract-gate" :depends-on '("αυτοεπίγνωση"))

(orchestrator.contracts:defcontract "contract-registry-protocol" :protocol
 :package :orchestrator.contracts :system "orchestrator-infrastructure"
 :capability "συμβόλαια" :role "έλεγχος"
 :purpose "η πηγή αλήθειας της δεσμευτικής αυτοπεριγραφής: δήλωση, ερώτηση, επικύρωση συμβολαίων"
 :inputs '("δηλώσεις defcontract στις έδρες των πυλών")
 :outputs '("queryable μητρώο" "λίστα παραβάσεων")
 :postconditions '("συμβόλαιο με ανύπαρκτη ικανότητα/ρόλο/τεστ = παράβαση, ποτέ σιωπηλή αποδοχή")
 :legal-critical t :policy-level :φραγή
 :tests '("--contract-gate"))

(orchestrator.contracts:defcontract "mirror-protocol" :protocol
 :package :orchestrator.self-model :system "orchestrator-infrastructure"
 :capability "αυτοεπίγνωση" :role "έλεγχος"
 :purpose "ο καθρέφτης: μητρώο ικανοτήτων, αιτιώδης επίπτωση (depends-on ∪ contract dependents), τίμιος αναλυτής κενών"
 :outputs '("απογραφή --mirror" "impact report" "gap report")
 :postconditions '("ό,τι δείχνει είναι υπολογισμένο από τα ζωντανά μητρώα — ποτέ αφήγηση")
 :legal-critical t :policy-level :φραγή
 :tests '("--mirror-gate" "--contract-gate"))
