# MACHINE LEGAL TRUST PROTOCOL (MLTP) v3 — ΤΡΙΑ ΕΠΙΠΕΔΑ, TYPED CLAIMS, ΠΛΗΡΗΣ ΔΕΣΜΕΥΣΗ ΥΠΟΓΡΑΦΗΣ, ΑΥΘΕΝΤΙΚΟΠΟΙΗΜΕΝΟΣ ΧΡΟΝΟΣ, DISTRIBUTED TRUST MESH
# Υποσύστημα του `CHANGE-PROPOSAL-v1.4.md §4.10` — ΟΧΙ δεύτερη αρχιτεκτονική

**Design only.** Έκδοση v3 = κλείσιμο, ΣΤΗΝ ΕΔΡΑ, των 31 ριζών (RC-01 έως RC-31)
που επιβεβαίωσε το Stage A (`V1.3-DESTRUCTION-PASS/STAGE-A-ADJUDICATION.md`) πάνω
στη v2. Η v2 είχε σωστή μακροδομή (τρία επίπεδα) αλλά το συμβόλαιο του verifier
(§8.3) δεν παρέδιδε τους invariants που το κείμενο υποσχόταν. **Καμία υλοποίηση,
κανένα destruction pass, καμία αξίωση qualification.** Κάθε πεδίο ανάγεται σε
υπάρχουσα έδρα ή σε ρητά δηλωμένο κενό (`PUBLIC-OBSERVATORY-CROSSWALK.md`).

**Σημειογραφία:** `<τύπος>` = τυπική θέση σχήματος (τι μπαίνει εκεί), όχι
εκκρεμότητα. Κάθε σχήμα εδώ είναι ΚΛΕΙΣΤΟ: άγνωστο πεδίο ⇒ `malformed-envelope`.

**Θεμελιώδης διαχωρισμός (αμετάβλητος από τη v2):**

```
Layer 0  TrustStatements       — ο OWNER ROOT υπογράφει ΜΟΝΟ: delegations, revocations,
                                 registry snapshots, ceremony record. ΠΟΤΕ claims.
Layer A  IssuedClaim           — ο ΕΚΔΟΤΗΣ (delegated key) υπογράφει έναν typed claim +
                                 proof material. ΠΟΤΕ δεν γράφει «VERIFIED». ΠΟΤΕ assurance.
Layer B  TrustBundle           — CONTAINER μεταφοράς. Δεν ισχυρίζεται τίποτα· μεταφέρει
                                 ΚΑΘΕ αντικείμενο που ο offline verifier χρειάζεται.
Layer C  VerificationReceipt   — ο ΤΟΠΙΚΟΣ verifier/auditor παράγει το ΑΠΟΤΕΛΕΣΜΑ.
                                 Δεν υπογράφεται ποτέ από τον εκδότη ως αυτο-ετυμηγορία.
```

---

## 0. ΤΙ ΑΛΛΑΖΕΙ ΑΠΟ ΤΗ v2 — ΜΙΑ ΓΡΑΜΜΗ ΑΝΑ ΡΙΖΑ STAGE A

| ρίζα | ελάττωμα v2 (μηχανικά επιβεβαιωμένο) | κλείσιμο v3 (έδρα) |
|---|---|---|
| RC-01 | signing input IssuedClaim αόριστο | §1.2: context `mltp3:issued-claim`, target = ΟΛΟΚΛΗΡΟ το envelope πλην `signature.sig` — κανένα ανυπόγραφο πεδίο |
| RC-02 | κανένας φορέας/δέσμευση delegated κλειδιού | §6 `keys[]` (JWK), `kid ≡ RFC 7638 thumbprint`, §8.3 βήμα K1 δεσμεύει κλειδί↔delegation |
| RC-03 | `issued_at` (v2 όνομα· v3: `signed_at`) issuer-written | §1.3 + §6 `time_evidence[]` (TSR DER bytes) + §8.1 `tsa_trust_anchors` + §8.3 βήμα T: ο verifier ΠΑΡΑΓΕΙ `t_sig` από genTime, imprint επί της υπογραφής |
| RC-04 | παράθυρο delegation vs `d.signed_time` | §8.3 βήμα K3: `not_before ≤ t_sig ≤ not_after` else `delegation-expired` |
| RC-05 | επιλογή delegation/seq αόριστη | §8.3 βήμα K2: μέγιστο seq ανά kid, `delegation_seq` του claim πρέπει να ισούται, ανάκληση κατά kid ΚΑΙ seq |
| RC-06 | QSR χωρίς sig_verify/registry/quorum | §3 signer = λίστα, §8.3 βήμα Q: κάθε υπογραφή ελέγχεται έναντι registry allowlist, role από registry, quorum μετρήσιμο, receipts υπογεγραμμένα |
| RC-07 | dangling ⇒ VERIFIED, receipt χωρίς level | §7 per-claim `level` + `result`· §8.3: dangling ⇒ `UNVERIFIED_FOR_MACHINE_RELIANCE` |
| RC-08 | QSR χωρίς id/subject binding | §3 `record_id`, typed `subject`, §8.3 βήμα Q2 subject == release_root/claim_id, receipts `bundle_digest` δεσμευμένο |
| RC-09 | φρεσκάδα δεν υπολογίζεται | §8.3 βήμα F: FRESH/STALE από `max_staleness` και `expiry`, `expired` εκπέμπεται |
| RC-10 | κανένα provenance βήμα | §8.3 βήμα P: κάθε released αντικείμενο απαιτεί πλήρη source-authenticity claim, αλλιώς `insufficient-provenance` |
| RC-11 | provenance ids χωρίς consumer άγκυρα | §8.1 `authority_registry_root`, `institutional_register_root`· §6 inclusion proofs registry εγγραφών· §2.1 `authority-proof/2` (κρατική προέλευση) ≠ `release-authority-proof` (owner→delegate) |
| RC-12 | 11 errors χωρίς βήμα, result εκτός sum | §4.4 πίνακας error → βήμα (πλήρης)· §7 κλειστό result sum, `reason` = error |
| RC-13 | UNDEC ⇒ VERIFIED | §8.3 βήμα S: UNDEC ⇒ `UNKNOWN(undecided-legal-state)` |
| RC-14 | self-verdict πεδίο αγνοείται | §8.3 βήμα 0: κλειστό schema, `malformed-envelope` |
| RC-15 | PCL §5 pinned-key μοντέλο ενεργό | §4.5 versioned precedence MLTP v3 §8 επί PCL §4-5 (η PCL-2 delegation-aware επέκταση = βήμα 6 υλοποίησης) |
| RC-16 | «SHA-256 μόνο» περιγραφέας | `PUBLIC-OBSERVATORY-CROSSWALK.md` γραμμή verifier = EXTEND (inclusion SHA-256 + signatures Ed25519/RS256) |
| RC-17 | inclusion ≠ release_root, root χωρίς υπογραφή | §8.3 βήμα R: `proof.merkle_root == release_root`, υπογραφή release_root (context `mltp3:release-root`), tlog inclusion του release_root |
| RC-18 | `profile` ≠ `claim_type` | §1.1: `schema_id` ΠΑΡΑΓΩΓΟ του `claim_type` (ο verifier το ξαναϋπολογίζει)· πεδίο `profile` ΑΦΑΙΡΕΘΗΚΕ |
| RC-19 | ανάκληση: αντίφαση εξουσίας, ανυπόγραφα records | §2.9 + §9: RevocationStatement υπογεγραμμένο ΜΟΝΟ από owner root (Layer 0), προτεραιότητα = αυστηρότερο `invalid_from`, subject-εξουσία |
| RC-20 | reviewer adoption αυτο-υπογράψιμο | §8.1 `reviewer_registry`, §8.3 βήμα J: adoption act ελέγχεται έναντι registered reviewer ∉ issuer keys, `unadopted-analysis` |
| RC-21 | `issuer` ελεύθερο, `auth1:` σύγκρουση | §1.0: `issuer` ΑΦΑΙΡΕΘΗΚΕ· ταυτότητα εκδότη = `issuer_name` ΜΕΣΑ στη root-signed delegation |
| RC-22 | ελεύθερο `description` | §1.0: ΑΦΑΙΡΕΘΗΚΕ από κάθε υπογεγραμμένο αντικείμενο· ανθρώπινο κείμενο ΜΟΝΟ ως typed, passage-anchored, reviewer-adopted πεδίο (§2.6) |
| RC-23 | cockpit intent σε untyped envelope | `CHANGE-PROPOSAL-v1.4.md §1.4` PUBLIC InstitutionalAct profile (κλειστό σύνολο πεδίων) |
| RC-24 | καμία μονοτονία/ηλικία checkpoint | §8.3 βήμα L: `tree_size` μονότονο, revocation checkpoint ≤ `max_revocation_staleness` |
| RC-25 | δύο μηχανισμοί rotation | §9.3: rotation = νέα root delegation (seq+1)· continuity statement = πληροφοριακό lineage, ΠΟΤΕ αυθεντία· versioned precedence επί KEY-LIFECYCLE §2.4 |
| RC-26 | crypto χωρίς παραμέτρους | §4.1: ΜΙΑ fingerprint συνάρτηση (RFC 7638), RSA floor 3072 (era-1 μόνο), Ed25519 = RFC 8032 strict, `alg` ≡ τύπος κλειδιού |
| RC-27 | proof_material για 3/8 profiles | §2: `proof_material` ΟΡΙΣΜΕΝΟ και για τα 8 profiles |
| RC-28 | two-channel ταυτότητα ασαφής | §2.5: `derived_from_expression` για anonymized κείμενο· invariant δύο καναλιών = ίδιο `work_id` (Q13 γ διορθωμένο) |
| RC-29 | καμία γέφυρα bytes↔νομικό αντικείμενο | §2.1/§2.2/§2.5: `manifestation_id` (lsm1) + `acquisition_receipt_id` + `extraction_receipt_id` σε κάθε profile που αφορά κείμενο |
| RC-30 | provider-adoption αυτο-εκδόσιμο | §8.1 `provider_registry`, §8.3 βήμα Q4 provider attestations υπογεγραμμένες από registered providers |
| RC-31 | witnesses ≠ μη-equivocation | §10: τρεις τάξεις (publication witnesses / cross-client witnesses / auditors)· split-view αξίωση ΜΟΝΟ με cross-client witness quorum· first-time consumer ⇒ `UNKNOWN(split-view-unverifiable)` |
| CL-1 | διευκρίνιση δημιουργού 2026-09-01: δημόσιος νομικός χρόνος ≠ εσωτερικός χρόνος ελέγχου | §2.0: `legal-timeline/1` στο payload (περιγράφει τον νόμο) vs `audit-timeline/1` στο proof/audit layer (λογοδοσία)· ο χρόνος γνώσης ΠΟΤΕ δεν κρίνει νομική ισχύ· το envelope πεδίο χρόνου υπογραφής μετονομάζεται `issued_at` → `signed_at` (μία σημασία ανά όνομα) |
| CL-2 | διευκρίνιση δημιουργού 2026-09-01: citation-bound verification | §2.10: `CertifiedResult` με typed `citation/1` **μέσα** στην υπογραφή· αφαίρεση/αλλοίωση ⇒ `citation-unbound` ⇒ `UNVERIFIED_FOR_ATTRIBUTED_RELIANCE`· διπλή παραπομπή (de jure εκδότης + Watchtower ως πηγή της επαληθευμένης αναπαράστασης) |

---

## 1. LAYER A — `IssuedClaim`

### 1.0 Envelope — ΚΛΕΙΣΤΟ σύνολο πεδίων, ΟΛΑ υπογεγραμμένα

```
{ "mltp": "3",
  "layer": "IssuedClaim",
  "claim_id": <"clm1:" + canonical-hash(envelope χωρίς signature)>,
  "claim_type": <ΚΛΕΙΣΤΟ sum — §1.1· ΠΟΤΕ ελεύθερο string>,
  "schema_id": <ΠΑΡΑΓΩΓΟ: "mltp3/" + claim_type + "/1" — ο verifier το ξαναϋπολογίζει>,
  "payload": <TYPED κατά schema_id — §2>,
  "proof_material": <TYPED κατά schema_id — §2, ΥΠΟΧΡΕΩΤΙΚΟ και στα 8 profiles>,
  "release_ref": { "release_root": "sha256:<hex>", "release_generation": {"era": 2, "seq": <int>} },
  "signature": { "alg": <"Ed25519" | "RS256">,
                 "kid": <RFC 7638 JWK thumbprint του delegated κλειδιού — §4.1>,
                 "delegation_seq": <int — το seq της delegation που εξουσιοδοτεί το kid>,
                 "sig": <base64url — §1.2 signing input> },
  "signed_at": { "trusted_time": <legal-instant>,
                 "anchor": { "kind": <"rfc3161" | "witnessed-checkpoint">,
                             "evidence_ref": <id εγγραφής στο TrustBundle.time_evidence — §6> } },
  "qualification_state_ref": <"qsr1:" record_id — §3> }
```

**Ρητοί κανόνες:**
- **ΚΑΝΕΝΑ `verification_result` σε IssuedClaim** — το αποτέλεσμα ζει στο Layer C.
- **ΚΑΝΕΝΑ `assurance_level` inline** — μόνο `qualification_state_ref`.
- **ΚΑΝΕΝΑ ελεύθερο κείμενο** — τα πεδία `description` και `issuer` της v2
  **αφαιρέθηκαν**. Ανθρώπινο κείμενο είναι ΠΟΤΕ input επαλήθευσης, και επομένως
  ΠΟΤΕ δεν ζει μέσα σε υπογεγραμμένο IssuedClaim (RC-22). Η ταυτότητα του εκδότη
  δεν είναι πεδίο του claim: είναι το `issuer_name` της root-signed delegation
  (§2.9) που εξουσιοδοτεί το `signature.kid` (RC-21). Καμία σύγκρουση με το
  `auth1:` namespace του USC §2.2 — αυτό ονομάζει ΜΟΝΟ κρατικές/θεσμικές αρχές.
- **`signed_at` = trusted signature-time anchor** (RFC-3161 TSR ή witnessed
  checkpoint), **ΟΧΙ** self-declared timestamp. (Στη v2 το πεδίο λεγόταν `issued_at`·
  μετονομάστηκε γιατί `issued_at` είναι πλέον πεδίο του **νομικού** χρονολογίου §2.0 —
  η ημερομηνία έκδοσης της πράξης — και ένα όνομα έχει μία σημασία.) Είναι
  **εσωτερικός χρόνος ελέγχου** (§2.0): δεν εμφανίζεται ποτέ ως χρόνος του νόμου. Ο verifier **δεν διαβάζει** το
  `trusted_time`· το **ξαναπαράγει** από το evidence (§8.3 βήμα T) και απαιτεί
  ισότητα. Χωρίς επαληθεύσιμο evidence ⇒ `UNKNOWN(no-trusted-signature-time)`.
- **Temporal fields ΜΟΝΟ όπου ισχύουν** (§2 ανά profile), όχι στο envelope.
- **`release_ref` σε κάθε claim**: κάθε claim δηλώνει σε ποιο release_root ανήκει·
  ο verifier απαιτεί `proof_material` inclusion **σε αυτό** το root (RC-17).

### 1.1 `claim_type` — ΚΛΕΙΣΤΟ sum (8 profiles, semantic completeness)

```
source-authenticity | legal-state | temporal-projection |
coverage-and-freshness | judgment-identity-and-text |
jurisprudential-analysis | legal-object-correction-or-withdrawal |
normative-impact-projection
```

- **`schema_id` δεν είναι ανεξάρτητο πεδίο επιλογής**: `schema_id :=
  "mltp3/" ‖ claim_type ‖ "/1"`. Ο verifier το ξαναϋπολογίζει από το `claim_type`
  και απορρίπτει διαφορά (`malformed-envelope`). Ένα μόνο πεδίο ορίζει τύπο,
  scope και schema (RC-18).
- Η ανάκληση κλειδιού/εξουσιοδότησης **δεν είναι πλέον claim_type**: είναι
  Layer-0 `RevocationStatement` υπογεγραμμένο από τον owner root (§2.9, RC-19).
  Η διάκριση «διόρθωση νομικού αντικειμένου» (§2.7) vs «ανάκληση κλειδιού» (§2.9)
  διατηρείται — διαφορετικά αντικείμενα, διαφορετικοί υπογράφοντες.
- Επέκταση = **νέο profile με typed payload + spec έγκριση**, ποτέ ελεύθερο string.

### 1.2 Signing input — ΠΛΗΡΗΣ ΔΕΣΜΕΥΣΗ (RC-01)

```
signed_fields(c) := canonical_bytes( c με signature.sig αφαιρεμένο )
sig := SIGN(kid, "mltp3:issued-claim" ‖ 0x1F ‖ signed_fields(c))
```

- Το `signed_fields` περιλαμβάνει ΚΑΘΕ πεδίο του envelope: `claim_id`,
  `claim_type`, `schema_id`, `payload`, `proof_material`, `release_ref`,
  `signature.alg/kid/delegation_seq`, `signed_at`, `qualification_state_ref`.
  Δεν υπάρχει ανυπόγραφο πεδίο — άρα κανένας re-packager δεν μπορεί να αλλάξει
  `signed_at`, `qualification_state_ref` ή `claim_type` χωρίς ακύρωση της υπογραφής.
- Canonical encoding: `deployment/verify/canonical-serialization-spec.md` (JCS-class,
  sorted keys, NFC, LF, χωρίς floats, `0x1F` διαχωριστικό συνθέσεων).
- Ο verifier **ξαναχτίζει** το ίδιο `signed_fields` και επαληθεύει (§8.3 βήμα K4).

### 1.3 Χρόνος υπογραφής — τι αποδεικνύει το anchor (RC-03)

- **RFC-3161:** το `messageImprint` του TSR = `SHA-256(signature.sig)` — δηλαδή
  χρονοσφραγίζεται **η υπογραφή**, όχι το payload. Έτσι το genTime αποδεικνύει
  «η υπογραφή υπήρχε τη στιγμή Τ», που είναι ακριβώς ό,τι απαιτεί η αναδρομική
  ανάκληση §9. Το TSR (DER) ΚΑΙ η αλυσίδα της TSA βρίσκονται στο
  `TrustBundle.time_evidence[]`· οι έμπιστες TSA ρίζες στο
  `LocalTrustState.tsa_trust_anchors`.
- **Witnessed checkpoint:** εναλλακτικά, `SHA-256(signature.sig)` περιλαμβάνεται
  ως φύλλο στο tlog και ένα checkpoint υπογεγραμμένο από ≥2 registered
  cross-client witnesses (§10) φέρει χρόνο. Τότε `t_sig` = ο χρόνος του
  checkpoint (άνω φράγμα: η υπογραφή υπήρχε το αργότερο τότε).
- `tlog_leaf_index` **μόνο του** ΔΕΝ είναι anchor (δίνει σειρά, όχι χρόνο) —
  αφαιρέθηκε ως αυτόνομη επιλογή.

---

## 2. TYPED PAYLOADS ΑΝΑ PROFILE — `proof_material` ΥΠΟΧΡΕΩΤΙΚΟ ΠΑΝΤΟΥ (RC-27)

Στήλη «temporal»: ✔ = φέρει `(valid_time, known_time)`· ✘ = **δεν** φέρει (δικά
του πεδία χρόνου). Κάθε profile ονομάζει ρητά ΤΙ επαληθεύει το `proof_material`
του στο βήμα R του §8.3.

### 2.0 ΔΥΟ ΧΡΟΝΟΛΟΓΙΑ, ΠΟΤΕ ΣΥΓΧΕΟΜΕΝΑ — νομικός χρόνος (payload) vs χρόνος ελέγχου (proof/audit) (CL-1)

```
lawmax/legal-timeline/1  — ΠΕΡΙΓΡΑΦΕΙ ΤΟΝ ΝΟΜΟ· ζει ΜΟΝΟ στο payload· είναι το δημόσιο και AI-facing χρονολόγιο
  { "issued_at":      <legal-date — έκδοση της πράξης/απόφασης από τη de jure αρχή>,
    "published_at":   <legal-date — δημοσίευση (ΦΕΚ/επίσημο κανάλι)> | null,
    "effective_from": <legal-date — έναρξη ισχύος> | null,
    "effective_to":   <legal-date — λήξη ισχύος> | null,
    "ceased_by":      <lsw1 work_id | rel1 relation_id — η πράξη/απόφαση που έπαυσε την ισχύ> | null,
    "cessation_type": <ΚΛΕΙΣΤΟ: "repeal" | "sunset" | "replacement" | "suspension" | "annulment" | "transition"> | null }
  Κανόνας: ceased_by ≠ null ⇔ cessation_type ≠ null· effective_to ≠ null ⇒ cessation_type ≠ null εκτός "sunset"
  με δηλωμένη ημερομηνία. Επέκταση του sum = νέα έκδοση registry, ποτέ ελεύθερο string.

lawmax/audit-timeline/1  — ΛΟΓΟΔΟΣΙΑ ΤΟΥ ΙΔΡΥΜΑΤΟΣ· ζει ΜΟΝΟ στο proof_material / audit layer· ΠΟΤΕ στο payload
  { "acquired_at":  <legal-instant — πότε το Ίδρυμα απέκτησε τα bytes>,
    "verified_at":  <legal-instant — πότε η proposer-blind M5 επαλήθευσε>,
    "released_at":  <legal-instant — πότε μπήκε σε release_root>,
    "corrected_at": <legal-instant> | null,
    "revoked_at":   <legal-instant> | null }
```
- **Ο χρόνος γνώσης/απόκτησης ΠΟΤΕ δεν κρίνει νομική ισχύ** και ΠΟΤΕ δεν παρουσιάζεται
  ως μέρος του νομικού κανόνα. Υπάρχει για λογοδοσία, ανίχνευση καθυστερημένης πηγής,
  μέτρηση φρεσκάδας, ανακατασκευή ιστορικής απάντησης, διόρθωση, διερεύνηση συμβάντων.
- **Η διτεμπορικότητα διατηρείται εσωτερικά** (`valid_time × known_time` στον γράφο,
  v1.4 §4.5)· το `known_time` ενός payload είναι η **τομή γνώσης του release**
  (ποιο release απαντά), όχι «πότε το μάθαμε» ανά αντικείμενο.
- **Ο verifier** χρησιμοποιεί το audit-timeline ΜΟΝΟ για freshness (§8.3 F), ανάκληση
  (V), προέλευση (P) — ποτέ για το βήμα S (νομική κατάσταση). Ανθρώπινες και συνήθεις
  AI απαντήσεις δεν χρειάζεται να το εμφανίζουν· η πλήρης χρονική λογοδοσία είναι
  διαθέσιμη στο audit endpoint (v1.4 §4.7).
- Κάθε profile που αφορά νομικό αντικείμενο φέρει `legal_timeline` στο payload και
  κάθε `proof_material` φέρει `audit_timeline`.

### 2.1 `source-authenticity` · temporal: ✘ — Η ΓΕΦΥΡΑ BYTES ↔ ΝΟΜΙΚΟ ΑΝΤΙΚΕΙΜΕΝΟ (RC-29, RC-11)
```
payload = { "raw_artifact": {"digest_algorithm": "sha256", "digest": "<hex>", "byte_length": <int>},
            "manifestation_id": "lsm1:<hash>",                 # USC §1.3 — ΥΠΟΧΡΕΩΤΙΚΟ
            "expression_id": "lse1:<hash>",                    # USC §1.2
            "work_id": "lsw1:<hash>",                          # USC §1.1
            "acquisition_receipt_id": "acq1:<hash>",           # USC §5.1 (origin sum)
            "extraction_receipt_id": "xrc2:<hash>",            # USC §5.3 extraction-receipt/2
            "authority_id": "auth1:<hash>",                    # USC §2.2 — ΤΟ ΚΡΑΤΙΚΟ/ΘΕΣΜΙΚΟ όργανο
            "institutional_register_id": "ireg1:<hash>",       # USC §2.1β
            "authority_proof_ref": "aprf2:<hash>",             # §2.1α authority-proof/2 (κρατική προέλευση)
            "custody_chain_ref": "cust1:<hash>",               # §2.1β custody chain
            "time_anchor": { "kind": "rfc3161", "evidence_ref": <id στο time_evidence> },
            "divergence_ref": <"unc1:<hash>" official-sources-conflict | null> }
proof_material = { "acquisition_receipt": <πλήρες acquisition-receipt/1 αντικείμενο>,
                   "extraction_receipt": <πλήρες extraction-receipt/2 αντικείμενο>,
                   "authority_proof": <πλήρες authority-proof/2 αντικείμενο — §2.1α>,
                   "custody_chain": <λίστα custody events, καθένα με actor-ref + χρόνο + digest>,
                   "registry_inclusion": { "authority_record": <inclusion proof του auth1 record
                                                                 στο authority_registry_root>,
                                           "register_record": <inclusion proof του ireg1 record
                                                                 στο institutional_register_root> },
                   "audit_timeline": <lawmax/audit-timeline/1 — §2.0 (acquired_at ζει ΕΔΩ, όχι στο payload)>,
                   "release_inclusion": <PCL path του canonical claim leaf ≤64 στο release_root> }
```
**Κανόνας (RC-10):** RFC-3161 μόνο ⇒ ΑΝΕΠΑΡΚΕΣ. Ο local verifier απαιτεί ΚΑΙ τα
τέσσερα: `authority_id`, `institutional_register_id`, `authority_proof_ref`,
`acquisition_receipt_id` — μη-null ΚΑΙ επιλύσιμα μέσα στο bundle ΚΑΙ (για τα δύο
registry ids) με inclusion proof σε registry root που ο καταναλωτής έχει pinned
(§8.1). Οποιοδήποτε λείπει ⇒ `insufficient-provenance`.

#### 2.1α `authority-proof/2` — απόδειξη ΚΡΑΤΙΚΗΣ προέλευσης (νέα έδρα, διακριτή από την `authority-proof-bundle/1`)

Η υπάρχουσα `lawmax/authority-proof-bundle/1` (`source/authority-evidence-replay.lisp`,
required keys: `delegation-scope`, `authority-statement-jws`, `tra`, `census`,
`release-manifest`) αποδεικνύει την **εξουσία του Watchtower επί του δικού του
γράφου** (owner → delegate). Στη v3 ονομάζεται ρητά **`release-authority-proof`**
και ζει στο `TrustBundle.release_anchor` (§6). ΔΕΝ αποδεικνύει κρατική έκδοση.

Η κρατική προέλευση αποδεικνύεται από το **`authority-proof/2`** — τυπωμένο
evidence με **βαθμό ισχύος** (ο verifier τον εκθέτει στο receipt, δεν τον κρύβει):

```
authority-proof/2 = { "id": "aprf2:<hash>",
  "manifestation_id": "lsm1:<hash>",
  "channel": <"official-host-tls" | "official-signed-artifact" | "official-register-entry" |
              "manual-deposit-attested" | "archive-import">,
  "strength": <"S3-signed-by-authority" | "S2-official-channel-attested" |
               "S1-register-entry-only" | "S0-declared-only">,
  "evidence": { "tls_chain_at_acquisition": <λίστα DER certs> | null,
                "official_signature": { "format": <"PAdES" | "XAdES" | "CAdES">,
                                        "signer_cert": <DER>, "verified_against": <trust-list ref> } | null,
                "register_entry": { "register_id": "ireg1:<hash>", "entry_key": <string>,
                                    "entry_digest": "<hex>", "observed_at": <legal-instant> } | null,
                "depositor": <actor-ref/1 USC §2.4> | null },
  "recorded_at": <legal-instant> }
```
- `S0-declared-only` ⇒ ο verifier επιστρέφει `insufficient-provenance` (δεν είναι
  απόδειξη). `S1` ⇒ επιτρεπτό μόνο για αντικείμενα που το register δεν εκδίδει
  υπογεγραμμένα· το receipt εκθέτει `provenance_strength: S1`. Ο καταναλωτής
  αποφασίζει με βάση τον βαθμό — ποτέ σιωπηλή εξίσωση S1 με S3.
- **Τίμιο όριο:** το Watchtower αποδεικνύει ΔΕΣΙΜΟ σε επίσημο κανάλι/μητρώο/υπογραφή·
  δεν αποδεικνύει ότι η πηγή λέει αλήθεια (THREAT-MODEL §4).

#### 2.1β custody chain
Κάθε μεταβίβαση των bytes (fetch → vault → extraction) = γεγονός `{actor, at, digest_in,
digest_out, tool_manifest_sha256}`. Το vault (M2) είναι append-only· η αλυσίδα
ξεκινά από τον acquirer και τελειώνει στο `raw_artifact.digest`.

### 2.2 `legal-state` · temporal: ✔
```
payload = { "work_id": "lsw1:<hash>", "expression_id": "lse1:<hash>",
            "manifestation_ids": [ "lsm1:<hash>" ],            # τα items από τα οποία παράχθηκε η expression
            "valid_time": <legal-date | {"from": <legal-date>, "to": <legal-date>}>,
            "known_time": <legal-instant>,
            "legal_state": <"IN" | "OUT" | "UNDEC">,            # UNDEC ⇒ verifier: UNKNOWN(undecided-legal-state) — §8.3 βήμα S
            "legal_timeline": <lawmax/legal-timeline/1 — §2.0: issued_at, published_at, effective_from, effective_to, ceased_by, cessation_type>,
            "attestation_id": "lsa1:<hash>",                   # USC §1.2γ
            "knowledge_checkpoint_id": "kchk1:<hash>" }         # USC §1.2β
proof_material = { "release_inclusion": <PCL path ≤64 στο release_root>,
                   "receipt": <LegalAuthorityReceipt — TEMPORAL-IDENTITY §1.5, με πλήρη amendment-genealogy>,
                   "audit_timeline": <lawmax/audit-timeline/1 — §2.0>,
                   "uncertainty_roots": { "open": "<hex>", "resolved": "<hex>" } }
```
Το βήμα R επαληθεύει: receipt-id recompute → merkle path → release_root· η
genealogy επαναπαίζεται ακμή-προς-ακμή (§8.3 R3) — τίποτε «κατά δήλωση».

### 2.3 `temporal-projection` · temporal: ✔
```
payload = { "body": <"gr/<σώμα>">, "valid_time": <legal-date>, "known_time": <legal-instant>,
            "projection_root": "sha256:<hex>",                 # ρίζα της προβολής στην τομή
            "release_root": "sha256:<hex>" }                   # §5 ΜΟΝΗ authority root — ίση με release_ref
proof_material = { "snapshot_manifest": <version-graph snapshot-at + per-step fold>,
                   "census_temporal": { "graph_root": "<hex>", "receipt_set_root": "<hex>",
                                        "valid_at": <legal-date>, "known_at": <legal-instant> },
                   "audit_timeline": <lawmax/audit-timeline/1 — §2.0>,
                   "release_inclusion": <PCL path ≤64> }
```

### 2.4 `coverage-and-freshness` · temporal: ✔ (known_time = «ως πότε ξέρω») — ΑΠΟΓΡΑΦΗ ΩΣ ΟΛΙΚΗ ΣΥΝΑΡΤΗΣΗ
```
payload = { "space": <census-space id, π.χ. "gr/gazette/A" | "gr/court/areios-pagos">,
            "known_time": <legal-instant>,
            "coverage_ledger_root": "sha256:<hex>",           # RFC 9162 MTH όλων των θέσεων του χώρου
            "position_count": <int>,                           # πλήθος θέσεων = |δηλωμένο universe|
            "state_counts": { "INGESTED": <int>, "EXPLICITLY-ABSENT": <int>,
                              "QUARANTINED": <int>, "UNKNOWN": <int> },   # άθροισμα == position_count
            "freshness": { "as_of": <legal-instant>, "max_staleness": <duration> },
            "gaps": [ { "position": <census position key>, "state": "UNKNOWN",
                        "gap_reason": <ΚΛΕΙΣΤΟ: "not-yet-published" | "fetch-failed" | "quarantined" |
                                       "legally-unavailable" | "unpublished-by-source">,
                        "first_observed_at": <legal-instant>,
                        "retry_state": { "attempts": <int>, "next_at": <legal-instant> | null,
                                         "escalated": <bool> } } ] }
proof_material = { "ledger_inclusion": [ <inclusion proof ανά θέση που παρατίθεται στο gaps> ],
                   "universe_declaration_ref": "cens1:<hash>",   # η δηλωμένη απογραφή (§4.1 v1.4) — root-signed registry snapshot
                   "audit_timeline": <lawmax/audit-timeline/1 — §2.0>,
                   "release_inclusion": <PCL path ≤64> }
```
**Κανόνας:** «τα πάντα» λέγεται ΜΟΝΟ έναντι δηλωμένου `universe_declaration_ref`.
Θέση χωρίς κατάσταση ⇒ ο verifier απορρίπτει (`coverage-not-total`).

### 2.5 `judgment-identity-and-text` · temporal: ✔ — SOURCE-VERIFIABLE (νομολογία #7α)
```
payload = { "work_id": "lsw1:<hash>",                        # judgment domain (USC §1.4)
            "expression_id": "lse1:<hash>",
            "manifestation_id": "lsm1:<hash>",
            "content_sha256": "<hex>",                       # του §2-normalized κειμένου της expression
            "ecli": <string> | null, "provisional_id": <"prov1:" + canonical-hash(official_key) — USC §1.4 key> ,
            "court": "auth1:<hash>", "chamber": <string> | null, "formation": <string> | null,
            "jurisdiction_level": <ΚΛΕΙΣΤΟ registry>,
            "number": <int>, "year": <int>,
            "legal_timeline": <lawmax/legal-timeline/1 — issued_at = ημερομηνία έκδοσης της απόφασης, published_at = δημοσίευση· effective/cessation μόνο για αποφάσεις με erga-omnes ισχύ>,
            "anonymization": { "status": <"none" | "partial" | "full">,
                               "provenance": <"source" | "watchtower">,
                               "derived_from_expression": "lse1:<hash>" | null },   # RC-28
            "procedural_history_ref": "pref1:<hash>" | null,
            "valid_time": <legal-date>, "known_time": <legal-instant> }
proof_material = { "source_seal": { "acquisition_receipt": <acquisition-receipt/1>,
                                    "extraction_receipt": <extraction-receipt/2>,
                                    "bytes_inclusion": <PCL path των raw bytes leaf> },
                   "audit_timeline": <lawmax/audit-timeline/1 — §2.0>,
                   "release_inclusion": <PCL path ≤64> }
```
**Μόνο ό,τι επαληθεύεται από την πηγή.** Καμία ερμηνεία εδώ.
**Ταυτότητα δύο καναλιών (RC-28):** ίδια απόφαση από δύο κανάλια ⇒ **ίδιο `work_id`**
(ο invariant). Αν το κείμενο διαφέρει (π.χ. ανωνυμοποιημένη vs πλήρης έκδοση) ⇒
**διακριτές expressions** του ΙΔΙΟΥ work, με `anonymization.derived_from_expression`
να δένει τη μία στην άλλη. Το `provisional_id` είναι ντετερμινιστικό: hash του
official key (μητρώο, αριθμός, έτος, σειρά) — ποτέ των bytes.

### 2.6 `jurisprudential-analysis` · temporal: ✔ — INSTITUTIONAL ATTESTATION (νομολογία #7β)
```
payload = { "judgment_ref": "lsw1:<hash>",                     # §2.5 work_id
            "expression_ref": "lse1:<hash>",
            "ratio":   [ { "text": <string>, "passage_anchor": {"artifact_digest": "<hex>", "start": <int>, "end": <int>} } ],
            "obiter":  [ { "text": <string>, "passage_anchor": {"artifact_digest": "<hex>", "start": <int>, "end": <int>} } ],
            "holding": { "text": <string>, "state": <"IN" | "OUT" | "UNDEC">, "passage_anchor": {"artifact_digest": "<hex>", "start": <int>, "end": <int>} },
            "legal_issue": { "text": <string>, "passage_anchor": {"artifact_digest": "<hex>", "start": <int>, "end": <int>} },
            "disposition": <ΚΛΕΙΣΤΟ registry: "granted" | "dismissed" | "annulled" | "remanded" | "partly-granted">,
            "separate_opinions": [ { "kind": <"dissent" | "concurrence">, "passage_anchor": {"artifact_digest": "<hex>", "start": <int>, "end": <int>} } ],
            "authority_level": <ΚΛΕΙΣΤΟ registry: "plenary" | "chamber" | "single-judge">,
            "authority_weight": { "value": <int>, "basis": <ΚΛΕΙΣΤΟ: "plenary-over-chamber" | "line-count" | "line-consistency"> },
            "later_treatment": [ { "relation": <USC §6.3 kind ∪ {"followed","applied","distinguished","doubted","limited","overruled","annulled"}>,
                                   "target": "lsw1:<hash>", "relation_id": "rel1:<hash>" } ],
            "attribution": <actor-ref/1 του θεσμικού συντάκτη — PLANE-2>,
            "methodology_version": <pinned registry id>,
            "reviewer_adoption_act": { "act_id": "adopt1:<hash>", "reviewer_kid": <RFC 7638 thumbprint>,
                                       "adopted_digest": "<hex — canonical-hash του payload χωρίς το act>",
                                       "adopted_at": { "trusted_time": <legal-instant>, "anchor": {"kind": "rfc3161", "evidence_ref": <id>} },
                                       "sig": <base64url — context "mltp3:reviewer-adoption"> },
            "typed_uncertainty": [ <lawmax/uncertainty/1 — USC §8> ],
            "valid_time": <legal-date>, "known_time": <legal-instant> }
proof_material = { "passage_inclusion": [ <inclusion proof του artifact_digest στο release_root ανά anchor> ],
                   "adoption_inclusion": <inclusion proof του act_id στο tlog>,
                   "relation_evidence": [ <USC §6.3 relation records με endpoint pins> ],
                   "audit_timeline": <lawmax/audit-timeline/1 — §2.0>,
                   "release_inclusion": <PCL path ≤64> }
```
**Δομικοί κανόνες:** κάθε ratio/holding **αγκυρωμένο σε passage_anchor** (`PLANE-0`)·
**attribution + methodology_version + reviewer_adoption_act ΥΠΟΧΡΕΩΤΙΚΑ**· **raw AI
inference (`PLANE-3`) ΠΟΤΕ ως θεσμικά πιστοποιημένο ratio** (μπορεί μόνο ως
`typed_uncertainty` πρόταση προς reviewer). Ο `reviewer_kid` πρέπει να ανήκει στο
`LocalTrustState.reviewer_registry` ΚΑΙ να μην ανήκει σε κανένα issuer key
(delegation_chain ∪ owner root) — αλλιώς `unadopted-analysis` ⇒
`UNVERIFIED_FOR_MACHINE_RELIANCE` (RC-20). Το `text` των ratio/holding είναι
θεσμικό δημόσιο κείμενο (PLANE-2), υπογεγραμμένο από reviewer — όχι ελεύθερο
σχόλιο εκδότη.

### 2.7 `legal-object-correction-or-withdrawal` · temporal: ✔ (νομικό αντικείμενο)
```
payload = { "subject": { "kind": <"work" | "expression" | "manifestation">, "id": <lsw1 | lse1 | lsm1> },
            "transition": <"SUPERSEDED" | "WITHDRAWN" | "CORRECTION">,
            "authority_id": "auth1:<hash>",                    # ποια αρχή θεμελιώνει τη μετάβαση (π.χ. διόρθωση ΦΕΚ)
            "legal_timeline": <lawmax/legal-timeline/1 — η ισχύς της διορθωτικής/καταργητικής πράξης>,
            "effective_valid_time": <legal-date>, "known_time": <legal-instant>,
            "supersedes": <id> | null, "superseded_by": <id> | null,
            "uncertainty_resolution_ref": "unc1:<hash>" | null,
            "relation_retract_ref": "rel1:<hash>" | null }
proof_material = { "journal_inclusion": <inclusion proof του journaled μεταβατικού γεγονότος στο graph_root>,
                   "authority_evidence": <authority-proof/2 της διορθωτικής πράξης> | null,
                   "audit_timeline": <lawmax/audit-timeline/1 — corrected_at/revoked_at ζουν ΕΔΩ>,
                   "release_inclusion": <PCL path ≤64> }
```
**Καμία διαγραφή**· ανακληθέν ορατό στη διτεμπορική του τομή.

### 2.8 `normative-impact-projection` · temporal: ✔ — ΔΗΜΟΣΙΟ L7 (v1.4 §4.8)
```
payload = { "trigger_event_ref": <event id του bitemporal graph>,
            "valid_time": <legal-date>, "known_time": <legal-instant>,
            "affected": { "provisions": [ <provision-id> ], "delegated_acts": [ "lsw1:<hash>" ],
                          "broken_references": [ "rel1:<hash>" ], "consolidated_texts": [ "lse1:<hash>" ],
                          "eu_transpositions": [ "rel1:<hash>" ], "jurisprudential_lines": [ "line1:<hash>" ] },
            "impact_root": "sha256:<hex>",                     # MTH της λίστας affected (ντετερμινιστική σειρά)
            "method_version": <pinned registry id> }
proof_material = { "replay_manifest": <ο ντετερμινιστικός υπολογισμός: είσοδοι (graph_root, event), βήματα, έξοδος>,
                   "dependency_proofs": [ <inclusion proof κάθε affected στοιχείου στο graph_root> ],
                   "audit_timeline": <lawmax/audit-timeline/1 — §2.0>,
                   "release_inclusion": <PCL path ≤64> }
```
**Κανόνας:** η προβολή είναι **επαναπαίξιμη** (ο auditor ξανατρέχει το
`replay_manifest` και συγκρίνει `impact_root`)· δεν είναι γνώμη. Καμία πρόβλεψη
έκβασης υπόθεσης — ο τύπος δεν έχει πεδίο για αυτό (v1.4 §1.3).

### 2.9 LAYER 0 — `RevocationStatement` και οι λοιπές root-signed δηλώσεις (ΟΧΙ IssuedClaim) (RC-19)
```
DelegationStatement = { "kind": "delegation", "seq": <int>,
  "delegate_kid": <RFC 7638 thumbprint>, "issuer_name": <string — θεσμικό όνομα εκδότη>,
  "scope": [ <claim_type> ] ∪ { "release-signing" },
  "not_before": <legal-instant>, "not_after": <legal-instant>,   # ≤ 1 έτος
  "sig": { "alg", "kid": <owner root thumbprint>, "sig": <base64url — context "mltp3:delegation"> } }

RevocationStatement = { "kind": "trust-key-or-delegation-revocation",
  "revoked_subject": { "kind": <"kid" | "delegation_seq">, "value": <thumbprint | int> },
  "revocation_reason": <"superseded" | "key-compromise" | "delegation-expired" | "policy">,
  "revoked_at": <legal-instant>,
  "compromise_known_at": <legal-instant> | null,      # μόνο σε key-compromise
  "invalid_from": <legal-instant>,                    # §9 retroactivity
  "replacement_delegation_seq": <int> | null,
  "sig": { "alg", "kid": <owner root thumbprint>, "sig": <base64url — context "mltp3:revocation"> } }

RegistrySnapshot = { "kind": <"auditor-registry" | "reviewer-registry" | "provider-registry" |
                              "witness-registry" | "authority-registry" | "institutional-register" |
                              "census-universe">,
  "seq": <int>, "root": "sha256:<hex>", "entry_count": <int>, "snapshot_at": <legal-instant>,
  "sig": { "alg", "kid": <owner root thumbprint>, "sig": <base64url — context "mltp3:registry-snapshot"> } }
```
- **ΜΟΝΟ ο owner root** (ή το threshold owner root, §10.2) υπογράφει Layer 0. Ένα
  delegated κλειδί ΔΕΝ μπορεί να ανακαλέσει τίποτα — δεν υπάρχει scope που να το
  επιτρέπει (RC-19 β). Ένα RevocationStatement υπογεγραμμένο από μη-root κλειδί
  ⇒ `untrusted-key` και ΑΓΝΟΕΙΤΑΙ ως ανάκληση (όχι fail-open: η κατάσταση παραμένει
  ό,τι λένε τα root-signed statements).
- Owner-root συμβιβασμός: ανάκληση out-of-band σε ≥2 κανάλια (TRUST-BOOTSTRAP §2)
  + νέο ceremony record· ο καταναλωτής αλλάζει pinned root χειροκίνητα — καμία
  αυτόματη διαδρομή (θα ήταν το ίδιο κλειδί που εξουσιοδοτεί τον διάδοχό του).

### 2.10 CITATION-BOUND VERIFICATION PROFILE — `CertifiedResult` + `citation/1` (CL-2, v1.4 §4.16)

Κάθε **πιστοποιημένο** αποτέλεσμα API/MCP/SDK (η `proof-carrying-answer/1` του v1.4
§4.7 όταν παραδίδεται σε καταναλωτή) είναι `CertifiedResult`: υπογεγραμμένο από
delegated κλειδί με scope `certified-result`, και **περιέχει μέσα στα υπογεγραμμένα
bytes** ένα typed αντικείμενο παραπομπής.

```
lawmax/citation/1 = {
  "official_source_uri":   <URI της de jure πηγής — ΦΕΚ τεύχος/σελίδα, δικαστική απόφαση (ELI/ECLI όπου υπάρχει)>,
  "watchtower_release_uri": <canonical URI της τομής: <base>/release/<release_root>/claim/<claim_id>>,
  "claim_id":              "clm1:<hash>",
  "certificate_uri":       <URI του TrustBundle/receipt: <base>/bundle/<bundle_id>>,
  "attribution_text":      <ΠΑΡΑΓΩΓΟ από citation_policy_id — ΔΙΠΛΗ παραπομπή:
                            «<de jure εκδότης>, <πράξη/απόφαση>, <ΦΕΚ/ECLI>» ΚΑΙ
                            «Επαληθευμένη μηχανική αναπαράσταση, ενοποίηση, απόδειξη και πιστοποίηση:
                             LAWMAX OMEGA — THE LEGAL WATCHTOWER OF GREECE, release <seq>, claim <claim_id>»>,
  "citation_policy_id":    <"lawmax/citation-policy/1" — registry, versioned> }

CertifiedResult = {
  "mltp": "3", "layer": "CertifiedResult",
  "result_id": <"res1:" + canonical-hash(CertifiedResult χωρίς signature.sig)>,
  "answer": <proof-carrying-answer/1 — v1.4 §4.7>,
  "citation": <lawmax/citation/1>,
  "citation_digest": <canonical-hash(citation)>,          # δεσμεύει την παραπομπή ΚΑΙ μέσα στην απάντηση
  "release_ref": { "release_root", "release_generation" },
  "signed_at": { "trusted_time", "anchor" },               # όπως §1.0
  "signature": { "alg", "kid", "delegation_seq", "sig": <context "mltp3:certified-result"> } }

CitationToken = SIGN(kid, "mltp3:citation" ‖ 0x1F ‖ canonical_bytes(citation ‖ 0x1F ‖ result_id))
  — φορητή, υπογεγραμμένη παραπομπή (JWS compact / COSE_Sign1) για ενσωμάτωση σε HTML, JSON-LD, SDK rendering.
```
**Κανόνες:**
- Το `citation` είναι **μέσα** στα `signed_fields` του CertifiedResult **και** το
  `citation_digest` είναι μέσα στην υπογεγραμμένη απάντηση. Αφαίρεση ή αλλοίωση της
  παραπομπής ⇒ `citation-unbound` ⇒ **`UNVERIFIED_FOR_ATTRIBUTED_RELIANCE`** (§8.3 βήμα C).
  Ένας provider **δεν μπορεί** να διατηρήσει έγκυρη υπογραφή Watchtower, κατάσταση
  `VERIFIED` ή `provider-adoption-qualified` αφού αφαιρέσει τη δεσμευμένη παραπομπή.
- **Διπλή παραπομπή** υποχρεωτική: το Κράτος/ΦΕΚ/δικαστήριο ως **de jure εκδότης**·
  το `LAWMAX OMEGA — THE LEGAL WATCHTOWER OF GREECE` ως **πηγή της επαληθευμένης
  μηχανικής αναπαράστασης, ενοποίησης, απόδειξης και πιστοποίησης**. Ποτέ το
  Watchtower ως εκδότης δικαίου.
- **Τίμιο όριο:** το σύστημα δεν μπορεί να εμποδίσει φυσικά τη χρήση αντιγραμμένου
  δημόσιου κειμένου χωρίς απόδοση αφού φύγει από τον έλεγχό του. Εγγυάται ΜΟΝΟ ότι
  καμία **επαληθευμένη** αναπαράσταση δεν επιβιώνει χωρίς την παραπομπή.
- Κανονικά citation URLs (`watchtower_release_uri`, `certificate_uri`) = σταθερά ανά
  διτεμπορική τομή (Q14)· citation-ready JSON / JSON-LD προβολή (§11)· υποχρεωτικά
  πεδία στα OpenAPI/MCP/SDK σχήματα· default rendering στα επίσημα SDKs· conformance
  vectors (θετικά + stripped-citation αρνητικά)· παρακολούθηση συμμόρφωσης providers
  από το citation observatory (v1.4 §4.13)· μη-συμμόρφωση ⇒ μη-ανανέωση/ανάκληση
  `provider-adoption-qualified` και, όπου εφαρμόζεται, ενέργεια API-access.
  Εμπορικές συμφωνίες είναι εξωτερικές — όχι αρχιτεκτονική εξάρτηση.

### 2.11 TEMPORAL ONTOLOGY & VALIDATION GOVERNANCE — `ontology-bundle` + `shacl-validation-receipt` (POST-C2 Finding 3, v1.4 §4.19)

Content-addressed, immutable κύκλος ζωής οντολογίας/SHACL· η επικύρωση δένεται στην
**ακριβή** έκδοση σχημάτων ώστε ένα αντικείμενο του 2025 να μην απορρίπτεται αναδρομικά
όταν εισαχθεί bundle του 2027. **Τρεις χρονικοί άξονες διακριτοί** (ρητή εντολή): νομικός
χρόνος γεγονότος (`legal-timeline/1`) ≠ **εφαρμοσιμότητα οντολογίας** (`applicability`) ≠
θεσμικός χρόνος υιοθέτησης/ελέγχου (`audit-timeline/1`).

**Ακυκλική κατασκευή (POST-C2 correction, §4.2 κανόνας 2):** το `*_id` υπολογίζεται από
το **BODY** (όλα τα πεδία **εκτός** του ίδιου του `*_id` και του `sig`)· η υπογραφή μετά
καλύπτει BODY + id. Envelope = BODY ∪ {`*_id`}· detached/signature πεδίο = `sig`.
```
OntologyBundle:
  # BODY = { record, shapes_graph_digest, ontology_graph_digest, semver, applicability,
  #          adopted_at, published_at, approving_act, supersedes, compat }   (ΟΧΙ id, ΟΧΙ sig)
  "ontology_bundle_id": <"onto1:" + hex(sha256("mltp3:ontology-bundle-id" ‖ 0x1F ‖ canonical(BODY)))>,
  "record": "ontology-bundle", "mltp": "3",
  "shapes_graph_digest": "sha256:<hex>",       # URDNA2015 canonical N-Quads των SHACL shapes
  "ontology_graph_digest": "sha256:<hex>",
  "semver": <"MAJOR.MINOR.PATCH">,
  "applicability": { "from": <legal-instant>, "to": <legal-instant> | null },   # εφαρμοσιμότητα, ΟΧΙ νομικός χρόνος γεγονότος
  "adopted_at": { "trusted_time", "anchor" },  # θεσμικός χρόνος (audit-timeline)
  "published_at": <legal-instant>,
  "approving_act": "clm1:<hash>",              # InstitutionalAct (L8/L12)
  "supersedes": "onto1:<hash>" | null,
  "compat": <"backward" | "breaking" | "orthogonal">,   # typed migration rule, ΟΧΙ boolean
  "sig": { "alg","kid": <delegated release key>, "sig": <SIGN over (envelope minus sig), context "mltp3:ontology-bundle"> }

ShaclValidationReceipt:
  # BODY = { record, object_ref, ontology_bundle_id, shapes_graph_digest, object_legal_time,
  #          result, violations, validated_at, validator_version }   (ΟΧΙ receipt_id, ΟΧΙ sig)
  "receipt_id": <"shr1:" + hex(sha256("mltp3:shacl-receipt-id" ‖ 0x1F ‖ canonical(BODY)))>,
  "record": "shacl-validation-receipt", "mltp": "3",
  "object_ref": { "manifestation_id": "lsm1:<hash>", "artifact_digest": "sha256:<hex>" },
  "ontology_bundle_id": "onto1:<hash>", "shapes_graph_digest": "sha256:<hex>",   # ΔΕΣΜΕΥΣΗ στην ακριβή έκδοση (ξένο id, ΟΧΙ δικό του)
  "object_legal_time": <legal-instant>,        # νομικός χρόνος του αντικειμένου
  "result": <"conforms" | "violates" | "migration-required">,   # typed enum, ΟΧΙ boolean (repo law)
  "violations": [ { "shape": <iri>, "focus": <iri>, "detail_anchor": <anchor> } ],
  "validated_at": { "trusted_time", "anchor" },  # audit-timeline
  "validator_version": <string>,
  "sig": { "alg","kid": <delegated release key>, "sig": <SIGN over (envelope minus sig), context "mltp3:shacl-receipt"> }
```

**Κανόνες (fail-closed):** (α) receipt χωρίς `ontology_bundle_id` **ΚΑΙ**
`shapes_graph_digest` ⇒ `ontology-unbound`· (β) revalidation υπό νεότερο bundle παράγει
**νέο** receipt — το παλιό παραμένει έγκυρο τεκμήριο «συμμορφώθηκε στα σχήματα που ίσχυαν
στον χρόνο του»· **καμία σιωπηλή μετάλλαξη/ακύρωση ιστορικού receipt** (`ontology-evidence-
mutated`)· (γ) δύο bundles με επικαλυπτόμενη `applicability` και ασύμβατα shapes ⇒
`ontology-conflict` ⇒ `CONFLICTING` (ποτέ σιωπηλός νικητής)· (δ) rollback = νέα υιοθέτηση
προηγούμενου bundle ως **νέα** πράξη, ποτέ σιωπηλή επαναφορά. Extension error taxonomy
(διακριτή από §4.3): `ontology-unbound · ontology-evidence-mutated · ontology-conflict ·
shapes-digest-mismatch · unadopted-ontology-bundle`. Έδρες: `source/shacl-validator.lisp`
(EXTEND — δέσμευση receipt στο bundle+digest)· `deployment/shapes/*.ttl` (γίνονται
versioned bundles). **Falsifier: KW-106.**

---

## 3. `QualificationStateRecord` — assurance ΩΣ ΞΕΧΩΡΙΣΤΟ ΥΠΟΓΕΓΡΑΜΜΕΝΟ RECORD (RC-06, RC-08, RC-30)

```
{ "mltp": "3", "record": "QualificationStateRecord",
  "record_id": <"qsr1:" + hex(sha256(id_domain(qsr1) ‖ 0x1F ‖ canonical(BODY)))>,   # ακυκλικό (§4.2 κανόνας 2, §13.1): BODY = record εκτός record_id ΚΑΙ signers[].sig
  "subject": { "kind": <"release" | "claim">, "release_root": "sha256:<hex>", "claim_id": "clm1:<hash>" | null },
  "level": <"spec-qualified" | "implementation-qualified" | "mission-greece-qualified" |
            "security-operations-qualified" | "provider-adoption-qualified" | "none">,
  "evidence_refs": [ <ids τεκμηρίων — ΚΑΘΟΡΙΣΜΕΝΟ σύνολο ανά level, §3.1> ],
  "auditor_receipts": [ <VerificationReceipt με local_signature ΜΗ-null — §7> ],
  "provider_attestations": [ { "provider_kid": <thumbprint ∈ provider_registry>, "statement": <typed adoption statement>,
                               "sig": <base64url — context "mltp3:provider-attestation"> } ],   # μόνο provider-adoption
  "signed_at": { "trusted_time": <legal-instant>, "anchor": { "kind": "rfc3161", "evidence_ref": <id> } },
  "expiry": <legal-instant>,                               # καμία βαθμίδα μόνιμη (Q28)
  "signers": [ { "alg", "kid": <thumbprint ∈ auditor_registry | provider_registry>,
                 "sig": <base64url — context "mltp3:qual-state"> } ] }
```

### 3.1 Ποιος επιτρέπεται να εκδίδει κάθε level — ο ρόλος προέρχεται ΑΠΟ ΤΟ REGISTRY, όχι από το record

| level | signers (όλοι από registry του καταναλωτή) | quorum | υποχρεωτικό evidence |
|---|---|---|---|
| `spec-qualified` | independent-auditor | ≥1 | adjudication record του destruction programme + contradiction/omission audit output (`V1.4-CONTRADICTION-OMISSION-AUDIT.out`) |
| `implementation-qualified` | independent-auditor | ≥2 διακριτοί | Q01–Q42 auditor receipts, proposer-blind re-derivation, 15 vertical-slice evidence bundles |
| `mission-greece-qualified` | independent-auditor | ≥2 διακριτοί | MISSION GREECE-1 receipts (Μ-1 έως Μ-6) + ανεξάρτητη απογραφή πηγών |
| `security-operations-qualified` | independent-auditor | ≥2 διακριτοί | SLO receipts, supply-chain provenance verification, disaster-replay receipt (Q19), split-view drill |
| `provider-adoption-qualified` | provider-registry members | ≥2 διακριτοί providers | provider attestations (όχι δικές μας) |
| `none` | — | — | — |

- **Ο release issuer ΔΕΝ μπορεί να υπογράψει QualificationStateRecord για τον
  εαυτό του — δομικά:** τα registries του καταναλωτή (auditor/provider) πρέπει να
  είναι **ξένα** προς το σύνολο issuer keys = {owner root} ∪ {κάθε `delegate_kid`
  στο `delegation_chain`}. Ο verifier ελέγχει τη διαζευξιμότητα (§8.3 βήμα Q1)·
  τομή ≠ ∅ ⇒ `unauthorized-qualification-issuer`. Καμία denylist ενός kid.
- **Κάθε υπογραφή του `signers[]` επαληθεύεται** (context `mltp3:qual-state`) με το
  δημόσιο κλειδί που το registry συνδέει με το kid. Quorum = πλήθος **διακριτών**
  registry kids με έγκυρη υπογραφή. Άγνωστο kid ⇒ δεν μετρά ΚΑΙ ⇒
  `unauthorized-qualification-issuer`.
- **Auditor receipts** μετρούν ως evidence ΜΟΝΟ αν `local_signature` ≠ null,
  επαληθεύεται έναντι registry, `bundle_digest` == digest του release manifest του
  `subject.release_root`, και `result == VERIFIED`.
- **Subject binding:** ο verifier απαιτεί `subject.release_root == bundle.release_anchor.release_root`
  (και, για `subject.kind == claim`, `claim_id` ίσο με το claim που το επικαλείται).
  Μεταφύτευση record σε άλλο release ⇒ `qualification-subject-mismatch`.
- Dangling `qualification_state_ref` (δεν επιλύεται στο `qualification_records`
  του bundle) ⇒ `dangling-qualification-ref` ⇒ level `none` ΚΑΙ claim result
  `UNVERIFIED_FOR_MACHINE_RELIANCE` (ποτέ VERIFIED — RC-07). Λήξη `expiry` ⇒
  `expired` ⇒ level `none`.
- Η επίλυση γίνεται **ΜΟΝΟ** από το `qualification_records` του bundle (η v2
  εναλλακτική «ή με tlog inclusion» αφαιρέθηκε: από hash δεν προκύπτει record).

---

## 4. CRYPTOGRAPHIC PROFILE — ΠΛΗΡΕΙΣ ΠΑΡΑΜΕΤΡΟΙ (RC-26)

### 4.1 Πρωτόγονες, παράμετροι, ταυτότητες κλειδιών

| λειτουργία | αλγόριθμος / παράμετρος | που |
|---|---|---|
| **Hashing / Merkle inclusion** | **SHA-256**, RFC 9162 profile `lawmax-merkle-sha256-v1` (leaf `0x00`, node `0x01`, unbalanced split, no-duplicate-last) | inclusion proofs, roots, κάθε `*_id` |
| **Signatures (era-2, κανονικό)** | **Ed25519** (RFC 8032), επαλήθευση **strict**: απόρριψη μη-κανονικού `S` (S ≥ L), απόρριψη σημείων εκτός της κύριας υποομάδας (small-order), καμία ZIP215-χαλάρωση | delegations, revocations, registry snapshots, release root, IssuedClaims, witness checkpoints, QSR, receipts, reviewer adoption, provider attestations |
| **Signatures (era-1, legacy)** | **RS256** = RSASSA-PKCS1-v1_5/SHA-256, modulus **≥ 3072 bit**, `e = 65537` | ΜΟΝΟ επαλήθευση era-1 releases (PCL corpus-proof JWS)· ποτέ νέες υπογραφές |
| **Ταυτότητα κλειδιού** | `kid` ≡ **RFC 7638 JWK thumbprint (SHA-256)** του δημόσιου κλειδιού — Η ΜΙΑ συνάρτηση fingerprint· η «sha256 του δημόσιου κλειδιού» της TRUST-BOOTSTRAP §2 ΟΡΙΖΕΤΑΙ ως αυτή (versioned precedence, §4.5) | παντού |
| **Δέσμευση `alg`↔κλειδί** | `alg` πρέπει να ταιριάζει με το `kty`/`crv` του JWK του `kid` (Ed25519 ⇔ OKP/Ed25519· RS256 ⇔ RSA) — αλλιώς `unknown-alg` | κάθε υπογραφή |
| **RFC-3161** | TSR DER (RFC 3161/5816), `messageImprint` = SHA-256, TSA cert chain επαληθεύεται έναντι `tsa_trust_anchors`· `accuracy` προστίθεται στο `clock_uncertainty` | `signed_at`, QSR `signed_at`, source `time_anchor` |
| **Threshold owner root** | FROST-Ed25519 t-of-n (προεπιλογή 3-of-5) — η δημόσια πλευρά είναι ΕΝΑ Ed25519 κλειδί· ο verifier δεν αλλάζει (§10.2) | Layer 0 |

**Canonical encoding:** `deployment/verify/canonical-serialization-spec.md`
(deterministic JSON, sorted keys, NFC, LF, χωρίς floats, ρητά type tags,
διαχωριστικά `0x1F`). **CBOR προβολή** (RFC 8949 deterministic encoding) ορίζεται
ΜΟΝΟ ως interoperability projection για SCITT (§11) — η υπογραφή γίνεται ΠΑΝΤΑ
πάνω στο canonical JSON· η CBOR μορφή φέρει το ίδιο `sig` και τον ίδιο digest.

### 4.2 Domain separation — ΠΛΗΡΗΣ ΚΛΕΙΣΤΟΣ ΚΑΤΑΛΟΓΟΣ context strings (canonical versioned registry)

**Executed-core contexts (era-2, στο εκτελέσιμο `schemas.json`):**
```
mltp3:issued-claim · mltp3:delegation · mltp3:revocation · mltp3:registry-snapshot ·
mltp3:release-root · mltp3:witness-checkpoint · mltp3:qual-state · mltp3:receipt ·
mltp3:reviewer-adoption · mltp3:provider-attestation · mltp3:compiler-attestation ·
mltp3:cockpit-intent · mltp3:certified-result · mltp3:citation · mltp3:profile-manifest
```
**POST-C2 design-only extension contexts (ΟΧΙ ακόμη στο εκτελέσιμο `schemas.json`· §2.11, §14, semantic-contract §4):**
```
mltp3:ontology-bundle · mltp3:shacl-receipt · mltp3:crypto-policy-epoch ·
mltp3:evidence-renewal · mltp3:pq-authorization · mltp3:conflict-policy
```
**Κανόνες (RC-26· POST-C2 correction):**
1. `sig = SIGN(kid, context_string ‖ 0x1F ‖ canonical_bytes(SIGNING_TARGET))` όπου
   **`SIGNING_TARGET` = το πλήρες αντικείμενο εξαιρώντας ΚΑΘΕ πεδίο υπογραφής**
   (`sig`, `signers[].sig`, `signatures[].sig`) — ώστε καμία υπογραφή να μην υπογράφει
   άλλη υπογραφή (no cross-signature cycle). Υπογραφή με λάθος context ⇒ `sig-invalid`.
2. **Ακυκλικά `*_id` (RC-#1, §13.1):** για κάθε record που φέρει `*_id`, το
   `*_id = prefix ‖ hex(sha256(id_domain ‖ 0x1F ‖ canonical(BODY)))` όπου **`BODY` =
   το αντικείμενο εξαιρώντας το ίδιο το `*_id`, ΚΑΘΕ πεδίο υπογραφής και κάθε detached
   στοιχείο** (time attestation, inclusion proofs, `release_root`). Το `*_id` **ΠΟΤΕ**
   δεν εμφανίζεται στο δικό του preimage (`self-referential-id`). Η υπογραφή (κανόνας 1)
   καλύπτει το αντικείμενο **μαζί** με το ήδη υπολογισμένο `*_id`.
3. **Κλειστότητα registry:** κανένα context δεν χρησιμοποιείται αν δεν ορίζεται
   **ακριβώς μία φορά** εδώ. Νέο context = νέα έκδοση MLTP. `id_domain` ανά prefix:
   `onto1:→mltp3:ontology-bundle-id`, `shr1:→mltp3:shacl-receipt-id` (domain separation
   ταυτότητας, διακριτό από το signature context).

### 4.3 Error taxonomy — ΚΛΕΙΣΤΗ, ΟΝΟΜΑΣΤΙΚΗ (35 ονόματα)

```
malformed-envelope · unknown-claim-type · schema-mismatch ·
text-hash-mismatch · inclusion-failed · path-too-long · root-mismatch ·
untrusted-key · unknown-alg · sig-invalid · key-binding-mismatch ·
delegation-invalid · delegation-expired · delegation-scope-violation ·
no-trusted-signature-time · consistency-failed · split-view · split-view-unverifiable ·
witness-quorum-failed · untrusted-registry · stale-revocation-state ·
revoked · retroactively-revoked · expired · stale ·
dangling-qualification-ref · unauthorized-qualification-issuer ·
qualification-subject-mismatch · insufficient-provenance · coverage-not-total ·
undecided-legal-state · unadopted-analysis · compiler-divergence · citation-unbound ·
UNKNOWN_FRESHNESS
```
Ο πίνακας §4.4 καλύπτει και τα 35 ένα-προς-ένα· όνομα χωρίς βήμα = ελάττωμα αυτού
του κειμένου (ελέγχεται μηχανικά από τον `V1.4-CONTRADICTION-OMISSION-AUDIT.sh`).

### 4.4 Κάθε error έχει ονομαστικό βήμα εκπομπής στο §8.3 (RC-12)

| error | βήμα §8.3 | claim result |
|---|---|---|
| malformed-envelope, unknown-claim-type, schema-mismatch | 0 (malformed-envelope και σε Q2 για record_id) | UNVERIFIED_FOR_MACHINE_RELIANCE |
| untrusted-key | K0, K1, K2 | UNVERIFIED_FOR_MACHINE_RELIANCE |
| unknown-alg | K2 (alg↔κλειδί) | UNVERIFIED_FOR_MACHINE_RELIANCE |
| key-binding-mismatch | K1 | UNVERIFIED_FOR_MACHINE_RELIANCE |
| delegation-invalid | K1 (root→root), K2 (seq) | UNVERIFIED_FOR_MACHINE_RELIANCE |
| no-trusted-signature-time | T | UNKNOWN |
| delegation-expired | K3 | UNVERIFIED_FOR_MACHINE_RELIANCE |
| delegation-scope-violation | K3 | UNVERIFIED_FOR_MACHINE_RELIANCE |
| sig-invalid | K4 | UNVERIFIED_FOR_MACHINE_RELIANCE |
| text-hash-mismatch, inclusion-failed, path-too-long | R1 (PCL §5 `inclusion()`) | UNVERIFIED_FOR_MACHINE_RELIANCE |
| root-mismatch | R2 | UNVERIFIED_FOR_MACHINE_RELIANCE |
| compiler-divergence | R4 | UNVERIFIED_FOR_MACHINE_RELIANCE (ολόκληρο το bundle) |
| consistency-failed | L1 (άκυρο/ελλιπές consistency proof) | UNVERIFIED_FOR_MACHINE_RELIANCE (ολόκληρο το bundle) |
| split-view | L1 (μη μονότονο tree_size ή ασύμβατες ρίζες), L3 (revocation checkpoint οπισθοδρομεί) | UNVERIFIED_FOR_MACHINE_RELIANCE (ολόκληρο το bundle) |
| split-view-unverifiable | L2 | UNKNOWN |
| witness-quorum-failed, untrusted-registry | L2, D | UNVERIFIED_FOR_MACHINE_RELIANCE |
| stale-revocation-state | L3 | UNKNOWN |
| revoked, retroactively-revoked | V | UNVERIFIED_FOR_MACHINE_RELIANCE |
| insufficient-provenance, coverage-not-total | P | UNKNOWN |
| undecided-legal-state | S | UNKNOWN |
| UNKNOWN_FRESHNESS | F0 | UNKNOWN |
| stale, expired | F | UNKNOWN |
| dangling-qualification-ref, unauthorized-qualification-issuer, qualification-subject-mismatch | Q | UNVERIFIED_FOR_MACHINE_RELIANCE |
| unadopted-analysis | J | UNVERIFIED_FOR_MACHINE_RELIANCE |
| citation-unbound | C (CertifiedResult χωρίς/με αλλοιωμένη παραπομπή) | UNVERIFIED_FOR_ATTRIBUTED_RELIANCE |

### 4.5 Versioned precedence έναντι foundations (RC-15, RC-25, RC-26)

- **PCL §4-5 (`authentic()`):** το μοντέλο «`thumbprint(public_key) == PINNED_KEY`
  ΚΑΙ `RS256_verify(PINNED_KEY)`» ισχύει **ΜΟΝΟ για era-1 releases**. Για era-2
  υπερισχύει το §8 αυτού του κειμένου: η ρίζα υπογράφεται από delegated
  release key, εξουσιοδοτημένο από τον pinned owner root. Η επέκταση της PCL σε
  PCL-2 (delegation-aware, Ed25519) είναι το βήμα 6 της υλοποίησης — μέχρι τότε η
  PCL-1 verifier επαληθεύει μόνο era-1. Καμία σύγκρουση ετυμηγορίας: ο
  `release_profile` (§5) επιλέγει.
- **TRUST-BOOTSTRAP §2 «fingerprint = sha256 του δημόσιου κλειδιού»:** ορίζεται
  ως RFC 7638 thumbprint (§4.1). Το TRUST-BOOTSTRAP §3 delegation statement
  προσλαμβάνει τη μορφή §2.9.
- **KEY-LIFECYCLE §2.4 (continuity statement από το παλιό κλειδί):** πληροφοριακό
  lineage ΜΟΝΟ (§9.3)· η αυθεντία διαδοχής είναι ΠΑΝΤΑ νέα root delegation.
- **KEY-LIFECYCLE §2.5:** όπως στη v2 — μόνο για scheduled rotation· key-compromise
  = §9 αυτού του κειμένου (η παραπομπή υπάρχει και στα δύο).

---

## 5. CANONICAL ROOTS — ΜΙΑ AUTHORITY ROOT, ΥΠΟΓΕΓΡΑΜΜΕΝΗ ΚΑΙ ΔΕΣΜΕΥΤΙΚΗ (RC-17)

`LAWMAX-TEMPORAL-IDENTITY-DESIGN.md §1.5/§8 (PCL-02)` ορίζει ρητά: **«Μία ρίζα:
receipt-set-root + graph-root ΜΕΣΑ στο canonical set → release root → TSR → tlog.
Το `pcl_text_root` πεθαίνει· cross-check στο spine verify.»**

- **TARGET authority root = `release_root`** (era-2): το canonical-set root που
  δεσμεύει `receipt_set_root` + `graph_root` + census-2, σφραγισμένο με TSR + tlog.
  **Η ΜΟΝΗ** ρίζα αυθεντίας. Κάθε IssuedClaim δηλώνει `release_ref.release_root`
  και ο verifier απαιτεί το `proof_material` inclusion **σε αυτήν** — όχι στη ρίζα
  που κουβαλά το ίδιο το proof (RC-17).
- **`ReleaseRootSignature`:** `{ "release_root", "release_generation", "census_digest",
  "sig": {alg, kid: <delegated release key>, sig — context "mltp3:release-root"} }`
  μέσα στο `release_anchor`· ο verifier το επαληθεύει με κλειδί εξουσιοδοτημένο
  για `release-signing`.
- **`pcl_text_root` = LEGACY CROSS-CHECK, όχι authority root.** Παραμένει στο
  census-2 **μόνο** ως era-1 συμβατότητα και ως **spine cross-check**. Ένα
  `pcl_text_root` που παρουσιάζεται ως authority root ⇒ `root-mismatch`.
- **Versioned legacy migration profile:** `release_profile ∈ {era-1-legacy, era-2}`·
  era-1 verify = PCL-1 `authentic()` με pinned RS256 key· era-2 verify = §8.3.
  `trust-status :legacy-sealed` για era-1· το πρώτο era-2 census δεσμεύει
  `prev_release_root` και η tlog αλυσίδα συνεχίζεται (TEMPORAL-IDENTITY §5/M0).

---

## 6. LAYER B — `TrustBundle` (CONTAINER, ΟΧΙ certificate) — ΠΛΗΡΩΣ OFFLINE-RESOLVABLE

```
{ "mltp": "3", "layer": "TrustBundle",
  "bundle_id": <"bnd1:" + canonical-hash(bundle)>,
  "release_profile": <"era-1-legacy" | "era-2">,
  "issued_claims": [ <IssuedClaim §1> ],
  "certified_results": [ <CertifiedResult §2.10 — μόνο σε bundles που παραδίδουν αποτελέσματα σε καταναλωτή> ],
  "census": <census-2 (materials in-toto)>,
  "release_anchor": { "release_root": "sha256:<hex>", "release_generation": {"era": 2, "seq": <int>},
                      "release_root_signature": <ReleaseRootSignature §5>,
                      "release_authority_proof": <lawmax/authority-proof-bundle/1 — owner→delegate, §2.1α>,
                      "prev_release_root": "sha256:<hex>" | null },
  "delegation_chain": [ <DelegationStatement §2.9 — ΚΑΘΕ ΕΝΑ root-signed, με scope> ],
  "keys": [ <JWK δημόσιο κλειδί για ΚΑΘΕ kid που εμφανίζεται σε υπογραφή του bundle,
             συμπεριλαμβανομένου του owner root ως αντικείμενο-προς-ταύτιση> ],       # RC-02
  "time_evidence": [ { "id": <string>, "kind": <"rfc3161" | "witnessed-checkpoint">,
                       "tsr_der": <base64 DER> | null, "tsa_chain": [ <DER> ] | null,
                       "checkpoint": <SignedCheckpoint §10.1> | null } ],                 # RC-03
  "dual_compiler_attestation": { "compiler_a": { "id", "runtime", "legal_state_root": "sha256:<hex>", "projection_roots": {<name>: "sha256:<hex>"},
                                                 "sig": {alg, kid, sig — context "mltp3:compiler-attestation"} },
                                 "compiler_b": { "id", "runtime", "legal_state_root": "sha256:<hex>", "projection_roots": {<name>: "sha256:<hex>"},
                                                 "sig": {alg, kid, sig — context "mltp3:compiler-attestation"} } },   # v1.4 §4.6
  "transparency": { "log_id": <string>, "tree_size": <int>, "log_root": "sha256:<hex>",
                    "consistency_from": { "tree_size": <int>, "log_root": "sha256:<hex>" } | null,
                    "consistency_proof": [ "<hex>" ],
                    "inclusion": { "release_root_leaf_index": <int>, "proof": [ "<hex>" ] } },
  "witness_checkpoints": [ <SignedCheckpoint §10.1 — publication witnesses ΚΑΙ cross-client witnesses> ],
  "qualification_records": [ <QualificationStateRecord §3 για ΚΑΘΕ qualification_state_ref> ],
  "auditor_receipts": [ <VerificationReceipt §7 ανεξάρτητων auditors, local_signature ΜΗ-null> ],
  "revocation": { "statements": [ <RevocationStatement §2.9 — root-signed> ],
                  "checkpoint": { "tree_size": <int>, "log_root": "sha256:<hex>", "checkpoint_at": <legal-instant>,
                                  "inclusion_proofs": [ <ανά statement> ] } },
  "registry_snapshots": [ <RegistrySnapshot §2.9 — root-signed, για auth1/ireg1/census-universe που τα claims επικαλούνται> ],
  "registry_records": [ { "snapshot_kind", "record": <το πλήρες auth1/ireg1/census record>, "inclusion_proof": [ "<hex>" ] } ],
  "embedded_registries": { "witness_keys": [ <JWK> ], "auditor_keys": [ <JWK> ], "reviewer_keys": [ <JWK> ], "provider_keys": [ <JWK> ] }   # UNTRUSTED μέχρι επίλυση
}
```
**Το TrustBundle δεν ισχυρίζεται τίποτα από μόνο του — μεταφέρει.** Δεν φέρει
`verification_result`, δεν φέρει claim, δεν φέρει ελεύθερο κείμενο.

**Κανόνες offline-resolvability:**
- Κάθε `qualification_state_ref` **πρέπει** να επιλύεται σε `qualification_records`
  του ίδιου bundle — αλλιώς `dangling-qualification-ref`.
- Auditor receipts, revocation statements + checkpoint, witness checkpoints, time
  evidence, δημόσια κλειδιά, registry εγγραφές με inclusion proofs: **μέσα**
  στο bundle — ποτέ «κάπου αλλού». Κάθε `evidence_ref`/`aprf2`/`acq1`/`xrc2`/`cust1`
  αναφορά ενός claim επιλύεται σε αντικείμενο του ίδιου bundle (RC-11).
- **Embedded keys/registries είναι UNTRUSTED** μέχρι να επιλυθούν μέσω
  `LocalTrustState` (registries) ή μέσω pinned owner root (delegation, registry
  snapshots). Embedded registry χωρίς επίλυση ⇒ `untrusted-registry`· ένας
  witness/auditor/reviewer/provider που υπάρχει **μόνο** στο bundle **δεν** μετρά.
- `keys[]` είναι φορέας, όχι αυθεντία: ένα κλειδί «ισχύει» μόνο αν το thumbprint του
  ταιριάζει με `delegate_kid` root-signed delegation (issuer keys) ή με εγγραφή
  registry του καταναλωτή (auditors/witnesses/reviewers/providers).

---

## 7. LAYER C — `VerificationReceipt` (τοπικό αποτέλεσμα, ΟΧΙ issuer-signed) — ΜΕ LEVEL ΑΝΑ CLAIM (RC-07)

```
{ "mltp": "3", "layer": "VerificationReceipt",
  "bundle_digest": "sha256:<hex>",
  "release_root": "sha256:<hex>",
  "result": <"VERIFIED" | "UNVERIFIED_FOR_MACHINE_RELIANCE" | "UNVERIFIED_FOR_ATTRIBUTED_RELIANCE" | "UNKNOWN">,
                                                                              # = min επί των claims, των certified results και των bundle-level ελέγχων
  "reason": <§4.3 error name | "ok">,
  "certified_results": [ { "result_id": "res1:<hash>", "result": <"VERIFIED" | "UNVERIFIED_FOR_MACHINE_RELIANCE" | "UNVERIFIED_FOR_ATTRIBUTED_RELIANCE" | "UNKNOWN">,
                           "reason": <§4.3 error name | "ok">, "citation_bound": <bool> } ],
  "claims": [ { "claim_id": "clm1:<hash>", "claim_type": <claim_type>,
                "result": <"VERIFIED" | "UNVERIFIED_FOR_MACHINE_RELIANCE" | "UNKNOWN">,
                "reason": <§4.3 error name | "ok">,
                "level": <"spec-qualified" | "implementation-qualified" | "mission-greece-qualified" |
                          "security-operations-qualified" | "provider-adoption-qualified" | "none">,
                "provenance_strength": <"S3-signed-by-authority" | "S2-official-channel-attested" | "S1-register-entry-only" | null>,
                "t_sig": <legal-instant> | null,
                "freshness": <"FRESH" | "STALE" | "UNKNOWN_FRESHNESS"> } ],
  "checks": [ { "step": <§8.3 step id>, "name": <§4.3 error name | "ok">, "detail": <typed value> } ],
  "trusted_now": { "now": <legal-instant> | null, "evidence_kind": <string> | null, "clock_uncertainty": <duration> },
  "verifier": { "id": <string>, "version": <string>, "kernel": <"lisp-kernel" | "rust-kernel" | "ocaml-kernel" | "python-reference">,
                "kernel_diversity": <int — πλήθος ανεξάρτητων υλοποιήσεων που έδωσαν ταυτόσημο receipt> },
  "produced_at": <legal-instant>,
  "local_signature": { "alg", "kid", "sig": <base64url — context "mltp3:receipt"> } | null }   # ΤΟΥ VERIFIER, ποτέ του issuer
```
**Το αποτέλεσμα το παράγει ο καταναλωτής, όχι ο εκδότης.** Ο εκδότης δεν μπορεί να
προ-δηλώσει «VERIFIED». Αν ο verifier υπογράψει, υπογράφει **ως verifier** (δικό του
receipt), ποτέ ως αυτο-ετυμηγορία του εκδότη. Το `result` ανήκει **αυστηρά** στο
κλειστό sum· `retroactively-revoked`, `UNKNOWN_FRESHNESS` κ.λπ. είναι `reason`,
ποτέ `result` (RC-12). Receipt που χρησιμοποιείται ως auditor evidence (§3) ΠΡΕΠΕΙ
να έχει `local_signature ≠ null`.

**Ιδιότητα ντετερμινισμού (Q21 δ):** δύο verifiers με το ΙΔΙΟ `LocalTrustState`
και το ΙΔΙΟ bundle παράγουν receipts με ταυτόσημα `result`, `claims[].result`,
`claims[].level`, `claims[].reason` και `checks[]` (τα `verifier`, `produced_at`,
`local_signature` εξαιρούνται από τη σύγκριση).

---

## 8. OFFLINE VERIFIER — ΤΟ ΣΥΜΒΟΛΑΙΟ

Έδρα: PCL §5 `inclusion()` (SHA-256, RFC 9162) + Ed25519/RS256 verifier (§4) +
RFC-3161 verifier (§1.3) + PROOF-OBJECT §4 (LOC-ceiling, kernel diversity). Η
**δεύτερη ανεξάρτητη υλοποίηση** (v1.4 §4.4: Rust ή OCaml) καταναλώνει το ίδιο
συμβόλαιο· ταυτόσημο receipt = κριτήριο kernel diversity.

### 8.1 `LocalTrustState` — ό,τι ο καταναλωτής φέρνει ΑΠΟ ΜΟΝΟΣ ΤΟΥ (ποτέ από το bundle)

```
LocalTrustState = {
  pinned_owner_root:            <RFC 7638 thumbprint του owner-root JWK, out-of-band, ≥2 κανάλια>,
                                # ΤΑΥΤΟΠΟΙΕΙ ΑΠΟΚΛΕΙΣΤΙΚΑ τον OWNER ROOT — ποτέ delegated κλειδί
  tsa_trust_anchors:            [ <DER root/intermediate certs έμπιστων TSAs> ],           # RC-03
  witness_registry:             { publication: [ {kid, jwk, name} ], cross_client: [ {kid, jwk, institution} ],
                                  cross_client_quorum: <int ≥ 2> },                                    # RC-31
  auditor_registry:             [ { kid, jwk, name, role: "independent-auditor" } ],       # allowlist, RC-06
  reviewer_registry:            [ { kid, jwk, name, role: "institutional-reviewer" } ],    # RC-20
  provider_registry:            [ { kid, jwk, name, role: "provider" } ],                  # RC-30
  quorum_policy:                { level: <int> ανά level — προεπιλογές §3.1 },
  authority_registry_root:      { seq, root, from_snapshot_sig_kid: <owner root> },        # RC-11
  institutional_register_root:  { seq, root, from_snapshot_sig_kid: <owner root> },        # RC-11
  census_universe_root:         { seq, root } | null,                                      # §2.4
  last_accepted_tlog:           { tree_size, log_root } | null,                            # consistency / split-view
  revocation_state:             { statements: [ <RevocationStatement> ], checkpoint: {tree_size, log_root, checkpoint_at} } | null,
  max_revocation_staleness:     <duration>,                                                # RC-24
  trusted_time:                 { now: <legal-instant> | null,
                                  evidence: <TSR/beacon/witness-checkpoint> | null,
                                  clock_uncertainty: <duration> }                          # null ⇒ ΚΑΜΙΑ αξίωση freshness
}
```
Οι registry ρίζες (`authority_registry_root`, `institutional_register_root`,
`census_universe_root`) προέρχονται από root-signed `RegistrySnapshot` που ο
καταναλωτής έχει ήδη αποδεχθεί (ή που το bundle φέρει ΚΑΙ ο verifier επαληθεύει με
τον pinned root και μονοτονία `seq`).

### 8.2 Αλυσίδα κλειδιών

```
pinned_owner_root ──(signed delegation: scope, not-before/after, seq)──► delegated_key ──(sig)──► IssuedClaim
                  ──(signed revocation / registry snapshot)──► Layer 0 κατάσταση
```
- Το `pinned_owner_root` ταυτοποιεί **αποκλειστικά** τον owner root. Το delegated
  release key έχει **ΔΙΑΦΟΡΕΤΙΚΟ** thumbprint — **ποτέ** δεν συγκρίνεται ως «ίσο με
  το root». Verifier που κάνει `thumbprint(delegated) == pinned_root` είναι **λάθος**.
- Το κλειδί που επαληθεύει ένα claim είναι **ακριβώς** το κλειδί του οποίου το
  thumbprint ισούται με `delegate_kid` μιας root-signed delegation (βήμα K1).
- Κάθε delegation φέρει **`scope`**. Το scope **ελέγχεται έναντι του `claim_type`**
  κάθε IssuedClaim (και `release-signing` για την υπογραφή της ρίζας). Έγκυρο
  κλειδί, λάθος scope ⇒ `delegation-scope-violation`.

### 8.3 Ψευδοκώδικας — `verify_bundle(bundle, lts)` (ΠΛΗΡΕΣ ΣΥΜΒΟΛΑΙΟ)

```
verify_bundle(bundle, lts) -> VerificationReceipt:
  R = new receipt; bundle_result = VERIFIED

  # 0. ΚΛΕΙΣΤΟ SCHEMA (RC-14, RC-18)
  for obj in every object of bundle (bundle, claims, records, statements):
     require fields(obj) == closed_field_set(obj.kind)                  else malformed-envelope
  for c in bundle.issued_claims:
     require c.claim_type ∈ CLAIM_TYPES                                  else unknown-claim-type
     require c.schema_id == "mltp3/" ‖ c.claim_type ‖ "/1"               else malformed-envelope
     require validates(c.payload, schema(c.schema_id)) AND validates(c.proof_material, schema(c.schema_id))
                                                                          else schema-mismatch
     require c.claim_id == "clm1:" ‖ canonical-hash(c without signature)  else malformed-envelope

  # K0. OWNER ROOT ΚΑΙ LAYER 0
  root_jwk = the jwk in bundle.keys with jwk_thumbprint(jwk) == lts.pinned_owner_root   else untrusted-key
  for s in bundle.delegation_chain ∪ bundle.revocation.statements ∪ bundle.registry_snapshots:
     require s.sig.kid == lts.pinned_owner_root AND alg_matches(s.sig.alg, root_jwk)     else untrusted-key
     require verify(root_jwk, context(s.kind), s without sig, s.sig.sig)                 else sig-invalid
  # ΜΟΝΟ ο root υπογράφει Layer 0· delegated κλειδιά δεν έχουν scope για αυτό (RC-19)

  # K1. ΔΕΣΜΕΥΣΗ ΚΛΕΙΔΙΟΥ ↔ DELEGATION (RC-02)
  for d in bundle.delegation_chain:
     require exists k in bundle.keys with jwk_thumbprint(k) == d.delegate_kid           else key-binding-mismatch
     require d.delegate_kid != lts.pinned_owner_root                                     else delegation-invalid   # root never delegates to itself

  # L. TRANSPARENCY, ΜΟΝΟΤΟΝΙΑ, WITNESSES (RC-17, RC-24, RC-31)
  R_rel = bundle.release_anchor.release_root
  require tlog_inclusion(R_rel, bundle.transparency)                                     else inclusion-failed
  if lts.last_accepted_tlog != null:
     require bundle.transparency.tree_size >= lts.last_accepted_tlog.tree_size            else split-view          # L1 μονοτονία
     require well_formed(bundle.transparency.consistency_proof)                           else consistency-failed  # L1
     require consistency(lts.last_accepted_tlog, bundle.transparency, consistency_proof)  else split-view          # L1
  witnesses = resolve(bundle.embedded_registries.witness_keys, lts.witness_registry)      else untrusted-registry  # D
  pub_ok    = count_valid(bundle.witness_checkpoints, witnesses.publication)  >= 1
  xc_ok     = count_valid(bundle.witness_checkpoints, witnesses.cross_client) >= lts.witness_registry.cross_client_quorum
  require pub_ok                                                                          else witness-quorum-failed  # L2
  if lts.last_accepted_tlog == null AND NOT xc_ok:
     bundle_result = min(bundle_result, UNKNOWN(split-view-unverifiable))                                     # L2 first-time consumer
  elif NOT xc_ok:
     require false                                                                        else witness-quorum-failed
  # L3. ΑΝΑΚΛΗΣΗ: ΗΛΙΚΙΑ CHECKPOINT
  rev = merge(lts.revocation_state, bundle.revocation)   # μόνο root-signed statements (K0)
  if lts.trusted_time.now != null AND now - rev.checkpoint.checkpoint_at > lts.max_revocation_staleness:
     bundle_result = min(bundle_result, UNKNOWN(stale-revocation-state))
  if lts.revocation_state != null: require rev.checkpoint.tree_size >= lts.revocation_state.checkpoint.tree_size  else split-view

  # R. ΜΙΑ ΡΙΖΑ: ΥΠΟΓΡΑΦΗ ΚΑΙ ΔΕΣΜΕΥΣΗ (RC-17)
  rs = bundle.release_anchor.release_root_signature
  d_rel = delegation_for(rs.sig.kid)   # K2 rule: max seq, root-signed
  require "release-signing" ∈ d_rel.scope                                                 else delegation-scope-violation
  require verify(key(rs.sig.kid), "mltp3:release-root", rs without sig, rs.sig.sig)     else sig-invalid
  require rs.release_root == R_rel AND census_digest(bundle.census) == rs.census_digest  else root-mismatch   # R2
  # R4. ΔΥΟ ΑΝΕΞΑΡΤΗΤΟΙ COMPILERS (v1.4 §4.6)
  a = bundle.dual_compiler_attestation.compiler_a; b = bundle.dual_compiler_attestation.compiler_b
  require a.runtime != b.runtime AND verify_each(a, b, "mltp3:compiler-attestation")     else sig-invalid
  require a.legal_state_root == b.legal_state_root AND a.projection_roots == b.projection_roots   else compiler-divergence

  # F0. TRUSTED NOW (κλείνει KT1)
  if lts.trusted_time.now == null OR lts.trusted_time.evidence == null:
     freshness_global = UNKNOWN_FRESHNESS      # ιστορική υπογραφή ΜΠΟΡΕΙ να επαληθευτεί, freshness ΟΧΙ
  else: freshness_global = EVALUABLE; now = lts.trusted_time.now

  # ΑΝΑ CLAIM
  for c in bundle.issued_claims:
     cr = {claim_id: c.claim_id, result: VERIFIED, level: none, freshness: freshness_global}
     # K2. ΕΠΙΛΟΓΗ DELEGATION (RC-05)
     ds = [d in bundle.delegation_chain with d.delegate_kid == c.signature.kid]
     require ds non-empty                                                                 else untrusted-key
     d = argmax_seq(ds)
     require c.signature.delegation_seq == d.seq                                          else delegation-invalid
     require alg_matches(c.signature.alg, key(c.signature.kid))                           else unknown-alg
     # T. ΑΥΘΕΝΤΙΚΟΠΟΙΗΜΕΝΟΣ ΧΡΟΝΟΣ ΥΠΟΓΡΑΦΗΣ (RC-03)
     ev = resolve(c.signed_at.anchor.evidence_ref, bundle.time_evidence)                  else no-trusted-signature-time
     if ev.kind == "rfc3161":
        require verify_tsr(ev.tsr_der, ev.tsa_chain, lts.tsa_trust_anchors)              else no-trusted-signature-time
        require ev.messageImprint == SHA-256(c.signature.sig)                             else no-trusted-signature-time
        t_sig = ev.genTime
     else:  # witnessed-checkpoint
        require checkpoint_valid(ev.checkpoint, witnesses.cross_client, quorum)           else no-trusted-signature-time
        require leaf_included(SHA-256(c.signature.sig), ev.checkpoint)                    else no-trusted-signature-time
        t_sig = ev.checkpoint.time
     require c.signed_at.trusted_time == t_sig                                            else no-trusted-signature-time
     cr.t_sig = t_sig
     # K3. ΠΑΡΑΘΥΡΟ ΚΑΙ SCOPE ΣΤΟΝ ΧΡΟΝΟ ΥΠΟΓΡΑΦΗΣ (RC-04, RC-18)
     require d.not_before <= t_sig <= d.not_after                                         else delegation-expired
     require c.claim_type ∈ d.scope                                                       else delegation-scope-violation
     # K4. ΥΠΟΓΡΑΦΗ ΠΑΝΩ ΣΕ ΟΛΟ ΤΟ ENVELOPE (RC-01)
     require verify(key(c.signature.kid), "mltp3:issued-claim", signed_fields(c), c.signature.sig)   else sig-invalid
     # V. ΑΝΑΚΛΗΣΗ ΕΝΑΝΤΙ t_sig, ΑΥΣΤΗΡΟΤΕΡΗ ΠΡΟΤΕΡΑΙΟΤΗΤΑ (RC-05, RC-19, §9)
     applicable = [s in rev.statements with s.revoked_subject matches (c.signature.kid OR d.seq)]
     if applicable non-empty:
        inv = min(s.invalid_from for s in applicable)     # αυστηρότερο κερδίζει
        if t_sig >= inv: fail(cr, retroactively-revoked if any(s.revocation_reason == "key-compromise") else revoked)
     # R1-R3. INCLUSION ΣΤΗ ΜΙΑ ΡΙΖΑ (RC-17, RC-27)
     require c.release_ref.release_root == R_rel                                          else root-mismatch
     require pcl_inclusion(claim_leaf(c), c.proof_material.release_inclusion) == OK       else <PCL error>   # R1
     require c.proof_material.release_inclusion.merkle_root == R_rel                      else root-mismatch # R2
     require profile_proof_ok(c)   # R3: ανά profile — receipt replay, source_seal, ledger, passage, journal, replay_manifest
     # P. PROVENANCE (RC-10, RC-11)
     if c.claim_type ∈ {legal-state, temporal-projection, judgment-identity-and-text, jurisprudential-analysis, normative-impact-projection}:
        for m in manifestations_referenced(c):
           sa = source_authenticity_claim_for(m, bundle.issued_claims)                     else insufficient-provenance
           require all non-null: sa.authority_id, sa.institutional_register_id, sa.authority_proof_ref, sa.acquisition_receipt_id
                                                                                          else insufficient-provenance
           require sa.proof_material.authority_proof.strength != "S0-declared-only"       else insufficient-provenance
           require registry_inclusion_ok(sa, lts.authority_registry_root, lts.institutional_register_root)  else insufficient-provenance
           cr.provenance_strength = min(cr.provenance_strength, sa.proof_material.authority_proof.strength)
     if c.claim_type == coverage-and-freshness:
        require sum(c.payload.state_counts) == c.payload.position_count == entries(c.proof_material.universe_declaration_ref)  else coverage-not-total
     # S. UNDEC (RC-13)
     if c.claim_type == legal-state AND c.payload.legal_state == "UNDEC": set(cr, UNKNOWN, undecided-legal-state)
     if c.claim_type == jurisprudential-analysis AND c.payload.holding.state == "UNDEC": set(cr, UNKNOWN, undecided-legal-state)
     # J. REVIEWER ADOPTION (RC-20)
     if c.claim_type == jurisprudential-analysis:
        act = c.payload.reviewer_adoption_act
        require act.reviewer_kid ∈ lts.reviewer_registry AND act.reviewer_kid ∉ issuer_keys(bundle)   else unadopted-analysis
        require verify(key(act.reviewer_kid), "mltp3:reviewer-adoption", act without sig, act.sig)     else unadopted-analysis
        require act.adopted_digest == canonical-hash(c.payload without reviewer_adoption_act)          else unadopted-analysis
     # Q. QUALIFICATION (RC-06, RC-07, RC-08, RC-30)
     q = resolve(c.qualification_state_ref, bundle.qualification_records)
     if q == null: fail(cr, dangling-qualification-ref); cr.level = none
     else:
        require issuer_keys(bundle) ∩ (kids(lts.auditor_registry) ∪ kids(lts.provider_registry)) == ∅   else unauthorized-qualification-issuer  # Q1
        require q.record_id == "qsr1:" ‖ canonical-hash(q without signers[].sig)                         else malformed-envelope
        require q.subject.release_root == R_rel AND (q.subject.kind == "release" OR q.subject.claim_id == c.claim_id)
                                                                                          else qualification-subject-mismatch  # Q2
        reg = provider_registry if q.level == provider-adoption-qualified else auditor_registry
        valid_signers = { s.kid : s in q.signers, s.kid ∈ kids(lts[reg]), verify(key(s.kid), "mltp3:qual-state", q without signers[].sig, s.sig) }
        require |valid_signers| >= lts.quorum_policy[q.level]                             else unauthorized-qualification-issuer  # Q3
        require evidence_ok(q)   # §3.1: receipts signed by registered auditors, bundle_digest == release manifest digest, result VERIFIED;
                                 # provider attestations signed by registered providers ∉ issuer keys (Q4)
                                                                                          else unauthorized-qualification-issuer
        cr.level = q.level
        if freshness_global == EVALUABLE AND now > q.expiry: set(cr, UNKNOWN, expired); cr.level = none
     # F. ΦΡΕΣΚΑΔΑ (RC-09)
     if freshness_global == UNKNOWN_FRESHNESS: set(cr, UNKNOWN, UNKNOWN_FRESHNESS)
     elif c.claim_type == coverage-and-freshness:
        cr.freshness = FRESH if now - c.payload.freshness.as_of <= c.payload.freshness.max_staleness else STALE
        if cr.freshness == STALE: set(cr, UNKNOWN, stale)
     R.claims += cr
     bundle_result = min(bundle_result, cr.result)

  # C. CITATION-BOUND CERTIFIED RESULTS (§2.10)
  for x in bundle.certified_results:
     rr = {result_id: x.result_id, result: VERIFIED, citation_bound: false}
     require x.citation present AND fields(x.citation) == closed_field_set("citation/1")   else citation-unbound
     require canonical-hash(x.citation) == x.citation_digest                              else citation-unbound
     require x.citation.claim_id ∈ ids(bundle.issued_claims) AND x.citation.watchtower_release_uri names R_rel   else citation-unbound
     rr.citation_bound = true
     d = delegation_for(x.signature.kid) (K2 rule); require "certified-result" ∈ d.scope   else delegation-scope-violation
     t = authenticated_time(x.signed_at) (βήμα T); require d.not_before <= t <= d.not_after   else delegation-expired
     require verify(key(x.signature.kid), "mltp3:certified-result", x without signature.sig, x.signature.sig)   else sig-invalid
     require result_of_claim(x.citation.claim_id) == VERIFIED                             else propagate that claim result
     R.certified_results += rr
     bundle_result = min(bundle_result, rr.result)
  # citation-unbound ⇒ rr.result = UNVERIFIED_FOR_ATTRIBUTED_RELIANCE (§4.4)· ελέγχεται ΠΡΙΝ την υπογραφή ώστε το
  # αφαιρεμένο/αλλοιωμένο citation να ονομάζεται ρητά και όχι ως γενικό sig-invalid

  # Ε. ΤΕΛΙΚΟ
  R.result = bundle_result; R.reason = first_failing_reason_or_ok
  return R
```
`min` επί των results: `UNVERIFIED_FOR_MACHINE_RELIANCE < UNVERIFIED_FOR_ATTRIBUTED_RELIANCE < UNKNOWN < VERIFIED`
(η στέρηση παραπομπής ακυρώνει τη «πιστοποιημένη» χρήση, όχι την ιστορική επαλήθευση των claims).
`fail(cr, e)` θέτει `cr.result` κατά τον πίνακα §4.4 και `cr.reason = e`· `set(cr, UNKNOWN, e)`
ομοίως για UNKNOWN. Κανένα βήμα δεν είναι προαιρετικό. Ο πίνακας §4.4 είναι ο
έλεγχος πληρότητας: κάθε error εμφανίζεται σε ακριβώς ένα βήμα παραπάνω.

**Stopped/rewound clock (KT1):** ο verifier **δεν** εμπιστεύεται ποτέ το τοπικό
ρολόι ως `now`· χρειάζεται `trusted_time.evidence` (TSR/beacon/witness checkpoint
εντός `clock_uncertainty`). Χωρίς αυτό, η **ιστορική** υπογραφή επαληθεύεται
(inclusion + chain), αλλά το αποτέλεσμα είναι **`UNKNOWN` με reason
`UNKNOWN_FRESHNESS`, ποτέ `VERIFIED`**.

**Provider-side κανόνας:** αποτυχία οποιουδήποτε βήματος ⇒
`UNVERIFIED_FOR_MACHINE_RELIANCE`/`UNKNOWN` — ποτέ σιωπηλή παρουσίαση ως αυθεντικού
(v1.4 §4.7/§4.15). **Απορρίψεις** (PROOF-OBJECT §5, `DOMINANCE-MATRIX.md`): blockchain,
ZK-SNARK/STARK, W3C VC/DID ως CORE, LLM στο trusted path.

---

## 9. REVOCATION SEMANTICS — ΟΧΙ ΑΠΟΛΥΤΟ «pre-revocation stays valid»

Το «ό,τι υπογράφηκε πριν την ανάκληση παραμένει έγκυρο» ισχύει **μόνο** για
προγραμματισμένη rotation/supersession — **ΟΧΙ** σε key compromise. Κανόνες:

| `revocation_reason` | `invalid_from` | συνέπεια |
|---|---|---|
| `superseded` / `delegation-expired` / `policy` | = `revoked_at` | υπογραφές με αυθεντικοποιημένο `t_sig` **πριν** το `revoked_at` **παραμένουν έγκυρες** (key-lifecycle §2.5) |
| `key-compromise` | = `compromise_known_at` **ή νωρίτερα** (policy) | υπογραφές με `t_sig ≥ invalid_from` **ΑΚΥΡΩΝΟΝΤΑΙ ΑΝΑΔΡΟΜΙΚΑ**· **μόνο** υπογραφές με ανεξάρτητο RFC-3161 χρόνο (επί της υπογραφής, §1.3) **πριν** το `invalid_from` επιβιώνουν· ο verifier επιστρέφει reason `retroactively-revoked` |

**9.1 Υποχρεωτικά πεδία** (§2.9): `revocation_reason`, `revoked_at`, `invalid_from`,
`compromise_known_at` (για compromise) — **fail-closed**: απόν πεδίο ⇒ η ανάκληση
θεωρείται `key-compromise` με `invalid_from = revoked_at`, ποτέ αγνοείται. Η
αναδρομική ακύρωση είναι **ρητή policy**, όχι σιωπηλή — δημοσιεύεται ως root-signed
`RevocationStatement` στο tlog (ώστε οι consumers να τη δουν μέσω consistency/gossip
και witnessed checkpoints) και ΑΝΑΔΡΟΜΙΚΑ επηρεάζει κάθε υπογραφή με `t_sig ≥ invalid_from`.

**9.2 Χρόνος σύγκρισης:** η ανάκληση ελέγχεται **έναντι του trusted signature time**
(`t_sig`, παραγόμενο από το time evidence — §8.3 βήμα T), **ΟΧΙ** έναντι του legal
effective-time του payload. Χωρίς αυθεντικοποιημένο `t_sig` ⇒ `UNKNOWN`. Πολλαπλά
statements για το ίδιο subject ⇒ ισχύει το **ελάχιστο** `invalid_from` (RC-19 γ).

**9.3 Rotation — ΕΝΑΣ μηχανισμός (RC-25):** διαδοχή κλειδιού = νέα root-signed
`DelegationStatement` με `seq+1` για το νέο `delegate_kid` ΚΑΙ `RevocationStatement`
(`superseded`) για το παλιό. Η «continuity statement υπογεγραμμένη από το παλιό
κλειδί» (KEY-LIFECYCLE §2.4) παραμένει ΜΟΝΟ ως πληροφοριακό `key_lineage` στο
registry — ο verifier ΔΕΝ την καταναλώνει ως αυθεντία. Δύο ACTIVE specs **δεν**
δίνουν αντίθετη ετυμηγορία: versioned precedence §4.5.

**Versioned precedence — μία ετυμηγορία ανά υπογραφή:** το
`LAWMAX-KEY-LIFECYCLE-SPEC.md §2.5` ισχύει **μόνο** για `superseded`/`delegation-expired`/
`policy`. Για `key-compromise`, **το MLTP v3 §9 έχει ρητή versioned precedence** και η
αναδρομική ακύρωση υπερισχύει. Το KEY-LIFECYCLE §2.5 φέρει αντίστοιχη παραπομπή.

**9.4 Έκτακτη ανάκληση:** `RevocationStatement` με `key-compromise` μπορεί να
δημοσιευθεί από το threshold owner root (§10.2) σε οποιοδήποτε από τα ≥2 κανάλια
witnesses· ο καταναλωτής που το λαμβάνει με έγκυρο root signature το εφαρμόζει
ΑΜΕΣΑ (δεν περιμένει checkpoint) — η προσθήκη ανάκλησης είναι πάντα ασφαλής
κατεύθυνση (fail-closed).

---

## 10. ΕΞΩΤΕΡΙΚΟΙ ΕΛΕΓΚΤΕΣ — ΤΡΕΙΣ ΔΙΑΚΡΙΤΕΣ ΤΑΞΕΙΣ + DISTRIBUTED TRUST MESH (RC-31, v1.4 §4.10)

| τάξη | τι αποδεικνύει | τι ΔΕΝ αποδεικνύει | έδρα |
|---|---|---|---|
| **Transparency witnesses — publication** (GitHub mirror, ≥2 RFC-3161 TSAs) | ότι κάτι δημοσιεύτηκε και **πότε** | **ΟΧΙ** μη-equivocation (μια TSA χρονοσφραγίζει οποιοδήποτε digest· ένα mirror του ίδιου owner δεν είναι ανεξάρτητο) | trust-bootstrap §4 |
| **Cross-client witnesses** (≥2 ανεξάρτητα θεσμικά witnesses που **υπογράφουν checkpoints** αφού επαληθεύσουν consistency με το ΔΙΚΟ τους προηγούμενο checkpoint) | **consistency / μη-equivocation (split-view)** για κάθε consumer, ακόμη και first-time | **ΟΧΙ** ορθότητα περιεχομένου | §10.1 SignedCheckpoint· registry §8.1 |
| **Independent auditors/verifiers** | αναπαραγωγή coverage, freshness, legal-state, jurisprudence metrics **από την πηγή** | — | proposer-blind re-derivation (M5), δεύτερη υλοποίηση (kernel diversity) |

**Ρητά:** GitHub/TSAs **δεν** πιστοποιούν ότι το περιεχόμενο είναι σωστό ή ότι τα
metrics ισχύουν — πιστοποιούν **μόνο** ότι κάτι δημοσιεύτηκε και πότε. Η
μη-equivocation απαιτεί **cross-client witnesses** (ή τον ίδιο τον consumer με
προηγούμενο checkpoint). Η ορθότητα περιεχομένου/metrics απαιτεί **independent
auditor**, όχι witness. Ένα `VerificationReceipt` που στηρίζει content-correctness
σε witness μόνο ⇒ σφάλμα ταξινομίας. Ένας first-time consumer χωρίς cross-client
quorum λαμβάνει `UNKNOWN(split-view-unverifiable)` — ποτέ VERIFIED.

### 10.1 `SignedCheckpoint`
```
{ "log_id": <string>, "tree_size": <int>, "log_root": "sha256:<hex>", "time": <legal-instant>,
  "witness_kind": <"publication" | "cross-client">,
  "prev_witnessed": { "tree_size": <int>, "log_root": "sha256:<hex>" } | null,   # cross-client: ΥΠΟΧΡΕΩΤΙΚΟ μετά το πρώτο
  "sig": { "alg", "kid": <thumbprint ∈ witness_registry>, "sig": <base64url — context "mltp3:witness-checkpoint"> } }
```
Ένα cross-client witness υπογράφει ΜΟΝΟ αφού επαληθεύσει consistency proof από το
`prev_witnessed` του — έτσι δύο forks δεν μπορούν και τα δύο να πάρουν υπογραφή
του ίδιου witness. Πρότυπο: witness cosigning όπως στα CT/sigstore witness networks.

### 10.2 Distributed Trust Mesh — η επιλεγμένη μορφή (η ανάλυση κυριαρχίας στο `DOMINANCE-MATRIX.md` D-07 έως D-11)

| στοιχείο | επιλογή | γιατί (σύνοψη) |
|---|---|---|
| Owner root | **threshold Ed25519 (FROST) 3-of-5**, μερίδια σε ανεξάρτητες custody (δημιουργός offline ×2, HSM ×2, escrow ×1) | καμία μονή συσκευή/πρόσωπο δεν υπογράφει Layer 0· η δημόσια πλευρά παραμένει ένα Ed25519 κλειδί — ο verifier αμετάβλητος |
| Release-signing keys | delegated Ed25519 σε **HSM** ανά ανεξάρτητη υποδομή (τουλάχιστον δύο: παραγωγή + auditor-hosted), delegation ≤ 90 ημέρες | κλοπή = χρονικά φραγμένη· rotation = §9.3 |
| Transparency | **δύο** append-only logs: το tlog του Watchtower + **ανεξάρτητο θεσμικό log** (cross-logging: κάθε release_root γράφεται και στα δύο) | ένα log του owner δεν αποδεικνύει μη-equivocation |
| Witnesses | ≥2 cross-client witnesses (θεσμικά: π.χ. πανεπιστήμιο, δικηγορικός σύλλογος, αρχείο) + ≥2 TSAs + GitHub mirror | §10 |
| Interoperability | **SCITT-compatible** Signed Statements + Receipts (§11) | οι providers καταναλώνουν μια τυποποιημένη μορφή χωρίς να χάσουν τη σημασιολογία MLTP |
| Έκτακτη ανάκληση | §9.4 | — |
| Απορρίψεις | blockchain, ZK, VC/DID ως core | δεν κυριαρχούν (DOMINANCE D-11) |

---

## 11. ΔΙΑΛΕΙΤΟΥΡΓΙΚΟΤΗΤΑ — SCITT ΠΡΟΒΟΛΗ (v1.4 §4.11)

| MLTP v3 αντικείμενο | SCITT αντίστοιχο | κανόνας |
|---|---|---|
| `IssuedClaim` | Signed Statement (COSE_Sign1, RFC 9052) πάνω στα **ακριβή** COSE `Sig_structure` bytes | **ΔΙΑΚΡΙΤΗ υπογραφή** (διόρθωση #13): η κανονική-JSON υπογραφή MLTP (`sig = Ed25519(context ‖ 0x1F ‖ canonical(obj))`) **ΔΕΝ είναι** αυτομάτως COSE_Sign1. Η SCITT/COSE προβολή φέρει **δική της** επαληθεύσιμη υπογραφή πάνω στα COSE Sig_structure bytes (RFC 9052/9943)· ένα relabeling της JSON υπογραφής ως COSE **απορρίπτεται**. Η COSE προβολή = `MISSING` (βήμα 6, §13) |
| tlog inclusion + `SignedCheckpoint` | SCITT Receipt (COSE countersignature με inclusion proof) | ο verifier δέχεται receipt από **registered** transparency service (log_id ∈ witness_registry) |
| `TrustBundle` | Statement + Receipts + όλα τα resolvable αντικείμενα ως attached bundle | το bundle παραμένει η μονάδα offline επαλήθευσης |
| `RevocationStatement` | Signed Statement τύπου revocation στο ίδιο log | root-signed |
| `CertifiedResult` + `citation/1` | JSON-LD προβολή (`@context` lawmax/citation/1 → schema.org `Legislation`/`LegalForceStatus` και ELI ιδιότητες), `CitationToken` ως COSE_Sign1 | η παραπομπή ταξιδεύει με την υπογραφή της· `CitationToken` COSE = **χωριστή** υπογραφή πάνω στα COSE bytes, όχι relabeling (διόρθωση #13)· JSON-LD = προβολή, όχι πηγή αλήθειας |

Τα πρότυπα είναι επιφάνειες διαλειτουργικότητας, **όχι** ανταγωνιστική πηγή
αλήθειας: η σημασιολογία (ποιος υπογράφει τι, τι σημαίνει VERIFIED) ζει ΜΟΝΟ εδώ.

---

## 12. ΤΙ ΔΕΝ ΚΑΝΕΙ ΑΥΤΟ ΤΟ SPEC

Καμία υλοποίηση· κανένα νέο store/primitive/subsystem· κανένα destruction pass·
καμία αξίωση qualification. Η **σύνθεση** (τρία επίπεδα + Layer 0 + typed profiles +
trust mesh) είναι **σχεδιαστική**· οι επιμέρους έδρες υπάρχουν και απαριθμούνται με
disposition στο `PUBLIC-OBSERVATORY-CROSSWALK.md`. Οι kill witnesses που
αντιστοιχούν σε κάθε ρίζα RC-01 έως RC-31 ζουν στο
`PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md §7` (KW-17 έως KW-47) — **προδηλωμένοι,
ΜΗ εκτελεσμένοι**.


---

## 13. ΕΚΤΕΛΕΣΙΜΗ ΑΝΑΦΟΡΑ — ΑΚΥΚΛΙΚΗ ΚΑΤΑΣΚΕΥΗ (ΑΥΘΕΝΤΙΚΗ ΕΠΙ ΣΥΓΚΡΟΥΣΗΣ ΜΕ §1–§6)

**Έδρα: `deployment/verify/mltp3/` — `EXECUTABLE PROTOCOL CLOSURE PASSED — NOT YET
SPEC QUALIFIED`.** Δύο ανεξάρτητοι επαληθευτές (Go pure-Go `crypto/ed25519` και Node
`node:crypto`/OpenSSL — γνήσια διαφορετικά vetted backends· builder: libsodium)
επαληθεύουν έναν θετικό `TrustBundle` και απορρίπτουν 31 μεταλλάξεις (KW-64 έως KW-94),
**ο καθένας με το ίδιο typed error class**. `bash deployment/verify/mltp3/run.sh`
(exit 0· `fixtures/REPORT.json` με tool versions + SHA-256). Αυτή η ενότητα
**υπερισχύει** των §1–§6 όπου η ανεπίσημη διατύπωσή τους για `*_id`, χρόνο ή release
membership συγκρούεται με την ακυκλική κατασκευή.

### 13.1 Οι διορθωμένοι κύκλοι (ρητά)

- **(#1 self-id):** κάθε `*_id` = `prefix ‖ hex(sha256(id_domain ‖ 0x1F ‖ canonical(BODY)))`
  όπου το `BODY` **αποκλείει** το ίδιο το id, την υπογραφή, το detached χρονικό
  στοιχείο, το `release_root` και τα inclusion proofs. Το `claim_id`/`result_id`/
  `bundle_id` **ποτέ** δεν εμφανίζεται στο δικό του preimage (`self-referential-id`).
- **(#2 timestamp cycle):** ο αξιόπιστος χρόνος είναι **detached `TimeAttestation`**
  που υπογράφει το `message-imprint` της υπογραφής ενός αντικειμένου — **έξω** από τα
  signed fields. Το `signed_at` **δεν** είναι πλέον υπογεγραμμένο πεδίο του
  `IssuedClaim` στην εκτελέσιμη μορφή· ο verifier παράγει `t_sig` από το detached
  `TimeAttestation`. (Το §1.0 διατηρεί το `signed_at` ως ιστορική διατύπωση· εδώ
  αποσπάται.)
- **(#3 release/merkle cycle):** το claim **δεν** φέρει `release_root`/`release_ref`
  στο υπογεγραμμένο σώμα του· η ένταξη αποδεικνύεται με **detached inclusion proof**
  στην υπογεγραμμένη `release_root` (που παράγεται **μετά** τα claim_ids).
- **(#4 result/bundle cycle):** το `CertifiedResultBody` αναφέρεται μόνο σε
  προϋπάρχοντα ids· το `bundle_id` = `hash(BundleManifest)` όπου το manifest
  **δεν** περιέχει το `bundle_id`, και κανένα result δεν ενσωματώνει το `bundle_id`.
- **(#5 revocation checkpoint):** υπογεγραμμένο από ≥2 witnesses, με authenticated
  time (φρεσκάδα ≤ `max_revocation_staleness` αλλιώς `stale-revocation-state`),
  consistency proof, και inclusion/non-inclusion ανά statement (`omitted-revocation`).

### 13.2 Ενιαίο `verify_attestation` συμβόλαιο (#6)

Κάθε υπογεγραμμένη οντότητα (claims, release, QSR, results, compiler/provider/
witness/reviewer records) περνά από **ένα** συμβόλαιο: (1) υπογραφή Ed25519 πάνω στο
`context ‖ 0x1F ‖ canonical(obj χωρίς sig)`· (2) ταυτότητα υπογράφοντα (delegation
chain → owner root για issuer keys· registry για auditor/witness/provider/reviewer/
tsa)· (3) delegated scope που καλύπτει τον σκοπό· (4) παράθυρο ισχύος έναντι
**συντηρητικού** `t_sig = gen_time + accuracy` (RFC 3161: το `genTime` είναι
τεκμήριο ότι το imprint υπήρχε **το αργότερο** τότε — **όχι** ακριβής χρόνος
δημιουργίας, διόρθωση #10)· (5) ανάκληση έναντι `t_sig`· (6) canonical recompute·
(7) trusted roots. Άγνωστο backend ⇒ `CRYPTO_BACKEND_UNAVAILABLE`, fail-closed.

### 13.3 Πλήρης επαλήθευση `CertifiedResult` + citation binding (#7, #8)

Ο verifier ελέγχει **ολόκληρη** την απάντηση: `dependency_set` ⊆ επαληθευμένων
claims, `release_root`/`projection` ρίζες, `derivation_proof`/`counterproof`,
`coverage_ref` παρόν και φρέσκο (#11). Το `citation/1` είναι **μέσα** στα signed
bytes· ο verifier ελέγχει `citation_digest`, `claim_id ∈ dependency_set`,
`watchtower_release_uri` δεσμεύει το `release_root`, `citation_policy_id` ∈ trusted,
**διπλή** απόδοση (de jure εκδότης ΚΑΙ Watchtower ως πηγή αναπαράστασης), και τον
`CitationToken`. Αποτυχία ⇒ `citation-unbound`/`citation-policy-untrusted`/
`citation-incomplete-dual` ⇒ **`UNVERIFIED_FOR_ATTRIBUTED_RELIANCE`**. Μία έγκυρη
παραπομπή σε ένα claim **δεν** αρκεί.

### 13.4 Provider conformance (#9), compiler independence (#12), jurisprudence (#15), governance (#16)

- **`ProviderConformanceRecord`** (typed, §13.5): `provider_id`, `provider_kid` ∈
  provider registry, `policy_version`, `evidence_window`, `expiry`, υπογραφή —
  **διακριτό** από τη γενική «υιοθέτηση providers». Ληγμένο ⇒ `provider-nonconformant`·
  εκτός registry ⇒ `provider-subject-mismatch`.
- **Compiler independence:** δύο attestations δεσμεύουν **κοινό** `input_journal_root`
  και `output_root`, με **διακριτά** `compiler_family_id`, `source_digest`, `kid`.
  Ίδιο family/source/kid ⇒ `fabricated-compiler-independence`· άνισο output ⇒
  `compiler-divergence`.
- **Jurisprudence (#15):** ντετερμινιστικός parser πιστοποιεί μόνο `cites`· ρήματα
  μεταχείρισης (`followed`/`overruled` κ.λπ.) χωρίς reviewer adoption ⇒
  `misrepresented-treatment`.
- **Governance (#16):** το QSR απαιτεί ≥2 auditors **ξένους** προς τα issuer keys
  (separation-of-duty)· δύο συσκευές ίδιου operator **δεν** είναι ανεξάρτητοι
  custodians — οι πραγματικές ταυτότητες custodians/quorum παραμένουν **U-2**
  (δεν εφευρίσκονται).

### 13.5 Επεκταμένη ταξινομία σφαλμάτων (superset της §4.3 για την ακυκλική κατασκευή)

Επιπλέον των 35 ονομάτων της §4.3, η εκτελέσιμη αναφορά εκπέμπει typed:
`self-referential-id`, `id-mismatch`, `release-root-cycle`, `result-bundle-cycle`,
`time-imprint-mismatch`, `no-trusted-signature-time`, `unsigned-revocation-checkpoint`,
`omitted-revocation`, `answer-incomplete`, `dependency-unverified`,
`citation-policy-untrusted`, `citation-incomplete-dual`, `provider-conformance`
(`provider-nonconformant`/`provider-subject-mismatch`),
`fabricated-compiler-independence`, `misrepresented-treatment`,
`CRYPTO_BACKEND_UNAVAILABLE`. Η πλήρης λίστα + result mapping: `schemas.json`
(`error_taxonomy`), επαληθευμένη ένα-προς-ένα από τους δύο verifiers.

### 13.6 COSE/SCITT (#13) — vetted interop vector + τι λείπει ρητά

Η εκτελέσιμη αναφορά υπογράφει με το κανονικό-JSON σχήμα. Ένα **πραγματικό**
`COSE_Sign1` vector πάνω στα **ακριβή** MLTP canonical payload bytes παράγεται και
επαληθεύεται με τη **vetted veraison/go-cose v1.3.0** (pinned, vendored, offline) —
`deployment/verify/mltp3/interop/cose/` (C1.4· ποτέ hand-rolled CBOR/COSE). Η
κανονική-JSON υπογραφή MLTP και το `COSE_Sign1` είναι **διακριτές κατασκευές**
(διαφορετικά bytes, διαφορετικός container)· η JSON υπογραφή **δεν** είναι COSE και
**δεν** μετονομάζεται σε τέτοια. Η **πλήρης SCITT υπηρεσία** παραμένει `MISSING`
(μόνο το construction boundary + interop vector ζητήθηκαν).

### 13.8 Pre-freeze evidence hardening (Stage C1)

- **Profile manifest pinning (C1.1):** signed `MLTPProfileManifest`
  (`fixtures/profile.json`, owner-root-signed, context `mltp3:profile-manifest`)
  pins το SHA-256 του `schemas.json`, canonicalization/merkle profiles, sig-context
  και id-domain digests, error-taxonomy/qualification-policy versions, min verifier
  version, activation/expiry/revoked. Αλλαγμένο/υποβαθμισμένο/άγνωστο schema ή profile
  ⇒ `untrusted-profile` (fail-closed). Dev override (`MLTP_DEV_OVERRIDE=1`) **ποτέ**
  δεν επιστρέφει `VERIFIED` (cap σε `UNKNOWN`, `profile-override-active`). Μάρτυρες
  KW-95 έως KW-100.
- **LocalTrustState boundary (C1.2):** το `LocalTrustState` μένει **εξωτερικό** στο
  untrusted bundle· bundle δεν αντικαθιστά owner root/registry/citation-policy·
  embedded registries άκυρα μέχρι authentication· trust-state update = authenticated
  **monotonic** transition (`nonmonotonic-revocation-state`). Μάρτυρες KW-101 έως KW-103.
- **Backend evidence (C1.3):** libsodium version από `sodium_version_string()`
  (**1.0.18**, soname libsodium.so.23, ABI 10.3) — όχι από το filename.
- **Standards interop (C1.4):** πραγματικό DER RFC-3161 token (OpenSSL `ts`) +
  πραγματικό `COSE_Sign1` (veraison/go-cose), `interop/`. Το core `TimeAttestation`
  είναι deterministic **test double**, όχι TSR.
- **Honesty (C1.6):** Go+Node = δύο ανεξάρτητες **N-version υλοποιήσεις** από μία
  προδιαγραφή, **όχι** ανεξάρτητος οργανωτικός έλεγχος.

### 13.7 Κατάσταση

`EXECUTABLE PROTOCOL CLOSURE PASSED — NOT YET SPEC QUALIFIED`. Δεν είναι freeze,
δεν είναι υλοποίηση των 15 επιπέδων, δεν διεκδικεί βαθμίδα. Μάρτυρες KW-64 έως
KW-103 εκτελεσμένοι (40 μεταλλάξεις). Επόμενο (μόνο με ρητή εντολή δημιουργού):
targeted executable protocol validation → `SPEC QUALIFIED` (κλίμακα v1.4 §10).

---

## 14. CRYPTOGRAPHIC AGILITY & LONG-TERM EVIDENCE PRESERVATION PROFILE (POST-C2 Finding 2, v1.4 §4.10)

**Σκοπός:** ένα δημόσιο νομικό παρατηρητήριο πρέπει να διατηρεί **επαληθεύσιμο** τεκμήριο
για **δεκαετίες**. Η §4 πινάρει Ed25519/SHA-256/RFC-3161 και έχει μόνο δι-εποχικό
μονοπάτι `{era-1-legacy, era-2}` (RSA→Ed25519, §5). Αυτό **δεν** είναι γενική
κρυπτογραφική ευελιξία. Αυτή η ενότητα **επεκτείνει** (δεν αντικαθιστά) την §4/§5/§9/§10
με versioned suites, epochs, hybrid classical/PQ, downgrade resistance και long-term
evidence renewal. **ΔΕΝ** ανάγεται σε «αντικατάσταση Ed25519» ή «επιβολή SHA-3». Ένα
χρονοδιάγραμμα US/NSS **δεν** είναι νομικά δεσμευτικό για αυτό το ελληνικό παρατηρητήριο·
η πολιτική epochs ορίζεται από τον δημιουργό/ελληνική διακυβέρνηση, **ενημερωμένη** από
NIST FIPS 204 (ML-DSA), ETSI/CEN long-term signatures, χωρίς εξωτερική δέσμευση.

### 14.1 Versioned algorithm-suite registry
```
AlgorithmSuite = { "suite_id": <"suite:" + short>, "sig_alg": <"Ed25519" | "ML-DSA-65" | "RS256">,
  "hash_alg": <"SHA-256" | "SHA-384" | "SHA3-256">, "canonical_binding": "jcs-0x1F-context",
  "status": <"active" | "sunset-announced" | "sunset" | "forbidden">,   # typed, ΟΧΙ boolean
  "activation": <legal-instant>, "sunset_at": <legal-instant> | null }
```
Κλειστό, versioned. `ML-DSA-65` = FIPS 204 (Dilithium level 3). Η δέσμευση υπογραφής
παραμένει `SIGN(kid, context ‖ 0x1F ‖ canonical_bytes)` με **suite tag** στο signed
structure ώστε να μην συγχέεται suite (cross-suite confusion ⇒ `suite-mismatch`).

### 14.2 Crypto-policy epochs — root-signed, monotonic
```
CryptoPolicyEpoch = { "record": "crypto-policy-epoch", "seq": <int monotonic>,
  "required_new": [ <suite_id> ],   # suites υποχρεωτικά για ΝΕΕΣ υπογραφές (AND, όχι OR)
  "accepted_verify": [ <suite_id> ], "forbidden": [ <suite_id> ],
  "hybrid_required": <"none" | "classical+pq">,   # typed
  "effective_from": <legal-instant>, "sig": <threshold owner root, context "mltp3:crypto-policy-epoch"> }
```
Το epoch πινιέται στο `MLTPProfileManifest` (C1.1) και στο `LocalTrustState`. Ο verifier
απορρίπτει suite κάτω από το `required_new`/`accepted_verify` του epoch που ισχύει για την
εποχή του αντικειμένου ⇒ `algorithm-downgrade` / `suite-below-policy` (**downgrade
resistance**: η επίθεση υποβάθμισης δεν περνά επειδή το ελάχιστο είναι root-pinned).

### 14.3 Hybrid classical + post-quantum (ordinary signed objects)
Σε epoch με `hybrid_required = classical+pq`, κάθε **ordinary** υπογεγραμμένο αντικείμενο
(delegated-signer: IssuedClaim, receipt κ.λπ.) φέρει **ΚΑΙ** μία Ed25519 **ΚΑΙ** μία
ML-DSA υπογραφή πάνω στα **ίδια** canonical bytes = `SIGNING_TARGET` (§4.2 κανόνας 1:
αντικείμενο **εξαιρώντας ΚΑΘΕ πεδίο υπογραφής** — καμία υπογραφή δεν υπογράφει άλλη),
με **ανεξάρτητα κλειδιά σε διακριτά failure domains**. `signatures = [ {suite, kid, sig}
(Ed25519), {suite, kid, sig} (ML-DSA-65) ]`. Ο verifier απαιτεί **AND**· απούσα/άκυρη
απαιτούμενη PQ υπογραφή ⇒ `pq-signature-missing` / `pq-signature-invalid`, **ποτέ
VERIFIED**. **Falsifier: KW-104.**

### 14.4 PQ ROOT AUTHORIZATION — ΕΠΙΛΟΓΗ: independent n-of-m ML-DSA multisignature (ΟΧΙ threshold)

**Ρητή επιλογή (POST-C2 correction):** η PQ εξουσιοδότηση Layer-0 είναι **independent
n-of-m ML-DSA multisignature policy**, **ΟΧΙ** threshold construction. Λόγος: το FROST
είναι vetted threshold **μόνο** για Ed25519· **δεν υπάρχει vetted standardized threshold
ML-DSA** (το FIPS 204 είναι single-signer). Ένα threshold ML-DSA θα ήταν **homemade crypto
στο trusted path** — απαγορευμένο (repo law). Άρα η κατασκευή είναι σκόπιμα **ασύμμετρη**:
classical = FROST-Ed25519 3-of-5 (ένα aggregate public key)· PQ = **m ανεξάρτητα** ML-DSA
κλειδιά, ≥n έγκυρες ανεξάρτητες υπογραφές. Κάθε πλευρά χρησιμοποιεί **μόνο** vetted primitive.

```
PQRootSet = { "record": "pq-root-set", "seq": <int monotonic>,
  "members": [ { "kid": <RFC 7638 thumbprint ML-DSA pubkey>, "custody": <domain-id> } × m ],
  "threshold_n": <int, 1 ≤ n ≤ m>,   # m ανεξάρτητες custody/failure domains
  "sig": <υπογεγραμμένο από το ΤΡΕΧΟΝ root-set (bootstrap: out-of-band ceremony), context "mltp3:pq-authorization"> }

PQAuthorization = { "suite": "ML-DSA-65",
  "signatures": [ { "kid": <member kid>, "sig": <ML-DSA over SIGNING_TARGET> } × ≥n distinct ] }
```
- **Canonical detached signing target:** `sig_i = ML-DSA(member_i,
  "mltp3:pq-authorization" ‖ 0x1F ‖ canonical(SIGNING_TARGET))` όπου `SIGNING_TARGET` = το
  Layer-0 statement **εξαιρώντας ΚΑΘΕ πεδίο υπογραφής (classical ΚΑΙ PQ) και κάθε `*_id`**
  — **κανένα signature-over-signature, κανένας κύκλος** (§4.2 κανόνες 1–2). Κάθε member
  υπογράφει τα **ίδια** bytes ανεξάρτητα· καμία aggregation.
- **Root-set policy (hybrid epoch):** ένα Layer-0 statement είναι έγκυρο ⇔ **classical
  FROST-Ed25519 threshold sig ΕΓΚΥΡΗ ΚΑΙ ≥n διακριτές ML-DSA member υπογραφές έγκυρες**
  (AND). PQ-only epoch: μόνο ≥n PQ. Legacy epoch: μόνο classical (+ renewal §14.5).
- **Rotation:** νέο `PQRootSet` με `seq+1`, υπογεγραμμένο από το τρέχον root-set (hybrid:
  classical+PQ)· ιστορικά statements κρατούν το **τότε** member set (versioned precedence §4.5).
- **Revocation:** per-member — compromised member ⇒ `RevocationStatement` (§9)· αν έγκυρα
  members < n ⇒ το root-set θεωρείται compromised και ανασυστήνεται με ceremony.
- **Downgrade behavior:** λιγότερες από n έγκυρες PQ member υπογραφές σε hybrid epoch ⇒
  `pq-authorization-insufficient`, **ποτέ VERIFIED**· ελλείπουσα classical ⇒ ως §10.2.
- **Verifier rules:** (1) verify classical aggregate έναντι pinned classical root· (2)
  verify ≥n διακριτές ML-DSA sigs έναντι pinned `PQRootSet`· (3) και οι δύο πάνω στα
  **ταυτόσημα** `SIGNING_TARGET` bytes· (4) καμία υπογραφή δεν είναι μέρος του
  `SIGNING_TARGET` (acyclic). Το `PQRootSet` πινιέται out-of-band μαζί με το classical root
  (LocalTrustState / `MLTPProfileManifest`). Καμία μονή αλγοριθμική οικογένεια δεν κρατά το
  Layer 0 στην hybrid εποχή.

### 14.5 Migration χωρίς επανεγγραφή ιστορικών αντικειμένων + evidence renewal
Τα ιστορικά αντικείμενα **δεν** ξαναγράφονται· διατηρούν τις αρχικές υπογραφές τους. Η
συνέχιση εμπιστοσύνης τους γίνεται με **archival re-anchoring**:
```
EvidenceRenewalStatement = { "record": "evidence-renewal", "renews": "sha256:<digest ιστορικού object>",
  "prev_renewal": "sha256:<hex>" | null,   # αλυσίδα ανανεώσεων
  "fresh_suite": <suite_id>, "fresh_tsr": <RFC-3161 TSR με fresh suite>,
  "renewed_at": <legal-instant>, "sig": <root/delegated, context "mltp3:evidence-renewal"> }
```
Πρότυπο: ERS/LTA long-term signature renewal — ένα φρέσκο-suite timestamp+υπογραφή πάνω
στο digest του ιστορικού αντικειμένου **ΠΡΙΝ** η παλιά suite γίνει `sunset`, επεκτείνει την
αποδεικτική ζωή **χωρίς** αλλοίωση του αντικειμένου. Αλυσίδα renewals (`prev_renewal`)
γεφυρώνει εποχές.

### 14.6 Verifier behavior ανά εποχή (legacy / hybrid / PQ-only)
| εποχή αντικειμένου | κανόνας verifier |
|---|---|
| legacy (classical-only) | δεκτό **μόνο** με έγκυρη αλυσίδα renewal αγκυρωμένη πριν το `sunset_at`· αλλιώς `evidence-expired-algorithm` (UNKNOWN, ποτέ VERIFIED) |
| hybrid | απαιτούνται classical **AND** pq (§14.3) |
| PQ-only | απαιτείται pq· classical προαιρετική/αγνοείται |
Χωρίς αλυσίδα renewal για object που στηρίζεται σε `sunset` suite μετά το `sunset_at` ⇒
`evidence-expired-algorithm`.

### 14.7 Transparency-log & witness continuity across migrations
Το tlog και τα witness checkpoints (§10.1) **μεταναστεύουν** ρητά: σε hybrid epoch τα
`SignedCheckpoint` co-signed classical+PQ· consistency proof **γεφυρώνει** pre/post
migration roots· witness registry entries φέρουν `suite`· witness που δεν co-signs στην
απαιτούμενη suite **δεν** μετρά για τη νέα εποχή. SCITT (§11) προβολή με PQ COSE
algorithms (RFC 9053 + PQ registrations) — χωριστή υπογραφή, όχι relabeling.

### 14.8 Compromise & revocation semantics (per-algorithm)
Ένα αλγοριθμικό σπάσιμο είναι **class-wide compromise**: root-signed `CryptoPolicyEpoch`
με το suite σε `forbidden` ακυρώνει κάθε **ΝΕΑ** στήριξη σε αυτό (ανάλογο §9 key-compromise,
αλλά **ανά αλγόριθμο**, όχι ανά κλειδί). Ιστορικά αντικείμενα επιβιώνουν **μόνο** μέσω
renewal chains αγκυρωμένων **πριν** το σπάσιμο. Διακριτό από key-compromise (ανά κλειδί).

### 14.9 Extension error taxonomy (διακριτή από §4.3· κάθε όνομα έχει βήμα verifier §14.6/§14.4)
```
suite-mismatch · algorithm-downgrade · suite-below-policy · pq-signature-missing ·
pq-signature-invalid · pq-authorization-insufficient · evidence-expired-algorithm ·
stale-crypto-policy-epoch · unrenewed-legacy-evidence
```
Ontology extension taxonomy (§2.11): `ontology-unbound · ontology-evidence-mutated ·
ontology-conflict · shapes-digest-mismatch · unadopted-ontology-bundle`. Οι δύο extension
taxonomies είναι **διακριτές** από τη core §4.3 «35 ονόματα» (η core αμετάβλητη)· κάθε
όνομα έχει ονομαστικό βήμα εκπομπής στην έδρα του (§14.4/§14.6, §2.11).
**Απορρίψεις:** κανένα PQ signature στον πυρήνα ΔΕΝ επιβάλλεται *σήμερα* — η προεπιλογή
epoch παραμένει `era-2` (Ed25519)· η hybrid εποχή **ενεργοποιείται με ρητή πράξη** όταν το
threat model (Θ15) το απαιτεί. Design-only· καμία υλοποίηση.

## 15. APPENDIX — SPEC v1.5 NARROW-DELTA · D3 EVIDENCE-BACKED INDEPENDENCE QUORUMS (CANDIDATE · NOT FROZEN)

**Additive· frozen v1.4 περιεχόμενο (§0–§14) αμετάβλητο· frozen commit `88129099` δεν γίνεται amend.**
Full spec `CHANGE-PROPOSAL-v1.5.md §3` + `§11.4` (type-closure micro-pass)· machine-readable
`V1.5-SCHEMAS.sexp`. **Μία** quorum έδρα — καμία δεύτερη. Τρία διακριτά objects στο
LocalTrustState/qualification layer (D3 type-closure):

**(1) Assurance stratification** — `IndependenceAssuranceProfile` (χωριστό από το D1 semantic profile):
`IA-0 DECLARED` (self-declared· **ποτέ** δεν μετρά υπό strict), `IA-1 ATTESTED` (third-party attested),
`IA-2 CRYPTO_BOUND` (cryptographic identity + custody). Η αντικατάσταση του κοινού
`SemanticAdmissionAssuranceProfile` κλείνει το D3.1.

**(2) Κρυπτογραφικά δεσμευμένο evidence** — `ActorIndependenceEvidence/1` δεσμεύει:
`actor_identity · actor_kid · actor_public_key · control_domain_id · evidence_subject_digest ·
evidence_issuer · evidence_type · assurance_profile · valid_from · valid_to ·
legal_beneficial_control_evidence · privileged_administration_evidence · key_custody_evidence ·
infrastructure_dependency_evidence · conflict_of_interest_evidence · digest · signature · revocation_ref`.
Invariant `V5I-D3-bind`: η `signature` **ΠΡΕΠΕΙ** να καλύπτει canonical body που δένει
`actor_identity + actor_kid + actor_public_key + control_domain_id + evidence_subject_digest`· evidence
που δεν είναι έτσι δεμένο ⇒ αγνοείται (`INDEPENDENCE_UNKNOWN` υπό strict). Κλείνει το D3.2 (η ταυτότητα
actor, το `kid`/public key, το control/custody domain και το evidence subject δένονται κρυπτογραφικά).
**F4 (ποιος υπογράφει + επιλογή κλειδιού):** το `ActorIndependenceEvidence/1` υπογράφεται από τον issuer
του `evidence_issuer`· κλειδί επαλήθευσης = το `IssuerEntry.issuer_public_key` που επιλύεται με `issuer_id`
στο **pinned** registry· self-issued (`evidence_issuer = actor_identity`) = IA-0 και **δεν** μετρά ως
ανεξάρτητη βεβαίωση (invariant `V5I-D3-issuer-signing`).

**(2b) Normalized per-dimension input (F4)** — ένα `control_domain_id` **δεν** εκφράζει όλες τις
`IndependenceDimension` σχέσεις· ο partition καταναλώνει typed `DomainAssertion/1`
(`dimension · subject_actor_id · subject_kid · normalized_domain_id ·
relation(:same-domain|:distinct-domain|:unknown) · source_evidence_ref · issuer_id · valid_from · valid_to ·
revocation_ref · digest · signature`), **μία ανά (actor,dimension)**· το `control_domain_id` είναι
convenience summary, **ποτέ** input (invariant `V5I-D3-domainassertion`).

**(3) Typed trusted issuer registry (F4· versioned + content-addressed + pinned)** —
`TrustedIssuerRegistry/1` (`registry_id = hash(BODY) · version · entries · supersedes · digest · signature`)
+ `IssuerEntry/1` (`issuer_id · issuer_public_key · issuer_authority(list IndependenceDimension) · scope ·
delegated_from · valid_from · valid_to · revocation_ref`). **Pinned** από
`LocalTrustState.independence_issuer_registry_ref` (content-addressed `registry_id`)· authenticity υπό
LocalTrustState-pinned root· **monotonic** update (`supersedes`)· ένα delivered bundle **δεν** αλλάζει το
pinned registry (rule `trusted-issuer-registry-pinning`). Το `revocation_ref` είναι **required** όταν η
αποδεχόμενη `IssuerEntry`/`IndependencePolicy` δηλώνει ότι ο issuer υποστηρίζει revocation· verify
semantics: resolve revocation source, αν δείχνει revoked στο `t_use` ⇒ **δεν** μετρά· **fail-closed** —
evidence με μη επιλύσιμο revocation status ⇒ `UNKNOWN` (ποτέ σιωπηλά μετρημένο). Κλείνει τα D3.3/D3.4.

`IndependencePolicy/1` ορίζει: `required_distinct_dimensions · prohibited_shared_dimensions ·
accepted_issuer_registry_ref (→ TrustedIssuerRegistry/1) · evidence_freshness ·
min_independence_assurance · unknown_handling · quorum`. `unknown_handling ∈ {FAIL_CLOSED, DEGRADE}` με
**αυστηρή** σημασιολογία: unknown evidence **ποτέ** δεν μετρά προς strict quorum· `DEGRADE` μειώνει το
attainable assurance profile αντί να προσποιείται γνώση (D3.6).

**Control-domain partition (D3.5· F4)** — ντετερμινιστικός `control-domain-partition` αλγόριθμος που
καταναλώνει typed `DomainAssertion/1`: union-find· ακμή μεταξύ actors με `:same-domain` σε **ίδιο**
`normalized_domain_id` για prohibited dimension (proven)· κάθε `:unknown`/missing shared status **προσθέτει
ακμή** (fail-closed: potentially-shared) υπό FAIL_CLOSED (ίδια είσοδος ⇒ ίδιες equivalence classes). Το
τελικό quorum μετρά **διακριτά control-domain components**, όχι διακριτά `kid` — δύο actors στο ίδιο
control domain μετρούν ως **ένας**.

Κανόνες (αμετάβλητοι): διαφορετικά `kid` δεν αποδεικνύουν ανεξαρτησία· self-signed independence
declaration δεν μετρά· expired/revoked evidence δεν μετρά· ανεπαρκές evidence ⇒ `INDEPENDENCE_UNKNOWN`·
ο **consumer-local** verifier αποφασίζει την policy· το Ίδρυμα/οι auditors δεν αυτοπιστοποιούν την
ανεξαρτησία τους· shared provider/cloud δεν έχει **καθολικό** αποτέλεσμα — αξιολογείται ανά assurance
profile και control domain.

Το υπάρχον §10 mesh quorum παραμένει **μία** έδρα· η predicate εκφράζεται **κανονιστικά + machine-readable**
(`mesh-independence-quorum`, `define-quorum-predicate`) και αλλάζει **μόνο** από `distinct-valid-kids` σε
`distinct-control-domain-components(valid, assurance>=policy) >= required`. Invariants
V5I-06/V5I-07/V5I-D3-bind· kill witnesses V5KW-D3-1..6 **και** V5KW-D3-7..12 (assurance-strip,
unbound-evidence, cross-issuer-authority, unresolved-revocation, shared-control-collapse, degrade-abuse).
Design-only· καμία υλοποίηση· ο executable core αμετάβλητος.
