;;;; tests/seat-integrity-test.lisp
;;;; ============================================================================
;;;; [0086] ΑΚΕΡΑΙΟΤΗΤΑ ΕΔΡΩΝ — regression locks των ευρημάτων της εξωτερικής
;;;; μελέτης (επαληθευμένα ένα-ένα στον κώδικα πριν κλειδωθούν):
;;;;   Α. Θάνατος σιωπηλής αντικατάστασης έδρας εντολής (command-seat-collision)
;;;;      + ανάσταση νομικού --what-if + --capability-impact.
;;;;   Β. ΜΙΑ export-provenance-json (chain) — η νεκρή article-εκδοχή διαγράφηκε.
;;;;   Γ. Persistence Receipt: id ⇒ durable + read-back verified· degraded ⇒ ΣΦΑΛΜΑ.
;;;;      Adoption ledger ΔΙΑΡΚΕΣ (όχι RAM-only).
;;;;   Δ. ΜΙΑ ρίζα: κανένα uiop:getcwd σε persistent path (source scan).
;;;;   ΣΤ. WFS proof-honesty: defeater :undefined ΔΕΝ λογίζεται «απών» στο support.
;;;; ============================================================================

(in-package :cl-user)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(format t "~%== Α. μητρώο εντολών: ΜΙΑ έδρα ανά εντολή ==~%")
(check "το --what-if ανήκει στη ΝΟΜΙΚΗ έδρα (subsumption-commands)"
       (let ((o (orchestrator.cli::command-owner "--what-if")))
         (and o (search "subsumption-commands" o))))
(check "το --self-what-if υπάρχει (η αυτοεξέλιξη ΔΕΝ σκιάζει πια το νομικό)"
       (and (orchestrator.cli::find-command "--self-what-if")
            (let ((o (orchestrator.cli::command-owner "--self-what-if")))
              (and o (search "evolution-gate" o)))))
(check "το --capability-impact υπάρχει (αναστήθηκε από τη σκίαση του --impact)"
       (and (orchestrator.cli::find-command "--capability-impact") t))
(check "duplicate εγγραφή από ΑΛΛΟ αρχείο ⇒ COMMAND-SEAT-COLLISION (δομικά αδύνατη η σκίαση)"
       (handler-case
           (progn (orchestrator.cli::register-command "--what-if" (lambda (a) a)) nil)
         (orchestrator.cli::command-seat-collision () t)))
(check "ΚΑΘΕ εντολή του μητρώου έχει ΕΝΑΝ καταγεγραμμένο ιδιοκτήτη"
       (let ((ok t))
         (maphash (lambda (name fn)
                    (declare (ignore fn))
                    (unless (orchestrator.cli::command-owner name) (setf ok nil)))
                  orchestrator.cli::*commands*)
         ok))

(format t "~%== Β. ΜΙΑ έδρα export-provenance-json (chain) ==~%")
(check "ΑΚΡΙΒΩΣ ΕΝΑΣ ορισμός export-provenance-json σε όλο το δέντρο (source scan)"
       (= 1 (let ((n 0))
              (dolist (dir '("source/" "systems/") n)
                (dolist (f (directory (merge-pathnames
                                       (format nil "~A**/*.lisp" dir)
                                       (orchestrator.paths:institution-root))))
                  (with-open-file (s f :external-format :utf-8)
                    (loop for l = (read-line s nil nil) while l
                          when (search "(defun export-provenance-json" l)
                            do (incf n))))))))

(format t "~%== Γ. Persistence Receipt: id ⟺ durable ==~%")
(let ((tmp (merge-pathnames (format nil "seat-receipt-~D.sexp" (sb-unix:unix-getpid))
                            (uiop:temporary-directory))))
  (multiple-value-bind (line r) (orchestrator.journal:append-line tmp '(:probe t) :verify t)
    (declare (ignore line))
    (check "append-line :verify ⇒ receipt :durable + :readback-verified"
           (and (orchestrator.journal:durable-p r)
                (orchestrator.journal:receipt-verified-p r))))
  (ignore-errors (delete-file tmp)))
(let ((orchestrator.proposals:*proposals-path*
        (merge-pathnames (format nil "seat-props-~D.sexp" (sb-unix:unix-getpid))
                         (uiop:temporary-directory))))
  (check "propose! σε εγγράψιμο ημερολόγιο ⇒ id (και το γεγονός ΔΙΑΒΑΖΕΤΑΙ πίσω)"
         (let ((id (orchestrator.proposals:propose!
                    :sig "seat-integrity-πρόταση" :kind :test :why "lock")))
           (and id (find id (orchestrator.proposals:proposals)
                        :key #'orchestrator.proposals:proposal-id :test #'equal))))
  (ignore-errors (delete-file orchestrator.proposals:*proposals-path*)))
(let ((orchestrator.proposals:*proposals-path* #p"/proc/lawmax-αδύνατο/props.sexp"))
  (check "propose! σε ΜΗ εγγράψιμο ⇒ journal:NOT-DURABLE (η ΜΙΑ έδρα — ΚΑΝΕΝΑ σιωπηλό id)"
         (handler-case
             (progn (orchestrator.proposals:propose!
                     :sig "seat-degraded-πρόταση" :kind :test :why "x")
                    nil)
           (orchestrator.journal:not-durable (c)
             (eq (orchestrator.journal:not-durable-context c) :proposal)))))
;; [0086+] Γραμμή-δηλητήριο: απορρίπτεται ΠΡΙΝ τον δίσκο, το αρχείο ΔΕΝ ρυπαίνεται
(let ((tmp (merge-pathnames (format nil "seat-poison-~D.sexp" (sb-unix:unix-getpid))
                            (uiop:temporary-directory))))
  (orchestrator.journal:append-line tmp '(:ok 1))
  (check "μη-σειριοποιήσιμο plist ⇒ UNSERIALIZABLE-RECORD ΠΡΙΝ τον δίσκο (0 ρύπανση)"
         (and (handler-case
                  (progn (orchestrator.journal:append-line
                          tmp (list :bad (make-hash-table)) :verify t)
                         nil)
                (orchestrator.journal:unserializable-record () t))
              (= 1 (length (orchestrator.journal:read-lines tmp)))))
  ;; [0086+] Ανθεκτικός αναγνώστης: κακή γραμμή ΠΡΟΣΠΕΡΝΙΕΤΑΙ, οι επόμενες ΖΟΥΝ
  (with-open-file (s tmp :direction :output :if-exists :append :external-format :utf-8)
    (write-line "(:σκουπίδι #<UNREADABLE" s))
  (orchestrator.journal:append-line tmp '(:ok 2))
  (check "κακή γραμμή στη μέση ⇒ ΠΡΟΣΠΕΡΝΙΕΤΑΙ· οι μεταγενέστερες γραμμές ΟΡΑΤΕΣ (θάνατος «μαύρης τρύπας»)"
         (equal '((:ok 1) (:ok 2))
                (remove-if-not (lambda (f) (getf f :ok))
                               (orchestrator.journal:read-lines tmp))))
  (ignore-errors (delete-file tmp)))
;; [0086+] B-A1 lock: η ροή adopt-knowledge δεν ξανασπάει με NIL override
(check "knowledge-dir accessor: non-NIL υπό ρίζα και merge-pathnames λειτουργεί (lock του σπασμένου --adopt-knowledge)"
       (let ((d (orchestrator.knowledge-packs:knowledge-dir)))
         (and d (pathnamep (merge-pathnames "x.sexp" d))
              (search (namestring (orchestrator.paths:institution-root))
                      (namestring d)))))
(let ((orchestrator.adoption:*adoptions-path*
        (merge-pathnames (format nil "seat-adopt-~D.sexp" (sb-unix:unix-getpid))
                         (uiop:temporary-directory))))
  (check "record-adoption! γράφει στο ΔΙΑΡΚΕΣ ledger και ξαναδιαβάζεται (όχι RAM-only)"
         (multiple-value-bind (rec sha tid receipt)
             (orchestrator.adoption:record-adoption!
              (list :verdict :allowed :proposal "seat-δοκιμή" :whatif '(:x t)))
           (declare (ignore rec tid))
           (and sha
                (orchestrator.journal:durable-p receipt)
                (orchestrator.journal:receipt-verified-p receipt)
                (find sha (orchestrator.adoption:adoption-records)
                      :key (lambda (r) (getf r :sha)) :test #'equal))))
  (ignore-errors (delete-file orchestrator.adoption:*adoptions-path*)))

(format t "~%== Δ. ΜΙΑ ρίζα (institution-root) — accessors ==~%")
;; Η αστυνομία πηγών «κανένα getcwd» έχει ΜΙΑ έδρα: architecture-gate ⑭ ([0086+]
;; εύρημα κριτή Β-Γ2 — το τεστ δεν κρατά δεύτερο αντίγραφο του ίδιου ελέγχου).
(check "episodes/history/proposals/adoptions paths ΟΛΑ κάτω από institution-root"
       (let ((root (namestring (orchestrator.paths:institution-root))))
         (every (lambda (p) (search root (namestring p)))
                (list (orchestrator.memory:episodes-path)
                      (orchestrator.self-history:history-path)
                      (orchestrator.proposals::%proposals-path)
                      (orchestrator.adoption::%adoptions-path)))))

(format t "~%== ΣΤ. WFS proof-honesty (μάρτυρας του κριτή, μόνιμος) ==~%")
(let* ((j (orchestrator.inference:make-jtms))
       (d (orchestrator.inference:tms-intern j :d))
       (e (orchestrator.inference:tms-intern j :e))
       (f (orchestrator.inference:tms-intern j :f)))
  (declare (ignorable e f))
  (orchestrator.inference:tms-justify j :d '() (list e) :r-d)
  (orchestrator.inference:tms-justify j :e '() (list d) :r-e)
  (orchestrator.inference:tms-justify j :p '() (list d) :j1-μέσω-αναποφάσιστου)
  (orchestrator.inference:tms-justify j :p '() (list f) :j2-μέσω-ψευδούς)
  (orchestrator.inference:recompute-beliefs j)
  (let ((p (orchestrator.inference:tms-find j :p)))
    (check "p είναι :in (WFS αλήθεια αμετάβλητη)"
           (orchestrator.inference:node-believed-p p))
    (check "d είναι :undefined (η ισοπαλία ΔΗΛΩΝΕΤΑΙ)"
           (eq (orchestrator.inference:fact-status j :d) :undefined))
    (check "support(p) = j2 μέσω ΓΝΗΣΙΑ ψευδούς defeater — ΟΧΙ j1 μέσω αναποφάσιστου"
           (let ((sup (orchestrator.inference::node-support p)))
             (and sup (not (eq sup :premise))
                  (eq (orchestrator.inference::justification-informant sup)
                      :j2-μέσω-ψευδούς)))))
  (orchestrator.inference:tms-justify j :q '() (list d) :jq)
  (orchestrator.inference:recompute-beliefs j)
  (check "q (ΜΟΝΟ μέσω αναποφάσιστου defeater) ⇒ :undefined, ποτέ :in"
         (eq (orchestrator.inference:fact-status j :q) :undefined)))

(format t "~%========================================~%")
(format t "SEAT-INTEGRITY [0086]: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
