;;;; source/ast-gate.lisp
;;;; ============================================================================
;;;; AST STRUCTURAL GATE  —  the dead 5-layer validators, made live over the corpus
;;;; ============================================================================
;;;;
;;;; The system already ships a rich CLOS legal-AST (document/article/paragraph
;;;; nodes with ast-walk / ast-validate generics) and a Layer-4 validator
;;;; (validate-ast: structural integrity, content presence, Greek legal rules).
;;;; But that validator only ever ran on the raw-text source type — for the PDF /
;;;; ΦΕΚ path it was DEAD code: the ΦΕΚ state machine produced articles that were
;;;; never lifted into the AST, so the AST-level correctness guarantees never
;;;; applied to the real, served corpus.
;;;;
;;;; This module closes that gap WITHOUT touching the ΦΕΚ parser (no functionality
;;;; removed, the superior path is reused, not replaced): it lifts the served
;;;; consolidated corpus into the SAME legal-AST the raw-text path builds, then
;;;; runs the SAME Layer-4 validators over it. The previously-dead validators now
;;;; guard the live corpus as an advisory structural gate — alongside the
;;;; reference-graph, anomaly and Q-A intelligence layers.
;;;;
;;;;   corpus-ast               served legal-document  -> legal-ast document-node
;;;;   validate-corpus-structure run Layer-4 validation over that AST
;;;;   format-structure-report   human (Greek) report of issues/warnings
;;;;
;;;; Deterministic, pure CLOS, no PDF/poppler needed (operates on parsed text);
;;;; lettered article ids (100Α) are carried as strings into the AST, so the
;;;; distinctness guarantee holds at the AST level too.
;;;; ============================================================================

(defpackage :orchestrator.ast-gate
  (:use :cl)
  (:export #:articles->document-ast #:corpus-ast
           #:validate-document-ast #:validate-corpus-structure
           #:structure-clean-p #:format-structure-report))

(in-package :orchestrator.ast-gate)

;;; consolidation accessors (resolved at load; no hard package coupling — the same
;;; defensive pattern the other intelligence modules use)
(macrolet ((bind (&rest names)
             `(progn
                ,@(loop for n in names
                        collect `(defun ,(intern (format nil "%~A" n))
                                     (&rest args)
                                   (apply (find-symbol ,(string n) :orchestrator.consolidation)
                                          args))))))
  (bind legal-document-provisions provision-eid provision-text provision-children))

;;; ----------------------------------------------------------------------------
;;; lift parsed articles into the CLOS legal-AST
;;; ----------------------------------------------------------------------------

(defun articles->document-ast (specs &key (title "Corpus"))
  "Build a legal-ast DOCUMENT-NODE from SPECS, a list of plists:
     (:number <string-or-integer> :title <string-or-nil> :paragraphs <list-of-strings>)
   Article numbers are kept verbatim (a string \"100Α\" stays distinct from 100),
   so the AST preserves the lettered-article guarantee. Reuses the project's
   legal-ast node constructors — no parsing here, only structural lifting."
  (orchestrator.legal-ast:make-document-node
   :title title
   :articles
   (loop for s in specs
         collect (orchestrator.legal-ast:make-article-node
                  :number (getf s :number)
                  :title (getf s :title)
                  :text (or (getf s :text)
                            (format nil "~{~A~^ ~}" (getf s :paragraphs)))
                  :paragraphs
                  (loop for p in (getf s :paragraphs)
                        for i from 1
                        collect (orchestrator.legal-ast:make-paragraph-node
                                 :number i :content p :text p))))))

(defun %eid->number (eid)
  "art_100Α -> \"100Α\" (kept as a string so lettered articles stay distinct)."
  (let ((us (position #\_ eid :from-end t)))
    (if us (subseq eid (1+ us)) eid)))

(defun corpus-ast (doc)
  "Lift the served consolidated DOC (an orchestrator.consolidation legal-document)
   into a legal-ast document-node: one article-node per provision, its children
   (or its own text) becoming paragraph-nodes."
  (articles->document-ast
   (loop for p in (%legal-document-provisions doc)
         for kids = (%provision-children p)
         collect (list :number (%eid->number (%provision-eid p))
                       :title nil
                       :text (%provision-text p)
                       :paragraphs (if kids
                                       (remove nil (mapcar #'%provision-text kids))
                                       (let ((tx (%provision-text p)))
                                         (when (and tx (plusp (length tx))) (list tx))))))))

;;; ----------------------------------------------------------------------------
;;; run the Layer-4 validators over the lifted AST
;;; ----------------------------------------------------------------------------

(defun validate-document-ast (document-node)
  "Run the Layer-4 AST validators over DOCUMENT-NODE. Returns (values valid-p
   result). The layout TRACE chain is a raw-text-pipeline concern (the ΦΕΚ path
   carries its own provenance), so it is not required here — structural integrity,
   content presence and the Greek legal rules ARE."
  (let ((orchestrator.validate-ast:*require-trace-chain* nil))
    (orchestrator.validate-ast:validate-ast document-node)))

(defun validate-corpus-structure (doc)
  "Lift DOC into the legal-AST and validate it. Returns (values valid-p result).
   Advisory: surfaces structural problems (missing article numbers, empty
   provisions, malformed nesting) the flat consolidation cannot see."
  (validate-document-ast (corpus-ast doc)))

(defun structure-clean-p (result)
  "Whether the AST validation RESULT reports a structurally sound corpus."
  (orchestrator.validate-ast:result-valid-p result))

(defun format-structure-report (result &optional (stream nil))
  "A human (Greek) summary of an AST validation RESULT."
  (let ((issues (orchestrator.validate-ast:result-issues result))
        (warnings (orchestrator.validate-ast:result-warnings result))
        (nodes (orchestrator.validate-ast:result-node-count result)))
    (if (and (null issues) (orchestrator.validate-ast:result-valid-p result))
        (format stream "✓ δομή άρθρων έγκυρη (~D κόμβοι AST ελέγχθηκαν)~@[~%  ⚠ ~D προειδοποίηση(εις)~]"
                nodes (and warnings (length warnings)))
        (format stream "✗ ~D δομικό(ά) πρόβλημα(τα) στον κώδικα (~D κόμβοι AST):~{~%  · ~A~}~@[~%  ⚠ ~D προειδοποίηση(εις)~]"
                (length issues) nodes
                (mapcar #'princ-to-string issues)
                (and warnings (length warnings))))))
