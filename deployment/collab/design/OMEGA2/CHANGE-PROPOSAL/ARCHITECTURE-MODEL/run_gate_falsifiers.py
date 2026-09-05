#!/usr/bin/env python3
"""run_gate_falsifiers.py — the COMPOSED-GATE falsifier battery (Review-2 N-2).

Every falsifier before this one injected a defect and required an ISOLATED helper to reject it. That is not the
same claim as "the gate catches it", and the independent review proved the difference: the falsifier written for
"inventory drift is erased instead of compared" could not itself detect inventory drift being erased instead of
compared, because it never ran the composed gate.

Each falsifier here therefore:

  1. materialises the IMMUTABLE CANDIDATE TREE as a disposable, self-contained git repository — never the
     primary working tree, which this program does not write under any circumstance;
  2. injects exactly one defect into that disposable repository;
  3. runs `ARCHITECTURE-MODEL-GATE.sh` inside it, composed, end to end;
  4. requires the gate to FAIL, and to fail through the NAMED check that exists for that defect. A gate that
     fails for an unrelated reason has not demonstrated anything, so it counts as not rejected.

This battery is deliberately NOT run from inside the gate: a gate that ran it would recurse forever. It is run
by the acceptance battery, and `gate_checks.py corpus` asserts that the falsifiers the model declares for the
COMPOSED_GATE harness are exactly the ones implemented here.

Usage: run_gate_falsifiers.py [--list] [--only ID[,ID...]]
"""
import argparse, os, re, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..', '..', '..', '..'))
REL = os.path.relpath(HERE, REPO).replace(os.sep, '/')
GATE = 'ARCHITECTURE-MODEL-GATE.sh'
IDENT = ['-c', 'user.name=Stavropoulos Law®', '-c', 'user.email=info@stavropouloslaw.com']
# the fixed scratch paths the SUPERSEDED gate wrote to; G08 proves the corrected gate is indifferent to them
LEGACY_SCRATCH = ['/tmp/k.out', '/tmp/c.out', '/tmp/fx.out', '/tmp/fl.out', '/tmp/ov.bak', '/tmp/ddi.out']

RESULTS = []


def candidate_tree():
    r = subprocess.run([sys.executable, os.path.join(HERE, 'gate_checks.py'), 'candidate'],
                       capture_output=True, text=True, cwd=HERE)
    tree = next((l.split()[1] for l in r.stdout.splitlines() if l.startswith('CANDIDATE-TREE ')), None)
    if tree is None:
        raise RuntimeError('the candidate tree could not be resolved: %s' % (r.stdout + r.stderr)[-400:])
    return tree


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
    tree = candidate_tree()
    d = tempfile.mkdtemp(prefix='gfals-repo-')
    root = os.path.join(d, 'repo')
    subprocess.run(['git', 'init', '-q', root], check=True, capture_output=True)
    # Borrow the source repository's object store read-only. A plain local clone copies only REACHABLE
    # objects, and the candidate tree is deliberately unreferenced, so it would not come across.
    src_objects = os.path.join(subprocess.run(['git', '-C', REPO, 'rev-parse', '--absolute-git-dir'],
                                              check=True, capture_output=True, text=True).stdout.strip(),
                               'objects')
    with open(os.path.join(root, '.git', 'objects', 'info', 'alternates'), 'w', encoding='utf-8') as f:
        f.write(src_objects + '\n')
    for args in (['read-tree', tree], ['checkout-index', '-a', '-f']):
        subprocess.run(['git', '-C', root] + args, check=True, capture_output=True)
    commit = subprocess.run(['git', '-C', root] + IDENT + ['commit-tree', tree, '-m',
                                                           'candidate tree under audit'],
                            check=True, capture_output=True, text=True).stdout.strip()
    subprocess.run(['git', '-C', root, 'reset', '--hard', '-q', commit], check=True, capture_output=True)
    n = len(subprocess.run(['git', '-C', root, 'ls-files', '-z'], check=True,
                           capture_output=True).stdout.split(b'\0')) - 1
    m = len(subprocess.run(['git', '-C', REPO, 'ls-tree', '-r', '--name-only', '-z', tree], check=True,
                           capture_output=True).stdout.split(b'\0')) - 1
    if n != m:
        raise RuntimeError('the disposable repository holds %d paths, the candidate tree %d — a falsifier over '
                           'an incomplete copy would prove nothing' % (n, m))
    return d, root


def run_gate(root, env=None):
    seat = os.path.join(root, REL)
    r = subprocess.run(['bash', os.path.join(seat, GATE)], capture_output=True, text=True, cwd=seat,
                       env=env or os.environ.copy())
    return r.returncode, r.stdout + r.stderr


def seat_file(root, rel):
    return os.path.join(root, REL, rel)


def read(root, rel):
    with open(seat_file(root, rel), encoding='utf-8') as f:
        return f.read()


def write(root, rel, text):
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


def record(name, intent, ok_, detail):
    detail = detail if isinstance(detail, str) else repr(detail)
    RESULTS.append((name, intent, ok_, detail))
    print('%-30s %-64s %s' % (name, intent[:64], 'REJECTED as intended' if ok_ else 'NOT REJECTED - ' + detail))


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


# ═══════════════════════════════════════════════════════════════════════════ the composed-gate falsifiers
def g01_gate_writes_to_tree():
    """A gate that writes to the tree it audits must not be able to report PASS."""
    d, root = disposable_repo()
    try:
        gate = read(root, GATE)
        marker = 'export AML_CANDIDATE_TREE="$TREE"'
        if marker not in gate:
            return False, 'the gate no longer pins the candidate; this falsifier cannot be placed'
        write(root, GATE, gate.replace(
            marker, marker + '\nprintf "\\n<!-- the gate wrote here -->\\n" >> GENERATED/OWNERSHIP-MATRIX.md', 1))
        return gate_must_fail(root, 'ro-01-working-tree-byte-identical-after-the-run')
    finally:
        shutil.rmtree(d, ignore_errors=True)


def g02_pre_existing_drift_erased():
    """The exact Review-2 N-2 regression: a hand-edited generated artifact ALREADY in the candidate must be
    NAMED, not regenerated away before anything compares it. The superseded gate reported pass=20 fail=0."""
    d, root = disposable_repo()
    try:
        write(root, 'GENERATED/OWNERSHIP-MATRIX.md',
              read(root, 'GENERATED/OWNERSHIP-MATRIX.md') + '\n<!-- hand-edited after generation -->\n')
        return gate_must_fail(root, 'gen-02-artifacts-regenerate-byte-identical', 'ARTIFACT-DRIFT')
    finally:
        shutil.rmtree(d, ignore_errors=True)


def g03_artifact_deleted():
    """A declared generated artifact deleted from the tree — the superseded gate enumerated no members."""
    d, root = disposable_repo()
    try:
        os.remove(seat_file(root, 'GENERATED/DEPENDENCY-VIEW.md'))
        subprocess.run(['git', '-C', root, 'add', '-A'], check=True, capture_output=True)
        return gate_must_fail(root, 'art-01-generated-artifact-universe-is-exact', 'GENERATED-ARTIFACT-MISSING')
    finally:
        shutil.rmtree(d, ignore_errors=True)


def g04_artifact_undeclared():
    """An extra artifact produced into the generated seat that the model declares nowhere."""
    d, root = disposable_repo()
    try:
        write(root, 'GENERATED/UNDECLARED-EXTRA-VIEW.md',
              '# GENERATED — DO NOT EDIT\n\nAn artifact the model declares nowhere.\n')
        subprocess.run(['git', '-C', root, 'add', '-A'], check=True, capture_output=True)
        return gate_must_fail(root, 'art-01-generated-artifact-universe-is-exact',
                              'GENERATED-ARTIFACT-UNDECLARED')
    finally:
        shutil.rmtree(d, ignore_errors=True)


def g05_corpus_shrunk():
    """A held-out falsifier removed from the declared corpus. The superseded gate reported the smaller number
    as a success: `31 ... not-rejected=0` with the complete gate at pass=20 fail=0."""
    d, root = disposable_repo()
    try:
        corpus = read(root, 'verification-corpus.sexp')
        line = [l for l in corpus.splitlines() if l.startswith('(fact falsifier X32-')][0]
        write(root, 'verification-corpus.sexp', corpus.replace(line + '\n', '', 1))
        return gate_must_fail(root, 'cor-01-corpus-universe-is-exact', 'FALSIFIER-UNDECLARED')
    finally:
        shutil.rmtree(d, ignore_errors=True)


def g06_toolchain_identity():
    """A tool whose executable identity is not the pinned one. Nothing may be verified by an unpinned tool."""
    d, root = disposable_repo()
    try:
        # only the 64 hex digits change: the module must stay well-formed, or the gate would reject it as
        # unreadable and prove nothing about identity enforcement
        tc = read(root, 'TOOLCHAIN.sexp')
        mutated, n = re.subn(r'(:sha256 ")[0-9a-f]{64}(")', r'\g<1>' + '0' * 64 + r'\g<2>', tc, count=1)
        if n != 1:
            return False, 'no pinned :sha256 to repoint'
        write(root, 'TOOLCHAIN.sexp', mutated)
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
        subprocess.run(['git', '-C', root, 'add', '-A'], check=True, capture_output=True)
        # make the model internally consistent about the new file, and leave ONLY the ledger stale
        seat = os.path.join(root, REL)
        for producer in ('build_inventory.py', 'build_root.py', 'generate_views.py',
                         'build_decision_packet.py'):
            r = subprocess.run([sys.executable, producer], cwd=seat, capture_output=True, text=True)
            if r.returncode != 0:
                return False, 'the reproducer could not be prepared: %s exited %d' % (producer, r.returncode)
        subprocess.run(['git', '-C', root, 'add', '-A'], check=True, capture_output=True)
        return gate_must_fail(root, 'led-01-deferred-ledger-exact-source-universe', 'DEFERRED-IMPORT LEDGER: FAIL')
    finally:
        shutil.rmtree(d, ignore_errors=True)


def g08_tmp_collision():
    """A hostile pre-existing path at every scratch location the SUPERSEDED gate used.

    The corrected gate takes a private mode-0700 workspace from mktemp and holds no fixed path, so a defect must
    still be detected with all of those paths occupied by directories it cannot write. Both halves are asserted:
    no fixed scratch literal survives in the gate's own source, and detection is unaffected in practice.
    """
    gate_src = read_local(GATE)
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
            write(root, 'GENERATED/OWNERSHIP-MATRIX.md',
                  read(root, 'GENERATED/OWNERSHIP-MATRIX.md') + '\n<!-- hand-edited after generation -->\n')
            return gate_must_fail(root, 'gen-02-artifacts-regenerate-byte-identical', 'ARTIFACT-DRIFT')
        finally:
            shutil.rmtree(d, ignore_errors=True)
    finally:
        for p in made:                      # only what this run created; a pre-existing path is left alone
            try:
                os.rmdir(p)
            except OSError:
                pass


def read_local(rel):
    with open(os.path.join(HERE, rel), encoding='utf-8') as f:
        return f.read()


FALSIFIERS = [
    ('G01-GATE-WRITES-TO-TREE', 'the validation gate modifying the tree it audits', g01_gate_writes_to_tree),
    ('G02-PRE-EXISTING-DRIFT-ERASED', 'pre-existing drift regenerated away before comparison',
     g02_pre_existing_drift_erased),
    ('G03-ARTIFACT-DELETED', 'a declared generated artifact deleted from generator and tree', g03_artifact_deleted),
    ('G04-ARTIFACT-UNDECLARED', 'an undeclared artifact produced into the seat', g04_artifact_undeclared),
    ('G05-CORPUS-SHRUNK', 'a fixture, property family or falsifier silently removed', g05_corpus_shrunk),
    ('G06-TOOLCHAIN-IDENTITY', 'a tool whose executable identity is not the pinned one', g06_toolchain_identity),
    ('G07-UNADJUDICATED-SOURCE', 'a qualifying migration source absent from the ledger', g07_unadjudicated_source),
    ('G08-TMP-COLLISION', 'a hostile pre-existing path at a gate scratch location', g08_tmp_collision),
]

if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--list', action='store_true')
    ap.add_argument('--only', default=None, help='run only these ids, comma separated')
    a = ap.parse_args()
    if a.list:
        for n, i, _f in FALSIFIERS:
            print('%-30s %s' % (n, i))
        sys.exit(0)
    only = {x.strip().upper() for x in a.only.split(',')} if a.only else None
    okc, why = control_unmutated()
    print('%-30s %-64s %s' % ('CONTROL-UNMUTATED-GATE-PASSES', 'the gate passes when no defect is injected',
                              'CONTROL HOLDS' if okc else 'CONTROL BROKEN - ' + why))
    if not okc:
        print('composed-gate falsifiers=0 rejected-as-intended=0 not-rejected=0 BATTERY-VACUOUS')
        sys.exit(2)
    for name, intent, fn in FALSIFIERS:
        if only and name.upper() not in only:
            continue
        try:
            okk, detail = fn()
        except Exception as e:                      # a falsifier must never pass by crashing
            okk, detail = False, 'harness error: %r' % (e,)
        record(name, intent, okk, detail)
    bad = [r for r in RESULTS if not r[2]]
    print('composed-gate falsifiers=%d rejected-as-intended=%d not-rejected=%d'
          % (len(RESULTS), len(RESULTS) - len(bad), len(bad)))
    for r in bad:
        print('  NOT REJECTED: %s — %s — %s' % (r[0], r[1], r[3]))
    sys.exit(0 if not bad else 1)
