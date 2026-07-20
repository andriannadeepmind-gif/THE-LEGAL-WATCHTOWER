#!/usr/bin/env bash
# =============================================================================
# ΑΡΝΗΤΙΚΟ FIXTURE για την έδρα κρίσης ολομέλειας ([audit#1])
# =============================================================================
# Κλειδώνει ΚΑΘΕ κλάδο του συμβολαίου exit code του assess-gate-plenary.sh, με
# έμφαση στα false-green σενάρια που ο κριτής εντόπισε: crash χωρίς σφραγίδα,
# OOM/segv exit, μη-advisor κόκκινη πύλη, και ΑΝΤΙΦΑΣΗ exit0-με-κόκκινο.
# Καμία εξάρτηση από docker/SBCL — καθαρή δοκιμή της ΛΟΓΙΚΗΣ ΚΡΙΣΗΣ (μία έδρα).
set -u
here="$(cd "$(dirname "$0")" && pwd)"
assess="$here/assess-gate-plenary.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0

FOOTER='════ ΟΛΟΜΕΛΕΙΑ ΠΥΛΩΝ (12) ════'

mklog() { printf '%s\n' "$@" > "$tmp/log.txt"; echo "$tmp/log.txt"; }

# check NAME EXPECTED_EXIT  <log-path> <status> [GATE_BASELINE_EXCEPTIONS]
check() {
  local name="$1" want="$2" log="$3" status="$4" exc="${5:-}"
  local got
  if [ -n "$exc" ]; then
    GATE_BASELINE_EXCEPTIONS="$exc" bash "$assess" "$log" "$status" >/dev/null 2>&1
  else
    bash "$assess" "$log" "$status" >/dev/null 2>&1
  fi
  got=$?
  if [ "$got" = "$want" ]; then
    printf '  ok   %s (exit %s)\n' "$name" "$got"; pass=$((pass+1))
  else
    printf '  FAIL %s: περίμενα exit %s, πήρα %s\n' "$name" "$want" "$got"; fail=$((fail+1))
  fi
}

# ── ΑΠΟΔΕΚΤΑ ────────────────────────────────────────────────────────────────
# 1. Ολοκληρωμένη, μόνο advisor-gate κόκκινο, docker exit 1 (η KNOWN baseline).
L="$(mklog "  --understanding-gate: ΠΕΡΑΣΕ" "  --advisor-gate: ΑΠΕΤΥΧΕ" "$FOOTER")"
check "ΑΠΟΔΕΚΤΟ: ολοκληρωμένη, μόνο advisor κόκκινο, exit1" 0 "$L" 1

# 2. Ολοκληρωμένη, ΟΛΕΣ πράσινες, docker exit 0.
L="$(mklog "  --understanding-gate: ΠΕΡΑΣΕ" "  --advisor-gate: ΠΕΡΑΣΕ" "$FOOTER")"
check "ΑΠΟΔΕΚΤΟ: ολοκληρωμένη, όλες πράσινες, exit0" 0 "$L" 0

# ── FALSE-GREEN ΠΟΥ ΠΡΕΠΕΙ ΝΑ ΠΙΑΣΤΟΥΝ ─────────────────────────────────────
# 3. CRASH: το docker κατέρρευσε πριν τη σφραγίδα (tee θα επέστρεφε 0) — exit 3.
L="$(mklog "  --understanding-gate: ΠΕΡΑΣΕ" "Fatal error: heap exhausted")"
check "CRASH χωρίς σφραγίδα, tee-θα-έλεγε-0 (status 0)" 3 "$L" 0
check "CRASH χωρίς σφραγίδα, status 139 (segv)"          3 "$L" 139

# 4. OOM/infra exit ΜΕ σφραγίδα κάπως παρούσα αλλά μη-πυλικό status — exit 4.
L="$(mklog "  --advisor-gate: ΑΠΕΤΥΧΕ" "$FOOTER")"
check "μη-πυλικό docker exit 137 (OOM)" 4 "$L" 137
check "μη-πυλικό docker exit 125 (docker error)" 4 "$L" 125

# 5. Μη-advisor πύλη κόκκινη (ολοκληρωμένη, exit1) — exit 5.
L="$(mklog "  --understanding-gate: ΑΠΕΤΥΧΕ" "  --advisor-gate: ΑΠΕΤΥΧΕ" "$FOOTER")"
check "μη-advisor πύλη κόκκινη ⇒ απόρριψη" 5 "$L" 1

# 6. ΑΝΤΙΦΑΣΗ: docker exit 0 αλλά κόκκινη πύλη στο log — exit 6.
L="$(mklog "  --advisor-gate: ΑΠΕΤΥΧΕ" "$FOOTER")"
check "ΑΝΤΙΦΑΣΗ exit0-με-κόκκινο" 6 "$L" 0

# 7. ΑΝΤΙΦΑΣΗ: docker exit 1 αλλά καμία κόκκινη — exit 6.
L="$(mklog "  --advisor-gate: ΠΕΡΑΣΕ" "$FOOTER")"
check "ΑΝΤΙΦΑΣΗ exit1-χωρίς-κόκκινο" 6 "$L" 1

# 8. Κακή χρήση: λείπει status — exit 2· ανύπαρκτο log — exit 2.
check "κακή χρήση: ανύπαρκτο log" 2 "$tmp/nope.txt" 1
bash "$assess" "" "" >/dev/null 2>&1; [ $? = 2 ] && { echo "  ok   κακή χρήση: κενά ορίσματα (exit 2)"; pass=$((pass+1)); } || { echo "  FAIL κενά ορίσματα"; fail=$((fail+1)); }

# 9. Custom exception set: understanding-gate δηλωμένο εξαιρεμένο ⇒ αποδεκτό.
L="$(mklog "  --understanding-gate: ΑΠΕΤΥΧΕ" "$FOOTER")"
check "custom baseline exception (understanding-gate)" 0 "$L" 1 "understanding-gate"

printf '\nassess-gate-plenary fixture: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
