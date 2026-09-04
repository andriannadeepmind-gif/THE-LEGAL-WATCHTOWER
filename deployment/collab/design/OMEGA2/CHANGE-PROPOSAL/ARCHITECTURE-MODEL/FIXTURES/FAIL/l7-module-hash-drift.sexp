(fixture FAIL-L7-module-hash-drift :law L7 :expect FAIL :reason "SHA drift"
  :provenance "IR4-02 manifest drift / exact file-module-hash universe"
  :mutate (append-no-rehash "subsystems.sexp" "; tampered fact injected without updating ROOT"))
