;;;; experiment/artifacts/execution-census.sexp — AUTHORITATIVE EXECUTION CENSUS
;;;; ΑΝΑΚΑΛΥΨΗ, όχι αριθμητική ονομάτων. ΣΟΥΙΤΕΣ ≠ CHECKS ≠ ΕΓΓΡΑΦΕΣ ΚΑΤΑΛΟΓΟΥ.

(:lawmax-execution-census/1
 :total-entries 193
 :by-type ((:aggregator 4) (:declared-nonsuite 8) (:declared-suite-exclusion 1) (:e2e 1) (:proof 15) (:self-check 12) (:suite 136) (:suite-fiveam 1) (:test-file-outside-inventory 12) (:tooling-checker 3))
 :note-counting "ΔΙΟΡΘΩΣΗ §14.2: το tests/comparison-test.lisp είναι ΕΝΑ αρχείο, μετρημένο ΜΙΑ φορά ως :declared-suite-exclusion. Αρχεία σουιτών: 136. Εκτελέστηκαν: 136. Gated: 135."
 :note-146 "Το 146 είναι ΕΓΓΡΑΦΕΣ του καταλόγου tests/ (144 .lisp + 2 φάκελοι). ΔΕΝ είναι σουίτες."
 :entries
  (
   (:id "suite:ai-corpus-dump" :path "tests/ai-corpus-dump-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/ai-corpus-dump-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:ai-ingest-manifest" :path "tests/ai-ingest-manifest-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/ai-ingest-manifest-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:akoma-ntoso-emitter" :path "tests/akoma-ntoso-emitter-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/akoma-ntoso-emitter-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:amended-split" :path "tests/amended-split-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/amended-split-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:amendment-accuracy" :path "tests/amendment-accuracy-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/amendment-accuracy-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:amendment-backtest" :path "tests/amendment-backtest-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/amendment-backtest-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:amendment-consolidation-e2e" :path "tests/amendment-consolidation-e2e-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/amendment-consolidation-e2e-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:amendment-extractor" :path "tests/amendment-extractor-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/amendment-extractor-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:amendment-routing" :path "tests/amendment-routing-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/amendment-routing-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:amendment-state" :path "tests/amendment-state-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/amendment-state-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:anomaly-detection" :path "tests/anomaly-detection-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/anomaly-detection-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:architecture-multiplicity" :path "tests/architecture-multiplicity-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/architecture-multiplicity-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:article-identity" :path "tests/article-identity-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/article-identity-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:article-number-fidelity" :path "tests/article-number-fidelity-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/article-number-fidelity-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:artifact-census" :path "tests/artifact-census-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/artifact-census-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:as-known-e2e" :path "tests/as-known-e2e-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/as-known-e2e-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:ast-gate" :path "tests/ast-gate-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/ast-gate-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:ast-persistence" :path "tests/ast-persistence-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/ast-persistence-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:audit-signature-failclosed" :path "tests/audit-signature-failclosed-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/audit-signature-failclosed-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:authority-cross-language" :path "tests/authority-cross-language-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/authority-cross-language-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:authority-evidence-replay" :path "tests/authority-evidence-replay-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/authority-evidence-replay-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:authority-proof-bundle" :path "tests/authority-proof-bundle-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/authority-proof-bundle-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:auto-consolidate" :path "tests/auto-consolidate-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/auto-consolidate-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:auto-update-verdict" :path "tests/auto-update-verdict-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/auto-update-verdict-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:autonomy-consolidation" :path "tests/autonomy-consolidation-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/autonomy-consolidation-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:blockchain-authority" :path "tests/blockchain-authority-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/blockchain-authority-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:bpe-persistence" :path "tests/bpe-persistence-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/bpe-persistence-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:canonical-serialization" :path "tests/canonical-serialization-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/canonical-serialization-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:capability-api" :path "tests/capability-api-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/capability-api-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:capability-gate" :path "tests/capability-gate-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/capability-gate-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:capability-registry" :path "tests/capability-registry-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/capability-registry-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:casegrammar" :path "tests/casegrammar-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/casegrammar-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:citation-authority" :path "tests/citation-authority-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/citation-authority-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:clean-json-format" :path "tests/clean-json-format-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/clean-json-format-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:clean-output" :path "tests/clean-output-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/clean-output-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:cockpit" :path "tests/cockpit-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/cockpit-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:codification-validation" :path "tests/codification-validation-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/codification-validation-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:comparison" :path "tests/comparison-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/comparison-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:consolidation-bridge" :path "tests/consolidation-bridge-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/consolidation-bridge-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:consolidation-engine" :path "tests/consolidation-engine-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/consolidation-engine-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:consolidation-feed" :path "tests/consolidation-feed-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/consolidation-feed-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:constitution-crawler" :path "tests/constitution-crawler-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/constitution-crawler-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:corpus-diff" :path "tests/corpus-diff-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/corpus-diff-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:corpus-eu-links" :path "tests/corpus-eu-links-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/corpus-eu-links-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:corpus-fingerprint" :path "tests/corpus-fingerprint-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/corpus-fingerprint-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:corpus-identity" :path "tests/corpus-identity-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/corpus-identity-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:corpus-intelligence" :path "tests/corpus-intelligence-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/corpus-intelligence-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:corpus-provenance" :path "tests/corpus-provenance-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/corpus-provenance-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:corpus-search" :path "tests/corpus-search-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/corpus-search-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:corpus-service" :path "tests/corpus-service-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/corpus-service-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:corpus-sparql" :path "tests/corpus-sparql-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/corpus-sparql-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:cross-language-verifier" :path "tests/cross-language-verifier-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/cross-language-verifier-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:currentness-34" :path "tests/currentness-34-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/currentness-34-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:dependency-contract-consistency" :path "tests/dependency-contract-consistency-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/dependency-contract-consistency-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:deps-hash" :path "tests/deps-hash-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/deps-hash-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:document-fetch" :path "tests/document-fetch-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/document-fetch-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:dsanet-chrome" :path "tests/dsanet-chrome-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/dsanet-chrome-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:errata-boundary" :path "tests/errata-boundary-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/errata-boundary-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:escape-sequences" :path "tests/escape-sequences-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/escape-sequences-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:fek-article-header" :path "tests/fek-article-header-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/fek-article-header-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:fek-backtest-report" :path "tests/fek-backtest-report-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/fek-backtest-report-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:fek-discovery" :path "tests/fek-discovery-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/fek-discovery-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:fek-html-parser" :path "tests/fek-html-parser-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/fek-html-parser-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:fek-ingestion" :path "tests/fek-ingestion-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/fek-ingestion-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:fek-noise" :path "tests/fek-noise-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/fek-noise-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:fek-rubric" :path "tests/fek-rubric-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/fek-rubric-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:government-source" :path "tests/government-source-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/government-source-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:graph-import-parity" :path "tests/graph-import-parity-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/graph-import-parity-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:greek-homoglyph" :path "tests/greek-homoglyph-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/greek-homoglyph-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:greek-morphology" :path "tests/greek-morphology-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/greek-morphology-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:greek-nlp" :path "tests/greek-nlp-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/greek-nlp-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:hash-authority" :path "tests/hash-authority-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/hash-authority-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:hash-seat-registry" :path "tests/hash-seat-registry-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/hash-seat-registry-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:incremental-emit" :path "tests/incremental-emit-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/incremental-emit-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:ingestion-daemon" :path "tests/ingestion-daemon-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/ingestion-daemon-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:ingestion-e2e" :path "tests/ingestion-e2e-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/ingestion-e2e-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:isokratis-amended" :path "tests/isokratis-amended-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/isokratis-amended-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:isokratis-parser" :path "tests/isokratis-parser-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/isokratis-parser-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:journal-integrity" :path "tests/journal-integrity-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/journal-integrity-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:json-emit" :path "tests/json-emit-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/json-emit-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:json-escape-seat" :path "tests/json-escape-seat-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/json-escape-seat-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:jws-strict-grammar" :path "tests/jws-strict-grammar-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/jws-strict-grammar-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:kernel-conformance" :path "tests/kernel-conformance-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/kernel-conformance-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:layout-extraction" :path "tests/layout-extraction-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/layout-extraction-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:layout-persistence" :path "tests/layout-persistence-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/layout-persistence-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:legal-authority-receipt" :path "tests/legal-authority-receipt-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/legal-authority-receipt-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:legal-eval" :path "tests/legal-eval-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/legal-eval-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:legal-id-registry" :path "tests/legal-id-registry-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/legal-id-registry-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:legal-id-routing" :path "tests/legal-id-routing-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/legal-id-routing-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:legal-identity" :path "tests/legal-identity-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/legal-identity-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:legal-qa" :path "tests/legal-qa-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/legal-qa-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:legal-references" :path "tests/legal-references-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/legal-references-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:legislation-ingestion" :path "tests/legislation-ingestion-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/legislation-ingestion-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:level7-disarm" :path "tests/level7-disarm-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/level7-disarm-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:mcp-live-resolver" :path "tests/mcp-live-resolver-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/mcp-live-resolver-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:mcp-server" :path "tests/mcp-server-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/mcp-server-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:merkle-authority" :path "tests/merkle-authority-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/merkle-authority-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:merkle-single-truth" :path "tests/merkle-single-truth-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/merkle-single-truth-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:multi-corpus-service" :path "tests/multi-corpus-service-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/multi-corpus-service-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:orthography" :path "tests/orthography-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/orthography-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:param-type-coercion" :path "tests/param-type-coercion-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/param-type-coercion-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:param-type-roundtrip" :path "tests/param-type-roundtrip-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/param-type-roundtrip-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:parliament-html-wiring" :path "tests/parliament-html-wiring-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/parliament-html-wiring-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:pdf-column-reflow" :path "tests/pdf-column-reflow-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/pdf-column-reflow-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:proof-carrying" :path "tests/proof-carrying-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/proof-carrying-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:reader-census" :path "tests/reader-census-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/reader-census-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:reasoning-authority" :path "tests/reasoning-authority-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/reasoning-authority-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:release-authority" :path "tests/release-authority-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/release-authority-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:release-vector-conformance" :path "tests/release-vector-conformance-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/release-vector-conformance-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:repeal-polish" :path "tests/repeal-polish-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/repeal-polish-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:retired-entrypoint" :path "tests/retired-entrypoint-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/retired-entrypoint-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:review-queue-safe-read" :path "tests/review-queue-safe-read-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/review-queue-safe-read-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:review-queue" :path "tests/review-queue-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/review-queue-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:review-service" :path "tests/review-service-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/review-service-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:safe-read" :path "tests/safe-read-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/safe-read-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:seam-detector" :path "tests/seam-detector-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/seam-detector-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:seat-integrity" :path "tests/seat-integrity-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/seat-integrity-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:self-identity" :path "tests/self-identity-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/self-identity-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:semantic-validity" :path "tests/semantic-validity-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/semantic-validity-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:shacl-validator" :path "tests/shacl-validator-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/shacl-validator-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:source-detect" :path "tests/source-detect-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/source-detect-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:source-materialize" :path "tests/source-materialize-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/source-materialize-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:source-profile" :path "tests/source-profile-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/source-profile-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:static-site" :path "tests/static-site-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/static-site-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:temporal-semantics" :path "tests/temporal-semantics-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/temporal-semantics-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:temporal-verifier" :path "tests/temporal-verifier-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/temporal-verifier-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:text-admission" :path "tests/text-admission-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/text-admission-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:text-sovereignty" :path "tests/text-sovereignty-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/text-sovereignty-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:time-unified" :path "tests/time-unified-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/time-unified-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:trace-persistence" :path "tests/trace-persistence-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/trace-persistence-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:transparency-log" :path "tests/transparency-log-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/transparency-log-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:tsr-crypto-verify" :path "tests/tsr-crypto-verify-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/tsr-crypto-verify-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:turtle-nil-omit" :path "tests/turtle-nil-omit-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/turtle-nil-omit-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:version-chain-tc2" :path "tests/version-chain-tc2-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/version-chain-tc2-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:version-graph" :path "tests/version-graph-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/version-graph-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite:write-authority" :path "tests/write-authority-test.lisp" :type :suite
    :invocation "sbcl --script /app/docker/run-standalone-test.lisp /app/tests/write-authority-test.lisp" :prerequisites "runner image· corpus read-only"
    :inclusion-reason "glob tests/*-test.lisp μείον εξαιρέσεις"
    :expected-exit 0 :actual "βλ. suite-census.sexp" :status :EXECUTED)
   (:id "suite-excluded:comparison" :path "tests/comparison-test.lisp" :type :declared-suite-exclusion
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΔΗΛΩΜΕΝΗ εξαίρεση σουίτας"
    :expected-exit — :actual "—" :status :EXCLUDED-DECLARED)
   (:id "nonsuite:architecture-verification.lisp" :path "tests/architecture-verification.lisp" :type :declared-nonsuite
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΔΗΛΩΜΕΝΗ εξαίρεση με λόγο στο ΕΝΑ αρχείο εξαιρέσεων"
    :expected-exit — :actual "—" :status :EXCLUDED-DECLARED)
   (:id "nonsuite:hardcoded-verification.lisp" :path "tests/hardcoded-verification.lisp" :type :declared-nonsuite
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΔΗΛΩΜΕΝΗ εξαίρεση με λόγο στο ΕΝΑ αρχείο εξαιρέσεων"
    :expected-exit — :actual "—" :status :EXCLUDED-DECLARED)
   (:id "nonsuite:mathematical-proof.lisp" :path "tests/mathematical-proof.lisp" :type :declared-nonsuite
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΔΗΛΩΜΕΝΗ εξαίρεση με λόγο στο ΕΝΑ αρχείο εξαιρέσεων"
    :expected-exit — :actual "—" :status :EXCLUDED-DECLARED)
   (:id "nonsuite:observer-verification.lisp" :path "tests/observer-verification.lisp" :type :declared-nonsuite
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΔΗΛΩΜΕΝΗ εξαίρεση με λόγο στο ΕΝΑ αρχείο εξαιρέσεων"
    :expected-exit — :actual "—" :status :EXCLUDED-DECLARED)
   (:id "nonsuite:run-citation-verification.lisp" :path "tests/run-citation-verification.lisp" :type :declared-nonsuite
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΔΗΛΩΜΕΝΗ εξαίρεση με λόγο στο ΕΝΑ αρχείο εξαιρέσεων"
    :expected-exit — :actual "—" :status :EXCLUDED-DECLARED)
   (:id "nonsuite:test-citation-authority.lisp" :path "tests/test-citation-authority.lisp" :type :declared-nonsuite
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΔΗΛΩΜΕΝΗ εξαίρεση με λόγο στο ΕΝΑ αρχείο εξαιρέσεων"
    :expected-exit — :actual "—" :status :EXCLUDED-DECLARED)
   (:id "nonsuite:test-infrastructure.lisp" :path "tests/test-infrastructure.lisp" :type :declared-nonsuite
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΔΗΛΩΜΕΝΗ εξαίρεση με λόγο στο ΕΝΑ αρχείο εξαιρέσεων"
    :expected-exit — :actual "—" :status :EXCLUDED-DECLARED)
   (:id "nonsuite:tokenizer-verification.lisp" :path "tests/tokenizer-verification.lisp" :type :declared-nonsuite
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΔΗΛΩΜΕΝΗ εξαίρεση με λόγο στο ΕΝΑ αρχείο εξαιρέσεων"
    :expected-exit — :actual "—" :status :EXCLUDED-DECLARED)
   (:id "fiveam:orchestrator-tests" :path "orchestrator-tests.asd" :type :suite-fiveam
    :invocation "(asdf:load-system :orchestrator-tests) + (fiveam:run-all-tests)" :prerequisites "runner image"
    :inclusion-reason "ΔΕΥΤΕΡΗ ΕΔΡΑ ΔΟΚΙΜΩΝ — 12 αρχεία ΕΚΤΟΣ tests/, ΑΟΡΑΤΗ στο glob inventory"
    :expected-exit 0 :actual "31 tests, 7 X, ΚΑΤΑΡΡΕΥΣΗ: memory fault στο JONATHAN.ENCODE::%TO-JSON" :status :FAILED+CRASH)
   (:id "proof:capture-mountpoint-test.sh" :path "authority-v2/proofs/capture-mountpoint-test.sh" :type :proof
    :invocation "bash/python3 authority-v2/proofs/capture-mountpoint-test.sh" :prerequisites "runner/host"
    :inclusion-reason "απογεγραμμένη απόδειξη authority-v2"
    :expected-exit 0 :actual "run-proofs.sh: 14 passed/0 failed/1 blocked" :status :EXECUTED-AGGREGATE)
   (:id "proof:capture-seat-differential-test.sh" :path "authority-v2/proofs/capture-seat-differential-test.sh" :type :proof
    :invocation "bash/python3 authority-v2/proofs/capture-seat-differential-test.sh" :prerequisites "runner/host"
    :inclusion-reason "απογεγραμμένη απόδειξη authority-v2"
    :expected-exit 0 :actual "run-proofs.sh: 14 passed/0 failed/1 blocked" :status :EXECUTED-AGGREGATE)
   (:id "proof:ceremony-rehearsal-test.sh" :path "authority-v2/proofs/ceremony-rehearsal-test.sh" :type :proof
    :invocation "bash/python3 authority-v2/proofs/ceremony-rehearsal-test.sh" :prerequisites "runner/host"
    :inclusion-reason "απογεγραμμένη απόδειξη authority-v2"
    :expected-exit 0 :actual "run-proofs.sh: 14 passed/0 failed/1 blocked" :status :EXECUTED-AGGREGATE)
   (:id "proof:delta23-evidence-bundle.sh" :path "authority-v2/proofs/delta23-evidence-bundle.sh" :type :proof
    :invocation "bash/python3 authority-v2/proofs/delta23-evidence-bundle.sh" :prerequisites "runner/host"
    :inclusion-reason "απογεγραμμένη απόδειξη authority-v2"
    :expected-exit 0 :actual "run-proofs.sh: 14 passed/0 failed/1 blocked" :status :EXECUTED-AGGREGATE)
   (:id "proof:docker-e2e-test.sh" :path "authority-v2/proofs/docker-e2e-test.sh" :type :proof
    :invocation "bash/python3 authority-v2/proofs/docker-e2e-test.sh" :prerequisites "runner/host"
    :inclusion-reason "απογεγραμμένη απόδειξη authority-v2"
    :expected-exit 0 :actual "run-proofs.sh: 14 passed/0 failed/1 blocked" :status :EXECUTED-AGGREGATE)
   (:id "proof:producer-os-boundary-test.sh" :path "authority-v2/proofs/producer-os-boundary-test.sh" :type :proof
    :invocation "bash/python3 authority-v2/proofs/producer-os-boundary-test.sh" :prerequisites "runner/host"
    :inclusion-reason "απογεγραμμένη απόδειξη authority-v2"
    :expected-exit 0 :actual "run-proofs.sh: 14 passed/0 failed/1 blocked" :status :EXECUTED-AGGREGATE)
   (:id "proof:verify-capability-closure.sh" :path "authority-v2/proofs/verify-capability-closure.sh" :type :proof
    :invocation "bash/python3 authority-v2/proofs/verify-capability-closure.sh" :prerequisites "runner/host"
    :inclusion-reason "απογεγραμμένη απόδειξη authority-v2"
    :expected-exit 0 :actual "run-proofs.sh: 14 passed/0 failed/1 blocked" :status :EXECUTED-AGGREGATE)
   (:id "proof:capture-adversarial-test.py" :path "authority-v2/proofs/capture-adversarial-test.py" :type :proof
    :invocation "bash/python3 authority-v2/proofs/capture-adversarial-test.py" :prerequisites "runner/host"
    :inclusion-reason "απογεγραμμένη απόδειξη authority-v2"
    :expected-exit 0 :actual "run-proofs.sh: 14 passed/0 failed/1 blocked" :status :EXECUTED-AGGREGATE)
   (:id "proof:capture-mutation-witness.py" :path "authority-v2/proofs/capture-mutation-witness.py" :type :proof
    :invocation "bash/python3 authority-v2/proofs/capture-mutation-witness.py" :prerequisites "runner/host"
    :inclusion-reason "απογεγραμμένη απόδειξη authority-v2"
    :expected-exit 0 :actual "run-proofs.sh: 14 passed/0 failed/1 blocked" :status :EXECUTED-AGGREGATE)
   (:id "proof:gate-negative-fixtures.py" :path "authority-v2/proofs/gate-negative-fixtures.py" :type :proof
    :invocation "bash/python3 authority-v2/proofs/gate-negative-fixtures.py" :prerequisites "runner/host"
    :inclusion-reason "απογεγραμμένη απόδειξη authority-v2"
    :expected-exit 0 :actual "run-proofs.sh: 14 passed/0 failed/1 blocked" :status :EXECUTED-AGGREGATE)
   (:id "proof:producer-topology-test.py" :path "authority-v2/proofs/producer-topology-test.py" :type :proof
    :invocation "bash/python3 authority-v2/proofs/producer-topology-test.py" :prerequisites "runner/host"
    :inclusion-reason "απογεγραμμένη απόδειξη authority-v2"
    :expected-exit 0 :actual "run-proofs.sh: 14 passed/0 failed/1 blocked" :status :EXECUTED-AGGREGATE)
   (:id "proof:proof-census-adversarial-test.py" :path "authority-v2/proofs/proof-census-adversarial-test.py" :type :proof
    :invocation "bash/python3 authority-v2/proofs/proof-census-adversarial-test.py" :prerequisites "runner/host"
    :inclusion-reason "απογεγραμμένη απόδειξη authority-v2"
    :expected-exit 0 :actual "run-proofs.sh: 14 passed/0 failed/1 blocked" :status :EXECUTED-AGGREGATE)
   (:id "proof:verify-completion-matrix.py" :path "authority-v2/proofs/verify-completion-matrix.py" :type :proof
    :invocation "bash/python3 authority-v2/proofs/verify-completion-matrix.py" :prerequisites "runner/host"
    :inclusion-reason "απογεγραμμένη απόδειξη authority-v2"
    :expected-exit 0 :actual "run-proofs.sh: 14 passed/0 failed/1 blocked" :status :EXECUTED-AGGREGATE)
   (:id "proof:verify-proof-manifest.py" :path "authority-v2/proofs/verify-proof-manifest.py" :type :proof
    :invocation "bash/python3 authority-v2/proofs/verify-proof-manifest.py" :prerequisites "runner/host"
    :inclusion-reason "απογεγραμμένη απόδειξη authority-v2"
    :expected-exit 0 :actual "run-proofs.sh: 14 passed/0 failed/1 blocked" :status :EXECUTED-AGGREGATE)
   (:id "proof:witness-quorum-test.py" :path "authority-v2/proofs/witness-quorum-test.py" :type :proof
    :invocation "bash/python3 authority-v2/proofs/witness-quorum-test.py" :prerequisites "runner/host"
    :inclusion-reason "απογεγραμμένη απόδειξη authority-v2"
    :expected-exit 0 :actual "run-proofs.sh: 14 passed/0 failed/1 blocked" :status :EXECUTED-AGGREGATE)
   (:id "aggregator:run-all.sh" :path "authority-v2/run-all.sh" :type :aggregator
    :invocation "bash authority-v2/run-all.sh" :prerequisites "—"
    :inclusion-reason "συναθροιστής — ΔΕΝ μετριέται ως ξεχωριστή σουίτα"
    :expected-exit 0 :actual "run-proofs.sh EXECUTED· run-all.sh NOT-EXECUTED (θέλει root+docker E2E)" :status :MIXED)
   (:id "aggregator:run-proofs.sh" :path "authority-v2/run-proofs.sh" :type :aggregator
    :invocation "bash authority-v2/run-proofs.sh" :prerequisites "—"
    :inclusion-reason "συναθροιστής — ΔΕΝ μετριέται ως ξεχωριστή σουίτα"
    :expected-exit 0 :actual "run-proofs.sh EXECUTED· run-all.sh NOT-EXECUTED (θέλει root+docker E2E)" :status :MIXED)
   (:id "aggregator:run-standalone-suites.sh" :path "docker/run-standalone-suites.sh" :type :aggregator
    :invocation "bash docker/run-standalone-suites.sh" :prerequisites "—"
    :inclusion-reason "συναθροιστής — ΔΕΝ μετριέται ως ξεχωριστή σουίτα"
    :expected-exit 0 :actual "run-proofs.sh EXECUTED· run-all.sh NOT-EXECUTED (θέλει root+docker E2E)" :status :MIXED)
   (:id "aggregator:run-standalone-suites-test.sh" :path "docker/run-standalone-suites-test.sh" :type :aggregator
    :invocation "bash docker/run-standalone-suites-test.sh" :prerequisites "—"
    :inclusion-reason "συναθροιστής — ΔΕΝ μετριέται ως ξεχωριστή σουίτα"
    :expected-exit 0 :actual "run-proofs.sh EXECUTED· run-all.sh NOT-EXECUTED (θέλει root+docker E2E)" :status :MIXED)
   (:id "e2e:docker" :path "authority-v2/proofs/docker-e2e-test.sh" :type :e2e
    :invocation "bash authority-v2/proofs/docker-e2e-test.sh" :prerequisites "docker daemon + Debian archive"
    :inclusion-reason "production-equivalent E2E"
    :expected-exit 0 :actual "exit 1 — apt 403 deb.debian.org" :status :BLOCKED)
   (:id "outside:probe-attest-refusal.lisp" :path "authority-v2/tests/probe-attest-refusal.lisp" :type :test-file-outside-inventory
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΕΚΤΟΣ του glob tests/*-test.lisp — δεν καλύπτεται από τον έλεγχο ολότητας του corpus"
    :expected-exit — :actual "—" :status :OUT-OF-INVENTORY)
   (:id "outside:test-escaping.lisp" :path "systems/orchestrator-engine-sbcl/stages/test-escaping.lisp" :type :test-file-outside-inventory
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΕΚΤΟΣ του glob tests/*-test.lisp — δεν καλύπτεται από τον έλεγχο ολότητας του corpus"
    :expected-exit — :actual "—" :status :OUT-OF-INVENTORY)
   (:id "outside:test-articles.lisp" :path "systems/orchestrator-tests/fixtures/test-articles.lisp" :type :test-file-outside-inventory
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΕΚΤΟΣ του glob tests/*-test.lisp — δεν καλύπτεται από τον έλεγχο ολότητας του corpus"
    :expected-exit — :actual "—" :status :OUT-OF-INVENTORY)
   (:id "outside:ai-export-integration-test.lisp" :path "systems/orchestrator-tests/integration/ai-export-integration-test.lisp" :type :test-file-outside-inventory
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΕΚΤΟΣ του glob tests/*-test.lisp — δεν καλύπτεται από τον έλεγχο ολότητας του corpus"
    :expected-exit — :actual "—" :status :OUT-OF-INVENTORY)
   (:id "outside:mini-corpus-test.lisp" :path "systems/orchestrator-tests/integration/mini-corpus-test.lisp" :type :test-file-outside-inventory
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΕΚΤΟΣ του glob tests/*-test.lisp — δεν καλύπτεται από τον έλεγχο ολότητας του corpus"
    :expected-exit — :actual "—" :status :OUT-OF-INVENTORY)
   (:id "outside:pipeline-test.lisp" :path "systems/orchestrator-tests/integration/pipeline-test.lisp" :type :test-file-outside-inventory
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΕΚΤΟΣ του glob tests/*-test.lisp — δεν καλύπτεται από τον έλεγχο ολότητας του corpus"
    :expected-exit — :actual "—" :status :OUT-OF-INVENTORY)
   (:id "outside:hash-stability-test.lisp" :path "systems/orchestrator-tests/reproducibility/hash-stability-test.lisp" :type :test-file-outside-inventory
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΕΚΤΟΣ του glob tests/*-test.lisp — δεν καλύπτεται από τον έλεγχο ολότητας του corpus"
    :expected-exit — :actual "—" :status :OUT-OF-INVENTORY)
   (:id "outside:artifact-test.lisp" :path "systems/orchestrator-tests/unit/artifact-test.lisp" :type :test-file-outside-inventory
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΕΚΤΟΣ του glob tests/*-test.lisp — δεν καλύπτεται από τον έλεγχο ολότητας του corpus"
    :expected-exit — :actual "—" :status :OUT-OF-INVENTORY)
   (:id "outside:dependency-graph-test.lisp" :path "systems/orchestrator-tests/unit/dependency-graph-test.lisp" :type :test-file-outside-inventory
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΕΚΤΟΣ του glob tests/*-test.lisp — δεν καλύπτεται από τον έλεγχο ολότητας του corpus"
    :expected-exit — :actual "—" :status :OUT-OF-INVENTORY)
   (:id "outside:dsl-test.lisp" :path "systems/orchestrator-tests/unit/dsl-test.lisp" :type :test-file-outside-inventory
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΕΚΤΟΣ του glob tests/*-test.lisp — δεν καλύπτεται από τον έλεγχο ολότητας του corpus"
    :expected-exit — :actual "—" :status :OUT-OF-INVENTORY)
   (:id "outside:test-ai-core.lisp" :path "systems/orchestrator-tests/unit/test-ai-core.lisp" :type :test-file-outside-inventory
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΕΚΤΟΣ του glob tests/*-test.lisp — δεν καλύπτεται από τον έλεγχο ολότητας του corpus"
    :expected-exit — :actual "—" :status :OUT-OF-INVENTORY)
   (:id "outside:utilities-test.lisp" :path "systems/orchestrator-tests/unit/utilities-test.lisp" :type :test-file-outside-inventory
    :invocation "—" :prerequisites "—"
    :inclusion-reason "ΕΚΤΟΣ του glob tests/*-test.lisp — δεν καλύπτεται από τον έλεγχο ολότητας του corpus"
    :expected-exit — :actual "—" :status :OUT-OF-INVENTORY)
   (:id "selfcheck:assess-gate-plenary-test.sh" :path "deployment/verify/assess-gate-plenary-test.sh" :type :self-check
    :invocation "bash/python3 deployment/verify/assess-gate-plenary-test.sh" :prerequisites "sbcl/python3"
    :inclusion-reason "self-verification vectors του corpus"
    :expected-exit 0 :actual "NOT-EXECUTED" :status :NOT-EXECUTED)
   (:id "selfcheck:assess-gate-plenary.sh" :path "deployment/verify/assess-gate-plenary.sh" :type :self-check
    :invocation "bash/python3 deployment/verify/assess-gate-plenary.sh" :prerequisites "sbcl/python3"
    :inclusion-reason "self-verification vectors του corpus"
    :expected-exit 0 :actual "NOT-EXECUTED" :status :NOT-EXECUTED)
   (:id "selfcheck:blind-failure-test.sh" :path "deployment/verify/blind-failure-test.sh" :type :self-check
    :invocation "bash/python3 deployment/verify/blind-failure-test.sh" :prerequisites "sbcl/python3"
    :inclusion-reason "self-verification vectors του corpus"
    :expected-exit 0 :actual "NOT-EXECUTED" :status :NOT-EXECUTED)
   (:id "selfcheck:census-execution-constructs.sh" :path "deployment/verify/census-execution-constructs.sh" :type :self-check
    :invocation "bash/python3 deployment/verify/census-execution-constructs.sh" :prerequisites "sbcl/python3"
    :inclusion-reason "self-verification vectors του corpus"
    :expected-exit 0 :actual "NOT-EXECUTED" :status :NOT-EXECUTED)
   (:id "selfcheck:self-understanding-audit-v1.sh" :path "deployment/verify/self-understanding-audit/self-understanding-audit-v1.sh" :type :self-check
    :invocation "bash/python3 deployment/verify/self-understanding-audit/self-understanding-audit-v1.sh" :prerequisites "sbcl/python3"
    :inclusion-reason "self-verification vectors του corpus"
    :expected-exit 0 :actual "NOT-EXECUTED" :status :NOT-EXECUTED)
   (:id "selfcheck:run-vectors.sh" :path "deployment/verify/vectors/run-vectors.sh" :type :self-check
    :invocation "bash/python3 deployment/verify/vectors/run-vectors.sh" :prerequisites "sbcl/python3"
    :inclusion-reason "self-verification vectors του corpus"
    :expected-exit 0 :actual "NOT-EXECUTED" :status :NOT-EXECUTED)
   (:id "selfcheck:verify-authority-bundle.py" :path "deployment/verify/verify-authority-bundle.py" :type :self-check
    :invocation "bash/python3 deployment/verify/verify-authority-bundle.py" :prerequisites "sbcl/python3"
    :inclusion-reason "self-verification vectors του corpus"
    :expected-exit 0 :actual "NOT-EXECUTED" :status :NOT-EXECUTED)
   (:id "selfcheck:verify-canonical.py" :path "deployment/verify/verify-canonical.py" :type :self-check
    :invocation "bash/python3 deployment/verify/verify-canonical.py" :prerequisites "sbcl/python3"
    :inclusion-reason "self-verification vectors του corpus"
    :expected-exit 0 :actual "NOT-EXECUTED" :status :NOT-EXECUTED)
   (:id "selfcheck:verify-merkle.py" :path "deployment/verify/verify-merkle.py" :type :self-check
    :invocation "bash/python3 deployment/verify/verify-merkle.py" :prerequisites "sbcl/python3"
    :inclusion-reason "self-verification vectors του corpus"
    :expected-exit 0 :actual "NOT-EXECUTED" :status :NOT-EXECUTED)
   (:id "selfcheck:verify-release.py" :path "deployment/verify/verify-release.py" :type :self-check
    :invocation "bash/python3 deployment/verify/verify-release.py" :prerequisites "sbcl/python3"
    :inclusion-reason "self-verification vectors του corpus"
    :expected-exit 0 :actual "NOT-EXECUTED" :status :NOT-EXECUTED)
   (:id "selfcheck:verify-temporal.py" :path "deployment/verify/verify-temporal.py" :type :self-check
    :invocation "bash/python3 deployment/verify/verify-temporal.py" :prerequisites "sbcl/python3"
    :inclusion-reason "self-verification vectors του corpus"
    :expected-exit 0 :actual "NOT-EXECUTED" :status :NOT-EXECUTED)
   (:id "selfcheck:verify.py" :path "deployment/verify/verify.py" :type :self-check
    :invocation "bash/python3 deployment/verify/verify.py" :prerequisites "sbcl/python3"
    :inclusion-reason "self-verification vectors του corpus"
    :expected-exit 0 :actual "NOT-EXECUTED" :status :NOT-EXECUTED)
   (:id "tool:independent-audit.py" :path "tools/independent-audit.py" :type :tooling-checker
    :invocation "python3 tools/independent-audit.py" :prerequisites "python3"
    :inclusion-reason "ανεξάρτητος ελεγκτής/εργαλείο"
    :expected-exit 0 :actual "NOT-EXECUTED" :status :NOT-EXECUTED)
   (:id "tool:verify-proof-manifest-test.py" :path "docker/verify-proof-manifest-test.py" :type :tooling-checker
    :invocation "python3 docker/verify-proof-manifest-test.py" :prerequisites "python3"
    :inclusion-reason "ανεξάρτητος ελεγκτής/εργαλείο"
    :expected-exit 0 :actual "NOT-EXECUTED" :status :NOT-EXECUTED)
   (:id "tool:verify-proof-manifest.py" :path "docker/verify-proof-manifest.py" :type :tooling-checker
    :invocation "python3 docker/verify-proof-manifest.py" :prerequisites "python3"
    :inclusion-reason "ανεξάρτητος ελεγκτής/εργαλείο"
    :expected-exit 0 :actual "NOT-EXECUTED" :status :NOT-EXECUTED)
  ))
