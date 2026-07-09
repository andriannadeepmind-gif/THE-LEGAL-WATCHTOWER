# [0044] Claude (Χειρουργός Πυρήνα) — P1 Semantic Validity: ΥΛΟΠΟΙΗΣΗ (A/C/D)

**Ημερομηνία:** 2026-07-09 · **Έγκριση:** [0043] plan + αποφάσεις (i)/(ii) δημιουργού.

## 1. Τι έγινε (3 commits στο designated branch)

- `49645ae9` — Έδρες + test: **A** render-canonical-jsonld → ΕΝΑ document
  `{@context, @graph:[Org, Legislation]}`· **C1** *common-prefixes* επίπεδη
  λίστα (τέλος τα `(@prefix …)` και στα 8 είδη TTL)· **C2** 56× `\\\"`→`\"`
  στο build-release-manifest· **D** jonathan `:from :plist` → manifest.jsonld
  top-level object· ΝΕΟ gated `semantic-validity-test` + Dockerfile
  (standalone loop + python3-rdflib σκληροί μάρτυρες στο verifier-conformance).
- `06deb10b` — offline rdflib μάρτυρας (τοπικό `@vocab` αντί remote context).
- `19739a10` — αναγέννηση **4.694** tracked standalone `.jsonld` μέσω του
  παραγωγικού pipeline (χειρουργική αντιγραφή μόνο σε ήδη-tracked ονόματα).

## 2. Audit αναγέννησης (πλήρες, καμία εξαίρεση)

4.694/4.694: ΜΟΝΟ αλλαγή container· **0 @id μετακινήθηκαν**· Organization
κόμβος αμετάβλητος παντού· lettered @id (…/art/5Α κ.λπ.) άθικτα· 4 αρχεία με
αλλαγή `sha256` μόνο (τα 4 διορθωμένα κείμενα του P0 audit). Εξωτερικά:
json.tool 4.694/4.694 ΕΓΚΥΡΑ· rdflib Turtle/JSON-LD πράσινα.

## 3. Διορθώσεις εντιμότητας προς [0043]

1. Το §3 έλεγε «4.550 tracked + 144 λείπουν». **Λάθος μου**: τα 144 lettered
   `.jsonld` ΕΙΝΑΙ tracked — το `git ls-files` εμφανίζει μη-ASCII paths quoted
   και το φίλτρο μου τα έχανε. Αναγεννήθηκαν κι αυτά (ίδιο εγκεκριμένο σύνολο
   «existing tracked»· η απόφαση (i) αφορούσε ΝΕΑ αρχεία — κανένα δεν προστέθηκε).
2. **Εύρημα για P1b:** η έδρα ονοματοδοσίας του deploy γράφει τα lettered
   per-article αρχεία με τον εσωτερικό συνθετικό αριθμό (`article-5001Α` αντί
   `article-005Α`) — το περιεχόμενο ΣΩΣΤΟ (@id `/art/5Α`, identifier
   `art-005Α`), μόνο το filename πάσχει. Η τοποθέτηση στα κανονικά tracked
   ονόματα έγινε με ντετερμινιστική αντιστοίχιση @id↔όνομα + έλεγχο ανά αρχείο.

## 4. Νέα releases (απόφαση (ii)): ΜΠΛΟΚΑΡΙΣΜΕΝΑ από το περιβάλλον

Οι TSAs (freetsa 000/403, digicert 403) φράσσονται από τον proxy του
περιβάλλοντος εκτέλεσης, και η πύλη πληρότητας του release απαιτεί
`temporal-proof/timestamp.tsr` ΑΚΟΜΗ και σε dev-mode. Δεν χαλάρωσα την πύλη
(εκτός εγκεκριμένων ορίων — και σωστά: proof-bearing artifact χωρίς temporal
proof δεν πρέπει να περνά σιωπηλά). **Τα 6 παλιά immutable releases
(2025-01-01T00:00:00Z) ΑΝΕΓΓΙΧΤΑ** — 0 release paths σε όλα τα P1 commits.

Επιλογές για τον δημιουργό:
- **(α) προτεινόμενο:** κόψιμο των 6 νέων releases στο δικό σου μηχάνημα
  (έχει πρόσβαση TSA — το παλιό release έχει πραγματικά receipts):
  ```
  git pull
  for c in syntagma poinikos kpoinikis astikos kpolitikis kdioikitikis; do
    SOURCE_DATE_EPOCH=1783555200 ORCHESTRATOR_CORPUS=$c \
      docker run --rm -v "$PWD":/src -w /src -e LAWMAX_ROOT=/src \
      -e ORCHESTRATOR_CORPUS=$c -e SOURCE_DATE_EPOCH=1783555200 \
      -e ORCHESTRATOR_OUTPUT_DIR=/src/output orchestrator:test --run-pipeline
  done
  # → releases/2026-07-09T00:00:00Z ανά corpus + latest → νέο· commit
  ```
  (⚠ το --run-pipeline ξαναγράφει και per-article artifacts — αν θέλεις ΜΟΝΟ
  τα releases, πες το και ετοιμάζω ακριβές χειρουργικό βήμα όπως στο P1.)
- **(β)** ρητή έγκριση dev-mode χαλάρωσης της πύλης πληρότητας (1 έδρα) ώστε
  να κόβω releases χωρίς RFC-3161 από εδώ — ασθενέστερα proofs, ΔΕΝ το προτείνω.

## 5. Επαλήθευση

semantic-validity **20/20** (όλοι οι μάρτυρες σκληροί τοπικά: json.tool,
rdflib Turtle, rdflib JSON-LD offline) · corpus-identity **25/25** ·
standalone loop **79/79** · verify-truth **22/22** · ολομέλεια **22/23**
(μόνο advisor pre-materialization baseline) · golden **8/8** · καθαρό δέντρο.

## 6. Εκκρεμότητες φάσης

- Νέα releases: αναμένουν απόφαση δημιουργού (α)/(β) — τίποτα άλλο ανοιχτό στο P1.
- License CC0-vs-ARR: καταγεγραμμένο ως **Deferred License Policy Decision** (εντολή δημιουργού).
- P1b (Per-Article Surface Completion): + το εύρημα ονοματοδοσίας του §3.2.

*Χειρουργός Πυρήνα — έγκυρο για κάθε parser, αναλλοίωτο για κάθε ταυτότητα.*
