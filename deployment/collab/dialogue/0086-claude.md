# [0086] Θάνατος σιωπηλής αντικατάστασης έδρας + Persistence Receipt + ΜΙΑ ρίζα + WFS proof-honesty

**Εντολή δημιουργού:** «προχώρα με την ανώτατη υλοποίηση» (μετά την επαλήθευση της
εξωτερικής μελέτης — [0085-verify]: 13/13 ευρήματα επιβεβαιωμένα στον κώδικα με file:line).
Νόμοι σε ισχύ: ποτέ μπαλώματα/workarounds/wrappers· default = το ανώτατο· ο χρόνος
δεν είναι μεταβλητή απόφασης.

## Α. Μητρώο εντολών: η σύγκρουση έδρας έγινε ΔΟΜΙΚΑ αδύνατη
- `register-command` (cli-util.lisp): μητρώο ΙΔΙΟΚΤΗΣΙΑΣ `*command-owners*` —
  duplicate από ΑΛΛΟ αρχείο ⇒ `command-seat-collision` ERROR στο build (όχι σιωπηλή
  νίκη του τελευταίου στο load order)· ίδιο αρχείο ⇒ idempotent reload. Η ταυτότητα
  αρχείου από ΝΕΑ εξαγωγή της έδρας paths: `current-load-file` (identity-only,
  ποτέ ρίζα — το FF1 ⑭ μένει αληθές: load-truename ΜΟΝΟ στο paths.lisp).
- **Ανάσταση του νομικού `--what-if`** (counterfactual υπόθεσης, subsumption-commands):
  ήταν ΝΕΚΡΟ στο CLI — το evolution-gate το σκίαζε σιωπηλά (φόρτωση αργότερα).
  Η αυτοεξέλιξη μετονομάστηκε `--self-what-if` (και το defun `run-self-what-if` —
  πέθανε και η σύγκρουση ΣΥΜΒΟΛΟΥ `orchestrator.cli::run-what-if`).
- `--impact` = graph (η σημερινή ενεργή συμπεριφορά)· το σκιασμένο του
  self-reflection αναστήθηκε ως `--capability-impact`.
- Σύνταγμα command-map ενημερωμένο (+2 νέες εντολές) **+ κλείσιμο ΠΡΟΫΠΑΡΧΟΝΤΟΣ
  κόκκινου ②**: τα `--cockpit`/`--legal-eval` ήταν αχαρτογράφητα (απόδειξη: gate
  κόκκινο ΚΑΙ σε stash/καθαρό HEAD) — χαρτογραφήθηκαν.

## Β. ΜΙΑ έδρα export-provenance-json
Η article-εκδοχή (exporters.lisp, 18 γραμμές, **0 καλούντες**) σκίαζε την chain-εκδοχή
και έσπαγε τον μόνο πραγματικό καλούντα (provenance-model.lisp:274 + test). ΔΙΑΓΡΑΦΗΚΕ
το αρχείο + η εγγραφή .asd — καμία μετονομασία, δεν υπήρχε καταναλωτής να εξυπηρετηθεί.

## Γ. Persistence Receipt — id ⟺ durable (η σύλληψη του εξωτερικού κριτή, στην έδρα)
- `journal:append-line` επιστρέφει `(values plist receipt)`: `:durability` ∈
  {`:durable`, `:ephemeral-replica`, `:degraded-memory-only`, `:failed-verification`}
  + `:content-hash` + `:readback-verified` + `:path` + `:at`. Με `:verify` ⇒ ΦΡΕΣΚΙΑ
  επανανάγνωση από δίσκο (παρακάμπτει σκόπιμα την cache). Εξαγωγές: `durable-p`,
  `receipt-durability`, `receipt-verified-p`. Hot-paths (επεισόδια) πληρώνουν μόνο
  το φθηνό receipt· θεσμικοί συγγραφείς καλούν `:verify t`.
- `proposals:%append-event`: ο `ignore-errors` ΠΕΘΑΝΕ — χωρίς durable receipt ⇒
  `proposal-not-durable` ERROR. **Κανένα proposal id χωρίς αποθηκευμένη πρόταση.**
- `adoption:record-adoption!`: το RAM-only `*adoption-records*` ΠΕΘΑΝΕ — ΝΕΟ διαρκές
  ledger `deployment/self/adoptions.sexp` (canonical store, δηλωμένο στο σύνταγμα)
  με `:verify t` + `adoption-not-durable` ERROR. `adoption-records`/validate διαβάζουν
  από το ημερολόγιο. Το «κυβερνά αυστηρότερα απ' όσο καταγράφει» — κλειστό.
- Η πύλη αυτοεξέλιξης δένει ΔΟΚΙΜΑΣΤΙΚΟ ledger (`%fresh-gate-ledger`) — οι πύλες
  δεν γράφουν ποτέ το πραγματικό θεσμικό ledger.
- ΔΗΛΩΜΕΝΟ υπόλοιπο (όχι σιωπηλό): execution-trace παραμένει session-only
  (declared debt από την έδρα του)· receipts εκεί = επόμενη φάση.

## Δ. ΜΙΑ ρίζα — θάνατος getcwd (28 σημεία, 0 απομένουν)
Όλα τα persistent paths μέσω `orchestrator.paths:institution-root` (verified,
lazy — ΠΟΤΕ παγωμένα από load/saved-image/ξένο cwd): episodes, history, proposals,
adoptions, policies, knowledge-dir, graph-snapshot, decisions data, cursors,
review-queue, gate artifacts, engine outputs. Τα 4 store-vars έγιναν
override-var (για τα gates) + ΤΕΜΠΕΛΙΚΟΣ accessor (`episodes-path`, `history-path`,
`knowledge-dir`, `%policies-path`, `%proposals-path`, `%adoptions-path`).
Ξεμπλοκάρει και NixOS (καμία build-time παγωμένη διαδρομή).

## Ε. Πύλη ⑨: αποδεικνύει πλέον ό,τι δηλώνει
Σάρωση: self/*.sexp + state/*.jsonl + **state/*.json + state/*.txt + root
component-manifest.sexp + output/review-queue.sexp**. Σύνταγμα: +5 δηλώσεις
(adoptions ledger, component-manifest, daemon-status, review-queue, cursors ως
`:path-glob`). Η πύλη υποστηρίζει glob-δηλώσεις (pathname-match-p).

## ΣΤ. WFS proof-honesty — ο «πιθανός» του κριτή, ΔΟΜΙΚΑ επιβεβαιωμένος & νεκρός
Επιβεβαίωση στον κώδικα: undefined κόμβοι έπαιρναν label `:out` (γρ.345) και το
`%valid-justification` κοιτούσε ΜΟΝΟ labels ⇒ proof object ισχυρότερο από τη WFS
σημασιολογία. Διόρθωση στην έδρα: το τελικό `u` του alternating fixpoint ΕΙΝΑΙ το
U∞ — cached στο jtms (`jtms-undefined-set`, ΜΙΑ θέση υπολογισμού· το `%undefined-set`
το διαβάζει πλέον αντί να ξανατρέχει A(K∞))· το `%valid-justification` απαιτεί
defeaters ΓΝΗΣΙΑ ψευδείς (`:out` ∧ ∉U∞). Πληρότητα εγγυημένη από τη θεωρία:
K∞ = A(U∞) ⇒ κάθε :in κόμβος ΕΧΕΙ αυστηρά-έγκυρη justification.
**Μάρτυρας (μόνιμος στο test):** p με j1(defeater:undefined) + j2(defeater:false)
⇒ support = j2· q μόνο-με-undefined-defeater ⇒ :undefined, ποτέ :in.

## Απόδειξη (πλήρης, μετρημένη)
- ΝΕΟ gated test `seat-integrity` **16/16** (στο Dockerfile standalone-test):
  κλειδώνει Α/Β/Γ/Δ/ΣΤ — συμπεριλαμβανομένου source-scan «0 getcwd» και του
  WFS μάρτυρα.
- Standalone: capability-registry 18, capability-api 16, cockpit 37, review-queue 30,
  proof-carrying 45, reasoning-authority 12, legal-qa 12, legal-eval 8, casegrammar 30,
  greek-morphology 18, citation-authority 20 — **όλα 0 failed**.
- Runtime πύλες: self-evolution **23/23** (ήταν 21 — +2 από τα νέα αρνητικά),
  policy 12/12, memory 10/10, contract πράσινη, **architecture-constitution ΠΡΑΣΙΝΗ**
  (② κλειστό, ⑨ πλήρες, ⑭ αληθές μέσω της έδρας paths).
- Ολομέλεια `--gates`: όλες πράσινες πλην χρυσών αποτυπωμάτων — **αποδεδειγμένα
  ΠΡΟΫΠΑΡΧΟΝ περιβαλλοντικό** (πανομοιότυπο κόκκινο σε stash/καθαρό HEAD, ίδιες
  ρίζες)· αυθεντική απόδειξη = owner docker, ως πάντα.
- Αντιπαλική επιθεώρηση [0047]: 2 ανεξάρτητοι κριτές (σπάσιμο σχεδίασης + κυνήγι
  μετριότητας) — ευρήματα & κλείσιμο: §Κριτές παρακάτω.

## Κριτές [0047]
Δύο ανεξάρτητοι αντιπαλικοί κριτές (α: σπάσιμο σχεδίασης — receipt races,
U∞ caching, current-load-file/fasl, root fallback· β: κυνήγι μετριότητας —
μπαλώματα/wrappers/διπλές έδρες/σιωπηλά fallbacks/τεστ-ταυτολογίες) εξαπολύθηκαν
σε φρέσκο πλαίσιο ΠΑΝΩ στο diff. Το commit αυτό εκδίδεται με τα ΜΕΤΡΗΜΕΝΑ proofs
πράσινα (stop-hook πειθαρχία branch)· τα ευρήματα των κριτών κλείνουν σε [0086+]
ΠΡΙΝ από οποιοδήποτε merge — ο δημιουργός συγχωνεύει μόνο με ρητή εντολή.

## Εκκρεμή (ρητά)
- **Ζ (απόφαση δημιουργού):** exit-code σύνταγμα — 0 για θεσμικά ορθή άρνηση
  (constitutional-dispatch.lisp:76 επιστρέφει 1 σε block). Δεν αγγίχτηκε χωρίς εντολή.
- Γέφυρα των δύο capability registries (Δ3 [0083]) — χωριστή φάση.
- execution-trace durability — δηλωμένο χρέος, φάση receipt-2.
