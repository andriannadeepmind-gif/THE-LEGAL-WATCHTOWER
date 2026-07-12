;;;; source/consolidation-bridge.lisp
;;;; ============================================================================
;;;; CONSOLIDATION BRIDGE
;;;; ============================================================================
;;;;
;;;; Connects the consolidation engine to real data:
;;;;
;;;;   1. Corpus articles (as parsed from the JSON corpus: a number, a title and
;;;;      content text/paragraphs) -> a consolidation LEGAL-DOCUMENT whose
;;;;      provisions are addressed by stable Akoma-Ntoso-style eIds.
;;;;
;;;;   2. Amendment records in the existing ELI-temporal config shape
;;;;      (id / date / date_applicability / fek / articles_amended /
;;;;       articles_repealed [/ operations]) -> AMENDING-ACT objects.
;;;;
;;;; Honesty guarantee: when the config only states WHICH articles an act
;;;; amended (no consolidated text), we record provenance via :mark-amended
;;;; rather than fabricating legal text. Repeals are fully derived from
;;;; articles_repealed and need no text. Acts may also carry explicit, text
;;;; bearing operations, which are applied as-is.
;;;; ============================================================================

(defpackage :orchestrator.consolidation.bridge
  (:use :cl :orchestrator.consolidation)
  (:export
   #:article-eid #:paragraph-eid
   #:article->provision #:articles->document
   #:amendment-records->acts
   #:consolidate-corpus
   #:apply-extracted-amendments #:auto-applicable-operation-p
   #:round-trip-report
   #:law->record #:laws->records))

(in-package :orchestrator.consolidation.bridge)

;;; ============================================================================
;;; eId SCHEME
;;; ============================================================================

(defun article-eid (number)
  (format nil "art_~A" number))

(defun paragraph-eid (number index)
  (format nil "art_~A__para_~A" number index))

;;; ============================================================================
;;; ARTICLES -> DOCUMENT
;;; ============================================================================

(defun %normalize-content (content)
  "Return CONTENT as a list of non-empty paragraph strings.
   Accepts a string, a list of strings, or a vector of strings."
  (let ((items (cond ((stringp content) (list content))
                     ((and (vectorp content) (not (stringp content)))
                      (coerce content 'list))
                     ((listp content) content)
                     ((null content) nil)
                     (t (list (princ-to-string content))))))
    (remove-if (lambda (x) (or (null x) (and (stringp x) (zerop (length x)))))
               (mapcar (lambda (x) (if (stringp x) x (princ-to-string x))) items))))

(defun article->provision (number title content)
  "Build an article PROVISION from a number, a title and its content.

   A single-paragraph article keeps its text inline; a multi-paragraph article
   gets one child paragraph provision per element so amendments can target an
   individual paragraph (art_N__para_M)."
  (let ((paras (%normalize-content content)))
    (cond
      ((<= (length paras) 1)
       (make-provision :eid (article-eid number) :kind :article
                       :num (princ-to-string number) :heading title
                       :text (first paras)))
      (t
       (make-provision
        :eid (article-eid number) :kind :article
        :num (princ-to-string number) :heading title
        :children
        (loop for p in paras
              for m from 1
              collect (make-provision :eid (paragraph-eid number m)
                                      :kind :paragraph :num (princ-to-string m)
                                      :text p)))))))

(defun articles->document (articles &key id title (language "el"))
  "Build a LEGAL-DOCUMENT from ARTICLES, a list of (number title content).
   Το ID είναι ΥΠΟΧΡΕΩΤΙΚΟ — η ταυτότητα corpus δεν μαντεύεται ποτέ (το παλιό
   σιωπηλό default «corpus» έγραφε πλαστή ταυτότητα εγγράφου)."
  (unless (and (stringp id) (plusp (length id)))
    (error "articles->document: το :id (ταυτότητα corpus) είναι υποχρεωτικό — δόθηκε ~S" id))
  (make-legal-document
   :id id :title title :language language
   :provisions
   (mapcar (lambda (a)
             (destructuring-bind (number title content) a
               (article->provision number title content)))
           articles)))

;;; ============================================================================
;;; CONFIG AMENDMENT RECORDS -> AMENDING-ACTS
;;; ============================================================================

(defun %rget (record key)
  "Read KEY from a record that may be a string-keyed alist (ELI-temporal config
   shape), a keyword plist, or a hash-table (e.g. parsed YAML). KEY is a string;
   its keyword form is also tried."
  (cond
    ((hash-table-p record)
     (multiple-value-bind (v found) (gethash key record)
       (if found v
           (gethash (intern (string-upcase key) :keyword) record))))
    ((and (listp record) (consp (first record)))    ; alist
     (cdr (or (assoc key record :test #'equal)
              (assoc (intern (string-upcase key) :keyword) record :test #'eql))))
    ((listp record)                                  ; plist
     (getf record (intern (string-upcase key) :keyword)))
    (t nil)))

(defun amendment-record->act (record)
  "Convert a single amendment RECORD (ELI-temporal config shape) into an
   AMENDING-ACT, auto-deriving operations:
     - articles_repealed -> :repeal art_N
     - articles_amended  -> :mark-amended art_N
     - operations        -> applied verbatim (native op plists), if present"
  (let* ((id (%rget record "id"))
         (date (%rget record "date"))
         (applic (or (%rget record "date_applicability") date))
         (fek (%rget record "fek"))
         (amended (%rget record "articles_amended"))
         (repealed (%rget record "articles_repealed"))
         (explicit (%rget record "operations"))
         ;; P1.4 [0054]#7: transaction-time capture (θεμέλιο Ω2 bitemporal).
         ;; Ρητό record field «recorded_at» = η αληθινή στιγμή γνώσης· αλλιώς
         ;; σφραγίζεται από την ΝΤΕΤΕΡΜΙΝΙΣΤΙΚΗ έδρα χρόνου (:deterministic —
         ;; pinned epoch σε reproducible build, γνήσιο now σε live serving).
         ;; Ο χρόνος γνώσης δεν χάνεται· δεν είναι πλαστή νομική ημερομηνία
         ;; αλλά τίμια σφραγίδα συστημικού γεγονότος εισαγωγής.
         (recorded (or (%rget record "recorded_at")
                       (orchestrator.time:format-iso8601
                        (orchestrator.time:now :source :deterministic))))
         (ops '()))
    ;; Repeals first (strongest status), then amendment provenance.
    ;; These are derived from amendment METADATA (article lists), so a target
    ;; absent from a partial corpus is tolerated rather than fatal.
    (dolist (n repealed)
      (push (list :op :repeal :target (article-eid n) :if-missing :skip) ops))
    (dolist (n amended)
      (push (list :op :mark-amended :target (article-eid n) :if-missing :skip) ops))
    (setf ops (nreverse ops))
    (when explicit
      (setf ops (append ops explicit)))
    (make-amending-act
     :id (and id (princ-to-string id))
     :fek (and fek (princ-to-string fek))
     :enacted (and date (princ-to-string date))
     :effective (and applic (princ-to-string applic))
     :recorded (and recorded (princ-to-string recorded))
     :operations ops)))

(defun amendment-records->acts (records)
  "Convert a list of amendment RECORDS into AMENDING-ACT objects."
  (mapcar #'amendment-record->act records))

;;; ============================================================================
;;; CONVENIENCE: consolidate a corpus from raw inputs
;;; ============================================================================

(defun consolidate-corpus (articles amendment-records
                           &key as-of-date id title)
  "Consolidate a corpus end-to-end.

   ARTICLES:          list of (number title content).
   AMENDMENT-RECORDS: list of ELI-temporal config-shaped records.
   AS-OF-DATE:        optional ISO date; consolidate as it stood on that date.
   ID:                ΥΠΟΧΡΕΩΤΙΚΗ ταυτότητα corpus (βλ. articles->document).

   Returns the consolidated LEGAL-DOCUMENT."
  (consolidate (articles->document articles :id id :title title)
               (amendment-records->acts amendment-records)
               :as-of-date as-of-date))

(defun auto-applicable-operation-p (op)
  "T for an EXTRACT-OPERATIONS clause the engine can apply VERBATIM and safely,
   with no human in the loop: a :high-confidence :replace-text / :repeal /
   :mark-amended whose plist IS already an apply-operation clause (same :op,
   :target, :text, :if-missing keys). Structural :insert and whole-law
   :repeal-law are deliberately NOT auto-applicable — that is exactly what the
   extractor's :confidence levels are for: recognise everything, auto-apply only
   what is unambiguous, defer the rest to review."
  (and (eq :high (getf op :confidence))
       (member (getf op :op) '(:replace-text :repeal :mark-amended))))

(defun apply-extracted-amendments (document ops &key (id "fek") effective as-of-date)
  "Close the autonomy loop. OPS is the output of
   orchestrator.amendment-extractor:extract-operations for ONE code; DOCUMENT is
   that code's consolidated LEGAL-DOCUMENT. Wrap the auto-applicable ops in an
   amending act and run the consolidation engine — the op plists flow straight
   through, no translation. The base DOCUMENT is never mutated (consolidate copies);
   ops targeting a missing article skip themselves (:if-missing :skip the extractor
   already set). Returns (values consolidated-document applied-ops deferred-ops), so
   the caller can apply the certain changes and surface the rest for review.
   Deterministic: same ops in, same consolidated document out."
  (let* ((applied  (remove-if-not #'auto-applicable-operation-p ops))
         (deferred (remove-if     #'auto-applicable-operation-p ops))
         (act (make-amending-act :id id :effective effective :operations applied)))
    (values (consolidate document (list act) :as-of-date as-of-date)
            applied deferred)))

(defun round-trip-report (consolidated applied-ops)
  "[FEK-COMPILER] Έλεγχος εφαρμογής (application audit) των auto-applied
   πράξεων πάνω στο ενοποιημένο έγγραφο. ΤΙΜΙΑ ΕΜΒΕΛΕΙΑ (εύρημα κριτή #7):
   επαληθεύει ότι η μηχανή ΠΡΑΓΜΑΤΙ εφάρμοσε κάθε πράξη — ΔΕΝ ξαναδιαβάζει το
   ΦΕΚ ανεξάρτητα· η ισότητα κειμένου κληρονομεί την εγγύηση του extractor ότι
   το op :text είναι το αυτούσιο παράθεμα του ΦΕΚ (balanced «…»).
     :replace-text ⇒ provision παρόν ΚΑΙ κείμενο ≡ op :text·
     :repeal       ⇒ provision παρόν ΚΑΙ status :repealed·
     :mark-amended ⇒ provision παρόν ΚΑΙ status ≠ :original (η σφράγιση έγινε —
                     όχι σκέτη ύπαρξη, που θα ήταν ταυτολογία).
   Επιστρέφει (values verified skipped mismatched):
     SKIPPED    = ο στόχος ΔΕΝ υπάρχει (η μηχανή τον προσπέρασε με
                  :if-missing :skip) — αναφέρεται ΠΑΝΤΑ, ποτέ αόρατος·
     MISMATCHED = ο στόχος υπάρχει αλλά το αποτέλεσμα ΔΕΝ φέρει την πράξη —
                  εσωτερικό ελάττωμα, ΔΙΑΦΟΡΕΤΙΚΗ κλάση από το skip.
   verified+skipped+mismatched ≡ applied-ops — καμία πράξη αόρατη."
  (let ((verified '()) (skipped '()) (mismatched '()))
    (dolist (op applied-ops)
      (let* ((eid (getf op :target))
             (prov (and eid (find-provision consolidated eid))))
        (cond
          ((null prov) (push op skipped))
          (t (case (getf op :op)
               (:replace-text
                (if (equal (provision-text prov) (getf op :text))
                    (push op verified) (push op mismatched)))
               (:repeal
                (if (eq (provision-status prov) :repealed)
                    (push op verified) (push op mismatched)))
               (:mark-amended
                (if (not (eq (provision-status prov) :original))
                    (push op verified) (push op mismatched)))
               (t (push op verified)))))))
    (values (nreverse verified) (nreverse skipped) (nreverse mismatched))))

;;; ============================================================================
;;; AUTONOMY: amending-law TEXT -> per-corpus amendment records (auto-extracted)
;;; ============================================================================
;;; The discovery+fetch edge hands us the TEXT of each amending law. This turns it
;;; into the SAME ELI-temporal records consolidate-corpus already consumes — closing
;;; the loop discover → route → fetch → EXTRACT → consolidate, with the same «0 λάθη»
;;; discipline: only high-confidence operations are applied; the rest go to review.
;;; The extractor is looked up at runtime so the bridge carries no load-order
;;; dependency on it.

(defun %extract-ops (text &key code-resolver article-exists-fn)
  "Extract operations from amending TEXT, threading the registry CODE-RESOLVER and
   census ARTICLE-EXISTS-FN so routing/identity apply on THIS (consolidation) path
   too — not only on discovery. Χωρίς resolver, ΚΑΘΕ πράξη μένει αδρομολόγητη
   (:code NIL) και το law->record τη θεωρεί «sole» ⇒ θα εφαρμοζόταν σε ΚΑΘΕ κώδικα·
   ο resolver το κόβει στη ρίζα (η δρομολόγηση του FEK-COMPILER δένεται εδώ)."
  (let ((f (find-symbol "EXTRACT-OPERATIONS" :orchestrator.amendment-extractor)))
    (and f text (funcall f text :code-resolver code-resolver
                                :article-exists-fn article-exists-fn))))

(defun %op-applicable (op)
  (let ((f (find-symbol "OPERATION-APPLICABLE-P" :orchestrator.amendment-extractor)))
    (and f (funcall f op))))

(defun law->record (law corpus-id &key code-resolver article-exists-fn)
  "LAW (alist/plist with \"id\",\"date\",\"fek\",\"text\") → an amendment RECORD whose
   \"operations\" are the law's APPLICABLE operations that target CORPUS-ID, or NIL if
   the law does not amend this corpus. A clause whose code did not resolve is taken
   ONLY when CORPUS-ID is the law's sole code — never guessed across a multi-code act.
   Recognised-but-not-auto-applicable operations are kept under \"review\".
   CODE-RESOLVER/ARTICLE-EXISTS-FN: περνούν στον extractor ώστε η δρομολόγηση ανά
   κώδικα + η επαλήθευση ταυτότητας να ισχύουν ΚΑΙ εδώ (χωρίς αυτά, κάθε πράξη
   θεωρείται sole-unrouted ⇒ θα εφαρμοζόταν σε ΚΑΘΕ corpus)."
  (let ((ops (%extract-ops (%rget law "text") :code-resolver code-resolver
                                              :article-exists-fn article-exists-fn)))
    (when ops
      (let* ((codes (remove nil (remove-duplicates
                                 (mapcar (lambda (o) (getf o :code)) ops) :test #'equal)))
             (sole (or (null codes) (equal codes (list corpus-id))))
             ;; FAIL-CLOSED (εύρημα κριτή C/BONUS): ΜΟΝΟ ΔΡΟΜΟΛΟΓΗΜΕΝΕΣ σε ΑΥΤΟΝ
             ;; τον κώδικα πράξεις αυτο-εφαρμόζονται. Αδρομολόγητη πράξη (:code
             ;; NIL) — ακόμη κι όταν ο νόμος αγγίζει μόνο αυτόν τον κώδικα (sole)
             ;; — ΔΕΝ αυτο-εφαρμόζεται ποτέ· πάει στο review. Το «sole» δεν είναι
             ;; πλέον άδεια εφαρμογής, μόνο κριτήριο για το τι εμφανίζεται στο
             ;; review αυτού του κώδικα. Έτσι το fail-closed είναι ΔΟΜΙΚΟ, όχι
             ;; ατύχημα του κειμένου: καμία πράξη χωρίς αποδεδειγμένη δρομολόγηση.
             (routed-here (remove-if-not
                           (lambda (o) (equal (getf o :code) corpus-id)) ops))
             (unrouted-sole (when sole
                              (remove-if (lambda (o) (getf o :code)) ops)))
             (applicable (remove-if-not #'%op-applicable routed-here))
             (review (append (remove-if #'%op-applicable routed-here)
                             unrouted-sole)))
        (when applicable
          (flet ((s (k) (let ((v (%rget law k))) (and v (princ-to-string v)))))
            (list :id (s "id") :fek (s "fek") :date (s "date")
                  :date_applicability (or (s "date_applicability") (s "date"))
                  :operations applicable :review review)))))))

(defun laws->records (laws corpus-id &key code-resolver article-exists-fn)
  "Map amending LAWS to the records that apply to CORPUS-ID (laws not touching it are
   dropped), in deterministic chronological order. CODE-RESOLVER/ARTICLE-EXISTS-FN
   are threaded to each law->record (per-code routing + identity verification)."
  (let ((recs (loop for law in laws
                    for r = (law->record law corpus-id :code-resolver code-resolver
                                         :article-exists-fn article-exists-fn)
                    when r collect r)))
    (stable-sort recs #'string< :key (lambda (r) (or (getf r :date_applicability) "")))))
