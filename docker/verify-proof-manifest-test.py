#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ΑΡΝΗΤΙΚΟ FIXTURE για τον verify-proof-manifest.py ([audit#2 / re-review C-2a]).

Κλειδώνει τη ΔΟΜΙΚΗ πύλη totality: ΚΑΘΕ tests/*.lisp πρέπει να είναι ταξινομημένο
— είτε -test.lisp σουίτα είτε δηλωμένο «nonsuite:». Αποδεικνύει:
  (α) αταξινόμητο non-test .lisp ⇒ FAIL (σιωπηλό κενό αδύνατο)·
  (β) το ίδιο αρχείο δηλωμένο nonsuite ⇒ περνά totality·
  (γ) stale nonsuite δήλωση (ανύπαρκτο αρχείο) ⇒ FAIL·
  (δ) πλήρως έγκυρο σετ ⇒ OK.
Χωρίς app_root ⇒ παραλείπεται ο επανυπολογισμός hash (self-contained, χωρίς build).
"""
import hashlib, json, os, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
VERIFIER = os.path.join(HERE, "verify-proof-manifest.py")
HEX40 = "a" * 40
HEX64 = "b" * 64

EXCL_BODY_BASE = "comparison\n"  # η KNOWN gated εξαίρεση
NONSUITE_LINES = "".join(
    "nonsuite: %s\n" % f for f in (
        "architecture-verification.lisp", "hardcoded-verification.lisp",
        "mathematical-proof.lisp", "observer-verification.lisp",
        "run-citation-verification.lisp", "test-citation-authority.lisp",
        "test-infrastructure.lisp", "tokenizer-verification.lisp"))

pass_n = 0; fail_n = 0
def ok(m):
    global pass_n; pass_n += 1; print("  ok   " + m)
def no(m):
    global fail_n; fail_n += 1; print("  FAIL " + m)


def build(root, test_files, nonsuite_decls, suites, census=None):
    """Στήνει app-root με tests/, docker/exclusions, docker/suite-census, proof/.

    [RATCHET-5] Το census είναι ΠΑΓΩΜΕΝΟ μητρώο: default = ακριβώς οι gated
    suites (υγιής κατάσταση). Τα αρνητικά σενάρια το παραλλάσσουν."""
    tests = os.path.join(root, "tests"); os.makedirs(tests)
    for f in test_files:
        open(os.path.join(tests, f), "w").close()
    docker = os.path.join(root, "docker"); os.makedirs(docker)
    with open(os.path.join(docker, "standalone-suite-exclusions.txt"), "w", encoding="utf-8") as fh:
        fh.write(EXCL_BODY_BASE)
        for f in nonsuite_decls:
            fh.write("nonsuite: %s\n" % f)
    census_names = suites if census is None else census
    with open(os.path.join(docker, "suite-census.txt"), "w", encoding="utf-8") as fh:
        fh.write("# frozen suite census (fixture)\n")
        for s in census_names:
            fh.write("%s\n" % s)
    proof = os.path.join(root, "proof"); os.makedirs(os.path.join(proof, "logs"))
    open(os.path.join(proof, "logs", "x.log"), "w").close()
    sp = {"proof": "lawmax/standalone-proof/1", "git_commit": HEX40,
          "orchestrator_core_sha256": HEX64, "component_manifest_sha256": HEX64,
          "source_tree_sha256": HEX64, "logs_sha256": HEX64,
          "suites": [{"suite": s, "result": "1 passed, 0 failed"} for s in suites]}
    with open(os.path.join(proof, "standalone-proof.json"), "w") as fh:
        json.dump(sp, fh)
    vp = {"proof": "lawmax/verifier-proof/1", "git_commit": HEX40,
          "verify_py_sha256": HEX64, "verify_mjs_sha256": HEX64,
          "verify_canonical_py_sha256": HEX64, "verify_temporal_py_sha256": HEX64,
          "verify_release_py_sha256": HEX64,
          "gates": ["cross-language-verifier", "release-vector-conformance",
                    "verify-canonical", "semantic-validity", "temporal-verifier"]}
    with open(os.path.join(proof, "verifier-proof.json"), "w") as fh:
        json.dump(vp, fh)
    with open(os.path.join(proof, "suites-run.txt"), "w") as fh:
        for s in suites:
            fh.write(s + "\n")
    return proof, tests


def run(proof, tests):
    r = subprocess.run([sys.executable, VERIFIER, proof, tests],
                       capture_output=True, text=True)
    return r.returncode, (r.stdout + r.stderr)


def case(name, test_files, nonsuite_decls, suites, want_ok, needle=None, census=None,
         drop_census=False):
    with tempfile.TemporaryDirectory() as root:
        proof, tests = build(root, test_files, nonsuite_decls, suites, census)
        if drop_census:
            os.remove(os.path.join(root, "docker", "suite-census.txt"))
        rc, out = run(proof, tests)
        got_ok = (rc == 0)
        cond = (got_ok == want_ok) and (needle is None or needle in out)
        (ok if cond else no)("%s (rc=%s, want_ok=%s)" % (name, rc, want_ok))
        if not cond:
            print("      ── output ──\n" + "\n".join("      " + l for l in out.splitlines()))


# (α) Αταξινόμητο non-test αρχείο ⇒ FAIL totality.
case("(α) αταξινόμητο tests/legacy.lisp ⇒ FAIL",
     ["foo-test.lisp", "legacy.lisp"], [], ["foo"],
     want_ok=False, needle="ΑΤΑΞΙΝΟΜΗΤΑ")

# (β) Το ίδιο αρχείο δηλωμένο nonsuite ⇒ περνά totality (OK συνολικά).
case("(β) legacy.lisp δηλωμένο nonsuite ⇒ OK",
     ["foo-test.lisp", "legacy.lisp"], ["legacy.lisp"], ["foo"],
     want_ok=True)

# (γ) Stale nonsuite δήλωση για ανύπαρκτο αρχείο ⇒ FAIL.
case("(γ) stale nonsuite (ghost.lisp ανύπαρκτο) ⇒ FAIL",
     ["foo-test.lisp"], ["ghost.lisp"], ["foo"],
     want_ok=False, needle="stale")

# (δ) Πλήρες έγκυρο σετ (μόνο -test suites) ⇒ OK.
case("(δ) καθαρό -test-only σετ ⇒ OK",
     ["foo-test.lisp", "bar-test.lisp"], [], ["foo", "bar"],
     want_ok=True)

# (ε) Οι 8 πραγματικές legacy δηλώσεις ⇒ OK (totality πλήρης).
case("(ε) 8 legacy nonsuite + 1 suite ⇒ OK",
     ["foo-test.lisp",
      "architecture-verification.lisp", "hardcoded-verification.lisp",
      "mathematical-proof.lisp", "observer-verification.lisp",
      "run-citation-verification.lisp", "test-citation-authority.lisp",
      "test-infrastructure.lisp", "tokenizer-verification.lisp"],
     ["architecture-verification.lisp", "hardcoded-verification.lisp",
      "mathematical-proof.lisp", "observer-verification.lisp",
      "run-citation-verification.lisp", "test-citation-authority.lisp",
      "test-infrastructure.lisp", "tokenizer-verification.lisp"],
     ["foo"], want_ok=True)

# (στ) Λάθος δήλωση: nonsuite σε -test.lisp ⇒ FAIL (μη-έγκυρη δήλωση).
case("(στ) nonsuite δήλωση σε -test.lisp ⇒ FAIL",
     ["foo-test.lisp"], ["foo-test.lisp"], ["foo"],
     want_ok=False, needle="μη-έγκυρη nonsuite")


# ── [RATCHET-5] RATCHET ΣΟΥΙΤΩΝ: η σιωπηλή αφαίρεση γίνεται αδύνατη ──
# Ο αντίπαλος μεταλλάξεων μέτρησε ότι σουίτα μπορούσε να εξαφανιστεί με δύο
# τρόπους ΧΩΡΙΣ κανένα κόκκινο: διαγραφή αρχείου (σμικραίνει το glob) ή μία
# γραμμή στο exclusions (σμικραίνει το gated set). Το παγωμένο μητρώο είναι
# ΑΝΕΞΑΡΤΗΤΗ committed αυθεντία που επιβιώνει και των δύο.

# (ζ) ΔΙΑΓΡΑΜΜΕΝΗ σουίτα: στο μητρώο αλλά το αρχείο λείπει ⇒ FAIL.
case("(ζ) διαγραμμένη σουίτα (στο census, εκτός δίσκου) ⇒ FAIL",
     ["foo-test.lisp"], [], ["foo"],
     want_ok=False, needle="ΣΙΩΠΗΛΗ ΑΦΑΙΡΕΣΗ", census=["foo", "bar"])

# (η) ΕΞΑΙΡΕΘΕΙΣΑ σουίτα: υπάρχει στον δίσκο και στο μητρώο, αλλά «comparison»
#     είναι δηλωμένη εξαίρεση ⇒ εκτός gated set ⇒ FAIL.
case("(η) εξαιρεθείσα σουίτα παρούσα στο census ⇒ FAIL",
     ["foo-test.lisp", "comparison-test.lisp"], [], ["foo"],
     want_ok=False, needle="ΣΙΩΠΗΛΗ ΑΦΑΙΡΕΣΗ", census=["foo", "comparison"])

# (θ) ΑΔΗΛΩΤΗ σουίτα: τρέχει αλλά λείπει από το μητρώο ⇒ FAIL (ώστε η μελλοντική
#     αφαίρεσή της να μπορεί να κοκκινίσει).
case("(θ) σουίτα εκτός census ⇒ FAIL",
     ["foo-test.lisp", "bar-test.lisp"], [], ["foo", "bar"],
     want_ok=False, needle="ΑΔΗΛΩΤΗ", census=["foo"])

# (ι) ΑΠΟΝ μητρώο ⇒ fail-closed (χωρίς ratchet δεν υπάρχει απόδειξη).
case("(ι) απόν suite-census ⇒ FAIL (fail-closed)",
     ["foo-test.lisp"], [], ["foo"],
     want_ok=False, needle="census", drop_census=True)

# (κ) Μητρώο ΤΑΥΤΟ με το gated set ⇒ OK.
case("(κ) census ≡ gated set ⇒ OK",
     ["foo-test.lisp", "bar-test.lisp"], [], ["foo", "bar"],
     want_ok=True, census=["foo", "bar"])

print("\nverify-proof-manifest fixture: %d passed, %d failed" % (pass_n, fail_n))
sys.exit(0 if fail_n == 0 else 1)
