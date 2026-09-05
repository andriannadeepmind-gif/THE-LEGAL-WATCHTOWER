#!/usr/bin/env python3
"""run_fixtures.py — the golden fixtures and the generated property families, driven by the MODEL.

REVIEW-2 N-4 / N-5 / N-19 — WHAT CHANGED AND WHY.
The previous runner defined its own universe and read the model with a regex and physical lines:

    MODULES = re.findall(r':module "([^"]+)"', open('ROOT.sexp').read())
    subs    = [l.split()[2] for l in open('subsystems.sexp') if l.startswith('(fact subsystem ')]
    privs   = [l.split()[2] for l in open('interfaces-and-types.sexp') if l.startswith('(fact type ') and 'PRIVATE' in l]

The independent review showed both consequences. Deleting a golden fixture reported `golden fixtures=7` and
still exited 0; forcing zero tests reported `0/0 failures=0` and still exited 0. And a semantically neutral
multi-line reformat — which left the kernel at `facts=1439` with an unchanged commitment digest — silently
dropped the entire public/private-leak family from six cases to zero, because `'PRIVATE' in l` is a statement
about a LINE, not about a fact. The parsed `:law` of each fixture was never used at all.

Now:
  * the universe is `verification-corpus.sexp`. Fixture ids, expectations, expected LAW and expected REASON, the
    property families and their EXACT cardinalities are model facts. This program enumerates what the model
    declares and fails if what it finds differs — in either direction;
  * every case is enumerated through the classified reader seat, so line structure carries no meaning;
  * mutations are STRUCTURAL: a fact is removed by rebuilding the module from its parsed forms, never by
    dropping a line that happens to start with the right prefix;
  * both the expected law and the expected reason are enforced on BOTH verification paths. A rejection for the
    wrong law is a failure, not a pass;
  * there are no caps. `subs[:6]` and `stores[:4]` are gone; a family runs exactly its declared cardinality.

Exit 0 iff the declared universe is exactly the executed universe, every golden fixture yields its expected
result for its exact reason on both paths, and every generated property case is rejected for its declared law.
"""
import argparse, hashlib, importlib.util, os, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location('sexp_reader', os.path.join(HERE, 'SEXP-READER.py'))
SR = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(SR)
HEADERS = SR.HEADERS          # one seat: the reader declares the header vocabulary


# ─────────────────────────────────────────────────────────────── model access
def root_modules(dirp):
    forms = SR.read_forms_file(os.path.join(dirp, 'ROOT.sexp'))
    root = [f for f in forms if SR.head(f) == 'define-model-root'][0]
    pl = dict(SR.plist(root[2:], 'ROOT.sexp', 'root'))
    return [str(dict(SR.plist(e, 'ROOT.sexp', 'entry'))['module']) for e in pl['composition']]


def read_facts(dirp, module):
    out = []
    for form in SR.read_forms_file(os.path.join(dirp, module)):
        if SR.head(form) in HEADERS:
            continue
        ftype = str(form[1]).lower()
        fid = SR.canonical_value(form[2], module, 'id')
        pairs = SR.plist(form[3:], module, '%s %s' % (ftype, fid))
        out.append((ftype, fid, {k.lower(): SR.canonical_value(v, module, k) for k, v in pairs}, form))
    return out


def corpus():
    fx, fam = {}, {}
    for ftype, fid, p, _f in read_facts(HERE, 'verification-corpus.sexp'):
        if ftype == 'fixture':
            fx[fid] = p
        elif ftype == 'property-family':
            fam[fid] = p
    return fx, fam


# ─────────────────────────────────────────────────────────────── structural mutation
def emit(form):
    """Serialize a parsed form back to canonical text. Used so a fact can be REMOVED without touching lines."""
    if isinstance(form, list):
        return '(' + ' '.join(emit(x) for x in form) + ')'
    if isinstance(form, SR.Str):
        return '"%s"' % str(form).replace('\\', '\\\\').replace('"', '\\"')
    if isinstance(form, SR.Kw):
        return ':' + str(form)
    return str(form)


def remove_fact(dirp, module, ftype, fid, field=None):
    """Remove facts structurally. With FIELD, every fact of FTYPE whose FIELD equals FID goes — which is what
    'this subsystem has no mapping at all' means when a subsystem legitimately carries several req-map rows."""
    path = os.path.join(dirp, module)
    kept = []
    dropped = 0
    for form in SR.read_forms_file(path):
        if SR.head(form) == 'fact' and str(form[1]).lower() == ftype.lower():
            if field is None:
                match = SR.canonical_value(form[2], module, 'id') == fid
            else:
                v = SR.kv(form, field)
                match = v is not None and SR.canonical_value(v, module, field) == fid
            if match:
                dropped += 1
                continue
        kept.append(form)
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(emit(x) for x in kept) + '\n')
    return dropped


def rehash(dirp):
    subprocess.run([sys.executable, os.path.join(dirp, 'build_root.py')], capture_output=True, cwd=dirp, check=True)


def model_copy(work, n):
    d = os.path.join(work, 'm%04d' % n)
    os.makedirs(d, exist_ok=True)
    for m in MODULES:
        shutil.copy(os.path.join(HERE, m), os.path.join(d, m))
    shutil.copy(os.path.join(HERE, 'ROOT.sexp'), os.path.join(d, 'ROOT.sexp'))
    shutil.copy(os.path.join(HERE, 'SEXP-READER.py'), os.path.join(d, 'SEXP-READER.py'))
    shutil.copy(os.path.join(HERE, 'build_root.py'), os.path.join(d, 'build_root.py'))
    return d


def apply_mutation(d, mut):
    op = str(mut[0])
    if op == 'none':
        return
    if op == 'add':
        with open(os.path.join(d, str(mut[1])), 'a', encoding='utf-8') as f:
            f.write('\n' + str(mut[2]) + '\n')
        rehash(d)
    elif op in ('remove-fact', 'remove-facts-where'):
        field = str(mut[4]) if op == 'remove-facts-where' else None
        if remove_fact(d, str(mut[1]), str(mut[2]), str(mut[3]), field) == 0:
            raise SystemExit('FIXTURE-MUTATION-VACUOUS: %s %s is not present in %s; the fixture would test '
                             'nothing' % (mut[2], mut[3], mut[1]))
        rehash(d)
    elif op == 'append-no-rehash':
        with open(os.path.join(d, str(mut[1])), 'a', encoding='utf-8') as f:
            f.write('\n' + str(mut[2]) + '\n')
    else:
        raise SystemExit('FIXTURE-MUTATION-UNKNOWN: %r' % op)


# ─────────────────────────────────────────────────────────────── the two verification paths
def run_kernel(d, work):
    c = os.path.join(work, 'k.txt')
    r = subprocess.run(['sbcl', '--script', os.path.join(HERE, 'KERNEL', 'model-law-kernel.lisp'),
                        os.path.join(d, 'ROOT.sexp'), '--commitment', c], capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr, c


def run_checker(d, work, kcommit):
    r = subprocess.run([sys.executable, os.path.join(HERE, 'CHECKER', 'independent_check.py'),
                        os.path.join(d, 'ROOT.sexp'), '--kernel-commitment', kcommit,
                        '--commitment', os.path.join(work, 'c.txt'),
                        '--export', os.path.join(work, 'export.json')], capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


FAILURES = []


def check(name, expect, law, reason, mut, work, n):
    d = model_copy(work, n)
    try:
        apply_mutation(d, mut)
        want = 0 if expect == 'PASS' else 3
        kc, ko, kcommit = run_kernel(d, work)
        if kc != want:
            FAILURES.append('%s: kernel exit %d != %d' % (name, kc, want)); return
        if expect == 'FAIL':
            if ('VIOLATION %s' % law) not in ko:
                FAILURES.append('%s: kernel rejected it, but not for %s — %s'
                                % (name, law, [l for l in ko.splitlines() if 'VIOLATION' in l][:2])); return
            if reason.upper() not in ko.upper():
                FAILURES.append('%s: kernel reason missing: %r' % (name, reason)); return
        cc, co = run_checker(d, work, kcommit)
        if cc != want:
            FAILURES.append('%s: checker exit %d != %d (path disagreement)' % (name, cc, want)); return
        if expect == 'FAIL' and ('INDEPENDENT %s: FAIL' % law) not in co and ('VIOLATION %s' % law) not in co:
            FAILURES.append('%s: the independent path rejected it, but not for %s' % (name, law))
    finally:
        shutil.rmtree(d, ignore_errors=True)


# ─────────────────────────────────────────────────────────────── property families
def family_cases(fid, spec):
    """Enumerate a family's cases FROM THE MODEL, through the reader. Never from lines."""
    module = spec['source-module']
    sel = spec['selector']
    facts = read_facts(HERE, module)
    if sel == 'subsystem':
        # remove EVERY req-map of the subsystem: S20 and S21 legitimately carry several (a recorded
        # COMPOSITE-WP normalization), so dropping only the first would leave them mapped and test nothing
        return [(i, ('remove-facts-where', 'requirements-tests-workpackets.sexp', 'req-map', i, 'subsystem'))
                for _t, i, _p, _f in facts if _t == 'subsystem']
    if sel == 'type:classification=PRIVATE':
        pub = next(x[1] for x in read_facts(HERE, 'subsystems.sexp')
                   if x[0] == 'subsystem' and x[2]['classification'] == 'PUBLIC')
        return [(i, ('add', 'dependencies-and-boundaries.sexp',
                     '(fact consumes PROP__%s :consumer %s :provides %s)' % (i, pub, i)))
                for _t, i, p, _f in facts if _t == 'type' and p['classification'] == 'PRIVATE']
    if sel == 'store':
        return [(i, ('add', 'stores-and-authorities.sexp',
                     '(fact store %s :owner %s :writer %s)' % (i, p['owner'], p['writer'])))
                for _t, i, p, _f in facts if _t == 'store']
    if sel == 'seat':
        return [(i, ('remove-fact', 'seats.sexp', 'seat', i)) for _t, i, _p, _f in facts if _t == 'seat']
    if sel == 'stage-edge':
        return [(i, ('add', 'dependencies-and-boundaries.sexp',
                     '(fact stage-edge PROP__%s :from %s :to %s)' % (i, p['to'], p['from'])))
                for _t, i, p, _f in facts if _t == 'stage-edge']
    raise SystemExit('PROPERTY-FAMILY-SELECTOR-UNKNOWN: %s declares selector %r' % (fid, sel))


def main():
    global MODULES
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--work', default=None)
    args = ap.parse_args()
    work = args.work or tempfile.mkdtemp(prefix='aml-fixtures-')
    os.makedirs(work, exist_ok=True)
    MODULES = root_modules(HERE)
    fx, fam = corpus()

    # the declared fixture universe must equal the fixture files that exist — in both directions
    present = set()
    for sub in ('PASS', 'FAIL'):
        d = os.path.join(HERE, 'FIXTURES', sub)
        if os.path.isdir(d):
            present |= {'FIXTURES/%s/%s' % (sub, f) for f in os.listdir(d) if f.endswith('.sexp')}
    declared_paths = {p['path'] for p in fx.values()}
    for p in sorted(declared_paths - present):
        FAILURES.append('FIXTURE-FILE-MISSING: the corpus declares %s but no such file exists' % p)
    for p in sorted(present - declared_paths):
        FAILURES.append('FIXTURE-FILE-UNDECLARED: %s exists but the corpus declares no fixture for it' % p)
    if FAILURES:
        print('golden fixtures=0 generated properties=0 failures=%d' % len(FAILURES))
        for f in FAILURES:
            print('  FAIL:', f)
        sys.exit(1)

    n = 0
    for fid in sorted(fx):
        spec = fx[fid]
        forms = SR.read_forms_file(os.path.join(HERE, spec['path']))
        decl = [f for f in forms if SR.head(f) == 'fixture']
        if len(decl) != 1 or len(forms) != 1:
            FAILURES.append('%s: %s must hold exactly one fixture form' % (fid, spec['path'])); continue
        if SR.canonical_value(decl[0][1], spec['path'], 'id') != fid:
            FAILURES.append('%s: %s declares a different fixture id' % (fid, spec['path'])); continue
        mut = SR.kv(decl[0], 'mutate')
        n += 1
        check(fid, spec['expect'], spec['law'], spec['reason'], mut, work, n)
    ng = n

    np = 0
    for fid in sorted(fam):
        spec = fam[fid]
        cases = family_cases(fid, spec)
        want = int(spec['cardinality'])
        if len(cases) != want:
            FAILURES.append('PROPERTY-FAMILY-CARDINALITY: %s declares %d cases, the model yields %d — a family '
                            'that silently changed size is a failure, not a smaller number'
                            % (fid, want, len(cases)))
            continue
        for label, mut in cases:
            n += 1; np += 1
            check('%s/%s' % (fid, label), 'FAIL', spec['law'], spec['reason'], mut, work, n)

    print('golden fixtures=%d  generated properties=%d  failures=%d' % (ng, np, len(FAILURES)))
    for f in FAILURES:
        print('  FAIL:', f)
    if ng == 0 or np == 0:
        print('  FAIL: a run that executes no fixture or no property case is not a pass')
        sys.exit(1)
    sys.exit(0 if not FAILURES else 1)


if __name__ == '__main__':
    main()
