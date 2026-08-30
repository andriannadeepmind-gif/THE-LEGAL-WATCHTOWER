#!/usr/bin/env python3
# PHASE-2-MUTATION-HARNESS.py — persisted, reproducible planted-defect test.
#
# EXACT INVOCATION (from the Phase-2 directory, no arguments):
#     python PHASE-2-MUTATION-HARNESS.py
#
# Exit 0 = every mutation detected, every rule class covered, clean baseline
#          passes, and the frozen digests match.
# Exit 1 = a mutation escaped, a rule class is uncovered, or the baseline failed.
# Exit 3 = precondition failed: strict compile, or a digest does not match the
#          frozen policy/corpus/checker recorded in the run.
#
# WHY THIS FILE EXISTS
#
# R5 finding 3: the R4 "26-class planted-defect test" was not persisted and not
# reproducible. A claimed test that nobody else can run is not evidence. This
# harness is persisted, hashed, and applies a FROZEN corpus that was written
# before the checker was modified.
#
# INVALIDATION RULE (policy: invalidation_rule). The harness records the SHA-256
# of the checker, the policy and the corpus. If the checker changes after the
# freeze, the recorded digest no longer matches and the run is void. This is what
# stops the instrument being tuned until the package passes.

import hashlib
import io
import json
import os
import shutil
import subprocess
import sys
import tempfile

D = os.path.dirname(os.path.abspath(__file__))
CHECKER = "PHASE-2-XCHECK.py"
POLICY = "PHASE-2-CHECKER-POLICY.json"
CORPUS = "PHASE-2-MUTATION-CORPUS.jsonl"
RUNFILE = "PHASE-2-MUTATION-RUN.json"


def digest(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()


def load_corpus():
    recs = []
    for line in io.open(os.path.join(D, CORPUS), encoding="utf-8"):
        if line.strip():
            r = json.loads(line)
            if r.get("kind") != "corpus-header":
                recs.append(r)
    return recs


def set_dotted(obj, key, value):
    parts = key.split(".")
    cur = obj
    for p in parts[:-1]:
        if isinstance(cur, list):
            cur = cur[int(p)]
        else:
            cur = cur[p]
    last = parts[-1]
    if isinstance(cur, list):
        cur[int(last)] = value
    else:
        cur[last] = value


def apply_mutation(root, rec):
    """Return True if the mutation actually changed the working copy."""
    path = os.path.join(root, rec["file"])
    before = open(path, "rb").read()
    op = rec["op"]

    if op == "append":
        with io.open(path, "a", encoding="utf-8", newline="") as f:
            f.write(rec["text"])

    elif op == "replace":
        t = io.open(path, encoding="utf-8").read()
        if rec["find"] not in t:
            return False
        t = t.replace(rec["find"], rec["text"], 1)
        io.open(path, "w", encoding="utf-8", newline="").write(t)

    elif op == "json_set":
        obj = json.load(io.open(path, encoding="utf-8"))
        set_dotted(obj, rec["key"], rec["value"])
        with io.open(path, "w", encoding="utf-8", newline="\n") as f:
            json.dump(obj, f, indent=2, ensure_ascii=False)
            f.write("\n")

    elif op == "json_append_supporting":
        obj = json.load(io.open(path, encoding="utf-8"))
        obj.setdefault("supporting_files", []).append(rec["value"])
        with io.open(path, "w", encoding="utf-8", newline="\n") as f:
            json.dump(obj, f, indent=2, ensure_ascii=False)
            f.write("\n")

    else:
        raise SystemExit("unknown mutation op %r in %s" % (op, rec["id"]))

    return open(path, "rb").read() != before


def run_checker(root):
    return subprocess.run([sys.executable, CHECKER], cwd=root,
                          capture_output=True, text=True).returncode


def main():
    # ---- precondition: strict, warning-free compile (policy: mandatory) ------
    pc = subprocess.run([sys.executable, "-W", "error::SyntaxWarning",
                         "-m", "py_compile", os.path.join(D, CHECKER)],
                        capture_output=True, text=True)
    if pc.returncode != 0:
        print("PRECONDITION FAILED — checker does not compile warning-free:")
        print(pc.stderr.strip()[-900:])
        return 3
    print("precondition: strict warning-free compile ... PASS")

    digests = {CHECKER: digest(os.path.join(D, CHECKER)),
               POLICY: digest(os.path.join(D, POLICY)),
               CORPUS: digest(os.path.join(D, CORPUS))}
    for k, v in digests.items():
        print("  %-32s %s" % (k, v))

    policy = json.load(io.open(os.path.join(D, POLICY), encoding="utf-8"))
    required_classes = set(r["id"] for r in policy["required_rule_classes"])
    corpus = load_corpus()
    covered = set(r["rule_class"] for r in corpus)

    work = tempfile.mkdtemp(prefix="p2mut-")
    root = os.path.join(work, "phase-2")
    shutil.copytree(D, root)

    try:
        base = run_checker(root)
        print("\nbaseline (untouched copy): exit %d  %s"
              % (base, "PASS" if base == 0 else "**FAIL**"))

        rows = []
        for rec in corpus:
            src = os.path.join(D, rec["file"])
            dst = os.path.join(root, rec["file"])
            shutil.copyfile(src, dst)                 # restore before each test
            applied = apply_mutation(root, rec)
            rc = run_checker(root)
            shutil.copyfile(src, dst)                 # revert
            rows.append((rec["id"], rec["rule_class"], rec.get("covers", ""),
                         applied, rc, applied and rc != 0))

        after = run_checker(root)
    finally:
        shutil.rmtree(work, ignore_errors=True)

    print("\n%-8s %-24s %-6s %-5s %s" % ("id", "rule class", "applied", "exit", "verdict"))
    print("-" * 78)
    for mid, cls, covers, applied, rc, ok in rows:
        print("%-8s %-24s %-6s %-5d %s" % (mid, cls, applied, rc, "PASS" if ok else "**FAIL**"))
        if not ok:
            print("         covers: %s" % covers)

    escaped = [r for r in rows if not r[5]]
    uncovered = sorted(required_classes - covered)

    print("\nbaseline after all reverts: exit %d" % after)
    print("mutations: %d   detected: %d   escaped: %d"
          % (len(rows), len(rows) - len(escaped), len(escaped)))
    print("rule classes required: %d   covered: %d   uncovered: %s"
          % (len(required_classes), len(covered & required_classes),
             ", ".join(uncovered) if uncovered else "none"))

    ok = (base == 0 and after == 0 and not escaped and not uncovered)
    print("\nMUTATION RUN: %s" % ("PASS" if ok else "FAIL"))
    record = {"checker_sha256": digests[CHECKER],
              "policy_sha256": digests[POLICY],
              "corpus_sha256": digests[CORPUS],
              "mutations": len(rows),
              "detected": len(rows) - len(escaped),
              "escaped": [r[0] for r in escaped],
              "uncovered_rule_classes": uncovered,
              "baseline_before": base, "baseline_after": after,
              "result": "PASS" if ok else "FAIL"}
    # PERSISTED, not merely printed. R5 finding 3 / HF-043: a result that exists
    # only in a terminal is not evidence. The seal hashes this file, so the run
    # record cannot drift from the run that produced it.
    with io.open(os.path.join(D, RUNFILE), "w", encoding="utf-8", newline="\n") as f:
        json.dump(record, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print("\nrun record written to %s (compare its three digests against the "
          "sealed ones before trusting any CLEAN result):" % RUNFILE)
    print(json.dumps(record, indent=2))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
