# 0164 — OPTION-2 CORE · REVIEW-4 ΣΤΟΧΕΥΜΕΝΗ ΔΙΟΡΘΩΣΗ (R4-1…R4-7)

**Ρόλος:** Χειρουργός Πυρήνα. **Parent/base:** `cc52a27d79e3d60c2a85ed8f85ba0516830406e4` (tree `aacec2f0…`).
**Κυβερνών τεκμήριο:** η ανεξάρτητη έκθεση *INDEPENDENT REVIEW #4 — TARGETED VERIFICATION OF THE REVIEW-3
CORRECTION @ `cc52a27d`*, ετυμηγορία `OPTION-2 INDEPENDENT REVIEW #4 FAILED — CORRECTION REQUIRED — DDI-1
BLOCKED` (1 blocking P2, 1 non-blocking P2, 5 P3). Read-only συνημμένο· ΟΧΙ artifact του repo. Ο κριτής
επιβεβαίωσε νεκρό το P1 του Review-3, αναπαρήγαγε κάθε headline αριθμό με δικό του κώδικα (τέταρτη υλοποίηση
AMC2, δικός του counter) και διόρθωσε το δικό του review #3.

**Εύρος που ΔΕΝ αγγίχτηκε:** DDI‑1…DDI‑4, Επιλογή Α και τα αρχικά 20 Full-Build gates, νέο subsystem/protocol/
store/authority axis/product architecture, production code, frozen v1.4 `88129099` (tree `a2617649`),
Implementation Book/WP‑00, freeze/qualification, δημόσιο/ιδιωτικό όριο, `RAW-JOURNAL-PARTIAL.jsonl`· κανένα
amend/rebase/squash/merge.

---

## 1. Μέθοδος
R4-1 και R4-2 αναπαράχθηκαν σε αναλώσιμα exports ΠΡΙΝ αλλάξει οτιδήποτε (coherent shrink: `universe: PASS`
με 5 families, `corpus: PASS` με 75 cases· απών pinned tool: `FileNotFoundError` traceback). Κάθε κλείσιμο
είναι αλλαγή στην έδρα της κλάσης σφάλματος, επαληθευμένη με εκτέλεση. Πρακτικό ανά εύρημα:
`ARCHITECTURE-MODEL/REVIEW-4-CORRECTION-ADJUDICATION.md`.

## 2. Τι έκλεισε
**R4-1 (blocking).** Το πλαίσιο αναφοράς του «συρρίκνωση» είναι πλέον **η ιστορία που ο υποψήφιος δεν ελέγχει**:
ο `uni-01` διαβάζει floors, authorizations και schema του **base commit** από τα objects του repository και
απαιτεί κάθε base family να κρατά floor ≥ του base· χαμήλωμα, διαγραφή ή μετονομασία = `UNIVERSE-FLOOR-REDUCED`.
Το base είναι canonical χωρίς fallback: μοναδικός πρώτος γονέας για committed candidate, ρητό `--base <full SHA>`
για working-tree/export candidate· 0/πολλοί γονείς, αντιφατικό ρητό base ή απόν base object ⇒ typed
(`UNIVERSE-BASE-AMBIGUOUS`/`-MISMATCH`/`-UNSPECIFIED`/`-UNAVAILABLE` με την ακριβή προϋπόθεση bounded fetch).
Τυπώνονται candidate και base commit/tree/model-root. Ο `cor-01` συμφιλιώνει τα υλοποιημένα counts με τα floors.
**Καμία self-authorization:** μείωση στέκει μόνο σε **base-anchored prospective authorization** — committed στο
base, με previous-minimum = το floor του base, previous-model-root = το root του γονέα του base (το ίδιο το root
του base δεν μπορεί να περιέχει fact που το ονομάζει), μεταφερόμενη αμετάβλητη στον υποψήφιο, χορηγώντας ακριβώς
το δηλωμένο minimum· ξοδεύεται μόλις μετακινηθεί το floor (replay αποτυγχάνει)· authorization μόνο στον
υποψήφιο = `AUTHORIZATION-CANDIDATE-INJECTED`. Κανένας εξωτερικός μηχανισμός έγκρισης δεν υπάρχει στο repo και
κανένας δεν εφευρέθηκε.
**R4-2.** Η κοινή έδρα εκτέλεσης μετατρέπει κάθε spawn failure σε typed `ToolUnavailable` με κλειστό λόγο
(`TOOLCHAIN-MISSING`/`-UNEXECUTABLE`/`-SPAWN-FAILED`)· pre-check ύπαρξης/regular/readable/executable· ο
toolchain check αποτυγχάνει ΠΡΙΝ από κάθε probe· κανένα traceback — και ο harness απορρίπτει κάθε case με traceback.
**R4-3.** Μητρώο των ΔΙΚΩΝ του παιδιών στην έδρα runtime, τερματισμός ως process groups σε INT/TERM/HUP· η εντολή
εκκινεί κάθε φάση ως job σε δικό της process group και προωθεί το σήμα μόνο σε αυτό. Καμία glob διαγραφή· τίποτα
για SIGKILL.
**R4-4.** Μία έδρα επιβάλλει `GIT_OPTIONAL_LOCKS=0` σε ΚΑΘΕ git subprocess (override του κληρονομημένου) και η
εντολή το εξάγει· οι τέσσερις άμεσες κλήσεις git δρομολογήθηκαν μέσω της έδρας.
**R4-5.** Schema **version 4**· bytes διαφορετικά από το base ⇒ έκδοση ακέραια και αυστηρά μεγαλύτερη, αλλιώς
`SCHEMA-VERSION-STALE`· το `CANONICAL-ENCODING.md` §2.1 λέει πλέον την αλήθεια (το model root δεσμεύει τα bytes,
η έκδοση είναι enforced policy discriminator).
**R4-6.** Διορθώσεις στα ζωντανά έγγραφα της έδρας· ρητή διόρθωση εδώ (§3)· «fact types» = δύο αριθμοί,
generated στο packet.
**R4-7.** Το `ro-02` αφαιρέθηκε ως γνήσιο υποσύνολο του content-sensitive `ro-01`. Η εντολή μετρά και τυπώνει
τον ζωντανό αριθμό: **21 OPTION-2 ACCEPTANCE CHECKS — NOT THE ORIGINAL 20 OPTION-A FULL-BUILD GATES**. Η εντολή
του δημιουργού προέβλεπε «20» υποθέτοντας ότι το `ro-02` μετριόταν στην canonical διαδρομή· δεν μετριόταν (αυτό
ήταν το εύρημα R4-7: στο `cc52a27d` ήταν `INFORMATIONAL_PRESENCE_CHECK`), οπότε η αφαίρεσή του αφήνει τους 21
που μέτρησε ο κριτής. Αναφέρεται ο πραγματικός αριθμός, όχι ο αναμενόμενος.

## 3. Ρητή διόρθωση των records του [0163] (R4-6) — το [0163] παραμένει ως έχει
* Το `ACCEPT.sh` **δεν ήταν ποτέ tracked** σε κανένα commit (`git log --all -- '*ACCEPT.sh'` = 0)· έζησε μόνο
  παροδικά στο working tree της συνεδρίας. Οι τρεις διαγραφές ήταν ακριβώς οι τρεις runners.
* Οι προσθήκες ήταν **8 μέσα στην έδρα `ARCHITECTURE-MODEL/` + 1 dialogue record εκτός έδρας** (9 paths).
* Το delta ήταν **+442** NBNC, όχι 443.
* «fact types»: στο `cc52a27d` **32 schema-declared / 31 instantiated**· στο `af0eb3c9` 26/26· στην παρούσα
  διόρθωση **34 declared / 33 instantiated / 18 enums / 14 modules**· ο μόνος declared-but-uninstantiated τύπος
  είναι το `universe-authorization` (ο μηχανισμός υπάρχει· καμία μείωση δεν έχει εξουσιοδοτηθεί).

## 4. TCB — ο αριθμητικός κόφτης καταργήθηκε (εντολή δημιουργού)
Ο `tcb-01` είναι accountability gate: ακριβές file universe κατά είδος, πραγματική μέτρηση, per-file delta έναντι
του επαληθευμένου baseline `af0eb3c9 = 17 / 5.544 / 4.577` (authored `tcb-baseline` rows), και **κάθε αύξηση
αντιστοιχισμένη σε αναπαραχθέν εύρημα** (`tcb-attribution` έναντι του κλειστού `finding-id`). Το σύνολο είναι
μετρημένο γεγονός και complexity signal, όχι λόγος PASS/FAIL. Τίποτα δεν αφαιρέθηκε/συμπιέστηκε/αποδυναμώθηκε.
**Τελική μέτρηση:** **16 αρχεία / 6.550 physical / 5.420 NBNC** έναντι baseline `af0eb3c9` 17 / 5.544 / 4.577 (**+843 NBNC**), και
έναντι `cc52a27d` (5.019) **+401 NBNC** για την παρούσα διόρθωση: `gate_checks.py` +178 (R4-1 base/floors/
authorizations/schema, R4-2 typed tools, tcb accountability), `run_corpus.py` +149 (R4-1 synthetic-base harness,
`--base`, ενοποιημένη μηχανή μεταλλάξεων, G11 σήμα, X73 spawn), `acceptance_runtime.py` +57 (R4-2/R4-3/R4-4),
`build_decision_packet.py` +14 (R4-6 generated fact-type reconciliation), εντολή +3 (R4-3/R4-4/R4-7, καθαρό
μετά την αφαίρεση του `ro-02`). Κάθε γραμμή αντιστοιχισμένη (`tcb-attribution`)· τίποτα δεν αφαιρέθηκε για
αριθμητικό λόγο.

## 5. Μπαταρία (§11) — εκτελεσμένη
| δοκιμή | αποτέλεσμα |
|---|---|
| R4 falsifiers X54, X61–X78 (18 data + 1 coded = 19), με τα δύο θετικά controls X68/X76 | **19/19 REJECTED as intended** (X68/X76: PASS ως control), μηδέν traceback |
| πλήρης COMPONENT μπαταρία (69) σε commit-mode depth‑1 clone μετά το exact-object fetch | **69/69** |
| G11 — SIGTERM σε μία από δύο ταυτόχρονες εκτελέσεις | **REJECTED as intended**: μηδέν δικά της workspaces/orphans, η δεύτερη ολοκλήρωσε κανονικά, repo byte-identical |
| G09/G10 — coherent shrink (floor↓+member· floor deleted+family) μέσα από την ΠΡΑΓΜΑΤΙΚΗ top-level εντολή σε αναλώσιμο repo, με αναγέννηση artifacts | **REJECTED as intended** μέσω `uni-01` / `UNIVERSE-FLOOR-REDUCED` |
| depth‑1 clone, `--checks HEAD`, base object απόν | typed `UNIVERSE-BASE-UNAVAILABLE` ονομάζοντας το ακριβές object και το bounded `git fetch --depth=1 <remote> <sha>`, exit 1, μηδέν traceback |
| μετά από fetch ακριβώς του ονομασμένου object | η ίδια canonical διαδρομή: **21/21 PASS, 69/69**, candidate commit/tree + base commit/tree τυπωμένα |
| `--base` αντιφατικό με μοναδικό γονέα / απόν `--base` σε WORKTREE | typed `UNIVERSE-BASE-MISMATCH` / `UNIVERSE-BASE-UNSPECIFIED` |
| strace ολόκληρης της φάσης checks με **κληρονομημένο `GIT_OPTIONAL_LOCKS=1`** (195.082 syscalls) | **0 `.git/index.lock`**, 0 write-class syscalls μέσα στο repo |
| μετάλλαξη πραγματικής αποδυνάμωσης (ο `check_universe` δεν αναφέρει τίποτα), artifacts αναγεννημένα, ΠΛΗΡΗΣ εντολή | `uni-01: PASS` όπως θέλει ο επιτιθέμενος ⇒ X61–X67/X69 NOT REJECTED ⇒ `fls-01 FAIL` ⇒ `ACCEPT model-checks: FAIL` ⇒ composed `CONTROL BROKEN … BATTERY-VACUOUS` (καμία κατασκευασμένη επιτυχία) ⇒ **exit 1** |
| spawn-time typed failure (εκτελέσιμο εξαφανίζεται μετά το pre-check· μη-εκτελέσιμο regular file) | `TOOLCHAIN-MISSING` / `TOOLCHAIN-UNEXECUTABLE`, μηδέν traceback |
| σταθερό σημείο αναγέννησης | `0 changed` |
| πλήρες `ACCEPT` (`--base=cc52a27d…`) στο ακριβές prospective tree | **PASS**: 4/4 subsets, 21 έλεγχοι / 0 FAIL, 69/69 COMPONENT + 11/11 COMPOSED_GATE, control HOLDS, exit 0 |

## 6. Ετυμηγορία
> `OPTION-2 REVIEW-4 CORRECTION COMPLETE — AWAITING TARGETED INDEPENDENT REVIEW #5 — DDI-1 BLOCKED — NOT FROZEN —
> NOT QUALIFIED — IMPLEMENTATION BLOCKED`

Κανένα structural PASS δεν παρουσιάζεται ως semantic/legal/security/operational proof· κανένας verifier/kernel/
model δεν χαρακτηρίζεται perfect, sound, complete ή freeze-ready· το `400/400` είναι budget ΜΙΑΣ διαδρομής. Τα
21 counted checks ΔΕΝ είναι, δεν υποκαθιστούν και δεν εκτελούν τα αρχικά 20 gates της Επιλογής Α. Στάση.
