#!/usr/bin/env bash
# =============================================================================
# ΚΑΤΑΣΚΕΥΗ ΤΟΥ RUNNER — ΧΩΡΙΣ ΔΙΚΤΥΟ, ΑΠΟ ΕΠΑΛΗΘΕΥΜΕΝΑ BYTES
# =============================================================================
# Προϋπόθεση: τα bytes υπάρχουν ήδη content-addressed στο store. Αν λείπει
# έστω ένα, ή αν ένα byte δεν ταιριάζει με το όνομά του, το build ΔΕΝ γίνεται.
# Καμία «σχεδόν πλήρης» toolchain.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CACHE="${LAWMAX_RUNNER_CACHE:-/var/cache/lawmax-runner}"
MANIFEST="$REPO/experiment/runner/toolchain.manifest.sexp"

[ -f "$MANIFEST" ] || { echo "::error::λείπει το toolchain manifest"; exit 2; }

# ── ΠΥΛΗ ①: κάθε δηλωμένο artifact υπάρχει ΚΑΙ τα bytes το επιβεβαιώνουν ────
python3 "$REPO/experiment/runner/verify-toolchain.py" "$MANIFEST" "$CACHE" || {
  echo "::error::η toolchain ΔΕΝ είναι πλήρης/ακέραιη. Τρέξε fetch-toolchain.sh (η ΜΟΝΗ φορά που επιτρέπεται δίκτυο)."
  exit 1; }

CLOSURE="$(grep -o ':closure-sha256 "[0-9a-f]\{64\}"' "$MANIFEST" | cut -d'"' -f2)"
TAG="lawmax-runner:${CLOSURE:0:16}"

cp "$REPO/experiment/runner/runner-entry.sh" "$CACHE/runner-entry.sh"

# ── ΠΥΛΗ ②: ΧΤΙΣΙΜΟ ΧΩΡΙΣ ΔΙΚΤΥΟ ───────────────────────────────────────────
docker build --network=none \
  -f "$REPO/experiment/runner/Dockerfile.runner" \
  -t "$TAG" "$CACHE"

IMAGE_ID="$(docker image inspect "$TAG" --format '{{.Id}}')"
echo "runner-image: $TAG"
echo "image-id:     $IMAGE_ID"
