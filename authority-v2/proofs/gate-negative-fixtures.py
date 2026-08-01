#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ΑΡΝΗΤΙΚΑ FIXTURES ΓΙΑ ΤΙΣ ΔΥΟ ΠΥΛΕΣ ΤΗΣ ΤΙΜΙΟΤΗΤΑΣ

Ο LEVEL7-COMPLETION-MATRIX και το PROOF-MANIFEST είναι πύλες. Μια πύλη που δεν
απορρίπτει τίποτα είναι ταυτολογία. Εδώ κατασκευάζονται ΠΡΑΓΜΑΤΙΚΑ ψευδο-πράσινα
σενάρια — ακριβώς αυτά που θα έκανε κάποιος για να δηλώσει πρόωρα Level-7 — και
απαιτείται από κάθε verifier να τα ΚΑΤΑΓΓΕΙΛΕΙ.

Θετικός μάρτυρας: τα ΠΡΑΓΜΑΤΙΚΑ αρχεία πρέπει να ΠΕΡΝΟΥΝ — αλλιώς το fixture θα
«περνούσε» και με σπασμένο verifier.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
AV2 = os.path.dirname(HERE)   # authority-v2/  (το proofs/ είναι ΜΕΣΑ του)
MATRIX = os.path.join(AV2, "LEVEL7-COMPLETION-MATRIX.sexp")
PROOFS = os.path.join(AV2, "proof-manifest.sexp")
MATRIX_V = os.path.join(HERE, "verify-completion-matrix.py")
PROOFS_V = os.path.join(HERE, "verify-proof-manifest.py")

passed = failed = 0


def ok(m):
    global passed
    passed += 1
    print("  ok   " + m)


def no(m):
    global failed
    failed += 1
    print("  FAIL " + m)


def run(verifier, path):
    r = subprocess.run([sys.executable, verifier, path],
                       capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def case(name, verifier, src, mutate, want_reject, needle=None):
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, os.path.basename(src))
        shutil.copy(src, p)
        text = open(p, encoding="utf-8").read()
        new = mutate(text)
        if new == text and mutate is not identity:
            no("%s — Η ΜΕΤΑΛΛΑΞΗ ΔΕΝ ΕΦΑΡΜΟΣΤΗΚΕ (anchor δεν βρέθηκε)" % name)
            return
        open(p, "w", encoding="utf-8").write(new)
        rc, out = run(verifier, p)
        rejected = rc != 0
        cond = (rejected == want_reject) and (needle is None or needle in out)
        (ok if cond else no)("%s (rc=%d, αναμ. %s)"
                             % (name, rc, "ΑΠΟΡΡΙΨΗ" if want_reject else "ΑΠΟΔΟΧΗ"))
        if not cond:
            print("      ── έξοδος ──\n" + "\n".join("      " + l for l in out.splitlines()[:12]))


def identity(t):
    return t


print("== ΘΕΤΙΚΟΙ ΜΑΡΤΥΡΕΣ: τα ΠΡΑΓΜΑΤΙΚΑ αρχεία περνούν ==")
case("matrix ως έχει ⇒ ΑΠΟΔΟΧΗ", MATRIX_V, MATRIX, identity, want_reject=False)
case("proof-manifest ως έχει ⇒ ΑΠΟΔΟΧΗ", PROOFS_V, PROOFS, identity, want_reject=False)

print("\n== COMPLETION MATRIX: κάθε ψευδο-πράσινο ΚΑΤΑΓΓΕΛΛΕΤΑΙ ==")

case("gate δηλωμένο :passed ενώ φέρουσες ≠ PROVED ⇒ ΑΠΟΡΡΙΨΗ", MATRIX_V, MATRIX,
     lambda t: t.replace(":level7-gate :not-passed", ":level7-gate :passed", 1),
     want_reject=True, needle="ΨΕΥΔΟ-ΠΡΑΣΙΝΟ")

# ΑΚΡΙΒΗΣ ΣΤΟΧΟΣ: γραμμή που ΟΝΤΩΣ έχει κενά proof-objects (:not-started) —
# αλλιώς η απόρριψη θα ερχόταν από άλλον κανόνα και ο μάρτυρας θα ήταν θολός.
case("γραμμή :proved ΧΩΡΙΣ proof objects ⇒ ΑΠΟΡΡΙΨΗ", MATRIX_V, MATRIX,
     lambda t: t.replace(":status :not-started", ":status :proved", 1),
     want_reject=True, needle="ΧΩΡΙΣ proof objects")

case("επινοημένο status εκτός λεξιλογίου ⇒ ΑΠΟΡΡΙΨΗ", MATRIX_V, MATRIX,
     lambda t: t.replace(":status :not-started", ":status :mostly-done", 1),
     want_reject=True, needle="ΜΗ ΕΠΙΤΡΕΠΤΟ")

case("χειροκίνητη «βαθμολογία» στο summary ⇒ ΑΠΟΡΡΙΨΗ", MATRIX_V, MATRIX,
     lambda t: re.sub(r":proved 0", ":proved 9", t, count=1),
     want_reject=True, needle="summary")

case("αφαίρεση υποχρεωτικού πεδίου (:negative-witness) ⇒ ΑΠΟΡΡΙΨΗ", MATRIX_V, MATRIX,
     lambda t: t.replace(":negative-witness", ":xx-witness", 1),
     want_reject=True, needle="ΑΠΟΝ υποχρεωτικό")

case("γραμμή IMPLEMENTED-NOT-PROVED με NOT-EXECUTED ⇒ ΑΠΟΡΡΙΨΗ", MATRIX_V, MATRIX,
     lambda t: t.replace(
         ':actual-result "EXECUTED 2026-07-31: 5 ok, 0 FAIL — producer⇒EACCES, reader⇒EACCES, authority γράφει, producer γράφει candidates, reader διαβάζει"',
         ':actual-result "NOT-EXECUTED"', 1),
     want_reject=True, needle="χωρίς εκτελεσμένο")

print("\n== PROOF MANIFEST: κάθε ψευδο-πράσινο ΚΑΤΑΓΓΕΛΛΕΤΑΙ ==")

case("θεώρημα :proved χωρίς artifact ⇒ ΑΠΟΡΡΙΨΗ", PROOFS_V, PROOFS,
     lambda t: t.replace(":status :blocked-toolchain", ":status :proved", 1),
     want_reject=True, needle=":proved")

case("gate :passed ενώ φέροντα blocked ⇒ ΑΠΟΡΡΙΨΗ", PROOFS_V, PROOFS,
     lambda t: t.replace(":gate :not-passed", ":gate :passed", 1),
     want_reject=True, needle="ΨΕΥΔΟ-ΠΡΑΣΙΝΟ")

case("summary που δεν συμφωνεί με τις γραμμές ⇒ ΑΠΟΡΡΙΨΗ", PROOFS_V, PROOFS,
     lambda t: t.replace(":total 17 :proved 0", ":total 17 :proved 17", 1),
     want_reject=True, needle="summary")

case("επινοημένο status θεωρήματος ⇒ ΑΠΟΡΡΙΨΗ", PROOFS_V, PROOFS,
     lambda t: t.replace(":status :blocked-toolchain", ":status :probably-fine", 1),
     want_reject=True, needle="ΜΗ ΕΠΙΤΡΕΠΤΟ")

print("\n── gate negative fixtures: %d passed, %d failed ──" % (passed, failed))
sys.exit(0 if failed == 0 else 1)
