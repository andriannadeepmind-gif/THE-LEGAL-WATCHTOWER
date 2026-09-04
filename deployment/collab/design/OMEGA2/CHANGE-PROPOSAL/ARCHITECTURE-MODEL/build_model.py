#!/usr/bin/env python3
"""MIGRATION (one-time provenance): emit the canonical ARCHITECTURE-MODEL from the existing v1.6-v1.8 registries.
After this migration the emitted ARCHITECTURE-MODEL/*.sexp modules are the SINGLE SOURCE OF TRUTH; the old
registries become CANONICAL_MODEL_INPUT (migration input) + GENERATED views. This script is NOT part of the
verification path (the kernel and the independent checker read only the emitted model). Deterministic output."""
import importlib.util, os, sys, hashlib, collections
HERE=os.path.dirname(os.path.abspath(__file__)); CP=os.path.dirname(HERE)
# The migration sources are read through the repository's single classified reader seat. The historical
# v1.8 harness is NOT imported here: a file classified HISTORICAL_EVIDENCE / NON_AUTHORITATIVE_GATE cannot be
# a live dependency of the model that supersedes it.
_spec=importlib.util.spec_from_file_location('sexp_reader',os.path.join(HERE,'SEXP-READER.py'))
SR=importlib.util.module_from_spec(_spec); _spec.loader.exec_module(SR)
def R(p):
    try: return SR.read_forms_file(os.path.join(CP,p), SR.REGISTRY)
    except SR.MissingSourceFile as e:
        sys.stderr.write('MISSING-SOURCE-FILE: %s\n'%e.path); sys.exit(5)
    except SR.SexpError as e:
        sys.stderr.write('UNREADABLE-SOURCE-FILE: %s\n'%e); sys.exit(5)
def head(f): return SR.head(f)
def form_name(f): return f[1] if (isinstance(f,list) and len(f)>1 and isinstance(f[1],SR.Sym)) else None
def kv(f,k): return SR.kv(f,k)
def T(x):
    """Exact source text of a scalar token: a keyword keeps its leading colon, so a registry value written
    as :RESTRICTED is never confused with a bare symbol RESTRICTED."""
    return (':'+str(x)) if isinstance(x,SR.Kw) else str(x)
def edge_pairs(node):
    return [(str(e[0]),str(e[1])) for e in node if isinstance(e,list) and len(e)>=2
            and isinstance(e[0],SR.Sym) and isinstance(e[1],SR.Sym)] if isinstance(node,list) else []
def syms(node): return [str(x) for x in node if isinstance(x,(SR.Sym,SR.Str))] if isinstance(node,list) else []
conflicts=[]

# ---- subsystems ----
subs={}
for f in R('SUBSYSTEM-REGISTRY.sexp'):
    if head(f) is not None and head(f)=='define-subsystem':
        sid=str(form_name(f))
        subs[sid]=dict(mission=T(kv(f,'mission')),req=T(kv(f,'requirement')),test=T(kv(f,'test')),
                       wp=T(kv(f,'future-wp')),migration=T(kv(f,'migration')),owner=T(kv(f,'owner')))
priv_sub={s for s,d in subs.items() if d['migration']=='DEFER_PRIVATE'}

# ---- types/interfaces ----
types={}; consumes=[]; components={}
_isr=[f for f in R('INTERFACE-AND-SCHEMA-REGISTRY.sexp') if head(f) is not None and head(f)=='define-interface']
for f in _isr:                                   # pass 1: collect all type names first
    types[str(form_name(f))]=dict(owner=T(kv(f,'owner')),cls=T(kv(f,'classification')))
for f in _isr:                                   # pass 2: consumes edges + non-subsystem/non-type consumers => components
    nm=str(form_name(f))
    for c in syms(kv(f,'consumers')):
        consumes.append((c,nm))
        if c not in subs and c not in types and c not in components:
            components[c]='S03'                  # proposers / legal-extraction-verify.lisp are S03 components (SemanticProposer is a type)
# classification: private if RESTRICTED or owned by a private subsystem
def type_cls(nm):
    d=types[nm]
    if d['cls']==':RESTRICTED' or d['owner'] in priv_sub: return 'PRIVATE'
    return 'PUBLIC'
def sub_cls(sid): return 'PRIVATE' if sid in priv_sub else 'PUBLIC'

# ---- stores ----
stores={}
for f in R('V1.8-SCHEMAS.sexp'):
    if head(f) is not None and head(f)=='define-write-authority':
        st=T(kv(f,'store')); stores[st]=dict(owner=T(kv(f,'owner')),writer=T(kv(f,'write-authority')))

# ---- pipeline stages (the acyclic PERMITTED dependency graph) ----
stages=[]; stage_edges=[]
for f in R('V1.8-SCHEMAS.sexp'):
    if head(f) is not None and head(f)=='define-pipeline':
        stages=[str(x) for x in kv(f,'nodes')]
        stage_edges=[(a,b) for a,b in edge_pairs(kv(f,'edges'))]

# ---- requirements/tests/wps ----
def wp_tokens(w):
    # composite WP tokens like WP-07+WP-08 -> list; FUTURE markers stay whole
    return w.split('+') if ('+' in w and w.startswith('WP-')) else [w]
reqs=sorted({d['req'] for d in subs.values()})
tests=sorted({d['test'] for d in subs.values()})
wps=sorted({t for d in subs.values() for t in wp_tokens(d['wp'])})

# ---- data-flow cycle detection (recorded, NOT a defect: acyclicity law applies to stages) ----
edges=set()
for c,nm in consumes:
    o=types[nm]['owner']
    if c in subs and c!=o: edges.add((c,o))
# Deterministic enumeration: sorted adjacency, sorted start order, and each cycle canonicalised to its
# lexicographically smallest rotation and de-duplicated. A set iteration order must never decide what an
# architecture record says.
adj=collections.defaultdict(list)
for a,b in sorted(edges): adj[a].append(b)
for a in adj: adj[a].sort()
col=collections.defaultdict(int); cyc=[]
def dfs(u,st):
    col[u]=1; st.append(u)
    for w in adj[u]:
        if col[w]==1: cyc.append(st[st.index(w):])
        elif col[w]==0: dfs(w,st)
    col[u]=2; st.pop()
for u in sorted(subs):
    if col[u]==0: dfs(u,[])
def canon(c):
    k=min(range(len(c)),key=lambda i:c[i:]+c[:i]); r=c[k:]+c[:k]; return tuple(r+[r[0]])
cyc=sorted({canon(c) for c in cyc})
for c in cyc:
    conflicts.append(('DATAFLOW-CYCLE','subsystem consumer/data-flow graph','->'.join(c),
        'RECORD as non-invariant: the acyclic law (L4) governs the PERMITTED processing pipeline (stage graph), '
        'not runtime data-flow; data-flow legitimately cycles (reactive cockpit<->cognition<->trust).',
        ':V6I-17 + pipeline symbolic-only-path','both graphs preserved','none','no creator approval required'))
# composite WP tokens
for sid,d in subs.items():
    if len(wp_tokens(d['wp']))>1:
        conflicts.append(('COMPOSITE-WP','SUBSYSTEM-REGISTRY '+sid,d['wp'],
            'SPLIT into one wp-map fact per WP token (each resolves to a declared wp fact).',
            ':SR-V6-one-seat','all WP tokens preserved','revert to single composite token','none'))
# non-subsystem consumers
for c in sorted(components):
    conflicts.append(('NON-SUBSYSTEM-CONSUMER','INTERFACE-AND-SCHEMA-REGISTRY consumers',c,
        'declare as a `component` fact owned by its subsystem (%s) so reference-closure holds.'%components[c],
        'closed typed references','consumer preserved as component','drop component fact','none'))

# ============ EMIT MODULES (deterministic: sorted, canonical) ============
def wq(v):  # value quote: bare symbol if identifier-ish else quoted string
    if v and all(ch.isalnum() or ch in './+_-:' for ch in v) and not v[0].isspace():
        return v
    return '"%s"'%v.replace('"','\\"')
def fact(t,i,**kw):
    parts=['(fact %s %s'%(t,i)]
    for k in sorted(kw):
        parts.append(':%s %s'%(k,wq(str(kw[k]))))
    return ' '.join(parts)+')'
def emit(fn,header,lines):
    with open(os.path.join(HERE,fn),'w') as f:
        f.write(';;;; %s\n'%header)
        f.write(';;;; GENERATED BY MIGRATION build_model.py FROM v1.6-v1.8 REGISTRIES — thereafter EDIT HERE (canonical).\n')
        f.write(';;;; Uniform fact form: (fact <type> <id> :key value ...). No eval. Read with *read-eval* nil.\n\n')
        for ln in lines: f.write(ln+'\n')

emit('subsystems.sexp','subsystems.sexp — one fact per subsystem (owner-seat = the single seat, L2)',
     [fact('subsystem',s,**{'owner-seat':subs[s]['owner'],'mission':subs[s]['mission'],'migration':subs[s]['migration'],
        'classification':sub_cls(s)}) for s in sorted(subs)])

# a type that appears as a consumer is a PROPOSER class: it must say so explicitly, because the consumer
# universe is closed (subsystem | component | consumer-role-bearing type) and fails closed otherwise.
proposer_types={c for c,_nm in consumes if c in types}
def type_kw(t):
    kw={'owner-subsystem':types[t]['owner'],'classification':type_cls(t)}
    if t in proposer_types: kw['consumer-role']='PROPOSER'
    return kw
tlines=[fact('type',t,**type_kw(t)) for t in sorted(types)]
clines=[fact('component',c,**{'owner-subsystem':components[c]}) for c in sorted(components)]
emit('interfaces-and-types.sexp','interfaces-and-types.sexp — one fact per canonical type/interface + components',tlines+['']+clines)

emit('stores-and-authorities.sexp','stores-and-authorities.sexp — one fact per store (single owner + single writer, L2)',
     [fact('store',s,**{'owner':stores[s]['owner'],'writer':stores[s]['writer']}) for s in sorted(stores)])

dep=[fact('stage',s) for s in stages]
dep+=['']+[fact('stage-edge','%s__%s'%(a,b),**{'from':a,'to':b}) for a,b in stage_edges]
dep+=['']+[fact('consumes','%s__%s'%(c,nm),**{'consumer':c,'provides':nm}) for c,nm in sorted(set(consumes))]
emit('dependencies-and-boundaries.sexp','dependencies-and-boundaries.sexp — acyclic pipeline stage DAG (L4) + data-flow consumes edges',dep)

rt=[fact('requirement',r) for r in reqs]+['']+[fact('test',t) for t in tests]+['']+[fact('wp',w) for w in wps]
rt+=['']
for s in sorted(subs):
    for w in wp_tokens(subs[s]['wp']):
        rt.append(fact('req-map','%s__%s'%(s,w),**{'subsystem':s,'requirement':subs[s]['req'],'test':subs[s]['test'],'wp':w}))
emit('requirements-tests-workpackets.sexp','requirements-tests-workpackets.sexp — requirement/test/wp entities + subsystem req-map (L6)',rt)

print('EMITTED modules. subsystems=%d types=%d components=%d stores=%d stages=%d stage-edges=%d consumes=%d reqs=%d tests=%d wps=%d conflicts=%d'
      %(len(subs),len(types),len(components),len(stores),len(stages),len(stage_edges),len(set(consumes)),len(reqs),len(tests),len(wps),len(conflicts)))
# The conflict set is REPORTED, not stashed: MODEL-MIGRATION-CONFLICT-LEDGER.md is the adjudication record and
# the gate reconciles every one of its rows against the canonical model (gate_checks.py conflict-ledger check),
# so there is no derived side-file to go stale.
for c in conflicts: print('CONFLICT %s | %s | %s'%(c[0],c[1],c[2]))
