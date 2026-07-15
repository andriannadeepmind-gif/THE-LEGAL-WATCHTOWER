# LAWMAX TRUST-BOOTSTRAP SPECIFICATION v1 (κλείσιμο Β-S2 — ΣΧΕΔΙΟ)

**Κατάσταση: SPEC-ONLY. Υλοποίηση ΜΟΝΟ με ρητό «εγκρίνω trust-bootstrap»
του δημιουργού. Κλείνει το finding Β-S2 (self-certifying release anchor)
του αντιπαλικού κριτή Β [0088].**

## 1. Το πρόβλημα (ακριβώς)

Σήμερα το `release-anchored` αποδεικνύει ΣΥΝΕΠΕΙΑ, όχι ΑΥΘΕΝΤΙΑ:
- η JWS υπογραφή του release root επαληθεύεται με `verify/public.jwk`
  ΜΕΣΑ στο ίδιο το release (self-certifying)·
- το transparency log είναι τοπικό αρχείο, ολικά αναγεννήσιμο από τα ίδια
  τα census·
- το RFC-3161 TSR αποδεικνύει ΧΡΟΝΟ ύπαρξης bytes, όχι ποιος τα εξέδωσε.
Όποιος ελέγχει το `output/<corpus>/releases/` κατασκευάζει πλήρως
self-consistent ψευδο-anchored κατάσταση.

## 2. Owner Key Ceremony (η ΜΙΑ γενεσιουργός πράξη)

1. Ο ΔΗΜΙΟΥΡΓΟΣ, offline (air-gapped μηχανή ή τουλάχιστον εκτός του
   serving host), γεννά το **Owner Root Key** (Ed25519 προτεινόμενο·
   RSA-3072 αποδεκτό για συμβατότητα με την υπάρχουσα RSA έδρα):
   `owner-root.private` (ΠΟΤΕ σε repo/host/CI) + `owner-root.pub`.
2. Πρακτικό τελετής (ceremony record): ημερομηνία, fingerprint
   (sha256 του δημόσιου κλειδιού), μάρτυρες (§4), αποθήκευση ιδιωτικού
   (π.χ. 2 αντίγραφα offline). Το πρακτικό υπογράφεται από το ίδιο το
   root key και δημοσιεύεται.
3. Το root key υπογράφει ΜΟΝΟ: (α) delegation statements (§3),
   (β) revocations, (γ) το ceremony record. ΠΟΤΕ per-release/per-query.

## 3. Out-of-band pinned root + delegation

- **Pinned root**: το `owner-root.pub` fingerprint δημοσιεύεται σε ≥2
  κανάλια ΕΚΤΟΣ του serving host: (α) commit στο GitHub repo (η ιστορία
  του GitHub = ανεξάρτητος μάρτυρας), (β) DNS TXT record ή σελίδα του
  δικηγορικού γραφείου, (γ) προαιρετικά: αποτύπωση σε δημόσιο CT-like
  μέσο. Ο verifier ΔΕΝ δέχεται ποτέ root key από το ίδιο το release.
- **Release signing key delegation**: το root υπογράφει statement
  `{delegate: <release-key fingerprint>, scope: release-signing,
  not-before, not-after (≤ 1 έτος), seq}` — το per-release JWS υπογράφεται
  από το delegated κλειδί. Ανάκληση = νεότερο statement με μεγαλύτερο seq.
  Έτσι το root μένει offline και η καθημερινή έκδοση δεν το αγγίζει.
- **Επαλήθευση (νέος ορισμός release-anchored)**: root-pin (out-of-band)
  → delegation chain valid στο genTime του TSR → JWS του release root με
  το delegated key → census graph_root ≡ chain-head → tlog inclusion +
  **consistency με προηγούμενο ΓΝΩΣΤΟ checkpoint του καταναλωτή**
  (gossip κατά ολικής αντικατάστασης) → verifier-set membership.

## 4. Witness model

- **Μάρτυρας 1 — GitHub**: κάθε promote-latest δημοσιεύει το release root
  + tlog root ως commit (ή release tag) στο δημόσιο repo. Η ιστορία του
  δεν ελέγχεται από τον serving host.
- **Μάρτυρας 2 — RFC-3161 TSAs** (υπάρχει): ≥2 ανεξάρτητες TSAs
  χρονοσφραγίζουν το root — μαζί με τον μάρτυρα 1 κλειδώνει ΚΑΙ χρόνο
  ΚΑΙ περιεχόμενο.
- **Μάρτυρας 3 (μελλοντικός, προαιρετικός)**: εξωτερικό append-only log
  (public CT log / OTS blockchain aggregator) για το tlog root.
- **Gossip κανόνας καταναλωτή**: αποθηκεύει το τελευταίο (tree_size,
  log_root) που είδε· νεότερη απάντηση με μη-συνεπές log ⇒ απόρριψη
  (split-view detection). Το `tlog-verify` ήδη παρέχει consistency proofs
  (RFC 6962 §2.1.2) — λείπει μόνο ο εξωτερικός checkpoint.

## 5. Τι αλλάζει στον κώδικα (όταν εγκριθεί)

1. `release-anchor-for`: +pinned-root αρχείο ΕΚΤΟΣ release
   (`deployment/keys/owner-root.pub`, committed — ο verifier το παίρνει
   από το repo/2ο κανάλι, όχι από το release) + delegation chain check·
   αποτυχία = ονομαστικό reason (όπως όλα).
2. tra/2 → tra/3: +`owner_root_fingerprint`, +`delegation_seq`,
   +`witness_checkpoints` μέσα στο hashed payload.
3. Python verifier: αντίστοιχη επέκταση + delegation/pin επαλήθευση.
4. Ο #4 verifier δεύτερης βαθμίδας καταναλώνει το πλήρες bundle με τον
   pin ως input ΤΟΥ ΧΡΗΣΤΗ (ποτέ από το bundle).

## 6. Συναφή δηλωμένα (κριτής Β)

- **N3 cache poisoning**: owner proof ΠΑΝΤΑ `--no-cache`· μελλοντικά
  signed build provenance (SLSA-style attestation: builder identity ↔
  git_commit ↔ image digest) — δένει με το Approval Act.
- **N4**: ο in-build manifest verifier είναι έλεγχος συνέπειας· οι
  εγγυήσεις ζουν στα RUN gates — δηλωμένος καταμερισμός.

## 7. Ανοιχτές αποφάσεις ΔΗΜΙΟΥΡΓΟΥ

Δ1 αλγόριθμος root key (Ed25519 vs RSA-3072)· Δ2 κανάλια δημοσίευσης pin
(ποια 2+)· Δ3 διάρκεια delegation· Δ4 μάρτυρας 3 ναι/όχι· Δ5 πότε
εκτελείται η τελετή (πριν ή μετά το Π7).
