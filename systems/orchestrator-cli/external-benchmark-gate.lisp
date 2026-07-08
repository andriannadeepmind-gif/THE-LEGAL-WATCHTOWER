;;;; systems/orchestrator-cli/external-benchmark-gate.lisp
;;;; ============================================================================
;;;; ΠΥΛΗ ΕΞΩΤΕΡΙΚΟΥ BENCHMARK — CPEI L11 external attestation · DRY-RUN HOOK
;;;; ============================================================================
;;;;
;;;; Το άγκιστρο που ζήτησε ο Κριτής Εξωτερικής Νοημοσύνης (0004) και ο νόμος
;;;; που το δένει: EXTERNAL-BENCHMARK-BUNDLE-SCHEMA-CONTRACT-v1-dry-run
;;;; (deployment/collab/dialogue/0009-kritis.md §2 + schema_duplicate_id από
;;;; το 0008) — και τα δύο με ρητό ΟΚ δημιουργού.
;;;;
;;;;   --external-benchmark-gate --bundle <path> [--fingerprint sha256:…]
;;;;                             [--mode dry-run]
;;;;
;;;; DRY-RUN ΜΟΝΟ: επικυρώνει σχήμα + αποτύπωμα του hidden bundle και
;;;; επιστρέφει :not-run ή :invalid. ΔΕΝ εκτελεί ΚΑΝΕΝΑ hidden item, ΔΕΝ
;;;; τυπώνει ΠΟΤΕ περιεχόμενο item (ούτε visible-prompt/scoring/citations) —
;;;; μόνο verdict/κλειστούς λόγους/πλήθη. Τα :measured/:blocked/:passed
;;;; παραμένουν ΠΑΡΑΝΟΜΑ σε αυτό το hook μέχρι νέα ρητή έγκριση (0009 §2.5).
;;;; Το αποτύπωμα είναι DETACHED (όρισμα ή sidecar <path>.sha256): hash των
;;;; bytes του αρχείου δεν μπορεί να αυτο-περιέχεται.
;;;;
;;;; Χωρίς --bundle (ολομέλεια): αυτο-έλεγχος του επικυρωτή με συνθετικά
;;;; bundles σε temp — αποδεικνύει tamper/schema/no-leak/ντετερμινισμό ΧΩΡΙΣ
;;;; πραγματικό hidden set.

(in-package :orchestrator.cli)

(defparameter +ebg-layers+ '(:currentness :provision :subsumption :dialectic)
  "Τα 4 στρώματα του CPEI-BENCHMARK-SPEC (Κριτής, 0004/0009).")

(defparameter +ebg-source-classes+
  '(:fek :kodikas :areios-pagos :syntagma :eu :other)
  "Κλειστό enum source-class (0009 §2.2).")

(defparameter +ebg-max-bundle-bytes+ (* 16 1024 1024)
  "Προαιρετικό size cap του 0009 §5.3 — φραγή DoS πριν από κάθε ανάγνωση.")

(defparameter +ebg-max-items+ 4096
  "Άνω φράγμα items ανά bundle — μαζί με το size cap, τα μόνα όρια όγκου.")

(defun %ebg-file-fingerprint (path)
  "Αποτύπωμα των bytes του bundle: sha256 του πλήρους κειμένου του αρχείου."
  (format nil "sha256:~A"
          (orchestrator.journal:sha256-hex (uiop:read-file-string path))))

(defparameter +ebg-readtable+
  (let ((rt (copy-readtable nil)))
    (flet ((deny (stream char arg)
             (declare (ignore stream char arg))
             (error "ebg: reader macro εκτός data-only υποσυνόλου")))
      ;; #=/## = κυκλικές δομές: θα έκαναν length/getf/διάσχιση να μην
      ;; τερματίζουν. Αποκλείονται στη ΡΙΖΑ του reader — η μη-κυκλικότητα
      ;; είναι εγγύηση ΕΚ ΚΑΤΑΣΚΕΥΗΣ, όχι έλεγχος με όριο. #S επίσης εκτός
      ;; (κατασκευή δομών ≠ data-only ανάγνωση).
      (set-dispatch-macro-character #\# #\= #'deny rt)
      (set-dispatch-macro-character #\# #\# #'deny rt)
      (set-dispatch-macro-character #\# #\S #'deny rt)
      (set-dispatch-macro-character #\# #\s #'deny rt))
    rt)
  "Data-only readtable του bundle: ό,τι δεν είναι απλό datum, αρνείται.")

(defun %ebg-read-data (path)
  "Data-only ανάγνωση: *read-eval* NIL (κανένα #.), +ebg-readtable+ (καμία
   κυκλική/κατασκευαστική σύνταξη), keyword package — ποτέ εκτέλεση."
  (with-open-file (s path :external-format :utf-8)
    (let ((*read-eval* nil)
          (*readtable* +ebg-readtable+)
          (*package* (find-package :keyword)))
      (read s nil nil))))

(defun %ebg-proper-list-length (l)
  "Μήκος proper list ή NIL για dotted/μη-λίστα. Τερματισμός ΕΓΓΥΗΜΕΝΟΣ:
   κυκλικές δομές είναι αδύνατες (+ebg-readtable+)."
  (loop for tail = l then (cdr tail)
        for n from 0
        do (cond ((null tail) (return n))
                 ((not (consp tail)) (return nil)))))

(defun %ebg-proper-plist-p (l)
  "Proper plist: proper list, ζυγό μήκος, keys keywords (0009 §1.2.2 —
   schema_plist, όχι σιωπηλό unreadable). Τερματισμός εγγυημένος ομοίως."
  (loop for tail = l then (cddr tail)
        do (cond ((null tail) (return t))
                 ((not (consp tail)) (return nil))
                 ((not (keywordp (car tail))) (return nil))
                 ((not (consp (cdr tail))) (return nil)))))

(defun %ebg-real-date-p (s)
  "Πραγματική ISO ημερομηνία Gregorian (0009 §1.2.3) — όχι μόνο regex:
   το 2026-99-99 απορρίπτεται, τα δίσεκτα υπολογίζονται."
  (and (stringp s)
       (cl-ppcre:register-groups-bind ((#'parse-integer y m d))
           ("^(\\d{4})-(\\d{2})-(\\d{2})$" s)
         (and (<= 1 m 12)
              (<= 1 d (let ((days #(31 28 31 30 31 30 31 31 30 31 30 31)))
                        (if (and (= m 2)
                                 (or (and (zerop (mod y 4)) (plusp (mod y 100)))
                                     (zerop (mod y 400))))
                            29
                            (aref days (1- m)))))))))

(defun %ebg-booleanish-p (v)
  "Δεκτό boolean πεδίου bundle: T/NIL — ΚΑΙ :T/:NIL, γιατί η data-only
   ανάγνωση γίνεται στο keyword package όπου το γυμνό «t» διαβάζεται ως :T."
  (member v '(t nil :t :nil)))

(defun %ebg-tree-contains (tree kw)
  "Υπάρχει το keyword KW οπουδήποτε στο δέντρο; ΕΠΑΝΑΛΗΠΤΙΚΑ με ρητή στοίβα
   — βαθιά φωλιασμένο bundle δεν μπορεί να εξαντλήσει το control stack
   (η αναδρομή θα σήμαινε storage-condition, που ΔΕΝ είναι error). Ανάγνωση
   ΜΟΝΟ — το δέντρο δεν τυπώνεται ποτέ."
  (loop with stack = (list tree)
        while stack
        for node = (pop stack)
        do (cond ((eq node kw) (return t))
                 ((consp node) (push (car node) stack)
                               (push (cdr node) stack)))
        finally (return nil)))

(defparameter +ebg-missing+ '#:missing
  "Δείκτης απουσίας για getf — τα required πεδία πρέπει να ΥΠΑΡΧΟΥΝ, το
   σκέτο nil δεν αρκεί για να τα διακρίνει.")

(defun %ebg-item-invalid (item seen-ids)
  "Ο λόγος ακυρότητας ενός item (κλειστός κωδικός) ή NIL — ΠΟΤΕ περιεχόμενο.
   SEEN-IDS: hash των ids που έχουν ήδη εμφανιστεί (schema_duplicate_id, 0008).
   Πλήρες validation floor του 0009 §2.2."
  (flet ((f (k) (getf item k +ebg-missing+)))
    (cond ((not (%ebg-proper-plist-p item)) :item_not_plist)
          ((not (and (stringp (f :id)) (plusp (length (f :id)))))
           :item_id_missing)
          ((gethash (f :id) seen-ids) :item_id_duplicate)
          ((not (member (f :layer) +ebg-layers+)) :item_layer_invalid)
          ((not (eq (f :jurisdiction) :gr)) :item_jurisdiction_invalid)
          ((not (member (f :source-class) +ebg-source-classes+))
           :item_source_class_invalid)
          ((not (and (stringp (f :visible-prompt))
                     (plusp (length (f :visible-prompt)))))
           :item_visible_prompt_missing)
          ((not (%ebg-real-date-p (f :as-of-date))) :item_as_of_date_invalid)
          ((not (%ebg-proper-list-length
                 (let ((c (f :required-citations)))
                   (if (eq c +ebg-missing+) '#:not-a-list c))))
           :item_required_citations_invalid)
          ;; κενές παραπομπές ΜΟΝΟ όταν το αναμενόμενο είναι τίμια άγνοια
          ;; (0009 §2.2) — το hidden-expected ΔΙΑΒΑΖΕΤΑΙ, δεν τυπώνεται ποτέ.
          ((and (null (f :required-citations))
                (not (or (%ebg-tree-contains (f :hidden-expected)
                                             :unknown-source-needed)
                         (%ebg-tree-contains (f :hidden-expected)
                                             :blocked-insufficient-provenance))))
           :item_required_citations_invalid)
          ((not (%ebg-booleanish-p (f :stale-law-decoy-p)))
           :item_stale_law_decoy_p_invalid)
          ((not (%ebg-proper-list-length
                 (let ((sc (f :scoring)))
                   (if (eq sc +ebg-missing+) '#:not-a-list sc))))
           :item_scoring_missing)
          ((eq (f :hidden-expected) +ebg-missing+) :item_hidden_expected_missing)
          (t (setf (gethash (f :id) seen-ids) t)
             nil))))

(defun %ebg-validate (bundle-path fingerprint)
  "Η ΜΙΑ επικύρωση dry-run κατά το SCHEMA-CONTRACT-v1-dry-run (0009 §2).
   (values verdict reason info): verdict :not-run (επικύρωση ΠΕΡΑΣΕ — το
   benchmark απλώς δεν έχει τρέξει) ή :invalid (κλειστός reason). Το info
   περιέχει ΜΟΝΟ αποτύπωμα/δημόσια metadata/πλήθη — ποτέ περιεχόμενο item."
  (block validate
    (handler-case
        (progn
          (unless (and bundle-path (probe-file bundle-path))
            (return-from validate (values :invalid :bundle_missing nil)))
          ;; size cap ΠΡΙΝ από κάθε ανάγνωση (0009 §5.3)
          (with-open-file (s bundle-path :element-type '(unsigned-byte 8))
            (when (> (file-length s) +ebg-max-bundle-bytes+)
              (return-from validate (values :invalid :bundle_too_large nil))))
          (unless fingerprint
            (return-from validate (values :invalid :fingerprint_missing nil)))
          (unless (cl-ppcre:scan "^sha256:[0-9a-f]{64}$" (string-downcase fingerprint))
            (return-from validate (values :invalid :fingerprint_format nil)))
          (let ((computed (%ebg-file-fingerprint bundle-path)))
            (unless (string= computed (string-downcase fingerprint))
              (return-from validate
                (values :invalid :fingerprint_mismatch (list :computed computed))))
            (let ((form (%ebg-read-data bundle-path)))
              (unless (and (consp form)
                           (eq (first form) :external-benchmark-bundle)
                           (consp (cdr form)))
                (return-from validate (values :invalid :schema_not_bundle nil)))
              ;; v1: η έκδοση είναι ΑΚΡΙΒΩΣ 1 (0009 §1.2.1)
              (unless (eql (second form) 1)
                (return-from validate (values :invalid :schema_version nil)))
              (let ((plist (cddr form)))
                ;; v1: ρητός proper-plist έλεγχος (0009 §1.2.2)
                (unless (%ebg-proper-plist-p plist)
                  (return-from validate (values :invalid :schema_plist nil)))
                (let ((owner (getf plist :owner))
                      (as-of (getf plist :as-of-date))
                      (jur (getf plist :jurisdiction))
                      (purpose (getf plist :bundle-purpose))
                      (items (getf plist :items)))
                  (unless (and (stringp owner) (plusp (length owner)))
                    (return-from validate (values :invalid :schema_owner_missing nil)))
                  (unless (%ebg-real-date-p as-of)
                    (return-from validate (values :invalid :schema_as_of_date nil)))
                  (unless (eq jur :gr)
                    (return-from validate (values :invalid :schema_jurisdiction nil)))
                  (unless (eq purpose :dry-run)
                    (return-from validate (values :invalid :schema_bundle_purpose nil)))
                  (let ((n-items (%ebg-proper-list-length items)))
                    (unless (and n-items (plusp n-items))
                      (return-from validate (values :invalid :schema_items_empty nil)))
                    (when (> n-items +ebg-max-items+)
                      (return-from validate (values :invalid :schema_items_too_many nil)))
                    (let* ((seen (make-hash-table :test 'equal))
                           (bad (loop for it in items
                                      for i from 0
                                      for why = (%ebg-item-invalid it seen)
                                      when why collect (list :item-index i :why why))))
                      (when bad
                        (return-from validate
                          (values :invalid :schema_item_invalid (list :bad-items bad))))
                      (values :not-run nil
                              (list :fingerprint computed
                                    :version (second form)
                                    :owner owner
                                    :as-of-date as-of
                                    :jurisdiction jur
                                    :bundle-purpose purpose
                                    :items-count n-items
                                    :per-layer
                                    (loop for l in +ebg-layers+
                                          collect (cons l (count l items
                                                                 :key (lambda (it)
                                                                        (getf it :layer))))))))))))))
      ;; SERIOUS-CONDITION, όχι σκέτο ERROR: και η εξάντληση στοίβας/χώρου
      ;; (storage-condition) από εχθρικό input καταλήγει σε κλειστό
      ;; :unreadable — ποτέ crash, ποτέ raw λεπτομέρεια που ηχεί περιεχόμενο.
      (serious-condition ()
        (values :invalid :unreadable nil)))))

(defun %ebg-report (verdict reason info mode)
  "Η αναφορά — μηχανικά αναγνώσιμη, ΧΩΡΙΣ κανένα περιεχόμενο item. Το MODE
   είναι πάντα κλειστό enum (:dry-run ή :unsupported) — ποτέ raw echo του
   ορίσματος χρήστη (0009 §1.2.5)."
  (format t "~%── ΠΥΛΗ ΕΞΩΤΕΡΙΚΟΥ BENCHMARK (CPEI L11 · external attestation) ──~%")
  (format t "mode: ~(~A~)~%" mode)
  (format t "verdict: ~(~S~)~%" verdict)
  (when reason (format t "reason: ~(~A~)~%" reason))
  (when info
    (loop for (k v) on info by #'cddr
          do (format t "~(~A~): ~A~%" (substitute #\_ #\- (string k)) v)))
  ;; «passed» ΜΟΝΟ όταν η επικύρωση πραγματικά έτρεξε και πέρασε (verdict
  ;; :not-run ΧΩΡΙΣ reason)· ένα :not-run λόγω π.χ. mode_not_implemented ΔΕΝ
  ;; επιτρέπεται να μοιάζει με πέρασμα επικύρωσης.
  (when (and (eq verdict :not-run) (null reason))
    (format t "dry_run_validation: passed~%")
    (format t "note: κανένα hidden item δεν εκτελέστηκε ούτε τυπώθηκε — μόνο σχήμα/αποτύπωμα/πλήθη~%")))

(defun %ebg-selftest ()
  "Αυτο-έλεγχος του επικυρωτή v1 με συνθετικά bundles (temp, εκτός repo):
   tamper, πλήρες schema floor, no-leak, ντετερμινισμός — 16 έλεγχοι."
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
      (macrolet ((expect (label file-text want-verdict want-reason)
                   `(let* ((p (wr (format nil "~D.sexp" total) ,file-text))
                           (fp (%ebg-file-fingerprint p)))
                      (multiple-value-bind (v r) (%ebg-validate p fp)
                        (chk ,label (and (eq v ,want-verdict)
                                         (or (null ,want-reason) (eq r ,want-reason))))))))
        (let* ((valid-text
                 "(:external-benchmark-bundle 1
 :owner \"kritis-selftest\"
 :as-of-date \"2026-07-07\"
 :jurisdiction :gr
 :bundle-purpose :dry-run
 :items ((:id \"T1\" :layer :currentness :jurisdiction :gr :source-class :fek
          :visible-prompt \"ΟΡΑΤΟ-ΔΟΚΙΜΙΟ-1\" :as-of-date \"2026-07-07\"
          :required-citations (\"synthetic-citation\") :stale-law-decoy-p t
          :scoring (:max 1) :hidden-expected (:answer \"ΚΡΥΦΗ-ΑΠΑΝΤΗΣΗ-1\"))
         (:id \"T2\" :layer :dialectic :jurisdiction :gr :source-class :areios-pagos
          :visible-prompt \"ΟΡΑΤΟ-ΔΟΚΙΜΙΟ-2\" :as-of-date \"2026-07-07\"
          :required-citations () :stale-law-decoy-p nil
          :scoring (:max 1)
          :hidden-expected (:verdict :unknown-source-needed :answer \"ΚΡΥΦΗ-ΑΠΑΝΤΗΣΗ-2\"))))")
               (vp (wr "valid.sexp" valid-text))
               (vfp (%ebg-file-fingerprint vp)))
          ;; ① έγκυρο v1 bundle ⇒ :not-run (και ο κανόνας «κενές παραπομπές
          ;;   μόνο με τίμια-άγνοια στο hidden-expected» περνά για το T2)
          (multiple-value-bind (v r i) (%ebg-validate vp vfp)
            (declare (ignore r))
            (chk "① έγκυρο v1 bundle ⇒ :not-run · counts · κενές citations OK μόνο με unknown-source-needed"
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
          ;; ⑦ ΦΡΑΓΜΑ ΔΙΑΡΡΟΗΣ σε ΟΛΗ την αναφορά
          (let ((out (with-output-to-string (*standard-output*)
                       (multiple-value-bind (v r i) (%ebg-validate vp vfp)
                         (%ebg-report v r i :dry-run)))))
            (chk "⑤ no-leak: η αναφορά ΔΕΝ περιέχει hidden/visible/scoring/citation κείμενο"
                 (and (not (search "ΚΡΥΦΗ-ΑΠΑΝΤΗΣΗ" out))
                      (not (search "ΟΡΑΤΟ-ΔΟΚΙΜΙΟ" out))
                      (not (search "synthetic-citation" out)))))
          ;; ⑧ ντετερμινισμός
          (multiple-value-bind (v1 r1 i1) (%ebg-validate vp vfp)
            (declare (ignore r1))
            (multiple-value-bind (v2 r2 i2) (%ebg-validate vp vfp)
              (declare (ignore r2))
              (chk "⑥ ντετερμινισμός: δύο επικυρώσεις ⇒ ίδιο verdict + fingerprint"
                   (and (eq v1 v2)
                        (equal (getf i1 :fingerprint) (getf i2 :fingerprint)))))))
        ;; ── v1 schema floor (0009 §2 + 0008 duplicate_id) ──
        (expect "⑦ version ≠ 1 ⇒ :invalid / schema_version"
                "(:external-benchmark-bundle 2 :owner \"x\" :as-of-date \"2026-07-07\" :jurisdiction :gr :bundle-purpose :dry-run :items ((:id \"A\")))"
                :invalid :schema_version)
        (expect "⑧ dotted/κακό plist ⇒ :invalid / schema_plist"
                "(:external-benchmark-bundle 1 :owner . \"x\")"
                :invalid :schema_plist)
        (expect "⑨ χωρίς :owner ⇒ :invalid / schema_owner_missing"
                "(:external-benchmark-bundle 1 :as-of-date \"2026-07-07\" :jurisdiction :gr :bundle-purpose :dry-run :items ((:id \"A\")))"
                :invalid :schema_owner_missing)
        (expect "⑩ ψεύτικη ημερομηνία 2026-99-99 ⇒ :invalid / schema_as_of_date"
                "(:external-benchmark-bundle 1 :owner \"x\" :as-of-date \"2026-99-99\" :jurisdiction :gr :bundle-purpose :dry-run :items ((:id \"A\")))"
                :invalid :schema_as_of_date)
        (expect "⑪ jurisdiction ≠ :gr ⇒ :invalid / schema_jurisdiction"
                "(:external-benchmark-bundle 1 :owner \"x\" :as-of-date \"2026-07-07\" :jurisdiction :us :bundle-purpose :dry-run :items ((:id \"A\")))"
                :invalid :schema_jurisdiction)
        (expect "⑫ bundle-purpose ≠ :dry-run ⇒ :invalid / schema_bundle_purpose"
                "(:external-benchmark-bundle 1 :owner \"x\" :as-of-date \"2026-07-07\" :jurisdiction :gr :bundle-purpose :evaluation :items ((:id \"A\")))"
                :invalid :schema_bundle_purpose)
        (expect "⑬ κενά items ⇒ :invalid / schema_items_empty"
                "(:external-benchmark-bundle 1 :owner \"x\" :as-of-date \"2026-07-07\" :jurisdiction :gr :bundle-purpose :dry-run :items ())"
                :invalid :schema_items_empty)
        ;; διπλότυπο id (0008): δύο πλήρη items με ίδιο :id
        (expect "⑭ διπλότυπο item :id ⇒ :invalid / schema_item_invalid (item_id_duplicate)"
                "(:external-benchmark-bundle 1 :owner \"x\" :as-of-date \"2026-07-07\" :jurisdiction :gr :bundle-purpose :dry-run
 :items ((:id \"DUP\" :layer :currentness :jurisdiction :gr :source-class :fek :visible-prompt \"a\" :as-of-date \"2026-07-07\" :required-citations (\"c\") :stale-law-decoy-p nil :scoring (:max 1) :hidden-expected (:x))
         (:id \"DUP\" :layer :dialectic :jurisdiction :gr :source-class :eu :visible-prompt \"b\" :as-of-date \"2026-07-07\" :required-citations (\"c\") :stale-law-decoy-p t :scoring (:max 1) :hidden-expected (:x))))"
                :invalid :schema_item_invalid)
        ;; item χωρίς scoring
        (expect "⑮ item χωρίς :scoring ⇒ :invalid / schema_item_invalid (item_scoring_missing)"
                "(:external-benchmark-bundle 1 :owner \"x\" :as-of-date \"2026-07-07\" :jurisdiction :gr :bundle-purpose :dry-run
 :items ((:id \"S\" :layer :provision :jurisdiction :gr :source-class :kodikas :visible-prompt \"a\" :as-of-date \"2026-07-07\" :required-citations (\"c\") :stale-law-decoy-p nil :hidden-expected (:x))))"
                :invalid :schema_item_invalid)
        ;; κενές citations ΧΩΡΙΣ τίμια-άγνοια στο hidden-expected
        (expect "⑯ κενές :required-citations χωρίς unknown-source-needed ⇒ :invalid (κανόνας 0009 §2.2)"
                "(:external-benchmark-bundle 1 :owner \"x\" :as-of-date \"2026-07-07\" :jurisdiction :gr :bundle-purpose :dry-run
 :items ((:id \"C\" :layer :currentness :jurisdiction :gr :source-class :fek :visible-prompt \"a\" :as-of-date \"2026-07-07\" :required-citations () :stale-law-decoy-p nil :scoring (:max 1) :hidden-expected (:answer \"y\"))))"
                :invalid :schema_item_invalid))
      (format t "~%── ΠΥΛΗ ΕΞΩΤΕΡΙΚΟΥ BENCHMARK: ~D/~D αυτο-έλεγχοι πέρασαν · verdict: :not-run (κανένα bundle δεν προσκομίστηκε) ──~%"
              (- total (length fails)) total)
      (if fails 1 0))))

(defun run-external-benchmark-gate (args)
  "--external-benchmark-gate [--bundle <path> [--fingerprint sha256:…] [--mode dry-run]]
   Χωρίς bundle: αυτο-έλεγχος επικυρωτή + verdict :not-run (τίμια απουσία).
   Με bundle: dry-run επικύρωση κατά το SCHEMA-CONTRACT-v1-dry-run — ΠΟΤΕ
   εκτέλεση items."
  (flet ((argval (key)
           (let ((pos (position key args :test #'string=)))
             (and pos (nth (1+ pos) args)))))
    (let ((bundle (argval "--bundle"))
          (fp (argval "--fingerprint"))
          (mode (or (argval "--mode") "dry-run")))
      (cond
        ((null bundle) (%ebg-selftest))
        ((not (string= mode "dry-run"))
         ;; ΚΛΕΙΣΤΟ enum στην έξοδο — ποτέ raw echo του user-controlled
         ;; --mode (0009 §1.2.5: operator self-leak φράσσεται μηχανικά).
         (%ebg-report :not-run :mode_not_implemented
                      (list :requested-mode :unsupported
                            :note "v1 = ΜΟΝΟ dry-run· measured/blocked/passed απαιτούν νέα έγκριση δημιουργού")
                      :unsupported)
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
 :description "CPEI L11 external attestation: dry-run επικύρωση hidden bundle κατά το SCHEMA-CONTRACT-v1-dry-run (0009 §2) — σχήμα+detached fingerprint+no-leak· εκτέλεση items = μελλοντικό βήμα με έγκριση"
 :package :orchestrator.cli
 :functions '("run-external-benchmark-gate" "%ebg-validate")
 :gate "--external-benchmark-gate")

(orchestrator.contracts:defcontract "external-benchmark-dry-run" :protocol
 :package :orchestrator.cli :system "orchestrator-cli"
 :capability "εξωτερική-μαρτυρία" :role "έλεγχος"
 :purpose "dry-run επικύρωση hidden bundle κατά το v1-dry-run contract (0009 §2 + schema_duplicate_id): strict version=1, proper plist, πραγματικό calendar date, jurisdiction :gr, bundle-purpose :dry-run, πλήρες item floor· verdicts :not-run|:invalid — ΠΟΤΕ εκτέλεση/έκθεση hidden items"
 :inputs '("bundle path (εκτός repo)" "detached fingerprint (όρισμα ή sidecar .sha256)")
 :outputs '("verdict + κλειστός reason + δημόσια metadata + πλήθη ανά layer — κανένα περιεχόμενο item, κανένα raw echo χρήστη")
 :preconditions '("*read-eval* NIL στην ανάγνωση" "fingerprint = sha256 των bytes του αρχείου" "size caps πριν από κάθε ανάγνωση")
 :postconditions '("έγκυρο ⇒ :not-run (το benchmark ΔΕΝ έτρεξε — τίμιο)"
                   "tamper/σχήμα/απόν αποτύπωμα ⇒ :invalid με κλειστό reason"
                   "η αναφορά δεν περιέχει ποτέ hidden-expected/visible-prompt/scoring/citations"
                   ":measured/:blocked/:passed παράνομα μέχρι νέα ρητή έγκριση")
 :side-effects '("καμία — read-only· τα self-test bundles γράφονται σε temp εκτός repo")
 :legal-critical nil :policy-level :συμβουλευτικό
 :audit "self-test no-leak + ντετερμινισμός + πλήρες v1 schema floor σε κάθε ολομέλεια (16 έλεγχοι)"
 :rollback "αφαίρεση CLI εγγραφής/αρχείου — ιστορικά signed scorecards ΔΕΝ διαγράφονται ποτέ (spec 0004)"
 :tests '("--external-benchmark-gate"))
