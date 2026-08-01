#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""LEVEL-7 COMPLETION MATRIX — ΜΗΧΑΝΙΚΟΣ ΕΛΕΓΧΟΣ (fail-closed)

Ο πίνακας δεν είναι κείμενο: είναι πύλη. Αυτός ο verifier επιβάλλει:
  1. ΚΑΘΕ γραμμή έχει status ΜΟΝΟ από το επιτρεπτό σύνολο.
  2. ΚΑΘΕ γραμμή έχει ΟΛΑ τα υποχρεωτικά πεδία.
  3. Καμία γραμμή δεν λέει PASS χωρίς actual-result που να ΜΗΝ είναι NOT-EXECUTED.
  4. Το :level7-gate είναι :not-passed όσο οποιαδήποτε φέρουσα γραμμή ≠ :proved
     — και αν κάποιος το γυρίσει σε passed χωρίς 12/12 PROVED, ΚΟΚΚΙΝΟ.
  5. Το :summary συμφωνεί με τον ΠΡΑΓΜΑΤΙΚΟ υπολογισμό από τις γραμμές
     (αδύνατη η χειροκίνητη «βαθμολογία»).

Χρήση: verify-completion-matrix.py [matrix.sexp]
Έξοδος: 0 = συνεπής · 1 = ΑΣΥΝΕΠΕΙΑ/ΨΕΥΔΟ-ΠΡΑΣΙΝΟ
"""
import os
import re
import sys

ALLOWED = {":not-started", ":implemented-not-proved", ":proved", ":externally-blocked"}
REQUIRED_KEYS = [":id", ":title", ":status", ":load-bearing", ":implementation",
                 ":proof-objects", ":command", ":actual-result",
                 ":negative-witness", ":residual-assumptions"]

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main(argv):
    path = argv[1] if len(argv) > 1 else os.path.join(HERE, "LEVEL7-COMPLETION-MATRIX.sexp")
    src = open(path, encoding="utf-8").read()
    fails = []

    # Οι γραμμές αρχίζουν με (:id <n>  — απομονώνουμε κάθε μπλοκ ως το επόμενο (:id
    # ΠΡΟΣΟΧΗ: η πρώτη γραμμή ξεκινά με «((:id» (άνοιγμα της λίστας) — το
    # split ΠΡΕΠΕΙ να την πιάνει, αλλιώς μια ολόκληρη απαίτηση γίνεται αόρατη
    # (ακριβώς το είδος σιωπηλού κενού που ο πίνακας υπάρχει για να αποκλείει).
    blocks = re.split(r"\n\s*\(+:id ", src)[1:]
    rows = []
    for b in blocks:
        body = "(:id " + b
        ident = re.match(r'\(:id\s+("?[\w"]+)', body).group(1).strip('"')
        status = re.search(r":status\s+(:[a-z-]+)", body)
        lb = re.search(r":load-bearing\s+(t|nil)", body)
        actual = re.search(r':actual-result\s+("(?:[^"\\]|\\.)*"|nil)', body, re.S)
        rows.append({
            "id": ident,
            "status": status.group(1) if status else None,
            "load_bearing": (lb.group(1) == "t") if lb else None,
            "actual": actual.group(1) if actual else None,
            "body": body,
        })

    if not rows:
        print("::error::ΚΕΝΟΣ πίνακας — fail-closed")
        return 1

    for r in rows:
        rid = r["id"]
        if r["status"] not in ALLOWED:
            fails.append("γραμμή %s: ΜΗ ΕΠΙΤΡΕΠΤΟ status %r" % (rid, r["status"]))
        for k in REQUIRED_KEYS:
            if k not in r["body"]:
                fails.append("γραμμή %s: ΑΠΟΝ υποχρεωτικό πεδίο %s" % (rid, k))
        if r["load_bearing"] is None:
            fails.append("γραμμή %s: ΑΠΡΟΣΔΙΟΡΙΣΤΟ :load-bearing" % rid)
        # PROVED απαιτεί ΕΚΤΕΛΕΣΜΕΝΟ αποτέλεσμα ΚΑΙ proof objects.
        if r["status"] == ":proved":
            if not r["actual"] or "NOT-EXECUTED" in r["actual"]:
                fails.append("γραμμή %s: :proved ΧΩΡΙΣ εκτελεσμένο actual-result" % rid)
            if re.search(r":proof-objects\s+\(\)", r["body"]):
                fails.append("γραμμή %s: :proved ΧΩΡΙΣ proof objects" % rid)
        # implemented-not-proved απαιτεί πραγματική εκτέλεση.
        if r["status"] == ":implemented-not-proved":
            if not r["actual"] or "NOT-EXECUTED" in r["actual"]:
                fails.append("γραμμή %s: :implemented-not-proved χωρίς εκτελεσμένο αποτέλεσμα" % rid)

    counts = {s: sum(1 for r in rows if r["status"] == s) for s in ALLOWED}
    load_bearing_not_proved = [r["id"] for r in rows
                               if r["load_bearing"] and r["status"] != ":proved"]

    gate = re.search(r":level7-gate\s+(:[a-z-]+)", src).group(1)
    if load_bearing_not_proved and gate != ":not-passed":
        fails.append("ΨΕΥΔΟ-ΠΡΑΣΙΝΟ: level7-gate=%s ενώ φέρουσες γραμμές ≠ :proved: %s"
                     % (gate, load_bearing_not_proved))
    if not load_bearing_not_proved and gate != ":passed":
        fails.append("ΑΣΥΝΕΠΕΙΑ: όλες οι φέρουσες PROVED αλλά gate=%s" % gate)

    # Το δηλωμένο summary ΠΡΕΠΕΙ να συμφωνεί με τον υπολογισμό.
    declared = {}
    m = re.search(r":summary\s*\((.*?)\n\s*:statement", src, re.S)
    if m:
        for k, v in re.findall(r":([a-z0-9-]+)\s+(\d+)", m.group(1)):
            declared[k] = int(v)
    computed = {
        "total": len(rows),
        "proved": counts[":proved"],
        "implemented-not-proved": counts[":implemented-not-proved"],
        "externally-blocked": counts[":externally-blocked"],
        "not-started": counts[":not-started"],
    }
    for k, v in computed.items():
        if k in declared and declared[k] != v:
            fails.append("summary %s: δηλωμένο %d ≠ υπολογισμένο %d" % (k, declared[k], v))

    print("LEVEL7 COMPLETION MATRIX — %d γραμμές" % len(rows))
    for s in (":proved", ":implemented-not-proved", ":externally-blocked", ":not-started"):
        print("  %-26s %d" % (s, counts[s]))
    print("  φέρουσες ΟΧΙ-proved      : %s" % (load_bearing_not_proved or "καμία"))
    print("  level7-gate              : %s" % gate)
    if fails:
        print("\n%d ΑΣΥΝΕΠΕΙΕΣ:" % len(fails))
        for f in fails:
            print("  ✗ " + f)
        return 1
    print("\n✓ ο πίνακας είναι ΣΥΝΕΠΗΣ (καμία ψευδο-πράσινη γραμμή)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
