#!/usr/bin/env bash
# ============================================================================
# L7-A VECTOR RUNNER — η προδιαγραφή γίνεται πύλη.
# ============================================================================
# Τρέχει ΚΑΘΕ release-conformance vector μέσα από ΔΥΟ ανεξάρτητες υλοποιήσεις:
#   · L6 πυρήνας      (Common Lisp)  — deployment/verify/kernel-verify.lisp
#   · δεύτερη γλώσσα  (Python stdlib) — deployment/verify/verify-release.py
# και απαιτεί: (α) κάθε υλοποίηση ≡ την ετυμηγορία του INDEX.json, ΚΑΙ
#             (β) οι δύο υλοποιήσεις να ΣΥΜΦΩΝΟΥΝ μεταξύ τους (L7 diversity).
# Απόκλιση σε οτιδήποτε = ΚΟΚΚΙΝΟ. Exit 0 μόνο αν ΟΛΑ συμφωνούν.
#
# Το θετικό vector τρέχει ΚΑΙ με το out-of-band pinned root (<name>.pinned-root).
# ============================================================================
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
KERNEL="$HERE/../kernel-verify.lisp"
PYVER="$HERE/../verify-release.py"
INDEX="$HERE/INDEX.json"

# ironclad κ.λπ. για τον Lisp πυρήνα (στο runtime image είναι ήδη ορατά).
: "${LAWMAX_ROOT:=$(cd "$HERE/../../.." && pwd)}"
: "${CL_SOURCE_REGISTRY:=(:source-registry (:tree \"$LAWMAX_ROOT/third-party/\") (:tree \"$LAWMAX_ROOT/source/cl-dependencies/\") :inherit-configuration)}"
export CL_SOURCE_REGISTRY

have() { command -v "$1" >/dev/null 2>&1; }
if ! have sbcl; then echo "SKIP: sbcl absent (Lisp kernel unavailable)"; exit 0; fi
if ! have python3; then echo "SKIP: python3 absent (second verifier unavailable)"; exit 0; fi

# Εξαγωγή (name, verdict) ζευγών από το INDEX μέσω python (όχι εύθραυστο grep).
mapfile -t ROWS < <(python3 - "$INDEX" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
for v in d["vectors"]:
    print(v["name"]+"\t"+v["verdict"])
PY
)

pass=0; fail=0
verdict() { # $1=exit-code -> pass|fail
  [ "$1" -eq 0 ] && echo pass || echo fail
}

for row in "${ROWS[@]}"; do
  name="${row%%$'\t'*}"; expect="${row##*$'\t'}"
  dir="$HERE/$name"
  pin=""; [ -f "$HERE/$name.pinned-root" ] && pin="$(cat "$HERE/$name.pinned-root")"

  sbcl --script "$KERNEL" "$dir" $pin >/dev/null 2>&1; kv=$(verdict $?)
  python3 "$PYVER" "$dir" $pin        >/dev/null 2>&1; pv=$(verdict $?)

  if [ "$kv" = "$expect" ] && [ "$pv" = "$expect" ]; then
    echo "  ✓ $name  [expect=$expect kernel=$kv python=$pv]"
    pass=$((pass+1))
  else
    echo "  ✗ $name  [expect=$expect kernel=$kv python=$pv]  <-- ΑΠΟΚΛΙΣΗ"
    fail=$((fail+1))
  fi
done

echo "── L7-A vector runner: $pass/$((pass+fail)) (kernel ≡ python ≡ INDEX) ──"
[ "$fail" -eq 0 ]
