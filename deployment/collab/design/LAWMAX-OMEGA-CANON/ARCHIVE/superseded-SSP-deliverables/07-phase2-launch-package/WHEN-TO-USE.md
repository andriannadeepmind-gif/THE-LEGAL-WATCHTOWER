# REVIEWER CAPSULE — ΚΑΡΑΝΤΙΝΑ (μην το δείξεις ποτέ στον producer)

Αρχείο: **`PHASE-2-REVIEWER-FROZEN-GATES.zip`**
sha256: `a34c37aa4850ac4aa4758b37829a8d7f5c1624c4e089138b53a6988128fa25eb`

## ΚΑΝΟΝΑΣ ΔΙΑΧΩΡΙΣΜΟΥ

Ο producer λαμβάνει **μόνο** την blind κάψουλα + το reviewer-hash commitment
(που είναι ήδη μέσα στη blind κάψουλα ως `REVIEWER-CAPSULE-COMMITMENT.json`).
Αυτό το reviewer capsule αποκαλύπτεται **ΜΟΝΟ ΜΕΤΑ**:
1. ο producer έχει σταματήσει, **και**
2. τα bytes + SHA-256 του submission ZIP του έχουν **κλειδωθεί/καταγραφεί**.

Ο διαχωρισμός εγγυάται ότι οι πύλες κρίσης ήταν παγωμένες **πριν** υπάρξει
απάντηση — δεν μπορούν να «κουρδιστούν» για να περάσει ένα συγκεκριμένο output.

## Πότε & πώς

- Άνοιξέ το σε **ξεχωριστή reviewer συνεδρία** (όχι fork/resume του producer).
- Δώσε στον reviewer: το reviewer capsule + το παγωμένο producer ZIP + το πλήρες
  διατηρημένο producer transcript.
- Ο reviewer εφαρμόζει **μόνο** τις προ-παγωμένες πύλες + negative controls.
  Καμία πύλη δεν τροποποιείται για να πιστοποιήσει το ίδιο output.
- Πρώτη ετυμηγορία: είτε `PHASE_2_CANDIDATE_ACCEPTED_FOR_PROOF_PIPELINE` (με
  ξεχωριστή ετικέτα blindness) είτε `PHASE_2_BLOCKED` (με τις ακριβείς πύλες που
  απέτυχαν).

## Επαλήθευση δομής (ήδη περασμένη — μπορείς να την ξανατρέξεις)

```
python verify_freeze.py   ->  FREEZE_STRUCTURE_VALID  (33/33)
node   verify_freeze.mjs  ->  FREEZE_STRUCTURE_VALID  (33/33)
```

Δομικός validator — **ΟΧΙ** απόδειξη βελτιστότητας.
