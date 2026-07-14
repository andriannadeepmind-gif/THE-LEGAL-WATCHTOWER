;;;; source/legal-temporal.lisp
;;;; ============================================================================
;;;; ΗΜΕΡΟΛΟΓΙΑΚΗ ΑΡΙΘΜΗΤΙΚΗ ΗΜΕΡΟΜΗΝΙΩΝ — η ΜΙΑ έδρα (προθεσμίες Σ9, validity)
;;;; ============================================================================
;;;;
;;;; [0088 Φ6 — ΘΑΝΑΤΟΣ ΤΗΣ L3 VERSIONING ΜΗΧΑΝΗΣ]: το παλιό «BRAIN L3
;;;; point-in-time law» (temporal-version/versions-in-force-at/point-in-time/
;;;; temporal-anomalies/in-force-facts/allen-relation + defeasible ultra-activity
;;;; rule) ΔΙΑΓΡΑΦΗΚΕ με grep-gate 0 καταναλωτών: η διτεμπορική σημασιολογία
;;;; (valid×recorded, εκδόσεις, κενά, point-in-time με απόδειξη) έχει πλέον ΜΙΑ
;;;; έδρα — τον διτεμπορικό γράφο orchestrator.version-graph (journal-backed,
;;;; full-record chain, typed legal-date/legal-instant). Δύο παράλληλες
;;;; οντολογίες «έκδοση/ισχύς» ήταν η κλάση σφάλματος TEMP-* — δεν φρουρείται,
;;;; εξαλείφεται.
;;;;
;;;; Ό,τι μένει εδώ είναι ΔΙΑΦΟΡΕΤΙΚΗ έννοια: καθαρή ημερολογιακή αριθμητική
;;;; πάνω σε ISO-8601 ημερομηνίες (προσθήκη ημερών για προθεσμίες, μισάνοιχτα
;;;; διαστήματα εγκυρότητας). Καταναλωτές: legal-strategy (Σ9 προθεσμίες),
;;;; knowledge-graph (validity intervals). Για ΣΤΙΓΜΕΣ/συγκρίσεις νομικού
;;;; χρόνου με τύπο, η έδρα είναι το version-graph (legal-instant, %time-key).

(defpackage :orchestrator.temporal
  (:use :cl)
  (:export #:date<= #:date< #:date-in-interval-p #:date-plus-days))

(in-package :orchestrator.temporal)

(defun date-plus-days (iso-date days)
  "Η ISO-8601 ημερομηνία DAYS ημέρες μετά την ISO-DATE — η ΜΙΑ ημερολογιακή
   αριθμητική του συστήματος (για προθεσμίες: Σ9). Ντετερμινιστική (UTC)."
  (multiple-value-bind (y m d)
      (values (parse-integer iso-date :start 0 :end 4)
              (parse-integer iso-date :start 5 :end 7)
              (parse-integer iso-date :start 8 :end 10))
    (multiple-value-bind (sec min hr day mon yr)
        (decode-universal-time
         (+ (encode-universal-time 0 0 12 d m y 0) (* days 86400)) 0)
      (declare (ignore sec min hr))
      (format nil "~4,'0D-~2,'0D-~2,'0D" yr mon day))))

;;; Σύγκριση ISO-8601 ημερομηνιών: για έγκυρες YYYY-MM-DD η λεξικογραφική
;;; σειρά ΤΑΥΤΙΖΕΤΑΙ με τη χρονολογική — εδώ δεν μπαίνει lossy parsing στο
;;; trusted path. (Η ΕΠΙΚΥΡΩΣΗ μορφής είναι ευθύνη της typed έδρας
;;; version-graph:legal-date-p, όχι αυτής της αριθμητικής.)
(defun date<= (a b) (string<= a b))
(defun date<  (a b) (string<  a b))

(defun date-in-interval-p (d from to)
  "T iff date D lies in the half-open interval [FROM, TO). NIL FROM = −∞, NIL TO = +∞.
   Half-open so consecutive intervals [.. a)[a ..) tile time with neither gap nor overlap."
  (and d
       (or (null from) (date<= from d))
       (or (null to)   (date<  d to))))
