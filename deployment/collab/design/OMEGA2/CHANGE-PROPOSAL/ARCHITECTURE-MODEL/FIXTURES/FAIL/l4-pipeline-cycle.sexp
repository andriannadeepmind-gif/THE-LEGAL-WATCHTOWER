(fixture FAIL-L4-pipeline-cycle :law L4 :expect FAIL :reason "cycle in permitted pipeline stage graph"
  :provenance "v1.8 V8-COGLIFE illegal-cycle / acyclic permitted dependency graph"
  :mutate (add "dependencies-and-boundaries.sexp" "(fact stage-edge PUBLISH__ACQUIRE :from PUBLISH :to ACQUIRE)"))
