#!/usr/bin/env python3
# LAWMAX OMEGA — AS-IS DEPENDENCY INVENTORY (machine-reproducible, deterministic)
# Implementation Book v1.1 · Deliverable 2. Run from repo root:
#   python3 deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/IMPLEMENTATION-BOOK/tools/asis-inventory.py
# Emits three TSVs next to this tools/ dir + a stdout summary + an ASDF-graph cycle check.
#
# HONEST LIMITS (declared, not hidden): Common Lisp is dynamic. A fully sound static
# call graph is undecidable here (macro-generated calls, runtime INTERN/FIND-SYMBOL,
# generic dispatch, READ-based dispatch). Therefore:
#   - file -> package -> top-level defined symbols : SOUND (syntactic top-level forms).
#   - ASDF system :depends-on graph               : SOUND (declared in .asd).
#   - package -> package edges                     : APPROX-LOWER-BOUND from *qualified*
#     references `orchestrator.X:sym` / `orchestrator.X::sym` only. Unqualified and
#     macro/dynamic references are NOT captured and are reported as UNKNOWN, never as 0.
import os, re, sys, glob, collections

ROOT = os.path.abspath(os.path.dirname(__file__))
while ROOT != '/' and not (os.path.isdir(os.path.join(ROOT,'source')) and os.path.isdir(os.path.join(ROOT,'.git'))):
    ROOT = os.path.dirname(ROOT)
OUT  = os.path.dirname(__file__)
SRC  = sorted(glob.glob(os.path.join(ROOT, 'source', '*.lisp')))
CLI  = sorted(glob.glob(os.path.join(ROOT, 'systems', 'orchestrator-cli', '*.lisp')))
FILES = SRC + CLI
X = os.path.join(ROOT, 'deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/PUBLIC-OBSERVATORY-CROSSWALK.md')

DEF_KINDS = ('defun','defmacro','defgeneric','defmethod','defvar','defparameter',
             'defconstant','defclass','defstruct','define-condition','deftype',
             'defrule','defconcept','define-primitive','define-noun','define-derived',
             'defcfun','defctype','define-foreign-library','define-source-channel',
             'define-representation','define-review-kind','define-mcp-tool','define-corpus-check')
EXT_LIBS = ('alexandria','ironclad','cl-ppcre','ppcre','babel','log4cl','local-time',
            'jonathan','closer-mop','uiop','drakma','cl-yaml','yaml','bordeaux-threads','bt',
            'yason','uuid','serapeum','fiveam','5am','cl-base64','base64','usocket',
            'trivial-garbage','sb-concurrency','named-readtables','lparallel','ieee-floats',
            'cxml','cxml-stp','stp','chipz','cffi')

def read(p):
    return open(p, encoding='utf-8', errors='replace').read()

# ---- crosswalk §A.3/§A.4 : file -> (layer, disposition) ----
def crosswalk_map():
    L = read(X).split('\n'); m={}
    def bound(pat):
        for i,l in enumerate(L):
            if re.match(pat,l): return i
        return None
    a3,a4,a5 = bound(r'^### A\.3 '), bound(r'^### A\.4 '), bound(r'^### A\.5 ')
    for lo,hi in ((a3,a4),(a4,a5)):
        for l in L[lo:hi]:
            mm=re.match(r'^\| `([^`]+\.lisp)` \|([^|]*)\|([^|]*)\|([^|]*)\|',l)
            if mm:
                fn=mm.group(1); layer=mm.group(3).strip(); disp=mm.group(4).strip().strip('`* ')
                m[fn]=(layer,disp)
    return m
CW = crosswalk_map()

def parse(path):
    fn = os.path.basename(path); s = read(path)
    pkg = None
    mm = re.search(r'\(in-package\s+[:#]{0,2}([A-Za-z0-9.\-]+)', s)
    if mm: pkg = mm.group(1).lower().lstrip(':#')
    # defpackage :use
    use=[]
    dp = re.search(r'\(defpackage[^\(]*?(\(:use.*?\))', s, re.S)
    if dp: use = sorted(set(re.findall(r'[:#]{1,2}([A-Za-z0-9.\-]+)', dp.group(1))))
    # top-level symbols (line-anchored def forms)
    syms=[]
    for m in re.finditer(r'^\((%s)\s+#?\'?[:]{0,2}([A-Za-z0-9%%*+<>=/.!?\-]+)'
                         % '|'.join(DEF_KINDS), s, re.M):
        syms.append((m.group(1), m.group(2)))
    kinds = collections.Counter(k for k,_ in syms)
    foreign = ('defcfun' in kinds) or ('define-foreign-library' in kinds) or ('defctype' in kinds)
    ext = sorted({e for e in EXT_LIBS if re.search(r'(?<![A-Za-z0-9.\-])'+re.escape(e)+r':', s)})
    # qualified references to OTHER orchestrator packages (approx lower bound)
    refpk = sorted({r.lower() for r in re.findall(r'\b(orchestrator\.[A-Za-z0-9.\-]+)::?', s)}
                   - ({pkg} if pkg else set()))
    layer,disp = CW.get(fn, ('UNKNOWN','UNKNOWN'))
    return dict(fn=fn, pkg=pkg or 'UNKNOWN', use=use, nsym=len(syms), kinds=dict(kinds),
                foreign=foreign, ext=ext, refpk=refpk, layer=layer, disp=disp)

rows = [parse(p) for p in FILES]

# ---- ASDF system graph ----
asd = {}
for a in sorted(glob.glob(os.path.join(ROOT,'*.asd'))):
    s = read(a)
    name = re.search(r'defsystem\s+["#:]*([A-Za-z0-9.\-]+)', s)
    name = name.group(1) if name else os.path.basename(a)
    dep = re.search(r':depends-on\s*\(([^)]*)\)', s, re.S)
    deps = sorted(set(re.findall(r'#:([A-Za-z0-9.\-]+)', dep.group(1)))) if dep else []
    orch_deps = [d for d in deps if d.startswith('orchestrator')]
    comps = re.findall(r':file\s+"([^"]+)"', s)
    asd[name] = dict(deps=orch_deps, all_deps=deps, comps=comps)

# ASDF cycle check (only orchestrator-internal edges)
def cycle(graph):
    color={}; found=[]
    def dfs(n,stack):
        color[n]='gray'
        for m in graph.get(n,{}).get('deps',[]):
            if color.get(m)=='gray': found.append(stack+[m]); return True
            if color.get(m)!='black' and m in graph and dfs(m,stack+[m]): return True
        color[n]='black'; return False
    for n in graph:
        if color.get(n)!='black' and dfs(n,[n]): break
    return found
cyc = cycle(asd)

# ---- write TSVs ----
def w(path, header, lines):
    with open(os.path.join(OUT, path),'w',encoding='utf-8') as f:
        f.write(header+'\n'); f.write('\n'.join(lines)+'\n')

w('AS-IS-FILE-INVENTORY.tsv',
  'file\tdisposition\tlayer\tpackage\tn_toplevel\tforeign_cffi\text_libs\tqualified_refs(APPROX;unqualified/dynamic=UNKNOWN)\tkinds',
  ['\t'.join([r['fn'], r['disp'], r['layer'], r['pkg'], str(r['nsym']),
              'yes' if r['foreign'] else 'no', ','.join(r['ext']) or '-',
              ','.join(r['refpk']) or 'UNKNOWN-none-qualified',
              ','.join(f"{k}:{v}" for k,v in sorted(r['kinds'].items())) or '-'])
   for r in rows])

w('AS-IS-ASDF-GRAPH.tsv','system\torchestrator_depends_on\tn_components',
  ['\t'.join([n, ','.join(d['deps']) or '-', str(len(d['comps']))]) for n,d in sorted(asd.items())])

edges=collections.Counter()
for r in rows:
    for tp in r['refpk']:
        if r['pkg']!='UNKNOWN': edges[(r['pkg'],tp)]+=1
w('AS-IS-PACKAGE-EDGES.tsv','from_package\tto_package\tqualified_ref_files(APPROX)',
  ['\t'.join([a,b,str(n)]) for (a,b),n in sorted(edges.items())])

# ---- stdout summary ----
disp_c=collections.Counter(r['disp'] for r in rows)
print("### AS-IS DEPENDENCY INVENTORY —", len(FILES), "lisp files (source",len(SRC),"+ cli",len(CLI),")")
print("disposition (181 lisp universe):", dict(disp_c), "sum=", sum(disp_c.values()))
print("files with CFFI/foreign bindings:", sum(1 for r in rows if r['foreign']))
print("distinct packages:", len({r['pkg'] for r in rows}))
print("ASDF systems:", len(asd), " orchestrator-internal edges:",
      sum(len(d['deps']) for d in asd.values()))
print("ASDF dependency cycle:", "NONE" if not cyc else cyc)
print("package qualified-ref edges (APPROX lower bound):", len(edges))
tot_sym=sum(r['nsym'] for r in rows)
print("total top-level defined symbols (SOUND):", tot_sym,
      "— per-symbol Requirement+test binding for pre-existing REUSE symbols = UNKNOWN (evidence cat [3]/[4], not this pass)")
print("wrote: AS-IS-FILE-INVENTORY.tsv, AS-IS-ASDF-GRAPH.tsv, AS-IS-PACKAGE-EDGES.tsv")
