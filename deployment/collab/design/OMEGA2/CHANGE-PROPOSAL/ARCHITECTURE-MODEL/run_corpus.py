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
import argparse, ast, contextlib, hashlib, importlib.util, io, os, re, shutil, signal, subprocess, sys, tempfile, time

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
BASE = None                    # the base every history-bound check is judged against — DERIVED by the candidate
                               # step from what was named; a --base only confirms it (Review-4 R4-1, Review-5 R5-2)
CANDIDATE = 'WORKTREE'         # what is judged: a commit-ish, or WORKTREE; never a bare tree


PY = SR.tool_path(HERE, 'CHECKER_RUNTIME')
SBCL = SR.tool_path(HERE, 'KERNEL_RUNTIME')


def read_model(source=HERE, **kw):
    """The ONE seat of this program that reads a model, and the only place SR.read_model is called.

    Every failure the READER declares becomes the model's own typed outcome — the same vocabulary
    gate_checks.model() speaks — so no entry point of this program can end in a Python traceback over an
    unreadable or absent canonical module (Review-6 R6-2 error totality). Only the reader's DECLARED failures
    are converted: SR.SexpError is the base of every typed reader failure, and anything outside it is a
    programming fault that must keep its traceback. There is no `except Exception` here, by design.
    """
    try:
        return SR.read_model(source, **kw)
    except SR.MissingSourceFile as e:
        raise SystemExit('MISSING-MODEL-FILE: %s' % e.path)
    except SR.SexpError as e:
        raise SystemExit('UNREADABLE-MODEL-FILE: %s' % e)



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
    return read_model(dirp, cache=False).modules


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
    """The declared fixtures and property families — discovered by fact type across the whole model."""
    m = read_model()
    return dict(m.of('fixture')), dict(m.of('property-family'))


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
    kept, dropped = [], []
    for form in SR.read_forms_file(path):
        if SR.head(form) == 'fact' and str(form[1]).lower() == ftype.lower():
            if field is None:
                match = SR.canonical_value(form[2], module, 'id') == fid
            else:
                v = SR.kv(form, field)
                match = v is not None and SR.canonical_value(v, module, field) == fid
            if match:
                dropped.append(form)
                continue
        kept.append(form)
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(emit(x) for x in kept) + '\n')
    return dropped                      # the removed forms, so a caller can RELOCATE them structurally


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
    """(tree, exported seat rel) for the immutable candidate — resolved once by the one seat that derives the
    candidate AND its base from what was named (Review-5 R5-2). The derived base is this battery's BASE; a
    --base given on the command line was only confirmed by that step."""
    global BASE
    if not _CAND:
        cmd = [PY, os.path.join(HERE, 'gate_checks.py'), 'candidate', '--candidate', CANDIDATE]
        r = AR.bounded_run(cmd + (['--base', BASE] if BASE else []), capture_output=True, text=True, cwd=HERE)
        got = dict(l.split(' ', 1) for l in r.stdout.splitlines() if l.startswith(('CANDIDATE-', 'BASE-')))
        if r.returncode != 0 or 'CANDIDATE-TREE' not in got or 'BASE-COMMIT' not in got:
            print('  CANDIDATE-UNRESOLVED: no case can run against an unresolved candidate:')
            for l in (r.stdout + r.stderr).strip().splitlines()[-3:]:
                print('  ' + l[:200])
            sys.exit(1)
        _CAND.update(tree=got['CANDIDATE-TREE'], commit=got['CANDIDATE-COMMIT'], base=got['BASE-COMMIT'],
                     base_root=got['BASE-MODEL-ROOT'],
                     rel=os.path.relpath(HERE, LAYOUT_ROOT).replace(os.sep, '/'))
        BASE = _CAND['base']
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
    dig = SR.root_digest(rows)
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


def seat_run(which, mutate, base=None, env=None, cand=None):
    """(exit code, output) of a REAL gate check over a deliberately mutated export of the immutable candidate
    seat, judged as candidate CAND (default: this battery's candidate identity) against BASE (default: the
    derived base). The check re-derives the base from the candidate identity itself; the base passed here only
    confirms it, exactly as on the command line."""
    tree, _rel = candidate()
    d, seat = export_seat()
    work = tempfile.mkdtemp(prefix='fals-work-')
    try:
        mutate(seat)
        r = AR.bounded_run([PY, os.path.join(HERE, 'gate_checks.py'), which, '--candidate', cand or CANDIDATE,
                            '--tree', tree, '--work', work, '--seat', seat, '--base', base or BASE],
                           capture_output=True, text=True, cwd=HERE, env=env)
        return r.returncode, r.stdout + r.stderr
    finally:
        shutil.rmtree(d, ignore_errors=True)
        shutil.rmtree(work, ignore_errors=True)


def _seat_check(which, mutate, needle, expect='FAIL', base=None, env=None, cand=None):
    """Run a REAL gate check against a deliberately mutated export of the immutable candidate seat.

    The check logic is the gate's own; only the source of the model differs, so a falsifier proves the deployed
    check catches the defect rather than proving a re-implementation of it does. A positive control (EXPECT
    PASS) proves the guard accepts the legitimate case, without which every FAIL it reports would be vacuous.
    Review-4 R4-2: a traceback in the output is a failure of the case whatever the exit code says."""
    code, out = seat_run(which, mutate, base, env, cand)
    return verdict(code, out, needle, expect)


def verdict(code, out, needle, expect='FAIL'):
    """The one reading of a check's outcome: typed reason named, no traceback, expected exit direction."""
    if 'Traceback (most recent call last)' in out:
        return False, 'a traceback escaped: %s' % [l for l in out.splitlines() if l.strip()][-1:]
    if expect == 'PASS':
        return (code == 0 and needle in out), ('the check did not pass: %s' % out.strip().splitlines()[-1:])
    if code == 0:
        return False, 'the check passed: %s' % out.strip().splitlines()[-1:]
    if needle not in out:
        return False, 'rejected for another reason: %s' % [l.strip() for l in out.splitlines()
                                                           if l.startswith('  ')][:2]
    return True, ''


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


def synthetic_commit(tree, parents, env, message='held-out synthetic commit'):
    """A commit over TREE with exactly PARENTS, written into the throwaway object store ENV names — the
    repository under audit gains no object and no ref. A bare tree is no candidate (Review-5 R5-2), so a falsifier
    that puts a defect into a tree presents it as the commit that tree would be."""
    args = ['commit-tree', tree] + [x for par in parents for x in ('-p', par)] + ['-m', message]
    return AR.checked(['git', '-C', REPO] + IDENT + args, env=env, capture_output=True, text=True).stdout.strip()


def _tree_check(which, changes, needle):
    """Put a defect into the CANDIDATE TREE ITSELF and require the real gate check to name it."""
    _tree, _rel = candidate()
    tree, env, d = tree_with(changes)
    work = tempfile.mkdtemp(prefix='fals-work-')
    try:
        cand = synthetic_commit(tree, [BASE], env)
        r = AR.bounded_run([PY, os.path.join(HERE, 'gate_checks.py'), which, '--candidate', cand, '--tree', tree,
                            '--work', work, '--base', BASE], capture_output=True, text=True, cwd=HERE, env=env)
        return verdict(r.returncode, r.stdout + r.stderr, needle)
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


def expand(text, seat=''):
    if '{BASE-ROOT}' in str(text):
        candidate()
    return (str(text).replace('{NL}', '\n').replace('{Q}', '"').replace('{BS}', '\\')
            .replace('{BASE-ROOT}', _CAND.get('base_root', '')).replace('{SEAT}', seat))


def declared_falsifiers(harness):
    """Every falsifier the MODEL declares with a mutation, for one harness — the runner carries the shapes,
    the model carries the cases."""
    return sorted((fid, p) for fid, p in read_model().of('falsifier')
                  if p.get('harness') == harness and p.get('mutation'))


def apply_ops(dirp, module, spec, prefix=''):
    """Apply, in order, the declared DROP, REPLACE and APPEND operations of one falsifier row to MODULE in DIRP.

    One engine for every copy a falsifier mutates — the model copy the two verifiers judge, the exported seat a
    single check judges, the synthetic base, the disposable repository the whole gate judges. DROP removes whole
    facts structurally ("type id; type id"), so a removal can never leave a half-deleted form behind."""
    path, changed, moved = os.path.join(dirp, module), False, []
    for item in [x.strip() for x in str(spec.get(prefix + 'drop', '')).split(';') if x.strip()]:
        ftype, fid = item.split()
        moved += remove_fact(dirp, module, ftype, fid)
        changed = True
    if prefix + 'relocate-to' in spec:
        # RELOCATE: the dropped facts are appended, unchanged, to another canonical module — the Review-5 shape:
        # a fact that moved between modules must be discovered where it went, never lost with its old file
        if not moved:
            raise RuntimeError('the declared :%srelocate-to moves nothing: no fact was dropped' % prefix)
        with open(os.path.join(dirp, str(spec[prefix + 'relocate-to'])), 'a', encoding='utf-8', newline='\n') as fh:
            fh.write('\n' + '\n'.join(emit(f) for f in moved) + '\n')
    text = open(path, encoding='utf-8').read()
    if prefix + 'replace-from' in spec:
        new = text.replace(expand(spec[prefix + 'replace-from'], dirp), expand(spec[prefix + 'replace-to'], dirp), 1)
        if new == text:
            raise RuntimeError('the declared :%sreplace-from does not occur in %s' % (prefix, module))
        text, changed = new, True
    if prefix + 'form' in spec:
        target = str(spec.get(prefix + 'form-module', module))     # the module the form is appended to
        if target == module:
            text = text + '\n' + expand(spec[prefix + 'form'], dirp) + '\n'
        else:
            with open(os.path.join(dirp, target), 'a', encoding='utf-8', newline='\n') as fh:
                fh.write('\n' + expand(spec[prefix + 'form'], dirp) + '\n')
        changed = True
    if not changed:
        raise RuntimeError('the declared %smutation changed nothing in %s' % (prefix, module))
    open(path, 'w', encoding='utf-8', newline='\n').write(text)


def data_driven(spec):
    """Run one model-declared mutation and require the intended named outcome."""
    kind, mod = spec['mutation'], spec.get('module')
    needle, expect = expand(spec.get('reason', '')), str(spec.get('expect', 'FAIL'))
    if kind == 'CHECK' and any(k.startswith('base-') for k in spec):
        return _base_check(spec['check'].lower(), spec, needle, expect)
    if kind == 'CHECK':
        return _seat_check(spec['check'].lower(), lambda seat: apply_ops(seat, mod, spec), needle, expect)
    if kind == 'GATE':
        # the defect goes into a disposable repository and is made COHERENT — the derived artifacts regenerated
        # exactly as a careful attacker would — so that the named check, and not artifact drift, is what fails
        d, root = disposable_repo()
        try:
            seat = os.path.join(root, REL)
            apply_ops(seat, mod, spec)
            AR.checked([PY, os.path.join(seat, 'regenerate.py')], cwd=seat, capture_output=True)
            AR.checked(['git', '-C', root, 'add', '-A'], capture_output=True)
            return gate_must_fail(root, str(spec['check']).lower(), needle)
        finally:
            shutil.rmtree(d, ignore_errors=True)
    return both_reject(lambda d: apply_ops(d, mod, spec), expand(spec['kernel-reason']),
                       expand(spec['checker-reason']), rehash_after=spec.get('rehash', 'YES') == 'YES')


def _base_check(which, spec, needle, expect):
    """Exercise a base-anchored authorization: a SYNTHETIC BASE is committed on top of the real base — the
    candidate's own module with the row's :base-* edits — and the check judges the mutated export against it.

    The synthetic commit lives in a throwaway object store that reads the repository's objects through the
    alternates mechanism, so the repository under audit gains no object and no ref. The check sees it because
    the same object-directory environment is handed to it explicitly."""
    tree, rel = candidate()
    scratch = model_copy()
    try:
        # the synthetic base is a COHERENT model: every module it changed is re-pinned and its root digest
        # recomputed, because the historical loader verifies a base against its own root (Review-5 R5-1)
        apply_ops(scratch, str(spec.get('base-module', spec['module'])), spec, prefix='base-')
        rehash(scratch)
        changes = {}
        for name in modules() + ['ROOT.sexp']:
            with open(os.path.join(scratch, name), 'rb') as fh:
                data = fh.read()
            with open(os.path.join(HERE, name), 'rb') as fh:
                if fh.read() != data:
                    changes['%s/%s' % (rel, name)] = data
        base_tree, env, odb = tree_with(changes)
        try:
            synthetic_base = synthetic_commit(base_tree, [BASE], env, 'synthetic base for a held-out case')
            # the candidate under judgement is the COMMIT the candidate tree would be on top of that base, so the
            # check derives the base from the candidate's own parentage — nothing is chosen for it
            synthetic_cand = synthetic_commit(tree, [synthetic_base], env, 'candidate over a synthetic base')
            return _seat_check(which, lambda st: apply_ops(st, spec['module'], spec), needle, expect,
                               base=synthetic_base, env=env, cand=synthetic_cand)
        finally:
            shutil.rmtree(odb, ignore_errors=True)
    finally:
        shutil.rmtree(scratch, ignore_errors=True)


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
        if not remove_fact(d, str(mut[1]), str(mut[2]), str(mut[3]), field):
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
    commit = AR.checked(['git', '-C', root] + IDENT + ['commit-tree', tree, '-p', BASE, '-m',
                                                           'candidate tree under audit'],
                            capture_output=True, text=True).stdout.strip()
    AR.checked(['git', '-C', root, 'reset', '--hard', '-q', commit], capture_output=True)
    n = len(AR.checked(['git', '-C', root, 'ls-files', '-z']).stdout.split(b'\0')) - 1
    m = len(AR.checked(['git', '-C', REPO, 'ls-tree', '-r', '--name-only', '-z', tree]).stdout.split(b'\0')) - 1
    if n != m:
        raise RuntimeError('the disposable repository holds %d paths, the candidate tree %d — a falsifier over '
                           'an incomplete copy would prove nothing' % (n, m))
    return d, root


def run_gate(root, env=None, base=None):
    seat = os.path.join(root, REL)
    # --checks is the gate's model-check phase. The full phase runs THIS battery, so a composed falsifier that
    # invoked it would recurse forever; the phase argument is what makes that structurally impossible.
    #
    # AML_* must NOT cross into the inner gate. They name the OUTER repository and the OUTER candidate tree, and
    # when the full phase exported them every composed falsifier made its inner gate judge the unmutated outer
    # tree instead of the disposable repository it had just injected a defect into — eight falsifiers reporting
    # NOT REJECTED for a defect that was never actually put in front of the check. The inner gate resolves its
    # own repository and its own worktree candidate, which is the only thing a composed falsifier proves.
    # The inner gate DERIVES its base from its own repository (Review-5 R5-2): a clean checkout of the disposable
    # HEAD is judged against that HEAD's parent (the real base), a mutated working tree against the disposable
    # HEAD itself. A base is passed only where the caller knows it is the derived one, as a confirmation.
    clean = {k: v for k, v in (env or os.environ).items() if not k.startswith('AML_')}
    r = AR.bounded_run(['bash', os.path.join(seat, GATE), '--checks'] + (['--base=' + base] if base else []),
                       capture_output=True, text=True, cwd=seat, env=clean)
    return r.returncode, r.stdout + r.stderr


def seat_file(root, rel):
    return os.path.join(root, REL, rel)


def repo_seat_text(root, rel):
    with open(seat_file(root, rel), encoding='utf-8') as f:
        return f.read()


def repo_seat_write(root, rel, text):
    with open(seat_file(root, rel), 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)


def gate_must_fail(root, check, reason=None, env=None, base=None):
    """The gate must FAIL, and the NAMED check must be the one that failed."""
    code, out = run_gate(root, env, base)
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
        code, out = run_gate(root, base=BASE)          # clean checkout: derived base = HEAD's parent = BASE
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
        marker = 'export AML_CANDIDATE="$CANDID" AML_CANDIDATE_TREE="$TREE"'
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

def f73_tool_vanishes_before_spawn():
    """Review-4 R4-2. The execution seat must turn a spawn failure into a typed refusal: an executable that passes
    the pre-check and is gone by the time of the spawn (the race, made deterministic here), and a regular file
    that is not executable at all. Neither may surface as a traceback."""
    d = tempfile.mkdtemp(prefix='fals-spawn-')
    try:
        tool = os.path.join(d, 'tool')
        with open(tool, 'w') as fh:
            fh.write('#!/bin/sh\nexit 0\n')
        os.chmod(tool, 0o755)
        if AR.tool_defect(tool):
            return False, 'the pre-check rejected a valid executable'
        os.remove(tool)
        try:
            AR.bounded_run([tool], timeout=30)
            return False, 'no typed failure for a tool that vanished before the spawn'
        except AR.ToolUnavailable as e:
            if e.reason != 'TOOLCHAIN-MISSING':
                return False, 'vanished tool reported %s' % e.reason
        flat = os.path.join(d, 'flat')
        with open(flat, 'w') as fh:
            fh.write('not a program\n')
        try:
            AR.bounded_run([flat], timeout=30)
            return False, 'no typed failure for a non-executable regular file'
        except AR.ToolUnavailable as e:
            return e.reason == 'TOOLCHAIN-UNEXECUTABLE', str(e)
    finally:
        shutil.rmtree(d, ignore_errors=True)


def group_alive(pgid):
    """Processes still in process group PGID, read from /proc so the harness needs no extra binary."""
    alive = []
    for pid in os.listdir('/proc'):
        if pid.isdigit():
            try:
                with open('/proc/%s/stat' % pid) as fh:
                    if int(fh.read().rsplit(')', 1)[1].split()[2]) == pgid:
                        alive.append(int(pid))
            except (OSError, ValueError, IndexError):
                continue
    return alive


def g11_signal_cleans_only_its_own():
    """Review-4 R4-3. Two concurrent acceptance runs on the same disposable repository, each with its own scratch
    root. SIGTERM goes to ONE of them. That one must leave no workspace of its own and no process in its group;
    the other must finish with its normal verdict; the repository content must be byte-identical throughout.
    Nothing here promises anything for SIGKILL, which no process can handle."""
    d, root = disposable_repo()
    seat = os.path.join(root, REL)
    clean = {k: v for k, v in os.environ.items() if not k.startswith('AML_')}
    tmps = [tempfile.mkdtemp(prefix='fals-sig-') for _ in range(2)]
    procs = []

    def state():
        return AR.checked([PY, os.path.join(seat, 'gate_checks.py'), 'content-state'], cwd=seat, env=clean,
                          text=True).stdout
    try:
        before = state()
        for t in tmps:
            procs.append(subprocess.Popen(['bash', os.path.join(seat, GATE), '--checks', '--base=' + BASE],
                                          cwd=seat, env=dict(clean, TMPDIR=t), stdout=subprocess.DEVNULL,
                                          stderr=subprocess.DEVNULL, start_new_session=True))
        deadline = time.time() + 600
        while time.time() < deadline and not all(os.listdir(t) for t in tmps):
            time.sleep(1)
        if not all(os.listdir(t) for t in tmps):
            return False, 'the two runs never opened their workspaces'
        time.sleep(20)                                   # let both be inside a child check, not between two
        os.killpg(procs[0].pid, signal.SIGTERM)
        try:
            procs[0].wait(timeout=600)
        except subprocess.TimeoutExpired:
            return False, 'the signalled run did not exit'
        time.sleep(3)
        left, orphans = os.listdir(tmps[0]), group_alive(procs[0].pid)
        procs[1].wait(timeout=AR.DEFAULT_TIMEOUT * 3)
        after = state()
        if left:
            return False, 'the signalled run left %s in its own scratch root' % left
        if orphans:
            return False, 'orphans survive in the signalled process group: %s' % orphans
        if procs[1].returncode != 0:
            return False, 'the concurrent run was disturbed (exit %d)' % procs[1].returncode
        if not os.listdir(tmps[1]) == []:
            return False, 'the concurrent run left %s behind' % os.listdir(tmps[1])
        if before != after:
            return False, 'the repository content changed during the runs'
        return True, ''
    finally:
        for pr in procs:
            if pr.poll() is None:
                os.killpg(pr.pid, signal.SIGKILL)
        for t in tmps:
            shutil.rmtree(t, ignore_errors=True)
        shutil.rmtree(d, ignore_errors=True)


# ═══════════════════════════════════════ Review-5: candidate/base derivation and whole-model discovery — the cases
# that need a process, a repository or a history rather than a model mutation
def throwaway_odb():
    """(env, dir) of a throwaway object store that reads the repository's objects through alternates: synthetic
    commits are written there, and the repository under audit gains no object and no ref."""
    d = tempfile.mkdtemp(prefix='fals-odb-')
    env = dict(os.environ, GIT_OBJECT_DIRECTORY=os.path.join(d, 'objects'),
               GIT_ALTERNATE_OBJECT_DIRECTORIES=AR.git_object_dir(REPO))
    os.makedirs(env['GIT_OBJECT_DIRECTORY'])
    return env, d


def clean_env(extra=None):
    """An environment in which the inner seat resolves its OWN repository: no AML_* crosses in."""
    env = {k: v for k, v in os.environ.items() if not k.startswith('AML_')}
    env.update(extra or {})
    return env


def candidate_step(args, env=None, cwd=None):
    """(exit code, output, the CANDIDATE-/BASE- lines) of the REAL candidate step, run from CWD's seat."""
    work = tempfile.mkdtemp(prefix='fals-work-')
    try:
        r = AR.bounded_run([PY, os.path.join(cwd or HERE, 'gate_checks.py'), 'candidate', '--work', work] + args,
                           capture_output=True, text=True, cwd=cwd or HERE, env=env)
    finally:
        shutil.rmtree(work, ignore_errors=True)
    out = r.stdout + r.stderr
    return r.returncode, out, dict(l.split(' ', 1) for l in out.splitlines() if l.startswith(('CANDIDATE-', 'BASE-')))


def x79_candidate_tree_is_tree_not_commit():
    """A commit-ish candidate resolves to the TREE it carries, never to the commit's own id (Review-5 §5.4)."""
    tree, _rel = candidate()
    env, d = throwaway_odb()
    try:
        c = synthetic_commit(tree, [BASE], env)
        code, out, got = candidate_step(['--candidate', c], env=env)
        if code != 0:
            return False, 'the candidate step failed: %s' % out.strip().splitlines()[-1:]
        if got.get('CANDIDATE-TREE') != tree or got.get('CANDIDATE-COMMIT') != c:
            return False, 'commit %s resolved to tree %s / commit %s; expected tree %s' \
                          % (c[:12], got.get('CANDIDATE-TREE', '')[:12], got.get('CANDIDATE-COMMIT', '')[:12], tree[:12])
        return True, ''
    finally:
        shutil.rmtree(d, ignore_errors=True)


def x80_worktree_arbitrary_base_refused():
    """An arbitrary --base for a WORKTREE candidate — an unrelated history — is refused by name (R5-2)."""
    tree, _rel = candidate()
    env, d = throwaway_odb()
    try:
        wrong = synthetic_commit(tree, [], env, 'an unrelated history')
        code, out, _got = candidate_step(['--candidate', 'WORKTREE', '--base', wrong], env=env)
        return verdict(code, out, 'UNIVERSE-BASE-MISMATCH')
    finally:
        shutil.rmtree(d, ignore_errors=True)


def x81_commit_base_not_parent_refused():
    """A committed candidate with a --base other than its unique parent is refused by name (R5-2)."""
    tree, _rel = candidate()
    env, d = throwaway_odb()
    try:
        c, wrong = synthetic_commit(tree, [BASE], env), synthetic_commit(tree, [], env, 'not the parent')
        code, out, _got = candidate_step(['--candidate', c, '--base', wrong], env=env)
        return verdict(code, out, 'UNIVERSE-BASE-MISMATCH')
    finally:
        shutil.rmtree(d, ignore_errors=True)


def x82_merge_candidate_refused():
    """A merge commit has no single history: refused with and without an explicit base (R5-2)."""
    tree, _rel = candidate()
    env, d = throwaway_odb()
    try:
        other = synthetic_commit(tree, [], env, 'the other side')
        m = synthetic_commit(tree, [BASE, other], env, 'a merge')
        code, out, _got = candidate_step(['--candidate', m], env=env)
        okk, why = verdict(code, out, 'UNIVERSE-BASE-AMBIGUOUS')
        if not okk:
            return False, why
        code, out, _got = candidate_step(['--candidate', m, '--base', BASE], env=env)
        okk, why = verdict(code, out, 'UNIVERSE-BASE-AMBIGUOUS')
        return okk, ('' if okk else 'with an explicit base: ' + why)
    finally:
        shutil.rmtree(d, ignore_errors=True)


def x83_orphan_candidate_refused():
    """A zero-parent candidate has no history to be judged against (R5-2)."""
    tree, _rel = candidate()
    env, d = throwaway_odb()
    try:
        o = synthetic_commit(tree, [], env, 'an orphan')
        code, out, _got = candidate_step(['--candidate', o], env=env)
        return verdict(code, out, 'UNIVERSE-BASE-ORPHAN')
    finally:
        shutil.rmtree(d, ignore_errors=True)


def x84_worktree_differs_base_is_head():
    """A working tree that differs from HEAD is the candidate, and HEAD is its base (R5-2)."""
    d, root = disposable_repo()
    try:
        head = AR.checked(['git', '-C', root, 'rev-parse', 'HEAD'], capture_output=True, text=True).stdout.strip()
        head_tree = AR.checked(['git', '-C', root, 'rev-parse', 'HEAD^{tree}'], capture_output=True, text=True).stdout.strip()
        with open(seat_file(root, 'PACKET-TEMPLATE.md'), 'a', encoding='utf-8', newline='\n') as fh:
            fh.write('\n<!-- held-out working-tree change -->\n')
        code, out, got = candidate_step(['--candidate', 'WORKTREE'], env=clean_env(), cwd=os.path.join(root, REL))
        if code != 0:
            return False, 'the candidate step failed: %s' % out.strip().splitlines()[-1:]
        if got.get('CANDIDATE-COMMIT') != 'WORKTREE' or got.get('BASE-COMMIT') != head or got.get('CANDIDATE-TREE') == head_tree:
            return False, 'candidate %s tree %s base %s; expected WORKTREE, a tree other than HEAD\'s, base HEAD %s' \
                          % (got.get('CANDIDATE-COMMIT'), got.get('CANDIDATE-TREE', '')[:12], got.get('BASE-COMMIT', '')[:12], head[:12])
        return True, ''
    finally:
        shutil.rmtree(d, ignore_errors=True)


def x85_worktree_equals_head_base_is_parent():
    """A working tree equal to HEAD's tree IS HEAD, and HEAD's unique parent is its base (R5-2)."""
    tree, _rel = candidate()
    d, root = disposable_repo()
    try:
        head = AR.checked(['git', '-C', root, 'rev-parse', 'HEAD'], capture_output=True, text=True).stdout.strip()
        code, out, got = candidate_step(['--candidate', 'WORKTREE'], env=clean_env(), cwd=os.path.join(root, REL))
        if code != 0:
            return False, 'the candidate step failed: %s' % out.strip().splitlines()[-1:]
        if got.get('CANDIDATE-COMMIT') != head or got.get('BASE-COMMIT') != BASE or got.get('CANDIDATE-TREE') != tree:
            return False, 'candidate %s base %s; expected HEAD %s with base %s' \
                          % (got.get('CANDIDATE-COMMIT', '')[:12], got.get('BASE-COMMIT', '')[:12], head[:12], BASE[:12])
        return True, ''
    finally:
        shutil.rmtree(d, ignore_errors=True)


def x86_shallow_clone_base_missing_then_fetched():
    """In a depth-1 clone the base object is absent: a typed refusal naming exactly the object to fetch; after
    a bounded fetch of exactly that object the same step passes (R5-2)."""
    d, root = disposable_repo()
    sh = tempfile.mkdtemp(prefix='fals-shallow-')
    try:
        AR.checked(['git', '-C', root, 'config', 'uploadpack.allowReachableSHA1InWant', 'true'], capture_output=True)
        repo = os.path.join(sh, 'repo')
        AR.checked(['git', 'clone', '-q', '--depth=1', 'file://' + root, repo], capture_output=True, timeout=900)
        seat = os.path.join(repo, REL)
        code, out, _got = candidate_step(['--candidate', 'HEAD'], env=clean_env(), cwd=seat)
        okk, why = verdict(code, out, 'UNIVERSE-BASE-OBJECT-MISSING')
        if not okk:
            return False, 'before the fetch: ' + why
        if BASE not in out or 'git fetch --depth=1' not in out:
            return False, 'the refusal does not name the exact object and the bounded fetch that brings it'
        AR.checked(['git', '-C', repo, 'fetch', '-q', '--depth=1', 'origin', BASE], capture_output=True, timeout=900)
        code, out, got = candidate_step(['--candidate', 'HEAD'], env=clean_env(), cwd=seat)
        if code != 0 or got.get('BASE-COMMIT') != BASE:
            return False, 'after fetching exactly %s: %s' % (BASE[:12], out.strip().splitlines()[-1:])
        return True, ''
    finally:
        shutil.rmtree(d, ignore_errors=True)
        shutil.rmtree(sh, ignore_errors=True)


def x87_floors_reported_separately():
    """uni-01 reports the base's floors and the candidate's floors as two lines, and they differ when the
    candidate floors one more family (Review-5 §5.1). Every existing floor is tight, so the difference is a new
    floor rather than a raised one."""
    def add_floor(seat):
        with open(os.path.join(seat, 'verification-corpus.sexp'), 'a', encoding='utf-8', newline='\n') as fh:
            fh.write('\n(fact universe-floor UF-HARNESS :family harness :minimum 2 :rationale "held-out")\n')
    code, out = seat_run('universe', add_floor)
    if code != 0 or 'Traceback' in out:
        return False, 'adding a floor was refused: %s' % out.strip().splitlines()[-1:]
    lines = dict(l.split(' ', 1) for l in out.splitlines() if l.startswith('UNIVERSE-'))
    b, c = lines.get('UNIVERSE-BASE-FLOORS', ''), lines.get('UNIVERSE-CANDIDATE-FLOORS', '')
    if not b or not c:
        return False, 'base and candidate floors are not reported as separate lines'
    if 'harness>=2' in b or 'harness>=2' not in c or b == c:
        return False, 'base %r / candidate %r do not show the added floor separately' % (b, c)
    if lines.get('UNIVERSE-REDUCTIONS') != 'none' or lines.get('UNIVERSE-AUTHORIZATIONS-CONSUMED') != 'none':
        return False, 'reductions / consumed authorizations are not reported: %r' % lines
    return True, ''


def relocate_facts(dirp, src, dst, ftype):
    """Move every fact of FTYPE from module SRC to module DST, structurally and unchanged."""
    forms = SR.read_forms_file(os.path.join(dirp, src))
    moved = [f for f in forms if SR.head(f) == 'fact' and str(f[1]).lower() == ftype]
    kept = [f for f in forms if not (SR.head(f) == 'fact' and str(f[1]).lower() == ftype)]
    with open(os.path.join(dirp, src), 'w', encoding='utf-8', newline='\n') as fh:
        fh.write('\n'.join(emit(x) for x in kept) + '\n')
    with open(os.path.join(dirp, dst), 'a', encoding='utf-8', newline='\n') as fh:
        fh.write('\n' + '\n'.join(emit(x) for x in moved) + '\n')
    return len(moved)


def g12_two_commit_relocation_then_shrink():
    """Review-5 R5-1 C1 -> C2 through the REAL command. C1 relocates every floor to another canonical module,
    values unchanged — legal, and the single history-bound check passes against the candidate. C2, on top of
    C1, deletes five floors and shrinks the corpus coherently. Judged edge by edge, C2 against C1, the whole
    checks phase must fail through uni-01: the floors are discovered where C1 put them."""
    d, root = disposable_repo()
    seat = os.path.join(root, REL)
    try:
        def commit(msg):
            AR.checked(['git', '-C', root, 'add', '-A'], capture_output=True)
            AR.checked(['git', '-C', root] + IDENT + ['commit', '-q', '-m', msg], capture_output=True)
        if relocate_facts(seat, 'verification-corpus.sexp', 'seats.sexp', 'universe-floor') < 7:
            return False, 'fewer than seven floors were found to relocate'
        AR.checked([PY, os.path.join(seat, 'regenerate.py')], cwd=seat, capture_output=True)
        commit('C1: relocate the universe floors, values unchanged')
        work = tempfile.mkdtemp(prefix='fals-work-')
        try:
            r = AR.bounded_run([PY, os.path.join(seat, 'gate_checks.py'), 'universe', '--candidate', 'HEAD',
                                '--work', work], capture_output=True, text=True, cwd=seat, env=clean_env())
        finally:
            shutil.rmtree(work, ignore_errors=True)
        okk, why = verdict(r.returncode, r.stdout + r.stderr, 'GATECHECK universe: PASS', 'PASS')
        if not okk:
            return False, 'C1 (relocation, values unchanged) must pass and did not: ' + why
        for fid in ('UF-FIXTURE', 'UF-PROPERTY-FAMILY', 'UF-FALSIFIER', 'UF-GEN-ARTIFACT', 'UF-SEAT'):
            if not remove_fact(seat, 'seats.sexp', 'universe-floor', fid):
                return False, '%s was not found where C1 relocated it' % fid
        remove_fact(seat, 'verification-corpus.sexp', 'property-family', 'PF-L4-STAGE-CYCLE')
        remove_fact(seat, 'verification-corpus.sexp', 'falsifier', 'X69-FLOOR-SET-WEAKENED')
        AR.checked([PY, os.path.join(seat, 'regenerate.py')], cwd=seat, capture_output=True)
        commit('C2: delete five floors and shrink the corpus coherently')
        return gate_must_fail(root, 'uni-01-no-declared-family-below-its-floor', 'UNIVERSE-FLOOR-REDUCED')
    finally:
        shutil.rmtree(d, ignore_errors=True)


# ═══════════════════════════════════════ Review-6 R6-1: the derived lifecycle of an authorization, edge by edge
# A reduction costs two commits: one that introduces a well-formed prospective authorization, one that consumes
# it. A removal (:minimum 0) leaves behind a record that no longer names a live floor, and these cases pin down
# exactly what that record may and may not do afterwards. Every case builds a REAL chain of commits in a
# throwaway object store and judges the last edge with the deployed check, so nothing here re-implements it; a
# history cannot be expressed as a corpus row, which is why they are coded rather than data.
AUTH_ROW = ('(fact universe-authorization %s :family %s :previous-minimum %d :minimum %d :previous-model-root "%s" '
            ':rationale "held-out lifecycle case" :approver "held-out authority")')


def _corpus_text():
    with open(os.path.join(HERE, 'verification-corpus.sexp'), encoding='utf-8') as fh:
        return fh.read()


def _auth(fid, fam, prev, new):
    """A well-formed record for a held-out chain. Its :previous-model-root is the CANDIDATE's own model root:
    every chain is grown from the candidate as a commit, so that is the root the first edge is judged against
    and, one edge later, the root of the base's parent the consumption is checked against."""
    return AUTH_ROW % (fid, fam, prev, new, str(read_model().root['canonical-model-root-digest']))


def _edge(env, rel, edits, parent):
    """One committed edge: the candidate's modules with EDITS {module: text}, re-pinned exactly as build_root.py
    would, committed over PARENT in the caller's throwaway object store."""
    m = model_copy()
    try:
        for name, text in edits.items():
            with open(os.path.join(m, name), 'w', encoding='utf-8', newline='\n') as fh:
                fh.write(text)
        rehash(m)

        def g(args, **kw):
            return AR.checked(['git', '-C', REPO] + args, env=env, capture_output=True, **kw)

        g(['read-tree', _CAND['tree']])
        for name in modules() + ['ROOT.sexp']:
            with open(os.path.join(m, name), 'rb') as fh:
                data = fh.read()
            with open(os.path.join(HERE, name), 'rb') as fh:
                if fh.read() == data:
                    continue
            blob = g(['hash-object', '-w', '--stdin'], input=data).stdout.decode().strip()
            g(['update-index', '--add', '--cacheinfo', '100644,%s,%s/%s' % (blob, rel, name)])
        return synthetic_commit(g(['write-tree']).stdout.decode().strip(), [parent], env, 'held-out lifecycle edge')
    finally:
        shutil.rmtree(m, ignore_errors=True)


def lifecycle(steps, expect, needle, check='universe'):
    """Judge the LAST of a chain of edges, each committed over the one before, the first over the candidate
    itself — the same edge-by-edge discipline the command uses."""
    _tree, rel = candidate()
    env, d = throwaway_odb()
    # the chain's edges are candidates of their own: the acceptance command exports AML_CANDIDATE and
    # AML_CANDIDATE_TREE for ITS candidate, and an inherited tree hint would make every edge a
    # CANDIDATE-TREE-MISMATCH. AML_REPO stays: the seat still resolves the real repository through it.
    env = {k: v for k, v in env.items() if k not in ('AML_CANDIDATE', 'AML_CANDIDATE_TREE')}
    env = dict(env, GIT_INDEX_FILE=os.path.join(d, 'index'))
    try:
        parent = synthetic_commit(_CAND['tree'], [BASE], env, 'the candidate itself, as a commit')
        for text in steps:
            parent = _edge(env, rel, {'verification-corpus.sexp': text}, parent)
        work = tempfile.mkdtemp(prefix='fals-work-')
        try:
            r = AR.bounded_run([PY, os.path.join(HERE, 'gate_checks.py'), check, '--candidate', parent,
                                '--work', work], capture_output=True, text=True, cwd=HERE, env=env)
        finally:
            shutil.rmtree(work, ignore_errors=True)
        return verdict(r.returncode, r.stdout + r.stderr, needle, expect)
    finally:
        shutil.rmtree(d, ignore_errors=True)


def _removal_chain():
    """The two edges of a LEGITIMATE authorised removal: one that introduces the prospective records, one that
    consumes them by deleting the floor and lowering the self-floor the deletion costs."""
    base = _corpus_text()
    e1 = (base + '\n' + _auth('UA-HELD-OUT-REMOVAL', 'property-family', 5, 0) + '\n'
          + _auth('UA-HELD-OUT-SELF', 'universe-floor', 7, 6) + '\n')
    e2 = (re.sub(r'\(fact universe-floor UF-PROPERTY-FAMILY[^)]*\)\n?', '', e1)
          .replace(':family universe-floor :minimum 7', ':family universe-floor :minimum 6'))
    return e1, e2


def x116_prospective_removal_control():
    """A prospective authorization for a full removal reduces nothing on the edge that introduces it."""
    return lifecycle([_removal_chain()[0]], 'PASS', 'UNIVERSE-AUTHORIZATIONS-PROSPECTIVE UA-HELD-OUT-REMOVAL')


def x117_authorised_removal_control():
    """The next edge removes the floor and lowers the self-floor, consuming both records exactly."""
    return lifecycle(list(_removal_chain()), 'PASS', 'UNIVERSE-AUTHORIZATIONS-CONSUMED UA-HELD-OUT-REMOVAL')


def x118_spent_noop_edge_control():
    """A no-op edge after an authorised removal passes: a terminally spent record is historical evidence, not a
    permanent refusal of every later edge."""
    e1, e2 = _removal_chain()
    return lifecycle([e1, e2, e2], 'PASS', 'UNIVERSE-AUTHORIZATIONS-TERMINALLY-SPENT UA-HELD-OUT-REMOVAL')


def x119_spent_second_noop_control():
    """And the edge after that, so the state is a state and not a one-off exemption."""
    e1, e2 = _removal_chain()
    return lifecycle([e1, e2, e2, e2], 'PASS', 'GATECHECK universe: PASS')


def x120_spent_record_removed():
    """Dropping the spent record is still tampering with the record of who authorised what."""
    e1, e2 = _removal_chain()
    return lifecycle([e1, e2, re.sub(r'\(fact universe-authorization UA-HELD-OUT-REMOVAL[^)]*\)\n?', '', e2)],
                     'FAIL', 'AUTHORIZATION-TAMPERED')


def x121_spent_record_altered():
    """Nor may its content be edited once it is history."""
    e1, e2 = _removal_chain()
    e3 = e2.replace('UA-HELD-OUT-REMOVAL :family property-family :previous-minimum 5 :minimum 0',
                    'UA-HELD-OUT-REMOVAL :family property-family :previous-minimum 5 :minimum 1', 1)
    return lifecycle([e1, e2, e3], 'FAIL', 'AUTHORIZATION-TAMPERED')


def x122_spent_record_replayed():
    """A spent record grants nothing further: a later reduction of another floored family is refused."""
    e1, e2 = _removal_chain()
    return lifecycle([e1, e2, e2.replace(':family fixture :minimum 8', ':family fixture :minimum 7', 1)],
                     'FAIL', 'UNIVERSE-FLOOR-REDUCED')


def x123_candidate_injected_spent_record():
    """A candidate cannot write itself a record that merely LOOKS terminally spent."""
    return lifecycle([_corpus_text() + '\n' + _auth('UA-HELD-OUT-FAKE', 'harness', 2, 0) + '\n'],
                     'FAIL', 'AUTHORIZATION-MALFORMED-PROSPECTIVE')


def x124_nonzero_authorization_undefined_family():
    """A record that authorised no removal cannot excuse one: the edge that deletes the floor it names is
    refused, and the record never reaches a spent state."""
    e1 = _corpus_text() + '\n' + _auth('UA-HELD-OUT-GHOST', 'property-family', 5, 4) + '\n'
    e2 = (re.sub(r'\(fact universe-floor UF-PROPERTY-FAMILY[^)]*\)\n?', '', e1)
          .replace(':family universe-floor :minimum 7', ':family universe-floor :minimum 6'))
    return lifecycle([e1, e2], 'FAIL', 'UNIVERSE-FLOOR-REDUCED')


def x125_spent_family_revived():
    """The removed family may not be floored again while its spent record still names it: a revived floor would
    turn a spent authorization back into a fresh permission."""
    e1, e2 = _removal_chain()
    e3 = (e2 + '\n(fact universe-floor UF-PROPERTY-FAMILY-REVIVED :family property-family :minimum 5 '
               ':rationale "held-out revival")\n')
    return lifecycle([e1, e2, e3], 'FAIL', 'AUTHORIZATION-SPENT-FAMILY-REVIVED')


def x126_sibling_no_extra_authority():
    """Two siblings of one authorised base each consume exactly the grant and nothing more: the sibling that
    takes more than its minimum is refused, so sibling consumption adds no authority to either."""
    e1, e2 = _removal_chain()
    okk, why = lifecycle([e1, e2], 'PASS', 'UNIVERSE-AUTHORIZATIONS-CONSUMED UA-HELD-OUT-REMOVAL')
    if not okk:
        return False, 'the first sibling was refused: %s' % why
    return lifecycle([e1, e2.replace(':family fixture :minimum 8', ':family fixture :minimum 7', 1)],
                     'FAIL', 'UNIVERSE-FLOOR-REDUCED')


def x127_unauthorised_removal_not_cured():
    """A removal nobody authorised is not cured by a later record claiming to have authorised it: such a record
    is absent from the base's parent, so it was never prospective anywhere."""
    e1 = (re.sub(r'\(fact universe-floor UF-PROPERTY-FAMILY[^)]*\)\n?', '', _corpus_text())
          .replace(':family universe-floor :minimum 7', ':family universe-floor :minimum 6'))
    e2 = e1 + '\n' + _auth('UA-HELD-OUT-CURE', 'property-family', 5, 0) + '\n'
    return lifecycle([e1, e2, e2], 'FAIL', 'AUTHORIZATION-SPENT-WITHOUT-HISTORY')


# ═══════════════════════════════════════ Review-6 R6-2: every count comes from the model, never from a filename
def _composed_ids():
    return sorted(i for i, p in read_model().of('falsifier') if str(p.get('harness')) == 'COMPOSED_GATE')


def _count_after_moving(destinations):
    """The command's own count expression, over a seat whose COMPOSED_GATE facts were moved to DESTINATIONS
    [(module, [ids])]. The count is a property of the model, so relocating or splitting cannot change it."""
    d, seat = export_seat()
    try:
        for dest, ids in destinations:
            src = os.path.join(seat, 'verification-corpus.sexp')
            forms = SR.read_forms_file(src)
            take = [f for f in forms if SR.head(f) == 'fact' and str(f[1]).lower() == 'falsifier'
                    and str(SR.canonical_value(f[2], 'corpus', 'fact id')) in ids]
            keep = [f for f in forms if not (SR.head(f) == 'fact' and str(f[1]).lower() == 'falsifier'
                    and str(SR.canonical_value(f[2], 'corpus', 'fact id')) in ids)]
            with open(src, 'w', encoding='utf-8', newline='\n') as fh:
                fh.write('\n'.join(emit(x) for x in keep) + '\n')
            with open(os.path.join(seat, dest), 'a', encoding='utf-8', newline='\n') as fh:
                fh.write('\n' + '\n'.join(emit(x) for x in take) + '\n')
        rehash(seat)
        r = AR.bounded_run([PY, os.path.join(seat, 'run_corpus.py'), '--count', 'COMPOSED_GATE'],
                           capture_output=True, text=True, cwd=seat)
        return r.returncode, (r.stdout + r.stderr).strip()
    finally:
        shutil.rmtree(d, ignore_errors=True)


def x128_composed_count_relocated():
    """Every COMPOSED_GATE fact moved to another canonical module: the informational count is unchanged."""
    ids = _composed_ids()
    code, out = _count_after_moving([('seats.sexp', ids)])
    return (code == 0 and out == str(len(ids))), 'after relocation the count is %r, not %d' % (out[:60], len(ids))


def x129_composed_count_split():
    """The same facts split across two modules: still one exact count, still from the model."""
    ids = _composed_ids()
    half = len(ids) // 2
    code, out = _count_after_moving([('seats.sexp', ids[:half]), ('rationale-references.sexp', ids[half:])])
    return (code == 0 and out == str(len(ids))), 'after the split the count is %r, not %d' % (out[:60], len(ids))


def x130_count_unreadable_model_typed():
    """A malformed canonical module must reach the operator as the model's own typed outcome. --count is a model
    read like every other, so its failure speaks the same vocabulary the checks speak and never a traceback."""
    d, seat = export_seat()
    try:
        with io.open(os.path.join(seat, 'verification-corpus.sexp'), 'a', encoding='utf-8', newline='\n') as fh:
            fh.write('\n(fact falsifier X-UNTERMINATED :harness COMPONENT\n')      # an unterminated list
        r = AR.bounded_run([PY, os.path.join(seat, 'run_corpus.py'), '--count', 'COMPOSED_GATE'],
                           capture_output=True, text=True, cwd=seat)
        out = (r.stdout + r.stderr).strip()
        typed, trace = 'UNREADABLE-MODEL-FILE' in out, 'Traceback' in out
        return (r.returncode != 0 and typed and not trace), \
               'exit=%d typed=%s traceback=%s: %r' % (r.returncode, typed, trace, out[:70])
    finally:
        shutil.rmtree(d, ignore_errors=True)


def x131_kind_model_reads_typed():
    """Every public entry point of this program is a model read, so the typed outcome cannot be the property of
    one flag. Over all three --kind entry points, with a malformed and with an absent canonical module, the run
    must end non-zero, in the model's own vocabulary, with no traceback and no count printed (Review-6 R6-2)."""
    bad = []
    for kind in ('fixtures', 'component', 'composed'):
        for how, marker in (('malformed', 'UNREADABLE-MODEL-FILE'), ('missing', 'MISSING-MODEL-FILE')):
            d, seat = export_seat()
            try:
                vc = os.path.join(seat, 'verification-corpus.sexp')
                if how == 'malformed':
                    with io.open(vc, 'a', encoding='utf-8', newline='\n') as fh:
                        fh.write('\n(fact falsifier X-UNTERMINATED :harness COMPONENT\n')
                else:
                    os.remove(vc)
                r = AR.bounded_run([PY, os.path.join(seat, 'run_corpus.py'), '--kind', kind],
                                   capture_output=True, text=True, cwd=seat)
                out = (r.stdout + r.stderr).strip()
                if r.returncode == 0 or marker not in out or 'Traceback' in out:
                    bad.append('--kind %s/%s: exit=%d typed=%s traceback=%s'
                               % (kind, how, r.returncode, marker in out, 'Traceback' in out))
            finally:
                shutil.rmtree(d, ignore_errors=True)
    return (not bad), ('; '.join(bad) if bad else 'six subcases all typed, none a traceback')


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
    ('X44-GLOBAL-PROMOTION-OVERCLAIM', 'global source-of-truth claimed while classes remain deferred', f44_global_promotion_overclaim),
    ('X73-TOOL-VANISHES-BEFORE-SPAWN', 'a tool that passes the pre-check and vanishes before the spawn; a non-executable spawn', f73_tool_vanishes_before_spawn),
    ('X116-PROSPECTIVE-REMOVAL-CONTROL', 'a prospective authorization for a full removal, reducing nothing yet', x116_prospective_removal_control),
    ('X117-AUTHORISED-REMOVAL-CONTROL', 'the next edge removing the floor and consuming the record', x117_authorised_removal_control),
    ('X118-SPENT-NOOP-EDGE-CONTROL', 'a no-op edge after an authorised removal', x118_spent_noop_edge_control),
    ('X119-SPENT-SECOND-NOOP-CONTROL', 'a second no-op edge, so the spent state is not a one-off exemption', x119_spent_second_noop_control),
    ('X120-SPENT-RECORD-REMOVED', 'the spent record dropped by a later candidate', x120_spent_record_removed),
    ('X121-SPENT-RECORD-ALTERED', 'the spent record edited by a later candidate', x121_spent_record_altered),
    ('X122-SPENT-RECORD-REPLAYED', 'a spent record replayed for a further reduction', x122_spent_record_replayed),
    ('X123-CANDIDATE-INJECTED-SPENT-RECORD', 'a candidate writing itself a record that looks terminally spent', x123_candidate_injected_spent_record),
    ('X124-NONZERO-AUTHORIZATION-UNDEFINED-FAMILY', 'a record that authorised no removal excusing one', x124_nonzero_authorization_undefined_family),
    ('X125-SPENT-FAMILY-REVIVED', 'the removed family floored again while its spent record still names it', x125_spent_family_revived),
    ('X126-SIBLING-NO-EXTRA-AUTHORITY', 'two siblings of one authorised base gaining no authority beyond the grant', x126_sibling_no_extra_authority),
    ('X127-UNAUTHORISED-REMOVAL-NOT-CURED', 'an unauthorised removal cured by a later record claiming to have authorised it', x127_unauthorised_removal_not_cured),
    ('X128-COMPOSED-COUNT-RELOCATED', 'the informational composed count with every such fact in another module', x128_composed_count_relocated),
    ('X129-COMPOSED-COUNT-SPLIT', 'the informational composed count with those facts split across two modules', x129_composed_count_split),
    ('X130-COUNT-UNREADABLE-MODEL-TYPED', 'the informational count over a malformed canonical module', x130_count_unreadable_model_typed),
    ('X131-KIND-MODEL-READS-TYPED', 'every --kind entry point over a malformed and an absent canonical module', x131_kind_model_reads_typed),
    ('X79-CANDIDATE-TREE-NOT-COMMIT-ID', 'a commit-ish candidate resolves to its tree, never to the commit id', x79_candidate_tree_is_tree_not_commit),
    ('X80-WORKTREE-ARBITRARY-BASE', 'an arbitrary --base for a WORKTREE candidate', x80_worktree_arbitrary_base_refused),
    ('X81-COMMIT-BASE-NOT-PARENT', 'a committed candidate with a --base other than its unique parent', x81_commit_base_not_parent_refused),
    ('X82-MERGE-CANDIDATE', 'a merge commit as candidate, with and without an explicit base', x82_merge_candidate_refused),
    ('X83-ORPHAN-CANDIDATE', 'a zero-parent commit as candidate', x83_orphan_candidate_refused),
    ('X84-WORKTREE-DIFFERS-BASE-IS-HEAD', 'a working tree differing from HEAD is judged against HEAD', x84_worktree_differs_base_is_head),
    ('X85-WORKTREE-EQUALS-HEAD-BASE-IS-PARENT', 'a working tree equal to HEAD is HEAD, judged against its parent', x85_worktree_equals_head_base_is_parent),
    ('X86-SHALLOW-BASE-MISSING-THEN-FETCHED', 'a depth-1 clone: typed refusal naming the object, PASS after fetching exactly it', x86_shallow_clone_base_missing_then_fetched),
    ('X87-FLOORS-REPORTED-SEPARATELY', 'base floors and candidate floors reported as distinct lines that differ', x87_floors_reported_separately),]
COMPOSED = [
    ('G01-GATE-WRITES-TO-TREE', 'the validation gate modifying the tree it audits', g01_gate_writes_to_tree),
    ('G02-PRE-EXISTING-DRIFT-ERASED', 'pre-existing drift regenerated away before comparison',
     g02_pre_existing_drift_erased),
    ('G03-ARTIFACT-DELETED', 'a declared generated artifact deleted from generator and tree', g03_artifact_deleted),
    ('G04-ARTIFACT-UNDECLARED', 'an undeclared artifact produced into the seat', g04_artifact_undeclared),
    ('G05-CORPUS-SHRUNK', 'a fixture, property family or falsifier silently removed', g05_corpus_shrunk),
    ('G06-TOOLCHAIN-IDENTITY', 'a tool whose executable identity is not the pinned one', g06_toolchain_identity),
    ('G07-UNADJUDICATED-SOURCE', 'a qualifying migration source absent from the ledger', g07_unadjudicated_source),
    ('G08-TMP-COLLISION', 'a hostile pre-existing path at a gate scratch location', g08_tmp_collision),
    ('G11-SIGNAL-CLEANS-ONLY-ITS-OWN-RESOURCES', 'SIGTERM to one of two concurrent runs: own resources gone, the other unaffected, repository identical', g11_signal_cleans_only_its_own),
    ('G12-RELOCATE-THEN-SHRINK-TWO-COMMITS', 'C1 relocates every floor (passes), C2 deletes five and shrinks the corpus: judged against C1 through the real command', g12_two_commit_relocation_then_shrink),]

# ═══════════════════════════════════════════════════════════════════════ the declared universe, then the cases
def universe_integrity():
    """Missing, extra, duplicate or coherently deleted — each a named failure before a single case runs."""
    bad, seen = [], {}
    m = read_model()
    for ftype, fid, _p, mod, _form in m.facts:
        if (ftype, fid) in seen:
            bad.append('DUPLICATE-FACT-ID: %s %s is declared in %s and again in %s' % (ftype, fid, seen[(ftype, fid)], mod))
        seen[(ftype, fid)] = mod
    try:                                     # whole-model discovery, never one module's (Review-5 R5-1)
        floors = SR.universe_floors(m)
        auths = {str(p['family']).lower() for p in SR.universe_authorizations(m).values()}
    except SR.SexpError as e:
        bad.append(str(e)); floors, auths = {}, set()
    fx, fam = corpus()
    counts = {'fixture': len(fx), 'property-family': len(fam), 'falsifier': len(m.of('falsifier'))}
    for fam_name, d in sorted(floors.items()):
        if fam_name in counts and counts[fam_name] < d['minimum'] and fam_name not in auths:
            bad.append('UNIVERSE-BELOW-FLOOR: family %s holds %d, floor %d (%s), and no universe-authorization '
                       'records the reduction' % (fam_name, counts[fam_name], d['minimum'], d['id']))
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
    declared = dict(m.of('falsifier'))
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
    ap.add_argument('--kind', choices=('fixtures', 'component', 'composed'), default=None)
    ap.add_argument('--work', default=None)
    ap.add_argument('--keep-work', action='store_true')
    ap.add_argument('--only', default=None, help='run only these falsifier ids, comma separated')
    ap.add_argument('--candidate', default=os.environ.get('AML_CANDIDATE', 'WORKTREE'),
                    help='what the falsifier kinds judge: a commit-ish (base = its unique parent) or WORKTREE '
                         '(base = HEAD, or HEAD\'s parent when the working tree equals HEAD); never a bare tree')
    ap.add_argument('--base', default=None,
                    help='confirmation of the base the candidate determines (Review-5 R5-2); one that differs is '
                         'a typed refusal, never a choice; the fixtures kind judges model copies and needs none')
    ap.add_argument('--count', default=None, choices=('COMPONENT', 'COMPOSED_GATE'),
                    help='print how many falsifiers of that harness THIS SEAT\'s model declares, and exit. It is '
                         'the same whole-model ROOT-composed read the battery itself uses, so no count anywhere '
                         'depends on the name of a module (Review-6 R6-2); distinct ids, so a duplicate is a '
                         'model-law failure rather than a double count')
    a = ap.parse_args()
    if a.count:
        m = read_model()                     # the one typed model-read seat, like every other read here
        print(len({i for i, p in m.of('falsifier') if str(p.get('harness')) == a.count}))
        sys.exit(0)
    if not a.kind:
        ap.error('--kind is required unless --count is given')
    BASE, CANDIDATE = a.base, a.candidate
    problems = universe_integrity()
    if problems:
        for p in problems:
            print('  UNIVERSE:', p)
        print('corpus universe integrity: FAIL (%d finding(s)) — no case was run' % len(problems))
        sys.exit(1)
    if a.kind != 'fixtures':
        candidate()                          # typed refusal before any case if the candidate has no legal base
    work = AR.workspace('aml-corpus-', REPO, keep=a.keep_work, reuse=a.work)
    sys.exit(fixtures_kind(work) if a.kind == 'fixtures'
             else falsifier_kind('COMPONENT' if a.kind == 'component' else 'COMPOSED_GATE', a.only))
