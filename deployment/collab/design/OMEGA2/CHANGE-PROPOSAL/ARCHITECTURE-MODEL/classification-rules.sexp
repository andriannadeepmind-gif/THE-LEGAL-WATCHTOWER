;;;; classification-rules.sexp — the ONE canonical seat of the repository classification table.
;;;; Every tracked path is classified by exactly one of these rules, in :order, first match wins. The rule
;;;; is DATA: build_inventory.py reads this module rather than carrying a second hand-written copy, and
;;;; both verification paths read the same facts, so the table the generator applies and the table the
;;;; model declares cannot drift apart. A rule that matches no tracked path is a build failure (dead or
;;;; shadowed), a duplicate id, order or match expression is a build failure, and a path that matches no
;;;; rule is UNCLASSIFIED — named and fatal. There is no catch-all.
;;;;
;;;; :match grammar — disjunction of conjunctions, "|" separating terms and "&" separating atoms:
;;;;   prefix:S   the path starts with S          suffix:S   the path ends with S
;;;;   equals:S   the path is exactly S           depth:N    the path contains exactly N slashes
;;;;   pattern:R  the Python regular expression R is found in the path
;;;; An atom name outside this vocabulary is a fatal error, never a false.

(fact classification-rule R-000 :order 1 :role HISTORICAL_EVIDENCE
      :match "equals:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/build_model.py"
      :reason "one-time migration that emitted the canonical model from the v1.6-v1.8 registries; not on the live path")
(fact classification-rule R-001 :order 2 :role GENERATED_VIEW
      :match "prefix:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/GENERATED/"
      :reason "deterministically generated from the canonical model")
(fact classification-rule R-002 :order 3 :role GOVERNANCE_FIXTURE
      :match "prefix:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/FIXTURES/"
      :reason "golden PASS/FAIL fixture exercising the model laws")
(fact classification-rule R-003 :order 4 :role GOVERNANCE_MACHINERY
      :match "prefix:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/KERNEL/ | prefix:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/CHECKER/ | prefix:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/ & suffix:.py | prefix:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/ & suffix:.sh"
      :reason "executable seat of the architecture-governance path (kernel, independent checker, builders, gate)")
(fact classification-rule R-004 :order 5 :role GOVERNANCE_MACHINERY
      :match "prefix:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ & suffix:/.gitignore"
      :reason "ignore rules for the derived and interpreter-generated areas of the architecture-governance seat")
(fact classification-rule R-005 :order 6 :role CANONICAL_MODEL_INPUT
      :match "equals:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/TOOLCHAIN.sexp"
      :reason "pinned toolchain identities (part of the model root)")
(fact classification-rule R-006 :order 7 :role ARCHITECTURE_DECISION
      :match "equals:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/MODEL-MIGRATION-CONFLICT-LEDGER.md"
      :reason "migration conflict adjudications")
(fact classification-rule R-007 :order 8 :role ARCHITECTURE_DECISION
      :match "equals:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/ROOT-OPERATOR-DECISION-PACKET.md"
      :reason "single-operator decision packet")
(fact classification-rule R-008 :order 9 :role CANONICAL_MODEL_INPUT
      :match "prefix:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/ & suffix:.sexp"
      :reason "canonical model module (single source of truth)")
(fact classification-rule R-009 :order 10 :role AUTHORED_NORMATIVE_PROSE
      :match "prefix:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/ & suffix:.md"
      :reason "architecture-model authored document")
(fact classification-rule R-009Q :order 11 :role REVIEW_REQUIRED
      :match "prefix:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/"
      :reason "a file inside the architecture-model seat whose kind no rule declares — the model seat never blesses by prefix (Review-2 N-18)")
(fact classification-rule R-010 :order 12 :role CANONICAL_MODEL_INPUT
      :match "equals:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/SUBSYSTEM-REGISTRY.sexp | equals:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/INTERFACE-AND-SCHEMA-REGISTRY.sexp"
      :reason "v1.6 registry — migration input to the canonical model")
(fact classification-rule R-011 :order 13 :role CANONICAL_MODEL_INPUT
      :match "prefix:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ & suffix:-SCHEMAS.sexp"
      :reason "versioned schema — type/record facts migration input")
(fact classification-rule R-012 :order 14 :role HISTORICAL_EVIDENCE
      :match "pattern:/V1\\.\\d.*AUDIT | pattern:/V1\\.\\d.*VERIFY | pattern:/V1\\.\\d.*EVIDENCE | pattern:/V1\\.\\d.*MANIFEST | pattern:/V1\\.\\d.*BOOTSTRAP | pattern:/V1\\.\\d.*CONSISTENCY | pattern:/V1\\.\\d.*KILL-WITNESSES | pattern:/V1\\.\\d.*SEMANTIC-CROSSWALK | pattern:/V1\\.\\d.*DESTRUCTION-PASS-RECORD | pattern:/V1\\.\\d.*NARROW-DELTA | suffix:.out"
      :reason "legacy v1.x verifier/audit/manifest or captured run output — NON_AUTHORITATIVE (frozen at 4787b342)")
(fact classification-rule R-013 :order 15 :role GENERATED_VIEW
      :match "equals:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-CLOSURE-MATRIX.md | equals:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/PUBLIC-OBSERVATORY-CROSSWALK.md | equals:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/DOMINANCE-MATRIX.md"
      :reason "human-readable table generated from the registries/model")
(fact classification-rule R-014 :order 16 :role HISTORICAL_EVIDENCE
      :match "prefix:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/IMPLEMENTATION-BOOK/tools/"
      :reason "AS-IS extraction tool and its extracted inventory (Implementation-Book execution not authorized)")
(fact classification-rule R-015 :order 17 :role AUTHORED_NORMATIVE_PROSE
      :match "prefix:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/IMPLEMENTATION-BOOK/"
      :reason "Implementation Book construction detail (execution not authorized)")
(fact classification-rule R-016 :order 18 :role HISTORICAL_EVIDENCE
      :match "prefix:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-DESTRUCTION-PASS/"
      :reason "v1.3 destruction-pass record")
(fact classification-rule R-017 :order 19 :role HISTORICAL_EVIDENCE
      :match "prefix:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/formal-v1.1/"
      :reason "v1.1 TLA+ specifications, configurations and falsifiers (v1.1 is FALSIFIED — historical candidate)")
(fact classification-rule R-018 :order 20 :role HISTORICAL_EVIDENCE
      :match "prefix:deployment/collab/dialogue/"
      :reason "append-only AI-dialogue record")
(fact classification-rule R-019 :order 21 :role OUT_OF_SCOPE_WITH_REASON
      :match "prefix:deployment/self/"
      :reason "runtime self-state (restored before every commit; not a model fact)")
(fact classification-rule R-020 :order 22 :role OUT_OF_SCOPE_WITH_REASON
      :match "prefix:deployment/knowledge/"
      :reason "product knowledge base (legal lexicon/taxonomy; not architecture facts)")
(fact classification-rule R-021 :order 23 :role HISTORICAL_EVIDENCE
      :match "prefix:deployment/self-study/"
      :reason "dated external-review / intelligence-audit record")
(fact classification-rule R-022 :order 24 :role PRODUCTION_CODE
      :match "prefix:deployment/verify/"
      :reason "MLTP verification runtime (product)")
(fact classification-rule R-023 :order 25 :role OUT_OF_SCOPE_WITH_REASON
      :match "prefix:deployment/data/"
      :reason "reference/corpus data under deployment (not architecture facts)")
(fact classification-rule R-024 :order 26 :role OUT_OF_SCOPE_WITH_REASON
      :match "prefix:deployment/state/"
      :reason "daemon runtime state (not a model fact)")
(fact classification-rule R-025 :order 27 :role PRODUCTION_CODE
      :match "prefix:deployment/templates/ | prefix:deployment/shapes/ | prefix:deployment/mcp/"
      :reason "RDF templates, SHACL shapes and MCP wiring for publication (product)")
(fact classification-rule R-026 :order 28 :role PRODUCTION_CODE
      :match "prefix:deployment/ & depth:1 & suffix:.ttl | prefix:deployment/ & depth:1 & suffix:.jsonld | prefix:deployment/ & depth:1 & suffix:.json | prefix:deployment/ & depth:1 & suffix:.js | prefix:deployment/ & depth:1 & suffix:.sh"
      :reason "FEK ingestion and semantic-web publication runtime (product)")
(fact classification-rule R-027 :order 29 :role AUTHORED_NORMATIVE_PROSE
      :match "prefix:deployment/ & suffix:.md"
      :reason "authored normative document under deployment/")
(fact classification-rule R-028 :order 30 :role AUTHORED_NORMATIVE_PROSE
      :match "prefix:deployment/ & suffix:.sexp"
      :reason "authored normative contract in S-expression form under deployment/")
(fact classification-rule R-029 :order 31 :role HISTORICAL_EVIDENCE
      :match "prefix:deployment/collab/design/ & suffix:.md | prefix:deployment/collab/design/ & suffix:.sexp | prefix:deployment/collab/design/ & suffix:.json | prefix:deployment/collab/design/ & suffix:.jsonl | prefix:deployment/collab/design/ & suffix:.html | prefix:deployment/collab/design/ & suffix:.txt | prefix:deployment/collab/design/ & suffix:.tsv | prefix:deployment/collab/design/ & suffix:.csv | prefix:deployment/collab/design/ & suffix:.yml | prefix:deployment/collab/design/ & suffix:.yaml | prefix:deployment/collab/design/ & suffix:.tla | prefix:deployment/collab/design/ & suffix:.cfg | prefix:deployment/collab/design/ & suffix:.py | prefix:deployment/collab/design/ & suffix:.sh | prefix:deployment/collab/design/ & suffix:.js | prefix:deployment/collab/design/ & suffix:.mjs"
      :reason "design-round artifact of a declared kind (formal model, analysis tool or evidence data) — round record, not a live path")
(fact classification-rule R-030 :order 32 :role HISTORICAL_EVIDENCE
      :match "prefix:deployment/collab/ & suffix:.md | prefix:deployment/collab/ & suffix:.sexp | prefix:deployment/collab/ & suffix:.json | prefix:deployment/collab/ & suffix:.jsonl | prefix:deployment/collab/ & suffix:.html | prefix:deployment/collab/ & suffix:.txt | prefix:deployment/collab/ & suffix:.tsv | prefix:deployment/collab/ & suffix:.csv | prefix:deployment/collab/ & suffix:.yml | prefix:deployment/collab/ & suffix:.yaml | prefix:deployment/collab/ & suffix:.tla | prefix:deployment/collab/ & suffix:.cfg | prefix:deployment/collab/ & suffix:.py | prefix:deployment/collab/ & suffix:.sh | prefix:deployment/collab/ & suffix:.js | prefix:deployment/collab/ & suffix:.mjs"
      :reason "collaboration-round record of a declared kind (freeze/launch verification evidence outside the design subtree)")
(fact classification-rule R-031 :order 33 :role PRODUCTION_CODE
      :match "prefix:source/ | prefix:systems/"
      :reason "LAWMAX product source (untouched by this pass)")
(fact classification-rule R-032 :order 34 :role PRODUCTION_CODE
      :match "prefix:authority-v2/"
      :reason "authority-v2 attestation/proof machinery (product)")
(fact classification-rule R-033 :order 35 :role PRODUCTION_CODE
      :match "prefix:docker/"
      :reason "container build and proof machinery (product)")
(fact classification-rule R-034 :order 36 :role PRODUCTION_CODE
      :match "prefix:scripts/ | prefix:tools/"
      :reason "build and verification scripts (product)")
(fact classification-rule R-035 :order 37 :role PRODUCTION_CODE
      :match "prefix:cloudflare/"
      :reason "edge publication runtime (product)")
(fact classification-rule R-036 :order 38 :role TEST_OR_FIXTURE
      :match "prefix:determinism/"
      :reason "determinism verification harness")
(fact classification-rule R-037 :order 39 :role TEST_OR_FIXTURE
      :match "prefix:tests/"
      :reason "product test/fixture")
(fact classification-rule R-038 :order 40 :role VENDORED_DEPENDENCY
      :match "prefix:third-party/"
      :reason "vendored third-party dependency tree — executable material, kept distinct from data corpora so that a dependency can never be filed under the same role as a corpus (Review-2 N-18); no governance path compiles or loads any of it since the kernel stopped using the vendored ironclad closure (Review-2 N-1)")
(fact classification-rule R-039 :order 41 :role OUT_OF_SCOPE_WITH_REASON
      :match "prefix:output/ | prefix:output_run1/ | prefix:input/"
      :reason "pipeline data/artifact corpus (not architecture facts)")
(fact classification-rule R-040 :order 42 :role OUT_OF_SCOPE_WITH_REASON
      :match "prefix:docs/"
      :reason "product documentation (not architecture facts)")
(fact classification-rule R-041 :order 43 :role OUT_OF_SCOPE_WITH_REASON
      :match "prefix:configs/"
      :reason "corpus pipeline configuration (not architecture facts)")
(fact classification-rule R-042 :order 44 :role OUT_OF_SCOPE_WITH_REASON
      :match "prefix:keys/"
      :reason "key material placeholder/README (not architecture facts)")
(fact classification-rule R-043 :order 45 :role OUT_OF_SCOPE_WITH_REASON
      :match "prefix:evidence/ | prefix:state/ | prefix:candidates/ | prefix:releases/"
      :reason "runtime evidence/state/release artifacts (not architecture facts)")
(fact classification-rule R-044 :order 46 :role OUT_OF_SCOPE_WITH_REASON
      :match "prefix:examples/"
      :reason "example material (not architecture facts)")
(fact classification-rule R-045 :order 47 :role OUT_OF_SCOPE_WITH_REASON
      :match "prefix:deps/ | equals:deps.lock | equals:deps.archives.lock"
      :reason "vendored dependency lock/manifest (not architecture facts)")
(fact classification-rule R-046 :order 48 :role OUT_OF_SCOPE_WITH_REASON
      :match "prefix:.github/"
      :reason "CI workflow configuration (not architecture facts)")
(fact classification-rule R-047 :order 49 :role OUT_OF_SCOPE_WITH_REASON
      :match "prefix:."
      :reason "repository dotfile configuration (not architecture facts)")
(fact classification-rule R-048 :order 50 :role PRODUCTION_CODE
      :match "depth:0 & suffix:.asd"
      :reason "ASDF system definition (LAWMAX product build)")
(fact classification-rule R-049 :order 51 :role PRODUCTION_CODE
      :match "equals:build.lisp | equals:entrypoint.lisp"
      :reason "product build/entrypoint (LAWMAX product)")
(fact classification-rule R-050 :order 52 :role PRODUCTION_CODE
      :match "depth:0 & equals:Dockerfile | depth:0 & prefix:Dockerfile. | depth:0 & prefix:docker-compose"
      :reason "container build/compose definition (product)")
(fact classification-rule R-051 :order 53 :role OUT_OF_SCOPE_WITH_REASON
      :match "equals:package.json | equals:package-lock.json"
      :reason "node tooling manifest (not architecture facts)")
(fact classification-rule R-052 :order 54 :role OUT_OF_SCOPE_WITH_REASON
      :match "equals:LICENSE | equals:PROVENANCE.yaml | equals:SYSTEM-HIERARCHY.txt"
      :reason "repository licence/provenance/hierarchy manifest (not architecture facts)")
(fact classification-rule R-053 :order 55 :role AUTHORED_NORMATIVE_PROSE
      :match "depth:0 & suffix:.md"
      :reason "repository-root normative document/contract")
