#!/bin/bash
# Epistemic Release Verification Script
# Usage: ./verify.sh <release-dir>
#
# NOTE: For DARPA-GRADE verification, use verify.lisp instead:
#   sbcl --script verify.lisp <release-dir>

set -e

RELEASE_DIR="${1:-.}"

echo "=== EPISTEMIC RELEASE VERIFICATION ==="
echo "Release: $RELEASE_DIR"
echo "NOTE: For Pure Lisp verification, use: sbcl --script verify.lisp $RELEASE_DIR"
echo

# Check if files exist
echo "[1/4] Checking manifests..."
[ -f "$RELEASE_DIR/manifest.ttl" ] && echo "  ✓ manifest.ttl" || { echo "  ✗ manifest.ttl missing"; exit 1; }
[ -f "$RELEASE_DIR/manifest.jsonld" ] && echo "  ✓ manifest.jsonld" || { echo "  ✗ manifest.jsonld missing"; exit 1; }
echo

echo "[2/4] Checking JWS signature..."
[ -f "$RELEASE_DIR/temporal-proof/signature.jws" ] && echo "  ✓ signature.jws" || echo "  ⚠ signature.jws not found"
[ -f "$RELEASE_DIR/verify/public.jwk" ] && echo "  ✓ public.jwk" || echo "  ⚠ public.jwk not found"
echo

echo "[3/4] Checking RFC 3161 timestamp..."
[ -f "$RELEASE_DIR/temporal-proof/timestamp.tsr" ] && echo "  ✓ timestamp.tsr" || echo "  ⚠ timestamp.tsr not found"
echo

echo "[4/4] Checking Merkle tree..."
[ -f "$RELEASE_DIR/temporal-proof/merkle-tree.json" ] && echo "  ✓ merkle-tree.json" || echo "  ⚠ merkle-tree.json not found"
echo

echo "==========================================="
echo "✓ BASIC VERIFICATION PASSED"
echo ""
echo "For cryptographic verification, use Pure Lisp:"
echo "  sbcl --script verify.lisp $RELEASE_DIR"
echo "==========================================="
