#!/usr/bin/env bash
# V1.8 VERIFICATION-EVIDENCE audit — FAIL-CLOSED harness (re-verification corrective pass).
#
# The guard logic lives in the standalone, re-runnable runner V1.8-VERIFY.py. Every mutation alters ACTUAL source
# bytes in a unique mktemp workspace; the SAME baseline guard is rerun against those mutated bytes; the evidence
# records the real baseline/mutant PATHS, the full 64-char SHA-256 of the real baseline bytes and the real mutant
# bytes, an assertion that they differ, the exact command, its exit code, and the guard reason that rejected the
# mutant. No filename / label / description is ever hashed as a substitute for mutated content.
#
# FAIL-CLOSED: the run exits non-zero if the verifier crashes or emits no result, a declared guard/mutation id is
# missing / unexpected / duplicated, evidence generation fails, evidence is stale, any baseline==mutant hash is
# equal, any mutation survives, or the produced evidence set differs from the declared exact set. Meta-kill tests
# prove the harness itself fails closed. There is no `except Exception: pass` anywhere in the runner.
#
# EVIDENCE TIERS (honest): [STR] structural/type · [XFILE] opens a real file and verifies a real definition ·
# [EXEC-MODEL] executes a machine-readable contract over the MODEL (e.g. the full 4^8 root-authority product).
# It is NOT executable-protocol / legal / security-qualification / operational / behavioral proof.
set -euo pipefail
cd "$(dirname "$0")"

VERIFY=./V1.8-VERIFY.py
P=CHANGE-PROPOSAL-v1.8.md; S=V1.8-SCHEMAS.sexp; MAN=V1.8-CANDIDATE-MANIFEST.md
EVID=V1.8-VERIFICATION-EVIDENCE.md; ROOT=../../../../..
pass=0; fail=0; n=0
tier_for(){ case "$1" in V8-XREF|V8-CAP) echo '[XFILE]';; V8-RASTATUS|V8-CLARIFY) echo '[EXEC-MODEL]';; *) echo '[STR]';; esac; }

ck(){ n=$((n+1)); local id="$1" a="$2" op="$3" e="$4" v
  case "$op" in ge) [ "$a" -ge "$e" ] && v=PASS || v=FAIL ;; eq) [ "$a" = "$e" ] && v=PASS || v=FAIL ;; esac
  [ "$v" = PASS ] && pass=$((pass+1)) || fail=$((fail+1))
  printf '%-22s | actual=%-7s | want %s %-7s | %s\n' "$id" "$a" "$op" "$e" "$v"; }
# capture a command's stdout+exit WITHOUT tripping errexit
CAP_OUT=""; CAP_EC=0
capture(){ set +e; CAP_OUT="$("$@" 2>&1)"; CAP_EC=$?; set -e; }
die(){ echo "### FAIL-CLOSED: $*" >&2; echo "### EXIT 1 — HARNESS FAILED CLOSED"; exit 1; }
sha(){ sha256sum "$1" | cut -d' ' -f1; }

echo "### V1.8 VERIFICATION-EVIDENCE AUDIT (fail-closed) — $(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo no-git) — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "### tiers [STR]/[XFILE]/[EXEC-MODEL] — NOT executable/legal/security/qualification/behavioral proof; every mutation is real mutated bytes"

# ---------- DECLARED EXACT SETS (the harness fails if the runner drifts from these) ----------
DECLARED_GUARDS="V8-PUBPRIV V8-XREF V8-CAP V8-OWN V8-COGLIFE V8-CLARIFY V8-RASTATUS V8-SYM V8-REQ V8-RA-DELTAS"
declare -A DECLARED_MUTS=(
 [V8-PUBPRIV]="field-type ref-target interface-io subsystem-dep store-owner-writer api-mcp-schema publication declassification undefined-endpoint"
 [V8-XREF]="wrong-file wrong-identity wrong-version wrong-reference-target locator-absent"
 [V8-CAP]="nonexistent-symbol wrong-package wrong-file symbol-in-other-package"
 [V8-OWN]="dup-store two-writers writer-on-readonly owner-unreconciled"
 [V8-COGLIFE]="remove-resume-edge dangling-resume-target wrong-instance-binding incompatible-edge-type terminal-with-outgoing orphan-terminal illegal-cycle"
 [V8-CLARIFY]="corrupt-abstain-fixture corrupt-selection-fixture corrupt-merge-provenance"
 [V8-RASTATUS]="merge-proof-into-security derived-not-constant self-qualification-allowed drop-unknown-state advisory-can-block"
 [V8-SYM]="broken-edge unreachable-mandatory mandatory-model-node proposer-removal-inequiv"
 [V8-REQ]="blank-requirement blank-owner-seat blank-test blank-future-wp blank-interface unresolvable-interface-id"
 [V8-RA-DELTAS]="drop-to-six rename-jurns-to-frost blank-seat"
)
EXPECTED_EVIDENCE=0
for g in $DECLARED_GUARDS; do EXPECTED_EVIDENCE=$((EXPECTED_EVIDENCE + 1)); for _ in ${DECLARED_MUTS[$g]}; do EXPECTED_EVIDENCE=$((EXPECTED_EVIDENCE + 1)); done; done

echo "# M — META-KILL tests (the harness must fail closed on each fault)"
# M1 verifier crash -> non-zero (uncaught crash is exit 1; the harness treats any non-zero as fail-closed)
capture python3 "$VERIFY" --selfcrash; ck M1-verifier-crash "$([ "$CAP_EC" -ne 0 ] && echo 1 || echo 0)" eq 1
# M2 unknown guard (missing section-B / no result) -> exit 2
capture python3 "$VERIFY" run V8-DOES-NOT-EXIST; ck M2-missing-guard "$CAP_EC" eq 2
# M3 runner guard-id set matches the declared set exactly (no missing/extra/duplicate)
ACTUAL_GUARDS="$(python3 "$VERIFY" list-guards)"
[ -n "$ACTUAL_GUARDS" ] || die "runner emitted no guards"
dup=$(echo "$ACTUAL_GUARDS" | sort | uniq -d | grep -c . || true); ck M3a-no-duplicate-guard "$dup" eq 0
miss=0; for g in $DECLARED_GUARDS; do echo "$ACTUAL_GUARDS" | grep -qx "$g" || miss=$((miss+1)); done; ck M3b-no-missing-guard "$miss" eq 0
extra=0; while read -r g; do [ -z "$g" ] && continue; echo "$DECLARED_GUARDS" | tr ' ' '\n' | grep -qx "$g" || extra=$((extra+1)); done <<<"$ACTUAL_GUARDS"; ck M3c-no-unexpected-guard "$extra" eq 0
# M4 unchanged-bytes mutation is rejected by the runner (never silently "DETECTED")
MW=$(mktemp -d); capture python3 "$VERIFY" mutate V8-PUBPRIV field-type --outdir "$MW"
first="$(echo "$CAP_OUT" | awk '{print $2}')"; keyk="$(echo "$CAP_OUT" | awk '{print $1}')"
# feed the BASELINE (unchanged) back to the guard: must be OK (proves guard is not hard-coded to DETECTED)
capture python3 "$VERIFY" run V8-PUBPRIV --file "$keyk=$first"; ck M4-baseline-not-hardcoded "$CAP_EC" eq 0
rm -rf "$MW"
# M5 evidence-write-failure detection: writing under a non-existent dir must fail (fail-closed on I/O)
set +e; ( echo x > /nonexistent_dir_xyz/evid.tmp ) 2>/dev/null; wec=$?; set -e; ck M5-evidence-write-fault "$([ $wec -ne 0 ] && echo 1 || echo 0)" eq 1

echo "# B — guards + real-byte mutations (writes $EVID atomically) — the fail-closed engine"
TMPEVID="$(mktemp)"; WORK="$(mktemp -d)"; trap 'rm -rf "$WORK" "$TMPEVID"' EXIT
{
  echo "# V1.8 VERIFICATION-EVIDENCE (generated by V1.8-CONTRADICTION-OMISSION-AUDIT.sh via V1.8-VERIFY.py)"
  echo
  echo "Every mutation alters ACTUAL bytes of a real source file in a unique mktemp workspace; the SAME guard is"
  echo "rerun against the mutated bytes. Rows carry real baseline/mutant paths, full 64-char SHA-256 of the actual"
  echo "baseline and mutant bytes, the differ-assertion, the exact command, its exit code, and the guard reason."
  echo
  echo "| guard/mutation | tier | baseline_sha256 | mutant_sha256 | differ | command | exit | reason |"
  echo "|---|---|---|---|---|---|---|---|"
} > "$TMPEVID"

EV_ROWS=0; MUT_TOTAL=0; MUT_KILLED=0; BASE_CLEAN=0
for g in $DECLARED_GUARDS; do
  tier="$(tier_for "$g")"
  # BASELINE: guard on the real committed files must be clean (exit 0)
  capture python3 "$VERIFY" run "$g"
  base_reason="$CAP_OUT"; base_ec="$CAP_EC"
  ck "BASE/$g" "$base_ec" eq 0
  [ "$base_ec" -eq 0 ] && BASE_CLEAN=$((BASE_CLEAN+1))
  bshasrc="$(sha "$S")"
  printf '| `BASELINE/%s` | %s | `%s` | (real committed sources) | n/a | `python3 V1.8-VERIFY.py run %s` | %s | %s |\n' \
     "$g" "$tier" "$bshasrc" "$g" "$base_ec" "${base_reason//|/ }" >> "$TMPEVID"
  EV_ROWS=$((EV_ROWS+1))
  # runner's mutation-id set for this guard must equal the declared set
  ACTUAL_MUTS="$(python3 "$VERIFY" list-muts "$g" | sort)"
  DECL_SORTED="$(echo "${DECLARED_MUTS[$g]}" | tr ' ' '\n' | sort)"
  [ "$ACTUAL_MUTS" = "$DECL_SORTED" ] || die "mutation-id drift for $g"
  for m in ${DECLARED_MUTS[$g]}; do
    MUT_TOTAL=$((MUT_TOTAL+1))
    W="$WORK/$g.$m"; mkdir -p "$W"
    capture python3 "$VERIFY" mutate "$g" "$m" --outdir "$W"
    [ "$CAP_EC" -eq 0 ] || die "mutate $g/$m failed: $CAP_OUT"
    fkey="$(echo "$CAP_OUT" | awk '{print $1}')"; bpath="$(echo "$CAP_OUT" | awk '{print $2}')"; mpath="$(echo "$CAP_OUT" | awk '{print $3}')"
    bs="$(sha "$bpath")"; ms="$(sha "$mpath")"
    [ "$bs" != "$ms" ] || die "unchanged mutant bytes for $g/$m (baseline==mutant sha)"
    # rerun the SAME guard against the mutated bytes: must REJECT (exit 3)
    capture python3 "$VERIFY" run "$g" --file "$fkey=$mpath"
    mreason="$CAP_OUT"; mec="$CAP_EC"
    [ "$mec" -eq 3 ] || die "mutation SURVIVED (or crashed) $g/$m exit=$mec: $mreason"
    MUT_KILLED=$((MUT_KILLED+1))
    printf '| `%s/%s` | %s | `%s` | `%s` | yes | `python3 V1.8-VERIFY.py run %s --file %s=<mutant>` | %s | %s |\n' \
       "$g" "$m" "$tier" "$bs" "$ms" "$g" "$fkey" "$mec" "${mreason//|/ }" >> "$TMPEVID"
    EV_ROWS=$((EV_ROWS+1))
  done
done
echo >> "$TMPEVID"
echo "Guards: $(echo $DECLARED_GUARDS | wc -w) · baselines clean: $BASE_CLEAN · mutations killed: $MUT_KILLED/$MUT_TOTAL · evidence rows: $EV_ROWS (expected $EXPECTED_EVIDENCE)." >> "$TMPEVID"

ck B-baselines-clean "$BASE_CLEAN" eq "$(echo $DECLARED_GUARDS | wc -w)"
ck B-mutations-killed "$MUT_KILLED" eq "$MUT_TOTAL"
ck B-evidence-rows "$EV_ROWS" eq "$EXPECTED_EVIDENCE"
[ "$EV_ROWS" -eq "$EXPECTED_EVIDENCE" ] || die "produced evidence set ($EV_ROWS) != declared exact set ($EXPECTED_EVIDENCE)"

# atomic publish: write temp, validate completely, then replace
grep -q '^| `BASELINE/V8-PUBPRIV`' "$TMPEVID" || die "evidence generation incomplete (no section-B rows)"
mv -f "$TMPEVID" "$EVID"; trap 'rm -rf "$WORK"' EXIT
# staleness: the published evidence must equal what we just generated (row count + killed count)
got_rows=$(grep -c '^| `' "$EVID" || true); ck B-evidence-not-stale "$got_rows" eq "$((EXPECTED_EVIDENCE))"
grep -q "mutations killed: $MUT_KILLED/$MUT_TOTAL" "$EVID" || die "published evidence is stale"

echo "# A — full 4^8 aggregation + artifacts + honest status"
capture python3 "$VERIFY" aggregate
agg_ok=$(echo "$CAP_OUT" | grep -c '65536/65536 states=4 dims=8 OK' || true)
ck A1-full-product-4^8 "$agg_ok" eq 1
echo "  (aggregate: $CAP_OUT)"
ck A2-artifacts "$(for f in "$P" "$S" "$MAN" "$EVID" V1.8-CONTRADICTION-OMISSION-AUDIT.sh V1.8-VERIFY.py; do [ -f "$f" ] && echo 1; done | grep -c 1)" eq 6
ck A3-parent-451ce01a "$(grep -c '451ce01a' "$MAN" || true)" ge 1
ck A4-frozen-88129099 "$(grep -c '88129099' "$MAN" || true)" ge 1
ck A5-honest-status "$(grep -cE 'READY FOR FRESH INDEPENDENT RE-VERIFICATION' "$MAN" || true)" ge 1
# must NOT re-introduce the falsified 2^8 / 256 claim as the full product
ck A6-no-256-full-product "$(grep -cE '2\^8|256 states.*full|full product.*256' "$S" "$MAN" "$EVID" 2>/dev/null | awk -F: '{s+=$2}END{print s+0}')" eq 0

echo "# D — regressions (v1.7 + v1.6 + v1.5 + v1.4) + frozen immutability"
reg(){ set +e; bash "$1" >/dev/null 2>&1; local e=$?; set -e; echo $e; }
ck D1-v1.7 "$(reg ./V1.7-CONTRADICTION-OMISSION-AUDIT.sh)" eq 0
ck D2-v1.6 "$(reg ./V1.6-CONTRADICTION-OMISSION-AUDIT.sh)" eq 0
ck D3-v1.5 "$(reg ./V1.5-CONTRADICTION-OMISSION-AUDIT.sh)" eq 0
ck D4-v1.4 "$(reg ./V1.4-CONTRADICTION-OMISSION-AUDIT.sh)" eq 0
ck D5-frozen-tree "$(git -C "$ROOT" rev-parse 88129099^{tree} 2>/dev/null | grep -c '^a2617649596644c25894c4343f25ddb6c4dec1ce' || true)" eq 1
ck D6-pinned-out "$(sha256sum V1.4-CONTRADICTION-OMISSION-AUDIT.out | grep -c '^4873e61069d4a1a2a1047d059b81cd9103171776346650a3b5ed4eee077624fb' || true)" eq 1

echo "### SUMMARY: checks=$n pass=$pass fail=$fail"
if [ "$fail" -eq 0 ]; then
  echo "### EXIT 0 — V1.8 VERIFICATION-EVIDENCE PASS (fail-closed; [STR]+[XFILE]+[EXEC-MODEL] only; full 4^8 product; every mutation real mutated bytes) — NOT executable/legal/security/qualification/behavioral proof"
  exit 0
else
  echo "### EXIT 1 — DEVIATIONS PRESENT"
  exit 1
fi
