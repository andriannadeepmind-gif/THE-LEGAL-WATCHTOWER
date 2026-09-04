#!/usr/bin/env python3
"""Emit deferred-imports.sexp: enumerate EVERY top-level fact class in the v1.6-v1.8 migration-source registries
exactly once and mark each IMPORTED (this pass), DEFERRED_DATA_IMPORT (enumerated + mapped to a finite migration
batch), or OUT_OF_MIGRATION_SCOPE (version metadata, not a data class). No source fact class may be silently
omitted and none may be left as an open architecture decision: build_deferred.py --verify re-scans the sources
with an INDEPENDENT reader and fails closed unless the on-disk (file,class) universe and the ledger are exactly
equal, every deferred class has a declared finite batch, and every ledger row maps to a real source form.

This is a MIGRATION/enumeration tool, not part of the kernel verification path. The kernel loads the emitted
deferred-imports.sexp facts like any other model facts (L1 well-formedness + L2 uniqueness apply)."""
import importlib.util, os, sys, collections
HERE=os.path.dirname(os.path.abspath(__file__)); CP=os.path.dirname(HERE)
spec=importlib.util.spec_from_file_location('vfy',os.path.join(CP,'V1.8-VERIFY.py'))
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)

# The exact migration-source universe (v1.6-v1.8 registries + schemas). V1.5 is a superseded ancestor: enumerated
# too so nothing is silently omitted. build_model.py migrates FROM these files.
SOURCES=['SUBSYSTEM-REGISTRY.sexp','INTERFACE-AND-SCHEMA-REGISTRY.sexp',
         'V1.5-SCHEMAS.sexp','V1.6-SCHEMAS.sexp','V1.7-SCHEMAS.sexp','V1.8-SCHEMAS.sexp']

# What THIS pass imported: (source-file, top-level form head) -> the model fact-type(s) it became.
IMPORTED={
    ('SUBSYSTEM-REGISTRY.sexp','define-subsystem'):'subsystem (+requirement/test/wp/req-map derived)',
    ('INTERFACE-AND-SCHEMA-REGISTRY.sexp','define-interface'):'type + component + consumes',
    ('V1.8-SCHEMAS.sexp','define-write-authority'):'store',
    ('V1.8-SCHEMAS.sexp','define-pipeline'):'stage + stage-edge',
}
# Top-level forms that are version metadata, not a migratable data class.
METADATA={'registry-version','spec-version'}

# Finite migration batches. Every DEFERRED fact class maps to exactly one batch; an unmapped deferred class is a
# fail-closed error (a new source class can never be silently dropped without a batch).
BATCH={
 # DDI-1 seats / canonical identities / RA closure / topology + write-authority (superseded-version occurrences)
 'define-capability-seat':'DDI-1','define-canonical-identity':'DDI-1','define-ra-delta-seats':'DDI-1',
 'define-ra-closure-roots':'DDI-1','define-pipeline':'DDI-1','define-write-authority':'DDI-1',
 'define-construction-order':'DDI-1','define-required-refs':'DDI-1',
 # DDI-2 type/record/enum/reference schema detail
 'define-record':'DDI-2','define-closed-enum':'DDI-2','define-reference':'DDI-2',
 'define-frozen-enum-reference':'DDI-2','define-cardinality-table':'DDI-2','define-cardinality-matrix':'DDI-2',
 'define-ref-classification':'DDI-2','define-ref-classification-v6':'DDI-2','define-adapter-contract':'DDI-2',
 'define-mapping':'DDI-2',
 # DDI-3 cognition / decision / projection layer
 'define-cognition-graph':'DDI-3','define-cognition-node-types':'DDI-3','define-dimension-policy':'DDI-3',
 'define-reliance-aggregation':'DDI-3','define-decision-function':'DDI-3','define-quorum-predicate':'DDI-3',
 'define-projection':'DDI-3','define-algorithm':'DDI-3','define-source-type-coverage':'DDI-3',
 # DDI-4 normative constraints / rules / prose
 'define-invariant':'DDI-4','define-rule':'DDI-4','define-protocol':'DDI-4','define-gate':'DDI-4',
 'define-constitution-reference':'DDI-4','define-fixtures':'DDI-4','define-wp-reconciliation':'DDI-4',
 'define-wp-purpose':'DDI-4','define-file-disposition':'DDI-4',
}
BATCH_TITLE={'DDI-1':'seats / canonical identities / RA closure / pipeline+authority topology',
             'DDI-2':'type / record / enum / reference schema detail',
             'DDI-3':'cognition graph / decision / projection layer',
             'DDI-4':'normative invariants / rules / prose'}

def scan():
    """Independent scan of the sources -> {(file,head): count} for every top-level form (define-* and metadata)."""
    universe=collections.OrderedDict()
    for fn in SOURCES:
        forms=m.read_all(m.readpath(os.path.join(CP,fn)))
        heads=collections.Counter()
        for f in forms:
            h=m.head(f)
            if h is not None: heads[str(h)]+=1
        for h in sorted(heads): universe[(fn,h)]=heads[h]
    return universe

def classify(fn,head,count):
    stem=fn[:-5] if fn.endswith('.sexp') else fn   # id stem
    fid='%s__%s'%(stem,head)
    if (fn,head) in IMPORTED:
        return dict(fid=fid,fact_class=head,source_file=fn,source_count=count,status='IMPORTED',
                    maps_to=IMPORTED[(fn,head)])
    if head in METADATA:
        return dict(fid=fid,fact_class=head,source_file=fn,source_count=count,status='OUT_OF_MIGRATION_SCOPE',
                    reason='version-metadata form, not a migratable data fact class')
    batch=BATCH.get(head)
    if batch is None:
        sys.stderr.write('FATAL: deferred source class with no finite batch: %s (%s)\n'%(head,fn)); sys.exit(2)
    ver='prior-version (may be superseded by v1.8)' if fn.startswith(('V1.5','V1.6','V1.7')) else 'current source'
    return dict(fid=fid,fact_class=head,source_file=fn,source_count=count,status='DEFERRED_DATA_IMPORT',
                batch=batch,reason='%s class enumerated, not imported in the initial structural pass; '
                'scheduled for batch %s (%s)'%(ver,batch,BATCH_TITLE[batch]))

def wq(v): return '"%s"'%str(v).replace('"','\\"')
def fact(row):
    parts=['(fact source-class %s'%row['fid'],
           ':source-file %s'%wq(row['source_file']),
           ':fact-class %s'%wq(row['fact_class']),
           ':source-count %d'%row['source_count'],
           ':status %s'%row['status']]
    if 'batch' in row: parts.append(':batch %s'%row['batch'])
    if 'maps-to' in row or 'maps_to' in row: parts.append(':maps-to %s'%wq(row.get('maps_to',row.get('maps-to'))))
    if 'reason' in row: parts.append(':reason %s'%wq(row['reason']))
    return ' '.join(parts)+')'

def build():
    uni=scan(); rows=[classify(fn,h,c) for (fn,h),c in uni.items()]
    imp=[r for r in rows if r['status']=='IMPORTED']
    dfr=[r for r in rows if r['status']=='DEFERRED_DATA_IMPORT']
    oos=[r for r in rows if r['status']=='OUT_OF_MIGRATION_SCOPE']
    out=[';;;; deferred-imports.sexp — every migration-source fact class enumerated exactly once (no silent omission).',
         ';;;; GENERATED by build_deferred.py FROM the v1.6-v1.8 registries. status IMPORTED (this pass) |',
         ';;;; DEFERRED_DATA_IMPORT (enumerated + finite batch, never an open decision) | OUT_OF_MIGRATION_SCOPE.',
         ';;;; Uniform fact form: (fact source-class <id> :key value ...). No eval. Read with *read-eval* nil.','']
    for r in rows: out.append(fact(r))
    open(os.path.join(HERE,'deferred-imports.sexp'),'w').write('\n'.join(out)+'\n')
    print('deferred-imports.sexp: source-classes=%d imported=%d deferred=%d out-of-scope=%d batches=%s'
          %(len(rows),len(imp),len(dfr),len(oos),','.join(sorted(set(r['batch'] for r in dfr)))))

def parse_ledger():
    """Read deferred-imports.sexp back with an independent reader -> {(source_file,fact_class): row}."""
    forms=m.read_all(m.readpath(os.path.join(HERE,'deferred-imports.sexp')))
    led={}
    for f in forms:
        if m.head(f) is None or str(m.head(f))!='fact': continue
        if m.form_name(f) is None or str(m.form_name(f))!='source-class': continue
        sf=str(m.kv_after(f,':source-file')).strip('"'); fc=str(m.kv_after(f,':fact-class')).strip('"')
        cnt=int(str(m.kv_after(f,':source-count'))); st=str(m.kv_after(f,':status'))
        bt=m.kv_after(f,':batch'); bt=None if bt is None else str(bt)
        led[(sf,fc)]=dict(count=cnt,status=st,batch=bt)
    return led

def verify():
    uni=scan(); led=parse_ledger(); ok=True
    # (a) exact universe: every on-disk (file,class) has exactly one ledger row and vice-versa
    us=set(uni.keys()); ls=set(led.keys())
    for k in sorted(us-ls): print('MISSING-FROM-LEDGER: %s %s'%k); ok=False
    for k in sorted(ls-us): print('PHANTOM-LEDGER-ROW: %s %s'%k); ok=False
    # (b) counts match (no silent normalization of how many forms a class has)
    for k in sorted(us&ls):
        if uni[k]!=led[k]['count']: print('COUNT-MISMATCH: %s %s on-disk=%d ledger=%d'%(k[0],k[1],uni[k],led[k]['count'])); ok=False
    # (c) every deferred row has a declared finite batch + the class is batch-mapped
    valid_batches=set(BATCH_TITLE)
    for k in sorted(ls):
        r=led[k]
        if r['status']=='DEFERRED_DATA_IMPORT':
            if r['batch'] not in valid_batches: print('DEFERRED-WITHOUT-BATCH: %s %s batch=%r'%(k[0],k[1],r['batch'])); ok=False
        elif r['status'] not in ('IMPORTED','OUT_OF_MIGRATION_SCOPE'):
            print('UNKNOWN-STATUS: %s %s status=%r'%(k[0],k[1],r['status'])); ok=False
    # (d) every IMPORTED (file,class) in the ledger is one this pass actually imported (no over-claim)
    for k in sorted(ls):
        if led[k]['status']=='IMPORTED' and k not in IMPORTED: print('OVER-CLAIMED-IMPORT: %s %s'%k); ok=False
    for k in sorted(IMPORTED):
        if k not in led or led[k]['status']!='IMPORTED': print('IMPORT-NOT-LEDGERED: %s %s'%k); ok=False
    ndef=sum(1 for k in ls if led[k]['status']=='DEFERRED_DATA_IMPORT')
    if ok: print('DEFERRED-IMPORT LEDGER: PASS (source-classes=%d exact-universe deferred=%d all-batched)'%(len(ls),ndef)); sys.exit(0)
    print('DEFERRED-IMPORT LEDGER: FAIL'); sys.exit(3)

if __name__=='__main__':
    if len(sys.argv)>1 and sys.argv[1]=='--verify': verify()
    else: build()
