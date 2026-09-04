(fixture FAIL-L3-dangling-wp :law L3 :expect FAIL :reason "undeclared wp WP-999"
  :provenance "v1.8 V8-REQ ghost-wp / closed typed references"
  :mutate (add "requirements-tests-workpackets.sexp" "(fact req-map S01__WP-999 :subsystem S01 :requirement R-132 :test Q01 :wp WP-999)"))
