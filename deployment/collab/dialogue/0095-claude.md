# [0095] ΚΥΚΛΟΣ-2 — Phase 1 (task #65): read/eval/load elimination ΩΣ ΑΝΑΒΑΘΜΙΣΗ (data-only + typed decoder), + 2 CRITICAL κλεισίματα

- Ημερομηνία: 2026-07-20
- Ρόλος: Claude = Χειρουργός Πυρήνα· ΕΣΩΤΕΡΙΚΟΣ αντίπαλος (μέσω δημιουργού) = δεύτερος κριτής [0047]
- HEAD κύκλου: `f6560284` (branch `claude/ministry-justice-url-candidates-twghsj`)
- Πρότερη κατάσταση: `7f3ef6d1` (safe-read quote-deny). Phase-0 census = [0094]/task #64.

## Εντολή δημιουργού (αυτού του κύκλου, verbatim intent)

«δεν αφαιρείς ποτέ λειτουργία — την αναβαθμίζεις μόνο»· «μόνο ανώτατη υλοποίηση, εάν
υπάρχει ανώτερη κάνεις απευθείας την ανώτερη»· «κανένα wrapper κανένα workaround»·
«το ρεπό θα φέρει την υπογραφή της Anthropic — βαθμολογείται η ίδια η Anthropic».
Διόρθωση κλασ. [0094]: τα ΝΕΚΡΑ homoiconicity sinks ΔΕΝ διαγράφονται — **ΑΝΑΒΑΘΜΙΖΟΝΤΑΙ**
(η ικανότητα save/load διατηρείται με data-only schema + typed decoder· ο μηχανισμός
eval/load πεθαίνει). Ο εξωτερικός κριτής (μέσω δημιουργού) το επιβεβαίωσε ως ΣΩΣΤΗ
αρχιτεκτονική κατεύθυνση.

## Α. Ground truth (ΟΛΟ το repo, όχι μόνο ο summary): eval/load/read surface

Ζωντανά eval/load seats που βρέθηκαν (πέρα από το ήδη-κλεισμένο trace-core F3):
- `layout-types:1010` `form-to-element = (eval form)` (+ `element-to-form` παρήγαγε
  `(make-instance …)` κώδικα) — «HOMOICONICITY: data becomes code becomes data».
- `legal-ast`: `form-to-ast = (eval form)` (1617)· `load-ast-from-file = (eval (read stream))`
  (1662)· `provide-node` restart `:interactive = (eval (read))` (1533).
- `greek-tokenizer:905` `load-bpe-model = (load filename)`.
Καθένα με **0 live callers** (μόνο export lines) — αλλά exported public API (⇒ REPL/plugin/
future caller· «dead code» ΔΕΝ αρκεί ως closure, το είπε ο κριτής). Ανώτατη closure =
**αναβάθμιση σε data-only, ΟΧΙ διαγραφή** (εντολή δημιουργού).

## Β. Κλεισίματα ΣΤΗΝ ΕΔΡΑ (upgrade, όχι αφαίρεση)

| Έδρα | Commit | Μηχανισμός → Ανώτατη μορφή | Fixture (gated) |
|---|---|---|---|
| BPE persistence | `e09b2833`,`f6560284` | `(setf *bpe-model* (make-bpe-model …))`+`(load f)` → `:lawmax-bpe-model/1` data + `%bpe-decode` (STRICT: closed+required, deep merge check) + safe-read `read-data-file` | `bpe-persistence-test` (round-trip+9 attacks) |
| Layout serialization | `059fdd7f` | 7 `(make-instance …)` methods + `(eval form)` → `:layout-*/1` data + typed `form-to-element` (ecase allowlist, per-slot type) | `layout-persistence-test` (αναδρ. round-trip+5 attacks) |
| AST persistence | `3150eb9d` | 3 eval seats (form-to-ast/load-ast/restart) → `:*-node/1` data + STRICT decoder (closed+ΥΠΟΧΡΕΩΤΙΚΟ, deep, class allowlist, char→`(:char/1 …)`)· save=`write-file-atomic`· load=`read-data-file` | `ast-persistence-test` (in-mem+file+9 attacks) |
| trace-core (πρότυπο) | `7555166e` | required trace-id/timestamp/layer (θάνατος fabrication)· deep elements· decode χωρίς side-effects· **validate-all-first→ATOMIC commit**· deterministic sort+`write-file-atomic` | `trace-persistence-test` (+8 attacks: fabrication/atomic/deterministic) |

Αρχή: **data serialization ≠ executable Lisp· read ≠ eval· restore ≠ load.**
`read-data-file` (ΟΧΙ `read-data-form`: το streaming primitive ΔΕΝ έχει depth/atom pre-scan —
τα αρχεία θεωρούνται δυνητικά αλλοιώσιμα).

## Γ. Δύο CRITICAL της αντιπαλικής επιθεώρησης (κύκλος-2) — ΖΩΝΤΑΝΑ

1. **intern-DoS σε μη-έμπιστη είσοδο** (regression του adv2-F2): `%coerce-one :keyword` και
   ο route resolver έκαναν `(intern (string-upcase …) :keyword)` σε HTTP query/path ⇒ κάθε
   διαφορετικό request γεννούσε μόνιμο keyword (request-size cap ΔΕΝ φράζει το σωρευτικό).
   **ΔΙΟΡΘΩΣΗ** (`e3697774`): `find-symbol` — μόνο ΗΔΗ-υπαρκτό keyword· άγνωστο ⇒ 400/404
   ΧΩΡΙΣ intern. Fixture: 2 security asserts (άγνωστη τιμή ⇒ coercion-error· παραμένει uninterned).
2. **CI false-green `| tee … || true; ${PIPESTATUS[0]}`**: μετά το `|| true` το PIPESTATUS
   αντικαθίσταται με (0) ΑΚΡΙΒΩΣ όταν το docker αποτυγχάνει (materialization + authoritative
   plenary). **ΔΙΟΡΘΩΣΗ** (`e3697774`): `set +e`/capture/`set -e`, κανένα `|| true`.
   Αποδείχθηκε: BUGGY status=0, FIXED status=7 (fail)/0 (success).

## Δ. Οκτώ σημεία κριτή — τίμια κατάσταση (contract law #3)

1. required+closed schema + deep validation — ✔ trace-core/AST/BPE (layout: strict σε
   numerics/tags/dupes, string slots δέχονται nil).
2. decode χωρίς side-effects + atomic commit — ✔ trace-core (register nil + validate-all-first).
   AST/BPE/layout: pure constructors (καμία registry παρενέργεια).
3. deterministic sort + temp+fsync+atomic rename — ✔ trace-core, AST (`write-file-atomic`)·
   **BPE: ΕΚΚΡΕΜΕΙ** — η ΜΙΑ έδρα `write-file-atomic` (journal, asd#92) φορτώνεται ΜΕΤΑ τον
   tokenizer (asd#55)· δεύτερη έδρα atomic-write ΑΠΑΓΟΡΕΥΕΤΑΙ. Απαιτεί προαγωγή της έδρας σε
   foundational io ΠΡΙΝ τον tokenizer (ξεχωριστή, αποδεδειγμένη φάση· ΟΧΙ security gap —
   κολοβό αρχείο απορρίπτεται fail-closed). Layout: in-memory (N/A).
4. explicit migration — ✔ κανένα legacy artifact (dead· 0 στο δίσκο)· versioned schemas
   (bump = ρητή migration).
5. όχι `read-data-form` σε μη-έμπιστα — ✔ (όλα `read-data-file`/`-file-sequence`, pre-scanned).
6. CI PIPESTATUS — ✔.
7. **machine-readable verdict manifest + exact unique gate-set equality — ΕΚΚΡΕΜΕΙ** (μεγάλο,
   ξεχωριστό). Το CRITICAL false-green (PIPESTATUS) έκλεισε· το manifest είναι η ανώτατη μορφή
   της πύλης (αντικατάσταση text-grep) — δηλώνεται ως επόμενη φάση, ΟΧΙ ολοκληρωμένη.
8. κανένα intern σε user-controlled string — ✔.

## Ε. Υπόλοιπο Phase-1 backlog (ΤΙΜΙΑ — δεν είναι «τέλειο»)

- **~13 ζωντανοί bare `(read s)` data readers** (journal:123, self-constitution:80,
  legal-identity:142, what-if:82, component-scan:111, knowledge-packs:71, corpus-fingerprint:151,
  version-graph:1362/1420, knowledge-graph:246/249, greek-nlp-core:264) — ΔΕΝ έχουν μεταναστεύσει.
  Απαιτούν per-store writer/reader co-upgrade (κάποια γράφουν symbols ⇒ safe-read keyword-only
  θα τα απέρριπτε· χρειάζονται typed decoders). Ρίσκο 0-λάθος ⇒ ανά-έδρα, με απόδειξη.
- **census ratchet**: ο `census-execution-constructs.sh` είναι ΑΠΑΡΙΘΜΗΤΗΣ (print+count), ΟΧΙ
  enforcing. Αναβάθμιση σε enforcing (fail σε νέο/μετακινημένο/αδήλωτο site) ΜΕΤΑ τη μετανάστευση,
  ώστε το registry να μη «νομιμοποιεί» επικίνδυνο κώδικα (προειδοποίηση κριτή).
- **gate manifest (#7)**, **BPE atomicity (#3)** — ως άνω.

## ΣΤ. Απόδειξη — τίμια οριοθέτηση (ΟΧΙ «supreme» πρόωρα)

- Τοπικά: parse-check (`read` όλων των forms, `*read-eval* nil`, stubbed packages) CLEAN σε
  greek-tokenizer/layout-types/legal-ast/trace-core/capability-api/safe-read· CI PIPESTATUS
  bug+fix ΑΝΑΠΑΡΑΧΘΗΚΑΝ σε bash· CLOS initargs επαληθεύτηκαν 1-προς-1.
- **ΔΕΝ ισοδυναμεί με exact-head full-system proof**: τα gated fixtures (bpe/layout/ast/trace
  persistence + param-type security) απαιτούν **owner-side hermetic Docker build** για να
  ΕΚΤΕΛΕΣΤΟΥΝ (πλήρες σύστημα + crypto libs). Parse-check + local logic = αναγκαία, ΟΧΙ επαρκή.
- **Υποχρεωτικό επόμενο βήμα (δημιουργός):** owner Docker build στο `f6560284` ώστε να τρέξουν
  οι gated σουίτες· μετά, enforcing census + 13-reader migration ανά έδρα.

Ετυμηγορία: σοβαρές δομικές αναβαθμίσεις (κλάση eval/load-persistence εξαλείφθηκε στις 4 έδρες·
2 CRITICAL live κλείσιμο)· **ΟΧΙ ακόμη πιστοποιήσιμο ως ανώτατο** πριν το owner-proof + το
εναπομείναν Phase-1 backlog.
