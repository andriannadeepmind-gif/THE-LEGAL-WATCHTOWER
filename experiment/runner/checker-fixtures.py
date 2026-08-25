#!/usr/bin/env python3
"""ADVERSARIAL FALSE-OPEN FIXTURES — executable αρνητικοί μάρτυρες του checker.

Κάθε fixture στήνει ΠΛΗΡΕΣ sandbox repo (git commit-bound) που αναπαράγει μια
επίθεση, και βεβαιώνει ότι η πύλη μένει ΚΛΕΙΣΤΗ. Το F0 είναι ΑΚΡΙΒΩΣ το
σενάριο που άνοιγε ψευδώς τον προηγούμενο checker.
"""
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile

REPO = "/home/user/THE-LEGAL-WATCHTOWER"
CHK = f"{REPO}/experiment/runner/constitution-checker-v2.REV3.DRAFT.py"
V1_SEAL = "5b3ab5bf9561d535adbf5049b975ac2ab8e9a63db32dfb14a07d82d78b729be6"
PASS = FAIL = 0


def ok(m):
    global PASS; PASS += 1; print(f"  ✓ {m}")


def bad(m):
    global FAIL; FAIL += 1; print(f"  ✗ {m}")


def sha_f(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()


def build_sandbox(mutate):
    """Αντιγράφει τα ΠΡΑΓΜΑΤΙΚΑ REV3 artifacts, εφαρμόζει τη μετάλλαξη,
    κάνει git commit ώστε ο checker να έχει commit-bound snapshot."""
    d = tempfile.mkdtemp(prefix="chk-fix-")
    os.makedirs(f"{d}/experiment/runner", exist_ok=True)
    for rel in ["experiment/OBJECTIVE-CONSTITUTION.json",
                "experiment/OBJECTIVE-CONSTITUTION.v2.REV3.DRAFT.json",
                "experiment/CONSTITUTION-AMENDMENT-1.REV3.DRAFT.json",
                "experiment/OBJECTIVE-EPOCH-1.REV3.DRAFT.json",
                "experiment/LIFECYCLE-RECORD.json"]:
        shutil.copy(f"{REPO}/{rel}", f"{d}/{rel}") if os.path.exists(f"{REPO}/{rel}") \
            else None
    mutate(d)
    def rebind(d):
        # ξαναδέσε την αλυσίδα ΠΑΝΩ στα μεταλλαγμένα bytes — η επίθεση είναι
        # συνεπής στο επίπεδο hash· ΠΡΕΠΕΙ να πέσει στη ΣΗΜΑΣΙΟΛΟΓΙΑ
        v2p = f"{d}/experiment/OBJECTIVE-CONSTITUTION.v2.REV3.DRAFT.json"
        v2sha = sha_f(v2p)
        for rel, key in [("experiment/CONSTITUTION-AMENDMENT-1.REV3.DRAFT.json",
                          ("to_version", "sha256")),
                         ("experiment/OBJECTIVE-EPOCH-1.REV3.DRAFT.json",
                          ("bound_to_constitution", "sha256"))]:
            p = f"{d}/{rel}"
            j = json.load(open(p, encoding="utf-8"))
            j[key[0]][key[1]] = v2sha
            json.dump(j, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    rebind(d)
    subprocess.run(["git", "-C", d, "init", "-q"], check=True)
    subprocess.run(["git", "-C", d, "add", "-A"], check=True)
    subprocess.run(["git", "-C", d, "-c", "user.name=f", "-c", "user.email=f@f",
                    "commit", "-q", "-m", "fixture"], check=True)
    return d


def run_checker(d, mode):
    r = subprocess.run([sys.executable, CHK, "--mode", mode, "--root", d],
                       capture_output=True, text=True)
    return r.returncode, r.stdout


def main():
    print("ADVERSARIAL FALSE-OPEN FIXTURES")
    print("═" * 60)

    # ── F0: ΤΟ ΑΚΡΙΒΕΣ ΣΕΝΑΡΙΟ ΤΟΥ ΑΠΟΔΕΔΕΙΓΜΕΝΟΥ FALSE-OPEN ─────────
    def f0(d):
        p = f"{d}/experiment/OBJECTIVE-EPOCH-1.REV3.DRAFT.json"
        ep = json.load(open(p, encoding="utf-8"))
        for k in ep["precommit_pre_phi2A"]["inputs"]:
            ep["precommit_pre_phi2A"]["inputs"][k] = {"status": "SEALED"}   # ΧΩΡΙΣ τιμές
        json.dump(ep, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        v2sha = sha_f(f"{d}/experiment/OBJECTIVE-CONSTITUTION.v2.REV3.DRAFT.json")
        at = {"v1_sha256": V1_SEAL, "v2_sha256": v2sha,
              "approved_by_creator": True,
              "padding": "x" * 2000}                                       # PADDED
        json.dump(at, open(f"{d}/experiment/RATIFICATION-ATTESTATION.json", "w"),
                  ensure_ascii=False, indent=1)
    d = build_sandbox(f0)
    for mode in ("preflight", "active"):
        rc, out = run_checker(d, mode)
        (ok if rc != 0 else bad)(
            f"F0/{mode}: SEALED-χωρίς-τιμές + padded attestation ⇒ "
            f"{'ΚΛΕΙΣΤΗ (exit '+str(rc)+')' if rc != 0 else 'ΑΝΟΙΚΤΗ — FALSE OPEN!'}")
        if rc != 0 and mode == "preflight":
            for sig in ("CH-05-inputs", "CH-06-attestation"):
                (ok if f"✗ [UNMET  ] {sig}" in out else bad)(
                    f"F0: το {sig} απορρίφθηκε ΟΝΟΜΑΣΤΙΚΑ")
    shutil.rmtree(d, ignore_errors=True)

    # ── F1: μη κενό αλλά ΣΚΟΥΠΙΔΙ proof artifact ⇒ ΟΧΙ MET ─────────────
    def f1(d):
        os.makedirs(f"{d}/experiment/phase2", exist_ok=True)
        open(f"{d}/experiment/phase2/DOMAIN-CLOSURE-CERTIFICATE.json", "w").write(
            "x" * 900)                                     # 900 bytes σκουπίδι
    d = build_sandbox(f1)
    rc, out = run_checker(d, "draft-lint")
    (ok if "CH-10-domain-closure: experiment/phase2/DOMAIN-CLOSURE-CERTIFICATE.json: "
           "κενό/τετριμμένο/μη-JSON — ΑΠΟΡΡΙΠΤΕΤΑΙ" in out.replace("✗ [UNMET  ] ", "")
     else bad)("F1: garbage .json proof ⇒ ΑΠΟΡΡΙΦΘΗΚΕ, όχι MET")
    shutil.rmtree(d, ignore_errors=True)

    # ── F2: έγκυρο JSON proof ΧΩΡΙΣ epoch binding ⇒ UNBOUND ────────────
    def f2(d):
        os.makedirs(f"{d}/experiment/phase2", exist_ok=True)
        json.dump({"claims": ["πλήρες"], "data": list(range(200))},
                  open(f"{d}/experiment/phase2/DOMAIN-CLOSURE-CERTIFICATE.json", "w"))
    d = build_sandbox(f2)
    rc, out = run_checker(d, "draft-lint")
    (ok if "UNBOUND" in out else bad)("F2: proof χωρίς epoch binding ⇒ UNBOUND/ΑΠΟΡΡΙΨΗ")
    shutil.rmtree(d, ignore_errors=True)

    # ── F3: δεμένο proof ΧΩΡΙΣ replay spec ⇒ ΑΠΟΡΡΙΨΗ ──────────────────
    def f3(d):
        os.makedirs(f"{d}/experiment/phase2", exist_ok=True)
        epsha = sha_f(f"{d}/experiment/OBJECTIVE-EPOCH-1.REV3.DRAFT.json")
        json.dump({"bound_epoch_sha256": epsha, "claims": ["x"] * 100},
                  open(f"{d}/experiment/phase2/DOMAIN-CLOSURE-CERTIFICATE.json", "w"))
    d = build_sandbox(f3)
    rc, out = run_checker(d, "draft-lint")
    (ok if "ΧΩΡΙΣ replay spec" in out else bad)("F3: proof χωρίς replay ⇒ ΑΠΟΡΡΙΨΗ")
    shutil.rmtree(d, ignore_errors=True)

    # ── F4: replay που ΔΕΝ αναπαράγει ⇒ ΑΠΟΡΡΙΨΗ ───────────────────────
    def f4(d):
        os.makedirs(f"{d}/experiment/phase2", exist_ok=True)
        # rebind τρέχει ΜΕΤΑ το mutate — υπολόγισε το epoch sha ΟΠΩΣ θα είναι
    d = build_sandbox(f4)
    epsha = sha_f(f"{d}/experiment/OBJECTIVE-EPOCH-1.REV3.DRAFT.json")
    json.dump({"bound_epoch_sha256": epsha, "claims": ["x"] * 100,
               "replay": {"cmd": ["echo", "όχι-αυτό"], "expect_sha256": "ab" * 32}},
              open(f"{d}/experiment/phase2/DOMAIN-CLOSURE-CERTIFICATE.json", "w"))
    subprocess.run(["git", "-C", d, "add", "-A"], check=True)
    subprocess.run(["git", "-C", d, "-c", "user.name=f", "-c", "user.email=f@f",
                    "commit", "-q", "-m", "f4"], check=True)
    rc, out = run_checker(d, "draft-lint")
    (ok if "REPLAY ΑΠΕΤΥΧΕ" in out else bad)("F4: replay που δεν αναπαράγει ⇒ ΑΠΟΡΡΙΨΗ")
    shutil.rmtree(d, ignore_errors=True)

    # ── F5: ΚΥΚΛΙΚΟ attestation (μέσα στο commit που δεσμεύει) ─────────
    def f5(d):
        pass
    d = build_sandbox(f5)
    v2sha = sha_f(f"{d}/experiment/OBJECTIVE-CONSTITUTION.v2.REV3.DRAFT.json")
    amsha = sha_f(f"{d}/experiment/CONSTITUTION-AMENDMENT-1.REV3.DRAFT.json")
    epsha = sha_f(f"{d}/experiment/OBJECTIVE-EPOCH-1.REV3.DRAFT.json")
    head = subprocess.run(["git", "-C", d, "rev-parse", "HEAD"],
                          capture_output=True, text=True).stdout.strip()
    at = {"v1_sha256": V1_SEAL, "v2_sha256": v2sha, "amendment_sha256": amsha,
          "epoch_sha256": epsha, "checker_sha256": "00" * 32,
          "construction_commit": head,
          "approved_by_creator": True,
          "approval_statement": "εγκρίνω ρητά το πακέτο v2 REV3 ως δημιουργός"}
    json.dump(at, open(f"{d}/experiment/RATIFICATION-ATTESTATION.json", "w"),
              ensure_ascii=False, indent=1)
    subprocess.run(["git", "-C", d, "add", "-A"], check=True)
    subprocess.run(["git", "-C", d, "-c", "user.name=f", "-c", "user.email=f@f",
                    "commit", "-q", "--amend", "-m", "cyclic"], check=True)
    # τώρα το attestation ζει ΜΕΣΑ στο commit που το construction_commit δείχνει
    rc, out = run_checker(d, "preflight")
    # ο κύκλος εκδηλώνεται είτε ως ρητός ΚΥΚΛΟΣ (attestation στο δέντρο του C)
    # είτε ως σπασμένο lineage (amend ⇒ ο C δεν είναι πλέον πρόγονος) —
    # ΚΑΙ ΟΙ ΔΥΟ μορφές πρέπει να κλείνουν την πύλη
    (ok if rc != 0 and ("ΚΥΚΛΟΣ" in out or "πρόγονος" in out or "ανύπαρκτο" in out)
     else bad)(f"F5: κυκλικό attestation ⇒ ΚΛΕΙΣΤΗ (exit {rc})")
    shutil.rmtree(d, ignore_errors=True)

    # ── F6: active mode ΔΕΝ επιστρέφει 0 χωρίς αποδείξεις ──────────────
    d = build_sandbox(lambda d: None)
    rc, out = run_checker(d, "active")
    (ok if rc != 0 else bad)(f"F6: active χωρίς proofs ⇒ exit {rc} ≠ 0 "
                             f"(κάθε NOT-YET = BLOCKING)")
    shutil.rmtree(d, ignore_errors=True)

    # ── F7: βρώμικο worktree ⇒ άρνηση ──────────────────────────────────
    d = build_sandbox(lambda d: None)
    open(f"{d}/dirt.txt", "w").write("dirt")
    rc, out = run_checker(d, "preflight")
    (ok if rc != 0 and "ΒΡΩΜΙΚΟ" in out else bad)("F7: βρώμικο worktree ⇒ άρνηση")
    shutil.rmtree(d, ignore_errors=True)

    print("═" * 60)
    print(f"FIXTURES: PASS={PASS} FAIL={FAIL}")
    if FAIL:
        print("::error::FALSE-OPEN ΔΥΝΑΤΟ — ο checker ΔΕΝ είναι αποδεκτός")
        return 1
    print("ALL-FALSE-OPEN-PATHS-CLOSED")
    return 0


sys.exit(main())
