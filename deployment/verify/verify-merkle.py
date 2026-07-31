#!/usr/bin/env python3
"""MERKLE-SINGLE-TRUTH — independent Python conformance verifier (pure stdlib).

This is an INDEPENDENT implementation of the canonical profile
`lawmax-merkle-sha256-v1` (RFC 9162 §2.1.1). It is deliberately NOT generated
from any shared code: N-version diversity is the defence against a bug in a
single implementation, and a common code generator would destroy it. Only the
DATA (golden vectors) is shared.

It checks this implementation against deployment/verify/vectors/merkle/vectors.json:
  * empty tree root                         MTH([]) = SHA-256("")
  * every leaf vector (inputs given as HEX — never trust a string parser)
  * every tree root                         n = 0..8, 15, 16, 17
  * every inclusion path
  * every consistency proof
  * the full differential range             every n in [from, to]

Usage:  verify-merkle.py [vectors.json]
Exit:   0 = every vector matches;  1 = ANY divergence;  2 = usage/IO error.
"""
import sys, os, json, hashlib

PREFIX = "sha256:"
LEAF_DOMAIN = b"\x00"
NODE_DOMAIN = b"\x01"


def _h(domain: bytes, data: bytes) -> str:
    return PREFIX + hashlib.sha256(domain + data).hexdigest()


def leaf_hash_bytes(data: bytes) -> str:
    """MTH({d}) = SHA-256(0x00 || d)."""
    return _h(LEAF_DOMAIN, data)


def node(a: str, b: str) -> str:
    """node(l,r) = SHA-256(0x01 || raw(l) || raw(r)) — RAW bytes, not hex text."""
    return _h(NODE_DOMAIN, bytes.fromhex(a[len(PREFIX):]) + bytes.fromhex(b[len(PREFIX):]))


def largest_power_of_two_below(n: int) -> int:
    """k such that k < n <= 2k (n >= 2)."""
    k = 1
    while k * 2 < n:
        k *= 2
    return k


def mth(leaves):
    """RFC 9162 §2.1.1 Merkle Tree Hash over ALREADY-HASHED leaves.
    NEVER duplicate-last: the odd case splits at the largest power of two < n."""
    if len(leaves) == 0:
        return PREFIX + hashlib.sha256(b"").hexdigest()
    if len(leaves) == 1:
        return leaves[0]
    k = largest_power_of_two_below(len(leaves))
    return node(mth(leaves[:k]), mth(leaves[k:]))


def tree_leaves(n):
    """Profile rule: leaf data for index i = ASCII bytes of decimal i."""
    return [leaf_hash_bytes(str(i).encode("ascii")) for i in range(n)]


def verify_inclusion(leaf: str, path, root: str) -> bool:
    h = leaf
    for step in path:
        # side = θέση του ΑΔΕΡΦΟΥ ως προς τον τρέχοντα hash (ίδιο με verify.py
        # και με source/merkle-authority.lisp): "left" ⇒ node(sib, h).
        h = node(step["hash"], h) if step["side"] == "left" else node(h, step["hash"])
    return h == root


def path_gen(m: int, lo: int, hi: int, leaves):
    """RFC 9162 §2.1.3.1 PATH(m, D[n]) — INDEPENDENT construction, outside the
    Lisp TCB. The generator's own cross-checks share an author and an image
    with the production seat; THIS build is the out-of-TCB authority that the
    emitted path is the canonical RFC path, element for element — not merely
    one that happens to fold to the root."""
    n = hi - lo
    if n == 1:
        return []
    k = largest_power_of_two_below(n)
    if m < k:
        return path_gen(m, lo, lo + k, leaves) + \
            [{"side": "right", "hash": mth(leaves[lo + k:hi])}]
    return path_gen(m - k, lo + k, hi, leaves) + \
        [{"side": "left", "hash": mth(leaves[lo:lo + k])}]


def proof_gen(m: int, leaves):
    """RFC 9162 §2.1.4.1 PROOF(m, D[n]) = SUBPROOF(m, D[n], true) — independent
    construction of the consistency proof itself (not only its verification)."""
    def sub(m, lo, hi, complete):
        n = hi - lo
        if m == n:
            return [] if complete else [mth(leaves[lo:hi])]
        k = largest_power_of_two_below(n)
        if m <= k:
            return sub(m, lo, lo + k, complete) + [mth(leaves[lo + k:hi])]
        return sub(m - k, lo + k, hi, False) + [mth(leaves[lo:lo + k])]
    n = len(leaves)
    return [] if m == n else sub(m, 0, n, True)


def verify_consistency(m: int, n: int, old_root: str, new_root: str, proof) -> bool:
    """RFC 9162 §2.1.4.2 — verify D[m] is a prefix of D[n] from the roots alone."""
    if m < 1 or m > n:
        return False
    if m == n:
        return not proof and old_root == new_root
    path = list(proof)
    if not path:
        return False
    if m & (m - 1) == 0:            # m an exact power of two ⇒ old_root leads
        path = [old_root] + path
    fn, sn = m - 1, n - 1
    while fn & 1:
        fn >>= 1
        sn >>= 1
    fr = sr = path[0]
    for c in path[1:]:
        if sn == 0:
            return False
        if (fn & 1) or fn == sn:
            fr = node(c, fr)
            sr = node(c, sr)
            while fn != 0 and (fn & 1) == 0:
                fn >>= 1
                sn >>= 1
        else:
            sr = node(sr, c)
        fn >>= 1
        sn >>= 1
    return sn == 0 and fr == old_root and sr == new_root


def main(argv):
    here = os.path.dirname(os.path.abspath(__file__))
    path = argv[1] if len(argv) > 1 else os.path.join(here, "vectors", "merkle", "vectors.json")
    try:
        with open(path, encoding="utf-8") as fh:
            v = json.load(fh)
    except Exception as exc:
        print(f"::error::vectors unreadable: {exc}", file=sys.stderr)
        return 2

    ok = failed = 0

    def check(name, cond):
        nonlocal ok, failed
        if cond:
            ok += 1
        else:
            failed += 1
            print(f"  FAIL {name}")

    check("profile id", v.get("profile") == "lawmax-merkle-sha256-v1")
    check("empty tree root", mth([]) == v["empty_tree_root"])

    for lv in v["leaves"]:
        data = bytes.fromhex(lv["input_hex"])
        check(f"leaf {lv['id']}", leaf_hash_bytes(data) == lv["leaf"])

    for t in v["trees"]:
        check(f"root n={t['n']}", mth(tree_leaves(t["n"])) == t["root"])

    for inc in v["inclusion"]:
        leaves = tree_leaves(inc["n"])
        check(f"inclusion n={inc['n']} i={inc['index']}",
              leaves[inc["index"]] == inc["leaf"]
              and verify_inclusion(inc["leaf"], inc["path"], inc["root"])
              and mth(leaves) == inc["root"])
        # Ανεξάρτητη ΠΑΡΑΓΩΓΗ του path (όχι μόνο επαλήθευση): στοιχείο-στοιχείο.
        check(f"inclusion PATH-gen n={inc['n']} i={inc['index']}",
              path_gen(inc["index"], 0, inc["n"], leaves) == inc["path"])

    for c in v["consistency"]:
        check(f"consistency n={c['n']} m={c['m']}",
              verify_consistency(c["m"], c["n"], c["old_root"], c["new_root"], c["proof"]))
        # Ανεξάρτητη ΠΑΡΑΓΩΓΗ του proof: στοιχείο-στοιχείο.
        check(f"consistency PROOF-gen n={c['n']} m={c['m']}",
              proof_gen(c["m"], tree_leaves(c["n"])) == c["proof"])

    d = v["differential"]
    for i, expected in enumerate(d["roots"]):
        n = d["from"] + i
        check(f"differential n={n}", mth(tree_leaves(n)) == expected)

    print(f"── verify-merkle.py: {ok} ok, {failed} FAIL ──")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
