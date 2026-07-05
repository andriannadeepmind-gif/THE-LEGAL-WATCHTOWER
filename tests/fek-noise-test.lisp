;;;; tests/fek-noise-test.lisp
;;;; Residual editorial-annotation artifacts that the corpus audit does NOT catch
;;;; must be removed AT THE ROOT, in the parser, so every source matches the rich
;;;; Constitution/Isokratis format. This suite pins each artifact class:
;;;;
;;;;   (1) spelled-out-ordinal chapter banners bleeding into bodies
;;;;       «ΕΚΤΟ ΚΕΦΑΛΑΙΟ:», «ΟΓΔΟΟ ΚΕΦΑΛΑΙΟ», «ΔΕΚΑΤΟ ΤΕΤΑΡΤΟ ΚΕΦΑΛΑΙΟ»
;;;;   (2) the bare/parenthesised editorial pointer «προσοχή && βλ. σχόλια»
;;;;   (3) a line-initial editorial attention bang «! »
;;;;   (4) the «&&» database operator
;;;;   (5) orphan single-letter extraction debris «ς ρ ρ»
;;;;   (6) a πλαγιότιτλος echoed at the head of the body (no duplication)
;;;;
;;;; Every removal is conservative: legitimate punctuation, single short Greek
;;;; words, trailing «!» and quoted amended text must survive untouched.

(in-package :orchestrator.engine.sbcl)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun art1-noise (text)
  "Parse TEXT and return its first article."
  (first (parse-fek-text text)))

(defun body-of-noise (art)
  (format nil "~{~A~^ ~}" (mapcar #'paragraph-text (article-paragraphs art))))

;;; (1) spelled-out-ordinal section banners are recognised as headers
(format t "~%== (1) spelled-ordinal section headers ==~%")
(check "ΕΚΤΟ ΚΕΦΑΛΑΙΟ: is a header"
       (section-header-in-text-p "ΕΚΤΟ ΚΕΦΑΛΑΙΟ: Περί εγκλημάτων κατά της ζωής"))
(check "ΟΓΔΟΟ ΚΕΦΑΛΑΙΟ is a header"
       (section-header-in-text-p "ΟΓΔΟΟ ΚΕΦΑΛΑΙΟ"))
(check "compound ΔΕΚΑΤΟ ΤΕΤΑΡΤΟ ΚΕΦΑΛΑΙΟ is a header"
       (section-header-in-text-p "ΔΕΚΑΤΟ ΤΕΤΑΡΤΟ ΚΕΦΑΛΑΙΟ: Εγκλήματα κατά της ιδιοκτησίας"))
(check "ΠΡΩΤΟ ΒΙΒΛΙΟ is a header"
       (section-header-in-text-p "ΠΡΩΤΟ ΒΙΒΛΙΟ"))
(check "normal sentence is NOT a header"
       (not (section-header-in-text-p "Όποιος με πρόθεση σκότωσε άλλον τιμωρείται.")))
(check "lowercase 'πρώτο κεφάλαιο' is NOT a header"
       (not (section-header-in-text-p "το πρώτο κεφάλαιο της σύμβασης")))

;;; assembled content has the banner line stripped
(format t "~%== (1b) banner stripped from assembled content ==~%")
(check "banner line removed, body kept"
       (let ((out (strip-section-headers-from-text
                   (format nil "ΕΚΤΟ ΚΕΦΑΛΑΙΟ: Περί ζωής~%Όποιος σκότωσε τιμωρείται."))))
         (and (not (search "ΚΕΦΑΛΑΙΟ" out)) (search "τιμωρείται" out))))

;;; (2)+(4) editorial pointer and && operator
(format t "~%== (2/4) editorial pointer & && operator ==~%")
(check "'προσοχή && βλ. σχόλια' removed"
       (let ((out (strip-isokratis-markers "Το κείμενο προσοχή && βλ. σχόλια συνεχίζεται.")))
         (and (not (search "προσοχή" out)) (not (search "&&" out))
              (not (search "σχόλια" out)) (search "Το κείμενο" out)
              (search "συνεχίζεται" out))))
(check "bare '&&' removed"
       (not (search "&&" (strip-isokratis-markers "Α && Β"))))
(check "parenthesised '(βλ. σχόλια)' still removed"
       (not (search "σχόλια" (strip-isokratis-markers "Κείμενο (βλ. σχόλια κατωτέρω) τέλος"))))

;;; (2b) STRUCTURAL: real Isokratis editorial preamble + ASCII-quote wrapper.
;;;      These are the EXACT strings observed in the materialised corpus.
(format t "~%== (2b) editorial preamble + quote wrapper (real data) ==~%")
(check "art_122: 'προσοχή && \"law\"' → unwraps to the law"
       (let ((out (strip-isokratis-markers
                   "προσοχή && \"1. Αναμορφωτικά μέτρα είναι: α) η επίπληξη του ανηλίκου.\"")))
         (and (not (search "προσοχή" out)) (not (search "&&" out))
              (not (search "\"" out))
              (search "Αναμορφωτικά μέτρα είναι" out))))
(check "art_1368: 'ΠΡΟΣΟΧΗ!!! Βλ. σχόλια \"law\"' → unwraps (uppercase+accents)"
       (let ((out (strip-isokratis-markers
                   "ΠΡΟΣΟΧΗ!!! Βλ. σχόλια \"Για να τελεσθεί ο γάμος απαιτείται άδεια.\"")))
         (and (not (search "ΠΡΟΣΟΧΗ" out)) (not (search "σχόλια" out))
              (not (search "!" out)) (not (search "\"" out))
              (search "Για να τελεσθεί ο γάμος" out))))
(check "legitimate in-text ASCII quote is NOT unwrapped"
       (let ((out (strip-isokratis-markers "Ο νόμος ορίζει \"το γραπτό δίκαιο\" ως πηγή.")))
         (and (search "Ο νόμος ορίζει" out) (search "το γραπτό δίκαιο" out)
              (search "ως πηγή" out))))

;;; (3) leading attention bang
(format t "~%== (3) leading editorial bang ==~%")
(check "leading '! ' removed"
       (let ((out (strip-isokratis-markers (format nil "! Όποιος σκότωσε άλλον."))))
         (and (not (search "!" out)) (search "Όποιος σκότωσε" out))))
(check "trailing '!' preserved"
       (search "!" (strip-isokratis-markers "Τιμωρείται!")))

;;; (5) orphan single-letter runs
(format t "~%== (5) orphan single-letter debris ==~%")
(check "'ς ρ ρ' run removed"
       (let ((out (strip-isokratis-markers "ς ρ ρ Αναιρετική διαδικασία")))
         (and (not (search "ς ρ ρ" out)) (search "Αναιρετική" out))))
(check "single article 'ο' preserved"
       (search "ο νόμος" (strip-isokratis-markers "ο νόμος ορίζει")))
(check "two single letters preserved (below run threshold)"
       (search "η ο" (strip-isokratis-markers "η ο πράξη")))

;;; (6) πλαγιότιτλος echoed at the head of the body — end-to-end
(format t "~%== (6) rubric echo not duplicated ==~%")
(let ((a (art1-noise (format nil "Άρθρο 8~%Παραγραφή των εγκλημάτων~%~
                                  Παραγραφή των εγκλημάτων. Τα εγκλήματα παραγράφονται μετά εικοσαετία."))))
  (check "rubric captured"
         (equal "Παραγραφή των εγκλημάτων" (article-rubric a)))
  (check "rubric NOT duplicated in body"
         (let ((b (body-of-noise a)))
           ;; the phrase must appear at most once across title+body — i.e. NOT in body
           (not (search "Παραγραφή των εγκλημάτων" b))))
  (check "real body retained"
         (search "παραγράφονται μετά εικοσαετία" (body-of-noise a))))

(format t "~%========================================~%")
(format t "ΦΕΚ editorial-artifact tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
