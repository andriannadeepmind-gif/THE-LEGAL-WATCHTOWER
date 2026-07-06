;;;; systems/orchestrator-cli/component-gate.lisp
;;;; ============================================================================
;;;; Η ΠΥΛΗ ΣΥΣΤΑΤΙΚΩΝ — «ό,τι δεν ταυτοποιείται, δεν θεωρείται γνωστό»
;;;; ============================================================================
;;;;
;;;; Καταναλωτής του orchestrator.components/component-scan (η πηγή αλήθειας)·
;;;; εδώ ΜΟΝΟ οι όψεις CLI (--components, --component, --component-of,
;;;; --symbols-of, --files-of) και το κλείδωμα: επικύρωση πλήρους ταυτοποίησης,
;;;; ο τύπος canonical-article-id στην πράξη, και ΑΡΝΗΤΙΚΑ τεστ (το μητρώο
;;;; πρέπει να ΠΙΑΝΕΙ ψέματα — αλλιώς είναι απογραφή, όχι επίγνωση).

(in-package :orchestrator.cli)

(defun %ensure-components ()
  "Φρέσκο μητρώο από τη ζωντανή εικόνα — η αλήθεια της στιγμής, όχι cache."
  (orchestrator.component-scan:build-component-registry!))

(defun run-components ()
  "--components : η απογραφή ταυτοτήτων — μετρημένη τώρα, ανά είδος."
  (multiple-value-bind (n e) (%ensure-components)
    (format t "~%══ ΜΗΤΡΩΟ ΣΥΣΤΑΤΙΚΩΝ: ~D ταυτότητες · ~D ακμές ══~%" n e)
    (dolist (kind '(:system :file :package :symbol))
      (let ((cs (orchestrator.components:components-of-kind kind)))
        (format t "~%▸ ~(~A~) (~D):~%" kind (length cs))
        (if (member kind '(:system :package))
            (dolist (c cs)
              (format t "  • ~A~@[ [~A]~]~@[ — ρόλος: ~A~]~%"
                      (orchestrator.components:component-name c)
                      (orchestrator.components:meta-get c :version)
                      (orchestrator.components:component-role c)))
            (format t "  (~D — λεπτομέρεια με --component <id>)~%" (length cs)))))
    (let ((v (orchestrator.component-scan:validate-components
              :test-exists-p #'find-command)))
      (if v (format t "~%▸ ΠΑΡΑΒΑΣΕΙΣ ΤΑΥΤΟΠΟΙΗΣΗΣ (~D):~%~{    ✗ ~A~%~}" (length v) v)
          (format t "~%▸ Πλήρης ταυτοποίηση: 0 παραβάσεις.~%")))
    0))

(defun %print-component (c)
  (format t "~%── ΣΥΣΤΑΤΙΚΟ ~A ──~%" (orchestrator.components:component-id c))
  (format t "  είδος: ~(~A~) · όνομα: ~A~@[ · γονέας: ~A~]~@[ · ρόλος: ~A~]~%"
          (orchestrator.components:component-kind c)
          (orchestrator.components:component-name c)
          (orchestrator.components:component-parent c)
          (orchestrator.components:component-role c))
  (when (orchestrator.components:component-hash c)
    (format t "  sha256: ~A~%" (orchestrator.components:component-hash c)))
  (loop for (k v) on (orchestrator.components:component-meta c) by #'cddr
        when (and v (not (eq k :exports)))   ; τα exports πλήρη μόνο στο --symbols-of
          do (format t "  ~(~A~): ~A~%" k
                     (if (consp v) (format nil "~{~A~^ · ~}" v) v)))
  (let ((out (orchestrator.components:edges-from (orchestrator.components:component-id c)))
        (in  (orchestrator.components:edges-to (orchestrator.components:component-id c))))
    (dolist (e out) (format t "  → ~(~A~) ~A~%" (first e) (third e)))
    (dolist (e in)  (format t "  ← ~(~A~) ~A~%" (first e) (second e)))))

(defun run-component (args)
  "--component <id|όνομα> : η πλήρης ταυτότητα ενός συστατικού + οι ακμές του."
  (%ensure-components)
  (let* ((name (format nil "~{~A~^ ~}" args))
         (hit (or (orchestrator.components:find-component name)
                  (find name (orchestrator.components:all-components)
                        :key #'orchestrator.components:component-name
                        :test #'string-equal))))
    (cond ((zerop (length name)) (format t "χρήση: --component <id|όνομα>~%") 1)
          ((null hit) (format t "Άγνωστο συστατικό «~A» — δεν το γνωρίζω, τίμια.~%" name) 1)
          (t (%print-component hit) 0))))

(defun run-component-of (args)
  "--component-of <σύμβολο> : ποιο συστατικό/αρχείο/ικανότητα κατέχει το σύμβολο."
  (%ensure-components)
  (let* ((name (format nil "~{~A~^ ~}" args))
         (hits (remove-if-not
                (lambda (c) (string-equal (orchestrator.components:component-name c) name))
                (orchestrator.components:components-of-kind :symbol))))
    (cond ((zerop (length name)) (format t "χρήση: --component-of <σύμβολο>~%") 1)
          ((null hits)
           (format t "Το «~A» ΔΕΝ είναι καταχωρισμένο κρίσιμο σύμβολο — ό,τι δεν ταυτοποιείται δεν θεωρείται γνωστό.~%" name) 1)
          (t (mapc #'%print-component hits) 0))))

(defun run-symbols-of (args)
  "--symbols-of <πακέτο> : εξαγόμενα σύμβολα + καταχωρισμένα κρίσιμα του πακέτου."
  (%ensure-components)
  (let* ((name (string-downcase (format nil "~{~A~^ ~}" args)))
         (p (orchestrator.components:find-component (format nil "package:~A" name))))
    (if (null p)
        (progn (format t "Άγνωστο πακέτο «~A».~%" name) 1)
        (progn
          (format t "~%Πακέτο ~A — ~D εξαγόμενα:~%  ~{~(~A~)~^ · ~}~%"
                  name (orchestrator.components:meta-get p :exports-count)
                  (orchestrator.components:meta-get p :exports))
          (let ((crit (orchestrator.components:edges-from
                       (format nil "package:~A" name) :exports)))
            (when crit
              (format t "Κρίσιμα (με ταυτότητα συστατικού): ~{~A~^ · ~}~%"
                      (mapcar #'third crit))))
          0))))

(defun run-files-of (args)
  "--files-of <σύστημα-asdf> : τα αρχεία-μέλη με τα SHA-256 τους."
  (%ensure-components)
  (let* ((name (format nil "~{~A~^ ~}" args))
         (edges (orchestrator.components:edges-from
                 (format nil "system:~A" name) :contains)))
    (if (null edges)
        (progn (format t "Άγνωστο σύστημα «~A».~%" name) 1)
        (progn
          (format t "~%Σύστημα ~A — ~D αρχεία:~%" name (length edges))
          (dolist (e edges)
            (let ((f (orchestrator.components:find-component (third e))))
              (format t "  ~A  ~A~%"
                      (subseq (orchestrator.components:component-hash f) 0 12)
                      (orchestrator.components:component-name f))))
          0))))

(defun run-component-gate ()
  "--component-gate : η κανονική επίγνωση συστατικών, κλειδωμένη."
  (let ((fails '()) (total 0))
    (labels ((check (label ok)
               (incf total)
               (if ok (format t "  ✓ ~A~%" label)
                   (progn (push label fails) (format t "  ✗ ~A~%" label)))))
      (format t "~%── ΠΥΛΗ ΣΥΣΤΑΤΙΚΩΝ: ό,τι δεν ταυτοποιείται δεν είναι γνωστό ──~%")
      (multiple-value-bind (n e) (%ensure-components)
        (check (format nil "① το μητρώο χτίζεται από τη ζωντανή εικόνα (~D ταυτότητες, ~D ακμές)" n e)
               (and (> n 100) (> e 100)))
        ;; ② πλήρης ταυτοποίηση: 0 παραβάσεις στον επικυρωτή
        (let ((v (orchestrator.component-scan:validate-components
                  :test-exists-p #'find-command)))
          (check (format nil "② επικυρωτής συστατικών: ~D παραβάσεις" (length v))
                 (null v))
          (dolist (msg v) (format t "      ✗ ~A~%" msg)))
        ;; ③ κάθε αρχείο κάθε συστήματος έχει SHA-256
        (check "③ κάθε αρχείο πηγής φέρει SHA-256 — αταυτοποίητη ύλη δεν υπάρχει"
               (every #'orchestrator.components:component-hash
                      (orchestrator.components:components-of-kind :file)))
        ;; ④ οι πάροχοι της ταυτότητας άρθρων χαρτογραφούνται ΟΛΟΙ στην πηγή
        (check "④ οι πάροχοι της «ταυτότητα-άρθρων» (URI/registry/normalize/typed id) χαρτογραφημένοι στην πηγή"
               (let ((cap (orchestrator.self-model:find-capability "ταυτότητα-άρθρων")))
                 (and cap
                      (every (lambda (f)
                               (nth-value 1 (orchestrator.component-scan:resolve-critical-symbol
                                             f (orchestrator.self-model:capability-package cap))))
                             (orchestrator.self-model:capability-functions cap)))))
        ;; ⑤ ο γράφος απαντά διαδρομές: σύστημα→αρχείο→πακέτο→σύμβολο→συμβόλαιο→ικανότητα
        (check "⑤ διαδρομή στον γράφο: το subsume φτάνει την ικανότητα «υπαγωγή» και το αρχείο-έδρα του"
               (let* ((sym-id (format nil "symbol:~A::subsume"
                                      "orchestrator.subsumption"))
                      (fwd (orchestrator.components:reachable-from sym-id)))
                 (and (member "capability:υπαγωγή" fwd :test #'string=)
                      (member "contract:subsume" fwd :test #'string=)
                      (some (lambda (id) (eql 0 (search "file:" id))) fwd)))))
      ;; ⑥-⑨ Ο ΤΥΠΟΣ canonical-article-id — η ταυτότητα ως αντικείμενο
      (check "⑥ parse: «100Α» ⇒ βάση 100, επίθημα Α· «100 α» κανονικοποιείται ΙΔΙΑ· raw διατηρείται ως display"
             (let ((a (orchestrator.article-id:parse-article-id "100Α"))
                   (b (orchestrator.article-id:parse-article-id "100 α")))
               (and a b (= 100 (orchestrator.article-id:article-id-base a))
                    (equal "Α" (orchestrator.article-id:article-id-suffix a))
                    (orchestrator.article-id:article-id= a b)
                    (string= (orchestrator.article-id:article-id-string a)
                             (orchestrator.article-id:article-id-string b))
                    (string/= (orchestrator.article-id:article-id-display a)
                              (orchestrator.article-id:article-id-display b)))))
      (check "⑦ 100 ≠ 100Α ως ΤΑΥΤΟΤΗΤΕΣ· ίδια ⇒ ίδιο hash, διαφορετικές ⇒ διαφορετικό"
             (let ((a (orchestrator.article-id:parse-article-id "100"))
                   (b (orchestrator.article-id:parse-article-id "100Α"))
                   (b2 (orchestrator.article-id:parse-article-id "100α")))
               (and (not (orchestrator.article-id:article-id= a b))
                    (orchestrator.article-id:article-id= b b2)
                    (= (orchestrator.article-id:article-id-hash b)
                       (orchestrator.article-id:article-id-hash b2))
                    (/= (orchestrator.article-id:article-id-hash a)
                        (orchestrator.article-id:article-id-hash b)))))
      (check "⑧ ωμός αριθμός ≠ κανονική ταυτότητα: το 100 ΔΕΝ είναι article-id και δεν συγκρίνεται σιωπηλά"
             (and (not (orchestrator.article-id:article-id-p 100))
                  (not (orchestrator.article-id:article-id=
                        100 (orchestrator.article-id:parse-article-id "100")))
                  (not (orchestrator.article-id:parse-article-id "ΧΩΡΙΣ ΑΡΙΘΜΟ"))))
      (check "⑨ η γένεση URI καταναλώνει την ΚΑΝΟΝΙΚΗ σειριοποίηση — το επίθημα επιζεί ως το URI"
             (let ((orchestrator.uris:*canonical-config*
                     (if (gethash "base_uri" orchestrator.uris:*canonical-config*)
                         orchestrator.uris:*canonical-config*
                         (let ((h (make-hash-table :test 'equal)))
                           (setf (gethash "base_uri" h) "https://gate.test") h))))
               (let ((id (orchestrator.article-id:parse-article-id "100 α")))
                 (search "/article/100Α"
                         (orchestrator.uris:build-article-uri
                          (orchestrator.article-id:article-id-string id))))))
      ;; ⑩-⑬ ΑΡΝΗΤΙΚΑ — το μητρώο πιάνει ψέματα ή είναι διακοσμητικό
      (check "⑩ διπλή ταυτότητα συστατικού ⇒ ΣΦΑΛΜΑ duplicate-component-id, ποτέ σιωπηλή αντικατάσταση"
             (handler-case
                 (progn (orchestrator.components:register-component!
                         "system:orchestrator-cli" :system "x") nil)
               (orchestrator.components:duplicate-component-id () t)))
      (check "⑪ πλαστή ικανότητα με ΑΝΥΠΑΡΚΤΟ πάροχο ⇒ ο επικυρωτής την πιάνει (σκιά μητρώων)"
             (prog1
                 (let ((orchestrator.self-model::*capabilities*
                         (copy-list orchestrator.self-model::*capabilities*)))
                   (orchestrator.self-model:declare-capability! "πλαστή-ικανότητα"
                    :package :orchestrator.cli :functions '("συνάρτηση-που-δεν-υπάρχει")
                    :gate nil :depends-on '())
                   (orchestrator.component-scan:build-component-registry!)
                   (some (lambda (m) (search "συνάρτηση-που-δεν-υπάρχει" m))
                         (orchestrator.component-scan:validate-components)))
               (orchestrator.component-scan:build-component-registry!)))
      (check "⑫ πλαστό :function συμβόλαιο σε ανύπαρκτο σύμβολο ⇒ παράβαση ταυτοποίησης"
             (prog1
                 (let ((orchestrator.contracts::*contracts*
                         (copy-list orchestrator.contracts::*contracts*)))
                   (orchestrator.contracts:declare-contract! "ghost-fn" :function
                    :package :orchestrator.cli :capability "υπαγωγή" :role "αποδείξεις")
                   (orchestrator.component-scan:build-component-registry!)
                   (some (lambda (m) (search "ghost-fn" m))
                         (orchestrator.component-scan:validate-components)))
               (orchestrator.component-scan:build-component-registry!)))
      (check "⑬ πειραγμένο hash αρχείου ⇒ ΞΕΠΕΡΑΣΜΕΝΟ (με πηγές)· χωρίς πηγές ⇒ manifest = η αλήθεια του build"
             (let ((f (find-if (lambda (c)
                                 (probe-file (orchestrator.components:meta-get c :path)))
                               (orchestrator.components:components-of-kind :file))))
               (if f
                   (progn (setf (orchestrator.components:component-hash f) "τίποτα")
                          (prog1 (and (member f (orchestrator.component-scan:stale-components)) t)
                            (orchestrator.component-scan:build-component-registry!)))
                   ;; source-less runtime: η ταυτοποίηση οφείλεται στο παγωμένο manifest
                   (plusp (orchestrator.component-scan:manifest-count))))))
    (format t "~%── ΠΥΛΗ ΣΥΣΤΑΤΙΚΩΝ: ~D/~D πέρασαν ──~%" (- total (length fails)) total)
    (if fails 1 0)))

(register-command "--components"   (lambda (a) (declare (ignore a)) (run-components)))
(register-command "--component"    (lambda (a) (run-component a)))
(register-command "--component-of" (lambda (a) (run-component-of a)))
(register-command "--symbols-of"   (lambda (a) (run-symbols-of a)))
(register-command "--files-of"     (lambda (a) (run-files-of a)))
(register-command "--component-gate" (lambda (a) (declare (ignore a)) (run-component-gate)))
(register-command "--freeze-components"
  (lambda (a) (declare (ignore a))
    (format t "Πάγωμα ταυτοτήτων συστατικών: ~D αρχεία στο manifest.~%"
            (orchestrator.component-scan:freeze-components!))
    0))

(orchestrator.self-model:declare-capability! "συστατικά"
 :description "canonical component registry: κάθε όργανο με ταυτότητα, hash, πηγή, ρόλο, ακμές — αλλιώς άγνωστο"
 :package :orchestrator.components
 :functions '("register-component!" "build-component-registry!" "validate-components")
 :gate "--component-gate" :depends-on '("συμβόλαια" "αυτοεπίγνωση"))

(orchestrator.contracts:defcontract "component-registry-protocol" :protocol
 :package :orchestrator.components :system "orchestrator-infrastructure"
 :capability "συστατικά" :role "έλεγχος"
 :purpose "το μητρώο οργάνων του Ιδρύματος: ταυτότητα/hash/πηγή/ρόλος/ακμές για κάθε συστατικό, χτισμένο από τη ζωντανή εικόνα"
 :inputs '("ASDF συστήματα" "ζωντανά πακέτα" "sb-introspect πηγές" "SHA-256 αρχείων")
 :outputs '("ταυτότητες" "γράφος ακμών" "παραβάσεις ταυτοποίησης")
 :postconditions '("διπλή ταυτότητα ⇒ σφάλμα φωναχτά" "ό,τι δεν ταυτοποιείται ⇒ παράβαση, όχι σιωπή")
 :legal-critical t :policy-level :φραγή
 :tests '("--component-gate"))

(orchestrator.contracts:defcontract "parse-article-id" :function
 :package :orchestrator.article-id :system "orchestrator-infrastructure"
 :capability "ταυτότητα-άρθρων" :role "νομική-μνήμη"
 :purpose "first-class τύπος ταυτότητας άρθρου: parse-article-id/article-id=/article-id-string — 100 ≠ 100Α, ετικέτα ≠ ταυτότητα"
 :inputs '("ετικέτα (string ή integer)") :outputs '("typed canonical-article-id ή NIL + λόγος")
 :postconditions '("ισότητα/hash μόνο μεταξύ τύπων — ωμός αριθμός δεν συγκρίνεται σιωπηλά"
                   "σταθερή σειριοποίηση: αυτή καταναλώνουν κλειδιά και URIs")
 :legal-critical t :policy-level :φραγή
 :failure-modes '("μη αριθμητική ετικέτα ⇒ NIL + λόγος — ποτέ μαντεψιά")
 :tests '("--component-gate")
 :dependents '("υπαγωγή" "παραδοτέο" "πρόσληψη-νομολογίας"))
