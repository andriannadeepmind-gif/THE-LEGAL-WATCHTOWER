;;; build.lisp - Orchestrator build script
;;; HERMETIC BUILD - Uses only third-party/ with explicit versions
;;; Google-Standard: Muffle notes for third-party, strict for our code

(require :asdf)
(require :sb-posix)  ; Required by log4cl

;; Production optimization settings
(declaim (optimize (speed 3) (safety 1) (debug 0)))

;; Configure ASDF paths (hermetic layout - no Quicklisp)
(setf asdf:*central-registry*
      (list #p"/app/"
            #p"/app/systems/orchestrator-spec/"
            #p"/app/systems/orchestrator-model/"
            #p"/app/systems/orchestrator-core/"
            #p"/app/systems/orchestrator-engine-sbcl/"
            #p"/app/systems/orchestrator-cli/"
            #p"/app/systems/orchestrator-gr-syntagma/"
            #p"/app/systems/orchestrator-meta/"
            #p"/app/systems/orchestrator-ai-core/"
            #p"/app/systems/orchestrator-infrastructure/"
            #p"/app/systems/orchestrator-omega-modules/"
            #p"/app/systems/orchestrator-epistemic/"
            #p"/app/tests/"))

;; Muffle compiler notes only for third-party libraries
(locally
  (declare (sb-ext:muffle-conditions sb-ext:compiler-note))
  (asdf:load-system :alexandria)
  (asdf:load-system :log4cl))  ; Load log4cl before our systems

;; Our code: strict compilation, do not muffle anything
(asdf:load-system :orchestrator-core-runtime)

;; ΚΑΘΡΕΦΤΗΣ: πάγωμα ταυτοτήτων συστατικών (SHA-256 + έδρες δηλώσεων) ΤΩΡΑ,
;; που οι πηγές υπάρχουν — το runtime image δεν τις κουβαλά· το μητρώο
;; συστατικών θα διαβάζει το manifest (deployment/self/component-manifest.sexp).
(format t "~%Freezing component manifest: ~D files~%"
        (orchestrator.component-scan:freeze-components!))

;; Build executable (CLI entrypoint)
(sb-ext:save-lisp-and-die "/app/orchestrator.core"
                          :toplevel #'orchestrator.cli:main
                          :executable t
                          :save-runtime-options t  ; Maximize standalone exec probability
                          :compression 9
                          :purify t)
