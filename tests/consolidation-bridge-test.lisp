;;;; tests/consolidation-bridge-test.lisp
;;;; Verifies the consolidation bridge against the REAL Penal Code corpus
;;;; (deployment/data/poinikoskodikas_clean.json), parsed with jonathan.

(in-package :orchestrator.consolidation.bridge)

(defvar *pass* 0)
(defvar *fail* 0)

(defmacro check (name form)
  `(handler-case
       (if ,form
           (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e)
       (incf *fail*)
       (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

;;; --------------------------------------------------------------------------
;;; Load the real Penal Code corpus
;;; --------------------------------------------------------------------------

(defun slurp (path)
  (with-open-file (s path :direction :input :external-format :utf-8)
    (let ((buf (make-string (file-length s))))
      (subseq buf 0 (read-sequence buf s)))))

(defun %corpus-file (rel)
  "Resolve a repo-relative path in every harness: the CWD (repo root locally, /app
   in the Docker gate), then the known absolute roots as fallbacks. Avoids a
   hardcoded /home path that exists locally but breaks the containerised CI gate."
  (or (probe-file rel)
      (probe-file (merge-pathnames rel #p"/app/"))
      (probe-file (merge-pathnames rel #p"/home/user/STAVROPOULOSLAWCORPUS/"))
      (error "corpus file not found in any known root: ~A" rel)))

(defun load-real-articles ()
  "Parse the real Penal Code JSON into (number title content) triples.
   Article numbers are assigned by position (1..N)."
  (let* ((path (%corpus-file "deployment/data/poinikoskodikas_clean.json"))
         (objs (jonathan:parse (slurp path) :as :alist)))
    (loop for obj in objs
          for n from 1
          collect (list n
                        (cdr (assoc "title" obj :test #'string=))
                        (cdr (assoc "content" obj :test #'string=))))))

(defun %full-text (p)
  "All normative text of provision P — its own text plus every descendant's —
   joined. A multi-paragraph article reads the same whether the source split it
   into child paragraphs or kept «1. … 2. …» as one numbered body, so assertions
   over content are robust to that representation choice."
  (if p
      (string-trim '(#\Space)
                   (format nil "~@[~A ~]~{~A~^ ~}"
                           (provision-text p)
                           (mapcar #'%full-text (provision-children p))))
      ""))

;;; --------------------------------------------------------------------------
;;; Tests
;;; --------------------------------------------------------------------------

(let* ((articles (load-real-articles))
       (doc (articles->document articles :id "poinikos" :title "Ποινικός Κώδικας")))

  (format t "~%== Real corpus -> document ==~%")
  (check "parsed at least 10 real articles" (>= (length articles) 10))
  ;; The art_1 rubric (πλαγιότιτλος) must be present in the corpus — in the
  ;; heading once extraction promotes it (the ΦΕΚ fix), or in the body text on
  ;; older materialisations. Either placement satisfies the real requirement.
  (check "art_1 exists with its real Greek rubric"
         (let ((p (find-provision doc "art_1")))
           (and p (or (search "Καμία ποινή χωρίς νόμο" (or (provision-heading p) ""))
                      (search "Καμία ποινή χωρίς νόμο" (or (provision-text p) ""))))))
  (check "art_1 carries real legal text"
         (search "Έγκλημα δεν υπάρχει χωρίς νόμο"
                 (or (provision-text (find-provision doc "art_1")) "")))
  (check "art_2 is multi-paragraph (carries §1 and §2)"
         (let ((tx (%full-text (find-provision doc "art_2"))))
           (and (search "ευμενέστερη μεταχείριση" tx)     ; paragraph 1
                (search "μη αξιόποινη" tx))))              ; paragraph 2

  ;; Config-shaped amendment records (the ELI-temporal alist format).
  (let ((records
          (list
           ;; A 2010 act that repeals article 3 and amends article 2.
           (list (cons "id" "L3904-2010")
                 (cons "date" "2010-12-23")
                 (cons "date_applicability" "2010-12-23")
                 (cons "fek" "ΦΕΚ Α' 218/2010")
                 (cons "articles_amended" (list 2))
                 (cons "articles_repealed" (list 3)))
           ;; A 2019 act that amends article 1 (provenance only, no new text).
           (list (cons "id" "L4619-2019")
                 (cons "date" "2019-06-11")
                 (cons "date_applicability" "2019-07-01")
                 (cons "fek" "ΦΕΚ Α' 95/2019")
                 (cons "articles_amended" (list 1))
                 (cons "articles_repealed" nil)))))

    (format t "~%== Config records -> acts ==~%")
    (let ((acts (amendment-records->acts records)))
      (check "two acts built" (= 2 (length acts)))
      (check "repeal op derived from articles_repealed"
             (find-if (lambda (op) (and (eq (getf op :op) :repeal)
                                        (string= (getf op :target) "art_3")))
                      (amending-act-operations (first acts))))
      (check "mark-amended op derived from articles_amended"
             (find-if (lambda (op) (and (eq (getf op :op) :mark-amended)
                                        (string= (getf op :target) "art_2")))
                      (amending-act-operations (first acts)))))

    (format t "~%== Point-in-time consolidation on real data ==~%")
    ;; Before any amendment: article 3 present and original.
    (let ((c2000 (consolidate-corpus articles records :as-of-date "2000-01-01" :id "test-corpus")))
      (check "2000: art_3 still original"
             (eq (provision-status (find-provision c2000 "art_3")) :original))
      (check "2000: art_1 not yet amended"
             (eq (provision-status (find-provision c2000 "art_1")) :original)))

    ;; As of 2015: 2010 act applied, 2019 act not.
    (let ((c2015 (consolidate-corpus articles records :as-of-date "2015-01-01" :id "test-corpus")))
      (check "2015: art_3 repealed by L3904-2010"
             (and (eq (provision-status (find-provision c2015 "art_3")) :repealed)
                  (string= (provision-source-act (find-provision c2015 "art_3"))
                           "L3904-2010")))
      (check "2015: art_2 marked amended by L3904-2010"
             (and (eq (provision-status (find-provision c2015 "art_2")) :amended)
                  (string= (provision-source-act (find-provision c2015 "art_2"))
                           "L3904-2010")))
      (check "2015: art_1 not yet amended (2019 act not effective)"
             (eq (provision-status (find-provision c2015 "art_1")) :original)))

    ;; Current consolidation (all acts).
    (let ((current (consolidate-corpus articles records :id "test-corpus")))
      (check "current: art_1 amended by L4619-2019"
             (string= (provision-source-act (find-provision current "art_1"))
                      "L4619-2019"))
      (check "current: art_2 text preserved under mark-amended"
             ;; Stronger than a child count: the full normative text is BYTE-
             ;; IDENTICAL before and after mark-amended — provenance changes, text
             ;; does not.
             (string= (%full-text (find-provision doc "art_2"))
                      (%full-text (find-provision current "art_2"))))
      (check "current: repealed art_3 omitted from in-force text"
             ;; Behavioural, data-robust assertion: art_3 is repealed, and the
             ;; in-force rendering is strictly shorter than the include-repealed
             ;; rendering precisely because the repealed article is dropped.
             (and (eq (provision-status (find-provision current "art_3")) :repealed)
                  (let ((in-force (render-consolidated-text current))
                        (with-repealed (render-consolidated-text current :include-repealed t)))
                    (< (length in-force) (length with-repealed)))))
      (check "current: provenance TTL references the amending acts"
             (let ((ttl (render-consolidation-provenance-ttl current)))
               (and (search "act/L3904-2010" ttl)
                    (search "act/L4619-2019" ttl)
                    (search "eli:repealed_by" ttl)))))

    (format t "~%== Determinism on real data ==~%")
    (check "consolidated text identical across runs"
           (string= (render-consolidated-text (consolidate-corpus articles records :id "test-corpus"))
                    (render-consolidated-text (consolidate-corpus articles records :id "test-corpus"))))
    (check "base articles list not mutated"
           (eq (provision-status (find-provision doc "art_3")) :original))))

(format t "~%========================================~%")
(format t "Consolidation bridge tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
