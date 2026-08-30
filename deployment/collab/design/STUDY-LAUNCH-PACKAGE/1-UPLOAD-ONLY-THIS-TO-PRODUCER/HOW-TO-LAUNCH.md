# ΕΚΚΙΝΗΣΗ PRODUCER — Φάση 2 (blind)

> Σε αυτόν τον φάκελο υπάρχει **ΕΝΑ ΚΑΙ ΜΟΝΟ** αρχείο προς ανέβασμα:
> **`PHASE-2-BLIND-PRODUCER-INPUT.zip`**
> (sha256 `ac571a7a17971808811a98ae5a7dc9c9b0850f9bfdc808c90ae0b499060a10d3`)
>
> ΠΟΤΕ μην ανεβάσεις ή αναφέρεις το reviewer capsule, το B0/Andrianna repo, τη
> Φάση 1 ή προηγούμενη δουλειά Φάσης 2.

## 1. Καθαρό περιβάλλον (υποχρεωτικό)

Άνοιξε **νέο, κενό, upload-only workspace χωρίς κανένα repository** και ξεκίνα
**γνήσια νέα συνεδρία** — όχι resume / continue / branch / fork / κληρονομημένο
subagent. Το τρέχον session που είναι δεμένο στο Andrianna repo **ΔΕΝ** είναι
επιλέξιμο (έχει filesystem + project-memory έκθεση· η «φρέσκια συνομιλία» δεν
είναι απομόνωση εισόδου).

Σειρά επιλέξιμων διαδρομών (χρησιμοποίησε την πρώτη που μπορείς):
1. **Νέο upload-only cloud workspace** χωρίς mounted repo και χωρίς connector.
2. **Νέο sterile study-only repo** (μόνο αν η πλατφόρμα απαιτεί repo): νέο root
   commit που περιέχει **μόνο** την blind κάψουλα ή τα εξαγόμενα σφραγισμένα
   αρχεία της· κανένα fork/mirror/import/template/submodule/κοινό object-database
   /remote με το baseline. Κατέγραψε την ταυτότητα + το πλήρες tree hash πριν την
   εκκίνηση.
3. **Τοπικό bare απομονωμένο sandbox** με φρέσκο `CLAUDE_CONFIG_DIR` + bare mode
   (χωρίς host hooks/plugins/auto-memory/CLAUDE.md), χωρίς mount του baseline.

## 2. Ανέβασε ΜΟΝΟ αυτό

```
PHASE-2-BLIND-PRODUCER-INPUT.zip
```

## 3. Επικόλλησε ΑΚΡΙΒΩΣ αυτό το μήνυμα (canonical launch prompt)

```text
Extract the attached blind-input capsule in this new empty workspace. Read
START-FRESH-PHASE-2.md and execute it exactly. Before research, perform the
isolation preflight and stop before architecture work if prior project memory, a
baseline repository, an earlier study artifact, reviewer material or inherited
session context is visible. Phase 2 only. Deliver one sealed submission ZIP and
do not begin Phase 3.
```

(Ισοδύναμη διατύπωση από το REVIEW-RUNBOOK — προσθέτει ρητή υπενθύμιση για το
access ledger, το οποίο ούτως ή άλλως επιβάλλει η isolation policy:)

```text
Extract the attached blind-input capsule in this new empty workspace. Read
START-FRESH-PHASE-2.md and execute it exactly. Before research, perform the
isolation preflight and stop immediately if any prior project memory, baseline
repository, earlier study artifact, reviewer file or inherited session context is
visible. Phase 2 only. Preserve the complete access ledger and deliver one sealed
submission ZIP. Do not begin Phase 3.
```

## 4. Τι πρέπει να συμβεί μέσα στη συνεδρία (το κάνει η ίδια η κάψουλα)

- Πρώτη ενέργεια, πριν από κάθε αρχιτεκτονική έρευνα: δημιουργία
  `PHASE-2-ENVIRONMENT-ATTESTATION.json` + append-only `PHASE-2-ACCESS-LEDGER.jsonl`.
- Isolation preflight: αν φανεί **οτιδήποτε** απαγορευμένο (project memory,
  baseline repo/Git object, προηγούμενο study artifact, reviewer αρχείο,
  κληρονομημένο context) → **STOP** πριν την αρχιτεκτονική και κατέγραψε
  `PRELAUNCH_ISOLATION_BLOCKED`· επανα-παροχή καθαρού περιβάλλοντος **μία** φορά.
- Δημόσια έρευνα μόνο σε primary sources/επίσημα manuals/επίσημες νομικές πηγές
  /paper, με καταγραφή URL στο ledger. Καμία αναζήτηση baseline/prior-study.
- Παράδοση: **ένα** σφραγισμένο submission ZIP. **Δεν** ξεκινά Φάση 3, **δεν**
  αυτο-πιστοποιείται.

## 5. Μόλις σταματήσει ο producer

Πήγαινε στο `../READ-ME-COORDINATOR.md` βήμα «Μετά τον producer»: κλείδωσε
bytes/SHA-256 του submission ZIP **πριν** το ανοίξεις, διατήρησε ολόκληρο το
transcript, και **μόνο τότε** άνοιξε το φάκελο `2-REVIEWER-ONLY...` για ξεχωριστή
reviewer συνεδρία.
