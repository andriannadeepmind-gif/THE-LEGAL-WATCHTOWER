;;;; tests/artifact-census-test.lisp
;;;; Artifact Census (census-1) — το 9ο canonical αρχείο δένει per-article
;;;; artifacts + text-σπονδυλική + prev-root + materials στο release root.

(in-package :orchestrator.epistemic)

(defvar *p* 0) (defvar *f* 0)
(defmacro ck (name form)
  `(handler-case (if ,form (progn (incf *p*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *f*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *f*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

;; Synthetic corpus: 3 άρθρα με per-article artifacts (identity order 1 < 2 < 2Α).
(defun mk-art (label)
  (let ((num (parse-integer label :junk-allowed t)))  ; leading digits ("2Α"→2)
    (orchestrator.model:make-article
     :number num
     :label label
     :title (format nil "Άρθρο ~A" label)
     :content (format nil "Κείμενο άρθρου ~A." label))))

(defun write-artifacts (dir art)
  (let ((fid (orchestrator.model:article-file-id art)))
    (dolist (ext '("ttl" "jsonld" "html" "txt"))
      (alexandria:write-string-into-file
       (format nil "~A-content-of-~A" ext (orchestrator.model:article-uri-id art))
       (merge-pathnames (format nil "article-~A.~A" fid ext)
                        (uiop:ensure-directory-pathname dir))
       :if-exists :supersede))))

(let* ((base (uiop:ensure-directory-pathname
              (merge-pathnames "census-test/" (uiop:temporary-directory))))
       (arts (list (mk-art "1") (mk-art "2Α") (mk-art "2"))))
  (ensure-directories-exist base)
  (dolist (a arts) (write-artifacts base a))

  (format t "~%== build-artifact-census ==~%")
  (let ((c (build-artifact-census arts "test-corpus" base
                                  :prev-release-root "sha256:aa"
                                  :materials (list :git-commit "abc" :deps-lock "sha256:dd"
                                                   :sbcl-version "9.9" :base-image nil))))
    (ck "version = census-1" (string= (getf c :version) "census-1"))
    (ck "count = 3" (= 3 (getf c :count)))
    (ck "pcl_text_root είναι sha256:" (eql 0 (search "sha256:" (getf c :pcl-text-root))))
    (ck "άρθρα σε identity order (1, 2, 2Α)"
        (equal '("1" "2" "2Α")
               (mapcar (lambda (r) (getf r :id)) (getf c :articles))))
    (ck "κάθε άρθρο έχει ttl/jsonld/html sha512 + text_leaf"
        (every (lambda (r) (and (eql 0 (search "sha512:" (getf r :ttl)))
                                (eql 0 (search "sha512:" (getf r :jsonld)))
                                (eql 0 (search "sha512:" (getf r :html)))
                                (eql 0 (search "sha256:" (getf r :text-leaf)))))
               (getf c :articles)))

    (format t "~%== pcl_text_root = MTH των text leaves (identity order) ==~%")
    (let* ((ordered (orchestrator.model:articles-in-identity-order arts))
           (leaves (mapcar (lambda (a)
                             (orchestrator.merkle:hash-leaf-file
                              (merge-pathnames
                               (format nil "article-~A.txt"
                                       (orchestrator.model:article-file-id a))
                               base)))
                           ordered)))
      (ck "pcl_text_root ≡ merkle-tree-hash(text leaves)"
          (string= (getf c :pcl-text-root)
                   (orchestrator.merkle:merkle-tree-hash leaves))))

    (format t "~%== per-article hash ≡ πραγματικά bytes ==~%")
    (let* ((a1 (first (orchestrator.model:articles-in-identity-order arts)))
           (fid (orchestrator.model:article-file-id a1))
           (row (first (getf c :articles)))
           (ttl-path (merge-pathnames (format nil "article-~A.ttl" fid) base)))
      (ck "row.ttl ≡ sha512 των πραγματικών ttl bytes"
          (string= (getf row :ttl) (%sha512-file-prefixed ttl-path))))

    (format t "~%== JSON determinism + schema ==~%")
    (let ((j1 (census->json c)) (j2 (census->json c)))
      (ck "census->json ντετερμινιστικό" (string= j1 j2))
      (ck "JSON έχει merkle κανόνα rfc6962-split" (search "rfc6962-split" j1))
      (ck "JSON έχει pcl_text_root" (search "pcl_text_root" j1))
      (ck "JSON έχει prev_release_root=sha256:aa" (search "\"prev_release_root\":\"sha256:aa\"" j1))
      (ck "JSON materials.base_image=null (τίμιο)" (search "\"base_image\":null" j1))
      (ck "JSON count=3" (search "\"count\":3" j1)))

    (format t "~%== negative: λείπον artifact ⇒ ΣΦΑΛΜΑ ==~%")
    (let ((base2 (uiop:ensure-directory-pathname
                  (merge-pathnames "census-test-missing/" (uiop:temporary-directory)))))
      (ensure-directories-exist base2)
      (write-artifacts base2 (first arts))  ; μόνο ενός άρθρου
      (ck "λείπον per-article artifact ⇒ error"
          (handler-case (progn (build-artifact-census arts "x" base2) nil)
            (error () t))))))

(format t "~%== %prev-release-root: JSON parser, fail-closed (εύρημα κριτή #4) ==~%")
(let ((rd (uiop:ensure-directory-pathname
           (merge-pathnames "census-prev-root-test/" (uiop:temporary-directory)))))
  (ensure-directories-exist rd)
  (ck "χωρίς latest.json ⇒ NIL (τίμιο πρώτο της αλυσίδας)"
      (null (%prev-release-root rd)))
  (alexandria:write-string-into-file
   (format nil "{\"release\":\"sha256-~A\",\"attested\":true}" (make-string 64 :initial-element #\b))
   (merge-pathnames "latest.json" rd) :if-exists :supersede)
  (ck "έγκυρο latest.json ⇒ sha256:<hex> μέσω JSON parser"
      (string= (%prev-release-root rd)
               (format nil "sha256:~A" (make-string 64 :initial-element #\b))))
  (alexandria:write-string-into-file
   "{\"releaze\":\"τίποτα\"}" (merge-pathnames "latest.json" rd) :if-exists :supersede)
  (ck "latest.json ΧΩΡΙΣ έγκυρο release ⇒ ΣΦΑΛΜΑ (όχι σιωπηλό NIL)"
      (handler-case (progn (%prev-release-root rd) nil) (error () t)))
  (alexandria:write-string-into-file
   "οχι JSON" (merge-pathnames "latest.json" rd) :if-exists :supersede)
  (ck "άκυρο JSON ⇒ ΣΦΑΛΜΑ"
      (handler-case (progn (%prev-release-root rd) nil) (error () t))))

(format t "~%========================================~%")
(format t "Artifact census tests: ~D passed, ~D failed~%" *p* *f*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *f*) 0 1))
