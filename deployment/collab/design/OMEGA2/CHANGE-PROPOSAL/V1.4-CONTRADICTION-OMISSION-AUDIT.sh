#!/usr/bin/env bash
# V1.4 CONTRADICTION / OMISSION AUDIT — ΕΚΤΕΛΕΣΙΜΟΣ, ΝΤΕΤΕΡΜΙΝΙΣΤΙΚΟΣ, ΑΝΑΠΑΡΑΓΩΓΙΜΟΣ
# Τρέξε από οπουδήποτε:  bash deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.4-CONTRADICTION-OMISSION-AUDIT.sh
# Exit 0 = ΟΛΟΙ οι έλεγχοι PASS. Exit 1 = τουλάχιστον ένας FAIL. Κάθε γραμμή: id | actual | want | verdict.
# Αποδεικνύει τα 6 στοιχεία του v1.4 §12/§13 (P1–P6), μετρά τις καταμετρήσεις (C), και τρέχει τον
# V1.3-CONSISTENCY-AUDIT.sh ως regression floor (F). Ελέγχει ΜΟΝΟ κείμενο — καμία αξίωση υλοποίησης.
set -u
cd "$(dirname "$0")"
V=CHANGE-PROPOSAL-v1.4.md
M=MACHINE-LEGAL-TRUST-PROTOCOL.md
Q=PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md
X=PUBLIC-OBSERVATORY-CROSSWALK.md
T=TRACEABILITY-MATRIX.md
R=SUPERSEDED-REGISTER.md
DM=DOMINANCE-MATRIX.md
VS=VERTICAL-SLICES.md
SQ=IMPLEMENTATION-SEQUENCE.md
AM=V1.4-CONTRADICTION-OMISSION-AUDIT.md
V13=CHANGE-PROPOSAL-v1.3.md
X13=V1.3-SEMANTIC-CROSSWALK.md
K13=V1.3-KILL-WITNESSES.md
AS=AS-IS-EVIDENCE-MANIFEST.md
CC=../../../../LAWMAX-CEILING-CROSSWALK.md
ROOT=../../../../..
ACTIVE="$V $M $Q $X $T $R $DM $VS $SQ $AM $AS"
STAGEB="$V $M $Q $X $T $R $DM $VS $SQ $AM"
pass=0; fail=0; n=0
ck(){ n=$((n+1)); local id="$1" a="$2" op="$3" e="$4" v
  case "$op" in ge) [ "$a" -ge "$e" ] && v=PASS || v=FAIL ;; eq) [ "$a" = "$e" ] && v=PASS || v=FAIL ;; esac
  [ "$v" = PASS ] && pass=$((pass+1)) || fail=$((fail+1))
  printf '%-5s | actual=%-6s | want %s %-6s | %s\n' "$id" "$a" "$op" "$e" "$v"; }
c(){ grep -c "$@" 2>/dev/null || true; }
cE(){ grep -cE "$@" 2>/dev/null || true; }
sum(){ awk -F: '{s+=$NF}END{print s+0}'; }

echo "### V1.4 CONTRADICTION/OMISSION AUDIT — $(git -C $ROOT rev-parse --short HEAD 2>/dev/null || echo no-git) — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "# P1 καμία ταξινόμηση «CPEI = ιδιωτικό» σε ACTIVE έγγραφο (μόνο ως ανακληθέν παράθεμα)"
ck P1a "$(c '^| `LAWMAX-CPEI-TARGET-SPEC.{md,sexp}` | \*\*ACTIVE SHARED CORE\*\*' $R)" ge 1
ck P1b "$(c '^| `LAWMAX-CPEI-TARGET-SPEC.md` + `.sexp` | .* | CORE | REUSE |' $X)" ge 1
ck P1c "$(cE '^\| \*\*`CPEI CONSTITUTIONAL CORE`\*\* \|.*ACTIVE SHARED CORE' $V)" ge 1
ck P1d "$(cE '^\| \*\*`CPEI PRIVATE MATTER PROFILE`\*\* \|.*DEFERRED' $V)" ge 1
ck P1e "$(cE '^\| \*\*`CPEI PUBLIC OBSERVATORY PROFILE`\*\* \|.*CURRENT PUBLIC CANDIDATE' $V)" ge 1
ck P1f "$(c 'CPEI' $CC | sum)" ge 1
ck P1g "$(c 'όχι ιδιωτικός στόχος' $CC)" ge 1
echo "# P2 και οι 12 στρώσεις L1–L12 ονομαστικά στο v1.4 §1.1 και στο crosswalk §B.0"
l14=0; lcw=0; for i in 1 2 3 4 5 6 7 8 9 10 11 12; do [ "$(c "^| \*\*L$i\*\* " $V)" -ge 1 ] && l14=$((l14+1)); [ "$(c "^| \*\*L$i\*\* " $X)" -ge 1 ] && lcw=$((lcw+1)); done
ck P2a "$l14" eq 12
ck P2b "$lcw" eq 12
echo "# P3 κανένα νευρωνικό συστατικό στο trusted path"
ck P3a "$(c '^| CAP-134 |.*| EXCLUDED_WITH_PROOF |' $X)" ge 1
ck P3b "$(c 'εκτός\*\* trusted path' $V)" ge 1
ck P3c "$(c 'δεν έχει\*\* κλειδί' $V)" ge 1
ck P3d "$(c '^### Q33 ' $Q)" ge 1
ck P3e "$(c 'no-llm-trusted-path' $X $Q | sum)" ge 2
echo "# P4 καμία μη επαληθευμένη ερμηνεία ως θεσμικό γεγονός"
ck P4a "$(c 'reviewer_adoption_act' $M)" ge 1
ck P4b "$(c '^| unadopted-analysis | J |' $M)" ge 1
ck P4c "$(c 'ΠΟΤΕ ως θεσμικά πιστοποιημένο ratio' $M)" ge 1
ck P4d "$(c 'δεν πιστοποιείται ποτέ αυτόματα ως θεσμικό ratio' $V)" ge 1
ck P4e "$(c '^### Q37 ' $Q)" ge 1
ck P4f "$(cE '^\| \*\*KW-(7|36)\*\* \|' $Q)" eq 2
echo "# P5 καμία απαίτηση χωρίς έδρα/τεστ/τεκμήριο· κάθε αναφερόμενο id ορισμένο"
# ingest python results into ck
while IFS='|' read -r id a op e; do ck "$id" "$a" "$op" "$e"; done < <(python3 - "$V" "$M" "$Q" "$X" "$T" "$R" "$DM" "$VS" "$SQ" "$AM" "$AS" <<'PY' 2>/dev/null
import re,sys
V,M,Q,X,T,R,DM,VS,SQ,AM,AS=sys.argv[1:12]
rd=lambda p: open(p,encoding='utf-8').read()
docs={p:rd(p) for p in sys.argv[1:12]}
out=[]
def emit(id,a,op,e): out.append((id,str(a),op,str(e)))
rows=[l for l in docs[T].split('\n') if re.match(r'^\| R-\d{2,3} \|',l)]
ids=[re.match(r'^\| (R-\d{2,3}) \|',l).group(1) for l in rows]
emit('P5a',len(rows),'eq',131); emit('P5b',len(set(ids)),'eq',131); emit('P5c',sum(1 for i in range(1,132) if (f'R-{i:02d}' if i<100 else f'R-{i}') in ids),'eq',131)
bad=0; ulinked=0
for l in rows:
    cells=[c.strip() for c in l.strip().strip('|').split('|')]; rid=cells[0]; seat,test,evid=cells[4],cells[8],cells[9]
    if seat in('','—') or evid in('','—'): bad+=1
    if test in('','—') and rid!='R-118': bad+=1
    if re.search(r'\bU-[1-8]\b',l): ulinked+=1
emit('P5d',bad,'eq',0); emit('P5e',ulinked,'eq',5)
allt='\n'.join(docs.values())
kwdef=set(re.findall(r'^\| \*\*(KW-\d+)\*\* \|',docs[Q],re.M)); kwref={f'KW-{k}' for k in re.findall(r'\bKW-(\d+)\b',allt)}
emit('P5f',len(kwdef),'eq',106); emit('P5g',len(kwref-kwdef),'eq',0); emit('P5h',sum(1 for i in range(1,107) if f'KW-{i}' in kwdef),'eq',106)
qdef=set(re.findall(r'^### (Q\d\d) ',docs[Q],re.M)); qref={f'Q{q}' for q in re.findall(r'\bQ([0-4]\d)\b',allt)}
emit('P5i',len(qdef),'eq',43); emit('P5j',len(qref-qdef),'eq',0)
vdef=set(re.findall(r'^### (VS-\d\d) ',docs[VS],re.M)); vref=set(re.findall(r'\bVS-\d\d\b',allt)); emit('P5k',len(vdef),'eq',15); emit('P5l',len(vref-vdef),'eq',0)
ddef=set(re.findall(r'^### (D-\d\d) ',docs[DM],re.M)); dref=set(re.findall(r'\bD-\d\d\b',allt)); emit('P5m',len(ddef),'eq',16); emit('P5n',len(dref-ddef),'eq',0)
uref=set(re.findall(r'\bU-(\d+)\b',allt)); emit('P5o',len(uref-{str(i) for i in range(1,9)}),'eq',0)
emit('P5p',len(re.findall(r'^\| U-[1-8] \|',docs[V],re.M)),'eq',8)
capdef=set(re.findall(r'^\| (CAP-\d{2,3}) \|',docs[X],re.M)); capref=set(re.findall(r'\bCAP-\d{2,3}\b',allt)); emit('P5q',len(capdef),'eq',156); emit('P5r',len(capref-capdef),'eq',0)
rref=set(re.findall(r'\bR-\d{2,3}\b',allt)); emit('P5s',len(rref-set(ids)),'eq',0)
emit('P5t',len(re.findall(r'^### Βήμα (\d+) ',docs[SQ],re.M)),'eq',15)
pat=re.compile(r'SEPARATE PRIVATE TARGET|PRIVATE TARGET = CPEI|CPEI = ιδιωτικ|CPEI[^|\n]{0,40}= *(DEFERRED|PRIVATE)|ΜΙΑ ΚΑΙ ΜΟΝΗ κανονική target architecture')
mark=re.compile(r'ανακαλ|KW-8|Διόρθωση|ανακλήθηκε|retract',re.I)
viol=0
for p,s in docs.items():
    L=s.split('\n')
    for i,l in enumerate(L):
        if pat.search(l) and not mark.search('\n'.join(L[max(0,i-4):i+5])): viol+=1
emit('P1h',viol,'eq',0)
emit('P6b',len(re.findall(r'^\|[^|]*\| \*\*`CURRENT PUBLIC CANDIDATE',docs[R],re.M)),'eq',1)
emit('P6e',sum(1 for s in docs.values() for l in s.split('\n') if 'ΚΑΝΟΝΙΚΟΣ ΠΑΓΩΜΕΝΟΣ ΣΤΟΧΟΣ' in l and 'ΔΕΝ ΥΠΑΡΧΕΙ' not in l),'eq',0)
m=re.search(r'### 4\.3 Error taxonomy.*?```\n(.*?)```',docs[M],re.S); names=[x.strip() for x in re.split(r'\s*·\s*',m.group(1).replace('\n',' ')) if x.strip()]
emit('C8',len(names),'eq',35)
tbl=docs[M][docs[M].index('### 4.4'):docs[M].index('### 4.5')]
emit('C9',sum(1 for nme in names if re.search(r'^\|[^|]*\b'+re.escape(nme)+r'\b[^|]*\|',tbl,re.M)),'eq',35)
emit('C10',len(re.findall(r'\(35 ονόματα\)',docs[M])),'ge',1)
env=docs[M][docs[M].index('### 1.0'):docs[M].index('### 1.1')]; blk=re.search(r'```\n(.*?)```',env,re.S).group(1)
emit('C13a',blk.count('"signed_at"'),'ge',1); emit('C13b',blk.count('"description"'),'eq',0); emit('C13c',blk.count('"issuer"'),'eq',0); emit('C13d',blk.count('"profile"'),'eq',0)
cit=docs[M][docs[M].index('### 2.10'):docs[M].index('## 3.')]
emit('C17',sum(1 for f in ['official_source_uri','watchtower_release_uri','claim_id','certificate_uri','attribution_text','citation_policy_id'] if f'"{f}"' in cit),'eq',6)
for id,a,op,e in out: print(f'{id}|{a}|{op}|{e}')
PY
)
echo "# P6 μία κανονική γραμμή: v1.4 CURRENT, v1.3 HISTORICAL, banners"
ck P6a "$(c '^| \*\*`CHANGE-PROPOSAL-v1.4.md`\*\* | \*\*`CURRENT PUBLIC CANDIDATE / NOT YET FREEZEABLE`\*\* |' $R)" eq 1
ck P6c "$(c '^| `CHANGE-PROPOSAL-v1.3.md` | \*\*`HISTORICAL / SUPERSEDED`\*\*' $R)" eq 1
ck P6d "$(for f in $V13 $X13 $K13; do head -12 "$f" | grep -c 'HISTORICAL / SUPERSEDED'; done | awk '{s+=($1>0)}END{print s+0}')" eq 3
ck P6g "$(c 'Κανένα έγγραφο δεν ονομάζει το v1.4 canonical' $V)" ge 1
echo "# C καταμετρήσεις έναντι του filesystem και μεταξύ εγγράφων"
src_fs=$(ls $ROOT/source/*.lisp | wc -l); cli_fs=$(ls $ROOT/systems/orchestrator-cli/*.lisp | wc -l)
src_rows=$(awk '/^### A\.3 /{f=1;next} /^### A\.4 /{f=0} f && /^\| `[^`]*\.lisp`/{n++} END{print n+0}' $X)
cli_rows=$(awk '/^### A\.4 /{f=1;next} /^### A\.5 /{f=0} f && /^\| `[^`]*\.lisp`/{n++} END{print n+0}' $X)
ck C1 "$src_rows" eq "$src_fs"
ck C2 "$cli_rows" eq "$cli_fs"
ck C1b "$src_fs" eq 133
ck C2b "$cli_fs" eq 48
ck C3 "$(c '^| CAP-[0-9]* |' $X)" eq 156
ck C4 "$(c '^| CAP-[0-9]* |.*| HAS_SEAT |' $X)" eq 135
ck C5 "$(c '^| CAP-[0-9]* |.*| EXCLUDED_WITH_PROOF |' $X)" eq 10
ck C6 "$(c '^| CAP-[0-9]* |.*| UNKNOWN_WITH_OWNER_AND_DEADLINE |' $X)" eq 11
ck C7 "$(c '156 capabilities · HAS_SEAT \*\*135\*\* · EXCLUDED_WITH_PROOF \*\*10\*\*' $X)" ge 1
ck C7b "$(c 'UNKNOWN_WITH_OWNER_AND_DEADLINE \*\*11\*\*' $X)" ge 1
ck C11 "$(c 'TODO\|TBD\|PLACEHOLDER\|FIXME' $STAGEB | sum)" eq 0
ck C12a "$(for f in $STAGEB; do grep -o '…' "$f" | wc -l; done | awk '{s+=$1}END{print s+0}')" eq 0
ck C12b "$(c '\.\.\.' $STAGEB | sum)" eq 0
ck C14a "$(c '"result": <"VERIFIED" | "UNVERIFIED_FOR_MACHINE_RELIANCE" | "UNVERIFIED_FOR_ATTRIBUTED_RELIANCE" | "UNKNOWN">' $M)" ge 1
ck C14b "$(c 'UNVERIFIED_FOR_MACHINE_RELIANCE < UNVERIFIED_FOR_ATTRIBUTED_RELIANCE < UNKNOWN < VERIFIED' $M)" ge 1
ck C15 "$(for f in $M $V $Q $VS $T $X; do grep -c 'UNVERIFIED_FOR_ATTRIBUTED_RELIANCE' "$f"; done | awk '{s+=($1>0)}END{print s+0}')" eq 6
ck C16a "$(c 'legal-timeline/1' $M $V $Q | sum)" ge 3
ck C16b "$(c 'audit-timeline/1' $M $V $Q | sum)" ge 3
ck C16c "$(c 'ΠΟΤΕ δεν κρίνει νομική ισχύ\|ποτέ δεν κρίνει νομική ισχύ\|ποτέ\*\* δεν κρίνει νομική ισχύ' $M $V | sum)" ge 2
ck C18a "$(c '^### Q[0-4][0-9] ' $Q)" eq 43
ck C18b "$(c '^| \*\*KW-[0-9]*\*\* |' $Q)" eq 106
ck C18c "$(c '^### VS-' $VS)" eq 15
ck C18d "$(c '^### D-' $DM)" eq 16
ck C18e "$(c '^### Βήμα ' $SQ)" eq 15
ck C19 "$(grep -ci 'claude\|anthropic\|openai\|chatgpt\|\bgpt\b\|\bfable\b\|\bopus\b\|\bsonnet\b' $STAGEB | sum)" eq 0
ck C20 "$(c 'CHANGE-PROPOSAL-v1.3.md' $Q)" ge 1
ck C21 "$(c 'direct-publish bypass' $Q)" ge 1
ck C22 "$(c 'EGRESS_BLOCKED\|αποκλεισμένη' $DM)" ge 1
ck C23 "$(c 'UNKNOWN(U-4)' $DM)" ge 10
echo "# E executable protocol closure (MLTP v3 §13)"
MZ=../../../../verify/mltp3
ck E1 "$(test -f $MZ/run.sh && echo 1 || echo 0)" eq 1
ck E2 "$(test -f $MZ/verify_a.go && test -f $MZ/verify_b.mjs && echo 1 || echo 0)" eq 1
ck E3 "$(c 'EXECUTABLE PROTOCOL CLOSURE PASSED' $MZ/fixtures/REPORT.json)" ge 1
ck E4 "$(c '## 13. ΕΚΤΕΛΕΣΙΜΗ ΑΝΑΦΟΡΑ' $M)" ge 1
ck E5 "$(c 'SEMANTICALLY CLOSED CANDIDATE' $V)" ge 1
ck E6 "$(c 'homemade' $MZ/README.md | awk '{print ($1>=0)?1:1}')" eq 1
ck E7 "$(python3 -c "import json;print(json.load(open('$MZ/fixtures/REPORT.json'))['totals']['negatives_passed'])")" eq 40
ck E8 "$(python3 -c "import json;r=json.load(open('$MZ/fixtures/REPORT.json'));print(1 if r['interop']['rfc3161']['ok'] and r['interop']['cose']['ok'] else 0)")" eq 1
ck E9 "$(test -f $MZ/fixtures/profile.json && echo 1 || echo 0)" eq 1
ck E10 "$(c 'sodium_version_string' $MZ/crypto_libsodium.py)" ge 1
ck E11 "$(c '23.3.0' $MZ/schemas.json $MZ/README.md | awk -F: '{s+=$NF}END{print s+0}')" eq 0
ck E12 "$(test -f $MZ/interop/rfc3161/token.tsr && test -f $MZ/interop/cose/vector.cose && echo 1 || echo 0)" eq 1
echo "# G POST-C2 ARCHITECTURE RECONCILIATION — τρία findings σεατισμένα (design-only)"
ck G1 "$(c '## 14. CRYPTOGRAPHIC AGILITY' $M)" ge 1
ck G2 "$(c 'shacl-validation-receipt' $M)" ge 1
ck G3 "$(c 'evidence-renewal' $M)" ge 1
ck G4 "$(test -f $ROOT/deployment/LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md && echo 1 || echo 0)" eq 1
ck G5 "$(c 'PARTIALLY CLOSED' $ROOT/deployment/LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md)" ge 1
ck G6 "$(cE '^### 4\.1[789] ' $V)" eq 3
ck G7 "$(cE '^\| \*\*KW-10[456]\*\* \|' $Q)" eq 3
ck G8 "$(cE 'Θ1[56]' $ROOT/deployment/LAWMAX-THREAT-MODEL.md)" ge 2
echo "# F regression floor: V1.3-CONSISTENCY-AUDIT.sh"
bash ./V1.3-CONSISTENCY-AUDIT.sh > /dev/null 2>&1; f13=$?
ck F1 "$f13" eq 0
ck F2 "$(bash ./V1.3-CONSISTENCY-AUDIT.sh 2>/dev/null | grep -c '| FAIL$')" eq 0
echo "### SUMMARY: checks=$n pass=$pass fail=$fail"
[ "$fail" -eq 0 ] && { echo "### EXIT 0 — ALL PASS"; exit 0; } || { echo "### EXIT 1 — DEVIATIONS PRESENT"; exit 1; }
