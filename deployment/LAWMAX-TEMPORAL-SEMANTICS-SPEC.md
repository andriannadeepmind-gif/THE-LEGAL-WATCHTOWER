# LAWMAX Φ7 — FORMAL TEMPORAL SEMANTICS (spec, προ-υλοποίησης)

Κατά την [0088-ΕΝΤΟΛΗ-2] (ceiling capabilities #1 + #2). Καθεστώς: ΣΧΕΔΙΟ —
καμία γραμμή παραγωγικού κώδικα δεν γράφεται πριν (α) κριθούν οι εναλλακτικές
από ανεξάρτητους κριτές, (β) ρητό «εγκρίνω Φ7» του δημιουργού για την τελική
σύλληψη. Έδρα-στόχος: orchestrator.version-graph (ΚΑΜΙΑ νέα παράλληλη έδρα).

## 0. Πρόβλημα (τι ΔΕΝ εκφράζεται σήμερα)

Ο γράφος απαιτεί enacted/effective/fek-date ως συγκεκριμένες legal-dates.
Ορθό για απλές πράξεις· αδύνατο για: «ισχύει μετά την έκδοση ΥΑ», «όταν
λειτουργήσει το πληροφοριακό σύστημα», «υπό όρο έγκρισης ΕΕ», «6 μήνες μετά
το γεγονός Χ», αναστολές, παρατάσεις, επαναφορές, αναδρομικότητα, μερική
ισχύ ανά παράγραφο/πρόσωπο/περιοχή/αντικείμενο. Σήμερα αυτά καταλήγουν σε
καραντίνα (:unknown-effective) — τίμιο αλλά όχι σημασιολογία. Στόχος: το
«πότε/πού/σε ποιον ισχύει» να γίνει first-class, αποδεικτό, fail-closed.

## 1. EFFECTIVITY-CONDITION — formal AST

### 1.1 Γραμματική (typed, κλειστή — άγνωστος κόμβος = σφάλμα κατασκευής)

```
condition := (:date-reached DATE)                     ; ισχύς από ημερομηνία
           | (:event-occurred EVENT-ID)               ; δηλωμένο γεγονός
           | (:act-published ACT-REF)                 ; δημοσίευση πράξης (ΥΑ/ΠΔ)
           | (:decision-issued DECISION-REF)          ; έκδοση απόφασης
           | (:system-operational SYSTEM-ID)          ; θέση σε λειτουργία
           | (:approval-granted AUTHORITY-REF)        ; έγκριση αρχής (π.χ. ΕΕ)
           | (:after DURATION condition)              ; Χ διάστημα ΜΕΤΑ την ικανοποίηση
           | (:and condition+) | (:or condition+)
           | (:not condition) | (:unless condition condition)
DURATION  := (:days N) | (:months N) | (:years N)     ; ελληνικός ημερολογιακός κανόνας
```

### 1.2 Ταυτότητα & δέσμευση
- condition-id = canonical hash (JCS έδρα) ΟΛΟΚΛΗΡΟΥ του AST — ίδιο AST ⇒ ίδια
  ταυτότητα· μπαίνει στο edge payload ⇒ δεσμεύεται από payload-hash/chain/
  graph_root/census (καμία νέα ρίζα).
- Κατάσταση: :pending | :satisfied | :refuted | :unknown — ΠΟΤΕ default.
- Μετάβαση κατάστασης = ΜΟΝΟ journaled γεγονός (:condition-event) με:
  evidence (source_digest/prov stamp/act-ref/FEK), satisfied-at (legal-date ή
  legal-instant), recorded-from (:at της γραμμής — Υ3 πειθαρχία), verifier
  (ποιος/τι επαλήθευσε), αλυσιδωτές εξαρτήσεις.
- ΔΙΤΕΜΠΟΡΙΚΟ: η ικανοποίηση μετρά σε ερώτημα ΜΟΝΟ αν recorded ≤ known-at
  (Υ2 πύλη — μελλοντική γνώση δεν αγγίζει παλιό snapshot).

### 1.3 Σημασιολογία επιλογής έκδοσης
Ακμή με condition ≠ :satisfied στην τομή (valid-at, known-at) ⇒ οι to-versions
ΔΕΝ είναι in-force· αν η ύπαρξη της ακμής είναι γνωστή (recorded ≤ known):
version-at ⇒ temporal-uncertainty με ΟΝΟΜΑΣΤΙΚΟ pending condition (τίμια
δήλωση «ψηφισμένο αλλά όχι σε ισχύ — εκκρεμεί Χ»), εκτός αν η προϋπάρχουσα
έκδοση καλύπτει πλήρως (τότε: προϋπάρχουσα + δηλωμένο pending στο receipt.
Επιλογή μεταξύ των δύο = κρίσιμο σημείο για τους κριτές — βλ. §4 Ε1).

## 2. INTERVAL ALGEBRA & ΚΑΘΕΣΤΩΤΑ ΙΣΧΥΟΣ

### 2.1 Πράξεις καθεστώτος (νέα ops στον γράφο — journaled, typed)
:suspend (αναστολή [from,until|:open))· :extend (παράταση λήξης)· :expire
(λήξη χωρίς κατάργηση)· :revive (επαναφορά — ρητός δεσμός στο αρχικό)·
:retroact (αναδρομική ισχύς — valid-from < enacted, ΔΗΛΩΜΕΝΗ κλάση)·
:transitional (μεταβατική διάταξη με δικό της παράθυρο).
Κάθε μία = amendment-edge υπότυπος με πλήρη payload δέσμευση — όχι flags.

### 2.2 Αλγεβρα
Οι 13 σχέσεις Allen υλοποιούνται ΣΤΟΝ γράφο πάνω σε typed διαστήματα
[legal-date, legal-date|:open) με %time-key σύγκριση (η Υ1 έδρα — ΟΧΙ η
διαγραμμένη string-based εκδοχή). Χρήσεις: (α) έλεγχος συνέπειας καθεστώτων
μιας διάταξης (επικαλύψεις αναστολών, κενά)· (β) version-at: in-force ⟺
valid-καλύπτεται ∧ recorded-ζωντανό ∧ ∄ γνωστή-κατά-known αναστολή που τέμνει
το valid-at ∧ conditions satisfied. Κλείνει και το Υ2β (gaps με άνω όριο:
το κενό γνώσης γίνεται διάστημα, όχι σημείο).

### 2.3 Scope dimensions (temporal × territorial × personal × material × procedural)
Το in-force παύει να είναι boolean: γίνεται συνάρτηση scope. Αναπαράσταση:
κάθε έκδοση/καθεστώς φέρει προαιρετικό scope-set {(:territory …) (:persons …)
(:matter …) (:procedure …)} με ΚΛΕΙΣΤΟ λεξιλόγιο ανά διάσταση από δηλωμένο
μητρώο (data, όπως το body-kind-registry). Ερώτημα χωρίς scope ⇒ απαντά για
το ΚΑΘΟΛΙΚΟ scope και ΔΗΛΩΝΕΙ τυχόν scoped καθεστώτα (ποτέ σιωπηλή παράλειψη).
ΟΡΙΟ Φ7 (τίμιο): πλήρης άλγεβρα τομής scopes = Φ8+ ύλη· στη Φ7 τα scoped
καθεστώτα καταγράφονται typed + δηλώνονται στα ερωτήματα, χωρίς αυτόματη
scope-επίλυση.

## 3. ΕΝΤΑΞΗ ΣΤΙΣ ΥΠΑΡΧΟΥΣΕΣ ΕΔΡΕΣ (καμία νέα ρίζα/έδρα)
- journal σχήμα: νέα kinds :condition-declared / :condition-event /
  :regime-edge — ίδιο payload-hash/chain (Κ2), ίδιο replay (semantic hash ανά
  kind), παλαιά journals συμβατά (νέα kinds προστίθενται, δεν αλλάζουν παλιά).
- receipts: το LegalAuthorityReceipt αποκτά πεδίο effectivity (conditions +
  καταστάσεις στην τομή + καθεστώτα που την τέμνουν) — μπαίνει στη δέσμευση
  receipt-id. Το census/graph_root κληρονομεί αυτόματα.
- /as-known: όταν η απάντηση εξαρτάται από pending condition ⇒ ρητό πεδίο
  effectivity_pending στο JSON (όχι νέο status code — 200 με δηλωμένη
  εκκρεμότητα, 422 μόνο για γνήσια αβεβαιότητα ανακατασκευής).
- import Φ3 path: υπάρχουσες καραντίνες :unknown-effective μπορούν να
  ΜΕΤΑΤΑΧΘΟΥΝ σε typed conditions με νέα journaled γεγονότα (ποτέ επανεγγραφή).

## 4. ΣΧΕΔΙΑΣΤΙΚΕΣ ΕΝΑΛΛΑΚΤΙΚΕΣ (κρίνονται με απόλυτα κριτήρια [0082+])
- **Ε1 Pending σημασιολογία**: (α) pending ⇒ πάντα temporal-uncertainty·
  (β) pending ⇒ προϋπάρχουσα έκδοση in-force + δηλωμένο pending στο
  receipt/απάντηση. [Η (β) είναι νομικά ορθότερη — ό,τι δεν άρχισε να ισχύει
  δεν θολώνει το ισχύον — αλλά απαιτεί αυστηρό έλεγχο ότι η ακμή ΔΕΝ έκλεισε
  την προηγούμενη validity πριν την ικανοποίηση.]
- **Ε2 Καθεστώτα**: (α) ξεχωριστός τύπος regime-edge δίπλα στο amendment-edge·
  (β) υπότυποι του amendment-edge με op ∈ {:suspend …}. [Η (β) κρατά ΜΙΑ
  ταξινόμηση πράξεων· η (α) καθαρότερη σημασιολογικά — οι αναστολές δεν
  παράγουν νέο κείμενο.]
- **Ε3 Conditions αποθήκευση**: (α) μέσα στο edge payload· (β) ξεχωριστά
  :condition-declared records με αναφορά από το edge. [Η (β) επιτρέπει κοινό
  condition σε πολλές ακμές (μία ΥΑ ενεργοποιεί δεκάδες διατάξεις) — ΜΙΑ
  έδρα γεγονότος, όχι αντίγραφα.]
Κριτήρια (απόλυτα, ανά εναλλακτική): δομική αδυναμία σφάλματος· μία έδρα·
τίμια άγνοια· διτεμπορική ορθότητα· δεσμευσιμότητα (payload/receipt/census)·
replay ταυτότητα· συμβατότητα υπαρχόντων journals· απλότητα verifier·
επεκτασιμότητα σε Φ8/Φ9 (fine-grained ids, Lean kernel).

## 5. ΠΑΡΑΔΟΤΕΑ Φ7 (όταν εγκριθεί)
Π1 condition AST + ταυτότητα + lifecycle (journaled) στο version-graph.
Π2 regime ops + Allen άλγεβρα + version-at ενσωμάτωση (Υ2β κλείσιμο).
Π3 scope-sets typed καταγραφή + δήλωση στα ερωτήματα (όριο §2.3).
Π4 receipts/census/as-known effectivity δέσμευση.
Π5 gated tests: πραγματικά ελληνικά παραδείγματα (conditional commencement
   από υπαρκτούς νόμους — π.χ. διατάξεις «με απόφαση του Υπουργού ορίζεται
   η έναρξη»), tamper vectors σε conditions, bitemporal ζεύγη, replay parity.
Π6 verifier επέκταση (python) για τα νέα journal kinds.
Acceptance counters: condition_state_defaults=0 · unverified_satisfactions=0 ·
silent_scope_omissions=0 · replay_mismatches=0.

## 6. ΔΗΛΩΜΕΝΑ ΟΡΙΑ Φ7
Πλήρης scope-τομή άλγεβρα → Φ8. Formal proofs των invariants → Φ9 (το AST
σχεδιάζεται Lean-friendly: κλειστή γραμματική, ολικές συναρτήσεις). Δικαστική
κρίση εγκυρότητας όρων → εκτός (μόνο ΚΑΤΑΓΡΑΦΗ ικανοποίησης με τεκμήρια).
