;;;; tests/akoma-ntoso-emitter-test.lisp
;;;; Verifies the Akoma Ntoso emitter: structure, provenance mapping,
;;;; well-formedness (parsed with cxml), and determinism.

(in-package :orchestrator.akoma-ntoso)

(defvar *pass* 0)
(defvar *fail* 0)

(defmacro check (name form)
  `(handler-case
       (if ,form
           (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e)
       (incf *fail*)
       (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

(defun contains (needle haystack) (search needle haystack))

;;; Build a consolidated document using the engine, then emit AKN.
(defun build-consolidated ()
  (let ((c (find-package :orchestrator.consolidation)))
    (flet ((mp (&rest args) (apply (find-symbol "MAKE-PROVISION" c) args))
           (md (&rest args) (apply (find-symbol "MAKE-LEGAL-DOCUMENT" c) args))
           (ma (&rest args) (apply (find-symbol "MAKE-AMENDING-ACT" c) args))
           (consolidate (&rest args) (apply (find-symbol "CONSOLIDATE" c) args)))
      (let ((doc (md :id "test-code" :title "Δοκιμαστικός Κώδικας" :language "el"
                     :provisions
                     (list
                      (mp :eid "art_1" :kind :article :num "1" :heading "Ορισμοί"
                          :text "Αρχικό άρθρο 1.")
                      (mp :eid "art_2" :kind :article :num "2" :heading "Πεδίο"
                          :children
                          (list (mp :eid "art_2__para_1" :kind :paragraph :num "1"
                                    :text "Παράγραφος 1.")
                                (mp :eid "art_2__para_2" :kind :paragraph :num "2"
                                    :text "Παράγραφος 2.")))
                      (mp :eid "art_3" :kind :article :num "3" :heading "Κυρώσεις"
                          :text "Αρχικό άρθρο 3. <τεστ & escaping>"))))
            (acts (list
                   (ma :id "L100-2001" :effective "2001-04-17"
                       :operations (list (list :op :replace-text :target "art_2__para_1"
                                               :text "Παράγραφος 1 (2001).")))
                   (ma :id "L200-2008" :effective "2008-05-27"
                       :operations (list (list :op :repeal :target "art_1"))))))
        (consolidate doc acts)))))

(let* ((doc (build-consolidated))
       (xml (emit-akoma-ntoso doc :work-date "2008-05-27")))

  (format t "~%== Structure ==~%")
  (check "declares akomaNtoso root" (contains "<akomaNtoso" xml))
  (check "declares AKN 3.0 namespace"
         (contains "http://docs.oasis-open.org/legaldocml/ns/akn/3.0" xml))
  (check "has act element" (contains "<act name=\"act\">" xml))
  (check "has FRBRWork" (contains "<FRBRWork>" xml))
  (check "has FRBRExpression with language" (contains "<FRBRlanguage language=\"el\"/>" xml))
  (check "has body" (contains "<body>" xml))

  (format t "~%== Provisions & eIds ==~%")
  (check "article element with eId" (contains "<article eId=\"art_1\"" xml))
  (check "paragraph element with nested eId" (contains "<paragraph eId=\"art_2__para_1\"" xml))
  (check "num element present" (contains "<num>1</num>" xml))
  (check "heading element present" (contains "<heading>Ορισμοί</heading>" xml))
  (check "content/p wraps text" (contains "<p>Παράγραφος 1 (2001).</p>" xml))

  (format t "~%== Provenance mapping ==~%")
  (check "repealed article marked status=repealed"
         (contains "<article eId=\"art_1\" status=\"repealed\"" xml))
  (check "repealed article refersTo amending event"
         (contains "refersTo=\"#e_L200-2008\"" xml))
  (check "amended paragraph refersTo amending event"
         (contains "refersTo=\"#e_L100-2001\"" xml))
  (check "lifecycle has eventRef for 2001 act"
         (contains "<eventRef eId=\"e_L100-2001\" date=\"2001-04-17\"" xml))
  (check "lifecycle has eventRef for 2008 act"
         (contains "<eventRef eId=\"e_L200-2008\" date=\"2008-05-27\"" xml))

  (format t "~%== XML escaping ==~%")
  (check "special chars escaped in text"
         (and (contains "&lt;τεστ" xml)          ; '<' escaped, Greek letters kept
              (null (contains "<τεστ" xml))      ; raw '<τεστ' must not appear
              (contains "&amp; escaping&gt;" xml)))

  (format t "~%== Well-formedness (cxml) ==~%")
  (check "parses as well-formed XML via cxml"
         (handler-case
             (progn (cxml:parse xml (cxml-dom:make-dom-builder)) t)
           (error () nil)))

  (format t "~%== Determinism ==~%")
  (check "two emissions identical"
         (string= xml (emit-akoma-ntoso (build-consolidated) :work-date "2008-05-27"))))

(format t "~%========================================~%")
(format t "Akoma Ntoso emitter tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
