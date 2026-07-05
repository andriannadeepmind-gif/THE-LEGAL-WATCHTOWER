;;;; tests/consolidation-engine-test.lisp
;;;; Standalone, dependency-free verification of the consolidation engine.
;;;; Run: sbcl --non-interactive --load source/consolidation-engine.lisp \
;;;;          --load tests/consolidation-engine-test.lisp

(in-package :orchestrator.consolidation)

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

;;; --------------------------------------------------------------------------
;;; Base document
;;; --------------------------------------------------------------------------

(defun build-base ()
  (make-legal-document
   :id "test-code" :title "Δοκιμαστικός Κώδικας" :language "el"
   :provisions
   (list
    (make-provision :eid "art_1" :kind :article :num "1" :heading "Ορισμοί"
                    :text "Αρχικό κείμενο άρθρου 1.")
    (make-provision :eid "art_2" :kind :article :num "2" :heading "Πεδίο εφαρμογής"
                    :children
                    (list
                     (make-provision :eid "art_2__para_1" :kind :paragraph :num "1"
                                     :text "Παράγραφος 1 αρχική.")
                     (make-provision :eid "art_2__para_2" :kind :paragraph :num "2"
                                     :text "Παράγραφος 2 αρχική.")))
    (make-provision :eid "art_3" :kind :article :num "3" :heading "Κυρώσεις"
                    :text "Αρχικό κείμενο άρθρου 3."))))

(defun build-amendments ()
  (list
   (make-amending-act
    :id "L100-2001" :fek "ΦΕΚ Α' 85/2001"
    :enacted "2001-04-17" :effective "2001-04-17"
    :operations
    (list
     (list :op :replace-text :target "art_2__para_1"
           :text "Παράγραφος 1 όπως τροποποιήθηκε το 2001.")
     (list :op :insert :parent "art_2" :position :end
           :node (make-provision :eid "art_2__para_3" :kind :paragraph :num "3"
                                 :text "Νέα παράγραφος 3 (2001)."))))
   (make-amending-act
    :id "L200-2008" :fek "ΦΕΚ Α' 102/2008"
    :enacted "2008-05-27" :effective "2008-05-27"
    :operations
    (list
     (list :op :repeal :target "art_1")
     (list :op :replace :target "art_3"
           :node (make-provision :eid "ignored" :kind :article :num "3"
                                 :heading "Κυρώσεις (νέο)"
                                 :text "Πλήρως αντικατεστημένο άρθρο 3 (2008)."))))))

;;; --------------------------------------------------------------------------
;;; Tests
;;; --------------------------------------------------------------------------

(let* ((base (build-base))
       (amends (build-amendments)))

  (format t "~%== Point-in-time consolidation ==~%")

  ;; As of 2000: nothing applied yet -> identical to base text.
  (let ((c2000 (consolidate base amends :as-of-date "2000-01-01")))
    (check "2000: art_1 still in force"
           (eq (provision-status (find-provision c2000 "art_1")) :original))
    (check "2000: para_1 original text"
           (string= (provision-text (find-provision c2000 "art_2__para_1"))
                    "Παράγραφος 1 αρχική."))
    (check "2000: para_3 not yet inserted"
           (null (find-provision c2000 "art_2__para_3")))
    (check "2000: art_3 original text"
           (string= (provision-text (find-provision c2000 "art_3"))
                    "Αρχικό κείμενο άρθρου 3.")))

  ;; As of 2005: act A applied, act B not.
  (let ((c2005 (consolidate base amends :as-of-date "2005-01-01")))
    (check "2005: para_1 amended text"
           (string= (provision-text (find-provision c2005 "art_2__para_1"))
                    "Παράγραφος 1 όπως τροποποιήθηκε το 2001."))
    (check "2005: para_1 provenance -> L100-2001 / amended"
           (and (eq (provision-status (find-provision c2005 "art_2__para_1")) :amended)
                (string= (provision-source-act (find-provision c2005 "art_2__para_1"))
                         "L100-2001")))
    (check "2005: para_3 inserted by L100-2001"
           (let ((p (find-provision c2005 "art_2__para_3")))
             (and p (eq (provision-status p) :inserted)
                  (string= (provision-source-act p) "L100-2001"))))
    (check "2005: art_1 still in force (B not yet effective)"
           (not (eq (provision-status (find-provision c2005 "art_1")) :repealed)))
    (check "2005: art_3 still original (B not yet effective)"
           (string= (provision-text (find-provision c2005 "art_3"))
                    "Αρχικό κείμενο άρθρου 3.")))

  ;; As of 2010 (and nil): both acts applied.
  (let ((c2010 (consolidate base amends :as-of-date "2010-01-01"))
        (call  (consolidate base amends)))
    (check "2010: art_1 repealed by L200-2008"
           (and (eq (provision-status (find-provision c2010 "art_1")) :repealed)
                (string= (provision-source-act (find-provision c2010 "art_1")) "L200-2008")))
    (check "2010: art_3 replaced text + eId preserved"
           (let ((p (find-provision c2010 "art_3")))
             (and p
                  (string= (provision-text p) "Πλήρως αντικατεστημένο άρθρο 3 (2008).")
                  (string= (provision-heading p) "Κυρώσεις (νέο)")
                  (string= (provision-eid p) "art_3")          ; eId preserved
                  (eq (provision-status p) :amended)
                  (string= (provision-source-act p) "L200-2008"))))
    (check "no-as-of-date == as-of far future (render equal)"
           (string= (render-consolidated-text c2010)
                    (render-consolidated-text call))))

  (format t "~%== Base immutability ==~%")
  (consolidate base amends)  ; must not mutate base
  (check "base art_1 untouched after consolidation"
         (and (eq (provision-status (find-provision base "art_1")) :original)
              (null (provision-source-act (find-provision base "art_1")))))
  (check "base art_2 still has exactly 2 children"
         (= 2 (length (provision-children (find-provision base "art_2")))))
  (check "base para_1 text unchanged"
         (string= (provision-text (find-provision base "art_2__para_1"))
                  "Παράγραφος 1 αρχική."))

  (format t "~%== Determinism ==~%")
  (let ((r1 (render-consolidated-text (consolidate base amends)))
        (r2 (render-consolidated-text (consolidate base amends)))
        (t1 (render-consolidation-provenance-ttl (consolidate base amends)))
        (t2 (render-consolidation-provenance-ttl (consolidate base amends))))
    (check "consolidated text identical across runs" (string= r1 r2))
    (check "provenance TTL identical across runs" (string= t1 t2)))

  (format t "~%== In-force rendering omits repealed ==~%")
  (let ((txt (render-consolidated-text (consolidate base amends))))
    (check "repealed art_1 omitted from in-force text"
           (null (search "Αρχικό κείμενο άρθρου 1." txt)))
    (check "amended para_1 present in in-force text"
           (search "τροποποιήθηκε το 2001" txt))
    (check "inserted para_3 present in in-force text"
           (search "Νέα παράγραφος 3 (2001)" txt))
    (check "replaced art_3 present in in-force text"
           (search "Πλήρως αντικατεστημένο άρθρο 3" txt))))

(format t "~%== :if-missing policy ==~%")
(let ((base (build-base)))
  ;; :skip tolerates an absent target.
  (let ((act-skip (make-amending-act
                   :id "X" :effective "2020-01-01"
                   :operations (list (list :op :mark-amended :target "art_999"
                                           :if-missing :skip)))))
    (check ":if-missing :skip tolerates absent target"
           (handler-case (progn (consolidate base (list act-skip)) t)
             (consolidation-error () nil))))
  ;; default (:error) signals on an absent target.
  (let ((act-err (make-amending-act
                  :id "Y" :effective "2020-01-01"
                  :operations (list (list :op :mark-amended :target "art_999")))))
    (check "default :if-missing :error signals on absent target"
           (handler-case (progn (consolidate base (list act-err)) nil)
             (consolidation-error () t)))))

(format t "~%========================================~%")
(format t "Consolidation engine tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
