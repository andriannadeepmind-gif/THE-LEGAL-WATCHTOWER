#!/usr/bin/env bash
# ============================================================================
# LAWMAX BLIND FAILURE-MEMORY TEST (Π0 verification) — v3, Windows/Docker-safe
# ============================================================================
# VERIFICATION ARTIFACT (όχι runtime feature): τρέχει ΕΞΩ από το σύστημα, πάνω
# σε προσωρινά αντίγραφα· δεν εγγράφει εντολή/έδρα/store/primitive. Δηλωμένο
# στο Σύνταγμα (:verification-artifacts).
#
# ΓΙΑΤΙ v3: το v2 έβαζε Linux /tmp path ως Docker volume. Σε Windows+Docker
# Desktop το docker.exe δεν βλέπει το MSYS /tmp → mount ΔΕΝ προσαρτιόταν → ο
# container έτρεχε με το IMAGE deployment (χωρίς Σύνταγμα, χωρίς state, self μη
# εγγράψιμο). v3: (1) repo-local temp, (2) cygpath -w για Windows mount paths,
# (3) PREFLIGHT + SENTINEL πριν από ΟΠΟΙΟΔΗΠΟΤΕ --ask — αν αποτύχει, ΣΤΟΠ.
#
# Χρήση (από τη ρίζα του repo):
#   bash deployment/verify/blind-failure-test.sh "ερώτηση1" ["ερώτηση2" …]
# Μεταβλητές: IMAGE (default orchestrator:latest) · D (default $PWD)
#             KEEP=1 κρατά το TESTROOT · SKIP_GATES=1 παραλείπει τα gates
set -euo pipefail

D="${D:-$PWD}"
IMAGE="${IMAGE:-orchestrator:latest}"
[ $# -ge 1 ] || { echo "χρήση: $0 \"ερώτηση1\" [\"ερώτηση2\" …]" >&2; exit 2; }

# ── MSYS/Git-Bash: μην πειράξεις τα container paths (/app/...)· τα host paths
#    τα δίνουμε ΕΜΕΙΣ σε Windows μορφή με cygpath -w. ──
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL='*'

# to_win: MSYS/POSIX path → Windows path όταν τρέχουμε σε Git Bash· αλλιώς ως έχει.
to_win() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi
}

# ── repo-local temp (ΟΧΙ Linux /tmp): αποδεδειγμένα Docker-shared σε Windows ──
TESTROOT="$(mktemp -d "$D/.blindtest.XXXXXX")"
TESTDEPLOY="$TESTROOT/deployment"
TESTOUTPUT="$TESTROOT/output"
LEDGER="$TESTDEPLOY/state/failure-ledger.jsonl"

cleanup() {
  if [ "${KEEP:-0}" = "1" ]; then echo "KEEP=1 → ΚΡΑΤΗΘΗΚΕ: $TESTROOT"
  else rm -rf "$TESTROOT"; echo "cleanup: διαγράφηκε $TESTROOT (η παραγωγή δεν αγγίχτηκε ποτέ)"; fi
}
trap cleanup EXIT

PASS=0; FAIL=0
ok()  { echo "  [PASS] $1"; PASS=$((PASS+1)); }
bad() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }

echo "═ 1/9 Αντιγραφή deployment+output σε repo-local TESTROOT (παραγωγή άθικτη)"
cp -r "$D/deployment" "$TESTDEPLOY"
cp -r "$D/output"     "$TESTOUTPUT"
mkdir -p "$TESTDEPLOY/state" "$TESTDEPLOY/self"

WIN_DEPLOY="$(to_win "$TESTDEPLOY")"
WIN_OUTPUT="$(to_win "$TESTOUTPUT")"

echo "  host TESTDEPLOY : $TESTDEPLOY"
echo "  host TESTOUTPUT : $TESTOUTPUT"
echo "  win  TESTDEPLOY : $WIN_DEPLOY"
echo "  win  TESTOUTPUT : $WIN_OUTPUT"
echo "  docker -v mounts:"
echo "    -v \"$WIN_DEPLOY:/app/deployment\""
echo "    -v \"$WIN_OUTPUT:/app/output\""

# run: εφαρμογή (native entrypoint) πάνω στα αντίγραφα
run() {
  docker run --rm -v "$WIN_DEPLOY:/app/deployment" -v "$WIN_OUTPUT:/app/output" "$IMAGE" "$@"
}
# sh_in: shell μέσα στον container (override entrypoint) — για preflight/sentinel
sh_in() {
  docker run --rm --entrypoint /bin/sh \
    -v "$WIN_DEPLOY:/app/deployment" -v "$WIN_OUTPUT:/app/output" "$IMAGE" -c "$1"
}
count() { if [ -f "$LEDGER" ]; then wc -l < "$LEDGER"; else echo 0; fi; }

# ── 2/9 PREFLIGHT: ο container ΠΡΕΠΕΙ να βλέπει το ΙΔΙΟ TESTDEPLOY, εγγράψιμο ──
echo; echo "═ 2/9 PREFLIGHT μέσα στον container (id/pwd/ls/test/touch)"
PRE="$(sh_in '
  echo "id: $(id)"
  echo "pwd: $(pwd)"
  ls -ld /app/deployment /app/deployment/state /app/deployment/self 2>&1
  test -f /app/deployment/LAWMAX-ARCHITECTURE-CONSTITUTION.sexp && echo "constitution: OK" || echo "constitution: MISSING"
  test -f /app/deployment/state/failure-ledger.jsonl && echo "ledger-file: PRESENT" || echo "ledger-file: absent(θα δημιουργηθεί)"
  touch /app/deployment/state/.write-test && echo "write state: OK" || echo "write state: FAIL"
  touch /app/deployment/self/.write-test  && echo "write self: OK"  || echo "write self: FAIL"
' 2>&1)" || true
printf '%s\n' "$PRE"

PRE_OK=1
printf '%s' "$PRE" | grep -q "constitution: OK"   || { bad "preflight: Σύνταγμα δεν φαίνεται στο mount"; PRE_OK=0; }
printf '%s' "$PRE" | grep -q "write state: OK"     || { bad "preflight: state ΜΗ εγγράψιμο"; PRE_OK=0; }
printf '%s' "$PRE" | grep -q "write self: OK"      || { bad "preflight: self ΜΗ εγγράψιμο"; PRE_OK=0; }

# ── 3/9 SENTINEL: αμφίδρομη ταυτότητα host ↔ container ──
echo; echo "═ 3/9 SENTINEL (host→container→host)"
STAMP="$$-$(count)-${RANDOM:-x}"
printf 'host-sentinel-%s\n' "$STAMP" > "$TESTDEPLOY/state/.host-sentinel"
SEEN="$(sh_in 'cat /app/deployment/state/.host-sentinel 2>/dev/null; echo "container-sentinel-'"$STAMP"'" > /app/deployment/state/.container-sentinel 2>/dev/null && echo WROTE || echo NOWRITE' 2>&1)" || true
printf '  container είδε: %s\n' "$(printf '%s' "$SEEN" | head -1)"
if printf '%s' "$SEEN" | grep -q "host-sentinel-$STAMP"; then ok "sentinel: ο container ΔΙΑΒΑΣΕ το host αρχείο"; else bad "sentinel: ο container ΔΕΝ διάβασε το host αρχείο"; PRE_OK=0; fi
if [ -f "$TESTDEPLOY/state/.container-sentinel" ] && grep -q "container-sentinel-$STAMP" "$TESTDEPLOY/state/.container-sentinel"; then
  ok "sentinel: ο host ΔΙΑΒΑΣΕ το container αρχείο (αμφίδρομο mount)"
else bad "sentinel: ο host ΔΕΝ διάβασε το container αρχείο"; PRE_OK=0; fi
rm -f "$TESTDEPLOY/state/.host-sentinel" "$TESTDEPLOY/state/.container-sentinel" "$TESTDEPLOY/state/.write-test" "$TESTDEPLOY/self/.write-test" 2>/dev/null || true

if [ "$PRE_OK" != "1" ]; then
  echo; echo "═══ PREFLIGHT ΑΠΕΤΥΧΕ — ΣΤΑΜΑΤΩ. Κανένα --ask, κανένα gate πάνω σε σπασμένο mount. ═══"
  echo "═══ ΑΠΟΤΕΛΕΣΜΑ: PASS=$PASS FAIL=$FAIL (preflight) ═══"
  exit 1
fi

# ── snapshot παραγωγής (αποδεικνύουμε ότι δεν αγγίχτηκε) ──
PROD_DEP_BEFORE="$(find "$D/deployment" -type f 2>/dev/null | wc -l)"
PROD_OUT_BEFORE="$(find "$D/output" -type f 2>/dev/null | wc -l)"

B0="$(count)"
echo; echo "═ 4/9 Ledger ΠΡΙΝ: $B0 εγγραφές"

LASTFID=""; LASTQ=""; i=0
for q in "$@"; do
  i=$((i+1))
  echo; echo "═ 5/9 BLIND #$i: «$q»"
  OUT="$(run --ask "$q")" || true
  printf '%s\n' "$OUT"
  FID="$(printf '%s\n' "$OUT" | sed -n 's/^failure_id: \(fail:[0-9a-f]*\).*/\1/p' | head -1)"
  GID="$(printf '%s\n' "$OUT" | sed -n 's/^gap_id: \(gap:[^ ]*\).*/\1/p' | head -1)"
  if [ -n "$FID" ]; then ok "#$i failure_id στο envelope: $FID"; else bad "#$i ΧΩΡΙΣ failure_id"; fi
  # P0 invariant: memory_recorded:true ΜΟΝΟ αν όντως γράφτηκε+ξαναδιαβάστηκε
  if printf '%s' "$OUT" | grep -q "memory_recorded: true"; then ok "#$i memory_recorded: true"; else bad "#$i memory_recorded ΟΧΙ true (δες failure_record_reason)"; fi
  if [ -n "$FID" ] && grep -q "$FID" "$LEDGER" 2>/dev/null; then
    ok "#$i ο $FID ΥΠΑΡΧΕΙ στον host ledger (read-back)"
    LINE="$(grep "$FID" "$LEDGER" | tail -1)"
    if [ -n "$GID" ] && printf '%s' "$LINE" | grep -q "$GID"; then ok "#$i gap_id ταυτίζεται ($GID)"; else bad "#$i gap_id ΔΕΝ ταυτίζεται"; fi
    if printf '%s' "$LINE" | grep -q '"status":"open"'; then ok "#$i status: open"; else bad "#$i χωρίς status open"; fi
    LASTFID="$FID"; LASTQ="$q"
  else
    bad "#$i το failure_id ΔΕΝ βρέθηκε στον host ledger"
  fi
done

B1="$(count)"
echo
if [ "$B1" -eq "$((B0 + $#))" ]; then ok "count: $B0 → $B1 (+$#)"; else bad "count: $B0 → $B1 (αναμενόταν +$#)"; fi

echo; echo "═ 6/9 RECALL: «δείξε μου τι κατέγραψες»"
ROUT="$(run --ask "δείξε μου τι κατέγραψες")" || true
printf '%s\n' "$ROUT"
if [ -n "$LASTFID" ] && printf '%s' "$ROUT" | grep -q "$LASTFID"; then ok "recall: δείχνει $LASTFID"; else bad "recall: δεν δείχνει το τελευταίο failure_id"; fi
if [ -n "$LASTQ" ] && printf '%s' "$ROUT" | grep -qF "$LASTQ"; then ok "recall: δείχνει το input"; else bad "recall: δεν δείχνει το input"; fi
for fld in produced_mode wrong_behavior created_gap status; do
  if printf '%s' "$ROUT" | grep -q "$fld"; then ok "recall: πεδίο $fld"; else bad "recall: λείπει $fld"; fi
done

echo; echo "═ 7/9 NEGATIVE: «ποιος είσαι;» δεν πρέπει να γράψει"
B2="$(count)"; run --ask "ποιος είσαι;" > /dev/null || true; B3="$(count)"
if [ "$B2" -eq "$B3" ]; then ok "negative: $B2 → $B3 (καμία νέα εγγραφή)"; else bad "negative: $B2 → $B3 (γράφτηκε!)"; fi

echo; echo "═ 8/9 DUPLICATE-LEDGER CHECK (find με παρενθέσεις)"
FOUND="$(find "$TESTDEPLOY/self" "$TESTDEPLOY/state" \( -name "*failure*" -o -name "*ledger*" \) -print)"
printf '%s\n' "$FOUND"
if [ "$FOUND" = "$LEDGER" ]; then ok "ένας και μόνο ledger: $LEDGER"; else bad "επιπλέον ledger-like αρχεία"; fi

# ── παραγωγή άθικτη ──
PROD_DEP_AFTER="$(find "$D/deployment" -type f 2>/dev/null | wc -l)"
PROD_OUT_AFTER="$(find "$D/output" -type f 2>/dev/null | wc -l)"
echo; echo "═ παραγωγή: deployment $PROD_DEP_BEFORE→$PROD_DEP_AFTER · output $PROD_OUT_BEFORE→$PROD_OUT_AFTER"
if [ "$PROD_DEP_BEFORE" = "$PROD_DEP_AFTER" ] && [ "$PROD_OUT_BEFORE" = "$PROD_OUT_AFTER" ]; then ok "PROD-UNTOUCHED (ίδιο πλήθος αρχείων)"; else bad "PROD ΑΛΛΑΞΕ — έλεγξε"; fi

if [ "${SKIP_GATES:-0}" != "1" ]; then
  echo; echo "═ 9/9 TARGETED GATES (κατά σειρά)"
  run --understanding-gate             && ok "--understanding-gate"             || bad "--understanding-gate"
  run --architecture-constitution-gate && ok "--architecture-constitution-gate" || bad "--architecture-constitution-gate"
  run --gates                          && ok "--gates (ολομέλεια)"              || bad "--gates"
else
  echo; echo "═ 9/9 GATES: ΠΑΡΑΛΕΙΦΘΗΚΑΝ (SKIP_GATES=1)"
fi

echo; echo "═══ ΑΠΟΤΕΛΕΣΜΑ: PASS=$PASS FAIL=$FAIL ═══"
[ "$FAIL" -eq 0 ]
