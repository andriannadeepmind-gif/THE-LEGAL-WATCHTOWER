#!/usr/bin/env bash
# =============================================================================
# Η ΜΙΑ ΕΔΡΑ ΕΚΤΕΛΕΣΗΣ ΤΩΝ STANDALONE SUITES ([audit#2])
# =============================================================================
# ΓΙΑΤΙ: το proof manifest παραγόταν από ΧΕΙΡΟΓΡΑΦΗ λίστα σουιτών στο Dockerfile —
# ο κριτής βρήκε 4 κρίσιμες σουίτες εκτός· ο πλήρης έλεγχος βρήκε 7 (safe-read,
# review-queue-safe-read, param-type-coercion, audit-signature-failclosed,
# auto-update-verdict, json-escape-seat, version-chain-tc2). Signed proof ΧΩΡΙΣ
# αυτά = ψευδής εγγύηση.
#
# ΛΥΣΗ (θάνατος κλάσης, όχι μπάλωμα): το suite inventory ΠΑΡΑΓΕΤΑΙ από το
# filesystem (glob tests/*-test.lisp) μείον τη ΜΙΑ δηλωμένη πηγή εξαιρέσεων
# (standalone-suite-exclusions.txt, κοινή με το verify-proof-manifest.py). Καμία
# νέα σουίτα δεν μπορεί να ξεχαστεί — μπαίνει αυτόματα ή δηλώνεται ρητά εξαίρεση.
#
# FAIL-CLOSED: pipefail ⇒ ${PIPESTATUS[0]} = ΠΡΑΓΜΑΤΙΚΟ exit του sbcl (όχι του
# tee)· ΟΠΟΙΑΔΗΠΟΤΕ σουίτα ≠0 (fail/crash) ⇒ το script βγαίνει ≠0. Κενό inventory
# ⇒ σφάλμα (καμία «πέρασαν 0 σουίτες» ψευδο-επιτυχία).
#
# ΣΥΜΒΟΛΑΙΟ:  run-standalone-suites.sh <tests-dir> <proof-dir> <runner.lisp> <exclusions-file>
#   Interpreter: env SBCL (default «sbcl») — παραμετρικό ΓΙΑ testability (fake sbcl στο PATH).
#   Γράφει: <proof-dir>/suites-run.txt (μία γραμμή ανά εκτελεσμένη σουίτα) και
#           <proof-dir>/logs/<suite>.log (stdout+stderr). Ίδια artifacts με πριν
#           (τα καταναλώνει ο manifest generator + verify-proof-manifest.py).
set -euo pipefail

TESTS_DIR="${1:?usage: $0 <tests-dir> <proof-dir> <runner.lisp> <exclusions-file>}"
PROOF_DIR="${2:?proof-dir}"
RUNNER="${3:?runner.lisp}"
EXCL_FILE="${4:?exclusions-file}"
SBCL="${SBCL:-sbcl}"

[ -d "$TESTS_DIR" ] || { echo "::error::tests-dir '$TESTS_DIR' ανύπαρκτο"; exit 2; }
[ -f "$RUNNER" ]    || { echo "::error::runner '$RUNNER' ανύπαρκτο"; exit 2; }
[ -f "$EXCL_FILE" ] || { echo "::error::exclusions-file '$EXCL_FILE' ανύπαρκτο"; exit 2; }

mkdir -p "$PROOF_DIR/logs"
: > "$PROOF_DIR/suites-run.txt"

# Δηλωμένες εξαιρέσεις (αγνόησε σχόλια/κενές γραμμές· κράτα το 1ο token).
excl=()
while IFS= read -r line; do
  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"   # ltrim
  # nonsuite:-δηλώσεις (full-filename μη-harness αρχεία) ΔΕΝ είναι suite basenames —
  # τα ταξινομεί/επιβάλλει ο verify-proof-manifest.py (totality). Εδώ αγνοούνται.
  case "$line" in nonsuite:*) continue ;; esac
  line="${line//[[:space:]]/}"
  [ -n "$line" ] && excl+=("$line")
done < "$EXCL_FILE"
is_excluded() { local s="$1" e; for e in "${excl[@]:-}"; do [ "$s" = "$e" ] && return 0; done; return 1; }

shopt -s nullglob
suites=("$TESTS_DIR"/*-test.lisp)
if [ "${#suites[@]}" -eq 0 ]; then
  echo "::error::ΚΕΝΟ inventory: καμία $TESTS_DIR/*-test.lisp (καμία ψευδο-επιτυχία)"; exit 1
fi

# Σύνολο ονομάτων σουιτών (basenames) — για validation των εξαιρέσεων.
suite_names=()
for f in "${suites[@]}"; do suite_names+=("$(basename "$f" -test.lisp)"); done
name_exists() { local s="$1" n; for n in "${suite_names[@]}"; do [ "$s" = "$n" ] && return 0; done; return 1; }

# (C-2b) ΚΑΘΕ δηλωμένη suite-εξαίρεση ΠΡΕΠΕΙ να αντιστοιχεί σε ΥΠΑΡΚΤΗ σουίτα —
# stale/typo εξαίρεση = σιωπηλά ανενεργή (και μελλοντικά μασκάρει πραγματική σουίτα).
# Fail-closed: αδικαιολόγητη εξαίρεση ⇒ σφάλμα (η εξαίρεση οφείλει να είναι τίμια).
stale_excl=()
for e in "${excl[@]:-}"; do
  [ -n "$e" ] || continue
  name_exists "$e" || stale_excl+=("$e")
done
if [ "${#stale_excl[@]}" -gt 0 ]; then
  echo "::error::stale/typo suite-εξαίρεση (δεν αντιστοιχεί σε tests/*-test.lisp): ${stale_excl[*]}"; exit 1
fi

ran=0; skipped=0; failed=0
for f in "${suites[@]}"; do
  t="$(basename "$f" -test.lisp)"
  if is_excluded "$t"; then
    echo "=== SKIP (δηλωμένη εξαίρεση): $t ==="; skipped=$((skipped+1)); continue
  fi
  echo "=== running $t-test.lisp ==="
  echo "$t" >> "$PROOF_DIR/suites-run.txt"
  set +e
  "$SBCL" --script "$RUNNER" "$f" 2>&1 | tee "$PROOF_DIR/logs/$t.log"
  rc=${PIPESTATUS[0]}
  set -e
  ran=$((ran+1))
  if [ "$rc" -ne 0 ]; then
    echo "::error::suite '$t' ΑΠΕΤΥΧΕ (exit $rc)"; failed=$((failed+1))
  fi
done

echo "──────── standalone suites: $ran έτρεξαν, $skipped εξαιρέθηκαν, $failed απέτυχαν ────────"
if [ "$failed" -ne 0 ]; then
  echo "::error::$failed σουίτα(ες) απέτυχαν — fail-closed"; exit 1
fi
# (C-2d) ΚΑΜΙΑ σουίτα δεν εκτελέστηκε (όλες εξαιρέθηκαν) ⇒ false-green: «0 απέτυχαν»
# ΔΕΝ είναι απόδειξη. Fail-closed — τουλάχιστον μία σουίτα οφείλει να τρέξει ως gate.
if [ "$ran" -eq 0 ]; then
  echo "::error::ΚΑΜΙΑ σουίτα εκτελέστηκε ($skipped εξαιρέθηκαν) — καμία ψευδο-επιτυχία «0 failed»"; exit 1
fi
echo "✓ όλες οι εκτελεσμένες standalone suites πέρασαν."
