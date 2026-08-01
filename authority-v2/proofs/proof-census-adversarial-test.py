#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ΑΝΤΙΠΑΛΟΣ ΤΗΣ ΑΠΟΓΡΑΦΗΣ ΑΠΟΔΕΙΞΕΩΝ — η απογραφή είναι ΚΛΕΙΣΤΗ ή δεν είναι

ΕΤΥΜΗΓΟΡΙΑ ΔΗΜΙΟΥΡΓΟΥ: «Το verify-capability-closure.sh δεν περιλαμβάνεται στο
PROOF-CENSUS.txt … Επομένως ο ισχυρισμός “τρέχει όλες τις αποδείξεις” είναι
ψευδής.» Η διόρθωση της απογραφής ΔΕΝ αρκεί: χωρίς αντίπαλο, η επόμενη
ξεχασμένη απόδειξη θα περάσει ξανά σιωπηλά.

ΕΔΩ ο runner δοκιμάζεται πάνω σε ΤΕΧΝΗΤΑ αποθετήρια, όπου ΞΕΡΟΥΜΕ την αλήθεια:
  · απόδειξη στον δίσκο εκτός απογραφής   ⇒ ΞΕΧΑΣΜΕΝΕΣ ΑΠΟΔΕΙΞΕΙΣ
  · εγγραφή απογραφής χωρίς αρχείο        ⇒ ΝΕΚΡΕΣ ΕΓΓΡΑΦΕΣ (ορφανό)
  · ίδιο μονοπάτι δύο φορές               ⇒ ΔΙΠΛΟΤΥΠΗ ΕΓΓΡΑΦΗ
  · άγνωστος τρόπος                       ⇒ ΑΓΝΩΣΤΟΣ τρόπος (κλειστό σχήμα)
  · γραμμή με ένα μόνο πεδίο              ⇒ ΚΑΚΟΣΧΗΜΑΤΗ γραμμή
  · κενή απογραφή πάνω σε μη κενό δίσκο   ⇒ ΞΕΧΑΣΜΕΝΕΣ ΑΠΟΔΕΙΞΕΙΣ
ΘΕΤΙΚΟΣ ΜΑΡΤΥΡΑΣ: συνεπής απογραφή ⇒ ο runner ΤΡΕΧΕΙ και επιστρέφει 0. Χωρίς
αυτό, ένας runner που απορρίπτει τα πάντα θα «περνούσε» όλα τα αρνητικά.

ΕΠΙΠΛΕΟΝ — Ο ΕΛΕΓΧΟΣ ΤΗΣ ΠΡΑΓΜΑΤΙΚΗΣ ΑΠΟΓΡΑΦΗΣ: το capability-closure ΟΦΕΙΛΕΙ
να είναι μέσα στην ΠΡΑΓΜΑΤΙΚΗ PROOF-CENSUS.txt. Ελέγχεται ρητά εδώ.
"""
import os
import subprocess
import sys
import tempfile

_HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(_HERE))
RUNNER = os.path.join(REPO, "authority-v2", "run-proofs.sh")
REAL_CENSUS = os.path.join(REPO, "authority-v2", "PROOF-CENSUS.txt")

passed = failed = 0


def ok(m):
    global passed
    passed += 1
    print("  ok   " + m)


def no(m):
    global failed
    failed += 1
    print("  FAIL " + m)


def fake_repo(d, proofs, census_lines, strays=()):
    """Τεχνητό αποθετήριο: authority-v2/proofs/<name> + απογραφή (+ αδέσποτα)."""
    tests = os.path.join(d, "authority-v2", "proofs")
    os.makedirs(tests)
    os.makedirs(os.path.join(d, "authority-v2", "capability"))
    for rel in strays:
        sp = os.path.join(d, rel)
        os.makedirs(os.path.dirname(sp), exist_ok=True)
        with open(sp, "w", encoding="utf-8") as fh:
            fh.write("#!/usr/bin/env python3\nimport sys\nsys.exit(1)\n")
        os.chmod(sp, 0o755)
    for name in proofs:
        p = os.path.join(tests, name)
        with open(p, "w", encoding="utf-8") as fh:
            fh.write("#!/usr/bin/env python3\nprint('fake proof ok')\n")
        os.chmod(p, 0o755)
    census = os.path.join(d, "census.txt")
    with open(census, "w", encoding="utf-8") as fh:
        fh.write("\n".join(census_lines) + "\n")
    return census


def run(d, census):
    r = subprocess.run(["bash", RUNNER, "--census", census, "--root", d],
                       capture_output=True, text=True, timeout=300)
    return r.returncode, r.stdout + r.stderr


def case(name, proofs, census_lines, want_rc, want_token, strays=()):
    with tempfile.TemporaryDirectory() as d:
        census = fake_repo(d, proofs, census_lines, strays)
        rc, out = run(d, census)
        if rc != want_rc:
            no("%s ⇒ exit %d (αναμενόταν %d)\n%s" % (name, rc, want_rc, out[-400:]))
            return
        if want_token and want_token not in out:
            no("%s ⇒ σωστό exit αλλά ΧΩΡΙΣ την αιτία %r\n%s" % (name, want_token, out[-400:]))
            return
        ok("%s ⇒ exit %d + αιτία «%s»" % (name, rc, want_token or "—"))


print("== ΘΕΤΙΚΟΣ ΜΑΡΤΥΡΑΣ: ΣΥΝΕΠΗΣ ΑΠΟΓΡΑΦΗ ΠΕΡΝΑΕΙ ==")
case("συνεπής απογραφή (2 αποδείξεις)",
     ["alpha-test.py", "beta-test.py"],
     ["authority-v2/proofs/alpha-test.py  plain",
      "authority-v2/proofs/beta-test.py   plain"], 0, "είσοδοι στο proofs/ ≡ committed")

print("\n== ΚΑΘΕ ΑΝΩΜΑΛΙΑ ΤΗΣ ΑΠΟΓΡΑΦΗΣ ΕΙΝΑΙ ΣΦΑΛΜΑ ==")
case("απόδειξη ΕΚΤΟΣ απογραφής (ξεχασμένη)",
     ["alpha-test.py", "forgotten-test.py"],
     ["authority-v2/proofs/alpha-test.py  plain"], 1, "ΞΕΧΑΣΜΕΝΕΣ ΑΠΟΔΕΙΞΕΙΣ")

case("ΟΡΦΑΝΗ εγγραφή (αρχείο ανύπαρκτο)",
     ["alpha-test.py"],
     ["authority-v2/proofs/alpha-test.py  plain",
      "authority-v2/proofs/ghost-test.py  plain"], 1, "ΝΕΚΡΕΣ ΕΓΓΡΑΦΕΣ")

case("ΔΙΠΛΟΤΥΠΗ εγγραφή",
     ["alpha-test.py"],
     ["authority-v2/proofs/alpha-test.py  plain",
      "authority-v2/proofs/alpha-test.py  plain"], 1, "ΔΙΠΛΟΤΥΠΗ ΕΓΓΡΑΦΗ")

case("ΑΓΝΩΣΤΟΣ τρόπος (κλειστό σχήμα)",
     ["alpha-test.py"],
     ["authority-v2/proofs/alpha-test.py  maybe-someday"], 1, "ΑΓΝΩΣΤΟΣ τρόπος")

case("ΚΑΚΟΣΧΗΜΑΤΗ γραμμή (ένα μόνο πεδίο)",
     ["alpha-test.py"],
     ["authority-v2/proofs/alpha-test.py"], 1, "ΚΑΚΟΣΧΗΜΑΤΗ γραμμή")

case("ΚΕΝΗ απογραφή πάνω σε ΜΗ ΚΕΝΟ δίσκο",
     ["alpha-test.py"], ["# μόνο σχόλιο"], 1, "ΞΕΧΑΣΜΕΝΕΣ ΑΠΟΔΕΙΞΕΙΣ")

print("\n== ΤΟ ΑΚΡΙΒΕΣ MUTANT ΤΟΥ ΔΗΜΙΟΥΡΓΟΥ: authority-v2/other/forgotten-proof.py ==")
# «Έβαλα τεχνητή αποτυχημένη απόδειξη στο authority-v2/other/forgotten-proof.py:
#  ο runner την ΑΓΝΟΗΣΕ και επέστρεψε exit 0.» ΤΩΡΑ ΟΦΕΙΛΕΙ ΝΑ ΚΟΚΚΙΝΙΖΕΙ.
case("ΞΕΧΑΣΜΕΝΗ απόδειξη ΕΚΤΟΣ του καταλόγου εισόδων (authority-v2/other/)",
     ["alpha-test.py"],
     ["authority-v2/proofs/alpha-test.py  plain"], 1,
     "ΑΠΟΔΕΙΞΗ ΕΚΤΟΣ ΤΟΥ ΚΑΤΑΛΟΓΟΥ ΕΙΣΟΔΩΝ",
     strays=("authority-v2/other/forgotten-proof.py",))

case("ΑΔΕΣΠΟΤΟ εκτελέσιμο σε ΤΥΧΑΙΟ βάθος (authority-v2/a/b/c/)",
     ["alpha-test.py"],
     ["authority-v2/proofs/alpha-test.py  plain"], 1,
     "ΑΠΟΔΕΙΞΗ ΕΚΤΟΣ ΤΟΥ ΚΑΤΑΛΟΓΟΥ ΕΙΣΟΔΩΝ",
     strays=("authority-v2/a/b/c/deep-witness.py",))

case("Η ΑΠΟΓΡΑΦΗ δηλώνει απόδειξη ΕΚΤΟΣ proofs/",
     ["alpha-test.py"],
     ["authority-v2/proofs/alpha-test.py  plain",
      "authority-v2/elsewhere/x-test.py   plain"], 1,
     "ΝΕΚΡΕΣ ΕΓΓΡΑΦΕΣ")

print("\n== Η ΠΡΑΓΜΑΤΙΚΗ ΑΠΟΓΡΑΦΗ ΠΕΡΙΕΧΕΙ ΤΟ CAPABILITY CLOSURE ==")
with open(REAL_CENSUS, encoding="utf-8") as fh:
    body = [l.split("#")[0].split() for l in fh]
entries = {parts[0]: parts[1] for parts in body if len(parts) >= 2}
for required, mode in (("authority-v2/proofs/verify-capability-closure.sh", "requires-root"),
                       ("authority-v2/capability/identities.sh", "tool-requires-root"),
                       ("authority-v2/proofs/verify-completion-matrix.py", "plain"),
                       ("authority-v2/proofs/verify-proof-manifest.py", "plain")):
    if entries.get(required) == mode:
        ok("η απογραφή περιέχει %s [%s]" % (required, mode))
    else:
        no("ΑΠΟΥΣΙΑΖΕΙ/ΛΑΘΟΣ ΤΡΟΠΟΣ: %s (got=%s)" % (required, entries.get(required)))

print("\n── proof census adversarial: %d passed, %d failed ──" % (passed, failed))
sys.exit(0 if failed == 0 else 1)
