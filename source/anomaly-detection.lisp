;;;; source/anomaly-detection.lisp
;;;; ============================================================================
;;;; ANOMALY SELF-DETECTION  (the system reflects on its own output)
;;;; ============================================================================
;;;;
;;;; Beyond the structural invariants (no gap, no duplicate, no empty article),
;;;; this layer inspects each consolidated article for the SIGNATURES of an
;;;; extraction error that is still well-formed structurally: leftover source
;;;; chrome or editorial markers, text that is mostly non-Greek (garbled or wrong
;;;; script), or no letters at all. Each finding names the exact article and a
;;;; reason — a precise, explainable signal for the human review queue.
;;;;
;;;; Deterministic and high-precision (it flags only clear extraction signatures,
;;;; never penalises a legitimately short or repealed article).
;;;; ============================================================================

(defpackage :orchestrator.anomaly
  (:use :cl)
  (:export #:article-anomalies #:detect-anomalies #:format-anomalies
           #:greek-letter-ratio))

(in-package :orchestrator.anomaly)

(macrolet ((bind (&rest names)
             `(progn
                ,@(loop for n in names
                        collect `(defun ,(intern (format nil "%~A" n))
                                     (&rest args)
                                   (apply (find-symbol ,(string n) :orchestrator.consolidation)
                                          args))))))
  (bind legal-document-provisions provision-eid provision-text provision-children))

(defun %full-text (p)
  (with-output-to-string (s)
    (let ((tx (%provision-text p))) (when tx (write-string tx s) (write-char #\Space s)))
    (dolist (c (%provision-children p)) (write-string (%full-text c) s))))

(defun %greek-letter-p (c)
  (let ((code (char-code c)))
    (or (<= #x0370 code #x03FF) (<= #x1F00 code #x1FFF))))

(defun greek-letter-ratio (text)
  "Greek letters as a fraction of all alphabetic characters (1.0 if no letters)."
  (let ((letters 0) (greek 0))
    (loop for c across text
          when (alpha-char-p c)
          do (incf letters) (when (%greek-letter-p c) (incf greek)))
    (if (zerop letters) 1.0 (/ greek letters 1.0))))

(defparameter *residual-noise-scanner*
  (cl-ppcre:create-scanner "[*#^]|https?://|www\\.|dsanet|print_law_record|ΟΘΟΝΗ\\s+ΕΚΤΥΠΩΣΗΣ")
  "Signatures of source chrome / editorial markers that should have been cleaned.")

(defun article-anomalies (text &key (min-letters 15) (min-greek-ratio 0.6))
  "Return the list of anomaly reasons for an article's TEXT (NIL if clean):
     :empty                 - no substantive text
     :no-greek-letters      - has content but not a single Greek letter
     :low-greek-ratio       - mostly non-Greek letters (garbled / wrong script)
     :residual-extraction-noise - leftover *,#,^, a URL, or print chrome."
  (let* ((tx (string-trim '(#\Space #\Tab #\Newline #\Return) (or text "")))
         (reasons '())
         (letters (count-if #'alpha-char-p tx))
         (greek (count-if (lambda (c) (and (alpha-char-p c) (%greek-letter-p c))) tx)))
    (cond ((zerop (length tx)) (push :empty reasons))
          ((zerop greek) (when (plusp letters) (push :no-greek-letters reasons)))
          ((and (>= letters min-letters)
                (< (/ greek letters 1.0) min-greek-ratio))
           (push :low-greek-ratio reasons)))
    (when (cl-ppcre:scan *residual-noise-scanner* tx)
      (push :residual-extraction-noise reasons))
    (nreverse reasons)))

(defun detect-anomalies (doc &key (min-letters 15) (min-greek-ratio 0.6))
  "Return (values ok-p findings); FINDINGS is a list of (article-id . reasons)
   for every article showing an extraction-error signature."
  (let ((findings '()))
    (dolist (p (%legal-document-provisions doc))
      (let ((reasons (article-anomalies (%full-text p)
                                        :min-letters min-letters
                                        :min-greek-ratio min-greek-ratio)))
        (when reasons
          (let* ((eid (%provision-eid p))
                 (us (position #\_ eid :from-end t)))
            (push (cons (if us (subseq eid (1+ us)) eid) reasons) findings)))))
    (let ((f (nreverse findings)))
      (values (null f) f))))

(defun format-anomalies (findings &optional (stream nil))
  (if (null findings)
      (format stream "✓ καμία ανωμαλία εξαγωγής — όλα τα άρθρα φαίνονται καθαρά")
      (format stream "⚠ ~D άρθρο(α) με ύποπτη υπογραφή (για έλεγχο):~{~%  · άρθρο ~A: ~{~A~^, ~}~}"
              (length findings)
              (loop for (id . reasons) in findings append (list id reasons)))))
