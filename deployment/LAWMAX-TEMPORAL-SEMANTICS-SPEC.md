# LAWMAX Φ7 — FORMAL TEMPORAL SEMANTICS (spec v2 — μετά τον αντιπαλικό κριτή)

Κατά την [0088-ΕΝΤΟΛΗ-2]. v2: κλείνει ΟΛΑ τα ευρήματα του ανεξάρτητου κριτή
σχεδίου (Ε-1…Ε-13, κατάθεση στο 0088-claude.md). Καθεστώς: ΣΧΕΔΙΟ — καμία
γραμμή κώδικα πριν από ρητό «εγκρίνω Φ7». Έδρα-στόχος: orchestrator.version-graph.

## 0. Πρόβλημα
(αμετάβλητο από v1) Conditional commencement, αναστολές, παρατάσεις,
επαναφορές, αναδρομικότητα, scoped ισχύς δεν εκφράζονται — καταλήγουν σε
καραντίνα. Στόχος: first-class, αποδεικτό, fail-closed, μονότονο.

## 1. EFFECTIVITY-CONDITION — formal AST (v2)

### 1.1 Γραμματική — ΜΟΝΟΤΟΝΗ (κλείνει Ε-1, Ε-3)
```
condition := (:date-reached DATE)
           | (:instrument-event KIND REF)     ; ΕΝΑΣ κόμβος θεσμικού γεγονότος·
                                              ; KIND από ΚΛΕΙΣΤΟ data-μητρώο
                                              ; (instrument-kind-registry: :ya,
                                              ; :pd, :decision, :eu-approval,
                                              ; :system-operational, :event, …)
                                              ; — όχι 5 ad-hoc κόμβοι με
                                              ; επικαλυπτόμενες κατηγορίες/
                                              ; equivocation στα condition-ids
           | (:after DURATION condition)
           | (:and condition+) | (:or condition+)
DURATION  := (:days N) | (:months N) | (:years N)
```
- **ΤΑ :not/:unless ΔΕΝ ΥΠΑΡΧΟΥΝ** (Ε-1: μη-μονότονα, σπάνε τη σταθερότητα
  του snapshot). Η ελληνική πραγματικότητα των αιρέσεων μοντελοποιείται με
  ΚΛΑΣΗ στη δήλωση: `:suspensive` (αναβλητική — η ισχύς αρχίζει όταν
  ικανοποιηθεί) | `:resolutory` (διαλυτική — η ισχύς ΠΑΥΕΙ όταν ικανοποιηθεί·
  π.χ. ΠΝΠ μη κυρωθείσα, άρθ. 44§1 Σ). Κάθε ατομικό condition μένει μονότονο
  pending→satisfied|refuted· η «άρνηση» είναι δομικά αδύνατη, όχι φρουρημένη.
- **«Από τη δημοσίευση» ΔΕΝ είναι condition** (Ε-3): όταν το ΦΕΚ είναι
  γνωστό, είναι συγκεκριμένη ημερομηνία (fek-date ± DURATION) — κανόνας
  μετάπτωσης στο import, δηλωμένος εδώ ρητά.

### 1.2 Denotational ορισμός sat — ολική συνάρτηση (κλείνει Ε-2)
```
sat : condition × live-events(known-at) → :pending | (:satisfied AT) | (:refuted AT)
sat(:date-reached d)        = (:satisfied d)                    ; πάντα
sat(:instrument-event k r)  = από το ΜΟΝΑΔΙΚΟ live event (βλ. 1.3)· αλλιώς :pending
sat(:after dur c)           = αν sat(c)=(:satisfied t) ⇒ (:satisfied (date+ t dur))
                              αλλιώς sat(c)
sat(:and cs)                = αν ∀ (:satisfied tᵢ) ⇒ (:satisfied (max tᵢ))
                              αν ∃ (:refuted t) ⇒ (:refuted (min t των refuted))
                              αλλιώς :pending
sat(:or cs)                 = αν ∃ (:satisfied tᵢ) ⇒ (:satisfied (min tᵢ))
                              αν ∀ (:refuted tᵢ) ⇒ (:refuted (max tᵢ))
                              αλλιώς :pending
```
`date+` = η ΜΙΑ ολική συνάρτηση ελληνικής προθεσμίας (κλείνει Ε-8): ΑΚ 241-243
— μη προσμέτρηση ημέρας έναρξης· μήνες/έτη λήγουν την αντίστοιχη ημερομηνία,
ελλείψει αυτής την τελευταία του μήνα (31/1+1μ ⇒ 28-29/2)· ΧΩΡΙΣ κανόνα
αργιών στη Φ7 (δηλωμένο όριο — αφορά δικονομικές προθεσμίες, όχι έναρξη
ισχύος νόμων)· πλήρη edge-case tests + ίδια συνάρτηση στον python verifier.

### 1.3 ΚΑΜΙΑ αποθηκευμένη κατάσταση — παράγωγη από διτεμπορικά events (κλείνει Ε-4)
- `:condition-declared` record: condition-id = canonical hash (JCS) του
  (AST + class)· δηλώνεται ΠΡΙΝ αναφερθεί από ακμή (declare-before-reference
  — δομική απόρριψη dangling, Ε3β φρουρός).
- `:condition-event` record: (condition-id, instrument-kind, ref, outcome
  :satisfied|:refuted, at (legal-date), evidence {source_digest/act-ref/FEK},
  verifier, :at) — ΔΙΤΕΜΠΟΡΙΚΟ (recorded-from/until όπως text-versions).
- Η κατάσταση ΔΕΝ αποθηκεύεται πουθενά: υπολογίζεται ΠΑΝΤΑ ως
  sat(AST, events recorded-live κατά known-at) — retract ικανοποίησης =
  G5 κλείσιμο recorded-until του event ⇒ κάθε snapshot συνεπές αυτόματα,
  καμία μετάλλαξη, καμία «απο-ικανοποίηση» εκ των υστέρων.
- Υ2 πύλη παντού: event μετρά μόνο αν recorded ≤ known-at.

### 1.4 Ακμές υπό αίρεση — συμφιλίωση με G2/admit-edge! (κλείνει Ε-6)
- Τύπος πεδίου: `effective := legal-date | (:conditional condition-id)` —
  ΚΛΕΙΣΤΟ sum, το NIL εξακολουθεί να μην χωράει στον τύπο.
- G2 διάταξη: conditional ακμές ταξινομούνται με (fek-date, act-seq, edge-id)
  ΜΕΧΡΙ την ικανοποίηση· μετά, με το derived effective (από sat) — και οι
  δύο φάσεις ντετερμινιστικές, journaled.
- Το admit-edge! για conditional ακμή ΔΕΝ κλείνει την προηγούμενη validity:
  το κλείσιμο γίνεται με ΝΕΟ journaled γεγονός `:validity-close-on-satisfaction`
  όταν καταγραφεί (:satisfied t) — valid-until = t, recorded = τότε. Η
  προηγούμενη έκδοση παραμένει in-force μέχρι τότε (νομικά ορθό — Ε1β).

### 1.5 Αποτέλεσμα version-at — TYPED τριών σκελών (κλείνει Ε-7, Ε1-δίλημμα)
```
version-at ⇒ (values v :complete)                        ; in-force έκδοση
           | (values v (:not-yet-effective cid since))   ; ΠΡΟΫΠΑΡΧΟΥΣΑ in-force,
                                                         ; νέα ψηφισμένη με pending
                                                         ; cid γνωστό από since —
                                                         ; αξιοποιεί το υπάρχον
                                                         ; tv-status :not-yet-effective
           | (values nil :no-version-in-force)           ; + ονομαστικό pending αν
                                                         ; fresh :insert υπό αίρεση
           | temporal-uncertainty                        ; ΜΟΝΟ γνήσια αδυναμία
                                                         ; ανακατασκευής — ΠΟΤΕ για
                                                         ; γνωστό pending (ψευδής
                                                         ; άγνοια απαγορεύεται)
```

## 2. REGIME EDGES & INTERVAL ALGEBRA (v2)
- **Ξεχωριστός τύπος `regime-edge`** (ετυμηγορία Ε2α): :suspend/:extend/
  :expire/:revive/:retroact — ΔΕΝ παράγουν to-versions· υπότυπος του
  amendment-edge θα ξανάφερνε NIL-σχήμα πεδία. Ίδιο journal/Κ2/γράφος, άλλο
  record kind (όπως quarantined-edge ≠ amendment-edge). Το `:transitional`
  ΔΙΑΓΡΑΦΗΚΕ από τα regime ops (Ε-9): μεταβατικές διατάξεις = text-versions
  με παράθυρο ισχύος, όχι καθεστωτική πράξη.
- Allen άλγεβρα πάνω σε typed [legal-date, legal-date|:open) με %time-key —
  χρήσεις: συνέπεια καθεστώτων (επικαλύψεις/κενά) + in-force predicate:
  valid-καλύπτεται ∧ recorded-live ∧ ∄ γνωστή-κατά-known τέμνουσα αναστολή ∧
  suspensive conditions satisfied ∧ resolutory conditions ¬satisfied.
- Υ2β: τα knowledge-gaps αποκτούν διάστημα [from, until|:open) — το κενό
  παύει να είναι σημείο.
- Scope-sets §2.3 v1 αμετάβλητο (κρίθηκε ΟΚ) + όρος Ε-11: όπου scoped
  καθεστώς θα μπορούσε να αλλάξει την απάντηση, η δήλωση μπαίνει ΜΕΣΑ στο
  δεσμευμένο τεκμήριο (attestation §3), όχι μόνο στο JSON.

## 3. ΔΕΣΜΕΥΣΗ — ΔΥΟ ΣΤΡΩΜΑΤΑ (κλείνει Ε-5)
- **Receipt έκδοσης (intrinsic, αμετάβλητο)**: στο receipt-id μπαίνουν ΜΟΝΟ
  τα query-ανεξάρτητα: condition-ids + class + regime-edge-ids που αφορούν
  την έκδοση. Ένα receipt ανά έκδοση, σταθερό Merkle φύλλο — το receipt-set
  root ΜΕΝΕΙ σταθερό ανά release.
- **Effectivity-attestation (ανά ερώτημα)**: ξεχωριστό τεκμήριο που δεσμεύει
  ρητά (valid-at, known-at, receipt-id, sat-καταστάσεις, τέμνοντα καθεστώτα,
  scoped δηλώσεις) — canonical hash, επιστρέφεται από /as-known/verifier·
  ΔΕΝ μπαίνει στο Merkle των receipts.
- /as-known JSON (κλείνει Ε-10): typed κορυφαίο πεδίο `in_force: true|false`
  + `basis` (complete | pending-condition | suspended | …) — caller που
  διαβάζει μόνο το text ΔΕΝ μπορεί να παρερμηνεύσει pending ως ισχύον, γιατί
  το text συνοδεύεται από in_force=false όταν δεν ισχύει.

## 4. JOURNAL/REPLAY (κλείνει Ε-12)
Semantic hash ανά νέο kind (επίπεδο ③ replay):
- :condition-declared → record-id = condition-id = hash(AST+class).
- :condition-event → record-id = hash(condition-id, kind, ref, outcome, at,
  evidence digest) — επανυπολογίσιμο από τα πεδία.
- :regime-edge → record-id = hash(op, target, span, act-ref, act-seq,
  enacted, fek-date) (ανάλογο %edge-hash).
- :validity-close-on-satisfaction → hash(version, condition-id, derived-t).
Παλαιά binaries σκάνε fail-closed σε νέα kinds (δηλωμένη συνέπεια)· ο python
verifier (Π6) επεκτείνεται ΣΤΟ ΙΔΙΟ gate με την υλοποίηση, όχι follow-up.

## 5. ΠΑΡΑΔΟΤΕΑ & COUNTERS
Π1 AST+registry+sat (ολική, με date+ και edge-case tests). Π2 condition
records + declare-before-reference + G5 retract ροή. Π3 conditional ακμές
(effective sum type, G2 δύο φάσεων, validity-close-on-satisfaction).
Π4 regime-edges + Allen + version-at τριών σκελών + Υ2β διαστήματα.
Π5 receipts intrinsic + effectivity-attestation + /as-known in_force.
Π6 python verifier ΙΔΙΟ gate. Π7 gated tests σε ΠΡΑΓΜΑΤΙΚΑ ελληνικά μοτίβα
(«με ΥΑ ορίζεται η έναρξη· άλλως 6 μήνες από δημοσίευση» = :or/:after,
ΠΝΠ resolutory, αναστολή+known-at ζεύγη, retract ικανοποίησης, tamper).
Counters: condition_state_defaults=0 · unverified_satisfactions=0 ·
silent_scope_omissions=0 · replay_mismatches=0 · false_uncertainty=0 (νέο —
κανένα temporal-uncertainty όπου η απάντηση είναι γνωστή).

## 6. ΟΡΙΑ Φ7 (δηλωμένα)
Scope-τομή άλγεβρα → Φ8. Lean proofs → Φ9 (v2 = κλειστή γραμματική, ολικές
συναρτήσεις, μονότονα διτεμπορικά events — άμεσα μηχανοποιήσιμο). Κανόνας
αργιών στο date+ → μελλοντική δικονομική επέκταση, ΕΚΤΟΣ έναρξης ισχύος.
Δικαστική κρίση εγκυρότητας όρων → εκτός (μόνο καταγραφή με τεκμήρια).
