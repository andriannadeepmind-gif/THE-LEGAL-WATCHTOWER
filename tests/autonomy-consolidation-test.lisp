;;;; tests/autonomy-consolidation-test.lisp
;;;; THE CAPSTONE: a discovered amending law's TEXT, with NO hand-authored records,
;;;; becomes per-corpus amendment records and consolidates each code correctly.
;;;;
;;;;   law TEXT  → laws->records(corpus)  → consolidate-corpus  → in-force article
;;;;
;;;; One act that touches BOTH the Penal Code and the Code of Criminal Procedure
;;;; must hand each corpus ONLY its own operation — the missing «κούμπωμα» that makes
;;;; discover → route → fetch → extract → consolidate fully autonomous.

(in-package :orchestrator.consolidation.bridge)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun ptext (doc eid)
  (let ((p (orchestrator.consolidation:find-provision doc eid)))
    (and p (orchestrator.consolidation:provision-text p))))

;; A real-shaped law (alist, exactly as the discovery JSON delivers it) amending
;; TWO codes — and the ΚΠΔ payload nests its own « » quote.
(defparameter *law*
  (list (cons "id" "Ν.5090/2024") (cons "date" "2024-02-24") (cons "fek" "Α 30/2024")
        (cons "text"
              (concatenate 'string
                "Άρθρο 1. Το άρθρο 92 του Κώδικα Ποινικής Δικονομίας αντικαθίσταται ως εξής: "
                "«Άρθρο 92. Παρίσταται ο «διάδικος» αυτοπροσώπως.» "
                "Άρθρο 2. Το άρθρο 15 του Ποινικού Κώδικα καταργείται."))))

(format t "~%== one act → records split per corpus (only its own ops) ==~%")
(let ((rk (laws->records (list *law*) "kpoinikis"))
      (rp (laws->records (list *law*) "poinikos"))
      (rx (laws->records (list *law*) "astikos")))
  (check "kpoinikis gets exactly one record" (= 1 (length rk)))
  (check "kpoinikis op is replace of art_92 (its ΚΠΔ clause)"
         (let ((o (first (getf (first rk) :operations))))
           (and o (eq (getf o :op) :replace-text) (string= (getf o :target) "art_92"))))
  (check "kpoinikis payload kept the nested «διάδικος» quote"
         (search "«διάδικος»" (getf (first (getf (first rk) :operations)) :text)))
  (check "poinikos op is repeal of art_15 (its ΠΚ clause)"
         (let ((o (first (getf (first rp) :operations))))
           (and o (eq (getf o :op) :repeal) (string= (getf o :target) "art_15"))))
  (check "kpoinikis did NOT get the ΠΚ repeal, poinikos did NOT get the ΚΠΔ replace"
         (and (notany (lambda (o) (string= (getf o :target) "art_15")) (getf (first rk) :operations))
              (notany (lambda (o) (string= (getf o :target) "art_92")) (getf (first rp) :operations))))
  (check "a code the act does not touch gets no record" (null rx)))

(format t "~%== consolidate each code from its AUTO-extracted records ==~%")
(let* ((rk (laws->records (list *law*) "kpoinikis"))
       (rp (laws->records (list *law*) "poinikos"))
       (dk (consolidate-corpus '((92 "παλαιός" "ΠΑΛΑΙΟ κείμενο 92.")) rk))
       (dp (consolidate-corpus '((15 "παλαιός" "ΠΑΛΑΙΟ κείμενο 15.")) rp)))
  (check "ΚΠΔ art_92 now carries the new text"
         (and (search "αυτοπροσώπως" (ptext dk "art_92"))
              (not (search "ΠΑΛΑΙΟ" (ptext dk "art_92")))))
  (check "ΠΚ art_15 is now repealed"
         (eq (orchestrator.consolidation:provision-status
              (orchestrator.consolidation:find-provision dp "art_15"))
             :repealed)))

(format t "~%== point-in-time still holds through the autonomous path ==~%")
(let* ((rk (laws->records (list *law*) "kpoinikis"))
       (before (consolidate-corpus '((92 "π" "ΠΑΛΑΙΟ κείμενο 92.")) rk :as-of-date "2024-01-01"))
       (after  (consolidate-corpus '((92 "π" "ΠΑΛΑΙΟ κείμενο 92.")) rk :as-of-date "2024-12-31")))
  (check "before the effective date → OLD text" (search "ΠΑΛΑΙΟ" (ptext before "art_92")))
  (check "after the effective date → NEW text" (search "αυτοπροσώπως" (ptext after "art_92"))))

(format t "~%========================================~%")
(format t "Autonomy consolidation (text→records→apply): ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
