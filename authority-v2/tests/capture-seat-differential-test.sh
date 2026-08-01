#!/usr/bin/env bash
# =============================================================================
# ΔΙΑΦΟΡΙΚΟ ΤΕΣΤ ΕΔΡΑΣ — capture.py vs ΠΑΡΑΓΩΓΙΚΟΣ LISP ΠΥΡΗΝΑΣ
# =============================================================================
# ΔΥΟ ανεξάρτητες ταυτίσεις, καμία υπόσχεση σχολίου:
#   ① Η MERKLE ΕΔΡΑ: τρέχουν ΚΑΙ ΟΙ ΔΥΟ έδρες στα ΙΔΙΑ bytes
#      (capture.py και orchestrator.merkle:merkle-root-of-files — ΔΕΝ
#      αντιγράφεται, ΚΑΛΕΙΤΑΙ) και οι ρίζες συγκρίνονται byte-για-byte.
#   ② ΤΟ CANONICAL ΣΥΝΟΛΟ: το authority-v2/capture/canonical-profile.json
#      ΟΦΕΙΛΕΙ να είναι ΑΚΡΙΒΩΣ η σταθερά +EPISTEMIC-CANONICAL-FILES+ του
#      παραγωγικού πυρήνα, ΣΤΗ ΣΕΙΡΑ που παράγει η collect-epistemic-artifacts.
#      Απόκλιση ⇒ δύο διαφορετικοί ορισμοί «release identity» — απαράδεκτο.
#
# ΑΡΝΗΤΙΚΟΣ ΜΑΡΤΥΡΑΣ: ένα byte αλλάζει ⇒ ΚΑΙ ΟΙ ΔΥΟ ρίζες αλλάζουν και μένουν
# ίσες μεταξύ τους. Χωρίς αυτό, μια σταθερή/ταυτολογική ρίζα θα περνούσε.
#
# Χωρίς sbcl ⇒ exit 2 BLOCKED — ΠΟΤΕ pass.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
p=0; f=0
ok(){ p=$((p+1)); echo "  ok   $*"; }
no(){ f=$((f+1)); echo "  FAIL $*"; }

command -v sbcl >/dev/null || { echo "::error::BLOCKED — sbcl ΑΠΩΝ (δεν δηλώνεται pass)"; exit 2; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

# Το core χτίζεται ΜΙΑ φορά· και οι δύο probes το φορτώνουν σε ms.
CORE="$WORK/authority-cli.core"
LAWMAX_REPO="$REPO" sbcl --script "$REPO/authority-v2/tests/build-authority-core.lisp" "$CORE" >/dev/null 2>&1
[ -s "$CORE" ] || { echo "::error::BLOCKED — core δεν χτίστηκε"; exit 2; }

CANON_JSON="$REPO/authority-v2/capture/canonical-profile.json"
mapfile -t CANON < <(python3 -c '
import json,sys
print("\n".join(json.load(open(sys.argv[1], encoding="utf-8"))["files"]))' "$CANON_JSON")
[ "${#CANON[@]}" -gt 0 ] || { echo "::error::κενό canonical profile"; exit 1; }

echo "== ① ΤΟ CANONICAL ΣΥΝΟΛΟ ΤΑΥΤΙΖΕΤΑΙ ΜΕ ΤΗ ΣΤΑΘΕΡΑ ΤΟΥ ΠΥΡΗΝΑ =="
mapfile -t KERNEL < <(LAWMAX_REPO="$REPO" sbcl --core "$CORE" --script \
    "$REPO/authority-v2/tests/probe-canonical-files.lisp" 2>/dev/null \
    | sed -n 's/^CANON //p')
if [ "${#KERNEL[@]}" -eq 0 ]; then
  no "ο πυρήνας δεν εξέπεμψε canonical λίστα"
elif [ "${CANON[*]}" = "${KERNEL[*]}" ]; then
  ok "profile ≡ +EPISTEMIC-CANONICAL-FILES+ (${#CANON[@]} αρχεία, ΙΔΙΑ ΣΕΙΡΑ)"
else
  no "ΑΠΟΚΛΙΣΗ canonical συνόλου:
        profile: ${CANON[*]}
        πυρήνας: ${KERNEL[*]}"
fi

build_candidate() {           # $1 = inbox, $2 = περιεχόμενο του πρώτου canonical
  local cand="$1/cand" i=0
  mkdir -p "$cand"
  for rel in "${CANON[@]}"; do
    mkdir -p "$cand/$(dirname "$rel")"
    if [ "$i" -eq 0 ]; then printf '%s' "$2" > "$cand/$rel"
    else printf 'canonical:%s' "$rel" > "$cand/$rel"; fi
    i=$((i+1))
  done
  # ΜΗ canonical αρχεία: ΔΕΝ επηρεάζουν το release_root, ΜΟΝΟ το snapshot_root.
  printf '\316\206\317\201\316\270\317\201\316\277 1' > "$cand/greek-extra.txt"
  : > "$cand/empty-extra.bin"
}

run_pair() {                  # $1 = ετικέτα, $2 = περιεχόμενο· ορίζει PY_ROOT/CL_ROOT
  local tag="$1" content="$2" inbox="$WORK/$1-inbox" vault="$WORK/$1-vault"
  mkdir -p "$inbox" "$vault"
  build_candidate "$inbox" "$content"
  PY_ROOT="$(python3 "$REPO/authority-v2/capture/capture.py" "$inbox" cand "$vault" q \
             | python3 -c 'import json,sys; print(json.load(sys.stdin)["release_root"])')"
  local files=()
  for rel in "${CANON[@]}"; do files+=("$vault/q/$rel"); done
  CL_ROOT="$(LAWMAX_REPO="$REPO" sbcl --core "$CORE" --script \
      "$REPO/authority-v2/tests/probe-merkle-root-of-files.lisp" "${files[@]}" 2>/dev/null \
      | sed -n 's/^RELEASE-ROOT //p' | tail -1)"
}

echo
echo "== ② ΙΔΙΑ BYTES ⇒ ΙΔΙΑ ΡΙΖΑ (capture.py vs merkle-root-of-files) =="
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
echo "== ③ ΑΡΝΗΤΙΚΟΣ ΜΑΡΤΥΡΑΣ: ΕΝΑ byte αλλάζει ⇒ ΚΑΙ ΟΙ ΔΥΟ ρίζες αλλάζουν =="
run_pair "v2" "beta byteS"
V2_PY="$PY_ROOT"; V2_CL="$CL_ROOT"
[ "$V2_PY" != "$V1_PY" ] && ok "capture.py: η ρίζα ΑΛΛΑΞΕ (όχι σταθερά/ταυτολογία)" \
                         || no "capture.py: ΙΔΙΑ ρίζα για ΔΙΑΦΟΡΕΤΙΚΑ bytes"
[ "$V2_CL" != "$V1_CL" ] && ok "Lisp: η ρίζα ΑΛΛΑΞΕ" \
                         || no "Lisp: ΙΔΙΑ ρίζα για ΔΙΑΦΟΡΕΤΙΚΑ bytes"
[ -n "$V2_PY" ] && [ "$V2_PY" = "$V2_CL" ] && ok "ΤΑΥΤΙΣΗ ΕΔΡΩΝ και στο μεταλλαγμένο σύνολο" \
                                           || no "ΑΠΟΚΛΙΣΗ: python=$V2_PY lisp=$V2_CL"

echo
echo "== ④ Η ΣΕΙΡΑ ΕΙΝΑΙ ΜΕΡΟΣ ΤΗΣ ΔΕΣΜΕΥΣΗΣ (ΚΑΙ ΣΤΙΣ ΔΥΟ ΕΔΡΕΣ) =="
SW=(); for ((i=${#CANON[@]}-1; i>=0; i--)); do SW+=("$WORK/v1-vault/q/${CANON[$i]}"); done
SW_CL="$(LAWMAX_REPO="$REPO" sbcl --core "$CORE" --script \
    "$REPO/authority-v2/tests/probe-merkle-root-of-files.lisp" "${SW[@]}" 2>/dev/null \
    | sed -n 's/^RELEASE-ROOT //p' | tail -1)"
[ -n "$SW_CL" ] && [ "$SW_CL" != "$V1_CL" ] \
  && ok "αντίστροφη σειρά ⇒ ΔΙΑΦΟΡΕΤΙΚΗ ρίζα (η σειρά δεσμεύεται)" \
  || no "η σειρά ΔΕΝ δεσμεύεται: $SW_CL"

echo
echo "── capture seat differential: $p passed, $f failed ──"
[ "$f" -eq 0 ]
