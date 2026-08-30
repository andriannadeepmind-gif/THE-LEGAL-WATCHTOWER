# WATCHTOWER VLT — TARGET ARCHITECTURE v0.1
**Layered Verifiable Legal Twin — καθαρή αρχιτεκτονική-στόχος (κοινό artifact Reviewer-A × Reviewer-B)**

**Status: DESIGN HYPOTHESIS.** Καθαρό ιδανικό σύστημα: κανένα migration στοιχείο, κανένα
KEEP/MOVE/RETIRE, καμία legacy δέσμευση, καμία αναφορά σε υπάρχοντα paths. Γίνεται
**DEMONSTRATED ARCHITECTURE** μόνο εντός δηλωμένου fixture universe, όταν περάσουν και τα 10
πειράματα του §17. Freeze σε Target Architecture v1.0 ΜΟΝΟ μετά από αμοιβαίο destruction pass
των δύο reviewers ΚΑΙ ρητό «εγκρίνω» του δημιουργού. Μετά το freeze, το MERGED-BLUEPRINT v0.8
ξαναδένεται ως migration plan ΠΡΟΣ το παρόν target (v0.9)· μέχρι τότε καμία production αλλαγή.

---

## 0. CONSTITUTION

### 0.1 Αμετάβλητα I-1…I-10 (κληρονομούνται ως έχουν, μη διαπραγματεύσιμα)
1. Κανένα LLM δεν αποτελεί trust root. 2. Κανένας verifier αξιόπιστος επειδή ελέγχει output του
ίδιου implementation. 3. Κανένα subsystem με implicit authority. 4. Κανένα confidence δεν
μετατρέπει interpretation σε fact. 5. Κανένα derived conclusion χωρίς evidence/dependency state.
6. Κανένα external AI/provider call δεν παρακάμπτει matter/privilege/egress policy. 7. Καμία
production απόφαση legal temporal state έξω από τη μοναδική canonical temporal authority.
8. Boundaries machine-enforced. 9. Κάθε phase με executable discharge condition. 10. Νέα μηχανή
πρώτα σε shadow/differential όπου εφικτό.

### 0.2 Νέα αμετάβλητα I-11…I-15 (προϊόντα της σύγκλισης A×B επί των έξι αξόνων)

- **I-11 — Δύο ledgers, μία υποχρεωτική αναφορά.** Evidence history (S) ≠ legal-event history (L).
  Το S απαντά «τι bytes παρατηρήσαμε, πότε, από πού, με ποιο digest/receipt». Το L απαντά «ποια
  legal-state transitions έγιναν δεκτά από το admission machinery». `CanonicalLegalEvent MUST
  reference admitted EvidenceSet (≥1)`. Poisoned capture ζει για πάντα στο S **χωρίς ποτέ να
  αποκτά legal authority**: immutability ≠ correctness — η authority απονέμεται ΜΟΝΟ από admission.

- **I-12 — Root-or-Cache.** `REBUILD ROOT SET := { S, L, Claim History, Attested Authored
  Artifacts@versions (schemas, rulepacks, Normative IR, projector code, policy tables) }`.
  Κάθε άλλο store του συστήματος είναι CACHE: deterministically reconstructible από το Root Set.
  **Store που δεν είναι ούτε Root ούτε αποδεδειγμένα Cache απαγορεύεται να υπάρχει.**
  Συνέπεια: disaster recovery = προγραμματισμένο discharge test (§17.9), όχι έκτακτο σενάριο.

- **I-13 — Interpretation ποτέ canonical event· κριτήριο διατακτικού.** Στο L εισέρχεται από
  δικαιοδοτική πράξη ΜΟΝΟ το **operative erga omnes αποτέλεσμα του διατακτικού** που μεταβάλλει
  legal state κατά το ισχύον δίκαιο (π.χ. κήρυξη αντισυνταγματικότητας ΑΕΔ κατ' άρθρο 100 Σ·
  ακύρωση κανονιστικής πράξης από ΣτΕ, ex tunc/erga omnes). Ratio decidendi, δογματική σημασία,
  inter partes κρίσεις (συμπεριλαμβανομένου του διάχυτου ελέγχου συνταγματικότητας) ζουν
  ΑΠΟΚΛΕΙΣΤΙΚΑ στο E-plane ως Claims. Ο πίνακας κατάταξης «ποιες πράξεις έχουν erga omnes
  operative effect» είναι **attested, F-graded authored artifact** του Root Set — όχι hardcoded.
  Μία απόφαση παράγει έτσι έως δύο εγγραφές: (α) event στο L για το operative effect (evidence =
  η δημοσιευμένη απόφαση), (β) claims στο E για ό,τι σημαίνει.

- **I-14 — Certified reconstruction.** Κάθε canonical projection εκπέμπει **Projection
  Certificate** `PC := ⟨projection-version, input-ledger-root, rule/schema-version,
  output-state-root⟩`. State root χωρίς PC δεν είναι canonical. Release-critical/golden state
  roots απαιτούν συμφωνία **ανεξάρτητου projector** (χωριστό θεμέλιο, όχι fork): `StateRootA ==
  StateRootB`, αλλιώς release BLOCK. Το B4 regime (falsifiability ∧ independence ∧ positive
  conformance) καλύπτει ρητά και το canonical state reconstruction — ο projector δεν γίνεται ποτέ
  ο νέος αόρατος trust root.

- **I-15 — UNKNOWN με σημασιολογία αιτίας, χωρίς σιωπηλή μετατροπή.** Το UNKNOWN είναι
  first-class δομή (§7.3): κλειστό, versioned reason enum + evidence + scope +
  resolution_condition. Κανένας καταναλωτής δεν μετατρέπει UNKNOWN σε default τιμή («no-silent-
  coercion»)· προσθήκη reason = governance ceremony. Το `POLICY_RESTRICTED` επιτρέπεται ΜΟΝΟ σε
  publication/egress-class αρνήσεις — ποτέ ως σήμα ύπαρξης cross-matter πληροφορίας: η
  cross-matter απομόνωση παραμένει structural absence (το ερώτημα δεν σχηματίζεται), όχι απάντηση.

---

## 1. ΟΙ ΕΞΙ ΣΥΣΤΑΤΙΚΟΙ ΑΞΟΝΕΣ

Η αρχιτεκτονική απαντά ρητά έξι ορθογώνια ερωτήματα· κανένα δεν απαντιέται «κατά σύμπτωση»:

| Άξονας | Ερώτημα | Απάντηση VLT |
|---|---|---|
| **A** topology/authority | ποιος κρατά τα κλειδιά, πού είναι τα όρια | trusted kernel + capability model + domain DAG (§2, §4.1) |
| **B** truth/time | τι είναι η αλήθεια, πώς αλλάζει | δύο ledgers + bitemporal deterministic reconstruction (§3–§6) |
| **C** representation/query | πώς αναπαρίσταται/ερωτάται η γνώση | rebuildable graph/RDF/search projections, claim-bearing edges (§9) |
| **D** trust distribution | ποιος πιστοποιεί ποιον | internal independence τώρα, federation με πραγματικό trust diversity (§12) |
| **E** epistemology | τι είδους γνώση είναι κάθε πρόταση | Claim Contract, A/F, worlds, disputes, UNKNOWN (§7) |
| **P** practice containment | απόρρητο, matters, δημοσίευση, egress | practice plane: walls, data classes, fail-closed gates (§11) |

---

## 2. LAYER MODEL — σπονδυλική στήλη + planes

```
            ┌────────────────────────────────────────────────────────┐
planes ──▶  │ P  PRACTICE/PRIVILEGE   E  EPISTEMIC   G  GOVERNANCE   │  (τέμνουν όλα τα στρώματα)
            └────────────────────────────────────────────────────────┘
  ▲  C   DERIVED KNOWLEDGE / QUERY / IMPACT      — caches: graph, RDF, search, indexes
  │  N   NORMATIVE / CASE                        — IR, inference, deontic, subsumption
  │  B   CANONICAL BITEMPORAL STATE              — deterministic reconstruction, state roots
  │  L   CANONICAL LEGAL EVENT LEDGER            — admitted state-changing events
  │  S   IMMUTABLE SOURCE / EVIDENCE HISTORY     — captures, bytes, receipts, hashes
  └─ A   TRUSTED KERNEL / ADMISSION              — identity, crypto, capabilities, policies

            ║ D — INDEPENDENT VERIFICATION / FEDERATION ║   (εξωτερικός δακτύλιος)
            ║ AI/INTELLIGENCE — εκτός αλήθειας, proposals μέσω gates ║  (πλάγιο plane)
```

**Ένας νόμος διάταξης, τρεις αναγνώσεις:** η σειρά `A→S→L→B→N→C` είναι ταυτόχρονα
(i) **data-flow order** — κάθε στρώμα καταναλώνει μόνο από κάτω,
(ii) **trust order** — η εμπιστοσύνη ρέει μόνο προς τα πάνω, ποτέ ανάποδα,
(iii) **rebuild order** — η ανακατασκευή γίνεται ακριβώς bottom-up.
Τα E/P/G είναι **cross-cutting planes** (φέρουν σημασιολογία/περιορισμούς σε κάθε στρώμα, δεν
είναι σκαλιά της στοίβας)· το D είναι εξωτερικός δακτύλιος· το AI plane δεν αγγίζει κανένα
authoritative store — γράφει μόνο proposals προς E/N ουρές, μέσω gates (§10).

---

## 3. S — IMMUTABLE SOURCE / EVIDENCE HISTORY

**Ρόλος:** πλήρης, append-only ιστορία παρατήρησης. Απαντά ΜΟΝΟ: τι bytes, πότε, από πού, πώς.

```
CaptureRecord := ⟨ capture_id      : content-addressed (digest των bytes)
                 , source_locator  : ⟨channel, uri/physical-ref, source-authority-id⟩
                 , captured_at     : timestamp (kernel clock authority)
                 , transport_proof : TLS/cert-chain observation, page receipts, ή physical intake record
                 , bytes_ref       : blob store ref (content-addressed)
                 , capture_agent   : principal + version
                 , receipt         : kernel-signed intake receipt ⟩
```

- Κανένα CaptureRecord δεν διαγράφεται ή μεταλλάσσεται· διορθώσεις = νέα captures.
- Το S ΔΕΝ φέρει καμία νομική σημασιολογία: ένα capture δεν είναι «νόμος», είναι παρατήρηση.
- Poisoned/forged captures παραμένουν στο S επ' άπειρον ως αποδεικτικό υλικό της επίθεσης —
  χωρίς authority (I-11)· η quarantine σήμανση ζει σε metadata, ποτέ σε αλλοίωση του record.
- Merkle-anchored checkpoints του S σε τακτά διαστήματα → attestation υλικό για το D (§12).

## 4. L — CANONICAL LEGAL EVENT LEDGER

### 4.1 Admission pipeline (η μόνη είσοδος στο L· fail-closed σε ΚΑΘΕ βήμα)
```
Capture (S) → Source Authority Policy → Authenticity/Integrity Verification
  → Parser/Structural Validation → Identity Resolution → Temporal/Semantic Validation
  → Conflict/Quarantine → Admission Decision → CanonicalLegalEvent (L) + AdmissionCertificate
```
- **Source Authority Policy** = attested πίνακας: ποια πηγή είναι αυθεντική για ποιο είδος
  γεγονότος (ΦΕΚ ανά τεύχος, δικαστήρια, ανεξάρτητες αρχές, ΕΕ), με ιεραρχία και ημερομηνιακά όρια.
- Κάθε admission εκπέμπει **AdmissionCertificate** (τι ελέγχθηκε, από ποιους checkers, με ποιες
  εκδόσεις, επί ποιου EvidenceSet) — kernel-signed, μέρος του L.
- Αποτυχία/αμφιβολία σε οποιοδήποτε βήμα ⇒ ΟΧΙ admission: το υλικό μένει σε **quarantine queue**
  με ρητό reason, ορατό σε review — ποτέ σιωπηλό skip.
- **Identity resolution:** ντετερμινιστική όπου γίνεται· όπου απαιτείται κρίση (merge/split
  ταυτοτήτων, αναγνώριση αναδημοσίευσης), η απόφαση καταγράφεται ως ρητό identity-decision event
  στο L με τον αποφασίσαντα principal — ώστε και η ταυτότητα να είναι replayable.

### 4.2 Event taxonomy (κλειστή, versioned — επέκταση μόνο με governance ceremony)
```
Publication · Amendment · Correction · Commencement · ConditionalCommencement
Repeal · Revival · Renumber · Split · Merge · Retroactivity(-scope)
AdjudicativeOperativeEffect {annulment-erga-omnes, unconstitutionality-declaration, …}
IdentityDecision {merge, split, alias}
DiscoveryCorrection   (διόρθωση της ΓΝΩΣΗΣ μας — αλλάζει known_time, ποτέ το παρελθόν του L)
```
**ΔΕΝ υπάρχει `InterpretationEvent`** (I-13). Η κατάταξη δικαιοδοτικών πράξεων γίνεται από τον
attested erga-omnes πίνακα· ό,τι δεν πληροί το κριτήριο του διατακτικού πάει στο E-plane.

### 4.3 CanonicalLegalEvent (canonical record)
```
CanonicalLegalEvent := ⟨ event_id        : content-addressed — ΑΜΕΤΑΒΛΗΤΟ
                       , event_type      : taxonomy (§4.2) + schema_version
                       , target_refs     : {provision@identity, instrument@identity …}
                       , operative_spec  : typed περιγραφή της μεταβολής (όχι free text)
                       , valid_time      : πότε ισχύει νομικά η μεταβολή (μπορεί παρελθόν/μέλλον/υπό αίρεση)
                       , recorded_time   : πότε εισήλθε στο L (μονότονο)
                       , evidence_set    : {capture_id …} ≥1 (I-11)
                       , admission_cert  : AdmissionCertificate ref
                       , supersedes      : event_id | ∅  (μόνο μέσω DiscoveryCorrection σημασιολογίας) ⟩
```
Το L είναι append-only· «διόρθωση» = νέο event με supersedes + διατήρηση του παλαιού ορατού στη
known_at διάσταση. Merkle root ανά checkpoint → `input-ledger-root` των PCs (I-14).

## 5. B — CANONICAL BITEMPORAL STATE

- **Ορισμός:** το canonical legal state ΔΕΝ αποθηκεύεται ως πρωτογενής αλήθεια· **προκύπτει** ως
  deterministic projection του L. Materializations = caches (I-12) με PC (I-14).
- **Μοναδικό API αλήθειας (I-7):**
```
resolve(provision, valid_at, known_at, context) → ResolvedState | UNKNOWN{…}
```
  Κάθε production ερώτημα ισχύοντος δικαίου περνά ΜΟΝΟ από εδώ. `context` = forum/regime όπου
  απαιτείται (διαχρονικό δίκαιο, μεταβατικές διατάξεις).
- **Structural semantics:** πλήρης υποστήριξη renumber/split/merge/repeal/revival/correction/
  conditional-commencement/retroactivity με ακριβή provenance ανά τεμάχιο κειμένου: κάθε
  ResolvedState φέρει span-level καταγωγή σε events και μέσω αυτών σε evidence.
- **Snapshots:** επιτρέπονται ΜΟΝΟ ως certified caches: snapshot = PC-φέρον υλικό σε
  checkpoint· replay από πλησιέστερο verified checkpoint· κάθε release ξαναδένει snapshot⇄ledger.
- **N-version για release-critical roots** (I-14): δεύτερος projector σε χωριστό θεμέλιο
  αναπαράγει τα golden state roots· διαφωνία ⇒ BLOCK + incident· η συμφωνία καταγράφεται στο
  attestation υλικό (§12).

## 6. TEMPORAL SEMANTICS

- **Δύο χρόνοι παντού:** `valid_time` (πότε ισχύει στον νομικό κόσμο) × `known_time` (πότε το
  γνωρίζαμε). Το ζεύγος είναι υποχρεωτικό σε L events, B state, E claims.
- Η ερώτηση «τι ίσχυε στις t₁ όπως το γνωρίζαμε στις t₂» είναι πάντα απαντήσιμη ή ρητά UNKNOWN —
  ποτέ σιωπηλά προσεγγιστική.
- **Retroactivity:** αναδρομική διάταξη = event με valid_time στο παρελθόν και recorded_time
  τώρα· τα προγενέστερα known_at ερωτήματα ΔΕΝ αλλοιώνονται (ό,τι πιστεύαμε τότε μένει
  ανακτήσιμο)· όλα τα εξαρτημένα claims γίνονται STALE αυτόματα (§7.2).
- **Conditional commencement:** έναρξη υπό αίρεση = event με τυπωμένη condition· η πλήρωση της
  αίρεσης είναι ΝΕΟ event (με δικό του evidence), όχι mutation.
- Ημερομηνιακή αριθμητική/σύγκριση ΜΟΝΟ μέσω του kernel temporal library — ποτέ ad-hoc
  συγκρίσεις strings.

## 7. E — EPISTEMIC PLANE

### 7.1 Claim Contract
Ισχύει αυτούσιο το κλειστό σχήμα του v0.8 §0.1: Claim record (content-addressed, immutable,
supersedes), `EpistemicClass` enum {AUTHORITATIVE_TEXT, VERIFIED_OBSERVATION,
DETERMINISTIC_DERIVATION, LEGAL_INTERPRETATION, DISPUTED_INTERPRETATION, PREDICTION, UNKNOWN}
με επιτρεπτές εισόδους ανά class και απαγορευμένες μεταβάσεις· A0–A4 derivation assurance·
F0–F3 formalization fidelity (F3 ταβάνι, πάντα EMPIRICAL)· anti-laundering (A ποτέ δεν
αναβαθμίζει F· συνολική ισχύς = min αξόνων)· coverage stamp ⟨C,S,T,W,G⟩.

### 7.2 Worlds, disputes, lifecycle
- `InterpretationWorld` = ⟨fact-world × construal-set × forum⟩· ανταγωνιστικές ερμηνείες
  συνυπάρχουν ως claims σε διαφορετικά/ίδια worlds με καταγεγραμμένες σχέσεις
  SUPPORTS/CONFLICTS_WITH — το σύστημα δεν «διαλέγει» δόγμα ως fact (I-4).
- **Claim History = μέλος του Root Set (I-12):** append-only· τα claim indexes/υλοποιημένες
  όψεις είναι caches.
- Lifecycle αυτοματισμός: κάθε dependency μεταβολή (νέο L event, superseded premise, source
  change) ⇒ STALE διάδοση σε φραγμένο χρόνο· STALE ποτέ δεν σερβίρεται ως ACTIVE.

### 7.3 UNKNOWN (πλήρης δομή — I-15)
```
UNKNOWN := ⟨ reason ∈ { SOURCE_MISSING, TEMPORAL_AMBIGUITY, CONFLICTING_AUTHORITIES,
                        UNRESOLVED_IDENTITY, INSUFFICIENT_FORMALIZATION,
                        INCOMPLETE_COVERAGE, POLICY_RESTRICTED }   (κλειστό, versioned)
           , evidence             : τι ΞΕΡΟΥΜΕ που θεμελιώνει την άγνοια
           , scope                : σε τι ακριβώς αναφέρεται (provision/χρονικό παράθυρο/world)
           , resolution_condition : τι artifact/γεγονός θα το έλυνε (actionable) ⟩
```
- No-silent-coercion: UNKNOWN δεν γίνεται ποτέ default από κανένα ανώτερο στρώμα.
- `POLICY_RESTRICTED` μόνο για publication/egress αρνήσεις· ΠΟΤΕ ως cross-matter σήμα (I-15).

## 8. N — NORMATIVE / CASE

- **Normative IR:** typed, versioned, authored artifact (μέλος Root Set): norms με atoms
  δεμένα σε source spans (`atom → provision@version → event → evidence`), deontic τελεστές,
  exceptions/defeasibility, applicability conditions, χρονικό scope. Acceptance: `serialize →
  parse → ταυτό IR` + πλήρης atom→span κάλυψη· το text round-trip είναι διαγνωστικό, όχι κριτήριο.
- **Inference:** αιτιολογημένη συμπερασματολογία (JTMS-class dependency tracking, well-founded
  semantics για defeasibility, event calculus για καταστάσεις/προθεσμίες). Κάθε συμπέρασμα
  εκπέμπεται ΜΟΝΟ ως Claim με πλήρες contract (§7) — το inference engine δεν έχει δικό του
  «κανάλι αλήθειας».
- **Case layer:** υπαγωγή, precedent χρήση, dialectic δέντρα (επιχείρημα/αντεπιχείρημα ανά
  world), προθεσμίες/δικονομικά βήματα ως executable κανόνες με deadline claims. Όλα τα
  αποτελέσματα = Claims· τίποτα δεν γράφει L/B/S.
- F-fidelity πειθαρχία: κάθε φορμαλοποίηση φέρει F-level· source change ⇒ αυτόματο F-πτώση/STALE
  μέχρι re-attestation.

## 9. C — DERIVED KNOWLEDGE / QUERY / IMPACT

- Graph store, RDF/SPARQL, full-text/semantic search, embeddings, dependency indexes, impact
  propagation δομές: **όλα caches** (I-12).
- **Κάθε epistemic ακμή (INTERPRETS, DEPENDS_ON, SUPPORTS, CONFLICTS_WITH, AMENDS-derived κ.λπ.)
  φέρει claim/event semantics** — δείχνει στο claim ή event από το οποίο προκύπτει. «Γυμνή» ακμή
  χωρίς καταγωγή δεν μπορεί να υπάρξει στο σχήμα.
- **Rebuild law:** `DELETE <any derived store>` ⇒ πλήρης ανακατασκευή από Root Set με
  ταυτόσημα αποτελέσματα (state roots / canonical serializations). Ασκείται ως τεστ (§17.2).
- Impact/invalidation: νέο L event ⇒ ο dependency graph παράγει το σύνολο επηρεαζόμενων claims ⇒
  STALE διάδοση (§7.2) + review queues· mass invalidation φραγμένη και μετρήσιμη (§17.6).

## 10. INTELLIGENCE PLANE (AI) — εκτός αλήθειας

- Ρόλοι: extractor, researcher, counsel/counter-counsel, critic, citation-checker, synthesizer —
  όλοι **R3/untrusted**. Κανένα authoritative state ownership· μόνο proposals + scratch.
- Έξοδοι AI εισέρχονται ΜΟΝΟ ως: (α) admission candidates προς το pipeline του §4.1 (όπου το
  machinery, όχι το μοντέλο, αποφασίζει), ή (β) Claims κλάσης LEGAL_INTERPRETATION/PREDICTION με
  A0/A1 και generator manifest στο coverage stamp. Ποτέ DETERMINISTIC/AUTHORITATIVE (CC-1).
- Egress ΜΟΝΟ μέσω G-inf (privilege/matter policy πριν από κάθε provider call — I-6)· prompts,
  responses, context συνθέσεις = matter-tagged, compartmented (§11).
- Retrieval accelerators (embeddings κ.λπ.) = caches του C με τα ίδια rebuild/containment laws.

## 11. P — PRACTICE / PRIVILEGE / SECURITY PLANE

- **Matter compartments:** isolation = απουσία handle σε ΟΛΟ το surface: stores, indexes,
  caches, embeddings, temp files, logs, traces, dumps, backups, snapshots, agent memory, model
  contexts, exports, telemetry. Cross-matter πρόσβαση = μη σχηματίσιμο ερώτημα (structural
  absence), όχι policy άρνηση (I-15).
- **Data classes** {PUBLIC, INTERNAL, CLIENT_CONFIDENTIAL, PRIVILEGED, WORK_PRODUCT, RESTRICTED}·
  για PRIVILEGED/RESTRICTED η external-egress capability είναι δομικά απούσα.
- **G-pub (publication gateway):** fail-closed· μόνο PUBLIC-class, approved υλικό (δημόσιο =
  μόνο κωδικοποιημένοι δημόσιοι νόμοι)· failure ⇒ publication disabled, ΚΑΝΕΝΑ bypass σε
  ασθενέστερο μονοπάτι· canary + stego red-team καθεστώς σε κάθε release.
- **Capabilities:** κάθε write/egress με issued capability ⟨issuer, holder, scope, expiry,
  bounded delegation, revocation, replay-nonce, audit-binding, SoD⟩· break-glass = χωριστός
  τύπος με 2-person issuance, ρητό expiry, loud incident, καμία delegation.
- Ethical walls, conflicts checking, procedural calendars = policy state του plane, με τα
  deadlines να παράγονται από το N ως claims και να επιτηρούνται εδώ.

## 12. D — VERIFICATION & TRUST DISTRIBUTION

- **Internal independence, ΤΩΡΑ:** χωριστός verifier per critical function (admission checker,
  proof checker, projector B) σε **χωριστό θεμέλιο/υλοποίηση**, χωριστό build, χωριστή
  state reconstruction. Καθεστώς B4: mutation fixture ∧ independent implementation ∧ positive
  conformance — για ΚΑΘΕ high-assurance verifier, ρητά και για το canonical reconstruction (I-14).
- **Attestation υλικό:** περιοδικά kernel-signed checkpoints ⟨S-root, L-root, golden state
  roots, PCs, admission stats⟩ — ανεξάρτητα επαληθεύσιμο bundle.
- **Federation, ΟΤΑΝ υπάρξει πραγματικό trust diversity:** external institutional witness,
  federated verifier, independent observatory — ανταλλαγή signed observations/checkpoints/proof
  bundles. **Καμία federation-of-one**: μέχρι τότε ο ρόλος καλύπτεται από την εσωτερική
  ανεξαρτησία + offline επαληθευσιμότητα του attestation bundle από τρίτο, αν του δοθεί.

## 13. STORAGE & REBUILD SEMANTICS

- Root Set stores: append-only, content-addressed, merkle-checkpointed, με τα ισχυρότερα
  durability guarantees του συστήματος (fsync πειθαρχία, πολλαπλά αντίγραφα, offline copies).
- Caches: οποιοδήποτε substrate εξυπηρετεί (γράφος, σχεσιακό, search engine, vector store) —
  η επιλογή substrate ΔΕΝ είναι αρχιτεκτονική δέσμευση, ακριβώς επειδή είναι cache (I-12).
- **Νόμος ανακατασκευής:** `rebuild(S, L, ClaimHistory, AuthoredArtifacts@versions) →` πλήρες
  σύστημα με byte-ταυτόσημα canonical state roots και ταυτόσημες canonical όψεις των caches.
  Τρέχει προγραμματισμένα (κάθε release τουλάχιστον μερικώς, περιοδικά πλήρως) — όχι μόνο σε
  καταστροφή.

## 14. SCALE MODEL

- Κλιμάκωση διαβάζοντας: όλο το ερωτηματικό φορτίο χτυπά caches (C/B materializations)· τα
  Root Set stores δέχονται μόνο admission/append ρυθμούς (χαμηλούς εκ φύσεως για νομικό υλικό).
- Incremental projection: νέο event ⇒ delta-projection με PC ανά checkpoint· πλήρες replay μόνο
  για verification/rebuild.
- Sharding κατά φυσικά όρια (instrument/domain/court) στο C· το L παραμένει ενιαίο λογικά
  (μοναδική σειρά admission) ακόμη κι αν φυσικά τμηματοποιημένο με cross-checkpoints.
- Ο σχεδιασμός δεν απαιτεί εξωτικό hardware: το κρίσιμο κόστος είναι το verification καθεστώς,
  που τρέχει offline/async από το serving path.

## 15. UPGRADEABILITY & SCHEMA EVOLUTION

- Event schemas versioned· **παλαιά events δεν ξαναγράφονται ΠΟΤΕ**· εξέλιξη = νέο schema
  version + **upcast functions** που είναι versioned authored artifacts του Root Set.
- Αλλαγή projector/κανόνων ⇒ νέα PC γενιά + **differential report** παλαιών/νέων state roots
  με εξήγηση κάθε απόκλισης πριν γίνει αποδεκτή.
- Κάθε αναβάθμιση trusted συστατικού (kernel, checkers, projectors, taxonomies, enums) περνά
  από **upgrade ceremony** (G-sev): proposal → adversarial review → shadow/differential →
  ρητή έγκριση δημιουργού. Τα κλειστά enums (§4.2, §7.3, EpistemicClass) επεκτείνονται ΜΟΝΟ έτσι.
- Autonomy: το σύστημα μπορεί να προτείνει αναβαθμίσεις που έχει τρέξει σε sandbox — πάντα ως
  proposals σε ουρά, ποτέ αυτο-εφαρμογή.

## 16. FAILURE MODEL

- **Default = fail-closed** σε κάθε trusted απόφαση: admission, gates (G-pub/G-inf/G-sev),
  capability checks, PC verification. Crash σε rule/predicate ⇒ REJECT + incident, ποτέ ALLOW.
- **Containment:** poisoned source ⇒ ζει στο S χωρίς authority (I-11)· ύποπτο event ⇒
  quarantine με reason· διαφωνία projectors ⇒ BLOCK release· gateway failure ⇒ κανάλι κλειστό.
- **Degradation σκάλα (ρητή):** χωρίς caches ⇒ αργό αλλά ορθό (rebuild)· χωρίς AI plane ⇒
  πλήρως λειτουργικό canonical/temporal/normative core· χωρίς δίκτυο πηγών ⇒ ρητά stale-marked
  απαντήσεις με known_at όριο — ποτέ σιωπηλά ξεπερασμένες.
- Κάθε incident = journaled, capability-bound, με post-mortem υποχρέωση στο governance plane.

## 17. ARCHITECTURE EXPERIMENTS — τα 10 falsifiers (πύλη DESIGN HYPOTHESIS → DEMONSTRATED)

Κάθε πείραμα: δηλωμένο fixture universe + metric + threshold + failure action (καθεστώς §0.3
του v0.8, δεσμευτικό). Σκιαγράφηση:

1. **Temporal replay torture** — grid (provision × valid_at × known_at) σε golden corpus με
   retroactivity/corrections/conditional commencements· κάθε resolve ντετερμινιστικό και ίσο
   με ανεξάρτητο projector. *Falsifies:* B-semantics, I-7, I-14.
2. **Full reconstruction** — καταστροφή ΟΛΩΝ των caches· rebuild από Root Set· byte-ταυτόσημα
   state roots + ταυτόσημες canonical όψεις. *Falsifies:* I-12.
3. **Poisoned admission** — adversarial captures (πλαστή πηγή, πειραγμένο digest, αναρμόδια
   αρχή, αντιφατικό περιεχόμενο): 0 admissions· όλα ανιχνεύσιμα στο S χωρίς authority.
   *Falsifies:* §4.1, I-11.
4. **Projector N-version disagreement** — εμφύτευση bug στον projector A· η διαφωνία
   ανιχνεύεται στο golden set και μπλοκάρει release. *Falsifies:* I-14, I-2.
5. **Claim laundering** — απόπειρες απαγορευμένων μεταβάσεων (confidence/επανάληψη/LLM-consensus
   → class promotion, A→F αναβάθμιση): 100% REJECT. *Falsifies:* §7, I-4.
6. **Mass invalidation** — αναδρομικός νόμος/ακύρωση erga omnes: πλήρες, φραγμένο STALE wave·
   0 stale claims σερβίρονται ως ACTIVE. *Falsifies:* §7.2, §9, I-5.
7. **Matter escape** — red-team σε όλο το isolation surface (§11) + inference-channel απόπειρες
   (μεταξύ άλλων μέσω UNKNOWN/latency/cache σημάτων): 0 bytes, 0 existence signals.
   *Falsifies:* P-plane, I-6, I-15.
8. **Schema evolution** — εισαγωγή event-schema v+1 με upcast· πλήρες replay παλαιού L· roots
   σταθερά ή με εξηγημένο diff. *Falsifies:* §15.
9. **Disaster recovery** — χρονομετρημένο πλήρες rebuild σε καθαρό host από Root Set αντίγραφα·
   όλα τα certificates επαληθεύουν· εντός δηλωμένου RTO. *Falsifies:* §13.
10. **Independent reproduction** — τρίτη υλοποίηση (ελάχιστη, χωριστό θεμέλιο) αναπαράγει golden
    state roots από δημοσιευμένα S+L+artifacts. *Falsifies:* I-14, §12 — το ισχυρότερο τεστ.

## 18. RESIDUALS — ρητά ανοιχτά (τίμια άγνοια του ίδιου του σχεδίου)

- **R-a:** Το περιεχόμενο του erga-omnes κατατακτήριου πίνακα (I-13) είναι νομική έρευνα προς
  attestation — το σχήμα είναι έτοιμο, ο πίνακας όχι. [Απαιτεί F-graded authored artifact.]
- **R-b:** Το φράγμα χρόνου της STALE διάδοσης (§7.2/§17.6) — αριθμητικός στόχος ορίζεται στο
  freeze, όχι εδώ, για να μην είναι αυθαίρετος.
- **R-c:** Η ελάχιστη επάρκεια του «χωριστού θεμελίου» για projector B (I-14): πλήρης δεύτερη
  γλώσσα/στοίβα vs. ανεξάρτητη minimal υλοποίηση — απόφαση στο destruction pass.
- **R-d:** Αν το Claim History χρειάζεται δικό του admission καθεστώς πέραν του K-typ (ποιος
  εμποδίζει claim-flooding από agents) — προτεινόμενη λύση: rate/quota capabilities στο P-plane.
- **R-e:** Federation protocol λεπτομέρειες (μορφή proof bundles για τρίτους) — σκόπιμα ανοιχτό
  μέχρι να υπάρξει πραγματικός δεύτερος θεσμός (§12).

---

**Πύλη:** destruction pass Reviewer-A × Reviewer-B επί του παρόντος → κλείσιμο/ανασκευή κάθε
ευρήματος → Target Architecture v1.0 → ρητό «εγκρίνω freeze target» του δημιουργού → το v0.8
ξαναδένεται ως migration plan (v0.9) προς το v1.0. Καμία production αλλαγή πριν από όλα αυτά.
