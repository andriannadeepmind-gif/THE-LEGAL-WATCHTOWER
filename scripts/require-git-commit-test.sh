#!/usr/bin/env bash
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SEAT="$REPO/scripts/require-git-commit.sh"
HEAD_SHA="$(git -C "$REPO" rev-parse --verify 'HEAD^{commit}')"
p=0; f=0
ok(){ p=$((p+1)); echo "  ok   $*"; }
no(){ f=$((f+1)); echo "  FAIL $*"; }

accept(){
  local label="$1" value="$2" out rc
  out="$(bash "$SEAT" "$value" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ] && [ "$out" = "$HEAD_SHA" ]; then ok "$label"; else no "$label (exit=$rc output='$out')"; fi
}
reject(){
  local label="$1" value="$2" out rc
  out="$(bash "$SEAT" "$value" 2>&1)"; rc=$?
  if [ "$rc" -ne 0 ] && grep -q '^::error::' <<<"$out"; then ok "$label"; else no "$label (exit=$rc output='$out')"; fi
}

accept "δέχεται μόνο το ακριβές checkout HEAD" "$HEAD_SHA"
reject "απορρίπτει κενό" ""
reject "απορρίπτει legacy dev default" "dev"
reject "απορρίπτει 39-hex" "${HEAD_SHA%?}"
reject "απορρίπτει άλλο 40-hex commit" "0000000000000000000000000000000000000000"
reject "απορρίπτει uppercase SHA" "${HEAD_SHA^^}"

echo "── GIT_COMMIT seat: $p passed, $f failed ──"
[ "$f" -eq 0 ]
