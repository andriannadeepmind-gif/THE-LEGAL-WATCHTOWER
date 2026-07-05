;;;; tests/corpus-diff-test.lisp
;;;; Point-in-time legal diff (consolidation + the restored semantic-versioning
;;;; LCS word diff).

(in-package :orchestrator.corpus-diff)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun cons* (&rest a)
  (apply (find-symbol "CONSOLIDATE" :orchestrator.consolidation) a))
(defun mp (&rest a) (apply (find-symbol "MAKE-PROVISION" :orchestrator.consolidation) a))
(defun md (&rest a) (apply (find-symbol "MAKE-LEGAL-DOCUMENT" :orchestrator.consolidation) a))
(defun ma (&rest a) (apply (find-symbol "MAKE-AMENDING-ACT" :orchestrator.consolidation) a))

(defun base ()
  (md :id "demo" :title "Demo" :language "el"
      :provisions (list (mp :eid "art_1" :kind :article :num "1" :heading "Α"
                            :text "Το αρχικό κείμενο του νόμου ισχύει.")
                        (mp :eid "art_2" :kind :article :num "2" :heading "Β" :text "Δεύτερο.")
                        (mp :eid "art_3" :kind :article :num "3" :heading "Γ" :text "Τρίτο αμετάβλητο."))))

(defun acts ()
  (list (ma :id "L1" :effective "2015-01-01"
            :operations (list (list :op :replace-text :target "art_1"
                                    :text "Το νέο κείμενο του νόμου ισχύει.")))
        (ma :id "L2" :effective "2018-01-01"
            :operations (list (list :op :repeal :target "art_2")))))

(format t "~%== LCS word diff (compute-text-diff) ==~%")
(let ((d (funcall (find-symbol "COMPUTE-TEXT-DIFF" :orchestrator.semantic-versioning)
                  "a b c d" "a x c d")))
  (check "modification-count = 2 (b removed, x added)"
         (= 2 (getf d :modification-count)))
  (check "additions = (x)" (equal (getf d :additions) '("x")))
  (check "deletions = (b)" (equal (getf d :deletions) '("b")))
  (check "segments: a equal, b/x substituted (add+remove), c & d equal"
         (let ((ops (mapcar (lambda (s) (getf s :op)) (getf d :segments))))
           (and (eq (first ops) :equal)
                (equal (subseq ops 3) '(:equal :equal))           ; c, d unchanged
                (equal (sort (copy-list (subseq ops 1 3)) #'string<) '(:add :remove))))))

(let* ((b (base)) (am (acts))
       (d2010 (cons* b am :as-of-date "2010-01-01"))
       (d2020 (cons* b am :as-of-date "2020-01-01"))
       (json (corpus-diff d2010 d2020 "2010-01-01" "2020-01-01" :base-uri "https://x/eli/demo")))

  (format t "~%== Point-in-time legal diff ==~%")
  (check "art_1 amended between 2010 and 2020"
         (search "\"eId\":\"art_1\",\"number\":\"1\",\"heading\":\"Α\",\"change\":\"amended\"" json))
  (check "art_1 diff carries word modifications"
         (and (search "\"modifications\":" json) (search "\"diff\":[" json)))
  (check "diff shows αρχικό removed and νέο added"
         (and (search "{\"op\":\"remove\",\"text\":\"αρχικό\"}" json)
              (search "{\"op\":\"add\",\"text\":\"νέο\"}" json)))
  (check "art_2 reported as repealed" (search "\"eId\":\"art_2\"" json))
  (check "art_2 change=repealed"
         (search "\"change\":\"repealed\"" json))
  (check "unchanged art_3 NOT in the diff" (null (search "\"eId\":\"art_3\"" json)))
  (check "valid JSON envelope (from/to/count)"
         (and (search "\"from\":\"2010-01-01\"" json) (search "\"to\":\"2020-01-01\"" json)
              (search "\"count\":2" json)))

  (format t "~%== No-change window + determinism ==~%")
  (let ((same (corpus-diff (cons* b am :as-of-date "2016-01-01")
                           (cons* b am :as-of-date "2017-01-01") "2016-01-01" "2017-01-01"
                           :base-uri "https://x/eli/demo")))
    (check "no changes between 2016 and 2017 -> count 0" (search "\"count\":0" same)))
  (check "deterministic across calls"
         (string= json (corpus-diff d2010 d2020 "2010-01-01" "2020-01-01" :base-uri "https://x/eli/demo"))))

(format t "~%========================================~%")
(format t "Corpus diff tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
