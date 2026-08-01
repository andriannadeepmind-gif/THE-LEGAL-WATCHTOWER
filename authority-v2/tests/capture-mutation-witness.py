#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ΜΑΡΤΥΡΑΣ ΜΕΤΑΛΛΑΞΕΩΝ ΤΗΣ CAPTURE — «περνάει» δεν σημαίνει «ελέγχει»

Κάθε εύρημα του δημιουργού ΞΑΝΑΕΙΣΑΓΕΤΑΙ επίτηδες στον κώδικα και ΠΡΕΠΕΙ να
σκοτωθεί από το αντιπαλικό harness. Αν επιζήσει, το harness ΔΕΝ ελέγχει την
ιδιότητα — και το λέμε, δεν το κρύβουμε.

ΠΩΣ: για κάθε μετάλλαξη χτίζεται ΠΛΗΡΕΣ μίνι-δέντρο σε tmp με ΜΕΤΑΛΛΑΓΜΕΝΗ
capture.py και ΑΥΤΟΥΣΙΟ harness· symlink στα ΠΡΑΓΜΑΤΙΚΑ golden vectors. ΚΑΜΙΑ
αγκίστρωση (env var/flag) δεν μπαίνει στον παραγωγικό κώδικα για χάρη του
ελέγχου.

ΚΡΙΤΗΡΙΟ: κάθε μετάλλαξη ΠΡΕΠΕΙ να εφαρμοστεί (αλλιώς FAIL: κενή μετάλλαξη)
ΚΑΙ ΠΡΕΠΕΙ να σκοτωθεί. Ο ΑΜΕΤΑΛΛΑΚΤΟΣ κώδικας ΠΡΕΠΕΙ να περνά (θετικός
μάρτυρας: ο έλεγχος δεν σκοτώνει τα πάντα αδιακρίτως).
"""
import os
import shutil
import subprocess
import sys
import tempfile

_HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(_HERE))
CAPTURE_DIR = os.path.join(REPO, "authority-v2", "capture")
CAPTURE_SRC = os.path.join(CAPTURE_DIR, "capture.py")
PROFILE_SRC = os.path.join(CAPTURE_DIR, "canonical-profile.json")
HARNESS = os.path.join(_HERE, "capture-adversarial-test.py")
MUTATOR = os.path.join(_HERE, "_mutator.py")

passed = failed = 0
survivors = []
declared_survivors = []


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
    ("release_root ως hash-of-hash (P0 πρώτης ετυμηγορίας)",
     '    release_root = _mth([by_path[f]["leaf"] for f in prof["files"]])',
     '    release_root = _mth([_leaf(bytes.fromhex(by_path[f]["sha256"]))\n'
     '                         for f in prof["files"]])'),

    ("φύλλο ΧΩΡΙΣ domain separation (0x00)",
     '    return PREFIX + hashlib.sha256(LEAF_DOMAIN + data).hexdigest()',
     '    return PREFIX + hashlib.sha256(data).hexdigest()'),

    ("MTH με duplicate-last (κλάση CVE-2012-2459)",
     '    k = 1\n    while k * 2 < len(leaves):\n        k *= 2\n'
     '    return _node(_mth_recursive(leaves[:k]), _mth_recursive(leaves[k:]))',
     '    if len(leaves) % 2:\n        leaves = leaves + [leaves[-1]]\n'
     '    k = len(leaves) // 2\n'
     '    return _node(_mth_recursive(leaves[:k]), _mth_recursive(leaves[k:]))'),

    ("ΛΑΘΟΣ ΜΟΝΟ ΣΕ ΔΕΝΤΡΟ 18 ΦΥΛΛΩΝ (ΤΟ ΑΚΡΙΒΕΣ ΕΥΡΗΜΑ ΤΟΥ ΔΗΜΙΟΥΡΓΟΥ)",
     '    k = 1\n    while k * 2 < len(leaves):\n        k *= 2\n'
     '    return _node(_mth_recursive(leaves[:k]), _mth_recursive(leaves[k:]))',
     '    k = 1\n    while k * 2 < len(leaves):\n        k *= 2\n'
     '    if len(leaves) == 18:\n        k = 8          # ΜΕΤΑΛΛΑΞΗ: μόνο εδώ\n'
     '    return _node(_mth_recursive(leaves[:k]), _mth_recursive(leaves[k:]))'),

    ("ΛΑΘΟΣ n=18 **ΚΑΙ** κατάργηση του δεύτερου αλγορίθμου (μένουν μόνο τα vectors)",
     '    a = _mth_recursive(leaves)\n    b = _mth_streaming(leaves)',
     '    a = _mth_recursive(leaves)\n    b = a          # ΜΕΤΑΛΛΑΞΗ: καμία δεύτερη γνώμη'),

    ("μερική εγγραφή (η os.write αγνοεί την επιστροφή)",
     '            w = os.write(fd, mv[off:])',
     '            w = os.write(fd, mv[off:off + max(1, (n - off) // 2)])\n'
     '            if off == 0 and n > 1:\n                return n'),

    ("κατάργηση του ελέγχου fingerprint ΜΕΤΑ την ανάγνωση (TOCTOU ανοιχτό)",
     '            if _fingerprint(os.fstat(fd)) != before:\n'
     '                raise CaptureRefused("mutated-during-capture", child)',
     '            pass  # ΜΕΤΑΛΛΑΞΗ: καμία ανίχνευση μεταβολής'),

    ("κατάργηση της άρνησης hardlink (διαρροή authority secret)",
     '            if sb.st_nlink > 1:\n'
     '                raise CaptureRefused("hardlink-present", "%s (nlink=%d)" % (child, sb.st_nlink))',
     '            pass  # ΜΕΤΑΛΛΑΞΗ: hardlinks γίνονται δεκτά'),

    ("ΔΙΑΡΡΟΗ DESCRIPTORS (το ακριβές OSError(24) του δημιουργού)",
     '        finally:\n            os.close(fd)                  # ΑΜΕΣΩΣ, σε ΚΑΘΕ διαδρομή',
     '        finally:\n            globals().setdefault("_LEAK", []).append(fd)  # ΜΕΤΑΛΛΑΞΗ'),

    ("ΑΥΘΑΙΡΕΤΟ PATHNAME ΑΓΚΥΡΑΣ (χωρίς διάσχιση συνιστωσών)",
     '    if not os.path.isabs(abs_path):\n'
     '        raise CaptureRefused("anchor-not-absolute", abs_path)\n'
     '    try:\n        fd = os.open("/", _DIR_FLAGS)',
     '    if os.path.isabs(abs_path):\n'
     '        return os.open(abs_path, os.O_RDONLY | os.O_DIRECTORY)  # ΜΕΤΑΛΛΑΞΗ\n'
     '    try:\n        fd = os.open("/", _DIR_FLAGS)'),

    ("ΑΠΟΔΟΧΗ μη έγκυρου UTF-8 ονόματος (surrogateescape)",
     '    try:\n        text = raw.decode("utf-8")\n'
     '    except UnicodeDecodeError as exc:\n'
     '        raise CaptureRefused("non-utf8-name",\n'
     '                             "%r δεν είναι έγκυρο UTF-8 (%s)" % (raw, exc.reason))',
     '    text = raw.decode("utf-8", "surrogateescape")  # ΜΕΤΑΛΛΑΞΗ'),

    ("ΑΠΟΔΟΧΗ διπλότυπου στο canonical profile",
     '        if f in seen:\n'
     '            raise CaptureRefused("canonical-profile-duplicate",\n'
     '                                 "%r εμφανίζεται δύο φορές — δύο ρίζες για τα ΙΔΙΑ bytes" % f)',
     '        pass  # ΜΕΤΑΛΛΑΞΗ: διπλότυπα γίνονται δεκτά'),

    ("ΚΑΝΕΝΑΣ ΚΑΘΑΡΙΣΜΟΣ του ΜΕΡΙΚΟΥ quarantine μετά από άρνηση",
     '            _purge(vault_fd, qraw)                   # ΜΕΡΙΚΟ quarantine ⇒ ΤΕΛΟΣ',
     '            pass  # ΜΕΤΑΛΛΑΞΗ: το μερικό quarantine μένει'),

    # ΔΗΛΩΜΕΝΑ ΜΗ ΠΑΡΑΤΗΡΗΣΙΜΗ — και η δήλωση ΕΙΝΑΙ ΔΙΑΨΕΥΣΙΜΗ (βλ. παρακάτω).
    ("κατάργηση του fixed point ΜΕΣΑ στην capture() [ΔΗΛΩΜΕΝΑ ΜΗ ΠΑΡΑΤΗΡΗΣΙΜΗ]",
     '        again = measure(vault_path, quarantine_name, canonical_profile=prof, limits=lim)',
     '        again = dict(result)  # ΜΕΤΑΛΛΑΞΗ: καμία δεύτερη μέτρηση'),

    ("κατάργηση της ΔΙΑΣΤΑΥΡΩΣΗΣ ΦΑΣΕΩΝ + μερική εγγραφή",
     '        if written != measured:',
     '        if False:'),
]

# ── ΔΗΛΩΜΕΝΑ ΜΗ ΠΑΡΑΤΗΡΗΣΙΜΕΣ ΜΕΤΑΛΛΑΞΕΙΣ ──────────────────────────────────
# Το in-capture fixed point (δεύτερη πλήρης μέτρηση) είναι ΠΑΡΑΓΩΓΙΚΗ άμυνα
# απέναντι σε ΜΗ ΝΤΕΤΕΡΜΙΝΙΣΤΙΚΗ αποθήκευση. Όταν η αποθήκευση ΕΙΝΑΙ
# ντετερμινιστική — δηλαδή σε κάθε υγιές σύστημα — η απουσία του ΔΕΝ ΕΧΕΙ ΚΑΜΙΑ
# παρατηρήσιμη συνέπεια από έξω: δεν υπάρχει σφάλμα που να το πιάνει ΜΟΝΟ αυτό
# και να μην το πιάνει ήδη η ανεξάρτητη επαναμέτρηση ② του harness.
#
# ΔΕΝ το κρύβω και ΔΕΝ το μετράω ως φόνο. Το δηλώνω — ΚΑΙ Η ΔΗΛΩΣΗ ΕΙΝΑΙ
# ΔΙΑΨΕΥΣΙΜΗ: αν κάποτε ΣΚΟΤΩΘΕΙ, ο μάρτυρας ΑΠΟΤΥΓΧΑΝΕΙ, γιατί τότε η δήλωση
# «μη παρατηρήσιμη» ήταν ΨΕΥΔΗΣ και πρέπει να αφαιρεθεί από εδώ.
NON_OBSERVABLE = {
    "κατάργηση του fixed point ΜΕΣΑ στην capture() [ΔΗΛΩΜΕΝΑ ΜΗ ΠΑΡΑΤΗΡΗΣΙΜΗ]":
        "παραγωγική άμυνα έναντι μη ντετερμινιστικής αποθήκευσης· με ντετερμινιστική "
        "αποθήκευση καμία μαύρου-κουτιού συνέπεια. Παραμένει στον κώδικα ΩΣ ΑΜΥΝΑ, "
        "ΟΧΙ ως ελεγμένη ιδιότητα.",
}

# Η «διασταύρωση φάσεων» και η «n=18 χωρίς δεύτερη γνώμη» είναι παρατηρήσιμες
# ΜΟΝΟ σε συνδυασμό — δηλώνονται ΡΗΤΑ, όχι σιωπηλά.
COMBOS = {
    "ΛΑΘΟΣ n=18 **ΚΑΙ** κατάργηση του δεύτερου αλγορίθμου (μένουν μόνο τα vectors)": 3,
    "κατάργηση της ΔΙΑΣΤΑΥΡΩΣΗΣ ΦΑΣΕΩΝ + μερική εγγραφή": 5,
}


def build_tree(tmp, source_text):
    os.makedirs(os.path.join(tmp, "authority-v2", "capture"))
    os.makedirs(os.path.join(tmp, "authority-v2", "tests"))
    with open(os.path.join(tmp, "authority-v2", "capture", "capture.py"), "w",
              encoding="utf-8") as fh:
        fh.write(source_text)
    shutil.copy2(PROFILE_SRC, os.path.join(tmp, "authority-v2", "capture",
                                           "canonical-profile.json"))
    shutil.copy2(HARNESS, os.path.join(tmp, "authority-v2", "tests",
                                       "capture-adversarial-test.py"))
    shutil.copy2(MUTATOR, os.path.join(tmp, "authority-v2", "tests", "_mutator.py"))
    os.symlink(os.path.join(REPO, "deployment"), os.path.join(tmp, "deployment"))
    return os.path.join(tmp, "authority-v2", "tests", "capture-adversarial-test.py")


def run_harness(tmp, source_text):
    h = build_tree(tmp, source_text)
    r = subprocess.run([sys.executable, h], capture_output=True, text=True, timeout=1800)
    return r.returncode, (r.stdout + r.stderr)


with open(CAPTURE_SRC, encoding="utf-8") as fh:
    ORIGINAL = fh.read()

print("== ΘΕΤΙΚΟΣ ΜΑΡΤΥΡΑΣ: ο ΑΜΕΤΑΛΛΑΚΤΟΣ κώδικας ΠΕΡΝΑΕΙ ==")
with tempfile.TemporaryDirectory() as tmp:
    rc, out = run_harness(tmp, ORIGINAL)
    if rc == 0:
        ok("αμετάλλακτη capture ⇒ το harness περνά (ΔΕΝ σκοτώνει τα πάντα)")
    else:
        no("αμετάλλακτη capture ⇒ το harness ΑΠΕΤΥΧΕ:\n%s" % out[-2000:])

print("\n== ΚΑΘΕ ΜΕΤΑΛΛΑΞΗ ΠΡΕΠΕΙ ΝΑ ΣΚΟΤΩΘΕΙ ==")
for i, (name, old, new) in enumerate(MUTANTS):
    src = ORIGINAL
    prereq = COMBOS.get(name)
    if prereq is not None:
        po, pn = MUTANTS[prereq][1], MUTANTS[prereq][2]
        if src.count(po) != 1:
            no("M%d: το προαπαιτούμενο (%s) δεν εφαρμόστηκε" % (i + 1, MUTANTS[prereq][0]))
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
    declared = NON_OBSERVABLE.get(name)
    if declared is not None:
        # Η ΔΗΛΩΣΗ ΕΛΕΓΧΕΤΑΙ: αν σκοτωθεί, η δήλωση ήταν ΨΕΥΔΗΣ ⇒ ΑΠΟΤΥΧΙΑ.
        if rc == 0:
            declared_survivors.append("M%d %s — %s" % (i + 1, name, declared))
            print("  ⊘   M%d %s ⇒ ΕΠΕΖΗΣΕ ΟΠΩΣ ΔΗΛΩΘΗΚΕ (μη παρατηρήσιμη)" % (i + 1, name))
        else:
            no("M%d %s ⇒ ΣΚΟΤΩΘΗΚΕ ενώ δηλώθηκε ΜΗ ΠΑΡΑΤΗΡΗΣΙΜΗ — η ΔΗΛΩΣΗ ΕΙΝΑΙ ΨΕΥΔΗΣ, "
               "αφαίρεσέ την από το NON_OBSERVABLE" % (i + 1, name))
        continue
    if rc != 0:
        ok("M%d %s ⇒ ΣΚΟΤΩΘΗΚΕ" % (i + 1, name))
    else:
        survivors.append("M%d %s" % (i + 1, name))
        no("M%d %s ⇒ ΕΠΕΖΗΣΕ — το harness ΔΕΝ ελέγχει αυτή την ιδιότητα" % (i + 1, name))

print("\n── capture mutation witness: %d passed, %d failed, %d δηλωμένα μη παρατηρήσιμα ──"
      % (passed, failed, len(declared_survivors)))
if declared_survivors:
    print("ΔΗΛΩΜΕΝΑ ΜΗ ΠΑΡΑΤΗΡΗΣΙΜΑ (παραμένουν στον κώδικα ως άμυνα, ΟΧΙ ως ελεγμένη ιδιότητα):")
    for x in declared_survivors:
        print("  ⊘ " + x)
if survivors:
    print("ΑΝΕΞΗΓΗΤΟΙ ΕΠΙΖΩΝΤΕΣ (κάθε ένας είναι κενό του harness):")
    for x in survivors:
        print("  ⚠ " + x)
sys.exit(0 if failed == 0 else 1)
