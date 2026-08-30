# THE LEGAL WATCHTOWER — COORDINATOR MASTER (pre-Phase-2 freeze v2-R3)

Αυτός ο φάκελος είναι **coordinator-only** και ζει **ΕΚΤΟΣ** του Andrianna repo.
Προτεινόμενη θέση (Windows): `C:\THE-LEGAL-WATCHTOWER-STUDY-OUTPUT\PRE-PHASE-2-FREEZE-v2-R3\`.

**Ρόλος σου = CREATOR_COORDINATOR.** Μπορείς να βλέπεις τα πάντα, να εγκρίνεις τα
hashes, να παρέχεις καθαρά περιβάλλοντα και να δρομολογείς σφραγισμένα artifacts.
**ΔΕΝ** δίνεις ποτέ αρχιτεκτονική απάντηση στον blind producer και **ΔΕΝ** ξαναγράφεις
πύλες μετά το output.

Τρέχουσα τίμια κατάσταση μελέτης: **`FINAL_OPTIMALITY_BLOCKED`**.
Ο ένας κανόνας που κυβερνά τα πάντα: **`UNIVERSAL_PROOF_ONLY`** (fail-closed).

---

## Δομή φακέλου

| Διαδρομή | Τι είναι |
|---|---|
| `0-VERIFY-FIRST/` | Το κανονικό σφραγισμένο outer freeze bundle (7 αρχεία, ΑΘΙΚΤΑ). Εδώ τρέχεις τους verifiers. |
| `1-UPLOAD-ONLY-THIS-TO-PRODUCER/` | Το **μοναδικό** αρχείο που ανεβαίνει στον producer + `HOW-TO-LAUNCH.md`. |
| `2-REVIEWER-ONLY--DO-NOT-SHOW-PRODUCER/` | Το reviewer capsule σε **καραντίνα** + `WHEN-TO-USE.md`. |
| `VERIFICATION-RESULTS.txt` | Τα αποτελέσματα επαλήθευσης (ήδη περασμένα). |
| `CREATOR-APPROVAL-RECEIPT.filled.json` | Έτοιμο receipt με τα 3 hashes· βάζεις μόνο timestamp + έγκριση. |
| `PHASES-2-6-EXECUTION-ROADMAP.md` | Ο πλήρης χάρτης εκτέλεσης Φάσεων 2→6 μέχρι το τελικό ceiling. |
| `SHA256SUMS.txt` | Checksums όλου του πακέτου. |

---

## Τι έχει ΗΔΗ γίνει (coordinator preflight)

- [x] Επαλήθευση outer bundle: `verify_bundle.py` → **`OUTER_FREEZE_VALID`**.
- [x] Reviewer structural validators (και οι δύο): **`FREEZE_STRUCTURE_VALID`** (33/33 έκαστος).
- [x] Επιβεβαίωση των **3 αμετάβλητων hashes** (βλ. `VERIFICATION-RESULTS.txt`).
- [x] Φυσικός διαχωρισμός ρόλων: το μοναδικό upload απομονωμένο, το reviewer capsule σε καραντίνα.
- [x] Το Andrianna repo παραμένει **άθικτο** (καμία κάψουλα/περιεχόμενο μελέτης μέσα σ' αυτό).

## Τι μένει να κάνεις εσύ (σειρά βημάτων)

1. **Ξανα-επαλήθευσε** (προαιρετικό, καλή πρακτική): μπες στο `0-VERIFY-FIRST/` και τρέξε
   `python verify_bundle.py`. Πρέπει να δεις `OUTER_FREEZE_VALID` + τα ίδια 3 hashes.
2. **Ενέκρινε τα 3 hashes**: άνοιξε `CREATOR-APPROVAL-RECEIPT.filled.json`, βάλε
   `timestamp_utc` και άλλαξε `status` σε `APPROVED`. Κράτα το receipt **εκτός** του
   σφραγισμένου bundle (η έγκριση δεν αλλάζει κανένα byte).
3. **Εκκίνηση PRODUCER (Φάση 2, blind)**: ακολούθησε το
   `1-UPLOAD-ONLY-THIS-TO-PRODUCER/HOW-TO-LAUNCH.md` — νέο κενό workspace, ανεβάζεις
   **μόνο** τη blind κάψουλα, επικολλάς το canonical prompt. Η κάψουλα κάνει μόνη της
   το isolation preflight και σταματά πριν την αρχιτεκτονική αν δει μόλυνση.
4. **Μετά τον producer**:
   - Κατέγραψε **byte length + SHA-256** του submission ZIP **ΠΡΙΝ** το ανοίξεις.
   - Διατήρησε ολόκληρο το session/tool transcript. **Μην** κάνεις resume τον producer.
5. **REVIEWER (ξεχωριστή συνεδρία)**: μόνο **τώρα** άνοιξε το
   `2-REVIEWER-ONLY--DO-NOT-SHOW-PRODUCER/`. Δώσε στον reviewer: reviewer capsule +
   παγωμένο producer ZIP + producer transcript. Ετυμηγορία: `PHASE_2_CANDIDATE_ACCEPTED_FOR_PROOF_PIPELINE`
   ή `PHASE_2_BLOCKED`.
6. **Φάσεις 3→6**: ακολούθησε το `PHASES-2-6-EXECUTION-ROADMAP.md`.

---

## ΚΡΙΣΙΜΕΣ ΥΠΕΝΘΥΜΙΣΕΙΣ (μη-διαπραγματεύσιμες)

- **Blindness είναι ξεχωριστή ετικέτα provenance.** Ένα κενό transcript δίνει
  `BLINDNESS_UNVERIFIED` — δεν επιβάλλει ατέρμονο rerun και **δεν** αποδεικνύει/
  αναιρεί το τελικό θεώρημα.
- **Κανένας δεν αποδέχεται το δικό του artifact.** Producer ≠ reviewer ≠ judge ≠
  synthesizer ≠ red team ≠ replicators — διακριτές συνεδρίες, όχι fork/resume/subagent.
- **Καμία πύλη δεν χαλαρώνει** μετά το output για να περάσει.
- Το «ανώτερο από Harvey» **δεν είναι δεδομένο** — είναι proof-gated: απαιτεί και τα
  66 κελιά `STRICTLY_BETTER` σε CoCounsel Legal, Lexis+ with Protégé, Harvey **και**
  proper-subset capability **και** ακριβή B0→E_star μετατροπή **και** ανεξάρτητη
  αναπαραγωγή. Αλλιώς η τίμια κατάσταση παραμένει `FINAL_OPTIMALITY_BLOCKED`.
