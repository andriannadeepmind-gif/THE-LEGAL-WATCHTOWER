#!/usr/bin/env bash
# run.sh — ONE command from a clean checkout: build fixtures, cross-check the
# vetted crypto backends against RFC 8032, prove determinism + DAG/no-self-id, run
# BOTH independent verifiers (Go / Node) over the positive bundle and every mutation.
# Exit 0 iff every acceptance criterion holds. Writes fixtures/REPORT.json.
set -euo pipefail
cd "$(dirname "$0")"

for t in python3 go node openssl; do
  command -v "$t" >/dev/null 2>&1 || { echo "BLOCKED — required tool missing: $t"; exit 3; }
done
python3 -c "import ctypes; ctypes.CDLL('libsodium.so.23')" 2>/dev/null || \
  { echo "BLOCKED — BUILDER CRYPTO BACKEND UNAVAILABLE (libsodium — the builder signer, not a verifier)"; exit 3; }

exec python3 harness.py
