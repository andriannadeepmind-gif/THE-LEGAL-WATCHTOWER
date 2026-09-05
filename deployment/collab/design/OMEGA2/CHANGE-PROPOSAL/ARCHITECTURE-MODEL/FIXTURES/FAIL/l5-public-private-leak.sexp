(fixture FX-L5-PUBLIC-PRIVATE-LEAK
  :provenance "v1.8 V8-PUBPRIV leak / public->private isolation"
  :mutate (add "dependencies-and-boundaries.sexp" "(fact consumes S12__TenantProfile/1 :consumer S12 :provides TenantProfile/1)"))
