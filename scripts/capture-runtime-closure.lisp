#!/usr/bin/env sbcl --script
;;;; capture-runtime-closure.lisp
;;;; Captures ACTUAL runtime dependency closure via ASDF operation plan instrumentation
;;;; Output: deps/*.closure.json (canonical, deterministic, schema-validated)

(require :asdf)
(require :uiop)

(defvar *closure-data* (make-hash-table :test 'equal)
  "Hash table: system-name -> {version, source-id, hash, layer}")

(defvar *dependency-graph* (make-hash-table :test 'equal)
  "Hash table: system-name -> list of direct dependencies")

(defvar *loaded-systems* nil
  "List of systems that have been loaded (in order)")

(defvar *project-root* (uiop:getcwd)
  "Project root directory for filtering paths")

(defvar *third-party-dir* (merge-pathnames "third-party/" *project-root*)
  "Third-party dependencies directory")

(defparameter *target-system* "orchestrator-core-runtime"
  "Target system to capture closure for")

(defparameter *output-file* "deps/orchestrator-core-runtime.closure.json"
  "Output canonical closure artifact")

;;;; ============================================================================
;;;; ASDF Operation Plan Instrumentation
;;;; ============================================================================

(defmethod asdf:operate :before ((operation asdf:operation) (component asdf:component)
                                  &key &allow-other-keys)
  "Hook ASDF operations to capture dependency closure at operation plan level."
  (let ((system (asdf:component-system component)))
    (when system
      (let ((system-name (asdf:component-name system)))
        ;; Track system loading
        (unless (gethash system-name *closure-data*)
          (capture-system-metadata system-name system))

        ;; Track load order
        (pushnew system-name *loaded-systems* :test #'equal)))))

(defun normalize-dependency-name (spec)
  "[RATCHET-5] Κανονικοποίηση ΚΑΘΕ μορφής ASDF dependency spec.
   Επιστρέφει (values name recognized-p):
     name         = όνομα συστήματος (string) ή NIL
     recognized-p = T αν η ΜΟΡΦΗ αναγνωρίστηκε (ακόμη κι αν δεν ισχύει εδώ)
   Το ASDF επιτρέπει: \"name\" · :name · (:version name v) · (:feature f dep) ·
   (:require name). Η ΔΙΑΚΡΙΣΗ είναι ουσιώδης: μια εξάρτηση υπό ΑΝΕΝΕΡΓΟ feature
   (π.χ. (:feature :corman …) σε SBCL) ΔΕΝ είναι εξάρτηση εδώ — παραλείπεται
   νόμιμα. Μια ΑΓΝΩΣΤΗ μορφή είναι τίμια άγνοια και ρίχνει το build.
   Πριν, οι σύνθετες μορφές περνούσαν ΩΜΕΣ στο (sort … #'string<) και το script
   έσκαγε με TYPE-ERROR — ένας από τους λόγους που το closure έμενε ΚΕΝΟ."
  (typecase spec
    (string (values spec t))
    (symbol (values (string-downcase (symbol-name spec)) t))
    (cons (case (first spec)
            (:version (normalize-dependency-name (second spec)))
            (:require (normalize-dependency-name (second spec)))
            (:feature (if (uiop:featurep (second spec))
                          (normalize-dependency-name (third spec))
                          (values nil t)))   ; αναγνωρίσιμο, ανενεργό εδώ
            (t (values nil nil))))
    (t (values nil nil))))

(defvar *unclassified-deps* nil
  "Dependency specs που ΔΕΝ αναγνωρίστηκαν — δηλώνονται, ποτέ σιωπηλά.")

(defmethod asdf:perform :before ((operation asdf:load-op) (component asdf:system))
  "Hook load operations to capture system-level dependencies."
  (let ((system-name (asdf:component-name component)))
    ;; [RATCHET-5] ΚΑΙ metadata εδώ: το operate-hook δεν πυροδοτείται για
    ;; υπο-συστήματα (ironclad/cipher/aes, trivia.level0) — έμπαιναν στον γράφο
    ;; ΧΩΡΙΣ εγγραφή closure, σπάζοντας κάθε αμφιμονοσήμαντο έλεγχο.
    (unless (gethash system-name *closure-data*)
      (capture-system-metadata system-name component))
    ;; Capture dependencies from ASDF system definition
    (let ((deps (asdf:component-sideway-dependencies component)))
      (when deps
        (let ((names '()))
          (dolist (d deps)
            (multiple-value-bind (n recognized) (normalize-dependency-name d)
              (cond (n (push n names))
                    (recognized)   ; αναγνωρίσιμη μορφή, ανενεργή εδώ — νόμιμη παράλειψη
                    (t (pushnew (format nil "~S" d) *unclassified-deps* :test #'equal)))))
          (setf (gethash system-name *dependency-graph*)
                (remove-duplicates
                 (append (gethash system-name *dependency-graph*) (nreverse names))
                 :test #'equal)))))))

;;;; ============================================================================
;;;; Metadata Capture
;;;; ============================================================================

(defun capture-system-metadata (system-name system)
  "Capture metadata for a system: version, source-id, hash, layer."
  (let* ((source-location (asdf:system-source-directory system))
         (source-id (extract-source-id source-location))
         ;; Για τα ΔΙΚΑ μας συστήματα αυθεντία είναι το :version του .asd·
         ;; για τα pinned third-party, η πινακίδα του καταλόγου.
         (declared (ignore-errors (asdf:component-version system)))
         (version (or declared (extract-version source-id system-name)))
         (origin (system-origin system-name source-id))
         (hash (get-hash-for system-name source-id origin))
         (layer (determine-layer system-name)))

    (setf (gethash system-name *closure-data*)
          (list :name system-name
                :version version
                :source-id source-id
                :hash hash
                :origin (string-downcase (symbol-name origin))
                :layer layer))))

(defun extract-source-id (source-location)
  "Extract logical source-id from source location (relative to project root)."
  (when source-location
    (let* ((namestring (namestring source-location))
           (relative (if (uiop:subpathp namestring *third-party-dir*)
                         (enough-namestring namestring *third-party-dir*)
                         (enough-namestring namestring *project-root*))))
      ;; [RATCHET-5] Κατάλογος == ρίζα έργου ⇒ enough-namestring δίνει "" και το
      ;; source_id έβγαινε ΚΕΝΟ για ΚΑΘΕ δικό μας σύστημα (η έδρα κρίσης το
      ;; έπιασε ως ελλιπές πεδίο). Η ρίζα δηλώνεται ρητά ως "." — ποτέ κενό.
      (let ((trimmed (string-right-trim "/" relative)))
        (if (string= trimmed "") "." trimmed)))))

(defun extract-version (source-id name)
  "[RATCHET-5] Η ΠΙΝΑΚΙΔΑ έκδοσης του pinned καταλόγου: ό,τι ακολουθεί το όνομα
   του συστήματος στο source-id (π.χ. name=\"alexandria\",
   source-id=\"third-party/alexandria-20241012-git\" ⇒ \"20241012-git\").
   Πριν, επιστρεφόταν ό,τι ήταν μετά την ΤΕΛΕΥΤΑΙΑ παύλα ⇒ «git» — ψευδής
   ένδειξη έκδοσης μέσα σε artifact που καταναλώνει πύλη. Όταν η αντιστοίχιση
   δεν είναι βέβαιη, δηλώνεται \"unpinned\" (τίμια άγνοια, ποτέ μαντεψιά).
   ΑΥΘΕΝΤΙΚΗ ταυτότητα παραμένουν πάντα source_id + hash."
  (let* ((base (car (last (remove "" (uiop:split-string (or source-id "") :separator "/")
                                  :test #'string=))))
         (prefix (concatenate 'string name "-")))
    (cond ((null base) "unpinned")
          ((and (> (length base) (length prefix))
                (string= prefix base :end2 (length prefix)))
           (subseq base (length prefix)))
          (t "unpinned"))))

(defvar *deps-lock-table* nil
  "pinned-dir-name → sha256, από το deps.lock. Η ΜΙΑ πηγή των καρφωμένων hashes.")

(defun load-deps-lock ()
  "Διάβασε το deps.lock ΜΙΑ φορά σε πίνακα: <dir-name> | sha256."
  (or *deps-lock-table*
      (setf *deps-lock-table*
            (let ((table (make-hash-table :test 'equal))
                  (deps-lock (merge-pathnames "deps.lock" *project-root*)))
              (when (probe-file deps-lock)
                (with-open-file (stream deps-lock :direction :input)
                  (loop for line = (read-line stream nil)
                        while line
                        do (unless (or (string= line "")
                                       (char= (char line 0) #\#))
                             (let ((parts (uiop:split-string line :separator "|")))
                               (when (= (length parts) 2)
                                 (setf (gethash (string-trim " " (first parts)) table)
                                       (string-trim " " (second parts)))))))))
              table))))

(defun %path-parts (source-id)
  (remove "" (uiop:split-string (or source-id "") :separator "/") :test #'string=))

(defun pinned-dir-of (source-id)
  "Ο ΚΑΡΦΩΜΕΝΟΣ κατάλογος third-party στον οποίο ζει το σύστημα.
   [RATCHET-5] Υπολογίζεται από τα ΣΤΟΙΧΕΙΑ ΔΙΑΔΡΟΜΗΣ του source-id, όχι με
   uiop:subpathp πάνω σε string (επιστρέφει NIL — γι' αυτό ΟΛΑ τα third-party
   ταξινομούνταν λανθασμένα ως first-party και έχαναν το pin τους)."
  (let ((parts (%path-parts source-id)))
    (cond ((null parts) nil)
          ((string= (first parts) "third-party") (second parts))
          (t (first parts)))))

(defun system-origin (system-name source-id)
  "[RATCHET-5] ΤΑΞΙΝΟΜΗΣΗ ΚΑΤΑΓΩΓΗΣ — καμία εγγραφή δεν μένει «unknown»:
     :third-party  = ζει κάτω από third-party/ (ΠΡΕΠΕΙ να είναι καρφωμένο)
     :sbcl-contrib = module της ίδιας της SBCL (sb-*) — δεν καρφώνεται από εμάς
     :first-party  = δικό μας σύστημα (orchestrator-*) — ταυτότητα από git
   Η κρίση γίνεται στα στοιχεία διαδρομής του source-id (ντετερμινιστικά)."
  (let ((parts (%path-parts source-id)))
    (cond ((and parts (string= (first parts) "third-party")) :third-party)
          ((and (> (length system-name) 3) (string= "sb-" system-name :end2 3))
           :sbcl-contrib)
          (t :first-party))))

(defun get-hash-for (system-name source-id origin)
  "SHA-256 του ΚΑΡΦΩΜΕΝΟΥ ΚΑΤΑΛΟΓΟΥ στον οποίο ζει το σύστημα.
   [RATCHET-5] Πριν γινόταν (search system-name <dir>) — υπο-συστήματα όπως
   trivia.level0 / ironclad/cipher/aes ΔΕΝ ταίριαζαν με τον κατάλογό τους και
   έπαιρναν «unknown», δηλαδή καρφωμένος κώδικας εμφανιζόταν ΑΚΑΡΦΩΤΟΣ. Το pin
   είναι ιδιότητα του ΚΑΤΑΛΟΓΟΥ, όχι του ονόματος."
  (declare (ignore system-name))
  (ecase origin
    (:third-party (or (gethash (pinned-dir-of source-id) (load-deps-lock))
                      :missing-pin))
    (:sbcl-contrib "n/a-sbcl-contrib")
    (:first-party "n/a-first-party")))

(defun determine-layer (system-name)
  "Determine layer (runtime/test/tooling) based on system name."
  (cond
    ((search "test" system-name :test #'char-equal) "test")
    ((search "tooling" system-name :test #'char-equal) "tooling")
    (t "runtime")))

;;;; ============================================================================
;;;; ΣΗΜΕΙΩΣΗ [RATCHET-5]: εδώ υπήρχε redefinition του CL:REQUIRE ώστε να
;;;; «παρακολουθούνται» non-ASDF module loads. Αυτό ΕΙΝΑΙ ΑΔΥΝΑΤΟ στην SBCL
;;;; (package lock του COMMON-LISP) και έσκαγε ΠΑΝΤΑ με SYMBOL-PACKAGE-LOCKED-
;;;; ERROR: το script δεν ολοκλήρωνε ΠΟΤΕ, το closure artifact έμενε ΚΕΝΟ
;;;; ("closure": []), και το πρώτο job του CI πέθαινε — παρασύροντας ΟΛΑ τα
;;;; υπόλοιπα (needs: dependency-policy-gate). Το ίδιο το κενό artifact έκανε
;;;; μετά τον layer-separation έλεγχο ΤΕΤΡΙΜΜΕΝΑ πράσινο (jq πάνω σε κενό array).
;;;; Διαγράφηκε: η αυθεντία του closure είναι τα ASDF systems (τα οποία ήδη
;;;; συλλαμβάνονται από τα instrumentation methods παραπάνω) — όχι τα
;;;; sb-* modules. Κανένα monkey-patch σε κλειδωμένο σύμβολο προτύπου.
;;;; ============================================================================

;;;; ============================================================================
;;;; Canonical JSON Output
;;;; ============================================================================

(defun generate-canonical-closure-json ()
  "Generate canonical, deterministic JSON closure artifact."
  (let* ((closure-list (sort-closure-data))
         (graph-sorted (sort-dependency-graph))
         (sbcl-version (lisp-implementation-version)))

    (with-open-file (stream (merge-pathnames *output-file* *project-root*)
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (format stream "{~%")
      (format stream "  \"format_version\": \"1.0\",~%")
      (format stream "  \"system\": \"~A\",~%" *target-system*)
      (format stream "  \"sbcl_version\": \"~A\",~%" sbcl-version)
      (format stream "  \"closure\": [~%")

      ;; Write closure data (sorted)
      (loop for (data . rest) on closure-list
            do (write-closure-entry stream data (not (null rest))))

      (format stream "  ],~%")
      (format stream "  \"graph\": {~%")

      ;; Write dependency graph (sorted)
      (loop for ((sys . deps) . rest) on graph-sorted
            do (format stream "    \"~A\": [~{\"~A\"~^, ~}]~:[~;,~]~%"
                       sys deps (not (null rest))))

      (format stream "  }~%")
      (format stream "}~%"))))

(defun sort-closure-data ()
  "Sort closure data alphabetically by system name."
  (let ((entries nil))
    (maphash (lambda (key value)
               (push (cons key value) entries))
             *closure-data*)
    (sort entries #'string< :key #'car)))

(defun sort-dependency-graph ()
  "Sort dependency graph alphabetically by system name."
  (let ((entries nil))
    (maphash (lambda (key value)
               (push (cons key (sort (copy-list value) #'string<)) entries))
             *dependency-graph*)
    (sort entries #'string< :key #'car)))

(defun write-closure-entry (stream entry trailing-comma)
  "Write a single closure entry to JSON stream.
   [RATCHET-5] Η εγγραφή ΕΙΝΑΙ plist (:name … :version … :source-id … :hash …
   :layer …). Το προηγούμενο (destructuring-bind (name &key …) (cdr entry))
   έδενε το `name` στο ΚΕΙΝΟ keyword :NAME και άφηνε περιττό μονό στοιχείο ⇒
   DEFMACRO-LAMBDA-LIST-BROKEN-KEY-LIST-ERROR. Δεν φαινόταν ποτέ επειδή το
   script έσκαγε νωρίτερα (require monkey-patch). Ανάγνωση με getf — μία μορφή."
  (let ((plist (cdr entry)))
    (format stream "    {~%")
    (format stream "      \"name\": \"~A\",~%" (getf plist :name))
    (format stream "      \"version\": \"~A\",~%" (or (getf plist :version) "unpinned"))
    (format stream "      \"source_id\": \"~A\",~%" (getf plist :source-id))
    (format stream "      \"hash\": \"~A\",~%" (let ((h (getf plist :hash)))
                                                 (if (eq h :missing-pin) "MISSING-PIN" (or h "unknown"))))
    (format stream "      \"origin\": \"~A\",~%" (getf plist :origin))
    (format stream "      \"layer\": \"~A\"~%" (getf plist :layer))
    (format stream "    }~:[~;,~]~%" trailing-comma)))

;;;; ============================================================================
;;;; Main Execution
;;;; ============================================================================

(defun main ()
  "Main entry point: load target system and capture closure."
  (format t "~&========================================~%")
  (format t "Runtime Closure Capture~%")
  (format t "========================================~%")
  (format t "Target system: ~A~%" *target-system*)
  (format t "Output file: ~A~%" *output-file*)
  (format t "~%")

  ;; Configure ASDF source registry (hermetic)
  (let ((third-party-tree (list :tree (namestring *third-party-dir*))))
    (asdf:initialize-source-registry
     `(:source-registry
       ,third-party-tree
       (:tree ,(namestring (merge-pathnames "source/cl-dependencies/" *project-root*)))
       :inherit-configuration)))

  ;; [RATCHET-5] Central registry = ΚΑΘΕ σύστημα από το οποίο εξαρτάται το
  ;; orchestrator-core-runtime. Πριν δηλώνονταν 4 από τα 10 (spec/model/core/
  ;; engine-sbcl) — ακόμη κι αν το script δεν έσκαγε στο require monkey-patch,
  ;; η φόρτωση ΘΑ αποτύγχανε. Η λίστα παράγεται από τον ΔΙΣΚΟ (κάθε φάκελος
  ;; systems/*/), όχι χειρόγραφα: νέο σύστημα = αυτομάτως ορατό, καμία
  ;; ξεχασμένη εγγραφή.
  (push *project-root* asdf:*central-registry*)
  (dolist (dir (directory (merge-pathnames "systems/*/" *project-root*)))
    (push dir asdf:*central-registry*))

  ;; Load target system (instrumentation captures closure)
  (format t "Loading system: ~A~%" *target-system*)
  (handler-case
      (handler-bind ((warning #'muffle-warning))
        (asdf:load-system *target-system*))
    (error (e)
      (format t "~&ERROR loading system: ~A~%" e)
      (uiop:quit 1)))

  (format t "~%Systems loaded: ~D~%" (hash-table-count *closure-data*))

  ;; [RATCHET-5] ΤΙΜΙΑ ΑΓΝΟΙΑ: κάθε μη-αναγνωρισμένη μορφή εξάρτησης ΔΗΛΩΝΕΤΑΙ
  ;; και ρίχνει το build — ποτέ σιωπηλά παραλειπόμενη ακμή στον γράφο.
  (when *unclassified-deps*
    (format *error-output*
            "~&::error::ΑΤΑΞΙΝΟΜΗΤΕΣ μορφές εξάρτησης (~D): ~{~A~^, ~}~%"
            (length *unclassified-deps*) *unclassified-deps*)
    (uiop:quit 1))

  ;; [RATCHET-5] FAIL-CLOSED: κενό closure ΔΕΝ γράφεται ΠΟΤΕ. Το κενό artifact
  ;; ήταν η αιτία που ο layer-separation έλεγχος περνούσε ΤΕΤΡΙΜΜΕΝΑ (jq πάνω
  ;; σε κενό array) — «απόδειξη» χωρίς περιεχόμενο. Καμία ψευδο-επιτυχία.
  (when (zerop (hash-table-count *closure-data*))
    (format *error-output*
            "~&::error::ΚΕΝΟ closure — καμία εξάρτηση δεν συνελήφθη. Το artifact ~
             ΔΕΝ γράφεται (κενή «απόδειξη» = ψευδής απόδειξη).~%")
    (uiop:quit 1))

  ;; Generate canonical JSON output
  (ensure-directories-exist (merge-pathnames "deps/" *project-root*))
  (generate-canonical-closure-json)

  (format t "~%Closure artifact written: ~A~%" *output-file*)
  (format t "========================================~%")
  (uiop:quit 0))

;; Execute main
(main)
