# [0149] — SPEC v1.5 INDEPENDENT-REVIEW REPAIR (F1–F5· design-only· bounded corrective pass)
**2026-09-02 · parent `019c0d58` · frozen v1.4 baseline `88129099` αμετάβλητο · CANDIDATE — NOT FROZEN — NOT QUALIFIED — IMPLEMENTATION BLOCKED**

Εντολή: «INDEPENDENT REVIEW RESULT — V1.5 SEMANTIC CLOSURE FALSIFIED BY FIVE NAMED WITNESSES». Ανεξάρτητη
αντιπαλική επιθεώρηση falsified την «semantic closure» του `019c0d58` με **πέντε** ονομαστικούς μάρτυρες·
η μακροαρχιτεκτονική **δεν** απορρίφθηκε. **Μία** bounded corrective commit· **καμία** νέα αρχιτεκτονική/
axis/plane/engine/store/trust-protocol· **κανένας** κώδικας παραγωγής· **κανένα** Implementation-Book
update/re-freeze/WP-00. Frozen v1.4 `88129099` (tree `a2617649`) immutable· `RAW-JOURNAL` ανέγγιχτο·
pinned `.out` (`4873e610`) αμετάβλητο· `history.sexp`/`output/.healthy` δεν άλλαξαν.

## Οι πέντε διορθώσεις (before → after)

- **F1 — content-hash dependency cycle.** Legal-IR IDs = hash(BODY). Το `ArgumentRecord/1` έχει `claim_ref`
  ΚΑΙ το `ClaimRecord/1` είχε `argument_refs[]` ⇒ `ClaimID ↔ ArgumentID` κύκλος. **Fix:** αφαιρέθηκε το
  `argument_refs` από το hash-bearing `ClaimRecord/1` body· `claim_id = hex(sha256(id_domain ‖ 0x1F ‖
  canonical(BODY)))` χωρίς καμία αναφορά argument· `define-construction-order legal-ir-interpretive`
  (Profile → statement → Claim → Argument → index)· το `ArgumentRecord.claim_ref` δείχνει σε **ήδη
  υπάρχον** `claim_id`· αντίστροφη αναζήτηση = derived `ClaimArgumentIndex` projection (όχι μέρος
  ταυτότητας)· `define-ref-targets` (hash-bearing edges) + **πραγματικός** type-dependency cycle detector
  (V5F1) — αποδεδειγμένα non-vacuous (injected back-edge ⇒ cycle detected). Invariant `V5I-C1-acyclic`.
- **F2 — residual assumption as trust bypass.** Το `V5I-01` επέτρεπε SA-2 canonical με evidence **ή**
  assumption. **Fix:** `define-gate SA-2-canonical-admission` απαιτεί **έγκυρο** `DerivationIndependence
  Evidence/1` και `:forbids-alternative residual_independence_assumption`· η υπόθεση κρατά record **το
  πολύ** σε `CANDIDATE/UNKNOWN/QUARANTINED`, **ποτέ** `CANONICAL`/`PUBLISHED` machine-reliance· δομικό
  invariant `V5I-D1-no-assumption-canonical` (η πύλη δεν έχει assumption εναλλακτική).
- **F3 — coverage-state shadow.** Το v1.5 όριζε `coverage_state {PRESENT, EXPLICITLY_ABSENT, UNKNOWN}` που
  **σκίαζε** το παγωμένο v1.4 `state {INGESTED, EXPLICITLY-ABSENT, QUARANTINED, UNKNOWN}`. **Fix:**
  αφαιρέθηκε το shadow· `define-frozen-enum-reference census_coverage_state` επαναχρησιμοποιεί το παγωμένο
  enum **ακριβώς** (`INGESTED` δεν → `PRESENT`· `QUARANTINED` διατηρημένο)· `observation_state`/
  `availability_state` = χωριστές διαστάσεις που **χαρτογραφούνται** (`dimensions->census_coverage_state`)·
  **cross-spec conflicting-enum** audit (V5F3) συγκρίνει v1.4 `state` == v1.5 reference. Invariant `V5I-05`.
- **F4 — control-domain algorithm insufficient input.** Ένα `control_domain_id` + opaque refs δεν εκφράζουν
  όλες τις dimension σχέσεις. **Fix:** normalized per-dimension `DomainAssertion/1{dimension, subject_actor_id,
  subject_kid, normalized_domain_id, relation, source_evidence_ref, issuer_id, valid_from/to,
  revocation_ref, digest, signature}` = το **typed input** του partition· UNKNOWN pairwise ⇒ fail-closed
  edge· `TrustedIssuerRegistry/1` **versioned + content-addressed + pinned** από LocalTrustState
  (`trusted-issuer-registry-pinning`)· ρητό ποιος υπογράφει το `ActorIndependenceEvidence` και πώς το
  `evidence_issuer` επιλέγει κλειδί (`V5I-D3-issuer-signing`, `V5I-D3-domainassertion`).
- **F5 — opaque interpretive canons.** Το `InterpretiveProfile/1` είχε `(:methodology_canons (list canon))`.
  **Fix:** typed `CanonRule/1{canon_id, version, canon_kind, applicability, authority_basis, source_anchors,
  adoption_status}` + adopted scoped `CanonPolicy/1{ordering, conflict_policy_bundle_ref, ...}` που
  **delegates** στο **υπάρχον** v1.4 `ConflictPolicyBundle` (§4.17)· καμία επινοημένη καθολική ελληνική
  προτεραιότητα· απών ⇒ `UNKNOWN(no-applicable-conflict-policy)`, ασύμβατα ⇒ `CONFLICTING`
  (`V5I-C1-canon`)· **καμία** νέα μηχανή/έδρα (επαναχρήση argument engine + ConflictPolicyBundle).

## Audit (τίμια ταξινομημένο)
`V1.5-CONTRADICTION-OMISSION-AUDIT.sh` = **64/64 exit 0**: 43 document/reference + 16 V5S structural + **5
V5F** (F1 cycle detector· F2 no-assumption gate· F3 cross-spec conflicting-enum· F4 DomainAssertion+pinned
registry· F5 typed canons). Ρητά **parse-level structural/type consistency μόνο** — **ΟΧΙ** semantic/legal/
security ή qualification proof· **κανένα** `V5Q`/`V5KW` δεν εκτελείται. Ο F1 cycle detector αποδείχθηκε
non-vacuous (injected `ClaimRecord→ArgumentRecord` back-edge ⇒ cycle detected, verdict 0).

## Integration
`TRACEABILITY-MATRIX §v1.5` +5 `V5R-F1..F5` (σύνολο 22)· `QUALIFICATION-TESTS §10` +`V5KW-C1-9`+`V5KW-F2..F5`
+`V5Q-F1..F5` (σύνολο 22)· `THREAT-MODEL Θ19` F4-refined (DomainAssertion + pinned registry)· V5R-D2-08 /
V5R-C1-07 / V5KW-D2-8 / V5KW-C1-7 rows διορθωμένα στην επισκευασμένη δομή. Όλα additive/UNEXECUTED με
πρόθεμα `V5*` ⇒ οι v1.4 μετρήσεις (R-01..134, Q01..43, 109 KW) αμετάβλητες.

## Αρχεία (8 τροπ., 1 νέο — κανένα νέο seat)
`V1.5-SCHEMAS.sexp`, `CHANGE-PROPOSAL-v1.5.md` (§2.4/§11.1/§11.3/§11.4/§11.5/§11.7/§12),
`MACHINE-LEGAL-TRUST-PROTOCOL.md` (§15 F4), `LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md` (§12 F1/F5),
`TRACEABILITY-MATRIX.md`, `PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md`, `LAWMAX-THREAT-MODEL.md`,
`V1.5-CONTRADICTION-OMISSION-AUDIT.sh` (V5F block + realigned V5S04/10/14 + D2c), `V1.5-NARROW-DELTA-
MANIFEST.md` (re-pin + §5-bis). Νέο: `dialogue/0149-claude.md` + AI-DIALOGUE row 139. **Δεν αγγίχθηκαν:**
`source/ systems/ .github/ deployment/verify/mltp3/ RAW-JOURNAL history.sexp output/.healthy
IMPLEMENTATION-BOOK/`· ούτε `LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md`/`LAWMAX-ARCHITECTURE-CONSTITUTION.sexp`
/SourceType/USC/CPEI αυτή τη φορά.

## Regressions
- **Frozen v1.4** σε isolated worktree του `88129099`: `V1.4-CONTRADICTION-OMISSION-AUDIT.sh` = **158/158
  exit 0**· **working tree** v1.4 = **158/158 exit 0**· **v1.5** = **64/64 exit 0**.
- Frozen `88129099` immutable (tree `a2617649`)· 7 frozen seat hashes αμετάβλητα· pinned `.out`
  (`4873e610`) αμετάβλητο.

**ΕΤΥΜΗΓΟΡΙΑ: `V1.5 REPAIR COMPLETE — READY FOR BOUNDED ADVERSARIAL REVIEW`.** Καμία re-freeze/book-update/
WP-00/implementation χωρίς νέα ρητή εντολή δημιουργού. Στάση.
