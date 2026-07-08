;;;; deployment/LAWMAX-ARCHITECTURE-CONSTITUTION.sexp
;;;; ============================================================================
;;;; ΤΟ ΑΡΧΙΤΕΚΤΟΝΙΚΟ ΣΥΝΤΑΓΜΑ — μηχανικά ελέγξιμο (--architecture-constitution-gate)
;;;; ============================================================================
;;;; Data-only (*read-eval* NIL). Κάθε αλλαγή εδώ = συνταγματική τροποποίηση:
;;;; πρόταση + τεστ + αρνητικά τεστ + rollback + ρητή έγκριση δημιουργού.
;;;; Πηγή αλήθειας των ελέγχων: τα ΖΩΝΤΑΝΑ μητρώα τη στιγμή της πύλης.

(:lawmax-architecture-constitution
 :version 1
 :authored-at-commit "85b8f7f1658d9348ede4dbd116642fcc7b9aa5dd"

 ;; ══ ΤΑ 13 PRIMITIVES — ΚΛΕΙΔΩΜΕΝΑ. Καμία νέα κορυφαία έννοια. ══
 :primitives (:self :law :authority :fact :proof :hypothesis :argument
              :matter :output-trust :evolution :institution :memory :substrate)

 ;; Κάθε ΝΕΑ ιδέα δηλώνεται υποχρεωτικά με αυτό το σχήμα ΠΡΙΝ γραφτεί κώδικας:
 :concept-declaration-template
 (:concept :__ :belongs-to (:__) :extends-existing (:__)
  :does-not-duplicate (:__) :tests (:__) :rollback :__)

 ;; ══ ΟΙ ΚΑΝΟΝΕΣ ══
 :rules
 ((:rule :no-new-top-level
   :text "Καμία νέα κορυφαία έννοια/φάκελος/σύστημα εκτός των 13 primitives και των δηλωμένων top-level directories — χωρίς συνταγματική τροποποίηση.")
  (:rule :no-duplicate
   :text "Μία έδρα ανά έννοια. Δεύτερη υλοποίηση/μητρώο/ledger για ήδη εδρευμένη έννοια = παράβαση, εκτός αν δηλωθεί εδώ με αιτιολόγηση.")
  (:rule :no-unowned-command
   :text "Κάθε εντολή CLI έχει owner-file, primitive και envelope-δήλωση σε αυτό το αρχείο. Αχαρτογράφητη εντολή = κόκκινη πύλη.")
  (:rule :no-command-without-envelope
   :text "Κάθε legal/dynamic έξοδος φέρει trust envelope ή ΡΗΤΗ εξαίρεση με λόγο.")
  (:rule :no-proposal-bypass
   :text "Κάθε υιοθέτηση γνώσης/κανόνων/αλλαγών περνά από τη ΜΙΑ μηχανή απόφασης (can-adopt/Σ11 approve). Δεύτερο μονοπάτι υιοθεσίας = παράβαση.")
  (:rule :no-bootstrap-as-learning-proof
   :text "Τα bootstrap artifacts (χειροποίητο περιεχόμενο) ΔΕΝ επικαλούνται ως απόδειξη μάθησης. Απόδειξη μάθησης = μόνο υιοθετημένοι κανόνες από failure→proposal→shadow→υπογραφή.")
  (:rule :no-llm-trusted-path
   :text "Έξοδος LLM εισέρχεται ΜΟΝΟ ως untrusted proposal μέσω data-only ingest. Ποτέ σε trusted μονοπάτι, μνήμη, κανόνα, benchmark ή οντολογία απευθείας."))

 ;; ══ CAPABILITY → PRIMITIVE (πλήρης κάλυψη — ελέγχεται αμφίδρομα) ══
 :capability-map (
  (:capability "πρόσληψη-νομολογίας" :primitive :authority)
  (:capability "ταυτότητα-άρθρων" :primitive :law)
  (:capability "αυτοεπίγνωση" :primitive :self)
  (:capability "σύμβουλος" :primitive :hypothesis)
  (:capability "διάλογος" :primitive :self)
  (:capability "δεοντικό" :primitive :law)
  (:capability "λογισμός-φραγμών" :primitive :proof)
  (:capability "συμπερασμός-wfs" :primitive :proof)
  (:capability "πυρήνας-iq" :primitive :proof)
  (:capability "ρευστή-επαγωγή" :primitive :hypothesis)
  (:capability "ιστορία-συμβάντων" :primitive :fact)
  (:capability "παραδοτέο" :primitive :output-trust)
  (:capability "γλωσσική-αντίληψη" :primitive :fact)
  (:capability "υπαγωγή" :primitive :proof)
  (:capability "αντιδικία" :primitive :argument)
  (:capability "υποθετικός-λόγος" :primitive :hypothesis)
  (:capability "δικονομικός-σχεδιασμός" :primitive :argument)
  (:capability "ομοιότητα-υποθέσεων" :primitive :authority)
  (:capability "πακέτα-γνώσης" :primitive :memory)
  (:capability "αυτοεπέκταση" :primitive :evolution)
  (:capability "πολιτικές-έγκρισης" :primitive :institution)
  (:capability "μνήμη" :primitive :memory)
  (:capability "γένεση-ελληνικών" :primitive :output-trust)
  (:capability "εκτελεστική-προέλευση" :primitive :output-trust)
  (:capability "ελεγχόμενη-αυτοεξέλιξη" :primitive :evolution)
  (:capability "συστατικά" :primitive :self)
  (:capability "συμβόλαια" :primitive :self)
  (:capability "μάθηση-κατανόησης" :primitive :evolution)
  (:capability "αρχιτεκτονική-περιφρούρηση" :primitive :substrate)
  (:capability "χρυσή-περιφρούρηση" :primitive :law)
  (:capability "εξωτερική-μαρτυρία" :primitive :hypothesis)
 )

 ;; ══ COMMAND → PRIMITIVE/OWNER/ENVELOPE (πλήρης κάλυψη — ελέγχεται αμφίδρομα) ══
 :command-map (
  (:command "--adopt-knowledge" :primitive :evolution :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--adoption-decision" :primitive :evolution :owner-file "systems/orchestrator-cli/evolution-gate.lisp" :envelope (:structured "decision:/reason: ή πλήρες δομημένο αντικείμενο"))
  (:command "--architecture-constitution-gate" :primitive :substrate :owner-file "systems/orchestrator-cli/architecture-gate.lisp" :envelope (:exception "read-only πύλη — τυπώνει ελέγχους, όχι νομική κρίση"))
  (:command "--golden-gate" :primitive :law :owner-file "systems/orchestrator-cli/golden-gate.lisp" :envelope (:exception "read-only regression ratchet — golden ≡ τρέχον αποτύπωμα, όχι νομική κρίση"))
  (:command "--advisor" :primitive :hypothesis :owner-file "systems/orchestrator-cli/advisor.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--advisor-gate" :primitive :hypothesis :owner-file "systems/orchestrator-cli/advisor.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--affected-proofs" :primitive :evolution :owner-file "systems/orchestrator-cli/evolution-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--affected-traces" :primitive :evolution :owner-file "systems/orchestrator-cli/evolution-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--agenda" :primitive :institution :owner-file "systems/orchestrator-cli/memory-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--apply-upgrade" :primitive :substrate :owner-file "systems/orchestrator-cli/ingestion-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--approve" :primitive :evolution :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--arc-eval" :primitive :hypothesis :owner-file "systems/orchestrator-cli/fluid-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--argue" :primitive :argument :owner-file "systems/orchestrator-cli/subsumption-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--ask" :primitive :output-trust :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:required "TRUST ENVELOPE σε κάθε έξοδο"))
  (:command "--auto-update" :primitive :law :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--autonomous" :primitive :institution :owner-file "systems/orchestrator-cli/autonomy-missions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--can-adopt" :primitive :evolution :owner-file "systems/orchestrator-cli/evolution-gate.lisp" :envelope (:structured "decision:/reason: ή πλήρες δομημένο αντικείμενο"))
  (:command "--capability-contracts" :primitive :self :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--case" :primitive :matter :owner-file "systems/orchestrator-cli/case-workspace.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--check-upgrades" :primitive :substrate :owner-file "systems/orchestrator-cli/ingestion-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--component" :primitive :self :owner-file "systems/orchestrator-cli/component-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--component-gate" :primitive :self :owner-file "systems/orchestrator-cli/component-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--component-of" :primitive :self :owner-file "systems/orchestrator-cli/component-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--components" :primitive :self :owner-file "systems/orchestrator-cli/component-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--constitution" :primitive :self :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--contract" :primitive :self :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--contract-gate" :primitive :self :owner-file "systems/orchestrator-cli/contract-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--contracts-missing" :primitive :self :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--deontic-gate" :primitive :law :owner-file "systems/orchestrator-cli/deontic-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--dialogue-gate" :primitive :self :owner-file "systems/orchestrator-cli/dialogue-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--discover-fek" :primitive :law :owner-file "systems/orchestrator-cli/ingestion-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--draft" :primitive :output-trust :owner-file "systems/orchestrator-cli/draft-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--draft-gate" :primitive :output-trust :owner-file "systems/orchestrator-cli/draft-commands.lisp" :envelope (:untrusted-declaration "trace-off ⇒ ρητή δήλωση untrusted στο προοίμιο"))
  (:command "--dump-pdf-text" :primitive :law :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--emit-hypergraph" :primitive :law :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--emit-proofs" :primitive :proof :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--emit-references" :primitive :law :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--emit-site" :primitive :law :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--event-gate" :primitive :fact :owner-file "systems/orchestrator-cli/event-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--evolve" :primitive :evolution :owner-file "systems/orchestrator-cli/self-extension.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--explain-decision" :primitive :authority :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--extension-gate" :primitive :evolution :owner-file "systems/orchestrator-cli/self-extension.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--failures" :primitive :memory :owner-file "systems/orchestrator-cli/understanding-learning.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--fetch-amendments" :primitive :law :owner-file "systems/orchestrator-cli/ingestion-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--fetch-decision" :primitive :authority :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--fetch-pdf" :primitive :law :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--fetch-sources" :primitive :law :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--fetch-year" :primitive :law :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--files-of" :primitive :self :owner-file "systems/orchestrator-cli/component-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--fluid-gate" :primitive :hypothesis :owner-file "systems/orchestrator-cli/fluid-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--freeze-components" :primitive :substrate :owner-file "systems/orchestrator-cli/component-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--gap" :primitive :self :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--gates" :primitive :substrate :owner-file "systems/orchestrator-cli/gates-runner.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--generation-gate" :primitive :output-trust :owner-file "systems/orchestrator-cli/generation-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--graph" :primitive :law :owner-file "systems/orchestrator-cli/graph-import.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--guard-language" :primitive :proof :owner-file "systems/orchestrator-cli/inference-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--help" :primitive :substrate :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--history" :primitive :self :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--impact" :primitive :proof :owner-file "systems/orchestrator-cli/graph-import.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--index-decisions" :primitive :authority :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--inference-gate" :primitive :proof :owner-file "systems/orchestrator-cli/inference-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--institution" :primitive :institution :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--intend" :primitive :institution :owner-file "systems/orchestrator-cli/memory-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--intentions" :primitive :institution :owner-file "systems/orchestrator-cli/memory-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--iq-gate" :primitive :proof :owner-file "systems/orchestrator-cli/iq-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--judge" :primitive :authority :owner-file "systems/orchestrator-cli/jurisprudence-judge.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--judge-profile" :primitive :authority :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--jurisprudence" :primitive :authority :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--learn-understanding" :primitive :evolution :owner-file "systems/orchestrator-cli/understanding-learning.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--self-study-night" :primitive :evolution :owner-file "systems/orchestrator-cli/understanding-learning.lisp" :envelope (:exception "Runner v1 proposal-only: κύκλος αυτομελέτης κατανόησης — ΜΟΝΟ προτάσεις στην ουρά υπογραφής, καμία υιοθέτηση/μετάλλαξη"))
  (:command "--external-benchmark-gate" :primitive :hypothesis :owner-file "systems/orchestrator-cli/external-benchmark-gate.lisp" :envelope (:exception "CPEI L11 external attestation dry-run: read-only επικύρωση σχήματος/αποτυπώματος bundle — δεν εκτελεί items, δεν εκφέρει νομική κρίση"))
  (:command "--lessons" :primitive :memory :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--list-corpora" :primitive :law :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--list-pipelines" :primitive :law :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--materialize-decisions" :primitive :authority :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--materialize-pdf" :primitive :law :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--memory" :primitive :memory :owner-file "systems/orchestrator-cli/memory-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--memory-gate" :primitive :memory :owner-file "systems/orchestrator-cli/memory-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--mirror" :primitive :self :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--mirror-gate" :primitive :self :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--policies" :primitive :institution :owner-file "systems/orchestrator-cli/approval-policy.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--policy" :primitive :institution :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--policy-approve" :primitive :institution :owner-file "systems/orchestrator-cli/approval-policy.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--policy-gate" :primitive :institution :owner-file "systems/orchestrator-cli/approval-policy.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--policy-revoke" :primitive :institution :owner-file "systems/orchestrator-cli/approval-policy.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--process-pdf" :primitive :law :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--provenance-gate" :primitive :output-trust :owner-file "systems/orchestrator-cli/provenance-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--providers" :primitive :self :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--read-provision" :primitive :law :owner-file "systems/orchestrator-cli/self-extension.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--reason" :primitive :proof :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--reason-decision" :primitive :authority :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--recall" :primitive :memory :owner-file "systems/orchestrator-cli/memory-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--reflect" :primitive :evolution :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--reject" :primitive :evolution :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--review" :primitive :institution :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--review-approve" :primitive :institution :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--review-reject" :primitive :institution :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--rollback-plan" :primitive :evolution :owner-file "systems/orchestrator-cli/evolution-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--run-all-pipelines" :primitive :law :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--run-ingestion" :primitive :law :owner-file "systems/orchestrator-cli/ingestion-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--run-pipeline" :primitive :law :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--run-tests" :primitive :substrate :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--self-evolution-gate" :primitive :evolution :owner-file "systems/orchestrator-cli/evolution-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--self-extend" :primitive :evolution :owner-file "systems/orchestrator-cli/self-extension.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--serve" :primitive :output-trust :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--serve-mcp" :primitive :output-trust :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--serve-review" :primitive :institution :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--shadow-knowledge" :primitive :evolution :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--strategy" :primitive :argument :owner-file "systems/orchestrator-cli/subsumption-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--study-code" :primitive :evolution :owner-file "systems/orchestrator-cli/self-extension.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--subsume" :primitive :proof :owner-file "systems/orchestrator-cli/subsumption-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--subsume-text" :primitive :proof :owner-file "systems/orchestrator-cli/subsumption-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--subsumption-gate" :primitive :proof :owner-file "systems/orchestrator-cli/subsumption-commands.lisp" :envelope (:untrusted-declaration "trace-off ⇒ ρητή δήλωση untrusted στο προοίμιο"))
  (:command "--symbols-of" :primitive :self :owner-file "systems/orchestrator-cli/component-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--tests" :primitive :substrate :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--think" :primitive :self :owner-file "systems/orchestrator-cli/subsumption-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--thoughts" :primitive :evolution :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--trace" :primitive :output-trust :owner-file "systems/orchestrator-cli/provenance-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--trace-capability" :primitive :output-trust :owner-file "systems/orchestrator-cli/provenance-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--trace-command" :primitive :output-trust :owner-file "systems/orchestrator-cli/provenance-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--trace-component" :primitive :output-trust :owner-file "systems/orchestrator-cli/provenance-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--trace-last" :primitive :output-trust :owner-file "systems/orchestrator-cli/provenance-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--trace-last-conclusion" :primitive :output-trust :owner-file "systems/orchestrator-cli/provenance-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--trace-legal-state" :primitive :output-trust :owner-file "systems/orchestrator-cli/provenance-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--trace-proof" :primitive :proof :owner-file "systems/orchestrator-cli/provenance-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--training-proposal" :primitive :evolution :owner-file "systems/orchestrator-cli/evolution-gate.lisp" :envelope (:structured "decision:/reason: ή πλήρες δομημένο αντικείμενο"))
  (:command "--understanding" :primitive :self :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--understanding-gate" :primitive :evolution :owner-file "systems/orchestrator-cli/understanding-learning.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--verify-all" :primitive :substrate :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--verify-all-intelligence" :primitive :substrate :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--verify-consolidation" :primitive :law :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--verify-corpus" :primitive :law :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--verify-intelligence" :primitive :substrate :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--verify-proof" :primitive :proof :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--version" :primitive :substrate :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--watch-decisions" :primitive :authority :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--watch-fek" :primitive :law :owner-file "systems/orchestrator-cli/ingestion-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--what-if" :primitive :evolution :owner-file "systems/orchestrator-cli/evolution-gate.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--why" :primitive :proof :owner-file "systems/orchestrator-cli/graph-import.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--ίδρυμα" :primitive :institution :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--αναστοχασμός" :primitive :evolution :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--αυτόνομα" :primitive :institution :owner-file "systems/orchestrator-cli/autonomy-missions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--γράφος" :primitive :law :owner-file "systems/orchestrator-cli/graph-import.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--ιστορία" :primitive :self :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--καθρέφτης" :primitive :self :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--ρώτα" :primitive :output-trust :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:required "TRUST ENVELOPE σε κάθε έξοδο"))
  (:command "--σκέψεις" :primitive :evolution :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--συμβόλαιο" :primitive :self :owner-file "systems/orchestrator-cli/self-reflection.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--σύνταγμα" :primitive :self :owner-file "systems/orchestrator-cli/decisions.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--υπαγωγή" :primitive :proof :owner-file "systems/orchestrator-cli/subsumption-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "--φάκελος" :primitive :matter :owner-file "systems/orchestrator-cli/case-workspace.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "-h" :primitive :substrate :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
  (:command "-v" :primitive :substrate :owner-file "systems/orchestrator-cli/builtin-commands.lisp" :envelope (:exception "εσωτερική/διαγνωστική/στατική αναφορά — δεν εκφέρει νομική κρίση προς τρίτο"))
 )

 ;; ══ ΚΑΝΟΝΙΚΑ STORES — ένα ανά ρόλο· άγνωστο αρχείο store = παράβαση ══
 :canonical-stores
 ((:path "deployment/self/episodes.sexp"    :role :experiential-stream)
  (:path "deployment/self/history.sexp"     :role :biography
   :note "GENESIS/bootstrap tracked αρχείο — η ΖΩΝΤΑΝΗ βιογραφία ζει στο runtime volume του δημιουργού, ποτέ σε git cleanup")
  (:path "deployment/self/proposals.sexp"   :role :proposal-queue)
  (:path "deployment/self/graph-snapshot.sexp" :role :graph-snapshot)
  (:path "deployment/state/lessons.jsonl"   :role :reflection-aggregate)
  (:path "deployment/state/failure-ledger.jsonl" :role :dialogue-failure-ledger)
  (:path "deployment/self/policies.sexp"    :role :approval-policies)
  (:path "deployment/self/candidates/"      :role :candidate-pack-staging))

 ;; ══ Η ΜΙΑ ΜΗΧΑΝΗ ΥΙΟΘΕΣΙΑΣ + η επιτρεπτή επιφάνειά της ══
 :adoption-engine (:decision "orchestrator.adoption:can-adopt"
                   :queue "orchestrator.proposals" :approval "--approve")
 :adoption-surface ("--can-adopt" "--adoption-decision" "--adopt-knowledge"
                    "--approve" "--reject" "--policy-approve" "--review-approve"
                    "--review-reject" "--policy-revoke")

 ;; ══ VERIFICATION ARTIFACTS — εξωτερικά scripts πιστοποίησης (ΟΧΙ runtime
 ;; features: καμία εντολή/έδρα/store — τρέχουν ΕΞΩ από το σύστημα, σε
 ;; αντίγραφα ή read-only). Το command-map καλύπτει ΜΟΝΟ CLI εντολές του
 ;; ζωντανού μητρώου· scripts κάτω από deployment/verify ΔΕΝ απαιτούν
 ;; command-mapping — απαιτούν δήλωση ΕΔΩ.
 ;; ══ ΠΡΩΤΟΚΟΛΛΟ Ν ΜΥΑΛΩΝ: κάθε AI-συνεργάτης δεσμεύεται εξίσου ══
 ;; (πλήρης διατύπωση: deployment/LAWMAX-CEILING-CROSSWALK.{md,sexp})
 :collaboration-protocol
 ((:r 1 "το Σύνταγμα δεσμεύει ΚΑΘΕ committer — αχαρτογράφητο = κόκκινη πύλη")
  (:r 2 "branch ανά AI· ποτέ απευθείας main· merge ΜΟΝΟ ο δημιουργός με πράσινη ολομέλεια")
  (:r 3 "μηδέν διπλός κώδικας: μητρώο + git log -S + Σύνταγμα πριν γραφτεί οτιδήποτε")
  (:r 4 "AI = συλλέκτης/προτείνων· δημιουργός = υπογράφων")
  (:r 5 "spec πριν από κώδικα: δέσιμο σε CPEI layer/primitive/πύλη/rollback")
  (:r 6 "διαφωνία μυαλών: καταγράφονται και τα δύο σκεπτικά, αποφασίζει ο δημιουργός")
  (:r 7 "κοινή γλώσσα = τα κανονικά κείμενα"))

 :verification-artifacts
 ((:script "deployment/verify/consciousness-audit/consciousness-audit-v1.ps1" :kind :external-audit)
  (:script "deployment/verify/self-understanding-audit/self-understanding-audit-v1.sh" :kind :external-audit)
  (:script "deployment/verify/blind-failure-test.sh" :kind :blind-verification)
  (:script "deployment/verify/verify.mjs" :kind :independent-proof-verifier)
  (:script "deployment/verify/verify.py"  :kind :independent-proof-verifier))

 ;; ══ BOOTSTRAP ΣΚΑΛΩΣΙΑ — ΔΕΝ μετρά ως μάθηση (rule :no-bootstrap-as-learning-proof) ══
 :bootstrap-artifacts
 ((:artifact "systems/orchestrator-cli/cognition-self.lisp" :kind :manual-frames  :marker "BOOTSTRAP")
  (:artifact "deployment/knowledge/self-glossary.sexp"      :kind :manual-lexicon :marker "BOOTSTRAP")
  (:artifact "systems/orchestrator-cli/dialogue-gate.lisp"  :kind :manual-suite   :marker "BOOTSTRAP")
  (:artifact "systems/orchestrator-cli/understanding-learning.lisp" :kind :feature-extractors :marker "bootstrap")
  (:artifact "deployment/knowledge/casegrammar-core.sexp"   :kind :manual-lexicon :marker "BOOTSTRAP"))

 ;; ══ ΔΗΛΩΜΕΝΑ ΔΙΠΛΑ (με αιτιολόγηση) — ό,τι δεν είναι εδώ και βρεθεί διπλό: παράβαση ══
 :justified-multiplicity
 ((:area :dialogue-classifiers
   :implementations ("learned-understanding" "conversation" "self" "legal"
                     "narrative-subsumption" "proof-quest" "act-horizon"
                     "understanding-floor" "general-tail")
   :why "ΕΝΑΣ dispatcher (orchestrator.cognition:decompose), διατεταγμένη αλυσίδα — όχι παράλληλες υλοποιήσεις· οι μαθημένοι κανόνες ΠΡΩΤΟΙ.")
  (:area :text-normalization
   :implementations ("orchestrator.decisions:%fold" "orchestrator.citation-authority:normalize-greek")
   :why "Διακριτοί ρόλοι: %fold = 1:1 ταύτιση ίδιου μήκους (offsets)· normalize-greek = κανονικοποίηση παραπομπών. ΧΡΕΟΣ Π3: ενιαία τεκμηρίωση ορίων χρήσης.")
  (:area :failure-memories
   :implementations ("lessons.jsonl" "failure-ledger.jsonl" "episodes.sexp")
   :why "Διακριτοί ρόλοι: aggregate αναστοχασμού / δομημένο ledger διαλόγου / βιωματικό ρεύμα. Ίδιος γονικός φάκελος state, κοινή εποπτεία στο gap-ledger-frame.")
  (:area :proposal-registries
   :implementations ("orchestrator.proposals (Σ11 γνώση)" "orchestrator.whatif (change-proposals)")
   :why "Διαφορετικά αντικείμενα: πακέτα γνώσης προς έγκριση vs first-class προτάσεις αλλαγής με what-if. Η ΑΠΟΦΑΣΗ είναι κοινή (can-adopt).")
  (:area :dialogue-surfaces
   :implementations ("--ask/--ρώτα" "/chat + /ask (--serve)" "--serve-mcp tools")
   :why "Όλες οι επιφάνειες δρομολογούν στην ΙΔΙΑ έδρα (run-ask/corpus providers) — δεδικασμένο 08a93db6: κανένας δεύτερος διάλογος.")
  (:area :article-identity
   :implementations ("source/canonical-article-id.lisp" "source/legal-id-registry.lisp" "source/canonical-uris.lisp")
   :why "ΧΡΕΟΣ Π2 (consolidation plan): τρία αρχεία στην τροχιά της ταυτότητας άρθρων — canonical-article-id = ο τύπος· registry/uris = καταναλωτές. Συγχώνευση τεκμηρίωσης εκκρεμεί· ΟΧΙ νέος κώδικας εν τω μεταξύ."))

 ;; ══ CONCEPT MAPPING — αποφασισμένες μελλοντικές έννοιες → έδρες (κανένας νέος φάκελος) ══
 :concept-mapping
 ((:concept :understanding-runner
   :belongs-to (:evolution :memory :hypothesis :proof :institution)
   :extends-existing ("understanding-learning.lisp" "autonomy-missions.lisp" "proposals")
   :does-not-duplicate ("adoption engine" "shadow evaluator") :new-folder-needed :no)
  (:concept :autodidactic-runner
   :belongs-to (:evolution :law :memory :institution)
   :extends-existing ("self-extension.lisp" "what-if" "can-adopt" "knowledge-packs")
   :does-not-duplicate ("Σ11 queue" "gates") :new-folder-needed :no)
  (:concept :code-witness
   :belongs-to (:self :proof :memory :substrate)
   :extends-existing ("component-scan" "proof-carrying" "execution-trace")
   :does-not-duplicate ("component manifest") :new-folder-needed :no)
  (:concept :nix-substrate
   :belongs-to (:substrate)
   :extends-existing ("deployment/LAWMAX-NIXOS-COGNITIVE-SUBSTRATE.md" "Dockerfile")
   :does-not-duplicate ("gates — τα flake checks τις ΤΥΛΙΓΟΥΝ") :new-folder-needed :yes-nix-dir-only)))
