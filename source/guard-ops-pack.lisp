;;;; source/guard-ops-pack.lisp
;;;; ============================================================================
;;;; Ο ΚΑΤΑΝΑΛΩΤΗΣ :guard-ops — νέοι τελεστές φραγμών ΩΣ ΓΝΩΣΗ
;;;; ============================================================================
;;;;
;;;; Γέφυρα μετακυκλικού αποτιμητή ↔ πακέτων γνώσης (φορτώνει ΜΕΤΑ τα πακέτα).
;;;; Ένα πακέτο (:knowledge-pack :guard-ops 1 (:op "εντός-μηνών" (α β ν)
;;;; (within-days α β (* 30 ν))) …) προσθέτει τελεστή ΣΤΗ ΓΛΩΣΣΑ — με όλες τις
;;;; εγγυήσεις της: στρωμάτωση (τερματισμός), όχι επανορισμός πρωτογενούς,
;;;; snapshot/restore για σκιώδη δοκιμή. Η γλώσσα των φραγμών εξελίσσεται
;;;; όπως κάθε γνώση: πρόταση → σκιά → έγκριση — ποτέ σιωπηλά.

(in-package :orchestrator.metaeval)

(orchestrator.knowledge-packs:define-knowledge-kind :guard-ops
 :doc "Παράγωγοι τελεστές της γλώσσας φραγμών (:op όνομα (παράμετροι) σώμα [doc])"
 :install (lambda (entries)
            ;; COPY-ON-WRITE + ατομική δημοσίευση (εύρημα επιθεώρησης 05-07-2026):
            ;; η εγκατάσταση δουλεύει σε ΑΝΤΙΓΡΑΦΟ του μητρώου· αναγνώστες σε
            ;; άλλα νήματα (/ask) βλέπουν πάντα ΠΛΗΡΗ γλώσσα — ποτέ μισογραμμένη.
            (let ((work (make-hash-table :test 'equal)))
              (maphash (lambda (k v) (setf (gethash k work) v)) *ops*)
              (let ((*ops* work))
                (dolist (e entries)
                  (destructuring-bind (marker name params body &optional doc) e
                    (unless (eq marker :op)
                      (error ":guard-ops: κάθε entry είναι (:op όνομα (παράμετροι) σώμα), βρέθηκε ~S" e))
                    (define-derived (string name) params body doc))))
              (setf *ops* work)))
 :snapshot #'ops-snapshot
 :restore #'ops-restore)
