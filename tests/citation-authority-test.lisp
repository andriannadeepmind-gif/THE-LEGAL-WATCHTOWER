;;;; tests/citation-authority-test.lisp
;;;; The citation-authority analytics engine, now live: a directed citation graph
;;;; with PageRank, degree centrality, Greek citation extraction, and a rule-based
;;;; Greek legal lemmatizer. Deterministic; pure Common Lisp.

(in-package :orchestrator.citation-authority)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun %sum-table (h) (let ((s 0d0)) (maphash (lambda (k v) (declare (ignore k)) (incf s v)) h) s))
(defun %argmax-table (h)
  (let ((best nil) (best-v most-negative-double-float))
    (maphash (lambda (k v) (when (> v best-v) (setf best k best-v v))) h) best))

(format t "~%== directed citation graph construction ==~%")
(let ((g (make-citation-graph)))
  (add-article g 1 :title "Άρθρο 1")
  (add-article g 2 :title "Άρθρο 2")
  (add-article g 3 :title "Άρθρο 3")
  (add-citation g 1 2)
  (add-citation g 1 3)
  (add-citation g 2 3)              ; article 3 is the most cited
  (check "all articles are nodes" (= 3 (article-count g)))
  (check "all citations are edges" (= 3 (citation-count g)))
  (check "a re-added edge is not double-counted"
         (progn (add-citation g 1 2) (= 3 (citation-count g))))

  (format t "~%== PageRank (power iteration) ==~%")
  (let ((pr (pagerank g)))
    (check "every article gets a positive score"
           (let ((ok t)) (dolist (n (get-articles g) ok)
                           (unless (> (gethash n pr) 0) (setf ok nil)))))
    (check "scores form a probability distribution (sum ≈ 1)"
           (< (abs (- (%sum-table pr) 1.0)) 0.02))
    (check "the most-cited article ranks highest" (eql 3 (%argmax-table pr)))
    (check "PageRank is deterministic"
           (let ((pr2 (pagerank g)))
             (every (lambda (n) (< (abs (- (gethash n pr) (gethash n pr2))) 1e-9))
                    (get-articles g)))))

  (format t "~%== degree centrality ==~%")
  (let ((indeg (in-degree-centrality g)))
    (check "the most-cited article has the highest in-degree centrality"
           (eql 3 (%argmax-table indeg)))))

(format t "~%== Greek citation extraction ==~%")
(let ((cites (extract-greek-citations "Κατά το άρθρο 5 και το άρθρο 25 του Συντάγματος")))
  (check "extracts the cited article numbers" (equal '(5 25) cites))
  (check "returns them sorted" (equal cites (sort (copy-list cites) #'<))))

(format t "~%== rule-based Greek legal lemmatizer ==~%")
(check "genitive masculine → nominative (νόμου → νόμος)"
       (string= "νόμος" (lemmatize-greek "νόμου")))
(check "genitive feminine → nominative (δημοκρατίας → δημοκρατία)"
       (string= "δημοκρατία" (lemmatize-greek "δημοκρατίας")))
(check "an unknown token falls back to itself"
       (string= "ξζ" (lemmatize-greek "ξζ")))
(check "the legal vocabulary is populated" (plusp (legal-vocabulary-size)))

(format t "~%== ΜΙΑ έδρα ΑΡΝΗΣΗΣ (+negators+) — αποσύγχυση από +adversatives+ ==~%")
;; [0080] Η άρνηση έχει ΜΙΑ έδρα· οι αντιθετικοί σύνδεσμοι ΑΛΛΗ. Καμία επικάλυψη.
(check "+negators+ ∩ +adversatives+ = ∅ (καμία σύγχυση εννοιών)"
       (null (intersection +negators+ +adversatives+ :test #'string=)))
(check "οι αρνητές δεν περιέχουν αντιθετικούς (μα/αλλά/όμως)"
       (notany (lambda (w) (member w +negators+ :test #'string=))
               (mapcar #'normalize-greek '("μα" "αλλά" "όμως"))))
;; ΔΟΜΙΚΗ ΕΓΓΥΗΣΗ κανονικοποίησης: κάθε εγγραφή είναι ΗΔΗ σε κανονική μορφή (τελικό σ)
;; ⇒ ταιριάζει άμεσα με normalize-greek token. Ο θάνατος του «ομως(ς)≠ομωσ(σ)».
(check "κάθε αρνητής/αντιθετικός είναι ΗΔΗ κανονικοποιημένος (idempotent normalize)"
       (every (lambda (w) (string= w (normalize-greek w)))
              (append +negators+ +adversatives+ +interrogatives+)))
(check "utterance-act(«Όμως …») = :objection (η ς-fold διόρθωση, ζωντανή)"
       (eq :objection (utterance-act "Όμως αυτό είναι λάθος.")))
(check "utterance-act(«Δεν …») = :objection μέσω +negators+ (μία έδρα)"
       (eq :objection (utterance-act "Δεν συμφωνώ.")))

(format t "~%== determinism: same graph, same analytics ==~%")
(let ((g (make-citation-graph)))
  (add-article g 10) (add-article g 20) (add-citation g 10 20)
  (check "two PageRank runs agree exactly"
         (let ((a (pagerank g)) (b (pagerank g)))
           (and (< (abs (- (gethash 10 a) (gethash 10 b))) 1e-12)
                (< (abs (- (gethash 20 a) (gethash 20 b))) 1e-12)))))

(format t "~%========================================~%")
(format t "Citation authority tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
