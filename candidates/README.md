# candidates/ — Ο ΧΩΡΟΣ ΕΡΓΑΣΙΑΣ ΤΟΥ ΜΗ ΕΜΠΙΣΤΟΥ ΠΑΡΑΓΩΓΟΥ

**ΕΤΥΜΗΓΟΡΙΑ ΔΗΜΙΟΥΡΓΟΥ (P0):** «Το κανονικό orchestrator έχει `/app/output:ro`,
αλλά το `--run-all-pipelines` γράφει άρθρα, manifests και `/app/output/.healthy`
έξω από το writable `candidates/` ⇒ ο αγωγός αποτυγχάνει με EROFS.»

Η λύση δεν ήταν να ξανανοίξει το `output/`. Είναι ότι ο παραγωγός έχει **δικό του
χώρο εργασίας**: `ORCHESTRATOR_OUTPUT_DIR=/app/candidates`. Το `output/` μένει
read-only (authority evidence, legacy releases) και η **εφήμερη** κατάσταση
(health/pid) πάει σε tmpfs `/run/lawmax` — ΠΟΤΕ μέσα σε evidence.
