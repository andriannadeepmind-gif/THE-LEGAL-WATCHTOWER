#!/usr/bin/env bash
# ARCHITECTURE-MODEL-GATE — the acceptance gate of the canonical architecture-model system.
#
# It executes the generation order the MODEL declares (generation-order.sexp, topologically sorted — the gate
# carries no private order of its own), then runs the SBCL model-law kernel, the independent clingo checker, the
# golden/property fixtures and the held-out falsifiers, and reports each check.
#
# Two rules govern what may be counted here:
#   * a check that cannot fail is not a check. Nothing in the counted set is satisfied by grepping the
#     repository's own prose for a phrase the repository wrote;
#   * a check whose evidence is only the presence of text is reported as INFORMATIONAL_PRESENCE_CHECK and is
#     EXCLUDED from the architecture-law count. The count is not a target; what each check can catch is.
#
# Nothing here restores a file before comparing it. `git checkout` does not appear in this gate.
# This is NOT a semantic, legal, security, operational or qualification proof.
set -uo pipefail
cd "$(dirname "$0")"
pass=0; fail=0; info=0
ck(){ if [ "$2" = "$3" ]; then echo "GATE $1: PASS"; pass=$((pass+1)); else echo "GATE $1: FAIL (got '$2' want '$3')"; fail=$((fail+1)); fi; }
note(){ echo "GATE $1: INFORMATIONAL_PRESENCE_CHECK ($2) — reported, not counted"; info=$((info+1)); }
SEAT="."

echo "== generation: the order declared by the model =="
ORDER=$(python3 gate_checks.py generation-order) || { echo "GATE gen-order: FAIL (the declared order is unusable)"; exit 1; }
echo "$ORDER" | sed 's/^/  step: /'
genrun(){ for p in $ORDER; do python3 "$p" >/dev/null || return 1; done; return 0; }
genrun; gen1=$?
ck gen-01-declared-order-runs "$gen1" 0

echo "== inventory =="
python3 gate_checks.py inventory; ck inv-01-inventory-equals-tracked-universe "$?" 0
# regeneration must leave the tracked tree byte-identical to what is committed. Porcelain columns are XY
# (X=index, Y=worktree); a regeneration that DRIFTS a tracked file makes the worktree column non-blank.
drift=$(git status --porcelain "$SEAT" 2>/dev/null | grep -E '^.[^ ?]' | wc -l | tr -d ' ')
ck inv-02-regeneration-leaves-no-drift "$drift" 0
snap=$(mktemp -d); cp -a GENERATED "$snap/"; cp ROOT.sexp files-and-roles.sexp deferred-imports.sexp ROOT-OPERATOR-DECISION-PACKET.md "$snap/"
genrun; gen2=$?
same=1; diff -rq "$snap/GENERATED" GENERATED >/dev/null 2>&1 || same=0
for f in ROOT.sexp files-and-roles.sexp deferred-imports.sexp ROOT-OPERATOR-DECISION-PACKET.md; do diff -q "$snap/$f" "$f" >/dev/null 2>&1 || same=0; done
rm -rf "$snap"
ck inv-03-two-generations-identical "$([ $gen2 -eq 0 ] && echo $same || echo 0)" 1
cp GENERATED/OWNERSHIP-MATRIX.md /tmp/ov.bak; echo "MANUAL TAMPER" >> GENERATED/OWNERSHIP-MATRIX.md
python3 generate_views.py >/dev/null
if diff -q /tmp/ov.bak GENERATED/OWNERSHIP-MATRIX.md >/dev/null; then g=1; else g=0; fi
rm -f /tmp/ov.bak
ck inv-04-manual-view-edit-detected "$g" 1

echo "== model-law kernel (SBCL) =="
sbcl --script KERNEL/model-law-kernel.lisp ROOT.sexp >/tmp/k.out 2>&1; kec=$?
ck krn-01-kernel-passes "$([ $kec -eq 0 ] && echo 1 || echo 0)" 1
ck krn-02-no-hash-universe-violation "$(grep -c 'VIOLATION L7' /tmp/k.out)" 0
ck krn-03-no-duplicate-seat-violation "$(grep -c 'VIOLATION L2' /tmp/k.out)" 0
sloc=$(grep -vE '^[[:space:]]*;|^[[:space:]]*$' KERNEL/model-law-kernel.lisp KERNEL/hash-provider.lisp | wc -l | tr -d ' ')
ck krn-04-kernel-source-budget "$([ "$sloc" -le 400 ] && echo 1 || echo 0)" 1

echo "== independent path (clingo) =="
python3 CHECKER/independent_check.py ROOT.sexp >/tmp/c.out 2>&1; cec=$?
ck chk-01-independent-path-passes "$([ $cec -eq 0 ] && echo 1 || echo 0)" 1
diff -q KERNEL-COMMITMENT.txt CHECKER-COMMITMENT.txt >/dev/null 2>&1; ck chk-02-fact-set-commitments-identical "$?" 0
python3 gate_checks.py module-universe; ck chk-03-both-paths-consume-root-universe "$?" 0

echo "== hashing =="
python3 gate_checks.py hash-engines; ck hsh-01-two-vetted-engines-agree "$?" 0

echo "== fixtures and held-out falsifiers =="
python3 run_fixtures.py >/tmp/fx.out 2>&1; fxc=$?
tail -1 /tmp/fx.out | sed 's/^/  /'
ck fix-01-golden-and-property-fixtures "$([ $fxc -eq 0 ] && echo 1 || echo 0)" 1
python3 run_falsifiers.py >/tmp/fl.out 2>&1; flc=$?
grep -E '^held-out falsifiers' /tmp/fl.out | sed 's/^/  /'
grep -E '^  NOT REJECTED' /tmp/fl.out | sed 's/^/  /'
ck fls-01-held-out-falsifiers-rejected "$([ $flc -eq 0 ] && echo 1 || echo 0)" 1

echo "== migration-scope ledger =="
python3 build_deferred.py --verify >/tmp/ddi.out 2>&1; ddic=$?
ck led-01-deferred-ledger-exact-universe "$([ $ddic -eq 0 ] && grep -q 'DEFERRED-IMPORT LEDGER: PASS' /tmp/ddi.out && echo 1 || echo 0)" 1
ck led-02-ledger-inside-model-universe "$(grep -q 'deferred-imports.sexp' ROOT.sexp && grep -q ':status DEFERRED_DATA_IMPORT' deferred-imports.sexp && echo 1 || echo 0)" 1

echo "== derived documents =="
python3 gate_checks.py conflict-ledger; ck doc-01-conflict-ledger-reconciled "$?" 0
python3 gate_checks.py packet; ck doc-02-decision-packet-reconciled "$?" 0
python3 gate_checks.py live-path; ck doc-03-no-historical-code-on-live-path "$?" 0

echo "== reported, not counted =="
rx=$(grep -vE '^[[:space:]]*;' KERNEL/model-law-kernel.lisp KERNEL/hash-provider.lisp | grep -ciE 'ppcre|run-program|sb-ext:run|shell-out')
note krn-lexical-scan "a lexical scan of the kernel sources for regex/shell constructs found $rx; a lexical scan cannot prove absence"
note packet-single-operator-assurance "the decision packet states that no gate requires exhaustive human repository review; the statement is prose, its totals are what the counted checks reconcile"

echo "### ARCHITECTURE-MODEL-GATE SUMMARY: pass=$pass fail=$fail informational=$info"
if [ $fail -eq 0 ]; then
  echo "### ARCHITECTURE MODEL LAWS: PASS — structural model-law + independent-path + fixture + held-out-falsifier evidence."
  echo "### NOT semantic, legal, security, behavioral, operational or qualification proof. No freeze and no qualification follows."
  exit 0
else
  echo "### ARCHITECTURE MODEL LAWS: FAIL"
  exit 1
fi
