# Implemented levels — reference & verification guide

This is the maintainer map of the correctness/authority stack: what each level does, the
Lisp modules that implement it, the CLI command that runs it, the artifact it produces,
and how to verify it. Every piece is deterministic and reuses the layers below it.

> **Sourcing note (read first).** The proof/gate stack certifies and protects the corpus;
> it does **not** invent legal text. Two codes (`poinikos`, `kpoinikis`) currently carry a
> **stale** official source (the Ministry PDF is pre-2019). The content gate correctly
> **blocks** them. The fix is a *fresh, current* source (latest Isokratis consolidation) —
> a sourcing decision, not a code change. Do **not** establish a golden fingerprint for a
> code until its content is confirmed current (see “Golden” below).

---

## Ingestion — source → clean text

| Piece | Module | Notes |
|-------|--------|-------|
| PDF adapter | `systems/orchestrator-engine-sbcl/adapters/pdf-adapter.lisp` | libpoppler-backed; Isokratis/ΦΕΚ styles |
| **.docx adapter** | `…/adapters/docx-adapter.lisp` | Pure-Lisp OOXML: ZIP (chipz inflate) → `word/document.xml` (cxml-stp DOM) → text → the existing raw-text FSM. Unlocks `kpolitikis` from the Ministry `.docx`. |
| Fetch | `source/document-fetch.lisp` | `fetch-url-pdf` / **`fetch-url-docx`** (drakma, magic-byte validated) + ΦΕΚ blob. `--fetch-pdf` |
| Materialize | `systems/orchestrator-cli/main.lisp` `materialize-pdf-sources` | dispatches by extension (`.docx`→docx-adapter). `--materialize-pdf` |
| Pipeline mode | `main.lisp` `run-pipeline` | PDF mode; **falls back to JSON** when the PDF yields 0 articles (a `:json` source is forced so it loads regardless of `format`). |

Run order for a corpus: `--fetch-pdf` → `--materialize-pdf` → `--run-all-pipelines`.

---

## Level 1 — Proof back to the primary source (ΦΕΚ)

**What.** Every provision’s proof carries a verifiable link to the authentic ΦΕΚ bytes, so
a third party can recompute the digest over the gazette and confirm authenticity — truth
derived from the primary source, not asserted.

- **Module.** `systems/orchestrator-epistemic/primary-anchor.lisp` — `primary-anchor` CLOS
  object on an **`immutable-class` metaclass** (sb-mop): tamper-evident (slots set once).
  `anchor-verified-p` / `anchor-assert` are the verification primitives. Reuses
  `compute-sha256-*` (merkle-tree); ΦΕΚ ref comes from config as a plist (no re-parse).
- **Wiring.** `main.lisp` `%corpus-anchor-plist` → `write-provision-proofs` (`source/proof-carrying.lisp`)
  embeds `primary_source {fek, source_digest, source_uri, locator}` in each proof.
- **Command.** `--emit-proofs` → `output/<corpus>/article-<id>.proof.json`
- **Verify.** Open a proof; `primary_source` must be populated (not `null`).

## Level 2 — Correctness

### 2a. Content-sanity gate (the box must not certify broken law)
The crypto proof certifies the *box*, never the *text*. This gate runs before certification.

- **Module.** `systems/orchestrator-cli/content-validation.lisp` — rules are CLOS classes
  under `content-rule`, **discovered via the MOP class graph** (`sb-mop:class-direct-subclasses`);
  `rule-violations` is the generic. Severity `:block` (fails release) / `:warn`.
  Rules: `empty-body`, `abolished-death-penalty`, `editorial-brackets`, `unbalanced-quotes`,
  `punctuation-artifacts`.
- **Wiring.** `verify-corpus` → `content-gate` over the corpus triples → flows into
  `--verify-all` and the `--auto-update` gate.
- **Command.** `--verify-all` (per-code report; blocking issues fail rc).

### 2b. Replayable amendment ledger (provably-correct consolidation)
- **Module.** `source/consolidation-proof.lisp` — `consolidation-ledger` + `amendment-step`
  (CLOS). Recording rides the existing `consolidate` via the
  `*consolidation-ledger*` / `record-step` hook in `consolidation-engine.lisp` (no driver
  duplication; zero behaviour change when unbound).
- **Command.** `--verify-consolidation` → per code: builds the ledger and **independently
  replays** it, confirming base + ops reproduce the consolidated text exactly.

## Level 3 — Reasoning substrate

### 3a. Intelligence suite (pre-existing, wired)
Reference integrity, extraction anomalies, AST validity, citation centrality.
- **Modules.** `source/legal-references.lisp`, `source/corpus-intelligence.lisp`.
- **Command.** `--verify-all-intelligence` → `output/<corpus>/<corpus>.intelligence.json`.

### 3b. Citation graph as RDF
- **Command.** `--emit-references` → `output/<corpus>/references.ttl` — resolved
  article→article `eli:cites` edges (an AI/court can traverse the law). Reuses
  `orchestrator.references` (`reference-graph` / `graph-edges`).

### 3c. Legal hypergraph (N-ary knowledge model)
Law is N-ary: one act touches a SET of articles; a citation binds a SET.
- **Module.** `source/legal-hypergraph.lisp` — `hyperedge` (abstract) → `amendment-edge`,
  `reference-edge`, `concept-edge`. **Polymorphic serialization**: `edge->turtle` is a
  template-method generic (shared n-ary skeleton + per-subclass `edge-type-uri` /
  `edge-extra-turtle`); adding an edge type = a subclass + two methods, the emitter never
  changes. Edge types discovered via the MOP class graph (`edge-types`).
- **Command.** `--emit-hypergraph` → `output/<corpus>/hypergraph.ttl` —
  `slw:AmendmentEvent` (from the L2 ledger, proof-carrying) + `slw:CitationSet` (from the
  L3 reference graph), W3C n-ary relations pattern → SPARQL-queryable.
- **Pending data.** `concept-edge` (EuroVoc) — class ready, needs a concept source.

---

## Golden fingerprints (drift lock) — *follows* correctness

`--verify-corpus` / `--verify-all` compute a deterministic fingerprint; `GOLDEN_WRITE=1`
establishes the committed golden a future run is compared against. **Establish a golden only
after a code’s content is confirmed current** — goldening stale text blesses the wrong
baseline and produces false drift alarms once the source is fixed. Gate-clean is necessary
but not sufficient (the gate catches known error classes, not “is this the current version”).

Per-code sequence: confirm the source is current → gate clean → `GOLDEN_WRITE=1 --verify-corpus`.

---

## Open, externally-gated work
1. **Correct source** for `poinikos` / `kpoinikis` (fresh Isokratis) — a sourcing decision.
2. **Consensus acquirer** (`source/source-profile.lisp` framework exists) — needs a verified
   current endpoint (Isokratis / e-nomothesia / EU CELLAR) to become operational.
3. **`concept-edge`** population — needs a EuroVoc concept mapping.
