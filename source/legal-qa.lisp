;;;; source/legal-qa.lisp
;;;; ============================================================================
;;;; DETERMINISTIC LEGAL REASONING  (provable answers, never generated)
;;;; ============================================================================
;;;;
;;;; Built on the reference graph, this is the query layer an AI can rely on: it
;;;; ANSWERS questions about the corpus by computing over verified data, and every
;;;; answer carries its citations (the article ids it is derived from). Nothing is
;;;; generated or guessed — the same question over the same corpus always yields
;;;; the same, auditable answer.
;;;;
;;;;   references-from   what does article N cite?            (outgoing edges)
;;;;   references-to     which articles cite article N?       (incoming edges)
;;;;   neighbourhood     both directions around N
;;;;   most-referenced   the most-cited (structurally central) articles
;;;;   isolated          articles neither citing nor cited (entry points/islands)
;;;;   legal-graph-json  the whole citation graph, AI-consumable
;;;; ============================================================================

(defpackage :orchestrator.legal-qa
  (:use :cl)
  (:export #:references-from #:references-to #:neighbourhood
           #:most-referenced #:isolated-articles #:legal-graph-json #:answer))

(in-package :orchestrator.legal-qa)

(macrolet ((bind (pkg &rest names)
             `(progn
                ,@(loop for n in names
                        collect `(defun ,(intern (format nil "%~A" n)) (&rest args)
                                   (apply (find-symbol ,(string n) ,pkg) args))))))
  (bind :orchestrator.consolidation
        legal-document-provisions provision-eid provision-text provision-heading)
  (bind :orchestrator.references
        reference-graph graph-edges graph-referenced-by))

(defun %eid->id (eid)
  (let ((us (position #\_ eid :from-end t)))
    (string-upcase (if us (subseq eid (1+ us)) eid))))

(defun %title-table (doc)
  (let ((h (make-hash-table :test 'equal)))
    (dolist (p (%legal-document-provisions doc) h)
      (setf (gethash (%eid->id (%provision-eid p)) h) (or (%provision-heading p) "")))))

;;; ----------------------------------------------------------------------------
;;; queries — each returns a serialisable plist with its citations
;;; ----------------------------------------------------------------------------

(defun references-from (doc id &optional (graph (%reference-graph doc)))
  "What article ID cites. (:article ID :references (...) :count N)"
  (let ((refs (%graph-edges graph id)))
    (list :question :references-from :article (string-upcase id)
          :references refs :count (length refs))))

(defun references-to (doc id &optional (graph (%reference-graph doc)))
  "Which articles cite article ID. (:article ID :referenced-by (...) :count N)"
  (let ((refs (%graph-referenced-by graph id)))
    (list :question :references-to :article (string-upcase id)
          :referenced-by refs :count (length refs))))

(defun neighbourhood (doc id &optional (graph (%reference-graph doc)))
  "Both directions around article ID."
  (list :question :neighbourhood :article (string-upcase id)
        :references (%graph-edges graph id)
        :referenced-by (%graph-referenced-by graph id)))

(defun most-referenced (doc &key (limit 10) (graph (%reference-graph doc)))
  "The most-cited articles — a structural-centrality ranking of which provisions
   the rest of the code leans on most. (:ranking ((id . in-degree) ...))"
  (let ((in (make-hash-table :test 'equal)))
    (dolist (p (%legal-document-provisions doc))
      (dolist (target (%graph-edges graph (%eid->id (%provision-eid p))))
        (incf (gethash target in 0))))
    (let ((ranked (sort (let (acc) (maphash (lambda (k v) (push (cons k v) acc)) in) acc)
                        (lambda (a b) (or (> (cdr a) (cdr b))
                                          (and (= (cdr a) (cdr b)) (string< (car a) (car b))))))))
      (list :question :most-referenced
            :ranking (if (and limit (> (length ranked) limit)) (subseq ranked 0 limit) ranked)))))

(defun isolated-articles (doc &optional (graph (%reference-graph doc)))
  "Articles that neither cite nor are cited — standalone provisions."
  (let ((out '()))
    (dolist (p (%legal-document-provisions doc))
      (let ((id (%eid->id (%provision-eid p))))
        (when (and (null (%graph-edges graph id))
                   (null (%graph-referenced-by graph id)))
          (push id out))))
    (list :question :isolated :articles (nreverse out))))

;;; ----------------------------------------------------------------------------
;;; AI-consumable JSON of the whole graph
;;; ----------------------------------------------------------------------------

(defun %jstr (s)
  (with-output-to-string (o)
    (write-char #\" o)
    (loop for c across (princ-to-string (or s "")) do
      (case c ((#\" #\\) (write-char #\\ o) (write-char c o))
              (#\Newline (write-string "\\n" o)) (#\Return (write-string "\\r" o))
              (#\Tab (write-string "\\t" o)) (#\Backspace (write-string "\\b" o))
              (#\Page (write-string "\\f" o))
              (t (if (< (char-code c) #x20)
                     (format o "\\u~4,'0x" (char-code c))
                     (write-char c o)))))
    (write-char #\" o)))

(defun %jarr (items) (format nil "[~{~A~^,~}]" (mapcar #'%jstr items)))

(defun legal-graph-json (doc)
  "The complete citation graph as JSON — one object per article with its title,
   outgoing references and incoming citations. Deterministic ordering."
  (let* ((graph (%reference-graph doc))
         (titles (%title-table doc)))
    (with-output-to-string (s)
      (write-string "{\"articles\":[" s)
      (loop for p in (%legal-document-provisions doc) for firstp = t then nil
            for id = (%eid->id (%provision-eid p)) do
        (unless firstp (write-char #\, s))
        (format s "{\"id\":~A,\"title\":~A,\"references\":~A,\"referenced_by\":~A}"
                (%jstr id) (%jstr (gethash id titles ""))
                (%jarr (%graph-edges graph id)) (%jarr (%graph-referenced-by graph id))))
      (write-string "]}" s))))

;;; ----------------------------------------------------------------------------
;;; one dispatcher
;;; ----------------------------------------------------------------------------

(defun answer (doc question &key id (limit 10))
  "Answer a structured QUESTION (:references-from | :references-to |
   :neighbourhood | :most-referenced | :isolated) over DOC, returning the
   answer plist. ID is required for the per-article questions."
  (let ((graph (%reference-graph doc)))
    (ecase question
      (:references-from (references-from doc id graph))
      (:references-to   (references-to doc id graph))
      (:neighbourhood   (neighbourhood doc id graph))
      (:most-referenced (most-referenced doc :limit limit :graph graph))
      (:isolated        (isolated-articles doc graph)))))
