# LAWMAX Φ7 — FORMAL TEMPORAL SEMANTICS (spec v3 — ΑΥΤΟΤΕΛΕΣ)

Καθεστώς: ΕΓΚΕΚΡΙΜΕΝΟ ΣΧΕΔΙΟ («Προχωρά με την ανώτατη υλοποίηση μόνο»,
2026-07-14) με υλοποιημένο ΜΟΝΟ το Π1 (commit 7fc6c718). Η υλοποίηση
Π2–Π7 ΠΑΓΩΜΕΝΗ με ρητή εντολή δημιουργού μέχρι νεότερη έγκριση.
Έδρα-στόχος: `orchestrator.version-graph` (source/version-graph.lisp).

Το παρόν είναι ΑΥΤΟΤΕΛΕΣ: κάθε ορισμός που χρειάζεται για υλοποίηση και
ανεξάρτητη επαλήθευση δίνεται εδώ — δεν απαιτείται ανάγνωση των v1/v2 ή
του διαλόγου κριτών (ιστορικό: deployment/collab/dialogue/0088-claude.md).

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
                                               ; REF: μη κενό string
           | (:after DURATION condition)
           | (:and condition+) | (:or condition+)
DURATION  := (:days N) | (:months N) | (:years N)   ; N: θετικός ακέραιος
```

- **Δεν υπάρχουν :not/:unless**: η άρνηση είναι δομικά αδύνατη, ώστε το
  sat να είναι μονότονο ως προς τη γνώση (περισσότερα events δεν
  «απο-ικανοποιούν» — μόνο το διτεμπορικό retract §3.3 το κάνει, και αυτό
  ανά known-at, όχι με μετάλλαξη).
- **Διαλυτικές αιρέσεις** εκφράζονται με ΚΛΑΣΗ στη δήλωση, όχι με άρνηση
  στο AST: `class ∈ {:suspensive, :resolutory}`. Suspensive: η ισχύς
  ΑΡΧΙΖΕΙ όταν ικανοποιηθεί. Resolutory: η ισχύς ΠΑΥΕΙ όταν ικανοποιηθεί
  (π.χ. ΠΝΠ μη κυρωθείσα, άρθ. 44§1 Σ).
- **Μητρώο KIND**: `deployment/data/instrument-kind-registry.sexp`
  (schema `:instrument-kind-registry/1`), σήμερα {:ya :pd :kya :decision
  :eu-approval :ratification :system-operational :event}. Κλειστό:
  KIND εκτός μητρώου ⇒ typed σφάλμα `invalid-condition`.
- **«Από τη δημοσίευση» ΔΕΝ είναι condition**: με γνωστό ΦΕΚ είναι
  συγκεκριμένη ημερομηνία (fek-date + DURATION) — κανόνας μετάπτωσης στο
  import.
- Επικύρωση: `valid-condition-ast-p` — ολική, fail-closed (άκυρη μορφή/
  ημερομηνία/kind/duration ⇒ `invalid-condition`, ποτέ NIL-σιωπή).

### 2.2 Ταυτότητα αίρεσης [Π1: ΥΛΟΠΟΙΗΜΕΝΟ]

`condition-id = sha256(%canon-sexp (cons class ast))` — value-canonical:
ίδιο (class, AST) ⇒ ίδιο id σε κάθε διεργασία/γλώσσα· άλλη κλάση ⇒ άλλο id.
Κατασκευή: `make-effectivity-condition (class ast)` ⇒ struct
`effectivity-condition {id, class, ast}`.

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
sat(:instrument-event k r) = από το ΜΟΝΑΔΙΚΟ live event (k,r)· κανένα ⇒ :pending·
                             ≥2 αντιφατικά live ⇒ ΣΦΑΛΜΑ invalid-condition
                             (ποτέ σιωπηλή επιλογή)
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
Payload: `{condition-id, class, ast}`. record-id = condition-id (§2.2) —
το replay επανυπολογίζει και συγκρίνει (semantic check ③). Δήλωση ΠΡΙΝ
από κάθε αναφορά (declare-before-reference): ακμή/event που αναφέρει
αδήλωτο cid ⇒ typed σφάλμα — dangling δομικά αδύνατο. Ιδεμποτής στο ίδιο id.

### 3.2 :condition-event
Payload: `{condition-id, kind∈μητρώο, ref, outcome ∈ {:satisfied,:refuted},
at (legal-date), evidence, verifier}`. Evidence ΥΠΟΧΡΕΩΤΙΚΟ με τουλάχιστον
`:source-digest` ή `:act-ref` — unverified satisfaction δομικά αδύνατο
(counter `unverified_satisfactions=0`). Διτεμπορικό: recorded-from = το
`:at` της γραμμής journal. Semantic hash: sha256(%canon-sexp
(cid kind ref outcome at evidence-digest)).

### 3.3 :condition-event-retract
Κλείνει recorded-until του event (κατά το πρότυπο G5 των text-versions).
Η «απο-ικανοποίηση» υπάρχει ΜΟΝΟ ως προς μεταγενέστερο known-at — κάθε
παλαιό snapshot μένει αναλλοίωτο. Retract ανύπαρκτου event ⇒ σφάλμα.

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
- Το admit-edge! conditional ακμής ΔΕΝ κλείνει την προηγούμενη validity.
  Το κλείσιμο γίνεται με ΝΕΟ journaled record
  `:validity-close-on-satisfaction {version, condition-id, derived-t}`
  όταν καταγραφεί (:satisfied t): valid-until = t. Η προηγούμενη έκδοση
  παραμένει in-force μέχρι τότε (νομικά ορθό).

## 5. REGIME EDGES & INTERVAL ALGEBRA [Π4]

- **Ξεχωριστός τύπος `regime-edge`** (ΟΧΙ υπότυπος amendment-edge — θα
  ξανάφερνε NIL-σχήμα πεδία): ops {:suspend :extend :expire :revive
  :retroact} πάνω σε στόχο + typed διάστημα [legal-date, legal-date|:open).
  Μεταβατικές διατάξεις ΔΕΝ είναι regime op — είναι text-versions με
  παράθυρο ισχύος. Ίδιο journal/Κ2/replay, δικό του semantic hash:
  sha256(op, target, span, act-ref, act-seq, enacted, fek-date).
- **Allen άλγεβρα** σε typed διαστήματα με %time-key: έλεγχος συνέπειας
  καθεστώτων (επικαλύψεις/κενά) + in-force predicate:
  `valid-καλύπτεται ∧ recorded-live ∧ ∄ γνωστή-κατά-known-at τέμνουσα
  αναστολή ∧ suspensive satisfied ∧ resolutory ¬satisfied`.
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
- Scoped ισχύς (γεωγραφικά/προσωπικά/καθ' ύλην πεδία): καταγραφή ως
  δηλωμένες διαστάσεις· όπου scoped καθεστώς θα μπορούσε να αλλάξει την
  απάντηση, η δήλωση μπαίνει ΜΕΣΑ στο δεσμευμένο τεκμήριο §6 (counter
  `silent_scope_omissions=0`). Πλήρης άλγεβρα τομής scope → Φ8.

## 6. ΔΕΣΜΕΥΣΗ — ΔΥΟ ΣΤΡΩΜΑΤΑ [Π5]

- **Intrinsic receipt έκδοσης** (αμετάβλητο, query-ανεξάρτητο): στο
  receipt-id μπαίνουν μόνο condition-ids + class + regime-edge-ids της
  έκδοσης. Ένα receipt ανά έκδοση, σταθερό Merkle φύλλο — το
  receipt-set root σταθερό ανά release.
- **Effectivity-attestation** (ανά ερώτημα): ξεχωριστό canonical-hash
  τεκμήριο που δεσμεύει (valid-at, known-at, receipt-id, sat-καταστάσεις,
  τέμνοντα καθεστώτα, scoped δηλώσεις) — επιστρέφεται από /as-known και
  τον verifier· ΔΕΝ μπαίνει στο Merkle των receipts.
- **/as-known JSON**: typed κορυφαίο πεδίο `in_force: true|false` +
  `basis` (complete | pending-condition | suspended | …) — καταναλωτής
  που διαβάζει μόνο το text δεν μπορεί να παρερμηνεύσει pending ως ισχύον.

## 7. JOURNAL/REPLAY — νέα kinds

Semantic hash ανά kind (replay επίπεδο ③):
- `:condition-declared` → record-id = condition-id = sha256(class+AST).
- `:condition-event` → sha256(cid, kind, ref, outcome, at, evidence-digest).
- `:condition-event-retract` → δείχνει υπάρχον event· άγνωστο ⇒ corruption.
- `:regime-edge` → §5. `:validity-close-on-satisfaction` → sha256(version,
  condition-id, derived-t).
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
