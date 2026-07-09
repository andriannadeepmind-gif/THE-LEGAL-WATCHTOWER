# [0035] Claude → Κριτή+δημιουργό · 2026-07-09 · CI-unblockers: corpus-fingerprint ΚΛΕΙΣΤΟ + πλήρης χαρτογράφηση standalone-test

Εντολή δημιουργού: (1) materialize A, (2) εντόπισε/διόρθωσε το failing
standalone-test, (3) component identity → local proof δημιουργού, (4) proof.
Commits: `038ae247`. Έτρεξα τοπικά ΚΑΙ τα 77 tests του gated loop — πλήρης
χαρτογράφηση, όχι μόνο το πρώτο σπάσιμο.

## ① corpus-fingerprint — ΚΛΕΙΣΤΟ (οι 4 αποδείξεις)
1. **Σπάει στο main:** test+πηγή byte-identical με origin/main ⇒ pre-existing.
2. **Αιτία:** το test περίμενε PADDED eIds (`art_001`, `art_002Α`) ενώ η
   `%file-id-eid` κανονικοποιεί ΣΩΣΤΑ σε unpadded (`art_1`, `art_2Α`) — και τα
   ΠΡΑΓΜΑΤΙΚΑ goldens/corpus είναι unpadded (`art_1`, `art_10`, `art_1001Α`·
   ΚΑΝΕΝΑ `art_0…` στα δεδομένα). Stale test expectations.
3. **Fix:** ΜΟΝΟ οι 3 προσδοκίες του test → canonical. Η ΠΗΓΗ
   `corpus-fingerprint.lisp` ΑΜΕΤΑΒΛΗΤΗ ⇒ ταυτότητα άρθρων ΑΘΙΚΤΗ· golden 8/8
   αμετάβλητο. **30/30 pass, exit 0.**

## ② Materialization A — ΚΩΔΙΚΟΠΟΙΗΜΕΝΟ
`--run-pipeline` + `ORCHESTRATOR_CORPUS`/`ORCHESTRATOR_OUTPUT_DIR` επιβεβαιωμένα
υπαρκτά. Νέο CI βήμα ΠΡΙΝ το authoritative `--gates`: materialize
`output/poinikos` (+assert). README ενημερωμένο· verify-truth **22/22**.

## ③ ΝΕΑ ΕΥΡΗΜΑΤΑ — τρέχοντας ΟΛΟ το loop (77 tests): 5 ακόμη pre-existing red

**ΟΛΑ identical με main** (pre-existing)· κανένα δεν αγγίχτηκε από FF1–FF3.

**(α) `fek-html-parser` (10/1)** — ΙΔΙΑ ΚΛΑΣΗ stale-test με το corpus-fingerprint:
το test περιμένει flatten `"α β γ"` ενώ η `html->text` ΣΚΟΠΙΜΑ διατηρεί δομή
παραγράφων (docstring: «block tags → newlines· collapse whitespace ΜΕΣΑ στη
γραμμή ΜΟΝΟ») ⇒ σωστό αποτέλεσμα `"α β\nγ"`. Deterministic red και στο docker
(pure function). 1-line test fix — **αναμένει έγκριση** (εκτός στενής εντολής
«μόνο article-id ordering»).

**(β) `fek-ingestion` (0/10), `ingestion-e2e` (0/10), `government-source` (4/3),
`review-service` (14/6)** — ΜΙΑ κοινή ρίζα, εμπειρικά αποδεδειγμένη:
```
URL-FETCH-ALLOWED-P "http://127.0.0.1:<port>/" ⇒ NIL
```
Ο **SSRF guard** του `document-fetch` (σωστός ως ασφάλεια — «reject internal/
loopback/link-local/metadata hosts», identical με main) **απορρίπτει το loopback**.
Τα 4 tests σηκώνουν ΤΟΠΙΚΟ test server (127.0.0.1) και κάνουν fetch μέσω του
guarded path ⇒ 0 items ⇒ καταρράκτης. **Ντετερμινιστικό — θα αποτύχουν ΚΑΙ στο
docker** (όχι env θέμα· loopback sockets δουλεύουν, το απέκλεισα εμπειρικά).
Πιθανόν γράφτηκαν ΠΡΙΝ προστεθεί ο guard.

## Απόφαση που χρειάζομαι (εκτός εγκεκριμένου scope — ΔΕΝ έδρασα)
Για να γίνει το `docker build --target standalone-test .` PASS:

- **(i)** Έγκριση 1-line fix του fek-html-parser stale expectation (ίδια κλάση
  με το εγκεκριμένο corpus-fingerprint).
- **(ii)** Για τον SSRF guard vs loopback-server tests, επιλογές:
  - **Δ1. Scoped test binding:** dynamic `*allow-loopback-fetch*` (default NIL,
    ΚΑΜΙΑ αλλαγή παραγωγικής συμπεριφοράς)· τα 4 tests την δένουν ρητά γύρω από
    τον τοπικό server τους. Ελάχιστο, ρητό, ελεγχόμενο.
  - **Δ2. Αφαίρεση των 4 από το gated loop** με δηλωμένο λόγο (τίμιο «δεν
    τρέχουν υπό SSRF guard») — χάνουν gating.
  - **Δ3. Refactor των tests** να μην περνούν από HTTP (inject HTML) — μεγαλύτερο.

Η σύστασή μου: **(i) + Δ1** — ο guard μένει ΑΘΙΚΤΟΣ στην παραγωγή, τα tests
δηλώνουν ρητά το loopback τους, το gated loop γίνεται πραγματικά πράσινο.

## Κατάσταση acceptance ([0035] §4)
```
standalone-test: corpus-fingerprint FIXED· εκκρεμούν fek-html-parser + 4 SSRF/loopback (απόφαση)
materialization A: στο CI + README (verify-truth 22/22)
component identity: αναμένει local proof δημιουργού στο 038ae247
HEAD 038ae247 · git clean · FF4 unopened · κανένα merge
```

— Claude (Χειρουργός Πυρήνα) · κλάδος `claude/ministry-justice-url-candidates-twghsj`
