#!/usr/bin/env bash
# ARCHITECTURE-MODEL-GATE — the ONE acceptance command of the canonical architecture-model system.
#
# Review-3 R3-15 and §15 M-consolidation. Acceptance was two shell entry points: this gate, and an ACCEPT.sh
# that resolved the same candidate, made the same workspace, refused the same hostile TMPDIR and then called
# this script. Two entry points for one function is the wrapper this repository forbids, and an operator who ran
# the inner one saw a verdict that did not include the composed battery. There is now one command with two
# phases: run without arguments it IS acceptance — it binds the machinery to the candidate, exports it, re-runs
# ITSELF from that export with --checks, then runs the composed-gate battery and validates the evidence. Run
# with --checks it performs the model checks only, which is what the composed falsifiers execute (a phase that
# ran the composed battery would recurse forever).
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
# Usage:  ARCHITECTURE-MODEL-GATE.sh [--checks] [--base=<full commit SHA>] [<commit-ish>|WORKTREE]
#         The candidate is a COMMIT (its base is its unique parent) or WORKTREE, the default: the tree the current
#         state would commit to, whose base is HEAD — or, when that tree equals HEAD's, HEAD itself with HEAD's
#         unique parent as base. A bare tree is not a candidate. --base only CONFIRMS the base the candidate
#         determines; one that differs is a typed failure, never a choice (Review-4 R4-1, Review-5 R5-2).
set -uo pipefail
cd "$(dirname "$0")"

umask 077
# Review-4 R4-4: one git lock policy for this whole process tree, exported here and forced again on every git
# subprocess the seat programs start — a hostile inherited GIT_OPTIONAL_LOCKS=1 changes nothing.
export GIT_OPTIONAL_LOCKS=0
# Review-4 R4-3: job control (enabled only around the launch of each child) puts every child phase in its own
# process group, so a signal to this command is forwarded to exactly the children IT started — never to a
# concurrent independent run sharing the host.
# The full phase re-runs this script from an export of the candidate; AML_REPO then names the real repository.
# Review-3 R3-3. No interpreter is resolved by NAME here. The pinned absolute path is lifted out of the model
# with awk — a bootstrap tool, not a verified one — before anything else runs, and every later invocation uses
# it. A `python3` planted earlier on PATH is therefore never executed by this command at all, rather than being
# executed invisibly and then reporting the real interpreter's identity back as its own.
pinned(){ awk -v role="$1" 'BEGIN{RS="\n\n"} $0 ~ (":role " role) {match($0, /:path "[^"]+"/); print substr($0, RSTART+7, RLENGTH-8)}' TOOLCHAIN.sexp; }
PY=$(pinned CHECKER_RUNTIME)
[ -n "$PY" ] && [ -x "$PY" ] || { echo "### ACCEPTANCE: FAIL — TOOLCHAIN-UNRESOLVED: TOOLCHAIN.sexp pins no executable CHECKER_RUNTIME path ($PY)"; exit 1; }
# The bootstrap root, stated rather than implied (Review-3 R3-3d): bash, coreutils (mktemp/chmod/sed/grep/cmp/
# sha256sum/awk), git, tar and the dynamic loader are trusted BEFORE any identity can be checked, because the
# checking itself needs them. They are an EXTERNAL TCB ASSUMPTION of this command, not something it proves.
REPO="${AML_REPO:-$(cd ../../../../../.. && pwd)}"
REL=$("$PY" -c 'import os,sys;print(os.path.relpath(os.getcwd(), sys.argv[1]))' "$REPO")
PHASE=full; CAND=""; BASE=""
for arg in "$@"; do
  case "$arg" in --checks) PHASE=checks ;; --base=*) BASE="${arg#--base=}" ;; *) CAND="$arg" ;; esac
done
CAND="${CAND:-${AML_CANDIDATE:-WORKTREE}}"
BASEARG=(); [ -n "$BASE" ] && BASEARG=(--base "$BASE")
TMPROOT=$("$PY" -c 'import tempfile,os;print(os.path.realpath(tempfile.gettempdir()))')
case "$TMPROOT" in
  "$REPO"|"$REPO"/*) echo "### ACCEPTANCE: FAIL — HOSTILE-TMPDIR: the scratch root $TMPROOT is inside the repository under audit"; exit 1 ;;
esac
WORK="$(mktemp -d "${TMPDIR:-/tmp}/aml-gate-XXXXXXXXXX")" || { echo "GATE: FAIL (no private workspace)"; exit 1; }
chmod 700 "$WORK"
KID=""
cleanup(){ rm -rf "$WORK"; }
# On INT/TERM/HUP: terminate the child process group THIS command is waiting on (its own trap removes its own
# workspace and its runtime seat terminates its own children), then remove this workspace, then exit. Nothing
# else on the host is touched: no glob over the scratch root, no other run's directories.
on_signal(){ trap - INT TERM HUP; [ -n "$KID" ] && kill -TERM -- "-$KID" 2>/dev/null; [ -n "$KID" ] && wait "$KID" 2>/dev/null; cleanup; exit 130; }
trap cleanup EXIT
trap on_signal INT TERM HUP
# every child phase runs as a JOB in its own process group and is waited for, so its exit status is preserved
# and a signal can be forwarded to exactly that group
job(){ set -m; "$@" & KID=$!; set +m; wait "$KID"; rc=$?; KID=""; return $rc; }

pass=0; fail=0; info=0; failed_names=""
ck(){ # ck <name> <exit-code>
  if [ "$2" = "0" ]; then echo "GATE $1: PASS"; pass=$((pass+1));
  else echo "GATE $1: FAIL"; fail=$((fail+1)); failed_names="$failed_names $1"; fi
}
note(){ echo "GATE $1: INFORMATIONAL_PRESENCE_CHECK ($2) — reported, not counted"; info=$((info+1)); }
sub(){ # sub <name> <exit-code> <logfile> <expected-marker>  — one acceptance subset
  # Review-3, found by the wrapper battery: matching a marker was not enough. A composed battery that ran ZERO
  # cases printed "not-rejected=0", matched, and was reported PASS while announcing BATTERY-VACUOUS. A subset
  # passes only when it EXITED zero, produced evidence, and its verdict line appears exactly once.
  if [ "$2" != "0" ]; then echo "ACCEPT $1: FAIL (exit $2)"; fail=$((fail+1)); failed_names="$failed_names $1"; return; fi
  if [ ! -s "$3" ]; then echo "ACCEPT $1: FAIL (produced no evidence)"; fail=$((fail+1)); failed_names="$failed_names $1"; return; fi
  n=$(grep -c -- "$4" "$3" || true)
  if [ "$n" != "1" ]; then echo "ACCEPT $1: FAIL (its verdict line appears $n times, expected exactly 1)"; fail=$((fail+1)); failed_names="$failed_names $1"; return; fi
  echo "ACCEPT $1: PASS"; pass=$((pass+1))
}

# The exact state of the working tree BEFORE anything else runs — captured first, so that a write performed by
# any later line of this gate, including the very first one, is visible to the read-only check at the end.
WT_BEFORE=$("$PY" gate_checks.py content-state)

echo "== candidate and base =="
if ! job "$PY" gate_checks.py candidate --candidate "$CAND" "${BASEARG[@]}" --work "$WORK" >"$WORK/candidate.out" 2>&1; then
  cat "$WORK/candidate.out"; echo "### ARCHITECTURE MODEL LAWS: FAIL (no candidate commit or no base)"; exit 1
fi
TREE=$(sed -n 's/^CANDIDATE-TREE //p' "$WORK/candidate.out")
CANDID=$(sed -n 's/^CANDIDATE-COMMIT //p' "$WORK/candidate.out")
SEAT=$(sed -n 's/^CANDIDATE-SEAT //p' "$WORK/candidate.out")
SEATREL=$(sed -n 's/^CANDIDATE-REL //p' "$WORK/candidate.out")
BASE=$(sed -n 's/^BASE-COMMIT //p' "$WORK/candidate.out")
[ -n "$TREE" ] && [ -n "$CANDID" ] && [ -d "$SEAT" ] && [ -n "$BASE" ] || { cat "$WORK/candidate.out"; echo "### ARCHITECTURE MODEL LAWS: FAIL"; exit 1; }
grep -E '^(CANDIDATE|BASE)-(COMMIT|TREE|MODEL-ROOT|RELATION) ' "$WORK/candidate.out" | sed 's/^/  /'
grep -v -E '^(CANDIDATE|BASE)-' "$WORK/candidate.out"
# every later invocation names the SAME candidate identity (a commit, or WORKTREE) and re-derives the base from
# it; the resolved tree travels along only to be verified against that derivation, never to replace it
export AML_CANDIDATE="$CANDID" AML_CANDIDATE_TREE="$TREE"

# ── the FULL phase: bind the machinery to the candidate, then run every acceptance subset from ITS export ────
# Review-3 R3-2 and R3-15. In tree-ish mode the candidate used to be judged by the WORKING TREE's tools, so
# tampering with gate_checks.py turned a broken tree into a PASS. Provenance is therefore established FIRST,
# from the export, and nothing else is executed until it holds. Everything acceptance means then runs here: a
# subset that is missing, that did not run, that ran twice or that failed makes this command fail.
if [ "$PHASE" = "full" ]; then
  echo "== acceptance: the verifier must be the candidate's own machinery =="
  mkdir -p "$WORK/verifier"
  git -C "$REPO" archive "$TREE" "$(dirname "$REL")" | tar -x -C "$WORK/verifier" || { echo "### ACCEPTANCE: FAIL (export)"; exit 1; }
  VSEAT="$WORK/verifier/$REL"
  export AML_REPO="$REPO"
  job bash -c 'cd "$1" && exec "$2" gate_checks.py provenance --candidate "$3" --tree "$4" --base "$5" --work "$6"' _ "$VSEAT" "$PY" "$CANDID" "$TREE" "$BASE" "$WORK" >"$WORK/provenance.out" 2>&1
  prc=$?; cat "$WORK/provenance.out"
  [ $prc -eq 0 ] || { echo "### ACCEPTANCE: FAIL — the verifier is not the candidate's; no PASS may be issued from here"; exit 1; }
  sub provenance "$prc" "$WORK/provenance.out" 'GATECHECK provenance: PASS'
  echo "== acceptance: the model checks, executed from the verifier export =="
  job bash -c 'cd "$1" && exec ./ARCHITECTURE-MODEL-GATE.sh --checks "--base=$2" "$3"' _ "$VSEAT" "$BASE" "$CANDID" >"$WORK/checks.out" 2>&1
  ckc=$?
  sed 's/^/  /' "$WORK/checks.out"
  sub model-checks "$ckc" "$WORK/checks.out" '### ARCHITECTURE MODEL LAWS: PASS'
  echo "== acceptance: the composed-gate falsifiers, executed from the verifier export =="
  job bash -c 'cd "$1" && exec "$2" run_corpus.py --kind composed --candidate "$3" --base "$4"' _ "$VSEAT" "$PY" "$CANDID" "$BASE" >"$WORK/composed.out" 2>&1
  cfc=$?
  sed 's/^/  /' "$WORK/composed.out"
  sub composed-gate-falsifiers "$cfc" "$WORK/composed.out" 'not-rejected=0'
  missing=""
  for m in 'GATE fix-01' 'GATE fls-01' 'GATE prv-01' 'GATE cor-01' 'GATE uni-01' 'GATE enc-01' 'GATE tcb-01'; do
    grep -q "$m" "$WORK/checks.out" || missing="$missing [$m]"
  done
  grep -q 'CONTROL HOLDS' "$WORK/composed.out" || missing="$missing [composed-gate control]"
  if [ -n "$missing" ]; then echo "ACCEPT evidence: FAIL (subset(s) absent from the evidence:$missing)"; fail=$((fail+1)); failed_names="$failed_names evidence"
  else echo "ACCEPT evidence: PASS"; pass=$((pass+1)); fi
  echo "### ACCEPTANCE SUMMARY: candidate=$CANDID tree=$TREE base=$BASE subsets-passed=$pass subsets-failed=$fail"
  if [ $fail -eq 0 ]; then
    echo "### ARCHITECTURE MODEL LAWS: PASS — the complete acceptance battery ran from an export of candidate"
    echo "### $TREE, bound to the machinery that tree declares."
    echo "### NOT semantic, legal, security, behavioural, operational or qualification proof. No freeze and no"
    echo "### qualification follows."
    exit 0
  fi
  echo "### FAILED SUBSETS:$failed_names"; echo "### ARCHITECTURE MODEL LAWS: FAIL"; exit 1
fi

# every check reads the SAME exported candidate and the SAME workspace: one export, one commitment, one answer
gc(){ job "$PY" gate_checks.py "$1" --candidate "$CANDID" --tree "$TREE" --base "$BASE" --work "$WORK" >"$WORK/$1.out" 2>&1; rc=$?; cat "$WORK/$1.out"; return $rc; }

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
echo "  kernel + hash provider: $KSLOC non-blank non-comment lines (budget 400 — the LISP PATH's budget, NOT the"
echo "  total trusted computing base, which is measured by tcb-01 below and is an order of magnitude larger)"
gc tcb; ck tcb-01-acceptance-base-measured-and-every-growth-attributed "$?"

echo "== hashing =="
gc hash-engines; ck hsh-01-two-vetted-engines-agree-on-raw-bytes "$?"

echo "== provenance, universe and encoding =="
gc provenance; ck prv-01-verifier-is-the-candidates-machinery "$?"
gc universe;   ck uni-01-no-declared-family-below-its-floor "$?"   # history-bound: the base's whole model, floors, authorizations, schema version
gc encoding;   ck enc-01-three-implementations-one-encoding "$?"

echo "== the verification corpus itself =="
gc corpus; ck cor-01-corpus-universe-is-exact "$?"
job "$PY" "$SEAT/run_corpus.py" --kind fixtures --base "$BASE" --work "$WORK/fx" >"$WORK/fixtures.out" 2>&1; fxc=$?
tail -1 "$WORK/fixtures.out" | sed 's/^/  /'
ck fix-01-golden-and-generated-fixtures "$fxc"
# COMPONENT falsifiers only. The COMPOSED_GATE falsifiers execute THIS script's --checks phase and are
# therefore run by its full phase — a checks phase that ran them would recurse forever (Review-2 N-2).
job "$PY" run_corpus.py --kind component --candidate "$CANDID" --base "$BASE" >"$WORK/falsifiers.out" 2>&1; flc=$?
grep -E '^held-out falsifiers' "$WORK/falsifiers.out" | sed 's/^/  /'
grep -E '^  NOT REJECTED' "$WORK/falsifiers.out" | sed 's/^/  /'
ck fls-01-component-falsifiers-all-rejected "$flc"

echo "== migration-scope ledger =="
job bash -c 'cd "$1" && exec "$2" build_deferred.py --verify' _ "$SEAT" "$PY" >"$WORK/ledger.out" 2>&1; ddic=$?
grep -E 'DEFERRED-IMPORT LEDGER' "$WORK/ledger.out" | sed 's/^/  /'
[ $ddic -eq 0 ] && grep -q 'DEFERRED-IMPORT LEDGER: PASS' "$WORK/ledger.out"
ck led-01-deferred-ledger-exact-source-universe "$?"

echo "== derived documents =="
gc conflict-ledger;    ck doc-01-conflict-ledger-reconciled-both-ways "$?"
gc packet;             ck doc-02-decision-packet-reconciled-to-the-model "$?"
gc dependency-closure; ck doc-03-governance-closure-declared-and-historic-free "$?"

echo "== the gate's own effect on the repository =="
# Review-4 R4-7: the former ro-02 compared the working-tree candidate tree before and after; ro-01's measure IS
# that tree plus the bytes of every untracked file, so ro-02 was a strict subset that could never fail alone.
# One property, one counted check.
WT_AFTER=$("$PY" gate_checks.py content-state)
[ "$WT_BEFORE" = "$WT_AFTER" ]; a=$?
ck ro-01-repository-content-identical-after-the-run "$a"

echo "== reported, not counted =="
rx=$(grep -vE '^[[:space:]]*;' "$SEAT/KERNEL/model-law-kernel.lisp" "$SEAT/KERNEL/hash-provider.lisp" | grep -ciE 'ppcre|shell-out')
note krn-lexical-scan "a lexical scan of the kernel sources for regex/shell constructs found $rx; a lexical scan cannot prove absence"
note packet-single-operator-assurance "the decision packet states that no gate requires exhaustive human repository review; the statement is prose, its totals are what the counted checks reconcile"
note composed-gate-battery "the $(grep -c ':harness COMPOSED_GATE' "$SEAT/verification-corpus.sexp") COMPOSED_GATE falsifiers execute this script with --checks and are run by its own full phase as run_corpus.py --kind composed, never from inside the checks phase"

echo "### ARCHITECTURE-MODEL-GATE SUMMARY: candidate=$CANDID tree=$TREE base=$BASE pass=$pass fail=$fail informational=$info"
echo "### $((pass+fail)) OPTION-2 ACCEPTANCE CHECKS — NOT THE ORIGINAL 20 OPTION-A FULL-BUILD GATES (those remain a"
echo "### mandatory future stage after DDI-1…DDI-4; nothing here completes, replaces or executes them)"
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
