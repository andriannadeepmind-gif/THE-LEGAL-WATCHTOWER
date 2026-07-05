;;;; source/turtle-parser.lisp
;;;; ============================================================================
;;;; TURTLE PARSER (pure Common Lisp)
;;;; ============================================================================
;;;;
;;;; Parses a useful subset of RDF 1.1 Turtle into a flat list of triples, for
;;;; use by the SHACL validator. Supports:
;;;;   - @prefix / @base directives and PNAME prefix expansion
;;;;   - IRIs <...>, prefixed names (pfx:local, :local), the `a` keyword
;;;;   - String literals "..." with \\-escapes, optional @lang or ^^datatype
;;;;   - Integer / decimal / double numbers, true/false booleans
;;;;   - Predicate-object lists (;), object lists (,)
;;;;   - Blank node property lists [ ... ] and labelled blanks _:b
;;;;   - RDF collections ( ... )  (rdf:first/rdf:rest/rdf:nil)
;;;;   - # comments
;;;;
;;;; Terms are represented by RDF-TERM structs (kind :iri / :literal / :blank).
;;;; This is enough to parse both the corpus's emitted TTL and SHACL shapes.
;;;; ============================================================================

(defpackage :orchestrator.turtle
  (:use :cl)
  (:export
   #:rdf-term #:make-rdf-term #:rdf-term-p
   #:rdf-term-kind #:rdf-term-value #:rdf-term-datatype #:rdf-term-lang
   #:iri #:literal #:blank #:term-iri-p #:term-literal-p #:term-blank-p
   #:term= #:term-string
   #:triple-s #:triple-p #:triple-o
   #:parse-turtle #:turtle-parse-error))

(in-package :orchestrator.turtle)

(define-condition turtle-parse-error (error)
  ((message :initarg :message :reader turtle-parse-error-message)
   (pos :initarg :pos :reader turtle-parse-error-pos :initform nil))
  (:report (lambda (c s)
             (format s "Turtle parse error~@[ at ~D~]: ~A"
                     (turtle-parse-error-pos c) (turtle-parse-error-message c)))))

;;; ============================================================================
;;; TERM MODEL
;;; ============================================================================

(defstruct (rdf-term (:constructor %make-rdf-term))
  (kind :iri :type keyword)              ; :iri :literal :blank
  (value "" :type string)               ; IRI string / lexical form / blank id
  (datatype nil :type (or null string)) ; literal datatype IRI
  (lang nil :type (or null string)))    ; literal language tag

(defun iri (string) (%make-rdf-term :kind :iri :value string))
(defun literal (value &key datatype lang)
  (%make-rdf-term :kind :literal :value value :datatype datatype :lang lang))
(defun blank (id) (%make-rdf-term :kind :blank :value id))
(defun make-rdf-term (&rest args) (apply #'%make-rdf-term args))

(defun term-iri-p (term) (eq (rdf-term-kind term) :iri))
(defun term-literal-p (term) (eq (rdf-term-kind term) :literal))
(defun term-blank-p (term) (eq (rdf-term-kind term) :blank))

(defun term= (a b)
  (and (eq (rdf-term-kind a) (rdf-term-kind b))
       (string= (rdf-term-value a) (rdf-term-value b))
       (equal (rdf-term-datatype a) (rdf-term-datatype b))
       (equal (rdf-term-lang a) (rdf-term-lang b))))

(defun term-string (term)
  "A debug/readable string for a term."
  (ecase (rdf-term-kind term)
    (:iri (format nil "<~A>" (rdf-term-value term)))
    (:blank (format nil "_:~A" (rdf-term-value term)))
    (:literal (format nil "~S~@[@~A~]~@[^^<~A>~]"
                      (rdf-term-value term) (rdf-term-lang term)
                      (rdf-term-datatype term)))))

;; Triples are simple 3-element lists (s p o).
(defun triple-s (tr) (first tr))
(defun triple-p (tr) (second tr))
(defun triple-o (tr) (third tr))

;;; ============================================================================
;;; LEXER
;;; ============================================================================

(defstruct lexer (text "" :type string) (pos 0 :type fixnum) (len 0 :type fixnum))

(defun make-lex (text) (make-lexer :text text :pos 0 :len (length text)))

(declaim (inline lx-peek lx-eof))
(defun lx-peek (lx &optional (k 0))
  (let ((i (+ (lexer-pos lx) k)))
    (when (< i (lexer-len lx)) (char (lexer-text lx) i))))
(defun lx-eof (lx) (>= (lexer-pos lx) (lexer-len lx)))
(defun lx-next (lx) (prog1 (char (lexer-text lx) (lexer-pos lx)) (incf (lexer-pos lx))))

(defun ws-char-p (ch) (member ch '(#\Space #\Tab #\Newline #\Return #\Linefeed)))

(defun skip-ws-and-comments (lx)
  (loop
    (let ((ch (lx-peek lx)))
      (cond
        ((null ch) (return))
        ((ws-char-p ch) (lx-next lx))
        ((char= ch #\#)
         (loop for c = (lx-peek lx)
               until (or (null c) (char= c #\Newline))
               do (lx-next lx)))
        (t (return))))))

(defun pname-char-p (ch)
  (and ch (or (alphanumericp ch)
              (member ch '(#\_ #\: #\/ #\# #\- #\. #\% #\+ #\~ #\@)))))

(defun read-iriref (lx)
  (lx-next lx)                           ; consume <
  (with-output-to-string (s)
    (loop for ch = (lx-peek lx)
          do (cond
               ((null ch) (error 'turtle-parse-error :message "unterminated IRI"
                                 :pos (lexer-pos lx)))
               ((char= ch #\>) (lx-next lx) (return))
               ((char= ch #\\)            ; \uXXXX or escaped
                (lx-next lx)
                (let ((e (lx-next lx)))
                  (case e
                    (#\u (write-char (code-char (parse-integer
                                                 (coerce (loop repeat 4 collect (lx-next lx)) 'string)
                                                 :radix 16)) s))
                    (#\U (write-char (code-char (parse-integer
                                                 (coerce (loop repeat 8 collect (lx-next lx)) 'string)
                                                 :radix 16)) s))
                    (t (write-char e s)))))
               (t (write-char (lx-next lx) s))))))

(defun read-string-literal (lx)
  "Read a \"...\" or \"\"\"...\"\"\" string body (quote already at pos). Returns the
   decoded string."
  (let ((long (and (eql (lx-peek lx) #\")
                   (eql (lx-peek lx 1) #\")
                   (eql (lx-peek lx 2) #\"))))
    (if long (progn (lx-next lx) (lx-next lx) (lx-next lx))
        (lx-next lx))
    (with-output-to-string (s)
      (loop
        (let ((ch (lx-peek lx)))
          (when (null ch)
            (error 'turtle-parse-error :message "unterminated string" :pos (lexer-pos lx)))
          (cond
            ((char= ch #\\)
             (lx-next lx)
             (let ((e (lx-next lx)))
               (case e
                 (#\n (write-char #\Newline s))
                 (#\t (write-char #\Tab s))
                 (#\r (write-char #\Return s))
                 (#\\ (write-char #\\ s))
                 (#\" (write-char #\" s))
                 (#\' (write-char #\' s))
                 (#\u (write-char (code-char (parse-integer
                                              (coerce (loop repeat 4 collect (lx-next lx)) 'string)
                                              :radix 16)) s))
                 (#\U (write-char (code-char (parse-integer
                                              (coerce (loop repeat 8 collect (lx-next lx)) 'string)
                                              :radix 16)) s))
                 (t (write-char e s)))))
            ((char= ch #\")
             (cond
               (long (if (and (eql (lx-peek lx 1) #\") (eql (lx-peek lx 2) #\"))
                         (progn (lx-next lx) (lx-next lx) (lx-next lx) (return))
                         (progn (write-char (lx-next lx) s))))
               (t (lx-next lx) (return))))
            (t (write-char (lx-next lx) s))))))))

;;; ============================================================================
;;; PARSER
;;; ============================================================================

(defstruct parser
  lexer
  (prefixes (make-hash-table :test 'equal))
  (base nil)
  (triples '())
  (blank-counter 0))

(defun fresh-blank (p)
  (blank (format nil "b~D" (incf (parser-blank-counter p)))))

(defun emit (p s pred o)
  (push (list s pred o) (parser-triples p)))

(defun expand-pname (p prefix local)
  (let ((ns (gethash prefix (parser-prefixes p))))
    (unless ns
      (error 'turtle-parse-error :message (format nil "unknown prefix ~S" prefix)))
    (iri (concatenate 'string ns local))))

(defparameter +rdf-type+ "http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
(defparameter +xsd-integer+ "http://www.w3.org/2001/XMLSchema#integer")
(defparameter +xsd-decimal+ "http://www.w3.org/2001/XMLSchema#decimal")
(defparameter +xsd-double+ "http://www.w3.org/2001/XMLSchema#double")
(defparameter +xsd-boolean+ "http://www.w3.org/2001/XMLSchema#boolean")

(defun read-pname-or-keyword (lx)
  "Read a bareword token: returns a string of the raw token."
  (with-output-to-string (s)
    (loop for ch = (lx-peek lx)
          while (pname-char-p ch)
          do (write-char (lx-next lx) s))))

(defun strip-trailing-dots (token)
  "Turtle PN_LOCAL/number may not end with '.'; trailing dots are terminators.
   Returns (values cleaned n-dots)."
  (let ((end (length token)))
    (loop while (and (> end 0) (char= (char token (1- end)) #\.))
          do (decf end))
    (values (subseq token 0 end) (- (length token) end))))

(defun number-token-p (token)
  (and (plusp (length token))
       (every (lambda (c) (or (digit-char-p c) (member c '(#\- #\+ #\. #\e #\E)))) token)
       (some #'digit-char-p token)))

(defun parse-object-token (p lx token)
  "Interpret a bareword TOKEN (already read) as an object/term."
  (declare (ignore lx))
  (cond
    ((string= token "a") (iri +rdf-type+))
    ((string= token "true") (literal "true" :datatype +xsd-boolean+))
    ((string= token "false") (literal "false" :datatype +xsd-boolean+))
    ((number-token-p token)
     (literal token :datatype (cond ((find #\e token :test #'char-equal) +xsd-double+)
                                    ((find #\. token) +xsd-decimal+)
                                    (t +xsd-integer+))))
    ((find #\: token)
     (let ((cidx (position #\: token)))
       (expand-pname p (subseq token 0 cidx) (subseq token (1+ cidx)))))
    (t (error 'turtle-parse-error :message (format nil "unexpected token ~S" token)))))

(defun parse-term (p lx)
  "Parse a single subject/object term, including [ ] and ( )."
  (skip-ws-and-comments lx)
  (let ((ch (lx-peek lx)))
    (when (null ch)
      (error 'turtle-parse-error :message "unexpected EOF" :pos (lexer-pos lx)))
    (cond
      ((char= ch #\<)
       (iri (read-iriref lx)))
      ((char= ch #\")
       (let ((val (read-string-literal lx))
             (lang nil) (dt nil))
         (when (eql (lx-peek lx) #\@)
           (lx-next lx)
           (setf lang (string-downcase
                       (with-output-to-string (s)
                         (loop for c = (lx-peek lx)
                               while (and c (or (alpha-char-p c) (char= c #\-)))
                               do (write-char (lx-next lx) s))))))
         (when (and (eql (lx-peek lx) #\^) (eql (lx-peek lx 1) #\^))
           (lx-next lx) (lx-next lx)
           (skip-ws-and-comments lx)
           (let ((dterm (parse-term p lx)))
             (setf dt (rdf-term-value dterm))))
         (literal val :lang lang :datatype dt)))
      ((char= ch #\[)
       (lx-next lx)                            ; [
       (let ((b (fresh-blank p)))
         (skip-ws-and-comments lx)
         (unless (eql (lx-peek lx) #\])
           (parse-predicate-object-list p lx b))
         (skip-ws-and-comments lx)
         (unless (eql (lx-peek lx) #\])
           (error 'turtle-parse-error :message "expected ]" :pos (lexer-pos lx)))
         (lx-next lx)                          ; ]
         b))
      ((char= ch #\()                          ; RDF collection
       (lx-next lx)
       (parse-collection p lx))
      ((char= ch #\_)                          ; _:label
       (read-pname-or-keyword lx)              ; consume but...
       ;; re-read properly:
       (error 'turtle-parse-error :message "labelled blank handled separately"))
      (t
       (let ((raw (read-pname-or-keyword lx)))
         (multiple-value-bind (clean dots) (strip-trailing-dots raw)
           (when (plusp dots)
             ;; push back the dots so the statement parser sees the terminator
             (decf (lexer-pos lx) dots))
           (parse-object-token p lx clean)))))))

(defun parse-collection (p lx)
  "Parse ( a b c ) into an rdf:first/rdf:rest list, returning its head term."
  (let ((rdf-first "http://www.w3.org/1999/02/22-rdf-syntax-ns#first")
        (rdf-rest "http://www.w3.org/1999/02/22-rdf-syntax-ns#rest")
        (rdf-nil "http://www.w3.org/1999/02/22-rdf-syntax-ns#nil")
        (items '()))
    (loop
      (skip-ws-and-comments lx)
      (when (eql (lx-peek lx) #\)) (lx-next lx) (return))
      (push (parse-term-or-blank p lx) items))
    (setf items (nreverse items))
    (if (null items)
        (iri rdf-nil)
        (let ((head (fresh-blank p)) (prev nil))
          (let ((node head))
            (dolist (it items)
              (when prev (emit p prev (iri rdf-rest) node))
              (emit p node (iri rdf-first) it)
              (setf prev node node (fresh-blank p)))
            (emit p prev (iri rdf-rest) (iri rdf-nil)))
          head))))

(defun parse-term-or-blank (p lx)
  "Like parse-term but also handles _:label blanks."
  (skip-ws-and-comments lx)
  (if (and (eql (lx-peek lx) #\_) (eql (lx-peek lx 1) #\:))
      (progn (lx-next lx) (lx-next lx)
             (blank (concatenate 'string "u" (nth-value 0 (strip-trailing-dots
                                                           (read-pname-or-keyword lx))))))
      (parse-term p lx)))

(defun parse-predicate-object-list (p lx subject)
  "Parse 'pred obj (, obj)* (; pred obj ...)*' for SUBJECT."
  (loop
    (skip-ws-and-comments lx)
    (let ((ch (lx-peek lx)))
      (when (or (null ch) (member ch '(#\. #\] )))
        (return)))
    ;; predicate
    (let ((pred (parse-term-or-blank p lx)))
      (loop
        (let ((obj (parse-term-or-blank p lx)))
          (emit p subject pred obj))
        (skip-ws-and-comments lx)
        (if (eql (lx-peek lx) #\,)
            (lx-next lx)
            (return))))
    (skip-ws-and-comments lx)
    (if (eql (lx-peek lx) #\;)
        (progn (lx-next lx)
               (skip-ws-and-comments lx)
               ;; allow trailing ; before . or ]
               (when (member (lx-peek lx) '(#\. #\]))
                 (return)))
        (return))))

(defun parse-directive (p lx)
  "Parse @prefix or @base (the @ already consumed via token)."
  (let ((kw (read-pname-or-keyword lx)))
    (cond
      ((string= kw "prefix")
       (skip-ws-and-comments lx)
       (let* ((raw (read-pname-or-keyword lx))
              (prefix (subseq raw 0 (position #\: raw))))
         (skip-ws-and-comments lx)
         (let ((ns (read-iriref lx)))
           (setf (gethash prefix (parser-prefixes p)) ns))
         (skip-ws-and-comments lx)
         (when (eql (lx-peek lx) #\.) (lx-next lx))))
      ((string= kw "base")
       (skip-ws-and-comments lx)
       (setf (parser-base p) (read-iriref lx))
       (skip-ws-and-comments lx)
       (when (eql (lx-peek lx) #\.) (lx-next lx)))
      (t (error 'turtle-parse-error :message (format nil "unknown directive @~A" kw))))))

(defun parse-statement (p lx)
  (skip-ws-and-comments lx)
  (when (lx-eof lx) (return-from parse-statement nil))
  (let ((ch (lx-peek lx)))
    (cond
      ((char= ch #\@) (lx-next lx) (parse-directive p lx) t)
      (t
       (let ((subject (parse-term-or-blank p lx)))
         (parse-predicate-object-list p lx subject)
         (skip-ws-and-comments lx)
         (when (eql (lx-peek lx) #\.) (lx-next lx))
         t)))))

(defun parse-turtle (text)
  "Parse TEXT (a Turtle string) into a list of (subject predicate object)
   triples whose terms are RDF-TERM structs."
  (let ((p (make-parser :lexer (make-lex text))))
    (loop while (progn (skip-ws-and-comments (parser-lexer p))
                       (not (lx-eof (parser-lexer p))))
          do (unless (parse-statement p (parser-lexer p)) (return)))
    (nreverse (parser-triples p))))
