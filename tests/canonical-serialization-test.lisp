;;;; tests/canonical-serialization-test.lisp
;;;; ============================================================================
;;;; [0088] Φ1β — Συμμόρφωση της Lisp έδρας canonical serialization με τα
;;;; ΔΕΣΜΕΥΜΕΝΑ vectors (deployment/verify/vectors/canonical-serialization.json).
;;;; Τα ίδια vectors επαληθεύει ανεξάρτητα ο verify-canonical.py (δύο γλώσσες,
;;;; ίδια ετυμηγορία — spec: deployment/verify/canonical-serialization-spec.md).
;;;; Αλλαγή στη σειριοποίηση χωρίς συνειδητή αναγέννηση vectors ⇒ ΚΟΚΚΙΝΟ.
;;;; ============================================================================

(in-package :orchestrator.cli)

(defvar *cs-pass* 0)
(defvar *cs-fail* 0)

(defmacro cs-check (name form)
  `(handler-case
       (if ,form
           (progn (incf *cs-pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *cs-fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e)
       (incf *cs-fail*)
       (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

(format t "~%── [0088] Φ1β CANONICAL SERIALIZATION: Lisp έδρα ≡ δεσμευμένα vectors ──~%")

(let* ((path (orchestrator.paths:institution-dir
              "deployment/verify/vectors/canonical-serialization.json"))
       (data (jonathan:parse (uiop:read-file-string path :external-format :utf-8)
                             :as :alist))
       (vectors (cdr (assoc "vectors" data :test #'string=))))

  (cs-check "σχήμα vectors: canonical-serialization-vectors/1, ≥8 διανύσματα"
            (and (equal "canonical-serialization-vectors/1"
                        (cdr (assoc "schema" data :test #'string=)))
                 (>= (length vectors) 8)))

  ;; Για ΚΑΘΕ vector: canonicalize(value) ≡ canonical ΚΑΙ sha256 ≡ δεσμευμένο.
  ;; Το value ξαναδιαβάζεται από το JSON (jonathan alist) — άρα ελέγχεται και
  ;; η σταθερότητα parse→canonicalize, όχι μόνο η εσωτερική συνέπεια.
  (dolist (v vectors)
    (let* ((name (cdr (assoc "name" v :test #'string=)))
           (value (cdr (assoc "value" v :test #'string=)))
           (want-canon (cdr (assoc "canonical" v :test #'string=)))
           (want-hash (cdr (assoc "sha256" v :test #'string=)))
           (got-canon (orchestrator.canonical-representation:canonicalize-json value))
           (got-hash (orchestrator.canonical-representation:canonical-hash value)))
      (cs-check (format nil "vector «~A»: canonical byte-ταυτόσημο + sha256 ίδιο" name)
                (and (equal want-canon got-canon)
                     (equal want-hash got-hash)))))

  ;; Θεμελιώδεις ιδιότητες πάνω από τα vectors:
  (cs-check "ντετερμινισμός: δεύτερη κλήση ⇒ byte-ταυτόσημη έξοδος σε ΟΛΑ τα vectors"
            (every (lambda (v)
                     (let ((val (cdr (assoc "value" v :test #'string=))))
                       (equal (orchestrator.canonical-representation:canonicalize-json val)
                              (orchestrator.canonical-representation:canonicalize-json val))))
                   vectors))
  (cs-check "ταξινόμηση κλειδιών κατά code point: ελληνικά ΜΕΤΑ τα λατινικά"
            (let ((c (orchestrator.canonical-representation:canonicalize-json
                      '(("τ" . 1) ("a" . 2) ("β" . 3)))))
              (and (< (search "\"a\"" c) (search "\"β\"" c))
                   (< (search "\"β\"" c) (search "\"τ\"" c)))))
  (cs-check "χαρακτήρας ελέγχου ⇒ \\u με ΠΕΖΑ hex (RFC 8785)"
            (search "\\u001f"
                    (orchestrator.canonical-representation:canonicalize-json
                     (list (cons "c" (format nil "a~Ab" (code-char 31))))))))

(format t "~%========================================~%")
(format t "CANONICAL-SERIALIZATION [0088 Φ1β]: ~D passed, ~D failed~%" *cs-pass* *cs-fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *cs-fail*) 0 1))
