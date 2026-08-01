#!/usr/bin/env bash
# =============================================================================
# ΜΙΑ ΕΝΤΟΛΗ — ΟΛΕΣ ΟΙ ΑΠΟΔΕΙΞΕΙΣ (proofs + Lisp suites + ΠΡΑΓΜΑΤΙΚΟ Docker E2E)
# =============================================================================
#   sudo bash authority-v2/run-all.sh
#
# ΤΙ ΤΡΕΧΕΙ, ΜΕ ΑΥΤΗ ΤΗ ΣΕΙΡΑ:
#   ① authority-v2/run-proofs.sh   — ΟΛΕΣ οι απογεγραμμένες αποδείξεις
#   ② οι τρεις Lisp σουίτες        — level7-disarm / release-authority / tlog
#   ③ Docker E2E                    — ΜΟΝΟ αν υπάρχει ΤΡΕΧΩΝ daemon
#
# ΚΩΔΙΚΟΙ ΕΞΟΔΟΥ (καμία ψευδο-επιτυχία):
#   0 = ΟΛΑ εκτελέστηκαν ΚΑΙ πέρασαν
#   1 = ΚΑΠΟΙΑ ΑΠΕΤΥΧΕ
#   3 = ΟΛΑ όσα έτρεξαν πέρασαν, ΑΛΛΑ κάτι ΔΕΝ ΕΚΤΕΛΕΣΤΗΚΕ (BLOCKED)
#
# ΑΠΑΙΤΗΣΕΙΣ ΓΙΑ ΠΛΗΡΗ ΕΚΤΕΛΕΣΗ: root (mount/setpriv/unshare), sbcl, python3
# με PyYAML, και ΤΡΕΧΩΝ docker daemon. Ό,τι λείπει δηλώνεται BLOCKED ΟΝΟΜΑΣΤΙΚΑ.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"
BLOCKED=(); FAILED=(); PASSED=()

hr(){ printf '\n%s\n' "═══════════════════════════════════════════════════════════════════"; }
run(){                                   # run <ετικέτα> <εντολή...>
  local label="$1"; shift
  hr; echo "▶ $label"; hr
  "$@"; local rc=$?
  case "$rc" in
    0) PASSED+=("$label"); echo "  ✓ $label";;
    2|3) BLOCKED+=("$label (exit $rc)"); echo "  ⊘ $label — BLOCKED/ΑΤΕΛΕΣ (exit $rc)";;
    *) FAILED+=("$label (exit $rc)"); echo "  ✗ $label — ΑΠΕΤΥΧΕ (exit $rc)";;
  esac
  return 0
}

echo "ΠΕΡΙΒΑΛΛΟΝ: uid=$(id -u) · sbcl=$(command -v sbcl || echo ΑΠΩΝ) · docker daemon=$(docker info >/dev/null 2>&1 && echo ΝΑΙ || echo ΟΧΙ)"

# ── ① ΟΛΕΣ ΟΙ ΑΠΟΓΕΓΡΑΜΜΕΝΕΣ ΑΠΟΔΕΙΞΕΙΣ ────────────────────────────────────
run "authority-v2 proofs (απογραφή + ΟΛΕΣ οι αποδείξεις)" \
    bash "$REPO/authority-v2/run-proofs.sh"

# ── ② ΟΙ LISP ΣΟΥΙΤΕΣ (ΕΝΑ core, χτισμένο ΜΙΑ φορά) ────────────────────────
if command -v sbcl >/dev/null 2>&1; then
  CORE="$(mktemp -d)/authority-cli.core"
  echo; echo "▶ χτίσιμο SBCL core (μία φορά)…"
  if LAWMAX_REPO="$REPO" sbcl --script "$REPO/authority-v2/tests/build-authority-core.lisp" "$CORE" >/tmp/core-build.$$.log 2>&1 && [ -s "$CORE" ]; then
    for t in tests/level7-disarm-test.lisp tests/release-authority-test.lisp tests/transparency-log-test.lisp; do
      run "$t" env LAWMAX_REPO="$REPO" sbcl --core "$CORE" --script "$REPO/$t"
    done
  else
    BLOCKED+=("Lisp σουίτες (το core δεν χτίστηκε)"); echo "  ⊘ core δεν χτίστηκε — δες /tmp/core-build.$$.log"
  fi
  rm -rf "$(dirname "$CORE")"
else
  BLOCKED+=("Lisp σουίτες (sbcl ΑΠΩΝ)")
fi

# ── ③ ΤΟ ΠΡΑΓΜΑΤΙΚΟ DOCKER E2E ──────────────────────────────────────────────
run "Docker E2E (αγωγός + υγεία + όριο + candidate workspace)" \
    bash "$REPO/authority-v2/proofs/docker-e2e-test.sh"

# ── ΤΕΛΙΚΟ ΙΣΟΖΥΓΙΟ ─────────────────────────────────────────────────────────
hr
echo "ΣΥΝΟΛΟ: ${#PASSED[@]} πέρασαν · ${#FAILED[@]} απέτυχαν · ${#BLOCKED[@]} ΔΕΝ ΕΚΤΕΛΕΣΤΗΚΑΝ"
[ "${#PASSED[@]}"  -gt 0 ] && printf '  ✓ %s\n' "${PASSED[@]}"
[ "${#FAILED[@]}"  -gt 0 ] && printf '  ✗ %s\n' "${FAILED[@]}"
[ "${#BLOCKED[@]}" -gt 0 ] && printf '  ⊘ %s\n' "${BLOCKED[@]}"
hr
[ "${#FAILED[@]}"  -gt 0 ] && { echo "ΑΠΟΤΕΛΕΣΜΑ: ΑΠΟΤΥΧΙΑ"; exit 1; }
[ "${#BLOCKED[@]}" -gt 0 ] && { echo "ΑΠΟΤΕΛΕΣΜΑ: ΑΤΕΛΕΣ — ό,τι έτρεξε πέρασε, ΑΛΛΑ κάτι ΔΕΝ ΕΚΤΕΛΕΣΤΗΚΕ"; exit 3; }
echo "ΑΠΟΤΕΛΕΣΜΑ: ΟΛΑ ΕΚΤΕΛΕΣΤΗΚΑΝ ΚΑΙ ΠΕΡΑΣΑΝ"; exit 0
