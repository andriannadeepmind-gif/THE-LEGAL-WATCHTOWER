;;;; tests/corpus-search-test.lisp
;;;; Greek full-text search over the corpus (reuses the real Greek tokenizer).

(in-package :orchestrator.corpus-search)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun build-doc ()
  (let ((c (find-package :orchestrator.consolidation)))
    (flet ((mp (&rest a) (apply (find-symbol "MAKE-PROVISION" c) a))
           (md (&rest a) (apply (find-symbol "MAKE-LEGAL-DOCUMENT" c) a)))
      (md :id "demo" :title "Demo" :language "el"
          :provisions
          (list (mp :eid "art_1" :kind :article :num "1" :heading "Καμία ποινή χωρίς νόμο"
                    :text "Έγκλημα δεν υπάρχει χωρίς νόμο.")
                (mp :eid "art_5" :kind :article :num "5" :heading "Εγκλήματα στην ημεδαπή"
                    :text "Οι ελληνικοί ποινικοί νόμοι εφαρμόζονται στα εγκλήματα που τελέστηκαν στην ημεδαπή.")
                (mp :eid "art_9" :kind :article :num "9" :heading "Ακαταδίωκτο"
                    :text "Διατάξεις περί παραγραφής."))))))

(let ((doc (build-doc)) (base "https://x/eli/demo"))

  (format t "~%== Greek normalization ==~%")
  (check "fold-greek strips accents + final sigma"
         (string= (fold-greek "Νόμος") "νομοσ"))
  (check "accented and unaccented fold the same"
         (string= (fold-greek "εγκλήματα") (fold-greek "ΕΓΚΛΗΜΑΤΑ")))

  (format t "~%== Search results ==~%")
  (let ((r (search-corpus doc "εγκλήματα ημεδαπή" :base-uri base)))
    (check "query terms folded in output" (search "\"εγκληματα\"" r))
    (check "top result is art_5 (both terms)" (search "\"eId\":\"art_5\"" r))
    (check "result carries score + in_force + heading"
           (and (search "\"score\":" r) (search "\"in_force\":true" r)
                (search "ημεδαπή" r)))
    (check "valid JSON shape" (and (search "\"results\"" r) (search "\"count\"" r))))

  (format t "~%== Matching quality ==~%")
  (let ((r (search-corpus doc "νόμος" :base-uri base)))
    ;; "νόμος"/"νόμο"/"νόμοι" — at least art_1 and art_5 mention νόμ-
    (check "search 'νόμος' finds article(s)" (search "art_" r)))
  (let ((r (search-corpus doc "παραγραφή" :base-uri base)))
    (check "search 'παραγραφή' finds art_9" (search "\"eId\":\"art_9\"" r)))
  (let ((r (search-corpus doc "ζζζανύπαρκτο" :base-uri base)))
    (check "no-match query returns count 0" (search "\"count\":0" r)))

  (format t "~%== Robustness / determinism ==~%")
  (check "empty query is handled (count 0)"
         (search "\"count\":0" (search-corpus doc "" :base-uri base)))
  (check "deterministic across calls"
         (string= (search-corpus doc "εγκλήματα" :base-uri base)
                  (search-corpus doc "εγκλήματα" :base-uri base))))

(format t "~%========================================~%")
(format t "Corpus search tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
