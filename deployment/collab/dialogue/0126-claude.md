# [0126] — ΧΑΡΤΗΣ REFACTORING ΤΟΥ COMMON LISP ΣΩΜΑΤΟΣ (PANOPLIA βήμα 0.0 — σκέλος ΚΩΔΙΚΑ)
**Claude · 2026-09-26 · branch `claude/exciting-mccarthy-tj8969` · ΜΕΛΕΤΗ-ΜΟΝΟ (καμία γραμμή runtime κώδικα δεν άλλαξε)**

Εντολή δημιουργού (εν συνεδρία): «Μελέτησε ΧΩΡΙΣ agents όλα τα αρχεία
[PANOPLIA-COMPLETE zip] και βρες τι refactoring πρέπει να γίνει στο
THE-LEGAL-WATCHTOWER· ασχολήσου με τον Common Lisp κώδικα, όχι με τα outputs
ακόμα.»

Μέθοδος: πλήρης ανάγνωση των κανονικών εγγράφων του PANOPLIA πακέτου
(MASTER-INDEX, PANOPLIA-MASTER-EXECUTION-PLAN v1.4, DECISION-CL-FROM-START,
INDEPENDENT-FINDINGS-REGISTER 22 ευρημάτων, MIGRATION-FATE-MAP,
WATCHTOWER-ULTIMATE-ARCHITECTURE/ΣΚΟΠΙΑ, SYSTEM-DECOMPOSITION,
COMMON-LISP-COGNITIVE-SUBSTRATE) + επαλήθευση ΚΑΘΕ ισχυρισμού με μέτρηση
πάνω στο τρέχον HEAD `e621dbe1` — ΣΕ ΕΝΑ πλαίσιο, χωρίς πράκτορες, κατά τη
ρητή εντολή της συνεδρίας (η εκκρεμότητα «διαιτησία agents» του MASTER-INDEX
§5.6 παραμένει απόφαση δημιουργού). Το σκέλος «outputs/publication audit»
(Π.1 επί του output/ 304MB) ΔΕΝ καλύπτεται εδώ — επόμενη κατάθεση όταν
ζητηθεί. Τα αρχεία tests/ εξετάστηκαν μόνο όπου δένουν με έδρες κώδικα.

Το παρόν είναι το σκέλος ΚΩΔΙΚΑ του βήματος **0.0 Integration audit** του
PANOPLIA-MASTER-EXECUTION-PLAN («χάρτης refactoring/rebase από τη βάση όπου
χρειάζεται») και προϋπόθεση της ΠΥΛΗΣ ΕΚΔΟΣΗΣ της Φάσης Π. Κατά το πλάνο
v1.4, το ίδιο το refactoring εκτελείται ΥΠΟ τον M-0H2 κυβερνήτη μετά από
ρητή έγκριση — τίποτα από τα κατωτέρω δεν ανοίγει μόνο του.

---

## §1 · ΤΙ ΕΚΛΕΙΣΕ ΗΔΗ ΑΠΟ ΤΟ [0116] (επαληθευμένο στον σημερινό κώδικα — τίμια αφετηρία)

Ο ολικός έλεγχος [0116/0116+] (2026-07-30) παραμένει η βάση. Από τις τότε
«παραβιάσεις 0-λάθους», σήμερα είναι ΚΛΕΙΣΤΑ στην έδρα τους:

1. **fsync-τιμιότητα + cross-process single-writer** — journal.lisp:
   RATCHET-1 (%fsync fail-closed, γρ. 203-233) + RATCHET-2 (flock(2) LOCK_EX
   σε <journal>.lock, γρ. 96-160). ([0117])
2. **ΜΙΑ αλυσίδα/σειριοποίηση** — memory.lisp:95 και self-history.lisp:48
   εκχωρούν πλέον στο `orchestrator.journal:chained-append`· το ~S-hash
   επιβιώνει ΜΟΝΟ ως δηλωμένο legacy decoder (memory.lisp:160-165). ([0117])
3. **verify-episode-chain με επανυπολογισμό** (memory.lisp:167-195) +
   self-history verify-chain (self-history.lisp:80). ([0117])
4. **MERKLE-SINGLE-TRUTH** — ανεξάρτητο RFC oracle, profile identity,
   publisher guards, πραγματικοί mutants. ([0118]-[0121], 57c0cd86)
5. **CI script** — το `scripts/verify-runtime-closure.sh` ΥΠΑΡΧΕΙ πλέον, με
   αντιπαλικό fixture στο workflow. ([0119]· η ΕΚΤΕΛΕΣΗ του CI παραμένει
   χωρίς πράσινο run — δηλωμένο BLOCKED των [0122]-[0125])
6. **run-citation-verification** — τίμιο exit code (tests/run-citation-
   verification.lisp:49-55).
7. **L7 VCCT-RSM Φ1-Φ4** — capability closure, αφοπλισμός legacy authority
   writers, ρόλοι/χώροι εργασίας, quarantine capture. (1c46ff7f…57a47fef)

**ΔΕΝ έκλεισαν** και αποτελούν τον κάτωθι χάρτη: όλη η Φ-ΥΓΙΕΙΝΗ του [0116]
§7.2, το Στρώμα 6 («δομική υγιεινή») του [0116] §6, και τα σημεία τίμιας
άγνοιας του pipeline. Κάθε γραμμή κατωτέρω ΕΠΑΛΗΘΕΥΤΗΚΕ σήμερα με μέτρηση.

## §2 · Ο ΧΑΡΤΗΣ REFACTORING (μετρημένος στο HEAD e621dbe1)

Σώμα: 484 .lisp εκτός output/third-party/deps (source 133 · systems 171 ·
tests 144)· ~129.000 γραμμές σε source+systems+tests+deployment+authority-v2.

### Ρ1 — Δομική αποσύνθεση: ο :serial μονόλιθος ζει και μεγάλωσε [ΚΡΙΣΙΜΟ]

- `orchestrator-infrastructure.asd`: **132 αρχεία σε ΕΝΑ module με
  `:serial t`** (γρ. 44) — μέσα του συνυπάρχουν NLP, νομική συλλογιστική,
  κρυπτογραφία, HTTP, KG. `orchestrator-cli.asd`: 48 αρχεία `:serial t`
  (γρ. 27)· `orchestrator-omega.asd`: 24 αρχεία serial.
- **Δυναμικές συνδέσεις αόρατες στο ASDF: 280 find-symbol + 86 intern = 366**
  σε source+systems (στο [0116] μετρήθηκαν 226 — η τάση ΧΕΙΡΟΤΕΡΕΨΕ).
  Υπόδειγμα: corpus-service.lisp:84-98 καλεί ΚΑΘΕ output format μέσω
  find-symbol.
- **Refactoring**: διάλυση σε πραγματικά ASDF systems με δηλωμένες
  εξαρτήσεις, ΟΧΙ κατά τεχνικό στρώμα αλλά κατά τις γραμμές επιστημικής
  εξουσίας της ΣΚΟΠΙΑ (SYSTEM-DECOMPOSITION §1/§5): πυρήνας-ΚΡΗΠΙΣ
  (journal/canonical/merkle/safe-read/hash) · Αρχείο (version-graph/
  identity/receipts/checkpoints) · Όργανα Ε2 (legal-ast/layout/OCR/μία-έδρα
  NLP) · Ελεγκτές (proof-bundle/evidence-replay/consolidation-proof) ·
  Συλλογιστική→μελλοντικό ΕΡΜΗΝΕΙΟΝ (WFS/deontic/dialectic/event-calculus) ·
  Interface προβολές (http/mcp/site/AKN/TTL/SPARQL) · Governance
  (self-model/contracts/policies/capability). Τα 366 find-symbol πεθαίνουν
  σε ρητές εξαρτήσεις ή ΜΙΑ έδρα registry-dispatch. Αυτό είναι ΚΑΙ
  προϋπόθεση του M-0H2: το orchestrator-meta.asd σήμερα εξαρτάται από
  ΟΛΟΚΛΗΡΟ το orchestrator-infrastructure «for orchestrator.time» — ο
  κυβερνήτης δεν πρέπει να κληρονομήσει μονόλιθο 132 αρχείων για ένα package.

### Ρ2 — Νησιά και νεκρός/ψευδο-κώδικας ΜΕΣΑ στο build [ΥΨΗΛΟ — χαμηλό ρίσκο]

Μεταγλωττίζονται σε ΚΑΘΕ build μέσω orchestrator-infrastructure.asd, με 0
αναφορές από source/systems/tests (μέτρηση σήμερα, αναφορές πακέτου):

| Αρχείο | Γρ. | Εύρημα | Τύχη κατά MIGRATION-FATE-MAP |
|---|---|---|---|
| ai-citation-strategy.lisp | 917 | ψευδο-υλοποίηση: MongoDB «integration» χωρίς driver (γρ. 106-109, 436-438, 764+), 0 callers | **DPR — θάνατος** |
| signed-embedding-manifest.lisp | 710 | νησί· μόνη αμοιβαία αναφορά με embeddings-authority (481 γρ.) | **DPR — θάνατος ζεύγους** |
| validate-layout-graph.lisp | 752 | νησί (0 refs) | καλωδίωση ως ΣΚΟΠΙΑ ελεγκτής Ή θάνατος — όχι λίμπο |
| validate-logical-blocks.lisp | 377 | νησί (0 refs) | ομοίως |
| archive-authority.lisp | 163 | νησί (0 refs) | θάνατος ή ένταξη στην αυθεντία κτήσης |
| legal-penalty.lisp | 190 | νησί | **MOVE(ΑΠΕΙΡΟΝ/ΠΡΑΞΙΣ) ή DPR** |
| legal-hypo.lisp | 84 | νησί | ομοίως |
| protocols.lisp | 263 | **41 defgeneric / 0 defmethod / 0 αναφορές** — και ΔΙΠΛΗ έδρα με systems/orchestrator-spec/protocols.lisp (17 defgeneric)· και τα ΔΥΟ στο build (infrastructure.asd:188, spec.asd:23) | συγχώνευση στη ΜΙΑ έδρα (orchestrator-spec) |
| fluid-induction.lisp | 264 | 1 καταναλωτής (cli/fluid-gate) | **MOVE(ΑΠΕΙΡΟΝ)** — εκτός νομικού πεδίου |

Κάθε θάνατος: πρώτα `git log -S` + απόδειξη 0 callers + LEGACY σφράγιση όπου
το fate map ορίζει διατήρηση (ποτέ διαγραφή sealed artifacts).

### Ρ3 — Διπλές/πολλαπλές έδρες ανά έννοια [ΥΨΗΛΟ]

Μετρήθηκαν σήμερα (παραβίαση «μία έδρα ανά έννοια» ΣΕ ΙΣΧΥ):

1. **mod-inverse ×2 — κρυπτο-πρωτόγονο**: jws-authority.lisp:711 +
   blockchain-authority.lisp:259. Επιπλέον το jws χειρο-υλοποιεί EMSA-PKCS1
   v1.5 (γρ. 345-368) ενώ το Ironclad (ήδη vendored, deps.lock
   ironclad-v0.61· 34 αρχεία το χρησιμοποιούν) παρέχει RSA sign/verify.
   Κατά τον νόμο «Ironclad αντί crypto-wrapper» και το PANOPLIA plan
   (Ironclad ed25519/RSA): μετάπτωση στο Ironclad, μία έδρα.
2. **normalize-greek ×3 + 3 παραλλαγές**: greek-lemmatizer.lisp:41 ·
   text-canonicalizer.lisp:409 · legal-id-registry.lisp:74 (+ wrappers/
   variants: cli/content-validation.lisp:81, raw-text-adapter.lisp:1481,
   pdf-adapter.lisp:554). Μία έδρα ελληνικής κανονικοποίησης.
3. **tokenize ≥7 έδρες**: greek-tokenizer-advanced (610/695/714/1035) ·
   greek-lemmatizer:521 · embeddings-authority:282 · citation-authority:
   241/257 · ai-ingest-manifest:358 · greek-nlp-core:431/618 ·
   gr-syntagma/parsing.lisp:954. Fate map: «greek-tokenizer(×5)
   REFACTOR→SUPERSEDE — μία έδρα· FST διάδοχος».
4. **JSON escaping ×3**: json-emit.lisp:24/39 · ai-corpus-dump.lisp:40 ·
   orchestrator-spec/escaping.lisp:74.
5. **Turtle escaping ×2**: orchestrator-spec/escaping.lisp:38 ·
   omega-modules/turtle-dsl.lisp:173.
6. **Ανάγνωση sexp ×2**: ο journal reader χρησιμοποιεί γυμνό `read` με
   τοπικό `*read-eval* nil` (journal.lisp:273-286, 357-360) ενώ υπάρχει η
   έδρα `orchestrator.safe-read` (safe-read.lisp — «στο ταβάνι της κλάσης
   του» κατά [0116]). Μετάπτωση του reader στη μία έδρα (τα #S/#A μένουν
   σήμερα ενεργά στον reader — η άμυνα είναι μόνο το chain-hash).

### Ρ4 — Σιωπηλά fallbacks / καταπιέσεις σφαλμάτων [ΥΨΗΛΟ]

- **226 ignore-errors σε 65 αρχεία· εξ αυτών 52 στη μορφή σιωπηλού default
  `(or (ignore-errors …) τιμή)`** — αριθμός ΑΜΕΤΑΒΛΗΤΟΣ από το [0116].
  Χειρότερο παράδειγμα ζωντανό: semantic-authority.lisp εκπέμπει authority
  RDF με hardcoded fallback URLs σε 6 σημεία (γρ. 40, 85, 294, 401, 435,
  704) αν πέσει η έδρα orchestrator.uris — αντί σφάλματος.
- **metrics-stub no-op ΜΕΣΑ στο build**: orchestrator-omega.asd:54 →
  omega-modules/metrics-stub.lisp (record-error-event ⇒ nil, με σχόλιο
  «REAL IMPLEMENTATION: if you want real metrics…») ενώ το
  frbr-conditions.lisp:170 του παραδίδει error events — χάνονται σιωπηλά.
- **Refactoring**: τα 52 σιωπηλά defaults ταξινομούνται και γίνονται
  τυπισμένες conditions με δηλωμένα restarts — η αντιστοίχιση condition ↔
  failure-mode μητρώο είναι ακριβώς το πρότυπο του Ω8
  COMMON-LISP-COGNITIVE-SUBSTRATE §2 («ποτέ σιωπηλό swallow»). Το
  metrics-stub πεθαίνει: πραγματική έδρα ή fail-loud.

### Ρ5 — Ψευδο-λειτουργίες / παραβιάσεις τίμιας άγνοιας [ΥΨΗΛΟ]

1. **SPARQL ψευδο-διαφήμιση**: sparql-endpoint.lisp διαφημίζει FILTER/
   OPTIONAL/ORDER BY (γρ. 8-10, 78-80, 115-116)· ο evaluator
   (sparql-select, γρ. 381-418) εφαρμόζει ΜΟΝΟ DISTINCT/OFFSET/LIMIT —
   ερώτημα με FILTER επιστρέφει ΣΙΩΠΗΛΑ λάθος αποτελέσματα. Υλοποίηση Ή
   τυπισμένη άρνηση (unsupported-feature) — όχι τρίτος δρόμος. (Το
   corpus-sparql.lisp είναι υγιές: ρητά wiring layer πάνω στη μία μηχανή.)
2. **eu-interop-layer.lisp (723 γρ.)**: φανταστικά endpoints (EBSI
   `api.ebsi.eu`, eur-lex `api/`, γρ. 25-34). Fate map: **DPR — μόνο το
   CELLAR SPARQL επιβιώνει σε νέο, τίμιο module** (καταναλωτές: corpus-eu-
   links, source-profile — μεταφέρονται εκεί).
3. **blockchain-authority.lisp (976 γρ.)**: ήδη [0116] πιθανώς
   μη-λειτουργικό ethereum anchoring· fate map: **SUPERSEDE από
   witnesses+ERS** (ζωντανοί καταναλωτές: semantic-authority, engine
   stages/anchor-blockchain, backends/arweave — αποσυνδέονται στη φάση
   Φ-ΑΥΘΕΝΤΙΑ· τα offline RLP tests μπορούν να μείνουν LEGACY).
4. **greek-nlp-core.lisp (652 γρ.)**: κεφαλίδα «DARPA-GRADE … guarantees
   10/10» με 2 μόνο αναφορές (gr-syntagma/parsing + architecture test).
   Απορρόφηση στη μία NLP έδρα του Ρ3.3 με τίμια αυτοπεριγραφή.
5. **SSRF στο government-source.lisp**: drakma `:redirect 5` χωρίς per-hop
   έλεγχο (γρ. 117-120), σε αντίθεση με τη ρητή πολιτική του
   document-fetch. Μία έδρα HTTP κτήσης με per-hop policy — το
   government-source εκχωρεί σε αυτήν (fate map: REFACTOR → USC
   acquisition).

### Ρ6 — Ελληνο-κεντρισμός στην ΕΔΡΑ ταυτότητας [ΜΕΣΟ — προϋπόθεση Π7-U.2]

legal-identity.lisp: hardcoded `:gr` και στα δύο σκέλη του make-body
(γρ. 155, 179, 186), κλειστή ιεραρχία διάταξης, hardcoded χάρτης σωμάτων.
Κατά Π7-U.1 v7 (εγκεκριμένο-προς-εξέταση contract) και PANOPLIA Στρώμα 1:
δικαιοδοσία/ιεραρχία/τυπολογίες φεύγουν από τον κώδικα και γίνονται
εγγραφές journaled registries — νέα δικαιοδοσία = ΝΕΕΣ ΕΓΓΡΑΦΕΣ, μηδέν
επέμβαση σε έδρα. (Μαζί πεθαίνει και το δεύτερο, filename-based σύστημα
ταυτότητας της νομολογίας — [0116] §4.4.)

### Ρ7 — God-files (δείκτης, όχι αυτοσκοπός)

version-graph.lisp 2613 · cli/main.lisp 2557 · legal-ast.lisp 2359 ·
pdf-adapter.lisp 2275 · gr-syntagma/parsing.lisp 2222 · cli/decisions.lisp
2150. Το version-graph είναι KEEP CORE (fate map) — δεν ξαναγράφεται·
τεμαχίζεται μόνο ό,τι απαιτεί η Ρ1 αποσύνθεση (π.χ. checkpoint/fold έδρα
χωριστή, κατά το «Στρώμα 3 — Προβολές» του [0116] §6). Το cli/main.lisp
τεμαχίζεται με το registry ιδιοκτησίας εντολών που ήδη υπάρχει ([0086]).

### Ρ8 — Εκτός σκέλους κώδικα (ονομαστικά — δένουν με το Π.1 σκέλος outputs)

SBOM «MIT» μέσα στο runtime image (docker/sbom.json:24-25, αντίφαση με
All-Rights-Reserved) · Dockerfile.test με Quicklisp από δίκτυο (γρ. 6-19) ·
auto tag-release στο workflow (γρ. 359+, χωρίς πύλη δημιουργού) ·
Φ-ΜΑΡΤΥΡΕΣ-ΜΕΤΑΛΛΑΞΗΣ (οι 10 επιβιώσεις του [0116+] §Β2 — ο Merkle άξονας
καλύφθηκε στα [0118]-[0121], οι λοιπές κλάσεις εκκρεμούν) · Φ-ΕΝΑ-ΚΕΙΜΕΝΟ
(spec-drift/supersession — παραμένει ανοιχτό όπως μετρήθηκε στο [0116+]).

## §3 · ΣΤΟΙΧΙΣΗ ΜΕ ΤΟ PANOPLIA (τι προσγειώνεται πού — και τι ΑΠΑΓΟΡΕΥΕΤΑΙ)

1. **Το M-0H2 προσγειώνεται στο orchestrator-meta** (ASDF επέκταση, κατά
   DECISION-CL-FROM-START και Master Plan Φάση 0): refinement calculus,
   succession objects (CAS predecessor≡current + epochs — F-01/F-02),
   rollback tokens single-use (F-02/F-19), atomic admission με REJECT
   records (F-03), attestation με Ironclad (F-10/F-20 — η ed25519 εμπειρία
   υπάρχει ΜΟΝΟ στο authority-proof-bundle: αυτή είναι η έδρα-πρότυπο),
   execution broker (F-18 — σήμερα μόνο 2 σημεία run-program:
   document-fetch, pdf-authority· ο broker γίνεται η ΜΙΑ πύλη εξωτερικών
   διεργασιών), CLI/JSON διεπαφή για εξωτερικά falsifiers.
2. **ΔΕΝ ξαναγράφονται σε CL** (ρητή απαγόρευση δεύτερης-κατώτερης έδρας,
   Master Plan v1.2): το Zig journal/transaction kernel του LAW-MAX· ο
   admission kernel K του authority-v2/kernel/admission-model.sexp (στόχος
   F* μέσω succession — το CL τον ΚΑΤΑΝΑΛΩΝΕΙ ως spec, δεν τον υλοποιεί).
3. **Το υπάρχον journal.lisp** (KEEP CORE) επεκτείνεται με enumerated
   kill-points + replay semantics (F-19) — επέκταση, όχι rewrite· η
   fsync/flock βάση του [0117] είναι ήδη η σωστή αφετηρία.
4. **Τρεις κλάσεις κώδικα** (Ω9/Ι5: TRUSTED_AUTHORED / GENERATED_CANDIDATE
   / ADMITTED_GENERATED): το L7 candidates/+quarantine capture είναι ήδη ο
   σπόρος· η κλάση γίνεται machine-readable πεδίο artifact στο load path.
5. **Η Ρ1 αποσύνθεση κατά ΣΚΟΠΙΑ** δεν είναι αισθητική: είναι η προϋπόθεση
   ώστε ΕΡΜΗΝΕΙΟΝ/ΑΠΕΙΡΟΝ/ΠΡΑΞΙΣ κτήσεις να αποσπαστούν αργότερα ΧΩΡΙΣ νέο
   refactoring (SYSTEM-DECOMPOSITION §5: «γεννήτορες εκτός, ελεγκτές
   εντός»), και ώστε η Φάση Π να εκδώσει πάνω σε σταθερές έδρες.

## §4 · ΠΡΟΤΕΙΝΟΜΕΝΕΣ ΔΟΣΕΙΣ (όλες :requires-ok — καμία δεν ανοίγει χωρίς «εγκρίνω»)

| Δόση | Περιεχόμενο | Ρίσκο | Προαπαιτούμενο |
|---|---|---|---|
| Δ-Α ΝΕΚΡΩΣΕΙΣ | Ρ2 (νησιά/DPR/ψευδο-υλοποιήσεις) + metrics-stub + protocols ×2 | ελάχιστο (0 callers, αποδεικνύεται) | έγκριση· git log -S ανά θάνατο |
| Δ-Β ΜΙΑ ΕΔΡΑ | Ρ3 (mod-inverse→Ironclad, normalize-greek, tokenize, escaping, safe-read reader) | μέτριο (ζωντανοί callers — ανά έδρα proof) | Δ-Α |
| Δ-Γ ΤΙΜΙΑ ΑΓΝΟΙΑ | Ρ4+Ρ5 (52 σιωπηλά defaults→conditions, SPARQL, eu-interop→CELLAR, SSRF per-hop, blockchain αποσύνδεση) | μέτριο | Δ-Α |
| Δ-Δ ΑΠΟΣΥΝΘΕΣΗ | Ρ1 (ASDF systems κατά ΣΚΟΠΙΑ, θάνατος 366 find-symbol/intern) | υψηλό — γίνεται ΥΠΟ M-0H2 κυβερνήτη κατά το πλάνο v1.4 | M-0H2 ή ρητή εντολή |
| Δ-Ε ΤΑΥΤΟΤΗΤΑ ΩΣ ΔΕΔΟΜΕΝΑ | Ρ6 (:gr/ιεραρχία/σώματα → registries) | υψηλό | «εγκρίνω Π7-U.1»/Π7-U.2 |
| Δ-ΣΤ M-0H2 ΠΡΟΣΓΕΙΩΣΗ | §3.1 έδρες στο orchestrator-meta | — | Φάση 0 του Master Plan |

Η σειρά σέβεται το Master Plan: το 0.0 audit (παρόν) → έγκριση → Δ-Α/Δ-Β/Δ-Γ
μπορούν να προηγηθούν ως αυτοτελείς, χαμηλού ρίσκου δόσεις ή να μπουν όλες
υπό τον M-0H2 — **απόφαση δημιουργού**. Η ΠΥΛΗ ΕΚΔΟΣΗΣ (Φάση Π) απαιτεί
τουλάχιστον Δ-Α/Δ-Β/Δ-Γ + το σκέλος outputs του Π.1 που δεν καλύφθηκε εδώ.

## §5 · ΤΙΜΙΑ ΟΡΙΑ

Στατική ανάλυση — κανένα gate/τεστ δεν εκτελέστηκε· οι αριθμοί σουιτών όπου
αναφέρονται είναι δηλώσεις των proofs του repo. Οι μετρήσεις νησιών βασίζονται
σε αναφορές ονόματος πακέτου (ένα ψευδο-θετικό εντοπίστηκε και εξαιρέθηκε:
authority-evidence-replay έχει gated σουίτα)· πριν από κάθε θάνατο, το
0-callers ξανα-αποδεικνύεται στην έδρα με git log -S κατά το [0045]. Η
σύγκριση 366 vs 226 find-symbol/intern φέρει αβεβαιότητα πλαισίου μέτρησης
του [0116] — το ελάχιστο συμπέρασμα είναι ότι η κλάση ΔΕΝ συρρικνώθηκε. Τα
specs του PANOPLIA zip διαβάστηκαν στα κανονικά τους έγγραφα (§3 MASTER-INDEX
+ fate map + ΣΚΟΠΙΑ corpus)· οι 13 κύκλοι omega διαβάστηκαν επιλεκτικά όπου
δένουν με το WATCHTOWER — όχι λέξη-προς-λέξη στο σύνολό τους.

---

# [0126+] — ΤΡΕΙΣ ΕΡΜΗΝΕΥΤΙΚΕΣ ΑΠΟΦΑΣΕΙΣ ΔΗΜΙΟΥΡΓΟΥ ΕΠΙ ΤΩΝ ΝΟΜΩΝ (2026-09-26, εν συνεδρία — δεσμευτικές)
**Claude · 2026-09-26 · καταγραφή αυτούσιων αποφάσεων + συνέπειες στον χάρτη [0126]**

## Απόφαση 1 — Wrappers: όχι απλώς απαγόρευση — ΚΑΘΗΚΟΝ ΑΝΤΙΚΑΤΑΣΤΑΣΗΣ
«Wrapper απαγορεύεται· εάν υπάρχει ήδη, πρέπει να αντικατασταθεί με κάτι
ανώτερο.» Δηλαδή: υπάρχων wrapper στο repo δεν είναι ανεκτό κατάλοιπο —
είναι ΕΚΚΡΕΜΗΣ ΟΦΕΙΛΗ αντικατάστασης από την ανώτερη έδρα.
**Συνέπεια στον χάρτη:** η δόση Δ-Β αναδιατυπώνεται ως «αντικατάσταση με το
ανώτερο», όχι «ενοποίηση»: χειροποίητο EMSA-PKCS1/mod-inverse ⇒
ΑΝΤΙΚΑΘΙΣΤΑΤΑΙ από Ironclad RSA (όχι wrapper γύρω από το παλιό)· metrics-stub
⇒ ΑΝΤΙΚΑΘΙΣΤΑΤΑΙ από πραγματική έδρα ή fail-loud (όχι νέο stub)· τα
find-symbol trampolines του corpus-service ⇒ ρητές εξαρτήσεις/registry-
dispatch· τα %sha/%normalize shims ανά αρχείο ⇒ απευθείας κλήση της μίας
έδρας. Κριτήριο αποδοχής ανά αντικατάσταση: ο παλιός wrapper ΔΕΝ υπάρχει
πλέον (git log -S μαρτυρεί), οι callers δείχνουν στην ανώτερη έδρα, κανένα
συμβατικό «στρώμα μετάβασης» δεν μένει χωρίς ημερομηνία θανάτου.

## Απόφαση 2 — «0 λάθος»
Ο δημιουργός επιβεβαιώνει την ανάγνωση μηχανισμού (κάθε λάθος ⇒ finding στο
μητρώο, υπολογισμένες πύλες, fail-closed) — καμία αλλαγή νόμου.

## Απόφαση 3 — Άδεια: All Rights Reserved ΙΣΧΥΕΙ· πρόσβαση-έναντι-citation ΜΟΝΟ στο OUTPUT
«Το All Rights Reserved ισχύει. Εάν [τα AI συστήματα] δέχονται να κάνουν
citation, τότε θα έχουν πρόσβαση στο OUTPUT — ποτέ στον κώδικα.»
Αυτό απαντά την εκκρεμότητα Π.7/Deferred License Policy ως προς τη ΔΟΜΗ:
- **Κώδικας/σύστημα:** All Rights Reserved, καμία εξαίρεση, ποτέ.
- **Δημοσιευμένο στρώμα (output):** πρόσβαση ΥΠΟ ΟΡΟ απόδοσης/παράθεσης
  (citation-conditional), όχι ανοιχτή άδεια.
**Συνέπειες στη Φάση Π (καταγράφονται για το σκέλος Π.2-Π.4, ΟΧΙ υλοποίηση
τώρα):** (α) οι όροι γίνονται ΜΗΧΑΝΙΚΑ αναγνώσιμοι σε κάθε τεκμήριο —
license/terms πεδίο στο JSON-LD, llms.txt, robots policy, per-document
terms URI — ώστε ο όρος «citation ⇒ πρόσβαση» να είναι δηλωμένος εκεί που
διαβάζουν οι crawlers· (β) η τεχνική επιβολή του όρου σε crawlers είναι εκ
φύσεως μερική (robots/ToS είναι δηλώσεις, όχι φράχτες) — η συμμόρφωση
ΜΕΤΡΙΕΤΑΙ από το Π.6 harness (citation-share/attribution accuracy) και η
παράβαση είναι νομικό ζήτημα, πεδίο του δημιουργού· (γ) η ΣΥΝΤΑΞΗ της
άδειας (κείμενο όρων citation-conditional) είναι νομική πράξη του
δημιουργού — εκκρεμεί ως το τελευταίο σκέλος του Π.7 πριν το πάγωμα
URI+άδειας της Πύλης Έκδοσης.

Οι τρεις αποφάσεις είναι εντολές δημιουργού εν συνεδρία· το παρόν είναι η
καταγραφή τους στο μητρώο κατά το πρωτόκολλο. ΚΑΜΙΑ υλοποίηση δεν ξεκίνησε.
