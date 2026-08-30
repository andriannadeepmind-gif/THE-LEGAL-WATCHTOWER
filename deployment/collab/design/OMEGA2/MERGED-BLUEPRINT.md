# MERGED-BLUEPRINT — THE-LEGAL-WATCHTOWER → Verifiable Legal Digital Twin

**Nature (τριπλή, δεσμευτική):** (1) TARGET ARCHITECTURE — το πλήρες σχέδιο του τελικού νέου
THE-LEGAL-WATCHTOWER· (2) MIGRATION MAP — η ακριβής μετάβαση από το σημερινό repo (baseline
`e621dbe1`, working tree +`deployment/collab/fresh-phase-2-launch/` EXTRA) στο target·
(3) ENGINEERING CONTRACT — σειρά υλοποίησης + executable tests που αποδεικνύουν κάθε βήμα.
**Συντάκτης:** Reviewer-A (Claude). **Προς review item-by-item από:** Reviewer-B (co-reviewer),
με ετυμηγορία `ACCEPT / MODIFY / REJECT / MISSING` ανά item, πριν αγγιχτεί έστω μία γραμμή.
**Κανόνας αποδείξεων (κοινός, συμφωνημένος):** κανένα «υπάρχει/λείπει/ασφαλές/broken» δεν είναι
accepted fact χωρίς executable evidence ή path/symbol/failure-case. Ό,τι στο παρόν φέρει
`[V]` έχει επαληθευτεί σε αυτό το session με path+γραμμή· ό,τι φέρει `[A]` προέρχεται από τα
base-audit πορίσματα και οφείλει να ανα-επαληθευτεί από τον Reviewer-B· ό,τι φέρει `[D]` είναι
design decision προς κρίση.
**Governance:** ΚΑΜΙΑ αλλαγή production κώδικα χωρίς ρητό «εγκρίνω <phase>» του δημιουργού ανά
φάση. Commit identity: `Stavropoulos Law® <info@stavropouloslaw.com>`, no AI trailer,
restore `deployment/self/history.sexp` + `output/.healthy` προ commit.
**Evidence base:** OMEGA2/{repo-paths, base-audit-1..6, BASE-VERDICT, autopsy, tournament,
CANON-OMEGA2-ARCHITECTURE, DELIVERABLE-6, DELIVERABLE-7} + dialogue evidence pack (Reviewer-A↔B).

---

## 0. ΟΙ 10 ΑΔΙΑΠΡΑΓΜΑΤΕΥΤΟΙ ARCHITECTURAL INVARIANTS (I-1..I-10)

1. **I-1** Κανένα LLM δεν αποτελεί trust root.
2. **I-2** Κανένας verifier δεν θεωρείται αξιόπιστος επειδή επαληθεύει output του ίδιου implementation.
3. **I-3** Κανένα subsystem δεν αποκτά implicit authority.
4. **I-4** Κανένα confidence score δεν μετατρέπει interpretation σε fact.
5. **I-5** Κανένα derived legal conclusion δεν υπάρχει χωρίς evidence/dependency state.
6. **I-6** Κανένα external AI/provider call δεν παρακάμπτει matter/privilege/egress policy.
7. **I-7** Κανένα production path δεν αποφασίζει legal temporal state έξω από τη μοναδική canonical temporal authority.
8. **I-8** Architecture boundaries machine-enforced (ASDF DAG + package exports + `::`-lint + dynamic-access lint `FIND-SYMBOL/INTERN/FDEFINITION/SYMBOL-CALL` + CI dependency proof) — όχι diagrams.
9. **I-9** Κάθε migration phase έχει executable discharge condition.
10. **I-10** Κάθε νέα μηχανή μπαίνει, όπου εφικτό, πρώτα σε shadow/differential mode απέναντι στην προηγούμενη.

## 0.1 CLAIM CONTRACT (κοινό, συμφωνημένο)

Κάθε derived αντικείμενο φέρει την πεντάδα:
`{epistemic_class, confidence_within_class, A-level (derivation assurance), F-level (formalization fidelity), coverage_stamp}`
- `epistemic_class ∈ {AUTHORITATIVE_TEXT, VERIFIED_OBSERVATION, DETERMINISTIC_DERIVATION,
  LEGAL_INTERPRETATION, DISPUTED_INTERPRETATION, PREDICTION, UNKNOWN}` + lifecycle
  `{STALE, SUPERSEDED, REJECTED}`.
- **Invariant CC-1 (I-4 operationalized):** κανένα confidence, model vote ή repeated inference
  δεν αναβαθμίζει `epistemic_class`· κανένας άξονας της πεντάδας δεν αναβαθμίζει άλλον·
  A-level ποτέ δεν αναβαθμίζει F-level. `INTERPRETATION 0.999` παραμένει interpretation.
- F-ceiling: substantive-law fidelity ≤ F3 (EMPIRICAL, expert-attested, dated) — ποτέ THEOREM.

## 0.2 ΟΙ 4 ΑΞΟΝΕΣ ΩΡΙΜΟΤΗΤΑΣ (ανά subsystem, παντού στο παρόν)

`kernel maturity` (η μηχανή σωστή ως μηχανή) · `semantic coverage` (πόσο δίκαιο/ύλη
μοντελοποιεί) · `operational maturity` (τρέχει στη γραμμή παραγωγής;) · `production assurance`
(αποδείξεις/fixtures/fail-closed). Κλίμακα: `ABSENT / SEED / PARTIAL / HIGH`.

---

## 1. TARGET ARCHITECTURE — η 13-βάθμια αλυσίδα ως benchmark

Νέα ASDF domain systems (dependency DAG, κατεύθυνση ΜΟΝΟ προς τα κάτω):
`watchtower-intelligence → watchtower-twin → watchtower-case → watchtower-normative →
watchtower-temporal → watchtower-canonical → watchtower-kernel`, με πλάγια:
`watchtower-acquisition` (→canonical), `watchtower-practice` (→case/temporal),
`watchtower-governance`, `watchtower-api` (projections only), `watchtower-observability`.
Το kernel ΔΕΝ γνωρίζει ότι υπάρχει LLM (I-1, I-8).

| # | Στάδιο αλυσίδας | Target system | Σήμερα (verified state) | Ωριμότητα σήμερα (K/S/O/P) |
|---|---|---|---|---|
| 1 | Authoritative Source Mesh | watchtower-acquisition | `ingestion-daemon.lisp` skeleton + `government-source.lisp` (Diavgeia/ΦΕΚ paths, SSRF guard) [V]· κανάλια αρρύθμιστα, stringly-wired μέσω `find-symbol` [V:30-97] | PARTIAL/SEED/ABSENT/ABSENT |
| 2 | Immutable Evidence Layer | watchtower-kernel | `journal.lisp` (single-writer, compare-and-append) + `merkle-authority.lisp` (RFC-6962) + `timestamp/jws/receipt` ισχυρά [A]· ΑΛΛΑ corpus γράφεται από `write-authority:emit-graph` με `:supersede`, εκτός σπονδυλικής στήλης, scope check `when *current-write-authority*` fail-open [V] | HIGH/—/PARTIAL/**λάθος αντικείμενο** |
| 3 | Canonical Identity / Structural Model | watchtower-canonical | `legal-identity.lisp`, `legal-ast.lisp`, references [V exist] | PARTIAL/PARTIAL/PARTIAL/SEED |
| 4 | Single Bitemporal Legal State | watchtower-temporal | `version-graph.lisp`: bitemporal πεδία recorded-from/until 46/48 refs, quarantine 28, retract 34, regime 65, anchors 47 [V] — ΕΚΤΟΣ load path· διπλή temporal αρχή στο `consolidation-engine.lisp` (δικά του effective/enacted/recorded + as-of στο 406-415) [V] | HIGH/PARTIAL/**DARK**/PARTIAL |
| 5 | Normative IR | watchtower-normative (NEW seat) | ΔΕΝ υπάρχει· μόνο document-AST | ABSENT |
| 6 | Executable Normative System | watchtower-normative | `legal-inference-engine.lisp`: JTMS 69, WFS 16, alternating fixpoint, :when/:unless/:where, unification [V]· `legal-event-calculus.lisp` 64 γραμμές δηλωτικός EC (θεμελίωση/διακοπή/αδράνεια) [V]· deontic/conflicts/precedent seats [V exist] | HIGH/SEED/LOW/LOW |
| 7 | Claim / Dependency / Epistemic Graph | watchtower-twin (NEW) | ΔΕΝ υπάρχει ενιαίο layer· provenance seats μοντελοποιούν build-pipeline όχι legal provenance [A] | ABSENT |
| 8 | Continuous Impact & Invalidation | watchtower-twin (NEW) | primitive: JTMS retraction [V]· καμία firm-wide διάδοση | SEED/ABSENT/ABSENT/ABSENT |
| 9 | Counterfactual Legal Digital Twin | watchtower-twin | `legal-counterfactual.lisp` (case-facts) + `what-if` (self-change) [V exist]· legislative what-if ΔΕΝ υπάρχει | SEED/SEED/ABSENT/ABSENT |
| 10 | Adversarial Intelligence Plane | watchtower-intelligence (NEW) | `orchestrator-ai-core` = manifests/citation/feeds, ΟΧΙ cognition [A]· `legal-dialectic.lisp` deterministic ground layer [V exists]· `legal-qa` «never generated» [V:3] | SEED/—/ABSENT/ABSENT |
| 11 | Practice / Matter / Privilege Plane | watchtower-practice (NEW) | deadline kernel-seed στο `legal-strategy.lisp` (:deadline-days/:deadline-from/%deadline-check/date-plus-days) [V:26-62] present-but-insufficient· capability primitives (:trusted/:advisor, fail-closed registration) [B-claim, να ανα-επαληθευτεί]· matter isolation / walls / data classes ΔΕΝ υπάρχουν | SEED/SEED/ABSENT/ABSENT |
| 12 | Proof-Carrying Outputs | watchtower-kernel + normative | `proof-carrying.lisp` (authenticity) + `authority-proof-bundle.lisp` (trust chain, tiers, witnesses) [V exist]· Legal Reasoning Proof Bundle ΔΕΝ υπάρχει· διάκριση authenticity≠legal-conclusion δεσμευτική | PARTIAL/—/PARTIAL/PARTIAL |
| 13 | Independent Attestation / Federation | watchtower-governance | TSA/witness primitives [A]· `witness-quorum-test.py` τεστ-παιχνίδι (evaluate_quorum ορίζεται in-test, imports: sys) [V:15,52]· federation ΔΕΝ υπάρχει | SEED/—/ABSENT/ABSENT |

**Δύο πραγματικότητες (δεσμευτικό):** Canonical Reality (sources, documents, versions, events,
authorities, decisions, dates) ↔ Derived Reality (norms, claims, interpretations, conflicts,
obligations, impacts, predictions, strategies). Μετάβαση ΜΟΝΟ μέσω proof/provenance edge —
κανένα implicit jump (I-5). RDF/SPARQL/JSON-LD/Akoma-Ntoso/hypergraph = **projections**, ποτέ
source of truth. Embeddings/vector = retrieval accelerator, ποτέ authority.
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
---

## 4. DISPOSITION TABLE — απόφαση ανά σημαντικό seat (KEEP/MOVE/REFACTOR/MERGE/REPLACE/RETIRE/NEW)

Paths verified on disk (repo-paths + base-audit + dialogue evidence). «MOVE» = αλλάζει domain
system χωρίς semantic αλλαγή· «REFACTOR» = αλλάζει συμπεριφορά στο ίδιο concept· «REPLACE» = το
concept μένει, η υλοποίηση αντικαθίσταται· «RETIRE» = το concept πεθαίνει με death-record.

| Seat (verified path) | Απόφαση | Target system | Phase |
|---|---|---|---|
| `source/version-graph.lisp` | KEEP + REFACTOR (extend: renumber/split/merge/delete· multi-world typing) → **sole temporal authority** | watchtower-temporal | B2, B5 |
| `source/consolidation-engine.lisp` | REFACTOR (demote σε renderer/replay consumer· τέλος δικής του temporal απόφασης) | watchtower-temporal | B2 |
| `source/consolidation-proof.lisp` | REFACTOR (per-step hash compare + independent replayer) | watchtower-temporal | B4 |
| `source/journal.lisp` | KEEP + UPGRADE (fsync-directory στο genesis append· external anchor στο write path) | watchtower-kernel | B0/B4 |
| `source/self-history.lisp` | KEEP + UPGRADE (canon-sexp hashing αντί naive join) | watchtower-kernel | B4 |
| `source/merkle-authority.lisp` | KEEP | watchtower-kernel | — |
| `source/timestamp-authority.lisp`, `jws-authority.lisp`, `legal-authority-receipt.lisp` | KEEP | watchtower-kernel | — |
| `source/blockchain-authority.lisp`, `archive-authority.lisp` | KEEP (OPTIONAL witnesses, όχι trust root) | watchtower-kernel | — |
| `source/safe-read.lisp` | KEEP (trusted serialization boundary) | watchtower-kernel | — |
| `source/write-authority.lisp` (`emit-graph` defun) | REFACTOR (issued-context guard) και MOVE πίσω από G-pub | watchtower-kernel + practice | B0-2, B1-1 |
| `source/validation-authority.lisp` | REFACTOR (πραγματικό RDF/Turtle parse αντί substring contract) | watchtower-canonical | B4 |
| `authority-v2/kernel/admission-model.sexp` | REPLACE-as-spec → BUILD executable decider (σήμερα :specification-only, 0/9, ποτέ loaded) | watchtower-kernel | B0/B6 |
| `source/constitutional-gate.lisp` | REFACTOR (fail-closed) | watchtower-kernel | **B0-1** |
| `systems/orchestrator-cli/constitutional-dispatch.lisp` | REFACTOR (mediation completeness) | watchtower-kernel | B0-1 |
| `source/ast-gate.lisp` | KEEP (bus checker) | watchtower-kernel | — |
| 17× `systems/orchestrator-cli/*-gate.lisp` | AUDIT → REFACTOR σε typed bus checkers· RETIRE όσα διπλασιάζουν concept (κατά B0a inventory) | watchtower-kernel/governance | B0a, B4 |
| `systems/orchestrator-cli/inference-gate.lisp` | REFACTOR (per-data-class posture) → G-inf | watchtower-practice | B1-2 |
| `source/legal-inference-engine.lisp` (JTMS/WFS) | KEEP (normative reasoning kernel· LLM υπηρετεί αυτήν, όχι αντίστροφα) | watchtower-normative | — |
| `source/legal-event-calculus.lisp` | KEEP + EXTEND (event ontology: publication/enactment/commencement/amendment/repeal/interpretation/correction) | watchtower-normative | D1+ |
| `source/legal-deontic.lisp`, `legal-conflict-resolution.lisp`, `legal-precedent.lisp` | KEEP (specialist engines)· conflict-resolution + multi-world edges | watchtower-normative | B5 |
| `source/legal-dialectic.lisp` | KEEP (deterministic ground layer· multi-model adversarial από πάνω) | watchtower-case | D6 |
| `source/legal-counterfactual.lisp` | KEEP (case-fact counterfactuals) | watchtower-case/twin | D4 |
| `source/legal-subsumption.lisp`, `legal-strategy.lisp` | KEEP + EXTEND (deadline seed → full practice calendars) | watchtower-case/practice | D7 |
| what-if (self-change analysis) | KEEP | watchtower-governance | — |
| `source/legal-ast.lisp`, `legal-identity.lisp` | KEEP | watchtower-canonical | — |
| `source/legal-hypergraph.lisp` | REFACTOR ρόλου → derived projection (όχι 2ο authoritative universe) | watchtower-api | B5+ |
| RDF/SPARQL emitters | MOVE → projections | watchtower-api | B6 |
| embeddings/vector search | KEEP as DERIVED ONLY (retrieval accelerator, ποτέ authority) | watchtower-intelligence | D6 |
| `source/memory.lisp` | REFACTOR (per-matter partition) | watchtower-practice | B1-2 |
| `source/ingestion-daemon.lisp` | REFACTOR (typed calls αντί find-symbol· emits μέσω G-pub· Source Mesh protocol) | watchtower-acquisition | B1, B3, D5 |
| `source/government-source.lisp`, `source-profile.lisp` | KEEP + EXTEND (adapter protocol, source universe: Parliament/ΕΤ/Diavgeia/ΣτΕ/ΑΠ/EUR-Lex/CURIA/HUDOC) | watchtower-acquisition | D5 |
| `source/corpus-fingerprint.lisp` | UPGRADE (golden-earned: source-fidelity gate — golden↔ΦΕΚ, όχι μόνο golden↔served) | watchtower-acquisition | B4/D5 |
| `source/corpus-provenance.lisp` | UPGRADE (τέλος fabricated `2025-01-01` fallback — malformed date ⇒ error/review) | watchtower-canonical | B4 |
| `source/narrative-provenance.lisp` | REPLACE verify (hash-chain) ή RENAME (όχι «verify») | watchtower-kernel | **B4** |
| `systems/orchestrator-ai-core/provenance-model.lisp` | REFACTOR (legal-authority provenance, όχι build-pipeline· fix Blake2/Blake3 label) | watchtower-canonical | B5 |
| `source/ai-citation-strategy.lisp` | RETIRE από trusted core (SEO/egress/fabricated-DOI/CC-BY vs ARR)· ό,τι χρήσιμο → G-pub-gated publication feature | — | B1 |
| `source/semantic-versioning-system.lisp` | MERGE/RETIRE (3ο versioning seat· μία έδρα: version-graph) | — | B3 |
| `source/legal-qa.lisp` | KEEP (deterministic, «never generated») | watchtower-case | — |
| `source/http-server.lisp`, `review-queue.lisp` | KEEP → MOVE | watchtower-api / governance | B6 |
| `source/autonomy.lisp` | KEEP → MOVE σε governance sandbox (proposal-queue φιλοσοφία σωστή· ποτέ direct mutation) | watchtower-governance | B6 |
| self-model (`meta-ontology.lisp`) | REPLACE axioms (multi-world reconcile + recompute commit hash) | watchtower-normative | **B5-1** |
| cognition/self-model runtime coupling | MOVE έξω από trusted runtime | watchtower-governance | B6 |
| `orchestrator-omega` | ΑΠΟΣΥΝΑΡΜΟΛΟΓΗΣΗ (FRBR/serialization → σωστά domains· τέλος ως architecture universe) | διάφορα | B6 |
| `orchestrator-infrastructure.asd` (132 files) | ΣΠΑΕΙ σε domain systems | 11 watchtower-* | B6 |
| `deployment/verify/*`, `authority-v2/proofs/*`, `scripts/*` | KEEP (discharge substrate) + B0a qualification + B4 replacements | proof-CI | B0a |
| `authority-v2/` store dirs | KEEP + REFACTOR (multi-world substrate reconcile με version-graph append-log αντίφαση [A]) | watchtower-temporal | B2/B5 |
| `deploy.lisp` (SINGLE FILESYSTEM TRUTH) | KEEP + telos change (publish → served/watched observatory) | watchtower-api | B6+ |
| `output/`, `output_run1/` | ΔΙΑΧΩΡΙΖΟΝΤΑΙ εκτός source tree (state/artifacts) | — | B6 |
| παλιά docs/URLs/v1.0-1.3/ORCHESTRATORSUPER narratives | ARCHIVE· docs generated από κώδικα (ARCHITECTURE/TRUST-MODEL/LEGAL-SEMANTICS/EPISTEMIC-CONTRACT/SOURCE-CONTRACT/CLAIM-CONTRACT/SECURITY-MODEL/UPGRADE-CONTRACT.md) | docs | B6 |
| NEW seats | Publication Gateway, matter-isolation/egress, Normative IR, Claim/Dependency graph, Impact engine, Legislative simulator, Source-mesh adapters, AI plane registry/roles/policies, deadline calendars, Legal Reasoning Proof Bundle, federation | κατά πίνακα §3 | B1→D10 |

---

## 5. MATURITY MATRIX (σήμερα, τίμια — K=kernel, S=semantic, O=operational, P=production-assurance)

| Subsystem | K | S | O | P | Σχόλιο |
|---|---|---|---|---|---|
| Crypto/attestation spine | HIGH | — | PARTIAL | HIGH | προστατεύει λάθος αντικείμενο μέχρι B0/B1 |
| Journal/ledger | HIGH | — | PARTIAL | PARTIAL | anchor-on-write + fsync gaps |
| Version-graph (temporal) | HIGH | PARTIAL | **ABSENT (dark)** | PARTIAL | εκτός load path — B2 το θεραπεύει |
| Consolidation | PARTIAL | PARTIAL | HIGH | LOW | serving σήμερα· demote σε renderer |
| Inference (JTMS/WFS) | HIGH | SEED | LOW | LOW | καλός πυρήνας, λίγη ύλη |
| Event calculus | PARTIAL | SEED | ABSENT | ABSENT | 64-γραμμο δηλωτικό kernel· ontology πρώιμη |
| Dialectic/precedent/deontic | PARTIAL | SEED | LOW | LOW | |
| Admission/gates | **BROKEN** (fail-open) | — | HIGH (τρέχουν) | **ABSENT** (0/17 theorem-backed) | B0/B0a |
| Ingestion/sources | PARTIAL | SEED | ABSENT | ABSENT | αρρύθμιστο, stringly-wired |
| Provenance/claims | SEED | SEED | LOW | LOW | build-pipeline provenance, όχι legal |
| Practice (deadlines κ.λπ.) | SEED | SEED | ABSENT | ABSENT | present-but-insufficient |
| AI plane | SEED | — | ABSENT | ABSENT | manifests/citation μόνο |
| Security/privilege | SEED (capabilities) | ABSENT | ABSENT | ABSENT | B1 foundation |

## 6. ΤΙ ΜΕΝΕΙ ΑΝΟΙΧΤΟ (carried BLOCKING — δεν κρύβεται)

R-1 novel-at-speed (reduced-to-human-limit, DESIGN-ENTAILED)· R-2 advocacy two-register (dissolved
ως αντίφαση, unpaid Axiom-Φ bet)· R-3 population blind spot (contained, conditional on R-5)·
R-5 verifier-calculus/mode-tag F≤F3 (το K-typ mode-mislabel seam = το ένα σημείο worse-than-human)·
R-6 e-filing hole· R-7 AI-Act/GDPR/privilege retention· R-9 DLP-classifier-in-TCB. Κανένα «supreme»
claim χωρίς το verification regime (DELIVERABLE-7) + independent reproduction.

## 7. REVIEW PROTOCOL (για τους δύο reviewers)

1. Reviewer-B: item-by-item `ACCEPT / MODIFY / REJECT / MISSING` σε κάθε migration item (§2, §3)
   και κάθε disposition row (§4)· κάθε MODIFY/REJECT με path/symbol/failure-case.
2. Διαφωνίες: BLOCKING μέχρι executable evidence ή απόφαση δημιουργού.
3. Μετά τη σύγκλιση: ο δημιουργός εγκρίνει ανά φάση («εγκρίνω B0a», …)· υλοποίηση από τον έναν,
   adversarial verification από τον άλλον (author ≠ reviewer by construction)· κάθε phase κλείνει
   ΜΟΝΟ με GREEN discharge tests + review sign-off.
4. Τα `[A]`-tagged facts του παρόντος οφείλουν ανεξάρτητη ανα-επαλήθευση από Reviewer-B πριν
   θεωρηθούν accepted (ο κοινός κανόνας ισχύει και για το ίδιο το blueprint).

**DONE WHEN (του ίδιου του blueprint):** και οι δύο reviewers έχουν καταθέσει πλήρη item-by-item
ετυμηγορία· 0 items σε κατάσταση διαφωνίας-χωρίς-evidence· ο δημιουργός έχει εγκρίνει το τελικό
κείμενο ως το κοινό engineering contract.
