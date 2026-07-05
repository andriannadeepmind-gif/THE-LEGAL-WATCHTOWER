;;;; source/legal-references.lisp
;;;; ============================================================================
;;;; LEGAL REFERENCE GRAPH  (the first brick of the law's knowledge graph)
;;;; ============================================================================
;;;;
;;;; Greek legislation is a web of cross-references ("κατά το άρθρο 299", "των
;;;; άρθρων 235 - 263Α", "άρθρα 216, 217, 218"). This module reads those citations
;;;; out of the consolidated text, builds a directed graph article → articles it
;;;; cites, and checks that every INTERNAL citation resolves to an article that
;;;; actually exists in the corpus. A citation that does not resolve is either an
;;;; extraction error, a reference to a repealed article, or a reference to a
;;;; DIFFERENT law — so it is surfaced for human review, never silently trusted.
;;;;
;;;; Deterministic, pure Common Lisp, operating on the served legal-document.
;;;; ============================================================================

(defpackage :orchestrator.references
  (:use :cl)
  (:export #:extract-article-refs #:document-article-ids #:reference-graph
           #:graph-edges #:graph-referenced-by #:verify-references
           #:format-reference-report))

(in-package :orchestrator.references)

;;; consolidation accessors (resolved at load; no hard package coupling)
(macrolet ((bind (&rest names)
             `(progn
                ,@(loop for n in names
                        collect `(defun ,(intern (format nil "%~A" n))
                                     (&rest args)
                                   (apply (find-symbol ,(string n) :orchestrator.consolidation)
                                          args))))))
  (bind legal-document-provisions provision-eid provision-text provision-children))

;;; ----------------------------------------------------------------------------
;;; citation extraction
;;; ----------------------------------------------------------------------------

(defparameter +gl+
  (format nil "~A-~A~A-~A"
          (code-char #x0370) (code-char #x03FF) (code-char #x1F00) (code-char #x1FFF))
  "Greek letter ranges (for use inside a [...] char class).")

(defparameter *article-ref-scanner*
  (cl-ppcre:create-scanner
   (format nil "[άΆ]ρθρ[~A]*\\s+(\\d+[~A]?(?:\\s*(?:[,\\-–]|έως|ως|μέχρι|και)\\s*\\d+[~A]?)*)"
           +gl+ +gl+ +gl+))
  "Matches an 'άρθρο/άρθρων/άρθρα …' citation; group 1 is the number run.")

(defparameter *ref-number-scanner*
  (cl-ppcre:create-scanner (format nil "\\d+[~A]?" +gl+))
  "A single article number, with an optional letter suffix (263Α).")

(defun %normalize-id (s)
  "Canonical article id: digits + UPPER-CASE letter suffix (263α → 263Α)."
  (string-upcase (string-trim " " s)))

(defun extract-article-refs (text)
  "The distinct article ids cited in TEXT (e.g. '299', '263Α'), in order of
   first appearance. Handles single citations, comma lists and ranges."
  (when (and text (plusp (length text)))
    (let ((out '()) (seen (make-hash-table :test 'equal)))
      (cl-ppcre:do-register-groups (run) (*article-ref-scanner* text)
        (dolist (n (cl-ppcre:all-matches-as-strings *ref-number-scanner* run))
          (let ((id (%normalize-id n)))
            (unless (gethash id seen)
              (setf (gethash id seen) t)
              (push id out)))))
      (nreverse out))))

;;; ----------------------------------------------------------------------------
;;; the corpus's own article ids + provision text
;;; ----------------------------------------------------------------------------

(defun %eid->id (eid)
  "art_263Α → 263Α (the citable article number)."
  (let ((us (position #\_ eid :from-end t)))
    (if us (%normalize-id (subseq eid (1+ us))) (%normalize-id eid))))

(defun %provision-full-text (p)
  "An article's text plus all of its descendants' text."
  (with-output-to-string (s)
    (let ((tx (%provision-text p))) (when tx (write-string tx s) (write-char #\Space s)))
    (dolist (c (%provision-children p))
      (write-string (%provision-full-text c) s))))

(defun document-article-ids (doc)
  "The set (hash id→t) of article ids the corpus actually contains."
  (let ((h (make-hash-table :test 'equal)))
    (dolist (p (%legal-document-provisions doc) h)
      (setf (gethash (%eid->id (%provision-eid p)) h) t))))

;;; ----------------------------------------------------------------------------
;;; the reference graph
;;; ----------------------------------------------------------------------------

(defstruct (reference-graph (:constructor %make-graph))
  (edges (make-hash-table :test 'equal))        ; id -> (referenced id ...)
  (ids   (make-hash-table :test 'equal)))        ; id -> t  (existing articles)

(defun reference-graph (doc)
  "Build the directed citation graph of DOC: each article id → the ids it cites
   (self-citations and citations of a non-existent article are dropped from the
   edges but reported by VERIFY-REFERENCES)."
  (let ((g (%make-graph :ids (document-article-ids doc))))
    (dolist (p (%legal-document-provisions doc) g)
      (let* ((id (%eid->id (%provision-eid p)))
             (refs (extract-article-refs (%provision-full-text p))))
        (setf (gethash id (reference-graph-edges g))
              (remove-if (lambda (r) (or (string= r id)
                                         (not (gethash r (reference-graph-ids g)))))
                         refs))))))

(defun graph-edges (g id)
  "The article ids cited by article ID (resolved, existing)."
  (gethash (%normalize-id id) (reference-graph-edges g)))

(defun graph-referenced-by (g id)
  "The article ids that cite article ID (reverse edges) — 'who points here'."
  (let ((id (%normalize-id id)) (out '()))
    (maphash (lambda (src targets) (when (member id targets :test #'string=) (push src out)))
             (reference-graph-edges g))
    (sort out #'string<)))

;;; ----------------------------------------------------------------------------
;;; integrity check
;;; ----------------------------------------------------------------------------

(defun verify-references (doc)
  "Return (values ok-p unresolved) where UNRESOLVED is a list of
     (source-id . cited-id)
   for every INTERNAL citation that does not resolve to an existing article.
   NOTE: an unresolved citation may legitimately point to a different law
   (e.g. 'άρθρο 8 του Ν.Δ. 181/1974') or a repealed article, so this is an
   ADVISORY signal for review, not a hard failure of the corpus."
  (let ((ids (document-article-ids doc))
        (unresolved '()))
    (dolist (p (%legal-document-provisions doc))
      (let ((src (%eid->id (%provision-eid p))))
        (dolist (r (extract-article-refs (%provision-full-text p)))
          (unless (or (string= r src) (gethash r ids))
            (push (cons src r) unresolved)))))
    (let ((u (nreverse unresolved)))
      (values (null u) u))))

(defun format-reference-report (unresolved &optional (stream nil))
  (if (null unresolved)
      (format stream "✓ κάθε εσωτερική παραπομπή δένει σε υπαρκτό άρθρο")
      (format stream "ℹ ~D παραπομπή(ές) δεν δένουν εσωτερικά (πιθανώς άλλος νόμος / καταργημένο / λάθος εξαγωγής):~{~%  · άρθρο ~A → άρθρο ~A~}"
              (length unresolved)
              (loop for (s . r) in unresolved append (list s r)))))
