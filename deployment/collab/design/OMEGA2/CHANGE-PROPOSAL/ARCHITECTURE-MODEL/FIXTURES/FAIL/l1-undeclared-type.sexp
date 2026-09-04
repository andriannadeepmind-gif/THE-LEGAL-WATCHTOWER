(fixture FAIL-L1-undeclared-type :law L1 :expect FAIL :reason "undeclared fact type BOGUS"
  :provenance "v1.x: malformed/unknown structural form"
  :mutate (add "subsystems.sexp" "(fact bogus X01 :a b)"))
