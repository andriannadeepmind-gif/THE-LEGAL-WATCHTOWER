#!/usr/bin/env bash
# V1.6 FUTURE-EXTENSIBILITY DOCUMENT/REFERENCE + DUPLICATE-SEAT CONSISTENCY AUDIT — deterministic.
# Run:  bash deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.6-CONTRADICTION-OMISSION-AUDIT.sh
# Exit 0 = all PASS. Exit 1 = a deviation.
#
# HONEST SCOPE: structural / document-reference / duplicate-seat consistency ONLY over the v1.6 CANDIDATE
# (that every v1.6 contract is defined once and type-closed, ONNX is optional, SYMBOLIC_ONLY is a complete
# path, memory and cognition each have ONE seat, public/private/embodiment is acyclic, registries carry a
# single source of truth with no orphan/dual-seat, and every v1.5 repair regression stays green). It is
# NOT a semantic/legal/security or qualification proof; it executes NONE of the predeclared V6Q/V6KW tests.
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

echo "# F — machine-checkable structural parse of V1.6-SCHEMAS.sexp + registries"
while IFS='|' read -r vid va ve; do
  [ -n "$vid" ] && ck "$vid" "$va" eq "$ve"
done < <(python3 - "$S" "$SUB" "$ISR" <<'PYV6'
import sys,re
schem=open(sys.argv[1],encoding='utf-8').read()
sub=open(sys.argv[2],encoding='utf-8').read()
isr=open(sys.argv[3],encoding='utf-8').read()
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
code=strip(schem)
R=[]
def out(i,a,e): R.append((i,str(a),str(e)))
# V6S1 — paren balance of the schema
d=0;i=0;ins=False;mind=0
for ch in schem:
    pass
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
# V6S2 — the 13 universal contracts all defined as records
need13=['PerceptionEnvelope/1','CandidateInterpretation/1','LegalIR/1','MemoryEvent/1','CapabilityManifest/1',
 'ToolInvocation/1','Plan/1','ActionIntent/1','Approval/1','ExecutionReceipt/1','SafetyState/1','TrustBundle/1',
 'DeclassificationReceipt/1']
drec=set(re.findall(r'\(define-record\s+([A-Za-z0-9_]+/1)',code))
out('V6S2', sum(1 for x in need13 if x in drec), 13)
# V6S3 — reference closure: every :type record/enum atom resolves
den=set(re.findall(r'\(define-closed-enum\s+([A-Za-z0-9_]+)',code))
prim={'id','ref','sha256','sig','instant','scope','semver','text','keyword','pubkey','kid','anchor','usc-id','duration','uncertainty','null','span','mime','url'}
unres=set()
for tm in re.finditer(r':type\s+(\([^()]*\)|[A-Za-z0-9_+/.-]+)',code):
    t=tm.group(1); atoms=[]
    if t.startswith('('):
        inner=t.strip('()').split(); head=inner[0] if inner else ''
        if head=='member': continue
        atoms=[a for a in inner[1:] if a!='null'] if head in ('list','or') else inner
    else: atoms=[t]
    for a in atoms:
        if a in prim or a.startswith(':') or a in drec or a in den: continue
        unres.add(a)
out('V6S3', len(unres), 0)
# V6S4 — SUBSYSTEM-REGISTRY: each subsystem id defined once (no dual seats)
subids=re.findall(r'\(define-subsystem\s+(S\d+)\b',sub)
out('V6S4', len(subids)-len(set(subids)), 0)   # duplicates == 0
# V6S5 — every subsystem has exactly one :owner (single write owner)
owners=len(re.findall(r':owner ',sub))
out('V6S5', 1 if owners>=len(subids) and len(subids)>=24 else 0, 1)
# V6S6 — INTERFACE-AND-SCHEMA-REGISTRY: each interface defined once; owners present
ifaces=re.findall(r'\(define-interface\s+([A-Za-z0-9_/-]+)',isr)
dup_if=len(ifaces)-len(set(ifaces))
out('V6S6', dup_if, 0)
# V6S7 — every interface names an :owner subsystem
out('V6S7', 1 if len(re.findall(r':owner ',isr))>=len(ifaces) and len(ifaces)>=17 else 0, 1)
# V6S8 — referenced-but-undefined: every subsystem :interface referencing an X/1 contract is defined in ISR
defined_if=set(ifaces)
ref_missing=0
for m in re.finditer(r':interface "([^"]*)"',sub):
    for ct in re.findall(r'([A-Za-z][A-Za-z0-9_-]*/1)',m.group(1)):
        if ct not in defined_if and ct not in drec: ref_missing+=1
out('V6S8', ref_missing, 0)
# V6S9 — no adapter-specific/vendor canonical type: no 'onnx'/'vendor' token inside a define-record name
vend=len(re.findall(r'\(define-record\s+\w*(?:ONNX|Onnx|vendor|Vendor)\w*',code))
out('V6S9', vend, 0)
# V6S10 — public build hash-bearing set excludes private/embodiment records
pubclass=re.search(r'\(public-build\s+:hash-bearing\s+\(([^)]*)\)',code)
pubset=set(pubclass.group(1).split()) if pubclass else set()
leak=len({'PrivateMatterProfile/1','RealTimeAssistance/1','EmbodimentInterfaces/1'} & pubset)
out('V6S10', leak, 0)
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
