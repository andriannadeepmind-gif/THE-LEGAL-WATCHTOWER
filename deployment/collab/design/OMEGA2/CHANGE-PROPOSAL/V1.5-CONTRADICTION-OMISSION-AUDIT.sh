#!/usr/bin/env bash
# V1.5 NARROW-DELTA DOCUMENT/REFERENCE CONSISTENCY AUDIT — deterministic, reproducible.
# Run:  bash deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.5-CONTRADICTION-OMISSION-AUDIT.sh
# Exit 0 = all PASS. Exit 1 = a deviation.
#
# HONEST SCOPE: DOCUMENT/REFERENCE CONSISTENCY ONLY over the v1.5 CANDIDATE working tree — that every
# v1.5 id is defined and used, invariants/kill-witnesses are present, no second seat is created, AION
# is not active, the trust wording is exact, the frozen v1.4 commit is intact and its pinned .out is
# untouched. It does NOT prove semantic/legal/security correctness or qualification (tests predeclared,
# UNEXECUTED). It does NOT re-run or alter the frozen v1.4 audit or its manifest-pinned output.
set -u
cd "$(dirname "$0")"
P=CHANGE-PROPOSAL-v1.5.md
S=V1.5-SCHEMAS.sexp
MAN=V1.5-NARROW-DELTA-MANIFEST.md
M=MACHINE-LEGAL-TRUST-PROTOCOL.md
ROOT=../../../../..
IN=$ROOT/deployment/LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md
SR=$ROOT/deployment/LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md
USC=$ROOT/deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md
SC=$ROOT/deployment/LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md
CPEI=$ROOT/deployment/LAWMAX-CPEI-TARGET-SPEC.md
CONST=$ROOT/deployment/LAWMAX-ARCHITECTURE-CONSTITUTION.sexp
OUT14=V1.4-CONTRADICTION-OMISSION-AUDIT.out
ALLV5="$P $S $MAN $M $IN $SR $USC $SC $CPEI $CONST"
pass=0; fail=0; n=0
ck(){ n=$((n+1)); local id="$1" a="$2" op="$3" e="$4" v
  case "$op" in ge) [ "$a" -ge "$e" ] && v=PASS || v=FAIL ;; eq) [ "$a" = "$e" ] && v=PASS || v=FAIL ;; esac
  [ "$v" = PASS ] && pass=$((pass+1)) || fail=$((fail+1))
  printf '%-6s | actual=%-6s | want %s %-6s | %s\n' "$id" "$a" "$op" "$e" "$v"; }
c(){ grep -c "$@" 2>/dev/null || true; }
cE(){ grep -cE "$@" 2>/dev/null || true; }
sum(){ awk -F: '{s+=$NF}END{print s+0}'; }

echo "### V1.5 NARROW-DELTA DOCUMENT/REFERENCE CONSISTENCY AUDIT — $(git -C $ROOT rev-parse --short HEAD 2>/dev/null || echo no-git) — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "### SCOPE: document/reference consistency ONLY (v1.5 CANDIDATE) — NOT semantic/legal/security/qualification proof"

echo "# D1 — Independent Semantic Admission"
ck D1a "$(c 'SA-0' $P $S | sum)" ge 2
ck D1b "$(c 'SA-1' $P $S | sum)" ge 2
ck D1c "$(c 'SA-2' $P $S | sum)" ge 2
ck D1d "$(for f in candidate_id assurance_profile source_manifestation_id source_anchors derivation_family_id derivation_artifact_digest transformation_proof_ref independent_check_ref independent_derivation_ref divergence_state adoption_act_ref; do grep -lq "$f" $S && echo 1; done | sum)" eq 11
ck D1e "$(c 'SA-2 MUST NOT transition ADOPTED' $P $S $IN | sum)" ge 3
ck D1f "$(c 'INDEPENDENCE_INSUFFICIENT' $P $S | sum)" ge 2
ck D1g "$(cE 'DETERMINISTIC_DIVERGENCE|deterministic-extraction-divergence' $P $S | sum)" ge 2
ck D1h "$(c 'INTERPRETIVE_DISAGREEMENT' $P $S | sum)" ge 2
ck D1i "$(c 'universal N-version' $P)" ge 1

echo "# D2 — Census Enumerability + Negative Evidence"
ck D2a "$(for v in AUTHORITATIVE_COMPLETE_INDEX AUTHENTICATED_SERIAL_SPACE AUTHORITATIVE_PARTIAL_INDEX OBSERVATIONAL_OPEN_WORLD_SOURCE; do grep -lq "$v" $S && echo 1; done | sum)" eq 4
ck D2b "$(for v in PUBLICLY_AVAILABLE LEGALLY_UNAVAILABLE_OR_NON_PUBLIC ACCESS_RESTRICTED LICENSING_RESTRICTED; do grep -lq "$v" $S && echo 1; done | sum)" eq 4
ck D2c "$(c 'EXPLICITLY_ABSENT' $P $S $SR | sum)" ge 3
ck D2d "$(c 'NOT_OBSERVED_IN_DECLARED_SOURCE' $P $S $SR | sum)" ge 3
ck D2e "$(c 'authenticated negative evidence' $P $SR $USC | sum)" ge 3
ck D2f "$(cE 'ποτέ .* absence|never .* absence|δεν.*αποδεικνύ.*ανυπαρξ' $P $SR | sum)" ge 1

echo "# D3 — Evidence-Backed Independence Quorums"
ck D3a "$(c 'ActorIndependenceEvidence' $P $S $M | sum)" ge 3
ck D3b "$(c 'IndependencePolicy' $P $S $M | sum)" ge 3
ck D3c "$(c 'distinct-valid-kids AND satisfies' $P $M | sum)" ge 2
ck D3d "$(c 'INDEPENDENCE_UNKNOWN' $P $S $M | sum)" ge 3
ck D3e "$(cE 'δεν αποδεικνύουν ανεξαρτησία|does NOT prove independence' $P $S $M | sum)" ge 2
ck D3f "$(c 'consumer-local' $P $S $M | sum)" ge 3

echo "# C1 — Interpretive Profile closure (no new engine/primitive)"
ck C1a "$(c 'InterpretiveProfile' $P $S $SC $CPEI | sum)" ge 4
ck C1b "$(c 'ArgumentRecord' $P $S $SC $CPEI $CONST | sum)" ge 4
ck C1c "$(c 'interpretive_profile_ref' $P $S $SC | sum)" ge 3
ck C1d "$(cE 'χωρίς ψευδή επιλογή νικητή|no forced winner|no forced winner' $P $S $SC | sum)" ge 1
ck C1e "$(cE 'ΟΧΙ.*αντικειμενικ.*αλήθεια|NOT the objective truth|NOT .* objective truth' $P $S $SC | sum)" ge 2
ck C1f "$(cE 'top-level constitutional primitive|νέο primitive' $P $CPEI | sum)" ge 1

echo "# G — global invariants, no-second-seat, honesty"
ck G1 "$(c 'NO SINGLE POINT OF BLIND TRUST' $P $S | sum)" ge 2
ck G2 "$(c 'NO REQUIRED TRUST' $P $S $MAN | sum)" eq 0
ck G3 "$(for p in 'δεύτερο canonical journal' 'δεύτερο Legal Digital Twin' 'δεύτερο reasoning engine'; do grep -lq "$p" $P && echo 1; done | sum)" eq 3   # all three named as forbidden
ck G4 "$(cE 'μία έδρα|quorum έδρα' $P $M | sum)" ge 2
ck G5 "$(c -i 'document/reference consistency' $MAN)" ge 1

echo "# H — AION not active · scope exactly four deltas · frozen intact · pinned output untouched"
# every AION occurrence must be in a rejection context (reject/απορρίπτ); active-AION = 0
ck H1 "$(python3 -c "
import re,glob
files='$ALLV5'.split()
viol=0
for f in files:
  try: s=open(f,encoding='utf-8').read()
  except: continue
  for ln in s.split(chr(10)):
    if 'AION' in ln and not re.search(r'reject|απορρίπτ|maturity ladder|AION document|AION brand',ln,re.I): viol+=1
print(viol)")" eq 0
ck H2 "$(cE 'D1, D2, D3, C1' $MAN)" ge 1
ck H3 "$(git -C $ROOT show 88129099:deployment/LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md 2>/dev/null | sha256sum | grep -c '^08d1b2cb8db4073d8b58e335d4e5597e76ff1a34286dbf3e9c671ff1ae4289e0')" eq 1
ck H4 "$(git -C $ROOT show 88129099:deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.4.md 2>/dev/null | sha256sum | grep -c '^ef22d1879d9e87e8a9643dd48bba41aa680dcc3f18cd7471684541df22ea6a4e')" eq 1
ck H5 "$(sha256sum $OUT14 | grep -c '^4873e61069d4a1a2a1047d059b81cd9103171776346650a3b5ed4eee077624fb')" eq 1

echo "# K — kill witnesses predeclared (D1×5, D2×5, D3×6, C1×4 = 20) + status CANDIDATE"
ck K1 "$(cE 'V5KW-D1-[1-5]' $P | grep -c .)" ge 1
ck K2 "$(python3 -c "
import re
s=open('$P',encoding='utf-8').read()
d1=len(set(re.findall(r'V5KW-D1-([1-5])',s)))
d2=len(set(re.findall(r'V5KW-D2-([1-5])',s)))
d3=len(set(re.findall(r'V5KW-D3-([1-6])',s)))
c1=len(set(re.findall(r'V5KW-C1-([1-4])',s)))
print(1 if (d1==5 and d2==5 and d3==6 and c1==4) else 0)")" eq 1
ck K3 "$(c 'NARROW-DELTA CANDIDATE — NOT FROZEN — NOT QUALIFIED — IMPLEMENTATION BLOCKED' $P $MAN | sum)" ge 2
ck K4 "$(cE 'V5R-D1-0[1-5]|V5R-D2-0[1-5]|V5R-D3-0[1-6]|V5R-C1-0[1-4]' $P | grep -c .)" ge 1
# every affected seat carries its v1.5 appendix
ck K5 "$(for f in "$IN" "$SR" "$USC" "$M" "$SC" "$CPEI"; do grep -lq 'SPEC v1.5 NARROW-DELTA' "$f" && echo 1; done | sum)" eq 6
ck K6 "$(c 'SPEC v1.5 NARROW-DELTA' $CONST)" ge 1

echo "### SUMMARY: checks=$n pass=$pass fail=$fail"
[ "$fail" -eq 0 ] && { echo "### EXIT 0 — V1.5 DOCUMENT/REFERENCE CONSISTENCY PASS (CANDIDATE· ΟΧΙ semantic/legal/security/qualification proof)"; exit 0; } || { echo "### EXIT 1 — DEVIATIONS PRESENT"; exit 1; }
