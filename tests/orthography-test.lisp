;;;; tests/orthography-test.lisp
;;;; The learned-orthography authority, re-homed as a greek-nlp LEXICON backend.
;;;; This LOCKS the exact restoration behaviour (the cases that matter: restore a
;;;; dropped accent, remove a wrong one, never touch the η/ή που/πού πως/πώς
;;;; homographs, leave genuine ambiguities for review) AND proves the lexicon now
;;;; conforms to and composes with the unified CLOS lexicon protocol.

(in-package :orchestrator.orthography)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun rep (n word) (with-output-to-string (s) (dotimes (i n) (write-string word s) (write-char #\Space s))))

;; A training corpus that attests the canonical spellings dominantly (≥95%),
;; plus genuine ambiguities and the protected homographs.
(defparameter *corpus*
  (concatenate 'string
    (rep 30 "όποιος") "Οποιος "              ; accented dominant → restore dropped accent
    (rep 30 "της")    "τής "                 ; unaccented dominant → remove wrong accent
    (rep 20 "πιο")    "πιό "                 ; "πιο" takes no accent
    (rep 20 "για")    "γιά "                 ; "για" takes no accent
    (rep 10 "πότε") (rep 10 "ποτέ")          ; two accented forms → ambiguous
    "ή η πού που πώς πως "))                  ; the protected homographs

(defparameter *lex* (learn-orthography *corpus*))

(format t "~%== restoration: drop-accent restored, wrong-accent removed ==~%")
(check "a dropped accent is restored, case preserved (Οποιος → Όποιος)"
       (string= "Όποιος" (restore-word-orthography "Οποιος" *lex*)))
(check "the canonical accented form is left alone (όποιος → όποιος)"
       (string= "όποιος" (restore-word-orthography "όποιος" *lex*)))
(check "a wrong accent is removed (τής → της)"
       (string= "της" (restore-word-orthography "τής" *lex*)))
(check "πιό → πιο (the corpus says it takes no accent)"
       (string= "πιο" (restore-word-orthography "πιό" *lex*)))
(check "γιά → για"
       (string= "για" (restore-word-orthography "γιά" *lex*)))

(format t "~%== the protected monotonic homographs are NEVER touched ==~%")
(dolist (pair '(("η" . "η") ("ή" . "ή") ("που" . "που") ("πού" . "πού") ("πως" . "πως") ("πώς" . "πώς")))
  (check (format nil "~A stays ~A" (car pair) (cdr pair))
         (string= (cdr pair) (restore-word-orthography (car pair) *lex*))))

(format t "~%== genuine ambiguity is left untouched and surfaced for review ==~%")
(check "an ambiguous skeleton (ποτε: πότε/ποτέ) is left unchanged"
       (string= "ποτε" (restore-word-orthography "ποτε" *lex*)))
(check "the ambiguity is reported for the human review queue"
       (member "ποτε" (orthography-ambiguities "το ποτε είναι ασαφές" *lex*) :test #'string=))
(check "a resolved word is NOT reported as ambiguous"
       (not (member "οποιος" (orthography-ambiguities "οποιος" *lex*) :test #'string=)))

(format t "~%== whole-text restoration is deterministic ==~%")
(check "restore-orthography fixes a sentence in place"
       (string= "Όποιος έχει της πιο για"
                (restore-orthography "Οποιος έχει τής πιό γιά" *lex*)))
(check "same input, same output (deterministic)"
       (string= (restore-orthography "Οποιος τής" *lex*)
                (restore-orthography "Οποιος τής" *lex*)))

(format t "~%== it IS a greek-nlp lexicon (protocol conformance + composability) ==~%")
(check "the learned lexicon is a greek-nlp lexicon"
       (typep *lex* 'orchestrator.greek-nlp:lexicon))
(check "lexicon-lookup returns (:canonical FORM) for a resolved word"
       (equal '(:canonical "όποιος") (orchestrator.greek-nlp:lexicon-lookup *lex* "Οποιος")))
(check "lexicon-lookup returns (:ambiguous T) for a contested skeleton"
       (equal '(:ambiguous t) (orchestrator.greek-nlp:lexicon-lookup *lex* "ποτε")))
(check "lexicon-lookup returns NIL for an unseen word"
       (null (orchestrator.greek-nlp:lexicon-lookup *lex* "ξυλοδαρμός")))
(check "lexicon-size reflects the learned skeletons" (plusp (orchestrator.greek-nlp:lexicon-size *lex*)))
(check "it composes with another backend via composite-lexicon"
       (let ((comp (orchestrator.greek-nlp::make-composite-lexicon
                    "all" (list *lex*) :strategy :first-match)))
         (equal '(:canonical "της") (orchestrator.greek-nlp:lexicon-lookup comp "τής"))))

(format t "~%========================================~%")
(format t "Orthography tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
