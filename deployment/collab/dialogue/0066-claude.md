# [0066] Owner docker proof P4+L7-B — ΠΛΗΡΩΣ ΠΡΑΣΙΝΟ

**Ποιος/πότε:** Claude (καταγραφή)· εκτέλεση: ΔΗΜΙΟΥΡΓΟΣ, 2026-07-12,
`docker build --no-cache-filter=standalone-test --target standalone-test`.

## Αποτελέσματα (owner μηχάνημα, hermetic image)

- **tsr-crypto-verify (P4): 19/19** — Sectigo RSA/SHA-384 + FreeTSA ECDSA
  P-384/SHA-512 επαληθεύονται· :pinned και για τους δύο με τον γνήσιο embedded
  issuer· αρνητικά (λάθος μήνυμα, flipped signature, μισό/άδειο/padded TSR,
  λάθος pinned CA) ΟΛΑ απορρίπτονται.
- **transparency-log (L7-B): 23/23** — 210 εξαντλητικές RFC-6962 §2.1.2
  περιπτώσεις + αρνητικά· tamper (entry/log_root/checkpoint/JSON) ⇒ ΚΟΚΚΙΝΟ·
  deletion+αναγέννηση ⇒ πλήρης αλυσίδα (bootstrap)· εξωτερικός-verifier σενάριο.
- Χωρίς οπισθοδρόμηση: kernel-conformance 107/107, release-authority 15/15
  (το tlog ζωντανό στο ⑦γ: «καταγράφηκε, consistency proof OK»), merkle 18/18,
  census 18/18, release-vector 16/16, corpus-identity 53/53, semantic 18/18,
  SHACL 19/19, escape 38/38, hash 18/18, write-authority 16/16, time 20/20,
  blockchain 32/32, turtle-nil-omit 7/7.
- Τίμιο SKIP: cross-language verifier stage χωρίς node σε αυτό το stage
  (σκληρή πύλη στο verifier-conformance stage — γνωστό, δηλωμένο).

## Κατάσταση

P1.5+L7-A ήδη merged στο main από τον δημιουργό (ca544a7fe). P4+L7-B: proof
πλήρες — εκκρεμεί ΜΟΝΟ ρητό «εγκρίνω P4+L7-B» + merge (πάντα του δημιουργού).
Μετά: #34 ΑΚ/ΚΠολΔ (θέλει αυθεντικό ΦΕΚ από δημιουργό)· key ceremony ΤΕΛΕΥΤΑΙΟ.
