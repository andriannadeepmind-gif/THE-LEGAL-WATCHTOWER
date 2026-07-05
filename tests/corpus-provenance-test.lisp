;;;; tests/corpus-provenance-test.lisp
;;;; PROV-O provenance built from real consolidation amendment provenance
;;;; (wires the restored legal-audit capability). Deterministic.

(in-package :orchestrator.corpus-provenance)

;; Production builds run with deterministic time; enable it so the byte-identical
;; guarantee is exercised exactly as it ships.
(funcall (find-symbol "CONFIGURE-DETERMINISTIC-TIME" :orchestrator.time)
         :enabled t :fixed-time "2025-01-01T00:00:00Z")

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun mp (&rest a) (apply (find-symbol "MAKE-PROVISION" :orchestrator.consolidation) a))
(defun md (&rest a) (apply (find-symbol "MAKE-LEGAL-DOCUMENT" :orchestrator.consolidation) a))
(defun ma (&rest a) (apply (find-symbol "MAKE-AMENDING-ACT" :orchestrator.consolidation) a))
(defun cons* (&rest a) (apply (find-symbol "CONSOLIDATE" :orchestrator.consolidation) a))

(defun built ()
  (cons* (md :id "demo" :title "Demo Code" :language "el"
             :provisions (list (mp :eid "art_1" :kind :article :num "1" :heading "Α" :text "Αρχικό.")
                               (mp :eid "art_2" :kind :article :num "2" :heading "Β" :text "Δεύτερο.")
                               (mp :eid "art_3" :kind :article :num "3" :heading "Γ" :text "Τρίτο.")))
         (list (ma :id "Ν.4000/2015" :effective "2015-01-01"
                   :operations (list (list :op :replace-text :target "art_1" :text "Νέο κείμενο.")))
               (ma :id "Ν.4500/2018" :effective "2018-01-01"
                   :operations (list (list :op :repeal :target "art_2"))))))

(format t "~%== PROV-O Turtle from real provenance ==~%")
(let* ((doc (built))
       (ttl (corpus-provenance doc :base-uri "https://x/eli/demo" :format :turtle)))
  (check "is PROV-O turtle" (search "a prov:Bundle" ttl))
  (check "records the amendment act Ν.4000/2015" (search "Ν.4000/2015" ttl))
  (check "records the repeal act Ν.4500/2018" (search "Ν.4500/2018" ttl))
  (check "art_1 amendment is a prov:Activity"
         (and (search "art_1--Ν.4000/2015" ttl) (search "prov:Activity" ttl)))
  (check "carries the effective date 2015" (search "2015-01-01" ttl))
  (check "unchanged art_3 has no activity" (null (search "art_3--" ttl)))
  (check "deterministic across calls"
         (string= ttl (corpus-provenance doc :base-uri "https://x/eli/demo" :format :turtle))))

(format t "~%== JSON-LD + PROV-XML formats ==~%")
(let* ((doc (built))
       (jld (corpus-provenance doc :base-uri "https://x/eli/demo" :format :json-ld))
       (xml (corpus-provenance doc :base-uri "https://x/eli/demo" :format :xml)))
  (check "JSON-LD has @context prov" (search "prov" jld))
  (check "JSON-LD lists activities" (search "prov:Activity" jld))
  (check "PROV-XML well-formed root" (search "<prov:document" xml))
  (check "PROV-XML has activity element" (search "<prov:activity" xml))
  (check "PROV-XML escapes nothing unsafe (no raw &)"
         (null (search " & " xml))))

(format t "~%========================================~%")
(format t "Corpus provenance tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
