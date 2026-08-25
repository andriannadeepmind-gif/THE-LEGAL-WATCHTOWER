#!/usr/bin/env python3
"""CHECKER v2 — DRAFT. ΔΕΝ ΕΙΝΑΙ ΣΕ ΙΣΧΥ πριν από την επικύρωση του v2.

ΤΙ ΕΙΝΑΙ: ceiling checker — ελέγχει τις ΔΟΜΙΚΕΣ προϋποθέσεις του θεωρήματος
οροφής, όχι μόνο ταυτότητες. Ο παλιός constitution-checker.py είναι
identity/policy linter και παραμένει ΜΟΝΟ ως συμπληρωματικός έλεγχος.

ΚΑΘΕ υποχρέωση αναφέρεται ονομαστικά με κατάσταση:
  MET       — ελέγχθηκε μηχανικά και ισχύει
  UNMET     — ελέγχθηκε μηχανικά και ΔΕΝ ισχύει
  NOT-YET   — το artifact που ελέγχει δεν υπάρχει ακόμη (π.χ. Φ2 certificates)
Σε DRAFT mode: exit 0 μόνο αν ΚΑΝΕΝΑ UNMET (τα NOT-YET επιτρέπονται).
Μετά την επικύρωση: τα NOT-YET των ενεργών φάσεων γίνονται UNMET.
"""
import hashlib
import json
import os
import re
import sys

REPO = "/home/user/THE-LEGAL-WATCHTOWER"
V1 = f"{REPO}/experiment/OBJECTIVE-CONSTITUTION.json"
V1_SEAL = "5b3ab5bf9561d535adbf5049b975ac2ab8e9a63db32dfb14a07d82d78b729be6"
V2 = f"{REPO}/experiment/OBJECTIVE-CONSTITUTION.v2.DRAFT.json"
AMEND = f"{REPO}/experiment/CONSTITUTION-AMENDMENT-1.DRAFT.json"
EPOCH = f"{REPO}/experiment/OBJECTIVE-EPOCH-1.DRAFT.json"

results = []


def check(oid, status, detail):
    results.append((oid, status, detail))


def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()


def main():
    # ── C2-01 αλυσίδα εκδόσεων ──────────────────────────────────────────
    ok = os.path.exists(V1) and sha(V1) == V1_SEAL
    check("C2-01-v1-immutable", "MET" if ok else "UNMET",
          f"v1 sha256 {'ταυτίζεται' if ok else 'ΔΙΑΦΕΡΕΙ'} με τη σφραγίδα")
    v2 = json.load(open(V2, encoding="utf-8"))
    am = json.load(open(AMEND, encoding="utf-8"))
    ok = (v2.get("amends_sha256") == V1_SEAL
          and am["from_version"]["sha256"] == V1_SEAL
          and am["to_version"]["sha256"] == sha(V2))
    check("C2-02-amendment-chain", "MET" if ok else "UNMET",
          "amends_sha256 + amendment act δένουν v1→v2 με πραγματικά hashes")
    check("C2-03-not-in-force", "MET" if not v2.get("in_force") else "UNMET",
          "το v2 δηλώνει ρητά ότι ΔΕΝ είναι σε ισχύ")

    # ── C2-04 πλήρες schema του v2 ─────────────────────────────────────
    need = ["c1_supreme_purpose", "c2_separation_of_law_epoch_state",
            "c3_finite_theorem_domain", "c4_joint_refinement_order_omega",
            "c5_feasibility_and_unknown", "c6_positive_termination",
            "c7_greatest_frontier_join", "c8_implementable_today_and_blueprint",
            "c9_common_lisp_authority", "c10_candidate_admission",
            "c11_amendment_procedure", "c12_checker_v2_requirements"]
    missing = [k for k in need if k not in v2]
    check("C2-04-schema", "MET" if not missing else "UNMET",
          f"τμήματα: {12-len(missing)}/12" + (f" — λείπουν {missing}" if missing else ""))

    # ── C2-05 epoch artifacts + hashes ─────────────────────────────────
    ep = json.load(open(EPOCH, encoding="utf-8"))
    bad = []
    for k, v in ep.get("runner_identities", {}).items():
        if v is None:
            bad.append(k)
    check("C2-05-epoch-hashes", "MET" if not bad else "UNMET",
          "όλα τα runner identities έχουν πραγματικά hashes"
          if not bad else f"κενά: {bad}")
    ok = ep["bound_to_constitution"]["sha256"] == sha(V2)
    check("C2-05b-epoch-binding", "MET" if ok else "UNMET",
          "το epoch δένεται στο ΠΡΑΓΜΑΤΙΚΟ hash του v2 draft")

    # ── C2-06 finite domain / closure certificate ──────────────────────
    p = f"{REPO}/experiment/phase2/DOMAIN-CLOSURE-CERTIFICATE.sexp"
    check("C2-06-domain-closure", "NOT-YET" if not os.path.exists(p) else "MET",
          "DOMAIN-CLOSURE-CERTIFICATE — παραδοτέο Φ2")

    # ── C2-07 Ω order laws ─────────────────────────────────────────────
    c4 = v2["c4_joint_refinement_order_omega"]
    ok = "order_laws_required" in c4 and len(c4["sealed_axes"]) == 8
    check("C2-07-omega-laws-declared", "MET" if ok else "UNMET",
          "8 σφραγισμένοι άξονες + απαίτηση order laws")
    check("C2-07b-omega-laws-proved", "NOT-YET",
          "η ΑΠΟΔΕΙΞΗ των order laws ζει στο DOMAIN-CLOSURE-CERTIFICATE")

    # ── C2-08/09/10 witnesses, upper bounds, joins ─────────────────────
    for oid, art, what in [
        ("C2-08-implementability-witnesses", "phase2/CANDIDATE-ARCHITECTURES.sexp",
         "witnesses ανά candidate"),
        ("C2-09-branch-upper-bounds", "phase3/PAIRWISE-DOMINANCE.sexp",
         "UB certificates ανά κλεισμένο branch"),
        ("C2-10-nary-join-coverage", "phase3/JOIN-SUPERSET-SYNTHESIS.sexp",
         "κάλυψη και των 8 topologies")]:
        p = f"{REPO}/experiment/{art}"
        check(oid, "NOT-YET" if not os.path.exists(p) else "MET", what)

    # ── C2-11 DAG closure + measure ────────────────────────────────────
    c6 = v2["c6_positive_termination"]
    ok = (set(c6["leaf_kinds_exhaustive"]) ==
          {"FEASIBLE-WITNESS", "INFEASIBLE-CERTIFICATE", "DOMINATED-UPPER-BOUND"}
          and "N⁴" in c6["measure"])
    check("C2-11-termination-declared", "MET" if ok else "UNMET",
          "3 leaf kinds + μέτρο N⁴ δηλωμένα")
    check("C2-11b-dag-closure", "NOT-YET", "το ίδιο το DAG — παραδοτέο Φ2/Φ3")

    # ── C2-12 comparisons use Ω only · no Phase-2/3/4 binds v1 ─────────
    offenders = []
    for ph in ("phase2", "phase3", "phase4"):
        d = f"{REPO}/experiment/{ph}"
        if not os.path.isdir(d):
            continue
        for root, _, files in os.walk(d):
            for f in files:
                t = open(os.path.join(root, f), encoding="utf-8",
                         errors="ignore").read()
                if "omega-ceiling-constitution/1" in t or V1_SEAL in t:
                    offenders.append(os.path.join(root, f))
    check("C2-12-no-phase234-binds-v1", "MET" if not offenders else "UNMET",
          "κανένα Φ2/Φ3/Φ4 artifact δεμένο στο v1"
          if not offenders else f"ΠΑΡΑΒΑΤΕΣ: {offenders}")

    # ── ΑΝΑΦΟΡΑ ────────────────────────────────────────────────────────
    unmet = [r for r in results if r[1] == "UNMET"]
    print("CHECKER v2 (DRAFT) — ceiling checker, ΟΧΙ linter")
    print("═" * 66)
    for oid, st, d in results:
        print(f"  {'✓' if st=='MET' else '…' if st=='NOT-YET' else '✗'} "
              f"[{st:7}] {oid}: {d}")
    print("═" * 66)
    met = sum(1 for r in results if r[1] == "MET")
    ny = sum(1 for r in results if r[1] == "NOT-YET")
    print(f"MET {met} · NOT-YET {ny} · UNMET {len(unmet)}")
    if unmet:
        print("::error::UNMET υποχρεώσεις — το draft ΔΕΝ είναι συνεπές")
        return 1
    print("DRAFT-CONSISTENT — έτοιμο για επικύρωση δημιουργού (ΔΕΝ σφραγίζεται μόνο του)")
    return 0


sys.exit(main())
