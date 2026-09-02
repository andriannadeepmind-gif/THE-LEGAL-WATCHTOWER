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
ck D3c "$(cE 'distinct-components\(control-domain-partition|distinct-control-domain-components' $P $M | sum)" ge 2   # type-closed predicate (D3.7): counts control-domain components, not kids
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

echo "# V5S — STRUCTURAL PARSE of $S (schema/cardinality/reference presence + conditional cardinality)"
echo "#       HONEST SCOPE: parse-level structural checks over the s-expression ONLY (that the closed types,"
echo "#       cardinality codes, required-refs, crypto-bind fields, deterministic partition, quorum predicate,"
echo "#       non-circular argument record, and record/enum reference closure are PRESENT and well-formed as"
echo "#       DATA). It is NOT semantic/legal/security proof and executes NONE of the predeclared V5Q/V5KW tests."
while IFS='|' read -r vid va ve; do
  [ -n "$vid" ] && ck "$vid" "$va" eq "$ve"
done < <(python3 - "$S" <<'PYV5S'
import sys,re
src=open(sys.argv[1],encoding='utf-8').read()
def strip_line_comments(s):
    out=[];i=0;n=len(s);instr=False
    while i<n:
        c=s[i]
        if instr:
            out.append(c)
            if c=='\\' and i+1<n: out.append(s[i+1]);i+=2;continue
            if c=='"':instr=False
            i+=1;continue
        if c=='"':instr=True;out.append(c);i+=1;continue
        if c==';':
            while i<n and s[i]!='\n': i+=1
            continue
        out.append(c);i+=1
    return ''.join(out)
code=strip_line_comments(src)
def form(head):
    idx=code.find('('+head)
    if idx<0: return ''
    i=idx;depth=0;instr=False;n=len(code)
    while i<n:
        c=code[i]
        if instr:
            if c=='\\': i+=2;continue
            if c=='"':instr=False
            i+=1;continue
        if c=='"':instr=True
        elif c=='(':depth+=1
        elif c==')':
            depth-=1
            if depth==0: return code[idx:i+1]
        i+=1
    return code[idx:]
def fields(rf): return re.findall(r'\(:([A-Za-z0-9_]+)\s+:type',rf)
def emembers(ef): return re.findall(r'\(:([A-Za-z0-9_]+)',ef)
R=[]
def out(i,a,e): R.append((i,str(a),str(e)))
# V5S01 D1 cardinality matrix: 16 rows, key cells correct
mform=form('define-cardinality-matrix SemanticAdmissionEvidence/1');rows={}
for m in re.finditer(r'\(([a-z_0-9]+)\s+(:[RFC])\s+(:[RFC])\s+(:[RFC])\)',mform):
    rows[m.group(1)]=(m.group(2),m.group(3),m.group(4))
key_ok=(len(rows)==16 and rows.get('transformation_proof_ref',('',))[0]==':F'
    and rows.get('independent_derivation_ref')==(':F',':F',':R')
    and rows.get('adoption_act_ref')==(':F',':F',':R')
    and rows.get('derivation_independence_evidence_ref')==(':F',':F',':C')
    and rows.get('residual_independence_assumption')==(':F',':F',':C')
    and rows.get('independent_check_ref')==(':F',':R',':R'))
out('V5S01',1 if key_ok else 0,1)
# V5S02 record fields == matrix domain
rf=set(fields(form('define-record SemanticAdmissionEvidence/1')))
out('V5S02',len(rf-set(rows))+len(set(rows)-rf),0)
# V5S03 StateEventKind SA-2 completeness
sa2=set(re.findall(r'\(:([A-Z_]+)\s+:sa\s+:SA-2\)',form('define-closed-enum StateEventKind')))
req={'ENACTMENT','AMENDMENT','COMMENCEMENT','REPEAL','SUSPENSION','REVIVAL','ANNULMENT','CORRECTION',
 'DELEGATED_AUTHORITY_CHANGE','REGIME_EFFECTIVITY_TRANSITION','CONSTITUTIONAL_REVIEW_STATE_CHANGE',
 'JUDICIAL_REVIEW_STATE_CHANGE','LINE_OF_AUTHORITY_MUTATION'}
out('V5S03',1 if req<=sa2 else 0,1)
# V5S04 coverage_state exactly 3
cs={x for x in emembers(form('define-closed-enum coverage_state')) if x.isupper()}
out('V5S04',1 if cs=={'PRESENT','EXPLICITLY_ABSENT','UNKNOWN'} else 0,1)
# V5S05 NegativeEvidence/1 fields
ne=set(fields(form('define-record NegativeEvidence/1')))
out('V5S05',1 if {'census_space_ref','issuing_authority_ref','source_ref','scope','observation_time','completeness_or_serial_rule_ref','evidence_artifact_digest','expiry','signature'}<=ne else 0,1)
# V5S06 required-refs AUTHENTICATED_SERIAL_SPACE
mss=re.search(r'\(:AUTHENTICATED_SERIAL_SPACE([^)]*)\)',form('define-required-refs CensusSpaceClassification/1'))
sr=set(mss.group(1).split()) if mss else set()
out('V5S06',1 if {'serial_authority_ref','completeness_assertion_ref','serial_position_semantics_ref'}<=sr else 0,1)
# V5S07 IndependenceAssuranceProfile IA-0/1/2 distinct enum
iap=form('define-closed-enum IndependenceAssuranceProfile')
ia=set(re.findall(r'\(:(IA-[0-2])',iap))
out('V5S07',1 if (ia=={'IA-0','IA-1','IA-2'} and 'define-closed-enum SemanticAdmissionAssuranceProfile' in code and iap) else 0,1)
# V5S08 ActorIndependenceEvidence/1 crypto-bind + invariant
aie=set(fields(form('define-record ActorIndependenceEvidence/1')))
inv=form('define-invariant :V5I-D3-bind')
bind={'actor_identity','actor_kid','actor_public_key','control_domain_id','evidence_subject_digest'}
out('V5S08',1 if (bind<=aie and all(k in inv for k in bind)) else 0,1)
# V5S09 issuer registry
ie=set(fields(form('define-record IssuerEntry/1')))
out('V5S09',1 if (form('define-record TrustedIssuerRegistry/1') and {'issuer_id','issuer_public_key','issuer_authority','scope','revocation_ref'}<=ie) else 0,1)
# V5S10 partition deterministic + fail-closed
alg=form('define-algorithm control-domain-partition')
out('V5S10',1 if (('union-find' in alg or 'connected components' in alg) and 'deterministic' in alg and 'fail-closed' in alg and 'UNKNOWN' in alg) else 0,1)
# V5S11 quorum counts components not kids
qp=form('define-quorum-predicate mesh-independence-quorum')
out('V5S11',1 if ('control-domain-partition' in qp and 'distinct-components' in qp and 'distinct-valid-kids' in qp) else 0,1)
# V5S12 ArgumentRecord/1 non-circular
arf=set(fields(form('define-record ArgumentRecord/1')))
out('V5S12',1 if ('claim_ref' in arf and 'argument_ref' not in arf) else 0,1)
# V5S13 InterpretiveProfile/1 expanded
ip=set(fields(form('define-record InterpretiveProfile/1')))
out('V5S13',1 if {'methodology_canons','precedence_stance','applicability','authority_basis','conflict_handling','adoption_status'}<=ip else 0,1)
# V5S14 ClaimRecord/1 binding
crf=set(fields(form('define-record ClaimRecord/1')))
out('V5S14',1 if {'statement_ref','interpretive_profile_ref','argument_refs'}<=crf else 0,1)
# V5S15 constitution reference adds nothing
cref=form('define-constitution-reference v1.5-interpretive-binding')
out('V5S15',1 if (':adds-primitive nil' in cref and ':adds-engine nil' in cref and ':adds-gate nil' in cref and ':represents-primitive :argument' in cref) else 0,1)
# V5S16 reference closure (records + enums)
drec=set(re.findall(r'\(define-record\s+([A-Za-z0-9_]+/1)',code))
den=set(re.findall(r'\(define-closed-enum\s+([A-Za-z0-9_]+)',code))
prim={'id','ref','sha256','sig','instant','scope','semver','text','keyword','pubkey','kid','anchor','usc-id','duration','uncertainty','canon','requirement','quorum-spec','null'}
unres=set()
for tm in re.finditer(r':type\s+(\([^()]*\)|[A-Za-z0-9_+/.-]+)',code):
    t=tm.group(1);atoms=[]
    if t.startswith('('):
        inner=t.strip('()').split();head=inner[0] if inner else ''
        if head=='member': continue
        atoms=[a for a in inner[1:] if a!='null'] if head in ('list','or') else inner
    else: atoms=[t]
    for a in atoms:
        if a in prim or a.startswith(':') or a in drec or a in den: continue
        unres.add(a)
out('V5S16',len(unres),0)
for i,a,e in R: print(f"{i}|{a}|{e}")
PYV5S
)

echo "### SUMMARY: checks=$n pass=$pass fail=$fail"
[ "$fail" -eq 0 ] && { echo "### EXIT 0 — V1.5 DOCUMENT/REFERENCE CONSISTENCY PASS (CANDIDATE· ΟΧΙ semantic/legal/security/qualification proof)"; exit 0; } || { echo "### EXIT 1 — DEVIATIONS PRESENT"; exit 1; }
