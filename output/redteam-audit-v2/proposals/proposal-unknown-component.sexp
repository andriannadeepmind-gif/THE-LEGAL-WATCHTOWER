(:proposal
 :id "redteam-unknown-component"
 :type :code
 :legal-critical t
 :affected-files ("source/does-not-exist-redteam.lisp")
 :affected-components ("file:source/does-not-exist-redteam.lisp")
 :affected-capabilities ("υπαγωγή")
 :affected-contracts ("subsume")
 :purpose "Red-team proposal with unknown component"
 :expected-improvement (:metric "contract-coverage" :from 0 :to 1)
 :rollback (:method :restore-previous-hash :files ("source/does-not-exist-redteam.lisp"))
 :revalidation-plan (:gates ("--subsumption-gate"))
 :human-approval nil)
