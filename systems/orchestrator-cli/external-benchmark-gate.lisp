;;;; systems/orchestrator-cli/external-benchmark-gate.lisp
;;;; ============================================================================
;;;; ΠΥΛΗ ΕΞΩΤΕΡΙΚΟΥ BENCHMARK — CPEI L11 external attestation · DRY-RUN HOOK
;;;; ============================================================================
;;;;
;;;; Το ελάχιστο σταθερό άγκιστρο που ζήτησε ο Κριτής Εξωτερικής Νοημοσύνης
;;;; (CPEI-BENCHMARK-SPEC-v0, deployment/collab/dialogue/0004-kritis.md), με
;;;; ρητό ΟΚ δημιουργού:
;;;;
;;;;   --external-benchmark-gate --bundle <path> [--fingerprint sha256:…]
;;;;                             [--mode dry-run]
;;;;
;;;; DRY-RUN ΜΟΝΟ: επικυρώνει σχήμα + αποτύπωμα του hidden bundle και
;;;; επιστρέφει :not-run ή :invalid. ΔΕΝ εκτελεί ΚΑΝΕΝΑ hidden item, ΔΕΝ
;;;; τυπώνει ΠΟΤΕ περιεχόμενο item (ούτε visible-prompt) — μόνο πλήθη ανά
;;;; layer. Τα :measured/:blocked/:passed είναι ΜΕΛΛΟΝΤΙΚΟ βήμα με νέα
;;;; έγκριση. Το αποτύπωμα είναι DETACHED (όρισμα ή sidecar <path>.sha256):
;;;; hash των bytes του αρχείου δεν μπορεί να αυτο-περιέχεται.
;;;;
;;;; Χωρίς --bundle (ολομέλεια): αυτο-έλεγχος του επικυρωτή με συνθετικά
;;;; bundles σε temp — αποδεικνύει ότι η έδρα L11 υπάρχει και ο επικυρωτής
;;;; πιάνει tamper/schema/leak, ΧΩΡΙΣ να απαιτεί πραγματικό hidden set.

(in-package :orchestrator.cli)

(defparameter +ebg-layers+ '(:currentness :provision :subsumption :dialectic)
  "Τα 4 στρώματα του CPEI-BENCHMARK-SPEC-v0 (Κριτής, 0004).")

(defun %ebg-file-fingerprint (path)
  "Αποτύπωμα των bytes του bundle: sha256 του πλήρους κειμένου του αρχείου."
  (format nil "sha256:~A"
          (orchestrator.journal:sha256-hex (uiop:read-file-string path))))

(defun %ebg-read-data (path)
  "Data-only ανάγνωση (*read-eval* NIL, keyword package) — ποτέ εκτέλεση."
  (with-open-file (s path :external-format :utf-8)
    (let ((*read-eval* nil)
          (*package* (find-package :keyword)))
      (read s nil nil))))

(defun %ebg-item-invalid (item)
  "Ο λόγος ακυρότητας ενός item ή NIL — ΧΩΡΙΣ να επιστρέφει ΠΟΤΕ περιεχόμενο."
  (cond ((or (not (listp item)) (oddp (length item))) :item_not_plist)
        ((not (stringp (getf item :id))) :item_id_missing)
        ((not (member (getf item :layer) +ebg-layers+)) :item_layer_invalid)
        ((not (stringp (getf item :visible-prompt))) :item_visible_prompt_missing)
        (t nil)))

(defun %ebg-validate (bundle-path fingerprint)
  "Η ΜΙΑ επικύρωση dry-run. (values verdict reason info) όπου verdict
   :not-run (επικύρωση ΠΕΡΑΣΕ — το benchmark απλώς δεν έχει τρέξει) ή
   :invalid (με ρητό reason). Το info περιέχει ΜΟΝΟ πλήθη/αποτύπωμα —
   ποτέ περιεχόμενο item (φράγμα διαρροής εκ κατασκευής)."
  (block validate
    (handler-case
        (progn
          (unless (and bundle-path (probe-file bundle-path))
            (return-from validate (values :invalid :bundle_missing nil)))
          (unless fingerprint
            (return-from validate (values :invalid :fingerprint_missing nil)))
          (unless (cl-ppcre:scan "^sha256:[0-9a-f]{64}$" (string-downcase fingerprint))
            (return-from validate (values :invalid :fingerprint_format nil)))
          (let ((computed (%ebg-file-fingerprint bundle-path)))
            (unless (string= computed (string-downcase fingerprint))
              (return-from validate
                (values :invalid :fingerprint_mismatch (list :computed computed))))
            (let ((form (%ebg-read-data bundle-path)))
              (unless (and (listp form)
                           (eq (first form) :external-benchmark-bundle)
                           (integerp (second form)))
                (return-from validate (values :invalid :schema_not_bundle nil)))
              (let* ((plist (cddr form))
                     (owner (getf plist :owner))
                     (as-of (getf plist :as-of-date))
                     (items (getf plist :items)))
                (unless (stringp owner)
                  (return-from validate (values :invalid :schema_owner_missing nil)))
                (unless (and (stringp as-of)
                             (cl-ppcre:scan "^\\d{4}-\\d{2}-\\d{2}$" as-of))
                  (return-from validate (values :invalid :schema_as_of_date nil)))
                (unless (and (listp items) (plusp (length items)))
                  (return-from validate (values :invalid :schema_items_empty nil)))
                (let ((bad (loop for it in items
                                 for i from 0
                                 for why = (%ebg-item-invalid it)
                                 when why collect (list :item-index i :why why))))
                  (when bad
                    (return-from validate
                      (values :invalid :schema_item_invalid (list :bad-items bad))))
                  (values :not-run nil
                          (list :fingerprint computed
                                :version (second form)
                                :owner owner
                                :as-of-date as-of
                                :items-count (length items)
                                :per-layer
                                (loop for l in +ebg-layers+
                                      collect (cons l (count l items
                                                             :key (lambda (it)
                                                                    (getf it :layer))))))))))))
      (error ()
        ;; ποτέ λεπτομέρεια σφάλματος που θα μπορούσε να ηχήσει περιεχόμενο
        (values :invalid :unreadable nil)))))

(defun %ebg-report (verdict reason info mode)
  "Η αναφορά — μηχανικά αναγνώσιμη, ΧΩΡΙΣ κανένα περιεχόμενο item."
  (format t "~%── ΠΥΛΗ ΕΞΩΤΕΡΙΚΟΥ BENCHMARK (CPEI L11 · external attestation) ──~%")
  (format t "mode: ~(~A~)~%" mode)
  (format t "verdict: ~(~S~)~%" verdict)
  (when reason (format t "reason: ~(~A~)~%" reason))
  (when info
    (loop for (k v) on info by #'cddr
          do (format t "~(~A~): ~A~%" (substitute #\_ #\- (string k)) v)))
  (when (eq verdict :not-run)
    (format t "dry_run_validation: ~:[not-applicable~;passed~]~%" info)
    (format t "note: κανένα hidden item δεν εκτελέστηκε ούτε τυπώθηκε — μόνο σχήμα/αποτύπωμα/πλήθη~%")))

(defun %ebg-selftest ()
  "Αυτο-έλεγχος του επικυρωτή με συνθετικά bundles (temp, εκτός repo):
   αποδεικνύει tamper-detection, schema-detection, no-leak, ντετερμινισμό."
  (let ((dir (merge-pathnames "lawmax-ebg-selftest/" (uiop:temporary-directory)))
        (fails '()) (total 0))
    (ensure-directories-exist dir)
    (flet ((chk (label ok)
             (incf total)
             (if ok (format t "  ✓ ~A~%" label)
                 (progn (push label fails) (format t "  ✗ ~A~%" label))))
           (wr (name text)
             (let ((p (merge-pathnames name dir)))
               (with-open-file (o p :direction :output :if-exists :supersede
                                    :external-format :utf-8)
                 (write-string text o))
               p)))
      (let* ((valid-text
               (format nil "(:external-benchmark-bundle 1~% :owner \"kritis-selftest\"~% :as-of-date \"2026-07-07\"~% :items ((:id \"T1\" :layer :currentness :visible-prompt \"ΟΡΑΤΟ-ΔΟΚΙΜΙΟ-1\" :hidden-expected (:answer \"ΚΡΥΦΗ-ΑΠΑΝΤΗΣΗ-1\"))~%          (:id \"T2\" :layer :dialectic :visible-prompt \"ΟΡΑΤΟ-ΔΟΚΙΜΙΟ-2\" :hidden-expected (:answer \"ΚΡΥΦΗ-ΑΠΑΝΤΗΣΗ-2\"))))~%"))
             (vp (wr "valid.sexp" valid-text))
             (vfp (%ebg-file-fingerprint vp)))
        ;; ① έγκυρο bundle + σωστό αποτύπωμα ⇒ :not-run (validation passed)
        (multiple-value-bind (v r i) (%ebg-validate vp vfp)
          (declare (ignore r))
          (chk "① έγκυρο bundle + σωστό αποτύπωμα ⇒ :not-run · counts ανά layer"
               (and (eq v :not-run) (= 2 (getf i :items-count)))))
        ;; ② tamper 1 χαρακτήρα ⇒ fingerprint_mismatch
        (let ((tp (wr "tampered.sexp"
                      (substitute #\5 #\1 valid-text :count 1 :from-end t))))
          (multiple-value-bind (v r) (%ebg-validate tp vfp)
            (chk "② tamper 1 byte ⇒ :invalid / fingerprint_mismatch"
                 (and (eq v :invalid) (eq r :fingerprint_mismatch)))))
        ;; ③ χωρίς αποτύπωμα ⇒ fingerprint_missing
        (multiple-value-bind (v r) (%ebg-validate vp nil)
          (chk "③ χωρίς αποτύπωμα ⇒ :invalid / fingerprint_missing"
               (and (eq v :invalid) (eq r :fingerprint_missing))))
        ;; ④ κακή μορφή αποτυπώματος ⇒ fingerprint_format
        (multiple-value-bind (v r) (%ebg-validate vp "md5:abc")
          (chk "④ μορφή ≠ sha256:<64hex> ⇒ :invalid / fingerprint_format"
               (and (eq v :invalid) (eq r :fingerprint_format))))
        ;; ⑤ σχήμα: χωρίς owner ⇒ schema_owner_missing
        (let* ((no-owner (wr "no-owner.sexp"
                             "(:external-benchmark-bundle 1 :as-of-date \"2026-07-07\" :items ((:id \"T\" :layer :provision :visible-prompt \"x\")))"))
               (fp (%ebg-file-fingerprint no-owner)))
          (multiple-value-bind (v r) (%ebg-validate no-owner fp)
            (chk "⑤ σχήμα χωρίς :owner ⇒ :invalid / schema_owner_missing"
                 (and (eq v :invalid) (eq r :schema_owner_missing)))))
        ;; ⑥ κενά items ⇒ schema_items_empty
        (let* ((empty (wr "empty.sexp"
                          "(:external-benchmark-bundle 1 :owner \"x\" :as-of-date \"2026-07-07\" :items ())"))
               (fp (%ebg-file-fingerprint empty)))
          (multiple-value-bind (v r) (%ebg-validate empty fp)
            (chk "⑥ κενά items ⇒ :invalid / schema_items_empty"
                 (and (eq v :invalid) (eq r :schema_items_empty)))))
        ;; ⑦ ΦΡΑΓΜΑ ΔΙΑΡΡΟΗΣ: η πλήρης αναφορά δεν περιέχει ΟΥΤΕ hidden ΟΥΤΕ visible κείμενο
        (let ((out (with-output-to-string (*standard-output*)
                     (multiple-value-bind (v r i) (%ebg-validate vp vfp)
                       (%ebg-report v r i :dry-run)))))
          (chk "⑦ no-leak: η αναφορά ΔΕΝ περιέχει hidden-expected ούτε visible-prompt κείμενο"
               (and (not (search "ΚΡΥΦΗ-ΑΠΑΝΤΗΣΗ" out))
                    (not (search "ΟΡΑΤΟ-ΔΟΚΙΜΙΟ" out)))))
        ;; ⑧ ντετερμινισμός: δεύτερη επικύρωση ⇒ ίδια ετυμηγορία + αποτύπωμα
        (multiple-value-bind (v1 r1 i1) (%ebg-validate vp vfp)
          (declare (ignore r1))
          (multiple-value-bind (v2 r2 i2) (%ebg-validate vp vfp)
            (declare (ignore r2))
            (chk "⑧ ντετερμινισμός: δύο επικυρώσεις ⇒ ίδιο verdict + fingerprint"
                 (and (eq v1 v2)
                      (equal (getf i1 :fingerprint) (getf i2 :fingerprint)))))))
      (format t "~%── ΠΥΛΗ ΕΞΩΤΕΡΙΚΟΥ BENCHMARK: ~D/~D αυτο-έλεγχοι πέρασαν · verdict: :not-run (κανένα bundle δεν προσκομίστηκε) ──~%"
              (- total (length fails)) total)
      (if fails 1 0))))

(defun run-external-benchmark-gate (args)
  "--external-benchmark-gate [--bundle <path> [--fingerprint sha256:…] [--mode dry-run]]
   Χωρίς bundle: αυτο-έλεγχος επικυρωτή + verdict :not-run (τίμια απουσία).
   Με bundle: dry-run επικύρωση σχήματος/αποτυπώματος — ΠΟΤΕ εκτέλεση items."
  (flet ((argval (key)
           (let ((pos (position key args :test #'string=)))
             (and pos (nth (1+ pos) args)))))
    (let ((bundle (argval "--bundle"))
          (fp (argval "--fingerprint"))
          (mode (or (argval "--mode") "dry-run")))
      (cond
        ((null bundle) (%ebg-selftest))
        ((not (string= mode "dry-run"))
         (%ebg-report :not-run :mode_not_implemented
                      (list :requested-mode mode
                            :note "v0 = ΜΟΝΟ dry-run· measured/blocked απαιτούν νέα έγκριση δημιουργού")
                      mode)
         1)
        (t
         ;; detached fingerprint: όρισμα ή sidecar <path>.sha256 (πρώτη γραμμή)
         (let ((fingerprint
                 (or fp
                     (let ((side (probe-file (concatenate 'string bundle ".sha256"))))
                       (and side (string-trim " \t\r\n"
                                              (or (first (uiop:read-file-lines side)) "")))))))
           (multiple-value-bind (verdict reason info)
               (%ebg-validate bundle (and fingerprint
                                          (plusp (length fingerprint))
                                          fingerprint))
             (%ebg-report verdict reason info :dry-run)
             (if (eq verdict :invalid) 1 0))))))))

(register-command "--external-benchmark-gate"
  (lambda (a) (run-external-benchmark-gate a)))

(orchestrator.self-model:declare-capability! "εξωτερική-μαρτυρία"
 :description "CPEI L11 external attestation: dry-run επικύρωση hidden bundle (σχήμα+detached fingerprint+no-leak) — η εξωτερική μέτρηση του Κριτή· εκτέλεση items = μελλοντικό βήμα με έγκριση"
 :package :orchestrator.cli
 :functions '("run-external-benchmark-gate" "%ebg-validate")
 :gate "--external-benchmark-gate")

(orchestrator.contracts:defcontract "external-benchmark-dry-run" :protocol
 :package :orchestrator.cli :system "orchestrator-cli"
 :capability "εξωτερική-μαρτυρία" :role "έλεγχος"
 :purpose "dry-run επικύρωση hidden bundle: σχήμα (owner/as-of/items/layers) + detached sha256 αποτύπωμα· verdicts :not-run|:invalid — ΠΟΤΕ εκτέλεση/έκθεση hidden items"
 :inputs '("bundle path (εκτός repo)" "detached fingerprint (όρισμα ή sidecar .sha256)")
 :outputs '("verdict + reason + πλήθη ανά layer — κανένα περιεχόμενο item")
 :preconditions '("*read-eval* NIL στην ανάγνωση" "fingerprint = sha256 των bytes του αρχείου")
 :postconditions '("έγκυρο ⇒ :not-run (το benchmark ΔΕΝ έτρεξε — τίμιο)"
                   "tamper/σχήμα/απόν αποτύπωμα ⇒ :invalid με ρητό reason"
                   "η αναφορά δεν περιέχει ποτέ hidden-expected ή visible-prompt")
 :side-effects '("καμία — read-only· τα self-test bundles γράφονται σε temp εκτός repo")
 :legal-critical nil :policy-level :συμβουλευτικό
 :audit "self-test ⑦ no-leak + ⑧ ντετερμινισμός σε κάθε ολομέλεια"
 :rollback "αφαίρεση CLI εγγραφής/αρχείου — ιστορικά signed scorecards ΔΕΝ διαγράφονται ποτέ (spec 0004)"
 :tests '("--external-benchmark-gate"))
