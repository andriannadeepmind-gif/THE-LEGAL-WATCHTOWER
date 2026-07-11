# Proof-Carrying Law — PCL-1 specification

A portable, self-verifying proof that a piece of text **is the authentic provision**
of a Greek legal code, anchored in time — checkable by anyone, in any language,
**without trusting the publisher**.

The goal: a legal-AI's claim about Greek law is authentic **iff** it resolves to a
PCL-1 proof. From *"cite this source"* to *"verify against this root."*

---

## 1. Hashing (RFC 6962 domain separation)

Leaves and internal nodes are **domain-separated** by a one-byte prefix, so a
leaf's preimage can never be reinterpreted as an internal node (second-preimage
hardening, per RFC 6962 §2.1):

- **Leaf:** `leaf = "sha256:" + hex( SHA-256( 0x00 ‖ UTF-8(text) ) )`
- **Internal node:** prefix `0x01`, then the **raw bytes** of the two child hashes
  (not their hex text), then SHA-256:
  `parent = "sha256:" + hex( SHA-256( 0x01 ‖ bytes(h_left) ‖ bytes(h_right) ) )`
  where `bytes(h)` decodes the hex after the `sha256:` prefix.
- All hex is lowercase.

## 2. Merkle tree

- Leaves are the provision leaves **in corpus order** (article 1, 2, …, including
  lettered articles as their own leaves: 100, 100Α, 100Β …).
- Build bottom-up; an **odd** node at any level is paired **with itself**.
- The top node is the **`merkle_root`**. This single value is what the corpus
  RFC-3161 timestamps (multi-TSA) and JWS-signs — see `corpus-proof.json` and the
  release's `temporal-proof/` + `verify/` kit.

## 3. Inclusion path

For a leaf at index `i`, the path is the list of sibling hashes from leaf to root:

```
[ { "side": "left" | "right", "hash": "sha256:…" }, … ]
```

`side` is the position of the **sibling** relative to the running hash:
`"right"` ⇒ `next = node(running ‖ sibling)`, `"left"` ⇒ `next = node(sibling ‖ running)`.

## 4. The proof object — `article-<id>.proof.json`

```json
{
  "version": "pcl-1",
  "id": "299",
  "eli": "https://stavropouloslaw.com/eli/gr/l/2019/4619/art/299",
  "cite_as": "Άρθρο 299 ΠΚ (ν.4619/2019, ΦΕΚ Α΄95)",
  "anchored_at": "2025-01-01T00:00:00Z",
  "leaf": "sha256:…",
  "merkle_root": "sha256:…",
  "path": [ { "side": "right", "hash": "sha256:…" }, … ]
}
```

The corpus-level anchor — `corpus-proof.json`:

```json
{ "version":"pcl-1", "algorithm":"sha256-merkle/rfc6962+RS256",
  "merkle_root":"sha256:…", "count":536, "anchored_at":"2025-01-01T00:00:00Z",
  "signature":"<detached RS256 JWS over merkle_root>",
  "public_key":{ "kty":"RSA", "alg":"RS256", "kid":"stavropoulos-law-root", "n":"…", "e":"AQAB" } }
```

The `signature` is a **detached JWS** (RFC 7797, RS256) whose payload is the
`merkle_root` string. Verifying it proves the root — and therefore every
provision that chains to it — was sealed by the root authority.

> **Trust anchor — critical.** `public_key` is embedded for convenience only; a
> verifier MUST NOT trust it. A forger can sign their own root with their own key
> and embed it. Authenticity is proven **only** against the genuine key obtained
> out-of-band — the standalone `pcl-public-key.jwk` distributed with the verifier
> (or its RFC 7638 thumbprint). If a proof embeds a `public_key`, it must match
> the pinned key by thumbprint; otherwise the result is `untrusted-key`.

## 5. Verification algorithm (any language)

```
# node(x, y) = "sha256:" + hex(SHA256(0x01 ‖ bytes(x) ‖ bytes(y)))   # RFC 6962 internal node
inclusion(text, proof):                  # STRUCTURAL: commits text under proof.merkle_root
  if len(proof.path) > 64:           return FAIL("path-too-long")     # DoS bound
  leaf = "sha256:" + hex(SHA256(0x00 ‖ UTF8(text)))                   # RFC 6962 leaf
  if leaf != proof.leaf:             return FAIL("text-hash-mismatch")
  h = leaf
  for step in proof.path:
     sib = step.hash
     h = (step.side == "left") ? node(sib, h) : node(h, sib)
  if h != proof.merkle_root:         return FAIL("inclusion-failed")
  return OK

authentic(text, proof, corpus_proof, PINNED_KEY):   # the real guarantee
  require inclusion(text, proof) == OK
  require proof.merkle_root == corpus_proof.merkle_root          # root-mismatch otherwise
  require corpus_proof.header.alg == "RS256"
  if corpus_proof.public_key present:
     require thumbprint(corpus_proof.public_key) == thumbprint(PINNED_KEY)   # else untrusted-key
  require RS256_verify(PINNED_KEY, signing_input(corpus_proof), corpus_proof.signature)
  return AUTHENTIC
```

`inclusion` alone proves only that the text sits under *the proof's own* root —
it is **not** proof of authenticity. `authentic` is the real guarantee: it binds
to a root signed by the **pinned** key (and, in a full release, also checked
against the RFC-3161 timestamps in `verify/`).

## 6. Reference verifiers

- **CLI:** `PROOF_FILE=article-299.proof.json TEXT_FILE=art299.txt orchestrator.core --verify-proof`
- **Lisp:** `orchestrator.proof-carrying:verify-proof-json`
- Implementing the 6 lines above in JS/Python/Go is trivial — that is the point:
  the proof needs **no library and no trust**, only SHA-256.

## 7. Why this is the trust root

Citation is soft — an AI can cite (or hallucinate a citation to) anything.
Verification is hard — the text either hashes into the signed root or it does not.
PCL-1 makes every provision **born-verifiable**, so the authentic Greek legal text
becomes the substrate a legal-AI must resolve to in order to be trustworthy.
