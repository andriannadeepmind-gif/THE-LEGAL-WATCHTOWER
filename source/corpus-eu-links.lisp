;;;; source/corpus-eu-links.lisp
;;;; ============================================================================
;;;; NATIONAL ↔ EU LAW LINKING  ("which EU act does this article implement/cite")
;;;; ============================================================================
;;;;
;;;; Greek legislation constantly cites EU directives, regulations and decisions
;;;; ("Οδηγία 2011/83/ΕΕ", "Κανονισμός (ΕΕ) 2016/679", "Κανονισμός (ΕΚ) αριθ.
;;;; 178/2002", "Οδηγία 93/13/ΕΟΚ"). This bridge scans the consolidated text and,
;;;; for every reference, mints the OFFICIAL European identifiers:
;;;;   * CELEX number  (e.g. 32011L0083)
;;;;   * ELI URI       (e.g. http://data.europa.eu/eli/dir/2011/83/oj)
;;;;   * EUR-Lex URL   (deep link into the official portal)
;;;;
;;;; These are exactly the identifiers orchestrator.eu-interop (EUR-Lex / CELLAR
;;;; clients) consumes, so an online deployment can fetch the full EU document
;;;; for any link. The scan itself is deterministic and offline — byte-identical
;;;; output across runs. Exposed as /<corpus>/eu-references.
;;;; ============================================================================

(defpackage :orchestrator.corpus-eu-links
  (:use :cl)
  (:export #:corpus-eu-references #:detect-eu-references
           #:eu-celex #:eu-eli #:eu-eurlex-url))

(in-package :orchestrator.corpus-eu-links)

(defparameter +gl+ "[α-ωΑ-Ωάέήίόύώΐΰϊϋϊ]"
  "A Greek letter (the vendored cl-ppcre has no \\p{L} support).")

(defparameter +eu-ref-scanner+
  (cl-ppcre:create-scanner
   (format nil "(Οδηγ~A*|οδηγ~A*|Κανονισμ~A*|κανονισμ~A*|Απόφασ~A*|απόφασ~A*)~
                \\s*(?:\\([Α-ΩA-Z]+\\)\\s*)?(?:αριθ\\.?\\s*)?(\\d{1,4})/(\\d{1,4})"
           +gl+ +gl+ +gl+ +gl+ +gl+ +gl+))
  "Captures: 1=Greek act word (Οδηγία/Κανονισμός/Απόφαση …), 2=first number,
   3=second number. An optional (ΕΕ)/(ΕΚ)/(ΕΟΚ) union marker and 'αριθ.' are
   skipped between them.")

(defun %act-kind (word)
  "Classify the matched Greek act word into a kind keyword."
  (let ((w (string-downcase word)))
    (cond ((and (>= (length w) 4) (string= (subseq w 0 4) "οδηγ")) :directive)
          ((and (>= (length w) 7) (string= (subseq w 0 7) "κανονισ")) :regulation)
          ((and (>= (length w) 5) (string= (subseq w 0 5) "απόφα")) :decision)
          (t nil))))

(defun %year-number (a b)
  "Normalise the two captured numbers to (VALUES year number). EU acts are
   written YEAR/NUMBER, but older 'αριθ. N/YEAR' forms invert that, and the
   pre-2000 directives use a 2-digit year (93/13)."
  (let ((ai (parse-integer a)) (bi (parse-integer b)))
    (cond ((>= (length a) 4) (values ai bi))            ; 2011/83
          ((>= (length b) 4) (values bi ai))            ; αριθ. 178/2002
          ((>= ai 70) (values (+ 1900 ai) bi))          ; 93/13 -> 1993/13
          (t (values (+ 2000 ai) bi)))))                ; 05/29 -> 2005/29

(defun eu-celex (kind year number)
  "Official CELEX number, e.g. (:directive 2011 83) -> \"32011L0083\"."
  (format nil "3~4,'0D~A~4,'0D" year
          (ecase kind (:directive "L") (:regulation "R") (:decision "D"))
          number))

(defun eu-eli (kind year number)
  "Official ELI URI on data.europa.eu."
  (format nil "http://data.europa.eu/eli/~A/~D/~D/oj"
          (ecase kind (:directive "dir") (:regulation "reg") (:decision "dec"))
          year number))

(defun eu-eurlex-url (celex)
  "Deep link into the EUR-Lex portal (Greek language tab)."
  (format nil "https://eur-lex.europa.eu/legal-content/EL/TXT/?uri=CELEX:~A" celex))

(defun detect-eu-references (text)
  "Return the de-duplicated list of EU-law references found in TEXT, each a
   plist (:kind :year :number :celex :eli :eurlex :label), in first-seen order."
  (let ((seen (make-hash-table :test 'equal))
        (out '()))
    (cl-ppcre:do-scans (ms me rs re +eu-ref-scanner+ (or text ""))
      (flet ((grp (i) (when (aref rs i)
                        (subseq text (aref rs i) (aref re i)))))
        (let ((kind (%act-kind (grp 0))))
          (when kind
            (multiple-value-bind (year number) (%year-number (grp 1) (grp 2))
              (let ((celex (eu-celex kind year number)))
                (unless (gethash celex seen)
                  (setf (gethash celex seen) t)
                  (push (list :kind kind :year year :number number
                              :celex celex
                              :eli (eu-eli kind year number)
                              :eurlex (eu-eurlex-url celex)
                              :label (format nil "~A ~D/~D"
                                             (ecase kind (:directive "Οδηγία")
                                               (:regulation "Κανονισμός")
                                               (:decision "Απόφαση"))
                                             year number))
                        out))))))))
    (nreverse out)))

;;; ---------------------------------------------------------------------------
;;; JSON emission
;;; ---------------------------------------------------------------------------

(defun %cons (name) (find-symbol name :orchestrator.consolidation))

(defun %article-text (p)
  (with-output-to-string (s)
    (labels ((walk (x)
               (let ((tx (funcall (%cons "PROVISION-TEXT") x)))
                 (when tx (write-string tx s) (write-char #\Space s)))
               (dolist (c (funcall (%cons "PROVISION-CHILDREN") x)) (walk c))))
      (walk p))))

(defun jstr (x)
  (with-output-to-string (s)
    (write-char #\" s)
    (loop for ch across (princ-to-string (or x ""))
          do (case ch
               (#\" (write-string "\\\"" s)) (#\\ (write-string "\\\\" s))
               (#\Newline (write-string "\\n" s)) (#\Return (write-string "\\r" s))
               (#\Tab (write-string "\\t" s)) (t (write-char ch s))))
    (write-char #\" s)))

(defun %ref->json (r)
  (format nil "{\"type\":~A,\"label\":~A,\"year\":~D,\"number\":~D,~
\"celex\":~A,\"eli\":~A,\"eurlex\":~A}"
          (jstr (string-downcase (symbol-name (getf r :kind))))
          (jstr (getf r :label)) (getf r :year) (getf r :number)
          (jstr (getf r :celex)) (jstr (getf r :eli)) (jstr (getf r :eurlex))))

(defun corpus-eu-references (document &key (base-uri "https://stavropouloslaw.com/eli"))
  "Scan the consolidated DOCUMENT and return a JSON object linking each article
   that cites EU law to the official EU identifiers (CELEX / ELI / EUR-Lex)."
  (let ((articles '()) (total 0))
    (dolist (p (funcall (%cons "LEGAL-DOCUMENT-PROVISIONS") document))
      (let ((refs (detect-eu-references (%article-text p))))
        (when refs
          (incf total (length refs))
          (push (list :eid (funcall (%cons "PROVISION-EID") p)
                      :num (funcall (%cons "PROVISION-NUM") p)
                      :heading (funcall (%cons "PROVISION-HEADING") p)
                      :refs refs)
                articles))))
    (setf articles (nreverse articles))
    (with-output-to-string (s)
      (format s "{\"corpus\":~A,\"references\":~D,\"articles_with_references\":~D,\"articles\":["
              (jstr base-uri) total (length articles))
      (loop for a in articles for firstp = t then nil
            do (unless firstp (write-char #\, s))
               (format s "{\"@id\":~A,\"eId\":~A,\"number\":~A,\"heading\":~A,\"references\":["
                       (jstr (format nil "~A/~A" base-uri (getf a :eid)))
                       (jstr (getf a :eid)) (jstr (getf a :num)) (jstr (getf a :heading)))
               (loop for r in (getf a :refs) for f2 = t then nil
                     do (unless f2 (write-char #\, s))
                        (write-string (%ref->json r) s))
               (write-string "]}" s))
      (write-string "]}" s))))
