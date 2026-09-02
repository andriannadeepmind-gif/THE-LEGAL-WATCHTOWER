#!/usr/bin/env python3
# LAWMAX OMEGA — MACHINE-READABLE TRACEABILITY (deterministic, pass/fail)
# Implementation Book v1.1 · Deliverable 9. Run from repo root:
#   python3 .../IMPLEMENTATION-BOOK/tools/traceability-build.py
# Emits TRACEABILITY-MACHINE.tsv (Requirement -> WP -> subsystem -> seat file -> test ->
# evidence, one row per R-01..R-134) and checks: every R has a WP, a non-empty seat and a
# non-empty test. Exit 0 = complete. Exit 1 = a gap.
#
# SCOPE (honest): rows join the FROZEN TRACEABILITY-MATRIX (R -> seat/test/evidence) to the
# verified R->WP map (Book v1.1 §11.1). The top-level *symbol* column is bound at the WP
# element granularity for the CONSTRUCTION SURFACE (new/modified symbols in each WP file).
# Per-symbol Requirement+test binding for the 4053 PRE-EXISTING REUSE symbols is declared
# UNKNOWN here (evidence category [3] legal / [4] security review), never faked as bound.
import os, re, sys

ROOT = os.path.abspath(os.path.dirname(__file__))
while ROOT != '/' and not (os.path.isdir(os.path.join(ROOT,'source')) and os.path.isdir(os.path.join(ROOT,'.git'))):
    ROOT = os.path.dirname(ROOT)
T = os.path.join(ROOT,'deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/TRACEABILITY-MATRIX.md')
OUT = os.path.dirname(__file__)

def R2WP(n):
    m = {**{r:'WP-01' for r in range(1,14)}, **{r:'WP-02' for r in range(14,24)},
         **{r:'WP-07' for r in range(24,31)}, **{r:'WP-03' for r in range(31,39)},
         39:'WP-05',40:'WP-04',41:'WP-05',42:'WP-05',43:'WP-04',
         **{r:'WP-11' for r in range(44,48)}, **{r:'WP-10' for r in range(48,51)},
         **{r:'WP-09' for r in range(51,57)}, **{r:'WP-06' for r in range(57,71)},
         71:'WP-11',72:'WP-11',73:'WP-11', **{r:'WP-12' for r in range(74,82)},
         82:'WP-13',83:'WP-13',84:'WP-13',
         85:'WP-00',86:'WP-00',87:'WP-00',88:'WP-00',89:'WP-06',90:'WP-06',91:'WP-12',
         92:'WP-06',93:'WP-13',94:'WP-06',95:'WP-13',96:'WP-13',97:'WP-13',98:'WP-13',
         99:'WP-00',100:'WP-00', **{r:'WP-11' for r in range(101,111)},
         111:'WP-12', **{r:'WP-14' for r in range(112,119)}, **{r:'WP-11' for r in range(119,125)},
         **{r:'WP-06' for r in range(125,129)}, 129:'WP-08',130:'WP-06',131:'WP-07',
         132:'WP-01',133:'WP-02',134:'WP-06'}
    return m.get(n)
WP2SUB = {'WP-00':'S11/S15','WP-01':'S1/S16','WP-02':'S2','WP-03':'S4/S5','WP-04':'S8a',
          'WP-05':'S8b/S8g','WP-06':'S10/S11','WP-07':'S2/S3/S17','WP-08':'S4','WP-09':'S7',
          'WP-10':'S5/S6','WP-11':'S9/S14','WP-12':'S12/S13/S18','WP-13':'S15','WP-14':'qualification'}

rows={}
for l in open(T,encoding='utf-8'):
    m=re.match(r'^\| (R-\d{2,3}) \|',l)
    if not m: continue
    cells=[c.strip() for c in l.strip().strip('|').split('|')]
    rid=cells[0]; n=int(rid.split('-')[1])
    seat=cells[4] if len(cells)>4 else ''
    test=cells[8] if len(cells)>8 else ''
    evid=cells[9] if len(cells)>9 else ''
    rows[n]=dict(rid=rid, mission=cells[1] if len(cells)>1 else '', seat=seat, test=test, evid=evid)

lines=[]; gaps=[]
for n in range(1,135):
    r=rows.get(n)
    wp=R2WP(n)
    if not r:
        gaps.append(f'{n}:no-matrix-row');
        lines.append('\t'.join([f'R-{n:02d}' if n<100 else f'R-{n}', wp or 'UNKNOWN', WP2SUB.get(wp,'UNKNOWN'),'UNKNOWN','UNKNOWN','UNKNOWN']))
        continue
    sub=WP2SUB.get(wp,'UNKNOWN')
    if not wp: gaps.append(f'{r["rid"]}:no-WP')
    if not r['seat'] or r['seat']=='—': gaps.append(f'{r["rid"]}:no-seat')
    if not r['test'] or r['test']=='—':
        # R-118 is the predeclared programme (explicitly not executed in frozen matrix)
        if r['rid']!='R-118': gaps.append(f'{r["rid"]}:no-test')
    lines.append('\t'.join([r['rid'], wp or 'UNKNOWN', sub, r['seat'] or 'UNKNOWN', r['test'] or 'UNKNOWN', r['evid'] or 'UNKNOWN']))

with open(os.path.join(OUT,'TRACEABILITY-MACHINE.tsv'),'w',encoding='utf-8') as f:
    f.write('requirement\twork_packet\tsubsystem\tseat_file\ttest(Q/KW/VS)\tevidence\n')
    f.write('\n'.join(lines)+'\n')

print("### MACHINE TRACEABILITY — R-01..R-134 ->", len({R2WP(n) for n in range(1,135)}), "work packets")
print("rows written:", len(lines))
print("R covered by a WP:", sum(1 for n in range(1,135) if R2WP(n)), "/134")
print("gaps (want none, R-118 test exempt):", gaps or "NONE")
print("wrote: TRACEABILITY-MACHINE.tsv")
sys.exit(0 if not gaps else 1)
