# IMPLEMENTATION-BOOK MIGRATION IMPACT — v1.7 (REPORT ONLY · Book NOT changed)

**This is a REPORT.** It records how a FUTURE Implementation-Book revision would absorb v1.7. It does **not**
change the Implementation Book (v1.0 / v1.1 stay bound to frozen `88129099`), starts no WP, moves no file, and
changes no production code. Parent `f05f5514`. Classification `INFORMATIVE`. Every WP row is validated against
the **actual** `IMPLEMENTATION-BOOK/WORK-PACKETS/WP-NN.md` (purpose/requirements/paths/symbols/interfaces/tests/
migration/rollback/exit-gate) — C-6. Where **no** packet owns a v1.7 concept the row says
`FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED`; no false mapping is invented.

## 1. Per-WP v1.7 impact (future revision — NOT applied; grounded in WP-NN.md)
| WP | actual seat/purpose (WP-NN.md evidence) | v1.7 impact | disposition |
|---|---|---|---|
| WP-00 | clean reproducible base + green CI (`.github/workflows`, image digest) | no v1.7 concept lands here | KEEP |
| WP-01 | census + coverage ledger (`coverage-ledger.lisp`, `RegistrySnapshot`) | RA-F fast-lane freshness SLO per census space; C-11 coverage guard (availability live). WP-01-a (U-7 lawfully-publishable courts) is a rights gate feeding RA-L | EXTEND |
| WP-02 | acquisition + Secure Semantic Ingress sandbox (`ingress-decoder.lisp`, `taint-state.lisp`) | RA-F provisional acquisition via SA-0/1/2; security §14 non-evaluating decoder unchanged; neural/model → WP-07 | EXTEND |
| WP-03 | typed Legal IR + **bitemporal event store** (`journal.lisp` L1, `version-graph.lisp`, `legal-temporal.lisp`, `eu-interop-layer.lisp`) | **nearest substrate to MEMORY** (temporal/provenance/episodic continuity only); ELI event linkage feeds RA-I resolver; §7 time-kinds live here. Full memory kernel **NOT** owned here | EXTEND (substrate only) |
| WP-04 | first Legal Compiler A (`consolidation-engine.lisp`) | unchanged; Common-Lisp-native contract applies to the CL compiler | KEEP |
| WP-05 | second compiler B (Rust) + differential | unchanged; two compilers share only normative semantics + conformance corpus (§10) | KEEP |
| WP-06 | MLTP v3 + Trust Mesh + crypto agility (owns `TrustBundle`, `crypto-policy-epoch`) | RA-INST institutional auditor/witness registries (WP-06-b, U-2) feed tenant profiles; crypto agility = §14 | EXTEND |
| WP-07 | external neural runtime (`neural-runtime/`, `neural-candidate/1`, ontology bundle) | **C-10:** `neural = Python + ONNX Runtime` (toolchain-freeze) → OPTIONAL `ONNXProposerAdapter`; ontology/shapes epochs = §7 | EXTEND (Book edit required §5) |
| WP-08 | epistemic wall / Public Legal Discernment core (`legal-inference-engine.lisp`, `write-authority.lisp`) | hosts the Language Cognition Layer (§8) + the type-correct cognition DAG (C-2); single journal write seat (C-7) | EXTEND |
| WP-09 | jurisprudence evolution (`legal-decisions.lisp`, ECLI impl, reviewer registry, `authority_weight`, LATER-TREATMENT) | **RA-J** access-basis register + acquisition profiles + `AnonymizationReceipt` + EN headnotes (RA-E). WP-09-a (U-3 doctrine/full-text licensing + anonymization) feeds RA-L. Owns the **ECLI** seat for RA-I | EXTEND |
| WP-10 | Digital Twin + impact projection (`normative-impact-projection`, ELI-Impact) | counterfactuals stay overlays/branches (§7); ELI emission feeds RA-I | KEEP |
| WP-11 | proof-carrying query / MCP / SDK + citation-bound (`canonical-uris.lisp`, `ai-corpus-dump.lisp`, `ai-ingest-manifest.lisp`, JSON-LD, SPARQL, Akoma Ntoso) | **RA-R** canonical URIs (owns `canonical-uris.lisp`); **RA-T** dataset distribution (owns signed delta feeds); **RA-I** resolver front extends `canonical-uris.lisp`; provider integration R-101..R-110 feeds RA-INST | EXTEND |
| WP-12 | website + cockpit + public→private (`static-site.lisp` `/lawmax/{path}`, `cockpit.lisp`, `approval-policy.lisp`) | **RA-R** public retrieval surface (owns `static-site.lisp`); §11 cockpit = signed proposal/approval, no direct canonical write; `DeclassificationReceipt` public→private | EXTEND |
| WP-13 | citation + security/operational observatory (`ai-citation-strategy.lisp`, `prometheus-citation.yml`, provider-compliance monitor) | **RA-K** citation-supremacy measurement (owns the citation observatory); §14 security monitoring | EXTEND |
| WP-14 | mission qualification + provider adoption (`LocalTrustState.provider_registry`, QSR) | **RA-INST** provider registry (owns `provider_registry`); **RA** Root-Authority qualification state = typed/expiring QSR (auto-downgrade) | EXTEND |

## 2. v1.7 concepts with NO owning packet → `FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED`
Validated against WP-00..WP-14 — these are **not** owned by any existing packet; a future Book revision MUST
declare a new packet (no false mapping):
1. **Memory kernel** (13-type taxonomy). Only WP-03's bitemporal event store overlaps (temporal/provenance/
   episodic). **`FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED`** — this is the C-1 resolution: NOT WP-11.
2. **Unified ELI/ECLI/CELEX resolver** (RA-I). ELI (WP-03/WP-10), ECLI (WP-09), canonical URIs (WP-11) exist as
   scattered emitters/linkers; **CELEX resolution is in zero packets**; there is no single resolver seat.
   `FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED` for the unified resolver + offline resolution dataset.
3. **License/Rights matrix construction** (RA-L). Only external decision gates exist (WP-01-a U-7, WP-09-a U-3);
   no `RightsMatrix` data structure. `FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED` (the spec seat is
   `LAWMAX-LICENSE-POLICY.md`; construction is future).
4. **Content-negotiation + sitemaps** (RA-R). Canonical URIs and the static site exist (WP-11/WP-12); content
   negotiation and per-census-space sitemaps are in zero packets. `FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED`.
5. **Multi-tenant provider/institutional profiles** (RA-INST). A provider *registry* (WP-14) + RBAC roles
   (WP-12) + institutional trust registries (WP-06) exist; a per-tenant *profile* abstraction does not.
   `FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED` (v1.7 locks interfaces only, §RA-S26).

## 3. RA delta → real seat (EXTEND, no second emitter)
`RA-R` → `static-site.lisp` (WP-12) + `canonical-uris.lisp` (WP-11). `RA-I` → `canonical-uris.lisp` front +
`eu-interop-layer.lisp` (WP-03) + ECLI (WP-09); unified resolver packet = FUTURE. `RA-J` → `legal-decisions.lisp`
/ reviewer registry (WP-09). `RA-K` → citation observatory (WP-13). `RA-T` → `ai-corpus-dump.lisp` /
`ai-ingest-manifest.lisp` (WP-11). `RA-INST` → `LocalTrustState.provider_registry` (WP-14) + interface-only
`RA-S26`. `RA-E` → USC expression model + multilingual point (WP-03/WP-09). `RA-L` → new spec seat
`LAWMAX-LICENSE-POLICY.md`.

## 4. Memory (C-1) — single true owner
Memory kernel owner = **`FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED`**. No existing WP owns a memory kernel;
WP-03's bitemporal event store is the ONLY substrate overlap (temporal / source-provenance / episodic
continuity). The prior v1.6 residual "built in WP-11" is superseded and corrected. `memory.lisp` remains the
ONE runtime seat to EXTEND when that future packet is declared — no second memory system.

## 5. Model independence (C-10) — future Book modifications (RECORDED, not applied) + retirement gate
| # | location (file:line) | current (verbatim) | FUTURE modification |
|---|---|---|---|
| 1 | `WP-07.md:25` | "**Toolchain freeze:** neural = **Python + ONNX Runtime** (out-of-process, PLANE-3)…" | neural = OPTIONAL `SemanticProposer` adapter(s); `ONNXProposerAdapter` `:mandatory nil`; absent ⇒ `SafetyMode :SYMBOLIC_ONLY`; `runtime_manifest_sha256` = conformance pin only |
| 2 | `WP-07.md:17` | "\| neural runtime \| **NEW** `neural-runtime/` \| Python/PyTorch/ONNX \| NEW \|…" | OPTIONAL adapter, replaceable, non-authoritative, disableable (fail-closed) |
| 3 | `IMPLEMENTATION-BOOK/…v1.1.md:118` | "\| WP-07 \| Python + ONNX Runtime (external, PLANE-3)…" | OPTIONAL external adapter runtime (any `SemanticProposer`; ONNX one reference impl), non-mandatory |
| 4 | `PUBLIC-OBSERVATORY-CROSSWALK.md:388` (CAP-40) | "εξωτερικό νευρωνικό runtime (Python/PyTorch/ONNX) … HAS_SEAT" | OPTIONAL `SemanticProposer` capability via `ONNXProposerAdapter` `:mandatory nil` |
| 5 | `TRACEABILITY-MATRIX.md:65` (R-32) | "νευρωνικό runtime εξωτερικό (Python/PyTorch/ONNX ή ανώτερο)" | OPTIONAL model-agnostic `SemanticProposer` (any/none); no mandatory model/runtime (`V6I-02`) |

**Retirement gate (C-10, mandatory — NOT a soft UNKNOWN):** at any FUTURE re-freeze, retiring the old
Implementation Book as *execution authority* is a required GATE
`RA-RETIRE-GATE → owner=creator → required evidence=v1.7 successor Book supersedes v1.0/v1.1 with the model
edits above applied → entry gate before any new freeze → failure state=block re-freeze`. Rows 4/5 are in the
v1.4-count-bearing blocks and are **NOT** edited here.

## 6. What is explicitly NOT done here
No Implementation-Book file edited; no second Book created; no WP started; no file moved; no production code; no
freeze/re-freeze; no qualification claim; no v1.4-count-bearing row touched. All revisions above happen only
under a future explicit creator order after v1.7 passes one final bounded independent review.
