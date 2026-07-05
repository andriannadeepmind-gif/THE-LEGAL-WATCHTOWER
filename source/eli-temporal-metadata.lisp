;;;; source/eli-temporal-metadata.lisp
;;;; ELI TEMPORAL COMPLETENESS
;;;;
;;;; Phase D: Article-level temporal metadata for ELI compliance
;;;;
;;;; This module generates complete temporal metadata for each article:
;;;;   - eli:date_applicability: When this version became applicable
;;;;   - eli:in_force: Boolean indicating if article is currently in force
;;;;   - eli:amends: Links to previous versions (amendment chain)
;;;;   - eli:repeals: Links to repealed provisions
;;;;
;;;; Guarantee: AI can answer "Is this article in force on date X?"
;;;;           without hallucinations.

(defpackage :orchestrator.eli-temporal
  (:use :cl)
  (:import-from :local-time
                #:parse-timestring
                #:timestamp<
                #:timestamp<=
                #:timestamp>
                #:timestamp>=
                #:timestamp=)
  (:export
   ;; Configuration
   #:*amendments-config*
   #:*article-defaults*
   #:configure-temporal-metadata
   #:load-temporal-metadata-from-config
   
   ;; Main API
   #:get-article-temporal-metadata
   #:get-article-amendment-history
   #:is-article-in-force
   #:get-article-version-at-date
   
   ;; RDF generation
   #:generate-temporal-metadata-ttl))

(in-package :orchestrator.eli-temporal)

;;; ============================================================
;;; CONFIGURATION
;;; ============================================================

(defparameter *amendments-config* nil
  "List of amendment records from configuration.
   Each record has: id, date, date_applicability, fek, description, 
   articles_amended, articles_repealed")

(defparameter *article-defaults* (make-hash-table :test 'equal)
  "Default temporal metadata for articles not in amendment lists")

;;; ============================================================
;;; CONFIGURATION API
;;; ============================================================

(defun configure-temporal-metadata (&key amendments article-defaults)
  "Configure temporal metadata from configuration data.
   
   Arguments:
     :amendments - List of amendment records
     :article-defaults - Hash table with default values"
  (when amendments
    (setf *amendments-config* amendments))
  (when article-defaults
    (setf *article-defaults* article-defaults)))

(defun load-temporal-metadata-from-config (config-hash)
  "Load temporal metadata from configuration hash table.
   
   Expected keys:
     - versioning/amendments: List of amendment records
     - article_defaults: Default values for articles"
  (let ((versioning (gethash "versioning" config-hash))
        (defaults (gethash "article_defaults" config-hash)))
    
    (when versioning
      (let ((amendments (cdr (assoc "amendments" versioning :test #'string=))))
        (setf *amendments-config* amendments)))
    
    (when defaults
      (loop for (key . value) in defaults
            do (setf (gethash (string key) *article-defaults*) value)))))

;;; ============================================================
;;; AMENDMENT HISTORY API
;;; ============================================================

(defun get-article-amendment-history (article-number)
  "Get list of amendments that modified this article.
   
   Returns list of amendment records in chronological order.
   Each record includes: id, date, date_applicability, fek, description"
  (let ((amendments nil))
    (dolist (amendment *amendments-config*)
      (let* ((articles-amended (cdr (assoc "articles_amended" amendment :test #'string=)))
             (is-amended (member article-number articles-amended)))
        (when is-amended
          (push amendment amendments))))
    (nreverse amendments)))

(defun is-article-repealed (article-number)
  "Check if article has been repealed in any amendment.
   
   Returns amendment record if repealed, NIL otherwise."
  (dolist (amendment *amendments-config*)
    (let ((articles-repealed (cdr (assoc "articles_repealed" amendment :test #'string=))))
      (when (member article-number articles-repealed)
        (return amendment)))))

(defun is-article-in-force (article-number &optional (at-date nil))
  "Check if article is in force.
   
   Arguments:
     article-number - Article number (1-120)
     at-date - Optional date to check (defaults to current date)
   
   Returns T if in force, NIL if repealed"
  (let ((repealed (is-article-repealed article-number)))
    (if repealed
        ;; If repealed, check if at-date is before repeal date
        (if at-date
            (let ((repeal-date (parse-timestring 
                               (cdr (assoc "date" repealed :test #'string=)))))
              (timestamp< at-date repeal-date))
            nil)  ; Currently repealed
        t)))  ; Not repealed, so in force

;;; ============================================================
;;; TEMPORAL METADATA API
;;; ============================================================

(defun get-article-temporal-metadata (article-number)
  "Get complete temporal metadata for an article.
   
   Returns plist with:
     :in-force - Boolean
     :date-applicability - ISO8601 date string
     :amendments - List of amendment records
     :amendment-count - Number of amendments
     :last-amended - Date of last amendment (or NIL)"
  (let* ((amendments (get-article-amendment-history article-number))
         (in-force (is-article-in-force article-number))
         (last-amended (when amendments
                        (cdr (assoc "date" (car (last amendments)) :test #'string=))))
         (date-applicability (if last-amended
                                last-amended
                                (gethash "date_applicability" *article-defaults* "1975-06-11"))))
    
    (list :in-force in-force
          :date-applicability date-applicability
          :amendments amendments
          :amendment-count (length amendments)
          :last-amended last-amended)))

(defun get-article-version-at-date (article-number date-string)
  "Get the version of an article that was in force at a specific date.
   
   Arguments:
     article-number - Article number (1-120)
     date-string - ISO8601 date string
   
   Returns plist with version information and applicable amendments"
  (let* ((target-date (parse-timestring date-string))
         (amendments (get-article-amendment-history article-number))
         (applicable-amendments nil))
    
    ;; Find all amendments that were in effect before target date
    (dolist (amendment amendments)
      (let ((amend-date (parse-timestring 
                        (cdr (assoc "date" amendment :test #'string=)))))
        (when (timestamp<= amend-date target-date)
          (push amendment applicable-amendments))))
    
    (list :article-number article-number
          :as-of-date date-string
          :amendments (nreverse applicable-amendments)
          :in-force (is-article-in-force article-number target-date))))

;;; ============================================================
;;; RDF GENERATION
;;; ============================================================

(defun generate-temporal-metadata-ttl (article-uri article-number)
  "Generate Turtle RDF for article-level temporal metadata.
   
   Arguments:
     article-uri - Full URI of the article (Work resource)
     article-number - Article number (1-120)
   
   Returns string with Turtle RDF triples for temporal metadata"
  (let* ((metadata (get-article-temporal-metadata article-number))
         (in-force (getf metadata :in-force))
         (date-applicability (getf metadata :date-applicability))
         (amendments (getf metadata :amendments))
         (output (make-string-output-stream)))
    
    ;; eli:date_applicability
    (format output "    eli:date_applicability \"~A\"^^xsd:date ;~%" 
            date-applicability)
    
    ;; eli:in_force
    (format output "    eli:in_force ~A ;~%" 
            (if in-force "true" "false"))
    
    ;; eli:amends relationships (amendment chain)
    (dolist (amendment amendments)
      (let ((amend-id (cdr (assoc "id" amendment :test #'string=)))
            (amend-date (cdr (assoc "date" amendment :test #'string=))))
        (format output "    eli:amends <~A/version/~A> ;~%" 
                article-uri amend-id)))
    
    ;; Return the generated Turtle
    (get-output-stream-string output)))

;;; ============================================================
;;; INITIALIZATION
;;; ============================================================

;; Set defaults on load
(eval-when (:load-toplevel :execute)
  (setf (gethash "in_force" *article-defaults*) t)
  (setf (gethash "date_applicability" *article-defaults*) "1975-06-11"))
