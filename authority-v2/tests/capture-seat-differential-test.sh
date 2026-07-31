#!/usr/bin/env bash
# =============================================================================
# ΔΙΑΦΟΡΙΚΟ ΤΕΣΤ ΕΔΡΑΣ — Η capture ΚΑΙ Η ΠΑΡΑΓΩΓΗ ΠΡΕΠΕΙ ΝΑ ΔΙΝΟΥΝ ΤΗΝ ΙΔΙΑ ΡΙΖΑ
# =============================================================================
# ΕΥΡΗΜΑ ΔΗΜΙΟΥΡΓΟΥ (P0): «η capture υπολογίζει SHA256(0x00 ‖ SHA256(bytes))·
# η παραγωγική hash-leaf-file υπολογίζει SHA256(0x00 ‖ ΩΜΑ BYTES). Ασύμβατο.»
#
# Η ΑΠΟΔΕΙΞΗ ΔΕΝ ΕΙΝΑΙ ΙΣΧΥΡΙΣΜΟΣ ΣΕ ΣΧΟΛΙΟ. Εδώ τρέχουν ΚΑΙ ΟΙ ΔΥΟ έδρες πάνω
# στα ΙΔΙΑ bytes και οι ρίζες συγκρίνονται byte-για-byte:
#   · authority-v2/capture/capture.py            (Python, authority process)
#   · orchestrator.merkle:merkle-root-of-files   (ΠΑΡΑΓΩΓΙΚΟΣ Lisp πυρήνας,
#     source/merkle-authority.lisp — ΔΕΝ αντιγράφεται, ΚΑΛΕΙΤΑΙ)
#
# ΕΠΙΠΛΕΟΝ: αρνητικός μάρτυρας — αν αλλάξει ΕΝΑ byte σε ΕΝΑ αρχείο, οι ρίζες
# ΟΦΕΙΛΟΥΝ να αλλάξουν ΚΑΙ ΟΙ ΔΥΟ και να παραμείνουν ίσες μεταξύ τους. Χωρίς
# αυτό, μια σταθερή/ταυτολογική ρίζα θα περνούσε.
#
# Χωρίς sbcl ⇒ exit 2 BLOCKED — ΠΟΤΕ pass.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
p=0; f=0
ok(){ p=$((p+1)); echo "  ok   $*"; }
no(){ f=$((f+1)); echo "  FAIL $*"; }

command -v sbcl >/dev/null || { echo "::error::BLOCKED — sbcl ΑΠΩΝ (δεν δηλώνεται pass)"; exit 2; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

build_candidate() {           # $1 = κατάλογος, $2 = περιεχόμενο του b.txt
  mkdir -p "$1/sub"
  printf 'alpha'   > "$1/a.txt"
  printf '%s'  "$2" > "$1/b.txt"
  printf 'gamma'   > "$1/sub/c.txt"
  # Μη-ASCII και κενό αρχείο: η έδρα οφείλει να δουλεύει στα ΩΜΑ bytes.
  printf '\316\206\317\201\316\270\317\201\316\277 1' > "$1/greek.txt"
  : > "$1/empty.bin"
}

CANON="$WORK/canonical.txt"
printf 'a.txt\nb.txt\nsub/c.txt\ngreek.txt\nempty.bin\n' > "$CANON"

run_pair() {                  # $1 = ετικέτα, $2 = περιεχόμενο, ορίζει PY_ROOT/CL_ROOT
  local tag="$1" content="$2" cand="$WORK/$1-cand" q="$WORK/$1-q"
  build_candidate "$cand" "$content"
  PY_ROOT="$(python3 "$REPO/authority-v2/capture/capture.py" "$cand" "$q" "$CANON" \
             | python3 -c 'import json,sys; print(json.load(sys.stdin)["release_root"])')"
  # ΤΑ ΙΔΙΑ ΑΡΧΕΙΑ, ΑΠΟ ΤΟ QUARANTINE, ΣΤΗΝ ΙΔΙΑ ΣΕΙΡΑ.
  local files=()
  while IFS= read -r rel; do files+=("$q/$rel"); done < "$CANON"
  CL_ROOT="$(LAWMAX_REPO="$REPO" sbcl --script \
      "$REPO/authority-v2/tests/probe-merkle-root-of-files.lisp" "${files[@]}" 2>/dev/null \
      | sed -n 's/^RELEASE-ROOT //p' | tail -1)"
}

echo "== ① ΙΔΙΑ BYTES ⇒ ΙΔΙΑ ΡΙΖΑ (capture.py vs ΠΑΡΑΓΩΓΙΚΟΣ Lisp πυρήνας) =="
run_pair "v1" "beta bytes"
V1_PY="$PY_ROOT"; V1_CL="$CL_ROOT"
[ -n "$V1_PY" ] && ok "capture.py ⇒ $V1_PY" || no "capture.py δεν παρήγαγε ρίζα"
[ -n "$V1_CL" ] && ok "merkle-root-of-files ⇒ $V1_CL" || no "ο Lisp πυρήνας δεν παρήγαγε ρίζα"
if [ -n "$V1_PY" ] && [ "$V1_PY" = "$V1_CL" ]; then
  ok "ΤΑΥΤΙΣΗ ΕΔΡΩΝ — η capture χρησιμοποιεί ΑΚΡΙΒΩΣ την παραγωγική Merkle έδρα"
else
  no "ΑΠΟΚΛΙΣΗ ΕΔΡΩΝ: python=$V1_PY lisp=$V1_CL"
fi

echo
echo "== ② ΑΡΝΗΤΙΚΟΣ ΜΑΡΤΥΡΑΣ: ΕΝΑ byte αλλάζει ⇒ ΚΑΙ ΟΙ ΔΥΟ ρίζες αλλάζουν =="
run_pair "v2" "beta byteS"
V2_PY="$PY_ROOT"; V2_CL="$CL_ROOT"
[ "$V2_PY" != "$V1_PY" ] && ok "capture.py: η ρίζα ΑΛΛΑΞΕ (όχι σταθερά/ταυτολογία)" \
                         || no "capture.py: ΙΔΙΑ ρίζα για ΔΙΑΦΟΡΕΤΙΚΑ bytes"
[ "$V2_CL" != "$V1_CL" ] && ok "Lisp: η ρίζα ΑΛΛΑΞΕ" \
                         || no "Lisp: ΙΔΙΑ ρίζα για ΔΙΑΦΟΡΕΤΙΚΑ bytes"
[ -n "$V2_PY" ] && [ "$V2_PY" = "$V2_CL" ] && ok "ΤΑΥΤΙΣΗ ΕΔΡΩΝ και στο μεταλλαγμένο σύνολο" \
                                           || no "ΑΠΟΚΛΙΣΗ: python=$V2_PY lisp=$V2_CL"

echo
echo "== ③ Η ΣΕΙΡΑ ΕΙΝΑΙ ΜΕΡΟΣ ΤΗΣ ΔΕΣΜΕΥΣΗΣ (ΚΑΙ ΣΤΙΣ ΔΥΟ ΕΔΡΕΣ) =="
printf 'b.txt\na.txt\nsub/c.txt\ngreek.txt\nempty.bin\n' > "$WORK/canon-swapped.txt"
SW_PY="$(python3 "$REPO/authority-v2/capture/capture.py" "$WORK/v1-cand" "$WORK/v3-q" \
         "$WORK/canon-swapped.txt" \
         | python3 -c 'import json,sys; print(json.load(sys.stdin)["release_root"])')"
files=(); while IFS= read -r rel; do files+=("$WORK/v3-q/$rel"); done < "$WORK/canon-swapped.txt"
SW_CL="$(LAWMAX_REPO="$REPO" sbcl --script \
    "$REPO/authority-v2/tests/probe-merkle-root-of-files.lisp" "${files[@]}" 2>/dev/null \
    | sed -n 's/^RELEASE-ROOT //p' | tail -1)"
[ "$SW_PY" != "$V1_PY" ] && ok "εναλλαγή σειράς ⇒ ΔΙΑΦΟΡΕΤΙΚΗ ρίζα (capture.py)" \
                         || no "η σειρά ΔΕΝ δεσμεύεται στην capture.py"
[ -n "$SW_PY" ] && [ "$SW_PY" = "$SW_CL" ] && ok "ΤΑΥΤΙΣΗ ΕΔΡΩΝ και στην εναλλαγμένη σειρά" \
                                           || no "ΑΠΟΚΛΙΣΗ: python=$SW_PY lisp=$SW_CL"

echo
echo "── capture seat differential: $p passed, $f failed ──"
[ "$f" -eq 0 ]
