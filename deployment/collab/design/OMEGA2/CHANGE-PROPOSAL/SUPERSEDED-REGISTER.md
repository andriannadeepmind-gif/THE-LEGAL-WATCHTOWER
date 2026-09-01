# ΜΗΤΡΩΟ ΑΡΧΙΤΕΚΤΟΝΙΚΩΝ — ΤΑΞΙΝΟΜΗΣΗ ΑΝΑ SCOPE ΚΑΙ ΡΟΛΟ

# **ΔΕΝ ΥΠΑΡΧΕΙ ΣΗΜΕΡΑ ΚΑΝΟΝΙΚΟΣ ΠΑΓΩΜΕΝΟΣ ΣΤΟΧΟΣ.**

Καμία αρχιτεκτονική αυτού του αποθετηρίου δεν είναι σήμερα `CANONICAL` ούτε
`FROZEN`. Κανονική κατάσταση **κερδίζεται** μόνο μέσω της κλίμακας ποιοτικής
επάρκειας (`PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md`) — δεν απονέμεται με
δήλωση.

---

## ΔΙΟΡΘΩΣΗ ΤΟΥ ΠΡΟΗΓΟΥΜΕΝΟΥ ΜΗΤΡΩΟΥ (ΥΠΟΧΡΕΩΤΙΚΗ ΑΝΑΓΝΩΣΗ)

Η προηγούμενη έκδοση αυτού του αρχείου (commit `47bed1e7`, αμετάβλητη στο
`78277cc0`) άνοιγε με τη δήλωση:

> «Η ΜΙΑ ΚΑΙ ΜΟΝΗ κανονική target architecture είναι το `CHANGE-PROPOSAL-v1.1.md`.»

**Αυτή η δήλωση ήταν ΣΗΜΑΣΙΟΛΟΓΙΚΑ ΑΣΥΝΕΠΗΣ και ΑΝΑΚΑΛΕΙΤΑΙ.**

Στο **ίδιο commit** (`78277cc0`), το `CHANGE-PROPOSAL-v1.1.md` δηλώνει στην
πρώτη του γραμμή: *«ΚΑΤΑΣΤΑΣΗ: FALSIFIED ΑΠΟ ΤΟ ΔΙΚΟ ΤΗΣ DESTRUCTION PASS. ΔΕΝ
ΕΙΝΑΙ FREEZEABLE»* (9 `FALSIFIED` · 3 `UNCERTAIN` · 1 `SURVIVES`).

Ένα έγγραφο **δεν μπορεί ταυτόχρονα** να είναι ο μοναδικός κανονικός στόχος
**και** καταρριφθέν. Το μητρώο ονόμαζε canonical ένα falsified κείμενο. Η αιτία
ήταν διαδικαστική: το μητρώο γράφτηκε στο `47bed1e7` (πριν από το destruction
pass) και **δεν ενημερώθηκε** όταν το `78277cc0` κατέθεσε την κατάρριψη.

**Κανόνας που προκύπτει:** κανένα έγγραφο δεν ονομάζει canonical έναν στόχο του
οποίου η ίδια η κατάσταση είναι `FALSIFIED`. Ο έλεγχος αυτός είναι πλέον μέρος
του υποχρεωτικού self-audit πριν από κάθε κατάθεση.

---

## ΜΙΑ ΕΔΡΑ ΑΝΑ SCOPE — ΔΥΟ ΞΕΧΩΡΙΣΤΟΙ ΣΤΟΧΟΙ

Δύο στόχοι, ποτέ αναμειγμένοι, με **αυστηρά μονόδρομο** όριο `PUBLIC → PRIVATE`:

- **PUBLIC TARGET** = η δημόσια γραμμή `CHANGE-PROPOSAL` (τρέχων υποψήφιος: v1.3).
- **PRIVATE TARGET** = CPEI + CEILING-CROSSWALK — **DEFERRED, NOT SUPERSEDED**.

Καμία δεύτερη παράλληλη αρχιτεκτονική· κάθε scope έχει **μία** έδρα στόχου.

## ΟΙ ΚΑΤΗΓΟΡΙΕΣ

| κατηγορία | σημασία | στόχος; | επεξεργάζεται; |
|---|---|---|---|
| **`CURRENT PUBLIC CANDIDATE`** | ο τρέχων δημόσιος υποψήφιος — **υποψήφιος, όχι κανονικός** | ναι (public) | ναι, με νέα έκδοση |
| **`DEFERRED / SEPARATE PRIVATE TARGET — NOT SUPERSEDED`** | ο ιδιωτικός στόχος· αναβεβλημένος, **όχι** καταργημένος | ναι (private, deferred) | όχι εδώ — δικό του scope |
| **`ACTIVE ENFORCED FOUNDATION`** | επιβάλλεται **τώρα** από πύλη (ratchet) | — (θεμέλιο) | μόνο με έγκριση |
| **`ACTIVE SHARED TRUST FOUNDATIONS`** | ενεργές προδιαγραφές που **και τα δύο** scopes καταναλώνουν | — (θεμέλιο) | με νέα έκδοση ανά spec |
| **`HISTORICAL / FALSIFIED`** | δεν ορίζει στόχο· τεκμήριο της αναζήτησης | **όχι** | **ποτέ** |
| **`HISTORICAL / SUPERSEDED`** | προηγούμενη έκδοση δημόσιου στόχου, **όχι** falsified | **όχι** | **ποτέ** |
| **`REUSABLE FOUNDATION OR EVIDENCE`** | θεμέλιο/μέτρηση, επαναχρήσιμο **μετά από επαλήθευση** | όχι μόνο του | αρχειακά: ποτέ |

---

## 1. `CURRENT PUBLIC CANDIDATE`

| έγγραφο | κατάσταση |
|---|---|
| **`CHANGE-PROPOSAL-v1.3.md`** | **`CURRENT PUBLIC CANDIDATE / NOT YET FREEZEABLE`** |

Ρητοί περιορισμοί του v1.3:

- **ΔΕΝ** είναι canonical. **ΔΕΝ** είναι frozen. **ΔΕΝ** είναι qualified.
- **ΔΕΝ** έχει δεχθεί destruction pass (εντολή: STOP BEFORE). Καμία θέση αποδεδειγμένη.
- **Μόνο δημόσιο.** Ο ιδιωτικός στόχος (CPEI) είναι **εκτός ευρους**, μονόδρομο
  όριο `PUBLIC → PRIVATE`.
- Βαθμίδα: **καμία** από `SPEC` / `IMPLEMENTATION` / `MISSION` / `PROVIDER-ADOPTION`
  `QUALIFIED`.
- Συνοδεύεται από: `MACHINE-LEGAL-TRUST-PROTOCOL.md`, `V1.3-SEMANTIC-CROSSWALK.md`,
  `AS-IS-EVIDENCE-MANIFEST.md`.

## 1α. `DEFERRED / SEPARATE PRIVATE TARGET — NOT SUPERSEDED`

| έγγραφο | κατάσταση | γιατί |
|---|---|---|
| `LAWMAX-CPEI-TARGET-SPEC.{md,sexp}` | **DEFERRED / SEPARATE PRIVATE TARGET — NOT SUPERSEDED** | το πλήρες Ίδρυμα με `:matter` primitive + L5–L7 (hypothesis workspace, adversarial parliament, legal world simulator) — ο ιδιωτικός matter-solving στόχος· αναβάλλεται, **δεν** καταργείται από τον δημόσιο στόχο |
| `LAWMAX-CEILING-CROSSWALK.{md,sexp}` | **DEFERRED / SEPARATE PRIVATE TARGET — NOT SUPERSEDED** | η «σάρκα» (15 capabilities) πάνω στο CPEI· περιλαμβάνει το Level-7 plane που ο δημόσιος στόχος δανείζεται (§5 v1.3) — αλλά ως **σύνολο** είναι ο ιδιωτικός/πλήρης στόχος |

**Ρητά:** DEFERRED ≠ HISTORICAL· NOT SUPERSEDED. Το v1.3 δεν επιδιορθώνει και δεν
υποβιβάζει το CPEI — απλώς **δεν** ανήκει στο δημόσιο εύρος. Ο δημόσιος στόχος
μπορεί να δανειστεί **επιμέρους** έδρες (π.χ. Level-7 για νομολογία), αλλά ο
ιδιωτικός matter-solving πυρήνας μένει εκτός.

## 1β. `ACTIVE ENFORCED FOUNDATION`

| έγγραφο | κατάσταση | επιβολή |
|---|---|---|
| `LAWMAX-ARCHITECTURE-CONSTITUTION.sexp` | **ACTIVE ENFORCED FOUNDATION** | επιβάλλεται **τώρα** από `--architecture-constitution-gate` (12/12, read-only ratchet): αχαρτογράφητη εντολή/έδρα/store ⇒ κόκκινη πύλη (CPEI §1, CEILING-CROSSWALK §3). Δένει και τα δύο scopes· κανένα δεν το παρακάμπτει. |

## 1γ. `ACTIVE SHARED TRUST FOUNDATIONS`

Ενεργές προδιαγραφές που **και ο δημόσιος και ο ιδιωτικός** στόχος καταναλώνουν —
θεμέλια εμπιστοσύνης, όχι ανταγωνιστικοί στόχοι:

| έγγραφο | ρόλος |
|---|---|
| `PROOF-CARRYING-LAW.md` (PCL-1) | Merkle inclusion + authentic-against-pinned-key (RFC 9162) |
| `LAWMAX-PROOF-OBJECT-SPEC.md` | proof object + census-2 + Legal Proof Receipt + kernel LOC-ceiling |
| `LAWMAX-TRUST-BOOTSTRAP-SPEC.md` | owner key ceremony, out-of-band pinned root, delegation, witnesses, gossip |
| `LAWMAX-KEY-LIFECYCLE-SPEC.md` | TUF-class roles, kid/alg/lineage, rotation/revocation/succession |
| `LAWMAX-TEMPORAL-IDENTITY-DESIGN.md` | διτεμπορική ταυτότητα (per-event) |
| `LAWMAX-TEMPORAL-SEMANTICS-SPEC.md` | διτεμπορική σημασιολογία |
| `LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md` | Work→Expression→Manifestation→Item, authority/institutional registries |

**Κανόνας:** το v1.3 τα **καταναλώνει**, δεν τα αναδιατυπώνει (βλ.
`V1.3-SEMANTIC-CROSSWALK.md`). Αλλαγή σε αυτά = νέα έκδοση **του spec**, με δική του
έγκριση — ποτέ αντιγραφή στη γραμμή `CHANGE-PROPOSAL`.

## 1δ. `HISTORICAL / SUPERSEDED` (δημόσιοι στόχοι, ΟΧΙ falsified)

| έγγραφο | κατάσταση | από |
|---|---|---|
| `CHANGE-PROPOSAL-v1.2.md` | **`HISTORICAL / SUPERSEDED`** (όχι falsified) | αντικαταστάθηκε ως τρέχων δημόσιος υποψήφιος από το v1.3· το περιεχόμενό του που κρατιέται μεταφέρθηκε/διορθώθηκε στο v1.3 (ταυτότητα §2.1, αυθεντικότητα §2.2, cockpit §6, Root Authority §7, AS-IS §9) |

---

## 2. `HISTORICAL / FALSIFIED`

Κανένα από τα παρακάτω δεν ορίζει στόχο. Διατηρούνται ως τεκμήρια. **Δεν
επεξεργάζονται, δεν επιδιορθώνονται, δεν «σώζονται».**

| έγγραφο | τι ισχυριζόταν | κατάσταση | γιατί |
|---|---|---|---|
| **`CHANGE-PROPOSAL-v1.1.md`** | η μία κανονική target architecture | **`HISTORICAL / FALSIFIED / NOT CANONICAL`** | **καταρρίφθηκε από το δικό της destruction pass** (9/13)· μικτή δημόσια+ιδιωτική αρχιτεκτονική που **δεν επιδιορθώνεται** ως τρέχων στόχος |
| `CHANGE-PROPOSAL-v1.0.md` | πρόταση 11 αλλαγών (Π1–Π11) | `HISTORICAL` | απορρίφθηκε· το Π11 χαρακτηρίστηκε `MISSING` και ξαναγράφτηκε |
| `OMEGA2/TARGET-ARCH/WATCHTOWER-TARGET-ARCHITECTURE-v0.1 … v0.7` | διαδοχικές target αρχιτεκτονικές | `HISTORICAL` | ιστορικό εξέλιξης |
| `OMEGA2/TARGET-ARCH/WATCHTOWER-v0.7.1-…`, `-v0.7.2-…` | pre-freeze / counter-challenge closure | `HISTORICAL` | — |
| `OMEGA2/TARGET-ARCH/MERGED-BLUEPRINT-v0.8.md` | συγχωνευμένο blueprint | `HISTORICAL / ΝΕΚΡΟ` | κηρύχθηκε νεκρό στο [0126] |
| `OMEGA2/MERGED-BLUEPRINT.md`, `OMEGA2/MERGED-BLUEPRINT-v0.8.md` | blueprint | `HISTORICAL / ΝΕΚΡΟ` | γράφτηκαν ενάντια στα 44 invariants αντί για τον πυρήνα |
| `OMEGA2/BP/**` | blueprint σετ | `HISTORICAL / ΝΕΚΡΟ` | ό.π. |
| `OMEGA2/CANON-OMEGA2-ARCHITECTURE.md` | αρχιτεκτονική CANON | `HISTORICAL` | — |
| `CANON-OMEGA2/06-FINAL-ARCHITECTURE.md` | «final architecture» | `HISTORICAL` | καμία «τελική» αρχιτεκτονική δεν ήταν ποτέ qualified |
| `CANON-OMEGA2/11-MERGED-BLUEPRINT.md`, `-v0.8.md` | merged blueprint | `HISTORICAL / ΝΕΚΡΟ` | — |
| `CANON-OMEGA2/03-CANDIDATES/design-A\|B\|C` + `04-TOURNAMENT/**` | υποψήφιοι + tournament | `HISTORICAL` | αντικαταστάθηκαν από το non-compensatory tournament του [0127] |
| `LAWMAX-OMEGA-CANON/02-ARCHITECTURE.md` (+ `GR/02-ΑΡΧΙΤΕΚΤΟΝΙΚΗ.md`) | αρχιτεκτονική CANON | `HISTORICAL` | — |
| `LAWMAX-OMEGA-CANON/06-TRANSITION.md`, `07-VERIFICATION.md` | μετάβαση/επαλήθευση | `HISTORICAL` | η μετάβαση ορίζεται πλέον ως μεταβατικά στάδια με ημ. θανάτου |
| `phase2-r5/phase-2/PHASE-2-CANDIDATE-ARCHITECTURES.md`, `PHASE-2-FRONTIER-ARCHITECTURE.md` | υποψήφιες/frontier | `HISTORICAL` | — |
| `deployment/LAWMAX-OMEGA-PLAN.md`, `LAWMAX-CONSOLIDATION-PLAN.md` | σχέδια αρχιτεκτονικής | `HISTORICAL ως προς τον στόχο` | το λειτουργικό/περιγραφικό τους περιεχόμενο για τον σημερινό σπόρο παραμένει περιγραφικό — **ποτέ κανονιστικός στόχος** (ΣΗΜ.: το `LAWMAX-ARCHITECTURE-CONSTITUTION.sexp` **ΔΕΝ** είναι εδώ — είναι `ACTIVE ENFORCED FOUNDATION`, §1β· ήταν λάθος να λογίζεται ιστορικό) |
| `OMEGA2/v07R/REDUCED-CONSTITUTION.md` + `v07R/**` | μειωμένο σύνταγμα v0.7-R | `HISTORICAL / ΑΝΑΣΚΕΥΑΣΜΕΝΟ` | κενότητα `KernelL1.tla` ([0128]) |

---

## 3. `REUSABLE FOUNDATION OR EVIDENCE`

**ΟΡΟΣ ΕΠΑΝΑΧΡΗΣΗΣ (δεσμευτικός):** τίποτα εδώ δεν θεωρείται πλήρες ή σωστό
επειδή υπάρχει. Πριν ενσωματωθεί στο v1.3 πρέπει να **επαληθευθεί** η πραγματική
του υλοποίηση, κάλυψη, τεστ και σχέση με τον στόχο (βλ. `AS-IS-EVIDENCE-MANIFEST.md`
για το αναπαραγώγιμο τεκμήριο). **Η ύπαρξη αρχείου δεν είναι απόδειξη λειτουργίας.**

### 3.1 Κανονιστικό θεμέλιο

| τεκμήριο | ρόλος | επιφύλαξη |
|---|---|---|
| `OMEGA2/O4-NORMATIVE/O4-NORMATIVE-SPEC-v1.0.md` §4/§5/§8/§10 | **ΘΕΜΕΛΙΟ** που το v1.2 επικαλείται ονομαστικά | το §5.5 ήταν το σημείο που κατέρριψε το KT1 — επαναχρησιμοποιείται **μόνο** στην υπό-όρο μορφή (`v−r ≤ Δ+σ`), ποτέ ανεπιφύλακτα |

### 3.2 Αρχειακά τεκμήρια εκτέλεσης (ΜΕΤΡΗΣΕΙΣ — δεν τροποποιούνται ποτέ)

| τεκμήριο | τι είναι | επιφύλαξη |
|---|---|---|
| `formal-v1.1/` (2 νέα μοντέλα + `run-pack.sh` + `EVIDENCE-PACK-RESULTS.txt`) | θετικό evidence pack | **19 έλεγχοι, όχι 20** — βλ. `V1.1-DESTRUCTION-PASS-RECORD.md §8.1` |
| `O4-NORMATIVE/formal/` (7 μοντέλα TLA+ + `TLC-RESULTS.md`) | μοντέλα Round 3 | 7 από τα 9 μοντέλα του «pack v1.1» είναι **προγενέστερα** (§8.3 ό.π.) |
| `formal-v1.1/falsifiers/` (6 εκτελούμενοι + `TPKill` αδρανής) | counterexamples κατάρριψης | **καμία κατατεθειμένη έξοδος εκτέλεσης**· `TPKill` **ουδέποτε εκτελέστηκε** (§2.1, §3 ό.π.) |
| `CANON-OMEGA2/09-BLOCKERS/`, `10-BASE-AUDIT/`, `LAWMAX-OMEGA-CANON/EVIDENCE/` | break reports, base audits, adversary critiques | αφορούν **προγενέστερους γύρους**, όχι το destruction pass του v1.1 |
| `deployment/collab/dialogue/0001–0131` | append-only ιστορικό | ιστορικό, όχι προδιαγραφή |

### 3.3 Υλοποιητικά θεμέλια προς επαλήθευση (ΟΧΙ αποδεδειγμένα)

Η κατάστασή τους **επαληθεύτηκε** στο `CHANGE-PROPOSAL-v1.2.md §12` (AS-IS) με
δεκατρείς ανεξάρτητους ελέγχους μόνο-ανάγνωσης. Περίληψη εκεί· **καμία δεν
θεωρείται δεδομένη χωρίς αυτόν τον έλεγχο**:

- διτεμπορικές έννοιες version-graph · μοντέλα νομικής ταυτότητας
- Akoma Ntoso / RDF / PROV-O / SHACL / ELI / ECLI υλικό
- provenance, Merkle, JWS, RFC 3161 timestamping
- source profiles (`merkle-profile`, `hash-seat-registry`)
- μηχανισμοί στατικής δημοσίευσης
- τυπικά/TLA+ artifacts (21 `.tla` σε 5 καταλόγους)

---

## 4. ΚΑΝΟΝΑΣ ΑΠΟ ΕΔΩ ΚΑΙ ΠΕΡΑ

1. **Μία έδρα ανά scope.** Δημόσιος στόχος = η γραμμή `CHANGE-PROPOSAL` (νυν v1.3)·
   ιδιωτικός στόχος = CPEI (deferred). Αλλαγή δημόσιου στόχου = **νέα έκδοση**
   (v1.4, …), ποτέ νέο παράλληλο έγγραφο, ποτέ ανάμειξη με τον ιδιωτικό.
2. **Κανένα falsified έγγραφο δεν ονομάζεται canonical** — από κανένα αρχείο.
3. **Το `CURRENT CANDIDATE` δεν είναι canonical.** Κανονικότητα κερδίζεται μόνο
   με `MISSION QUALIFIED` και ρητό «εγκρίνω freeze target» του δημιουργού.
4. **Όταν αλλάζει η κατάσταση ενός στόχου, το μητρώο ενημερώνεται στο ΙΔΙΟ
   commit.** Η ασυνέπεια που διορθώθηκε παραπάνω προήλθε ακριβώς από την
   παράλειψη αυτού του βήματος.
