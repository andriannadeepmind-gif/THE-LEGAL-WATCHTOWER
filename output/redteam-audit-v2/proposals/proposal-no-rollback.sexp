(:proposal
 :id "redteam-no-rollback"
 :type :code
 :legal-critical t
 :affected-files ("source/legal-subsumption.lisp")
 :affected-capabilities ("υπαγωγή")
 :affected-contracts ("subsume")
 :purpose "Red-team proposal with no rollback"
 :expected-improvement (:metric "subsumption-accuracy" :from 1 :to 2)
 :revalidation-plan (:gates ("--subsumption-gate" "--draft-gate"))
 :human-approval (:by "creator" :reason "red-team"))
