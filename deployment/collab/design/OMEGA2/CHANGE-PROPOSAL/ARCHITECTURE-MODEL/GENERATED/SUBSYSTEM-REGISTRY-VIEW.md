<!-- GENERATED — DO NOT EDIT. Regenerate: python3 ARCHITECTURE-MODEL/generate_views.py -->
# Subsystem Registry View (GENERATED VIEW — DO NOT EDIT)

- generator: `generate_views.py/2`
- canonical-model-root-digest: `9202ad3aa7bc5bdc3592569b6dff222c05e641bd587edc1e8cf7a95fb1e7dcd4`
- regeneration command: `python3 ARCHITECTURE-MODEL/generate_views.py`

| subsystem | classification | owner-seat | mission | migration |
|---|---|---|---|---|
| S01 | PUBLIC | COVERAGE-LEDGER.LISP | MIS-2 | KEEP |
| S02 | PUBLIC | acquirer/1 + ingestion-daemon.lisp | MIS-1 | EXTEND |
| S03 | PUBLIC | legal-extraction-verify.lisp (epistemic wall) | MIS-1 | EXTEND |
| S04 | PUBLIC | greek-nlp-core.lisp + legal-ast.lisp + legal-inference-engine.lisp | MIS-1 | EXTEND |
| S05 | PUBLIC | version-graph.lisp + legal-temporal.lisp | MIS-3 | EXTEND |
| S06 | PUBLIC | legal graph store | MIS-4 | KEEP |
| S07 | PUBLIC | LEGAL-EVENT-CALCULUS.LISP | MIS-4 | KEEP |
| S08 | PUBLIC | RELEASE-GATE.LISP | MIS-5 | KEEP |
| S09 | PUBLIC | proof layer | MIS-5 | KEEP |
| S10 | PUBLIC | MLTP v3 | MIS-1 | EXTEND |
| S11 | PUBLIC | security cells | MIS-9 | KEEP |
| S12 | PUBLIC | approval-policy.lisp + decisions.lisp | MIS-6 | EXTEND |
| S13 | PUBLIC | STATIC-SITE.LISP | MIS-6 | KEEP |
| S14 | PUBLIC | CAPABILITY-API | MIS-5 | EXTEND |
| S15 | PUBLIC | OBSERVATORY | MIS-9 | KEEP |
| S16 | PUBLIC | LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.MD | MIS-2 | EXTEND |
| S17 | PUBLIC | SHACL-VALIDATOR.LISP | MIS-8 | KEEP |
| S18 | PUBLIC | boundary schemas | MIS-10 | EXTEND |
| S19 | PUBLIC | memory.lisp (ONE seat, EXTEND) | MIS-1 | EXTEND |
| S20 | PUBLIC | capability registry | MIS-1 | EXTEND |
| S21 | PUBLIC | safe-mode controller (EXTEND write-authority.lisp) | MIS-1 | EXTEND |
| S22 | PRIVATE | DEFERRED_PRIVATE (no public dependency) | MIS-10 | DEFER_PRIVATE |
| S23 | PRIVATE | DEFERRED_PRIVATE | MIS-10 | DEFER_PRIVATE |
| S24 | PRIVATE | DEFERRED_PRIVATE | MIS-10 | DEFER_PRIVATE |
| S25 | PUBLIC | canonical-uris.lisp (EXTEND: ECLI/CELEX/ADA/FEK) + legal-identity.lisp | MIS-5 | EXTEND |
| S26 | PRIVATE | INTERFACE_ONLY (no public dependency) | MIS-10 | DEFER_PRIVATE |
