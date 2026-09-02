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

### 1.3 Event kinds → assurance
SA-0: `ANCHOR, CITATION_ANCHOR, OBSERVATION`. SA-1: `CLASSIFICATION, LATER_TREATMENT_LINK, CROSS_REFERENCE`.
SA-2: `ENACTMENT, AMENDMENT, COMMENCEMENT, REPEAL` (κάθε γεγονός που μεταβάλλει την in-force κατάσταση).

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

### 2.4 Αυστηροί κανόνες κενού (gap → coverage state)
- `EXPLICITLY_ABSENT` **μόνο** με **admissible authenticated negative evidence** πάνω σε
  `AUTHORITATIVE_COMPLETE_INDEX` ή `AUTHENTICATED_SERIAL_SPACE`.
- partial index gap ⇒ **`NOT_OBSERVED_IN_DECLARED_SOURCE`** (όχι absence).
- open-world gap ⇒ **`UNKNOWN`**.
- legally non-public υλικό ⇒ ρητό **coverage state** (`COVERED_STATE_NON_PUBLIC`), **όχι crawler failure**.
- expired/missing completeness assertion ⇒ **ποτέ** absence proof ⇒ `UNKNOWN`.

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
`distinct-valid-kids` → `distinct-valid-kids AND satisfies(local_independence_policy, accepted_evidence)`.

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
  authenticated gap σε complete index ⇒ EXPLICITLY_ABSENT (μόνο τότε)· V5KW-D2-3 non-public/restricted ⇒
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

## 11. STATUS
`SPEC v1.5 NARROW-DELTA CANDIDATE — NOT FROZEN — NOT QUALIFIED — IMPLEMENTATION BLOCKED`. No re-freeze,
no Implementation Book update, no WP-00, no implementation without a new explicit creator order.
