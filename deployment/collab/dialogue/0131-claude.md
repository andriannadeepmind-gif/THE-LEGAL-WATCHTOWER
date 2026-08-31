# [0131] — CHANGE-PROPOSAL v1.1 · Η ΜΙΑ TARGET ARCHITECTURE · DESTRUCTION PASS · FALSIFIED
**Claude · 2026-08-31 · branch `claude/blind-input-capsule-phase-2-efiajz` · πάνω στο `47bed1e7`**

Απάντηση στην απόρριψη του v1.0. Design only, καμία γραμμή κώδικα. **Δεν ζητείται
έγκριση υλοποίησης ούτε freeze.** Πλήρες κείμενο:
`design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.1.md`.

## Τι κατατίθεται

1. **Disposition ACCEPT/MODIFY/REJECT/MISSING** για Π1–Π11.
2. **Η ανώτερη μορφή έγινε target** για Π4/Π5/Π6/Π7/Π8/Π9/Π10· η κατώτερη μόνο ως
   μεταβατικό στάδιο με **ημερομηνία θανάτου + falsifier**.
3. **Π6** αντικαταστάθηκε με temporal proof contract + event-calculus projection.
4. **Π7** αντικαταστάθηκε με ολόκληρο το Ο4 §5.1–§5.6.
5. **Π8** λύθηκε υπέρ typed argument με **εκτελέσιμη** αξιολόγηση.
6. **Π11** ξαναγράφτηκε ως πλήρης δημόσια+ιδιωτική αποστολή με **U-01 ΚΑΙ U-02**.
7. **Μία κανονική target** + `SUPERSEDED-REGISTER.md` (15 παλαιότερες ιστορικές).
8. **Αναπαραγώγιμο evidence pack** (`formal-v1.1/`): 9 μοντέλα, 20 έλεγχοι, 0
   αποκλίσεις, με tool version + digests. Ο αριθμός agents ΔΕΝ είναι απόδειξη.

## Το ανεξάρτητο destruction pass — και η ειλικρινής ετυμηγορία

13 αντίπαλοι, ένα προδηλωμένο kill test ο καθένας. **Αποτέλεσμα: 9 FALSIFIED · 3
UNCERTAIN · 1 SURVIVES ⇒ ΣΥΝΟΛΙΚΑ FALSIFIED.** Έξι counterexamples
**αναπαρήχθησαν από τον συντάκτη** (`formal-v1.1/falsifiers/run-falsifiers.sh`,
όλα VIOLATED):

- **KT1** `TrustStateSkew`: σταματημένο ρολόι verifier κρατά «valid» πέρα από Δ —
  το §5.5 δηλωνόταν ανεπιφύλακτο ενώ υποθέτει σιωπηρά αξιόπιστο ρολόι.
- **KT3** `MatterCellSpoliation`: υλικό υπό νόμιμη διακράτηση φτάνει σε «erased»
  (ClearHold χωρίς εξουσιοδότηση) — σπολίαση αποδεικτικού υλικού.
- **KT6** `ArgKill`: δίτιμο grounded μπερδεύει UNDEC (ζωντανή σύγκρουση) με OUT
  (ανατραπείσα) — «ανοιχτό ζήτημα» ως «δεν είναι δίκαιο».
- **KT8** `PublicRootKT8`: ο `Publish` φυλάει μόνο `~conflicting`, όχι `official`
  ⇒ δημοσίευση χωρίς επίσημη πηγή (Root≠Truth παραβιάζεται).
- **KT9** `OfflineConsumeLeak`: version-pull fingerprint ⇒ το δημόσιο παρατηρεί
  δραστηριότητα υπόθεσης.
- **KT4** `MigrationRepro`: επανα-κανονικοποίηση αλλάζει content-id ⇒ old proof
  σπάει ακόμη και σε πλήρως συμμορφούμενο κόσμο.

Επιπλέον χωρίς μοντέλο: **KT2/KT12** aggregate declassification (singleton
ανακατασκευάζει προνομιακό δεδομένο)· **KT11** η γραμματική G / «ταβάνι = ρυθμός»
καταρρέει σε εσωτερική αντίφαση· **KT13** το AY class-approval λαθραία περνά
instances (self-authorization).

## Δύο σκληρά ταβάνια (δηλώνονται, δεν διεκδικούνται)
KT1: φραγμένη-σε-πραγματικό-χρόνο ανάκληση υπό σταματημένο ρολόι είναι αδύνατη
κατ' αρχήν (OCSP/CRL το μοιράζονται). KT9: {τέλεια τυφλό} ∧ {φρεσκάδα ≤ Δ} ∧
{cloud} είναι μη ικανοποιήσιμο — μηδενική διαρροή είναι ταβάνι.

## Διαδικασία
FALSIFIED ⇒ όχι freezeable. Απαιτούνται πρώτα οι εννέα διατεταγμένες δομικές
αλλαγές (§6.1), νέο destruction pass, επιβίωση στα kill tests, και ρητό «εγκρίνω
freeze target» του δημιουργού. Το Track-0 (Π1–Π3) μόνο ως emergency containment,
χωρίς κώδικα πριν από ρητή εντολή.
