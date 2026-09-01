#!/usr/bin/env python3
"""build_fixtures.py — DETERMINISTIC builder for the MLTP v3 executable reference.

Constructs the corrected, ACYCLIC trust graph (schemas.json construction_order)
and signs every entity with the VETTED libsodium backend (crypto_libsodium.py).
Emits fixtures/{keys,bundle,lts,expected}.json. Fully deterministic: fixed key
seeds, fixed integer times, canonical serialization — two runs are byte-identical
(checked by run.sh, acceptance #4).

The builder is NOT a verifier and shares no verification function with Verifier A
(Go) or Verifier B (Node); they share only schemas.json and these fixtures.

NOTE ON SCOPE: this reference asserts NO qualification and NO production trust. The
QualificationStateRecord here carries a non-ladder level and only exercises the
issuer-disjointness / quorum / subject-binding verification path.
"""
import hashlib
import json
import os

import crypto_libsodium as cx

HERE = os.path.dirname(os.path.abspath(__file__))
FIX = os.path.join(HERE, "fixtures")

# ---- canonical JSON (RFC 8785 JCS, no booleans in hash-bearing records) -------
_ESC = {'"': '\\"', "\\": "\\\\", "\b": "\\b", "\f": "\\f",
        "\n": "\\n", "\r": "\\r", "\t": "\\t"}


def _cstr(s):
    out = ['"']
    for ch in s:
        if ch in _ESC:
            out.append(_ESC[ch])
        elif ord(ch) < 0x20:
            out.append("\\u%04x" % ord(ch))
        else:
            out.append(ch)
    out.append('"')
    return "".join(out)


def canon(v):
    if v is None:
        return "null"
    if v is True or v is False:
        raise ValueError("boolean in hash-bearing record — forbidden (spec §1.6)")
    if isinstance(v, str):
        return _cstr(v)
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        raise ValueError("float in hash-bearing record — forbidden (spec §1.5)")
    if isinstance(v, list):
        return "[" + ",".join(canon(x) for x in v) + "]"
    if isinstance(v, dict):
        return "{" + ",".join(_cstr(k) + ":" + canon(v[k]) for k in sorted(v)) + "}"
    raise TypeError(f"unserializable {type(v)}")


US = "\x1f"


def cid(domain, body):
    return hashlib.sha256((domain + US).encode() + canon(body).encode()).hexdigest()


def sig_over(secret, context, obj_without_sig):
    msg = (context + US).encode() + canon(obj_without_sig).encode()
    return cx.b64u(cx.sign(secret, msg))


# ---- merkle profile lawmax-merkle-sha256-v1 (RFC 9162) ------------------------
PREFIX = "sha256:"


def _h(dom, data):
    return PREFIX + hashlib.sha256(dom + data).hexdigest()


def leaf(data_bytes):
    return _h(b"\x00", data_bytes)


def _node(a, b):
    return _h(b"\x01", bytes.fromhex(a[len(PREFIX):]) + bytes.fromhex(b[len(PREFIX):]))


def _lpow2(n):
    k = 1
    while k * 2 < n:
        k *= 2
    return k


def mth(leaves):
    if len(leaves) == 0:
        return PREFIX + hashlib.sha256(b"").hexdigest()
    if len(leaves) == 1:
        return leaves[0]
    k = _lpow2(len(leaves))
    return _node(mth(leaves[:k]), mth(leaves[k:]))


def inclusion_path(m, lo, hi, leaves):
    n = hi - lo
    if n == 1:
        return []
    k = _lpow2(n)
    if m < k:
        return inclusion_path(m, lo, lo + k, leaves) + [{"side": "right", "hash": mth(leaves[lo + k:hi])}]
    return inclusion_path(m - k, lo + k, hi, leaves) + [{"side": "left", "hash": mth(leaves[lo:lo + k])}]


def digest_of(obj):
    return PREFIX + hashlib.sha256(canon(obj).encode()).hexdigest()


def sha256_file(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()


def build_profile(schemas_path, **ov):
    schemas = json.load(open(schemas_path, encoding="utf-8"))
    body = {"mltp": "3", "layer": "MLTPProfileManifest",
            "profile_id": ov.get("profile_id", "mltp3-executable-reference/1"),
            "schemas_sha256": ov.get("schemas_sha256", sha256_file(schemas_path)),
            "canonicalization_profile": "rfc8785-jcs-no-bool/1",
            "signature_contexts_digest": hashlib.sha256(canon(sorted(schemas["sig_contexts"])).encode()).hexdigest(),
            "id_domains_digest": hashlib.sha256(canon(schemas["id_domains"]).encode()).hexdigest(),
            "merkle_profile": "lawmax-merkle-sha256-v1",
            "error_taxonomy_version": ov.get("error_taxonomy_version", "1"),
            "qualification_policy_version": "1",
            "min_verifier_version": ov.get("min_verifier_version", "1"),
            "activation": 1700000000, "expiry": 1900000000, "revoked": ov.get("revoked", "false"),
            "owner_kid": kid("owner_root")}
    signer = ov.get("sign_role", "owner_root")
    body["sig"] = sign_as(signer, "mltp3:profile-manifest", body)
    return body


# ---- keys (deterministic seeds) -----------------------------------------------
def seed(n):
    return bytes([n]) * 32


ROLES = {
    "owner_root":       {"seed": 0x01},
    "delegate_release": {"seed": 0x02, "scopes": ["release-signing",
                                                  "issued-claim:source-authenticity",
                                                  "issued-claim:legal-state",
                                                  "issued-claim:coverage-and-freshness",
                                                  "issued-claim:judgment-identity-and-text"]},
    "delegate_certified": {"seed": 0x03, "scopes": ["certified-result"]},
    "tsa":            {"seed": 0x04, "registry": "tsa"},
    "witness1":       {"seed": 0x05, "registry": "witness"},
    "witness2":       {"seed": 0x06, "registry": "witness"},
    "auditor1":       {"seed": 0x07, "registry": "auditor"},
    "auditor2":       {"seed": 0x08, "registry": "auditor"},
    "provider1":      {"seed": 0x09, "registry": "provider"},
    "compilerA":      {"seed": 0x0a, "scopes": ["compiler-attestation"]},
    "compilerB":      {"seed": 0x0b, "scopes": ["compiler-attestation"]},
    "reviewer1":      {"seed": 0x0c, "registry": "reviewer"},
}

KEYS = {}      # role -> {pub, secret, kid, x}
for role, meta in ROLES.items():
    pub, sec = cx.keypair_from_seed(seed(meta["seed"]))
    KEYS[role] = {"pub": pub, "secret": sec, "kid": cx.ed25519_thumbprint(pub), "x": cx.b64u(pub)}


def kid(role):
    return KEYS[role]["kid"]


def sign_as(role, context, obj):
    return sig_over(KEYS[role]["secret"], context, obj)


# ---- times --------------------------------------------------------------------
T_NOT_BEFORE = 1740000000
T_NOT_AFTER = 1760000000
T_GEN = 1749990000        # signature timestamp evidence
T_ACC = 5                 # accuracy seconds
T_NOW = 1750000000        # consumer trusted now
T_CHECKPOINT = 1749999000
MAX_REVOCATION_STALENESS = 86400


def build(opts=None):
    opts = opts or {}
    treatment_verb = opts.get("treatment_verb", "cites")
    treatment_adopted = opts.get("treatment_adopted", False)
    include_coverage = opts.get("include_coverage", True)
    fabricate_compiler = opts.get("fabricate_compiler", False)
    artifacts = {"time_attestations": [], "inclusion_proofs": []}

    # ---- Layer 0: delegations (owner-root-signed) -----------------------------
    delegations = []
    for role in ("delegate_release", "delegate_certified", "compilerA", "compilerB"):
        body = {"mltp": "3", "layer0": "DelegationStatement",
                "delegate_kid": kid(role), "delegate_x": KEYS[role]["x"],
                "scopes": sorted(ROLES[role]["scopes"]),
                "not_before": T_NOT_BEFORE, "not_after": T_NOT_AFTER,
                "seq": 1 + list(("delegate_release", "delegate_certified", "compilerA", "compilerB")).index(role),
                "owner_kid": kid("owner_root")}
        body["sig"] = sign_as("owner_root", "mltp3:delegation", body)
        delegations.append(body)

    # ---- Layer 0: a revocation statement for an UNUSED key (positive stays VERIFIED)
    unused_pub, _ = cx.keypair_from_seed(seed(0xFE))
    unused_kid = cx.ed25519_thumbprint(unused_pub)
    revstmt = {"mltp": "3", "layer0": "RevocationStatement",
               "revoked_subject": unused_kid, "invalid_from": 1745000000,
               "reason": "test-rotation", "owner_kid": kid("owner_root")}
    revstmt["sig"] = sign_as("owner_root", "mltp3:revocation", revstmt)
    revstmt_id = "rev1:" + cid("mltp3:revocation-id", {k: revstmt[k] for k in revstmt if k != "sig"})

    # ---- Claims (ClaimBody -> claim_id -> SignedClaim -> detached TimeAttestation)
    def build_claim(role, claim_type, payload, proof_material):
        schema_id = "mltp3/" + claim_type + "/1"
        body = {"mltp": "3", "claim_type": claim_type, "schema_id": schema_id,
                "payload": payload, "proof_material": proof_material}
        claim_id = "clm1:" + cid("mltp3:claim-id", body)
        signed = dict(body)
        signed["claim_id"] = claim_id
        signed["signer"] = {"alg": "Ed25519", "kid": kid(role), "delegation_seq": 1}
        raw_sig = cx.sign(KEYS[role]["secret"],
                          ("mltp3:issued-claim" + US).encode() + canon(signed).encode())
        signed["signature"] = {"alg": "Ed25519", "kid": kid(role),
                               "delegation_seq": signed["signer"]["delegation_seq"],
                               "sig": cx.b64u(raw_sig)}
        # detached time attestation over the signature bytes
        ta = {"mltp": "3", "layer": "TimeAttestation", "attests_context": "mltp3:issued-claim",
              "target_id": claim_id, "target_sig_imprint": PREFIX + hashlib.sha256(raw_sig).hexdigest(),
              "gen_time": T_GEN, "accuracy_seconds": T_ACC, "tsa_kid": kid("tsa")}
        ta["sig"] = sign_as("tsa", "mltp3:time-attestation", ta)
        artifacts["time_attestations"].append(ta)
        return claim_id, signed

    legal_timeline = {"issued_at": 1704067200, "published_at": 1704067200,
                      "effective_from": 1704067200, "effective_to": None,
                      "ceased_by": None, "cessation_type": None}

    src_id, src_claim = build_claim(
        "delegate_release", "source-authenticity",
        {"work_id": "gr/syntagma", "expression_id": "gr/syntagma@1975",
         "manifestation_id": "lsm1:demo-manifestation", "legal_timeline": legal_timeline},
        {"institutional_register_id": "ireg1:national-printing-office",
         "authority_proof_ref": "aprf2:grade-s2-demo", "authority_grade": "S2",
         "acquisition_receipt_id": "acq1:demo", "text_hash": "sha256:demo-item-bytes"})

    state_id, state_claim = build_claim(
        "delegate_release", "legal-state",
        {"work_id": "gr/syntagma", "provision": "gr/syntagma#art:4",
         "valid_at": 1704067200, "state": "IN", "legal_timeline": legal_timeline},
        {"source_authenticity_ref": src_id, "derivation_proof": "proof:demo-debruijn"})

    cov_id, cov_claim = build_claim(
        "delegate_release", "coverage-and-freshness",
        {"corpus": "gr/syntagma", "known_time": T_GEN, "positions_total": 120,
         "positions_covered": 120, "coverage_ledger_root": "sha256:demo-ledger"},
        {"universe_declaration_ref": "rsnap:census-universe-demo"})

    # judgment with a parser-certifiable relation ("cites") — correction #15
    jud_id, jud_claim = build_claim(
        "delegate_release", "judgment-identity-and-text",
        {"work_id": "gr/court/areios-pagos/2020/1", "ecli": "ECLI:GR:AP:2020:1",
         "anonymisation": "applied", "legal_timeline": legal_timeline},
        {"text_hash": "sha256:demo-judgment-item",
         "legal_relations": [dict({"verb": treatment_verb, "target": "gr/syntagma#art:4",
                              "passage_anchor": "para-12", "evidence": "explicit-citation"},
                              **({"reviewer_adoption": "reviewer1"} if treatment_adopted else {}))]})

    if include_coverage:
        claims = [src_claim, state_claim, cov_claim, jud_claim]
        claim_ids = sorted([src_id, state_id, cov_id, jud_id])
    else:
        claims = [src_claim, state_claim, jud_claim]
        claim_ids = sorted([src_id, state_id, jud_id])

    # ---- Release: manifest -> release_root (merkle over sorted claim_ids) ------
    leaves = [leaf(c.encode("utf-8")) for c in claim_ids]
    release_root = mth(leaves)
    release_manifest = {"mltp": "3", "layer": "ReleaseManifest",
                        "release_generation": {"era": 2, "seq": 1},
                        "prev_release_root": None, "census_digest": "sha256:demo-census",
                        "claim_ids": claim_ids}
    release_attestation = {"mltp": "3", "layer": "ReleaseAttestation",
                           "release_root": release_root,
                           "release_generation": {"era": 2, "seq": 1},
                           "prev_release_root": None, "census_digest": "sha256:demo-census",
                           "signer": {"alg": "Ed25519", "kid": kid("delegate_release"), "delegation_seq": 1}}
    release_attestation["sig"] = sign_as("delegate_release", "mltp3:release-root", release_attestation)
    # detached time attestation for the release signature
    ra_rawsig = cx.sign(KEYS["delegate_release"]["secret"],
                        ("mltp3:release-root" + US).encode()
                        + canon({k: release_attestation[k] for k in release_attestation if k != "sig"}).encode())
    ra_ta = {"mltp": "3", "layer": "TimeAttestation", "attests_context": "mltp3:release-root",
             "target_id": release_root, "target_sig_imprint": PREFIX + hashlib.sha256(ra_rawsig).hexdigest(),
             "gen_time": T_GEN, "accuracy_seconds": T_ACC, "tsa_kid": kid("tsa")}
    ra_ta["sig"] = sign_as("tsa", "mltp3:time-attestation", ra_ta)
    artifacts["time_attestations"].append(ra_ta)

    # ---- detached inclusion proofs --------------------------------------------
    for i, c in enumerate(claim_ids):
        artifacts["inclusion_proofs"].append(
            {"claim_id": c, "release_root": release_root, "leaf": leaves[i],
             "path": inclusion_path(i, 0, len(claim_ids), leaves)})

    # ---- CertifiedResult (body -> result_id -> sig -> time att -> citation token)
    citation = {"official_source_uri": "https://et.gr/fek/A-111-1975",
                "watchtower_release_uri": "https://watchtower.gr/release/" + release_root + "/claim/" + state_id,
                "claim_id": state_id,
                "certificate_uri": "https://watchtower.gr/bundle/<bundle_id-resolved-at-delivery>",
                "attribution_text": ("Ελληνική Δημοκρατία, Σύνταγμα 1975, ΦΕΚ Α΄111. "
                                     "Επαληθευμένη μηχανική αναπαράσταση, ενοποίηση, απόδειξη και πιστοποίηση: "
                                     "LAWMAX OMEGA — THE LEGAL WATCHTOWER OF GREECE, release 1, claim " + state_id),
                "citation_policy_id": "lawmax/citation-policy/1"}
    citation_digest = PREFIX + hashlib.sha256(canon(citation).encode()).hexdigest()
    answer = {"query": {"work_id": "gr/syntagma", "provision": "gr/syntagma#art:4",
                        "valid_at": 1704067200, "known_at": T_GEN},
              "result_state": "IN", "release_root": release_root,
              "dependency_set": sorted([state_id, src_id]),
              "applied_legal_events": [], "coverage_ref": cov_id,
              "official_source_chain": [src_id],
              "derivation_proof": "proof:demo-answer", "counterproof": {"open_objections": []},
              "legal_timeline": legal_timeline}
    cr_body = {"mltp": "3", "layer": "CertifiedResultBody", "answer": answer,
               "citation": citation, "citation_digest": citation_digest,
               "release_ref": {"release_root": release_root, "release_generation": {"era": 2, "seq": 1}}}
    result_id = "res1:" + cid("mltp3:result-id", cr_body)
    cr = dict(cr_body)
    cr["result_id"] = result_id
    cr["signer"] = {"alg": "Ed25519", "kid": kid("delegate_certified"), "delegation_seq": 2}
    cr_rawsig = cx.sign(KEYS["delegate_certified"]["secret"],
                        ("mltp3:certified-result" + US).encode() + canon(cr).encode())
    cr["signature"] = {"alg": "Ed25519", "kid": kid("delegate_certified"),
                       "delegation_seq": 2, "sig": cx.b64u(cr_rawsig)}
    cr_ta = {"mltp": "3", "layer": "TimeAttestation", "attests_context": "mltp3:certified-result",
             "target_id": result_id, "target_sig_imprint": PREFIX + hashlib.sha256(cr_rawsig).hexdigest(),
             "gen_time": T_GEN, "accuracy_seconds": T_ACC, "tsa_kid": kid("tsa")}
    cr_ta["sig"] = sign_as("tsa", "mltp3:time-attestation", cr_ta)
    artifacts["time_attestations"].append(cr_ta)
    citation_token = {"mltp": "3", "layer": "CitationToken", "citation": citation,
                      "result_id": result_id,
                      "signer": {"alg": "Ed25519", "kid": kid("delegate_certified"), "delegation_seq": 2}}
    citation_token["sig"] = sign_as("delegate_certified", "mltp3:citation",
                                    {"citation": citation, "result_id": result_id})

    # ---- compiler attestations (correction #12) -------------------------------
    input_journal_root = "sha256:demo-journal-root"
    output_root = "sha256:demo-legal-state-root"
    comp_a = {"mltp": "3", "layer": "CompilerAttestation", "compiler_family_id": "lisp-sbcl",
              "source_digest": "sha256:compilerA-src", "toolchain_manifest_digest": "sha256:compilerA-tc",
              "runtime": "SBCL", "input_journal_root": input_journal_root, "output_root": output_root,
              "signer": {"alg": "Ed25519", "kid": kid("compilerA"), "delegation_seq": 3}}
    comp_a["sig"] = sign_as("compilerA", "mltp3:compiler-attestation", comp_a)
    _fam_b = "lisp-sbcl" if fabricate_compiler else "rust"
    _src_b = "sha256:compilerA-src" if fabricate_compiler else "sha256:compilerB-src"
    comp_b = {"mltp": "3", "layer": "CompilerAttestation", "compiler_family_id": _fam_b,
              "source_digest": _src_b, "toolchain_manifest_digest": "sha256:compilerB-tc",
              "runtime": "rustc", "input_journal_root": input_journal_root, "output_root": output_root,
              "signer": {"alg": "Ed25519", "kid": kid("compilerB"), "delegation_seq": 4}}
    comp_b["sig"] = sign_as("compilerB", "mltp3:compiler-attestation", comp_b)

    # ---- provider conformance record (correction #9) --------------------------
    provider_conformance = {"mltp": "3", "layer": "ProviderConformanceRecord",
                            "provider_id": "provider:demo-1", "provider_kid": kid("provider1"),
                            "policy_version": "lawmax/citation-policy/1",
                            "evidence_window": {"from": 1749000000, "to": T_NOW},
                            "expiry": 1760000000}
    provider_conformance["sig"] = sign_as("provider1", "mltp3:provider-conformance", provider_conformance)

    # ---- QSR (mechanism-only, NON-qualifying level) ---------------------------
    qsr_body = {"mltp": "3", "record": "QualificationStateRecord",
                "subject": {"kind": "release", "release_root": release_root, "claim_id": None},
                "level": "reference-fixture-nonqualifying",
                "evidence_refs": ["V1.4-CONTRADICTION-OMISSION-AUDIT.out"],
                "expiry": 1760000000}
    qsr_id = "qsr1:" + cid("mltp3:qsr-id", qsr_body)
    qsr = dict(qsr_body)
    qsr["record_id"] = qsr_id
    qsr["signers"] = []
    for r in ("auditor1", "auditor2"):
        s = {"alg": "Ed25519", "kid": kid(r),
             "sig": sign_as(r, "mltp3:qual-state", {**qsr_body, "record_id": qsr_id})}
        qsr["signers"].append(s)

    # ---- revocation checkpoint (correction #5) --------------------------------
    rev_leaves = [leaf(revstmt_id.encode("utf-8"))]
    rev_log_root = mth(rev_leaves)
    checkpoint = {"mltp": "3", "layer": "RevocationCheckpoint",
                  "tree_size": 1, "log_root": rev_log_root, "checkpoint_at": T_CHECKPOINT,
                  "consistency_from": None, "consistency_proof": [],
                  "revocations": [{"statement_id": revstmt_id, "revoked_subject": unused_kid,
                                   "inclusion": {"leaf": rev_leaves[0], "path": inclusion_path(0, 0, 1, rev_leaves)}}]}
    checkpoint["signers"] = []
    for r in ("witness1", "witness2"):
        s = {"alg": "Ed25519", "kid": kid(r),
             "sig": sign_as(r, "mltp3:witness-checkpoint",
                            {k: checkpoint[k] for k in checkpoint if k != "signers"})}
        checkpoint["signers"].append(s)

    # ---- BundleManifest -> bundle_id (manifest EXCLUDES bundle_id) ------------
    manifest = {
        "mltp": "3", "layer": "BundleManifest", "release_profile": "era-2",
        "release_anchor": {"release_root": release_root, "release_generation": {"era": 2, "seq": 1},
                           "release_attestation_digest": digest_of(release_attestation), "prev_release_root": None},
        "claims": [{"claim_id": c["claim_id"], "digest": digest_of(c)} for c in claims],
        "time_attestations": [digest_of(t) for t in artifacts["time_attestations"]],
        "inclusion_proofs": [digest_of(p) for p in artifacts["inclusion_proofs"]],
        "certified_results": [{"result_id": result_id, "digest": digest_of(cr)}],
        "citation_tokens": [digest_of(citation_token)],
        "delegations": [digest_of(d) for d in delegations],
        "revocation_statements": [digest_of(revstmt)],
        "revocation_checkpoint_digest": digest_of(checkpoint),
        "qualification_records": [{"record_id": qsr_id, "digest": digest_of(qsr)}],
        "compiler_attestations": [digest_of(comp_a), digest_of(comp_b)],
        "provider_conformance": [digest_of(provider_conformance)],
    }
    bundle_id = "bnd1:" + cid("mltp3:bundle-id", manifest)

    bundle = {"mltp": "3", "layer": "TrustBundle", "bundle_id": bundle_id, "manifest": manifest,
              "owner_kid": kid("owner_root"),
              "keys": [{"kid": KEYS[r]["kid"], "x": KEYS[r]["x"], "alg": "Ed25519"} for r in ROLES],
              "delegations": delegations, "revocation_statements": [revstmt],
              "release_attestation": release_attestation,
              "issued_claims": claims, "time_attestations": artifacts["time_attestations"],
              "inclusion_proofs": artifacts["inclusion_proofs"],
              "certified_results": [cr], "citation_tokens": [citation_token],
              "revocation_checkpoint": checkpoint,
              "qualification_records": [qsr], "compiler_attestations": [comp_a, comp_b],
              "provider_conformance": [provider_conformance]}

    # ---- LocalTrustState (what the consumer brings) ---------------------------
    lts = {"schema": "mltp3-lts/1", "owner_root": {"kid": kid("owner_root"), "x": KEYS["owner_root"]["x"]},
           "trusted_now": T_NOW, "max_revocation_staleness_seconds": MAX_REVOCATION_STALENESS,
           "registries": {reg: sorted([KEYS[r]["kid"] for r, m in ROLES.items() if m.get("registry") == reg])
                          for reg in ("tsa", "witness", "auditor", "provider", "reviewer")},
           "trusted_citation_policies": ["lawmax/citation-policy/1"],
           "last_revocation_checkpoint": {"tree_size": 0, "log_root": mth([])}}
    profile = build_profile(os.path.join(HERE, "schemas.json"))

    keys_pub = {"schema": "mltp3-keys/1",
                "keys": {r: {"kid": KEYS[r]["kid"], "x": KEYS[r]["x"],
                             "scopes": ROLES[r].get("scopes"), "registry": ROLES[r].get("registry")}
                         for r in ROLES}}

    expected = {"schema": "mltp3-expected/1", "case": "positive",
                "result": "VERIFIED", "reason": "ok",
                "certified_results": [{"result_id": result_id, "result": "VERIFIED", "citation_bound": "true"}]}

    return {"bundle": bundle, "lts": lts, "keys": keys_pub, "expected": expected, "profile": profile,
            "bundle_id": bundle_id, "release_root": release_root, "n_claims": len(claims)}


def main():
    os.makedirs(FIX, exist_ok=True)
    out = build()
    for name in ("keys", "bundle", "lts", "expected", "profile"):
        with open(os.path.join(FIX, name + ".json"), "w", encoding="utf-8") as fh:
            fh.write(json.dumps(out[name], ensure_ascii=False, sort_keys=True, separators=(",", ":")))
            fh.write("\n")
    print("build_fixtures: OK  bundle_id=%s  release_root=%s  claims=%d  backend=%s"
          % (out["bundle_id"], out["release_root"], out["n_claims"], cx.backend_id()))


if __name__ == "__main__":
    main()
