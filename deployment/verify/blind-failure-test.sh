#!/usr/bin/env bash
# ============================================================================
# LAWMAX BLIND FAILURE-MEMORY TEST (Π0 verification) — v2, ερμητικό & αυτόματο
# ============================================================================
# VERIFICATION ARTIFACT (όχι runtime feature): δεν εγγράφει εντολή, δεν
# δημιουργεί έδρα/store/primitive — τρέχει ΕΞΩ από το σύστημα, πάνω σε
# προσωρινά αντίγραφα. Δηλωμένο στο Σύνταγμα (:verification-artifacts).
#
# Χρήση (από τη ρίζα του repo):
#   bash deployment/verify/blind-failure-test.sh "blind ερώτηση 1" ["ερ.2" …]
# Μεταβλητές: IMAGE (default orchestrator:latest) · D (default $PWD)
#             KEEP=1 κρατά το TESTROOT (μόνο αν το ζητήσεις ρητά)
#             SKIP_GATES=1 παραλείπει το βήμα των πυλών (για γρήγορο κύκλο)
#
# ΤΙ ΔΕΝ ΚΑΝΕΙ: δεν αγγίζει ΠΟΤΕ το πραγματικό deployment/ ή output/ ·
# δεν κάνει backup μέσα στο state · δεν κρατά test failures χωρίς KEEP=1 ·
# δεν κάνει Runner/learning/approval/refactor.
set -euo pipefail

D="${D:-$PWD}"
IMAGE="${IMAGE:-orchestrator:latest}"
[ $# -ge 1 ] || { echo "χρήση: $0 \"ερώτηση1\" [\"ερώτηση2\" …]" >&2; exit 2; }

TESTROOT="$(mktemp -d /tmp/lawmax-blind-XXXXXXXX)"
TESTDEPLOY="$TESTROOT/deployment"
TESTOUTPUT="$TESTROOT/output"
LEDGER="$TESTDEPLOY/state/failure-ledger.jsonl"

cleanup() {
  if [ "${KEEP:-0}" = "1" ]; then
    echo "KEEP=1 → το test περιβάλλον ΚΡΑΤΗΘΗΚΕ: $TESTROOT"
  else
    rm -rf "$TESTROOT"
    echo "cleanup: διαγράφηκε $TESTROOT (η παραγωγή δεν αγγίχτηκε ποτέ)"
  fi
}
trap cleanup EXIT

echo "═ 1/7 Αντιγραφή deployment+output σε $TESTROOT (η παραγωγή μένει άθικτη)"
cp -r "$D/deployment" "$TESTDEPLOY"
cp -r "$D/output"     "$TESTOUTPUT"

run() {  # ΜΟΝΟ τα προσωρινά αντίγραφα — καμία αναφορά στο πραγματικό $D
  docker run --rm \
    -v "$TESTOUTPUT:/app/output" \
    -v "$TESTDEPLOY:/app/deployment" \
    "$IMAGE" "$@"
}
count() { if [ -f "$LEDGER" ]; then wc -l < "$LEDGER"; else echo 0; fi; }

PASS=0; FAIL=0
ok()  { echo "  [PASS] $1"; PASS=$((PASS+1)); }
bad() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }

B0="$(count)"
echo "═ 2/7 Ledger ΠΡΙΝ: $B0 εγγραφές"

LASTFID=""; LASTQ=""
i=0
for q in "$@"; do
  i=$((i+1))
  echo; echo "═ 3/7 BLIND #$i: «$q»"
  OUT="$(run --ask "$q")" || true
  printf '%s\n' "$OUT"
  FID="$(printf '%s\n' "$OUT" | sed -n 's/^failure_id: \(fail:[0-9a-f]*\).*/\1/p' | head -1)"
  GID="$(printf '%s\n' "$OUT" | sed -n 's/^gap_id: \(gap:[^ ]*\).*/\1/p' | head -1)"
  if [ -n "$FID" ]; then ok "#$i failure_id στο envelope: $FID"; else bad "#$i ΧΩΡΙΣ failure_id στο envelope"; fi
  if printf '%s' "$OUT" | grep -q "memory_recorded: true"; then ok "#$i memory_recorded: true"; else bad "#$i χωρίς memory_recorded"; fi
  if [ -n "$FID" ] && grep -q "$FID" "$LEDGER" 2>/dev/null; then
    ok "#$i ο $FID ΥΠΑΡΧΕΙ στον test ledger"
    LINE="$(grep "$FID" "$LEDGER" | tail -1)"
    if [ -n "$GID" ] && printf '%s' "$LINE" | grep -q "$GID"; then ok "#$i gap_id ταυτίζεται ($GID)"; else bad "#$i gap_id ΔΕΝ ταυτίζεται"; fi
    if printf '%s' "$LINE" | grep -q '"status":"open"'; then ok "#$i status: open"; else bad "#$i χωρίς status open"; fi
    LASTFID="$FID"; LASTQ="$q"
  else
    bad "#$i το failure_id ΔΕΝ βρέθηκε στον ledger"
  fi
done

B1="$(count)"
echo
if [ "$B1" -eq "$((B0 + $#))" ]; then ok "count: $B0 → $B1 (+$# — μία εγγραφή ανά blind ερώτηση)"; else bad "count: $B0 → $B1 (αναμενόταν +$#)"; fi

echo; echo "═ 4/7 RECALL: «δείξε μου τι κατέγραψες»"
ROUT="$(run --ask "δείξε μου τι κατέγραψες")" || true
printf '%s\n' "$ROUT"
if [ -n "$LASTFID" ] && printf '%s' "$ROUT" | grep -q "$LASTFID"; then ok "recall: δείχνει το $LASTFID"; else bad "recall: δεν δείχνει το τελευταίο failure_id"; fi
if [ -n "$LASTQ" ] && printf '%s' "$ROUT" | grep -qF "$LASTQ"; then ok "recall: δείχνει το αυθεντικό input"; else bad "recall: δεν δείχνει το input"; fi
for fld in produced_mode wrong_behavior created_gap status; do
  if printf '%s' "$ROUT" | grep -q "$fld"; then ok "recall: πεδίο $fld"; else bad "recall: λείπει το $fld"; fi
done

echo; echo "═ 5/7 NEGATIVE: «ποιος είσαι;» δεν πρέπει να γράψει"
B2="$(count)"
run --ask "ποιος είσαι;" > /dev/null || true
B3="$(count)"
if [ "$B2" -eq "$B3" ]; then ok "negative: $B2 → $B3 (καμία νέα εγγραφή)"; else bad "negative: $B2 → $B3 (γράφτηκε εγγραφή!)"; fi

echo; echo "═ 6/7 DUPLICATE-LEDGER CHECK (σωστό find με παρενθέσεις)"
FOUND="$(find "$TESTDEPLOY/self" "$TESTDEPLOY/state" \( -name "*failure*" -o -name "*ledger*" \) -print)"
printf '%s\n' "$FOUND"
if [ "$FOUND" = "$LEDGER" ]; then ok "ένας και μόνο ledger: $LEDGER"; else bad "βρέθηκαν επιπλέον ledger-like αρχεία"; fi

if [ "${SKIP_GATES:-0}" != "1" ]; then
  echo; echo "═ 7/7 GATES πάνω στο TEST περιβάλλον"
  run --understanding-gate             && ok "--understanding-gate"             || bad "--understanding-gate"
  run --architecture-constitution-gate && ok "--architecture-constitution-gate" || bad "--architecture-constitution-gate"
  run --gates                          && ok "--gates (ολομέλεια)"              || bad "--gates"
else
  echo; echo "═ 7/7 GATES: ΠΑΡΑΛΕΙΦΘΗΚΑΝ (SKIP_GATES=1) — τρέξε τα χωριστά για πλήρη πιστοποίηση"
fi

echo
echo "═══ ΑΠΟΤΕΛΕΣΜΑ: PASS=$PASS FAIL=$FAIL ═══"
[ "$FAIL" -eq 0 ]
