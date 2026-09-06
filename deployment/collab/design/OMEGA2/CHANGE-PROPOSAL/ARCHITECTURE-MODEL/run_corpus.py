#!/usr/bin/env python3
"""run_corpus.py — the ONE runner of the declared verification corpus.

Review-3 §15. There were three runners — golden fixtures, component falsifiers, composed-gate falsifiers — and
each carried its own copy of the same scaffolding: model access, disposable copies, the two verification paths,
reporting. Three copies of one concept is three places for them to drift, and it was 1,162 lines of trusted
computing base for a model of 1,573 facts. This program is that one seat.

The universe is DATA, not code: `verification-corpus.sexp` declares the fixtures with their expected law and
reason, the property families with their exact cardinalities, the falsifiers with the harness that runs them and
— where the defect is an ordinary model mutation — the mutation itself. This runner carries mutation SHAPES; the
model carries the cases. A held-out defect therefore costs a corpus row and no code.

What consolidating the orchestration must not do, and does not do: the two verification paths stay independent.
The Common Lisp kernel and the independent checker are separate programs invoked as such, each with its own
reader and its own commitment, and the reference implementation in the reader seat is a third. This runner
compares their verdicts; it never computes them.

Before any case runs, the declared universe is checked against what exists — missing, extra, duplicate, and a
family that has been COHERENTLY deleted (fact and implementation together) are each a named failure unless the
model carries a `universe-authorization` for the reduction.

  run_corpus.py --kind fixtures   golden fixtures + generated property families
  run_corpus.py --kind component  COMPONENT falsifiers (isolated machinery)
  run_corpus.py --kind composed   COMPOSED_GATE falsifiers (they execute the gate's own --checks phase)
The composed kind is run by the gate's FULL phase and never from its --checks phase: a checks phase
that ran it would recurse forever.
"""
import argparse, ast, contextlib, hashlib, importlib.util, io, os, re, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
LAYOUT_ROOT = os.path.abspath(os.path.join(HERE, '..', '..', '..', '..', '..', '..'))
REPO = os.environ.get('AML_REPO') or LAYOUT_ROOT
REL = os.path.relpath(HERE, LAYOUT_ROOT).replace(os.sep, '/')
AM_REL, CP_REL = REL, os.path.dirname(REL)
_spec = importlib.util.spec_from_file_location('sexp_reader', os.path.join(HERE, 'SEXP-READER.py'))
SR = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(SR)
_aspec = importlib.util.spec_from_file_location('acceptance_runtime', os.path.join(HERE, 'acceptance_runtime.py'))
AR = importlib.util.module_from_spec(_aspec); _aspec.loader.exec_module(AR)
GATE = 'ARCHITECTURE-MODEL-GATE.sh'
IDENT = ['-c', 'user.name=Stavropoulos Law\u00ae', '-c', 'user.email=info@stavropouloslaw.com']
LEGACY_SCRATCH = ['/tmp/k.out', '/tmp/c.out', '/tmp/fx.out', '/tmp/fl.out', '/tmp/ov.bak', '/tmp/ddi.out']
RESULTS, FAILURES, MODULES, _CAND = [], [], [], {}


PY = SR.tool_path(HERE, 'CHECKER_RUNTIME')
SBCL = SR.tool_path(HERE, 'KERNEL_RUNTIME')


def record(name, intent, ok_, detail):
    detail = detail if isinstance(detail, str) else repr(detail)
    RESULTS.append((name, intent, ok_, detail))
    print('%-34s %-52s %s' % (name, intent[:52], 'REJECTED as intended' if ok_ else 'NOT REJECTED - ' + detail))


def run_one(name, intent, fn):
    try:
        okk, detail = fn()
    except Exception as e:                                   # a falsifier must never pass by crashing
        okk, detail = False, 'harness error: %r' % (e,)
    record(name, intent, okk, detail)
def root_modules(dirp):
    """The pinned module order of a (possibly mutated) copy — never cached: the copies are mutated in place."""
    return SR.read_model(dirp, cache=False).modules


def read_facts(dirp, module):
    out = []
    for form in SR.read_forms_file(os.path.join(dirp, module)):
        if SR.head(form) in SR.HEADERS:
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


def modules():
    forms = SR.read_forms_file(os.path.join(HERE, 'ROOT.sexp'))
    r = [f for f in forms if SR.head(f) == 'define-model-root'][0]
    pl = dict(SR.plist(r[2:], 'ROOT.sexp', 'root'))
    return [str(dict(SR.plist(e, 'ROOT.sexp', 'e'))['module']) for e in pl['composition']]


def sha_file(p):
    with open(p, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()


def append(d, mod, text):
    with open(os.path.join(d, mod), 'a', encoding='utf-8') as f:
        f.write('\n' + text + '\n')


def seat_text(seat, rel):
    with open(os.path.join(seat, rel), encoding='utf-8') as f:
        return f.read()


def seat_write(seat, rel, text):
    with open(os.path.join(seat, rel), 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)


def seat_path(rel):
    """A seat-relative path expressed as the repository path the candidate tree uses."""
    return '%s/%s' % (os.path.relpath(HERE, LAYOUT_ROOT).replace(os.sep, '/'), rel)


def candidate():
    """(tree, exported seat) for the immutable candidate — resolved once, by the one seat that builds it."""
    if not _CAND:
        r = AR.bounded_run([PY, os.path.join(HERE, 'gate_checks.py'), 'candidate'],
                           capture_output=True, text=True, cwd=HERE)
        tree = next((l.split()[1] for l in r.stdout.splitlines() if l.startswith('CANDIDATE-TREE ')), None)
        if tree is None:
            raise RuntimeError('the candidate tree could not be resolved: %s' % (r.stdout + r.stderr)[-400:])
        _CAND['tree'] = tree
        _CAND['rel'] = os.path.relpath(HERE, LAYOUT_ROOT).replace(os.sep, '/')
    return _CAND['tree'], _CAND['rel']


def export_seat():
    """A disposable export of the candidate, shaped exactly as the gate's own export.

    The gate archives the whole CHANGE-PROPOSAL subtree, because the producers read migration-source registries
    that sit beside the seat. A falsifier export of the seat ALONE therefore made a generation falsifier fail
    for a missing source file instead of for the defect it injected — a harness artefact masquerading as a
    rejection. The export shape is the gate's, so a falsifier proves something about the gate."""
    tree, rel = candidate()
    d = tempfile.mkdtemp(prefix='fals-seat-')
    tar = AR.checked(['git', '-C', REPO, 'archive', tree, CP_REL], capture_output=True).stdout
    AR.checked(['tar', '-x', '-C', d], input=tar)
    return d, os.path.join(d, rel)


def model_copy():
    d = tempfile.mkdtemp(prefix='fals-model-')
    for m in modules():
        shutil.copy(os.path.join(HERE, m), os.path.join(d, m))
    shutil.copy(os.path.join(HERE, 'ROOT.sexp'), os.path.join(d, 'ROOT.sexp'))
    return d


def rehash(d, digest_fn=None, order=None):
    """Re-pin every module and recompute the root digest exactly as build_root.py does."""
    import re
    mods = order or modules()
    t = open(os.path.join(d, 'ROOT.sexp'), encoding='utf-8').read()
    rows = [(m, (digest_fn or sha_file)(os.path.join(d, m))) for m in mods]
    for m, h in rows:
        t = re.sub(r'(:module "%s" :sha256 ")[0-9a-f]{64}' % re.escape(m), r'\g<1>' + h, t)
    dig = hashlib.sha256('\n'.join('%s:%s' % (m, h) for m, h in rows).encode('utf-8')).hexdigest()
    t = re.sub(r'(:canonical-model-root-digest ")[0-9a-f]{64}', r'\g<1>' + dig, t)
    open(os.path.join(d, 'ROOT.sexp'), 'w', encoding='utf-8', newline='\n').write(t)


def kernel(d):
    r = AR.bounded_run([SBCL, '--script', os.path.join(HERE, 'KERNEL', 'model-law-kernel.lisp'),
                        os.path.join(d, 'ROOT.sexp')], capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def checker(d):
    r = AR.bounded_run([PY, os.path.join(HERE, 'CHECKER', 'independent_check.py'),
                        os.path.join(d, 'ROOT.sexp')], capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def both_reject(mutate, needle_k, needle_c=None, rehash_after=True):
    """Both independent paths must reject the mutation, each naming the intended reason."""
    d = model_copy()
    try:
        mutate(d)
        if rehash_after:
            rehash(d)
        kc, ko = kernel(d)
        cc, co = checker(d)
        if kc == 0:
            return False, 'the Common Lisp kernel accepted it'
        if needle_k.upper() not in ko.upper():
            return False, 'kernel rejected it for another reason: %s' % [l for l in ko.splitlines() if 'VIOLATION' in l][:2]
        if cc == 0:
            return False, 'the independent checker accepted it'
        nc = needle_c or needle_k
        if nc.upper() not in co.upper():
            return False, 'checker rejected it for another reason: %s' % [l for l in co.splitlines() if 'VIOLATION' in l or 'MALFORMED' in l or 'UNCONSUMED' in l][:2]
        return True, ''
    finally:
        shutil.rmtree(d, ignore_errors=True)


def gate_check(which, cwd=None):
    r = AR.bounded_run([PY, os.path.join(HERE, 'gate_checks.py'), which],
                       capture_output=True, text=True, cwd=cwd or HERE)
    return r.returncode, r.stdout + r.stderr


def index_repo(add=(), remove=()):
    """A throwaway git repository whose INDEX mirrors the real one, with no file checked out at all."""
    d = tempfile.mkdtemp(prefix='fals-index-')
    AR.checked(['git', 'init', '-q', d], capture_output=True)
    # It indexes the real repository's entries, so it must be able to READ those objects: without the alternate
    # every blob lookup in this repo fails, and a generator that needs file BYTES could only be made to work by
    # teaching it to tolerate an unreadable tracked path — the one tolerance that would let real machinery drop
    # out of the measured base unseen.
    with open(os.path.join(d, '.git', 'objects', 'info', 'alternates'), 'w') as fh:
        fh.write(AR.git_object_dir(REPO) + '\n')
    listing = AR.checked(['git', '-C', REPO, 'ls-files', '-s', '-z'], capture_output=True).stdout
    AR.checked(['git', '-C', d, 'update-index', '-z', '--index-info'], input=listing,
                   capture_output=True)
    for path in add:
        blob = AR.checked(['git', '-C', d, 'hash-object', '-w', '--stdin'], input=b'x\n',
                              capture_output=True).stdout.decode().strip()
        AR.checked(['git', '-C', d, 'update-index', '--add', '--cacheinfo', '100644,%s,%s' % (blob, path)],
                       capture_output=True)
    for path in remove:
        AR.checked(['git', '-C', d, 'update-index', '--force-remove', path], capture_output=True)
    return d


def inventory_on(repo_dir, out):
    """Run the real classification seat against a throwaway tracked universe; return (exit code, output)."""
    import contextlib, io
    BI = importlib.util.module_from_spec(_bspec_fresh())
    BI.__spec__.loader.exec_module(BI)
    BI.ROOT = repo_dir
    argv, buf = sys.argv, io.StringIO()
    sys.argv = ['build_inventory.py', '--out', out]
    code = 0
    try:
        with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
            BI.main()
    except SystemExit as e:
        code = e.code or 0
    finally:
        sys.argv = argv
    return code, buf.getvalue()


def _bspec_fresh():
    return importlib.util.spec_from_file_location('build_inventory_%d' % len(RESULTS),
                                                  os.path.join(HERE, 'build_inventory.py'))


def _seat_check(which, mutate, needle):
    """Run a REAL gate check against a deliberately mutated export of the immutable candidate seat.

    The check logic is the gate's own; only the source of the model differs, so a falsifier proves the deployed
    check catches the defect rather than proving a re-implementation of it does."""
    tree, _rel = candidate()
    d, seat = export_seat()
    work = tempfile.mkdtemp(prefix='fals-work-')
    try:
        mutate(seat)
        r = AR.bounded_run([PY, os.path.join(HERE, 'gate_checks.py'), which,
                            '--tree', tree, '--work', work, '--seat', seat],
                           capture_output=True, text=True, cwd=HERE)
        out = r.stdout + r.stderr
        if r.returncode == 0:
            return False, 'the check passed: %s' % out.strip().splitlines()[-1:]
        if needle not in out:
            return False, 'rejected for another reason: %s' % [l.strip() for l in out.splitlines()
                                                               if l.startswith('  ')][:2]
        return True, ''
    finally:
        shutil.rmtree(d, ignore_errors=True)
        shutil.rmtree(work, ignore_errors=True)


def tree_with(changes):
    """(tree, env) for an immutable tree equal to the candidate except for CHANGES {repo path: bytes | None}.

    Built through a throwaway index AND a throwaway object directory: the new blobs are written into a
    temporary store that reads the repository's own objects through the alternates mechanism, so the repository
    gains nothing — no ref moves, no index is written, no file is touched. This is how a falsifier puts a defect
    into the TREE UNDER JUDGEMENT, which is the only place a defect the gate must catch can honestly live.
    """
    tree, _rel = candidate()
    d = tempfile.mkdtemp(prefix='fals-odb-')
    env = dict(os.environ, GIT_INDEX_FILE=os.path.join(d, 'index'),
               GIT_OBJECT_DIRECTORY=os.path.join(d, 'objects'),
               GIT_ALTERNATE_OBJECT_DIRECTORIES=AR.git_object_dir(REPO))
    os.makedirs(env['GIT_OBJECT_DIRECTORY'])

    def g(args, **kw):
        return AR.checked(['git', '-C', REPO] + args, env=env, capture_output=True, **kw)

    g(['read-tree', tree])
    for path, data in sorted(changes.items()):
        if data is None:
            g(['update-index', '--force-remove', path])
        else:
            blob = g(['hash-object', '-w', '--stdin'], input=data).stdout.decode().strip()
            g(['update-index', '--add', '--cacheinfo', '100644,%s,%s' % (blob, path)])
    return g(['write-tree']).stdout.decode().strip(), env, d


def _tree_check(which, changes, needle):
    """Put a defect into the CANDIDATE TREE ITSELF and require the real gate check to name it."""
    _tree, _rel = candidate()
    tree, env, d = tree_with(changes)
    work = tempfile.mkdtemp(prefix='fals-work-')
    try:
        r = AR.bounded_run([PY, os.path.join(HERE, 'gate_checks.py'), which,
                            '--tree', tree, '--work', work], capture_output=True, text=True, cwd=HERE, env=env)
        out = r.stdout + r.stderr
        if r.returncode == 0:
            return False, 'the check passed: %s' % out.strip().splitlines()[-1:]
        if needle not in out:
            return False, 'rejected for another reason: %s' % [l.strip() for l in out.splitlines()
                                                               if l.startswith('  ')][:2]
        return True, ''
    finally:
        shutil.rmtree(d, ignore_errors=True)
        shutil.rmtree(work, ignore_errors=True)


def _inventory_seat_mutation(transform):
    def mut(seat):
        b = seat_text(seat, 'files-and-roles.sexp')
        t = transform(b)
        if t == b:
            raise RuntimeError('the mutation changed nothing; the falsifier would be vacuous')
        seat_write(seat, 'files-and-roles.sexp', t)
    return mut


def _drop_line(match):
    def t(b):
        for l in b.splitlines():
            if match(l):
                return b.replace(l + '\n', '', 1)
        return b
    return t


def baseline_totals():
    d = model_copy()
    try:
        kc, ko = kernel(d)
        cc, co = checker(d)
        n = [l for l in ko.splitlines() if l.startswith('COMMITMENT total-facts ')][0].split()[-1]
        return kc == 0 and cc == 0, int(n)
    finally:
        shutil.rmtree(d, ignore_errors=True)


def _kernel_then_mutate(mutation):
    d = model_copy()
    try:
        kc, ko = kernel(d)
        if kc != 0:
            return False, 'the baseline model did not pass the kernel'
        mutation(d)
        cc, co = checker(d)
        return cc != 0 and 'COMMITMENT-MISMATCH' in co, co.strip().splitlines()[:3]
    finally:
        shutil.rmtree(d, ignore_errors=True)


def migration_sources(seat):
    """The migration-source universe, derived the way the model defines it — every CANONICAL_MODEL_INPUT path
    outside the model seat — so this harness carries no second, hand-written copy of that universe."""
    out = []
    for f in SR.read_forms_file(os.path.join(seat, 'files-and-roles.sexp')):
        if SR.head(f) != 'fact' or str(f[1]) != 'file':
            continue
        path = str(f[2])
        if str(SR.kv(f, 'role') or '') == 'CANONICAL_MODEL_INPUT' and not path.startswith(AM_REL + '/'):
            out.append(path)
    return sorted(set(out))


def cp_copy():
    """A temporary repository whose LAYOUT mirrors the real one — the same relative depth, so every program
    under test resolves exactly the paths it resolves in place — holding the migration sources, the inventory
    that DEFINES the source universe, and just enough of the model seat to verify the ledger."""
    d, seat = export_seat()
    root = tempfile.mkdtemp(prefix='fals-cp-')
    try:
        am = os.path.join(root, AM_REL)
        os.makedirs(am)
        for rel in migration_sources(seat):
            dst = os.path.join(root, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy(os.path.join(REPO, rel), dst)
        for f in ('build_deferred.py', 'SEXP-READER.py', 'deferred-imports.sexp', 'files-and-roles.sexp'):
            shutil.copy(os.path.join(seat, f), os.path.join(am, f))
    finally:
        shutil.rmtree(d, ignore_errors=True)
    return root, am


def run_verify(am):
    r = AR.bounded_run([PY, os.path.join(am, 'build_deferred.py'), '--verify'],
                       capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def _probe_seat(body):
    return lambda d: append(d, 'seats.sexp', body)


def expand(text):
    return str(text).replace('{NL}', '\n').replace('{Q}', '"').replace('{BS}', '\\')


def declared_falsifiers(harness):
    """Every falsifier the MODEL declares with a mutation, for one harness — the runner carries the shapes,
    the model carries the cases."""
    out = []
    for f in SR.read_forms_file(os.path.join(HERE, 'verification-corpus.sexp')):
        if SR.head(f) != 'fact' or str(f[1]) != 'falsifier':
            continue
        p = {str(k).lower(): SR.canonical_value(v, 'verification-corpus.sexp', 'falsifier')
             for k, v in SR.plist(f[3:], 'verification-corpus.sexp', str(f[2]))}
        if p.get('harness') == harness and p.get('mutation'):
            out.append((SR.canonical_value(f[2], 'verification-corpus.sexp', 'id'), p))
    return sorted(out)


def data_driven(spec):
    """Run one model-declared mutation and require the intended named rejection."""
    kind, mod = spec['mutation'], spec.get('module')

    def mutate(d):
        path = os.path.join(d, mod)
        text = open(path, encoding='utf-8').read()
        if kind == 'APPEND':
            text += '\n' + expand(spec['form']) + '\n'
        else:
            was = text
            text = text.replace(expand(spec['replace-from']), expand(spec['replace-to']), 1)
            if text == was:
                raise RuntimeError('the declared :replace-from does not occur in %s' % mod)
        open(path, 'w', encoding='utf-8', newline='\n').write(text)

    if kind == 'CHECK':
        def seat_mutate(seat):
            path = os.path.join(seat, mod)
            text = open(path, encoding='utf-8').read()
            new = (text + '\n' + expand(spec['form']) + '\n') if 'form' in spec else \
                text.replace(expand(spec['replace-from']), expand(spec['replace-to']), 1)
            if new == text:
                raise RuntimeError('the declared mutation changed nothing in %s' % mod)
            open(path, 'w', encoding='utf-8', newline='\n').write(new)
        return _seat_check(spec['check'].lower(), seat_mutate, expand(spec['reason']))
    return both_reject(mutate, expand(spec['kernel-reason']), expand(spec['checker-reason']),
                       rehash_after=spec.get('rehash', 'YES') == 'YES')


def rebuild_root(dirp):
    AR.checked([PY, os.path.join(dirp, 'build_root.py')], capture_output=True, cwd=dirp)


def fixture_copy(work, n):
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
        rebuild_root(d)
    elif op in ('remove-fact', 'remove-facts-where'):
        field = str(mut[4]) if op == 'remove-facts-where' else None
        if remove_fact(d, str(mut[1]), str(mut[2]), str(mut[3]), field) == 0:
            raise SystemExit('FIXTURE-MUTATION-VACUOUS: %s %s is not present in %s; the fixture would test '
                             'nothing' % (mut[2], mut[3], mut[1]))
        rebuild_root(d)
    elif op == 'append-no-rehash':
        with open(os.path.join(d, str(mut[1])), 'a', encoding='utf-8') as f:
            f.write('\n' + str(mut[2]) + '\n')
    else:
        raise SystemExit('FIXTURE-MUTATION-UNKNOWN: %r' % op)


def fx_kernel(d, work):
    c = os.path.join(work, 'k.txt')
    r = AR.bounded_run([SBCL, '--script', os.path.join(HERE, 'KERNEL', 'model-law-kernel.lisp'),
                        os.path.join(d, 'ROOT.sexp'), '--commitment', c], capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr, c


def fx_checker(d, work, kcommit):
    r = AR.bounded_run([PY, os.path.join(HERE, 'CHECKER', 'independent_check.py'),
                        os.path.join(d, 'ROOT.sexp'), '--kernel-commitment', kcommit,
                        '--commitment', os.path.join(work, 'c.txt'),
                        '--export', os.path.join(work, 'export.json')], capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def check(name, expect, law, reason, mut, work, n):
    d = fixture_copy(work, n)
    try:
        apply_mutation(d, mut)
        want = 0 if expect == 'PASS' else 3
        kc, ko, kcommit = fx_kernel(d, work)
        if kc != want:
            FAILURES.append('%s: kernel exit %d != %d' % (name, kc, want)); return
        if expect == 'FAIL':
            if ('VIOLATION %s' % law) not in ko:
                FAILURES.append('%s: kernel rejected it, but not for %s — %s'
                                % (name, law, [l for l in ko.splitlines() if 'VIOLATION' in l][:2])); return
            if reason.upper() not in ko.upper():
                FAILURES.append('%s: kernel reason missing: %r' % (name, reason)); return
        cc, co = fx_checker(d, work, kcommit)
        if cc != want:
            FAILURES.append('%s: checker exit %d != %d (path disagreement)' % (name, cc, want)); return
        if expect == 'FAIL' and ('INDEPENDENT %s: FAIL' % law) not in co and ('VIOLATION %s' % law) not in co:
            FAILURES.append('%s: the independent path rejected it, but not for %s' % (name, law))
    finally:
        shutil.rmtree(d, ignore_errors=True)


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


def f01_generated_view_missing():
    return _seat_check('inventory', _inventory_seat_mutation(
        _drop_line(lambda l: l.startswith('(fact file ') and 'GENERATED/DEFERRED-DATA-IMPORT-VIEW.md' in l)),
        'MULTISET-MISMATCH')


def f02_new_tracked_file_no_rule():
    d = index_repo(add=['zz-held-out-unruled-artifact.xyz'])
    try:
        out_path = os.path.join(d, 'inv.sexp')
        code, out = inventory_on(d, out_path)
        return code != 0 and 'UNCLASSIFIED' in out and 'zz-held-out-unruled-artifact.xyz' in out, out.strip()
    finally:
        shutil.rmtree(d, ignore_errors=True)


def f03_missing_inventory_path():
    return _seat_check('inventory', _inventory_seat_mutation(
        _drop_line(lambda l: l.startswith('(fact file ') and 'deployment/collab/dialogue/' in l)),
        'MULTISET-MISMATCH')


def f05_duplicate_inventory_key():
    def t(b):
        for l in b.splitlines():
            if l.startswith('(fact file '):
                return b.replace(l + '\n', l + '\n' + l + '\n', 1)
        return b
    return _seat_check('inventory', _inventory_seat_mutation(t), 'DUPLICATE-INVENTORY-KEY')


def f06_c_quoted_path():
    def t(b):
        for l in b.splitlines():
            if l.startswith('(fact file ') and 'LAWMAX-OMEGA-CANON/GR/' in l:
                start = l.index('"'); end = l.index('"', start + 1)
                path = l[start + 1:end]
                cq = '\\"' + ''.join(ch if ord(ch) < 128 else ''.join('\\\\%03o' % byte
                                                                   for byte in ch.encode('utf-8'))
                                     for ch in path) + '\\"'
                return b.replace(l, l[:start + 1] + cq + l[end:], 1)
        return b
    return _seat_check('inventory', _inventory_seat_mutation(t), 'C-QUOTED-INVENTORY-KEY')


def f08_multiline_fact_not_lost():
    """A benign multi-line fact must survive both readers: no silent omission, identical commitments."""
    okb, base = baseline_totals()
    if not okb:
        return False, 'the unmutated model does not pass both paths'
    d = model_copy()
    try:
        path = os.path.join(d, 'rationale-references.sexp')
        text = open(path, encoding='utf-8').read()
        line = [l for l in text.splitlines() if l.startswith('(fact rationale ')][0]
        parts = line[:-1].split(' :')
        spread = parts[0] + '\n' + '\n'.join('    :' + x for x in parts[1:]) + ')'
        open(path, 'w', encoding='utf-8', newline='\n').write(text.replace(line, spread, 1))
        rehash(d)
        kc, ko = kernel(d)
        cc, co = checker(d)
        n = [l for l in ko.splitlines() if l.startswith('COMMITMENT total-facts ')]
        got = int(n[0].split()[-1]) if n else -1
        if kc != 0 or cc != 0:
            return False, 'a benign multi-line fact was rejected (kernel %d, checker %d)' % (kc, cc)
        if got != base:
            return False, 'the fact count changed from %d to %d — a fact was lost or duplicated' % (base, got)
        return True, ''
    finally:
        shutil.rmtree(d, ignore_errors=True)


def f09_multiline_private_leak():
    def mut(d):
        path = os.path.join(d, 'interfaces-and-types.sexp')
        priv = [l for l in open(path, encoding='utf-8') if l.startswith('(fact type ') and ':classification PRIVATE' in l][0]
        pid = priv.split()[2]
        append(d, 'dependencies-and-boundaries.sexp',
               '(fact consumes S12__HELDOUTLEAK\n    :consumer S12\n    :provides %s)' % pid)
    return both_reject(mut, 'public/private leak', 'L5')


def f10_new_pinned_module_consumed():
    """A module newly pinned in ROOT must be consumed by BOTH paths, not silently ignored by one."""
    d = model_copy()
    try:
        extra = 'held-out-extra.sexp'
        open(os.path.join(d, extra), 'w', encoding='utf-8', newline='\n').write(
            ';;;; held-out module\n(fact rationale HELD-OUT-EXTRA :doc "held-out" :anchor "held-out")\n')
        t = open(os.path.join(d, 'ROOT.sexp'), encoding='utf-8').read()
        t = t.replace('  :module-count %d' % len(modules()), '  :module-count %d' % (len(modules()) + 1))
        t = t.replace('  :composition (\n', '  :composition (\n    (:module "%s" :sha256 "%s")\n' % (extra, '0' * 64))
        open(os.path.join(d, 'ROOT.sexp'), 'w', encoding='utf-8', newline='\n').write(t)
        rehash(d, order=[extra] + modules())
        kc, ko = kernel(d)
        cc, co = checker(d)
        if kc != 0 or cc != 0:
            return False, 'the extended model was rejected (kernel %d, checker %d): %s' % (kc, cc, co.strip()[-200:])
        kcom = open(os.path.join(d, 'KERNEL-COMMITMENT.txt'), encoding='utf-8').read()
        ccom = open(os.path.join(d, 'CHECKER-COMMITMENT.txt'), encoding='utf-8').read()
        if extra not in kcom or extra not in ccom:
            return False, 'a newly pinned module is absent from a published commitment'
        return kcom == ccom, 'the two commitments differ'
    finally:
        shutil.rmtree(d, ignore_errors=True)


def f11_fact_count_mismatch():
    return _kernel_then_mutate(lambda d: append(d, 'rationale-references.sexp',
                                                '(fact rationale HELD-OUT-EXTRA :doc "x" :anchor "y")'))


def f12_family_digest_mismatch():
    def mutate(d):
        path = os.path.join(d, 'rationale-references.sexp')
        t = open(path, encoding='utf-8').read()
        line = [l for l in t.splitlines() if l.startswith('(fact rationale ')][0]
        open(path, 'w', encoding='utf-8', newline='\n').write(
            t.replace(line, line[:-1].rsplit(':anchor', 1)[0] + ':anchor "held-out-changed")', 1))
    return _kernel_then_mutate(mutate)


def f16_root_digest_changed_alone():
    def mut(d):
        import re
        path = os.path.join(d, 'ROOT.sexp')
        t = open(path, encoding='utf-8').read()
        cur = re.search(r':canonical-model-root-digest "([0-9a-f]{64})"', t).group(1)
        new = ('0' if cur[0] != '0' else '1') + cur[1:]
        open(path, 'w', encoding='utf-8', newline='\n').write(t.replace(cur, new, 1))
    return both_reject(mut, 'canonical-model-root-digest mismatch', 'canonical-model-root-digest',
                       rehash_after=False)


def f17_duplicate_ledger_row():
    d, am = cp_copy()
    try:
        path = os.path.join(am, 'deferred-imports.sexp')
        t = open(path, encoding='utf-8').read()
        line = [l for l in t.splitlines() if l.startswith('(fact source-class ')][0]
        open(path, 'w', encoding='utf-8', newline='\n').write(t.replace(line, line + '\n' + line, 1))
        code, out = run_verify(am)
        return code != 0 and 'DUPLICATE-LEDGER-ROW' in out, out.strip().splitlines()[:2]
    finally:
        shutil.rmtree(d, ignore_errors=True)


def f18_missing_source_file():
    d, am = cp_copy()
    try:
        os.remove(os.path.join(d, CP_REL, 'V1.7-SCHEMAS.sexp'))
        code, out = run_verify(am)
        return code == 5 and 'MISSING-SOURCE-FILE' in out and 'V1.7-SCHEMAS.sexp' in out, out.strip().splitlines()[:2]
    finally:
        shutil.rmtree(d, ignore_errors=True)


def f19_restore_instead_of_compare():
    """The gate must never erase a difference before it is compared, and must never write the tree it audits."""
    bad = []
    for fn in ('ARCHITECTURE-MODEL-GATE.sh', 'gate_checks.py', 'build_inventory.py', 'run_corpus.py'):
        path = os.path.join(HERE, fn)
        if not os.path.isfile(path):
            continue
        for line in open(path, encoding='utf-8').read().splitlines():
            body = line.strip()
            if body.startswith(('#', '//', ';')) or 'git checkout' not in body:
                continue
            if fn == 'run_corpus.py':                   # the composed battery works inside its own clone
                continue
            bad.append('%s: %s' % (fn, body))
    if bad:
        return False, 'a restore-before-compare survives: %s' % bad
    # and positively: a hand-edited generated artifact ALREADY IN THE CANDIDATE TREE must be NAMED, not
    # regenerated away before anything compares it. The tamper therefore lives in the tree under judgement.
    d, seat = export_seat()
    try:
        tampered = (seat_text(seat, 'GENERATED/OWNERSHIP-MATRIX.md') + '\nMANUAL TAMPER\n').encode('utf-8')
    finally:
        shutil.rmtree(d, ignore_errors=True)
    return _tree_check('generation', {seat_path('GENERATED/OWNERSHIP-MATRIX.md'): tampered}, 'ARTIFACT-DRIFT')


def f20_packet_undercount():
    d, seat = export_seat()
    try:
        text = seat_text(seat, 'ROOT-OPERATOR-DECISION-PACKET.md')
    finally:
        shutil.rmtree(d, ignore_errors=True)
    line = [l for l in text.splitlines() if l.startswith('total-facts ')][0]
    tampered = text.replace(line, 'total-facts %d' % (int(line.split()[1]) - 1), 1)
    return _tree_check('packet', {seat_path('ROOT-OPERATOR-DECISION-PACKET.md'): tampered.encode('utf-8')},
                       'PACKET-MISMATCH')


def f21_no_self_certified_pass():
    """Neither path may issue a verdict on its own: without the other's commitment there is no verdict."""
    d = model_copy()
    try:
        kernel(d)
        os.remove(os.path.join(d, 'KERNEL-COMMITMENT.txt'))
        cc, co = checker(d)
        return cc != 0 and 'COMMITMENT-UNAVAILABLE' in co, co.strip().splitlines()[:2]
    finally:
        shutil.rmtree(d, ignore_errors=True)


def f24_crlf_text_decoded_hash():
    """Pinning with the abandoned text-decoded definition must not survive raw-byte verification."""
    d = model_copy()
    try:
        path = os.path.join(d, 'rationale-references.sexp')
        with open(path, 'rb') as f:
            raw = f.read()
        with open(path, 'wb') as f:
            f.write(raw.replace(b'\n', b'\r\n'))

        def text_decoded(p):                                  # the definition this correction abandoned
            with open(p, encoding='utf-8', errors='replace') as fh:
                return hashlib.sha256(fh.read().encode('utf-8')).hexdigest()
        rehash(d, digest_fn=text_decoded)
        kc, ko = kernel(d)
        cc, co = checker(d)
        return kc != 0 and 'SHA drift' in ko and cc != 0, (ko.strip().splitlines()[-3:-2] or [''])
    finally:
        shutil.rmtree(d, ignore_errors=True)


def f25_hash_provider_unavailable():
    """No provider, no verdict. The kernel must refuse rather than fall back to anything of its own."""
    d = model_copy()
    try:
        path = os.path.join(d, 'TOOLCHAIN.sexp')
        t = open(path, encoding='utf-8').read()
        line = [l for l in t.splitlines() if l.strip().startswith(':path "') and '/sha256sum' in l][0]
        open(path, 'w', encoding='utf-8', newline='\n').write(
            t.replace(line, line.replace('/sha256sum', '/no-such-digest-program'), 1))
        # NOT rehashed: the point is that the kernel dies at provider acquisition, before any hashing at all
        kc, ko = kernel(d)
        return (kc == 4 and 'TOOLCHAIN-FAILURE' in ko and 'UNAVAILABLE' in ko
                and 'ARCHITECTURE MODEL LAWS' not in ko), ko.strip().splitlines()[:2]
    finally:
        shutil.rmtree(d, ignore_errors=True)


def f26_dead_classification_rule():
    """A rule that can never fire is a build failure, not merely unused."""
    d = index_repo()
    try:
        BI = importlib.util.module_from_spec(_bspec_fresh())
        BI.__spec__.loader.exec_module(BI)
        BI.ROOT = d
        BI.RULES = list(BI.RULES) + [('R-999', lambda p: p == 'this/path/is/never/tracked', 'PRODUCTION_CODE',
                                      'a rule that cannot fire')]
        import contextlib, io
        buf = io.StringIO(); argv = sys.argv
        sys.argv = ['build_inventory.py', '--out', os.path.join(d, 'inv.sexp')]
        code = 0
        try:
            with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
                BI.main()
        except SystemExit as e:
            code = e.code or 0
        finally:
            sys.argv = argv
        return code == 3 and 'DEAD RULE' in buf.getvalue() and 'R-999' in buf.getvalue(), buf.getvalue().strip()
    finally:
        shutil.rmtree(d, ignore_errors=True)


def f30_unrecorded_normalization():
    d, seat = export_seat()
    try:
        text = seat_text(seat, 'MODEL-MIGRATION-CONFLICT-LEDGER.md')
    finally:
        shutil.rmtree(d, ignore_errors=True)
    line = [l for l in text.splitlines() if l.startswith('|') and 'NON-SUBSYSTEM-CONSUMER' in l][0]
    tampered = text.replace(line + '\n', '', 1)
    return _tree_check('conflict-ledger', {seat_path('MODEL-MIGRATION-CONFLICT-LEDGER.md'):
                                           tampered.encode('utf-8')}, 'UNRECORDED-NORMALIZATION')


def f31_historical_code_on_live_path():
    """A real HISTORICAL_EVIDENCE program copied into the governance seat and called from a live builder.

    Review-2 N-13: the earlier probe only added a basename string, which the earlier basename tripwire happened
    to see. The corrected check computes the real transitive execution closure, so the falsifier now performs
    the actual reintroduction: the historical file is placed in the seat and genuinely invoked."""
    d, seat = export_seat()
    try:
        hist = [str(f[2]) for f in SR.read_forms_file(os.path.join(seat, 'files-and-roles.sexp'))
                if SR.head(f) == 'fact' and str(f[1]) == 'file'
                and str(SR.kv(f, 'role') or '') == 'HISTORICAL_EVIDENCE' and str(f[2]).endswith('.py')]
        if not hist:
            return False, 'the model classifies no executable HISTORICAL_EVIDENCE file to reintroduce'
        victim = sorted(hist)[0]
        body = open(os.path.join(REPO, victim), 'rb').read()
        name = os.path.basename(victim)
        builder = seat_text(seat, 'build_root.py')
    finally:
        shutil.rmtree(d, ignore_errors=True)
    call = ('\n\ndef held_out_reintroduction():\n'
            '    import subprocess, sys\n'
            '    subprocess.run([PY, %r])\n' % name)
    return _tree_check('dependency-closure',
                       {seat_path(name): body, seat_path('build_root.py'): (builder + call).encode('utf-8')},
                       'HISTORICAL-CODE-IN-CLOSURE')


def f32_module_count_mismatch():
    def mut(d):
        path = os.path.join(d, 'ROOT.sexp')
        t = open(path, encoding='utf-8').read()
        open(path, 'w', encoding='utf-8', newline='\n').write(
            t.replace('  :module-count %d' % len(modules()), '  :module-count %d' % (len(modules()) - 1), 1))
    return both_reject(mut, 'module-count', 'module-count', rehash_after=False)


def f33_unknown_fact_field():
    return both_reject(_probe_seat('(fact seat SEAT-PROBE-X33 :status BUILT :path "CLAUDE.md" :note "probe" '
                                   ':unexpected-key FOO)'),
                       'is not a declared field', 'UNDECLARED-FIELD')


def f34_misspelled_optional_field():
    return both_reject(_probe_seat('(fact seat SEAT-PROBE-X34 :status DESIGN_TARGET :rationale RAT-ONE-SEAT '
                                   ':packett WP-01 :note "probe")'),
                       'is not a declared field', 'UNDECLARED-FIELD')


def f35_wrong_value_type():
    return both_reject(_probe_seat('(fact seat SEAT-PROBE-X35 :status BUILT :path "CLAUDE.md" :note 42)'),
                       'must be string, found integer', 'WRONG-VALUE-KIND')


def f44_global_promotion_overclaim():
    def mut(seat):
        p = os.path.join(seat, 'deferred-imports.sexp')
        t = open(p, encoding='utf-8').read()
        open(p, 'w', encoding='utf-8', newline='\n').write(
            t.replace(':scope GLOBAL :state FORBIDDEN_UNTIL_DDI_COMPLETE', ':scope GLOBAL :state PERMITTED', 1))
        AR.bounded_run([PY, os.path.join(seat, 'build_root.py')], capture_output=True, cwd=seat)
    return _seat_check('packet', mut, 'GLOBAL-PROMOTION-OVERCLAIM')


def disposable_repo():
    """A disposable git repository whose HEAD commit IS the candidate tree, byte for byte.

    Not a plain clone: a clone carries the last COMMIT, and the candidate under judgement is the tree that
    WOULD be committed, which is not the same thing while a correction is in flight.

    And not `git init` + `git add`, either — that was wrong in a way worth recording, because it made two of
    these falsifiers vacuous. `git add` obeys .gitignore, so ignored-but-tracked paths (here: the whole 29,204
    file `output/` subtree) vanished, and it applies .gitattributes text normalisation, so CRLF blobs changed.
    The reconstructed repository was missing four fifths of the tree, its gate failed for that reason alone,
    and a falsifier that merely requires the gate to fail would have "passed" with no defect injected at all.

    The tree object is therefore installed directly: the index is read from it, the working tree is written
    from the index, and a commit is made over that exact tree. Nothing re-derives what git already knows, and
    the path count is asserted against the tree before any falsifier runs.
    """
    tree = candidate()[0]
    d = tempfile.mkdtemp(prefix='gfals-repo-')
    root = os.path.join(d, 'repo')
    AR.checked(['git', 'init', '-q', root], capture_output=True)
    # Borrow the source repository's object store read-only. A plain local clone copies only REACHABLE
    # objects, and the candidate tree is deliberately unreferenced, so it would not come across.
    with open(os.path.join(root, '.git', 'objects', 'info', 'alternates'), 'w', encoding='utf-8') as f:
        f.write(AR.git_object_dir(REPO) + '\n')
    for args in (['read-tree', tree], ['checkout-index', '-a', '-f']):
        AR.checked(['git', '-C', root] + args, capture_output=True)
    commit = AR.checked(['git', '-C', root] + IDENT + ['commit-tree', tree, '-m',
                                                           'candidate tree under audit'],
                            capture_output=True, text=True).stdout.strip()
    AR.checked(['git', '-C', root, 'reset', '--hard', '-q', commit], capture_output=True)
    n = len(AR.checked(['git', '-C', root, 'ls-files', '-z']).stdout.split(b'\0')) - 1
    m = len(AR.checked(['git', '-C', REPO, 'ls-tree', '-r', '--name-only', '-z', tree]).stdout.split(b'\0')) - 1
    if n != m:
        raise RuntimeError('the disposable repository holds %d paths, the candidate tree %d — a falsifier over '
                           'an incomplete copy would prove nothing' % (n, m))
    return d, root


def run_gate(root, env=None):
    seat = os.path.join(root, REL)
    # --checks is the gate's model-check phase. The full phase runs THIS battery, so a composed falsifier that
    # invoked it would recurse forever; the phase argument is what makes that structurally impossible.
    #
    # AML_* must NOT cross into the inner gate. They name the OUTER repository and the OUTER candidate tree, and
    # when the full phase exported them every composed falsifier made its inner gate judge the unmutated outer
    # tree instead of the disposable repository it had just injected a defect into — eight falsifiers reporting
    # NOT REJECTED for a defect that was never actually put in front of the check. The inner gate resolves its
    # own repository and its own worktree candidate, which is the only thing a composed falsifier proves.
    clean = {k: v for k, v in (env or os.environ).items() if not k.startswith('AML_')}
    r = AR.bounded_run(['bash', os.path.join(seat, GATE), '--checks'], capture_output=True, text=True, cwd=seat,
                       env=clean)
    return r.returncode, r.stdout + r.stderr


def seat_file(root, rel):
    return os.path.join(root, REL, rel)


def repo_seat_text(root, rel):
    with open(seat_file(root, rel), encoding='utf-8') as f:
        return f.read()


def repo_seat_write(root, rel, text):
    with open(seat_file(root, rel), 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)


def gate_must_fail(root, check, reason=None, env=None):
    """The gate must FAIL, and the NAMED check must be the one that failed."""
    code, out = run_gate(root, env)
    if code == 0:
        return False, 'the composed gate PASSED: %s' % [l for l in out.splitlines()
                                                        if l.startswith('### ARCHITECTURE MODEL LAWS')][:1]
    if 'GATE %s: FAIL' % check not in out:
        failed = [l.split(':')[0].replace('GATE ', '') for l in out.splitlines() if l.endswith(': FAIL')]
        return False, 'the gate failed, but not through %s (failed: %s)' % (check, failed or 'nothing named')
    if reason and reason not in out:
        return False, '%s failed, but never named %r' % (check, reason)
    return True, ''


def control_unmutated():
    """The precondition without which this whole battery would be worthless.

    Every falsifier below asserts "the gate FAILS when this defect is present". That statement means nothing
    unless the gate PASSES when no defect is present: a disposable repository that is broken in some unrelated
    way makes the gate fail for its own reasons and every falsifier "passes" having injected nothing. This is
    not hypothetical — an earlier reconstruction of this repository silently dropped every ignored-but-tracked
    path, and two falsifiers passed vacuously because of it. So the control runs first, and a failure here
    aborts the battery instead of being reported as eight successes.
    """
    d, root = disposable_repo()
    try:
        code, out = run_gate(root)
        if code != 0:
            failed = [l.split(':')[0].replace('GATE ', '') for l in out.splitlines() if l.endswith(': FAIL')]
            return False, 'the gate FAILS on an unmutated copy (%s); every falsifier below would pass ' \
                          'vacuously' % (failed or 'no named check')
        return True, ''
    finally:
        shutil.rmtree(d, ignore_errors=True)


def local_text(rel):
    with open(os.path.join(HERE, rel), encoding='utf-8') as f:
        return f.read()


def g01_gate_writes_to_tree():
    """A gate that writes to the tree it audits must not be able to report PASS."""
    d, root = disposable_repo()
    try:
        gate = repo_seat_text(root, GATE)
        marker = 'export AML_CANDIDATE_TREE="$TREE"'
        if marker not in gate:
            return False, 'the gate no longer pins the candidate; this falsifier cannot be placed'
        repo_seat_write(root, GATE, gate.replace(
            marker, marker + '\nprintf "\\n<!-- the gate wrote here -->\\n" >> GENERATED/OWNERSHIP-MATRIX.md', 1))
        return gate_must_fail(root, 'ro-01-repository-content-identical-after-the-run')
    finally:
        shutil.rmtree(d, ignore_errors=True)


def g02_pre_existing_drift_erased():
    """The exact Review-2 N-2 regression: a hand-edited generated artifact ALREADY in the candidate must be
    NAMED, not regenerated away before anything compares it. The superseded gate reported pass=20 fail=0."""
    d, root = disposable_repo()
    try:
        repo_seat_write(root, 'GENERATED/OWNERSHIP-MATRIX.md',
              repo_seat_text(root, 'GENERATED/OWNERSHIP-MATRIX.md') + '\n<!-- hand-edited after generation -->\n')
        return gate_must_fail(root, 'gen-02-artifacts-regenerate-byte-identical', 'ARTIFACT-DRIFT')
    finally:
        shutil.rmtree(d, ignore_errors=True)


def g03_artifact_deleted():
    """A declared generated artifact deleted from the tree — the superseded gate enumerated no members."""
    d, root = disposable_repo()
    try:
        os.remove(seat_file(root, 'GENERATED/DEPENDENCY-VIEW.md'))
        AR.checked(['git', '-C', root, 'add', '-A'], capture_output=True)
        return gate_must_fail(root, 'art-01-generated-artifact-universe-is-exact', 'GENERATED-ARTIFACT-MISSING')
    finally:
        shutil.rmtree(d, ignore_errors=True)


def g04_artifact_undeclared():
    """An extra artifact produced into the generated seat that the model declares nowhere."""
    d, root = disposable_repo()
    try:
        repo_seat_write(root, 'GENERATED/UNDECLARED-EXTRA-VIEW.md',
              '# GENERATED — DO NOT EDIT\n\nAn artifact the model declares nowhere.\n')
        AR.checked(['git', '-C', root, 'add', '-A'], capture_output=True)
        return gate_must_fail(root, 'art-01-generated-artifact-universe-is-exact',
                              'GENERATED-ARTIFACT-UNDECLARED')
    finally:
        shutil.rmtree(d, ignore_errors=True)


def g05_corpus_shrunk():
    """A held-out falsifier removed from the declared corpus. The superseded gate reported the smaller number
    as a success: `31 ... not-rejected=0` with the complete gate at pass=20 fail=0."""
    d, root = disposable_repo()
    try:
        corpus = repo_seat_text(root, 'verification-corpus.sexp')
        line = [l for l in corpus.splitlines() if l.startswith('(fact falsifier X32-')][0]
        repo_seat_write(root, 'verification-corpus.sexp', corpus.replace(line + '\n', '', 1))
        return gate_must_fail(root, 'cor-01-corpus-universe-is-exact', 'FALSIFIER-UNDECLARED')
    finally:
        shutil.rmtree(d, ignore_errors=True)


def g06_toolchain_identity():
    """A tool whose executable identity is not the pinned one. Nothing may be verified by an unpinned tool."""
    d, root = disposable_repo()
    try:
        # only the 64 hex digits change: the module must stay well-formed, or the gate would reject it as
        # unreadable and prove nothing about identity enforcement
        tc = repo_seat_text(root, 'TOOLCHAIN.sexp')
        mutated, n = re.subn(r'(:sha256 ")[0-9a-f]{64}(")', r'\g<1>' + '0' * 64 + r'\g<2>', tc, count=1)
        if n != 1:
            return False, 'no pinned :sha256 to repoint'
        repo_seat_write(root, 'TOOLCHAIN.sexp', mutated)
        return gate_must_fail(root, 'tch-01-pinned-tools-are-the-tools-executed', 'TOOLCHAIN-IDENTITY-MISMATCH')
    finally:
        shutil.rmtree(d, ignore_errors=True)


def g07_unadjudicated_source():
    """A migration source that qualifies for the ledger by the model's own classification rule, present in the
    tree and consistent with the inventory, but absent from the deferred-import ledger."""
    d, root = disposable_repo()
    try:
        # a file the classification rule admits as a migration source, carrying REAL source forms — an empty
        # one would contribute no (file, class) pair and the ledger would be right to say nothing about it
        cp = os.path.dirname(os.path.join(root, REL))
        shutil.copyfile(os.path.join(cp, 'V1.7-SCHEMAS.sexp'), os.path.join(cp, 'V9.9-SCHEMAS.sexp'))
        AR.checked(['git', '-C', root, 'add', '-A'], capture_output=True)
        # make the model internally consistent about the new file, and leave ONLY the ledger stale
        seat = os.path.join(root, REL)
        for producer in ('build_inventory.py', 'build_root.py', 'generate_views.py',
                         'build_decision_packet.py'):
            # CLOSURE-BOUND: gen-step.producer
            r = AR.bounded_run([PY, producer], cwd=seat, capture_output=True, text=True)
            if r.returncode != 0:
                return False, 'the reproducer could not be prepared: %s exited %d' % (producer, r.returncode)
        AR.checked(['git', '-C', root, 'add', '-A'], capture_output=True)
        return gate_must_fail(root, 'led-01-deferred-ledger-exact-source-universe', 'DEFERRED-IMPORT LEDGER: FAIL')
    finally:
        shutil.rmtree(d, ignore_errors=True)


def g08_tmp_collision():
    """A hostile pre-existing path at every scratch location the SUPERSEDED gate used.

    The corrected gate takes a private mode-0700 workspace from mktemp and holds no fixed path, so a defect must
    still be detected with all of those paths occupied by directories it cannot write. Both halves are asserted:
    no fixed scratch literal survives in the gate's own source, and detection is unaffected in practice.
    """
    gate_src = local_text(GATE)
    literals = [p for p in LEGACY_SCRATCH if p in gate_src]
    if literals:
        return False, 'the gate still names fixed scratch paths: %s' % literals
    made = []
    try:
        for p in LEGACY_SCRATCH:
            if not os.path.exists(p):
                os.makedirs(p, mode=0o500)
                made.append(p)
        d, root = disposable_repo()
        try:
            repo_seat_write(root, 'GENERATED/OWNERSHIP-MATRIX.md',
                  repo_seat_text(root, 'GENERATED/OWNERSHIP-MATRIX.md') + '\n<!-- hand-edited after generation -->\n')
            return gate_must_fail(root, 'gen-02-artifacts-regenerate-byte-identical', 'ARTIFACT-DRIFT')
        finally:
            shutil.rmtree(d, ignore_errors=True)
    finally:
        for p in made:                      # only what this run created; a pre-existing path is left alone
            try:
                os.rmdir(p)
            except OSError:
                pass

CODED_COMPONENT = [
    ('K01-GENERATED-VIEW-MISSING', 'a tracked generated view absent from the inventory', f01_generated_view_missing),
    ('K02-NEW-FILE-NO-RULE', 'a new tracked file matching no classification rule', f02_new_tracked_file_no_rule),
    ('K03-MISSING-INVENTORY-PATH', 'a tracked path missing from the inventory', f03_missing_inventory_path),
    ('K05-DUPLICATE-INVENTORY-KEY', 'the same path classified twice', f05_duplicate_inventory_key),
    ('K06-C-QUOTED-PATH', 'a non-ASCII path written as C-quoted text', f06_c_quoted_path),
    ('K08-MULTILINE-FACT-KEPT', 'a benign multi-line fact silently omitted', f08_multiline_fact_not_lost),
    ('K09-MULTILINE-PRIVATE-LEAK', 'a public/private leak written across lines', f09_multiline_private_leak),
    ('K10-NEW-PINNED-MODULE', 'a newly pinned module ignored by one path', f10_new_pinned_module_consumed),
    ('K11-FACT-COUNT-MISMATCH', 'the two paths consuming different fact counts', f11_fact_count_mismatch),
    ('K12-FAMILY-DIGEST-MISMATCH', 'equal counts but a different per-family digest', f12_family_digest_mismatch),
    ('K16-ROOT-DIGEST-ALONE', 'the root digest changed without changing any pin', f16_root_digest_changed_alone),
    ('K17-DUPLICATE-LEDGER-ROW', 'a duplicated deferred-ledger row', f17_duplicate_ledger_row),
    ('K18-MISSING-SOURCE-FILE', 'an absent migration source file', f18_missing_source_file),
    ('K20-PACKET-UNDERCOUNT', 'a decision-packet total the model does not support', f20_packet_undercount),
    ('K21-SELF-CERTIFIED-PASS', 'a verdict issued without the other path present', f21_no_self_certified_pass),
    ('K24-CRLF-TEXT-HASHING', 'pins computed with text-decoded hashing', f24_crlf_text_decoded_hash),
    ('K25-PROVIDER-UNAVAILABLE', 'the vetted hash provider unavailable', f25_hash_provider_unavailable),
    ('X26-DEAD-RULE', 'a classification rule that can never fire', f26_dead_classification_rule),
    ('X30-UNRECORDED-NORMALIZATION', 'a migration normalization with no ledger row', f30_unrecorded_normalization),
    ('X31-HISTORICAL-ON-LIVE-PATH', 'historical code made a live dependency', f31_historical_code_on_live_path),
    ('X32-MODULE-COUNT-MISMATCH', 'a module count ROOT does not actually pin', f32_module_count_mismatch),
    ('X33-UNKNOWN-FACT-FIELD', 'a field no fact type declares', f33_unknown_fact_field),
    ('X34-MISSPELLED-OPTIONAL-FIELD', 'a misspelled optional field with no downstream law', f34_misspelled_optional_field),
    ('X35-WRONG-VALUE-TYPE', 'a declared field carrying the wrong value kind', f35_wrong_value_type),
    ('X44-GLOBAL-PROMOTION-OVERCLAIM', 'global source-of-truth claimed while classes remain deferred', f44_global_promotion_overclaim),]
COMPOSED = [
    ('G01-GATE-WRITES-TO-TREE', 'the validation gate modifying the tree it audits', g01_gate_writes_to_tree),
    ('G02-PRE-EXISTING-DRIFT-ERASED', 'pre-existing drift regenerated away before comparison',
     g02_pre_existing_drift_erased),
    ('G03-ARTIFACT-DELETED', 'a declared generated artifact deleted from generator and tree', g03_artifact_deleted),
    ('G04-ARTIFACT-UNDECLARED', 'an undeclared artifact produced into the seat', g04_artifact_undeclared),
    ('G05-CORPUS-SHRUNK', 'a fixture, property family or falsifier silently removed', g05_corpus_shrunk),
    ('G06-TOOLCHAIN-IDENTITY', 'a tool whose executable identity is not the pinned one', g06_toolchain_identity),
    ('G07-UNADJUDICATED-SOURCE', 'a qualifying migration source absent from the ledger', g07_unadjudicated_source),
    ('G08-TMP-COLLISION', 'a hostile pre-existing path at a gate scratch location', g08_tmp_collision),]

# ═══════════════════════════════════════════════════════════════════════ the declared universe, then the cases
def universe_integrity():
    """Missing, extra, duplicate or coherently deleted — each a named failure before a single case runs."""
    bad, seen, floors, auths, nfals = [], {}, {}, set(), 0
    fx, fam = corpus()
    for ftype, fid, p, _f in read_facts(HERE, 'verification-corpus.sexp'):
        if (ftype, fid) in seen:
            bad.append('DUPLICATE-CORPUS-ID: %s %s is declared twice' % (ftype, fid))
        seen[(ftype, fid)] = True
        if ftype == 'universe-floor':
            floors[p['family']] = (fid, int(p['minimum']))
        elif ftype == 'universe-authorization':
            auths.add(p['family'])
        elif ftype == 'falsifier':
            nfals += 1
    counts = {'FIXTURE': len(fx), 'PROPERTY-FAMILY': len(fam), 'FALSIFIER': nfals}
    for fam_name, (fid, low) in sorted(floors.items()):
        if fam_name in counts and counts[fam_name] < low and fam_name not in auths:
            bad.append('UNIVERSE-BELOW-FLOOR: family %s holds %d, floor %d (%s), and no universe-authorization '
                       'records the reduction' % (fam_name, counts[fam_name], low, fid))
    present = set()
    for sub in ('PASS', 'FAIL'):
        d = os.path.join(HERE, 'FIXTURES', sub)
        if os.path.isdir(d):
            present |= {'FIXTURES/%s/%s' % (sub, f) for f in os.listdir(d) if f.endswith('.sexp')}
    declared_paths = {p['path'] for p in fx.values()}
    bad += ['FIXTURE-FILE-MISSING: the corpus declares %s but no such file exists' % p
            for p in sorted(declared_paths - present)]
    bad += ['FIXTURE-FILE-UNDECLARED: %s exists but the corpus declares no fixture for it' % p
            for p in sorted(present - declared_paths)]
    declared = {i: p for t, i, p, _f in read_facts(HERE, 'verification-corpus.sexp') if t == 'falsifier'}
    coded = {n for n, _i, _fn in CODED_COMPONENT} | {n for n, _i, _fn in COMPOSED}
    datad = {i for i, p in declared.items() if p.get('mutation')}
    bad += ['FALSIFIER-NOT-IMPLEMENTED: %s is declared but neither coded nor given a mutation' % i
            for i in sorted(set(declared) - coded - datad)]
    bad += ['FALSIFIER-UNDECLARED: %s is implemented but the model declares no such falsifier' % i
            for i in sorted((coded | datad) - set(declared))]
    return bad


def fixtures_kind(work):
    global MODULES
    MODULES = root_modules(HERE)
    fx, fam = corpus()
    n = ng = np = 0
    for fid in sorted(fx):
        spec = fx[fid]
        forms = SR.read_forms_file(os.path.join(HERE, spec['path']))
        decl = [f for f in forms if SR.head(f) == 'fixture']
        if len(decl) != 1 or len(forms) != 1:
            FAILURES.append('%s: %s must hold exactly one fixture form' % (fid, spec['path'])); continue
        if SR.canonical_value(decl[0][1], spec['path'], 'id') != fid:
            FAILURES.append('%s: %s declares a different fixture id' % (fid, spec['path'])); continue
        n += 1; ng += 1
        check(fid, spec['expect'], spec['law'], spec['reason'], SR.kv(decl[0], 'mutate'), work, n)
    for fid in sorted(fam):
        spec = fam[fid]
        cases = family_cases(fid, spec)
        want = int(spec['cardinality'])
        if len(cases) != want:
            FAILURES.append('PROPERTY-FAMILY-CARDINALITY: %s declares %d cases, the model yields %d — a family '
                            'that silently changed size is a failure, not a smaller number' % (fid, want, len(cases)))
            continue
        for label, mut in cases:
            n += 1; np += 1
            check('%s/%s' % (fid, label), 'FAIL', spec['law'], spec['reason'], mut, work, n)
    print('golden fixtures=%d  generated properties=%d  failures=%d' % (ng, np, len(FAILURES)))
    for f in FAILURES:
        print('  FAIL:', f)
    if ng == 0 or np == 0:
        print('  FAIL: a run that executes no fixture or no property case is not a pass')
        return 1
    return 1 if FAILURES else 0


def falsifier_kind(harness, only=None):
    declared = dict(declared_falsifiers(harness))
    cases = list(CODED_COMPONENT if harness == 'COMPONENT' else COMPOSED)
    cases += [(fid, p['intent'], (lambda sp: lambda: data_driven(sp))(p)) for fid, p in sorted(declared.items())]
    if only:
        want = {x.strip().upper() for x in only.split(',')}
        cases = [c for c in cases if c[0].upper() in want]
    if harness == 'COMPOSED_GATE':
        okc, why = control_unmutated()
        print('%-34s %-52s %s' % ('CONTROL-UNMUTATED-GATE-PASSES', 'the gate passes when no defect is injected',
                                  'CONTROL HOLDS' if okc else 'CONTROL BROKEN - ' + why))
        if not okc:
            print('held-out falsifiers=0 rejected-as-intended=0 not-rejected=0 BATTERY-VACUOUS')
            return 2
    for name, intent, fn in sorted(cases):
        run_one(name, intent, fn)
    bad = [r for r in RESULTS if not r[2]]
    print('held-out falsifiers=%d rejected-as-intended=%d not-rejected=%d'
          % (len(RESULTS), len(RESULTS) - len(bad), len(bad)))
    for r in bad:
        print('  NOT REJECTED: %s — %s — %s' % (r[0], r[1], r[3]))
    return 1 if bad else 0


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--kind', choices=('fixtures', 'component', 'composed'), required=True)
    ap.add_argument('--work', default=None)
    ap.add_argument('--keep-work', action='store_true')
    ap.add_argument('--only', default=None, help='run only these falsifier ids, comma separated')
    a = ap.parse_args()
    problems = universe_integrity()
    if problems:
        for p in problems:
            print('  UNIVERSE:', p)
        print('corpus universe integrity: FAIL (%d finding(s)) — no case was run' % len(problems))
        sys.exit(1)
    work = AR.workspace('aml-corpus-', REPO, keep=a.keep_work, reuse=a.work)
    sys.exit(fixtures_kind(work) if a.kind == 'fixtures'
             else falsifier_kind('COMPONENT' if a.kind == 'component' else 'COMPOSED_GATE', a.only))
