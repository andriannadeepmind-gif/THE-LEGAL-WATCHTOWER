#!/usr/bin/env bash
# =============================================================================
# ΑΡΝΗΤΙΚΟ FIXTURE για τη ΜΙΑ έδρα εκτέλεσης standalone suites ([audit#2])
# =============================================================================
# Αποδεικνύει ότι η ΠΑΡΑΓΩΓΗ inventory από το filesystem:
#   (α) περιλαμβάνει ΑΥΤΟΜΑΤΑ κάθε νέα tests/*-test.lisp (ο κριτής βρήκε 7 ξεχασμένες)·
#   (β) τιμά τις δηλωμένες εξαιρέσεις (μία πηγή αλήθειας)·
#   (γ) είναι FAIL-CLOSED: μία σουίτα που αποτυγχάνει/καταρρέει ⇒ exit ≠0 (pipefail
#       ⇒ δεν κρύβεται πίσω από το tee)·
#   (δ) κενό inventory ⇒ σφάλμα (καμία ψευδο-επιτυχία).
# Χωρίς πραγματικό SBCL: fake «sbcl» στο PATH που κρίνει από το όνομα του αρχείου.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
runner_seat="$here/run-standalone-suites.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0

# fake sbcl: «--script <runner> <suite.lisp>» ⇒ exit 1 αν το όνομα περιέχει FAIL, αλλιώς 0.
mkdir -p "$tmp/bin"
cat > "$tmp/bin/sbcl" <<'FAKE'
#!/usr/bin/env bash
# argv: --script <runner.lisp> <suite-file>
suite="${3:-}"
echo "fake-sbcl running: $suite"
case "$suite" in
  *FAIL*) echo "  0 passed, 3 failed"; exit 1 ;;
  *)      echo "  5 passed, 0 failed"; exit 0 ;;
esac
FAKE
chmod +x "$tmp/bin/sbcl"

mktests() { local d="$tmp/tests_$1"; mkdir -p "$d"; shift; for n in "$@"; do : > "$d/$n-test.lisp"; done; echo "$d"; }
mkexcl()  { printf '%s\n' "$@" > "$tmp/excl_$RANDOM.txt"; ls -t "$tmp"/excl_*.txt | head -1; }

run_seat() {   # <tests-dir> <exclusions-file>  → sets GOT_RC, populates $tmp/proof
  local td="$1" excl="$2"
  rm -rf "$tmp/proof"; mkdir -p "$tmp/proof"
  SBCL="$tmp/bin/sbcl" PATH="$tmp/bin:$PATH" \
    bash "$runner_seat" "$td" "$tmp/proof" "$tmp/runner.lisp" "$excl" >"$tmp/out.txt" 2>&1
  GOT_RC=$?
}
: > "$tmp/runner.lisp"   # ο runner δεν εκτελείται πραγματικά (fake sbcl τον αγνοεί)

ok() { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
no() { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }

# (α) Νέα σουίτα περιλαμβάνεται ΑΥΤΟΜΑΤΑ + όλες πράσινες ⇒ exit 0.
TD="$(mktests A alpha beta brand-new-suite)"; EX="$(printf '# none\n' > "$tmp/e1"; echo "$tmp/e1")"
run_seat "$TD" "$EX"
{ [ "$GOT_RC" = 0 ] && grep -q "brand-new-suite" "$tmp/proof/suites-run.txt" \
  && [ "$(wc -l < "$tmp/proof/suites-run.txt")" = 3 ]; } \
  && ok "(α) νέα σουίτα auto-included, όλες πράσινες ⇒ exit 0" \
  || no "(α) νέα σουίτα auto-included ($GOT_RC)"

# (β) Δηλωμένη εξαίρεση ΔΕΝ τρέχει.
TD="$(mktests B alpha comparison)"; printf 'comparison\n' > "$tmp/e2"
run_seat "$TD" "$tmp/e2"
{ [ "$GOT_RC" = 0 ] && ! grep -q "comparison" "$tmp/proof/suites-run.txt" \
  && grep -q "alpha" "$tmp/proof/suites-run.txt"; } \
  && ok "(β) δηλωμένη εξαίρεση comparison ΔΕΝ έτρεξε" \
  || no "(β) εξαίρεση comparison ($GOT_RC)"

# (γ) FAIL-CLOSED: μία σουίτα που αποτυγχάνει ⇒ exit ≠0.
TD="$(mktests C alpha this-one-FAIL gamma)"; printf '# none\n' > "$tmp/e3"
run_seat "$TD" "$tmp/e3"
[ "$GOT_RC" != 0 ] && ok "(γ) αποτυχημένη σουίτα ⇒ fail-closed (exit $GOT_RC)" \
                   || no "(γ) αποτυχημένη σουίτα ΔΕΝ πέρασε fail-closed (exit 0!)"

# (γ2) Το false-green σενάριο: sbcl exit 1 πίσω από tee — ΠΡΕΠΕΙ να πιαστεί.
grep -q "ΑΠΕΤΥΧΕ" "$tmp/out.txt" && ok "(γ2) το fail καταγράφηκε ρητά" || no "(γ2) το fail δεν καταγράφηκε"

# (δ) Κενό inventory ⇒ σφάλμα.
TD="$(mktests D)"; printf 'comparison\n' > "$tmp/e4"
run_seat "$TD" "$tmp/e4"
[ "$GOT_RC" != 0 ] && ok "(δ) κενό inventory ⇒ σφάλμα (exit $GOT_RC)" \
                   || no "(δ) κενό inventory ΔΕΝ έβγαλε σφάλμα"

# (ε) Ανύπαρκτο tests-dir / exclusions ⇒ σφάλμα χρήσης.
run_seat "$tmp/nope" "$tmp/e4"; [ "$GOT_RC" != 0 ] && ok "(ε) ανύπαρκτο tests-dir ⇒ σφάλμα" || no "(ε) ανύπαρκτο tests-dir"

# (ζ) C-2b: stale/typo suite-εξαίρεση (δεν αντιστοιχεί σε καμία σουίτα) ⇒ σφάλμα.
TD="$(mktests Z alpha beta)"; printf 'ghost-suite\n' > "$tmp/e5"
run_seat "$TD" "$tmp/e5"
{ [ "$GOT_RC" != 0 ] && grep -q "stale/typo" "$tmp/out.txt"; } \
  && ok "(ζ) C-2b: stale εξαίρεση ⇒ σφάλμα" \
  || no "(ζ) C-2b: stale εξαίρεση ΔΕΝ πιάστηκε ($GOT_RC)"

# (η) C-2d: ΟΛΕΣ οι σουίτες εξαιρεμένες ⇒ ran=0 ⇒ σφάλμα (καμία ψευδο-επιτυχία «0 failed»).
TD="$(mktests H solo)"; printf 'solo\n' > "$tmp/e6"
run_seat "$TD" "$tmp/e6"
{ [ "$GOT_RC" != 0 ] && grep -q "ΚΑΜΙΑ σουίτα εκτελέστηκε" "$tmp/out.txt"; } \
  && ok "(η) C-2d: όλες εξαιρεμένες ⇒ σφάλμα (όχι false-green)" \
  || no "(η) C-2d: all-excluded ΔΕΝ πιάστηκε ($GOT_RC)"

# (θ) Έλεγχος ότι μια ΕΓΚΥΡΗ εξαίρεση (matches suite) + άλλη σουίτα τρέχει ⇒ exit 0.
TD="$(mktests T keeprun comparison)"; printf 'comparison\n' > "$tmp/e7"
run_seat "$TD" "$tmp/e7"
{ [ "$GOT_RC" = 0 ] && grep -q "keeprun" "$tmp/proof/suites-run.txt" \
  && ! grep -q "comparison" "$tmp/proof/suites-run.txt"; } \
  && ok "(θ) έγκυρη εξαίρεση + 1 σουίτα τρέχει ⇒ exit 0" \
  || no "(θ) έγκυρη εξαίρεση ($GOT_RC)"

printf '\nrun-standalone-suites fixture: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
