# [0156] — SPEC v1.8 VERIFICATION-HARNESS CORRECTIVE PASS (CANDIDATE — re-verification FAILED, harness rebuilt)
**2026-09-03 · parent `37cf223d` · frozen v1.4 baseline `88129099` (tree `a2617649`) αμετάβλητο · CURRENT CANDIDATE — NOT FROZEN — NOT QUALIFIED — IMPLEMENTATION BLOCKED**

Εντολή: «FRESH INDEPENDENT RE-VERIFICATION — FAILED». Η ανεξάρτητη επανα-επαλήθευση ΑΠΕΡΡΙΨΕ το evidence repair του
`37cf223d` (η macro-architecture ΔΕΝ διαψεύστηκε· να ΜΗΝ χρησιμοποιηθεί για SPEC FREEZE). Ένα bounded
VERIFICATION-HARNESS CORRECTIVE PASS πάνω στο `37cf223d`. Απαγορευμένα (τηρήθηκαν): νέα αρχιτεκτονική/requirement/
subsystem/protocol/store/capability/axis· production code· frozen v1.4 tree· Implementation Book· WP-00·
`RAW-JOURNAL`· swarm/destruction. Pre-flight: HEAD ακριβώς `37cf223d`, branch σωστό, `git diff --check` καθαρό.

## Οι επτά υποχρεωτικές διορθώσεις
1. **ΠΛΗΡΕΣ ROOT-AUTHORITY ΓΙΝΟΜΕΝΟ.** `DimensionState={OK,DEGRADED,FAILED,UNKNOWN}` × 8 dimensions ⇒ **4^8 =
   65.536** states (όχι 2^8=256). Ο guard `V8-RASTATUS` parse-άρει το enum + τα dimensions από το πραγματικό schema
   και αξιολογεί ΚΑΙ τα 65.536: μία ντετερμινιστική projection ανά state· σωστή worst mandatory failure class·
   πλήρες `blocking_dimensions`· πλήρες `advisory_dimensions`· preservation όλων των causes· recovery ενός
   dimension ΔΕΝ καθαρίζει άλλο· UNKNOWN και DEGRADED πράγματι exercised. Καμία δήλωση «256 = full product».
2. **ΠΡΑΓΜΑΤΙΚΗ ΕΚΤΕΛΕΣΗ MUTATION.** Κάθε mutation αλλάζει ΠΡΑΓΜΑΤΙΚΑ bytes σε μοναδικό `mktemp` workspace και ο
   ΙΔΙΟΣ baseline guard ξανατρέχει πάνω στα mutated bytes. Κάθε evidence record: real baseline path· real mutant
   path· ΠΛΗΡΕΣ 64-char SHA-256 baseline bytes· ΠΛΗΡΕΣ 64-char SHA-256 mutant bytes· assertion ότι διαφέρουν· exact
   command· exit code· ο ακριβής guard/reason που απέρριψε το mutant. Κανένα hash filename/description/label.
3. **ΑΦΑΙΡΕΣΗ ΤΑΥΤΟΛΟΓΙΩΝ.** `terminal-with-outgoing` (είχε `or True`), `mandatory-model-node` (πετύχαινε λόγω
   `+['IR']`), `proposer-removal-structural-inequiv` (καμία πραγματική αφαίρεση proposer — τώρα αφαιρεί κόμβο από
   `symbolic-only-nodes` και σπάει την symbolic reachability), `remove-resume-edge`/`dangling-resume-target` (τώρα
   mutate-άρουν το graph και ξανατρέχουν τον lifecycle validator), `V8-RA-DELTAS/seven-seats` (baseline success →
   3 πραγματικά mutations: drop-to-six, rename-jurns-to-frost, blank-seat). Κάθε αντικατάσταση σκοτώνεται από τον
   production guard, όχι από one-off Boolean.
4. **FAIL-CLOSED HARNESS.** `set -euo pipefail`· κανένα `except Exception: pass`. Exit non-zero αν: ο verifier
   crash-άρει/δεν βγάζει result· λείπει/περισσεύει/διπλασιάζεται guard id· αποτυγχάνει η παραγωγή evidence· evidence
   stale· baseline==mutant hash· επιβιώνει mutation· το evidence set ≠ declared exact set. Evidence: temp → πλήρης
   validation → atomic `mv`. **7 meta-kill tests**: verifier crash, missing guard output, evidence-write fault,
   stale evidence, hard-coded DETECTED, missing/extra/duplicate guard, unchanged mutant bytes.
5. **PUBLIC/PRIVATE + OWNERSHIP CLOSURE.** Καμία manual `ROOTS` λίστα. Το public/private DERIVED από ISR
   (RESTRICTED/DEFERRED_PRIVATE/INTERFACE_ONLY/`public-dependency nil`) + schema records (`:public-dependency nil`)·
   type/reference/interface graph ενοποιημένο v1.6+v1.7+v1.8· κάθε undefined endpoint απορρίπτεται· κάθε public
   interface ελέγχεται (και όλα τα v1.8). `V8-OWN` reconcile store owner/writer με τα subsystem/interface registries.
6. **CANONICAL IDENTITY CLOSURE.** `MemoryEvent/1`, `ResolverResult/1`, `DatasetSnapshot/1`, `RightsMatrix/1`
   RESOLVED στις §15 reference έδρες τους (χωρίς διπλασιασμό τύπου) με TWO-PART non-circular έλεγχο: PART A
   identity+version μέσα στο define-reference block· PART B το canonical-file του block υπάρχει στο δίσκο και
   περιέχει τον locator. **0 unresolved**· μη-επιλύσιμη ταυτότητα θα ήταν HARD_PRE_FREEZE_BLOCKER, ποτέ silent pass.
   Το «ακριβώς τέσσερα unresolved» ΔΕΝ μετρά ως passing verification.

## Παραδοτέα
Νέο: `V1.8-VERIFY.py` (standalone re-runnable guard runner: `run`/`mutate`/`list-guards`/`list-muts`/`aggregate`).
Ξαναγραμμένο: `V1.8-CONTRADICTION-OMISSION-AUDIT.sh` (fail-closed orchestrator). Ενημερώθηκαν: `V1.8-SCHEMAS.sexp`
(canonical-identity closure §VR-02 + two-part invariant), `V1.8-CANDIDATE-MANIFEST.md`, TRACEABILITY §v1.8,
SUPERSEDED, AI-DIALOGUE. `V1.8-VERIFICATION-EVIDENCE.md` παράγεται ντετερμινιστικά (60 rows: 10 baselines + 50
mutations). Καμία αλλαγή σε subsystem/v1.6/v1.7 schemas/history.

## Guard-ID / mutation-ID σετ (declared exact)
10 guards: `V8-PUBPRIV`(9) `V8-XREF`(5) `V8-CAP`(4) `V8-OWN`(4) `V8-COGLIFE`(7) `V8-CLARIFY`(3) `V8-RASTATUS`(5)
`V8-SYM`(4) `V8-REQ`(6) `V8-RA-DELTAS`(3) = **50 mutations, 60 evidence rows**.

## Αποτέλεσμα
Aggregation: **65.536/65.536** states (4^8), μία projection ανά state, blocking/advisory complete, recovery
independent, UNKNOWN+DEGRADED exercised. Audit = **fail-closed PASS** (7 meta-kill tests, 10 baselines clean, 50/50
mutations killed με baseline≠mutant SHA-256, 60/60 evidence rows). Regressions: v1.7 **49/49**, v1.6 **56/56**,
v1.5 **75/75**, v1.4 **158/158**, frozen tree `a2617649`, pinned `.out` `4873e610`. `git diff --check` καθαρό·
protected paths αμετάβλητα· `RAW-JOURNAL` ανέγγιχτο.

**ΕΤΥΜΗΓΟΡΙΑ: `V1.8 VERIFICATION HARNESS CORRECTED — READY FOR FRESH INDEPENDENT RE-VERIFICATION`.** Το v1.8 ΔΕΝ
πέρασε ανεξάρτητη επαλήθευση· αυτή η pass ξαναέχτισε ΜΟΝΟ τον harness επαλήθευσης. Καμία freeze/qualification/
Book/implementation χωρίς νέα ρητή εντολή δημιουργού. Στάση.
