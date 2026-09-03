#!/usr/bin/env bash
# V1.8-CLEAN-CLONE-BOOTSTRAP.sh — deterministic prerequisite check for the v1.8 verification harness.
#
# A fresh SHALLOW clone does not contain the frozen v1.4 baseline commit 88129099 (its tree a2617649 is a pinned
# regression anchor). Running the audit against such a clone otherwise reports a GENERIC regression failure. This
# bootstrap instead resolves the situation precisely: it verifies every pinned historical object is present (and
# has the pinned tree); if one is missing it tries a bounded fetch of that exact object; if the object still cannot
# be obtained it STOPS with a precise `MISSING_PINNED_OBJECT` line and a non-zero exit, so the operator knows the
# exact prerequisite rather than a vague "regression failed".
#
# Usage: bash V1.8-CLEAN-CLONE-BOOTSTRAP.sh    -> exit 0 (all pinned objects present + verified) or non-zero.
set -uo pipefail
cd "$(dirname "$0")"
ROOT=../../../../..

PINNED_COMMIT=88129099be1ad69feb80d40337ede6c286b83223
PINNED_TREE=a2617649596644c25894c4343f25ddb6c4dec1ce

have_obj(){ git -C "$ROOT" cat-file -e "$1^{commit}" 2>/dev/null; }
tree_of(){ git -C "$ROOT" rev-parse "$1^{tree}" 2>/dev/null; }

if ! have_obj "$PINNED_COMMIT"; then
  echo "bootstrap: pinned commit $PINNED_COMMIT absent (shallow clone?) — attempting bounded fetch"
  git -C "$ROOT" fetch --no-tags --depth=1 origin "$PINNED_COMMIT" >/dev/null 2>&1 \
    || git -C "$ROOT" fetch --no-tags origin "$PINNED_COMMIT" >/dev/null 2>&1 || true
fi

if ! have_obj "$PINNED_COMMIT"; then
  echo "MISSING_PINNED_OBJECT: commit $PINNED_COMMIT (frozen v1.4 baseline) — fetch it with:"
  echo "  git fetch --no-tags origin $PINNED_COMMIT"
  echo "bootstrap: PREREQUISITE NOT MET"
  exit 2
fi

got_tree="$(tree_of "$PINNED_COMMIT")"
if [ "$got_tree" != "$PINNED_TREE" ]; then
  echo "MISSING_PINNED_OBJECT: tree mismatch for $PINNED_COMMIT — got '$got_tree', pinned '$PINNED_TREE'"
  echo "bootstrap: PREREQUISITE NOT MET (pinned tree does not match)"
  exit 3
fi

# pinned .out artifact (checked into this directory) must be present + match
OUT=V1.4-CONTRADICTION-OMISSION-AUDIT.out
PINNED_OUT=4873e61069d4a1a2a1047d059b81cd9103171776346650a3b5ed4eee077624fb
if [ ! -f "$OUT" ]; then
  echo "MISSING_PINNED_OBJECT: $OUT (pinned v1.4 audit output) absent"
  exit 4
fi
got_out="$(sha256sum "$OUT" | cut -d' ' -f1)"
if [ "$got_out" != "$PINNED_OUT" ]; then
  echo "MISSING_PINNED_OBJECT: $OUT sha256 mismatch — got $got_out pinned $PINNED_OUT"
  exit 5
fi

echo "bootstrap: OK — pinned commit $PINNED_COMMIT present (tree $PINNED_TREE), pinned .out verified"
exit 0
