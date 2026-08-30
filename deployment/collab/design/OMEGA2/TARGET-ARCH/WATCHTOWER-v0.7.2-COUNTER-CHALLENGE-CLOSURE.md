# WATCHTOWER VLT v0.7.2 — COUNTER-CHALLENGE CLOSURE
**Patch to v0.7 + v0.7.1.** Προσθέτει ΜΟΝΟ τα τέσσερα constitutional seats που έγιναν δεκτά στην
adjudication (I-41…I-44 στη μορφή που όρισε ο Reviewer-B), τα B-1/B-2/B-3 ως mandatory
replication semantics, τους falsifiers 60–63, και το **εκτελεσμένο architecture evidence** για
καθένα. **Καμία άλλη αλλαγή σε PASS domain. Καμία production αλλαγή· το repository παραμένει
ανέγγιχτο.**

Βάσεις: v0.7 `sha256:bac029b7…5cb8` · v0.7.1 `sha256:fb37d119…bb00`.

## ΤΙ ΕΚΛΕΙΣΕ
| Item | Μορφή | Evidence |
|---|---|---|
| I-41 Verifiable Authoritative Answers | §1 (schema Reviewer-B + hard law + anti-laundering law) | **MODEL F — PASS** |
| I-42 Typed Accountability Evidence | §2 (τρεις τύποι· «culpability» ΔΕΝ χρησιμοποιείται) | **MODEL G — PASS** |
| I-43 Matter State Continuity | §3 (profiled mechanism classes + receipt + privacy law) | **MODEL H — PASS** |
| I-44 Canonical Encoding Assurance | §4 (profile + τρεις υποχρεωτικές ιδιότητες + strictness) | **MODEL I — PASS** |
| B-1/B-2/B-3 replication semantics | §5 (mandatory profile elements) | TLA+ §A.1 v0.7.1 |
| Falsifiers 60–63 | §6 (με τις οξύνσεις του Reviewer-B) | §7 |
| Reproducibility lock | `formal/REPRODUCIBILITY-LOCK.md` | tool URI + digest + runtime |

---

## §1 — I-41 VERIFIABLE AUTHORITATIVE ANSWERS
```
AnswerCertificate := ⟨ query_spec_digest, answer_digest, EvaluationCut
                     , authenticated_query_view_root, PC_ref, assurance_ref
                     , proof_class, proof, FreshnessEnvelope_ref ⟩
proof_class ∈ { MEMBERSHIP, NON_MEMBERSHIP, RANGE_COMPLETENESS, DETERMINISTIC_DERIVATION }
```
Το **authenticated query view** είναι deterministic, PC-certified projection/cache —
**ΠΟΤΕ νέο truth root** (υπακούει στο I-12: είναι cache του R).
**Hard law.** Καμία canonical-state / deterministic authoritative απάντηση δεν λαμβάνει
high-assurance serving label αν ο client δεν μπορεί να επαληθεύσει (α) ότι η απάντηση δεσμεύεται
στο certified state και (β) ότι **δεν παραλείφθηκε στοιχείο εντός του δηλωμένου query scope**.
**Anti-laundering law.** Η κρυπτογραφική πληρότητα αποδεικνύει πληρότητα **ως προς την admitted
state στο EvaluationCut** — ΠΟΤΕ πληρότητα του εξωτερικού νομικού κόσμου. Για current-world
ισχυρισμό απαιτείται επιπλέον έγκυρο FreshnessEnvelope. Για `LEGAL_INTERPRETATION`
**απαγορεύεται** ισχυρισμός «περιλαμβάνονται όλες οι δυνατές ερμηνείες»· πιστοποιείται μόνο το
δηλωμένο evidence/retrieval scope.

**Evidence — MODEL F (`formal/model_f_answers.py`): PASS.** Αναφορική κατασκευή authenticated
ordered view (Merkle, domain-separated leaf/node, δέσμευση index+key+value) + client verifier που
εμπιστεύεται **μόνο** το certified root. Positive conformance: τίμια απάντηση επαληθεύεται.
Απορρίφθηκαν όλες οι επιθέσεις: `omit_middle` (κενό δεικτών 2→4), `omit_last` και `omit_first`
(boundary μη γειτονικό), `forge_value` (inclusion proof αποτυγχάνει), `drop_boundary`,
`wrong_root`. **Το seeded silent-omission attack απορρίπτεται από τον client χωρίς καμία
εμπιστοσύνη στον server** — ακριβώς η απαίτηση του falsifier 60.

## §2 — I-42 TYPED ACCOUNTABILITY EVIDENCE
```
AccountabilityEvidence := EquivocationProof | ProtocolViolationProof | DisagreementEvidence
```
- **EquivocationProof** — ίδιος signer, ίδιο (domain, cut), αμοιβαία ασύμβατες υπογεγραμμένες
  δηλώσεις ⇒ ανεξάρτητα επαληθεύσιμο τεκμήριο παρέκκλισης, με attribution.
- **ProtocolViolationProof** — υπογεγραμμένα artifacts + ντετερμινιστική συνταγή επαλήθευσης
  ⇒ απόδειξη παραβίασης **ορισμένου** κανόνα, με attribution.
- **DisagreementEvidence** — υπογεγραμμένο output A ≠ υπογεγραμμένο output B από **διαφορετικούς**
  signers ⇒ **attribution = NONE** μέχρι ανεξάρτητος checker ή spec ceremony (MIC κανόνας 7)
  δείξει ποιος παραβίασε κανόνα.
**Hard law.** Η κρυπτογραφική απόδοση παρέκκλισης πρωτοκόλλου **δεν είναι** νομική υπαιτιότητα.
Η λέξη «culpability» δεν χρησιμοποιείται ως νομικό συμπέρασμα του πυρήνα.
**Συνέπεια για το PROJECTOR_DISAGREEMENT:** παράγει DisagreementEvidence, **ποτέ** attribution —
δύο ανεξάρτητες υλοποιήσεις μπορούν να διαφωνούν επειδή το spec είναι διφορούμενο.

**Evidence — MODEL G (`formal/model_g_accountability.py`): PASS.** Πέντε fixtures:
γνήσια equivocation ίδιου signer ⇒ κατασκευάζεται μεταβιβάσιμη απόδειξη (`attributed_to=opA`)·
ανεξάρτητη διαφωνία δύο projectors ⇒ **DisagreementEvidence με `attributed_to=None`, καμία ψευδής
απόδοση**· παραβίαση του I-21 (certificate που δεσμεύει μελλοντικό prefix) ⇒
ProtocolViolationProof, ενώ η συμμορφούμενη δήλωση **δεν** παράγει απόδειξη· μη επαληθεύσιμη
υπογραφή ⇒ καμία απόδειξη· ταυτόσημη επανάληψη ⇒ καμία απόδειξη. Το falsifier 61 ελέγχεται και
προς τις δύο κατευθύνσεις, όπως απαιτήθηκε.

## §3 — I-43 MATTER STATE CONTINUITY / ROLLBACK RESISTANCE
```
MatterContinuityProfile := ⟨ threat_model, rollback_adversary, continuity_mechanism
                           , freshness_anchor, client_receipt_policy, privacy_policy
                           , recovery, assurance_level ⟩
continuity_mechanism ∈ { HARDWARE_MONOTONIC_STATE, CLIENT_HELD_CHAIN_RECEIPTS,
                         PRIVACY_PRESERVING_EXTERNAL_ANCHOR, ROLLBACK_RESISTANT_TRUSTED_LEDGER,
                         HYBRID }
MatterFreshnessReceipt := ⟨ opaque_matter_commitment, chain_head, monotonic_sequence
                          , previous_receipt_hash, EvaluationCut, attestation_ref, signature ⟩
```
**Hard law.** High-assurance matter state **δεν σερβίρεται** αν το presented head δεν αποδεικνύεται
at-least-as-fresh ως προς continuity state που βρίσκεται **εκτός του ελέγχου του rollback
adversary**.
**Privacy law.** Public witness/anchor υλικό **ΠΟΤΕ** plaintext matter_id, matter cadence ή matter
metadata — μόνο opaque/activity-hiding commitment, σε σύνθεση με I-35 και R-i. Το client-held
receipt είναι **ένας** anchor, όχι universal λύση: όταν ο client έχει χάσει όλη την προηγούμενη
state, το profile πρέπει να δηλώνει ρητά ποια continuity assumption ισχύει.

**Evidence — MODEL H (`formal/model_h_continuity.py`): BOUNDED-EXHAUSTIVE PASS** (30 states,
depth 8). Ο αντίπαλος μπορεί να κατεβάσει αυθαίρετα το αποθηκευμένο head και να επανεκκινήσει.
Ιδιότητες: `NoStaleHighAssuranceServe` και `PublicAnchorRevealsNothing` — και οι δύο HOLD.
Mutation battery 2/2 CAUGHT: με απενεργοποιημένο continuity check το trace
`advance(head=1) → rollback(1→0) → serve_high_assurance(head=0, anchor=1)` σερβίρει stale head·
με δημοσίευση anchor **ανά matter advance** το public feed αποκαλύπτει δραστηριότητα. Ο
μηχανισμός παραμένει **profiled**, όχι hardcoded, όπως όρισε ο Reviewer-B.

## §4 — I-44 CANONICAL ENCODING ASSURANCE
```
CanonicalEncodingProfile := ⟨ encoding_id, protocol_version, schema_version, typed_domain
  , framing rules, field ordering, integer rules, string/unicode rules
  , duplicate-field policy, unknown-field policy, numeric/float policy
  , decoder strictness, conformance artifacts, assurance level ⟩
```
**Υποχρεωτικές ιδιότητες:** `decode(encode(x)) = x` · `accepted(b) ⇒ encode(decode(b)) = b` ·
`encode(x) = encode(y) ⇒ x = y` · cross-type/domain reinterpretation **αδύνατη/απορριπτόμενη**.
**Strictness law:** μη κανονικά bytes ⇒ **REJECT** — ποτέ «δέχομαι και μετά κανονικοποιώ».
**Assurance law:** για trust-critical cryptographic payloads το fuzzing **δεν αρκεί**· απαιτείται
δηλωμένος μηχανισμός: verified serializer/parser **ή** περιορισμένη ντετερμινιστική πρότυπη
κωδικοποίηση + ανεξάρτητο conformance + machine-checkable/property evidence, με structure-aware
fuzzing ως συμπληρωματική άμυνα. Το v1.0 δηλώνει ανά critical payload format ποιο επίπεδο απαιτεί.

**Evidence — MODEL I (`formal/model_i_encoding.py`): PASS.** Εξαντλητικά σε δηλωμένα bounds:
12 αντικείμενα δύο τύπων, **3.906 symbol strings** (alphabet 5, |b| ≤ 5). RoundTrip,
CanonicalAcceptance, Injectivity, DomainSeparation, Differential (ανεξάρτητος δεύτερος decoder) —
όλα HOLD. **Malleability mutants 5/5 CAUGHT:** `allow_trailing` (μη κανονικό γίνεται δεκτό),
`drop_type_tag`, `drop_domain_tag`, `drop_optional_entirely` (σύγκρουση `A(0,None)`/`A(0,0)`),
`conflate_types` (σύγκρουση `A(0,None)`/`B(0)`). *Καταγράφεται για τιμιότητα:* ο αρχικός mutant
`drop_presence_flag` ΔΕΝ πιάστηκε — δεν ήταν πραγματικό ελάττωμα στο συγκεκριμένο πεδίο·
αντικαταστάθηκε από τους δύο παραπάνω που είναι.

## §5 — B-1/B-2/B-3: MANDATORY REPLICATION-PROFILE SEMANTICS
Δεν είναι artifacts του model checking· είναι υποχρεωτικά στοιχεία κάθε `CommitReplicationProfile`:
- **B-1 Adopted-view well-formedness.** Ο εκλεγόμενος leader επικυρώνει κάθε view πριν το
  υιοθετήσει: συνεχόμενο prefix ΚΑΙ μη-φθίνουσες epochs· μη έγκυρο view απορρίπτεται.
- **B-2 Conflict truncation on accept.** Η αποδοχή entry στη θέση p απορρίπτει το suffix πέραν του p.
- **B-3 Truncation ΜΟΝΟ επί σύγκρουσης.** Ταυτόσημο entry είναι idempotent και δεν απορρίπτει
  τίποτα. *(Το B-3 εμφανίστηκε σε profile **χωρίς κανέναν** Byzantine κόμβο.)*

## §6 — FALSIFIERS 60–63
60. **Silent omission** — ο serving path αφαιρεί εν ισχύι στοιχείο ⇒ ο completeness proof
    αποτυγχάνει στον client, χωρίς εμπιστοσύνη στον server. *(MODEL F: 6/6 επιθέσεις REJECTED.)*
61. **Accountability, δύο κατευθύνσεις** — (α) γνήσια equivocation ίδιου signer ⇒ η απόδειξη
    ΠΡΕΠΕΙ να κατασκευαστεί· (β) απλή διαφωνία ανεξάρτητων projectors ⇒ ΠΡΕΠΕΙ να ΜΗΝ αποδοθεί
    ψευδής ευθύνη. *(MODEL G: και τα δύο PASS.)*
62. **Matter rollback** — επαναφορά matter chain σε παλαιότερο head ⇒ απόρριψη stale head από
    continuity state εκτός του ελέγχου του αντιπάλου· 0 existence signal προς τρίτους.
    *(MODEL H: 2/2 mutants CAUGHT.)*
63. **Encoding malleability (ενισχυμένο)** — δοκιμάζονται alternative representations,
    duplicate/unknown fields, field reorderings, numeric encodings, Unicode edge cases,
    cross-schema reinterpretation, encode/decode instability, differential implementations ⇒
    0 αποδεκτά μη κανονικά, 0 συγκρούσεις. *(MODEL I: 5/5 malleability mutants CAUGHT· τα Unicode
    και duplicate/unknown-field σκέλη απαιτούν το πραγματικό payload schema και εκτελούνται στο
    conformance suite του κάθε format — δηλώνεται ως **R-w**.)*

## §7 — ΣΥΝΟΛΙΚΟ EVIDENCE STATE
| Model | Κάλυψη | Αποτέλεσμα |
|---|---|---|
| A (py) | commit/cut/crash/corrections/certificate order | PASS · 6/6 mutants |
| B (py) + `WatchtowerLog.tla` | replication, μονοθέσιο & **πολυθέσιο log** | PASS (CFT, BFT) · CFT_BYZ = I-24 evidence |
| C (py) | authority/capability/entry proof/egress | PASS · 4/4 mutants |
| D + **D2** (py) | matter causality + **11/11 δηλωμένα channels** | PASS · 11/11 leaks caught |
| E (py) + `WatchtowerCore.tla` | key lifecycle· commit/cut/composite cuts | PASS · TLC 10/10 mutants |
| **F** (py) | **I-41 authenticated answers** | PASS · 6/6 attacks rejected |
| **G** (py) | **I-42 typed accountability** | PASS · 5/5 fixtures |
| **H** (py) | **I-43 state continuity + anchor privacy** | PASS · 2/2 mutants |
| **I** (py) | **I-44 canonical encoding** | PASS · 5/5 malleability mutants |
Reproducibility: `formal/REPRODUCIBILITY-LOCK.md` (tool URI + sha256 + JVM/Python/OS προφίλ).

## §8 — RESIDUALS (ενημέρωση)
- **R-w (ΝΕΟ):** τα σκέλη Unicode / duplicate-field / unknown-field / numeric του falsifier 63
  εκτελούνται στο conformance suite κάθε πραγματικού payload format (απαιτούν το schema)·
  το γενικό μοντέλο έχει ήδη αποδείξει τη μεθοδολογία και τις τέσσερις υποχρεωτικές ιδιότητες.
- **R-x (ΝΕΟ):** επιλογή continuity mechanism ανά deployment (I-43 profile) — HARDWARE_MONOTONIC_
  STATE vs CLIENT_HELD_CHAIN_RECEIPTS vs external anchor vs hybrid.
- **R-y (ΝΕΟ):** επιλογή authenticated-view δομής για production (Merkle ordered dictionary vs
  sparse/verifiable map) και το privacy προφίλ της για matter-private απαντήσεις.
- Όλα τα υπόλοιπα residuals του v0.7/v0.7.1 αμετάβλητα· R-j, R-s, R-b, R-f, R-c, R-d, R-m ΚΛΕΙΣΤΑ.

---
**Πύλη.** Το v0.7.2 κλείνει ό,τι όρισε η adjudication. Επόμενο: τελικό bounded ceiling audit του
Reviewer-B. Αν δεν προκύψει νέο counterexample που περνά και τα τέσσερα κριτήρια:
«GLOBAL ELITE CEILING — PASS» → «TARGET ARCHITECTURE v1.0 — READY FOR CREATOR FREEZE DECISION»
→ **ΜΟΝΟ ο δημιουργός: «εγκρίνω freeze target»**. ΚΑΜΙΑ PRODUCTION ΑΛΛΑΓΗ.
