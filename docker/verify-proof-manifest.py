#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""[0088 Φ7-HARDENING #8] Dedicated verifier του proof manifest ΜΕΣΑ στο build.

Fail-closed πύλη στον verifier-conformance κρίκο (η αλυσίδα κάνει το runtime
δομικά αδύνατο χωρίς αυτήν):
  • git_commit = ΑΚΡΙΒΩΣ 40-hex (η ύπαρξη default «pass» τιμής = build failure
    ήδη από το standalone-test gate — εδώ διπλο-ελέγχεται στο manifest)·
  • ΑΚΡΙΒΕΣ αναμενόμενο suite set: ΚΑΘΕ tests/*-test.lisp (πλην ΔΗΛΩΜΕΝΩΝ
    εξαιρέσεων) πρέπει να εμφανίζεται στο manifest ΚΑΙ στο suites-run.txt —
    σιωπηλή αφαίρεση σουίτας από τη λίστα του Dockerfile = FAIL·
  • κάθε suite: ΜΗ ΚΕΝΟ, parseable αποτέλεσμα με failed=0
    («N passed, 0 failed» | «N pass, 0 fail» | «0 διαφωνίες»)·
  • όλα τα sha256 πεδία = 64-hex· verifier-proof.json: 5 verifier hashes +
    ακριβής λίστα gates.
"""
import hashlib, json, os, re, subprocess, sys

# [audit#2] ΔΗΛΩΜΕΝΕΣ εξαιρέσεις: ΜΙΑ πηγή αλήθειας — το ΙΔΙΟ αρχείο που διαβάζει ο
# docker/run-standalone-suites.sh (τι τρέχει) ώστε «τι τρέχει» ≡ «τι αναμένεται».
# Καμία δεύτερη χειρόγραφη λίστα εδώ (η παλιά hardcoded {comparison} ξεσυγχρονιζόταν).
EXCLUSIONS_REL = os.path.join("docker", "standalone-suite-exclusions.txt")

def load_suite_census(app_root, tests_dir):
    """Το ΠΑΓΩΜΕΝΟ σύνολο σουιτών που ΟΦΕΙΛΟΥΝ να τρέχουν ως gate ([RATCHET-5]).

    Απόν/κενό μητρώο = fail-closed: χωρίς μητρώο δεν υπάρχει ratchet, και ένα
    «πέρασε» χωρίς ratchet είναι ακριβώς το ψευδο-πράσινο που κλείνουμε.
    """
    base = app_root if app_root else os.path.dirname(os.path.abspath(tests_dir.rstrip("/")))
    path = os.path.join(base, CENSUS_REL)
    if not os.path.isfile(path):
        print("verify-proof-manifest: ΑΠΟΝ suite census %r — fail-closed" % path)
        sys.exit(1)
    census = set()
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.split("#", 1)[0].strip()
            if line:
                census.add(line)
    if not census:
        print("verify-proof-manifest: ΚΕΝΟ suite census — fail-closed")
        sys.exit(1)
    return census


def load_exclusions(app_root, tests_dir):
    """Επιστρέφει (suite_exclusions, nonsuite_files) από τη ΜΙΑ έδρα δηλώσεων.

    suite_exclusions: basenames (-test.lisp suites) που ΔΕΝ τρέχουν ως gate.
    nonsuite_files:    ΠΛΗΡΗ filenames tests/*.lisp που δεν είναι harness suites
                       (κληρονομημένο/διαφορετικό συμβόλαιο) — δηλωμένα «nonsuite:».
    """
    base = app_root if app_root else os.path.dirname(os.path.abspath(tests_dir.rstrip("/")))
    path = os.path.join(base, EXCLUSIONS_REL)
    if not os.path.isfile(path):
        print("verify-proof-manifest: ΑΠΟΝ exclusions file %r — fail-closed" % path)
        sys.exit(1)
    excl, nonsuite = set(), set()
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            if line.startswith("nonsuite:"):
                fn = line[len("nonsuite:"):].strip()
                if not fn.endswith(".lisp") or fn.endswith("-test.lisp"):
                    fail("exclusions: μη-έγκυρη nonsuite δήλωση %r "
                         "(πρέπει full filename *.lisp, όχι -test.lisp)" % fn)
                else:
                    nonsuite.add(fn)
            else:
                excl.add(line)
    return excl, nonsuite

# Σουίτες που τρέχουν ΜΟΝΟ στον verifier-conformance κρίκο (δικά τους RUN
# gates εκεί — δεν απαιτείται log στο standalone manifest).
VERIFIER_STAGE_ONLY = set()

# [RATCHET-5] Το ΠΑΓΩΜΕΝΟ μητρώο σουιτών: η μόνη άμυνα απέναντι στη ΣΙΩΠΗΛΗ
# ΑΦΑΙΡΕΣΗ (διαγραφή αρχείου ή νέα γραμμή στο exclusions) — και οι δύο σμίκρυναν
# το gated set αφήνοντας το build πράσινο.
CENSUS_REL = os.path.join("docker", "suite-census.txt")

EXPECTED_GATES = ["cross-language-verifier", "release-vector-conformance",
                  "verify-canonical", "semantic-validity", "temporal-verifier"]

# Σουίτες που στο standalone-test stage (SBCL-only, χωρίς node/rdflib) κάνουν
# ΤΙΜΙΟ SKIP και ΞΑΝΑΤΡΕΧΟΥΝ ως ΣΚΛΗΡΟ gate στο verifier-conformance stage
# (dedicated RUN). Γι' αυτές, «SKIP» result στο standalone manifest είναι
# αποδεκτό — ο πραγματικός τους gate ΔΕΝ είναι το manifest αλλά το RUN.
SKIP_ALLOWED_IN_STANDALONE = {"cross-language-verifier"}

HEX40 = re.compile(r"^[0-9a-f]{40}$")
HEX64 = re.compile(r"^[0-9a-f]{64}$")
RESULT_PATTERNS = [
    re.compile(r"(\d+) passed, (\d+) failed"),
    re.compile(r"(\d+) pass(?:es)?, (\d+) fail"),
    re.compile(r"(\d+) vectors, (\d+) διαφωνίες"),
]

FAIL = []
def fail(msg): FAIL.append(msg)

def check_result_line(suite, line):
    if not line or not line.strip():
        fail("suite %s: ΚΕΝΟ αποτέλεσμα — μη parseable proof" % suite); return
    for pat in RESULT_PATTERNS:
        m = pat.search(line)
        if m:
            if int(m.group(2)) != 0:
                fail("suite %s: failed=%s ≠ 0 (%r)" % (suite, m.group(2), line))
            return
    # SKIP επιτρέπεται ΜΟΝΟ για suites hard-gated στο verifier-conformance.
    if "SKIP" in line and suite in SKIP_ALLOWED_IN_STANDALONE:
        return
    fail("suite %s: μη αναγνωρίσιμη γραμμή αποτελέσματος %r" % (suite, line))

def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()

def main(proof_dir, tests_dir, app_root=None):
    sp_path = os.path.join(proof_dir, "standalone-proof.json")
    vp_path = os.path.join(proof_dir, "verifier-proof.json")
    run_path = os.path.join(proof_dir, "suites-run.txt")

    with open(sp_path, encoding="utf-8") as fh:
        sp = json.load(fh)
    if sp.get("proof") != "lawmax/standalone-proof/1":
        fail("standalone-proof: άγνωστο σχήμα %r" % sp.get("proof"))
    if not HEX40.match(sp.get("git_commit", "")):
        fail("standalone-proof: git_commit ΔΕΝ είναι 40-hex HEAD: %r" % sp.get("git_commit"))
    for k in ("orchestrator_core_sha256", "component_manifest_sha256",
              "source_tree_sha256", "logs_sha256"):
        if not HEX64.match(sp.get(k, "")):
            fail("standalone-proof: %s ΔΕΝ είναι 64-hex: %r" % (k, sp.get(k)))

    raw_suites = [s.get("suite") for s in sp.get("suites", [])]
    if len(raw_suites) != len(set(raw_suites)):
        fail("standalone-proof: ΔΙΠΛΟΤΥΠΗ σουίτα στο manifest: %s"
             % sorted({x for x in raw_suites if raw_suites.count(x) > 1}))
    suites = {s.get("suite"): s.get("result", "") for s in sp.get("suites", [])}
    if not suites:
        fail("standalone-proof: κενό suites[]")

    if not os.path.exists(run_path):
        fail("suites-run.txt ΑΠΟΝ — η λίστα εκτέλεσης δεν καταγράφηκε")
        ran = set()
    else:
        with open(run_path, encoding="utf-8") as fh:
            ran = {l.strip() for l in fh if l.strip()}
        if set(suites) != ran:
            fail("manifest suites ≠ εκτελεσμένες: μόνο-manifest=%s μόνο-run=%s"
                 % (sorted(set(suites) - ran), sorted(ran - set(suites))))

    declared_not_gated, declared_nonsuite = load_exclusions(app_root, tests_dir)

    # [re-review C-2a] TOTALITY: ΚΑΘΕ tests/*.lisp πρέπει να είναι ταξινομημένο —
    # είτε -test.lisp σουίτα (gated ή δηλωμένη εξαίρεση) είτε δηλωμένο nonsuite.
    # Οτιδήποτε αταξινόμητο = σιωπηλό κενό = fail-closed (το κενό γίνεται δομικά
    # αδύνατο, όχι απλώς απαγορευμένο).
    all_lisp = {f for f in os.listdir(tests_dir) if f.endswith(".lisp")}
    non_test = {f for f in all_lisp if not f.endswith("-test.lisp")}
    unclassified = non_test - declared_nonsuite
    if unclassified:
        fail("ΑΤΑΞΙΝΟΜΗΤΑ tests/*.lisp (ούτε -test σουίτα ούτε δηλωμένο nonsuite): %s"
             % sorted(unclassified))
    stale_nonsuite = declared_nonsuite - all_lisp
    if stale_nonsuite:
        fail("nonsuite δηλώσεις για ΑΝΥΠΑΡΚΤΑ αρχεία (stale): %s" % sorted(stale_nonsuite))

    expected = {f[:-len("-test.lisp")] for f in os.listdir(tests_dir)
                if f.endswith("-test.lisp")} - declared_not_gated - VERIFIER_STAGE_ONLY
    missing = expected - set(suites)
    if missing:
        fail("ΛΕΙΠΟΥΝ σουίτες από το gated set (σιωπηλή αφαίρεση;): %s"
             % sorted(missing))
    # [ΣΤ] ΑΜΦΙΔΡΟΜΑ: extra σουίτα (εκτός δηλωμένου συνόλου) = FAIL —
    # «ακριβές set» σημαίνει ισότητα, όχι υπερσύνολο.
    extra = set(suites) - expected
    if extra:
        fail("ΕΠΙΠΛΕΟΝ σουίτες εκτός του αναμενόμενου set: %s" % sorted(extra))

    # [RATCHET-5] RATCHET ΣΟΥΙΤΩΝ: ακριβής set-ισότητα με το ΠΑΓΩΜΕΝΟ μητρώο.
    # Πιάνει ό,τι το `expected` ΔΕΝ μπορούσε να πιάσει, επειδή το ίδιο το
    # `expected` παράγεται από τον δίσκο: διαγραμμένη σουίτα εξαφανίζεται και από
    # τα δύο σκέλη της σύγκρισης· εξαιρεθείσα σουίτα φεύγει «νόμιμα». Το μητρώο
    # είναι ΑΝΕΞΑΡΤΗΤΗ, committed αυθεντία — η μόνη που επιβιώνει και των δύο.
    census = load_suite_census(app_root, tests_dir)
    removed = census - expected
    if removed:
        fail("ΣΙΩΠΗΛΗ ΑΦΑΙΡΕΣΗ σουίτας (διαγραφή ή εξαίρεση) — στο μητρώο αλλά ΕΚΤΟΣ "
             "gated set: %s. Αφαίρεση απαιτεί ΡΗΤΗ μεταβολή του docker/suite-census.txt"
             % sorted(removed))
    added = expected - census
    if added:
        fail("ΑΔΗΛΩΤΗ σουίτα (τρέχει αλλά ΔΕΝ είναι στο μητρώο): %s. Πρόσθεσέ τη στο "
             "docker/suite-census.txt ώστε η αφαίρεσή της να κοκκινίζει στο μέλλον"
             % sorted(added))
    for suite, line in sorted(suites.items()):
        check_result_line(suite, line)

    with open(vp_path, encoding="utf-8") as fh:
        vp = json.load(fh)
    if vp.get("proof") != "lawmax/verifier-proof/1":
        fail("verifier-proof: άγνωστο σχήμα %r" % vp.get("proof"))
    if vp.get("git_commit") != sp.get("git_commit"):
        fail("verifier-proof: git_commit ≠ standalone-proof")
    for k in ("verify_py_sha256", "verify_mjs_sha256", "verify_canonical_py_sha256",
              "verify_temporal_py_sha256", "verify_release_py_sha256"):
        if not HEX64.match(vp.get(k, "")):
            fail("verifier-proof: %s ΔΕΝ είναι 64-hex: %r" % (k, vp.get(k)))
    if vp.get("gates") != EXPECTED_GATES:
        fail("verifier-proof: gates ≠ αναμενόμενα: %r" % vp.get("gates"))

    # [ΣΤ] ΕΠΑΝΥΠΟΛΟΓΙΣΜΟΣ hashes από τα ΠΡΑΓΜΑΤΙΚΑ αρχεία — όχι μόνο μορφή.
    if app_root:
        core = os.path.join(app_root, "orchestrator.core")
        if sp.get("orchestrator_core_sha256") != sha256_file(core):
            fail("orchestrator_core_sha256 ≠ επανυπολογισμός από %s" % core)
        cm = os.path.join(app_root, "component-manifest.sexp")
        if sp.get("component_manifest_sha256") != sha256_file(cm):
            fail("component_manifest_sha256 ≠ επανυπολογισμός")
        logs = sorted(os.path.join(proof_dir, "logs", f)
                      for f in os.listdir(os.path.join(proof_dir, "logs")))
        h = hashlib.sha256()
        for lf in logs:
            with open(lf, "rb") as fh:
                h.update(fh.read())
        if sp.get("logs_sha256") != h.hexdigest():
            fail("logs_sha256 ≠ επανυπολογισμός από proof/logs/*")
        for k, rel in (("verify_py_sha256", "deployment/verify/verify.py"),
                       ("verify_mjs_sha256", "deployment/verify/verify.mjs"),
                       ("verify_canonical_py_sha256", "deployment/verify/verify-canonical.py"),
                       ("verify_temporal_py_sha256", "deployment/verify/verify-temporal.py"),
                       ("verify_release_py_sha256", "deployment/verify/verify-release.py")):
            fp = os.path.join(app_root, rel)
            if vp.get(k) != sha256_file(fp):
                fail("%s ≠ επανυπολογισμός από %s" % (k, rel))

    if FAIL:
        print("verify-proof-manifest: %d ΑΠΟΤΥΧΙΕΣ" % len(FAIL))
        for f in FAIL:
            print("  ✗ " + f)
        sys.exit(1)
    print("verify-proof-manifest: OK — %d σουίτες, όλες failed=0, manifests δεσμευμένα"
          % len(suites))

if __name__ == "__main__":
    if len(sys.argv) not in (3, 4):
        print("usage: verify-proof-manifest.py <proof-dir> <tests-dir> [app-root]"); sys.exit(2)
    main(*sys.argv[1:])
