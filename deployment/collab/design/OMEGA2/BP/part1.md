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
