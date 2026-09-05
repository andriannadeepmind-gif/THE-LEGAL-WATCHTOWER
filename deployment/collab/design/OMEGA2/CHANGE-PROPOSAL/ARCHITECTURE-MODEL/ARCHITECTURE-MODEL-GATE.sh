#!/usr/bin/env bash
# ARCHITECTURE-MODEL-GATE — the acceptance gate of the canonical architecture-model system.
#
# WHAT THIS IS. A judgement, not a build. It resolves ONE immutable candidate tree, exports it into a private
# workspace, and asks every question of that tree. It regenerates nothing in place, restores nothing before
# comparing it, and writes no file outside its own workspace — so "the gate passed" can never mean "the gate
# rewrote the thing it was about to inspect". Applying belongs to a different command: `regenerate.py`.
#
# Review-2 N-2, N-14, N-16, N-18 are the reasons for each of those properties:
#   * the previous gate ran the five in-place producers BEFORE comparing anything, so a hand-edited generated
#     artifact was overwritten and the run then reported `pass=20 fail=0` having named nothing;
#   * its drift measure was a porcelain-column regex that could not see the index at all;
#   * it deliberately tampered with a tracked view in the working tree and restored it afterwards, so an
#     interrupted run left the repository damaged;
#   * it wrote to fixed `/tmp/*.out` paths, which are attacker- and collision-reachable on a shared host.
#
# WHAT IS COUNTED. A check that cannot fail is not a check. Everything counted here can fail on a defect it
# names. Anything whose evidence is only the presence of text is reported as INFORMATIONAL_PRESENCE_CHECK and
# is EXCLUDED from the count. The count is not a target; what each check can catch is.
#
# WHAT THIS IS NOT. Not a semantic, legal, security, behavioural, operational or qualification proof. No freeze
# and no qualification follows from a PASS here.
#
# Usage:  ARCHITECTURE-MODEL-GATE.sh [<tree-ish>]
#         with no argument, or with WORKTREE, the candidate is the tree the current state would commit to.
set -uo pipefail
cd "$(dirname "$0")"

umask 077
WORK="$(mktemp -d "${TMPDIR:-/tmp}/aml-gate-XXXXXXXXXX")" || { echo "GATE: FAIL (no private workspace)"; exit 1; }
chmod 700 "$WORK"
cleanup(){ rm -rf "$WORK"; }
trap cleanup EXIT INT TERM HUP

pass=0; fail=0; info=0; failed_names=""
ck(){ # ck <name> <exit-code>
  if [ "$2" = "0" ]; then echo "GATE $1: PASS"; pass=$((pass+1));
  else echo "GATE $1: FAIL"; fail=$((fail+1)); failed_names="$failed_names $1"; fi
}
note(){ echo "GATE $1: INFORMATIONAL_PRESENCE_CHECK ($2) — reported, not counted"; info=$((info+1)); }

CAND="${1:-${AML_CANDIDATE_TREE:-WORKTREE}}"

# The exact state of the working tree BEFORE anything else runs — captured first, so that a write performed by
# any later line of this gate, including the very first one, is visible to the read-only check at the end.
WT_BEFORE=$(git -C ../../../../../.. status --porcelain -uall | sha256sum)

echo "== candidate =="
if ! python3 gate_checks.py candidate --tree "$CAND" --work "$WORK" >"$WORK/candidate.out" 2>&1; then
  cat "$WORK/candidate.out"; echo "### ARCHITECTURE MODEL LAWS: FAIL (no candidate tree)"; exit 1
fi
TREE=$(sed -n 's/^CANDIDATE-TREE //p' "$WORK/candidate.out")
SEAT=$(sed -n 's/^CANDIDATE-SEAT //p' "$WORK/candidate.out")
SEATREL=$(sed -n 's/^CANDIDATE-REL //p' "$WORK/candidate.out")
[ -n "$TREE" ] && [ -d "$SEAT" ] || { cat "$WORK/candidate.out"; echo "### ARCHITECTURE MODEL LAWS: FAIL"; exit 1; }
grep -v '^CANDIDATE-' "$WORK/candidate.out"
export AML_CANDIDATE_TREE="$TREE"

# every check reads the SAME exported candidate and the SAME workspace: one export, one commitment, one answer
gc(){ python3 gate_checks.py "$1" --tree "$TREE" --work "$WORK" >"$WORK/$1.out" 2>&1; rc=$?; cat "$WORK/$1.out"; return $rc; }

echo "== toolchain identity (before any verdict is issued) =="
gc toolchain; ck tch-01-pinned-tools-are-the-tools-executed "$?"

echo "== generation: the declared order, run in the workspace and byte-compared =="
gc generation-order; ck gen-01-declared-order-is-total-and-acyclic "$?"
gc generation;       ck gen-02-artifacts-regenerate-byte-identical "$?"

echo "== the tracked universe =="
gc inventory; ck inv-01-inventory-equals-candidate-universe "$?"
gc artifacts; ck art-01-generated-artifact-universe-is-exact "$?"
gc seats;     ck sea-01-every-seat-resolves-or-declares-why "$?"

echo "== the two verification paths =="
gc commitments; ck ver-01-both-paths-agree-on-one-fact-universe "$?"
KSLOC=$(grep -vE '^[[:space:]]*;|^[[:space:]]*$' "$SEAT/KERNEL/model-law-kernel.lisp" "$SEAT/KERNEL/hash-provider.lisp" | wc -l | tr -d ' ')
[ "$KSLOC" -le 400 ]; ck ver-02-kernel-source-budget-400-lines "$?"
echo "  kernel + hash provider: $KSLOC non-blank non-comment lines (budget 400)"

echo "== hashing =="
gc hash-engines; ck hsh-01-two-vetted-engines-agree-on-raw-bytes "$?"

echo "== the verification corpus itself =="
gc corpus; ck cor-01-corpus-universe-is-exact "$?"
python3 "$SEAT/run_fixtures.py" >"$WORK/fixtures.out" 2>&1; fxc=$?
tail -1 "$WORK/fixtures.out" | sed 's/^/  /'
ck fix-01-golden-and-generated-fixtures "$fxc"
# COMPONENT falsifiers only. The COMPOSED_GATE falsifiers execute THIS script and are therefore run by the
# separate battery, run_gate_falsifiers.py — a gate that ran them would recurse forever (Review-2 N-2).
#
# The battery needs a real git repository, so it is the working copy that executes rather than the export. That
# is only honest if the two are the same bytes, so the candidate's own blob is compared to it first: a battery
# that is not the candidate's battery proves nothing about the candidate.
# When the candidate IS the working tree the two are the same bytes by construction, and a check that cannot
# fail is not a check — so it is reported, not counted, in that mode, and counted only when it can fail.
if [ "$CAND" = "WORKTREE" ]; then
  note fls-00-battery-executed-is-the-candidates-battery "the candidate is the working tree, so the battery executed is the candidate's by construction"
else
  git -C ../../../../../.. cat-file blob "$TREE:$SEATREL/run_falsifiers.py" 2>/dev/null | cmp -s - run_falsifiers.py
  ck fls-00-battery-executed-is-the-candidates-battery "$?"
fi
python3 run_falsifiers.py >"$WORK/falsifiers.out" 2>&1; flc=$?
grep -E '^held-out falsifiers' "$WORK/falsifiers.out" | sed 's/^/  /'
grep -E '^  NOT REJECTED' "$WORK/falsifiers.out" | sed 's/^/  /'
ck fls-01-component-falsifiers-all-rejected "$flc"

echo "== migration-scope ledger =="
(cd "$SEAT" && python3 build_deferred.py --verify) >"$WORK/ledger.out" 2>&1; ddic=$?
grep -E 'DEFERRED-IMPORT LEDGER' "$WORK/ledger.out" | sed 's/^/  /'
[ $ddic -eq 0 ] && grep -q 'DEFERRED-IMPORT LEDGER: PASS' "$WORK/ledger.out"
ck led-01-deferred-ledger-exact-source-universe "$?"

echo "== derived documents =="
gc conflict-ledger;    ck doc-01-conflict-ledger-reconciled-both-ways "$?"
gc packet;             ck doc-02-decision-packet-reconciled-to-the-model "$?"
gc dependency-closure; ck doc-03-governance-closure-declared-and-historic-free "$?"

echo "== the gate's own effect on the repository =="
WT_AFTER=$(git -C ../../../../../.. status --porcelain -uall | sha256sum)
TREE_AFTER=$(python3 gate_checks.py candidate --tree WORKTREE --work "$WORK/verify" 2>/dev/null | sed -n 's/^CANDIDATE-TREE //p')
[ "$WT_BEFORE" = "$WT_AFTER" ]; a=$?
ck ro-01-working-tree-byte-identical-after-the-run "$a"
if [ "$CAND" = "WORKTREE" ]; then
  [ "$TREE_AFTER" = "$TREE" ]; b=$?
  ck ro-02-candidate-tree-unchanged-by-the-run "$b"
else
  note ro-02-candidate-tree-unchanged-by-the-run "an explicit tree-ish was judged; the working-tree candidate is not the subject"
fi

echo "== reported, not counted =="
rx=$(grep -vE '^[[:space:]]*;' "$SEAT/KERNEL/model-law-kernel.lisp" "$SEAT/KERNEL/hash-provider.lisp" | grep -ciE 'ppcre|shell-out')
note krn-lexical-scan "a lexical scan of the kernel sources for regex/shell constructs found $rx; a lexical scan cannot prove absence"
note packet-single-operator-assurance "the decision packet states that no gate requires exhaustive human repository review; the statement is prose, its totals are what the counted checks reconcile"
note composed-gate-battery "the $(grep -c ':harness COMPOSED_GATE' "$SEAT/verification-corpus.sexp") COMPOSED_GATE falsifiers execute this script and are run by run_gate_falsifiers.py, never from inside it"

echo "### ARCHITECTURE-MODEL-GATE SUMMARY: candidate=$TREE pass=$pass fail=$fail informational=$info"
if [ $fail -eq 0 ]; then
  echo "### ARCHITECTURE MODEL LAWS: PASS — structural model-law + independent-path + fixture + held-out-falsifier"
  echo "### evidence over the immutable candidate tree $TREE."
  echo "### NOT semantic, legal, security, behavioural, operational or qualification proof. No freeze and no"
  echo "### qualification follows."
  exit 0
else
  echo "### FAILED CHECKS:$failed_names"
  echo "### ARCHITECTURE MODEL LAWS: FAIL"
  exit 1
fi
