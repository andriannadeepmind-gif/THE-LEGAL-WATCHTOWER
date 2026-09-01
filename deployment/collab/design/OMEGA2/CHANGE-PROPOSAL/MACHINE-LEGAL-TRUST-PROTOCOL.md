# MACHINE LEGAL TRUST PROTOCOL (MLTP) v2 — ΤΡΙΑ ΕΠΙΠΕΔΑ, TYPED CLAIMS, ΠΡΑΓΜΑΤΙΚΟ CRYPTO PROFILE
# Υποσύστημα του `CHANGE-PROPOSAL-v1.3.md §3-4` — ΟΧΙ δεύτερη αρχιτεκτονική

**Design only.** Semantic-closure αναθεώρηση της v1 (η v1 είχε γνωστές εσωτερικές
αντιφάσεις: self-asserted `verification_result`, «verified only with SHA-256»,
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
  "qualification_state_ref": <id ενός QualificationStateRecord §3· ΠΟΤΕ inline level>,
  "description": <ΠΡΟΑΙΡΕΤΙΚΟ ανθρώπινο κείμενο — ΠΟΤΕ input επαλήθευσης> }
```

**Ρητοί κανόνες:**
- **ΚΑΝΕΝΑ `verification_result` σε IssuedClaim** — το αποτέλεσμα ζει στο Layer C.
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
  "evidence_refs": [ <ids τεκμηρίων/receipts/audits> ],
  "issued_at","expiry",                                     # καμία βαθμίδα μόνιμη (Q28)
  "signer": {"alg","kid","sig"} }
```
Οι IssuedClaims **δείχνουν** εδώ (`qualification_state_ref`), **ποτέ** δεν
αυτοχαρακτηρίζονται. Λήξη `expiry` ⇒ ο verifier το χειρίζεται ως `none`.

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
consistency-failed · split-view · expired · revoked · retroactively-revoked ·
insufficient-provenance · unknown-claim-type · unadopted-analysis · UNKNOWN(reason)`.

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
  "delegation_chain": [ <root→delegate statements> ],
  "transparency": { "log_id","tree_size","log_root","consistency_from" } }
```
**Το TrustBundle δεν ισχυρίζεται τίποτα από μόνο του — μεταφέρει.** Δεν φέρει
`verification_result`, δεν φέρει claim. Ένας καταναλωτής το τροφοδοτεί στον local
verifier (§8) και **παράγει** `VerificationReceipt`.

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
(LOC-ceiling, kernel diversity). Ψευδοκώδικας:

```
verify_bundle(bundle, PINNED_ROOT) -> VerificationReceipt:
  checks = []
  # A. inclusion (SHA-256 μόνο)
  for c in bundle.issued_claims:
     checks += pcl_inclusion(c.payload, c.proof_material)          # RFC 9162
  # B. signatures (RS256/Ed25519 — ΟΧΙ SHA-256 μόνο)
  require thumbprint(bundle release key) == thumbprint(PINNED_ROOT) else untrusted-key
  require delegation_valid(bundle.delegation_chain, PINNED_ROOT)   # RS256/Ed25519
  for c in bundle.issued_claims:
     require sig_verify(c.signature, PINNED_ROOT/delegate)         # RS256/Ed25519
  # C. one authority root (§5)
  require bundle.release_anchor.release_root is THE authority root  # pcl_text_root = cross-check μόνο
  # D. transparency + gossip
  require tlog_inclusion(bundle) AND consistency(bundle, consumer.last_seen)  # split-view
  # E. revocation (§9) — retroactive-aware
  for c in bundle.issued_claims:
     if revoked(c.signature.kid, at=c.effective_time): return retroactively-revoked
  # F. freshness / qualification
  if now > qual_state(c).expiry: level = none
  if stale(bundle) or unadopted(analysis_claims): return UNVERIFIED_FOR_MACHINE_RELIANCE
  return VERIFIED
```

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
`compromise_known_at` (για compromise). Η αναδρομική ακύρωση είναι **ρητή policy**,
όχι σιωπηλή — και δημοσιεύεται ως `trust-key-or-delegation-revocation` IssuedClaim
στο tlog (ώστε οι consumers να την δουν μέσω consistency/gossip).

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
