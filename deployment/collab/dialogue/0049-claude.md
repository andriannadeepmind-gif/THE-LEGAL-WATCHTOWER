# [0049] Claude (Χειρουργός Πυρήνα) — P1b PLAN: Per-Article Surface Completion — PLANNING ONLY

**Ημερομηνία:** 2026-07-10 · **Κανένας κώδικας.** Ανοίγει ΜΟΝΟ με «εγκρίνω P1b».

## Σκοπός
Η per-article δημοσιευμένη επιφάνεια (.jsonld/.html/.ttl/.txt/.hash ανά άρθρο)
να παράγεται ΟΡΘΗ και ΠΛΗΡΗΣ απευθείας από το pipeline — να συνταξιοδοτηθεί
η τελευταία B/C-συμφιλίωση του [0045]/[0047] (η @id↔όνομα τοποθέτηση των 144
lettered .jsonld) και το εύρημα ονοματοδοσίας του [0044].

## 1. Failing proof στο τρέχον main (7b611781)
Το deploy εκπέμπει lettered per-article αρχεία με τον ΕΣΩΤΕΡΙΚΟ συνθετικό
αριθμό: `article-5001Α.*` αντί του κανονικού `article-005Α.*` (E2E απόδειξη
στο [0044]: fresh pipeline run, ενώ το ΠΕΡΙΕΧΟΜΕΝΟ είναι σωστό — @id
`/art/5Α`, identifier `art-005Α`).

## 2. Έδρες
- **Ρίζα:** `article-file-id` (systems/orchestrator-model/article.lisp:190)
  περνά το `article-number` (συνθετικό base*1000+index από json-adapter.lisp:39-52)
  στο `pad-article-id` — το filename κληρονομεί τον συνθετικό. ΔΙΟΡΘΩΣΗ ΣΤΗΝ
  ΕΔΡΑ: όταν υπάρχει label, η αριθμητική βάση του filename προκύπτει από το
  LABEL (η μία πηγή αλήθειας ταυτότητας), όχι από τον συνθετικό αριθμό.
  Καταναλωτές: filesystem.lisp:123 (deploy filenames) + fingerprint (ήδη
  συνεπές με padded κανονικά ονόματα).
- **[0047]-Β4:** μία εξαγόμενη έδρα provenance-checked-json-context
  (χρησιμοποιείται από run-json-mode ΚΑΙ cut-release — τέλος η διπλή
  ενορχήστρωση).
- **[0047]-Β7:** ΜΙΑ κανονική μορφή root string στην έδρα merkle
  (καταργείται η διπλή μορφή sha256:/γυμνό hex· το %root->release-id παύει
  να «συγχωρεί» δύο σχήματα).

## 3. Αναγέννηση επιφανειών (η συμφιλίωση πεθαίνει)
Μετά το fix: πλήρες `--run-pipeline` ανά corpus στο ΚΑΝΟΝΙΚΟ output (πλέον
ακίνδυνο — το clean διατηρεί το releases/), ώστε ΟΛΑ τα tracked per-article
artifacts να είναι φρέσκα pipeline-παραγόμενα με κανονικά ονόματα. Συνέπειες
που ΠΡΕΠΕΙ να αποφασιστούν ρητά:
- (i) Τα tracked per-article .html/.ttl/.txt/.hash θα αλλάξουν μαζικά
  (φέρουν ήδη stale μορφές — ίδια κατηγορία με τα P0/P1 stale artifacts).
  Πλήρες diff-audit ανά κλάση, όπως στο P0/P1.
- (ii) Τα emitted goldens (article-*.hash βάση) θα εμφανίσουν DRIFT ⇒
  απαιτείται συνειδητό GOLDEN_WRITE=1 επανακλείδωμα + commit (η πύλη δεν
  γράφει μόνη της — απόφαση δημιουργού, όπως ορίζει το golden συμβόλαιο).
- (iii) Θα προστεθούν τα per-article αρχεία των lettered που έλειπαν από
  δίσκο σε μορφές πλην .jsonld (πληρότητα επιφάνειας).

## 4. Πύλη filename≡identity
Νέος έλεγχος στο gated στρώμα (επέκταση της λογικής corpus-identity ⑦ στο
deploy): για ΚΑΘΕ εκπεμπόμενο per-article αρχείο, το όνομα ταυτίζεται με το
κανονικό pad του label — ένα μελλοντικό ναυάγιο ονοματοδοσίας κοκκινίζει το
build, δεν φτάνει ποτέ στο repo.

## 5. Tests/Proof/Rollback
- Νέος gated έλεγχος + επέκταση release/corpus-identity tests όπου χρειάζεται.
- ΕΣΩΤΕΡΙΚΟΣ ΑΝΤΙΠΑΛΟΣ (νέο πρωτόκολλο): δύο ανεξάρτητοι κριτές πάνω στην
  υλοποίηση ΠΡΙΝ το proof — ευρήματα κλείνουν στην έδρα ή δηλώνονται.
- Proof: 80+ standalone loop, ολομέλεια 24, verify-truth, release-gate,
  diff-audit αναγέννησης, goldens ξανακλειδωμένα με αριθμούς, owner docker.
- Rollback: απομονωμένα commits (fix → tests → artifacts → goldens), όλα
  revert-άσιμα· releases ανέγγιχτα εκ κατασκευής.

## 6. Εκτός P1b (κλειστά)
P1.5 release↔article binding · P2 canonical/telemetry · P3 temporal currency ·
FF4 · Ω+ · license policy · verify-kit-in-identity (v2 απόφαση [0047]) ·
πλήρης TSR crypto-verify (P4+).

*Αναμένει: «εγκρίνω P1b» + αποφάσεις (i)/(ii)/(iii) του §3.*
