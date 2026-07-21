# [0103] Claude — Κλείσιμο 2ου owner-run (2 κόκκινα) + οι πύλες-Σύνταγμα με πιάνουν και διορθώνονται στην έδρα τους

Ημερομηνία: 2026-07-21 · Βάση: συνέχεια του [0102] (2ος owner Docker γύρος: 2 απέτυχαν)

## Α. Τα 2 κόκκινα του owner build — ρίζες και κλείσιμο ΣΤΗΝ ΕΔΡΑ

1. **dependency-contract-consistency** — `FILE-DOES-NOT-EXIST /app/deps.lock`:
   το deps-verify stage είχε το deps.lock, ο **builder ΟΧΙ** ⇒ το test stage
   (κληρονομεί από builder) δεν το είχε. Τοπικά πέρναγε γιατί το repo checkout
   τα έχει. Κλείσιμο: `Dockerfile` builder stage αποκτά
   `COPY deps.lock DEPENDENCY-CONTRACT.md /app/` (μέρος της ταυτότητας εξαρτήσεων).
2. **architecture-multiplicity** — τα 3 `:failure-memories` implementations
   δηλώνονταν `(:file "deployment/state/lessons.jsonl")` αλλά είναι **runtime
   καταστήματα** (γεννιούνται στο τρέξιμο· απόντα σε καθαρό image). Τοπικά
   πέρναγε ΚΑΤΑ ΛΑΘΟΣ (τα δικά μου τρεξίματα τα είχαν γεννήσει). Κλείσιμο ΟΧΙ
   με probe-χαλάρωμα αλλά με **νέο τυπωμένο τύπο** στο Σύνταγμα:
   `(:store "path")` — ύπαρξη ΔΕΝ απαιτείται· απαιτείται ΕΣΩΤΕΡΙΚΗ συνέπεια:
   κάθε `(:store p)` ∈ `:canonical-stores`. Ο έλεγχος έγινε image-independent
   ΕΚ ΚΑΤΑΣΚΕΥΗΣ (κανένα touch δίσκου), σε test ΚΑΙ στον ⑫ του gate.

## Β. Το ΤΑΒΑΝΙ #1 με έπιασε: 5+1 κόκκινα των πυλών-Σύνταγμα μετά τις δικές μου προσθήκες

Τρέχοντας τις constitution-πύλες μετά τα παραπάνω (πράγμα που ΔΕΝ είχα κάνει
όταν πρόσθεσα την 25η πύλη — δική μου παράλειψη, η μηχανή τη βρήκε):

- ✗② uncharted εντολές `--capability-gate`/`--capability-baseline`, ✗⑤ uncharted
  capability «μέτρο-ικανότητας», ✗⑥ πύλη χωρίς primitive ⇒ **χαρτογραφήθηκαν**
  στο Σύνταγμα (`:primitive :law`, owner `capability-gate.lisp`, envelopes:
  read-only ratchet / συνειδητό GOLDEN_WRITE-style baseline write).
- ✗⑫ ο ίδιος ο gate δεν ήξερε τον τύπο `(:store)` ⇒ έμαθε (store-decl-p +
  cross-check στο :canonical-stores — ΙΔΙΑ σημασιολογία με το test).
- ✗⑬ FF1 literal ρίζα-path στο `verify-truth-gate.lisp`: το selftest fixture
  `"RUN /app/docker/run-standalone-suites.sh …"` (προϋπήρχε). Κλείσιμο δομικά:
  το fixture κατασκευάζεται από το token (`+vt-derived-runner-token+`) χωρίς
  literal ρίζα — ο L7 ελέγχει το όνομα του runner, όχι τη ρίζα.
- ✗⑭ verify-truth `:escape_suite_ungated`: **προϋπάρχον stale check** — από το
  [audit#2] το suite inventory ΠΑΡΑΓΕΤΑΙ από το filesystem και το literal
  «escape-sequences» έφυγε νόμιμα από το Dockerfile, αλλά ο L4 ακόμη το έψαχνε
  εκεί. Κλείσιμο στην έδρα: ο L4 ελέγχει πλέον το ΓΕΓΟΝΟΣ —
  `%vt-escape-suite-gated-p`: το `tests/escape-sequences-test.lisp` υπάρχει ΚΑΙ
  δεν είναι γραμμή-εξαίρεση στο `docker/standalone-suite-exclusions.txt`
  (ίδια γραμματική με τον runner). Καθαρή/testable + 4 νέα selftests (⑪α-δ:
  gated, εξαιρεμένη, απούσα, token-σε-σχόλιο).

## Γ. Απόδειξη

- architecture-constitution-gate: **18/18 ⇒ 0** · verify-truth-gate: **28/28 ⇒ 0**
- architecture-multiplicity 11/11 · dependency-contract 5/5 · seat-integrity 18/0
- Σειριακό rebuild [0101] + πλήρες standalone inventory (βλ. αριθμούς στο STATE-OF-PLAY / commit).

Κανένα μπάλωμα: κάθε κόκκινο κλείστηκε στην έδρα της αιτίας του ή με θάνατο
της κλάσης (stale-literal L4 → έλεγχος γεγονότος· image-dependent probe →
τυπωμένος (:store) τύπος).
