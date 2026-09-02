# [0147] — SPEC v1.5 NARROW-DELTA CANDIDATE (design-only· D1/D2/D3/C1)
**2026-09-02 · parent `182399b1` · frozen v1.4 baseline `88129099` αμετάβλητο · CANDIDATE — NOT FROZEN — NOT QUALIFIED — IMPLEMENTATION BLOCKED**

Εντολή: «AUTHORIZE ONE BOUNDED SPEC v1.5 NARROW-DELTA PASS — DESIGN ONLY». Μία ρητά περιορισμένη
εξαίρεση στον anti-loop, με frozen v1.4 commit **αμετάβλητο** (κανένα amend/rewrite). Ενσωμάτωση
**αποκλειστικά** τεσσάρων deltas — κανένα πέμπτο, κανένας νέος axis, καμία αλλαγή μακροαρχιτεκτονικής.
`AION` απορρίπτεται ως brand/architecture. Κανένας κώδικας/workflow/MLTP-core/WP/qualification/re-freeze.
**Δεν αγγίχθηκαν:** `source/ systems/ .github/ deployment/verify/mltp3/ RAW-JOURNAL history.sexp
output/.healthy IMPLEMENTATION-BOOK/ (v1.0+v1.1)` · ο manifest-pinned v1.4 `.out` (4873e610).

## Τα τέσσερα deltas
- **D1 Independent Semantic Admission** (Secure Ingress §9 + `V1.5-SCHEMAS.sexp`): `SemanticAdmission
  AssuranceProfile` SA-0/1/2· `SemanticAdmissionEvidence/1` (11 υποχρεωτικά πεδία)· event-kind→SA· real
  mechanism diversity = distinct `derivation_family_id` **και** `derivation_artifact_digest` (αποφυγή
  «δύο binaries στο ίδιο σφάλμα/spec»)· `DivergenceState` διαχωρίζει `DETERMINISTIC_DIVERGENCE` (⇒
  QUARANTINED) από `INTERPRETIVE_DISAGREEMENT` (⇒ typed argument L5/L6, ΟΧΙ error/majority vote).
  **Invariant V5I-01 (hard):** SA-2 δεν προάγεται ADOPTED→CANONICAL χωρίς εκπληρωμένη υποχρέωση· schema-
  valid λάθος state-mutating ⇒ QUARANTINED ακόμη κι αν οι compilers συμφωνούν. Καμία universal N-version.
- **D2 Census Enumerability + Negative Evidence** (SourceType §5, USC §13): `enumerability_class` (5)·
  `availability_class` (5)· `CensusSpaceClassification/1`· `EXPLICITLY_ABSENT` μόνο με authenticated
  negative evidence σε complete-index/serial-space· partial ⇒ `NOT_OBSERVED_IN_DECLARED_SOURCE`· open-world
  ⇒ UNKNOWN· non-public ⇒ coverage state (όχι crawler failure)· expired completeness ⇒ ποτέ absence.
- **D3 Evidence-Backed Independence Quorums** (MLTP §15): `ActorIndependenceEvidence/1` +
  `IndependencePolicy/1`· διαφορετικά kid ≠ independence· self-signed/expired/revoked δεν μετρά· ανεπαρκές
  ⇒ `INDEPENDENCE_UNKNOWN`· consumer-local αποφασίζει· shared provider/cloud ανά profile+control domain.
  **Μία** quorum έδρα· predicate `distinct-valid-kids` → `distinct-valid-kids AND satisfies(policy, evidence)`.
- **C1 Interpretive Profile closure** (Legal-IR §12, CPEI §7, Constitution comment): `InterpretiveProfile/1`
  + `ArgumentRecord/1` (αναπαράσταση του υπάρχοντος `:argument`)· competing interpretations συνυπάρχουν
  χωρίς ψευδή νικητή· adoption αλλάζει institutional/epistemic status, ΟΧΙ αντικειμενική αλήθεια. **ΟΧΙ**
  νέος engine/primitive.

Trust invariant διατηρημένο: `NO SINGLE POINT OF BLIND TRUST — ALL TRUST ASSUMPTIONS EXPLICIT, MINIMIZED, SCOPED` (το απόλυτο no-required-trust ΔΕΝ
χρησιμοποιείται). De jure boundary + internal/public time αμετάβλητα.

## Παραδοτέα
`CHANGE-PROPOSAL-v1.5.md` (successor candidate)· `V1.5-NARROW-DELTA-MANIFEST.md` (parent/baseline/scope/
affected seats + frozen→candidate hashes, CANDIDATE)· `V1.5-SCHEMAS.sexp` (machine-readable D1–D3/C1)·
`V1.5-CONTRADICTION-OMISSION-AUDIT.sh` (limited, document/reference ΜΟΝΟ)· 6 additive seat appendices +
constitution comment· error taxonomy + state transitions· traceability (20 V5R → seat/test/evidence)·
predeclared V5Q-01..04 + kill witnesses D1×5/D2×5/D3×6/C1×4=20· delta-impact matrix → WP (χωρίς αλλαγή WP).

## Self-check + regressions
Άλλαξαν **μόνο** 7 normative seats + 4 νέα v1.5 αρχεία (+ dialogue/index)· κανένα protected path·
`88129099` immutable (frozen file hashes επαληθεύονται)· AION μη ενεργό· κάθε νέο ID defined+used· κάθε
requirement seat/test/evidence· καμία δεύτερη έδρα· audit τίμια DOCUMENT/REFERENCE μόνο.
**Regressions:** v1.4 audit **158/158 exit 0** και στο frozen snapshot `88129099` **και** στο v1.5 working
tree (additive appendices)· v1.5 audit **43/43 exit 0**· `run.sh` exit 0· IB checks exit 0· v1.4 `.out`
(4873e610) αμετάβλητο.

**ΕΤΥΜΗΓΟΡΙΑ: `SPEC v1.5 NARROW-DELTA CANDIDATE — NOT FROZEN — NOT QUALIFIED — IMPLEMENTATION BLOCKED`.**
Καμία re-freeze/book-update/WP-00/implementation χωρίς νέα ρητή εντολή δημιουργού.
