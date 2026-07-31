#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""[0088 Φ7-HARDENING #4B] ΑΝΕΞΑΡΤΗΤΟΣ portable verifier του authority-proof-bundle.

Δεύτερη γλώσσα (Python, μόνο stdlib: hashlib/base64/json) — ΔΕΝ χρησιμοποιεί
καμία Lisp έδρα (Merkle/JWS/TSA/journal). Επανυπολογίζει ΑΝΕΞΑΡΤΗΤΑ τα
δομικά commitments του bundle και ελέγχει N-version συμφωνία με τις τιμές που
παρήγαγε ο Lisp verifier:
  • merkle root of strings κατά το κανονικό profile lawmax-merkle-sha256-v1
    (RFC 6962/9162: domain-separated 0x00 leaf / 0x01 node,
    unbalanced split k<n≤2k) — receipt-set-root, verifier-set-root·
  • canonical authority-statement (tag \\x1e, ταξινομημένα key \\x1f value \\x1e)
    + sha256 — η υπογεγραμμένη δέσμευση ΟΛΩΝ των ριζών·
  • RFC-7638 Ed25519 (OKP) JWK thumbprint·
  • εσωτερική συνέπεια: receipt-set-root ≡ MTH(receipt-ids), το authority-statement
    δεσμεύει ΤΙΣ ΙΔΙΕΣ ρίζες με το census/tlog.
Επιπλέον: RFC-6962 §2.1.1 inclusion path + RFC-9162 §2.1.4.2 consistency (οι πιο
error-prone pure-hash αλγόριθμοι — δεύτερη ανεξάρτητη υλοποίηση, χωρίς crypto lib).
ΚΑΘΕ διαφωνία ⇒ exit 1 (fail-closed). Είσοδος: vector JSON (stdin ή argv[1]).

ΔΗΛΩΜΕΝΟ ΟΡΙΟ (τίμια): αυτός ο verifier είναι N-version για τα STRUCTURAL-ENCODING
commitments (merkle/canonical/thumbprint/inclusion/consistency). ΔΕΝ επαληθεύει
signatures (RSA JWS / Ed25519 / RFC-3161 TSR) ούτε το journal replay — αυτά έχουν
ΜΙΑ (Lisp) υλοποίηση· η δεύτερη γλώσσα εδώ πιάνει encoding/merkle/canonical σφάλμα
που μια μόνη υλοποίηση θα «επιβεβαίωνε» ταυτολογικά.
"""
import base64, hashlib, json, sys

def b64url_nopad(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode("ascii")

def sha256_tag(b: bytes) -> str:
    return "sha256:" + hashlib.sha256(b).hexdigest()

# ── RFC 6962 domain-separated Merkle (ΑΚΡΙΒΩΣ όπως orchestrator.merkle) ──
def hash_leaf_string(s: str) -> str:
    return sha256_tag(b"\x00" + s.encode("utf-8"))

def hash_node(left: str, right: str) -> str:
    bl = bytes.fromhex(left[7:])
    br = bytes.fromhex(right[7:])
    return sha256_tag(b"\x01" + bl + br)

def largest_pow2_below(n: int) -> int:
    k = 1
    while k * 2 < n:
        k *= 2
    return k

def merkle_tree_hash(leaves):
    n = len(leaves)
    if n == 0:
        raise ValueError("empty merkle")
    if n == 1:
        return leaves[0]
    k = largest_pow2_below(n)
    return hash_node(merkle_tree_hash(leaves[:k]), merkle_tree_hash(leaves[k:]))

def merkle_root_of_strings(strings):
    return merkle_tree_hash([hash_leaf_string(s) for s in strings])

# RFC 6962 §2.1.1 audit/inclusion path (independent re-impl, no Lisp seat)
def verify_inclusion(leaf_hash, path, root):
    cur = leaf_hash
    for step in path:  # step = {"side": "left"|"right", "sib": "sha256:.."}
        side, sib = step["side"], step["sib"]
        if side == "left":
            cur = hash_node(sib, cur)
        elif side == "right":
            cur = hash_node(cur, sib)
        else:
            raise ValueError("bad inclusion side")
    return cur == root

# RFC 9162 §2.1.4.2 consistency verification (independent re-impl of the Lisp loop)
def verify_consistency(m, n, old_root, new_root, proof):
    if m < 1 or m > n:
        return False
    if m == n:
        return (not proof) and old_root == new_root
    path = ([old_root] + list(proof)) if (m & (m - 1)) == 0 else list(proof)
    if not path:
        return False
    fn, sn = m - 1, n - 1
    while fn & 1:
        fn >>= 1; sn >>= 1
    fr = sr = path[0]
    ok = True
    for c in path[1:]:
        if sn == 0:
            ok = False; break
        if (fn & 1) or (fn == sn):
            fr = hash_node(c, fr); sr = hash_node(c, sr)
            while fn != 0 and (fn & 1) == 0:
                fn >>= 1; sn >>= 1
        else:
            sr = hash_node(sr, c)
        fn >>= 1; sn >>= 1
    return ok and sn == 0 and fr == old_root and sr == new_root

# ── canonical statement (ΑΚΡΙΒΩΣ apb:canonical-statement-string) ──
SEP_FIELD = "\x1e"   # #x1e
SEP_KV = "\x1f"      # #x1f
def canonical_statement(tag: str, kv: dict) -> str:
    for k, v in list(kv.items()) + [("__tag__", tag)]:
        if SEP_FIELD in str(k) or SEP_KV in str(k) or SEP_FIELD in str(v) or SEP_KV in str(v):
            raise ValueError("separator control byte in field")
    out = [tag, SEP_FIELD]
    for k in sorted(kv.keys()):
        out += [k, SEP_KV, str(kv[k]), SEP_FIELD]
    return "".join(out)

def ed25519_jwk_thumbprint(x: str) -> str:
    raw = base64.urlsafe_b64decode(x + "=" * (-len(x) % 4))
    if len(raw) != 32:
        raise ValueError("ed25519 x not 32 bytes")
    xr = b64url_nopad(raw)  # recanonicalize
    canon = '{"crv":"Ed25519","kty":"OKP","x":"%s"}' % xr
    return b64url_nopad(hashlib.sha256(canon.encode("utf-8")).digest())

def verify(vec):
    disagreements = []
    def check(name, got, want):
        if got != want:
            disagreements.append("%s: python=%r ≠ lisp=%r" % (name, got, want))

    # 1. receipt-set-root
    check("receipt_set_root",
          merkle_root_of_strings(vec["receipt_ids"]), vec["receipt_set_root"])
    # 2. verifier-set-root
    check("verifier_set_root",
          merkle_root_of_strings(vec["verifier_set"]), vec["verifier_set_root"])
    # 3. canonical authority-statement sha256
    astmt = canonical_statement(vec["authority_statement_tag"],
                                vec["authority_statement_fields"])
    check("authority_statement_sha256",
          sha256_tag(astmt.encode("utf-8")), vec["authority_statement_sha256"])
    # 4. owner Ed25519 thumbprint (incl. non-canonical x → same identity)
    check("owner_thumbprint",
          ed25519_jwk_thumbprint(vec["owner_x"]), vec["owner_thumbprint"])
    if "owner_x_noncanonical" in vec:
        check("owner_thumbprint_noncanonical",
              ed25519_jwk_thumbprint(vec["owner_x_noncanonical"]), vec["owner_thumbprint"])
    # 4b. merkle boundary sizes (n=1,n=2) + inclusion + consistency (RFC 6962/9162)
    for mv in vec.get("merkle_roots", []):
        check("merkle_root[%s]" % mv["label"],
              merkle_root_of_strings(mv["strings"]), mv["root"])
    for iv in vec.get("inclusions", []):
        got = verify_inclusion(iv["leaf"], iv["path"], iv["root"])
        check("inclusion[%s]" % iv["label"], got, iv["expect"])
    for cv in vec.get("consistencies", []):
        got = verify_consistency(cv["m"], cv["n"], cv["old_root"], cv["new_root"], cv["proof"])
        check("consistency[%s]" % cv["label"], got, cv["expect"])
    # 5. internal consistency: το authority-statement δεσμεύει ΤΙΣ ΙΔΙΕΣ ρίζες
    af = vec["authority_statement_fields"]
    if af.get("receipt_set_root") != vec["receipt_set_root"]:
        disagreements.append("authority-statement receipt_set_root ≠ census")
    if af.get("verifier_set_root") != vec["verifier_set_root"]:
        disagreements.append("authority-statement verifier_set_root ≠ recomputed")

    if disagreements:
        print("verify-authority-bundle: %d ΔΙΑΦΩΝΙΕΣ" % len(disagreements))
        for d in disagreements:
            print("  ✗ " + d)
        sys.exit(1)
    print("verify-authority-bundle: OK — N-version agreement (%d commitments)" %
          (4 + len(vec["receipt_ids"])))

def main():
    src = open(sys.argv[1], encoding="utf-8").read() if len(sys.argv) > 1 else sys.stdin.read()
    verify(json.loads(src))

if __name__ == "__main__":
    main()
