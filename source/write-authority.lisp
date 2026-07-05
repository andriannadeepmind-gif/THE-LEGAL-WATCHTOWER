;;;; source/write-authority.lisp
;;;; GATE-2: WRITE AUTHORITY UNIFICATION

(defpackage #:orchestrator.write-authority
  (:use :cl :uiop)
  (:export #:emit-graph
           #:with-write-authority
           #:*current-write-authority*))

(in-package :orchestrator.write-authority)

(defvar *current-write-authority* nil
  "Dynamic variable tracking current write authority scope.
   Set by WITH-WRITE-AUTHORITY macro.")

(defun emit-graph (content output-path &key authority)
  "Low-level RDF graph write operation with mandatory authority.

   Args:
     content: String content (TTL/RDF) to write
     output-path: File path to write to
     authority: REQUIRED - must be :canonical or :provenance

   Fail-fast guarantees:
     - Errors if AUTHORITY not provided (prevents accidental omission)
     - Errors if authority doesn't match *current-write-authority* (scope violation)
     - Errors if authority not in allowed set

   This is the ONLY authorized write function for RDF content.
   All high-level write functions (write-unified-article-file, etc.) must use this."

  (unless authority
    (error "AUTHORITY parameter is required. Use :authority :canonical or :authority :provenance"))

  (unless (member authority '(:canonical :provenance))
    (error "AUTHORITY must be :canonical or :provenance, got: ~A" authority))

  (when *current-write-authority*
    (unless (eq authority *current-write-authority*)
      (error "Authority scope violation: attempted :authority ~A but current scope is ~A"
             authority *current-write-authority*)))

  (ensure-directories-exist output-path)

  (with-open-file (stream output-path
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (write-string content stream))

  output-path)

(defmacro with-write-authority (authority &body body)
  "Execute BODY with specified write authority scope.

   Args:
     authority: :canonical or :provenance

   All emit-graph calls within BODY must use matching :authority.
   Nested with-write-authority not allowed (prevents confusion).

   Example:
     (with-write-authority (:canonical)
       (emit-graph content path :authority :canonical))
   All emit-graph calls inside must use :authority :canonical."

  `(progn
     (when *current-write-authority*
       (error "Nested WITH-WRITE-AUTHORITY not allowed. Current scope: ~A, attempted: ~A"
              *current-write-authority* ,authority))

     (let ((*current-write-authority* ,authority))
       ,@body)))
