;;;; source/legal-precedent.lisp
;;;; ============================================================================
;;;; BRAIN L4 — ΔΕΔΙΚΑΣΜΕΝΟ ΚΑΙ ΧΡΟΝΟΣ: precedent reasoning over the JTMS
;;;; ============================================================================
;;;;
;;;; Η κληρονομιά των Lisp machines, στην δουλειά της: η νομολογία μπαίνει στον
;;;; ΙΔΙΟ non-monotonic JTMS που τρέχει τους κώδικες, και κάθε συμπέρασμα για
;;;; την ισχύ ενός δεδικασμένου βγαίνει ΜΕ ΤΟ ΔΕΝΤΡΟ ΑΠΟΔΕΙΞΗΣ ΤΟΥ — όχι ως
;;;; σκέτη σημαία σε JSON. Defeasible από κατασκευής: ο κανόνας «η κρίση
;;;; χρειάζεται επανεξέταση γιατί η διάταξη άλλαξε μετά την απόφαση» ισχύει
;;;; ΕΚΤΟΣ ΑΝ μεταγενέστερη απόφαση την επιβεβαίωσε επί του νέου κειμένου —
;;;; μόλις τέτοιο γεγονός μπει στο σύστημα, το συμπέρασμα αποσύρεται ΜΟΝΟ ΤΟΥ
;;;; (truth maintenance), με το ίδιο well-founded fixpoint που αποδείχθηκε
;;;; ορθό στους κώδικες. Καμία νέα μηχανή — μόνο νέοι δηλωτικοί κανόνες.
;;;;
;;;; Λεξιλόγιο γεγονότων (τα φορτώνει η γέφυρα από τα materialized decisions):
;;;;   (:cites DEC CORPUS ART)        — η απόφαση εφαρμόζει την διάταξη
;;;;   (:amended-since CORPUS ART DEC)— η διάταξη τροποποιήθηκε ΜΕΤΑ την απόφαση
;;;;   (:same-text CORPUS ART DEC)    — αποδεδειγμένα το ίδιο κείμενο (ημερομηνίες)
;;;;   (:reaffirmed-on-current DEC2 CORPUS ART) — μεταγενέστερη απόφαση επι-
;;;;      βεβαίωσε την κρίση επί του ΙΣΧΥΟΝΤΟΣ κειμένου (defeater, μελλοντικό)
;;;;
;;;; Παράγωγα (πάντα με απόδειξη):
;;;;   (:precedent-review DEC CORPUS ART)  — «ελέγξτε αν η κρίση διατηρεί ισχύ»
;;;;   (:precedent-current DEC CORPUS ART) — «η κρίση πατά σε αμετάβλητο κείμενο»

(defpackage :orchestrator.precedent
  (:use :cl :orchestrator.inference)
  (:export #:decision-facts #:precedent-report))

(in-package :orchestrator.precedent)

;; Η διάταξη άλλαξε μετά την απόφαση ⇒ το δεδικασμένο χρειάζεται επανεξέταση —
;; ΕΚΤΟΣ ΑΝ μεταγενέστερη απόφαση το επιβεβαίωσε επί του ισχύοντος κειμένου.
;; Το :unless είναι το σημείο όπου το σύστημα ΑΛΛΑΖΕΙ ΓΝΩΜΗ μόνο του όταν
;; μάθει περισσότερα — αυτό είναι truth maintenance, όχι ετικέτα.
;; ΥΠΑΡΞΙΑΚΟΣ defeater ΡΗΤΑ (εύρημα επιθεώρησης 05-07-2026): το παλαιό
;; :unless (:reaffirmed-on-current ?d2 …) με ΑΔΕΣΜΕΥΤΗ ?d2 ήταν ΝΕΚΡΟ —
;; η μηχανή στιγμιοποιεί defeaters με τη δέσμευση, άρα δεν πυροδοτούσε ποτέ.
;; Η ύπαρξη «κάποιας d2» γίνεται παράγωγο γεγονός και ο defeater δένεται εκεί.
(defrule precedent-reaffirmation-exists
  :when ((:reaffirmed-on-current ?d2 ?c ?a))
  :then (:reaffirmed-exists ?c ?a))

(defrule precedent-needs-review
  :when   ((:cites ?d ?c ?a)
           (:amended-since ?c ?a ?d))
  :unless ((:reaffirmed-exists ?c ?a))
  :then   (:precedent-review ?d ?c ?a))

;; Το κείμενο αποδεδειγμένα αμετάβλητο από την απόφαση έως σήμερα ⇒ η κρίση
;; πατά στο ίδιο ακριβώς γράμμα του νόμου που σερβίρεται.
(defrule precedent-on-current-text
  :when ((:cites ?d ?c ?a)
         (:same-text ?c ?a ?d))
  :then (:precedent-current ?d ?c ?a))

;; ── Ο ΑΞΟΝΑΣ ΤΗΣ ΠΡΑΞΗΣ (ουσιαστικό δίκαιο, tempus regit actum) ──
;; Η διάταξη τροποποιήθηκε ΜΕΣΑ στο παράθυρο τέλεση→κρίση. Σε ΠΟΙΝΙΚΗ υπόθεση
;; ενεργοποιείται το άρθρο 2 ΠΚ (lex mitior: εφαρμοστέος ο επιεικέστερος) — η
;; κρίση βγαίνει ΜΕ την απόδειξή της, όχι ως ετικέτα.
(defrule lex-mitior-applies
  :when ((:cites ?d ?c ?a)
         (:amended-in-window ?c ?a ?d)
         (:penal ?d))
  :then (:lex-mitior ?d ?c ?a))

;; Ίδια τροποποίηση-εντός-παραθύρου σε ΜΗ ποινική υπόθεση: καθαρό tempus regit
;; actum — διέπει η έκδοση του χρόνου τέλεσης, χωρίς την εξαίρεση του 2 ΠΚ.
(defrule act-time-law-governs
  :when   ((:cites ?d ?c ?a)
           (:amended-in-window ?c ?a ?d))
  :unless ((:penal ?d))
  :then   (:act-time-law ?d ?c ?a))

;; Κείμενο αμετάβλητο από ΠΡΙΝ την πράξη έως σήμερα ⇒ το σερβιριζόμενο γράμμα
;; ΕΙΝΑΙ το ουσιαστικό δίκαιο της πράξης, αποδεδειγμένα.
(defrule law-of-the-act-is-current
  :when ((:cites ?d ?c ?a)
         (:same-since-act ?c ?a ?d))
  :then (:law-of-act-current ?d ?c ?a))

(defun decision-facts (decision-id citations)
  "Lift one materialized decision's citations into engine facts. CITATIONS is
   a list of plists (:corpus C :article A :verdict V :act-verdict AV :penal P) —
   the verdicts the CLI already computed deterministically from the per-article
   version dates, the act date, and the penal flag. Two axes, same JTMS."
  (let ((facts '()) (penal-done nil))
    (dolist (c citations (nreverse facts))
      (let ((corpus (getf c :corpus)) (art (getf c :article)))
        (when corpus
          (push (list :cites decision-id corpus art) facts)
          ;; ο άξονας δεδικασμένου (κρίση vs σημερινό κείμενο)
          (case (getf c :verdict)
            (:amended-after (push (list :amended-since corpus art decision-id) facts))
            (:same-text-proven (push (list :same-text corpus art decision-id) facts)))
          ;; ο άξονας πράξης (ουσιαστικό δίκαιο του χρόνου τέλεσης)
          (case (getf c :act-verdict)
            (:lex-mitior-check (push (list :amended-in-window corpus art decision-id) facts))
            (:amended-since-act (push (list :amended-in-window corpus art decision-id) facts))
            (:same-since-act (push (list :same-since-act corpus art decision-id) facts)))
          ;; η ποινική φύση μπαίνει ΜΙΑ φορά — προϋπόθεση του 2 ΠΚ
          (when (and (getf c :penal) (not penal-done))
            (push (list :penal decision-id) facts)
            (setf penal-done t)))))))

(defun precedent-report (decision-id citations &optional (stream *standard-output*))
  "Run the precedent rules over one decision and print every verdict WITH its
   JTMS proof tree. Returns (values n-review n-current)."
  (let ((engine (make-inference-engine)))
    (add-facts engine (decision-facts decision-id citations))
    (run-inference engine)
    (let ((review (query engine (list :precedent-review decision-id '?c '?a)))
          (current (query engine (list :precedent-current decision-id '?c '?a))))
      (format stream "~%── ΔΕΔΙΚΑΣΜΕΝΟ ~A: ~D προς επανεξέταση · ~D επί ισχύοντος κειμένου ──~%"
              decision-id (length review) (length current))
      (loop for (fact . nil) in review do
        (format stream "~%  ⚠ ~A άρθρο ~A — ελέγξτε αν η κρίση διατηρεί ισχύ~%~A~%"
                (third fact) (fourth fact)
                (explanation->string (explain (engine-jtms engine) fact) 6)))
      (loop for (fact . nil) in current do
        (format stream "  ✓ ~A άρθρο ~A — αποδεδειγμένα το ίδιο κείμενο~%"
                (third fact) (fourth fact)))
      ;; ── ο άξονας της ΠΡΑΞΗΣ, κάθε κρίση ΜΕ την απόδειξή της ──
      (let ((mitior  (query engine (list :lex-mitior decision-id '?c '?a)))
            (acttime (query engine (list :act-time-law decision-id '?c '?a)))
            (ofact   (query engine (list :law-of-act-current decision-id '?c '?a))))
        (when (or mitior acttime ofact)
          (format stream "~%── ΟΥΣΙΑΣΤΙΚΟ ΔΙΚΑΙΟ ΤΗΣ ΠΡΑΞΗΣ ~A ──~%" decision-id))
        (loop for (fact . nil) in mitior do
          (format stream "~%  ⚖ ~A άρθρο ~A — ΑΡΘΡΟ 2 ΠΚ: εφαρμοστέος ο επιεικέστερος (τροποποίηση εντός τέλεση→κρίση)~%~A~%"
                  (third fact) (fourth fact)
                  (explanation->string (explain (engine-jtms engine) fact) 6)))
        (loop for (fact . nil) in acttime do
          (format stream "~%  ⧗ ~A άρθρο ~A — διέπει η έκδοση του χρόνου τέλεσης (tempus regit actum)~%~A~%"
                  (third fact) (fourth fact)
                  (explanation->string (explain (engine-jtms engine) fact) 6)))
        (loop for (fact . nil) in ofact do
          (format stream "  ⧗ ~A άρθρο ~A — το ισχύον κείμενο ΕΙΝΑΙ το δίκαιο της πράξης~%"
                  (third fact) (fourth fact)))
        (values (length review) (length current)
                (length mitior) (length acttime))))))
