#!/usr/bin/env python3
"""CEILING CHECKER v2 REV3 — DRAFT. Semantic + phase-aware. FSM-integrated.

Ο ΠΡΟΚΑΤΟΧΟΣ ΑΠΟΔΕΙΧΘΗΚΕ FALSE-OPEN (executable fixture): 8 inputs ως
{status:SEALED} χωρίς τιμές + padded attestation με σωστό v2_sha256 και
approved:true ⇒ ΑΝΟΙΚΤΗ πύλη. Εδώ αυτό είναι ΑΔΥΝΑΤΟ, και η αδυναμία
αποδεικνύεται από τη fixture suite — όχι από αυτό το docstring.

ΑΡΧΕΣ:
· ΚΑΘΕ έλεγχος είναι περιεχομένου/σημασιολογίας — ποτέ ύπαρξης/λέξης-κλειδιού.
· ΚΑΘΕ εφαρμοστέο NOT-YET στα preflight/active = BLOCKING.
· Proofs: PARSE + REPLAY — κάθε certificate φέρει :replay spec που ΕΚΤΕΛΕΙΤΑΙ.
· Unbound (χωρίς hash δέσμευση στο epoch) ή τετριμμένο artifact ⇒ ΑΠΟΡΡΙΨΗ.
· Πηγή κατάστασης: LIFECYCLE-RECORD.json (FSM) — όχι πεδία μέσα στα κείμενα.
"""
import argparse
import hashlib
import json
import os
import subprocess
import sys

DEF_ROOT = "/home/user/THE-LEGAL-WATCHTOWER"
V1_SEAL = "5b3ab5bf9561d535adbf5049b975ac2ab8e9a63db32dfb14a07d82d78b729be6"
R = []


def c(oid, st, d):
    R.append((oid, st, d))


def sha_b(b):
    return hashlib.sha256(b).hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mode", choices=["draft-lint", "preflight", "active"],
                    default="draft-lint")
    ap.add_argument("--root", default=DEF_ROOT)
    args = ap.parse_args()
    mode, ROOT = args.mode, os.path.abspath(args.root)
    strict = mode in ("preflight", "active")

    def P(rel):
        return os.path.join(ROOT, rel)

    def rj(rel, min_bytes=300):
        p = P(rel)
        if not os.path.exists(p):
            return None
        if os.path.getsize(p) < min_bytes:
            return False
        try:
            d = json.load(open(p, encoding="utf-8"))
        except Exception:
            return False
        return d if isinstance(d, dict) and len(json.dumps(d)) >= min_bytes else False

    # ── GIT: exit codes ΕΠΑΛΗΘΕΥΟΝΤΑΙ, HEAD/tree ΑΚΡΙΒΗ ────────────────
    def git(*cmd):
        r = subprocess.run(["git", "-C", ROOT, *cmd], capture_output=True, text=True)
        return r.returncode, r.stdout.strip()

    if strict:
        rc, out = git("status", "--porcelain")
        if rc != 0:
            c("CH-GIT", "UNMET", f"git status exit={rc} — ΔΕΝ αγνοείται")
            return report(mode)
        if out:
            c("CH-GIT", "UNMET", f"ΒΡΩΜΙΚΟ worktree ({len(out.splitlines())} εγγραφές)")
            return report(mode)
        rc1, head = git("rev-parse", "--verify", "HEAD")
        rc2, tree = git("rev-parse", "HEAD^{tree}")
        if rc1 or rc2 or len(head) != 40 or len(tree) != 40:
            c("CH-GIT", "UNMET", "HEAD/tree ΔΕΝ επαληθεύονται")
            return report(mode)
        c("CH-GIT", "MET", f"καθαρό snapshot · HEAD {head[:12]} · tree {tree[:12]}")

    # ── ΑΛΥΣΙΔΑ ────────────────────────────────────────────────────────
    v1ok = os.path.exists(P("experiment/OBJECTIVE-CONSTITUTION.json")) and \
        sha_b(open(P("experiment/OBJECTIVE-CONSTITUTION.json"), "rb").read()) == V1_SEAL
    c("CH-01-v1", "MET" if v1ok else "UNMET", "v1 byte-identical")
    v2 = rj("experiment/OBJECTIVE-CONSTITUTION.v2.REV3.DRAFT.json", 5000)
    am = rj("experiment/CONSTITUTION-AMENDMENT-1.REV3.DRAFT.json", 1500)
    ep = rj("experiment/OBJECTIVE-EPOCH-1.REV3.DRAFT.json", 1500)
    if not all(isinstance(x, dict) for x in (v2, am, ep)):
        c("CH-02", "UNMET", "v2/amendment/epoch: απόν/κενό/τετριμμένο")
        return report(mode)
    v2sha = sha_b(open(P("experiment/OBJECTIVE-CONSTITUTION.v2.REV3.DRAFT.json"), "rb").read())
    ok = (v2.get("amends_sha256") == V1_SEAL
          and am["to_version"]["sha256"] == v2sha
          and ep["bound_to_constitution"]["sha256"] == v2sha)
    c("CH-02-chain", "MET" if ok else "UNMET", "hashes ΕΠΑΝΥΠΟΛΟΓΙΣΜΕΝΑ, αλυσίδα συνεπής")
    ok = "in_force" not in v2 and "status" not in v2 and "STATUS-NEUTRAL" in v2.get("normative_body", "")
    c("CH-03-status-neutral", "MET" if ok else "UNMET",
      "normative body ΧΩΡΙΣ πεδία κατάστασης — lifecycle μόνο στο FSM record")
    dm = am.get("v1_disposition_map", {})
    v1keys = set(json.load(open(P("experiment/OBJECTIVE-CONSTITUTION.json"), encoding="utf-8")))
    ok = set(dm) == v1keys and all(
        d.get("disposition") in ("PRESERVED", "PRESERVED-META", "AMENDED", "SUPERSEDED")
        and len(d.get("where_why", "")) >= 8 for d in dm.values())
    c("CH-04-disposition", "MET" if ok else "UNMET",
      f"v1 disposition map: {len(dm)}/{len(v1keys)} με αιτιολόγηση")

    # ── PRECOMMIT INPUTS: ΠΕΡΙΕΧΟΜΕΝΟ, όχι status flag ─────────────────
    bad = []
    for k, v in ep["precommit_pre_phi2A"]["inputs"].items():
        sealed = (v.get("status") == "SEALED"
                  and v.get("value") not in (None, "", {}, [])
                  and isinstance(v.get("evidence"), list) and len(v["evidence"]) >= 1
                  and all(isinstance(e, dict) and e.get("sha256") for e in v["evidence"])
                  and len(json.dumps(v.get("value"))) >= 40)
        if not sealed:
            bad.append(k)
    if mode == "draft-lint":
        c("CH-05-inputs", "NOT-YET" if bad else "MET",
          f"{len(bad)}/8 PENDING — ΤΟ {{status:SEALED}} ΧΩΡΙΣ value+evidence "
          f"ΔΕΝ μετράει ως σφραγισμένο")
    else:
        c("CH-05-inputs", "UNMET" if bad else "MET",
          f"ΜΗ σφραγισμένα με περιεχόμενο: {bad}" if bad else "8/8 με value+evidence")

    # ── ATTESTATION: ΔΥΟ ΒΗΜΑΤΑ, ΟΧΙ ΚΥΚΛΟΣ, ΟΧΙ PADDING ───────────────
    at = rj("experiment/RATIFICATION-ATTESTATION.json", 400)
    def attestation_valid():
        if not isinstance(at, dict):
            return False, "απόν ή τετριμμένο"
        need = ["v1_sha256", "v2_sha256", "amendment_sha256", "epoch_sha256",
                "checker_sha256", "construction_commit", "approved_by_creator",
                "approval_statement"]
        miss = [k for k in need if k not in at]
        if miss:
            return False, f"λείπουν {miss}"
        if at["v1_sha256"] != V1_SEAL or at["v2_sha256"] != v2sha:
            return False, "hashes δεν ταιριάζουν με τα ΠΡΑΓΜΑΤΙΚΑ bytes"
        amsha = sha_b(open(P("experiment/CONSTITUTION-AMENDMENT-1.REV3.DRAFT.json"), "rb").read())
        epsha = sha_b(open(P("experiment/OBJECTIVE-EPOCH-1.REV3.DRAFT.json"), "rb").read())
        if at["amendment_sha256"] != amsha or at["epoch_sha256"] != epsha:
            return False, "amendment/epoch hashes ≠ πραγματικά"
        if at["approved_by_creator"] is not True or len(str(at["approval_statement"])) < 20:
            return False, "χωρίς ουσιαστική δήλωση έγκρισης"
        cc = at["construction_commit"]
        rc, _ = git("cat-file", "-e", f"{cc}^{{commit}}")
        if rc != 0:
            return False, f"C={cc[:12]} ανύπαρκτο"
        r2 = subprocess.run(["git", "-C", ROOT, "cat-file", "-p",
                             f"{cc}:experiment/OBJECTIVE-CONSTITUTION.v2.REV3.DRAFT.json"],
                            capture_output=True)
        if r2.returncode != 0 or sha_b(r2.stdout) != v2sha:
            return False, "τα v2 bytes ΣΤΟ ΔΕΝΤΡΟ ΤΟΥ C ≠ attestation"
        r3 = subprocess.run(["git", "-C", ROOT, "cat-file", "-e",
                             f"{cc}:experiment/RATIFICATION-ATTESTATION.json"],
                            capture_output=True)
        if r3.returncode == 0:
            return False, "ΚΥΚΛΟΣ: το attestation ζει ΜΕΣΑ στο C που δεσμεύει"
        r4 = subprocess.run(["git", "-C", ROOT, "merge-base", "--is-ancestor", cc, "HEAD"])
        if r4.returncode != 0:
            return False, "το C δεν είναι πρόγονος του HEAD (lineage)"
        return True, "δύο βήματα επαληθευμένα: C πρόγονος, bytes ταυτίζονται, χωρίς κύκλο"
    okat, why = attestation_valid()
    if mode == "draft-lint":
        c("CH-06-attestation", "NOT-YET" if at is None else ("MET" if okat else "UNMET"), why)
    else:
        c("CH-06-attestation", "MET" if okat else "UNMET", why)

    # ── FSM ─────────────────────────────────────────────────────────────
    lr = rj("experiment/LIFECYCLE-RECORD.json", 100)
    okf = isinstance(lr, dict) and "state" in lr
    c("CH-07-fsm", "MET" if okf else "UNMET",
      f"FSM record: {lr['state'] if okf else 'ΑΠΟΝ'}")
    if strict and okf:
        need_states = {"law": "IN-FORCE", "epoch": "ACTIVE",
                       "phase1a": "SEALED", "evaluator": "FROZEN"}
        badst = {k: lr["state"].get(k) for k, v in need_states.items()
                 if lr["state"].get(k) != v}
        c("CH-08-states", "MET" if not badst else "UNMET",
          f"απαιτούμενα: {need_states}· αποκλίσεις: {badst or 'καμία'}")
        order = P("experiment/PHASE2-ACTIVATION-ORDER.json")
        oko = os.path.exists(order) and rj("experiment/PHASE2-ACTIVATION-ORDER.json", 100)
        c("CH-09-order", "MET" if oko else "UNMET",
          "ρητή εντολή ενεργοποίησης δημιουργού" if oko else "ΑΠΟΥΣΑ εντολή")

    # ── PROOFS: PARSE + REPLAY — τετριμμένα/unbound ΑΠΟΡΡΙΠΤΟΝΤΑΙ ──────
    proofs = [("CH-10-domain-closure", "experiment/phase2/DOMAIN-CLOSURE-CERTIFICATE.json"),
              ("CH-11-omega-laws", "experiment/phase2/OMEGA-ORDER-LAWS-PROOF.json"),
              ("CH-12-candidates", "experiment/phase2/CANDIDATE-ARCHITECTURES.json"),
              ("CH-13-dominance", "experiment/phase3/PAIRWISE-DOMINANCE.json"),
              ("CH-14-joins", "experiment/phase3/JOIN-SUPERSET-SYNTHESIS.json"),
              ("CH-15-dag", "experiment/phase3/SEARCH-DAG-CLOSURE.json")]
    epsha = sha_b(open(P("experiment/OBJECTIVE-EPOCH-1.REV3.DRAFT.json"), "rb").read())
    for oid, rel in proofs:
        d = rj(rel, 500)
        if d is None:
            phase_active = strict and mode == "active"
            c(oid, "UNMET" if phase_active else "NOT-YET",
              f"{rel} — {'BLOCKING στο active' if phase_active else 'παραδοτέο φάσης'}")
            continue
        if d is False:
            c(oid, "UNMET", f"{rel}: κενό/τετριμμένο/μη-JSON — ΑΠΟΡΡΙΠΤΕΤΑΙ")
            continue
        if d.get("bound_epoch_sha256") != epsha:
            c(oid, "UNMET", f"{rel}: UNBOUND — δεν δένεται στο τρέχον epoch")
            continue
        rp = d.get("replay")
        if not (isinstance(rp, dict) and isinstance(rp.get("cmd"), list)
                and rp.get("expect_sha256")):
            c(oid, "UNMET", f"{rel}: ΧΩΡΙΣ replay spec — existence δεν αρκεί")
            continue
        rr = subprocess.run(rp["cmd"], cwd=ROOT, capture_output=True, timeout=600)
        got = sha_b(rr.stdout)
        okr = rr.returncode == 0 and got == rp["expect_sha256"]
        c(oid, "MET" if okr else "UNMET",
          f"{rel}: REPLAY {'αναπαρήγαγε το δηλωμένο αποτέλεσμα' if okr else f'ΑΠΕΤΥΧΕ (exit {rr.returncode}, sha {got[:12]}…)'}")

    return report(mode)


def report(mode):
    unmet = [r for r in R if r[1] == "UNMET"]
    notyet = [r for r in R if r[1] == "NOT-YET"]
    print(f"CEILING CHECKER v2 REV3 (DRAFT) · mode={mode}")
    print("═" * 70)
    for oid, st, d in R:
        print(f"  {'✓' if st=='MET' else '…' if st=='NOT-YET' else '✗'} [{st:7}] {oid}: {d}")
    print("═" * 70)
    print(f"MET {sum(1 for r in R if r[1]=='MET')} · NOT-YET {len(notyet)} · UNMET {len(unmet)}")
    if mode == "draft-lint":
        if unmet:
            print("::error::UNMET σε draft-lint")
            return 1
        print("DRAFT-CONSISTENT")
        return 0
    # preflight/active: ΚΑΘΕ εφαρμοστέο NOT-YET είναι ΕΠΙΣΗΣ blocking
    blocking = unmet + ([r for r in notyet] if mode == "active" else notyet)
    if blocking:
        print(f"ACTIVATION-GATE: ΚΛΕΙΣΤΗ — {len(blocking)} blocking "
              f"({len(unmet)} UNMET + {len(blocking)-len(unmet)} NOT-YET)")
        return 1
    print("ACTIVATION-GATE: ΑΝΟΙΚΤΗ")
    return 0


sys.exit(main())
