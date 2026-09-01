# MLTP v3 — STANDARDS INTEROPERABILITY VECTORS (C1.4)

Feasibility of a construction boundary + **standards-valid** interoperability
vectors. **Not** a production SCITT/timestamp service. Both vectors use
independently-maintained, vetted implementations — **no hand-rolled CBOR/COSE or
timestamp cryptography**.

## rfc3161/ — real RFC-3161 timestamp token
- `token.tsr` — a **real DER RFC-3161** token from a local test TSA, produced and
  verified via the **vetted OpenSSL `ts`** implementation (`gen.sh` provenance,
  `verify.sh` deterministic check: cert chain via `ca.crt`/`tsa.crt`, sha256
  message imprint over `message.txt`, `genTime` + `accuracy`).
- The test TSA signs with **RSA** (OpenSSL's `ts` app does not sign with Ed25519);
  this is the RFC-3161 interop vector, independent of MLTP's Ed25519 object signatures.
- **Distinction (do not confuse):** the deterministic `TimeAttestation` in the core
  reference (`schemas.json` → `time_attestation`) is a **reproducible unit-test
  double** with the same *verification contract* — it is **NOT** an RFC-3161 TSR.
  This directory holds the actual TSR. Private keys are not committed (verification
  is public); `gen.sh` regenerates them.

## cose/ — real COSE_Sign1 projection vector
- `vector.cose` — a **real `COSE_Sign1`** (CBOR) over the **exact MLTP canonical
  payload bytes** (`payload.bin` = canonical bytes of the legal-state claim body),
  produced and verified with **veraison/go-cose v1.3.0** (pinned, **vendored** for
  offline reproducibility) over **fxamacker/cbor** — vetted, not hand-rolled.
- `verify.sh` (deterministic): verifies the committed vector, rejects a tampered
  payload, and confirms a fresh re-make is byte-identical (Ed25519 COSE_Sign1 is
  deterministic).
- **Distinct constructions:** MLTP's canonical-JSON signature
  (`Ed25519(context ‖ 0x1F ‖ canonical(obj))`) and a `COSE_Sign1` sign **different
  bytes** in **different containers**. The MLTP JSON signature is **not** a COSE
  signature and is never relabeled as one (correction #13). COSE here is a separate,
  independently-verifiable **projection** signature — not the canonical container.

## Availability / blocker policy
If a vetted COSE (or RFC-3161) implementation were unavailable, the corresponding
vector would be retained as **MISSING** and reported as a blocker — never faked.
Here both vetted implementations are available and both vectors verify.
