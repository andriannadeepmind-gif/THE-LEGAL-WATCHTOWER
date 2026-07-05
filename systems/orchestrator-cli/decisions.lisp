;;;; systems/orchestrator-cli/decisions.lisp
;;;; ============================================================================
;;;; ΕΝΤΟΛΕΣ ΝΟΜΟΛΟΓΙΑΣ — intake, κατέβασμα (ΑΠ), υλικοποίηση, tempus, χάρτης
;;;; θέσεων, κατ' άρθρον ευρετήριο, προφίλ δικαστή, αναστοχασμός.
;;;; ============================================================================
;;;;
;;;; Βγήκε ολόκληρο ως συνεκτικό cluster από το main.lisp (αποδόμηση θεού-φακέλου
;;;; #2). Φορτώνεται ΤΕΛΕΥΤΑΙΟ: όλοι οι βοηθοί που χρησιμοποιεί (cli-util +
;;;; provenance/errata/articles του main) είναι ήδη ορισμένοι → μηδέν
;;;; forward-reference. Οι εντολές του ΕΓΓΡΑΦΟΝΤΑΙ στο μητρώο (register-command)
;;;; στο τέλος — το main δεν τις αγγίζει (open/closed).

(in-package :orchestrator.cli)

(defun %served-article-dates (corpus-id)
  "label → per-article version date (DD/MM/YYYY) from the served source.json of
   CORPUS-ID. NIL when the corpus or its JSON is unavailable."
  (handler-case
      (progn
        (orchestrator.spec:select-corpus corpus-id)
        (let* ((json-path (orchestrator.spec:config-get "source.json"))
               (objs (jonathan:parse (uiop:read-file-string json-path :external-format :utf-8)
                                     :as :alist))
               (table (make-hash-table :test 'equal)))
          (dolist (o objs table)
            (let ((title (cdr (assoc "title" o :test #'string=)))
                  (date (cdr (assoc "date" o :test #'string=))))
              (multiple-value-bind (aid) (%parse-article-title title)
                (when aid (setf (gethash aid table) date)))))))
    (error () nil)))

(defun %tempus-verdict (article-date decision-year)
  "The tempus-regit-actum verdict for a citation: compare the cited article's
   last-modification year with the decision year.
     :same-text-proven  — modified BEFORE the decision year: the court applied
                          the very text served today, provably (the two dates).
     :verify-same-year  — modified IN the decision year: order within the year
                          is unknown from the year alone — human check.
     :amended-after     — modified AFTER the decision: the served text is NOT
                          what the court applied· ελέγξτε αν η κρίση διατηρεί ισχύ."
  (let ((ay (and article-date (= (length article-date) 10)
                 (parse-integer article-date :start 6 :junk-allowed t))))
    (cond ((null ay) :unknown)
          ((< ay decision-year) :same-text-proven)
          ((= ay decision-year) :verify-same-year)
          (t :amended-after))))

(defun %date-key (date)
  "dd/mm/yyyy Ή yyyy-mm-dd → συγκρίσιμο yyyymmdd, αλλιώς NIL."
  (and date (stringp date) (= (length date) 10)
       (ignore-errors
        (if (char= (char date 4) #\-)
            (+ (* (parse-integer date :end 4) 10000)
               (* (parse-integer date :start 5 :end 7) 100)
               (parse-integer date :start 8))
            (+ (* (parse-integer date :start 6) 10000)
               (* (parse-integer date :start 3 :end 5) 100)
               (parse-integer date :end 2))))))

(defun %act-verdict (article-date act-date decision-year penal-p)
  "Η ετυμηγορία στον άξονα του ΧΡΟΝΟΥ ΤΕΛΕΣΗΣ — ποιο δίκαιο διέπει την πράξη:
     :same-since-act   — το άρθρο δεν άλλαξε από πριν την πράξη έως σήμερα: το
                         σερβιριζόμενο κείμενο ΕΙΝΑΙ το δίκαιο της πράξης
                         (αποδεικνύεται από τις δύο ημερομηνίες).
     :lex-mitior-check — (ποινικά) τροποποιήθηκε ΜΕΣΑ στο παράθυρο τέλεση→κρίση:
                         άρθρο 2 ΠΚ — εφαρμοστέος ο επιεικέστερος· θέλει κρίση.
     :amended-since-act— (αστικά/διοικητικά) ίδιο παράθυρο: το δίκαιο της πράξης
                         ΔΕΝ είναι το σερβιριζόμενο κείμενο (tempus regit actum).
     :amended-after-judgment — άλλαξε μετά την απόφαση (όπως ο άξονας δεδικασμένου).
   NIL όταν λείπει είτε ημερομηνία άρθρου είτε χρόνος τέλεσης — ποτέ μάντεμα."
  (let ((ak (%date-key act-date)) (dk (%date-key article-date)))
    (when (and ak dk)
      (cond ((<= dk ak) :same-since-act)
            ((> (floor dk 10000) decision-year) :amended-after-judgment)
            (penal-p :lex-mitior-check)
            (t :amended-since-act)))))

(defparameter *court-registry*
  '(("ΑΡΕΙΟΥ ΠΑΓΟΥ" "areios-pagos" "ap")
    ("ΑΡΕΙΟΣ ΠΑΓΟΣ" "areios-pagos" "ap")
    ("ΕΦΕΤΕΙΟ ΠΕΙΡΑΙΩΣ" "efeteio-peiraios" "efpeir")
    ("ΕΦΕΤΕΙΟ ΑΘΗΝΩΝ" "efeteio-athinon" "efath")
    ("ΕΦΕΤΕΙΟ ΘΕΣΣΑΛΟΝΙΚΗΣ" "efeteio-thessalonikis" "efthes")
    ("ΠΡΩΤΟΔΙΚΕΙΟ ΑΘΗΝΩΝ" "protodikeio-athinon" "prath")
    ("ΠΡΩΤΟΔΙΚΕΙΟ ΠΕΙΡΑΙΩΣ" "protodikeio-peiraios" "prpeir"))
  "(αναγνωριστικό-στο-κείμενο slug tag): τα δικαστήρια που το intake
   αναγνωρίζει ΑΠΟ ΤΟ ΙΔΙΟ ΤΟ ΕΓΓΡΑΦΟ. Νέο δικαστήριο = μία ακόμη γραμμή.")

(defun %lesson (kind subject detail)
  "ΜΝΗΜΗ ΑΝΑΣΤΟΧΑΣΜΟΥ: κάθε αποτυχία/αδυναμία του συστήματος καταγράφεται
   ΔΟΜΗΜΕΝΑ (είδος, αντικείμενο, λεπτομέρεια, πότε) στο lessons.jsonl — ώστε
   τα επαναλαμβανόμενα μοτίβα να γίνονται ορατά (--lessons) και διορθώσιμα
   στην ρίζα, όχι να ξανασυμβαίνουν σιωπηλά. Append-only, ποτέ δεν πετάει."
  (ignore-errors
    (let ((path (merge-pathnames "lessons.jsonl" (%state-dir))))
      (ensure-directories-exist path)
      (multiple-value-bind (sec min hr day mo yr) (decode-universal-time (get-universal-time) 0)
        (declare (ignore sec min hr))
        (with-open-file (o path :direction :output :if-exists :append
                               :if-does-not-exist :create :external-format :utf-8)
          (write-string (jonathan:to-json
                         (list (cons "date" (format nil "~4,'0D-~2,'0D-~2,'0D" yr mo day))
                               (cons "kind" (string-downcase (symbol-name kind)))
                               (cons "subject" (princ-to-string subject))
                               (cons "detail" (princ-to-string detail)))
                         :from :alist) o)
          (terpri o))))))

(defun %lessons-aggregate ()
  "Το λεξικό συχνότητας των lessons: sorted λίστα (count kind subject),
   φθίνουσα. ΜΙΑ πηγή — τη μοιράζονται το --lessons ΚΑΙ ο αναστοχασμός του
   LAWMAX (run-reflect). Κανένας διπλός κώδικας."
  (let ((path (merge-pathnames "lessons.jsonl" (%state-dir)))
        (counts (make-hash-table :test 'equal)))
    (when (probe-file path)
      (with-open-file (in path :external-format :utf-8)
        (loop for line = (read-line in nil) while line
              do (handler-case
                     (let* ((r (jonathan:parse line :as :alist))
                            (kind (cdr (assoc "kind" r :test #'string=)))
                            (subject (cdr (assoc "subject" r :test #'string=))))
                       (incf (gethash (cons kind subject) counts 0)))
                   (error () nil)))))
    (let ((rows '()))
      (maphash (lambda (k v) (push (list v (car k) (cdr k)) rows)) counts)
      (sort rows #'> :key #'first))))

(defun run-lessons ()
  "--lessons : Ο ΑΝΑΣΤΟΧΑΣΜΟΣ — τα μοτίβα των αποτυχιών, ομαδοποιημένα. Ό,τι
   επαναλαμβάνεται είναι υποψήφιο για διόρθωση στην ρίζα: νέο δικαστήριο στο
   registry, νέος τερματιστής γραμματικής, endpoint που άλλαξε."
  (let ((rows (%lessons-aggregate)))
    (if (null rows)
        (progn
          (format t "~%Καμία καταγεγραμμένη αποτυχία — ή το σύστημα δεν έχει τρέξει αρκετά.~%")
          0)
        (progn
          (format t "~%── ΑΝΑΣΤΟΧΑΣΜΟΣ: ~D μοτίβα ──~%" (length rows))
          (dolist (row rows)
            (format t "  ~3D× ~A: ~A~[~:;  ← ΕΠΑΝΑΛΑΜΒΑΝΟΜΕΝΟ — διόρθωσε στην ρίζα~]~%"
                    (first row) (second row) (third row)
                    (if (>= (first row) 3) 1 0)))
          0))))

(defun %decision-intake ()
  "ΕΥΦΥΗΣ ΕΙΣΑΓΩΓΗ: κάθε αρχείο ΣΤΗ ΡΙΖΑ του input/decisions/ (όπως το
   κατέβασε ο χρήστης, με οποιοδήποτε όνομα) διαβάζεται, ΑΝΑΓΝΩΡΙΖΕΤΑΙ από το
   ίδιο του το κείμενο — δικαστήριο από το *COURT-REGISTRY*, ταυτότητα από το
   «Απόφαση/ΑΡΙΘΜΟΣ N/YYYY» — και αρχειοθετείται μόνο του στον σωστό φάκελο με
   το συμβατικό όνομα. Ό,τι ΔΕΝ κατανοεί το αναφέρει ρητά με τον λόγο:
   σαρωμένο χωρίς text layer (χρειάζεται OCR), άγνωστο δικαστήριο, ή μη
   ευρέσιμη ταυτότητα — ποτέ σιωπηλή απόρριψη, ποτέ μάντεμα."
  (let ((root (merge-pathnames "input/decisions/" (uiop:getcwd))))
    (dolist (f (uiop:directory-files root))
      (let ((type (string-downcase (or (pathname-type f) ""))))
        (when (member type '("pdf" "html" "txt") :test #'string=)
          (handler-case
              (%intake-one f type root)
            (error (e)
              (format t "  ✗ intake ~A: ~A~%" (file-namestring f) e)))))))
  (values))

(defun %intake-one (f type root)
  "Understand ONE freshly-dropped decision file and file it (see %DECISION-INTAKE)."
  (multiple-value-bind (text source)
      (if (string= type "pdf")
          (orchestrator.pdf-authority:extract-text-any f)
          (values (uiop:read-file-string f :external-format :utf-8) :text-layer))
    (when (eq source :ocr)
      (format t "  ◌ ~A: χωρίς text layer — διαβάστηκε με OCR (tesseract, ελληνικά)~%"
              (file-namestring f)))
    (when (< (length text) 600)
      (format t "  ⚠ ~A: σαρωμένο PDF (~D χαρακτήρες) και το OCR ~:[λείπει (tesseract+ell)~;δεν απέδωσε~] — παραμένει προς χειροκίνητη εξέταση~%"
              (file-namestring f) (length text)
              (orchestrator.pdf-authority:ocr-available-p))
      (%lesson :needs-ocr (file-namestring f) (length text))
      (return-from %intake-one))
    (let ((court (loop for (needle slug tag) in *court-registry*
                       when (search needle text) return (list slug tag))))
      (unless court
        (format t "  ⚠ ~A: δεν αναγνωρίζω το δικαστήριο — πρόσθεσέ το στο *COURT-REGISTRY* ή αρχειοθέτησε χειροκίνητα~%"
                (file-namestring f))
        (%lesson :unknown-court (file-namestring f) "δεν βρέθηκε στο *court-registry*")
        (return-from %intake-one))
      (multiple-value-bind (m g)
          (cl-ppcre:scan-to-strings
           "(?:ΑΡΙΘΜΟΣ|Αριθμός\\s+[Αα]πόφασης|Απόφαση)\\s+(\\d+)\\s*/\\s*(\\d{4})"
           text)
        ;; Δεύτερη πηγή ταυτότητας (δηλωμένη): το ΟΝΟΜΑ ΑΡΧΕΙΟΥ — π.χ.
        ;; «2202_2025_…». Στα σαρωμένα ο σφραγισμένος αριθμός συχνά δεν
        ;; διαβάζεται από το OCR, αλλά η ταυτότητα ζει στο όνομα (README).
        (unless m
          (multiple-value-bind (fm fg)
              (cl-ppcre:scan-to-strings "(\\d{1,5})[_ -](\\d{4})(?:\\D|$)"
                                        (file-namestring f))
            (when (and fm (<= 1900 (parse-integer (aref fg 1)) 2100))
              (setf m fm g fg)
              (format t "  ◌ ~A: ταυτότητα από το ΟΝΟΜΑ αρχείου (~A/~A) — στο κείμενο δεν διαβάστηκε~%"
                      (file-namestring f) (aref g 0) (aref g 1)))))
        (unless m
          (format t "  ⚠ ~A: δεν βρίσκω «Αριθμός απόφασης N/ΕΕΕΕ» ούτε στο κείμενο ούτε στο όνομα — αρχειοθέτησε χειροκίνητα~%"
                  (file-namestring f))
          (return-from %intake-one))
        (destructuring-bind (slug tag) court
          (let ((dest (merge-pathnames
                       (format nil "~A/~A_~A_~A.~A" slug tag (aref g 1) (aref g 0) type)
                       root)))
            (ensure-directories-exist dest)
            (rename-file f dest)
            (format t "  ✦ κατανόησα: ~A ~A/~A → ~A~%"
                    slug (aref g 0) (aref g 1) (enough-namestring dest root))))))))

(defun %decision-fetch-template (tag)
  "The url_template for court TAG from configs/decisions-sources.yaml —
   the endpoint lives in CONFIG (state sites change paths without notice;
   a fix is one line there, never a rebuild)."
  (handler-case
      (let* ((path (merge-pathnames "configs/decisions-sources.yaml" (uiop:getcwd)))
             (doc (cl-yaml:parse (uiop:read-file-string path :external-format :utf-8)))
             (courts (gethash "courts" doc))
             (entry (and courts (gethash tag courts))))
        (and entry (gethash "url_template" entry)))
    (error () nil)))

(defun run-fetch-decision (args)
  "--fetch-decision <tag> <έτος> <αριθμός>… : με ΡΗΤΗ εντολή του χρήστη,
   κατέβασε τις αποφάσεις από το επίσημο site (endpoint στο
   configs/decisions-sources.yaml), ρίξε τες ΩΣ ΕΧΟΥΝ στο input/decisions/
   και τρέξε το ευφυές intake — δηλαδή και το κατεβασμένο ΑΝΑΓΝΩΡΙΖΕΤΑΙ από
   το κείμενό του, δεν βαφτίζεται από το URL. Σε αποτυχία τυπώνεται η ακριβής
   curl εντολή για χειροκίνητο έλεγχο (τα κρατικά sites δέχονται συνήθως μόνο
   ελληνικές IP)."
  (destructuring-bind (&optional tag etos &rest arithmoi) args
    (unless (and tag etos arithmoi)
      (format t "χρήση: --fetch-decision <tag> <έτος> <αριθμός> [αριθμός…]  (π.χ. --fetch-decision ap 2023 1234 1301)~%")
      (return-from run-fetch-decision 1))
    (let ((template (%decision-fetch-template tag)))
      (unless template
        (format t "  ✗ άγνωστο δικαστήριο «~A» στο configs/decisions-sources.yaml~%" tag)
        (return-from run-fetch-decision 1))
      (let ((root (merge-pathnames "input/decisions/" (uiop:getcwd))) (ok 0))
        (dolist (num arithmoi)
          (let* ((url (cl-ppcre:regex-replace-all
                       "\\{arithmos\\}"
                       (cl-ppcre:regex-replace-all "\\{etos\\}" template etos)
                       num)))
            (multiple-value-bind (content status)
                (orchestrator.gov-source:fetch-url url)
              (cond
                ((and content (or (not (integerp status)) (< status 400))
                      (> (length content) 500))
                 (let ((dest (merge-pathnames
                              (format nil "fetched-~A-~A-~A.html" tag etos num) root)))
                   (ensure-directories-exist dest)
                   (with-open-file (o dest :direction :output :if-exists :supersede
                                          :if-does-not-exist :create
                                          :external-format :utf-8)
                     (write-string (if (stringp content) content
                                       (map 'string #'code-char content))
                                   o))
                   (incf ok)
                   (format t "  ↓ ~A/~A: ~D bytes → intake~%" num etos (length content))))
                (t
                 (format t "  ✗ ~A/~A: αποτυχία (status ~A). Δοκίμασε χειροκίνητα:~%      curl -o test.html \"~A\"~%"
                         num etos status url))))))
        (when (plusp ok) (%decision-intake))
        (format t "~%Κατέβηκαν ~D/~D — τρέξε --materialize-decisions για πλήρη ανάλυση.~%"
                ok (length arithmoi))
        0))))

;;; ============================================================================
;;; ΝΟΜΟΛΟΓΟΣ — ο φρουρός νομολογίας του Αρείου Πάγου
;;; ============================================================================
;;;
;;; Κάνει ΑΚΡΙΒΩΣ ό,τι ο δικηγόρος: αναζήτηση με κριτήρια (έτος/κατηγορία) →
;;; λίστα αποτελεσμάτων με links (που φέρνουν το session-bound cd) → άνοιγμα κάθε
;;; απόφασης → αποθήκευση ΩΣ ΕΧΕΙ → το υπάρχον intake την ΚΑΤΑΛΑΒΑΙΝΕΙ. Πραγματική
;;; συνεδρία (cookie-jar, browser UA, ανθρώπινος ρυθμός), windows-1253, keyed
;;; cursor ανά (κατηγορία,έτος). Οι καθαροί helpers (extract/params/absolute)
;;; δοκιμάζονται offline· το δίκτυο επαληθεύεται από ελληνική IP.

(defun %ap-config ()
  "Το 'ap' court entry (μαζί με το search block) από το decisions-sources.yaml."
  (handler-case
      (let* ((path (merge-pathnames "configs/decisions-sources.yaml" (uiop:getcwd)))
             (doc (cl-yaml:parse (uiop:read-file-string path :external-format :utf-8)))
             (courts (gethash "courts" doc)))
        (and courts (gethash "ap" courts)))
    (error () nil)))

(defparameter +ap-display-scanner+
  (cl-ppcre:create-scanner "apofaseis_DISPLAY\\.asp\\?[^\"'>< \\t\\r\\n]*"
                           :case-insensitive-mode t)
  "Matches a decision-view href on a results page (ASCII → encoding-independent).")

(defparameter +ap-result-scanner+
  (cl-ppcre:create-scanner "apofaseis_result\\.asp\\?[^\"'>< \\t\\r\\n]*"
                           :case-insensitive-mode t)
  "Matches a further-results href (pagination), same endpoint as the search POST.")

(defun %ap-extract-links (html)
  "Every distinct decision on a results page as (:number N :year Y :cd TOKEN
   :href H), sorted by number. Keys off the DISPLAY hrefs only (apof=<n>_<year>,
   cd=<token>), so it is robust to page layout. Deduped by (number,year)."
  (let ((seen (make-hash-table :test 'equal)) (out '()))
    (cl-ppcre:do-matches-as-strings (href +ap-display-scanner+ html)
      (multiple-value-bind (m g) (cl-ppcre:scan-to-strings "[?&]apof=(\\d+)_(\\d+)" href)
        (when m
          (let* ((num (parse-integer (aref g 0)))
                 (year (parse-integer (aref g 1)))
                 (k (cons num year)))
            (unless (gethash k seen)
              (setf (gethash k seen) t)
              (let ((cd (nth-value 1 (cl-ppcre:scan-to-strings "[?&]cd=([^&\"'> \\t]*)" href))))
                (push (list :number num :year year :cd (and cd (aref cd 0)) :href href) out)))))))
    (sort out #'< :key (lambda (p) (getf p :number)))))

(defun %ap-next-pages (html)
  "Distinct further-results hrefs on a results page (deduped, order preserved).
   Following the unseen ones covers both single-page and numbered pagination
   without hardcoding either scheme."
  (let ((seen (make-hash-table :test 'equal)) (out '()))
    (cl-ppcre:do-matches-as-strings (href +ap-result-scanner+ html)
      (unless (gethash href seen) (setf (gethash href seen) t) (push href out)))
    (nreverse out)))

(defun %url-ascii (url)
  "Percent-encode every non-ASCII char (UTF-8 bytes) so drakma can send the URL.
   ASCII (incl. already-%XX) passes through. Needed because a results page decoded
   as cp1253 yields hrefs with literal Greek (e.g. info=ΠΟΛΙΤΙΚΕΣ), and a URL must
   be ASCII on the wire."
  (with-output-to-string (o)
    (loop for ch across url
          for code = (char-code ch)
          do (if (< code #x80)
                 (write-char ch o)
                 (loop for b across (babel:string-to-octets (string ch) :encoding :utf-8)
                       do (format o "%~2,'0X" b))))))

(defun %ap-decision-text (html)
  "Καθαρό κείμενο ΑΠΟΦΑΣΗΣ από την σελίδα DISPLAY του ΑΠ: html→text (με δομή
   παραγράφων) και ΚΟΨΙΜΟ του chrome της σελίδας — κουμπιά AI-περίληψης,
   disclaimers, πλοήγηση — δηλαδή ο,τιδήποτε πριν την πρώτη γραμμή «Απόφαση
   N / ΕΕΕΕ» ή «Αριθμός N/ΕΕΕΕ». Αν το μοτίβο δεν βρεθεί (άγνωστη σελίδα),
   κρατάμε ΟΛΟ το κείμενο — ποτέ σιωπηλή απώλεια, το intake θα κρίνει."
  (let* ((text (orchestrator.gov-source:html->text html))
         (start (cl-ppcre:scan "(?:Απόφαση\\s+\\d+\\s*/\\s*\\d{4}|Αριθμός\\s+\\d+/\\d{4})" text)))
    (if start (subseq text start) text)))

(defun %ap-display-url (base cd number year)
  "Canonical, ASCII decision-view URL built from CD+APOF only — drops the cosmetic
   info= label (source of literal Greek), so it is robust and encoding-clean."
  (format nil "~Aapofaseis_DISPLAY.asp?cd=~A&apof=~A_~A"
          base (or cd "") number year))

(defun %ap-absolute (href base)
  "Resolve a possibly-relative results/DISPLAY HREF against the BASE search URL,
   then ASCII-encode it for the wire."
  (%url-ascii
   (if (cl-ppcre:scan "^https?://" href)
       href
       (let* ((q (or (position #\? base) (length base)))
              (slash (position #\/ base :from-end t :end q)))
         (if slash (concatenate 'string (subseq base 0 (1+ slash)) href) href)))))

(defun %ap-base-dir (url)
  "The directory part of URL (up to and including the last '/' before any '?')."
  (let* ((q (or (position #\? url) (length url)))
         (slash (position #\/ url :from-end t :end q)))
    (if slash (subseq url 0 (1+ slash)) url)))

(defun %ap-search-params (cfg &key (chamber "all") (sub "1") year number
                                    (year-op :eq) (number-op :ge))
  "Build the POST alist (field-name . value) for the AP search form from CFG's
   'search' block. YEAR/NUMBER are integers or NIL (omitted). Field names,
   operator codes and chamber codes all come from config — nothing hardcoded."
  (let* ((search (gethash "search" cfg))
         (fields (gethash "fields" search))
         (chambers (gethash "chambers" search))
         (cham (and chambers (gethash chamber chambers)))
         (params '()))
    (flet ((fld (k) (gethash k fields))
           (op (o) (gethash (ecase o (:eq "op_eq") (:ge "op_ge") (:le "op_le")) search))
           (add (name val) (when (and name val)
                             (push (cons name (princ-to-string val)) params))))
      (add (fld "chamber") (or cham "6"))
      (add (fld "sub_chamber") sub)
      (add (fld "year_op") (op year-op))
      (add (fld "year") year)
      (add (fld "number_op") (op number-op))
      (add (fld "number") number))
    (nreverse params)))

(defun %ap-jar ()
  (let ((f (find-symbol "MAKE-COOKIE-JAR" :drakma))) (and f (funcall f))))

(defun %ap-sweep (cfg chamber year &key from (pace 3) (max-pages 300) cursor-key limit)
  "One search sweep for (CHAMBER, YEAR): POST the search, follow pagination, and
   download every decision with number > FROM (NIL = all) through a shared
   cookie-jar (the cd token is session-bound), decoding windows-1253 and saving
   raw HTML to input/decisions/ for the intake. Human pace between downloads.
   Returns (values downloaded-list max-number-seen). Network step; per-item
   failures are reported, never fatal."
  (let* ((search (gethash "search" cfg))
         (url (gethash "url" search))
         ;; Η κωδικοποίηση ζει στο config (ο ΑΠ: cp1253)· το διαβάζουμε από εκεί
         ;; αντί να το hardcode-άρουμε — μία πηγή αλήθειας, όπως το endpoint.
         (enc (let ((e (gethash "encoding" cfg)))
                (if (and e (string-equal e "utf-8")) :utf-8 :cp1253)))
         (jar (%ap-jar))
         (root (merge-pathnames "input/decisions/" (uiop:getcwd)))
         (downloaded '()) (maxnum (or from 0))
         (visited (make-hash-table :test 'equal))
         (pages 0)
         (queue (list (list :url url :method :post
                            :params (%ap-search-params cfg :chamber chamber :year year
                                                           :year-op :eq
                                                           :number (and from (1+ from))
                                                           :number-op :ge)))))
    (ensure-directories-exist root)
    (loop while (and queue (< pages max-pages)) do
      (let* ((job (pop queue)) (jurl (getf job :url)))
        (unless (gethash jurl visited)
          (setf (gethash jurl visited) t)
          (incf pages)
          (multiple-value-bind (html status)
              (orchestrator.gov-source:fetch-url
               jurl :method (getf job :method) :parameters (getf job :params)
                    :encoding enc :cookie-jar jar)
            (if (and html (stringp html) (> (length html) 300))
                (progn
                  (dolist (h (%ap-next-pages html))
                    (let ((full (%ap-absolute h url)))
                      (unless (gethash full visited) (setf queue (append queue (list (list :url full)))))))
                  (dolist (lk (%ap-extract-links html))
                    ;; Δοκιμαστική δόση: με LIMIT σταματάμε εκεί — ο cursor έχει
                    ;; ήδη γραφτεί ανά κατέβασμα, η επόμενη εκτέλεση συνεχίζει.
                    (when (and limit (>= (length downloaded) limit))
                      (format t "  ⏸ όριο ~D — ο cursor δείχνει #~D, συνεχίζεις όποτε θες~%" limit maxnum)
                      (return-from %ap-sweep (values (nreverse downloaded) maxnum)))
                    (let ((num (getf lk :number)))
                      (when (or (null from) (> num from))
                        (let ((durl (%ap-display-url (%ap-base-dir url)
                                                     (getf lk :cd) num year)))
                          (multiple-value-bind (dhtml dstatus)
                              (orchestrator.gov-source:fetch-url durl :encoding enc :cookie-jar jar)
                            (if (and dhtml (stringp dhtml) (> (length dhtml) 300))
                                ;; Ο ΑΠ δεν έχει PDF: το κείμενο της απόφασης ΕΙΝΑΙ μέσα
                                ;; στην σελίδα. Το βγάζουμε καθαρό (σαν copy-paste) με το
                                ;; υπάρχον html->text — ίδιο κείμενο-σκέτο που παράγει και
                                ;; το PDF path, ώστε intake+materialize να το χειριστούν
                                ;; πανομοιότυπα. Σώζεται ως .txt.
                                (let ((text (%ap-decision-text dhtml))
                                      (dest (merge-pathnames (format nil "ap-~A-~A.txt" year num) root)))
                                  (with-open-file (o dest :direction :output :if-exists :supersede
                                                          :if-does-not-exist :create :external-format :utf-8)
                                    (write-string text o))
                                  (push (cons num year) downloaded)
                                  (setf maxnum (max maxnum num))
                                  ;; cursor ΑΝΑ κατέβασμα: μια διακοπή (Ctrl+C,
                                  ;; ρεύμα) δεν χάνει την πρόοδο — η επόμενη
                                  ;; εκτέλεση συνεχίζει από το επόμενο νούμερο.
                                  (when cursor-key (%write-cursor cursor-key maxnum))
                                  (format t "    ↓ ΑΠ ~A/~A (~D χαρακτ.)~%" num year (length text))
                                  (sleep (+ pace (random (1+ pace)))))
                                (progn (%lesson :fetch-failed (format nil "ΑΠ ~A/~A" num year) dstatus)
                                       (format t "    ✗ ΑΠ ~A/~A: ~A~%" num year dstatus))))))))
                  (when (zerop (length downloaded))
                    (format t "  · ~A ~A: 0 links στην σελίδα (raw ~D χαρακτ.)~%" chamber year (length html))))
                (format t "  ✗ search ~A ~A: ~A~%" chamber year status))))))
    (values (nreverse downloaded) maxnum)))

(defun run-fetch-year (args)
  "--fetch-year <έτος> [all|politikes|poinikes] : BACKFILL μιας χρονιάς από τον
   Άρειο Πάγο — κάθε απόφαση της χρονιάς (αναζήτηση→links→κατέβασμα), intake, και
   cursor ap:<κατηγορία>:<έτος>. Ανθρώπινος ρυθμός (AP_PACE δευτ., default 3).
   Τρέχει από ελληνική IP (τα κρατικά sites κόβουν ξένες)."
  (destructuring-bind (&optional year chamber limit) args
    (let ((y (and year (parse-integer year :junk-allowed t)))
          (ch (or chamber "all"))
          (lim (and limit (parse-integer limit :junk-allowed t)))
          (cfg (%ap-config)))
      (unless (and y cfg)
        (format t "χρήση: --fetch-year <έτος> [all|politikes|poinikes] [πλήθος]~%")
        (return-from run-fetch-year 1))
      (let* ((pace (or (ignore-errors (parse-integer (uiop:getenv "AP_PACE"))) 3))
             (key (format nil "ap:~A:~A" ch y))
             (from (%read-cursor key)))
        (format t "~%── ΝΟΜΟΛΟΓΟΣ backfill: Άρειος Πάγος «~A», έτος ~A~@[ (συνέχεια από #~A)~]~@[ · δόση ~D~] ──~%"
                ch y from lim)
        (multiple-value-bind (dl maxnum)
            (%ap-sweep cfg ch y :pace pace :from from :cursor-key key :limit lim)
          (declare (ignore maxnum))
          (when (plusp (length dl)) (%decision-intake))
          (format t "~%Κατέβηκαν ~D αποφάσεις ~A/~A → intake ✓. Τρέξε --materialize-decisions.~%"
                  (length dl) ch y)
          0)))))

(defun run-watch-decisions ()
  "--watch-decisions : ΝΟΜΟΛΟΓΟΣ «από εδώ και πέρα». Για το τρέχον έτος κατεβάζει
   ΜΟΝΟ τις νέες αποφάσεις (αριθμός > cursor) στις πολιτικές και ποινικές, τρέχει
   intake + materialize, προχωρά τον cursor. Ένας κύκλος — ιδανικό δίπλα στο
   --watch-fek στο Task Scheduler. Δόση ανά κατηγορία: AP_WATCH_LIMIT (default
   10) — ανθρώπινος ρυθμός· ο cursor εξασφαλίζει ότι ο επόμενος κύκλος
   συνεχίζει από εκεί που έμεινε."
  (let ((cfg (%ap-config))
        (pace (or (ignore-errors (parse-integer (uiop:getenv "AP_PACE"))) 3))
        (lim (or (ignore-errors (parse-integer (uiop:getenv "AP_WATCH_LIMIT"))) 10))
        (any 0))
    (unless cfg
      (format t "  ✗ λείπει το configs/decisions-sources.yaml~%")
      (return-from run-watch-decisions 1))
    (let ((y (parse-integer (%current-year-string))))
      (dolist (ch '("politikes" "poinikes"))
        (let* ((key (format nil "ap:~A:~A" ch y))
               (from (%read-cursor key)))
          (format t "~%── ΝΟΜΟΛΟΓΟΣ: ΑΠ «~A» ~A (από #~A, δόση ~D) ──~%" ch y (or from "αρχή") lim)
          (multiple-value-bind (dl maxnum)
              (%ap-sweep cfg ch y :from from :pace pace :cursor-key key :limit lim)
            (declare (ignore maxnum))
            (when (plusp (length dl)) (incf any (length dl)))
            (format t "  → ~D νέες~%" (length dl)))))
      (when (plusp any) (%decision-intake) (run-materialize-decisions))
      (format t "~%ΝΟΜΟΛΟΓΟΣ: ~D νέες αποφάσεις συνολικά.~%" any)
      0)))

(defun run-judge-profile (args)
  "--judge-profile [όνομα] : ΤΕΚΜΗΡΙΩΜΕΝΟ προφίλ δικαστή — ΜΟΝΟ ό,τι έχει
   ΕΦΑΡΜΟΣΕΙ/ΔΕΧΘΕΙ, με τις αποφάσεις-αποδείξεις. Σκοπός: να ΜΗΝ κάνει ο
   συνήγορος αποφευκτέο λάθος ενώπιον γνωστής σύνθεσης (π.χ. ένσταση που το
   τμήμα πάγια απορρίπτει). ΟΧΙ πρόβλεψη, ΟΧΙ ψυχολογικό προφίλ — τεκμήριο,
   όχι εικασία. Χωρίς όνομα: κατάλογος δικαστών κατά συμμετοχή."
  (let ((judges (make-hash-table :test 'equal)))
    (labels ((rec (name) (or (gethash name judges)
                             (setf (gethash name judges)
                                   (list :parts 0 :rapp 0 :chambers '() :evidence '())))))
      (dolist (dir (uiop:subdirectories (merge-pathnames "deployment/data/decisions/" (uiop:getcwd))))
        (dolist (f (uiop:directory-files dir))
          (when (and (string= (pathname-type f) "json") (not (search ".prov" (pathname-name f))))
            (handler-case
                (let* ((r (jonathan:parse (uiop:read-file-string f :external-format :utf-8) :as :alist))
                       (chamber (cdr (assoc "chamber" r :test #'string=)))
                       (ratio (cdr (assoc "ratio_evidence" r :test #'string=)))
                       (id (format nil "~A ~A/~A" (cdr (assoc "court" r :test #'string=))
                                   (cdr (assoc "number" r :test #'string=))
                                   (cdr (assoc "year" r :test #'string=))))
                       (stances (and (stringp ratio) (orchestrator.decisions:ratio-stance ratio))))
                  (dolist (j (cdr (assoc "judges" r :test #'string=)))
                    (let* ((name (cdr (assoc "name" j :test #'string=)))
                           (rapp (eq t (cdr (assoc "rapporteur" j :test #'string=))))
                           (e (rec name)))
                      (incf (getf e :parts))
                      (when (and chamber (stringp chamber))
                        (pushnew chamber (getf e :chambers) :test #'string=))
                      (when rapp
                        (incf (getf e :rapp))
                        ;; η θέση αποδίδεται στον ΕΙΣΗΓΗΤΗ — αυτός συντάσσει το σκεπτικό
                        (push (list :id id :chamber chamber :stances stances) (getf e :evidence))))))
              (error () nil))))))
    (let ((query (and args (format nil "~{~A~^ ~}" args))))
      (if (null query)
          ;; κατάλογος
          (let ((rows '()))
            (maphash (lambda (n e) (push (list n (getf e :parts) (getf e :rapp)) rows)) judges)
            (format t "~%── ΔΙΚΑΣΤΕΣ (~D· τεκμηριωμένα, από τις materialized αποφάσεις) ──~%" (hash-table-count judges))
            (dolist (row (sort rows #'> :key #'second))
              (format t "  ~3D συμμ.~[ ~:; ~:*~2D ως εισηγ.~] · ~A~%" (second row) (third row) (first row)))
            (format t "~%Δώσε όνομα: --judge-profile <επώνυμο>~%"))
          ;; προφίλ ενός
          (let (found)
            (maphash
             (lambda (name e)
               (when (search query name :test #'char-equal)
                 (setf found t)
                 (format t "~%── ~A ──~%  ~D συμμετοχές · ~D ως εισηγητής · τμήματα:~{ ~A~^,~}~%"
                         name (getf e :parts) (getf e :rapp)
                         (or (getf e :chambers) '("—")))
                 (when (getf e :evidence)
                   (format t "  ΩΣ ΕΙΣΗΓΗΤΗΣ (η θέση του σκεπτικού, με απόδειξη):~%")
                   (dolist (ev (getf e :evidence))
                     (format t "    • ~A~@[ [~A]~]~%" (getf ev :id) (getf ev :chamber))
                     (dolist (st (getf ev :stances))
                       (format t "        ~A ~@[~A ~]άρθρο ~A~%"
                               (case (getf st :stance) (:upholds "▲ δέχθηκε") (:rejects "▼ απέρριψε") (t "•"))
                               (getf st :tag) (getf st :article)))))
                 (format t "~%  (τεκμήριο, όχι πρόβλεψη — τι ΕΧΕΙ εφαρμόσει, ώστε να αποφύγεις αποφευκτέο λάθος)~%")))
             judges)
            (unless found (format t "~%Δεν βρέθηκε δικαστής «~A» στις materialized αποφάσεις.~%" query)))))
    0))

(defun run-index-decisions ()
  "--index-decisions : Η ΚΑΤ' ΑΡΘΡΟΝ ΝΟΜΟΛΟΓΙΑ — ο ανώτερος τρόπος ταξινόμησης.
   Όχι φάκελοι (μία ιεραρχία): ο γράφος. Κάθε απόφαση ταξινομείται ΑΥΤΟΜΑΤΑ
   κάτω από ΚΑΘΕ διάταξη που εφαρμόζει, με τμήμα, έτος, ετυμηγορία χρόνου και
   θέση (▲/▼) όπου υπάρχει. Γράφει deployment/data/decisions/kat-arthron.json
   — το ευρετήριο που απαντά «ποια νομολογία υπάρχει για το άρθρο Χ;» σε ένα
   βλέμμα, με τις αποφάσεις-αποδείξεις."
  (let ((index (make-hash-table :test 'equal)) (ndec 0))
    (dolist (dir (uiop:subdirectories (merge-pathnames "deployment/data/decisions/" (uiop:getcwd))))
      (dolist (f (uiop:directory-files dir))
        (when (and (string= (pathname-type f) "json")
                   (not (search ".prov" (pathname-name f))))
          (handler-case
              (let* ((rec (jonathan:parse (uiop:read-file-string f :external-format :utf-8) :as :alist))
                     (id (format nil "~A ~A/~A"
                                 (cdr (assoc "court" rec :test #'string=))
                                 (cdr (assoc "number" rec :test #'string=))
                                 (cdr (assoc "year" rec :test #'string=))))
                     (chamber (cdr (assoc "chamber" rec :test #'string=)))
                     (year (cdr (assoc "year" rec :test #'string=)))
                     (ratio (cdr (assoc "ratio_evidence" rec :test #'string=)))
                     (stances (and (stringp ratio) (orchestrator.decisions:ratio-stance ratio))))
                (incf ndec)
                (dolist (c (cdr (assoc "citations" rec :test #'string=)))
                  (let ((corpus (cdr (assoc "corpus" c :test #'string=)))
                        (art (cdr (assoc "article" c :test #'string=))))
                    (when corpus
                      (let* ((already (find id (gethash (list corpus art) index)
                                            :key (lambda (e) (cdr (assoc "decision" e :test #'string=)))
                                            :test #'equal))
                             (st (find-if (lambda (x) (equal (getf x :article) art)) stances))
                             (entry (append
                                     (list (cons "decision" id)
                                           (cons "year" year)
                                           (cons "chamber" (if (stringp chamber) chamber :null))
                                           (cons "tempus" (or (cdr (assoc "tempus_verdict" c :test #'string=)) :null)))
                                     (when st
                                       (list (cons "stance" (string-downcase (symbol-name (getf st :stance)))))))))
                        (unless already
                          (push entry (gethash (list corpus art) index))))))))
            (error () nil)))))
    (let ((keys (sort (loop for k being the hash-keys of index collect k)
                      (lambda (a b) (if (string= (first a) (first b))
                                        (< (or (parse-integer (second a) :junk-allowed t) 0)
                                           (or (parse-integer (second b) :junk-allowed t) 0))
                                        (string< (first a) (first b))))))
          (out (merge-pathnames "deployment/data/decisions/kat-arthron.json" (uiop:getcwd))))
      (with-open-file (o out :direction :output :if-exists :supersede
                             :if-does-not-exist :create :external-format :utf-8)
        (write-string
         (jonathan:to-json
          (loop for k in keys
                collect (list (cons "corpus" (first k))
                              (cons "article" (second k))
                              (cons "decisions" (reverse (gethash k index)))))
          :from :alist)
         o))
      (format t "~%── ΚΑΤ' ΑΡΘΡΟΝ ΝΟΜΟΛΟΓΙΑ: ~D αποφάσεις → ~D διατάξεις ──~%" ndec (length keys))
      (loop for k in keys
            for entries = (gethash k index)
            when (>= (length entries) 2)
            do (format t "  ~A άρθρο ~A — ~D αποφάσεις~%" (first k) (second k) (length entries)))
      (format t "~%✎ ~A~%" (enough-namestring out (uiop:getcwd))))
    0))

(defun run-jurisprudence ()
  "--jurisprudence : Ο ΧΑΡΤΗΣ ΤΩΝ ΘΕΣΕΩΝ — τι δέχεται κάθε σύνθεση, ανά διάταξη,
   από τα ratio ΟΛΩΝ των materialized αποφάσεων. Και το κρίσιμο: ΑΝΤΙΘΕΣΗ
   ΝΟΜΟΛΟΓΙΑΣ — ίδια διάταξη, αντίθετη φορά, διαφορετικές συνθέσεις — με τα
   δύο ratio ΔΙΠΛΑ-ΔΙΠΛΑ ως απόδειξη. Υποψήφια αντίθεση προς ΔΙΚΗ ΣΟΥ κρίση
   (το σύστημα δεν βαφτίζει σημασιολογική σύγκρουση ό,τι δεν αποδεικνύει)·
   αν έχει αποφανθεί Ολομέλεια για την διάταξη, σημειώνεται ως λελυμένη.
   ΕΠΙΠΛΕΟΝ, σε επίπεδο ΛΟΓΟΥ (π.χ. «ΚΠολΔ 559 αρ.19»): (α) ΤΕΚΜΗΡΙΟ ΕΚΒΑΣΗΣ
   — πόσες φορές ο λόγος έγινε δεκτός/αβάσιμος/απαράδεκτος (η έκβαση είναι
   κρίση επί περιστατικών, ΟΧΙ δόγμα — γι' αυτό είναι στατιστικό τεκμήριο,
   ποτέ «θέση»)· (β) ΜΕΙΖΟΝΕΣ ΣΚΕΨΕΙΣ αντικριστά — η πραγματική αντίθεση
   νομολογίας ζει στις μείζονες, όχι στις εκβάσεις, και η τελική σύγκριση
   ανήκει στον νομικό (το σύστημα παραθέτει, δεν βαφτίζει)."
  (let ((positions (make-hash-table :test 'equal)) (n 0)
        (outcomes (make-hash-table :test 'equal))   ; όχημα → κρίσεις επί λόγων
        (premises (make-hash-table :test 'equal))   ; όχημα → μείζονες σκέψεις
        (seen-oc (make-hash-table :test 'equal)))   ; ΜΙΑ ψήφος ανά (απόφαση, λόγο)
    (dolist (dir (uiop:subdirectories (merge-pathnames "deployment/data/decisions/" (uiop:getcwd))))
      (dolist (f (uiop:directory-files dir))
        (when (and (string= (pathname-type f) "json")
                   (not (search ".prov" (pathname-name f))))
          (handler-case
              (let* ((rec (jonathan:parse (uiop:read-file-string f :external-format :utf-8) :as :alist))
                     (ratio (cdr (assoc "ratio_evidence" rec :test #'string=)))
                     (chamber (cdr (assoc "chamber" rec :test #'string=)))
                     (id (format nil "~A ~A/~A"
                                 (cdr (assoc "court" rec :test #'string=))
                                 (cdr (assoc "number" rec :test #'string=))
                                 (cdr (assoc "year" rec :test #'string=)))))
                (when (and ratio (stringp ratio))
                  (incf n)
                  (dolist (pos (orchestrator.decisions:ratio-stance ratio))
                    ;; θέση χωρίς βέβαιο νομοθέτημα ΔΕΝ ομαδοποιείται — η
                    ;; ασάφεια δεν γίνεται ποτέ «θέση» στον χάρτη.
                    (when (getf pos :tag)
                      (push (list :id id :chamber (and (stringp chamber) chamber)
                                  :stance (getf pos :stance) :ratio ratio)
                            (gethash (list (getf pos :tag) (getf pos :article)) positions)))))
                ;; επίπεδο ΛΟΓΟΥ: κρίσεις και μείζονες, από την κατανόηση σε βάθος
                (dolist (gr (cdr (assoc "grounds" rec :test #'string=)))
                  (let ((vehicle (cdr (assoc "vehicle" gr :test #'string=)))
                        (kind (cdr (assoc "kind" gr :test #'string=)))
                        (verdict (cdr (assoc "verdict" gr :test #'string=)))
                        (excerpt (cdr (assoc "excerpt" gr :test #'string=))))
                    (when (stringp vehicle)
                      (cond ((equal kind "ruling")
                             ;; μία ψήφος ανά (απόφαση, λόγο) — πολλαπλές
                             ;; προτάσεις για τον ίδιο λόγο δεν πολλαπλασιάζουν
                             ;; το τεκμήριο· κρατιέται η ΠΡΩΤΗ (η κύρια κρίση)
                             (unless (gethash (list id vehicle) seen-oc)
                               (setf (gethash (list id vehicle) seen-oc) t)
                               (push (list :id id :chamber (and (stringp chamber) chamber)
                                           :verdict verdict)
                                     (gethash vehicle outcomes))))
                            ((equal kind "legal-premise")
                             (push (list :id id :chamber (and (stringp chamber) chamber)
                                         :excerpt excerpt)
                                   (gethash vehicle premises))))))))
            (error () nil)))))
    (format t "~%── ΧΑΡΤΗΣ ΝΟΜΟΛΟΓΙΑΚΩΝ ΘΕΣΕΩΝ (~D αποφάσεις με ratio) ──~%" n)
    (let ((conflicts 0))
      (maphash
       (lambda (key entries)
         (destructuring-bind (tag art) key
           (let* ((up (remove :rejects entries :key (lambda (e) (getf e :stance))))
                  (down (remove :upholds entries :key (lambda (e) (getf e :stance))))
                  (chambers (remove-duplicates (mapcar (lambda (e) (getf e :chamber)) entries)
                                               :test #'equal))
                  (olom (find-if (lambda (e) (search "Ολομέλεια" (or (getf e :chamber) "")))
                                 entries)))
             (when (> (length entries) 1)
               ;; ΠΑΓΙΑ ΝΟΜΟΛΟΓΙΑ — όχι «κανόνας» (η νομολογία δεν είναι τυπική
               ;; πηγή δικαίου στην Ελλάδα) αλλά το ισχυρότερο πραγματικό
               ;; επιχείρημα: ≥3 ομόρροπες κρίσεις σε ≥2 συνθέσεις, ΚΑΜΙΑ
               ;; αντίθετη. Σημαίνεται ⚖ — υποστήριξη με απόδειξη, ποτέ αξίωμα.
               (let ((pagia (and (>= (length entries) 3) (>= (length chambers) 2)
                                 (or (null up) (null down)))))
                 (format t "~%  ~@[~A ~]άρθρο ~A — ~D θέσεις σε ~D συνθέσεις~@[ ⚖ ΠΑΓΙΑ~]~%"
                         tag art (length entries) (length chambers) pagia))
               (dolist (e entries)
                 (format t "     ~A [~A] ~A~%"
                         (case (getf e :stance) (:upholds "▲ δέχεται") (:rejects "▼ απορρίπτει") (t "•"))
                         (or (getf e :chamber) "—") (getf e :id))))
             (when (and up down
                        ;; στα άρθρα-οχήματα (559/560/510) η «θέση» είναι έκβαση
                        ;; λόγου, όχι δόγμα — η αντίθεσή τους κρίνεται στις
                        ;; ΜΕΙΖΟΝΕΣ ΣΚΕΨΕΙΣ παρακάτω, ποτέ εδώ.
                        (not (member key '(("ΚΠολΔ" "559") ("ΚΠολΔ" "560") ("ΚΠΔ" "510"))
                                     :test #'equal))
                        (not (equal (remove-duplicates (mapcar (lambda (e) (getf e :chamber)) up) :test #'equal)
                                    (remove-duplicates (mapcar (lambda (e) (getf e :chamber)) down) :test #'equal))))
               (incf conflicts)
               (format t "   ⚡ ΥΠΟΨΗΦΙΑ ΑΝΤΙΘΕΣΗ ΝΟΜΟΛΟΓΙΑΣ~@[ — ~A~]~%" (and olom "έχει μιλήσει Ολομέλεια: κατά τεκμήριο ΛΕΛΥΜΕΝΗ"))
               (format t "      ▲ «~A»~%" (%normspace (subseq (getf (first up) :ratio) 0 (min 200 (length (getf (first up) :ratio))))))
               (format t "      ▼ «~A»~%" (%normspace (subseq (getf (first down) :ratio) 0 (min 200 (length (getf (first down) :ratio))))))))))
       positions)
      ;; ── ΤΕΚΜΗΡΙΑ ΕΚΒΑΣΗΣ ΑΝΑ ΛΟΓΟ — τι ποσοστό επιτυχίας έχει κάθε λόγος ──
      (let ((keys (sort (loop for k being the hash-keys of outcomes collect k) #'string<)))
        (when keys
          (format t "~%── ΤΕΚΜΗΡΙΑ ΕΚΒΑΣΗΣ ΑΝΑ ΛΟΓΟ ΑΝΑΙΡΕΣΕΩΣ (στατιστικό τεκμήριο, ΟΧΙ δόγμα) ──~%")
          (dolist (k keys)
            (let* ((es (gethash k outcomes))
                   (acc (count "accepted" es :key (lambda (e) (getf e :verdict)) :test #'equal))
                   (unf (count "unfounded" es :key (lambda (e) (getf e :verdict)) :test #'equal))
                   (inad (count "inadmissible" es :key (lambda (e) (getf e :verdict)) :test #'equal)))
              (when (>= (length es) 2)
                (format t "  ~A — ~D κρίσεις: ✓~D δεκτοί · ⨯~D αβάσιμοι · ∅~D απαράδεκτοι~@[ (~D% επιτυχία)~]~%"
                        k (length es) acc unf inad
                        (and (plusp (length es)) (round (* 100 acc) (length es))))
                (dolist (e (subseq es 0 (min 3 (length es))))
                  (format t "     ~A [~A] ~A~%"
                          (cond ((equal (getf e :verdict) "accepted") "✓")
                                ((equal (getf e :verdict) "inadmissible") "∅") (t "⨯"))
                          (or (getf e :chamber) "—") (getf e :id))))))))
      ;; ── ΜΕΙΖΟΝΕΣ ΣΚΕΨΕΙΣ ΑΝΤΙΚΡΙΣΤΑ — εδώ ζει η πραγματική αντίθεση ──
      (let ((shown 0))
        (maphash
         (lambda (k es)
           (let ((chambers (remove-duplicates (mapcar (lambda (e) (getf e :chamber)) es)
                                              :test #'equal)))
             (when (>= (length chambers) 2)
               (when (zerop shown)
                 (format t "~%── ΜΕΙΖΟΝΕΣ ΣΚΕΨΕΙΣ ΑΝΤΙΚΡΙΣΤΑ (ίδιος λόγος, ≥2 συνθέσεις — προς ΔΙΚΗ ΣΟΥ κρίση) ──~%"))
               (incf shown)
               (format t "~%  ~A:~%" k)
               ;; ΜΙΑ μείζων ανά σύνθεση — το boilerplate του ίδιου τμήματος
               ;; επαναλαμβάνεται λέξη-λέξη· αξία έχει η ΔΙΑΣΤΑΥΡΩΣΗ συνθέσεων
               (let ((per-chamber '()))
                 (dolist (e es)
                   (unless (assoc (getf e :chamber) per-chamber :test #'equal)
                     (push (cons (getf e :chamber) e) per-chamber)))
                 (dolist (ce (nreverse per-chamber))
                   (let ((ex (getf (cdr ce) :excerpt)))
                     (format t "   ⚖ [~A ~A] «~A…»~%"
                             (or (car ce) "—") (getf (cdr ce) :id)
                             (subseq ex 0 (min 150 (length ex))))))))))
         premises)
        (when (plusp shown)
          (format t "~%  (η σύγκριση των μειζόνων είναι νομική κρίση — το σύστημα παραθέτει με απόδειξη, δεν βαφτίζει αντίθεση)~%")))
      (format t "~%Σύνολο: ~D υποψήφιες αντιθέσεις επί ουσιαστικών διατάξεων.~%" conflicts))
    0))

(defun %understanding-scan (&optional (record-lessons nil))
  "Η ΜΕΤΡΗΣΗ της πληρότητας κατανόησης, ΧΩΡΙΣ εκτύπωση — μία πηγή αλήθειας
   για τον --understanding έλεγχο ΚΑΙ για την αποστολή του συντάγματος.
   Επιστρέφει (values perfect total gaps-hash). RECORD-LESSONS: αν t,
   κάθε κενό γράφεται στην μνήμη αναστοχασμού."
  (let ((total 0) (perfect 0) (gaps (make-hash-table :test 'equal)))
    (dolist (dir (uiop:subdirectories (merge-pathnames "deployment/data/decisions/" (uiop:getcwd))))
      (dolist (f (uiop:directory-files dir))
        (when (and (string= (pathname-type f) "json")
                   (not (search ".prov" (pathname-name f))))
          (handler-case
              (let* ((rec (jonathan:parse (uiop:read-file-string f :external-format :utf-8) :as :alist))
                     (id (format nil "~A ~A/~A"
                                 (cdr (assoc "court" rec :test #'string=))
                                 (cdr (assoc "number" rec :test #'string=))
                                 (cdr (assoc "year" rec :test #'string=))))
                     (get (lambda (k) (let ((v (cdr (assoc k rec :test #'string=))))
                                        (and v (not (eq v :null))
                                             (or (not (listp v)) (plusp (length v))) v))))
                     (court-name (cdr (assoc "court" rec :test #'string=)))
                     (ap-p (and (stringp court-name) (search "areios" court-name)))
                     (operative (funcall get "operative"))
                     (substantive-p
                       (and operative
                            (some (lambda (v)
                                    (some (lambda (stem) (search stem v))
                                          '("Απορρ" "Αναιρ" "Δεχ" "Επιβαλ" "Καταδικ" "Εξαφαν")))
                                  operative)))
                     (missing '()))
                (incf total)
                (unless (funcall get "judges")    (push "σύνθεση" missing))
                (when ap-p
                  (unless (funcall get "chamber") (push "τμήμα" missing)))
                (unless (>= (length (or (funcall get "structure") '())) (if ap-p 4 3))
                  (push "ανατομία" missing))
                (when (and ap-p substantive-p)
                  (unless (funcall get "grounds") (push "λόγοι" missing))
                  (unless (funcall get "ratio_evidence") (push "ratio" missing)))
                (unless (funcall get "operative") (push "διατακτικό" missing))
                (unless (funcall get "citations") (push "παραπομπές" missing))
                (if missing
                    (progn
                      (push (cons id (nreverse missing)) (gethash (first missing) gaps))
                      (when record-lessons
                        (%lesson :understanding-gap id (format nil "~{~A~^, ~}" missing))))
                    (incf perfect)))
            (error () nil)))))
    (values perfect total gaps)))

(defun run-understanding ()
  "--understanding : Ο ΕΛΕΓΧΟΣ ΠΛΗΡΟΤΗΤΑΣ ΚΑΤΑΝΟΗΣΗΣ — η εγγύηση ως μέτρηση.
   Για ΚΑΘΕ materialized απόφαση: ποια συστατικά κατανόησης υπάρχουν
   (σύνθεση, τμήμα, ανατομία, λόγοι με κρίση, ratio, διατακτικό, παραπομπές)
   και ποια λείπουν — ΟΝΟΜΑΣΤΙΚΑ. Κάθε κενό γράφεται στην μνήμη αναστοχασμού
   ώστε η γραμματική να επεκταθεί στοχευμένα. Στόχος: 100% πριν φορτωθούν
   νέες αποφάσεις — το «1/1» ως αποδείξιμη ιδιότητα, όχι ως υπόσχεση."
  (orchestrator.knowledge-packs:ensure-fresh)
  (multiple-value-bind (perfect total gaps) (%understanding-scan t)
    (format t "~%── ΠΛΗΡΟΤΗΤΑ ΚΑΤΑΝΟΗΣΗΣ: ~D/~D αποφάσεις πλήρεις (~D%) ──~%"
            perfect total (if (plusp total) (round (* 100 perfect) total) 0))
    (let ((any nil))
      (maphash (lambda (component entries)
                 (setf any t)
                 (format t "~%  κενό «~A» σε ~D αποφάσεις:~%" component (length entries))
                 (dolist (e (subseq entries 0 (min 8 (length entries))))
                   (format t "    • ~A — λείπουν: ~{~A~^, ~}~%" (car e) (cdr e)))
                 (when (> (length entries) 8)
                   (format t "    … και ~D ακόμη~%" (- (length entries) 8))))
               gaps)
      (unless any
        (format t "~%  ✓ Κάθε απόφαση έχει ΟΛΑ τα συστατικά κατανόησης — το «1/1» ισχύει αποδείξιμα.~%")))
    (format t "~%(κάθε κενό καταγράφηκε στην μνήμη αναστοχασμού — δες --lessons)~%")
    (if (= perfect total) 0 1)))

(defun run-reason-decision (args)
  "--reason-decision <court> <αριθμός> <έτος>: φόρτωσε τη materialized απόφαση
   στον JTMS και τύπωσε τις ετυμηγορίες δεδικασμένου ΜΕ ΤΑ ΔΕΝΤΡΑ ΑΠΟΔΕΙΞΗΣ —
   defeasible: μελλοντικό γεγονός επιβεβαίωσης επί του νέου κειμένου αποσύρει
   μόνο του την προειδοποίηση (truth maintenance)."
  (destructuring-bind (&optional court num year) args
    (unless (and court num year)
      (format t "χρήση: --reason-decision <court> <αριθμός> <έτος>~%")
      (return-from run-reason-decision 1))
    (let* ((path (merge-pathnames
                  (format nil "deployment/data/decisions/~A/" court) (uiop:getcwd)))
           (file (find-if (lambda (f)
                            (search (format nil "_~A_~A" year num) (pathname-name f)))
                          (uiop:directory-files path))))
      (unless file
        (format t "  ✗ δεν βρέθηκε materialized απόφαση ~A ~A/~A — τρέξε --materialize-decisions~%"
                court num year)
        (return-from run-reason-decision 1))
      (let* ((rec (jonathan:parse (uiop:read-file-string file :external-format :utf-8)
                                  :as :alist))
             (penal (eq t (cdr (assoc "penal" rec :test #'string=))))
             (cits (loop for c in (cdr (assoc "citations" rec :test #'string=))
                         for corpus = (cdr (assoc "corpus" c :test #'string=))
                         for verdict = (cdr (assoc "tempus_verdict" c :test #'string=))
                         for av = (cdr (assoc "act_verdict" c :test #'string=))
                         when corpus
                         collect (list :corpus corpus
                                       :article (cdr (assoc "article" c :test #'string=))
                                       :penal penal
                                       :verdict (cond ((equal verdict "amended-after") :amended-after)
                                                      ((equal verdict "same-text-proven") :same-text-proven)
                                                      (t :unknown))
                                       :act-verdict
                                       (cond ((equal av "lex-mitior-check") :lex-mitior-check)
                                             ((equal av "amended-since-act") :amended-since-act)
                                             ((equal av "same-since-act") :same-since-act)
                                             (t :unknown)))))
             (id (format nil "~A-~A/~A" court num year)))
        (orchestrator.precedent:precedent-report id cits)
        0))))

(defun run-explain-decision (args)
  "--explain-decision <court> <αριθμός> <έτος>: Η ΕΞΗΓΗΣΗ της απόφασης — η
   κατανόηση σε βάθος, αφηγημένη: ποιοι δίκασαν, ποια η διαδρομή, ΚΑΘΕ λόγος
   αναιρέσεως με την τύχη του και την πρόταση-απόδειξη, το ratio, το
   διατακτικό, οι εφαρμοσθείσες διατάξεις και η χρονική τους αγκύρωση.
   Ό,τι το σύστημα ΔΕΝ κατάλαβε δηλώνεται ρητά και γράφεται στην μνήμη
   αναστοχασμού — τίμια άγνοια, ποτέ σιωπηλό κενό."
  (orchestrator.knowledge-packs:ensure-fresh)
  (destructuring-bind (&optional court num year) args
    (unless (and court num year)
      (format t "χρήση: --explain-decision <court> <αριθμός> <έτος>~%")
      (return-from run-explain-decision 1))
    (let* ((path (merge-pathnames
                  (format nil "deployment/data/decisions/~A/" court) (uiop:getcwd)))
           (file (find-if (lambda (f)
                            (and (string= (pathname-type f) "json")
                                 (not (search ".prov" (pathname-name f)))
                                 (search (format nil "_~A_~A" year num) (pathname-name f))))
                          (uiop:directory-files path))))
      (unless file
        (format t "  ✗ δεν βρέθηκε materialized απόφαση ~A ~A/~A — τρέξε --materialize-decisions~%"
                court num year)
        (return-from run-explain-decision 1))
      (let* ((rec (jonathan:parse (uiop:read-file-string file :external-format :utf-8) :as :alist))
             (get (lambda (k) (let ((v (cdr (assoc k rec :test #'string=))))
                                (and (not (eq v :null)) v)))))
        (format t "~%═══ ΕΞΗΓΗΣΗ: ~A ~A/~A~@[ — ~A~] ═══~%"
                court num year (funcall get "chamber"))
        ;; 1. Ποιοι δίκασαν
        (let ((judges (funcall get "judges")))
          (if judges
              (let ((rapp (find-if (lambda (j) (eq t (cdr (assoc "rapporteur" j :test #'string=)))) judges)))
                (format t "~%• ΣΥΝΘΕΣΗ (~D): ~A~@[ · εισηγητής: ~A~]~%"
                        (length judges)
                        (format nil "~{~A~^, ~}"
                                (loop for j in (subseq judges 0 (min 5 (length judges)))
                                      collect (format nil "~A (~A)"
                                                      (cdr (assoc "name" j :test #'string=))
                                                      (cdr (assoc "role" j :test #'string=)))))
                        (and rapp (cdr (assoc "name" rapp :test #'string=))))
                (when (> (length judges) 5)
                  (format t "  … και ~D ακόμη μέλη~%" (- (length judges) 5))))
              (progn (format t "~%• ΣΥΝΘΕΣΗ: ΔΕΝ αναγνωρίστηκε — άγνωστη μορφή, καταγράφεται~%")
                     (%lesson :composition-not-understood
                              (format nil "~A ~A/~A" court num year) "0 δικαστές"))))
        ;; 2. Η διαδρομή (ανατομία)
        (let ((secs (funcall get "structure")))
          (when secs
            (format t "~%• ΑΝΑΤΟΜΙΑ: ~{~A~^ → ~}~%"
                    (loop for s in secs
                          collect (let ((name (cdr (assoc "section" s :test #'string=))))
                                    (cond ((equal name "header") "προμετωπίδα")
                                          ((equal name "parties") "διάδικοι")
                                          ((equal name "history") "ιστορικό δίκης")
                                          ((equal name "reasoning") "σκεπτικό")
                                          ((equal name "operative") "διατακτικό")
                                          (t name)))))))
        ;; 3. Η πράξη (ποινικά)
        (let ((ad (funcall get "act_date")))
          (when ad
            (format t "~%• Η ΠΡΑΞΗ: τελέσθηκε ~A~@[ (απόδειξη: «~A»)~]~%"
                    ad (funcall get "act_date_evidence"))))
        ;; 4. ΟΙ ΛΟΓΟΙ ΚΑΙ Η ΤΥΧΗ ΤΟΥΣ — η καρδιά της εξήγησης, στις τρεις
        ;; φωνές της απόφασης: η τύχη της ΑΙΤΗΣΗΣ, η ΜΕΙΖΩΝ νομική σκέψη
        ;; (θεωρία με παραπομπές), και οι ΚΡΙΣΕΙΣ επί των λόγων της υπόθεσης.
        (let ((grounds (funcall get "grounds")))
          (if grounds
              (flet ((of-kind (k) (remove k grounds :test-not #'equal
                                          :key (lambda (g) (cdr (assoc "kind" g :test #'string=)))))
                     (field (g k) (let ((v (cdr (assoc k g :test #'string=))))
                                    (and (not (eq v :null)) v)))
                     (glyph (v) (cond ((equal v "accepted")     "✓ ΔΕΚΤΟΣ")
                                      ((equal v "unfounded")    "⨯ αβάσιμος")
                                      ((equal v "inadmissible") "∅ απαράδεκτος")
                                      (t v))))
                (let ((petition (of-kind "petition"))
                      (premises (of-kind "legal-premise"))
                      (rulings  (of-kind "ruling")))
                  (dolist (p petition)
                    (format t "~%• Η ΑΙΤΗΣΗ: ~A~%  «~A»~%"
                            (let ((v (cdr (assoc "verdict" p :test #'string=))))
                              (cond ((equal v "accepted") "παραδεκτή — ερευνώνται οι λόγοι")
                                    ((equal v "unfounded") "ΑΠΟΡΡΙΠΤΕΤΑΙ")
                                    ((equal v "inadmissible") "ΑΠΑΡΑΔΕΚΤΗ")
                                    (t v)))
                            (field p "excerpt")))
                  (when premises
                    (format t "~%• ΝΟΜΙΚΗ ΣΚΕΨΗ (~D μείζονες προτάσεις — η θεωρία που εφαρμόζει):~%"
                            (length premises))
                    (dolist (p premises)
                      (let ((ex (field p "excerpt")))
                        (format t "  ⚖ ~@[[~A] ~]«~A…»~%" (field p "vehicle")
                                (subseq ex 0 (min 140 (length ex)))))))
                  (when rulings
                    (format t "~%• ΚΡΙΣΕΙΣ ΕΠΙ ΤΩΝ ΛΟΓΩΝ ΤΗΣ ΥΠΟΘΕΣΗΣ (~D):~%" (length rulings))
                    (loop for gr in rulings for i from 1 do
                      (format t "~%  ~D. ~@[~Dος λόγος · ~]~@[όχημα ~A · ~]~A~%     «~A»~%"
                              i (field gr "ordinal") (field gr "vehicle")
                              (glyph (cdr (assoc "verdict" gr :test #'string=)))
                              (field gr "excerpt"))))))
              (progn
                (format t "~%• ΛΟΓΟΙ: κανένας δεν αναγνωρίστηκε — ")
                (format t "αν η απόφαση έχει λόγους, η γραμματική χρειάζεται επέκταση (καταγράφεται)~%")
                (%lesson :grounds-not-understood
                         (format nil "~A ~A/~A" court num year) "0 λόγοι"))))
        ;; 5. Ratio
        (let ((ratio (funcall get "ratio_evidence")))
          (when ratio
            (format t "~%• RATIO (η πρόταση-γέφυρα, verbatim):~%  «~A»~%" ratio)))
        ;; 6. Διατακτικό
        (let ((op (funcall get "operative")))
          (when op (format t "~%• ΔΙΑΤΑΚΤΙΚΟ: ~{~A~^ · ~}~%" op)))
        ;; 7. Διατάξεις + χρονική αγκύρωση
        (let* ((cits (funcall get "citations"))
               (amended (count "amended-after" cits
                               :key (lambda (c) (cdr (assoc "tempus_verdict" c :test #'string=)))
                               :test #'equal)))
          (format t "~%• ΕΦΑΡΜΟΖΕΙ ~D διατάξεις~@[ — ⚠ ~D τροποποιήθηκαν ΜΕΤΑ την απόφαση (βλ. --reason-decision)~]~%"
                  (length cits) (and (plusp amended) amended)))
        (format t "~%(κάθε στοιχείο προέρχεται από το ίδιο το κείμενο — offsets στο ~A)~%"
                (enough-namestring file (uiop:getcwd)))
        0))))

(defun run-materialize-decisions ()
  "Parse every decision under input/decisions/<court>/ (filename convention
   <tag>_<year>_<number>.<ext>) into structured JSON at
   deployment/data/decisions/<court>/, provenance-stamped. Each citation whose
   law tag is one of the six served codes gets a tempus-regit-actum verdict
   against that article's per-article version date."
  (format t "~%Υλικοποίηση αποφάσεων → δομημένο JSON (σύνθεση, παραπομπές, χρονική ταύτιση)...~%")
  (%decision-intake)
  (let ((n 0) (date-cache (make-hash-table :test 'equal))
        (new-citations '()))   ; η ΝΕΑ πραγματικότητα — τροφοδοτεί την προθετική μνήμη
    (labels ((dates-for (corpus)
               (multiple-value-bind (v hit) (gethash corpus date-cache)
                 (if hit v (setf (gethash corpus date-cache)
                                 (%served-article-dates corpus))))))
      (dolist (dir (uiop:subdirectories (merge-pathnames "input/decisions/"
                                                         (uiop:getcwd))))
        (let ((court (car (last (pathname-directory dir)))))
          (dolist (f (uiop:directory-files dir))
            (let ((type (string-downcase (or (pathname-type f) ""))))
              (when (member type '("pdf" "html" "txt") :test #'string=)
                (handler-case
                    (multiple-value-bind (m g)
                        (cl-ppcre:scan-to-strings "^[a-z]+_(\\d{4})_(\\d+)$"
                                                  (pathname-name f))
                      (unless m
                        (error "όνομα εκτός σύμβασης <tag>_<έτος>_<αριθμός>: ~A"
                               (pathname-name f)))
                      (let* ((year (parse-integer (aref g 0)))
                             (num (parse-integer (aref g 1)))
                             (text (if (string= type "pdf")
                                       (orchestrator.pdf-authority:extract-text-any f)
                                       (uiop:read-file-string f :external-format :utf-8)))
                             (d (orchestrator.decisions:parse-decision-text
                                 text :court court :number num :year year
                                      :source-file (namestring f)))
                             (out-dir (merge-pathnames
                                       (format nil "deployment/data/decisions/~A/" court)
                                       (uiop:getcwd)))
                             (out (merge-pathnames
                                   (format nil "~A.json" (pathname-name f)) out-dir))
                             (flags 0) (mitior 0)
                             (penal (orchestrator.decisions:penal-decision-p d))
                             (act-date nil) (act-evidence nil))
                        (multiple-value-setq (act-date act-evidence)
                          (orchestrator.decisions:parse-act-date text year))
                        (progn
                          (ensure-directories-exist out)
                          (with-open-file (o out :direction :output :if-exists :supersede
                                                 :if-does-not-exist :create
                                                 :external-format :utf-8)
                            (write-string
                             (jonathan:to-json
                              (append
                               (orchestrator.decisions:decision->json-alist
                                d
                                :citation-status
                                (lambda (c)
                                  (let* ((tag (orchestrator.decisions:citation-law-tag c))
                                         (corpus (cdr (assoc tag
                                                             orchestrator.decisions:+law-tag-corpus-map+
                                                             :test #'equal))))
                                    (when corpus
                                      (push (format nil "~A:~A" corpus
                                                    (orchestrator.decisions:citation-article c))
                                            new-citations)
                                      (let* ((dates (dates-for corpus))
                                             (adate (and dates
                                                         (gethash (orchestrator.decisions:citation-article c)
                                                                  dates)))
                                             (v (%tempus-verdict adate year))
                                             (av (%act-verdict adate act-date year penal)))
                                        (when (eq v :amended-after) (incf flags))
                                        (when (eq av :lex-mitior-check) (incf mitior))
                                        (append
                                         (list (cons "corpus" corpus)
                                               (cons "article_exists" (if adate t :false))
                                               (cons "article_date" (or adate :null))
                                               (cons "tempus_verdict"
                                                     (string-downcase (symbol-name v))))
                                         (when av
                                           (list (cons "act_verdict"
                                                       (string-downcase (symbol-name av)))))))))))
                               ;; Χρονική αγκύρωση στον άξονα της ΠΡΑΞΗΣ — με το
                               ;; τεκμήριο από το ίδιο το κείμενο (ποτέ μάντεμα).
                               (list (cons "penal" (if penal t :false))
                                     (cons "act_date" (or act-date :null))
                                     (cons "act_date_evidence" (or act-evidence :null))))
                              :from :alist)
                             o)))
                        (%write-source-provenance
                         (namestring out)
                         :source-digest (%sha256-file (namestring f))
                         :extraction-method "decision-adapter@1"
                         :date (princ-to-string year))
                        (incf n)
                        (format t "  ✓ ~A ~A/~A: ~D δικαστές~@[ (εισηγητής: ~A)~], ~D παραπομπές~[~:;, ⚠ ~:*~D ΜΕΤΑ την απόφαση~]~[~:;, ⚖ ~:*~D lex mitior~]~%"
                                court num year
                                (length (orchestrator.decisions:decision-judges d))
                                (let ((r (find-if #'orchestrator.decisions:judge-rapporteur-p
                                                  (orchestrator.decisions:decision-judges d))))
                                  (and r (orchestrator.decisions:judge-name r)))
                                (length (orchestrator.decisions:decision-citations d))
                                flags mitior)
                        ;; ΟΙ ΝΟΜΟΙ, ορατοί: ποιες διατάξεις εφάρμοσε η απόφαση,
                        ;; δεμένες στους κώδικες — όχι κρυμμένες στο JSON.
                        (let ((bound (loop for c in (orchestrator.decisions:decision-citations d)
                                           for tag = (orchestrator.decisions:citation-law-tag c)
                                           when tag
                                           collect (format nil "~A ~A~@[§~A~]"
                                                           tag
                                                           (orchestrator.decisions:citation-article c)
                                                           (orchestrator.decisions:citation-paragraph c)))))
                          (when bound
                            (format t "      § εφαρμόζει:~{ ~A~^ ·~}~%"
                                    (remove-duplicates bound :test #'string= :from-end t))))))
                  (error (e) (format t "  ✗ ~A: ~A~%" (pathname-name f) e))))))))
      (format t "~%Υλικοποιήθηκαν ~D αποφάσεις.~%" n)
      ;; ΠΡΟΘΕΤΙΚΗ ΜΝΗΜΗ: η νέα πραγματικότητα ελέγχει τις οπλισμένες προθέσεις —
      ;; «όταν έρθει απόφαση που εφαρμόζει το Χ, κάνε Υ» πυροδοτείται ΕΔΩ, στο
      ;; σημείο εισόδου της, όχι σε χειροκίνητη εντολή.
      (when (plusp n)
        (let ((fired (orchestrator.memory:fire-due-intentions
                      (list :new-citations (remove-duplicates new-citations :test #'string=)))))
          (dolist (int fired)
            (format t "  ⚡ ΠΡΟΘΕΣΗ ΠΥΡΟΔΟΤΗΘΗΚΕ [~A]: ~A~%"
                    (orchestrator.memory:episode-id int)
                    (orchestrator.memory:episode-text int)))))
      0)))


;;; ----------------------------------------------------------------------------
;;; ΕΓΓΡΑΦΗ ΣΤΟ ΜΗΤΡΩΟ — οι εντολές νομολογίας, χωρίς κανένα άγγιγμα στο main
;;; ----------------------------------------------------------------------------

(register-command "--fetch-decision"       (lambda (a) (run-fetch-decision a)))
(register-command "--materialize-decisions" (lambda (a) (declare (ignore a)) (run-materialize-decisions)))
;;; ----------------------------------------------------------------------------
;;; Η ΓΝΩΣΗ ΥΠΟ ΤΟ ΚΑΘΕΣΤΩΣ ΤΟΥ ΝΟΜΟΥ — είδη, σκιά, υιοθέτηση
;;; ----------------------------------------------------------------------------
;;;
;;; Εδώ οι καταναλωτές δηλώνουν ΠΩΣ εγκαθίσταται κάθε είδος γνώσης, και η
;;; CLI αποκτά την πύλη: --shadow-knowledge αποδεικνύει ΜΗ-ΠΑΛΙΝΔΡΟΜΗΣΗ
;;; υποψήφιας γνώσης πάνω σε ΟΛΟ το σώμα αποφάσεων πριν από κάθε υιοθέτηση
;;; (--adopt-knowledge). Το «0 λάθος» ως μηχανικός φραγμός.

(orchestrator.knowledge-packs:define-knowledge-kind :decision-grammar
 :doc "Επεκτάσεις της γραμματικής κατανόησης αποφάσεων: (:ratio-opener s)
 (:ratio-verdict s) (:operative-verb s) (:narration-verb s)
 (:judged-subject stem :ground|:petition|:narration)."
 :install
 (lambda (entries)
   (dolist (e entries)
     (destructuring-bind (key &rest args) e
       (ecase key
         (:ratio-opener
          (pushnew (first args) orchestrator.decisions:*ratio-openers* :test #'equal))
         (:ratio-verdict
          (pushnew (first args) orchestrator.decisions:*ratio-verdict-words* :test #'equal))
         (:operative-verb
          (pushnew (first args) orchestrator.decisions:*operative-verb-words* :test #'equal))
         (:narration-verb
          (pushnew (first args) orchestrator.decisions:*narration-verb-words* :test #'equal))
         (:judged-subject
          (pushnew (cons (first args) (second args))
                   orchestrator.decisions:*judged-subjects* :test #'equal)))))
   (orchestrator.decisions:rebuild-decision-scanners))
 :snapshot
 (lambda ()
   (list (copy-list orchestrator.decisions:*ratio-openers*)
         (copy-list orchestrator.decisions:*ratio-verdict-words*)
         (copy-list orchestrator.decisions:*operative-verb-words*)
         (copy-list orchestrator.decisions:*narration-verb-words*)
         (copy-alist orchestrator.decisions:*judged-subjects*)))
 :restore
 (lambda (st)
   (destructuring-bind (ro rv ov nv js) st
     (setf orchestrator.decisions:*ratio-openers* ro
           orchestrator.decisions:*ratio-verdict-words* rv
           orchestrator.decisions:*operative-verb-words* ov
           orchestrator.decisions:*narration-verb-words* nv
           orchestrator.decisions:*judged-subjects* js))
   (orchestrator.decisions:rebuild-decision-scanners)))

(defun %understanding-signature (text)
  "Η ΥΠΟΓΡΑΦΗ κατανόησης ενός κειμένου απόφασης — ό,τι συγκρίνει η σκιώδης
   εκτέλεση. Ντετερμινιστική, συγκρίσιμη με EQUALP ανά συστατικό."
  (let ((d (orchestrator.decisions:parse-decision-text text)))
    (list :judges (length (orchestrator.decisions:decision-judges d))
          :chamber (orchestrator.decisions:decision-chamber d)
          :grounds (sort (mapcar (lambda (g) (list (getf g :vehicle)
                                                   (getf g :kind) (getf g :verdict)))
                                 (orchestrator.decisions:decision-grounds text))
                         #'string< :key (lambda (x) (format nil "~S" x)))
          :ratio-p (and (orchestrator.decisions:decision-ratio text) t)
          :operative (orchestrator.decisions:decision-operative d))))

(defun %decision-input-texts ()
  "Όλα τα κείμενα αποφάσεων από το input/ — το σώμα πάνω στο οποίο
   αποδεικνύεται η μη-παλινδρόμηση. (id . text), σαρωμένα PDF εκτός."
  (let (out)
    (dolist (dir (uiop:subdirectories (merge-pathnames "input/decisions/" (uiop:getcwd))))
      (dolist (f (uiop:directory-files dir))
        (let ((type (string-downcase (or (pathname-type f) ""))))
          (when (member type '("txt" "html" "pdf") :test #'string=)
            (handler-case
                (let ((text (if (string= type "pdf")
                                (orchestrator.pdf-authority:extract-text-any f)
                                (uiop:read-file-string f :external-format :utf-8))))
                  (when (> (length text) 200)   ; σαρωμένα/κενά δεν συγκρίνονται
                    (push (cons (pathname-name f) text) out)))
              (error () nil))))))
    (nreverse out)))

(defun %signature-regressions (base new)
  "Τι ΧΑΘΗΚΕ από την κατανόηση — η μόνη ερώτηση της πύλης. Λίστα περιγραφών."
  (let (r)
    (when (< (getf new :judges) (getf base :judges))
      (push (format nil "δικαστές ~D→~D" (getf base :judges) (getf new :judges)) r))
    (when (and (getf base :chamber) (not (getf new :chamber)))
      (push "χάθηκε το τμήμα" r))
    (when (and (getf base :ratio-p) (not (getf new :ratio-p)))
      (push "χάθηκε το ratio" r))
    (when (and (getf base :operative) (null (getf new :operative)))
      (push "χάθηκε το διατακτικό" r))
    (dolist (g (getf base :grounds))
      (unless (member g (getf new :grounds) :test #'equalp)
        (push (format nil "χάθηκε κρίση ~S" g) r)))
    (nreverse r)))

(defun run-shadow-knowledge (args)
  "--shadow-knowledge <πακέτο…> : ΣΚΙΩΔΗΣ ΕΚΤΕΛΕΣΗ υποψήφιας γνώσης — η
   κατανόηση ξανατρέχει σε ΟΛΟ το σώμα αποφάσεων με το πακέτο προσωρινά
   εγκατεστημένο, και τυπώνεται το diff: τι κερδίζεται, τι (αν) χάνεται.
   Exit 0 ΜΟΝΟ χωρίς καμία παλινδρόμηση. Η ενεργή γνώση δεν αγγίζεται."
  (unless args
    (format t "χρήση: --shadow-knowledge <αρχείο.sexp>…~%")
    (return-from run-shadow-knowledge 1))
  (orchestrator.knowledge-packs:ensure-fresh)
  (let* ((inputs (%decision-input-texts))
         (baseline (loop for (id . text) in inputs
                         collect (cons id (%understanding-signature text)))))
    (format t "~%── ΣΚΙΩΔΗΣ ΕΚΤΕΛΕΣΗ: ~{~A~^, ~} σε ~D αποφάσεις ──~%"
            (mapcar #'file-namestring args) (length inputs))
    (let ((gains 0) (regressions 0))
      (orchestrator.knowledge-packs:with-packs-overlay args
        (lambda ()
          (loop for (id . text) in inputs
                for base = (cdr (assoc id baseline :test #'equal))
                for new = (%understanding-signature text)
                do (let ((lost (%signature-regressions base new))
                         (won  (%signature-regressions new base))) ; συμμετρικά: τι κερδήθηκε
                     (dolist (l lost)
                       (incf regressions)
                       (format t "  ✗ ~A: ΠΑΛΙΝΔΡΟΜΗΣΗ — ~A~%" id l))
                     (dolist (w won)
                       (incf gains)
                       (format t "  + ~A: κέρδος — ~A~%" id w))))))
      (format t "~%Σκιά: ~D κέρδη · ~D παλινδρομήσεις → ~:[ΑΠΟΡΡΙΠΤΕΤΑΙ~;ΑΠΟΔΕΚΤΟ~]~%"
              gains regressions (zerop regressions))
      (if (zerop regressions) 0 1))))

(defun run-adopt-knowledge (args)
  "--adopt-knowledge <πακέτο…> : σκιώδης εκτέλεση ΚΑΙ, μόνο επί αποδείξεως
   μη-παλινδρόμησης, εγκατάσταση στο deployment/knowledge/ (versioned, με
   fingerprint) και ζωντανή φόρτωση. Η γνώση μπαίνει όπως ο νόμος:
   με διαδικασία, με ταυτότητα, με απόδειξη."
  (let ((rc (run-shadow-knowledge args)))
    (unless (zerop rc)
      (format t "~%Η υιοθέτηση ΔΕΝ προχωρά — πρώτα μηδέν παλινδρομήσεις.~%")
      (return-from run-adopt-knowledge rc)))
  (ensure-directories-exist orchestrator.knowledge-packs:*knowledge-dir*)
  (dolist (p args)
    (let ((dest (merge-pathnames (file-namestring p)
                                 orchestrator.knowledge-packs:*knowledge-dir*)))
      (unless (equal (namestring (truename p)) (ignore-errors (namestring (truename dest))))
        (uiop:copy-file p dest))
      (format t "  ✓ υιοθετήθηκε: ~A · sha ~A~%"
              (file-namestring dest)
              (subseq (orchestrator.knowledge-packs:pack-sha dest) 0 16))
      (%lesson :knowledge-adopted (file-namestring dest)
               (orchestrator.knowledge-packs:pack-sha dest))
      ;; το σύστημα συνεχίζει τη ΒΙΟΓΡΑΦΙΑ του: έμαθα κάτι, με απόδειξη πότε/πώς
      (orchestrator.self-history:record!
       :knowledge-adopted
       (format nil "Υιοθέτησα γνώση «~A» (sha ~A) αφού πέρασε τη σκιώδη πύλη με μηδέν παλινδρομήσεις."
               (file-namestring dest)
               (subseq (orchestrator.knowledge-packs:pack-sha dest) 0 16)))))
  (orchestrator.knowledge-packs:ensure-fresh :stream *standard-output*)
  (orchestrator.knowledge-packs:describe-active)
  0)

(register-command "--shadow-knowledge" (lambda (a) (run-shadow-knowledge a)))
(register-command "--adopt-knowledge"  (lambda (a) (run-adopt-knowledge a)))

;;; ----------------------------------------------------------------------------
;;; ΔΙΑΛΟΓΟΣ ΣΕ ΦΥΣΙΚΗ ΓΛΩΣΣΑ — ντετερμινιστικά
;;; ----------------------------------------------------------------------------
;;;
;;; Η ερώτηση αναλύεται όπως και οι αποφάσεις: αναδίπλωση (η γραφή δεν
;;; μετρά), αναγνώριση ΠΡΟΘΕΣΗΣ από τα κατηγορήματα της, εξαγωγή ορισμάτων
;;; (άρθρο, κώδικας, αριθμός/έτος απόφασης, όνομα), και δρομολόγηση στην
;;; ήδη αποδεδειγμένη ικανότητα. Κάθε απάντηση κουβαλά την πηγή της.
;;; Ερώτηση που δεν κατανοείται ΔΗΛΩΝΕΤΑΙ και καταγράφεται (lessons) —
;;; ο ίδιος βρόχος τιμιότητας που κλείνει όλα τα κενά του συστήματος.

(defparameter +corpus-output-alias+ '(("syntagma" . "constitution"))
  "corpus id → όνομα φακέλου εξόδου, όπου διαφέρουν.")

(defun %corpus-outdir (corpus)
  (or (cdr (assoc corpus +corpus-output-alias+ :test #'string=)) corpus))

(defparameter *ask-tag-names*
  '(("ποινικός κώδικας" . "ΠΚ") ("ποινικού κώδικα" . "ΠΚ") ("πκ" . "ΠΚ")
    ("αστικός κώδικας" . "ΑΚ") ("αστικού κώδικα" . "ΑΚ") ("ακ" . "ΑΚ")
    ("πολιτικής δικονομίας" . "ΚΠολΔ") ("κπολδ" . "ΚΠολΔ")
    ("ποινικής δικονομίας" . "ΚΠΔ") ("κπδ" . "ΚΠΔ") ("κποινδ" . "ΚΠΔ")
    ("διοικητικής δικονομίας" . "ΚΔΔ") ("κδδ" . "ΚΔΔ")
    ("σύνταγμα" . "Σ") ("συντάγματος" . "Σ"))
  "Πώς ΛΕΓΕΤΑΙ κάθε κώδικας σε φυσική ερώτηση — γραμμένα φυσικά,
   ταυτισμένα αναδιπλωμένα (η γραφή δεν είναι περίπτωση).")

(orchestrator.knowledge-packs:define-knowledge-kind :dialogue
 :doc "Επεκτάσεις του διαλόγου: (:code-name \"φυσική ονομασία\" \"TAG\") —
 νέοι τρόποι να ΛΕΓΕΤΑΙ ένας κώδικας σε φυσική ερώτηση."
 :install
 (lambda (entries)
   (dolist (e entries)
     (destructuring-bind (key name tag) e
       (ecase key
         (:code-name
          (pushnew (cons name tag) *ask-tag-names* :test #'equal))))))
 :snapshot (lambda () (copy-alist *ask-tag-names*))
 :restore  (lambda (st) (setf *ask-tag-names* st)))

(defun %ask-find-tag (folded)
  (loop for (name . tag) in *ask-tag-names*
        when (search (orchestrator.decisions:%fold name) folded) return tag))

;;; ΕΥΡΕΤΗΡΙΟ ΑΡΘΡΩΝ (Φάση 1): το corpus.jsonl διαβάζεται ΜΙΑ φορά ανά αρχείο
;;; και ανά αλλαγή του — όχι γραμμική σάρωση σε κάθε ερώτημα. Εξωτερική αλλαγή
;;; (νέο materialize, git checkout) ανιχνεύεται από file-write-date και το
;;; ευρετήριο ξαναχτίζεται — ποτέ μπαγιάτικη αλήθεια σιωπηλά. Το αρχείο μένει
;;; η ΑΥΘΕΝΤΙΚΗ πηγή· εδώ ζει μόνο η προσπελασιμότητά του.

(defvar *article-index-lock* (sb-thread:make-mutex :name "article-index")
  "Ένας χτίστης ευρετηρίου τη φορά — δύο ταυτόχρονα /ask δεν διαβάζουν το ίδιο
   corpus.jsonl δύο φορές παράλληλα.")

(defvar *article-index* (make-hash-table :test 'equal)
  "corpus → (file-write-date πίνακας-number→(text heading) path). Ζει υπό το
   *article-index-lock* — καμία πρόσβαση εκτός κλειδώματος.")

(defun %article-table (corpus)
  "(values πίνακας path) του ζωντανού ευρετηρίου άρθρων του CORPUS, ή nil αν
   δεν υπάρχει εκδομένο corpus.jsonl. number → (text heading)."
  (sb-thread:with-mutex (*article-index-lock*)
    (let* ((path (merge-pathnames (format nil "output/~A/corpus.jsonl" (%corpus-outdir corpus))
                                  (uiop:getcwd)))
           (fwd (and (probe-file path) (file-write-date path)))
           (cached (gethash corpus *article-index*)))
      (cond ((null fwd) nil)
            ((and cached (eql (first cached) fwd))
             (values (second cached) (third cached)))
            (t (let ((table (make-hash-table :test 'equal)))
                 (with-open-file (s path :external-format :utf-8)
                   (loop for line = (read-line s nil nil)
                         while line
                         for rec = (ignore-errors (jonathan:parse line :as :alist))
                         when rec
                           do (let ((text (cdr (assoc "text" rec :test #'string=)))
                                    (heading (cdr (assoc "heading" rec :test #'string=))))
                                (setf (gethash (cdr (assoc "number" rec :test #'string=)) table)
                                      ;; (κείμενο τίτλος κανονικοποιημένο-κείμενο κανονικοποιημένος-τίτλος)
                                      ;; — η κανονικοποίηση ΜΙΑ φορά στο χτίσιμο, όχι ανά ερώτημα
                                      (list text heading
                                            (and (stringp text)
                                                 (orchestrator.citation-authority:normalize-greek text))
                                            (and (stringp heading)
                                                 (orchestrator.citation-authority:normalize-greek heading)))))))
                 (setf (gethash corpus *article-index*) (list fwd table path))
                 (values table path)))))))

(defun %ask-article-text (corpus number)
  "Το κείμενο του άρθρου από το ΕΚΔΟΜΕΝΟ corpus.jsonl — η πηγή, όχι περίληψη.
   Μέσω του ζωντανού ευρετηρίου: Ο(1) ανά ερώτημα, όχι σάρωση αρχείου."
  (multiple-value-bind (table path) (%article-table corpus)
    (when table
      (let ((hit (gethash number table)))
        (when hit
          (values (first hit) (second hit) path))))))

(defun %word-in (text word)
  "Εμφανίζεται η WORD στο TEXT ως ΛΕΞΗ (όχι υπο-συμβολοσειρά άλλης λέξης);
   Και τα δύο ήδη κανονικοποιημένα."
  (loop with wl = (length word)
        for pos = (search word text) then (search word text :start2 (1+ pos))
        while pos
        do (let ((before (and (plusp pos) (char text (1- pos))))
                 (after (let ((e (+ pos wl)))
                          (and (< e (length text)) (char text e)))))
             (when (and (or (null before) (not (alpha-char-p before)))
                        (or (null after) (not (alpha-char-p after))))
               (return t)))))

(defun %stem-in (text stem)
  "Αρχίζει ΛΕΞΗ του TEXT με το STEM; (πρόθεμα σε όριο λέξης — και τα δύο
   κανονικοποιημένα). Επιφανειακή ανάκληση, δηλωμένη ως τέτοια."
  (loop with sl = (length stem)
        for pos = (search stem text) then (search stem text :start2 (1+ pos))
        while pos
        do (let ((before (and (plusp pos) (char text (1- pos)))))
             (when (or (null before) (not (alpha-char-p before)))
               (return t)))))

(defun %corpus-stem-mentions (corpus stem &key (limit 4))
  "Τα άρθρα του CORPUS με λέξη που αρχίζει από STEM — για λέξεις ΕΚΤΟΣ του
   επιμελημένου λεξιλογίου (δηλωμένη επιφανειακή αναζήτηση· τίτλος πρώτα).
   (values ((num heading τίτλος-p)…) σύνολο)."
  (let ((table (%article-table corpus)) (hits '()) (total 0))
    (when (and table stem)
      (maphash
       (lambda (num entry)
         (destructuring-bind (text heading norm nhead) entry
           (declare (ignore text))
           (when (and norm (%stem-in norm stem))
             (incf total)
             (push (list num heading (and nhead (%stem-in nhead stem))) hits))))
       table))
    (values (subseq (sort hits (lambda (a b)
                                 (cond ((and (third a) (not (third b))) t)
                                       ((and (third b) (not (third a))) nil)
                                       (t (string< (first a) (first b))))))
                    0 (min limit (length hits)))
            total)))

(defun %sentence-bounds (text pos)
  "(values αρχή τέλος) της πρότασης γύρω από τη θέση POS."
  (let ((start (loop for i downfrom (1- pos) to 0
                     when (member (char text i) '(#\. #\; #\· #\Newline)) return (1+ i)
                     finally (return 0)))
        (end (loop for i from pos below (length text)
                   when (member (char text i) '(#\. #\; #\· #\Newline)) return (1+ i)
                   finally (return (length text)))))
    (values start end)))

(defun %raw-word-at (text norm pos)
  "Η ΠΡΑΓΜΑΤΙΚΗ λέξη (με τόνους) στη θέση POS — η %fold είναι 1:1, άρα τα
   όρια λέξης του κανονικοποιημένου ισχύουν και στο πρωτότυπο."
  (let ((start (loop for i downfrom (1- pos) to 0
                     unless (alpha-char-p (char norm i)) return (1+ i)
                     finally (return 0)))
        (end (loop for i from pos below (length norm)
                   while (alpha-char-p (char norm i))
                   finally (return i))))
    (string-downcase (subseq text start end))))

(defun %term-study (corpus stem)
  "ΜΕΛΕΤΗ όρου στα κείμενα του CORPUS (κατά θέμα): (values μορφές συνάψεις
   προτάσεις) — μορφές: ((πραγματική-λέξη . πλήθος)…) ΜΑΡΤΥΡΗΜΕΝΕΣ στα
   κείμενα· συνάψεις: ((«λέξη επόμενη-γενική» . πλήθος)…) — οι νομικοί ΡΟΛΟΙ
   του όρου· προτάσεις: ((num heading πρόταση οριστική-p τίτλος-p)…)."
  (let ((table (%article-table corpus))
        (forms (make-hash-table :test 'equal))
        (colls (make-hash-table :test 'equal))
        (sents '()))
    (when (and table stem)
      (maphash
       (lambda (num entry)
         (destructuring-bind (text heading norm nhead) entry
           (when norm
             (loop with sl = (length stem)
                   for pos = (search stem norm) then (search stem norm :start2 (1+ pos))
                   while pos
                   do (let ((before (and (plusp pos) (char norm (1- pos)))))
                        (when (or (null before) (not (alpha-char-p before)))
                          (incf (gethash (%raw-word-at text norm pos) forms 0))
                          (multiple-value-bind (a b) (%sentence-bounds norm pos)
                            (let* ((nsent (subseq norm a b))
                                   (def-p (loop for m in orchestrator.casegrammar:+definitional-markers+
                                                  thereis (search m nsent))))
                              ;; σύναψη: η ΕΠΟΜΕΝΗ λέξη σε γενική = νομικός ρόλος
                              (let* ((we (+ pos sl))
                                     (we2 (loop for i from we below b
                                                while (alpha-char-p (char norm i))
                                                finally (return i)))
                                     (ns (loop for i from we2 below b
                                               unless (alpha-char-p (char norm i)) collect i into gaps
                                               else return i
                                               finally (return nil))))
                                (when ns
                                  (let ((ne (loop for i from ns below b
                                                  while (alpha-char-p (char norm i))
                                                  finally (return i))))
                                    (when (and (>= (- ne ns) 4)
                                               (member (subseq norm (- ne 2) ne)
                                                       '("ων" "ησ" "ου") :test #'string=))
                                      (incf (gethash (format nil "~A ~A"
                                                             (%raw-word-at text norm pos)
                                                             (string-downcase (subseq text ns ne)))
                                                     colls 0))))))
                              (let ((sent (with-output-to-string (o)
                                            ;; εσωτερικά CR/LF/στηλοθέτες ⇒ ένα κενό
                                            (let ((sp t))
                                              (loop for ch across (subseq text a (min b (+ a 240)))
                                                    do (if (member ch '(#\Space #\Newline #\Return #\Tab))
                                                           (unless sp (write-char #\Space o) (setf sp t))
                                                           (progn (write-char ch o) (setf sp nil))))))))
                                (setf sent (string-right-trim " " sent))
                                (when (and (> (count-if #'alpha-char-p sent) 20)
                                           (or def-p (and nhead (%stem-in nhead stem))))
                                  (pushnew (list num heading sent
                                                 (and def-p t)
                                                 (and nhead (%stem-in nhead stem) t))
                                           sents :key #'first :test #'equal)))))
                          (setf pos (+ pos sl))))))))
       table))
    (let ((fl '()) (cl '()))
      (maphash (lambda (k v) (push (cons k v) fl)) forms)
      (maphash (lambda (k v) (push (cons k v) cl)) colls)
      (values (sort fl #'> :key #'cdr)
              (sort cl #'> :key #'cdr)
              (sort sents (lambda (a b)
                            (cond ((and (fourth a) (not (fourth b))) t)
                                  ((and (fourth b) (not (fourth a))) nil)
                                  ((and (fifth a) (not (fifth b))) t)
                                  (t nil))))))))

(defun %corpus-mentions (corpus lemmas &key (limit 4))
  "Τα άρθρα του CORPUS που μνημονεύουν ΟΛΑ τα LEMMAS (μέσω των επιμελημένων
   ΜΟΡΦΩΝ τους — η μία γλωσσική έδρα, όχι πρόθεμα-μαντεψιά). Επιστρέφει
   (values ((num heading τίτλος-περιέχει-p)…) σύνολο) — πρώτα όσα το φέρουν
   στον ΤΙΤΛΟ (το άρθρο ΕΙΝΑΙ γι' αυτό), μετά κατά αριθμό."
  (let ((table (%article-table corpus))
        (form-sets (mapcar (lambda (l)
                             (mapcar #'orchestrator.citation-authority:normalize-greek
                                     (orchestrator.citation-authority:lemma-forms l)))
                           lemmas))
        (hits '()) (total 0))
    (when (and table form-sets (notany #'null form-sets))
      (maphash
       (lambda (num entry)
         (destructuring-bind (text heading norm nhead) entry
           (declare (ignore text))
           (when (and norm
                      (every (lambda (forms)
                               (some (lambda (f) (%word-in norm f)) forms))
                             form-sets))
             (incf total)
             (push (list num heading
                         (and nhead
                              (every (lambda (forms)
                                       (some (lambda (f) (%word-in nhead f)) forms))
                                     form-sets)))
                   hits))))
       table))
    (values (subseq (sort hits (lambda (a b)
                                 (cond ((and (third a) (not (third b))) t)
                                       ((and (third b) (not (third a))) nil)
                                       (t (let ((na (parse-integer (first a) :junk-allowed t))
                                                (nb (parse-integer (first b) :junk-allowed t)))
                                            (if (and na nb (/= na nb)) (< na nb)
                                                (string< (first a) (first b))))))))
                    0 (min limit (length hits)))
            total)))

(defun %ask-decisions-for (corpus article tag)
  "Η κατ' άρθρον νομολογία από το ευρετήριο — με τμήμα και φορά όπου υπάρχει."
  (let ((path (merge-pathnames "deployment/data/decisions/kat-arthron.json" (uiop:getcwd))))
    (if (probe-file path)
        (let* ((idx (jonathan:parse (uiop:read-file-string path :external-format :utf-8) :as :alist))
               (entry (find-if (lambda (e)
                                 (and (equal (cdr (assoc "corpus" e :test #'string=)) corpus)
                                      (equal (cdr (assoc "article" e :test #'string=)) article)))
                               idx)))
          (if entry
              (let ((ds (cdr (assoc "decisions" entry :test #'string=))))
                (format t "~%Νομολογία για ~A άρθρο ~A — ~D αποφάσεις:~%" tag article (length ds))
                (dolist (d ds)
                  (format t "  • ~A~@[ [~A]~]~@[ ~A~]~%"
                          (cdr (assoc "decision" d :test #'string=))
                          (let ((c (cdr (assoc "chamber" d :test #'string=)))) (and (stringp c) c))
                          (let ((st (cdr (assoc "stance" d :test #'string=))))
                            (and (stringp st) (if (equal st "upholds") "▲ δέχεται" "▼ απορρίπτει")))))
                (format t "~%(πηγή: ~A — λεπτομέρεια: --explain-decision)~%"
                        (enough-namestring path (uiop:getcwd))))
              (format t "Καμία καταχωρισμένη απόφαση για ~A άρθρο ~A στο ευρετήριο.~%" tag article)))
        (format t "Δεν υπάρχει ακόμη κατ' άρθρον ευρετήριο — τρέξε --index-decisions.~%"))
    0))

;;; Η ΜΝΗΜΗ ΤΟΥ ΔΙΑΛΟΓΟΥ — ντετερμινιστική κατάσταση συνομιλίας, με ΜΙΑ έδρα:
;;; τη working-memory του τρέχοντος process-request (στάδιο 4 της γνωσιακής).
;;; Ό,τι μένει ανοιχτό σε μια στροφή (εκκρεμής διευκρίνιση, τελευταία αναφορά
;;; σε κώδικα/άρθρο) είναι διαθέσιμο στην επόμενη ΕΠΕΙΔΗ το run-ask περνά την
;;; ΙΔΙΑ *ask-memory* σε κάθε αίτημα — καμία παράλληλη global δίπλα στη μνήμη.

(defun %dialogue (key &optional default)
  "Ανάκληση κατάστασης διαλόγου από την ΕΝΕΡΓΗ μνήμη εργασίας (:tag/:article/:awaiting)."
  (orchestrator.cognition:recall orchestrator.cognition:*current-memory* key default))

(defun (setf %dialogue) (val key)
  "Εγγραφή κατάστασης διαλόγου στην ΕΝΕΡΓΗ μνήμη εργασίας."
  (orchestrator.cognition:remember orchestrator.cognition:*current-memory* key val))

(defparameter +tag-full-names+
  '(("ΠΚ" . "Ποινικός Κώδικας") ("ΑΚ" . "Αστικός Κώδικας")
    ("ΚΠολΔ" . "Κώδικας Πολιτικής Δικονομίας") ("ΚΠΔ" . "Κώδικας Ποινικής Δικονομίας")
    ("ΚΔΔ" . "Κώδικας Διοικητικής Δικονομίας") ("Σ" . "Σύνταγμα της Ελλάδας")))

(defun %ask-code-answer (folded)
  "Όταν εκκρεμεί το «ποιου κώδικα;», η απάντηση είναι συχνά ελλειπτική
   («του ποινικού»). Η εκκρεμής ερώτηση ορίζει τον τύπο της απάντησης —
   γι' αυτό εδώ επιτρέπεται ελεύθερη κλίση: το γένος/η δικονομία ξεδιαλύνουν."
  (or (%ask-find-tag folded)
      (cond ((cl-ppcre:scan (orchestrator.decisions:%fold "δικονομ") folded)
             (cond ((cl-ppcre:scan (orchestrator.decisions:%fold "πολιτικ") folded) "ΚΠολΔ")
                   ((cl-ppcre:scan (orchestrator.decisions:%fold "ποινικ") folded) "ΚΠΔ")
                   ((cl-ppcre:scan (orchestrator.decisions:%fold "διοικητ") folded) "ΚΔΔ")))
            ((cl-ppcre:scan (orchestrator.decisions:%fold "ποινικ") folded) "ΠΚ")
            ((cl-ppcre:scan (orchestrator.decisions:%fold "αστικ") folded) "ΑΚ")
            ((cl-ppcre:scan (orchestrator.decisions:%fold "συνταγμα") folded) "Σ"))))

(defun %ask-corpus-article-count (corpus)
  "Πόσα άρθρα έχει το materialized corpus — μετρημένα από το ζωντανό ευρετήριο
   (ίδια έδρα με το %ask-article-text — καμία δεύτερη σάρωση)."
  (let ((table (%article-table corpus)))
    (when table (hash-table-count table))))

(defun %ask-decisions-count ()
  (let ((n 0))
    (dolist (dir (uiop:subdirectories (merge-pathnames "deployment/data/decisions/" (uiop:getcwd))))
      (dolist (f (uiop:directory-files dir))
        (when (and (string= (pathname-type f) "json")
                   (not (search ".prov" (pathname-name f))))
          (incf n))))
    n))

(defun %ask-overview ()
  "Τι ΞΕΡΕΙ το σύστημα — απαρίθμηση από την πραγματική του κατάσταση,
   ποτέ από σενάριο. Κάθε αριθμός μετρήθηκε τώρα."
  (format t "~%Γνωρίζω, μετρημένα αυτή τη στιγμή:~%")
  (let ((seen '()))
    (loop for (tag . corpus) in orchestrator.decisions:+law-tag-corpus-map+
          unless (member corpus seen :test #'string=)
          do (push corpus seen)
             (let ((n (%ask-corpus-article-count corpus)))
               (when n
                 (format t "  • ~A (~A): ~D άρθρα, πλήρες κείμενο~%"
                         (or (cdr (assoc tag +tag-full-names+ :test #'string=)) tag)
                         tag n)))))
  (let ((d (%ask-decisions-count)))
    (when (plusp d)
      (format t "  • Νομολογία: ~D αποφάσεις σε βάθος (σύνθεση, λόγοι με την τύχη τους, ratio, διατακτικό)~%" d)))
  (format t "~%Ρώτα με π.χ.: «τι λέει το άρθρο 299 του ποινικού κώδικα», ~
«νομολογία για το άρθρο 559 ΚΠολΔ», «εξήγησέ μου την απόφαση 101/2026», ~
«προφίλ του δικαστή Κοσμίδη».~%")
  0)


(defvar *ask-memory* (make-instance 'orchestrator.cognition:working-memory)
  "Η ΔΙΑΡΚΗΣ μνήμη εργασίας της συνεδρίας — περνά σε ΚΑΘΕ process-request, ώστε
   το στάδιο 4 να έχει ζωή πέρα από το ένα ερώτημα.")

(defun %ask-topic (cog)
  "Το ΘΕΜΑ μιας αλληλεπίδρασης για το επεισόδιο: πρόθεση + ρητή αναφορά
   (art:<corpus>:<άρθρο>) από τα slots του frame — ώστε η ανάκληση ομοίων να
   πατά σε ταυτότητες, όχι μόνο σε κείμενο."
  (let ((frame (orchestrator.cognition:cog-frame cog)))
    (when frame
      (let* ((s (orchestrator.cognition:frame-slots frame))
             (corpus (getf s :corpus)) (article (getf s :article)))
        (append (list (string-downcase (symbol-name (class-name (class-of frame)))))
                (when (and corpus article)
                  (list (format nil "art:~A:~A" corpus article))))))))

(defun run-ask (args)
  "--ask «ερώτηση» : Ρώτα σε ΦΥΣΙΚΑ ΕΛΛΗΝΙΚΑ — ντετερμινιστικά, ΜΕΣΑ από τη
   γνωσιακή διαδικασία (5 στάδια, orchestrator.cognition). ΚΑΘΕ πρόθεση είναι
   frame· καμία cond περιπτώσεων εδώ. Ό,τι δεν αποδομείται δηλώνεται ΚΑΙ
   καταγράφεται — ποτέ μάντεμα. Κάθε αλληλεπίδραση γίνεται ΕΠΕΙΣΟΔΙΟ στο
   υπόστρωμα μνήμης — το σύστημα θυμάται ό,τι ζει, όχι μόνο ό,τι ξέρει."
  (orchestrator.knowledge-packs:ensure-fresh)   ; ζωντανή γνώση — χωρίς επανεκκίνηση
  (let ((q (string-trim " " (format nil "~{~A~^ ~}" args))))
    (when (zerop (length q))
      (format t "χρήση: --ask \"η ερώτησή σου σε φυσικά ελληνικά\"~%")
      (return-from run-ask 1))
    (multiple-value-bind (ans cog)
        (orchestrator.cognition:process-request q :memory *ask-memory*)
      (orchestrator.memory:record-episode :interaction q
        :status (if ans :answered :not-understood)
        :topic (%ask-topic cog)
        ;; και η ΑΠΑΝΤΗΣΗ (περίληψη) — ώστε η συνομιλία να ανασυστήνεται από τα
        ;; επεισόδια, όχι μόνο να καταμετράται
        :props (when ans (list :answer (subseq ans 0 (min 200 (length ans))))))
      (cond
        (ans (format t "~%~A~%" ans) 0)
        (t (format t "~%Δεν κατάλαβα την ερώτηση — τίμια, χωρίς μάντεμα. Καταγράφηκε.~%~
Καταλαβαίνω π.χ.:~%  «τι λέει το άρθρο 299 του ποινικού κώδικα»~%  «ποια νομολογία υπάρχει για το άρθρο 559 ΚΠολΔ»~%  «εξήγησέ μου την απόφαση 101/2026»~%  «προφίλ του δικαστή Κοσμίδη»~%")
           (%lesson :question-not-understood q "άγνωστη πρόθεση")
           1)))))

;;; ── Η αποστολή του συντάγματος, δεμένη στις ΠΡΑΓΜΑΤΙΚΕΣ μετρήσεις ──
;;; Ο αρμόδιος (αυτή η CLI) εγγράφει ΠΩΣ μετριέται κάθε στόχος· το σύνταγμα
;;; δεν ξέρει να μετρά — απλώς ρωτά τον αρμόδιο. Έτσι το «ξέρεις την αποστολή
;;; σου;» απαντιέται με την ΑΠΟΣΤΑΣΗ, μετρημένη τώρα, όχι με σύνθημα.
(orchestrator.self:register-mission-measure
 :understanding
 (lambda ()
   (multiple-value-bind (perfect total) (%understanding-scan nil)
     (if (plusp total)
         (values (format nil "~D/~D αποφάσεις σε πλήρη κατανόηση (~D%)"
                         perfect total (round (* 100 perfect) total))
                 (= perfect total))
         (values "καμία materialized απόφαση ακόμη" nil)))))

(orchestrator.self:register-mission-measure
 :corpus
 (lambda ()
   (let ((seen '()) (have 0) (want 0))
     (dolist (entry orchestrator.decisions:+law-tag-corpus-map+)
       (let ((corpus (cdr entry)))
         (unless (member corpus seen :test #'string=)
           (push corpus seen) (incf want)
           (when (%ask-corpus-article-count corpus) (incf have)))))
     (values (format nil "~D/~D κώδικες με πλήρες κείμενο" have want)
             (and (plusp want) (= have want))))))

(orchestrator.self:register-mission-measure
 :coverage
 (lambda ()
   (values (format nil "~D αποφάσεις σε βάθος (στόχος: νομολογία ΑΠ εικοσαετίας)"
                   (%ask-decisions-count))
           nil)))

(defun run-constitution ()
  "--constitution : το ΔΙΚΟ του σύνταγμα (όχι της Ελλάδας) — ποιον υπηρετεί,
   γιατί, οι αρχές του, και η αποστολή του ΜΕΤΡΗΜΕΝΗ."
  (orchestrator.self:describe-constitution))

(defun run-history ()
  "--history : η βιογραφία του — επαληθευμένη αλυσίδα, γένεση→σήμερα."
  (orchestrator.self-history:history-report))

(register-command "--constitution"         (lambda (a) (declare (ignore a)) (run-constitution)))
(register-command "--σύνταγμα"             (lambda (a) (declare (ignore a)) (run-constitution)))
(register-command "--history"              (lambda (a) (declare (ignore a)) (run-history)))
(register-command "--ιστορία"              (lambda (a) (declare (ignore a)) (run-history)))

(register-command "--ask"                  (lambda (a) (run-ask a)))
(register-command "--ρώτα"                 (lambda (a) (run-ask a)))

(register-command "--fetch-year"           (lambda (a) (run-fetch-year a)))
(register-command "--watch-decisions"      (lambda (a) (declare (ignore a)) (run-watch-decisions)))
(register-command "--reason-decision"      (lambda (a) (run-reason-decision a)))
(register-command "--explain-decision"     (lambda (a) (run-explain-decision a)))
(register-command "--understanding"        (lambda (a) (declare (ignore a)) (run-understanding)))
(register-command "--jurisprudence"        (lambda (a) (declare (ignore a)) (run-jurisprudence)))
(register-command "--judge-profile"        (lambda (a) (run-judge-profile a)))
(register-command "--index-decisions"      (lambda (a) (declare (ignore a)) (run-index-decisions)))
(register-command "--lessons"              (lambda (a) (declare (ignore a)) (run-lessons)))
