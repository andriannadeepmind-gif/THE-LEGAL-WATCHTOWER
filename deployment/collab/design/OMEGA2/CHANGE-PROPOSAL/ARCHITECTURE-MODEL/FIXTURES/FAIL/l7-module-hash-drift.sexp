(fixture FX-L7-MODULE-HASH-DRIFT
  :provenance "IR4-02 manifest drift / exact file-module-hash universe"
  :mutate (append-no-rehash "subsystems.sexp" "; tampered fact injected without updating ROOT"))
