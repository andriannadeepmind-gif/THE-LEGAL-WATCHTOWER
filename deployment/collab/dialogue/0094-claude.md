# [0094] Claude — PHASE 0: CENSUS & BASELINE (trusted/untrusted plane separation)

**Ημερομηνία:** 2026-07-20 · **Πλαίσιο:** εντολή δημιουργού — πλήρης αρχιτεκτονικός
διαχωρισμός trusted/untrusted plane (8 φάσεις· «κάθε φάση κλείνει πλήρως και
εγκρίνεται πριν ανοίξει η επόμενη»). Συνέχεια [0093] (το πρωτόκολλο· Κ-4/Κ-5/Κ-6).
**Αυτή είναι η Phase 0: census + baseline. ΚΑΜΙΑ αλλαγή κώδικα.**

Reproducible enumerator (μη-LLM oracle): `deployment/verify/census-execution-constructs.sh`
(deterministic rg σε ΟΛΟ το first-party repo). Baseline commit **8fce64de**.

## 0 · BASELINE
439 first-party `.lisp` (source 131, systems 168, tests 111 `*-test.lisp`, docker 5,
deployment 10, scripts 4, determinism 2, +build/entrypoint) · 17 ASDF systems · 24 gates.
**Code-only construct counts:** sexp-readers 47 · eval 9 · load/compile 20 ·
reader-macro 7 · with-standard-io-syntax 8 · **os-exec 19** · `*read-eval*` binds 46.

## 1 · ΜΕΘΟΔΟΣ (κατά [0093], μετά τα λάθη)
Μηχανικός census (εγώ) → caller analysis (εγώ) → **ανεξάρτητος αντίπαλος πληρότητας**
(φρέσκο πλαίσιο, ξανα-παρήγαγε την επιφάνεια από ΟΛΟ το repo, reader-fuzzing mindset)
→ **μηχανική επαλήθευση κάθε ισχυρισμού του αντιπάλου** (εγώ, όχι γνώμη) → αυτή η
κατάθεση. Ο αντίπαλος ΒΡΗΚΕ πραγματικά κενά (κάτω §3) — γι' αυτό προηγείται.

## 2 · ΤΑΞΙΝΟΜΗΣΗ ΤΗΣ ΚΛΑΣΗΣ read/eval/load (adversary-verified)

### 2.1 — ΝΕΚΡΑ homoiconicity sinks → ΔΙΑΓΡΑΦΗ (0 live callers, 0 test refs)
Επαληθευμένο: κάθε όνομα λύνεται μόνο σε defun/defgeneric/`#:export`/comment/intra-island
self-ref· κανένα σε command-registry, capability-registry, self-model, `(funcall (find-symbol …))`.
- `legal-ast.lisp`: `form-to-ast` (1615, `eval form`), `load-ast-from-file` (1647, `eval (read stream)`), restart (1533).
- `trace-core.lisp` ΟΛΟ το island: `form-to-trace` (979), `read-trace-from-string` (1006),
  `load-traces-from-file` (1039, `load`), `trace-to-readable-string` (991), macro **`trace-transform`**
  (1053· ΟΧΙ «transform-trace» — διόρθωση ονόματος), restart (274).
- `layout-types.lisp`: `form-to-element` (1006, `eval form`).
- `greek-tokenizer-advanced.lisp`: `load-bpe-model` (901, `load`).
- `parsing.lisp`: `embed-lisp-in-text` (1525) + `evaluate-embedded-forms` (1538, `(mapcar #'eval)` σε `{{…}}`) — dead DSL, restart (864).
**ΔΥΟ όροι διαγραφής (αντίπαλος):** (α) ΟΛΑ είναι **exported symbols** → η διαγραφή σβήνει
ΚΑΙ exports/contracts· (β) εξαφανίζει 3×`(eval form)` + 2×`(eval (read))` + 2×`load` + το `{{}}` eval
χωρίς redesign. Ανύπαρκτος κώδικας δεν εκτελείται — η ανώτατη μορφή.

### 2.2 — ΑΦΥΛΑΚΤΟΙ readers → REDESIGN μέσω της ΜΙΑΣ safe-read έδρας
- `main.lisp:1552` `load-review-queue`: `(read s nil nil)`, ΚΑΜΙΑ δέσμευση (default `*read-eval*` T).
  **11 callers, daemon-wired.** ΔΙΟΡΘΩΣΗ ΑΠΕΙΛΗΣ (αντίπαλος): ο writer `save-review-queue`
  (1557) εκπέμπει `prin1` κανονικών δεδομένων — `prin1` ΠΟΤΕ `#.` → νόμιμη ουρά round-trip
  ασφαλής ακόμη σε T. **Πραγματική έκθεση = filesystem tampering** του `output/review-queue.sexp`,
  ΟΧΙ injection ingested περιεχομένου. Live/must-redesign ισχύει· το framing «ingested content» ΛΑΘΟΣ.
- `corpus-fingerprint.lisp:151` `read-fingerprint-manifest`: `read` μέσα σε `with-standard-io-syntax`
  (→ `*read-eval*` **T**) + `*package* :keyword`, **ΚΑΜΙΑ `*read-eval* nil`** → αφύλακτο read-eval sink.
  **[ΔΙΟΡΘΩΣΗ ΤΑΞΙΝΟΜΗΣΗΣ ΜΟΥ: το είχα ΛΑΘΟΣ ως «guarded».]** Callers μόνο test harness·
  εξαγόμενο· latent RCE αν το golden-manifest path καλωδιωθεί σε production. → migrate στην έδρα.
- `greek-nlp-core.lisp:264` `load-lisp-lexicon`: `(read in nil :eof)` πλήρως αφύλακτο.
  Reachability ΚΕΝΗ σήμερα (μοναδικός constructor `initialize-greek-nlp:628` χωρίς caller· το
  shipped `legal-lexicon.sexp` είναι knowledge-pack μέσω του GUARDED `load-pack`, ΟΧΙ εδώ).
  Live-by-construction (format default `:lisp`, `guess-lexicon-type` → `:lisp` για `*.lisp`).
  → ΔΙΑΓΡΑΦΗ του `:lisp` branch Ή route στην έδρα.

### 2.3 — GUARDED readers → ΕΝΩΣΗ στη ΜΙΑ safe-read έδρα (ΜΙΑ έδρα)
~17 αντίγραφα `(let ((*read-eval* nil) …) (read …))`, dominance επαληθευμένη inline (χωρίς
`with-standard-io-syntax` να ξανα-ενεργοποιεί T μέσα, χωρίς read σε deferred closure):
journal:114/198, self-constitution:80, knowledge-packs:71, capability-api:47, legal-identity:140,
what-if:80, legal-subsumption:44, component-scan:110, version-graph:1361/1419, embeddings-authority:442,
knowledge-graph:243, advisor:84/118, architecture-gate:24, external-benchmark-gate:106 (+ deny-readtable
που ΗΔΗ απαγορεύει `#.`/`#=`/`#S` — το ΠΡΟΤΥΠΟ της έδρας), autonomy-missions:24, self-extension:23,
provenance-gate:161. (knowledge-packs & self-constitution: `*read-eval* nil` ΣΩΣΤΑ ΜΕΣΑ στο w-s-i-s.)

### 2.4 — READER-MACRO trusted-stream → ALLOWLIST per-SITE (sound, επαληθευμένο)
html-parliament-adapter:37, raw-text-adapter:1398/1403, parsing:1137-1161. **Κρίσιμο (αντίπαλος):**
`enable-legal-syntax` (parsing:1169) **χωρίς caller**· `with-raw-text-readtable` μόνο σε test-fixtures·
η ingestion parseάρει με `classify-line`/`read-line` string-ops — ΠΟΤΕ `read` σε document bytes υπό
αυτά τα readtables. Τα readtables ΔΕΝ είναι ενεργά στο ingestion path → ασφαλέστερα απ' ό,τι φοβόμουν.

### 2.5 — INTERACTIVE REPL restarts (trusted-operator console)
parsing:871, ingest-manifest:147 (+ οι restarts του §2.1 που σβήνονται). Read από `*query-io*`
(άνθρωπος), όχι external bytes. Δηλωμένα· `(eval (read))` → `(read)` όπου διατηρηθεί.

### 2.6 — BUILD/TEST/SCRIPT load → εκτός trusted runtime data-path (δηλωμένα)
scripts/*, docker/*, tests/* load-of-source + `kernel-conformance-test.lisp:40/45` (read→eval kernel
text — trusted). Δηλωμένα, μη-migrated.

## 3 · ΤΙ ΒΡΗΚΕ Ο ΑΝΕΞΑΡΤΗΤΟΣ ΑΝΤΙΠΑΛΟΣ (η αξία του adversary-before-closure)
- **Χαμένη ΟΛΟΚΛΗΡΗ κλάση: OS shell exec.** `document-fetch.lisp:99` `(uiop:run-program (list
  "/bin/sh" "-c" command))` — command από `source.fetch_cmd` config (operator-derived σήμερα, ΟΧΙ
  untrusted-doc). Ο census μου (μόνο lisp reader/eval/load) το ΠΑΡΕΛΕΙΨΕ. Προστέθηκε section G:
  **19 os-exec sites** (document-fetch /bin/sh -c· pdf-authority pdftoppm/tesseract σε downloaded PDF —
  list-args, όχι shell· docker/entrypoint· tests). + network egress (html-parliament-adapter:692-730,
  advisor:166, main:949, decisions:334). → trusted-plane fetcher/verifier· capability+sandbox σε Phase 5/6.
- **False-guarded:** `corpus-fingerprint.lisp:151` (§2.2) — το είχα λάθος ως guarded.
- **Threat-model διορθώσεις:** load-review-queue = filesystem tampering (όχι ingested content)·
  load-lisp-lexicon = κενή reachability.
- **Επιβεβαιωμένα ορθά (C1-C4):** νεκρό island (με exported caveat + macro name)· 17 guarded·
  reader-macro allowlist· reflective `(funcall (find-symbol "LIT"))` = literal names, fboundp-gated,
  ή introspection-only (cognition-self:370 introspects, δεν funcallάρει) — ΟΧΙ data-derived-code sink.

## 4 · FIXTURES ΤΗΣ safe-read ΕΔΡΑΣ (μηχανικός oracle κλεισίματος Phase 1)
Η έδρα = data decoder: `*read-eval* nil`, package pinned, size+depth caps, μηδέν reader macros
πλην locked whitelist, typed result ή τίμιο error.
- NEGATIVE (REJECT, όχι εκτέλεση/σιωπηρή διόρθωση): `#.(run-program …)`, `#.(error 1)`, `#=`/`##`
  circular bomb, oversized (>cap), deep-nest bomb (>depth), symbol σε forbidden package, πολλαπλά
  top-level forms, trailing garbage, μη-UTF-8, `(eval …)`/`(load …)` επιστρέφονται ΩΣ ΔΕΔΟΜΕΝΑ ποτέ εκτελεσμένα.
- POSITIVE (ACCEPT, round-trip identical): canonical `(:key val …)` plists, keywords, strings, ints,
  ratios, nested lists — τα σχήματα των 17 guarded sites (journal frames, version-graph, review-queue, manifests).
- REINTRODUCTION oracle: build/CI check ότι bare `read`/`read-from-string`/`eval`/`load` εκτός έδρας +
  per-site allowlist ΚΟΚΚΙΝΙΖΕΙ το build (Phase 5).

## 5 · ΕΝΤΙΜΗ ΟΡΙΟΘΕΤΗΣΗ (τίμια άγνοια)
Το scope της Phase 0 = read/eval/load/reader-macro/dynamic-symbol (η κλάση της Phase 1) + οι
γειτονικές κλάσεις exec/egress ΟΝΟΜΑΣΤΗΚΑΝ (G/H). Βαθύτερος census filesystem-write στις canonical
έδρες + signing-key access + ontology/URI writers = υλικό των Phase 4/5/6, censusάρεται στην αρχή τους.
Η εγγύηση πληρότητας = dated/scoped: «ένας ανεξάρτητος αντίπαλος + μηχανικός enumerator, σήμερα,
βρήκαν αυτή την επιφάνεια· ο enumerator είναι reproducible ώστε η επανεισαγωγή να πιάνεται».

## 6 · PHASE 1 PLAN (preview — ΔΕΝ ξεκίνησε· αναμένει ρητή έγκριση)
Κυρίως ΔΙΑΓΡΑΦΗ: (α) σβήσιμο νεκρού island §2.1 + exports· (β) ΜΙΑ safe-read/structured-decoder
έδρα (πρότυπο = external-benchmark-gate deny-readtable)· (γ) migrate load-review-queue +
corpus-fingerprint:151 + (delete/route) load-lisp-lexicon· (δ) ένωση 17 guarded στην έδρα· (ε)
shadow `read`/`read-from-string`/`eval`/`load` + `sb-ext:lock-package` ώστε bare κλήση ΝΑ ΜΗΝ
ΜΕΤΑΓΛΩΤΤΙΖΕΤΑΙ εκτός έδρας/allowlist· (στ) fixtures §4 + reintroduction gate. Το `main.lisp:1552`
γίνεται δομικά μη-αναπαραστάσιμο. Κάθε βήμα: adversarial-before-close + μηχανικός witness + proof.

**ΑΝΑΜΕΝΕΤΑΙ: «εγκρίνω Phase 1».** Καμία αλλαγή κώδικα μέχρι τότε.
