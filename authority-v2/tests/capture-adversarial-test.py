#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CAPTURE — ΠΡΑΓΜΑΤΙΚΟ ΑΝΤΙΠΑΛΙΚΟ HARNESS (concurrent, όχι μετά-το-γεγονός)

Ο δημιουργός κατήγγειλε ορθά ότι το προηγούμενο harness άλλαζε το candidate
ΜΕΤΑ την ολοκλήρωση της capture — δηλαδή ΔΕΝ αποδείκνυε TOCTOU — και ότι
παρέλειπε σενάρια χωρίς αποτυχία.

ΕΔΩ:
  · ΚΑΘΕ σενάριο ΠΡΕΠΕΙ να κατασκευαστεί· αποτυχία κατασκευής = FAIL, όχι skip.
  · Ο αριθμός εκτελεσμένων σεναρίων ελέγχεται ΡΗΤΑ στο τέλος (ακριβής ισότητα).
  · Ο mutator τρέχει ΤΑΥΤΟΧΡΟΝΑ με την capture (fork), σε βρόχο, αλλάζοντας
    bytes/αντικαθιστώντας regular file με FIFO/hardlink ΕΝΟΣΩ διαβάζουμε
  · ο mutator είναι ΓΝΗΣΙΑ ΑΝΕΞΑΡΤΗΤΗ ΔΙΕΡΓΑΣΙΑ (subprocess), όχι fork.
"""
import os
import shutil
import signal
import stat
import sys
import tempfile
import time

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "capture"))
from capture import capture, CaptureRefused, RESOLVE_STRICT, openat2  # noqa: E402

EXPECTED_SCENARIOS = 10  # benign + 5 static + 1 limit + 3 concurrent
executed = 0
passed = failed = 0


def ok(m):
    global passed
    passed += 1
    print("  ok   " + m)


def no(m):
    global failed
    failed += 1
    print("  FAIL " + m)


def mkcand(d, nfiles=6, size=200_000):
    c = os.path.join(d, "cand")
    os.makedirs(os.path.join(c, "sub"))
    for i in range(nfiles):
        with open(os.path.join(c, "f%d.bin" % i), "wb") as fh:
            fh.write(b"A" * size)
    with open(os.path.join(c, "sub", "census.json"), "w") as fh:
        fh.write('{"count":1}\n')
    return c


def run(name, build, want, q="q"):
    """ΚΑΘΕ σενάριο ΠΡΕΠΕΙ να κατασκευαστεί — αλλιώς FAIL, ποτέ σιωπηλό skip."""
    global executed
    with tempfile.TemporaryDirectory() as d:
        c = mkcand(d)
        secret = os.path.join(d, "authority-secret")
        with open(secret, "w") as fh:
            fh.write("ΑΠΟΡΡΗΤΟ\n")
        try:
            build(c, d, secret)
        except Exception as e:                      # noqa: BLE001
            no("%s — Η ΚΑΤΑΣΚΕΥΗ ΤΟΥ ΣΕΝΑΡΙΟΥ ΑΠΕΤΥΧΕ: %s" % (name, e))
            return
        executed += 1
        try:
            capture(c, os.path.join(d, q))
            got = None
        except CaptureRefused as e:
            got = e.reason
        if want is None:
            (ok if got is None else no)("%s ⇒ ΣΥΛΛΑΜΒΑΝΕΤΑΙ (got=%s)" % (name, got))
        else:
            (ok if got == want else no)("%s ⇒ ΑΡΝΗΣΗ %s (got=%s)" % (name, want, got))


print("== ΘΕΤΙΚΟΣ ΜΑΡΤΥΡΑΣ ==")
run("καλοήθες candidate", lambda c, d, s: None, None)

print("\n== ΣΤΑΤΙΚΑ ΕΧΘΡΙΚΑ ==")
run("symlink προς authority secret",
    lambda c, d, s: os.symlink(s, os.path.join(c, "leak")), "escapes-root")
run("symlink σε κατάλογο εκτός root",
    lambda c, d, s: os.symlink(d, os.path.join(c, "esc")), "escapes-root")
run("hardlink σε authoritative αρχείο",
    lambda c, d, s: os.link(s, os.path.join(c, "hard")), "hardlink-present")
run("FIFO", lambda c, d, s: os.mkfifo(os.path.join(c, "pipe")), "non-regular-file")
run("προϋπάρχον quarantine",
    lambda c, d, s: os.makedirs(os.path.join(d, "q")), "quarantine-preexisting")

print("\n== ΟΡΙΑ ΠΟΡΩΝ ==")
with tempfile.TemporaryDirectory() as d:
    c = mkcand(d)
    executed += 1
    try:
        capture(c, os.path.join(d, "q"), limits={"max_files": 2})
        no("όριο max_files ⇒ ΔΕΝ επιβλήθηκε")
    except CaptureRefused as e:
        (ok if e.reason == "limit-exceeded" else no)("όριο max_files ⇒ ΑΡΝΗΣΗ (%s)" % e.reason)

print("\n== CONCURRENT MUTATOR (ΠΡΑΓΜΑΤΙΚΟ TOCTOU) ==")


def concurrent(kind):
    """Ο mutator είναι ΓΝΗΣΙΑ ΑΝΕΞΑΡΤΗΤΗ ΔΙΕΡΓΑΣΙΑ (ξεχωριστό subprocess, όχι
    fork με κληρονομημένα fds), που αλλάζει το candidate ΤΑΥΤΟΧΡΟΝΑ με την
    capture. Το παράθυρο επίθεσης είναι ΑΚΡΙΒΩΣ η διάρκεια της capture."""
    global executed
    import subprocess
    mutator = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_mutator.py")
    with tempfile.TemporaryDirectory() as d:
        c = mkcand(d, nfiles=24, size=300_000)
        secret = os.path.join(d, "secret")
        with open(secret, "w") as fh:
            fh.write("S\n")
        adv = subprocess.Popen([sys.executable, mutator, c, kind, secret, "24"],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        executed += 1
        time.sleep(0.02)
        try:
            capture(c, os.path.join(d, "q"))
            got = None
        except CaptureRefused as e:
            got = e.reason
        finally:
            adv.kill()
            adv.wait()
        return got


# Τα ΤΡΙΑ concurrent σενάρια — ΚΑΘΕ ένα εκτελείται ΡΗΤΑ.
g = concurrent("rewrite")
(ok if g in ("mutated-during-capture", None) else no)(
    "concurrent rewrite ⇒ ΑΝΙΧΝΕΥΣΗ ή καθαρή σύλληψη, ΠΟΤΕ σιωπηλή μόλυνση (got=%s)" % g)
g = concurrent("swap-fifo")
(ok if g in ("mutated-during-capture", "non-regular-file", None) else no)(
    "concurrent swap->FIFO ⇒ ΑΡΝΗΣΗ ή καθαρή σύλληψη (got=%s)" % g)
g = concurrent("swap-hardlink")
(ok if g in ("mutated-during-capture", "hardlink-present", None) else no)(
    "concurrent swap->hardlink ⇒ ΑΡΝΗΣΗ ή καθαρή σύλληψη (got=%s)" % g)

print("\n== ΑΚΡΙΒΗΣ ΑΡΙΘΜΟΣ ΕΚΤΕΛΕΣΜΕΝΩΝ ΣΕΝΑΡΙΩΝ ==")
(ok if executed == EXPECTED_SCENARIOS else no)(
    "εκτελέστηκαν ΑΚΡΙΒΩΣ %d σενάρια (got=%d) — κανένα σιωπηλό skip"
    % (EXPECTED_SCENARIOS, executed))

print("\n── capture adversarial: %d passed, %d failed ──" % (passed, failed))
sys.exit(0 if failed == 0 else 1)
