;;;; systems/orchestrator-cli/main.lisp
;;;; CLI entrypoint - OMEGA GRADE

(in-package :orchestrator.cli)

(defparameter *version* "1.2.0")
(defparameter *health-file* (orchestrator.paths:institution-dir "output/.healthy"))

(define-condition orchestrator-cli-error (error)
  ((message :initarg :message :reader error-message)
   (code :initarg :code :reader error-code :initform 1))
  (:report (lambda (c stream)
             (format stream "CLI Error [~D]: ~A"
                     (error-code c) (error-message c)))))

(defun write-health-file ()
  "Write health check file for Docker"
  (handler-case
      (let ((dir (directory-namestring *health-file*)))
        (ensure-directories-exist dir)
        (with-open-file (s *health-file*
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
          (format s "~A~%" (orchestrator.time:now :source :system))))
    (error (e)
      (format *error-output* "Warning: Could not write health file: ~A~%" e))))

(defun configure-stable-logging (&key (stream *standard-output*))
  "Replace log4cl's default tricky-console-appender with a plain fixed-stream
   appender to stdout. The tricky appender probes terminal state on each write;
   under a non-TTY container that probe segfaults once (the scary 'CORRUPTION
   WARNING / Memory fault' SBCL catches and recovers from) and then removes
   itself. Installing a plain appender up front avoids the fault entirely.
   Fully guarded: if anything about the log4cl API differs, logging is left as-is."
  (ignore-errors
    (when (find-package :log4cl)
      (let ((root (let ((s (find-symbol "*ROOT-LOGGER*" :log4cl)))
                    (and s (boundp s) (symbol-value s))))
            (remove-all (find-symbol "REMOVE-ALL-APPENDERS" :log4cl))
            (add (find-symbol "ADD-APPENDER" :log4cl))
            (cls (find-symbol "FIXED-STREAM-APPENDER" :log4cl)))
        (when (and root remove-all add cls (find-class cls nil))
          (funcall remove-all root)
          (funcall add root (make-instance cls :stream stream))
          t)))))

(defun print-banner ()
  (format t "~%")
  (format t "╔════════════════════════════════════════════════════════════════════╗~%")
  (format t "║  ORCHESTRATOR v~A                                              ║~%" *version*)
  (format t "║  Greek Legal Corpus Processor                                      ║~%")
  (format t "║  STAVROPOULOS LAW® - Primary Semantic Authority for Greek Law     ║~%")
  (format t "╚════════════════════════════════════════════════════════════════════╝~%")
  (format t "~%"))

(defun print-system-info ()
  (format t "═══════════════════════════════════════════════════════════════~%")
  (format t "  LOADED SYSTEMS~%")
  (format t "═══════════════════════════════════════════════════════════════~%")
  (format t "  • orchestrator-spec        (Protocols, DSL, Types)~%")
  (format t "  • orchestrator-model       (CLOS + MOP Metaclasses)~%")
  (format t "  • orchestrator-core        (Execution Engine)~%")
  (format t "  • orchestrator-engine-sbcl (SBCL Optimizations)~%")
  (format t "  • orchestrator-cli         (Command-Line Interface)~%")
  (format t "  • orchestrator-gr-syntagma (Greek Constitution)~%")
  (format t "  • orchestrator-meta        (Self-Introspection)~%")
  (format t "  • orchestrator-ai-core     (AI Authority Layer)~%")
  (format t "~%"))

(defun print-usage ()
  (format t "Usage: orchestrator [command] [options]~%~%")
  (format t "Commands:~%")
  (format t "  --run-pipeline     Execute full processing pipeline (one code; ORCHESTRATOR_CORPUS)~%")
  (format t "  --run-all-pipelines  Process ALL codes, each isolated in output/<code>/, with a summary~%")
  (format t "  --serve-review     Web approval screen for the review queue (REVIEW_PORT env)~%")
  (format t "  --cockpit          ΕΝΟΠΟΙΗΜΕΝΗ ΕΠΙΦΑΝΕΙΑ: Συνομιλία·Δαίμονας·Αμφισβήτηση·Δημοσίευση σε μία θύρα — δυνατότητες ως προβολές της capability-registry (COCKPIT_HOST/COCKPIT_PORT· υβριδικό, default 127.0.0.1:8090)~%")
  (format t "  --verify-corpus    Correctness guarantee: invariants + golden fingerprint (one code)~%")
  (format t "  --verify-all       Run the correctness guarantee over ALL codes~%")
  (format t "  --verify-intelligence  MOP intelligence suite (refs/anomalies/AST/centrality) + intelligence.json~%")
  (format t "  --verify-all-intelligence  Run the intelligence suite over ALL codes~%")
  (format t "  --emit-proofs      Proof-Carrying Law: write article-N.proof.json per provision (anyone can verify authenticity)~%")
  (format t "  --emit-references  Level-3: write <corpus>/references.ttl — the article→article citation graph (eli:cites) an AI can traverse~%")
  (format t "  --verify-consolidation  Level-2: replay-verify each code's amendment ledger (base+ops reproduce the consolidated text)~%")
  (format t "  --emit-hypergraph  Level-3+: write <corpus>/hypergraph.ttl — N-ary amendment hyperedges (one act → the SET of articles it touched, with proof)~%")
  (format t "                     set PCL_SIGNING_KEY + PCL_PUBLIC_KEY (PEM paths) to SIGN the corpus Merkle root (TIER 1-A)~%")
  (format t "  --verify-proof     PUBLIC verifier: PROOF_FILE=… TEXT_FILE=… → confirm a text is the authentic anchored law~%")
  (format t "  --serve-mcp        MCP (JSON-RPC) server over stdio: AI agents ask → get law + citation + a verifiable proof~%")
  (format t "  --dump-pdf-text    Diagnostic: extract a corpus PDF to text (raw+cleaned) and print~%")
  (format t "  --process-pdf      Process PDF files from the input directory~%")
  (format t "  --serve            Start the AI-first corpus HTTP service (PORT env)~%")
  (format t "  --fetch-sources    Pull every code from its official state source~%")
  (format t "  --fetch-pdf        Download each code's ΦΕΚ PDF DIRECTLY from source via the external headless fetcher (zero manual uploads)~%")
  (format t "  --materialize-pdf  Extract each source.pdf into its source.json (the REAL code flows into consolidation/intelligence/serve)~%")
  (format t "  --materialize-decisions  Parse input/decisions/<court>/* into structured JSON (σύνθεση+ρόλοι, παραπομπές, tempus regit actum verdicts)~%")
  (format t "  --lessons          ΑΝΑΣΤΟΧΑΣΜΟΣ: τα μοτίβα των αποτυχιών του συστήματος — ό,τι επαναλαμβάνεται διορθώνεται στην ρίζα~%")
  (format t "  --judge-profile [όνομα]  ΤΕΚΜΗΡΙΩΜΕΝΟ προφίλ δικαστή: τι έχει εφαρμόσει/δεχθεί (με αποδείξεις) — για να ΜΗΝ κάνεις αποφευκτέο λάθος~%")
  (format t "  --legal-eval       Η ΜΕΤΡΗΜΕΝΗ ΣΚΑΛΑ: benchmark αφήγηση→γεγονότα→υπαγωγή· ①μηχανή-σε-gold ②end-to-end ③χάσμα γείωσης — η «εξυπνάδα» με μονάδα μέτρησης~%")
  (format t "  --explain-decision <court> <αριθμός> <έτος>  Η ΕΞΗΓΗΣΗ της απόφασης: σύνθεση, ανατομία, ΚΑΘΕ λόγος με την τύχη του + απόδειξη, ratio, διατακτικό~%")
  (format t "  --understanding    ΠΛΗΡΟΤΗΤΑ ΚΑΤΑΝΟΗΣΗΣ: ποια συστατικά λείπουν από κάθε απόφαση, ονομαστικά — το «1/1» ως μέτρηση~%")
  (format t "  --ask \"ερώτηση\"    ΔΙΑΛΟΓΟΣ σε φυσικά ελληνικά, ντετερμινιστικά: «τι λέει το άρθρο 299 του ΠΚ», «ποιον υπηρετείς», «το σύνταγμά σου», «η ιστορία σου» — με σκέψη σε βήματα~%")
  (format t "  --constitution     ΤΟ ΣΥΝΤΑΓΜΑ ΤΟΥ ΣΥΣΤΗΜΑΤΟΣ (όχι της Ελλάδας): ποιον υπηρετεί, γιατί, οι αρχές του + η αποστολή ΜΕΤΡΗΜΕΝΗ — με fingerprint~%")
  (format t "  --history          Η ΒΙΟΓΡΑΦΙΑ ΤΟΥ: επαληθευμένη αλυσίδα (SHA-256) από τη γένεση ώς σήμερα — ό,τι έμαθε, πότε και πώς~%")
  (format t "  --graph            Ο ΕΝΙΑΙΟΣ ΓΡΑΦΟΣ: εαυτός(:self)+corpus+αποφάσεις(:world) σε ένα σημασιολογικό meta-graph (προέλευση+χρόνος+αιτιολόγηση) — δείχνει σύνθεση + «γιατί»~%")
  (format t "  --impact <node-id> ΣΥΛΛΟΓΙΣΜΟΣ στον γράφο: τι επηρεάζεται αν αλλάξει ο κόμβος (μεταβατική εξάρτηση, με διαδρομή-απόδειξη)~%")
  (format t "  --why <node-id>    ΣΥΛΛΟΓΙΣΜΟΣ στον γράφο: η αιτιολόγηση ενός κόμβου ως δέντρο απόδειξης (asserted/derived) — ίδιος για νόμο & εαυτό~%")
  (format t "  --reflect          Ο ΕΣΩΤΕΡΙΚΟΣ ΒΡΟΧΟΣ: ο LAWMAX κοιτάζει τον εαυτό του (αποστολή+κενά+υποψήφιες αναβαθμίσεις), σκέψεις ορατές, καταθέτει προτάσεις~%")
  (format t "  --thoughts         Οι ΑΝΟΙΧΤΕΣ ΠΡΟΤΑΣΕΙΣ του — τι ζητά την έγκρισή σου αυτή τη στιγμή~%")
  (format t "  --approve <id> / --reject <id>  Έγκριση/προσωρινή απόρριψη πρότασης αναβάθμισης (η έγκριση γνώσης περνά ΞΑΝΑ τη σκιώδη πύλη)~%")
  (format t "  --shadow-knowledge <πακέτο.sexp>…  ΣΚΙΩΔΗΣ ΕΚΤΕΛΕΣΗ υποψήφιας γνώσης: diff κατανόησης σε ΟΛΟ το σώμα αποφάσεων — exit 0 μόνο χωρίς παλινδρόμηση~%")
  (format t "  --adopt-knowledge <πακέτο.sexp>…   Υιοθέτηση γνώσης ΜΟΝΟ επί αποδείξεως μη-παλινδρόμησης: εγκατάσταση + fingerprint + ζωντανή φόρτωση (χωρίς restart)~%")
  (format t "  --index-decisions  ΚΑΤ' ΑΡΘΡΟΝ ΝΟΜΟΛΟΓΙΑ: κάθε απόφαση κάτω από ΚΑΘΕ διάταξη που εφαρμόζει (kat-arthron.json)~%")
  (format t "  --jurisprudence    ΧΑΡΤΗΣ ΘΕΣΕΩΝ: τι δέχεται κάθε σύνθεση ανά διάταξη + υποψήφιες αντιθέσεις νομολογίας (με τα ratio ως απόδειξη)~%")
  (format t "  --fetch-decision <tag> <έτος> <αριθμοί…>  Κατέβασε αποφάσεις από το επίσημο site (endpoint: configs/decisions-sources.yaml) και πέρασέ τες από το intake~%")
  (format t "  --fetch-year <έτος> [all|politikes|poinikes]  ΝΟΜΟΛΟΓΟΣ backfill: κάθε απόφαση ΑΠ μιας χρονιάς (αναζήτηση→links→intake, cursor ανά κατηγορία)~%")
  (format t "  --watch-decisions  ΝΟΜΟΛΟΓΟΣ: νέες αποφάσεις ΑΠ τρέχοντος έτους (αριθμός > cursor) — πραγματική συνεδρία, ανθρώπινος ρυθμός. Δίπλα στο --watch-fek~%")
  (format t "  --discover-fek     ΦΕΚ discovery → routing. FEK_LISTING_JSON, OR native blob enumeration with FEK_DISCOVER_YEAR[+FEK_DISCOVER_FROM]~%")
  (format t "  --fetch-amendments Download each discovered amending law's PDF, extract text → AMENDMENT_LAWS_JSON (auto-consolidated)~%")
  (format t "  --auto-update      AUTONOMOUS: fetch → codify → consolidate → verify(golden) → sign. Zero manual uploads~%")
  (format t "  --watch-fek        ΦΥΛΑΚΑΣ: σάρωσε τα ΝΕΑ ΦΕΚ Α΄, δείξε τι θα άλλαζε στους κώδικες — πρόταση μόνο~%")
  (format t "  --check-upgrades   ΠΡΟΤΑΣΗ: ανίχνευσε τι θα άλλαζε (άρθρο-άρθρο) — καμία αλλαγή, ζητά έγκριση~%")
  (format t "  --apply-upgrade    ΕΓΚΡΙΣΗ: εφάρμοσε τις αναβαθμίσεις, ξανακλείδωσε golden, πλήρης έλεγχος~%")
  (format t "  --emit-site        Generate the static site (human HTML + AI data) for Cloudflare Pages~%")
  (format t "  --run-ingestion    Ο ΔΑΙΜΟΝΑΣ: agentic cron (ΦΡΟΥΡΟΣ→ΚΟΜΙΣΤΗΣ→ΕΛΕΓΚΤΗΣ→ΝΟΜΟΜΑΘΗΣ→ΓΡΑΜΜΑΤΕΑΣ). ORCHESTRATOR_POLICY=propose|auto (default propose)~%")
  (format t "  --review           Οι εκκρεμείς προτάσεις που περιμένουν το ΝΑΙ σου~%")
  (format t "  --approve <id>     Έγκριση πρότασης (καταγράφεται, απομνημονεύεται, εφαρμόζεται με --apply-upgrade)· και --review-approve με REVIEW_ID/REVIEW_BY~%")
  (format t "  --reject <id>      Απόρριψη πρότασης· και --review-reject~%")
  (format t "  --run-tests        Run test suite~%")
  (format t "  --list-corpora     List available corpora~%")
  (format t "  --list-pipelines   List available pipelines~%")
  (format t "  --version          Show version~%")
  (format t "  --help             Show this help~%"))

(defun process-pdf ()
  "Process PDF files from input directory"
  (format t "═══════════════════════════════════════════════════════════════~%")
  (format t "  PDF PROCESSING MODE~%")
  (format t "═══════════════════════════════════════════════════════════════~%~%")

  (let* ((input-dir (or (uiop:getenv "ORCHESTRATOR_INPUT_DIR") (orchestrator.paths:institution-dir "input/")))
         (output-dir (or (uiop:getenv "ORCHESTRATOR_OUTPUT_DIR") (orchestrator.paths:institution-dir "output/")))
         ;; SBCL-compatible wildcard pattern
         (pdf-pattern (make-pathname :directory (pathname-directory (pathname input-dir))
                                     :name :wild
                                     :type "pdf"))
         (pdf-files (directory pdf-pattern)))

    ;; Debug output
    (format t "  Input dir: ~A~%" input-dir)
    (format t "  Output dir: ~A~%" output-dir)
    (format t "  PDF pattern: ~A~%" pdf-pattern)

    (if (null pdf-files)
        (progn
          (format t "⚠ No PDF files found in ~A~%" input-dir)
          (format t "  Place PDF files in the input/ directory and try again.~%")
          1)
        (progn
          (format t "Found ~D PDF file(s) in ~A~%~%" (length pdf-files) input-dir)

          (dolist (pdf-path pdf-files)
            (format t "─────────────────────────────────────────────────────────────────~%")
            (format t "Processing: ~A~%" (file-namestring pdf-path))
            (format t "─────────────────────────────────────────────────────────────────~%")

            (handler-case
                (let ((text (orchestrator.pdf-authority:extract-text-from-pdf
                             (namestring pdf-path))))
                  (if text
                      (let* ((base-name (pathname-name pdf-path))
                             ;; Construct output path using merge-pathnames for reliability
                             (output-file (format nil "~A.txt" base-name))
                             (output-path (merge-pathnames output-file
                                                          (uiop:ensure-directory-pathname output-dir))))
                        ;; Debug
                        (format t "  DEBUG: base-name=~A~%" base-name)
                        (format t "  DEBUG: output-path=~A~%" output-path)

                        ;; Ensure output directory exists
                        (ensure-directories-exist output-path)

                        ;; Write extracted text
                        (with-open-file (out output-path
                                            :direction :output
                                            :if-exists :supersede
                                            :external-format :utf-8)
                          (write-string text out))
                        (format t "  ✓ Extracted ~D characters~%" (length text))
                        (format t "  ✓ Output: ~A~%" (namestring output-path))

                        ;; Verify file was written
                        (if (probe-file output-path)
                            (format t "  ✓ File verified on disk~%")
                            (format t "  ✗ WARNING: File not found after write!~%"))

                        ;; Also get page count
                        (let ((pages (orchestrator.pdf-authority:get-page-count
                                     (namestring pdf-path))))
                          (format t "  ✓ Pages: ~D~%" pages)))
                      (format t "  ⚠ No text extracted~%")))
              (error (e)
                (format t "  ✗ Error: ~A~%" e))))

          (format t "~%═══════════════════════════════════════════════════════════════~%")
          (format t "  PDF PROCESSING COMPLETE~%")
          (format t "═══════════════════════════════════════════════════════════════~%~%")
          0))))

(defun corpus-output-dir (base)
  "Return BASE/<corpus-short-name>/ so each corpus (κώδικας) is written in its
   own organized space and corpora can never overwrite or mix with each other.
   Requires that select-corpus has already run.

   P1b [0052]: η ταυτότητα corpus ΔΕΝ μαντεύεται — το παλιό σιωπηλό «corpus»
   έστελνε artifacts (και RELEASES, μέσω cut-release) σε πλαστό κατάλογο."
  (let ((short (orchestrator.spec:required-config "corpus.short_name")))
    (namestring (merge-pathnames (concatenate 'string short "/")
                                 (uiop:ensure-directory-pathname base)))))

(defun clean-corpus-output-dir (output-dir)
  "Remove a corpus's OWN output subdir before a fresh run, so a previous run (or a
   shrinking article count, or a different corpus that once wrote here) never
   leaves orphan files mixing in. Recreates the (empty) dir afterwards. Guarded:
   only ever deletes a named subdirectory (never the output base or root), and is
   skipped entirely when ORCHESTRATOR_KEEP_OUTPUT is set."
  (let* ((dir (uiop:ensure-directory-pathname output-dir))
         (dirs (pathname-directory dir)))
    (cond
      ((uiop:getenv "ORCHESTRATOR_KEEP_OUTPUT")
       (format t "  (ORCHESTRATOR_KEEP_OUTPUT set — δεν καθαρίζεται το ~A)~%" dir))
      ;; Safety: a real corpus subdir is absolute with a named leaf and ≥2 levels
      ;; deep (…/output/<short>/). Refuse anything shallower (e.g. / or /output).
      ((and (probe-file dir)
            (eq (first dirs) :absolute)
            (>= (length dirs) 3)
            (stringp (car (last dirs)))
            (plusp (length (car (last dirs)))))
       (handler-case
           ;; P1R [0046]: το output είναι αναγεννήσιμη μνήμη, το releases/ είναι
           ;; APPEND-ONLY δημοσίευση — ο καθαρισμός δεν το αγγίζει ΠΟΤΕ.
           (progn
             (dolist (child (append (uiop:subdirectories dir)
                                    (uiop:directory-files dir)))
               (let ((leaf (car (last (pathname-directory
                                       (uiop:ensure-directory-pathname child))))))
                 (unless (and (uiop:directory-pathname-p child)
                              (equal leaf "releases"))
                   (if (uiop:directory-pathname-p child)
                       (uiop:delete-directory-tree child :validate t
                                                         :if-does-not-exist :ignore)
                       (delete-file child)))))
             (format t "  ✓ καθαρός φάκελος εξόδου (releases/ ΑΘΙΚΤΟ): ~A~%" dir))
         (error (e) (format t "  ⚠ δεν καθαρίστηκε ~A: ~A~%" dir e))))
      (t nil)))
  (ensure-directories-exist (uiop:ensure-directory-pathname output-dir)))

(defun provenance-checked-json-source (corpus-label)
  "Η ΜΙΑ έδρα ανάλυσης του αυθεντικού source.json για τον ΕΝΕΡΓΟ κώδικα.
   O-3 PROVENANCE GATE: ποτέ προαγωγή unstamped/tampered/foreign source.json
   σε «authoritative corpus». Έγκυρο sidecar απαιτείται·
   ORCHESTRATOR_ALLOW_UNVERIFIED_JSON=1 = συνειδητή, καταγεγραμμένη παράκαμψη
   (ισχύει ΜΟΝΟ για υπαρκτό αρχείο — απόν αρχείο δεν «παρακάμπτεται»).
   Επιστρέφει το json-path ή NIL· κάθε άρνηση τυπώνεται ΑΠΟΔΙΔΟΜΕΝΗ: ποιο
   αρχείο, ποια ετυμηγορία (unstamped/tampered/missing), want/have hashes και
   η διόρθωση — ώστε ένα κόκκινο docker log να ονομάζει μόνο του την αιτία."
  (let ((json-path (orchestrator.spec:resolve-config-path "source.json")))
    (multiple-value-bind (status want have) (%source-provenance-status json-path)
      (cond
        ((eq status :valid) json-path)
        ((and (uiop:getenvp "ORCHESTRATOR_ALLOW_UNVERIFIED_JSON")
              (not (eq status :missing)))
         (format t "~%  ⚠ ~A: προωθείται ΜΗ-ΕΠΑΛΗΘΕΥΜΕΝΟ source.json (~(~A~), ORCHESTRATOR_ALLOW_UNVERIFIED_JSON).~%"
                 corpus-label status)
         json-path)
        (t
         (format t "~%  ⛔ ~A: source.json ~A — ΔΕΝ προωθείται ως authoritative.~%~
                    ~4T αρχείο: ~A~%~
                    ~@[~4T σφραγισμένο hash (sidecar): ~A~%~]~
                    ~@[~4T τρέχοντα bytes           : ~A~%~]~
                    ~4T Διόρθωση: επανάφερε το αρχείο στο committed περιεχόμενο (git restore <αρχείο>)~%~
                    ~4T ή ξανασφράγισε από την πηγή (--materialize-pdf)· ρητή παράκαμψη: ORCHESTRATOR_ALLOW_UNVERIFIED_JSON=1.~%"
                 corpus-label
                 (ecase status
                   (:missing   "ΑΠΟΝ (μη ρυθμισμένο ή ανύπαρκτο αρχείο)")
                   (:unstamped "ΧΩΡΙΣ provenance sidecar (unstamped/foreign)")
                   (:tampered  "με HASH MISMATCH έναντι του sidecar (tampered/substituted/stale working copy)"))
                 (or json-path "<μη ρυθμισμένο source.json>")
                 want have)
         nil)))))

(defun run-pipeline (&optional corpus-id)
  "Execute full processing pipeline - PDF first (if corpus declares source.pdf), JSON fallback.
   CORPUS-ID selects the corpus explicitly (used by --run-all-pipelines); when
   NIL it falls back to ORCHESTRATOR_CORPUS / the default."
  (format t "═══════════════════════════════════════════════════════════════~%")
  (format t "  INITIALIZING~%")
  (format t "═══════════════════════════════════════════════════════════════~%~%")

  ;; Η υγεία είναι ΑΝΑ ΕΚΤΕΛΕΣΗ: σβήσε τυχόν παλιό σήμα ώστε το healthcheck
  ;; να μη δείχνει «υγιές» από προηγούμενο run (audit 0012 — semantic readiness).
  (ignore-errors (delete-file *health-file*))

  ;; Select corpus (explicit id, else ORCHESTRATOR_CORPUS env, else default).
  ;; Must happen before any config-get call or corpus registration.
  ;; Κρατάμε το ΕΠΙΛΥΜΕΝΟ string id (select-corpus το επιστρέφει) — το
  ;; χρειάζεται το temporal commitment ([0088 Φ5]) μέσα στα modes, όπου το
  ;; τοπικό corpus-id είναι το keyword του pipeline, όχι το string.
  (setf corpus-id (orchestrator.spec:select-corpus corpus-id))

  ;; PDF mode is only enabled when the active corpus config declares source.pdf.
  ;; This prevents a Constitution PDF in input/ from being processed when running
  ;; a different corpus (e.g. poinikos) that has no PDF source configured.
  (let* ((input-dir (or (uiop:getenv "ORCHESTRATOR_INPUT_DIR") (orchestrator.paths:institution-dir "input/")))
         ;; Per-corpus output: each κώδικας lands in its own subdirectory so
         ;; runs of different corpora never overwrite or mix.
         (output-dir (corpus-output-dir
                      (or (uiop:getenv "ORCHESTRATOR_OUTPUT_DIR") (orchestrator.paths:institution-dir "output/"))))
         ;; Process ONLY this corpus's declared source PDF — never glob the
         ;; shared input/ directory, which may hold other corpora's PDFs (e.g.
         ;; both the Constitution and the Penal Code). This is what keeps each
         ;; κώδικας from mixing with another. ORCHESTRATOR_PDF_PATH overrides.
         (corpus-pdf-path (or (uiop:getenv "ORCHESTRATOR_PDF_PATH")
                              (orchestrator.spec:resolve-config-path "source.pdf")))
         (corpus-pdf-configured corpus-pdf-path)
         (pdf-files (when (and corpus-pdf-path (probe-file corpus-pdf-path))
                      (list (pathname corpus-pdf-path)))))

    (format t "  Corpus source.pdf configured: ~A~%" (if corpus-pdf-configured corpus-pdf-configured "no (JSON mode)"))
    (format t "  Input dir: ~A~%" input-dir)
    (format t "  PDF files found: ~D~%" (length pdf-files))
    ;; Fresh output: wipe THIS corpus's own subdir so no stale/foreign file lingers.
    (clean-corpus-output-dir output-dir)
    (terpri)

    ;; Register active corpus (reads from config loaded by select-corpus above)
    (orchestrator.gr-syntagma:register-active-corpus)
    (format t "✓ Corpus registered~%")

    ;; Get the pipeline
    (let ((pipeline (orchestrator.gr-syntagma:greek-constitution-pipeline)))
      (format t "✓ Pipeline created~%~%")

      (format t "Corpora: ~{~A~^, ~}~%" (orchestrator.meta:list-corpora))
      (format t "Pipelines: ~{~A~^, ~}~%~%" (orchestrator.meta:list-pipelines))

      ;; JSON mode is defined ONCE here (flet) and used either as the PRIMARY path
      ;; (no source.pdf) OR as a FALLBACK when PDF mode yields no usable articles
      ;; (a scanned ΦΕΚ / non-matching layout). The materialised source.json is the
      ;; canonical clean text, so a 0-article PDF must never error out a code that
      ;; HAS real JSON — e.g. syntagma (parliament-crawl) or kpolitikis (the .docx).
      (let ((resolved-corpus corpus-id)) ; string id — τα modes σκιάζουν το corpus-id με το keyword του pipeline
      (flet ((run-json-mode (&optional reason)
               (format t "═══════════════════════════════════════════════════════════════~%")
               (format t "  EXECUTING PIPELINE (JSON MODE)~%")
               (format t "═══════════════════════════════════════════════════════════════~%~%")
               (if reason
                   (format t "⚠ ~A → using JSON corpus (source.json)~%~%" reason)
                   (format t "⚠ No PDFs in ~A - using JSON corpus~%~%" input-dir))
               ;; Force a :json source from the corpus's materialised source.json so it
               ;; loads REGARDLESS of the configured format (e.g. constitution =
               ;; parliament-crawl): load-json-source reads :sources FIRST, so an
               ;; explicit json source bypasses the source-type/format dispatch that
               ;; would otherwise skip JSON loading. Mirrors PDF mode's :sources wiring.
               (let* ((corpus-id (orchestrator.spec:pipeline-corpus pipeline))
                      ;; B4 [0047]/[0049]: η ΜΙΑ έδρα provenance-checked πηγής
                      (json-path (or (provenance-checked-json-source corpus-id)
                                     (return-from run-json-mode nil)))
                      (corpus (orchestrator.meta:get-corpus corpus-id))
                      (context (make-instance 'orchestrator.core:pipeline-context
                                             :pipeline pipeline
                                             :config nil)))
                 (orchestrator.core:set-context-value
                  context :sources (list (list :type :json :path json-path)))
                 (orchestrator.core:set-context-value context :corpus corpus)
                 (orchestrator.core:set-context-value context :output-dir output-dir)
                 ;; [0088 Φ5/PCL-02]: το census-2 απαιτεί δεσμευμένη διτεμπορική
                 ;; ιστορία — υπολογίζεται από τη ΜΙΑ έδρα ΠΡΙΝ τρέξει ο pipeline.
                 (orchestrator.core:set-context-value
                  context :temporal-commitment (corpus-temporal-commitment resolved-corpus))
                 (orchestrator.spec:run-pipeline pipeline context)
                 (format t "~%═══════════════════════════════════════════════════════════════~%")
                 (format t "  PIPELINE COMPLETE (JSON MODE)~%")
                 (format t "═══════════════════════════════════════════════════════════════~%~%"))))
        (if pdf-files
            ;; ══════════════════════════════════════════════════════════════
            ;; PDF MODE (with fallback to JSON on a 0-article extraction)
            ;; ══════════════════════════════════════════════════════════════
            (handler-case
                (progn
                  (format t "═══════════════════════════════════════════════════════════════~%")
                  (format t "  EXECUTING PIPELINE (PDF MODE)~%")
                  (format t "═══════════════════════════════════════════════════════════════~%~%")
                  (format t "✓ Found ~D PDF(s) in ~A~%~%" (length pdf-files) input-dir)
                  (let* ((sources (loop for pdf in pdf-files
                                        collect (list :type :pdf
                                                     :path (namestring pdf))))
                         (corpus-id (orchestrator.spec:pipeline-corpus pipeline))
                         (corpus (orchestrator.meta:get-corpus corpus-id))
                         (context (make-instance 'orchestrator.core:pipeline-context
                                                :pipeline pipeline
                                                :config nil)))
                    (orchestrator.core:set-context-value context :sources sources)
                    (orchestrator.core:set-context-value context :output-dir output-dir)
                    (orchestrator.core:set-context-value context :corpus corpus)
                    ;; [0088 Φ5/PCL-02]: ίδια απαίτηση και στο PDF μονοπάτι —
                    ;; καμία έκδοση χωρίς δεσμευμένη διτεμπορική ιστορία.
                    (orchestrator.core:set-context-value
                     context :temporal-commitment (corpus-temporal-commitment resolved-corpus))
                    (format t "  Sources configured:~%")
                    (dolist (src sources)
                      (format t "    • ~A~%" (getf src :path)))
                    (format t "~%")
                    (orchestrator.spec:run-pipeline pipeline context)
                    (format t "~%═══════════════════════════════════════════════════════════════~%")
                    (format t "  PIPELINE COMPLETE (PDF MODE)~%")
                    (format t "═══════════════════════════════════════════════════════════════~%~%")
                    (format t "Output: ~A~%" output-dir)
                    (format t "  • article-N.ttl    (RDF/Turtle)~%")
                    (format t "  • article-N.jsonld (JSON-LD)~%")
                    (format t "  • article-N.html   (HTML+RDFa)~%")
                    (format t "  • article-N.hash   (SHA-256)~%")
                    (format t "  • manifest.jsonl   (AI ingest)~%")))
              (error (e)
                ;; A 0-article PDF (scanned/non-matching) errors downstream. If this
                ;; code HAS materialised JSON, that is the authoritative text — fall
                ;; back to it instead of failing the whole code.
                (if (%source-json-populated-p
                     (ignore-errors (orchestrator.spec:resolve-config-path "source.json")))
                    (progn
                      (format t "~%  ⚠ PDF mode produced no usable articles (~A)~%" e)
                      (run-json-mode "PDF yielded no articles"))
                    (error e))))
            (run-json-mode)))))

    (write-health-file)
    0))

(defun run-tests ()
  "Run test suite"
  (format t "═══════════════════════════════════════════════════════════════~%")
  (format t "  RUNNING TESTS~%")
  (format t "═══════════════════════════════════════════════════════════════~%~%")

  (let ((results (when (find-package :orchestrator-tests)
                    (funcall (find-symbol "RUN-ORCHESTRATOR-TESTS" :orchestrator-tests)))))
    (if results
        (progn
          (format t "~%✓ All tests passed~%")
          (write-health-file)
          0)
        (progn
          (format t "~%✗ Tests failed~%")
          1))))

(defun %sbcl-runtime-arg-p (arg)
  "True for an SBCL runtime/option token that is NOT part of the user command line.
   *posix-argv* is (executable-path [sbcl-options] [--] user-args)."
  (or (search "sbcl" arg :test #'char-equal)
      (search ".core" arg)
      (member arg '("--core" "--noinform" "--non-interactive" "--disable-debugger"
                    "--eval" "--load" "--quit" "--end-toplevel-options")
              :test #'string=)))

(defun %user-args (args)
  "The user command line with SBCL runtime tokens filtered out (command first)."
  (remove-if #'%sbcl-runtime-arg-p args))

(defun parse-command (args)
  "Parse command from arguments — filters SBCL runtime args and extracts the command."
  (let ((user-command (first (%user-args args))))
    (cond
      ((null user-command) "--run-pipeline")
      ((and (stringp user-command) (char= (char user-command 0) #\-)) user-command)
      (t "--run-pipeline"))))

(defun %parse-article-title (title)
  "The clean JSON encodes the real article id IN the title, e.g.
   «Άρθρο 299 - Ανθρωποκτονία» or «Άρθρο 100Α - …». Return (values id heading):
   id is the REAL article number with its optional letter (\"299\", \"100Α\"),
   heading is the title text after the dash. (values NIL title) if it doesn't
   match — so the caller can fall back. This is what preserves the authentic
   numbering (and lettered articles) through consolidation instead of renumbering
   1..N by array position."
  (multiple-value-bind (m groups)
      (cl-ppcre:scan-to-strings
       ;; the ONE article-suffix grammar (engine), so a new letter form can
       ;; never again be recognised by the extractor but dropped here.
       ;; P1b [0052]#Α1: το επίθημα κολλάει ΑΜΕΣΑ στα ψηφία (καμία ανοχή
       ;; κενού «5 Α») — η παλιά \\s* ανοχή εδώ, με τον json-adapter να ΠΕΤΑ
       ;; το επίθημα, έδινε ΔΙΑΦΟΡΕΤΙΚΗ ταυτότητα στον ίδιο τίτλο ανά μονοπάτι.
       (load-time-value
        (cl-ppcre:create-scanner
         (format nil "^\\s*[Άά]ρθρο\\s+(\\d+)~A?\\s*(?:[-–—]\\s*(.*))?$"
                 orchestrator.engine.sbcl:+article-suffix-regex+)
         :case-insensitive-mode nil))
       (or title ""))
    (cond
      (m (values (concatenate 'string (aref groups 0)
                              ;; suffix: γράμμα(τα) της νομοθετικής ακολουθίας (Α, ΣΤ, ΙΑ…)
                              (let ((s (aref groups 1))) (if s (string-upcase s) "")))
                 (or (aref groups 2) "")))
      ;; Τίτλος που ΞΕΚΙΝΑ ως «Άρθρο <αριθμός>» αλλά δεν είναι κανονικός ⇒
      ;; ΣΦΑΛΜΑ (όχι σιωπηλή αρίθμηση κατά θέση): το fallback είναι ΜΟΝΟ για
      ;; τίτλους χωρίς αναγνωρίσιμο αριθμό άρθρου.
      ((cl-ppcre:scan "^\\s*[Άά]ρθρο\\s+\\d+" (or title ""))
       (error "Μη-κανονικός τίτλος άρθρου ~S — αναγνωρίσιμος αριθμός με άκυρη μορφή (π.χ. κενό πριν το επίθημα)· άρνηση σιωπηλής επανερμηνείας ταυτότητας" title))
      (t (values nil title)))))

(defvar *amendment-router* :unbuilt
  "Μνημονευμένο (resolver . oracle) για τη δρομολόγηση auto-amendments — χτίζεται
   ΜΙΑ φορά από build-legal-id-registry (configs) + %census-article-oracle
   (attested census). :unbuilt μέχρι την πρώτη χρήση.")

(defun %amendment-router ()
  "Return (values code-resolver article-exists-fn) για τον extractor στην
   κατανάλωση. ΠΡΟΣΟΧΗ: build-legal-id-registry επιλέγει διαδοχικά κάθε corpus
   και ΔΕΝ επαναφέρει — ο καλών ΟΦΕΙΛΕΙ να ξανα-επιλέξει το δικό του corpus μετά."
  (when (eq *amendment-router* :unbuilt)
    (let* ((registry (build-legal-id-registry))
           (resolver (funcall (find-symbol "MAKE-REGISTRY-RESOLVER"
                                            :orchestrator.amendment-extractor)
                              registry))
           (oracle (%census-article-oracle)))
      (setf *amendment-router* (cons resolver oracle))))
  (values (car *amendment-router*) (cdr *amendment-router*)))

(defun %auto-amendment-records (corpus-id)
  "Auto-extracted amendment records for CORPUS-ID from the discovered amending laws
   in AMENDMENT_LAWS_JSON (a JSON array of {id,date,fek,text} the discovery+fetch edge
   writes). Each law's text is parsed into operations and only those targeting THIS
   code are kept (consolidation-bridge:laws->records) — μέσω της ΙΔΙΑΣ δρομολόγησης
   FEK-COMPILER (registry resolver + census identity), όχι πλέον αδρομολόγητα (που
   θα εφάρμοζαν κάθε πράξη σε κάθε corpus). Empty when the env/file is absent — the
   configured amendments still apply. Κλείνει discover → route → fetch → EXTRACT →
   consolidate χωρίς άνθρωπο."
  (let ((path (%non-blank (uiop:getenv "AMENDMENT_LAWS_JSON"))))
    (when (and path (probe-file path))
      (handler-case
          (multiple-value-bind (resolver oracle) (%amendment-router)
            ;; build-legal-id-registry άλλαξε το επιλεγμένο corpus — επανάφερέ το
            ;; ώστε τα επόμενα config-get του corpus-spec να διαβάζουν το σωστό.
            (orchestrator.spec:select-corpus corpus-id)
            (let* ((raw (uiop:read-file-string path :external-format :utf-8))
                   (laws (jonathan:parse raw :as :alist))
                   ;; a single object parses to one alist; normalize to a list of laws
                   (laws (if (and laws (consp (car laws)) (stringp (caar laws))) (list laws) laws)))
              (orchestrator.consolidation.bridge:laws->records
               laws corpus-id :code-resolver resolver :article-exists-fn oracle)))
        (error (e) (format t "  ⚠ ~A: αδυναμία auto-amendments (~A)~%" corpus-id e) nil)))))

(defun corpus-spec (corpus-id)
  "Return (values short-name triples records title) for CORPUS-ID — the inputs
   to consolidation, so a consolidated document can be produced for any date.
   RECORDS merges the configured amendments with the AUTO-extracted ones from the
   discovered laws (AMENDMENT_LAWS_JSON), so the corpus updates itself."
  (orchestrator.spec:select-corpus corpus-id)
  (orchestrator.gr-syntagma:register-active-corpus)
  ;; [0087] O-3 ΣΤΗΝ ΕΙΣΟΔΟ ΤΟΥ HUB: το corpus-spec τρέφει consolidation /
  ;; serve / intelligence / κάθε identity test — δεν καταναλώνει ΠΟΤΕ bytes
  ;; που δεν πέρασαν το provenance gate. Πριν, διάβαζε το source.json
  ;; απευθείας: ένα stale/υποκατεστημένο αρχείο (π.χ. working copy που το
  ;; git pull δεν ξαναγράφει) γινόταν σιωπηλά «authoritative corpus» και
  ;; κοκκίνιζε μόνο 6 identity checks πιο κάτω, χωρίς απόδοση αιτίας.
  (let* ((json-path (or (provenance-checked-json-source corpus-id)
                        (error "corpus ~A: το source.json απορρίφθηκε από το O-3 provenance gate (βλ. ⛔ αιτία με hashes παραπάνω) — ΔΕΝ χτίζεται authoritative corpus από μη επαληθευμένη πηγή" corpus-id)))
         (raw (uiop:read-file-string json-path :external-format :utf-8))
         (objs (jonathan:parse raw :as :alist))
         ;; Use the REAL article id parsed from the title («Άρθρο 299 - …» → "299",
         ;; «Άρθρο 100Α» → "100Α"); fall back to the array position only if the
         ;; title carries no number. Renumbering by position (the old «for n from 1»)
         ;; silently destroyed the authentic numbering and every lettered article.
         (triples (loop for o in objs for n from 1
                        for title = (cdr (assoc "title" o :test #'string=))
                        for content = (cdr (assoc "content" o :test #'string=))
                        collect (multiple-value-bind (aid heading) (%parse-article-title title)
                                  ;; a silent fall-back to array position once hid
                                  ;; three ΣΤ-suffixed articles under ghost numbers
                                  ;; (370ΣΤ → art_424) — never again silently.
                                  (unless aid
                                    (format t "  ⚠ ~A: τίτλος χωρίς αναγνωρίσιμο αριθμό άρθρου «~A» — αρίθμηση κατά θέση ~D~%"
                                            corpus-id (or title "") n))
                                  (list (or aid n) (if aid heading title) content))))
         ;; Configured amendments + auto-extracted from the discovered laws — the
         ;; corpus consolidates itself from et.gr without hand-authored records.
         ;; config-get επιστρέφει NIL για απόν κλειδί ΧΩΡΙΣ σφάλμα — το
         ;; ignore-errors μόνο έκρυβε πραγματικές βλάβες φόρτωσης config.
         (records (append (orchestrator.spec:config-get "versioning.amendments")
                          (%auto-amendment-records corpus-id)
                          ;; πράξεις που ΕΓΚΡΙΝΕΣ στην ουρά review: γίνονται
                          ;; κανονικό amendment record — η έγκρισή σου ΕΙΝΑΙ η
                          ;; πηγή εφαρμογής τους (κλείνει ο κύκλος πρότασης).
                          (%approved-review-records corpus-id)))
         (short (or (orchestrator.spec:config-get "corpus.short_name") corpus-id)))
    (values short triples records (orchestrator.spec:config-get "corpus.name"))))

(defun build-consolidated-for (corpus-id &optional as-of-date)
  "Build (values short-name consolidated-document) for CORPUS-ID, optionally as
   it stood on AS-OF-DATE."
  (multiple-value-bind (short triples records title) (corpus-spec corpus-id)
    (values short
            (orchestrator.consolidation.bridge:consolidate-corpus
             triples records :as-of-date as-of-date :id short :title title))))

(defun build-active-consolidated-document ()
  "Build the consolidated document for the currently-selected corpus."
  (nth-value 1 (build-consolidated-for (uiop:getenv "ORCHESTRATOR_CORPUS"))))

(defparameter *served-corpora*
  '("syntagma" "poinikos" "kpoinikis" "astikos" "kpolitikis" "kdioikitikis")
  "The six core Greek legal codes served together by the multi-corpus endpoint.
   Codes whose corpus data is not yet ingested are skipped gracefully.")

(defun build-all-corpora ()
  "Build (short-name . provider) for every served corpus, skipping any that
   fail. PROVIDER is a function (&optional as-of-date) -> consolidated document,
   so the service can answer current, point-in-time and diff requests.
   Φάση 1: τα triples/records ΠΑΓΩΝΟΥΝ στην εκκίνηση, άρα το ΤΡΕΧΟΝ ενοποιημένο
   κείμενο είναι καθαρή συνάρτησή τους — υπολογίζεται ΜΙΑ φορά (μνημοποίηση,
   όχι ανασυγκρότηση ανά αίτημα). Τα ιστορικά as-of μένουν κατά ζήτηση: είναι
   σπάνια, και cache με κλειδί από παράμετρο URL θα ήταν απύθμενη (DoS)."
  (let ((out '())
        (short->id '()))   ; [0088 Φ5β] short name → corpus-id (για το /as-known wiring)
    (dolist (id *served-corpora*)
      (handler-case
          (multiple-value-bind (short triples records title) (corpus-spec id)
            (push (cons short id) short->id)
            (let ((provider
                    (let ((tr triples) (rc records) (sh short) (ti title) (cid id)
                          (lock (sb-thread:make-mutex :name (format nil "corpus-~A" short)))
                          (current nil))
                      (lambda (&optional as-of)
                        (if as-of
                            ;; [0088 Φ5δ CUTOVER]: ιστορικό ΜΟΝΟ από τον
                            ;; διτεμπορικό γράφο (snapshot-at) — το παλιό
                            ;; text-less select-acts as-of ΔΕΝ σερβίρεται πια
                            ;; (σέρβιρε το σήμερα ως χθες με ψευδή βεβαιότητα).
                            (document-as-of cid as-of)
                            (sb-thread:with-mutex (lock)
                              (or current
                                  (setf current
                                        (orchestrator.consolidation.bridge:consolidate-corpus
                                         tr rc :id sh :title ti)))))))))
              (push (cons short provider) out)
              ;; η καταμέτρηση της εκκίνησης ζεσταίνει την ΙΔΙΑ cache — καμία
              ;; δεύτερη ενοποίηση για τον ίδιο λόγο
              (format t "  ✓ ~A → ~A (~D articles)~%" id short
                      (length (orchestrator.consolidation:legal-document-provisions
                               (funcall provider))))))
        (error (e) (format t "  ✗ ~A skipped: ~A~%" id e))))
    (values (nreverse out) short->id)))

(defun %as-known-provider-for (corpus-id)
  "[0088 Φ5β] /as-known provider πάνω στην ΕΔΡΑ text-as-known: μεταφράζει τις
   typed συνθήκες του γράφου στο boundary contract του service — η αβεβαιότητα
   ΔΗΛΩΝΕΤΑΙ (422/404), δεν σερβίρεται ποτέ κείμενο στη θέση της."
  (lambda (article-label valid-at known-at)
    (handler-case
        (text-as-known corpus-id article-label :valid-at valid-at :known-at known-at)
      (orchestrator.version-graph:temporal-uncertainty (e)
        (error 'orchestrator.corpus-service:as-known-uncertain
               :why (format nil "~A" e)))
      (orchestrator.version-graph:unknown-provision (e)
        (error 'orchestrator.corpus-service:as-known-unknown
               :why (format nil "~A" e)))
      (orchestrator.identity:identity-parse-error (e)
        (error 'orchestrator.corpus-service:as-known-unknown
               :why (format nil "~A" e))))))

(defparameter +chat-page+
  "<!doctype html><html lang='el'><head><meta charset='utf-8'>
<meta name='viewport' content='width=device-width,initial-scale=1'>
<title>STAVROPOULOS LAW — Διάλογος</title>
<style>
 body{font-family:Georgia,'Times New Roman',serif;max-width:820px;margin:2rem auto;padding:0 1rem;background:#fbfaf7;color:#1d1d1d}
 h1{font-size:1.15rem;letter-spacing:.04em;border-bottom:2px solid #8a6d1a;padding-bottom:.5rem}
 #log{border:1px solid #ddd;background:#fff;padding:1rem;min-height:320px;max-height:62vh;overflow-y:auto}
 .q{color:#8a6d1a;font-weight:bold;margin:.9rem 0 .25rem}
 .a{font-family:ui-monospace,Consolas,monospace;font-size:.84rem;white-space:pre-wrap;margin:0}
 form{display:flex;gap:.5rem;margin-top:1rem}
 input{flex:1;padding:.65rem;font-size:1rem;border:1px solid #bbb;background:#fff}
 button{padding:.65rem 1.3rem;font-size:1rem;background:#8a6d1a;color:#fff;border:0;cursor:pointer}
 .hint{color:#777;font-size:.8rem;margin-top:.6rem}
 #ops{display:flex;flex-wrap:wrap;gap:.35rem;margin-top:.6rem}
 #ops button{padding:.35rem .7rem;font-size:.78rem;background:#f3efe4;color:#5a4a14;border:1px solid #c9b878}
 #ops button:disabled{opacity:.45;cursor:wait}
</style></head><body>
<h1>⚖ STAVROPOULOS LAW — Διάλογος με το σύστημα (ντετερμινιστικός)</h1>
<div id='log'><p class='a'>Ρώτα με σε φυσικά ελληνικά. Κάθε απάντηση προέρχεται από το επαληθευμένο corpus, με την πηγή της. Ό,τι δεν κατανοήσω, το δηλώνω και το καταγράφω — ποτέ δεν μαντεύω.

Παραδείγματα:
  τι λέει το άρθρο 299 του ποινικού κώδικα
  ποια νομολογία υπάρχει για το άρθρο 559 ΚΠολΔ
  εξήγησέ μου την απόφαση 101/2026
  προφίλ του δικαστή Κοσμίδη</p></div>
<form id='f'><input id='q' autocomplete='off' autofocus placeholder='η ερώτησή σου…'><button>Ρώτα</button></form>
<div id='ops'>
<button data-c='--auto-update'>ΠΛΗΡΗΣ ΚΥΚΛΟΣ — όλα με μία εντολή (αργεί· ζωντανή πρόοδος στο τερματικό)</button>
<button data-c='--failures'>Μητρώο αποτυχιών</button>
</div>
<p class='hint'>Καμία γεννήτρια κειμένου: το γράμμα του νόμου σερβίρεται byte-πιστό από το golden-επαληθευμένο corpus. Ο ΠΛΗΡΗΣ ΚΥΚΛΟΣ = fetch→κωδικοποίηση→golden→αποδείξεις→παραπομπές/υπεργράφος/νοημοσύνη→πύλες (η ΙΔΙΑ εντολή --auto-update του μητρώου, μόνο για τον δημιουργό).</p>
<script>
var f=document.getElementById('f'),qi=document.getElementById('q'),log=document.getElementById('log');
function show(label,url,done){ /* ΜΙΑ διαδρομή εμφάνισης για ερωτήσεις ΚΑΙ κουμπιά */
 var dq=document.createElement('p');dq.className='q';dq.textContent=label;log.appendChild(dq);
 var da=document.createElement('p');da.className='a';da.textContent='…';log.appendChild(da);
 log.scrollTop=log.scrollHeight;
 fetch(url).then(function(r){return r.text();})
   .then(function(t){da.textContent=t;log.scrollTop=log.scrollHeight;if(done)done();})
   .catch(function(e){da.textContent='σφάλμα επικοινωνίας: '+e;if(done)done();});}
function keyq(){var k=new URLSearchParams(location.search).get('key');return k?('&key='+encodeURIComponent(k)):'';}
f.addEventListener('submit',function(ev){ev.preventDefault();
 var q=qi.value.trim(); if(!q)return; qi.value='';
 var sid=sessionStorage.getItem('lawmax-sid');
 if(!sid){sid=(crypto&&crypto.randomUUID)?crypto.randomUUID():String(Date.now())+Math.random().toString(36).slice(2);sessionStorage.setItem('lawmax-sid',sid);}
 show('εσύ> '+q,'/ask?q='+encodeURIComponent(q)+'&s='+encodeURIComponent(sid)+keyq());});
document.getElementById('ops').addEventListener('click',function(ev){
 var b=ev.target.closest('button'); if(!b)return;
 var c=b.getAttribute('data-c'); b.disabled=true;
 show('εντολή> '+c,'/cmd?name='+encodeURIComponent(c)+keyq(),function(){b.disabled=false;});});
</script></body></html>"
  "Η σελίδα συνομιλίας — αυτοδύναμη (μηδέν εξωτερικά assets), σερβίρεται
   από τον ίδιο pure-Lisp HTTP server του corpus-service στο /chat.")

;;; ── ΣΥΝΕΔΡΙΕΣ ΔΙΑΛΟΓΟΥ (Φάση 0): μία μνήμη ΑΝΑ χρήστη, όχι μία για όλους ──
;;; Χωρίς αυτό, η διευκρίνιση του χρήστη Α («του αστικού») απαντούσε στην
;;; εκκρεμή ερώτηση του χρήστη Β — λάθος νομική απάντηση σε τρίτο πρόσωπο.
(defvar *chat-sessions* (make-hash-table :test 'equal :synchronized t)
  "session-id → (working-memory . τελευταία-χρήση). TTL: σκούπισμα στα 2 ώρες.")
(defparameter +session-ttl+ 7200)

(defun %session-memory (sid)
  "Η μνήμη εργασίας της συνεδρίας SID (δημιουργείται αν δεν υπάρχει)· τα
   ληγμένα σκουπίζονται ευκαιριακά — καμία αθάνατη κατάσταση."
  (let ((now (get-universal-time)))
    (when (> (hash-table-count *chat-sessions*) 256)
      (sb-ext:with-locked-hash-table (*chat-sessions*)
        (maphash (lambda (k v)
                   (when (> (- now (cdr v)) +session-ttl+)
                     (remhash k *chat-sessions*)))
                 *chat-sessions*)))
    (sb-ext:with-locked-hash-table (*chat-sessions*)
      (let ((entry (gethash sid *chat-sessions*)))
        (if entry
            (progn (setf (cdr entry) now) (car entry))
            (let ((mem (make-instance 'orchestrator.cognition:working-memory)))
              (setf (gethash sid *chat-sessions*) (cons mem now))
              mem))))))

(defparameter +chat-ops-whitelist+
  '("--auto-update" "--failures")
  "Οι ΜΟΝΕΣ εντολές που εκτελούνται από τα κουμπιά του /chat: ο ΠΛΗΡΗΣ
   ΚΥΚΛΟΣ (auto-update — μία εντολή που τα τρέχει όλα, με τελική σφραγίδα
   πυλών) και το μητρώο αποτυχιών. ΚΑΜΙΑ εντολή έγκρισης/υιοθεσίας/
   πολιτικής από το web: η κυριαρχία ασκείται μόνο από το CLI.")

(defun %chat-wrap-handler (inner)
  "Τύλιξε τον handler του corpus-service με τον ΔΙΑΛΟΓΟ: /chat (η σελίδα),
   /ask?q=… (η ντετερμινιστική απάντηση του run-ask, με τις πηγές της) και
   /cmd?name=… (κουμπιά χειριστή: dispatch στο ΙΔΙΟ μητρώο εντολών —
   find-command — μέσα από κλειστό whitelist, ΜΟΝΟ για τον δημιουργό).
   Κάθε άλλο μονοπάτι περνά ανέγγιχτο στο service."
  (lambda (req)
    (let ((path (orchestrator.http:http-request-path req)))
      (cond
        ((string= path "/chat")
         (orchestrator.http:respond 200 +chat-page+
                                    "Content-Type" "text/html; charset=utf-8"))
        ((string= path "/ask")
         (let* ((q (cdr (assoc "q" (orchestrator.http:http-request-query req)
                               :test #'string=)))
                ;; ΑΚΡΟΑΤΗΡΙΟ: ενδοσκόπηση/ατζέντα ΜΟΝΟ στον δημιουργό. Χωρίς
                ;; LAWMAX_CREATOR_TOKEN (προσωπική εγκατάσταση): η τοπική θύρα
                ;; ΕΙΝΑΙ ο δημιουργός. Με token: απαιτείται ?key=… που ταιριάζει.
                (key (cdr (assoc "key" (orchestrator.http:http-request-query req)
                                 :test #'string=)))
                (sid (cdr (assoc "s" (orchestrator.http:http-request-query req)
                                 :test #'string=)))
                ;; Η ΜΙΑ έδρα ταυτότητας δημιουργού (cli-util) — καμία inline επανάληψη
                (audience (if (%creator-request-authorised-p key) :creator :guest))
                ;; μνήμη ΑΝΑ συνεδρία — ο διάλογος του ενός δεν αγγίζει του άλλου
                (*ask-memory* (if sid (%session-memory sid) *ask-memory*))
                (answer (if (and q (plusp (length q)))
                            (orchestrator.self-model:with-audience (audience)
                              (with-output-to-string (*standard-output*)
                                (handler-case (run-ask (list q))
                                  (error (e) (format t "σφάλμα: ~A~%" e)))))
                            "κενή ερώτηση")))
           (orchestrator.http:respond 200 answer
                                      "Content-Type" "text/plain; charset=utf-8")))
        ((string= path "/cmd")
         ;; ΚΟΥΜΠΙΑ ΧΕΙΡΙΣΤΗ: ίδια πύλη ταυτότητας με το /ask (token ⇒ key),
         ;; κλειστό whitelist, dispatch στο ΕΝΑ μητρώο εντολών — μηδέν δεύτερη
         ;; υλοποίηση οποιασδήποτε λειτουργίας.
         (let* ((name (cdr (assoc "name" (orchestrator.http:http-request-query req)
                                  :test #'string=)))
                (key (cdr (assoc "key" (orchestrator.http:http-request-query req)
                                 :test #'string=)))
                (creator-p (%creator-request-authorised-p key)))
           (cond
             ((not creator-p)
              (orchestrator.http:respond 403 "μόνο ο δημιουργός εκτελεί εντολές (λείπει/λάθος key)"
                                         "Content-Type" "text/plain; charset=utf-8"))
             ((not (member name +chat-ops-whitelist+ :test #'string=))
              (orchestrator.http:respond 400
                                         (format nil "η εντολή ~A δεν είναι στο whitelist των κουμπιών: ~{~A~^ ~}"
                                                 (or name "(κενή)") +chat-ops-whitelist+)
                                         "Content-Type" "text/plain; charset=utf-8"))
             (t
              (let ((out (with-output-to-string (*standard-output*)
                           (handler-case
                               (let ((rc (funcall (find-command name) nil)))
                                 (format t "~%── exit: ~A ──~%" rc))
                             (error (e) (format t "σφάλμα: ~A~%" e))))))
                (orchestrator.http:respond 200 out
                                           "Content-Type" "text/plain; charset=utf-8"))))))
        (t (funcall inner req))))))

(defun serve-corpus ()
  "Start the AI-first MULTI-corpus HTTP service: every κώδικας is served under
   its own /<corpus>/ prefix with a shared top-level catalog. PORT and
   CORPUS_BASE_URI are read from the environment."
  (let* ((port (let ((p (uiop:getenv "PORT")))
                 (or (and p (parse-integer p :junk-allowed t)) 8080)))
         (base (or (uiop:getenv "CORPUS_BASE_URI") "https://stavropouloslaw.com/eli")))
    (format t "~%Building corpora...~%")
    (multiple-value-bind (corpora short->id) (build-all-corpora) ; (short . provider) — provider supports as-of
    (let* ((multi (orchestrator.corpus-service:make-multi-corpus-service
                   corpora :base-uri base
                   ;; [0088 Φ5β] διτεμπορικό /as-known ανά σώμα — provider μόνο
                   ;; όταν το short αντιστοιχεί σε γνωστό corpus-id (αλλιώς 501)
                   :as-known-provider-fn
                   (lambda (short)
                     (let ((cid (cdr (assoc short short->id :test #'string=))))
                       (and cid (%as-known-provider-for cid))))))
           (handler (%chat-wrap-handler
                     (orchestrator.corpus-service:multi-service-handler multi))))
      (when (null corpora) (error "serve: no corpora could be built"))
      ;; Φάση 3: ο ΕΝΙΑΙΟΣ ΓΡΑΦΟΣ ζει ΚΑΙ στον server — το /ask απαντά με
      ;; ζωντανά δομικά γεγονότα (%live-provision-facts), όχι σιωπηλό τίποτα.
      ;; Από στιγμιότυπο όταν οι είσοδοι είναι αμετάβλητες, αλλιώς χτίζεται.
      (format t "~%Building knowledge graph...~%")
      (handler-case
          (progn (%graph-ensure)
                 (format t "  γράφος: ~D κόμβοι · ~D ακμές~%"
                         (orchestrator.graph:node-count) (orchestrator.graph:edge-count)))
        (error (e) (format t "  ⚠ γράφος μη διαθέσιμος: ~A~%" e)))
      (format t "~%AI-first multi-corpus service: http://0.0.0.0:~D  (~{~A~^, ~})~%"
              port (mapcar #'car corpora))
      (format t "  GET /chat                           Ο ΔΙΑΛΟΓΟΣ — μίλα του από τον browser~%")
      (format t "  GET /ask?q=…                        μία ερώτηση, μία τεκμηριωμένη απάντηση~%")
      (format t "  GET /catalog.jsonld                 catalog of ALL codes~%")
      (format t "  GET /<corpus>/catalog.jsonld        per-code DCAT~%")
      (format t "  GET /<corpus>/corpus.jsonl          bulk dump~%")
      (format t "  GET /<corpus>/article/{eId}         single article (JSON)~%")
      (format t "  GET /<corpus>/as-known?article=…&valid=…&known=…  διτεμπορική απάντηση (422 σε αβεβαιότητα)~%")
      (format t "  GET /<corpus>/ (Accept: akn+xml|turtle|ld+json|jsonl|plain)~%")
      (format t "  GET /robots.txt, /.well-known/ai-corpus.json~%")
      (orchestrator.http:start-server handler :port port :host "0.0.0.0")
      (loop (sleep 3600))))))

(defun materialize-served-corpora ()
  "Pull every served code from its official state source (source.url in each
   config) and write its clean JSON. Returns the number refreshed. Codes with no
   source.url, or an unreachable source, are reported and skipped."
  (let ((n 0))
    (dolist (id *served-corpora*)
      (handler-case
          (progn
            (orchestrator.spec:select-corpus id)
            (let ((url (orchestrator.spec:config-get "source.url"))
                  (fmt (intern (string-upcase
                                (or (orchestrator.spec:config-get "source.format") "json"))
                               :keyword))
                  (json (orchestrator.spec:resolve-config-path "source.json")))
              (cond
                ((not (and url (stringp url) (plusp (length url))))
                 (format t "  – ~A: no source.url configured~%" id))
                ;; Δυαδική πηγή εκ κατασκευής (.docx/.pdf/.zip στο URL): το text
                ;; refresh δεν την αφορά — και δεν την κατεβάζουμε κάθε κύκλο
                ;; για να το ανακαλύψουμε. Η ενημέρωσή της περνά από την ροή
                ;; --fetch-pdf → --materialize-pdf (docx/pdf adapters). Αν το
                ;; URL πει ψέματα για τον τύπο του, το magic-byte φράγμα στο
                ;; fetch-url το πιάνει ούτως ή άλλως (:binary-content).
                ((multiple-value-bind (m g)
                     (cl-ppcre:scan-to-strings "(?i)\\.(docx?|xlsx?|zip|pdf)(?:[?#]|$)" url)
                   (when m
                     (format t "  – ~A: δυαδική πηγή .~A — ενημέρωση μέσω --fetch-pdf → --materialize-pdf~%"
                             id (string-downcase (aref g 0)))
                     t)))
                (t
                 (multiple-value-bind (cnt status)
                     (orchestrator.gov-source:materialize-corpus
                      :url url :format fmt :json-path json)
                   (if (eq status :ok)
                       (progn (incf n)
                              (format t "  ✓ ~A ← ~A (~D articles)~%" id url cnt))
                       (format t "  ✗ ~A: ~A~%" id status)))))))
        (error (e) (format t "  ✗ ~A: ~A~%" id e))))
    n))

(defun fetch-sources ()
  "One-shot: pull every code from its official state source."
  (format t "~%Pulling codes from official state sources (κρατική πηγή)...~%")
  (let ((n (materialize-served-corpora)))
    (format t "~%Refreshed ~D corpus(es) from source.~%" n)
    0))

(defun fetch-pdf-sources ()
  "Pull each code's PDF DIRECTLY from its source — zero manual uploads. The ΦΕΚ
   number in each config (corpus.publication.fek_number) maps to a deterministic
   PUBLIC blob URL, so the PDF is fetched in PURE LISP (drakma) — no browser, no
   anti-bot. If the ΦΕΚ can't be parsed, fall back to source.fetch_cmd (external
   fetcher). The download is validated (%PDF magic). Then --run-all-pipelines
   codifies whatever was refreshed."
  (format t "~%Λήψη PDF κωδίκων ΑΠΕΥΘΕΙΑΣ από την πηγή (δημόσιο ΦΕΚ blob)...~%")
  (let ((n 0)
        (parse-fek (find-symbol "PARSE-FEK-REF" :orchestrator.legal-id))
        (blob-fetch (find-symbol "FETCH-FEK-BLOB" :orchestrator.document-fetch))
        (url-fetch (find-symbol "FETCH-URL-PDF" :orchestrator.document-fetch))
        (cmd-fetch (find-symbol "FETCH-PDF" :orchestrator.document-fetch))
        (docx-fetch (find-symbol "FETCH-URL-DOCX" :orchestrator.document-fetch)))
    (dolist (id *served-corpora*)
      (handler-case
          (progn
            (orchestrator.spec:select-corpus id)
            (let* ((pdf (ignore-errors (orchestrator.spec:resolve-config-path "source.pdf")))
                   (cmd (ignore-errors (orchestrator.spec:config-get "source.fetch_cmd")))
                   (pdfurl (ignore-errors (orchestrator.spec:config-get "source.pdf_url")))
                   (fekstr (ignore-errors (orchestrator.spec:config-get "corpus.publication.fek_number")))
                   (fek (and parse-fek fekstr (funcall parse-fek fekstr)))
                   (docx    (ignore-errors (orchestrator.spec:resolve-config-path "source.docx")))
                   (docxurl (ignore-errors (orchestrator.spec:config-get "source.docx_url"))))
              (cond
                ;; 0) AUTHORITATIVE DIGITAL .docx wins (e.g. Υπ. Δικαιοσύνης ΚΠολΔ):
                ;;    pure-Lisp drakma GET, ZIP-magic validated → source.docx, which
                ;;    --materialize-pdf then reads via docx-adapter. MUST precede the
                ;;    ΦΕΚ-blob branch — this code's 1985 gazette blob is a scan.
                ;;    (Needs a Greek network egress; the Ministry host geo-blocks.)
                ((and docx-fetch docx docxurl
                      (plusp (length (string-trim " " docx)))
                      (plusp (length (string-trim " " docxurl))))
                 (multiple-value-bind (ok status) (funcall docx-fetch docxurl docx)
                   (if ok (progn (incf n) (format t "  ✓ ~A ← .docx (κρατική πηγή) → ~A~%" id docx))
                       (format t "  ✗ ~A: ~A (.docx URL ~A)~%" id status docxurl))))
                ((or (null pdf) (zerop (length (or pdf "")))) (format t "  ✗ ~A: δεν έχει source.pdf~%" id))
                ;; 1) EXPLICIT authoritative PDF URL wins (pure Lisp drakma): the
                ;;    operator pointed source.pdf_url at the clean digital source
                ;;    (e.g. the Ministry/Isokratis PDF), which must override the
                ;;    auto-derived ΦΕΚ blob — for an old code that blob is a scan.
                ((and pdfurl (plusp (length (string-trim " " pdfurl))))
                 (multiple-value-bind (ok status) (funcall url-fetch pdfurl pdf)
                   (if ok (progn (incf n) (format t "  ✓ ~A ← direct URL (pdf_url) → ~A~%" id pdf))
                       (format t "  ✗ ~A: ~A (URL ~A)~%" id status pdfurl))))
                ;; 2) Otherwise the ΦΕΚ number → public blob, pure Lisp.
                (fek
                 (multiple-value-bind (ok status)
                     (funcall blob-fetch (getf fek :series) (getf fek :number) (getf fek :year) pdf)
                   (if ok
                       (progn (incf n) (format t "  ✓ ~A ← ΦΕΚ ~A ~A/~A (blob) → ~A~%"
                                               id (getf fek :series) (getf fek :number) (getf fek :year) pdf))
                       (format t "  ✗ ~A: ~A (ΦΕΚ ~A ~A/~A)~%" id status
                               (getf fek :series) (getf fek :number) (getf fek :year)))))
                ;; 3) Fallback: external fetch_cmd.
                ((and cmd (plusp (length (string-trim " " cmd))))
                 (multiple-value-bind (ok status) (funcall cmd-fetch cmd pdf)
                   (if ok (progn (incf n) (format t "  ✓ ~A ← fetch_cmd → ~A~%" id pdf))
                       (format t "  ✗ ~A: ~A~%" id status))))
                (t (format t "  – ~A: ούτε αναγνωρίσιμο ΦΕΚ ούτε source.fetch_cmd~%" id)))))
        (error (e) (format t "  ✗ ~A: ~A~%" id e))))
    (format t "~%Ελήφθησαν ~D PDF ΑΠΕΥΘΕΙΑΣ από την πηγή. Τρέξε --run-all-pipelines για κωδικοποίηση.~%" n)
    0))

(defun %source-json-populated-p (path)
  "True if PATH exists and already holds a non-empty JSON article array (not []/blank)
   — used to refuse overwriting a real corpus with an empty extraction."
  (and path (probe-file path)
       (let ((s (string-trim '(#\Space #\Tab #\Newline #\Return)
                             (or (ignore-errors (uiop:read-file-string path)) ""))))
         (and (> (length s) 2) (not (string= s "[]"))))))

(defun %source-json-count (path)
  "Number of article objects currently in the source.json at PATH, or 0 if absent /
   unreadable. Used as the SHRINK baseline so a partial/garbage re-extraction cannot
   silently overwrite a large, good corpus with a handful of junk articles."
  (or (ignore-errors
        (let ((data (jonathan:parse (uiop:read-file-string path) :as :alist)))
          (if (listp data) (length data) 0)))
      0))

;;; ----------------------------------------------------------------------------
;;; source.json PROVENANCE — the JSON fallback must not promote an unverified /
;;; tampered / foreign file to "authoritative corpus". A sidecar <json>.prov.json
;;; binds the file's content hash (and, when known, the primary source-digest +
;;; extraction-method) so the fallback can REFUSE anything that does not match.
;;; ----------------------------------------------------------------------------

(defun %sha256-string (s)
  "«sha256:<hex>» του UTF-8 του S — η έδρα content-hash της provenance (ΔΙΑΚΡΙΤΗ
   έννοια από το Merkle: ωμό sha256, χωρίς domain prefix 0x00). [P1.5-A] Πριν
   έδειχνε μέσω find-symbol στο διαγραμμένο COMPUTE-SHA256-STRING ⇒ σιωπηλά NIL·
   τώρα υπολογίζει άμεσα (ironclad)."
  (format nil "sha256:~(~{~2,'0x~}~)"
          (coerce (ironclad:digest-sequence
                   :sha256 (babel:string-to-octets s :encoding :utf-8))
                  'list)))

(defun %sha256-file (path)
  "«sha256:<hex>» των ΩΜΩΝ bytes του PATH (σωστό για binary πηγές, π.χ. .docx).
   NIL μόνο αν το αρχείο δεν υπάρχει (τίμιο απόν, όχι σιωπηλή αποτυχία seat)."
  (when (probe-file path)
    (format nil "sha256:~(~{~2,'0x~}~)"
            (coerce (ironclad:digest-file :sha256 path) 'list))))

(defun %source-prov-path (json-path)
  (concatenate 'string (namestring json-path) ".prov.json"))

(defun %corpus-errata ()
  "The declared errata of the ACTIVE corpus: config source.errata is a list of
   entries {article, from, to, reason, page}. This is the gazette practice --
   a documented editorial correction of a defect in the SOURCE's own text
   layer (e.g. a misplaced line fragment poppler cannot re-order because the
   glyph boxes are anomalous in the PDF itself). NEVER a silent patch: each
   entry names its article, exact text, justification and source page, and is
   recorded in the provenance sidecar."
  (let ((v (ignore-errors (orchestrator.spec:config-get "source.errata"))))
    (when (listp v) v)))

(defun %erratum-field (e key)
  "Read KEY from erratum entry E, whatever shape the YAML loader produced."
  (cond ((hash-table-p e)
         (or (gethash key e)
             (gethash (intern (string-upcase key) :keyword) e)))
        ((consp e)
         (or (cdr (assoc key e :test #'equalp))
             (getf e (intern (string-upcase key) :keyword))))))

(defun %apply-errata (iirs corpus-id)
  "Apply the corpus's declared errata to IIRS. Each entry must match its
   article and its FROM text EXACTLY ONCE -- anything else is reported loudly
   and skipped (an erratum that no longer matches is stale and must be
   reviewed, not guessed). Returns the list of applied entries (for the
   provenance record)."
  (let ((applied '())
        (label-fn (find-symbol "ARTICLE-LABEL" :orchestrator.model))
        (content-fn (find-symbol "ARTICLE-CONTENT" :orchestrator.model)))
    (dolist (e (%corpus-errata) (nreverse applied))
      (let* ((art  (princ-to-string (or (%erratum-field e "article") "")))
             (from (princ-to-string (or (%erratum-field e "from") "")))
             (to   (princ-to-string (or (%erratum-field e "to") "")))
             (why  (princ-to-string (or (%erratum-field e "reason") "")))
             (iir  (find art iirs
                         :test #'string=
                         :key (lambda (x) (princ-to-string (funcall label-fn x))))))
        (cond
          ((null iir)
           (format t "  ✗ erratum ~A/~A: το άρθρο δεν βρέθηκε — ΔΕΝ εφαρμόστηκε~%"
                   corpus-id art))
          ((zerop (length from))
           (format t "  ✗ erratum ~A/~A: κενό 'from' — ΔΕΝ εφαρμόστηκε~%" corpus-id art))
          (t
           (let* ((body (funcall content-fn iir))
                  (hits (loop with start = 0 with n = 0
                              for pos = (search from body :start2 start)
                              while pos do (incf n) (setf start (1+ pos))
                              finally (return n))))
             (cond
               ((/= hits 1)
                (format t "  ✗ erratum ~A/~A: το 'from' βρέθηκε ~D φορές (απαιτείται ακριβώς 1) — ΔΕΝ εφαρμόστηκε~%"
                        corpus-id art hits))
               (t
                (let ((pos (search from body)))
                  (funcall (fdefinition (list 'setf content-fn))
                           (concatenate 'string
                                        (subseq body 0 pos) to
                                        (subseq body (+ pos (length from))))
                           iir))
                (format t "  ✦ erratum ~A/~A εφαρμόστηκε: ~A~%" corpus-id art why)
                (push (list (cons "article" art) (cons "from" from)
                            (cons "to" to) (cons "reason" why)
                            (cons "page" (princ-to-string (or (%erratum-field e "page") ""))))
                      applied))))))))))

(defun %write-source-provenance (json-path &key source-digest extraction-method date errata)
  "Stamp a provenance sidecar for the source.json at JSON-PATH: the SHA-256 of its
   CURRENT bytes plus the primary SOURCE-DIGEST / EXTRACTION-METHOD / DATE when known.
   Written right after (re)materialize so every served source.json carries a record a
   third party — and the JSON fallback gate — can check."
  (ignore-errors
    (let* ((content (uiop:read-file-string json-path))
           (chash   (%sha256-string content)))
      (when chash
        (with-open-file (o (%source-prov-path json-path) :direction :output
                                                          :if-exists :supersede
                                                          :if-does-not-exist :create
                                                          :external-format :utf-8)
          (write-string
           (jonathan:to-json
            (list (cons "schema" "slw-source-prov/1")
                  (cons "content_sha256" chash)
                  (cons "source_digest" (or source-digest :null))
                  (cons "extraction_method" (or extraction-method :null))
                  (cons "date" (or date :null))
                  ;; the applied editorial errata — machine-readable, so the
                  ;; independent auditor replays them instead of flagging them
                  (cons "errata" (or errata #())))
            :from :alist)
           o))
        chash))))

(defun %source-provenance-status (json-path)
  "Η ΜΙΑ ετυμηγορία provenance του source.json — (values STATUS WANT HAVE):
     :valid     sidecar παρόν ΚΑΙ το content_sha256 του ταυτίζεται με τα τρέχοντα bytes
     :unstamped κανένα sidecar (foreign/legacy αρχείο — ποτέ δεν σφραγίστηκε)
     :tampered  sidecar παρόν αλλά hash mismatch (αλλαγμένο/υποκατεστημένο αρχείο —
                π.χ. stale working copy που το git pull δεν ξαναγράφει)
     :missing   το ίδιο το json απουσιάζει (ή δεν είναι καν ρυθμισμένο)
   WANT = ο σφραγισμένος hash του sidecar, HAVE = ο hash των τρεχόντων bytes (όπου
   ορίζονται). Κάθε καταναλωτής provenance κρίνει ΜΕΣΩ αυτής της έδρας — ποτέ με
   δική του σύγκριση hash."
  (cond
    ((or (null json-path) (not (probe-file json-path)))
     (values :missing nil nil))
    ((not (probe-file (%source-prov-path json-path)))
     (values :unstamped nil (%sha256-string (uiop:read-file-string json-path))))
    (t
     (let* ((rec  (ignore-errors
                    (jonathan:parse (uiop:read-file-string (%source-prov-path json-path))
                                    :as :plist)))
            (want (and rec (getf rec :|content_sha256|)))
            (have (%sha256-string (uiop:read-file-string json-path))))
       (if (and want have (string= want have))
           (values :valid want have)
           (values :tampered want have))))))

(defun %title-key (title)
  (multiple-value-bind (id) (%parse-article-title title) (or id title)))

(defun materialize-pdf-sources ()
  "Extract each served code's source.pdf into its source.json (the canonical clean
   text the PDF produced) — so the consolidation, the intelligence suite and the
   served corpus ALL read the REAL code from its source, not a placeholder. Run
   after --fetch-pdf (or whenever a source.pdf changes).

   SAFETY: an extraction that yields 0 articles (a scanned ΦΕΚ with no text layer)
   never overwrites an already-populated source.json — the real corpus is preserved
   and the missing digital source is reported instead of silently wiped."
  (format t "~%Υλικοποίηση PDF → source.json (ο πραγματικός κώδικας από την πηγή)...~%")
  (let ((n 0))
    (dolist (id *served-corpora*)
      (handler-case
          (progn
            (orchestrator.spec:select-corpus id)
            (ignore-errors (orchestrator.gr-syntagma:register-active-corpus))
            (let* ((docx (ignore-errors (orchestrator.spec:resolve-config-path "source.docx")))
                   (pdf  (ignore-errors (orchestrator.spec:resolve-config-path "source.pdf")))
                   (json (ignore-errors (orchestrator.spec:resolve-config-path "source.json")))
                   ;; Authoritative DIGITAL source wins: a .docx (real text — e.g. the
                   ;; Υπ. Δικαιοσύνης ΚΠολΔ) over a source.pdf that may be a scanned ΦΕΚ.
                   (src  (cond ((and docx (plusp (length docx)) (probe-file docx)) docx)
                               ((and pdf  (plusp (length pdf))  (probe-file pdf))  pdf)
                               (t nil))))
              (cond
                ((null src)
                 (format t "  – ~A: δεν υπάρχει source.docx/source.pdf~@[ (~A)~]~%" id (or docx pdf)))
                ((or (null json) (zerop (length (or json ""))))
                 (format t "  ✗ ~A: δεν έχει source.json~%" id))
                (t (let* ((iirs (if (string-equal (or (pathname-type src) "") "docx")
                                    (orchestrator.engine.sbcl:docx-adapter src)
                                    (orchestrator.engine.sbcl:pdf-adapter src)))
                          ;; Ρητή αλυσίδα δηλωμένων config τιμών (όχι κατασκευή)·
                          ;; το config-get δεν σηματοδοτεί για απόν κλειδί.
                          (date (or (orchestrator.spec:config-get "corpus.publication.date")
                                    (orchestrator.spec:config-get "corpus.modified_date"))))
                     (cond
                       ;; 0 articles → the PDF has no text layer (scanned ΦΕΚ). NEVER
                       ;; overwrite a populated corpus with an empty one.
                       ((null iirs)
                        (if (%source-json-populated-p json)
                            (progn
                              ;; preserve the existing corpus AND ensure it carries a
                              ;; provenance record (origin not re-derived this run).
                              (unless (eq :valid (%source-provenance-status json))
                                (%write-source-provenance json :extraction-method "preserved-no-digital-source" :date date))
                              (format t "  ⚠ ~A: 0 άρθρα (scanned PDF / χωρίς text layer) — ΔΙΑΤΗΡΕΙΤΑΙ το υπάρχον ~A [provenance ok]. Χρειάζεται ΨΗΦΙΑΚΗ πηγή (Υπ. Δικαιοσύνης/Ισοκράτης).~%" id json))
                            (format t "  – ~A: 0 άρθρα (scanned PDF / χωρίς text layer) — χρειάζεται ΨΗΦΙΑΚΗ πηγή (Υπ. Δικαιοσύνης/Ισοκράτης).~%" id)))
                       ;; SHRINK GUARD: a non-nil but suspiciously small extraction
                       ;; (e.g. one junk article from a wrong-layout PDF) must not
                       ;; overwrite a large, good corpus. Refuse when the new count is
                       ;; below half the existing populated count unless explicitly
                       ;; overridden (ORCHESTRATOR_ALLOW_SHRINK=1).
                       ((let ((old (%source-json-count json))
                              (new (length iirs)))
                          (and (%source-json-populated-p json)
                               (< new (floor old 2))
                               (not (uiop:getenvp "ORCHESTRATOR_ALLOW_SHRINK"))))
                        (progn
                          (unless (eq :valid (%source-provenance-status json))
                            (%write-source-provenance json :extraction-method "preserved-shrink-guard" :date date))
                          (format t "  ⚠ ~A: εξαγωγή ~D άρθρων ενώ το υπάρχον ~A έχει ~D — ΥΠΟΠΤΗ ΣΥΡΡΙΚΝΩΣΗ, ΔΙΑΤΗΡΕΙΤΑΙ το υπάρχον (θέσε ORCHESTRATOR_ALLOW_SHRINK=1 για παράκαμψη).~%"
                                  id (length iirs) json (%source-json-count json))))
                       (t (let* ((errata (%apply-errata iirs id))
                                 (cnt (orchestrator.gov-source:write-source-json iirs json date)))
                            (incf n)
                            ;; O-3: stamp provenance binding this source.json to the
                            ;; primary source it was derived from, so the JSON fallback
                            ;; can refuse an unstamped/tampered/foreign file later.
                            (%write-source-provenance
                             json
                             :source-digest (%sha256-file src)
                             :extraction-method
                             (if (string-equal (or (pathname-type src) "") "docx")
                                 "docx-adapter+raw-text-fsm@1" "pdf-adapter+raw-text-fsm@1")
                             :date date
                             :errata errata)
                            (format t "  ✓ ~A: ~D άρθρα → ~A  [provenance stamped]~%" id cnt json)))))))))
        (error (e) (format t "  ✗ ~A: ~A~%" id e))))
    (format t "~%Υλικοποιήθηκαν ~D κώδικ~:@P από PDF — verify/serve/intelligence διαβάζουν πλέον τον πραγματικό κώδικα.~%" n)
    0))

;;; ── TIER 3: autonomy — the legal-id registry, ΦΕΚ discovery, the update loop ──

(defun %cfg (key) (ignore-errors (orchestrator.spec:config-get key)))

(defun build-legal-id-registry ()
  "Derive the legal-id registry from the served-corpora CONFIGS (single source of
   truth — identity lives in configs, not duplicated here). Returns a list of
   orchestrator.legal-id registry entries used to route a ΦΕΚ to the code(s) it
   amends."
  (let ((lid :orchestrator.legal-id) (entries '()))
    (dolist (id *served-corpora* (nreverse entries))
      (handler-case
          (progn
            (orchestrator.spec:select-corpus id)
            (let* ((short (or (%cfg "corpus.short_name") id))
                   (law (let ((v (%cfg "corpus.law_number")))
                          (and v (parse-integer (princ-to-string v) :junk-allowed t))))
                   (fek (funcall (find-symbol "PARSE-FEK-REF" lid)
                                 (or (%cfg "corpus.publication.fek_number") "")))
                   (year (or (getf fek :year)
                             (let ((d (%cfg "corpus.publication.date")))
                               (and (stringp d) (>= (length d) 4)
                                    (parse-integer d :end 4 :junk-allowed t)))))
                   (abbr (or (%cfg "corpus.citation_abbrev") (%cfg "corpus.abbrev")))
                   (name (%cfg "corpus.name"))
                   ;; Conservative enrichment: a code's distinctive HEAD word
                   ;; (e.g. «Σύνταγμα») routes its inflected mentions, but the
                   ;; generic «Κώδικας» head is skipped so it cannot match every
                   ;; code. Codes with a law-number route on that stronger signal.
                   (head (and (stringp name)
                              (first (cl-ppcre:split "\\s+" (string-trim " " name)))))
                   (head-alias (and head (>= (length head) 5)
                                    (not (search "ΚΩΔΙΚ"
                                                 (funcall (find-symbol "NORMALIZE-GREEK" lid) head)))
                                    head))
                   ;; Distinctive inflected phrases from the config («Ποινικό Κώδικα»,
                   ;; «Ποινικής Δικονομίας», «Αστικού Κώδικα» …) — the strong routing
                   ;; signal that matches an amending ΦΕΚ's ALL-CAPS title.
                   (phrases (let* ((v (%cfg "corpus.routing_phrases"))
                                   ;; a 1-item YAML sequence can come back as a bare
                                   ;; string — normalise both shapes to a list.
                                   (vs (cond ((stringp v) (list v)) ((listp v) v) (t nil))))
                              (remove nil (mapcar (lambda (x)
                                                    (let ((s (and x (string-trim " " (princ-to-string x)))))
                                                      (and s (plusp (length s)) s)))
                                                  vs))))
                   (aliases (remove nil (append (list (and abbr (princ-to-string abbr)) head-alias)
                                                phrases))))
              (push (funcall (find-symbol "MAKE-REGISTRY-ENTRY" lid) short
                             :law-number law :year year :name name
                             :aliases aliases
                             :fek-series (getf fek :series) :fek-number (getf fek :number)
                             :eli-prefix (%cfg "corpus.eli_prefix")
                             :source-pdf (%cfg "source.pdf") :fetch-cmd (%cfg "source.fetch_cmd"))
                    entries)))
        (error (e) (format t "  ⚠ registry: ~A παραλείφθηκε (~A)~%" id e))))))

(defun %iso-date (s)
  "Normalize a date to yyyy-mm-dd (accepts yyyy-mm-dd or mm/dd/yyyy), else NIL."
  (when (and (stringp s) (plusp (length s)))
    (cond ((cl-ppcre:scan "^\\d{4}-\\d{2}-\\d{2}" s) (subseq s 0 10))
          (t (cl-ppcre:register-groups-bind (mo d y) ("^(\\d{1,2})/(\\d{1,2})/(\\d{4})" s)
               (format nil "~A-~2,'0D-~2,'0D" y (parse-integer mo) (parse-integer d)))))))

(defun %laws->json (laws)
  "Serialize [(\"id\".. \"date\".. \"fek\".. \"text\"..) …] to a clean JSON array."
  (with-output-to-string (s)
    (write-char #\[ s)
    (loop for law in laws for first = t then nil do
      (unless first (write-char #\, s))
      (flet ((g (k) (%json-scalar (or (cdr (assoc k law :test #'string=)) ""))))
        (format s "{\"id\":~A,\"date\":~A,\"fek\":~A,\"text\":~A}"
                (g "id") (g "date") (g "fek") (g "text"))))
    (write-char #\] s)))

(defun auto-update ()
  "AUTONOMOUS UPDATE — Ο ΠΛΗΡΗΣ ΚΥΚΛΟΣ με ΜΙΑ εντολή: pull every code from its
   source, codify, consolidate, verify against the golden, (re)issue SIGNED
   proofs, emit the reasoning substrate (references+hypergraph+intelligence),
   and SEAL with the full gate plenary. Phases are isolated; returns non-zero
   if codification, golden verification or the plenary fails, so cron can alert.
     AUTO_UPDATE_FETCH=0    skip the headless fetch (reuse existing source.pdf)
     AUTO_UPDATE_GATES=0    skip the final gate plenary (fast cycle only)
     AUTO_UPDATE_PUBLISH=1  also emit the static site (signed) at the end
     PCL_SIGNING_KEY/PCL_PUBLIC_KEY  sign the corpus roots (TIER 1-A)"
  (let ((fetch (not (string= "0" (or (uiop:getenv "AUTO_UPDATE_FETCH") "1"))))
        (gates (not (string= "0" (or (uiop:getenv "AUTO_UPDATE_GATES") "1"))))
        (publish (string= "1" (or (uiop:getenv "AUTO_UPDATE_PUBLISH") "0")))
        (codify-rc 0) (verify-rc 0) (gates-rc 0))
    (format t "~%╔══ ΠΛΗΡΗΣ ΚΥΚΛΟΣ: fetch → codify → verify → sign → substrate → gates ══╗~%")
    (when fetch
      (format t "~%[1/7] Λήψη ΑΠΕΥΘΕΙΑΣ από την πηγή (headless)~%")
      (ignore-errors (fetch-pdf-sources)))
    (format t "~%[2/7] Υλικοποίηση PDF → source.json~%")
    (ignore-errors (materialize-pdf-sources))
    (format t "~%[3/7] Κωδικοποίηση & ενοποίηση όλων των κωδίκων~%")
    (setf codify-rc (or (ignore-errors (run-all-pipelines)) 1))
    (format t "~%[4/7] Έλεγχος ορθότητας έναντι golden (drift detection)~%")
    (setf verify-rc (or (ignore-errors (verify-all-corpora)) 1))
    (format t "~%[5/7] Έκδοση υπογεγραμμένων αποδείξεων (Proof-Carrying Law)~%")
    (ignore-errors (emit-proofs))
    (format t "~%[6/7] Υπόστρωμα συλλογισμού: παραπομπές + υπεργράφος + νοημοσύνη~%")
    (ignore-errors (emit-references))
    (ignore-errors (emit-hypergraph))
    (ignore-errors (verify-all-intelligence))
    (if gates
        (progn
          (format t "~%[7/7] ΣΦΡΑΓΙΔΑ: ολομέλεια πυλών~%")
          (setf gates-rc (or (ignore-errors (run-all-gates)) 1)))
        (format t "~%[7/7] Πύλες: ΠΑΡΑΛΕΙΦΘΗΚΑΝ (AUTO_UPDATE_GATES=0) — τρέξε --gates χωριστά~%"))
    (when publish
      (format t "~%[+]  Δημοσίευση static site (born-cited, signed)~%")
      (ignore-errors (emit-site)))
    ;; Per-phase status, so the final verdict is never self-contradictory.
    (let ((rc (max codify-rc verify-rc gates-rc)))
      (format t "~%╠══ ΑΝΑΦΟΡΑ ΦΑΣΕΩΝ ══╣~%")
      (format t "  Κωδικοποίηση/ενοποίηση : ~:[✗ ΑΠΕΤΥΧΕ~;✓ ΟΚ~]~%" (zerop codify-rc))
      (format t "  Έλεγχος golden (drift) : ~:[✗ ΑΠΕΤΥΧΕ~;✓ ΟΚ~]~%" (zerop verify-rc))
      (format t "  Ολομέλεια πυλών        : ~:[✗ ΑΠΕΤΥΧΕ~;✓ ΟΚ~]~@[ (παραλείφθηκε)~]~%"
              (zerop gates-rc) (and (not gates) t))
      (format t "╚══ Ολοκληρώθηκε — rc=~D ~:[(ΣΦΑΛΜΑ σε φάση παραπάνω)~;(όλα καθαρά)~] ══╝~%"
              rc (zerop rc))
      rc)))

(defun %html-escape (s)
  (with-output-to-string (o)
    (loop for ch across (or s "")
          do (case ch (#\& (write-string "&amp;" o)) (#\< (write-string "&lt;" o))
                   (#\> (write-string "&gt;" o)) (t (write-char ch o))))))

(defun publish-verifier-assets (site-dir &optional public-jwk)
  "Publish the public verifiers + PCL-1 spec INTO the site so the URLs advertised
   in llms.txt / ai-corpus.json / JSON-LD actually resolve: <site>/verify/ gets
   verify.py, verify.mjs, README.md and a browsable index.html; <site>/ gets
   PROOF-CARRYING-LAW.html. When PUBLIC-JWK is given, the root-authority public key
   is published as <site>/verify/pcl-public-key.jwk so the bundled verifiers
   auto-PIN it (authenticity is proven against this key, never an embedded one).
   Source paths are overridable; best-effort."
  (handler-case
      (let* ((root (uiop:ensure-directory-pathname site-dir))
             (vsrc (uiop:ensure-directory-pathname
                    (or (%non-blank (uiop:getenv "VERIFY_ASSETS_DIR")) (orchestrator.paths:institution-dir "deployment/verify/"))))
             (spec (or (%non-blank (uiop:getenv "PCL_SPEC_FILE")) (orchestrator.paths:institution-dir "deployment/PROOF-CARRYING-LAW.md")))
             (vdir (uiop:ensure-directory-pathname (merge-pathnames "verify/" root))))
        (ensure-directories-exist vdir)
        (dolist (f '("verify.py" "verify.mjs" "README.md"))
          (let ((src (merge-pathnames f vsrc)))
            (when (probe-file src)
              (uiop:copy-file src (merge-pathnames f vdir)))))
        ;; Pin the trust anchor next to the verifiers.
        (when (%non-blank public-jwk)
          (alexandria:write-string-into-file
           public-jwk (merge-pathnames "pcl-public-key.jwk" vdir) :if-exists :supersede))
        ;; A browsable landing for /verify/.
        (with-open-file (o (merge-pathnames "index.html" vdir) :direction :output
                           :if-exists :supersede :if-does-not-exist :create :external-format :utf-8)
          (write-string
           "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"UTF-8\"><title>Verify — Proof-Carrying Law (PCL-1)</title></head><body><h1>Verify Greek law against the signed root</h1><p>Independent, zero-dependency verifiers. Don't trust — verify.</p><ul><li><a href=\"verify.py\">verify.py</a> — pure Python stdlib</li><li><a href=\"verify.mjs\">verify.mjs</a> — Node.js builtin crypto</li><li><a href=\"README.md\">README.md</a></li><li><a href=\"../PROOF-CARRYING-LAW.html\">PCL-1 specification</a></li></ul></body></html>" o))
        ;; The spec as a self-contained HTML page (markdown shown verbatim).
        (when (probe-file spec)
          (with-open-file (o (merge-pathnames "PROOF-CARRYING-LAW.html" root) :direction :output
                             :if-exists :supersede :if-does-not-exist :create :external-format :utf-8)
            (format o "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"UTF-8\"><title>Proof-Carrying Law (PCL-1) — Specification</title><style>body{max-width:48rem;margin:2rem auto;font:14px/1.5 system-ui;padding:0 1rem}pre{white-space:pre-wrap;word-wrap:break-word}</style></head><body><pre>~A</pre></body></html>"
                    (%html-escape (uiop:read-file-string spec :external-format :utf-8)))))
        (format t "  ✓ Published verifiers + spec under ~Averify/~%" (namestring root)))
    (error (e) (format t "  ⚠ could not publish verifier assets: ~A~%" e))))

(defun emit-site ()
  "Generate the complete Cloudflare-Pages-ready static site (human HTML + AI
   structured data) for every served code. SITE_OUTPUT_DIR, CORPUS_BASE_URI,
   FIRM_NAME and FIRM_URL are read from the environment."
  (let ((out (or (uiop:getenv "SITE_OUTPUT_DIR") (orchestrator.paths:institution-dir "site")))
        (base (or (uiop:getenv "CORPUS_BASE_URI") "https://stavropouloslaw.com/eli")))
    (let ((fn (uiop:getenv "FIRM_NAME")) (fu (uiop:getenv "FIRM_URL")))
      (when fn (setf orchestrator.static-site:*firm-name* fn))
      (when fu (setf orchestrator.static-site:*firm-url* fu)))
    (format t "~%Building corpora for static site...~%")
    (let* ((corpora (build-all-corpora))
           (docs (mapcar (lambda (pair) (cons (car pair) (funcall (cdr pair)))) corpora)))
      (when (null docs) (error "emit-site: no corpora could be built"))
      (multiple-value-bind (priv pub-jwk) (%pcl-signing-material)
        (when priv (format t "  🔑 Root authority key loaded — site corpus roots will be SIGNED.~%"))
        (orchestrator.static-site:emit-static-site
         docs out :base-uri base :private-key priv :public-jwk pub-jwk
         :anchored-at ;; [P1.5-C] commitment-time από την έδρα χρόνου (ΟΧΙ ψεύτικη σταθερά)·
                          ;; ο ΑΠΟΔΕΔΕΙΓΜΕΝΟΣ χρόνος ζει στο RFC-3161 receipt του release.
                          (orchestrator.time:format-iso8601 (orchestrator.time:require-deterministic-time)))
        (publish-verifier-assets out pub-jwk))
      (format t "~%✓ Static site emitted to ~A  (~D corpora, base ~A)~%" out (length docs) base)
      (format t "  Deploy: wrangler pages deploy ~A~%" out)
      0)))

(defun %count-article-files (dir)
  "Number of ARTICLES in DIR — counts only article-*.html (one per article). The
   output space writes 5 formats per article (.ttl/.jsonld/.html/.hash/.txt), so
   counting every article-* file over-reports ×5; restrict to .html for the true count."
  (count-if (lambda (p)
              (let ((n (pathname-name p)))
                (and n (string-equal (or (pathname-type p) "") "html")
                     (>= (length n) 8) (string= (subseq n 0 8) "article-"))))
            (ignore-errors (uiop:directory-files (uiop:ensure-directory-pathname dir)))))

(defun run-all-pipelines ()
  "Process EVERY served code through the full pipeline, each in STRICT isolation:
   its own config (source.pdf, no globbing) and its own /output/<short_name>/
   directory — corpora can never read each other's source or overwrite each
   other's output. Continues past any single failure and prints a per-code
   summary so a missing input PDF (placeholder fallback) is obvious at a glance."
  (let ((base (or (uiop:getenv "ORCHESTRATOR_OUTPUT_DIR") (orchestrator.paths:institution-dir "output/")))
        (rows '()))
    (dolist (id *served-corpora*)
      (format t "~%~A~%  CODE: ~A~%~A~%"
              (make-string 63 :initial-element #\=) id
              (make-string 63 :initial-element #\=))
      (let ((status "ok") (count 0) (dir ""))
        (handler-case
            (progn
              (run-pipeline id)            ; selects + isolates this corpus
              (setf dir (corpus-output-dir base)
                    count (%count-article-files dir)))
          (error (e) (setf status (format nil "ERROR: ~A" e))
                     (ignore-errors (setf dir (corpus-output-dir base)))))
        (push (list id dir count status) rows)))
    (setf rows (nreverse rows))
    (format t "~%~A~%  ALL CODES — SUMMARY (each in its own isolated space)~%~A~%"
            (make-string 72 :initial-element #\=) (make-string 72 :initial-element #\=))
    (format t "  ~14A ~9A  OUTPUT~%" "CODE" "ARTICLES")
    (dolist (r rows)
      (format t "  ~14A ~9D  ~A   [~A]~%" (first r) (third r) (second r) (fourth r)))
    (format t "~A~%" (make-string 72 :initial-element #\=))
    (let ((failed (count-if-not (lambda (r) (string= (fourth r) "ok")) rows))
          (thin (count-if (lambda (r) (and (string= (fourth r) "ok") (< (third r) 5))) rows)))
      (when (plusp thin)
        (format t "  ⚠ ~D code(s) produced <5 articles — likely a missing input PDF~%" thin)
        (format t "    (the pipeline fell back to the placeholder JSON). Add the PDF to input/.~%"))
      (when (plusp failed)
        (format t "  ✗ ~D code(s) errored — see the per-code logs above.~%" failed))
      (when (and (zerop thin) (zerop failed))
        (format t "  ✓ All codes processed cleanly into separate spaces.~%"))
      (if (zerop failed) 0 1))))

;;; ── Human-in-the-loop review queue (lawyer tool) ───────────────────────────

(defun %review-queue-file ()
  (or (uiop:getenv "REVIEW_QUEUE_FILE")
      (namestring (merge-pathnames "review-queue.sexp"
                                   (uiop:ensure-directory-pathname
                                    (or (uiop:getenv "ORCHESTRATOR_OUTPUT_DIR") (orchestrator.paths:institution-dir "output/")))))))

;; ΜΙΑ σειριοποίηση για το read-modify-write της ουράς εγκρίσεων: πολλά ταυτόχρονα
;; νήματα HTTP (cockpit) ή CLI+cockpit στην ΙΔΙΑ διεργασία δεν πατούν το ένα την
;; απόφαση του άλλου (lost update). Ενδο-διεργασιακό — η δια-διεργασιακή ασφάλεια
;; (δαίμονας σε ξεχωριστό process) είναι ρητά άλλη φάση (file-level CAS).
(defvar *review-queue-lock* (sb-thread:make-mutex :name "review-queue"))

(defmacro with-review-queue-lock (&body body)
  `(sb-thread:with-mutex (*review-queue-lock*) ,@body))

(defun load-review-queue ()
  (let ((q (funcall (find-symbol "MAKE-REVIEW-QUEUE" :orchestrator.review)))
        (f (%review-queue-file)))
    (when (probe-file f)
      (with-open-file (s f :external-format :utf-8)
        ;; FAIL-CLOSED: κενό αρχείο ⇒ nil (νόμιμα άδεια ουρά)· ΑΛΛΟΙΩΜΕΝΟ s-expr ⇒
        ;; το read ΣΗΜΑΤΟΔΟΤΕΙ (καμία σιωπηλή «άδεια ουρά» που κρύβει τις προτάσεις
        ;; του δαίμονα από τον άνθρωπο-αυθεντία — [0072] verify V3).
        (let ((state (read s nil nil)))
          (when state
            (funcall (find-symbol "RESTORE-QUEUE-STATE" :orchestrator.review) q state)))))
    q))

(defun save-review-queue (q)
  ;; ΑΤΟΜΙΚΗ αντικατάσταση (tmp+rename): crash στη μέση δεν αδειάζει ΠΟΤΕ
  ;; σιωπηλά την ουρά εγκρίσεων (Φάση 0).
  (let ((f (%review-queue-file)))
    (orchestrator.journal:write-file-atomic
     f
     (with-output-to-string (s)
       (with-standard-io-syntax
         (let ((*package* (find-package :keyword)))
           (prin1 (funcall (find-symbol "QUEUE-STATE" :orchestrator.review) q) s)))))
    f))

(defun review-list ()
  "List every change awaiting human approval, with a one-line summary + id."
  (let* ((q (load-review-queue))
         (pending (funcall (find-symbol "PENDING-ITEMS" :orchestrator.review) q)))
    (format t "~%Προς έλεγχο (~D):~%" (length pending))
    (if (null pending)
        (format t "  (κανένα — όλα τα αυτόματα κωδικοποιήθηκαν χωρίς αμφιβολία)~%")
        (dolist (i pending)
          (format t "  • id=~A~%    ~A~%"
                  (funcall (find-symbol "ITEM-ID" :orchestrator.review) i)
                  (funcall (find-symbol "ITEM-SUMMARY" :orchestrator.review) i))))
    (format t "~%Έγκριση:  --approve <id> [σημείωση]   Απόρριψη: --reject <id> [σημείωση]~%")
    0))

(defun review-decide (decision &optional args)
  "Η ΑΝΘΡΩΠΙΝΗ απόφαση επί πρότασης: --approve|--reject <id> [σημείωση…]
   (ή, για συμβατότητα, REVIEW_ID=/REVIEW_BY= env). Καταγράφεται με υπογραφή
   και σημείωση, ΑΠΟΜΝΗΜΟΝΕΥΕΤΑΙ (η ίδια μελλοντική πρόταση αποφασίζεται
   αυτόματα όπως αποφάσισες εσύ) και — για εγκρίσεις — η πράξη εφαρμόζεται
   μέσω του κανονικού consolidation στο επόμενο --apply-upgrade.
   DECISION είναι το ΡΗΜΑ της πράξης :approve ή :reject — ΑΚΡΙΒΩΣ ό,τι δέχεται
   η έδρα orchestrator.review:decide (apply-decision: (ecase decision (:approve
   :approved) (:reject :rejected))). Το status γίνεται :approved/:rejected· η
   πράξη είναι :approve/:reject. (Παλιότερα εδώ περνούσε :approved → ecase
   CASE-FAILURE, σιωπηλά καταπινόμενο ⇒ «δεν βρέθηκε» σε ΥΠΑΡΚΤΟ item.)"
  (let* ((id (or (first args) (uiop:getenv "REVIEW_ID")))
         (by (or (uiop:getenv "REVIEW_BY") "user"))
         (note (when (rest args) (format nil "~{~A~^ ~}" (rest args)))))
    (unless (and id (plusp (length id)))
      (format t "χρήση: --approve|--reject <id> [σημείωση]   (τα id: --review)~%")
      (return-from review-decide 1))
    (with-review-queue-lock
      (let* ((q (load-review-queue))
             (item (funcall (find-symbol "DECIDE" :orchestrator.review)
                            q id decision :by by :note note)))
        (if item
            (progn (save-review-queue q)
                   (format t "  ~A ~A (από ~A)~%"
                           (if (eq decision :approve) "✓ ΕΓΚΡΙΘΗΚΕ" "✗ ΑΠΟΡΡΙΦΘΗΚΕ")
                           (funcall (find-symbol "ITEM-SUMMARY" :orchestrator.review) item)
                           by)
                   (when (eq decision :approve)
                     (format t "  ➤ Εφαρμογή & νέο golden: --apply-upgrade~%"))
                   0)
            (progn (format t "Δεν βρέθηκε item με id=~A~%" id) 1))))))

;;; ── Correctness guarantee (invariants + golden fingerprint) ────────────────

(defun %corpus-golden-file (short)
  "Committed golden fingerprint for corpus SHORT. GOLDEN_DIR overrides the
   default deployment/verify/golden/ directory — which is BOTH committed to
   the repo AND inside the deployment/ Docker mount, so the same golden is
   seen identically in the container and in CI."
  (let ((dir (uiop:ensure-directory-pathname
              (or (uiop:getenv "GOLDEN_DIR")
                  (merge-pathnames "deployment/verify/golden/"
                                   (or (uiop:getenv "ORCHESTRATOR_ROOT")
                                       (orchestrator.paths:institution-root)))))))
    (merge-pathnames (concatenate 'string short ".fingerprint.sexp") dir)))

(defun %fingerprint-method (manifest)
  "Ποια ΜΕΘΟΔΟΣ αποτυπώματος είναι ένα manifest — ώστε η σύγκριση golden↔τρέχον να
   γίνεται LIKE-WITH-LIKE: :emitted (output-manifest — :file-id/:status :emitted) ή
   :semantic (corpus-fingerprint — :num/:status :original|:amended). Ανιχνεύεται από
   το σχήμα του πρώτου άρθρου, ώστε το ΙΔΙΟ το golden να ορίζει τη μέθοδο — χωρίς να
   χρειάζεται καμία αλλαγή στο κλειδωμένο αρχείο golden."
  (let ((a (first (getf manifest :articles))))
    (cond ((and a (getf a :file-id)) :emitted)
          ((and a (getf a :num)) :semantic)
          (t :emitted))))

(defun verify-corpus (&optional corpus-id)
  "The correctness guarantee, made operational: build the consolidated corpus,
   run the structural invariants, compute its deterministic fingerprint, write
   the manifest to the output dir, and compare against the committed golden.
   GOLDEN_WRITE=1 (re)establishes the golden for this corpus. Exit code is
   non-zero on any invariant violation or any drift from the golden."
  ;; Build the consolidated document for THIS corpus explicitly. (Do NOT route
  ;; through build-active-consolidated-document — it re-reads ORCHESTRATOR_CORPUS
  ;; from the env and would reset every corpus back to the env default.)
  (multiple-value-bind (short doc) (build-consolidated-for corpus-id)
   (let* ((fp (find-package :orchestrator.fingerprint))
          (out-dir (corpus-output-dir
                    (or (uiop:getenv "ORCHESTRATOR_OUTPUT_DIR") (orchestrator.paths:institution-dir "output/"))))
          (manifest-path (merge-pathnames (concatenate 'string short ".fingerprint.sexp")
                                          (uiop:ensure-directory-pathname out-dir)))
          (golden-path (%corpus-golden-file short))
          ;; Prefer the REAL emitted codification (article-*.hash) when the
          ;; pipeline has produced it — that is the published text, with real
          ;; article numbers/letters. Otherwise fingerprint the consolidated doc
          ;; (e.g. the JSON-sourced Constitution).
          (codified-p (funcall (find-symbol "OUTPUT-CODIFIED-P" fp) out-dir))
          (manifest (if codified-p
                        (funcall (find-symbol "OUTPUT-MANIFEST" fp) out-dir :id short)
                        (funcall (find-symbol "CORPUS-FINGERPRINT" fp) doc)))
          (expected (let ((v (ignore-errors
                              (orchestrator.spec:config-get "corpus.expected_articles"))))
                      (cond ((integerp v) v)
                            ((and (stringp v) (parse-integer v :junk-allowed t))
                             (parse-integer v :junk-allowed t))
                            (t nil))))
          ;; Article numbers the OFFICIAL SOURCE itself omits (documented per
          ;; corpus in configs — e.g. repealed ΠΚ articles the Ισοκράτης
          ;; consolidated export drops entirely). Gaps consisting only of these
          ;; are the source's truth, not a parse loss.
          (known-absent (let ((v (ignore-errors
                                  (orchestrator.spec:config-get "corpus.source_omitted_articles"))))
                          (when (listp v)
                            (loop for x in v
                                  for n = (if (integerp x)
                                              x
                                              (parse-integer (princ-to-string x) :junk-allowed t))
                                  when n collect n))))
          (rc 0))
    (format t "~%═══ ΕΓΓΥΗΣΗ ΟΡΘΟΤΗΤΑΣ: ~A ═══~%" short)
    (format t "Πηγή: ~:[consolidated document (JSON)~;εκδομένη κωδικοποίηση (article-*.hash)~]~%"
            codified-p)
    ;; 1. structural invariants (over whichever manifest we built)
    (multiple-value-bind (ok violations)
        (funcall (find-symbol "VERIFY-MANIFEST-INVARIANTS" fp) manifest
                 :expected-count expected :known-absent known-absent)
      (format t "~A~%" (funcall (find-symbol "FORMAT-VIOLATIONS" fp) violations))
      (unless ok (setf rc 1)))
    ;; 2. fingerprint manifest (always written to output)
    (funcall (find-symbol "WRITE-FINGERPRINT-MANIFEST" fp) manifest manifest-path)
    (format t "Άρθρα: ~D · ρίζα: ~A~%"
            (funcall (find-symbol "MANIFEST-COUNT" fp) manifest)
            (funcall (find-symbol "MANIFEST-ROOT" fp) manifest))
    (format t "Manifest: ~A~%" manifest-path)
    ;; 3. golden comparison / establishment
    (cond
      ((uiop:getenv "GOLDEN_WRITE")
       (funcall (find-symbol "WRITE-FINGERPRINT-MANIFEST" fp) manifest golden-path)
       (format t "✓ Golden καθορίστηκε -> ~A~%" golden-path))
      ((probe-file golden-path)
       (let* ((golden (funcall (find-symbol "READ-FINGERPRINT-MANIFEST" fp) golden-path))
              ;; ΣΥΓΚΡΙΣΗ LIKE-WITH-LIKE: το golden ΟΡΙΖΕΙ τη μέθοδο. Αν κλειδώθηκε
              ;; σημασιολογικά (corpus-fingerprint) αλλά τώρα υπάρχει output/*.hash,
              ;; ΜΗΝ το συγκρίνεις με output-manifest (αυτό ήταν η ρίζα του ψευδο-drift
              ;; μετά το commit του output cb26e5be) — ξαναϋπολόγισε ΤΗΝ ΙΔΙΑ μέθοδο.
              (gmethod (%fingerprint-method golden))
              (same (eq gmethod (%fingerprint-method manifest)))
              (cmp (if same manifest
                       (ecase gmethod
                         (:semantic (funcall (find-symbol "CORPUS-FINGERPRINT" fp) doc))
                         (:emitted  (funcall (find-symbol "OUTPUT-MANIFEST" fp) out-dir :id short)))))
              (diff (funcall (find-symbol "FINGERPRINT-DIFF" fp) golden cmp)))
         (unless same
           (format t "  ℹ σύγκριση golden στη μέθοδο που κλειδώθηκε: ~(~A~)~%" gmethod))
         (format t "~A~%" (funcall (find-symbol "FORMAT-DIFF" fp) diff))
         (unless (funcall (find-symbol "DIFF-CLEAN-P" fp) diff) (setf rc 1))))
      (t (format t "ℹ Δεν υπάρχει golden ακόμη· τρέξε με GOLDEN_WRITE=1 για να καθοριστεί.~%")))
    ;; 4. CONTENT-SANITY GATE (Level 2): the cryptographic proof certifies the BOX, not
    ;; the legal TEXT. This refuses a release whose CONTENT is broken (empty article
    ;; bodies, abolished death-penalty wording, extraction artifacts). Blocking → rc≠0,
    ;; so --verify-all and --auto-update (which gate on it) will not sign garbage.
    (multiple-value-bind (blocks warns) (content-gate (nth-value 1 (corpus-spec corpus-id))
                                                      :label short)
      (declare (ignore warns))
      (when (plusp blocks) (setf rc 1)))
    ;; 5. REFERENCE-INTEGRITY REPORT: does every internal citation («κατά το
    ;; άρθρο 299») bind to an existing article? Reuses the ONE authoritative
    ;; extractor (orchestrator.references — the same graph the reasoning brain
    ;; and references.ttl consume). ADVISORY by design: an unresolved citation
    ;; may point to another law or a repealed article, so it informs review,
    ;; it does not block the release.
    (handler-case
        (multiple-value-bind (ok unresolved) (orchestrator.references:verify-references doc)
          (declare (ignore ok))
          (format t "── ΠΑΡΑΠΟΜΠΕΣ: ~A ──~%"
                  (if unresolved
                      (format nil "~D εσωτερικές δεν δένουν (άλλος νόμος / καταργημένο) — advisory"
                              (length unresolved))
                      "κάθε εσωτερική παραπομπή δένει σε υπαρκτό άρθρο ✓")))
      (error (e) (format t "── ΠΑΡΑΠΟΜΠΕΣ: έλεγχος απέτυχε: ~A ──~%" e)))
    rc)))

(defun verify-all-corpora ()
  "Run the correctness guarantee over every served code; non-zero if any fails."
  (let ((failed 0))
    (dolist (id *served-corpora*)
      (handler-case
          (when (plusp (verify-corpus id)) (incf failed))
        (error (e) (incf failed) (format t "  ✗ ~A: ~A~%" id e))))
    (format t "~%═══ Σύνολο: ~D κώδικ~:*~[ες~;ας~:;ες~] με πρόβλημα ~:[(όλα ορθά ✓)~;~] ═══~%"
            failed (plusp failed))
    (if (zerop failed) 0 1)))

(defun verify-consolidation (&optional corpus-id)
  "Level-2: build the amendment-replay LEDGER for CORPUS-ID and INDEPENDENTLY verify it
   — re-consolidate base+ops and confirm the exact consolidated text reproduces
   (provably-correct consolidation). Reuses the bridge (articles->document /
   amendment-records->acts) + the ledger (build/verify-consolidation-ledger); nothing
   re-implemented. Non-zero rc on a replay divergence."
  (multiple-value-bind (short triples records title) (corpus-spec corpus-id)
    (let ((b2a    (find-symbol "ARTICLES->DOCUMENT" :orchestrator.consolidation.bridge))
          (r2a    (find-symbol "AMENDMENT-RECORDS->ACTS" :orchestrator.consolidation.bridge))
          (build  (find-symbol "BUILD-CONSOLIDATION-LEDGER" :orchestrator.consolidation))
          (verify (find-symbol "VERIFY-CONSOLIDATION-LEDGER" :orchestrator.consolidation))
          (steps  (find-symbol "LEDGER-STEPS" :orchestrator.consolidation)))
      (unless (and b2a r2a build verify steps)
        (format t "  ✗ consolidation bridge/ledger μη διαθέσιμα~%")
        (return-from verify-consolidation 1))
      (let ((base (funcall b2a triples :id short :title title))
            (acts (funcall r2a records)))
        (multiple-value-bind (ledger result) (funcall build base acts)
          (declare (ignore result))
          (multiple-value-bind (ok reason) (funcall verify base acts ledger)
            (format t "~%═══ REPLAY-VERIFY ΚΩΔΙΚΟΠΟΙΗΣΗΣ: ~A ═══~%" short)
            (format t "  Τροποποιητικές πράξεις: ~D · βήματα replay: ~D~%"
                    (length acts) (length (funcall steps ledger)))
            (if ok
                (progn (format t "  ✓ ΑΠΟΔΕΙΞΙΜΟ: base + ops αναπαράγουν ΑΚΡΙΒΩΣ το ενοποιημένο κείμενο~%")
                       0)
                (progn (format t "  ✗ ΑΠΟΤΥΧΙΑ replay: ~A~%" reason)
                       1))))))))

(defun verify-all-consolidation ()
  "Run the consolidation replay-verify over every served code; non-zero if any fails."
  (let ((failed 0))
    (dolist (id *served-corpora*)
      (handler-case
          (when (plusp (verify-consolidation id)) (incf failed))
        (error (e) (incf failed) (format t "  ✗ ~A: ~A~%" id e))))
    (format t "~%═══ Replay: ~D κώδικ~:*~[ες~;ας~:;ες~] με πρόβλημα ~:[(όλα αποδείξιμα ✓)~;~] ═══~%"
            failed (plusp failed))
    (if (zerop failed) 0 1)))

(defun verify-intelligence (&optional corpus-id)
  "Run the unified MOP intelligence suite over the served corpus — reference
   integrity, extraction anomalies, AST structural validity and citation
   centrality, discovered and run generically (orchestrator.intelligence). Prints
   the Greek report and writes <corpus>.intelligence.json (AI-consumable) to the
   output dir. Exit is non-zero only on a real structural :issue (advisories pass)."
  (multiple-value-bind (short doc) (build-consolidated-for corpus-id)
    (let* ((pkg :orchestrator.intelligence)
           (run   (find-symbol "RUN-CORPUS-INTELLIGENCE" pkg))
           (fmt   (find-symbol "FORMAT-INTELLIGENCE-REPORT" pkg))
           (json  (find-symbol "INTELLIGENCE-JSON" pkg))
           (clean (find-symbol "REPORT-CLEAN-P" pkg))
           (out-dir (corpus-output-dir
                     (or (uiop:getenv "ORCHESTRATOR_OUTPUT_DIR") (orchestrator.paths:institution-dir "output/"))))
           (json-path (merge-pathnames (concatenate 'string short ".intelligence.json")
                                       (uiop:ensure-directory-pathname out-dir))))
      (format t "~%═══ ΝΟΗΜΟΣΥΝΗ ΚΩΔΙΚΑ: ~A ═══~%" short)
      (if (not (and run fmt json clean))
          (progn (format t "ℹ Το module νοημοσύνης δεν είναι διαθέσιμο.~%") 0)
          (let ((findings (funcall run doc)))
            (format t "~A~%" (funcall fmt findings nil))
            (ensure-directories-exist json-path)
            (with-open-file (s json-path :direction :output :if-exists :supersede
                                         :if-does-not-exist :create :external-format :utf-8)
              (write-string (funcall json findings) s))
            (format t "AI report: ~A~%" json-path)
            (if (funcall clean findings) 0 1))))))

(defun verify-all-intelligence ()
  "Run the intelligence suite over every served code; non-zero if any has issues."
  (let ((failed 0))
    (dolist (id *served-corpora*)
      (handler-case
          (when (plusp (verify-intelligence id)) (incf failed))
        (error (e) (incf failed) (format t "  ✗ ~A: ~A~%" id e))))
    (format t "~%═══ Νοημοσύνη: ~D κώδικ~:[ες~;ας~] με ζητήματα ~:[(όλα καθαρά ✓)~;~] ═══~%"
            failed (= failed 1) (plusp failed))
    (if (zerop failed) 0 1)))

(defun %pcl-signing-material ()
  "Load the ROOT AUTHORITY signing material from the environment so the corpus
   Merkle root is signed (TIER 1-A). The keypair is operator-supplied and STABLE
   — never auto-generated here: a published trust root must not change per run.

     PCL_SIGNING_KEY  path to the RSA private key PEM (the secret signing key)
     PCL_PUBLIC_KEY   path to the RSA public key PEM (published as JWK)

   [0088 Φ4β — PCL-03 fail-closed]: επιστρέφει (values private-key public-jwk)
   ΜΟΝΟ όταν το υλικό υπάρχει και φορτώνει. Απόν υλικό ⇒ ΣΦΑΛΜΑ, εκτός αν
   ORCHESTRATOR_ALLOW_DEGRADED_PROOFS=1 (ρητή, τυπωμένη παράκαμψη ⇒ (values
   nil nil) και τα proofs φέρουν trust_status «unsigned-explicit»). Υλικό
   παρόν αλλά ΑΧΡΗΣΤΟ ⇒ ΣΦΑΛΜΑ ΠΑΝΤΑ — ρυθμισμένα κλειδιά που δεν φορτώνουν
   δεν «υποβαθμίζονται», διορθώνονται."
  (let ((priv-path (%non-blank (uiop:getenv "PCL_SIGNING_KEY")))
        (pub-path  (%non-blank (uiop:getenv "PCL_PUBLIC_KEY"))))
    (cond
      ((and priv-path pub-path)
       (handler-case
           (let* ((jws :orchestrator.jws-authority)
                  (priv (funcall (find-symbol "LOAD-RSA-PRIVATE-KEY" jws) priv-path))
                  (pub  (funcall (find-symbol "LOAD-RSA-PUBLIC-KEY" jws) pub-path))
                  (jwk  (funcall (find-symbol "EXPORT-JWK" jws) pub
                                 :kid "stavropoulos-law-root")))
             (values priv (jonathan:to-json jwk)))
         (error (e)
           (error "PCL signing υλικό ΡΥΘΜΙΣΜΕΝΟ αλλά ΑΧΡΗΣΤΟ (~A) — καμία σιωπηλή υποβάθμιση σε unsigned· διόρθωσε τα κλειδιά" e))))
      ((uiop:getenvp "ORCHESTRATOR_ALLOW_DEGRADED_PROOFS")
       (format t "  ⚠ ΡΗΤΗ παράκαμψη ORCHESTRATOR_ALLOW_DEGRADED_PROOFS: εκπομπή UNSIGNED proofs (trust_status: unsigned-explicit).~%")
       (values nil nil))
      (t
       (error "PCL signing υλικό ΑΠΟΝ (PCL_SIGNING_KEY/PCL_PUBLIC_KEY) — τα proofs ΔΕΝ εκπέμπονται unsigned σιωπηλά. Θέσε τα κλειδιά, ή ρητά ORCHESTRATOR_ALLOW_DEGRADED_PROOFS=1")))))

(defun %corpus-anchor-plist (provisions)
  "Level-1: build the PRIMARY-SOURCE anchor plist for the ACTIVE corpus and bind it to
   the SERVED text. It (a) hashes the source file the corpus was built from (the
   ΦΕΚ/Ministry document) → source-digest, (b) computes the EXTRACTION-DIGEST over the
   ordered served (id . text) PROVISIONS — the deterministic derivation from the primary
   — and (c) GATES on that derivation (anchor-assert :articles), the non-tautological
   check that the served law is exactly what the primary yields. Returns ANCHOR->PLIST,
   embedded per-article by write-provision-proofs. Loose find-symbol (no hard dependency);
   reuses compute-sha256-* inside the anchor module; never throws (NIL when no source /
   module → proofs stay valid without the anchor).

   EXTRACTION-METHOD names the adapter chain so a third party knows exactly what to
   re-run over the primary bytes to reproduce EXTRACTION-DIGEST.

   [0088 Φ4β — PCL-03]: η ΑΠΟΤΥΧΙΑ κατασκευής/assert του anchor ΔΕΝ
   καταπίνεται πια (η ολική error-κατάπια πέθανε) — σφάλμα σημαίνει ότι το
   σερβιριζόμενο κείμενο ΔΕΝ αναπαράγεται από την πηγή και πρέπει να
   κοκκινίσει· ΜΟΝΟ η ρητή ORCHESTRATOR_ALLOW_DEGRADED_PROOFS=1 επιτρέπει
   proofs χωρίς anchor (τυπωμένο). NIL επιστρέφεται ΜΟΝΟ για τίμια απουσία
   πηγής/module (δηλωμένη στα προαπαιτούμενα, όχι κατάπια σφάλματος)."
  (handler-case
      (let* ((mk    (find-symbol "MAKE-PRIMARY-ANCHOR" :orchestrator.epistemic))
             (asrt  (find-symbol "ANCHOR-ASSERT" :orchestrator.epistemic))
             (plist (find-symbol "ANCHOR->PLIST" :orchestrator.epistemic))
             (pfek  (find-symbol "PARSE-FEK-REF" :orchestrator.legal-id))
             (fekstr (ignore-errors (orchestrator.spec:config-get "corpus.publication.fek_number")))
             (fek   (and pfek fekstr (funcall pfek fekstr)))
             (src   (or (ignore-errors (orchestrator.spec:resolve-config-path "source.docx"))
                        (ignore-errors (orchestrator.spec:resolve-config-path "source.pdf"))))
             (method (if (and src (string-equal (or (pathname-type src) "") "docx"))
                         "docx-adapter+raw-text-fsm@1"
                         "pdf-adapter+raw-text-fsm@1"))
             ;; The exact served (id . text) list the proofs are built from — hashing
             ;; this is what binds the anchor to the derivation, not to the source file.
             (articles (loop for p in provisions
                             collect (cons (getf p :id) (getf p :text))))
             (uri   (or (ignore-errors (orchestrator.spec:config-get "source.docx_url"))
                        (ignore-errors (orchestrator.spec:config-get "source.pdf_url"))
                        (ignore-errors (orchestrator.spec:config-get "source.url")))))
        (when (and mk asrt plist src (probe-file src))
          (let ((anchor (funcall mk :fek fek :source-file src :source-uri uri
                                 :articles articles :extraction-method method
                                 :retrieved-at ;; [P1.5-C] commitment-time από την έδρα χρόνου (ΟΧΙ ψεύτικη σταθερά)
                                 (orchestrator.time:format-iso8601 (orchestrator.time:require-deterministic-time)))))
            ;; GATE on the DERIVATION: the served text must reproduce extraction-digest.
            (funcall asrt anchor :articles articles)
            (funcall plist anchor))))
    (error (e)
      (if (uiop:getenvp "ORCHESTRATOR_ALLOW_DEGRADED_PROOFS")
          (progn
            (format t "  ⚠ ΡΗΤΗ παράκαμψη: αποτυχία primary anchor (~A) — proofs ΧΩΡΙΣ anchor.~%" e)
            nil)
          (error "Αποτυχία primary-source anchor: ~A — τα proofs ΔΕΝ εκπέμπονται χωρίς αγκύρωση σιωπηλά (ORCHESTRATOR_ALLOW_DEGRADED_PROOFS=1 για ρητή παράκαμψη)" e)))))

(defun emit-proofs ()
  "Proof-Carrying Law: emit a portable proof per provision for every served code —
   article-<id>.proof.json + corpus-proof.json (the Merkle root every proof chains
   to). Each proof lets ANYONE verify the text is authentic without trusting us.
   When PCL_SIGNING_KEY/PCL_PUBLIC_KEY are set, the root is SIGNED (TIER 1-A)."
  (multiple-value-bind (priv pub-jwk) (%pcl-signing-material)
    (when priv (format t "  🔑 Root authority key loaded — corpus roots will be SIGNED.~%"))
   (let ((total 0) (failures '()))
    (dolist (id *served-corpora*)
      (handler-case
          (multiple-value-bind (short doc) (build-consolidated-for id)
            (declare (ignore short))
            (let* ((cons-pkg :orchestrator.consolidation)
                   (provs (funcall (find-symbol "LEGAL-DOCUMENT-PROVISIONS" cons-pkg) doc))
                   (eid-fn (find-symbol "PROVISION-EID" cons-pkg))
                   (eli-prefix (or (ignore-errors (orchestrator.spec:config-get "corpus.eli_prefix")) ""))
                   (abbr (or (ignore-errors (orchestrator.spec:config-get "corpus.citation_abbrev"))
                             (or (ignore-errors (orchestrator.spec:config-get "corpus.short_name")) "")))
                   (out-dir (corpus-output-dir
                             (or (uiop:getenv "ORCHESTRATOR_OUTPUT_DIR") (orchestrator.paths:institution-dir "output/"))))
                   (provisions
                     (loop for p in provs
                           for eid = (funcall eid-fn p)
                           for aid = (let ((us (position #\_ eid :from-end t)))
                                       (if us (subseq eid (1+ us)) eid))
                           collect (list :id aid
                                         ;; ONE canonical text (full article incl.
                                         ;; paragraphs) — same as the site & MCP.
                                         :text (orchestrator.static-site:article-canonical-text p)
                                         :eli (format nil "~A/art/~A" eli-prefix aid)
                                         :cite (format nil "Άρθρο ~A~@[ ~A~]" aid
                                                       (and (plusp (length abbr)) abbr))))))
              (multiple-value-bind (root count sig)
                  (funcall (find-symbol "WRITE-PROVISION-PROOFS" :orchestrator.proof-carrying)
                           provisions out-dir :anchored-at ;; [P1.5-C] commitment-time από την έδρα χρόνου (ΟΧΙ ψεύτικη σταθερά)·
                          ;; ο ΑΠΟΔΕΔΕΙΓΜΕΝΟΣ χρόνος ζει στο RFC-3161 receipt του release.
                          (orchestrator.time:format-iso8601 (orchestrator.time:require-deterministic-time))
                           :private-key priv :public-jwk pub-jwk
                           ;; Level-1: each proof embeds the primary-source (ΦΕΚ) anchor,
                           ;; whose extraction-digest is bound to THESE served provisions.
                           :anchor (%corpus-anchor-plist provisions))
                (incf total (or count 0))
                ;; Publish the public key alongside the proofs so any verifier can
                ;; fetch it (the corpus-proof.json already embeds it too).
                (when (and sig pub-jwk)
                  (ignore-errors
                    (alexandria:write-string-into-file
                     pub-jwk (format nil "~Apcl-public-key.jwk" out-dir)
                     :if-exists :supersede)))
                (format t "  ✓ ~A: ~D proofs → ~A  (root ~A…)~A~%"
                        id count out-dir (subseq (or root "") 0 (min 23 (length (or root ""))))
                        (if sig "  [SIGNED]" "")))))
        (error (e) (push (cons id e) failures)
               (format t "  ✗ ~A: ~A~%" id e))))
    (format t "~%Proof-Carrying Law: ~D αποδείξεις εκπέμφθηκαν~@[, ~D σώματα ΑΠΕΤΥΧΑΝ~].~%"
            total (and failures (length failures)))
    (if failures 1 0))))

(defun emit-references ()
  "Level-3 reasoning substrate: for every served code emit <corpus>/references.ttl —
   the RESOLVED article→article citation graph as ELI linked data (eli:cites), so an
   AI (or a court) can TRAVERSE the law, not just read isolated articles. Also reports
   internal citations that don't resolve (advisory: another law / repealed / mis-parse).
   Reuses orchestrator.references (REFERENCE-GRAPH / GRAPH-EDGES / VERIFY-REFERENCES)
   via loose find-symbol — the citation graph is never re-implemented here."
  (let ((rg       (find-symbol "REFERENCE-GRAPH" :orchestrator.references))
        (ge       (find-symbol "GRAPH-EDGES" :orchestrator.references))
        (vr       (find-symbol "VERIFY-REFERENCES" :orchestrator.references))
        (provs-fn (find-symbol "LEGAL-DOCUMENT-PROVISIONS" :orchestrator.consolidation))
        (eid-fn   (find-symbol "PROVISION-EID" :orchestrator.consolidation))
        (total 0))
    (unless (and rg ge vr provs-fn eid-fn)
      (format t "  ✗ orchestrator.references / consolidation μη διαθέσιμα~%")
      (return-from emit-references 1))
    (dolist (id *served-corpora*)
      (handler-case
          (multiple-value-bind (short doc) (build-consolidated-for id)
            (let* ((graph (funcall rg doc))
                   (eli   (or (ignore-errors (orchestrator.spec:config-get "corpus.eli_prefix")) ""))
                   (out-dir (corpus-output-dir
                             (or (uiop:getenv "ORCHESTRATOR_OUTPUT_DIR") (orchestrator.paths:institution-dir "output/"))))
                   (path  (merge-pathnames "references.ttl"
                                           (uiop:ensure-directory-pathname out-dir)))
                   (n 0))
              (ensure-directories-exist path)
              (with-open-file (o path :direction :output :if-exists :supersede
                                      :if-does-not-exist :create :external-format :utf-8)
                (format o "@prefix eli: <http://data.europa.eu/eli/ontology#> .~%")
                (format o "@prefix slw: <https://stavropouloslaw.com/ontology/legal#> .~%~%")
                (format o "# ~A — citation graph (each edge: article eli:cites article).~%~%" short)
                (dolist (p (funcall provs-fn doc))
                  (let* ((eid (funcall eid-fn p))
                         (aid (let ((us (position #\_ eid :from-end t)))
                                (if us (subseq eid (1+ us)) eid))))
                    (dolist (c (funcall ge graph aid))
                      (format o "<~A/art/~A> eli:cites <~A/art/~A> .~%" eli aid eli c)
                      (incf n)))))
              (multiple-value-bind (ok unresolved) (funcall vr doc)
                (format t "  ✓ ~A: ~D citation edges → references.ttl~@[  (~D εξωτερικές/αδύναμες)~]~%"
                        id n (and (not ok) (length unresolved))))
              (incf total n)))
        (error (e) (format t "  ✗ ~A: ~A~%" id e))))
    (format t "~%Reasoning substrate: ~D citation edges εκπέμφθηκαν.~%" total)
    0))

(defun %hg-artid (eid)
  "Article id from an eId like 'art_299' → '299' (else the eId unchanged)."
  (let ((s (princ-to-string (or eid ""))))
    (if (and (>= (length s) 4) (string= (subseq s 0 4) "art_")) (subseq s 4) s)))

(defun %hg-slug (s)
  "URI-safe-ish slug for an act id: whitespace / quotes / slashes → '-'."
  (with-output-to-string (o)
    (loop for c across (princ-to-string (or s ""))
          do (write-char (if (member c '(#\Space #\/ #\' #\" #\Newline #\Tab #\Return)) #\- c) o))))

(defun run-reason (corpus article)
  "BRAIN, live: impact analysis over the REAL corpus — every provision (transitively)
   affected by a change to CORPUS/ARTICLE, each with its JTMS proof tree. Runs the
   inference engine on facts lifted from the actual citation graph via the reasoning
   bridge; no reasoning logic or graph building is duplicated here."
  (cond
    ((or (null corpus) (null article))
     (format t "~&Χρήση: --reason <corpus> <άρθρο>   (π.χ. --reason poinikos 299)~%")
     (format t "  Δείχνει τι επηρεάζεται αν αλλάξει το άρθρο, με απόδειξη.~%")
     2)
    (t
     (handler-case
         (multiple-value-bind (short doc) (build-consolidated-for corpus)
           (declare (ignore short))
           ;; [0088 Φ5γ — TRUST-01 νεκρό εδώ]: ΚΑΘΕ συμπέρασμα θεμελιωμένο στη
           ;; διτεμπορική τομή με receipt-id — αθεμελίωτο άρθρο ΔΗΛΩΝΕΤΑΙ.
           (let ((tc (corpus-temporal-commitment corpus)))
             (multiple-value-bind (grounded ungrounded)
                 (orchestrator.reasoning:grounded-impact
                  doc corpus article
                  :body (getf tc :typed-body) :graph (getf tc :graph)
                  :receipts (getf tc :receipts)
                  :valid-at (getf tc :valid-at) :known-at (getf tc :known-at))
               (format t "~&── ΘΕΜΕΛΙΩΜΕΝΗ ΑΝΑΛΥΣΗ ΕΠΙΠΤΩΣΗΣ: ~A άρθρο ~A @ (~A, ~A) ──~%"
                       corpus article (getf tc :valid-at) (getf tc :known-at))
               (dolist (g grounded)
                 (format t "  • άρθρο ~A  [receipt ~A  hash ~A  valid-from ~A]~%~A"
                         (getf g :article)
                         (subseq (getf g :receipt-id) 0 16)
                         (subseq (getf g :content-hash) 0 16)
                         (getf g :valid-from)
                         (orchestrator.inference:explanation->string (getf g :proof) 4)))
               (dolist (u ungrounded)
                 (format t "  ✗ ΑΘΕΜΕΛΙΩΤΟ άρθρο ~A: ~A~%" (getf u :article) (getf u :why)))
               (format t "  Σύνολο: ~D θεμελιωμένα, ~D δηλωμένα αθεμελίωτα~%"
                       (length grounded) (length ungrounded))))
           0)
       (error (e) (format t "  ✗ ~A: ~A~%" corpus e) 1)))))

(defun emit-hypergraph ()
  "Level-3+ HYPERGRAPH: emit <corpus>/hypergraph.ttl — the N-ary legal knowledge layer.
   Each amending act is a HYPEREDGE (slw:AmendmentEvent) linking one ΦΕΚ to the SET of
   articles it touched, with a proof-carrying slw:Operation (op kind + before/after
   hashes) per edit. The law is N-ary: one act changes many articles at once — a binary
   graph fragments that; this captures it as ONE edge. Reuses the replay LEDGER (acts
   ARE hyperedges) via the bridge — nothing re-implemented. RDF via the W3C n-ary
   relations pattern, so it stays SPARQL-queryable (not a niche hypergraph DB)."
  (let ((b2a   (find-symbol "ARTICLES->DOCUMENT" :orchestrator.consolidation.bridge))
        (r2a   (find-symbol "AMENDMENT-RECORDS->ACTS" :orchestrator.consolidation.bridge))
        (build (find-symbol "BUILD-CONSOLIDATION-LEDGER" :orchestrator.consolidation))
        (steps (find-symbol "LEDGER-STEPS" :orchestrator.consolidation))
        (s-act (find-symbol "STEP-ACT-ID" :orchestrator.consolidation))
        (s-fek (find-symbol "STEP-FEK" :orchestrator.consolidation))
        (s-eff (find-symbol "STEP-EFFECTIVE" :orchestrator.consolidation))
        (s-op  (find-symbol "STEP-OP-KIND" :orchestrator.consolidation))
        (s-tgt (find-symbol "STEP-TARGET" :orchestrator.consolidation))
        (s-bh  (find-symbol "STEP-BEFORE-HASH" :orchestrator.consolidation))
        (s-ah  (find-symbol "STEP-AFTER-HASH" :orchestrator.consolidation))
        (mk-hg    (find-symbol "MAKE-LEGAL-HYPERGRAPH" :orchestrator.hypergraph))
        (mk-edge  (find-symbol "MAKE-AMENDMENT-EDGE" :orchestrator.hypergraph))
        (hadd     (find-symbol "HYPERGRAPH-ADD" :orchestrator.hypergraph))
        (hedges   (find-symbol "HYPERGRAPH-EDGES" :orchestrator.hypergraph))
        (emit-ttl (find-symbol "EMIT-HYPERGRAPH-TTL" :orchestrator.hypergraph))
        (mk-ref   (find-symbol "MAKE-REFERENCE-EDGE" :orchestrator.hypergraph))
        (rg       (find-symbol "REFERENCE-GRAPH" :orchestrator.references))
        (ge       (find-symbol "GRAPH-EDGES" :orchestrator.references))
        (provs-fn (find-symbol "LEGAL-DOCUMENT-PROVISIONS" :orchestrator.consolidation))
        (eid-fn   (find-symbol "PROVISION-EID" :orchestrator.consolidation))
        (total 0))
    (unless (and b2a r2a build steps s-act s-tgt mk-hg mk-edge hadd emit-ttl hedges)
      (format t "  ✗ ledger/bridge μη διαθέσιμα~%")
      (return-from emit-hypergraph 1))
    (dolist (id *served-corpora*)
      (handler-case
          (multiple-value-bind (short triples records title) (corpus-spec id)
            (let* ((base    (funcall b2a triples :id short :title title))
                   (acts    (funcall r2a records))
                   (_bl     (multiple-value-list (funcall build base acts)))
                   (ledger  (first _bl))
                   (result  (second _bl))
                   (eli     (or (ignore-errors (orchestrator.spec:config-get "corpus.eli_prefix")) ""))
                   (out-dir (corpus-output-dir
                             (or (uiop:getenv "ORCHESTRATOR_OUTPUT_DIR") (orchestrator.paths:institution-dir "output/"))))
                   (path    (merge-pathnames "hypergraph.ttl"
                                             (uiop:ensure-directory-pathname out-dir)))
                   (by-act  (make-hash-table :test 'equal))
                   (order   '())
                   (hg      (funcall mk-hg)))
              ;; group ledger steps by act → each act becomes ONE hyperedge
              (dolist (st (funcall steps ledger))
                (let ((a (or (funcall s-act st) "?")))
                  (unless (nth-value 1 (gethash a by-act)) (push a order))
                  (push st (gethash a by-act))))
              (setf order (nreverse order))
              ;; Build the CLOS hypergraph model; ALL serialization lives in the model
              ;; (edge->turtle, polymorphic) — the CLI never formats RDF (no duplication).
              (dolist (a order)
                (let* ((grp     (nreverse (gethash a by-act)))
                       (fek     (and s-fek (funcall s-fek (first grp))))
                       (eff     (and s-eff (funcall s-eff (first grp))))
                       (targets (remove-duplicates
                                 (remove nil (mapcar (lambda (st) (funcall s-tgt st)) grp))
                                 :test #'equal))
                       (ops     (mapcar (lambda (st)
                                          (list (funcall s-op st) (%hg-artid (funcall s-tgt st))
                                                (and s-bh (funcall s-bh st))
                                                (and s-ah (funcall s-ah st))))
                                        grp)))
                  (funcall hadd hg
                           (funcall mk-edge :subject (%hg-slug a)
                                    :members (mapcar #'%hg-artid targets)
                                    :fek fek :effective eff :operations ops))))
              ;; reference hyperedges: each article's whole citation set as ONE N-ary
              ;; edge — reuses the reference graph, added to the SAME hypergraph. The
              ;; emitter is untouched: reference-edge serializes via its own methods.
              (when (and mk-ref rg ge provs-fn eid-fn result)
                (let ((graph (funcall rg result)))
                  (dolist (p (funcall provs-fn result))
                    (let* ((aid   (%hg-artid (funcall eid-fn p)))
                           (cited (funcall ge graph aid)))
                      (when cited
                        (funcall hadd hg
                                 (funcall mk-ref :subject (format nil "cites-~A" aid)
                                          :source aid :members cited)))))))
              (ensure-directories-exist path)
              (with-open-file (o path :direction :output :if-exists :supersede
                                      :if-does-not-exist :create :external-format :utf-8)
                (funcall emit-ttl hg o eli :title short))
              (let ((edges (length (funcall hedges hg))))
                (format t "  ✓ ~A: ~D hyperedges (amendment + citation) → hypergraph.ttl~%" id edges)
                (incf total edges))))
        (error (e) (format t "  ✗ ~A: ~A~%" id e))))
    (format t "~%Hypergraph: ~D N-ary amendment edges εκπέμφθηκαν.~%" total)
    0))

(defun verify-proof ()
  "PUBLIC verifier — check a PCL-1 proof against a provision's text WITHOUT
   trusting the corpus. PROOF_FILE=<article-N.proof.json> TEXT_FILE=<text file>.
   Exit 0 iff the text is the authentic, anchored law."
  (let ((pf (uiop:getenv "PROOF_FILE")) (tf (uiop:getenv "TEXT_FILE")))
    (if (not (and pf tf (probe-file pf) (probe-file tf)))
        (progn (format t "Χρήση: PROOF_FILE=<article-N.proof.json> TEXT_FILE=<κείμενο> --verify-proof~%") 2)
        (multiple-value-bind (ok reason)
            (funcall (find-symbol "VERIFY-PROOF-JSON" :orchestrator.proof-carrying)
                     (uiop:read-file-string tf :external-format :utf-8)
                     (uiop:read-file-string pf :external-format :utf-8))
          (if ok
              (progn (format t "✓ ΑΥΘΕΝΤΙΚΟ — το κείμενο δένει στην υπογεγραμμένη ρίζα του corpus.~%") 0)
              (progn (format t "✗ ΑΠΕΤΥΧΕ (~A) — το κείμενο ΔΕΝ είναι το αυθεντικό άρθρο.~%" reason) 1))))))

;;; ----------------------------------------------------------------------------
;;; TIER 2-H: bind the MCP get_article tool to LIVE consolidation, so an agent
;;; receives the authentic provision text + citation + ELI + a freshly built,
;;; self-consistent PCL-1 proof — no dependency on pre-emitted output files.
;;; ----------------------------------------------------------------------------

(defvar *mcp-corpus-cache* (make-hash-table :test 'equal)
  "corpus-id -> plist (:ids :texts :leaves :root :eli :abbrev) built once per process.")

(defun %aid-of-eid (eid)
  (let ((us (position #\_ eid :from-end t)))
    (if us (subseq eid (1+ us)) eid)))

(defun %mcp-corpus-entry (corpus-id)
  "Build (and cache) the leaf/root index for CORPUS-ID from live consolidation."
  (or (gethash corpus-id *mcp-corpus-cache*)
      (setf (gethash corpus-id *mcp-corpus-cache*)
            (handler-case
                (multiple-value-bind (short doc) (build-consolidated-for corpus-id)
                  (declare (ignore short))
                  (let* ((cons-pkg :orchestrator.consolidation)
                         (provs (funcall (find-symbol "LEGAL-DOCUMENT-PROVISIONS" cons-pkg) doc))
                         (eid-fn (find-symbol "PROVISION-EID" cons-pkg))
                         ;; [P1.5-A] seat rename: LEAF-HASH→HASH-LEAF-STRING,
                         ;; BUILD-MERKLE-ROOT→MERKLE-TREE-HASH (orchestrator.merkle,
                         ;; re-exported από proof-carrying). Τα παλιά ονόματα
                         ;; έδιναν NIL ⇒ ο live resolver σιωπηλά επέστρεφε :error.
                         (leaf-fn (find-symbol "HASH-LEAF-STRING" :orchestrator.proof-carrying))
                         (root-fn (find-symbol "MERKLE-TREE-HASH" :orchestrator.proof-carrying))
                         (eli (or (ignore-errors (orchestrator.spec:config-get "corpus.eli_prefix")) ""))
                         (abbr (or (ignore-errors (orchestrator.spec:config-get "corpus.citation_abbrev"))
                                   (ignore-errors (orchestrator.spec:config-get "corpus.short_name")) ""))
                         (ids (mapcar (lambda (p) (%aid-of-eid (funcall eid-fn p))) provs))
                         ;; ONE canonical text — same as --emit-proofs & the site.
                         (texts (mapcar #'orchestrator.static-site:article-canonical-text provs))
                         (leaves (mapcar (lambda (tx) (funcall leaf-fn tx)) texts))
                         (root (and leaves (funcall root-fn leaves))))
                    (list :ids ids :texts texts :leaves leaves :root root :eli eli :abbrev abbr)))
              (error (e) (declare (ignore e)) :error)))))

(defun %mcp-resolve-article (corpus id)
  "Return (plist :text :cite :eli :proof) for article ID in CORPUS, freshly built
   from live consolidation, or NIL if unknown."
  (let ((entry (%mcp-corpus-entry corpus)))
    (when (and (consp entry) (getf entry :root))
      (let ((idx (position id (getf entry :ids) :test #'string=)))
        (when idx
          (let* ((text (nth idx (getf entry :texts)))
                 (abbr (getf entry :abbrev)) (eli (getf entry :eli))
                 (make-fn (find-symbol "MAKE-PROVISION-PROOF" :orchestrator.proof-carrying))
                 (json-fn (find-symbol "PROOF-PLIST->JSON" :orchestrator.proof-carrying))
                 (proof (funcall make-fn id text (getf entry :leaves) idx (getf entry :root)
                                 :eli (format nil "~A/art/~A" eli id)
                                 :cite (format nil "Άρθρο ~A~@[ ~A~]" id (and (plusp (length abbr)) abbr))
                                 :anchored-at ;; [P1.5-C] commitment-time από την έδρα χρόνου (ΟΧΙ ψεύτικη σταθερά)·
                          ;; ο ΑΠΟΔΕΔΕΙΓΜΕΝΟΣ χρόνος ζει στο RFC-3161 receipt του release.
                          (orchestrator.time:format-iso8601 (orchestrator.time:require-deterministic-time)))))
            (list :text text
                  :cite (format nil "Άρθρο ~A~@[ ~A~]" id (and (plusp (length abbr)) abbr))
                  :eli (format nil "~A/art/~A" eli id)
                  :proof (funcall json-fn proof))))))))

(defparameter *latin-homoglyph-chars* "ABEZHIKMNOPTYXo"
  "Latin letters a ΦΕΚ PDF emits for the visually identical Greek letter. One sitting
   inside a Greek-letter token is an un-repaired homoglyph error.")

(defun %greek-block-char-p (ch)
  (let ((c (char-code ch))) (or (<= #x0370 c #x03FF) (<= #x1F00 c #x1FFF))))

(defun %text-homoglyph-p (text)
  "True if TEXT has a token mixing a real Greek letter with a Latin homoglyph
   (Oι, Aν, στoν) — i.e. a wrong-codepoint error the cleaner missed."
  (let ((n (length text)) (i 0))
    (loop while (< i n) do
      (let ((ch (char text i)))
        (if (or (alpha-char-p ch) (%greek-block-char-p ch))
            (let ((j i) (greekp nil) (latinp nil))
              (loop while (and (< j n)
                               (let ((c (char text j)))
                                 (or (alpha-char-p c) (%greek-block-char-p c))))
                    do (let ((c (char text j)))
                         (when (%greek-block-char-p c) (setf greekp t))
                         (when (find c *latin-homoglyph-chars*) (setf latinp t)))
                       (incf j))
              (when (and greekp latinp) (return-from %text-homoglyph-p t))
              (setf i j))
            (incf i))))
    nil))

(defun %text-hyphen-seam-p (text)
  "If TEXT has an unrejoined hyphenation seam <2+ letters>-<space(s)><lowercase letter>
   (δικαστη- αυτόν, συ- πράξεις) — text lost/garbled at a column/page break — return
   the ~60-char CONTEXT around it (so the audit shows exactly what broke), else NIL.
   Ignored (not seams): a spaced separator dash (λέξη - λέξη, space before the hyphen);
   a joined compound (κοινωνικο-οικ., no space after); and an enumeration range whose
   left side is a label, not a word — «α΄- θ΄» (tonos before) or «α- β» (single letter)
   — by requiring TWO real letters immediately before the hyphen."
  (let ((n (length text)))
    (loop for i from 2 below (1- n)
          when (and (char= (char text i) #\-)
                    ;; ≥2 real LETTERS before the hyphen → a word, not an enumeration
                    ;; label («α΄-», «α-») whose tonos/single letter is not a word part.
                    (alpha-char-p (char text (1- i)))
                    (alpha-char-p (char text (- i 2)))
                    (let ((j (1+ i)))
                      (loop while (and (< j n) (member (char text j) '(#\Space #\Tab #\Newline)))
                            do (incf j))
                      (and (> j (1+ i)) (< j n) (lower-case-p (char text j)))))
            do (return-from %text-hyphen-seam-p
                 (substitute #\Space #\Newline
                             (subseq text (max 0 (- i 40)) (min n (+ i 25))))))
    nil))

(defun %mcp-audit-corpus (corpus)
  "Quality report a connected AI uses to audit CORPUS's codification: count,
   numbering range, lettered families, gaps (repealed-or-missing for the AI to
   judge), suspiciously empty/short articles, and the two extraction error classes
   the cleaner must drive to zero — Latin/Greek homoglyphs and unrejoined hyphenation
   seams. Built from live consolidation."
  (let ((entry (%mcp-corpus-entry corpus)))
    (when (and (consp entry) (getf entry :ids))
      (let* ((ids (getf entry :ids)) (texts (getf entry :texts))
             (nums (sort (remove-duplicates
                          (loop for id in ids for n = (parse-integer id :junk-allowed t)
                                when n collect n)) #'<))
             (lettered (count-if (lambda (id) (some (lambda (c) (not (digit-char-p c))) id)) ids))
             (gaps (loop for (a b) on nums while b
                         when (> b (1+ a)) collect (format nil "~D→~D" a b)))
             ;; A repealed article («Καταργήθηκε.») is short ON PURPOSE — that is
             ;; faithful codification, not a defect. Exclude any «καταργ…» body
             ;; (case-insensitive: «(καταργείται)» appears lower-case too).
             (suspect (loop for id in ids for tx in texts
                            for clean = (string-trim '(#\Space #\Tab #\Newline) (or tx ""))
                            when (and (< (length clean) 20)
                                      (not (search "καταργ" (string-downcase clean))))
                              collect id))
             (homoglyphs (loop for id in ids for tx in texts
                               when (%text-homoglyph-p (or tx "")) collect id))
             (hyphen-breaks (loop for id in ids for tx in texts
                                  for ctx = (%text-hyphen-seam-p (or tx ""))
                                  when ctx collect (format nil "~A «~A»" id ctx))))
        (list :count (length ids) :min (and nums (first nums)) :max (and nums (car (last nums)))
              :lettered lettered :gaps gaps :suspect suspect
              :homoglyphs homoglyphs :hyphen-breaks hyphen-breaks
              :note (format nil "~D κενά αρίθμησης (κρίνε αν είναι καταργήσεις), ~D ύποπτα, ~
                                 ~D homoglyphs, ~D σπασμένες ραφές. ~A Δες λεπτομέρειες με ~
                                 get_article(corpus=~S, id=…)."
                            (length gaps) (length suspect) (length homoglyphs) (length hyphen-breaks)
                            (if (and (null homoglyphs) (null hyphen-breaks) (null suspect))
                                "✓ 0 λάθη ποιότητας."
                                "")
                            corpus))))))

(defun install-live-mcp-resolvers ()
  "Point the MCP server's injected resolvers at live consolidation."
  (setf (symbol-value (find-symbol "*ARTICLE-RESOLVER*" :orchestrator.mcp))
        #'%mcp-resolve-article)
  (setf (symbol-value (find-symbol "*CORPUS-LIST-FN*" :orchestrator.mcp))
        (lambda () (copy-list *served-corpora*)))
  (setf (symbol-value (find-symbol "*CORPUS-AUDIT-FN*" :orchestrator.mcp))
        #'%mcp-audit-corpus))

(defun dump-pdf-text ()
  "Diagnostic: extract the active corpus's source.pdf to text (raw + cleaned),
   write both under the corpus output dir, and print the first lines — so the
   real structure of a given source (DSAnet/Isokratis/ΦΕΚ) can be inspected and
   the parser tuned to it. ORCHESTRATOR_CORPUS selects the code; DUMP_LINES sets
   how many cleaned lines to print (default 150); ORCHESTRATOR_PDF_PATH overrides."
  (orchestrator.spec:select-corpus (uiop:getenv "ORCHESTRATOR_CORPUS"))
  (orchestrator.gr-syntagma:register-active-corpus)
  (let* ((short (or (ignore-errors (orchestrator.spec:config-get "corpus.short_name")) "corpus"))
         (pdf (or (uiop:getenv "ORCHESTRATOR_PDF_PATH")
                  (orchestrator.spec:resolve-config-path "source.pdf")))
         (n (let ((p (uiop:getenv "DUMP_LINES")))
              (or (and p (parse-integer p :junk-allowed t)) 150)))
         (out-dir (corpus-output-dir
                   (or (uiop:getenv "ORCHESTRATOR_OUTPUT_DIR") (orchestrator.paths:institution-dir "output/")))))
    (unless (and pdf (probe-file pdf))
      (format t "✗ Δεν βρέθηκε PDF για ~A: ~A~%" short pdf)
      (return-from dump-pdf-text 1))
    (format t "~%═══ DUMP PDF TEXT: ~A ═══~%PDF: ~A~%" short pdf)
    (let* ((raw (funcall (find-symbol "EXTRACT-TEXT-FROM-PDF" :orchestrator.pdf-authority) pdf))
           (cleaned (funcall (find-symbol "CLEAN-FEK-TEXT" :orchestrator.engine.sbcl) raw))
           ;; Also dump the COLUMN-reflowed extraction (the real ΦΕΚ path) so the
           ;; reflow output can be inspected directly — DUMP_GREP=<term> prints the
           ;; window around each match so a seam can be traced without huge files.
           (columns (funcall (find-symbol "EXTRACT-TEXT-COLUMNS-FROM-PDF" :orchestrator.pdf-authority) pdf))
           (columns-cleaned (funcall (find-symbol "CLEAN-FEK-TEXT" :orchestrator.engine.sbcl) columns)))
      (ensure-directories-exist (uiop:ensure-directory-pathname out-dir))
      (flet ((w (name content)
               (let ((p (merge-pathnames name (uiop:ensure-directory-pathname out-dir))))
                 (with-open-file (s p :direction :output :if-exists :supersede
                                      :if-does-not-exist :create :external-format :utf-8)
                   (write-string content s))
                 p)))
        (format t "raw=~D chars -> ~A~%" (length raw) (w (format nil "~A.raw.txt" short) raw))
        (format t "cleaned=~D chars -> ~A~%" (length cleaned)
                (w (format nil "~A.cleaned.txt" short) cleaned))
        (format t "columns(reflow) raw=~D chars -> ~A~%" (length columns)
                (w (format nil "~A.columns.txt" short) columns))
        (format t "columns(reflow) cleaned=~D chars -> ~A~%~%" (length columns-cleaned)
                (w (format nil "~A.columns.cleaned.txt" short) columns-cleaned)))
      (let ((grep (uiop:getenv "DUMP_GREP")))
        (when (and grep (plusp (length grep)))
          (format t "── DUMP_GREP ~S στο columns(raw) — παράθυρο 200 χαρ. ─────~%" grep)
          (let ((start 0))
            (loop for pos = (search grep columns :start2 start) while pos do
              (format t "  …~A…~%~%"
                      (subseq columns (max 0 (- pos 120)) (min (length columns) (+ pos 120))))
              (setf start (+ pos (length grep)))))
          (format t "──────────────────────────────────────────────────────~%")))
      (format t "── πρώτες ~D γραμμές (columns cleaned) ──────────────────~%" n)
      (let ((i 0))
        (dolist (ln (uiop:split-string columns-cleaned :separator '(#\Newline)))
          (when (< i n)
            (incf i)
            (format t "~4,'0D| ~A~%" i (subseq ln 0 (min 160 (length ln)))))))
      (format t "──────────────────────────────────────────────────────~%")
      0)))

(defun serve-review ()
  "Start the lawyer's web approval screen over the persistent review queue.
   The page lists every uncertain change with its Greek summary and Έγκριση /
   Απόρριψη buttons; a decision is recorded (who + when) and persisted at once.
   REVIEW_PORT (default 8081) and REVIEW_QUEUE_FILE / ORCHESTRATOR_OUTPUT_DIR
   from the environment."
  (let* ((port (let ((p (uiop:getenv "REVIEW_PORT")))
                 (or (and p (parse-integer p :junk-allowed t)) 8081)))
         ;; Re-load on every request so the page reflects whatever the daemon has
         ;; enqueued in the meantime; persist after each decision.
         (service (funcall (find-symbol "MAKE-REVIEW-SERVICE" :orchestrator.review-service)
                           :load-fn #'load-review-queue
                           :save-fn #'save-review-queue))
         (handler (funcall (find-symbol "REVIEW-SERVICE-HANDLER" :orchestrator.review-service)
                           service)))
    (format t "~%Review approval screen: http://0.0.0.0:~D~%" port)
    (format t "  GET /            ο πίνακας έγκρισης (HTML)~%")
    (format t "  GET /review.json τα εκκρεμή σε JSON~%")
    (format t "  Queue file: ~A~%" (%review-queue-file))
    (orchestrator.http:start-server handler :port port :host "0.0.0.0")
    (loop (sleep 3600))))

(defun %env-pathname (name)
  (let ((v (uiop:getenv name))) (and v (plusp (length v)) (pathname v))))

(defun make-consensus-ingestion-source (review-queue)
  "Build the multi-source consensus acquisition stack as a single ingestion source
   (INGEST_SOURCE=consensus). Channels are configured from env, highest authority
   first; an unconfigured channel is simply skipped:

     FEK_FEED_URL / FEK_FEED_DIR  the sanctioned ΦΕΚ feed (the top channel)
     CELLAR_ELI                   the EUR-Lex/CELLAR work to corroborate against
     ALLOW_SCRAPER=1              enable the (fragile) ΦΕΚ web scraper fallback

   Provisions on which the available channels AGREE are dispatched and published;
   genuine disagreements are turned into high-severity review items and enqueued
   for the lawyer — the system never silently picks the authoritative text."
  (let ((profiles (orchestrator.source-authority:default-source-profiles
                   :fek-feed-url (uiop:getenv "FEK_FEED_URL")
                   :fek-feed-dir (%env-pathname "FEK_FEED_DIR")
                   :eli (uiop:getenv "CELLAR_ELI")
                   :diavgeia t
                   :scrape (let ((s (uiop:getenv "ALLOW_SCRAPER")))
                             (and s (plusp (length s)) (not (string= s "0"))))
                   :manual t)))
    (format t "Consensus acquisition stack (highest authority first):~%")
    (dolist (p profiles)
      (format t "  · ~24A authority ~3D  ~:[unavailable~;available~]~%"
              (orchestrator.source-authority:profile-name p)
              (orchestrator.source-authority:profile-authority p)
              (orchestrator.source-authority:profile-available-p p)))
    (orchestrator.source-authority:make-consensus-source
     :profiles profiles
     :on-conflict
     (lambda (conflicts)
       (let ((items (orchestrator.source-authority:consensus-conflicts->review-items conflicts)))
         (dolist (ri items)
           (funcall (find-symbol "ENQUEUE" :orchestrator.review) review-queue ri))
         (when items
           (format t "Consensus: ~D source disagreement(s) queued for review.~%" (length items))
           (save-review-queue review-queue)))))))

(defun %approved-review-records (corpus-id)
  "The operations the human APPROVED in the review queue, as one synthetic
   amendment record for CORPUS-ID — so consolidation applies them through the
   very same path as any ΦΕΚ (no second application mechanism)."
  (handler-case
      (let* ((q (load-review-queue))
             (ops (remove-if-not
                   (lambda (op)
                     (let ((c (getf op :code)))
                       (or (null c) (equal c corpus-id))))
                   (orchestrator.review:approved-operations q))))
        (when ops
          (list (list :id "review:εγκεκριμένα" :operations ops))))
    (error () nil)))

(defun main (&rest args)
  "Main CLI entrypoint - ΩΜΕΓΑ GRADE"
  (let* ((argv (or args sb-ext:*posix-argv*))
         (command (parse-command argv))
         ;; MCP speaks JSON-RPC on stdout — keep stdout CLEAN: in MCP mode the
         ;; banner, system info and all logging go to stderr instead.
         (mcp-mode (and command (string= command "--serve-mcp"))))
    (configure-stable-logging :stream (if mcp-mode *error-output* *standard-output*))
    (unless mcp-mode
      (print-banner)
      (print-system-info))
    ;; ΠΡΟΦΙΛ ΙΧΝΩΝ από το περιβάλλον — ΡΗΤΑ και ορατά, ποτέ σιωπηλά:
    ;; off/minimal σημαίνει ΚΑΜΙΑ έμπιστη legal-critical έξοδος (--ask αρνείται).
    (let ((env (uiop:getenv "ORCHESTRATOR_TRACE_PROFILE")))
      (when (and env (plusp (length env)))
        (let ((prof (cond ((string-equal env "off") :off)
                          ((string-equal env "minimal") :minimal)
                          ((string-equal env "legal-critical") :legal-critical)
                          ((string-equal env "full-debug") :full-debug)
                          (t nil))))
          (cond (prof (setf orchestrator.trace:*trace-profile* prof)
                      (unless (member prof '(:legal-critical :full-debug))
                        (format *error-output*
                                "⚠ ΠΡΟΦΙΛ ΙΧΝΩΝ ~(~A~): καμία έμπιστη legal-critical έξοδος σε αυτόν τον τρόπο.~%"
                                prof)))
                (t (format *error-output*
                           "⚠ Άγνωστο ORCHESTRATOR_TRACE_PROFILE «~A» — μένει ~(~A~).~%"
                           env orchestrator.trace:*trace-profile*))))))
    ;; ΡΙΖΑ ΓΝΩΣΗΣ: τα πακέτα γνώσης φορτώνονται ΣΕ ΚΑΘΕ εκκίνηση — χωρίς αυτά
    ;; οι κανόνες/ορισμοί λείπουν και κάθε πύλη/διάλογος κρίνει στο κενό.
    ;; Αποτυχία = ΦΩΝΑΧΤΗ δήλωση στο stderr, ποτέ σιωπηλό κενό γνώσης.
    (handler-case
        (orchestrator.knowledge-packs:ensure-fresh
         :stream (if mcp-mode *error-output* *standard-output*))
      (error (e)
        (format *error-output* "~%⚠ ΠΑΚΕΤΑ ΓΝΩΣΗΣ ΔΕΝ ΦΟΡΤΩΘΗΚΑΝ: ~A~%~
                                ⚠ Το σύστημα τρέχει ΧΩΡΙΣ δηλωτική γνώση — οι κρίσεις θα είναι ελλιπείς.~%" e)))

  (let ((exit-code
          (handler-case
                ;; ΕΝΑΣ δρόμος για ΚΑΘΕ πράξη — εγγεγραμμένη στο μητρώο ή builtin:
                ;; ΟΛΕΣ μέσω του συντάγματος (CLOS :around, constitutional-dispatch).
                ;; Κανένα προνομιακό μονοπάτι: εξωτερική επιθεώρηση (05-07-2026)
                ;; βρήκε 30 builtin εντολές να εκτελούνται ΕΚΤΟΣ της πύλης του
                ;; ΕΓΩ — το εύρημα κλείνει εδώ, στη ρίζα της δρομολόγησης.
                (execute-command command
                                 (or (find-command command)
                                     (lambda (args)
                                       (declare (ignore args))
                                       (format *error-output* "Unknown command: ~A~%" command)
                                       (print-usage)
                                       1))
                                 (rest (%user-args argv)))

            ;; DARPA EXIT CODES: deterministic error classification
            (orchestrator.spec:validation-error (e)
              (format *error-output* "~%FATAL ERROR (VALIDATION): ~A~%" e)
              (format *error-output* "Pipeline integrity compromised - validation failed~%")
              2)

            (error (e)
              (format *error-output* "~%FATAL ERROR: ~A~%" e)
              1))))

    ;; CRITICAL: Actually exit with the code (don't just return it)
    (sb-ext:exit :code exit-code))))
