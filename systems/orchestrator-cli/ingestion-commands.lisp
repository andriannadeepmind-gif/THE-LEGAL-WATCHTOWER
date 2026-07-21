;;;; systems/orchestrator-cli/ingestion-commands.lisp
;;;; ============================================================================
;;;; ΕΝΤΟΛΕΣ ΦΕΚ & ΔΑΙΜΟΝΑ — discovery/routing, τροποποιητικές πράξεις, φύλακας
;;;; ΦΕΚ, προτάσεις αναβάθμισης (consent), αγεντικός κύκλος.
;;;; ============================================================================
;;;;
;;;; Αποδόμηση θεού-φακέλου #3. 14 αμιγώς δαιμονικές/αναβάθμισης συναρτήσεις,
;;;; εσωτερικά κλειστές (καλούν μόνο η μία την άλλη + τον ΣΤΑΘΕΡΟ πυρήνα του main:
;;;; materialize-served-corpora, build-active-consolidated-document, corpus-spec
;;;; records, fingerprint). Φορτώνεται ΤΕΛΕΥΤΑΙΟ (μετά το main) → κάθε βοηθός
;;;; πυρήνα ήδη ορισμένος, μηδέν forward-reference — ίδιο πρότυπο με decisions.lisp.
;;;; Οι εντολές του εγγράφονται στο μητρώο· το main δεν τις αγγίζει.

(in-package :orchestrator.cli)

(defun %fresh-articles-from-source (id)
  "Parse THIS corpus's source (pdf/docx) into (title . content-string) pairs —
   exactly what materialize WOULD write, but WITHOUT touching anything. NIL when
   there is no digital source or it yields nothing."
  (orchestrator.spec:select-corpus id)
  (ignore-errors (orchestrator.gr-syntagma:register-active-corpus))
  (let* ((docx (ignore-errors (orchestrator.spec:resolve-config-path "source.docx")))
         (pdf  (ignore-errors (orchestrator.spec:resolve-config-path "source.pdf")))
         (src  (cond ((and docx (plusp (length docx)) (probe-file docx)) docx)
                     ((and pdf (plusp (length pdf)) (probe-file pdf)) pdf)
                     (t nil))))
    (when src
      (let ((iirs (if (string-equal (or (pathname-type src) "") "docx")
                      (orchestrator.engine.sbcl:docx-adapter src)
                      (orchestrator.engine.sbcl:pdf-adapter src)))
            (title-fn (find-symbol "ARTICLE-TITLE" :orchestrator.model))
            (content-fn (find-symbol "ARTICLE-CONTENT" :orchestrator.model)))
        (when iirs
          ;; [Π7-U.1 Φ1γ] Τα errata εφαρμόστηκαν ΗΔΗ μέσα στον adapter (η ΜΙΑ
          ;; έδρα στο όριο εξαγωγής) — το diff μένει τίμιο χωρίς δεύτερη κλήση.
          (loop for iir in iirs
                collect (cons (princ-to-string (funcall title-fn iir))
                              (princ-to-string (funcall content-fn iir)))))))))

(defun %served-articles (id)
  "The CURRENTLY served (title . content-string) pairs from source.json."
  (handler-case
      (progn
        (orchestrator.spec:select-corpus id)
        (let* ((jp (orchestrator.spec:resolve-config-path "source.json"))
               (objs (jonathan:parse (uiop:read-file-string jp :external-format :utf-8)
                                     :as :alist)))
          (loop for o in objs
                collect (cons (or (cdr (assoc "title" o :test #'string=)) "")
                              (let ((c (cdr (assoc "content" o :test #'string=))))
                                (format nil "~{~A~^ ~}" (if (listp c) c (list c))))))))
    (error () nil)))

(defun %corpus-upgrade-diff (id)
  "Compare the FRESH parse of the source against the SERVED corpus, keyed by
   article id. Returns (values added removed changed) — lists of article ids —
   or :no-source when there is no digital source to compare."
  (let ((fresh (%fresh-articles-from-source id)))
    (if (null fresh)
        :no-source
        (let ((fh (make-hash-table :test 'equal))
              (sh (make-hash-table :test 'equal))
              (added '()) (removed '()) (changed '()))
          (dolist (a fresh) (setf (gethash (%title-key (car a)) fh) (cdr a)))
          (dolist (a (%served-articles id)) (setf (gethash (%title-key (car a)) sh) (cdr a)))
          (maphash (lambda (k fv)
                     (multiple-value-bind (sv hit) (gethash k sh)
                       (cond ((not hit) (push k added))
                             ((not (string= (%normspace fv) (%normspace sv))) (push k changed)))))
                   fh)
          (maphash (lambda (k v) (declare (ignore v))
                     (unless (nth-value 1 (gethash k fh)) (push k removed))) sh)
          (values (sort added #'string<) (sort removed #'string<) (sort changed #'string<))))))

(defun %consolidation-proposal (id)
  "What the NEW consolidation (source + all amendment records, incl. freshly
   discovered ΦΕΚ) would change versus the LOCKED golden — added/removed/
   changed article eIds. NIL when identical or no golden exists yet."
  (handler-case
      (multiple-value-bind (short doc) (build-consolidated-for id)
        (let* ((fp (find-package :orchestrator.fingerprint))
               (manifest (funcall (find-symbol "CORPUS-FINGERPRINT" fp) doc))
               (gp (%corpus-golden-file short)))
          (when (probe-file gp)
            (let* ((golden (funcall (find-symbol "READ-FINGERPRINT-MANIFEST" fp) gp))
                   (diff (funcall (find-symbol "FINGERPRINT-DIFF" fp) golden manifest)))
              (unless (funcall (find-symbol "DIFF-CLEAN-P" fp) diff)
                diff)))))
    (error () nil)))

(defun run-watch-fek ()
  "Ένας κύκλος του ΔΑΙΜΟΝΑ σε πολιτική PROPOSE — το χειροκίνητο «για δες τώρα»
   είναι ΤΟ ΙΔΙΟ μονοπάτι με το συνεχές ρολόι, όχι δεύτερος μηχανισμός."
  (sb-posix:setenv "ORCHESTRATOR_POLICY" "propose" 1)
  (sb-posix:setenv "INGEST_MAX_POLLS" "1" 1)
  (run-ingestion-daemon)
  0)

(defun run-check-upgrades ()
  "ΠΡΟΤΑΣΗ ΑΝΑΒΑΘΜΙΣΗΣ — δεν αγγίζει ΤΙΠΟΤΑ. Για κάθε σώμα, συγκρίνει την ΦΡΕΣΚΙΑ
   ανάγνωση της πηγής (π.χ. ένα νεότερο PDF που έριξες, ή τις ενοποιημένες
   τροποποιήσεις από --discover-fek) με το ΣΕΡΒΙΡΙΖΟΜΕΝΟ κείμενο, και αναφέρει
   άρθρο-άρθρο τι ΘΑ άλλαζε. Στο τέλος ζητά ΡΗΤΗ έγκριση: τίποτα δεν εφαρμόζεται
   χωρίς το «--apply-upgrade». Έτσι το σύστημα αυτο-αναβαθμίζεται ΜΕ ΤΗ ΣΥΓΚΑΤΑΘΕΣΗ
   σου — ανιχνεύει και προτείνει, δεν αποφασίζει."
  (format t "~%═══ ΕΛΕΓΧΟΣ ΑΝΑΒΑΘΜΙΣΕΩΝ (πρόταση — καμία αλλαγή) ═══~%")
  (let ((any nil))
    (dolist (id *served-corpora*)
      (handler-case
          (multiple-value-bind (added removed changed) (%corpus-upgrade-diff id)
            (cond
              ((eq added :no-source)
               (format t "  – ~A: καμία ψηφιακή πηγή για σύγκριση~%" id))
              ((and (null added) (null removed) (null changed))
               (format t "  ✓ ~A: ενήμερο (η πηγή ταυτίζεται με το σερβιριζόμενο)~%" id))
              (t
               (setf any t)
               (format t "~%  ⬆ ~A: ΔΙΑΘΕΣΙΜΗ ΑΝΑΒΑΘΜΙΣΗ~%" id)
               (when added
                 (format t "     + ~D νέα άρθρα: ~{~A~^, ~}~@[ …~]~%"
                         (length added) (subseq added 0 (min 12 (length added)))
                         (> (length added) 12)))
               (when removed
                 (format t "     − ~D άρθρα προς αφαίρεση: ~{~A~^, ~}~@[ …~]~%"
                         (length removed) (subseq removed 0 (min 12 (length removed)))
                         (> (length removed) 12)))
               (when changed
                 (format t "     ~~ ~D τροποποιημένα άρθρα: ~{~A~^, ~}~@[ …~]~%"
                         (length changed) (subseq changed 0 (min 12 (length changed)))
                         (> (length changed) 12))))))
        (error (e) (format t "  ✗ ~A: ~A~%" id e))))
    (if any
        (format t "~%➤ Για να ΕΓΚΡΙΝΕΙΣ και να εφαρμόσεις: --apply-upgrade~%   (υλικοποιεί, ξανακλειδώνει golden, τρέχει πλήρη έλεγχο — με την δική σου εντολή)~%")
        (format t "~%✓ Όλα ενήμερα — καμία αναβάθμιση διαθέσιμη.~%"))
    0))

(defun run-apply-upgrade ()
  "ΕΓΚΡΙΣΗ: εφαρμόζει τις προτεινόμενες αναβαθμίσεις — υλικοποιεί από τις πηγές,
   ξανακλειδώνει τα golden αποτυπώματα και τρέχει τον πλήρη έλεγχο. Καλείται ΜΟΝΟ
   μετά από --check-upgrades και ρητή απόφαση του χρήστη."
  (format t "~%═══ ΕΦΑΡΜΟΓΗ ΑΝΑΒΑΘΜΙΣΗΣ (με έγκρισή σου) ═══~%")
  (materialize-pdf-sources)
  (sb-posix:setenv "GOLDEN_WRITE" "1" 1)
  (let ((rc (verify-all-corpora)))
    ;; οι χρονικές ετυμηγορίες των αποθηκευμένων αποφάσεων επανυπολογίζονται —
    ;; ένα άρθρο που μόλις άλλαξε μπορεί να γύρισε δεδικασμένα σε «amended-after».
    (ignore-errors (run-materialize-decisions))
    (format t "~%✓ Αναβάθμιση εφαρμόστηκε & κλειδώθηκε. Κάνε git commit/push για μονιμότητα.~%")
    rc))

(defun %fek-discover-only ()
  "Bounded ΝΤΕΤΕΡΜΙΝΙΣΤΙΚΗ ανακάλυψη: FEK_DISCOVER_ONLY=103,105,239 → (103 105 239)
   ταξινομημένα/χωρίς διπλότυπα· NIL αν άδειο. Μετατρέπει το backtest από walk
   (μη-ντετερμινιστικό, δικτυακά ευρύ) σε στοχευμένο σύνολο — το §Superior του
   FEK-COMPILER φάση β': μόνιμο, φθηνό, χωρίς walk."
  (let ((s (%non-blank (uiop:getenv "FEK_DISCOVER_ONLY"))))
    (when s
      (flet ((whole-pos (tok)
               ;; ΟΛΟΚΛΗΡΟ θετικό ακέραιο (εύρημα κριτή C): «103abc»/«-5»/«1.5»
               ;; ΑΠΟΡΡΙΠΤΟΝΤΑΙ (NIL) αντί για σιωπηλή αναδιαμόρφωση σε 103/-5/1.
               (let ((tok (string-trim '(#\Space #\Tab) tok)))
                 (when (and (plusp (length tok)) (every #'digit-char-p tok))
                   (let ((n (parse-integer tok))) (and (plusp n) n))))))
        (sort (remove-duplicates
               (remove nil (mapcar #'whole-pos
                                   (uiop:split-string s :separator '(#\, #\Space #\Tab #\Newline)))))
              #'<)))))

(defun %backtest-entry (fek-label measurement buckets)
  "Μία εγγραφή report ΑΠΟ ΤΗΝ ΕΔΡΑ measure-extraction (ΟΧΙ log-grep): structured
   metrics ενός ΦΕΚ. Οι ρητοί λόγοι → double για JSON."
  (flet ((r (k) (let ((v (getf measurement k))) (and v (float v 1d0)))))
    (list :fek fek-label
          :extracted (getf measurement :extracted)
          :routed (getf measurement :routed)
          :unrouted (getf measurement :unrouted)
          :self-reference (getf measurement :self-reference)
          :identity-contradicted (getf measurement :identity-contradicted)
          :census-consistency (r :census-consistency)
          :ops-per-structural-verb (r :ops-per-structural-verb)
          :routed-buckets (length buckets)
          :buckets buckets)))

(defun %backtest-report->json (entries)
  "Ντετερμινιστικό JSON του backtest report (λίστα από %backtest-entry). Καθαρή
   συνάρτηση — gated-testable χωρίς δίκτυο. Καταναλώνει ΤΗ ΜΙΑ cli scalar έδρα
   %json-scalar (καμία inline null/string/number διάκριση — νόμος «0 διπλά»)."
  (with-output-to-string (s)
    (write-char #\[ s)
    (loop for e in entries for first = t then nil do
      (unless first (write-char #\, s))
      (flet ((j (k) (%json-scalar (getf e k))))
        (format s "{\"fek\":~A,\"extracted\":~A,\"routed\":~A,\"unrouted\":~A,~
                   \"self_reference\":~A,\"identity_contradicted\":~A,~
                   \"census_consistency\":~A,\"ops_per_structural_verb\":~A,~
                   \"routed_buckets\":~A,\"buckets\":[~{~A~^,~}]}"
                (j :fek) (j :extracted) (j :routed) (j :unrouted) (j :self-reference)
                (j :identity-contradicted) (j :census-consistency)
                (j :ops-per-structural-verb) (j :routed-buckets)
                (mapcar #'%json-scalar (getf e :buckets)))))
    (write-char #\] s)))

(defun %census-article-oracle ()
  "Μαντείο ταυτότητας: (corpus-id base-article-id) → T / NIL / :unknown, από τα
   census.json των ΤΕΛΕΥΤΑΙΩΝ attested releases (η κρυπτογραφημένη ταυτότητα του
   κάθε served κώδικα — ό,τι πράγματι περιέχει, όχι ό,τι υποθέτουμε). :unknown
   όταν δεν υπάρχει census για τον κώδικα (π.χ. καθαρό checkout) — τίμια άγνοια,
   ο extractor τότε ΔΕΝ προβάλλει αξίωση ταυτότητας."
  (let ((cache (make-hash-table :test 'equal))
        (root (uiop:ensure-directory-pathname
               (or (uiop:getenv "ORCHESTRATOR_OUTPUT_DIR")
                   (orchestrator.paths:institution-dir "output")))))
    (flet ((ids-for (code)
             (multiple-value-bind (v present) (gethash code cache)
               (if present v
                   (setf (gethash code cache)
                         ;; Μέσω latest.json (ΟΧΙ symlink — φορητό και σε Windows
                         ;; checkout όπου το symlink είναι αρχείο) + ΜΟΝΟ αν
                         ;; attested:true (εύρημα κριτή #3: το docstring οφείλει
                         ;; να είναι αληθές). Legacy-era latest χωρίς census ⇒
                         ;; NIL ⇒ :unknown — τίμια προ-census εποχή.
                         (let* ((lj (merge-pathnames
                                     (format nil "~A/releases/latest.json" code) root))
                                (rel (and (probe-file lj)
                                          (handler-case
                                              (let ((d (jonathan:parse
                                                        (uiop:read-file-string lj)
                                                        :as :hash-table)))
                                                (and (eq (gethash "attested" d) t)
                                                     (gethash "release" d)))
                                            (error () nil))))
                                (path (and (stringp rel)
                                           (probe-file
                                            (merge-pathnames
                                             (format nil "~A/releases/~A/census.json"
                                                     code rel)
                                             root)))))
                           (when path
                             (handler-case
                                 (let* ((doc (jonathan:parse (uiop:read-file-string path)
                                                             :as :hash-table))
                                        (arts (gethash "articles" doc))
                                        (set (make-hash-table :test 'equal)))
                                   (dolist (a arts set)
                                     (let ((id (gethash "id" a)))
                                       (when (stringp id) (setf (gethash id set) t)))))
                               (error () nil)))))))))
      (lambda (code base-id)
        (let ((set (ids-for code)))
          (cond ((null set) :unknown)
                ((gethash base-id set) t)
                (t nil)))))))

(defun discover-fek ()
  "ΦΕΚ DISCOVERY → routing: given a listing of recently published gazettes, decide
   which served code(s) each one amends, using the legal-id registry. This is the
   'νόηση που κρίνει' — it tells cron WHICH codes have pending updates, without a
   human. Network stays at the edge: the headless fetcher writes a JSON listing
   (array of {title,url[,number,year]}); FEK_LISTING_JSON points here. Read-only."
  (let* ((lid :orchestrator.legal-id)
         (registry (build-legal-id-registry))
         (path (%non-blank (uiop:getenv "FEK_LISTING_JSON"))))
    (format t "~%╔══ ΑΝΑΚΑΛΥΨΗ ΦΕΚ → δρομολόγηση σε κώδικες ══╗~%")
    (format t "Μητρώο: ~D κώδικες~%" (length registry))
    ;; NATIVE enumeration — no external listing/.js needed. With FEK_DISCOVER_YEAR
    ;; (optional FEK_DISCOVER_FROM = last-seen number) the discovery walks the public
    ;; ΦΕΚ blob and reports every gazette at or after FROM — proven live (ΦΕΚ Α'
    ;; 2025 enumerates to #245). The blob URLs feed --fetch-amendments for routing.
    (unless (and path (probe-file path))
      (let* ((enum (find-symbol "ENUMERATE-NEW-FEK" :orchestrator.document-fetch))
             (url-of (find-symbol "FEK-BLOB-URL" :orchestrator.document-fetch))
             (year-s (%non-blank (uiop:getenv "FEK_DISCOVER_YEAR")))
             (year (and year-s (ignore-errors (parse-integer year-s))))
             ;; FROM = explicit override, else resume after the persisted last-seen,
             ;; else 1. So a cron run only ever processes genuinely-new gazettes.
             (from (or (ignore-errors (parse-integer (or (%non-blank (uiop:getenv "FEK_DISCOVER_FROM")) "")))
                       (let ((ls (%read-last-seen))) (and ls (1+ ls)))
                       1))
             (series (or (%non-blank (uiop:getenv "FEK_DISCOVER_SERIES")) "Α"))
             (only (%fek-discover-only)))     ; bounded ντετερμινιστικό σύνολο ή NIL
        (cond
          ((and enum url-of year)
           (if only
               (format t "~%[native] Bounded backtest ΦΕΚ ~A' ~D: {~{~D~^, ~}} (ντετερμινιστικό)…~%"
                       series year only)
               (format t "~%[native] Ανακάλυψη ΦΕΚ ~A' ~D από #~D (blob enumeration)…~%" series year from))
           (let ((nums (or only (funcall enum series year :from from)))
                 ;; FEK_ANALYZE=1 closes the loop: fetch each new gazette, extract its
                 ;; text, run the amendment extractor, and — when AMENDMENT_LAWS_JSON is
                 ;; set — RECORD every gazette that amends a served code, which
                 ;; consolidation then folds in automatically. Off by default (network).
                 (analyze (string= "1" (or (%non-blank (uiop:getenv "FEK_ANALYZE")) "0")))
                 (laws-out (%non-blank (uiop:getenv "AMENDMENT_LAWS_JSON")))
                 (blob-fetch (find-symbol "FETCH-FEK-BLOB" :orchestrator.document-fetch))
                 (extract-txt (find-symbol "EXTRACT-TEXT-FROM-PDF" :orchestrator.pdf-authority))
                 (extract-ops (find-symbol "EXTRACT-OPERATIONS" :orchestrator.amendment-extractor))
                 (summarize (find-symbol "SUMMARIZE-OPERATIONS" :orchestrator.amendment-extractor))
                 ;; [FEK-COMPILER] Δρομολόγηση από τη ΜΙΑ έδρα (registry των
                 ;; configs) με ΔΟΜΙΚΗ κληρονομιά scope + επαλήθευση κατά της
                 ;; ταυτότητας του served corpus (τα eIds του census του).
                 (resolver (funcall (find-symbol "MAKE-REGISTRY-RESOLVER"
                                                 :orchestrator.amendment-extractor)
                                    registry))
                 (art-exists (%census-article-oracle))
                 ;; [FEK-COMPILER β'] Structured backtest report ΑΠΟ ΤΗΝ ΕΔΡΑ
                 ;; measure-extraction (ΟΧΙ log-grep). FEK_BACKTEST_REPORT=<path>.
                 (report-path (%non-blank (uiop:getenv "FEK_BACKTEST_REPORT")))
                 (measure (find-symbol "MEASURE-EXTRACTION" :orchestrator.amendment-extractor))
                 (report '())
                 (new-laws '()))
             (dolist (n nums)
               (format t "  + ΦΕΚ ~A' ~D/~D → ~A~%" series n year (funcall url-of series n year))
               (when (and analyze blob-fetch extract-txt extract-ops summarize)
                 (let ((tmp (format nil "/tmp/fek-~A-~D-~D.pdf" series n year)))
                   (when (funcall blob-fetch series n year tmp)
                     (let* ((text (ignore-errors (funcall extract-txt tmp)))
                            ;; «0 διπλά»: ΜΙΑ εξαγωγή ανά ΦΕΚ — log (summarize) ΚΑΙ
                            ;; report (measure-extraction) από τις ΙΔΙΕΣ ops.
                            (ops (and text (funcall extract-ops text
                                                    :code-resolver resolver
                                                    :article-exists-fn art-exists)))
                            (summary (and ops (funcall summarize ops)))
                            ;; buckets with a real (non-NIL) code → this ΦΕΚ amends a served code
                            (touches (remove nil (mapcar #'car summary))))
                       (if summary
                           (dolist (g summary)
                             (format t "      ⮑ ~A : ~{~A~^, ~}~%"
                                     (or (car g) "(αδρομολόγητο)")
                                     (mapcar (lambda (o) (format nil "~A[~(~A~)]"
                                                                 (getf o :target) (getf o :op)))
                                             (cdr g))))
                           (format t "      ⮑ (καμία τροποποίηση κώδικα)~%"))
                       ;; [β'] structured metrics ΑΠΟ ΤΗΝ ΕΔΡΑ (όχι log-grep)
                       (when (and report-path measure)
                         (push (%backtest-entry
                                (format nil "~A' ~D/~D" series n year)
                                ;; «0 διπλά»: ΟΙ ΙΔΙΕΣ ops του log — καμία 2η εξαγωγή
                                (funcall measure text :ops ops
                                                      :code-resolver resolver
                                                      :article-exists-fn art-exists)
                                touches)
                               report))
                       ;; record the amending law's TEXT so consolidation auto-folds it
                       (when (and laws-out touches text)
                         (push (list (cons "id"   (format nil "ΦΕΚ ~A' ~D/~D" series n year))
                                     (cons "date" "")
                                     (cons "fek"  (format nil "~A' ~D/~D" series n year))
                                     (cons "text" text))
                               new-laws)))
                     (ignore-errors (delete-file tmp))))))
             ;; PERSIST: merge the newly-discovered amending laws into AMENDMENT_LAWS_JSON
             ;; (idempotent, dedup by id), and advance the last-seen cursor.
             (when (and laws-out new-laws)
               (let ((merged (%merge-laws (%read-laws-json laws-out) (nreverse new-laws))))
                 (ignore-errors
                  (ensure-directories-exist laws-out)
                  (with-open-file (o laws-out :direction :output :if-exists :supersede
                                              :if-does-not-exist :create :external-format :utf-8)
                    (write-string (%laws->json merged) o)))
                 (format t "  ✎ ~D τροποποιητικά → ~A (σύνολο ~D)~%" (length new-laws) laws-out (length merged))))
             ;; Bounded backtest ΔΕΝ προχωρά τον cursor (στοχευμένο, όχι forward scan).
             (when (and nums (not only)) (%write-last-seen (reduce #'max nums)))
             ;; [β'] γράψε το structured report ΑΠΟ ΤΗΝ ΕΔΡΑ (deterministic JSON)
             (when (and report-path report)
               (ensure-directories-exist report-path)
               (with-open-file (o report-path :direction :output :if-exists :supersede
                                              :if-does-not-exist :create :external-format :utf-8)
                 (write-string (%backtest-report->json (nreverse report)) o))
               (format t "  ⎘ backtest report (~D ΦΕΚ) → ~A~%" (length report) report-path))
             (format t "~%~D ~:[νέα ΦΕΚ~;ΦΕΚ (bounded)~]· ~D αγγίζουν κώδικες.~:[~; --auto-update τα ενοποιεί & υπογράφει.~]~%"
                     (length nums) only (length new-laws) (and analyze laws-out))
             (return-from discover-fek 0)))
          (t
           (format t "~%ℹ Δώσε FEK_LISTING_JSON=<JSON [{title,url}]>, Ή FEK_DISCOVER_YEAR=<έτος> [FEK_DISCOVER_FROM=<αριθμός>]~%")
           (format t "  για εγγενή ανακάλυψη ΦΕΚ από το δημόσιο blob (χωρίς εξωτερικό fetcher).~%")
           (return-from discover-fek 0)))))
    (let* ((raw (uiop:read-file-string path :external-format :utf-8))
           (listing (jonathan:parse raw :as :alist))
           ;; jonathan returns a single alist for one object; normalize to a list.
           (listing (if (and listing (consp (car listing)) (stringp (caar listing)))
                        (list listing) listing))
           (routed (funcall (find-symbol "ROUTE-LISTING" lid) registry listing))
           (pending (make-hash-table :test 'equal)) (n 0))
      (dolist (r routed)
        (let* ((item (getf r :item)) (corpora (getf r :corpora))
               (title (cdr (assoc "title" item :test #'string=))))
          (incf n)
          (if corpora
              (progn (format t "  → ~{~A~^, ~}  ⟵  ~A~%" corpora title)
                     (dolist (c corpora) (setf (gethash c pending) t)))
              (format t "  – (κανένας κώδικας)  ⟵  ~A~%" title))))
      (format t "~%~D ΦΕΚ εξετάστηκαν· κώδικες με εκκρεμείς ενημερώσεις: ~:[(κανένας)~;~:*~{~A~^, ~}~]~%"
              n (loop for k being the hash-keys of pending collect k))
      (format t "  Τρέξε --auto-update για να ενημερωθούν από την πηγή.~%")
      0)))

;;; ── EDGE: discovered laws → their TEXT → AMENDMENT_LAWS_JSON (closes the loop) ──

(defun %read-laws-json (path)
  "Read an AMENDMENT_LAWS_JSON file into a list of law alists ({id,date,fek,text}),
   or NIL if absent/unreadable. A single object normalises to a one-law list."
  (when (and path (probe-file path))
    (ignore-errors
     (let ((laws (jonathan:parse (uiop:read-file-string path :external-format :utf-8) :as :alist)))
       (if (and laws (consp (car laws)) (stringp (caar laws))) (list laws) laws)))))

(defun %merge-laws (existing new)
  "Merge NEW law alists into EXISTING, deduplicating by \"id\" so a re-discovered ΦΕΚ
   is never recorded twice. Stable: EXISTING order preserved, genuinely-new appended.
   This makes the discovery idempotent — running it again adds only what is new."
  (let ((seen (make-hash-table :test 'equal)) (out '()))
    (flet ((id (l) (cdr (assoc "id" l :test #'string=))))
      (dolist (l existing) (setf (gethash (id l) seen) t) (push l out))
      (dolist (l new) (unless (gethash (id l) seen) (setf (gethash (id l) seen) t) (push l out))))
    (nreverse out)))

;;; KEYED CURSOR — one persisted-state mechanism, many streams. The ΦΕΚ guard was
;;; the first user (key "fek"); the jurisprudence watcher adds "ap:politikes:2015",
;;; "ap:poinikes:2026", … Each key remembers the highest number already processed
;;; on its stream, so a run resumes after it. No second state store, ever.

(defun fetch-amendments ()
  "EDGE step that closes discovery → consolidation. Read the discovered ΦΕΚ listing
   (FEK_LISTING_JSON), keep the laws that amend a served code, download each one's PDF
   (its blob url, pure-Lisp drakma), extract its text (libpoppler), and write
   AMENDMENT_LAWS_JSON [{id,date,fek,text}] — which corpus-spec then folds into every
   consolidation automatically. Network + libpoppler edge; idempotent; never throws."
  (let* ((lst (%non-blank (uiop:getenv "FEK_LISTING_JSON")))
         (out (or (%non-blank (uiop:getenv "AMENDMENT_LAWS_JSON"))
                  (namestring (merge-pathnames "amendment-laws.json" (%state-dir)))))
         (fetch (find-symbol "FETCH-URL-PDF" :orchestrator.document-fetch))
         (extract (find-symbol "EXTRACT-TEXT-FROM-PDF" :orchestrator.pdf-authority)))
    (unless (and lst (probe-file lst))
      (format t "✗ FEK_LISTING_JSON απουσιάζει — τρέξε πρώτα τη discovery (discover-fek.js).~%")
      (return-from fetch-amendments 1))
    (let* ((raw (uiop:read-file-string lst :external-format :utf-8))
           (listing (jonathan:parse raw :as :alist))
           (listing (if (and listing (consp (car listing)) (stringp (caar listing))) (list listing) listing))
           (registry (build-legal-id-registry))
           (routed (funcall (find-symbol "ROUTE-LISTING" :orchestrator.legal-id) registry listing))
           (laws '()) (n 0))
      (format t "~%╔══ ΛΗΨΗ ΤΡΟΠΟΠΟΙΗΤΙΚΩΝ ΝΟΜΩΝ → ~A ══╗~%" out)
      (dolist (r routed)
        (let* ((item (getf r :item)) (corpora (getf r :corpora))
               (url (cdr (assoc "url" item :test #'string=)))
               (num (cdr (assoc "number" item :test #'string=)))
               (year (cdr (assoc "year" item :test #'string=)))
               (fek (cdr (assoc "fek" item :test #'string=)))
               (date (%iso-date (cdr (assoc "date" item :test #'string=)))))
          (when (and corpora url)
            (let ((tmp (format nil "/tmp/amend-~A-~A.pdf" (or num "x") (random 100000))))
              (multiple-value-bind (ok status) (funcall fetch url tmp)
                (if ok
                    (let ((text (ignore-errors (funcall extract tmp))))
                      (if (and text (> (length text) 200))
                          (progn
                            (push (list (cons "id" (format nil "ν. ~A/~A" num year))
                                        (cons "date" (or date (and year (format nil "~A-01-01" year))))
                                        (cons "fek" (or fek ""))
                                        (cons "text" text))
                                  laws)
                            (incf n)
                            (format t "  ✓ ν. ~A/~A → ~D χαρ.  ⟶ ~{~A~^, ~}~%" num year (length text) corpora))
                          (format t "  ⚠ ν. ~A/~A: κενό/σαρωμένο κείμενο — παραλείπεται~%" num year)))
                    (format t "  ✗ ν. ~A/~A: λήψη απέτυχε (~A)~%" num year status)))
              (ignore-errors (delete-file tmp))))))
      (ensure-directories-exist out)
      (with-open-file (o out :direction :output :if-exists :supersede :if-does-not-exist :create
                            :external-format :utf-8)
        (write-string (%laws->json (nreverse laws)) o))
      (format t "~%~D τροποποιητικ~:@P νόμ~:@P γράφτηκαν → ~A.~%" n out)
      (format t "  Η consolidation (serve/audit/point-in-time) θα τους εφαρμόσει ΑΥΤΟΜΑΤΑ.~%")
      0)))

(defun %write-daemon-status (cycle policy proposals pending)
  "Heartbeat του δαίμονα: μηχανικά αναγνώσιμη κατάσταση στο
   deployment/state/daemon-status.json — τελευταίος κύκλος, πολιτική,
   εκκρεμείς εγκρίσεις, προτάσεις ανά κώδικα. Ο άνθρωπος (ή ένα UI) βλέπει
   με μια ματιά τι περιμένει το ΝΑΙ του."
  (ignore-errors
    (let ((path (merge-pathnames "deployment/state/daemon-status.json" (orchestrator.paths:institution-root))))
      (ensure-directories-exist path)
      (multiple-value-bind (sec min hr day mo yr) (decode-universal-time (get-universal-time) 0)
        (with-open-file (o path :direction :output :if-exists :supersede
                               :if-does-not-exist :create :external-format :utf-8)
          (write-string
           (jonathan:to-json
            (list (cons "utc" (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ"
                                      yr mo day hr min sec))
                  (cons "cycle" cycle)
                  (cons "policy" (string-downcase (symbol-name policy)))
                  (cons "pending_review" pending)
                  (cons "proposals" (or proposals #())))
            :from :alist)
           o))))))

(defun %daemon-cycle (cycle policy review-queue)
  "Ο ΑΓΕΝΤΙΚΟΣ ΚΥΚΛΟΣ — οι ντετερμινιστικοί ρόλοι του δαίμονα, με την σειρά:
     ΦΡΟΥΡΟΣ    discover-fek: νέα ΦΕΚ Α΄ από τον persisted cursor
     ΚΟΜΙΣΤΗΣ   fetch-amendments: κείμενα → τροποποιητικές πράξεις
     ΕΛΕΓΚΤΗΣ   fingerprint diff κάθε κώδικα έναντι του ΚΛΕΙΔΩΜΕΝΟΥ golden
     ΝΟΜΟΜΑΘΗΣ  reason-impact στα άρθρα που θα άλλαζαν — η πρόταση φτάνει
                στον άνθρωπο ΜΕ έτοιμη ανάλυση επίπτωσης από τον εγκέφαλο
     ΓΡΑΜΜΑΤΕΑΣ status heartbeat + αναφορά
   Κάθε ρόλος υπάρχον module· εδώ μόνο η ενορχήστρωση."
  (format t "~%── κύκλος ~D [~A] ──~%" cycle (string-downcase (symbol-name policy)))
  (unless (%non-blank (uiop:getenv "FEK_DISCOVER_YEAR"))
    (sb-posix:setenv "FEK_DISCOVER_YEAR" (%current-year-string) 1))
  (handler-case (discover-fek)
    (error (e) (format t "  ⚠ ΦΡΟΥΡΟΣ: ~A~%" e)))
  (handler-case (fetch-amendments)
    (error (e) (format t "  ⚠ ΚΟΜΙΣΤΗΣ: ~A~%" e)))
  ;; ΝΟΜΟΛΟΓΟΣ — ο ίδιος δαίμονας πιάνει και τις νέες αποφάσεις ΑΠ (τρέχον έτος,
  ;; αριθμός > cursor). Ίδιο μονοπάτι, όχι δεύτερο cron. Off με INGEST_WATCH_DECISIONS=0.
  ;; Ο δαίμονας είναι ΠΡΑΚΤΟΡΑΣ του LAWMAX — υπόκειται κι αυτός στο σύνταγμα:
  ;; η φόρτωση νέων αποφάσεων περνά από την ΙΔΙΑ πύλη (execute-command). Έτσι
  ;; ο αυτόνομος δεν συσσωρεύει αδιάβαστες όσο η κατανόηση δεν είναι 1/1.
  (unless (equal (uiop:getenv "INGEST_WATCH_DECISIONS") "0")
    (handler-case (execute-command "--watch-decisions"
                                   (find-command "--watch-decisions") nil)
      (error (e) (format t "  ⚠ ΝΟΜΟΛΟΓΟΣ: ~A~%" e))))
  ;; ΣΤΟΧΑΣΤΗΣ — η συνείδηση του LAWMAX κοιτάζει τον εαυτό της κάθε κύκλο:
  ;; αποστολή, επαναλαμβανόμενα κενά, υποψήφιες αναβαθμίσεις → προτάσεις προς
  ;; έγκριση. Ο δαίμονας είναι ΕΝΑΣ πράκτορας· εδώ ο εαυτός. Off: INGEST_SELF_REFLECT=0.
  (unless (equal (uiop:getenv "INGEST_SELF_REFLECT") "0")
    (handler-case (run-reflect)
      (error (e) (format t "  ⚠ ΣΤΟΧΑΣΤΗΣ: ~A~%" e))))
  ;; ΑΥΤΟΕΞΕΛΙΞΗ: μελέτη→όνειρο→δίκη→αυτο-υιοθέτηση ΕΝΤΟΣ πολιτικών του
  ;; δημιουργού, δέλτα στη βιογραφία. Off: INGEST_EVOLVE=0.
  (unless (equal (uiop:getenv "INGEST_EVOLVE") "0")
    (handler-case (run-evolve :quiet t)
      (error (e) (format t "  ⚠ ΕΞΕΛΙΞΗ: ~A~%" e))))
  (let ((proposals '()))
    (dolist (id *served-corpora*)
      (let ((diff (%consolidation-proposal id)))
        (when diff
          (let* ((fp (find-package :orchestrator.fingerprint))
                 (changed (append (getf diff :changed) (getf diff :added)))
                 ;; ΝΟΜΟΜΑΘΗΣ: για έως 5 άρθρα, πόσα άλλα επηρεάζονται
                 (impact
                   (handler-case
                       (multiple-value-bind (short doc) (build-consolidated-for id)
                         (declare (ignore short))
                         (loop for eid in (subseq changed 0 (min 5 (length changed)))
                               for art = (cl-ppcre:regex-replace "^art_" eid "")
                               collect (cons art
                                             (length (orchestrator.reasoning:reason-impact
                                                      doc id art)))))
                     (error () nil))))
            (format t "~%  ⬆ ~A — πρόταση αλλαγής:~%~A~%"
                    id (funcall (find-symbol "FORMAT-DIFF" fp) diff))
            (when impact
              (format t "     ΝΟΜΟΜΑΘΗΣ: επιπτώσεις~{ ~A→~D~} (χρήσε --reason ~A <άρθρο> για τις αποδείξεις)~%"
                      (loop for (a . n) in impact append (list a n)) id))
            (push (list (cons "corpus" id)
                        (cons "changed" (length changed))
                        (cons "impact" (loop for (a . n) in impact
                                             collect (list (cons "article" a)
                                                           (cons "affected" n)))))
                  proposals)))))
    (let ((pending (orchestrator.review:queue-pending-count review-queue)))
      (%write-daemon-status cycle policy (nreverse proposals) pending)
      (when (plusp pending)
        (format t "~%  ⏳ ~D προτάσεις περιμένουν την απόφασή σου — δες: --review~%" pending)))))

(defun run-ingestion-daemon ()
  "Run the live ingestion daemon: poll the state legislation feed (ΦΕΚ laws by
   default; INGEST_SOURCE=diavgeia for decisions), re-consolidate on each new
   amending act, and re-emit the consumption artifacts to the output directory.
   INGEST_INTERVAL (seconds) and ORCHESTRATOR_OUTPUT_DIR from env."
  (let* ((interval (let ((p (uiop:getenv "INGEST_INTERVAL")))
                     (or (and p (parse-integer p :junk-allowed t)) 3600)))
         ;; Πολιτική: PROPOSE (προεπιλογή — ΟΛΑ ζητούν την έγκρισή σου) ή
         ;; AUTO (οι βέβαιες πράξεις δημοσιεύονται, οι αμφίβολες σε ρωτούν).
         ;; ORCHESTRATOR_POLICY=auto για την δεύτερη — ρητή επιλογή, ποτέ σιωπηλή.
         (policy (if (string-equal (or (uiop:getenv "ORCHESTRATOR_POLICY") "propose")
                                   "auto")
                     :auto :propose))
         (max-polls (let ((p (uiop:getenv "INGEST_MAX_POLLS")))
                      (and p (parse-integer p :junk-allowed t))))
         ;; Pull the codes from their official state source before consolidating,
         ;; so the daemon serves the real text (the scheduler then keeps polling
         ;; the legislation feed for newly published laws / amending acts).
         (refreshed (materialize-served-corpora))
         (base-doc (build-active-consolidated-document))
         ;; per-corpus output (build-active-consolidated-document ran select-corpus)
         (output-dir (corpus-output-dir
                      (or (uiop:getenv "ORCHESTRATOR_OUTPUT_DIR") (orchestrator.paths:institution-dir "output"))))
         ;; The initial production feed is ΦΕΚ (laws). INGEST_SOURCE=diavgeia
         ;; switches to decision-level ingestion; INGEST_SOURCE=consensus runs the
         ;; full ranked acquisition stack (institutional > open-data > eu-cellar >
         ;; scraper > manual) with multi-source consensus — agreed provisions are
         ;; applied, genuine disagreements go to the review queue, never published.
         (which (string-downcase (or (uiop:getenv "INGEST_SOURCE") "fek")))
         ;; Restore the persistent review queue so flagged (uncertain) changes
         ;; survive restarts and accumulate for the lawyer, while high-confidence
         ;; ops continue to auto-publish through the feed.
         (review-queue (load-review-queue))
         (source (cond
                   ((string= which "consensus") (make-consensus-ingestion-source review-queue))
                   ((string= which "diavgeia") (orchestrator.gov-source:make-diavgeia-source))
                   (t (orchestrator.gov-source:make-fek-source)))))
    (format t "~%Ingestion daemon [~A]: refreshed ~D code(s); polling ~A every ~Ds -> ~A~%"
            (string-downcase (symbol-name policy)) refreshed which interval output-dir)
    (format t "Review queue: ~D item(s) pending human approval.~%"
            (funcall (find-symbol "QUEUE-PENDING-COUNT" :orchestrator.review) review-queue))
    (orchestrator.ingestion.daemon:run-update-daemon
     :base-document base-doc :source source
     :output-dir output-dir :interval interval :max-polls max-polls
     :policy policy
     :cycle-hook (lambda (cycle) (%daemon-cycle cycle policy review-queue))
     :review-queue review-queue
     :save-review-fn #'save-review-queue)))


;;; ----------------------------------------------------------------------------
;;; ΕΓΓΡΑΦΗ ΣΤΟ ΜΗΤΡΩΟ — ΦΕΚ, δαίμονας, αναβαθμίσεις (open/closed)
;;; ----------------------------------------------------------------------------

(register-command "--discover-fek"     (lambda (a) (declare (ignore a)) (discover-fek)))
(register-command "--fetch-amendments" (lambda (a) (declare (ignore a)) (fetch-amendments)))
(register-command "--watch-fek"        (lambda (a) (declare (ignore a)) (run-watch-fek)))
(register-command "--check-upgrades"   (lambda (a) (declare (ignore a)) (run-check-upgrades)))
(register-command "--apply-upgrade"    (lambda (a) (declare (ignore a)) (run-apply-upgrade)))
(register-command "--run-ingestion"    (lambda (a) (declare (ignore a)) (run-ingestion-daemon)))
