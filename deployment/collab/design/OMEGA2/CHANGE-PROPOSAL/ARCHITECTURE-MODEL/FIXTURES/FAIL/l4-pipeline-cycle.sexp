(fixture FX-L4-PIPELINE-CYCLE
  :provenance "v1.8 V8-COGLIFE illegal-cycle / acyclic permitted dependency graph"
  :mutate (add "dependencies-and-boundaries.sexp" "(fact stage-edge PUBLISH__ACQUIRE :from PUBLISH :to ACQUIRE)"))
