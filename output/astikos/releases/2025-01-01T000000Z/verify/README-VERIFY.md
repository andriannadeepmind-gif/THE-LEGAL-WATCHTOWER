# Epistemic Release Verification

This directory contains all tools needed to verify the epistemic integrity of this release.

## DARPA-GRADE: Pure Lisp Verification (Recommended)

```bash
cd verify
sbcl --script verify.lisp ..
```

**No OpenSSL required.** The Pure Lisp verification script performs full cryptographic
verification using only Common Lisp libraries (Ironclad).

## What Gets Verified

1. **Manifest Integrity**: Presence of manifest.ttl and manifest.jsonld
2. **JWS Signature**: RSA-SHA256 digital signature verification (Pure Lisp)
3. **RFC 3161 Timestamp**: Presence and structure verification
4. **Merkle Tree**: Presence verification

## Alternative Verification Methods

### Bash (basic checks only)
```bash
cd verify
chmod +x verify.sh
./verify.sh ..
```

### PowerShell (basic checks only)
```powershell
cd verify
.\verify.ps1 ..
```

Note: Shell scripts perform basic file presence checks only.
For full cryptographic verification, use the Pure Lisp script.

## Files in this Directory

- `verify.lisp` - **Primary** Pure Lisp verification (DARPA-GRADE)
- `verify.sh` - Bash script (basic checks)
- `verify.ps1` - PowerShell script (basic checks)
- `public.jwk` - JWK public key for JWS verification
- `tsa-ca.pem` - TSA CA certificate

## Dependencies for Pure Lisp Verification

- SBCL (Steel Bank Common Lisp)
- Ironclad (cryptography)
- Babel (encoding)
- Yason (JSON parsing)
- cl-base64 (Base64 encoding)

## Verification Failure = Invalid Release

If ANY verification step fails, this release MUST be considered invalid.
No fallbacks, no partial validity - strict proof gates.

**η DARPA δεν δουλεύει με wrappers**
