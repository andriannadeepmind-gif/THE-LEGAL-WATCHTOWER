;;;; tests/corpus-eu-links-test.lisp
;;;; National ↔ EU law linking: detect EU directive/regulation/decision
;;;; references in Greek text and mint official CELEX / ELI / EUR-Lex ids.
;;;; Deterministic, offline.

(in-package :orchestrator.corpus-eu-links)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun mp (&rest a) (apply (find-symbol "MAKE-PROVISION" :orchestrator.consolidation) a))
(defun md (&rest a) (apply (find-symbol "MAKE-LEGAL-DOCUMENT" :orchestrator.consolidation) a))

(format t "~%== Official EU identifier construction ==~%")
(check "directive 2011/83 -> CELEX 32011L0083" (string= (eu-celex :directive 2011 83) "32011L0083"))
(check "regulation 2016/679 -> CELEX 32016R0679" (string= (eu-celex :regulation 2016 679) "32016R0679"))
(check "directive ELI" (string= (eu-eli :directive 2011 83)
                                "http://data.europa.eu/eli/dir/2011/83/oj"))
(check "regulation ELI" (string= (eu-eli :regulation 2016 679)
                                 "http://data.europa.eu/eli/reg/2016/679/oj"))
(check "EUR-Lex deep link" (search "CELEX:32016R0679" (eu-eurlex-url "32016R0679")))

(format t "~%== Detection in Greek text ==~%")
(let ((r (detect-eu-references
          "Με την παρούσα ενσωματώνεται η Οδηγία 2011/83/ΕΕ στο εθνικό δίκαιο.")))
  (check "modern directive detected" (= 1 (length r)))
  (check "directive year/number" (and (= 2011 (getf (first r) :year))
                                      (= 83 (getf (first r) :number))))
  (check "directive celex" (string= (getf (first r) :celex) "32011L0083")))

(let ((r (detect-eu-references
          "Εφαρμόζεται ο Κανονισμός (ΕΕ) 2016/679 και ο Κανονισμός (ΕΚ) αριθ. 178/2002.")))
  (check "two regulations detected" (= 2 (length r)))
  (check "GDPR 2016/679 celex" (find "32016R0679" r :key (lambda (x) (getf x :celex)) :test #'string=))
  (check "αριθ. 178/2002 normalised to year 2002"
         (find 2002 r :key (lambda (x) (getf x :year)))))

(let ((r (detect-eu-references "Καταργείται η Οδηγία 93/13/ΕΟΚ περί καταχρηστικών ρητρών.")))
  (check "old 2-digit-year directive 93/13 -> 1993" (= 1993 (getf (first r) :year)))
  (check "old directive celex 31993L0013" (string= (getf (first r) :celex) "31993L0013")))

(check "no false positives on plain numbers"
       (null (detect-eu-references "Το άρθρο 5 παρ. 2 ορίζει ότι 10/10 είναι σωστό.")))

(format t "~%== Corpus JSON + determinism ==~%")
(let* ((doc (md :id "demo" :title "Demo" :language "el"
                :provisions
                (list (mp :eid "art_1" :kind :article :num "1" :heading "Α"
                          :text "Ενσωματώνει την Οδηγία 2011/83/ΕΕ.")
                      (mp :eid "art_2" :kind :article :num "2" :heading "Β"
                          :text "Καμία αναφορά εδώ.")
                      (mp :eid "art_3" :kind :article :num "3" :heading "Γ"
                          :text "Βλέπε Κανονισμό (ΕΕ) 2016/679."))))
       (json (corpus-eu-references doc :base-uri "https://x/eli/demo")))
  (check "two articles carry references" (search "\"articles_with_references\":2" json))
  (check "total references = 2" (search "\"references\":2" json))
  (check "art_1 links to GDPR? no — to 32011L0083" (search "32011L0083" json))
  (check "art_3 links to GDPR 32016R0679" (search "32016R0679" json))
  (check "art_2 (no refs) absent" (null (search "\"eId\":\"art_2\"" json)))
  (check "deterministic" (string= json (corpus-eu-references doc :base-uri "https://x/eli/demo"))))

(format t "~%========================================~%")
(format t "Corpus EU-links tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
