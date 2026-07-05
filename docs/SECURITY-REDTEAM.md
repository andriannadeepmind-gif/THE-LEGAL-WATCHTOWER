# Red-team findings & remediation

An adversarial red-team sweep (multiple independent attackers per surface, each
finding then **refute-verified** by a skeptical second pass) audited the untrusted-input
parsers, the proof/gate trust stack, the network fetch + pipeline orchestration, and the
HTTP/SPARQL/RDF surface. Every finding below survived verification — none are speculative.

Status legend: **FIXED** (closed on this branch) · **OPEN** (needs a build/endpoint/decision).

---

## Fixed on this branch

| # | Severity | Finding | Location | Fix |
|---|----------|---------|----------|-----|
| 1 | CRITICAL | **RCE** via `READ-FROM-STRING` on the `Accept: …;q=` header (`#.` reader macro executes at read time, `*read-eval*` never bound) | `source/corpus-service.lisp` `parse-accept` | Strict numeric-only `q` scanner; the Lisp reader never touches network input |
| 2 | CRITICAL | Custom ZIP parser trusts every EOCD/CD/LFH offset & length → OOB `aref`/`subseq` from a crafted `.docx` | `…/adapters/docx-adapter.lisp` `%zip-locate`/`%zip-entry-octets` | Single `%need` bounds choke point on every attacker field → clean `DOCX-MALFORMED` → NIL fallback |
| 3 | HIGH | **Zip-bomb**: `chipz:decompress` with no size cap → OOM | `docx-adapter.lisp` inflate path | Decompress into a fixed `usize` buffer with a 256 MB ceiling; oversize declared size rejected up front |
| 4 | HIGH | Content gate death-penalty regex bypassed by `θανατική ποινή`, unaccented, double-space, capitalized, euphemism | `…/content-validation.lisp` `abolished-penalty-rule` | Greek normalization (strip accents/final-sigma, downcase, fold NBSP/zero-width, collapse whitespace) then match every attested phrasing |
| 5 | HIGH | Empty-body rule only detects whitespace (NBSP / `.` / `[…]` pass as "content") | `content-validation.lisp` `empty-body-rule` | Substance check: requires ≥1 alphanumeric after normalization |
| 6 | HIGH | **SSRF**: no host validation; `:redirect 5` follows 3xx to internal/metadata hosts; response written before validation | `source/document-fetch.lisp` `%fetch-url-to-file`, `source/government-source.lisp` `fetch-url` | Per-hop host guard (http/https only; reject loopback/private/link-local/metadata/localhost); redirects followed manually and re-checked each hop; one shared guard, no duplicate policy |
| 7 | HIGH | SPARQL **query-of-death**: unbounded N^k BGP join materialized before LIMIT; unauthenticated GET | `source/sparql-endpoint.lisp` `evaluate-bgp`/`sparql-select` | Per-row budget cap during the join (`*sparql-max-bindings*`) + pattern-count cap; aborts as `SPARQL-RESOURCE-LIMIT` (an `error`, caught by the endpoint handler) |
| 8 | MEDIUM-HIGH | Turtle **injection**: `~S` emits fek/label/operation fields without escaping newline/tab/CR | `source/legal-hypergraph.lisp` | `%ttl-lit` escaper choke point for every attacker-controlled literal |
| 9 | MEDIUM-HIGH | Turtle **injection** in `eli:date_applicability` (raw, unescaped, unvalidated) → forged triples | `source/consolidation-engine.lisp` `render-consolidation-provenance-ttl` | `%xsd-date-or-nil` validates the date; `%ttl-escape` extended to CR/Tab |
| 10 | MEDIUM-HIGH | **Silent data loss**: a partial extraction (even 1 junk article) overwrites a full corpus; guard only checks `(null iirs)` | `systems/orchestrator-cli/main.lisp` `materialize-pdf-sources` | Shrink guard: refuse when new count < half the existing populated count (`ORCHESTRATOR_ALLOW_SHRINK=1` overrides) |
| 11 | MEDIUM | HTTP **slowloris / unbounded head read**: no size cap, no terminator → per-connection heap growth | `source/http-server.lisp` `read-request-head` | 64 KiB head cap; oversize/unterminated head aborts the connection |
| 12 | LOW | `READ-FROM-STRING` with active `#.` on untrusted word-vector model tokens | `source/embeddings-authority.lisp` `parse-float` | Bind `*read-eval*` NIL |
| 13 | (correctness) | `arweave-upload` fabricates success (no signing, no submission, no `:tx-id`) → false "permanent anchor" provenance claim | `source/blockchain-authority.lisp` | Returns `:submitted nil :status :prepared-not-submitted`; logs it did NOT submit |

---

## Open — require a build, a real endpoint, or a design decision

These are the highest **conceptual** severity: the trust stack proves internal
consistency but not authenticity. Fixing them changes cryptographic behaviour and
must be validated against real TSAs/gateways and the full build — not patched blind.

### O-1 (CRITICAL, systemic) — Level-1 anchor binds the wrong bytes — **FIXED (needs build validation)**
`systems/orchestrator-epistemic/primary-anchor.lisp`, `systems/orchestrator-cli/main.lisp` `%corpus-anchor-plist`.
The anchor now carries a second digest, **EXTRACTION-DIGEST**: SHA-256 over the ordered
served `(id . text)` provisions — the deterministic derivation of the primary bytes via a
named **EXTRACTION-METHOD** (e.g. `docx-adapter+raw-text-fsm@1`). The proof gate now calls
`anchor-assert :articles <served provisions>` — a real check that the served text
reproduces the recorded derivation — instead of the old `:file src` tautology (which hashed
the source file and asserted it against its own hash, binding nothing to the served text).
Because the served proofs' leaves ARE those same article texts, the chain
`primary bytes → adapter → served text → leaves → Merkle root → signature` is recomputable
end to end by a third party. `anchor->plist` emits `extraction_digest` + `extraction_method`
(flows to proof JSON automatically). **Still to validate under a build**, and the residual is
honest: for a *scanned* ΦΕΚ (no text layer) a third party cannot re-run the adapter over the
image — the derivation-reproducibility holds for digital sources (docx); source-digest still
binds the primary file in all cases.

### O-2 (HIGH, thematic — five findings, one root) — verification theatre in the time/anchor authorities
- `timestamp-authority.lisp` `verify-timestamp` (~345/374): byte-scans the TSR for
  `04 20 <hash>` — **no** CMS/SignedData signature check, **no** TSA cert chain, **no**
  TSTInfo/genTime parse. Any hand-crafted ASN.1 blob is accepted.
- `timestamp-authority.lisp` `submit-to-tsa` (~161): accepts on HTTP 200 + first byte
  `0x30`, no token verification.
- `timestamp-authority.lisp` nonce (~345): generated but never checked → replay.
- `blockchain-authority.lisp` `verify-anchor` (~921): Arweave/IPFS "verify" checks only
  HTTP 200, never that the fetched bytes hash to the claimed value.
**Fix direction:** real RFC-3161/CMS verification (parse TSTInfo, verify SignedData,
validate TSA chain to a trust anchor, match messageImprint, check nonce); for anchors,
fetch content and compare its hash/merkle-root before returning T. Needs real endpoints
+ a crypto library + build.

### O-3 (HIGH) — unauthenticated JSON fallback has no provenance — **FIXED (needs build validation)**
`systems/orchestrator-cli/main.lisp`.
Materialize now writes a provenance sidecar `<source.json>.prov.json`
(`%write-source-provenance`) binding the file's content SHA-256 to the primary
`source_digest` + `extraction_method` + date; the preserve branches (scanned ΦΕΚ /
shrink-guard) stamp the existing file too, so every served corpus carries a record.
The JSON fallback (`run-json-mode`) now **refuses** to promote a `source.json` whose
sidecar is missing (foreign/legacy) or whose content hash no longer matches
(tampered/substituted) — `%source-provenance-valid-p`. Override for a deliberate,
logged exception: `ORCHESTRATOR_ALLOW_UNVERIFIED_JSON=1`. Hashing reuses the epistemic
`compute-sha256-*` primitives (no duplicate hashing). **Validate under a build**; note a
one-time `--materialize-pdf` run is needed to stamp existing corpora.

### O-4 (MEDIUM, defense-in-depth) — config is a full trust boundary
`source.fetch_cmd` → `sh -c` is RCE-by-design for anyone who can edit a corpus YAML;
`{{out}}` templating is unquoted; `source.pdf/json/docx` paths are used unvalidated.
**Fix direction:** treat config integrity as security-critical (documented), and/or
sandbox the fetch command and quote/validate templated paths.

### O-5 (LOW) — `immutable-class` is defense-in-depth, not a boundary
`primary-anchor.lisp`: `change-class` / `slot-makunbound-using-class` are not guarded.
Acceptable given the in-image threat model; do not rely on it as a security control.

---

## Where the system is genuinely solid
No memory-safety bugs beyond the ZIP parser (now fixed), no SQL injection, no credential
leaks. The **Merkle proof verifier is sound** (RFC-6962 domain separation, correct path
walk, inclusion→root→JWS chain). The **consolidation replay ledger is real** (independent
recompute, not a tautology). `clean-corpus-output-dir` has a genuine depth/absolute-path
guard. Magic-byte validation correctly stops an anti-bot HTML page from being ingested as
law. The architecture shows consistent intent toward correct escaping and provenance — the
open items are unfinished wiring, not absent design.
