# [0039] Claude → Κριτή+δημιουργό · 2026-07-09 · P0 PLAN: Lettered Article Identity (Publisher/Root-Authority Hardening)

**PLANNING ONLY — κανένας κώδικας δεν αγγίχτηκε.** Απαίτηση: `5Α/9Α/100Α/101Α`
διακριτά από `5/9/100/101` σε corpus.jsonl / AKN / manifests. FF3 κλειστό στο
`main` (deec3b33). FF4 κλειστό.

## ΠΡΩΤΑ: διόρθωση της [0036] εκτίμησης (τίμια αναθεώρηση)

Στο [0036] χαρακτήρισα το B «ΕΠΙΒΕΒΑΙΩΜΕΝΟ στο τρέχον HEAD» με εικαζόμενη έδρα
«eIds από number, αγνοείται το label». Η βαθύτερη έρευνα το ΑΝΑΤΡΕΠΕΙ:

```
LIVE PROOF @ deec3b33 (build-consolidated-for "syntagma", in-memory):
  count=124 · unique=124 · duplicates=NIL
  art_5Α=T · art_9Α=T · art_100Α=T · art_101Α=T   (διακριτά από art_5/9/100/101)
```

Ο `%parse-article-title` (main.lisp:426) ΗΔΗ εξάγει «100Α» από τον τίτλο
(digits+suffix μέσω του ΕΝΟΣ +article-suffix-regex+· ρητό σχόλιο για το παλιό
370ΣΤ bug «never again»). Το per-article path επίσης διατηρεί την ταυτότητα
ΑΚΟΜΑ ΚΑΙ στο παλιό output: filenames `article-005Α.*` ΚΑΙ ELI
`…/art/5Α` ≠ `…/art/5`. **Τα zip/τοπικά corpus.jsonl+AKN (124 records/120
unique) είναι STALE artifacts από build ΠΡΙΝ το parser fix** — όχι ο τρέχων
κώδικας.

**Συνέπεια για το P0:** δεν χρειάζεται rewrite του identity μοντέλου. Το P0
γίνεται: **(α) αναγέννηση των stale artifacts, (β) ΜΟΝΙΜΟ regression lock
end-to-end** (ώστε καμία μελλοντική παλινδρόμηση να μην ξαναπεράσει σιωπηλά),
**(γ) ένα προαιρετικό latent-seat fix** (κάτω, χρειάζεται τη δική σου έγκριση).

---

## 1. Ακριβείς έδρες (πλήρης χάρτης ταυτότητας)

| Έδρα | Ρόλος | Κατάσταση @ deec3b33 |
|---|---|---|
| `main.lisp:426 %parse-article-title` | τίτλος→id «100Α» (consolidation είσοδος) | ✅ σωστό (live proof) |
| `consolidation-bridge.lisp:40 article-eid` | id→`art_100Α` | ✅ σωστό (περνά ό,τι πάρει) |
| `static-site.lisp %serialize JSONL/AKN/CATALOG/TTL` | doc→corpus.jsonl / consolidated.akn.xml | ✅ καταναλωτής των σωστών eids |
| `corpus-fingerprint.lisp %file-id-eid` | article-070Α.hash→`art_70Α` (manifests) | ✅ σωστό (30/30 test) |
| `generate-rdf.lisp:126 make-canonical-uri … article-label` | per-article ELI URI | ✅ label-aware |
| `filesystem.lisp article-base-filename / article-file-id` | filenames `article-005Α` | ✅ label-aware |
| **`normalized-input.lisp:286 article->normalized`** | article→normalized: `:article-label (format nil "~D" number)` | ⚠ **LATENT**: πετά το label — ΔΕΝ ασκείται από το pipeline (που περνά ρητό label), αλλά είναι παγίδα για μελλοντικό caller |
| `amendment-extractor.lisp %art-eid` | στόχοι τροπολογιών από ΦΕΚ κείμενο | ✅ περνά το id όπως εξάγεται (incl. suffix grammar) |

## 2. Τρέχον failing proof
- **Stale artifacts** (zip + τοπικό `output/constitution` pre-fix):
  `corpus.jsonl`: 124 records / **120 unique** · AKN: duplicates `art_5, art_9,
  art_100, art_101` · τα 5Α/9Α/100Α/101Α ΑΠΟΝΤΑ.
- **Live code**: 124/124 unique (proof παραπάνω). ⇒ Το failing είναι το
  ΔΗΜΟΣΙΕΥΜΕΝΟ/αποθηκευμένο artifact layer + η ΑΠΟΥΣΙΑ regression lock.

## 3. Κανονικό article-id μοντέλο (καμία αλλαγή — επικύρωση του υπάρχοντος)
```
canonical id   : <αριθμός χωρίς padding><ΚΕΦΑΛΑΙΟ ελληνικό επίθημα>   π.χ. 5Α, 370ΣΤ
eId            : art_<id>                π.χ. art_5Α   (≠ art_5)
ELI URI        : …/art/<id>              π.χ. …/art/5Α (≠ …/art/5)
filename       : article-<zero-padded><suffix>  π.χ. article-005Α.*
μία γραμματική : orchestrator.engine.sbcl:+article-suffix-regex+ (η ΜΙΑ έδρα επιθημάτων)
μία ταυτότητα  : orchestrator.article-id (parse/serialize/hash — ήδη gated: contract ⑩⑪⑫, component ⑥⑦⑧⑨)
```

## 4. Migration boundary
- **Αναγέννηση artifacts** (fresh run: pipeline + site emit για constitution·
  προαιρετικά όλα τα corpora). Το `output/` είναι regenerable (gitignored) —
  ΚΑΝΕΝΑ committed data migration.
- **Goldens**: ΑΜΕΤΑΒΛΗΤΑ — το golden-gate είναι ΗΔΗ πράσινο 8/8 στον τρέχοντα
  κώδικα (σημασιολογικές ρίζες)· καμία επέμβαση.
- **Μοντέλο/πυρήνας**: ΚΑΜΙΑ αλλαγή. Το μόνο προαιρετικό code fix: το latent
  seat `normalized-input.lisp:286` να διατηρεί το πραγματικό label
  (`(article-label article)` αν υπάρχει, αλλιώς `~D`) — 1 γραμμή, μηδενική
  επίδραση στο ασκούμενο pipeline (που ήδη περνά ρητό label). **Θέλει τη δική
  σου έγκριση· αλλιώς μένει εκτός P0 ως καταγεγραμμένο χρέος.**

## 5. Regression tests (το ΚΛΕΙΔΩΜΑ — νέα, gated)
Νέο `tests/corpus-identity-test.lisp` στο standalone loop (ίδιο harness):
```
① build-consolidated-for syntagma ⇒ 124 provisions · 124 unique eIds
② art_5Α/9Α/100Α/101Α ΠΑΡΟΝΤΑ και ≠ art_5/9/100/101 (όλα τα 8 διακριτά)
③ JSONL-REPRESENTATION του doc ⇒ 124 γραμμές · unique ids · περιέχει "art_5Α"
④ AKN-REPRESENTATION ⇒ 124 eId= · unique · art_5Α παρόν · ΚΑΝΕΝΑ duplicate eId
⑤ %parse-article-title: «Άρθρο 5Α - Χ» ⇒ ("5Α","Χ")· «Άρθρο 370ΣΤ» ⇒ "370ΣΤ"·
   «Άρθρο 5 - Χ» ⇒ ("5","Χ") — η γραμματική κλειδωμένη στο test επίπεδο
⑥ fingerprint manifest από article-005.hash + article-005Α.hash ⇒ 2 ΔΙΑΚΡΙΤΑ
   eIds art_5/art_5Α (συμπληρώνει το υπάρχον 30/30)
```
Καμία πύλη δεν αγγίζεται (το lock ζει στο gated standalone loop = canonical CI).

## 6. Αναμενόμενες αλλαγές artifacts (στην αναγέννηση)
```
output/<corpus>/corpus.jsonl        : 124 records · 124 unique ids (ήταν 120)
output/<corpus>/consolidated.akn.xml: +art_5Α/9Α/100Α/101Α · κανένα duplicate
catalog/manifests                   : νέα hashes (παράγωγα)
per-article αρχεία                  : ΑΜΕΤΑΒΛΗΤΗ ονοματολογία (ήδη σωστή)
```

## 7. Rollback
- Test αρχείο + Dockerfile γραμμή: 1 commit revert.
- Artifacts: regenerable — αναγέννηση από προηγούμενο `main` = πλήρης επιστροφή.
- (Αν εγκριθεί το latent fix) normalized-input: 1-γραμμή revert, καμία κατάντη
  εξάρτηση (proof: pipeline περνά ρητό label ήδη).

## 8. Proof commands (μετά την υλοποίηση)
```powershell
docker build --target standalone-test .          # incl. ΝΕΟ corpus-identity-test
docker build --tag orchestrator:test .
docker run --rm -v "${PWD}:/src" -w /src -e LAWMAX_ROOT=/src -e ORCHESTRATOR_OUTPUT_DIR=/src/output -e ORCHESTRATOR_CORPUS=syntagma orchestrator:test --run-pipeline
docker run --rm -v "${PWD}:/src" -w /src -e LAWMAX_ROOT=/src -e ORCHESTRATOR_OUTPUT_DIR=/src/output orchestrator:test --emit-site
# audit (python): corpus.jsonl 124/124 unique · AKN eIds unique · 5Α/9Α/100Α/101Α distinct
docker run --rm -v "${PWD}:/src" -w /src -e LAWMAX_ROOT=/src orchestrator:test --gates
docker run --rm -v "${PWD}:/src" -w /src -e LAWMAX_ROOT=/src orchestrator:test --verify-truth-gate
```

## 9. Αρχεία που θα αγγιχτούν (ΜΟΝΟ)
```
tests/corpus-identity-test.lisp     (ΝΕΟ — το regression lock)
Dockerfile                          (1 γραμμή: + corpus-identity στο loop)
deployment/collab/dialogue/0040-*   (record)
[ΜΟΝΟ ΜΕ ΕΓΚΡΙΣΗ] systems/orchestrator-model/normalized-input.lisp:286 (1 γραμμή, latent label seat)
```

## 10. Επιβεβαίωση ορίων
**ΔΕΝ αγγίζονται σε αυτό το P0 PR:** A (standalone JSON-LD double-object) ·
C (release TTL) · D (manifest.jsonld plist) · E (release binding) ·
F (telemetry σε canonical HTML) · FF4 · Ω+ · καμία νέα λειτουργία.

---
**Αποφάσεις που ζητώ:** (i) έγκριση του P0 plan όπως είναι· (ii) ναι/όχι στο
1-γραμμή latent fix του normalized-input (αλλιώς μένει καταγεγραμμένο χρέος)·
(iii) η αναγέννηση artifacts να καλύψει ΜΟΝΟ constitution ή ΟΛΑ τα corpora.

— Claude (Χειρουργός Πυρήνα) · planning only · κανένας κώδικας δεν αγγίχτηκε
