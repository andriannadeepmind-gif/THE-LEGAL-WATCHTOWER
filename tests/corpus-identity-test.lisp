;;;; tests/corpus-identity-test.lisp
;;;; ============================================================================
;;;; P0 IDENTITY LOCK [0039]/[0041]: κανένα νομικό αντικείμενο χωρίς μοναδική
;;;; ταυτότητα — τα lettered άρθρα (5Α, 370ΣΤ, …) ΔΙΑΚΡΙΤΑ από τα βασικά,
;;;; σε ΚΑΘΕ corpus, σε doc / JSONL / AKN / fingerprint / γραμματική τίτλου.
;;;; ============================================================================
;;;; Ιστορικό: τα stale corpus.jsonl/AKN artifacts είχαν καταρρεύσει τα lettered
;;;; (constitution 124/120, poinikos 529/462 κ.λπ.). Ο ζωντανός κώδικας είναι
;;;; σωστός — αυτό το test ΚΛΕΙΔΩΝΕΙ ότι θα μείνει σωστός: κάθε μελλοντική
;;;; παλινδρόμηση ταυτότητας κοκκινίζει το gated standalone loop.
;;;; Τρέχει κάτω από docker/run-standalone-test.lisp (self-exit 0/1).

(in-package :orchestrator.cli)

(defvar *cit-pass* 0)
(defvar *cit-fail* 0)

(defmacro cit-check (name form)
  `(handler-case
       (if ,form
           (progn (incf *cit-pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *cit-fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e)
       (incf *cit-fail*)
       (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

(format t "~%── P0 IDENTITY LOCK: μοναδικότητα νομικών ταυτοτήτων ανά corpus ──~%")

;;; ① ΚΑΘΕ corpus: πλήθος>0 και eIds ΜΟΝΑΔΙΚΑ (η θεμελιώδης αναλλοίωτη)
(defparameter *cit-docs* '())
(dolist (cid '("syntagma" "poinikos" "kpoinikis" "astikos" "kpolitikis" "kdioikitikis"))
  (multiple-value-bind (short doc) (build-consolidated-for cid)
    (push (list cid short doc) *cit-docs*)
    (let* ((eids (mapcar #'orchestrator.consolidation:provision-eid
                         (orchestrator.consolidation:legal-document-provisions doc)))
           (uniq (remove-duplicates eids :test #'equal)))
      (cit-check (format nil "① ~A: ~D άρθρα, ΟΛΑ με μοναδικό eId" cid (length eids))
                 (and (plusp (length eids)) (= (length eids) (length uniq)))))))
(setf *cit-docs* (nreverse *cit-docs*))

;;; ② Σύνταγμα: τα 4 γνωστά lettered ΠΑΡΟΝΤΑ και τα βασικά τους ΕΠΙΣΗΣ παρόντα
;;;   (μοναδικότητα ① ⇒ διακριτά· εδώ κλειδώνουμε ότι ΥΠΑΡΧΟΥΝ και τα 8)
(let* ((doc (third (assoc "syntagma" *cit-docs* :test #'equal)))
       (eids (mapcar #'orchestrator.consolidation:provision-eid
                     (orchestrator.consolidation:legal-document-provisions doc))))
  (dolist (pair '(("art_5Α" "art_5") ("art_9Α" "art_9")
                  ("art_100Α" "art_100") ("art_101Α" "art_101")))
    (cit-check (format nil "② σύνταγμα: ~A ΚΑΙ ~A παρόντα (διακριτά)" (first pair) (second pair))
               (and (member (first pair) eids :test #'equal)
                    (member (second pair) eids :test #'equal)))))

;;; ③ Γενική αναλλοίωτη lettered: σε ΚΑΘΕ corpus, κάθε lettered eId έχει
;;;   ΔΙΑΦΟΡΕΤΙΚΟ string από το βασικό του — και όπου το βασικό υπάρχει,
;;;   συνυπάρχουν ως ΔΥΟ εγγραφές (καμία σιωπηλή κατάρρευση)
(dolist (entry *cit-docs*)
  (destructuring-bind (cid short doc) entry
    (declare (ignore short))
    (let* ((eids (mapcar #'orchestrator.consolidation:provision-eid
                         (orchestrator.consolidation:legal-document-provisions doc)))
           (lettered (remove-if-not
                      (lambda (e) (cl-ppcre:scan "^art_[0-9]+[Α-Ω]+$" e)) eids))
           (bad (loop for l in lettered
                      for base = (cl-ppcre:regex-replace "[Α-Ω]+$" l "")
                      when (and (member base eids :test #'equal)
                                (= (count l eids :test #'equal) 0))
                        collect l)))
      (cit-check (format nil "③ ~A: ~D lettered, κανένα δεν καταρρέει στο βασικό του"
                         cid (length lettered))
                 (null bad)))))

;;; ④ JSONL serialization (σύνταγμα): γραμμές = άρθρα · ids μοναδικά · art_5Α παρόν
(let* ((doc (third (assoc "syntagma" *cit-docs* :test #'equal)))
       (n (length (orchestrator.consolidation:legal-document-provisions doc)))
       (jsonl (funcall (find-symbol "EMIT-CORPUS-JSONL" :orchestrator.ai-dump) doc))
       (ids '()))
  ;; ΜΟΝΟ article-level eIds (κλειστό pattern με το quote) — τα paragraph
  ;; eIds (art_1__para_1) ΔΕΝ μετρούν στην αναλλοίωτη «μία γραμμή ανά άρθρο».
  (cl-ppcre:do-register-groups (id) ("\"eId\":\"(art_[0-9]+[Α-Ω]*)\"" jsonl)
    (push id ids))
  (cit-check "④ JSONL: μία γραμμή ανά άρθρο, eIds ΜΟΝΑΔΙΚΑ, art_5Α ΚΑΙ art_5 παρόντα"
             (and (= (length ids) n)
                  (= (length ids) (length (remove-duplicates ids :test #'equal)))
                  (member "art_5Α" ids :test #'equal)
                  (member "art_5" ids :test #'equal))))

;;; ⑤ AKN serialization (σύνταγμα): eId attributes άρθρων μοναδικά · art_5Α παρόν
(let* ((doc (third (assoc "syntagma" *cit-docs* :test #'equal)))
       (akn (funcall (find-symbol "EMIT-AKOMA-NTOSO" :orchestrator.akoma-ntoso) doc))
       (eids '()))
  (cl-ppcre:do-register-groups (e) ("eId=\"(art_[^\"_]+)\"" akn)
    (push e eids))
  (cit-check "⑤ AKN: eIds άρθρων ΜΟΝΑΔΙΚΑ, art_5Α ΚΑΙ art_5 παρόντα"
             (and (plusp (length eids))
                  (= (length eids) (length (remove-duplicates eids :test #'equal)))
                  (member "art_5Α" eids :test #'equal)
                  (member "art_5" eids :test #'equal))))

;;; ⑥ Γραμματική τίτλου (η ΜΙΑ είσοδος ταυτότητας): lettered/digraph/απλά/άκυρα
(multiple-value-bind (id heading) (%parse-article-title "Άρθρο 5Α - Δικαίωμα στην πληροφόρηση")
  (cit-check "⑥α «Άρθρο 5Α - …» ⇒ id=5Α + heading"
             (and (equal id "5Α") (equal heading "Δικαίωμα στην πληροφόρηση"))))
(multiple-value-bind (id heading) (%parse-article-title "Άρθρο 370ΣΤ - Ψηφιακά δεδομένα")
  (declare (ignore heading))
  (cit-check "⑥β δίγραφο επίθημα: «Άρθρο 370ΣΤ» ⇒ id=370ΣΤ" (equal id "370ΣΤ")))
(multiple-value-bind (id heading) (%parse-article-title "Άρθρο 5 - Ελεύθερη ανάπτυξη")
  (declare (ignore heading))
  (cit-check "⑥γ απλό: «Άρθρο 5 - …» ⇒ id=5 (ΟΧΙ 5Α)" (equal id "5")))
(multiple-value-bind (id heading) (%parse-article-title "Γενικές διατάξεις")
  (declare (ignore id))
  (cit-check "⑥δ τίτλος χωρίς αριθμό ⇒ NIL + πλήρης τίτλος (τίμιο fallback σήμα)"
             (equal heading "Γενικές διατάξεις")))

;;; ⑦ Fingerprint manifest: 005 και 005Α ⇒ ΔΥΟ διακριτές ταυτότητες art_5/art_5Α
(let ((dir (merge-pathnames (format nil "cit-fp-~D/" (get-universal-time))
                            (uiop:temporary-directory))))
  (ensure-directories-exist dir)
  (dolist (pair '(("005" "aaaa1111") ("005Α" "bbbb2222")))
    (with-open-file (o (merge-pathnames (format nil "article-~A.hash" (first pair)) dir)
                       :direction :output :if-exists :supersede :external-format :utf-8)
      (write-string (second pair) o)))
  (let* ((m (orchestrator.fingerprint:output-manifest dir :id "cit"))
         (eids (mapcar (lambda (r) (getf r :eid))
                       (orchestrator.fingerprint:manifest-articles m))))
    (cit-check "⑦ fingerprint: article-005 + article-005Α ⇒ art_5 ΚΑΙ art_5Α (διακριτά)"
               (and (= 2 (length eids))
                    (member "art_5" eids :test #'equal)
                    (member "art_5Α" eids :test #'equal))))
  (ignore-errors (uiop:delete-directory-tree dir :validate (constantly t))))

;;; ⑧ Latent seat ([0041] 1-line fix): article→normalized ΔΙΑΤΗΡΕΙ το label
(let* ((a (orchestrator.model:make-article :number 5 :title "x" :content "y")))
  (setf (orchestrator.model:article-label a) "5Α")
  (let ((n (orchestrator.model:article-to-normalized-input a :json "test.json")))
    (cit-check "⑧ article(label=5Α) → normalized: το label ΕΠΙΖΕΙ (όχι «5»)"
               (equal "5Α" (orchestrator.model:article-label n)))))
(let* ((a (orchestrator.model:make-article :number 7 :title "x" :content "y"))
       (n (orchestrator.model:article-to-normalized-input a :json "test.json")))
  (cit-check "⑧β χωρίς label ⇒ fallback στον αριθμό «7» (συμβατότητα)"
             (equal "7" (orchestrator.model:article-label n))))

(format t "~%========================================~%")
(format t "Corpus identity tests: ~D passed, ~D failed~%" *cit-pass* *cit-fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *cit-fail*) 0 1))
