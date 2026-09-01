# [0138] — STAGE C1: PRE-FREEZE EVIDENCE HARDENING
**2026-09-01 · πάνω στο `6dc80e45` · εκτελέσιμο · scope: πυρήνας πρωτοκόλλου (όχι 15 επίπεδα)**

Εντολή: «NEXT ORDER — PRE-FREEZE EVIDENCE HARDENING + FINAL PUBLIC CEILING DECISION».
Η εκτελέσιμη MLTP closure έγινε δεκτή ως επιτυχές τοπικό architecture spike· καμία
επανασχεδίαση/επανυλοποίηση, κανένα refactoring repo, καμία υλοποίηση 15 επιπέδων.

## C1.1 Profile-manifest pinning
Signed `MLTPProfileManifest` (`fixtures/profile.json`, owner-root-signed, context
`mltp3:profile-manifest`) πινάρει: profile_id, SHA-256 του `schemas.json`,
canonicalization/merkle profiles, sig-context + id-domain digests, error-taxonomy +
qualification-policy versions, min verifier version, activation/expiry/revoked.
Και οι δύο verifiers απορρίπτουν αλλαγμένο/υποβαθμισμένο/άγνωστο schema ή profile ⇒
`untrusted-profile` (fail-closed). Dev override (`MLTP_DEV_OVERRIDE=1`) **ποτέ** δεν
επιστρέφει `VERIFIED` (cap σε `UNKNOWN`, `profile-override-active`). Μάρτυρες
KW-95 έως KW-100 (modified schema/unchanged digest, downgraded taxonomy, changed
sig-context, changed id-domain, untrusted version, unsigned-by-owner).

## C1.2 LocalTrustState boundary
`LocalTrustState` εξωτερικό στο untrusted bundle· bundle δεν αντικαθιστά owner root
(KW-101 `untrusted-root`)· embedded registries άκυρα μέχρι authentication (KW-103
`unsigned-revocation-checkpoint`)· trust-state update = authenticated **monotonic**
transition (KW-102 `nonmonotonic-revocation-state`).

## C1.3 Correct backend evidence
libsodium version από `sodium_version_string()` = **1.0.18** (soname libsodium.so.23,
ABI 10.3, loaded_path καταγεγραμμένο) — όχι από filename «23.3.0» (διορθώθηκε παντού).
`run.sh` κείμενο: libsodium = builder backend, ΟΧΙ «second verifier».

## C1.4 Standards interoperability (vetted, όχι hand-rolled)
- **RFC 3161:** πραγματικό DER token από τοπικό test TSA μέσω **OpenSSL `ts`**
  (`interop/rfc3161/`, RSA signer — Ed25519 δεν υποστηρίζεται από το ts app)·
  `verify.sh` επαληθεύει cert chain + sha256 imprint + genTime/accuracy και απορρίπτει
  tampered message. Το core `TimeAttestation` παραμένει **deterministic test double**,
  ΟΧΙ TSR.
- **COSE_Sign1:** πραγματικό vector μέσω **veraison/go-cose v1.3.0** (pinned, **vendored**,
  offline) πάνω στα **ακριβή** MLTP canonical payload bytes (`interop/cose/`)· κανένα
  hand-rolled CBOR/COSE· deterministic re-make· tampered payload απορρίπτεται. Η
  κανονική-JSON υπογραφή MLTP και το COSE_Sign1 είναι **διακριτές κατασκευές**. Πλήρης
  SCITT υπηρεσία = `MISSING` (μόνο boundary + vector ζητήθηκαν).

## C1.5 Independent reproducibility (CI)
Στενό GitHub Actions job `.github/workflows/mltp3-verify.yml` — μόνο
`bash deployment/verify/mltp3/run.sh`, pinned toolchains (go 1.24.7, node 22.18.0,
python 3.11.9, ubuntu-24.04), upload `REPORT.json`, καμία άσχετη σουίτα. Το CI
αποτέλεσμα καταγράφεται μετά το push (δεν διεκδικείται externally reproducible πριν
περάσει καθαρό run).

## C1.6 Honesty of independence
Go + Node = δύο ανεξάρτητες **N-version υλοποιήσεις** από **μία** προδιαγραφή, ίδια
μηχανική συνεδρία — **ΟΧΙ** ανεξάρτητος οργανωτικός/θεσμικός έλεγχος. Ανεξάρτητη
υλοποίηση ≠ ανεξάρτητη adjudication.

## Αποτελέσματα
`run.sh` exit 0: RFC 8032 cross-check (libsodium/Go/Node)· determinism· DAG/no-self-id·
θετικό VERIFIED (2/2)· **40 μεταλλάξεις KW-64 έως KW-103** απορρίπτονται από αμφότερους
με ίδιο typed error· interop rfc3161 + cose OK. Audits: v1.4 98/98, v1.3 64/64, exit 0.
**C1 verdict (εκκρεμεί μόνο η επιβεβαίωση CI):** `PRE-FREEZE EVIDENCE HARDENING PASSED`.

ΔΕΝ ΕΓΙΝΕ: freeze, qualification, merge, refactoring, υλοποίηση 15 επιπέδων, πλήρης
SCITT service. RAW-JOURNAL-PARTIAL.jsonl αμετάβλητο/ακατάθετο.
