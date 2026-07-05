;;;; tests/anomaly-detection-test.lisp
;;;; The system reflects on its own output: high-precision extraction-error signatures.

(in-package :orchestrator.anomaly)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun mk (eid text) (orchestrator.consolidation:make-provision :eid eid :kind :article :text text))

(format t "~%== per-article signatures ==~%")
(check "clean Greek article: no anomaly"
       (null (article-anomalies "Όποιος με πρόθεση προξενεί σωματική βλάβη τιμωρείται με φυλάκιση.")))
(check "legitimately short/repealed article: NOT flagged"
       (null (article-anomalies "Παραλείπεται ως μη ισχύον.")))
(check "empty flagged" (member :empty (article-anomalies "   ")))
(check "residual marker flagged" (member :residual-extraction-noise (article-anomalies "κείμενο *** (βλ)")))
(check "leftover URL flagged" (member :residual-extraction-noise (article-anomalies "δες www.dsanet.gr/x")))
(check "no-greek (all latin) flagged"
       (member :no-greek-letters (article-anomalies "This article has only latin letters here")))
(check "mostly-latin garbled flagged"
       (member :low-greek-ratio (article-anomalies "ο νoμoσ has many latin lookalike words mixed in here badly")))
(check "pure punctuation/short is empty-ish not greek-ratio"
       (not (member :low-greek-ratio (article-anomalies "1. — («»)"))))

(format t "~%== greek-letter-ratio ==~%")
(check "all greek ~ 1.0" (> (greek-letter-ratio "ελληνικό κείμενο") 0.99))
(check "all latin ~ 0.0" (< (greek-letter-ratio "latin only") 0.01))

(format t "~%== document-level detection ==~%")
(let ((doc (orchestrator.consolidation:make-legal-document
            :id "syn"
            :provisions (list (mk "art_1" "Καθαρό ελληνικό άρθρο με κανονικό κείμενο.")
                              (mk "art_2" "Παραλείπεται ως μη ισχύον.")
                              (mk "art_3" "σκουπίδια *** ΟΘΟΝΗ ΕΚΤΥΠΩΣΗΣ leftover")
                              (mk "art_4" "")))))
  (multiple-value-bind (ok findings) (detect-anomalies doc)
    (check "not ok (some anomalies)" (not ok))
    (check "clean art 1 NOT flagged" (not (assoc "1" findings :test #'string=)))
    (check "repealed art 2 NOT flagged" (not (assoc "2" findings :test #'string=)))
    (check "noisy art 3 flagged" (assoc "3" findings :test #'string=))
    (check "empty art 4 flagged :empty"
           (member :empty (cdr (assoc "4" findings :test #'string=))))
    (check "report names the article" (search "άρθρο 3" (format-anomalies findings)))))

(format t "~%========================================~%")
(format t "Anomaly detection tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
