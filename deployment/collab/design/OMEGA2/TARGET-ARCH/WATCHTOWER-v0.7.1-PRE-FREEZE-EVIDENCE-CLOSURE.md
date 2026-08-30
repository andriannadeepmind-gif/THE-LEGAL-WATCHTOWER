# WATCHTOWER VLT v0.7.1 — PRE-FREEZE EVIDENCE CLOSURE
**Patch to v0.7** (`sha256:bac029b7abb3e113b5fb7f0350e6b70eb355419cdf0492abb46e6274c7765cb8`).
Applies ONLY the four pre-freeze obligations of the Group-T audit, plus the architectural
requirements that the industrial model checker discovered while closing them. **No redesign of
any PASS domain.** v1.0, when authorized, will be assembled self-contained from v0.7 + this patch.
**Καμία production αλλαγή· το repository παραμένει ανέγγιχτο** (όλα τα μοντέλα ζουν στο scratchpad).

## CLOSURE MAP
| Obligation | Status |
|---|---|
| R-j industrial formal tooling, critical nucleus | **CLOSED** — TLA+/TLC 2.19, δύο modules, 17 configurations, βλ. §A |
| R-s multi-position log matching / gap-freedom | **CLOSED** — `WatchtowerLog.tla`, πλήρες state graph CFT & BFT, βλ. §A.1 |
| Model D proof-scope mismatch | **CLOSED κατά Option A** (επέκταση, όχι περιορισμό ισχυρισμού) — και τα 11 δηλωμένα channels έχουν πλέον explicit observation function και δικό τους noninterference check, βλ. §A.3 |
| R-b / R-f freeze hygiene | **CLOSED κατά Option B** (versioned operational policy parameters + safety invariants ανεξάρτητες τιμών), βλ. §C |
| — | **ΝΕΟ:** τρεις αρχιτεκτονικές απαιτήσεις που ανακάλυψε το TLC, §B |
| — | **ΝΕΟ:** Reviewer-A counter-challenge — τέσσερα ευρήματα state-of-the-art, §E (προς κρίση, ΟΧΙ σιωπηλή συγχώνευση) |

---

# §A — ΕΚΤΕΛΕΣΜΕΝΟ INDUSTRIAL FORMAL EVIDENCE

Εργαλείο: **TLA+ / TLC 2.19 (08 Aug 2024)**, `tla2tools.jar`
`sha256:936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88`, OpenJDK 21.
Πλήρη αποτελέσματα: `formal/TLA-RESULTS.md`. Πειθαρχία αμετάβλητη: κάθε αποτέλεσμα με bounds
stamp· «Model checking completed» σημαίνει **πλήρες state graph** στα δηλωμένα bounds· κάθε
μοντέλο συνοδεύεται από mutation battery και χωρίς αυτήν δηλώνεται VACUOUS.

## A.1 `WatchtowerLog.tla` — ordered commit chain (κλείνει το R-s)
Πολυθέσιο replicated log, epoch fencing, election restriction με lock adoption, bounded
partitions, Byzantine replicas που αποκρύπτουν log στο view change και δέχονται replication
χωρίς έλεγχο. Bounds: 2 θέσεις, 2 τιμές, 2 epochs.
Ιδιότητες: `NoTwoValuesAtSamePosition`, `NoCommittedGap`, `LogMatching`, `PrefixConsistency`,
`CommittedPrefixMonotonicity` (action property).

| configuration | αποτέλεσμα | distinct states | depth |
|---|---|---|---|
| CFT (n=3, q=2, 0 byz) | **No error found — πλήρες state graph** | 4.975 | 11 |
| CFT_BYZ (n=3, q=2, 1 byz) | `NoTwoValuesAtSamePosition` VIOLATED — **αναμενόμενο**: η εκτελέσιμη απόδειξη του I-24 σε επίπεδο πολυθέσιου log | 6.392 | 10 |
| BFT (n=4, q=3, f=1) | **No error found — πλήρες state graph** | 37.071 | 14 |
| BUG_GAP | `NoCommittedGap` VIOLATED (teeth) | 1.024 | 8 |
| BUG_ADOPT | `NoTwoValuesAtSamePosition` VIOLATED (teeth) | 5.022 | 10 |
| BUG_TRUNC | `CommittedPrefixMonotonicity` VIOLATED (teeth) | 555 | 7 |

## A.2 `WatchtowerCore.tla` — commit/cut nucleus + key lifecycle (κλείνει το R-j)
RootCommit με intended transaction, crash/recovery, checkpoint cuts, admission corrections,
composite ⟨system, matter⟩ cuts, key lifecycle με threshold recovery και destruction.
Bounds: 2 objects, 2 commits, 2 cuts, 2 system commits, 2 matter commits, threshold 2/3.
Δέκα invariants· **baseline: πλήρες state graph, 390.400 distinct states, depth 16, κανένα
σφάλμα**· **mutation battery 10/10 CAUGHT**, κάθε mutant από τον στόχο του:
`torn_commit → NoHalfCommit` · `rewrite_history → HistoricalImmutability` ·
`cut_regression → CutMonotonicity` · `leak_pending → NoBackdating` ·
`basis_future → BasisBackwardOnly` · `basis_regress → BasisMonotonic` ·
`resurrect_key → DestroyedKeyCannotReturn` · `self_recover → NoSelfRecovery` ·
`sign_when_revoked → RevokedKeyCannotAuthorize` · `threshold_off → RecoveryRequiresThreshold`.

## A.3 `model_d2_channels.py` — noninterference σε ΟΛΑ τα δηλωμένα channels (κλείνει το scope mismatch)
Το §28 του v0.7 χαρακτήριζε έντεκα channels «formal/modelled» ενώ το παραδοθέν Model D
φορμαλοποιούσε ΔΥΟ. Επιλέχθηκε το **Option A**: επέκταση του μοντέλου, όχι περιορισμός του
ισχυρισμού. Κάθε entry φέρει **visibility tag** (ποιο matter το βλέπει, ή `*` για κοινή
επιφάνεια) και **causer tag** (ποιο matter το προκάλεσε, μη-παρατηρήσιμο). Ιδιότητα: ό,τι
βλέπει το matter B στην πραγματική εκτέλεση ταυτίζεται με ό,τι θα έβλεπε στην εκτέλεση από την
οποία αφαιρέθηκε **κάθε** ενέργεια του matter A.
Αποτέλεσμα ανά channel — **11/11 baseline EXHAUSTED & HOLDS, 11/11 seeded leak CAUGHT**:
`identifiers · handles · counters · sequence_numbers · namespace_presence · storage_keys ·
cache_keys · control_messages · error_results · authorization_outcomes · explicit_metadata`.
**Εκτός μοντέλου, ρητά (αμετάβλητο):** timing, contention, scheduling, storage latency, traffic
patterns, witness/checkpoint cadence, cache timing — παραμένουν Assumptions/Residuals και
ελέγχονται εμπειρικά (falsifiers 43/49).

## A.4 Bounded-model discipline (αμετάβλητη)
Κανένα από τα παραπάνω δεν είναι universal theorem. Το `WatchtowerLog` **δεν** αποτελεί απόδειξη
του Raft, του PBFT ή οποιουδήποτε production πρωτοκόλλου· είναι evidence για τη σημασιολογία της
commit chain που απαιτεί το `CommitReplicationProfile`. Το επίπεδο αφαίρεσης, τα bounds και τα
αποκλεισμένα channels δηλώνονται σε κάθε αποτέλεσμα.

---

# §B — ΤΡΕΙΣ ΑΡΧΙΤΕΚΤΟΝΙΚΕΣ ΑΠΑΙΤΗΣΕΙΣ ΠΟΥ ΑΝΑΚΑΛΥΨΕ ΤΟ TLC

Δεν είναι διορθώσεις του μοντέλου· είναι κανόνες που **έλειπαν από την πρόζα του v0.7** και που
χωρίς αυτούς η commit chain είναι αποδεδειγμένα μη ασφαλής. Προστίθενται στο §21
(CommitReplicationProfile) ως υποχρεωτικά στοιχεία κάθε profile.

**B-1 — Adopted-view well-formedness validation.**
*Counterexample (BFT, n=4, q=3, f=1):* Byzantine replica δέχεται entry στη θέση 2 χωρίς να
κατέχει τη θέση 1, δημιουργώντας **μη συνεχόμενο log**· ο επόμενος leader υιοθετεί αυτό το view
στο view change και το log matching μεταξύ έντιμων replicas καταρρέει.
*Κανόνας:* ο εκλεγόμενος leader **επικυρώνει τη μορφική ορθότητα κάθε view πριν το υιοθετήσει** —
συνεχόμενο prefix ΚΑΙ μη-φθίνουσες epochs. Μη έγκυρο view απορρίπτεται (θεωρείται κενό).

**B-2 — Conflict truncation on accept.**
*Counterexample:* χωρίς truncation, μια replica που δέχεται νέο entry σε προηγούμενη θέση
διατηρεί **παλαιό suffix από προηγούμενο leader**· δύο έντιμες replicas καταλήγουν να συμφωνούν
σε μια θέση ενώ διαφωνούν σε προγενέστερη — παραβίαση `LogMatching`.
*Κανόνας:* η αποδοχή entry στη θέση p **απορρίπτει το suffix πέραν του p**.

**B-3 — Η truncation είναι ΜΟΝΟ επί σύγκρουσης, ποτέ ανεπιφύλακτη.**
*Counterexample (CFT, n=3, χωρίς κανέναν Byzantine!):* με **ανεπιφύλακτη** truncation, μια
replica που ξανα-δέχεται ένα **ταυτόσημο** entry πετά έγκυρα entries που στήριζαν ήδη committed
θέση· χάνει την ιδιότητα «most up-to-date», ο επόμενος leader εκλέγεται από quorum χωρίς αυτά,
και **δεσμεύει διαφορετική τιμή σε ήδη committed θέση**.
*Κανόνας:* ταυτόσημο entry είναι **idempotent και δεν απορρίπτει τίποτα**· το suffix κόβεται
μόνο όταν το εισερχόμενο entry συγκρούεται με το αποθηκευμένο.

> Και τα τρία εντοπίστηκαν από το TLC, όχι από ανάγνωση. Το B-3 είναι το πιο διδακτικό: εμφανίζεται
> σε profile **χωρίς κανέναν κακόβουλο κόμβο** — ακριβώς η κατηγορία σφάλματος που η πρόζα
> «ακούγεται σωστή» και θα είχε παγώσει στο v1.0.

**Επιπλέον, δύο αυτο-διορθώσεις της ίδιας της μεθόδου** (καταγράφονται για τιμιότητα): (i) στην
πρώτη έκδοση του `WatchtowerCore` το mutant `torn_commit` ΔΕΝ πιάστηκε — η `NoHalfCommit` ήταν
vacuous γιατί το μοντέλο δεν κατέγραφε την **πρόθεση** της συναλλαγής· προστέθηκε `intents` και
το mutant πιάνεται· (ii) δύο actions ήταν σιωπηλά απενεργοποιημένες επειδή μια μεταβλητή
εμφανιζόταν ταυτόχρονα σε assignment και σε `UNCHANGED` — εντοπίστηκε με μηχανικό έλεγχο και
διορθώθηκε πριν ανακοινωθεί οποιοδήποτε αποτέλεσμα.

---

# §C — R-b / R-f: OPERATIONAL POLICY PARAMETERS (Option B)

Δεν μπαίνουν αυθαίρετοι αριθμοί στο σύνταγμα. Εισάγεται versioned R_ARTIFACT:
```
OperationalPolicyProfile := ⟨ profile_id, policy_version
  , stale_propagation_bound            (R-b)
  , checkpoint_cadence                 (R-f)
  , quarantine_sla_per_class           (R-f)
  , freshness_window_per_scope, admission_latency_target
  , witness_publication_interval, attestation_freshness_window
  , change_ceremony_ref ⟩
```
**Συνταγματικές ιδιότητες, ανεξάρτητες των τιμών** (αυτές είναι που δεσμεύουν):
1. Κάθε παράμετρος **υπάρχει, είναι πεπερασμένη και δηλωμένη**· απουσία τιμής = fail-closed, όχι
   σιωπηλό default.
2. **Η ασφάλεια δεν εξαρτάται από την τιμή:** claim του οποίου η dependency άλλαξε δεν σερβίρεται
   ποτέ ως ACTIVE, ανεξαρτήτως του `stale_propagation_bound` — η τιμή φράσσει **καθυστέρηση**,
   ποτέ ορθότητα.
3. Κάθε committed entry εντάσσεται σε checkpoint **εντός** του δηλωμένου cadence· υπέρβαση =
   incident, όχι αθόρυβη ολίσθηση.
4. Υλικό σε quarantine **δεν γερνά σιωπηλά**: υπέρβαση SLA ⇒ escalation στο review queue.
5. Ισχυρισμός current-completeness εκτός του `freshness_window` του scope ⇒
   `UNKNOWN{INCOMPLETE_COVERAGE}`.
6. Αλλαγή οποιασδήποτε παραμέτρου = governance ceremony με security-claim delta· η τιμή που ίσχυε
   σε κάθε cut είναι ανακτήσιμη (η policy version δεσμεύεται στα PCs).
**R-b και R-f: CLOSED** ως προς την αρχιτεκτονική· οι αριθμητικές τιμές παραμένουν deployment
decisions (OPERATIONAL), όπως συμφωνήθηκε.

---

# §D — ΕΝΗΜΕΡΩΣΗ RESIDUALS
- **R-j: CLOSED** (§A.1/A.2). Το industrial μοντέλο εισέρχεται ως R_ARTIFACT με
  ArtifactAdmissionCertificate· διατηρείται υποχρέωση trace-conformance υλοποίησης↔μοντέλου.
- **R-s: CLOSED** (§A.1).
- **R-b / R-f: CLOSED ως αρχιτεκτονική** (§C)· τιμές = OPERATIONAL.
- **R-v (ΝΕΟ):** επέκταση bounds του `WatchtowerLog` (3 θέσεις / 3 epochs / n=5) και συμμετρική
  αναγωγή — βελτιώνει την εμπιστοσύνη, **δεν** είναι προϋπόθεση freeze (τα υπάρχοντα bounds
  εκθέτουν και τις τρεις κλάσεις σφάλματος του §B).
- Όλα τα υπόλοιπα residuals αμετάβλητα.

---

# §E — REVIEWER-A STATE-OF-ART COUNTER-CHALLENGE

Ο Reviewer-B έκλεισε το design-space search. Ο Υπέρτατος Νόμος του δημιουργού με υποχρεώνει να
ρωτήσω ξανά: **υπάρχει αυστηρά ανώτερο;** Απάντηση: **ναι, τέσσερα.** Καθένα κρίθηκε με τον
τετραπλό κανόνα του Reviewer-B (concrete & mature · authoritative evidence · συγκεκριμένο
ακάλυπτο threat · μη-regressive). Κατατίθενται **προς κρίση ως προτεινόμενα I-41…I-44 — δεν
συγχωνεύονται σιωπηλά.**

## GE-16 — Authenticated answers: proof of inclusion ΚΑΙ proof of completeness
**Ακάλυπτο threat.** Το v0.7 πιστοποιεί **state roots**· δεν πιστοποιεί **απαντήσεις**. Μια
απάντηση του `resolve(...)` φτάνει στον χρήστη χωρίς καμία επαληθεύσιμη δέσμευση προς το
certified root. Το serving/cache μονοπάτι είναι εκτός κάθε υπάρχοντος ελέγχου: PC πιστοποιεί
ανακατασκευή, tiers πιστοποιούν το root, witnesses βλέπουν roots — **κανένα δεν βλέπει την
απάντηση**. Και η θανατηφόρα εκδοχή δεν είναι η αλλοιωμένη απάντηση αλλά η **σιωπηλή παράλειψη**:
μια απάντηση που παραλείπει μια τροποποίηση φαίνεται απολύτως έγκυρη. Για νομικό σύστημα, η
παράλειψη είναι η χειρότερη αστοχία που υπάρχει, και σήμερα είναι αόρατη.
**Ώριμη τεχνική.** Authenticated data structures / verifiable query answers: inclusion proofs
**και completeness (non-membership / range) proofs** πάνω σε authenticated ordered dictionary —
η οικογένεια CT (inclusion+consistency) και CONIKS/Key-Transparency-class (per-record proofs με
privacy) είναι production-grade.
**Πρόταση (I-41).** `AnswerCertificate := ⟨answer, inclusion proofs κάθε επιστρεφόμενου
στοιχείου, completeness proof για το ερωτηθέν εύρος/κατηγόρημα, PC ref, EvaluationCut, tier⟩`.
Νόμος: **καμία authoritative απάντηση χωρίς επαληθεύσιμη δέσμευση προς certified root,
συμπεριλαμβανομένης απόδειξης ότι τίποτα εντός scope δεν παραλείφθηκε.**
**Μη-regressive.** Καθαρή προσθήκη στο serving boundary· συντίθεται με PC, με tiers, και με το
matter privacy (private απαντήσεις αποδεικνύονται έναντι του matter root).
**Falsifier 60 — silent omission:** ο serving path αφαιρεί ένα εν ισχύι στοιχείο από την
απάντηση ⇒ ο completeness proof **αποτυγχάνει στον client**, χωρίς εμπιστοσύνη στον server.

## GE-17 — Accountability: μεταβιβάσιμη απόδειξη υπαιτιότητας, όχι μόνο ανίχνευση
**Ακάλυπτο threat.** Το v0.7 **ανιχνεύει** equivocation και projector disagreement, αλλά δεν
παράγει **αυτοτελές, μεταβιβάσιμο τεκμήριο που κατονομάζει τον υπαίτιο**. Για σύστημα του οποίου
ο σκοπός είναι αποδεικτικός (ισότητα όπλων, υπεράσπιση γνωμοδότησης), το «εντοπίσαμε απόκλιση»
είναι ασύγκριτα ασθενέστερο από «ιδού υπογεγραμμένη απόδειξη ότι ο X εξέδωσε δύο αντιφατικές
δηλώσεις για το ίδιο cut».
**Ώριμη τεχνική.** Accountable distributed systems (PeerReview-class) και BFT forensics: εξαγωγή
υπαιτιότητας από υπογεγραμμένα αντιφατικά μηνύματα.
**Πρόταση (I-42).** `CulpabilityProof := ⟨conflicting signed statements, common context
(cut/domain), signer identity, verification recipe⟩` — αυτοτελές, επαληθεύσιμο από τρίτο **χωρίς
καμία εμπιστοσύνη στον operator**· υποχρεωτική έξοδος κάθε EQUIVOCATION_DETECTED και κάθε
PROJECTOR_DISAGREEMENT όπου τα artifacts είναι υπογεγραμμένα.
**Μη-regressive.** Προσθήκη στο witness/attestation στρώμα· το I-30 (domain separation) την κάνει
άμεσα κατασκευάσιμη. **Falsifier 61.**

## GE-18 — Rollback/forking detection για τα matter-private namespaces
**Ακάλυπτο threat — και είναι κενό που δημιούργησε ο ΔΙΚΟΣ ΜΑΣ σχεδιασμός.** Το blind anchoring
κρύβει σκόπιμα τη δραστηριότητα κάθε matter από τους witnesses. Συνέπεια: τα **system roots**
είναι witnessed, τα **matter roots όχι**. Άρα επαναφορά ενός matter chain σε παλαιότερο συνεπές
snapshot — όλες οι υπογραφές εξακολουθούν να επαληθεύονται — **δεν ανιχνεύεται από κανένα
στρώμα**. Επιτιθέμενος με πρόσβαση στην αποθήκευση μπορεί σιωπηλά να εξαφανίσει ένα admitted
claim μιας υπόθεσης. Κανένας από τους δύο reviewers δεν το είχε εντοπίσει.
**Ώριμη τεχνική.** Rollback protection με **monotonic counters** σε hardware root of trust
(TPM/TEE-class) και client-held freshness receipts — η καθιερωμένη λύση για trusted storage.
**Πρόταση (I-43).** `MatterFreshnessAnchor := ⟨matter_id, chain_head, monotonic_counter_value,
attestation ref, client receipt⟩`: κάθε matter chain head δεσμεύεται σε μονότονο μετρητή του
hardware root of trust ή/και σε αποδείξεις που κρατά ο ίδιος ο χρήστης, ώστε το rollback να
είναι **ανιχνεύσιμο χωρίς να αποκαλύπτεται δραστηριότητα σε τρίτους**.
**Μη-regressive.** Συντίθεται με το RuntimeIntegrityProfile (ήδη υπάρχον) και διατηρεί το blind
anchoring. **Falsifier 62 — matter rollback:** επαναφορά matter chain σε παλαιότερο head ⇒
ανίχνευση από counter/receipt mismatch· 0 existence signal προς τρίτους.

## GE-19 — Canonical encoding injectivity / malleability assurance
**Ακάλυπτο threat.** Τα I-22 και I-30 στηρίζονται εξ ολοκλήρου στην υπόθεση ότι η canonical
κωδικοποίηση είναι **ενριπτική και μη αμφίσημη**. Το v0.7 δηλώνει τον encoding νόμο ως artifact
αλλά **δεν έχει κανέναν μηχανισμό διασφάλισης**. Ένα malleability bug — δύο διαφορετικά
σημασιολογικά αντικείμενα με την ίδια κωδικοποίηση, ή bytes που ο parser δέχεται και
επανακωδικοποιεί διαφορετικά — καταρρίπτει **ταυτόχρονα** το content addressing και το domain
separation. Κάθε άλλη εγγύηση του συστήματος είναι κατάντη αυτής.
**Ώριμη τεχνική.** Formally verified parsers/serializers (EverParse-class παραγωγή αποδεδειγμένα
ορθού κώδικα μορφοτύπων) και canonical-form property/differential testing.
**Πρόταση (I-44).** `CanonicalEncodingAssurance` με δηλωμένο επίπεδο: (a) round-trip
`decode(encode(x)) = x`· (b) canonicity `encode(decode(b)) = b` για κάθε αποδεκτό b·
(c) injectivity διασταυρούμενη με τα domain separation πεδία (κανένα object type δεν παράγει
κωδικοποίηση άλλου)· ελάχιστο: structure-aware fuzzing + property testing· στόχος για το trusted
path: formally verified parser/serializer.
**Μη-regressive.** Ενισχύει το θεμέλιο των I-22/I-30 χωρίς να τα αλλάζει.
**Falsifier 63 — encoding malleability:** αναζήτηση δύο διακριτών αντικειμένων με ίδιο ObjectId ή
bytes με μη σταθερό re-encoding ⇒ 0 ευρήματα εντός του δηλωμένου fuzz envelope.

### Σύνοψη counter-challenge
| # | Threat που μένει ακάλυπτο στο v0.7 | Ώριμη οικογένεια | Κρισιμότητα |
|---|---|---|---|
| GE-16 | σιωπηλή **παράλειψη** σε σερβιρισμένη απάντηση | authenticated dictionaries / CT-class inclusion+completeness | **υψίστη** — η χειρότερη νομική αστοχία, σήμερα αόρατη |
| GE-17 | ανίχνευση χωρίς μεταβιβάσιμο τεκμήριο υπαιτιότητας | accountable systems / BFT forensics | υψηλή — αποδεικτική αξία |
| GE-18 | rollback matter-private ιστορίας, αόρατο λόγω blind anchoring | monotonic counters / TEE rollback protection | **υψίστη** — κενό που δημιούργησε ο δικός μας σχεδιασμός |
| GE-19 | malleability της canonical κωδικοποίησης | verified parsers/serializers | υψηλή — θεμέλιο των I-22/I-30 |

---

**Πύλη.** Το §A/§B/§C κλείνει ό,τι ζήτησε το Group-T audit. Το §E κατατίθεται προς κρίση του
Reviewer-B με τον δικό του τετραπλό κανόνα. Αν το §E γίνει δεκτό, ενσωματώνεται πριν από κάθε
δήλωση ceiling — αλλιώς καταγράφεται ως ρητά απορριφθέν με αιτιολογία. Σε κάθε περίπτωση:
«GLOBAL ELITE CEILING — PASS» → «TARGET ARCHITECTURE v1.0 — READY FOR CREATOR FREEZE DECISION»
→ **ΜΟΝΟ ο δημιουργός: «εγκρίνω freeze target»**. ΚΑΜΙΑ PRODUCTION ΑΛΛΑΓΗ.
