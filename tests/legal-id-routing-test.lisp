;;;; tests/legal-id-routing-test.lisp
;;;; INTEGRATION: the legal-id registry derived from the REAL corpus configs must
;;;; route a ΦΕΚ to the correct served code(s) — and must NOT over-route on the
;;;; generic word «Κώδικας». Exercises build-legal-id-registry (config-derived,
;;;; single source of truth) + the conservative head-word enrichment.

(in-package :orchestrator.cli)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun lid (name) (find-symbol name :orchestrator.legal-id))
(defun classify (reg text) (funcall (lid "CLASSIFY-TEXT") reg text))
(defun corpus-of (e) (funcall (lid "REGISTRY-ENTRY-CORPUS-ID") e))

(let ((reg (build-legal-id-registry)))
  (format t "~%== registry is derived from every served config ==~%")
  (check "one entry per served corpus" (= (length reg) (length *served-corpora*)))
  (check "poinikos carries its statute number 4619"
         (let ((e (funcall (lid "REGISTRY-BY-CORPUS") reg "poinikos")))
           (and e (eql 4619 (funcall (lid "ENTRY-LAW-NUMBER") e)))))
  (check "lookup by law 4619/2019 → poinikos"
         (let ((e (funcall (lid "REGISTRY-BY-LAW") reg 4619 2019)))
           (and e (string= "poinikos" (corpus-of e)))))

  (format t "~%== routing: strong (statute) and conservative (name) signals ==~%")
  (check "explicit ν.4619/2019 citation → poinikos ONLY"
         (equal '("poinikos")
                (classify reg "Στο άρθρο 299 του ν. 4619/2019 προστίθεται εδάφιο.")))
  (check "inflected «Συντάγματος» → constitution (head-word alias)"
         (member "constitution" (classify reg "Αναθεώρηση του Συντάγματος.") :test #'string=))
  (check "a bare «Κώδικας» mention does NOT route to the procedure codes"
         (null (intersection '("kpoinikis" "kpolitikis" "kdioikitikis")
                             (classify reg "Δημοσιεύεται νέος Κώδικας δεοντολογίας.")
                             :test #'string=)))
  (check "an unrelated gazette routes to nothing"
         (null (classify reg "Υπουργική απόφαση για το λιμάνι, ν. 9988/2024.")))

  ;; REAL ΦΕΚ titles harvested live from search.et.gr (ALL-CAPS, inflected) — the
  ;; phrase aliases must route them to exactly the right code(s).
  (format t "~%== real ΦΕΚ titles (ALL-CAPS inflected) route by phrase ==~%")
  (check "Ν.5090/2024 «…ΠΟΙΝΙΚΟ ΚΩΔΙΚΑ ΚΑΙ ΤΟΝ ΚΩΔΙΚΑ ΠΟΙΝΙΚΗΣ ΔΙΚΟΝΟΜΙΑΣ…» → poinikos + kpoinikis"
         (let ((c (classify reg "ΠΑΡΕΜΒΑΣΕΙΣ ΣΤΟΝ ΠΟΙΝΙΚΟ ΚΩΔΙΚΑ ΚΑΙ ΤΟΝ ΚΩΔΙΚΑ ΠΟΙΝΙΚΗΣ ΔΙΚΟΝΟΜΙΑΣ ΓΙΑ ΤΗΝ ΕΠΙΤΑΧΥΝΣΗ ΤΗΣ ΠΟΙΝΙΚΗΣ ΔΙΚΗΣ")))
           (and (member "poinikos" c :test #'string=)
                (member "kpoinikis" c :test #'string=))))
  (check "Ν.5089/2024 «…ΤΡΟΠΟΠΟΙΗΣΗ ΤΟΥ ΑΣΤΙΚΟΥ ΚΩΔΙΚΑ» → astikos"
         (member "astikos" (classify reg "ΙΣΟΤΗΤΑ ΣΤΟΝ ΠΟΛΙΤΙΚΟ ΓΑΜΟ, ΤΡΟΠΟΠΟΙΗΣΗ ΤΟΥ ΑΣΤΙΚΟΥ ΚΩΔΙΚΑ ΣΕ ΑΛΛΕΣ ΔΙΑΤΑΞΕΙΣ.") :test #'string=))
  (check "Ν.5134/2024 «…ΚΩΔΙΚΑ ΠΟΛΙΤΙΚΗΣ ΔΙΚΟΝΟΜΙΑΣ…ΚΩΔΙΚΑ ΠΟΙΝΙΚΗΣ ΔΙΚΟΝΟΜΙΑΣ» → kpolitikis + kpoinikis"
         (let ((c (classify reg "ΠΑΡΕΜΒΑΣΕΙΣ ΣΤΟΝ ΚΩΔΙΚΑ ΠΟΛΙΤΙΚΗΣ ΔΙΚΟΝΟΜΙΑΣ ΚΑΙ ΣΤΟΝ ΚΩΔΙΚΑ ΠΟΙΝΙΚΗΣ ΔΙΚΟΝΟΜΙΑΣ")))
           (and (member "kpolitikis" c :test #'string=)
                (member "kpoinikis" c :test #'string=))))
  (check "ΠΟΙΝΙΚΟ ΚΩΔΙΚΑ does NOT over-route to kpoinikis (που θέλει «Δικονομίας»)"
         (let ((c (classify reg "ΤΡΟΠΟΠΟΙΗΣΗ ΤΟΥ ΠΟΙΝΙΚΟΥ ΚΩΔΙΚΑ")))
           (and (member "poinikos" c :test #'string=)
                (not (member "kpoinikis" c :test #'string=)))))
  (check "a cybersecurity law citing no code routes to nothing"
         (null (classify reg "ΕΘΝΙΚΗ ΑΡΧΗ ΚΥΒΕΡΝΟΑΣΦΑΛΕΙΑΣ ΚΑΙ ΛΟΙΠΕΣ ΔΙΑΤΑΞΕΙΣ."))))

(format t "~%========================================~%")
(format t "Legal-ID routing (config) tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
