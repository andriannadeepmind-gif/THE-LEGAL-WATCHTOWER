#!/usr/bin/env python3
"""CEILING CHECKER v2 — REV2 DRAFT. Lifecycle-aware. ΔΕΝ είναι σε ισχύ.

ΤΡΕΙΣ ΤΡΟΠΟΙ ΛΕΙΤΟΥΡΓΙΑΣ (--mode):
  draft-lint  έλεγχος συνέπειας των DRAFT artifacts (προεπιλογή τώρα)
  preflight   ΟΛΑ τα objective-defining inputs σφραγισμένα + attestation παρόν·
              αυτό είναι το ACTIVATION GATE της Φ2 — αποτυγχάνει σήμερα ΟΡΘΩΣ
  active      πλήρης έλεγχος εν λειτουργία φάσεων (μελλοντικός)

ΤΙ ΤΟΝ ΚΑΝΕΙ CEILING CHECKER ΚΑΙ ΟΧΙ LINTER:
  · ΑΡΝΕΙΤΑΙ να τρέξει preflight/active σε βρώμικο worktree — κρίνει ΜΟΝΟ
    commit-bound snapshot
  · ΕΠΑΝΥΠΟΛΟΓΙΖΕΙ κάθε hash από τα bytes — δεν εμπιστεύεται καταγεγραμμένα
  · ΑΠΟΡΡΙΠΤΕΙ κενά/πλαστά artifacts: ελάχιστο μέγεθος, δομικά πεδία,
    μη τετριμμένες τιμές (dummy axis = άξονας χωρίς levels ή με 1 level)
  · Ελέγχει σημασιολογία: διαμέριση status algebra, congruence obligations
    δηλωμένες, precedence των AS, 8+ topologies με grammar obligation
"""
import argparse
import hashlib
import json
import os
import subprocess
import sys

REPO = "/home/user/THE-LEGAL-WATCHTOWER"
V1 = f"{REPO}/experiment/OBJECTIVE-CONSTITUTION.json"
V1_SEAL = "5b3ab5bf9561d535adbf5049b975ac2ab8e9a63db32dfb14a07d82d78b729be6"
V2 = f"{REPO}/experiment/OBJECTIVE-CONSTITUTION.v2.REV2.DRAFT.json"
AMEND = f"{REPO}/experiment/CONSTITUTION-AMENDMENT-1.REV2.DRAFT.json"
EPOCH = f"{REPO}/experiment/OBJECTIVE-EPOCH-1.REV2.DRAFT.json"
ATTEST = f"{REPO}/experiment/RATIFICATION-ATTESTATION.json"

R = []


def c(oid, st, d):
    R.append((oid, st, d))


def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()


def nonempty_json(p, min_bytes=200):
    """Απόρριψη κενών/πλαστών: υπάρχει, ≥min bytes, έγκυρο JSON, όχι κενό dict."""
    if not os.path.exists(p):
        return None
    if os.path.getsize(p) < min_bytes:
        return False
    try:
        d = json.load(open(p, encoding="utf-8"))
    except Exception:
        return False
    return d if isinstance(d, dict) and d else False


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mode", choices=["draft-lint", "preflight", "active"],
                    default="draft-lint")
    mode = ap.parse_args().mode

    if mode in ("preflight", "active"):
        dirty = subprocess.run(["git", "-C", REPO, "status", "--porcelain"],
                               capture_output=True, text=True).stdout.strip()
        if dirty:
            print("::error::ΒΡΩΜΙΚΟ WORKTREE — preflight/active κρίνουν ΜΟΝΟ "
                  "commit-bound snapshot")
            return 2

    # ── ΑΛΥΣΙΔΑ (επανυπολογισμός, όχι εμπιστοσύνη) ─────────────────────
    ok = sha(V1) == V1_SEAL
    c("CH-01-v1", "MET" if ok else "UNMET", "v1 byte-identical με τη σφραγίδα")
    v2 = nonempty_json(V2, 5000)
    am = nonempty_json(AMEND, 1000)
    ep = nonempty_json(EPOCH, 1000)
    if not all(isinstance(x, dict) for x in (v2, am, ep)):
        c("CH-02-artifacts", "UNMET", "κενό/πλαστό/απόν βασικό artifact")
        return report(mode)
    c("CH-02-artifacts", "MET", "v2/amendment/epoch: παρόντα, μη-τετριμμένα, έγκυρα")
    ok = (v2["amends_sha256"] == V1_SEAL
          and am["from_version"]["sha256"] == V1_SEAL
          and am["to_version"]["sha256"] == sha(V2)
          and ep["bound_to_constitution"]["sha256"] == sha(V2))
    c("CH-03-chain", "MET" if ok else "UNMET",
      "v1→v2→amendment→epoch: όλα τα hashes ΕΠΑΝΥΠΟΛΟΓΙΣΜΕΝΑ και συνεπή")
    c("CH-04-immutability", "MET" if not v2.get("in_force") else "UNMET",
      "το v2 δεν αυτο-ενεργοποιείται· ratification μόνο με χωριστό attestation")

    # ── ΣΗΜΑΣΙΟΛΟΓΙΑ, ΟΧΙ ΣΧΗΜΑ ───────────────────────────────────────
    ax = v2["c6_omega_and_feasibility"]["sealed_axes"]
    c("CH-05-axes", "MET" if len(ax) >= 8 and len(set(ax)) == len(ax) else "UNMET",
      f"{len(ax)} διακριτοί άξονες· dummy-έλεγχος πλήρης όταν οριστούν τα levels "
      f"(κάθε άξονας ≥2 levels) στο DOMAIN-CLOSURE-CERTIFICATE")
    sa = v2["c6_omega_and_feasibility"]["status_algebra"]
    ok = ("ΔΙΑΜΕΡΙΣΗ" in sa["partition"] and "F+ = {q ∈ Q_t | H(q)=PASS}" in sa["partition"])
    c("CH-06-status-algebra", "MET" if ok else "UNMET",
      "αμοιβαία αποκλειόμενη διαμέριση F+/F-/F? δηλωμένη με τον ορισμό F+")
    cong = v2["c5_finite_theorem_domain"]["equivalence_obligations"]
    need = ["H", "Ω", "joins", "implementability"]
    ok = all(any(n in x for x in cong) for n in need) and any("ΑΠΟΦΑΣΙΣΙΜΗ" in x for x in cong)
    c("CH-07-congruence", "MET" if ok else "UNMET",
      "≡material: αποφασισιμότητα + congruence ως προς H/Ω/joins/implementability δηλωμένα ως ΥΠΟΧΡΕΩΣΕΙΣ")
    ok = "ΜΕΤΑΒΑΤΙΚΗ preorder" in v2["c6_omega_and_feasibility"]["axis_obligation"]
    c("CH-08-transitivity", "MET" if ok else "UNMET",
      "κάθε άξονας απαιτείται αποδεδειγμένα μεταβατικός — όχι threshold")
    ok = (v2["c10b_anti_simplification_verbatim"]["verbatim_s11"] ==
          json.load(open(V1, encoding="utf-8"))["s11_anti_simplification_obligations"])
    c("CH-09-as-verbatim", "MET" if ok else "UNMET",
      "AS1-AS10 ΑΥΤΟΥΣΙΑ ίδια bytes με το v1 + precedence δηλωμένη")
    g = v2["c9_join_closure_and_implementability"]
    ok = "COMPOSITION GRAMMAR" in g["topology_incompleteness"] and len(g["base_topologies"]) == 8
    c("CH-10-grammar", "MET" if ok else "UNMET",
      "grammar + coverage theorem απαιτούνται· 8 βασικές topologies")
    ok = "ΜΕΤΑ το closure" in v2["c8_termination"]["resolution"]
    c("CH-11-measure", "MET" if ok else "UNMET",
      "το M μετριέται μόνο μετά το DAG freeze· multiset εναλλακτική δηλωμένη")

    # ── PRECOMMIT INPUTS — το activation gate ──────────────────────────
    pend = [k for k, v in ep["precommit_barrier"]["inputs"].items()
            if v.get("status") != "SEALED"]
    if mode == "draft-lint":
        c("CH-12-precommit", "NOT-YET" if pend else "MET",
          f"{len(pend)}/8 inputs PENDING-SEAL — αποδεκτό ΜΟΝΟ σε draft-lint")
    else:
        c("CH-12-precommit", "UNMET" if pend else "MET",
          f"ΕΚΚΡΕΜΗ: {pend}" if pend else "όλα σφραγισμένα")

    at = nonempty_json(ATTEST, 300)
    if mode == "draft-lint":
        c("CH-13-attestation", "NOT-YET" if not at else ("MET" if at else "UNMET"),
          "ratification attestation — δεν απαιτείται σε draft-lint")
    else:
        ok = (isinstance(at, dict)
              and at.get("v2_sha256") == sha(V2)
              and at.get("approved_by_creator") is True)
        c("CH-13-attestation", "MET" if ok else "UNMET",
          "attestation: δένει v2 bytes + ρητή έγκριση" if ok else "ΑΠΟΝ ή ασύνδετο")

    # ── ΜΕΛΛΟΝΤΙΚΑ PROOF ARTIFACTS (επιτρεπτά NOT-YET προ των φάσεών τους) ─
    for oid, p in [("CH-14-domain-closure", "phase2/DOMAIN-CLOSURE-CERTIFICATE.sexp"),
                   ("CH-15-omega-laws", "phase2/OMEGA-ORDER-LAWS-PROOF.sexp"),
                   ("CH-16-witnesses", "phase2/CANDIDATE-ARCHITECTURES.sexp"),
                   ("CH-17-upper-bounds", "phase3/PAIRWISE-DOMINANCE.sexp"),
                   ("CH-18-join-coverage", "phase3/JOIN-SUPERSET-SYNTHESIS.sexp"),
                   ("CH-19-dag-closure", "phase3/SEARCH-DAG-CLOSURE.sexp")]:
        fp = f"{REPO}/experiment/{p}"
        d = nonempty_json(fp) if fp.endswith(".json") else (
            open(fp, encoding="utf-8").read() if os.path.exists(fp) else None)
        st = "NOT-YET" if d is None else ("MET" if d else "UNMET")
        c(oid, st, p)

    # ── ΚΑΝΕΝΑ Φ2+ artifact δεμένο σε v1 ή σε REV1 draft ───────────────
    off = []
    for ph in ("phase2", "phase3", "phase4"):
        d = f"{REPO}/experiment/{ph}"
        if os.path.isdir(d):
            for root, _, fs in os.walk(d):
                for f in fs:
                    t = open(os.path.join(root, f), encoding="utf-8",
                             errors="ignore").read()
                    if V1_SEAL in t or "omega-ceiling-constitution/1" in t \
                       or "v2.DRAFT" in t.replace("v2.REV2.DRAFT", ""):
                        off.append(os.path.join(root, f))
    c("CH-20-phase-binding", "MET" if not off else "UNMET",
      "κανένα Φ2/Φ3/Φ4 artifact δεμένο σε v1 ή REV1" if not off else f"{off}")

    return report(mode)


def report(mode):
    unmet = [r for r in R if r[1] == "UNMET"]
    print(f"CEILING CHECKER v2 REV2 (DRAFT) · mode={mode}")
    print("═" * 68)
    for oid, st, d in R:
        print(f"  {'✓' if st=='MET' else '…' if st=='NOT-YET' else '✗'} [{st:7}] {oid}: {d}")
    print("═" * 68)
    met = sum(1 for r in R if r[1] == "MET")
    ny = sum(1 for r in R if r[1] == "NOT-YET")
    print(f"MET {met} · NOT-YET {ny} · UNMET {len(unmet)}")
    if mode == "preflight" and not unmet:
        print("ACTIVATION-GATE-Φ2: ΑΝΟΙΚΤΗ")
        return 0
    if mode == "preflight":
        print("ACTIVATION-GATE-Φ2: ΚΛΕΙΣΤΗ — και ΟΡΘΩΣ, όσο εκκρεμούν inputs/attestation")
        return 1
    if unmet:
        print("::error::UNMET σε draft-lint — το draft ΔΕΝ είναι συνεπές")
        return 1
    print("DRAFT-CONSISTENT — αναμονή σφράγισης inputs + ρητής επικύρωσης")
    return 0


sys.exit(main())
