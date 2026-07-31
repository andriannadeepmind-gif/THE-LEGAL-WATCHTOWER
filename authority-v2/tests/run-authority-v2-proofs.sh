#!/usr/bin/env bash
# =============================================================================
# Η ΜΙΑ ΕΔΡΑ ΕΚΤΕΛΕΣΗΣ ΤΩΝ ΑΠΟΔΕΙΞΕΩΝ authority-v2 (παραγωγική συρμάτωση)
# =============================================================================
# ΕΥΡΗΜΑ ΔΗΜΙΟΥΡΓΟΥ (P1): «τίποτα δεν είναι συρματωμένο σε Docker/compose/
# workflow· το HEAD έχει μηδέν Actions runs και μηδέν status checks».
#
# Η ΑΝΩΤΑΤΗ ΜΟΡΦΗ ΔΕΝ ΕΙΝΑΙ ΒΗΜΑΤΑ ΣΕ YAML. Το YAML δεν κρίνει τίποτα εδώ:
# καλεί ΑΥΤΗ την έδρα, μία φορά. Η έδρα:
#   ① ΠΑΡΑΓΕΙ το inventory από το filesystem (glob), ΔΕΝ το γράφει κανείς με το χέρι
#   ② το ΣΥΓΚΡΙΝΕΙ με τη committed απογραφή PROOF-CENSUS.txt — απόκλιση προς
#      ΟΠΟΙΑΔΗΠΟΤΕ κατεύθυνση ⇒ ΣΦΑΛΜΑ (ξεχασμένη απόδειξη / νεκρή εγγραφή)
#   ③ τρέχει ΚΑΘΕ εγγραφή και ΜΕΤΡΑΕΙ: passed / failed / blocked
#   ④ ΤΟ BLOCKED ΔΕΝ ΕΙΝΑΙ ΠΟΤΕ PASS. Τοπικά (χωρίς root) δηλώνεται τίμια και ο
#      συνολικός κωδικός είναι 3 = ΑΤΕΛΗΣ. Με AUTHORITY_V2_REQUIRE_ALL=1 (CI,
#      όπου root ΥΠΑΡΧΕΙ) το BLOCKED είναι ΣΦΑΛΜΑ — απώλεια δυνατότητας δεν
#      επιτρέπεται να περνά ως σιωπή.
#
# Έξοδοι: 0 = όλα εκτελέστηκαν και πέρασαν· 1 = αποτυχία· 3 = ατελές (blocked).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
CENSUS="$HERE/PROOF-CENSUS.txt"
REQUIRE_ALL="${AUTHORITY_V2_REQUIRE_ALL:-0}"

[ -f "$CENSUS" ] || { echo "::error::ΑΠΟΓΡΑΦΗ ΑΠΟΥΣΑ: $CENSUS"; exit 1; }

# ── ① inventory ΑΠΟ ΤΟ FILESYSTEM ────────────────────────────────────────────
# Εκτελεστές = *-test.{py,sh} και *-witness.py. Τα probe-*/_*/build-* είναι
# ΒΟΗΘΟΙ (καλούνται ΑΠΟ τις αποδείξεις), ΟΧΙ αυτοτελείς αποδείξεις — και τα
# δύο σύνολα είναι ΞΕΝΑ μεταξύ τους εξ ορισμού του glob.
shopt -s nullglob
disk=()
for f in "$HERE"/*-test.py "$HERE"/*-test.sh "$HERE"/*-witness.py "$HERE"/*-witness.sh \
         "$HERE"/*-fixtures.py "$HERE"/*-bundle.sh; do
  disk+=("$(basename "$f")")
done
IFS=$'\n' disk=($(printf '%s\n' "${disk[@]}" | sort -u)); unset IFS
[ "${#disk[@]}" -gt 0 ] || { echo "::error::ΚΕΝΟ inventory — καμία ψευδο-επιτυχία"; exit 1; }

# ── ② σύγκριση με τη committed απογραφή ──────────────────────────────────────
declare -A MODE=()
census=()
while IFS= read -r line; do
  line="${line%%#*}"
  # shellcheck disable=SC2086
  set -- $line
  [ "$#" -eq 0 ] && continue
  [ "$#" -eq 2 ] || { echo "::error::ΚΑΚΟΣΧΗΜΑΤΗ γραμμή απογραφής: '$line'"; exit 1; }
  case "$2" in plain|requires-root|requires-sbcl) ;; *)
    echo "::error::ΑΓΝΩΣΤΟΣ τρόπος '$2' (κλειστό σχήμα)"; exit 1;; esac
  MODE["$1"]="$2"; census+=("$1")
done < "$CENSUS"
IFS=$'\n' census=($(printf '%s\n' "${census[@]}" | sort -u)); unset IFS

missing=(); dead=()
for f in "${disk[@]}";   do [ -n "${MODE[$f]:-}" ] || missing+=("$f"); done
for f in "${census[@]}"; do [ -f "$HERE/$f" ]      || dead+=("$f"); done
if [ "${#missing[@]}" -gt 0 ] || [ "${#dead[@]}" -gt 0 ]; then
  [ "${#missing[@]}" -gt 0 ] && echo "::error::ΞΕΧΑΣΜΕΝΕΣ ΑΠΟΔΕΙΞΕΙΣ (στον δίσκο, εκτός απογραφής): ${missing[*]}"
  [ "${#dead[@]}" -gt 0 ]    && echo "::error::ΝΕΚΡΕΣ ΕΓΓΡΑΦΕΣ (στην απογραφή, ανύπαρκτες): ${dead[*]}"
  exit 1
fi
echo "── απογραφή authority-v2: ${#census[@]} αποδείξεις, filesystem ≡ committed ──"
echo

# ── ③ εκτέλεση ───────────────────────────────────────────────────────────────
pass=0; fail=0; blocked=0
declare -a FAILED=() BLOCKED=()
for f in "${census[@]}"; do
  mode="${MODE[$f]}"
  echo "▶ $f  [$mode]"
  case "$f" in
    *.py) LAWMAX_REPO="$REPO" python3 "$HERE/$f" ;;
    *.sh) LAWMAX_REPO="$REPO" bash    "$HERE/$f" ;;
  esac
  rc=$?
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

echo "═══════════════════════════════════════════════════════════════════"
echo "authority-v2 proofs: $pass passed, $fail failed, $blocked blocked (από ${#census[@]})"
[ "${#FAILED[@]}"  -gt 0 ] && printf '  ✗ %s\n' "${FAILED[@]}"
[ "${#BLOCKED[@]}" -gt 0 ] && printf '  ⊘ %s\n' "${BLOCKED[@]}"
echo "═══════════════════════════════════════════════════════════════════"

[ "$fail" -gt 0 ] && exit 1
[ "$blocked" -gt 0 ] && exit 3
exit 0
