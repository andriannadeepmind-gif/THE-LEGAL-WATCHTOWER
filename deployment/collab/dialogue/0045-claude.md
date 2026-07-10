# [0045] Claude (Χειρουργός Πυρήνα) — NO-WORKAROUND AUDIT (FF3/P0/P1) — audit only, κανένας κώδικας

**Ημερομηνία:** 2026-07-10 · Εντολή δημιουργού πριν το P1R.
**Κλίμακα:** A = διαγνωστικό, μη committed · B = ελεγχόμενη συμφιλίωση artifacts,
committed αλλά source-backed · C = αρχιτεκτονικό χρέος · D = απαράδεκτο για
Verifiable Legal Authority.

## 1. Πλήρης απογραφή

| # | Τι | Κλάση | Σοβαρότητα | Μπλοκάρει P1 merge; | Έδρα πηγής που το καθιστά περιττό |
|---|---|---|---|---|---|
| 1 | Scratchpad harnesses (build-cli/one-test/verify-ff3/p0-regen/p1-pipeline/audit scripts), simulations baked≠live, TSA probes, τοπικό rdflib | **A** | — | ΟΧΙ | — (εργαλεία απόδειξης, εκτός repo) |
| 2 | **P0**: αναγέννηση 30 corpus-level artifacts με απευθείας κλήση του παραγωγικού `corpus-updater` (ίδιοι 5 serializers, ίδιος write-authority writer) | **B** | χαμηλή | ΟΧΙ | οπλισμένος ingestion daemon (`run-update-daemon`, ingestion-daemon.lisp) ή CI publish βήμα — σήμερα ο daemon είναι ΑΟΠΛΟΣ (συνειδητή αναβολή δημιουργού) |
| 3 | **P1**: 4.550 .jsonld — production pipeline σε απομονωμένο staging + αντιγραφή production bytes στα tracked ονόματα | **B** | χαμηλή | ΟΧΙ | ίδιο με #2: παραγωγική δημοσίευση artifacts, όχι χειροκίνητη συμφιλίωση |
| 4 | CI Materialization A (`--run-pipeline` πριν το authoritative `--gates`) — committed στο workflow | **B** | χαμηλή | ΟΧΙ | ο advisor-gate να μη χρειάζεται materialized κατάσταση για τη σκιώδη δίκη (μελλοντική φάση) |
| 5 | Test witness: offline αντικατάσταση schema.org context με τοπικό `@vocab` (committed, test-scoped, τεκμηριωμένο) | **B** | ελάχιστη | ΟΧΙ | vendored τοπικό schema.org context αρχείο |
| 6 | **P1**: 144 lettered .jsonld — ΠΕΡΙΕΧΟΜΕΝΟ production, αλλά ΤΟΠΟΘΕΤΗΣΗ με χαρτογράφηση @id↔όνομα επειδή το deploy εκπέμπει `article-5001Α` αντί `article-005Α` | **C** | ΜΕΣΗ | ΟΧΙ το merge του P1 καθαυτό — ΝΑΙ το κλείσιμο του χρέους στο P1b | συνθετικός αριθμός `base*1000+index` στο `json-adapter.lisp:39-52` × `article-file-id` (article.lisp:190) που τον περνά στο `pad-article-id` αντί για τη βάση του label |
| 7 | Tracked generated/runtime state: `output/` gitignored αλλά ~28.5k legacy-tracked· `output/.healthy` tracked αλλά διαγράφεται/ξαναγράφεται από κάθε run· `deployment/self/history.sexp` θέλει διαρκές `git checkout --` πριν από commits | **C** | ΜΕΣΗ | ΟΧΙ | πολιτική generated-state του repo: runtime αρχεία εκτός ευρετηρίου (ignore+untrack) ή ρητά δηλωμένα ως published artifacts |
| 8 | Owner-side PowerShell διαδικασία release (staging + container copy + `test ! -e`) — ΔΕΝ είναι committed κώδικας· είναι ελεγχόμενη διαδικασία απόδειξης | **C** | ΥΨΗΛΗ ως αρχιτεκτονική | **ΝΑΙ** — per κανόνα δημιουργού: manual copy-back ≠ τελική αρχιτεκτονική release | ΝΕΑ release-only παραγωγική είσοδος (π.χ. `--cut-release`) που δημοσιεύει απευθείας στο κανονικό output με φρουρό αμεταβλητότητας (P1R) |
| 9 | Το προσχέδιο εντολής στο [0044] §4(α) με `ORCHESTRATOR_OUTPUT_DIR=/src/output` ήταν ΕΠΙΣΦΑΛΕΣ (βλ. #12) — αντικαταστάθηκε από τη staging διαδικασία πριν εκτελεστεί | **A** (δεν εκτελέστηκε, δεν committed) | — | ΟΧΙ | καταγράφεται για τιμιότητα· το #12 είναι η ρίζα |
| 10 | **`atomic-publish-release`** (deploy-epistemic.lisp:917-926): για ΙΔΙΟ stamp ΣΒΗΝΕΙ το υπάρχον release και το αντικαθιστά («replacing existing release») | **D** | ΚΡΙΣΙΜΗ | **ΝΑΙ** (απόφαση δημιουργού: όχι merge πριν διορθωθεί το immutable-overwrite) | το ίδιο το seat: άρνηση δημοσίευσης σε υπάρχον stamp — νέο stamp ή τίποτα |
| 11 | **Timestamp authority**: `(now :source :deterministic)` χωρίς SOURCE_DATE_EPOCH πέφτει ΣΙΩΠΗΛΑ σε ρολόι συστήματος (deterministic-time.lisp:154-157) — output-bound stamp χωρίς δηλωμένη εξουσία | **D** | ΚΡΙΣΙΜΗ | **ΝΑΙ** (απόφαση δημιουργού: όχι merge πριν τη release timestamp authority) | fail-fast: για output-bound χρήση, deterministic mode ΥΠΟΧΡΕΩΤΙΚΟ αλλιώς σφάλμα (deploy-epistemic-stage ή time seat) |
| 12 | **`clean-corpus-output-dir`** (main.lisp:216-239): κάθε `--run-pipeline` σβήνει ΟΛΟ το `output/<short>/` ΜΑΖΙ με το `releases/` (εκτός αν ORCHESTRATOR_KEEP_OUTPUT) — παραγωγική διαδρομή καταστρέφει «immutable» releases στο working tree | **D** | ΚΡΙΣΙΜΗ | **ΝΑΙ** (ίδιο κεφάλαιο: immutable release protection) | ο καθαρισμός να ΕΞΑΙΡΕΙ το `releases/` — pipeline output ≠ proof-bearing ιστορικό |

## 2. Απαντήσεις στα 4-8

- **(4) P0 Identity Lock:** ΔΕΝ εξαρτάται από workaround. Ο ζωντανός κώδικας
  ταυτότητας ήταν ήδη ορθός· το lock είναι tests + 1-line latent fix. Το
  artifact commit του P0 είναι κλάση B (production bytes)· το test περνά και
  σε δέντρο χωρίς artifacts.
- **(5) P1 semantic-validity:** οι 4 διορθώσεις εδρών και το test ΔΕΝ
  εξαρτώνται από workaround. Από τα artifacts: 4.550 = B· τα 144 lettered = C
  (#6) — το ΜΟΝΟ committed σύνολο του οποίου η τοποθέτηση δεν αναπαράγεται
  σήμερα αυτούσια από το pipeline (λόγω του bug ονοματοδοσίας, όχι του σχήματος).
- **(6) P1 release layer:** ΝΑΙ — σήμερα εξαρτάται από χειροκίνητη διαδικασία
  (#8) πάνω σε τρεις D-ρωγμές της παραγωγικής διαδρομής (#10, #11, #12).
  Άρα: **ΟΧΙ merge-ready**, σύμφωνο με την ετυμηγορία του δημιουργού.
- **(7) Πού μπορεί ο παραγωγικός κώδικας να ξαναγράψει «immutable» releases:**
  ΔΥΟ σημεία — atomic-publish-release ίδιο-stamp replace (#10) και
  clean-corpus-output-dir ολικό wipe του corpus subdir (#12). Κανένα τρίτο δεν
  βρέθηκε (ο μόνος γραφέας του `releases/` είναι το deploy-epistemic· το
  emit-graph/write-authority δεν αγγίζει releases).
- **(8) Πού αποκλίνουν ονόματα αρχείων από κανονικές νομικές ταυτότητες:**
  ΕΝΑ ενεργό σημείο — per-article filenames για lettered: `json-adapter`
  συνθετικός αριθμός (5Α→5001) → `article-file-id`→`pad-article-id(5001,…)`
  → `article-5001Α` αντί του κανονικού `article-005Α` (article.lisp:172-194).
  Τα υπόλοιπα στρώματα (eIds, @id/ELI, JSONL/AKN/fingerprint, corpus-level
  ονόματα) αποδείχθηκαν συνεπή στο P0 (25/25) και στο P1 audit (0 @id moved).

## 3. Προτεινόμενες πύλες κατά μελλοντικών workarounds (#9 — πρόταση, όχι κώδικας)

1. **release-immutability**: (α) το publish ΑΡΝΕΙΤΑΙ υπάρχον stamp· (β) πύλη
   που σαρώνει κάθε tracked release: recomputed Merkle ≡ merkle-tree.json και
   κανένα ιστορικό stamp δεν άλλαξε ως προς το git (regression lock).
2. **timestamp-authority**: output-bound `now :deterministic` χωρίς ενεργό
   deterministic mode ⇒ ΣΦΑΛΜΑ, όχι σιωπηλό ρολόι.
3. **filename≡identity**: για κάθε εκπεμπόμενο per-article αρχείο,
   file-id ≡ κανονικό label (επέκταση της λογικής του corpus-identity ⑦ στο
   deploy στρώμα).
4. **artifact-drift**: committed serializations ≡ φρέσκια έξοδος των εδρών
   (επέκταση του golden ratchet) — ώστε καμία χειροκίνητη συμφιλίωση να μη
   χρειάζεται ούτε να περνά απαρατήρητη.
5. **workaround registry**: κάθε B-συμφιλίωση επιτρέπεται ΜΟΝΟ με αναφορά σε
   απόφαση διαλόγου + φάση που τη ΣΥΝΤΑΞΙΟΔΟΤΕΙ (αλλιώς κόκκινο).

## 4. Προτεινόμενο σχίσμα P1R / P1b

- **P1R — Release Authority Hardening (πριν από κάθε P1 merge):**
  ① #10 no-overwrite publish ② #11 fail-fast timestamp authority
  ③ #12 clean εξαιρεί `releases/` ④ ΝΕΑ release-only είσοδος `--cut-release`
  (συνταξιοδοτεί το owner-side copy-back #8) ⑤ release-immutability gate/test.
  Μετά: ο δημιουργός κόβει τα 6 νέα releases ΜΕΣΩ της παραγωγικής εισόδου →
  P1 πλήρες → ετυμηγορία merge.
- **P1b — Per-Article Surface Completion:** ① fix ονοματοδοσίας (#6: file-id
  από το label, όχι από τον συνθετικό αριθμό) ② αναγέννηση per-article
  επιφανειών ΜΕΣΩ pipeline (συνταξιοδοτεί τη χαρτογράφηση των 144)
  ③ filename≡identity gate ④ πληρότητα ελλειπουσών επιφανειών.

## 5. Συμπεράσματα (δεσμευτικά, όπως όρισε ο δημιουργός)

- ΟΧΙ merge μέχρι να κλείσουν #10/#11/#12 (P1R).
- ΚΑΝΕΝΑ manual copy-back δεν γίνεται δεκτό ως τελική αρχιτεκτονική release.
- Κάθε συμφιλίωση artifacts (B/C) αντικαθίσταται από παραγωγική ορθότητα στη
  σχετική φάση: #2/#3 → οπλισμένη δημοσίευση, #6 → P1b, #8 → P1R.

*Χειρουργός Πυρήνα — το χρέος καταγράφεται, δεν κρύβεται· και πεθαίνει σε φάση, όχι σε σιωπή.*
