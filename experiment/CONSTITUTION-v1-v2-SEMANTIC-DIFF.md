# Ω-CEILING CONSTITUTION — Σημασιολογική διαφορά v1 → v2 (DRAFT)

**Το v1 (`5b3ab5bf…29be6`) παραμένει byte-identical και ΣΕ ΙΣΧΥ μέχρι ρητή
επικύρωση του v2.** Ο πυρήνας κατά της απλούστευσης διατηρείται και
ενισχύεται· καμία διάταξη δεν χαλαρώνει.

## Ανά τμήμα του v1

| v1 | Τύχη στο v2 | Ουσία |
|---|---|---|
| s1 supreme purpose | **c1 — ΔΙΑΤΗΡΕΙΤΑΙ** | αμετάβλητο στην ουσία |
| s2 sealed definitions | **διασπάται** | το capability contract και το presence rule μένουν ΝΟΜΟΣ (c10)· τα t0/D_t/U_t/B±/H_i/thresholds γίνονται ΔΕΔΟΜΕΝΑ epoch |
| s3 trivalent feasibility | **c5 — ΕΝΙΣΧΥΕΤΑΙ** | H() ορίζεται με iff· F?≡F_unknown ρητά· το blocking απαιτεί ADMITTED challenger (όνομα+evidence+witness)· branch closure ΜΟΝΟ με UB(branch)⪯Ω W ή refutation certificate. Το «υποθετικό UNKNOWN μπλοκάρει για πάντα» φεύγει — ΟΧΙ χαλαρώνοντας, αλλά απαιτώντας το UNKNOWN να γίνει ΣΥΓΚΕΚΡΙΜΕΝΟ |
| s4 hard gates H_1..H_13 | **→ EPOCH-1** | οι πύλες είναι δεδομένα του epoch· ο ΝΟΜΟΣ κρατά μόνο τη σχέση H(A)=PASS⟺∀H_i PASS |
| s4 proof floor | **c1/c5 — ΔΙΑΤΗΡΕΙΤΑΙ** | |
| s5 baseline B± | **→ EPOCH-1** | δείκτες προς dossiers/ledgers· το T1 μένει ως υποχρέωση AS1 |
| s6 ⪯K | **c4 — ΑΝΤΙΚΑΘΙΣΤΑΤΑΙ από Ω** | το K-only συνέκρινε ΜΟΝΟ capabilities· το Ω απαιτεί ΕΠΙΠΛΕΟΝ μη-χειροτέρευση σε 8 σφραγισμένους άξονες υπό ίδιο workload/uncertainty. ΙΣΧΥΡΟΤΕΡΗ σχέση ⇒ ΔΥΣΚΟΛΟΤΕΡΗ νίκη ⇒ αντι-απλουστευτικά ΑΥΣΤΗΡΟΤΕΡΟ |
| s7 winner GREATEST | **c7 — ΑΚΡΙΒΕΣΤΕΡΟ** | greatest = μοναδική equivalence CLASS [W], όχι υποχρεωτικά μοναδική υλοποίηση |
| s8 join synthesis | **c7 — ΕΝΙΣΧΥΕΤΑΙ** | από «κατασκεύασε join» σε ΟΚΤΩ ονομασμένες topologies· incompatibility certificate πρέπει να τις αποκλείει ΟΛΕΣ |
| s9 secondary axes | **c4 — ΑΠΟΡΡΟΦΩΝΤΑΙ στο Ω** | οι άξονες δεν είναι πλέον «δευτερεύοντες μετά τη νίκη»: είναι ΜΕΡΟΣ της σχέσης κυριαρχίας. Τα excluded (κόστος/χρόνος/effort) μένουν εκτός (c8) |
| s10 no prover-driven | **c10 — ΔΙΑΤΗΡΕΙΤΑΙ ΑΥΤΟΛΕΞΕΙ** | |
| s11 AS1-AS10 + counter-design | **c10 — ΔΙΑΤΗΡΟΥΝΤΑΙ** | |
| s12 forbidden termination | **c6 — ΔΙΑΤΗΡΕΙΤΑΙ + ΠΡΟΣΤΙΘΕΤΑΙ θετικό κριτήριο** | το v1 έλεγε μόνο πότε ΔΕΝ τερματίζεις· το v2 ορίζει πότε ΜΠΟΡΕΙΣ: M=(0,0,0,0)+reproduced root |
| s13 claim limits | **c7 — ΜΕΤΟΝΟΜΑΖΟΝΤΑΙ ΑΚΡΙΒΕΣΤΕΡΑ** | GREATEST-FEASIBLE…AT-t0 → PROVED-GREATEST-IN-SEALED-Q_t· προστίθεται PROVED-NO-GREATEST+COMPLETE-PARETO-FRONTIER· η invalidation γίνεται monotonic epoch n+1 |
| s14 admission corrections | **→ STATE LEDGERS** | λειτουργική κατάσταση, όχι δίκαιο. ΟΙ ΥΠΟΧΡΕΩΣΕΙΣ ΔΕΝ ΧΑΝΟΝΤΑΙ — μεταφέρονται ως obligations |
| s15 authorization | **→ STATE** | phase status δεν είναι σύνταγμα |
| frozen corpus (τελευταίες γραμμές) | **→ EPOCH-1** | το v1 ενσωμάτωνε την ΞΕΠΕΡΑΣΜΕΝΗ content-only ρίζα ΩΣ ΝΟΜΟ — αυτό ακριβώς που η διάσπαση διορθώνει |

## Νέα ύλη χωρίς προηγούμενο στο v1

- **c3**: O_t/Q_t, πεπερασμένο lattice, DOMAIN-CLOSURE-CERTIFICATE, epoch invalidation
- **c6**: search DAG, 3 leaf kinds, μέτρο M∈N⁴
- **c8**: IMPLEMENTABLE_AT_t0 ως constructive predicate· inert IR ως τελικό αντικείμενο
- **c9**: ρητή Common Lisp authority (ήταν διάσπαρτη σε s4/s10 + εντολές δημιουργού)
- **c11**: hash-bound amendment chain + evidence transfer
- **c12**: checker v2

## Τι ΔΕΝ αλλάζει πουθενά

Καμία από τις 10 AS υποχρεώσεις. Κανένα forbidden termination ground. Κανένα
excluded criterion (κόστος/χρόνος/effort/απλότητα). Το «FAIL μόνο με
certificate». Το «η δύσκολη απόδειξη δεν χαρίζει νίκη σε μικρότερο σύστημα».
Η υποταγή του prover στην αρχιτεκτονική.
