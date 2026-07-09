# [0041] Claude (Χειρουργός Πυρήνα) — P0 Identity Lock + Artifact Regeneration: ΥΛΟΠΟΙΗΣΗ

**Ημερομηνία:** 2026-07-09
**Φάση:** Publisher/Root-Authority Hardening — P0 (η ΜΟΝΗ ανοιχτή)
**Εγκρίσεις δημιουργού:** (1) P0 plan [0039] ΕΓΚΡΙΘΗΚΕ (2) latent fix
`normalized-input.lisp` ΝΑΙ (3) αναγέννηση artifacts: ΟΛΑ τα corpora.
**Κλειστά:** FF4 · Ω+ · A/C/D/E/F · JSON-LD/TTL/manifest/release/telemetry ·
MCP/API/discovery · temporal currency · γενικό cleanup.

---

## 1. Αναφορά ΠΡΙΝ το implementation commit (τα 5 ζητούμενα)

### 1.1 Ακριβής λίστα corpora που ανιχνεύθηκαν

Έξι (6), από τη ΜΙΑ έδρα `*served-corpora*` (`systems/orchestrator-cli/main.lisp`),
με τα short names των configs (= κατάλογοι στο `output/`):

| corpus-id (`build-consolidated-for`) | short (output dir) | ζωντανά άρθρα | lettered |
|---|---|---|---|
| `syntagma` | `constitution` | 124 | 4 |
| `poinikos` | `poinikos` | 529 | 67 |
| `kpoinikis` | `kpoinikis` | 595 | 1 |
| `astikos` | `astikos` | 2040 | 5 |
| `kpolitikis` | `kpolitikis` | 1102 | 48 |
| `kdioikitikis` | `kdioikitikis` | 304 | 19 |

### 1.2 Ακριβής λίστα corpora προς αναγέννηση

ΚΑΙ τα 6 (απόφαση δημιουργού: «ΟΛΑ, όχι constitution-only») — τα tracked
`corpus.jsonl` και των 6 είναι STALE με διπλά eIds (κατάρρευση lettered):
constitution 124 records/120 unique · poinikos 529/462 · kpoinikis 595/594 ·
astikos 2040/2035 · kpolitikis 1102/1054 · kdioikitikis 304/285.

### 1.3 Ακριβής λίστα artifact paths που αναμένεται να αλλάξουν

Ακριβώς **30 αρχεία** — ανά corpus τα 5 corpus-level artifacts που γράφει ο
παραγωγικός `corpus-updater` (`source/ingestion-daemon.lisp`):

```
output/{constitution,poinikos,kpoinikis,astikos,kpolitikis,kdioikitikis}/
  ├─ corpus.jsonl
  ├─ consolidated.akn.xml
  ├─ catalog.jsonld
  ├─ consolidated.ttl
  └─ consolidated.txt
```

ΚΑΝΕΝΑ άλλο μονοπάτι: όχι per-article αρχεία (`article-*.{html,ttl,jsonld,txt,
hash,proof.json}`), όχι goldens, όχι site. Η αναγέννηση καλεί ΤΟΝ ΙΔΙΟ κώδικα
με την παραγωγή (`corpus-updater` → 5 serializers → write-authority
`EMIT-GRAPH :provenance`), όχι πλήρες pipeline — χειρουργική, όχι θόρυβος.

### 1.4 Ποια generated outputs είναι committed vs ignored

- `output/` είναι στο `.gitignore` (γραμμή 11), ΑΛΛΑ ~28.563 αρχεία είναι
  **legacy-tracked** (μπήκαν πριν το ignore· το gitignore δεν ξε-track-άρει).
- Τα 30 αρχεία του §1.3 είναι ΟΛΑ tracked ⇒ οι αλλαγές τους θα φανούν ως
  κανονικά diffs στο commit — αυτό ΕΙΝΑΙ το παραδοτέο (διόρθωση της
  δημοσιευμένης stale ταυτότητας).
- Νέα ΜΗ-tracked παράγωγα ΔΕΝ προστίθενται στο ευρετήριο (ό,τι δεν είναι ήδη
  tracked μένει κάτω από το ignore).
- Το `deployment/self/history.sexp` (runtime state) επαναφέρεται με
  `git checkout --` πριν από κάθε commit, όπως πάντα.

### 1.5 Επιβεβαίωση: κανένας άσχετος generated θόρυβος

Το implementation commit περιέχει ΜΟΝΟ: το 1-line latent fix, το νέο gated
test, τη γραμμή gating στο Dockerfile, και τα αρχεία διαλόγου/κατάστασης.
Το artifact commit περιέχει ΜΟΝΟ τα 30 αρχεία του §1.3. Απόδειξη στο τελικό
proof: `git show --stat` και των δύο commits + καθαρό `git status`.

---

## 2. Τι υλοποιήθηκε (μέσα στο εγκεκριμένο scope, τίποτα άλλο)

### 2.1 Latent fix — `systems/orchestrator-model/normalized-input.lisp` (1 γραμμή)

`article-to-normalized-input` πετούσε το γράμμα: `:article-label (format nil
"~D" number)` ⇒ ένα lettered άρθρο που θα περνούσε από εδώ θα κατέρρεε στη
βασική ταυτότητα. Τώρα: `(or (article-label article) (format nil "~D" …))`.
Έρευνα καλούντων: **κανένας παραγωγικός caller σήμερα** — γι' αυτό ήταν latent
και γι' αυτό η διόρθωση δεν αλλάζει κανένα τρέχον artifact· το νέο test την
κλειδώνει ώστε όποιος μελλοντικός caller τη χρησιμοποιήσει να είναι ασφαλής.

### 2.2 Νέο gated test — `tests/corpus-identity-test.lisp` (25 έλεγχοι, self-exit 0/1)

Το regression lock του [0039]: καμία νομική ταυτότητα χωρίς μοναδική έδρα.

| # | Αναλλοίωτη |
|---|---|
| ① ×6 | ΚΑΘΕ corpus: πλήθος>0 και ΟΛΑ τα eIds μοναδικά |
| ② ×4 | Σύνταγμα: art_5Α/art_5, art_9Α/art_9, art_100Α/art_100, art_101Α/art_101 συνυπάρχουν διακριτά |
| ③ ×6 | ΚΑΘΕ corpus: κανένα lettered eId δεν καταρρέει στο βασικό του (144 lettered συνολικά) |
| ④ | JSONL: μία γραμμή ανά άρθρο, article-eIds μοναδικά (τα `art_N__para_M` ΔΕΝ μετρούν), art_5Α ΚΑΙ art_5 παρόντα |
| ⑤ | AKN: eId attributes άρθρων μοναδικά, art_5Α ΚΑΙ art_5 παρόντα |
| ⑥ ×4 | Γραμματική τίτλου `%parse-article-title`: «5Α»→5Α · δίγραφο «370ΣΤ»→370ΣΤ · απλό «5»→5 · χωρίς αριθμό→NIL (τίμιο fallback) |
| ⑦ | Fingerprint: `article-005` + `article-005Α` ⇒ art_5 ΚΑΙ art_5Α διακριτά στο output-manifest |
| ⑧+⑧β | Latent fix: label «5Α» ΕΠΙΖΕΙ στη μετατροπή· χωρίς label ⇒ fallback «7» |

Gating: προστέθηκε `corpus-identity` στο standalone-test loop του `Dockerfile`
(ίδιος μηχανισμός με όλα τα gated tests — ΚΑΝΕΝΑΣ wrapper).

### 2.3 Αναγέννηση των 30 stale artifacts

Μέσω ΤΟΥ ΙΔΙΟΥ παραγωγικού μονοπατιού (`corpus-updater` per corpus). Η ανά
αρχείο εξήγηση των diffs κατατίθεται στο μήνυμα του artifact commit και στην
τελική αναφορά προς τον δημιουργό.

---

## 3. Επαλήθευση (τοπικά, source-present, πριν τα commits)

- `corpus-identity-test`: **25/25** ✓
- Πλήρες gated standalone loop (78 tests): **78/78 PASS** ✓
- `verify-truth`: φρουρός 21 fixtures + live = **22/22** ✓
- Ολομέλεια `--gates` (23 πύλες): **22/23** — μόνο `--advisor-gate` κόκκινη,
  το γνωστό pre-materialization baseline (η σκιώδης δίκη ονείρων θέλει τα
  materialized deontic norms του pipeline· στο CI με materialization A και
  στο docker του δημιουργού ⇒ 23/23). ΙΔΙΟ με το accepted state στο merge
  του FF3 — καμία νέα κόκκινη πύλη από το P0.
- `--golden-gate` 8/8: αμετάβλητη εκ κατασκευής — semantic goldens εξαρτώνται
  μόνο από το in-memory consolidated document (δεν άλλαξε)· emitted goldens
  διαβάζουν ΜΟΝΟ `article-*.hash` (δεν αγγίχτηκαν).

---

*Χειρουργός Πυρήνα — καμία ταυτότητα χωρίς έδρα, καμία έδρα χωρίς φρουρό.*
