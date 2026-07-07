# LAWMAX REPO ONTOLOGY MAP — Ανθρώπινη αναφορά
**Ontological Closure Audit, μέρος 1/2.** Κάθε αριθμός εδώ προέρχεται από τα
ζωντανά μητρώα (runtime dump) ή από grep στην πηγή — ποτέ από αφήγηση.
Μηχανικά αδέλφια: `LAWMAX-REPO-ONTOLOGY-MAP.sexp` (πλήρης χάρτης με evidence
ανά γραμμή), `LAWMAX-REPO-GRAPH.json` (259 κόμβοι / 443 ακμές),
`LAWMAX-ARCHITECTURE-CONSTITUTION.sexp` (κανονιστική πηγή, επιβαλλόμενη από
το `--architecture-constitution-gate`).

## Αριθμοί (ζωντανό μητρώο, τη στιγμή της γένεσης)

| Μέγεθος | Τιμή | Evidence |
|---|---|---|
| Εντολές CLI | **150** | `*commands*` hash-table (runtime) |
| Πύλες | **20** | μητρώο, κατάληξη `-gate` |
| Ικανότητες | **29** | `self-model:all-capabilities` |
| Συμβόλαια | **40** | `contracts:all-contracts` |
| Συστατικά | **494** (271 αρχεία SHA-256, 135 πακέτα, 72 κρίσιμα σύμβολα) | `components:all-components` |
| Πακέτα ORCHESTRATOR.* | **135** | `list-all-packages` |
| ASDF συστήματα | spec 8 · model 8 · core 8 · engine-sbcl 2 · infrastructure 126 · cli 44 | `asdf:find-system` |

## Τα 13 primitives (ΚΛΕΙΔΩΜΕΝΑ)

`SELF · LAW · AUTHORITY · FACT · PROOF · HYPOTHESIS · ARGUMENT · MATTER ·
OUTPUT_TRUST · EVOLUTION · INSTITUTION · MEMORY · SUBSTRATE`

Κάθε εντολή (150/150) και κάθε ικανότητα (29/29) φέρει primitive στο Σύνταγμα·
η πύλη ελέγχει την κάλυψη **αμφίδρομα** σε κάθε ολομέλεια. Νέα έννοια χωρίς
δήλωση `concept / belongs_to / extends_existing / does_not_duplicate / tests /
rollback` δεν μπαίνει — μηχανικά, όχι εθιμικά.

## Κατανομή εντολών ανά primitive

- **:law 24** (corpus/ΦΕΚ/pipelines/emitters) · **:evolution 23** (Σ11, what-if,
  can-adopt, training, learn-understanding) · **:self 23** (mirror, contracts,
  components introspection) · **:output-trust 16** (ask, serve, traces, draft,
  provenance) · **:institution 17** (policies, review, missions, agenda) ·
  **:proof 14** (subsume, reason, verify-proof, inference/iq) ·
  **:substrate 14** (gates plenary, upgrades, help/version) · **:authority 9**
  (νομολογία/δικαστές) · **:memory 5** · **:hypothesis 4** (advisor, arc, fluid)
  · **:matter 2** (--case/--φάκελος) · **:argument 2** (--argue, --strategy) ·
  **:fact 1** (event-gate). Πλήρης πίνακας: στο .sexp, με owner-file ανά εντολή.

## Έδρες-κλειδιά ανά primitive (canonical homes)

| Primitive | Κανονική έδρα |
|---|---|
| SELF | self-model, contracts, components(+scan), cognition-self |
| LAW | corpora+prov, consolidation, legal-temporal, canonical-article-id |
| AUTHORITY | legal-decisions (decision-ratio!), legal-precedent, jurisprudence-judge |
| FACT | casegrammar/γλωσσική-αντίληψη, event-calculus |
| PROOF | legal-subsumption, inference-engine (WFS), guard-metaeval, proof-carrying |
| HYPOTHESIS | advisor (όνειρα), fluid-induction, legal-hypo |
| ARGUMENT | legal-dialectic, legal-strategy |
| MATTER | case-workspace |
| OUTPUT_TRUST | %ask-envelope, execution-trace+provenance-link, generation, draft |
| EVOLUTION | proposals (Σ11), what-if, adoption-decision, self-extension, understanding-learning |
| INSTITUTION | institution, approval-policy, review-queue, autonomy |
| MEMORY | memory (επεισόδια SHA-256), self-history, lessons/failure-ledger |
| SUBSTRATE | build.lisp, component manifest, Dockerfile/docker, (μελλοντικά nix/) |

## Bootstrap (ΔΕΝ μετρά ως μάθηση — σημασμένο στην πηγή)

`cognition-self.lisp` (χειροποίητοι ταξινομητές/frames) · `self-glossary.sexp` ·
`dialogue-gate.lisp` (σουίτα προσδοκιών) · `casegrammar-core.sexp` (σπόροι) ·
feature extractors στο `understanding-learning.lisp`. Όλα φέρουν σήμανση
BOOTSTRAP· η πύλη ⑩ το επαληθεύει στην πηγή.

## Πού είναι ο πλήρης χάρτης

- Ανά εντολή (150 γραμμές): `LAWMAX-REPO-ONTOLOGY-MAP.sexp :commands` —
  command / handler-file / primitive / evidence.
- Γράφος command→file→capability→contract→test→primitive:
  `LAWMAX-REPO-GRAPH.json`.
- Διπλότυπα/κίνδυνοι & σχέδιο: `LAWMAX-CONSOLIDATION-PLAN.md`.
