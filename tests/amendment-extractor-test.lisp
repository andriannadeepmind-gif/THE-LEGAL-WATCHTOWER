;;;; tests/amendment-extractor-test.lisp
;;;; Greek nomotechnic amendment extraction -> consolidation operations.
;;;; Deterministic, offline.

(in-package :orchestrator.amendment-extractor)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun op-targets (ops kind)
  (loop for o in ops when (eq (getf o :op) kind) collect (getf o :target)))

(format t "~%== Replacement with new text ==~%")
(let ((ops (extract-operations
            "Το άρθρο 5 του ν. 4000/2011 αντικαθίσταται ως εξής: «Η νέα διάταξη ισχύει από σήμερα.»")))
  (check "one replace-text op" (= 1 (length ops)))
  (check "targets art_5" (equal (op-targets ops :replace-text) '("art_5")))
  (check "captures the new text"
         (string= (getf (first ops) :text) "Η νέα διάταξη ισχύει από σήμερα."))
  (check "carries :if-missing :skip" (eq (getf (first ops) :if-missing) :skip)))

(format t "~%== Replacement whose NEW TEXT itself nests « » quotes (no truncation) ==~%")
;; A real replaced article quotes a defined term inside its own text. A naive
;; «([^»]*)» stopped at the first inner », corrupting the consolidated article.
(let* ((ops (extract-operations
             "Το άρθρο 92 αντικαθίσταται ως εξής: «Άρθρο 92. Θεωρείται «δημόσιο έγγραφο» κάθε έγγραφο που συντάσσεται από δημόσια αρχή.»"))
       (new (getf (first ops) :text)))
  (check "one replace-text op" (= 1 (length (op-targets ops :replace-text))))
  (check "payload keeps the inner «δημόσιο έγγραφο» quote"
         (search "«δημόσιο έγγραφο»" new))
  (check "payload is NOT truncated at the first inner » (full sentence kept)"
         (search "από δημόσια αρχή." new)))

(format t "~%== One act amending TWO codes: each op tagged with the right corpus ==~%")
;; Like Ν.5090/2024 («…ΠΟΙΝΙΚΟ ΚΩΔΙΚΑ ΚΑΙ ΤΟΝ ΚΩΔΙΚΑ ΠΟΙΝΙΚΗΣ ΔΙΚΟΝΟΜΙΑΣ…»): the
;; same article number in two codes must NOT collide — proximity code-resolution
;; tags each operation, and dedup is per (code . eId).
(let* ((ops (extract-operations
             (concatenate 'string
               "Άρθρο 1. Το άρθρο 92 του Κώδικα Ποινικής Δικονομίας αντικαθίσταται ως εξής: «Άρθρο 92. Νέο ΚΠΔ.» "
               "Άρθρο 2. Το άρθρο 92 του Ποινικού Κώδικα αντικαθίσταται ως εξής: «Άρθρο 92. Νέο ΠΚ.»")))
       (by-code (lambda (c) (find c ops :key (lambda (o) (getf o :code)) :test #'equal))))
  (check "both art_92 operations survive (no eId collision)" (= 2 (length ops)))
  (check "ΚΠΔ clause → kpoinikis with the ΚΠΔ text"
         (let ((o (funcall by-code "kpoinikis")))
           (and o (string= (getf o :target) "art_92") (search "Νέο ΚΠΔ" (getf o :text)))))
  (check "ΠΚ clause → poinikos with the ΠΚ text"
         (let ((o (funcall by-code "poinikos")))
           (and o (string= (getf o :target) "art_92") (search "Νέο ΠΚ" (getf o :text))))))

(format t "~%== Repeal, both phrasings ==~%")
(check "άρθρο N … καταργείται"
       (equal (op-targets (extract-operations "Το άρθρο 7 του Κώδικα καταργείται.") :repeal)
              '("art_7")))
(check "καταργείται το άρθρο N"
       (equal (op-targets (extract-operations "Καταργείται το άρθρο 9 του νόμου.") :repeal)
              '("art_9")))

(format t "~%== Generic amendment ==~%")
(check "τροποποιείται -> mark-amended"
       (equal (op-targets (extract-operations "Το άρθρο 3 τροποποιείται σύμφωνα με τα ανωτέρω.")
                          :mark-amended)
              '("art_3")))

(format t "~%== Mixed decision + de-dup + order ==~%")
(let ((ops (extract-operations
            "Άρθρο 1. Το άρθρο 2 αντικαθίσταται ως εξής: «Νέο 2.» Άρθρο 2. Το άρθρο 4 καταργείται. Άρθρο 3. Το άρθρο 6 τροποποιείται.")))
  (check "three operations" (= 3 (length ops)))
  (check "order: replace, repeal, amend"
         (equal (mapcar (lambda (o) (getf o :op)) ops)
                '(:replace-text :repeal :mark-amended)))
  (check "an already-replaced article is not also marked amended"
         (let ((o2 (extract-operations
                    "Το άρθρο 2 αντικαθίσταται ως εξής: «Νέο.» Το άρθρο 2 τροποποιείται επίσης.")))
           (= 1 (length o2)))))

(format t "~%== No amendment -> empty ==~%")
(check "pure announcement yields no operations"
       (null (extract-operations "Ανακοινώνεται η διενέργεια διαγωνισμού για προμήθειες.")))

(format t "~%== Διαύγεια decision -> record ==~%")
(let* ((decision (list (cons "ada" "ΨΨΨΨ-ΑΑΑ")
                       (cons "submissionTimestamp" "2024-03-01")
                       (cons "subject" "Το άρθρο 8 αντικαθίσταται ως εξής: «Αναμορφωμένο 8.»")))
       (rec (diavgeia-decision->record decision)))
  (check "record built from decision subject" (not (null rec)))
  (check "record id = ada" (string= (cdr (assoc "id" rec :test #'equal)) "ΨΨΨΨ-ΑΑΑ"))
  (check "record date = submissionTimestamp"
         (string= (cdr (assoc "date" rec :test #'equal)) "2024-03-01"))
  (check "record carries the replace op"
         (equal (op-targets (cdr (assoc "operations" rec :test #'equal)) :replace-text)
                '("art_8")))
  (check "announcement decision -> NIL record"
         (null (diavgeia-decision->record
                (list (cons "ada" "X") (cons "subject" "Πρόσκληση εκδήλωσης ενδιαφέροντος."))))))

(format t "~%== Determinism ==~%")
(let ((t1 (extract-operations "Το άρθρο 5 αντικαθίσταται ως εξής: «Α.» Το άρθρο 7 καταργείται."))
      (t2 (extract-operations "Το άρθρο 5 αντικαθίσταται ως εξής: «Α.» Το άρθρο 7 καταργείται.")))
  (check "same text -> identical operations" (equal t1 t2)))

(format t "~%========================================~%")
(format t "Amendment extractor tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
