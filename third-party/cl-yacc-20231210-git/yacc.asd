;;; cl-yacc.asd — ASDF system definition
;;; Provides the "yacc" system name (as required by plexippus-xpath)
;;;
;;; This is the authoritative upstream cl-yacc by Juliusz Chroboczek
;;; (https://www.irif.fr/~jch/software/cl-yacc/, MIT licensed). The package
;;; definition is self-contained inside yacc.lisp, so a single component is used.

(defsystem "yacc"
  :name        "cl-yacc"
  :description "LALR(1) Parser Generator for Common Lisp"
  :author      "Juliusz Chroboczek"
  :license     "MIT"
  :version     "0.3"
  :serial      t
  :components  ((:file "yacc")))
