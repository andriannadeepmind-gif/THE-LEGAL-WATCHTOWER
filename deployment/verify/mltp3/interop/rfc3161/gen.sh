#!/usr/bin/env bash
# Provenance: regenerate the local test TSA and a fresh real RFC-3161 token.
# The committed token.tsr is a FIXED example produced by this script; verification
# (verify.sh) is deterministic and needs only the public certs. Private keys are
# NOT committed (regenerated here). openssl `ts` signs with RSA (Ed25519 is not
# supported by the ts app); this is the RFC-3161 interop vector, independent of
# MLTP's Ed25519 object signatures.
set -eu
cd "$(dirname "$0")"
openssl req -x509 -newkey rsa:2048 -keyout ca.key -out ca.crt -days 3650 -nodes -config tsa.cnf >/dev/null 2>&1
openssl req -newkey rsa:2048 -keyout tsa.key -out tsa.csr -nodes -subj "/CN=MLTP3 Test TSA" >/dev/null 2>&1
openssl x509 -req -in tsa.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out tsa.crt -days 3650 -extfile tsa.cnf -extensions tsa_ext >/dev/null 2>&1
printf 'mltp3-rfc3161-interop-vector-v1' > message.txt
openssl ts -query -data message.txt -sha256 -cert -out request.tsq >/dev/null 2>&1
: > index.txt; echo 01 > tsa_serial
openssl ts -reply -queryfile request.tsq -config tsa.cnf -section tsa_config -out token.tsr >/dev/null 2>&1
rm -f ca.key tsa.key tsa.csr *.srl request.tsq index.txt* tsa_serial
echo "regenerated token.tsr"; bash verify.sh
