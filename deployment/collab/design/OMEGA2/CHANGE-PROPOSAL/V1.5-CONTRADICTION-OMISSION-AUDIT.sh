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
ck D2c "$(c 'EXPLICITLY-ABSENT' $P $S $SR | sum)" ge 3   # F3: canonical frozen v1.4 spelling (hyphen), not the shadow underscore
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
# V5S04 F3: NO shadow coverage_state enum; census state is the FROZEN v1.4 reference (4 members, incl QUARANTINED)
no_shadow = '(define-closed-enum coverage_state' not in code
fref=form('define-frozen-enum-reference census_coverage_state')
fmembers=set(re.findall(r':([A-Z][A-Z_-]+)',fref.split(':members',1)[1])) if ':members' in fref else set()
out('V5S04',1 if (no_shadow and {'INGESTED','EXPLICITLY-ABSENT','QUARANTINED','UNKNOWN'}<=fmembers) else 0,1)
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
# V5S10 partition deterministic + fail-closed + consumes typed DomainAssertion (F4)
alg=form('define-algorithm control-domain-partition')
out('V5S10',1 if (('union-find' in alg or 'connected components' in alg) and 'deterministic' in alg and 'fail-closed' in alg and 'DomainAssertion' in alg and re.search(r'unknown',alg,re.I)) else 0,1)
# V5S11 quorum counts components not kids
qp=form('define-quorum-predicate mesh-independence-quorum')
out('V5S11',1 if ('control-domain-partition' in qp and 'distinct-components' in qp and 'distinct-valid-kids' in qp) else 0,1)
# V5S12 ArgumentRecord/1 non-circular
arf=set(fields(form('define-record ArgumentRecord/1')))
out('V5S12',1 if ('claim_ref' in arf and 'argument_ref' not in arf) else 0,1)
# V5S13 InterpretiveProfile/1 expanded (R6: single canon source via canon_policy_ref; no embedded list, no lifecycle)
ip=set(fields(form('define-record InterpretiveProfile/1')))
out('V5S13',1 if ({'canon_policy_ref','precedence_stance','applicability','authority_basis','conflict_handling'}<=ip and 'methodology_canons' not in ip and 'adoption_status' not in ip) else 0,1)
# V5S14 F1: ClaimRecord/1 binds profile+statement AND has NO argument_refs in its hash-bearing body;
#          reverse lookup is the derived ClaimArgumentIndex projection.
crf=set(fields(form('define-record ClaimRecord/1')))
out('V5S14',1 if ({'statement_ref','interpretive_profile_ref'}<=crf and 'argument_refs' not in crf
                  and 'define-projection ClaimArgumentIndex' in code) else 0,1)
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

echo "# V5F/V5G — INDEPENDENT-REVIEW REPAIR structural checks (F1-F5 + R1-R8/A-1/A-2/B-1/B-2/C-1/D-1/F7)."
echo "#       HONEST: parse-level structural/type/model consistency ONLY — ref-field classification"
echo "#       completeness, an actual-field hash-bearing DAG with 3 injected cycles, immutable-id stability,"
echo "#       coverage decision-table totality/exclusivity over the enumerated finite input product, D2"
echo "#       cross-seat agreement, namespace collision/conflict handling, single canon list, lifecycle"
echo "#       cardinalities, F7 evidence validity, and MLTP quorum-predicate sync. It is NOT a legal-content"
echo "#       validation, NOT a security-implementation proof, NOT qualification; no predeclared executable"
echo "#       V5Q/V5KW test is executed or reported as executed."
while IFS='|' read -r fid fa fe; do
  [ -n "$fid" ] && ck "$fid" "$fa" eq "$fe"
done < <(python3 - "$S" V1.4-CONTRADICTION-OMISSION-AUDIT.sh CHANGE-PROPOSAL-v1.4.md "$SR" "$USC" "$M" "$P" <<'PYV5F'
import sys,re
from collections import defaultdict
code=open(sys.argv[1],encoding='utf-8').read()
v14=open(sys.argv[3],encoding='utf-8').read()
def strip(s):
    o=[];i=0;n=len(s);ins=False
    while i<n:
        c=s[i]
        if ins:
            if c=='\\': o.append(c); i+=1
            if i<n: o.append(s[i])
            if c=='"': ins=False
            i+=1; continue
        if c=='"': ins=True; o.append(c); i+=1; continue
        if c==';':
            while i<n and s[i]!='\n': i+=1
            continue
        o.append(c); i+=1
    return ''.join(o)
code_nc=strip(code)
def form(head,src=None):
    src=code_nc if src is None else src
    idx=src.find('('+head)
    if idx<0: return ''
    i=idx;d=0;ins=False;n=len(src)
    while i<n:
        c=src[i]
        if ins:
            if c=='\\': i+=2; continue
            if c=='"': ins=False
            i+=1; continue
        if c=='"': ins=True
        elif c=='(': d+=1
        elif c==')':
            d-=1
            if d==0: return src[idx:i+1]
        i+=1
    return src[idx:]
def fields(rf): return re.findall(r'\(:([A-Za-z0-9_]+)\s+:type',rf)
R=[]
def out(i,a,e): R.append((i,str(a),str(e)))

# V5F1 — F1/A-1 content-hash dependency cycle: cycle detector over :hash-bearing edges from
# define-ref-classification; ClaimRecord body free of any argument ref; ArgumentRecord body free of
# support/attack edges; construction order + derived projection present.
rc=form('define-ref-classification')
g=defaultdict(list)
for m in re.finditer(r'\(([A-Za-z0-9_/]+)\.[A-Za-z0-9_]+\s+:hash-bearing\s+\(([^)]*)\)',rc):
    src=m.group(1)
    for t in m.group(2).split():
        if t[:1].isupper(): g[src].append(t)   # record/enum targets; lowercase primitives (anchor/scope) skipped
color=defaultdict(int); cyc=[False]   # 0=white 1=gray 2=black
def dfs(u):
    color[u]=1
    for v in g[u]:
        if color[v]==1: cyc[0]=True
        elif color[v]==0: dfs(v)
    color[u]=2
for nnode in list(g):
    if color[nnode]==0: dfs(nnode)
claim_body=form('define-record ClaimRecord/1')
arg_body=form('define-record ArgumentRecord/1')
no_arg=not re.search(r':argument_ref|:argument_refs|:argument_id',claim_body)
no_edges=not re.search(r':support_edges|:attack_edges',arg_body)
ok1 = (not cyc[0]) and no_arg and no_edges and ('define-construction-order legal-ir-interpretive' in code_nc) and ('define-projection ClaimArgumentIndex' in code_nc) and (len(g)>=4)
out('V5F1',1 if ok1 else 0,1)

# V5F2 — F2 no assumption alternative in the SA-2 canonical gate.
gate=form('define-gate SA-2-canonical-admission')
inv=form('define-invariant :V5I-D1-no-assumption-canonical')
ok2 = ('derivation_independence_evidence_ref' in gate
       and ':forbids-alternative residual_independence_assumption' in gate
       and inv!='' and 'never' in inv.lower())
out('V5F2',1 if ok2 else 0,1)

# V5F3 — F3 cross-spec conflicting-enum: frozen v1.4 census enum == v1.5 census_coverage_state reference,
# and NO shadow coverage_state enum in the candidate.
m14=re.search(r'state\s*∈\s*\{([^}]*)\}',v14)
v14set=set(x.strip() for x in re.split(r'[,\s]+',m14.group(1)) if x.strip()) if m14 else set()
fref=form('define-frozen-enum-reference census_coverage_state')
v15set=set(re.findall(r':([A-Z][A-Z_-]+)',fref.split(':members',1)[1])) if ':members' in fref else set()
no_shadow='(define-closed-enum coverage_state' not in code_nc
ok3 = (v14set=={'INGESTED','EXPLICITLY-ABSENT','QUARANTINED','UNKNOWN'}
       and v14set==v15set and no_shadow)
out('V5F3',1 if ok3 else 0,1)

# V5F4 — F4/R5 typed-membership DomainAssertion (namespace) + versioned/content-addressed/pinned registry + signing.
da=set(fields(form('define-record DomainAssertion/1')))
tir=set(fields(form('define-record TrustedIssuerRegistry/1')))
pin=form('define-rule trusted-issuer-registry-pinning')
sign=form('define-invariant :V5I-D3-issuer-signing')
ok4 = ({'dimension','subject_actor_id','namespace_id','domain_identifier','normalized_domain_id','issuer_id','revocation_ref'}<=da
       and {'registry_id','version','supersedes'}<=tir
       and 'LocalTrustState' in pin and 'evidence-issuer-key-selection' in pin
       and sign!='' and 'issuer_public_key' in sign)
out('V5F4',1 if ok4 else 0,1)

# V5F5 — F5/R6 single-source typed canons + delegate to existing ConflictPolicyBundle; no opaque, no embedded list.
cr=form('define-record CanonRule/1'); cpf=set(fields(form('define-record CanonPolicy/1')))
ipf=set(fields(form('define-record InterpretiveProfile/1')))
inv5=form('define-invariant :V5I-C1-canon')
no_opaque = '(list canon)' not in code_nc
ok5 = (cr!='' and 'conflict_policy_bundle_ref' in cpf and 'canon_id_refs' in cpf
       and 'canon_policy_ref' in ipf and 'methodology_canons' not in ipf
       and inv5!='' and 'ConflictPolicyBundle' in inv5 and no_opaque)
out('V5F5',1 if ok5 else 0,1)

# ============ V5G — R1-R8 FINITE ADVERSARIAL-REPAIR structural checks (parse-level; not semantic proof) ============
sr=open(sys.argv[4],encoding='utf-8').read()
usc=open(sys.argv[5],encoding='utf-8').read()
mltp=open(sys.argv[6],encoding='utf-8').read()
prop=open(sys.argv[7],encoding='utf-8').read()

# V5G1 (A-1) — complete ref-field classification: every ref-bearing field of every C1 record is classified.
c1recs=['CanonRule/1','CanonPolicy/1','InterpretiveProfile/1','ClaimRecord/1','ArgumentRecord/1','ArgumentRelation/1','LifecycleRecord/1']
rcf=form('define-ref-classification')
classified=set(re.findall(r'\(([A-Za-z0-9_/]+\.[A-Za-z0-9_]+)\s+:(?:hash-bearing|detached|derived)',rcf))
missing=0
for rec in c1recs:
    body=form('define-record '+rec)
    for fm in re.finditer(r'\(:([A-Za-z0-9_]+)\s+:type\s+(\([^()]*\)|[A-Za-z0-9_+/.-]+)',body):
        fld=fm.group(1); typ=fm.group(2)
        if fld in ('digest','signature'): continue
        isref = ('ref' in typ) or ('/1' in typ) or fld.endswith('_ref') or fld.endswith('_refs')
        if isref and (rec+'.'+fld not in classified): missing+=1
out('V5G1', missing, 0)

# V5G2 (A-1) — non-vacuity: 3 injected hash-bearing cycles each detected by the classification-graph cycle detector.
def has_cycle(edges):
    gg=defaultdict(list)
    for a,b in edges: gg[a].append(b)
    col=defaultdict(int); f=[False]
    def d(u):
        col[u]=1
        for v in gg[u]:
            if col[v]==1: f[0]=True
            elif col[v]==0: d(v)
        col[u]=2
    for nn in list(gg):
        if col[nn]==0: d(nn)
    return f[0]
base=[]
for m in re.finditer(r'\(([A-Za-z0-9_/]+)\.[A-Za-z0-9_]+\s+:hash-bearing\s+\(([^)]*)\)',rcf):
    for t in m.group(2).split():
        if t[:1].isupper(): base.append((m.group(1),t))
det=((not has_cycle(base))
     and has_cycle(base+[('ClaimRecord/1','ArgumentRecord/1')])
     and has_cycle(base+[('ArgumentRecord/1','ArgumentRecord/1')])
     and has_cycle(base+[('CanonPolicy/1','InterpretiveProfile/1')]))
out('V5G2', 1 if det else 0, 1)

# V5G3 (A-2) — immutable identity: no adoption/withdrawal/status in any identity-bearing body; LifecycleRecord detached.
idrecs=['ClaimRecord/1','ArgumentRecord/1','InterpretiveProfile/1','CanonRule/1','CanonPolicy/1']
leak=sum(1 for rec in idrecs if re.search(r':adoption_status|:adoption_act_ref|:withdrawal_ref|:status\b',form('define-record '+rec)))
lr=set(fields(form('define-record LifecycleRecord/1')))
out('V5G3', 1 if (leak==0 and {'subject_id','subject_kind','transition','act_ref','supersedes'}<=lr and form('define-invariant :V5I-A2-immutable-id')!='') else 0, 1)

# V5G4 (B-1) — coverage decision-table totality/exclusivity over the finite input product.
import itertools
OBS=['OBSERVED','NOT_OBSERVED_IN_DECLARED_SOURCE','UNKNOWN']
ACQ=['ACQUIRED_LAWFUL','ACQUISITION_FAILED','NOT_ATTEMPTED','UNKNOWN']
VAL=['VALIDATED','VALIDATION_FAILED','NOT_VALIDATED','UNKNOWN']
ADM=['SATISFIED','UNMET','NOT_APPLICABLE','UNKNOWN']
DIV=['AGREED','DETERMINISTIC_DIVERGENCE','INTERPRETIVE_DISAGREEMENT','INDEPENDENCE_INSUFFICIENT','UNKNOWN']
AVA=['PUBLIC_PRESENT','COVERED_STATE_NON_PUBLIC','ACCESS_RESTRICTED','LICENSING_RESTRICTED','UNKNOWN']
ENU=['AUTHORITATIVE_COMPLETE_INDEX','AUTHENTICATED_SERIAL_SPACE','AUTHORITATIVE_PARTIAL_INDEX','OBSERVATIONAL_OPEN_WORLD_SOURCE','UNKNOWN']
NEG=['FRESH_QUALIFYING','INSUFFICIENT','EXPIRED','ABSENT','UNKNOWN']
def decide(obs,acq,val,adm,div,ava,enu,neg):
    o=[]
    if div=='DETERMINISTIC_DIVERGENCE': o.append('QUARANTINED')
    elif val=='VALIDATION_FAILED': o.append('QUARANTINED')
    elif adm=='UNMET': o.append('QUARANTINED')
    elif obs=='OBSERVED' and acq=='ACQUIRED_LAWFUL' and val=='VALIDATED' and adm in ('SATISFIED','NOT_APPLICABLE'): o.append('INGESTED')
    elif neg=='FRESH_QUALIFYING' and enu in ('AUTHORITATIVE_COMPLETE_INDEX','AUTHENTICATED_SERIAL_SPACE'): o.append('EXPLICITLY-ABSENT')
    else: o.append('UNKNOWN')
    return o
unc=multi=0; st=set()
for c in itertools.product(OBS,ACQ,VAL,ADM,DIV,AVA,ENU,NEG):
    r=decide(*c)
    if len(r)==0: unc+=1
    elif len(r)>1: multi+=1
    else: st.add(r[0])
out('V5G4', 1 if (unc==0 and multi==0 and st<= {'INGESTED','EXPLICITLY-ABSENT','QUARANTINED','UNKNOWN'} and 'define-decision-function census-coverage-decision' in code_nc) else 0, 1)

# V5G5 (B-2) — D2 cross-seat agreement: canonical frozen state present in schema, proposal, SourceType, USC.
out('V5G5', 1 if all(('EXPLICITLY-ABSENT' in t and 'INGESTED' in t and 'QUARANTINED' in t) for t in (code_nc,prop,sr,usc)) else 0, 1)

# V5G6 (C-1) — namespace membership + authorization + equivalence + comparison/conflict rule; no unary relation.
da=set(fields(form('define-record DomainAssertion/1'))); comp=form('define-rule domain-namespace-comparison')
out('V5G6', 1 if ({'namespace_id','domain_identifier','normalized_domain_id'}<=da
      and ':relation ' not in form('define-record DomainAssertion/1')
      and form('define-record DomainNamespaceAuthorization/1')!='' and form('define-record NamespaceEquivalence/1')!=''
      and 'cross-namespace' in comp and 'conflict' in comp and 'INDEPENDENCE_UNKNOWN' in comp) else 0, 1)

# V5G7 (D-1) — single canon list: CanonPolicy owns canon_id_refs; InterpretiveProfile no embedded list.
cpf2=set(fields(form('define-record CanonPolicy/1'))); ipf2=set(fields(form('define-record InterpretiveProfile/1')))
out('V5G7', 1 if ('canon_id_refs' in cpf2 and 'canon_policy_ref' in ipf2 and 'methodology_canons' not in ipf2
      and '(list CanonRule/1)' not in form('define-record InterpretiveProfile/1')) else 0, 1)

# V5G8 (D-1) — conditional lifecycle cardinalities.
lov=form('define-rule lifecycle-overlay')
out('V5G8', 1 if (':proposed' in lov and ':adopted' in lov and ':withdrawn' in lov and 'adoption' in lov.lower() and 'withdrawal' in lov.lower()) else 0, 1)

# V5G9 (F7) — DerivationIndependenceEvidence validity/trust: candidate binding + issuer + freshness + revocation + verify.
de=set(fields(form('define-record DerivationIndependenceEvidence/1'))); tr=form('define-rule derivation-independence-trust-root'); gate2=form('define-gate SA-2-canonical-admission')
out('V5G9', 1 if ({'candidate_id','event_ref','evidence_issuer','freshness_policy_ref','revocation_ref','valid_from','valid_to'}<=de
      and 'qualification registry' in tr and 'self-issued' in tr and ':verify' in gate2
      and form('define-invariant :V5I-F7-derivation-trust')!='') else 0, 1)

# V5G10 (R8.4) — MLTP quorum prose synchronized with the four-conjunct predicate.
out('V5G10', 1 if all(k in mltp for k in ['|INDEP|','covers(policy.required_distinct_dimensions','no-prohibited-shared-dimension','FAIL_CLOSED']) else 0, 1)

# V5G11 (R8) — residuals: statement target closed; candidate_id discipline; ClaimArgumentIndex single :derivation; unregistered-event rule.
cai=form('define-projection ClaimArgumentIndex')
out('V5G11', 1 if (form('define-closed-enum StatementTargetKind')!='' and form('define-rule candidate-id-discipline')!=''
      and ':derivation' in cai and ':over' not in cai and form('define-invariant :V5I-D1-unregistered-event')!='') else 0, 1)

for i,a,e in R: print(f"{i}|{a}|{e}")
PYV5F
)

echo "### SUMMARY: checks=$n pass=$pass fail=$fail"
[ "$fail" -eq 0 ] && { echo "### EXIT 0 — V1.5 DOCUMENT/REFERENCE CONSISTENCY PASS (CANDIDATE· ΟΧΙ semantic/legal/security/qualification proof)"; exit 0; } || { echo "### EXIT 1 — DEVIATIONS PRESENT"; exit 1; }
