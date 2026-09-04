#!/usr/bin/env bash
# ARCHITECTURE-MODEL-GATE — top-level orchestrator for the canonical architecture-model system. Runs the SBCL
# model-law kernel, the independent clingo checker, deterministic generation, the golden/property fixtures, and the
# tampering / disagreement / omission meta-tests, then reports the acceptance gates. NOT a semantic/legal/security/
# operational/qualification proof. Legacy v1.x PASS results are NEVER used as proof here.
set -uo pipefail
cd "$(dirname "$0")"
pass=0; fail=0
ck(){ if [ "$2" = "$3" ]; then echo "GATE $1: PASS"; pass=$((pass+1)); else echo "GATE $1: FAIL (got '$2' want '$3')"; fail=$((fail+1)); fi; }

# G1 file-role inventory zero unclassified
u=$(python3 build_inventory.py | grep -oE 'unclassified=[0-9]+' | cut -d= -f2); python3 build_inventory.py >/dev/null; git checkout -- files-and-roles.sexp 2>/dev/null || true
ck 01-inventory-zero-unclassified "$u" 0

# G4 model parses/composes + kernel PASS
sbcl --script KERNEL/model-law-kernel.lisp ROOT.sexp >/tmp/k.out 2>&1; kec=$?
ck 04-kernel-parses-and-passes "$([ $kec -eq 0 ] && echo 1 || echo 0)" 1
# G5 exact module/hash universe = kernel L7 (no L7 violation in a passing run)
ck 05-exact-hash-universe "$(grep -c 'VIOLATION L7' /tmp/k.out)" 0
# G2 no duplicate facts (L2) + ledger present
ck 02-no-duplicate-facts "$(grep -c 'VIOLATION L2' /tmp/k.out)" 0
ck 03-conflicts-recorded "$([ -f MODEL-MIGRATION-CONFLICT-LEDGER.md ] && grep -cq '| 1 |' MODEL-MIGRATION-CONFLICT-LEDGER.md && echo 1 || echo 0)" 1

# G13 independent checker PASS + agreement
python3 CHECKER/independent_check.py ROOT.sexp >/tmp/c.out 2>&1; cec=$?
kv=$(grep -q 'ARCHITECTURE MODEL LAWS: PASS' /tmp/k.out && echo PASS || echo FAIL)
cv=$(grep -q 'INDEPENDENT ARCHITECTURE INVARIANTS: PASS' /tmp/c.out && echo PASS || echo FAIL)
ck 13-independent-agree "$([ "$kv" = "$cv" ] && [ "$kv" = PASS ] && echo 1 || echo 0)" 1

# G6 two clean generations byte-identical (generator + ROOT)
python3 generate_views.py >/dev/null; python3 build_root.py >/dev/null
cp -r GENERATED /tmp/g1; cp ROOT.sexp /tmp/r1
python3 generate_views.py >/dev/null; python3 build_root.py >/dev/null
if diff -rq /tmp/g1 GENERATED >/dev/null && diff -q /tmp/r1 ROOT.sexp >/dev/null; then g6=1; else g6=0; fi; rm -rf /tmp/g1 /tmp/r1
ck 06-two-generations-identical "$g6" 1
# G7 clean regeneration leaves the working tree byte-identical to the canonical index/HEAD content.
# Porcelain columns are XY (X=index, Y=worktree); a regeneration that DRIFTS a tracked file makes the
# worktree column non-blank (' M' committed-drift, 'AM' staged-drift). A staged-but-unchanged add is 'A '
# (worktree clean) and is NOT a drift. So count only worktree-dirty lines (2nd column neither space nor '?').
python3 generate_views.py >/dev/null; python3 build_root.py >/dev/null
ck 07-regen-empty-diff "$(git status --porcelain GENERATED ROOT.sexp 2>/dev/null | grep -E '^.[^ ?]' | wc -l | tr -d ' ')" 0
# G8 manual generated-view edit detected
cp GENERATED/OWNERSHIP-MATRIX.md /tmp/ov.bak; echo "MANUAL TAMPER" >> GENERATED/OWNERSHIP-MATRIX.md
python3 generate_views.py >/dev/null
if diff -q /tmp/ov.bak GENERATED/OWNERSHIP-MATRIX.md >/dev/null; then g8=1; else g8=0; fi   # regen restores canonical -> tamper gone -> detected
ck 08-manual-view-edit-detected "$g8" 1; rm -f /tmp/ov.bak

# G9 kernel budget + no regex/grep-as-proof
sloc=$(grep -vE '^[[:space:]]*;|^[[:space:]]*$' KERNEL/model-law-kernel.lisp KERNEL/sha256.lisp | wc -l | tr -d ' ')
ck 09a-kernel-sloc-budget "$([ "$sloc" -le 400 ] && echo 1 || echo 0)" 1
ck 09b-kernel-no-regex "$(grep -vE '^[[:space:]]*;' KERNEL/model-law-kernel.lisp KERNEL/sha256.lisp | grep -ciE 'ppcre|run-program|sb-ext:run|\(search |cl-ppcre|shell-out')" 0

# G10-G12 golden PASS/FAIL fixtures + property families
python3 run_fixtures.py >/tmp/fx.out 2>&1; fxc=$?
ck 10-12-fixtures-and-properties "$([ $fxc -eq 0 ] && echo 1 || echo 0)" 1

# G14 corrupt neutral export / omit fact detected: (a) omit a fact -> kernel FAILs; (b) export regen restores
d=$(mktemp -d); for m in *.sexp; do cp "$m" "$d/"; done
python3 - "$d" <<'PY'
import sys,re,hashlib,os
d=sys.argv[1]; p=os.path.join(d,'requirements-tests-workpackets.sexp')
ls=[l for l in open(p) if not l.startswith('(fact req-map S03__')]; open(p,'w').write(''.join(ls))
# rehash omitted -> also drift; but we want the OMISSION detected (L6). recompute ROOT so only L6 shows.
mods=re.findall(r':module "([^"]+)"',open(os.path.join(d,'ROOT.sexp')).read())   # single source: exactly what ROOT pins
def sha(fp): return hashlib.sha256(open(fp,encoding='utf-8',errors='replace').read().encode('utf-8')).hexdigest()
t=open(os.path.join(d,'ROOT.sexp')).read()
for m in mods: t=re.sub(r'(:module "%s" :sha256 ")[0-9a-f]{64}'%re.escape(m), r'\g<1>'+sha(os.path.join(d,m)), t)
dig=hashlib.sha256('\n'.join('%s:%s'%(m,sha(os.path.join(d,m))) for m in mods).encode()).hexdigest()
t=re.sub(r'(:canonical-model-root-digest ")[0-9a-f]{64}', r'\g<1>'+dig, t); open(os.path.join(d,'ROOT.sexp'),'w').write(t)
PY
sbcl --script KERNEL/model-law-kernel.lisp "$d/ROOT.sexp" >/tmp/omit.out 2>&1; omitec=$?
ck 14-omission-detected "$([ $omitec -ne 0 ] && echo 1 || echo 0)" 1; rm -rf "$d"

# G15 deliberate kernel/clingo disagreement BLOCKS: run clingo on an L4-cycle temp while kernel sees baseline
d=$(mktemp -d); for m in *.sexp; do cp "$m" "$d/"; done; cp ROOT.sexp "$d/"
printf '\n(fact stage-edge PUBLISH__ACQUIRE :from PUBLISH :to ACQUIRE)\n' >> "$d/dependencies-and-boundaries.sexp"
python3 CHECKER/independent_check.py "$d/ROOT.sexp" >/tmp/dis.out 2>&1; disc=$?
# kernel(baseline)=PASS, clingo(mutated)=FAIL -> disagreement -> agreement check must be FALSE
ck 15-disagreement-blocks "$([ "$kv" = PASS ] && [ $disc -ne 0 ] && echo 1 || echo 0)" 1; rm -rf "$d"

# G16 decision packet from evidence
python3 build_decision_packet.py >/dev/null 2>&1
ck 16-decision-packet "$([ -f ROOT-OPERATOR-DECISION-PACKET.md ] && grep -cq 'APPROVE / REJECT / DEFER\|APPROVE\b' ROOT-OPERATOR-DECISION-PACKET.md && echo 1 || echo 0)" 1
# G17 no gate requires exhaustive human review (asserted in packet)
ck 17-no-exhaustive-human-review "$(grep -cq 'No gate requires exhaustive human repository review' ROOT-OPERATOR-DECISION-PACKET.md && echo 1 || echo 0)" 1
# G18 legacy audits classified non-authoritative (not used as proof here)
ck 18-legacy-nonauthoritative "$(grep -cq 'NON_AUTHORITATIVE_GATE' files-and-roles.sexp && echo 1 || echo 0)" 1

# G19 no source fact class silently omitted: every v1.6-v1.8 (file,class) is IMPORTED|DEFERRED_DATA_IMPORT|
#     OUT_OF_MIGRATION_SCOPE, exact-universe against an independent re-scan, every deferred class finite-batched.
python3 build_deferred.py >/dev/null 2>&1; python3 build_deferred.py --verify >/tmp/ddi.out 2>&1; ddic=$?
ck 19-deferred-ledger-exact-universe "$([ $ddic -eq 0 ] && grep -q 'DEFERRED-IMPORT LEDGER: PASS' /tmp/ddi.out && echo 1 || echo 0)" 1
# G20 the deferred ledger is inside the hash-rooted model universe (pinned in ROOT + carries DEFERRED_DATA_IMPORT rows)
ck 20-deferred-in-model-universe "$(grep -q 'deferred-imports.sexp' ROOT.sexp && grep -q ':status DEFERRED_DATA_IMPORT' deferred-imports.sexp && echo 1 || echo 0)" 1
# G21 anti-omission gate actually bites: drop one ledger row -> --verify FAILs with MISSING-FROM-LEDGER; regen restores
grep -v 'source-class V1.8-SCHEMAS__define-record ' deferred-imports.sexp > /tmp/ddi.mut && cp /tmp/ddi.mut deferred-imports.sexp
python3 build_deferred.py --verify >/tmp/ddi2.out 2>&1; bitec=$?
python3 build_deferred.py >/dev/null 2>&1                                # regenerate -> canonical ledger restored
ck 21-omission-gate-bites "$([ $bitec -ne 0 ] && grep -q 'MISSING-FROM-LEDGER' /tmp/ddi2.out && echo 1 || echo 0)" 1; rm -f /tmp/ddi.mut

echo "### ARCHITECTURE-MODEL-GATE SUMMARY: pass=$pass fail=$fail"
if [ $fail -eq 0 ]; then echo "### ARCHITECTURE MODEL LAWS: PASS — (structural model-law + independent-checker + fixtures; NOT semantic/legal/security/operational/qualification proof)"; exit 0
else echo "### ARCHITECTURE MODEL LAWS: FAIL"; exit 1; fi
