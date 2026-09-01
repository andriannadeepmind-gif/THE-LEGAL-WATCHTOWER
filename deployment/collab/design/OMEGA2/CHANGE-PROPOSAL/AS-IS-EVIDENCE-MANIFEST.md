# AS-IS EVIDENCE MANIFEST v2 — ΠΛΗΡΩΣ ΑΝΑΠΑΡΑΓΩΓΙΜΟ

**Σκοπός:** ανά ισχυρισμό AS-IS, η **πλήρης** εντολή (καμία συντετμημένη διαδρομή),
το **πλήρες 64-char digest** ή committed artifact, και το πραγματικό output — ώστε
τρίτος να αναπαράγει χωρίς εμπιστοσύνη. Ό,τι δεν ανάγεται σε ντετερμινιστική εντολή
= `REPORTED / NOT REPRODUCIBLE` (§3).

**Commit υπό audit:** `78277cc05dbb252e0fc3bada5ae10dd6cfa39413`.
Preamble κάθε εντολής: `cd <repo-root> && A=78277cc05dbb252e0fc3bada5ae10dd6cfa39413`.
HEAD (`973b614b…`, και ο απόγονος v1.3) προσθέτει **μόνο** design docs — έλεγχος:
`git diff --stat 78277cc0 HEAD -- ':!deployment/collab'` → κενό.

**Βαθμίδες:** `REPRODUCIBLE-OFFLINE` (git/grep, χωρίς δίκτυο) · `REPRODUCIBLE-ONLINE`
(GitHub REST API· η **ιδιότητα** αναπαραγώγιμη, ο απόλυτος αριθμός runs αυξάνει) ·
`REPORTED / NOT REPRODUCIBLE` (κρίση agent, όχι μία εντολή).

---

## 1. REPRODUCIBLE-OFFLINE

### EV-1 · Ακριβώς 6 served corpora (hardcoded) — CONFIRMED
```
git show $A:systems/orchestrator-cli/main.lisp | sed -n '622,625p'
```
Output:
```
(defparameter *served-corpora*
  '("syntagma" "poinikos" "kpoinikis" "astikos" "kpolitikis" "kdioikitikis")
  "The six core Greek legal codes served together by the multi-corpus endpoint.
   Codes whose corpus data is not yet ingested are skipped gracefully.")
```
Blob digest του αρχείου (πλήρες):
`8cf601f197ad5223d8b63711806b4635ab8e8f0b26e7d0a0f45e3bc02306a6ae`.

### EV-2 · **ARTIFACT count** `article-*.txt` (ΟΧΙ unique legal-content) — CONFIRMED
```
git ls-tree -r --name-only $A -- output | grep -cE '/article-[^/]*\.txt$'
```
→ `4550`. Per-corpus:
```
git ls-tree -r --name-only $A -- output | grep -oE '^output/[^/]+/article-[^/]*\.txt$' \
  | sed -E 's#^output/([^/]+)/.*#\1#' | sort | uniq -c
```
→ `2035 astikos · 120 constitution · 285 kdioikitikis · 594 kpoinikis · 1054 kpolitikis · 462 poinikos`.

**ΡΗΤΗ ΟΡΙΟΘΕΤΗΣΗ:** το `4550` είναι **πλήθος git-tracked ARTIFACT αρχείων**
`article-*.txt` κάτω από `output/` — **ΟΧΙ** πλήθος μοναδικών νομικών διατάξεων.
Το κάθε άρθρο εκπέμπεται σε πολλαπλές σειριοποιήσεις (.txt/.html/.ttl/.jsonld/.hash)
και υπάρχουν παράγωγα/legacy δέντρα· ο αριθμός μοναδικού νομικού περιεχομένου δεν
μετριέται εδώ. Η τιμή 4.694 της v1.2 §12 προήλθε από διαφορετική μέθοδο (`find` στο
working tree + μήκη `deployment/data/*_clean.json`) — **μέθοδο-εξαρτώμενη**. Η μόνη
αναπαραγώγιμη έδρα είναι το git-tree artifact count = **4550**. Το «6 σώματα» (EV-1)
είναι ανεξάρτητο.

### EV-3 · Νομολογία 161/164 = 98,2% Άρειος Πάγος — CONFIRMED
```
git ls-tree -r --name-only $A -- input/decisions \
  | grep -oE '^input/decisions/[^/]+/' | sort | uniq -c
```
→ `161 areios-pagos/ · 2 efeteio-peiraios/ · 1 protodikeio-athinon/`.
```
git ls-tree -r --name-only $A -- deployment/data/decisions | grep -cE '[0-9]\.json$'
```
→ `164`. Μηδέν ΣτΕ/Ελ.Συν./ΔΕΕ/ΕΔΔΑ.

### EV-4 · ECLI: μηδενική υλοποίηση σε `source/` — CONFIRMED
```
git grep -iEl 'ecli' $A -- 'source/*' | wc -l
```
→ `0`.

### EV-5 · OpenAPI/Swagger: κανένα spec — CONFIRMED
```
git ls-tree -r --name-only $A | grep -iE 'openapi|swagger' | wc -l
```
→ `0`.

### EV-6 · Falsifier runner: 6 kill tests, `TPKill` ουδέποτε — CONFIRMED
```
git show $A:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/formal-v1.1/falsifiers/run-falsifiers.sh | grep -cE '^chk [A-Z]'
git show $A:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/formal-v1.1/falsifiers/run-falsifiers.sh | grep -c 'TPKill'
```
→ `6` και `0`. Blob digest του runner (πλήρες):
`a23dbd6e82211c4339687c44bcfc11e87587f86c8ff02231044d0b59160c8774`.

### EV-7 · «20 έλεγχοι» → πραγματικά 19 — CONFIRMED
```
git show $A:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/formal-v1.1/run-pack.sh | grep -cE '^check (\.|"\$O4")'
git show $A:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/formal-v1.1/EVIDENCE-PACK-RESULTS.txt | grep -cE '^(ok|DIFF)'
```
→ `19` και `19`. Digests (πλήρη): run-pack.sh
`e8acf05b5c6cf1d019a3f980a09d62bd95b12e2f563494c0d8409ad42b71315c` ·
EVIDENCE-PACK-RESULTS.txt
`70c5de982abd90a776f0e484fb2f43fab71c21bf7e9dfd6af854088522e13816`.

### EV-8 · Διπλή έδρα — byte-ταυτόσημα μοντέλα (πλήρη digests) — CONFIRMED
```
git show $A:deployment/collab/design/OMEGA2/O4-NORMATIVE/formal/MatterCell.tla | sha256sum
git show $A:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/formal-v1.1/falsifiers/MatterCell.tla | sha256sum
git show $A:deployment/collab/design/OMEGA2/O4-NORMATIVE/formal/PublicRoot.tla | sha256sum
git show $A:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/formal-v1.1/falsifiers/PublicRoot.tla | sha256sum
```
→ MatterCell (και τα δύο):
`230106c9cc5de0492c85d43dcebb5088e34e0f33028c40db26984740f590d5fa`
→ PublicRoot (και τα δύο):
`d85e672a110aa244c4109e4c22715e33d00151e06cb84ca2ae2f0e20387743d0`.

### EV-9 · Citation collectors = stubs (ρητοί δείκτες) — CONFIRMED (ύπαρξη markers)
```
git show $A:source/ai-citation-strategy.lisp | grep -niE 'would setup actual|would integrate with actual|simplified'
```
→ `523: In production, would setup actual HTTP endpoint · 524: This is simplified ·
530: Would integrate with actual telemetry system · 773: This is simplified`.
Blob digest (πλήρες): `af9cd72d5bf202d4bdb8129cc44cf1453401880a8f80affc9f98412c74bfa61c`.
(Το «default = καθαρός stub» = **REPORTED**, §3 R-3.)

### EV-10 · P0 — `content-gate` ένα call site, εκτός `emit-site` — CONFIRMED (call sites)
```
git grep -n 'content-gate' $A -- 'systems/orchestrator-cli/content-validation.lisp' 'systems/orchestrator-cli/main.lisp'
```
→ `content-validation.lisp:204` (ορισμός) · `main.lisp:1696` (μοναδική κλήση, εντός
verification). (Το «η δημοσίευση είναι ανεπιφύλακτο soft» = **REPORTED**, §3 R-4.)

### EV-11 · Υπερ-ισχυρισμοί — μηχανικά αναγνώσιμοι — CONFIRMED
```
git grep -c 'PRIMARY_SEMANTIC_AUTHORITY' $A -- deployment/provenance-narrative.ttl   # → 1 (line 120)
git grep -n 'Verified all 120' $A -- source/narrative-provenance.lisp                 # → line 501
git grep -c 'blockchain-anchored' $A -- SEMANTIC-CONTRACT.md                          # → 1
git ls-tree -r --name-only $A | grep -c '\.ots$'                                      # → 0
git grep -il 'Primary Semantic Authority' $A | wc -l                                  # → 223
```
Ο ισχυρισμός υπάρχει σε **223** tracked αρχεία (περιλαμβάνει `output/` captured
banners)· μηχανικά αναγνώσιμο `authorityStatus "PRIMARY_SEMANTIC_AUTHORITY"`·
κατασκευασμένη «Verified all 120 articles»· εγγύηση «blockchain-anchored» με **0**
`.ots`. **Ασύμβατο με v1.3 §11.**

---

## 2. REPRODUCIBLE-ONLINE (GitHub REST API) — ΠΛΗΡΗΣ PAGINATION

### EV-12 · CI: μηδέν `conclusion=success` σε ΟΛΑ τα καταγεγραμμένα runs — CONFIRMED
Εντολές (REST, πλήρης pagination — 30/σελίδα cap):
```
GET /repos/andriannadeepmind-gif/THE-LEGAL-WATCHTOWER/actions/workflows/docker-orchestrator.yml/runs?per_page=30&page=1
GET /repos/andriannadeepmind-gif/THE-LEGAL-WATCHTOWER/actions/workflows/docker-orchestrator.yml/runs?per_page=30&page=2
GET /repos/andriannadeepmind-gif/THE-LEGAL-WATCHTOWER/actions/workflows/provenance.yml/runs?per_page=30&page=1
GET /repos/andriannadeepmind-gif/THE-LEGAL-WATCHTOWER/actions/workflows/provenance.yml/runs?per_page=30&page=2
GET /repos/andriannadeepmind-gif/THE-LEGAL-WATCHTOWER/actions/workflows/deploy-corpus.yml/runs?per_page=30&page=1
```
Μετρημένα (2026-09-01):

| workflow | total_count | runs examined (όλες οι σελίδες) | conclusion=success |
|---|---|---|---|
| `docker-orchestrator.yml` | 36 | 36 (30+6) | **0** |
| `provenance.yml` | 35 | 35 (30+5) | **0** |
| `deploy-corpus.yml` | 0 | 0 | **0** |
| **σύνολο** | **71** | **71** | **0** |

**ΑΚΡΙΒΗΣ ΙΣΧΥΡΙΣΜΟΣ:** και στα **71** καταγεγραμμένα runs, `conclusion=success`
εμφανίζεται **0 φορές** (όλα `failure`)· η αξίωση «0 successes» τεκμηριώνεται με
**πλήρη** pagination, όχι μία σελίδα. **ΤΙΜΙΑ ΕΠΙΦΥΛΑΞΗ:** πολλές αποτυχίες είναι
**περιβαλλοντικές** (docker daemon απών, `deb.debian.org` 403, API session limit —
ρητά στα ίδια τα commit bodies), όχι απόδειξη σπασμένου build. Το αναπαραγώγιμο
γεγονός είναι «καμία επιτυχία στο μητρώο CI», ΟΧΙ «ο κώδικας δεν χτίζεται». Ο
αριθμός runs αυξάνει με τον χρόνο· η **ιδιότητα** (0 successes) είναι το σταθερό.

---

## 3. REPORTED / NOT REPRODUCIBLE — υποβαθμισμένα ρητά

Ερμηνευτικοί ισχυρισμοί agent που **δεν** ανάγονται σε μία εντολή. Ενδείξεις, όχι
απόδειξη· βαθμίδα `REPORTED / NOT REPRODUCIBLE` μέχρι να κατατεθεί εκτελέσιμο τεστ.

| # | ισχυρισμός | τι θα το ανήγαγε σε REPRODUCIBLE |
|---|---|---|
| R-1 | «καμία εθνική απογραφή· απαριθμητής 1 τεύχος × 1 έτος» | test: coverage ledger ΔΕΝ είναι ολική συνάρτηση στον χώρο ΦΕΚ |
| R-2 | «η συνομιλιακή εφαρμογή `--cockpit` είναι πραγματική/λειτουργική» | boot + HTTP probe σε καθαρό περιβάλλον (εκτός read-only εύρους) |
| R-3 | «ο default συλλέκτης παραπομπών = καθαρός stub» | test: κλήση default observer δείχνει no-op |
| R-4 | «κόκκινη πύλη δεν εμποδίζει `emit-site`» | test: red content-gate → `emit-site` γράφει |
| R-5 | «version-graph per-event, καλύπτει terminating events (KT5)» | model-check `TPKill.tla` + `version-graph-test ④β` |
| R-6 | (v1.2) «CI 67/67» — απόλυτος αριθμός | αντικαταστάθηκε από EV-12 (ιδιότητα «0 successes», πλήρης pagination) |

---

## 4. ΤΙ ΔΕΝ ΑΠΟΔΕΙΚΝΥΕΙ

Δεν αποδεικνύει ορθότητα νομικού περιεχομένου (μετρά artifacts/strings, όχι νομική
αλήθεια)· δεν εκτέλεσε κώδικα/build/test/TLC· δεν αποδεικνύει ανυπαρξία άλλων
ευρημάτων (μητρώο ιχνηλασιμότητας, όχι απόδειξη πληρότητας)· η CI αξίωση αφορά το
**μητρώο runs**, όχι τη χτισιμότητα του κώδικα.
