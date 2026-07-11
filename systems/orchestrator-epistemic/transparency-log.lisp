;;;; systems/orchestrator-epistemic/transparency-log.lisp
;;;; ============================================================================
;;;; L7-B — TRANSPARENCY LOG ΤΩΝ RELEASE ROOTS (RFC 6962 §2.1.2)
;;;; ============================================================================
;;;;
;;;; Πρότυπο Certificate Transparency: κάθε corpus κρατά ένα append-only log
;;;; (releases/transparency-log.json) όπου κάθε ΦΥΛΛΟ = ένα attested release
;;;; root, με σειρά δημοσίευσης. Το log δεσμεύεται από τη δική του Merkle ρίζα
;;;; (log_root, η ΜΙΑ έδρα orchestrator.merkle) και κρατά ΟΛΑ τα προηγούμενα
;;;; checkpoints {size, log_root}. Σε ΚΑΘΕ append:
;;;;   1. υπολογίζεται consistency proof PROOF(old_size, new) (RFC 6962 §2.1.2)
;;;;   2. επαληθεύεται ΠΡΙΝ γραφτεί οτιδήποτε (verify-consistency — μαθηματικά,
;;;;      όχι εμπιστοσύνη)· αποτυχία ⇒ ΣΦΑΛΜΑ, το log ΔΕΝ αγγίζεται.
;;;; Έτσι η ιδιότητα «η ιστορία ΔΕΝ ξαναγράφεται» (δόγμα δύο εποχών, CT/
;;;; Trillian) παύει να είναι υπόσχεση και γίνεται ελέγξιμο μαθηματικό γεγονός:
;;;; ένας εξωτερικός verifier που κράτησε ΟΠΟΙΟΔΗΠΟΤΕ παλιό log_root
;;;; αποδεικνύει με το proof ότι το σημερινό log τον επεκτείνει.
;;;;
;;;; ΜΙΑ έδρα: κανένα άλλο σημείο του συστήματος δεν ορίζει log/checkpoint/
;;;; consistency. Τα Merkle μαθηματικά ζουν ΜΟΝΟ στο orchestrator.merkle.
;;;; ============================================================================

(in-package :orchestrator.epistemic)

(defparameter +tlog-version+ "tlog-1")

(defun %tlog-path (releases-dir)
  (merge-pathnames "transparency-log.json"
                   (uiop:ensure-directory-pathname releases-dir)))

(defun %tlog-leaf (root)
  "Φύλλο log = domain-separated hash του release-root string (sha256:<hex>)."
  (orchestrator.merkle:hash-leaf-string root))

(defun %tlog-read (path)
  "Διαβάζει και ΔΟΜΙΚΑ ελέγχει το transparency log. NIL αν δεν υπάρχει αρχείο.
   Επιστρέφει plist (:entries (roots…) :log-root str :checkpoints ((size . root)…)).
   Άκυρο/ελλιπές αρχείο ⇒ ΣΦΑΛΜΑ (ποτέ σιωπηλή επανεκκίνηση ιστορίας)."
  (when (probe-file path)
    (let ((doc (handler-case (jonathan:parse (uiop:read-file-string path)
                                             :as :hash-table)
                 (error (e)
                   (error 'validation-error
                          :message "transparency-log.json: άκυρο JSON"
                          :details (princ-to-string e))))))
      (let ((version (gethash "version" doc))
            (entries (gethash "entries" doc))
            (log-root (gethash "log_root" doc))
            (checkpoints (gethash "checkpoints" doc)))
        (unless (equal version +tlog-version+)
          (error 'validation-error
                 :message "transparency-log.json: άγνωστη έκδοση"
                 :details (format nil "~A" version)))
        (unless (and (listp entries) entries (stringp log-root))
          (error 'validation-error
                 :message "transparency-log.json: λείπουν entries/log_root"))
        (list :entries entries
              :log-root log-root
              :checkpoints (mapcar (lambda (cp)
                                     (cons (gethash "size" cp)
                                           (gethash "log_root" cp)))
                                   (or checkpoints '())))))))

(defun %tlog-write (path entries log-root checkpoints)
  (with-open-file (o path :direction :output :if-exists :supersede)
    ;; Χειροποίητο ντετερμινιστικό JSON (ίδια πειθαρχία με census->json):
    ;; σταθερή σειρά κλειδιών, καμία εξάρτηση από hash-table iteration.
    (format o "{\"version\":\"~A\",\"merkle\":\"rfc6962-sha256\",~
               \"tree_size\":~D,\"log_root\":\"~A\",\"entries\":[~{\"~A\"~^,~}],~
               \"checkpoints\":[~{~A~^,~}]}~%"
            +tlog-version+ (length entries) log-root entries
            (mapcar (lambda (cp)
                      (format nil "{\"size\":~D,\"log_root\":\"~A\"}"
                              (car cp) (cdr cp)))
                    checkpoints))))

(defun tlog-append-root! (releases-dir release-root)
  "Append του RELEASE-ROOT στο transparency log του RELEASES-DIR.
   Ιδεμποτές για το ΤΕΛΕΥΤΑΙΟ entry (re-attest ίδιου root δεν διπλογράφει).
   Πριν από κάθε εγγραφή: PROOF(old,new) επαληθεύεται με verify-consistency —
   αποτυχία ⇒ ΣΦΑΛΜΑ και το αρχείο μένει ανέγγιχτο. Επιστρέφει το νέο log_root."
  (unless (and (stringp release-root)
               (eql 0 (search "sha256:" release-root))
               (= (length release-root) 71))
    (error 'validation-error
           :message "tlog-append-root!: μη έγκυρο release root"
           :details (format nil "~S" release-root)))
  (let* ((path (%tlog-path releases-dir))
         (old (%tlog-read path))
         (old-entries (getf old :entries))
         (old-root (getf old :log-root)))
    (cond
      ;; Ιδεμποτές: το root είναι ήδη το τελευταίο entry ⇒ καμία αλλαγή.
      ((and old-entries (equal (car (last old-entries)) release-root))
       old-root)
      (t
       (let* ((new-entries (append old-entries (list release-root)))
              (leaves (mapcar #'%tlog-leaf new-entries))
              (new-root (orchestrator.merkle:merkle-tree-hash leaves))
              (m (length old-entries))
              (n (length new-entries)))
         ;; Συνέπεια με ΟΛΗ την ιστορία πριν γραφτεί byte (fail-closed).
         (when old
           (let ((proof (orchestrator.merkle:consistency-proof leaves m)))
             (unless (orchestrator.merkle:verify-consistency
                      m n old-root new-root proof)
               (error 'validation-error
                      :message "tlog-append-root!: το νέο log ΔΕΝ επεκτείνει το παλιό — άρνηση εγγραφής"
                      :details (format nil "m=~D n=~D old=~A" m n old-root))))
           ;; Και κάθε παλιό checkpoint παραμένει consistent με το νέο δέντρο.
           (dolist (cp (getf old :checkpoints))
             (let ((proof (orchestrator.merkle:consistency-proof leaves (car cp))))
               (unless (orchestrator.merkle:verify-consistency
                        (car cp) n (cdr cp) new-root proof)
                 (error 'validation-error
                        :message "tlog-append-root!: checkpoint ασυνεπές με το νέο δέντρο"
                        :details (format nil "size=~D" (car cp)))))))
         (%tlog-write path new-entries new-root
                      (append (getf old :checkpoints)
                              (when old (list (cons m old-root)))))
         new-root)))))

(defun tlog-verify (releases-dir)
  "Πλήρης επαλήθευση του transparency log:
     (α) log_root ≡ MTH(entries) — επανυπολογισμός από τη ΜΙΑ Merkle έδρα·
     (β) ΚΑΘΕ checkpoint {size m, root} συνεπές με το τρέχον δέντρο
         (PROOF(m,n) + verify-consistency — RFC 6962 §2.1.2).
   Επιστρέφει (values t plist) ή σφάλμα VALIDATION-ERROR (fail-closed).
   Αν δεν υπάρχει log: (values :absent nil) — ΤΙΜΙΟ (πρώτη εποχή), ο καλών
   αποφασίζει αν το απόν είναι αποδεκτό για το πλαίσιό του."
  (let* ((path (%tlog-path releases-dir))
         (log (%tlog-read path)))
    (if (null log)
        (values :absent nil)
        (let* ((entries (getf log :entries))
               (leaves (mapcar #'%tlog-leaf entries))
               (n (length entries))
               (recomputed (orchestrator.merkle:merkle-tree-hash leaves)))
          (unless (equal recomputed (getf log :log-root))
            (error 'validation-error
                   :message "transparency log: log_root ≠ MTH(entries) — ΔΙΑΦΘΟΡΑ"
                   :details (format nil "δηλωμένο ~A ≠ ~A"
                                    (getf log :log-root) recomputed)))
          (dolist (cp (getf log :checkpoints))
            (destructuring-bind (m . old-root) cp
              (unless (and (integerp m) (<= 1 m n))
                (error 'validation-error
                       :message "transparency log: άκυρο checkpoint size"
                       :details (format nil "~S" m)))
              (let ((proof (orchestrator.merkle:consistency-proof leaves m)))
                (unless (orchestrator.merkle:verify-consistency
                         m n old-root recomputed proof)
                  (error 'validation-error
                         :message "transparency log: checkpoint ΔΕΝ επεκτείνεται από το τρέχον δέντρο — η ιστορία ξαναγράφτηκε"
                         :details (format nil "size=~D root=~A" m old-root))))))
          (values t (list :tree-size n :log-root recomputed
                          :checkpoints (length (getf log :checkpoints))))))))
