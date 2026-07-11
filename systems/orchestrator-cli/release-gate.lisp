;;;; systems/orchestrator-cli/release-gate.lisp
;;;; ============================================================================
;;;; ΠΥΛΗ ΑΜΕΤΑΒΛΗΤΩΝ ΕΚΔΟΣΕΩΝ: --release-gate — P1R [0046]
;;;; ============================================================================
;;;; Για ΚΑΘΕ δημοσιευμένο release κάτω από output/<corpus>/releases/:
;;;;   · content-addressed (sha256-*): recomputed Merkle root των 10 canonical
;;;;     ≡ όνομα καταλόγου ≡ δηλωμένο root στο merkle-tree.json
;;;;   · legacy (timestamp-named, π.χ. 2025-01-01…): recomputed root ≡ δηλωμένο
;;;;     root — το ιστορικό ΔΕΝ ξαναγράφεται, μόνο επαληθεύεται
;;;;   · latest: δείχνει σε υπαρκτό release· αν είναι content-addressed, πρέπει
;;;;     να είναι ATTESTED (temporal-proof/timestamp.tsr παρόν)
;;;; Read-only πύλη — δεν γράφει ΤΙΠΟΤΑ.

(in-package :orchestrator.cli)

(defun %rg-verify-release (dir chk)
  (let* ((leaf (car (last (pathname-directory dir))))
         (fp (find-package :orchestrator.epistemic))
         (err nil)
         (declared (handler-case (funcall (find-symbol "%RELEASE-DIR-ROOT" fp) dir)
                     (error (e) (setf err e) nil)))
         (recomputed (handler-case
                         (funcall (find-symbol "%RELEASE-RECOMPUTED-ROOT" fp) dir)
                       (error (e) (setf err e) nil))))
    (funcall chk (format nil "~A: recomputed root ≡ δηλωμένο" leaf)
             (and declared recomputed (equal declared recomputed))
             (format nil "δηλωμένο=~A recomputed=~A~@[ (σφάλμα: ~A)~]" declared recomputed err))
    (when (and (stringp leaf) (eql 0 (search "sha256-" leaf)))
      (funcall chk (format nil "~A: όνομα ≡ περιεχόμενο (content-addressed)" leaf)
               (and recomputed
                    (equal leaf (funcall (find-symbol "%ROOT->RELEASE-ID" fp) recomputed)))
               recomputed)
      ;; [P1.5-D] gate v2: ΠΛΗΡΗΣ spine (census membership + text-σπονδυλική +
      ;; αλυσίδα + JWS πάνω στο recomputed root) — όχι μόνο root recompute.
      (multiple-value-bind (ok failures)
          (handler-case
              (funcall (find-symbol "VERIFY-RELEASE-SPINE" fp) dir :root recomputed)
            (error (e) (values nil (list (princ-to-string e)))))
        (funcall chk (format nil "~A: spine (census+αλυσίδα+JWS)" leaf)
                 ok (and failures (format nil "~{~A~^ · ~}" failures)))))))

(defun run-release-gate ()
  "--release-gate : καμία δημοσιευμένη έκδοση χωρίς επαληθεύσιμη αμεταβλητότητα."
  (let ((total 0) (fails '())
        (output-root (uiop:ensure-directory-pathname
                      (or (uiop:getenv "ORCHESTRATOR_OUTPUT_DIR")
                          (orchestrator.paths:institution-dir "output/")))))
    (flet ((chk (label ok &optional detail)
             (incf total)
             (if ok (format t "  ✓ ~A~%" label)
                 (progn (push label fails)
                        (format t "  ✗ ~A~@[~%      → ~A~]~%" label detail)))))
      (format t "~%── ΠΥΛΗ ΑΜΕΤΑΒΛΗΤΩΝ ΕΚΔΟΣΕΩΝ (content-addressed, read-only) ──~%")
      (let ((found 0))
        ;; I/O σφάλμα σε read-only audit = ΑΠΟΤΥΧΙΑ πύλης, ποτέ σιωπηλό πράσινο
        (dolist (corpus-dir (handler-case (uiop:subdirectories output-root)
                              (error (e)
                                (chk "ανάγνωση output root" nil (princ-to-string e))
                                nil)))
          (let ((releases-dir (merge-pathnames "releases/" corpus-dir)))
            (when (probe-file releases-dir)
              (dolist (rel (uiop:subdirectories releases-dir))
                (let ((leaf (car (last (pathname-directory rel)))))
                  (unless (or (not (stringp leaf))
                              (eql 0 (search ".staging" leaf))
                              (equal leaf "latest")) ; το symlink ελέγχεται χωριστά ως δείκτης
                    (incf found)
                    (%rg-verify-release rel #'chk))))
              ;; latest: υπαρκτός στόχος· content-addressed στόχος ⇒ attested
              (let ((latest (merge-pathnames "latest" releases-dir)))
                (when (probe-file latest)
                  (let* ((target (probe-file latest))
                         (tleaf (and target (car (last (pathname-directory
                                                        (uiop:ensure-directory-pathname target))))))
                         (corpus (car (last (pathname-directory corpus-dir)))))
                    (chk (format nil "~A: latest → υπαρκτό release (~A)" corpus tleaf)
                         (and target tleaf))
                    (when (and (stringp tleaf) (eql 0 (search "sha256-" tleaf)))
                      (chk (format nil "~A: latest είναι ATTESTED (receipt δεμένο στο recomputed root)" corpus)
                           (funcall (find-symbol "RELEASE-ATTESTED-P"
                                                 (find-package :orchestrator.epistemic))
                                    target
                                    (handler-case
                                        (funcall (find-symbol "%RELEASE-RECOMPUTED-ROOT"
                                                              (find-package :orchestrator.epistemic))
                                                 target)
                                      (error () nil)))
                           "content-addressed latest χωρίς δεμένο timestamp.tsr")
                      ;; Ο υπογεγραμμένος δείκτης ΕΛΕΓΧΕΤΑΙ, δεν διακοσμεί:
                      ;; latest.json.release ≡ στόχος symlink + attested:true
                      (let ((ptr (merge-pathnames "latest.json" releases-dir)))
                        (chk (format nil "~A: latest.json ≡ symlink στόχος + attested" corpus)
                             (handler-case
                                 (let ((d (jonathan:parse (uiop:read-file-string ptr))))
                                   (and (equal (getf d :|release|) tleaf)
                                        (eq (getf d :|attested|) t)))
                               (error () nil))
                             "latest.json απόν/ασύμφωνο με τον στόχο του symlink")))))))))
        (chk (format nil "σαρώθηκαν ~D δημοσιευμένα releases (≥1 απαιτείται όταν υπάρχει output)" found)
             (or (plusp found)
                 (null (probe-file output-root)))))
      (format t "~%── ΠΥΛΗ ΑΜΕΤΑΒΛΗΤΩΝ ΕΚΔΟΣΕΩΝ: ~D/~D πέρασαν ──~%"
              (- total (length fails)) total)
      (if fails 1 0))))

(register-command "--release-gate"
  (lambda (a) (declare (ignore a)) (run-release-gate)))

(orchestrator.self-model:declare-capability! "περιφρούρηση-εκδόσεων"
 :description "read-only πύλη ολομέλειας: κάθε δημοσιευμένο release (content-addressed ή legacy) έχει recomputed Merkle root ταυτόσημο με το δηλωμένο· content-addressed ⇒ όνομα ≡ περιεχόμενο· latest ⇒ υπαρκτό και (για content-addressed) attested"
 :package :orchestrator.cli
 :functions '("run-release-gate" "%rg-verify-release")
 :gate "--release-gate"
 :depends-on '("εξουσία-εκδόσεων"))

(orchestrator.contracts:defcontract "release-immutability-guard" :protocol
 :package :orchestrator.cli :system "orchestrator-cli"
 :capability "περιφρούρηση-εκδόσεων" :role "έλεγχος"
 :purpose "drift ή αλλοίωση σε ΟΠΟΙΟΔΗΠΟΤΕ δημοσιευμένο release (και στα ιστορικά legacy) κοκκινίζει την ολομέλεια — η αμεταβλητότητα επαληθεύεται, δεν υποτίθεται"
 :inputs '("output/*/releases/** (committed δημοσιεύσεις)")
 :outputs '("ετυμηγορία ανά release + ονομαστική απόκλιση")
 :preconditions '("η ταυτότητα content-addressed release ορίζεται από %root->release-id")
 :postconditions '("η πύλη δεν έγραψε τίποτα — read-only")
 :side-effects '("καμία")
 :legal-critical t :policy-level :φραγή
 :audit "ανά release: δηλωμένο root, recomputed root, όνομα, attestation state"
 :rollback "revert του commit εισαγωγής"
 :tests '("--release-gate"))
