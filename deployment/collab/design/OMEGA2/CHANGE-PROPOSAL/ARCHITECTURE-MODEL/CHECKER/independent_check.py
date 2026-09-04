#!/usr/bin/env python3
"""INDEPENDENT second verification path (gate 13-15). Uses clingo (stock ASP/Datalog-family solver) — NO shared
parsing or invariant-evaluation code with the SBCL kernel. It parses the canonical facts with its OWN small sexp
tokenizer, encodes the three OBJECTIVE freeze invariants (L4 pipeline acyclicity, L3 graph reference closure,
L5 public/private isolation) as ASP rules, and derives violation/1 atoms. Emits a neutral export (node/edge/fact
counts + per-family digests bound to the model root) so corruption/omission is detectable. Exit 0 = all three
objective invariants hold, non-zero otherwise."""
import os, re, sys, hashlib, json
import clingo
HERE=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHECKER_VERSION="independent_check.py/1 (clingo %s)"%clingo.__version__
# ---- own independent sexp tokenizer (no import of kernel/build_model) ----
def parse_facts(dirp):
    facts=[]
    for mod in ('subsystems.sexp','interfaces-and-types.sexp','dependencies-and-boundaries.sexp',
                'requirements-tests-workpackets.sexp','stores-and-authorities.sexp','files-and-roles.sexp'):
        for raw in open(os.path.join(dirp,mod)):
            raw=raw.strip()
            if not raw.startswith('(fact ') or not raw.endswith(')'): continue
            toks=re.findall(r'"[^"]*"|[^\s()]+', raw[6:-1])
            typ=toks[0].lower(); fid=toks[1].strip('"'); pl={}; i=2
            while i<len(toks)-1:
                if toks[i].startswith(':'): pl[toks[i][1:]]=toks[i+1].strip('"'); i+=2
                else: i+=1
            facts.append((typ,fid,pl))
    return facts
def q(s):  # clingo constant: quote as a string term (robust to /,-,. etc.)
    return '"%s"'%s.replace('\\','\\\\').replace('"','\\"')
REF_MAP={'type':[('owner-subsystem','subsystem')],'component':[('owner-subsystem','subsystem')],
         'stage-edge':[('from','stage'),('to','stage')],'consumes':[('provides','type')],
         'req-map':[('subsystem','subsystem'),('requirement','requirement'),('test','test'),('wp','wp')]}
def build_program(facts):
    L=[]
    for t,i,p in facts:
        L.append('decl(%s,%s).'%(q(t),q(i)))                       # every fact declares (type,id)
        for key,tgt in REF_MAP.get(t,[]):                          # every typed reference (independent closure)
            if key in p: L.append('ref(%s,%s).'%(q(tgt),q(p[key])))
        if t=='stage-edge': L.append('edge(%s,%s).'%(q(p['from']),q(p['to'])))
        elif t=='type': L.append('class(%s,%s).'%(q(i),q(p.get('classification','PUBLIC'))))
        elif t=='subsystem': L.append('subclass(%s,%s).'%(q(i),q(p.get('classification','PUBLIC'))))
        elif t=='component': L.append('component(%s,%s).'%(q(i),q(p['owner-subsystem'])))
        elif t=='consumes': L.append('consumes(%s,%s).'%(q(p['consumer']),q(p['provides'])))
    rules=r'''
% L3 — closed typed references (same closure the kernel checks): a referenced (type,value) must be declared
declared(T,V) :- decl(T,V).
violation("L3",V) :- ref(T,V), not declared(T,V).
% L4 — permitted pipeline stage graph must be acyclic
reach(X,Y) :- edge(X,Y).
reach(X,Z) :- reach(X,Y), edge(Y,Z).
violation("L4",X) :- reach(X,X).
% L5 — public/private isolation: a PUBLIC consumer must not consume a PRIVATE type
private_type(P) :- class(P,"PRIVATE").
public_consumer(C) :- subclass(C,"PUBLIC").
public_consumer(C) :- component(C,O), subclass(O,"PUBLIC").
violation("L5",P) :- consumes(C,P), private_type(P), public_consumer(C).
#show violation/2.
'''
    return '\n'.join(L)+'\n'+rules
def run(facts):
    ctl=clingo.Control(); ctl.add("base",[],build_program(facts)); ctl.ground([("base",[])])
    viols=set()
    with ctl.solve(yield_=True) as h:
        for mdl in h:
            for a in mdl.symbols(shown=True):
                if a.name=="violation": viols.add(str(a.arguments[0]).strip('"'))
            break
    return viols
def neutral_export(facts, dirp):
    fam={}
    for t,i,p in facts: fam.setdefault(t,[]).append(i+'|'+'|'.join('%s=%s'%(k,p[k]) for k in sorted(p)))
    root=re.search(r':canonical-model-root-digest "([0-9a-f]{64})"',open(os.path.join(dirp,'ROOT.sexp')).read()).group(1)
    exp={'checker':CHECKER_VERSION,'bound-model-root-digest':root,
         'family-counts':{t:len(v) for t,v in sorted(fam.items())},
         'family-digests':{t:hashlib.sha256('\n'.join(sorted(v)).encode()).hexdigest() for t,v in sorted(fam.items())},
         'total-facts':len(facts)}
    return exp
def main():
    dirp=HERE
    if len(sys.argv)>1: dirp=os.path.dirname(os.path.abspath(sys.argv[1]))
    facts=parse_facts(dirp)
    viols=run(facts)
    exp=neutral_export(facts,dirp)
    os.makedirs(os.path.join(dirp,'CHECKER'),exist_ok=True)
    json.dump(exp,open(os.path.join(dirp,'CHECKER','NEUTRAL-EXPORT.json'),'w'),indent=1,sort_keys=True)
    for law in ('L3','L4','L5'):
        print("INDEPENDENT %s: %s"%(law,'FAIL' if law in viols else 'PASS'))
    if viols:
        print("INDEPENDENT ARCHITECTURE INVARIANTS: FAIL (%s)"%','.join(sorted(viols)))
        print("; (independent ASP check of objective invariants only — NOT semantic/legal/security proof)")
        sys.exit(3)
    print("INDEPENDENT ARCHITECTURE INVARIANTS: PASS (facts=%d, bound to model-root %s)"%(len(facts),exp['bound-model-root-digest'][:12]))
    print("; (independent ASP check of objective invariants only — NOT semantic/legal/security proof)")
    sys.exit(0)
if __name__=='__main__': main()
