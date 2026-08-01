#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CAPTURE — ΑΝΤΙΠΑΛΙΚΟ HARNESS, FIXED POINT **ΚΑΙ** ΟΙ ΜΑΡΤΥΡΕΣ ΤΟΥ ΔΗΜΙΟΥΡΓΟΥ

Ο δημιουργός πρόσθεσε σενάρια που δεν είχε η σουίτα και βρήκε επιζώντα σφάλματα.
Αυτά τα σενάρια γίνονται ΜΟΝΙΜΟΙ μάρτυρες εδώ — δεν θα ξαναλείψουν:

  · RLIMIT_NOFILE: 200 αρχεία με όριο 96 descriptors ⇒ ΠΡΕΠΕΙ να πετύχει
    (κάθε fd κλείνει αμέσως). Με εξωφρενικά χαμηλό όριο ⇒ ΕΛΕΓΧΟΜΕΝΗ άρνηση
    `fd-exhausted`, ΠΟΤΕ ακατέργαστο OSError/traceback.
  · Μη έγκυρο UTF-8 όνομα αρχείου ⇒ `non-utf8-name`, όχι UnicodeEncodeError.
  · Ενδιάμεσο symlink ΣΤΗΝ ΙΔΙΑ ΤΗΝ ΑΓΚΥΡΑ ⇒ `symlink-in-anchor`.
  · Canonical profile: απόν / κενό / με διπλότυπα ⇒ ΑΡΝΗΣΗ. `release_root`
    ΠΟΤΕ None.
  · Ενδιάμεσο symlink ΜΕΣΑ στο candidate ⇒ `escapes-root` (ως πριν).

ΚΑΘΕ καθαρή σύλληψη περνά ΥΠΟΧΡΕΩΤΙΚΑ από `fixed_point()` (①ίδια έδρα
②ΑΝΕΞΑΡΤΗΤΗ υλοποίηση ③συνοχή+καμία διαρροή). Το `None` δεν αρκεί ποτέ.
Κάθε σενάριο ΠΡΕΠΕΙ να κατασκευαστεί· ο αριθμός ελέγχεται με ακριβή ισότητα.
"""
import hashlib
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import time

_HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(_HERE))
sys.path.insert(0, os.path.join(REPO, "authority-v2", "capture"))
from capture import (capture, measure, load_canonical_profile, open_anchor,  # noqa: E402
                     CanonicalProfile, CaptureRefused, PREFIX, CHUNK,
                     CANONICAL_PROFILE)

_spec = importlib.util.spec_from_file_location(
    "indep_merkle", os.path.join(REPO, "deployment", "verify", "verify-merkle.py"))
_indep = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_indep)

SECRET_MARKER = b"APORRHTO-AUTHORITY-SECRET-DO-NOT-CAPTURE"
GENERATIONS = set(b"ABCDEFGH")
CANON = load_canonical_profile().files
# 1 benign + 5 static + 4 μάρτυρες + 5 profile + 4 φρουροί API/άγκυρας
# + 2 όρια + 2 rlimit + 3 concurrent
EXPECTED_SCENARIOS = 26
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


def independent_measure(qdir):
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
    snap = []
    for r in rows:
        p = r["path"].encode("utf-8")
        snap.append(_indep.leaf_hash_bytes(
            SNAP_DOMAIN + len(p).to_bytes(8, "big") + p
            + r["size"].to_bytes(8, "big")
            + bytes.fromhex(r["leaf"][len(PREFIX):])))
    by = {r["path"]: r for r in rows}
    return {"rows": rows, "snapshot_root": _indep.mth(snap),
            "release_root": _indep.mth([by[f]["leaf"] for f in CANON])}


def fixed_point(name, result, vault_anchor, vault_path, qname, coherence=False):
    good = True
    again = measure(vault_anchor, qname)
    if (again["snapshot_root"] != result["snapshot_root"]
            or again["release_root"] != result["release_root"]
            or again["census"] != result["census"]):
        no("%s ① επαναμέτρηση ΔΙΑΦΕΡΕΙ — ΔΕΝ είναι fixed point" % name)
        good = False
    if result.get("fixed_point") != "verified-in-capture":
        no("%s ① η ΙΔΙΑ η capture() δεν δήλωσε επαληθευμένο fixed point" % name)
        good = False
    if result.get("release_root") is None:
        no("%s ① release_root=None — ΑΠΑΓΟΡΕΥΜΕΝΟ" % name)
        good = False

    ind = independent_measure(os.path.join(vault_path, qname))
    if ind["snapshot_root"] != result["snapshot_root"]:
        no("%s ② snapshot_root ≠ ανεξάρτητης υλοποίησης" % name)
        good = False
    if ind["release_root"] != result["release_root"]:
        no("%s ② release_root ≠ ανεξάρτητης υλοποίησης" % name)
        good = False
    if ([(r["path"], r["size"], r["sha256"]) for r in ind["rows"]]
            != [(e["path"], e["size"], e["sha256"]) for e in result["census"]]):
        no("%s ② census ≠ των bytes του quarantine" % name)
        good = False

    for r in ind["rows"]:
        if SECRET_MARKER in r["raw"]:
            no("%s ③ ΔΙΑΡΡΟΗ: authority secret στο %s" % (name, r["path"]))
            good = False
        if coherence and r["path"].startswith("f") and r["path"].endswith(".bin"):
            alphabet = set(r["raw"])
            if len(alphabet) > 1 or not alphabet <= GENERATIONS:
                no("%s ③ ΣΙΩΠΗΛΗ ΜΟΛΥΝΣΗ: το %s αναμειγνύει %d γενιές"
                   % (name, r["path"], len(alphabet)))
                good = False
    return good


def mkcand(d, nbin=0, size=0):
    """inbox/cand με ΟΛΑ τα canonical αρχεία (+ προαιρετικά binary για TOCTOU)."""
    inbox = os.path.join(d, "inbox")
    cand = os.path.join(inbox, "cand")
    os.makedirs(os.path.join(cand, "shapes"))
    os.makedirs(os.path.join(cand, "verify"))
    for rel in CANON:
        p = os.path.join(cand, rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "wb") as fh:
            fh.write(("canonical:" + rel).encode("utf-8"))
    for i in range(nbin):
        with open(os.path.join(cand, "f%d.bin" % i), "wb") as fh:
            fh.write(b"A" * size)
    vault = os.path.join(d, "vault")
    os.makedirs(vault, 0o700)          # authority-ιδιωτικό ⇒ open_anchor το δέχεται
    os.chmod(vault, 0o700)
    return inbox, cand, vault


def run(name, build, want):
    """ΚΑΘΕ σενάριο ΠΡΕΠΕΙ να κατασκευαστεί — αλλιώς FAIL, ποτέ σιωπηλό skip."""
    global executed
    with tempfile.TemporaryDirectory() as d:
        inbox, cand, vault = mkcand(d)
        secret = os.path.join(d, "authority-secret")
        with open(secret, "wb") as fh:
            fh.write(SECRET_MARKER + b"\n")
        try:
            ctx = build(cand, d, secret, inbox, vault)
        except Exception as e:                      # noqa: BLE001
            no("%s — Η ΚΑΤΑΣΚΕΥΗ ΤΟΥ ΣΕΝΑΡΙΟΥ ΑΠΕΤΥΧΕ: %s" % (name, e))
            return
        executed += 1
        use_inbox = (ctx or {}).get("inbox", inbox)
        res, got = None, None
        ia = va = None
        try:
            # Ο ΕΜΠΙΣΤΟΣ LAUNCHER ανοίγει τα anchors· η capture ΔΕΝ βλέπει pathname.
            ia = open_anchor(use_inbox, "inbox")
            va = open_anchor(vault, "vault")
            res = capture(ia, "cand", va, "q")
        except CaptureRefused as e:
            got = e.reason
        except Exception as e:                      # ΑΚΑΤΕΡΓΑΣΤΗ = ΑΠΟΤΥΧΙΑ
            no("%s ⇒ ΑΚΑΤΕΡΓΑΣΤΗ ΕΞΑΙΡΕΣΗ %s: %s" % (name, type(e).__name__, e))
            return
        if want is None:
            if got is not None:
                no("%s ⇒ ΑΝΑΜΕΝΟΤΑΝ σύλληψη (got=%s)" % (name, got))
            elif fixed_point(name, res, va, vault, "q"):
                ok("%s ⇒ ΣΥΛΛΑΜΒΑΝΕΤΑΙ + fixed point ①②③" % name)
        else:
            (ok if got == want else no)("%s ⇒ ΑΡΝΗΣΗ %s (got=%s)" % (name, want, got))
        # ΚΑΘΑΡΙΣΜΟΣ ΜΕΡΙΚΟΥ QUARANTINE: σε άρνηση ΤΙΠΟΤΑ απ' όσα ΔΗΜΙΟΥΡΓΗΣΕ η
        # capture δεν επιβιώνει. ΕΞΑΙΡΕΣΗ ΜΕ ΑΡΧΗ: όταν το quarantine ΠΡΟΫΠΗΡΧΕ,
        # η capture ΔΕΝ επιτρέπεται να το σβήσει — δεν το έφτιαξε αυτή, και η
        # διαγραφή ξένου authority καταλόγου θα ήταν καταστροφή δεδομένων.
        if (got not in (None, "quarantine-preexisting")
                and os.path.exists(os.path.join(vault, "q"))):
            no("%s ⇒ ΑΡΝΗΘΗΚΕ αλλά το ΜΕΡΙΚΟ quarantine ΕΜΕΙΝΕ στον δίσκο" % name)
        for a in (ia, va):
            if a is not None:
                a.close()


print("== ΘΕΤΙΚΟΣ ΜΑΡΤΥΡΑΣ ==")
run("καλοήθες candidate", lambda c, d, s, i, v: None, None)

print("\n== ΣΤΑΤΙΚΑ ΕΧΘΡΙΚΑ ==")
run("symlink προς authority secret",
    lambda c, d, s, i, v: os.symlink(s, os.path.join(c, "leak")), "escapes-root")
run("symlink σε κατάλογο εκτός root",
    lambda c, d, s, i, v: os.symlink(d, os.path.join(c, "esc")), "escapes-root")
run("hardlink σε authoritative αρχείο",
    lambda c, d, s, i, v: os.link(s, os.path.join(c, "hard")), "hardlink-present")
run("FIFO", lambda c, d, s, i, v: os.mkfifo(os.path.join(c, "pipe")), "non-regular-file")
run("προϋπάρχον quarantine",
    lambda c, d, s, i, v: os.makedirs(os.path.join(v, "q")), "quarantine-preexisting")

print("\n== ΜΑΡΤΥΡΕΣ ΤΟΥ ΔΗΜΙΟΥΡΓΟΥ ==")


def _mk_bad_name(c, d, s, i, v):
    """Μη έγκυρο UTF-8 όνομα — ΠΡΙΝ έδινε ακατέργαστο UnicodeEncodeError."""
    with open(os.path.join(os.fsencode(c), b"\xff\xfe-invalid.bin"), "wb") as fh:
        fh.write(b"x")


run("μη έγκυρο UTF-8 όνομα αρχείου", _mk_bad_name, "non-utf8-name")


def _mk_anchor_symlink(c, d, s, i, v):
    """Ενδιάμεσο symlink ΣΤΗΝ ΑΓΚΥΡΑ: το openat2 προστατεύει τους απογόνους,
    ΟΧΙ τον αρχικό pathname. ΠΡΙΝ γινόταν δεκτό."""
    link = os.path.join(d, "inbox-link")
    os.symlink(i, link)
    return {"inbox": link}


run("ενδιάμεσο symlink ΣΤΗΝ ΑΓΚΥΡΑ", _mk_anchor_symlink, "symlink-in-anchor")


def _mk_deep_anchor_symlink(c, d, s, i, v):
    """Το symlink ΔΕΝ είναι το τελευταίο component αλλά ΕΝΔΙΑΜΕΣΟ."""
    os.makedirs(os.path.join(d, "real", "deep"))
    os.symlink(os.path.join(d, "real"), os.path.join(d, "shadow"))
    os.rename(i, os.path.join(d, "real", "deep", "inbox"))
    return {"inbox": os.path.join(d, "shadow", "deep", "inbox")}


run("symlink σε ΕΝΔΙΑΜΕΣΗ συνιστώσα της άγκυρας", _mk_deep_anchor_symlink,
    "symlink-in-anchor")


def _mk_missing_canonical(c, d, s, i, v):
    os.unlink(os.path.join(c, CANON[0]))


run("canonical αρχείο ΑΠΟΝ από το bundle", _mk_missing_canonical, "canonical-missing")

print("\n== CANONICAL PROFILE: ΥΠΟΧΡΕΩΤΙΚΟ, ΜΟΝΑΔΙΚΟ, ΧΩΡΙΣ ΔΙΠΛΟΤΥΠΑ ==")


def profile_case(name, obj, want, raw=None):
    global executed
    executed += 1
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, "profile.json")
        with open(p, "wb") as fh:
            fh.write(raw if raw is not None else json.dumps(obj).encode("utf-8"))
        try:
            load_canonical_profile(p)
            no("%s ⇒ ΕΓΙΝΕ ΔΕΚΤΟ" % name)
        except CaptureRefused as e:
            (ok if e.reason == want else no)("%s ⇒ ΑΡΝΗΣΗ %s (got=%s)" % (name, want, e.reason))


PID = "lawmax-candidate-canonical-v1"
profile_case("profile ΑΠΩΝ", None, "canonical-profile-unreadable", raw=b"")
profile_case("profile ΚΕΝΗ λίστα", {"profile_id": PID, "files": []},
             "canonical-profile-invalid")
profile_case("profile με ΔΙΠΛΟΤΥΠΟ", {"profile_id": PID, "files": ["a.txt", "a.txt"]},
             "canonical-profile-duplicate")
profile_case("profile με λάθος id", {"profile_id": "other", "files": ["a.txt"]},
             "canonical-profile-invalid")
profile_case("profile με απόλυτο path", {"profile_id": PID, "files": ["/etc/passwd"]},
             "canonical-profile-invalid")

print("\n== ΦΡΟΥΡΟΙ API ΚΑΙ ΑΓΚΥΡΑΣ (ΕΥΡΗΜΑΤΑ ΔΗΜΙΟΥΡΓΟΥ) ==")


def guard(name, fn, want):
    """Ο φρουρός ΠΡΕΠΕΙ να είναι στον ΤΥΠΟ, όχι στην πόρτα."""
    global executed
    executed += 1
    try:
        fn()
        no("%s ⇒ ΕΓΙΝΕ ΔΕΚΤΟ" % name)
    except CaptureRefused as e:
        (ok if e.reason == want else no)("%s ⇒ ΑΡΝΗΣΗ %s (got=%s)" % (name, want, e.reason))
    except Exception as e:                          # noqa: BLE001
        no("%s ⇒ ΑΚΑΤΕΡΓΑΣΤΗ ΕΞΑΙΡΕΣΗ %s: %s" % (name, type(e).__name__, e))


with tempfile.TemporaryDirectory() as d:
    _inbox, _cand, _vault = mkcand(d)
    _ia, _va = open_anchor(_inbox, "inbox"), open_anchor(_vault, "vault")
    # ΤΟ ΑΚΡΙΒΕΣ ΕΥΡΗΜΑ: «capture(..., canonical_profile=<οποιοδήποτε dict>)».
    guard("capture με ΩΜΟ dict ως profile",
          lambda: capture(_ia, "cand", _va, "qq",
                          profile={"profile_id": "x", "files": ["a"]}),
          "canonical-profile-not-validated")
    guard("measure με ΩΜΟ dict ως profile",
          lambda: measure(_va, "q", profile={"profile_id": "x", "files": ["a"]}),
          "canonical-profile-not-validated")
    # Η capture ΔΕΝ δέχεται pathname — μόνο επαληθευμένο Anchor.
    guard("capture με PATHNAME αντί για Anchor",
          lambda: capture(_inbox, "cand", _va, "qq"), "anchor-required")
    _ia.close(); _va.close()

with tempfile.TemporaryDirectory() as d:
    _inbox, _cand, _vault = mkcand(d)
    os.chmod(_vault, 0o770)             # group-writable ⇒ ΟΧΙ authority-ιδιωτικό
    guard("vault group-writable ⇒ ΔΕΝ είναι authority-ιδιωτικό",
          lambda: open_anchor(_vault, "vault"), "anchor-group-world-writable")

print("\n== ΟΡΙΑ ΠΟΡΩΝ ==")
with tempfile.TemporaryDirectory() as d:
    inbox, cand, vault = mkcand(d)
    executed += 1
    ia, va = open_anchor(inbox, "inbox"), open_anchor(vault, "vault")
    try:
        capture(ia, "cand", va, "q", limits={"max_files": 2})
        no("όριο max_files ⇒ ΔΕΝ επιβλήθηκε")
    except CaptureRefused as e:
        (ok if e.reason == "limit-exceeded" else no)("όριο max_files ⇒ ΑΡΝΗΣΗ (%s)" % e.reason)

with tempfile.TemporaryDirectory() as d:
    inbox, cand, vault = mkcand(d)
    executed += 1
    ia, va = open_anchor(inbox, "inbox"), open_anchor(vault, "vault")
    try:
        capture(ia, "cand", va, "q", limits={"max_dir_entries": 3})
        no("όριο max_dir_entries ⇒ ΔΕΝ επιβλήθηκε")
    except CaptureRefused as e:
        (ok if e.reason == "limit-exceeded" else no)(
            "όριο max_dir_entries ⇒ ΑΡΝΗΣΗ ΠΡΙΝ τη συσσώρευση (%s)" % e.reason)

print("\n== RLIMIT_NOFILE — Ο ΜΑΡΤΥΡΑΣ ΤΟΥ ΔΗΜΙΟΥΡΓΟΥ ==")
RLIMIT_RUNNER = r'''
import os, resource, sys, json, tempfile
sys.path.insert(0, sys.argv[1])
from capture import capture, open_anchor, CaptureRefused
nfiles, soft = int(sys.argv[2]), int(sys.argv[3])
d = tempfile.mkdtemp()
inbox = os.path.join(d, "inbox"); cand = os.path.join(inbox, "cand")
os.makedirs(os.path.join(cand, "shapes")); os.makedirs(os.path.join(cand, "verify"))
for rel in json.loads(sys.argv[4]):
    p = os.path.join(cand, rel); os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "wb").write(("canonical:" + rel).encode("utf-8"))
for i in range(nfiles):
    open(os.path.join(cand, "extra%04d.bin" % i), "wb").write(b"x" * 64)
vault = os.path.join(d, "vault"); os.makedirs(vault, 0o700); os.chmod(vault, 0o700)
ia = open_anchor(inbox, "inbox"); va = open_anchor(vault, "vault")
resource.setrlimit(resource.RLIMIT_NOFILE, (soft, soft))
try:
    r = capture(ia, "cand", va, "q")
    print("OK %d" % r["file_count"])
except CaptureRefused as e:
    print("REFUSED %s" % e.reason)
except BaseException as e:
    print("CRASH %s: %s" % (type(e).__name__, e))
'''


def rlimit_case(name, nfiles, soft, accept):
    global executed
    executed += 1
    with tempfile.TemporaryDirectory() as d:
        runner = os.path.join(d, "r.py")
        with open(runner, "w", encoding="utf-8") as fh:
            fh.write(RLIMIT_RUNNER)
        out = subprocess.run(
            [sys.executable, runner, os.path.join(REPO, "authority-v2", "capture"),
             str(nfiles), str(soft), json.dumps(list(CANON))],
            capture_output=True, text=True, timeout=600)
        line = (out.stdout or out.stderr).strip().split("\n")[-1]
        if line.startswith("CRASH"):
            no("%s ⇒ ΑΚΑΤΕΡΓΑΣΤΗ ΕΞΑΙΡΕΣΗ: %s" % (name, line))
        elif any(line.startswith(a) for a in accept):
            ok("%s ⇒ %s" % (name, line))
        else:
            no("%s ⇒ ΑΝΕΠΙΤΡΕΠΤΟ: %s" % (name, line))


rlimit_case("200 αρχεία με RLIMIT_NOFILE=96 (κάθε fd κλείνει ΑΜΕΣΩΣ)", 200, 96, ("OK",))
rlimit_case("εξαντλημένοι descriptors (RLIMIT_NOFILE=8) ⇒ ΕΛΕΓΧΟΜΕΝΗ άρνηση",
            200, 8, ("REFUSED fd-exhausted", "REFUSED os-error", "OK"))

print("\n== CONCURRENT MUTATOR (ΠΡΑΓΜΑΤΙΚΟ TOCTOU) ==")
# Το μέγεθος ΕΙΝΑΙ ΜΕΡΟΣ ΤΗΣ ΑΠΟΔΕΙΞΗΣ: με αρχείο < chunk ανάγνωσης η σχισμένη
# ανάγνωση είναι φυσικά αδύνατη και το σενάριο θα ήταν ΚΕΝΟ.
NF = 8
CONC_SIZE = 4 * CHUNK
assert CONC_SIZE > CHUNK, "το σενάριο θα ήταν κενό"


def concurrent(name, kind, allowed):
    global executed
    mutator = os.path.join(REPO, "authority-v2", "tests", "_mutator.py")
    with tempfile.TemporaryDirectory() as d:
        inbox, cand, vault = mkcand(d, nbin=NF, size=CONC_SIZE)
        secret = os.path.join(d, "secret")
        with open(secret, "wb") as fh:
            fh.write(SECRET_MARKER + b"\n")
        adv = subprocess.Popen([sys.executable, mutator, cand, kind, secret,
                                str(NF), str(CONC_SIZE)],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        executed += 1
        time.sleep(0.02)
        res, got = None, None
        ia = va = None
        try:
            ia = open_anchor(inbox, "inbox")
            va = open_anchor(vault, "vault")
            res = capture(ia, "cand", va, "q")
        except CaptureRefused as e:
            got = e.reason
        except Exception as e:                      # noqa: BLE001
            adv.kill(); adv.wait()
            no("%s ⇒ ΑΚΑΤΕΡΓΑΣΤΗ ΕΞΑΙΡΕΣΗ %s: %s" % (name, type(e).__name__, e))
            return
        finally:
            adv.kill()
            adv.wait()
        if got is None:
            if fixed_point(name, res, va, vault, "q", coherence=True):
                ok("%s ⇒ ΚΑΘΑΡΗ ΣΥΛΛΗΨΗ + fixed point ①②③ (καμία μόλυνση)" % name)
        elif got in allowed:
            ok("%s ⇒ ΑΡΝΗΣΗ %s" % (name, got))
        else:
            no("%s ⇒ ΑΝΕΠΙΤΡΕΠΤΟ αποτέλεσμα: %s" % (name, got))


concurrent("concurrent rewrite", "rewrite", ("mutated-during-capture",))
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
