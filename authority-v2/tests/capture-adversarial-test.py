#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CAPTURE — ΑΝΤΙΠΑΛΙΚΟ HARNESS **ΚΑΙ** ΠΡΑΓΜΑΤΙΚΟ FIXED-POINT

ΕΤΥΜΗΓΟΡΙΑ ΔΗΜΙΟΥΡΓΟΥ (P1): «το concurrent test δέχεται ρητά ψευδώς-πράσινο —
δέχεται `None` ως επιτυχία και ΔΕΝ ελέγχει ποτέ quarantine↔census↔snapshot_root».
ΟΡΘΟ. Η απάντηση ΔΕΝ είναι ένας ακόμη έλεγχος δίπλα στον παλιό· είναι ότι το
`None` **παύει να είναι αποδεκτό απο μόνο του**:

    ΚΑΘΕ καθαρή σύλληψη, σε ΚΑΘΕ σενάριο, περνά ΥΠΟΧΡΕΩΤΙΚΑ από το
    `fixed_point()` πριν χαρακτηριστεί ok. Δεν υπάρχει διαδρομή που δέχεται
    σύλληψη χωρίς επαναμέτρηση — η κλάση «ψευδώς πράσινο» εξαλείφεται δομικά.

ΤΟ FIXED POINT ΕΧΕΙ ΤΡΙΑ ΑΝΕΞΑΡΤΗΤΑ ΣΚΕΛΗ:
  ① ΙΔΙΑ ΕΔΡΑ, ΔΕΥΤΕΡΗ ΑΝΑΓΝΩΣΗ — `measure()` ξανά πάνω στο quarantine:
     census, snapshot_root, release_root ΟΦΕΙΛΟΥΝ να είναι ταυτόσημα.
  ② ΑΝΕΞΑΡΤΗΤΗ ΥΛΟΠΟΙΗΣΗ (N-version) — `os.walk` + τα πρωτόγονα του
     deployment/verify/verify-merkle.py (ξεχωριστός συγγραφέας, ξεχωριστό
     αρχείο, καμία κοινή γραμμή με την capture) ΚΑΙ ανεξάρτητη επανυλοποίηση
     της κωδικοποίησης snapshot-entry.
  ③ ΣΥΝΟΧΗ ΠΕΡΙΕΧΟΜΕΝΟΥ — κάθε συλληφθέν f*.bin ΟΦΕΙΛΕΙ να είναι ομοιογενές
     (μία «γενιά» του αντιπάλου) και ΚΑΝΕΝΑ συλληφθέν byte δεν επιτρέπεται να
     περιέχει το authority secret. Μείγμα γενιών = σχισμένη ανάγνωση· secret
     μέσα στο bundle = διαρροή μέσω hardlink. Και τα δύο ⇒ FAIL.

Ο mutator είναι ΓΝΗΣΙΑ ΑΝΕΞΑΡΤΗΤΗ ΔΙΕΡΓΑΣΙΑ (subprocess), όχι fork.
Κάθε σενάριο ΠΡΕΠΕΙ να κατασκευαστεί· αποτυχία κατασκευής = FAIL, όχι skip.
Ο αριθμός εκτελεσμένων σεναρίων ελέγχεται ΡΗΤΑ με ακριβή ισότητα.
"""
import hashlib
import importlib.util
import os
import subprocess
import sys
import tempfile
import time

_HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(_HERE))
sys.path.insert(0, os.path.join(REPO, "authority-v2", "capture"))
from capture import capture, measure, CaptureRefused, PREFIX, CHUNK  # noqa: E402

# ── ΑΝΕΞΑΡΤΗΤΗ ΕΔΡΑ MERKLE: το committed N-version verifier, ΟΧΙ η capture ────
_spec = importlib.util.spec_from_file_location(
    "indep_merkle", os.path.join(REPO, "deployment", "verify", "verify-merkle.py"))
_indep = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_indep)

SECRET_MARKER = b"APORRHTO-AUTHORITY-SECRET-DO-NOT-CAPTURE"
GENERATIONS = set(b"ABCDEFGH")
EXPECTED_SCENARIOS = 10          # benign + 5 static + 1 limit + 3 concurrent
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


# ═════════════════════════════════════════════════════════════════════════════
# ΑΝΕΞΑΡΤΗΤΗ ΕΠΑΝΑΜΕΤΡΗΣΗ — ούτε μία γραμμή κοινή με την capture.py
# ═════════════════════════════════════════════════════════════════════════════
SNAP_DOMAIN = b"lawmax-snapshot-entry-v1\x00"


def independent_measure(qdir, canonical=()):
    """os.walk + πρωτόγονα του verify-merkle.py + χειρόγραφη κωδικοποίηση."""
    rows = []
    for dirpath, dirnames, filenames in os.walk(qdir):
        dirnames.sort()
        for fn in sorted(filenames):
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, qdir)
            with open(full, "rb") as fh:
                raw = fh.read()
            rows.append({"path": rel, "size": len(raw), "raw": raw,
                         "sha256": hashlib.sha256(raw).hexdigest(),
                         "leaf": _indep.leaf_hash_bytes(raw)})
    rows.sort(key=lambda r: r["path"].encode("utf-8"))
    snap_leaves = []
    for r in rows:
        p = r["path"].encode("utf-8")
        rec = (SNAP_DOMAIN + len(p).to_bytes(8, "big") + p
               + r["size"].to_bytes(8, "big")
               + bytes.fromhex(r["leaf"][len(PREFIX):]))
        snap_leaves.append(_indep.leaf_hash_bytes(rec))
    by = {r["path"]: r for r in rows}
    rel_root = _indep.mth([by[f]["leaf"] for f in canonical]) if canonical else None
    return {"rows": rows, "snapshot_root": _indep.mth(snap_leaves),
            "release_root": rel_root}


def fixed_point(name, result, canonical=(), coherence=False):
    """ΥΠΟΧΡΕΩΤΙΚΟ για ΚΑΘΕ καθαρή σύλληψη. Επιστρέφει True μόνο αν ΟΛΑ ισχύουν."""
    q = result["quarantine"]
    good = True

    # ① ίδια έδρα, δεύτερη ανάγνωση του ΣΦΡΑΓΙΣΜΕΝΟΥ quarantine
    again = measure(q, canonical_files=canonical)
    if (again["snapshot_root"] != result["snapshot_root"]
            or again["release_root"] != result["release_root"]
            or again["census"] != result["census"]):
        no("%s ① επαναμέτρηση ΔΙΑΦΕΡΕΙ — ΔΕΝ είναι fixed point" % name)
        good = False

    # ② ανεξάρτητη υλοποίηση
    ind = independent_measure(q, canonical)
    if ind["snapshot_root"] != result["snapshot_root"]:
        no("%s ② snapshot_root ≠ ανεξάρτητης υλοποίησης (%s vs %s)"
           % (name, result["snapshot_root"][:24], ind["snapshot_root"][:24]))
        good = False
    if ind["release_root"] != result["release_root"]:
        no("%s ② release_root ≠ ανεξάρτητης υλοποίησης" % name)
        good = False
    icen = [(r["path"], r["size"], r["sha256"]) for r in ind["rows"]]
    ccen = [(e["path"], e["size"], e["sha256"]) for e in result["census"]]
    if icen != ccen:
        no("%s ② census ≠ των bytes του quarantine" % name)
        good = False

    # ③ συνοχή περιεχομένου + καμία διαρροή authority secret
    for r in ind["rows"]:
        if SECRET_MARKER in r["raw"]:
            no("%s ③ ΔΙΑΡΡΟΗ: το authority secret βρέθηκε στο %s" % (name, r["path"]))
            good = False
        if coherence and r["path"].startswith("f") and r["path"].endswith(".bin"):
            # ΤΟ ΚΡΙΤΗΡΙΟ ΕΙΝΑΙ Η ΜΕΙΞΗ, ΟΧΙ ΤΟ ΜΕΓΕΘΟΣ. Στα swap σενάρια ο
            # αντίπαλος κάνει unlink+create: ένα ΚΕΝΟ αρχείο (0 γενιές) είναι
            # ΝΟΜΙΜΗ στιγμιαία κατάσταση του δίσκου, όχι μόλυνση — το harness
            # δεν επιτρέπεται να κατηγορεί σωστή συμπεριφορά. ΜΟΛΥΝΣΗ είναι
            # ΑΚΡΙΒΩΣ η συνύπαρξη ΔΥΟ ή περισσότερων γενιών στο ΙΔΙΟ αντίγραφο
            # (σχισμένη ανάγνωση) ή byte εκτός του αλφαβήτου του αντιπάλου.
            alphabet = set(r["raw"])
            if len(alphabet) > 1 or not alphabet <= GENERATIONS:
                no("%s ③ ΣΙΩΠΗΛΗ ΜΟΛΥΝΣΗ: το %s αναμειγνύει %d γενιές"
                   % (name, r["path"], len(alphabet)))
                good = False
    return good


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
        with open(secret, "wb") as fh:
            fh.write(SECRET_MARKER + b"\n")
        try:
            build(c, d, secret)
        except Exception as e:                      # noqa: BLE001
            no("%s — Η ΚΑΤΑΣΚΕΥΗ ΤΟΥ ΣΕΝΑΡΙΟΥ ΑΠΕΤΥΧΕ: %s" % (name, e))
            return
        executed += 1
        canon = ["f0.bin", "sub/census.json"]
        res, got = None, None
        try:
            res = capture(c, os.path.join(d, q), canonical_files=canon)
        except CaptureRefused as e:
            got = e.reason
        if want is None:
            # ΚΑΘΑΡΗ ΣΥΛΛΗΨΗ ⇒ ΥΠΟΧΡΕΩΤΙΚΟ fixed point. Χωρίς αυτό, ΟΧΙ ok.
            if got is not None:
                no("%s ⇒ ΑΝΑΜΕΝΟΤΑΝ σύλληψη (got=%s)" % (name, got))
            elif fixed_point(name, res, canon):
                ok("%s ⇒ ΣΥΛΛΑΜΒΑΝΕΤΑΙ + fixed point ①②③" % name)
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
# ΤΟ ΜΕΓΕΘΟΣ ΕΙΝΑΙ ΜΕΡΟΣ ΤΗΣ ΑΠΟΔΕΙΞΗΣ, ΟΧΙ ΡΥΘΜΙΣΗ: με αρχείο μικρότερο του
# chunk ανάγνωσης (capture.CHUNK = 1 MiB) ολόκληρο το αρχείο διαβάζεται με ΜΙΑ
# os.read και η σχισμένη ανάγνωση είναι φυσικά αδύνατη — το σενάριο θα ήταν
# ΚΕΝΟ (ο μάρτυρας μεταλλάξεων το απέδειξε: η κατάργηση του fingerprint check
# επιζούσε). Απαιτούμε ΠΟΛΛΑΠΛΕΣ αναγνώσεις ανά αρχείο.
NF = 8
CONC_SIZE = 4 * CHUNK
assert CONC_SIZE > CHUNK, "το σενάριο θα ήταν κενό"


def concurrent(name, kind, allowed):
    """Ο mutator τρέχει ΤΑΥΤΟΧΡΟΝΑ με την capture, σε ξεχωριστή διεργασία.
    Καθαρή σύλληψη γίνεται δεκτή ΜΟΝΟ αν περάσει το fixed point ①②③."""
    global executed
    mutator = os.path.join(_HERE, "_mutator.py")
    with tempfile.TemporaryDirectory() as d:
        c = mkcand(d, nfiles=NF, size=CONC_SIZE)
        secret = os.path.join(d, "secret")
        with open(secret, "wb") as fh:
            fh.write(SECRET_MARKER + b"\n")
        adv = subprocess.Popen([sys.executable, mutator, c, kind, secret,
                                str(NF), str(CONC_SIZE)],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        executed += 1
        time.sleep(0.02)
        canon = ["f0.bin", "sub/census.json"]
        res, got = None, None
        try:
            res = capture(c, os.path.join(d, "q"), canonical_files=canon)
        except CaptureRefused as e:
            got = e.reason
        finally:
            adv.kill()
            adv.wait()
        if got is None:
            if fixed_point(name, res, canon, coherence=True):
                ok("%s ⇒ ΚΑΘΑΡΗ ΣΥΛΛΗΨΗ + fixed point ①②③ (καμία μόλυνση)" % name)
        elif got in allowed:
            ok("%s ⇒ ΑΡΝΗΣΗ %s" % (name, got))
        else:
            no("%s ⇒ ΑΝΕΠΙΤΡΕΠΤΟ αποτέλεσμα: %s" % (name, got))


concurrent("concurrent rewrite", "rewrite", ("mutated-during-capture",))
# «canonical-missing»: ο αντίπαλος έκανε unlink το f0.bin ΤΗ ΣΤΙΓΜΗ της
# απαρίθμησης. Είναι ΟΡΘΗ, fail-closed άρνηση (το canonical αρχείο απουσιάζει),
# όχι σφάλμα — και σίγουρα όχι σιωπηλή αποδοχή.
concurrent("concurrent swap->FIFO", "swap-fifo",
           ("mutated-during-capture", "non-regular-file", "open-refused",
            "canonical-missing"))
concurrent("concurrent swap->hardlink", "swap-hardlink",
           ("mutated-during-capture", "hardlink-present", "open-refused",
            "canonical-missing"))

print("\n== ΑΚΡΙΒΗΣ ΑΡΙΘΜΟΣ ΕΚΤΕΛΕΣΜΕΝΩΝ ΣΕΝΑΡΙΩΝ ==")
(ok if executed == EXPECTED_SCENARIOS else no)(
    "εκτελέστηκαν ΑΚΡΙΒΩΣ %d σενάρια (got=%d) — κανένα σιωπηλό skip"
    % (EXPECTED_SCENARIOS, executed))

print("\n── capture adversarial + fixed point: %d passed, %d failed ──" % (passed, failed))
sys.exit(0 if failed == 0 else 1)
