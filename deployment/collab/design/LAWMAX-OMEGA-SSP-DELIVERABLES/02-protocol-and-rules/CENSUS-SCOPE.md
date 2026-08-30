# CENSUS SCOPE — Στάδιο B (FOC-02, εντολή δημιουργού 2026-08-28)

## Εντολή
«Τα output δεν μας ενδιαφέρουν — είναι αυτό που παράγει το σύστημα. Στόχευσε στο σύστημα μόνο.»

## ΕΝΤΟΣ census (πλήρης σημασιολογική απογραφή, αρχείο-προς-αρχείο)
- `source/` (133) — πυρήνας
- `systems/` (175) — τα 12 ASDF συστήματα
- `authority-v2/` (63) — integrity TCB (kernel, capability, capture, genesis, proofs, log, schema)
- `tests/` (152)
- `determinism/` (52)
- `scripts/`, `tools/`, `docker/` (16), `configs/` (9), `deps/`
- Κορυφαία: 16× `*.asd`, `build.lisp`, `entrypoint.lisp`, `Dockerfile*`, `docker-compose*.yml`, `.dockerignore`, `.gitattributes`, `.gitignore`, `package.json`
- `.github/workflows/` (CI — μαζί με το γνωστό startup-failure του provenance.yml)
- Συμβόλαια/τεκμηρίωση συστήματος: `SEMANTIC-CONTRACT.md`, `DEPENDENCY-CONTRACT.md`, `PROVENANCE.yaml`, `SYSTEM-HIERARCHY.txt`, `README.md`, `CLAUDE.md`, `CHANGELOG.md`, `LICENSE`, `docs/` (16), `MANUAL-STEPS-HERMETIC.md`, `DEPLOY-PRODUCTION.md`, `RUN-DOCKER.md`
- `deployment/verify/` + `deployment/self/` (λειτουργικά μέρη του συστήματος ελέγχου)
- `keys/`, `state/`, `candidates/`, `releases/`, `examples/`, `evidence/` (μικρά — ταξινόμηση ρόλου έδρας)

## ΚΛΑΣΕΙΣ (ταξινόμηση σε επίπεδο κλάσης/βιβλιοθήκης, ΟΧΙ αρχείο-προς-αρχείο)
- `third-party/` (3307) — ανά βιβλιοθήκη (60 libs): όνομα, έκδοση, ρόλος, ποιο σύστημα την απαιτεί (διασταύρωση με deps.lock)
- `input/` (990) — corpus δεδομένων εισόδου: κλάσεις πηγών, όχι per-file
- `deployment/collab/` (dialogue/ιστορικό) — governance record: καταλογογράφηση, όχι ανάλυση

## ΕΚΤΟΣ (ρητή απόφαση scope δημιουργού — ΔΕΝ απογράφονται)
- `output/` (~29.200) και `output_run1/` (~700) — παράγωγα artifacts. Η ορθότητά τους είναι υπόθεση των γεννητόρων/gates τους, όχι του census.

## Τίμια διατύπωση του ισχυρισμού FOC-02
«0 ανεξήγητα» ισχύει για το ΣΥΣΤΗΜΑ όπως ορίζεται παραπάνω (~2.100 αρχεία πλήρους απογραφής + 2 ζώνες κλάσεων). Η εξαίρεση των output* είναι καταγεγραμμένη απόφαση scope του δημιουργού, όχι σιωπηλή παράλειψη.

## Παραδοτέο Σταδίου B — ΜΕΛΕΤΗ ΒΑΘΟΥΣ (εντολή δημιουργού 2026-08-28, 2η)
«Όλα τα άλλα: μελέτη σε βάθος, όχι δείγματα κώδικα. Να βρεθεί το ανώτατο δυνατό και πώς θα το φτάσουμε — refactoring, αλλαγές κώδικα, αλλαγές στο γράψιμο της Common Lisp, οτιδήποτε υπάρχει ως ανώτατο ιεραρχικά, λειτουργικά, δυναμικά.»

Κανόνας ανάγνωσης: ΚΑΘΕ αρχείο του συστήματος διαβάζεται ΟΛΟΚΛΗΡΟ (no sampling). Ανά αρχείο/έδρα καταγράφονται:
1. **Ταυτότητα**: διαδρομή · ρόλος · σύστημα-ιδιοκτήτης · είδος έδρας (gate/writer/store/proof/test/adapter/config) · εξαρτήσεις · αξονική αντιστοίχιση (AX-01..22) · κατάσταση εγγύησης.
2. **Ανώτατη μορφή** σε τρία στρώματα:
   - *Ιεραρχικά/αρχιτεκτονικά*: σωστή έδρα; μία έδρα ανά έννοια; σωστό στρώμα (trusted/untrusted); τι θα ήταν το ταβάνι της έδρας.
   - *Λειτουργικά/αλγοριθμικά*: ορθότητα, πληρότητα, fail-closed συμπεριφορά, ντετερμινισμός, πολυπλοκότητα — και το ανώτατο εφικτό εδώ.
   - *Common Lisp craftsmanship*: πακέτα/exports, CLOS/MOP χρήση (generic functions, :around barriers, metaclasses όπου αξίζει), condition system (typed conditions + restarts αντί για ad-hoc errors· ΚΑΝΕΝΑ fail-open handler), macro-DSLs για δηλωτικότητα με απόδειξη υγιεινής, `declaim`/`ftype`/`optimize` πειθαρχία, purity των αποφασιστικών συναρτήσεων (no clock/RNG/IO), immutability, tail-discipline, FiveAM δομή στα tests. Το ανώτατο ιδίωμα, όχι το βολικό.
3. **Ο δρόμος**: συγκεκριμένη αλλαγή (REFACTOR/REWRITE/MOVE/SPLIT/DELETE/DECLARE) που πάει την έδρα στην ανώτατη μορφή, με σειρά εξάρτησης — τροφοδοτεί απευθείας τον χάρτη μετάβασης (Στάδιο E).

Συνολικά: πίνακας όλων των εδρών + δείκτης ανά σύστημα + πλήρης κατάλογος writers/gates/stores + ιεράρχηση χρεών κατά κρισιμότητα (P0 φέρουσες, P1 λειτουργικές, P2 ιδιωματικές).
