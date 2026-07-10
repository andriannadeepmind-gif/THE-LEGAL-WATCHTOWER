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

(defparameter +census-version+ "census-1")

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

(defun build-artifact-census (articles corpus-short-name output-dir
                              &key prev-release-root materials)
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
                                    (uiop:ensure-directory-pathname output-dir))))
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
    (list :version +census-version+
          :corpus corpus-short-name
          :count (length rows)
          :pcl-text-root pcl-root
          :prev-release-root prev-release-root
          :materials materials
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
      (let* ((s (uiop:read-file-string lj))
             (k "\"release\":\"sha256-")
             (p (search k s)))
        (when p
          (let* ((start (+ p (length k)))
                 (end (position #\" s :start start)))
            (when (and end (= 64 (- end start)))
              (format nil "sha256:~A" (subseq s start end)))))))))

(defun write-artifact-census (articles corpus-short-name output-dir staging-dir
                              releases-dir)
  "Γράφει το census.json στο STAGING-DIR (πριν το Merkle build ⇒ γίνεται το 9ο
   canonical φύλλο). Επιστρέφει το census plist."
  (let ((census (build-artifact-census
                 articles corpus-short-name output-dir
                 :prev-release-root (%prev-release-root releases-dir)
                 :materials (%census-materials))))
    (alexandria:write-string-into-file
     (census->json census)
     (merge-pathnames "census.json" (uiop:ensure-directory-pathname staging-dir))
     :if-exists :supersede)
    census))
