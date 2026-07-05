;;;; tests/greek-nlp-test.lisp
;;;; The Greek NLP core: a CLOS/MOP protocol where word knowledge (the lexicon)
;;;; and analysis (tokenize/lemmatize) are swappable behind generic functions.
;;;; This proves the protocol works end to end — built-in hash/composite backends,
;;;; a CUSTOM backend added purely by subclassing + a method (no core change), and
;;;; morphological fallback rules — so the architecture is genuinely live, not a stub.

(in-package :orchestrator.greek-nlp)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(format t "~%== tokenization (Greek text, multi-byte intact) ==~%")
(let ((toks (tokenize "Άρθρο 299 του Ποινικού Κώδικα")))
  (check "splits into the right number of tokens" (= 5 (length toks)))
  (check "tokens are case-folded for NLP (Άρθρο → άρθρο)" (string= "άρθρο" (first toks)))
  (check "the number is its own token" (member "299" toks :test #'string=))
  (check "an accented Greek word survives folding" (member "ποινικού" toks :test #'string=)))

(let ((objs (tokenize-text "Άρθρο 1" :preserve-case t)))
  (check "tokenize-text yields CLOS token objects" (every (lambda (o) (typep o 'token)) objs))
  (check "with :preserve-case the surface form is kept" (string= "Άρθρο" (token-text (first objs))))
  (check "token carries a character span" (consp (token-span (first objs)))))

(format t "~%== lexicon protocol: built-in hash-table backend ==~%")
(let ((lex (make-hash-table-lexicon "test")))
  (add-to-lexicon lex "άρθρου" (list :lemma "άρθρο" :pos :noun))
  (add-to-lexicon lex "νόμου"  (list :lemma "νόμος" :pos :noun))
  (check "lexicon-lookup returns the features plist"
         (string= "άρθρο" (getf (lexicon-lookup lex "άρθρου") :lemma)))
  (check "lookup is case-folded (Άρθρου → άρθρου)"
         (string= "άρθρο" (getf (lexicon-lookup lex "Άρθρου") :lemma)))
  (check "lexicon-size reflects entries" (= 2 (lexicon-size lex)))
  (check "lexicon-contains-p is true for a known word" (lexicon-contains-p lex "νόμου"))
  (check "lexicon-contains-p is false for an unknown word" (not (lexicon-contains-p lex "ξύλο")))
  ;; lemmatize driven by the active lexicon
  (let ((*active-lexicon* lex))
    (check "lemmatize uses the active lexicon" (equal '("άρθρο") (lemmatize "άρθρου")))))

(format t "~%== MOP: a CUSTOM lexicon backend added by subclass + method only ==~%")
;; The whole point of the protocol: new word-knowledge sources plug in with ZERO
;; change to the core — just a subclass of LEXICON and a LEXICON-LOOKUP method.
(defclass genitive-rule-lexicon (lexicon) ()
  (:documentation "A rule backend: Greek 2nd-declension genitive -ου → nominative -ος."))
(defmethod lexicon-lookup ((lex genitive-rule-lexicon) word)
  (let ((w (string-downcase word)))
    (when (and (> (length w) 2) (string= "ου" w :start2 (- (length w) 2)))
      (list :lemma (concatenate 'string (subseq w 0 (- (length w) 2)) "ος") :pos :noun))))
(defmethod lexicon-size ((lex genitive-rule-lexicon)) 0) ; rule-based: no finite entry set

(let ((lex (make-instance 'genitive-rule-lexicon :name "genitive-rules")))
  (check "generic lexicon-lookup dispatches to the custom backend"
         (string= "νόμος" (getf (lexicon-lookup lex "νόμου") :lemma)))
  (check "custom backend composes with the protocol (lemmatize)"
         (let ((*active-lexicon* lex)) (equal '("κώδικος") (lemmatize "κώδικου")))))

(format t "~%== composite lexicon: first-match fall-through across backends ==~%")
(let* ((a (make-hash-table-lexicon "primary"))
       (b (make-instance 'genitive-rule-lexicon :name "rules"))
       (comp (make-composite-lexicon "all" (list a b) :strategy :first-match)))
  (add-to-lexicon a "άρθρου" (list :lemma "άρθρο" :pos :noun)) ; authoritative override
  (check "primary backend wins when it has the word"
         (string= "άρθρο" (getf (lexicon-lookup comp "άρθρου") :lemma)))
  (check "falls through to the rule backend otherwise"
         (string= "νόμος" (getf (lexicon-lookup comp "νόμου") :lemma)))
  (check "composite size is the sum of its children" (= 1 (lexicon-size comp))))

(format t "~%== morphological fallback rules (no lexicon data needed) ==~%")
(let* ((lem (make-instance 'lemmatizer :fallback-rules '(("ου" . "ος"))))
       (out (analyze lem (tokenize-text "νόμου")))
       (*active-lexicon* nil))
  (check "a lemmatizer with rules reduces the word"
         (string= "νόμος" (token-lemma (first out)))))

(format t "~%== graceful degradation: no lexicon, no rules → passthrough ==~%")
(let ((*active-lexicon* nil))
  (check "lemmatize returns one lemma per token even with no knowledge"
         (= 2 (length (lemmatize "άγνωστη λέξη"))))
  (check "passthrough keeps the surface form" (equal '("άγνωστη" "λέξη") (lemmatize "άγνωστη λέξη"))))

(format t "~%========================================~%")
(format t "Greek NLP tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
