# [0089] GAAF-0 — Global AI Authority Framework (ΣΧΕΔΙΟ, καμία υλοποίηση)

Κατάθεση: Claude (Χειρουργός Πυρήνα), 2026-07-14.
Εντολή δημιουργού: «κατέθεσε το GAAF-0 design με Authority Capsule,
universal retrieval, citation contract, crawler policy, benchmark και
adoption observatory. Μετά ξεκινά υλοποίηση, όχι πριν.»
Καθεστώς: ΣΧΕΔΙΟ προς έγκριση — ΚΑΜΙΑ γραμμή runtime κώδικα πριν από ρητό
«εγκρίνω GAAF-0».

## 0. Πρόβλημα και θέση

Το LAWMAX είναι σήμερα proof-carrying authority publisher: κάθε διάταξη
φέρει LegalAuthorityReceipt, διτεμπορική τομή (valid-at × known-at),
Merkle δέσμευση, TSA χρονοσφράγιση και ανεξάρτητο verifier. Αυτό όμως
αποδεικνύει την αυθεντία ΣΤΟΝ ΕΑΥΤΟ ΤΟΥ. Το GAAF-0 ορίζει το ΕΞΩΤΕΡΙΚΟ
συμβόλαιο: πώς ΚΑΘΕ AI σύστημα (LLM crawler, RAG pipeline, agent,
αναζήτηση) ανακτά, επαληθεύει και ΠΑΡΑΘΕΤΕΙ το corpus με τρόπο που
(α) καθιστά τη μη-επαληθεύσιμη παράθεση ανιχνεύσιμη, (β) μετράει την
υιοθέτηση, (γ) δεν εμπιστεύεται κανένα LLM στο trusted path.

Αρχές (κληρονομούμενες, δεσμευτικές): μία έδρα ανά έννοια· fail-closed·
τίμια άγνοια· καμία σιωπηλή υποβάθμιση· All Rights Reserved· ο δημιουργός
εγκρίνει κάθε φάση.

## 1. AUTHORITY CAPSULE — η μονάδα διανομής

**Ορισμός**: αυτοτελές, content-addressed αντικείμενο ανά (διάταξη ×
διτεμπορική τομή) που περιέχει ΟΛΑ όσα χρειάζεται τρίτος για ανεξάρτητη
επαλήθευση, χωρίς πρόσβαση στο σύστημά μας:

```
capsule/1 := {
  provision      : { work-uri, article-uri (typed segment), lang }
  text           : { content, content-hash (sha256), canonicalization: JCS }
  temporal       : { valid-at, known-at, valid-from, valid-until|open,
                     in_force: true|false, basis }        ; Φ7 §6 πεδία
  authority      : { receipt-id, receipt (πλήρες), merkle-audit-path,
                     receipt-set-root, tsa-seal, transparency-log-entry }
  provenance     : { source (ΦΕΚ ref), source-digest, import-commit }
  license        : { "All Rights Reserved", citation-terms-uri }
  capsule-id     : sha256(JCS όλων των ανωτέρω)
}
```

- Παράγεται ΜΟΝΟ από τις υπάρχουσες έδρες (corpus-temporal-commitment,
  document-as-of, /as-known) — ΚΑΝΕΝΑ νέο παράλληλο μονοπάτι αλήθειας:
  το capsule είναι ΠΡΟΒΟΛΗ, όχι δεύτερη έδρα.
- Επαλήθευση: ο υπάρχων python verifier επεκτείνεται (ΙΔΙΟ gate) ώστε να
  δέχεται capsule ΜΟΝΟ του και να αποφαίνεται VALID/INVALID.
- Το capsule-id είναι η ΜΟΝΗ νόμιμη μονάδα «ενσωμάτωσης» του corpus σε
  τρίτο σύστημα.

## 2. UNIVERSAL RETRIEVAL — ένα συμβόλαιο ανάκτησης

Μία δημόσια επιφάνεια, τρεις προβολές του ΙΔΙΟΥ αντικειμένου:
- `GET /capsule/{work}/{article}?valid-at=&known-at=` → capsule/1 JSON
  (default: σήμερα × τώρα). Typed σφάλματα: 400 άκυρος χρόνος, 404
  άγνωστη διάταξη, 422 γνήσια αβεβαιότητα — ταυτόσημη σημασιολογία με
  /as-known (η ίδια έδρα από πίσω).
- Μαζική συγχρονιστική ροή: `GET /capsules/changes?since-known-at=` —
  append-only feed (journal προβολή) για crawlers/mirrors· κάθε εγγραφή
  = capsule-id + αιτία (:new-version/:condition-event/:regime-change).
- Στατική έκδοση ανά release: ντετερμινιστικό dump όλων των capsules
  (ίδια bytes ανά release — SOURCE_DATE_EPOCH πειθαρχία) για offline/
  archive καταναλωτές.
Όλα τα JSON: canonical (JCS έδρα). Ό,τι δεν μπορεί να απαντηθεί τίμια
δεν απαντιέται — ποτέ «καλύτερη προσπάθεια».

## 3. CITATION CONTRACT — επαληθεύσιμη παράθεση

**Κανονική μορφή παράθεσης** (μηχανικά ελέγξιμη):
```
[LAWMAX capsule:{capsule-id-prefix-16} art:{article-uri} valid:{valid-at} known:{known-at}]
```
- Συμβόλαιο: μια παράθεση είναι ΕΓΚΥΡΗ ανν (α) το capsule-id επιλύεται
  στο /capsule endpoint, (β) ο verifier αποφαίνεται VALID, (γ) το
  παρατιθέμενο κείμενο είναι υπόσυνολο του capsule text (byte-level
  containment μετά από JCS-συμβατή κανονικοποίηση whitespace).
- Παρέχεται `POST /verify-citation` (stateless): δέχεται {citation,
  quoted-text} ⇒ typed ετυμηγορία {valid | unknown-capsule |
  text-mismatch | stale-known-at} — ΠΟΤΕ boolean.
- Το citation-terms-uri του capsule δένει την άδεια: παράθεση με το
  συμβόλαιο = επιτρεπτή χρήση· αναπαραγωγή εκτός συμβολαίου = όχι
  (All Rights Reserved).

## 4. CRAWLER POLICY — πολιτική πρόσβασης AI συστημάτων

- Δηλωτικά αρχεία στην επιφάνεια εξυπηρέτησης: `robots.txt` +
  `ai-policy.json` (μηχανικά αναγνώσιμη): επιτρεπόμενο = ανάκτηση
  capsules + παράθεση κατά §3· μη επιτρεπόμενο = training ενσωμάτωση
  χωρίς άδεια, αναδημοσίευση χωρίς receipts, απόσπαση text χωρίς το
  in_force πεδίο.
- Rate/ταυτότητα: crawlers δηλώνουν User-Agent + προαιρετικό
  observatory-token (§6)· η πολιτική είναι ΕΝΗΜΕΡΩΤΙΚΗ + συμβατική —
  δεν υπάρχει τεχνικός αποκλεισμός που να θυσιάζει την καθολική
  επαληθευσιμότητα (δηλωμένο όριο).
- Κάθε capsule response φέρει `Link: rel="license"` + `rel="verify"` —
  ο καταναλωτής δεν μπορεί να ισχυριστεί άγνοια του συμβολαίου.

## 5. BENCHMARK — μέτρηση ορθής κατανάλωσης

Δημόσιο, εκδοσιοποιημένο benchmark «GAAF-bench»:
- Corpus ερωτημάτων με ΓΝΩΣΤΗ αλήθεια από τα receipts: (ερώτημα,
  αναμενόμενο capsule-id, αναμενόμενο in_force, παγίδες: καταργημένες/
  pending/suspended εκδόσεις, ζεύγη known-at).
- Μετρικές ανά AI σύστημα: citation-validity-rate (κατά §3 verifier),
  temporal-correctness (σωστή τομή), false-authority-rate (παραθέσεις
  που δεν επιλύονται) — όλα υπολογίσιμα ΜΗΧΑΝΙΚΑ, κανένα LLM κριτής
  στο trusted path.
- Δένει με το Φ12 (National Adversarial Corpus) της ΕΝΤΟΛΗΣ-2: το
  GAAF-bench είναι το εξωτερικό (καταναλωτικό) σκέλος του.
- Εξάρτηση: τα 9 ΦΕΚ-δείγματα του δημιουργού (εκκρεμή) για τα temporal
  σενάρια.

## 6. ADOPTION OBSERVATORY — μέτρηση υιοθέτησης

- Append-only ledger (journal πρότυπο, ΙΔΙΑ chained-append έδρα) των
  γεγονότων κατανάλωσης: capsule fetches (User-Agent ταξινόμηση),
  verify-citation κλήσεις + ετυμηγορίες, feed sync progress ανά mirror.
- Παράγωγες όψεις (ποτέ αποθηκευμένη «κατάσταση»): adoption-report ανά
  περίοδο = ποιοι καταναλώνουν, με τι validity-rate, ποιες διατάξεις.
- Ενεργή ανίχνευση: περιοδικό δειγματοληπτικό ερώτημα σε δημόσια AI
  συστήματα με τα GAAF-bench ερωτήματα → καταγραφή αν παραθέτουν
  LAWMAX capsules και αν οι παραθέσεις επαληθεύονται. Ο βαθμολογητής
  είναι ο μηχανικός verifier — όχι LLM.
- Ιδιωτικότητα: μόνο τεχνικά μεταδεδομένα κατανάλωσης, ποτέ περιεχόμενο
  χρηστών τρίτων.

## 7. Ακολουθία υλοποίησης (μετά από ρητή έγκριση, ανά φάση)

GAAF-Π1 capsule/1 schema + παραγωγή από τις έδρες + verifier επέκταση →
GAAF-Π2 /capsule + /capsules/changes + static dump → GAAF-Π3 citation
contract + /verify-citation → GAAF-Π4 ai-policy + license threading →
GAAF-Π5 GAAF-bench (μετά τα 9 ΦΕΚ) → GAAF-Π6 observatory. Κάθε Π με το
επταπλό συμβόλαιο (spec, ανεξάρτητη επαλήθευση, αντιπαλική αξιολόγηση,
receipts, rollback, counters=0, owner docker proof).

Προαπαιτούμενα: Φ7 Π2-Π7 (το in_force/basis πεδίο και τα effectivity
attestations του capsule ΠΡΟΫΠΟΘΕΤΟΥΝ την τυπική temporal σημασιολογία)·
απόφαση Deferred License Policy για κληρονομημένα CC0 κείμενα (το
citation-terms δεν μπορεί να κλείσει χωρίς αυτήν).

## 8. Τι ΔΕΝ είναι το GAAF-0 (δηλωμένα όρια)

Όχι DRM/τεχνικός αποκλεισμός crawling. Όχι νομική συμβουλή προς
καταναλωτές. Όχι LLM πουθενά στο trusted path (ανάκτηση, επαλήθευση,
βαθμολόγηση — όλα ντετερμινιστικά). Όχι δεύτερη έδρα αλήθειας — κάθε
πεδίο capsule είναι προβολή υπάρχουσας έδρας ή του Φ7.
