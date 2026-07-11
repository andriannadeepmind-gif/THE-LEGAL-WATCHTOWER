# LAWMAX Release-Verification Vectors (L7-A)

Wycheproof-style conformance corpus for the **release/census layer**. These
vectors ARE the specification: any release verifier, in any language, must
return the `INDEX.json` verdict for every vector — or it is not conformant.

## Why this exists

A single implementation "looking correct" guarantees nothing. Guarantee comes
from **N independent implementations that provably agree on public test
vectors**, kept honest by **permanent adversarial inputs**. Every adversarial
finding from our security reviews lives here as a negative vector, so every
future verifier must prove it blocks the same attacks.

## Layout

- `INDEX.json` — `{name, verdict: pass|fail, reason}` for each vector.
- `sha256-<root>/` — a genuine, minimal valid census-era release (2 synthetic
  articles), built through the real seats (RFC-6962 Merkle, census, RS256 JWS).
- `sha256-<root>.pinned-root` — the out-of-band root (trust anchor); pass it as
  the second arg to verify with a pinned root.
- `sha256-<root>--<mutation>/` — negative vectors (documented tamper):
  - `tampered-article` / `tampered-ttl` — content ≠ census (integrity)
  - `stripped-census` — census removed (epoch-downgrade attempt)
  - `stripped-signature` — signature.jws + public.jwk removed (F2)
  - `attached-payload-jws` — JWS with a non-empty embedded payload (F1)
  - `tampered-verifier` — verify/verify.lisp altered (10th canonical → root≠name)
- `test-key/` — the fixed test keypair (**FIXTURES ONLY** — never a production
  root key; committed solely so the valid vector's signature is reproducible).
- `build-vectors.lisp` — regenerates everything from the seats.
- `run-vectors.sh` — runs every vector through the L6 Lisp kernel AND the Python
  verifier and requires both to match INDEX and each other.

## Run

```bash
# both verifiers vs the corpus (needs sbcl + python3)
LAWMAX_ROOT=<repo> bash deployment/verify/vectors/run-vectors.sh

# a single release, either verifier, with the pinned root (RECOMMENDED):
sbcl --script deployment/verify/kernel-verify.lisp   <release-dir> <pinned-root-hex>
python3        deployment/verify/verify-release.py   <release-dir> <pinned-root-hex>
```

The CI gate `tests/release-vector-conformance-test.lisp` runs the production
spine seat + the Python verifier against INDEX.

## Regenerate

```bash
sbcl ... --eval '(load "deployment/verify/vectors/build-vectors.lisp")'
```
Deterministic (fixed key, fixed article content, `SOURCE_DATE_EPOCH`), so the
roots and signatures are byte-stable. If a seat's hashing changes, the roots
change by construction — that is the point.
