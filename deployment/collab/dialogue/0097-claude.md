# [0097] REAL-BUILD — Το πραγματικό build βρήκε ό,τι η parse-check ΔΕΝ μπορούσε: writer-class #A(base-char)

- Ημερομηνία: 2026-07-21
- HEAD κύκλου: `ecf45296` (branch `claude/ministry-justice-url-candidates-twghsj`)
- Πρότερο: `def5c73a` (κύκλος [0096], §Δ: «ΔΕΝ έτρεξαν end-to-end … απαιτούν owner-side Docker»)
- Εντολή δημιουργού: «γιατι δεν ετρεξες εσυ πρωτα στο περιβαλλον σου» + «απαγορεύεται
  μπάλωμα ή έτσι απλά για να τρέξει κάτι· πάντα την ανώτατη υλοποίηση, ποτέ workarounds».

## Α. Το επιστημικό λάθος που διορθώθηκε

Το [0096] §Δ δήλωσε τίμια ότι το end-to-end run «απαιτεί owner-side hermetic Docker build»
και ότι το local proof (parse-check + self-contained repros) είναι «αναγκαίο, όχι επαρκές».
Αυτό ήταν **σωστό ως οριοθέτηση αλλά ελλιπές ως προσπάθεια**: υπέθεσα φραγμό (docker daemon
απών) χωρίς να δοκιμάσω την εναλλακτική. Η αλήθεια: οι **vendored deps στο `third-party/`**
(ironclad, babel, alexandria, cffi, log4cl, …) επιτρέπουν **πλήρες, ερμητικό ASDF load ΧΩΡΙΣ
docker/δίκτυο**. Το έτρεξα. Και βρήκε πραγματικά bugs που **καμία** parse-check/text-scan δεν
έπιανε — γιατί είναι bugs **χρόνου εκτέλεσης serialization**, όχι σύνταξης.

Μάθημα, κλειδωμένο: parse-check ≠ build· «φαίνεται σωστό» ≠ «τρέχει σωστό». Η ανώτατη
επαλήθευση είναι η **πραγματική εκτέλεση** όποτε είναι εφικτή — και εδώ ΗΤΑΝ.

## Β. Η κλάση σφάλματος που βρήκε το πραγματικό build: `#A(base-char)` writer leak

`generate-ast-id` / sha256-hex παράγουν `(simple-array base-char (n))` strings. Υπό
`with-standard-io-syntax` (⇒ `*print-readably* t`) το `prin1` τα τυπώνει ως
`#A((n) BASE-CHAR . "…")` — array-literal. Η ΜΙΑ safe-read έδρα (wholesale `#`-deny)
**σωστά** το απορρίπτει ως μη-data. Άρα κάθε writer που έγραφε τέτοιο string υπό std-io
παρήγαγε αρχείο **που δεν διαβαζόταν πίσω** (round-trip break) — σιωπηλά, μέχρι το πρώτο restore.

Αυτό ΔΕΝ ήταν ορατό στην parse-check (η parse-check διαβάζει· δεν *γράφει-και-ξαναδιαβάζει*).
Το πραγματικό build + οι round-trip σουίτες το εξέθεσαν αμέσως.

## Γ. Ανώτατη λύση — ΜΙΑ έδρα data-only εγγραφής (όχι φρουρός, όχι μπάλωμα)

Νέα κανονική έδρα **`orchestrator.safe-read:data-to-string`** (`source/safe-read.lisp`,
commit `52d48762`) — συμμετρική του reader:

- **`%data-only-p` ΠΡΙΝ την εγγραφή** ⇒ fail-closed: μη-data-only form δεν γράφεται ΠΟΤΕ
  (δομικά αδύνατο να παραχθεί αρχείο που ο reader θα απέρριπτε).
- **`*print-readably* nil`** ⇒ τα specialized base-char strings τυπώνονται ως απλά `"…"`
  (η ίδια η ρίζα της κλάσης, εξαλειμμένη — όχι κρυμμένη).
- keyword package, `*read-default-float-format* 'double-float`, no pretty/circle, byte-cap.

**6 έδρες εγγραφής** δρομολογήθηκαν στη ΜΙΑ αυτή έδρα (θάνατος της κλάσης, όχι per-site patch):

| # | Έδρα | Αρχείο | Commit |
|---|---|---|---|
| 1 | BPE `save-bpe-model` | `source/greek-tokenizer-advanced.lisp` | `52d48762` |
| 2 | AST `save-ast-to-file` | `source/legal-ast.lisp` | `52d48762` |
| 3 | Trace `save` | `source/trace-core.lisp` | `52d48762` |
| 4 | `%canon-encode` (canonical item-key/id) | `source/review-queue.lisp` | `ecf45296` |
| 5 | `save-review-queue` | `systems/orchestrator-cli/main.lisp` | `ecf45296` |
| 6 | gate-plenary-manifest | `systems/orchestrator-cli/gates-runner.lisp` | `ecf45296` |

Η #4 ήταν η πιο ύπουλη: το `#A(…)` διέρρεε **μέσα στο ίδιο το κανονικό κλειδί ταυτότητας**
(`%item-key` = injective canon-encode του payload-fingerprint), δηλαδή το item-id έφερε
implementation artifact. Τώρα το κλειδί είναι καθαρό/portable· η injectivity διατηρείται
(strings πάντα quoted+escaped).

## Δ. Stale tests — διορθωμένα στην ΤΑΥΤΟΤΗΤΑ, όχι πειραγμένα να περάσουν

Το πραγματικό build εξέθεσε και 4 tests που έγραφαν με ΞΕΠΕΡΑΣΜΕΝΗ παραδοχή. Καμία αλλαγή
δεν «μαλάκωσε» assertion· κάθε test τώρα χρησιμοποιεί το ΠΡΑΓΜΑΤΙΚΟ artifact:

- `tests/layout-persistence-test.lisp`: `:size 10` → `10.0` (font-info slot = single-float).
- `tests/param-type-roundtrip-test.lisp`: `:keyword` sample → find-symbol + σωστή load-order
  (το `:foo` υπάρχει μόνο αφού διαβαστεί η ίδια η φόρμα).
- `tests/review-queue-test.lisp`: `decide` μέσω `(item-id a)` του enqueued item (το injective
  `%item-key`), όχι hardcoded human-key `"AMENDMENT|L1|art_5"` (προ-injective format).
- `tests/cockpit-test.lisp`: `decide` μέσω content-derived id που το `restore-queue-state`
  επαναϋπολογίζει (δομικό id↔payload binding), όχι fake string.

## Ε. Απόδειξη — ΠΡΑΓΜΑΤΙΚΟ vendored-deps ASDF build (χωρίς docker)

- `orchestrator-core-runtime` LOAD/compile: **EXIT=0**, 0 LOAD-FAIL, 0 caught errors
  (compilerάρει review-queue.lisp + main.lisp + gates-runner.lisp).
- Round-trip σουίτες (real build): safe-read **73/0**, review-queue-safe-read **22/0**,
  bpe **16/0**, layout **20/0**, ast **30/0**, trace **27/0**, jws **13/0**,
  param-roundtrip **12/0**, param-coercion **17/0**, canonical-serialization **12/0**.
- review-queue **66/0**, cockpit **37/0**.
- gate-manifest → `data-to-string` round-trip **6/6**: safe-read EQUAL + **ανεξάρτητος**
  `#`-deny assessor EQUAL + `data-to-string` άρνηση μη-data-only (fail-closed).
- reader-census ratchet **PASS** (133 source αρχεία, 2 δηλωμένες εξαιρέσεις).

## ΣΤ. Τίμια οριοθέτηση (τι ΔΕΝ αποδείχθηκε ακόμη)

- Το vendored-deps load καλύπτει **core-runtime + τα compiled CLI αρχεία**. Δύο σουίτες
  (`write-authority-test` = FIVEAM framework, `capability-api-test` = seat-conflict `ASK`
  όταν cockpit+test φορτώνονται στο ΙΔΙΟ image) **αποτυγχάνουν στο LOAD ΤΑΥΤΟΣΗΜΑ και στο
  pristine tree** — harness artifacts (isolated-image expectation), ΟΧΙ regressions αυτού
  του κύκλου· επιβεβαιώθηκε με stash του batch.
- Παραμένει: owner-side hermetic **Docker build** στο `ecf45296` για (α) τα gated
  crypto/persistence fixtures και (β) runtime gate-set == `gate-registry.sexp`.
  Το vendored-deps run είναι **ισχυρότερο** από το προηγούμενο local proof — αλλά η docker
  invocation glue μένει owner-verified.
- Φάσεις ARCH 2-7 (tasks #66-#71) ανοιχτές.

## Ζ. Δομικό αποτέλεσμα

Reader **και** writer έχουν πλέον **από ΜΙΑ έδρα**: κάθε data-only string διαβάζεται από τη
safe-read και γράφεται από τη `data-to-string`, με **αμοιβαία αντιστρεψιμότητα εγγυημένη εκ
κατασκευής** (writer `%data-only-p` ⇒ ό,τι γράφεται είναι εξ ορισμού αναγνώσιμο). Η κλάση
`#A(base-char)` round-trip break είναι **εξαλειμμένη**, όχι φυλαγμένη. Και αποδείχθηκε με
πραγματική εκτέλεση, όχι μόνο ανάγνωση.
