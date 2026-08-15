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

# ── ① ΑΝΑΔΡΟΜΙΚΗ ΑΠΑΡΙΘΜΗΣΗ + ΤΑΞΙΝΟΜΗΣΗ ΑΚΡΙΒΩΣ ΜΙΑ ΦΟΡΑ ────────────────
# ΕΤΥΜΗΓΟΡΙΑ ΔΗΜΙΟΥΡΓΟΥ: «Το proof census παρακάμπτεται: non-executable .py,
# αυθαίρετα .lisp, symlinks ή proof δηλωμένο ως tool μπορούν να διαφύγουν.»
# ΟΡΘΟ — ο προηγούμενος έλεγχος στηριζόταν σε ΕΥΡΕΤΙΚΑ ΟΝΟΜΑΤΩΝ και στο bit
# εκτέλεσης· και τα δύο είναι επιλογές του συγγραφέα του κακόβουλου αρχείου.
#
# ΤΩΡΑ: ΚΑΘΕ αρχείο κώδικα (.py/.sh/.lisp) κάτω από το authority-v2/
# ΤΑΞΙΝΟΜΕΙΤΑΙ ΑΚΡΙΒΩΣ ΜΙΑ ΦΟΡΑ:
#   · μέσα στο proofs/  ⇒ ΠΡΕΠΕΙ να είναι εγγραφή ΑΠΟΔΕΙΞΗΣ στην απογραφή
#   · εκτός proofs/     ⇒ ΠΡΕΠΕΙ να είναι εγγραφή tool-* ή helper στην απογραφή
#   · οτιδήποτε άλλο    ⇒ ΑΤΑΞΙΝΟΜΗΤΟ ⇒ ΣΦΑΛΜΑ
# Καμία εξάρτηση από όνομα ή +x. Και:
#   · ΚΑΝΕΝΑ symlink κάτω από το authority-v2/ (θα έδειχνε εκτός απογραφής)
#   · ΚΑΜΙΑ ΒΑΠΤΙΣΗ: απόδειξη μέσα στο proofs/ ΔΕΝ δηλώνεται tool/helper
PROOFS_DIR="authority-v2/proofs"

mapfile -t symlinks < <(cd "$ROOT" && find authority-v2 -type l | LC_ALL=C sort)
if [ "${#symlinks[@]}" -gt 0 ]; then
  echo "::error::SYMLINK ΚΑΤΩ ΑΠΟ authority-v2/ (η απογραφή δεν μπορεί να τα δεσμεύσει): ${symlinks[*]}"
  exit 1
fi

mapfile -t all_files < <(cd "$ROOT" && find authority-v2 -type f | LC_ALL=C sort)
[ "${#all_files[@]}" -gt 0 ] || { echo "::error::ΚΕΝΟ authority-v2 — καμία ψευδο-επιτυχία"; exit 1; }

in_proofs=(); code_outside=()
for f in "${all_files[@]}"; do
  case "$f" in
    "$PROOFS_DIR"/*)
      rest="${f#"$PROOFS_DIR"/}"
      case "$rest" in
        */*) echo "::error::ΥΠΟΚΑΤΑΛΟΓΟΣ ΣΤΟ proofs/: $f — ο κατάλογος εισόδων είναι ΕΠΙΠΕΔΟΣ"; exit 1;;
      esac
      in_proofs+=("$f");;
    *.py|*.sh|*.lisp) code_outside+=("$f");;   # ΟΛΟΣ ο κώδικας, ΧΩΡΙΣ ευρετικά
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
    plain|requires-root|requires-sbcl|requires-docker|tool-requires-root|tool-declared|helper) ;;
    *) echo "::error::ΑΓΝΩΣΤΟΣ τρόπος '$mode' (γραμμή $lineno· κλειστό σχήμα)"; exit 1;;
  esac
  if [ -n "${MODE[$path]:-}" ]; then
    echo "::error::ΔΙΠΛΟΤΥΠΗ ΕΓΓΡΑΦΗ '$path' (γραμμή $lineno)"; exit 1
  fi
  MODE["$path"]="$mode"; ARGS["$path"]="$*"
  census+=("$path"); order+=("$path")
done < "$CENSUS"

missing=(); dead=(); stray=(); baptised=()
for f in "${in_proofs[@]}"; do
  case "${MODE[$f]:-}" in
    "")            missing+=("$f");;
    tool-*|helper) baptised+=("$f");;          # ΒΑΠΤΙΣΗ: απόδειξη ως εργαλείο
  esac
done
for f in "${census[@]}"; do [ -f "$ROOT/$f" ] || dead+=("$f"); done
# ΚΑΘΕ αρχείο κώδικα ΕΚΤΟΣ proofs/ ΠΡΕΠΕΙ να είναι ΔΗΛΩΜΕΝΟ tool-* ή helper.
for f in "${code_outside[@]:-}"; do
  [ -n "$f" ] || continue
  case "${MODE[$f]:-}" in tool-*|helper) ;; *) stray+=("$f");; esac
done
if [ "${#missing[@]}" -gt 0 ] || [ "${#dead[@]}" -gt 0 ] || [ "${#stray[@]}" -gt 0 ] \
   || [ "${#baptised[@]}" -gt 0 ]; then
  [ "${#missing[@]}" -gt 0 ]  && echo "::error::ΞΕΧΑΣΜΕΝΕΣ ΑΠΟΔΕΙΞΕΙΣ (στο proofs/, εκτός απογραφής): ${missing[*]}"
  [ "${#dead[@]}" -gt 0 ]     && echo "::error::ΝΕΚΡΕΣ ΕΓΓΡΑΦΕΣ (στην απογραφή, ανύπαρκτες): ${dead[*]}"
  [ "${#stray[@]}" -gt 0 ]    && echo "::error::ΑΤΑΞΙΝΟΜΗΤΟΣ ΚΩΔΙΚΑΣ ΕΚΤΟΣ ΤΟΥ ΚΑΤΑΛΟΓΟΥ ΕΙΣΟΔΩΝ: ${stray[*]}"
  [ "${#baptised[@]}" -gt 0 ] && echo "::error::ΒΑΠΤΙΣΗ ΑΠΟΔΕΙΞΗΣ ΩΣ ΕΡΓΑΛΕΙΟΥ (μέσα στο proofs/): ${baptised[*]}"
  exit 1
fi
for f in "${census[@]}"; do
  case "${MODE[$f]}" in tool-*|helper) continue;; esac
  case "$f" in
    "$PROOFS_DIR"/*) ;;
    *) echo "::error::Η ΑΠΟΓΡΑΦΗ δηλώνει απόδειξη ΕΚΤΟΣ proofs/: $f"; exit 1;;
  esac
done
echo "── απογραφή: ${#all_files[@]} αρχεία σαρώθηκαν ΑΝΑΔΡΟΜΙΚΑ· ${#in_proofs[@]} είσοδοι στο proofs/· ${#code_outside[@]} αρχεία κώδικα εκτός, ΟΛΑ ταξινομημένα· 0 symlinks ──"
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
  elif exec_entry "$f"; then
    echo "  ✓ προετοιμασία ΟΚ"
  else
    rc=$?
    setup_ok=0; fail=$((fail+1)); FAILED+=("$f (setup απέτυχε)")
    echo "  ✗ Η ΠΡΟΕΤΟΙΜΑΣΙΑ ΑΠΕΤΥΧΕ (exit $rc)"
  fi
  echo
done

for f in "${order[@]}"; do
  mode="${MODE[$f]}"
  case "$mode" in tool-*|helper) continue;; esac
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
