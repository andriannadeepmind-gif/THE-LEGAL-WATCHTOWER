#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ΜΑΡΤΥΡΑΣ ΜΕΤΑΛΛΑΞΕΩΝ ΤΗΣ CAPTURE — «περνάει» δεν σημαίνει «ελέγχει»

Ένα harness που περνά μπορεί να είναι ταυτολογία. Η ΜΟΝΗ απόδειξη ότι το
fixed-point test είναι φορτίου είναι να ΣΠΑΣΟΥΜΕ την capture με τρόπους που
αντιστοιχούν ΑΚΡΙΒΩΣ στα ευρήματα του δημιουργού και να δούμε το harness να
ΣΚΟΤΩΝΕΙ κάθε μετάλλαξη.

ΠΩΣ: για κάθε μετάλλαξη χτίζεται ΠΛΗΡΕΣ μίνι-δέντρο σε tmp —
    <tmp>/authority-v2/capture/capture.py     (ΜΕΤΑΛΛΑΓΜΕΝΟ)
    <tmp>/authority-v2/tests/{harness,_mutator}.py  (αυτούσια)
    <tmp>/deployment -> symlink στα ΠΡΑΓΜΑΤΙΚΑ golden vectors
— και τρέχει το ΑΥΤΟΥΣΙΟ αντιπαλικό harness εναντίον του. ΚΑΜΙΑ αγκίστρωση
(env var/flag) δεν μπαίνει στον παραγωγικό κώδικα για χάρη του ελέγχου.

ΚΡΙΤΗΡΙΟ: κάθε μετάλλαξη ΠΡΕΠΕΙ να εφαρμοστεί (αλλιώς FAIL: κενή μετάλλαξη)
ΚΑΙ ΠΡΕΠΕΙ να σκοτωθεί (exit ≠ 0). Ο ΑΜΕΤΑΛΛΑΚΤΟΣ κώδικας ΠΡΕΠΕΙ να περνά —
θετικός μάρτυρας, ώστε ο έλεγχος να μη σκοτώνει τα πάντα αδιακρίτως.
"""
import os
import shutil
import subprocess
import sys
import tempfile

_HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(_HERE))
CAPTURE_SRC = os.path.join(REPO, "authority-v2", "capture", "capture.py")
HARNESS = os.path.join(_HERE, "capture-adversarial-test.py")
MUTATOR = os.path.join(_HERE, "_mutator.py")

passed = failed = 0


def ok(m):
    global passed
    passed += 1
    print("  ok   " + m)


def no(m):
    global failed
    failed += 1
    print("  FAIL " + m)


# ── ΟΙ ΜΕΤΑΛΛΑΞΕΙΣ = ΤΑ ΕΥΡΗΜΑΤΑ ΤΟΥ ΔΗΜΙΟΥΡΓΟΥ, ΞΑΝΑΕΙΣΑΓΜΕΝΑ ΕΠΙΤΗΔΕΣ ────
MUTANTS = [
    ("release_root ως hash-of-hash (ΤΟ ΑΚΡΙΒΕΣ P0 ΤΟΥ ΔΗΜΙΟΥΡΓΟΥ)",
     'release_root = _mth([by_path[f]["leaf"] for f in canonical_files])',
     'release_root = _mth([_leaf(bytes.fromhex(by_path[f]["sha256"]))\n'
     '                             for f in canonical_files])'),

    ("φύλλο ΧΩΡΙΣ domain separation (0x00)",
     '    return PREFIX + hashlib.sha256(LEAF_DOMAIN + data).hexdigest()',
     '    return PREFIX + hashlib.sha256(data).hexdigest()'),

    ("MTH με duplicate-last (κλάση CVE-2012-2459)",
     '    k = 1\n    while k * 2 < len(leaves):\n        k *= 2\n'
     '    return _node(_mth(leaves[:k]), _mth(leaves[k:]))',
     '    if len(leaves) % 2:\n        leaves = leaves + [leaves[-1]]\n'
     '    k = len(leaves) // 2\n'
     '    return _node(_mth(leaves[:k]), _mth(leaves[k:]))'),

    ("μερική εγγραφή (η os.write αγνοεί την επιστροφή)",
     '        w = os.write(fd, mv[off:])',
     '        w = os.write(fd, mv[off:off + max(1, (n - off) // 2)])\n'
     '        if off == 0 and n > 1:\n            return n'),

    ("κατάργηση του ελέγχου fingerprint ΜΕΤΑ την ανάγνωση (TOCTOU ανοιχτό)",
     '        if _fingerprint(os.fstat(fd)) != before:\n'
     '            raise CaptureRefused("mutated-during-capture", rel)',
     '        pass  # ΜΕΤΑΛΛΑΞΗ: καμία ανίχνευση μεταβολής'),

    ("κατάργηση της άρνησης hardlink (διαρροή authority secret)",
     '        if st.st_nlink > 1:\n'
     '            raise CaptureRefused("hardlink-present", "%s (nlink=%d)" % (rel, st.st_nlink))',
     '        pass  # ΜΕΤΑΛΛΑΞΗ: hardlinks γίνονται δεκτά'),

    ("κατάργηση της ΔΙΑΣΤΑΥΡΩΣΗΣ ΦΑΣΕΩΝ + μερική εγγραφή",
     '    if written != measured:',
     '    if False:'),
]


def build_tree(tmp, source_text):
    os.makedirs(os.path.join(tmp, "authority-v2", "capture"))
    os.makedirs(os.path.join(tmp, "authority-v2", "tests"))
    with open(os.path.join(tmp, "authority-v2", "capture", "capture.py"), "w",
              encoding="utf-8") as fh:
        fh.write(source_text)
    shutil.copy2(HARNESS, os.path.join(tmp, "authority-v2", "tests",
                                       "capture-adversarial-test.py"))
    shutil.copy2(MUTATOR, os.path.join(tmp, "authority-v2", "tests", "_mutator.py"))
    os.symlink(os.path.join(REPO, "deployment"), os.path.join(tmp, "deployment"))
    return os.path.join(tmp, "authority-v2", "tests", "capture-adversarial-test.py")


def run_harness(tmp, source_text):
    h = build_tree(tmp, source_text)
    r = subprocess.run([sys.executable, h], capture_output=True, text=True, timeout=900)
    return r.returncode, (r.stdout + r.stderr)


with open(CAPTURE_SRC, encoding="utf-8") as fh:
    ORIGINAL = fh.read()

print("== ΘΕΤΙΚΟΣ ΜΑΡΤΥΡΑΣ: ο ΑΜΕΤΑΛΛΑΚΤΟΣ κώδικας ΠΕΡΝΑΕΙ ==")
with tempfile.TemporaryDirectory() as tmp:
    rc, out = run_harness(tmp, ORIGINAL)
    if rc == 0:
        ok("αμετάλλακτη capture ⇒ το harness περνά (ΔΕΝ σκοτώνει τα πάντα)")
    else:
        no("αμετάλλακτη capture ⇒ το harness ΑΠΕΤΥΧΕ:\n%s" % out[-1500:])

print("\n== ΚΑΘΕ ΜΕΤΑΛΛΑΞΗ ΠΡΕΠΕΙ ΝΑ ΣΚΟΤΩΘΕΙ ==")
# Η τελευταία μετάλλαξη (διασταύρωση φάσεων) είναι παρατηρήσιμη ΜΟΝΟ μαζί με
# μερική εγγραφή — αλλιώς θα ήταν κενή. Συνδυάζεται ΡΗΤΑ.
for i, (name, old, new) in enumerate(MUTANTS):
    src = ORIGINAL
    if name.startswith("κατάργηση της ΔΙΑΣΤΑΥΡΩΣΗΣ"):
        po, pn = MUTANTS[3][1], MUTANTS[3][2]
        if src.count(po) != 1:
            no("M%d: η προαπαιτούμενη μερική εγγραφή δεν εφαρμόστηκε" % (i + 1))
            continue
        src = src.replace(po, pn)
    if src.count(old) != 1:
        no("M%d %s — ΚΕΝΗ ΜΕΤΑΛΛΑΞΗ (βρέθηκαν %d εμφανίσεις)"
           % (i + 1, name, src.count(old)))
        continue
    src = src.replace(old, new)
    with tempfile.TemporaryDirectory() as tmp:
        try:
            rc, out = run_harness(tmp, src)
        except subprocess.TimeoutExpired:
            rc, out = 124, "timeout"
    if rc != 0:
        ok("M%d %s ⇒ ΣΚΟΤΩΘΗΚΕ" % (i + 1, name))
    else:
        no("M%d %s ⇒ ΕΠΕΖΗΣΕ — το harness ΔΕΝ ελέγχει αυτή την ιδιότητα" % (i + 1, name))

print("\n── capture mutation witness: %d passed, %d failed ──" % (passed, failed))
sys.exit(0 if failed == 0 else 1)
