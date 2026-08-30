"""MODEL F — I-41 Verifiable Authoritative Answers (architecture evidence).

Reference construction of an authenticated query view plus a client-side verifier, and the
seeded silent-omission attack the verifier must reject.

Construction: leaves are (key, value) sorted by key, placed at fixed indices in a Merkle tree;
the root is the authenticated_query_view_root that a PC certifies. A range answer carries, for
every returned element, an inclusion proof binding it to BOTH its value and its index, plus the
two boundary leaves immediately outside the range. Completeness follows from index contiguity:
the returned indices must be consecutive and the boundary leaves must fall outside the query
range. Omitting an in-range element breaks contiguity and is rejected without trusting the server.

Scope discipline (Reviewer-B): this proves completeness RELATIVE TO the admitted state at the
EvaluationCut. It says nothing about the completeness of the external legal world.
"""
from __future__ import annotations
import hashlib

def H(*parts: bytes) -> bytes:
    h = hashlib.sha256()
    for p in parts:
        h.update(len(p).to_bytes(4, "big")); h.update(p)
    return h.digest()

DOM_LEAF, DOM_NODE = b"WATCHTOWER/answer/leaf/v1", b"WATCHTOWER/answer/node/v1"

def leaf_hash(i: int, k: str, v: str) -> bytes:
    return H(DOM_LEAF, i.to_bytes(4, "big"), k.encode(), v.encode())

class AuthView:
    """Authenticated query view: a deterministic, PC-certified projection. Never a truth root."""
    def __init__(self, kv: dict[str, str]):
        self.items = sorted(kv.items())
        self.leaves = [leaf_hash(i, k, v) for i, (k, v) in enumerate(self.items)]
        self.levels = [self.leaves]
        cur = self.leaves
        while len(cur) > 1:
            nxt = [H(DOM_NODE, cur[j], cur[j + 1] if j + 1 < len(cur) else cur[j])
                   for j in range(0, len(cur), 2)]
            self.levels.append(nxt); cur = nxt
        self.root = cur[0] if cur else H(DOM_NODE, b"", b"")

    def path(self, i: int) -> list[tuple[str, bytes]]:
        out, idx = [], i
        for lvl in self.levels[:-1]:
            sib = idx ^ 1
            if sib >= len(lvl):
                out.append(("R", lvl[idx]))        # odd level: last node is duplicated
            else:
                out.append(("R", lvl[sib]) if idx % 2 == 0 else ("L", lvl[sib]))
            idx //= 2
        return out

    def answer(self, lo: str, hi: str) -> dict:
        idxs = [i for i, (k, _) in enumerate(self.items) if lo <= k <= hi]
        first, last = (idxs[0], idxs[-1]) if idxs else (0, -1)
        elems = [{"i": i, "k": self.items[i][0], "v": self.items[i][1], "p": self.path(i)}
                 for i in idxs]
        bnd = {}
        if first - 1 >= 0:
            i = first - 1
            bnd["left"] = {"i": i, "k": self.items[i][0], "v": self.items[i][1], "p": self.path(i)}
        if last + 1 < len(self.items):
            i = last + 1
            bnd["right"] = {"i": i, "k": self.items[i][0], "v": self.items[i][1], "p": self.path(i)}
        return {"lo": lo, "hi": hi, "elements": elems, "boundaries": bnd,
                "n": len(self.items), "proof_class": "RANGE_COMPLETENESS"}

def verify_path(i: int, k: str, v: str, path, root: bytes, n: int) -> bool:
    cur, idx = leaf_hash(i, k, v), i
    for side, sib in path:
        cur = H(DOM_NODE, cur, sib) if side == "R" else H(DOM_NODE, sib, cur)
        idx //= 2
    return cur == root

def client_verify(ans: dict, root: bytes) -> tuple[bool, str]:
    """The client trusts only the certified root."""
    els = ans["elements"]
    for e in els:
        if not verify_path(e["i"], e["k"], e["v"], e["p"], root, ans["n"]):
            return False, f"inclusion proof failed at index {e['i']}"
        if not (ans["lo"] <= e["k"] <= ans["hi"]):
            return False, "element outside the queried range"
    for a, b in zip(els, els[1:]):
        if b["i"] != a["i"] + 1:
            return False, f"index gap {a['i']}->{b['i']}: an in-range element was omitted"
    bnd = ans["boundaries"]
    if "left" in bnd:
        L = bnd["left"]
        if not verify_path(L["i"], L["k"], L["v"], L["p"], root, ans["n"]):
            return False, "left boundary proof failed"
        if L["k"] >= ans["lo"]:
            return False, "left boundary is inside the range: a prefix element was omitted"
        if els and L["i"] + 1 != els[0]["i"]:
            return False, "left boundary is not adjacent to the first returned element"
    elif els and els[0]["i"] != 0:
        return False, "no left boundary and the answer does not start at index 0"
    if "right" in bnd:
        R = bnd["right"]
        if not verify_path(R["i"], R["k"], R["v"], R["p"], root, ans["n"]):
            return False, "right boundary proof failed"
        if R["k"] <= ans["hi"]:
            return False, "right boundary is inside the range: a suffix element was omitted"
        if els and els[-1]["i"] + 1 != R["i"]:
            return False, "right boundary is not adjacent to the last returned element"
    elif els and els[-1]["i"] != ans["n"] - 1:
        return False, "no right boundary and the answer does not end at the last index"
    return True, "verified against the certified root"

CORPUS = {f"art{i:02d}": f"text-{i}" for i in range(1, 9)}
ATTACKS = {
    "omit_middle":   lambda a: {**a, "elements": [e for j, e in enumerate(a["elements"]) if j != 1]},
    "omit_last":     lambda a: {**a, "elements": a["elements"][:-1]},
    "omit_first":    lambda a: {**a, "elements": a["elements"][1:]},
    "forge_value":   lambda a: {**a, "elements": [{**a["elements"][0], "v": "TAMPERED"}] + a["elements"][1:]},
    "drop_boundary": lambda a: {**a, "boundaries": {k: v for k, v in a["boundaries"].items() if k != "right"}},
}

def run() -> dict:
    view = AuthView(CORPUS)
    honest = view.answer("art03", "art06")
    ok, why = client_verify(honest, view.root)
    res = {"positive_conformance": (ok, why), "attacks": {}, "wrong_root": None}
    for name, atk in ATTACKS.items():
        bad = atk({k: (list(v) if isinstance(v, list) else v) for k, v in honest.items()})
        rej, why2 = client_verify(bad, view.root)
        res["attacks"][name] = (not rej, why2)
    other = AuthView({**CORPUS, "art09": "x"})
    rej, why3 = client_verify(honest, other.root)
    res["wrong_root"] = (not rej, why3)
    return res

if __name__ == "__main__":
    r = run()
    ok, why = r["positive_conformance"]
    print(f"positive conformance (honest answer verifies): {'PASS' if ok else 'FAIL'} — {why}")
    allgood = ok
    for n, (rejected, why) in r["attacks"].items():
        print(f"attack {n:14s}: {'REJECTED' if rejected else 'ACCEPTED — FAIL'} — {why}")
        allgood &= rejected
    rj, why = r["wrong_root"]
    print(f"attack {'wrong_root':14s}: {'REJECTED' if rj else 'ACCEPTED — FAIL'} — {why}")
    allgood &= rj
    print("\nMODEL F:", "PASS" if allgood else "FAIL")
