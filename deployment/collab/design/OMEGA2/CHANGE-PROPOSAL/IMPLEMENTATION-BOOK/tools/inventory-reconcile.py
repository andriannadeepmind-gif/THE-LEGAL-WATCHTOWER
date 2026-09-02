#!/usr/bin/env python3
# LAWMAX OMEGA — INVENTORY RECONCILIATION CHECK (deterministic, pass/fail)
# Implementation Book v1.1 · Deliverable 1. Run from repo root:
#   python3 deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/IMPLEMENTATION-BOOK/tools/inventory-reconcile.py
# Exit 0 = every assertion holds. Exit 1 = a discrepancy exists.
#
# Reconciles the two DISTINCT denominators the numbers 181 and 249 measure, and proves
# the "0 orphan" claim over the Lisp universe with a reproducible check (no bare assertion).
import os, re, glob, sys, subprocess

ROOT = os.path.abspath(os.path.dirname(__file__))
while ROOT != '/' and not (os.path.isdir(os.path.join(ROOT,'source')) and os.path.isdir(os.path.join(ROOT,'.git'))):
    ROOT = os.path.dirname(ROOT)
X = os.path.join(ROOT, 'deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/PUBLIC-OBSERVATORY-CROSSWALK.md')
L = open(X, encoding='utf-8').read().split('\n')
DISP = ['REUSE','EXTEND','REPLACE','REMOVE','DEFER_PRIVATE']

def bound(pat):
    for i,l in enumerate(L):
        if re.match(pat,l): return i
    return None
B = {k:bound(r'^### A\.%s '%k[-1]) for k in ('A1','A2','A3','A4','A5')}
B['END'] = bound(r'^## B\. ')
seq = ['A1','A2','A3','A4','A5','END']
span = {seq[i]:(B[seq[i]], B[seq[i+1]]) for i in range(len(seq)-1)}

def tokens(lo,hi):
    c = {d:0 for d in DISP}
    for l in L[lo:hi]:
        if not l.startswith('|'): continue
        for cell in (x.strip().strip('`* ') for x in l.strip().strip('|').split('|')):
            if cell in c: c[cell]+=1
    return c

def listed(lo,hi):
    return [m.group(1) for l in L[lo:hi] for m in [re.match(r'^\| `([^`]+\.lisp)`',l)] if m]

src = sorted(os.path.basename(p) for p in glob.glob(os.path.join(ROOT,'source','*.lisp')))
cli = sorted(os.path.basename(p) for p in glob.glob(os.path.join(ROOT,'systems','orchestrator-cli','*.lisp')))
a3, a4 = listed(*span['A3']), listed(*span['A4'])
tokA = {k:tokens(*span[k]) for k in ('A1','A2','A3','A4','A5')}
tot = {d: sum(tokA[k][d] for k in tokA) for d in DISP}
lisp = {d: tokA['A3'][d] + tokA['A4'][d] for d in DISP}

checks = []
def ck(name, ok, detail=''):
    checks.append((name, ok, detail)); return ok

ck('lisp_universe=181', len(src)+len(cli)==181, f'source {len(src)} + cli {len(cli)}')
ck('A3_lists_all_source_once', sorted(a3)==src and len(a3)==len(set(a3)),
   f'listed {len(a3)} vs actual {len(src)}; missing {sorted(set(src)-set(a3))}; extra {sorted(set(a3)-set(src))}')
ck('A4_lists_all_cli_once', sorted(a4)==cli and len(a4)==len(set(a4)),
   f'listed {len(a4)} vs actual {len(cli)}; missing {sorted(set(cli)-set(a4))}; extra {sorted(set(a4)-set(cli))}')
ck('lisp_disposition_tokens=181_one_per_file', sum(lisp.values())==181, f'{lisp} sum={sum(lisp.values())}')
ck('full_A_disposition_tokens=249', sum(tot.values())==249, f'{tot} sum={sum(tot.values())}')
ck('A1+A2+A5_nonlisp_tokens=249-181', sum(tot.values())-sum(lisp.values())==68,
   f'nonlisp={sum(tot.values())-sum(lisp.values())} (A1 {sum(tokA["A1"].values())} + A2 {sum(tokA["A2"].values())} + A5 {sum(tokA["A5"].values())})')
ck('no_REPLACE_among_lisp', lisp['REPLACE']==0, f'REPLACE lisp={lisp["REPLACE"]} (all 7 REPLACE are non-lisp)')

print("### INVENTORY RECONCILIATION —", ROOT.split('/')[-1])
print("Denominator A (Lisp universe)      = 181 files = source", len(src), "+ cli", len(cli))
print("  per-file disposition (one each)  =", {d:lisp[d] for d in DISP if lisp[d]}, "sum", sum(lisp.values()))
print("Denominator B (whole §A universe)  = 249 disposition tokens over files+dirs+doc-families")
print("  by subsection:", {k:sum(tokA[k].values()) for k in tokA})
print("  by token     :", tot)
print("  B - A = 68 non-lisp tokens (arch docs A1=18, canonical texts A2=26, verify/scripts A5=24)")
print("0-orphan proof (reproducible): every one of the 181 lisp files is listed exactly once in §A.3/§A.4.")
print()
ok = all(o for _,o,_ in checks)
for name,o,detail in checks:
    print(f"  [{'PASS' if o else 'FAIL'}] {name}   {'' if o else detail}")
print("### RECONCILED" if ok else "### DISCREPANCY")
sys.exit(0 if ok else 1)
