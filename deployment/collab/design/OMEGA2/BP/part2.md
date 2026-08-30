---

## 2. ENGINEERING CONTRACT — migration items (9-field, phase-ordered)

Κάθε item: `CURRENT · DEFECT/GAP · TARGET INVARIANT · FILES/SYSTEMS · MIGRATION · DISCHARGE TEST ·
ROLLBACK · DEPENDENCIES · DONE WHEN`. Discharge tests είναι executable (script/fuzz/replay/lint),
ποτέ «review confirms». Phase-gated· καμία production αλλαγή χωρίς «εγκρίνω».

### PHASE B0a — Baseline & Harness Qualification (ο μηχανισμός απόδειξης πρέπει να ΜΠΟΡΕΙ να αποτύχει)

**B0a-1 · Harness falsifiability qualification**
- **CURRENT:** `deployment/verify/` (assess-gate-plenary.sh, verify-*.py, kernel-verify.lisp) +
  `authority-v2/run-proofs.sh` + `authority-v2/proofs/*` υπάρχουν, τρέχουν [A]· έχουν negative
  fixtures για gate-assessor/runtime-closure/proof-manifest/cross-language [B-claim].
- **DEFECT/GAP:** πράσινο harness ≠ ικανό harness· ορισμένοι verifiers επαληθεύουν output του
  ίδιου implementation (I-2 violation candidate — βλ. B4). Δεν έχει αποδειχθεί ότι ΚΑΘΕ critical
  gate γίνεται RED όταν πρέπει.
- **TARGET INVARIANT:** κάθε critical gate έχει ≥1 known-invalid/mutated fixture που το κάνει RED·
  το πράσινο baseline γίνεται αποδεκτό ως migration reference ΜΟΝΟ αφού αποδειχθεί falsifiable.
- **FILES/SYSTEMS:** `deployment/verify/*`, `authority-v2/proofs/*`, `authority-v2/run-proofs.sh`,
  `scripts/*verify*`, `.github/workflows/*`.
- **MIGRATION:** freeze HEAD· πλήρες proof/test inventory (κάθε gate → τι ελέγχει)· κατέγραψε
  outputs+hashes στο frozen tree· για κάθε critical gate πρόσθεσε mutated fixture· τρέξε.
- **DISCHARGE TEST:** `harness-falsifiability`: ∀ critical gate g, ∃ fixture f: g(f)=RED· και
  clean baseline: g(clean)=GREEN· αποτύπωσε τον πίνακα gate→{red-fixture, green-hash}. Ένα gate
  χωρίς red-fixture ⇒ **BLOCKED**, όχι trusted.
- **ROLLBACK:** N/A (μόνο μετρήσεις + νέα fixtures, καμία seat αλλαγή).
- **DEPENDENCIES:** καμία (πρώτο βήμα απολύτως).
- **DONE WHEN:** πίνακας gate→red-fixture πλήρης· 0 critical gates χωρίς αποδεδειγμένη ικανότητα
  αποτυχίας· frozen baseline hash καταγεγραμμένος.

### PHASE B0 — Stop unsafe authority paths (BLOCKING R-4)

**B0-1 · Fail-open constitutional gate → fail-closed**
- **CURRENT:** `source/constitutional-gate.lisp:43-47`: rule-predicate που signals error πιάνεται
  και επιστρέφει ALLOW (`(error () (values t nil))`) [V].
- **DEFECT/GAP:** σφάλμα/timeout/UNKNOWN ⇒ ΕΓΚΡΙΣΗ. Άμεση παραβίαση fail-closed.
- **TARGET INVARIANT:** predicate error/timeout/UNKNOWN ⇒ REJECT· ALLOW **unrepresentable** στο
  error path· το σφάλμα surfaces, δεν swallowed.
- **FILES/SYSTEMS:** `constitutional-gate.lisp`, `constitutional-dispatch.lisp`,
  `approval-policy.lisp`, `self-reflection.lisp`.
- **MIGRATION:** αντικατάσταση error-branch με REJECT· mediation completeness (κάθε privileged
  command → registered rule ή explicit REJECT).
- **DISCHARGE TEST:** `fail-closed-fuzz`: inject predicate που κάνει unconditional `(error)` ⇒
  decision ≠ ALLOW ∀ covered command· property test ∀ rules· CI blocks merge αν admit-path φτάνει
  ALLOW via error branch.
- **ROLLBACK:** revert του seat (μικρό, τοπικό)· baseline hash του B0a επιστρέφει.
- **DEPENDENCIES:** B0a (χρειάζεται qualified harness για να αποδειχθεί το bypass με red test).
- **DONE WHEN:** `fail-closed-fuzz` GREEN (δηλ. ΚΑΝΕΝΑ ALLOW-on-error)· η red-fixture του bypass
  (που περνούσε) τώρα RED→FIXED.

**B0-2 · emit-graph scope fail-open → mandatory issued authority context**
- **CURRENT:** `source/write-authority.lisp:emit-graph` απαιτεί `:authority` (17-21) αλλά ελέγχει
  scope ΜΟΝΟ `(when *current-write-authority* …)` (23) [V]· γυμνή κλήση ⇒ scope NIL ⇒ γράφει.
- **DEFECT/GAP:** fail-open ως προς authority scope· keyword `:canonical` ως token είναι forgeable.
- **TARGET INVARIANT:** καμία εγγραφή χωρίς unforgeable/issued execution-context ή capability
  object, policy-checked + audit-linked· απουσία context ⇒ REJECT (I-3).
- **FILES/SYSTEMS:** `write-authority.lisp`, callers (`ingestion-daemon.lisp:30`,
  `ai-citation-strategy`, `legal-audit-system`, `consolidate.lisp`, FRBR generators).
- **MIGRATION:** αντικατάσταση `when` με mandatory-context guard· εισαγωγή capability object
  (issued, checked, logged) αντί keyword.
- **DISCHARGE TEST:** `emit-guard`: γυμνή `emit-graph` χωρίς issued context ⇒ 0 bytes, REJECT·
  ∀ call-site περνά μέσα από issued context· forged token ⇒ REJECT.
- **ROLLBACK:** revert seat· callers επανέρχονται στο προηγούμενο (καταγεγραμμένο) API.
- **DEPENDENCIES:** B0a.
- **DONE WHEN:** `emit-guard` GREEN· 0 write paths με NIL-scope bypass.

### PHASE B1 — Publication + Information Security Boundary (πριν το split, πριν κάθε external provider)

**B1-1 · Typed Publication Gateway (G-pub)**
- **CURRENT:** ο `ingestion-daemon` περνά consolidated.txt/.ttl/.akn.xml/corpus.jsonl/catalog.jsonld
  όλα από τον ίδιο `EMIT-GRAPH` με `:authority :provenance` [V:43-51]· «wall» = μόνο structural
  read-partition [A].
- **DEFECT/GAP:** καμία classification/DLP/privilege-review/human-approval στο egress· ένας code
  path για canonical + provenance + derived + public.
- **TARGET INVARIANT (I-6):** `artifact → classification → provenance → publication-policy →
  approval → sink`· fail-closed (ABSTAIN≡FAIL)· separate code paths· immutable release receipt·
  data classes {PUBLIC, INTERNAL, CLIENT_CONFIDENTIAL, PRIVILEGED, WORK_PRODUCT, RESTRICTED}.
- **FILES/SYSTEMS:** NEW `watchtower-practice/publication-gateway/`· `ingestion-daemon.lisp`,
  `write-authority.lisp`, `legal-authority-receipt.lisp`.
- **MIGRATION:** εισαγωγή artifact classifier + policy engine + human-approval seat + receipt·
  τα 5 emit αντικείμενα ταξινομούνται· μόνο PUBLIC-by-nature φτάνει σε public sink.
- **DISCHARGE TEST:** `publication-canary`: seed sensitive canary σε pre-pub ⇒ BLOCK·
  stego/paraphrastic red-team miss-rate μετρημένο· redaction verified by independent re-detection
  των exact release bytes· 2 distinct non-self approvals ή καμία R4-write capability.
- **ROLLBACK:** G-pub bypass flag OFF ⇒ επιστροφή σε read-partition (μόνο σε emergency, logged).
- **DEPENDENCIES:** B0-1, B0-2.
- **DONE WHEN:** κανένα artifact egress χωρίς πλήρη conjunction· canary+stego tests GREEN.

**B1-2 · Matter isolation + ethical walls + egress policy (G-inf)**
- **CURRENT:** capability primitives (immutable contracts, :trusted/:advisor, frozen taxonomy,
  ownership-collision, fail-closed registration) [B-claim, ανα-επαλήθευση Reviewer-B]· κανένα
  matter/tenant/privilege model [A].
- **DEFECT/GAP:** external provider = απλό adapter call· καμία tenant/matter/client/privilege
  ετικέτα· shared state cross-matter δυνατό.
- **TARGET INVARIANT (I-6):** κάθε request φέρει
  `{tenant_id, matter_id, client_id, ethical_wall, confidentiality_class, privilege_status,
  work_product_status, egress_policy}`· PRIVILEGED/RESTRICTED ⇒ **no external egress** (structural:
  external backend capability απών από το routing table)· isolation = absence of handle, όχι WHERE.
- **FILES/SYSTEMS:** NEW `watchtower-practice/matter-isolation/`, `.../egress-gateway/`·
  `inference-gate.lisp`, `memory.lisp` (partition), capability seats.
- **MIGRATION:** per-matter compartments (DEK/matter)· grant algebra monotone/non-transitive·
  egress gateway ως μόνο path σε provider· classify-then-route.
- **DISCHARGE TEST:** `cross-matter-read`: από session matter M, read matter M' κάθε API ⇒ DENY,
  0 bytes· `egress-privileged`: PRIVILEGED payload στο external wire ⇒ 0 bytes, matter labels
  stripped· `route-audit`: privileged classes NO external route.
- **ROLLBACK:** provider adapters disabled (χωρίς isolation, κανένα external call επιτρέπεται —
  fail-closed default).
- **DEPENDENCIES:** B0· (πριν ΟΠΟΙΟΝΔΗΠΟΤΕ external provider — αδιαπραγμάτευτο).
- **DONE WHEN:** cross-matter + egress + route tests GREEN· default privileged = no-egress αποδεδειγμένο.

### PHASE B2 — Temporal Single Authority (I-7)

**B2-1 · version-graph = sole legal temporal authority· consolidation → consumer/replay**
- **CURRENT:** in-force queries σερβίρονται από `consolidation-engine.lisp:406-415` με lexical
  `string</string>` πάνω σε effective-only order· `recorded` (bitemporal) ποτέ δεν διαβάζεται από
  query· `:if-missing :skip` ρίχνει σιωπηλά amendments [V/A]· το αυστηρό `version-graph` είναι DARK.
- **DEFECT/GAP:** duplicated temporal authority (δύο ενεργά μονοπάτια αποφασίζουν «τι ίσχυε τότε»).
  (Σημ.: το lexical ordering σε canonical validated ISO dates ΔΕΝ είναι μαθηματικά λάθος — το
  πρόβλημα είναι η διπλή αρχή, όχι η σύγκριση.)
- **TARGET INVARIANT (I-7):** ΜΟΝΟ το `version-graph` αποφασίζει legal temporal state·
  consolidation = deterministic renderer/replay ενός resolved snapshot· ΜΙΑ `%time-key`· καμία
  lexical date σύγκριση σε in-force path· malformed effective ⇒ error, ποτέ silent mis-order·
  `:if-missing` ⇒ surfaced review event, ποτέ silent skip.
- **FILES/SYSTEMS:** `version-graph.lisp` (authority), `consolidation-engine.lisp` (→renderer),
  `consolidation-proof.lisp`, ~16 serving seats που καλούν consolidation.
- **MIGRATION:** route in-force queries μέσα από version-graph· demote consolidation· extend
  version-graph με `:renumber/:split/:merge/:delete` replay semantics (Greek recodifications).
- **DISCHARGE TEST:** `single-date-order`: grep+property — 0 lexical date comparisons σε in-force
  path· `inforce-through-vg`: κάθε in-force query resolves μέσω version-graph· `recodification-replay`:
  renumber/split/merge replays σε exact hashes· `no-silent-skip`: missing amendment ⇒ review event.
- **ROLLBACK:** feature-flag «temporal-authority=consolidation» (legacy) — μόνο για διαφορικό test,
  όχι production· shadow diff πρώτα (I-10).
- **DEPENDENCIES:** B0a, B0.
- **DONE WHEN:** 0 δεύτερα temporal paths· shadow diff version-graph vs legacy = 0 divergence σε
  golden corpus· recodification replay GREEN.

### PHASE B3 — Architectural Boundary Enforcement (I-8, machine-enforced)

**B3-1 · ASDF DAG + exports + `::`-lint + dynamic-access lint + dependency proof**
- **CURRENT:** `orchestrator-infrastructure.asd` φορτώνει 132 files [V]· `orchestrator-core-runtime`
  εξαρτάται και από τα 10 systems [V]· cross-package `::` σε ≥9 packages [V]· dynamic wiring με
  `find-symbol/fdefinition` σε `ingestion-daemon` (30,43,45,47,49,51,66,84,94,96) [V].
- **DEFECT/GAP:** ASDF split ΜΟΝΟ του δεν επιβάλλει boundaries· το God System είναι stringly-wired,
  αόρατο σε ASDF και σε `::`-grep.
- **TARGET INVARIANT (I-8):** dependency DAG κατεύθυνσης-κάτω· package export contract· CI lint που
  απορρίπτει (α) `other.pkg::private`, (β) `FIND-SYMBOL/INTERN/FDEFINITION/SYMBOL-CALL` cross-domain·
  machine-generated dependency graph = source of truth.
- **FILES/SYSTEMS:** όλα τα `.asd`· `ingestion-daemon.lisp` (rewire σε typed calls)· NEW
  `deployment/verify/boundary-lint.lisp`.
- **MIGRATION:** ορισμός domain DAG· conversion dynamic lookups σε explicit `:depends-on` + exported
  API· boundary-lint στο CI.
- **DISCHARGE TEST:** `boundary-lint`: 0 cross-domain `::`· 0 cross-domain dynamic symbol resolution·
  `dag-acyclic`: dependency graph acyclic + κατεύθυνση σωστή· `system-load` clean.
- **ROLLBACK:** lint σε warn-mode (μεταβατικά)· δεν επιτρέπεται production merge σε warn-mode πέρα
  από τη μεταβατική φάση.
- **DEPENDENCIES:** B2 (temporal wiring πρώτα, ώστε το rewire να μη «κλειδώσει» τη διπλή αρχή).
- **DONE WHEN:** boundary-lint GREEN στο CI· 0 dynamic cross-domain calls· DAG αποδεδειγμένα acyclic.

### PHASE B4 — Verifier Independence Audit (I-2)

**B4-1 · Αντικατάσταση/ανεξαρτητοποίηση μη-ανεξάρτητων verifiers**
- **CURRENT (verified defects):**
  (a) `consolidation-proof.lisp:113 verify-consolidation-ledger` καλεί `build-consolidation-ledger`
  (ίδιος κώδικας) και συγκρίνει base+result hash + **step COUNT**· τα per-step before/after hashes
  αποθηκεύονται (`step->plist`) αλλά **ποτέ δεν συγκρίνονται** [V] → τυφλό σε tampered ενδιάμεσο.
  (b) `narrative-provenance.lisp:verify-provenance-chain` ελέγχει μόνο non-empty lists + start<end,
  κανένα hash· κενό narrative ⇒ `(every #'cdr NIL)=T` ⇒ "verified" [V].
  (c) `authority-v2/proofs/witness-quorum-test.py` ορίζει `evaluate_quorum` in-test, imports μόνο
  `sys`, μηδενική σύζευξη με deployed seat [V:15,52].
- **DEFECT/GAP:** verifiers που αποδεικνύουν είτε τον εαυτό τους (a,c) είτε τίποτα (b) — I-2.
- **TARGET INVARIANT (I-2):** κάθε critical verifier έχει independent/differential implementation ή
  adversarial fixture· κανένα πράσινο gate δεν γίνεται migration evidence αν αποδεικνύει μόνο εαυτό.
- **FILES/SYSTEMS:** (a) `consolidation-proof.lisp` (b) `narrative-provenance.lisp`
  (c) `witness-quorum-test.py`· + οποιοσδήποτε gate έμεινε χωρίς red-fixture στο B0a.
- **MIGRATION:** (a) πραγματικός op-by-op replay που ΣΥΓΚΡΙΝΕΙ per-step before/after hashes,
  independent από `consolidate`· (b) hash-chain ή rename· (c) delete ή test πραγματικού deployed
  quorum seat.
- **DISCHARGE TEST:** ανά verifier `mutation-witness`: tampered per-step / empty narrative / forged
  quorum ⇒ REJECT· positive witness: clean ⇒ PASS.
- **ROLLBACK:** παλιός verifier παραμένει σε shadow (reporting-only) μέχρι ο νέος να περάσει.
- **DEPENDENCIES:** B0a (πίνακας gate→red-fixture ορίζει το scope).
- **DONE WHEN:** τα 3 verified fixtures RED-when-should· 0 critical gates «self-proving».

### PHASE B5 — Epistemic / Claim Contract (I-4, I-5)

**B5-1 · First-class Claim + A/F anti-laundering + dependency/lifecycle**
- **CURRENT:** self-model `meta-ontology.lisp` αγκυρωμένο με `doesNotResolveConflicts=true` (122/167),
  `doesNotSelectInterpretation=true` (129/168), `nonNormativeNature=true` (91/163),
  `doesNotModelIntent` (136), δεμένα στο `system-commit-hash` (12/24/33) [V] — αντιφάσκει με 25
  `legal-*` reasoners· κανένα ενιαίο claim layer.
- **DEFECT/GAP:** (i) το σφραγισμένο self-model αρνείται την αποστολή & αποκλείει multi-world·
  (ii) κανένα typed claim με epistemic class + dependencies + provenance.
- **TARGET INVARIANT (I-4/I-5/CC-1):** κάθε σοβαρό result = first-class Claim με την πεντάδα του
  Claim Contract· κανένας άξονας δεν αναβαθμίζει άλλον· κανένα derived conclusion χωρίς
  evidence/dependency state· self-model τυποποιεί conflict/DISPUTED ως first-class.
- **FILES/SYSTEMS:** `meta-ontology.lisp` (REPLACE self-model axioms + recompute commit hash),
  `legal-conflict-resolution.lisp`, NEW `watchtower-twin/claim-graph/`, `.../dependency-graph/`.
- **MIGRATION:** νέο Claim schema· re-seat ontology ως multi-world· cross-check axioms↔reasoners.
- **DISCHARGE TEST:** `no-laundering`: model vote/confidence/repeat δεν αλλάζει epistemic_class
  (property test)· `self-model-consistency`: ontology types conflict/DISPUTED & axioms δεν
  αντιφάσκουν με shipped `legal-*` (automated cross-check)· `claim-requires-evidence`: claim χωρίς
  dependency/evidence ⇒ REJECT.
- **ROLLBACK:** νέο claim layer σε shadow (γράφει claims παράλληλα, δεν σερβίρει) μέχρι πλήρες.
- **DEPENDENCIES:** B2 (temporal authority), B4 (trusted verifiers).
- **DONE WHEN:** no-laundering + self-model-consistency GREEN· κάθε νέο derived output είναι Claim.

### PHASE B6 — Runtime decomposition (μόνο τώρα σπάει το God System)

**B6-1 · orchestrator-infrastructure (132 files) → domain systems**
- **CURRENT:** infrastructure = God System [V]· `core-runtime` → 10 systems [V]· omega δηλώνει
  "DARPA-class"/v1.3/FRBR ιστορική ορολογία [A]· πολλαπλές γενιές v1.0/1.2/1.3, ORCHESTRATORSUPER
  στο dependency contract [A].
- **DEFECT/GAP:** αλλαγή σε ένα engine ρισκάρει όλη την εικόνα· semantic debt.
- **TARGET INVARIANT (I-8):** 11 watchtower-* domain systems με enforced DAG· ένα version contract·
  omega παύει να είναι architecture universe (χρήσιμα FRBR/serialization → σωστό domain)·
  self-model/cognition/autonomy → governance/control-plane sandbox (έξω από trusted runtime).
- **FILES/SYSTEMS:** όλα τα `.asd`, `orchestrator-omega`, `autonomy.lisp` (→governance),
  `self-model`/`cognition`.
- **MIGRATION:** move-not-rewrite ανά domain· κάθε move behind boundary-lint (B3)· semantics
  αμετάβλητα στο βήμα αυτό (καθαρή αναδιάταξη).
- **DISCHARGE TEST:** `behavior-invariance`: full regression + golden replay = identical outputs
  προ/μετά split (καμία semantic αλλαγή)· `boundary-lint` παραμένει GREEN· `system-load` clean.
- **ROLLBACK:** git revert του move commit (καθαρά structural, χωρίς semantic entanglement).
- **DEPENDENCIES:** B3 (enforcement), B4 (trusted tests για invariance).
- **DONE WHEN:** 0 files στο God System· behavior-invariance GREEN· ένα version contract.

---

## 3. DOWNSTREAM BUILD (μετά τα B, στην target chain — κάθε ένα NEW system, shadow-first I-10)

| Item | Στάδιο | Κύριο TARGET INVARIANT | Κύριο DISCHARGE TEST | DEPENDS |
|---|---|---|---|---|
| D1 Normative IR | 5 | typed normative AST (norm/scope/operator OBLIG-PROHIB-PERMIT-POWER-IMMUNITY/defeaters/rank/provenance)· extraction admission μόνο μετά schema+source-align+symbolic-validate+review (I-1) | `ir-admission`: LLM extraction χωρίς source-alignment ⇒ REJECT· round-trip IR→text diff | B5 |
| D2 Claim/Dependency Graph | 7 | κάθε conclusion → node με deps/provenance/epistemic (I-5)· `P:v7 superseded ⇒ affected set STALE` | `impact-stale`: supersede provision ⇒ όλα τα dependents STALE, 0 tυφλά | D1 |
| D3 Continuous Impact & Invalidation | 8 | αυτόματο invalidation/recompute σε κάθε source change | `auto-invalidate`: injected amendment ⇒ recompute-required στα σωστά nodes | D2 |
| D4 Normative Change Simulator (legislative what-if) | 9 | ephemeral branch· apply proposed act· recompute· impact report· ΧΩΡΙΣ μόλυνση production graph | `ephemeral-isolation`: sim δεν αγγίζει production hashes· impact report reproducible | D3 |
| D5 Source Mesh | 1 | κοινό adapter protocol DISCOVER/FETCH/SNAPSHOT/VERIFY/PARSE/NORMALIZE/IDENTIFY/DIFF/EMIT· immutable raw evidence ΠΡΙΝ parsing· source→capture→receipt→hash→parse | `evidence-before-parse`: κανένα parsed legal fact χωρίς προηγούμενο immutable capture+receipt | B1,B2 |
| D6 Adversarial Intelligence Plane | 10 | model registry + roles (extractor/researcher/counsel±/critic/citation-checker/synthesizer)· AI ΜΟΝΟ proposal (I-1)· provider call = policy decision (I-6)· model IDs όχι hardcoded | `ai-no-authority`: AI output δεν γίνεται authoritative state χωρίς symbolic+human gate· `provider-policy`: call χωρίς egress-policy ⇒ DENY | B1,D2 |
| D7 Practice/Matter Plane (deadlines full) | 11 | deadline kernel + εργάσιμες/διακοπές/ΚΠολΔ calendars/suspension/service/e-filing/timezone· conflicts· evidence lifecycle | `deadline-corpus`: golden ελληνικές προθεσμίες (αργίες/Αύγουστος/ένδικα μέσα) exact· dual-engine agree | B1,D2 |
| D8 Proof-Carrying Outputs (Legal Reasoning Proof Bundle) | 12 | claim→facts→norms→versions→valid/known-time→scope→derivation→defeaters→conflicting authority→evidence→source proofs→engine/rulepack version→epistemic· authenticity≠legal-conclusion | `bundle-complete`: output χωρίς πλήρες bundle ⇒ όχι trusted· independent re-verify | D2,D6 |
| D9 Attestation/Federation | 13 | independent witnesses· verifier federation· (workload attestation όπου έχει αξία) | `independent-repro`: δεύτερο party ξαναχτίζει checker + re-verifies bundle corpus· divergence=fail | D8 |
| D10 Continuous Legal Evaluation | (cross) | historical replay corpus + golden legal cases + auto re-eval σε κάθε change· νέα CI class gates (source-fidelity/temporal/normative-compilation/historical-replay/legal-regression/impact/claim-provenance/AI-evidence/adversarial/model-drift) | `legal-regression`: κάθε change re-runs golden cases· regression ⇒ block | D2,D8 |
