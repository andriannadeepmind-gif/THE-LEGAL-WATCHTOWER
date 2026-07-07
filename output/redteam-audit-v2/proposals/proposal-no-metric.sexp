(:proposal
 :id "redteam-no-metric"
 :type :code
 :legal-critical t
 :affected-files ("source/legal-subsumption.lisp")
 :affected-capabilities ("υπαγωγή")
 :affected-contracts ("subsume")
 :purpose "Red-team proposal with no measurable improvement"
 :rollback (:method :restore-previous-hash :files ("source/legal-subsumption.lisp"))
 :revalidation-plan (:gates ("--subsumption-gate" "--draft-gate"))
 :human-approval (:by "creator" :reason "red-team"))
