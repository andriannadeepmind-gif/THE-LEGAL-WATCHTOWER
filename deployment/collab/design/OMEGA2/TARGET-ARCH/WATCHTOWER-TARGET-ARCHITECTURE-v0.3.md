# WATCHTOWER VLT — TARGET ARCHITECTURE v0.3 — FREEZE CANDIDATE
**Layered Verifiable Legal Twin — μετά το Destruction Pass #2 (κοινό artifact Reviewer-A × Reviewer-B)**

**Status: DESIGN HYPOTHESIS — FREEZE CANDIDATE.** Πλήρως **self-contained** normative spec
(DP#2 M7, επιλογή A): καμία κανονιστική αναφορά σε προηγούμενα drafts· ό,τι δεσμεύει είναι
γραμμένο εδώ αυτούσιο. Καθαρό target: μηδέν migration, μηδέν legacy paths. Γίνεται DEMONSTRATED
ARCHITECTURE μόνο όταν περάσουν και τα 21 πειράματα του §17 εντός δηλωμένων fixture universes.
Πύλη: freeze-readiness audit Reviewer-B → v1.0 → ρητό «εγκρίνω freeze target» του δημιουργού →
το MERGED-BLUEPRINT ξαναδένεται ως migration plan. Καμία production αλλαγή πριν.

## RESPONSE MAP (DP#2 εύρημα → πού κλείνει)
| Εύρημα | Κλείσιμο |
|---|---|
| B1 R_ARTIFACT admission regress | §13: πέμπτη κλάση **R_CONTROL** + §15.2 entry rules + **I-20 Trust Anchor** (αντι-εύρημα A-2: η αναδρομή τερματίζει σε ρητό genesis, όχι σε «kernel rules») |
| B2 transaction-cut model | **I-18** αναθεωρημένο: 4 χρονικές έννοιες + `tx_coord` + `CheckpointCut`· `known_at` = committed cut id (αντι-εύρημα A-1: ΜΟΝΟ committed, totally-ordered cuts) — §6 |
| B3 generalized PC | §5.2: `input_roots` ανά Root class + `transaction_cut` + `projection_kind` |
| B4 identity lineage | **I-19** + §4.5: StableEntityId/EntityVersionId/IdentityAssertion/lineage· identity map = PC-φέρουσα projection του R_CONTROL |
| B5 source probe/freshness | §3.4 `SourceProbeObservation` (αντι-εύρημα A-3: bytes ⇒ blob πάντα) + §5.4 freshness envelope + serving rule |
| B6 MIC criterion 2 | §12.2 v2: γλώσσα = ένδειξη, ποτέ υποκατάστατο· + κανόνας μη-κοινής καταγωγής (no translation ancestry) |
| M1 candidate rejection non-root | §7.4: rejection πριν από admission = non-root disposition· root `CLAIM_REJECTED` μόνο για admitted |
| M2 supersession single seat | §7.5: έδρα = `supersedes` του νέου admitted assertion, επικυρωμένο από ClaimAdmissionDecision· `CLAIM_SUPERSEDED` = derived, ΟΧΙ root fact |
| M3 claim bitemporality | §7.2: ClaimAssertion φέρει valid_time· tx_coord ζει στο ClaimAdmissionDecision (R_CONTROL) |
| M4 AdmitView equations | §13.2 |
| M5 CERTIFIED semantics | §5.3: τρίτο tier = **RECONSTRUCTION_CERTIFIED** — πιστοποιεί ανακατασκευή δηλωμένων inputs, ΠΟΤΕ ουσιαστική νομική ορθότητα |
| M6 effect scope | I-13 + §4.2: classifier με `effect_scope/target_kind/temporal_effect/authority_basis`· τα L events τυπώνουν ΤΙ είδους state άλλαξε |
| M7 self-contained | Ολόκληρο το παρόν — όλες οι normative προδιαγραφές inline |
| Failure matrix | §16 |
| Experiments 16–21 | §17 |

---

## 0. CONSTITUTION — I-1…I-20 (πλήρες κείμενο, μη διαπραγματεύσιμο)

**I-1.** Κανένα LLM δεν αποτελεί trust root· κανένα LLM στο trusted path.
**I-2.** Κανένας verifier δεν είναι αξιόπιστος επειδή ελέγχει output του ίδιου implementation
από το οποίο παρήχθη.
**I-3.** Κανένα subsystem δεν φέρει implicit authority· κάθε εξουσία είναι ρητή, τυπωμένη, ελέγξιμη.
**I-4.** Κανένα confidence score, ψήφος, επανάληψη ή consensus δεν μετατρέπει interpretation σε fact.
**I-5.** Κανένα derived conclusion δεν υπάρχει χωρίς evidence set και dependency state· dependency
μεταβολή καθιστά το συμπέρασμα STALE και STALE δεν σερβίρεται ως ACTIVE.
**I-6.** Κανένα external AI/provider call δεν παρακάμπτει matter/privilege/egress policy.
**I-7.** Καμία production απόφαση legal temporal state έξω από τη μοναδική canonical temporal
authority (`resolve` — §5.1).
**I-8.** Τα boundaries είναι machine-enforced· καμία σύμβαση καλής θέλησης.
**I-9.** Κάθε φάση/ιδιότητα έχει executable discharge condition.
**I-10.** Κάθε νέα μηχανή περνά πρώτα από shadow/differential λειτουργία όπου είναι εφικτό.

**I-11 — Δύο ledgers, μία υποχρεωτική αναφορά.** Evidence history (S) ≠ legal-event history (L).
`LegalEffectEvent MUST reference EvidenceSet = {CaptureObservation…} ≥1` — παρατηρήσεις με
provenance, όχι γυμνά bytes. Poisoned capture ζει για πάντα στο S χωρίς ποτέ authority:
η authority απονέμεται ΜΟΝΟ από admission. Immutability ≠ correctness.

**I-12 — Root-or-Cache (πενταμερές, με admission).**
`R := R_SOURCE ∪ R_LEGAL ∪ R_EPISTEMIC ∪ R_ARTIFACT ∪ R_CONTROL` (§13). Κάθε store είναι είτε
μέλος του R είτε αποδεδειγμένα cache του R· τρίτη κατηγορία απαγορεύεται να υπάρχει. Είσοδος σε
κάθε Root class ΜΟΝΟ μέσω του δικού της admission καθεστώτος (§15)· κανένα untrusted principal
δεν γράφει Root state απευθείας. Reconstruction equations: §13.2.

**I-13 — Operative-effect criterion + no-best-guess + effect scope.** Στο L εισέρχεται από
δικαιοδοτική πράξη ΜΟΝΟ το operative erga omnes αποτέλεσμα του διατακτικού που μεταβάλλει legal
state κατά το ισχύον δίκαιο (π.χ. κήρυξη αντισυνταγματικότητας ΑΕΔ κατ' άρθρο 100 §4 Σ· ακυρωτικό
αποτέλεσμα ΣτΕ έναντι όλων επί κανονιστικών/διοικητικών πράξεων κατ' άρθρο 95 Σ και τη δικονομία
του). Ratio, δόγμα, inter partes κρίσεις (συμπεριλαμβανομένου του διάχυτου ελέγχου) = πάντα
Claims. Ο κατατακτήριος πίνακας είναι attested, F-graded R_ARTIFACT με πεδία
`{effect_scope, target_kind, temporal_effect, authority_basis}` — «erga omnes» δεν σημαίνει
αυτομάτως μεταβολή γενικού κανόνα: το L τυπώνει ΤΙ είδους state άλλαξε (γενικός κανόνας ή
συγκεκριμένη πράξη). **Αν μια πράξη δεν ταξινομείται με την απαιτούμενη F/authority assurance:
ΚΑΝΕΝΑ LegalEffectEvent· UNKNOWN/DISPUTED Claim μέχρι attestation. Ποτέ best-guess admission.**

**I-14 — Certified reconstruction, tiered.** Κάθε canonical projection (legal state, claim
status, identity map, freshness envelope) εκπέμπει generalized Projection Certificate (§5.2) που
δεσμεύει ΟΛΑ τα Root inputs της ανά class. Κάθε state root φέρει tier ∈ {PROJECTED,
INDEPENDENTLY_VERIFIED, RECONSTRUCTION_CERTIFIED} (§5.3)· κάθε served απάντηση δηλώνει το tier
της· ελάχιστο tier ανά context = versioned policy. Release-critical roots: υποχρεωτική συμφωνία
ανεξάρτητου projector κατά MIC (§12.2)· διαφωνία ⇒ BLOCK. Το tier πιστοποιεί **ανακατασκευή των
δηλωμένων inputs υπό το δηλωμένο spec — ποτέ ουσιαστική ορθότητα δικαίου ή ερμηνείας.**

**I-15 — UNKNOWN semantics.** UNKNOWN = first-class δομή: κλειστό versioned reason enum
`{SOURCE_MISSING, TEMPORAL_AMBIGUITY, CONFLICTING_AUTHORITIES, UNRESOLVED_IDENTITY,
INSUFFICIENT_FORMALIZATION, INCOMPLETE_COVERAGE, POLICY_RESTRICTED}` + `evidence` (τι ΞΕΡΟΥΜΕ
που θεμελιώνει την άγνοια) + `scope` + `resolution_condition` (τι θα το έλυνε — actionable).
No-silent-coercion: κανένας καταναλωτής δεν μετατρέπει UNKNOWN σε default. Προσθήκη reason =
governance ceremony. `POLICY_RESTRICTED` ΜΟΝΟ για publication/egress αρνήσεις — ποτέ ως
cross-matter σήμα: η cross-matter απομόνωση είναι structural absence (§11.1).

**I-16 — Typed identity.** Τρία επίπεδα, ποτέ συγχωνευμένα: content identity (`blob_id`),
observation identity (`observation_id`), semantic legal identity (§4.5). `same bytes ⇒ same
blob`· `same bytes ≠ same observation`· καμία semantic ταυτότητα από byte ισότητα.

**I-17 — Root ≠ Truth.** Root membership = μη ανακατασκευάσιμο durable input απαραίτητο για
ιστορική αναπαραγωγή — ΔΕΝ συνεπάγεται authority. Κάθε Root object φέρει χωριστά `root_class`,
`authority_class`, `admission_class`. Μόνο το R_LEGAL είναι canonical legal-state authority·
R_SOURCE = καμία legal authority· R_EPISTEMIC = interpretation-grade· R_ARTIFACT =
formalization/policy authority (F-graded όπου εφαρμόζεται)· R_CONTROL = control-plane ιστορικά
γεγονότα, όχι νομικό περιεχόμενο.

**I-18 — Χρονικό μοντέλο: τέσσερις έννοιες + logical cut.**
`valid_time` = legal-world χρόνος ισχύος · `observed_at` = wall-clock forensic χρόνος
παρατήρησης (S) · `admitted_wall_time` = wall-clock audit timestamp της admission (μόνο audit,
ποτέ σημασιολογία) · `tx_coord := ⟨partition_id, sequence⟩` = canonical logical συντεταγμένη
admission. **`known_at := CheckpointCutId`** — id δεσμευμένου (committed) checkpoint cut, ΟΧΙ
wall-clock. Έγκυρα known_at είναι ΜΟΝΟ committed cuts: hash-chained αλυσίδα στο R_CONTROL όπου
κάθε checkpoint κυριαρχεί τον προηγούμενο ⇒ ολική διάταξη εκ κατασκευής. Αντιστοίχιση
wall-clock→cut: μέσω checkpoint registry, ντετερμινιστική. Ό,τι είναι σε quarantine δεν
εμφανίζεται ποτέ ως canonical γνώση πριν το admission tx_coord του ενταχθεί σε cut.

**I-19 — Immutable semantic identity lineage.** `StableEntityId` δεν επαναχρησιμοποιείται ΠΟΤΕ·
canonicalization αναβάθμιση δεν ξαναγράφει ιστορικά identifiers· λάθος ταυτότητα = append-only
`IdentityCorrection` στο R_CONTROL· merge/split του μοντέλου μας = lineage mappings· queries σε
παλαιό known_at βλέπουν το παλαιό identity map, νέα cuts το διορθωμένο. Η canonicalization
supersedes identity assertions — never rewrites historical identifiers.

**I-20 — Ρητό Trust Anchor.** Η αλυσίδα πιστοποίησης τερματίζει σε δηλωμένο
`TrustAnchor := ⟨genesis ceremony record, kernel root keys + key rotation history⟩` — τα ΜΟΝΑ
αξιωματικά, μη-πιστοποιημένα αντικείμενα του συστήματος, ρητά απαριθμημένα και τυπωμένα σε κάθε
attestation bundle. Καμία κρυφή κυκλικότητα: ό,τι δεν πιστοποιείται, δηλώνεται ως αξίωμα.

---

## 1. ΟΙ ΕΞΙ ΣΥΣΤΑΤΙΚΟΙ ΑΞΟΝΕΣ
| Άξονας | Ερώτημα | Απάντηση VLT |
|---|---|---|
| **A** topology/authority | ποιος κρατά τα κλειδιά | trusted kernel + capabilities + domain DAG |
| **B** truth/time | τι είναι η αλήθεια, πώς αλλάζει | δύο ledgers + bitemporal certified reconstruction |
| **C** representation/query | πώς ερωτάται η γνώση | rebuildable claim-bearing projections |
| **D** trust distribution | ποιος πιστοποιεί ποιον | internal independence τώρα· federation με πραγματικό diversity |
| **E** epistemology | τι είδους γνώση είναι κάθε πρόταση | Claim Contract, A/F, worlds, UNKNOWN |
| **P** practice containment | απόρρητο/matters/δημοσίευση/egress | structural isolation + fail-closed gates |

## 2. LAYER MODEL
```
 UNTRUSTED ACQUISITION EDGE (R3): fetchers · adapters · PDF/OCR · parsers · API clients
      │  μόνο ΠΡΟΤΑΣΕΙΣ capture/candidates — ποτέ trusted δομή
      ▼
            ┌────────────────────────────────────────────────────────┐
planes ──▶  │ P  PRACTICE/PRIVILEGE   E  EPISTEMIC   G  GOVERNANCE   │  (τέμνουν όλα τα στρώματα)
            └────────────────────────────────────────────────────────┘
  ▲  C   DERIVED KNOWLEDGE / QUERY / IMPACT      — caches (DETERMINISTIC | SEMANTIC)
  │  N   NORMATIVE / CASE                        — IR, inference, deontic, subsumption
  │  B   CANONICAL BITEMPORAL STATE              — PC-φέρουσες projections, tiered roots
  │  L   CANONICAL LEGAL EVENT LEDGER            — ΜΟΝΟ admitted LegalEffectEvents
  │  S   IMMUTABLE SOURCE / EVIDENCE HISTORY     — blobs + observations + probes + receipts
  └─ A   TRUSTED KERNEL / ADMISSION              — identity, crypto, capabilities, intake, clocks

            ║ D — INDEPENDENT VERIFICATION / FEDERATION ║   (εξωτερικός δακτύλιος)
            ║ AI/INTELLIGENCE — εκτός αλήθειας, proposals μέσω gates ║  (πλάγιο plane)
```
Μία διάταξη, τρεις αναγνώσεις: data-flow = trust order = rebuild order. E/P/G = cross-cutting
planes. Ο acquisition edge είναι έξω από το trusted boundary: το kernel intake, όχι ο parser,
γεννά trusted Observation/Receipt.

## 3. S — IMMUTABLE SOURCE / EVIDENCE HISTORY

### 3.1 Τύποι (I-16)
```
EvidenceBlob        := ⟨ blob_id = hash(bytes), bytes ⟩
CaptureObservation  := ⟨ observation_id = hash(canonical envelope ΧΩΡΙΣ receipt)
                       , blob_id, source_locator, observed_at
                       , transport_evidence, capture_principal ⟩
IntakeReceipt       := kernel-signed ⟨observation_id, received_at, intake-policy-version⟩
```
Ο canonical encoding νόμος του envelope = versioned R_ARTIFACT. Το receipt υπογράφει το id —
ποτέ μέσα σε αυτό που hash-άρεται (καμία κυκλικότητα).

### 3.2 Ιδιότητες
Append-only· διορθώσεις = νέες observations· quarantine σήμανση σε metadata, ποτέ αλλοίωση.
**Corroboration:** `corroborate(blob) = πλήθος ανεξάρτητων observations (διαφορετικό
locator/principal/χρόνος)` — υπολογίσιμο θεμέλιο για source-diversity απαιτήσεις admission.
Merkle checkpoints του S → attestation υλικό.

### 3.3 Acquisition edge
Fetchers/adapters/parsers = R3 attack surface: παράγουν μόνο candidates. Intake επικυρώνει
transport evidence, υπογράφει receipts, τηρεί intake policy (R_ARTIFACT).

### 3.4 SourceProbeObservation — αρνητικό/λειτουργικό evidence (DP#2 B5)
```
SourceProbeObservation := ⟨ probe_id, source_authority, attempted_at, request_profile
                          , outcome ∈ {SUCCESS, NOT_FOUND, TIMEOUT, AUTH_FAILURE,
                                       TRANSPORT_FAILURE, MALFORMED_RESPONSE, …}
                          , blob_id | ∅, capture_principal, signed_intake_record ⟩
```
- **Κανόνας bytes⇒blob:** αν ελήφθησαν bytes, το blob αποθηκεύεται ΠΑΝΤΑ, ανεξαρτήτως outcome —
  η κακοσχηματισμένη/ύποπτη απόκριση είναι forensic απόδειξη.
- Probe schedule/profiles = versioned R_ARTIFACT policy.
- Δίνει evidence στα `UNKNOWN{SOURCE_MISSING}` και θεμελιώνει το freshness envelope (§5.4):
  **κανένας ισχυρισμός current completeness χωρίς απόδειξη ότι το source mesh ήταν πρόσφατα
  operational.**

## 4. L — CANONICAL LEGAL EVENT LEDGER

### 4.1 Admission pipeline (μόνη είσοδος, fail-closed σε ΚΑΘΕ βήμα)
```
CaptureObservation(S) → Source Authority Policy → Authenticity/Integrity →
Untrusted-Parser candidate → Trusted Structural Validation → Identity Resolution →
Temporal/Semantic Validation → Conflict/Quarantine → Admission Decision →
LegalEffectEvent (R_LEGAL) + AdmissionDecision record (R_CONTROL)
```
Source Authority Policy = attested πίνακας αυθεντικών πηγών ανά είδος γεγονότος (ΦΕΚ ανά τεύχος,
δικαστήρια, ανεξάρτητες αρχές, ΕΕ) με ιεραρχία και χρονικά όρια. Αποτυχία/αμφιβολία ⇒ quarantine
queue με ρητό reason και SLA — ποτέ σιωπηλό skip.

### 4.2 Event taxonomy (κλειστή, versioned — ΜΟΝΟ legal-world μεταβολές)
```
Publication · Amendment · Correction(επίσημη/εκδοτική) · Commencement ·
ConditionalCommencement · Repeal · Revival · Renumber · Split · Merge ·
Retroactivity-scope · AdjudicativeOperativeEffect{…κατά τον attested classifier}
```
Κάθε `AdjudicativeOperativeEffect` φέρει από τον classifier: `effect_scope` (γενικός κανόνας |
συγκεκριμένη πράξη), `target_kind`, `temporal_effect` (ex tunc/ex nunc/ορισμένος χρόνος),
`authority_basis`. Η επίσημη διόρθωση ΦΕΚ = μεταβολή του κόσμου ⇒ L event `Correction`. Το δικό
μας λάθος admission = μεταβολή του μοντέλου μας ⇒ `AdmissionCorrection` στο R_CONTROL (§4.4).
`IdentityDecision`/`DiscoveryCorrection` ΔΕΝ υπάρχουν ως legal events.

### 4.3 LegalEffectEvent (canonical record)
```
LegalEffectEvent := ⟨ event_id (content-addressed), event_type + schema_version
                    , target_refs {StableEntityId[@EntityVersionId]…}
                    , operative_spec (typed — όχι free text)
                    , valid_time, tx_coord, evidence_set {observation_id…} ≥1
                    , admission_decision_ref (R_CONTROL), supersedes | ∅ ⟩
```
Append-only· «διόρθωση» = νέο event + supersedes· το παρελθόν ορατό στη known_at διάσταση.

### 4.4 Admission corrections — known-cut σημασιολογία
`AdmissionCorrection` (R_CONTROL) ενεργεί **από control cut**, όχι από wall-clock σύγκριση:
event ορατό σε cut K iff `tx_coord(event) ∈ K` ΚΑΙ δεν υπάρχει AdmissionCorrection που το ακυρώνει
με control coord ∈ K. Έτσι: cuts μεταξύ admission και correction δείχνουν τίμια τι πιστεύαμε·
μεταγενέστερα cuts το εξαιρούν· τίποτα δεν ξαναγράφεται.

### 4.5 Semantic identity — lineage constitution (I-19)
```
StableEntityId      — αιώνιο, ποτέ επαναχρησιμοποιούμενο (instrument/provision/decision/authority)
EntityVersionId     — συγκεκριμένη εκδοχή περιεχομένου υπό canonicalization version
IdentityAssertion   — «το κείμενο X είναι η οντότητα E@v» — supersedable
IdentityLineageEdge — merge/split/alias mapping μεταξύ entities/versions
```
Οι CanonicalizationDecisions/IdentityCorrections ζουν στο R_CONTROL· **το identity map είναι
PC-φέρουσα projection** (`projection_kind = identity-map`) επί R_CONTROL + R_ARTIFACT — bitemporal
και replayable: παλαιά cuts βλέπουν παλαιό map, νέα το διορθωμένο, κανένα ιστορικό reference δεν
μένει dangling (§17.19).

### 4.6 Διάταξη: partitioned monotonic + committed checkpoints
Partitions ανά δικαιοδοσία/πηγή· strictly monotonic sequence ανά partition· ο partition χάρτης =
versioned R_ARTIFACT με ceremony· `CheckpointCut := {partition→seq}` δεσμεύεται kernel-signed στο
R_CONTROL σε hash-chained αλυσίδα (κάθε cut κυριαρχεί τον προηγούμενο — ολική διάταξη)·
**deterministic merge rule** για projections: `(cut, partition_id, seq)` — η version του κανόνα
δεσμεύεται στο PC. Replay με οποιαδήποτε σειρά παράδοσης ⇒ ταυτόσημα roots (§17.14/17.17).

## 5. B — CANONICAL BITEMPORAL STATE

### 5.1 API αλήθειας (I-7)
`resolve(entity, valid_at, known_at: CheckpointCutId, context) → ResolvedState | UNKNOWN{…}`
Μοναδική production είσοδος για ισχύον δίκαιο· span-level provenance: κάθε ResolvedState ανάγεται
σε events → observations → blobs· `context` = forum/regime όπου απαιτείται.

### 5.2 Generalized Projection Certificate (DP#2 B3)
```
PC := ⟨ projection_kind ∈ {legal-state, claim-status, identity-map, freshness, …}
      , projector_spec (attested spec id), implementation_digest
      , input_roots { R_LEGAL: root/cut|∅ · R_EPISTEMIC: root/cut|∅ · R_ARTIFACT: root
                    , R_CONTROL: root/cut · R_SOURCE: root|∅ }
      , transaction_cut (CheckpointCutId), scope, canonicalization_version
      , merge_rule_version, output_root, toolchain_manifest ⟩
```
Κάθε projection δηλώνει ΑΚΡΙΒΩΣ ποιες Root classes κατανάλωσε: legal state ⇒
R_LEGAL+R_CONTROL+R_ARTIFACT· claim status ⇒ R_EPISTEMIC+R_LEGAL+R_CONTROL+R_ARTIFACT·
identity map ⇒ R_CONTROL+R_ARTIFACT· freshness ⇒ R_SOURCE+R_CONTROL+R_ARTIFACT.
Root χωρίς έγκυρο PC δεν είναι canonical. Μεταβολή οποιουδήποτε δηλωμένου input root ⇒ το PC
δεν επαληθεύει (§17.18).

### 5.3 Assurance tiers (σημασιολογία M5)
```
PROJECTED                 — ένας projector, έγκυρο PC
INDEPENDENTLY_VERIFIED    — ≥2 projectors κατά MIC συμφωνούν στο ίδιο scope/cut
RECONSTRUCTION_CERTIFIED  — INDEPENDENTLY_VERIFIED + ένταξη σε kernel-signed attestation checkpoint
```
Το tier πιστοποιεί **ανακατασκευή δηλωμένων inputs υπό δηλωμένο spec** — ποτέ ουσιαστική νομική
ορθότητα (I-14). Κάθε served απάντηση φέρει tier· serving-tier policy (versioned R_ARTIFACT):
ενδεικτικά G-pub έξοδοι και δικόγραφα ⇒ ≥ INDEPENDENTLY_VERIFIED (στόχος RECONSTRUCTION_CERTIFIED)·
εσωτερική έρευνα ⇒ PROJECTED με ρητή ετικέτα. Mismatch ⇒ REJECT + incident, ποτέ σιωπηλή υποβάθμιση.
Snapshots = PC-φέροντα caches σε committed cuts· replay από πλησιέστερο verified checkpoint.

### 5.4 Freshness envelope (DP#2 B5)
PC-φέρουσα projection επί probe history: ανά source authority ⇒ `last_success, failure streak,
coverage window`. Serving rule: ερώτημα «τρέχον δίκαιο» απαιτεί πλήρωση freshness policy·
αλλιώς `canonical state as-of cut K + freshness envelope` ή `UNKNOWN{INCOMPLETE_COVERAGE}` με
resolution_condition = ποιο probe θα το έλυνε. Outage δεν αλλάζει το παρελθόν — αφαιρεί το
δικαίωμα ισχυρισμού πληρότητας στο παρόν.

## 6. TEMPORAL SEMANTICS
- Canonical plane: `valid_time × known_at(cut)`. Forensic plane: ερωτήματα επί S/probes με
  `observed_at` — απαντήσεις ΠΑΝΤΑ επισημασμένες forensic, ποτέ ως ισχύον δίκαιο. Ποτέ μεικτές
  χωρίς ετικέτα.
- `admitted_wall_time` = audit μόνο· καμία σημασιολογική σύγκριση wall-clock στο canonical plane.
- Retroactivity: valid_time στο παρελθόν, tx_coord τώρα· προγενέστερα cuts αναλλοίωτα· STALE wave.
- ConditionalCommencement: πλήρωση αίρεσης = ΝΕΟ event με δικό του EvidenceSet.
- Ημερομηνιακή αριθμητική ΜΟΝΟ μέσω kernel temporal library.

## 7. E — EPISTEMIC PLANE (πλήρες, self-contained)

### 7.1 EpistemicClass (κλειστό enum + επιτρεπτές είσοδοι)
- `AUTHORITATIVE_TEXT` — ΜΟΝΟ μέσω L admission (K-src recompute-from-authentic-source)· ποτέ
  μέσω claim queue.
- `VERIFIED_OBSERVATION` — capture+receipt+hash επιβεβαιωμένο γεγονός παρατήρησης.
- `DETERMINISTIC_DERIVATION` — παράγωγο με A≥A2 από premises κλάσεων {AUTH, VERIF, DET}.
- `LEGAL_INTERPRETATION` — ερμηνεία/υπαγωγή με κρίση· πάντα ανατρέψιμη.
- `DISPUTED_INTERPRETATION` — interpretation με καταγεγραμμένη ενεργή αντίκρουση.
- `PREDICTION` — forecast· ποτέ νομική «αλήθεια».
- `UNKNOWN` — τίμια άγνοια, first-class (I-15).
**Απαγορευμένες μεταβάσεις (CC-1):** καμία ανοδική αλλαγή class μέσω confidence/votes/
επανάληψης/LLM-consensus (I-4). `INTERPRETATION→DETERMINISTIC` δεν υπάρχει ως μετάβαση — μόνο
ΝΕΟ assertion με δική του A≥A2 derivation, που supersedes το παλαιό. `→AUTHORITATIVE_TEXT` μόνο
από L admission.

### 7.2 ClaimAssertion (αμετάβλητο root record — R_EPISTEMIC)
```
ClaimAssertion := ⟨ claim_id (content-addressed), claim_type ∈ {legal-state, in-force,
                    subsumption, deadline, conflict, interpretation, prediction, impact, meta}
                  , statement (typed proposition — όχι free text στο trusted layer)
                  , epistemic_class, confidence_in_class ∈ [0,1]|∅ (μόνο εντός class)
                  , derivation_assurance (A-level), formalization_fid (F-level)
                  , coverage_stamp, world_context (InterpretationWorld id)
                  , valid_time, evidence_set {observation/event/claim refs} ≥1
                  , dependency_set {claim_id | StableEntityId@version | authority_ref…}
                  , created_by (principal+version), supersedes | ∅ ⟩
```
**ΧΩΡΙΣ lifecycle field, ΧΩΡΙΣ admission timestamp** — η ίδια assertion υπάρχει ως candidate
πριν το admission· το `tx_coord` ζει στο `ClaimAdmissionDecision` (R_CONTROL). Μαζί δίνουν την
bitemporal epistemic history (DP#2 M3).

### 7.3 A-levels / F-levels / Coverage (κλειστές κλίμακες)
**A (derivation assurance):** A0 unchecked (μη-εκπεμπόμενο ως trusted) · A1 replay από ΤΟ ΙΔΙΟ
implementation (όχι independence) · A2 certificate ελεγμένο από ΑΝΕΞΑΡΤΗΤΟ checker · A3 A2 +
N-version συμφωνία · A4 A3 + machine-checked θεώρημα για τον checker. Άνοδος ΜΟΝΟ με προσθήκη
evidence artifact· ποτέ με ψήφους.
**F (formalization fidelity, ταβάνι F3):** F0 μηχανική εξαγωγή μη-επικυρωμένη · F1 ένας ειδικός,
χωρίς scope/date δέσμευση · F2 διπλή ανεξάρτητη φορμαλοποίηση reconciled + back-translation +
scoped+dated · F3 F2 + contrastive suite + re-attestation trigger σε source changes. **F3 =
ταβάνι· EMPIRICAL πάντα· ποτέ THEOREM.** In-scope source change ⇒ F πέφτει (STALE) μέχρι
re-attestation.
**Anti-laundering:** A ποτέ δεν αναβαθμίζει F· συνολική ισχύς = min των αξόνων στο πεδίο.
**Coverage := ⟨C: construal-set id+hash, S: source-set@versions, T: time-window, W: world-set,
G: generator-manifest⟩** — κάθε ισχυρισμός πληρότητας σχετικός με stamp· ελλιπές stamp ⇒ REJECT.

### 7.4 Claim admission (μόνη είσοδος στο R_EPISTEMIC)
```
ClaimCandidate (non-root proposal/scratch queue — εκεί γράφουν agents/humans/engines)
      ↓  class-specific admission (K-cl family — πίνακας = versioned R_ARTIFACT)
AdmittedClaimAssertion (R_EPISTEMIC) + ClaimAdmissionDecision (R_CONTROL, φέρει tx_coord)
```
Απαιτήσεις ανά class: DETERMINISTIC_DERIVATION ⇒ derivation certificate από ανεξάρτητο checker
(A≥A2)· LEGAL_INTERPRETATION ⇒ evidence set + admissible principal/model provenance + policy·
DISPUTED ⇒ ρητό conflict edge· PREDICTION ⇒ model/evaluation manifest· VERIFIED_OBSERVATION ⇒
receipts· UNKNOWN ⇒ πλήρης I-15 δομή. Ενιαία έδρα: ΟΛΟΙ περνούν admission — trusted engine
certificate = αυτόματο/φθηνό admission, όχι παράκαμψη.
**Rejection semantics (DP#2 M1):** απόρριψη candidate = non-root disposition στην ουρά (bounded
audit δείγμα στο R_CONTROL μετά από quota gate)· το root-level `CLAIM_REJECTED` σημαίνει ΜΟΝΟ
«previously admitted assertion invalidated μέσω governed process». Flooding γεμίζει την ουρά
(quota/TTL στο P-plane), ποτέ το Root (§17.12).

### 7.5 Supersession — μία έδρα (DP#2 M2)
Authoritative seat = το `supersedes` πεδίο του ΝΕΟΥ admitted assertion, επικυρωμένο από το
ClaimAdmissionDecision του. Το `CLAIM_SUPERSEDED` ΔΕΝ είναι ανεξάρτητο root fact — είναι derived
status. Δύο root facts που μπορούν να διαφωνήσουν δεν υπάρχουν.

### 7.6 Status = derived bitemporal projection
`status(claim, valid_at, known_at) ∈ {ACTIVE, STALE, SUPERSEDED, REJECTED}` — υπολογίζεται από
`R_EPISTEMIC + R_LEGAL + R_CONTROL + R_ARTIFACT` στο δηλωμένο cut· υλοποιήσεις = caches.
**Ο status projector είναι canonical projection υπό I-14** (PC kind=claim-status, tiers) — αλλιώς
bug του σερβίρει STALE ως ACTIVE αόρατα. Dependency μεταβολή ⇒ STALE ορατό στο επόμενο cut·
φραγμένο freshness bound (R-b).

### 7.7 Worlds & disputes
`InterpretationWorld = ⟨fact-world × construal-set × forum⟩`· ανταγωνιστικές ερμηνείες
συνυπάρχουν ως assertions με SUPPORTS/CONFLICTS_WITH σχέσεις — το σύστημα δεν «διαλέγει» δόγμα
ως fact. Dialectic δέντρα (επιχείρημα/αντεπιχείρημα) χτίζονται επί αυτών στο N/C.

## 8. N — NORMATIVE / CASE
- **Normative IR** = typed, versioned authored R_ARTIFACT: norms με atoms δεμένα σε source spans
  (`atom → EntityVersionId → event → observation`), deontic τελεστές, exceptions/defeasibility,
  applicability conditions, χρονικό scope. Acceptance: `serialize → parse → ταυτό IR` + πλήρης
  atom→span κάλυψη· text round-trip = διαγνωστικό, όχι κριτήριο. Είσοδος μέσω
  ArtifactAdmissionCertificate (§15.1), F-graded.
- **Inference:** dependency-tracked συμπερασματολογία (JTMS-class), well-founded semantics για
  defeasibility, event calculus για καταστάσεις/προθεσμίες. Κάθε συμπέρασμα εκπέμπεται ΜΟΝΟ ως
  ClaimCandidate → §7.4 — κανένα ιδιωτικό «κανάλι αλήθειας».
- **Case layer:** υπαγωγή, precedent, dialectic, deadlines/δικονομικά βήματα ως executable
  κανόνες που παράγουν deadline claims· όλα τα αποτελέσματα = ClaimCandidates· τίποτα δεν
  γράφει S/L/R_CONTROL.

## 9. C — DERIVED KNOWLEDGE / QUERY / IMPACT
- Graph/RDF/SPARQL/search/embeddings/indexes: ΟΛΑ caches (I-12). Κάθε epistemic ακμή
  (INTERPRETS, DEPENDS_ON, SUPPORTS, CONFLICTS_WITH, AMENDS-derived) φέρει claim/event καταγωγή —
  «γυμνή» ακμή δεν υπάρχει στο σχήμα.
- **Conformance classes:** DETERMINISTIC (byte-identical rebuild — υποχρεωτικό για canonical
  serializations/roots/event projections) | SEMANTIC (functional conformance κατά δηλωμένο τεστ —
  embeddings/ANN/search internals). SEMANTIC cache ποτέ μοναδικός φορέας authoritative
  πληροφορίας. `DELETE any cache ⇒ REBUILD από R` κατά την class του.
- Impact: νέο L event ⇒ dependency graph ⇒ σύνολο επηρεαζόμενων claims ⇒ STALE στο επόμενο cut +
  review queues· mass invalidation φραγμένη και μετρήσιμη.

## 10. INTELLIGENCE PLANE (AI) — εκτός αλήθειας
Ρόλοι (extractor, researcher, counsel/counter-counsel, critic, citation-checker, synthesizer) =
R3/untrusted· ΚΑΝΕΝΑ authoritative state ownership. Έξοδοι ΜΟΝΟ ως: admission candidates (§4.1)
ή ClaimCandidates (§7.4) κλάσεων LEGAL_INTERPRETATION/PREDICTION με A0/A1 + generator manifest.
Ποτέ DETERMINISTIC/AUTHORITATIVE. Egress ΜΟΝΟ μέσω G-inf (I-6)· prompts/responses/contexts =
matter-tagged, compartmented. Retrieval accelerators = SEMANTIC caches.

## 11. P — PRACTICE / PRIVILEGE / SECURITY PLANE

### 11.1 Matter isolation (structural absence)
Isolation = απουσία handle σε ΟΛΟ το surface: canonical stores, vector indexes, caches,
embeddings, temp files, logs, traces, exception dumps, backups, snapshots, agent memory, model
context windows, exported artifacts, analytics/telemetry. Cross-matter πρόσβαση = μη σχηματίσιμο
ερώτημα — ποτέ policy άρνηση που διαρρέει ύπαρξη (I-15).

### 11.2 Data classes & capabilities
`{PUBLIC, INTERNAL, CLIENT_CONFIDENTIAL, PRIVILEGED, WORK_PRODUCT, RESTRICTED}`·
PRIVILEGED/RESTRICTED ⇒ external egress capability δομικά απούσα. Κάθε write/egress με issued
capability `⟨issuer, holder, scope (matter/authority-class), expiry, bounded delegation-chain,
revocation-hook, replay-nonce, audit-binding, SoD-tag⟩`· issuance/revocation history = R_CONTROL.
**Break-glass:** χωριστός τύπος — 2-person issuance, ρητό expiry, loud incident + auto-review,
καμία delegation.

### 11.3 Publication
**Αρχιτεκτονικός νόμος:** `PUBLIC-class ∧ release-policy-approved ∧ privilege-safe ⇒ publication
candidate` — τίποτα άλλο δεν φτάνει σε staging. Το ΤΙ επιτρέπεται = versioned G-pub policy
artifact· **policy v1 = η εντολή του δημιουργού: δημόσιο = μόνο κωδικοποιημένοι δημόσιοι νόμοι**
(αλλάζει μόνο με ρητή δική του απόφαση). G-pub failure ⇒ publication disabled, fail-closed,
κανένα weaker bypass· canary + stego red-team καθεστώς κάθε release. Deadlines/conflicts/ethical
walls = policy state του plane (deadline claims παράγονται στο N, επιτηρούνται εδώ).

## 12. D — VERIFICATION & TRUST DISTRIBUTION

### 12.1 Internal independence τώρα · federation με πραγματικό diversity
Χωριστοί verifiers ανά critical function (admission checkers, proof checkers, projector B) —
χωριστό θεμέλιο, build, state reconstruction. Attestation checkpoints: kernel-signed
⟨S-root, L-roots ανά partition, R_CONTROL chain head, golden state roots, PCs, admission stats,
TrustAnchor fingerprint⟩ — offline επαληθεύσιμο bundle από τρίτο. Federation (institutional
witness, federated verifier, independent observatory) ΟΤΑΝ υπάρξει δεύτερος πραγματικός θεσμός·
**καμία federation-of-one.**

### 12.2 Minimum Independence Contract — MIC v2 (DP#2 B6)
Δύο υλοποιήσεις είναι ανεξάρτητες iff:
1. **0 shared critical semantic implementation code.** Κοινά ΜΟΝΟ: frozen spec + conformance
   vectors.
2. **Independent critical dependency closure** — καμία κοινή βιβλιοθήκη/generated component στο
   semantic critical path (parser, canonicalization, projector algorithm, ruleset compiler)·
   επαληθεύσιμο με manifest diff. **Η διαφορετική γλώσσα είναι ένδειξη, ΠΟΤΕ υποκατάστατο** του
   κριτηρίου αυτού.
3. **Καμία κοινή καταγωγή:** καμία υλοποίηση δεν παράγεται με μετάφραση/transpilation της άλλης
   ή κοινού μη-spec προγόνου (ο «μεταφρασμένος ίδιος buggy helper» απαγορεύεται ρητά).
4. **Ανεξάρτητο build + runtime** (χωριστό toolchain manifest).
5. **Shared foundations** επιτρέπονται ΜΟΝΟ αν: (α) δηλωμένες ρητά ως common trust assumptions,
   (β) εκτός του συγκρινόμενου semantic logic, (γ) με δικό τους conformance/alternative-
   verification καθεστώς. (SHA-256 primitive: ναι· canonicalization parser: όχι.)
6. **Mutation/defect-seeding batteries** από τις error classes του spec — και οι δύο τις περνούν.
7. **Disagreement resolution law:** διαφωνία ⇒ διόρθωση spec μέσω ceremony· ΠΟΤΕ αντιγραφή της
   συμπεριφοράς της άλλης υλοποίησης χωρίς spec αλλαγή.
8. **SoD:** διαφορετικός συντάκτης/θεμέλιο ανά υλοποίηση.
Υπόλειμμα: κοινό conceptual bug ΣΤΟ spec — δηλωμένο spec-level residual, αντιμετωπίζεται με
contrastive fixtures + εξωτερική αναπαραγωγή (§17.10), όχι με ψευδή ισχυρισμό πλήρους ανεξαρτησίας.

## 13. ROOT SET & REBUILD

### 13.1 Πέντε κλάσεις (I-12, I-17)
```
R_SOURCE    blobs · observations · probes · intake receipts          authority: ΚΑΜΙΑ
R_LEGAL     admitted LegalEffectEvents                               authority: CANONICAL
R_EPISTEMIC admitted ClaimAssertions                                 authority: interpretation-grade
R_ARTIFACT  schemas · rulepacks · Normative IR · projector specs ·   authority: formalization/
            policy tables · classifiers · partition maps              policy (F-graded)
R_CONTROL   AdmissionDecision · AdmissionCorrection ·                authority: control-plane
            ClaimAdmissionDecision · ArtifactAdmissionCertificate ·   ιστορικά γεγονότα —
            IdentityCorrection/CanonicalizationDecision ·             ΟΧΙ νομικό περιεχόμενο
            capability issuance/revocation · ceremonies ·
            checkpoints (cut chain) · PCs · attestation records
```
Όλα append-only, content-addressed, merkle-checkpointed, μέγιστο durability καθεστώς
(fsync πειθαρχία, πολλαπλά αντίγραφα, offline copies).

### 13.2 Reconstruction equations
```
EffectiveLegalEvents(K)  = AdmitView(R_LEGAL, R_CONTROL, K)
CanonicalLegalState(K)   = Project(EffectiveLegalEvents(K), relevant R_ARTIFACT, K)
EpistemicState(K)        = Evaluate(R_EPISTEMIC, CanonicalLegalState(K), R_CONTROL, R_ARTIFACT, K)
DerivedStores            = Cache(CanonicalLegalState, EpistemicState)
```
Το R_SOURCE θεμελιώνει/επαληθεύει admissions — δεν γίνεται legal truth επειδή είναι immutable.
**Νόμος ανακατασκευής:** από το R και μόνο: byte-identical canonical roots (DETERMINISTIC) και
κάθε cache κατά την class του. DR = προγραμματισμένο discharge test κάθε release, όχι έκτακτο.

## 14. SCALE MODEL
Read φορτίο ⇒ caches· Root δέχεται μόνο admission ρυθμούς· incremental projections με PC ανά
committed cut· partitions κλιμακώνουν admission ανεξάρτητα· verification offline/async από το
serving path· substrate επιλογή caches = μη-αρχιτεκτονική απόφαση (I-12).

## 15. UPGRADEABILITY

### 15.1 R_ARTIFACT entry
```
ArtifactAdmissionCertificate := ⟨ artifact_digest, author, reviewer(s), A/F όπου εφαρμόζεται
                                , applicability/scope, supersedes, ceremony record ref
                                , effective_version ⟩   — ζει στο R_CONTROL
```
Κάθε G-sev ceremony παράγει canonical admission record — όχι πρακτικό.

### 15.2 R_CONTROL entry (τερματισμός regress — I-20)
R_CONTROL records εισέρχονται μέσω kernel capability rules: kernel-signed, hash-chained,
υπό τα capability/SoD καθεστώτα του §11.2 — **ΟΧΙ μέσω ArtifactAdmissionCertificate του εαυτού
τους.** Η αλυσίδα υπογραφών τερματίζει στο TrustAnchor (genesis record + kernel root keys +
rotation history), το οποίο είναι ρητά αξιωματικό και τυπώνεται σε κάθε attestation bundle.

### 15.3 Evolution
Event/claim schemas versioned· παλαιά records ποτέ ξαναγραμμένα· upcast functions = versioned
R_ARTIFACT· projector αλλαγή ⇒ νέα PC γενιά + differential report πριν γίνει αποδεκτή· κλειστά
enums (taxonomy, EpistemicClass, UNKNOWN reasons, tiers) επεκτείνονται ΜΟΝΟ με ceremony·
autonomy = sandbox προτάσεις σε ουρά (governance), ποτέ αυτο-εφαρμογή.

## 16. FAILURE / DEGRADATION MATRIX
Στήλες: τι σερβίρεται ασφαλώς · ελάχιστο tier · τι γίνεται UNKNOWN · τι μπλοκάρεται · recovery authority.

| Κατάσταση | Σερβίρεται | Min tier | UNKNOWN | Μπλοκάρεται | Recovery |
|---|---|---|---|---|---|
| **SOURCE_MESH_DEGRADED** | historical resolve σε κάθε committed cut | κατά policy | current-completeness ⇒ `INCOMPLETE_COVERAGE` με freshness envelope | τίποτα εσωτερικό | ops capability· probe επανεκκίνηση |
| **ROOT_CORRUPTION_DETECTED** | ΜΟΝΟ cuts ≤ τελευταίο verified checkpoint | RECONSTRUCTION_CERTIFIED | ό,τι μετά το ύποπτο cut | admissions + certifications | break-glass (2-person) + rebuild από αντίγραφα + incident |
| **KEY_COMPROMISE** | read-only προηγούμενα certified cuts, με ρητή προειδοποίηση | RECONSTRUCTION_CERTIFIED προ-συμβάντος | ό,τι υπογράφηκε στο ύποπτο διάστημα | ΟΛΕΣ οι admissions + publications + νέες υπογραφές | key rotation ceremony (G-sev) + re-attestation από τελευταίο καθαρό checkpoint |
| **PROJECTOR_DISAGREEMENT** | scopes εκτός διαφωνίας κανονικά | affected scope ⇒ ΔΕΝ σερβίρεται όπου policy > PROJECTED | affected αποτελέσματα κατά policy | release του affected scope | spec ceremony (MIC κανόνας 7) |
| **CONTROL_ROOT_DIVERGENCE** | τελευταίο κοινό certified cut | RECONSTRUCTION_CERTIFIED | ό,τι μετά τη διάσταση | admissions + certifications + ceremonies | break-glass forensic + governance απόφαση |
| **CACHE_LOSS** | όλα — αργότερα (rebuild) | αμετάβλητο | τίποτα | τίποτα | ops· rebuild ρουτίνα §13.2 |
| **AI_UNAVAILABLE** | πλήρες canonical/temporal/normative core | αμετάβλητο | τίποτα | νέες AI proposals (ουρά παγώνει) | ops |
| **EXTERNAL_EGRESS_DISABLED** | όλα τα εσωτερικά | αμετάβλητο | τίποτα | G-inf calls (fail-closed)· publication κατά G-pub status | ops + policy |

Γενικοί κανόνες: default fail-closed σε κάθε trusted απόφαση· crash σε predicate ⇒ REJECT +
incident, ποτέ ALLOW· quarantine με ρητό SLA/escalation· κάθε incident journaled στο R_CONTROL,
capability-bound, με post-mortem υποχρέωση. **Acquisition outage δεν αλλάζει ποτέ το παρελθόν —
αφαιρεί μόνο το δικαίωμα ισχυρισμού πληρότητας πέρα από το τελευταίο freshness-certified cut.**

## 17. ARCHITECTURE EXPERIMENTS — 21 falsifiers (πύλη → DEMONSTRATED)
Κάθε ένα με δηλωμένο fixture universe + metric + threshold + failure action πριν εκτελεστεί.
1. **Temporal replay torture** — grid (entity × valid_at × cut) με retroactivity/corrections/
   conditional commencements· resolve ντετερμινιστικό = ανεξάρτητος projector.
2. **Full reconstruction** — καταστροφή ΟΛΩΝ των caches· rebuild από R· byte-identical roots.
3. **Poisoned admission** — πλαστή πηγή/πειραγμένο digest/αναρμόδια αρχή ⇒ 0 admissions·
   ανιχνεύσιμα στο S χωρίς authority.
4. **Projector N-version disagreement** — εμφυτευμένο bug ⇒ διαφωνία ανιχνεύεται, release BLOCK.
5. **Claim laundering** — απαγορευμένες μεταβάσεις/A→F αναβάθμιση ⇒ 100% REJECT.
6. **Mass invalidation** — αναδρομικός νόμος/ακύρωση ⇒ φραγμένο STALE wave· 0 STALE served ACTIVE.
7. **Matter escape** — red-team σε όλο το §11.1 surface + inference channels ⇒ 0 bytes, 0 signals.
8. **Schema evolution** — schema v+1 + upcast ⇒ replay παλαιού L· roots σταθερά ή εξηγημένο diff.
9. **Disaster recovery** — χρονομετρημένο πλήρες rebuild σε καθαρό host· certificates verify· RTO.
10. **Independent reproduction** — τρίτη minimal υλοποίηση αναπαράγει golden roots από R.
11. **Observation identity torture** — ίδια bytes, 2 πηγές/χρόνοι ⇒ 1 blob, 2 observations·
    corroboration σωστό· καμία διπλο-admission.
12. **Claim flooding** — R3 πλημμύρα candidates ⇒ Root ανέγγιχτο· quotas ενεργά.
13. **Backdating attempt** — quarantine → admission ⇒ κανένα cut προ-admission δεν το βλέπει·
    forensic plane δείχνει observed_at.
14. **Partition merge determinism** — ανακατεμένη σειρά παράδοσης ⇒ ταυτόσημα roots.
15. **Tier mislabel** — PROJECTED σε context που απαιτεί RECONSTRUCTION_CERTIFIED ⇒ REJECT.
16. **Control-root genesis/regress** — δημιουργία ArtifactAdmissionCertificate χωρίς αναδρομική
    αλυσίδα πιστοποιητικών· επαληθεύσιμος τερματισμός στο TrustAnchor.
17. **Transaction-cut race** — admissions σε 3 partitions με wall-clock reordering ⇒ ίδιο
    committed cut, ίδιο canonical root ανεξαρτήτως delivery timing.
18. **Claim-status PC tamper** — αλλαγή R_EPISTEMIC root χωρίς αλλαγή PC ⇒ verification FAIL.
19. **Re-canonicalization identity torture** — v2 διορθώνει λάθος merge/split ⇒ παλαιά cuts
    κρατούν παλαιό map, νέα το διορθωμένο, κανένα dangling ref.
20. **Source-freshness outage** — probes αποτυγχάνουν για ορισμένο διάστημα ⇒ current-
    completeness ΔΕΝ σερβίρεται ως fresh· historical queries σωστά.
21. **False-independence trap** — 2 γλώσσες, κοινό critical dependency ⇒ MIC REJECT.

## 18. RESIDUALS (τελική κατάσταση προ freeze)
- **R-a** — περιεχόμενο erga-omnes classifier (με τα M6 πεδία): νομική έρευνα προς F-graded
  attestation· το I-13 fail-closed μονοπάτι καλύπτει το μεσοδιάστημα. RESIDUAL.
- **R-b** — freshness bound της status projection: αριθμητικός στόχος στο freeze. OPERATIONAL.
- **R-c** — **ΚΛΕΙΣΤΟ** με MIC v2 (§12.2)· υπόλειμμα = δηλωμένο spec-level common-mode.
- **R-d** — **ΚΛΕΙΣΤΟ** (§7.4/7.5 + M1/M2 semantics).
- **R-e** — federation protocol: intentionally later. RESIDUAL.
- **R-f** — checkpoint cadence & quarantine SLA τιμές: στο freeze. OPERATIONAL.
- **R-g** — semantic-conformance πρότυπα ανά SEMANTIC cache τύπο: πριν το αντίστοιχο build. RESIDUAL.
- **R-h (ΝΕΟ)** — μορφή attestation bundle για εξωτερικό verifier (δένει με R-e). RESIDUAL.

---

**Πύλη:** Freeze-readiness audit Reviewer-B επί του παρόντος (κατά δήλωσή του: όχι redesign pass,
εφόσον δεν προκύψει νέα circular authority ή mutable truth path) → TARGET ARCHITECTURE v1.0 —
READY FOR CREATOR FREEZE DECISION → ρητό «εγκρίνω freeze target» του δημιουργού → το
MERGED-BLUEPRINT v0.8 ξαναδένεται ως migration plan (v0.9) προς το v1.0. Καμία production αλλαγή πριν.
