#!/usr/bin/env python3
"""run_falsifiers.py — held-out falsifiers for the corrected architecture-governance seat.

A gate that has never been made to fail is a decoration. Each falsifier below injects one specific defect and
requires the corrected machinery to REJECT it for the intended, named reason. A falsifier that is rejected for
the wrong reason counts as a failure, because it would not have caught the defect it exists for.

Every mutation happens on a COPY: model mutations in a temporary model directory, migration-source mutations in
a temporary change-proposal tree, tracked-universe mutations in a temporary git index built from the real one
without checking out a single file. Where a falsifier must exercise the committed working tree itself, the file
is restored in a finally block AFTER the check has already reported.

Usage: run_falsifiers.py [--list]
"""
import hashlib, importlib.util, os, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..', '..', '..', '..'))
_spec = importlib.util.spec_from_file_location('sexp_reader', os.path.join(HERE, 'SEXP-READER.py'))
SR = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(SR)
_bspec = importlib.util.spec_from_file_location('build_inventory', os.path.join(HERE, 'build_inventory.py'))

RESULTS = []


def record(name, intent, ok_, detail):
    detail = detail if isinstance(detail, str) else repr(detail)
    RESULTS.append((name, intent, ok_, detail))
    print('%-34s %-52s %s' % (name, intent, 'REJECTED as intended' if ok_ else 'NOT REJECTED - ' + detail))


# ----------------------------------------------------------------- model-level helpers
def modules():
    forms = SR.read_forms_file(os.path.join(HERE, 'ROOT.sexp'))
    r = [f for f in forms if SR.head(f) == 'define-model-root'][0]
    pl = dict(SR.plist(r[2:], 'ROOT.sexp', 'root'))
    return [str(dict(SR.plist(e, 'ROOT.sexp', 'e'))['module']) for e in pl['composition']]


def sha_file(p):
    with open(p, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()


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
    r = subprocess.run(['sbcl', '--script', os.path.join(HERE, 'KERNEL', 'model-law-kernel.lisp'),
                        os.path.join(d, 'ROOT.sexp')], capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def checker(d):
    r = subprocess.run([sys.executable, os.path.join(HERE, 'CHECKER', 'independent_check.py'),
                        os.path.join(d, 'ROOT.sexp')], capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def append(d, mod, text):
    with open(os.path.join(d, mod), 'a', encoding='utf-8') as f:
        f.write('\n' + text + '\n')


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


def run_one(name, intent, fn):
    try:
        okk, detail = fn()
    except Exception as e:                                   # a falsifier must never pass by crashing
        okk, detail = False, 'harness error: %r' % (e,)
    record(name, intent, okk, detail)


# ----------------------------------------------------------------- temp tracked-universe (no checkout)
def index_repo(add=(), remove=()):
    """A throwaway git repository whose INDEX mirrors the real one, with no file checked out at all."""
    d = tempfile.mkdtemp(prefix='fals-index-')
    subprocess.run(['git', 'init', '-q', d], check=True, capture_output=True)
    listing = subprocess.run(['git', '-C', REPO, 'ls-files', '-s', '-z'], capture_output=True, check=True).stdout
    subprocess.run(['git', '-C', d, 'update-index', '-z', '--index-info'], input=listing, check=True,
                   capture_output=True)
    for path in add:
        blob = subprocess.run(['git', '-C', d, 'hash-object', '-w', '--stdin'], input=b'x\n',
                              capture_output=True, check=True).stdout.decode().strip()
        subprocess.run(['git', '-C', d, 'update-index', '--add', '--cacheinfo', '100644,%s,%s' % (blob, path)],
                       check=True, capture_output=True)
    for path in remove:
        subprocess.run(['git', '-C', d, 'update-index', '--force-remove', path], check=True, capture_output=True)
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


def gate_check(which, cwd=None):
    r = subprocess.run([sys.executable, os.path.join(HERE, 'gate_checks.py'), which],
                       capture_output=True, text=True, cwd=cwd or HERE)
    return r.returncode, r.stdout + r.stderr


# ----------------------------------------------------------------- the immutable candidate, exported
# Review-2 §2. NOTHING here writes the primary working tree. There is deliberately no helper that edits a
# repository file and restores it afterwards: a reproducer that mutates the tree under audit can leave it
# damaged when a run is interrupted, and a harness that CAN do that will eventually be written to do it. Every
# falsifier below therefore mutates either a disposable model copy or a disposable EXPORT of the immutable
# candidate tree, and runs the real check against that export with `gate_checks.py --seat`.
_CAND = {}


def candidate():
    """(tree, exported seat) for the immutable candidate — resolved once, by the one seat that builds it."""
    if not _CAND:
        r = subprocess.run([sys.executable, os.path.join(HERE, 'gate_checks.py'), 'candidate'],
                           capture_output=True, text=True, cwd=HERE)
        tree = next((l.split()[1] for l in r.stdout.splitlines() if l.startswith('CANDIDATE-TREE ')), None)
        if tree is None:
            raise RuntimeError('the candidate tree could not be resolved: %s' % (r.stdout + r.stderr)[-400:])
        _CAND['tree'] = tree
        _CAND['rel'] = os.path.relpath(HERE, REPO).replace(os.sep, '/')
    return _CAND['tree'], _CAND['rel']


def export_seat():
    """A disposable directory holding the candidate tree's own bytes for the architecture-model seat."""
    tree, rel = candidate()
    d = tempfile.mkdtemp(prefix='fals-seat-')
    tar = subprocess.run(['git', '-C', REPO, 'archive', tree, rel], capture_output=True, check=True).stdout
    subprocess.run(['tar', '-x', '-C', d], input=tar, check=True)
    return d, os.path.join(d, rel)


def seat_text(seat, rel):
    with open(os.path.join(seat, rel), encoding='utf-8') as f:
        return f.read()


def seat_write(seat, rel, text):
    with open(os.path.join(seat, rel), 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)


def _seat_check(which, mutate, needle):
    """Run a REAL gate check against a deliberately mutated export of the immutable candidate seat.

    The check logic is the gate's own; only the source of the model differs, so a falsifier proves the deployed
    check catches the defect rather than proving a re-implementation of it does."""
    tree, _rel = candidate()
    d, seat = export_seat()
    work = tempfile.mkdtemp(prefix='fals-work-')
    try:
        mutate(seat)
        r = subprocess.run([sys.executable, os.path.join(HERE, 'gate_checks.py'), which,
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
               GIT_ALTERNATE_OBJECT_DIRECTORIES=os.path.join(REPO, '.git', 'objects'))
    os.makedirs(env['GIT_OBJECT_DIRECTORY'])

    def g(args, **kw):
        return subprocess.run(['git', '-C', REPO] + args, env=env, capture_output=True, check=True, **kw)

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
        r = subprocess.run([sys.executable, os.path.join(HERE, 'gate_checks.py'), which,
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


def seat_path(rel):
    """A seat-relative path expressed as the repository path the candidate tree uses."""
    return '%s/%s' % (os.path.relpath(HERE, REPO).replace(os.sep, '/'), rel)


def _inventory_seat_mutation(transform):
    def mut(seat):
        b = seat_text(seat, 'files-and-roles.sexp')
        t = transform(b)
        if t == b:
            raise RuntimeError('the mutation changed nothing; the falsifier would be vacuous')
        seat_write(seat, 'files-and-roles.sexp', t)
    return mut


# =========================================================================== INVENTORY AND TRACKED UNIVERSE
def _drop_line(match):
    def t(b):
        for l in b.splitlines():
            if match(l):
                return b.replace(l + '\n', '', 1)
        return b
    return t


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


def f04_extra_inventory_path():
    def t(b):
        return b.replace('\n(fact dir-rule DR-0001',
                         '\n(fact file "no/such/tracked/path.md" :role AUTHORED_NORMATIVE_PROSE :rule R-027 '
                         ':reason "invented")\n(fact dir-rule DR-0001', 1)
    return _seat_check('inventory', _inventory_seat_mutation(t), 'EXTRA-INVENTORY-PATH')


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


def f07_greek_normative_out_of_scope():
    """A NAMED inventory row silently re-roled. Before this pass only directory-rule counts were re-derived,
    so an individually listed normative document could be re-classified out of scope and nothing looked."""
    def t(b):
        for l in b.splitlines():
            if l.startswith('(fact file ') and 'LAWMAX-OMEGA-CANON/GR/' in l and 'AUTHORED_NORMATIVE_PROSE' in l:
                return b.replace(l, l.replace('AUTHORED_NORMATIVE_PROSE', 'OUT_OF_SCOPE_WITH_REASON', 1), 1)
        return b
    return _seat_check('inventory', _inventory_seat_mutation(t), 'INVENTORY-CLASSIFICATION-DRIFT')


def f19_restore_instead_of_compare():
    """The gate must never erase a difference before it is compared, and must never write the tree it audits."""
    bad = []
    for fn in ('ARCHITECTURE-MODEL-GATE.sh', 'gate_checks.py', 'build_inventory.py', 'run_gate_falsifiers.py'):
        path = os.path.join(HERE, fn)
        if not os.path.isfile(path):
            continue
        for line in open(path, encoding='utf-8').read().splitlines():
            body = line.strip()
            if body.startswith(('#', '//', ';')) or 'git checkout' not in body:
                continue
            if fn == 'run_gate_falsifiers.py':          # the composed battery works inside its own clone
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


# =========================================================================== READER, UNIVERSE AND COMMITMENTS
def baseline_totals():
    d = model_copy()
    try:
        kc, ko = kernel(d)
        cc, co = checker(d)
        n = [l for l in ko.splitlines() if l.startswith('COMMITMENT total-facts ')][0].split()[-1]
        return kc == 0 and cc == 0, int(n)
    finally:
        shutil.rmtree(d, ignore_errors=True)


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


# =========================================================================== SCHEMA, ISOLATION AND GRAMMAR
def f13_private_typo():
    def mut(d):
        path = os.path.join(d, 'interfaces-and-types.sexp')
        t = open(path, encoding='utf-8').read()
        line = [l for l in t.splitlines() if l.startswith('(fact type ') and ':classification PRIVATE' in l][0]
        open(path, 'w', encoding='utf-8', newline='\n').write(
            t.replace(line, line.replace(':classification PRIVATE', ':classification PRIVAT'), 1))
    return both_reject(mut, 'outside enum classification domain', 'L1')


def f14_unknown_consumer():
    return both_reject(lambda d: append(d, 'dependencies-and-boundaries.sexp',
                                        '(fact consumes S99__HELDOUT :consumer S99 :provides ActionIntent/1)'),
                       'resolves to no declared subsystem', 'L3')


def f15_wrong_type_provides():
    return both_reject(lambda d: append(d, 'dependencies-and-boundaries.sexp',
                                        '(fact consumes S01__WRONGKIND :consumer S01 :provides S02)'),
                       ':provides = S02 resolves to no declared type', 'L3')


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


def f32_module_count_mismatch():
    def mut(d):
        path = os.path.join(d, 'ROOT.sexp')
        t = open(path, encoding='utf-8').read()
        open(path, 'w', encoding='utf-8', newline='\n').write(
            t.replace('  :module-count %d' % len(modules()), '  :module-count %d' % (len(modules()) - 1), 1))
    return both_reject(mut, 'module-count', 'module-count', rehash_after=False)


def f22_unconsumed_syntax():
    return both_reject(lambda d: append(d, 'rationale-references.sexp', '(define-something-else extra)'),
                       'unexpected top-level form', 'UNCONSUMED-CANONICAL-SYNTAX')


def f23_reader_injection():
    return both_reject(lambda d: append(d, 'rationale-references.sexp',
                                        '(fact rationale INJECTED :doc #.(sb-ext:run-program "/bin/true" nil) '
                                        ':anchor "x")'),
                       'unreadable model file', 'MODEL-UNREADABLE')


def f27_illegal_value_kind():
    return both_reject(lambda d: append(d, 'rationale-references.sexp',
                                        '(fact rationale KEYWORDVALUE :doc :A-KEYWORD :anchor "x")'),
                       'illegal value kind', 'MALFORMED-FACT')


def f28_type_consumer_without_role():
    def mut(d):
        path = os.path.join(d, 'interfaces-and-types.sexp')
        t = open(path, encoding='utf-8').read()
        open(path, 'w', encoding='utf-8', newline='\n').write(t.replace(' :consumer-role PROPOSER', '', 1))
    return both_reject(mut, 'declares no :consumer-role', 'TYPE-CONSUMER-WITHOUT-CONSUMER-ROLE')


def f29_generation_order_cycle():
    return both_reject(lambda d: append(d, 'generation-order.sexp',
                                        '(fact gen-edge PACKET__DEFERRED-LEDGER :from PACKET :to DEFERRED-LEDGER)'),
                       'cycle in the gen-edge graph over gen-step', 'L4')


def f09_multiline_private_leak():
    def mut(d):
        path = os.path.join(d, 'interfaces-and-types.sexp')
        priv = [l for l in open(path, encoding='utf-8') if l.startswith('(fact type ') and ':classification PRIVATE' in l][0]
        pid = priv.split()[2]
        append(d, 'dependencies-and-boundaries.sexp',
               '(fact consumes S12__HELDOUTLEAK\n    :consumer S12\n    :provides %s)' % pid)
    return both_reject(mut, 'public/private leak', 'L5')


# =========================================================================== DEFERRED LEDGER
AM_REL = os.path.relpath(HERE, REPO).replace(os.sep, '/')
CP_REL = os.path.dirname(AM_REL)


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
    r = subprocess.run([sys.executable, os.path.join(am, 'build_deferred.py'), '--verify'],
                       capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


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


# =========================================================================== DERIVED DOCUMENTS
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
            '    subprocess.run([sys.executable, %r])\n' % name)
    return _tree_check('dependency-closure',
                       {seat_path(name): body, seat_path('build_root.py'): (builder + call).encode('utf-8')},
                       'HISTORICAL-CODE-IN-CLOSURE')


# =========================================================================== SCHEMA CLOSURE, SEATS, AUTHORITY
# Review-2 N-8/N-9/N-10/N-7. Each of these was accepted by BOTH paths before this pass.
def _probe_seat(body):
    return lambda d: append(d, 'seats.sexp', body)


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


def f36_id_space_violation():
    return both_reject(lambda d: append(d, 'subsystems.sexp',
                                        '(fact subsystem BADID :owner-seat SEAT-MEMORY :classification PUBLIC '
                                        ':migration KEEP :mission MIS-1)'),
                       'does not start with the SUBSYSTEM-SPACE prefix', 'ID-SPACE')


def f37_root_extra_form():
    return both_reject(lambda d: append(d, 'ROOT.sexp', '(fact seat SEAT-SMUGGLED :status BUILT :path "x" :note "y")'),
                       'exactly one define-model-root form and nothing else', 'ROOT-MALFORMED',
                       rehash_after=False)


def f38_root_duplicate_key():
    def mut(d):
        p = os.path.join(d, 'ROOT.sexp')
        t = open(p, encoding='utf-8').read()
        open(p, 'w', encoding='utf-8', newline='\n').write(
            t.replace('  :module-count', '  :module-count 99\n  :module-count', 1))
    return both_reject(mut, 'declares :module-count more than once', 'ROOT-MALFORMED', rehash_after=False)


def f39_root_schema_version():
    def mut(d):
        p = os.path.join(d, 'ROOT.sexp')
        t = open(p, encoding='utf-8').read()
        open(p, 'w', encoding='utf-8', newline='\n').write(t.replace(':schema-version "3"', ':schema-version "99"'))
    return both_reject(mut, 'binds :schema-version', 'schema-version', rehash_after=False)


def f40_ghost_seat():
    def mut(d):
        p = os.path.join(d, 'subsystems.sexp')
        t = open(p, encoding='utf-8').read()
        open(p, 'w', encoding='utf-8', newline='\n').write(
            t.replace(':owner-seat SEAT-MEMORY', ':owner-seat SEAT-GHOST-DOES-NOT-EXIST', 1))
    return both_reject(mut, 'resolves to no declared seat', 'L3')


def f41_design_target_with_path():
    def mut(d):
        p = os.path.join(d, 'seats.sexp')
        t = open(p, encoding='utf-8').read()
        open(p, 'w', encoding='utf-8', newline='\n').write(
            t.replace('(fact seat SEAT-SECURITY-CELLS :status DESIGN_TARGET',
                      '(fact seat SEAT-SECURITY-CELLS :path "CLAUDE.md" :status DESIGN_TARGET', 1))
    return both_reject(mut, 'forbids :path', 'CONDITIONAL-FORBIDS')


def f43_rival_store_owner():
    return both_reject(lambda d: append(d, 'stores-and-authorities.sexp',
                                        '(fact store probe-rival :owner SEAT-JOURNAL :writer SEAT-NO-WRITER)'),
                       'STORE-OWNER-IS-ONE-SEAT', 'ALSO-CLAIMED-BY')


def f42_built_seat_path_untracked():
    def mut(seat):
        p = os.path.join(seat, 'seats.sexp')
        t = open(p, encoding='utf-8').read()
        open(p, 'w', encoding='utf-8', newline='\n').write(
            t.replace(':path "source/memory.lisp"', ':path "source/this-file-does-not-exist.lisp"', 1))
    return _seat_check('seats', mut, 'SEAT-PATH-NOT-TRACKED')


def f44_global_promotion_overclaim():
    def mut(seat):
        p = os.path.join(seat, 'deferred-imports.sexp')
        t = open(p, encoding='utf-8').read()
        open(p, 'w', encoding='utf-8', newline='\n').write(
            t.replace(':scope GLOBAL :state FORBIDDEN_UNTIL_DDI_COMPLETE', ':scope GLOBAL :state PERMITTED', 1))
        subprocess.run([sys.executable, os.path.join(seat, 'build_root.py')], capture_output=True, cwd=seat)
    return _seat_check('packet', mut, 'GLOBAL-PROMOTION-OVERCLAIM')


def f45_control_character_in_string():
    """A canonical commitment joins rendered fact lines with a newline. A value able to contain one would make
    two different fact sets renderable to the same bytes, so the grammar forbids it and both paths must say so
    rather than accepting it (the kernel) or dying in the solver's lexer (the checker)."""
    return both_reject(lambda d: append(d, 'rationale-references.sexp',
                                        '(fact rationale CONTROLCHAR :doc "line one\nline two" :anchor "x")'),
                       'illegal value kind', 'control character')


FALSIFIERS = [
    ('K01-GENERATED-VIEW-MISSING', 'a tracked generated view absent from the inventory', f01_generated_view_missing),
    ('K02-NEW-FILE-NO-RULE', 'a new tracked file matching no classification rule', f02_new_tracked_file_no_rule),
    ('K03-MISSING-INVENTORY-PATH', 'a tracked path missing from the inventory', f03_missing_inventory_path),
    ('K04-EXTRA-INVENTORY-PATH', 'an inventory key that is not tracked', f04_extra_inventory_path),
    ('K05-DUPLICATE-INVENTORY-KEY', 'the same path classified twice', f05_duplicate_inventory_key),
    ('K06-C-QUOTED-PATH', 'a non-ASCII path written as C-quoted text', f06_c_quoted_path),
    ('K07-GREEK-FILE-OUT-OF-SCOPE', 'a normative Greek document classified out of scope', f07_greek_normative_out_of_scope),
    ('K08-MULTILINE-FACT-KEPT', 'a benign multi-line fact silently omitted', f08_multiline_fact_not_lost),
    ('K09-MULTILINE-PRIVATE-LEAK', 'a public/private leak written across lines', f09_multiline_private_leak),
    ('K10-NEW-PINNED-MODULE', 'a newly pinned module ignored by one path', f10_new_pinned_module_consumed),
    ('K11-FACT-COUNT-MISMATCH', 'the two paths consuming different fact counts', f11_fact_count_mismatch),
    ('K12-FAMILY-DIGEST-MISMATCH', 'equal counts but a different per-family digest', f12_family_digest_mismatch),
    ('K13-PRIVATE-TYPO', 'a mistyped classification value (PRIVAT)', f13_private_typo),
    ('K14-UNKNOWN-CONSUMER', 'an undeclared consumer (S99)', f14_unknown_consumer),
    ('K15-WRONG-TYPE-PROVIDES', 'a provides endpoint of the wrong kind', f15_wrong_type_provides),
    ('K16-ROOT-DIGEST-ALONE', 'the root digest changed without changing any pin', f16_root_digest_changed_alone),
    ('K17-DUPLICATE-LEDGER-ROW', 'a duplicated deferred-ledger row', f17_duplicate_ledger_row),
    ('K18-MISSING-SOURCE-FILE', 'an absent migration source file', f18_missing_source_file),
    ('K20-PACKET-UNDERCOUNT', 'a decision-packet total the model does not support', f20_packet_undercount),
    ('K21-SELF-CERTIFIED-PASS', 'a verdict issued without the other path present', f21_no_self_certified_pass),
    ('K22-UNCONSUMED-SYNTAX', 'canonical-model syntax no reader consumes', f22_unconsumed_syntax),
    ('K23-READER-INJECTION', 'a read-time evaluation attempt in a module', f23_reader_injection),
    ('K24-CRLF-TEXT-HASHING', 'pins computed with text-decoded hashing', f24_crlf_text_decoded_hash),
    ('K25-PROVIDER-UNAVAILABLE', 'the vetted hash provider unavailable', f25_hash_provider_unavailable),
    ('X26-DEAD-RULE', 'a classification rule that can never fire', f26_dead_classification_rule),
    ('X27-ILLEGAL-VALUE-KIND', 'a value of a kind the grammar forbids', f27_illegal_value_kind),
    ('X28-CONSUMER-WITHOUT-ROLE', 'a type consuming without a declared consumer-role', f28_type_consumer_without_role),
    ('X29-GENERATION-ORDER-CYCLE', 'a cycle in the declared generation order', f29_generation_order_cycle),
    ('X30-UNRECORDED-NORMALIZATION', 'a migration normalization with no ledger row', f30_unrecorded_normalization),
    ('X31-HISTORICAL-ON-LIVE-PATH', 'historical code made a live dependency', f31_historical_code_on_live_path),
    ('X32-MODULE-COUNT-MISMATCH', 'a module count ROOT does not actually pin', f32_module_count_mismatch),
    ('X33-UNKNOWN-FACT-FIELD', 'a field no fact type declares', f33_unknown_fact_field),
    ('X34-MISSPELLED-OPTIONAL-FIELD', 'a misspelled optional field with no downstream law', f34_misspelled_optional_field),
    ('X35-WRONG-VALUE-TYPE', 'a declared field carrying the wrong value kind', f35_wrong_value_type),
    ('X36-ID-SPACE-VIOLATION', 'an id outside its declared id-space', f36_id_space_violation),
    ('X37-ROOT-EXTRA-FORM', 'a surplus top-level form in ROOT.sexp', f37_root_extra_form),
    ('X38-ROOT-DUPLICATE-KEY', 'a duplicated plist key in ROOT.sexp', f38_root_duplicate_key),
    ('X39-ROOT-SCHEMA-VERSION', 'a schema version ROOT does not actually bind', f39_root_schema_version),
    ('X40-GHOST-SEAT', 'a seat reference resolving to no declared seat', f40_ghost_seat),
    ('X41-DESIGN-TARGET-WITH-PATH', 'a design target dressed as a built artifact', f41_design_target_with_path),
    ('X42-BUILT-SEAT-PATH-UNTRACKED', 'a built seat whose path is not in the candidate tree', f42_built_seat_path_untracked),
    ('X43-RIVAL-STORE-WRITER', 'two stores claiming the same owner seat', f43_rival_store_owner),
    ('X44-GLOBAL-PROMOTION-OVERCLAIM', 'global source-of-truth claimed while classes remain deferred', f44_global_promotion_overclaim),
    ('X45-CONTROL-CHARACTER-IN-STRING', 'a control character inside a canonical string value', f45_control_character_in_string),
]

if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == '--list':
        for n, i, _f in FALSIFIERS:
            print('%-34s %s' % (n, i))
        sys.exit(0)
    for name, intent, fn in FALSIFIERS:
        run_one(name, intent, fn)
    bad = [r for r in RESULTS if not r[2]]
    print('held-out falsifiers=%d rejected-as-intended=%d not-rejected=%d'
          % (len(RESULTS), len(RESULTS) - len(bad), len(bad)))
    for r in bad:
        print('  NOT REJECTED: %s — %s — %s' % (r[0], r[1], r[3]))
    sys.exit(0 if not bad else 1)
