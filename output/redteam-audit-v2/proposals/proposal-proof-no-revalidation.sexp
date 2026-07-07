(:proposal
 :id "redteam-proof-no-revalidation"
 :type :code
 :legal-critical t
 :affected-files ("source/legal-subsumption.lisp")
 :affected-capabilities ("υπαγωγή")
 :affected-contracts ("subsume")
 :purpose "Red-team proposal affects proof-producing function but no revalidation plan"
 :expected-improvement (:metric "subsumption-accuracy" :from 1 :to 2)
 :rollback (:method :restore-previous-hash :files ("source/legal-subsumption.lisp"))
 :human-approval (:by "creator" :reason "red-team"))
