;;;; tests/corpus-intelligence-test.lisp
;;;; The corpus-intelligence suite: one MOP-discovered set of checks (reference
;;;; integrity, extraction anomalies, AST structure, citation centrality) run over
;;;; the served legal-document, producing a unified human + AI report. Verifies
;;;; the MOP discovery, that a clean corpus passes, that real problems are
;;;; surfaced, and that the output is deterministic. Pure CLOS, no PDF needed.

(in-package :orchestrator.intelligence)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun mk (eid text)
  (orchestrator.consolidation:make-provision :eid eid :kind :article :text text))
(defun doc (&rest provisions)
  (orchestrator.consolidation:make-legal-document :id "t" :provisions provisions))
(defun finding-for (findings id) (find id findings :key #'finding-check))

(format t "~%== MOP: the checks are discovered via the metaobject protocol ==~%")
(check "at least four checks are registered" (>= (length (corpus-checks)) 4))
(let ((ids (mapcar #'class-check-id (corpus-checks))))
  (check "reference integrity is one of them" (member :references ids))
  (check "anomaly detection is one of them" (member :anomalies ids))
  (check "AST structure is one of them" (member :structure ids))
  (check "centrality is one of them" (member :centrality ids)))

(format t "~%== a clean, well-formed corpus passes ==~%")
(let* ((d (doc (mk "art_1" "Η παρούσα διάταξη ορίζει κατά το άρθρο 2 τις προϋποθέσεις εφαρμογής.")
               (mk "art_2" "Το παρόν άρθρο περιγράφει αναλυτικά τις σχετικές υποχρεώσεις των μερών.")))
       (findings (run-corpus-intelligence d)))
  (check "every check produced a finding" (= (length (corpus-checks)) (length findings)))
  (check "the report is clean (no :issues)" (report-clean-p findings))
  (check "reference integrity is :ok (art_1 → art_2 resolves)"
         (eq :ok (finding-status (finding-for findings :references))))
  (check "structure is :ok" (eq :ok (finding-status (finding-for findings :structure))))
  (check "findings are deterministically ordered by check id"
         (equal (mapcar (lambda (f) (string (finding-check f))) findings)
                (sort (mapcar (lambda (f) (string (finding-check f))) findings) #'string<))))

(format t "~%== a dangling citation is surfaced (advisory) ==~%")
(let* ((d (doc (mk "art_1" "Εφαρμόζεται κατά το άρθρο 5 του παρόντος, με τις αναγκαίες προσαρμογές.")
               (mk "art_2" "Δεύτερο άρθρο με επαρκές ελληνικό κείμενο για τον έλεγχο ανωμαλιών.")))
       (findings (run-corpus-intelligence d))
       (ref (finding-for findings :references)))
  (check "reference integrity flags the unresolved citation as advisory"
         (eq :advisory (finding-status ref)))
  (check "it counts the dangling reference" (>= (finding-count ref) 1))
  (check "an advisory does NOT make the report dirty" (report-clean-p findings)))

(format t "~%== an extraction anomaly is a real issue (dirties the report) ==~%")
(let* ((d (doc (mk "art_1" "Κανονικό άρθρο με αρκετό ελληνικό κείμενο για τον έλεγχο.")
               (mk "art_2" "xxxxxxxxxx yyyyyyyyyy zzzzzzzzzz wwwwwwwwww qqqqqqqqqq"))) ; extraction noise: no Greek
       (findings (run-corpus-intelligence d))
       (an (finding-for findings :anomalies)))
  (check "the anomaly check reports issues" (eq :issues (finding-status an)))
  (check "it counts the bad article" (>= (finding-count an) 1))
  (check "the overall report is NOT clean" (not (report-clean-p findings))))

(format t "~%== an empty corpus fails the structural check ==~%")
(let* ((findings (run-corpus-intelligence (doc)))
       (st (finding-for findings :structure)))
  (check "structure reports issues for a document with no articles"
         (eq :issues (finding-status st))))

(format t "~%== reports: human (Greek) + AI (JSON) ==~%")
(let* ((d (doc (mk "art_1" "Η διάταξη ορίζει κατά το άρθρο 2 τα σχετικά με την εφαρμογή της.")
               (mk "art_2" "Δεύτερο άρθρο με επαρκές ελληνικό κείμενο για κάθε έλεγχο εδώ.")))
       (findings (run-corpus-intelligence d)))
  (check "the human report names the suite"
         (search "ΝΟΗΜΟΣΥΝΗΣ" (format-intelligence-report findings nil)))
  (check "the human report shows the clean banner"
         (search "καθαρός κώδικας" (format-intelligence-report findings nil)))
  (let ((json (intelligence-json findings)))
    (check "the AI JSON is an array" (and (char= #\[ (char json 0))
                                          (char= #\] (char json (1- (length json))))))
    (check "the JSON mentions a check id" (search "\"references\"" json))
    (check "the JSON is deterministic" (string= json (intelligence-json (run-corpus-intelligence d))))))

(format t "~%== MOP extensibility: a new check joins with zero suite changes ==~%")
(define-corpus-check %demo-check (:demo "Demo")
    (doc) (finding :summary "demo"))
(check "the newly-defined check is auto-discovered by the suite"
       (member :demo (mapcar #'class-check-id (corpus-checks))))
(check "and it runs as part of run-corpus-intelligence"
       (finding-for (run-corpus-intelligence (doc (mk "art_1" "κείμενο"))) :demo))

(format t "~%========================================~%")
(format t "Corpus intelligence tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
