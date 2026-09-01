# [0133] — CHANGE-PROPOSAL v1.3 · MACHINE LEGAL TRUST ROOT · CURRENT PUBLIC CANDIDATE
**2026-09-01 · branch από το `973b614b` · design only · ΚΑΝΕΝΑ destruction pass**

Εντολή δημιουργού: «STOP BEFORE DESTRUCTION PASS — το v1.2 είναι ισχυρή δημόσια
βάση, αλλά το target παραμένει εν γνώσει μας ελλιπές.» **Design only, καμία γραμμή
κώδικα, κανένα destruction pass, καμία αξίωση qualification.**

## Τι κατατίθεται (έξι παραδοτέα, ένα commit, parent `973b614b`)

1. **`CHANGE-PROPOSAL-v1.3.md`** — δημόσιος στόχος ως **Machine Legal Trust Root**.
2. **`MACHINE-LEGAL-TRUST-PROTOCOL.md`** — wire schemas 7 πιστοποιητικών + offline verifier.
3. **`V1.3-SEMANTIC-CROSSWALK.md`** — κάθε νέα έννοια → έδρα ή ρητό κενό.
4. **`AS-IS-EVIDENCE-MANIFEST.md`** — αναπαραγώγιμο τεκμήριο, εντολές+outputs+digests.
5. **`SUPERSEDED-REGISTER.md`** — ταξινόμηση ανά scope/ρόλο (διορθωμένη).
6. **`PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md`** — +Q21–Q28, +PROVIDER-ADOPTION, +expiry.

## Οι επτά διορθώσεις (κενά v1.2 που ήταν εν γνώσει μας ελλιπή)

- **#5 Ταυτότητα.** Το v1.2 «ταυτότητα = PLANE-0 digest + path» **αντιφάσκει** στο
  Q07. Υιοθετείται αυτούσια η διάκριση USC `Work→Expression→Manifestation→Item`:
  **τα raw bytes ταυτοποιούν το item μιας manifestation, ΟΧΙ το legal work**. Δύο
  κανάλια, ίδια απόφαση ⇒ ίδιο `work_id`/`expression_id`, διαφορετικά
  `manifestation_id`/receipts.
- **#6 Αυθεντικότητα.** RFC-3161 αποδεικνύει **χρόνο bytes, όχι προέλευση**
  (trust-bootstrap §1). Χρησιμοποιούνται authority-registry + institutional-register
  + authority-proof-bundle + acquisition-receipts + `official-sources-conflict`
  divergence witnesses.
- **#3 Machine Legal Trust Protocol.** 7 πιστοποιητικά
  (`SourceAuthenticityReceipt`, `LegalStateCertificate`, `TemporalProjectionCertificate`,
  `CoverageAndFreshnessCertificate`, `JurisprudenceCertificate`,
  `CorrectionOrRevocationRecord`, `TrustBundle`) — κάθε ένα proof-carrying, με
  claim/scope/valid+known/roots/coverage/assurance/expiry/signer/tlog/result.
  Κάθε πεδίο δένει σε υπάρχουσα έδρα (PCL/census-2/attestation/checkpoint/
  trust-bootstrap/key-lifecycle).
- **#4 Offline verifier + provider integration.** 6 γραμμές, μόνο SHA-256, pinned
  root out-of-band, delegation chain, tlog consistency + gossip (split-view),
  witnesses. Provider-side κανόνας: χωρίς έγκυρη φρέσκια πιστοποίηση ⇒
  `UNVERIFIED_FOR_MACHINE_RELIANCE`/`UNKNOWN`. De jure = κράτος/δικαστήρια.
- **#7 Νομολογία.** Ενσωμάτωση του κατατεθειμένου **Level-7** «Νομολογιακή
  συνείδηση-εξέλιξη» (CEILING-CROSSWALK, status ✗): ratio/obiter, holding, legal
  issue, disposition, separate opinions, authority weight (μετρημένο, όχι γνώμη),
  later treatment, temporal line-of-authority graph.
- **#8 Cockpit.** Signed proposal/approval **intent** → ουρά M5· **ποτέ** παράκαμψη
  M5, ποτέ direct publish, ούτε παθητικό-μόνο.
- **#9 Root Authority.** Όχι μόνιμο βραβείο 30ημέρου. **Συνεχής, time-bounded,
  freshness-bound, ανακλητή** κατάσταση με εξωτερικά επαληθεύσιμα metrics +
  ξεχωριστό `PROVIDER-ADOPTION QUALIFIED`.

## #2 Ταξινόμηση (SUPERSEDED-REGISTER)

- v1.3 = **CURRENT PUBLIC CANDIDATE**· v1.2 = **HISTORICAL / SUPERSEDED** (όχι
  falsified)· v1.1 = **HISTORICAL / FALSIFIED**.
- **CPEI + CEILING-CROSSWALK = DEFERRED / SEPARATE PRIVATE TARGET — NOT
  SUPERSEDED** (το `:matter` primitive + L5–L7 = ο ιδιωτικός matter-solving πυρήνας).
- **ARCHITECTURE-CONSTITUTION.sexp = ACTIVE ENFORCED FOUNDATION**
  (`--architecture-constitution-gate` 12/12, ratchet). Διορθώθηκε προηγούμενη
  εγγραφή που το λογάριαζε ιστορικό.
- **PCL / PROOF-OBJECT / TRUST-BOOTSTRAP / KEY-LIFECYCLE / TEMPORAL-IDENTITY /
  TEMPORAL-SEMANTICS / USC = ACTIVE SHARED TRUST FOUNDATIONS** (και τα δύο scopes).
- **Μία έδρα ανά scope**, μόνο `PUBLIC → PRIVATE`.

## #11 AS-IS τιμιότητα — «13 verifiers δεν είναι απόδειξη»

Κατατέθηκε `AS-IS-EVIDENCE-MANIFEST.md`:
- **EV-1…EV-12 = CONFIRMED** (αναπαραγώγιμα, εντολή+output+digest). **Διόρθωση:**
  git-tracked `article-*.txt` = **4.550** (όχι 4.694· η διαφορά ήταν `find` στο
  working tree). CI 100% failure αναπαραγώγιμο via API (incl. το push αυτού του κλάδου).
- **R-1…R-6 = REPORTED / NOT REPRODUCIBLE** — ερμηνευτικοί ισχυρισμοί agent
  (national-census, cockpit-real, citation-stub-default, publish-gate-flow,
  version-graph-covers-KT5, CI-total) **υποβαθμίστηκαν** από `VERIFIED` μέχρι να
  κατατεθεί εκτελέσιμο τεστ.

## Νέα κενά που ΔΕΝ κρύβονται (crosswalk)

coverage ledger / εθνική απογραφή (κύριο)· Level-7 jurisprudence plane· εκδοχοποιημένο
OpenAPI + SDKs· RBAC/MFA στο cockpit intent· η **σύνθεση** των 7 πιστοποιητικών·
Root Authority ως συνεχής/ανακλητή κατάσταση + provider-adoption qualification.

## Τι ΔΕΝ έγινε

Κανένα destruction pass στο v1.3. Κανένα νέο τυπικό μοντέλο. Καμία υλοποίηση,
κανένα deployment. Καμία βαθμίδα qualification. **Καμία δεύτερη παράλληλη
αρχιτεκτονική** (κάθε έννοια δένει σε έδρα ή δηλώνεται κενό). Επόμενο βήμα, **μόνο**
με ρητή εντολή: ανεξάρτητο destruction pass στο v1.3.
