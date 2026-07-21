;;;; tests/self-identity-test.lisp
;;;; ============================================================================
;;;; [0112] ΑΥΤΟΓΝΩΣΙΑ ΤΑΥΤΟΤΗΤΑΣ — regression lock (εντολή δημιουργού 2026-07-21)
;;;; ============================================================================
;;;; Το σύστημα ΓΝΩΡΙΖΕΙ: δημιουργός = Stavropoulos Law®, σύστημα = LAWMAX-Ω.
;;;; Η γνώση ζει στη δηλωτική έδρα (deployment/knowledge/self-glossary.sexp) και
;;;; ρέει από τον ΠΡΑΓΜΑΤΙΚΟ μηχανισμό (ensure-fresh → %glossary-hit) — το τεστ
;;;; δεν ελέγχει string σε αρχείο αλλά τη ζωντανή απάντηση του γλωσσαρίου.

(in-package :orchestrator.cli)

(defvar *si-pass* 0)
(defvar *si-fail* 0)
(defmacro si-check (name form)
  `(handler-case
       (if ,form (progn (incf *si-pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *si-fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *si-fail*) (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

(format t "~%── [0112] SELF-IDENTITY: δημιουργός + όνομα συστήματος από τη ζωντανή γνώση ──~%")

(orchestrator.knowledge-packs:ensure-fresh)

(defun %si-answer (utterance)
  (let ((entry (%glossary-hit utterance)))
    (and entry (getf entry :answer))))

(let ((a (%si-answer "ποιος σε έφτιαξε;")))
  (si-check "① «ποιος σε έφτιαξε» ⇒ εγγραφή γλωσσαρίου ΥΠΑΡΧΕΙ" a)
  (si-check "② η απάντηση κατονομάζει το Stavropoulos Law®"
            (and a (search "Stavropoulos Law" a)))
  (si-check "③ η απάντηση φέρει τη διεύθυνση του γραφείου"
            (and a (search "info@stavropouloslaw.com" a))))

(let ((a (%si-answer "τι σύστημα είσαι;")))
  (si-check "④ «τι σύστημα είσαι» ⇒ εγγραφή γλωσσαρίου ΥΠΑΡΧΕΙ" a)
  (si-check "⑤ η απάντηση αυτοκατονομάζεται LAWMAX-Ω"
            (and a (search "LAWMAX-Ω" a)))
  (si-check "⑥ η απάντηση αποδίδει τη δημιουργία στο Stavropoulos Law®"
            (and a (search "Stavropoulos Law" a))))

(let ((a (%si-answer "LAWMAX τι είναι;")))
  (si-check "⑦ σκέτο «LAWMAX» ⇒ ίδια εγγραφή ταυτότητας"
            (and a (search "LAWMAX-Ω" a))))

;;; Αρνητικό: άσχετη εκφορά ΔΕΝ πιάνει εγγραφή ταυτότητας — καμία ψευδο-αναγνώριση
(si-check "⑧ άσχετη εκφορά ⇒ ΚΑΜΙΑ εγγραφή ταυτότητας (τίμιο κενό)"
          (let ((e (%glossary-hit "πόσα άρθρα έχει το σύνταγμα;")))
            (not (and e (member (getf e :term)
                                '("δημιουργός" "LAWMAX-Ω") :test #'string=)))))

(format t "~%========================================~%")
(format t "SELF-IDENTITY tests: ~D passed, ~D failed~%" *si-pass* *si-fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *si-fail*) 0 1))
