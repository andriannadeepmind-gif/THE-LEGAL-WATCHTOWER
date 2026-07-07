(:proposal
 :id "consciousness-no-rollback"
 :type :code
 :legal-critical t
 :affected-files ("source/legal-subsumption.lisp")
 :affected-capabilities ("υπαγωγή")
 :affected-contracts ("subsume")
 :purpose "Audit proposal with no rollback"
 :expected-improvement (:metric "trace-coverage" :from 90 :to 95)
 :revalidation-plan (:gates ("--subsumption-gate" "--provenance-gate"))
 :human-approval (:by "external-audit" :reason "consciousness-audit"))
