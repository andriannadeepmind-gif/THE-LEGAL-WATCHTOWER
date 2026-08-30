#!/usr/bin/env python3
# PHASE-2-XCHECK.py - cross-artifact semantic checker for the Phase-2 package.
#
# EXACT INVOCATION (from the Phase-2 directory, no arguments):
#     python PHASE-2-XCHECK.py
#
# Exit 0 = CLEAN
# Exit 1 = ISSUES FOUND
# Exit 2 = SELF-TEST FAILED (the checker is not trustworthy; disregard its verdict)
# Exit 3 = PRECONDITION FAILED (policy/corpus digest or environment)
#
# Deterministic: no network, no clock, no randomness, no environment variables.
# Reads only files inside the Phase-2 directory.
#
# Specification: PHASE-2-CHECKER-POLICY.json (frozen before this file was rebuilt).
# Mutation evidence: PHASE-2-MUTATION-HARNESS.py over PHASE-2-MUTATION-CORPUS.jsonl.
#
# THE ONE RULE THAT MATTERS MOST (R5 finding 1)
# Self-test probes and production scanning use THE SAME COMPILED RULE OBJECT with
# THE SAME FLAGS. In R4 the self-test probed with re.IGNORECASE while production
# scanned without it, so rule WC-2 was untested in production and the active
# heading "...ARE THE SAME TEXT" evaded it. The R4 CLEAN result was FALSE. No call
# site in this file may pass flags; flags live on the Rule.

import collections
import glob
import io
import json
import os
import re
import sys

SELF = os.path.basename(__file__)
D = os.path.dirname(os.path.abspath(__file__))

# Exemptions are enumerated in the frozen policy and nowhere else. There is NO
# blanket exemption for generated files (R5 finding 5): the seal and the manifest
# are scanned exactly like every other artifact.
EXCLUDE = {
    SELF,
    "PHASE-2-MUTATION-CORPUS.jsonl",     # contains planted defect strings by design
    "PHASE-2-MUTATION-HARNESS.py",       # applies them
    "PHASE-2-CHECKER-POLICY.json",       # quotes rule ids and rationale
    "START-THE-LEGAL-WATCHTOWER-PHASE-2.md",  # creator directive: permitted input
}

PATHS = (sorted(glob.glob(os.path.join(D, "*.md")))
         + sorted(glob.glob(os.path.join(D, "*.jsonl")))
         + sorted(glob.glob(os.path.join(D, "*.json")))
         + sorted(glob.glob(os.path.join(D, "*.py"))))
ALL = {os.path.basename(p): io.open(p, encoding="utf-8").read()
       for p in PATHS if os.path.basename(p) not in EXCLUDE}

issues = []


def bad(kind, fn, detail, ctx=""):
    issues.append({"kind": kind, "file": fn, "detail": detail,
                   "context": " ".join(ctx.split())[:190]})


def jl(name):
    return [json.loads(l) for l in ALL[name].splitlines() if l.strip()]


def load(name):
    return json.loads(ALL[name])


# ---------------------------------------------------------------------------
# RULE OBJECTS - compiled once; used identically by self-test and production.
# ---------------------------------------------------------------------------
class Rule(object):
    __slots__ = ("rid", "kind", "rx", "why")

    def __init__(self, rid, kind, pattern, flags, why):
        self.rid = rid
        self.kind = kind
        self.why = why
        self.rx = re.compile(pattern, flags)

    def finditer(self, text):
        return self.rx.finditer(text)

    def search(self, text):
        return self.rx.search(text)


IC = re.IGNORECASE

# Withdrawn-claim wordings. Absolute blacklist, case-insensitive, no exceptions.
STALE_RULES = [
    Rule("WC-1", "stale-claim", r"model/code gap", IC, "gap-elimination claim"),
    Rule("WC-2a", "stale-claim", r"same text", IC, "text-identity claim"),
    Rule("WC-2b", "stale-claim", r"proved text and the executed text are identical", IC, "text-identity claim"),
    Rule("WC-2c", "stale-claim", r"proved text\s*=\s*executed text", IC, "text-identity claim"),
    Rule("WC-2d", "stale-claim", r"identity of proved and executed", IC, "text-identity claim"),
    Rule("WC-2e", "stale-claim", r"verified and executed text can be identical", IC, "text-identity claim"),
    Rule("WC-3", "stale-claim", r"imports no effectful symbol", IC, "import-purity claim"),
    Rule("WC-4a", "stale-claim", r"run\s+unconditionally", IC, "unconditional-record claim"),
    Rule("WC-4b", "stale-claim", r"unconditionally, including on veto", IC, "unconditional-record claim"),
    Rule("WC-5a", "stale-claim", r"cannot be bypassed by calling", IC, "bypass-immunity claim"),
    Rule("WC-5b", "stale-claim", r"only reachable through the effective method", IC, "bypass-immunity claim"),
    Rule("WC-6a", "stale-claim", r"enforced rather than advisory", IC, "lock-authority claim"),
    Rule("WC-6b", "stale-claim", r"locks make office boundaries", IC, "lock-authority claim"),
    Rule("WC-6c", "stale-claim", r"make the boundary enforced", IC, "lock-authority claim"),
    Rule("WC-6d", "stale-claim", r"as authority and dependency boundaries", IC, "lock-authority claim"),
    Rule("WC-7", "stale-claim", r"same kernel that (audits|produces)", IC, "self-audit circularity"),
    Rule("WC-8a", "stale-claim", r"K_v\s*\(\s*(the\s+)?record\s*\)", IC, "elided artifact store"),
    Rule("WC-8b", "stale-claim", r"K_v\(R\)(?!\s*,)", IC, "elided artifact store"),
    Rule("WC-9a", "stale-claim", r"issue\(PROPOSAL\)", IC, "proposal-as-entry"),
    Rule("WC-9b", "stale-claim", r"emit\s+PROPOSAL", IC, "proposal-as-entry"),
    Rule("WC-9c", "stale-claim", r"kind\s+`?PROPOSAL`?(?![-\w])", IC, "proposal-as-entry"),
    Rule("WC-11a", "stale-claim", r"enforcement point for warranted", IC, "metaclass-as-enforcement"),
    Rule("WC-11b", "stale-claim", r"metaclass is the enforcement point", IC, "metaclass-as-enforcement"),
    Rule("WC-11c", "stale-claim", r"ENFORCED PERSISTENCE", IC, "metaclass-as-enforcement"),
    Rule("WC-11d", "stale-claim", r"enforced by (a|the) metaclass", IC, "metaclass-as-enforcement"),
    Rule("WC-12a", "stale-claim", r"guaranteed to complete", IC, "cleanup-completion claim"),
    Rule("WC-12b", "stale-claim", r"every (:)?record form", IC, "cleanup-completion claim"),
    Rule("WC-12c", "stale-claim", r"(all|every) cleanup forms? (run|complete)", IC, "cleanup-completion claim"),
]

# Current counts restated in prose. Numeric, spelled, hyphenated, capitalised and
# multiplication forms (R5 finding 5).
_SPELLED = (r"(?:one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|"
            r"thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|"
            r"twenty|thirty|forty|fifty|sixty)(?:-(?:one|two|three|four|five|six|"
            r"seven|eight|nine))?")
_NUM = r"(?<![.\-\w])\d+"
_QTY = r"(?:" + _NUM + r"|(?<![-\w])" + _SPELLED + r")"
_NOUNS = (r"(?:invariants|proof obligations|obligations|defeaters|contenders|"
          r"sources|architectures|candidates|fault classes|audit rounds|"
          r"assurance claims|surfaces|findings|properties|capabilities|"
          r"open defeaters|unproved obligations|replacement challenges|"
          r"out-of-scope classes|classes)")

# Up to two intervening adjectives are allowed between the quantity and the noun.
# R5 caught "fourteen DECLARED fault classes" that an adjacency-only rule missed;
# this is a strengthening, and MC-055 locks it in.
_ADJ = r"(?:\s+(?!are|were|remain)[a-z-]+){0,2}"
# A THRESHOLD is not a count. "at least three contenders" is a fixed requirement
# quoted from the acceptance contract and cannot drift, so it is not drift. This
# is a precision fix, not a relaxation: MC-056 proves a real count in the same
# sentence shape still fires.
_NOTHRESH = r"(?<!at least )(?<!at most )(?<!no fewer than )(?<!minimum of )(?<!maximum of )"

COUNT_RULES = [
    Rule("CNT-QTY", "count-drift", _NOTHRESH + _QTY + _ADJ + r"\s+" + _NOUNS + r"(?![-\w])", IC,
         "quantity + counted noun restated in prose"),
    Rule("CNT-MUL", "count-drift", _NUM + r"\s*[x*×]\s*\d+(\s*=\s*\d+)?", IC,
         "matrix multiplication expression restated"),
    Rule("CNT-ARE", "count-drift",
         r"(?<![-\w])(?:" + _SPELLED + r")" + _ADJ + r"\s+" + _NOUNS + r"\s+(?:are|were|remain)", IC,
         "spelled count asserted about a set"),
]

CANON_PREFIX = re.compile(
    r"^\s*(?:-\s*)?(CANDIDATE_IDS|ORIGINAL_SYNTHESES|AUDIT_ROUNDS|DISTINCT_[A-Z_]+)\s*:")

# ---------------------------------------------------------------------------
# SELF-TEST - runs first, using the SAME Rule objects production uses.
# ---------------------------------------------------------------------------
def _r(rid):
    for r in STALE_RULES + COUNT_RULES:
        if r.rid == rid:
            return r
    raise KeyError(rid)


PROBES = [
    # (rule id, probe string, expected)
    ("WC-2a", "## 1. THE VERIFIED TEXT AND THE RUNNING TEXT ARE THE SAME TEXT", True),
    ("WC-2a", "proved and executed are the same text", True),
    ("WC-2a", "Proved And Executed Are The Same Text", True),
    ("WC-2d", "the ACL2 identity of proved and executed text", True),
    ("WC-2e", "verified and executed text can be identical", True),
    ("WC-1", "there is NO MODEL/CODE GAP", True),
    ("WC-6a", "Enforced Rather Than Advisory", True),
    ("WC-11c", "ENFORCED PERSISTENCE, ACCESS CONTROL", True),
    ("WC-11d", "the migration warrant is enforced by a metaclass", True),
    ("CNT-QTY", "The design has 47 invariants.", True),
    ("CNT-QTY", "Thirty-eight proof obligations are assigned.", True),
    ("CNT-QTY", "fourteen fault classes", True),
    ("CNT-QTY", "eight open defeaters", True),
    ("CNT-QTY", "five unproved obligations", True),
    ("CNT-QTY", "See I-47 invariants list.", False),
    ("CNT-QTY", "under L5 sources lawfully replace", False),
    ("CNT-MUL", "the matrix is 37 x 14 cells", True),
    ("CNT-MUL", "46 x 15 = 690", True),
    ("CNT-ARE", "Five properties are unproved.", True),
    ("CNT-QTY", "specifies fourteen declared fault classes", True),
    ("CNT-QTY", "against at least three contenders", False),
    ("CNT-QTY", "evaluated three contenders", True),
    ("CNT-QTY", "six explicitly unproved properties", True),
]


def selftest():
    f = []
    seen = collections.Counter()
    for r in STALE_RULES + COUNT_RULES:
        seen[r.rid] += 1
        if any(ord(c) < 32 for c in r.rx.pattern):
            f.append("control character in rule %s" % r.rid)
        if r.rx.flags & re.IGNORECASE == 0:
            f.append("rule %s is not case-insensitive; policy requires IGNORECASE" % r.rid)
    for rid, n in seen.items():
        if n > 1:
            f.append("duplicate rule id %s" % rid)
    for rid, probe, expect in PROBES:
        got = bool(_r(rid).search(probe))     # SAME object, SAME flags as production
        if got != expect:
            f.append("rule %s on %r gave %s, expected %s" % (rid, probe, got, expect))
    # every declared rule class in the policy must exist here
    try:
        pol = json.load(io.open(os.path.join(D, "PHASE-2-CHECKER-POLICY.json"), encoding="utf-8"))
    except Exception as e:                                   # noqa: BLE001
        f.append("cannot read frozen policy: %s" % e)
    else:
        need = set(c["id"] for c in pol["required_rule_classes"])
        have = {"STALE-CLAIM", "COUNT-DRIFT-PROSE", "COUNT-DRIFT-DERIVED",
                "UP-SET-EQUALITY", "STATUS-DRIFT", "VALIDATION-STRICT",
                "ISOLATION-TRUTH", "SELECTED-CANDIDATE", "DANGLING-REF",
                "STRUCTURAL-RECORD", "SEAL-INVENTORY-HYGIENE"}
        missing = need - have
        if missing:
            f.append("policy requires rule classes not implemented: %s" % sorted(missing))
    return f


_fails = selftest()
if _fails:
    print("=" * 78)
    print("XCHECK SELF-TEST FAILED - the checker is not trustworthy; fix it first.")
    print("=" * 78)
    for line in _fails:
        print("  " + line)
    sys.exit(2)

# ---------------------------------------------------------------------------
# 1 + 2. STALE CLAIMS AND PROSE COUNTS - every artifact, no exemptions.
# ---------------------------------------------------------------------------
for fn, text in ALL.items():
    for rule in STALE_RULES:
        for m in rule.finditer(text):
            bad("stale-claim", fn,
                "%s (%s) at line %d" % (rule.rid, rule.why, text[:m.start()].count("\n") + 1),
                text[max(0, m.start() - 90):m.end() + 90])
    for i, line in enumerate(text.splitlines(), 1):
        if CANON_PREFIX.match(line):
            continue
        for rule in COUNT_RULES:
            m = rule.search(line)
            if m:
                bad("count-drift", fn,
                    "%s: %s (line %d)" % (rule.rid, rule.why, i), line)

# ---------------------------------------------------------------------------
# 3. DERIVED COUNTS - recomputed, never hard-coded.
# ---------------------------------------------------------------------------
REQ = ALL["PHASE-2-REQUIREMENTS-AND-INVARIANTS.md"]
DFS = {r["id"]: r for r in jl("PHASE-2-DEFEATER-REGISTER.jsonl") if r["id"] != "DF-000"}
DM = [r for r in jl("PHASE-2-DECISION-MATRIX.jsonl") if r["id"] != "D00"]
SEAL = load("PHASE-2-SEAL.json")
MAN = load("PHASE-2-MANIFEST.json")
COV = load("PHASE-2-COVERAGE.json")
CANDM = re.search(r"^CANDIDATE_IDS:\s*(.+)$", ALL["PHASE-2-CANDIDATE-ARCHITECTURES.md"], re.M)
CAND_IDS = CANDM.group(1).split() if CANDM else []

LIVE = {
    "defeater_count": len(DFS),
    "defeaters_by_status": dict(sorted(collections.Counter(r["status"] for r in DFS.values()).items())),
    "consequential_decision_count": len(DM),
    "total_contender_count": sum(len(r["candidates"]) for r in DM),
    "dominance_challenge_iteration_count": sum(len(r["dominance_challenges"]) for r in DM),
    "invariant_count": len(set(re.findall(r"^### (I-\d+)", REQ, re.M))),
    "proof_obligation_count": len(set(re.findall(r"PO-\d+", REQ))),
    "system_level_candidate_count": len(CAND_IDS),
    "source_count": len(jl("PHASE-2-RESEARCH-LEDGER.jsonl")),
    "assurance_case_claim_count": len(set(re.findall(r"^## (AC-\d+)", ALL["PHASE-2-ASSURANCE-CASE.md"], re.M))),
    "design_surface_count": len(COV["surfaces"]),
}
for k, v in LIVE.items():
    if k in SEAL.get("counts", {}) and SEAL["counts"][k] != v:
        bad("count-drift", "PHASE-2-SEAL.json",
            "seal.counts.%s = %r but recomputation gives %r" % (k, SEAL["counts"][k], v))

_cs = collections.Counter(s["status"] for s in COV["surfaces"])
if COV["summary"].get("COMPLETE") != _cs.get("COMPLETE") or \
        COV["summary"].get("PARTIAL") != _cs.get("PARTIAL"):
    bad("count-drift", "PHASE-2-COVERAGE.json", "summary disagrees with its own surfaces array")

# ---------------------------------------------------------------------------
# 4. UP-ID SET EQUALITY (R5 finding 6)
# ---------------------------------------------------------------------------
UP_WINDOW = 300
UP_CANON = set(re.findall(r"\*\*(UP-\d+)", REQ))
if not UP_CANON:
    bad("up-set", "PHASE-2-REQUIREMENTS-AND-INVARIANTS.md", "canonical UP enumeration is absent")
for fn, text in ALL.items():
    if fn == "PHASE-2-REQUIREMENTS-AND-INVARIANTS.md":
        continue
    found = set(re.findall(r"(?<![-\w])UP-\d{1,2}(?![-\d])", text))
    if not found:
        continue
    unknown = found - UP_CANON
    if unknown:
        bad("up-set", fn, "cites UP ids outside the canonical set: %s" % sorted(unknown))
    # RE-ENUMERATION, not citation. Citing UP-4 where scope adequacy is discussed
    # is what R5 finding 6 asks for; what it forbids is a second copy of the list.
    # A copy is a CONTIGUOUS run of ids, so the window - not the whole document -
    # is the unit. A window holding three or more ids must hold the exact
    # canonical set or it is a partial re-listing. Corpus: MC-028, MC-029.
    _hits = [(m.start(), m.group(0))
             for m in re.finditer(r"(?<![-\w])UP-\d{1,2}(?![-\d])", text)]
    for _i in range(len(_hits)):
        _win = set(v for p, v in _hits[_i:] if p - _hits[_i][0] <= UP_WINDOW)
        if len(_win) >= 3 and _win != UP_CANON:
            bad("up-set", fn,
                "re-enumerates a strict subset of UP ids (%d of %d) within %d "
                "characters; refer to the canonical list instead of re-listing it"
                % (len(_win), len(UP_CANON), UP_WINDOW), text[_hits[_i][0]:_hits[_i][0] + 160])
            break

# ---------------------------------------------------------------------------
# 5. STATUS DRIFT
# ---------------------------------------------------------------------------
EXPECTED_STATUS = {"DF-026": "BOUNDED", "DF-043": "OPEN", "DF-002": "ELIMINATED"}
for did, want in EXPECTED_STATUS.items():
    got = DFS.get(did, {}).get("status")
    if got != want:
        bad("status-drift", "PHASE-2-DEFEATER-REGISTER.jsonl",
            "%s status is %r, expected %r" % (did, got, want))

for fn, text in ALL.items():
    for did, want in EXPECTED_STATUS.items():
        if want == "OPEN":
            continue
        for m in re.finditer(re.escape(did) + r"[^\n]{0,90}OPEN", text):
            window = text[m.start():m.end() + 24]
            if "->" in window or "→" in window:   # a recorded transition
                continue
            bad("status-drift", fn, "%s presented as OPEN but is %s" % (did, want),
                text[max(0, m.start() - 60):m.end() + 60])

_want_open = sorted(d for d, r in DFS.items() if r["status"] == "OPEN")
_got_open = sorted(SEAL.get("counts", {}).get("open_defeater_ids", []))
if _want_open != _got_open:
    bad("status-drift", "PHASE-2-SEAL.json",
        "open_defeater_ids %r != register %r" % (_got_open, _want_open))

# ---------------------------------------------------------------------------
# 6. VALIDATION STRICTNESS (R5 finding 11) - null is not PASS.
# ---------------------------------------------------------------------------
STATUS = SEAL.get("status")
if STATUS not in ("PHASE_2_COMPLETE", "PHASE_2_BLOCKED"):
    bad("status-drift", "PHASE-2-SEAL.json", "status %r is not an admissible value" % STATUS)
_VAL = SEAL.get("validation", {})
# (a) Type discipline holds under EVERY status. A non-boolean in `validation` is
#     not a weaker assertion, it is a category error, and null is not PASS.
for k, val in _VAL.items():
    if not isinstance(val, bool):
        bad("validation-strict", "PHASE-2-SEAL.json",
            "validation.%s is %r; every validation field must be a literal boolean "
            "under any status (null is not PASS)" % (k, val))
# (b) Under COMPLETE every field must additionally be true.
if STATUS == "PHASE_2_COMPLETE":
    for k, val in _VAL.items():
        if val is not True:
            bad("validation-strict", "PHASE-2-SEAL.json",
                "status is COMPLETE but validation.%s is %r; only literal true passes" % (k, val))
# (c) Do not take the seal's word for what this checker can recompute. Reaching
#     this line means every JSON and JSONL artifact already parsed, so a seal
#     claiming otherwise is false under ANY status.
for k in ("all_json_parse", "all_jsonl_parse"):
    if k in _VAL and _VAL[k] is not True:
        bad("validation-strict", "PHASE-2-SEAL.json",
            "validation.%s is %r, but this checker parsed every JSON and JSONL "
            "artifact to reach this line" % (k, _VAL[k]))

# ---------------------------------------------------------------------------
# 7. ISOLATION TRUTH (R5 finding 12)
# ---------------------------------------------------------------------------
iso = SEAL.get("isolation", {})
inc = iso.get("forbidden_input_incidents")
if inc is None:
    bad("isolation-truth", "PHASE-2-SEAL.json",
        "isolation record does not enumerate forbidden-input incidents")
else:
    enum_n = iso.get("forbidden_input_enumeration_count")
    if enum_n != len(inc):
        bad("isolation-truth", "PHASE-2-SEAL.json",
            "forbidden_input_enumeration_count=%r but %d incidents are recorded"
            % (enum_n, len(inc)))
    if inc and STATUS == "PHASE_2_COMPLETE":
        bad("isolation-truth", "PHASE-2-SEAL.json",
            "status COMPLETE is inadmissible while forbidden-input incidents are recorded; "
            "the acceptance contract requires zero forbidden-input access")
    if "forbidden_input_access_count" in iso and inc:
        bad("isolation-truth", "PHASE-2-SEAL.json",
            "a single forbidden_input_access_count is ambiguous; report content reads and "
            "enumerations separately")

# ---------------------------------------------------------------------------
# 8. SELECTED CANDIDATE
# ---------------------------------------------------------------------------
ND = ALL["PHASE-2-NON-DOMINANCE.md"]
_sel = re.findall(r"^\|\s*(A\d)\s*\|[^\n]*\|\s*selected\s*\|", ND, re.M)
if len(_sel) != 1:
    bad("selected-candidate", "PHASE-2-NON-DOMINANCE.md",
        "expected exactly one row marked selected, found %r" % (_sel,))
else:
    if _sel[0] != "A6":
        bad("selected-candidate", "PHASE-2-NON-DOMINANCE.md",
            "marks %s selected; CDAI is A6" % _sel[0])
    if "CDAI" not in SEAL.get("selected_architecture", ""):
        bad("selected-candidate", "PHASE-2-SEAL.json",
            "seal selected_architecture %r does not name CDAI" % SEAL.get("selected_architecture"))
_listed = set(re.findall(r"^\|\s*(A\d)\s*\|", ND, re.M))
for cid in CAND_IDS:
    if cid not in _listed:
        bad("selected-candidate", "PHASE-2-NON-DOMINANCE.md",
            "candidate %s is enumerated but absent from the evaluated-set table" % cid)

# ---------------------------------------------------------------------------
# 9. DANGLING REFERENCES - structured set equality.
# ---------------------------------------------------------------------------
DEFINED = {
    "I": set(re.findall(r"^### (I-\d+)", REQ, re.M)),
    "PO": set(re.findall(r"PO-\d+", REQ)),
    "UP": UP_CANON,
    "DF": set(DFS) | {"DF-000"},
    "RL": set(r["id"] for r in jl("PHASE-2-RESEARCH-LEDGER.jsonl")),
    "AC": set(re.findall(r"^## (AC-\d+)", ALL["PHASE-2-ASSURANCE-CASE.md"], re.M)),
    "WC": set(re.findall(r"\*\*(WC-\d+)\*\*", ALL["PHASE-2-REPORT.md"])),
    "D": set(r["id"] for r in jl("PHASE-2-DECISION-MATRIX.jsonl")),
}
REF = [("I", r"(?<![-\w])I-\d{2}(?![-\d])"), ("PO", r"(?<![-\w])PO-\d{3}(?![-\d])"),
       ("UP", r"(?<![-\w])UP-\d{1,2}(?![-\d])"), ("DF", r"(?<![-\w])DF-\d{3}(?![-\d])"),
       ("RL", r"(?<![-\w])RL-\d{3}(?![-\d])"), ("AC", r"(?<![-\w])AC-\d{2}(?![-\d])"),
       ("WC", r"(?<![-\w])WC-\d{1,2}(?![-\d])"), ("D", r"(?<![-\w])D\d{2}(?![-\d])")]
for fn, text in ALL.items():
    for label, pat in REF:
        for ref in set(re.findall(pat, text)):
            if ref not in DEFINED[label]:
                bad("dangling-ref", fn, "%s reference %s is not defined" % (label, ref))

# ---------------------------------------------------------------------------
# 10. STRUCTURAL RECORDS (R5 finding 4) - relations and ordering, not substrings.
# ---------------------------------------------------------------------------
try:
    SR = load("PHASE-2-STRUCTURAL-RECORDS.json")
except Exception as e:                                       # noqa: BLE001
    bad("structural", "PHASE-2-STRUCTURAL-RECORDS.json", "unreadable: %s" % e)
    SR = None

if SR:
    sa = SR["staged_admission"]
    steps = {s["n"]: s for s in sa["steps"]}
    oc = sa["ordering_constraint"]
    app = next((s["n"] for s in sa["steps"] if s["action"] == "append-entry"), None)
    prm = next((s["n"] for s in sa["steps"] if s["action"] == "promote"), None)
    if app is None or prm is None:
        bad("structural", "PHASE-2-STRUCTURAL-RECORDS.json", "append-entry or promote step missing")
    else:
        if not app < prm:
            bad("structural", "PHASE-2-STRUCTURAL-RECORDS.json",
                "append-entry (step %d) must precede promote (step %d)" % (app, prm))
        if oc.get("append_step") != app or oc.get("promote_step") != prm:
            bad("structural", "PHASE-2-STRUCTURAL-RECORDS.json",
                "ordering_constraint does not match the step sequence")
        if not steps[prm].get("atomic"):
            bad("structural", "PHASE-2-STRUCTURAL-RECORDS.json", "promotion is not atomic")
        if not steps[prm].get("idempotent") or not steps[prm].get("resumable"):
            bad("structural", "PHASE-2-STRUCTURAL-RECORDS.json",
                "promotion must be idempotent and resumable")
    stg = next((s for s in sa["stores"] if s["id"] == "S"), None)
    if stg is None or stg.get("visible_to_kernel") is not False or stg.get("authority") is not False:
        bad("structural", "PHASE-2-STRUCTURAL-RECORDS.json",
            "staging store must exist, be non-authoritative and invisible to the kernel")
    if sa.get("silent_discard_possible") is not False:
        bad("structural", "PHASE-2-STRUCTURAL-RECORDS.json", "silent discard must be impossible")
    if not any(w.get("invariant_touched") == "I-44" for w in sa["crash_windows"]):
        bad("structural", "PHASE-2-STRUCTURAL-RECORDS.json",
            "no crash window is governed by I-44; the ordering choice is unjustified")

    mc = SR["method_combination"]
    if mc.get("binding_placement") != "outside-unwind-protect":
        bad("structural", "PHASE-2-STRUCTURAL-RECORDS.json",
            "act-context bindings must be established outside the unwind-protect")
    if mc.get("special_declaration_required") is not True or mc.get("special_declaration_form") != "defvar":
        bad("structural", "PHASE-2-STRUCTURAL-RECORDS.json",
            "act-context variables must be proclaimed special with defvar")
    if mc.get("warrant_evaluation_placement") != "inside-protected-form":
        bad("structural", "PHASE-2-STRUCTURAL-RECORDS.json",
            "warrant evaluation must occur inside the protected form")
    order = mc.get("structural_order", [])
    for a, b in (("defvar", "let"), ("let", "unwind-protect"),
                 ("unwind-protect", "cleanup-forms")):
        if a not in order or b not in order or order.index(a) >= order.index(b):
            bad("structural", "PHASE-2-STRUCTURAL-RECORDS.json",
                "structural_order violates %s before %s" % (a, b))
    cg = mc.get("cleanup_guarantee", {})
    if not cg.get("residual") or not cg.get("residual_defeater"):
        bad("structural", "PHASE-2-STRUCTURAL-RECORDS.json",
            "cleanup guarantee must carry the nested-exit residual and a defeater (R5 finding 10)")
    if mc.get("verification_required", {}).get("macroexpansion_inspection") is not True:
        bad("structural", "PHASE-2-STRUCTURAL-RECORDS.json",
            "macroexpansion inspection must be required")

    # The prose must RENDER the record.
    LISP = ALL["PHASE-2-LISP-NATIVE-DESIGN.md"]
    for v in mc["special_variables"]:
        if "(defvar %s" % v not in LISP:
            bad("structural", "PHASE-2-LISP-NATIVE-DESIGN.md",
                "prose does not render the record: %s is not proclaimed special" % v)
    if not re.search(r"\(let \(\(\*act-warrant-results\*[^\n]*\n[^\n]*\*act-outcome\*[^\n]*\n\s*\(unwind-protect",
                     LISP):
        bad("structural", "PHASE-2-LISP-NATIVE-DESIGN.md",
            "prose does not render the record: bindings are not outside the unwind-protect")

# ---------------------------------------------------------------------------
# 11. SEAL INVENTORY HYGIENE
# ---------------------------------------------------------------------------
inv_entries = SEAL.get("artifact_inventory", []) + SEAL.get("supporting_files", [])
for e in inv_entries:
    a = e.get("artifact", "")
    if a.startswith(".") or "/." in a or "\\." in a:
        bad("structural", "PHASE-2-SEAL.json",
            "sealed inventory hashes a dot-directory path %r; volatile non-deliverables "
            "must not be hashed (HF-040)" % a)
    if e.get("sha256") and not os.path.exists(os.path.join(D, a)):
        bad("structural", "PHASE-2-SEAL.json",
            "sealed inventory member %r is not present on disk" % a)

# ---------------------------------------------------------------------------
# REPORT
# ---------------------------------------------------------------------------
print("=" * 78)
print("PHASE-2 CROSS-ARTIFACT SEMANTIC CHECK")
print("self-test: PASS (%d rules, %d probes, identical objects in test and production)"
      % (len(STALE_RULES) + len(COUNT_RULES), len(PROBES)))
print("artifacts scanned: %d   exempt: %d (enumerated in the frozen policy)"
      % (len(ALL), len(EXCLUDE)))
print("=" * 78)
for k, v in sorted(collections.Counter(i["kind"] for i in issues).items()):
    print("  %-22s %d" % (k, v))
print("  %-22s %d" % ("TOTAL", len(issues)))
print()
for i in issues:
    print("[%s] %s" % (i["kind"], i["file"]))
    print("    %s" % i["detail"])
    if i["context"]:
        print("    ...%s..." % i["context"])
print()
print("CLEAN" if not issues else "ISSUES FOUND: %d" % len(issues))
sys.exit(0 if not issues else 1)
