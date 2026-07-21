;;;; tests/currentness-34-test.lisp
;;;; ============================================================================
;;;; [#34] CURRENTNESS LOCK — Ν.5221/2025 (Α'133) & Ν.5303/2026 (Α'81)
;;;; ============================================================================
;;;; Κλειδώνει ότι τα δύο τροποποιητικά ΓΕΓΟΝΟΤΑ είναι καταγεγραμμένα διτεμπορικά
;;;; στα configs (records ΧΩΡΙΣ κείμενο — fail-closed, βλ. docs/CURRENTNESS-34.md)
;;;; και ότι η consolidation τα εφαρμόζει με σωστή as-of σημασιολογία:
;;;;   · Ν.5303 (ισχύς 2026-09-16): as-of 15/9 ⇒ ORIGINAL· από 16/9 ⇒ AMENDED
;;;;     με provenance act n5303-2026 (μόνο mark-amended — ΚΑΜΙΑ αλλαγή κειμένου).
;;;;   · Ν.5221 (ισχύς 2026-01-01): record-μόνο-γεγονός (στόχοι άγνωστοι στο repo)
;;;;     — παρόν στα records, ΚΑΜΙΑ πράξη επί άρθρων.
;;;; Η αφαίρεση/αλλοίωση των records κοκκινίζει ΕΔΩ — το currentness debt είναι
;;;; εκτελεστό, όχι σχόλιο. Τρέχει με φορτωμένο orchestrator-cli (όπως cockpit-test).

(in-package :orchestrator.cli)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun %c34-records (corpus-id)
  (nth-value 2 (corpus-spec corpus-id)))

(defun %c34-record (corpus-id id)
  (find id (%c34-records corpus-id)
        :key (lambda (r) (orchestrator.consolidation.bridge::%rget r "id"))
        :test #'equal))

(defun %c34-status (corpus-id art &optional as-of)
  (multiple-value-bind (short doc) (build-consolidated-for corpus-id as-of)
    (declare (ignore short))
    (let ((p (orchestrator.consolidation:find-provision doc (format nil "art_~A" art))))
      (values (and p (orchestrator.consolidation:provision-status p))
              (and p (orchestrator.consolidation:provision-source-act p))))))

(format t "~%== [#34] Records παρόντα (γεγονότα, όχι κείμενο) ==~%")
(dolist (cid '("astikos" "kpolitikis" "kpoinikis"))
  (let ((r (%c34-record cid "n5303-2026")))
    (check (format nil "~A: record n5303-2026 παρόν, ΦΕΚ Α' 81/2026, ισχύς 2026-09-16" cid)
           (and r
                (equal "ΦΕΚ Α' 81/2026" (orchestrator.consolidation.bridge::%rget r "fek"))
                (equal "2026-09-16"
                       (orchestrator.consolidation.bridge::%rget r "date_applicability"))
                (equal "2026-07-21"
                       (orchestrator.consolidation.bridge::%rget r "recorded_at"))))))
(dolist (cid '("astikos" "kpolitikis"))
  (let ((r (%c34-record cid "n5221-2025")))
    (check (format nil "~A: record n5221-2025 παρόν, Α'133, ισχύς 2026-01-01, ΧΩΡΙΣ στόχους (τίμια άγνοια)" cid)
           (and r
                (equal "ΦΕΚ Α' 133/2025" (orchestrator.consolidation.bridge::%rget r "fek"))
                (equal "2026-01-01"
                       (orchestrator.consolidation.bridge::%rget r "date_applicability"))
                (null (orchestrator.consolidation.bridge::%rget r "articles_amended"))))))

(format t "~%== [#34] Διτεμπορική εφαρμογή (as-of semantics) ==~%")
(check "astikos art_1527 as-of 2026-09-15 ⇒ ORIGINAL (ο 5303 δεν ισχύει ακόμη)"
       (eq :original (%c34-status "astikos" "1527" "2026-09-15")))
(check "astikos art_1527 as-of 2026-09-16 ⇒ AMENDED (ημέρα έναρξης ισχύος)"
       (eq :amended (%c34-status "astikos" "1527" "2026-09-16")))
(check "astikos art_1527 τρέχον ⇒ AMENDED με provenance act n5303-2026"
       (multiple-value-bind (st act) (%c34-status "astikos" "1527" nil)
         (and (eq st :amended) (equal "n5303-2026" act))))
(check "kpolitikis art_808 as-of 2026-09-15 ⇒ ORIGINAL"
       (eq :original (%c34-status "kpolitikis" "808" "2026-09-15")))
(check "kpolitikis art_808 τρέχον ⇒ AMENDED (n5303-2026)"
       (multiple-value-bind (st act) (%c34-status "kpolitikis" "808" nil)
         (and (eq st :amended) (equal "n5303-2026" act))))
(check "ΟΛΟΙ οι [0067] στόχοι astikos (1521,1522,1616,1625) τρέχον ⇒ AMENDED"
       (every (lambda (n) (eq :amended (%c34-status "astikos" n nil)))
              '("1521" "1522" "1616" "1625")))

(format t "~%== [#34] Καμία αλλαγή ΚΕΙΜΕΝΟΥ (mark-amended = provenance μόνο) ==~%")
(check "astikos: το ΚΕΙΜΕΝΟ του art_1527 ταυτίζεται πριν/μετά την ισχύ (μόνο status αλλάζει)"
       (multiple-value-bind (s1 doc-before)
           (values nil (nth-value 1 (build-consolidated-for "astikos" "2026-09-15")))
         (declare (ignore s1))
         (let* ((doc-after (nth-value 1 (build-consolidated-for "astikos" "2026-09-16")))
                (p-before (orchestrator.consolidation:find-provision doc-before "art_1527"))
                (p-after  (orchestrator.consolidation:find-provision doc-after "art_1527")))
           (and p-before p-after
                (equal (orchestrator.consolidation:provision-text p-before)
                       (orchestrator.consolidation:provision-text p-after))))))

(format t "~%========================================~%")
(format t "CURRENTNESS-34 tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
