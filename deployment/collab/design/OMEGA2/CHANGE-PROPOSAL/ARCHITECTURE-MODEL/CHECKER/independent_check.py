#!/usr/bin/env python3
"""INDEPENDENT second verification path.

Independence is defined against the Common Lisp kernel: this path shares NO parsing code and NO
invariant-evaluation code with it. The invariants are evaluated by clingo (a stock ASP/Datalog-family solver)
from a declarative encoding; the model is read by the repository's single Python reader seat (SEXP-READER.py),
which is a real multi-line s-expression reader with complete-consumption and typed errors — not a line matcher.
Both paths read the same SPECIFICATION (MODEL-SCHEMA.sexp, and the canonical value/fact rendering it defines);
sharing a specification is what makes two implementations comparable, and is not shared code.

What this path establishes, in order, failing closed at the first step it cannot complete:
  1. its SHA-256 engine (hashlib/OpenSSL) reproduces the FIPS 180-4 known-answer vectors;
  2. ROOT.sexp is the sole module universe: every pinned module is hashed over RAW BYTES and compared to its
     pin, no undeclared *.sexp module exists beside them, and the canonical model-root digest is RECOMPUTED
     from the ordered pins rather than read;
  3. every ROOT-pinned module is read completely; every top-level form is either a fact or a declared header;
     duplicate seats and duplicate keys are detected before anything is folded into a dictionary;
  4. its fact-set commitment (total, per-module and per-family counts and digests) is byte-identical to the
     kernel's commitment — a PASS is not issued, and verdicts are not compared, if the two universes differ;
  5. the model laws are derived by clingo and reported as typed violations.
"""
import importlib.util, json, os, sys, hashlib

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_spec = importlib.util.spec_from_file_location('sexp_reader', os.path.join(HERE, 'SEXP-READER.py'))
SR = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(SR)
import clingo

CHECKER_VERSION = 'independent_check.py/2 (clingo %s, hashlib/%s)' % (
    clingo.__version__, hashlib.sha256(b'').name)
HEADERS = ('define-model-schema', 'define-model-root', 'define-toolchain')
FIPS = {'': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        'abc': 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
        'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq':
            '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1'}
MILLION_A = 'cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0'


def die(code, *lines):
    for l in lines:
        print(l)
    print('; (independent ASP check of objective invariants only — NOT semantic/legal/security proof)')
    sys.exit(code)


def self_test_hash():
    for msg, want in FIPS.items():
        got = hashlib.sha256(msg.encode('ascii')).hexdigest()
        if got != want:
            die(4, 'TOOLCHAIN-FAILURE: hashlib failed FIPS 180-4 vector %r: got %s want %s' % (msg, got, want),
                'SHA-256 PROVIDER: UNAVAILABLE — no model hash was computed and no verdict is issued.')
    if hashlib.sha256(b'a' * 1000000).hexdigest() != MILLION_A:
        die(4, "TOOLCHAIN-FAILURE: hashlib failed the 1,000,000 x 'a' vector",
            'SHA-256 PROVIDER: UNAVAILABLE — no model hash was computed and no verdict is issued.')


def sha_file(path):
    """SHA-256 over the exact raw bytes of PATH (one hashing definition, shared with the Common Lisp path)."""
    with open(path, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()


def sha_text(s):
    return hashlib.sha256(s.encode('utf-8')).hexdigest()


# ------------------------------------------------------------------ ROOT: the sole module universe
def read_root(dirp):
    forms = SR.read_forms_file(os.path.join(dirp, 'ROOT.sexp'))
    roots = [f for f in forms if SR.head(f) == 'define-model-root']
    if len(roots) != 1:
        die(3, 'ROOT-MALFORMED: expected exactly one define-model-root form, found %d' % len(roots))
    pl = dict(SR.plist(roots[0][2:], 'ROOT.sexp', 'define-model-root'))
    comp = []
    for entry in pl.get('composition', []):
        e = dict(SR.plist(entry, 'ROOT.sexp', 'composition entry'))
        comp.append((str(e['module']), str(e['sha256'])))
    return pl, comp


def verify_root(dirp, pl, comp, viol):
    rows = []
    for name, pin in comp:
        path = os.path.join(dirp, name)
        if not os.path.isfile(path):
            rows.append('%s:MISSING' % name)
            viol.append(('L7', 'module', name, 'sha256', 'MISSING-ON-DISK'))
            continue
        actual = sha_file(path)
        rows.append('%s:%s' % (name, actual))
        if actual != pin:
            viol.append(('L7', 'module', name, 'sha256', '%s!=%s' % (actual[:12], pin[:12])))
    declared = {n for n, _ in comp}
    for fn in sorted(os.listdir(dirp)):
        if fn.endswith('.sexp') and fn != 'ROOT.sexp' and fn not in declared:
            viol.append(('L7', 'module', fn, 'composition', 'UNDECLARED-EXTRA-MODULE'))
    count = pl.get('module-count')
    if not isinstance(count, SR.Int) or int(count) != len(comp):
        viol.append(('L7', 'root', 'ROOT.sexp', 'module-count', '%s!=%d' % (count, len(comp))))
    recomputed = sha_text('\n'.join(rows))
    stated = str(pl.get('canonical-model-root-digest', ''))
    if recomputed != stated:
        viol.append(('L7', 'root', 'ROOT.sexp', 'canonical-model-root-digest',
                     '%s!=%s' % (recomputed[:16], stated[:16])))
    return recomputed


# ------------------------------------------------------------------ schema
def read_schema(dirp):
    forms = SR.read_forms_file(os.path.join(dirp, 'MODEL-SCHEMA.sexp'))
    decls = [f for f in forms if SR.head(f) == 'define-model-schema']
    if len(decls) != 1:
        die(3, 'SCHEMA-MALFORMED: expected exactly one define-model-schema form, found %d' % len(decls))
    enums, ftypes = {}, {}
    for sub in decls[0][3:]:
        h = SR.head(sub)
        if h == 'define-enum':
            enums[str(sub[1]).lower()] = [SR.canonical_value(v, 'MODEL-SCHEMA.sexp', 'enum value') for v in sub[2]]
        elif h == 'define-fact-type':
            name = str(sub[1]).lower()
            pl = dict(SR.plist(sub[2:], 'MODEL-SCHEMA.sexp', 'define-fact-type %s' % name))
            req = [str(x).lower() for x in pl.get('required', [])]
            enum_keys = {str(pair[0]).lower(): str(pair[1]).lower() for pair in pl.get('enum', [])}
            refs = {}
            for r in pl.get('ref', []):
                refs[str(r[0]).lower()] = [str(t).lower() for t in r[1:]]
            ftypes[name] = dict(required=req, enum=enum_keys, ref=refs)
    return enums, ftypes


# ------------------------------------------------------------------ facts
def read_facts(dirp, comp, viol):
    facts, seen = [], {}
    for name, _pin in comp:
        path = os.path.join(dirp, name)
        if not os.path.isfile(path):
            continue
        try:
            forms = SR.read_forms_file(path)
        except SR.SexpError as e:
            die(3, 'MODULE-UNREADABLE: %s' % e)
        for form in forms:
            h = SR.head(form)
            if h in HEADERS:
                continue
            if h != 'fact':
                die(3, 'UNCONSUMED-CANONICAL-SYNTAX: %s: top-level form %r is neither a fact nor a declared '
                       'header — the model universe would be incomplete' % (name, h))
            if len(form) < 3:
                die(3, 'MALFORMED-FACT: %s: a fact needs a type and an id' % name)
            ftype = str(form[1]).lower()
            fid = SR.canonical_value(form[2], name, 'fact id')
            try:
                pairs = SR.plist(form[3:], name, '%s %s' % (ftype, fid))
            except SR.SexpError as e:
                die(3, 'MALFORMED-FACT: %s' % e)
            keys = [k.lower() for k, _ in pairs]
            for k in sorted(set(keys)):
                if keys.count(k) > 1:
                    viol.append(('L2', ftype, fid, k, 'DUPLICATE-KEY'))
            if (ftype, fid) in seen:
                viol.append(('L2', ftype, fid, 'seat', 'DUPLICATE-SEAT-ALSO-IN-%s' % seen[(ftype, fid)]))
            else:
                seen[(ftype, fid)] = name
            facts.append((name, ftype, fid, pairs))
    owner = {}
    for _m, ftype, fid, _p in facts:
        if fid in owner and owner[fid] != ftype:
            viol.append(('L2', ftype, fid, 'id', 'ALSO-DECLARED-UNDER-%s' % owner[fid]))
        owner.setdefault(fid, ftype)
    return facts


def commitment_lines(facts):
    per_mod, per_fam, allr = {}, {}, []
    for mod, ftype, fid, pairs in facts:
        r = SR.canonical_fact_render(ftype, fid, pairs, mod)
        allr.append(r); per_mod.setdefault(mod, []).append(r); per_fam.setdefault(ftype, []).append(r)
    dig = lambda rs: sha_text('\n'.join(sorted(rs)))
    out = ['COMMITMENT total-facts %d' % len(allr), 'COMMITMENT total-digest %s' % dig(allr)]
    for m in sorted(per_mod):
        out.append('COMMITMENT module %s %d %s' % (m, len(per_mod[m]), dig(per_mod[m])))
    for f in sorted(per_fam):
        out.append('COMMITMENT family %s %d %s' % (f, len(per_fam[f]), dig(per_fam[f])))
    return out, per_mod, per_fam


def compare_commitments(dirp, mine):
    path = os.path.join(dirp, 'KERNEL-COMMITMENT.txt')
    if not os.path.isfile(path):
        die(3, 'COMMITMENT-UNAVAILABLE: %s does not exist — the kernel universe cannot be compared, so no '
               'verdict is issued by this path' % path)
    theirs = SR.read_file(path).splitlines()
    if theirs != mine:
        only_k = [l for l in theirs if l not in mine]
        only_c = [l for l in mine if l not in theirs]
        die(3, 'COMMITMENT-MISMATCH: the kernel and this checker consumed different fact universes',
            *(['  kernel-only: %s' % l for l in only_k[:12]] + ['  checker-only: %s' % l for l in only_c[:12]]))


# ------------------------------------------------------------------ clingo encoding
def q(s):
    return '"%s"' % str(s).replace('\\', '\\\\').replace('"', '\\"')


RULES = r'''
% ---------- L1 well-formedness: declared type, required keys, closed enum domains
haskey(T,I,K) :- kv(T,I,K,_).
violation("L1",T,I,"fact-type","UNDECLARED-FACT-TYPE") :- decl(T,I), not ftype(T).
violation("L1",T,I,K,"MISSING-REQUIRED-KEY") :- decl(T,I), reqkey(T,K), not haskey(T,I,K).
violation("L1",T,I,K,V) :- kv(T,I,K,V), enumkey(T,K,E), not enumdom(E,V).
% ---------- L3 closed typed references: the value must be a declared id of one permitted target type
resolved(T,I,K) :- kv(T,I,K,V), refkey(T,K,G), decl(G,V).
violation("L3",T,I,K,V) :- kv(T,I,K,V), refkey(T,K,_), not resolved(T,I,K).
% ---------- L4 acyclicity of EVERY declared from/to relation over a single node type
multi(T,K) :- refkey(T,K,A), refkey(T,K,B), A!=B.
edgerel(T,N) :- refkey(T,"from",N), refkey(T,"to",N), not multi(T,"from"), not multi(T,"to").
edge(T,X,Y) :- edgerel(T,_), kv(T,I,"from",X), kv(T,I,"to",Y).
reach(T,X,Y) :- edge(T,X,Y).
reach(T,X,Z) :- reach(T,X,Y), edge(T,Y,Z).
violation("L4",T,X,"cycle",X) :- edgerel(T,_), reach(T,X,X).
% ---------- L5 public/private isolation, failing closed on any consumer of undecidable kind
subkind(S,"PUBLIC")  :- kv("subsystem",S,"classification","PUBLIC").
subkind(S,"PRIVATE") :- kv("subsystem",S,"classification","PRIVATE").
consumer(C) :- kv("consumes",_,"consumer",C).
ckind(C,K) :- consumer(C), decl("subsystem",C), subkind(C,K).
ckind(C,K) :- consumer(C), decl("component",C), kv("component",C,"owner-subsystem",O), subkind(O,K).
ckind(C,K) :- consumer(C), decl("type",C), haskey("type",C,"consumer-role"), kv("type",C,"classification",K).
unpermitted(C) :- consumer(C), decl("type",C), not haskey("type",C,"consumer-role").
violation("L5","consumes",C,"consumer","TYPE-CONSUMER-WITHOUT-CONSUMER-ROLE") :- unpermitted(C).
violation("L5","consumes",C,"consumer","UNKNOWN-CONSUMER-KIND") :-
    consumer(C), not unpermitted(C), not ckind(C,"PUBLIC"), not ckind(C,"PRIVATE").
privtype(P) :- kv("type",P,"classification","PRIVATE").
violation("L5","consumes",I,"provides",P) :-
    kv("consumes",I,"consumer",C), kv("consumes",I,"provides",P), privtype(P), ckind(C,"PUBLIC").
% ---------- L6 every subsystem carries a requirement -> seat -> test -> WP mapping
covered(S) :- kv("req-map",_,"subsystem",S).
violation("L6","subsystem",S,"req-map","UNMAPPED-SUBSYSTEM") :- decl("subsystem",S), not covered(S).
#show violation/5.
'''


def build_program(facts, enums, ftypes):
    L = []
    for _mod, ftype, fid, pairs in facts:
        L.append('decl(%s,%s).' % (q(ftype), q(fid)))
        for k, v in pairs:
            L.append('kv(%s,%s,%s,%s).' % (q(ftype), q(fid), q(k.lower()),
                                           q(SR.canonical_value(v, _mod, '%s %s :%s' % (ftype, fid, k)))))
    for name, vals in sorted(enums.items()):
        for v in vals:
            L.append('enumdom(%s,%s).' % (q(name), q(v)))
    for t, spec in sorted(ftypes.items()):
        L.append('ftype(%s).' % q(t))
        for k in spec['required']:
            L.append('reqkey(%s,%s).' % (q(t), q(k)))
        for k, e in sorted(spec['enum'].items()):
            L.append('enumkey(%s,%s,%s).' % (q(t), q(k), q(e)))
        for k, tgts in sorted(spec['ref'].items()):
            for g in tgts:
                L.append('refkey(%s,%s,%s).' % (q(t), q(k), q(g)))
    return '\n'.join(L) + '\n' + RULES


def run(program):
    ctl = clingo.Control(['--warn=none'])
    ctl.add('base', [], program)
    ctl.ground([('base', [])])
    out = set()
    with ctl.solve(yield_=True) as h:
        for mdl in h:
            for a in mdl.symbols(shown=True):
                if a.name == 'violation':
                    out.add(tuple(str(x).strip('"') for x in a.arguments))
            break
    return out


def main():
    self_test_hash()
    dirp = HERE
    if len(sys.argv) > 1:
        dirp = os.path.dirname(os.path.abspath(sys.argv[1]))
    viol = []
    try:
        pl, comp = read_root(dirp)
        recomputed = verify_root(dirp, pl, comp, viol)
        enums, ftypes = read_schema(dirp)
        facts = read_facts(dirp, comp, viol)
    except SR.SexpError as e:
        die(3, 'MODEL-UNREADABLE: %s' % e)
    try:
        lines, per_mod, per_fam = commitment_lines(facts)
    except SR.SexpError as e:
        die(3, 'MALFORMED-MODEL: %s' % e)
    with open(os.path.join(dirp, 'CHECKER-COMMITMENT.txt'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(lines) + '\n')
    compare_commitments(dirp, lines)
    try:
        program = build_program(facts, enums, ftypes)
    except SR.SexpError as e:
        die(3, 'MALFORMED-MODEL: %s' % e)
    viol = sorted(set(viol) | run(program))
    exp = {'checker': CHECKER_VERSION,
           'module-universe': [n for n, _ in comp],
           'recomputed-model-root-digest': recomputed,
           'declared-model-root-digest': str(pl.get('canonical-model-root-digest', '')),
           'total-facts': len(facts),
           'module-counts': {m: len(v) for m, v in sorted(per_mod.items())},
           'module-digests': {m: sha_text('\n'.join(sorted(v))) for m, v in sorted(per_mod.items())},
           'family-counts': {t: len(v) for t, v in sorted(per_fam.items())},
           'family-digests': {t: sha_text('\n'.join(sorted(v))) for t, v in sorted(per_fam.items())},
           'violations': [list(v) for v in viol]}
    os.makedirs(os.path.join(dirp, 'CHECKER'), exist_ok=True)
    with open(os.path.join(dirp, 'CHECKER', 'NEUTRAL-EXPORT.json'), 'w', encoding='utf-8') as f:
        json.dump(exp, f, indent=1, sort_keys=True)
    laws = sorted({v[0] for v in viol})
    for law in ('L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7'):
        print('INDEPENDENT %s: %s' % (law, 'FAIL' if law in laws else 'PASS'))
    if viol:
        for v in viol:
            print('INDEPENDENT VIOLATION %s: %s %s :%s = %s' % v)
        die(3, 'INDEPENDENT ARCHITECTURE INVARIANTS: FAIL (%s)' % ','.join(laws))
    die(0, 'INDEPENDENT ARCHITECTURE INVARIANTS: PASS (facts=%d, modules=%d, fact-set commitment identical to '
           'the kernel, model-root %s recomputed)' % (len(facts), len(comp), recomputed[:12]))


if __name__ == '__main__':
    main()
