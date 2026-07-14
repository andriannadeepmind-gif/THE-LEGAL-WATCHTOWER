# LAWMAX Φ7 — FORMAL TEMPORAL SEMANTICS (spec v3 — ΑΥΤΟΤΕΛΕΣ)

Καθεστώς: ΕΓΚΕΚΡΙΜΕΝΟ ΣΧΕΔΙΟ («Προχωρά με την ανώτατη υλοποίηση μόνο»,
2026-07-14) με υλοποιημένο ΜΟΝΟ το Π1 (commit 7fc6c718). Η υλοποίηση
Π2–Π7 ΠΑΓΩΜΕΝΗ με ρητή εντολή δημιουργού μέχρι νεότερη έγκριση.
Έδρα-στόχος: `orchestrator.version-graph` (source/version-graph.lisp).

Το παρόν είναι ΑΥΤΟΤΕΛΕΣ: κάθε ορισμός που χρειάζεται για υλοποίηση και
ανεξάρτητη επαλήθευση δίνεται εδώ — δεν απαιτείται ανάγνωση των v1/v2 ή
του διαλόγου κριτών (ιστορικό: deployment/collab/dialogue/0088-claude.md).
Το v3 κλείνει και τα ευρήματα του στρατηγικού ελέγχου δημιουργού
2026-07-14: Κρίσιμο Α (scope model ορισμένο εδώ, §5), Κρίσιμο Β (πλήρες
regime-edge semantic hash, §5), Κρίσιμο Γ (υπογεγραμμένο release-bound
attestation, §6), Υψηλά: date-reached derived closure (§4), conflict
semantics condition events (§3.3β), Allen σχέσεις ορισμένες (§5).

## 0. Πρόβλημα και στόχος

Η ελληνική νομοθετική πραγματικότητα περιέχει έναρξη ισχύος υπό αίρεση
(«με απόφαση του Υπουργού ορίζεται η έναρξη· άλλως έξι μήνες από τη
δημοσίευση»), αναστολές, παρατάσεις, επαναφορές, αναδρομικότητα και
scoped ισχύ. Χωρίς τυπική σημασιολογία, τέτοιες διατάξεις καταλήγουν σε
καραντίνα (τίμια άγνοια) ενώ η απάντηση είναι γνώσιμη. Στόχος: first-class,
αποδεικτός, fail-closed, ΜΟΝΟΤΟΝΟΣ λογισμός ισχύος πάνω στο υπάρχον
διτεμπορικό version-graph, με μηδενική αποθηκευμένη παράγωγη κατάσταση.

## 1. Θεμέλια (προϋπάρχουσες έδρες που δεσμεύουν το Φ7)

- **Διτεμπορικός γράφος**: κάθε record φέρει valid-διάσταση (νομική ισχύς)
  και recorded-διάσταση (`recorded-from`/`recorded-until`, από το `:at` της
  γραμμής journal — ποτέ δεύτερο ρολόι). «Live κατά known-at» σημαίνει
  `recorded-from ≤ known-at < recorded-until|∞`.
- **Journal**: chained-append· κάθε γραμμή φέρει `:payload-hash` =
  sha256(%canon-sexp ΟΛΟΥ του payload) και `:chain` =
  sha256(prev ‖ 0x1F ‖ payload-hash). Το replay (load-graph) επαληθεύει
  ① payload-hash ② chain ③ semantic record hash ανά kind. Αποτυχία ⇒
  `journal-corruption` (500-κλάση), ποτέ σιωπηλή αποδοχή.
- **Typed χρόνος**: `legal-date-p` (γνήσιος γρηγοριανός με δίσεκτα),
  `legal-instant-p` (canonical UTC «Z»), σύγκριση με ακέραιο `%time-key`,
  ψηφία ΜΟΝΟ ASCII. Άκυρος χρόνος σε δημόσιο όριο ⇒ 400, ποτέ 500.
- **Υ2 πύλη**: record μετρά σε ερώτημα known-at ΜΟΝΟ αν recorded-from ≤ known-at.
- **Τίμια άγνοια**: `temporal-uncertainty` (422) ΜΟΝΟ για γνήσια αδυναμία
  ανακατασκευής. Ψευδής άγνοια (422 όπου η απάντηση είναι γνωστή)
  απαγορεύεται και μετριέται (counter `false_uncertainty=0`).

## 2. EFFECTIVITY-CONDITION — τυπικό AST

### 2.1 Γραμματική — ΜΟΝΟΤΟΝΗ, ΚΛΕΙΣΤΗ [Π1: ΥΛΟΠΟΙΗΜΕΝΟ]

```
condition := (:date-reached DATE)              ; DATE: legal-date string
           | (:instrument-event KIND REF)      ; KIND ∈ κλειστό data-μητρώο,
                                               ; REF: ΚΑΝΟΝΙΚΟΣ προσδιοριστής
           | (:after DURATION condition)
           | (:and condition+) | (:or condition+)
DURATION  := (:days N) | (:months N) | (:years N)   ; N: θετικός ακέραιος
```

- **REF — κανονικός προσδιοριστής, ΟΧΙ ελεύθερο κείμενο (κλείσιμο κριτή
  Β Α5-1)**: κάθε kind στο μητρώο /2 φέρει `:ref-syntax`· για αναμενόμενη
  πράξη ΑΓΝΩΣΤΗΣ ακόμη ταυτότητας (το ναυαρχικό μοτίβο), το REF είναι
  ΥΠΟΧΡΕΩΤΙΚΑ ο προσδιοριστής της ΕΞΟΥΣΙΟΔΟΤΟΥΣΑΣ διάταξης
  (π.χ. `ya-per:gr/nomos/2023/5039#art:40`) — παγκοσμίως μοναδικός μέσω
  της έδρας provision-id: δύο νόμοι με «ίδια» αίρεση δεν μπορούν ΔΟΜΙΚΑ
  να συμπέσουν σε condition-id, γιατί τα REF τους διαφέρουν. Στο Π1 το
  REF ελέγχεται ως μη κενό string· η συντακτική πύλη ref-syntax είναι
  ΡΗΤΟ gate του Π2 (counter `freeform_refs=0`).

- **Δεν υπάρχουν :not/:unless**: η άρνηση είναι δομικά αδύνατη, ώστε το
  sat να είναι μονότονο ως προς τη γνώση (περισσότερα events δεν
  «απο-ικανοποιούν» — μόνο το διτεμπορικό retract §3.3 το κάνει, και αυτό
  ανά known-at, όχι με μετάλλαξη).
- **Διαλυτικές αιρέσεις** εκφράζονται με ΚΛΑΣΗ στη δήλωση, όχι με άρνηση
  στο AST: `class ∈ {:suspensive, :resolutory}`. Suspensive: η ισχύς
  ΑΡΧΙΖΕΙ όταν ικανοποιηθεί. Resolutory: η ισχύς ΠΑΥΕΙ όταν ικανοποιηθεί
  (π.χ. ΠΝΠ μη κυρωθείσα, άρθ. 44§1 Σ).
- **Μητρώο KIND — TYPED**: `deployment/data/instrument-kind-registry.sexp`
  (schema `:instrument-kind-registry/2`): κάθε kind φέρει ΥΠΟΧΡΕΩΤΙΚΑ
  `:authority-class` + `:evidence` schema — το γενικό `:event` απαιτεί
  ρητή πράξη-πηγή με digest, δεν είναι «οτιδήποτε συνέβη». Σήμερα
  {:ya :pd :kya :decision :eu-approval :ratification :system-operational
  :event}. Κλειστό: KIND εκτός μητρώου ⇒ `invalid-condition`. Reader:
  `*read-eval*` ρητά NIL + πλήρης επικύρωση εγγραφών στη φόρτωση.
  **Κριτήριο `:event` (κλείσιμο Β-7)**: επιτρέπεται ΜΟΝΟ όταν κανένα
  ειδικό kind δεν ταιριάζει ΚΑΙ το REF προσδιορίζει συγκεκριμένη πράξη
  με digest· κάθε χρήση μετριέται (counter `generic_event_uses` ανά
  release, ορατό στο proof trail — η διαφυγή σε catch-all είναι μετρήσιμο
  χρέος, όχι σιωπηλή πόρτα).
- **«Από τη δημοσίευση» ΔΕΝ είναι condition**: με γνωστό ΦΕΚ είναι
  συγκεκριμένη ημερομηνία (fek-date + DURATION) — κανόνας μετάπτωσης στο
  import.
- Επικύρωση: `valid-condition-ast-p` — ολική, fail-closed (άκυρη μορφή/
  ημερομηνία/kind/duration ⇒ `invalid-condition`, ποτέ NIL-σιωπή).

### 2.2 Ταυτότητα αίρεσης — ΣΗΜΑΣΙΟΛΟΓΙΚΗ, domain-separated [Π1: ΥΛΟΠΟΙΗΜΕΝΟ]

Η ταυτότητα είναι ΡΗΤΑ **semantic** (όχι συντακτική): πριν το hash, το AST
κανονικοποιείται — στα αντιμεταθετικά :and/:or γίνεται flattening ίδιων
τελεστών, αφαίρεση διπλοτύπων και ντετερμινιστική ταξινόμηση παιδιών κατά
value-canonical string· μονομελές αποτέλεσμα καταρρέει στο παιδί. Άρα
(:and A B) ≡ (:and B A) ≡ (:and A A B) ≡ (:and A (:and B)) — ένα id.

`condition-id = sha256(%canon-sexp (:lawmax/effectivity-condition/1 class canon-ast))`
— **domain separation**: το tag `:lawmax/effectivity-condition/1` μπαίνει
ΜΕΣΑ στο hashed υλικό· μελλοντική αλλαγή σημασιολογίας ⇒ νέο tag ⇒ κανένα
παλαιό id δεν επιζεί με άλλη έννοια. Κατασκευή:
`make-effectivity-condition (class ast)` ⇒ struct
`effectivity-condition {id, class, canon-ast}`.

### 2.3 date+ — ελληνική προθεσμία, ολική [Π1: ΥΛΟΠΟΙΗΜΕΝΟ]

`date+ : legal-date × DURATION → legal-date`, κατά ΑΚ 241–243:
- `:days` — ημερολογιακή πρόσθεση.
- `:months`/`:years` — λήξη την αντίστοιχη ημερομηνία· ελλείψει αυτής, την
  τελευταία ημέρα του μήνα (31/1 + 1μ ⇒ 28/2 ή 29/2 σε δίσεκτο).
- Άκυρη είσοδος ⇒ `invalid-condition`. ΧΩΡΙΣ κανόνα αργιών (δηλωμένο όριο
  §9 — αφορά δικονομικές προθεσμίες, όχι έναρξη ισχύος).
- Ο ίδιος αλγόριθμος υποχρεωτικά στον ανεξάρτητο python verifier (Π6).

### 2.4 sat — denotational, ολική [Π1: ΥΛΟΠΟΙΗΜΕΝΟ]

```
sat : condition × live-events → :pending | (:satisfied AT) | (:refuted AT)
sat(:date-reached d)       = (:satisfied d)
sat(:instrument-event k r) = από τα live events (k,r) ΔΕΜΕΝΑ στο condition-id
                             (§3.2): κανένα ⇒ :pending· ≥1 ΣΥΜΦΩΝΑ (ίδιο
                             outcome) ⇒ (outcome, ΕΛΑΧΙΣΤΟ at)· αντιφατικά
                             outcomes ⇒ ΣΦΑΛΜΑ invalid-condition — ΕΝΑΣ
                             ορισμός, ταυτόσημος με §3.3β (κλείσιμο κριτή
                             Β-1: καμία δεύτερη σημασιολογία στο ίδιο spec)
sat(:after dur c)          = αν sat(c)=(:satisfied t) ⇒ (:satisfied (date+ t dur))
                             αλλιώς sat(c)
sat(:and cs)               = ∀ satisfied ⇒ (:satisfied (max tᵢ))·
                             ∃ refuted ⇒ (:refuted (min t των refuted))· αλλιώς :pending
sat(:or cs)                = ∃ satisfied ⇒ (:satisfied (min tᵢ))·
                             ∀ refuted ⇒ (:refuted (max tᵢ))· αλλιώς :pending
```
Ντετερμινιστικό: ίδια είσοδος ⇒ ίδια έξοδος (θεμέλιο replay + Π6).

## 3. CONDITION RECORDS — διτεμπορικά, ΚΑΜΙΑ αποθηκευμένη κατάσταση [Π2]

### 3.1 :condition-declared
Payload: `{condition-id, class, ast}` — **το journaled ast είναι ΠΑΝΤΑ το
ΚΑΝΟΝΙΚΟ (semantic) AST** (κλείσιμο Β Α5-2): το replay επανυπολογίζει το
cid από (class, ast) και συγκρίνει (semantic check ③) χωρίς να χρειάζεται
τη συντακτική μορφή εισόδου. Επαναδήλωση με άλλη επιφανειακή σύνταξη ⇒
ίδιο canon ⇒ ίδιο record ⇒ ιδεμποτής (καμία απώλεια — τα records είναι
ταυτόσημα)· άλλο canon ⇒ άλλο cid ⇒ άλλη δήλωση. Δήλωση ΠΡΙΝ από κάθε
αναφορά (declare-before-reference): ακμή/event που αναφέρει αδήλωτο cid
⇒ typed σφάλμα — dangling δομικά αδύνατο.

### 3.2 :condition-event
Payload: `{condition-id, kind∈μητρώο, ref, outcome ∈ {:satisfied,:refuted},
at (legal-date), evidence, verifier}`. Evidence ΥΠΟΧΡΕΩΤΙΚΟ κατά το
evidence schema του kind (μητρώο /2) — unverified satisfaction δομικά
αδύνατο (counter `unverified_satisfactions=0`). Διτεμπορικό: recorded-from
= το `:at` της γραμμής journal. Semantic hash: sha256(%canon-sexp
(cid kind ref outcome at evidence-digest)).
**Πειθαρχία (kind,ref) ↔ δήλωση (κλείσιμο Β Α5-1i)**: το (kind, ref) του
event πρέπει να ΥΠΑΡΧΕΙ ως :instrument-event κόμβος στο canonical AST της
δηλωμένης αίρεσης — αλλιώς η καταγραφή ΑΠΟΡΡΙΠΤΕΤΑΙ με typed σφάλμα στο
record-condition-event!: ορθογραφική/συντακτική απόκλιση δεν μπορεί να
παραγάγει σιωπηλό αιώνιο :pending. Στο sat, τα events μετρούν ΜΟΝΟ
δεμένα στο condition-id (cid-scoped — υλοποιημένο στο Π1 hardening).

### 3.3 :condition-event-retract
Κλείνει recorded-until του event (κατά το πρότυπο G5 των text-versions).
Η «απο-ικανοποίηση» υπάρχει ΜΟΝΟ ως προς μεταγενέστερο known-at — κάθε
παλαιό snapshot μένει αναλλοίωτο. Retract ανύπαρκτου event ⇒ σφάλμα.

### 3.3β Συγκρούσεις condition events — πλήρης σημασιολογία

- **Ταυτότητα γεγονότος**: event-id = sha256(%canon-sexp (cid kind ref
  outcome at evidence-digest)) — δύο καταγραφές με ίδια πεδία είναι ΤΟ ΙΔΙΟ
  γεγονός (ιδεμποτής επανακαταγραφή), με διαφορετικό οποιοδήποτε πεδίο
  είναι ΑΛΛΟ γεγονός.
- **Conflict set**: τα live-κατά-known-at events ίδιου (cid, kind, ref) με
  ΔΙΑΦΟΡΕΤΙΚΟ outcome. Μη κενό conflict set ⇒ το sat σηκώνει typed σφάλμα
  (invalid-condition) — ΠΟΤΕ σιωπηλή επιλογή, ΠΟΤΕ αυτόματη προτεραιότητα.
- **Adjudication (ΜΟΝΗ οδός)**: journaled retract (§3.3) του ηττημένου
  event με ρητό evidence (διορθωτικό ΦΕΚ / ανακλητική πράξη / verifier
  απόφαση). Δεν υπάρχει αυτόματο authority ordering: η επίλυση είναι
  ΘΕΣΜΙΚΗ πράξη με τεκμήριο, καταγεγραμμένη διτεμπορικά — snapshots πριν
  από την επίλυση συνεχίζουν τίμια να σφάλλουν-κλειστά (422/σφάλμα).
- Πολλαπλά ΣΥΜΦΩΝΑ events ίδιου (cid,kind,ref,outcome): sat χρησιμοποιεί
  το ΕΛΑΧΙΣΤΟ at (η ικανοποίηση συνέβη όταν πρωτοσυνέβη) — ντετερμινιστικό.

### 3.4 condition-status
`condition-status(graph, cid, known-at) = sat(ast, events live κατά known-at)`.
Η κατάσταση ΔΕΝ αποθηκεύεται πουθενά (counter `condition_state_defaults=0`) —
υπολογίζεται πάντα ως fold πάνω στα live events. Υ2 πύλη υποχρεωτική.

## 4. ΑΚΜΕΣ ΥΠΟ ΑΙΡΕΣΗ [Π3]

- Τύπος πεδίου: `effective := legal-date | (:conditional condition-id)` —
  κλειστό sum type· NIL δεν χωράει στον τύπο.
- G2 ντετερμινιστική διάταξη σε δύο φάσεις, αμφότερες journaled:
  πριν την ικανοποίηση με (fek-date, act-seq, edge-id)· μετά, με το
  derived effective από το sat.
- **ΕΝΑΣ μηχανισμός κλεισίματος — ΠΑΝΤΑ ΠΑΡΑΓΩΓΟΣ (κλείσιμο κριτή Β
  Α6-1/Α6-2· το journaled `:validity-close-on-satisfaction` ΔΙΑΓΡΑΦΕΤΑΙ
  από τη σχεδίαση)**: το admit-edge! conditional ακμής ΔΕΝ κλείνει την
  προηγούμενη validity — και ΚΑΝΕΝΑ ξεχωριστό close-record δεν υπάρχει.
  Το version-at υπολογίζει ΠΑΝΤΑ, στην τομή (valid-at, known-at):
  `sat(AST, events live κατά known-at)` — αν (:satisfied t), η
  προηγούμενη έκδοση συμπεριφέρεται ΣΑΝ valid-until = t. Συνέπειες:
  (α) το μικτό :or (ΥΑ ή 6 μήνες) δουλεύει ομοιόμορφα — αν η ΥΑ δεν
  εκδοθεί ποτέ, το date σκέλος ικανοποιεί με ∅ events, χωρίς να
  απαιτείται γεγονός που «δεν συνέβη»· (β) ο recorded άξονας είναι
  αυτομάτως τίμιος — για known-at πριν την καταγραφή του event, το sat
  δεν το βλέπει (Υ2) ⇒ καμία απόκλιση σκελών, γιατί ΔΕΝ υπάρχουν δύο
  σκέλη· (γ) καθαρά ημερολογιακή ικανοποίηση είναι ορατή σε ΚΑΘΕ
  known-at ≥ καταγραφή της ΑΚΜΗΣ (το κείμενο του νόμου με την ημερομηνία
  ήταν ήδη γνωστό — νομικά ορθό). ΚΑΜΙΑ αποθηκευμένη/journaled παράγωγη
  κατάσταση κλεισίματος = καμία δεύτερη έδρα της σημασιολογίας.

## 5. REGIME EDGES & INTERVAL ALGEBRA [Π4]

- **Ξεχωριστός τύπος `regime-edge`** (ΟΧΙ υπότυπος amendment-edge — θα
  ξανάφερνε NIL-σχήμα πεδία): ops {:suspend :extend :expire :revive
  :retroact} πάνω σε στόχο + typed διάστημα [legal-date, legal-date|:open).
  Μεταβατικές διατάξεις ΔΕΝ είναι regime op — είναι text-versions με
  παράθυρο ισχύος. Ίδιο journal/Κ2/replay.
  **Σημασιολογία ανά op (κλείσιμο Β-2/Β-6)**: `:suspend` — η ισχύς
  αναστέλλεται στο span (in-force=false εκεί)· `:revive` — αναιρεί
  ΣΥΓΚΕΚΡΙΜΕΝΟ προγενέστερο suspend (prior-edge-id ΥΠΟΧΡΕΩΤΙΚΟ) από
  σημείο εντός του span του· `:extend`/`:expire` — μετάθεση του
  valid-until του στόχου σε ΡΗΤΟ νέο όριο (μεταγενέστερο/προγενέστερο
  αντίστοιχα)· `:retroact` — ΔΙΤΕΜΠΟΡΙΚΗ επανεγγραφή του valid άξονα:
  δηλώνει (target, νέο valid-from|valid-until) με recorded-from = χρόνο
  journal — version-at σε known-at ≥ recorded βλέπει τα νέα όρια,
  σε προγενέστερο known-at τα παλαιά· ΚΑΜΙΑ μετάλλαξη, η αναδρομικότητα
  είναι ορατή ΜΟΝΟ ως προς το πότε έγινε γνωστή (τίμιος recorded άξονας).
  Συγκρουόμενα retroacts στο ίδιο target ⇒ σφάλμα, επίλυση με retract.
- **Semantic hash regime-edge (ΠΛΗΡΕΣ — κλείσιμο Κρίσιμου Β)**:
  sha256(%canon-sexp (op target span-from span-until|:open scope-set
  condition-id|NIL act-ref act-seq enacted fek-date prior-edge-id|NIL)) —
  δεσμεύει ΚΑΙ τα όρια διαστήματος, ΚΑΙ το scope, ΚΑΙ την τυχόν αίρεση,
  ΚΑΙ τον προηγούμενο κρίκο (revive δείχνει το suspend που αναιρεί):
  δύο διαφορετικές καθεστωτικές πράξεις ΔΕΝ μπορούν να συμπέσουν σε
  semantic id.
- **Allen άλγεβρα — ΟΡΙΣΜΕΝΗ** σε typed διαστήματα I=[i⁻,i⁺), J=[j⁻,j⁺)
  με σύγκριση %time-key (το :open ⇒ +∞)· και οι 13 σχέσεις:
  before(I,J): i⁺<j⁻ · meets: i⁺=j⁻ · overlaps: i⁻<j⁻<i⁺<j⁺ ·
  starts: i⁻=j⁻ ∧ i⁺<j⁺ · during: j⁻<i⁻ ∧ i⁺<j⁺ · finishes: i⁺=j⁺ ∧ j⁻<i⁻ ·
  equals: i⁻=j⁻ ∧ i⁺=j⁺ · + οι 6 αντίστροφες (after, met-by, overlapped-by,
  started-by, contains, finished-by). Παράγωγα κατηγορήματα του runtime:
  intersects(I,J) ≡ ¬(before ∨ after ∨ meets ∨ met-by)· covers(I,t) ≡
  i⁻ ≤ t < i⁺. Χρήσεις: **in-force predicate ΜΕ ΧΡΟΝΙΚΗ ΑΓΚΥΡΩΣΗ των
  αιρέσεων (κλείσιμο Β-4)** —
  `valid-καλύπτεται ∧ recorded-live ∧ ∄ γνωστή-κατά-known-at τέμνουσα
  αναστολή ∧ (∀ suspensive: sat=(:satisfied t) ∧ t ≤ valid-at)
  ∧ (∀ resolutory: ¬(sat=(:satisfied t′) ∧ t′ ≤ valid-at))` —
  ικανοποίηση ΜΕΤΑ το valid-at δεν ενεργοποιεί/παύει αναδρομικά· το sat
  δεν έχει «τώρα», η σύγκριση t↔valid-at γίνεται ΕΔΩ + έλεγχοι
  συνέπειας καθεστώτων (revive χωρίς τέμνον suspend ⇒ σφάλμα· δύο live
  regime edges ίδιου op/target με τέμνοντα spans και ΔΙΑΦΟΡΕΤΙΚΑ όρια
  στο κοινό τμήμα ⇒ σφάλμα — επίλυση ΜΟΝΟ με journaled retract, §3.3β
  πρότυπο). Πίνακας σύνθεσης
  (composition table) ΔΕΝ απαιτείται στο runtime — τα κατηγορήματα
  υπολογίζονται απευθείας στα typed άκρα· η πλήρης αλγεβρική μηχανοποίηση
  ανήκει στο Φ9 (Lean).
- **Υ2β**: τα knowledge-gaps αποκτούν διάστημα [from, until|:open) — το
  κενό γνώσης παύει να είναι σημείο.
- **version-at τριών σκελών** (typed, ποτέ ψευδής άγνοια):
```
version-at ⇒ (values v :complete)                      ; in-force έκδοση
           | (values v (:not-yet-effective cid since)) ; προϋπάρχουσα in-force,
                                                       ; νεότερη με pending cid
           | (values nil :no-version-in-force)         ; + ονομαστικό pending
                                                       ; αν fresh :insert υπό αίρεση
           | temporal-uncertainty                      ; ΜΟΝΟ γνήσια αδυναμία
```
- **Scope model — ΑΥΤΟΤΕΛΗΣ ΟΡΙΣΜΟΣ (κλείσιμο Κρίσιμου Α — καμία αναφορά
  σε v1)**: scope-set = πεπερασμένο σύνολο δηλώσεων στις 4 διαστάσεις
  {:territorial, :personal, :material, :procedural}. Κάθε δήλωση:
  `(διάσταση tag+)` με tags από κλειστό data-μητρώο ανά διάσταση
  (scope-tag-registry, ίδιο πρότυπο με instrument-kinds — εκτός μητρώου ⇒
  typed σφάλμα). Σημασιολογία: απούσα διάσταση = ΚΑΘΟΛΙΚΗ (universal)·
  παρούσα = η ισχύς περιορίζεται στην ένωση των tags της. Canonical μορφή:
  διαστάσεις σε σταθερή σειρά, tags ταξινομημένα — μία value-canonical
  αναπαράσταση, hashable με %canon-sexp. Πράξεις που ΟΡΙΖΟΝΤΑΙ στη Φ7:
  scope-covers-p (scope-set × ερώτημα-πλαίσιο → boolean | :unknown όταν
  το ερώτημα δεν δηλώνει τη διάσταση — τίμια άγνοια, ποτέ σιωπηλό ναι)
  και scope-intersects-p (δύο scope-sets — ανά διάσταση: universal τέμνει
  τα πάντα· αλλιώς μη κενή τομή tags). Πλήρης άλγεβρα (κανονικοποίηση
  ενώσεων/διαφορών, μερική κατάργηση ανά υποσύνολο) → Φ8 — δηλωμένο όριο,
  ΟΧΙ σιωπηλή εξάρτηση. Όπου scoped καθεστώς θα μπορούσε να αλλάξει την
  απάντηση, η δήλωση μπαίνει ΜΕΣΑ στο δεσμευμένο τεκμήριο §6 (counter
  `silent_scope_omissions=0`).

## 6. ΔΕΣΜΕΥΣΗ — ΔΥΟ ΣΤΡΩΜΑΤΑ [Π5]

- **Intrinsic receipt έκδοσης** (αμετάβλητο, query-ανεξάρτητο): στο
  receipt-id μπαίνουν μόνο condition-ids + class + regime-edge-ids της
  έκδοσης. Ένα receipt ανά έκδοση, σταθερό Merkle φύλλο — το
  receipt-set root σταθερό ανά release.
- **Effectivity-attestation** (ανά ερώτημα — ΠΛΗΡΩΣ δεσμευμένο, κλείσιμο
  Κρίσιμου Γ): canonical (JCS) αντικείμενο που δεσμεύει ΟΛΑ τα
  query-εξαρτώμενα ΚΑΙ τα αγκυρωτικά πεδία:
  `{protocol-version, corpus-id, valid-at, known-at, receipt-id,
  release-root, graph-chain-head, sat-καταστάσεις (ανά condition-id),
  τέμνοντα regime-edge-ids, scoped δηλώσεις, verifier-hash (sha256 του
  verify.lisp — ήδη 10ο canonical της ταυτότητας)}`.
  **ΚΛΕΙΔΙΑ (κλείσιμο ελέγχου Δ³#7): το release private key ΔΕΝ αγγίζει
  ΠΟΤΕ online runtime** — καμία per-query υπογραφή με αυτό. Το attestation
  είναι **deterministic certificate ΧΩΡΙΣ δική του υπογραφή**: κάθε πεδίο
  του είναι επανυπολογίσιμο από (α) το ΥΠΟΓΕΓΡΑΜΜΕΝΟ release root
  (offline-signed, transparency log), (β) το journaled γράφο (chain-head),
  (γ) τον canonical verifier (10ο canonical). Ο ανεξάρτητος verifier
  ΑΝΑΠΑΡΑΓΕΙ το attestation από αυτά και συγκρίνει byte-wise — η αυθεντία
  προκύπτει από την αναπαραγωγιμότητα πάνω σε offline-υπογεγραμμένες ρίζες,
  όχι από online κλειδί. (Δηλωμένη εναλλακτική, ΜΟΝΟ με έγκριση δημιουργού:
  delegated short-lived attestation key με offline-υπογεγραμμένη
  εξουσιοδότηση + λήξη + ανάκληση — δεν επιλέγεται τώρα.)
  Επιστρέφεται από /as-known και τον verifier· ΔΕΝ μπαίνει στο Merkle των
  receipts (query-εξαρτώμενο).
  **Αγκύρωση σε ΥΠΟΓΕΓΡΑΜΜΕΝΟ release (κλείσιμο κριτή Β Α1-1/Α1-2/Α1-3)**:
  (α) ΕΓΚΥΡΟ attestation ⇔ το graph-chain-head του ισούται με το
  census-δεσμευμένο graph_root ΥΠΟΓΕΓΡΑΜΜΕΝΟΥ release που επιλύεται στο
  transparency log — unsigned journal suffix (γνήσιο prefix + πλαστές
  γραμμές) δίνει chain-head που ΔΕΝ ανήκει σε κανένα υπογεγραμμένο
  release ⇒ απόρριψη. Ενδιάμεσες (μεταξύ releases) απαντήσεις είναι
  ΞΕΧΩΡΙΣΤΗ, ΡΗΤΗ κλάση: typed πεδίο `assurance: release-anchored |
  provisional-unanchored` — το δεύτερο ΔΕΝ επιτρέπεται να παρουσιάζεται
  ως «verified» και δεν σερβίρεται από authority profile χωρίς ρητή
  επιλογή καταναλωτή. (β) Φρεσκάδα: το attestation φέρει
  transparency-log entry + consistency proof του release του· ο
  καταναλωτής οφείλει να συγκρίνει με το ΝΕΟΤΕΡΟ checkpoint που γνωρίζει
  (≥1 ανεξάρτητο κανάλι — log mirror)· «stale» ⇔ νεότερο γνωστό release
  περιέχει supersession/retract που αλλάζει την απάντηση. Δηλωμένο όριο:
  απόλυτη φρεσκάδα offline είναι μη αποφασίσιμη — πολιτική max-age πεδίο
  του attestation, ποτέ σιωπηλή. (γ) Βήμα 0 κάθε επαλήθευσης
  (ΥΠΟΧΡΕΩΤΙΚΟ, όχι υπονοούμενο): έλεγχος verifier-hash κατά το canonical
  set του υπογεγραμμένου release — verifier από τον ίδιο mirror χωρίς
  αυτό το βήμα = κυκλική βεβαίωση, ΑΚΥΡΗ.
  **Αρνητικές εκβάσεις (κλείσιμο Β-3)**: το attestation έχει ΠΑΝΤΑ πεδίο
  `provision` (typed provision-id string) και
  `outcome ∈ {resolved(version-id), no-version-in-force,
  not-yet-effective(cid, since), uncertain(λόγος-422)}` — οι αρνητικές/
  αβέβαιες απαντήσεις (οι δικαστικά κρισιμότερες) δεσμεύονται στο ΙΔΙΟ
  release root + chain-head, ΔΕΝ κυκλοφορούν αδέσμευτες· receipt-id
  nullable ΜΟΝΟ όταν outcome ≠ resolved, με τον λόγο μέσα στο αντικείμενο.
- **/as-known JSON**: typed κορυφαίο πεδίο `in_force: true|false` +
  `basis` (complete | pending-condition | suspended | …) — καταναλωτής
  που διαβάζει μόνο το text δεν μπορεί να παρερμηνεύσει pending ως ισχύον.

## 7. JOURNAL/REPLAY — νέα kinds

Semantic hash ανά kind (replay επίπεδο ③):
- `:condition-declared` → record-id = condition-id = sha256(class+AST).
- `:condition-event` → sha256(cid, kind, ref, outcome, at, evidence-digest).
- `:condition-event-retract` → δείχνει υπάρχον event· άγνωστο ⇒ corruption.
- `:regime-edge` → §5. (Το `:validity-close-on-satisfaction` ΔΕΝ υπάρχει
  πλέον — το κλείσιμο είναι πάντα παράγωγο, §4.)
Παλαιά binaries σκάνε fail-closed σε άγνωστα kinds (δηλωμένη συνέπεια).
Ο python verifier (Π6) επεκτείνεται ΣΤΟ ΙΔΙΟ gate — όχι follow-up.

## 8. ΠΑΡΑΔΟΤΕΑ, ΚΡΙΤΗΡΙΑ ΑΠΟΔΟΧΗΣ, COUNTERS

| Π | Περιεχόμενο | Καθεστώς |
|---|---|---|
| Π1 | AST + μητρώο + ταυτότητα + date+ + sat | ΚΛΕΙΣΤΟ (7fc6c718, 23/23) |
| Π2 | condition records §3 + replay branches + locks ⑥-⑨ | ΠΑΓΩΜΕΝΟ |
| Π3 | conditional ακμές §4 | ΠΑΓΩΜΕΝΟ |
| Π4 | regime-edges/Allen/version-at/Υ2β §5 | ΠΑΓΩΜΕΝΟ |
| Π5 | δέσμευση §6 | ΠΑΓΩΜΕΝΟ |
| Π6 | python verifier ίδιων σημασιολογιών, ΙΔΙΟ gate | ΠΑΓΩΜΕΝΟ |
| Π7 | gated tests σε ΠΡΑΓΜΑΤΙΚΑ ελληνικά μοτίβα + tamper + restart parity | ΠΑΓΩΜΕΝΟ |

Κριτήρια αποδοχής κάθε Π: (α) πλήρης σουίτα πράσινη (version-graph,
graph-import-parity, as-known-e2e, temporal-semantics + νέα locks)·
(β) restart parity (φρέσκια διεργασία ⇒ ταυτόσημος γράφος)· (γ) tamper
⇒ journal-corruption· (δ) ανεξάρτητος αντιπαλικός κριτής με απόλυτο
rubric· (ε) owner docker proof· (στ) ρητή εντολή merge.

Counters (όλα υποχρεωτικά 0 στο κλείσιμο Φ7): `condition_state_defaults`,
`unverified_satisfactions`, `silent_scope_omissions`, `replay_mismatches`,
`false_uncertainty`.

## 9. ΔΗΛΩΜΕΝΑ ΟΡΙΑ Φ7

- Άλγεβρα τομής scope-sets → Φ8 (fine-grained identity/provenance).
- Μηχανικές αποδείξεις (Lean) → Φ9 — το v3 είναι άμεσα μηχανοποιήσιμο:
  κλειστή γραμματική, ολικές συναρτήσεις, μονότονα διτεμπορικά events.
- Κανόνας αργιών στο date+ → μελλοντική δικονομική επέκταση, ΕΚΤΟΣ
  έναρξης ισχύος νόμων.
- Δικαστική κρίση εγκυρότητας αιρέσεων → εκτός συστήματος· μόνο καταγραφή
  με τεκμήρια.
- Το benchmark Π7 απαιτεί τα 9 ΦΕΚ-δείγματα από τον δημιουργό (εκκρεμές).
