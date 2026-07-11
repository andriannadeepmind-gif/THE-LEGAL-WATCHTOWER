;;;; systems/orchestrator-cli/release-gate.lisp
;;;; ============================================================================
;;;; ΠΥΛΗ ΑΜΕΤΑΒΛΗΤΩΝ ΕΚΔΟΣΕΩΝ: --release-gate — P1R [0046]
;;;; ============================================================================
;;;; Για ΚΑΘΕ δημοσιευμένο release κάτω από output/<corpus>/releases/:
;;;;
;;;; ΔΥΟ ΕΠΟΧΕΣ, ΡΗΤΑ (P1.5-D, πρότυπο CT/Trillian — ποτέ rewrite ιστορίας):
;;;;   · census-εποχή (census.json παρόν): recomputed RFC-6962 root των 10
;;;;     canonical ≡ όνομα ≡ δηλωμένο + ΠΛΗΡΕΣ spine (census+αλυσίδα+JWS)
;;;;     + ΓΕΦΥΡΑ: μη-null prev_release_root ⇒ ο στόχος ΥΠΑΡΧΕΙ στο corpus
;;;;     (η παλιά εποχή σφραγίζεται ΜΕΣΑ στη νέα αλυσίδα).
;;;;   · legacy-εποχή (προ-P1.5, χωρίς census): SEALED — ο αλγόριθμος
;;;;     ταυτότητάς τους (χωρίς domain separation, duplicate-last) πέθανε
;;;;     ΣΚΟΠΙΜΑ στο [P1.5-A.2]/15555e9b· ΔΕΝ ανα-υπολογίζεται με τον νέο
;;;;     (θα ήταν ψευδο-κόκκινο) ούτε κρατάμε δεύτερη ζωντανή Merkle έδρα.
;;;;     Ελέγχεται: δηλωμένο root παρόν + όνομα ≡ δηλωμένο id + TSR δεμένο
;;;;     στο δηλωμένο root (owner attestation [0058]). Ο verifier της εποχής
;;;;     τους είναι αρχειοθετημένος ΜΕΣΑ τους (verify/verify.lisp).
;;;;   · latest: δείχνει σε υπαρκτό release· αν είναι content-addressed, πρέπει
;;;;     να είναι ATTESTED (temporal-proof/timestamp.tsr παρόν)
;;;; Read-only πύλη — δεν γράφει ΤΙΠΟΤΑ.

(in-package :orchestrator.cli)

(defun %rg-census-prev-root (dir)
  "Το prev_release_root του census (string «sha256:<hex>») ή NIL (null/απόν)."
  (let ((cpath (merge-pathnames "census.json" dir)))
    (when (probe-file cpath)
      (ignore-errors
        (gethash "prev_release_root"
                 (jonathan:parse (uiop:read-file-string cpath) :as :hash-table))))))

(defun %rg-verify-release (dir chk)
  (let* ((leaf (car (last (pathname-directory dir))))
         (fp (find-package :orchestrator.epistemic))
         (census-era (probe-file (merge-pathnames "census.json" dir)))
         (sha256-named (and (stringp leaf) (eql 0 (search "sha256-" leaf))))
         ;; ΚΛΕΙΣΙΜΟ κριτή P1.5-D#1 (epoch-downgrade): legacy ελέγχους παίρνει
         ;; ΜΟΝΟ id στο παγωμένο σύνολο ή timestamp-named ιστορικό. sha256-named
         ;; ΧΩΡΙΣ census ΚΑΙ εκτός frozen = απόπειρα stripped-census downgrade.
         (frozen-legacy (funcall (find-symbol "FROZEN-LEGACY-RELEASE-ID-P" fp) leaf))
         (err nil)
         (declared (handler-case (funcall (find-symbol "%RELEASE-DIR-ROOT" fp) dir)
                     (error (e) (setf err e) nil))))
    (when (and (not census-era) sha256-named (not frozen-legacy))
      (funcall chk (format nil "~A: sha256-named χωρίς census ΚΑΙ εκτός frozen legacy (epoch-downgrade)" leaf)
               nil "απόπειρα stripped-census downgrade — απαιτείται census.json ή frozen id")
      (return-from %rg-verify-release))
    (if (not census-era)
        ;; ── LEGACY-ΕΠΟΧΗ (προ-P1.5, frozen/ιστορικό): SEALED, όχι recompute ──
        (progn
          (funcall chk (format nil "~A: legacy-epoch (pre-P1.5) — δηλωμένο root παρόν" leaf)
                   (and declared t)
                   (format nil "~@[σφάλμα: ~A~]" err))
          (when (and (stringp leaf) (eql 0 (search "sha256-" leaf)))
            (funcall chk (format nil "~A: legacy-epoch — όνομα ≡ δηλωμένο id" leaf)
                     (and declared
                          (equal leaf (handler-case
                                          (funcall (find-symbol "%ROOT->RELEASE-ID" fp) declared)
                                        (error () nil))))
                     declared)
            ;; Η σφραγίδα της εποχής: TSR (όπου υπάρχει) δεμένο στο ΔΗΛΩΜΕΝΟ
            ;; root (imprint) — το owner attestation [0058] είναι η αλήθεια των
            ;; legacy releases. Legacy ΧΩΡΙΣ TSR = ξεπερασμένη ιστορία (τίμια
            ;; δηλωμένο)· ΜΟΝΟ το latest απαιτεί attestation (χωριστός έλεγχος).
            (if (probe-file (merge-pathnames "temporal-proof/timestamp.tsr" dir))
                (funcall chk (format nil "~A: legacy-epoch — TSR δεμένο στο δηλωμένο root (attested seal)" leaf)
                         (and declared
                              (funcall (find-symbol "RELEASE-ATTESTED-P" fp) dir declared))
                         "TSR παρόν αλλά ΔΕΝ δένει το δηλωμένο root")
                (funcall chk (format nil "~A: legacy-epoch — χωρίς TSR: ξεπερασμένη ιστορία (μόνο το latest απαιτεί attestation)" leaf)
                         t))))
        ;; ── CENSUS-ΕΠΟΧΗ: πλήρης RFC-6962 recompute + spine + γέφυρα ──
        (let ((recomputed (handler-case
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
            ;; [P1.5-D] gate v2: ΠΛΗΡΗΣ spine (census membership + text-σπονδυλική
            ;; + αλυσίδα + JWS πάνω στο recomputed root) — όχι μόνο root recompute.
            (multiple-value-bind (ok failures)
                (handler-case
                    (funcall (find-symbol "VERIFY-RELEASE-SPINE" fp) dir :root recomputed)
                  (error (e) (values nil (list (princ-to-string e)))))
              (funcall chk (format nil "~A: spine (census+αλυσίδα+JWS)" leaf)
                       ok (and failures (format nil "~{~A~^ · ~}" failures))))
            ;; ΓΕΦΥΡΑ ΕΠΟΧΩΝ (πρότυπο CT): μη-null prev_release_root ⇒ ο στόχος
            ;; ΥΠΑΡΧΕΙ ως δημοσιευμένο release του corpus — η παλιά εποχή είναι
            ;; σφραγισμένη ΜΕΣΑ στη νέα αλυσίδα, όχι ξεχασμένη.
            (let ((prev (%rg-census-prev-root dir)))
              (when prev
                (let* ((target-id (format nil "sha256-~A" (subseq prev 7)))
                       (target-dir (merge-pathnames
                                    (format nil "../~A/" target-id) dir)))
                  (funcall chk (format nil "~A: γέφυρα εποχών — prev ~A… υπαρκτό" leaf
                                       (subseq target-id 0 19))
                           (and (probe-file target-dir) t)
                           (format nil "prev_release_root δείχνει σε ανύπαρκτο ~A" target-id))))))))))

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
              ;; [L7-B] Transparency log: αν υπάρχει, επαληθεύεται ΠΛΗΡΩΣ
              ;; (log_root ≡ MTH(entries) + ΚΑΘΕ checkpoint consistency, RFC
              ;; 6962 §2.1.2). Απόν = τίμιο (προ-L7-B εποχή)· άκυρο = ΚΟΚΚΙΝΟ.
              (let ((corpus (car (last (pathname-directory corpus-dir)))))
                (multiple-value-bind (status info)
                    (handler-case
                        (funcall (find-symbol "TLOG-VERIFY"
                                              (find-package :orchestrator.epistemic))
                                 releases-dir)
                      (error (e) (values :invalid (princ-to-string e))))
                  (case status
                    (:absent nil) ; προ-L7-B releases: δηλωμένο, όχι σιωπηλό
                    ((t)
                     (chk (format nil "~A: transparency log εσωτερικά συνεπές (n=~D, ~D checkpoints)"
                                  corpus (getf info :tree-size)
                                  (getf info :checkpoints))
                          t)
                     ;; [A1] Αντι-διαγραφή: όταν υπάρχει log, ΚΑΘΕ census-era
                     ;; attested release του corpus οφείλει να είναι entry του.
                     ;; Διαγραφή+αναγέννηση log ⇒ παλιά roots ∉ entries ⇒ ΚΟΚΚΙΝΟ.
                     (let* ((ep (find-package :orchestrator.epistemic))
                            (entries (getf info :entries))
                            (missing '()))
                       (dolist (rel (uiop:subdirectories releases-dir))
                         (let ((leaf (car (last (pathname-directory rel)))))
                           (when (and (stringp leaf) (eql 0 (search "sha256-" leaf))
                                      (probe-file (merge-pathnames "census.json" rel))
                                      (probe-file (merge-pathnames
                                                   "temporal-proof/timestamp.tsr" rel)))
                             (let ((root (handler-case
                                             (funcall (find-symbol
                                                       "%RELEASE-RECOMPUTED-ROOT" ep)
                                                      rel)
                                           (error () nil))))
                               (unless (and root (member root entries :test #'equal))
                                 (push leaf missing))))))
                       (chk (format nil "~A: κάθε census-era attested root ∈ log entries" corpus)
                            (null missing)
                            (when missing
                              (format nil "εκτός log: ~{~A~^, ~} — πιθανή διαγραφή/αναγέννηση log"
                                      missing)))))
                    (otherwise
                     (chk (format nil "~A: transparency log" corpus) nil info)))))
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
                      ;; Ρίζα ΤΗΣ ΕΠΟΧΗΣ του στόχου: census-εποχή ⇒ recomputed
                      ;; RFC-6962· legacy-εποχή ⇒ το ΔΗΛΩΜΕΝΟ root (ο παλιός
                      ;; αλγόριθμος πέθανε σκόπιμα — δεν ανα-υπολογίζεται).
                      (chk (format nil "~A: latest είναι ATTESTED (receipt δεμένο στη ρίζα της εποχής του)" corpus)
                           (let* ((ep (find-package :orchestrator.epistemic))
                                  (troot (handler-case
                                             (if (probe-file (merge-pathnames "census.json"
                                                                              (uiop:ensure-directory-pathname target)))
                                                 (funcall (find-symbol "%RELEASE-RECOMPUTED-ROOT" ep) target)
                                                 (funcall (find-symbol "%RELEASE-DIR-ROOT" ep) target))
                                           (error () nil))))
                             (funcall (find-symbol "RELEASE-ATTESTED-P" ep) target troot))
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
 :description "read-only πύλη ολομέλειας δύο εποχών (πρότυπο CT — ποτέ rewrite ιστορίας): census-εποχή ⇒ recomputed RFC-6962 root ≡ όνομα ≡ δηλωμένο + πλήρες spine (census+αλυσίδα+JWS) + γέφυρα εποχών (prev_release_root ⇒ υπαρκτός στόχος)· legacy-εποχή (προ-P1.5) ⇒ sealed: δηλωμένο root + όνομα ≡ id + TSR δεμένο στο δηλωμένο root· latest ⇒ υπαρκτό και attested"
 :package :orchestrator.cli
 :functions '("run-release-gate" "%rg-verify-release")
 :gate "--release-gate"
 :depends-on '("εξουσία-εκδόσεων"))

(orchestrator.contracts:defcontract "release-immutability-guard" :protocol
 :package :orchestrator.cli :system "orchestrator-cli"
 :capability "περιφρούρηση-εκδόσεων" :role "έλεγχος"
 :purpose "drift ή αλλοίωση σε ΟΠΟΙΟΔΗΠΟΤΕ δημοσιευμένο release κοκκινίζει την ολομέλεια — census-εποχή με πλήρες spine, legacy-εποχή sealed μέσω attested TSR στο δηλωμένο root· η αμεταβλητότητα επαληθεύεται, δεν υποτίθεται"
 :inputs '("output/*/releases/** (committed δημοσιεύσεις)")
 :outputs '("ετυμηγορία ανά release + ονομαστική απόκλιση")
 :preconditions '("η ταυτότητα content-addressed release ορίζεται από %root->release-id")
 :postconditions '("η πύλη δεν έγραψε τίποτα — read-only")
 :side-effects '("καμία")
 :legal-critical t :policy-level :φραγή
 :audit "ανά release: δηλωμένο root, recomputed root, όνομα, attestation state"
 :rollback "revert του commit εισαγωγής"
 :tests '("--release-gate"))
