#!/usr/bin/env bash
# Πύλη: ΟΛΕΣ οι τελετές προβάρονται ΠΡΑΓΜΑΤΙΚΑ και το production STOP POINT κρατά.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export LAWMAX_CEREMONY_WORK="$(mktemp -d)"
trap 'rm -rf "$LAWMAX_CEREMONY_WORK"' EXIT
p=0; f=0
ok(){ p=$((p+1)); echo "  ok   $*"; }
no(){ f=$((f+1)); echo "  FAIL $*"; }
for c in rehearse-genesis rehearse-rotation rehearse-revocation rehearse-recovery; do
  if bash "$HERE/roles/ceremony.sh" "$c" >/dev/null 2>&1; then ok "$c εκτελέστηκε"
  else no "$c ΑΠΕΤΥΧΕ"; fi
done
# ΤΟ ΟΡΙΟ: κάθε production εντολή ΠΡΕΠΕΙ να σταματά με exit 3.
for c in production-genesis production-rotation production-revocation; do
  bash "$HERE/roles/ceremony.sh" "$c" >/dev/null 2>&1
  [ $? -eq 3 ] && ok "$c ΣΤΑΜΑΤΑ (exit 3)" || no "$c ΔΕΝ σταμάτησε — ΠΑΡΑΒΙΑΣΗ ΟΡΙΟΥ"
done
# Και με ρητό MODE=production, ακόμη και οι rehearse εντολές σταματούν.
LAWMAX_CEREMONY_MODE=production bash "$HERE/roles/ceremony.sh" rehearse-genesis >/dev/null 2>&1
[ $? -eq 3 ] && ok "MODE=production ⇒ ακόμη και rehearse σταματά" || no "MODE=production ΔΕΝ κράτησε"
echo; echo "── ceremony rehearsal: $p passed, $f failed ──"
[ $f -eq 0 ]
