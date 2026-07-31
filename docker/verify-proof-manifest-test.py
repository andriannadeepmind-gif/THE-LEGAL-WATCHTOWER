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
import hashlib, importlib.util, json, os, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
VERIFIER = os.path.join(HERE, "verify-proof-manifest.py")

# [ΕΥΡΗΜΑ ΚΡΙΤΗ #2] Το fixture ΔΕΝ εισάγει πια τη λίστα δεσμευμένων verifiers
# από τον κώδικα του verifier: όταν το έκανε, η αφαίρεση ενός verifier από τη
# λίστα μίκραινε ΜΑΖΙ τον verifier ΚΑΙ το fixture — ο ratchet συρρικνωνόταν
# αόρατα. Τώρα η έδρα είναι το committed docker/verifier-census.txt: το sandbox
# γράφει ΔΙΚΟ ΤΟΥ census (δεδομένα του σεναρίου) και το vp παράγεται ΑΠΟ ΑΥΤΟ,
# ενώ το πραγματικό census καρφώνεται ανεξάρτητα στο merkle-single-truth-test §Ε.
# Από τον κώδικα εισάγεται ΜΟΝΟ το EXPECTED_GATES (διαφορετική έννοια — η λίστα
# gates διασταυρώνεται με τα RUN του Dockerfile, όχι με αρχεία).
# ΚΑΝΕΝΑ __pycache__: το fixture ΔΕΝ επιτρέπεται να λερώσει το δέντρο — το
# runtime-assets manifest υπολογίζει hashes πάνω σε ΑΥΤΟ το δέντρο μέσα στο build.
sys.dont_write_bytecode = True
_spec = importlib.util.spec_from_file_location("_vpm", VERIFIER)
_vpm = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_vpm)

# Το sandbox-μητρώο του fixture: ΔΕΔΟΜΕΝΑ σεναρίου, όχι αντίγραφο του κώδικα.
FIXTURE_VCENSUS = [
    ("alpha_sha256", "deployment/verify/alpha.py"),
    ("beta_sha256",  "deployment/verify/beta.mjs"),
    ("gamma_sha256", "deployment/verify/gamma.sexp"),
]
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


def build(root, test_files, nonsuite_decls, suites, census=None,
          vcensus=None, vp_drop_key=None, vp_extra_key=None):
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
    vcensus_entries = FIXTURE_VCENSUS if vcensus is None else vcensus
    with open(os.path.join(docker, "verifier-census.txt"), "w", encoding="utf-8") as fh:
        fh.write("# frozen verifier census (fixture)\n")
        for k, rel in vcensus_entries:
            fh.write("%s\t%s\n" % (k, rel))
    proof = os.path.join(root, "proof"); os.makedirs(os.path.join(proof, "logs"))
    open(os.path.join(proof, "logs", "x.log"), "w").close()
    sp = {"proof": "lawmax/standalone-proof/1", "git_commit": HEX40,
          "orchestrator_core_sha256": HEX64, "component_manifest_sha256": HEX64,
          "source_tree_sha256": HEX64, "logs_sha256": HEX64,
          "suites": [{"suite": s, "result": "1 passed, 0 failed"} for s in suites]}
    with open(os.path.join(proof, "standalone-proof.json"), "w") as fh:
        json.dump(sp, fh)
    # Το vp παράγεται ΑΠΟ το sandbox-μητρώο (όπως το Dockerfile από το
    # πραγματικό) — ΟΧΙ από λίστα μέσα στον κώδικα του verifier.
    vp = {"proof": "lawmax/verifier-proof/1", "git_commit": HEX40,
          "gates": list(_vpm.EXPECTED_GATES)}
    for _k, _rel in vcensus_entries:
        vp[_k] = HEX64
    if vp_drop_key is not None:
        del vp[vp_drop_key]
    if vp_extra_key is not None:
        vp[vp_extra_key] = HEX64
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
         drop_census=False, vcensus=None, vp_drop_key=None, vp_extra_key=None,
         drop_vcensus=False):
    with tempfile.TemporaryDirectory() as root:
        proof, tests = build(root, test_files, nonsuite_decls, suites, census,
                             vcensus=vcensus, vp_drop_key=vp_drop_key,
                             vp_extra_key=vp_extra_key)
        if drop_census:
            os.remove(os.path.join(root, "docker", "suite-census.txt"))
        if drop_vcensus:
            os.remove(os.path.join(root, "docker", "verifier-census.txt"))
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


# ── [ΕΥΡΗΜΑ ΚΡΙΤΗ #2] VERIFIER CENSUS: ο ratchet δεν συρρικνώνεται με το τεστ ──
# Μετάλλαξη ΑΦΑΙΡΕΣΗΣ για ΚΑΘΕ δεσμευμένο verifier: το κλειδί του λείπει από το
# manifest ⇒ FAIL. Επειδή το μητρώο είναι committed ΑΡΧΕΙΟ (όχι λίστα στον
# κώδικα), «μικραίνω verifier και fixture μαζί» απαιτεί πλέον ΟΡΑΤΟ diff στο
# docker/verifier-census.txt — και το πραγματικό περιεχόμενο του census
# καρφώνεται ανεξάρτητα στο merkle-single-truth-test §Ε.

# (λ) Αφαίρεση ΚΑΘΕ δεσμευμένου κλειδιού, ένα-ένα ⇒ FAIL για το καθένα.
for _k, _rel in FIXTURE_VCENSUS:
    case("(λ) αφαίρεση δεσμευμένου κλειδιού %s ⇒ FAIL" % _k,
         ["foo-test.lisp"], [], ["foo"],
         want_ok=False, needle="ΔΕΝ είναι 64-hex", vp_drop_key=_k)

# (μ) ΑΔΗΛΩΤΟ επιπλέον κλειδί στο manifest (κλειστό σχήμα) ⇒ FAIL.
case("(μ) αδήλωτο κλειδί rogue_sha256 στο manifest ⇒ FAIL",
     ["foo-test.lisp"], [], ["foo"],
     want_ok=False, needle="ΑΔΗΛΩΤΑ κλειδιά", vp_extra_key="rogue_sha256")

# (ν) ΑΠΟΝ verifier census ⇒ fail-closed.
case("(ν) απόν verifier-census ⇒ FAIL (fail-closed)",
     ["foo-test.lisp"], [], ["foo"],
     want_ok=False, needle="verifier census", drop_vcensus=True)

# (ξ) ΚΕΝΟ verifier census ⇒ fail-closed.
case("(ξ) κενό verifier-census ⇒ FAIL (fail-closed)",
     ["foo-test.lisp"], [], ["foo"],
     want_ok=False, needle="ΚΕΝΟ/διπλότυπο", vcensus=[])

print("\nverify-proof-manifest fixture: %d passed, %d failed" % (pass_n, fail_n))
sys.exit(0 if fail_n == 0 else 1)
