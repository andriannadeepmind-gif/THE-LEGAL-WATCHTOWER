# [0037] Claude → Κριτή+δημιουργό · 2026-07-09 · Component package-seat mapping — τελευταίο FF3 blocker κλεισμένο

Local proof δημιουργού στο `e8040bd9`: advisor ΠΡΑΣΙΝΟΣ (materialization A δούλεψε),
verify-truth 22/22, ΑΛΛΑ component-gate 12/13 — 135× «Πακέτο χωρίς αρχείο-έδρα
σε δηλωμένο σύστημα». Εντολή: μόνο component identity / package-seat mapping.
Commit: `e5679c27`.

## Αιτία (ένα ξεχασμένο baked-path IO)
Στο [0034] το hash έγινε root-coherent (`%live-file`), αλλά η **σάρωση εδρών**
(`%scan-file-text`) διάβαζε ακόμη το **baked** path. Τοπικά baked=live ⇒ περνούσε·
στο docker source-present το baked αρχείο ΔΕΝ υπάρχει ⇒ `ignore-errors` ⇒ κενό
κείμενο ⇒ κανένα defpackage seat ⇒ **κάθε** loaded πακέτο «χωρίς αρχείο-έδρα».

## Διόρθωση (αρχή [0034]: live IO ΜΟΝΟ μέσω FF1 ρίζας — ΚΑΜΙΑ baked-path IO)
- `build-component-registry!`: `%scan-file-text` → `(%live-file path)`
- `freeze-components!`: ομοίως (μία σύμβαση παντού)
- `stale-components`: meta `:path` (repo-relative) → επίλυση στην institution-root

## Απόδειξη
```
τοπικά (baked=live):      component 13/13 · 0 παραβάσεις · self-evolution 23/23
ΠΡΟΣΟΜΟΙΩΣΗ baked≠live:   git-archive αντίγραφο ως mount + LAWMAX_ROOT=αντίγραφο
                          (το ακριβές docker σενάριο) ⇒ component 13/13
ολομέλεια 22/23 (advisor local-env) · golden 8/8 · verify-truth 22/22 · git clean
```

Μόνο package-seat. Όχι FF4, όχι Publisher Hardening, όχι A–F. Αναμένει το
τελικό docker proof δημιουργού στο `e5679c27` → αν «--gates acceptable +
verify-truth 22/22» ⇒ FF3 MERGE-READY (ρητή εντολή merge).

— Claude (Χειρουργός Πυρήνα) · κλάδος `claude/ministry-justice-url-candidates-twghsj`
