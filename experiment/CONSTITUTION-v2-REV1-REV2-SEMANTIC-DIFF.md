# v2 REV1 → REV2 — Σημασιολογική διαφορά (DRAFT)

Το REV1 (`9d68e56a`) διατηρείται αμετάβλητο ως ιστορικό checkpoint. Το v1
παραμένει το ΜΟΝΟ σε ισχύ. Κάθε αλλαγή εδώ ΣΤΕΝΕΥΕΙ ή ΘΩΡΑΚΙΖΕΙ — καμία δεν
χαλαρώνει τον αντι-απλουστευτικό πυρήνα.

| # | REV1 | REV2 | Γιατί |
|---|---|---|---|
| 1 | precommit inputs διάσπαρτα («ΕΚΚΡΕΜΕΙ στη Φ2») | **c3 PRECOMMIT BARRIER**: 8 inputs σφραγίζονται ΠΡΙΝ από κάθε candidate· ο checker αρνείται ενεργοποίηση Φ2 | Ορισμός στόχου ΜΕΤΑ τα αποτελέσματα = προσαρμογή στόχου στα ευρήματα |
| 2 | ενιαία «Φ2» | **c4**: Φ2A ανοικτή ανακάλυψη → closure boundary → Φ2B/Φ3 πάνω σε ΑΜΕΤΑΒΛΗΤΟ Q_t· late candidate ⇒ epoch invalidation | Χωρίς όριο, η discovery θα μόλυνε το θεώρημα |
| 3 | «Q_t πεπερασμένο» ως δήλωση | **c5**: ΑΠΟΔΕΙΞΕΙΣ πεπερασμένου I_t και κάθε L_i· I_t καλύπτει topology/interactions/recovery/performance/TCB/evolution· ≡material ΑΠΟΦΑΣΙΣΙΜΗ + CONGRUENCE ως προς H/Ω/joins/implementability/blueprints | Χωρίς congruence, το quotient δεν ορίζεται καν — δύο ισοδύναμα profiles θα μπορούσαν να κριθούν διαφορετικά |
| 4 | άξονες «not materially worse» | **c6**: κάθε άξονας = αποδεδειγμένα ΜΕΤΑΒΑΤΙΚΗ preorder επί πεπερασμένων levels· materiality στη χαρτογράφηση, ΟΧΙ στη σχέση | Το threshold είναι μη μεταβατικό (a~b, b~c ⇏ a~c) — το Ω θα ήταν ασυνεπές |
| 4β | UNKNOWN μπλοκάρει «αν μπορεί να έχει capability εκτός W» | **c6**: κάθε q∈F? που θα μπορούσε να υπερέχει σε ΟΠΟΙΟΝΔΗΠΟΤΕ Ω-άξονα μπλοκάρει FINAL, και χωρίς νέο capability· κλείνει ΜΟΝΟ με PASS / ηχηρό FAIL / UB(q)⪯Ω W. Το admission (named contract+evidence+witness) κρατά τα υποθετικά ΕΚΤΟΣ Q_t | ΙΣΧΥΡΟΤΕΡΟ blocking· το φίλτρο μετακινείται στην είσοδο του Q_t, όχι στη σιωπή |
| 4γ | F+ ⊆ D_t | **F+ = {q ∈ Q_t \| H(q)=PASS}** — διαμέριση F+/F-/F? του Q_t | Το θεώρημα ποσοδεικτεί στο Q_t, άρα και η διαμέριση |
| 5 | «GREATEST ή NO WINNER» | **c7**: greatest ΜΕ πλήρη απόδειξη Ή PROVED-NO-GREATEST + ΠΛΗΡΕΣ frontier με join challenges ΚΑΙ blueprint ΑΝΑ μη κυριαρχούμενο στοιχείο· ρητή απαγόρευση τεχνητού νικητή | Αναγκαστικός «νικητής» σε antichain = ψευδής απόδειξη ⇒ πιθανό ΚΑΤΩΤΕΡΟ σύστημα |
| 6 | 8 topologies ως λίστα | **c9**: COMPOSITION GRAMMAR + COVERAGE THEOREM· incompatibility αποκλείει κάθε παραγωγή της grammar· blueprint → END-TO-END realization witness (συνδέσεις, dependencies, pinned toolchains, πόροι, migration, ΕΚΤΕΛΕΣΙΜΕΣ gates) | Απαρίθμηση ≠ πληρότητα· blueprint ≠ υλοποιησιμότητα |
| 7 | v1 απόλυτα «no duplicated authority / no facade / CL χωρίς subset» | **c10**: απαγορεύεται η ΑΣΥΝΤΟΝΙΣΤΗ αυθεντία — επιτρέπεται ρητή πολυ-αυθεντία με jurisdiction/quorum/adjudication· απαγορεύεται facade ανύπαρκτης δυνατότητας — επιτρέπεται αποδεδειγμένος adapter· επιτρέπεται verified kernel με checked refinement· contract 15 πεδίων | Τα απόλυτα θα ΑΠΕΚΛΕΙΑΝ ανώτερες θεσμικές αρχιτεκτονικές — ευθεία παραβίαση του s1 |
| 8 | M∈N⁴ «αυστηρά φθίνον» καθολικά | **c8**: M ΜΟΝΟ μετά το DAG freeze· pre-closure χωρίς αξίωση μονοτονίας· multiset/rank (Dershowitz-Manna) ως δηλωμένη εναλλακτική | Η discovery ΑΥΞΑΝΕΙ profiles/obligations — το καθολικό «φθίνον» ήταν ψευδές |
| 9 | AS1-AS10 ως ονόματα | **c10b**: ΑΥΤΟΥΣΙΑ bytes από το v1 με hash-bound πηγή + JSON pointers + PRECEDENCE: σε σύγκρουση υπερισχύουν οι AS | Ονόματα δεν δεσμεύουν· bytes δεσμεύουν |
| 9β | «DRAFT→σφράγιση» ασαφές | **c11**: το αρχείο ΔΕΝ αλλάζει ποτέ bytes· ratification = ΧΩΡΙΣΤΟ attestation δεσμεύον v1+v2+amendment+epoch+checker+commit/tree+έγκριση | Αλλαγή DRAFT→IN_FORCE αλλάζει hash ⇒ ακυρώνει amendment/epoch |
| 10 | checker: ύπαρξη/σχήμα | **c12 + υλοποίηση REV2**: commit-bound snapshot, hash recompute, απόρριψη κενών/πλαστών/dummy, lifecycle modes draft-lint/preflight/active, activation gates, self-binding στο epoch | Ο linter δεν φρουρεί οροφή |

## Επαληθευμένο τώρα
- draft-lint: **MET 12 · NOT-YET 8 · UNMET 0**
- preflight: **ΑΡΝΕΙΤΑΙ** (βρώμικο worktree ΚΑΙ 8/8 inputs PENDING-SEAL) — και τα δύο ΟΡΘΩΣ
