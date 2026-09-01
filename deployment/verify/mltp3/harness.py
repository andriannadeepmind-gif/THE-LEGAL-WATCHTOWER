#!/usr/bin/env python3
"""harness.py — one-command acceptance runner for the MLTP v3 executable reference.

From a clean checkout: cross-checks the vetted crypto backends against RFC 8032,
builds the fixtures twice (determinism), runs the DAG/self-id check, generates the
mutation matrix, and runs BOTH independent verifiers (Go / Node) over the positive
bundle plus every mutation — requiring both to agree with each other and with the
expected typed result. Emits fixtures/REPORT.json and exits 0 iff every acceptance
criterion holds. Fail-closed everywhere.
"""
import hashlib
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
FIX = os.path.join(HERE, "fixtures")


def sh(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, cwd=HERE, **kw)


def sha256_file(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()


def tool_versions():
    v = {}
    v["python"] = sys.version.split()[0]
    v["go"] = sh(["go", "version"]).stdout.strip()
    v["node"] = sh(["node", "--version"]).stdout.strip()
    v["node_openssl"] = sh(["node", "-e", "process.stdout.write(process.versions.openssl)"]).stdout.strip()
    try:
        import crypto_libsodium as cx
        v["libsodium"] = cx.backend_info()
    except Exception as e:
        v["libsodium"] = "UNAVAILABLE: %s" % e
    return v


RFC_GO = r'''
package main
import ("crypto/ed25519";"encoding/hex";"fmt")
func main(){
 seed,_:=hex.DecodeString("4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb")
 pk,_:=hex.DecodeString("3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c")
 msg,_:=hex.DecodeString("72"); sig,_:=hex.DecodeString("92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00")
 priv:=ed25519.NewKeyFromSeed(seed); der:=priv.Public().(ed25519.PublicKey)
 fmt.Print(hex.EncodeToString(der)==hex.EncodeToString(pk) && ed25519.Verify(pk,msg,sig))
}'''

RFC_NODE = r'''
const c=require("crypto");
const pk=Buffer.from("3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c","hex");
const spki=Buffer.concat([Buffer.from("302a300506032b6570032100","hex"),pk]);
const pub=c.createPublicKey({key:spki,format:"der",type:"spki"});
const ok=c.verify(null,Buffer.from("72","hex"),pub,Buffer.from("92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00","hex"));
process.stdout.write(String(ok));'''


def rfc_crosscheck():
    out = {}
    # libsodium (Python)
    r = sh(["python3", "crypto_libsodium.py"])
    out["libsodium"] = r.returncode == 0 and "RFC 8032 TEST 2 OK" in r.stdout
    # go
    with tempfile.TemporaryDirectory() as d:
        gp = os.path.join(d, "rfc.go")
        open(gp, "w").write(RFC_GO)
        r = sh(["go", "run", gp], env={**os.environ, "GO111MODULE": "off"})
        out["go"] = r.stdout.strip() == "true"
    # node
    r = sh(["node", "-e", RFC_NODE])
    out["node"] = r.stdout.strip() == "true"
    out["all_ok"] = all(out.values())
    return out


def build_once():
    r = sh(["python3", "build_fixtures.py"])
    if r.returncode != 0:
        print(r.stderr, file=sys.stderr)
        raise SystemExit("build failed")


def determinism():
    build_once()
    d1 = {f: sha256_file(os.path.join(FIX, f)) for f in ("bundle.json", "keys.json", "lts.json", "expected.json")}
    build_once()
    d2 = {f: sha256_file(os.path.join(FIX, f)) for f in ("bundle.json", "keys.json", "lts.json", "expected.json")}
    return {"ok": d1 == d2, "digests": d2}


def run_verifier(prog_args, bundle, lts, schemas=None, profile=None):
    schemas = schemas or os.path.join(HERE, "schemas.json")
    profile = profile or os.path.join(FIX, "profile.json")
    r = sh(prog_args + [bundle, lts, os.path.join(FIX, "keys.json"), schemas, profile])
    if r.returncode != 0 and not r.stdout.strip():
        return {"result": "CRYPTO_BACKEND_UNAVAILABLE", "reason": "verifier-error", "stderr": r.stderr[-400:]}
    try:
        return json.loads(r.stdout.strip().splitlines()[-1])
    except Exception:
        return {"result": "PARSE_ERROR", "reason": r.stdout[-200:] + " ERR " + r.stderr[-200:]}


A_CMD = ["go", "run", os.path.join(HERE, "verify_a.go")]
B_CMD = ["node", os.path.join(HERE, "verify_b.mjs")]


def run_case(bundle, lts, schemas=None, profile=None):
    a = run_verifier(A_CMD, bundle, lts, schemas, profile)
    b = run_verifier(B_CMD, bundle, lts, schemas, profile)
    return a, b


def main():
    report = {"schema": "mltp3-acceptance-report/1",
              "generated_from": "clean build of deployment/verify/mltp3",
              "backends": {"verifier_a": "Go stdlib crypto/ed25519 (pure Go, not OpenSSL)",
                           "verifier_b": "Node node:crypto (OpenSSL)",
                           "builder": "libsodium via ctypes"},
              "independence_claim": "Go and Node are two independent N-version IMPLEMENTATIONS from one specification, same engineering session — NOT an independent organizational audit. Independent implementation and independent adjudication are different claims (C1.6).",
              "tool_versions": tool_versions()}

    report["rfc8032_crosscheck"] = rfc_crosscheck()
    report["determinism"] = determinism()

    dag = sh(["python3", "dag_check.py"])
    report["dag"] = {"ok": dag.returncode == 0, "detail": json.loads(dag.stdout.strip()) if dag.stdout.strip() else None}

    # C1.4 standards-interoperability vectors (vetted, no hand-rolled crypto)
    rfc = sh(["bash", os.path.join(HERE, "interop", "rfc3161", "verify.sh")])
    cose = sh(["bash", os.path.join(HERE, "interop", "cose", "verify.sh")])
    report["interop"] = {
        "rfc3161": {"ok": rfc.returncode == 0, "impl": "OpenSSL ts", "detail": rfc.stdout.strip().splitlines()[-1] if rfc.stdout.strip() else rfc.stderr[-200:]},
        "cose": {"ok": cose.returncode == 0, "impl": "veraison/go-cose v1.3.0 (vendored)", "detail": cose.stdout.strip().splitlines()[-1] if cose.stdout.strip() else cose.stderr[-200:]},
        "note": "TimeAttestation in the core reference is a deterministic test double, NOT an RFC-3161 TSR; the real TSR is interop/rfc3161/token.tsr. MLTP canonical-JSON signatures and COSE_Sign1 are distinct constructions."}

    mut = sh(["python3", "mutate.py"])
    if mut.returncode != 0:
        raise SystemExit("mutate failed: " + mut.stderr)

    # positive
    a, b = run_case(os.path.join(FIX, "bundle.json"), os.path.join(FIX, "lts.json"))
    pos_ok = (a.get("result") == "VERIFIED" and b.get("result") == "VERIFIED"
              and a.get("reason") == "ok" and b.get("reason") == "ok")
    report["positive"] = {"ok": pos_ok, "verifier_a": a, "verifier_b": b}

    # negatives
    muts = json.load(open(os.path.join(FIX, "mutations.json")))["mutations"]
    neg = []
    neg_ok = 0
    for m in muts:
        d = os.path.join(FIX, "mut", m["name"])
        sc = os.path.join(d, "schemas.json"); sc = sc if os.path.exists(sc) else None
        pf = os.path.join(d, "profile.json"); pf = pf if os.path.exists(pf) else None
        a, b = run_case(os.path.join(d, "bundle.json"), os.path.join(d, "lts.json"), sc, pf)
        agree = (a.get("result") == b.get("result") and a.get("reason") == b.get("reason"))
        res_ok = a.get("result") == m["expected_result"]
        rea_ok = a.get("reason") in m["expected_reasons"]
        ok = agree and res_ok and rea_ok
        if ok:
            neg_ok += 1
        neg.append({"name": m["name"], "kw": m["kw"], "expected_result": m["expected_result"],
                    "expected_reasons": m["expected_reasons"],
                    "a": {"result": a.get("result"), "reason": a.get("reason")},
                    "b": {"result": b.get("result"), "reason": b.get("reason")},
                    "agree": agree, "ok": ok})
    report["negatives"] = neg
    report["totals"] = {"positive": 1 if pos_ok else 0, "negatives_total": len(muts), "negatives_passed": neg_ok}

    report["artifact_digests"] = {
        f: sha256_file(os.path.join(HERE, f)) for f in
        ("schemas.json", "build_fixtures.py", "crypto_libsodium.py", "verify_a.go", "verify_b.mjs",
         "mutate.py", "dag_check.py", "harness.py")}
    report["artifact_digests"]["fixtures/bundle.json"] = sha256_file(os.path.join(FIX, "bundle.json"))

    passed = (report["rfc8032_crosscheck"]["all_ok"] and report["determinism"]["ok"]
              and report["dag"]["ok"] and pos_ok and neg_ok == len(muts)
              and report["interop"]["rfc3161"]["ok"] and report["interop"]["cose"]["ok"])
    report["verdict"] = "EXECUTABLE PROTOCOL CLOSURE PASSED — NOT YET SPEC QUALIFIED" if passed \
        else "EXECUTABLE PROTOCOL CLOSURE BLOCKED — NO QUALIFICATION CLAIM"

    with open(os.path.join(FIX, "REPORT.json"), "w", encoding="utf-8") as fh:
        json.dump(report, fh, ensure_ascii=False, indent=1)
        fh.write("\n")

    print("rfc8032 crosscheck :", report["rfc8032_crosscheck"])
    print("determinism        :", report["determinism"]["ok"])
    print("dag/self-id        :", report["dag"]["ok"])
    print("positive           :", pos_ok)
    print("negatives          : %d/%d rejected identically by A and B with expected typed error"
          % (neg_ok, len(muts)))
    print("interop rfc3161    :", report["interop"]["rfc3161"]["ok"])
    print("interop cose       :", report["interop"]["cose"]["ok"])
    print("VERDICT            :", report["verdict"])
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
