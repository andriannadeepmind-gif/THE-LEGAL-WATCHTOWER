;;;; session-handoff.lisp
;;;; Session management and AI handoff functionality
;;;; Proper session lifecycle and state management

(defpackage :orchestrator.session
  (:use :cl :alexandria :local-time :bordeaux-threads)
  (:export #:session
           #:make-session
           #:session-id
           #:session-state
           #:session-data
           #:session-timestamp
           #:session-user
           #:session-get            ; NEW: Export for testing
           #:session-set            ; NEW: Export for testing
           #:session-remove
           #:save-session
           #:load-session
           #:close-session
           #:list-sessions
           #:*active-sessions*
           #:with-session
           #:handoff-to-ai
           #:ai-handoff-context
           #:create-handoff-context
           #:serialize-session-state))

(in-package :orchestrator.session)

;;;; ========================================================================
;;;; CONSTANTS
;;;; ========================================================================

(defconstant +default-session-timeout-hours+ 24
  "Default session timeout in hours")

(defconstant +max-session-data-size+ 10000
  "Maximum number of entries in session data")

(defconstant +session-id-length+ 32
  "Length of session ID string")

;;;; ========================================================================
;;;; SESSION CLASS
;;;; ========================================================================

(defclass session ()
  ((id
    :initarg :id
    :accessor session-id
    :type string
    :documentation "Unique session identifier")
   
   (user
    :initarg :user
    :accessor session-user
    :initform "system"
    :type string
    :documentation "User associated with session")
   
   (state
    :initarg :state
    :accessor session-state
    :initform :active
    :type (member :active :suspended :closed)
    :documentation "Current session state")
   
   (data
    :initform (make-hash-table :test 'equal)
    :accessor session-data
    :documentation "Session data storage")
   
   (created-at
    :initform (local-time:now)
    :accessor session-timestamp
    :type timestamp
    :documentation "Session creation timestamp")

   (last-activity
    :initform (local-time:now)
    :accessor session-last-activity
    :type timestamp
    :documentation "Last activity timestamp")
   
   (lock
    :initform (make-lock "session-lock")
    :accessor session-lock
    :documentation "Lock for thread-safe operations")))

;;;; ========================================================================
;;;; GLOBAL SESSION REGISTRY
;;;; ========================================================================

(defvar *active-sessions* (make-hash-table :test 'equal)
  "Registry of active sessions")

(defvar *sessions-lock* (make-lock "sessions-registry-lock")
  "Lock for session registry operations")

;;;; ========================================================================
;;;; SESSION MANAGEMENT
;;;; ========================================================================

(defun generate-session-id ()
  "Generate unique session ID"
  (format nil "sess-~A-~A"
          (format-timestring nil (local-time:now) :format '(:year :month :day))
          (random 1000000000)))

(defun make-session (&key user (state :active))
  "Create a new session"
  (declare (type (or null string) user))
  (declare (type (member :active :suspended :closed) state))
  (declare (optimize (speed 3) (safety 1)))
  (check-type state (member :active :suspended :closed))
  (let ((session (make-instance 'session
                                :id (generate-session-id)
                                :user (or user "system")
                                :state state)))
    (with-lock-held (*sessions-lock*)
      (setf (gethash (session-id session) *active-sessions*) session))
    session))

(defun get-session (session-id)
  "Retrieve session by ID"
  (declare (type string session-id))
  (declare (optimize (speed 3) (safety 1)))
  (check-type session-id string)
  (with-lock-held (*sessions-lock*)
    (gethash session-id *active-sessions*)))

(defun close-session (session-id)
  "Close and remove session"
  (declare (type string session-id))
  (declare (optimize (speed 3) (safety 1)))
  (check-type session-id string)
  (let ((session (get-session session-id)))
    (when session
      (with-lock-held ((session-lock session))
        (setf (session-state session) :closed))
      (with-lock-held (*sessions-lock*)
        (remhash session-id *active-sessions*))
      t)))

(defun list-sessions ()
  "List all active sessions"
  (declare (optimize (speed 3) (safety 1)))
  (with-lock-held (*sessions-lock*)
    (loop for session being the hash-values of *active-sessions*
          collect (list :id (session-id session)
                       :user (session-user session)
                       :state (session-state session)
                       :created-at (session-timestamp session)
                       :last-activity (session-last-activity session)))))

;;;; ========================================================================
;;;; SESSION DATA OPERATIONS
;;;; ========================================================================

(defun session-get (session key &optional default)
  "Get value from session data"
  (declare (type session session))
  (declare (type string key))
  (declare (optimize (speed 3) (safety 1)))
  (check-type session session)
  (check-type key string)
  (with-lock-held ((session-lock session))
    (gethash key (session-data session) default)))

(defun session-set (session key value)
  "Set value in session data"
  (declare (type session session))
  (declare (type string key))
  (declare (optimize (speed 3) (safety 1)))
  (check-type session session)
  (check-type key string)
  (with-lock-held ((session-lock session))
    (setf (gethash key (session-data session)) value)
    (setf (session-last-activity session) (local-time:now))
    value))

(defun session-remove (session key)
  "Remove key from session data"
  (declare (type session session))
  (declare (type string key))
  (declare (optimize (speed 3) (safety 1)))
  (check-type session session)
  (check-type key string)
  (with-lock-held ((session-lock session))
    (remhash key (session-data session))))

(defmacro with-session ((var session-id-or-session &key (create-if-missing t)) &body body)
  "Execute body with session bound to var"
  (with-gensyms (sess-id)
    `(let* ((,sess-id (if (typep ,session-id-or-session 'session)
                         (session-id ,session-id-or-session)
                         ,session-id-or-session))
            (,var (or (get-session ,sess-id)
                     ,(when create-if-missing
                        `(make-session :user "system")))))
       (unless ,var
         (error "Session ~A not found" ,sess-id))
       (unwind-protect
            (progn ,@body)
         (setf (session-last-activity ,var) (local-time:now))))))

;;;; ========================================================================
;;;; SESSION PERSISTENCE
;;;; ========================================================================

(defun serialize-session-state (session)
  "Serialize session state to a plist"
  (declare (type session session))
  (declare (optimize (speed 3) (safety 1)))
  (check-type session session)
  (with-lock-held ((session-lock session))
    (list :id (session-id session)
          :user (session-user session)
          :state (session-state session)
          :created-at (format-timestring nil (session-timestamp session))
          :last-activity (format-timestring nil (session-last-activity session))
          :data (let ((data-list nil))
                  (maphash (lambda (k v)
                            (push (cons k v) data-list))
                          (session-data session))
                  data-list))))

(defun save-session (session filepath)
  "Save session to file"
  (declare (type session session))
  (declare (type (or string pathname) filepath))
  (declare (optimize (speed 3) (safety 1)))
  (check-type session session)
  (let ((serialized (serialize-session-state session)))
    (with-open-file (out filepath
                        :direction :output
                        :if-exists :supersede
                        :if-does-not-exist :create)
      (prin1 serialized out))
    filepath))

(defun load-session (filepath)
  "Load session from file"
  (declare (type (or string pathname) filepath))
  (declare (optimize (speed 3) (safety 1)))
  (with-open-file (in filepath :direction :input)
    (let* ((data (read in))
           (session (make-instance 'session
                                  :id (getf data :id)
                                  :user (getf data :user)
                                  :state (getf data :state))))
      ;; Restore session data
      (loop for (key . value) in (getf data :data)
            do (session-set session key value))
      
      ;; Register session
      (with-lock-held (*sessions-lock*)
        (setf (gethash (session-id session) *active-sessions*) session))
      
      session)))

;;;; ========================================================================
;;;; AI HANDOFF CONTEXT
;;;; ========================================================================

(defclass ai-handoff-context ()
  ((session-id
    :initarg :session-id
    :accessor handoff-session-id
    :type string
    :documentation "Session being handed off")
   
   (context-data
    :initarg :context-data
    :accessor handoff-context-data
    :type list
    :documentation "Context data for AI")
   
   (task-description
    :initarg :task-description
    :accessor handoff-task-description
    :type string
    :documentation "Description of task for AI")
   
   (corpus-state
    :initarg :corpus-state
    :accessor handoff-corpus-state
    :initform nil
    :documentation "Current corpus processing state")
   
   (timestamp
    :initform (local-time:now)
    :accessor handoff-timestamp
    :type timestamp
    :documentation "Handoff timestamp")))

(defun create-handoff-context (session &key task-description corpus-state additional-context)
  "Create AI handoff context from session"
  (declare (type session session))
  (declare (type (or null string) task-description))
  (declare (optimize (speed 3) (safety 1)))
  (check-type session session)
  (make-instance 'ai-handoff-context
                 :session-id (session-id session)
                 :task-description task-description
                 :corpus-state corpus-state
                 :context-data (append
                               (list :session-data (serialize-session-state session))
                               additional-context)))

(defun handoff-to-ai (session &key task-description corpus-state additional-context)
  "Prepare session for AI handoff"
  (declare (type session session))
  (declare (type (or null string) task-description))
  (declare (optimize (speed 3) (safety 1)))
  (check-type session session)
  (let ((context (create-handoff-context session
                                        :task-description task-description
                                        :corpus-state corpus-state
                                        :additional-context additional-context)))
    ;; Suspend session during AI processing
    (with-lock-held ((session-lock session))
      (setf (session-state session) :suspended)
      (session-set session :handoff-context context))
    
    ;; Return handoff context
    context))

(defun resume-from-ai (session-id &key ai-results)
  "Resume session after AI processing"
  (let ((session (get-session session-id)))
    (unless session
      (error "Session ~A not found" session-id))
    
    (with-lock-held ((session-lock session))
      (setf (session-state session) :active)
      (when ai-results
        (session-set session :ai-results ai-results))
      (session-remove session :handoff-context))
    
    session))

;;;; ========================================================================
;;;; SESSION CLEANUP
;;;; ========================================================================

(defun cleanup-expired-sessions (&key (timeout-hours 24))
  "Clean up sessions inactive for longer than timeout"
  (declare (type integer timeout-hours))
  (declare (optimize (speed 3) (safety 1)))
  (check-type timeout-hours integer)
  (let ((cutoff-time (timestamp- (local-time:now) timeout-hours :hour))
        (removed-count 0))
    (with-lock-held (*sessions-lock*)
      (maphash (lambda (id session)
                 (when (timestamp< (session-last-activity session) cutoff-time)
                   (remhash id *active-sessions*)
                   (incf removed-count)))
               *active-sessions*))
    removed-count))

;;;; ========================================================================
;;;; INITIALIZATION
;;;; ========================================================================

(defun initialize-session-manager ()
  "Initialize session management system"
  (declare (optimize (speed 3) (safety 1)))
  (clrhash *active-sessions*)
  (values))

;; Initialize on load
(initialize-session-manager)
