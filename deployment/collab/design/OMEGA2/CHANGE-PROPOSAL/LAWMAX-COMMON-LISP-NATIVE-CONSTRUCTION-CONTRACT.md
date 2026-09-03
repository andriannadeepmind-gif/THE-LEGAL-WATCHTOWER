# LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT (v1.7 CANDIDATE · NORMATIVE)

**Parent `f05f5514`. Design-only.** The single normative seat for making the future system genuinely
**Common-Lisp-native** — not a Python-style imperative program transliterated into Lisp. Each advanced Lisp
mechanism is admitted ONLY with a proven benefit and the eight-field discipline
`reason → seat → requirement → invariant → test → fallback → migration → rollback`. **Macro / MOP /
metaprogramming without a demonstrated benefit is forbidden** — maximal use of the language never means
gratuitous complexity. Seats marked `[design-target]` are registry-declared with no source file yet (honest).

## 1. Language-independence of the Legal IR (hard boundary)
The Legal-IR semantic contract (`LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md` + `source/legal-ast.lisp`) is
**language-independent**. Compiler A (Common Lisp, WP-04) and compiler B (Rust, WP-05) **share no evaluator
code** — they share ONLY the normative semantics and the conformance corpus, so the design avoids **both**
arbitrary divergence **and** common-implementation failure. This is a constraint on §2 below: no CL mechanism may
leak into the IR contract such that a non-Lisp compiler cannot conform.

## 2. Per-mechanism admission (grounded in real seats)
| mechanism | reason | seat (file:symbol) | requirement | invariant | test | fallback | migration | rollback |
|---|---|---|---|---|---|---|---|---|
| CLOS classes | typed domain objects with inheritance | `knowledge-graph.lisp:116 knowledge-graph`, `legal-decisions.lisp:71 legal-decision`, `cognition.lisp:46 working-memory` | typed Legal objects | one class per concept (constitution `:no-duplicate`) | class-slot conformance | plain structs | additive slots, versioned | revert class, keep data |
| generic-function multimethods | open dispatch for analyzers/stages/adapters | `cognition.lisp:107 defgeneric triage / plan / execute-step / synthesize` | pluggable cognition stages | dispatch is total or errors typed | per-method unit test | single dispatch fn | add methods, no core edit | remove method |
| method combination | ONLY where a real accumulation/ordering benefit exists | candidate: proof aggregation (`proof-carrying.lisp`) | proof composition | no `:around` that hides a forced winner | combination test | explicit fold | introduce only with benefit | drop to explicit fold |
| MOP (metaobject protocol) | **NOT USED in the trusted path** | — (none) | — | forbidden without a specific proven invariant (§10) | n/a | standard CLOS | admit only with a named invariant + test | n/a |
| condition/restart | controlled ambiguity/recovery, no silent failure | `safe-read.lisp:safe-read-error`; cognition clarification (COG7-11) | typed errors, never a guess | every error is a typed condition | restart-driven test | return typed error value | add restarts, no core edit | remove restart |
| macros / DSLs | grammar/morphology/Legal-IR/rules as data | `greek-legislation-ontology.lisp:57 defconcept`, `capability-registry:define-capability`, `mcp-server:define-mcp-tool`, `legal-event-calculus:defrule ec-*` | declarative rule/grammar definition | macros expand at compile time only; NEVER over external bytes | macroexpand golden test | hand-written forms | additive macro clauses | expand + inline |
| declarative pattern matching / rule definitions | rules as inspectable data | `legal-event-calculus:defrule`, `rdfs-inference:apply-rdfs-rules`, `legal-inference-engine:unify` | symbolic legal reasoning | rules are data, not opaque code | rule-firing test | procedural branch | add rules | remove rule |
| immutable / persistent canonical objects | content-addressed identity | hash-bearing records (`expression_id`,`manifestation_id`); `journal.lisp:chained-append` | immutable identity body | identity = content-address; lifecycle detached (v1.5 R2) | hash-stability test | copy-on-write | additive fields, re-hash new version | keep prior version |
| incremental truth maintenance (JTMS) | dependency-directed recomputation of legal conclusions | `legal-inference-engine.lisp:238 make-jtms` | retract/recompute on new evidence | belief revision is monotone-audited | JTMS revision test | full recompute | wire JTMS into consolidation | disable JTMS, full recompute |
| dependency-directed recomputation | avoid full recompute on small deltas | JTMS (as above) + `corpus-diff.lisp` | efficient re-consolidation | recomputation is deterministic + replayable | replay test | full recompute | additive | full recompute |
| memoization with epoch invalidation | cache derivations, invalidate on epoch change | ontology/shape epoch (`shacl-validator.lisp` + `mltp3:ontology-bundle`) | epoch-scoped caching | a cache entry names its validation epoch; epoch change invalidates | epoch-invalidation test | no cache | add epoch key | flush cache |
| package / ASDF boundaries | enforced module isolation + forbidden deps | 16 ASDF systems / 53 edges (acyclic, [0146]) | declared forbidden dependencies | package boundary = capability boundary | ASDF graph cycle check (exit 0) | monolith package | split additively | merge back |
| compile-time validation | schema/invariant generation at compile time | `constitutional-gate.lisp` + compile-time schema | fail at build, not runtime | invariants checked at compile time | build gate | runtime check | move checks to compile time | runtime check |
| interactive image development | fast REPL development | dev image only | dev velocity | **NEVER a mutable canonical shortcut**; canonical writes only via write-authority.lisp | reproducible build test | batch build | dev-only | discard image |
| deterministic serialization | reproducible hashing/roots | `journal.lisp:canon-sexp` | byte-identical roots | one canonical serialization boundary | dual-compiler root equality | explicit encoder | additive | pin encoder |
| no read/eval/macro over external input | external bytes never become code | `safe-read.lisp` (internal-only) + `ingress-decoder.lisp` (non-evaluating) | §14 security | no `cl:read`/`eval`/reader-macro/`compile`/macroexpand on external bytes | SIK-1..9 | reject input (fail-closed) | keep boundary | n/a |

## 3. Discipline
- Every row above is admitted because it has a **proven benefit** and a **fallback** — remove the mechanism and
  the system still works (more slowly / more verbosely), never breaks.
- **MOP is deliberately absent** from the trusted path: no named invariant currently requires it, so it is not
  used (§10). It may be admitted later ONLY with `reason/seat/requirement/invariant/test`.
- The two compilers' independence (§1) is the ceiling on CL-nativeness: a mechanism that a Rust conformer cannot
  mirror at the **semantic** level (not the code level) is confined to the CL compiler's private implementation,
  never the shared Legal-IR contract.
