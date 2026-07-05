#!/usr/bin/env python3
"""Proof-Carrying Law (PCL-1) — independent public verifier, pure stdlib.

This re-implements, in a second language with ZERO third-party dependencies,
exactly what the canonical Common Lisp implementation does. Its whole point is
that you do NOT have to trust StavropoulosLaw — you verify against our signed
Merkle root yourself. A single tampered byte, a forged path, or a wrong signing
key all fail.

TRUST MODEL — read this:
  * `inclusion` proves a text is committed under the proof's OWN stated root. It
    does NOT prove that root is authentic. Treat it as a structural check only.
  * `signature`/`full` prove authenticity ONLY against a PINNED public key you
    supply out-of-band (--key FILE, or env PCL_TRUSTED_JWK, or a sibling
    `pcl-public-key.jwk`). The verifier NEVER trusts a key embedded in the proof:
    a forger can embed their own key and sign their own root. With a pinned key,
    the embedded key (if any) must match it by RFC 7638 thumbprint. Without a
    pinned key, `signature`/`full` return code 3 (UNPINNED — not a trust anchor).

The hashing convention (must match source/proof-carrying.lisp byte-for-byte):
  leaf      = "sha256:" + hex(SHA256( 0x00 ‖ UTF-8(text) ))          # RFC 6962 leaf
  node(a,b) = "sha256:" + hex(SHA256( 0x01 ‖ raw(a) ‖ raw(b) ))      # RFC 6962 node
  root      = Merkle root over the ordered leaves (odd node duplicates itself)

Usage:
  verify.py [--key JWK] inclusion <article.proof.json> <text-file>
  verify.py [--key JWK] signature <corpus-proof.json>
  verify.py [--key JWK] full      <article.proof.json> <corpus-proof.json> <text-file>
Exit: 0 authentic/consistent; 1 FAIL; 2 usage; 3 verified but UNPINNED key.
"""
import sys, os, json, hashlib, base64

PREFIX = "sha256:"
LEAF_DOMAIN = b"\x00"
NODE_DOMAIN = b"\x01"
MAX_PATH = 64

SHA256_DIGESTINFO_PREFIX = bytes([
    0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01,
    0x65, 0x03, 0x04, 0x02, 0x01, 0x05, 0x00, 0x04, 0x20])


def _h(domain: bytes, data: bytes) -> str:
    return PREFIX + hashlib.sha256(domain + data).hexdigest()


def leaf_hash(text: str) -> str:
    return _h(LEAF_DOMAIN, text.encode("utf-8"))


def node(a: str, b: str) -> str:
    return _h(NODE_DOMAIN, bytes.fromhex(a[len(PREFIX):]) + bytes.fromhex(b[len(PREFIX):]))


def verify_inclusion(text: str, proof: dict):
    """(ok, reason) — re-hash text, walk the path, compare to the proof's root."""
    path = proof.get("path", [])
    if len(path) > MAX_PATH:
        return False, "path-too-long"
    leaf = leaf_hash(text)
    if leaf != proof.get("leaf"):
        return False, "text-hash-mismatch"
    h = leaf
    for step in path:
        sib = step["hash"]
        h = node(sib, h) if step["side"] == "left" else node(h, sib)
    if h != proof.get("merkle_root"):
        return False, "inclusion-failed"
    return True, "ok"


def b64url_decode(s: str) -> bytes:
    return base64.urlsafe_b64decode(s + "=" * (-len(s) % 4))


def b64url_encode(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode("ascii")


def jwk_thumbprint(jwk: dict) -> str:
    """RFC 7638 SHA-256 thumbprint over the required RSA members (e, kty, n)."""
    canon = json.dumps({"e": jwk["e"], "kty": "RSA", "n": jwk["n"]},
                       separators=(",", ":"), sort_keys=True)
    return hashlib.sha256(canon.encode("ascii")).hexdigest()


def verify_rs256(signing_input: bytes, signature: bytes, n: int, e: int) -> bool:
    """RSASSA-PKCS1-v1_5 / SHA-256 with a FULL encoded-message comparison."""
    k = (n.bit_length() + 7) // 8
    if len(signature) != k:
        return False
    m = pow(int.from_bytes(signature, "big"), e, n)
    em = m.to_bytes(k, "big")
    digest = hashlib.sha256(signing_input).digest()
    t = SHA256_DIGESTINFO_PREFIX + digest
    ps_len = k - 3 - len(t)
    if ps_len < 8:
        return False
    expected = b"\x00\x01" + b"\xff" * ps_len + b"\x00" + t
    return len(em) == len(expected) and sum(x ^ y for x, y in zip(em, expected)) == 0


def _sig_check(corpus: dict, key_jwk: dict):
    """Verify the detached RS256 JWS over merkle_root with KEY_JWK. (ok, reason)."""
    root = corpus.get("merkle_root")
    jws = corpus.get("signature")
    if not jws:
        return False, "unsigned-root"
    parts = jws.split(".")
    if len(parts) != 3:
        return False, "malformed-jws"
    header_b64, _, sig_b64 = parts
    # Pin alg to RS256.
    try:
        hdr = json.loads(b64url_decode(header_b64))
        if hdr.get("alg") != "RS256":
            return False, "bad-alg"
    except Exception:
        return False, "malformed-header"
    signing_input = (header_b64 + "." + b64url_encode(root.encode("utf-8"))).encode("ascii")
    signature = b64url_decode(sig_b64)
    n = int.from_bytes(b64url_decode(key_jwk["n"]), "big")
    e = int.from_bytes(b64url_decode(key_jwk["e"]), "big")
    if e < 3:
        return False, "bad-exponent"
    return (True, "ok") if verify_rs256(signing_input, signature, n, e) else (False, "bad-signature")


def verify_signature(corpus: dict, trusted: dict):
    """(ok, reason, pinned?) — verify against the PINNED key, never the embedded one.
    If no trusted key is pinned, verify against the embedded key but flag UNPINNED."""
    embedded = corpus.get("public_key")
    if trusted is not None:
        if embedded is not None and jwk_thumbprint(embedded) != jwk_thumbprint(trusted):
            return False, "untrusted-key", True
        ok, reason = _sig_check(corpus, trusted)
        return ok, reason, True
    if embedded is None:
        return False, "no-public-key", False
    ok, reason = _sig_check(corpus, embedded)
    return ok, reason, False


def _resolve_trusted(key_arg):
    """Trusted JWK precedence: --key → $PCL_TRUSTED_JWK (path or inline) → sibling
    pcl-public-key.jwk. Returns the JWK dict or None."""
    candidates = [key_arg, os.environ.get("PCL_TRUSTED_JWK"),
                  os.path.join(os.path.dirname(os.path.abspath(__file__)), "pcl-public-key.jwk")]
    for c in candidates:
        if not c:
            continue
        try:
            if isinstance(c, str) and c.strip().startswith("{"):
                return json.loads(c)
            if os.path.isfile(c):
                with open(c, "r", encoding="utf-8") as f:
                    return json.load(f)
        except Exception:
            continue
    return None


def _load(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def _read_text(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def main(argv):
    args = argv[1:]
    key_arg = None
    if args and args[0] == "--key" and len(args) >= 2:
        key_arg = args[1]
        args = args[2:]
    if not args:
        print(__doc__)
        return 2
    cmd = args[0]
    trusted = _resolve_trusted(key_arg)

    if cmd == "inclusion" and len(args) == 3:
        ok, reason = verify_inclusion(_read_text(args[2]), _load(args[1]))
        if ok:
            print("OK  inclusion: structurally consistent (root UNVERIFIED — "
                  "use 'full' with a pinned --key to prove authenticity)")
            return 0
        print(f"FAIL  inclusion: {reason}", file=sys.stderr)
        return 1

    if cmd == "signature" and len(args) == 2:
        ok, reason, pinned = verify_signature(_load(args[1]), trusted)
    elif cmd == "full" and len(args) == 4:
        proof, corpus, text = _load(args[1]), _load(args[2]), _read_text(args[3])
        iok, ireason = verify_inclusion(text, proof)
        if not iok:
            print(f"FAIL  full: {ireason}", file=sys.stderr)
            return 1
        if proof.get("merkle_root") != corpus.get("merkle_root"):
            print("FAIL  full: root-mismatch", file=sys.stderr)
            return 1
        ok, reason, pinned = verify_signature(corpus, trusted)
    else:
        print(__doc__, file=sys.stderr)
        return 2

    if ok and pinned:
        print(f"OK  {cmd}: AUTHENTIC — signed by the pinned root authority ({reason})")
        return 0
    if ok and not pinned:
        print(f"WARN  {cmd}: signature is internally consistent but NO trusted key was "
              f"pinned — this is NOT proof of authenticity. Supply --key / "
              f"PCL_TRUSTED_JWK / pcl-public-key.jwk.", file=sys.stderr)
        return 3
    print(f"FAIL  {cmd}: {reason}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
