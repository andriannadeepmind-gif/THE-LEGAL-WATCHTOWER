# External coordinator package — pointer

Το εκτελέσιμο υλικό της μελέτης **δεν** ζει σε αυτό το repo. Ζει σε coordinator
study-output πακέτο, εκτός του Andrianna repo.

Προτεινόμενη θέση (Windows, από το freeze manifest):

```
C:\THE-LEGAL-WATCHTOWER-STUDY-OUTPUT\PRE-PHASE-2-FREEZE-v2-R3\
```

## Τι περιέχει το εξωτερικό πακέτο (`STUDY-LAUNCH-PACKAGE/`)

- `0-VERIFY-FIRST/` — το σφραγισμένο outer freeze bundle (7 αρχεία) + verifiers.
- `1-UPLOAD-ONLY-THIS-TO-PRODUCER/` — το **μοναδικό** αρχείο προς ανέβασμα στον
  producer (`PHASE-2-BLIND-PRODUCER-INPUT.zip`) + `HOW-TO-LAUNCH.md`.
- `2-REVIEWER-ONLY--DO-NOT-SHOW-PRODUCER/` — το reviewer capsule σε καραντίνα.
- `VERIFICATION-RESULTS.txt`, `CREATOR-APPROVAL-RECEIPT.filled.json`,
  `PHASES-2-6-EXECUTION-ROADMAP.md`, `SHA256SUMS.txt`.

## Τι ΔΕΝ μπαίνει ΠΟΤΕ σε αυτό το repo

- Οι κάψουλες (`PHASE-2-BLIND-PRODUCER-INPUT.zip`, `PHASE-2-REVIEWER-FROZEN-GATES.zip`).
- Οποιοδήποτε blind-input αρχείο ή reviewer-gate αρχείο ή το περιεχόμενό τους.
- Οποιαδήποτε αρχιτεκτονική απάντηση / υποψήφιο σχέδιο Φάσης 2.

Λόγος: η blind απομόνωση και ο διαχωρισμός ρόλων. Ο B0 baseline πρέπει να μένει
καθαρός· η μετατροπή του σε E_star γίνεται μόνο στη Φάση 3 (FOC-19/T7), μετά από
ρητή έγκριση δημιουργού και σφραγισμένο repository-delta σχέδιο.
