;;;; source/corpus-search.lisp
;;;; ============================================================================
;;;; GREEK FULL-TEXT SEARCH OVER THE CONSOLIDATED CORPUS
;;;; ============================================================================
;;;;
;;;; Brings the real (previously unwired) Greek tokenizer to life: tokenizes the
;;;; query and each article with proper Greek handling, folds accents and final
;;;; sigma, and ranks articles by how many distinct query terms they contain.
;;;; Wired into the AI-first service as /<corpus>/search?q=…
;;;;
;;;; Reuses orchestrator.greek-tokenizer (real tokenizer) — no new tokenizer.
;;;; ============================================================================

(defpackage :orchestrator.corpus-search
  (:use :cl)
  (:import-from :orchestrator.consolidation
                #:legal-document-provisions
                #:provision-eid #:provision-num #:provision-heading
                #:provision-text #:provision-children #:provision-status)
  (:export #:search-corpus #:fold-greek))

(in-package :orchestrator.corpus-search)

;;; ----------------------------------------------------------------------------
;;; Greek normalization: lowercase tokens + fold accents and final sigma so that
;;; "Νόμος", "νόμος" and "νομος" all match.
;;; ----------------------------------------------------------------------------

(defparameter +greek-fold+
  '((#\ά . #\α) (#\έ . #\ε) (#\ή . #\η) (#\ί . #\ι) (#\ό . #\ο) (#\ύ . #\υ)
    (#\ώ . #\ω) (#\ϊ . #\ι) (#\ϋ . #\υ) (#\ΐ . #\ι) (#\ΰ . #\υ) (#\ς . #\σ)))

(defun fold-greek (string)
  (map 'string (lambda (ch)
                 (let ((m (assoc ch +greek-fold+)))
                   (if m (cdr m) ch)))
       (string-downcase (or string ""))))

(defun tokens-of (text)
  "Normalized token strings for TEXT via the real Greek tokenizer."
  (let ((toks (funcall (find-symbol "TOKENIZE-TO-TOKENS" :orchestrator.greek-tokenizer) text)))
    (remove-if (lambda (s) (< (length s) 2))
               (mapcar (lambda (tok)
                         (fold-greek (funcall (find-symbol "TOKEN-TEXT" :orchestrator.greek-tokenizer) tok)))
                       toks))))

(defun term-match-p (a b)
  "Inflection-tolerant Greek match: equal, or one a prefix of the other for
   stems of length >= 4 (so νόμος/νόμο/νόμοι and παραγραφή/παραγραφής match)."
  (let ((la (length a)) (lb (length b)))
    (cond ((string= a b) t)
          ((and (>= la 4) (>= lb 4))
           (let ((m (min la lb)))
             (string= a b :end1 m :end2 m)))
          (t nil))))

(defun provision-fulltext (p)
  "Heading + own text + all descendant text of provision P."
  (with-output-to-string (s)
    (when (provision-heading p) (write-string (provision-heading p) s) (write-char #\Space s))
    (labels ((walk (x)
               (when (provision-text x) (write-string (provision-text x) s) (write-char #\Space s))
               (dolist (c (provision-children x)) (walk c))))
      (walk p))))

;;; ----------------------------------------------------------------------------
;;; JSON
;;; ----------------------------------------------------------------------------

(defun jstr (x)
  (with-output-to-string (s)
    (write-char #\" s)
    (loop for ch across (princ-to-string (or x ""))
          do (case ch
               (#\" (write-string "\\\"" s)) (#\\ (write-string "\\\\" s))
               (#\Newline (write-string "\\n" s)) (#\Return (write-string "\\r" s))
               (#\Tab (write-string "\\t" s)) (t (write-char ch s))))
    (write-char #\" s)))

(defun snippet (text &optional (n 200))
  (let ((tt (string-trim '(#\Space #\Newline #\Tab) (or text ""))))
    (if (> (length tt) n) (concatenate 'string (subseq tt 0 n) "…") tt)))

;;; ----------------------------------------------------------------------------
;;; SEARCH
;;; ----------------------------------------------------------------------------

(defun search-corpus (document query &key (limit 20) (base-uri "https://stavropouloslaw.com/eli"))
  "Rank the articles of DOCUMENT by how many distinct QUERY terms they contain
   (accent-folded Greek tokens). Returns a JSON results object string."
  (let* ((qterms (remove-duplicates (tokens-of query) :test #'string=))
         (hits '()))
    (when qterms
      (dolist (article (legal-document-provisions document))
        (let* ((ptoks (tokens-of (provision-fulltext article)))
               (score (count-if (lambda (qt) (some (lambda (pt) (term-match-p qt pt)) ptoks))
                                qterms)))
          (when (plusp score)
            (push (list :eid (provision-eid article)
                        :num (provision-num article)
                        :heading (provision-heading article)
                        :score score
                        :in-force (not (eq (provision-status article) :repealed))
                        :text (provision-fulltext article))
                  hits)))))
    ;; rank: score desc, then eId asc (deterministic)
    (setf hits (stable-sort (nreverse hits)
                            (lambda (a b)
                              (cond ((> (getf a :score) (getf b :score)) t)
                                    ((< (getf a :score) (getf b :score)) nil)
                                    (t (string< (getf a :eid) (getf b :eid)))))))
    (when (and limit (> (length hits) limit)) (setf hits (subseq hits 0 limit)))
    (with-output-to-string (s)
      (format s "{\"query\":~A,\"terms\":[~{~A~^,~}],\"count\":~D,\"results\":["
              (jstr query) (mapcar #'jstr qterms) (length hits))
      (loop for h in hits for firstp = t then nil
            do (unless firstp (write-string "," s))
               (format s "{\"@id\":~A,\"eId\":~A,\"number\":~A,\"heading\":~A,~
\"score\":~D,\"in_force\":~A,\"snippet\":~A}"
                       (jstr (format nil "~A/~A" base-uri (getf h :eid)))
                       (jstr (getf h :eid)) (jstr (getf h :num)) (jstr (getf h :heading))
                       (getf h :score) (if (getf h :in-force) "true" "false")
                       (jstr (snippet (getf h :text)))))
      (write-string "]}" s))))
