# [0121] — MERKLE-SINGLE-TRUTH · ΑΠΑΝΤΗΣΗ ΣΤΑ 7 ΣΩΡΕΥΤΙΚΑ ΚΡΙΤΗΡΙΑ ΤΟΥ ΕΠΙΤΗΡΗΤΗ
**Claude · 2026-07-31 · branch `claude/lawmax-integrity-ratchet-v1` · πάνω στο `7d2f4486` [0120+]**

Ο επιτηρητής όρισε 7 σωρευτικά κριτήρια πριν από κάθε χαρακτηρισμό «ανώτατο»,
και απαγόρευσε νέες heuristic σαρώσεις ως «απόδειξη». Συμμόρφωση: **ΚΑΝΕΝΑΣ
χαρακτηρισμός «ανώτατο» δεν εκφέρεται** — παρακάτω η κατάσταση ΚΑΘΕ κριτηρίου
με ακριβείς εντολές, μεταλλάξεις, αποτελέσματα και όρια. Καμία νέα κειμενική
σάρωση δεν προστέθηκε· μία κανονιστική μηχανοπαραγόμενη προδιαγραφή (profile ⇒
generator ⇒ docs+vectors), όλα τα υπόλοιπα ρητά μη κανονιστικά.

Διόρθωση πραγματικότητας: το «branch ακόμη στο `85cf8350`» ίσχυε τη στιγμή της
σύνταξης — έκτοτε είναι pushed τα `5af60978` [0120] και `7d2f4486` [0120+]
(επιβεβαιωμένο στο remote), και το παρόν commit προστίθεται πάνω τους.

---

## Κριτήριο 1 — oracle εκτός production generator/TCB, άλλη μηχανική, παγωμένα εξωτερικά vectors

**ΜΕΡΙΚΩΣ: η εκτός-TCB αυθεντία υπάρχει, αλλά ΔΕΝ είναι ο εσωτερικός oracle.**
- Η in-image διασταύρωση (ροϊκός MTH + μεταγραφές PATH/SUBPROOF, 156 τιμές)
  ΠΑΡΑΜΕΝΕΙ ίδιου συγγραφέα, ίδιας εικόνας, ίδιας hash βιβλιοθήκης — ΔΕΝ
  προβάλλεται ως ανεξάρτητη αυθεντία· είναι κάλυψη γενεσιουργών σφαλμάτων.
- Η ΕΚΤΟΣ-TCB αυθεντία είναι τα `verify-merkle.py` (CPython/hashlib) και
  `verify-merkle.mjs` (Node/OpenSSL): άλλη γλώσσα, άλλη hash υλοποίηση, άλλη
  διεργασία, κανένα κοινό runtime με τη Lisp εικόνα — και με το παρόν commit
  δεν ΕΠΑΛΗΘΕΥΟΥΝ μόνο: **ΠΑΡΑΓΟΥΝ** (κριτήριο 2).
- **Παγωμένα ΕΞΩΤΕΡΙΚΑ vectors: ΔΕΝ ΥΠΑΡΧΟΥΝ — BLOCKED.** Η πολιτική δικτύου
  απορρίπτει (403) rfc-editor.org/κ.λπ.· ούτε το RFC 9162 ούτε το RFC 6962
  δημοσιεύουν πλήρη test vectors στο ίδιο το κείμενο ώστε να μεταγραφούν από
  μνήμη με ασφάλεια. Άγκυρα που ΥΠΑΡΧΟΥΝ: FIPS 180-4 KAT SHA-256("abc") +
  RFC 9162 MTH({}) = SHA-256(""). Το κριτήριο κλείνει ΜΟΝΟ με εισαγωγή
  εξωτερικού υλικού από τον δημιουργό (π.χ. certificate-transparency-go
  testdata ή C2SP tlog vectors) — μία ενέργεια, μόνιμο κέρδος.

## Κριτήριο 2 — ανεξάρτητη παραγωγή/επαλήθευση paths ΚΑΙ proofs — ΚΛΕΙΣΤΟ

Και οι ΔΥΟ εκτός-TCB υλοποιήσεις απέκτησαν **ΓΕΝΝΗΤΡΙΕΣ** `PATH(m, D[n])`
(RFC 9162 §2.1.3.1) και `PROOF(m, D[n])` (§2.1.4.1) και συγκρίνουν
ΣΤΟΙΧΕΙΟ-ΠΡΟΣ-ΣΤΟΙΧΕΙΟ (side+hash / hash λίστα) με τα committed vectors —
επιπλέον της fold-επαλήθευσης που ήδη είχαν:
```
python3 deployment/verify/verify-merkle.py   ⇒ 134 ok, 0 FAIL  (ήταν 111)
node   deployment/verify/verify-merkle.mjs   ⇒ 134 ok, 0 FAIL  (ήταν 111)
```
(+15 PATH-gen, +8 PROOF-gen ανά γλώσσα.) Λάθος-αλλά-επαληθεύσιμο path παύει να
είναι δυνατό να περάσει: απαιτείται η ΚΑΝΟΝΙΚΗ μορφή του RFC, όχι απλώς μορφή
που διπλώνει στη σωστή ρίζα.

## Κριτήριο 3 — mutation witness για ΚΑΘΕ κανονιστικό πεδίο — ΚΛΕΙΣΤΟ

Νέος μάρτυρας `profile-field-drift` στο harness: ΓΙΑ ΚΑΘΕ κανονιστικό πεδίο,
το profile μεταλλάσσεται ΠΡΑΓΜΑΤΙΚΑ σε αντίγραφο του repo και το
`gen-merkle-truth --check` ΠΡΕΠΕΙ να κοκκινίσει με το αναμενόμενο μήνυμα
(άσχετο σκάσιμο ΔΕΝ μετρά). Σάρωση 12 πεδίων: profile-id, normative-reference,
hash-representation, tree-leaf-rule, tree-sizes, leaf-inputs (hex),
inclusion-cases, consistency-cases, differential-range, rules statement,
byte-encoding statement, publication-policy statement — συν τους 3 υπάρχοντες
στοχευμένους (leaf-prefix, node-prefix, hash-algorithm) = **15 profile
mutations**. Η αρχή γράφτηκε ΜΕΣΑ στο profile: «αδρανές πεδίο δεν επιτρέπεται
να υπάρχει σε αυτό το αρχείο». Αποτελέσματα στον πίνακα §Π.

**Εύρημα του ίδιου του sweep (καταγράφεται γιατί δείχνει την αυστηρότητά του):**
στο πρώτο πέρασμα ο μάρτυρας `hash-representation` καταγράφηκε ΕΠΙΒΙΩΣΑΣ — ο
generator ΣΚΑΕΙ, αλλά από την άγκυρα δημοσιευμένων σταθερών (το FIPS 180-4 KAT
τρέχει ΠΡΙΝ τη σύγκριση έδρας/profile), όχι από το μήνυμα που δήλωνε ο
μάρτυρας. Ο κανόνας «φόνος με ΛΑΘΟΣ αιτία δεν μετράει» λειτούργησε ακριβώς όπως
σχεδιάστηκε· διορθώθηκε η ΠΡΟΣΔΟΚΙΑ του μάρτυρα στο πραγματικό (και ισχυρότερο —
εξωτερική σταθερά) σημείο θανάτου, όχι ο μηχανισμός.

## Κριτήριο 4 — census που δεν μικραίνει με verifier/fixture — ΚΛΕΙΣΤΟ ([0120])

Committed `docker/verifier-census.txt` (η ΜΙΑ έδρα, fail-closed στον verifier,
loop-πηγή του Dockerfile), κλειστό σχήμα JSON, fixture με ΔΙΚΟ ΤΟΥ sandbox
μητρώο + μετάλλαξη αφαίρεσης ΚΑΘΕ κλειδιού (17/17), και το πραγματικό census
καρφωμένο σε ΤΡΙΤΗ θέση (merkle-single-truth-test §Ε3). Συρρίκνωση απαιτεί
ταυτόχρονο, ΟΡΑΤΟ diff σε committed αρχείο δεδομένων + αλλαγή σε άλλη σουίτα.

## Κριτήριο 5 — πραγματικές source mutations στις πύλες ΚΑΙ ΤΩΝ ΤΡΙΩΝ publishers — ΚΛΕΙΣΤΟ

Το `publish-empty-corpus` ήταν το τελευταίο με χειρόγραφη eval-redefinition
(τρίτο σώμα γραμμένο στο probe — ΟΧΙ μετάλλαξη του πηγαίου). Αναβαθμίστηκε στο
πρότυπο census/tlog: το ΙΔΙΟ το `source/proof-carrying.lisp` μεταλλάσσεται
κειμενικά (`(when (null provisions)` → `(when nil` — η πύλη νεκρώνεται) και το
μεταλλαγμένο αντίγραφο φορτώνεται πάνω στην εικόνα. Και οι ΤΡΕΙΣ publishers
πλέον: GUARDED=REJECTED / UNGUARDED(source-mutant)=ACCEPTED ⇒ η ΓΡΑΜΜΗ του
πηγαίου αποδεικνύεται φέρουσα:
- `proof-carrying.lisp` γρ. 206-207 (empty-corpus-publication)
- `artifact-census.lisp` γρ. ~92 (κενό σύνολο άρθρων)
- `transparency-log.lisp` γρ. 130-134 (invalid release root)

## Κριτήριο 6 — οι αδέσμευτοι verifiers δεσμεύονται χωρίς εξαίρεση — ΚΛΕΙΣΤΟ ([0120])

Και τα 14 formula-bearing αδέσμευτα αρχεία (μαζί kernel-verify.lisp,
verify-authority-bundle.py, verify-release.py) ονομάζουν πλέον το
`lawmax-merkle-sha256-v1`. Ο κανόνας Ε2 (μη κανονιστικό tripwire — ΟΧΙ
«απόδειξη») το επιτηρεί με 0 εξαιρέσεις αρχείων. ΚΑΜΙΑ νέα σάρωση δεν
προστέθηκε σε αυτόν τον γύρο.

## Κριτήριο 7 — πλήρες Docker + Actions στο τελικό commit — BLOCKED — NOT EXECUTED

Επαληθευμένο με το API ([0120+]): `workflow_dispatch` ⇒ **403 Resource not
accessible by integration** (το App token δεν έχει `actions:write`)· push
`5af60978`/`7d2f4486` ⇒ **0 runs** (τα push του integration δεν πυροδοτούν
Actions)· Docker daemon τοπικά ανύπαρκτος. Η εκκίνηση είναι ΑΔΥΝΑΤΗ από τη
συνεδρία. Κλείνει ΜΟΝΟ από δημιουργό: (α) Actions → Run workflow στον κλάδο, ή
(β) PR του κλάδου προς main (τρέχουν ΟΛΕΣ οι πύλες + πλήρες Docker build), ή
(γ) push με credentials δημιουργού. Μέχρι τότε: οι αριθμοί του §Π είναι ΤΟΠΙΚΑ
γεγονότα, τίποτα δεν αναφέρεται ως «πράσινο CI», κανένα «ανώτατο».

---

## §Π · ΑΠΟΔΕΙΞΗ ΜΕ ΑΡΙΘΜΟΥΣ (τοπική εκτέλεση, τελικό δέντρο αυτού του commit)

| Εντολή | Αποτέλεσμα |
|---|---|
| `sbcl --script scripts/gen-merkle-truth.lisp --check` | OK · 156 διασταυρώσεις · σταθερές ≡ profile |
| `python3 deployment/verify/verify-merkle.py` | **134 ok, 0 FAIL** (+PATH/PROOF gen) |
| `node deployment/verify/verify-merkle.mjs` | **134 ok, 0 FAIL** (+PATH/PROOF gen) |
| `sbcl … tests/merkle-single-truth-test.lisp` | **48 passed, 0 failed** |
| `bash scripts/merkle-mutation-witness.sh` | **39/39 ΣΚΟΤΩΜΕΝΟΙ, 0 ΕΠΙΒΙΩΣΑΝ, 0 BLOCKED · μητρώο ≡ εφαρμοσμένοι (14 ids)** — 7 αλγοριθμικοί ×3 γλώσσες + 15 profile mutations + 3 publisher source-mutations |
| `python3 docker/verify-proof-manifest-test.py` | **17 passed, 0 failed** |

## §Ο · ΟΡΙΑ (ρητά, χωρίς χαρακτηρισμό «ανώτατο»)

1. In-image διασταύρωση = κάλυψη, ΟΧΙ ανεξάρτητη αυθεντία (ίδιος συγγραφέας/TCB).
2. Εξωτερικά παγωμένα vectors: ΑΠΟΝΤΑ — απαιτούν ενέργεια δημιουργού (δίκτυο).
3. Ε/Ε2 tripwires: μη κανονιστικά· η κανονιστική επιφάνεια είναι profile ⇒
   generator ⇒ docs+vectors, byte-checked.
4. CI/Docker: BLOCKED από τη συνεδρία — τρεις οδοί δημιουργού παραπάνω.
5. Ετικέτες `rfc6962-*` σε ιστορικά εκπεμπόμενα census/tlog JSON: versioned-format
   φάση, όχι silent rename ([0120] §8.3).
