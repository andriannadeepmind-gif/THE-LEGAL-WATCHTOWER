;;;; source/legal-temporal.lisp
;;;; ============================================================================
;;;; BRAIN L3 — TEMPORAL LEGAL REASONING (point-in-time law)
;;;; ============================================================================
;;;;
;;;; L1 derives consequences; L2 resolves conflicts; L3 answers the question a court
;;;; asks most: WHAT WAS THE LAW IN FORCE ON DATE D — and which version governs an act
;;;; that happened at a given time. Law is not a snapshot: each provision is a timeline
;;;; of versions (original → amended → re-amended → repealed), and a repealed provision
;;;; may still govern acts done while it was in force (ULTRA-ACTIVITY / survival), while
;;;; a new one may apply RETROACTIVELY. L3 models this precisely and provably.
;;;;
;;;; Golden-standard foundations:
;;;;   ✓ A proper INTERVAL CALCULUS — half-open validity intervals [from, to) and the
;;;;     thirteen ALLEN relations, so version timelines are reasoned about exactly.
;;;;   ✓ ISO-8601 dates compared as strings (lexicographic order = chronological order
;;;;     for YYYY-MM-DD), so no lossy date parsing enters the trusted path; NIL bounds
;;;;     mean −∞ / +∞.
;;;;   ✓ POINT-IN-TIME reconstruction with a proof (the interval that selects a version
;;;;     is the justification), plus detection of temporal GAPS (a period governed by no
;;;;     version) and OVERLAPS (two versions in force at once) — real consistency checks.
;;;;   ✓ Ultra-activity as a DEFEASIBLE rule on the well-founded engine: a provision that
;;;;     was in force when an act occurred governs that act UNLESS it was retroactively
;;;;     abolished — expressed with :unless, carrying a JTMS proof.
;;;;
;;;; Pure core (operates on version lists). A thin bridge lifts the consolidation
;;;; ledger's amendment events into TEMPORAL-VERSIONs; no ledger logic is duplicated.

(defpackage :orchestrator.temporal
  (:use :cl :orchestrator.inference)
  (:export #:date<= #:date< #:date-in-interval-p #:allen-relation #:date-plus-days
           #:temporal-version #:make-temporal-version
           #:tv-code #:tv-article #:tv-version #:tv-from #:tv-to #:tv-source #:tv-digest
           #:tv-active-at #:versions-in-force-at #:point-in-time #:point-in-time-proof
           #:temporal-anomalies #:in-force-facts))

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

;;; ============================================================================
;;; DATES & INTERVALS — ISO-8601 lexicographic order; half-open [from, to)
;;; ============================================================================

(defun date<= (a b) (string<= a b))
(defun date<  (a b) (string<  a b))

(defun date-in-interval-p (d from to)
  "T iff date D lies in the half-open interval [FROM, TO). NIL FROM = −∞, NIL TO = +∞.
   Half-open so consecutive versions [.. a)[a ..) tile time with neither gap nor overlap."
  (and d
       (or (null from) (date<= from d))
       (or (null to)   (date<  d to))))

;;; --- Allen's interval algebra: the exact relation between two intervals -------
;;; Intervals are (FROM . TO) with NIL = open. The thirteen relations reduce, for
;;; anomaly work, to whether two version-intervals of one provision meet, gap, or overlap.

(defun %lo<= (a b)   ; a,b are lower bounds (nil = -inf)
  (cond ((null a) t) ((null b) nil) (t (date<= a b))))
(defun %hi<= (a b)   ; a,b are upper bounds (nil = +inf)
  (cond ((null a) nil) ((null b) t) (t (date<= a b))))
(defun %hi<lo (hi lo)  ; upper bound HI strictly before lower bound LO
  (and hi lo (date< hi lo)))

(defun allen-relation (i1 i2)
  "The Allen relation of interval I1 to I2 (each a (FROM . TO) cons). Returns one of
   :before :meets :overlaps :starts :during :finishes :equal (and their inverses with
   an -I suffix). Used to classify how two version intervals relate on the timeline."
  (destructuring-bind (f1 . t1) i1
    (destructuring-bind (f2 . t2) i2
      (cond
        ((%hi<lo t1 f2) :before)
        ((%hi<lo t2 f1) :before-i)
        ((and t1 f2 (equal t1 f2)) :meets)
        ((and t2 f1 (equal t2 f1)) :meets-i)
        ((and (equal f1 f2) (equal t1 t2)) :equal)
        ((and (equal f1 f2) (%hi<= t1 t2)) :starts)
        ((and (equal f1 f2)) :starts-i)
        ((and (equal t1 t2) (%lo<= f2 f1)) :finishes)
        ((and (equal t1 t2)) :finishes-i)
        ((and (%lo<= f2 f1) (%hi<= t1 t2)) :during)
        ((and (%lo<= f1 f2) (%hi<= t2 t1)) :during-i)
        (t :overlaps)))))

;;; ============================================================================
;;; TEMPORAL VERSIONS — a provision's timeline
;;; ============================================================================

(defstruct (temporal-version (:conc-name tv-)
            (:constructor make-temporal-version
                (&key code article version from to source digest)))
  code       ; corpus id
  article    ; article id (string)
  version    ; version id / label
  from       ; in-force-from (ISO date, or NIL = from the beginning)
  to         ; in-force-to   (ISO date exclusive, or NIL = still in force)
  source     ; the act that produced this version (e.g. "4335/2015")
  digest)    ; SHA-256 of the version's text (ties L3 to the proof layer)

(defun tv-active-at (v date)
  "T iff version V is in force at DATE."
  (date-in-interval-p date (tv-from v) (tv-to v)))

(defun %provision-key (v) (cons (tv-code v) (tv-article v)))

(defun versions-in-force-at (versions code article date)
  "Every version of CODE/ARTICLE in force at DATE — normally exactly one. Zero ⇒ a
   temporal GAP; more than one ⇒ an OVERLAP (both surfaced by TEMPORAL-ANOMALIES)."
  (loop for v in versions
        when (and (equal (tv-code v) code) (equal (tv-article v) article)
                  (tv-active-at v date))
        collect v))

(defun point-in-time (versions date)
  "The in-force version of every provision at DATE, as a list of TEMPORAL-VERSIONs
   (one per provision that has a version active then). This is the consolidated corpus
   AS OF DATE — the point-in-time snapshot."
  (let ((seen (make-hash-table :test 'equal)) (out '()))
    (dolist (v versions (nreverse out))
      (let ((k (%provision-key v)))
        (when (and (tv-active-at v date) (not (gethash k seen)))
          (setf (gethash k seen) t)
          (push v out))))))

(defun point-in-time-proof (versions code article date)
  "The proof that a given version governs CODE/ARTICLE at DATE: the selected version
   and the interval that makes it in force (or an :anomaly verdict). Homoiconic — data."
  (let ((hits (versions-in-force-at versions code article date)))
    (cond ((null hits)
           (list :anomaly :temporal-gap :code code :article article :as-of date))
          ((cdr hits)
           (list :anomaly :temporal-overlap :code code :article article :as-of date
                 :versions (mapcar #'tv-version hits)))
          (t (let ((v (first hits)))
               (list :in-force :code code :article article :as-of date
                     :version (tv-version v) :interval (cons (tv-from v) (tv-to v))
                     :source (tv-source v) :digest (tv-digest v)))))))

;;; ============================================================================
;;; TEMPORAL ANOMALIES — gaps and overlaps in a provision's timeline
;;; ============================================================================

(defun %sort-versions (vs)
  "Versions of one provision ordered by lower bound (NIL first)."
  (stable-sort (copy-list vs)
               (lambda (a b)
                 (cond ((null (tv-from a)) t) ((null (tv-from b)) nil)
                       (t (date< (tv-from a) (tv-from b)))))))

(defun temporal-anomalies (versions)
  "Every gap and overlap across all provision timelines. A GAP is a period governed by
   no version between two consecutive ones; an OVERLAP is two versions in force at once.
   Returns a list of (:gap|:overlap CODE ART V-BEFORE V-AFTER)."
  (let ((by-prov (make-hash-table :test 'equal)) (out '()))
    (dolist (v versions)
      (push v (gethash (%provision-key v) by-prov)))
    (maphash
     (lambda (key vs)
       (let ((sorted (%sort-versions vs)))
         (loop for (a b) on sorted while b
               for rel = (allen-relation (cons (tv-from a) (tv-to a))
                                         (cons (tv-from b) (tv-to b)))
               do (case rel
                    ((:before)                 ; a strictly before b → possible gap
                     (when (%hi<lo (tv-to a) (tv-from b))
                       (push (list :gap (car key) (cdr key) (tv-version a) (tv-version b)) out)))
                    ((:meets))                 ; perfect tiling — fine
                    (t                         ; overlaps/during/equal/… → overlap
                     (push (list :overlap (car key) (cdr key) (tv-version a) (tv-version b)) out))))))
     by-prov)
    (nreverse out)))

;;; ============================================================================
;;; BRIDGE TO THE ENGINE — temporal facts + a defeasible ultra-activity rule
;;; ============================================================================

(defun in-force-facts (versions date)
  "Compile the point-in-time snapshot at DATE into engine facts
   (:in-force CODE ART VERSION), so the defeasible temporal rules below can reason
   about survival/retroactivity for that as-of date."
  (loop for v in (point-in-time versions date)
        collect (list :in-force (tv-code v) (tv-article v) (tv-version v))))

;; ULTRA-ACTIVITY (survival): a provision that was in force when an act occurred governs
;; that act EVEN AFTER it is repealed — UNLESS it was abolished with retroactive effect.
;; The classic tempus regit actum, expressed defeasibly on the well-founded engine.
(defrule ultra-activity-governs-past-act
  :when   ((:act-occurred ?code ?art ?act-date)
           (:was-in-force-at ?code ?art ?act-date))
  :unless ((:retroactively-abolished ?code ?art))
  :then   (:governs ?code ?art :act-on ?act-date :by tempus-regit-actum))
