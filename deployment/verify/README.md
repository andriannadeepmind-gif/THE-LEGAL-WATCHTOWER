# Public verifiers — *don't trust us, verify us*

Two independent, **zero-dependency** implementations of the Proof-Carrying Law
(PCL-1) verification algorithm. They exist so that any party — another AI, a
search engine's pipeline, a court, a journalist — can confirm a piece of Greek
law is authentic **without trusting StavropoulosLaw**. You verify against our
cryptographically signed Merkle root yourself.

| File | Runtime | Crypto |
|------|---------|--------|
| `verify.py`  | Python 3 (stdlib only) | SHA-256 via `hashlib`; **RSA from scratch** with big integers — no `cryptography`, no OpenSSL |
| `verify.mjs` | Node.js (builtin only) | `node:crypto` — `crypto.verify('RSA-SHA256', …)` (i.e. OpenSSL) |

Both agree with the canonical Common Lisp implementation
(`source/proof-carrying.lisp`) **byte-for-byte**, and the signatures are
standard **RSASSA-PKCS1-v1_5 / SHA-256** detached JWS (RFC 7797), so any JOSE
library (PyJWT, jose, jsonwebtoken, OpenSSL) verifies them too.

## What a proof is

- `article-<id>.proof.json` — a single provision's portable proof: its text
  `leaf`, the Merkle inclusion `path`, the `merkle_root`, plus its citation/ELI.
- `corpus-proof.json` — the corpus anchor: the `merkle_root` every proof chains
  to, the detached JWS `signature` over it, and the `public_key` (JWK) that
  verifies the signature. Emit them with `orchestrator.core --emit-proofs`.

## Trust anchor — pin the key (important)

Authenticity is proven **only against the genuine public key, obtained
out-of-band** — never the key embedded in a proof (a forger can embed their own).
Provide the pinned key by any of: `--key pcl-public-key.jwk`, env
`PCL_TRUSTED_JWK` (a path or inline JWK), or a `pcl-public-key.jwk` sitting next
to the verifier script. If a proof embeds a `public_key`, it must match the
pinned key by **RFC 7638 thumbprint**, or the result is `untrusted-key`.

## Usage

```bash
# A) inclusion only — STRUCTURAL: text commits under the proof's own root.
#    (Not proof of authenticity — the root is unverified.)
python3 verify.py inclusion article-299.proof.json art-299.txt

# B) signature — is the corpus root sealed by the PINNED root authority?
python3 verify.py --key pcl-public-key.jwk signature corpus-proof.json

# C) full chain — text → leaf → path → root → SIGNATURE under the pinned key.
python3 verify.py --key pcl-public-key.jwk full article-299.proof.json corpus-proof.json art-299.txt
node    verify.mjs --key pcl-public-key.jwk full article-299.proof.json corpus-proof.json art-299.txt
```

Exit codes:

| code | meaning |
|------|---------|
| `0` | **AUTHENTIC** (signature verified against the pinned key) — or, for `inclusion`, structurally consistent |
| `1` | FAIL — `text-hash-mismatch`, `inclusion-failed`, `root-mismatch`, `bad-signature`, `untrusted-key`, `bad-alg`, `path-too-long` |
| `2` | usage error |
| `3` | signature is internally consistent but **no trusted key was pinned** — NOT proof of authenticity |

A single tampered byte, a forged path, a wrong signing key, or a self-consistent
forgery signed by an attacker's own key all fail against the pinned anchor.

## The algorithm (so you can re-implement it in any language)

```
leaf      = "sha256:" + hex(SHA256(UTF-8(text)))
node(a,b) = "sha256:" + hex(SHA256( rawBytes(a) || rawBytes(b) ))   # strip "sha256:", concat RAW bytes
root      = Merkle root over the ordered leaves; an odd node pairs with itself

inclusion: h = leaf; for step in path: h = step.side=="left" ? node(step.hash,h) : node(h,step.hash)
           accept iff h == merkle_root

signature: a detached RS256 JWS "header..sig" whose payload is the merkle_root STRING.
           signing_input = header_b64 + "." + base64url(UTF-8(merkle_root))
           accept iff RSASSA-PKCS1-v1_5/SHA-256 verifies signing_input against sig with public_key (n,e)
```

That's the whole trust root. From *"cite this source"* to *"verify against this root."*
