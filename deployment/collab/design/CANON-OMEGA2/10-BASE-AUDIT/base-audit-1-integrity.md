# BASE AUDIT — LAYER 1: INTEGRITY / WRITE / MEMORY SPINE

**Stance:** adversarial, uncharitable. The prior transformation marked these seats KEEP/light-REFACTOR
on the assumption the foundations are sound. This audit falsifies that where false, by reading the REAL
code. Mission frame: "top legal OBSERVATORY of Greece" + trusted spine — a system that must *never lose
or forge a record*, holding *many matters*.

**Claim-status tags:** THEOREM / DESIGN-ENTAILED / IMPLEMENTED / DEMONSTRATED / EMPIRICAL / HYPOTHESIS /
UNKNOWN. Every code claim below was read directly (line-cited). "exists and runs" ≠ "correct" ≠ "top."

---

## 0. HEADLINE — the single most serious foundational defect

**`emit-graph` (`source/write-authority.lisp:16-51`) — the writer of the actual legal corpus — has NONE
of the integrity properties the "spine" advertises, while the entire append-only / hash-chain / Merkle /
fsync apparatus protects only the system's *self-metadata* (biography + episodes).** `[DEMONSTRATED]`

The observatory exists to hold Greek law, decisions, named judges, doctrine. Those records are emitted as
RDF/TTL through `emit-graph`, which is:

```lisp
(with-open-file (stream output-path
                        :direction :output
                        :if-exists :supersede          ; ← TRUNCATE-OVERWRITE: the OPPOSITE of append-only
                        :if-does-not-exist :create)
  (write-string content stream))                       ; ← no fsync, no atomic tmp+rename, no lock
                                                        ; ← no hash-chain, no Merkle leaf, no journal record
```

- **Not append-only.** `:if-exists :supersede` truncates and rewrites the file in place. There is no
  version chain, no prior-hash link, no tamper-evidence on the corpus content. An overwrite leaves no trace.
- **Not crash-safe.** No `write-file-atomic`, no fsync of file or directory. A crash mid-`write-string`
  leaves a truncated/half-written TTL as the record of law. `journal.lisp` has `write-file-atomic`
  (tmp+fsync+rename+dir-fsync, lines 552-576) — `emit-graph` uses none of it.
- **Not single-writer.** No `with-journal-lock`, no flock. Two processes emitting the same path race and
  one silently wins (supersede). The journal's cross-process flock discipline is absent here.
- **"authority" is not authority.** The `:authority` parameter is a dynamic-variable `eq` check against
  `*current-write-authority*` (lines 38-41) — a thread-local lint that catches `:canonical`/`:provenance`
  mix-ups. It carries no signature, no capability, no audit entry. The banner "This is the ONLY authorized
  write function for RDF content" is **false**: `grep` finds direct `with-open-file :output` writers across
  `source/` (proof-carrying, government-source, ai-citation-strategy, static-site, signed-embedding-manifest,
  corpus-fingerprint, pdf-authority, legal-audit-system, x509, review-queue, eu-interop-layer, …). "One
  write seat per concept" is aspirational, not enforced.

**Consequence:** the CANON-Ω2 K-write invariant I-WRITE ("append-only, tamper-evident, externally
anchored") is discharged for the biography/episode journals and **NOT discharged for the corpus** — the
records that matter most. `[DESIGN-ENTAILED gap]` **VERDICT: REPLACE** (route all corpus emission through
a journaled/atomic/anchored write seat; retire naive supersede I/O for records of record).

---

## 1. PER-SEAT VERDICTS

### 1.1 `source/journal.lisp` — **UPGRADE-IN-PLACE**
*Genuinely the strongest seat in the layer.* Cross-process single-writer is **structural**, not a
convention: recursive thread-mutex + `flock(2) LOCK_EX` on `<path>.lock` covering the whole
read-tail→build→append→fsync→cache cycle (lines 104-170). Compare-and-append (`chained-append`, 507-542)
verifies the new record's back-link against the **real file tail** before writing → chain-fork is
structurally rejected (`stale-chain-link`). Honest persistence receipts distinguish `:durable` (real
fsync) from `:sync-failed`/`:degraded-memory-only` (lines 383-479); poison-line pre-validation before disk
(`%validate-serializable`, 352-361); monotonic transaction-time guard (`%check-monotonic-at!`, 369-381);
resilient per-line read that declares and skips torn tails without losing following records (`%load-lines`,
265-292); `write-file-atomic` does tmp+fsync+rename+**dir-fsync** (552-576). This is real engineering.
`[IMPLEMENTED/DEMONSTRATED]`

**Defects found:**
- **(a) TOP — no external anchor in the write path.** The journal is a *self-referential linear SHA-256
  chain* (`:prev`→`:hash`). Nothing in `journal.lisp` calls `merkle-authority`, `timestamp-authority`, or
  `blockchain-authority` on append. Append-only is enforced only by the code that goes through
  `append-line` — NOT by the filesystem (no `chattr +a`/WORM) and NOT by any published anchor. An actor
  with write access to the `.sexp` file **plus** the code can rewrite the entire history, recomputing every
  `:prev`/`:hash`, and `verify-chain` will pass. **A hash chain without an independent anchor is
  tamper-*evident only to someone who kept an out-of-band root* — which is never captured here.** For "never
  forge a record," this is the load-bearing gap. `[DESIGN-ENTAILED; the comment "η ιστορία δεν ξαναγράφεται"
  is HYPOTHESIS, not enforced]`
- **(b) WORK — torn-create window.** `append-line` fsyncs the file stream (`%fsync`, line 424) but never
  the parent directory. `%fsync-directory` is called **only** in `write-file-atomic` (line 574), never in
  `append-line` (confirmed by grep: only defn:236 + call:574). On the *first* append to a new journal path,
  a power loss after `fsync(file)` but before the new directory entry is durable loses the **whole file** —
  yet the returned receipt already reported `:durable`. This violates the seat's own "id ⟺ durable" law for
  the genesis record of each stream. `[DEMONSTRATED code path]`
- **(c) minor — unlocked fallback.** When the `.lock` fd cannot be created, `%call-with-file-lock` proceeds
  and calls the body *without* flock (lines 141-147). Intended for read-only-FS degradation, but if the
  lockfile is transiently uncreatable while the journal file itself is writable, two processes can write
  unlocked. Low probability; note it.

*Fix: call `%fsync-directory` on file-creation in `append-line`; wire a per-append (or batched)
TSA/Merkle anchor so the chain root is externally witnessed; make the unlocked path fail-closed.*

### 1.2 `source/self-history.lisp` — **UPGRADE-IN-PLACE**
`verify-chain` (80-90) recomputes `%entry-hash` from the fields and checks both the `:prev` link and the
recomputed hash — **not** a tautology (it does not trust the stored `:hash`). `[IMPLEMENTED]`

**Defect:** `%entry-hash` (36-37) = `SHA-256("SEQ|AT|KIND|TEXT|PREV")` — a **naive `|`-delimited join**,
**not** an injective canonical serialization. A `:text` containing `|` (or the shape of a following field)
makes the pre-image ambiguous → a delimiter-injection / non-injective-encoding surface on the biography
chain. Crucially, `memory.lisp` **already fixed exactly this class** (RATCHET-3: migrated episode hashing
to `journal:canon-sexp`, "συνάρτηση της ΑΞΙΑΣ, ποτέ της αναπαράστασης") — the biography seat was left on
the old naive join. Inconsistent hardening within the same system. Severity is bounded (genesis inputs are
creator-controlled), but for a "0 λάθος / εξάλειψη της κλάσης σφάλματος" spine the *class* is live here
after being killed one file over. `[DEMONSTRATED]` Also inherits journal defect 1.1(a).
*Fix: hash via `canon-sexp` of the sealed field-plist, matching memory.lisp.*

### 1.3 `source/merkle-authority.lisp` — **KEEP-AS-IS**
Correct RFC-6962/9162: domain separation (`0x00` leaf / `0x01` node, raw-byte concat — 63-81); unbalanced
split via `%largest-power-of-two-below` (**no** duplicate-last → CVE-2012-2459 class structurally excluded,
87-119); canonical empty-tree = `SHA-256("")`; inclusion path + `verify-inclusion` (134-235); and a faithful
**consistency proof** (`consistency-proof`/`verify-consistency`, 170-225) implementing the §2.1.2 subproof
recursion, fail-closed on malformed hash strings. Second-preimage between leaf and internal node is closed
by the prefix. This is production-grade. `[IMPLEMENTED, faithful to spec]`
**Limitation (not a seat defect):** it is **not wired to the live journal** — `merkle-tree-hash`/
`merkle-root-of-files` are used only at *release* over file-sets. So the transparency-log append-only
*property* (old-root ⊑ new-root, provable to a third party without the leaves) is **not** available on the
running biography/episode streams; those rely solely on the linear chain (see 1.1(a)). For a TOP observatory
that publishes verifiable-inclusion to relying parties, the per-record Merkle log is a needed *wiring*, not
a new seat.

### 1.4 `source/memory.lisp` — **RESTRUCTURE**
Chain integrity is correct: `verify-episode-chain` (167-197) recomputes each `:hash` abstractively (whole
line minus `:hash`, via `canon-sexp` for `:hv 2`) — catches mutation of ANY sealed field, not just the
`:prev` link. `[IMPLEMENTED — RATCHET-3, genuinely non-tautological]`

**FOUNDATIONAL LIMITATION (mission-level): the memory substrate is globally shared, single-tenant.**
The brief asks directly: "is memory.lisp per-matter isolatable or globally shared (the observatory will
hold many matters)?" Answer, from the code: **globally shared, one stream, no matter concept exists.**
- One store: `*episodes-path*` = `deployment/self/episodes.sexp` (45-46) — a single global file.
- `record-episode` (79-111) has **no `matter-id` parameter**; the sealed body carries `:at :session :id
  :kind :text :topic :status :props :lemmas :prev :hv` — **no matter/tenant field at all**.
- `episodes`, `find-episodes`, `similar-episodes`, `open-goals`, `armed-intentions` all fold/scan the
  **entire** global stream (113-302). `similar-episodes` (285-302) recalls across ALL matters by lemma
  overlap.
- `*session*` (48) and `*intention-conditions*` (239) are global specials.

There is no compartment, no capability, no `WHERE matter=`, and (per CANON §5.4) even a `WHERE` clause would
be the wrong shape — isolation must be *absence of a handle*. As written, matter B's episodes are visible to
any matter-A query → **direct violation of matter isolation / ethical-wall duty** (autopsy BLOCK-1; CANON
§5.4). This is not "needs it to be TOP" — it is "needs it to satisfy the mission's binding (many matters,
Chinese walls)." `[DEMONSTRATED single-tenant design]` **RESTRUCTURE** to a per-matter-partitioned episode
store keyed by an unforgeable matter capability; the linear-chain idiom can stay, one chain *per compartment*.

### 1.5 `source/write-authority.lisp` (`emit-graph`) — **REPLACE**
See §0. The corpus write seat is supersede-truncate + no-fsync + no-atomic + no-lock + no-record + a
thread-local eq "authority" flag. It is the antithesis of the append-only spine and it governs the records
the observatory is *for*. `[DEMONSTRATED]`

### 1.6 `source/validation-authority.lisp` — **RESTRUCTURE**
Runs before `emit-graph`. Turtle "syntax" is a hand-rolled char state machine (quote/URI/comment parity,
93-171) — catches gross breakage only. The FRBR "structure contract" is **substring presence**:
`(search "eli:LegalResource" ttl)`, `(search "eli:hasWork" ttl)`, `(search "eli:jurisdiction" ttl)`, etc.
(220-259). This is **tautology-adjacent assurance**: it asserts the emitter's own tokens appear *somewhere*
in the string — a comment or a literal containing `"eli:LegalResource"` passes; a semantically-broken graph
with the right tokens passes; a *valid* graph that binds the `eli:` prefix to a different IRI, or reorders,
fails. It is not an RDF/Turtle parse and cannot validate triples, subjects, or graph well-formedness. For a
"top" observatory this gate demonstrates *shape*, not *correctness*. `[IMPLEMENTED but low-assurance; the
FRBR check is a finding, not assurance]` **RESTRUCTURE** to an actual Turtle parse + graph-shape check
(SHACL-class, in-repo — the no-external-dep rule permits a real parser seat).

### 1.7 `source/timestamp-authority.lisp` — **KEEP-AS-IS**
`verify-tsr-cryptographically` (698-900) is genuinely thorough RFC-3161 / CMS (RFC 5652): strict outer/inner
DER bounds (no trailing bytes), PKIStatus ∈ {granted, grantedWithMods}, `messageImprint ≡ digest(message)`
**positionally** (not containment), `signedAttrs.messageDigest ≡ digest(TSTInfo)` + `contentType`, signature
over re-tagged `SET signedAttrs`, signer selected *by which embedded cert verifies*, **ESSCertID binding**
(kills cert-injection), **id-kp-timeStamping EKU** required, **genTime within signer validity**, and a
pinned-CA anchor tier. `:unpinned` is honestly labeled as authenticating *nothing* about who signed.
Fail-closed throughout. `[IMPLEMENTED — production-grade verification]`
**Note:** not auto-invoked on journal append (anchoring is manual/release-time — see 1.1(a)). The old
byte-scan verifier is retired (single seat). Hand-rolled ASN.1 lives in `orchestrator.asn1` (out of scope).

### 1.8 `source/jws-authority.lisp` — **KEEP-AS-IS (light)**
Solid RS256: full EMSA-PKCS1-v1_5 encoded-message built manually over raw ironclad primitive (320-372),
`verify-jws` pins `alg=RS256` from the signed header (defeats alg-confusion / `alg:none`), requires exactly
3 non-empty compact segments, mandatory non-empty signed `kid`, and byte-exact payload-substitution defense
(394-469). `export-jwk` refuses to leak `d` as `e` from a private key (fail-closed, 514-557). Honest
`jwk-thumbprint` kid. `[IMPLEMENTED]`
**Key-custody weakness (outside this file, but decisive for "never forge"):** signing keys are **plain
on-disk PEM** (`keys/private.pem` via `institution-dir`; `generate-keys.lisp` writes `private.pem` to CWD).
**No HSM/KMS, no rotation, no revocation**; default `kid` is a static string `"orchestrator-key"`. The
`keys/private/README.md` claims topology-enforced non-mounting to non-authority services — a reasonable
compartment *policy*, but the key remains a single file-based secret whose compromise = full release
forgery. `[IMPLEMENTED but prototype custody]` → key management is a RESTRUCTURE at the deployment layer.

### 1.9 `source/blockchain-authority.lisp` — **UPGRADE-IN-PLACE (de-scope to optional adapter)**
Honest where it counts: `arweave-upload` explicitly returns `:submitted nil :status :prepared-not-submitted`
(779-794) after an earlier false "permanent anchor" bug — good. But: hand-rolled secp256k1 point arithmetic
+ `mod-inverse` + `ecrecover` (242-391) is variable-time and reimplements curve math (used only for the
system's **own** recovery-id, so no attacker-controlled timing path — bounded, still a smell); `verify-anchor`
(912-945) trusts an RPC receipt/HTTP-200; IPFS multipart part omits a per-part Content-Type. All chains are
CONDITIONAL (skip if unconfigured) and **not wired** into the journal write path. Treat as an optional
external-anchor adapter, not core integrity. `[IMPLEMENTED, partial, honestly flagged]`

### 1.10 `source/archive-authority.lisp` — **UPGRADE-IN-PLACE (optional)**
`submit-to-wayback` (56-94) marks `:status :success` on any non-error response and fabricates
`archived-url = save-url` when the response is a string — it does **not** confirm the capture actually
occurred or is retrievable. The "100-YEAR PROOF" banner oversells the implementation (existence of an
attempt ≠ existence of an archive). Optional/adjunct; downgrade the claim or verify the capture.
`[IMPLEMENTED but over-claimed]`

### 1.11 `source/legal-authority-receipt.lisp` — **KEEP-AS-IS (light UPGRADE)**
Actually strong and honest. `receipt-id` = canonical hash of the **whole** receipt (identity/times/genealogy/
source inside the commitment, 60-92, 186-189) → altering any field breaks the id and the release Merkle leaf.
`verify-receipt-intrinsic` (216-310) is **not** a tautology: it recomputes the self-hash, replays the exact
journal cut `{graph_root, journal_seq, known_at}` and **rejects seq overshoot** (`:cut-seq-overshoot`,
260-262 — makes "exact cut" structural), then re-derives EVERY graph-derived field (provision-id,
commencement, previous, valid-until, recorded-from/until, assurance, full genealogy replay, effectivity at
known-at) against the exact bitemporal record. Scope is honestly fenced ("does NOT prove source bytes /
membership / release signature / TSA / tlog"). `[IMPLEMENTED, non-tautological, honestly scoped]`
**Dependency caveat:** correctness rides entirely on `version-graph.lisp` (114-defun seat, out of this
audit's scope) — the receipt is only as sound as `graph-chain-head`, `load-graph :up-to-seq`, and
`version-at`. Flag for the version-graph audit.

---

## 2. CROSS-CUTTING FINDINGS

- **The spine protects the wrong thing.** Append-only + hash-chain + compare-and-append + honest receipts
  + Merkle + TSA are real and (journal/merkle/timestamp) production-grade — but they guard **self-metadata**
  (biography, episodes, release manifests). The **legal corpus** rides `emit-graph`'s supersede I/O with no
  chain, no atomicity, no anchor, no record. An observatory's promise "never lose/forge a record" is
  undischarged for its primary records. **(THE foundational defect.)**
- **Tamper-evidence ≠ tamper-proof without an anchor.** Every hash chain here (journal, self-history, memory)
  is self-referential; no append-path writes an external witness (TSA/Merkle/chain). Wholesale offline
  rewrite that recomputes all hashes passes every `verify-*`. Anchoring exists as seats but is unwired. `[R-DES]`
- **Inconsistent hardening.** memory.lisp killed the representation-ambiguity hash class (canon-sexp);
  self-history.lisp still uses a naive `|`-join. Same class, two verdicts, one system.
- **Single-tenant memory vs many-matter mission.** No matter/tenant dimension exists anywhere in the memory
  substrate — a structural conflict with matter isolation / ethical walls.
- **Substring "validation."** The pre-emit FRBR contract asserts the emitter's own tokens are present — it
  is closer to a test-tautology than to assurance.
- **Prototype key custody.** File-PEM signing keys, static default kid, no rotation, no HSM.

## 3. PRODUCTION-GRADE vs PROTOTYPE (bottom line)
- **Production-grade (KEEP):** `merkle-authority`, `timestamp-authority`, `jws-authority`,
  `legal-authority-receipt`; `journal`'s single-writer/compare-and-append/receipt core.
- **Prototype / must change to WORK:** `emit-graph` (REPLACE — corpus not on the spine); `journal`
  torn-create fsync + missing anchor wiring (UPGRADE); `self-history` hash canonicalization (UPGRADE).
- **Prototype / must change to be TOP or to meet the mission:** `memory` multi-matter isolation
  (RESTRUCTURE); `validation-authority` real RDF parse (RESTRUCTURE); key custody/rotation/HSM
  (RESTRUCTURE, deployment layer); `archive`/`blockchain` claims (UPGRADE/de-scope).
