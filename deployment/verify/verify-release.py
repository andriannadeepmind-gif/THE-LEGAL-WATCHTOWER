#!/usr/bin/env python3
"""LAWMAX release verifier — independent SECOND-LANGUAGE implementation (Python,
pure stdlib). Verdict-for-verdict identical to the Common Lisp L6 kernel
(deployment/verify/kernel-verify.lisp). This is the L7 diversity anchor for the
census/release layer: you do NOT trust the Lisp implementation — you re-verify
the same release with a program written independently, and both must agree.

Checks (census-era release, RFC-6962):
  1. Release root ≡ directory name: MTH of the 10 canonical files (incl. this
     verifier's Lisp twin verify/verify.lisp — the verifier is INSIDE identity).
     Optional: root ≡ out-of-band <pinned-root-hex> (RECOMMENDED trust anchor).
  2. Census self-consistency: every per-article ttl/jsonld/html sha512 ≡ the
     in-release bytes; every text_leaf ≡ RFC-6962 leaf of article-*.txt;
     pcl_text_root ≡ MTH(text leaves); prev_release_root present (chain).
  3. Detached JWS RS256 over the release root, FULL EMSA-PKCS1-v1_5. Missing
     signature = FAIL (no unsigned downgrade). Attached-payload token = FAIL
     (payload-substitution guard). NOTE: the JWK is read from inside the release,
     so this proves CONSISTENCY; AUTHENTICITY rests on the pinned root + TSR.
  4. RFC-3161 receipt: existence (full crypto = declared P4).

Usage:  verify-release.py <release-dir> [pinned-root-hex]
Exit:   0 pass; 1 fail; 2 usage/deps.
"""
import sys, os, json, hashlib

PREFIX = "sha256:"
LEAF, NODE = b"\x00", b"\x01"
CANONICAL = ["census.json", "lineage-graph.ttl", "meta-ontology.ttl", "negation.ttl",
             "shapes/article-shape.ttl", "shapes/lineage-shape.ttl",
             "shapes/manifest-shape.ttl", "stability-policy.md",
             "stability-policy.ttl", "verify/verify.lisp"]
SHA256_DIGESTINFO = bytes([0x30,0x31,0x30,0x0d,0x06,0x09,0x60,0x86,0x48,0x01,
                           0x65,0x03,0x04,0x02,0x01,0x05,0x00,0x04,0x20])


def sha256_hex(b): return PREFIX + hashlib.sha256(b).hexdigest()
def leaf_hash(b): return sha256_hex(LEAF + b)
def node(l, r): return sha256_hex(NODE + bytes.fromhex(l[7:]) + bytes.fromhex(r[7:]))


def largest_pow2_below(n):
    k = 1
    while k * 2 < n:
        k *= 2
    return k


def mth(leaves):
    def m(lo, hi):
        n = hi - lo
        if n == 1:
            return leaves[lo]
        k = largest_pow2_below(n)
        return node(m(lo, lo + k), m(lo + k, hi))
    return m(0, len(leaves))


def read_bytes(p):
    with open(p, "rb") as f:
        return f.read()


def sha512_hex(p): return "sha512:" + hashlib.sha512(read_bytes(p)).hexdigest()


def pad_file_id(cid):
    """Census id (article-uri-id, e.g. '5Α','70') -> file id ('005Α','070').
    Same logic as orchestrator.model:pad-article-id / kernel %pad."""
    i = 0
    while i < len(cid) and cid[i].isdigit():
        i += 1
    digits, suffix = cid[:i], cid[i:]
    return f"{int(digits):03d}{suffix}"


def b64url_decode(s):
    import base64
    return base64.urlsafe_b64decode(s + "=" * (-len(s) % 4))


def b64url_encode(b):
    import base64
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode("ascii")


def verify_jws(jws, payload, n, e):
    """Detached RS256 over PAYLOAD. Attached-payload token (non-empty middle
    segment) is REJECTED (payload substitution guard, matches kernel F1)."""
    parts = jws.split(".")
    if len(parts) != 3:
        return False
    if len(parts[1]) != 0:
        return False  # attached-payload token — never bound to our payload
    try:
        hdr = json.loads(b64url_decode(parts[0]))
        if hdr.get("alg") != "RS256":
            return False
    except Exception:
        return False
    payload_b64 = b64url_encode(payload.encode("utf-8"))
    signing_input = (parts[0] + "." + payload_b64).encode("ascii")
    sig = b64url_decode(parts[2])
    k = (n.bit_length() + 7) // 8
    if len(sig) != k:
        return False
    em = pow(int.from_bytes(sig, "big"), e, n).to_bytes(k, "big")
    t = SHA256_DIGESTINFO + hashlib.sha256(signing_input).digest()
    ps = k - 3 - len(t)
    if ps < 8:
        return False
    expected = b"\x00\x01" + b"\xff" * ps + b"\x00" + t
    return len(em) == len(expected) and sum(x ^ y for x, y in zip(em, expected)) == 0


def fail(msg):
    print(f"  ✗ {msg}")
    return False


def ok(msg):
    print(f"  ✓ {msg}")
    return True


def verify_release(d, pinned=None):
    d = os.path.abspath(d)
    leaf = os.path.basename(d)
    errors = 0
    root = None
    print(f"\n=== LAWMAX PY RELEASE VERIFIER — {leaf} ===")

    # 1. root ≡ dirname
    print("[1] Release root (RFC-6962, 10 canonical)...")
    paths = [os.path.join(d, c) for c in CANONICAL]
    missing = [c for c, p in zip(CANONICAL, paths) if not os.path.isfile(p)]
    if missing:
        errors += (not fail(f"missing canonical: {missing}"))
    else:
        leaves = [leaf_hash(read_bytes(p)) for p in paths]
        root = mth(leaves)
        rid = "sha256-" + root[7:]
        errors += (not (ok(f"root == dirname: {rid}") if rid == leaf
                        else fail(f"root {rid} != dirname {leaf}")))
        if pinned:
            errors += (not (ok("root == out-of-band pinned")
                            if root[7:] == pinned.lower()
                            else fail(f"root != pinned {pinned}")))

    # 2. census self-consistency
    print("[2] Census (per-article membership + text-spine)...")
    cpath = os.path.join(d, "census.json")
    if not os.path.isfile(cpath):
        errors += (not fail("census.json absent"))
    else:
        c = json.loads(read_bytes(cpath).decode("utf-8"))
        arts = c.get("articles", [])
        adir = os.path.join(d, "articles")
        # Parity with the Lisp kernel: key REQUIRED; null = honest first-of-chain;
        # else it MUST be "sha256:"+64 hex — a malformed pointer is a FAIL, never
        # a silently accepted chain break. (N-version conformance, forced by the
        # vector corpus.)
        if "prev_release_root" not in c:
            errors += (not fail("prev_release_root key absent"))
        else:
            prev = c["prev_release_root"]
            if prev is None:
                ok("prev_release_root: null (first of chain)")
            elif (isinstance(prev, str) and len(prev) == 71 and prev.startswith("sha256:")
                  and all(ch in "0123456789abcdefABCDEF" for ch in prev[7:])):
                ok(f"prev_release_root present (chain): {prev[:19]}…")
            else:
                errors += (not fail(f"prev_release_root malformed: {prev!r}"))
        bad = 0
        leaves = []
        for a in arts:
            fid = pad_file_id(a["id"])
            leaves.append(a["text_leaf"])
            for ext in ("ttl", "jsonld", "html"):
                p = os.path.join(adir, f"article-{fid}.{ext}")
                if not (os.path.isfile(p) and sha512_hex(p) == a[ext]):
                    bad += 1
            tp = os.path.join(adir, f"article-{fid}.txt")
            if not (os.path.isfile(tp) and leaf_hash(read_bytes(tp)) == a["text_leaf"]):
                bad += 1
        errors += (not (ok(f"{len(arts)} articles: every ttl/jsonld/html/txt == census")
                        if bad == 0 else fail(f"{bad} per-article mismatches")))
        errors += (not (ok("pcl_text_root == MTH(text leaves)")
                        if mth(leaves) == c.get("pcl_text_root") else fail("pcl_text_root mismatch")))

    # 3. JWS
    print("[3] JWS signature (RS256, full padding)...")
    jp = os.path.join(d, "temporal-proof", "signature.jws")
    kp = os.path.join(d, "verify", "public.jwk")
    if not (os.path.isfile(jp) and os.path.isfile(kp)):
        errors += (not fail("signature.jws/public.jwk absent (signature stripping)"))
    elif root is None:
        errors += (not fail("JWS: cannot verify without recomputed root"))
    else:
        jwk = json.loads(read_bytes(kp).decode("utf-8"))
        n = int.from_bytes(b64url_decode(jwk["n"]), "big")
        e = int.from_bytes(b64url_decode(jwk["e"]), "big")
        jws = read_bytes(jp).decode("ascii").strip()
        errors += (not (ok("JWS valid (payload = release root)")
                        if verify_jws(jws, root, n, e) else fail("JWS INVALID")))

    # 4. RFC-3161 existence
    print("[4] RFC-3161 receipt (existence; crypto-verify = P4)...")
    if os.path.isfile(os.path.join(d, "temporal-proof", "timestamp.tsr")):
        ok("timestamp.tsr present (attested)")
    else:
        print("  ⚠ timestamp.tsr absent (unattested commitment)")

    print("=== " + ("✓ VERIFICATION PASSED" if errors == 0
                    else f"✗ FAILED ({errors})") + " ===")
    return errors == 0


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    return 0 if verify_release(argv[1], argv[2] if len(argv) > 2 else None) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
