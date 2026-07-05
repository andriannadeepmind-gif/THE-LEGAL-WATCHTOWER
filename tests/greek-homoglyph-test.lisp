;;;; tests/greek-homoglyph-test.lisp
;;;; ΦΕΚ PDFs emit Latin capitals in place of the visually identical Greek letter
;;;; (Oι, Aν, EYAΓΓΕΛΟΣ, στoν) — a wrong-codepoint error that breaks search and
;;;; matching. normalize-greek-homoglyphs repairs them, but ONLY inside a token that
;;;; already has a real Greek letter, so genuine Latin (URLs, GDPR) is never touched.

(in-package :orchestrator.engine.sbcl)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(format t "~%== repairs the observed ΦΕΚ homoglyphs ==~%")
(check "Oι → Οι (capital O)"           (string= "Οι"  (normalize-greek-homoglyphs "Oι")))
(check "Aν → Αν (capital A)"           (string= "Αν"  (normalize-greek-homoglyphs "Aν")))
(check "Tο → Το (capital T)"           (string= "Το"  (normalize-greek-homoglyphs "Tο")))
(check "στoν → στον (lowercase o)"     (string= "στον" (normalize-greek-homoglyphs "στoν")))
(check "EYAΓΓΕΛΟΣ → ΕΥΑΓΓΕΛΟΣ"        (string= "ΕΥΑΓΓΕΛΟΣ" (normalize-greek-homoglyphs "EYAΓΓΕΛΟΣ")))
(check "whole sentence repaired"
       (string= "Οι διάδικοι" (normalize-greek-homoglyphs "Oι διάδικοι")))

(format t "~%== leaves genuine Latin untouched (no Greek letter in token) ==~%")
(check "URL untouched"   (string= "https://stavropouloslaw.com"
                                  (normalize-greek-homoglyphs "https://stavropouloslaw.com")))
(check "GDPR untouched"  (string= "GDPR" (normalize-greek-homoglyphs "GDPR")))
(check "English word untouched" (string= "Tax" (normalize-greek-homoglyphs "Tax")))
(check "mixed sentence: Latin token kept, Greek token fixed"
       (string= "ο νόμος GDPR και η Αρχή"
                (normalize-greek-homoglyphs "ο νόμος GDPR και η Aρχή")))

(format t "~%== never damages clean text / digits / punctuation ==~%")
(check "already-clean Greek unchanged"
       (string= "Άρθρο 92 — οι διάδικοι" (normalize-greek-homoglyphs "Άρθρο 92 — οι διάδικοι")))
(check "law reference untouched" (string= "ν. 2472/1997" (normalize-greek-homoglyphs "ν. 2472/1997")))
(check "empty string" (string= "" (normalize-greek-homoglyphs "")))

(format t "~%== SYMBOL homoglyphs: ∆/Ω/µ → Δ/Ω/μ (the masthead bug) ==~%")
(check "∆ U+2206 → Δ U+0394 in ΕΦΗΜΕΡΙ∆Α"
       (string= (coerce (list #\Ε #\Φ #\Η #\Μ #\Ε #\Ρ #\Ι #\Δ #\Α) 'string)
                (normalize-greek-homoglyphs
                 (coerce (list #\Ε #\Φ #\Η #\Μ #\Ε #\Ρ #\Ι (code-char #x2206) #\Α) 'string))))
(check "µ U+00B5 → μ U+03BC"
       (char= #\μ (char (normalize-greek-homoglyphs (string (code-char #x00B5))) 0)))

(format t "~%== END-TO-END: clean-fek-text rejoins a word across the page masthead ==~%")
;; Exactly the art-340 seam: a hyphenated word «δικαστη-» split by the page-break
;; masthead (Τεύχος… / ΕΦΗΜΕΡΙ∆Α… / page number) from its continuation «ρίου …».
;; The masthead must be dropped and the word rejoined — no body text lost.
(let* ((seam (format nil "ο πρόεδρος του δικαστη-~%Τεύχος A’ 96/11.06.2019~%~
                          ΕΦΗΜΕΡΙ∆Α TΗΣ ΚΥΒΕΡΝΗΣΕΩΣ~%2831~%ρίου διορίζει σε αυτόν"))
       (cleaned (clean-fek-text seam)))
  (check "the continuation «ρίου διορίζει σε αυτόν» survives"
         (search "ρίου διορίζει σε αυτόν" cleaned))
  (check "the word is rejoined to «δικαστηρίου» (hyphen gone)"
         (search "δικαστηρίου" cleaned))
  (check "the masthead is removed (no ΕΦΗΜΕΡΙ… left)"
         (not (search "ΕΦΗΜΕΡΙ" cleaned)))
  (check "no «δικαστη- » seam remains"
         (not (search "δικαστη- " cleaned))))

(format t "~%========================================~%")
(format t "Greek-homoglyph tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
