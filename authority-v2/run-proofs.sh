#!/usr/bin/env bash
# =============================================================================
# Η ΜΙΑ ΕΔΡΑ ΕΚΤΕΛΕΣΗΣ ΤΩΝ ΑΠΟΔΕΙΞΕΩΝ authority-v2
# =============================================================================
# ΕΤΥΜΗΓΟΡΙΑ ΔΗΜΙΟΥΡΓΟΥ: «Η "πλήρης απογραφή" παραμένει glob-based. Έβαλα
# τεχνητή αποτυχημένη απόδειξη στο authority-v2/other/forgotten-proof.py: ο
# runner την ΑΓΝΟΗΣΕ και επέστρεψε exit 0.»
# ΔΙΟΡΘΩΣΗ: ΕΝΑΣ κατάλογος εισόδων (authority-v2/proofs/) + ΑΝΑΔΡΟΜΙΚΗ σάρωση
# ΟΛΟΥ του authority-v2/ + απαγόρευση αποδείξεων εκτός του καταλόγου εισόδων.
#
# ΚΑΜΙΑ ΠΟΛΙΤΙΚΗ ΣΕ YAML. Η έδρα:
#   ① ΣΑΡΩΝΕΙ ΑΝΑΔΡΟΜΙΚΑ το filesystem, ΔΕΝ γράφει κανείς inventory με το χέρι
#   ② το ΣΥΓΚΡΙΝΕΙ με τη committed απογραφή· απόκλιση προς ΟΠΟΙΑΔΗΠΟΤΕ κατεύθυνση
#      ⇒ ΣΦΑΛΜΑ (ξεχασμένη απόδειξη / νεκρή εγγραφή), ΚΑΙ ελέγχει διπλότυπα και
#      άγνωστους τρόπους (κλειστό σχήμα)
#   ③ τρέχει ΠΡΩΤΑ τα tool-* (προετοιμασία), μετά ΚΑΘΕ απόδειξη, και ΜΕΤΡΑΕΙ
#   ④ ΤΟ BLOCKED ΔΕΝ ΕΙΝΑΙ ΠΟΤΕ PASS. Τοπικά ⇒ exit 3 (ΑΤΕΛΕΣ). Με
#      AUTHORITY_V2_REQUIRE_ALL=1 (CI) ⇒ ΣΦΑΛΜΑ.
#
#   authority-v2/run-proofs.sh [--census FILE] [--root DIR]
# Έξοδοι: 0 = όλα εκτελέστηκαν και πέρασαν· 1 = αποτυχία· 3 = ατελές (blocked).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
CENSUS="$HERE/PROOF-CENSUS.txt"
REQUIRE_ALL="${AUTHORITY_V2_REQUIRE_ALL:-0}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --census) CENSUS="$2"; shift 2;;
    --root)   ROOT="$(cd "$2" && pwd)"; shift 2;;
    *) echo "::error::άγνωστο όρισμα $1"; exit 1;;
  esac
done
[ -f "$CENSUS" ] || { echo "::error::ΑΠΟΓΡΑΦΗ ΑΠΟΥΣΑ: $CENSUS"; exit 1; }

# ── ① ΑΝΑΔΡΟΜΙΚΗ ΑΠΑΡΙΘΜΗΣΗ, ΟΧΙ GLOBS ──────────────────────────────────────
# ΕΤΥΜΗΓΟΡΙΑ ΔΗΜΙΟΥΡΓΟΥ: αποτυχημένη απόδειξη στο authority-v2/other/ ΑΓΝΟΗΘΗΚΕ
# επειδή τα globs κοιτούσαν μόνο συγκεκριμένους καταλόγους. Τώρα απαριθμείται
# ΚΑΘΕ regular file κάτω από το authority-v2/ και ισχύουν ΔΥΟ κανόνες:
#   (α) ό,τι είναι ΜΕΣΑ στο proofs/ ΕΙΝΑΙ απόδειξη και ΠΡΕΠΕΙ να απογράφεται
#   (β) ΚΑΝΕΝΑ εκτελέσιμο απόδειξης ΕΚΤΟΣ του proofs/ — εκτός αν δηλώνεται ρητά
#       ως tool-* στην απογραφή, με λόγο
PROOFS_DIR="authority-v2/proofs"
mapfile -t all_files < <(cd "$ROOT" && find authority-v2 -type f | LC_ALL=C sort)
[ "${#all_files[@]}" -gt 0 ] || { echo "::error::ΚΕΝΟ authority-v2 — καμία ψευδο-επιτυχία"; exit 1; }

in_proofs=(); outside_exec=()
for f in "${all_files[@]}"; do
  case "$f" in
    "$PROOFS_DIR"/*)
      rest="${f#$PROOFS_DIR/}"
      case "$rest" in
        */*) echo "::error::ΥΠΟΚΑΤΑΛΟΓΟΣ ΣΤΟ proofs/: $f — ο κατάλογος εισόδων είναι ΕΠΙΠΕΔΟΣ"; exit 1;;
      esac
      in_proofs+=("$f");;
    *)
      case "$f" in
        *-test.py|*-test.sh|*-witness.py|*-witness.sh|*-fixtures.py|*-bundle.sh|*/verify-*.py|*/verify-*.sh)
          outside_exec+=("$f");;
        *.py|*.sh) [ -x "$ROOT/$f" ] && outside_exec+=("$f");;
      esac;;
  esac
done

# ── ② σύγκριση με τη committed απογραφή (κλειστό σχήμα) ──────────────────────
declare -A MODE=() ARGS=()
census=(); order=()
lineno=0
while IFS= read -r line || [ -n "$line" ]; do
  lineno=$((lineno+1))
  line="${line%%#*}"
  # shellcheck disable=SC2086
  set -- $line
  [ "$#" -eq 0 ] && continue
  [ "$#" -ge 2 ] || { echo "::error::ΚΑΚΟΣΧΗΜΑΤΗ γραμμή $lineno: '$line'"; exit 1; }
  path="$1"; mode="$2"; shift 2
  case "$mode" in
    plain|requires-root|requires-sbcl|tool-requires-root|tool-declared) ;;
    *) echo "::error::ΑΓΝΩΣΤΟΣ τρόπος '$mode' (γραμμή $lineno· κλειστό σχήμα)"; exit 1;;
  esac
  if [ -n "${MODE[$path]:-}" ]; then
    echo "::error::ΔΙΠΛΟΤΥΠΗ ΕΓΓΡΑΦΗ '$path' (γραμμή $lineno)"; exit 1
  fi
  MODE["$path"]="$mode"; ARGS["$path"]="$*"
  census+=("$path"); order+=("$path")
done < "$CENSUS"

missing=(); dead=(); stray=()
for f in "${in_proofs[@]}"; do [ -n "${MODE[$f]:-}" ] || missing+=("$f"); done
for f in "${census[@]}";    do [ -f "$ROOT/$f" ]      || dead+=("$f"); done
for f in "${outside_exec[@]:-}"; do
  [ -n "$f" ] || continue
  case "${MODE[$f]:-}" in tool-*) ;; *) stray+=("$f");; esac
done
if [ "${#missing[@]}" -gt 0 ] || [ "${#dead[@]}" -gt 0 ] || [ "${#stray[@]}" -gt 0 ]; then
  [ "${#missing[@]}" -gt 0 ] && echo "::error::ΞΕΧΑΣΜΕΝΕΣ ΑΠΟΔΕΙΞΕΙΣ (στο proofs/, εκτός απογραφής): ${missing[*]}"
  [ "${#dead[@]}" -gt 0 ]    && echo "::error::ΝΕΚΡΕΣ ΕΓΓΡΑΦΕΣ (στην απογραφή, ανύπαρκτες): ${dead[*]}"
  [ "${#stray[@]}" -gt 0 ]   && echo "::error::ΑΠΟΔΕΙΞΗ ΕΚΤΟΣ ΤΟΥ ΚΑΤΑΛΟΓΟΥ ΕΙΣΟΔΩΝ (authority-v2/proofs/): ${stray[*]}"
  exit 1
fi
for f in "${census[@]}"; do
  case "${MODE[$f]}" in tool-*) continue;; esac
  case "$f" in
    "$PROOFS_DIR"/*) ;;
    *) echo "::error::Η ΑΠΟΓΡΑΦΗ δηλώνει απόδειξη ΕΚΤΟΣ proofs/: $f"; exit 1;;
  esac
done
echo "── απογραφή: ${#all_files[@]} αρχεία σαρώθηκαν ΑΝΑΔΡΟΜΙΚΑ· ${#in_proofs[@]} είσοδοι στο proofs/ ≡ committed ──"
echo

# ── ③ εκτέλεση: ΠΡΩΤΑ τα setup, μετά οι αποδείξεις ───────────────────────────
pass=0; fail=0; blocked=0; setup_ok=1
declare -a FAILED=() BLOCKED=()

exec_entry() {                     # $1 = repo-relative path
  local f="$1" args="${ARGS[$1]}" rc
  # shellcheck disable=SC2086
  case "$f" in
    *.py) LAWMAX_REPO="$ROOT" python3 "$ROOT/$f" $args ;;
    *.sh) LAWMAX_REPO="$ROOT" bash    "$ROOT/$f" $args ;;
    *)    echo "::error::μη εκτελέσιμος τύπος: $f"; return 1;;
  esac
  rc=$?
  return $rc
}

for f in "${order[@]}"; do
  [ "${MODE[$f]}" = "tool-requires-root" ] || continue
  echo "▶ [setup] $f"
  if [ "$(id -u)" -ne 0 ]; then
    setup_ok=0; echo "  ⊘ BLOCKED — απαιτείται root για την προετοιμασία"
  elif exec_entry "$f" >/dev/null 2>&1; then
    echo "  ✓ προετοιμασία ΟΚ"
  else
    setup_ok=0; fail=$((fail+1)); FAILED+=("$f (setup απέτυχε)")
    echo "  ✗ Η ΠΡΟΕΤΟΙΜΑΣΙΑ ΑΠΕΤΥΧΕ"
  fi
  echo
done

for f in "${order[@]}"; do
  mode="${MODE[$f]}"
  case "$mode" in tool-*) continue;; esac
  echo "▶ $f  [$mode]"
  if [ "$mode" = "requires-root" ] && [ "$setup_ok" -ne 1 ]; then
    if [ "$REQUIRE_ALL" = "1" ]; then
      fail=$((fail+1)); FAILED+=("$f (η προετοιμασία root δεν έγινε)")
      echo "  ✗ ΣΦΑΛΜΑ: απαιτείται πλήρης εκτέλεση αλλά λείπει η προετοιμασία"
    else
      blocked=$((blocked+1)); BLOCKED+=("$f"); echo "  ⊘ BLOCKED (ΔΕΝ δηλώνεται pass)"
    fi
    echo; continue
  fi
  exec_entry "$f"; rc=$?
  case "$rc" in
    0) pass=$((pass+1)); echo "  ✓ PASSED";;
    2) if [ "$REQUIRE_ALL" = "1" ]; then
         fail=$((fail+1)); FAILED+=("$f (BLOCKED ενώ απαιτείται πλήρης εκτέλεση)")
         echo "  ✗ ΣΦΑΛΜΑ: BLOCKED με AUTHORITY_V2_REQUIRE_ALL=1 — απώλεια δυνατότητας"
       else
         blocked=$((blocked+1)); BLOCKED+=("$f"); echo "  ⊘ BLOCKED (ΔΕΝ δηλώνεται pass)"
       fi;;
    *) fail=$((fail+1)); FAILED+=("$f (exit $rc)"); echo "  ✗ FAILED (exit $rc)";;
  esac
  echo
done

total=$((pass+fail+blocked))
echo "═══════════════════════════════════════════════════════════════════"
echo "authority-v2 proofs: $pass passed, $fail failed, $blocked blocked (από $total αποδείξεις)"
[ "${#FAILED[@]}"  -gt 0 ] && printf '  ✗ %s\n' "${FAILED[@]}"
[ "${#BLOCKED[@]}" -gt 0 ] && printf '  ⊘ %s\n' "${BLOCKED[@]}"
echo "═══════════════════════════════════════════════════════════════════"

[ "$fail" -gt 0 ] && exit 1
[ "$blocked" -gt 0 ] && exit 3
exit 0
