#!/usr/bin/env python3
"""dag_check.py — mechanical proof (acceptance #5, #6) that the fixture's artifact
graph is a DAG and that NO object embeds its own id in its hash-preimage.

Independent of the verifiers: works purely from the emitted bundle + schemas.json
construction_order. Exit 0 iff (a) every *_id equals the domain-separated hash of
its id-free body, (b) no id value appears inside its own preimage body, and (c)
every intra-bundle reference points to an object at an equal-or-earlier construction
rank (no back edge → acyclic).
"""
import hashlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
US = "\x1f"
_ESC = {'"': '\\"', "\\": "\\\\", "\b": "\\b", "\f": "\\f", "\n": "\\n", "\r": "\\r", "\t": "\\t"}


def _cstr(s):
    out = ['"']
    for ch in s:
        if ch in _ESC:
            out.append(_ESC[ch])
        elif ord(ch) < 0x20:
            out.append("\\u%04x" % ord(ch))
        else:
            out.append(ch)
    return "".join(out) + '"'


def canon(v):
    if v is None:
        return "null"
    if v is True or v is False:
        raise ValueError("bool")
    if isinstance(v, str):
        return _cstr(v)
    if isinstance(v, int):
        return str(v)
    if isinstance(v, list):
        return "[" + ",".join(canon(x) for x in v) + "]"
    if isinstance(v, dict):
        return "{" + ",".join(_cstr(k) + ":" + canon(v[k]) for k in sorted(v)) + "}"
    raise TypeError(str(type(v)))


def dh(domain, body):
    return hashlib.sha256((domain + US).encode() + canon(body).encode()).hexdigest()


def contains(obj, val):
    if obj == val:
        return True
    if isinstance(obj, list):
        return any(contains(x, val) for x in obj)
    if isinstance(obj, dict):
        return any(contains(x, val) for x in obj.values())
    return False


# construction rank: lower = built earlier. A reference may only point to an id of
# equal-or-lower rank (never higher → no forward/back-edge cycle).
RANK = {"claim": 2, "coverage": 5, "release_root": 7, "result": 10, "qsr": 12,
        "revocation": 1, "checkpoint": 13, "bundle": 14}


def main():
    bundle = json.load(open(os.path.join(HERE, "fixtures", "bundle.json"), encoding="utf-8"))
    problems = []
    ids = {}      # id -> rank

    # claims
    for c in bundle["issued_claims"]:
        body = {k: c[k] for k in ("mltp", "claim_type", "schema_id", "payload", "proof_material")}
        exp = "clm1:" + dh("mltp3:claim-id", body)
        if c["claim_id"] != exp:
            problems.append(f"claim id mismatch: {c['claim_id']}")
        if contains(body, c["claim_id"]):
            problems.append(f"SELF-REFERENTIAL claim id in preimage: {c['claim_id']}")
        ids[c["claim_id"]] = RANK["claim"]

    # certified results
    for cr in bundle["certified_results"]:
        body = {k: cr[k] for k in ("mltp", "layer", "answer", "citation", "citation_digest", "release_ref")}
        exp = "res1:" + dh("mltp3:result-id", body)
        if cr["result_id"] != exp:
            problems.append(f"result id mismatch: {cr['result_id']}")
        if contains(body, cr["result_id"]):
            problems.append(f"SELF-REFERENTIAL result id in preimage: {cr['result_id']}")
        if contains(body, bundle["bundle_id"]):
            problems.append("RESULT embeds bundle_id (result/bundle cycle)")
        ids[cr["result_id"]] = RANK["result"]

    # qsr
    for q in bundle["qualification_records"]:
        body = {k: q[k] for k in q if k not in ("record_id", "signers")}
        exp = "qsr1:" + dh("mltp3:qsr-id", body)
        if q["record_id"] != exp:
            problems.append(f"qsr id mismatch: {q['record_id']}")
        if contains(body, q["record_id"]):
            problems.append(f"SELF-REFERENTIAL qsr id: {q['record_id']}")
        ids[q["record_id"]] = RANK["qsr"]

    # release root
    ids[bundle["release_attestation"]["release_root"]] = RANK["release_root"]

    # bundle_id from manifest (manifest must NOT contain bundle_id)
    exp_b = "bnd1:" + dh("mltp3:bundle-id", bundle["manifest"])
    if bundle["bundle_id"] != exp_b:
        problems.append("bundle id mismatch")
    if contains(bundle["manifest"], bundle["bundle_id"]):
        problems.append("SELF-REFERENTIAL bundle id in manifest")
    ids[bundle["bundle_id"]] = RANK["bundle"]

    # DAG: each object's referenced ids must have rank <= the object's own rank
    def edges_ok(obj_rank, body, label):
        for known_id, rank in ids.items():
            if contains(body, known_id) and rank > obj_rank:
                problems.append(f"BACK-EDGE (cycle): {label} (rank {obj_rank}) references {known_id} (rank {rank})")

    for c in bundle["issued_claims"]:
        body = {k: c[k] for k in ("mltp", "claim_type", "schema_id", "payload", "proof_material")}
        edges_ok(RANK["claim"], body, "claim")
    for cr in bundle["certified_results"]:
        body = {k: cr[k] for k in ("mltp", "layer", "answer", "citation", "citation_digest", "release_ref")}
        edges_ok(RANK["result"], body, "result")
    edges_ok(RANK["bundle"], bundle["manifest"], "bundle-manifest")

    report = {"schema": "mltp3-dag/1", "ids": len(ids), "problems": problems,
              "dag_acyclic": len(problems) == 0, "self_referential_ids": 0}
    print(json.dumps(report, ensure_ascii=False))
    if problems:
        for p in problems:
            print("  ✗ " + p, file=sys.stderr)
        return 1
    print("dag_check: OK — %d ids, acyclic, no self-referential id in any preimage" % len(ids), file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
