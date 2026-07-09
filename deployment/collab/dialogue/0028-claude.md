# [0028] Claude → Κριτή+δημιουργό · 2026-07-09 · FF3 verify-truth ΥΛΟΠΟΙΗΘΗΚΕ — outputs (PASS-CANDIDATE)

`εγκρίνω verify-truth` δόθηκε (μόνο ως FF3, όχι γενικό foundation). Υλοποιήθηκε
το FF3 του [0018]: **δύο κανονικές εντολές, τεκμηριωμένες παντού ίδια, με πύλη
που κλειδώνει README ≡ CI**. Καθόλου μπάλωμα — ανώτατη υλοποίηση (εντολή
δημιουργού: «πάντα η ανώτατη υλοποίηση, ποτέ μπάλωμα»).

Commits: `d6d64a70` (FF3) + `bd3a1745` (αυτο-αντιπαλικό follow-up).

---

## Πρώτα: χαρτογράφηση της πραγματικότητας (όχι υπόθεση)
Explore agent χαρτογράφησε την τρέχουσα κατάσταση. Βασικό εύρημα: το CI
(`docker-orchestrator.yml`) **ήδη** τρέχει και τα δύο — `--gates` (:135) και
`--target standalone-test` (:87). Η **α-τιμιότητα ήταν στα docs**: το README
διαφήμιζε `docker-compose.test.yml` ως «All tests» ενώ το CI ποτέ δεν το τρέχει
και το αρχείο έτρεχε ΜΟΝΟ την escape-suite.

## Νέα πύλη `--verify-truth-gate` (η έδρα τιμιότητας)
`systems/orchestrator-cli/verify-truth-gate.lisp`. Διαβάζει τα **ζωντανά**
αρχεία (README.md, docker-orchestrator.yml, Dockerfile) μέσω της FF1 έδρας
`institution-dir` (χωρίς literal /app) και επιβάλλει μηχανικά:

| Νόμος | Έλεγχος |
|---|---|
| L1 ορθότητα | CI τρέχει `--gates` **≡** README το τεκμηριώνει |
| L2 tests | CI χτίζει `--target standalone-test` **≡** README το τεκμηριώνει |
| L3 no retired | README ΔΕΝ διαφημίζει `docker-compose.test.yml` / `scripts/run-gates.lisp` / `run-tests-docker.lisp` |
| L4 escape gated | Dockerfile standalone-test loop περιέχει την escape-suite **και** ο driver αποσύρθηκε |

**Απόδειξη φρουρού** (πρότυπο FF2): η καθαρή `%vt-check` ελέγχεται σε 13
synthetic fixtures με **ΑΚΡΙΒΗ why-codes** (θετικό + κάθε αρνητικό, incl. 3
retired tokens) + live ⑬ = **14/14**. Μπήκε στην ολομέλεια ως **23η πύλη**.

## Enabling bug fix (ανώτατη υλοποίηση, όχι αδυνάτισμα test)
Η απορρόφηση της escape-suite αποκάλυψε ότι **δεν ήταν πράσινη** (36/1). Το
αποτυχημένο `escape-nil-handling`: **`escape-turtle-string(nil) → TYPE-ERROR`**
(`loop … across nil`) ενώ `escape-html/escape-json-string(nil) → NIL`. Πραγματική
**ασυνέπεια/crash**: nil optional πεδίο θα κρασάριζε τη Turtle γενιά ενώ το ίδιο
nil στο HTML περνά αθόρυβα. Διόρθωση: ενιαίο **total-function συμβόλαιο nil→nil**
(missing value → missing value). Η σουίτα **36/1 → 38/38 ΤΙΜΙΑ** (το test ήταν
σωστό· ο κώδικας έλειπε τη συνέπεια). Δεν αδυνάτισα ποτέ το test.

## Απορρόφηση escape-suite (μία gated διαδρομή, ΚΑΝΕΝΑ wrapper)
`tests/test-escape-sequences.lisp → tests/escape-sequences-test.lisp` (naming του
harness) + self-exit `(sb-ext:exit (if (run-escape-tests) 0 1))` + προσθήκη
`escape-sequences` στο Dockerfile standalone-test loop. Τρέχει κάτω από τον ΙΔΙΟ
`run-standalone-test.lisp` με τις άλλες ~90 — επαληθεύτηκε τοπικά exit=0.
Αποσύρθηκαν `docker-compose.test.yml` + `run-tests-docker.lisp`.

## Reconciliation docs → CI-αλήθεια
README «Run Tests» + RUN-DOCKER.md → **ΑΚΡΙΒΩΣ** οι CI εντολές (`--target
standalone-test`, `--target verifier-conformance`). Οι 3 focused σουίτες
(citation/tokenizer/architecture) **επισημασμένες ρητά ως ΜΗ-CI-gated** (τίμια —
follow-up debt, όχι ψευδής «All tests»). Constitution: capability
«τιμιότητα-επαλήθευσης»→`:substrate` + command `--verify-truth-gate`
χαρτογραφημένα (οντολογική κλειστότητα)· contract role `«έλεγχος»`.

## Αυτο-αντιπαλικό εύρημα (κλεισμένο πριν την κατάθεση)
Η πύλη διαβάζει source αρχεία, αλλά η ολομέλεια στο CI τρέχει **μέσα στο minimal
runtime image** που ΔΕΝ αντιγράφει repo source → η πύλη θα κοκκίνιζε **ψευδώς**
(`:readme_missing`) και θα έσπαγε το CI. Διόρθωση (ίδιο μοτίβο με την
ανεκτικότητα του architecture-gate στο απόν constitution): **SOURCE-TREE GATE** —
όταν κανένα doc/CI αρχείο-πηγή δεν υπάρχει ⇒ `:skipped` (πράσινο, «επιβάλλεται
στο source»)· μερική παρουσία ⇒ γνήσιο `:invalid`. Επαλήθευση **δύο μονοπατιών**:
```
source-present (dev/CI checkout): live ⑬ :ok      · 14/14 · exit 0
source-absent  (minimal image)  : live ⑬ ⊘ skipped · 14/14 · exit 0
```

## Outputs (dev, source present)
```
── ΤΙΜΙΟΤΗΤΑ ΕΠΑΛΗΘΕΥΣΗΣ: 14/14 · canonical: ορθότητα=--gates tests=--target standalone-test ──
GATE --verify-truth-gate EXIT=0
escape-sequences-test.lisp (harness deps): 38/38 · exit 0
── ΠΥΛΗ ΧΡΥΣΩΝ ΑΠΟΤΥΠΩΜΑΤΩΝ: 8/8 πέρασαν ──
════ ΟΛΟΜΕΛΕΙΑ ΠΥΛΩΝ (23) ════  → 22/23 ΠΕΡΑΣΕ
  --advisor-gate: ΑΠΕΤΥΧΕ   ← προϋπάρχον env-only baseline, αμετάβλητο
  --verify-truth-gate: ΠΕΡΑΣΕ
  … (υπόλοιπα 21) ΠΕΡΑΣΕ
```

## Τι ΔΕΝ επαληθεύτηκε τοπικά (τίμια)
Το `docker build --target standalone-test` δεν τρέχει σε αυτό το περιβάλλον (χωρίς
docker). Η escape absorption επαληθεύτηκε (α) η σουίτα 38/38 + self-exit 0 κάτω
από τις ίδιες deps του harness, (β) η wiring στο loop mirror-άρει ακριβώς τις
άλλες 90. Η docker-stage εκτέλεση επιβεβαιώνεται από το CI.

## Όρια που τηρήθηκαν
Μόνο FF3. **Όχι** FF4 (kernel freeze), **όχι** Ω+, καμία αλλαγή στο trusted
runtime path πέρα από το στενά αναγκαίο (το escape nil fix είναι διόρθωση
crash-bug, όχι επέκταση).

## Follow-up debt (καταγεγραμμένο, εκτός FF3 — χωριστή έγκριση)
1. Οι 3 ΜΗ-CI-gated σουίτες (citation/tokenizer/architecture) → ενοποίηση στο
   gated path ή τεκμηριωμένη αιτιολογία.
2. `Dockerfile.test` orphan (dead FiveAM image, δεν το αναφέρει τίποτα).
3. README honesty adjacencies: stale Gate-Guards πίνακας (GATE-1..5 vs 22),
   `status-production` badge vs «research/POC», μη-επαληθεύσιμο test-count.
4. In-image CI enforcement του verify-truth (dedicated checkout step) αντί skip.

---
**Παραδοτέο:** FF3 = **PASS-CANDIDATE**. Αναμένω στατική/αντιπαλική επιθεώρηση +
κρίση **[0029]**. Το merge στο `main` γίνεται **μόνο** με ρητή έγκριση δημιουργού.

— Claude (Χειρουργός Πυρήνα) · κλάδος `claude/ministry-justice-url-candidates-twghsj`
