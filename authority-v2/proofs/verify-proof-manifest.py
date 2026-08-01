#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""PROOF MANIFEST — ΜΗΧΑΝΙΚΟΣ ΕΛΕΓΧΟΣ (fail-closed)

Επιβάλλει τον κανόνα της διορθωτικής §5:
  · status ΜΟΝΟ από {proved, failed, blocked-toolchain}
  · :proved απαιτεί ΔΗΛΩΜΕΝΟ proof artifact ΚΑΙ prover που ΥΠΑΡΧΕΙ
  · το gate είναι :passed ΜΟΝΟ αν ΚΑΘΕ φέρον θεώρημα είναι :proved
  · το summary υπολογίζεται από τις γραμμές (καμία χειροκίνητη βαθμολογία)
  · κανένα θεώρημα δεν γίνεται :proved επειδή «πέρασαν τα tests»
    (certificates/bounded checking ΔΕΝ αναβαθμίζουν status)
"""
import os
import re
import sys

ALLOWED = {":proved", ":failed", ":blocked-toolchain"}
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main(argv):
    path = argv[1] if len(argv) > 1 else os.path.join(HERE, "proof-manifest.sexp")
    src = open(path, encoding="utf-8").read()
    fails = []

    present = {}
    for m in re.finditer(r'\(:name\s+"([^"]+)"[^)]*?:present\s+(t|nil)', src, re.S):
        present[m.group(1)] = (m.group(2) == "t")

    rows = []
    for b in re.split(r"\n\s*\(+:id ", src)[1:]:
        body = "(:id " + b
        rid = re.match(r"\(:id\s+(:[\w-]+)", body)
        if not rid:
            continue
        st = re.search(r":status\s+(:[a-z-]+)", body)
        lb = re.search(r":load-bearing\s+(t|nil)", body)
        pv = re.search(r':prover\s+"([^"]+)"', body)
        rows.append({"id": rid.group(1),
                     "status": st.group(1) if st else None,
                     "lb": (lb.group(1) == "t") if lb else None,
                     "prover": pv.group(1) if pv else None,
                     "body": body})

    if not rows:
        print("::error::ΚΕΝΟ proof manifest — fail-closed")
        return 1

    for r in rows:
        if r["status"] not in ALLOWED:
            fails.append("%s: ΜΗ ΕΠΙΤΡΕΠΤΟ status %r" % (r["id"], r["status"]))
        if r["lb"] is None:
            fails.append("%s: ΑΠΡΟΣΔΙΟΡΙΣΤΟ :load-bearing" % r["id"])
        if r["status"] == ":proved":
            if ":proof-artifact" not in r["body"]:
                fails.append("%s: :proved ΧΩΡΙΣ :proof-artifact" % r["id"])
            if r["prover"] and present.get(r["prover"]) is False:
                fails.append("%s: :proved αλλά ο prover %r ΔΕΝ ΥΠΑΡΧΕΙ — αδύνατο"
                             % (r["id"], r["prover"]))

    counts = {s: sum(1 for r in rows if r["status"] == s) for s in ALLOWED}
    lb_not_proved = [r["id"] for r in rows if r["lb"] and r["status"] != ":proved"]
    gate = re.search(r":gate\s+(:[a-z-]+)", src).group(1)
    if lb_not_proved and gate != ":not-passed":
        fails.append("ΨΕΥΔΟ-ΠΡΑΣΙΝΟ: gate=%s ενώ %d φέροντα θεωρήματα ≠ :proved"
                     % (gate, len(lb_not_proved)))

    declared = {}
    m = re.search(r":summary\s*\((.*?):statement", src, re.S)
    if m:
        for k, v in re.findall(r":([a-z-]+)\s+(\d+)", m.group(1)):
            declared[k] = int(v)
    computed = {"total": len(rows), "proved": counts[":proved"],
                "failed": counts[":failed"],
                "blocked-toolchain": counts[":blocked-toolchain"]}
    for k, v in computed.items():
        if k in declared and declared[k] != v:
            fails.append("summary %s: δηλωμένο %d ≠ υπολογισμένο %d" % (k, declared[k], v))

    print("PROOF MANIFEST — %d θεωρήματα" % len(rows))
    for s in (":proved", ":failed", ":blocked-toolchain"):
        print("  %-20s %d" % (s, counts[s]))
    print("  φέροντα ΟΧΙ-proved  : %d" % len(lb_not_proved))
    print("  gate                : %s" % gate)
    if fails:
        print("\n%d ΑΣΥΝΕΠΕΙΕΣ:" % len(fails))
        for f in fails:
            print("  ✗ " + f)
        return 1
    print("\n✓ proof manifest ΣΥΝΕΠΕΣ")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
