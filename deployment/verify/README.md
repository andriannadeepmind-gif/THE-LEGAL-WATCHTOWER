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

<!-- BEGIN GENERATED lawmax-merkle-sha256-v1 — DO NOT EDIT BY HAND -->
*Αυτή η ενότητα **ΠΑΡΑΓΕΤΑΙ** από τη μία κανονική πηγή
`deployment/verify/merkle-profile.sexp` μέσω `scripts/gen-merkle-truth.lisp`.
Χειροκίνητη επεξεργασία θα ανατραπεί και **κοκκινίζει το build**.*

## The algorithm (so you can re-implement it in any language)

Canonical profile **`lawmax-merkle-sha256-v1`** — normative reference
[RFC 9162 §2.1.1 (Merkle Tree Hash) — obsoletes RFC 6962](https://www.rfc-editor.org/rfc/rfc9162.html#section-2.1.1).

```
# profile: lawmax-merkle-sha256-v1   (RFC 9162 §2.1.1 (Merkle Tree Hash) — obsoletes RFC 6962)
MTH([])        = SHA-256("")                                  # empty tree
MTH([d0])      = SHA-256(0x00 || d0)                          # leaf, domain-separated
MTH(D[n>1])    = SHA-256(0x01 || MTH(D[0:k]) || MTH(D[k:n]))   # internal node
                 where k = largest power of two STRICTLY < n   # unbalanced split
                 NEVER duplicate-last                          # CVE-2012-2459 class

# hashes are carried as "sha256:" + 64 lowercase hex; node() concatenates the
# RAW decoded bytes of the children, never their hex text.

inclusion(text, proof):
  leaf = "sha256:" + hex(SHA-256(0x00 || UTF8_no_BOM(text)))
  if leaf != proof.leaf:              FAIL("text-hash-mismatch")
  h = leaf
  for step in proof.path:                                      # leaf -> root
     h = (step.side == "left") ? node(step.hash, h) : node(h, step.hash)
  if h != proof.merkle_root:          FAIL("inclusion-failed")
  OK
```

### Byte-exact input

- **`utf8-no-bom`** — text -> bytes = UTF-8, ΧΩΡΙΣ BOM
- **`no-normalization`** — ΚΑΜΙΑ Unicode normalization (ούτε NFC ούτε NFD ούτε NFKC/NFKD)
  <br/>*Δύο ΟΠΤΙΚΑ ισοδύναμες ακολουθίες είναι ΔΙΑΦΟΡΕΤΙΚΑ φύλλα. Σιωπηλή κανονικοποίηση θα άλλαζε ρίζα χωρίς αλλαγή κειμένου.*
- **`no-eol-conversion`** — ΚΑΜΙΑ μετατροπή LF/CRLF προς οποιαδήποτε κατεύθυνση
- **`preserve-trailing-newline`** — Το τελικό newline διατηρείται ΑΚΡΙΒΩΣ όπως είναι (ούτε προστίθεται ούτε αφαιρείται)

### Publication policy

- **`reject-empty-corpus`** — Δημοσίευση/υπογραφή/checkpoint corpus με leaf_count = 0 ΑΠΟΡΡΙΠΤΕΤΑΙ fail-closed
  <br/>*Ο πρωτόγονος ΟΦΕΙΛΕΙ να ξέρει τη ρίζα του κενού δέντρου (συμμόρφωση προτύπου)· ο ΘΕΣΜΟΣ δεν επιτρέπεται να υπογράψει δέσμευση για ΤΙΠΟΤΑ. Μηχανισμός != πολιτική· απαιτούνται ΑΝΕΞΑΡΤΗΤΑ tests για τις δύο ιδιότητες.*

Every implementation in this directory is checked against the shared golden
vectors (`vectors/merkle/vectors.json`) by the build gate. A second, contradictory
description of this algorithm anywhere in the repository is a build failure.
<!-- END GENERATED lawmax-merkle-sha256-v1 -->
