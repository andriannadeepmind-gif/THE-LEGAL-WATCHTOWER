;;;; systems/orchestrator-cli/case-workspace.lisp
;;;; ============================================================================
;;;; Ο ΧΩΡΟΣ ΥΠΟΘΕΣΗΣ — deterministic Global Workspace (Hearsay-II/SOAR blackboard)
;;;; ============================================================================
;;;;
;;;; Μία ΑΡΕΝΑ ανά υπόθεση: όλοι οι ειδικοί γράφουν στον ίδιο πίνακα —
;;;; ΥΠΑΓΩΓΗ (θέσεις+κενά), ΑΝΤΙΔΙΚΙΑ (ενστάσεις), ΥΠΟΘΕΤΙΚΟΣ ΛΟΓΟΣ (κρίσιμα),
;;;; ΣΤΡΑΤΗΓΙΚΗ (προθεσμίες/πορεία), ΠΡΟΗΓΟΥΜΕΝΑ (αποφάσεις που εφαρμόζουν τα
;;;; ίδια άρθρα), ΘΕΜΕΛΙΩΣΗ (ασθενέστεροι κρίκοι) — και η σύνθεση διαβάζει την
;;;; αρένα, όχι τον καθένα χωριστά. Ντετερμινιστικό blackboard: σταθερή σειρά
;;;; εγγραφής, κάθε εγγραφή με τον ειδικό-συγγραφέα και τις αποδείξεις της.

(in-package :orchestrator.cli)

(defun %decisions-citing (corpus article)
  "Οι υλικοποιημένες αποφάσεις που ΕΦΑΡΜΟΖΟΥΝ το corpus:article —
   ((δικαστήριο αριθμός έτος)…) από τα δεσίματα παραπομπών τους."
  (let ((out '()))
    (dolist (dir (uiop:subdirectories
                  (merge-pathnames "deployment/data/decisions/" (uiop:getcwd))) out)
      (dolist (f (uiop:directory-files dir))
        (when (and (string= (pathname-type f) "json")
                   (not (search ".prov" (pathname-name f))))
          (handler-case
              (let ((d (jonathan:parse (uiop:read-file-string f :external-format :utf-8)
                                       :as :alist)))
                (when (loop for c in (cdr (assoc "citations" d :test #'string=))
                            thereis (and (listp c)
                                         (equal corpus (cdr (assoc "corpus" c :test #'string=)))
                                         (equal article (cdr (assoc "article" c :test #'string=)))))
                  (push (list (cdr (assoc "court" d :test #'string=))
                              (cdr (assoc "number" d :test #'string=))
                              (cdr (assoc "year" d :test #'string=)))
                        out)))
            (error () nil)))))))

(defun case-workspace (facts &key today (stream *standard-output*))
  "Ο ΦΑΚΕΛΟΣ ΤΗΣ ΥΠΟΘΕΣΗΣ: όλοι οι ειδικοί στην ίδια αρένα, μία σύνθεση.
   Επιστρέφει (values πλήθος-θέσεων αρένα)."
  (orchestrator.knowledge-packs:ensure-fresh)
  (let ((arena '()))
    ;; ── ① ΥΠΑΓΩΓΗ: ο πρώτος ειδικός γράφει θέσεις + κενά ──
    (multiple-value-bind (engine positions) (orchestrator.subsumption:subsume facts)
      (declare (ignore engine))
      (push (list :υπαγωγή positions) arena)
      (format stream "~%══════ ΦΑΚΕΛΟΣ ΥΠΟΘΕΣΗΣ (~D γεγονότα · όλοι οι ειδικοί στην αρένα) ══════~%"
              (length facts))
      (format stream "~%── ① ΥΠΑΓΩΓΗ ──")
      (orchestrator.subsumption:subsumption-report facts :stream stream)
      ;; ── ② ΑΝΤΙΔΙΚΙΑ ──
      (format stream "~%── ② ΑΝΤΙΔΙΚΙΑ (θέση ↔ ένσταση) ──")
      (multiple-value-bind (standing upheld undecided)
          (orchestrator.dialectic:dialectic-report facts :stream stream)
        (push (list :αντιδικία standing upheld undecided) arena))
      ;; ── ③ ΥΠΟΘΕΤΙΚΟΣ ΛΟΓΟΣ: κρίσιμα ανά ιστάμενη θέση ──
      (format stream "~%── ③ ΚΡΙΣΙΜΑ ΓΕΓΟΝΟΤΑ (τι δεν πρέπει να πέσει) ──~%")
      (dolist (pos positions)
        (let* ((id (fifth (car pos)))
               (norm (and id (orchestrator.deontic:find-norm id))))
          (when norm
            (multiple-value-bind (critical idle basis-p)
                (orchestrator.counterfactual:critical-facts facts norm)
              (declare (ignore idle))
              (when basis-p
                (push (list :κρίσιμα id critical) arena)
                (format stream "  ~A:~{ ~A~}~%" id
                        (mapcar #'orchestrator.knowledge:fact->string critical)))))))
      ;; ── ④ ΠΡΟΗΓΟΥΜΕΝΑ: αποφάσεις που εφαρμόζουν τα ίδια άρθρα ──
      (format stream "~%── ④ ΠΡΟΗΓΟΥΜΕΝΑ (νομολογία στα ίδια άρθρα) ──~%")
      (let ((seen '()))
        (dolist (pos positions)
          (let* ((id (fifth (car pos)))
                 (norm (and id (orchestrator.deontic:find-norm id))))
            (when (and norm (not (member id seen)))
              (push id seen)
              (let* ((corpus (orchestrator.deontic:norm-corpus norm))
                     (article (orchestrator.deontic:norm-article norm))
                     (ds (%decisions-citing corpus article)))
                (push (list :προηγούμενα id ds) arena)
                (if ds
                    (format stream "  άρθρο ~A ~A — το εφαρμόζουν ~D αποφάσεις:~{ ~{~A ~A/~A~}~^ ·~}~%"
                            article corpus (length ds) (subseq ds 0 (min 5 (length ds))))
                    (format stream "  άρθρο ~A ~A — καμία απόφαση στο σώμα μου ακόμη (τίμια)~%"
                            article corpus))))))
        (unless seen (format stream "  (καμία ιστάμενη θέση — δεν αναζητώ προηγούμενα)~%")))
      ;; ── ⑤ ΣΤΡΑΤΗΓΙΚΗ: οι στόχοι ΠΡΟΚΥΠΤΟΥΝ από το μητρώο τελεστών —
      ;;    κάθε τελεστής του δικονομικού δικαίου του οποίου οι προϋποθέσεις
      ;;    ή η αφετηρία προθεσμίας αγγίζουν τα γεγονότα, προτείνει τον
      ;;    ΔΙΚΟ του στόχο (τα :add του). Καμία καρφωτή πράξη.
      (let ((goals '()))
        (dolist (op orchestrator.strategy:*operators*)
          (when (or (loop for pre in (getf op :pre)
                          thereis (member pre facts :test #'equal))
                    (and (getf op :deadline-from)
                         (loop for f in facts
                               thereis (eq (second f) (getf op :deadline-from)))))
            (dolist (g (getf op :add)) (pushnew g goals :test #'equal))))
        (when goals
          (format stream "~%── ⑤ ΣΤΡΑΤΗΓΙΚΗ (στόχοι από το ΙΔΙΟ το δικονομικό δίκαιο) ──")
          (dolist (g goals)
            (orchestrator.strategy:strategy-report facts g :today today :stream stream))
          (push (list :στρατηγική goals) arena)))
      (format stream "~%══════ ΤΕΛΟΣ ΦΑΚΕΛΟΥ — κάθε εγγραφή με τον ειδικό και την απόδειξή της ══════~%")
      (values (length positions) (nreverse arena)))))

(defun run-case (args)
  "--case '<γεγονότα ή αφήγηση>' : ο πλήρης φάκελος — όλοι οι ειδικοί, μία αρένα."
  (let ((s (format nil "~{~A~^ ~}" args)))
    (cond
      ((zerop (length (string-trim " " s)))
       (format t "χρήση: --case 'Ο Α αφαίρεσε το πορτοφόλι της Β για να το ιδιοποιηθεί.' ή --case '((:γεγονός …) …)'~%") 1)
      (t (orchestrator.knowledge-packs:ensure-fresh)
         (let ((facts (if (char= #\( (char (string-left-trim " " s) 0))
                          (handler-case (orchestrator.subsumption:parse-case-facts s)
                            (error (e) (format t "άκυρα γεγονότα: ~A~%" e) nil))
                          (multiple-value-bind (fs unparsed)
                              (orchestrator.casegrammar:parse-narrative s)
                            (dolist (u unparsed)
                              (format t "  ⚠ ΔΕΝ αναγνωρίστηκε: «~A»~%" u))
                            fs))))
           (if (null facts)
               (progn (format t "Καμία αναγνωρισμένη πράξη/γεγονός.~%") 1)
               (progn (case-workspace facts) 0)))))))

(register-command "--case"     (lambda (a) (run-case a)))
(register-command "--φάκελος"  (lambda (a) (run-case a)))
