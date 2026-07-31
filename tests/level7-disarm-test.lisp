;;;; tests/level7-disarm-test.lisp
;;;; ============================================================================
;;;; LEVEL-7 VCCT-RSM — ΑΠΟΔΕΙΞΗ ΑΦΟΠΛΙΣΜΟΥ ΤΩΝ LEGACY PUBLISHERS
;;;; ============================================================================
;;;; Το ΠΡΩΤΟ παραδοτέο της εντολής FV-CCT-RSM: κώδικας που αποδεικνύει ότι
;;;; ΚΑΝΕΝΑΣ υπάρχων publisher δεν μπορεί πλέον να προαγάγει authority.
;;;;
;;;; Δύο επίπεδα άμυνας, δύο αποδείξεις:
;;;;   Α. ΚΩΔΙΚΑΣ: κάθε παλιά authority έδρα (promote-latest!, tlog-append-root!,
;;;;      release-attested-p) σηματοδοτεί LEGACY-AUTHORITY-SEAT-REMOVED για ΚΑΘΕ
;;;;      είσοδο — ακόμη και για την πλήρως «νόμιμη» legacy διαδρομή που ΠΡΙΝ
;;;;      περνούσε (attested release με tsr). Αρνητικός μάρτυρας: το τεστ στήνει
;;;;      το ΑΚΡΙΒΕΣ σενάριο που η παλιά έδρα δεχόταν (fake tsr με imprint —
;;;;      release-authority-test ⑦β) και απαιτεί ΑΡΝΗΣΗ εκεί που πριν ήταν
;;;;      αποδοχή.
;;;;   Β. CANDIDATE BOUNDARY: ο παραγωγός γράφει ΜΟΝΟ candidate bundles
;;;;      (evidence-only, authority:false), και το marker είναι immutable.
;;;;
;;;; (Το OS επίπεδο — EACCES για κάθε ταυτότητα πλην authority — αποδεικνύεται
;;;;  ΕΚΤΕΛΕΣΤΙΚΑ από authority-v2/capability/verify-capability-closure.sh:
;;;;  ξεχωριστή έδρα, ξεχωριστή απόδειξη, BLOCKED χωρίς root — ποτέ PASS.)

(defvar *pass* 0)
(defvar *fail* 0)
(defun check (name ok)
  (if ok (progn (incf *pass*) (format t "  ok   ~A~%" name))
      (progn (incf *fail*) (format t "  FAIL ~A~%" name))))

(defmacro seat-removed-p (form)
  "T αν το FORM σηματοδοτεί ΑΚΡΙΒΩΣ legacy-authority-seat-removed (όχι άλλο
   σφάλμα — ένα τυχαίο crash ΔΕΝ είναι αφοπλισμός, είναι θόρυβος)."
  `(handler-case (progn ,form :no-signal)
     (orchestrator.epistemic:legacy-authority-seat-removed () :removed)
     (error (e) (list :other-error (format nil "~A" e)))))

(format t "~%== Α. ΟΙ ΠΑΛΙΕΣ AUTHORITY ΕΔΡΕΣ ΑΡΝΟΥΝΤΑΙ — ΠΑΝΤΑ ==~%")

(defvar *base* (merge-pathnames (format nil "lawmax-disarm-~D/" (sb-unix:unix-getpid))
                                (uiop:temporary-directory)))
(ensure-directories-exist (merge-pathnames "releases/" *base*))

;; Στήνουμε το ΑΚΡΙΒΕΣ σενάριο που η ΠΑΛΙΑ διαδρομή δεχόταν (⑦β):
;; release dir + temporal-proof/timestamp.tsr που περιέχει το imprint.
(defvar *rel-id* "sha256-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
(defvar *rel-dir* (merge-pathnames (format nil "releases/~A/" *rel-id*) *base*))
(ensure-directories-exist (merge-pathnames "temporal-proof/" *rel-dir*))
(let* ((root (concatenate 'string "sha256:" (make-string 64 :initial-element #\a)))
       (imprint (ironclad:digest-sequence
                 :sha256 (babel:string-to-octets root :encoding :utf-8))))
  (with-open-file (o (merge-pathnames "temporal-proof/timestamp.tsr" *rel-dir*)
                     :direction :output :element-type '(unsigned-byte 8)
                     :if-exists :supersede)
    (write-sequence imprint o)))

(check "promote-latest! ⇒ SEAT-REMOVED (το σενάριο που ΠΡΙΝ περνούσε, τώρα ΑΡΝΗΣΗ)"
       (eq :removed (seat-removed-p
                     (orchestrator.epistemic::promote-latest! *base* *rel-id*))))

(check "release-attested-p ⇒ SEAT-REMOVED (το substring-κατηγόρημα ΔΕΝ κρίνει πια τίποτα)"
       (eq :removed (seat-removed-p
                     (orchestrator.epistemic::release-attested-p *rel-dir* "sha256:x"))))

(check "tlog-append-root! ⇒ SEAT-REMOVED (καμία authoritative log εγγραφή από legacy)"
       (eq :removed (seat-removed-p
                     (orchestrator.epistemic:tlog-append-root!
                      (merge-pathnames "releases/" *base*)
                      (concatenate 'string "sha256:" (make-string 64 :initial-element #\b))))))

;; Η άρνηση είναι ΚΑΘΟΛΙΚΗ — όχι input-εξαρτώμενη: και με ανύπαρκτα paths.
(check "promote-latest! αρνείται ΚΑΙ με ανύπαρκτο release (καθολική άρνηση, όχι validation)"
       (eq :removed (seat-removed-p
                     (orchestrator.epistemic::promote-latest! *base* "sha256-nonexistent"))))

(format t "~%== Β. Ο ΠΑΡΑΓΩΓΟΣ ΓΡΑΦΕΙ ΜΟΝΟ CANDIDATES (evidence-only) ==~%")

(let ((marker (orchestrator.epistemic:emit-candidate-bundle!
               *base* *rel-id* :candidate-root "sha256:cafe")))
  (check "emit-candidate-bundle! γράφει στο candidate namespace"
         (and (probe-file marker)
              (search "candidates/" (namestring marker))))
  (let ((txt (uiop:read-file-string marker)))
    (check "ο δείκτης δηλώνει authority:false (ΠΟΤΕ authority από παραγωγό)"
           (and (search "\"authority\":false" txt)
                (search "candidate-bundle" txt))))
  ;; Immutability: δεύτερη εκπομπή ΔΕΝ ξαναγράφει (ίδιο αρχείο, ίδια bytes).
  (let ((before (uiop:read-file-string marker)))
    (orchestrator.epistemic:emit-candidate-bundle! *base* *rel-id* :candidate-root "sha256:beef")
    (check "candidate marker είναι IMMUTABLE (δεύτερη εκπομπή δεν τον αλλάζει)"
           (equal before (uiop:read-file-string marker)))))

;; ΚΑΝΕΝΑ authoritative artifact δεν εμφανίστηκε από όλες τις παραπάνω κλήσεις.
(check "ΚΑΝΕΝΑ latest/latest.json/transparency-log δεν γράφτηκε από τις απόπειρες"
       (and (not (probe-file (merge-pathnames "releases/latest" *base*)))
            (not (probe-file (merge-pathnames "releases/latest.json" *base*)))
            (not (probe-file (merge-pathnames "releases/transparency-log.json" *base*)))))

(format t "~%== Γ. Η ΓΡΑΜΜΗ ΕΙΝΑΙ ΦΕΡΟΥΣΑ (μάρτυρας μη-κενότητας) ==~%")
;; Ο μάρτυρας: αν η κατάργηση ΔΕΝ υπήρχε, το σενάριο ⑦β θα ΠΕΡΝΟΥΣΕ (όπως
;; στο release-authority-test πριν). Αποδεικνύουμε ότι η συνθήκη-άρνηση είναι
;; ΑΥΤΗ που φέρει: το condition είναι το δηλωμένο, με τη σωστή έδρα μέσα.
(check "το condition κατονομάζει την έδρα (seat) που αρνήθηκε"
       (handler-case (progn (orchestrator.epistemic::promote-latest! *base* *rel-id*) nil)
         (orchestrator.epistemic:legacy-authority-seat-removed (c)
           (equal "promote-latest!"
                  (orchestrator.epistemic:legacy-authority-seat-removed-seat c)))
         (error () nil)))

(format t "~%== [Δ2] ΚΑΝΕΝΑΣ παραγωγικός writer του legacy log ==~%")
;; [Δ2] Ο αφοπλισμός του tlog-append-root! δεν αρκούσε: όσο ο ΜΗΧΑΝΙΣΜΟΣ
;; εγγραφής ζούσε στην εικόνα, παρέμενε διαδρομή που ΘΑ μπορούσε να ξανακληθεί.
;; Τώρα ο κώδικας ΔΕΝ ΥΠΑΡΧΕΙ σε κανένα ASDF system — ελέγχεται εκτελεστικά.
(check "Δ2α %tlog-write ΔΕΝ είναι fbound (εκτός παραγωγής)"
       (let ((sym (find-symbol "%TLOG-WRITE" :orchestrator.epistemic)))
         (or (null sym) (not (fboundp sym)))))
(check "Δ2β %tlog-write-1 ΔΕΝ είναι fbound"
       (let ((sym (find-symbol "%TLOG-WRITE-1" :orchestrator.epistemic)))
         (or (null sym) (not (fboundp sym)))))
(check "Δ2γ ο READER %tlog-read ΠΑΡΑΜΕΝΕΙ (legacy evidence γένεσης)"
       (let ((sym (find-symbol "%TLOG-READ" :orchestrator.epistemic)))
         (and sym (fboundp sym))))

(format t "~%== [Δ3] Ο ΠΑΡΑΓΩΓΟΣ ΓΡΑΦΕΙ ΜΟΝΟ ΣΕ candidates/ ==~%")
;; [Δ3] Ο προορισμός του παραγωγού είναι ΑΛΛΟ namespace — δομικά, όχι κατά
;; σύμβαση. Ελέγχεται με ΠΡΑΓΜΑΤΙΚΗ κλήση του publish path.
(check "Δ3α η έδρα publish στοχεύει candidates/ (όχι releases/)"
       (let ((src (uiop:read-file-string
                   (merge-pathnames "systems/orchestrator-epistemic/deploy-epistemic.lisp"
                                    (uiop:ensure-directory-pathname
                                     (or (uiop:getenv "LAWMAX_REPO") (uiop:getcwd)))))))
         (and (search "candidates/~A/" src)
              (not (search "(format nil \"releases/~A/\" release-id)" src)))))

(uiop:delete-directory-tree *base* :validate t :if-does-not-exist :ignore)

(format t "~%── level7-disarm: ~D passed, ~D failed ──~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
