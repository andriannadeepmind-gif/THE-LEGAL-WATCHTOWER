(fixture FAIL-L5-public-private-leak :law L5 :expect FAIL :reason "public/private leak"
  :provenance "v1.8 V8-PUBPRIV leak / public->private isolation"
  :mutate (add "dependencies-and-boundaries.sexp" "(fact consumes S12__TenantProfile/1 :consumer S12 :provides TenantProfile/1)"))
