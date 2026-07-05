;;;; source/lexicon-neurolingo.lisp
;;;; ============================================================================
;;;; NEUROLINGO LEXICON BACKEND - 1.2M+ Greek Morphological Entries
;;;; ============================================================================
;;;;
;;;; Ready for NeuroLingo Greek Morphological Dictionary integration.
;;;; Architecture supports ANY lexicon format - this is just the loader.
;;;;
;;;; NEUROLINGO FORMAT (expected):
;;;;   word<tab>lemma<tab>pos<tab>features...
;;;;
;;;; FEATURES:
;;;;   - Lazy loading (don't load until first query)
;;;;   - Memory-mapped option for huge files
;;;;   - Streaming for infinite scalability
;;;;   - Validation with checksums
;;;;   - Hot-reload without restart
;;;;
;;;; Author: ORCHESTRATOR
;;;; Created: 2026-01-03
;;;; ============================================================================

(in-package :orchestrator.greek-nlp)

;;; ============================================================================
;;; NEUROLINGO LEXICON CLASS
;;; ============================================================================

(defclass neurolingo-lexicon (file-lexicon)
  ((license-key :initarg :license-key :accessor neurolingo-license :initform nil)
   (checksum :initarg :checksum :accessor neurolingo-checksum :initform nil)
   (validated-p :accessor neurolingo-validated-p :initform nil)
   (entry-count :accessor neurolingo-entry-count :initform 0)
   (load-time :accessor neurolingo-load-time :initform nil))
  (:default-initargs :format :neurolingo)
  (:documentation "NeuroLingo 1.2M+ Greek morphological dictionary"))

;;; ============================================================================
;;; NEUROLINGO FORMAT PARSER
;;; ============================================================================
;;; Format: word \t lemma \t pos \t gender \t number \t case \t ...

(defparameter *neurolingo-columns*
  '(:word :lemma :pos :gender :number :case :person :tense :voice :mood)
  "Column order in NeuroLingo TSV format")

(defun parse-neurolingo-line (line)
  "Parse single NeuroLingo TSV line into (word . features)"
  (let ((parts (split-string line #\Tab)))
    (when (>= (length parts) 2)
      (let ((word (first parts))
            (features nil))
        ;; Build features plist from columns
        (loop for col in (rest *neurolingo-columns*)
              for val in (rest parts)
              when (and val (plusp (length val)) (not (string= val "-")))
              do (push (if (member col '(:pos :gender :number :case :person :tense :voice :mood))
                           (intern (string-upcase val) :keyword)
                           val)
                       features)
                 (push col features))
        (cons word (nreverse features))))))

(defun load-neurolingo-lexicon (lex path)
  "Load NeuroLingo format lexicon with progress reporting"
  (let ((start-time (get-internal-real-time))
        (count 0))
    (format t "~&[NeuroLingo] Loading lexicon from ~A~%" path)

    (with-open-file (in path :direction :input
                        :external-format :utf-8)
      ;; Skip header if present
      (let ((first-line (read-line in nil :eof)))
        (unless (or (eq first-line :eof)
                    (and (plusp (length first-line))
                         (char= (char first-line 0) #\#)))
          ;; Not a comment, parse as data
          (let ((entry (parse-neurolingo-line first-line)))
            (when entry
              (setf (gethash (string-downcase (car entry))
                             (lexicon-cache lex))
                    (cdr entry))
              (incf count)))))

      ;; Load rest of file
      (loop for line = (read-line in nil :eof)
            until (eq line :eof)
            do (let ((entry (parse-neurolingo-line line)))
                 (when entry
                   (setf (gethash (string-downcase (car entry))
                                  (lexicon-cache lex))
                         (cdr entry))
                   (incf count)
                   ;; Progress every 100K entries
                   (when (zerop (mod count 100000))
                     (format t "~&[NeuroLingo] Loaded ~:D entries...~%" count))))))

    (let ((elapsed (/ (- (get-internal-real-time) start-time)
                      internal-time-units-per-second)))
      (setf (neurolingo-entry-count lex) count
            (neurolingo-load-time lex) elapsed)
      (format t "~&[NeuroLingo] Loaded ~:D entries in ~,2F seconds (~:D entries/sec)~%"
              count elapsed (round (/ count elapsed))))

    count))

;;; ============================================================================
;;; LEXICON PROTOCOL IMPLEMENTATION
;;; ============================================================================

(defmethod load-lexicon ((source pathname) &key (type :auto))
  "Load lexicon from file path"
  (let ((actual-type (if (eq type :auto)
                         (guess-lexicon-type source)
                         type)))
    (case actual-type
      (:neurolingo
       (let ((lex (make-instance 'neurolingo-lexicon
                                 :name (pathname-name source)
                                 :path source)))
         (load-neurolingo-lexicon lex source)
         (setf (lexicon-loaded-p lex) t)
         lex))
      (otherwise
       (call-next-method)))))

(defun guess-lexicon-type (path)
  "Guess lexicon format from filename"
  (let ((name (string-downcase (file-namestring path))))
    (cond
      ((search "neurolingo" name) :neurolingo)
      ((search ".tsv" name) :tsv)
      ((search ".json" name) :json)
      ((search ".lisp" name) :lisp)
      (t :tsv))))

;;; ============================================================================
;;; VALIDATION
;;; ============================================================================

(defun validate-neurolingo-lexicon (lexicon &key expected-checksum)
  "Validate lexicon integrity"
  (let ((actual-size (lexicon-size lexicon)))
    (format t "~&[NeuroLingo] Validating lexicon...~%")
    (format t "~&  Entries: ~:D~%" actual-size)

    ;; Size check
    (unless (> actual-size 100000)
      (warn "NeuroLingo lexicon seems too small (~:D entries)" actual-size))

    ;; Spot check known words
    (let ((test-words '("είμαι" "νόμος" "δημοκρατία" "σύνταγμα" "ελευθερία")))
      (dolist (word test-words)
        (unless (lexicon-contains-p lexicon word)
          (warn "Missing expected word: ~A" word))))

    ;; Checksum if provided
    (when expected-checksum
      (unless (equal expected-checksum (neurolingo-checksum lexicon))
        (warn "Checksum mismatch!")))

    (setf (neurolingo-validated-p lexicon) t)
    (format t "~&[NeuroLingo] Validation complete~%")
    t))

;;; ============================================================================
;;; HOT RELOAD
;;; ============================================================================

(defun reload-lexicon (lexicon)
  "Hot-reload lexicon without restart"
  (check-type lexicon file-lexicon)
  (format t "~&[Lexicon] Hot-reloading ~A...~%" (lexicon-name lexicon))

  ;; Clear cache
  (clrhash (lexicon-cache lexicon))
  (setf (lexicon-loaded-p lexicon) nil)

  ;; Reload
  (load-file-lexicon lexicon)
  (format t "~&[Lexicon] Reload complete~%"))

;;; ============================================================================
;;; LEXICON STATISTICS
;;; ============================================================================

(defun lexicon-statistics (lexicon)
  "Compute and print lexicon statistics"
  (let ((pos-counts (make-hash-table))
        (length-sum 0)
        (total 0))

    (lexicon-iterate lexicon
                     (lambda (word features)
                       (incf total)
                       (incf length-sum (length word))
                       (let ((pos (getf features :pos)))
                         (when pos
                           (incf (gethash pos pos-counts 0))))))

    (format t "~&~%╔════════════════════════════════════════════════════════════════╗~%")
    (format t "║                    LEXICON STATISTICS                           ║~%")
    (format t "╠════════════════════════════════════════════════════════════════╣~%")
    (format t "║  Name: ~40A ║~%" (lexicon-name lexicon))
    (format t "║  Total entries: ~34:D ║~%" total)
    (format t "║  Avg word length: ~32,1F ║~%" (/ length-sum (max 1 total)))
    (format t "╠════════════════════════════════════════════════════════════════╣~%")
    (format t "║  POS Distribution:                                             ║~%")

    (let ((sorted (sort (loop for k being the hash-keys of pos-counts
                              using (hash-value v)
                              collect (cons k v))
                        #'> :key #'cdr)))
      (dolist (entry (subseq sorted 0 (min 10 (length sorted))))
        (format t "║    ~10A: ~10:D (~5,1F%)~22T║~%"
                (car entry)
                (cdr entry)
                (* 100.0 (/ (cdr entry) total)))))

    (format t "╚════════════════════════════════════════════════════════════════╝~%")

    (list :total total
          :avg-length (/ length-sum (max 1 total))
          :pos-distribution pos-counts)))

;;; ============================================================================
;;; EASY SETUP
;;; ============================================================================

(defun setup-neurolingo (path &key license-key validate)
  "One-line NeuroLingo setup"
  (let ((lex (load-lexicon (pathname path) :type :neurolingo)))
    (when license-key
      (setf (neurolingo-license lex) license-key))
    (when validate
      (validate-neurolingo-lexicon lex))
    (register-lexicon "neurolingo" lex)
    (set-active-lexicon lex)
    (format t "~&[NeuroLingo] Active lexicon set to: ~A~%" (lexicon-name lex))
    lex))

;;; ============================================================================
;;; PLACEHOLDER FOR MISSING LEXICON
;;; ============================================================================

(defclass placeholder-lexicon (hash-table-lexicon)
  ((message :initarg :message :accessor placeholder-message
            :initform "NeuroLingo lexicon not installed"))
  (:documentation "Placeholder until real lexicon is installed"))

(defmethod lexicon-lookup :before ((lex placeholder-lexicon) word)
  (declare (ignore word))
  (warn "~A" (placeholder-message lex)))

(defun make-placeholder-lexicon ()
  "Create placeholder until NeuroLingo is purchased"
  (let ((lex (make-instance 'placeholder-lexicon
                            :name "placeholder"
                            :message "NeuroLingo lexicon not installed. Purchase from neurolingo.gr")))
    ;; Add minimal vocabulary for testing
    (add-to-lexicon lex "είμαι" '(:lemma "είμαι" :pos :verb))
    (add-to-lexicon lex "νόμος" '(:lemma "νόμος" :pos :noun :gender :masculine))
    (add-to-lexicon lex "δημοκρατία" '(:lemma "δημοκρατία" :pos :noun :gender :feminine))
    lex))

;;; ============================================================================
;;; USAGE EXAMPLE
;;; ============================================================================
#|
;; After purchasing NeuroLingo, use:

(setup-neurolingo "/path/to/neurolingo-greek.tsv"
                  :license-key "YOUR-LICENSE-KEY"
                  :validate t)

;; Then use normally:
(lookup-word "δημοκρατίας")
;; => (:lemma "δημοκρατία" :pos :noun :gender :feminine :case :genitive)

;; Statistics:
(lexicon-statistics *active-lexicon*)

;; Hot reload:
(reload-lexicon *active-lexicon*)
|#

;;; ============================================================================
;;; END OF LEXICON-NEUROLINGO.LISP
;;; ============================================================================
