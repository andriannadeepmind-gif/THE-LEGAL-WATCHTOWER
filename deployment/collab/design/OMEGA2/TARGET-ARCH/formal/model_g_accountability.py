"""MODEL G — I-42 Typed Accountability Evidence (architecture evidence).

Reviewer-B's discipline: two independent implementations may disagree because the SPEC is
ambiguous, so disagreement must never be laundered into blame. Accountability evidence is
therefore typed, and only one of the three types attributes misbehaviour to a signer.

  EquivocationProof      same signer, same (domain, cut), mutually incompatible signed
                         statements -> transferable, independently verifiable misbehaviour
  ProtocolViolationProof signed artifact + deterministic verification recipe -> proof that a
                         DEFINED protocol rule was broken by a named signer
  DisagreementEvidence   two different signers produced different outputs -> evidence only,
                         attribution = NONE until an independent checker or a spec ceremony
                         establishes which rule was broken

Cryptographic attribution of protocol misbehaviour is NOT juridical culpability; the word
"culpability" is deliberately absent from the evidence types.
"""
from __future__ import annotations
import hashlib

KEYS = {"opA": b"secret-A", "opB": b"secret-B", "projX": b"secret-X", "projY": b"secret-Y"}

def sign(signer: str, domain: str, cut: str, content: str) -> dict:
    payload = f"{domain}|{cut}|{content}".encode()
    sig = hashlib.sha256(KEYS[signer] + payload).hexdigest()
    return {"signer": signer, "domain": domain, "cut": cut, "content": content, "sig": sig}

def verify(st: dict) -> bool:
    if st["signer"] not in KEYS:
        return False
    payload = f"{st['domain']}|{st['cut']}|{st['content']}".encode()
    return hashlib.sha256(KEYS[st["signer"]] + payload).hexdigest() == st["sig"]

def build_equivocation_proof(s1: dict, s2: dict):
    if not (verify(s1) and verify(s2)):
        return None, "a statement does not verify"
    if s1["signer"] != s2["signer"]:
        return None, "different signers: this is disagreement, not equivocation"
    if (s1["domain"], s1["cut"]) != (s2["domain"], s2["cut"]):
        return None, "different context: statements are not mutually exclusive"
    if s1["content"] == s2["content"]:
        return None, "identical content: no conflict"
    return {"type": "EquivocationProof", "attributed_to": s1["signer"],
            "context": (s1["domain"], s1["cut"]), "statements": [s1, s2],
            "recipe": "verify both signatures; assert same signer+domain+cut; assert contents differ"}, "ok"

def check_equivocation_proof(p: dict) -> bool:
    a, b = p["statements"]
    return (verify(a) and verify(b) and a["signer"] == b["signer"]
            and (a["domain"], a["cut"]) == (b["domain"], b["cut"]) and a["content"] != b["content"])

def build_protocol_violation_proof(st: dict, rule, rule_name: str):
    if not verify(st):
        return None, "statement does not verify"
    if rule(st):
        return None, "no violation: the statement satisfies the rule"
    return {"type": "ProtocolViolationProof", "attributed_to": st["signer"],
            "rule": rule_name, "statement": st,
            "recipe": f"verify signature; evaluate rule '{rule_name}' deterministically"}, "ok"

def build_disagreement_evidence(a: dict, b: dict):
    if not (verify(a) and verify(b)):
        return None, "a statement does not verify"
    if a["signer"] == b["signer"]:
        return None, "same signer: this is equivocation, not disagreement"
    return {"type": "DisagreementEvidence", "attributed_to": None,
            "parties": [a["signer"], b["signer"]], "outputs": [a, b],
            "next_step": "independent checker or spec ceremony (MIC rule 7)"}, "ok"

# rule used for the ProtocolViolationProof fixture: a certificate may only bind a control
# prefix that causally precedes it (I-21)
def causal_rule(st: dict) -> bool:
    ref = int(st["content"].split("=")[1]); pos = int(st["cut"].split("K")[1])
    return ref <= pos

def run():
    out, ok = {}, True
    a1 = sign("opA", "checkpoint", "K7", "root=aaa")
    a2 = sign("opA", "checkpoint", "K7", "root=bbb")
    p, why = build_equivocation_proof(a1, a2)
    out["true_equivocation"] = (p is not None and check_equivocation_proof(p), why,
                               p["attributed_to"] if p else None)
    ok &= out["true_equivocation"][0]

    x = sign("projX", "state-root", "K9", "root=111")
    y = sign("projY", "state-root", "K9", "root=222")
    p2, why2 = build_equivocation_proof(x, y)
    d, why3 = build_disagreement_evidence(x, y)
    no_false_blame = (p2 is None) and (d is not None) and (d["attributed_to"] is None)
    out["independent_disagreement"] = (no_false_blame, why2, d["attributed_to"] if d else "n/a")
    ok &= no_false_blame

    bad = sign("opB", "PC", "K3", "control_ref=5")     # binds a future prefix -> violates I-21
    good = sign("opB", "PC", "K3", "control_ref=3")
    pv, _ = build_protocol_violation_proof(bad, causal_rule, "I-21 causal certificate order")
    pv_none, _ = build_protocol_violation_proof(good, causal_rule, "I-21 causal certificate order")
    out["protocol_violation"] = (pv is not None and pv["attributed_to"] == "opB" and pv_none is None,
                                 "violating statement yields a proof; conforming one does not",
                                 pv["attributed_to"] if pv else None)
    ok &= out["protocol_violation"][0]

    forged = {**a1, "sig": "0" * 64}
    p3, why4 = build_equivocation_proof(forged, a2)
    out["unverifiable_statement"] = (p3 is None, why4, None)
    ok &= p3 is None

    same = sign("opA", "checkpoint", "K7", "root=aaa")
    p4, why5 = build_equivocation_proof(a1, same)
    out["identical_restatement"] = (p4 is None, why5, None)
    ok &= p4 is None
    return out, ok

if __name__ == "__main__":
    res, ok = run()
    for name, (good, why, attributed) in res.items():
        print(f"{name:26s}: {'PASS' if good else 'FAIL'} — {why} | attributed_to={attributed}")
    print("\nMODEL G:", "PASS" if ok else "FAIL")
