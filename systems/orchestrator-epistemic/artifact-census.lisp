;;;; systems/orchestrator-epistemic/artifact-census.lisp
;;;; ============================================================================
;;;; ARTIFACT CENSUS — το 9ο κανονικό αρχείο του release (P1.5, census-1)
;;;; ============================================================================
;;;;
;;;; Σχήμα: LAWMAX-PROOF-OBJECT-SPEC §2. Το census δένει ΚΑΘΕ per-article
;;;; artifact (ttl/jsonld/html/txt) + την text-σπονδυλική (pcl_text_root) +
;;;; το prev_release_root (anti-equivocation αλυσίδα) + materials provenance
;;;; μέσα στο canonical σύνολο ⇒ το release root (ταυτότητα) τα δεσμεύει ΟΛΑ.
;;;;
;;;; Ντετερμινισμός: άρθρα σε identity order (η ΜΙΑ έδρα article-identity<)·
;;;; σταθερή σειρά κλειδιών JSON· κανένα ρολόι/τυχαιότητα. Τίμια άγνοια:
;;;; πεδίο που δεν είναι γνωστό ⇒ null, ΠΟΤΕ επινοημένη τιμή.
;;;; ============================================================================

(in-package :orchestrator.epistemic)

(defparameter +census-version+ "census-2")

(defparameter +per-article-formats+ '("ttl" "jsonld" "html" "txt" "hash")
  "Οι μορφές per-article που κάνουν το release SELF-CONTAINED: αντιγράφονται
   στο release/articles/ ώστε ΤΡΙΤΟΣ να επαληθεύει το census από ΤΑ ΙΔΙΑ bytes
   που διανέμονται (χωρίς πρόσβαση στο base output).")

(defun stage-per-article-artifacts (articles base-output-dir staging-dir)
  "Αντιγράφει article-<file-id>.<fmt> από το BASE-OUTPUT-DIR στο
   STAGING-DIR/articles/ για ΚΑΘΕ άρθρο (identity order δεν χρειάζεται εδώ —
   ονόματα αρχείων). Έτσι το release είναι αυτοτελές proof object. Λείπον
   υποχρεωτικό artifact (ttl/jsonld/html/txt) ⇒ ΣΦΑΛΜΑ (κανένα σιωπηλό κενό)·
   το .hash είναι προαιρετικό (codification sidecar). Επιστρέφει το πλήθος."
  (let ((adir (merge-pathnames "articles/" (uiop:ensure-directory-pathname staging-dir)))
        (n 0))
    (ensure-directories-exist adir)
    (dolist (a articles n)
      (let ((fid (orchestrator.model:article-file-id a)))
        (dolist (fmt +per-article-formats+)
          (let ((src (merge-pathnames (format nil "article-~A.~A" fid fmt)
                                      (uiop:ensure-directory-pathname base-output-dir))))
            (cond
              ((probe-file src)
               (uiop:copy-file src (merge-pathnames (format nil "article-~A.~A" fid fmt) adir))
               (when (string= fmt "txt") (incf n)))
              ((string= fmt "hash") nil)          ; προαιρετικό
              (t (error "self-contained release: λείπει per-article artifact ~A" src)))))))))

(defun %sha512-file-prefixed (path)
  "«sha512:<hex>» των ωμών bytes του αρχείου (per-article artifact digest)."
  (format nil "sha512:~A"
          (ironclad:byte-array-to-hex-string
           (ironclad:digest-sequence
            :sha512 (alexandria:read-file-into-byte-vector path)))))

(defun %json-escape (s)
  (with-output-to-string (o)
    (loop for c across s
          do (case c
               (#\" (write-string "\\\"" o))
               (#\\ (write-string "\\\\" o))
               (#\Newline (write-string "\\n" o))
               (#\Return (write-string "\\r" o))
               (#\Tab (write-string "\\t" o))
               (t (write-char c o))))))

(defun %jstr (s) (if s (format nil "\"~A\"" (%json-escape s)) "null"))

(defun build-artifact-census (articles corpus-short-name articles-dir
                              &key prev-release-root materials temporal-commitment)
  "Κατασκευή του census plist από τα ΑΡΘΡΑ (identity order μέσω της έδρας) και
   τα ΠΡΑΓΜΑΤΙΚΑ per-article artifacts στο OUTPUT-DIR (article-<file-id>.{ttl,
   jsonld,html,txt}). text_leaf = RFC-6962 φύλλο των ωμών bytes του .txt
   artifact (τα ΙΔΙΑ bytes που διανέμονται)· pcl_text_root = MTH όλων των
   text_leafs σε identity order. Αρχείο που λείπει ⇒ ΣΦΑΛΜΑ (κανένα σιωπηλό
   κενό σε id-δεσμευτικό αρχείο). PREV-RELEASE-ROOT: «sha256:<hex>» ή NIL.
   MATERIALS: plist (:git-commit :deps-lock :sbcl-version :base-image), τιμές
   string ή NIL (τίμιο null)."
  (let* ((ordered (orchestrator.model:articles-in-identity-order articles))
         (rows
           (loop for a in ordered
                 for fid = (orchestrator.model:article-file-id a)
                 for uid = (orchestrator.model:article-uri-id
                            (orchestrator.model:article-number a)
                            (orchestrator.model:article-label a))
                 collect
                 (flet ((artifact (ext)
                          (let ((p (merge-pathnames
                                    (format nil "article-~A.~A" fid ext)
                                    (uiop:ensure-directory-pathname articles-dir))))
                            (unless (probe-file p)
                              (error "census: λείπει per-article artifact ~A" p))
                            p)))
                   (list :id uid
                         :ttl (%sha512-file-prefixed (artifact "ttl"))
                         :jsonld (%sha512-file-prefixed (artifact "jsonld"))
                         :html (%sha512-file-prefixed (artifact "html"))
                         :text-leaf (orchestrator.merkle:hash-leaf-file
                                     (artifact "txt"))))))
         (pcl-root (if rows
                       (orchestrator.merkle:merkle-tree-hash
                        (mapcar (lambda (r) (getf r :text-leaf)) rows))
                       (error "census: κενό σύνολο άρθρων"))))
    ;; [0088 Φ5/PCL-02] Το census-2 δεσμεύει ΚΑΙ τη διτεμπορική ιστορία:
    ;; χωρίς temporal commitment ΔΕΝ κόβεται census — fail-closed, όχι null.
    (unless (and temporal-commitment
                 (getf temporal-commitment :graph-root)
                 (getf temporal-commitment :receipt-set-root))
      (error "census: απόν/ελλιπές temporal commitment (graph_root + receipt_set_root) — το census-2 δεν κόβεται χωρίς δεσμευμένη διτεμπορική ιστορία"))
    (list :version +census-version+
          :corpus corpus-short-name
          :count (length rows)
          :pcl-text-root pcl-root
          :prev-release-root prev-release-root
          :materials materials
          :temporal-commitment temporal-commitment
          :articles rows)))

(defun census->json (census)
  "Ντετερμινιστικό JSON (σταθερή σειρά κλειδιών, LF, χωρίς pretty-όρους που
   αλλάζουν) — τα bytes αυτά μπαίνουν στο canonical σύνολο του release."
  (with-output-to-string (o)
    (format o "{~%\"version\":~A,~%\"corpus\":~A,~%\"count\":~D,~%"
            (%jstr (getf census :version))
            (%jstr (getf census :corpus))
            (getf census :count))
    (format o "\"merkle\":{\"leaf\":\"sha256/0x00\",\"node\":\"sha256/0x01\",\"odd\":\"rfc6962-split\"},~%")
    (format o "\"pcl_text_root\":~A,~%" (%jstr (getf census :pcl-text-root)))
    (format o "\"prev_release_root\":~A,~%" (%jstr (getf census :prev-release-root)))
    (let ((m (getf census :materials)))
      (format o "\"materials\":{\"git_commit\":~A,\"deps_lock\":~A,\"sbcl_version\":~A,\"base_image\":~A},~%"
              (%jstr (getf m :git-commit)) (%jstr (getf m :deps-lock))
              (%jstr (getf m :sbcl-version)) (%jstr (getf m :base-image))))
    (let ((tc (getf census :temporal-commitment)))
      (format o "\"temporal\":{\"body\":~A,\"graph_root\":~A,\"graph_records\":~D,\"receipt_set_root\":~A,\"receipt_count\":~D,\"valid_at\":~A,\"known_at\":~A},~%"
              (%jstr (getf tc :body)) (%jstr (getf tc :graph-root))
              (getf tc :graph-records) (%jstr (getf tc :receipt-set-root))
              (getf tc :receipt-count) (%jstr (getf tc :valid-at))
              (%jstr (getf tc :known-at))))
    (format o "\"articles\":[~%")
    (loop for (row . rest) on (getf census :articles)
          do (format o "{\"id\":~A,\"ttl\":~A,\"jsonld\":~A,\"html\":~A,\"text_leaf\":~A}~:[~;,~]~%"
                     (%jstr (getf row :id)) (%jstr (getf row :ttl))
                     (%jstr (getf row :jsonld)) (%jstr (getf row :html))
                     (%jstr (getf row :text-leaf)) rest))
    (format o "]~%}~%")))

(defun %census-materials ()
  "Materials provenance με ΤΙΜΙΑ άγνοια: env GIT_COMMIT (το docker build το
   περνά ως build-arg) ή null· sha256 του deps.lock (υπάρχει πάντα στο repo,
   null σε runtime-only image)· τρέχουσα SBCL· BASE_IMAGE_DIGEST env ή null."
  (let ((deps (orchestrator.paths:institution-dir "deps.lock")))
    (list :git-commit (let ((v (uiop:getenv "GIT_COMMIT")))
                        (and v (plusp (length v)) (not (string= v "dev")) v))
          :deps-lock (and (probe-file deps)
                          (format nil "sha256:~A"
                                  (ironclad:byte-array-to-hex-string
                                   (ironclad:digest-sequence
                                    :sha256 (alexandria:read-file-into-byte-vector deps)))))
          :sbcl-version (lisp-implementation-version)
          :base-image (let ((v (uiop:getenv "BASE_IMAGE_DIGEST")))
                        (and v (plusp (length v)) v)))))

(defun %prev-release-root (releases-dir)
  "Το prev_release_root της αλυσίδας: η ρίζα («sha256:<hex>») του ΤΡΕΧΟΝΤΟΣ
   attested latest (latest.json) πριν κοπεί το νέο — ή NIL για το πρώτο της
   αλυσίδας. Επιλογή (i) του [0059]Δ4: μόνο το προαγμένο/attested latest είναι
   δημόσια «τρέχουσα έκδοση», άρα μόνο αυτό αλυσοδένεται (τίμια, ελέγξιμη ρίζα)."
  (let ((lj (merge-pathnames "latest.json"
                             (uiop:ensure-directory-pathname releases-dir))))
    (when (probe-file lj)
      ;; ΠΡΑΓΜΑΤΙΚΟΣ JSON parser (εύρημα κριτή: όχι μοτίβα κειμένου). Υπάρχον
      ;; latest.json που ΔΕΝ δίνει έγκυρη ρίζα = ΣΦΑΛΜΑ, ποτέ σιωπηλό NIL —
      ;; αλλιώς σπασμένος δείκτης αλυσίδας μεταμφιέζεται σε «πρώτο release».
      (let* ((doc (handler-case (jonathan:parse (uiop:read-file-string lj) :as :hash-table)
                    (error (e) (error "census: μη αναγνώσιμο latest.json ~A: ~A" lj e))))
             (rel (gethash "release" doc)))
        (unless (and (stringp rel)
                     (= 71 (length rel))
                     (string= "sha256-" (subseq rel 0 7))
                     (every (lambda (c) (digit-char-p c 16)) (subseq rel 7)))
          (error "census: latest.json χωρίς έγκυρο πεδίο release (sha256-<64hex>): ~S" rel))
        (format nil "sha256:~A" (subseq rel 7))))))

(defun write-artifact-census (articles corpus-short-name base-output-dir staging-dir
                              releases-dir &key temporal-commitment)
  "SELF-CONTAINED release: (1) αντιγράφει τα per-article artifacts από το
   BASE-OUTPUT-DIR στο STAGING-DIR/articles/· (2) χτίζει το census ΔΙΑΒΑΖΟΝΤΑΣ
   τα IN-RELEASE αντίγραφα (ώστε το census να δείχνει αρχεία που ΥΠΑΡΧΟΥΝ στο
   release)· (3) γράφει το census.json στο STAGING-DIR (9ο canonical φύλλο, πριν
   το Merkle build). Επιστρέφει το census plist."
  (stage-per-article-artifacts articles base-output-dir staging-dir)
  (let ((census (build-artifact-census
                 articles corpus-short-name
                 (merge-pathnames "articles/" (uiop:ensure-directory-pathname staging-dir))
                 :prev-release-root (%prev-release-root releases-dir)
                 :materials (%census-materials)
                 :temporal-commitment temporal-commitment)))
    (alexandria:write-string-into-file
     (census->json census)
     (merge-pathnames "census.json" (uiop:ensure-directory-pathname staging-dir))
     :if-exists :supersede)
    census))
