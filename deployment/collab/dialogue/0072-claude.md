# [0072] COCKPIT — ενοποιημένη επιφάνεια + ΕΣΩΤΕΡΙΚΗ ΑΝΤΙΠΑΛΙΚΗ ΕΠΙΘΕΩΡΗΣΗ (κλείσιμο 11 ευρημάτων στην έδρα)

**Ρόλος:** Claude = Χειρουργός Πυρήνα ΚΑΙ (μέσω 2 ανεξάρτητων agents, φρέσκο πλαίσιο,
χωρίς πρόσβαση στο σκεπτικό μου) Κριτής. Πρότυπο [0047]/[0071].

## Τι χτίστηκε
`--cockpit`: ΜΙΑ εντολή, ΜΙΑ θύρα, 4 καρτέλες (Συνομιλία/Δαίμονας/Αμφισβήτηση/Δημοσίευση)
για ΟΛΟΝ τον κύκλο του δημιουργού. **Καμία wrapper**: οι δυνατότητες ορίζονται ΜΙΑ φορά
(`orchestrator.capability:define-capability` :ask/:pending/:decide/:publish) και η HTTP
επιφάνεια είναι ΠΡΟΒΟΛΗ μέσω `orchestrator.capability-api:api-dispatch`. Το AI μένει ΕΚΤΟΣ
trusted path (—serve-mcp). Υβριδικό (COCKPIT_HOST 127.0.0.1 default / 0.0.0.0 όπου θες).

## Πρώτη έκδοση (7c890585) — ΤΙ ΒΡΗΚΑΝ ΟΙ ΚΡΙΤΕΣ
Δύο άξονες. **Άξονας α (ασφάλεια/μοντέλο)** και **άξονας β (μετριότητα)**. 11 ευρήματα,
ΟΛΑ επαληθευμένα στην έδρα (empirical proof όπου χρειάστηκε). Η πρώτη έκδοση ΔΕΝ ήταν η
ανώτατη — ίδιο δίδαγμα με [0068]: το proof πριν τους κριτές ήταν ελλιπές.

### Άξονας α — ασφάλεια
- **S1 CRITICAL — CSRF / state-mutating GET / no Host-guard.** `/api/decide`,`/api/publish`
  εκτελούνταν με απλό GET· καμία επικύρωση Host/Origin ⇒ κάθε σελίδα που επισκέπτεται ο
  δημιουργός μπορούσε να πυροδοτήσει `<img src=…/api/publish>` (zero-knowledge) ή decide, και
  DNS-rebinding διάβαζε `/api/pending`. **Παραβίαζε «άνθρωπος = μόνη αυθεντία».**
- **S2 HIGH — trusted-path enforcement ΑΔΡΑΝΕΣ.** `api-dispatch` δεν περνούσε ΠΟΤΕ
  `require-trust` (μόνο σε tests)· ο δομικός φραγμός «κανένα advisor στο trusted path» ήταν
  no-op στη ΜΙΑ projection απ' όπου περνά κάθε επιφάνεια.
- **S3 HIGH — DOM-XSS.** `esc()` (HTML-entity) ήταν ΛΑΘΟΣ escaper για το context
  `onclick="decide('…')"`· id με `'` (π.χ. `Α'133`, ΦΕΚ-επηρεαζόμενο) έσπαγε το JS-string και
  έτρεχε κώδικα in-origin με `KEY` στο scope.
- **S4 MED — lost-update race** στην ουρά (read-modify-write χωρίς lock, νήμα-ανά-σύνδεση).
- **S5 MED — fail-open σε blank token** (υποκαταστάθηκε από S1 hardening).
- ΚΑΘΑΡΑ (με απόδειξη): JSON-breakout, thread/DoS μοντέλο, `*read-eval* nil` coercion.

### Άξονας β — μετριότητα
- **M1 CRITICAL — η ναυαρχίδα `:decide` ΣΠΑΣΜΕΝΗ.** Περνούσε `:approved`/`:rejected` στην έδρα
  `orchestrator.review:decide`, που δέχεται ΜΟΝΟ `:approve`/`:reject`
  (`apply-decision`: `(ecase decision (:approve :approved)(:reject :rejected))`).
  **Empirical proof:** `:approved` → `CASE-FAILURE`· `:approve` → status APPROVED,
  approved-operations=1. Σε ΥΠΑΡΚΤΟ item → 500. Η μόνη ανθρώπινη-αυθεντία πράξη δεν
  ενέκρινε ποτέ. **Το ΙΔΙΟ latent bug ήδη στην CLI** `review-decide`/`--review-approve`
  (`:approved`), κρυμμένο από swallowing `handler-case` + ψευδές docstring.
- **M2 — ΜΗΔΕΝ tests** για όλη την επιφάνεια (γι' αυτό πέρασε το M1). Παραβίαζε
  «regression lock για ΚΑΘΕ νέα συμπεριφορά» (task #8).
- **M3 — σιωπηλό fallback:** `:ask`/`:publish` τύλιγαν το domain call σε `handler-case`
  ⇒ σφάλμα γινόταν 200 `:result "σφάλμα…"` (fail-OPEN στο trusted path).
- **M4 — διπλή έδρα JSON:** `%cockpit-json` ξαναϋλοποιούσε τη scalar διάκριση δίπλα στη
  δηλωμένη ΜΙΑ έδρα `%json-scalar` ([0070] finding A), με απόκλιση `~,6F` vs `~,4F`.
- **M5 — 3η αντιγραφή auth:** `%cockpit-authorised-p` = 3ο αντίγραφο του creator-token
  ελέγχου (ήδη inline σε `/ask` και `/cmd`).
- **M6 — δεν ενοποιεί, τριπλασιάζει:** ο τίτλος λέει «ΕΝΟΠΟΙΗΜΕΝΗ» αλλά `--serve-review`
  και `--serve` μένουν ζωντανά — αρχιτεκτονικό, ΦΑΣΗ ΤΟΥ ΔΗΜΙΟΥΡΓΟΥ (βλ. κάτω).
- **M7 — drift:** `:ask` έχανε το `with-audience` που εφαρμόζει το `/ask`.

## ΚΛΕΙΣΙΜΟ ΣΤΗΝ ΕΔΡΑ (έκδοση β')
| # | Κλείσιμο | Έδρα |
|---|---|---|
| S1 | `%cockpit-api-guard`: Host-allowlist (loopback ⇒ μόνο localhost/127.0.0.1/::1, ή COCKPIT_ALLOWED_HOSTS) + ΥΠΟΧΡΕΩΤΙΚΟ custom header `X-LAWMAX-Cockpit` (θάνατος simple-CORS CSRF: `<img>`/`<form>`/`<script>` δεν το θέτουν· cross-origin fetch ⇒ preflight που δεν εγκρίνουμε) | cockpit.lisp |
| S2 | `api-dispatch`/`api-catalog` δέχονται `:require-trust` (default nil = γενική υποδομή)· ο cockpit περνά `t` ⇒ advisor cap → 403 (pre-check + `invoke-capability :require-trust`, διπλή άμυνα)· catalog δεν διαφημίζει advisor | capability-api.lisp + cockpit.lisp |
| S3 | Η σελίδα δομεί DOM με `textContent`/`dataset` + ΕΝΑ delegated listener (`data-id`/`data-action`) — καμία string-παρεμβολή, XSS αδύνατο εκ κατασκευής (ίδιο μοτίβο με review-service) | cockpit.lisp |
| S4 | `*review-queue-lock*` + `with-review-queue-lock` (ΜΙΑ σειριοποίηση read-modify-write· ενδο-διεργασιακή — δια-διεργασιακό CAS = δηλωμένη άλλη φάση) | main.lisp |
| M1 | `:decide` (και CLI `review-decide` + `--review-approve/-reject`) περνούν `:approve`/`:reject` — το ΡΗΜΑ που δέχεται η έδρα· ψευδές docstring διορθώθηκε | cockpit.lisp + main.lisp + builtin-commands.lisp |
| M2 | `tests/cockpit-test.lisp` — 28 checks locking ΟΛΑ (routing/CSRF/host/require-trust/decide round-trip σε ΥΠΑΡΚΤΟ item/json/auth-with-token)· gated στο Dockerfile | tests/ + Dockerfile |
| M3 | Αφαιρέθηκε το εσωτερικό `handler-case` από `:ask`/`:publish` ⇒ σφάλμα διαφεύγει ⇒ api-dispatch 500 (ΜΙΑ πειθαρχία σφάλματος για τις 4 δυνατότητες) | cockpit.lisp |
| M4 | `%cockpit-json` ΚΑΤΑΝΑΛΩΝΕΙ `%json-scalar` για κάθε scalar· κρατά μόνο τη σύνθεση plist→object/list→array/t→true | cockpit.lisp |
| M5 | ΜΙΑ έδρα `%creator-request-authorised-p` (cli-util)· `/ask`, `/cmd`, cockpit την καταναλώνουν — τα 3 αντίγραφα πέθαναν | cli-util.lisp + main.lisp + cockpit.lisp |
| M7 | `:ask` τυλίγεται σε `with-audience (:creator)` (η θύρα έχει ήδη πιστοποιηθεί) | cockpit.lisp |

**M6 (ΔΗΛΩΜΕΝΟ ΥΠΟΛΕΙΜΜΑ — φάση δημιουργού):** η πλήρης ενοποίηση (συνταξιοδότηση/προβολή
των `--serve-review` και `--serve` ώστε ΜΙΑ έδρα ανά έννοια «pending/approve/ask/publish»)
είναι αρχιτεκτονική τομή που ΜΟΝΟ ο δημιουργός εγκρίνει (CLAUDE.md: «Μόνο ο δημιουργός
συγχωνεύει/εγκρίνει φάσεις»). ΔΕΝ έσβησα ζωντανές επιφάνειες μονομερώς. Πρόταση: επόμενη
φάση ο `serve-review` dashboard + το `/ask` του `--serve` να γίνουν ΠΡΟΒΟΛΕΣ των ίδιων
capabilities (φάση θανάτου των παλιών εδρών). Εκκρεμεί ρητό «εγκρίνω».

## ΑΠΟΔΕΙΞΗ (τοπικά, hermetic ASDF όπως build.lisp)
- Full runtime compile: cockpit.lisp **0 non-style + 0 style warnings**· κανένα warning σε
  main/cli-util/capability-api/builtin-commands (αυστηρή μεταγλώττιση, χωρίς muffle).
- `tests/cockpit-test.lisp`: **28/28** μέσω του ΓΝΗΣΙΟΥ gate harness (run-standalone-test.lisp).
- Κανένα regression: capability-api **16/16** (+4 require-trust locks), capability-registry
  18/18, review-queue 30/30, review-service 20/20, fek-ingestion 10/10.
- Empirical seat-proof του M1: `:approved`→CASE-FAILURE, `:approve`→APPROVED.

## ΕΠΙΒΕΒΑΙΩΤΙΚΟ PASS (3 ανεξάρτητοι verifiers στον ΔΙΟΡΘΩΜΕΝΟ κώδικα)
Οι διορθώσεις ΚΡΑΤΗΣΑΝ (cleared: M4 γνήσια delegation, M5 μοναδική έδρα auth,
require-trust δομικό διπλής άμυνας, CSRF header, καμία test-ταυτολογία, macro
load-order ασφαλής). Βρέθηκαν 3 ΝΕΑ πραγματικά ελαττώματα — κλείστηκαν:
- **V1 HIGH (S1 residue):** μη-loopback bind (`COCKPIT_HOST=0.0.0.0`) ΧΩΡΙΣ token &
  ΧΩΡΙΣ allowlist κατέρρεε τον φρουρό σε «ύπαρξη header» (που ένας curl θέτει
  ελεύθερα) ⇒ δημόσια πρόσβαση σε `/api/decide`,`/api/publish`. **Κλείσιμο:** ο
  host-guard ΑΡΝΕΙΤΑΙ (fail-closed) δημόσιο bind χωρίς token ή allowlist — καμία
  δημόσια θύρα ανοιχτή by default.
- **V2 LOW:** `COCKPIT_ALLOWED_HOSTS` με κενή καταχώρηση (trailing/double comma) +
  IPv6 `[::1]` parsing. **Κλείσιμο:** `%cockpit-allowed-hosts` αγνοεί κενές·
  `%cockpit-host-only` χειρίζεται `[::1]:port`.
- **V3 MEDIUM (fail-open):** `load-review-queue` κατάπινε read-errors ⇒ αλλοιωμένο
  αρχείο ουράς → «άδεια ουρά» → ο άνθρωπος βλέπει «κανένα εκκρεμές» αντί σφάλματος
  (οι προτάσεις του δαίμονα εξαφανίζονται). **Κλείσιμο:** το `read` σηματοδοτεί σε
  αλλοιωμένο s-expr (κενό αρχείο = νόμιμα άδειο)· /api/pending → 500.

M6-συγγενή ευρήματα (2ος lock `*decide-lock*`, action→verb map & `%json-string`
στο review-service, ζωντανά `--serve-review`/`--serve`) = ΤΙΜΙΑ ΔΗΛΩΜΕΝΑ υπόλοιπα
του M6 (ο verifier το επιβεβαίωσε ρητά: «HONEST scope declaration»). Φάση δημιουργού.

Proof v2: cockpit **35/35** (+7 locks V1/V2/V3), 0 compile warnings, κανένα
regression (review-service 20, review-queue 30, fek-ingestion 10, capability-api 16).

Εκκρεμεί: owner docker proof (`docker build` χτίζει cockpit μέσω core-runtime· `--target
standalone-test` τρέχει το gated cockpit-test) + ρητό «εγκρίνω» + απόφαση M6.
