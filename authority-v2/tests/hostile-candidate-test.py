#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ΑΝΤΙΠΑΛΙΚΟ HARNESS: το candidates/ ΕΙΝΑΙ ΕΧΘΡΙΚΗ ΜΕΤΑΒΛΗΤΗ ΕΙΣΟΔΟΣ

Κατασκευάζει ΠΡΑΓΜΑΤΙΚΑ εχθρικά candidates — symlink escape, hardlink σε
authoritative αρχείο, path traversal, non-regular file, ψευδής δηλωμένος root —
και απαιτεί ΑΡΝΗΣΗ. Θετικός μάρτυρας: το ΚΑΛΟΗΘΕΣ candidate συλλαμβάνεται.

Αποδεικνύει επίσης το κρίσιμο: μετά τη σύλληψη, μεταβολή του candidates/ ΔΕΝ
αλλάζει το συλληφθέν snapshot (το TOCTOU κλείνει).
"""
import os
import shutil
import sys
import tempfile

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "capture"))
from reference_capture import capture, CaptureRefused  # noqa: E402

passed = failed = 0


def ok(m):
    global passed
    passed += 1
    print("  ok   " + m)


def no(m):
    global failed
    failed += 1
    print("  FAIL " + m)


def benign(root):
    os.makedirs(os.path.join(root, "sub"), exist_ok=True)
    with open(os.path.join(root, "manifest.ttl"), "w") as fh:
        fh.write("@prefix ex: <x> .\n")
    with open(os.path.join(root, "sub", "census.json"), "w") as fh:
        fh.write('{"count":1}\n')


def scenario(name, build, want_reason):
    with tempfile.TemporaryDirectory() as d:
        cand = os.path.join(d, "candidates", "sha256-deadbeef")
        os.makedirs(cand)
        secret = os.path.join(d, "authority-secret.txt")
        with open(secret, "w") as fh:
            fh.write("ΑΠΟΡΡΗΤΟ AUTHORITY STATE\n")
        benign(cand)
        try:
            build(cand, d, secret)
        except OSError as e:
            print("      (το σενάριο δεν κατασκευάστηκε: %s) — παραλείπεται" % e)
            return
        q = os.path.join(d, "quarantine")
        try:
            capture(cand, q)
            got = None
        except CaptureRefused as e:
            got = e.reason
        if want_reason is None:
            (ok if got is None else no)("%s ⇒ ΣΥΛΛΑΜΒΑΝΕΤΑΙ (got=%s)" % (name, got))
        else:
            (ok if got == want_reason else no)(
                "%s ⇒ ΑΡΝΗΣΗ %s (got=%s)" % (name, want_reason, got))


print("== ΘΕΤΙΚΟΣ ΜΑΡΤΥΡΑΣ ==")
scenario("καλοήθες candidate", lambda c, d, s: None, None)

print("\n== ΕΧΘΡΙΚΑ CANDIDATES ==")
scenario("symlink που δείχνει ΕΞΩ (authority secret)",
         lambda c, d, s: os.symlink(s, os.path.join(c, "leak.txt")),
         "symlink-present")

scenario("symlink σε κατάλογο εκτός root",
         lambda c, d, s: os.symlink(d, os.path.join(c, "escape")),
         "symlink-present")

scenario("hardlink σε authoritative αρχείο",
         lambda c, d, s: os.link(s, os.path.join(c, "hard.txt")),
         "hardlink-present")

scenario("FIFO (non-regular file)",
         lambda c, d, s: os.mkfifo(os.path.join(c, "pipe")),
         "non-regular-file")

print("\n== ΨΕΥΔΗΣ ΔΗΛΩΜΕΝΟΣ ROOT ==")
with tempfile.TemporaryDirectory() as d:
    cand = os.path.join(d, "cand")
    os.makedirs(cand)
    benign(cand)
    try:
        capture(cand, os.path.join(d, "q"), declared_root="sha256:" + "0" * 64)
        no("ψευδής δηλωμένος root ⇒ ΕΓΙΝΕ ΔΕΚΤΟΣ")
    except CaptureRefused as e:
        (ok if e.reason == "declared-root-mismatch" else no)(
            "ψευδής δηλωμένος root ⇒ ΑΡΝΗΣΗ (%s)" % e.reason)

print("\n== ΤΟ TOCTOU ΚΛΕΙΝΕΙ: μετά τη σύλληψη, το candidates/ ΔΕΝ μετράει ==")
with tempfile.TemporaryDirectory() as d:
    cand = os.path.join(d, "cand")
    os.makedirs(cand)
    benign(cand)
    q = os.path.join(d, "q")
    r1 = capture(cand, q)
    # Ο producer αλλάζει το candidate ΜΕΤΑ τη σύλληψη — ό,τι ακριβώς θα έκανε.
    with open(os.path.join(cand, "manifest.ttl"), "w") as fh:
        fh.write("ΔΗΛΗΤΗΡΙΑΣΜΕΝΟ\n")
    with open(os.path.join(q, "manifest.ttl")) as fh:
        quarantined = fh.read()
    ok("το quarantine ΔΕΝ μολύνθηκε") if "ΔΗΛΗΤΗΡΙΑΣΜΕΝΟ" not in quarantined else \
        no("το quarantine ΜΟΛΥΝΘΗΚΕ")
    r2 = capture(cand, os.path.join(d, "q2"))
    (ok if r1["root"] != r2["root"] else no)(
        "νέα σύλληψη ⇒ ΔΙΑΦΟΡΕΤΙΚΟΣ root (η αλλαγή είναι ΟΡΑΤΗ, όχι σιωπηλή)")

print("\n── hostile candidate: %d passed, %d failed ──" % (passed, failed))
sys.exit(0 if failed == 0 else 1)
