;;;; source/legal-id-registry.lisp
;;;; ============================================================================
;;;; LEGAL-ID REGISTRY — the router that knows which CODE a ΦΕΚ touches
;;;; ============================================================================
;;;;
;;;; Autonomy needs a brain that, given a freshly published ΦΕΚ (Government
;;;; Gazette) or law, decides WHICH served code it amends — so the system can
;;;; fetch → codify → consolidate → sign → publish the right corpus without a
;;;; human in the loop. This module is that brain, kept PURE and deterministic:
;;;; it operates on registry entries (data) the CLI derives from the corpus
;;;; configs (the single source of truth), so there is no duplicated identity.
;;;;
;;;; The strong routing signal is the explicit statutory citation a Greek
;;;; amending act always carries ("…του ν. 4619/2019…"); the code's canonical
;;;; name and abbreviations are secondary signals. Matching is conservative:
;;;; only a concrete law-number/year or a name/alias hit routes a ΦΕΚ, so the
;;;; system never guesses a code for an unrelated gazette.
;;;; ============================================================================

(defpackage :orchestrator.legal-id
  (:use :cl)
  (:export #:make-registry-entry #:registry-entry-corpus-id #:registry-entry-p
           #:entry-law-number #:entry-year #:entry-name #:entry-aliases
           #:entry-fek-series #:entry-fek-number #:entry-eli-prefix
           #:entry-source-pdf #:entry-fetch-cmd
           #:parse-fek-ref #:parse-law-ref #:normalize-greek
           #:registry-by-corpus #:registry-by-law #:registry-by-fek
           #:classify-text #:route-listing
           ;; [FEK-COMPILER] Η ΜΙΑ έδρα θέσης-ευαίσθητης δρομολόγησης: ποιον
           ;; served κώδικα ονομάζει το κείμενο, και ΠΟΥ (rightmost mention).
           #:resolve-code-rightmost))

(in-package :orchestrator.legal-id)

;;; ----------------------------------------------------------------------------
;;; registry entry (a plist behind accessors so callers stay decoupled)
;;; ----------------------------------------------------------------------------

(defun make-registry-entry (corpus-id &key law-number year name aliases
                                            fek-series fek-number eli-prefix
                                            source-pdf fetch-cmd)
  "One code's identity, derived from its config. CORPUS-ID is the served short
   name (e.g. \"poinikos\"). LAW-NUMBER/YEAR are integers (NIL for the
   Constitution). ALIASES is a list of strings (abbrevs / inflected names)."
  (list :corpus-id corpus-id :law-number law-number :year year :name name
        :aliases aliases :fek-series fek-series :fek-number fek-number
        :eli-prefix eli-prefix :source-pdf source-pdf :fetch-cmd fetch-cmd))

(defun registry-entry-p (x) (and (consp x) (eq (car x) :corpus-id)))
(defun registry-entry-corpus-id (e) (getf e :corpus-id))
(defun entry-law-number (e) (getf e :law-number))
(defun entry-year (e) (getf e :year))
(defun entry-name (e) (getf e :name))
(defun entry-aliases (e) (getf e :aliases))
(defun entry-fek-series (e) (getf e :fek-series))
(defun entry-fek-number (e) (getf e :fek-number))
(defun entry-eli-prefix (e) (getf e :eli-prefix))
(defun entry-source-pdf (e) (getf e :source-pdf))
(defun entry-fetch-cmd (e) (getf e :fetch-cmd))

;;; ----------------------------------------------------------------------------
;;; parsing Greek statutory references (deterministic, tolerant of punctuation)
;;; ----------------------------------------------------------------------------

(defun %to-int (s) (and s (ignore-errors (parse-integer s :junk-allowed t))))

(defparameter +greek-accent-map+
  '((#\ά . #\α) (#\έ . #\ε) (#\ή . #\η) (#\ί . #\ι) (#\ό . #\ο) (#\ύ . #\υ) (#\ώ . #\ω)
    (#\ϊ . #\ι) (#\ϋ . #\υ) (#\ΐ . #\ι) (#\ΰ . #\υ)
    (#\Ά . #\Α) (#\Έ . #\Ε) (#\Ή . #\Η) (#\Ί . #\Ι) (#\Ό . #\Ο) (#\Ύ . #\Υ) (#\Ώ . #\Ω)
    (#\Ϊ . #\Ι) (#\Ϋ . #\Υ))
  "Monotonic-Greek diacritic folding: accented vowel → base vowel.")

(defun normalize-greek (s)
  "Fold Greek diacritics and upcase, so matching is robust to inflection and case
   (e.g. \"Σύνταγμα\" matches inside \"Συντάγματος\"; \"α\" matches \"Α\"; the
   accented \"Ώ\" in \"Κώδικας\" folds to \"Ω\"). The final sigma ς (U+03C2) is
   folded to Σ — SBCL's string-upcase leaves it lower-case, which would otherwise
   break every word ending in -ς (\"Ποινικής Δικονομίας\")."
  (when (stringp s)
    (nsubstitute (code-char #x03A3) (code-char #x03C2)
                 (string-upcase
                  (map 'string (lambda (c) (or (cdr (assoc c +greek-accent-map+)) c)) s)))))

(defun %normalize-greek (s) (normalize-greek s))

(defparameter +fek-series-letters+ "ΑΒΓΔ"
  "ΦΕΚ teύχη we route: Α (laws), Β, Γ, Δ. Greek capitals.")

(defun parse-fek-ref (string)
  "Parse a ΦΕΚ reference like \"ΦΕΚ Α' 95/2019\", \"Α΄ 95/2019\" or
   \"ΦΕΚ Α 95 / 2019\" → plist (:series \"Α\" :number 95 :year 2019), or NIL.
   Tolerates the tonos/keraia variants (' ΄ ´) and spacing."
  (when (stringp string)
    (let ((s (%normalize-greek
              (or (ignore-errors
                    (cl-ppcre:regex-replace-all "[ΦΕΚφεκ.\\s]+" string " ")) string))))
      (cl-ppcre:register-groups-bind (series num year)
          ((format nil "([~A])[´'’΄]?\\s*([0-9]{1,5})\\s*/\\s*((?:19|20)[0-9]{2})"
                   +fek-series-letters+) s)
        (when (and series num year)
          (list :series series :number (%to-int num) :year (%to-int year)))))))

(defun parse-law-ref (string)
  "Parse a law reference like \"ν. 4619/2019\", \"Ν.4619/2019\",
   \"νόμος 4619 / 2019\" or a bare \"4619/2019\" → plist (:number 4619 :year 2019),
   or NIL."
  (when (stringp string)
    (cl-ppcre:register-groups-bind (num year)
        ("(?:ν\\.?|Ν\\.?|νόμος|νόμου)?\\s*([0-9]{1,5})\\s*/\\s*((?:19|20)[0-9]{2})" string)
      (when (and num year)
        (list :number (%to-int num) :year (%to-int year))))))

;;; ----------------------------------------------------------------------------
;;; lookups
;;; ----------------------------------------------------------------------------

(defun registry-by-corpus (registry corpus-id)
  (find corpus-id registry :key #'registry-entry-corpus-id :test #'string=))

(defun registry-by-law (registry law-number year)
  "The entry whose statute is LAW-NUMBER/YEAR (both integers), or NIL."
  (and law-number year
       (find-if (lambda (e) (and (eql law-number (entry-law-number e))
                                 (eql year (entry-year e))))
                registry)))

(defun registry-by-fek (registry series number year)
  "The entry first published in ΦΕΚ SERIES NUMBER/YEAR, or NIL."
  (find-if (lambda (e) (and (equal series (entry-fek-series e))
                            (eql number (entry-fek-number e))
                            (eql year (entry-year e))))
           registry))

;;; ----------------------------------------------------------------------------
;;; classification — which code(s) does this gazette text touch?
;;; ----------------------------------------------------------------------------

(defun %contains (haystack needle)
  "Accent/case-insensitive substring test (Greek-aware), so an inflected mention
   of a code's name still matches its canonical form."
  (and (stringp haystack) (stringp needle) (plusp (length needle))
       (search (%normalize-greek needle) (%normalize-greek haystack))))

(defun %law-cited-p (text num year)
  "T iff TEXT cites law NUM/YEAR as a WHOLE number/year — with non-digit boundaries
   and tolerant of spaces around the slash. This is what stops «4619/2019» from
   matching inside «14619/2019» (a different law) or «4619/20199» (a typo)."
  (and num year (stringp text)
       (cl-ppcre:scan (format nil "(?<![0-9])~D\\s*/\\s*~D(?![0-9])" num year) text)
       t))

(defun classify-text (registry text)
  "Return the list of corpus-ids whose code TEXT appears to amend, by the strong
   signal of an explicit statutory citation (the code's own law-number/year,
   matched on numeric boundaries — never a substring) and the secondary signals of
   its canonical name / aliases. Conservative: a code is only routed on a concrete
   hit, never guessed. Order follows REGISTRY."
  (when (stringp text)
    (loop for e in registry
          when (or (%law-cited-p text (entry-law-number e) (entry-year e))
                   (%contains text (entry-name e))
                   (some (lambda (a) (%contains text a)) (entry-aliases e)))
            collect (registry-entry-corpus-id e))))

(defun %law-cited-position (text num year)
  "Η θέση (ή NIL) της ΤΕΛΕΥΤΑΙΑΣ αναφοράς του νόμου NUM/YEAR στο TEXT — ολόκληρος
   αριθμός/έτος με αριθμητικά όρια (βλ. %law-cited-p), ποτέ substring."
  (when (and num year (stringp text))
    (let ((last nil))
      (cl-ppcre:do-matches (ms me (format nil "(?<![0-9])~D\\s*/\\s*~D(?![0-9])" num year) text)
        (declare (ignore me))
        (setf last ms))
      last)))

(defun resolve-code-rightmost (registry text)
  "(values corpus-id position) του served κώδικα που το TEXT ονομάζει ΡΗΤΑ
   πλησιέστερα στο τέλος του (rightmost mention) — μέσω ονόματος, alias
   (routing_phrases των configs) ή αναφοράς νόμου (ν. Χ/ΕΕΕΕ σε αριθμητικά όρια).
   NIL όταν κανένας κώδικας δεν ονομάζεται — ΠΟΤΕ μαντεψιά. Αυτή είναι η ΜΙΑ
   έδρα θέσης-ευαίσθητης δρομολόγησης: ο amendment extractor την καταναλώνει
   για scope resolution, το discovery για ταξινόμηση· καμία λίστα φράσεων δεν
   ζει πουθενά αλλού (η γνώση κατάγεται από τα configs)."
  (when (and (stringp text) (plusp (length text)))
    (let ((nz (normalize-greek text)) (best -1) (best-code nil))
      (flet ((consider (pos code)
               (when (and pos (> pos best))
                 (setf best pos best-code code))))
        (dolist (e registry)
          (let ((code (registry-entry-corpus-id e)))
            ;; (α) ρητή αναφορά του νόμου-φορέα (ισχυρό σήμα)
            (consider (%law-cited-position text (entry-law-number e) (entry-year e)) code)
            ;; (β) κανονικό όνομα + aliases/routing_phrases (NORMALIZE-GREEK είναι
            ;; length-preserving ⇒ οι θέσεις στο nz ταυτίζονται με το text)
            (dolist (needle (cons (entry-name e) (entry-aliases e)))
              (when (and (stringp needle) (plusp (length needle)))
                (consider (search (normalize-greek needle) nz :from-end t) code))))))
      (when best-code (values best-code best)))))

(defun route-listing (registry listing &key fetch-text-fn)
  "Route a ΦΕΚ search LISTING (a list of alists with at least \"title\" and
   \"url\", optionally \"number\"/\"year\") to the codes each item touches.
   Classification uses the item's title; when FETCH-TEXT-FN is supplied it is
   called on the item's url to pull the full gazette text for a deeper match.
   Returns a list of plists (:item ITEM :corpora (corpus-id …)); items that match
   no served code carry :corpora NIL (caller decides whether to ignore them)."
  (flet ((aget (a k) (cdr (assoc k a :test #'string=))))
    (loop for item in listing
          for title = (or (aget item "title") "")
          for url = (aget item "url")
          for text = (if (and fetch-text-fn url)
                         (or (ignore-errors (funcall fetch-text-fn url)) title)
                         title)
          collect (list :item item :corpora (classify-text registry text)))))
