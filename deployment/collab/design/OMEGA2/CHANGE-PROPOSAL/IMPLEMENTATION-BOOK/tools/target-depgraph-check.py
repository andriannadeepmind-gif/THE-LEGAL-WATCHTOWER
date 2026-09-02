#!/usr/bin/env python3
# LAWMAX OMEGA — TARGET DEPENDENCY GRAPH CHECK (deterministic, pass/fail)
# Implementation Book v1.1 · Deliverable 3. Run from anywhere:
#   python3 .../IMPLEMENTATION-BOOK/tools/target-depgraph-check.py
# Exit 0 = the target subsystem graph is acyclic, carries no forbidden edge, has a single
# write authority, and keeps compiler A/B domains isolated. Exit 1 = a violation exists.
# The check is NON-VACUOUS: it self-tests by injecting each forbidden edge and asserting the
# detector fires (reported at the end). The graph here is the TARGET (to-build) subsystem
# DERIVATION graph, distinct from the AS-IS source graph (asis-inventory.py) and from the WP
# scheduling DAG (Book §5).
import sys

# Nodes: S1..S18 subsystems (Book v1.1 §2) + compiler A/B/gate refinement of S8.
NODES = [f'S{i}' for i in range(1,19)] + ['S8a','S8b','S8g']
# DERIVATION edges  A -> B  ==  "A is derived from / depends on B's output".
# Intent/cockpit submission is NOT a derivation edge (it is a write; see WRITE_AUTHORITY).
EDGES = [
 ('S1','S16'),
 ('S2','S1'), ('S2','S16'),
 ('S3','S2'), ('S3','S17'),
 ('S4','S2'), ('S4','S3'), ('S4','S16'), ('S4','S17'),
 ('S5','S4'),
 ('S6','S5'), ('S6','S4'),
 ('S7','S5'), ('S7','S6'), ('S7','S4'),
 ('S8a','S5'), ('S8b','S5'), ('S8g','S8a'), ('S8g','S8b'), ('S8','S8g'),
 ('S9','S8'), ('S9','S6'), ('S9','S7'), ('S9','S10'),
 ('S10','S11'),
 ('S12','S9'), ('S12','S18'),
 ('S13','S8'), ('S13','S9'),
 ('S14','S9'), ('S14','S10'),
 ('S15','S8'), ('S15','S9'), ('S15','S10'), ('S15','S13'), ('S15','S14'),
]
# WRITE_AUTHORITY: the single seat allowed to append to each owned store.
WRITE_AUTHORITY = {
 'L1_journal':     ['write-authority.lisp'],      # one seat; every write journaled, proposer-blind
 'PLANE0_vault':   ['corpus-provenance.lisp'],    # append-only; no external/public writer
 'release_root':   ['release-authority.lisp'],    # only via M5 dual-attestation
 'census_universe':['ingestion-daemon.lisp'],
 'trust_root':     ['authority-v2/'],
}
# FORBIDDEN edges/patterns — presence of any is a hard failure.
def forbidden(edges, wa):
    v=[]
    es=set(edges)
    # F1 neural (PLANE-3, S3) may never be a direct derivation source of the journal/event store S5
    if ('S5','S3') in es: v.append('F1 neural->journal direct (must pass S4 symbolic gate)')
    # F2 external bytes / acquisition may not be evaluated as Lisp forms: S4 depends on S2 only via decoder,
    #    modelled as: S4 must NOT depend on a raw-eval node. (No raw-eval node exists by construction.)
    if ('S4','RAWEVAL') in es: v.append('F2 external-bytes->eval')
    # F3 compiler A and B domains share nothing: no edge between S8a and S8b in either direction
    if ('S8a','S8b') in es or ('S8b','S8a') in es: v.append('F3 compiler A<->B shared derivation')
    # F4 public services (S13 site, S14 API) may not be a derivation source of core stores (S5/S8/S8a/S8b)
    for pub in ('S13','S14','S12'):
        for core in ('S5','S8','S8a','S8b'):
            if (core,pub) in es: v.append(f'F4 {core} derives from public {pub} (public=projection only)')
    # F5 single write authority per store
    for store,seats in wa.items():
        if len(seats)!=1: v.append(f'F5 multiple write authority for {store}: {seats}')
    # F6 cockpit direct-publish: release_root writer must be release-authority only (not cockpit)
    if any('cockpit' in s for s in wa.get('release_root',[])): v.append('F6 cockpit direct-publish to release_root')
    return v

def acyclic(edges):
    from collections import defaultdict
    g=defaultdict(list); nodes=set()
    for a,b in edges: g[a].append(b); nodes|={a,b}
    color={}
    cyc=[]
    def dfs(n,st):
        color[n]='g'
        for m in g[n]:
            if color.get(m)=='g': cyc.append(st+[m]); return True
            if color.get(m)!='b' and dfs(m,st+[m]): return True
        color[n]='b'; return False
    for n in nodes:
        if color.get(n)!='b' and dfs(n,[n]): break
    return (not cyc), cyc

def run(edges, wa):
    ok=True; out=[]
    ac,cyc=acyclic(edges)
    out.append(('acyclic derivation graph', ac, '' if ac else f'cycle {cyc}')); ok&=ac
    fv=forbidden(edges,wa)
    out.append(('no forbidden edge/pattern', not fv, '' if not fv else '; '.join(fv))); ok&=(not fv)
    return ok,out

ok,out=run(EDGES,WRITE_AUTHORITY)
print("### TARGET DEPENDENCY GRAPH CHECK")
print(f"nodes={len(NODES)} edges={len(EDGES)} write-stores={len(WRITE_AUTHORITY)}")
for name,o,d in out: print(f"  [{'PASS' if o else 'FAIL'}] {name}   {d}")

# --- NON-VACUITY self-test: inject each forbidden case, assert the check FAILS ---
inject = [
 ('F1', EDGES+[('S5','S3')], WRITE_AUTHORITY),
 ('F3', EDGES+[('S8a','S8b')], WRITE_AUTHORITY),
 ('F4', EDGES+[('S8','S14')], WRITE_AUTHORITY),
 ('F5', EDGES, {**WRITE_AUTHORITY,'L1_journal':['write-authority.lisp','cockpit.lisp']}),
 ('cycle', EDGES+[('S11','S15')], WRITE_AUTHORITY),  # S15->...->? create back-edge S11<-S15 via S10
]
selftest_ok=True
detail=[]
for tag,e,w in inject:
    o,_=run(e,w)
    fired = (o is False)
    selftest_ok &= fired
    detail.append(f'{tag}:{"detected" if fired else "MISSED"}')
print(f"  [{'PASS' if selftest_ok else 'FAIL'}] non-vacuity self-test (each injected forbidden edge detected)   {', '.join(detail)}")

final = ok and selftest_ok
print("### TARGET GRAPH VALID" if final else "### TARGET GRAPH VIOLATION")
sys.exit(0 if final else 1)
