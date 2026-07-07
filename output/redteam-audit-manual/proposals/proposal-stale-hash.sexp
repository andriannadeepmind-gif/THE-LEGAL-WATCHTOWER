(:proposal
 :id "redteam-stale-hash"
 :type :code
 :legal-critical t
 :affected-files ("source/legal-subsumption.lisp")
 :expected-source-hashes (("source/legal-subsumption.lisp" . "0000000000000000000000000000000000000000000000000000000000000000"))
 :affected-capabilities ("υπαγωγή")
 :affected-contracts ("subsume")
 :purpose "Red-team proposal with stale/wrong source hash"
 :expected-improvement (:metric "subsumption-accuracy" :from 1 :to 2)
 :rollback (:method :restore-previous-hash :files ("source/legal-subsumption.lisp"))
 :revalidation-plan (:gates ("--subsumption-gate" "--draft-gate"))
 :human-approval (:by "creator" :reason "red-team"))
