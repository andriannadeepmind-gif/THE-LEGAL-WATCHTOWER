# Fresh Phase-2 — Coordinator playbook (in-repo, answer-neutral)

Έδρα: `deployment/collab/fresh-phase-2-launch/`.
Σκοπός: να υπάρχει **εντός του repo**, υπό έλεγχο έκδοσης, ο συντονιστικός οδηγός
για την εκκίνηση της φρέσκιας (blind) Φάσης 2 — **χωρίς** να μπαίνει καμία κάψουλα
και κανένα περιεχόμενο μελέτης μέσα στο repo.

> **Δομικός κανόνας απομόνωσης.** Ούτε η blind κάψουλα ούτε το reviewer capsule
> ούτε οποιοδήποτε blind-input / reviewer-gate περιεχόμενο μπαίνει σε αυτό το repo.
> Το repo παραμένει ο B0 baseline (`main @ e621dbe1…`), άθικτος. Ο producer τρέχει
> σε ξεχωριστό, κενό workspace και **δεν βλέπει ποτέ** αυτό το repo. Αυτό το dossier
> είναι answer-neutral logistics.

## Πού ζει η μελέτη

Το πλήρες, εκτελέσιμο υλικό (σφραγισμένη κάψουλα, verifiers, launch checklist,
approval receipt, roadmap Φάσεων 2→6) βρίσκεται **εκτός** του repo, στο coordinator
study-output πακέτο (βλ. `EXTERNAL-PACKAGE-POINTER.md`). Εδώ κρατάμε μόνο:

- `FREEZE-VERIFICATION-RECORD.json` — τα 3 αμετάβλητα hashes + τα αποτελέσματα των verifiers.
- `COORDINATOR-PLAYBOOK.md` — αυτό το αρχείο.
- `EXTERNAL-PACKAGE-POINTER.md` — δείκτης προς το εξωτερικό πακέτο + τι ΔΕΝ μπαίνει εδώ.

## Κατάσταση (τίμια)

- Freeze bundle v2-R3: **transport-verified** (`OUTER_FREEZE_VALID`,
  `FREEZE_STRUCTURE_VALID` ×2, 33/33).
- Μελέτη: **`FINAL_OPTIMALITY_BLOCKED`** (κανόνας: `UNIVERSAL_PROOF_ONLY`, fail-closed).
- Γιατί χρειάζεται fresh blind epoch: το αρχικό producer-session evidence ήταν
  μη-ανακτήσιμο (`SESSION_LOG_NOT_FOUND`), άρα η blind-independence δεν μπορεί να
  θεμελιωθεί από το παλιό υλικό — μόνο μια νέα, καθαρή blind εποχή το αντικαθιστά.

## Επιλεξιμότητα περιβάλλοντος

| Περιβάλλον | Επιλέξιμο για blind producer; |
|---|---|
| Συνεδρία δεμένη σε αυτό το repo (ακόμη και «νέο chat») | **ΟΧΙ** — filesystem + project-memory έκθεση |
| Νέο κενό upload-only workspace, γνήσια νέα συνεδρία | ΝΑΙ (προτιμώμενο) |
| Νέο sterile study-only repo (μόνο η blind κάψουλα, κανένα remote/fork/submodule) | ΝΑΙ (fallback) |
| Τοπικό bare απομονωμένο sandbox (φρέσκο config, χωρίς mount του baseline) | ΝΑΙ (fallback) |

## Ροή συντονισμού (υψηλού επιπέδου)

1. Επαλήθευση bundle → 2. Έγκριση δημιουργού των 3 hashes (external receipt) →
3. Εκκίνηση **producer** σε καθαρό περιβάλλον (ανεβαίνει **μόνο** η blind κάψουλα) →
4. Producer σταματά· κλείδωμα submission bytes/SHA-256· διατήρηση transcript →
5. **Reviewer** σε ξεχωριστή συνεδρία με το reviewer capsule (αποκάλυψη μόνο τώρα) →
6. Φάσεις 3→6 κατά τον εξωτερικό roadmap.

Οι λεπτομέρειες κάθε βήματος (ακριβές paste-prompt, isolation preflight, πύλες
κρίσης) βρίσκονται στο εξωτερικό πακέτο, ώστε reviewer-gate specifics να μη
γράφονται μέσα στο repo.

## Απαρέγκλιτα

- Producer ≠ reviewer ≠ judge ≠ synthesizer ≠ red team ≠ replicators (διακριτές
  συνεδρίες, όχι fork/resume/subagent). Κανείς δεν αποδέχεται το δικό του artifact.
- Καμία πύλη δεν τροποποιείται μετά το output.
- «Ανώτερο από Harvey»: proof-gated, όχι δεδομένο (66/66 `STRICTLY_BETTER` + proper
  subset + ακριβής B0→E_star + ανεξάρτητη αναπαραγωγή), αλλιώς `FINAL_OPTIMALITY_BLOCKED`.
