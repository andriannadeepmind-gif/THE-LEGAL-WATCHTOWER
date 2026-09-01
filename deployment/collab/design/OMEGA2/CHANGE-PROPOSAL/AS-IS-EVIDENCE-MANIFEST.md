# AS-IS EVIDENCE MANIFEST — ΑΝΑΠΑΡΑΓΩΓΙΜΟ, ΑΝΑ ΕΝΤΟΛΗ

**Σκοπός (εντολή v1.3 #11):** «Οι 13 verifiers / 541 calls δεν είναι απόδειξη
από μόνα τους.» Αυτό το αρχείο δίνει, ανά ισχυρισμό AS-IS, την **ακριβή εντολή**,
το **path**, το **commit SHA** και το **πραγματικό output/digest** — ώστε τρίτος
να αναπαράγει χωρίς να μας εμπιστευτεί. Ό,τι **δεν** ανάγεται σε ντετερμινιστική
εντολή υποβαθμίζεται ρητά σε `REPORTED / NOT REPRODUCIBLE`.

**Commit υπό audit:** `78277cc05dbb252e0fc3bada5ae10dd6cfa39413`.
Το τρέχον HEAD `973b614b` είναι **απόγονος** που προσθέτει **μόνο** design docs
(v1.2)· καμία πηγή/output δεν άλλαξε μεταξύ των δύο (επαληθεύσιμο:
`git diff --stat 78277cc0 973b614b` αγγίζει μόνο `deployment/collab/…`).

**Βαθμίδες τεκμηρίου:**
- `REPRODUCIBLE-OFFLINE` — μία ντετερμινιστική git/grep εντολή, χωρίς δίκτυο.
- `REPRODUCIBLE-ONLINE` — μία κλήση στο GitHub REST API (κατάσταση CI). Εξαρτάται
  από ζωντανό μητρώο· ο αριθμός μπορεί να αυξηθεί με νέα runs.
- `REPORTED / NOT REPRODUCIBLE` — ερμηνευτικός ισχυρισμός agent που **δεν**
  ανάγεται σε μία εντολή· κρατιέται ως ένδειξη, **όχι** ως απόδειξη.

---

## 1. REPRODUCIBLE-OFFLINE

Κάθε εντολή τρέχει από τη ρίζα του repo, με `A=78277cc05dbb252e0fc3bada5ae10dd6cfa39413`.

### EV-1 · Ακριβώς 6 served corpora (hardcoded)
```
$ git show $A:systems/orchestrator-cli/main.lisp | sed -n 622,625p
(defparameter *served-corpora*
  '("syntagma" "poinikos" "kpoinikis" "astikos" "kpolitikis" "kdioikitikis")
  "The six core Greek legal codes served together by the multi-corpus endpoint.
   Codes whose corpus data is not yet ingested are skipped gracefully.")
```
**Verdict: CONFIRMED.** Έξι, ονομαστικά, hardcoded.

### EV-2 · Πλήθος git-tracked `article-*.txt` κάτω από `output/`
```
$ git ls-tree -r --name-only $A -- output | grep -cE '/article-[^/]*\.txt$'
4550
$ git ls-tree -r --name-only $A -- output | grep -oE '^output/[^/]+/article-[^/]*\.txt$' \
    | sed -E 's#^output/([^/]+)/.*#\1#' | sort | uniq -c
   2035 astikos
    120 constitution
    285 kdioikitikis
    594 kpoinikis
   1054 kpolitikis
    462 poinikos
```
**Verdict: CONFIRMED με ΔΙΟΡΘΩΣΗ.** Το **αναπαραγώγιμο git-tracked** σύνολο είναι
**4.550** (όχι 4.694). Η τιμή 4.694 του v1.2 §12 προήλθε από `find output` στο
**working tree** (μη-tracked/παράγωγα συμπεριλαμβανόμενα) και από μήκη λιστών
`deployment/data/*_clean.json` — διαφορετική μέθοδος. **Ο ακριβής αριθμός είναι
μέθοδο-εξαρτώμενος· η αναπαραγώγιμη έδρα είναι το git-tree = 4.550.** Το «6 σώματα»
(EV-1) παραμένει ανεπηρέαστο.

### EV-3 · Νομολογία — κατανομή δικαστηρίων (input)
```
$ git ls-tree -r --name-only $A -- input/decisions | grep -oE '^input/decisions/[^/]+/' | sort | uniq -c
    161 input/decisions/areios-pagos/
      2 input/decisions/efeteio-peiraios/
      1 input/decisions/protodikeio-athinon/
$ git ls-tree -r --name-only $A -- deployment/data/decisions | grep -cE '[0-9]\.json$'
164
```
**Verdict: CONFIRMED.** 161/164 = 98,2% Άρειος Πάγος· μηδέν ΣτΕ/Ελ.Συν./ΔΕΕ/ΕΔΔΑ.

### EV-4 · ECLI: μηδενική υλοποίηση σε `source/`
```
$ git grep -iEl 'ecli' $A -- 'source/*' | wc -l
0
```
**Verdict: CONFIRMED.**

### EV-5 · OpenAPI/Swagger: κανένα spec αρχείο
```
$ git ls-tree -r --name-only $A | grep -iE 'openapi|swagger' | wc -l
0
```
**Verdict: CONFIRMED.**

### EV-6 · Falsifier runner: 6 kill tests, `TPKill` ουδέποτε
```
$ git show $A:.../formal-v1.1/falsifiers/run-falsifiers.sh | grep -cE '^chk [A-Z]'
6
$ git show $A:.../formal-v1.1/falsifiers/run-falsifiers.sh | grep -c 'TPKill'
0
```
**Verdict: CONFIRMED.** Το KT5 μοντέλο (`TPKill.tla`) υπάρχει αλλά δεν καλείται.

### EV-7 · «20 έλεγχοι» → πραγματικά 19
```
$ git show $A:.../formal-v1.1/run-pack.sh | grep -cE '^check (\.|"\$O4")'
19
$ git show $A:.../formal-v1.1/EVIDENCE-PACK-RESULTS.txt | grep -cE '^(ok|DIFF)'
19
```
**Verdict: CONFIRMED.** Πραγματικές κλήσεις 19· καταγεγραμμένες γραμμές 19· ο
ισχυρισμός «20» (v1.1 ×2, [0131] ×1) είναι υπερμέτρηση κατά ένα.

### EV-8 · Διπλή έδρα — byte-ταυτόσημα μοντέλα σε δύο καταλόγους
```
$ for m in MatterCell PublicRoot; do
    git show $A:.../O4-NORMATIVE/formal/$m.tla        | sha256sum
    git show $A:.../CHANGE-PROPOSAL/formal-v1.1/falsifiers/$m.tla | sha256sum
  done
  MatterCell : 230106c9cc5de049…  (και στα δύο) → IDENTICAL
  PublicRoot : d85e672a110aa244…  (και στα δύο) → IDENTICAL
```
**Verdict: CONFIRMED.** Δύο αντίγραφα ανά μοντέλο — παραβίαση «μία έδρα ανά έννοια».

### EV-9 · Citation collectors = stubs (ρητοί δείκτες)
```
$ git show $A:source/ai-citation-strategy.lisp | grep -niE 'would setup actual|would integrate with actual|simplified'
523:  ;; In production, would setup actual HTTP endpoint
524:  ;; This is simplified
530:  ;; Would integrate with actual telemetry system
773:          ;; This is simplified
```
**Verdict: CONFIRMED** (ως προς την ύπαρξη stub markers). Το «default = καθαρός
stub» (dispatch) είναι **REPORTED** (βλ. §3, R-3).

### EV-10 · P0 — `content-gate` έχει ΕΝΑ σημείο κλήσης, εκτός `emit-site`
```
$ git grep -n 'content-gate' $A -- 'systems/orchestrator-cli/*.lisp'
…/content-validation.lisp:204:(defun content-gate …)          # ορισμός
…/main.lisp:1696: … (content-gate …)                          # ΜΟΝΑΔΙΚΗ κλήση
```
**Verdict: CONFIRMED** (ένα call site, στη verification όχι στο `emit-site`). Ότι
το βήμα δημοσίευσης είναι «ανεπιφύλακτο `soft`» ⇒ **REPORTED** (ροή ελέγχου, R-4).

### EV-11 · Υπερ-ισχυρισμοί — μηχανικά αναγνώσιμοι
```
$ git grep -n 'PRIMARY_SEMANTIC_AUTHORITY' $A -- deployment/provenance-narrative.ttl
120:    infra:authorityStatus "PRIMARY_SEMANTIC_AUTHORITY"@en
$ git grep -n 'Verified all 120' $A -- source/narrative-provenance.lisp
501:  (format stream "  … Verified all 120 articles agains…")
$ git grep -c 'blockchain-anchored' $A -- SEMANTIC-CONTRACT.md   → 1
$ git ls-tree -r --name-only $A | grep -c '\.ots$'               → 0
$ git grep -il 'Primary Semantic Authority' $A | wc -l           → 223
```
**Verdict: CONFIRMED.** Ο ισχυρισμός «Primary Semantic Authority» υπάρχει σε
**223** tracked αρχεία (περιλαμβάνει output/ captured banners)· μηχανικά αναγνώσιμο
`authorityStatus`· κατασκευασμένη «Verified all 120 articles»· εγγύηση
«blockchain-anchored» με **0** `.ots`. **Ασύμβατο με §11 του v1.3.**

---

## 2. REPRODUCIBLE-ONLINE (GitHub REST API)

### EV-12 · CI: 100% αποτυχία, καμία επιτυχία ποτέ
```
GET /repos/andriannadeepmind-gif/THE-LEGAL-WATCHTOWER/actions/workflows/docker-orchestrator.yml/runs
  → total_count = 35 · σελίδα (30) conclusions: {failure: 30}
  → κορυφαίο run: αυτός ο κλάδος ανάπτυξης (v1.2 push), 2026-09-01, conclusion=failure
GET …/provenance.yml/runs                → (v1.2 μέτρηση) 33 runs, όλα failure
GET …/deploy-corpus.yml/runs             → 0 runs ποτέ
```
**Verdict: CONFIRMED.** ≥ 68 runs, **0 επιτυχίες**. Η αποτυχία υπάρχει **και στο
ίδιο το push του v1.2** αυτού του κλάδου. Ο αριθμός runs αυξάνει με τον χρόνο —
η **ιδιότητα** «καμία επιτυχία» είναι το αναπαραγώγιμο.

---

## 3. REPORTED / NOT REPRODUCIBLE — υποβαθμισμένα ρητά

Οι παρακάτω ισχυρισμοί του v1.2 §12 **στηρίζονται σε ανάγνωση/κρίση agent** και
**δεν** ανάγονται σε μία ντετερμινιστική εντολή. Κρατιούνται ως **ενδείξεις προς
επαλήθευση**, **όχι** ως απόδειξη· βαθμίδα `REPORTED / NOT REPRODUCIBLE`.

| # | ισχυρισμός | γιατί δεν είναι αναπαραγώγιμο ως έχει | τι θα το ανήγαγε σε REPRODUCIBLE |
|---|---|---|---|
| R-1 | «καμία εθνική απογραφή· ο απαριθμητής καλύπτει 1 τεύχος × 1 έτος» | απαιτεί ανάγνωση της σημασιολογίας του `enumerate-new-fek` + της παραγωγής — κρίση, όχι grep | εκτελέσιμο τεστ που δείχνει ότι το coverage ledger **δεν** είναι ολική συνάρτηση στον χώρο ΦΕΚ |
| R-2 | «η συνομιλιακή εφαρμογή υπάρχει και είναι πραγματική (`--cockpit`)» | το «πραγματική» είναι κρίση· χωρίς boot/HTTP δεν αποδεικνύεται λειτουργία | εκτέλεση `--cockpit` + HTTP probe σε καθαρό περιβάλλον (εκτός εύρους read-only) |
| R-3 | «ο default συλλέκτης παραπομπών = καθαρός stub» | εξάρτηση από dispatch ροή· απαιτεί ανάγνωση, όχι μία εντολή | test που καλεί τον default observer και δείχνει no-op |
| R-4 | «κόκκινη πύλη δεν εμποδίζει την έκδοση (`emit-site`)» | ισχυρισμός ροής ελέγχου (main.lisp:1335-1358)· απαιτεί εκτέλεση για απόδειξη | test: red content-gate → δείξε ότι το `emit-site` παρ' όλα αυτά γράφει |
| R-5 | «version-graph 2.613 γρ., per-event, καλύπτει terminating events» | το LOC είναι μετρήσιμο· το «καλύπτει σωστά» είναι κρίση επί TLA/tests χωρίς εκτέλεση | model-check `TPKill.tla` + εκτέλεση `version-graph-test` ④β |
| R-6 | «CI 67/67» (v1.2 συνολικό) | ο συνολικός αριθμός runs είναι χρονικά μεταβλητός | η **ιδιότητα** «0 επιτυχίες» (EV-12) είναι το αναπαραγώγιμο, όχι ο αριθμός |

**Συνέπεια για το v1.2/v1.3:** όπου το v1.2 §12 έγραφε `ΕΠΑΛΗΘΕΥΜΕΝΟ/VERIFIED`
για R-1…R-6, ισχύει **`REPORTED / NOT REPRODUCIBLE`** μέχρι να κατατεθεί το
αντίστοιχο εκτελέσιμο τεστ. Τα EV-1…EV-12 παραμένουν `CONFIRMED` (αναπαραγώγιμα).

---

## 4. ΤΙ ΔΕΝ ΑΠΟΔΕΙΚΝΥΕΙ ΑΥΤΟ ΤΟ ΑΡΧΕΙΟ

- Δεν αποδεικνύει **ορθότητα** του νομικού περιεχομένου — μετρά αρχεία και
  συμβολοσειρές, όχι νομική αλήθεια.
- Δεν εκτέλεσε κώδικα, build, test, ή TLC — καμία εκτέλεση (read-only mandate).
- Δεν αποδεικνύει ανυπαρξία άλλων ευρημάτων — είναι μητρώο ιχνηλασιμότητας, όχι
  απόδειξη πληρότητας.
