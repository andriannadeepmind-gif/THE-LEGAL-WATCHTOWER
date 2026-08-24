#!/usr/bin/env python3
"""ΜΗΧΑΝΙΚΟΣ ΥΠΟΛΟΓΙΣΜΟΣ ΠΡΟΟΔΟΥ — ΑΠΟ ΚΑΤΑΛΟΓΟ ΚΑΙ RECEIPT, ΟΧΙ ΕΚΤΙΜΗΣΗ.

Κάθε υποχρέωση αξιολογείται με το acceptance predicate της. ΜΟΝΟ το VERIFIED
συνεισφέρει· καμία μερική πίστωση. Μια υποχρέωση της οποίας οι εξαρτήσεις δεν
είναι VERIFIED σημαίνεται BLOCKED ακόμη κι αν το predicate της περνά — δεν
μπορεί να στέκει σε θεμέλιο που δεν στέκει.

Το αποτέλεσμα γράφεται ως receipt με hash του καταλόγου και του gate receipt
που χρησιμοποιήθηκε.
"""
import hashlib
import json
import os
import subprocess
import sys

REPO = "/home/user/THE-LEGAL-WATCHTOWER"
CATALOGUE = f"{REPO}/experiment/OBLIGATIONS.json"
RECEIPTS = f"{REPO}/experiment/artifacts/gate-receipts"


def latest_receipt():
    if not os.path.isdir(RECEIPTS):
        return None, None
    # ΤΟ «latest» ΕΙΝΑΙ ΜΕΤΑΒΛΗΤΗ ΠΡΟΒΟΛΗ, ΟΧΙ ΤΕΚΜΗΡΙΟ: αποκλείεται ρητά.
    runs = sorted(d for d in os.listdir(RECEIPTS)
                  if not os.path.islink(os.path.join(RECEIPTS, d))
                  and os.path.isfile(os.path.join(RECEIPTS, d, "RECEIPT.json")))
    if not runs:
        return None, None
    p = os.path.join(RECEIPTS, runs[-1], "RECEIPT.json")
    return json.load(open(p, encoding="utf-8")), p


def dig(d, pointer):
    for k in pointer:
        if not isinstance(d, dict) or k not in d:
            return None
        d = d[k]
    return d


def evaluate(acc, receipt):
    k = acc["kind"]
    if k == "file_exists":
        return os.path.exists(os.path.join(REPO, acc["path"])), acc["path"]
    if k == "cmd_exit_zero":
        try:
            r = subprocess.run(acc["cmd"], cwd=REPO, capture_output=True, timeout=600)
            return r.returncode == 0, f"exit {r.returncode}"
        except Exception as e:
            return False, f"<{e}>"
    if receipt is None:
        return False, "κανένα gate receipt"
    if k == "receipt_equals":
        v = dig(receipt, acc["pointer"])
        return v == acc["value"], f"{'/'.join(acc['pointer'])}={v!r}"
    if k == "receipt_gte":
        v = dig(receipt, acc["pointer"])
        return isinstance(v, (int, float)) and v >= acc["value"], \
            f"{'/'.join(acc['pointer'])}={v!r}"
    if k == "lane_pass":
        for r in receipt.get("results", []):
            if r["lane"] == acc["lane"]:
                return (r.get("verdict") == "RECOGNIZED-CITATION-INTEGRITY"
                        and r.get("exit_code") == 0), \
                    f"exit={r.get('exit_code')} verdict={r.get('verdict')}"
        return False, "η διαδρομή απούσα από το receipt"
    if k == "not_yet_constructible":
        return False, acc["reason"]
    return False, f"άγνωστο predicate «{k}»"


def main():
    cat = json.load(open(CATALOGUE, encoding="utf-8"))
    receipt, rpath = latest_receipt()
    obs = {o["id"]: o for o in cat["obligations"]}
    status, why = {}, {}

    # τοπολογική αξιολόγηση: μια υποχρέωση δεν μπορεί να στέκει πάνω σε
    # θεμέλιο που δεν στέκει
    for _ in range(len(obs) + 1):
        for oid, o in obs.items():
            if status.get(oid) == "VERIFIED":
                continue
            deps_ok = all(status.get(d) == "VERIFIED" for d in o["depends_on"])
            ok, detail = evaluate(o["acceptance"], receipt)
            if ok and deps_ok:
                status[oid], why[oid] = "VERIFIED", detail
            elif ok and not deps_ok:
                missing = [d for d in o["depends_on"] if status.get(d) != "VERIFIED"]
                status[oid], why[oid] = "BLOCKED", f"predicate ✓ αλλά εξαρτήσεις: {missing}"
            elif not deps_ok:
                status[oid], why[oid] = "BLOCKED", f"εξαρτήσεις: " + ", ".join(
                    d for d in o["depends_on"] if status.get(d) != "VERIFIED")
            else:
                status[oid], why[oid] = "NOT-STARTED", detail

    by_cat = {}
    for oid, o in obs.items():
        c = by_cat.setdefault(o["category"], {"weight": 0.0, "verified": 0.0,
                                              "n": 0, "n_verified": 0})
        c["weight"] += o["weight"]
        c["n"] += 1
        if status[oid] == "VERIFIED":
            c["verified"] += o["weight"]
            c["n_verified"] += 1
    total_w = sum(c["weight"] for c in by_cat.values())
    total_v = sum(c["verified"] for c in by_cat.values())
    pct = 100.0 * total_v / total_w if total_w else 0.0

    print("═" * 72)
    print("ΜΗΧΑΝΙΚΗ ΠΡΟΟΔΟΣ — ΜΟΝΟ VERIFIED ΣΥΝΕΙΣΦΕΡΕΙ")
    print("═" * 72)
    print(f"{'κατηγορία':36} {'βάρος':>6} {'VERIFIED':>9} {'%':>7}  υποχρ.")
    for c in cat["category_weights"]:
        d = by_cat[c]
        p = 100.0 * d["verified"] / d["weight"] if d["weight"] else 0.0
        print(f"{c:36} {d['weight']:6.1f} {d['verified']:9.1f} {p:6.1f}%  "
              f"{d['n_verified']}/{d['n']}")
    print("─" * 72)
    print(f"{'ΣΥΝΟΛΟ':36} {total_w:6.1f} {total_v:9.1f} {pct:6.2f}%")
    print()
    counts = {}
    for s in status.values():
        counts[s] = counts.get(s, 0) + 1
    print("κατάσταση:", " · ".join(f"{k} {v}" for k, v in sorted(counts.items())))
    print(f"gate receipt: {os.path.relpath(rpath, REPO) if rpath else 'ΚΑΝΕΝΑ'}")

    out = {
      "kind": "lawmax-progress/1",
      "catalogue_sha256": "sha256:" + hashlib.sha256(
          open(CATALOGUE, "rb").read()).hexdigest(),
      "gate_receipt": os.path.relpath(rpath, REPO) if rpath else None,
      "gate_receipt_sha256": ("sha256:" + hashlib.sha256(
          open(rpath, "rb").read()).hexdigest()) if rpath else None,
      "rule": cat["rule"],
      "total_weight": total_w, "verified_weight": total_v,
      "percent_complete": round(pct, 2),
      "by_category": {c: {**by_cat[c],
                          "percent": round(100.0 * by_cat[c]["verified"]
                                           / by_cat[c]["weight"], 2)}
                      for c in cat["category_weights"]},
      "status_counts": counts,
      "obligations": {oid: {"status": status[oid], "weight": obs[oid]["weight"],
                            "category": obs[oid]["category"], "detail": why[oid]}
                      for oid in sorted(obs)},
    }
    p = f"{REPO}/experiment/artifacts/PROGRESS-RECEIPT.json"
    tmp = p + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(out, fh, ensure_ascii=False, indent=1)
        fh.flush(); os.fsync(fh.fileno())
    os.rename(tmp, p)
    print(f"receipt: experiment/artifacts/PROGRESS-RECEIPT.json")
    return 0


sys.exit(main())
