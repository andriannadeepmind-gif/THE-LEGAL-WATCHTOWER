#!/usr/bin/env python3
"""mutate.py — generate the NEGATIVE test matrix for the MLTP v3 executable
reference. Each mutation is a full (bundle, lts) that BOTH independent verifiers
(Go, Node) must reject with the SAME typed error class. Covers corrections #1..#16
and the eight required negative cryptographic vectors (#7). Re-signs individual
objects with the VETTED libsodium backend (via build_fixtures) so that "validly
signed but semantically broken" cases are genuine, not merely truncated.

Emits fixtures/mut/<name>/{bundle,lts}.json and fixtures/mutations.json (index with
expected result + allowed reasons + KW id).
"""
import copy
import json
import os

import build_fixtures as B

FIX = B.FIX
MUT = os.path.join(FIX, "mut")


def canon(o):
    return B.canon(o)


def sign_as(role, context, obj_no_sig):
    return B.sign_as(role, context, obj_no_sig)


def resign_claim(claim, role, context="mltp3:issued-claim", set_signer=True):
    c = copy.deepcopy(claim)
    if set_signer:
        c["signer"]["kid"] = B.KEYS[role]["kid"]
    signed = {k: v for k, v in c.items() if k != "signature"}
    raw = B.cx.sign(B.KEYS[role]["secret"], (context + B.US).encode() + canon(signed).encode())
    c["signature"] = {"alg": "Ed25519", "kid": B.KEYS[role]["kid"],
                      "delegation_seq": c["signature"]["delegation_seq"], "sig": B.cx.b64u(raw)}
    return c


def base():
    return B.build()["bundle"], B.build()["lts"]


MUTATIONS = []


def add(name, kw, result, reasons, mutate_fn, desc, opts=None):
    if opts is not None:
        built = B.build(opts)
        bundle, lts = built["bundle"], built["lts"]
    else:
        bundle, lts = base()
    bundle, lts = mutate_fn(bundle, lts)
    d = os.path.join(MUT, name)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "bundle.json"), "w", encoding="utf-8") as fh:
        fh.write(json.dumps(bundle, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n")
    with open(os.path.join(d, "lts.json"), "w", encoding="utf-8") as fh:
        fh.write(json.dumps(lts, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n")
    MUTATIONS.append({"name": name, "kw": kw, "expected_result": result,
                      "expected_reasons": reasons, "desc": desc})



def resign_result(bundle, edit):
    cr = bundle["certified_results"][0]
    body = {"mltp": cr["mltp"], "layer": cr["layer"], "answer": copy.deepcopy(cr["answer"]),
            "citation": copy.deepcopy(cr["citation"]), "citation_digest": cr["citation_digest"],
            "release_ref": cr["release_ref"]}
    edit(body)
    result_id = "res1:" + B.cid("mltp3:result-id", body)
    newcr = dict(body)
    newcr["result_id"] = result_id
    newcr["signer"] = {"alg": "Ed25519", "kid": B.KEYS["delegate_certified"]["kid"], "delegation_seq": 2}
    raw = B.cx.sign(B.KEYS["delegate_certified"]["secret"],
                    ("mltp3:certified-result" + B.US).encode() + canon(newcr).encode())
    newcr["signature"] = {"alg": "Ed25519", "kid": B.KEYS["delegate_certified"]["kid"],
                          "delegation_seq": 2, "sig": B.cx.b64u(raw)}
    bundle["certified_results"][0] = newcr
    import hashlib
    imprint = "sha256:" + hashlib.sha256(raw).hexdigest()
    bundle["time_attestations"] = [t for t in bundle["time_attestations"] if t.get("attests_context") != "mltp3:certified-result"]
    ta = {"mltp": "3", "layer": "TimeAttestation", "attests_context": "mltp3:certified-result",
          "target_id": result_id, "target_sig_imprint": imprint, "gen_time": B.T_GEN,
          "accuracy_seconds": B.T_ACC, "tsa_kid": B.KEYS["tsa"]["kid"]}
    ta["sig"] = sign_as("tsa", "mltp3:time-attestation", ta)
    bundle["time_attestations"].append(ta)
    tok = {"mltp": "3", "layer": "CitationToken", "citation": newcr["citation"], "result_id": result_id,
           "signer": {"alg": "Ed25519", "kid": B.KEYS["delegate_certified"]["kid"], "delegation_seq": 2}}
    tok["sig"] = sign_as("delegate_certified", "mltp3:citation",
                         {"citation": newcr["citation"], "result_id": result_id})
    bundle["citation_tokens"] = [tok]
    return bundle


def first_claim_idx(bundle, ctype):
    for i, c in enumerate(bundle["issued_claims"]):
        if c["claim_type"] == ctype:
            return i
    raise KeyError(ctype)


# ---- correction #1: self-referential id --------------------------------------
def m_selfid(bundle, lts):
    i = first_claim_idx(bundle, "source-authenticity")
    c = bundle["issued_claims"][i]
    c["payload"]["_injected"] = c["claim_id"]      # id now appears in its own preimage
    return bundle, lts


def m_idmismatch(bundle, lts):
    i = first_claim_idx(bundle, "source-authenticity")
    bundle["issued_claims"][i]["payload"]["work_id"] = "gr/TAMPERED"
    return bundle, lts


# ---- correction #2/#3: timestamp / release-root cycle re-introduced -----------
def m_timestamp_in_signed(bundle, lts):
    i = first_claim_idx(bundle, "legal-state")
    bundle["issued_claims"][i]["signed_at"] = {"trusted_time": 1749990000}
    return bundle, lts


def m_release_root_in_claim(bundle, lts):
    i = first_claim_idx(bundle, "legal-state")
    bundle["issued_claims"][i]["release_root"] = bundle["release_attestation"]["release_root"]
    return bundle, lts


# ---- correction #4: result/bundle cycle --------------------------------------
def m_result_bundle_cycle(bundle, lts):
    bundle["certified_results"][0]["answer"]["_bref"] = bundle["bundle_id"]
    return bundle, lts


# ---- correction #5: revocation checkpoint ------------------------------------
def m_unsigned_checkpoint(bundle, lts):
    bundle["revocation_checkpoint"]["signers"] = bundle["revocation_checkpoint"]["signers"][:1]
    return bundle, lts


def m_stale_checkpoint(bundle, lts):
    bundle["revocation_checkpoint"]["checkpoint_at"] = lts["trusted_now"] - 200000
    # re-sign so the only defect is staleness
    cp = bundle["revocation_checkpoint"]
    body = {k: v for k, v in cp.items() if k != "signers"}
    cp["signers"] = [{"alg": "Ed25519", "kid": B.KEYS[r]["kid"],
                      "sig": sign_as(r, "mltp3:witness-checkpoint", body)} for r in ("witness1", "witness2")]
    return bundle, lts


def m_omitted_revocation(bundle, lts):
    bundle["revocation_checkpoint"]["revocations"] = []
    cp = bundle["revocation_checkpoint"]
    body = {k: v for k, v in cp.items() if k != "signers"}
    cp["signers"] = [{"alg": "Ed25519", "kid": B.KEYS[r]["kid"],
                      "sig": sign_as(r, "mltp3:witness-checkpoint", body)} for r in ("witness1", "witness2")]
    return bundle, lts


# ---- correction #6 (verify_attestation): scope / window / revocation ----------
def m_wrong_scope(bundle, lts):
    i = first_claim_idx(bundle, "legal-state")
    bundle["issued_claims"][i] = resign_claim(bundle["issued_claims"][i], "delegate_certified")
    return bundle, lts


def m_expired_time(bundle, lts):
    i = first_claim_idx(bundle, "legal-state")
    tgt = bundle["issued_claims"][i]["claim_id"]
    for ta in bundle["time_attestations"]:
        if ta["target_id"] == tgt:
            ta["gen_time"] = 1770000000     # after not_after (1760000000)
            body = {k: v for k, v in ta.items() if k != "sig"}
            ta["sig"] = sign_as("tsa", "mltp3:time-attestation", body)
    return bundle, lts


def m_revoked_signer(bundle, lts):
    # add a root-signed revocation for the delegate_release key, invalid_from before t_sig
    rs = {"mltp": "3", "layer0": "RevocationStatement",
          "revoked_subject": B.KEYS["delegate_release"]["kid"], "invalid_from": 1749000000,
          "reason": "key-compromise", "owner_kid": B.KEYS["owner_root"]["kid"]}
    rs["sig"] = sign_as("owner_root", "mltp3:revocation", rs)
    bundle["revocation_statements"].append(rs)
    # include it in the checkpoint so the checkpoint stays consistent (else omitted-revocation)
    rid = "rev1:" + B.cid("mltp3:revocation-id", {k: v for k, v in rs.items() if k != "sig"})
    cp = bundle["revocation_checkpoint"]
    ids = sorted([r["statement_id"] for r in cp["revocations"]] + [rid])
    leaves = [B.leaf(x.encode()) for x in ids]
    cp["log_root"] = B.mth(leaves)
    cp["tree_size"] = len(ids)
    cp["revocations"] = [{"statement_id": x, "revoked_subject": (B.KEYS["delegate_release"]["kid"] if x == rid else None),
                          "inclusion": {"leaf": leaves[ids.index(x)], "path": B.inclusion_path(ids.index(x), 0, len(ids), leaves)}} for x in ids]
    body = {k: v for k, v in cp.items() if k != "signers"}
    cp["signers"] = [{"alg": "Ed25519", "kid": B.KEYS[r]["kid"],
                      "sig": sign_as(r, "mltp3:witness-checkpoint", body)} for r in ("witness1", "witness2")]
    return bundle, lts


# ---- correction #7/#8: answer completeness & citation binding -----------------
def m_dependency_unverified(bundle, lts):
    resign_result(bundle, lambda b: b["answer"].__setitem__(
        "dependency_set", sorted(b["answer"]["dependency_set"] + ["clm1:does-not-exist"])))
    return bundle, lts


def m_citation_not_in_deps(bundle, lts):
    cited = bundle["certified_results"][0]["citation"]["claim_id"]
    resign_result(bundle, lambda b: b["answer"].__setitem__(
        "dependency_set", [d for d in b["answer"]["dependency_set"] if d != cited]))
    return bundle, lts


def m_citation_digest_altered(bundle, lts):
    resign_result(bundle, lambda b: b.__setitem__("citation_digest", "sha256:" + "0" * 64))
    return bundle, lts


def m_citation_policy_untrusted(bundle, lts):
    lts["trusted_citation_policies"] = []       # consumer trusts no policy
    return bundle, lts


# ---- correction #9: provider conformance -------------------------------------
def m_provider_nonconformant(bundle, lts):
    pc = bundle["provider_conformance"][0]
    pc["expiry"] = lts["trusted_now"] - 1
    body = {k: v for k, v in pc.items() if k != "sig"}
    pc["sig"] = sign_as("provider1", "mltp3:provider-conformance", body)
    return bundle, lts


def m_provider_subject_mismatch(bundle, lts):
    bundle["provider_conformance"][0]["provider_kid"] = B.KEYS["owner_root"]["kid"]  # not in provider registry
    return bundle, lts


# ---- correction #11: coverage missing ----------------------------------------
def m_missing_coverage(bundle, lts):
    return bundle, lts   # opts include_coverage=False handled by add()


# ---- correction #12: fabricated compiler independence ------------------------
def m_identity(bundle, lts):
    return bundle, lts


# ---- correction #14: canonical false/null ------------------------------------
def m_canonical_bool(bundle, lts):
    i = first_claim_idx(bundle, "source-authenticity")
    bundle["issued_claims"][i]["payload"]["_flag"] = True   # boolean forbidden in hash-bearing record
    return bundle, lts


# ---- correction #16 (QSR governance) -----------------------------------------
def m_qsr_no_quorum(bundle, lts):
    bundle["qualification_records"][0]["signers"] = bundle["qualification_records"][0]["signers"][:1]
    return bundle, lts


def m_qsr_issuer_not_disjoint(bundle, lts):
    q = bundle["qualification_records"][0]
    body = {k: v for k, v in q.items() if k != "signers"}
    q["signers"][0] = {"alg": "Ed25519", "kid": B.KEYS["delegate_release"]["kid"],
                       "sig": sign_as("delegate_release", "mltp3:qual-state", body)}
    return bundle, lts


# ---- 8 required negative cryptographic vectors (#7) ---------------------------
def m_crypto_modified_headers(bundle, lts):
    i = first_claim_idx(bundle, "legal-state")
    bundle["issued_claims"][i]["signer"]["delegation_seq"] = 99   # signed header, not in id preimage
    return bundle, lts


def m_crypto_modified_signature(bundle, lts):
    i = first_claim_idx(bundle, "legal-state")
    s = bundle["issued_claims"][i]["signature"]["sig"]
    bundle["issued_claims"][i]["signature"]["sig"] = ("A" if s[0] != "A" else "B") + s[1:]
    return bundle, lts


def m_crypto_wrong_pubkey(bundle, lts):
    i = first_claim_idx(bundle, "legal-state")
    bundle["issued_claims"][i]["signature"]["kid"] = B.KEYS["tsa"]["kid"]  # resolves, but won't verify
    return bundle, lts


def m_crypto_bad_length(bundle, lts):
    i = first_claim_idx(bundle, "legal-state")
    bundle["issued_claims"][i]["signature"]["sig"] = "AAAA"  # decodes to <64 bytes
    return bundle, lts


def m_crypto_malformed_key(bundle, lts):
    for k in bundle["keys"]:
        if k["kid"] == B.KEYS["delegate_release"]["kid"]:
            k["x"] = "AAAA"   # not 32 bytes; breaks delegation key-binding
    return bundle, lts


def m_crypto_replay_context(bundle, lts):
    i = first_claim_idx(bundle, "legal-state")
    # sign the claim body under the WRONG domain separator (mltp3:delegation)
    bundle["issued_claims"][i] = resign_claim(bundle["issued_claims"][i], "delegate_release",
                                              context="mltp3:delegation", set_signer=False)
    return bundle, lts


def main():
    os.makedirs(MUT, exist_ok=True)
    UFMR = "UNVERIFIED_FOR_MACHINE_RELIANCE"
    UFAR = "UNVERIFIED_FOR_ATTRIBUTED_RELIANCE"
    UNK = "UNKNOWN"
    add("selfid-claim", 64, UFMR, ["self-referential-id"], m_selfid, "correction #1: id in own preimage")
    add("id-mismatch", 65, UFMR, ["id-mismatch"], m_idmismatch, "tampered payload caught at id layer")
    add("timestamp-in-signed", 66, UFMR, ["schema-mismatch"], m_timestamp_in_signed, "correction #2: signed_at re-injected")
    add("release-root-in-claim", 67, UFMR, ["schema-mismatch"], m_release_root_in_claim, "correction #3: release_root re-injected")
    add("result-bundle-cycle", 68, UFMR, ["result-bundle-cycle"], m_result_bundle_cycle, "correction #4: bundle_id inside result")
    add("unsigned-checkpoint", 69, UFMR, ["unsigned-revocation-checkpoint"], m_unsigned_checkpoint, "correction #5: <2 witnesses")
    add("stale-checkpoint", 70, UNK, ["stale-revocation-state"], m_stale_checkpoint, "correction #5: checkpoint too old")
    add("omitted-revocation", 71, UFMR, ["omitted-revocation"], m_omitted_revocation, "correction #5: newer revocation hidden")
    add("wrong-scope", 72, UFMR, ["delegation-scope-violation"], m_wrong_scope, "correction #6: scope not covering claim_type")
    add("expired-delegation", 73, UFMR, ["delegation-expired"], m_expired_time, "correction #6/#10: t_sig after window")
    add("revoked-signer", 74, UFMR, ["retroactively-revoked"], m_revoked_signer, "correction #6: signature by revoked key")
    add("dependency-unverified", 75, UFMR, ["dependency-unverified"], m_dependency_unverified, "correction #7: unresolvable dependency")
    add("arbitrary-answer-one-citation", 76, UFAR, ["citation-unbound"], m_citation_not_in_deps, "correction #7/#8: valid citation, answer not dependent")
    add("citation-digest-altered", 77, UFAR, ["citation-unbound"], m_citation_digest_altered, "correction #8: stripped/altered citation")
    add("citation-policy-untrusted", 78, UFAR, ["citation-policy-untrusted"], m_citation_policy_untrusted, "correction #8: untrusted citation policy")
    add("provider-nonconformant", 79, UFMR, ["provider-nonconformant"], m_provider_nonconformant, "correction #9: expired conformance")
    add("provider-subject-mismatch", 80, UFMR, ["provider-subject-mismatch"], m_provider_subject_mismatch, "correction #9: provider not in registry")
    add("missing-coverage", 81, UNK, ["coverage-missing"], m_missing_coverage, "correction #11: no coverage evidence", opts={"include_coverage": False})
    add("fabricated-compiler-independence", 82, UFMR, ["fabricated-compiler-independence"], m_identity, "correction #12: same family/source", opts={"fabricate_compiler": True})
    add("canonical-bool", 83, UFMR, ["malformed-envelope"], m_canonical_bool, "correction #14: boolean in hash-bearing record")
    add("misrepresented-treatment", 84, UFMR, ["misrepresented-treatment"], m_identity, "correction #15: 'overruled' without adoption", opts={"treatment_verb": "overruled"})
    add("qsr-no-quorum", 85, UFMR, ["unauthorized-qualification-issuer"], m_qsr_no_quorum, "correction #16: <2 auditors")
    add("qsr-issuer-not-disjoint", 86, UFMR, ["unauthorized-qualification-issuer"], m_qsr_issuer_not_disjoint, "correction #16: issuer signs own QSR")
    # 8 negative cryptographic vectors (#7)
    add("crypto-modified-payload", 87, UFMR, ["id-mismatch"], m_idmismatch, "crypto neg: modified payload (caught at id layer)")
    add("crypto-modified-headers", 88, UFMR, ["sig-invalid"], m_crypto_modified_headers, "crypto neg: modified protected header")
    add("crypto-modified-signature", 89, UFMR, ["sig-invalid"], m_crypto_modified_signature, "crypto neg: modified signature")
    add("crypto-wrong-pubkey", 90, UFMR, ["sig-invalid"], m_crypto_wrong_pubkey, "crypto neg: wrong public key")
    add("crypto-noncanonical", 91, UFMR, ["malformed-envelope"], m_canonical_bool, "crypto neg: non-canonical payload")
    add("crypto-bad-length", 92, UFMR, ["sig-invalid"], m_crypto_bad_length, "crypto neg: invalid signature length")
    add("crypto-malformed-key", 93, UFMR, ["key-binding-mismatch"], m_crypto_malformed_key, "crypto neg: malformed key")
    add("crypto-replay-context", 94, UFMR, ["sig-invalid"], m_crypto_replay_context, "crypto neg: replay under different domain separator")

    with open(os.path.join(FIX, "mutations.json"), "w", encoding="utf-8") as fh:
        json.dump({"schema": "mltp3-mutations/1", "count": len(MUTATIONS), "mutations": MUTATIONS},
                  fh, ensure_ascii=False, indent=1)
        fh.write("\n")
    print("mutate: %d mutations written (KW-64..KW-%d)" % (len(MUTATIONS), 63 + len(MUTATIONS)))


if __name__ == "__main__":
    main()
