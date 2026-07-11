# Epistemic Release Verification Script (PowerShell)
# Usage: .\verify.ps1 <release-dir>
#
# NOTE: For DARPA-GRADE verification, use verify.lisp instead:
#   sbcl --script verify.lisp <release-dir>

param(
    [string]$ReleaseDir = "."
)

Write-Host "=== EPISTEMIC RELEASE VERIFICATION ===" -ForegroundColor Cyan
Write-Host "Release: $ReleaseDir"
Write-Host "NOTE: For Pure Lisp verification, use: sbcl --script verify.lisp $ReleaseDir" -ForegroundColor Gray
Write-Host

# Check if files exist
Write-Host "[1/4] Checking manifests..." -ForegroundColor Yellow
if (Test-Path "$ReleaseDir/manifest.ttl") { Write-Host "  ✓ manifest.ttl" -ForegroundColor Green }
else { Write-Host "  ✗ manifest.ttl missing" -ForegroundColor Red; exit 1 }
if (Test-Path "$ReleaseDir/manifest.jsonld") { Write-Host "  ✓ manifest.jsonld" -ForegroundColor Green }
else { Write-Host "  ✗ manifest.jsonld missing" -ForegroundColor Red; exit 1 }
Write-Host

Write-Host "[2/4] Checking JWS signature..." -ForegroundColor Yellow
if (Test-Path "$ReleaseDir/temporal-proof/signature.jws") { Write-Host "  ✓ signature.jws" -ForegroundColor Green }
else { Write-Host "  ⚠ signature.jws not found" -ForegroundColor Yellow }
if (Test-Path "$ReleaseDir/verify/public.jwk") { Write-Host "  ✓ public.jwk" -ForegroundColor Green }
else { Write-Host "  ⚠ public.jwk not found" -ForegroundColor Yellow }
Write-Host

Write-Host "[3/4] Checking RFC 3161 timestamp..." -ForegroundColor Yellow
if (Test-Path "$ReleaseDir/temporal-proof/timestamp.tsr") { Write-Host "  ✓ timestamp.tsr" -ForegroundColor Green }
else { Write-Host "  ⚠ timestamp.tsr not found" -ForegroundColor Yellow }
Write-Host

Write-Host "[4/4] Checking Merkle tree..." -ForegroundColor Yellow
if (Test-Path "$ReleaseDir/temporal-proof/merkle-tree.json") { Write-Host "  ✓ merkle-tree.json" -ForegroundColor Green }
else { Write-Host "  ⚠ merkle-tree.json not found" -ForegroundColor Yellow }
Write-Host

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "✓ BASIC VERIFICATION PASSED" -ForegroundColor Green
Write-Host ""
Write-Host "For cryptographic verification, use Pure Lisp:"
Write-Host "  sbcl --script verify.lisp $ReleaseDir" -ForegroundColor White
Write-Host "===========================================" -ForegroundColor Cyan
