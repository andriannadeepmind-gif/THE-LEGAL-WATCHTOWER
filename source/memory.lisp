;;;; source/memory.lisp
;;;; ============================================================================
;;;; ΤΟ ΥΠΟΣΤΡΩΜΑ ΜΝΗΜΗΣ — ένα ρεύμα επεισοδίων, πέντε ικανότητες
;;;; ============================================================================
;;;;
;;;; Ό,τι το σύστημα ΖΕΙ (όχι ό,τι ξέρει — αυτό το κρατά ο γράφος γνώσης) γίνεται
;;;; ΕΠΕΙΣΟΔΙΟ σε ΕΝΑ append-only ημερολόγιο, με αλυσίδα SHA-256 όπως η βιογραφία.
;;;; Πάνω σε ΑΥΤΟ το ένα υπόστρωμα ζουν, ως λεπτά APIs (καμία δεύτερη αποθήκη):
;;;;
;;;;   1. ΕΠΕΙΣΟΔΙΑΚΗ    — record-episode / episodes / recent / find-episodes
;;;;   2. ΣΥΝΟΜΙΛΙΑΚΗ    — τα πρόσφατα :interaction της τρέχουσας συνεδρίας
;;;;   3. ΑΤΖΕΝΤΑ        — επεισόδια :goal με κατάσταση+δρομέα (fold: το ΤΕΛΕΥΤΑΙΟ
;;;;                       γεγονός ανά id νικά — ίδιο ιδίωμα με τις προτάσεις)·
;;;;                       ο αυτόνομος οδηγός διακόπτεται και ΣΥΝΕΧΙΖΕΙ
;;;;   4. ΠΡΟΘΕΤΙΚΗ      — επεισόδια :intention (οπλισμένες σκανδάλες): «όταν
;;;;                       συμβεί Χ κάνε Υ» — μητρώο συνθηκών open/closed,
;;;;                       fire-due-intentions όπου φτάνει νέα πραγματικότητα
;;;;   5. ΠΕΡΙΠΤΩΣΕΩΝ    — similar-episodes: ανάκληση ομοίων μέσω ΛΗΜΜΑΤΩΝ
;;;;                       (η ίδια γλωσσική έδρα — καμία δεύτερη γλωσσολογία)
;;;;
;;;; Αναλλοίωτα (ίδια με όλο το σύστημα): append-only (τίποτα δεν σβήνεται —
;;;; οι «αλλαγές» είναι νέα γεγονότα ίδιου id)· κάθε επεισόδιο με χρόνο και
;;;; αλυσίδα· runtime κατάσταση του ΑΝΤΙΤΥΠΟΥ (gitignored), όχι του repo.
;;;; Διάκριση από τα lessons: το lessons.jsonl είναι το ρεύμα ΑΝΑΣΤΟΧΑΣΜΟΥ
;;;; (αποτυχίες προς ριζική διόρθωση)· εδώ είναι το ΒΙΩΜΑΤΙΚΟ ρεύμα (ό,τι έζησε).

(defpackage :orchestrator.memory
  (:use :cl)
  (:export #:*episodes-path* #:episodes-path #:*session*
           #:record-episode #:episodes #:recent-episodes #:find-episodes
           #:episode-id #:episode-kind #:episode-text #:episode-topic
           #:episode-status #:episode-props #:episode-at #:episode-session
           #:episode-lemmas
           #:verify-episode-chain
           ;; ατζέντα
           #:record-goal #:update-goal #:open-goals #:find-goal
           ;; προθετική
           #:register-intention-condition #:arm-intention #:armed-intentions
           #:fire-due-intentions
           ;; περιπτώσεις
           #:similar-episodes))

(in-package :orchestrator.memory)

(orchestrator.paths:define-store-path episodes-path *episodes-path*
  "deployment/self/episodes.sexp" "Hot-path ρεύμα επεισοδίων (gitignored).")

(defvar *session*
  (format nil "s~36R" (get-universal-time))
  "Ταυτότητα της τρέχουσας συνεδρίας — δένει τα επεισόδια μιας ζωής της διεργασίας.")

;;; ── Το γεγονός στο ημερολόγιο — από το ΕΝΑ ιδίωμα (orchestrator.journal) ──

(defun %now () (orchestrator.journal:iso-now))
(defun %sha256 (s) (orchestrator.journal:sha256-hex s))
(defun %events () (orchestrator.journal:read-lines (episodes-path)))

;; Η ουρά της αλυσίδας ζει στον ΕΝΑΝ συγγραφέα (journal) — καμία ανάγνωση
;; όλου του αρχείου ανά εγγραφή, καμία δεύτερη cache εδώ.

;;; ── Πρόσβαση επεισοδίου (plist accessors — το γεγονός ΕΙΝΑΙ το επεισόδιο) ──
(defun episode-id      (e) (getf e :id))
(defun episode-kind    (e) (getf e :kind))
(defun episode-text    (e) (getf e :text))
(defun episode-topic   (e) (getf e :topic))
(defun episode-status  (e) (getf e :status))
(defun episode-props   (e) (getf e :props))
(defun episode-at      (e) (getf e :at))
(defun episode-session (e) (getf e :session))
(defun episode-lemmas  (e) (getf e :lemmas))

(defun %lemma-set (text)
  "Τα γνωστά λήμματα του TEXT — η ΜΙΑ γλωσσική έδρα (καμία δεύτερη γλωσσολογία)."
  (remove-duplicates
   (remove nil (mapcar #'orchestrator.citation-authority:known-lemma
                       (orchestrator.citation-authority:tokenize-greek text)))
   :test #'string=))

(defun record-episode (kind text &key topic props status id)
  "Κατέγραψε ΕΝΑ επεισόδιο στο βιωματικό ρεύμα — ό,τι ζω γίνεται γεγονός με χρόνο, λήμματα και αλυσίδα.
   KIND keyword (:interaction/:goal/:intention/:observation…),
   TEXT η μαρτυρία, TOPIC λίστα λημμάτων/αναφορών (πχ (\"νόμος\" \"art:poinikos:380\")),
   STATUS προαιρετική κατάσταση, ID για ΣΥΝΕΧΙΣΗ υπάρχοντος (fold: το τελευταίο
   γεγονός ανά id νικά). Επιστρέφει το γεγονός (με :id/:hash).
   Τα ΛΗΜΜΑΤΑ του κειμένου αποθηκεύονται ΣΤΟ γεγονός (Φάση 1): η ανάκληση
   ομοίων δεν ξαναλημματοποιεί όλο το ρεύμα σε κάθε ερώτημα."
  (check-type kind keyword)
  (check-type text string)
  ;; λημματοποίηση + ρολόι ΠΡΙΝ το κλείδωμα — ο ένας-συγγραφέας δεν σειριοποιεί
  ;; γλωσσική εργασία, μόνο την πράξη της αλυσίδας
  (let ((at (%now))
        (lemmas (%lemma-set text)))
    ;; ΑΤΟΜΙΚΗ πράξη αλυσίδας στον ΕΝΑΝ συγγραφέα: κανένα δεύτερο νήμα δεν
    ;; μπορεί να χτίσει πάνω στο ίδιο :prev — η αλυσίδα μένει αληθινή.
    (orchestrator.journal:chained-append
     (episodes-path)
     (lambda (tail)
       (let* ((prev (if tail (getf tail :hash) (make-string 64 :initial-element #\0)))
              ;; 16 hex (64 bits — τα 12 hex συγκρούονται πολύ νωρίτερα)· το PREV
              ;; μέσα στην ταυτότητα ⇒ μοναδική ανά θέση αλυσίδας, ντετερμινιστική
              (eid (or id (subseq (%sha256 (format nil "~A|~A|~A|~A" kind text at prev)) 0 16)))
              (body (list :at at :session *session* :id eid :kind kind :text text
                          :topic topic :status status :props props :lemmas lemmas
                          :prev prev))
              (hash (%sha256 (let ((*print-pretty* nil)) (format nil "~S" body)))))
         (append body (list :hash hash)))))))

(defun episodes (&key kind session (fold t))
  "Τα επεισόδια, με προαιρετικό φίλτρο είδους/συνεδρίας. FOLD (προεπιλογή): ένα
   ανά id — το ΤΕΛΕΥΤΑΙΟ του γεγονός (η τρέχουσα κατάστασή του)."
  (let ((es (%events)))
    (when kind (setf es (remove kind es :key #'episode-kind :test-not #'eq)))
    (when session (setf es (remove session es :key #'episode-session :test-not #'equal)))
    (if (not fold)
        es
        (let ((h (make-hash-table :test 'equal)) (order '()))
          (dolist (e es)
            (let ((id (episode-id e)))
              (unless (gethash id h) (push id order))
              (setf (gethash id h) e)))
          (mapcar (lambda (id) (gethash id h)) (nreverse order))))))

(defun recent-episodes (n &key kind session)
  "Τα Ν πιο πρόσφατα (νεότερο πρώτο)."
  (let ((es (episodes :kind kind :session session)))
    (subseq (reverse es) 0 (min n (length es)))))

(defun find-episodes (&key kind status topic-includes)
  "Αναζήτηση: είδος, κατάσταση, ή/και θέμα (ένα στοιχείο του :topic)."
  (remove-if-not
   (lambda (e)
     (and (or (null kind) (eq (episode-kind e) kind))
          (or (null status) (eq (episode-status e) status))
          (or (null topic-includes)
              (member topic-includes (episode-topic e) :test #'equal))))
   (episodes)))

(defun verify-episode-chain ()
  "Επαλήθευση της αλυσίδας SHA-256: (values ok-p πλήθος πρώτο-σπασμένο-id)."
  (let ((prev (make-string 64 :initial-element #\0)) (n 0))
    (dolist (e (%events) (values t n nil))
      (incf n)
      (unless (equal (getf e :prev) prev)
        (return (values nil n (episode-id e))))
      (setf prev (getf e :hash)))))

;;; ============================================================================
;;; ΑΤΖΕΝΤΑ — επεισόδια :goal με κατάσταση + δρομέα (ο οδηγός συνεχίζει)
;;; ============================================================================

(defun record-goal (title &key props)
  "Νέος ανοιχτός στόχος. Επιστρέφει το επεισόδιο (κράτα το :id για ενημερώσεις)."
  (record-episode :goal title :status :open :props props))

(defun update-goal (id &key status progress note)
  "Νέο γεγονός στο ΙΔΙΟ id (append-only — το fold δίνει την τρέχουσα κατάσταση).
   PROGRESS: αδιαφανής δρομέας συνέχισης (πχ πλήθος επεξεργασμένων)."
  (let ((g (find-goal id)))
    (when g
      (record-episode :goal (episode-text g) :id id
                      :status (or status (episode-status g))
                      :topic (episode-topic g)
                      :props (append (when progress (list :progress progress))
                                     (when note (list :note note))
                                     ;; κράτα ό,τι δεν αντικαθίσταται
                                     (let ((old (episode-props g)))
                                       (loop for (k v) on old by #'cddr
                                             unless (or (and progress (eq k :progress))
                                                        (and note (eq k :note)))
                                               append (list k v))))))))

(defun find-goal (id) (find id (episodes :kind :goal) :key #'episode-id :test #'equal))

(defun open-goals ()
  "Οι ανοιχτοί στόχοι — «πού είχα μείνει, τι εκκρεμεί»."
  (remove-if-not (lambda (g) (eq (episode-status g) :open)) (episodes :kind :goal)))

;;; ============================================================================
;;; ΠΡΟΘΕΤΙΚΗ — «όταν συμβεί Χ, κάνε Υ»: οπλισμένες σκανδάλες
;;; ============================================================================
;;;
;;; Η ΣΥΝΘΗΚΗ είναι δηλωτική: (όνομα . ορίσματα). Το ΤΙ σημαίνει κάθε όνομα το
;;; δηλώνουν οι τομείς (open/closed) — εδώ μόνο το μητρώο και ο κύκλος ελέγχου.
;;; Η σκανδάλη ΔΕΝ εκτελεί αυθαίρετο κώδικα από δεδομένα: δείχνει καταχωρημένη
;;; συνθήκη και περιγραφή πράξης· τη πράξη την τρέχει ο καλών (πχ ο δαίμονας).

(defvar *intention-conditions* (make-hash-table :test 'eq)
  "όνομα-συνθήκης → fn(args context)→boolean. Οι τομείς εγγράφουν.")

(defun register-intention-condition (name fn)
  (check-type name keyword)
  (setf (gethash name *intention-conditions*) fn)
  name)

(defun arm-intention (when-spec then-text &key why)
  "Όπλισε πρόθεση — «όταν συμβεί Χ, κάνε Υ»: σκανδάλη που πυροδοτείται όταν φτάσει νέα πραγματικότητα.
   WHEN-SPEC = (όνομα-συνθήκης . ορίσματα), THEN-TEXT = τι θα
   γίνει όταν ισχύσει (ανθρώπινη περιγραφή — η πράξη ζει στον καλούντα)."
  (check-type when-spec cons)
  (record-episode :intention then-text :status :armed
                  :props (list :when when-spec :why why)))

(defun armed-intentions ()
  (remove-if-not (lambda (e) (eq (episode-status e) :armed)) (episodes :kind :intention)))

(defun fire-due-intentions (context &key (on-fire nil))
  "Έλεγξε ΚΑΘΕ οπλισμένη πρόθεση απέναντι στο CONTEXT (ό,τι δώσει ο καλών — πχ
   νέα γεγονότα εισαγωγής). Όσες η συνθήκη τους ισχύει: σημαίνονται :fired
   (νέο γεγονός, ίδιο id) και καλείται το ON-FIRE (episode). Επιστρέφει τις
   πυροδοτημένες. Άγνωστη συνθήκη = ΔΕΝ πυροδοτεί (τίμια: δεν μαντεύω)."
  (let ((fired '()))
    (dolist (int (armed-intentions) (nreverse fired))
      (let* ((spec (getf (episode-props int) :when))
             (fn (gethash (car spec) *intention-conditions*)))
        (when (and fn (ignore-errors (funcall fn (cdr spec) context)))
          (record-episode :intention (episode-text int) :id (episode-id int)
                          :status :fired
                          :props (append (list :fired-at (%now)) (episode-props int)))
          (when on-fire (funcall on-fire int))
          (push int fired))))))

;;; ============================================================================
;;; ΠΕΡΙΠΤΩΣΕΙΣ — ανάκληση ομοίων μέσω λημμάτων (η ΜΙΑ γλωσσική έδρα)
;;; ============================================================================
;;;
;;; Ομοιότητα = επικάλυψη ΛΗΜΜΑΤΩΝ (Jaccard) + επικάλυψη ρητών αναφορών (:topic).
;;; Ντετερμινιστική και ΕΞΗΓΗΣΙΜΗ («όμοιο γιατί μοιράζεται: νόμος, αναδρομικότητα»)
;;; — TF-IDF πάνω σε λίγα επεισόδια θα ήταν ψευδο-στατιστική, όχι γνώση.
;;; Τα λήμματα κάθε επεισοδίου είναι ΑΠΟΘΗΚΕΥΜΕΝΑ στο γεγονός του (Φάση 1) —
;;; εδώ λημματοποιείται ΜΟΝΟ το ερώτημα· παλαιά γεγονότα χωρίς :lemmas
;;; λημματοποιούνται επιτόπου (συμβατότητα, όχι δεύτερος δρόμος).

(defun similar-episodes (text &key (k 5) kind)
  "Τα Κ πιο όμοια επεισόδια με το TEXT — ομοιότητα μέσω κοινών λημμάτων, ντετερμινιστική και εξηγήσιμη.
   Score = |κοινά λήμματα| + 2·|κοινές ρητές
   αναφορές θέματος|. Επιστρέφει λίστα (score κοινά-λήμματα επεισόδιο), φθίνουσα."
  (let* ((q-lem (%lemma-set text))
         (scored
           (loop for e in (episodes :kind kind)
                 for e-lem = (union (or (episode-lemmas e)
                                        (%lemma-set (or (episode-text e) "")))
                                    (remove-if-not #'stringp (episode-topic e))
                                    :test #'string=)
                 for common = (intersection q-lem e-lem :test #'string=)
                 for refs = (intersection (episode-topic e) q-lem :test #'equal)
                 for score = (+ (length common) (* 2 (length refs)))
                 when (plusp score)
                   collect (list score common e))))
    (subseq (sort scored (lambda (a b) (> (first a) (first b))))
            0 (min k (length scored)))))
