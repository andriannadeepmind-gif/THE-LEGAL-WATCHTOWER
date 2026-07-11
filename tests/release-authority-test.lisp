;;;; tests/release-authority-test.lisp
;;;; ============================================================================
;;;; P1R [0046]: CONTENT-ADDRESSED RELEASE AUTHORITY — regression lock.
;;;;   · ταυτότητα release = Merkle root ⇒ overwrite ΔΟΜΙΚΑ αδύνατο
;;;;   · χρόνος output-bound ΜΟΝΟ από δηλωμένη αρχή (ποτέ σιωπηλό ρολόι)
;;;;   · latest προάγεται ΜΟΝΟ σε attested commitment
;;;;   · ο καθαρισμός output ΔΕΝ αγγίζει ΠΟΤΕ το releases/
;;;; Τρέχει κάτω από docker/run-standalone-test.lisp (self-exit 0/1). Offline.

(in-package :orchestrator.cli)

(defvar *rat-pass* 0)
(defvar *rat-fail* 0)

(defmacro rat-check (name form)
  `(handler-case
       (if ,form
           (progn (incf *rat-pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *rat-fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e)
       (incf *rat-fail*)
       (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

(format t "~%── P1R RELEASE AUTHORITY: content-addressed αμεταβλητότητα ──~%")

;;; ① Timestamp authority: χωρίς deterministic mode ⇒ ΣΦΑΛΜΑ, ποτέ ρολόι
(let ((orchestrator.time:*deterministic-mode* nil))
  (rat-check "① require-deterministic-time ΧΩΡΙΣ αρχή ⇒ σφάλμα (όχι σιωπηλό ρολόι)"
             (handler-case (progn (orchestrator.time:require-deterministic-time) nil)
               (error () t))))
(progn
  (orchestrator.time:configure-deterministic-time :enabled t :fixed-time "2026-07-09T00:00:00Z")
  (rat-check "①β με δηλωμένη αρχή ⇒ σταθερή τιμή"
             (integerp (orchestrator.time:require-deterministic-time))))

;;; ② Κανονική ταυτότητα από root
(rat-check "② %root->release-id: ΜΟΝΟ κανονική μορφή «sha256:<64-hex>»· άλλη μορφή ⇒ σφάλμα"
           (and (equal (concatenate 'string "sha256-" (make-string 64 :initial-element #\a))
                       (orchestrator.epistemic::%root->release-id
                        (concatenate 'string "sha256:" (make-string 64 :initial-element #\a))))
                (handler-case (progn (orchestrator.epistemic::%root->release-id "γυμνό-hex") nil)
                  (error () t))))

;;; Βοηθός: φτιάξε staging με ΟΛΑ τα canonical + δηλωμένο root (πραγματικές έδρες)
(defun %rat-make-staging (base tag)
  (let* ((staging (merge-pathnames (format nil "releases/.staging-~A/" tag) base)))
    (ensure-directories-exist (merge-pathnames "shapes/" staging))
    (ensure-directories-exist (merge-pathnames "verify/" staging))
    (ensure-directories-exist (merge-pathnames "temporal-proof/" staging))
    (dolist (f orchestrator.epistemic::+epistemic-canonical-files+)
      (with-open-file (o (merge-pathnames f staging) :direction :output
                         :if-exists :supersede :external-format :utf-8)
        (format o "~A περιεχόμενο ~A~%" f tag)))
    (let* ((root (orchestrator.epistemic::merkle-tree-root
                  (orchestrator.epistemic::build-merkle-tree
                   (orchestrator.epistemic::collect-epistemic-artifacts staging)))))
      (with-open-file (o (merge-pathnames "temporal-proof/merkle-tree.json" staging)
                         :direction :output :if-exists :supersede)
        (format o "{\"root\":~S,\"totalFiles\":~D}~%" root (length orchestrator.epistemic::+epistemic-canonical-files+)))
      (values staging root (orchestrator.epistemic::%root->release-id root)))))

(let ((base (uiop:ensure-directory-pathname
             (merge-pathnames (format nil "rat-~D/" (get-universal-time))
                              (uiop:temporary-directory)))))
  (ensure-directories-exist base)

  ;; ③ Πρώτο publish: ο κατάλογος παίρνει το όνομα του ΠΕΡΙΕΧΟΜΕΝΟΥ του
  (multiple-value-bind (staging root id) (%rat-make-staging base "a1")
    (declare (ignore root))
    (let ((final (orchestrator.epistemic::atomic-publish-release base staging id)))
      (rat-check "③ publish: κατάλογος = ταυτότητα περιεχομένου (sha256-…)"
                 (and (probe-file final)
                      (equal id (car (last (pathname-directory final))))))
      ;; ④ Ιδεμποτές: ΞΑΝΑ ίδιο περιεχόμενο ⇒ επαναχρησιμοποίηση, ΠΟΤΕ delete
      (let ((mtime (file-write-date (merge-pathnames "meta-ontology.ttl" final))))
        (multiple-value-bind (staging2 root2 id2) (%rat-make-staging base "a1")
          (declare (ignore root2))
          (let ((final2 (orchestrator.epistemic::atomic-publish-release base staging2 id2)))
            (rat-check "④ ίδιο περιεχόμενο ⇒ ίδια ταυτότητα, υπάρχον ΔΕΝ ξαναγράφτηκε"
                       (and (equal id id2)
                            (equal (namestring final) (namestring final2))
                            (= mtime (file-write-date (merge-pathnames "meta-ontology.ttl" final2)))
                            (not (probe-file staging2)))))))
      ;; ⑤ Ξένο περιεχόμενο κάτω από την ΙΔΙΑ ταυτότητα ⇒ ΣΦΑΛΜΑ (διαφθορά)
      (multiple-value-bind (staging3 root3 id3) (%rat-make-staging base "b2")
        (declare (ignore root3 id3))
        (rat-check "⑤ υπάρχων κατάλογος με ΞΕΝΟ root ⇒ validation-error (όχι σιωπηλή αντικατάσταση)"
                   (handler-case
                       (progn (orchestrator.epistemic::atomic-publish-release base staging3 id) nil)
                     (orchestrator.spec:validation-error () t)
                     (error () nil))))
      ;; ⑥ Διαφορετικό περιεχόμενο ⇒ ΑΛΛΟΣ κατάλογος, το ιστορικό άθικτο
      (multiple-value-bind (staging4 root4 id4) (%rat-make-staging base "b2")
        (declare (ignore root4))
        (let ((final4 (orchestrator.epistemic::atomic-publish-release base staging4 id4)))
          (rat-check "⑥ νέο περιεχόμενο ⇒ νέος κατάλογος, ο παλιός ΑΘΙΚΤΟΣ (append-only)"
                     (and (probe-file final4) (not (equal id id4)) (probe-file final)))))
      ;; ⑦ promote-latest!: unattested ⇒ ΣΦΑΛΜΑ· attested ⇒ symlink+signed pointer
      (rat-check "⑦ latest σε UNATTESTED ⇒ αρνείται (η εξουσία θέλει χρονική απόδειξη)"
                 (handler-case
                     (progn (orchestrator.epistemic::promote-latest! base id) nil)
                   (orchestrator.spec:validation-error () t)
                   (error () nil)))
      ;; Το receipt πρέπει να ΔΕΝΕΙ το root: γράφουμε tsr που περιέχει το
      ;; messageImprint (SHA-256 του recomputed root string) — όπως ένα γνήσιο.
      (let* ((root (orchestrator.epistemic::%release-recomputed-root final))
             (imprint (ironclad:digest-sequence
                       :sha256 (babel:string-to-octets root :encoding :utf-8))))
        (with-open-file (o (merge-pathnames "temporal-proof/timestamp.tsr" final)
                           :direction :output :if-exists :supersede
                           :element-type '(unsigned-byte 8))
          (write-sequence imprint o)))
      (rat-check "⑦β attested ⇒ receipt δεμένο στο recomputed root"
                 (orchestrator.epistemic::release-attested-p
                  final (orchestrator.epistemic::%release-recomputed-root final)))
      (rat-check "⑦β2 receipt με ΞΕΝΟ imprint ⇒ ΔΕΝ μετρά ως attested για αυτό το root"
                 (not (orchestrator.epistemic::release-attested-p
                       final (concatenate 'string "sha256:" (make-string 64 :initial-element #\d)))))
      (orchestrator.epistemic::promote-latest! base id)
      (rat-check "⑦γ latest symlink + latest.json δείχνουν στην ταυτότητα, attested:true"
                 (let ((ptr (uiop:read-file-string
                             (merge-pathnames "releases/latest.json" base))))
                   (and (probe-file (merge-pathnames "releases/latest" base))
                        (search id ptr)
                        (search "\"attested\":true" ptr))))))

  ;; ⑧ Ο καθαρισμός output ΔΕΝ αγγίζει το releases/
  (with-open-file (o (merge-pathnames "junk.txt" base) :direction :output
                     :if-exists :supersede)
    (write-string "junk" o))
  (orchestrator.cli::clean-corpus-output-dir base)
  (rat-check "⑧ clean-corpus-output-dir: junk ΦΕΥΓΕΙ, releases/ ΜΕΝΕΙ (append-only δημοσίευση)"
             (and (not (probe-file (merge-pathnames "junk.txt" base)))
                  (probe-file (merge-pathnames "releases/latest.json" base))))
  (ignore-errors (uiop:delete-directory-tree base :validate (constantly t))))

(format t "~%========================================~%")
(format t "Release authority tests: ~D passed, ~D failed~%" *rat-pass* *rat-fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *rat-fail*) 0 1))
