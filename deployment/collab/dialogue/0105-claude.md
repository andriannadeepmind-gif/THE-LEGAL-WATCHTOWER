# [0105] Claude — +3 ΘΕΩΡΗΜΑ, Στάδιο 2: ΜΕΤΑΘΕΣΗ ΚΥΡΙΑΡΧΙΑΣ ΚΕΙΜΕΝΟΥ

Ημερομηνία: 2026-07-21 · Συνέχεια του [0104] (Στάδιο 1: πόρτα εισδοχής). Task #73.

## Α. Το δομικό πρόβλημα που πέθανε

Ο χάρτης του emit pipeline έδειξε ΔΥΟ αλήθειες κειμένου:
- Per-article artifacts (article-*.txt/html/jsonld/ttl): πάγωναν από το **raw
  IIR** στο generate-rdf-stage — ΠΡΙΝ καν υπάρξει το consolidated (DAG:
  generate-rdf → consolidate).
- Serving/static-site/graph bootstrap: από το **consolidated** legal-document.

Κάθε μελλοντική τροποποίηση/κατάργηση θα άλλαζε το consolidated αλλά ΟΧΙ τα
per-article artifacts — σιωπηλή τρίτη αλήθεια. Φρουρός-parity θα ήταν μπάλωμα·
η κλάση πέθανε δομικά.

## Β. Η υλοποίηση (έδρες: stages/generate-rdf.lisp, stages/consolidate.lisp)

1. `generate-rdf-stage` αναδομήθηκε σε φάσεις:
   (1) **ΤΑΥΤΟΤΗΤΑ**: `build-canonical-article` (IIR → article instance, typed
   identity/URI/metadata — ΧΩΡΙΣ formats)·
   (2) **Η ΜΙΑ ΠΑΡΑΓΩΓΗ**: `%consolidate-from-articles` (ίδιες έδρες με πριν:
   triples → consolidate-corpus + amendments + work-date) — ΕΔΩ, πριν από κάθε
   render· μπαίνει στο context ως :consolidated·
   (3) **ΚΥΡΙΑΡΧΙΑ**: `article-content` ΚΑΘΕ άρθρου := in-force κείμενο του
   consolidated (`ai-dump:article-text` — Η ΜΙΑ έδρα απόδοσης, ίδια με
   JSONL/graph bootstrap)· provision που λείπει ⇒ ΣΦΑΛΜΑ· :repealed ⇒ κενό
   σώμα (τίμιο tombstone)·
   (4) **ΑΠΟΔΟΣΗ**: `render-canonical-formats` — ΟΛΑ τα formats (TTL μέσω
   content-override στο FRBR stack, JSON-LD, HTML) από το κυρίαρχο κείμενο.
2. `consolidate-stage`: ΔΕΝ ξανα-υπολογίζει — καταναλώνει το context
   :consolidated (απόν ⇒ ΣΦΑΛΜΑ, καμία σιωπηλή δεύτερη παραγωγή) και γράφει
   τα consolidated artifacts + corpus.jsonl/catalog.

Αλυσίδα πλέον ΕΚ ΚΑΤΑΣΚΕΥΗΣ: **graph fold ≡ consolidated ≡ per-article
artifacts** (το πρώτο ≡ ήταν ήδη ο fold-parity φρουρός· το δεύτερο έγινε
αδύνατο να σπάσει γιατί δεν υπάρχει δεύτερη ροή κειμένου).

## Γ. Απόδειξη

- ΝΕΟ lock `tests/text-sovereignty-test.lisp` **11/11**: consolidated στο
  context από το generate-rdf· article-content byte-ίσο με το in-force κείμενο·
  η κανονική μορφή ΕΠΙΒΛΗΘΗΚΕ (≠ ακατέργαστη πηγή — όχι ταυτολογία)· HTML/
  JSON-LD-hash/TTL φέρουν το κυρίαρχο κείμενο· consolidate-stage fail-closed
  χωρίς context· corpus.jsonl στον δίσκο ταυτίζεται.
- ingestion-e2e 10/10 · fek-ingestion 10/10 · corpus-identity 55/55 ·
  static-site 45/45 · πλήρες inventory: βλ. commit.

## Δ. Τίμιες δηλώσεις

- Τα per-article artifacts θα αλλάξουν bytes στον επόμενο owner --run-pipeline
  όπου IIR ≠ κανονική μορφή consolidated (whitespace/δομή) ή όπου amendments
  αγγίζουν άρθρα — αυτό ΕΙΝΑΙ η διόρθωση, όχι regression. Ο golden-gate θα το
  δείξει· τυχόν επαν-αναφορά goldens = ΣΥΝΕΙΔΗΤΗ (GOLDEN_WRITE), μετά από
  επιθεώρηση του δημιουργού.
- Επόμενα (#73): Στάδιο 3 — text-bearing amendment operators ως ο ΜΟΝΟΣ δρόμος
  αλλαγής κειμένου + πύλη μη-παράκαμψης (η consolidated βάση να έρχεται από
  τον ΓΡΑΦΟ αντί για clean.json — το τελικό κλείσιμο του +3)· Στάδιο 4 — +1
  άγκυρα ΕΤ-υπογραφών, +2 N-version εξαγωγή.
