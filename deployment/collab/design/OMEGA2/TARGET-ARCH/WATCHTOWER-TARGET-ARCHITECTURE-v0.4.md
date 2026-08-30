# WATCHTOWER VLT — TARGET ARCHITECTURE v0.4 — FINAL FREEZE CANDIDATE
**Layered Verifiable Legal Twin — μετά το Freeze-Readiness Audit (κοινό artifact Reviewer-A × Reviewer-B)**

**Status: DESIGN HYPOTHESIS — FINAL FREEZE CANDIDATE.** Πλήρως self-contained normative spec:
ό,τι δεσμεύει είναι γραμμένο εδώ αυτούσιο· καμία κανονιστική αναφορά σε προηγούμενα drafts.
Καθαρό target: μηδέν migration, μηδέν legacy paths. DEMONSTRATED μόνο όταν περάσουν και τα 27
πειράματα του §17 εντός δηλωμένων fixture universes. Πύλη: τελικό audit Reviewer-B (κριτήρια:
καμία νέα circular authority, κανένα mutable historical truth, κανένα unrecoverable split-brain)
→ «TARGET ARCHITECTURE v1.0 — READY FOR CREATOR FREEZE DECISION» → ρητό «εγκρίνω freeze target»
του δημιουργού → το MERGED-BLUEPRINT ξαναδένεται ως migration plan v0.9. Καμία production αλλαγή πριν.

## RESPONSE MAP (Freeze audit εύρημα → πού κλείνει)
| Εύρημα | Κλείσιμο |
|---|---|
| FB1 atomic multi-root commit | §13.3 **Root Commit Law** (prepare/commit, tx_coord από RootCommit) + αντι-εύρημα A-1: per-namespace commit chains + ADR |
| FB2 PC↔R_CONTROL self-reference | **I-21** — no self-certifying Root object· DAG causal order (§13.4) |
| FB3 cut δεσμεύει control prefix | §4.6: CheckpointCut v2 ⟨cut_id, parent, legal heads, control_head/root⟩· corrections effective μόνο via cut inclusion |
| FB4 R_LEGAL reconstruction sufficiency | §4.3: `transition_payload` + **self-sufficiency law** + discharge LEGAL-REPLAY-SUFFICIENCY (πείραμα 25) |
| M1 cut-scoped view roots | §5.2: PC δεσμεύει `*ViewRoot(K, scope)` — ποτέ future-inclusive store root |
| M2 TrustAnchor immutable | **I-20** αναθεωρημένο: TrustAnchorGenesis· rotation history = R_CONTROL· offline recovery quorum (§15.2, §16) |
| M3 A/F immutable ιστορικά | §7.3: FormalizationStatus/AssuranceStatus = derived· re-attestation = ΝΕΟ assertion/artifact |
| M4 matter Root namespaces | §11.4 + αντι-εύρημα A-2: **blind anchoring** (residual R-i με σκληρή απαίτηση 0 existence signal) |
| M5 γενικός envelope law | **I-22** — ObjectId = hash(unsigned payload)· υπογραφές εκτός hash |
| M6 scoped FreshnessEnvelope | §5.4: envelope ανά ⟨jurisdiction, source set, classes, window⟩ — ποτέ global boolean |
| KEY_COMPROMISE recovery chain | §16 (offline quorum· compromised key δεν πιστοποιεί τον αντικαταστάτη του) |
| Experiments 22–27 | §17 |
| Αντι-εύρημα A-3 staging hygiene | §13.3: staging εντός compartment, TTL/GC, journaled καταστροφή |

---

## 0. CONSTITUTION — I-1…I-22 (πλήρες κείμενο, μη διαπραγματεύσιμο)

**I-1.** Κανένα LLM δεν αποτελεί trust root· κανένα LLM στο trusted path.
**I-2.** Κανένας verifier δεν είναι αξιόπιστος επειδή ελέγχει output του ίδιου implementation
από το οποίο παρήχθη.
**I-3.** Κανένα subsystem δεν φέρει implicit authority· κάθε εξουσία ρητή, τυπωμένη, ελέγξιμη.
**I-4.** Κανένα confidence score, ψήφος, επανάληψη ή consensus δεν μετατρέπει interpretation σε fact.
**I-5.** Κανένα derived conclusion χωρίς evidence set και dependency state· dependency μεταβολή ⇒
STALE στο επόμενο cut· STALE δεν σερβίρεται ως ACTIVE.
**I-6.** Κανένα external AI/provider call δεν παρακάμπτει matter/privilege/egress policy.
**I-7.** Καμία production απόφαση legal temporal state έξω από τη μοναδική canonical temporal
authority (`resolve` — §5.1).
**I-8.** Boundaries machine-enforced· καμία σύμβαση καλής θέλησης.
**I-9.** Κάθε φάση/ιδιότητα με executable discharge condition.
**I-10.** Κάθε νέα μηχανή πρώτα σε shadow/differential όπου εφικτό.

**I-11 — Δύο ledgers, μία υποχρεωτική αναφορά.** Evidence history (S) ≠ legal-event history (L).
`LegalEffectEvent MUST reference EvidenceSet = {CaptureObservation…} ≥1`. Poisoned capture ζει
για πάντα στο S χωρίς authority: η authority απονέμεται ΜΟΝΟ από admission. Immutability ≠ correctness.

**I-12 — Root-or-Cache (πενταμερές, με admission και commit).**
`R := R_SOURCE ∪ R_LEGAL ∪ R_EPISTEMIC ∪ R_ARTIFACT ∪ R_CONTROL` (§13). Κάθε store: μέλος του R
ή αποδεδειγμένα cache του R — τρίτη κατηγορία απαγορεύεται. Είσοδος σε κάθε class ΜΟΝΟ μέσω του
admission καθεστώτος της, και effectiveness ΜΟΝΟ μέσω RootCommit (§13.3). Reconstruction
equations: §13.2.

**I-13 — Operative-effect criterion + no-best-guess + effect scope.** Από δικαιοδοτική πράξη στο
L εισέρχεται ΜΟΝΟ το operative erga omnes αποτέλεσμα του διατακτικού που μεταβάλλει legal state
κατά το ισχύον δίκαιο (π.χ. ΑΕΔ άρθρο 100 §4 Σ· ακυρωτικό αποτέλεσμα ΣτΕ κατ' άρθρο 95 Σ και τη
δικονομία του). Ratio/δόγμα/inter partes = πάντα Claims. Ο κατατακτήριος πίνακας = attested,
F-graded R_ARTIFACT με `{effect_scope, target_kind, temporal_effect, authority_basis}`. Χωρίς
την απαιτούμενη assurance: ΚΑΝΕΝΑ event· UNKNOWN/DISPUTED Claim. Ποτέ best-guess admission.

**I-14 — Certified reconstruction, tiered.** Κάθε canonical projection εκπέμπει generalized PC
(§5.2) που δεσμεύει cut-scoped views ΟΛΩΝ των Root inputs. Tiers {PROJECTED,
INDEPENDENTLY_VERIFIED, RECONSTRUCTION_CERTIFIED} (§5.3)· κάθε served απάντηση δηλώνει tier·
ελάχιστο tier ανά context = versioned policy· release-critical roots ⇒ συμφωνία ανεξάρτητου
projector κατά MIC· διαφωνία ⇒ BLOCK. Το tier πιστοποιεί ανακατασκευή δηλωμένων inputs υπό
δηλωμένο spec — ΠΟΤΕ ουσιαστική νομική ορθότητα.

**I-15 — UNKNOWN semantics.** Κλειστό versioned reason enum {SOURCE_MISSING, TEMPORAL_AMBIGUITY,
CONFLICTING_AUTHORITIES, UNRESOLVED_IDENTITY, INSUFFICIENT_FORMALIZATION, INCOMPLETE_COVERAGE,
POLICY_RESTRICTED} + evidence + scope + resolution_condition. No-silent-coercion. Προσθήκη
reason = ceremony. POLICY_RESTRICTED μόνο για publication/egress — ποτέ cross-matter σήμα.

**I-16 — Typed identity.** Content identity (blob_id) ≠ observation identity (observation_id) ≠
semantic legal identity (§4.5). Same bytes ⇒ same blob· same bytes ≠ same observation· καμία
semantic ταυτότητα από byte ισότητα.

**I-17 — Root ≠ Truth.** Root membership = μη ανακατασκευάσιμο durable input για ιστορική
αναπαραγωγή — ΟΧΙ authority. Κάθε Root object: `root_class, authority_class, admission_class`
χωριστά. Μόνο R_LEGAL = canonical legal-state authority.

**I-18 — Χρονικό μοντέλο.** `valid_time` (legal-world) · `observed_at` (forensic wall-clock) ·
`admitted_wall_time` (audit μόνο) · `tx_coord` (logical συντεταγμένη, απονέμεται ΜΟΝΟ από
RootCommit — §13.3). **`known_at := CheckpointCutId`** — ΜΟΝΟ committed cuts (§4.6), σε
hash-chain με ολική διάταξη. Quarantine υλικό δεν εμφανίζεται ως γνώση πριν το commit του
ενταχθεί σε cut.

**I-19 — Immutable semantic identity lineage.** StableEntityId ποτέ επαναχρησιμοποιούμενο·
canonicalization αναβάθμιση δεν ξαναγράφει ιστορικά identifiers· λάθος = append-only
IdentityCorrection (R_CONTROL)· merge/split = lineage mappings· παλαιά cuts βλέπουν παλαιό map.

**I-20 — Αμετάβλητο Trust Anchor (αναθ. M2).**
`TrustAnchorGenesis := ⟨genesis ceremony record, initial trust-root public keys,
recovery-policy digest⟩` — τα ΜΟΝΑ αξιωματικά, μη-πιστοποιημένα αντικείμενα, τυπωμένα σε κάθε
attestation bundle. **Η key rotation history ΔΕΝ είναι μέρος του αξιώματος** — είναι R_CONTROL
history επαληθευόμενη ΑΠΟ το genesis anchor. Recovery authority = χωριστό offline quorum κατά το
recovery-policy digest· **compromised key δεν μπορεί να πιστοποιήσει τον αντικαταστάτη του.**

**I-21 — No self-certifying Root object (ΝΕΟ — FB2).** Κανένα Root object δεν περιλαμβάνεται,
άμεσα ή έμμεσα, στο commitment που χρησιμοποιεί για να πιστοποιήσει τον εαυτό του. Κάθε
certificate/PC/attestation/checkpoint δεσμεύει ΜΟΝΟ control prefix που **αιτιωδώς προηγείται**
του ίδιου: `PC(K)` δεσμεύει `root_at(K)` και εισέρχεται στην αλυσίδα ΜΕΤΑ το K. DAG causal
order παντού· κατασκευή που το παραβιάζει = αδύνατη/REJECT (πείραμα 23).

**I-22 — Γενικός envelope law (ΝΕΟ — M5).** Για ΚΑΘΕ Root record:
`ObjectId = hash(canonical_unsigned_payload)` · `SignedEnvelope = ⟨ObjectId, signature(s),
certificate refs⟩` χωριστά. Υπογραφές/πιστοποιητικά ΔΕΝ συμμετέχουν ποτέ στο hash που απαιτείται
για αναφορά στο object — καμία κρυφή hash circularity σε events, commits, decisions, PCs,
certificates. Ο canonical encoding νόμος κάθε payload = versioned R_ARTIFACT.

---

## 1. ΟΙ ΕΞΙ ΣΥΣΤΑΤΙΚΟΙ ΑΞΟΝΕΣ
| Άξονας | Ερώτημα | Απάντηση VLT |
|---|---|---|
| **A** topology/authority | ποιος κρατά τα κλειδιά | trusted kernel + capabilities + domain DAG |
| **B** truth/time | τι είναι η αλήθεια, πώς αλλάζει | δύο ledgers + committed cuts + certified reconstruction |
| **C** representation/query | πώς ερωτάται η γνώση | rebuildable claim-bearing projections |
| **D** trust distribution | ποιος πιστοποιεί ποιον | internal independence τώρα· federation με πραγματικό diversity |
| **E** epistemology | τι είδους γνώση είναι κάθε πρόταση | Claim Contract, A/F, worlds, UNKNOWN |
| **P** practice containment | απόρρητο/matters/δημοσίευση/egress | structural isolation + fail-closed gates + matter namespaces |

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
  │  L   CANONICAL LEGAL EVENT LEDGER            — ΜΟΝΟ admitted LegalEffectEvents (self-sufficient)
  │  S   IMMUTABLE SOURCE / EVIDENCE HISTORY     — blobs + observations + probes + receipts
  └─ A   TRUSTED KERNEL / ADMISSION              — identity, crypto, capabilities, intake, commits, clocks

            ║ D — INDEPENDENT VERIFICATION / FEDERATION ║   (εξωτερικός δακτύλιος)
            ║ AI/INTELLIGENCE — εκτός αλήθειας, proposals μέσω gates ║  (πλάγιο plane)
```
Μία διάταξη, τρεις αναγνώσεις: data-flow = trust order = rebuild order. E/P/G cross-cutting.
Το kernel intake, όχι ο parser, γεννά trusted Observation/Receipt.

## 3. S — IMMUTABLE SOURCE / EVIDENCE HISTORY

### 3.1 Τύποι (I-16, I-22)
```
EvidenceBlob        := ⟨ blob_id = hash(bytes), bytes ⟩
CaptureObservation  := ⟨ observation_id = hash(canonical unsigned envelope)
                       , blob_id, source_locator, observed_at
                       , transport_evidence, capture_principal ⟩
IntakeReceipt       := SignedEnvelope⟨observation_id, received_at, intake-policy-version⟩
```
### 3.2 Ιδιότητες
Append-only· διορθώσεις = νέες observations· quarantine σε metadata, ποτέ αλλοίωση.
Corroboration: `corroborate(blob) = πλήθος ανεξάρτητων observations` — θεμέλιο source-diversity
απαιτήσεων admission. Merkle checkpoints → attestation.

### 3.3 Acquisition edge
Fetchers/adapters/parsers = R3 attack surface: μόνο candidates. Intake επικυρώνει transport
evidence, υπογράφει receipts, τηρεί intake policy (R_ARTIFACT).

### 3.4 SourceProbeObservation
```
SourceProbeObservation := ⟨ probe_id, source_authority, attempted_at, request_profile
                          , outcome ∈ {SUCCESS, NOT_FOUND, TIMEOUT, AUTH_FAILURE,
                                       TRANSPORT_FAILURE, MALFORMED_RESPONSE, …}
                          , blob_id | ∅, capture_principal, signed_intake_record ⟩
```
Κανόνας bytes⇒blob: ελήφθησαν bytes ⇒ blob αποθηκεύεται ΠΑΝΤΑ (forensic απόδειξη). Probe
schedule/profiles = R_ARTIFACT policy. Θεμελιώνει UNKNOWN{SOURCE_MISSING} + freshness (§5.4).

## 4. L — CANONICAL LEGAL EVENT LEDGER

### 4.1 Admission pipeline (μόνη είσοδος, fail-closed σε ΚΑΘΕ βήμα)
```
CaptureObservation(S) → Source Authority Policy → Authenticity/Integrity →
Untrusted-Parser candidate → Trusted Structural Validation → Identity Resolution →
Temporal/Semantic Validation → Conflict/Quarantine → Admission Decision →
prepare{LegalEffectEvent, AdmissionDecision} → RootCommit (§13.3)
```
Source Authority Policy = attested πίνακας αυθεντικών πηγών ανά είδος γεγονότος, με ιεραρχία και
χρονικά όρια. Αποτυχία/αμφιβολία ⇒ quarantine queue με ρητό reason και SLA — ποτέ σιωπηλό skip.

### 4.2 Event taxonomy (κλειστή, versioned — ΜΟΝΟ legal-world μεταβολές)
```
Publication · Amendment · Correction(επίσημη/εκδοτική) · Commencement ·
ConditionalCommencement · Repeal · Revival · Renumber · Split · Merge ·
Retroactivity-scope · AdjudicativeOperativeEffect{…κατά τον attested classifier}
```
`AdjudicativeOperativeEffect` φέρει `effect_scope/target_kind/temporal_effect/authority_basis`.
Επίσημη διόρθωση ΦΕΚ = L event `Correction`· δικό μας λάθος admission = `AdmissionCorrection`
(R_CONTROL, §4.4). IdentityDecision/DiscoveryCorrection ΔΕΝ υπάρχουν ως legal events.

### 4.3 LegalEffectEvent — self-sufficient state transition (FB4)
```
LegalEffectEvent := ⟨ event_id (I-22), event_type + schema_version
                    , target_refs {StableEntityId[@EntityVersionId]…}
                    , operative_spec (typed)
                    , transition_payload_ref + transition_payload_digest
                    , source_span_map (payload spans → observations)
                    , valid_time, tx_coord (από RootCommit)
                    , evidence_set {observation_id…} ≥1
                    , admission_decision_ref, supersedes | ∅ ⟩
TransitionPayload ∈ R_LEGAL (content-addressed, παγωμένο στο admission)
```
**Νόμος αυτάρκειας:** κάθε event περιέχει ή content-references το admitted canonical payload που
αρκεί για deterministic state transition. **Η ανακατασκευή του B ΔΕΝ διαβάζει ΠΟΤΕ το S και ΔΕΝ
ξανατρέχει parser σε ιστορικά bytes** — αλλιώς parser v2 ξαναγράφει το παρελθόν. Το payload
είναι το προϊόν της trusted validation ΤΗΣ ΣΤΙΓΜΗΣ του admission, υπό την τότε canonicalization
version, παγωμένο έκτοτε (συνεπές με I-19). Το S παραμένει αποκλειστικά evidence/provenance
ground για ανεξάρτητη επαλήθευση. **Discharge: LEGAL-REPLAY-SUFFICIENCY** (πείραμα 25).

### 4.4 Admission corrections — cut σημασιολογία (FB3)
AdmissionCorrection (R_CONTROL) γίνεται effective **όταν το RootCommit του περιληφθεί σε
committed cut** — όχι νωρίτερα, ποτέ με wall-clock σύγκριση. Event ορατό σε cut K iff το commit
του ∈ K ΚΑΙ καμία effective-in-K correction δεν το ακυρώνει. Cuts μεταξύ admission και
correction δείχνουν τίμια τι πιστεύαμε· τίποτα δεν ξαναγράφεται.

### 4.5 Semantic identity — lineage (I-19)
```
StableEntityId · EntityVersionId · IdentityAssertion (supersedable) · IdentityLineageEdge
```
CanonicalizationDecisions/IdentityCorrections στο R_CONTROL· identity map = PC-φέρουσα
projection (`kind=identity-map`) — bitemporal, replayable, κανένα dangling ref (πείραμα 19).

### 4.6 Commit & cut model (FB1+FB3, αντι-εύρημα A-1)
- **Partitions** ανά δικαιοδοσία/πηγή· strictly monotonic seq ανά partition· partition χάρτης =
  versioned R_ARTIFACT με ceremony.
- **Commit chains ανά namespace (ADR-C1):** ένα system commit chain + ένα ανά matter (§11.4).
  Η commit-level σειριοποίηση ΔΕΝ είναι bottleneck: ο ρυθμός admissions νομικού υλικού είναι
  εγγενώς χαμηλός, και τα L partitions κρατούν την κλιμάκωση σε επίπεδο event replay/projection.
  Αν ποτέ απαιτηθεί μεγαλύτερο commit throughput, η προβλεπόμενη επέκταση είναι περισσότερα
  namespaces — ποτέ χαλάρωση της ατομικότητας.
- **CheckpointCut v2 (FB3):**
```
CheckpointCut := ⟨ cut_id, parent_cut_id
                 , legal_partition_heads {partition_id → seq}
                 , control_head (RootCommit chain position), control_root
                 , committed_at_wall_time (audit μόνο) ⟩
```
  Διάταξη cuts ΜΟΝΟ μέσω parent hash-chain. `known_at = K` σημαίνει ΑΚΡΙΒΩΣ: όλο το admitted
  legal state έως τα L heads του K ΚΑΙ όλο το control history έως το control_head του K.
- **Deterministic merge rule** για projections: `(cut, partition_id, seq)` — version δεσμευμένη
  στο PC. Replay με οποιαδήποτε σειρά παράδοσης ⇒ ταυτόσημα roots (πειράματα 14/17).

## 5. B — CANONICAL BITEMPORAL STATE

### 5.1 API αλήθειας (I-7)
`resolve(entity, valid_at, known_at: CheckpointCutId, context) → ResolvedState | UNKNOWN{…}`
Span-level provenance: ResolvedState → events → payloads → (μέσω evidence) observations → blobs.

### 5.2 Generalized Projection Certificate — cut-scoped views (M1)
```
PC := ⟨ projection_kind ∈ {legal-state, claim-status, identity-map, freshness, …}
      , projector_spec, implementation_digest
      , input_views { LegalViewRoot(K, scope) | ∅ · EpistemicViewRoot(K, scope) | ∅
                    , ArtifactViewRoot(K, scope) · ControlRoot(K) · SourceRoot | ∅ }
      , transaction_cut = K, scope, canonicalization_version, merge_rule_version
      , output_root, toolchain_manifest ⟩
```
Κάθε input = **exact admitted view στο cut K** — ποτέ future-inclusive store root: artifact
admitted στο K+10 δεν αλλάζει το commitment replay στο K (πείραμα 24). Κατά I-21, το PC(K)
εισέρχεται στην αλυσίδα ΜΕΤΑ το K. Root χωρίς έγκυρο PC δεν είναι canonical· μεταβολή δηλωμένου
input ⇒ verification FAIL (πείραμα 18).

### 5.3 Assurance tiers
```
PROJECTED → INDEPENDENTLY_VERIFIED (≥2 projectors κατά MIC, ίδιο scope/cut)
          → RECONSTRUCTION_CERTIFIED (+ ένταξη σε kernel-signed attestation checkpoint)
```
Πιστοποιείται η ανακατασκευή δηλωμένων inputs υπό δηλωμένο spec — ποτέ ουσιαστική νομική
ορθότητα. Serving-tier policy = versioned R_ARTIFACT: G-pub έξοδοι/δικόγραφα ⇒
≥ INDEPENDENTLY_VERIFIED (στόχος RECONSTRUCTION_CERTIFIED)· εσωτερική έρευνα ⇒ PROJECTED με
ρητή ετικέτα. Mismatch ⇒ REJECT + incident. Snapshots = PC-φέροντα caches σε committed cuts.

### 5.4 Freshness envelope — scoped (M6)
```
FreshnessEnvelope := ⟨ jurisdiction, source_authority_set, document/event classes
                     , probe_policy_version, covered_window, failures, assurance ⟩
```
PC-φέρουσα projection επί probe history. Current-completeness claim ΠΑΝΤΑ σχετικό με coverage
scope: «τρέχον ελληνικό φορολογικό δίκαιο» δεν είναι fresh επειδή απάντησε το EUR-Lex. Αν το
scope δεν καλύπτεται: `state as-of cut K + envelope` ή `UNKNOWN{INCOMPLETE_COVERAGE}` με
resolution_condition. Outage δεν αλλάζει το παρελθόν — αφαιρεί το δικαίωμα ισχυρισμού
πληρότητας στο παρόν.

## 6. TEMPORAL SEMANTICS
Canonical plane: `valid_time × known_at(cut)`. Forensic plane: ερωτήματα επί S/probes με
`observed_at` — πάντα επισημασμένα forensic, ποτέ ως ισχύον δίκαιο, ποτέ μεικτά χωρίς ετικέτα.
`admitted_wall_time` = audit μόνο. Retroactivity: valid_time στο παρελθόν, commit τώρα·
προγενέστερα cuts αναλλοίωτα· STALE wave. ConditionalCommencement: πλήρωση αίρεσης = ΝΕΟ event
με δικό του EvidenceSet. Ημερομηνιακή αριθμητική ΜΟΝΟ μέσω kernel temporal library.

## 7. E — EPISTEMIC PLANE

### 7.1 EpistemicClass (κλειστό enum + επιτρεπτές είσοδοι)
`AUTHORITATIVE_TEXT` (ΜΟΝΟ μέσω L admission — ποτέ claim queue) · `VERIFIED_OBSERVATION`
(capture+receipt+hash) · `DETERMINISTIC_DERIVATION` (A≥A2 από {AUTH, VERIF, DET}) ·
`LEGAL_INTERPRETATION` (κρίση, ανατρέψιμη) · `DISPUTED_INTERPRETATION` (ενεργή αντίκρουση) ·
`PREDICTION` (ποτέ νομική αλήθεια) · `UNKNOWN` (I-15).
**CC-1 απαγορευμένες μεταβάσεις:** καμία ανοδική αλλαγή class μέσω confidence/votes/επανάληψης/
LLM-consensus· `INTERPRETATION→DETERMINISTIC` δεν υπάρχει — μόνο ΝΕΟ assertion με δική του A≥A2
derivation + supersedes· `→AUTHORITATIVE_TEXT` μόνο από L admission.

### 7.2 ClaimAssertion (αμετάβλητο — R_EPISTEMIC)
```
ClaimAssertion := ⟨ claim_id (I-22), claim_type ∈ {legal-state, in-force, subsumption, deadline,
                    conflict, interpretation, prediction, impact, meta}
                  , statement (typed — όχι free text στο trusted layer)
                  , epistemic_class, confidence_in_class ∈ [0,1]|∅ (μόνο εντός class)
                  , derivation_assurance (A), formalization_fid (F), coverage_stamp
                  , world_context, valid_time
                  , evidence_set {observation/event/claim refs} ≥1
                  , dependency_set {claim_id | StableEntityId@version | authority_ref…}
                  , created_by, supersedes | ∅ ⟩
```
Χωρίς lifecycle field, χωρίς admission timestamp — το tx_coord ζει στο ClaimAdmissionDecision
(R_CONTROL) μέσω του RootCommit τους.

### 7.3 A/F/Coverage — αμετάβλητες ιστορικές δηλώσεις (M3)
**A:** A0 unchecked (μη-trusted) · A1 replay ίδιου implementation · A2 ανεξάρτητος checker ·
A3 A2+N-version · A4 A3+machine-checked checker. **F:** F0 μηχανική εξαγωγή · F1 ένας ειδικός ·
F2 διπλή ανεξάρτητη φορμαλοποίηση+back-translation+scoped/dated · F3 F2+contrastive suite+
re-attestation trigger. **F3 = ταβάνι· EMPIRICAL· ποτέ THEOREM.**
**Το ιστορικό A/F μιας assertion ΔΕΝ αλλάζει ΠΟΤΕ.** Source change ⇒
`FormalizationStatus(assertion, K) = STALE` (derived projection §7.6) — και re-attestation
δημιουργεί ΝΕΟ assertion/artifact με νέο F + supersedes. Νέο evidence ⇒ ΝΕΟ admitted
assertion/certificate — ποτέ «άνοδος» A στο ίδιο record. Anti-laundering: A ποτέ δεν αναβαθμίζει
F· συνολική ισχύς = min αξόνων. **Coverage := ⟨C construal-set, S source-set@versions,
T window, W world-set, G generator-manifest⟩** — πληρότητα πάντα σχετική με stamp· ελλιπές ⇒ REJECT.

### 7.4 Claim admission (μόνη είσοδος στο R_EPISTEMIC)
```
ClaimCandidate (non-root queue) → class-specific admission (K-cl, πίνακας = R_ARTIFACT)
→ prepare{ClaimAssertion, ClaimAdmissionDecision} → RootCommit
```
Απαιτήσεις ανά class: DETERMINISTIC ⇒ derivation certificate από ανεξάρτητο checker·
INTERPRETATION ⇒ evidence + admissible principal/model provenance + policy· DISPUTED ⇒ ρητό
conflict edge· PREDICTION ⇒ model/eval manifest· VERIFIED_OBSERVATION ⇒ receipts· UNKNOWN ⇒
πλήρης I-15 δομή. Ενιαία έδρα: ΟΛΟΙ περνούν admission. Απόρριψη candidate = non-root disposition
(bounded audit δείγμα στο R_CONTROL μετά από quota gate)· root `CLAIM_REJECTED` = ΜΟΝΟ
invalidation ήδη admitted assertion μέσω governed process. Flooding γεμίζει την ουρά, ποτέ το Root.

### 7.5 Supersession — μία έδρα
Έδρα = το `supersedes` του νέου admitted assertion, επικυρωμένο από το ClaimAdmissionDecision
του. `CLAIM_SUPERSEDED` = derived status, ΟΧΙ root fact.

### 7.6 Status = derived bitemporal projection
`status(claim, valid_at, known_at) ∈ {ACTIVE, STALE, SUPERSEDED, REJECTED}` από
`R_EPISTEMIC + R_LEGAL + R_CONTROL + R_ARTIFACT` στο cut· υλοποιήσεις = caches· **ο status
projector = canonical projection υπό I-14** (PC kind=claim-status, tiers). Dependency μεταβολή ⇒
STALE στο επόμενο cut· φραγμένο freshness bound (R-b).

### 7.7 Worlds & disputes
`InterpretationWorld = ⟨fact-world × construal-set × forum⟩`· ανταγωνιστικές ερμηνείες
συνυπάρχουν με SUPPORTS/CONFLICTS_WITH — το σύστημα δεν «διαλέγει» δόγμα ως fact.

## 8. N — NORMATIVE / CASE
Normative IR = typed, versioned authored R_ARTIFACT: atoms δεμένα σε source spans
(`atom → EntityVersionId → event payload → observations`), deontic τελεστές, defeasibility,
applicability, χρονικό scope· acceptance = `serialize → parse → ταυτό IR` + πλήρης span κάλυψη·
είσοδος μέσω ArtifactAdmissionCertificate, F-graded. Inference (JTMS-class, WFS, event calculus)
και case layer (υπαγωγή, precedent, dialectic, deadlines): κάθε αποτέλεσμα = ClaimCandidate →
§7.4 — κανένα ιδιωτικό κανάλι αλήθειας.

## 9. C — DERIVED KNOWLEDGE / QUERY / IMPACT
Όλα caches. Κάθε epistemic ακμή φέρει claim/event καταγωγή — «γυμνή» ακμή δεν υπάρχει.
Conformance classes: DETERMINISTIC (byte-identical — canonical serializations/roots/projections)
| SEMANTIC (δηλωμένο functional τεστ — embeddings/ANN/search)· SEMANTIC ποτέ μοναδικός φορέας
authoritative πληροφορίας· `DELETE cache ⇒ REBUILD` κατά class. Impact: νέο event ⇒ dependency
graph ⇒ STALE στο επόμενο cut + review queues· mass invalidation φραγμένη/μετρήσιμη.

## 10. INTELLIGENCE PLANE (AI) — εκτός αλήθειας
Ρόλοι R3/untrusted· κανένα authoritative state. Έξοδοι ΜΟΝΟ ως admission candidates ή
ClaimCandidates (INTERPRETATION/PREDICTION, A0/A1, generator manifest). Ποτέ
DETERMINISTIC/AUTHORITATIVE. Egress ΜΟΝΟ μέσω G-inf· prompts/responses/contexts matter-tagged,
compartmented. Retrieval accelerators = SEMANTIC caches.

## 11. P — PRACTICE / PRIVILEGE / SECURITY PLANE

### 11.1 Matter isolation (structural absence)
Isolation = απουσία handle σε ΟΛΟ το surface: canonical stores, vector indexes, caches,
embeddings, temp files, logs, traces, exception dumps, backups, snapshots, agent memory, model
context windows, exported artifacts, analytics/telemetry, **staging areas (§13.3)**.
Cross-matter = μη σχηματίσιμο ερώτημα — ποτέ policy άρνηση που διαρρέει ύπαρξη.

### 11.2 Data classes & capabilities
{PUBLIC, INTERNAL, CLIENT_CONFIDENTIAL, PRIVILEGED, WORK_PRODUCT, RESTRICTED}·
PRIVILEGED/RESTRICTED ⇒ egress capability δομικά απούσα. Capabilities ⟨issuer, holder, scope,
expiry, bounded delegation, revocation, replay-nonce, audit-binding, SoD⟩· ιστορικό στο
R_CONTROL. Break-glass: 2-person, expiry, loud incident, καμία delegation.

### 11.3 Publication
Νόμος: `PUBLIC-class ∧ release-policy-approved ∧ privilege-safe ⇒ publication candidate`. Το ΤΙ
επιτρέπεται = versioned G-pub policy artifact· **policy v1 = εντολή δημιουργού: δημόσιο = μόνο
κωδικοποιημένοι δημόσιοι νόμοι** (αλλάζει μόνο με ρητή δική του απόφαση). G-pub failure ⇒
publication disabled, fail-closed, κανένα weaker bypass· canary + stego red-team κάθε release.

### 11.4 Matter Root namespaces (M4 + αντι-εύρημα A-2)
- Matter-private state ζει σε χωριστά namespaces: `R_SOURCE[m], R_EPISTEMIC[m], R_CONTROL[m]`
  με **δικό τους commit chain και matter-local cuts**· system/public γνώση (νόμοι, δημόσια
  νομολογία) στο `R_*_SYSTEM`.
- Matter-local principal ΔΕΝ μπορεί να συναγάγει δραστηριότητα άλλου matter από sequence
  numbers, gaps, checkpoint cadence, attestation αλλαγές ή timing — τα system counters δεν
  εκθέτουν per-matter συμβολές.
- **Blind anchoring:** η ακεραιότητα των matter chains αγκυρώνεται στο system attestation ΜΟΝΟ
  μέσω activity-hiding commitment (σταθερός ρυθμός/padded accumulator) — ποτέ raw heads/counts.
  Η ακριβής κατασκευή = R-i (residual) με ΣΚΛΗΡΗ απαίτηση ήδη δεσμευτική: 0 existence signal
  εντός του threat model (πείραμα 27).
- Public/external attestation bundles δεν δημοσιεύουν private-matter commitment metadata χωρίς
  ρητή policy.

## 12. D — VERIFICATION & TRUST DISTRIBUTION

### 12.1 Internal independence τώρα · federation με πραγματικό diversity
Χωριστοί verifiers ανά critical function — χωριστό θεμέλιο/build/reconstruction. Attestation
checkpoints: kernel-signed ⟨S-root, L-heads, control_head/root, golden state roots, PCs,
admission stats, TrustAnchorGenesis fingerprint⟩ — offline επαληθεύσιμα από τρίτο. Federation
ΟΤΑΝ υπάρξει δεύτερος πραγματικός θεσμός· καμία federation-of-one.

### 12.2 Minimum Independence Contract — MIC
1. 0 shared critical semantic implementation code (κοινά ΜΟΝΟ frozen spec + conformance vectors).
2. Independent critical dependency closure — καμία κοινή βιβλιοθήκη/generated component στο
   semantic critical path· γλώσσα = ένδειξη, ΠΟΤΕ υποκατάστατο· manifest diff επαληθεύσιμο.
3. Καμία κοινή καταγωγή: όχι μετάφραση/transpilation της άλλης ή κοινού μη-spec προγόνου.
4. Ανεξάρτητο build + runtime (χωριστό toolchain manifest).
5. Shared foundations ΜΟΝΟ: δηλωμένα ως common trust assumptions, εκτός συγκρινόμενου semantic
   logic, με δικό τους conformance καθεστώς (SHA-256: ναι· canonicalization parser: όχι).
6. Mutation/defect-seeding batteries από τις error classes του spec — και οι δύο περνούν.
7. Disagreement ⇒ διόρθωση spec μέσω ceremony· ποτέ αντιγραφή συμπεριφοράς χωρίς spec αλλαγή.
8. SoD: διαφορετικός συντάκτης/θεμέλιο ανά υλοποίηση.
Υπόλειμμα: κοινό conceptual bug ΣΤΟ spec — δηλωμένο spec-level residual (contrastive fixtures +
εξωτερική αναπαραγωγή, πείραμα 10).

## 13. ROOT SET, COMMIT LAW & REBUILD

### 13.1 Πέντε κλάσεις (I-12, I-17)
```
R_SOURCE    blobs · observations · probes · receipts               authority: ΚΑΜΙΑ
R_LEGAL     admitted LegalEffectEvents + TransitionPayloads        authority: CANONICAL
R_EPISTEMIC admitted ClaimAssertions                               authority: interpretation-grade
R_ARTIFACT  schemas · rulepacks · IR · projector specs ·           authority: formalization/policy
            policy tables · classifiers · partition maps            (F-graded)
R_CONTROL   RootCommits · AdmissionDecision/Correction ·           authority: control-plane
            ClaimAdmissionDecision · ArtifactAdmissionCertificate · ιστορικά γεγονότα —
            Identity/Canonicalization records · capabilities ·      ΟΧΙ νομικό περιεχόμενο
            checkpoints (cut chain) · PCs · attestations
```
Όλα append-only, content-addressed (I-22), merkle-checkpointed, μέγιστο durability καθεστώς.

### 13.2 Reconstruction equations
```
EffectiveLegalEvents(K)  = AdmitView(R_LEGAL, R_CONTROL, K)
CanonicalLegalState(K)   = Project(EffectiveLegalEvents(K), ArtifactView(K), K)   — ΧΩΡΙΣ S
EpistemicState(K)        = Evaluate(EpistemicView(K), CanonicalLegalState(K), ControlView(K), ArtifactView(K))
DerivedStores            = Cache(CanonicalLegalState, EpistemicState)
```
Το R_SOURCE θεμελιώνει/επαληθεύει admissions — δεν συμμετέχει στην canonical ανακατασκευή (FB4).
DR = προγραμματισμένο discharge test κάθε release.

### 13.3 Root Commit Law (FB1 + αντι-ευρήματα A-1/A-3)
```
RootCommit := ⟨ commit_id (I-22), parent_control_root
              , prepared_objects {root_class, object_digest, admission_decision_ref}…
              , logical_tx, principal/capability, policy_versions
              , signature (SignedEnvelope) ⟩
```
- **Νόμος:** prepared object ≠ Root member. Effectiveness ΜΟΝΟ με έγκυρο RootCommit στο
  αντίστοιχο namespace chain: `prepare → validate → append RootCommit → referenced objects
  effective`. Το `tx_coord` απονέμεται ΑΠΟΚΛΕΙΣΤΙΚΑ από το RootCommit — ποτέ από ανεξάρτητους
  writers.
- Crash πριν το commit ⇒ 0 effective Root changes· orphan prepared objects συλλέγονται
  deterministically. Crash μετά το commit ⇒ recovery ολοκληρώνει idempotently όλη τη συναλλαγή.
  Ποτέ half state (πείραμα 22).
- **Staging hygiene (A-3):** το staging area ζει ΜΕΣΑ στο compartment του matter/namespace που
  αφορά, με TTL/GC και journaled καταστροφή — ποτέ unaudited σκιώδες store, ποτέ cross-matter
  ορατό.
- Commit chains ανά namespace (ADR-C1, §4.6): system + per-matter· καμία distributed
  transaction fiction — μία ατομική append ανά συναλλαγή στο chain της.

### 13.4 Causal certificate order (I-21)
```
ControlRoot(K) → projection → PC(K) → RootCommit K+n (n≥1)
```
Κάθε certificate/attestation/checkpoint δεσμεύει ΜΟΝΟ prefix που προηγείται αιτιωδώς· κατασκευή
self-inclusive commitment = αδύνατη/REJECT (πείραμα 23).

## 14. SCALE MODEL
Read φορτίο ⇒ caches· Root δέχεται μόνο admission ρυθμούς· commit chains ανά namespace
(χαμηλός ρυθμός — ADR-C1)· incremental projections με PC ανά committed cut· partitions
κλιμακώνουν replay ανεξάρτητα· verification offline/async· substrate caches = μη-αρχιτεκτονική
απόφαση.

## 15. UPGRADEABILITY

### 15.1 R_ARTIFACT entry
`ArtifactAdmissionCertificate := ⟨artifact_digest, author, reviewer(s), A/F, applicability,
supersedes, ceremony record ref, effective_version⟩` — ζει στο R_CONTROL, committed μέσω
RootCommit. Κάθε G-sev ceremony παράγει canonical admission record.

### 15.2 R_CONTROL entry & Trust Anchor (I-20/I-21)
R_CONTROL records: kernel-signed, hash-chained, υπό capability/SoD καθεστώτα — ΟΧΙ μέσω
ArtifactAdmissionCertificate του εαυτού τους. Η αλυσίδα τερματίζει στο **TrustAnchorGenesis**
(genesis ceremony, initial trust-root keys, recovery-policy digest) — ρητά αξιωματικό, τυπωμένο
σε κάθε attestation bundle. Key rotation = R_CONTROL history επαληθευόμενη ΑΠΟ το genesis·
recovery = χωριστό offline quorum· compromised key δεν πιστοποιεί τον αντικαταστάτη του.

### 15.3 Evolution
Schemas versioned· παλαιά records ποτέ ξαναγραμμένα· upcast functions = versioned R_ARTIFACT·
projector αλλαγή ⇒ νέα PC γενιά + differential report· κλειστά enums μόνο με ceremony·
autonomy = sandbox προτάσεις σε ουρά, ποτέ αυτο-εφαρμογή.

## 16. FAILURE / DEGRADATION MATRIX
| Κατάσταση | Σερβίρεται | Min tier | UNKNOWN | Μπλοκάρεται | Recovery |
|---|---|---|---|---|---|
| **SOURCE_MESH_DEGRADED** | historical resolve σε κάθε committed cut | κατά policy | current-completeness ⇒ `INCOMPLETE_COVERAGE` με scoped envelope | τίποτα εσωτερικό | ops· probe επανεκκίνηση |
| **ROOT_CORRUPTION_DETECTED** | ΜΟΝΟ cuts ≤ τελευταίο verified checkpoint | RECONSTRUCTION_CERTIFIED | ό,τι μετά το ύποπτο cut | admissions + certifications | break-glass (2-person) + rebuild + incident |
| **KEY_COMPROMISE** | read-only certified cuts προ-συμβάντος, με ρητή προειδοποίηση | RECONSTRUCTION_CERTIFIED προ-συμβάντος | ό,τι υπογράφηκε στο ύποπτο διάστημα | ΟΛΕΣ οι admissions/publications/νέες υπογραφές | **αλυσίδα: offline recovery quorum → revoke → νέο operational key → re-attest από τελευταίο καθαρό cut· compromised key ΔΕΝ πιστοποιεί αντικαταστάτη** (πείραμα 26) |
| **PROJECTOR_DISAGREEMENT** | scopes εκτός διαφωνίας | affected ⇒ ΔΕΝ σερβίρεται όπου policy > PROJECTED | affected κατά policy | release affected scope | spec ceremony (MIC 7) |
| **CONTROL_ROOT_DIVERGENCE** | τελευταίο κοινό certified cut | RECONSTRUCTION_CERTIFIED | ό,τι μετά τη διάσταση | admissions + certifications + ceremonies | break-glass forensic + governance |
| **CACHE_LOSS** | όλα — αργότερα (rebuild) | αμετάβλητο | τίποτα | τίποτα | ops· §13.2 ρουτίνα |
| **AI_UNAVAILABLE** | πλήρες canonical/temporal/normative core | αμετάβλητο | τίποτα | νέες AI proposals | ops |
| **EXTERNAL_EGRESS_DISABLED** | όλα τα εσωτερικά | αμετάβλητο | τίποτα | G-inf calls (fail-closed)· publication κατά G-pub | ops + policy |

Γενικοί κανόνες: fail-closed default· crash σε predicate ⇒ REJECT + incident, ποτέ ALLOW·
quarantine με SLA/escalation· incidents journaled στο R_CONTROL με post-mortem υποχρέωση.
Acquisition outage δεν αλλάζει ποτέ το παρελθόν — αφαιρεί μόνο το δικαίωμα ισχυρισμού
πληρότητας πέρα από το τελευταίο freshness-certified cut.

## 17. ARCHITECTURE EXPERIMENTS — 27 falsifiers (πύλη → DEMONSTRATED)
Κάθε ένα με δηλωμένο fixture universe + metric + threshold + failure action πριν εκτελεστεί.
1. **Temporal replay torture** — grid (entity × valid_at × cut) με retroactivity/corrections/
   conditional commencements· resolve ντετερμινιστικό = ανεξάρτητος projector.
2. **Full reconstruction** — καταστροφή ΟΛΩΝ των caches· rebuild από R· byte-identical roots.
3. **Poisoned admission** — πλαστή πηγή/πειραγμένο digest/αναρμόδια αρχή ⇒ 0 admissions.
4. **Projector N-version disagreement** — εμφυτευμένο bug ⇒ ανίχνευση, release BLOCK.
5. **Claim laundering** — απαγορευμένες μεταβάσεις/A→F αναβάθμιση ⇒ 100% REJECT.
6. **Mass invalidation** — αναδρομικός νόμος/ακύρωση ⇒ φραγμένο STALE wave· 0 STALE ως ACTIVE.
7. **Matter escape** — red-team σε όλο το §11.1 surface + inference channels ⇒ 0 bytes, 0 signals.
8. **Schema evolution** — v+1 + upcast ⇒ replay· roots σταθερά ή εξηγημένο diff.
9. **Disaster recovery** — χρονομετρημένο πλήρες rebuild σε καθαρό host· certificates verify· RTO.
10. **Independent reproduction** — τρίτη minimal υλοποίηση αναπαράγει golden roots από R.
11. **Observation identity torture** — ίδια bytes, 2 πηγές ⇒ 1 blob, 2 observations· σωστό corroboration.
12. **Claim flooding** — R3 πλημμύρα ⇒ Root ανέγγιχτο· quotas ενεργά.
13. **Backdating attempt** — quarantine → admission ⇒ κανένα προγενέστερο cut δεν το βλέπει.
14. **Partition merge determinism** — ανακατεμένη παράδοση ⇒ ταυτόσημα roots.
15. **Tier mislabel** — PROJECTED όπου απαιτείται RECONSTRUCTION_CERTIFIED ⇒ REJECT.
16. **Control-root genesis/regress** — certificate χωρίς αναδρομική αλυσίδα· επαληθεύσιμος
    τερματισμός στο TrustAnchorGenesis.
17. **Transaction-cut race** — 3 partitions, wall-clock reordering ⇒ ίδιο committed cut, ίδιο root.
18. **Claim-status PC tamper** — αλλαγή epistemic view χωρίς αλλαγή PC ⇒ verification FAIL.
19. **Re-canonicalization identity torture** — v2 διορθώνει merge/split ⇒ παλαιά cuts παλαιό map,
    κανένα dangling ref.
20. **Source-freshness outage** — probes down ⇒ current-completeness ΟΧΙ fresh· historical σωστά.
21. **False-independence trap** — 2 γλώσσες, κοινό critical dependency ⇒ MIC REJECT.
22. **Half-commit crash** — crash πριν το RootCommit ⇒ 0 effective changes + deterministic
    cleanup· crash μετά ⇒ πλήρης συναλλαγή ορατή· ποτέ half state.
23. **PC self-reference trap** — PC που δεσμεύει control root περιέχον το ίδιο PC ⇒ κατασκευή
    αδύνατη/REJECT (I-21).
24. **Historical artifact contamination** — artifact admitted στο K+10· replay του K ⇒ PC(K)
    και StateRoot(K) αμετάβλητα.
25. **Legal replay without source parser** — S και acquisition parsers ΑΠΕΝΕΡΓΟΙ· input ΜΟΝΟ
    R_LEGAL+R_CONTROL+R_ARTIFACT ⇒ ταυτόσημο canonical B root (LEGAL-REPLAY-SUFFICIENCY).
26. **Compromised-key recovery** — κλεμμένος operational signer επιχειρεί self-rotation ⇒
    REJECT· offline quorum κάνει revoke/rotate ⇒ PASS + re-attestation από καθαρό cut.
27. **Matter-root metadata escape** — matter A προσπαθεί να διακρίνει activity του B μέσω
    counters/gaps/cadence/attestations/timing ⇒ 0 existence signal εντός threat model.

## 18. RESIDUALS (τελική κατάσταση προ freeze)
- **R-a** — περιεχόμενο erga-omnes classifier (με effect_scope πεδία): νομική έρευνα προς
  F-graded attestation· I-13 fail-closed καλύπτει το μεσοδιάστημα. RESIDUAL.
- **R-b** — freshness bound status projection: αριθμητικός στόχος στο freeze. OPERATIONAL.
- **R-c** — ΚΛΕΙΣΤΟ (MIC)· υπόλειμμα = δηλωμένο spec-level common-mode.
- **R-d** — ΚΛΕΙΣΤΟ (§7.4/7.5).
- **R-e** — federation protocol: intentionally later. RESIDUAL.
- **R-f** — checkpoint cadence & quarantine SLA τιμές: στο freeze. OPERATIONAL.
- **R-g** — semantic-conformance πρότυπα ανά SEMANTIC cache: πριν το αντίστοιχο build. RESIDUAL.
- **R-h** — μορφή attestation bundle για εξωτερικό verifier (δένει με R-e). RESIDUAL.
- **R-i (ΝΕΟ)** — ακριβής κατασκευή blind anchoring των matter chains (§11.4)· η απαίτηση
  «0 existence signal» είναι ΗΔΗ δεσμευτική και falsifiable (πείραμα 27)· η κατασκευή
  επιλέγεται/αποδεικνύεται πριν το αντίστοιχο build. RESIDUAL.

---

**Πύλη:** Τελικό audit Reviewer-B επί του παρόντος (κριτήρια: καμία νέα circular authority,
κανένα mutable historical truth, κανένα unrecoverable split-brain) → «TARGET ARCHITECTURE v1.0 —
READY FOR CREATOR FREEZE DECISION» → ΜΟΝΟ ο δημιουργός αποφασίζει «εγκρίνω freeze target» →
μετά το MERGED-BLUEPRINT ξαναδένεται ως migration plan v0.9 προς το v1.0. Καμία production
αλλαγή πριν.
