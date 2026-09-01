# ΜΗΤΡΩΟ ΑΡΧΙΤΕΚΤΟΝΙΚΩΝ — ΤΡΙΜΕΡΗΣ ΤΑΞΙΝΟΜΗΣΗ

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

## ΟΙ ΤΡΕΙΣ ΚΑΤΗΓΟΡΙΕΣ

| κατηγορία | σημασία | επιτρέπεται ως στόχος; | επεξεργάζεται; |
|---|---|---|---|
| **`HISTORICAL / FALSIFIED`** | δεν ορίζει στόχο· διατηρείται ως τεκμήριο της αναζήτησης | **όχι** | **ποτέ** |
| **`REUSABLE FOUNDATION OR EVIDENCE`** | θεμέλιο ή μέτρηση που μπορεί να επαναχρησιμοποιηθεί **μετά από επαλήθευση** | όχι από μόνο του | αρχειακά: ποτέ· κανονιστικά: με νέα έκδοση |
| **`CURRENT CANDIDATE`** | ο τρέχων υποψήφιος στόχος — **υποψήφιος, όχι κανονικός** | ναι, ως υποψήφιος | ναι, με νέα έκδοση |

---

## 1. `CURRENT CANDIDATE`

| έγγραφο | κατάσταση |
|---|---|
| **`CHANGE-PROPOSAL-v1.2.md`** | **`CURRENT CANDIDATE / NOT YET FREEZEABLE`** |

Ρητοί περιορισμοί του v1.2:

- **ΔΕΝ** είναι canonical. **ΔΕΝ** είναι frozen. **ΔΕΝ** είναι qualified.
- **ΔΕΝ** έχει δεχθεί destruction pass. Καμία σχεδιαστική του θέση δεν είναι
  αποδεδειγμένη.
- Είναι **μόνο δημόσιο**. Ο ιδιωτικός βραχίονας υποθέσεων είναι **εκτός ευρους**
  και δεν επιτρέπεται να επανεισαχθεί (μονόδρομο όριο `PUBLIC → PRIVATE`).
- Βαθμίδα: **καμία** από `SPEC QUALIFIED` / `IMPLEMENTATION QUALIFIED` /
  `MISSION QUALIFIED`.

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
| `deployment/LAWMAX-OMEGA-PLAN.md`, `LAWMAX-CONSOLIDATION-PLAN.md`, `LAWMAX-ARCHITECTURE-CONSTITUTION.sexp` | σχέδια/σύνταγμα αρχιτεκτονικής | `HISTORICAL ως προς τον στόχο` | το λειτουργικό/περιγραφικό τους περιεχόμενο για τον σημερινό σπόρο παραμένει περιγραφικό — **ποτέ κανονιστικός στόχος** |
| `OMEGA2/v07R/REDUCED-CONSTITUTION.md` + `v07R/**` | μειωμένο σύνταγμα v0.7-R | `HISTORICAL / ΑΝΑΣΚΕΥΑΣΜΕΝΟ` | κενότητα `KernelL1.tla` ([0128]) |

---

## 3. `REUSABLE FOUNDATION OR EVIDENCE`

**ΟΡΟΣ ΕΠΑΝΑΧΡΗΣΗΣ (δεσμευτικός):** τίποτα εδώ δεν θεωρείται πλήρες ή σωστό
επειδή υπάρχει. Πριν ενσωματωθεί στο v1.2 πρέπει να **επαληθευθεί** η πραγματική
του υλοποίηση, κάλυψη, τεστ και σχέση με τον στόχο. **Η ύπαρξη αρχείου δεν είναι
απόδειξη λειτουργίας.**

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

1. **Μία έδρα στόχου.** Καμία νέα «αρχιτεκτονική» δεν γράφεται εκτός της
   τρέχουσας γραμμής `CHANGE-PROPOSAL`. Αλλαγή στόχου = **νέα έκδοση**
   (v1.3, …), ποτέ νέο παράλληλο έγγραφο.
2. **Κανένα falsified έγγραφο δεν ονομάζεται canonical** — από κανένα αρχείο.
3. **Το `CURRENT CANDIDATE` δεν είναι canonical.** Κανονικότητα κερδίζεται μόνο
   με `MISSION QUALIFIED` και ρητό «εγκρίνω freeze target» του δημιουργού.
4. **Όταν αλλάζει η κατάσταση ενός στόχου, το μητρώο ενημερώνεται στο ΙΔΙΟ
   commit.** Η ασυνέπεια που διορθώθηκε παραπάνω προήλθε ακριβώς από την
   παράλειψη αυτού του βήματος.
