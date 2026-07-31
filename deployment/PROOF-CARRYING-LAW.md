# Proof-Carrying Law — PCL-1 specification

A portable, self-verifying proof that a piece of text **is the authentic provision**
of a Greek legal code, anchored in time — checkable by anyone, in any language,
**without trusting the publisher**.

The goal: a legal-AI's claim about Greek law is authentic **iff** it resolves to a
PCL-1 proof. From *"cite this source"* to *"verify against this root."*

---

<!-- BEGIN GENERATED lawmax-merkle-sha256-v1 — DO NOT EDIT BY HAND -->
*Αυτή η ενότητα **ΠΑΡΑΓΕΤΑΙ** από τη μία κανονική πηγή
`deployment/verify/merkle-profile.sexp` μέσω `scripts/gen-merkle-truth.lisp`.
Χειροκίνητη επεξεργασία θα ανατραπεί και **κοκκινίζει το build**.*

## Merkle tree — canonical profile `lawmax-merkle-sha256-v1`

Normative reference: [RFC 9162 §2.1.1 (Merkle Tree Hash) — obsoletes RFC 6962](https://www.rfc-editor.org/rfc/rfc9162.html#section-2.1.1).

### Rules

- **`empty`** — `MTH({}) = SHA-256("")  — ο hash του ΚΕΝΟΥ string`
  <br/>*RFC 9162 §2.1.1: το κενό δέντρο έχει ΟΡΙΣΜΕΝΗ ρίζα. Ο πρωτόγονος ΟΦΕΙΛΕΙ να τη δίνει· η ΠΟΛΙΤΙΚΗ δημοσίευσης χωριστά ΑΠΑΓΟΡΕΥΕΙ κενό corpus.*
- **`leaf`** — `MTH({d(0)}) = SHA-256(0x00 || d(0))`
  <br/>*Domain separation: χωρίς το 0x00 ένα 64-byte φύλλο είναι second-preimage εσωτερικού κόμβου.*
- **`node`** — `MTH(D[n]) = SHA-256(0x01 || MTH(D[0:k]) || MTH(D[k:n]))  για n > 1`
  <br/>*Το 0x01 σφραγίζει τον εσωτερικό κόμβο· συνενώνονται τα ΩΜΑ bytes των παιδιών, ΟΧΙ το hex κείμενό τους.*
- **`split`** — `k = η μεγαλύτερη δύναμη του 2 ΑΥΣΤΗΡΑ μικρότερη του n  (k < n <= 2k)`
  <br/>*Unbalanced split: το δέντρο καθορίζεται μονοσήμαντα από το n.*
- **`no-duplicate-last`** — `duplicate-last ΑΠΑΓΟΡΕΥΕΤΑΙ ΑΠΟΛΥΤΩΣ`
  <br/>*Κλάση CVE-2012-2459: με αντιγραφή του τελευταίου φύλλου, ΔΙΑΦΟΡΕΤΙΚΑ σύνολα φύλλων παράγουν ΙΔΙΑ ρίζα (π.χ. [a b c] και [a b c c]) — ανεπίτρεπτο όταν εκδίδονται inclusion proofs σε τρίτους.*
- **`order-sensitive`** — `node(L,R) != node(R,L) — η σειρά είναι μέρος της δέσμευσης`
  <br/>*Η θέση του φύλλου στο corpus είναι σημασιολογική.*

### Byte-exact input

- **`utf8-no-bom`** — text -> bytes = UTF-8, ΧΩΡΙΣ BOM
- **`no-normalization`** — ΚΑΜΙΑ Unicode normalization (ούτε NFC ούτε NFD ούτε NFKC/NFKD)
  <br/>*Δύο ΟΠΤΙΚΑ ισοδύναμες ακολουθίες είναι ΔΙΑΦΟΡΕΤΙΚΑ φύλλα. Σιωπηλή κανονικοποίηση θα άλλαζε ρίζα χωρίς αλλαγή κειμένου.*
- **`no-eol-conversion`** — ΚΑΜΙΑ μετατροπή LF/CRLF προς οποιαδήποτε κατεύθυνση
- **`preserve-trailing-newline`** — Το τελικό newline διατηρείται ΑΚΡΙΒΩΣ όπως είναι (ούτε προστίθεται ούτε αφαιρείται)

### Publication policy (mechanism ≠ policy)

- **`reject-empty-corpus`** — Δημοσίευση/υπογραφή/checkpoint corpus με leaf_count = 0 ΑΠΟΡΡΙΠΤΕΤΑΙ fail-closed
  <br/>*Ο πρωτόγονος ΟΦΕΙΛΕΙ να ξέρει τη ρίζα του κενού δέντρου (συμμόρφωση προτύπου)· ο ΘΕΣΜΟΣ δεν επιτρέπεται να υπογράψει δέσμευση για ΤΙΠΟΤΑ. Μηχανισμός != πολιτική· απαιτούνται ΑΝΕΞΑΡΤΗΤΑ tests για τις δύο ιδιότητες.*

### Algorithm

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

Golden vectors shared by all three independent implementations:
`deployment/verify/vectors/merkle/vectors.json`.
<!-- END GENERATED lawmax-merkle-sha256-v1 -->

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
