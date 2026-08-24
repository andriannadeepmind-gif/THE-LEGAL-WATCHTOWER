#!/usr/bin/env python3
"""ΑΠΟΓΡΑΦΗ ΣΟΥΙΤΩΝ — ΑΚΡΙΒΩΣ ποιες εκτελέστηκαν, μία γραμμή ανά σουίτα.

ΚΑΝΟΝΑΣ: το πλήθος των CHECKS ΔΕΝ είναι πλήθος ΣΟΥΙΤΩΝ. Καταγράφονται χωριστά.
Ό,τι δεν έτρεξε γράφεται NOT-EXECUTED· ό,τι δεν παρσάρεται γράφεται UNKNOWN.
ΠΟΤΕ PASS χωρίς exit code 0.
"""
import hashlib, json, os, re, subprocess, sys, time, datetime

FROZEN = sys.argv[1]
IMAGE  = sys.argv[2]
WORK   = sys.argv[3]
OUTDIR = sys.argv[4]
ONLY   = sys.argv[5] if len(sys.argv) > 5 else None

os.makedirs(f"{OUTDIR}/logs", exist_ok=True)
os.makedirs(WORK, exist_ok=True)

excl_path = os.path.join(FROZEN, "docker/standalone-suite-exclusions.txt")
suite_excl, nonsuite = set(), set()
for line in open(excl_path, encoding="utf-8"):
    s = line.split("#")[0].strip()
    if not s:
        continue
    if s.startswith("nonsuite:"):
        nonsuite.add(s.split(":", 1)[1].strip())
    else:
        suite_excl.add(s)

suites = sorted(f for f in os.listdir(os.path.join(FROZEN, "tests")) if f.endswith("-test.lisp"))
if ONLY:
    suites = [s for s in suites if ONLY in s]
if not suites:
    print("::error::ΚΕΝΟ inventory — καμία ψευδο-επιτυχία"); sys.exit(2)

RESULT_RE = re.compile(r"(\d+)\s+passed,\s+(\d+)\s+failed")
rows, t0 = [], time.time()

for i, fn in enumerate(suites, 1):
    name = fn[:-len("-test.lisp")]
    path = os.path.join(FROZEN, "tests", fn)
    sha  = hashlib.sha256(open(path, "rb").read()).hexdigest()
    gated = name not in suite_excl
    before = set()
    up = os.path.join(WORK, "upper")
    if os.path.isdir(up):
        for r, _d, fs in os.walk(up):
            for f in fs:
                before.add(os.path.relpath(os.path.join(r, f), up))
    t = time.time()
    proc = subprocess.run(
        ["docker", "run", "--rm", "--privileged",
         "-v", f"{FROZEN}:/corpus:ro", "-v", f"{WORK}:/work", IMAGE,
         "sbcl", "--script", "/app/docker/run-standalone-test.lisp", f"/app/tests/{fn}"],
        capture_output=True, text=True, timeout=1800)
    dur = round(time.time() - t, 1)
    out = proc.stdout + proc.stderr
    open(f"{OUTDIR}/logs/{name}.log", "w", encoding="utf-8").write(out)
    m = RESULT_RE.findall(out)
    passed, failed = (int(m[-1][0]), int(m[-1][1])) if m else (None, None)
    after = set()
    if os.path.isdir(up):
        for r, _d, fs in os.walk(up):
            for f in fs:
                after.add(os.path.relpath(os.path.join(r, f), up))
    wrote = sorted(x for x in (after - before) if not x.startswith(("fasl/", "work/", "tmp/")))
    rows.append({"suite": name, "file": f"tests/{fn}", "sha256": sha, "gated": gated,
                 "exit": proc.returncode, "passed": passed, "failed": failed,
                 "seconds": dur, "corpus_writes": wrote})
    print(f"[{i}/{len(suites)}] {name}: exit={proc.returncode} "
          f"checks={passed if passed is not None else 'UNKNOWN'}/{failed if failed is not None else 'UNKNOWN'} {dur}s",
          flush=True)

ok      = [r for r in rows if r["exit"] == 0]
bad     = [r for r in rows if r["exit"] != 0]
unknown = [r for r in rows if r["passed"] is None]
checks_p = sum(r["passed"] or 0 for r in rows)
checks_f = sum(r["failed"] or 0 for r in rows)

with open(f"{OUTDIR}/suite-census.sexp", "w", encoding="utf-8") as fh:
    fh.write(";;;; experiment/artifacts/suite-census.sexp — ΠΑΡΑΓΟΜΕΝΟ από census.py\n")
    fh.write(";;;; ΣΟΥΙΤΕΣ ≠ CHECKS. Τα δύο μεγέθη δηλώνονται ΧΩΡΙΣΤΑ και δεν αθροίζονται.\n\n")
    fh.write("(:lawmax-suite-census/1\n")
    fh.write(f' :ran-at "{datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}"\n')
    fh.write(f' :runner-image "{IMAGE}"\n')
    fh.write(' :inventory-rule "glob tests/*-test.lisp ΜΕΙΟΝ docker/standalone-suite-exclusions.txt (Η ΜΙΑ έδρα του corpus)"\n')
    fh.write(f' :suite-files {len(suites)}\n')
    fh.write(f' :declared-suite-exclusions {len(suite_excl)}\n')
    fh.write(f' :declared-nonsuite-files {len(nonsuite)}\n')
    fh.write(f' :executed {len(rows)}\n :exit-zero {len(ok)}\n :exit-nonzero {len(bad)}\n')
    fh.write(f' :unparsed-result {len(unknown)}\n')
    fh.write(f' :checks-passed-total {checks_p}\n :checks-failed-total {checks_f}\n')
    fh.write(f' :wallclock-seconds {round(time.time()-t0)}\n')
    fh.write(" :suites\n  (")
    for i, r in enumerate(rows):
        pre = "" if i == 0 else "   "
        p = r["passed"] if r["passed"] is not None else ":unknown"
        f_ = r["failed"] if r["failed"] is not None else ":unknown"
        w = " ".join(f'"{x}"' for x in r["corpus_writes"]) or ""
        fh.write(f'{pre}(:suite "{r["suite"]}" :file "{r["file"]}" :sha256 "{r["sha256"]}"\n')
        fh.write(f'    :gated {"t" if r["gated"] else "nil"} :exit {r["exit"]} '
                 f':checks-passed {p} :checks-failed {f_} :seconds {r["seconds"]}\n')
        fh.write(f'    :corpus-write-attempts ({w}))\n')
    fh.write("  ))\n")

print(json.dumps({"suite_files": len(suites), "executed": len(rows), "exit_zero": len(ok),
                  "exit_nonzero": len(bad), "unparsed": len(unknown),
                  "checks_passed": checks_p, "checks_failed": checks_f}))
sys.exit(0 if not bad else 1)
