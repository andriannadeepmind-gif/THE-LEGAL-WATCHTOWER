# [0159] — SPEC v1.8 IR4 CORRECTIVE PASS (CANDIDATE — re-verification #4 FAILED, five systemic corrections)
**2026-09-03 · parent `56da942a` · frozen v1.4 baseline `88129099` (tree `a2617649`) αμετάβλητο · CURRENT CANDIDATE — NOT FROZEN — NOT QUALIFIED — IMPLEMENTATION BLOCKED**

Εντολή: «INDEPENDENT RE-VERIFICATION #4 — FAILED». Η τέταρτη ανεξάρτητη επαλήθευση ΑΠΕΡΡΙΨΕ τον harness στο
`56da942a` με πέντε ευρήματα (IR4-01…IR4-05). Μία bounded **IR4 CORRECTIVE PASS** πάνω στο `56da942a`. Verification
tooling ΜΟΝΟ (πλην IR4-04 που κλείνει έναν πραγματικό dangling identifier σε traceability/qualification)· καμία νέα
αρχιτεκτονική/subsystem/protocol/store/capability/axis· κανένα production code/frozen v1.4/Book/WP-00/`RAW-JOURNAL`
change· καμία freeze/qualification. Pre-flight: HEAD ακριβώς `56da942a`, `git diff --check` καθαρό.

## Τα πέντε ευρήματα (αναπαραγμένα) και η συστημική διόρθωση
- **IR4-01 — πραγματική capability μπορούσε να εξαφανιστεί ενώ ο audit περνούσε.** Το `V8-CAP` (και το `.lisp`
  σκέλος του `V8-XREF`) αποφάσιζε την ύπαρξη ορισμού με regex/substring πάνω στο κείμενο· τυλίγοντας το
  `get-eli-law-prefix` σε `#| … |#` ο ορισμός έπαυε να υπάρχει ως εκτελέσιμη μορφή αλλά ο audit επέστρεφε 0.
  **Διόρθωση:** νέος **CL-aware structural reader** (`lisp_read_all`/`lisp_defs`) — αφαιρεί σημασιολογικά line +
  nested block comments, χειρίζεται strings/`#\\`char/`|bar|`, αναγνωρίζει πραγματικές top-level μορφές, λύνει
  `defpackage`/`in-package`/τις επιτρεπτές defining μορφές, απορρίπτει malformed input fail-closed, ΠΟΤΕ regex/
  substring ως απόδειξη ορισμού. Το `V8-CAP` αποτυγχάνει τώρα με `required-top-level-definition-missing`.
- **IR4-02 — το manifest δεν επέβαλλε ακριβές artifact universe.** Αφαιρώντας μια pinned γραμμή, το `do_manifest`
  ανέφερε «17 match» ελέγχοντας μόνο τις εναπομείνασες. **Διόρθωση:** ανεξάρτητο `EXPECTED_ARTIFACTS` (πηγή:
  `V1.8-VERIFY.py`, ΟΧΙ οι γραμμές που ελέγχει) — exact set/count, χωρίς missing/extra/duplicate path, per-file
  digest· ο orchestrator δένει τον declared parent σε `HEAD`/`HEAD^`· 5 meta-kills (remove/add/duplicate/substitute
  row, remove required artifact) → exit 3.
- **IR4-03 — καθαρό depth-1 clone δεν ήταν αναπαραγώγιμο.** Σε shallow clone το `git rev-parse HEAD^` αποτύγχανε →
  `A3-corrective-parent-binding` έπεφτε (41/42), μόνο χειροκίνητο `git fetch --deepen=1` το διόρθωνε. **Διόρθωση:**
  το bootstrap εξασφαλίζει bounded τον declared parent + `HEAD^` (deepen/exact fetch) ή σταματά με ακριβές
  `MISSING_PINNED_OBJECT`· επαληθεύτηκε σε πραγματικό depth-1 clone (bootstrap+audit → HEAD^ resolvable).
- **IR4-04 — πραγματικό baseline traceability defect.** Το `V1.8-SCHEMAS.sexp` δήλωνε `RA-JUR-NS → RA8-JURNS/T8-JURNS`
  που ΔΕΝ υπήρχαν στα traceability/qualification (είχαν `RA8-FROST/T8-FROST`). **Διόρθωση:** το `RA-JUR-NS` κλείνει
  end-to-end σε μία έδρα — `RA8-JURNS` requirement (traceability, δεμένο σε `JurisdictionNamespace/1`, owner S25,
  distinct από FROST) + `T8-JURNS` test (qualification)· το `V8-RA-DELTAS` λύνει τώρα requirement→traceability και
  test→qualification (η nonempty prose ΔΕΝ αρκεί).
- **IR4-05 — 23 νέα counterexamples επιβίωναν και τα 11 guards.** **Διόρθωση (γενικεύσεις):** exact node/edge/
  mutation/concept universes· duplicate detection (node-type, graph-edge, cardinality-rule, record-field,
  concept)· edge-endpoint + typed compatibility (resume_binding_ref, ghost node)· cardinality table δεμένο στα
  record fields + nullable selected· typed aggregation (pinned rule, `total`/`deterministic`/`preserve-causes`)
  αντί keyword-inspection prose· full traversal σε private-bearing enums (v1.6 `MemoryScope`) + exact ISR public-
  root set· exact WP concept→file map + exact future marker· traceability interface/owner/test/wp pinned EXACTLY
  ανά row (resolved against real registries).

## Παραδοτέα + αποτέλεσμα
Ξαναγραμμένα guards + reader + manifest universe στο `V1.8-VERIFY.py` (11 guards, 117 real-byte mutations, 70
held-out, 128 evidence rows). Ενημερωμένος `V1.8-CONTRADICTION-OMISSION-AUDIT.sh` (12 guard-mutation blocks σε 11
guards, MK11–MK15 manifest meta-kills, 15 injected meta-kills). Ενημερωμένο `V1.8-CLEAN-CLONE-BOOTSTRAP.sh`
(corrective parent + HEAD^). Κλείσιμο `RA-JUR-NS` σε traceability + qualification. `V1.8-SCHEMAS.sexp`/subsystem/
v1.6/v1.7 ΑΜΕΤΑΒΛΗΤΑ. Audit = **PASS** (65.536/65.536 aggregation, 11 baselines clean, 117/117 killed baseline≠
mutant SHA-256, 128/128 rows, manifest pins match, generated families killed, 15 meta-kills detected, bootstrap OK)·
regressions v1.7 **49/49** + v1.6 **56/56** + v1.5 **75/75** + v1.4 **158/158** + frozen tree `a2617649` + pinned
`.out` `4873e610`· `git diff --check` καθαρό· evidence deterministic (byte-identical, όλα τα `PYTHONHASHSEED`).

**ΕΤΥΜΗΓΟΡΙΑ: `V1.8 IR4 CORRECTIVE PASS COMPLETE — AWAITING FRESH INDEPENDENT RE-VERIFICATION #5 — NOT FROZEN —
NOT QUALIFIED — IMPLEMENTATION BLOCKED`.** Το v1.8 ΔΕΝ πέρασε ανεξάρτητη επαλήθευση· διορθώθηκαν ΜΟΝΟ τα πέντε
ευρήματα. ΔΕΝ δηλώνεται sound / complete / perfect / freeze-ready / independently-verified — μόνο ένας ανεξάρτητος
κριτής εκδίδει την επόμενη ετυμηγορία. Καμία freeze/qualification/Book/implementation χωρίς νέα ρητή εντολή
δημιουργού. Στάση.
