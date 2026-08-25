#!/usr/bin/env python3
"""LIFECYCLE FSM — ΤΟ ΕΞΩΤΕΡΙΚΟ AUTHORITATIVE RECORD ΚΑΤΑΣΤΑΣΗΣ.

Το normative body του v2 είναι STATUS-NEUTRAL: δεν γράφει πουθενά αν είναι σε
ισχύ. Η κατάσταση ζει ΕΔΩ (experiment/LIFECYCLE-RECORD.json), ως phase-indexed
FSM με ΦΡΟΥΡΟΥΜΕΝΕΣ μεταβάσεις. Κάθε μετάβαση απαιτεί evidence· χωρίς αυτό ο
guard ΑΡΝΕΙΤΑΙ. Το record είναι append-only ως προς το :history.

  show                         τρέχουσα κατάσταση
  assert <track> <state>       exit 0 αν ισχύει, 1 αλλιώς (για scripts)
  transition <track> <to> [--evidence k=v ...]   φρουρούμενη μετάβαση
"""
import hashlib
import json
import os
import subprocess
import sys
import time

REPO = "/home/user/THE-LEGAL-WATCHTOWER"
RECORD = f"{REPO}/experiment/LIFECYCLE-RECORD.json"
V1_SEAL = "5b3ab5bf9561d535adbf5049b975ac2ab8e9a63db32dfb14a07d82d78b729be6"

TRACKS = {
 "law":     ["DRAFT", "RATIFIED-SEALED", "IN-FORCE", "SUPERSEDED"],
 "epoch":   ["DRAFT", "SEALED-INACTIVE", "ACTIVE", "INVALIDATED"],
 "checker": ["DRAFT", "BOUND-TO-EPOCH"],
 "evaluator": ["CONSTRUCTION", "FROZEN"],
 "phase1a": ["RUNNING", "SEALED"],
 "phase2A": ["LOCKED", "AUTHORIZED", "RUNNING", "CLOSED"],
 "phase2B": ["LOCKED", "AUTHORIZED", "RUNNING", "SEALED"],
 "phase3":  ["LOCKED", "AUTHORIZED", "RUNNING", "SEALED"],
 "phase4":  ["LOCKED", "AUTHORIZED", "RUNNING", "SEALED"],
}


def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()


def load():
    if not os.path.exists(RECORD):
        return {"kind": "lawmax-lifecycle-record/1",
                "state": {t: TRACKS[t][0] for t in TRACKS},
                "history": []}
    return json.load(open(RECORD, encoding="utf-8"))


def save(r):
    tmp = RECORD + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(r, fh, ensure_ascii=False, indent=1)
        fh.flush(); os.fsync(fh.fileno())
    os.rename(tmp, RECORD)


# ── ΦΡΟΥΡΟΙ — καθένας επιστρέφει (ok, why) ─────────────────────────────────
def g_law_ratify(r, ev):
    p = ev.get("attestation")
    if not p or not os.path.exists(os.path.join(REPO, p)):
        return False, "απαιτείται attestation αρχείο"
    at = json.load(open(os.path.join(REPO, p), encoding="utf-8"))
    need = ["v1_sha256", "v2_sha256", "amendment_sha256", "epoch_sha256",
            "checker_sha256", "construction_commit", "construction_tree",
            "approved_by_creator", "approval_statement"]
    miss = [k for k in need if k not in at]
    if miss:
        return False, f"attestation: λείπουν {miss}"
    if at["v1_sha256"] != V1_SEAL:
        return False, "attestation: λάθος v1"
    if at["approved_by_creator"] is not True or len(str(at.get("approval_statement", ""))) < 20:
        return False, "attestation: απουσιάζει ουσιαστική δήλωση έγκρισης"
    # ΔΥΟ ΒΗΜΑΤΑ, ΟΧΙ ΚΥΚΛΟΣ: το attestation δεσμεύει ΠΡΟΓΕΝΕΣΤΕΡΟ commit C
    # του οποίου το δέντρο περιέχει τα ακριβή v2 bytes· το ίδιο το attestation
    # ζει ΕΞΩ από το C (επόμενο commit / εξωτερική υπογραφή).
    c = at["construction_commit"]
    r2 = subprocess.run(["git", "-C", REPO, "cat-file", "-p",
                         f"{c}:experiment/OBJECTIVE-CONSTITUTION.v2.REV3.DRAFT.json"],
                        capture_output=True)
    if r2.returncode != 0:
        return False, f"το commit C={c[:12]} δεν περιέχει το v2 αρχείο"
    if hashlib.sha256(r2.stdout).hexdigest() != at["v2_sha256"]:
        return False, "τα v2 bytes στο C ≠ attestation v2_sha256"
    r3 = subprocess.run(["git", "-C", REPO, "merge-base", "--is-ancestor", c, "HEAD"])
    if r3.returncode != 0:
        return False, f"το C={c[:12]} δεν είναι πρόγονος του HEAD (lineage)"
    here = subprocess.run(["git", "-C", REPO, "ls-tree", "-r", "HEAD", "--name-only"],
                          capture_output=True, text=True).stdout
    return True, "attestation πλήρες· C είναι πρόγονος· v2 bytes επαληθευμένα"


def g_epoch_seal(r, ev):
    if r["state"]["law"] not in ("RATIFIED-SEALED", "IN-FORCE"):
        return False, "law πρέπει RATIFIED πρώτα"
    p = os.path.join(REPO, "experiment/OBJECTIVE-EPOCH-1.REV3.DRAFT.json")
    ep = json.load(open(p, encoding="utf-8"))
    bad = []
    for k, v in ep["precommit_pre_phi2A"]["inputs"].items():
        if v.get("status") != "SEALED" or not v.get("value") or not v.get("evidence"):
            bad.append(k)
    return (not bad, "όλα τα pre-Φ2A inputs SEALED με value+evidence"
            if not bad else f"ΕΚΚΡΕΜΗ/κενά: {bad}")


def g_phase2A_auth(r, ev):
    if r["state"]["law"] != "IN-FORCE":
        return False, "law όχι IN-FORCE"
    if r["state"]["epoch"] != "ACTIVE":
        return False, "epoch όχι ACTIVE"
    if r["state"]["phase1a"] != "SEALED":
        return False, "Φ1A όχι SEALED"
    if r["state"]["evaluator"] != "FROZEN":
        return False, "evaluator όχι FROZEN — το όργανο πρέπει να παγώσει πριν τη μελέτη"
    order = ev.get("creator_order")
    if not order or not os.path.exists(os.path.join(REPO, order)):
        return False, "απαιτείται ΡΗΤΗ εντολή ενεργοποίησης του δημιουργού (αρχείο)"
    pf = subprocess.run(["python3", f"{REPO}/experiment/runner/"
                         "constitution-checker-v2.REV3.DRAFT.py", "--mode", "preflight"],
                        cwd=REPO, capture_output=True)
    if pf.returncode != 0:
        return False, "checker preflight ΚΛΕΙΣΤΟ"
    return True, "όλα τα gates ανοιχτά + ρητή εντολή + preflight PASS"


GUARDS = {
 ("law", "RATIFIED-SEALED"): g_law_ratify,
 ("law", "IN-FORCE"): lambda r, ev: (
     (r["state"]["epoch"] in ("SEALED-INACTIVE", "ACTIVE"),
      "απαιτεί epoch SEALED")),
 ("epoch", "SEALED-INACTIVE"): g_epoch_seal,
 ("epoch", "ACTIVE"): lambda r, ev: (
     (r["state"]["law"] == "IN-FORCE" and r["state"]["checker"] == "BOUND-TO-EPOCH",
      "απαιτεί law IN-FORCE + checker δεμένο")),
 ("checker", "BOUND-TO-EPOCH"): lambda r, ev: (
     (bool(ev.get("checker_sha256")) and bool(ev.get("epoch_sha256")),
      "απαιτεί checker_sha256 + epoch_sha256")),
 ("evaluator", "FROZEN"): lambda r, ev: (
     (bool(ev.get("freeze_receipt")), "απαιτεί freeze receipt")),
 ("phase1a", "SEALED"): lambda r, ev: (
     (all(os.path.exists(os.path.join(REPO, f"experiment/phase1a/{f}"))
          for f in ("CLAIM-CITATION-COVERAGE.sexp", "CLAIM-ENTAILMENT.sexp",
                    "READ-LEDGER.sexp", "MACRO-LAYER.sexp", "PHASE-1A-SEAL.sexp")),
      "απαιτεί coverage+entailment+read-ledger+macro+seal artifacts")),
 ("phase2A", "AUTHORIZED"): g_phase2A_auth,
}


def main():
    a = sys.argv[1:]
    r = load()
    if not os.path.exists(RECORD):
        save(r)                     # γένεση του authoritative record
    if not a or a[0] == "show":
        print(json.dumps(r["state"], ensure_ascii=False, indent=1))
        print(f"history: {len(r['history'])} μεταβάσεις")
        return 0
    if a[0] == "assert":
        return 0 if r["state"].get(a[1]) == a[2] else 1
    if a[0] != "transition":
        print("show | assert <track> <state> | transition <track> <to> [--evidence k=v]")
        return 2
    track, to = a[1], a[2]
    ev = {}
    for i, t in enumerate(a):
        if t == "--evidence" and i + 1 < len(a) and "=" in a[i + 1]:
            k, _, v = a[i + 1].partition("=")
            ev[k] = v
    if track not in TRACKS or to not in TRACKS[track]:
        print(f"::error::άγνωστο {track}/{to}")
        return 2
    cur = r["state"][track]
    if TRACKS[track].index(to) != TRACKS[track].index(cur) + 1 and not (
            track == "epoch" and to == "INVALIDATED"):
        print(f"::error::μη γραμμική μετάβαση {cur}→{to} — απαγορεύεται")
        return 2
    guard = GUARDS.get((track, to))
    if guard:
        ok, why = guard(r, ev)
        if not ok:
            print(f"::error::GUARD ΑΡΝΗΘΗΚΕ {track}:{cur}→{to} — {why}")
            return 1
    else:
        why = "χωρίς πρόσθετο guard"
    r["state"][track] = to
    r["history"].append({"utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                         "track": track, "from": cur, "to": to,
                         "evidence": ev, "guard": why})
    save(r)
    print(f"{track}: {cur} → {to}  ({why})")
    return 0


sys.exit(main())
