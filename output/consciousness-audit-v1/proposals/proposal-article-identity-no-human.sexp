(:proposal
 :id "consciousness-article-identity-no-human"
 :type :article-identity
 :legal-critical t
 :affected-files ("source/canonical-article-id.lisp")
 :affected-capabilities ("ταυτότητα-άρθρων")
 :affected-contracts ("article-identity-management")
 :purpose "Audit article identity change without human approval"
 :expected-improvement (:metric "identity-debt" :from 10 :to 5)
 :rollback (:method :restore-previous-hash :files ("source/canonical-article-id.lisp"))
 :revalidation-plan (:gates ("--component-gate" "--contract-gate" "--provenance-gate")))
