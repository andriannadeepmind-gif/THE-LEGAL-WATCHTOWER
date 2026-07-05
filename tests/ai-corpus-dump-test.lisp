;;;; tests/ai-corpus-dump-test.lisp
;;;; Verifies the AI corpus dump: JSONL per article + DCAT catalog.

(in-package :orchestrator.ai-dump)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun jget (obj key) (cdr (assoc key obj :test #'string=)))

(defun build-doc ()
  (let ((c (find-package :orchestrator.consolidation)))
    (flet ((mp (&rest a) (apply (find-symbol "MAKE-PROVISION" c) a))
           (md (&rest a) (apply (find-symbol "MAKE-LEGAL-DOCUMENT" c) a))
           (ma (&rest a) (apply (find-symbol "MAKE-AMENDING-ACT" c) a))
           (cons* (&rest a) (apply (find-symbol "CONSOLIDATE" c) a)))
      (cons*
       (md :id "demo" :title "Demo Code" :language "el"
           :provisions
           (list (mp :eid "art_1" :kind :article :num "1" :heading "Α" :text "Κείμενο 1.")
                 (mp :eid "art_2" :kind :article :num "2" :heading "Β"
                     :children (list (mp :eid "art_2__para_1" :kind :paragraph :num "1" :text "Παρ 1.")
                                     (mp :eid "art_2__para_2" :kind :paragraph :num "2" :text "Παρ 2.")))
                 (mp :eid "art_3" :kind :article :num "3" :heading "Γ" :text "Κείμενο 3.")))
       (list (ma :id "L1" :effective "2010-01-01"
                 :operations (list (list :op :repeal :target "art_3")))
             (ma :id "L2" :effective "2019-01-01"
                 :operations (list (list :op :replace-text :target "art_1" :text "Κείμενο 1 (νέο).")))) ))))

(let* ((doc (build-doc))
       (jsonl (emit-corpus-jsonl doc))
       (lines (remove "" (uiop:split-string jsonl :separator '(#\Newline)) :test #'string=))
       (objs (mapcar (lambda (l) (jonathan:parse l :as :alist)) lines)))

  (format t "~%== JSONL structure ==~%")
  (check "one line per article (3)" (= 3 (length objs)))
  (check "every line is valid JSON" (= 3 (length objs)))
  (check "has @id, eId, in_force, status keys"
         (let ((o (first objs)))
           (and (jget o "@id") (jget o "eId") (assoc "in_force" o :test #'string=)
                (jget o "status"))))

  (format t "~%== Per-article content ==~%")
  (let ((a1 (find "art_1" objs :key (lambda (o) (jget o "eId")) :test #'string=))
        (a2 (find "art_2" objs :key (lambda (o) (jget o "eId")) :test #'string=))
        (a3 (find "art_3" objs :key (lambda (o) (jget o "eId")) :test #'string=)))
    (check "art_1 amended by L2 with new text"
           (and (string= (jget a1 "status") "amended")
                (string= (jget a1 "amended_by") "L2")
                (search "νέο" (jget a1 "text"))))
    (check "art_2 in force with 2 paragraphs"
           (and (eq (jget a2 "in_force") t)
                (= 2 (length (jget a2 "paragraphs")))))
    (check "art_3 repealed: in_force false, text null"
           (and (eq (jget a3 "in_force") nil)
                (string= (jget a3 "status") "repealed")
                (null (jget a3 "text"))))
    (check "art_3 repealed_by L1" (string= (jget a3 "amended_by") "L1")))

  (format t "~%== DCAT catalog ==~%")
  (let* ((cat-str (emit-corpus-catalog doc))
         (cat (jonathan:parse cat-str :as :alist)))
    (check "catalog is dcat:Dataset" (string= (jget cat "@type") "dcat:Dataset"))
    (check "catalog itemCount = 3" (= 3 (jget cat "dcat:itemCount")))
    (check "catalog advertises 4 distributions"
           (= 4 (length (jget cat "dcat:distribution"))))
    (check "catalog includes Akoma Ntoso distribution"
           (some (lambda (d) (string= (jget d "dcat:mediaType") "application/akn+xml"))
                 (jget cat "dcat:distribution")))
    (check "catalog parses as valid JSON" (consp cat)))

  (format t "~%== Determinism ==~%")
  (check "jsonl identical across runs" (string= jsonl (emit-corpus-jsonl doc)))
  (check "catalog identical across runs"
         (string= (emit-corpus-catalog doc) (emit-corpus-catalog doc))))

(format t "~%========================================~%")
(format t "AI corpus dump tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
