#!/usr/bin/env bash
# Deterministic verification of the committed real COSE_Sign1 vector via the
# VETTED veraison/go-cose (vendored, offline). Exit 0 iff: the committed vector
# verifies over the exact MLTP payload bytes; a tampered payload is rejected; and
# a fresh re-make reproduces byte-identical bytes (Ed25519 COSE_Sign1 is deterministic).
set -u
cd "$(dirname "$0")"
go run -mod=vendor . verify payload.bin vector.cose >/dev/null 2>&1 || { echo "COSE BLOCKED: committed vector failed to verify"; exit 1; }
printf 'tampered-negative' > .wrong
if go run -mod=vendor . verify .wrong vector.cose >/dev/null 2>&1; then rm -f .wrong; echo "COSE BLOCKED: tampered payload accepted"; exit 1; fi
rm -f .wrong
go run -mod=vendor . make payload.bin .remade.cose >/dev/null 2>&1
if ! cmp -s vector.cose .remade.cose; then rm -f .remade.cose; echo "COSE BLOCKED: re-make not byte-identical (nondeterministic)"; exit 1; fi
rm -f .remade.cose
echo "COSE OK — real COSE_Sign1 (veraison/go-cose v1.3.0, Ed25519) verified over exact MLTP payload bytes; deterministic; distinct construction from MLTP canonical-JSON signature"
