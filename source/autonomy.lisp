;;;; source/autonomy.lisp
;;;; ============================================================================
;;;; Ο ΑΥΤΟΝΟΜΟΣ ΟΔΗΓΟΣ — στόχος → εκτέλεση → επαλήθευση → ημερολόγιο, μόνος του
;;;; ============================================================================
;;;;
;;;; Το κομμάτι που δένει όσα ήδη υπάρχουν σε ΑΥΤΟΝΟΜΗ εργασία: παίρνει μια ΑΠΟΣΤΟΛΗ
;;;; (στόχος + αντικείμενα + βήμα), τη δουλεύει αντικείμενο-αντικείμενο, ΚΑΘΕ βήμα
;;;; περνά από τον ντετερμινιστικό επαληθευτή του (το βήμα ΕΙΝΑΙ υπεύθυνο να
;;;; επαληθεύει — ο οδηγός δεν εμπιστεύεται, καταγράφει), και σταματά ΜΟΝΟΣ του:
;;;; όταν τελειώσει, όταν εξαντληθεί ο προϋπολογισμός, ή όταν αποτυγχάνει
;;;; συστηματικά (δεν επιμένει στα τυφλά — αναφέρει).
;;;;
;;;; Η σκέψη του είναι ΟΡΑΤΗ (deliberation) και το πέρας ΙΣΤΟΡΙΚΟ (self-history).
;;;; Ο οδηγός είναι ΓΕΝΙΚΟΣ: δεν ξέρει τίποτα για δίκαιο — οι αποστολές ορίζονται
;;;; από τους τομείς (open/closed). Καμία αυτόνομη μετάλλαξη: ό,τι παράγει ένα
;;;; βήμα πηγαίνει σε ΟΥΡΑ ΠΡΟΤΑΣΕΩΝ προς έγκριση, ποτέ κατευθείαν στη γνώση.

(defpackage :orchestrator.autonomy
  (:use :cl)
  (:export #:mission #:define-mission #:find-mission #:all-missions
           #:mission-name #:mission-title #:mission-goal
           #:run-mission))

(in-package :orchestrator.autonomy)

(defclass mission ()
  ((name     :initarg :name     :reader mission-name)     ; keyword
   (title    :initarg :title    :reader mission-title)    ; ανθρώπινος τίτλος
   (goal     :initarg :goal     :reader mission-goal)     ; τι σημαίνει «τελείωσα»
   (items-fn :initarg :items-fn :reader mission-items-fn) ; () → λίστα αντικειμένων
   (step-fn  :initarg :step-fn  :reader mission-step-fn)  ; item → (values status detail)
   ;; status ∈ :accepted (πέρασε επαλήθευση, μπήκε στην ουρά) · :rejected (κόπηκε,
   ;; με λόγο) · :skipped (τίποτα προς εξαγωγή εδώ) — οτιδήποτε άλλο = σφάλμα.
   (max-consecutive-errors :initarg :max-consecutive-errors :initform 3
                           :reader mission-max-consecutive-errors)))

(defvar *missions* (make-hash-table :test 'eq)
  "Μητρώο αποστολών — οι τομείς εγγράφουν, ο οδηγός εκτελεί (open/closed).")

(defun define-mission (name &key title goal items-fn step-fn (max-consecutive-errors 3))
  (check-type name keyword)
  (setf (gethash name *missions*)
        (make-instance 'mission :name name :title title :goal goal
                       :items-fn items-fn :step-fn step-fn
                       :max-consecutive-errors max-consecutive-errors))
  name)

(defun find-mission (name) (gethash name *missions*))
(defun all-missions ()
  (loop for m being the hash-values of *missions* collect m))

(defun %mission-goal-episode (mission)
  "Ο ανοιχτός στόχος-ατζέντας της αποστολής στο υπόστρωμα μνήμης, αν υπάρχει."
  (find-if (lambda (g) (eq (getf (orchestrator.memory:episode-props g) :mission)
                           (mission-name mission)))
           (orchestrator.memory:open-goals)))

(defun run-mission (mission &key limit (resume t) (stream *standard-output*))
  "Εκτέλεσε την αποστολή αυτόνομα. LIMIT: προϋπολογισμός αντικειμένων (nil = όλα).
   RESUME (προεπιλογή): αν υπάρχει ανοιχτός στόχος της ίδιας αποστολής στην
   ΑΤΖΕΝΤΑ, συνέχισε από τον δρομέα του — διακόπηκε, ξύπνησε, ΣΥΝΕΧΙΣΕ. Η πορεία
   γράφεται στη μνήμη (στόχος+δρομέας), ώστε καμία δουλειά να μη χάνεται σιωπηλά.
   Επιστρέφει plist-αναφορά: :processed :accepted :rejected :skipped :errors
   :aborted-p :journal. Η πορεία τυπώνεται ζωντανά."
  (let* ((items (funcall (mission-items-fn mission)))
         (total (length items))
         (goal (and resume (%mission-goal-episode mission)))
         (cursor (or (and goal (getf (orchestrator.memory:episode-props goal) :progress)) 0))
         (cursor (min cursor total))
         (budget (min (if limit (+ cursor limit) total) total))
         (goal-id (if goal (orchestrator.memory:episode-id goal)
                      (orchestrator.memory:episode-id
                       (orchestrator.memory:record-goal
                        (format nil "~A — ~A" (mission-title mission) (mission-goal mission))
                        :props (list :mission (mission-name mission) :progress 0)))))
         (processed 0) (accepted 0) (rejected 0) (skipped 0) (errors 0)
         (consecutive 0) (aborted nil) (journal '()))
    (orchestrator.deliberation:think 'orchestrator.deliberation:note
     "ΑΠΟΣΤΟΛΗ «~A»: ~D αντικείμενα, ~:[από την αρχή~;ΣΥΝΕΧΙΣΗ από ~:*~D~]. Στόχος: ~A"
     (mission-title mission) total (and goal (plusp cursor) cursor) (mission-goal mission))
    (format stream "~%── ΑΥΤΟΝΟΜΗ ΑΠΟΣΤΟΛΗ: ~A ──~%   στόχος: ~A~%   αντικείμενα: ~D~@[ (όριο ~D)~]~@[~%   ⟳ συνέχιση από τον δρομέα της ατζέντας: ~D~]~%"
            (mission-title mission) (mission-goal mission) total limit
            (and goal (plusp cursor) cursor))
    (dolist (item (subseq items cursor budget))
      (multiple-value-bind (status detail)
          (handler-case (funcall (mission-step-fn mission) item)
            (error (e) (values :error (format nil "~A" e))))
        (incf processed)
        (case status
          (:accepted (incf accepted) (setf consecutive 0))
          (:rejected (incf rejected) (setf consecutive 0))
          (:skipped  (incf skipped)  (setf consecutive 0))
          (t (incf errors) (incf consecutive)
             (orchestrator.deliberation:think 'orchestrator.deliberation:rejection
              "σφάλμα βήματος (~A): ~A" item detail)))
        (push (list item status detail) journal)
        ;; δρομέας στην ατζέντα κάθε 25 αντικείμενα — φθηνό, ανθεκτικό σε διακοπή
        (when (zerop (mod processed 25))
          (orchestrator.memory:update-goal goal-id :progress (+ cursor processed)))
        ;; Δεν επιμένει στα τυφλά: συστηματική αποτυχία ⇒ στάση + αναφορά.
        (when (>= consecutive (mission-max-consecutive-errors mission))
          (setf aborted t)
          (orchestrator.deliberation:think 'orchestrator.deliberation:rejection
           "ΣΤΑΣΗ: ~D συνεχόμενα σφάλματα — η αποστολή διακόπτεται, δεν μαντεύω."
           consecutive)
          (return))))
    ;; η ατζέντα κλείνει ΜΟΝΟ όταν καλύφθηκαν όλα· αλλιώς μένει ανοιχτή με δρομέα
    (let ((reached (+ cursor processed)))
      (if (and (not aborted) (>= reached total))
          (orchestrator.memory:update-goal goal-id :status :done :progress reached
            :note (format nil "ολοκληρώθηκε: ~D αντικείμενα" total))
          (orchestrator.memory:update-goal goal-id :progress reached
            :note (if aborted "διακόπηκε σε συστηματική αποτυχία" "όριο προϋπολογισμού"))))
    (format stream "~%   επεξεργάστηκαν: ~D/~D~@[ (σύνολο ~D/~D)~]~%   ✓ στην ουρά προτάσεων: ~D~%   ✗ απορρίφθηκαν από τον επαληθευτή: ~D~%   ∅ χωρίς εύρημα: ~D~%   ⚠ σφάλματα: ~D~@[~%   ΔΙΑΚΟΠΗΚΕ (συστηματική αποτυχία)~]~%"
            processed (- budget cursor) (and (plusp cursor) (+ cursor processed))
            (and (plusp cursor) total) accepted rejected skipped errors aborted)
    ;; Ιστορική μαρτυρία ΜΟΝΟ όταν παράχθηκε νέα (προς έγκριση) γνώση.
    (when (and (not aborted) (plusp accepted))
      (orchestrator.self-history:record! :milestone
       (format nil "Αυτόνομη αποστολή «~A»: ~D/~D αντικείμενα, ~D επαληθευμένες προτάσεις στην ουρά έγκρισης."
               (mission-title mission) (+ cursor processed) total accepted)))
    (list :processed processed :accepted accepted :rejected rejected
          :skipped skipped :errors errors :aborted-p aborted
          :journal (nreverse journal))))
