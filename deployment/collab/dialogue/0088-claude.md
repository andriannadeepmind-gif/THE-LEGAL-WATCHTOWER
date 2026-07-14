# [0088] Claude — ΦΑΣΗ TEMPORAL/IDENTITY (LAWMAX Authority Publisher) — άνοιγμα + P0 baseline receipt

**Ημερομηνία:** 2026-07-13 · **Εντολή δημιουργού:** «Εγκρίνω να ξεκινήσεις άμεσα τη φάση
Temporal/Identity … ανώτατη ενιαία υλοποίηση της συστάδας, όχι προσωρινό patch και όχι
ελάχιστο κλείσιμο των blockers.» (πλήρες κείμενο εντολής: acceptance constitution με
αλυσίδα official source bytes → … → signed published release, παραδοτέα Α-Ζ, όρια §6,
παραδοτέο §7 — ενσωματώνεται εδώ δια παραπομπής ως ο νόμος της φάσης.)

## P0 — Baseline receipt (owner docker proof του [0087]) — ΠΡΑΣΙΝΟ

- **HEAD:** `6e90646f217af53f845cafd0c933542cd88df48c` ([0087]) ≡ origin — επιβεβαιωμένο.
- **Owner docker** (`docker build --target standalone-test`, Windows/Docker Desktop,
  --no-cache-filter=standalone-test): ΟΛΟΚΛΗΡΟ το gated loop πέρασε, build DONE,
  image exported — ΚΑΝΕΝΑ exit 1.
- **Το κρίσιμο:** `corpus-identity: 55 passed, 0 failed` — ① syntagma **124 άρθρα**
  (5Α/9Α/100Α/101Α παρόντα ②×4), ㉗/㉗β (νέα O-3 locks) ΠΡΑΣΙΝΑ ΣΤΟ DOCKER.
  Η διάγνωση [0087] επιβεβαιώθηκε ΚΑΙ αιτιακά: ο δημιουργός βρήκε το τοπικό
  syntagma_clean.json modified (`git status`), το επανέφερε (`git restore`),
  και το ίδιο build που κοκκίνιζε 47/6 πέρασε 55/55.
- Ενδεικτικά περαιτέρω πράσινα ίδιου run: seat-integrity 18/18 (στο docker),
  cockpit 37/0, legal-eval 8/0, casegrammar 30/0, greek-morphology 18/0,
  escape-sequences 38/0, turtle-nil-omit 7/0, semantic-validity 18/0.
- **Image identity:** manifest list `sha256:0eb6a7cc442f05a10c6ee688740e0f0f18b9e8ff7c05b8dd6114ef3be0d36e34`
  (manifest `sha256:fe2e94b6eca3…`, config `sha256:532bab3b081e…`,
  attestation `sha256:a0878103ad0c…`), tag `lawmax-test:latest`.
- **Δηλωμένες αποκλίσεις: ΚΑΜΙΑ πραγματική.** Τα δύο SKIP είναι by-design στο
  SBCL-only stage: cross-language-verifier (χωρίς node — σκληρό gate στο
  verifier-conformance stage) και semantic-validity ⑤γ/⑤δ (χωρίς rdflib — ομοίως).

**⇒ Το P0 της φάσης ικανοποιείται. Καμία baseline επισκευή δεν απαιτείται.**

## Αντικείμενο της φάσης — τα 14 ανοιχτά cp04 ευρήματα

AUTH-01 (δύο έδρες ταυτότητας άρθρου) · TEMP-01 (ανακατασκευή=μεταδεδομένα, όχι κείμενο) ·
TEMP-02 (άγνωστη ημερομηνία ισχύος fail-open) · TEMP-03 (transaction-time εκτός query) ·
TEMP-04 (ισχύον Σύνταγμα με 1975 παντού) · AUTH-02 (authority=κανάλι, όχι βάρος) ·
TRUST-01 (reasoning proof δεν κλείνει source/temporal/authority) · CONS-01 (proof=count,
όχι ledger) · CONS-02 (hashes χωρίς πλήρη δομή) · PROV-01 (last-touch provenance) ·
PCL-01 (PCL δεσμεύει text, όχι identity/metadata) · PCL-02 (spine σε δεύτερη αλυσίδα) ·
ANCHOR-01 (self-verifying λίστα) · PCL-03 (σιωπηλή υποβάθμιση emission).

## Πορεία φάσης (κατά την εντολή)

1. **P0 baseline** — ✅ (παρόν receipt).
2. **Ανώτατη σχεδίαση**: as-is χαρτογράφηση των εδρών (ανεξάρτητοι αναγνώστες) →
   ≥2 ουσιωδώς διαφορετικές σχεδιάσεις ανά περιοχή (identity/intervals/amendments/
   bitemporal/derivation/receipts) → κρίση με ΑΠΟΛΥΤΑ κριτήρια (ένα σχέδιο ανά κριτή,
   9 κριτήρια της εντολής) → σύνθεση της ισχυρότερης συνεκτικής σύλληψης.
3. Υλοποίηση στην έδρα (μία έδρα ανά έννοια, migration/adapters/διαγραφή για κάθε
   παλαιά οικογένεια IDs — καμία δεύτερη έδρα).
4. Acceptance constitution (όλοι οι μετρητές = 0) + property/mutation/boundary/
   out-of-order/overlap/malformed/tampering/substitution tests + negative witnesses.
5. Δύο ανεξάρτητοι αντιπαλικοί κριτές → κλείσιμο ευρημάτων στην έδρα ή δηλωμένο υπόλειμμα.
6. Παραδοτέο §7 (SHA, diff ανά έδρα, re-baseline, snapshots 1975/1986/2001/2008/2019,
   receipts, verifier, δήλωση χωρίς υπερβολή).

Όρια σεβαστά (§6): όχι cognitive refactoring, όχι παράλληλο σύστημα, όχι δημόσιο
production πριν κλείσει η S6, Ζ/Δ1-Δ5 δεν μπλοκάρουν εκτός αποδεδειγμένης εξάρτησης.

---

## [0088+] Σχεδιαστικό στάδιο — ΟΛΟΚΛΗΡΩΘΗΚΕ (ίδια ημέρα)

**Διαδικασία**: 18 ανεξάρτητοι πράκτορες — 5 as-is αναγνώστες πραγματικού κώδικα (file:line),
3 σχεδιαστές με ουσιωδώς διαφορετικές φιλοσοφίες, 9 κριτές με ΑΠΟΛΥΤΟ rubric (ένα σχέδιο ανά
κριτή — μεθοδολογικός νόμος [0082+]) στα 9 κριτήρια της εντολής, 1 συνθέτης.

**Απόλυτες βαθμολογίες** (SOUND=3/MINOR=2/SERIOUS=1/WRONG=0, 27 κρίσεις ανά σχέδιο):
- **version-graph: 77/81** — ΒΑΣΗ (ισχυρότερο προφίλ, fatal=false, 0 SERIOUS/WRONG)
- event-ledger: 76/81 — μπολιάσματα: quarantined ΤΥΠΟΣ (αόρατος στο trusted fold),
  op-retract-knowledge, op-restate (δημοτική 1986), chain-hash + consistency proofs,
  ολικός κανόνας διάταξης εφαρμογής
- frbr-registry: 72/81 — μπολιάσματα: wId/eId διάκριση (αναριθμήσεις χωρίς lineage hacks),
  FRBR/ELI προβολές ανά επίπεδο, double-entry transcription για σαρωμένα ΦΕΚ

Κανένας κριτής δεν έδωσε SERIOUS/WRONG πουθενά· και τα 18 MINOR (5×ιστορική-ανακατασκευή,
4×αναπαραγωγιμότητα, 4×αντι-παραχάραξη, 2×πληρότητα-ταυτότητας, 2×επαληθευσιμότητα,
1×μία-έδρα) θεραπεύονται ΟΝΟΜΑΣΤΙΚΑ στη σύνθεση §3 — κανένα σιωπηλό.

**Το τελικό σχέδιο**: `deployment/LAWMAX-TEMPORAL-IDENTITY-DESIGN.md` — ΔΙΤΕΜΠΟΡΙΚΟΣ
ΓΡΑΦΟΣ ΕΚΔΟΣΕΩΝ ΜΕ EVENT-TYPED ΠΥΡΗΝΑ. Κύρια σημεία:
- ΜΙΑ έδρα ταυτότητας `source/legal-identity.lisp` (provision-id/lineage-id/path segments,
  ο συνθετικός base*1000 παύει να είναι ταυτότητα)· ΜΙΑ έδρα canonical serialization με
  δημοσιευμένο spec + vectors + ανεξάρτητη python υλοποίηση.
- text-version κόμβοι αμετάβλητοι με ΥΠΟΧΡΕΩΤΙΚΟ `legal-date` τύπο (το NIL effective ΔΕΝ
  ΧΩΡΑΕΙ στον τύπο — η κλάση TEMP-02 εξαλείφεται, δεν φρουρείται)· quarantined-edge =
  ΑΛΛΟΣ τύπος, δομικά αόρατος στην επιλογή έκδοσης.
- Πλήρες bitemporal: version-at με recorded ΣΤΟ selection predicate + text-as-known endpoint.
- admit-edge! = replay-then-append (G1)· append-only journal με chain-hash + interim TSA
  seals ανά 24h/256 appends + RFC-6962 consistency ανά cut (G3/G6).
- Hermetic derivation: content-addressed τριάδα (artifact, extractor-root, config) με ΠΛΗΡΗ
  επανεκτέλεση ανά νέα τριάδα — τέλος η ταυτολογία ANCHOR-01.
- LegalAuthorityReceipt: leaf = hash ΟΛΟΚΛΗΡΟΥ receipt (ταυτότητα+χρόνοι+γενεαλογία+authority
  ΜΕΣΑ στη Merkle δέσμευση)· ΜΙΑ ρίζα· sign-root fail-closed (exit≠0).
- Migration Φ0-Φ7/M0-M6 χωρίς απώλεια· era-1 sealed, era-2 συνεχίζει την tlog αλυσίδα.
- §8: και τα 14 ευρήματα → ονομαστικό κλείσιμο. §9: 10 ρητά όρια/υπολείμματα (τίμια).
- Έλεγχος υπέρτατου νόμου μέσα στο σχέδιο: δηλωμένες 2 αυστηρά ανώτερες επεκτάσεις
  (char-level provenance = Φάση Θ, typed effectivity conditions = Φάση Ι) — πάνω στο παρόν
  υπόστρωμα, καταγεγραμμένες, δεν παραδίδονται τώρα.

**ΚΡΙΣΙΜΟ ΓΙΑ ΤΟΝ ΔΗΜΙΟΥΡΓΟ — κτήση πηγών για το Σύνταγμα-benchmark (Φ7/M6):**
Η κειμενική ανακατασκευή 1975/1986/2001/2008 είναι ΑΔΥΝΑΤΗ από τα δεδομένα του repo
(υπάρχει ΜΟΝΟ το post-2019 κείμενο + 4 text-less records). Χρειάζονται (δημόσια, pinned
by digest): ΦΕΚ Α΄111/1975 (βάση)· Ψηφίσματα ΦΕΚ Α΄23/1986, Α΄84/2001, Α΄102/2008,
Α΄187/2019· ενοποιημένα-oracle ΦΕΚ Α΄24/1986, Α΄85/2001, Α΄120/2008, Α΄211/2019.
Η κτήση μπορεί να ξεκινήσει παράλληλα με τις Φ1-Φ6.

**Επόμενο βήμα**: Φ0 era-1 seal (καταγραφή υπαρχόντων attested roots) + Φ1 (canonical
serialization + identity). Η εντολή «Δεν εγκρίνω αποσπασματικό… Προχώρα τώρα» καλύπτει
τη συνεχή εκτέλεση Φ0→Φ6· το Φ7 εξαρτάται από την κτήση πηγών· το τελικό merge = δημιουργός.

---

## Φ0 — ERA-1 SEAL (receipt)

Καταγεγραμμένη κατάσταση era-1 στο HEAD της φάσης (μετά το [0088+] commit):

| Corpus | latest release (attested:true) |
|---|---|
| constitution | `sha256-0ee2ecc4e0efab7342908876454df179fb60187654338832cb05058903883825` |
| poinikos | `sha256-e8384152d401efc82566f9c5628c8b37a0a074ed1f95dea598334d0d8217dca6` |
| kpoinikis | `sha256-b53a6dfa5dd49cf8acfb61d000fa0dc9d7bfd4fc4b8d145fcac1a2e36018a47c` |
| astikos | `sha256-1129ac1e0453c9c98744f7c2ca6af138a611d8c706a2bc2d345c802132eaa30d` |
| kpolitikis | `sha256-aaf60c01d1bfec2a01ef4e914476f184771cc686c6dc8aa08bd1d067e5c3727f` |
| kdioikitikis | `sha256-a8d87d7ff439e524f403c7e1135c620055faadab657075354bfe8481a3416e93` |

Αυτά είναι τα ids που το πρώτο era-2 census θα δεσμεύσει ως `prev_release_root` ανά σώμα —
η αλυσίδα συνεχίζεται, η ιστορία δεν ξαναγράφεται (releases/ = append-only, [0058] owner attest ×6).

**Τίμια δήλωση**: per-corpus `transparency-log.json` ΔΕΝ υπάρχει ακόμη στο repo — η L7-B έδρα
(transparency-log.lisp, tests 23/23) γράφει το log στο `promote-latest!`· κανένα attested promote
δεν έχει τρέξει από τότε. Το era-1 seal εδώ = τα attested latest ids· το tlog ξεκινά τη ζωή του
με το πρώτο promote (era-2 cut ή owner-side), και το consistency-proof καθεστώς του σχεδίου (G6)
ισχύει από το πρώτο entry και μετά. Κανένα «νέο cut» δεν κόβεται από το cloud (τα signing/TSA
είναι owner-side από σχεδίαση) — το Φ0 είναι καταγραφή, όχι παραγωγή.

---

## [0088++] ΠΡΟΟΔΟΣ ΥΛΟΠΟΙΗΣΗΣ Φ0-Φ5μ (2026-07-14) — receipt με αριθμούς

| Βήμα | Commit | Παραδοτέο | Proof |
|---|---|---|---|
| Φ0 | (0088) | Era-1 seal — 6 attested roots ως prev_release_root βάση | receipt §Φ0 |
| Φ1α | 9dbbd7d9 | Η ΜΙΑ έδρα ταυτότητας orchestrator.identity + αυστηρός adapter + article.lisp delegation + component-gate νέα αλήθεια | legal-identity 18/18 · **bijection 4694/0/0** · cit 55/55 · seat 18/18 |
| Φ1β | db956717 | Canonical serialization spec + 8 vectors + verify-canonical.py + πεδίο τιμών χωρίς floats/booleans (jonathan false≡null — δομική εξάλειψη) + RFC8785 πεζά hex | Lisp 12/12 · Python 8/8 |
| Φ2 | 8d89d61e | Διτεμπορικός γράφος: legal-date τύπος (TEMP-02 δεν κατασκευάζεται), quarantined-edge ΤΥΠΟΣ, G1 replay-then-append, chain-hash journal ([0086] έδρα), version-at με recorded ΣΤΟ predicate, ΓΝΗΣΙΑ supersession | version-graph 18/18 |
| Φ3 | ebbf2d94 | Import 6 σωμάτων (genesis+κενά γνώσης) + FOLD-PARITY gate + δηλωμένα body_identity (κυρωτικές πράξεις) + lettered κληρονομιά βάσης | graph-import-parity 24/24 — 4694/4694 byte-ίδια, 0 αποκλίσεις |
| Φ4α | 0b8fad15 | LegalAuthorityReceipt: receipt-id = hash ΟΛΟΚΛΗΡΟΥ receipt, γενεαλογία replay | 11/11 — 124/124 receipts, 6/6 tampers FAIL |
| Φ4β | 3747082c | Θάνατος PCL-03 υποβαθμίσεων ×3 + trust_status typed + emit-proofs exit≠0 | 15/15 · κανείς καταναλωτής δεν έσπασε (45/45·45/45·12/12·16/16) |
| Φ5μ | (παρόν) | as-of fallback ΝΕΚΡΟ (typed as-of-unavailable + HTTP 422) + text-as-known από τον δίσκο | corpus-service 45/45 · parity 26/26 |

**Τα 14 ευρήματα — τίμια κατάσταση:**
- ΚΛΕΙΣΤΑ ΣΤΟ ΝΕΟ ΜΟΝΟΠΑΤΙ: AUTH-01 (μία έδρα — adapters με θάνατο Φ6), TEMP-01/
  TEMP-02/TEMP-04 (γράφος: κείμενο-φέρουσες εκδόσεις, τύπος χωρίς NIL, τίμια
  valid-from + κενά γνώσης), TEMP-03 (recorded στο predicate + text-as-known),
  PROV-01 (πλήρης γενεαλογία στο receipt), PCL-01 (leaf = hash όλου του receipt),
  PCL-03 (υποβαθμίσεις νεκρές, trust_status typed).
- ΜΕΡΙΚΩΣ: AUTH-02 (source-artifact/κανάλι ΜΕΣΑ στο receipt· το ΝΟΜΟΛΟΓΙΑΚΟ
  βάρος = εκτός εμβέλειας κώδικα-σωμάτων, δηλωμένο υπόλοιπο)· ANCHOR-01
  (ANCHOR failure πλέον σφάλμα· η hermetic ΕΠΑΝΕΚΤΕΛΕΣΗ extractor = §1.4
  verify-derivation, εκκρεμεί — δένει σε P4 substrate)· PCL-02 (receipts
  υπάρχουν· η ένταξη receipt-set-root στο era-2 canonical set = Φ5-πλήρες).
- ΑΝΟΙΧΤΑ: TRUST-01 (reasoning premises με receipt-ids — Φ5-πλήρες)·
  CONS-01/CONS-02 στο ΠΑΛΙΟ consolidation-proof (πεθαίνει με το cutover —
  ο γράφος ήδη κάνει per-record replay+chain)· TEMP-03 στο ΠΑΛΙΟ select-acts
  (ζει μέχρι το cutover Φ5-πλήρες/Φ6).
- Φ7 benchmark: αναμένει τα 9 ΦΕΚ (λίστα §[0088+]).

**ΤΙΜΙΟ ΟΡΙΟ ΣΥΝΕΧΕΙΑΣ:** το υπόλοιπο Φ5 (cutover emitters/serving στον γράφο)
και το Φ6 (θάνατοι adapters/παλαιών εδρών) αλλάζουν το ΣΕΡΒΙΡΙΖΟΜΕΝΟ μονοπάτι —
δεν προχωρούν χωρίς owner docker proof του σωρευμένου έργου (5 νέα gated tests
στο loop). Η φάση παύει εδώ μέχρι το docker πράσινο ή νέα εντολή.

---

## OWNER DOCKER PROOF Φ0-Φ5μ — ΠΛΗΡΕΣ ΠΡΑΣΙΝΟ (2026-07-14, receipt)

Owner build (`--target standalone-test`, --no-cache-filter): ΟΛΟΚΛΗΡΟ το gated
loop πέρασε (DONE 593.5s), image exported `sha256:1dc1083d142e1fc128a4ee11e64cde28f022f451aae1be671b212453517eaca9`.
Τα 5 νέα gates ΣΤΟ ΜΗΧΑΝΗΜΑ ΤΟΥ ΔΗΜΙΟΥΡΓΟΥ: legal-identity 18/18 (bijection
4694/0/0), canonical-serialization 12/12, version-graph 18/18,
graph-import-parity 26/26 (6/6 σώματα, FOLD-PARITY 4694/4694, χρονική
τιμιότητα Συντάγματος επιβεβαιωμένη σε docker), legal-authority-receipt 15/15.
Όλα τα προϋπάρχοντα: 0 αποτυχίες (corpus-identity 55/55 κ.λπ.).

Σημείωση διαδρομής: το προηγούμενο run κοκκίνισε ΟΡΘΑ στο O-3 gate
(HASH MISMATCH, αρχείο+hashes ονομαστικά) — το τοπικό syntagma_clean.json
είχε ξανα-αλλοιωθεί από τοπική διεργασία (το 120-άρθρων περιεχόμενο ΔΕΝ
υπάρχει στην ιστορία του git — παράγεται τοπικά, πιθανός ένοχος: παλαιό
container με RW mount). Ο δημιουργός το αποκατέστησε και το πλήρες loop
πέρασε. Ο μηχανισμός [0087] απέδειξε την αξία του ΣΤΗΝ ΠΡΑΞΗ: η κλάση
«σιωπηλά αλλοιωμένη πηγή» πλέον αυτο-ονομάζεται στο κατώφλι.

**⇒ Το δηλωμένο όριο συνέχειας ήρθη: Φ5-πλήρες (cutover) και Φ6 (θάνατοι
adapters) αποδεσμεύονται.**

---

## [0088+++] ΠΡΟΟΔΟΣ Φ5-ΠΛΗΡΕΣ (α/β/γ) — 2026-07-14

Μετά το πράσινο owner docker proof, αποδεσμεύτηκε και εκτελείται το Φ5-πλήρες:

- **Φ5α — census-2 (κλείσιμο PCL-02)**: `corpus-temporal-commitment` (ΜΙΑ έδρα,
  cli) = graph_root (κεφαλή chain-hash με verify-chain replay από δίσκο) +
  receipt_set_root (RFC-6962 MTH των receipt-ids στη σημερινή τομή, σειρά
  provision-id), fail-closed (0 uncertain / 0 verification failures / import
  από provenance-ελεγμένη πηγή αν λείπει journal). Το census-2 ΔΕΝ κόβεται
  χωρίς temporal block· ροή μέσω context σε run-pipeline (JSON+PDF) ΚΑΙ
  --cut-release· fail-closed στο engine stage ΚΑΙ στην έδρα census.
  Spec ενημερώθηκε (LAWMAX-PROOF-OBJECT-SPEC §2). Proofs: artifact-census
  21/21, graph-import-parity ⑥/⑥β.
- **Φ5β — HTTP /as-known**: route στο corpus-service με typed boundary
  contract (as-known-uncertain⇒422, as-known-unknown⇒404, χωρίς provider⇒501,
  χωρίς κάλυψη⇒404 τίμιο κενό). Provider ανά σώμα στο cli πάνω στην έδρα
  text-as-known (μετάφραση συνθηκών γράφου→boundary). Proofs: corpus-service
  52/52 (7 νέα locks).
- **Φ5γ — grounded reasoning (θάνατος TRUST-01)**: `grounded-impact` — κάθε
  συμπέρασμα impact φέρει {provision-id, receipt-id, content-hash, valid-from}
  επιλυμένα με version-at στην υποχρεωτική διτεμπορική τομή· αθεμελίωτα
  ΔΗΛΩΝΟΝΤΑΙ· ερωτώμενο άρθρο χωρίς θεμέλιο ⇒ ΣΦΑΛΜΑ· το --reason εκδίδει
  θεμελιωμένη αναφορά. Locks ⑦/⑦β (μη-ταυτολογικό — άρθρο με πραγματικές
  εισερχόμενες παραπομπές, 3 θεμελιωμένα)/⑦γ — graph-import-parity 31/31.

Commits: 98653515 (Φ5α), 61909485 (Φ5β), dd0e817b (Φ5γ).

**Επόμενο**: Φ5δ cutover emitters/serving από snapshot-at (fold-parity gate
ενεργός) + conformance transaction-time ζεύγη + grep-gate silent_fallbacks=0·
μετά Φ6 θάνατοι adapters (grep-gate 0 καταναλωτών ανά έδρα)· μετά 2
αντιπαλικοί κριτές + παραδοτέο §7.

---

## [0088-κριτής] ΑΥΣΤΗΡΟΣ ΕΛΕΓΧΟΣ ΔΗΜΙΟΥΡΓΟΥ ΣΤΟ Φ5β — ΚΛΕΙΣΙΜΟ 10 ΣΗΜΕΙΩΝ ΣΤΙΣ ΕΔΡΕΣ (2026-07-14)

Ο δημιουργός ΠΑΓΩΣΕ την ανακήρυξη Φ5β («μεταβατικό sidecar, όχι ανώτατο») με
2 κρίσιμα + 6 υψηλά + 2 μεσαία. Όλα κλείστηκαν στις έδρες, κανένας νέος adapter:

| # | Εύρημα | Κλείσιμο (έδρα) | Απόδειξη |
|---|---|---|---|
| Κ1 | service-handler φόρτωνε consolidated doc ΠΡΙΝ το route | route-first lazy doc-memo στο corpus-service — το /as-known ανεξάρτητο από την παλιά διαδρομή | E2E ⑧/⑧β/⑧γ: provider ΚΑΜΕΝΟΣ, /as-known 200 |
| Κ2 | chain δεν δέσμευε ΟΛΟ το record (μόνο record-id) | payload-hash = sha256(%canon-sexp ΟΛΟΥ payload — value-canonical, ΟΧΙ prin1: βρέθηκε & σκοτώθηκε το #A(...) non-simple-string bug)· chain = sha256(prev‖0x1F‖payload-hash)· replay: payload-hash + semantic hash (%version-hash/%edge-hash ≡ record-id) ανά kind· παλαιό σχήμα ⇒ ρητό σφάλμα | E2E ③ tampering ⇒ ρήξη· reimport→φρέσκια διεργασία→LOAD-OK |
| Υ1 | ψευδο-τύποι χρόνου (2026-99-99 περνούσε, λεξικογραφικές συγκρίσεις) | legal-date γνήσιος γρηγοριανός (δίσεκτα)· ΝΕΟΣ legal-instant (canonical UTC, υποχρεωτικό Z)· iso-now → UTC Z· %time-key integer σύγκριση· version-at typed· boundary ⇒ 400 | E2E ⑤/⑤β/⑤γ/⑦/⑦β |
| Υ2 | καραντίνα/κενά αγνοούσαν known-at | %known-by-p: επηρεάζουν ΜΟΝΟ αν recorded-from ≤ known-at· ΔΗΛΩΜΕΝΟ υπόλοιπο Υ2β: gaps χωρίς άνω όριο valid-διαστήματος (υπερ-προσοχή, ποτέ ψευδής βεβαιότητα) | E2E ④/④β, ⑥δ (μέσω HTTP) |
| Υ3 | δεύτερο iso-now μετά την εγγραφή (live≠replay drift) | edge recorded-from = :at της γραμμής· %recorded-of fail-closed (γραμμή χωρίς :at = διεφθαρμένη) | E2E ②γ/②δ ισότητα live≡replayed |
| Υ4 | χειροποίητο JSON με format/~S | /as-known ΜΟΝΟ μέσω της ΜΙΑΣ JCS έδρας (canonicalize-json)· typed 400 condition | E2E: ΚΑΘΕ response περνά jonathan parser |
| Υ5 | tests = boundary mocks | ΝΕΟ gated tests/as-known-e2e-test.lisp (21 locks): γνήσιο journal→graph→HTTP, δύο known-at ⇒ διαφορετικές ορθές απαντήσεις (πυρήνας ΚΑΙ HTTP στο πραγματικό syntagma), restart parity, tampering, καραντίνα, 400s, route-first | 21/21 + Dockerfile gated |
| Υ6 | 501 σε production | ORCHESTRATOR_SERVE_PROFILE: authority (default) = fail-closed readiness (provider+γράφος+ΟΛΑ receipts verified+FOLD-PARITY ή ΔΕΝ σερβίρεται)· migration = μόνο ρητά | serve-corpus gate |
| Μ1 | παράλληλες corpora/short->id alists | typed corpus-runtime στο corpus-service (name/corpus-id/doc-provider/as-known-provider) + uniqueness gate· build-all-corpora = Η ΜΙΑ κατασκευή | multi 13/13 (+lock) |
| Μ2 | STATE-OF-PLAY πίσω από HEAD | ενημερώθηκε στο ίδιο commit με το παρόν | αυτό το commit |

Επιπλέον (Φ5δ serving cutover): document-as-of — το as-of σερβίρισμα ΜΟΝΟ από
snapshot-at του γράφου (θάνατος της TEMP-03 text-less select-acts αναπαραγωγής
στο serving)· μερικό «ιστορικό» έγγραφο ΔΕΝ σερβίρεται (ονομαστική αβεβαιότητα).

Proofs (τοπικά, όλα πράσινα): version-graph 18/18 · graph-import-parity 31/31 ·
legal-authority-receipt 15/15 · corpus-service 52/52 · multi-corpus 13/13 ·
as-known-e2e 21/21.

**ΤΟ Φ5β ΔΕΝ ανακηρύσσεται πλήρες**: εκκρεμούν owner docker proof (νέο gate
as-known-e2e στο loop) και οι 2 ανεξάρτητοι αντιπαλικοί κριτές. Υπολείμματα
δηλωμένα: Υ2β (interval model των gaps), conformance ζεύγη σε ΟΛΟ το σώμα
(transaction_time_query_failures=0 ως gate), Φ6 θάνατοι adapters.
