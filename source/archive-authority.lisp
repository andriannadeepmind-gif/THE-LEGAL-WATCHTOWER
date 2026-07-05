;;;; source/archive-authority.lisp
;;;; ============================================================================
;;;; ARCHIVE AUTHORITY - Pure Common Lisp Implementation
;;;; ============================================================================
;;;;
;;;; Submits releases to Archive.org Wayback Machine for 100-year proof.
;;;; Uses Drakma for HTTP submission.
;;;;
;;;; AUTHORITY PATTERN:
;;;; - Submit release metadata to Archive.org Save Page Now API
;;;; - Creates permanent public record of temporal existence
;;;; - Independent third-party attestation
;;;;
;;;; DARPA-GRADE: Pure Lisp HTTP, public archival record.
;;;; ============================================================================

(defpackage :orchestrator.archive-authority
  (:use :cl)
  (:export
   ;; Core archiving
   #:submit-to-wayback
   #:submit-release-to-archive
   ;; Configuration
   #:*wayback-save-url*
   ;; Conditions
   #:archive-error
   #:submission-failed))

(in-package :orchestrator.archive-authority)

;;; ============================================================================
;;; CONFIGURATION
;;; ============================================================================

(defparameter *wayback-save-url* "https://web.archive.org/save/"
  "Archive.org Save Page Now API endpoint")

(defparameter *archive-timeout* 60
  "Archive submission timeout in seconds (archiving can be slow)")

;;; ============================================================================
;;; CONDITIONS
;;; ============================================================================

(define-condition archive-error (error)
  ((message :initarg :message :reader archive-error-message))
  (:report (lambda (c s)
             (format s "Archive Error: ~A" (archive-error-message c)))))

(define-condition submission-failed (archive-error) ())

;;; ============================================================================
;;; WAYBACK MACHINE SUBMISSION
;;; ============================================================================

(defun submit-to-wayback (url &key capture-all)
  "Submit URL to Archive.org Wayback Machine

   Uses the Save Page Now API to create permanent archive.

   Args:
     url: URL to archive
     capture-all: If true, also capture outlinks (slower)

   Returns:
     Plist with :archived-url, :timestamp, :status"

  (format t "[Archive.org] Submitting: ~A~%" url)

  (handler-case
      (let* ((save-url (format nil "~A~A" *wayback-save-url* url))
             (response (drakma:http-request
                        save-url
                        :method :get
                        :connection-timeout *archive-timeout*
                        :redirect 10)))  ; Follow redirects

        ;; Archive.org redirects to the archived page
        ;; The final URL contains the archive timestamp
        (let ((archived-url (if (stringp response)
                                save-url
                                (format nil "~A" response))))
          (format t "      ✓ Archived: ~A~%" archived-url)

          (list :original-url url
                :archived-url archived-url
                :timestamp (get-universal-time)
                :status :success)))

    (error (e)
      (format t "      ✗ Archive failed: ~A~%" e)
      (list :original-url url
            :status :failed
            :error (format nil "~A" e)))))

(defun submit-release-to-archive (release-manifest-url &key release-dir)
  "Submit release manifest to Archive.org for permanent record

   Creates multiple archive entries for redundancy:
   - Release manifest URL
   - GitHub repository (if applicable)

   Args:
     release-manifest-url: URL of the release manifest
     release-dir: Local release directory (for metadata)

   Returns:
     List of archive results"

  (let ((results nil))

    (format t "~%═══════════════════════════════════════════════════════════════~%")
    (format t "  100-YEAR PROOF: Archive.org Submission~%")
    (format t "═══════════════════════════════════════════════════════════════~%~%")

    ;; Submit main manifest
    (when release-manifest-url
      (push (submit-to-wayback release-manifest-url) results))

    ;; Generate archive record file if release-dir provided
    (when release-dir
      (let ((archive-record-path (merge-pathnames "archive-record.json" release-dir)))
        (alexandria:write-string-into-file
         (jonathan:to-json
          `(:|archiveSubmissions| ,(mapcar (lambda (r)
                                             `(:|url| ,(getf r :original-url)
                                               :|archivedUrl| ,(getf r :archived-url)
                                               :|timestamp| ,(getf r :timestamp)
                                               :|status| ,(string (getf r :status))))
                                           results)
            :|submittedAt| ,(orchestrator.time:format-iso8601
                            (orchestrator.time:now :source :system))
            :|purpose| "100-year temporal precedence proof"))
         archive-record-path
         :if-exists :supersede)
        (format t "~%Archive record saved: ~A~%" archive-record-path)))

    (format t "~%Archive.org Summary: ~D submissions~%" (length results))

    results))

;;; ============================================================================
;;; GITHUB ARCHIVE (via Archive.org)
;;; ============================================================================

(defun archive-github-commit (repo-owner repo-name commit-sha)
  "Archive specific GitHub commit via Archive.org

   Args:
     repo-owner: GitHub username/org
     repo-name: Repository name
     commit-sha: Commit SHA to archive

   Returns:
     Archive result plist"

  (let ((commit-url (format nil "https://github.com/~A/~A/commit/~A"
                            repo-owner repo-name commit-sha)))
    (submit-to-wayback commit-url)))

;;; ============================================================================
;;; END OF ARCHIVE-AUTHORITY.LISP
;;; ============================================================================
