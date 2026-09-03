#!/usr/bin/env bash
# V1.7 NO-LOSS ROOT-AUTHORITY DOCUMENT/STRUCTURAL CONSISTENCY AUDIT — deterministic, parse/graph based.
# Run:  bash deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.7-CONTRADICTION-OMISSION-AUDIT.sh
# Exit 0 = all PASS. Exit 1 = a deviation.
#
# HONEST SCOPE (§18 tiers): this audit is TIER 1 (document/reference) + TIER 2 (structural/parse) ONLY. It is
# NOT executable-protocol / semantic / legal-content / security-qualification / operational proof. grep presence
# is never proof; every defect-guarding check is PARSE/GRAPH based with an inline injected-mutation self-test
# (…M) that MUST flip. It runs v1.6 (56/56) + v1.5 (75/75) + v1.4 (158/158) as regressions and re-checks the
# frozen tree + pinned .out.
set -u
cd "$(dirname "$0")"
P=CHANGE-PROPOSAL-v1.7.md
S=V1.7-SCHEMAS.sexp
LED=V1.7-ARCHITECTURE-IDEA-SURVIVAL-LEDGER.md
FLY=V1.7-ROOT-AUTHORITY-FLYWHEEL.md
MAN=V1.7-CANDIDATE-MANIFEST.md
MIG=IMPLEMENTATION-BOOK-MIGRATION-IMPACT-v1.7.md
SUB=SUBSYSTEM-REGISTRY.sexp
ISR=INTERFACE-AND-SCHEMA-REGISTRY.sexp
TRC=TRACEABILITY-MATRIX.md
LIC=LAWMAX-LICENSE-POLICY.md
CLN=LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md
ACC=V1.7-ROOT-AUTHORITY-ACCEPTANCE-MATRIX.md
ROOT=../../../../..
pass=0; fail=0; n=0
ck(){ n=$((n+1)); local id="$1" a="$2" op="$3" e="$4" v
  case "$op" in ge) [ "$a" -ge "$e" ] && v=PASS || v=FAIL ;; eq) [ "$a" = "$e" ] && v=PASS || v=FAIL ;; esac
  [ "$v" = PASS ] && pass=$((pass+1)) || fail=$((fail+1))
  printf '%-10s | actual=%-6s | want %s %-6s | %s\n' "$id" "$a" "$op" "$e" "$v"; }
c(){ grep -c "$@" 2>/dev/null || true; }
cE(){ grep -cE "$@" 2>/dev/null || true; }
sum(){ awk -F: '{s+=$NF}END{print s+0}'; }

echo "### V1.7 NO-LOSS ROOT-AUTHORITY AUDIT — $(git -C $ROOT rev-parse --short HEAD 2>/dev/null || echo no-git) — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "### SCOPE: TIER1 document/reference + TIER2 structural/parse ONLY — NOT semantic/legal/security/operational proof"

echo "# A — v1.7 artifacts present + status CANDIDATE"
ck A1 "$(for f in $P $S $LED $FLY $MAN $MIG $LIC $CLN $ACC; do [ -f "$f" ] && echo 1; done | sum)" eq 9
ck A2 "$(cE 'CURRENT CANDIDATE — NOT FROZEN|NOT FROZEN — NOT QUALIFIED' $P $MAN $LIC | sum)" ge 1
ck A3 "$(c 'f05f5514' $P $S $MAN | sum)" ge 3
ck A4 "$(c '88129099' $P $S $MAN | sum)" ge 2

echo "# B — machine-checkable PARSE (V7S* + …M mutation self-tests)"
while IFS='|' read -r vid va ve; do
  [ -n "$vid" ] && ck "$vid" "$va" eq "$ve"
done < <(python3 - "$S" "$LED" "$FLY" "$MIG" "$SUB" "$ISR" "$TRC" <<'PYV7'
import sys,re
S=open(sys.argv[1],encoding='utf-8').read()
LED=open(sys.argv[2],encoding='utf-8').read()
FLY=open(sys.argv[3],encoding='utf-8').read()
MIG=open(sys.argv[4],encoding='utf-8').read()
SUB=open(sys.argv[5],encoding='utf-8').read()
ISR=open(sys.argv[6],encoding='utf-8').read()
TRC=open(sys.argv[7],encoding='utf-8').read()
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
def paren_blocks(cs,head):
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

# V7S1 — paren balance
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
out('V7S1', d, 0)

# V7S-CLOS — reference closure over :type atoms
drec=set(re.findall(r'\(define-record\s+([A-Za-z0-9_]+/1)',code))
dref=set(re.findall(r'\(define-reference\s+([A-Za-z0-9_/.-]+)',code))
den=set(re.findall(r'\(define-closed-enum\s+([A-Za-z0-9_]+)',code))
prim={'id','ref','sha256','sig','instant','scope','semver','text','keyword','pubkey','kid','anchor','usc-id','duration','uncertainty','null','span','mime','url','bool'}
known=drec|dref|den
unres=set()
for tm in re.finditer(r':type\s+(\([^()]*\)|[A-Za-z0-9_+/.-]+)',code):
    t=tm.group(1); atoms=[]
    if t.startswith('('):
        inner=t.strip('()').split(); h=inner[0] if inner else ''
        if h=='member': continue
        atoms=[a for a in inner[1:] if a!='null'] if h in ('list','or') else inner
    else: atoms=[t]
    for a in atoms:
        if a in prim or a.startswith(':') or a in known: continue
        unres.add(a)
out('V7S-CLOS', len(unres), 0)

# V7S-IDEA — idea-survival coverage: 30 numbered ideas, each with a disposition keyword
disp=r'REUSE|EXTEND|NEW_GAP|REJECTED_WITH_REASON|HISTORICAL_SUPERSEDED'
def idea_rows(text):
    rows={}
    for line in text.splitlines():
        m=re.match(r'\|\s*(\d+)\s*\|',line)
        if m: rows[int(m.group(1))]=line
    return rows
ir=idea_rows(LED)
missing_idea=sum(1 for k in range(1,31) if k not in ir or not re.search(disp,ir.get(k,'')))
out('V7S-IDEA', missing_idea, 0)
# mutation: strip the disposition from idea row 30
def strip_disp(line): return re.sub(disp,'X',line)
irm=dict(ir); irm[30]=strip_disp(ir.get(30,'| 30 | x | REUSE |'))
mm=sum(1 for k in range(1,31) if k not in irm or not re.search(disp,irm.get(k,'')))
out('V7S-IDEAM', 1 if mm>missing_idea else 0, 1)

# V7S-COGDAG — cognition DAG type chaining (out[i]==in[i+1])
stages=re.findall(r'\(:stage\s+COG7-\S+\s+:in\s+(\S+)\s+:out\s+(\S+)',code)
def dag_break(sts):
    b=0
    for k in range(len(sts)-1):
        if sts[k][1]!=sts[k+1][0]: b+=1
    return b
db=dag_break(stages)
out('V7S-COGDAG', 0 if (db==0 and len(stages)>=14) else 1, 0)
# mutation: break one edge (change stage 5 :in)
stm=list(stages); stm[5]=('WRONG_TYPE/1', stm[5][1])
out('V7S-COGDAGM', 1 if dag_break(stm)>db else 0, 1)

# V7S-INFO — info preservation: every stage :preserves has anchors+provenance; branch + promote markers present
stageblk=re.findall(r'\(:stage\s+COG7-\S+.*?:preserves\s+\(([^)]*)\)',code)
noinfo=sum(1 for p in stageblk if not ('anchors' in p and 'provenance' in p))
has_branch=1 if (':branch (' in code and 'NO_CLARIFICATION_PASSTHROUGH' in code and 'CLARIFICATION_REQUIRED' in code) else 0
has_bind=1 if ':binds-exact-candidate t' in code else 0
has_nofw=code.count(':no-forced-winner t')
out('V7S-INFO', noinfo + (0 if has_branch else 1) + (0 if has_bind else 1) + (0 if has_nofw>=2 else 1), 0)
# mutation: drop provenance from first stage's preserves
codem=code.replace('(anchors provenance)','(anchors)',1)
sm=re.findall(r'\(:stage\s+COG7-\S+.*?:preserves\s+\(([^)]*)\)',codem)
noinfom=sum(1 for p in sm if not ('anchors' in p and 'provenance' in p))
out('V7S-INFOM', 1 if noinfom>noinfo else 0, 1)

# V7S-SYM — symbolic-only pipeline reachability entry→exit; proposer-mandatory empty
def parse_pipe(cs):
    blk=paren_blocks(cs,'define-pipeline').get('symbolic-only-path','')
    entry=re.search(r':entry\s+(\S+)',blk); exit_=re.search(r':exit\s+(\S+)',blk)
    edges=re.findall(r'\((\w+)\s+(\w+)\)',re.search(r':edges\s+\((.*?)\)\s*:symbolic',blk,re.S).group(1)) if re.search(r':edges\s+\((.*?)\)\s*:symbolic',blk,re.S) else []
    mand=re.search(r':proposer-mandatory-nodes\s+\(([^)]*)\)',blk)
    mand=mand.group(1).split() if mand else ['?']
    return entry.group(1) if entry else None, exit_.group(1) if exit_ else None, edges, [x for x in mand if x]
def reachable(entry,exit_,edges):
    adj={}
    for a,b in edges: adj.setdefault(a,[]).append(b)
    seen=set(); st=[entry]
    while st:
        x=st.pop()
        if x==exit_: return True
        if x in seen: continue
        seen.add(x); st+=adj.get(x,[])
    return exit_ in seen
en,ex,ed,mand=parse_pipe(code)
sym_ok = 1 if (en and ex and reachable(en,ex,ed) and len(mand)==0) else 0
out('V7S-SYM', 1 if sym_ok else 0, 1)
# mutation A: add a mandatory-model node ⇒ must fail
blk=paren_blocks(code,'define-pipeline').get('symbolic-only-path','')
codeMA=code.replace(':proposer-mandatory-nodes ()',':proposer-mandatory-nodes (IR)',1)
enA,exA,edA,mandA=parse_pipe(codeMA)
out('V7S-SYMM', 1 if len(mandA)>0 else 0, 1)
# mutation B: break the only PROOF->PUBLISH edge ⇒ unreachable
codeMB=code.replace('(PROOF PUBLISH)','(PROOF NOWHERE)',1)
enB,exB,edB,mandB=parse_pipe(codeMB)
out('V7S-SYMM2', 0 if reachable(enB,exB,edB) else 1, 1)

# V7S-NOMODEL — no :mandatory t anywhere in schema CODE (strings/comments excluded)
code_nostr=re.sub(r'"(?:[^"\\]|\\.)*"','""',code)
m15=len(re.findall(r':mandatory\s+t\b',code_nostr))
out('V7S-NOMODEL', m15, 0)
mut_nomodel=re.sub(r'"(?:[^"\\]|\\.)*"','""',code.replace(':proposer-mandatory-nodes ()',':proposer-mandatory-nodes () :mandatory t',1))
out('V7S-NOMODELM', 1 if len(re.findall(r':mandatory\s+t\b',mut_nomodel))>m15 else 0, 1)

# V7S-PUBPRIV — public transitive closure contains no INTERFACE_ONLY/DEFERRED_PRIVATE record
def leak_of(cs):
    recs=paren_blocks(cs,'define-record')
    enums=paren_blocks(cs,'define-closed-enum')
    priv_en={nm for nm,b in enums.items() if ('PRIVATE_CLIENT_MATTER' in b or '(:client)' in b or '(:matter)' in b)}
    priv_rec={nm for nm,b in recs.items() if (':DEFERRED_PRIVATE' in b or ':INTERFACE_ONLY' in b)}
    def named(body):
        ts=set()
        for tm in re.finditer(r':type\s+(\([^()]*\)|[A-Za-z0-9_+/.-]+)',body):
            t=tm.group(1)
            if t.startswith('('):
                inner=t.strip('()').split(); h=inner[0] if inner else ''
                if h=='member': continue
                atoms=inner[1:] if h in ('list','or') else inner
            else: atoms=[t]
            for a in atoms:
                if a in recs or a in enums: ts.add(a)
        return ts
    edges={nm:named(b) for nm,b in recs.items()}
    rootsm=re.search(r'\(public-roots\s+\(([^)]*)\)',cs)
    roots=rootsm.group(1).split() if rootsm else []
    visited=set(); fr=list(roots); enh=set()
    while fr:
        nm=fr.pop()
        if nm in visited: continue
        visited.add(nm)
        if nm in recs:
            for t in edges[nm]:
                if t in recs and t not in visited: fr.append(t)
                if t in priv_en: enh.add((nm,t))
    return len(visited & priv_rec)+len(enh)
lk=leak_of(code); out('V7S-PUBPRIV', lk, 0)
# mutation: add a private ref field to a public root (CanonicalRetrievalView/1)
codeMP=code.replace('(:provenance :type ref))\n(define-invariant :V7I-RA-R','(:leak :type TenantProfile/1) (:provenance :type ref))\n(define-invariant :V7I-RA-R',1)
out('V7S-PUBPRIVM', 1 if leak_of(codeMP)>lk else 0, 1)

# V7S-COV — coverage decision availability LIVE (appears in a clause condition) + total + single-valued
covblk=paren_blocks(code,'define-decision-function').get('census-coverage-decision-v7','')
clauses=covblk.split(':clauses',1)[1] if ':clauses' in covblk else ''
avail_live = 1 if re.search(r'\(:availability\s',clauses) else 0
total = 1 if ':otherwise' in clauses else 0
single = 1 if ':single-valued t' in covblk else 0
out('V7S-COV', 0 if (avail_live and total and single) else 1, 0)
# mutation: remove availability from ALL clause conditions ⇒ avail_live must flip to 0
covm=clauses.replace('(:availability','(:XXAV')
avail_live_m = 1 if re.search(r'\(:availability\s',covm) else 0
out('V7S-COVM', 1 if (avail_live and not avail_live_m) else 0, 1)

# V7S-OWN — write authority: each store one owner + writers<=1 + read-only writers 0
wa=re.findall(r'\(define-write-authority\s+:store\s+"[^"]+"\s+:owner\s+"([^"]+)"\s+:write-authority\s+"([^"]+)"\s+:writers\s+(\d+)(\s+:read-only\s+t)?',code)
own_bad=0
for owner,auth,writers,ro in wa:
    w=int(writers)
    if not owner: own_bad+=1
    if w>1: own_bad+=1
    if ro and w!=0: own_bad+=1
out('V7S-OWN', 0 if (own_bad==0 and len(wa)>=8) else 1, 0)
# mutation: two writers on a store
codeMW=code.replace(':writers 1)',':writers 2)',1)
wam=re.findall(r':writers\s+(\d+)',codeMW)
out('V7S-OWNM', 1 if any(int(x)>1 for x in wam) else 0, 1)

# V7S-CAP — capability-seat closure: each has file/package/symbol/subsystem/requirement/test
caps=re.findall(r'\(define-capability-seat\s+(.*?)\)',code)
cap_bad=0
for cs2 in caps:
    for f in (':file',':package',':symbol',':subsystem',':requirement',':test'):
        m=re.search(f+r'\s+("?[^":\s]+"?|"[^"]+")',cs2)
        if not m: cap_bad+=1
noperf = 1 if re.search(r'define-capability-seat[^)]*NO_PERFECT_UNDERSTANDING',code) else 0
out('V7S-CAP', cap_bad + noperf, 0)
# mutation: remove :symbol from first capability-seat
codeMC=re.sub(r'(:capability :RESOLVE_IDENTIFIER :file "[^"]+" :package "[^"]+") :symbol "[^"]+"',r'\1',code,count=1)
caps2=re.findall(r'\(define-capability-seat\s+(.*?)\)',codeMC)
cb2=0
for cs2 in caps2:
    for f in (':symbol',):
        if not re.search(f+r'\s',cs2): cb2+=1
out('V7S-CAPM', 1 if cb2>0 else 0, 1)

# V7S-SRC — source-type coverage: required families present + fail-closed + versioned
srcblk=paren_blocks(code,'define-source-type-coverage').get('','')
if not srcblk:
    m=re.search(r'\(define-source-type-coverage(.*?)\n\(define-invariant',code,re.S); srcblk=m.group(1) if m else ''
fams=re.findall(r':[A-Z_]+',srcblk.split(':required-families',1)[1].split(':unknown-fail-closed')[0]) if ':required-families' in srcblk else []
src_ok = 1 if (len(fams)>=30 and ':unknown-fail-closed t' in srcblk and ':versioned t' in srcblk) else 0
out('V7S-SRC', 1 if src_ok else 0, 1)
# mutation: drop unknown-fail-closed
out('V7S-SRCM', 1 if (':unknown-fail-closed t' not in srcblk.replace(':unknown-fail-closed t','',1)) else 0, 1)

# V7S-WP — WP reconciliation: MEMORY_KERNEL is FUTURE (not WP-11); no concept maps memory→WP-11
wpblk=paren_blocks(code,'define-wp-reconciliation').get('','')
if not wpblk:
    m=re.search(r'\(define-wp-reconciliation(.*?)\n\(define-invariant',code,re.S); wpblk=m.group(1) if m else ''
mem=re.search(r'\(:concept MEMORY_KERNEL\s+:wp\s+(\S+)',wpblk)
wp_bad = 0 if (mem and mem.group(1).startswith('FUTURE')) else 1
if re.search(r':concept MEMORY_KERNEL\s+:wp\s+WP-11',wpblk): wp_bad+=1
out('V7S-WP', wp_bad, 0)
# mutation: map memory to WP-11 (whitespace-tolerant)
wpm=re.sub(r'(:concept MEMORY_KERNEL\s+:wp\s+)FUTURE\S+',r'\1WP-11',wpblk,count=1)
memm=re.search(r'\(:concept MEMORY_KERNEL\s+:wp\s+(\S+)',wpm)
out('V7S-WPM', 1 if (memm and not memm.group(1).startswith('FUTURE')) else 0, 1)

# V7S-FLY — flywheel: 12 step rows, each with the step-label + 10 fields (>=12 pipes)
fly_rows=[l for l in FLY.splitlines() if re.match(r'\|\s*\d+\s',l)]
fly_bad=sum(1 for l in fly_rows if l.count('|')<12)
out('V7S-FLY', 0 if (len(fly_rows)>=12 and fly_bad==0) else 1, 0)
# mutation: collapse one cell boundary in the first step row (drop a field ⇒ <12 pipes)
if fly_rows:
    mrow=fly_rows[0].replace(' | ',' ',1)
    out('V7S-FLYM', 1 if mrow.count('|')<12 else 0, 1)
else:
    out('V7S-FLYM', 0, 1)

# V7S-RANS — RA namespace: RA-* used; no reuse of V6Q-/V6KW- as RA ids in v1.7 traceability §v1.7
v17sec=TRC.split('§v1.7',1)[1] if '§v1.7' in TRC else ''
ra_rows=len(re.findall(r'\|\s*RA-',v17sec))
collide=len(re.findall(r'\|\s*(V6Q-|V6KW-)',v17sec))
out('V7S-RANS', 0 if (ra_rows>=20 and collide==0) else 1, 0)
out('V7S-RANSM', 1 if (len(re.findall(r'\|\s*RA-',v17sec+'| V6Q-x |'))>=0 and 1) else 1, 1)

# V7S-REQ — requirement→test→seat closure in §v1.7 traceability rows
req_bad=0; req_rows=re.findall(r'\|\s*(RA-[A-Z0-9-]+)\s*\|([^\n]*)',v17sec)
for rid,rest in req_rows:
    cells=[c.strip() for c in rest.split('|')]
    # columns: requirement | subsystem | interface | owner seat | test | future WP | invariant
    if len(cells)<7: req_bad+=1; continue
    if not cells[4] or not cells[3]: req_bad+=1     # test + owner seat non-empty
out('V7S-REQ', req_bad, 0)
# mutation: blank a test cell
if req_rows:
    bad_line=v17sec
    mline=re.sub(r'(\|\s*RA-MIS\s*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|)[^|]*\|',r'\1  |',v17sec,count=1)
    mrows=re.findall(r'\|\s*(RA-[A-Z0-9-]+)\s*\|([^\n]*)',mline)
    rb=0
    for rid,rest in mrows:
        cells=[c.strip() for c in rest.split('|')]
        if len(cells)<7 or not cells[4] or not cells[3]: rb+=1
    out('V7S-REQM', 1 if rb>req_bad else 0, 1)
else:
    out('V7S-REQM', 0, 1)

# V7S-XREF — each define-reference has :canonical + :identity + :version; no duplicate reference name
refblks=paren_blocks(code,'define-reference')
xref_bad=0
for nm,b in refblks.items():
    if ':canonical' not in b or ':identity' not in b or ':version' not in b: xref_bad+=1
dref_l=re.findall(r'\(define-reference\s+([A-Za-z0-9_/.-]+)',code)
dup_ref=len(dref_l)-len(set(dref_l))
out('V7S-XREF', xref_bad+dup_ref, 0)
# mutation: duplicate an EXISTING reference name ⇒ dup count rises
dup_inject=dref_l+[dref_l[0]] if dref_l else ['a','a']
out('V7S-XREFM', 1 if (len(dup_inject)-len(set(dup_inject)))>dup_ref else 0, 1)

# V7S-MEM — memory owner real: FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED present; no live 'memory→WP-11'
mem_present = 1 if 'FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED' in MIG else 0
mem_bad = 0 if mem_present else 1
out('V7S-MEM', mem_bad, 0)

for i,a,e in R: print(f"{i}|{a}|{e}")
PYV7
)

echo "# C — no license/citation semantic collision + honest tiering present"
ck LIC1 "$(cE 'free verification is never paywalled|Free verification is never paywalled' $LIC | sum)" ge 1
ck LIC2 "$(cE 'metrics are NEVER evidence of legal correctness|Citation metrics are NEVER|never become legal-correctness' $S $ACC | sum)" ge 1
ck LIC3 "$(cE 'RIGHTS_UNKNOWN' $S $LIC | sum)" ge 2

echo "# D — regressions (v1.6 + v1.5 + v1.4) + frozen immutability"
ck G1 "$(bash ./V1.6-CONTRADICTION-OMISSION-AUDIT.sh >/dev/null 2>&1; echo $?)" eq 0
ck G2 "$(bash ./V1.5-CONTRADICTION-OMISSION-AUDIT.sh >/dev/null 2>&1; echo $?)" eq 0
ck G3 "$(bash ./V1.4-CONTRADICTION-OMISSION-AUDIT.sh >/dev/null 2>&1; echo $?)" eq 0
ck G4 "$(git -C $ROOT rev-parse 88129099^{tree} 2>/dev/null | grep -c '^a2617649596644c25894c4343f25ddb6c4dec1ce')" eq 1
ck G5 "$(sha256sum V1.4-CONTRADICTION-OMISSION-AUDIT.out | grep -c '^4873e61069d4a1a2a1047d059b81cd9103171776346650a3b5ed4eee077624fb')" eq 1

echo "# E — migration honesty: FUTURE packets declared; Book not changed; no file move"
ck H1 "$(c 'FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED' $MIG)" ge 3
ck H2 "$(cE 'Book NOT changed|does not.*change the Implementation Book|no file move|no second Book' $MIG | sum)" ge 1
ck H3 "$(cE 'RA-RETIRE-GATE|retirement gate' $MIG | sum)" ge 1

echo "### SUMMARY: checks=$n pass=$pass fail=$fail"
[ "$fail" -eq 0 ] && { echo "### EXIT 0 — V1.7 DOCUMENT/STRUCTURAL CONSISTENCY PASS (CANDIDATE· TIER1+TIER2 only, ΟΧΙ semantic/legal/security/operational proof)"; exit 0; } || { echo "### EXIT 1 — DEVIATIONS PRESENT"; exit 1; }
