# WATCHTOWER VLT — TARGET ARCHITECTURE v0.2
**Layered Verifiable Legal Twin — μετά το Destruction Pass #1 (κοινό artifact Reviewer-A × Reviewer-B)**

**Status: DESIGN HYPOTHESIS.** Διάδοχος του v0.1: ενσωματώνει ΟΛΑ τα ευρήματα του Reviewer-B
Destruction Pass #1 (5 blockers, 9 MODIFY, ανακατάταξη residuals, τετραμερές Root Set) ΚΑΙ τα 3
αντι-ευρήματα του Reviewer-A επί των σκίτσων του B. Καθαρό target: μηδέν migration, μηδέν legacy.
Πύλη: Destruction Pass #2 → v1.0 → ρητό «εγκρίνω freeze target» του δημιουργού. Καμία production
αλλαγή πριν.

## RESPONSE MAP (DP#1 εύρημα → πού κλείνει)
| Εύρημα | Κλείσιμο |
|---|---|
| BLOCKER 1 Blob≠Observation | §3 + **I-16** (typed identity)· evidence_set πλέον δείχνει observations |
| BLOCKER 2 immutable Claim vs lifecycle | §7.1–7.2: ClaimAssertion αμετάβλητο + ClaimHistoryEvent + derived status projection **υπό καθεστώς I-14** (αντι-εύρημα A-2) |
| BLOCKER 3 Claim admission πριν το Root | §7.3: ClaimCandidate → class-specific admission → AdmittedClaimAssertion· admission table = R-ARTIFACT· R-d ΚΛΕΙΝΕΙ |
| BLOCKER 4 IdentityDecision/DiscoveryCorrection εκτός L | §4.2–4.3: L = ΜΟΝΟ LegalEffectEvents· decision records = R-ARTIFACT· AdmissionCorrection = known-time μηχανισμός |
| BLOCKER 5 Root ≠ Authority | **I-17** + τετραμερές Root Set §13 |
| MODIFY 1 ισχυρότερο PC | §5.2 (7 δεσμεύσεις + toolchain manifest όπου απαιτείται) |
| MODIFY 2 assurance tiers | §5.3: PROJECTED → INDEPENDENTLY_VERIFIED → CERTIFIED + serving-tier policy |
| MODIFY 3 untrusted acquisition edge | §2 + §3.3 |
| MODIFY 4 τρία ρολόγια | **I-18**: valid_time / observed_at / admitted_at· known_at ≡ admitted cut· §6 |
| MODIFY 5 total order του L | §4.4: partitioned monotonic + checkpoints + deterministic merge, με τους όρους του αντι-ευρήματος A-3 (partition map = ceremony artifact· merge rule μέσα στο PC) |
| MODIFY 6 byte-identical scope | §9.2/§13: conformance classes DETERMINISTIC \| SEMANTIC |
| MODIFY 7 PUBLIC ως policy | §11.2: αρχιτεκτονικός νόμος + versioned G-pub policy artifact (τρέχουσα εντολή δημιουργού = policy v1) |
| MODIFY 8 ArtifactAdmissionCertificate | §15.1 |
| MODIFY 9 I-13 uncertainty path | I-13 αναθεωρημένο: no best-guess admission |
| R-c minimum independence | §12.2: **Minimum Independence Contract** — ΚΛΕΙΝΕΙ πριν το freeze |
| Τετραμερές Root Set + equations | I-12 αναθεωρημένο + §13 |
| Αντι-εύρημα A-1 (receipt κυκλικότητα) | §3.2: observation_id χωρίς receipt· receipt υπογράφει το id |
| Αντι-εύρημα A-2 (status projector trust root) | §7.2: status projection PC-φέρουσα, στα tiers του §5.3 |
| Αντι-εύρημα A-3 (partition nondeterminism) | §4.4 όροι (α)/(β) |

---

## 0. CONSTITUTION

### 0.1 I-1…I-10 (αμετάβλητα, ως v0.1)
1. Κανένα LLM trust root. 2. Κανένας verifier αξιόπιστος για output του ίδιου implementation.
3. Καμία implicit authority. 4. Κανένα confidence δεν προάγει interpretation σε fact. 5. Κανένα
derived conclusion χωρίς evidence/dependency state. 6. Κανένα external AI call δεν παρακάμπτει
matter/privilege/egress policy. 7. Μοναδική canonical temporal authority. 8. Boundaries
machine-enforced. 9. Executable discharge conditions. 10. Shadow/differential πριν από κάθε νέα μηχανή.

### 0.2 I-11…I-18 (αναθεωρημένα/νέα)

- **I-11 — Δύο ledgers, μία υποχρεωτική αναφορά (αναθ.).** Evidence history (S) ≠ legal-event
  history (L). `LegalEffectEvent MUST reference EvidenceSet = {CaptureObservation…} ≥1` — δείχνει
  **παρατηρήσεις** (με provenance), όχι γυμνά bytes· μέσω αυτών τα blobs. Poisoned capture ζει
  για πάντα στο S χωρίς ποτέ authority: η authority απονέμεται ΜΟΝΟ από admission.

- **I-12 — Root-or-Cache, τετραμερές, με admission (αναθ.).**
  `R := R_SOURCE ∪ R_LEGAL ∪ R_EPISTEMIC ∪ R_ARTIFACT` (§13). Κάθε store είναι είτε μέλος του R
  είτε αποδεδειγμένα cache του R· τρίτη κατηγορία απαγορεύεται. **Είσοδος στο R ΜΟΝΟ μέσω του
  αντίστοιχου admission καθεστώτος** — κανένα untrusted principal δεν γράφει Root state απευθείας.
  Reconstruction equations: `CanonicalLegalState = Project(R_LEGAL, relevant R_ARTIFACT)` ·
  `EpistemicState = Evaluate(R_EPISTEMIC, CanonicalLegalState, relevant R_ARTIFACT)` ·
  `Query/Graph/Search = Cache(CanonicalLegalState, EpistemicState)`. Το R_SOURCE θεμελιώνει τα
  admissions· δεν γίνεται legal truth επειδή είναι immutable.

- **I-13 — Operative-effect criterion + no-best-guess (αναθ.).** Στο L εισέρχεται από
  δικαιοδοτική πράξη ΜΟΝΟ το operative erga omnes αποτέλεσμα του διατακτικού (ΑΕΔ άρθρο 100 Σ,
  ΣτΕ ακύρωση κανονιστικής πράξης κ.ο.κ. — κατά τον attested, F-graded κατατακτήριο πίνακα).
  Ratio/δόγμα/inter partes κρίσεις = πάντα Claims. **Αν μια πράξη δεν ταξινομείται με την
  απαιτούμενη F/authority assurance: ΚΑΝΕΝΑ LegalEffectEvent· εκδίδεται UNKNOWN/DISPUTED Claim
  μέχρι attestation. Ποτέ best-guess admission.**

- **I-14 — Certified reconstruction, tiered (αναθ.).** Κάθε canonical projection (legal state
  ΚΑΙ claim-status projection — §7.2) εκπέμπει Projection Certificate (§5.2). Κάθε state root
  φέρει assurance tier ∈ {PROJECTED, INDEPENDENTLY_VERIFIED, CERTIFIED} (§5.3)· κάθε served
  απάντηση δηλώνει το tier της· ελάχιστο tier ανά context = versioned policy. Release-critical/
  golden roots: υποχρεωτική συμφωνία ανεξάρτητου projector κατά το Minimum Independence Contract
  (§12.2)· διαφωνία ⇒ BLOCK.

- **I-15 — UNKNOWN semantics (ως v0.1).** Κλειστό versioned reason enum + evidence + scope +
  resolution_condition· no-silent-coercion· `POLICY_RESTRICTED` μόνο για publication/egress
  αρνήσεις, ποτέ ως cross-matter σήμα (η cross-matter απομόνωση = structural absence).

- **I-16 — Typed identity (ΝΕΟ — DP#1 B1).** Τρία επίπεδα ταυτότητας, ποτέ συγχωνευμένα:
  **content identity** (blob_id = hash bytes) · **observation identity** (observation_id =
  hash canonical envelope) · **semantic legal identity** (provision/instrument/decision ids υπό
  canonicalization version). `same bytes ⇒ same blob`· `same bytes ≠ same observation`·
  καμία semantic ταυτότητα δεν συνάγεται από byte ισότητα.

- **I-17 — Root ≠ Truth (ΝΕΟ — DP#1 B5).** Root membership = «μη ανακατασκευάσιμο durable input
  απαραίτητο για ιστορική αναπαραγωγή» — ΔΕΝ συνεπάγεται authority. Κάθε Root object φέρει
  χωριστά `root_class`, `authority_class`, `admission_class`. Μόνο το R_LEGAL είναι canonical
  legal-state authority· R_SOURCE = καμία legal authority· R_EPISTEMIC = interpretation-grade·
  R_ARTIFACT = formalization/policy authority με F-levels όπου εφαρμόζεται.

- **I-18 — Τρία ρολόγια, ποτέ συγχωνευμένα (ΝΕΟ — DP#1 M4).**
  `valid_time` = πότε ισχύει το legal effect · `observed_at` = πότε το Watchtower παρατήρησε την
  πηγή (S) · `admitted_at` = πότε η πληροφορία έγινε canonical γνώση (L transaction time).
  **`known_at` ≡ admitted cut, ΟΧΙ capture time**: υλικό σε quarantine δεν εμφανίζεται ποτέ ως
  canonical γνώση πριν το admission. Το observed_at ζει στο forensic query plane (§6.3).

---

## 1. ΟΙ ΕΞΙ ΑΞΟΝΕΣ (αμετάβλητο)
A topology/authority · B truth/time · C representation/query · D trust distribution ·
E epistemology · P practice containment — έξι συστατικές διαστάσεις, καμία «κατά σύμπτωση».

## 2. LAYER MODEL

```
 UNTRUSTED ACQUISITION EDGE (R3): fetchers · court adapters · PDF/OCR · HTML parsers · API clients
      │  μόνο ΠΡΟΤΑΣΕΙΣ capture/candidates — ποτέ trusted δομή
      ▼
            ┌────────────────────────────────────────────────────────┐
planes ──▶  │ P  PRACTICE/PRIVILEGE   E  EPISTEMIC   G  GOVERNANCE   │  (τέμνουν όλα τα στρώματα)
            └────────────────────────────────────────────────────────┘
  ▲  C   DERIVED KNOWLEDGE / QUERY / IMPACT      — caches (DETERMINISTIC | SEMANTIC — §9.2)
  │  N   NORMATIVE / CASE                        — IR, inference, deontic, subsumption
  │  B   CANONICAL BITEMPORAL STATE              — PC-φέρουσες projections, tiered roots
  │  L   CANONICAL LEGAL EVENT LEDGER            — ΜΟΝΟ admitted LegalEffectEvents
  │  S   IMMUTABLE SOURCE / EVIDENCE HISTORY     — blobs + observations + receipts
  └─ A   TRUSTED KERNEL / ADMISSION              — identity, crypto, capabilities, intake

            ║ D — INDEPENDENT VERIFICATION / FEDERATION ║   (εξωτερικός δακτύλιος)
            ║ AI/INTELLIGENCE — εκτός αλήθειας, proposals μέσω gates ║  (πλάγιο plane)
```
Μία διάταξη, τρεις αναγνώσεις: data-flow = trust order = rebuild order. Ο acquisition edge είναι
**έξω** από το trusted boundary: το kernel intake, όχι ο parser, γεννά trusted Observation/Receipt.

## 3. S — IMMUTABLE SOURCE / EVIDENCE HISTORY

### 3.1 Δύο τύποι (I-16)
```
EvidenceBlob        := ⟨ blob_id = hash(bytes), bytes ⟩            — content identity
CaptureObservation  := ⟨ observation_id = hash(canonical envelope) — observation identity
                       , blob_id, source_locator, observed_at
                       , transport_evidence, capture_principal ⟩
```
### 3.2 Receipt χωρίς κυκλικότητα (αντι-εύρημα A-1)
`observation_id = hash(envelope ΧΩΡΙΣ receipt)` · `IntakeReceipt := kernel-signed
⟨observation_id, received_at, intake-policy-version⟩`, αποθηκευμένο ΔΙΠΛΑ στην παρατήρηση.
Ο canonical encoding νόμος του envelope (deterministic serialization) είναι versioned R-ARTIFACT.

### 3.3 Ιδιότητες
- Append-only· καμία διαγραφή/μετάλλαξη· διορθώσεις = νέες observations.
- **Corroboration υπολογίσιμο:** `corroborate(blob) = πλήθος ανεξάρτητων observations
  (διαφορετικό source_locator/principal/χρόνος)` — same bytes από δύο επίσημες πηγές = δύο
  παρατηρήσεις, ένα blob· θεμέλιο για source diversity requirements στο admission.
- Ο acquisition edge (§2) μόνο προτείνει· το intake επικυρώνει transport evidence και υπογράφει.
- Merkle checkpoints του S → attestation υλικό (§12).

## 4. L — CANONICAL LEGAL EVENT LEDGER

### 4.1 Admission pipeline (μόνη είσοδος, fail-closed σε κάθε βήμα)
```
CaptureObservation(S) → Source Authority Policy → Authenticity/Integrity →
Untrusted-Parser candidate → Trusted Structural Validation → Identity Resolution →
Temporal/Semantic Validation → Conflict/Quarantine → Admission Decision →
LegalEffectEvent (L) + AdmissionDecision record (R-ARTIFACT)
```
Ο parser είναι attack surface (R3): παράγει ΜΟΝΟ candidate δομή· η trusted validation την
ελέγχει ανεξάρτητα. Κάθε admission παράγει AdmissionDecision record με πλήρη αιτιολογία.

### 4.2 Event taxonomy (κλειστή, versioned — ΜΟΝΟ legal-world μεταβολές)
```
Publication · Amendment · Correction(επίσημη/εκδοτική) · Commencement ·
ConditionalCommencement · Repeal · Revival · Renumber · Split · Merge ·
Retroactivity-scope · AdjudicativeOperativeEffect{annulment-erga-omnes,
unconstitutionality-declaration, …}
```
**Εκτός L (DP#1 B4):** `IdentityDecision` και `DiscoveryCorrection` ΔΕΝ είναι legal events.
Διάκριση: η **επίσημη διόρθωση** (π.χ. διόρθωση σφάλματος σε ΦΕΚ) είναι μεταβολή του νομικού
κόσμου ⇒ μένει στο L ως `Correction`. Το **δικό μας λάθος admission** είναι μεταβολή του
μοντέλου μας ⇒ §4.3.

### 4.3 Decision records (R-ARTIFACT, append-only, referenced από events)
```
CanonicalizationDecision — identity merge/split/alias υπό canonicalization version
AdmissionDecision        — τι ελέγχθηκε, από ποιους checkers/versions, επί ποιου EvidenceSet
AdmissionCorrection      — ακύρωση/διόρθωση προηγούμενου admission (δικό μας λάθος)
```
**Known-time σημασιολογία του AdmissionCorrection:** event με corrected admission είναι ορατό σε
cuts `admitted_at ≤ known_at < corrected_at` (τίμια ιστορία του τι πιστεύαμε) και εξαιρείται από
cuts `known_at ≥ corrected_at`. Το παρελθόν του L δεν ξαναγράφεται ποτέ.

### 4.4 Διάταξη: partitioned monotonic + checkpoints (DP#1 M5 + αντι-εύρημα A-3)
- Το L διαμερίζεται σε **jurisdictional/source partitions** (π.χ. ΦΕΚ τεύχη, EU, δικαστήρια,
  ανεξάρτητες αρχές)· κάθε partition = strictly monotonic admission sequence.
- **Ο partition χάρτης είναι versioned R-ARTIFACT με ceremony** — αλλαγή ορίων = αλλαγή
  σημασιολογίας, όχι ρύθμιση.
- Περιοδικά **globally committed checkpoints** δεσμεύουν consistent cut όλων των partitions
  (kernel-signed)· τα `known_at` cuts ορίζονται πάνω σε checkpoint-consistent τομές.
- **Deterministic merge rule** όταν projection καταναλώνει πολλά partitions:
  διάταξη κατά `(checkpoint cut, partition_id, per-partition seq)` — ολική, ντετερμινιστική,
  **δεσμευμένη μέσα στο PC scope**. Replay με οποιαδήποτε σειρά παράδοσης ⇒ ταυτόσημα roots (§17.14).
- ADR υποχρεωτικό αν ποτέ προταθεί επιστροφή σε single global sequence.

## 5. B — CANONICAL BITEMPORAL STATE

### 5.1 API αλήθειας (I-7)
`resolve(provision, valid_at, known_at, context) → ResolvedState | UNKNOWN{…}` — μοναδική
production είσοδος· `known_at` = admitted checkpoint cut (I-18)· span-level provenance:
κάθε ResolvedState ανάγεται σε events → observations → blobs.

### 5.2 Projection Certificate (DP#1 M1)
```
PC := ⟨ projector_spec              — ποιος αλγόριθμος/σημασιολογία (attested spec id)
      , implementation_digest      — build digest του projector
      , input_L_root               — merkle root του καταναλωθέντος cut
      , artifact_set_root          — root των R-ARTIFACT versions που χρησιμοποιήθηκαν
      , canonicalization_version   — identity model version
      , scope                      — partitions/checkpoint/χρονικό εύρος + merge-rule version
      , output_state_root
      , toolchain_manifest         — όπου το απαιτεί η policy (release-critical πάντα) ⟩
```
State root χωρίς έγκυρο PC δεν είναι canonical — για ΚΑΘΕ canonical projection, συμπεριλαμβανομένης
της claim-status projection (§7.2).

### 5.3 Assurance tiers (DP#1 M2)
```
PROJECTED               — ένας projector, έγκυρο PC
INDEPENDENTLY_VERIFIED  — ≥2 projectors κατά το MIC (§12.2) συμφωνούν στο ίδιο scope
CERTIFIED               — INDEPENDENTLY_VERIFIED + ένταξη σε kernel-signed attestation checkpoint
```
- Κάθε served απάντηση φέρει το tier του root της — ποτέ σιωπηλά.
- **Serving-tier policy (versioned R-ARTIFACT):** ελάχιστο tier ανά context· ενδεικτικά:
  ό,τι περνά G-pub ή τροφοδοτεί δικόγραφο ⇒ ≥ INDEPENDENTLY_VERIFIED (στόχος CERTIFIED)·
  εσωτερική έρευνα ⇒ επιτρέπεται PROJECTED με ρητή ετικέτα. Mismatch ⇒ REJECT (§17.15).
- Snapshots = PC-φέροντα certified caches σε checkpoints· replay από πλησιέστερο verified checkpoint.

## 6. TEMPORAL SEMANTICS

- **Τρία ρολόγια (I-18):** `valid_time` × `admitted_at` παντού στο canonical plane· `observed_at`
  μόνο στο forensic plane. Κάθε L event, κάθε ResolvedState, κάθε ClaimAssertion φέρει τα ζεύγη του.
- **Retroactivity:** αναδρομικό event = valid_time στο παρελθόν, admitted_at τώρα· προγενέστερα
  known_at ερωτήματα δεν αλλοιώνονται· STALE wave στα εξαρτημένα claims (§7.2).
- **Conditional commencement:** η πλήρωση αίρεσης = ΝΕΟ event με δικό του EvidenceSet.
- **§6.3 Δύο query planes, ποτέ αναμεμειγμένα χωρίς ετικέτα:**
  *Canonical plane* — `resolve(valid_at, known_at)` επί admitted γνώσης.
  *Forensic plane* — ερωτήματα επί S με observed_at («τι ήταν παρατηρήσιμο/παρατηρημένο πότε») για
  audit/malpractice/duty-of-knowledge· απαντήσεις ΠΑΝΤΑ επισημασμένες ως forensic, ποτέ ως ισχύον δίκαιο.
- Ημερομηνιακή αριθμητική μόνο μέσω kernel temporal library.

## 7. E — EPISTEMIC PLANE

### 7.1 ClaimAssertion — αμετάβλητο root record (DP#1 B2)
```
ClaimAssertion := ⟨ claim_id (content-addressed), claim_type, statement (typed)
                  , epistemic_class, confidence_in_class, A-level, F-level, coverage_stamp
                  , world_context, valid_time, evidence_set {observation/event/claim refs ≥1}
                  , dependency_set, created_by, supersedes | ∅ ⟩
```
**ΧΩΡΙΣ lifecycle field.** Παράλληλα, append-only `ClaimHistoryEvent ∈ {CLAIM_ADMITTED,
CLAIM_REJECTED, CLAIM_SUPERSEDED, CONFLICT_REGISTERED, …}`. EpistemicClass enum, απαγορευμένες
μεταβάσεις (CC-1), A0–A4, F0–F3 (F3 ταβάνι, EMPIRICAL), anti-laundering, coverage ⟨C,S,T,W,G⟩,
InterpretationWorlds: ως v0.8 §0.1, αμετάβλητα.

### 7.2 Status = derived bitemporal projection (DP#1 B2 + αντι-εύρημα A-2)
`status(claim, valid_at, known_at) ∈ {ACTIVE, STALE, SUPERSEDED, REJECTED}` υπολογίζεται από
`ClaimAssertion + dependency_set + L + ClaimHistoryEvents` — **καμία μετάλλαξη 100.000 records**·
συμβατό με I-12 (status υλοποιήσεις = caches). **Ο status projector είναι canonical projection
υπό I-14**: εκπέμπει PC, έχει tier, και release-critical claim-status roots απαιτούν ανεξάρτητη
επαλήθευση — αλλιώς bug του σερβίρει STALE ως ACTIVE (παραβίαση I-5) αόρατα.

### 7.3 Claim admission (DP#1 B3 — το R-d κλείνει ΕΔΩ)
```
ClaimCandidate (non-root proposal/scratch queue — εκεί γράφουν agents/humans)
      ↓  class-specific E-admission (K-cl checker family)
AdmittedClaimAssertion → Claim History (R_EPISTEMIC)
```
- **Admission requirements ανά class (πίνακας = versioned R-ARTIFACT):**
  `DETERMINISTIC_DERIVATION` ⇒ έγκυρο derivation certificate ελεγμένο από ανεξάρτητο checker (A≥A2)·
  `LEGAL_INTERPRETATION` ⇒ evidence set + admissible principal/model provenance + policy·
  `DISPUTED_INTERPRETATION` ⇒ ρητό conflict edge· `PREDICTION` ⇒ model/evaluation manifest·
  `VERIFIED_OBSERVATION` ⇒ capture receipts· `AUTHORITATIVE_TEXT` ⇒ ΜΟΝΟ μέσω L admission (K-src),
  ποτέ μέσω claim queue· `UNKNOWN` ⇒ typed δομή I-15 πλήρης.
- **Ενιαία έδρα:** ΚΑΘΕ claim — και από trusted engine και από άνθρωπο — περνά admission· του
  trusted engine το certificate κάνει το admission αυτόματο/φθηνό, δεν το παρακάμπτει.
- Agent flooding γεμίζει το proposal queue (quota/TTL hygiene στο P-plane), ΠΟΤΕ το Root (§17.12).

## 8. N — NORMATIVE / CASE
Ως v0.1: Normative IR = authored R-ARTIFACT με atom→source-span δέσιμο, versioned, admitted μέσω
ArtifactAdmissionCertificate (§15.1)· acceptance = serialize→parse→ταυτό IR + πλήρης span κάλυψη·
inference (JTMS-class, WFS, event calculus) εκπέμπει ΜΟΝΟ ClaimCandidates → §7.3· case layer
(υπαγωγή, precedent, dialectic, deadlines) ομοίως· F-πειθαρχία με αυτόματο STALE σε source change.

## 9. C — DERIVED KNOWLEDGE / QUERY / IMPACT

### 9.1 Ως v0.1
Όλα caches· κάθε epistemic ακμή φέρει claim/event καταγωγή — «γυμνή» ακμή δεν υπάρχει στο σχήμα·
impact/invalidation μέσω dependency graph → STALE wave → review queues.

### 9.2 Conformance classes (DP#1 M6)
Κάθε cache δηλώνει class: **DETERMINISTIC** (byte-identical rebuild — υποχρεωτικό για canonical
serializations, state roots, event projections) ή **SEMANTIC** (functional conformance κατά
δηλωμένο τεστ — embeddings, ANN, search internals). Νόμος: **κάθε cache rebuildable χωρίς απώλεια
authoritative πληροφορίας**· SEMANTIC cache δεν επιτρέπεται να είναι μοναδικός φορέας
οποιουδήποτε authoritative γεγονότος· το conformance τεστ κάθε SEMANTIC cache = δηλωμένο κατά το
global discharge standard.

## 10. INTELLIGENCE PLANE (AI) — εκτός αλήθειας
Ως v0.1, ευθυγραμμισμένο με §7.3: όλα τα AI outputs = ClaimCandidates ή admission candidates —
ποτέ Root γραφή, ποτέ DETERMINISTIC/AUTHORITATIVE class, ποτέ direct egress (μόνο G-inf)·
generator manifest υποχρεωτικό στο coverage stamp· retrieval accelerators = SEMANTIC caches §9.2.

## 11. P — PRACTICE / PRIVILEGE / SECURITY PLANE

### 11.1 Ως v0.1
Matter compartments = structural absence σε ΟΛΟ το surface· data classes {PUBLIC, INTERNAL,
CLIENT_CONFIDENTIAL, PRIVILEGED, WORK_PRODUCT, RESTRICTED}· PRIVILEGED/RESTRICTED ⇒ egress
capability δομικά απούσα· capabilities ⟨issuer, holder, scope, expiry, bounded delegation,
revocation, replay-nonce, audit-binding, SoD⟩· break-glass = 2-person, expiry, loud, no delegation.

### 11.2 Publication: νόμος vs policy (DP#1 M7)
**Αρχιτεκτονικός νόμος:** `PUBLIC-class ∧ release-policy-approved ∧ privilege-safe ⇒ publication
candidate` — τίποτα άλλο δεν φτάνει καν σε staging. **Το ΤΙ επιτρέπεται = versioned G-pub policy
artifact** (R-ARTIFACT, ceremony-governed). Η τρέχουσα εντολή του δημιουργού («δημόσιο = μόνο
κωδικοποιημένοι δημόσιοι νόμοι») κατοχυρώνεται ως **policy v1** — δεσμευτική μέχρι ρητή αλλαγή
από τον ίδιο, χωρίς να είναι hardcoded στο σύστημα. G-pub failure ⇒ publication disabled,
fail-closed, κανένα weaker bypass· canary + stego red-team κάθε release.

## 12. D — VERIFICATION & TRUST DISTRIBUTION

### 12.1 Ως v0.1
Internal independence ΤΩΡΑ (χωριστοί verifiers/projectors/proof checkers, χωριστά builds)·
attestation checkpoints ⟨S-root, L-roots ανά partition, golden state roots, PCs, admission
stats⟩· federation ΟΤΑΝ υπάρξει trust diversity· καμία federation-of-one.

### 12.2 Minimum Independence Contract — MIC (κλείνει το R-c, DP#1 απαίτηση pre-freeze)
Δύο υλοποιήσεις θεωρούνται ανεξάρτητες iff:
1. **Μηδέν κοινός implementation κώδικας.** Κοινά επιτρέπονται ΜΟΝΟ: το frozen spec + τα
   conformance test vectors.
2. **Disjoint dependency closure** στο critical path (καμία κοινή third-party βιβλιοθήκη), ή
   διαφορετική γλώσσα υλοποίησης — επαληθεύσιμο με manifest diff.
3. **Ανεξάρτητο build + runtime** (χωριστό toolchain manifest).
4. Και οι δύο περνούν **mutation/defect-seeding batteries** παραγόμενες από τις error classes
   του spec — απόδειξη ότι δεν μοιράζονται τυφλά σημεία στο μετρήσιμο πεδίο.
5. **Disagreement resolution law:** κάθε διαφωνία λύνεται με διόρθωση/διευκρίνιση του spec μέσω
   ceremony — ΠΟΤΕ με αντιγραφή της συμπεριφοράς της άλλης υλοποίησης χωρίς spec αλλαγή
   (αλλιώς η ανεξαρτησία διαβρώνεται σιωπηλά).
6. **SoD:** διαφορετικός συντάκτης/θεμέλιο ανά υλοποίηση (για το πλαίσιό μας: διαφορετικά
   agents/foundations, ποτέ ο producer του A reviewer του B του εαυτού του).
Το υπόλοιπο κοινό ρίσκο (κοινό conceptual bug ΣΤΟ spec) δηλώνεται ρητά ως residual κλάσης
spec-level — αντιμετωπίζεται από contrastive fixtures + εξωτερική αναπαραγωγή (§17.10), όχι από
ψευδή ισχυρισμό πλήρους ανεξαρτησίας.

## 13. STORAGE & REBUILD — τετραμερές Root Set (DP#1 refinement)

```
R_SOURCE    Evidence Blobs + Capture Observations + Intake Receipts     authority: ΚΑΜΙΑ
R_LEGAL     Admitted LegalEffectEvents (+ partition χάρτης cuts)        authority: CANONICAL
R_EPISTEMIC Admitted ClaimAssertions + ClaimHistoryEvents               authority: interpretation-grade
R_ARTIFACT  Schemas · Rulepacks · Normative IR · Projector specs ·      authority: formalization/
            Policy tables · Decision records · Admission certificates    policy (F-graded όπου εφαρμόζεται)
```
- Όλα Root για reconstruction (I-12)· ΜΟΝΟ το R_LEGAL είναι legal-state authority (I-17).
- Root stores: append-only, content-addressed, merkle-checkpointed, μέγιστο durability καθεστώς.
- **Νόμος ανακατασκευής:** από το R και μόνο, οι εξισώσεις του I-12 αναπαράγουν: canonical state
  με byte-identical roots (DETERMINISTIC class) και κάθε cache κατά την class του (§9.2).
  Ασκείται προγραμματισμένα κάθε release (μερικώς) και περιοδικά πλήρως — DR = ρουτίνα.

## 14. SCALE MODEL
Ως v0.1, με §4.4: read φορτίο ⇒ caches· Root δέχεται μόνο admission ρυθμούς· incremental
projections με PC ανά checkpoint· partitions κλιμακώνουν admission ανεξάρτητα· verification
offline/async από serving path.

## 15. UPGRADEABILITY & SCHEMA EVOLUTION

### 15.1 ArtifactAdmissionCertificate (DP#1 M8)
Κάθε R_ARTIFACT μέλος εισέρχεται ΜΟΝΟ με:
```
ArtifactAdmissionCertificate := ⟨ artifact_digest, author, reviewer(s), A/F όπου εφαρμόζεται
                                , applicability/scope, supersedes, approval ceremony record
                                , effective_version ⟩
```
— το αποτέλεσμα κάθε G-sev ceremony ΕΙΝΑΙ canonical admission record του Root Set, όχι πρακτικό.

### 15.2 Ως v0.1
Event schemas versioned· παλαιά events ποτέ ξαναγραμμένα· upcast functions = versioned R_ARTIFACT·
projector αλλαγή ⇒ νέα PC γενιά + differential report· κλειστά enums επεκτείνονται μόνο με
ceremony· autonomy = sandbox προτάσεις σε ουρά, ποτέ αυτο-εφαρμογή.

## 16. FAILURE MODEL
Ως v0.1 (fail-closed παντού· containment· degradation σκάλα· journaled incidents), συν:
- Αταξινόμητη δικαιοδοτική πράξη ⇒ fail-closed κατά I-13 (κανένα event, UNKNOWN/DISPUTED claim).
- Quarantine έχει ρητό clock: υλικό σε quarantine ΔΕΝ γερνά σιωπηλά — SLA ανά κατηγορία με
  escalation σε review queue (operational parameter, όχι αρχιτεκτονική σταθερά).
- Tier mismatch στο serving ⇒ REJECT + incident (ποτέ σιωπηλή υποβάθμιση απαίτησης).

## 17. ARCHITECTURE EXPERIMENTS — 15 falsifiers (πύλη DESIGN HYPOTHESIS → DEMONSTRATED)
1–10 ως v0.1 (temporal replay torture · full reconstruction · poisoned admission · projector
N-version disagreement · claim laundering · mass invalidation · matter escape · schema evolution ·
disaster recovery · independent reproduction), με τα 2/9 να απαιτούν πλέον την τετραμερή R
σημασιολογία και το 4 να τρέχει υπό MIC. Νέα, από τα DP#1 seams:
11. **Observation identity torture** — ίδια bytes από 2 πηγές/χρόνους ⇒ 1 blob, 2 observations·
    corroboration σωστό· καμία διπλο-admission event. *Falsifies:* I-16, §3.
12. **Claim flooding** — R3 agent πλημμυρίζει candidates ⇒ Root ανέγγιχτο· queue quotas ενεργά·
    καμία admitted assertion χωρίς πλήρες class requirement. *Falsifies:* §7.3, I-12.
13. **Backdating attempt** — capture σε quarantine 12h, μετά admitted ⇒ κανένα
    `resolve(known_at < admitted_at)` δεν το βλέπει· το forensic plane δείχνει observed_at σωστά.
    *Falsifies:* I-18, §6.3.
14. **Partition merge determinism** — replay με ανακατεμένη σειρά παράδοσης partitions ⇒
    ταυτόσημα state roots· merge-rule version ορατή στο PC. *Falsifies:* §4.4.
15. **Tier mislabel** — απόπειρα serving PROJECTED root σε context που απαιτεί CERTIFIED ⇒
    REJECT + incident· καμία σιωπηλή υποβάθμιση. *Falsifies:* §5.3, I-14.

## 18. RESIDUALS
- **R-a** (περιεχόμενο erga-omnes πίνακα): residual — νομική έρευνα προς F-graded attestation,
  με το I-13 fail-closed μονοπάτι να καλύπτει το μεσοδιάστημα. [συμφωνία DP#1]
- **R-b** (STALE bound): operational parameter — πλέον ως freshness bound της status projection
  (§7.2), ορίζεται αριθμητικά στο freeze. [συμφωνία DP#1]
- **R-c**: **ΚΛΕΙΣΤΟ** — MIC §12.2· ό,τι απομένει = δηλωμένο spec-level common-mode residual.
- **R-d**: **ΚΛΕΙΣΤΟ** — §7.3 claim admission.
- **R-e** (federation protocol): residual — intentionally later. [συμφωνία DP#1]
- **R-f (ΝΕΟ):** checkpoint cadence & quarantine SLA τιμές — operational parameters στο freeze.
- **R-g (ΝΕΟ):** πρότυπα semantic-conformance τεστ ανά τύπο SEMANTIC cache (§9.2) — προδιαγραφή
  ανά cache πριν το αντίστοιχο build, όχι πριν το target freeze.

---

**Πύλη:** Destruction Pass #2 (Reviewer-B: identity, root admission, lifecycle, temporal clocks,
reconstruction certificates, authority boundaries, failure/degradation) επί του παρόντος →
κλείσιμο ευρημάτων → Target Architecture v1.0 → ρητό «εγκρίνω freeze target» του δημιουργού →
το v0.8 ξαναδένεται ως migration plan (v0.9). Καμία production αλλαγή πριν.
