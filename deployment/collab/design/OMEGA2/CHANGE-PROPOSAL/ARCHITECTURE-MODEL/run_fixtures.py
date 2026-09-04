#!/usr/bin/env python3
"""Run golden fixtures (PASS/FAIL) + generated property families against the SBCL kernel (and clingo for the shared
objective laws L3/L4/L5). Each mutated model is rehashed (except the L7-drift fixture) so ONLY the intended law
fails. Exit 0 iff every golden fixture yields its expected result for its exact reason AND every generated property
is rejected AND the kernel/clingo agree on every shared-law failure (gate 15)."""
import os, re, sys, shutil, subprocess, tempfile, hashlib, glob
HERE=os.path.dirname(os.path.abspath(__file__))
# module universe = exactly what ROOT.sexp pins (single source; auto-includes any new module)
MODULES=re.findall(r':module "([^"]+)"',open(os.path.join(HERE,'ROOT.sexp')).read())
def sha(fp):
    with open(fp,encoding='utf-8',errors='replace') as f: return hashlib.sha256(f.read().encode('utf-8')).hexdigest()
def rehash(d):
    rootp=os.path.join(d,'ROOT.sexp'); t=open(rootp).read()
    rows=[(m,sha(os.path.join(d,m))) for m in MODULES]
    for m,h in rows: t=re.sub(r'(:module "%s" :sha256 ")[0-9a-f]{64}'%re.escape(m), r'\g<1>'+h, t)
    dig=hashlib.sha256('\n'.join('%s:%s'%(m,h) for m,h in rows).encode()).hexdigest()
    t=re.sub(r'(:canonical-model-root-digest ")[0-9a-f]{64}', r'\g<1>'+dig, t)
    open(rootp,'w').write(t)
def mkmodel(d):
    for m in MODULES: shutil.copy(os.path.join(HERE,m),os.path.join(d,m))
    shutil.copy(os.path.join(HERE,'ROOT.sexp'),os.path.join(d,'ROOT.sexp'))
def run_kernel(d):
    r=subprocess.run(['sbcl','--script',os.path.join(HERE,'KERNEL','model-law-kernel.lisp'),os.path.join(d,'ROOT.sexp')],
                     capture_output=True,text=True)
    return r.returncode, r.stdout+r.stderr
def run_clingo(d):
    r=subprocess.run(['python3',os.path.join(HERE,'CHECKER','independent_check.py'),os.path.join(d,'ROOT.sexp')],
                     capture_output=True,text=True)
    return r.returncode, r.stdout+r.stderr
def apply_mut(d,mut):
    op=mut[0]
    if op=='none': return True
    if op=='add':
        mod,line=mut[1],mut[2]; open(os.path.join(d,mod),'a').write('\n'+line+'\n'); rehash(d); return True
    if op=='remove-line':
        mod,pre=mut[1],mut[2]; p=os.path.join(d,mod)
        ls=[l for l in open(p) if not l.startswith(pre)]; open(p,'w').write(''.join(ls)); rehash(d); return True
    if op=='append-no-rehash':
        mod,text=mut[1],mut[2]; open(os.path.join(d,mod),'a').write('\n'+text+'\n'); return True  # L7 drift: no rehash
    return False
def parse_fixture(fp):
    t=open(fp).read()
    law=re.search(r':law (\S+)',t).group(1); exp=re.search(r':expect (\S+)',t).group(1)
    reason=re.search(r':reason "([^"]*)"',t).group(1)
    mm=re.search(r':mutate \((\w[\w-]*)(?:\s+"([^"]*)"\s+"([^"]*)")?\)',t)
    mut=[mm.group(1)]+([mm.group(2),mm.group(3)] if mm.group(2) else [])
    return law,exp,reason,mut
fails=[]
def check(name,law,exp,reason,mut,shared):
    d=tempfile.mkdtemp()
    try:
        mkmodel(d); apply_mut(d,mut)
        kc,ko=run_kernel(d)
        exp_code = 0 if exp=='PASS' else 3
        if kc!=exp_code: fails.append('%s kernel exit %d != %d'%(name,kc,exp_code)); return
        if reason.upper() not in ko.upper(): fails.append('%s kernel reason missing: %r'%(name,reason)); return
        if shared:
            cc,co=run_clingo(d)
            exp_c = 0 if exp=='PASS' else 3
            if cc!=exp_c: fails.append('%s clingo exit %d != %d (kernel/clingo disagreement)'%(name,cc,exp_c)); return
    finally: shutil.rmtree(d)
# --- golden fixtures ---
ng=0
for fp in sorted(glob.glob(os.path.join(HERE,'FIXTURES','PASS','*.sexp'))+glob.glob(os.path.join(HERE,'FIXTURES','FAIL','*.sexp'))):
    law,exp,reason,mut=parse_fixture(fp); shared=law in ('L3','L4','L5')
    check(os.path.basename(fp),law,exp,reason,mut,shared); ng+=1
# --- generated property families ---
np=0
# family: every subsystem needs a req-map (L6) — remove each subsystem's first req-map line
subs=[l.split()[2] for l in open(os.path.join(HERE,'subsystems.sexp')) if l.startswith('(fact subsystem ')]
for s in subs[:6]:
    pre='(fact req-map %s__'%s
    check('gen/L6-nomap/%s'%s,'L6','FAIL','has no requirement->seat->test->WP mapping',['remove-line','requirements-tests-workpackets.sexp',pre],False); np+=1
# family: public consumer of each private type (L5)
privs=[l.split()[2] for l in open(os.path.join(HERE,'interfaces-and-types.sexp')) if l.startswith('(fact type ') and 'PRIVATE' in l]
for p in privs:
    check('gen/L5-leak/%s'%p,'L5','FAIL','public/private leak',['add','dependencies-and-boundaries.sexp','(fact consumes S12__%s :consumer S12 :provides %s)'%(p,p)],True); np+=1
# family: dangling ref (L3) per made-up ghost
for gid in ('WP-777','WP-888','WP-999'):
    check('gen/L3-dangling/%s'%gid,'L3','FAIL','undeclared wp %s'%gid,['add','requirements-tests-workpackets.sexp','(fact req-map S02__%s :subsystem S02 :requirement R-16 :test Q16 :wp %s)'%(gid,gid)],True); np+=1
# family: duplicate seat (L2) per store
stores=[l.split()[2] for l in open(os.path.join(HERE,'stores-and-authorities.sexp')) if l.startswith('(fact store ')]
for st in stores[:4]:
    check('gen/L2-dup/%s'%st,'L2','FAIL','duplicate seat STORE %s'%st,['add','stores-and-authorities.sexp','(fact store %s :owner d :writer d)'%st],False); np+=1
# family: cycle (L4) per back-edge
for a,b in (('PUBLISH','ACQUIRE'),('PROOF','IR'),('COMPILE','ACQUIRE')):
    check('gen/L4-cycle/%s-%s'%(a,b),'L4','FAIL','cycle in permitted pipeline stage graph',['add','dependencies-and-boundaries.sexp','(fact stage-edge %s__%s :from %s :to %s)'%(a,b,a,b)],True); np+=1
print("golden fixtures=%d  generated properties=%d  failures=%d"%(ng,np,len(fails)))
for f in fails: print("  FAIL:",f)
sys.exit(0 if not fails else 1)
