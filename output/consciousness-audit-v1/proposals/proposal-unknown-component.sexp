(:proposal
 :id "consciousness-unknown-component"
 :type :code
 :legal-critical t
 :affected-files ("source/not-a-real-lawmax-file.lisp")
 :affected-components ("file:source/not-a-real-lawmax-file.lisp")
 :affected-capabilities ("υπαγωγή")
 :affected-contracts ("subsume")
 :purpose "Audit proposal with unknown component"
 :expected-improvement (:metric "trace-coverage" :from 90 :to 95)
 :rollback (:method :restore-previous-hash :files ("source/not-a-real-lawmax-file.lisp"))
 :revalidation-plan (:gates ("--subsumption-gate"))
 :human-approval (:by "external-audit" :reason "consciousness-audit"))
