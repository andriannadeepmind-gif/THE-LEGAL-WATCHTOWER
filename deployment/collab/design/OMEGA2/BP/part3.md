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
