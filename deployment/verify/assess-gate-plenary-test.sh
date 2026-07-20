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

# [re-review CRITICAL] Η σφραγίδα φέρει τον ΑΡΙΘΜΟ N πυλών· ο assessor απαιτεί N ==
# πλήθος γραμμών ετυμηγορίας. Άρα κάθε case δίνει footer με τον ΣΩΣΤΟ N (= gate lines).
footer() { printf '════ ΟΛΟΜΕΛΕΙΑ ΠΥΛΩΝ (%s) ════' "$1"; }

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
L="$(mklog "  --understanding-gate: ΠΕΡΑΣΕ" "  --advisor-gate: ΑΠΕΤΥΧΕ" "$(footer 2)")"
check "ΑΠΟΔΕΚΤΟ: ολοκληρωμένη, μόνο advisor κόκκινο, exit1" 0 "$L" 1

# 2. Ολοκληρωμένη, ΟΛΕΣ πράσινες, docker exit 0.
L="$(mklog "  --understanding-gate: ΠΕΡΑΣΕ" "  --advisor-gate: ΠΕΡΑΣΕ" "$(footer 2)")"
check "ΑΠΟΔΕΚΤΟ: ολοκληρωμένη, όλες πράσινες, exit0" 0 "$L" 0

# ── FALSE-GREEN ΠΟΥ ΠΡΕΠΕΙ ΝΑ ΠΙΑΣΤΟΥΝ ─────────────────────────────────────
# 3. CRASH: το docker κατέρρευσε πριν τη σφραγίδα (tee θα επέστρεφε 0) — exit 3.
L="$(mklog "  --understanding-gate: ΠΕΡΑΣΕ" "Fatal error: heap exhausted")"
check "CRASH χωρίς σφραγίδα, tee-θα-έλεγε-0 (status 0)" 3 "$L" 0
check "CRASH χωρίς σφραγίδα, status 139 (segv)"          3 "$L" 139

# 4. OOM/infra exit ΜΕ σφραγίδα κάπως παρούσα αλλά μη-πυλικό status — exit 4.
L="$(mklog "  --advisor-gate: ΑΠΕΤΥΧΕ" "$(footer 1)")"
check "μη-πυλικό docker exit 137 (OOM)" 4 "$L" 137
check "μη-πυλικό docker exit 125 (docker error)" 4 "$L" 125

# 5. Μη-advisor πύλη κόκκινη (ολοκληρωμένη, exit1) — exit 5.
L="$(mklog "  --understanding-gate: ΑΠΕΤΥΧΕ" "  --advisor-gate: ΑΠΕΤΥΧΕ" "$(footer 2)")"
check "μη-advisor πύλη κόκκινη ⇒ απόρριψη" 5 "$L" 1

# 6. ΑΝΤΙΦΑΣΗ: docker exit 0 αλλά κόκκινη πύλη στο log — exit 6.
L="$(mklog "  --advisor-gate: ΑΠΕΤΥΧΕ" "$(footer 1)")"
check "ΑΝΤΙΦΑΣΗ exit0-με-κόκκινο" 6 "$L" 0

# 7. ΑΝΤΙΦΑΣΗ: docker exit 1 αλλά καμία κόκκινη — exit 6.
L="$(mklog "  --advisor-gate: ΠΕΡΑΣΕ" "$(footer 1)")"
check "ΑΝΤΙΦΑΣΗ exit1-χωρίς-κόκκινο" 6 "$L" 1

# 8. Κακή χρήση: λείπει status — exit 2· ανύπαρκτο log — exit 2.
check "κακή χρήση: ανύπαρκτο log" 2 "$tmp/nope.txt" 1
bash "$assess" "" "" >/dev/null 2>&1; [ $? = 2 ] && { echo "  ok   κακή χρήση: κενά ορίσματα (exit 2)"; pass=$((pass+1)); } || { echo "  FAIL κενά ορίσματα"; fail=$((fail+1)); }

# 9. Custom exception set: understanding-gate δηλωμένο εξαιρεμένο ⇒ αποδεκτό.
L="$(mklog "  --understanding-gate: ΑΠΕΤΥΧΕ" "$(footer 1)")"
check "custom baseline exception (understanding-gate)" 0 "$L" 1 "understanding-gate"

# ── SUBSTRING-EXEMPTION (C-1c): η εξαίρεση ΠΡΕΠΕΙ να είναι ΑΚΡΙΒΗΣ, όχι substring ──
# 10. Πύλη «--meta-advisor-gate» ΠΕΡΙΕΧΕΙ το «advisor-gate» ως substring· με το παλιό
#     grep -v θα εξαιρούνταν λαθεμένα ⇒ false-green. ΤΩΡΑ πρέπει να απορρίπτεται (exit 5).
L="$(mklog "  --meta-advisor-gate: ΑΠΕΤΥΧΕ" "$(footer 1)")"
check "substring-όχι-exact: --meta-advisor-gate ΔΕΝ εξαιρείται από advisor-gate" 5 "$L" 1 "advisor-gate"

# 12. Κανονικοποίηση «--»: εξαίρεση δοσμένη ΜΕ dashes («--advisor-gate») ταιριάζει
#     ΑΚΡΙΒΩΣ το τυπωμένο «--advisor-gate» ⇒ αποδεκτό.
L="$(mklog "  --advisor-gate: ΑΠΕΤΥΧΕ" "$(footer 1)")"
check "normalize «--»: εξαίρεση με dashes ταιριάζει exact" 0 "$L" 1 "--advisor-gate"

# 13. Ακριβής εξαίρεση με ΔΥΟ ονόματα: μόνο τα δηλωμένα, όχι superstrings.
L="$(mklog "  --advisor-gate: ΑΠΕΤΥΧΕ" "  --meta-advisor-gate: ΑΠΕΤΥΧΕ" "$(footer 2)")"
check "δύο εξαιρέσεις: το exact-δηλωμένο superstring απορρίπτεται" 5 "$L" 1 "advisor-gate understanding-gate"

# ── [re-review CRITICAL/HIGH] ZERO-GATE + FOOTER-SPOOF + COUNT-MISMATCH ──────
# 14. ZERO-gate ολομέλεια «(0)»: έτρεξε ΚΑΜΙΑ πύλη ⇒ ΑΠΟΡΡΙΨΗ (exit 3), όχι false-green.
L="$(mklog "$(footer 0)")"
check "zero-gate plenary (0) ⇒ ΑΠΟΡΡΙΨΗ (false-green killer)" 3 "$L" 0

# 15. FOOTER SPOOF: το footer εμφανίζεται ΩΣ SUBSTRING σε debug/dialogue γραμμή, ο
#     runner κατέρρευσε μετά (status masked 0). Το anchored regex ΔΕΝ ταιριάζει ⇒ exit 3.
L="$(mklog "  --some-gate: ΠΕΡΑΣΕ" "DEBUG dump: ════ ΟΛΟΜΕΛΕΙΑ ΠΥΛΩΝ (blah) tail" "Fatal error: heap exhausted")"
check "footer-spoof (substring σε debug γραμμή) ⇒ ΑΠΟΡΡΙΨΗ" 3 "$L" 0

# 16. COUNT MISMATCH: footer δηλώνει N=3 αλλά τυπώθηκαν 1 ετυμηγορία (truncated) ⇒ exit 3.
L="$(mklog "  --advisor-gate: ΠΕΡΑΣΕ" "$(footer 3)")"
check "count mismatch (footer N=3, 1 ετυμηγορία) ⇒ ΑΠΟΡΡΙΨΗ" 3 "$L" 0

# 17. FLOOR: με GATE_PLENARY_MIN=5, μια ολομέλεια 2 πυλών ⇒ κάτω από floor (exit 3).
L="$(mklog "  --understanding-gate: ΠΕΡΑΣΕ" "  --advisor-gate: ΠΕΡΑΣΕ" "$(footer 2)")"
GATE_PLENARY_MIN=5 bash "$assess" "$L" 0 >/dev/null 2>&1
[ $? = 3 ] && { echo "  ok   floor GATE_PLENARY_MIN=5, N=2 ⇒ ΑΠΟΡΡΙΨΗ (exit 3)"; pass=$((pass+1)); } \
           || { echo "  FAIL floor check"; fail=$((fail+1)); }

# 18. EXACT EXPECT: silent shrink — όλες πράσινες, ΑΛΛΑ N=2 ≠ GATE_PLENARY_EXPECT=12 ⇒ exit 3.
L="$(mklog "  --understanding-gate: ΠΕΡΑΣΕ" "  --advisor-gate: ΠΕΡΑΣΕ" "$(footer 2)")"
GATE_PLENARY_EXPECT=12 bash "$assess" "$L" 0 >/dev/null 2>&1
[ $? = 3 ] && { echo "  ok   exact-expect 12, N=2 (silent shrink) ⇒ ΑΠΟΡΡΙΨΗ (exit 3)"; pass=$((pass+1)); } \
           || { echo "  FAIL exact-expect shrink"; fail=$((fail+1)); }
# 18b. EXACT EXPECT ικανοποιημένο: N == EXPECT ⇒ αποδεκτό.
GATE_PLENARY_EXPECT=2 bash "$assess" "$L" 0 >/dev/null 2>&1
[ $? = 0 ] && { echo "  ok   exact-expect 2, N=2 ⇒ ΑΠΟΔΕΚΤΟ (exit 0)"; pass=$((pass+1)); } \
           || { echo "  FAIL exact-expect match"; fail=$((fail+1)); }

printf '\nassess-gate-plenary fixture: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
