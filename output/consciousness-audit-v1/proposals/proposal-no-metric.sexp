(:proposal
 :id "consciousness-no-metric"
 :type :code
 :legal-critical t
 :affected-files ("source/legal-subsumption.lisp")
 :affected-capabilities ("υπαγωγή")
 :affected-contracts ("subsume")
 :purpose "Audit proposal with no measurable improvement"
 :rollback (:method :restore-previous-hash :files ("source/legal-subsumption.lisp"))
 :revalidation-plan (:gates ("--subsumption-gate" "--provenance-gate"))
 :human-approval (:by "external-audit" :reason "consciousness-audit"))
