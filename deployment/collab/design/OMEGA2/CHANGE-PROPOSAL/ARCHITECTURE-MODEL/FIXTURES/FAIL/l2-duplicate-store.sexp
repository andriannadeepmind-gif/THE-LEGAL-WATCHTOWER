(fixture FAIL-L2-duplicate-store :law L2 :expect FAIL :reason "duplicate seat STORE journal"
  :provenance "v1.8 V8-OWN dup-store / one-seat law"
  :mutate (add "stores-and-authorities.sexp" "(fact store journal :owner dup :writer dup)"))
