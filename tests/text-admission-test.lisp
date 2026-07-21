;;;; tests/text-admission-test.lisp
;;;; ============================================================================
;;;; [+3/0104] Η ΠΟΡΤΑ ΕΙΣΔΟΧΗΣ ΚΕΙΜΕΝΟΥ — σύνταξη-μεταφοράς δομικά αδύνατο
;;;; να εισέλθει σιωπηλά. Κλειδώνει: (α) text-hygiene καθαρή έδρα (κάθε κλάση
;;;; ευρήματος + αρνητικά)· (β) make-version-spec: ευρήματα χωρίς ρητό waiver ⇒
;;;; invalid-edge· waiver πρέπει να κατονομάζει ΑΚΡΙΒΩΣ· blanket waiver σε
;;;; καθαρό κείμενο ⇒ invalid-edge· (γ) εισδοχή με waiver ⇒ journaled
;;;; text-observation, ΚΑΙ στη γένεση ΚΑΙ στην ακμή· (δ) replay από δίσκο
;;;; αναπαράγει τις παρατηρήσεις + semantic ③ (πειραγμένο record ⇒ ρήξη)·
;;;; (ε) το κείμενο μένει ΑΘΙΚΤΟ — η παρατήρηση είναι στρώμα, όχι επέμβαση.
;;;; ============================================================================

(in-package :orchestrator.cli)

(defvar *ta-pass* 0)
(defvar *ta-fail* 0)
(defmacro ta-check (name form)
  `(handler-case
       (if ,form (progn (incf *ta-pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *ta-fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *ta-fail*) (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

(format t "~%── [+3/0104] TEXT ADMISSION: η πόρτα εισδοχής κειμένου ──~%")

(defparameter *ta-stamp* (get-universal-time))
(defun ta-body (tag) (format nil "test/ta-~D-~A" *ta-stamp* tag))

;;; ── (α) text-hygiene: η καθαρή έδρα ──
(ta-check "α1 καθαρό κείμενο ⇒ ΚΑΜΙΑ παρατήρηση"
          (null (orchestrator.version-graph:text-hygiene
                 "Οι κανόνες του δικαίου, κατά το άρθρο 5Α, «ενδιάμεση παράθεση» και τέλος.")))
(ta-check "α2 ASCII \" ⇒ :ascii-quote"
          (equal '(:ascii-quote)
                 (orchestrator.version-graph:text-hygiene "Κείμενο με \"λάθος\" εισαγωγικά.")))
(ta-check "α3 « χωρίς » ⇒ :unbalanced-guillemets"
          (equal '(:unbalanced-guillemets)
                 (orchestrator.version-graph:text-hygiene "Ανοίγει «και δεν κλείνει.")))
(ta-check "α4 ΟΛΟ το σώμα σε ΕΝΑ ζεύγος «…» ⇒ :fek-wrap"
          (equal '(:fek-wrap)
                 (orchestrator.version-graph:text-hygiene
                  "«Η ιατρική υποβοήθηση επιτρέπεται μόνο κατά τους όρους του νόμου.»")))
(ta-check "α4β εσωτερική παράθεση που ΚΛΕΙΝΕΙ ενδιάμεσα ⇒ ΟΧΙ fek-wrap"
          (null (orchestrator.version-graph:text-hygiene
                 "«πρώτη» και μετά κανονικό κείμενο και «δεύτερη»")))
(ta-check "α5 U+FFFD ⇒ :replacement-char"
          (equal '(:replacement-char)
                 (orchestrator.version-graph:text-hygiene
                  (format nil "σπασμένο ~A εδώ" (code-char #xFFFD)))))
(ta-check "α6 μικτό: \" + αταίριαστα ⇒ ΚΑΝΟΝΙΚΗ σειρά ευρημάτων"
          (equal '(:ascii-quote :unbalanced-guillemets)
                 (orchestrator.version-graph:text-hygiene "«ανοιχτό και \"ascii\".")))

;;; ── (β) η πόρτα: make-version-spec ──
(flet ((admits (&rest args)
         (handler-case (progn (apply #'orchestrator.version-graph:make-version-spec args) t)
           (orchestrator.version-graph:invalid-edge () nil))))
  (ta-check "β1 βρώμικο κείμενο ΧΩΡΙΣ waiver ⇒ invalid-edge (τίποτα σιωπηλό)"
            (not (admits :provision-id "p" :text "με \"ascii\"" :valid-from "2020-01-01"
                         :assurance :extracted-verified)))
  (ta-check "β2 waiver που ΔΕΝ κατονομάζει ακριβώς ⇒ invalid-edge"
            (not (admits :provision-id "p" :text "με \"ascii\"" :valid-from "2020-01-01"
                         :assurance :extracted-verified
                         :hygiene-waiver '(:fek-wrap))))
  (ta-check "β3 ακριβής waiver ⇒ εισδοχή, spec φέρει :hygiene"
            (equal '(:ascii-quote)
                   (getf (orchestrator.version-graph:make-version-spec
                          :provision-id "p" :text "με \"ascii\"" :valid-from "2020-01-01"
                          :assurance :extracted-verified
                          :hygiene-waiver '(:ascii-quote))
                         :hygiene)))
  (ta-check "β4 waiver σε ΚΑΘΑΡΟ κείμενο ⇒ invalid-edge (κανένα blanket/stale)"
            (not (admits :provision-id "p" :text "καθαρό." :valid-from "2020-01-01"
                         :assurance :extracted-verified
                         :hygiene-waiver '(:ascii-quote))))
  (ta-check "β5 πλαστό :hygiene ≠ επανυπολογισμός ⇒ invalid-edge"
            (not (admits :provision-id "p" :text "καθαρό." :valid-from "2020-01-01"
                         :assurance :extracted-verified
                         :hygiene '(:ascii-quote)))))

;;; ── (γ) εισδοχή ⇒ journaled παρατήρηση (γένεση ΚΑΙ ακμή), κείμενο ΑΘΙΚΤΟ ──
(defparameter *ta-g* (orchestrator.version-graph:make-graph (ta-body "main")))
(defparameter *ta-pid* "gr/test#art:1")
(defparameter *ta-dirty* "«Ολόκληρο το σώμα σε παράθεση ΦΕΚ.»")
(defparameter *ta-v1*
  (orchestrator.version-graph:submit-genesis!
   *ta-g* (orchestrator.version-graph:make-version-spec
           :provision-id *ta-pid* :text *ta-dirty* :valid-from "2020-01-01"
           :assurance :extracted-verified
           :hygiene-waiver '(:fek-wrap))))
(ta-check "γ1 genesis με waiver ⇒ 1 παρατήρηση (:fek-wrap) στη διάταξη"
          (let ((obs (orchestrator.version-graph:graph-observations *ta-g* *ta-pid*)))
            (and (= 1 (length obs))
                 (equal '(:fek-wrap)
                        (orchestrator.version-graph:to-findings (first obs)))
                 (equal (orchestrator.version-graph:tv-version-hash *ta-v1*)
                        (orchestrator.version-graph:to-version-hash (first obs))))))
(ta-check "γ2 το κείμενο ΑΘΙΚΤΟ — η παρατήρηση δεν είναι επέμβαση"
          (equal *ta-dirty* (orchestrator.version-graph:tv-text *ta-v1*)))
(ta-check "γ3 καθαρή γένεση σε άλλη διάταξη ⇒ ΚΑΜΙΑ παρατήρηση"
          (progn (orchestrator.version-graph:submit-genesis!
                  *ta-g* (orchestrator.version-graph:make-version-spec
                          :provision-id "gr/test#art:2" :text "Καθαρό κείμενο."
                          :valid-from "2020-01-01" :assurance :extracted-verified))
                 (null (orchestrator.version-graph:graph-observations *ta-g* "gr/test#art:2"))))
(defparameter *ta-edge*
  (orchestrator.version-graph:admit-edge!
   *ta-g* (orchestrator.version-graph:make-edge-spec
           :op :replace :target *ta-pid*
           :from-versions (list (orchestrator.version-graph:tv-version-hash *ta-v1*))
           :to-specs (list (orchestrator.version-graph:make-version-spec
                            :provision-id *ta-pid*
                            :text "Νέο κείμενο με \"ascii\" εισαγωγικά."
                            :valid-from "2021-06-01" :assurance :extracted-verified
                            :hygiene-waiver '(:ascii-quote)))
           :act-ref "ν.0000/2021" :act-internal-seq '(1 1)
           :enacted "2021-05-01" :effective "2021-06-01" :fek-date "2021-05-01")))
(ta-check "γ4 ακμή με βρώμικο to-spec ⇒ ΔΕΥΤΕΡΗ παρατήρηση (:ascii-quote) — ίδια πόρτα"
          (let ((obs (orchestrator.version-graph:graph-observations *ta-g* *ta-pid*)))
            (and (= 2 (length obs))
                 (equal '(:ascii-quote)
                        (orchestrator.version-graph:to-findings (first obs))))))

;;; ── (δ) replay από τον δίσκο: παρατηρήσεις αναπαράγονται + semantic ③ ──
(ta-check "δ1 verify-chain: πλήρες replay με τις νέες γραμμές ⇒ T"
          (nth-value 0 (orchestrator.version-graph:verify-chain (ta-body "main"))))
(ta-check "δ2 load-graph: οι 2 παρατηρήσεις ΞΑΝΑΓΕΝΝΙΟΥΝΤΑΙ από το journal"
          (let ((g2 (orchestrator.version-graph:load-graph (ta-body "main"))))
            (= 2 (length (orchestrator.version-graph:graph-observations g2 *ta-pid*)))))
(ta-check "δ3 πειραγμένα findings στο record ⇒ ρήξη replay (③/payload — εξίσου fail-closed)"
          (let* ((path (orchestrator.version-graph::%graph-path (ta-body "main")))
                 (lines (uiop:read-file-lines path))
                 (victim (find-if (lambda (l) (and (search ":TEXT-OBSERVATION" l)
                                                   (search ":FEK-WRAP" l)))
                                  lines))
                 (body2 (ta-body "tamper")))
            (and victim
                 (progn
                   ;; αντιγραφή journal σε νέο body + αλλοίωση: :FEK-WRAP → :ASCII-QUOTE
                   (with-open-file (out (orchestrator.version-graph::%graph-path body2)
                                        :direction :output :if-exists :supersede
                                        :if-does-not-exist :create
                                        :external-format :utf-8)
                     (dolist (l lines)
                       (write-line (if (string= l victim)
                                       (let ((p (search ":FEK-WRAP" l)))
                                         (concatenate 'string (subseq l 0 p)
                                                      ":ASCII-QUOTE" (subseq l (+ p 9))))
                                       l)
                                   out)))
                   (handler-case
                       (progn (orchestrator.version-graph:load-graph body2) nil)
                     (error () t))))))

(format t "~%========================================~%")
(format t "TEXT-ADMISSION tests: ~D passed, ~D failed~%" *ta-pass* *ta-fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *ta-fail*) 0 1))
