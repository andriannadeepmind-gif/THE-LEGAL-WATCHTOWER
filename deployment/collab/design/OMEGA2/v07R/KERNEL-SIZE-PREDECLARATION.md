# C5 — ΔΗΛΩΣΗ ΜΕΓΕΘΟΥΣ ΠΥΡΗΝΑ (σφραγισμένη ΠΡΙΝ από κάθε επίθεση)

Δηλώνεται πριν γραφτεί οποιοδήποτε attack, replay ή holdout. Κάθε μεταγενέστερη προσθήκη
μετριέται εναντίον αυτού του αριθμού. Αν ένα counterexample απαιτήσει νέο primitive ή νέο
special-case axiom, αυτό είναι **NOT CONVERGING** και δηλώνεται.

## Πρωτογενή (primitives): 8
1. `TypedObject`            2. `AuthorityOperation`     3. `LinearizationDomain`
4. `EvaluationFrontier`     5. `ClosureClaim`           6. `ArtifactValidityEnvelope`
7. `RootCommit`             8. `CanonicalEncoding`

## Τύποι μεταβάσεων πυρήνα: 9
`authority_op` · `root_commit` · `capture` · `dispose` · `claim_absence` · `answer_query`
· `issue_artifact` · `update_semantic_artifact` · `select_frontier`

## Αξιώματα πυρήνα: 3 νόμοι, 12 ρήτρες
- **L1** (5): L1.a κοινό domain για ό,τι αλληλο-ακυρώνεται · L1.b μία authority operation ανά
  position · L1.c causal-backward frontier · L1.d civil time → frontier μόνο με selection proof
  ή UNKNOWN · L1.e καμία τοπική θέα δεν παράγει authority.
- **L2** (4): L2.a καμία absence χωρίς universe+basis · L2.b conservation του captured ·
  L2.c terminal disposition durable/auditable · L2.d completeness μόνο εντός
  ProofSupportedQuerySubset.
- **L3** (3): L3.a artifact αμετάβλητο, applicability υπολογιζόμενη στο frontier · L3.b durable
  proof δεσμεύει commitment, ποτέ plaintext · L3.c semantic change ⇒ impact closure.

## Boundary contracts (STRATUM C, ρητά ΜΗ παραγόμενα από L1/L2/L3): 12
crypto suites · key management · runtime integrity · identity assurance · TCB · supply chain ·
trusted updates · code safety · noninterference envelope · AI boundary · source authority
policy · physical/hardware assumptions.

## Κριτήριο σύγκλισης (δηλωμένο εκ των προτέρων)
- **CONVERGENCE EVIDENCE** αν: όλα τα A-1…A-6 / B-1…B-8 κλείνουν ως συνέπειες των 12 ρητρών,
  **χωρίς** νέο primitive και **χωρίς** νέο special-case axiom.
- **NOT CONVERGING** αν έστω ένα απαιτεί νέο primitive/axiom.
- **REDUCTION FAILED** αν νέο break ανήκει πάλι σε R1/R2/R3 (C6).
