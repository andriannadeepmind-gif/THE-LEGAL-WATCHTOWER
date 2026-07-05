;;;; tests/amendment-consolidation-e2e-test.lisp
;;;; END-TO-END: the autonomous-consolidation chain, proven on one real-shaped law.
;;;;
;;;;   amending-law TEXT
;;;;     → orchestrator.amendment-extractor:extract-operations   (text → ops)
;;;;     → an ELI-temporal amendment RECORD (ops verbatim)
;;;;     → orchestrator.consolidation.bridge:consolidate-corpus   (apply, temporal)
;;;;     → the target article now carries the NEW text, AS OF the right date.
;;;;
;;;; This is the «be Isokratis, but point-in-time» path running for real: no
;;;; hand-authored operations, the full balanced payload, and time-travel.

(in-package :orchestrator.amendment-extractor)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun art92-text (doc)
  (let ((p (orchestrator.consolidation:find-provision doc "art_92")))
    (and p (orchestrator.consolidation:provision-text p))))
(defun art92-status (doc)
  (let ((p (orchestrator.consolidation:find-provision doc "art_92")))
    (and p (orchestrator.consolidation:provision-status p))))

;; The base corpus (as parsed from the clean JSON): one article, its original text.
(defparameter *articles*
  '((92 "Παλαιός τίτλος" "ΠΑΛΑΙΟ κείμενο του άρθρου 92.")))

;; A real-shaped amending clause — note the NEW text nests its own « » quote.
(defparameter *law-text*
  (concatenate 'string
    "Άρθρο 5. Τροποποίηση του Ποινικού Κώδικα. "
    "Το άρθρο 92 του Ποινικού Κώδικα αντικαθίσταται ως εξής: "
    "«Άρθρο 92. Θεωρείται «δημόσιο έγγραφο» κάθε έγγραφο που συντάσσεται από δημόσια αρχή.»"))

(format t "~%== 1) extract: law text → structured operation ==~%")
(defparameter *ops* (extract-operations *law-text*))
(check "one replace-text operation" (= 1 (length *ops*)))
(check "targets art_92 of poinikos"
       (and (string= (getf (first *ops*) :target) "art_92")
            (equal (getf (first *ops*) :code) "poinikos")))
(check "payload kept whole (nested «δημόσιο έγγραφο» + final sentence)"
       (and (search "«δημόσιο έγγραφο»" (getf (first *ops*) :text))
            (search "δημόσια αρχή." (getf (first *ops*) :text))))

;; Build the ELI-temporal record the bridge consumes (operations verbatim).
(defparameter *record*
  (list :id "Ν.5090/2024" :fek "Α 30/2024"
        :date "2024-02-24" :date_applicability "2024-02-24"
        :operations *ops*))

(format t "~%== 2) consolidate (current): the article carries the NEW text ==~%")
(let ((doc (orchestrator.consolidation.bridge:consolidate-corpus *articles* (list *record*))))
  (check "art_92 replaced by the new consolidated text"
         (let ((tx (art92-text doc)))
           (and tx (search "δημόσια αρχή." tx) (not (search "ΠΑΛΑΙΟ" tx)))))
  (check "provision marked :amended (provenance)" (eq (art92-status doc) :amended)))

(format t "~%== 3) point-in-time: time-travel around the effective date ==~%")
(let ((before (orchestrator.consolidation.bridge:consolidate-corpus
               *articles* (list *record*) :as-of-date "2024-01-01"))
      (after  (orchestrator.consolidation.bridge:consolidate-corpus
               *articles* (list *record*) :as-of-date "2024-12-31")))
  (check "BEFORE 2024-02-24 → the OLD text still stands"
         (search "ΠΑΛΑΙΟ" (art92-text before)))
  (check "AFTER  2024-02-24 → the NEW text is in force"
         (search "δημόσια αρχή." (art92-text after))))

(format t "~%========================================~%")
(format t "Amendment→consolidation E2E: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
