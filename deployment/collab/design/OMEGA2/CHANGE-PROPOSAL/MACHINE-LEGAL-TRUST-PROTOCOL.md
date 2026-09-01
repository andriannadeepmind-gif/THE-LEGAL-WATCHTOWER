# MACHINE LEGAL TRUST PROTOCOL (MLTP) v2 — ΤΡΙΑ ΕΠΙΠΕΔΑ, TYPED CLAIMS, ΠΡΑΓΜΑΤΙΚΟ CRYPTO PROFILE
# Υποσύστημα του `CHANGE-PROPOSAL-v1.3.md §3-4` — ΟΧΙ δεύτερη αρχιτεκτονική

**Design only.** Semantic-closure αναθεώρηση της v1 (η v1 είχε γνωστές εσωτερικές
αντιφάσεις: self-asserted `verification_result`, hash-only verification αντί signature verification,
ελεύθερο `claim` string, TrustBundle-ως-certificate, κοινά temporal fields παντού,
απόλυτη revocation). **Καμία υλοποίηση, κανένα destruction pass, καμία αξίωση
qualification.** Κάθε πεδίο ανάγεται σε υπάρχουσα έδρα (PCL/census-2/attestation/
checkpoint/trust-bootstrap/key-lifecycle/USC).

**Θεμελιώδης διαχωρισμός (κλείνει το «issuer self-verdict» finding):**

```
Layer A  IssuedClaim          — ο EKΔΟΤΗΣ υπογράφει έναν typed claim + proof material.
                                ΠΟΤΕ δεν γράφει «VERIFIED». ΠΟΤΕ δεν αυτοχαρακτηρίζει assurance.
Layer B  TrustBundle          — CONTAINER μεταφοράς. Δεν ισχυρίζεται τίποτα· μεταφέρει.
Layer C  VerificationReceipt  — ο ΤΟΠΙΚΟΣ verifier/auditor παράγει το ΑΠΟΤΕΛΕΣΜΑ.
                                Δεν υπογράφεται ποτέ από τον εκδότη ως αυτο-ετυμηγορία.
```

Ο αριθμός των profiles **δεν είναι στόχος** (η v1 κυνηγούσε «7»)· στόχος είναι η
**σημασιολογική πληρότητα**.

---

## 1. LAYER A — `IssuedClaim` (υπογεγραμμένος typed claim)

### 1.0 Envelope — ΜΟΝΟ ό,τι ισχύει για ΚΑΘΕ profile (κανένα temporal εδώ)

```
{ "mltp": "2",
  "layer": "IssuedClaim",
  "claim_type": <ΚΛΕΙΣΤΟ sum — §1.1· ΠΟΤΕ ελεύθερο string>,
  "profile": <το id του typed payload schema του claim_type>,
  "payload": <TYPED, κλειστό ανά profile — §2· ΤΟ ΜΟΝΟ input της επαλήθευσης>,
  "proof_material": <το αναπαραγώγιμο αντικείμενο απόδειξης — Merkle path,
                     attestation, snapshot-manifest κ.λπ., ανά profile>,
  "issuer": { "authority_id" | "verifier_id" },
  "signature": { "alg": <"RS256" | "Ed25519">, "kid",
                 "delegation_seq", "key_lineage": [...],
                 "sig": <base64url — §4 signature payload> },
  "issued_at": { "trusted_time": <legal-instant>,
                 "anchor": <tsr_sha256 (RFC-3161) | tlog_leaf_index> },   # ΑΞΙΟΠΙΣΤΟΣ χρόνος υπογραφής — §9
  "qualification_state_ref": <id ενός QualificationStateRecord §3· ΠΟΤΕ inline level>,
  "description": <ΠΡΟΑΙΡΕΤΙΚΟ ανθρώπινο κείμενο — ΠΟΤΕ input επαλήθευσης> }
```

**Ρητοί κανόνες:**
- **ΚΑΝΕΝΑ `verification_result` σε IssuedClaim** — το αποτέλεσμα ζει στο Layer C.
- **`issued_at` = trusted signature-time anchor** (TSR ή tlog leaf), **ΟΧΙ**
  self-declared timestamp. Η ανάκληση (§9) ελέγχεται **έναντι αυτού**, ποτέ έναντι
  γενικού legal effective-time του payload. Χωρίς αξιόπιστο anchor ⇒ ο verifier
  δεν μπορεί να τοποθετήσει την υπογραφή στον χρόνο ⇒ `UNKNOWN`.
- **ΚΑΝΕΝΑ inline `assurance_level`** — μόνο `qualification_state_ref` προς
  ξεχωριστό, υπογεγραμμένο `QualificationStateRecord` (§3) με evidence + expiry.
- **Το `description` (ελεύθερο κείμενο) ΔΕΝ διαβάζεται ποτέ από τον verifier.** Ο
  verifier δρα **μόνο** στο typed `payload`.
- **Temporal fields ΜΟΝΟ όπου ισχύουν** (§2 per-profile), όχι στο envelope.

### 1.1 `claim_type` — ΚΛΕΙΣΤΟ sum (semantic completeness, όχι αριθμός)

```
source-authenticity | legal-state | temporal-projection |
coverage-and-freshness | judgment-identity-and-text |
jurisprudential-analysis | legal-object-correction-or-withdrawal |
trust-key-or-delegation-revocation
```

Επέκταση = **νέο profile με typed payload + spec έγκριση**, ποτέ ελεύθερο string
(πρότυπο USC versioned registry).

---

## 2. TYPED PAYLOADS ΑΝΑ PROFILE (temporal μόνο όπου ισχύει)

Στήλη «temporal»: ✔ = φέρει `(valid_time, known_time)`· ✘ = **δεν** φέρει (δικά του
πεδία χρόνου).

### 2.1 `source-authenticity` · temporal: ✘ (χρόνος = acquisition/anchor)
```
payload = { "raw_artifact": {"digest_algorithm":"sha256","digest","byte_length"},
            "acquisition_receipt_id": "acq1:…",              # USC §5.1 (origin sum)
            "authority_id": "auth1:…",                       # USC §2.2
            "institutional_register_id": "ireg1:…",          # USC §2.1β
            "authority_proof_ref": <authority-proof-bundle/1>,# USC §0.1
            "acquired_at": <legal-instant>,
            "time_anchor": {"tsr_sha256","tlog_leaf_index"} | null,  # RFC-3161 = ΜΟΝΟ χρόνος
            "divergence_ref": <official-sources-conflict uncertainty> | null }
```
**Κανόνας:** RFC-3161 μόνο ⇒ ΑΝΕΠΑΡΚΕΣ· χωρίς `authority_proof_ref` ΚΑΙ
`institutional_register_id` ο local verifier παράγει `UNKNOWN` (§4 error `insufficient-provenance`).

### 2.2 `legal-state` · temporal: ✔
```
payload = { "work_id":"lsw1:…", "expression_id":"lse1:…",
            "valid_time": <legal-date | {from,to}>, "known_time": <legal-instant>,
            "legal_state": <"IN" | "OUT" | "UNDEC">,        # UNDEC ⇒ local verifier: UNKNOWN
            "attestation_id":"lsa1:…", "knowledge_checkpoint_id":"kchk1:…" }
proof_material = { "pcl_inclusion": <PCL path ≤64>, "uncertainty_roots": {...} }
```

### 2.3 `temporal-projection` · temporal: ✔
```
payload = { "body", "valid_time","known_time",
            "release_root": "sha256:…" }                     # §5 ΜΟΝΗ authority root
proof_material = { "snapshot_manifest": <version-graph snapshot-at + per-step fold>,
                   "census_temporal": {graph_root,receipt_set_root,valid_at,known_at} }
```

### 2.4 `coverage-and-freshness` · temporal: ✔ (known_time = «ως πότε ξέρω»)
```
payload = { "space": <π.χ. "fek/A">, "known_time",
            "coverage_ledger_root": <ΝΕΟ ΚΕΝΟ — national census, AS-IS R-1>,
            "freshness": {"as_of","max_staleness"},
            "gaps": [ {"position","state":"UNKNOWN","first_observed_at"} ] }
```

### 2.5 `judgment-identity-and-text` · temporal: ✔ — SOURCE-VERIFIABLE (νομολογία #7α)
```
payload = { "work_id":"lsw1:… (judgment domain)", "ecli" | "provisional_id",
            "court","chamber","formation","jurisdiction_level",
            "number","year","decision_date","publication_date",
            "anonymization": {"status","provenance"},
            "valid_time","known_time" }
proof_material = { "source_seal": <acquisition + PCL inclusion των bytes> }
```
**Μόνο ό,τι επαληθεύεται από την πηγή.** Καμία ερμηνεία εδώ.

### 2.6 `jurisprudential-analysis` · temporal: ✔ — INSTITUTIONAL ATTESTATION (νομολογία #7β)
```
payload = { "judgment_ref": <2.5 work_id>,
            "ratio": [ {"claim","passage_anchor":{artifact_digest,start,end}} ],
            "obiter":[ {...passage_anchor} ],
            "holding","legal_issue","disposition",
            "separate_opinions":[ {"kind":"dissent|concurrence","passage_anchor"} ],
            "authority_weight": {"value","basis":"Ολομέλεια>Τμήμα | count | consistency"},
            "later_treatment":[ {"relation":<USC §6.3 kind>,"target"} ],
            "attribution": <actor-ref του θεσμικού συντάκτη>,
            "methodology_version": <pinned>,
            "reviewer_adoption_act": <signed adoption record>,
            "typed_uncertainty":[ <USC §8 kinds> ] }
```
**Δομικοί κανόνες:** κάθε ratio/holding **αγκυρωμένο σε passage_anchor** (`PLANE-0`)·
**attribution + methodology_version + reviewer_adoption_act ΥΠΟΧΡΕΩΤΙΚΑ**· **raw AI
inference (`PLANE-3`) ΠΟΤΕ ως θεσμικά πιστοποιημένο ratio** (μπορεί μόνο ως
`typed_uncertainty` πρόταση προς reviewer). Χωρίς reviewer_adoption_act ⇒ ο local
verifier το επιστρέφει ως `UNVERIFIED_FOR_MACHINE_RELIANCE`, όχι ως πιστοποιημένο.

### 2.7 `legal-object-correction-or-withdrawal` · temporal: ✔ (νομικό αντικείμενο)
```
payload = { "subject": <work_id | expression_id>,
            "transition": <"SUPERSEDED" | "WITHDRAWN" | "CORRECTION">,
            "authority_id", "effective_valid_time","known_time",
            "supersedes" | "superseded_by",
            "uncertainty_resolution_ref": <USC §8>, "relation_retract_ref": <USC §6.3> }
```
**Καμία διαγραφή**· ανακληθέν ορατό στη διτεμπορική του τομή.

### 2.8 `trust-key-or-delegation-revocation` · temporal: ✘ — ΞΕΧΩΡΙΣΤΟ από 2.7 (#6, #9)
```
payload = { "revoked_subject": <kid | delegation_seq>,
            "revocation_reason": <"superseded" | "key-compromise" |
                                  "delegation-expired" | "policy">,
            "revoked_at": <legal-instant>,
            "compromise_known_at": <legal-instant> | null,   # μόνο σε key-compromise
            "invalid_from": <legal-instant>,                 # §9 retroactivity
            "replacement_kid": <kid> | null }
```
**ΔΙΑΦΟΡΕΤΙΚΟ αντικείμενο από 2.7:** εδώ ανακαλείται **κλειδί/εξουσιοδότηση**, εκεί
**νομικό αντικείμενο**. Δεν συγχωνεύονται (v1 σφάλμα).

---

## 3. `QualificationStateRecord` — assurance ΩΣ ΞΕΧΩΡΙΣΤΟ ΥΠΟΓΕΓΡΑΜΜΕΝΟ RECORD (#2)

```
{ "mltp":"2", "record":"QualificationStateRecord",
  "subject": <τι αφορά>,
  "level": <"spec-qualified" | "implementation-qualified" |
            "mission-qualified" | "provider-adoption-qualified" | "none">,
  "evidence_refs": [ <ids τεκμηρίων/receipts/audits — ΚΑΘΟΡΙΣΜΕΝΟ σύνολο ανά level> ],
  "auditor_receipts": [ <VerificationReceipt/audit receipts ΑΝΕΞΑΡΤΗΤΩΝ auditors> ],
  "provider_attestations": [ <εξωτερικές provider attestations/μετρήσεις — μόνο για provider-adoption> ],
  "issued_at": {"trusted_time","anchor"},                   # trusted anchor, όπως §1.0
  "expiry",                                                 # καμία βαθμίδα μόνιμη (Q28)
  "signer": {"role": <"independent-auditor" | "auditor-quorum" | "provider-registry">,
             "alg","kid","sig"} }
```

**Ποιος επιτρέπεται να εκδίδει κάθε level (κλείνει την έμμεση αυτοπιστοποίηση):**

| level | επιτρεπόμενος signer role | υποχρεωτικό evidence |
|---|---|---|
| `spec-qualified` | independent-auditor (≥1) | destruction-pass adjudication record + consistency-audit output |
| `implementation-qualified` | auditor-quorum (≥2 ανεξάρτητοι) | Q01–Q28 auditor receipts, proposer-blind re-derivation |
| `mission-qualified` | auditor-quorum (≥2) | MISSION GREECE-1 auditor receipts (Μ-1…Μ-6) + independent source census |
| `provider-adoption-qualified` | provider-registry (εξωτερικό) | provider attestations/μετρήσεις — **όχι** δικές μας |
| `none` | — | — |

- **Ο release issuer ΔΕΝ μπορεί να υπογράψει QualificationStateRecord για τον
  εαυτό του.** Signer με role `release-issuer` ή kid της release-authority ⇒ error
  `unauthorized-qualification-issuer`. Τα `evidence_refs` **πρέπει** να αναλύονται σε
  `auditor_receipts` ανεξάρτητων auditors (LocalTrustState auditor registry, §8).
- Ο verifier ελέγχει: signer **role** επιτρεπτό για το level · **evidence set**
  παρόν και επιλύσιμο · **quorum** (≥2 όπου απαιτείται) · **freshness** (issued_at
  anchor) · **expiry**. Οποιοδήποτε λείπει ⇒ level = `none`.
- Οι IssuedClaims **δείχνουν** εδώ (`qualification_state_ref`), **ποτέ** δεν
  αυτοχαρακτηρίζονται. Dangling ref (δεν επιλύεται στο bundle) ⇒
  `dangling-qualification-ref` ⇒ level `none`. Λήξη `expiry` ⇒ `none`.

---

## 4. CRYPTOGRAPHIC PROFILE — ΠΡΑΓΜΑΤΙΚΟ (κλείνει το «only SHA-256» finding)

**Δύο διακριτές πρωτόγονες λειτουργίες — ΠΟΤΕ συγχεόμενες:**

| λειτουργία | αλγόριθμος | που |
|---|---|---|
| **Hashing / Merkle inclusion** | **SHA-256**, RFC 9162 profile `lawmax-merkle-sha256-v1` (leaf `0x00`, node `0x01`, unbalanced split, no-duplicate-last) | inclusion proofs, roots, `*_id` |
| **Signatures** | **RS256** (υφιστάμενο PCL profile) **· δηλωμένη μετάβαση → Ed25519** (key-lifecycle §2.1, `kid`+`alg`+`key_lineage`) | corpus-proof JWS, delegation, witness checkpoints, QualificationStateRecord |

> **Η επαλήθευση υπογραφής ΑΠΑΙΤΕΙ RS256/Ed25519 primitive — ΟΧΙ «μόνο SHA-256».**
> Το «μόνο SHA-256» ισχύει **αποκλειστικά** για τον έλεγχο **inclusion** (PCL §5),
> όχι για signatures/delegation/witnesses. Ο ελεγκτής είναι μικρός (LOC-ceiling,
> PROOF-OBJECT §4) αλλά **δεν** είναι hash-only: φέρει έναν RS256 (ή Ed25519)
> verifier. Αυτό κλείνει την αντίφαση της v1 με PCL RS256 + trust-bootstrap delegation.

**Canonical encoding:** `deployment/verify/canonical-serialization-spec.md` —
deterministic JSON, sorted keys, NFC, LF, χωρίς floats, ρητά type tags, διαχωριστικά
`0x1F` για συνθέσεις hash (TEMPORAL-IDENTITY §1.0).

**Domain separation:** Merkle leaf `0x00` / node `0x01`· επιπλέον **context string**
ανά τύπο signature payload (π.χ. `"mltp2:release-root"`, `"mltp2:delegation"`,
`"mltp2:witness-checkpoint"`, `"mltp2:qual-state"`) ώστε υπογραφή ενός τύπου να μη
γίνεται δεκτή ως άλλου.

**Algorithm identifiers:** κάθε signature φέρει `alg` ∈ {`RS256`,`Ed25519`} + `kid`.
Άγνωστο `alg` ⇒ error `unknown-alg` (fail-closed, ποτέ «try next»).

**Signature payload (ρητά):** `sig = SIGN(kid, context_string ‖ 0x1F ‖ canonical_bytes(target))`
όπου `target` = το ρητά δηλωμένο αντικείμενο (π.χ. release_root string, delegation
statement, witness checkpoint). Ο verifier ξαναχτίζει το ίδιο payload και ελέγχει.

**Error taxonomy (κλειστή, ονομαστική):**
`text-hash-mismatch · inclusion-failed · path-too-long · root-mismatch ·
untrusted-key · unknown-alg · sig-invalid · delegation-invalid · delegation-expired ·
delegation-scope-violation · consistency-failed · split-view · expired · revoked ·
retroactively-revoked · untrusted-registry · dangling-qualification-ref ·
unauthorized-qualification-issuer · insufficient-provenance · unknown-claim-type ·
unadopted-analysis · UNKNOWN_FRESHNESS · UNKNOWN(reason)`.

- `delegation-scope-violation`: έγκυρο delegated key υπογράφει claim με `claim_type`
  **εκτός** του `scope` της delegation του.
- `untrusted-registry`: embedded witness/auditor registry που **δεν** επιλύεται μέσω
  `LocalTrustState`/pinned root.
- `UNKNOWN_FRESHNESS`: η υπογραφή επαληθεύεται ιστορικά, αλλά **χωρίς** αξιόπιστο
  current-time evidence δεν κρίνεται freshness/expiry ⇒ **ποτέ `VERIFIED`**.

**Delegation / witness signature verification:** root key (out-of-band pinned)
υπογράφει delegation statements (scope, not-before/after, seq) — RS256/Ed25519·
witnesses υπογράφουν checkpoints· ο verifier ελέγχει ΚΑΘΕ υπογραφή με το αντίστοιχο
δημόσιο κλειδί (root pinned out-of-band, witness keys από witness registry).

---

## 5. CANONICAL ROOTS — ΜΙΑ AUTHORITY ROOT (κλείνει τη σύγκρουση #5)

`LAWMAX-TEMPORAL-IDENTITY-DESIGN.md §1.5/§8 (PCL-02)` ορίζει ρητά: **«Μία ρίζα:
receipt-set-root + graph-root ΜΕΣΑ στο canonical set → release root → TSR → tlog.
Το `pcl_text_root` πεθαίνει· cross-check στο spine verify.»** Ενώ το
`LAWMAX-PROOF-OBJECT-SPEC.md §2 (census-2)` **ακόμη περιέχει** πεδίο `pcl_text_root`.

**Επίλυση (target + versioned legacy migration):**
- **TARGET authority root = `release_root`** (era-2): το canonical-set root που
  δεσμεύει `receipt_set_root` + `graph_root`, σφραγισμένο με TSR + tlog. **Η ΜΟΝΗ**
  ρίζα αυθεντίας. Κάθε MLTP `temporal-projection` / `TrustBundle` δείχνει σε αυτήν.
- **`pcl_text_root` = LEGACY CROSS-CHECK, όχι authority root.** Παραμένει στο
  census-2 **μόνο** ως era-1 συμβατότητα και ως **spine cross-check** (μη
  authoritative). Σημασιολογία ρητή: era-1 releases = `trust-status :legacy-sealed`·
  το πρώτο era-2 census δεσμεύει `prev_release_root` και η tlog αλυσίδα συνεχίζεται
  (TEMPORAL-IDENTITY §5/M0).
- **Καμία optional δεύτερη authority root χωρίς σημασιολογία.** Ένα `pcl_text_root`
  που παρουσιάζεται ως authority root ⇒ error `root-mismatch`.

**Versioned legacy migration profile:** `release_profile ∈ {era-1-legacy, era-2}`·
ο verifier επιλέγει κανόνες κατά `release_profile`· era-1 verify δέχεται
`pcl_text_root` ως cross-check, era-2 verify το αγνοεί ως authority.

---

## 6. LAYER B — `TrustBundle` (CONTAINER, ΟΧΙ certificate)

```
{ "mltp":"2", "layer":"TrustBundle",
  "issued_claims": [ <IssuedClaim §1> ],
  "census": <census-2 (materials in-toto)>,
  "release_anchor": <trust-bootstrap tra/3: owner_root_fingerprint,
                     delegation_seq, witness_checkpoints>,
  "delegation_chain": [ <root→delegate statements, ΚΑΘΕ ΕΝΑ με scope> ],
  "transparency": { "log_id","tree_size","log_root","consistency_from" },
  # ---- ΠΛΗΡΩΣ OFFLINE-RESOLVABLE: περιλαμβάνει Ή δεσμεύει με inclusion proofs ----
  "qualification_records": [ <QualificationStateRecord §3 για κάθε qualification_state_ref> ],
  "auditor_receipts":      [ <VerificationReceipt/audit evidence ανεξάρτητων auditors> ],
  "revocation": { "records": [ <trust-key-or-delegation-revocation IssuedClaims> ],
                  "checkpoint": <τρέχον revocation checkpoint + tlog inclusion> },
  "witness_checkpoints":   [ <signed checkpoints των transparency witnesses> ],
  "embedded_registries":   { "witness_keys": [...], "auditor_keys": [...] }   # UNTRUSTED μέχρι επίλυση
}
```
**Το TrustBundle δεν ισχυρίζεται τίποτα από μόνο του — μεταφέρει.** Δεν φέρει
`verification_result`, δεν φέρει claim.

**Κανόνες offline-resolvability (#4):**
- Κάθε `qualification_state_ref` **πρέπει** να επιλύεται σε `qualification_records`
  του ίδιου bundle (ή με inclusion proof στο tlog) — αλλιώς `dangling-qualification-ref`.
- Auditor receipts, revocation records + current revocation checkpoint, witness
  checkpoints: **μέσα** ή **δεσμευμένα με inclusion proof** — ποτέ «κάπου αλλού».
- **Embedded keys/registries είναι UNTRUSTED** μέχρι να επιλυθούν μέσω
  `LocalTrustState` (witness-key registry, auditor registry) ή μέσω pinned owner
  root (delegation). Embedded registry χωρίς επίλυση ⇒ `untrusted-registry`· ένας
  witness που υπάρχει **μόνο** στο bundle **δεν** μετρά για quorum.

Ένας καταναλωτής το τροφοδοτεί στον local verifier (§8) με το δικό του
`LocalTrustState` και **παράγει** `VerificationReceipt`.

---

## 7. LAYER C — `VerificationReceipt` (τοπικό αποτέλεσμα, ΟΧΙ issuer-signed)

```
{ "mltp":"2", "layer":"VerificationReceipt",
  "bundle_digest": "sha256:…",
  "checks": [ {"name":<§4 error taxonomy name ή "ok">, "profile", "result"} ],
  "result": <"VERIFIED" | "UNVERIFIED_FOR_MACHINE_RELIANCE" | "UNKNOWN">,
  "reason": <ονομαστικό, όταν όχι VERIFIED>,
  "verifier": {"id","version","kernel_diversity": <#ανεξάρτητων υλοποιήσεων>},
  "produced_at": <legal-instant>,
  "local_signature": {"alg","kid","sig"} | null }        # ΤΟΥ VERIFIER, ποτέ του issuer
```
**Το αποτέλεσμα το παράγει ο καταναλωτής, όχι ο εκδότης.** Ο εκδότης δεν μπορεί να
προ-δηλώσει «VERIFIED». Αν ο verifier υπογράψει, υπογράφει **ως verifier** (δικό του
receipt), ποτέ ως αυτο-ετυμηγορία του εκδότη.

---

## 8. OFFLINE VERIFIER — ΤΟ ΣΥΜΒΟΛΑΙΟ

Έδρα: PCL §5-6 (inclusion, SHA-256) + RS256/Ed25519 verifier (§4) + PROOF-OBJECT §4
(LOC-ceiling, kernel diversity).

### 8.1 `LocalTrustState` — ό,τι ο καταναλωτής φέρνει ΑΠΟ ΜΟΝΟΣ ΤΟΥ (ποτέ από το bundle)

```
LocalTrustState = {
  pinned_owner_root:      <fingerprint του owner-root.pub, out-of-band, ≥2 κανάλια>,
                          # ΤΑΥΤΟΠΟΙΕΙ ΑΠΟΚΛΕΙΣΤΙΚΑ τον OWNER ROOT — ποτέ delegated κλειδί
  witness_key_registry:   <γνωστά δημόσια κλειδιά transparency witnesses>,
  auditor_registry:       <γνωστοί independent auditors + policy quorum ανά level>,
  last_accepted_tlog:     {tree_size, log_root},          # για consistency / split-view
  revocation_state:       <τελευταίο αποδεκτό revocation checkpoint>,
  trusted_time:           { now: <legal-instant> | null,
                            evidence: <TSR/beacon/witness-checkpoint time> | null,
                            clock_uncertainty: <duration> }   # null ⇒ ΚΑΜΙΑ αξίωση freshness
}
```

### 8.2 Αλυσίδα κλειδιών — ΔΙΟΡΘΩΜΕΝΗ (#2)

```
pinned_owner_root ──(signed delegation: scope, not-before/after, seq)──► delegated_key ──(sig)──► IssuedClaim
```
- Το `pinned_owner_root` ταυτοποιεί **αποκλειστικά** τον owner root. Το delegated
  release key έχει **ΔΙΑΦΟΡΕΤΙΚΟ** thumbprint — **ποτέ** δεν συγκρίνεται ως «ίσο με
  το root». Verifier που κάνει `thumbprint(delegated) == pinned_root` είναι **λάθος**
  (θα απέρριπτε κάθε νόμιμο release ή θα δεχόταν κλειδί που παριστάνει root).
- Κάθε delegation φέρει **`scope`** (σύνολο επιτρεπόμενων `claim_type` + `release-signing`
  κ.λπ.). Το scope **ελέγχεται έναντι του `claim_type`** κάθε IssuedClaim που το
  delegated key υπογράφει. Έγκυρο κλειδί, λάθος scope ⇒ `delegation-scope-violation`.

### 8.3 Ψευδοκώδικας — `verify_bundle(bundle, LocalTrustState)`

```
verify_bundle(bundle, lts) -> VerificationReceipt:
  checks = []
  # A. inclusion (SHA-256 μόνο, RFC 9162)
  for c in bundle.issued_claims:
     checks += pcl_inclusion(c.payload, c.proof_material)
  # B. key chain (RS256/Ed25519) — root → delegation → delegated key → claim
  for d in bundle.delegation_chain:
     require sig_verify(d, lts.pinned_owner_root)                 # ΜΟΝΟ ο root υπογράφει delegations
     require d.not_before <= d.signed_time <= d.not_after
  for c in bundle.issued_claims:
     d = delegation_for(c.signature.kid, bundle.delegation_chain) else untrusted-key
     require c.claim_type IN d.scope                                else delegation-scope-violation
     require sig_verify(c.signature, d.delegated_key)              # ΟΧΙ thumbprint == root
  # C. one authority root (§5)
  require bundle.release_anchor.release_root is THE authority root   # pcl_text_root = cross-check μόνο
  # D. registries: embedded = UNTRUSTED μέχρι επίλυση
  witnesses = resolve(bundle.embedded_registries.witness_keys, lts.witness_key_registry)  else untrusted-registry
  auditors  = resolve(bundle.embedded_registries.auditor_keys,  lts.auditor_registry)     else untrusted-registry
  # E. transparency + gossip (split-view) — witnesses μόνο για publication/time/consistency
  require tlog_inclusion(bundle) AND consistency(bundle.transparency, lts.last_accepted_tlog)  else split-view
  require witness_quorum(bundle.witness_checkpoints, witnesses, quorum=2)
  # F. trusted time — ΧΩΡΙΣ αξιόπιστο now, ΚΑΜΙΑ αξίωση freshness (κλείνει KT1)
  if lts.trusted_time.now is null OR lts.trusted_time.evidence is null:
     freshness_verdict = UNKNOWN_FRESHNESS                            # ιστορική υπογραφή ΜΠΟΡΕΙ να επαληθευτεί
  # G. revocation (§9) — έναντι TRUSTED SIGNATURE TIME, όχι legal effective-time
  for c in bundle.issued_claims:
     t_sig = c.issued_at.trusted_time  (anchored)                     else UNKNOWN
     r = lts.revocation_state ∪ bundle.revocation.records  (resolved, checkpointed)
     if revoked(c.signature.kid, r) AND t_sig >= r.invalid_from:  return retroactively-revoked  # fail-closed
  # H. qualification — ΟΧΙ self-qualification
  for c in bundle.issued_claims:
     q = resolve(c.qualification_state_ref, bundle.qualification_records)  else dangling-qualification-ref → level none
     require q.signer.role allowed_for(q.level)                     else unauthorized-qualification-issuer
     require q.signer.kid NOT release-authority kid                 else unauthorized-qualification-issuer
     require evidence_resolves(q.evidence_refs, q.auditor_receipts, auditors, quorum_for(q.level))
     if freshness_verdict == UNKNOWN_FRESHNESS OR now > q.expiry: q.level = none
  # I. analysis claims
  if unadopted(analysis_claims): return UNVERIFIED_FOR_MACHINE_RELIANCE
  # J. result
  if freshness_verdict == UNKNOWN_FRESHNESS: return UNKNOWN_FRESHNESS   # ποτέ VERIFIED χωρίς trusted now
  return VERIFIED
```

**Stopped/rewound clock (KT1):** ο verifier **δεν** εμπιστεύεται ποτέ το τοπικό
ρολόι ως `now`· χρειάζεται `trusted_time.evidence` (TSR/beacon/witness checkpoint
εντός `clock_uncertainty`). Χωρίς αυτό, η **ιστορική** υπογραφή επαληθεύεται
(inclusion + chain), αλλά το αποτέλεσμα είναι **`UNKNOWN_FRESHNESS`, ποτέ `VERIFIED`**.

**Provider-side κανόνας:** αποτυχία οποιουδήποτε βήματος ⇒
`UNVERIFIED_FOR_MACHINE_RELIANCE`/`UNKNOWN` — ποτέ σιωπηλή παρουσίαση ως αυθεντικού
(v1.3 §4.2). **Απορρίψεις** (PROOF-OBJECT §5): ZK-SNARK/STARK, W3C VC/DID ως CORE,
LLM στο trusted path.

---

## 9. REVOCATION SEMANTICS — ΟΧΙ ΑΠΟΛΥΤΟ «pre-revocation stays valid» (#9)

Το «ό,τι υπογράφηκε πριν την ανάκληση παραμένει έγκυρο» ισχύει **μόνο** για
προγραμματισμένη rotation/supersession — **ΟΧΙ** σε key compromise. Κανόνες:

| `revocation_reason` | `invalid_from` | συνέπεια |
|---|---|---|
| `superseded` / `delegation-expired` / `policy` | = `revoked_at` | υπογραφές πριν το `revoked_at` με ανεξάρτητο RFC-3161 χρόνο **παραμένουν έγκυρες** (key-lifecycle §2.5) |
| `key-compromise` | = `compromise_known_at` **ή νωρίτερα** (policy) | υπογραφές μετά το `invalid_from` **ΑΚΥΡΩΝΟΝΤΑΙ ΑΝΑΔΡΟΜΙΚΑ** ακόμη κι αν φέρουν προγενέστερο timestamp· **μόνο** υπογραφές με ανεξάρτητο RFC-3161 χρόνο **πριν** το `invalid_from` επιβιώνουν· ο verifier επιστρέφει `retroactively-revoked` για τις υπόλοιπες |

**Υποχρεωτικά πεδία** (§2.8): `revocation_reason`, `revoked_at`, `invalid_from`,
`compromise_known_at` (για compromise) — **fail-closed**: απόν πεδίο ⇒ η ανάκληση
θεωρείται `key-compromise` με `invalid_from = revoked_at` (η αυστηρότερη ερμηνεία),
ποτέ αγνοείται. Η αναδρομική ακύρωση είναι **ρητή policy**, όχι σιωπηλή — και
δημοσιεύεται ως `trust-key-or-delegation-revocation` IssuedClaim στο tlog (ώστε οι
consumers να την δουν μέσω consistency/gossip).

**Χρόνος σύγκρισης (#6):** η ανάκληση ελέγχεται **έναντι του trusted signature time**
(`issued_at.trusted_time`, anchored — §1.0), **ΟΧΙ** έναντι του legal effective-time
του payload. Μια υπογραφή με `t_sig ≥ invalid_from` είναι `retroactively-revoked`
ανεξάρτητα από το πότε ισχύει νομικά το αντικείμενο που πιστοποιεί. Χωρίς anchored
`issued_at` ⇒ `UNKNOWN` (δεν τοποθετείται στον χρόνο, άρα δεν κρίνεται).

**Versioned precedence (#7) — μία ετυμηγορία ανά υπογραφή:** το
`LAWMAX-KEY-LIFECYCLE-SPEC.md §2.5` («ό,τι υπογράφηκε πριν την ανάκληση + RFC-3161
χρόνος παραμένει έγκυρο») ισχύει **μόνο** για `superseded`/`delegation-expired`/
`policy` (προγραμματισμένη rotation). Για `key-compromise`, **το MLTP v2 §9 έχει
ρητή versioned precedence** και η αναδρομική ακύρωση υπερισχύει. Το KEY-LIFECYCLE
§2.5 φέρει αντίστοιχη παραπομπή· δύο ACTIVE specs **δεν** δίνουν αντίθετη ετυμηγορία
για την ίδια υπογραφή.

---

## 10. ΕΞΩΤΕΡΙΚΟΙ ΕΛΕΓΚΤΕΣ — ΔΥΟ ΔΙΑΚΡΙΤΕΣ ΤΑΞΕΙΣ (#8)

| τάξη | τι αποδεικνύει | τι ΔΕΝ αποδεικνύει | έδρα |
|---|---|---|---|
| **Transparency witnesses** | δημοσίευση checkpoint, χρόνο (TSA), consistency/μη-equivocation (split-view) | **ΟΧΙ** ορθότητα περιεχομένου, **ΟΧΙ** metrics | GitHub history, ≥2 RFC-3161 TSAs, opt. external CT (trust-bootstrap §4) |
| **Independent auditors/verifiers** | αναπαραγωγή coverage, freshness, legal-state, jurisprudence metrics **από την πηγή** | — | proposer-blind re-derivation (v1.3 M5), δεύτερη υλοποίηση (kernel diversity) |

**Ρητά:** GitHub/TSAs **δεν** πιστοποιούν ότι το περιεχόμενο είναι σωστό ή ότι τα
metrics ισχύουν — πιστοποιούν **μόνο** ότι κάτι δημοσιεύτηκε, πότε, και ότι δεν
υπάρχει split view. Η ορθότητα περιεχομένου/metrics απαιτεί **independent auditor**,
όχι witness. Ένα `VerificationReceipt` που στηρίζει content-correctness σε witness
μόνο ⇒ σφάλμα ταξινομίας.

---

## 11. ΤΙ ΔΕΝ ΚΑΝΕΙ ΑΥΤΟ ΤΟ SPEC

Καμία υλοποίηση· κανένα νέο store/primitive/subsystem· κανένα destruction pass·
καμία αξίωση qualification. Η **σύνθεση** (τρία επίπεδα + typed profiles) είναι
**σχεδιαστική**· οι επιμέρους έδρες υπάρχουν και απαριθμούνται στο
`V1.3-SEMANTIC-CROSSWALK.md`. Πλήρης κατάλογος διορθωμένων αντιφάσεων:
`V1.3-CONSISTENCY-AUDIT.md`.
