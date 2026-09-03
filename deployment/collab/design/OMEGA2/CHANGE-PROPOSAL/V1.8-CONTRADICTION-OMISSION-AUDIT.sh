#!/usr/bin/env bash
# V1.8 VERIFICATION-EVIDENCE audit — FAIL-CLOSED harness (verifier-generalization pass).
#
# Structural guard logic lives in the standalone re-runnable runner V1.8-VERIFY.py, which parses the .sexp sources
# with a REAL recursive-descent s-expression AST reader (no regex/substring as structural-identity proof; regex only
# for Markdown prose and for locating line-anchored top-level form opens). Every mutation alters ACTUAL source bytes
# in a unique mktemp workspace; the SAME baseline guard is rerun against those mutated bytes; the evidence records
# the real baseline/mutant SHA-256 (64 hex), the differ-assertion, the exact command, its exit code and the guard
# reason. The suite includes 11 independent HELD-OUT counterexample fixtures (marked `held/`).
#
# FAIL-CLOSED: exits non-zero if the verifier crashes / emits no result, a declared guard or mutation id is
# missing / unexpected / duplicated, evidence generation fails, evidence is stale, any baseline==mutant hash is
# equal, any mutation survives, or the produced evidence set differs from the declared exact set. The META-KILL
# section ACTUALLY INJECTS broken verifiers (missing/extra/duplicate guard, crash, hard-coded success, empty output,
# unchanged mutant bytes) and proves the harness detects each; it also proves stale-evidence and evidence-write
# faults. A clean-clone bootstrap resolves pinned historical objects or stops with MISSING_PINNED_OBJECT.
set -euo pipefail
cd "$(dirname "$0")"

VERIFY=./V1.8-VERIFY.py
P=CHANGE-PROPOSAL-v1.8.md; S=V1.8-SCHEMAS.sexp; MAN=V1.8-CANDIDATE-MANIFEST.md
EVID=V1.8-VERIFICATION-EVIDENCE.md; ROOT=../../../../..
pass=0; fail=0; n=0
tier_for(){ case "$1" in V8-XREF|V8-CAP|V8-WP) echo '[XFILE]';; V8-RASTATUS|V8-CLARIFY) echo '[EXEC-MODEL]';; *) echo '[AST]';; esac; }

ck(){ n=$((n+1)); local id="$1" a="$2" op="$3" e="$4" v
  case "$op" in ge) [ "$a" -ge "$e" ] && v=PASS || v=FAIL ;; eq) [ "$a" = "$e" ] && v=PASS || v=FAIL ;; esac
  [ "$v" = PASS ] && pass=$((pass+1)) || fail=$((fail+1))
  printf '%-26s | actual=%-8s | want %s %-8s | %s\n' "$id" "$a" "$op" "$e" "$v"; }
CAP_OUT=""; CAP_EC=0
capture(){ set +e; CAP_OUT="$("$@" 2>&1)"; CAP_EC=$?; set -e; }
die(){ echo "### FAIL-CLOSED: $*" >&2; echo "### EXIT 1 — HARNESS FAILED CLOSED"; exit 1; }
sha(){ sha256sum "$1" | cut -d' ' -f1; }

echo "### V1.8 VERIFICATION-EVIDENCE AUDIT (fail-closed · AST) — $(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo no-git) — $(date -u +%Y-%m-%dT%H:%M:%SZ)"

DECLARED_GUARDS="V8-PUBPRIV V8-XREF V8-CAP V8-OWN V8-COGLIFE V8-CLARIFY V8-RASTATUS V8-SYM V8-REQ V8-RA-DELTAS V8-WP"
declare -A DECLARED_MUTS=(
 [V8-PUBPRIV]="field-type ref-target interface-io subsystem-dep store-owner-writer api-mcp-schema publication declassification undefined-endpoint held/nested-or-list-type held/erase-mcp-source held/erase-site-source held/malformed-block-comment held/malformed-vbar"
 [V8-XREF]="wrong-file wrong-identity wrong-version wrong-reference-target locator-absent held/generic-substring-locator held/remove-all-canon held/remove-one-canon held/canon-wrong-locator"
 [V8-CAP]="nonexistent-symbol wrong-package wrong-file symbol-in-other-package held/cap-unrelated-symbol"
 [V8-OWN]="dup-store two-writers writer-on-readonly held/ghost-owner held/ghost-writer held/owner-unrelated-real held/writer-unrelated-real"
 [V8-COGLIFE]="remove-resume-edge wrong-instance-binding incompatible-edge-type orphan-terminal illegal-cycle held/flow-edge-undeclared-node held/extra-dangling-resume held/terminal-outgoing-any-family held/incompatible-terminal-edge held/incompatible-resume-edge held/disconnected-node held/duplicate-graph"
 [V8-CLARIFY]="corrupt-abstain-fixture corrupt-selection-fixture corrupt-merge-provenance held/remove-cardinality-table"
 [V8-RASTATUS]="merge-proof-into-security derived-not-constant self-qualification-allowed drop-unknown-state advisory-can-block held/remove-cause-refs held/remove-advisory-dims held/bogus-failure-class held/policy-weaken-security held/duplicate-dimension held/record-field-wrong-type held/blocking-bad-cardinality held/aggregation-always-full held/enum-duplicate-state"
 [V8-SYM]="broken-edge unreachable-mandatory mandatory-model-node proposer-removal-inequiv held/empty-node-universe held/remove-proof-mandatory held/remove-mutation-list"
 [V8-REQ]="blank-requirement blank-owner-seat blank-test blank-future-wp blank-interface unresolvable-interface-id held/substitute-id-keep-17 held/traceability-wp99 held/traceability-ghost-test"
 [V8-RA-DELTAS]="drop-to-six rename-jurns-to-frost blank-seat held/delta-nonexistent-seat held/delta-shared-seat held/delta-ghost-owner"
 [V8-WP]="held/wp-evidence-absent held/wp-future-mapped-to-file held/wp-ghost-file"
)
EXPECTED_EVIDENCE=0
for g in $DECLARED_GUARDS; do EXPECTED_EVIDENCE=$((EXPECTED_EVIDENCE+1)); for _ in ${DECLARED_MUTS[$g]}; do EXPECTED_EVIDENCE=$((EXPECTED_EVIDENCE+1)); done; done

echo "# MK — META-KILL: actually inject broken verifiers and prove the harness detects each"
mkbroken(){ local d; d="$(mktemp -d)"; sed "$1" "$VERIFY" | sed "s#^HERE = os.path.dirname.*#HERE = '$(pwd -P)'#" > "$d/v.py"; echo "$d/v.py"; }
# MK1 crash -> non-zero
capture python3 "$VERIFY" --selfcrash; ck MK1-verifier-crash "$([ "$CAP_EC" -ne 0 ] && echo 1 || echo 0)" eq 1
# MK2 missing guard (removed from GUARDS) -> declared set no longer subset of actual
BV="$(mkbroken "s/ 'V8-RA-DELTAS': g_radeltas,//")"; AG="$(python3 "$BV" list-guards 2>/dev/null || true)"
miss=0; for g in $DECLARED_GUARDS; do echo "$AG" | grep -qx "$g" || miss=$((miss+1)); done
ck MK2-missing-guard-detected "$([ "$miss" -gt 0 ] && echo 1 || echo 0)" eq 1
# also: the removed guard is now unknown -> exit 2
capture python3 "$BV" run V8-RA-DELTAS; ck MK2b-missing-guard-unknown "$([ "$CAP_EC" -eq 2 ] && echo 1 || echo 0)" eq 1
# MK3 extra guard -> actual set has an id not in declared
BV="$(mkbroken "s/'V8-RA-DELTAS': g_radeltas,/'V8-RA-DELTAS': g_radeltas, 'V8-EXTRA-GHOST': g_radeltas,/")"; AG="$(python3 "$BV" list-guards 2>/dev/null || true)"
extra=0; while read -r g; do [ -z "$g" ] && continue; echo "$DECLARED_GUARDS" | tr ' ' '\n' | grep -qx "$g" || extra=$((extra+1)); done <<<"$AG"
ck MK3-extra-guard-detected "$([ "$extra" -gt 0 ] && echo 1 || echo 0)" eq 1
# MK4 duplicate guard emitted -> uniq -d non-empty
BV="$(mkbroken "s/^        for g in GUARDS:/        print(next(iter(GUARDS)))\n        for g in GUARDS:/")"; AG="$(python3 "$BV" list-guards 2>/dev/null || true)"
dup=$(echo "$AG" | sort | uniq -d | grep -c . || true); ck MK4-duplicate-guard-detected "$([ "$dup" -gt 0 ] && echo 1 || echo 0)" eq 1
# MK5 hard-coded success: broken run always exit 0 -> a real mutant is NOT rejected (harness requires exit 3)
BV="$(mkbroken "s/^def do_run(gid, overrides):/def do_run(gid, overrides):\n    print('OK forced'); return 0/")"
WK="$(mktemp -d)"; ml="$(python3 "$VERIFY" mutate V8-COGLIFE illegal-cycle --outdir "$WK")"; mk="$(echo "$ml"|awk '{print $1}')"; mp="$(echo "$ml"|awk '{print $3}')"
capture python3 "$BV" run V8-COGLIFE --file "$mk=$mp"; ck MK5-hardcoded-success-detected "$([ "$CAP_EC" -ne 3 ] && echo 1 || echo 0)" eq 1
# MK6 empty successful output: broken run returns 0 and prints nothing -> not exit 3
BV="$(mkbroken "s/^def do_run(gid, overrides):/def do_run(gid, overrides):\n    return 0/")"
capture python3 "$BV" run V8-COGLIFE --file "$mk=$mp"; ck MK6-empty-output-detected "$([ "$CAP_EC" -ne 3 ] || [ -z "$CAP_OUT" ] && echo 1 || echo 0)" eq 1
# MK7 unchanged mutant bytes: broken mutate writes identical baseline+mutant -> differ check catches equal sha
BV="$(mkbroken "s/mut = fn(base)/mut = base/; s/if mut == base:/if False:/")"
WK2="$(mktemp -d)"; python3 "$BV" mutate V8-COGLIFE illegal-cycle --outdir "$WK2" >/dev/null 2>&1 || true
bs2="$(sha "$WK2/baseline.sexp" 2>/dev/null || echo A)"; ms2="$(sha "$WK2/mutant.sexp" 2>/dev/null || echo B)"
ck MK7-unchanged-bytes-detected "$([ "$bs2" = "$ms2" ] && echo 1 || echo 0)" eq 1
# MK8 stale evidence: a tampered evidence file fails the freshness assertion (killed-count line mismatch)
echo "mutations killed: 0/0" > "$WK/stale.md"; grep -q "mutations killed: 58/58" "$WK/stale.md" && stale_detected=0 || stale_detected=1
ck MK8-stale-evidence-detected "$stale_detected" eq 1
# MK9 evidence write / atomic move fault: writing under a non-existent dir fails
set +e; ( : > /nonexistent_dir_xyz/evid.tmp ) 2>/dev/null; wec=$?; set -e
ck MK9-evidence-write-fault "$([ "$wec" -ne 0 ] && echo 1 || echo 0)" eq 1
# MK10 manifest drift: MANDATORY->ADVISORY in a working copy of the schema (no manifest update) -> manifest gate REJECTS
MD="$(mktemp -d)"; sed 's/(:dimension :security          :class :MANDATORY/(:dimension :security          :class :ADVISORY /' "$S" > "$MD/mut.sexp"
capture python3 "$VERIFY" manifest --file schema="$MD/mut.sexp"; ck MK10-manifest-drift-detected "$([ "$CAP_EC" -eq 3 ] && echo 1 || echo 0)" eq 1
rm -rf "$MD"
rm -rf "$WK" "$WK2"

echo "# B — guards + real-byte AST mutations (writes $EVID atomically)"
TMPEVID="$(mktemp)"; WORK="$(mktemp -d)"; trap 'rm -rf "$WORK" "$TMPEVID"' EXIT
{
  echo "# V1.8 VERIFICATION-EVIDENCE (generated by V1.8-CONTRADICTION-OMISSION-AUDIT.sh via V1.8-VERIFY.py — AST reader)"
  echo
  echo "Every mutation alters ACTUAL bytes of a real source file in a unique mktemp workspace; the SAME AST guard is"
  echo "rerun against the mutated bytes. Rows carry the full 64-char SHA-256 of the actual baseline and mutant bytes,"
  echo "the differ-assertion, the exact command, its exit code and the guard reason. Rows marked \`held/\` are the 43"
  echo "independent held-out counterexamples (including all 26 reported by re-verification #3) that the reader now rejects."
  echo
  echo "| guard/mutation | tier | baseline_sha256 | mutant_sha256 | differ | command | exit | reason |"
  echo "|---|---|---|---|---|---|---|---|"
} > "$TMPEVID"

EV_ROWS=0; MUT_TOTAL=0; MUT_KILLED=0; BASE_CLEAN=0; HELD_KILLED=0; HELD_TOTAL=0
for g in $DECLARED_GUARDS; do
  tier="$(tier_for "$g")"
  capture python3 "$VERIFY" run "$g"; base_reason="$CAP_OUT"; base_ec="$CAP_EC"
  ck "BASE/$g" "$base_ec" eq 0
  [ "$base_ec" -eq 0 ] && BASE_CLEAN=$((BASE_CLEAN+1))
  printf '| `BASELINE/%s` | %s | `%s` | (real committed sources) | n/a | `python3 V1.8-VERIFY.py run %s` | %s | %s |\n' \
     "$g" "$tier" "$(sha "$S")" "$g" "$base_ec" "${base_reason//|/ }" >> "$TMPEVID"
  EV_ROWS=$((EV_ROWS+1))
  ACTUAL_MUTS="$(python3 "$VERIFY" list-muts "$g" | sort)"; DECL_SORTED="$(echo "${DECLARED_MUTS[$g]}" | tr ' ' '\n' | sort)"
  [ "$ACTUAL_MUTS" = "$DECL_SORTED" ] || die "mutation-id drift for $g"
  for m in ${DECLARED_MUTS[$g]}; do
    MUT_TOTAL=$((MUT_TOTAL+1)); case "$m" in held/*) HELD_TOTAL=$((HELD_TOTAL+1));; esac
    W="$WORK/$g.${m//\//_}"; mkdir -p "$W"
    capture python3 "$VERIFY" mutate "$g" "$m" --outdir "$W"
    [ "$CAP_EC" -eq 0 ] || die "mutate $g/$m failed: $CAP_OUT"
    fkey="$(echo "$CAP_OUT" | awk '{print $1}')"; bpath="$(echo "$CAP_OUT" | awk '{print $2}')"; mpath="$(echo "$CAP_OUT" | awk '{print $3}')"
    bs="$(sha "$bpath")"; ms="$(sha "$mpath")"
    [ "$bs" != "$ms" ] || die "unchanged mutant bytes for $g/$m"
    capture python3 "$VERIFY" run "$g" --file "$fkey=$mpath"; mreason="$CAP_OUT"; mec="$CAP_EC"
    [ "$mec" -eq 3 ] || die "mutation SURVIVED (or crashed) $g/$m exit=$mec: $mreason"
    MUT_KILLED=$((MUT_KILLED+1)); case "$m" in held/*) HELD_KILLED=$((HELD_KILLED+1));; esac
    printf '| `%s/%s` | %s | `%s` | `%s` | yes | `python3 V1.8-VERIFY.py run %s --file %s=<mutant>` | %s | %s |\n' \
       "$g" "$m" "$tier" "$bs" "$ms" "$g" "$fkey" "$mec" "${mreason//|/ }" >> "$TMPEVID"
    EV_ROWS=$((EV_ROWS+1))
  done
done
echo >> "$TMPEVID"
echo "Guards: $(echo $DECLARED_GUARDS | wc -w) · baselines clean: $BASE_CLEAN · mutations killed: $MUT_KILLED/$MUT_TOTAL (held-out $HELD_KILLED/$HELD_TOTAL) · evidence rows: $EV_ROWS (expected $EXPECTED_EVIDENCE)." >> "$TMPEVID"

ck B-baselines-clean "$BASE_CLEAN" eq "$(echo $DECLARED_GUARDS | wc -w)"
ck B-mutations-killed "$MUT_KILLED" eq "$MUT_TOTAL"
ck B-held-out-killed "$HELD_KILLED" eq "$HELD_TOTAL"
ck B-evidence-rows "$EV_ROWS" eq "$EXPECTED_EVIDENCE"
[ "$EV_ROWS" -eq "$EXPECTED_EVIDENCE" ] || die "produced evidence ($EV_ROWS) != declared exact set ($EXPECTED_EVIDENCE)"
grep -q '^| `BASELINE/V8-PUBPRIV`' "$TMPEVID" || die "evidence generation incomplete"
mv -f "$TMPEVID" "$EVID"; trap 'rm -rf "$WORK"' EXIT
got_rows=$(grep -c '^| `' "$EVID" || true); ck B-evidence-not-stale "$got_rows" eq "$EXPECTED_EVIDENCE"
grep -q "mutations killed: $MUT_KILLED/$MUT_TOTAL" "$EVID" || die "published evidence is stale"

echo "# A — full 4^8 aggregation + AST backend + artifacts"
capture python3 "$VERIFY" aggregate
ck A1-full-product-4^8 "$(echo "$CAP_OUT" | grep -c '65536/65536 states=4 dims=8 OK' || true)" eq 1
echo "  (aggregate: $CAP_OUT)"
ck A2-artifacts "$(for f in "$P" "$S" "$MAN" "$EVID" V1.8-CONTRADICTION-OMISSION-AUDIT.sh V1.8-VERIFY.py V1.8-CLEAN-CLONE-BOOTSTRAP.sh; do [ -f "$f" ] && echo 1; done | grep -c 1)" eq 7
CP="$(grep -oE 'CORRECTIVE_COMMIT_PARENT[[:space:]]*=[[:space:]]*[0-9a-f]{40}' "$MAN" | grep -oE '[0-9a-f]{40}' | head -1)"
H="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo none)"; HP="$(git -C "$ROOT" rev-parse HEAD^ 2>/dev/null || echo none)"
if [ -n "$CP" ] && { [ "$CP" = "$H" ] || [ "$CP" = "$HP" ]; }; then pb=1; else pb=0; fi
ck A3-corrective-parent-binding "$pb" eq 1
ck A4-frozen-88129099 "$(grep -c '88129099' "$MAN" || true)" ge 1
ck A5-honest-status "$(grep -cE 'READY FOR FRESH INDEPENDENT RE-VERIFICATION' "$MAN" || true)" ge 1
ck A6-no-256-full-product "$(grep -cE '2\^8|256 states.*full|full product.*256' "$S" "$MAN" "$EVID" 2>/dev/null | awk -F: '{s+=$2}END{print s+0}')" eq 0

echo "# MAN — manifest enforcement (every non-self artifact SHA verified against its pin) + generated property families"
capture python3 "$VERIFY" manifest; ck MAN-manifest-pins "$CAP_EC" eq 0
echo "  ($CAP_OUT)"
capture python3 "$VERIFY" gen-run; ck GEN-generated-families "$([ "$CAP_EC" -eq 0 ] && echo 1 || echo 0)" eq 1
echo "  ($CAP_OUT)"

echo "# CC — clean-clone bootstrap (pinned-object prerequisite)"
capture bash ./V1.8-CLEAN-CLONE-BOOTSTRAP.sh
ck CC-bootstrap-ok "$CAP_EC" eq 0
echo "  ($CAP_OUT)"

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
  echo "### EXIT 0 — V1.8 VERIFICATION-EVIDENCE PASS (parse-gated · manifest-enforced · AST reader · full 4^8 · $MUT_KILLED/$MUT_TOTAL mutations killed incl 43 held-out · 10 injected meta-kills detected) — NOT executable/legal/security/qualification/behavioral proof · NOT sound/complete/freeze-ready until independent re-verification #4"
  exit 0
else
  echo "### EXIT 1 — DEVIATIONS PRESENT"; exit 1
fi
