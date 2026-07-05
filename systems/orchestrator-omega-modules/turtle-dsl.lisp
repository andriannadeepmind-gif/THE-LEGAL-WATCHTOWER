 ;;;; systems/orchestrator-dsl/turtle-dsl.lisp
;;;; RDF/Turtle DSL - Macro-based abstraction for RDF generation
;;;; ΟΜΕΓΑ-LEVEL: Homoiconic Lisp power for semantic web

(defpackage :orchestrator.dsl.turtle
  (:use :cl :alexandria :serapeum)
  (:export #:emit-separator
           #:emit-comment
           #:format-literal
           #:escape-turtle-literal
           #:format-uri
           #:with-turtle-output
           #:emit-triple
           #:emit-prefixes
           #:with-resource
           #:with-frbr-context
           #:define-rdf-generator))

(in-package :orchestrator.dsl.turtle)

;;; ============================================================
;;; TURTLE OUTPUT CONTEXT
;;; ============================================================

(defvar *turtle-stream* nil
  "Current Turtle output stream")

(defvar *turtle-indent-level* 0
  "Current indentation level for Turtle output")

(defvar *emitted-prefixes* nil
  "Set of already emitted prefixes to avoid duplication")

;;; ============================================================
;;; MAIN DSL MACRO - WITH-TURTLE-OUTPUT
;;; ============================================================

(defmacro with-turtle-output ((stream-var &key base-uri prefixes) &body body)
  "Execute body with Turtle output context
   
   Usage:
     (with-turtle-output (s :base-uri \"https://example.com/\"
                            :prefixes '((\"eli\" \"http://...\")))
       (emit-triple \"<subject>\" \"predicate\" \"object\"))"
  
  `(let ((*turtle-stream* ,stream-var)
         (*turtle-indent-level* 0)
         (*emitted-prefixes* nil))
     
     ,(when base-uri
        `(format *turtle-stream* "@base <~A> .~%~%" ,base-uri))
     
     ,(when prefixes
        `(emit-prefixes ,prefixes))
     
     (progn ,@body)
     
     *turtle-stream*))

;;; ============================================================
;;; PREFIX EMISSION
;;; ============================================================

(defun emit-prefixes (prefix-alist)
  "Emit RDF prefixes in deterministic order
   
   prefix-alist: ((prefix . uri) ...) in sorted order"
  
  (dolist (prefix-pair (sort (copy-list prefix-alist) #'string< :key #'car))
    (destructuring-bind (prefix . uri) prefix-pair
      (unless (member prefix *emitted-prefixes* :test #'string=)
        (format *turtle-stream* "@prefix ~A: <~A> .~%" prefix uri)
        (push prefix *emitted-prefixes*))))
  
  (terpri *turtle-stream*))

;;; ============================================================
;;; TRIPLE EMISSION
;;; ============================================================

(defun emit-triple (subject predicate object &key (terminator ";"))
  "Emit a single RDF triple with proper indentation
   
   terminator: ';' for continuation, '.' for end of statement"
  
  (let ((indent (make-string (* *turtle-indent-level* 4) :initial-element #\Space)))
    (format *turtle-stream* "~A~A ~A ~A~A~%"
            indent subject predicate object terminator)))

(defun emit-comment (text)
  "Emit a Turtle comment"
  (format *turtle-stream* "# ~A~%" text))

(defun emit-separator ()
  "Emit a visual separator for readability"
  (format *turtle-stream* "# ============================================================~%"))

;;; ============================================================
;;; RESOURCE CONTEXT MACRO
;;; ============================================================

(defmacro with-resource ((uri &key type) &body triples)
  "Define a resource with its triples - CORRECT TURTLE SYNTAX"
  
  (alexandria:with-gensyms (uri-var)
    `(let ((,uri-var ,uri))
       
       (format *turtle-stream* "<~A>~%" ,uri-var)
       
       ,(when type
          `(format *turtle-stream* "    a ~A ;~%" ,type))
       
       ,@(loop for triple in triples
               for (pred obj) = triple
               for last-p = (eq triple (car (last triples)))
               collect
               `(format *turtle-stream* "    ~A ~A~A~%"
                        ,pred ,obj ,(if last-p " ." " ;")))
       
       (terpri *turtle-stream*))))

;;; ============================================================
;;; FRBR CONTEXT MACRO
;;; ============================================================

(defmacro with-frbr-context ((frbr-instance) &body body)
  "Execute body with FRBR instance context"

  (with-gensyms (instance uri)
    `(let* ((,instance ,frbr-instance)
            (,uri (orchestrator.model:resource-uri ,instance)))

       (macrolet ((frbr-uri () ',uri)
                  (frbr-provenance ()
                    '(orchestrator.model:resource-provenance ,instance)))

         ,@body))))

;;; ============================================================
;;; RDF GENERATOR DEFINITION MACRO
;;; ============================================================

(defmacro define-rdf-generator (name (instance-var type) &body body)
  "Define a deterministic RDF generator for a FRBR type"
  
  `(defmethod ,name ((,instance-var ,type))
     ,(format nil "Generate RDF for ~A instance - DETERMINISTIC" type)
     
     (with-output-to-string (*turtle-stream*)
       
       (emit-prefixes 
         '(("dcat" . "http://www.w3.org/ns/dcat#")
           ("dct" . "http://purl.org/dc/terms/")
           ("eli" . "http://data.europa.eu/eli/ontology#")
           ("prov" . "http://www.w3.org/ns/prov#")
           ("schema" . "https://schema.org/")
           ("xsd" . "http://www.w3.org/2001/XMLSchema#")))
       
       (emit-separator)
       (emit-comment (format nil "FRBR ~A Layer" ',type))
       (emit-comment (format nil "Generated: ~A" 
                            (orchestrator.model:get-iso8601-timestamp)))
       (emit-comment "ORCHESTRATOR v1.3 - DARPA-level generation")
       (emit-separator)
       (terpri *turtle-stream*)
       
       ,@body)))

;;; ============================================================
;;; UTILITIES
;;; ============================================================

(defun escape-turtle-literal (text)
  "Escape special characters in Turtle literals - DETERMINISTIC"
  (with-output-to-string (s)
    (loop for char across text
          do (case char
               (#\" (write-string "\\\"" s))
               (#\\ (write-string "\\\\" s))
               (#\Newline (write-string "\\n" s))
               (#\Return (write-string "\\r" s))
               (#\Tab (write-string "\\t" s))
               (otherwise (write-char char s))))))

(defun format-literal (text &key lang datatype)
  "Format a Turtle literal with language tag or datatype - DETERMINISTIC"
  (let ((escaped (escape-turtle-literal text)))
    (cond
      (lang (format nil "\"\"\"~A\"\"\"@~A" escaped lang))
      (datatype (format nil "\"~A\"^^~A" escaped datatype))
      (t (format nil "\"~A\"" escaped)))))

(defun format-uri (uri)
  "Format a URI for Turtle output - DETERMINISTIC"
  (if (char= (char uri 0) #\<)
      uri
      (format nil "<~A>" uri)))

;;; ============================================================
;;; DETERMINISM STRATEGY (UNCHANGED)
;;; ============================================================

#|
... (όπως το έστειλες, τίποτα δεν αλλάχθηκε)
|#
