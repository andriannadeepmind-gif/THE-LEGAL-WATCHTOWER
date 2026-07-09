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

(defparameter +ebg-fingerprint-law+ "bytes-v2"
  "FF2 §2.1: το αποτύπωμα υπολογίζεται πάνω στα RAW BYTES του αρχείου —
   ΠΟΤΕ μέσω UTF-8 string normalization ή Lisp string path. Δηλώνεται ρητά
   στην αναφορά ώστε κανένα legacy-string hash να μη συγχέεται με bytes-v2.")

(defun %ebg-file-fingerprint (path)
  "bytes-v2 (FF2 §2.1): sha256 πάνω στα RAW BYTES του αρχείου μέσω
   ironclad:digest-file — καμία UTF-8 αποκωδικοποίηση. Δύο ίδια byte streams
   ⇒ ίδιο hash· αλλαγή 1 byte ⇒ διαφορετικό· ίδιο Unicode κείμενο με
   ΔΙΑΦΟΡΕΤΙΚΑ bytes (π.χ. NFC vs NFD) ⇒ ΔΙΑΦΟΡΕΤΙΚΟ hash (string-norm trap)."
  (format nil "sha256:~A"
          (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path))))

(defparameter +ebg-sidecar-max-chars+ 512
  "Άνω φράγμα ανάγνωσης του detached sidecar <bundle>.sha256: ένα fingerprint
   είναι ~71 chars (sha256:<64hex>). Bounded read ΠΡΙΝ από κάθε validation ώστε
   κακόβουλο πολυ-gigabyte sidecar να μη φορτώνεται ΠΟΤΕ — ίδιο πνεύμα με το
   +ebg-max-bundle-bytes+ size cap (0009 §5.3, 'size caps πριν από κάθε ανάγνωση').")

(defun %ebg-read-sidecar-fingerprint (bundle-path)
  "Detached fingerprint από sidecar: η ΠΡΩΤΗ γραμμή του <bundle>.sha256,
   ΦΡΑΓΜΕΝΗ σε +ebg-sidecar-max-chars+ και ΧΕΙΡΙΣΜΕΝΗ (serious-condition ⇒ NIL,
   ποτέ crash/leak). ΠΟΤΕ unbounded slurp: read-sequence σε buffer σταθερού
   μήκους — ό,τι ξεπερνά το φράγμα δεν διαβάζεται. Επιστρέφει trimmed string ή
   NIL (δεν υπάρχει/δεν διαβάζεται). Ο έλεγχος μορφής sha256:<64hex> γίνεται
   κατάντη στο %ebg-validate — εδώ μόνο η ΦΡΑΓΜΕΝΗ, ασφαλής ανάγνωση."
  (let ((side (probe-file (concatenate 'string (namestring bundle-path) ".sha256"))))
    (when side
      (handler-case
          (with-open-file (s side :external-format :utf-8)
            (let* ((buf (make-string +ebg-sidecar-max-chars+))
                   (n (read-sequence buf s))
                   (chunk (subseq buf 0 n))
                   (nl (position #\Newline chunk))
                   (line (if nl (subseq chunk 0 nl) chunk)))
              (string-trim '(#\Space #\Tab #\Return #\Newline) line)))
        ;; serious-condition, όχι σκέτο error: και storage/χώρου εξάντληση από
        ;; εχθρικό sidecar καταλήγει σε κλειστό NIL — κατάντη fingerprint_missing.
        (serious-condition () nil)))))

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
  "Data-only ανάγνωση + ONE-FORM EOF LAW (FF2 §2.2). Επιστρέφει (values form
   status) όπου status ∈ {:ok :empty :trailing}:
     • διαβάζει ΑΚΡΙΒΩΣ ένα top-level form (data-only: *read-eval* NIL,
       +ebg-readtable+, keyword package — ποτέ εκτέλεση)·
     • ΔΕΥΤΕΡΟ read πρέπει να είναι EOF ⇒ :ok· αλλιώς :trailing.
   Ο reader παραλείπει σχόλια/whitespace, άρα «comment-trick που κρύβει δεύτερη
   φόρμα» ΠΙΑΝΕΤΑΙ (το δεύτερο read επιστρέφει τη φόρμα, όχι EOF)."
  (with-open-file (s path :external-format :utf-8)
    (let ((*read-eval* nil)
          (*readtable* +ebg-readtable+)
          (*package* (find-package :keyword))
          (eof '#:eof))
      (let ((form (read s nil eof)))
        (if (eq form eof)
            (values nil :empty)
            (if (eq (read s nil eof) eof)
                (values form :ok)
                (values form :trailing)))))))

(defun %ebg-classify-condition (c)
  "RESOURCE-CONDITION POLICY (FF2 §2.5): διακρίνει καθαρά πόρους από
   αναγνωσιμότητα. storage-condition (εξάντληση μνήμης/στοίβας/χώρου) ⇒
   :resource_exhausted· κάθε άλλη serious-condition ⇒ :unreadable.
   Σε μελλοντικό measured: resource event ⇒ ΑΚΥΡΟ run, ποτέ μερικό scorecard."
  (if (typep c 'storage-condition) :resource_exhausted :unreadable))

(defun %ebg-canon-bool (v)
  "BOOLEAN CANONICALIZATION (FF2 §2.3): ΑΜΕΣΩΣ μετά το read. Επιστρέφει
   (values canonical valid-p): :T/T→T· :NIL/NIL→NIL (και τα δύο valid)·
   ΟΤΙΔΗΠΟΤΕ ΑΛΛΟ ⇒ (values NIL NIL). ΚΡΙΣΙΜΟ: το :NIL είναι truthy σύμβολο
   στο keyword package — downstream ΔΕΝ επιτρέπεται να αποφασίζει boolean από
   symbol truthiness· χρησιμοποιεί ΜΟΝΟ την canonical τιμή."
  (cond ((member v '(t :t)) (values t t))
        ((member v '(nil :nil)) (values nil t))
        (t (values nil nil))))

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
       (= 10 (length s))  ; \A…\z + μήκος: το "2026-07-07\n" ΔΕΝ είναι ημερομηνία
       (cl-ppcre:register-groups-bind ((#'parse-integer y m d))
           ("\\A(\\d{4})-(\\d{2})-(\\d{2})\\z" s)
         (and (<= 1 m 12)
              (<= 1 d (let ((days #(31 28 31 30 31 30 31 31 30 31 30 31)))
                        (if (and (= m 2)
                                 (or (and (zerop (mod y 4)) (plusp (mod y 100)))
                                     (zerop (mod y 400))))
                            29
                            (aref days (1- m)))))))))

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
          ((gethash (f :id) seen-ids) :schema_duplicate_id)
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
          ;; κενές παραπομπές ΜΟΝΟ όταν το ΑΝΑΜΕΝΟΜΕΝΟ VERDICT του item είναι
          ;; τίμια άγνοια (0009 §2.2 κατά γράμμα): το hidden-expected πρέπει να
          ;; είναι plist με :verdict ∈ {unknown-source-needed, blocked-…} —
          ;; marker θαμμένο αλλού στο δέντρο (π.χ. σε distractors) ΔΕΝ αρκεί.
          ;; Το hidden-expected ΔΙΑΒΑΖΕΤΑΙ, δεν τυπώνεται ποτέ.
          ((and (null (f :required-citations))
                (not (let ((he (f :hidden-expected)))
                       (and (%ebg-proper-plist-p he)
                            (member (getf he :verdict)
                                    '(:unknown-source-needed
                                      :blocked-insufficient-provenance))))))
           :item_required_citations_invalid)
          ;; boolean canonicalization (FF2 §2.3): valid-p ΜΟΝΟ αν :T/:NIL/T/NIL·
          ;; το :NIL ΔΕΝ περνά ως truthy — ελέγχεται η valid-p, όχι η truthiness.
          ((not (nth-value 1 (%ebg-canon-bool (f :stale-law-decoy-p))))
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
          (unless (cl-ppcre:scan "\\Asha256:[0-9a-f]{64}\\z" (string-downcase fingerprint))
            (return-from validate (values :invalid :fingerprint_format nil)))
          (let ((computed (%ebg-file-fingerprint bundle-path)))
            (unless (string= computed (string-downcase fingerprint))
              (return-from validate
                (values :invalid :fingerprint_mismatch (list :computed computed))))
            (multiple-value-bind (form rstatus) (%ebg-read-data bundle-path)
              ;; one-form EOF law (FF2 §2.2): κενό ⇒ not-bundle· trailing ⇒
              ;; ρητό schema_trailing_data (ποτέ σιωπηλή αποδοχή δεύτερης φόρμας).
              (when (eq rstatus :empty)
                (return-from validate (values :invalid :schema_not_bundle nil)))
              (when (eq rstatus :trailing)
                (return-from validate (values :invalid :schema_trailing_data nil)))
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
      ;; RESOURCE-CONDITION POLICY (FF2 §2.5): κάθε serious-condition πιάνεται
      ;; χωρίς crash/leak, αλλά ΔΙΑΚΡΙΝΕΤΑΙ: storage-condition (πόροι) ⇒
      ;; :resource_exhausted· οτιδήποτε άλλο ⇒ :unreadable. Ποτέ raw λεπτομέρεια.
      (serious-condition (c)
        (values :invalid (%ebg-classify-condition c) nil)))))

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
    (format t "fingerprint_law: ~A~%" +ebg-fingerprint-law+)
    (format t "dry_run_validation: passed~%")
    (format t "note: κανένα hidden item δεν εκτελέστηκε ούτε τυπώθηκε — μόνο σχήμα/αποτύπωμα/πλήθη~%")))

(defun %ebg-selftest ()
  "Αυτο-έλεγχος του επικυρωτή v1 με συνθετικά bundles (temp, εκτός repo):
   tamper, schema floor, no-leak, ντετερμινισμός + FF2 measured-preflight (bytes-v2, EOF law, boolean canon, resource policy, exact item-why, invalid-UTF-8) — 26 έλεγχοι."
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
               p))
           (wrb (name bytes)
             ;; ΩΜΑ BYTES — παρακάμπτει κάθε external-format ώστε να γραφτούν
             ;; ΜΗ-έγκυρα UTF-8 fixtures (απόδειξη bytes-v2 σε non-text input).
             (let ((p (merge-pathnames name dir)))
               (with-open-file (o p :direction :output :if-exists :supersede
                                    :element-type '(unsigned-byte 8))
                 (write-sequence bytes o))
               p)))
      (macrolet ((expect (label file-text want-verdict want-reason)
                   `(let* ((p (wr (format nil "~D.sexp" total) ,file-text))
                           (fp (%ebg-file-fingerprint p)))
                      (multiple-value-bind (v r) (%ebg-validate p fp)
                        (chk ,label (and (eq v ,want-verdict)
                                         (or (null ,want-reason) (eq r ,want-reason)))))))
                 ;; exact bad-reason ΠΛΗΡΕΣ (FF2 §2.4, εύρημα [0025]): για item-level
                 ;; ακυρότητες δεν αρκεί το top-level :schema_item_invalid — απαιτεί
                 ;; ΤΑΥΤΟΧΡΟΝΑ verdict=:invalid, reason=:schema_item_invalid ΚΑΙ το
                 ;; :why του ΠΡΩΤΟΥ κακού item = want-item-why (eq). Αλλαγή του
                 ;; εσωτερικού why-code ⇒ κόκκινο.
                 (expect-item-why (label file-text want-item-why)
                   `(let* ((p (wr (format nil "~D.sexp" total) ,file-text))
                           (fp (%ebg-file-fingerprint p)))
                      (multiple-value-bind (v r i) (%ebg-validate p fp)
                        (let ((first-why (getf (first (getf i :bad-items)) :why)))
                          (chk ,label (and (eq v :invalid)
                                           (eq r :schema_item_invalid)
                                           (eq first-why ,want-item-why))))))))
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
        ;; διπλότυπο id (0008): δύο πλήρη items με ίδιο :id — exact item :why
        (expect-item-why "⑭ διπλότυπο item :id ⇒ :schema_item_invalid · item :why=:schema_duplicate_id (0008)"
                "(:external-benchmark-bundle 1 :owner \"x\" :as-of-date \"2026-07-07\" :jurisdiction :gr :bundle-purpose :dry-run
 :items ((:id \"DUP\" :layer :currentness :jurisdiction :gr :source-class :fek :visible-prompt \"a\" :as-of-date \"2026-07-07\" :required-citations (\"c\") :stale-law-decoy-p nil :scoring (:max 1) :hidden-expected (:x))
         (:id \"DUP\" :layer :dialectic :jurisdiction :gr :source-class :eu :visible-prompt \"b\" :as-of-date \"2026-07-07\" :required-citations (\"c\") :stale-law-decoy-p t :scoring (:max 1) :hidden-expected (:x))))"
                :schema_duplicate_id)
        ;; item χωρίς scoring — exact item :why
        (expect-item-why "⑮ item χωρίς :scoring ⇒ :schema_item_invalid · item :why=:item_scoring_missing"
                "(:external-benchmark-bundle 1 :owner \"x\" :as-of-date \"2026-07-07\" :jurisdiction :gr :bundle-purpose :dry-run
 :items ((:id \"S\" :layer :provision :jurisdiction :gr :source-class :kodikas :visible-prompt \"a\" :as-of-date \"2026-07-07\" :required-citations (\"c\") :stale-law-decoy-p nil :hidden-expected (:x))))"
                :item_scoring_missing)
        ;; κενές citations ΧΩΡΙΣ τίμια-άγνοια στο hidden-expected — exact item :why
        (expect-item-why "⑯ κενές :required-citations χωρίς unknown-source-needed ⇒ item :why=:item_required_citations_invalid (0009 §2.2)"
                "(:external-benchmark-bundle 1 :owner \"x\" :as-of-date \"2026-07-07\" :jurisdiction :gr :bundle-purpose :dry-run
 :items ((:id \"C\" :layer :currentness :jurisdiction :gr :source-class :fek :visible-prompt \"a\" :as-of-date \"2026-07-07\" :required-citations () :stale-law-decoy-p nil :scoring (:max 1) :hidden-expected (:answer \"y\"))))"
                :item_required_citations_invalid)
        ;; marker ΘΑΜΜΕΝΟ σε distractors ≠ expected verdict — exact item :why (εύρημα σκεπτικιστή)
        (expect-item-why "⑰ κενές citations με marker ΜΟΝΟ σε distractors (όχι :verdict) ⇒ item :why=:item_required_citations_invalid"
                "(:external-benchmark-bundle 1 :owner \"x\" :as-of-date \"2026-07-07\" :jurisdiction :gr :bundle-purpose :dry-run
 :items ((:id \"D\" :layer :currentness :jurisdiction :gr :source-class :fek :visible-prompt \"a\" :as-of-date \"2026-07-07\" :required-citations () :stale-law-decoy-p nil :scoring (:max 1) :hidden-expected (:verdict :provision-found :distractors (:unknown-source-needed)))))"
                :item_required_citations_invalid)
        ;; trailing newline σε ημερομηνία = ΟΧΙ ημερομηνία (εύρημα σκεπτικιστή: το $ της
        ;; cl-ppcre δεχόταν τελικό \n και ο control χαρακτήρας ηχούσε στην αναφορά)
        (expect "⑱ :as-of-date με trailing newline ⇒ :invalid / schema_as_of_date"
                (format nil "(:external-benchmark-bundle 1 :owner \"x\" :as-of-date \"2026-07-07~C\" :jurisdiction :gr :bundle-purpose :dry-run :items ((:id \"N\")))" #\Newline)
                :invalid :schema_as_of_date)
        ;; ══ FF2 measured-preflight ×5 (acceptance gates B-G του [0023]) ══
        ;; ⑲ (B) raw-byte fingerprint: ίδια bytes ⇒ ίδιο hash· 1 byte ⇒ διαφορετικό
        (let* ((a (wr "fp-a.bin" "byte-stream-XYZ"))
               (b (wr "fp-b.bin" "byte-stream-XYZ"))
               (c (wr "fp-c.bin" "byte-stream-XYZ!")))
          (chk "⑲ (B) bytes-v2: ίδια byte streams ⇒ ίδιο hash· αλλαγή 1 byte ⇒ διαφορετικό"
               (and (string= (%ebg-file-fingerprint a) (%ebg-file-fingerprint b))
                    (not (string= (%ebg-file-fingerprint a) (%ebg-file-fingerprint c))))))
        ;; ⑳ (C) string-normalization trap: ίδιο Unicode κείμενο (é), ΔΙΑΦΟΡΕΤΙΚΑ bytes
        ;;     (NFC U+00E9 vs NFD e+U+0301) ⇒ ΔΙΑΦΟΡΕΤΙΚΟ hash (δεν εξισώνει)
        (let* ((nfc (wr "nfc.bin" (string (code-char #x00E9))))
               (nfd (wr "nfd.bin" (coerce (list (code-char #x65) (code-char #x0301)) 'string))))
          (chk "⑳ (C) string-norm trap: ίδιο render (é), διαφορετικά bytes ⇒ ΔΙΑΦΟΡΕΤΙΚΟ hash"
               (not (string= (%ebg-file-fingerprint nfc) (%ebg-file-fingerprint nfd)))))
        ;; ㉑ (D) one-form EOF law: έγκυρο bundle + trailing δεύτερη φόρμα ⇒ schema_trailing_data
        (expect "㉑ (D) trailing δεύτερη top-level φόρμα ⇒ :invalid / schema_trailing_data"
                "(:external-benchmark-bundle 1 :owner \"x\" :as-of-date \"2026-07-07\" :jurisdiction :gr :bundle-purpose :dry-run :items ((:id \"A\")))
(:sneaky-second-form 42)"
                :invalid :schema_trailing_data)
        ;; ㉒ (D′) comment-trick που κρύβει δεύτερη φόρμα ⇒ ΠΙΑΝΕΤΑΙ (ο reader παραλείπει σχόλιο)
        (expect "㉒ (D′) block comment ΠΡΙΝ από κρυφή δεύτερη φόρμα ⇒ schema_trailing_data"
                "(:external-benchmark-bundle 1 :owner \"x\" :as-of-date \"2026-07-07\" :jurisdiction :gr :bundle-purpose :dry-run :items ((:id \"A\")))
#| αθώο σχόλιο |# (:hidden 1)"
                :invalid :schema_trailing_data)
        ;; ㉓ (E) boolean canonicalization: :NIL ΔΕΝ περνά ως truthy· :maybe άκυρο
        (chk "㉓ (E) boolean canon: :NIL→NIL (όχι truthy)· :T→T· :maybe→invalid"
             (and (null (nth-value 0 (%ebg-canon-bool :nil)))    ; :NIL → NIL (falsy!)
                  (nth-value 1 (%ebg-canon-bool :nil))            ; valid
                  (eq t (nth-value 0 (%ebg-canon-bool :t)))       ; :T → T
                  (not (nth-value 1 (%ebg-canon-bool :maybe)))))  ; :maybe → invalid
        ;; ㉔ (E′) bundle item με μη-boolean stale-law-decoy-p ⇒ exact item :why
        (expect-item-why "㉔ (E′) item :stale-law-decoy-p :maybe (μη-boolean) ⇒ item :why=:item_stale_law_decoy_p_invalid"
                "(:external-benchmark-bundle 1 :owner \"x\" :as-of-date \"2026-07-07\" :jurisdiction :gr :bundle-purpose :dry-run
 :items ((:id \"B\" :layer :provision :jurisdiction :gr :source-class :kodikas :visible-prompt \"a\" :as-of-date \"2026-07-07\" :required-citations (\"c\") :stale-law-decoy-p :maybe :scoring (:max 1) :hidden-expected (:x))))"
                :item_stale_law_decoy_p_invalid)
        ;; ㉕ (G) resource-condition policy: storage-condition ξεχωρίζει από unreadable
        (chk "㉕ (G) resource policy: storage-condition→:resource_exhausted, error→:unreadable (διακριτά)"
             (and (eq :resource_exhausted
                      (%ebg-classify-condition (make-condition 'storage-condition)))
                  (eq :unreadable
                      (%ebg-classify-condition (make-condition 'simple-error)))
                  (not (eq :resource_exhausted :unreadable))))
        ;; ㉖ (C′) ΜΗ-έγκυρα UTF-8 bytes ([0025] note #2): bytes-v2 fingerprint
        ;;     λειτουργεί σε input που ΔΕΝ αποκωδικοποιείται ως UTF-8 — απόδειξη
        ;;     ότι το digest-file δουλεύει στα ΩΜΑ bytes (string-slurp θα έριχνε
        ;;     decoding error). Ίδια bytes ⇒ ίδιο· 1 byte ⇒ διαφορετικό.
        (let* ((raw (coerce '(#xFF #xFE #x00 #x80 #xC3 #x28 #xA0 #xA1)
                            '(vector (unsigned-byte 8))))
               (raw2 (coerce '(#xFF #xFE #x00 #x80 #xC3 #x28 #xA0 #xA1)
                             '(vector (unsigned-byte 8))))
               (raw3 (coerce '(#xFF #xFE #x00 #x80 #xC3 #x29 #xA0 #xA1)
                             '(vector (unsigned-byte 8))))
               (ba (wrb "bad-utf8-a.bin" raw))
               (bb (wrb "bad-utf8-b.bin" raw2))
               (bc (wrb "bad-utf8-c.bin" raw3)))
          (chk "㉖ (C′) invalid-UTF-8 bytes: bytes-v2 δουλεύει σε non-text· ίδια bytes ⇒ ίδιο· 1 byte ⇒ διαφορετικό"
               (and (string= (%ebg-file-fingerprint ba) (%ebg-file-fingerprint bb))
                    (not (string= (%ebg-file-fingerprint ba) (%ebg-file-fingerprint bc)))))))
      ;; (F) exact bad-reason ΠΛΗΡΕΣ: κάθε bundle-level negative μέσω `expect`
      ;;     (eq στο reason) ΚΑΙ κάθε item-level negative μέσω `expect-item-why`
      ;;     (eq στο ΕΣΩΤΕΡΙΚΟ item :why) — «απέτυχε άρα καλά» αδύνατο σε ΚΑΘΕ επίπεδο.
      (format t "~%── ΠΥΛΗ ΕΞΩΤΕΡΙΚΟΥ BENCHMARK: ~D/~D αυτο-έλεγχοι πέρασαν · verdict: :not-run (κανένα bundle δεν προσκομίστηκε) · fingerprint_law: bytes-v2 ──~%"
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
         ;; detached fingerprint: όρισμα ή sidecar <path>.sha256 (πρώτη γραμμή,
         ;; ΦΡΑΓΜΕΝΗ+ΧΕΙΡΙΣΜΕΝΗ ανάγνωση — %ebg-read-sidecar-fingerprint).
         (let ((fingerprint (or fp (%ebg-read-sidecar-fingerprint bundle))))
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
