# LAWMAX — LEGAL-IR SEMANTIC REQUIREMENTS SPECIFICATION (language-independent)
# ΟΙ ΑΠΑΙΤΗΣΕΙΣ ΤΟΥ ΣΗΜΑΣΙΟΛΟΓΙΚΟΥ ΣΥΜΒΟΛΑΙΟΥ ΓΙΑ ΔΥΟ ΑΝΕΞΑΡΤΗΤΟΥΣ COMPILERS — ΟΧΙ ΔΕΥΤΕΡΗ ΑΡΧΙΤΕΚΤΟΝΙΚΗ

**ΚΑΤΑΣΤΑΣΗ: `DESIGN-ONLY · NORMATIVE REQUIREMENTS SPEC — ΟΧΙ ΟΛΟΚΛΗΡΩΜΕΝΟ ΜΗΧΑΝΟΠΟΙΗΜΕΝΟ
ΣΥΜΒΟΛΑΙΟ`.** Καμία γραμμή κώδικα, κανένα freeze, καμία qualification. **Τιμιότητα
(POST-C2 correction, Finding 3-honesty):** αυτό το κείμενο **ΔΕΝ** είναι ένα πλήρες
μηχανοποιημένο σημασιολογικό συμβόλαιο· είναι η **προδιαγραφή απαιτήσεων** που **απαριθμεί
ρητά** τα γλωσσο-ανεξάρτητα μηχανοποιημένα artifacts που **λείπουν**, καθένα σημασμένο ως
**Implementation Book deliverable (ΜΗ ΠΑΡΑΧΘΕΝ)**. **Δεν διεκδικείται μηχανοποιημένο
κλείσιμο από πρόζα.** Είναι η κανονική έδρα (μία ανά έννοια), απαιτούμενη από
`CHANGE-PROPOSAL-v1.4.md §4.6` (Dual Independent Legal Compilers) και
`LAWMAX-CPEI-TARGET-SPEC.md` L3/L10.

## 0. ΔΙΑΘΕΣΗ FINDING 1: `PARTIALLY CLOSED` (τεκμηριωμένη από κώδικα)

Μηχανικά επαληθευμένη απογραφή των πραγματικών εδρών:

| # | συστατικό | κατάσταση σήμερα | έδρα |
|---|---|---|---|
| 1 | Κλειστό Legal IR grammar / node set | **SPLIT** — document-AST κλειστό ως δεδομένα· epistemic IR ABSENT | `source/legal-ast.lisp:+ast-schema+`· epistemic set = v1.4 §1.1 L3 |
| 2 | Typing / well-formedness | **LISP-ONLY** | `source/validate-ast.lisp`· `source/legal-deontic.lisp:make-norm` |
| 3 | Evaluation order (WFS) | **LISP-ONLY** (ιδιότητα, όχι κανονιστικό έγγραφο) | `source/legal-inference-engine.lisp` |
| 4 | Conflict-resolution mechanism | **LISP-ONLY** — canons hardcoded `:unless` (**substantive· λάθος έδρα**, §4) | `source/legal-conflict-resolution.lisp` |
| 5 | Temporal projection | **MACHINE-DEFINED (μερικό)** — Π1· Π2–Π7 FROZEN | `deployment/LAWMAX-TEMPORAL-SEMANTICS-SPEC.md` |
| 6 | Conflict / abstention | **LISP-ONLY** (WFS three-valued)· protocol UNKNOWN machine-defined | `source/legal-inference-engine.lisp`· `mltp3/schemas.json:result_order` |
| 7 | Compiler error taxonomy | **ABSENT** ως κλειστό αντικείμενο | scattered Lisp conditions |
| 8 | Canonical serialization | **MACHINE-DEFINED** (+ vectors + independent verifier) | `deployment/verify/canonical-serialization-spec.md` |

Γλωσσο-ανεξάρτητα και conformance-tested σήμερα μόνο τα 5-μερικό, 7-protocol, 8. Ο πυρήνας
συλλογισμού (1–4, 6, compiler-7) είναι **Lisp-only** ⇒ οι δύο compilers (§4.6, D-03)
κινδύνευαν από **common-mode failure**.

## 0.1 IMPLEMENTATION BOOK DELIVERABLES — ΤΙ ΛΕΙΠΕΙ ΓΙΑ ΜΗΧΑΝΟΠΟΙΗΜΕΝΟ ΚΛΕΙΣΙΜΟ (κανένα δεν έχει παραχθεί)

Κάθε γραμμή είναι **απαίτηση**, όχι ολοκληρωμένο artifact. Παράγεται στο **Implementation
Book** (μετά το SPEC FREEZE, πριν το product implementation — v1.4 §10 διορθωμένη κλίμακα).

| απαίτηση | συγκεκριμένο γλωσσο-ανεξάρτητο artifact | κατάσταση |
|---|---|---|
| IR grammar | `legal-ir-grammar.json` (κλειστό node/type set, machine-readable) | **IMPLEMENTATION BOOK — ΜΗ ΠΑΡΑΧΘΕΝ** |
| Typing judgments | κανόνες `⊢ node : kind` ως machine-checkable rule set | **IMPLEMENTATION BOOK — ΜΗ ΠΑΡΑΧΘΕΝ** |
| WFS εξισώσεις + termination | ακριβείς alternating-fixpoint εξισώσεις + όρος τερματισμού, machine-checkable | **IMPLEMENTATION BOOK — ΜΗ ΠΑΡΑΧΘΕΝ** |
| Conflict/abstention formal rules | ο evaluator του adopted `ConflictPolicyBundle` (§4) ως formal rules | **IMPLEMENTATION BOOK — ΜΗ ΠΑΡΑΧΘΕΝ** |
| Error mapping | compiler error taxonomy (§7) → result lattice, machine-readable | **IMPLEMENTATION BOOK — ΜΗ ΠΑΡΑΧΘΕΝ** |
| Conformance corpus | concrete `input-IR → expected-derivation` vectors (θετικά + αρνητικά) | **IMPLEMENTATION BOOK — ΜΗ ΠΑΡΑΧΘΕΝ** |

Ήδη γλωσσο-ανεξάρτητα (reusable, ΟΧΙ Implementation Book): canonical serialization
(`canonical-serialization-spec.md` + vectors), protocol error-taxonomy/result-lattice
(`mltp3/schemas.json`), temporal Π1 (`LAWMAX-TEMPORAL-SEMANTICS-SPEC.md`).

## 1. Κλειστό Legal IR grammar και node/type set (Component 1) — REQUIREMENT

Δύο επίπεδα: document-structure AST (κλειστό ήδη ως δεδομένα, `+ast-schema+` — απαίτηση:
ανύψωση σε `legal-ir-grammar.json`) και epistemic reasoning IR = κλειστό sum
`{ Fact, Norm, Claim, Proof, Counterproof, Hypothesis }`, καθένα με `plane ∈ {PLANE-0..3}`
στον τύπο· `id` domain-separated hash του BODY χωρίς id/sig (MLTP §4.2 κανόνας 2)·
`source_anchor` ≥1 ΥΠΟΧΡΕΩΤΙΚΟ· καμία boolean σε hash-bearing record (typed enums).

## 2. Typing / well-formedness (Component 2) — REQUIREMENT

Κρίση `⊢ node : kind`: υποχρεωτικά πεδία ανά kind· `Norm` απαιτεί `modality ∈ +modalities+`,
`consequent`, υποχρεωτική πηγή· `determinacy ∈ {mechanical, interpretive, discretionary,
underdetermined}`. Reference impl (προς ανύψωση): `validate-ast.lisp`. Μη καλοσχηματισμένος
⇒ `ir-type-error`/`ir-malformed` (§7).

## 3. Evaluation order (Component 3) — REQUIREMENT (μη μηχανοποιημένο ακόμη)

**Απαίτηση:** η κανονιστική σημασιολογία είναι Well-Founded Semantics (WFS) μέσω
alternating fixpoint (Van Gelder). Το **μηχανοποιημένο artifact** (ακριβείς εξισώσεις
`(K_i, U_i)`, όρος τερματισμού, **υποχρέωση απόδειξης order-independence**) είναι
**Implementation Book deliverable, ΜΗ ΠΑΡΑΧΘΕΝ** — εδώ δηλώνεται η απαίτηση, **όχι**
ολοκληρωμένη μηχανοποίηση. Reference impl: `legal-inference-engine.lisp`. Μη τερματισμός ⇒
`evaluation-nonterminating`.

## 4. CONFLICT RESOLUTION — ΜΗΧΑΝΙΣΜΟΣ, ΟΧΙ ΟΥΣΙΑΣΤΙΚΟΣ ΚΑΝΟΝΑΣ (Component 4· POST-C2 correction)

**ΑΦΑΙΡΕΘΗΚΕ η καθολική ουσιαστική παραδοχή** `lex superior ≻ lex specialis ≻ lex
posterior` και «specialis νικά posterior». **Η αρχιτεκτονική ΔΕΝ επινοεί τον ουσιαστικό
κανόνα** — αυτός εξαρτάται από jurisdiction/authority/competence/subject/time και είναι
**αμφισβητούμενος**. Η αρχιτεκτονική ορίζει **ΜΟΝΟ τον μηχανισμό αξιολόγησης** ενός
**υιοθετημένου, scoped** `ConflictPolicyBundle`.

```
ConflictPolicyBundle:
  # BODY = { record, scope, rules, approving_act, supersedes }   (ΟΧΙ id, ΟΧΙ sig)
  "policy_bundle_id": <"cpb1:" + hex(sha256("mltp3:conflict-policy-id" ‖ 0x1F ‖ canonical(BODY)))>,
  "record": "conflict-policy",
  "scope": { "jurisdiction": <iri>, "authority": <iri>, "competence": <iri>,
             "subject": [<iri>], "valid_from": <legal-instant>, "valid_to": <legal-instant>|null },
  "rules": [ { "when": <scoped predicate>, "prefer": <ordering πάνω σε source-classes>,
               "source_anchor": [ <manifestation_id + span> ] } ],   # ΚΑΘΕ rule source-anchored
  "approving_act": "clm1:<hash>",     # InstitutionalAct (L8/L12) — versioned adoption
  "supersedes": "cpb1:<hash>" | null,
  "sig": { "alg","kid": <delegated release key>, "sig": <SIGN over (envelope minus sig), context "mltp3:conflict-policy"> }
```

**Αξιολόγηση σύγκρουσης δύο εφαρμοστέων κανόνων N1, N2 (ντετερμινιστική, χωρίς επινόηση):**
1. Επίλεξε τα υιοθετημένα `ConflictPolicyBundle` των οποίων το `scope` **καλύπτει**
   (jurisdiction, authority, competence, subject, time) της σύγκρουσης.
2. **Κανένα** υιοθετημένο bundle δεν καλύπτει ⇒ **`UNKNOWN(no-applicable-conflict-policy)`**
   — ΠΟΤΕ επινοημένη διάταξη.
3. Ακριβώς ένα rule αποφασίζει ⇒ εφαρμόζεται (η διάταξη είναι **ΔΕΔΟΜΕΝΑ** από το bundle,
   source-anchored).
4. Δύο υιοθετημένα bundles ίσης προτεραιότητας με ασύμβατες διατάξεις, **ή** σιωπηλό rule
   ⇒ **`CONFLICTING(conflict-policy-underdetermined)`**.
5. **Ποτέ σιωπηλή ολικοποίηση** για να εξαναγκαστεί ντετερμινιστική έξοδος. Η μη-ολικότητα
   είναι **αποδεκτή έξοδος** (`CONFLICTING`/`UNKNOWN`), όχι σφάλμα να «διορθωθεί».

Extension error taxonomy (compiler §7): `no-applicable-conflict-policy ·
conflict-policy-underdetermined · unadopted-conflict-policy · conflict-policy-unscoped`.
**Falsifier: KW-105** (δύο compilers που, χωρίς καλύπτον υιοθετημένο bundle, παράγουν
**οποιαδήποτε** ντετερμινιστική διάταξη αντί `UNKNOWN`/`CONFLICTING` ⇒ κόκκινο).

## 5. Temporal projection (Component 5) — REUSE + REQUIREMENT

REUSE `LAWMAX-TEMPORAL-SEMANTICS-SPEC.md` (Π1). Event-history projection
(`legal-event-calculus.lisp`, Lisp-only) → κανονιστικό Discrete Event Calculus =
**Implementation Book deliverable**. **Τρεις χρονικοί άξονες διακριτοί:** νομικός χρόνος
γεγονότος · εφαρμοσιμότητα οντολογίας (`OntologyBundle.applicability`) · χρόνος υιοθέτησης/
ελέγχου (`audit-timeline/1`).

## 6. Conflict & abstention (Component 6) — REQUIREMENT

Reasoning layer: three-valued WFS `{in, out, undec}`· `undec` ⇒ `UNKNOWN(undecided-legal-state)`·
ρητή αποχή ΥΠΟΧΡΕΩΤΙΚΗ. Conflict ⇒ `CONFLICTING` (§4). Protocol lattice
`UNVERIFIED_FOR_MACHINE_RELIANCE < UNVERIFIED_FOR_ATTRIBUTED_RELIANCE < UNKNOWN < VERIFIED`
(reuse `mltp3/schemas.json:result_order`).

## 7. Deterministic COMPILER error taxonomy (Component 7) — REQUIREMENT (κλειστή)

Διακριτή από την protocol taxonomy. Κλειστό σύνολο:
```
ir-malformed · ir-type-error · unknown-node-kind · missing-source-anchor ·
evaluation-nonterminating · temporal-inconsistent · deontic-conflict-unresolved ·
subsumption-undetermined · serialization-noncanonical ·
no-applicable-conflict-policy · conflict-policy-underdetermined ·
unadopted-conflict-policy · conflict-policy-unscoped
```
Το machine-readable mapping σε result lattice = **Implementation Book deliverable**.

## 8. Canonical serialization (Component 8) — REUSE

REUSE `canonical-serialization-spec.md` (RFC 8785 JCS) + vectors + `verify-canonical.py`.
Non-canonical ⇒ `serialization-noncanonical`.

## 9. Proof obligations & conformance corpus (Component 9) — REQUIREMENT

Corpus `input-IR → expected-derivation` (θετικά + αρνητικά), που **αμφότεροι** οι compilers
περνούν **ανεξάρτητα** (κανένα κοινό evaluator code). Κλάσεις: grammar-roundtrip · typing ·
WFS-determinism · **conflict-policy evaluation** (καλύπτον bundle ⇒ ντετερμινιστικά·
απών ⇒ UNKNOWN· ασύμβατα ⇒ CONFLICTING) · temporal-projection · error-taxonomy · serialization.
Διάσταση ⇒ `compiler-divergence` ⇒ QUARANTINED (ποτέ νικητής). **Το corpus είναι
Implementation Book deliverable, ΜΗ ΠΑΡΑΧΘΕΝ.**

## 10. Απαίτηση ανεξαρτησίας

Οι δύο compilers ΔΕΝ παράγονται από κοινό evaluator code. Μηχανοποιημένο μοντέλο (TLA+/
Rocq/Lean) = **conformance oracle μόνο**, ΠΟΤΕ κοινή υλοποίηση. Διακριτά `compiler_family_id`,
`source_digest`, toolchain, `kid` (MLTP §13.4)· ίδιο ⇒ `fabricated-compiler-independence`.
**Falsifier: KW-105.**

## 11. Τι ΔΕΝ κάνει

Καμία υλοποίηση· κανένα freeze/qualification· δεν επιλέγει Rust vs OCaml (U-5)· δεν
ξεπαγώνει Π2–Π7· **δεν επινοεί ουσιαστικό νομικό κανόνα σύγκρουσης**· **δεν διεκδικεί
μηχανοποιημένο κλείσιμο** — τα μηχανοποιημένα artifacts είναι Implementation Book
deliverables (§0.1), όλα ΜΗ ΠΑΡΑΧΘΕΝΤΑ.
