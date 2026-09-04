(fixture FAIL-L6-subsystem-no-map :law L6 :expect FAIL :reason "has no requirement->seat->test->WP mapping"
  :provenance "v1.8 V8-REQ completeness / complete requirement->seat->test->WP mapping"
  :mutate (remove-line "requirements-tests-workpackets.sexp" "(fact req-map S01__WP-01"))
