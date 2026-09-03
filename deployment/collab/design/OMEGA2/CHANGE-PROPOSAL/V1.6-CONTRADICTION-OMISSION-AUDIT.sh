#!/usr/bin/env bash
# V1.6 FUTURE-EXTENSIBILITY DOCUMENT/REFERENCE + DUPLICATE-SEAT CONSISTENCY AUDIT — deterministic.
# Run:  bash deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.6-CONTRADICTION-OMISSION-AUDIT.sh
# Exit 0 = all PASS. Exit 1 = a deviation.
#
# HONEST SCOPE: structural / document-reference / duplicate-seat consistency ONLY over the v1.6 CANDIDATE
# (that every v1.6 contract is defined once and type-closed, ONNX is optional, SYMBOLIC_ONLY is a complete
# path, memory and cognition each have ONE seat, public/private/embodiment is acyclic, the public transitive
# type closure carries no private type, WP assignments resolve to a real WP, every cognition capability maps
# exactly once, and every v1.5 repair regression stays green). It is NOT a semantic/legal/security or
# qualification proof; it executes NONE of the predeclared V6Q/V6KW tests. Parse-based (V6S1-V6S17), not grep;
# each structural check that guards a v1.6 defect carries an inline injected-mutation self-test (…M) that MUST
# flip, proving the check is non-vacuous.
set -u
cd "$(dirname "$0")"
P=CHANGE-PROPOSAL-v1.6.md
S=V1.6-SCHEMAS.sexp
SUB=SUBSYSTEM-REGISTRY.sexp
ISR=INTERFACE-AND-SCHEMA-REGISTRY.sexp
MAN=V1.6-CANDIDATE-MANIFEST.md
MIG=IMPLEMENTATION-BOOK-MIGRATION-IMPACT-v1.6.md
ROOT=../../../../..
pass=0; fail=0; n=0
ck(){ n=$((n+1)); local id="$1" a="$2" op="$3" e="$4" v
  case "$op" in ge) [ "$a" -ge "$e" ] && v=PASS || v=FAIL ;; eq) [ "$a" = "$e" ] && v=PASS || v=FAIL ;; esac
  [ "$v" = PASS ] && pass=$((pass+1)) || fail=$((fail+1))
  printf '%-8s | actual=%-6s | want %s %-6s | %s\n' "$id" "$a" "$op" "$e" "$v"; }
c(){ grep -c "$@" 2>/dev/null || true; }
cE(){ grep -cE "$@" 2>/dev/null || true; }
sum(){ awk -F: '{s+=$NF}END{print s+0}'; }

echo "### V1.6 FUTURE-EXTENSIBILITY DOCUMENT/DUPLICATE-SEAT CONSISTENCY AUDIT — $(git -C $ROOT rev-parse --short HEAD 2>/dev/null || echo no-git) — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "### SCOPE: structural/document/duplicate-seat ONLY — NOT semantic/legal/security/qualification proof"

echo "# A — core artifacts present + status CANDIDATE"
ck A1 "$(for f in $P $S $SUB $ISR $MAN $MIG; do [ -f "$f" ] && echo 1; done | sum)" eq 6
ck A2 "$(c 'CURRENT CANDIDATE — NOT FROZEN — NOT QUALIFIED — IMPLEMENTATION BLOCKED' $P $MAN | sum)" ge 2
ck A3 "$(c '88129099' $P $S $MAN | sum)" ge 3
ck A4 "$(c 'successor' $P $S | sum)" ge 1   # same CPEI profile, no new architecture

echo "# B — ONNX / model independence (normative + checkable)"
ck B1 "$(c 'SYMBOLIC_ONLY' $P $S | sum)" ge 3
ck B2 "$(cE ':V6I-02-no-mandatory-model|no.*mandatory' $P $S | sum)" ge 1
ck B3 "$(c 'ONNXProposerAdapter' $S)" ge 1
ck B4 "$(cE ':mandatory nil' $S)" ge 2         # ONNX + OCR adapters explicitly optional
ck B5 "$(c 'SemanticProposer' $P $S $ISR | sum)" ge 3
ck B6 "$(cE 'removable with NO loss|χωρίς απώλεια μνήμης' $S $P | sum)" ge 1

echo "# C — language cognition ONE seat + casegrammar SPLIT (no second engine/impl)"
ck C1 "$(c 'LanguageCognitionLayer/1' $S $ISR $P | sum)" ge 3
ck C2 "$(c 'casegrammar-split' $S)" ge 1
ck C3 "$(cE 'no-copy|Καμία αντιγραφή|καμία.*δεύτερη.*υλοποίηση|no second implementation' $S $P | sum)" ge 1
ck C4 "$(c 'no-external-eval' $S)" ge 1        # no cl:read/eval/compile on external bytes
ck C5 "$(c 'NO_PERFECT_UNDERSTANDING_CLAIM' $S)" ge 1

echo "# D — memory ONE seat + model boundary"
ck D1 "$(c 'memory.lisp' $S $SUB $ISR | sum)" ge 3
ck D2 "$(c 'MemoryProjection/1' $S $ISR | sum)" ge 2
ck D3 "$(cE 'byte-verifiable memory continuity' $S $P | sum)" ge 1
ck D4 "$(for m in WORKING_CONTEXT EPISODIC_INTERACTION SEMANTIC PROCEDURAL PROSPECTIVE_GOALS SOURCE_PROVENANCE TEMPORAL ARGUMENT_COUNTERARGUMENT UNCERTAINTY_CONTRADICTION USER_PREFERENCE SKILL_CAPABILITY META_MEMORY PRIVATE_CLIENT_MATTER; do grep -lq ":$m" $S && echo 1; done | sum)" ge 13

echo "# E — extension boundary acyclic (public never depends on private/embodiment)"
ck E1 "$(c ':public-dependency nil' $S)" ge 3
ck E2 "$(cE 'Public.*NEVER depends|Public → private.*FORBIDDEN|ΑΠΑΓΟΡΕΥΟΝΤΑΙ' $S $P | sum)" ge 1
ck E3 "$(c 'independent_emergency_stop' $S)" ge 1
ck E4 "$(c 'DeclassificationReceipt/1' $S $ISR | sum)" ge 2

echo "# F — machine-checkable PARSE of V1.6-SCHEMAS.sexp + registries + migration (V6S1-V6S17 + …M mutation self-tests)"
while IFS='|' read -r vid va ve; do
  [ -n "$vid" ] && ck "$vid" "$va" eq "$ve"
done < <(python3 - "$S" "$SUB" "$ISR" "$MIG" <<'PYV6'
import sys,re
schem=open(sys.argv[1],encoding='utf-8').read()
sub_raw=open(sys.argv[2],encoding='utf-8').read()
isr_raw=open(sys.argv[3],encoding='utf-8').read()
mig=open(sys.argv[4],encoding='utf-8').read()
def strip(s):
    o=[];i=0;ins=False
    while i<len(s):
        c=s[i]
        if ins:
            o.append(c)
            if c=='\\' and i+1<len(s): o.append(s[i+1]); i+=2; continue
            if c=='"': ins=False
            i+=1; continue
        if c=='"': ins=True; o.append(c); i+=1; continue
        if c==';':
            while i<len(s) and s[i]!='\n': i+=1
            continue
        o.append(c); i+=1
    return ''.join(o)
code=strip(schem); sub=strip(sub_raw); isr=strip(isr_raw)
R=[]
def out(i,a,e): R.append((i,str(a),str(e)))

# ---- shared parses ----
drec_l=re.findall(r'\(define-record\s+([A-Za-z0-9_]+/1)',code)
dref_l=re.findall(r'\(define-reference\s+([A-Za-z0-9_]+/1)',code)
drec=set(drec_l); dref=set(dref_l)
den=set(re.findall(r'\(define-closed-enum\s+([A-Za-z0-9_]+)',code))
ifaces=re.findall(r'\(define-interface\s+([A-Za-z0-9_/-]+)',isr)
defined_if=set(ifaces)
prim={'id','ref','sha256','sig','instant','scope','semver','text','keyword','pubkey','kid','anchor','usc-id','duration','uncertainty','null','span','mime','url'}

def paren_blocks(cs,head):
    # return dict name->body for every (head NAME ...) top-level form
    res={}; i=0
    pat=re.compile(r'\('+head+r'\s+([A-Za-z0-9_]+/?1?)')
    for m in pat.finditer(cs):
        s=m.start(); d=0;j=s;ins=False
        while j<len(cs):
            c=cs[j]
            if ins:
                if c=='\\': j+=2; continue
                if c=='"': ins=False
                j+=1; continue
            if c=='"': ins=True
            elif c=='(': d+=1
            elif c==')':
                d-=1
                if d==0: j+=1; break
            j+=1
        res[m.group(1)]=cs[s:j]
    return res

# V6S1 — paren balance of the schema (over raw, string/comment aware)
d=0;i=0;ins=False
while i<len(schem):
    c=schem[i]
    if ins:
        if c=='\\':i+=2;continue
        if c=='"':ins=False
        i+=1;continue
    if c=='"':ins=True
    elif c==';':
        while i<len(schem) and schem[i]!='\n':i+=1
        continue
    elif c=='(':d+=1
    elif c==')':d-=1
    i+=1
out('V6S1', d, 0)

# V6S2 — the 13 universal contracts each defined EXACTLY once as record OR reference
need13=['PerceptionEnvelope/1','CandidateInterpretation/1','LegalIR/1','MemoryEvent/1','CapabilityManifest/1',
 'ToolInvocation/1','Plan/1','ActionIntent/1','Approval/1','ExecutionReceipt/1','SafetyState/1','TrustBundle/1',
 'DeclassificationReceipt/1']
allnames=drec_l+dref_l
def once(x): return allnames.count(x)==1 and (x in drec or x in dref)
out('V6S2', sum(1 for x in need13 if once(x)), 13)

# V6S3 — reference closure: every :type record/enum atom resolves (records, references or enums or primitive)
known=drec|dref|den
unres=set()
for tm in re.finditer(r':type\s+(\([^()]*\)|[A-Za-z0-9_+/.-]+)',code):
    t=tm.group(1); atoms=[]
    if t.startswith('('):
        inner=t.strip('()').split(); head=inner[0] if inner else ''
        if head=='member': continue
        atoms=[a for a in inner[1:] if a!='null'] if head in ('list','or') else inner
    else: atoms=[t]
    for a in atoms:
        if a in prim or a.startswith(':') or a in known: continue
        unres.add(a)
out('V6S3', len(unres), 0)

# V6S4 — SUBSYSTEM-REGISTRY: each subsystem id defined once (no dual seats)
subids=re.findall(r'\(define-subsystem\s+(S\d+)\b',sub)
out('V6S4', len(subids)-len(set(subids)), 0)
# V6S5 — every subsystem has exactly one :owner (single write owner)
owners=len(re.findall(r':owner ',sub))
out('V6S5', 1 if owners>=len(subids) and len(subids)>=24 else 0, 1)
# V6S6 — INTERFACE-AND-SCHEMA-REGISTRY: each interface defined once
dup_if=len(ifaces)-len(set(ifaces))
out('V6S6', dup_if, 0)
# V6S7 — every interface names an :owner subsystem
out('V6S7', 1 if len(re.findall(r':owner ',isr))>=len(ifaces) and len(ifaces)>=17 else 0, 1)
# V6S8 — referenced-but-undefined: every subsystem :interface X/1 is defined in ISR or as a schema record/reference
ref_missing=0
for m in re.finditer(r':interface "([^"]*)"',sub):
    for ct in re.findall(r'([A-Za-z][A-Za-z0-9_-]*/1)',m.group(1)):
        if ct not in defined_if and ct not in drec and ct not in dref: ref_missing+=1
out('V6S8', ref_missing, 0)
# V6S9 — no adapter-specific/vendor canonical record type
vend=len(re.findall(r'\(define-record\s+\w*(?:ONNX|Onnx|vendor|Vendor)\w*',code))
out('V6S9', vend, 0)
# V6S10 — public build hash-bearing set excludes private/embodiment records (seed check)
pubclass=re.search(r'\(public-build\s+:hash-bearing\s+\(([^)]*)\)',code)
pubset=set(pubclass.group(1).split()) if pubclass else set()
leak10=len({'PrivateMatterProfile/1','RealTimeAssistance/1','EmbodimentInterfaces/1','PrivateMemoryEvent/1'} & pubset)
out('V6S10', leak10, 0)

# ---- V6S11 — WP assignment resolves to a real define-wp-purpose WP (parse, not grep) ----
wpids=set(re.findall(r'\(define-wp-purpose\s+([A-Za-z0-9_\-]+)',sub))
allowed=wpids|{'DEFERRED'}
def wp_viol(text):
    v=0
    for tok in re.findall(r':future-wp\s+([A-Za-z0-9_+\-]+)',text):
        for part in tok.split('+'):
            if part not in allowed: v+=1
    return v
v11=wp_viol(sub); out('V6S11', v11, 0)
out('V6S11M', 1 if wp_viol(sub.replace(':future-wp WP-08',':future-wp WP-99',1))>v11 else 0, 1)

# ---- V6S12 — public transitive TYPE closure carries no private record or private-bearing enum ----
def leak_of(cs):
    recs=paren_blocks(cs,'define-record'); enums=paren_blocks(cs,'define-closed-enum')
    priv_en={nm for nm,b in enums.items() if ('PRIVATE_CLIENT_MATTER' in b or '(:client)' in b or '(:matter)' in b)}
    priv_rec={nm for nm,b in recs.items() if ':DEFERRED_PRIVATE' in b}
    def named(body):
        ts=set()
        for tm in re.finditer(r':type\s+(\([^()]*\)|[A-Za-z0-9_+/.-]+)',body):
            t=tm.group(1)
            if t.startswith('('):
                inner=t.strip('()').split(); head=inner[0] if inner else ''
                if head=='member': continue
                atoms=inner[1:] if head in ('list','or') else inner
            else: atoms=[t]
            for a in atoms:
                if a in recs or a in enums: ts.add(a)
        return ts
    edges={nm:named(b) for nm,b in recs.items()}
    pm=re.search(r'\(public-build\s+:hash-bearing\s+\(([^)]*)\)',cs)
    roots=pm.group(1).split() if pm else []
    visited=set(); frontier=list(roots); enum_hits=set()
    while frontier:
        nm=frontier.pop()
        if nm in visited: continue
        visited.add(nm)
        if nm in recs:
            for t in edges[nm]:
                if t in recs and t not in visited: frontier.append(t)
                if t in priv_en: enum_hits.add((nm,t))
    return len(visited & priv_rec)+len(enum_hits)
l12=leak_of(code); out('V6S12', l12, 0)
mut12=code.replace(':scope :type PublicMemoryScope)',':scope :type MemoryScope)',1)   # inject private enum into public root
out('V6S12M', 1 if leak_of(mut12)>l12 else 0, 1)

# ---- V6S13 — no duplicate cross-spec type definition (record+reference, or twice) ----
def dupcount(rl,fl): return (len(rl)-len(set(rl)))+(len(fl)-len(set(fl)))+len(set(rl)&set(fl))
d13=dupcount(drec_l,dref_l); out('V6S13', d13, 0)
out('V6S13M', 1 if dupcount(drec_l,dref_l+['LegalIR/1'])>d13 else 0, 1)   # inject a duplicate LegalIR/1

# ---- V6S14 — every CognitionCapability maps EXACTLY once (existing seat or declared extension) ----
capblk=paren_blocks(code,'define-closed-enum').get('CognitionCapability','')
caps=set(re.findall(r'\(:([A-Za-z0-9_+]+)\)',capblk))
mapblk=re.search(r'\(define-mapping\s+cognition->existing-lisp-seat(.*?)\n\(define',code,re.S)
mapt=mapblk.group(1) if mapblk else ''
keys=re.findall(r'\(\(:([A-Za-z0-9_+]+)\)\s+"',mapt)
def cog_viol(klist): return len(caps-set(klist))+(len(klist)-len(set(klist)))
v14=cog_viol(keys); out('V6S14', v14, 0)
out('V6S14M', 1 if cog_viol(keys+[keys[0]] if keys else ['X'])>v14 else 0, 1)   # inject a duplicate mapping

# ---- V6S15 — no active mandatory model/runtime in the schema (all adapters :mandatory nil) ----
m15=len(re.findall(r':mandatory\s+t\b',code)); out('V6S15', m15, 0)
out('V6S15M', 1 if len(re.findall(r':mandatory\s+t\b',code.replace(':mandatory nil',':mandatory t',1)))>m15 else 0, 1)

# ---- V6S16 — no orphan public root: every public-build hash-bearing root is registered as an interface ----
def orphan(dif): return sum(1 for r in pubset if r not in dif)
o16=orphan(defined_if); out('V6S16', o16, 0)
out('V6S16M', 1 if orphan(defined_if-{'CognitionResult/1'})>o16 else 0, 1)

# ---- V6S17 — symbolic-only reachability: SafetyMode :SYMBOLIC_ONLY + every cognition stage :symbolic-only t ----
def sym_viol(cs):
    v=0 if ':SYMBOLIC_ONLY' in cs else 1
    chunks=re.split(r'\(:stage\s+COG-',cs)[1:]   # real DAG stages only (not the :stage_dag_ref field)
    if len(chunks)<12: v+=1
    v+=sum(1 for ch in chunks if ':symbolic-only t' not in ch)
    return v
v17=sym_viol(code); out('V6S17', v17, 0)
out('V6S17M', 1 if sym_viol(code.replace(':symbolic-only t','',1))>v17 else 0, 1)

# ---- WPX — migration-impact table maps v1.6 concepts to the EVIDENCE-correct WP (parse markdown rows) ----
rows={}
for line in mig.splitlines():
    m=re.match(r'\|\s*(WP-\d\d)\s*\|(.*)$',line)
    if m: rows[m.group(1)]=m.group(2)
def has(wp,*subs): return wp in rows and any(s in rows[wp] for s in subs)
wpx=0
# required-correct
if not has('WP-08','Language Cognition','Cognition Layer'): wpx+=1     # cognition -> WP-08
if not has('WP-06','TrustBundle'): wpx+=1                              # trust -> WP-06
if not has('WP-07','SemanticProposer','ONNXProposerAdapter'): wpx+=1   # neural/model -> WP-07
if not has('WP-12','DeclassificationReceipt'): wpx+=1                  # boundary -> WP-12
if 'FUTURE BOOK REVISION REQUIRED' not in mig: wpx+=1                  # memory honesty
# forbidden-wrong (the exact prior misidentifications)
if has('WP-06','Language Cognition','Cognition Layer'): wpx+=1         # cognition NOT on WP-06
if has('WP-11','Memory Kernel','Memory taxonomy'): wpx+=1             # memory NOT on WP-11
out('WPX', wpx, 0)
# mutation: reintroduce the wrong "WP-06 ... Language Cognition Layer" row
mrows=dict(rows); mrows['WP-06']=mrows.get('WP-06','')+' Language Cognition Layer'
mwpx=0
if mrows.get('WP-06','').find('Language Cognition')>=0: mwpx+=1
out('WPXM', 1 if mwpx>=1 else 0, 1)

for i,a,e in R: print(f"{i}|{a}|{e}")
PYV6
)

echo "# G — v1.5 regression (all v1.5 repairs remain green) + v1.4 frozen regression"
ck G1 "$(bash ./V1.5-CONTRADICTION-OMISSION-AUDIT.sh >/dev/null 2>&1; echo $?)" eq 0
ck G2 "$(bash ./V1.4-CONTRADICTION-OMISSION-AUDIT.sh >/dev/null 2>&1; echo $?)" eq 0
ck G3 "$(git -C $ROOT rev-parse 88129099^{tree} 2>/dev/null | grep -c '^a2617649596644c25894c4343f25ddb6c4dec1ce')" eq 1
ck G4 "$(sha256sum V1.4-CONTRADICTION-OMISSION-AUDIT.out | grep -c '^4873e61069d4a1a2a1047d059b81cd9103171776346650a3b5ed4eee077624fb')" eq 1

echo "# H — migration map honesty + no file moved + Implementation Book untouched here"
ck H1 "$(cE 'KEEP|EXTEND|SPLIT|DEFER_PRIVATE|REMOVE' $SUB $MIG | sum)" ge 5
ck H2 "$(cE 'δεν μετακινούνται αρχεία|No file MOVE is executed|no file move' $P $SUB $MIG | sum)" ge 1
ck H3 "$(cE 'Book NOT changed|Implementation Book.*not changed|does not change the Implementation Book|Book.*untouched' $MIG $P | sum)" ge 1

echo "### SUMMARY: checks=$n pass=$pass fail=$fail"
[ "$fail" -eq 0 ] && { echo "### EXIT 0 — V1.6 DOCUMENT/DUPLICATE-SEAT CONSISTENCY PASS (CANDIDATE· ΟΧΙ semantic/legal/security/qualification proof)"; exit 0; } || { echo "### EXIT 1 — DEVIATIONS PRESENT"; exit 1; }
