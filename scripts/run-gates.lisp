#!/usr/bin/env -S sbcl --script
;;;; scripts/run-gates.lisp
;;;; ============================================================================
;;;; THIN WRAPPER → --gates (η ΜΙΑ κανονική ολομέλεια)
;;;; ============================================================================
;;;;
;;;; Το ιστορικό gate-guards runner (5 πύλες, source/gate-guards.lisp) δεν
;;;; υπάρχει πια — εύρημα εξωτερικού audit (dialogue 0012): το script φόρτωνε
;;;; ανύπαρκτο αρχείο. Η κανονική ολομέλεια είναι το --gates: αυτο-παράγεται
;;;; από το μητρώο εντολών (κάθε εντολή με επίθημα -gate συμμετέχει), ίδια
;;;; έδρα με το CLI — καμία δεύτερη λίστα πυλών πουθενά.
;;;;
;;;; Χρήση (από τη ρίζα του repo):  sbcl --script scripts/run-gates.lisp

(require :asdf)
(require :sb-posix)
(require :sb-bsd-sockets)

(asdf:initialize-source-registry
 `(:source-registry (:tree ,(uiop:getcwd))
                    (:tree ,(merge-pathnames "third-party/" (uiop:getcwd)))
                    :inherit-configuration))

(handler-case (asdf:load-system :orchestrator-cli)
  (error (e)
    (format *error-output* "~%✗ Αποτυχία φόρτωσης orchestrator-cli: ~A~%" e)
    (sb-ext:exit :code 1)))

(sb-ext:exit :code (funcall (find-symbol "RUN-ALL-GATES" :orchestrator.cli)))
