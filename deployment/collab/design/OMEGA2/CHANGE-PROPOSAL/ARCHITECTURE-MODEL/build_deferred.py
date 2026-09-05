#!/usr/bin/env python3
"""Emit deferred-imports.sexp: enumerate EVERY top-level fact class in the v1.6-v1.8 migration-source registries
exactly once and mark each IMPORTED (this pass), DEFERRED_DATA_IMPORT (enumerated + mapped to a finite migration
batch), or OUT_OF_MIGRATION_SCOPE (version metadata, not a data class). No source fact class may be silently
omitted and none may be left as an open architecture decision.

`build_deferred.py --verify` re-derives the (file, class) universe from the sources and compares it with the
committed ledger as a MULTISET: duplicated ledger rows are detected before anything is folded into a dictionary,
missing and phantom rows are named, counts must match, every deferred class must carry a declared finite batch,
and no row may over-claim an import this pass did not perform. A source file that is absent yields the typed
result MISSING-SOURCE-FILE: <path> and a controlled non-zero exit — never an unhandled traceback.

Honest scope of --verify: both sides of that comparison are read through the repository's single classified
reader seat (SEXP-READER.py). It therefore proves that the LEDGER matches the SOURCES; it does not, and is not
claimed to, cross-check the reader against a second implementation. The reader's own behaviour is covered by its
fixtures, and the canonical model — not this ledger — is what the two independent verification paths compare.

This is a MIGRATION/enumeration tool, not part of the kernel verification path. The kernel loads the emitted
deferred-imports.sexp facts like any other model facts (L1 well-formedness + L2 uniqueness apply)."""
import importlib.util, os, sys, collections
HERE=os.path.dirname(os.path.abspath(__file__)); CP=os.path.dirname(HERE)
_spec=importlib.util.spec_from_file_location('sexp_reader',os.path.join(HERE,'SEXP-READER.py'))
SR=importlib.util.module_from_spec(_spec); _spec.loader.exec_module(SR)

def read_source(fn):
    """Read one migration-source registry, or report a typed missing-source verdict and stop."""
    try:
        return SR.read_forms_file(os.path.join(CP,fn), SR.REGISTRY)
    except SR.MissingSourceFile as e:
        print('MISSING-SOURCE-FILE: %s'%e.path)
        print('DEFERRED-IMPORT LEDGER: FAIL (a declared migration source is absent; the universe is unknowable)')
        sys.exit(5)
    except SR.SexpError as e:
        print('UNREADABLE-SOURCE-FILE: %s'%e)
        print('DEFERRED-IMPORT LEDGER: FAIL (a declared migration source could not be read)')
        sys.exit(5)

# The migration-source universe is DERIVED, not listed (Review-2 N-6). Before this pass it was six literal
# filenames here, while build_inventory.py independently classified any CHANGE-PROPOSAL/*-SCHEMAS.sexp as
# CANONICAL_MODEL_INPUT — two seats for one concept, and they disagreed: a new V1.9-SCHEMAS.sexp was recorded by
# the inventory as a migration input and was still invisible to a ledger that reported "exact-universe".
# There is now ONE seat. A migration source is exactly a file the canonical inventory classifies
# CANONICAL_MODEL_INPUT that is NOT one of the model's own modules, so a qualifying file cannot be added without
# being adjudicated here, and this program fails closed if the inventory is absent or unreadable.
AM_PREFIX='deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/'
def migration_sources():
    inv=os.path.join(HERE,'files-and-roles.sexp')
    try:
        forms=SR.read_forms_file(inv)
    except SR.MissingSourceFile as e:
        print('MISSING-SOURCE-FILE: %s'%e.path)
        print('DEFERRED-IMPORT LEDGER: FAIL (the canonical inventory that defines the source universe is absent)')
        sys.exit(5)
    except SR.SexpError as e:
        print('UNREADABLE-SOURCE-FILE: %s'%e)
        print('DEFERRED-IMPORT LEDGER: FAIL (the canonical inventory could not be read)')
        sys.exit(5)
    out=[]
    for f in forms:
        if SR.head(f)!='fact' or len(f)<3 or str(f[1])!='file': continue
        path=str(f[2]); role=SR.kv(f,'role')
        if role is None or str(role)!='CANONICAL_MODEL_INPUT': continue
        if path.startswith(AM_PREFIX): continue          # the model's own modules are not migration inputs
        rel=os.path.relpath(os.path.join(REPO_ROOT,path), CP)
        if os.sep in rel:
            print('UNADJUDICATED-MIGRATION-SOURCE: %s is classified CANONICAL_MODEL_INPUT outside the '
                  'change-proposal directory; the ledger cannot enumerate it'%path)
            sys.exit(5)
        out.append(rel)
    return sorted(set(out))
REPO_ROOT=os.path.abspath(os.path.join(HERE,'..','..','..','..','..','..'))
SOURCES=None                                              # bound in main(); never a literal list

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
    """Re-scan the sources -> {(file,head): count} for every top-level form (define-* and metadata)."""
    universe=collections.OrderedDict()
    for fn in SOURCES:
        heads=collections.Counter()
        for f in read_source(fn):
            h=SR.head(f)
            if h is not None: heads[h]+=1
        for h in sorted(heads): universe[(fn,h)]=heads[h]
    return universe

def classify(fn,head,count):
    stem=fn[:-5] if fn.endswith('.sexp') else fn   # id stem
    fid='%s__%s'%(stem,head)
    if (fn,head) in IMPORTED:
        # imported detail now lives in the model, so the model is where it is authoritative
        return dict(fid=fid,fact_class=head,source_file=fn,source_count=count,status='IMPORTED',
                    authority='CANONICAL_IN_MODEL',maps_to=IMPORTED[(fn,head)])
    if head in METADATA:
        return dict(fid=fid,fact_class=head,source_file=fn,source_count=count,status='OUT_OF_MIGRATION_SCOPE',
                    authority='AUTHORITATIVE_AT_SOURCE',
                    reason='version-metadata form, not a migratable data fact class')
    batch=BATCH.get(head)
    if batch is None:
        sys.stderr.write('FATAL: deferred source class with no finite batch: %s (%s)\n'%(head,fn)); sys.exit(2)
    ver='prior-version (may be superseded by v1.8)' if fn.startswith(('V1.5','V1.6','V1.7')) else 'current source'
    # NOT YET IMPORTED, so NOT canonical here: the detail of this class stays authoritative at its declared
    # source until its DDI batch is complete and independently reviewed (Review-2 N-7).
    return dict(fid=fid,fact_class=head,source_file=fn,source_count=count,status='DEFERRED_DATA_IMPORT',
                authority='AUTHORITATIVE_AT_SOURCE',batch=batch,reason='%s class enumerated, not imported in the initial structural pass; '
                'scheduled for batch %s (%s)'%(ver,batch,BATCH_TITLE[batch]))

def wq(v): return '"%s"'%str(v).replace('"','\\"')
def fact(row):
    parts=['(fact source-class %s'%row['fid'],
           ':source-file %s'%wq(row['source_file']),
           ':fact-class %s'%wq(row['fact_class']),
           ':source-count %d'%row['source_count'],
           ':status %s'%row['status'],
           ':authority %s'%row['authority']]
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
    # The typed promotion seat (Review-2 N-7). While ANY class is still authoritative at its source, global
    # single-source-of-truth status is mechanically forbidden — the decision packet reads this, it does not assert it.
    deferred_forms=sum(r['source_count'] for r in dfr)
    out += ['', ';;;; Typed authority split. Imported classes are canonical in this model; every deferred class '
                'remains',
            ';;;; authoritative at its declared legacy source until its DDI batch is completed AND independently '
                'reviewed.',
            '(fact promotion PROMOTION-IMPORTED :scope IMPORTED_CLASSES_ONLY :state PERMITTED :reason %s)'
            % wq('the %d imported source classes are fully represented as canonical model facts' % len(imp)),
            '(fact promotion PROMOTION-GLOBAL :scope GLOBAL :state %s :reason %s)'
            % ('FORBIDDEN_UNTIL_DDI_COMPLETE' if dfr else 'PERMITTED',
               wq('%d source classes covering %d source forms are still authoritative at their declared legacy '
                  'source; global single-source-of-truth status is withheld until DDI-1..DDI-4 are complete and '
                  'independently reviewed' % (len(dfr), deferred_forms)))]
    target=os.path.join(OUTDIR if OUTDIR else HERE,'deferred-imports.sexp')
    open(target,'w',encoding='utf-8',newline='\n').write('\n'.join(out)+'\n')
    print('deferred-imports.sexp: source-classes=%d imported=%d deferred=%d out-of-scope=%d batches=%s'
          %(len(rows),len(imp),len(dfr),len(oos),','.join(sorted(set(r['batch'] for r in dfr)))))

def parse_ledger():
    """Read deferred-imports.sexp back as an ORDERED LIST of rows. Nothing is folded into a dict here: a
    duplicated row must still be visible to the caller, which is exactly what a dict would destroy."""
    try:
        forms=SR.read_forms_file(os.path.join(HERE,'deferred-imports.sexp'))
    except SR.MissingSourceFile as e:
        print('MISSING-SOURCE-FILE: %s'%e.path)
        print('DEFERRED-IMPORT LEDGER: FAIL (the ledger itself is absent)')
        sys.exit(5)
    except SR.SexpError as e:
        print('UNREADABLE-LEDGER: %s'%e)
        print('DEFERRED-IMPORT LEDGER: FAIL')
        sys.exit(5)
    rows=[]
    for f in forms:
        if SR.head(f)!='fact' or len(f)<3 or str(f[1])!='source-class': continue
        sf=str(SR.kv(f,'source-file')); fc=str(SR.kv(f,'fact-class'))
        cnt=SR.kv(f,'source-count'); st=str(SR.kv(f,'status')); bt=SR.kv(f,'batch')
        au=SR.kv(f,'authority')
        rows.append(((sf,fc),dict(count=int(cnt) if isinstance(cnt,SR.Int) else None,
                                  status=st,batch=None if bt is None else str(bt),
                                  authority=None if au is None else str(au))))
    return rows

def verify():
    uni=scan(); rows=parse_ledger(); ok=True
    # (0) MULTISET first: a duplicated ledger row must be named BEFORE any dict/set folding hides it
    keycount=collections.Counter(k for k,_r in rows)
    for k,n in sorted(keycount.items()):
        if n>1: print('DUPLICATE-LEDGER-ROW: %s %s appears %d times'%(k[0],k[1],n)); ok=False
    led={}
    for k,r in rows: led.setdefault(k,r)
    # (a) exact universe: every on-disk (file,class) has exactly one ledger row and vice-versa
    us=set(uni.keys()); ls=set(keycount.keys())
    for k in sorted(us-ls): print('MISSING-FROM-LEDGER: %s %s'%k); ok=False
    for k in sorted(ls-us): print('PHANTOM-LEDGER-ROW: %s %s'%k); ok=False
    # (b) counts match (no silent normalization of how many forms a class has)
    for k in sorted(us&ls):
        if uni[k]!=led[k]['count']: print('COUNT-MISMATCH: %s %s on-disk=%d ledger=%s'%(k[0],k[1],uni[k],led[k]['count'])); ok=False
    # (c) every deferred row has a declared finite batch + the class is batch-mapped
    valid_batches=set(BATCH_TITLE)
    for k in sorted(ls):
        r=led[k]
        if r['status']=='DEFERRED_DATA_IMPORT':
            if r['batch'] not in valid_batches: print('DEFERRED-WITHOUT-BATCH: %s %s batch=%r'%(k[0],k[1],r['batch'])); ok=False
        elif r['status'] not in ('IMPORTED','OUT_OF_MIGRATION_SCOPE'):
            print('UNKNOWN-STATUS: %s %s status=%r'%(k[0],k[1],r['status'])); ok=False
        want='CANONICAL_IN_MODEL' if r['status']=='IMPORTED' else 'AUTHORITATIVE_AT_SOURCE'
        if r['authority']!=want:
            print('AUTHORITY-MISMATCH: %s %s status=%s declares :authority %s, must be %s'
                  %(k[0],k[1],r['status'],r['authority'],want)); ok=False
    # (d) every IMPORTED (file,class) in the ledger is one this pass actually imported (no over-claim)
    for k in sorted(ls):
        if led[k]['status']=='IMPORTED' and k not in IMPORTED: print('OVER-CLAIMED-IMPORT: %s %s'%k); ok=False
    for k in sorted(IMPORTED):
        if k not in led or led[k]['status']!='IMPORTED': print('IMPORT-NOT-LEDGERED: %s %s'%k); ok=False
    ndef=sum(1 for k in ls if led[k]['status']=='DEFERRED_DATA_IMPORT')
    if ok:
        print('DEFERRED-IMPORT LEDGER: PASS (rows=%d source-classes=%d exact-universe multiset-checked deferred=%d all-batched)'
              %(len(rows),len(ls),ndef)); sys.exit(0)
    print('DEFERRED-IMPORT LEDGER: FAIL'); sys.exit(3)

OUTDIR=None
CP=os.path.dirname(HERE)
if __name__=='__main__':
    args=sys.argv[1:]
    if '--out' in args:
        i=args.index('--out'); OUTDIR=os.path.abspath(args[i+1]); del args[i:i+2]
    SOURCES=migration_sources()
    if not SOURCES:
        print('NO-MIGRATION-SOURCES: the canonical inventory classifies no file CANONICAL_MODEL_INPUT outside '
              'the model directory; the source universe would be empty, which is never a correct answer')
        sys.exit(5)
    if args and args[0]=='--verify': verify()
    else: build()
