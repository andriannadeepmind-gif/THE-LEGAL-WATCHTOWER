(:lawmax-phase1a-cluster/1
 :cluster "deployment-specs (ΚΑΝΟΝΙΚΕΣ ΠΡΟΔΙΑΓΡΑΦΕΣ /frozen/ro/deployment/)"
 :status :partial
 :files-read 8
 :scope-note "ΟΛΕΣ οι άγκυρες είναι σχετικές με /frozen/ro/deployment/ εκτός αν αρχίζουν με 'deployment/'. ΔΕΝ διαβάστηκαν (εκτός συστάδας): self/ self-study/ knowledge/ data/ state/ collab/."
 :capabilities ()
 :authorities ()
 :invariants ()
 :defects
 ((:what "TSA plurality contradiction: LAWMAX-THREAT-MODEL.md απαιτεί >=3 ανεξάρτητες RFC-3161 TSA· LAWMAX-TRUST-BOOTSTRAP-SPEC.md απαιτεί >=2."
   :severity :p1 :evidence "LAWMAX-THREAT-MODEL.md:L46 ; LAWMAX-TRUST-BOOTSTRAP-SPEC.md:L54"
   :is-it-in-the-known-defect-list :unknown))
 :hidden-execution-paths ()
 :duplicate-seats ()
 :unknowns ("σχεδόν τα πάντα — πρώτο checkpoint")
 :remaining ("ΟΛΑ τα υπόλοιπα LAWMAX-*.md/.sexp, *.ttl, publisher.jsonld, ΧΑΡΤΗΣ-ΝΟΗΣΗΣ.md, shapes/, templates/, mcp/, verify/*"))
