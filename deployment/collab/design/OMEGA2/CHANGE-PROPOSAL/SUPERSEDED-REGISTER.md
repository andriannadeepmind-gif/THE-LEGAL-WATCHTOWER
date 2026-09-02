# ΜΗΤΡΩΟ ΑΡΧΙΤΕΚΤΟΝΙΚΩΝ — ΤΑΞΙΝΟΜΗΣΗ ΑΝΑ PROFILE, ΡΟΛΟ ΚΑΙ ΙΣΤΟΡΙΑ

# **ΔΕΝ ΥΠΑΡΧΕΙ ΣΗΜΕΡΑ ΚΑΝΟΝΙΚΟΣ ΠΑΓΩΜΕΝΟΣ ΣΤΟΧΟΣ.**

Καμία αρχιτεκτονική αυτού του αποθετηρίου δεν είναι σήμερα `CANONICAL` ούτε
`FROZEN` ούτε `QUALIFIED`. Κανονική κατάσταση **κερδίζεται** μόνο μέσω της κλίμακας
ποιοτικής επάρκειας (`PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md §2`) — δεν
απονέμεται με δήλωση.

---

## ΔΙΟΡΘΩΣΕΙΣ ΠΡΟΗΓΟΥΜΕΝΩΝ ΕΚΔΟΣΕΩΝ ΤΟΥ ΜΗΤΡΩΟΥ (ΥΠΟΧΡΕΩΤΙΚΗ ΑΝΑΓΝΩΣΗ)

### Διόρθωση 2 (2026-09-01, εντολή δημιουργού «PUBLIC ABSOLUTE-CEILING CLOSURE»)

Η προηγούμενη έκδοση αυτού του αρχείου (commit `9dabc2bb`) ταξινομούσε:

> «`LAWMAX-CPEI-TARGET-SPEC.{md,sexp}` + `LAWMAX-CEILING-CROSSWALK.{md,sexp}` =
> DEFERRED / SEPARATE PRIVATE TARGET — NOT SUPERSEDED» και «PRIVATE TARGET = CPEI».

**Αυτή η ταξινόμηση ΑΝΑΚΑΛΕΙΤΑΙ.** Το CPEI **δεν είναι ιδιωτικό**. Είναι η **κοινή
συνταγματική θεσμική αρχιτεκτονική** και χωρίζεται σε **profiles**, όχι σε
ανταγωνιστικές αρχιτεκτονικές (`CHANGE-PROPOSAL-v1.4.md §1`):

1. `CPEI CONSTITUTIONAL CORE` — κοινό·
2. `CPEI PUBLIC OBSERVATORY PROFILE` — ο τρέχων δημόσιος υποψήφιος (v1.4), που
   χρησιμοποιεί **και τις 12** στρώσεις L1–L12 (συμπεριλαμβανομένων των δημόσιων
   L5–L7)·
3. `CPEI PRIVATE MATTER PROFILE` — αναβεβλημένο· μόνο οι ιδιωτικοί ΤΥΠΟΙ (Matter,
   Client, privileged material, case file, private strategy, opponent modelling,
   case-specific prediction, matter-specific simulation, private use telemetry)
   απουσιάζουν δομικά από το δημόσιο profile.

Η αιτία της παλιάς ταξινόμησης ήταν σύγχυση **προϊόντος** (public observatory vs
private matter system) με **αρχιτεκτονική** (CPEI). Το Stage A το ανέδειξε
έμμεσα (RC-23: το cockpit intent εδραζόταν σε «ιδιωτικό» envelope που στην
πραγματικότητα είναι το κοινό InstitutionalAct). **Κανένα έγγραφο δεν αποκαλεί
ξανά ολόκληρο το CPEI ιδιωτικό** — ο `V1.4-CONTRADICTION-OMISSION-AUDIT.sh` το
ελέγχει μηχανικά σε όλα τα active docs.

### Διόρθωση 1 (2026-09-01, διατηρείται)

Η έκδοση του commit `47bed1e7` (αμετάβλητη στο `78277cc0`) άνοιγε με τη δήλωση:

> «Η ΜΙΑ ΚΑΙ ΜΟΝΗ κανονική target architecture είναι το `CHANGE-PROPOSAL-v1.1.md`.»

**Αυτή η δήλωση ήταν ΣΗΜΑΣΙΟΛΟΓΙΚΑ ΑΣΥΝΕΠΗΣ και ΑΝΑΚΑΛΕΙΤΑΙ.** Στο ίδιο commit το
v1.1 δήλωνε *«ΚΑΤΑΣΤΑΣΗ: FALSIFIED ΑΠΟ ΤΟ ΔΙΚΟ ΤΗΣ DESTRUCTION PASS»* (9 `FALSIFIED`
· 3 `UNCERTAIN` · 1 `SURVIVES`). Ένα έγγραφο **δεν μπορεί ταυτόχρονα** να είναι ο
μοναδικός κανονικός στόχος **και** καταρριφθέν. **Κανόνας που προκύπτει:** κανένα
έγγραφο δεν ονομάζει canonical έναν στόχο του οποίου η ίδια η κατάσταση είναι
`FALSIFIED`. Ο έλεγχος είναι μέρος του υποχρεωτικού self-audit πριν από κάθε κατάθεση.

---

## ΜΙΑ ΑΡΧΙΤΕΚΤΟΝΙΚΗ, ΤΡΙΑ PROFILES, ΜΙΑ ΕΔΡΑ ΑΝΑ PROFILE

- **CPEI CONSTITUTIONAL CORE** = `LAWMAX-CPEI-TARGET-SPEC.{md,sexp}` +
  `LAWMAX-CEILING-CROSSWALK.{md,sexp}` + `LAWMAX-ARCHITECTURE-CONSTITUTION.sexp` + οι
  ACTIVE SHARED TRUST FOUNDATIONS.
- **CPEI PUBLIC OBSERVATORY PROFILE** = η δημόσια γραμμή `CHANGE-PROPOSAL` (τρέχων
  υποψήφιος: **v1.4**) με τις έδρες της (MLTP v3, crosswalk, traceability, Q-tests,
  dominance, slices, sequence, audit).
- **CPEI PRIVATE MATTER PROFILE** = **δεν υπάρχει έγγραφο-στόχος** (αναβεβλημένο· δεν
  σχεδιάζεται τώρα). Τα συστατικά με disposition `DEFER_PRIVATE`
  (`PUBLIC-OBSERVATORY-CROSSWALK.md §A`) είναι ο σπόρος του.

Όριο: **αυστηρά μονόδρομο** `PUBLIC → PRIVATE` (v1.4 §1.3/§1.4· Q20). Καμία δεύτερη
παράλληλη αρχιτεκτονική· κάθε profile έχει **μία** έδρα στόχου.

---

## ΟΙ ΚΑΤΗΓΟΡΙΕΣ

| κατηγορία | σημασία | στόχος; | επεξεργάζεται; |
|---|---|---|---|
| **`CURRENT PUBLIC CANDIDATE`** | ο τρέχων δημόσιος υποψήφιος — **υποψήφιος, όχι κανονικός** | ναι (public profile) | ναι, με νέα έκδοση ΜΟΝΟ με ονομαστικό falsifier (anti-loop 12) |
| **`ACTIVE SHARED CORE`** | το CPEI ως κοινή αρχιτεκτονική (profiles, όχι ανταγωνιστές) | — (σκελετός και των δύο profiles) | με νέα έκδοση του spec, με δική του έγκριση |
| **`DEFERRED PRIVATE PROFILE`** | ο ιδιωτικός matter-solving profile· αναβεβλημένος, **όχι** καταργημένος, **όχι** έγγραφο ακόμη | ναι (private, deferred) | όχι τώρα |
| **`ACTIVE ENFORCED FOUNDATION`** | επιβάλλεται **τώρα** από πύλη (ratchet) | — (θεμέλιο) | μόνο με έγκριση |
| **`ACTIVE SHARED TRUST FOUNDATIONS`** | ενεργές προδιαγραφές που **και τα δύο** profiles καταναλώνουν | — (θεμέλιο) | με νέα έκδοση ανά spec· versioned precedence δηλώνεται ρητά (MLTP v3 §4.5) |
| **`HISTORICAL / FALSIFIED`** | δεν ορίζει στόχο· τεκμήριο της αναζήτησης | **όχι** | **ποτέ** |
| **`HISTORICAL / SUPERSEDED`** | προηγούμενη έκδοση δημόσιου στόχου ή έδρας, **όχι** falsified | **όχι** | **ποτέ** (banner μόνο) |
| **`REUSABLE FOUNDATION OR EVIDENCE`** | θεμέλιο/μέτρηση, επαναχρήσιμο **μετά από επαλήθευση** | όχι μόνο του | αρχειακά: ποτέ |

---

## 1. `CURRENT PUBLIC CANDIDATE`

| έγγραφο | κατάσταση |
|---|---|
| **`CHANGE-PROPOSAL-v1.4.md`** | **`CURRENT PUBLIC CANDIDATE / NOT YET FREEZEABLE`** |

Ρητοί περιορισμοί του v1.4:

- **ΔΕΝ** είναι canonical. **ΔΕΝ** είναι frozen. **ΔΕΝ** είναι qualified.
- **ΔΕΝ** έχει δεχθεί validation programme (προδηλωμένο, Q-tests §8). Καμία θέση αποδεδειγμένη.
- **Public profile.** Οι ιδιωτικοί τύποι απουσιάζουν δομικά· μονόδρομο όριο `PUBLIC → PRIVATE`.
- Βαθμίδα: **καμία** από `SPEC` / `IMPLEMENTATION` / `MISSION GREECE` / `SECURITY/OPERATIONS`
  / `PROVIDER-ADOPTION` `QUALIFIED`.
- Συνοδεύεται από (μία έδρα ανά ρόλο): `MACHINE-LEGAL-TRUST-PROTOCOL.md` (v3),
  `PUBLIC-OBSERVATORY-CROSSWALK.md`, `TRACEABILITY-MATRIX.md`,
  `PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md`, `DOMINANCE-MATRIX.md`,
  `VERTICAL-SLICES.md`, `IMPLEMENTATION-SEQUENCE.md`, `AS-IS-EVIDENCE-MANIFEST.md`,
  `V1.4-CONTRADICTION-OMISSION-AUDIT.sh` (+ `.md`, `.out`).
- Γιατί νέα έκδοση: 31 ονομαστικοί falsifiers CONFIRMED στο Stage A
  (`V1.3-DESTRUCTION-PASS/STAGE-A-ADJUDICATION.md`) + ανάκληση της ταξινόμησης CPEI.

## 1α. `ACTIVE SHARED CORE`

| έγγραφο | κατάσταση | ρόλος |
|---|---|---|
| `LAWMAX-CPEI-TARGET-SPEC.{md,sexp}` | **ACTIVE SHARED CORE** | οι 12 στρώσεις, InstitutionalAct (18 πεδία), Constitutional Compiler target, 13 primitives — ο σκελετός ΚΑΙ των δύο profiles |
| `LAWMAX-CEILING-CROSSWALK.{md,sexp}` | **ACTIVE SHARED CORE** | τα 15 επίπεδα ↔ CPEI· §1β δείκτης προς το πλήρες capability universe του public profile (`PUBLIC-OBSERVATORY-CROSSWALK.md §B`)· τα επίπεδα 4, 6 (στρατηγική), 12-ως-αντιδικία ανήκουν ως ΧΡΗΣΗ στο private profile, ως ΜΗΧΑΝΙΣΜΟΣ στο core |

**Ρητά:** το CPEI **δεν** επιδιορθώνεται ούτε υποβιβάζεται από τον δημόσιο υποψήφιο·
ο δημόσιος υποψήφιος **το εφαρμόζει** (profile). Αλλαγή στο CPEI = νέα έκδοση **του
CPEI**, με δική της έγκριση.

## 1β. `DEFERRED PRIVATE PROFILE`

| στοιχείο | κατάσταση | τι |
|---|---|---|
| `CPEI PRIVATE MATTER PROFILE` | **DEFERRED — δεν σχεδιάζεται, δεν υλοποιείται τώρα** | matter-solving πάνω στο `:matter` primitive· Σ4–Σ9 του `ΧΑΡΤΗΣ-ΝΟΗΣΗΣ.md`· συστατικά `DEFER_PRIVATE`: `legal-subsumption.lisp`, `legal-strategy.lisp`, `legal-hypo.lisp`, `legal-precedent.lisp`, `legal-casegrammar.lisp`, `case-workspace.lisp`, `draft-commands.lisp`, `legal-eval.lisp`, `--subsume`/`--argue` |

**Ρητά:** DEFERRED ≠ HISTORICAL· τα ιδιωτικά kill tests της v1.1 (KT2/KT3/KT9/KT12/
KT13) **δεν** λύθηκαν — απλώς δεν έχουν πεδίο στο δημόσιο profile και επιστρέφουν
αυτούσια όταν σχεδιαστεί ο ιδιωτικός.

## 1γ. `ACTIVE ENFORCED FOUNDATION`

| έγγραφο | κατάσταση | επιβολή |
|---|---|---|
| `LAWMAX-ARCHITECTURE-CONSTITUTION.sexp` | **ACTIVE ENFORCED FOUNDATION** | επιβάλλεται **τώρα** από `--architecture-constitution-gate` (12/12, read-only ratchet): αχαρτογράφητη εντολή/έδρα/store ⇒ κόκκινη πύλη (CPEI §1, CEILING-CROSSWALK §3). Δένει και τα δύο profiles· κανένα δεν το παρακάμπτει. |

## 1δ. `ACTIVE SHARED TRUST FOUNDATIONS`

Ενεργές προδιαγραφές που **και τα δύο profiles** καταναλώνουν — θεμέλια
εμπιστοσύνης, όχι ανταγωνιστικοί στόχοι:

| έγγραφο | ρόλος | versioned precedence δηλωμένη στο MLTP v3 |
|---|---|---|
| `PROOF-CARRYING-LAW.md` (PCL-1) | Merkle inclusion RFC 9162 + `authentic()` | §4-5 `authentic()` = **era-1 μόνο**· era-2 = MLTP v3 §8 (RC-15) |
| `LAWMAX-PROOF-OBJECT-SPEC.md` | proof object + census-2 + Legal Proof Receipt + kernel LOC-ceiling | — |
| `LAWMAX-TRUST-BOOTSTRAP-SPEC.md` | owner key ceremony, out-of-band pinned root, delegation, witnesses, gossip | §2 fingerprint = RFC 7638 thumbprint· §3 delegation = MLTP v3 §2.9 μορφή· §4 witnesses = τρεις τάξεις (MLTP v3 §10) |
| `LAWMAX-KEY-LIFECYCLE-SPEC.md` | TUF-class roles, kid/alg/lineage, rotation/revocation/succession | §2.4 continuity = πληροφοριακό· §2.5 = scheduled rotation μόνο (MLTP v3 §9) |
| `LAWMAX-TEMPORAL-IDENTITY-DESIGN.md` | διτεμπορική ταυτότητα (per-event), receipts, μία ρίζα | — |
| `LAWMAX-TEMPORAL-SEMANTICS-SPEC.md` | διτεμπορική σημασιολογία (effectivity conditions) | — |
| `LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md` (+ closure matrix) | Work→Expression→Manifestation→Item, authority/institutional registries, receipts, relations, uncertainty | — |
| `LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md` (POST-C2) | Legal IR semantic **requirements** spec· conflict = adopted scoped bundle· μηχανοποιημένα artifacts = Implementation Book | conflict mechanism ≠ επινοημένος ουσιαστικός κανόνας (semantic-contract §4) |
| `LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md` (POST-C2) | απαριθμήσιμο/επεκτάσιμο/versioned μητρώο ST-01..28 + UNKNOWN_SOURCE_TYPE (schema/entry· ουσιαστικά PENDING_LEGAL_VALIDATION) | census total function (v1.4 §4.1/§4.20) |
| `LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md` (POST-C2) | trust boundary: external bytes ≠ Lisp forms· taint states· SIK-1..9 | NEW external non-evaluating decoder (MISSING, WP-02); `safe-read.lisp` internal-only adjacent foundation· v1.4 §4.21 |
| `LAWMAX-THREAT-MODEL.md` | Θ1–Θ18 | Θ3/Θ4/Θ5/Θ9/Θ10 → v1.4 §4.14· Θ15/Θ16 → MLTP §14/§2.11· Θ17 → v1.4 §4.22· Θ18 → ingress contract |

**Κανόνας:** το v1.4 τα **καταναλώνει**, δεν τα αναδιατυπώνει (βλ.
`PUBLIC-OBSERVATORY-CROSSWALK.md §A.2`). Όπου το v1.4/MLTP v3 απαιτεί διαφορετική
συμπεριφορά, δηλώνεται **ρητή versioned precedence** (MLTP v3 §4.5) — δύο ACTIVE
specs δεν δίνουν ποτέ αντίθετη ετυμηγορία σιωπηλά. Αλλαγή σε αυτά = νέα έκδοση
**του spec**, με δική του έγκριση — ποτέ αντιγραφή στη γραμμή `CHANGE-PROPOSAL`.

## 1ε. `HISTORICAL / SUPERSEDED` (δημόσιοι στόχοι και έδρες, ΟΧΙ falsified)

| έγγραφο | κατάσταση | από |
|---|---|---|
| `CHANGE-PROPOSAL-v1.3.md` | **`HISTORICAL / SUPERSEDED`** (όχι falsified ως σύνολο· 31 ρίζες CONFIRMED στο Stage A χωρίς πλήρη ετυμηγορία — ο κύκλος διακόπηκε `ABORTED_FOR_TARGET_RECONCILIATION`) | v1.4 |
| `CHANGE-PROPOSAL-v1.2.md` | **`HISTORICAL / SUPERSEDED`** | v1.3 |
| `V1.3-SEMANTIC-CROSSWALK.md` | **`HISTORICAL / SUPERSEDED`** | `PUBLIC-OBSERVATORY-CROSSWALK.md` |
| `V1.3-KILL-WITNESSES.md` | **`HISTORICAL / SUPERSEDED`** | `PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md §7` (KW-1 έως KW-63) |
| `MACHINE-LEGAL-TRUST-PROTOCOL.md` v2 (περιεχόμενο στο `9dabc2bb`) | **`HISTORICAL / SUPERSEDED`** στην ίδια έδρα | v3 (ίδιο αρχείο) |

---

## 2. `HISTORICAL / FALSIFIED`

Κανένα από τα παρακάτω δεν ορίζει στόχο. Διατηρούνται ως τεκμήρια. **Δεν
επεξεργάζονται, δεν επιδιορθώνονται, δεν «σώζονται».**

| έγγραφο | τι ισχυριζόταν | κατάσταση | γιατί |
|---|---|---|---|
| **`CHANGE-PROPOSAL-v1.1.md`** | η μία κανονική target architecture | **`HISTORICAL / FALSIFIED / NOT CANONICAL`** | **καταρρίφθηκε από το δικό της destruction pass** (9/13)· μικτή δημόσια+ιδιωτική αρχιτεκτονική που **δεν επιδιορθώνεται** ως τρέχων στόχος |
| `CHANGE-PROPOSAL-v1.0.md` | πρόταση 11 αλλαγών (Π1–Π11) | `HISTORICAL` | απορρίφθηκε· το Π11 χαρακτηρίστηκε `MISSING` και ξαναγράφτηκε |
| `OMEGA2/TARGET-ARCH/WATCHTOWER-TARGET-ARCHITECTURE-v0.1` έως `-v0.7`, `-v0.7.1-*`, `-v0.7.2-*` | διαδοχικές target αρχιτεκτονικές | `HISTORICAL` | ιστορικό εξέλιξης |
| `OMEGA2/TARGET-ARCH/MERGED-BLUEPRINT-v0.8.md`, `OMEGA2/MERGED-BLUEPRINT*.md`, `OMEGA2/BP/**` | blueprints | `HISTORICAL / ΝΕΚΡΟ` | γράφτηκαν ενάντια στα 44 invariants αντί για τον πυρήνα ([0126]) |
| `OMEGA2/CANON-OMEGA2-ARCHITECTURE.md`, `CANON-OMEGA2/06-FINAL-ARCHITECTURE.md`, `CANON-OMEGA2/11-MERGED-BLUEPRINT*.md` | αρχιτεκτονική/«final» CANON | `HISTORICAL` | καμία «τελική» αρχιτεκτονική δεν ήταν ποτέ qualified |
| `CANON-OMEGA2/03-CANDIDATES/design-A\|B\|C` + `04-TOURNAMENT/**` | υποψήφιοι + tournament | `HISTORICAL` | αντικαταστάθηκαν από το non-compensatory tournament του [0127] |
| `LAWMAX-OMEGA-CANON/02-ARCHITECTURE.md` (+ `GR/`), `06-TRANSITION.md`, `07-VERIFICATION.md` | CANON αρχιτεκτονική/μετάβαση | `HISTORICAL` | — |
| `phase2-r5/phase-2/PHASE-2-CANDIDATE-ARCHITECTURES.md`, `PHASE-2-FRONTIER-ARCHITECTURE.md` | υποψήφιες/frontier | `HISTORICAL` | — |
| `deployment/LAWMAX-OMEGA-PLAN.md`, `LAWMAX-CONSOLIDATION-PLAN.md` | σχέδια | `HISTORICAL ως προς τον στόχο` | περιγραφικά· ποτέ κανονιστικός στόχος |
| `OMEGA2/v07R/REDUCED-CONSTITUTION.md` + `v07R/**` | μειωμένο σύνταγμα v0.7-R | `HISTORICAL / ΑΝΑΣΚΕΥΑΣΜΕΝΟ` | κενότητα `KernelL1.tla` ([0128]) |
| `deployment/collab/design/CENSUS-SCOPE.md`, `LAWMAX-OMEGA-SSP-DELIVERABLES/**`, `LAWMAX-OMEGA-CANON/EVIDENCE/**`, `_stageB_*`, `_census_input.json` | παλαιότερες απογραφές/τεκμήρια repo | `HISTORICAL` | τεκμήρια προηγούμενων γύρων |

---

## 3. `REUSABLE FOUNDATION OR EVIDENCE`

**ΟΡΟΣ ΕΠΑΝΑΧΡΗΣΗΣ (δεσμευτικός):** τίποτα εδώ δεν θεωρείται πλήρες ή σωστό
επειδή υπάρχει. **Η ύπαρξη αρχείου δεν είναι απόδειξη λειτουργίας.** Πριν
ενσωματωθεί στο v1.4 πρέπει να **επαληθευθεί** (βλ. `AS-IS-EVIDENCE-MANIFEST.md`).

### 3.1 Κανονιστικό θεμέλιο

| τεκμήριο | ρόλος | επιφύλαξη |
|---|---|---|
| `OMEGA2/O4-NORMATIVE/O4-NORMATIVE-SPEC-v1.0.md` §4/§5/§8/§10 | **ΘΕΜΕΛΙΟ** που το v1.2/v1.3 επικαλούνται | το §5.5 κατέρριψε το KT1 — επαναχρησιμοποιείται **μόνο** στην υπό-όρο μορφή (`v−r ≤ Δ+σ`)· η MLTP v3 §8.3 F0 είναι η έδρα |

### 3.2 Αρχειακά τεκμήρια εκτέλεσης (ΜΕΤΡΗΣΕΙΣ — δεν τροποποιούνται ποτέ)

| τεκμήριο | τι είναι | επιφύλαξη |
|---|---|---|
| `V1.3-DESTRUCTION-PASS/` (`COMPLETED-A1.json` έως `COMPLETED-A4.json`, `STAGE-A-ADJUDICATION.md/.json`, `STAGE-A-RERUN-EVIDENCE.json`, `STAGE-A-RERUN.py`, journal, prompts, mapping, index, `STATUS-ABORTED.md`) | το διακοπέν destruction pass της v1.3 + η ντετερμινιστική adjudication του Stage A | **31 CONFIRMED ρίζες, 15 DUPLICATE_OF, 0 REFUTED, 0 UNREPRODUCIBLE**· A5–A8 ουδέποτε έτρεξαν· **NO VERDICT** για το πλήρες v1.3 |
| `V1.3-CONSISTENCY-AUDIT.sh` + `.md` + `.out` | 64 έλεγχοι v1.3 | regression floor του v1.4 audit (πρέπει να εξακολουθεί exit 0) |
| `formal-v1.1/` (2 μοντέλα + `run-pack.sh` + `EVIDENCE-PACK-RESULTS.txt`) | evidence pack v1.1 | **19 έλεγχοι, όχι 20** — `V1.1-DESTRUCTION-PASS-RECORD.md §8.1` |
| `O4-NORMATIVE/formal/` (7 μοντέλα TLA+ + `TLC-RESULTS.md`) | μοντέλα Round 3 | 7 από τα 9 μοντέλα του «pack v1.1» είναι **προγενέστερα** |
| `formal-v1.1/falsifiers/` (6 εκτελούμενοι + `TPKill` αδρανής) | counterexamples κατάρριψης | **καμία κατατεθειμένη έξοδος**· `TPKill` **ουδέποτε εκτελέστηκε** — validation pass 4 το εκτελεί |
| `CANON-OMEGA2/09-BLOCKERS/`, `10-BASE-AUDIT/`, `LAWMAX-OMEGA-CANON/EVIDENCE/` | break reports, base audits | προγενέστεροι γύροι |
| `deployment/collab/dialogue/0001–0136` | append-only ιστορικό | ιστορικό, όχι προδιαγραφή |

### 3.3 Υλοποιητικά θεμέλια προς επαλήθευση (ΟΧΙ αποδεδειγμένα)

Η κατάστασή τους καταγράφηκε στο `AS-IS-EVIDENCE-MANIFEST.md` (EV-1 έως EV-12 CONFIRMED,
R-1 έως R-6 REPORTED). Πλήρης disposition ανά αρχείο: `PUBLIC-OBSERVATORY-CROSSWALK.md §A`.
**Καμία δεν θεωρείται δεδομένη χωρίς αυτόν τον έλεγχο**: διτεμπορικές έννοιες
version-graph · μοντέλα νομικής ταυτότητας · Akoma Ntoso / RDF / PROV-O / SHACL /
ELI / ECLI υλικό · provenance, Merkle, JWS, RFC 3161 · source profiles · στατική
δημοσίευση · τυπικά/TLA+ artifacts · `authority-v2/` proofs.

---

## 4. ΚΑΝΟΝΑΣ ΑΠΟ ΕΔΩ ΚΑΙ ΠΕΡΑ

1. **Μία αρχιτεκτονική, τρία profiles, μία έδρα ανά profile.** Δημόσιος στόχος = η
   γραμμή `CHANGE-PROPOSAL` (νυν v1.4)· core = CPEI· ιδιωτικός = deferred profile.
   Αλλαγή δημόσιου στόχου = **νέα έκδοση** μόνο με ονομαστικό falsifier (anti-loop 12),
   ποτέ νέο παράλληλο έγγραφο, ποτέ ανάμειξη με τον ιδιωτικό.
2. **Κανένα falsified έγγραφο δεν ονομάζεται canonical** — από κανένα αρχείο.
3. **Το `CURRENT PUBLIC CANDIDATE` δεν είναι canonical.** Κανονικότητα κερδίζεται μόνο
   με `MISSION GREECE QUALIFIED` + `SECURITY/OPERATIONS QUALIFIED` και ρητό «εγκρίνω
   freeze target» του δημιουργού.
4. **Όταν αλλάζει η κατάσταση ενός στόχου ή μιας έδρας, το μητρώο ενημερώνεται στο
   ΙΔΙΟ commit.**
5. **Το CPEI δεν αποκαλείται ιδιωτικό.** Ό,τι είναι ιδιωτικό είναι ΤΥΠΟΣ, όχι
   στρώση: οι 12 στρώσεις είναι κοινές.
6. **Ιστορικοί υποψήφιοι δεν ανταγωνίζονται ποτέ τον τρέχοντα** (anti-loop 11).
