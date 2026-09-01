#!/usr/bin/env bash
# V1.3 SEMANTIC-CLOSURE CONSISTENCY AUDIT — ΕΚΤΕΛΕΣΙΜΟ, ΑΝΑΠΑΡΑΓΩΓΙΜΟ
# Τρέξε από τη ρίζα του repo:  bash deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-CONSISTENCY-AUDIT.sh
# Exit 0 = ΟΛΟΙ οι έλεγχοι PASS. Exit 1 = τουλάχιστον ένας FAIL. Κάθε γραμμή: id | actual | expected | verdict.
# Ελέγχει ΟΛΑ τα active target/foundation docs. Ιστορικά (v1.1, v1.2, DESTRUCTION-RECORD) ΔΕΝ ελέγχονται για stale.
set -u
cd "$(dirname "$0")"
D=.
M=$D/MACHINE-LEGAL-TRUST-PROTOCOL.md
V=$D/CHANGE-PROPOSAL-v1.3.md
Q=$D/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md
A=$D/AS-IS-EVIDENCE-MANIFEST.md
X=$D/V1.3-SEMANTIC-CROSSWALK.md
K=$D/V1.3-KILL-WITNESSES.md
R=$D/SUPERSEDED-REGISTER.md
KL=../../../../LAWMAX-KEY-LIFECYCLE-SPEC.md
ACTIVE="$V $M $Q $X $K $A $R"
pass=0; fail=0; n=0
ck(){ # id actual op expected
  n=$((n+1)); local id="$1" a="$2" op="$3" e="$4" v
  case "$op" in ge) [ "$a" -ge "$e" ] && v=PASS || v=FAIL ;; eq) [ "$a" = "$e" ] && v=PASS || v=FAIL ;; esac
  [ "$v" = PASS ] && pass=$((pass+1)) || fail=$((fail+1))
  printf '%-6s | actual=%-4s | want %s%-4s | %s\n' "$id" "$a" "$op" "$e" "$v"
}
c(){ grep -c "$@" 2>/dev/null || true; }
cE(){ grep -cE "$@" 2>/dev/null || true; }
ci(){ grep -ci "$@" 2>/dev/null || true; }

echo "### V1.3 CONSISTENCY AUDIT — $(git -C ../../../.. rev-parse --short HEAD 2>/dev/null || echo no-git) — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "# C1 issuer self-verdict"
ck C1a "$(c 'ΚΑΝΕΝΑ .verification_result. σε IssuedClaim' $M)" ge 1
ck C1b "$(c 'ΠΟΤΕ.*verification_result' $V)" ge 1
ck C1c "$(c 'verification_result' $V)" eq 1
echo "# C2 crypto profile (not SHA-only)"
ck C2a "$(cE 'RS256.*Ed25519|Ed25519.*RS256' $M)" ge 1
ck C2b "$(c 'SHA-256. για Merkle .inclusion.\|SHA-256 για inclusion' $V)" ge 1
ck C2c "$(ci 'verified only with sha-256' $ACTIVE | awk -F: '{s+=$NF}END{print s+0}')" eq 0
# newline-tolerant: η φράση δεν επιτρέπεται ούτε line-wrapped (κάθε active doc ξεχωριστά)
ck C2d "$(for f in $ACTIVE; do tr '\n' ' ' < "$f" | grep -oi 'verified only with sha-256' | wc -l; done | awk '{s+=$1}END{print s+0}')" eq 0
echo "# C3 typed claim"
ck C3a "$(c 'claim_type' $M)" ge 1
ck C3b "$(c 'ΠΟΤΕ input' $M)" ge 1
echo "# C4 one authority root"
ck C4a "$(c 'release_root' $M)" ge 1
ck C4b "$(c 'legacy cross-check\|LEGACY CROSS-CHECK' $M)" ge 1
echo "# C5 assurance separated"
ck C5a "$(c 'QualificationStateRecord' $M)" ge 1
ck C5b "$(c 'qualification_state_ref' $M)" ge 1
echo "# C6 taxonomy"
ck C6a "$(c 'CONTAINER' $M)" ge 1
ck C6b "$(c 'legal-object-correction-or-withdrawal' $M)" ge 1
ck C6c "$(c 'trust-key-or-delegation-revocation' $M)" ge 1
ck C6d "$(c 'temporal: ✘' $M)" ge 1
echo "# C7 jurisprudence split"
ck C7a "$(c 'judgment-identity-and-text' $M)" ge 1
ck C7b "$(c 'jurisprudential-analysis' $M)" ge 1
ck C7c "$(c 'reviewer_adoption_act' $M)" ge 1
ck C7d "$(c 'ΠΟΤΕ ως θεσμικά πιστοποιημένο ratio' $M)" ge 1
echo "# C8 witness vs auditor"
ck C8a "$(c 'Transparency witnesses' $M)" ge 1
ck C8b "$(c 'Independent auditors' $M)" ge 1
ck C8c "$(c 'GitHub/TSAs.*πιστοποιούν' $M)" ge 1
echo "# C9 revocation semantics"
ck C9a "$(c 'invalid_from' $M)" ge 1
ck C9b "$(c 'compromise_known_at' $M)" ge 1
ck C9c "$(c 'retroactively-revoked\|ΑΝΑΔΡΟΜΙΚΑ' $M)" ge 1
echo "# C10 AS-IS reproducible"
ck C10a "$(c '\.\.\.' $A)" eq 0
ck C10b "$(ci 'artifact count\|ARTIFACT αρχείων' $A)" ge 1
ck C10c "$(c '71' $A)" ge 1
ck C10d "$(cE '[0-9a-f]{64}' $A)" ge 3
echo "# C11 stale v1.2 in qualification"
ck C11a "$(c 'CHANGE-PROPOSAL-v1.3.md' $Q)" ge 1
ck C11b "$(c 'ταυτότητα = digest των .PLANE-0. bytes' $Q)" eq 0
ck C11c "$(c 'RFC 3161 timestamp . ταυτότητα καναλιού' $Q)" eq 0
ck C11d "$(c 'direct-publish bypass' $Q)" ge 1
echo "# C12 delegation chain (errata #2)"
ck C12a "$(c 'delegation-scope-violation' $M)" ge 2
ck C12b "$(c 'ΔΙΑΦΟΡΕΤΙΚΟ.*thumbprint' $M)" ge 1
ck C12c "$(c 'thumbprint(bundle release key) == thumbprint(PINNED_ROOT)' $M)" eq 0
ck C12d "$(c 'pinned_owner_root ──' $M)" ge 1
echo "# C13 LocalTrustState + UNKNOWN_FRESHNESS (errata #3)"
ck C13a "$(c 'LocalTrustState' $M)" ge 3
ck C13b "$(c 'UNKNOWN_FRESHNESS' $M)" ge 3
ck C13c "$(c 'verify_bundle(bundle, lts)\|verify_bundle(bundle, LocalTrustState)' $M)" ge 1
ck C13d "$(c 'trusted_time' $M)" ge 2
echo "# C14 offline-resolvable bundle (errata #4)"
ck C14a "$(c 'qualification_records' $M)" ge 2
ck C14b "$(c 'auditor_receipts' $M)" ge 2
ck C14c "$(c 'witness_checkpoints' $M)" ge 2
ck C14d "$(c 'untrusted-registry' $M)" ge 2
echo "# C15 no self-qualification (errata #5)"
ck C15a "$(c 'unauthorized-qualification-issuer' $M)" ge 2
ck C15b "$(c 'dangling-qualification-ref' $M)" ge 2
ck C15c "$(c 'ΔΕΝ μπορεί να υπογράψει QualificationStateRecord για τον' $M)" ge 1
ck C15d "$(c 'provider_attestations' $M)" ge 1
echo "# C16 signature-time revocation (errata #6)"
ck C16a "$(c 'issued_at' $M)" ge 3
ck C16b "$(c 'trusted signature time\|trusted signature-time' $M)" ge 2
ck C16c "$(c 'c.effective_time' $M)" eq 0
echo "# C17 KEY-LIFECYCLE precedence (errata #7)"
ck C17a "$(c 'versioned precedence' $M)" ge 1
ck C17b "$(c 'versioned precedence' $KL)" ge 1
ck C17c "$(c 'MACHINE-LEGAL-TRUST-PROTOCOL.md §9' $KL)" ge 1
echo "# C18 stale residuals across ALL active docs (errata #1)"
ck C18a "$(c 'destruction pass στο v1\.2' $ACTIVE | awk -F: '{s+=$NF}END{print s+0}')" eq 0
ck C18b "$(cE 'JurisprudenceCertificate|SourceAuthenticityReceipt|LegalStateCertificate|TemporalProjectionCertificate|CoverageAndFreshnessCertificate|CorrectionOrRevocationRecord' $ACTIVE | awk -F: '{s+=$NF}END{print s+0}')" eq 0
ck C18c "$(c 'metrics επαληθεύονται από τους witnesses' $ACTIVE | awk -F: '{s+=$NF}END{print s+0}')" eq 0
ck C18d "$(cE '7 πιστοποιητικ|επτά πιστοποιητικ|7 certs|7 certificates' $ACTIVE | awk -F: '{s+=$NF}END{print s+0}')" eq 0
ck C18e "$(c 'independent auditors\|Independent auditors' $V $M | awk -F: '{s+=$NF}END{print s+0}')" ge 2
echo "# C19 kill witnesses present & un-executed"
ck C19a "$(c '^| \*\*KW-' $K)" ge 16
ck C19b "$(c 'ΔΕΝ ΕΧΟΥΝ ΕΚΤΕΛΕΣΤΕΙ\|ΜΗ ΕΚΤΕΛΕΣΜΕΝΟΙ' $K)" ge 1
echo "### SUMMARY: checks=$n pass=$pass fail=$fail"
[ "$fail" -eq 0 ] && { echo "### EXIT 0 — ALL PASS"; exit 0; } || { echo "### EXIT 1 — DEVIATIONS PRESENT"; exit 1; }
