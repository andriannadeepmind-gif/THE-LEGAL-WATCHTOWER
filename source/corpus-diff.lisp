;;;; source/corpus-diff.lisp
;;;; ============================================================================
;;;; LEGAL CHANGE DIFF  ("what changed in the law between date X and date Y")
;;;; ============================================================================
;;;;
;;;; Wires the restored semantic-versioning capability to the consolidation
;;;; engine: consolidates the corpus as it stood on two dates, classifies each
;;;; article as amended / repealed / restored / unchanged, and for amended
;;;; articles produces a proper word-level diff (semantic-versioning's LCS
;;;; compute-text-diff). Exposed as /<corpus>/diff?from=…&to=…
;;;; ============================================================================

(defpackage :orchestrator.corpus-diff
  (:use :cl)
  (:import-from :orchestrator.consolidation
                #:consolidate #:legal-document-provisions
                #:provision-eid #:provision-num #:provision-heading
                #:provision-text #:provision-children #:provision-status
                #:provision-source-act #:provision-source-date)
  (:export #:corpus-diff))

(in-package :orchestrator.corpus-diff)

(defun article-text (p)
  (with-output-to-string (s)
    (labels ((walk (x)
               (when (provision-text x) (write-string (provision-text x) s) (write-char #\Space s))
               (dolist (c (provision-children x)) (walk c))))
      (walk p))))

(defun by-eid (document)
  (let ((h (make-hash-table :test 'equal)))
    (dolist (a (legal-document-provisions document) h)
      (setf (gethash (provision-eid a) h) a))))

(defun jstr (x)
  (with-output-to-string (s)
    (write-char #\" s)
    (loop for ch across (princ-to-string (or x ""))
          do (case ch
               (#\" (write-string "\\\"" s)) (#\\ (write-string "\\\\" s))
               (#\Newline (write-string "\\n" s)) (#\Return (write-string "\\r" s))
               (#\Tab (write-string "\\t" s)) (t (write-char ch s))))
    (write-char #\" s)))

(defun segments->json (segments)
  "Serialize compute-text-diff :segments to a compact JSON array."
  (with-output-to-string (s)
    (write-char #\[ s)
    (loop for seg in segments for firstp = t then nil
          do (unless firstp (write-char #\, s))
             (format s "{\"op\":~A,\"text\":~A}"
                     (jstr (string-downcase (symbol-name (getf seg :op))))
                     (jstr (getf seg :text))))
    (write-char #\] s)))

(defun classify (sf st tf tt)
  "Return a change keyword or NIL when unchanged."
  (cond
    ((and (eq st :repealed) (not (eq sf :repealed))) :repealed)
    ((and (eq sf :repealed) (not (eq st :repealed))) :restored)
    ((not (string= tf tt)) :amended)
    ((not (eq sf st)) :amended)
    (t nil)))

(defun corpus-diff (doc-from doc-to from-date to-date
                    &key (base-uri "https://stavropouloslaw.com/eli"))
  "Diff two already-consolidated versions of the corpus (as it stood on
   FROM-DATE and TO-DATE). Returns a JSON object describing every changed
   article, with a word-level diff for amended text."
  (let* ((from-map (by-eid doc-from))
         (changes '()))
    (dolist (a-to (legal-document-provisions doc-to))
      (let* ((eid (provision-eid a-to))
             (a-from (gethash eid from-map))
             (sf (and a-from (provision-status a-from)))
             (st (provision-status a-to))
             (tf (if a-from (article-text a-from) ""))
             (tt (article-text a-to))
             (change (if a-from (classify sf st tf tt) :new)))
        (when change
          (push (list :eid eid :num (provision-num a-to) :heading (provision-heading a-to)
                      :change change :from-status sf :to-status st
                      :act (provision-source-act a-to) :date (provision-source-date a-to)
                      :diff (when (and (eq change :amended) (not (string= tf tt)))
                              (funcall (find-symbol "COMPUTE-TEXT-DIFF" :orchestrator.semantic-versioning)
                                       tf tt)))
                changes))))
    (setf changes (nreverse changes))
    (with-output-to-string (s)
      (format s "{\"from\":~A,\"to\":~A,\"count\":~D,\"changes\":["
              (jstr from-date) (jstr to-date) (length changes))
      (loop for c in changes for firstp = t then nil
            do (unless firstp (write-char #\, s))
               (format s "{\"@id\":~A,\"eId\":~A,\"number\":~A,\"heading\":~A,~
\"change\":~A,\"from_status\":~A,\"to_status\":~A,\"amended_by\":~A"
                       (jstr (format nil "~A/~A" base-uri (getf c :eid)))
                       (jstr (getf c :eid)) (jstr (getf c :num)) (jstr (getf c :heading))
                       (jstr (string-downcase (symbol-name (getf c :change))))
                       (jstr (and (getf c :from-status) (string-downcase (symbol-name (getf c :from-status)))))
                       (jstr (string-downcase (symbol-name (getf c :to-status))))
                       (jstr (getf c :act)))
               (when (getf c :diff)
                 (let ((d (getf c :diff)))
                   (format s ",\"modifications\":~D,\"diff\":~A"
                           (getf d :modification-count)
                           (segments->json (getf d :segments)))))
               (write-char #\} s))
      (write-string "]}" s))))
