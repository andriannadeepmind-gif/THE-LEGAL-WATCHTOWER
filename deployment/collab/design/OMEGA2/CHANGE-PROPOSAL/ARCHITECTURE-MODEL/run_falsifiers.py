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


def mutated_file(path, new_bytes):
    """Replace PATH's bytes, yielding, then restore — the restore always happens AFTER the check reported."""
    class Ctx:
        def __enter__(self):
            with open(path, 'rb') as f:
                self.backup = f.read()
            with open(path, 'wb') as f:
                f.write(new_bytes)
            return path

        def __exit__(self, *exc):
            with open(path, 'wb') as f:
                f.write(self.backup)
            return False
    return Ctx()


INV = os.path.join(HERE, 'files-and-roles.sexp')


def inv_bytes():
    with open(INV, 'rb') as f:
        return f.read()


# =========================================================================== INVENTORY AND TRACKED UNIVERSE
def f01_generated_view_missing():
    b = inv_bytes().decode('utf-8')
    target = [l for l in b.splitlines() if 'GENERATED/DEFERRED-DATA-IMPORT-VIEW.md' in l]
    if not target:
        return False, 'the generated deferred view has no inventory fact to remove'
    mutated = b.replace(target[0] + '\n', '')
    with mutated_file(INV, mutated.encode('utf-8')):
        code, out = gate_check('inventory')
    return (code != 0 and 'MULTISET-MISMATCH' in out
            and 'GENERATED/DEFERRED-DATA-IMPORT-VIEW.md' in out
            and 'differs from the working-tree inventory' in out), out.strip().splitlines()[-1:]


def f02_new_tracked_file_no_rule():
    d = index_repo(add=['zz-held-out-unruled-artifact.xyz'])
    try:
        out_path = os.path.join(d, 'inv.sexp')
        code, out = inventory_on(d, out_path)
        return code != 0 and 'UNCLASSIFIED' in out and 'zz-held-out-unruled-artifact.xyz' in out, out.strip()
    finally:
        shutil.rmtree(d, ignore_errors=True)


def _inventory_mutation(transform, needle):
    b = inv_bytes().decode('utf-8')
    mutated = transform(b)
    if mutated == b:
        return False, 'the mutation changed nothing'
    with mutated_file(INV, mutated.encode('utf-8')):
        code, out = gate_check('inventory')
    return code != 0 and needle in out, out.strip().splitlines()[-3:]


def f03_missing_inventory_path():
    def t(b):
        for l in b.splitlines():
            if l.startswith('(fact file ') and 'deployment/collab/dialogue/' in l:
                return b.replace(l + '\n', '')
        return b
    return _inventory_mutation(t, 'MULTISET-MISMATCH')


def f04_extra_inventory_path():
    def t(b):
        return b.replace('\n(fact dir-rule DR-0001',
                         '\n(fact file "no/such/tracked/path.md" :role AUTHORED_NORMATIVE_PROSE :rule R-027 '
                         ':reason "invented")\n(fact dir-rule DR-0001', 1)
    return _inventory_mutation(t, 'EXTRA-INVENTORY-PATH')


def f05_duplicate_inventory_key():
    def t(b):
        for l in b.splitlines():
            if l.startswith('(fact file '):
                return b.replace(l + '\n', l + '\n' + l + '\n', 1)
        return b
    return _inventory_mutation(t, 'DUPLICATE-INVENTORY-KEY')


def f06_c_quoted_path():
    def t(b):
        for l in b.splitlines():
            if l.startswith('(fact file ') and 'LAWMAX-OMEGA-CANON/GR/' in l:
                start = l.index('"'); end = l.index('"', start + 1)
                path = l[start + 1:end]
                cq = '\\"' + ''.join(ch if ord(ch) < 128 else ''.join('\\\\%03o' % byte for byte in ch.encode('utf-8'))
                                     for ch in path) + '\\"'
                return b.replace(l, l[:start + 1] + cq + l[end:], 1)
        return b
    return _inventory_mutation(t, 'C-QUOTED-INVENTORY-KEY')


def f07_greek_normative_out_of_scope():
    def t(b):
        for l in b.splitlines():
            if l.startswith('(fact file ') and 'LAWMAX-OMEGA-CANON/GR/' in l and 'AUTHORED_NORMATIVE_PROSE' in l:
                return b.replace(l, l.replace('AUTHORED_NORMATIVE_PROSE', 'OUT_OF_SCOPE_WITH_REASON'), 1)
        return b
    return _inventory_mutation(t, 'differs from the working-tree inventory')


def f19_restore_instead_of_compare():
    """The gate must never erase a regenerated/committed difference before it is compared."""
    bad = []
    for fn in ('ARCHITECTURE-MODEL-GATE.sh', 'gate_checks.py', 'build_inventory.py'):
        path = os.path.join(HERE, fn)
        if not os.path.isfile(path):
            continue
        text = open(path, encoding='utf-8').read()
        for line in text.splitlines():
            if 'git checkout' in line and not line.strip().startswith(('#', '//', ';')):
                bad.append('%s: %s' % (fn, line.strip()))
    if bad:
        return False, 'a restore-before-compare survives: %s' % bad
    # and positively: a drifted inventory must fail rather than be silently repaired
    mutated = inv_bytes().decode('utf-8').replace(');\n', ');\n', 1) + '\n; drift\n'
    with mutated_file(INV, mutated.encode('utf-8')):
        code, out = gate_check('inventory')
    return code != 0 and 'differs from the working-tree inventory' in out, out.strip().splitlines()[-1:]


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
    d = model_copy()
    try:
        path = os.path.join(d, 'TOOLCHAIN.sexp')
        t = open(path, encoding='utf-8').read()
        open(path, 'w', encoding='utf-8', newline='\n').write(
            t.replace(':source-registry-tree "third-party/"', ':source-registry-tree "no-such-vendor-tree/"'))
        rehash(d)
        kc, ko = kernel(d)
        return kc == 4 and 'TOOLCHAIN-FAILURE' in ko and 'UNAVAILABLE' in ko, ko.strip().splitlines()[:2]
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
                       'unreadable model file', 'SEXP-SYNTAX-ERROR')


def f27_illegal_value_kind():
    return both_reject(lambda d: append(d, 'rationale-references.sexp',
                                        '(fact rationale KEYWORDVALUE :doc :A-KEYWORD :anchor "x")'),
                       'illegal value kind', 'VALUE-KIND-ERROR')


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
SOURCES = ['SUBSYSTEM-REGISTRY.sexp', 'INTERFACE-AND-SCHEMA-REGISTRY.sexp', 'V1.5-SCHEMAS.sexp',
           'V1.6-SCHEMAS.sexp', 'V1.7-SCHEMAS.sexp', 'V1.8-SCHEMAS.sexp']


def cp_copy():
    """A temporary change-proposal tree: the migration sources plus just enough of the model seat to verify."""
    d = tempfile.mkdtemp(prefix='fals-cp-')
    am = os.path.join(d, 'ARCHITECTURE-MODEL')
    os.makedirs(am)
    cp = os.path.dirname(HERE)
    for s in SOURCES:
        shutil.copy(os.path.join(cp, s), os.path.join(d, s))
    for f in ('build_deferred.py', 'SEXP-READER.py', 'deferred-imports.sexp'):
        shutil.copy(os.path.join(HERE, f), os.path.join(am, f))
    return d, am


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
        os.remove(os.path.join(d, 'V1.7-SCHEMAS.sexp'))
        code, out = run_verify(am)
        return code == 5 and 'MISSING-SOURCE-FILE' in out and 'V1.7-SCHEMAS.sexp' in out, out.strip().splitlines()[:2]
    finally:
        shutil.rmtree(d, ignore_errors=True)


# =========================================================================== DERIVED DOCUMENTS
def f20_packet_undercount():
    path = os.path.join(HERE, 'ROOT-OPERATOR-DECISION-PACKET.md')
    with open(path, 'rb') as f:
        raw = f.read()
    text = raw.decode('utf-8')
    line = [l for l in text.splitlines() if l.startswith('total-facts ')][0]
    mutated = text.replace(line, 'total-facts %d' % (int(line.split()[1]) - 1), 1)
    with mutated_file(path, mutated.encode('utf-8')):
        code, out = gate_check('packet')
    return code != 0 and 'PACKET-MISMATCH' in out and 'total-facts' in out, out.strip().splitlines()[:2]


def f30_unrecorded_normalization():
    path = os.path.join(HERE, 'MODEL-MIGRATION-CONFLICT-LEDGER.md')
    text = open(path, encoding='utf-8').read()
    line = [l for l in text.splitlines() if l.startswith('|') and 'NON-SUBSYSTEM-CONSUMER' in l][0]
    with mutated_file(path, text.replace(line + '\n', '', 1).encode('utf-8')):
        code, out = gate_check('conflict-ledger')
    return code != 0 and 'UNRECORDED-NORMALIZATION' in out, out.strip().splitlines()[:2]


def f31_historical_code_on_live_path():
    path = os.path.join(HERE, 'build_root.py')
    text = open(path, encoding='utf-8').read()
    mutated = text + '\nHELD_OUT_DEPENDENCY = "V1.8-VERIFY.py"\n'
    with mutated_file(path, mutated.encode('utf-8')):
        code, out = gate_check('live-path')
    return code != 0 and 'HISTORICAL-CODE-ON-LIVE-PATH' in out, out.strip().splitlines()[:2]


FALSIFIERS = [
    ('K01-generated-view-missing', 'a tracked generated view absent from the inventory', f01_generated_view_missing),
    ('K02-new-file-no-rule', 'a new tracked file matching no classification rule', f02_new_tracked_file_no_rule),
    ('K03-missing-inventory-path', 'a tracked path missing from the inventory', f03_missing_inventory_path),
    ('K04-extra-inventory-path', 'an inventory key that is not tracked', f04_extra_inventory_path),
    ('K05-duplicate-inventory-key', 'the same path classified twice', f05_duplicate_inventory_key),
    ('K06-c-quoted-path', 'a non-ASCII path written as C-quoted text', f06_c_quoted_path),
    ('K07-greek-file-out-of-scope', 'a normative Greek document classified out of scope', f07_greek_normative_out_of_scope),
    ('K08-multiline-fact-kept', 'a benign multi-line fact silently omitted', f08_multiline_fact_not_lost),
    ('K09-multiline-private-leak', 'a public/private leak written across lines', f09_multiline_private_leak),
    ('K10-new-pinned-module', 'a newly pinned module ignored by one path', f10_new_pinned_module_consumed),
    ('K11-fact-count-mismatch', 'the two paths consuming different fact counts', f11_fact_count_mismatch),
    ('K12-family-digest-mismatch', 'equal counts but a different per-family digest', f12_family_digest_mismatch),
    ('K13-private-typo', 'a mistyped classification value (PRIVAT)', f13_private_typo),
    ('K14-unknown-consumer', 'an undeclared consumer (S99)', f14_unknown_consumer),
    ('K15-wrong-type-provides', 'a provides endpoint of the wrong kind', f15_wrong_type_provides),
    ('K16-root-digest-alone', 'the root digest changed without changing any pin', f16_root_digest_changed_alone),
    ('K17-duplicate-ledger-row', 'a duplicated deferred-ledger row', f17_duplicate_ledger_row),
    ('K18-missing-source-file', 'an absent migration source file', f18_missing_source_file),
    ('K19-restore-not-compare', 'inventory drift erased instead of compared', f19_restore_instead_of_compare),
    ('K20-packet-undercount', 'a decision-packet total that the model does not support', f20_packet_undercount),
    ('K21-self-certified-pass', 'a verdict issued without the other path present', f21_no_self_certified_pass),
    ('K22-unconsumed-syntax', 'canonical-model syntax no reader consumes', f22_unconsumed_syntax),
    ('K23-reader-injection', 'a read-time evaluation attempt in a module', f23_reader_injection),
    ('K24-crlf-text-hashing', 'pins computed with text-decoded hashing', f24_crlf_text_decoded_hash),
    ('K25-provider-unavailable', 'the vetted hash provider unavailable', f25_hash_provider_unavailable),
    # further held-out mutations, one per repaired invariant, independent of the literal list above
    ('X26-dead-rule', 'a classification rule that can never fire', f26_dead_classification_rule),
    ('X27-illegal-value-kind', 'a value of a kind the grammar forbids', f27_illegal_value_kind),
    ('X28-consumer-without-role', 'a type consuming without a declared consumer-role', f28_type_consumer_without_role),
    ('X29-generation-order-cycle', 'a cycle in the declared generation order', f29_generation_order_cycle),
    ('X30-unrecorded-normalization', 'a migration normalization with no ledger row', f30_unrecorded_normalization),
    ('X31-historical-on-live-path', 'historical code made a live dependency', f31_historical_code_on_live_path),
    ('X32-module-count-mismatch', 'a module count ROOT does not actually pin', f32_module_count_mismatch),
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
