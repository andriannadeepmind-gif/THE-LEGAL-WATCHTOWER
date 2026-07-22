;;;; systems/orchestrator-cli/commands.lisp
;;;; ============================================================================
;;;; [0115] ΥΠΟ ΑΠΟΣΥΡΣΗ — TOMBSTONE STAGE (πρωτόκολλο απόσυρσης έδρας)
;;;; ============================================================================
;;;; Οι 5 συναρτήσεις αυτού του αρχείου αποδείχθηκαν ΜΗ ΠΡΟΣΒΑΣΙΜΕΣ στο όριο
;;;; εγγύησης (static + runtime closure, commit b5953a04): καμία registered
;;;; εντολή (163 στο μητρώο — καμία εδώ), κανένας ζωντανός caller, κανένα
;;;; Docker/ASDF/HTTP/cron μονοπάτι. Κατάταξη:
;;;;   run-full-build      → γνήσιο διπλό (κατώτερο υποσύνολο) του run-pipeline (main.lisp)
;;;;   run-full-build-ai   → legacy orchestration· manifest/provenance καλύπτονται
;;;;                          από τη ζωντανή deploy-stage (stages/deploy.lisp)
;;;;   run-ai-export-only  → legacy export entrypoint· βλ. dataset-package projection
;;;;                          contract (deployment/LAWMAX-DATASET-PACKAGE-PROJECTION.md)
;;;;   validate-pipeline   → redundant wrapper του orchestrator.spec:validate-pipeline
;;;;                          (introspection.lisp — το ζωντανό generic)
;;;;   generate-report     → νεκρός file-writing adapter του orchestrator.meta:generate-json-report
;;;;
;;;; Για ΕΝΑΝ κύκλο επαλήθευσης τα σώματα είναι typed παγίδες (retired-entrypoint):
;;;; κάθε κρυφός δυναμικός caller (find-symbol/funcall/uiop:symbol-call) εμφανίζεται
;;;; ΑΜΕΣΩΣ και ονομάζεται από τις πύλες. Tombstone hit ⇒ η διαγραφή ΑΚΥΡΩΝΕΤΑΙ.
;;;; Καθαρό tombstone run (rebuild + 25 πύλες + πλήρης σουίτα + all corpora) ⇒
;;;; οριστική διαγραφή του αρχείου σε επόμενη φάση, με έγκριση δημιουργού.

(in-package :orchestrator.cli)

(defun run-full-build (&key config-path corpus-name)
  "[0115 ΑΠΟΣΥΡΜΕΝΟ] Χρήση: orchestrator.cli::run-pipeline (η ΜΙΑ έδρα εκτέλεσης pipeline)."
  (declare (ignore config-path corpus-name))
  (error 'orchestrator.spec:retired-entrypoint
         :message "run-full-build αποσύρθηκε [0115]"
         :symbol 'run-full-build
         :canonical-entrypoint 'run-pipeline))

(defun run-full-build-ai (&key config-path corpus-name output-dir deterministic
                               timestamp-override ai-config-path ai-config)
  "[0115 ΑΠΟΣΥΡΜΕΝΟ] Build: run-pipeline · AI manifest/provenance: ζωντανή deploy-stage."
  (declare (ignore config-path corpus-name output-dir deterministic
                   timestamp-override ai-config-path ai-config))
  (error 'orchestrator.spec:retired-entrypoint
         :message "run-full-build-ai αποσύρθηκε [0115]"
         :symbol 'run-full-build-ai
         :canonical-entrypoint 'run-pipeline))

(defun run-ai-export-only (&key corpus-name config-path ai-config-path
                                deterministic timestamp-override)
  "[0115 ΑΠΟΣΥΡΜΕΝΟ] Ικανότητα δηλωμένη στο dataset-package projection contract — όχι δεύτερη orchestration έδρα."
  (declare (ignore corpus-name config-path ai-config-path
                   deterministic timestamp-override))
  (error 'orchestrator.spec:retired-entrypoint
         :message "run-ai-export-only αποσύρθηκε [0115] — βλ. LAWMAX-DATASET-PACKAGE-PROJECTION.md"
         :symbol 'run-ai-export-only
         :canonical-entrypoint nil))

(defun validate-pipeline (pipeline-name)
  "[0115 ΑΠΟΣΥΡΜΕΝΟ] Χρήση: orchestrator.spec:validate-pipeline (το ζωντανό generic κάνει ήδη symbol→lookup→validate)."
  (declare (ignore pipeline-name))
  (error 'orchestrator.spec:retired-entrypoint
         :message "cli::validate-pipeline αποσύρθηκε [0115]"
         :symbol 'validate-pipeline
         :canonical-entrypoint 'orchestrator.spec:validate-pipeline))

(defun generate-report (pipeline-name output-path)
  "[0115 ΑΠΟΣΥΡΜΕΝΟ] Χρήση: orchestrator.meta:generate-json-report (η έδρα introspection report)."
  (declare (ignore pipeline-name output-path))
  (error 'orchestrator.spec:retired-entrypoint
         :message "cli::generate-report αποσύρθηκε [0115]"
         :symbol 'generate-report
         :canonical-entrypoint 'orchestrator.meta:generate-json-report))
