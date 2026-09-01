#!/usr/bin/env bash
# Deterministic verification of the committed real RFC-3161 token via the vetted
# OpenSSL `ts` implementation. Exit 0 iff the token verifies against the committed
# test CA (cert chain + message imprint + time semantics) AND a tampered message
# is rejected. No private keys required (verification is public).
set -u
cd "$(dirname "$0")"
out=$(openssl ts -verify -data message.txt -in token.tsr -CAfile ca.crt -untrusted tsa.crt 2>&1)
echo "$out" | grep -q "Verification: OK" || { echo "RFC3161 BLOCKED: positive verify failed"; echo "$out"; exit 1; }
printf 'tampered-negative' > .wrong
if openssl ts -verify -data .wrong -in token.tsr -CAfile ca.crt -untrusted tsa.crt >/dev/null 2>&1; then
  rm -f .wrong; echo "RFC3161 BLOCKED: tampered message accepted"; exit 1
fi
rm -f .wrong
# surface the standards semantics
openssl ts -reply -in token.tsr -text 2>/dev/null | grep -iE 'Status:|Policy OID:|Hash Algorithm:|Time stamp:|Accuracy:' | sed 's/^/  /'
echo "RFC3161 OK — real DER token verified via OpenSSL ts (cert chain, sha256 imprint, genTime+accuracy)"
