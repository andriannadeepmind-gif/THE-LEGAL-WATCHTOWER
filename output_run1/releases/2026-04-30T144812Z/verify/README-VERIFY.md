# Epistemic Release Verification

This directory contains all tools needed to verify the epistemic integrity of this release.

## What Gets Verified

1. **Merkle Tree**: Cryptographic commitment to all artifacts
2. **RFC 3161 Timestamp**: Temporal priority proof from Timestamp Authority
3. **Certificate Transparency**: Multi-log public append-only proofs
4. **JWS Signature**: Digital signature over manifest
5. **SHACL Validation**: Structural compliance of all RDF artifacts

## Quick Verification

### Bash (Linux/macOS)
```bash
cd verify
chmod +x verify.sh
./verify.sh ..
```

### PowerShell (Windows)
```powershell
cd verify
.\verify.ps1 ..
```

### Lisp (Cross-platform, deterministic)
```bash
cd verify
sbcl --script verify.lisp ..
```

## Manual Verification

### RFC 3161 Timestamp
```bash
openssl ts -verify \
  -in ../temporal-proof/timestamp.tsr \
  -data ../manifest.ttl \
  -CAfile tsa-ca.pem
```

### JWS Signature
```bash
jose jws verify \
  -i ../manifest.ttl \
  -s ../temporal-proof/signature.jws \
  -k public.jwk
```

## Dependencies

- OpenSSL (for RFC 3161 verification)
- jose-util (for JWS verification)
- SHACL validator (e.g., Apache Jena shacl)

## Verification Failure = Invalid Release

If ANY verification step fails, this release MUST be considered invalid.
No fallbacks, no partial validity - strict proof gates.
