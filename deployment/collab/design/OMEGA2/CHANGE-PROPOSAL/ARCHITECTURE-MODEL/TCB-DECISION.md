# TCB-DECISION — the trusted computing base of the Common Lisp verification path

**Scope.** One bounded question, decided once, recorded here: *what computes SHA-256 for the Common Lisp
verification path, and how is that thing pinned?* This is the adjudication Review-2 **N-1** and **N-11**
required. It is a decision about the trusted computing base of a verifier. It is **not** a security proof, not a
supply-chain assurance, and not a qualification of any kind, and nothing here licenses any wider change.

---

## 1. The two candidates, stated fairly

**Option A — an external digest program, pinned as a model fact.**
`sha256sum` from GNU coreutils, invoked by the kernel through `sb-ext:run-program` with the bytes written to its
standard input. Its absolute path, semantic version and exact executable digest are declared in
`TOOLCHAIN.sexp` as a `tool` fact, and `gate_checks.py toolchain` enforces all three before any verdict is
issued. Nothing is vendored, compiled or cached.

**Option B — an in-repository implementation.**
Either the vendored `third-party/ironclad-v0.61` ASDF system that the superseded design loaded, or a SHA-256
written directly into the kernel. The digest function is then part of the repository and needs no host binary.

Both options were live. B was the incumbent: the superseded `SETUP-TOOLCHAIN.sh` pre-compiled ironclad and the
kernel loaded it. The question is not which is more comfortable; it is which is **strictly dominant**.

---

## 2. The decisive axis: can the thing be pinned at all?

A verifier's digest engine is the instrument every other pin depends on. Pinning it is therefore not one
property among several — it is the property that makes the other pins mean anything.

* **Option A is pinnable without circularity.** The digest program is a single file. It is measured by the
  *other* verification path's engine (`hashlib`/OpenSSL, declared as `:verified-by CHECKER_PATH`), so the
  Common Lisp path's instrument is certified by something that shares no code with it. No tool measures itself:
  the schema's `verifier` enum contains no value that would let it.

* **Option B cannot be pinned without Option A's mechanism.** To pin a vendored source closure you must digest
  it; to digest it inside the Lisp image you must already have a trusted digest function; the only candidate is
  the very implementation being pinned. That is an implementation certifying itself — the exact failure Review-2
  named. Vendoring does not remove the bootstrap, it hides it.

This is not a preference. **B is not merely worse on this axis; B cannot occupy it.** Any attempt to pin B
either imports A or accepts self-certification.

---

## 3. The other axes, measured rather than asserted

| axis | Option A (external, pinned) | Option B (vendored / in-kernel) |
|---|---|---|
| units that must be trusted | 1 executable, digest-pinned | 276 tracked ironclad files (129 Lisp sources) reached through an ASDF source registry rooted at the whole 3,307-file `third-party/` tree — **none pinned by any executable check** in the superseded design |
| bootstrap | non-circular: measured by the other path | circular: the engine would certify its own source |
| implementation independence from the Python path | separate lineage (coreutils vs OpenSSL); cross-engine agreement is real evidence | ironclad is a third lineage, so this axis alone slightly favours B |
| behaviour when absent or wrong | typed `TOOLCHAIN-FAILURE` / `SHA-256 PROVIDER: UNAVAILABLE`, exit 4, **no verdict** | silent fallback is easy to write and was not structurally prevented |
| kernel source cost | 67 non-blank lines of provider, no ASDF, no cache, no temp files | a full SHA-256 in-kernel would consume most of the 400-line budget the design law fixes |
| reproducibility across hosts | pinned to one declared supported base environment; any other host stops with a named mismatch | appears portable, but portability was never verified — the compiled fasl cache is host-specific |
| build and first-run cost | none | a one-off ASDF compile the superseded setup script existed to hide |

Exactly one axis favours B — implementation lineage — and it is not decisive, because A already provides a
lineage distinct from the Python path's OpenSSL. Every other axis favours A, and the pinning axis is not merely
favourable to A but impossible for B.

---

## 4. What Option A honestly costs

State it plainly rather than let it be discovered later:

1. **A process boundary and a host binary.** The Common Lisp path now depends on an external executable. Trust
   in the operating system is not removed by this decision — it is *made explicit and pinned*, where before it
   was implicit and unpinned.
2. **Host-specificity.** `:sha256` is the identity on one declared supported base environment (Ubuntu 24.04 LTS
   x86-64, coreutils 9.4 — see `SETUP-TOOLCHAIN.sh`). On any other host the gate stops with a typed
   `TOOLCHAIN-IDENTITY-MISMATCH`. Re-pinning is an explicit, reviewable edit of `TOOLCHAIN.sexp`; it is never an
   automatic accommodation, and no code performs one.
3. **`sb-ext:run-program` is in the kernel's trusted surface.** The bytes are piped on stdin; there is no shell,
   no temp file and no path interpolation, and the kernel refuses a verdict if the program is absent, is not
   executable, exits non-zero, or returns anything that is not a 64-character lower-case hexadecimal digest.

None of these is hidden by a fallback. Absence produces silence, not a guess.

---

## 5. Decision

**Option A is adopted. Option B is retired.**

Consequences, each mechanically checked rather than asserted:

* `KERNEL/hash-provider.lisp` acquires the provider from the schema-validated `tool` fact whose `:role` is
  `DIGEST_PROVIDER`. There is no second definition anywhere on either path.
* `gate_checks.py toolchain` runs **before** either verifier and enforces path, exact executable digest measured
  by the other path's engine, and semantic version.
* `gate_checks.py hash-engines` requires coreutils and hashlib/OpenSSL to agree over identical raw bytes for
  every pinned module and for adversarial cases: CRLF, a lone CR, a UTF-8 BOM, bytes that are not valid UTF-8,
  and the empty input.
* Held-out falsifier `K25-PROVIDER-UNAVAILABLE` requires the kernel to exit 4 with
  `SHA-256 PROVIDER: UNAVAILABLE` and **no** `ARCHITECTURE MODEL LAWS` line when the pinned program is not
  where the model says it is. `K24-CRLF-TEXT-HASHING` requires text-decoded hashing to be rejected.
  `G06-TOOLCHAIN-IDENTITY` requires the composed gate to fail when a pin no longer matches the executable.
* `third-party/ironclad-v0.61` remains in the repository, classified `VENDORED_DEPENDENCY`. It is **not** on the
  live governance path, and `gate_checks.py dependency-closure` computes the real transitive execution closure
  of every governance entrypoint and proves it.

## 6. Residual, recorded rather than closed

The identity of the host operating system's package archive is outside this model. Nothing here establishes that
the pinned `sha256sum` binary is free of defect — only that the binary actually executed is byte-for-byte the
one the model names, and that a second, independently sourced engine agrees with it on every input the gate
tries. That is cross-engine evidence, not a correctness proof of SHA-256, and it is stated as such everywhere it
is reported.
