;;;; tests/corpus-sparql-test.lisp
;;;; Live SPARQL over a consolidated corpus (reuses the sparql-endpoint engine).

(in-package :orchestrator.corpus-sparql)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun build-doc ()
  (let ((c (find-package :orchestrator.consolidation)))
    (flet ((mp (&rest a) (apply (find-symbol "MAKE-PROVISION" c) a))
           (md (&rest a) (apply (find-symbol "MAKE-LEGAL-DOCUMENT" c) a))
           (ma (&rest a) (apply (find-symbol "MAKE-AMENDING-ACT" c) a))
           (cons* (&rest a) (apply (find-symbol "CONSOLIDATE" c) a)))
      (cons* (md :id "demo" :title "Demo" :language "el"
                 :provisions (list (mp :eid "art_1" :kind :article :num "1" :heading "Α" :text "Κ1.")
                                   (mp :eid "art_2" :kind :article :num "2" :heading "Β" :text "Κ2.")
                                   (mp :eid "art_3" :kind :article :num "3" :heading "Γ" :text "Κ3.")))
             (list (ma :id "L1" :effective "2010-01-01"
                       :operations (list (list :op :repeal :target "art_3"))))))))

(defun n-bindings (json)
  "Count result bindings by counting the eId markers."
  (let ((c 0) (i 0))
    (loop for p = (search "\"value\"" json :start2 i)
          while p do (incf c) (setf i (+ p 7)))
    c))

(let* ((doc (build-doc))
       (base "https://x/eli/demo"))

  (format t "~%== KB + expansion ==~%")
  (check "build-corpus-kb yields triples"
         (> (funcall (find-symbol "KB-SIZE" :orchestrator.rdfs-inference)
                     (build-corpus-kb doc base)) 0))
  (check "prefix eli: expands to full IRI"
         (search "<http://data.europa.eu/eli/ontology#in_force>"
                 (%expand-prefixes "SELECT ?a WHERE { ?a eli:in_force \"true\" }")))
  (check "PREFIX declaration lines are dropped"
         (null (search "PREFIX"
                       (%expand-prefixes "PREFIX eli: <http://x#>
SELECT ?a WHERE { ?a eli:in_force \"true\" }"))))

  (format t "~%== Query results ==~%")
  (let ((in-force (sparql-query doc base "SELECT ?a WHERE { ?a eli:in_force \"true\" }"))
        (repealed (sparql-query doc base "SELECT ?a WHERE { ?a eli:in_force \"false\" }")))
    (check "in-force query returns art_1 and art_2"
           (and (search "art_1" in-force) (search "art_2" in-force)))
    (check "in-force query EXCLUDES repealed art_3"
           (null (search "/art_3" in-force)))
    (check "repealed query returns ONLY art_3"
           (and (search "art_3" repealed)
                (null (search "/art_1" repealed)) (null (search "/art_2" repealed))))
    (check "results are SPARQL-results JSON" (search "\"bindings\"" in-force)))

  (format t "~%== Robustness ==~%")
  (check "bad query -> JSON string, never throws"
         (let ((r (handler-case (sparql-query doc base "NOT A QUERY {{{") (error () :threw))))
           (and (stringp r)
                (or (search "\"error\"" r) (search "\"bindings\"" r)))))
  (check "deterministic results across calls"
         (string= (sparql-query doc base "SELECT ?a WHERE { ?a eli:in_force \"true\" }")
                  (sparql-query doc base "SELECT ?a WHERE { ?a eli:in_force \"true\" }"))))

(format t "~%========================================~%")
(format t "Corpus SPARQL tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
