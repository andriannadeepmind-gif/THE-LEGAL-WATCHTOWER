#!/usr/bin/env python3
"""Deterministic GENERATED views from the canonical model. Every view is stamped GENERATED — DO NOT EDIT + the
canonical model-root digest + generator version + the exact regeneration command. Regenerating twice is byte-
identical; a manual edit of a view is detected by the gate (fresh regeneration != committed file)."""
import os, re, sys, hashlib
GEN_VERSION="generate_views.py/1"
HERE=os.path.dirname(os.path.abspath(__file__))
def read_facts():
    facts=[]
    for mod in ('subsystems.sexp','interfaces-and-types.sexp','stores-and-authorities.sexp',
                'dependencies-and-boundaries.sexp','requirements-tests-workpackets.sexp','files-and-roles.sexp'):
        for line in open(os.path.join(HERE,mod)):
            line=line.strip()
            if not line.startswith('(fact '): continue
            body=line[6:-1]
            toks=re.findall(r'"[^"]*"|\S+', body)
            typ=toks[0]; fid=toks[1].strip('"'); pl={}
            i=2
            while i<len(toks)-1:
                if toks[i].startswith(':'):
                    pl[toks[i][1:]]=toks[i+1].strip('"'); i+=2
                else: i+=1
            facts.append((typ,fid,pl))
    return facts
def root_digest():
    t=open(os.path.join(HERE,'ROOT.sexp')).read()
    return re.search(r':canonical-model-root-digest "([0-9a-f]{64})"',t).group(1)
def stamp(title,cmd):
    return ("<!-- GENERATED — DO NOT EDIT. Regenerate: %s -->\n# %s (GENERATED VIEW — DO NOT EDIT)\n\n"
            "- generator: `%s`\n- canonical-model-root-digest: `%s`\n- regeneration command: `%s`\n\n"
            %(cmd,title,GEN_VERSION,root_digest(),cmd))
def w(name,text):
    open(os.path.join(HERE,'GENERATED',name),'w').write(text)
def main():
    F=read_facts(); byt={}
    for t,i,p in F: byt.setdefault(t,[]).append((i,p))
    cmd="python3 ARCHITECTURE-MODEL/generate_views.py"
    # 1) subsystem registry view
    s=stamp("Subsystem Registry View","generate_views.py")+"| subsystem | classification | owner-seat | mission | migration |\n|---|---|---|---|---|\n"
    for i,p in sorted(byt['subsystem']):
        s+="| %s | %s | %s | %s | %s |\n"%(i,p.get('classification',''),p.get('owner-seat',''),p.get('mission',''),p.get('migration',''))
    w("SUBSYSTEM-REGISTRY-VIEW.md",s)
    # 2) ownership matrix
    s=stamp("Store Ownership / Write-Authority Matrix","generate_views.py")+"| store | owner | writer |\n|---|---|---|\n"
    for i,p in sorted(byt['store']): s+="| %s | %s | %s |\n"%(i,p.get('owner',''),p.get('writer',''))
    w("OWNERSHIP-MATRIX.md",s)
    # 3) dependency view (pipeline DAG + data-flow consumes)
    s=stamp("Dependency View","generate_views.py")+"## Permitted pipeline (acyclic stage DAG — law L4)\n\n"
    for i,p in sorted(byt.get('stage-edge',[])): s+="- %s -> %s\n"%(p['from'],p['to'])
    s+="\n## Data-flow consumes edges (recorded, not acyclicity-constrained)\n\n"
    for i,p in sorted(byt.get('consumes',[])): s+="- %s consumes %s\n"%(p['consumer'],p['provides'])
    w("DEPENDENCY-VIEW.md",s)
    # 4) requirement traceability view
    s=stamp("Requirement -> Seat -> Test -> WP Traceability View","generate_views.py")+"| subsystem | requirement | test | wp |\n|---|---|---|---|\n"
    for i,p in sorted(byt['req-map']): s+="| %s | %s | %s | %s |\n"%(p['subsystem'],p['requirement'],p['test'],p['wp'])
    w("REQUIREMENT-TRACEABILITY-VIEW.md",s)
    # 5) closure summary
    priv=[i for i,p in byt['type'] if p.get('classification')=='PRIVATE']
    s=stamp("Architecture Closure Summary","generate_views.py")
    s+="| entity | count |\n|---|---|\n"
    for t in ('subsystem','type','component','store','stage','stage-edge','consumes','requirement','test','wp','req-map'):
        s+="| %s | %d |\n"%(t,len(byt.get(t,[])))
    s+="| private-types | %d |\n"%len(priv)
    s+="\nPrivate-bearing types: %s\n"%(', '.join(sorted(priv)))
    w("ARCHITECTURE-CLOSURE-SUMMARY.md",s)
    # 6) migration-scope ledger view (imported vs DEFERRED_DATA_IMPORT vs out-of-scope)
    dl=[]
    for line in open(os.path.join(HERE,'deferred-imports.sexp')):
        line=line.strip()
        if not line.startswith('(fact source-class '): continue
        body=line[6:-1]; toks=re.findall(r'"[^"]*"|\S+', body); pl={}; i=2
        while i<len(toks)-1:
            if toks[i].startswith(':'): pl[toks[i][1:]]=toks[i+1].strip('"'); i+=2
            else: i+=1
        dl.append(pl)
    s=stamp("Migration-Scope Ledger View (imported vs DEFERRED_DATA_IMPORT)","generate_views.py")
    order={'IMPORTED':0,'DEFERRED_DATA_IMPORT':1,'OUT_OF_MIGRATION_SCOPE':2}
    s+="| source-file | fact-class | count | status | batch | maps-to / reason |\n|---|---|---|---|---|---|\n"
    for p in sorted(dl,key=lambda p:(order.get(p.get('status'),9),p.get('source-file',''),p.get('fact-class',''))):
        s+="| %s | %s | %s | %s | %s | %s |\n"%(p.get('source-file',''),p.get('fact-class',''),
            p.get('source-count',''),p.get('status',''),p.get('batch','—'),p.get('maps-to',p.get('reason','')))
    w("DEFERRED-DATA-IMPORT-VIEW.md",s)
    print("generated %d views (root-digest %s)"%(6,root_digest()[:12]))
if __name__=='__main__': main()
