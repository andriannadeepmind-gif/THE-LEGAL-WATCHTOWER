# CHANGE-PROPOSAL-v1.5 — LAWMAX OMEGA — THE LEGAL WATCHTOWER OF GREECE
# NARROW-DELTA SUCCESSOR CANDIDATE OF v1.4 (CANDIDATE · NOT FROZEN · NOT QUALIFIED · IMPLEMENTATION BLOCKED)

**ΚΑΤΑΣΤΑΣΗ:** μοναδικός successor candidate του `CHANGE-PROPOSAL-v1.4.md`. Parent commit
`182399b10e834546bb79faddb353de82ab5dec62`. Frozen v1.4 baseline `88129099be1ad69feb80d40337ede6c286b83223`
**αμετάβλητο** (κανένα amend/rewrite/σιωπηρή μεταβολή). Ο μοναδικός στόχος παραμένει **LAWMAX OMEGA —
THE LEGAL WATCHTOWER OF GREECE**. Το `AION` **απορρίπτεται** ως brand/προϊόν/σχολή/maturity ladder/
δεύτερη αρχιτεκτονική — δεν εμφανίζεται ως ενεργή αρχιτεκτονική εδώ.

## 0. ΕΥΡΟΣ (αυστηρά περιορισμένο) ΚΑΙ ΜΗ-ΣΤΟΧΟΙ
Ενσωματώνει **αποκλειστικά** τέσσερα deltas — κανένα πέμπτο, κανένας νέος axis, καμία αλλαγή
μακροαρχιτεκτονικής:
- **D1** Assurance-Profiled Independent Semantic Admission (έδρα: Secure Ingress / adoption).
- **D2** Typed Census Enumerability + Negative-Evidence Semantics (έδρες: Census / SourceType / USC).
- **D3** Evidence-Backed Independence Quorums (έδρα: MLTP / LocalTrustState / qualification).
- **C1** Interpretive Profile / Argument cross-document closure (σύνδεση υπαρχόντων εδρών· ΟΧΙ νέος engine/primitive).

**Δεν δημιουργεί:** δεύτερο canonical journal· δεύτερο Legal Digital Twin· δεύτερο reasoning engine·
πολλαπλές competing canonical realities· νέο datastore· νέο AION document/brand· νέα L0–L10 κλίμακα·
universal agent swarm· universal semantic N-version processing. **Δεν αλλάζει** production/source code,
workflows, ή τον executable MLTP core. Machine-readable form: `V1.5-SCHEMAS.sexp` (canonical s-expr).

## 1. D1 — INDEPENDENT SEMANTIC ADMISSION
**Έδρα:** `LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md` (adoption boundary), §9 appendix. Δεν επιβάλλει
**universal N-version processing**· η υποχρέωση κλιμακώνεται με το **assurance profile του state effect**.

### 1.1 `SemanticAdmissionAssuranceProfile` (κλειστό)
| profile | σημασία | υποχρέωση |
|---|---|---|
| **SA-0 STRUCTURAL** | δομικό/anchor-only (δεν μεταβάλλει κατάσταση) | schema + anchors μόνο |
| **SA-1 CHECKABLE** | παραγόμενο & ελέγξιμο | derivation + **μικρός ανεξάρτητος checker** |
| **SA-2 STATE_MUTATING** | μεταβάλλει την κανονική νομική κατάσταση | **ανεξάρτητη source→event derivation** + divergence gate + adoption act |

### 1.2 `SemanticAdmissionEvidence/1` (υποχρεωτικά πεδία)
`candidate_id · assurance_profile · source_manifestation_id · source_anchors · derivation_family_id ·
derivation_artifact_digest · transformation_proof_ref · independent_check_ref (SA-1/SA-2) ·
independent_derivation_ref (SA-2) · divergence_state · adoption_act_ref (SA-2) · policy_ref · schema_id · version`.

### 1.3 Event kinds → assurance (πλήρης ταξινόμηση· §12.2)
- **SA-0** (structural): `ANCHOR, CITATION_ANCHOR, OBSERVATION`.
- **SA-1** (checkable, source-verifiable, non-mutating): `CLASSIFICATION, CROSS_REFERENCE,
  LATER_TREATMENT_EXTRACTION` (D1.5: επαληθεύσιμη από ρητή παραπομπή στο κείμενο).
- **SA-2** (state-mutating — μεταβάλλουν την κανονική in-force / authority / effectivity κατάσταση):
  `ENACTMENT, AMENDMENT, COMMENCEMENT, REPEAL, SUSPENSION, REVIVAL, ANNULMENT, CORRECTION,
  DELEGATED_AUTHORITY_CHANGE, REGIME_EFFECTIVITY_TRANSITION, CONSTITUTIONAL_REVIEW_STATE_CHANGE,
  JUDICIAL_REVIEW_STATE_CHANGE, LINE_OF_AUTHORITY_MUTATION` (D1.5: υιοθετημένη μεταβολή του authority
  graph, διακριτή από την SA-1 extraction).

### 1.4 Πότε τι αρκεί
- **SA-1**: derivation + **μικρός ανεξάρτητος checker** (διαφορετικού μηχανισμού) που επαληθεύει το
  παραγόμενο έναντι των anchors — αρκεί όταν το αποτέλεσμα είναι **ελέγξιμο** χωρίς επαναπαραγωγή.
- **SA-2**: απαιτείται **ανεξάρτητη source→event derivation** (χωριστό `derivation_family_id` +
  `derivation_artifact_digest`), όχι απλός re-check του ίδιου artifact.

### 1.5 Τι αποδεικνύει **πραγματική** diversity μηχανισμού
Διακριτό `derivation_family_id` **ΚΑΙ** διακριτό `derivation_artifact_digest` πάνω σε **ανεξάρτητη
source→event διαδρομή**. **Αποφυγή «δύο binaries πάνω στο ίδιο σφάλμα/spec»:** ίδιο family ή ίδιο
artifact digest ⇒ `INDEPENDENCE_INSUFFICIENT` (η συμφωνία τους δεν μετρά ως diversity).

### 1.6 Deterministic divergence ≠ interpretive disagreement
`DivergenceState` (κλειστό): `AGREED · DETERMINISTIC_DIVERGENCE · INTERPRETIVE_DISAGREEMENT ·
INDEPENDENCE_INSUFFICIENT · UNKNOWN`.
- `DETERMINISTIC_DIVERGENCE`: οι ανεξάρτητες derivations διαφωνούν σε **ντετερμινιστικό γεγονός**
  (π.χ. αριθμός άρθρου/ημερομηνία) ⇒ **`QUARANTINED`**.
- `INTERPRETIVE_DISAGREEMENT`: **νόμιμη νομική διαφωνία** ⇒ **ΟΧΙ compiler error, ΟΧΙ majority vote**·
  παραμένει typed hypothesis/argument/`UNKNOWN`/`CONFLICTING` στην υπάρχουσα **L5/L6** έδρα (C1).

### 1.7 Invariant (hard) — V5I-01
`SA-2 MUST NOT transition ADOPTED → CANONICAL unless its semantic-admission evidence obligation is
satisfied.` Ένα **schema-valid αλλά λάθος** state-mutating γεγονός γίνεται **`QUARANTINED`**, **ακόμη
κι αν οι downstream compilers συμφωνούν** (η συμφωνία compilers δεν υποκαθιστά τη semantic admission).

## 2. D2 — CENSUS ENUMERABILITY + NEGATIVE-EVIDENCE SEMANTICS
**Έδρες:** `LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md` §5 appendix, `LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md`
§13 appendix. Δύο **χωριστές** διαστάσεις + αυστηρή negative-evidence σημασιολογία.

### 2.1 `enumerability_class` (κλειστό)
`AUTHORITATIVE_COMPLETE_INDEX · AUTHENTICATED_SERIAL_SPACE · AUTHORITATIVE_PARTIAL_INDEX ·
OBSERVATIONAL_OPEN_WORLD_SOURCE · UNKNOWN`.

### 2.2 `availability_class` (κλειστό)
`PUBLICLY_AVAILABLE · LEGALLY_UNAVAILABLE_OR_NON_PUBLIC · ACCESS_RESTRICTED · LICENSING_RESTRICTED · UNKNOWN`.

### 2.3 Πεδία `CensusSpaceClassification/1`
`space_id · enumerability_class · availability_class · negative_evidence_policy · authoritative_index_ref ·
serial_authority_ref · completeness_assertion_ref · gap_evidence_requirements · valid_from · valid_to ·
revocation_correction_semantics`.

### 2.4 Coverage-state ΤΥΠΟΣ + gap rules (type-closed· §12.3· **F3 repair**)
**Απόφαση τύπου (D2.4 / F3):** το v1.5 **ΔΕΝ** ορίζει δικό του coverage-state τύπο. Ο κανονικός
census/coverage state είναι ο **παγωμένος v1.4** (CHANGE-PROPOSAL-v1.4.md §4.1, `88129099`):
`census_coverage_state = {INGESTED, EXPLICITLY-ABSENT, QUARANTINED, UNKNOWN}` — **επαναχρησιμοποιείται
ακριβώς** (το `INGESTED` **δεν** μετονομάζεται σε `PRESENT`· το `QUARANTINED` **δεν** αφαιρείται). Τα
`NOT_OBSERVED_IN_DECLARED_SOURCE` και `COVERED_STATE_NON_PUBLIC` είναι **χωριστές διαστάσεις**
`observation_state`/`availability_state` που **χαρτογραφούνται** στο παγωμένο enum
(`dimensions->census_coverage_state`), **ποτέ** μέλη του.
- observed ⇒ `INGESTED`.
- `EXPLICITLY-ABSENT` **μόνο** με **fresh authenticated `NegativeEvidence/1`** πάνω σε
  `AUTHORITATIVE_COMPLETE_INDEX`, ή σε `AUTHENTICATED_SERIAL_SPACE` **όπου** ο κανόνας
  `serial_position_semantics_ref` **αποδεικνύει** ότι το κενό δεν μπορεί να είναι
  reserved/void/cancelled/legally-unused (D2.2).
- `DETERMINISTIC_DIVERGENCE` (D1 admission) ⇒ `QUARANTINED` (διατηρημένο μέλος).
- serial gap χωρίς τέτοια απόδειξη ⇒ `UNKNOWN` (fail-closed).
- partial index gap ⇒ `observation_state = NOT_OBSERVED_IN_DECLARED_SOURCE` ⇒ `UNKNOWN`.
- open-world gap ⇒ `UNKNOWN`.
- legally non-public ⇒ `availability_state = COVERED_STATE_NON_PUBLIC` ⇒ `UNKNOWN` (**όχι** crawler failure).
- expired/missing completeness assertion / insufficient negative evidence ⇒ `UNKNOWN`.

### 2.5 Invariants — V5I-04 / V5I-05
Η **μη εμφάνιση** μιας δικαστικής απόφασης σε **επιλεκτική** πηγή **δεν** αποδεικνύει ότι δεν υπάρχει.

## 3. D3 — EVIDENCE-BACKED INDEPENDENCE QUORUMS
**Έδρα (μία):** `MACHINE-LEGAL-TRUST-PROTOCOL.md` §15 appendix (§10 mesh) + `LocalTrustState` + qualification.

### 3.1 `ActorIndependenceEvidence/1` (δεσμεύει· `evidence_type ∈ IndependenceDimension`)
`actor_identity · evidence_issuer · evidence_type · valid_from/valid_to · legal_beneficial_control_evidence ·
privileged_administration_evidence · key_custody_evidence · infrastructure_dependency_evidence ·
conflict_of_interest_evidence · digest · signature · revocation_ref`.

### 3.2 `IndependencePolicy/1` (ορίζει)
`required_distinct_dimensions · prohibited_shared_dimensions · accepted_evidence_issuers ·
evidence_freshness · unknown_handling · assurance_profile · quorum`.

### 3.3 Κανόνες
Διαφορετικά `kid` **δεν** αποδεικνύουν ανεξαρτησία· self-signed independence declaration **δεν** μετρά·
expired/revoked evidence **δεν** μετρά· ανεπαρκές evidence ⇒ **`INDEPENDENCE_UNKNOWN`**· ο
**consumer-local** verifier αποφασίζει την policy· το LAWMAX/οι auditors **δεν** αυτοπιστοποιούν την
ανεξαρτησία τους· shared provider/cloud **δεν** έχει **καθολικό** αποτέλεσμα — αξιολογείται **ανά
assurance profile και control domain**.

### 3.4 Αλλαγή quorum (μία έδρα, καμία δεύτερη)
Βάση (delta): `distinct-valid-kids` → `distinct-valid-kids AND satisfies(local_independence_policy,
accepted_evidence)`. **Type-closed (§11.4 D3.7, κανονιστικό):** το `satisfies` αναλύεται ρητά σε
`|distinct-components(control-domain-partition(valid))| ≥ quorum.n AND covers(required_distinct_dimensions)
AND no-prohibited-shared-dimension AND (FAIL_CLOSED ⇒ κανένα UNKNOWN counted)` — η μέτρηση είναι
**distinct control-domain components**, ΟΧΙ distinct `kid`. Ίδια **μία** έδρα (`define-quorum-predicate
mesh-independence-quorum`).

## 4. C1 — INTERPRETIVE PROFILE CLOSURE
**ΔΕΝ** είναι τέταρτο architectural delta, **ΔΕΝ** δημιουργεί νέο reasoning engine ή top-level
constitutional primitive. Συνδέει καθαρά: Architecture Constitution **`:argument`** · CPEI **L6
Adversarial Parliament** · Legal IR · Claim/Hypothesis · Proof/Counterproof · InstitutionalAct · proof
dependency graph. Έδρες: `LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md` §12, `LAWMAX-CPEI-TARGET-SPEC.md` §7,
`LAWMAX-ARCHITECTURE-CONSTITUTION.sexp` (comment pointer).

### 4.1 Ελάχιστος τύπος
`InterpretiveProfile/1{profile_id, version, scope, source_anchors}` (versioned/scoped)·
`ArgumentRecord/1{argument_id, interpretive_profile_ref, argument_ref (→ existing :argument),
proof_ref, counterproof_ref, adoption_act_ref?}`.

### 4.2 Συνύπαρξη
Competing interpretations συνυπάρχουν: `Claim-X → Profile-A`, `Claim-Y → Profile-B`, **χωρίς ψευδή
επιλογή νικητή**. Η **InstitutionalAct adoption** αλλάζει **institutional/epistemic status**, **ΟΧΙ την
αντικειμενική «αλήθεια»** μιας ερμηνείας (V5I-08/09).

## 5. TRUST & PUBLIC TIME (invariants — αμετάβλητη διατύπωση)
`NO SINGLE POINT OF BLIND TRUST — ALL TRUST ASSUMPTIONS EXPLICIT, MINIMIZED, SCOPED AND, WHERE POSSIBLE,
INDEPENDENTLY VERIFIABLE.` (Το απόλυτο «no-required-trust» claim — πλήρης απουσία απαιτούμενης εμπιστοσύνης — **δεν** χρησιμοποιείται.) De jure boundary
αμετάβλητο: Κράτος/δικαστήρια εκδίδουν· LAWMAX/auditors επαληθεύουν authenticity/representation/process/
publication, δεν υποκαθιστούν sovereign authority. Ο operational χρόνος του Ιδρύματος παραμένει στο
internal audit layer· public/API outputs εκθέτουν legal timeline, release-as-of, freshness — **όχι**
εσωτερική acquisition/monitoring activity.

## 6. ERROR TAXONOMY + STATE-TRANSITION RULES (v1.5, διακριτά)
```
D1: semantic-admission-obligation-unmet · deterministic-extraction-divergence · common-family-derivation ·
    interpretive-disagreement-miscast-as-mechanical · assurance-profile-mismatch
D2: absence-without-authenticated-negative-evidence · partial-index-gap-miscast-as-absent ·
    open-world-gap-miscast-as-absent · non-public-miscast-as-crawler-failure · expired-completeness-assertion
D3: kid-difference-miscast-as-independence · shared-control-domain-undetected · self-signed-independence ·
    expired-or-revoked-independence-evidence · bundle-attempts-consumer-policy-override
C1: profile-indistinct-conclusions · interpretive-conclusion-without-profile-ref ·
    adoption-presented-as-objective-truth · hidden-free-text-interpretive-premise
```
State transitions (SA-2): `PARSED → VALIDATED → (SemanticAdmissionEvidence obligation) → ADOPTED →
(InstitutionalAct) → CANONICAL`. Any unmet obligation or `DETERMINISTIC_DIVERGENCE` ⇒ `QUARANTINED`
(monotone, journaled). `INTERPRETIVE_DISAGREEMENT` ⇒ stays typed argument in L5/L6 (no transition to error).

## 7. TRACEABILITY (κάθε requirement → seat → test → evidence)
| req | delta | seat | test | evidence |
|---|---|---|---|---|
| V5R-D1-01 | D1 | Secure Ingress §9 | V5Q-01, V5KW-D1-1 | SemanticAdmissionEvidence records |
| V5R-D1-02 | D1 | Secure Ingress §9 | V5KW-D1-2 | derivation_family/digest diversity |
| V5R-D1-03 | D1 | Secure Ingress §9 | V5KW-D1-3 | independent_derivation_ref present |
| V5R-D1-04 | D1 | L5/L6 | V5KW-D1-4 | typed argument (not error) |
| V5R-D1-05 | D1 | Secure Ingress §9 | V5KW-D1-5 | SA-0 not over-burdened |
| V5R-D2-01 | D2 | SourceType §5 | V5Q-02, V5KW-D2-1 | enumerability/availability classes |
| V5R-D2-02 | D2 | USC §13 | V5KW-D2-2 | authenticated negative evidence |
| V5R-D2-03 | D2 | SourceType §5 | V5KW-D2-3 | non-public coverage state |
| V5R-D2-04 | D2 | SourceType §5 | V5KW-D2-4 | expired completeness ⇒ UNKNOWN |
| V5R-D2-05 | D2 | SourceType §5 | V5KW-D2-5 | UNKNOWN classification handled |
| V5R-D3-01 | D3 | MLTP §15 | V5Q-03, V5KW-D3-1 | ActorIndependenceEvidence |
| V5R-D3-02 | D3 | MLTP §15 | V5KW-D3-2 | shared control domain detected |
| V5R-D3-03 | D3 | MLTP §15 | V5KW-D3-3 | self-signed rejected |
| V5R-D3-04 | D3 | MLTP §15 | V5KW-D3-4 | expired/revoked rejected |
| V5R-D3-05 | D3 | MLTP §15 | V5KW-D3-5 | INDEPENDENCE_UNKNOWN under strict profile |
| V5R-D3-06 | D3 | LocalTrustState | V5KW-D3-6 | consumer-local policy wins |
| V5R-C1-01 | C1 | Legal-IR §12 | V5Q-04, V5KW-C1-1 | profile-distinct conclusions |
| V5R-C1-02 | C1 | Legal-IR §12 | V5KW-C1-2 | profile_ref mandatory |
| V5R-C1-03 | C1 | CPEI §7 (L6) | V5KW-C1-3 | adoption ≠ objective truth |
| V5R-C1-04 | C1 | Legal-IR §12 | V5KW-C1-4 | no hidden free-text premise |

## 8. PREDECLARED QUALIFICATION TESTS + KILL WITNESSES (design-level· ΜΗ εκτελεσμένα)
**Qualification tests (predeclared):** V5Q-01 (D1 admission obligation), V5Q-02 (D2 coverage-state
correctness), V5Q-03 (D3 evidence-backed quorum), V5Q-04 (C1 profile distinction). **Καμία εκτέλεση, καμία
αξίωση qualification, κανένα destruction pass τώρα.**

**Kill witnesses (υποχρεωτικά, predeclared):**
- **D1:** V5KW-D1-1 schema-valid wrong target/date σε SA-2 extractor ⇒ QUARANTINED· V5KW-D1-2 δύο
  nominally different αλλά common-family derivations ⇒ INDEPENDENCE_INSUFFICIENT· V5KW-D1-3 missing
  independent evidence ⇒ obligation-unmet· V5KW-D1-4 interpretive disagreement miscast as mechanical
  divergence ⇒ red· V5KW-D1-5 SA-0 αντικείμενο λανθασμένα επιβαρυμένο ως SA-2 ⇒ red.
- **D2:** V5KW-D2-1 gap σε partial judicial portal ⇒ NOT_OBSERVED_IN_DECLARED_SOURCE· V5KW-D2-2
  authenticated gap σε complete index ⇒ EXPLICITLY-ABSENT (μόνο τότε)· V5KW-D2-3 non-public/restricted ⇒
  coverage state, όχι crawler failure· V5KW-D2-4 expired completeness assertion ⇒ UNKNOWN· V5KW-D2-5
  unknown source classification ⇒ UNKNOWN handled.
- **D3:** V5KW-D3-1 διαφορετικά keys με ίδιο accepted controller ⇒ όχι independence· V5KW-D3-2 κοινός
  privileged administrator/HSM custody ⇒ shared dimension detected· V5KW-D3-3 self-signed independence ⇒
  rejected· V5KW-D3-4 expired/revoked evidence ⇒ rejected· V5KW-D3-5 unknown control domain υπό strict
  profile ⇒ INDEPENDENCE_UNKNOWN· V5KW-D3-6 bundle που επιχειρεί να αλλάξει consumer-local policy ⇒ rejected.
- **C1:** V5KW-C1-1 δύο conclusions με διαφορετικά profiles που ο verifier δεν διακρίνει ⇒ red· V5KW-C1-2
  interpretive conclusion χωρίς profile reference ⇒ red· V5KW-C1-3 adoption ως απόδειξη αντικειμενικής
  αλήθειας ⇒ red· V5KW-C1-4 hidden free-text interpretive premise ⇒ red.

## 9. DELTA IMPACT MATRIX → WORK PACKETS (ΧΩΡΙΣ τροποποίηση των WP αρχείων)
| delta | affected WP (v1.1 map, unmodified) | nature of impact |
|---|---|---|
| D1 | WP-02 (Secure Ingress/adoption), WP-08 (admission gate), WP-11 (proof-carrying answer surface) | adds SemanticAdmissionEvidence obligation to SA-2 promotion |
| D2 | WP-01 (census/coverage ledger), WP-02 (source-type classification) | adds enumerability/availability + negative-evidence semantics to coverage states |
| D3 | WP-06 (MLTP mesh/quorum), WP-14 (independence at qualification) | quorum predicate gains evidence-backed independence test |
| C1 | WP-08 (reasoning/L6), WP-09 (jurisprudence adoption) | binds InterpretiveProfile/ArgumentRecord to existing :argument/L6 |
**Τα WP αρχεία (`IMPLEMENTATION-BOOK/WORK-PACKETS/`) ΔΕΝ τροποποιούνται** — αυτός ο πίνακας είναι
προαναγγελία επιπτώσεων για πιθανό re-freeze, όχι εφαρμογή.

## 10. AFFECTED NORMATIVE SEATS (v1.5 additive appendices, CANDIDATE)
`LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md` §9 (D1) · `LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md`
§5 (D2) · `LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md` §13 (D2) · `MACHINE-LEGAL-TRUST-PROTOCOL.md` §15 (D3) ·
`LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md` §12 (C1) · `LAWMAX-CPEI-TARGET-SPEC.md` §7 (C1) ·
`LAWMAX-ARCHITECTURE-CONSTITUTION.sexp` (comment pointer, C1). Machine-readable: `V1.5-SCHEMAS.sexp`.
Each appendix is **additive** and marked CANDIDATE — the frozen v1.4 content above it is unchanged, and
the frozen commit `88129099` is not amended.

## 11. SEMANTIC TYPE-CLOSURE (v1.5 micro-pass) — closed D1/D2/D3/C1 types
Machine-readable: `V1.5-SCHEMAS.sexp` (type-closed). Machine-checkable structural checks:
`V1.5-CONTRADICTION-OMISSION-AUDIT.sh` block **V5S** (schema/cardinality/reference parse — structural,
not semantic proof).

### 11.1 D1 — per-profile cardinality of every `SemanticAdmissionEvidence/1` field (R=required · F=forbidden · C=conditional)
| field | SA-0 | SA-1 | SA-2 |
|---|---|---|---|
| candidate_id · assurance_profile · source_manifestation_id · source_anchors · policy_ref · schema_id · version | R | R | R |
| derivation_family_id · derivation_artifact_digest | **F** | R | R |
| transformation_proof_ref | **F** (D1.2: δεν υπάρχει transformation για SA-0) | R | R |
| independent_check_ref | **F** | R | R |
| independent_derivation_ref | **F** | **F** | **R** |
| divergence_state | **F** | R | R |
| derivation_independence_evidence_ref | **F** | **F** | **C** (XOR με residual) |
| residual_independence_assumption | **F** | **F** | **C** (required αν independence δεν αποδεικνύεται) |
| adoption_act_ref | **F** | **F** | **R** |
- **D1.2 resolved:** `transformation_proof_ref` **forbidden** για SA-0 (structural/anchors-only — καμία transformation).
- **D1.3 (μία rationale):** SA-2 απαιτεί **και** `independent_check_ref` **και** `independent_derivation_ref`
  γιατί καλύπτουν **ξένα** failure modes — ο check αποδεικνύει ότι το γεγονός είναι source-**checkable**
  από distinct μηχανισμό (πιάνει self-consistent αλλά source-inconsistent derivation)· η independent
  **re-derivation** πιάνει shared-spec/shared-artifact σφάλματα που ο check δεν πιάνει. Κανένα δεν
  υποκαθιστά το άλλο.
- **D1.6:** πραγματική independence = `DerivationIndependenceEvidence/1` (distinct specification source
  **και** provenance/toolchain **και** failure domain)· distinct `family_id`/`digest` **μόνο** ⇒
  `INDEPENDENCE_INSUFFICIENT`· αν υποτίθεται χωρίς απόδειξη, `residual_independence_assumption` το
  καταγράφει **ρητά**.
- **F2 (residual assumption ≠ trust bypass):** η SA-2 προαγωγή `ADOPTED→CANONICAL` απαιτεί **έγκυρο**
  `DerivationIndependenceEvidence/1` — η πύλη `SA-2-canonical-admission` **δεν** έχει assumption
  εναλλακτική (`:forbids-alternative residual_independence_assumption`). Το `residual_independence_assumption`
  κρατά record **το πολύ** σε `CANDIDATE/UNKNOWN/QUARANTINED`· **ποτέ** δεν προάγει σε `CANONICAL` ή σε
  `PUBLISHED` machine-reliance (invariant `V5I-D1-no-assumption-canonical`).

### 11.2 D1.4 — πλήρης state-mutating κατάλογος (όλα SA-2)
`ENACTMENT · AMENDMENT · COMMENCEMENT · REPEAL · SUSPENSION · REVIVAL · ANNULMENT · CORRECTION ·
DELEGATED_AUTHORITY_CHANGE · REGIME_EFFECTIVITY_TRANSITION · CONSTITUTIONAL_REVIEW_STATE_CHANGE ·
JUDICIAL_REVIEW_STATE_CHANGE · LINE_OF_AUTHORITY_MUTATION`. **D1.5:** `LATER_TREATMENT_EXTRACTION` (SA-1,
source-verifiable) ≠ `LINE_OF_AUTHORITY_MUTATION` (SA-2, adopted authority-graph mutation).

### 11.3 D2 — `NegativeEvidence/1` + coverage-state type decision
`NegativeEvidence/1` είναι ο **τυποποιημένος** φορέας authenticated negative evidence (η `signature` +
`evidence_artifact_digest` το κάνουν authenticated· `expiry` το κάνει ληξιπρόθεσμο):
`NegativeEvidence/1{census_space_ref, issuing_authority_ref, source_ref, scope, observation_time,
completeness_or_serial_rule_ref, evidence_artifact_digest, expiry, signature}`. **D2.3:**
`AUTHENTICATED_SERIAL_SPACE` απαιτεί `serial_authority_ref` **και** `completeness_assertion_ref` **και**
`serial_position_semantics_ref`. **D2.4 (type-closed· F3):** το v1.5 **δεν** ορίζει coverage-state τύπο·
ο κανονικός census/coverage state είναι ο **παγωμένος v1.4** `census_coverage_state = {INGESTED,
EXPLICITLY-ABSENT, QUARANTINED, UNKNOWN}` (επαναχρησιμοποιείται ακριβώς)· `observation_state = {OBSERVED,
NOT_OBSERVED_IN_DECLARED_SOURCE, UNKNOWN}`· `availability_state = {PUBLIC_PRESENT, COVERED_STATE_NON_PUBLIC,
ACCESS_RESTRICTED, LICENSING_RESTRICTED, UNKNOWN}` — **διαστάσεις** που χαρτογραφούνται στο παγωμένο enum,
όχι μέλη του. **D2.2/D2.5:** serial gap ⇒ EXPLICITLY-ABSENT
**μόνο** αν ο serial κανόνας αποδεικνύει μη-reservable/void/cancelled/unused· αλλιώς + insufficient/
expired ⇒ UNKNOWN (fail-closed).

### 11.4 D3 — independence assurance, issuer registry, partition, quorum
- **D3.1:** χωριστό `IndependenceAssuranceProfile {IA-0 DECLARED, IA-1 ATTESTED, IA-2 CRYPTO_BOUND}`
  (≠ `SemanticAdmissionAssuranceProfile`)· `IndependencePolicy.min_independence_assurance` το χρησιμοποιεί.
- **D3.2:** `ActorIndependenceEvidence/1` δεσμεύει **κρυπτογραφικά** `actor_identity + actor_kid +
  actor_public_key + control_domain_id + evidence_subject_digest` (signature πάνω σε canonical BODY).
  **F4 (ποιος υπογράφει):** υπογράφει ο issuer του `evidence_issuer`· κλειδί επαλήθευσης = το
  `IssuerEntry.issuer_public_key` που επιλύεται στο **pinned** registry· self-issued (`evidence_issuer =
  actor_identity`) = IA-0 και **δεν** μετρά ως ανεξάρτητη βεβαίωση (invariant `V5I-D3-issuer-signing`).
- **F4/R5 (typed-membership partition input):** ο partition καταναλώνει typed **membership**
  `DomainAssertion/1{dimension, subject_actor_id, subject_kid, namespace_id, domain_identifier,
  normalized_domain_id, issuer_id, source_evidence_ref, valid_from/to, revocation_ref, digest, signature}` —
  «ο actor ανήκει στο domain identifier X, στο accepted namespace N, για dimension D». **Το unary
  `relation :same-domain|:distinct-domain|:unknown` αντικαταστάθηκε.** Domain identifiers συγκρίνονται μόνο
  εντός **ίδιου** namespace ή μέσω root-authorized `NamespaceEquivalence/1`· το `control_domain_id` είναι
  convenience summary, **ποτέ** input (invariant `V5I-D3-domainassertion`, §11.8/R5).
- **D3.3 (F4):** `TrustedIssuerRegistry/1` **versioned + content-addressed** (`registry_id =
  hash(BODY)`, `version`, `supersedes`, signature) + `IssuerEntry/1{issuer_id, issuer_public_key,
  issuer_authority, scope, delegated_from, valid_from/to, revocation_ref}`· **pinned** από
  `LocalTrustState.independence_issuer_registry_ref`· authenticity υπό pinned root· monotonic update· ένα
  bundle **δεν** αλλάζει το pinned registry (rule `trusted-issuer-registry-pinning`).
- **D3.4:** `revocation_ref` required όταν ο issuer υποστηρίζει revocation· ο verifier επιλύει revocation
  source· μη-επιλύσιμο υπό strict ⇒ UNKNOWN (fail-closed).
- **D3.5/R5:** `control-domain-partition` = union-find (ντετερμινιστικό) πάνω σε typed-membership
  `DomainAssertion/1`: `SHARED(a,b,d)` iff (ίδιο namespace + ίδιο normalized id) **ή** valid root-authorized
  `NamespaceEquivalence/1`· missing / unauthorized-namespace / cross-namespace-χωρίς-equivalence /
  contradictory / `:unknown` ⇒ ακμή (fail-closed)· components = independent control domains.
- **D3.6:** `unknown_handling ∈ {FAIL_CLOSED, DEGRADE}`· υπό FAIL_CLOSED, UNKNOWN actor **δεν** μετρά ποτέ
  σε strict quorum· υπό DEGRADE, ρητό downgrade, ποτέ σιωπηλό.
- **D3.7 (final quorum predicate):** `satisfies := |distinct-components(control-domain-partition(valid))|
  ≥ quorum.n AND covers(required_distinct_dimensions) AND no-prohibited-shared-dimension AND (FAIL_CLOSED
  ⇒ κανένα UNKNOWN counted)`· insufficient ⇒ `INDEPENDENCE_UNKNOWN`.

### 11.5 C1 — expanded interpretive types (no new engine/primitive)
- **C1.1 (F5/R6· single canon source):** `InterpretiveProfile/1{profile_id, version, **canon_policy_ref
  μόνο**, precedence_stance, applicability, authority_basis, conflict_handling, source_anchors}` — **καμία
  ενσωματωμένη `methodology_canons` λίστα** (R6). Ο **μοναδικός** κάτοχος = `CanonPolicy/1{policy_id, version,
  **canon_id_refs (list id) → CanonRule/1**, ordering, conflict_policy_bundle_ref, applicability,
  authority_basis}` (content-addressed refs, όχι embedded records)· `CanonRule/1{canon_id, version,
  canon_kind, applicability, authority_basis, source_anchors}` immutable· convenience list = derived
  `InterpretiveProfileCanons`. Ordering/conflict delegate στο v1.4 `ConflictPolicyBundle` (§4.17) — καμία
  επινοημένη προτεραιότητα· απών ⇒ `UNKNOWN`, ασύμβατα ⇒ `CONFLICTING` (`V5I-C1-canon`).
- **C1.2/C1.3 (R1):** `ArgumentRecord/1{argument_id, interpretive_profile_ref, claim_ref, premises[],
  conclusion, argument_scheme, source_anchors[], authority_scope, uncertainty, constitution_primitive=
  :argument}` — **αφαιρέθηκαν** τα `support_edges`/`attack_edges` (και το adoption) από το hash-bearing σώμα·
  οι σχέσεις argument↔argument είναι typed `ArgumentRelation/1{relation_id, relation, from_argument_ref,
  to_target_ref, to_target_kind}` κατασκευασμένη **μετά** τα δύο ids (καμία ArgumentID↔ArgumentID hash-cycle).
- **C1.4 (F1/R1/R8.1):** `ClaimRecord/1{claim_id, kind, statement_ref, **statement_kind (Norm|Fact)**,
  interpretive_profile_ref}` — **χωρίς** `argument_refs` **και χωρίς** `status` στο hash-bearing σώμα. Το
  `statement_ref` δείχνει σε υπάρχον epistemic node `Norm|Fact`. Το `ClaimRecord` κατασκευάζεται **πριν**
  κάθε `ArgumentRecord`· το `ArgumentRecord.claim_ref` δείχνει σε **ήδη υπάρχον** `claim_id`. Η αντίστροφη
  αναζήτηση claim→arguments είναι **derived projection** `ClaimArgumentIndex` πάνω στο υπάρχον
  proof-dependency graph (όχι μέρος της ταυτότητας claim). Σειρά: `define-construction-order
  legal-ir-interpretive`· ακυκλικότητα `V5I-C1-acyclic` (kill V5KW-C1-9).
- **C1.5:** αντικαταστάθηκε το inert Constitution comment με **formal machine-readable reference/invariant**
  `(v1.5-interpretive-binding :represents-primitive :argument :adds-primitive nil :adds-engine nil
  :adds-gate nil)` στο `LAWMAX-ARCHITECTURE-CONSTITUTION.sexp` — καμία νέα μηχανή/primitive/gate.

### 11.6 Closure requirements + kill witnesses (predeclared)
Νέες απαιτήσεις `V5R-D1-06..09, V5R-D2-06..08, V5R-D3-07..12, V5R-C1-05..08` (TRACEABILITY-MATRIX §v1.5)·
νέα kill witnesses `V5KW-D1-6..9, V5KW-D2-6..8, V5KW-D3-7..12, V5KW-C1-5..8`
(PUBLIC-OBSERVATORY-QUALIFICATION-TESTS §v1.5)· νέα απειλή Θ19 (correlated/common-control independence
failure, THREAT-MODEL). Όλα **predeclared, UNEXECUTED**.

### 11.7 F1–F5 INDEPENDENT-REVIEW REPAIR (bounded corrective pass πάνω στο `019c0d58`)
Ανεξάρτητη αντιπαλική επιθεώρηση falsified την «semantic closure» με **πέντε** ονομαστικούς μάρτυρες·
η μακροαρχιτεκτονική **δεν** απορρίφθηκε. Διορθώσεις (design-only, μία εντολή):
- **F1 content-hash dependency cycle:** αφαιρέθηκε το `argument_refs` από το hash-bearing `ClaimRecord/1`·
  ρητή ακυκλική σειρά `define-construction-order legal-ir-interpretive` (Claim πριν Argument)· αντίστροφη
  αναζήτηση = derived `ClaimArgumentIndex` projection· `define-ref-targets` + πραγματικός type-dependency
  cycle check (όχι απλό «argument_ref absent»). Requirement `V5R-F1`· witness `V5KW-C1-9`.
- **F2 residual assumption as trust bypass:** η πύλη `SA-2-canonical-admission` απαιτεί **έγκυρο**
  `DerivationIndependenceEvidence/1` και `:forbids-alternative residual_independence_assumption`· η υπόθεση
  κρατά record το πολύ σε `CANDIDATE/UNKNOWN/QUARANTINED`· `V5I-01` + `V5I-D1-no-assumption-canonical`.
  Requirement `V5R-F2`· witness `V5KW-F2`.
- **F3 coverage-state shadow:** αφαιρέθηκε το shadow `coverage_state {PRESENT, EXPLICITLY_ABSENT, UNKNOWN}`· επαναχρησιμοποιείται
  **ακριβώς** το παγωμένο v1.4 `census_coverage_state {INGESTED, EXPLICITLY-ABSENT, QUARANTINED, UNKNOWN}`
  (`define-frozen-enum-reference`)· dimensions ⇒ frozen enum. Requirement `V5R-F3`· witness `V5KW-F3`.
- **F4 control-domain input:** normalized per-dimension `DomainAssertion/1`· partition το καταναλώνει·
  `TrustedIssuerRegistry/1` versioned/content-addressed/pinned (`trusted-issuer-registry-pinning`)· ρητό
  ποιος υπογράφει + επιλογή κλειδιού (`V5I-D3-issuer-signing`, `V5I-D3-domainassertion`). Requirement
  `V5R-F4`· witness `V5KW-F4`.
- **F5 opaque canons:** typed `CanonRule/1` + adopted scoped `CanonPolicy/1` που delegates στο v1.4
  `ConflictPolicyBundle`· καμία επινοημένη προτεραιότητα· απών ⇒ UNKNOWN, ασύμβατα ⇒ CONFLICTING
  (`V5I-C1-canon`). Requirement `V5R-F5`· witness `V5KW-F5`.

Νέος audit block **V5F** (structural): cycle detection, cross-spec conflicting-enum, no-assumption-in-gate,
DomainAssertion inputs, typed canons. Τίμια: parse-level, **ΟΧΙ** semantic/legal proof.

### 11.8 R1–R8 FINITE ADVERSARIAL-REPAIR (bounded corrective pass πάνω στο `4a55a1eb`)
Δεύτερη ανεξάρτητη επιθεώρηση: 6 named finite blockers (A-1/A-2/B-1/B-2/C-1/D-1) + F7 + finite residuals·
η μακροαρχιτεκτονική **δεν** απορρίφθηκε. Design-only, μία εντολή, κανένα νέο axis/store/engine/primitive.
- **R1 (A-1· πλήρες ακυκλικό content-addressing):** αφαιρέθηκαν `support_edges`/`attack_edges` από το
  hash-bearing `ArgumentRecord/1`· argument↔argument = detached typed `ArgumentRelation/1` στο υπάρχον L5/L6
  proof-dependency graph (μετά τα δύο ids)· πλήρης `define-ref-classification` (κάθε ref-πεδίο άπαξ:
  hash-bearing/detached/derived) + `define-construction-order`· ο cycle audit παράγει edges από τα **πραγματικά
  record fields** και αποτυγχάνει σε unclassified πεδίο ή κύκλο· non-vacuity: Claim↔Argument, Argument↔Argument
  mutual-attack, CanonPolicy↔InterpretiveProfile — όλα ανιχνεύονται.
- **R2 (A-2· immutable identity· detached lifecycle):** ClaimRecord/ArgumentRecord/InterpretiveProfile/
  CanonRule/CanonPolicy immutable (κανένα adoption/withdrawal/status στο σώμα)· lifecycle = detached
  `LifecycleRecord/1` στο υπάρχον InstitutionalAct + L2 event-ledger/`audit-timeline/1` seat, κλειδωμένο στο
  αμετάβλητο `subject_id`· current status = projection `SubjectCurrentStatus`· adoption/withdrawal **ποτέ** δεν
  αλλάζει `*_id` (`V5I-A2-immutable-id`, kill V5KW-A2)· correction/revocation/supersession μέσω supersedes-chain.
- **R3 (B-1· total exclusive coverage):** `define-decision-function census-coverage-decision` με 8 typed inputs
  (observation/acquisition/validation/admission/divergence/availability/enumerability/negative_evidence),
  ordered precedence `QUARANTINED > INGESTED > EXPLICITLY-ABSENT > UNKNOWN`, `:otherwise ⇒ UNKNOWN`· `INGESTED`
  απαιτεί lawful acquisition+validation+admission (όχι απλό OBSERVED)· audit V5G απαριθμεί το πεπερασμένο
  γινόμενο (μηδέν uncovered, μηδέν multi-output, ένα state ανά combination).
- **R4 (B-2· D2 seat sync):** SourceType §5 + USC §13 συγχρονισμένα με schema/proposal — canonical spelling
  `EXPLICITLY-ABSENT`, `INGESTED`/`QUARANTINED` διατηρημένα, dimensions χαρτογραφούνται, `serial_position_
  semantics_ref` απαίτηση, dense-non-reservable rule αλλιώς UNKNOWN· audit ελέγχει **όλες** τις D2 έδρες.
- **R5 (C-1· namespaces):** το unary relation αντικαταστάθηκε από typed membership `DomainAssertion/1`
  (namespace_id + domain_identifier + normalized_domain_id)· `DomainNamespaceAuthorization/1` per dimension +
  content-addressed root-authorized `NamespaceEquivalence/1` στο pinned registry· cross-namespace μόνο με
  accepted equivalence, αλλιώς fail-closed· contradictory ⇒ INDEPENDENCE_UNKNOWN· issuer-scope checks.
- **R6 (D-1· μία canon list):** `CanonPolicy/1.canon_id_refs` = ο μοναδικός κάτοχος (content-addressed)·
  `InterpretiveProfile/1` **μόνο** `canon_policy_ref`· convenience = derived `InterpretiveProfileCanons`·
  lifecycle cardinalities (proposed/adopted/withdrawn) στο `lifecycle-overlay` rule.
- **R7 (F7· derivation trust root):** `DerivationIndependenceEvidence/1` δένει candidate+event+issuer+validity+
  freshness+revocation+signed body· VALID μόνο υπό MLTP qualification registry/trust root (καμία παράλληλη)·
  self/operator-issued default rejection· η SA-2 gate **επαληθεύει** (όχι απλή παρουσία reference).
- **R8 (residuals):** `statement` → closed `StatementTargetKind {Norm,Fact}`· `candidate_id` discipline
  (`candidate-id-discipline`)· `ClaimArgumentIndex` μία `:derivation`· MLTP §15 quorum prose τετρα-συζευκτικό·
  unregistered/future mutating event ⇒ SA-2/QUARANTINED (`V5I-D1-unregistered-event`).

Νέος audit block **V5G** (structural): field-classification completeness, actual-field cycle DAG + 3
injected cycles, immutable-id stability, coverage decision-table totality/exclusivity, D2 cross-seat
agreement, namespace-collision/contradiction, single canon list, lifecycle cardinalities, F7 validity,
quorum-predicate sync, F1–F5 + six-blocker regressions. Τίμια: structural/type/model, **ΟΧΙ** legal-content/
security/qualification proof· κανένα predeclared executable test εκτελεσμένο.

## 12. STATUS
`SPEC v1.5 NARROW-DELTA CANDIDATE — NOT FROZEN — NOT QUALIFIED — IMPLEMENTATION BLOCKED`. No re-freeze,
no Implementation Book update, no WP-00, no implementation without a new explicit creator order.
`V1.5 FINITE REPAIR COMPLETE — READY FOR SAME REVIEWER DELTA RE-TEST` (A-1/A-2/B-1/B-2/C-1/D-1/F7 and the
finite residuals are repaired structurally; subject to the predeclared, UNEXECUTED tests and the finite
unknowns recorded in the manifest).
