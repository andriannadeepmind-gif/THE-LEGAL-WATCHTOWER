# CHANGE-PROPOSAL v1.3 — ΤΟ ΔΗΜΟΣΙΟ ΠΑΡΑΤΗΡΗΤΗΡΙΟ ΩΣ MACHINE LEGAL TRUST ROOT
# LAWMAX OMEGA — THE-LEGAL-WATCHTOWER OF GREECE

**ΚΑΤΑΣΤΑΣΗ: `CURRENT PUBLIC CANDIDATE / NOT YET FREEZEABLE`.**
**ΔΕΝ ΥΠΑΡΧΕΙ ΣΗΜΕΡΑ ΚΑΝΟΝΙΚΟΣ ΠΑΓΩΜΕΝΟΣ ΣΤΟΧΟΣ.**

**Design only — καμία γραμμή κώδικα.** Δεν ζητείται έγκριση υλοποίησης, ούτε
freeze, ούτε deployment. **ΔΕΝ ΕΧΕΙ ΕΚΤΕΛΕΣΤΕΙ DESTRUCTION PASS** — ούτε στο v1.3,
ούτε ζητείται τώρα (εντολή δημιουργού: «STOP BEFORE DESTRUCTION PASS»).

**Parent:** `973b614b`. **Νέα συγγραφή** πάνω στην υπάρχουσα δημόσια βάση v1.2 —
δεν αντικαθιστά, τη σκληραίνει εκεί που **εν γνώσει μας ήταν ελλιπής**.

Συνοδευτικά (ίδιος κατάλογος, μία έδρα ανά ρόλο):
`MACHINE-LEGAL-TRUST-PROTOCOL.md` (wire schemas πιστοποιητικών + offline
verifier), `V1.3-SEMANTIC-CROSSWALK.md` (κάθε νέα έννοια → έδρα ή κενό),
`AS-IS-EVIDENCE-MANIFEST.md` (αναπαραγώγιμο τεκμήριο), `SUPERSEDED-REGISTER.md`
(ταξινόμηση), `PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md` (πύλες).

---

## 0. ΕΥΡΟΣ ΚΑΙ ΔΙΑΧΩΡΙΣΜΟΣ — ΜΙΑ ΕΔΡΑ ΑΝΑ SCOPE

Δύο **ξεχωριστοί** στόχοι, ποτέ αναμειγμένοι, με **αυστηρά μονόδρομο** όριο:

```
        ┌─────────────────────────────┐        one-way, signed releases
        │  PUBLIC TARGET  (v1.3)      │  ───────────────────────────────►  ┌────────────────────────┐
        │  Machine Legal Trust Root   │        PUBLIC → PRIVATE only        │  PRIVATE TARGET (CPEI) │
        │  για τη ΔΗΜΟΣΙΑ,            │                                     │  matter-solving,       │
        │  ΕΠΑΛΗΘΕΥΜΕΝΗ μηχανική       │  ◄───────────────────────────╳──── │  DEFERRED, NOT         │
        │  αναπαράσταση του δικαίου    │        καμία παρατήρηση προς τα πίσω │  SUPERSEDED            │
        └─────────────────────────────┘                                     └────────────────────────┘
```

- **PUBLIC TARGET = αυτό το v1.3.** Μόνο δημόσιο. Καμία υπόθεση/πελάτης/στρατηγική/
  προνόμιο/AY δεν μπαίνει ποτέ μέσα — **δομική απουσία τύπου**, όχι φρουρός.
- **PRIVATE TARGET = CPEI + CEILING-CROSSWALK** (`LAWMAX-CPEI-TARGET-SPEC.{md,sexp}`,
  `LAWMAX-CEILING-CROSSWALK.{md,sexp}`). Είναι το πλήρες Ίδρυμα με το `:matter`
  primitive και τα στρώματα L5–L7 (hypothesis workspace, adversarial parliament,
  legal world simulator) — **DEFERRED / SEPARATE PRIVATE TARGET — NOT SUPERSEDED**
  (βλ. `SUPERSEDED-REGISTER.md §1`). **Δεν** επιδιορθώνεται εδώ, **δεν** υποβιβάζεται·
  απλώς **δεν** ανήκει στο δημόσιο εύρος.
- **Ο μονόδρομος:** το ιδιωτικό μπορεί αργότερα να **καταναλώνει υπογεγραμμένες
  δημόσιες εκδόσεις** (§3, TrustBundle). Το δημόσιο **δεν** παρατηρεί ιδιωτικές
  υποθέσεις, χρήση, πελάτες ή προνομιακό υλικό. Το δημόσιο σχήμα **δεν έχει τύπο**
  `Matter`/`Case`/`Client` — καμία διαρροή να φρουρηθεί, γιατί κανένα πεδίο να
  γραφτεί.

**ΤΙΜΙΑ ΔΗΛΩΣΗ:** ο διαχωρισμός **δεν λύνει** τα ιδιωτικά kill tests
(KT2/KT3/KT9/KT12/KT13)· **αφαιρεί το πεδίο** τους. Επιστρέφουν αυτούσια αν
χτιστεί ποτέ το PRIVATE TARGET.

---

## 1. ΤΙ ΑΛΛΑΖΕΙ ΤΟ v1.3 (η δήλωση ατέλειας του v1.2)

Το v1.2 ήταν ισχυρή δημόσια βάση αλλά **εν γνώσει μας ελλιπές** σε επτά σημεία.
Το v1.3 τα κλείνει σχεδιαστικά (όχι υλοποιητικά):

| # | κενό v1.2 | κλείσιμο v1.3 | §, εντολή |
|---|---|---|---|
| Α | Ταυτότητα «= PLANE-0 digest + path» **αντιφάσκει** στο Q07 | υιοθέτηση USC `Work→Expression→Manifestation→Item` | §2.1, #5 |
| Β | Αυθεντικότητα «= RFC-3161» — αποδεικνύει ΧΡΟΝΟ, όχι ΠΡΟΕΛΕΥΣΗ | authority registry + institutional register + authority-proof-bundle + acquisition receipts + divergence witnesses | §2.2, #6 |
| Γ | Καμία **μηχανικά καταναλώσιμη** μορφή εμπιστοσύνης | **Machine Legal Trust Protocol** — 7 πιστοποιητικά | §3, #3 |
| Δ | Καμία **ανοιχτή offline** επαλήθευση για τρίτους/AI | minimal offline verifier + provider integration | §4, #4 |
| Ε | Νομολογία ρηχή — αποθήκευση, όχι κωδικοποίηση εξέλιξης | Level-7 «Νομολογιακή συνείδηση-εξέλιξη» plane | §5, #7 |
| Ζ | Cockpit ασαφές (παθητικό vs publish) | signed proposal/approval **intent**, ποτέ παράκαμψη M5 | §6, #8 |
| Η | Root Authority «κερδίζεται» από ένα 30ήμερο | **συνεχής, time-bounded, freshness-bound, ανακλητή** κατάσταση | §7, #9 |

---

## 2. ΔΙΟΡΘΩΣΗ ΤΑΥΤΟΤΗΤΑΣ ΚΑΙ ΑΥΘΕΝΤΙΚΟΤΗΤΑΣ (υπάρχουσες έδρες)

### 2.1 Ταυτότητα — υιοθέτηση της διάκρισης USC (εντολή #5)

Η v1.2 §6 έγραφε «ταυτότητα = digest των `PLANE-0` bytes + δομική διαδρομή». Αυτό
**συγκρούεται** με το Q07 («ίδια απόφαση από δύο κανάλια = μία ταυτότητα»): δύο
επίσημα κανάλια δίνουν διαφορετικά bytes, άρα διαφορετικό digest, άρα — λανθασμένα
— δύο ταυτότητες. **Ανακαλείται.**

Υιοθετείται **αυτούσια** η υπάρχουσα διάκριση του
`LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md §1`:

```
WORK  ──►  EXPRESSION  ──►  MANIFESTATION  ──►  ITEM (raw bytes)
(νομικό     (κείμενο +        (media_type +        (acquisition-
 αντικείμενο) valid_at)        variant + edition)    receipt/1)
```

| επίπεδο | ταυτότητα | τι ταυτοποιεί | έδρα USC |
|---|---|---|---|
| `work_id` (`lsw1:`) | identity_domain + official_key | **το νομικό αντικείμενο** — αντέχει αναταξινόμηση, μετονομασία, μεταφορά εποπτείας | USC §1.1 |
| `expression_id` (`lse1:`) | κείμενο + valid_at | **τη νομική θέση/κείμενο** — καμία epistemic κατάσταση μέσα | USC §1.2 |
| `manifestation_id` (`lsm1:`) | media_type + official_variant + publisher + edition | **τη συγκεκριμένη έκδοση** | USC §1.3 |
| `acquisition-receipt/1` (`acq1:`) + `raw-artifact/1` | sha256(bytes) | **τα ίδια τα bytes ενός item** | USC §5.1, §4.1 |

**Ο κανόνας που κλείνει το Q07:** τα **raw bytes ταυτοποιούν το item μιας
manifestation, ΟΧΙ το legal work**. Δύο κανάλια που παραδίδουν την **ίδια απόφαση**
⇒ **ίδιο `work_id`** και (αν ίδιο §2-normalized κείμενο) **ίδιο `expression_id`**,
αλλά **διαφορετικά `manifestation_id` / acquisition receipts**. Μία νομική ταυτότητα,
πολλά items. (Μάρτυρας USC: `W-UNRELATED-CORPUS-IDENTITY-CHURN`.)

**Άμεση συνέπεια — διόρθωση του v1.2 §6 και του KT4:** η ταυτότητα ΔΕΝ εξαρτάται
από σειριοποίηση· εξαρτάται από `work_id`/`expression_id`. Επανα-κανονικοποίηση ενός
manifestation item δεν αγγίζει καμία νομική ταυτότητα (v1.2 §6 «ταυτότητα = bytes»
ισχύει **μόνο** για το επίπεδο item, όχι για το work).

### 2.2 Αυθεντικότητα πηγής — όχι RFC-3161 μόνο (εντολή #6)

Το `LAWMAX-TRUST-BOOTSTRAP-SPEC.md §1` το δηλώνει ρητά: **«το RFC-3161 TSR
αποδεικνύει ΧΡΟΝΟ ύπαρξης bytes, όχι ποιος τα εξέδωσε.»** Επομένως το v1.2 Σ-1
(«καμία έξοδος χωρίς σφραγισμένη επίσημη πηγή») **δεν** επαρκεί με RFC-3161. Η
αυθεντικότητα προέλευσης συντίθεται από **υπάρχουσες έδρες**:

| στοιχείο | έδρα | τι προσθέτει |
|---|---|---|
| Ποια θεσμική αρχή/μητρώο | `authority-registry` (`auth1:`) + `institutional-register/1` (`ireg1:`) | ταυτότητα εκδότη/μητρώου, ανθεκτική σε αναδιάρθρωση (USC §2.1β/§2.2) |
| Απόδειξη εξουσίας | `authority-proof-bundle/1` (CLOSED & FROZEN, κατανάλωση μέσω CENSUS) | ότι η αρχή **είχε** την εξουσία τη στιγμή έκδοσης (USC §0.1) |
| Πώς αποκτήθηκε | `acquisition-receipt/1` (origin sum: network-fetch \| manual-deposit \| archive-import) | ιχνηλάσιμη αλυσίδα κτήσης, custody (USC §5.1) |
| Χρόνος (μόνο) | RFC-3161 anchoring στο receipt | **μόνο** χρόνος bytes — ένα στοιχείο, όχι το όλον |
| Απόκλιση πηγών | uncertainty `official-sources-conflict` (13 kinds, USC §8) + **divergence witnesses** | δύο «επίσημες» πηγές διαφωνούν ⇒ `CONFLICTING`, ποτέ σιωπηλή επιλογή |

**Δομικός κανόνας (ενισχυμένο Σ-1):** μια ακμή προς `RELEASED` απαιτεί
`authority-proof-bundle` **ΚΑΙ** επιλυμένο `institutional_register_id` **ΚΑΙ**
acquisition receipt — όχι απλώς RFC-3161. «Χρόνος bytes» χωρίς «ποιος τα εξέδωσε»
⇒ `QUARANTINED`, ποτέ `RELEASED`.

---

## 3. MACHINE LEGAL TRUST PROTOCOL (εντολή #3)

**Ενοποιείται στον δημόσιο στόχο** — δεν είναι δεύτερη αρχιτεκτονική· είναι το
**μηχανικά καταναλώσιμο πρόσωπο** των υπαρχουσών εδρών (PCL-1, census-2,
attestation/checkpoint, trust-bootstrap, key-lifecycle). Πλήρη wire schemas:
`MACHINE-LEGAL-TRUST-PROTOCOL.md`. Εδώ: οι έδρες και τα claims.

Κάθε πιστοποιητικό φέρει **υποχρεωτικά**: `claim` (ακριβής ισχυρισμός) · `scope`
(τι καλύπτει, τι όχι) · `valid_time` + `known_time` · `source_roots` (Merkle/
authority roots) · `coverage_boundary` · `assurance_level` · `expiry`/`freshness` ·
`signer` (kid + delegation) · `transparency_log_inclusion` · `verification_result`.

| πιστοποιητικό | claim | υπάρχουσα έδρα | κενό; |
|---|---|---|---|
| **`SourceAuthenticityReceipt`** | «αυτά τα bytes προέρχονται από την Χ επίσημη αρχή/μητρώο, αποκτήθηκαν έτσι, σε αυτόν τον χρόνο» | `acquisition-receipt/1` + `raw-artifact/1` + `authority-proof-bundle/1` + `institutional-register/1` + RFC-3161 | έδρες ✅· **σύνθεση σε ένα cert = ΝΕΟ** |
| **`LegalStateCertificate`** | «σε (valid,known) το νομικό αντικείμενο έχει αυτό το κείμενο και αυτή τη νομική κατάσταση» | `legal-state-attestation/1` + `knowledge-checkpoint/1` + PCL-1 inclusion | έδρες ✅· cert = ΝΕΟ |
| **`TemporalProjectionCertificate`** | «η προβολή στο (valid,known) είναι αυτή, αναπαραγώγιμα» | version-graph `snapshot-at(valid_at,known_at)` + census-2 `temporal{graph_root,receipt_set_root,valid_at,known_at}` | έδρες ✅· cert = ΝΕΟ |
| **`CoverageAndFreshnessCertificate`** | «η κάλυψη του χώρου Χ είναι αυτή, με αυτή τη φρεσκάδα· τα κενά είναι ρητά» | **coverage ledger (v1.2 §4)** + census-2 `known_at` + TUF `timestamp` role | **coverage ledger = ΝΕΟ ΚΕΝΟ** (AS-IS R-1: καμία εθνική απογραφή) |
| **`JurisprudenceCertificate`** | «αυτή η απόφαση, με αυτή την ταυτότητα/ECLI, αυτές τις τυπωμένες σχέσεις και θέση στη γραμμή αυθεντίας» | M4 + USC §6.3 relations + **Level-7 plane** (§5) | Level-7 = **ΝΕΟ ΚΕΝΟ** (CEILING-CROSSWALK status ✗) |
| **`CorrectionOrRevocationRecord`** | «αυτό αντικαταστάθηκε/ανακλήθηκε/διορθώθηκε — από ποιον, πότε, με ποια εξουσία» | uncertainty resolution (USC §8) + `WITHDRAWN`/`SUPERSEDED` + relation-retract (USC §6.3) + key/delegation revocation (key-lifecycle §2.5) | έδρες ✅· cert = ΝΕΟ |
| **`TrustBundle`** | «η συνολική, αυτο-επαληθεύσιμη δέσμη για offline κατανάλωση» | census-2 + `corpus-proof.json` (PCL) + trust-bootstrap `tra/3` (`owner_root_fingerprint`, `delegation_seq`, `witness_checkpoints`) + delegation chain | έδρες ✅· σύνθεση = ΝΕΟ |

**Ιδιότητα του πρωτοκόλλου:** κάθε πιστοποιητικό είναι **proof-carrying** (κατά
`LAWMAX-PROOF-OBJECT-SPEC.md §0`, De Bruijn): περιέχει **το ίδιο το αντικείμενο
απόδειξης**, ώστε τρίτος να ξαναϋπολογίσει χωρίς εμπιστοσύνη. Καμία υπογραφή δεν
είναι *αντί* απόδειξης· είναι *επιπλέον*.

---

## 4. OPEN MINIMAL OFFLINE VERIFIER + PROVIDER INTEGRATION (εντολή #4)

### 4.1 Ο ελεγκτής — μικρός, offline, χωρίς βιβλιοθήκη

Έδρα: `PROOF-CARRYING-LAW.md §5-6` (6 γραμμές, μόνο SHA-256) + `LAWMAX-PROOF-OBJECT-SPEC.md §4`
(LOC-ceiling gate, «να τον audit-άρει ο καθένας σε ένα απόγευμα»). Ελέγχει:

1. **Merkle inclusion** (RFC 9162, profile `lawmax-merkle-sha256-v1`) — το κείμενο
   χασάρει στο δηλωμένο root.
2. **Authentic against pinned key** — root υπογεγραμμένο από **pinned** κλειδί που
   ο verifier παίρνει **out-of-band**, ΠΟΤΕ από το bundle (PCL §4 trust anchor).
3. **Delegation chain** — root → delegation statement (scope, not-before/after,
   seq) → delegated key (trust-bootstrap §3).
4. **Transparency-log inclusion + consistency** — RFC 9162 §2.1.2 consistency
   proofs· **gossip**: ο καταναλωτής κρατά το τελευταίο (tree_size, log_root)· μη
   συνεπές log ⇒ απόρριψη (split-view detection, trust-bootstrap §4).
5. **External witnesses** — GitHub commit history + ≥2 RFC-3161 TSAs (+ προαιρετικό
   εξωτερικό CT log) — trust-bootstrap §4 witness model.

**Pinned trust roots**: `owner-root.pub` fingerprint δημοσιευμένο σε ≥2 κανάλια
εκτός serving host (git tag, DNS TXT/ιστοσελίδα, προαιρετικά CT). **Key rotation/
revocation**: append-only key registry, `kid`+`alg`+`key_lineage`, continuity
statement υπογεγραμμένο από το παλιό κλειδί· revocation out-of-band (key-lifecycle §2.4-2.5).

**Ρητή απόρριψη ψευδο-ανωτέρων** (PROOF-OBJECT §5): ZK-SNARK/STARK (κρύβουν τον
συλλογισμό)· W3C VC/DID ως CORE (JSON-LD canonicalization στο έμπιστο μονοπάτι)·
**LLM στο trusted path**. Επιτρεπτά μόνο ως προαιρετικό envelope μεταφοράς (L5/L7).

### 4.2 Provider integration + ο κανόνας του καταναλωτή

- **Επιφάνειες:** OpenAPI (εκδοχοποιημένο — **ΝΕΟ ΚΕΝΟ**, AS-IS EV-5: κανένα σήμερα)
  · versioned MCP (υπάρχον seat `source/mcp-server.lisp` = 4 εργαλεία, **προς
  επέκταση**) · SDKs για offline verification (νέα, λεπτά — μόνο SHA-256 + ο ελεγκτής §4.1).
- **Provider-side κανόνας (δεσμευτικός):** ένα AI/provider σύστημα που στηρίζεται
  σε δημόσια νομική αναπαράσταση **χωρίς έγκυρη, φρέσκια πιστοποίηση** ΠΡΕΠΕΙ να
  επιστρέφει **`UNVERIFIED_FOR_MACHINE_RELIANCE`** ή **`UNKNOWN`** — ποτέ σιωπηλή
  παρουσίαση ως αυθεντικού. «Φρέσκια» = εντός του `freshness` του
  `CoverageAndFreshnessCertificate` (§3), αλλιώς `UNKNOWN` (θετική απόδειξη
  φρεσκάδας, όπως το v1.2 §8 KT1 ceiling).

**De jure**: η επίσημη πηγή παραμένει **κράτος/δικαστήρια**. Το Watchtower είναι
**Machine Legal Trust Root** για την **επαληθευμένη μηχανική αναπαράσταση** — ποτέ
πηγή δικαίου (§7, §10).

---

## 5. ΝΟΜΟΛΟΓΙΑ — ΤΟ ΕΠΙΠΕΔΟ «ΝΟΜΟΛΟΓΙΑΚΗ ΣΥΝΕΙΔΗΣΗ-ΕΞΕΛΙΞΗ» (εντολή #7)

Το ήδη κατατεθειμένο **Level 7** του `LAWMAX-CEILING-CROSSWALK.md` (`:authority`
primitive + L2 — line-of-authority temporal graph· status **✗**, phase Ω7β)
ενσωματώνεται στη δημόσια νομολογία (M4). **Είναι ΝΕΟ ΚΕΝΟ με κατατεθειμένη έδρα
σχεδίασης**, όχι υλοποιημένο.

Ανά απόφαση, πέρα από την ταυτότητα (§2.1, ECLI, δικονομικό ιστορικό, ανωνυμοποίηση):

- **`ratio` / `obiter`** — τυπωμένη διάκριση δεσμευτικού λόγου από παρεμπίπτον·
  κάθε τμήμα αγκυρωμένο σε χωρίο (`PLANE-0`).
- **`holding`** — το κρατούν, ως δομημένος ισχυρισμός με τρίτιμη κατάσταση
  (`IN`/`OUT`/`UNDEC`, v1.2 M4).
- **`legal_issue`** — το τεθέν ζήτημα.
- **`disposition`** — το διατακτικό (δεκτή/απορριπτέα/αναιρεί/παραπέμπει…).
- **`separate_opinions`** — μειοψηφίες/συγκλίνουσες, ξεχωριστά τυπωμένες.
- **`authority_weight`** — βάρος γραμμής αυθεντίας (Ολομέλεια > Τμήμα· πλήθος/
  συνέπεια ακολουθουσών) — **μετρημένο, ποτέ γνώμη μοντέλου** (CEILING-CROSSWALK #15 φρουρός).
- **`later_treatment`** — μεταγενέστερη μεταχείριση (followed/distinguished/
  overruled/doubted), μέσω USC §6.3 relations (`precedent-follows`/`distinguishes`,
  `annuls`, `declares-unconstitutional`).
- **`temporal_line_of_authority_graph`** — διτεμπορικός γράφος (L2): «ποια ήταν η
  ισχύουσα γραμμή αυθεντίας σε (valid,known)», με ρωγμές/outliers ρητά.

**Δομικοί φρουροί (μεταφορά v1.2 + USC):** `UNDEC ⇒ UNKNOWN` (KT6)· καμία απόφαση
δεν παράγει νομοθετικό γεγονός (USC §6.3, μη εκφράσιμο)· AI inference (`PLANE-3`)
**ποτέ** ως ratio/holding/source. Ο `JurisprudenceCertificate` (§3) πιστοποιεί
αυτό το επίπεδο.

---

## 6. COCKPIT — SIGNED INTENT, ΠΟΤΕ ΠΑΡΑΚΑΜΨΗ M5 (εντολή #8)

Το `--cockpit` υπάρχει (AS-IS R-2: 4 capabilities, με τεστ — **REPORTED**, όχι
αποδεδειγμένο λειτουργικά). Στο v1.3:

- Το cockpit **ΔΕΝ** είναι απλώς παθητική προβολή. Μπορεί να υποβάλλει
  **υπογεγραμμένη πρόθεση**: `signed_proposal_intent` (πρόταση αλλαγής χάρτη) και
  `signed_approval_intent` (πρόθεση έγκρισης) — φέρουν `kid`/υπογραφή του ενεργούντος
  (δένει με RBAC/MFA, AS-IS: **ΝΕΟ ΚΕΝΟ**, καμία αυθεντικοποίηση σήμερα).
- Το cockpit **ΔΕΝ** μπορεί να παρακάμψει την **M5 (Independent Verification and
  Release Fabric)**. Κάθε πρόθεση **μπαίνει στην ουρά** της M5 ως πρόταση· η
  μετάβαση σε `VERIFIED`/`RELEASED` γίνεται **μόνο** από την proposer-blind M5,
  ποτέ από το cockpit. Καμία διαδρομή cockpit → direct publish δεν υπάρχει —
  **δομικά** (ο τύπος απόκρισης του cockpit είναι όψη + πρόθεση, όχι release action).
- Έδρα: `%ask-envelope` / InstitutionalAct (CPEI §2) — μία έδρα envelope, το
  cockpit intent είναι πεδίο της, όχι δεύτερο κανάλι.

**Αποτέλεσμα:** ούτε «μουσειακή βιτρίνα» (παθητικό μόνο) ούτε «κόκκινο κουμπί»
(direct publish). Υπογεγραμμένη πρόθεση → M5 → (proposer-blind) → release.

---

## 7. ROOT AUTHORITY — ΣΥΝΕΧΗΣ, ΑΝΑΚΛΗΤΗ ΚΑΤΑΣΤΑΣΗ (εντολή #9)

Το v1.2 άφηνε να εννοηθεί ότι η Root Authority **κερδίζεται** από ένα 30ήμερο
`MISSION GREECE-1`. **Διορθώνεται:** η Root Authority **δεν είναι μόνιμο βραβείο**.
Είναι **συνεχής, χρονικά φραγμένη, freshness-bound, ΑΝΑΚΛΗΤΗ κατάσταση**:

- **Συνεχής & time-bounded:** ισχύει μόνο όσο τρέχουν, εντός παραθύρου, τα
  εξωτερικά επαληθεύσιμα metrics (κάλυψη, latency, μηδέν σιωπηλή απώλεια, source
  census). Λήξη παραθύρου χωρίς ανανέωση ⇒ πτώση σε `UNKNOWN`/`UNVERIFIED`.
- **Freshness-bound:** δένει με το TUF `timestamp` role (key-lifecycle §1) και το
  `CoverageAndFreshnessCertificate` (§3) — χωρίς φρέσκια απόδειξη, καμία αξίωση.
- **Externally verifiable:** τα metrics επαληθεύονται από τους witnesses (§4.1,
  trust-bootstrap §4), όχι από το ίδιο το σύστημα (καμία αυτο-πιστοποίηση, Σ-3).
- **Revocable:** ανακαλείται με υπογεγραμμένο revocation (key-lifecycle §2.5) ή
  αυτόματα όταν πέσει κάτω από κατώφλι — split-view/divergence ⇒ άμεση πτώση.
- **Ξεχωριστό provider-adoption qualification:** το «οι providers το χρησιμοποιούν
  ως root» είναι **διαφορετική** βαθμίδα από το «η αναπαράσταση είναι επαληθευμένη»
  (§8). Η μία δεν συνεπάγεται την άλλη.

**Απόλυτο όριο:** ακόμη και σε πλήρη ισχύ, η **de jure** αυθεντία παραμένει
**πάντα** στην Εφημερίδα της Κυβερνήσεως και στα αρμόδια δικαστήρια. Το Watchtower
είναι **de facto Machine Legal Trust Root για την επαληθευμένη μηχανική
αναπαράσταση** — ποτέ εκδότης δικαίου.

---

## 8. ΚΛΙΜΑΚΑ ΠΟΙΟΤΙΚΗΣ ΕΠΑΡΚΕΙΑΣ (εντολή #10)

Πλήρες: `PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md` (επεκτάθηκε με Q21–Q28:
certificate interoperability, offline verification, trust bootstrap/revocation/
tlog, identity invariance across manifestations, anonymization/licensing,
correction/challenge governance, provider integration, **qualification expiry**).

| βαθμίδα | v1.3 |
|---|---|
| `SPEC QUALIFIED` | **ΟΧΙ** — κανένα destruction pass στο v1.3 |
| `IMPLEMENTATION QUALIFIED` | **ΟΧΙ** — καμία υλοποίηση |
| `MISSION QUALIFIED` | **ΟΧΙ** — `MISSION GREECE-1` **ΟΡΙΣΜΕΝΗ, ΜΗ ΕΚΚΙΝΗΜΕΝΗ** |
| **`PROVIDER-ADOPTION QUALIFIED`** *(νέο, #9)* | **ΟΧΙ** — ξεχωριστή βαθμίδα, εξωτερικά μετρήσιμη |

**Καμία βαθμίδα δεν επιτεύχθηκε.** Η qualification **λήγει** (Q28): καμία βαθμίδα
δεν είναι μόνιμη· χωρίς ανανέωση εντός παραθύρου, υποβαθμίζεται.

---

## 9. ΕΠΑΝΑΧΡΗΣΙΜΟΠΟΙΗΣΗ ΕΔΡΩΝ + AS-IS ΤΙΜΙΟΤΗΤΑ (εντολή #11)

- **Crosswalk:** κάθε νέα έννοια του v1.3 → μία υπάρχουσα έδρα ή ρητό κενό:
  `V1.3-SEMANTIC-CROSSWALK.md`. **Καμία δεύτερη παράλληλη αρχιτεκτονική** —
  όλα δένουν σε PCL/USC/trust-bootstrap/key-lifecycle/census-2/CPEI-layers.
- **AS-IS τιμιότητα:** το v1.2 §12 σήμαινε ορισμένα ευρήματα `ΕΠΑΛΗΘΕΥΜΕΝΟ`
  στηριγμένα σε 13 agents. Κατατίθεται `AS-IS-EVIDENCE-MANIFEST.md`:
  - **EV-1…EV-12 = `CONFIRMED`** (αναπαραγώγιμα, με ακριβείς εντολές/outputs/digests·
    διόρθωση: git-tracked `article-*.txt` = **4.550**, όχι 4.694).
  - **R-1…R-6 = `REPORTED / NOT REPRODUCIBLE`** — ερμηνευτικοί ισχυρισμοί agent
    (national-census, cockpit-real, citation-stub-default, publish-gate-flow,
    version-graph-covers-KT5, CI-total) υποβαθμίζονται μέχρι να κατατεθεί
    εκτελέσιμο τεστ.

---

## 10. ΑΥΘΕΝΤΙΑ — ΤΙ ΔΕΝ ΔΙΕΚΔΙΚΕΙΤΑΙ

- Root Authority (§7) **μόνο** ως συνεχής/ανακλητή κατάσταση μετά από MISSION +
  PROVIDER-ADOPTION qualification· ποτέ μόνιμη, ποτέ αυτο-πιστοποιημένη.
- **De jure** αυθεντία = **πάντα** κράτος/δικαστήρια. Καμία βαθμίδα δεν το αλλάζει.
- Ο τίτλος «Primary Semantic Authority» και το μηχανικά αναγνώσιμο
  `PRIMARY_SEMANTIC_AUTHORITY` (AS-IS EV-11) είναι **ασύμβατα** με τα παραπάνω και
  σημαίνονται ως **P0 εύρημα τιμιότητας** προς αποκατάσταση (design-only — καμία
  διόρθωση κώδικα/κειμένου εδώ).

---

## 11. ΤΙ ΔΕΝ ΕΧΕΙ ΓΙΝΕΙ (ΡΗΤΑ ΑΝΟΙΧΤΑ)

1. **Κανένα destruction pass στο v1.3** (εντολή: STOP BEFORE). Καμία αξίωση κλεισίματος.
2. **Κανένα νέο τυπικό μοντέλο.** Καμία υλοποίηση, κανένα deployment.
3. **Νέα κενά που ονομάζονται (crosswalk):** coverage ledger / national census
   (R-1)· Level-7 jurisprudence plane (status ✗)· εκδοχοποιημένο OpenAPI (EV-5)·
   RBAC/MFA στο cockpit intent· η **σύνθεση** των 7 πιστοποιητικών σε ένα πρωτόκολλο.
4. **Καμία βαθμίδα ποιοτικής επάρκειας.** `MISSION GREECE-1` ορισμένη, μη εκκινημένη.
5. **Άδεια/anonymization** (Q25) παραμένει ανοιχτή· δεν αποφασίζεται εδώ.
6. **P0 υπερ-ισχυρισμοί** (§10) — καταγεγραμμένοι, μη διορθωμένοι (design-only).

---

## 12. ΔΙΑΔΙΚΑΣΙΑ

Δεν ζητείται έγκριση υλοποίησης. Επόμενο βήμα, **μόνο** με ρητή εντολή δημιουργού:
ανεξάρτητο destruction pass στο v1.3 με προδηλωμένα kill tests. Μόνο μετά την
επιβίωσή του τίθεται ζήτημα `SPEC QUALIFIED`. Κανένα έγγραφο δεν ονομάζει το v1.3
canonical πριν από αυτό.
