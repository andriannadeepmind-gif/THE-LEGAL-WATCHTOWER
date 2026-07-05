;;;; tests/dsanet-chrome-test.lisp
;;;; DSAnet web-print chrome stripping: removes the per-page print_law_record
;;;; URL + page/date footer and the 'ΟΘΟΝΗ ΕΚΤΥΠΩΣΗΣ' header that interleave into
;;;; the text — WITHOUT touching legal references or in-text dates.

(in-package :orchestrator.engine.sbcl)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(let* ((dirty "ορίζει τα στοιχεία της www.dsanet.gr:8380/Webtop/print_law_record.jsp?doc_id=41519&setno=1 1/247 27/8/2019 καθώς και την επιβλητέα γι ΟΘΟΝΗ ΕΚΤΥΠΩΣΗΣ αυτή ποινή.")
       (c (normalize-whitespace (strip-dsanet-chrome dirty))))
  (format t "~%== removes chrome ==~%")
  (check "URL removed" (not (search "dsanet" c)))
  (check "print_law_record removed" (not (search "print_law_record" c)))
  (check "page marker 1/247 removed" (not (search "1/247" c)))
  (check "footer date removed" (not (search "27/8/2019" c)))
  (check "ΟΘΟΝΗ ΕΚΤΥΠΩΣΗΣ removed" (not (search "ΟΘΟΝΗ" c)))
  (format t "~%== preserves legal text ==~%")
  (check "sentence head intact" (search "ορίζει τα στοιχεία της" c))
  (check "sentence tail intact" (search "την επιβλητέα" c))
  (check "final word intact" (search "ποινή" c)))

(let* ((legal "Με τον ν. 4619/2019 τροποποιήθηκε και η ημερομηνία 27/8/2019 αναφέρεται νόμιμα 1/247.")
       (c (strip-dsanet-chrome legal)))
  (format t "~%== legal references are NOT touched (no URL anchor) ==~%")
  (check "law ref 4619/2019 intact" (search "4619/2019" c))
  (check "in-text date intact" (search "27/8/2019" c))
  (check "bare fraction intact (no dsanet anchor)" (search "1/247" c)))

(let ((c (strip-dsanet-chrome "Καθαρό κείμενο χωρίς θόρυβο.")))
  (format t "~%== no-op on clean text ==~%")
  (check "clean text unchanged" (string= "Καθαρό κείμενο χωρίς θόρυβο." c)))

(format t "~%== Greek elision-apostrophe restoration (poppler drops them) ==~%")
(flet ((r (s) (restore-greek-elisions s)))
  ;; positives — bare proclitic stem before a lowercase vowel regains apostrophe
  (check "γι' restored"  (string= "γι' αυτή" (r "γι αυτή")))
  (check "απ' restored"  (string= "απ' αυτόν" (r "απ αυτόν")))
  (check "κατ' restored" (string= "κατ' αρχήν" (r "κατ αρχήν")))
  (check "υπ' restored"  (string= "υπ' αριθμόν" (r "υπ αριθμόν")))
  (check "newline-gap (the real DSAnet damage) joined + restored"
         (string= "επιβλητέα γι' αυτή ποινή."
                  (r (format nil "επιβλητέα γι~%~%αυτή ποινή."))))
  ;; negatives — non-elided full words are untouched
  (check "για (full word) untouched" (string= "για αυτή" (r "για αυτή")))
  (check "κατά untouched"   (string= "κατά την" (r "κατά την")))
  (check "εξ untouched"     (string= "εξ αυτών" (r "εξ αυτών")))
  (check "από untouched"    (string= "από την" (r "από την")))
  (check "stem before consonant untouched" (string= "γι το" (r "γι το")))
  ;; cross-boundary safety — never join into a Capitalised label/header
  (check "no join across boundary into Capital (Αρθρο)"
         (string= (format nil "τελεση απ~%Αρθρο: 5") (r (format nil "τελεση απ~%Αρθρο: 5"))))
  (check "all-caps stem never matches"
         (string= (format nil "ΚΑΘ~%ΟΘΟΝΗ") (r (format nil "ΚΑΘ~%ΟΘΟΝΗ")))))

(format t "~%== Detached Greek accent recombination (poppler splits them) ==~%")
(flet ((a (s) (recombine-greek-accents s)))
  (check "΄Οποιος -> Όποιος"
         (string= "Όποιος" (a (format nil "~AΟποιος" (code-char #x0384)))))
  (check "΄ Οποιος (with space) -> Όποιος"
         (string= "Όποιος" (a (format nil "~A Οποιος" (code-char #x0384)))))
  (check "´ανθρωπος (acute) -> άνθρωπος"
         (string= "άνθρωπος" (a (format nil "~Aανθρωπος" (code-char #x00B4)))))
  (check "real art.430 case: 1. ΄Οποιος -> Όποιος"
         (string= "1. Όποιος παραβαίνει"
                  (a (format nil "1. ~AΟποιος παραβαίνει" (code-char #x0384)))))
  (check "already-correct accented text untouched" (string= "Όποιος" (a "Όποιος")))
  (check "ordinary text untouched" (string= "καλός νόμος" (a "καλός νόμος"))))

(format t "~%== Isokratis editorial markers (***, ##, ^^^, (βλ. σχόλια)) ==~%")
(flet ((m (s) (normalize-whitespace (strip-isokratis-markers s))))
  (check "*** removed from end of sentence"
         (string= "τριών ετών." (m "τριών ετών***.")))
  (check "**##** and (βλ. σχόλια) removed from title"
         (not (or (search "*" (m "οργάνωση\"**##** (βλ. σχόλια)"))
                  (search "#" (m "οργάνωση\"**##** (βλ. σχόλια)"))
                  (search "βλ. σχόλια" (m "οργάνωση\"**##** (βλ. σχόλια)")))))
  (check "^^^ removed" (not (search "^" (m "322Β)»^^^ (βλ. σχόλια)"))))
  (check "leading markers stripped" (string= "1. Με κάθειρξη"
                                             (string-trim " " (m "### ** 1. Με κάθειρξη"))))
  ;; legal text / punctuation preserved
  (check "« » guillemets preserved" (search "«αναστολή»" (m "«αναστολή»***")))
  (check "quoted law title preserved"
         (search "\"περί φυλακών\"" (m "νόμος 881 \"περί φυλακών\"**")))
  (check "lettered article refs in text preserved" (search "322Α" (m "322Α^^^"))))

(format t "~%== Dropped-tonos restoration on capital words (strict whitelist) ==~%")
(flet ((r (s) (restore-common-greek-accents s)))
  (check "Οποιος -> Όποιος" (string= "1. Όποιος με" (r "1. Οποιος με")))
  (check "Οταν -> Όταν"     (string= "Όταν συμβεί" (r "Οταν συμβεί")))
  (check "Ολα -> Όλα"       (string= "Όλα τα" (r "Ολα τα")))
  (check "Ηταν -> Ήταν"     (string= "Ήταν" (r "Ηταν")))
  ;; whole-word only — words that merely CONTAIN a target are untouched
  (check "Ολυμπία untouched" (string= "Ολυμπία" (r "Ολυμπία")))
  (check "Ολομέλεια untouched" (string= "Ολομέλεια" (r "Ολομέλεια")))
  (check "Οσονούπω untouched" (string= "Οσονούπω" (r "Οσονούπω")))
  (check "Οτιδήποτε untouched" (string= "Οτιδήποτε" (r "Οτιδήποτε")))
  (check "already-accented untouched" (string= "Όποιος" (r "Όποιος"))))

(format t "~%== Orthography authority: the corpus LEARNS its spelling (no heuristics) ==~%")
;; Correct forms dominate (as in real legal text); the few corrupted ones are the
;; minority. The canonical spelling is decided purely by majority.
(let* ((corpus (format nil "~A"
   "πιο πιο πιο πιο για για για για της της της της του του του του
    βία βία βία δύο δύο δύο όποιος όποιος όποιος άνθρωπος άνθρωπος
    ή ή ή η η η η η που που που πού πού πότε πότε ποτέ ποτέ ναι ναι α α α"))
       (lex (orchestrator.orthography:learn-orthography corpus)))
  (flet ((rw (w) (orchestrator.orthography:restore-word-orthography w lex)))
    ;; LEARNS to ADD a dropped accent
    (check "Οποιος -> Όποιος (learned)" (string= "Όποιος" (rw "Οποιος")))
    (check "Ανθρωπος -> Άνθρωπος (learned, no list)" (string= "Άνθρωπος" (rw "Ανθρωπος")))
    ;; LEARNS to REMOVE a wrong accent — including πιό/γιά the user flagged
    (check "πιό -> πιο (learned)" (string= "πιο" (rw "πιό")))
    (check "γιά -> για (learned)" (string= "για" (rw "γιά")))
    (check "τής -> της (learned)" (string= "της" (rw "τής")))
    (check "τού -> του (learned)" (string= "του" (rw "τού")))
    (check "ναί -> ναι (learned)" (string= "ναι" (rw "ναί")))
    (check "ά -> α (learned)"     (string= "α" (rw "ά")))
    ;; LEARNS that βία/δύο keep their accent (NOT a syllable rule — from data)
    (check "βία kept (corpus says so)" (string= "βία" (rw "βία")))
    (check "δύο kept (corpus says so)" (string= "δύο" (rw "δύο")))
    ;; correctly-spelled words are unchanged
    (check "της stays της" (string= "της" (rw "της")))
    (check "όποιος stays όποιος" (string= "όποιος" (rw "όποιος")))
    ;; homographs: the 3 monotonic disambiguators and balanced skeletons are safe
    (check "ή preserved" (string= "ή" (rw "ή")))
    (check "πού preserved" (string= "πού" (rw "πού")))
    (check "πώς preserved" (string= "πώς" (rw "πώς")))
    (check "η preserved (η/ή homograph)" (string= "η" (rw "η")))
    (check "που preserved (που/πού homograph)" (string= "που" (rw "που")))
    ;; genuine accent-position homograph stays ambiguous, never auto-resolved
    (check "πότε unchanged (ambiguous)" (string= "πότε" (rw "πότε")))
    (check "ποτέ unchanged (ambiguous)" (string= "ποτέ" (rw "ποτέ")))))

(format t "~%========================================~%")
(format t "DSAnet chrome tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
