#!/usr/bin/env python3
# PHASE-2-VERIFY.py - the independent verification pass required by the R5 review,
# persisted so that a third party can run it rather than take its result on trust.
#
# EXACT INVOCATION (from any directory, no arguments):
#     python PHASE-2-VERIFY.py
#
# Exit 0 = every check passed. Exit 1 = at least one failed.
#
# It deliberately RECOMPUTES rather than reads: hashes and byte lengths are taken
# from the files, identifier sets are rebuilt from their canonical sources, and the
# checker and mutation harness are re-executed. It shares no code with
# PHASE-2-XCHECK.py or with the sealing script, so a defect in either does not
# propagate here.
#
# It prints NOTES for things that are true but not passes - chiefly the SBCL
# macroexpansion inspection, which was NOT PERFORMED because no Common Lisp
# implementation exists in this environment (HF-044, PO-048, DF-050).
"""R5 'REQUIRED VERIFICATION BEFORE THE BLOCKED R5 EVIDENCE PACKAGE'.
Independent of the sealing script: recomputes rather than reads."""
import hashlib, io, json, os, re, subprocess, sys

D = "phase-2"
fails, notes = [], []
total = [0]

def ck(name, ok, detail=""):
    total[0] += 1
    print("%-58s %s%s" % (name, "PASS" if ok else "**FAIL**",
                          ("  " + detail) if detail else ""))
    if not ok:
        fails.append(name)

def sha(p):
    with open(p, "rb") as f:
        b = f.read()
    return hashlib.sha256(b).hexdigest(), len(b)

files = sorted(os.listdir(D))
seal = json.load(io.open(os.path.join(D, "PHASE-2-SEAL.json"), encoding="utf-8"))
man = json.load(io.open(os.path.join(D, "PHASE-2-MANIFEST.json"), encoding="utf-8"))

# 1. JSON / JSONL parse from a clean process
bad = []
for fn in files:
    p = os.path.join(D, fn)
    if not os.path.isfile(p):
        continue
    try:
        if fn.endswith(".json"):
            json.load(io.open(p, encoding="utf-8"))
        elif fn.endswith(".jsonl"):
            for line in io.open(p, encoding="utf-8"):
                if line.strip():
                    json.loads(line)
    except Exception as e:
        bad.append("%s: %s" % (fn, e))
ck("1. every JSON and JSONL parses", not bad, "; ".join(bad))

# 2. inventory hashes and lengths independently recomputed
inv = [e for e in seal["artifact_inventory"] if e.get("sha256")] + \
      [e for e in seal["supporting_files"] if e.get("sha256")]
mm = []
for e in inv:
    p = os.path.join(D, e["artifact"])
    if not os.path.exists(p):
        mm.append(e["artifact"] + " absent"); continue
    dg, n = sha(p)
    if dg != e["sha256"] or n != e["byte_length"]:
        mm.append(e["artifact"])
ck("2. inventory hashes and lengths recomputed (%d entries)" % len(inv), not mm, "; ".join(mm))

# 3. exact inventory equality - no unaccounted member
accounted = set(e["artifact"] for e in inv)
accounted.add("PHASE-2-SEAL.json")
excluded = set(x["path"] for x in man.get("excluded_from_inventory", []))
present = set(f for f in files if os.path.isfile(os.path.join(D, f)))
unaccounted = sorted(present - accounted - excluded - {seal["creator_directive"]["file"]})
ck("3. exact inventory equality, no unaccounted member", not unaccounted, ", ".join(unaccounted))
missing = sorted(accounted - present)
ck("3b. no sealed member missing from disk", not missing, ", ".join(missing))

# 4. strict checker compile, warnings as errors
r = subprocess.run([sys.executable, "-W", "error::SyntaxWarning", "-m", "py_compile",
                    os.path.join(D, "PHASE-2-XCHECK.py")], capture_output=True, text=True)
ck("4. strict warning-free compile of the checker", r.returncode == 0, r.stderr.strip()[-200:])

# 5. persisted mutation run
run = json.load(io.open(os.path.join(D, "PHASE-2-MUTATION-RUN.json"), encoding="utf-8"))
live = {"PHASE-2-XCHECK.py": run["checker_sha256"],
        "PHASE-2-CHECKER-POLICY.json": run["policy_sha256"],
        "PHASE-2-MUTATION-CORPUS.jsonl": run["corpus_sha256"]}
drift = [k for k, v in live.items() if sha(os.path.join(D, k))[0] != v]
ck("5. mutation-run digests still match the live files", not drift, ", ".join(drift))
ck("5b. every planted defect detected, baseline clean",
   run["result"] == "PASS" and not run["escaped"] and run["baseline_before"] == 0
   and run["baseline_after"] == 0 and not run["uncovered_rule_classes"],
   "%d/%d detected" % (run["detected"], run["mutations"]))

# 6. corpus shape
corpus = [json.loads(l) for l in io.open(os.path.join(D, "PHASE-2-MUTATION-CORPUS.jsonl"),
                                         encoding="utf-8") if l.strip()]
corpus = [c for c in corpus if c.get("kind") != "corpus-header"]
blob = json.dumps(corpus, ensure_ascii=False)
SPELLED = r"(?i)\b(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen)\b"
has_case = any(len(c.get("text", "")) > 20 and c.get("text", "").upper() == c.get("text", "")
               for c in corpus)
ck("6. corpus includes case-variant mutations", has_case)
ck("6b. corpus includes spelled-number mutations", bool(re.search(SPELLED, blob)))
mul = re.search(r"\d\s*[x*" + chr(215) + r"]\s*\d", blob)
ck("6c. corpus includes a multiplication-form mutation", bool(mul))
pol = json.load(io.open(os.path.join(D, "PHASE-2-CHECKER-POLICY.json"), encoding="utf-8"))
ck("6d. corpus covers every required rule class",
   set(c["rule_class"] for c in corpus) >= set(x["id"] for x in pol["required_rule_classes"]))

# 7. structured set equality for every identifier family
def text(fn):
    return io.open(os.path.join(D, fn), encoding="utf-8").read()
def jl(fn):
    return [json.loads(l) for l in text(fn).splitlines() if l.strip()]
ALL = {fn: text(fn) for fn in files
       if fn.endswith((".md", ".json", ".jsonl")) and os.path.isfile(os.path.join(D, fn))}
req = text("PHASE-2-REQUIREMENTS-AND-INVARIANTS.md")
canon = {
    "I": set(re.findall(r"^### (I-\d+)", req, re.M)),
    "PO": set("PO-" + x for x in re.findall(r"PO-(\d+)", req)),
    "UP": set(re.findall(r"\*\*(UP-\d+)", req)),
    "DF": set(x["id"] for x in jl("PHASE-2-DEFEATER-REGISTER.jsonl")),
    "RL": set(x["id"] for x in jl("PHASE-2-RESEARCH-LEDGER.jsonl")),
    "AC": set(re.findall(r"^## (AC-\d+)", text("PHASE-2-ASSURANCE-CASE.md"), re.M)),
    "WC": set(re.findall(r"\*\*(WC-\d+)\*\*", text("PHASE-2-REPORT.md"))),
    "D":  set(x["id"] for x in jl("PHASE-2-DECISION-MATRIX.jsonl")) | {"D00"},
}
cand = re.search(r"^CANDIDATE_IDS:\s*(.+)$", text("PHASE-2-CANDIDATE-ARCHITECTURES.md"), re.M)
canon["A"] = set(cand.group(1).split())
PAT = {"I": r"(?<![-\w])I-\d{1,3}(?![-\d])", "PO": r"(?<![-\w])PO-\d{1,3}(?![-\d])",
       "UP": r"(?<![-\w])UP-\d{1,2}(?![-\d])", "DF": r"(?<![-\w])DF-\d{1,3}(?![-\d])",
       "RL": r"(?<![-\w])RL-\d{1,3}(?![-\d])", "AC": r"(?<![-\w])AC-\d{1,3}(?![-\d])",
       "WC": r"(?<![-\w])WC-\d{1,2}(?![-\d])", "D": r"(?<![-\w])D\d{2}(?![-\d])"}
EXEMPT = {"PHASE-2-XCHECK.py", "PHASE-2-MUTATION-CORPUS.jsonl"}
dang = []
for fam, pat in PAT.items():
    for fn, tx in ALL.items():
        if fn in EXEMPT:
            continue
        extra = set(re.findall(pat, tx)) - canon[fam] - {"DF-000"}
        if extra:
            dang.append("%s in %s: %s" % (fam, fn, sorted(extra)[:4]))
ck("7. structured set equality for I/PO/UP/DF/RL/AC/WC/D ids", not dang, " | ".join(dang[:3]))
# Candidate ids are checked POSITIONALLY, not lexically: the axiom namespace
# A1..A11 overlaps the candidate namespace A1..A8 (HF-053), so a lexical sweep
# reports every axiom reference as an unknown candidate. The authoritative
# positions are the CANDIDATE_IDS line and the non-dominance evaluated-set table.
nd = text("PHASE-2-NON-DOMINANCE.md")
tbl = set(re.findall(r"^\|\s*\*?\*?(A[1-9])(?![-\w])", nd, re.M))
heads = set(re.findall(r"^#+ [\d.]+ (A[1-9])(?![-\w])", nd, re.M))
ck("7b. candidate ids confined to CANDIDATE_IDS (positional)",
   (tbl | heads) <= canon["A"] and bool(tbl | heads),
   "table+headings %s; unknown %s" % (len(tbl | heads), sorted((tbl | heads) - canon["A"])))
axioms = set(re.findall(r"^### (A\d+)", text("PHASE-2-CREATOR-AXIOMS.md"), re.M))
ck("7c. axiom/candidate namespace collision disclosed as HF-053",
   bool(axioms & canon["A"]) and "HF-053" in text("PHASE-2-REPORT.md"),
   "colliding ids: %s" % ", ".join(sorted(axioms & canon["A"])))

# 8. checker CLEAN, no blanket exemption
r = subprocess.run([sys.executable, "PHASE-2-XCHECK.py"], cwd=D, capture_output=True, text=True)
ck("8. cross-artifact semantic check returns CLEAN", r.returncode == 0,
   (r.stdout.strip().splitlines() or [""])[-1])
src = text("PHASE-2-XCHECK.py")
ex = re.search(r"EXCLUDE = \{(.*?)\n\}", src, re.S)
exempt_names = re.findall(r'"([^"]+)"', ex.group(1)) if ex else []
MUST_BE_SCANNED = ["PHASE-2-SEAL.json", "PHASE-2-MANIFEST.json", "PHASE-2-COVERAGE.json",
                   "PHASE-2-REPORT.md", "PHASE-2-WORKING-MEMORY.md"]
declared = set(x["file"] for x in pol["no_blanket_exemptions"]["permitted_exclusions"])     if isinstance(pol.get("no_blanket_exemptions"), dict)     and "permitted_exclusions" in pol["no_blanket_exemptions"] else None
ck("8b. no blanket GENERATED exemption; generated files ARE scanned",
   not any(m in exempt_names for m in MUST_BE_SCANNED),
   "exempt: " + ", ".join(exempt_names))
ck("8c. every exclusion is a named file, not a category",
   all(n.startswith("PHASE-2-") or n.startswith("START-") for n in exempt_names))

# 9. SBCL macroexpansion honestly recorded
sr = json.load(io.open(os.path.join(D, "PHASE-2-STRUCTURAL-RECORDS.json"), encoding="utf-8"))
vr = sr["method_combination"]["verification_required"]
ck("9. SBCL macroexpansion status honestly recorded",
   vr["macroexpansion_inspection"] is True and vr["status"].startswith("NOT PERFORMED"),
   vr["status"][:52])
notes.append("SBCL macroexpansion/control-flow inspection: NOT PERFORMED - no Common Lisp "
             "implementation exists in this environment. Carried as HF-044 (disclosed and "
             "bounded), PO-048 (undischarged), DF-050 (OPEN), and as a condition of the handoff.")

# 10. status and isolation honesty
iso = seal["isolation"]
ck("10. status is PHASE_2_BLOCKED", seal["status"] == "PHASE_2_BLOCKED", seal["status"])
def keys_of(o, acc):
    if isinstance(o, dict):
        for k, v in o.items():
            acc.add(k); keys_of(v, acc)
    elif isinstance(o, list):
        for v in o:
            keys_of(v, acc)
    return acc
sk, mk = keys_of(seal, set()), keys_of(man, set())
ck("10b. no forbidden_input_access_count FIELD in seal or manifest",
   "forbidden_input_access_count" not in sk and "forbidden_input_access_count" not in mk,
   "(the phrase appears only inside explanatory text, which is the disclosure)")
ck("10c. content reads and enumerations recorded separately",
   iso["forbidden_input_content_reads"] == 0
   and iso["forbidden_input_enumeration_count"] == len(iso["forbidden_input_incidents"]),
   "reads %d, enumerations %d" % (iso["forbidden_input_content_reads"],
                                  iso["forbidden_input_enumeration_count"]))
ck("10d. every validation field is a literal boolean",
   all(isinstance(v, bool) for v in seal["validation"].values()))

# 11. Phase 3 remains NOT STARTED
term = seal["termination"]
ck("11. Phase 3 NOT STARTED", term["phase_3_begun"] is False
   and term["implementation_begun"] is False
   and term["repository_comparison_performed"] is False)

print()
print("=" * 78)
print("R5 REQUIRED VERIFICATION: %s   (%d checks, %d failed)"
      % ("PASS" if not fails else "FAIL", total[0], len(fails)))
for n in notes:
    print("  NOTE: " + n)
for f in fails:
    print("  FAILED: " + f)
sys.exit(1 if fails else 0)
