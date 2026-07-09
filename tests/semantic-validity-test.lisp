;;;; tests/semantic-validity-test.lisp
;;;; ============================================================================
;;;; P1 SEMANTIC VALIDITY [0043]: τα δημοσιευμένα σημασιολογικά artifacts πρέπει
;;;; να είναι ΕΓΚΥΡΑ για standard parsers — χωρίς καμία αλλαγή νομικής ταυτότητας.
;;;;   A: standalone JSON-LD = ΕΝΑ document (@graph), όχι δύο συνενωμένα objects
;;;;   C: epistemic/release Turtle χωρίς Lisp-παρενθέσεις και χωρίς \" literals
;;;;   D: release manifest.jsonld = top-level JSON object, όχι array
;;;; Εξωτερικοί μάρτυρες (python3 json.tool / rdflib) όταν υπάρχουν στο stage —
;;;; ίδιο πρότυπο με το cross-language-verifier: SKIP όπου λείπουν, ΣΚΛΗΡΟ gate
;;;; στο verifier-conformance stage που τους εγκαθιστά.
;;;; Τρέχει κάτω από docker/run-standalone-test.lisp (self-exit 0/1).

(in-package :orchestrator.cli)

(defvar *svt-pass* 0)
(defvar *svt-fail* 0)

(defmacro svt-check (name form)
  `(handler-case
       (if ,form
           (progn (incf *svt-pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *svt-fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e)
       (incf *svt-fail*)
       (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

(format t "~%── P1 SEMANTIC VALIDITY: έγκυρα JSON-LD / Turtle / manifest ──~%")

;;; Ενεργό corpus για τους config-driven generators (org-name, eli_prefix κ.λπ.)
(orchestrator.spec:select-corpus "syntagma")
(let ((yaml (orchestrator.spec:ensure-config-loaded)))
  (when yaml (orchestrator.uris:load-canonical-uris-from-config yaml)))

;;; Καθαρός single-document έλεγχος: το βάθος αγκίστρων (εκτός string literals)
;;; επιστρέφει στο 0 ΑΚΡΙΒΩΣ στο τέλος — το παλιό διπλό-object επέστρεφε στο 0
;;; στη μέση του κειμένου και ξανάρχιζε.
(defun %svt-single-json-document-p (text)
  (let ((depth 0) (in-string nil) (escaped nil) (closed nil))
    (loop for ch across text do
      (cond (escaped (setf escaped nil))
            (in-string (case ch (#\\ (setf escaped t)) (#\" (setf in-string nil))))
            (t (case ch
                 (#\" (setf in-string t))
                 (#\{ (when closed (return-from %svt-single-json-document-p nil))
                      (incf depth))
                 (#\} (decf depth)
                      (when (zerop depth) (setf closed t)))))))
    (and closed (zerop depth))))

;;; ① A: standalone JSON-LD = ΕΝΑ document, @graph 2 κόμβων, lettered-ασφαλές
(let* ((a (orchestrator.model:make-article :number 5 :title "Άρθρο 5Α - Δικαίωμα στην πληροφόρηση"
                                           :content "Δοκιμαστικό κείμενο."))
       (_ (setf (orchestrator.model:article-label a) "5Α"))
       (doc (orchestrator.engine.sbcl::render-canonical-jsonld a))
       (parsed (jonathan:parse doc))
       (graph (getf parsed :|@graph|)))
  (declare (ignore _))
  (svt-check "①α standalone .jsonld: ΕΝΑ top-level JSON document (όχι «Extra data»)"
             (%svt-single-json-document-p doc))
  (svt-check "①β top-level @context + @graph με ΑΚΡΙΒΩΣ 2 κόμβους (Org + Legislation)"
             (and (equal "https://schema.org" (getf parsed :|@context|))
                  (listp graph) (= 2 (length graph))))
  (let ((org (first graph)) (art (second graph)))
    (svt-check "①γ κόμβος 1 = Organization με @id (WebID) — αμετάβλητος"
               (and (getf org :|@id|)
                    (search "Organization" (format nil "~A" (getf org :|@type|)))))
    (svt-check "①δ κόμβος 2 = Legislation, @id τελειώνει σε /art/5Α (lettered ταυτότητα ΑΘΙΚΤΗ)"
               (let ((id (getf art :|@id|)))
                 (and id (equal "Legislation" (getf art :|@type|))
                      (let ((suffix "/art/5Α"))
                        (and (>= (length id) (length suffix))
                             (string= suffix id :start2 (- (length id) (length suffix))))))))
    ;; ④ αναλλοίωτη ταυτότητας: ο κόμβος άρθρου ΕΙΝΑΙ το αυτούσιο object της
    ;; έδρας generate-jsonld-article — ίδιο @id με το παλιό δεύτερο object.
    (svt-check "①ε ο κόμβος άρθρου ≡ έξοδος της έδρας generate-jsonld-article (ίδιο @id)"
               (let* ((standalone (orchestrator.spec:generate-jsonld-article
                                   "5Α" "Δικαίωμα στην πληροφόρηση"
                                   (orchestrator.spec:calculate-sha256-hash "Δοκιμαστικό κείμενο.")))
                      (solo (jonathan:parse standalone)))
                 (equal (getf solo :|@id|) (getf art :|@id|))))))

;;; ② C1: format-prefixes ⇒ καθαρές γραμμές @prefix (καμία παρένθεση)
(let* ((p (orchestrator.epistemic::format-prefixes))
       (lines (remove "" (uiop:split-string p :separator '(#\Newline)) :test #'equal)))
  (svt-check "②α format-prefixes: ΟΛΕΣ οι γραμμές «@prefix pfx: <iri> .» — καμία «(»"
             (and (plusp (length lines))
                  (every (lambda (l)
                           (and (not (char= #\( (char l 0)))
                                (cl-ppcre:scan "^@prefix [a-z]+: <[^>]+> \\.$" l)))
                         lines))))

;;; ② C: και τα 8 είδη epistemic/release TTL — καμία «(»-γραμμή, κανένα \"
(defun %svt-clean-turtle-p (ttl)
  (and (stringp ttl) (plusp (length ttl))
       (notany (lambda (l) (and (plusp (length l)) (char= #\( (char l 0))))
               (uiop:split-string ttl :separator '(#\Newline)))
       (not (search "\\\"" ttl))))

(let ((ts (orchestrator.time:now :source :system)))
  (svt-check "②β manifest.ttl (build-release-manifest): καθαρό Turtle, literals χωρίς \\\""
             (let ((ttl (orchestrator.epistemic::build-release-manifest
                         '() (uiop:temporary-directory) :timestamp ts)))
               (and (%svt-clean-turtle-p ttl)
                    (search "dcterms:title \"Greek" ttl))))
  (svt-check "②γ meta-ontology.ttl" (%svt-clean-turtle-p
                                     (orchestrator.epistemic::generate-meta-ontology :timestamp ts)))
  (svt-check "②δ negation.ttl" (%svt-clean-turtle-p
                                (orchestrator.epistemic::generate-negation-layer)))
  (svt-check "②ε stability-policy.ttl" (%svt-clean-turtle-p
                                        (orchestrator.epistemic::generate-stability-policy-ttl)))
  (svt-check "②στ lineage-graph.ttl" (%svt-clean-turtle-p
                                      (orchestrator.epistemic::generate-lineage-graph '())))
  (svt-check "②ζ shapes/article-shape.ttl" (%svt-clean-turtle-p
                                            (orchestrator.epistemic::generate-article-shape)))
  (svt-check "②η shapes/manifest-shape.ttl" (%svt-clean-turtle-p
                                             (orchestrator.epistemic::generate-manifest-shape)))

  ;; ③ D: manifest.jsonld = top-level JSON OBJECT με τα κλειδιά ταυτότητας
  (let* ((json (orchestrator.epistemic::build-release-manifest-jsonld
                '() (uiop:temporary-directory) :timestamp ts))
         (parsed (jonathan:parse json)))
    (svt-check "③α manifest.jsonld: αρχίζει με «{» (object, ΟΧΙ array)"
               (char= #\{ (char (string-left-trim '(#\Space #\Newline) json) 0)))
    (svt-check "③β top-level @id/@type/@context παρόντα και σωστά"
               (and (getf parsed :|@id|)
                    (equal "dcat:Catalog" (getf parsed :|@type|))
                    (getf parsed :|@context|)))
    (svt-check "③γ round-trip: ΕΝΑ document, parse χωρίς υπόλοιπο"
               (%svt-single-json-document-p json))))

;;; ⑤ Εξωτερικοί μάρτυρες (python3 / rdflib) — SKIP αν λείπουν, ΣΚΛΗΡΟΙ στο
;;; verifier-conformance stage (εγκαθιστά python3 + python3-rdflib).
(defun %svt-run-ok-p (cmd)
  (handler-case
      (zerop (nth-value 2 (uiop:run-program cmd :ignore-error-status t
                                                :output nil :error-output nil)))
    (error () nil)))

(if (not (%svt-run-ok-p '("python3" "--version")))
    (format t "  SKIP ⑤ python3 απών — εξωτερικοί μάρτυρες μόνο στο verifier-conformance stage~%")
    (let* ((dir (merge-pathnames (format nil "svt-~D/" (get-universal-time))
                                 (uiop:temporary-directory)))
           (a (orchestrator.model:make-article :number 5 :title "Άρθρο 5Α - Τίτλος"
                                               :content "Κείμενο."))
           (ts (orchestrator.time:now :source :system)))
      (ensure-directories-exist dir)
      (setf (orchestrator.model:article-label a) "5Α")
      (flet ((spit (name text)
               (let ((p (merge-pathnames name dir)))
                 (with-open-file (o p :direction :output :if-exists :supersede
                                      :external-format :utf-8)
                   (write-string text o))
                 (namestring p))))
        (let ((jsonld (spit "article.jsonld" (orchestrator.engine.sbcl::render-canonical-jsonld a)))
              (mjson (spit "manifest.jsonld" (orchestrator.epistemic::build-release-manifest-jsonld
                                              '() dir :timestamp ts)))
              (ttl (spit "manifest.ttl" (orchestrator.epistemic::build-release-manifest
                                         '() dir :timestamp ts))))
          (svt-check "⑤α python3 json.tool: standalone article.jsonld ΕΓΚΥΡΟ JSON"
                     (%svt-run-ok-p (list "python3" "-m" "json.tool" jsonld)))
          (svt-check "⑤β python3 json.tool: manifest.jsonld ΕΓΚΥΡΟ JSON"
                     (%svt-run-ok-p (list "python3" "-m" "json.tool" mjson)))
          (if (not (%svt-run-ok-p '("python3" "-c" "import rdflib")))
              (format t "  SKIP ⑤γ/⑤δ rdflib απόν — σκληρό μόνο στο verifier-conformance stage~%")
              (progn
                (svt-check "⑤γ rdflib: manifest.ttl parse-άρεται ως Turtle"
                           (%svt-run-ok-p
                            (list "python3" "-c"
                                  (format nil "from rdflib import Graph; Graph().parse('~A', format='turtle')" ttl))))
                (svt-check "⑤δ rdflib: article.jsonld parse-άρεται ως JSON-LD"
                           (%svt-run-ok-p
                            (list "python3" "-c"
                                  (format nil "from rdflib import Graph; Graph().parse('~A', format='json-ld')" jsonld))))))))
      (ignore-errors (uiop:delete-directory-tree dir :validate (constantly t)))))

(format t "~%========================================~%")
(format t "Semantic validity tests: ~D passed, ~D failed~%" *svt-pass* *svt-fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *svt-fail*) 0 1))
