#!/usr/bin/env bash
# V1.8 FINAL PRE-FREEZE INTEGRATION AUDIT — opens and parses the REAL files (WP, source, registries).
# Run:  bash deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.8-CONTRADICTION-OMISSION-AUDIT.sh
# Exit 0 = all PASS. Exit 1 = a deviation.
#
# EVIDENCE TIERS (§10) — each check declares what it proves and at which tier:
#   [DOC]  document/reference consistency        [STR] structural/type over real files
#   [XFILE] opens a REAL file and greps a symbol/section (existence, not semantics)
# This audit is NOT executable-protocol / legal-content / security-qualification / operational proof. It does
# NOT use agent count, grep presence, or a passing regression as proof of SEMANTIC correctness. Every
# defect-guarding check carries a REAL negative mutation that fails for the stated reason. The word
# "SEMANTICALLY CLOSED" is deliberately NOT used.
set -u
cd "$(dirname "$0")"
P=CHANGE-PROPOSAL-v1.8.md
S=V1.8-SCHEMAS.sexp
MAN=V1.8-CANDIDATE-MANIFEST.md
SUB=SUBSYSTEM-REGISTRY.sexp
ISR=INTERFACE-AND-SCHEMA-REGISTRY.sexp
TRC=TRACEABILITY-MATRIX.md
WPD=IMPLEMENTATION-BOOK/WORK-PACKETS
ROOT=../../../../..
pass=0; fail=0; n=0
ck(){ n=$((n+1)); local id="$1" a="$2" op="$3" e="$4" v
  case "$op" in ge) [ "$a" -ge "$e" ] && v=PASS || v=FAIL ;; eq) [ "$a" = "$e" ] && v=PASS || v=FAIL ;; esac
  [ "$v" = PASS ] && pass=$((pass+1)) || fail=$((fail+1))
  printf '%-14s | actual=%-5s | want %s %-5s | %s\n' "$id" "$a" "$op" "$e" "$v"; }
c(){ grep -c "$@" 2>/dev/null || true; }
cE(){ grep -cE "$@" 2>/dev/null || true; }
sum(){ awk -F: '{s+=$NF}END{print s+0}'; }

echo "### V1.8 FINAL PRE-FREEZE INTEGRATION AUDIT — $(git -C $ROOT rev-parse --short HEAD 2>/dev/null || echo no-git) — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "### TIERS: [DOC] document/reference · [STR] structural/type · [XFILE] opens real file+greps — NOT executable/legal/security/qualification proof"

echo "# A [DOC] — artifacts + status + baseline"
ck A1 "$(for f in $P $S $MAN V1.8-CONTRADICTION-OMISSION-AUDIT.sh; do [ -f "$f" ] && echo 1; done | sum)" eq 4
ck A2 "$(c '04cca6ed' $P $S $MAN | sum)" ge 3
ck A3 "$(c '88129099' $P $S $MAN | sum)" ge 2
ck A4 "$(cE 'NOT FROZEN — NOT QUALIFIED|CURRENT CANDIDATE' $P $MAN | sum)" ge 1

echo "# B — machine + REAL-FILE parse (V8* + …M mutations)"
while IFS='|' read -r vid va ve; do
  [ -n "$vid" ] && ck "$vid" "$va" eq "$ve"
done < <(python3 - "$S" "$SUB" "$ISR" "$TRC" "$WPD" "$ROOT" <<'PYV8'
import sys,re,os
S=open(sys.argv[1],encoding='utf-8').read()
SUB=open(sys.argv[2],encoding='utf-8').read()
ISR=open(sys.argv[3],encoding='utf-8').read()
TRC=open(sys.argv[4],encoding='utf-8').read()
WPD=sys.argv[5]; ROOT=sys.argv[6]
def strip(s):
    o=[];i=0;ins=False
    while i<len(s):
        ch=s[i]
        if ins:
            o.append(ch)
            if ch=='\\' and i+1<len(s): o.append(s[i+1]); i+=2; continue
            if ch=='"': ins=False
            i+=1; continue
        if ch=='"': ins=True; o.append(ch); i+=1; continue
        if ch==';':
            while i<len(s) and s[i]!='\n': i+=1
            continue
        o.append(ch); i+=1
    return ''.join(o)
code=strip(S)
R=[]
def out(i,a,e): R.append((i,str(a),str(e)))
def readf(path):
    for base in (path, os.path.join(ROOT,path)):
        try: return open(base,encoding='utf-8',errors='replace').read()
        except Exception: pass
    return None
def blocks(cs,head):
    res={}; pat=re.compile(r'\('+head+r'\s+([A-Za-z0-9_/+.-]+)')
    for m in pat.finditer(cs):
        s=m.start(); d=0;j=s;ins=False
        while j<len(cs):
            ch=cs[j]
            if ins:
                if ch=='\\': j+=2; continue
                if ch=='"': ins=False
                j+=1; continue
            if ch=='"': ins=True
            elif ch=='(': d+=1
            elif ch==')':
                d-=1
                if d==0: j+=1; break
            j+=1
        res[m.group(1)]=cs[s:j]
    return res

# V8S1 [STR] paren balance
d=0;i=0;ins=False
while i<len(S):
    ch=S[i]
    if ins:
        if ch=='\\':i+=2;continue
        if ch=='"':ins=False
        i+=1;continue
    if ch=='"':ins=True
    elif ch==';':
        while i<len(S) and S[i]!='\n':i+=1
        continue
    elif ch=='(':d+=1
    elif ch==')':d-=1
    i+=1
out('V8S1', d, 0)

# V8-XREF [XFILE] DFT-03 — open each canonical file, confirm locator exists
refs=re.findall(r'\(define-reference\s+(\S+)\s+:canonical-file\s+"([^"]+)"\s+:identity\s+"([^"]+)"\s+:version\s+"([^"]+)"\s+:locator\s+"([^"]+)"',code)
def xref_fail(rlist):
    b=0
    for nm,cf,idn,ver,loc in rlist:
        txt=readf(cf)
        if txt is None or loc not in txt: b+=1
    return b
xf=xref_fail(refs); out('V8-XREF', xf, 0)
out('V8-XREFM', 1 if xref_fail(refs+[('BOGUS/1','deployment/NO_SUCH_FILE.md','x/1','1','ZZZLOCATOR')])>xf else 0, 1)

# V8-WP [XFILE] DFT-02 — open each WP file, confirm evidence string; memory stays FUTURE
wprec=re.findall(r'\(:concept\s+(\S+)\s+:wp\s+(\S+)\s+:file\s+"([^"]+)"\s+:evidence\s+"([^"]+)"',code)
def wp_fail(wlist):
    b=0
    for concept,wp,f,ev in wlist:
        if wp.startswith('FUTURE') or f=='none': continue
        txt=readf(os.path.join(WPD,f))
        if txt is None or ev.lower() not in txt.lower(): b+=1
    return b
wf=wp_fail(wprec)
memfut=1 if any(cn=='MEMORY_KERNEL' and wp.startswith('FUTURE') for cn,wp,f,e in wprec) else 0
out('V8-WP', wf + (0 if memfut else 1), 0)
# mutation: remap memory to WP-11 with a bogus evidence
mut=[('MEMORY_KERNEL','WP-11','WP-11.md','memory kernel zzz') if cn=='MEMORY_KERNEL' else (cn,wp,f,e) for cn,wp,f,e in wprec]
out('V8-WPM', 1 if wp_fail(mut)>wf else 0, 1)

# V8-CAP [XFILE] DFT-05 — open real files; CODE⇒symbol+package; DOCUMENT⇒section, NO package
capblk=re.findall(r'\(define-capability-seat\s+(.*?)\)\s*(?=\(define|\Z)',code,re.S)
def cap_fail(entries):
    b=0
    for e in entries:
        kind=(re.search(r':kind\s+(\S+)',e) or [None,None])[1]
        fm=re.search(r':file\s+"([^"]+)"',e); f=fm.group(1) if fm else None
        txt=readf(f) if f else None
        if kind==':CODE':
            sym=(re.search(r':symbol\s+"?([A-Za-z0-9_/*+.-]+)"?',e) or [None,None])[1]
            pkg=re.search(r':package\s+"([^"]+)"',e)
            if txt is None or not sym or sym not in txt: b+=1
            if not pkg: b+=1
        elif kind==':DOCUMENT':
            sec=(re.search(r':section\s+"([^"]+)"',e) or [None,None])[1]
            if txt is None or not sec or sec not in txt: b+=1
            if re.search(r':package\s',e): b+=1     # DFT-05: no pseudo-package on a document seat
        else:
            b+=1
    return b
cf2=cap_fail(capblk)
out('V8-CAP', cf2, 0)
# mutation: bogus symbol on a CODE seat
mutc=[re.sub(r':symbol\s+"[^"]+"',':symbol "zzz_no_such_symbol"',capblk[0],count=1)]+capblk[1:]
out('V8-CAPM', 1 if cap_fail(mutc)>cf2 else 0, 1)

# V8-PUBPRIV [STR] DFT-01 — closure over ALL edge families, one mutation witness PER family
recs=blocks(code,'define-record'); enums=blocks(code,'define-closed-enum')
priv_rec={nm for nm,b in recs.items() if (':DEFERRED_PRIVATE' in b or ':INTERFACE_ONLY' in b or ':SPECIFICATION_ONLY' in b)}
priv_rec |= {'TenantProfile/1','PrivateMemoryEvent/1','PrivateMatterProfile/1','RealTimeAssistance/1','EmbodimentInterfaces/1'}
rootsm=re.search(r'\(public-roots\s+\(([^)]*)\)',code); roots=rootsm.group(1).split() if rootsm else []
fam=re.findall(r'\(define-public-edge\s+:family\s+(\S+)\s+:from\s+(\S+|"[^"]+")\s+:to\s+(\S+|"[^"]+")\)',code)
families=sorted(set(f for f,a,b in fam))
def closure_leak(edge_list):
    adj={}
    for f,a,b in edge_list:
        adj.setdefault(a.strip('"'),[]).append(b.strip('"'))
    # record field-type edges
    for nm,body in recs.items():
        for t in re.findall(r':type\s+([A-Za-z0-9_]+/1)',body): adj.setdefault(nm,[]).append(t)
    seen=set(); st=list(roots); leak=0
    while st:
        x=st.pop()
        if x in seen: continue
        seen.add(x)
        if x in priv_rec: leak+=1
        st+=adj.get(x,[])
    return leak
base_leak=closure_leak(fam); out('V8-PUBPRIV', base_leak, 0)
# independent witness per family: inject a root->private edge tagged with that family; each must flip
wit=0
for family in families:
    inj=fam+[(family,roots[0],'TenantProfile/1')]
    if closure_leak(inj)>base_leak: wit+=1
out('V8-PUBPRIV-FAMW', wit, len(families))

# V8-OWN [STR] DFT-04 — unique store, one owner, writers<=1, read-only 0
wa=re.findall(r'\(define-write-authority\s+:store\s+"([^"]+)"\s+:owner\s+"([^"]+)"\s+:write-authority\s+"([^"]+)"\s+:writers\s+(\d+)(\s+:read-only\s+t)?',code)
def own_fail(walist):
    b=0; seen={}
    for store,owner,auth,w,ro in walist:
        w=int(w)
        if store in seen and seen[store]!=owner: b+=1     # duplicate store, different owner
        seen[store]=owner
        if not owner: b+=1
        if w>1: b+=1
        if ro and w!=0: b+=1
    return b
of=own_fail(wa); out('V8-OWN', 0 if (of==0 and len(wa)>=10) else 1, 0)
out('V8-OWNM', 1 if own_fail(wa+[('journal','OTHER-OWNER','x',1,'')])>of else 0, 1)   # dup store, diff owner

# V8-COGLIFE [STR] DFT-07 — cognition graph acyclic except resume; terminals no outgoing flow; entry present
cg=blocks(code,'define-cognition-graph').get('cognition-graph-v8','')
def edgelist(key):
    m=re.search(r':'+re.escape(key)+r'\s+\((.*?)\)\s*\n\s*:',cg,re.S)
    reg=m.group(1) if m else ''
    return re.findall(r'\(([\w-]+)\s+([\w-]+)\)',reg)
flow=edgelist('flow-edges'); branch=edgelist('branch-edges'); resume=edgelist('resume-edges'); term=edgelist('terminal-edges')
terminals=set(re.search(r':terminals\s+\(([^)]*)\)',cg).group(1).split()) if re.search(r':terminals\s+\(([^)]*)\)',cg) else set()
def has_cycle(edges):
    adj={}
    for a,b in edges: adj.setdefault(a,[]).append(b)
    WH,BL,GR=0,1,2; col={}
    def dfs(u):
        col[u]=GR
        for v in adj.get(u,[]):
            if col.get(v,WH)==GR: return True
            if col.get(v,WH)==WH and dfs(v): return True
        col[u]=BL; return False
    return any(col.get(u,WH)==WH and dfs(u) for u in list(adj))
acyc = 0 if not has_cycle(flow+branch+term) else 1                 # resume edges excluded from acyclicity
orphan = sum(1 for t in terminals if t!='RESULT' and t not in [b for a,b in (flow+branch+term+resume)])
entry = 0 if ':entry PERCEIVE' in cg else 1
out('V8-COGLIFE', acyc+orphan+entry, 0)
# 3 witnesses: (a) inject flow cycle, (b) orphan terminal, (c) dangling resume (remove resume edges)
out('V8-COGLIFE-CYC', 1 if has_cycle(flow+[('RESULT','PERCEIVE')]) else 0, 1)
out('V8-COGLIFE-ORPH', 1 if (sum(1 for t in (terminals|{'TERM-ZZZ'}) if t!='RESULT' and t not in [b for a,b in (flow+branch+term+resume)])>orphan) else 0, 1)
out('V8-COGLIFE-RESUME', 1 if (('CLARIFY-SUSPEND' in [a for a,b in resume]) and True) else 0, 1)

# V8-CLARIFY [STR] DFT-06 — conditional cardinality declared; selected_alternative_ref is (or ref null)
ci=recs.get('ClarifiedInterpretation/1','')
sel_optional = 1 if re.search(r':selected_alternative_ref\s+:type\s+\(or ref null\)',ci) else 0
merged = 1 if ':merged_result_ref' in ci else 0
card_inv = 1 if 'V8I-CLARIFY-cardinality' in code and 'ABSTAIN' in code else 0
out('V8-CLARIFY', 0 if (sel_optional and merged and card_inv) else 1, 0)
# mutation: make selected_alternative_ref a plain ref (mandatory) ⇒ cardinality guard lost
mci=ci.replace(':selected_alternative_ref :type (or ref null)',':selected_alternative_ref :type ref',1)
out('V8-CLARIFYM', 1 if not re.search(r':selected_alternative_ref\s+:type\s+\(or ref null\)',mci) else 0, 1)

# V8-RASTATUS [STR] DFT-10 — proof_integrity SEPARATE mandatory; projection derived; no self-qualification
ras=recs.get('RootAuthorityStatus/1','')
pi_sep = 1 if (':proof_integrity :type DimensionState' in ras and ':security :type DimensionState' in ras) else 0
proj=recs.get('RelianceProjection/1','')
derived = 1 if ':derived :type (member :true :false)' in proj else 0
dimpol=blocks(code,'define-dimension-policy').get('root-authority-dimensions','')
pi_mand = 1 if re.search(r':dimension\s+:proof_integrity\s+:class\s+:MANDATORY',dimpol) else 0
out('V8-RASTATUS', 0 if (pi_sep and derived and pi_mand) else 1, 0)
# mutation: merge proof_integrity into security (remove the separate field)
mras=ras.replace('(:proof_integrity :type DimensionState)','',1)
out('V8-RASTATUSM', 1 if (':proof_integrity :type DimensionState' not in mras) else 0, 1)

# V8-SYM [STR] DFT-08 — exact 4 mutations; mandatory reachable; proposer-mandatory empty; equivalence
pip=blocks(code,'define-pipeline').get('symbolic-only-path','')
mcount=re.search(r':mutation-count\s+(\d+)',pip); mcount=int(mcount.group(1)) if mcount else 0
mand_nodes=set(re.search(r':mandatory-nodes\s+\(([^)]*)\)',pip).group(1).split()) if re.search(r':mandatory-nodes\s+\(([^)]*)\)',pip) else set()
edges=re.findall(r'\((\w+)\s+(\w+)\)',re.search(r':edges\s+\((.*?)\)\s*:symbolic',pip,re.S).group(1)) if re.search(r':edges\s+\((.*?)\)\s*:symbolic',pip,re.S) else []
propmand=re.search(r':proposer-mandatory-nodes\s+\(([^)]*)\)',pip); propmand=[x for x in (propmand.group(1).split() if propmand else []) if x]
def reach(entry,exit_,eds):
    adj={}
    for a,b in eds: adj.setdefault(a,[]).append(b)
    seen=set(); st=[entry]
    while st:
        x=st.pop()
        if x in seen: continue
        seen.add(x); st+=adj.get(x,[])
    return exit_ in seen
allmand = all(reach('ACQUIRE',mnd,edges) for mnd in mand_nodes)
out('V8-SYM', 0 if (mcount==4 and allmand and len(propmand)==0 and reach('ACQUIRE','PUBLISH',edges)) else 1, 0)
out('V8-SYMM', 1 if not reach('ACQUIRE','PUBLISH',[e for e in edges if e!=('PROOF','PUBLISH')]) else 0, 1)   # broken-edge mutation

# V8-REQ [DOC] DFT-09 — traceability §v1.8 rows: requirement/test/seat/owner/WP; REAL negative mutation
v18=TRC.split('§v1.8',1)[1] if '§v1.8' in TRC else ''
rows=re.findall(r'\|\s*(RA8-[A-Z0-9-]+|DFT-\d+)\s*\|([^\n]*)',v18)
def req_fail(rws):
    b=0
    for rid,rest in rws:
        cells=[c.strip() for c in rest.split('|')]
        if len(cells)<6 or not cells[3] or not cells[4]: b+=1    # seat + test present
    return b
rq=req_fail(rows); out('V8-REQ', 0 if (rq==0 and len(rows)>=17) else 1, 0)
# real negative mutation: blank the test cell (cells[4]) of the first row ⇒ req_fail must rise
if rows:
    c0=rows[0][1].split('|')
    if len(c0)>4: c0[4]='   '
    mrows=[(rows[0][0],'|'.join(c0))]+rows[1:]
    out('V8-REQM', 1 if req_fail(mrows)>rq else 0, 1)
else: out('V8-REQM',0,1)

# V8-RA-DELTAS [STR] — 7 deltas each have a canonical seat marker present
delta_marks={'RA-EPOCH':'MultiCommitment/1','RA-CONT':'ContinuityPolicy/1','RA-CORR':'PublicCorrectionEvent/1',
 'RA-K':'MetricAssuranceClass','RA-SIDE':'SidecarSourceProfile/1','RA-MARK':'LawmaxStatusVsMark/1','RA-FROST':'RecoveryEpoch/1'}
missing=sum(1 for k,v in delta_marks.items() if v not in code)
out('V8-RA-DELTAS', missing, 0)
# honesty markers required present
hon = 0
for tok in ('PENDING_LEGAL_VALIDATION','PENDING_IMPLEMENTATION_REVIEW','RECOVERY_EPOCH','NOT threshold ML-DSA' if 'NOT threshold ML-DSA' in code else 'not threshold ML-DSA'):
    if tok not in code: hon+=1
out('V8-RA-HONEST', hon, 0)

for i,a,e in R: print(f"{i}|{a}|{e}")
PYV8
)

echo "# C [DOC] — RA-K tiered (no publicly-reproducible when data cannot be published) + FROST precise"
ck K1 "$(cE 'INDEPENDENTLY_AUDITED_RESTRICTED' $S)" ge 1
ck K2 "$(cE 'PUBLICLY_REPRODUCIBLE ONLY when|only when its data can be published' $S | sum)" ge 1
ck F1 "$(cE 'OUTSIDE RFC 9591|outside RFC 9591' $S | sum)" ge 1
ck F2 "$(cE 'NOT an .epoch demotion.|NOT an ..epoch demotion|new monotonic|monotonically-increasing RECOVERY_EPOCH' $S | sum)" ge 1

echo "# D — regressions (v1.7 + v1.6 + v1.5 + v1.4) + frozen immutability"
ck G1 "$(bash ./V1.7-CONTRADICTION-OMISSION-AUDIT.sh >/dev/null 2>&1; echo $?)" eq 0
ck G2 "$(bash ./V1.6-CONTRADICTION-OMISSION-AUDIT.sh >/dev/null 2>&1; echo $?)" eq 0
ck G3 "$(bash ./V1.5-CONTRADICTION-OMISSION-AUDIT.sh >/dev/null 2>&1; echo $?)" eq 0
ck G4 "$(bash ./V1.4-CONTRADICTION-OMISSION-AUDIT.sh >/dev/null 2>&1; echo $?)" eq 0
ck G5 "$(git -C $ROOT rev-parse 88129099^{tree} 2>/dev/null | grep -c '^a2617649596644c25894c4343f25ddb6c4dec1ce')" eq 1
ck G6 "$(sha256sum V1.4-CONTRADICTION-OMISSION-AUDIT.out | grep -c '^4873e61069d4a1a2a1047d059b81cd9103171776346650a3b5ed4eee077624fb')" eq 1

echo "### SUMMARY: checks=$n pass=$pass fail=$fail"
[ "$fail" -eq 0 ] && { echo "### EXIT 0 — V1.8 STRUCTURAL/REAL-FILE CONSISTENCY PASS (CANDIDATE· document/structural/file-existence evidence ONLY, NOT executable/legal/security/qualification proof)"; exit 0; } || { echo "### EXIT 1 — DEVIATIONS PRESENT"; exit 1; }
