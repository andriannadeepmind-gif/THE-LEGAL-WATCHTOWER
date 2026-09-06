#!/usr/bin/env python3
"""gate_checks.py — the model-derived gate checks, in one seat, over an IMMUTABLE CANDIDATE TREE.

A shell gate can honestly orchestrate, run tools and compare exit codes. It cannot honestly decide whether a
document agrees with the model: `grep` finding an expected phrase in prose the repository itself wrote proves
only that the phrase is there. Every check that needs the MODEL to answer lives here, derives its answer from the
canonical facts, and names what disagreed.

REVIEW-2 N-2 / N-14 — WHY THERE IS A CANDIDATE TREE. The previous gate ran the five in-place producers BEFORE it
compared anything, so a pre-existing edit to any generated artifact was overwritten and the run then reported
`pass=20 fail=0` having named nothing; and its drift measure was a porcelain-column regex that could not see the
index at all. Both are structural, so both are fixed structurally:

  * every check reads the candidate from an immutable git TREE object, exported once into a private workspace.
    Nothing here reads the working tree except to REPORT pre-existing drift, and nothing here ever writes to it;
  * generation happens inside that workspace and is byte-compared against the candidate tree's own blobs. The
    artifact under judgement is never the artifact that was just written.

`regenerate.py` — a separate, explicitly invoked command that the gate never calls — is the only thing that
copies verified output back into the working tree.

Checks (each prints GATECHECK <name>: PASS|FAIL and exits 0/1):

  candidate           resolve and print the immutable candidate tree, and report (without touching) any
                      pre-existing difference between the working tree and that candidate.
  toolchain           every `tool` fact is enforced before any verifier runs: the executable exists at its
                      declared path, its digest equals the pin, and its semantic version equals the declared one.
                      No tool measures itself — each is measured by the engine of the OTHER verification path.
  generation          run the model-declared generation order inside a PRIVATE copy of the workspace and
                      byte-compare every declared artifact against the candidate tree. Nothing is restored
                      before it is compared, and the copy every other check reads is never written.
  inventory           the inventory equals the candidate tree's tracked universe: key set both ways, per
                      (top, rule) directory-rule counts re-derived, multiset total, no C-quoted key.
  artifacts           EXACT set equality between the model's declared generated-artifact universe and what the
                      candidate tree actually contains under the seat. Missing, extra and renamed all fail.
  corpus              EXACT set equality between the declared fixture / property-family / falsifier universe and
                      what is implemented and present, with declared cardinalities enforced.
  seats               every BUILT or DOCUMENT_SEAT seat resolves to a real path of the candidate tree.
  conflict-ledger     reconcile MODEL-MIGRATION-CONFLICT-LEDGER.md against the model IN BOTH DIRECTIONS.
  packet              recompute the decision packet's totals from the model and require its machine-readable
                      reconciliation block to match them, both verification commitments, and the authority split.
  dependency-closure  the real executable closure of every governance entrypoint, computed transitively, must
                      equal the declared manifest and must contain no file classified HISTORICAL_EVIDENCE.
  hash-engines        the two vetted SHA-256 engines must agree over identical RAW BYTES for every pinned module
                      and for adversarial inputs — CRLF, lone CR, a UTF-8 BOM and bytes that are not valid UTF-8.
  tcb                 the acceptance trusted computing base, re-derived from the candidate by file KIND (never
                      by role name), matched against the measurement the model records, and held under the cap
                      authored in a different module from the one that counts it.
"""
import argparse, ast, hashlib, importlib.util, json, os, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
# The seat's path INSIDE the repository is a property of the layout, not of where this file happens to sit:
# ACCEPT.sh executes this machinery from an export of the candidate, and AML_REPO then names the real
# repository. Deriving REL from AML_REPO would have produced a '../..'-laden path and matched nothing.
LAYOUT_ROOT = os.path.abspath(os.path.join(HERE, '..', '..', '..', '..', '..', '..'))
REL = os.path.relpath(HERE, LAYOUT_ROOT).replace(os.sep, '/')
REPO = os.environ.get('AML_REPO') or LAYOUT_ROOT
CPREL = os.path.dirname(REL)
_spec = importlib.util.spec_from_file_location('sexp_reader', os.path.join(HERE, 'SEXP-READER.py'))
SR = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(SR)
_aspec = importlib.util.spec_from_file_location('acceptance_runtime', os.path.join(HERE, 'acceptance_runtime.py'))
AR = importlib.util.module_from_spec(_aspec); _aspec.loader.exec_module(AR)

SEAT = None          # the exported candidate seat directory; every check reads the model from here
TREE = None          # the immutable candidate tree object


def fail(name, reasons):
    for r in reasons:
        print('  %s' % r)
    print('GATECHECK %s: FAIL (%d finding%s)' % (name, len(reasons), '' if len(reasons) == 1 else 's'))
    sys.exit(1)


def ok(name, note):
    print('GATECHECK %s: PASS — %s' % (name, note))
    sys.exit(0)


GIT_ENV = dict(os.environ, GIT_OPTIONAL_LOCKS='0')   # Review-3 R3-9: never write .git/index.lock while reading


def git(*args, binary=False):
    r = AR.bounded_run(['git', '-C', REPO] + list(args), env=GIT_ENV, timeout=900, text=False)
    if r.returncode != 0:
        raise SystemExit('git %s failed: %s' % (' '.join(args), r.stderr.decode('utf-8', 'replace')))
    return r.stdout if binary else r.stdout.decode('utf-8')


def candidate_tree(rev):
    """Resolve, once, the IMMUTABLE tree object this run judges. One seat; every check reads only its blobs.

    A named revision (`HEAD`, a tag, a tree sha) resolves directly. The sentinel `WORKTREE` builds the tree the
    current state WOULD commit to, through a THROWAWAY index copied from the real one and refreshed for tracked
    paths only: no ref moves, nothing is checked out, the real index is never written, and an untracked path is
    never staged by the gate — a file joins the candidate by being tracked or already staged, and until then
    `candidate` names it as a working-tree difference instead of quietly judging it. In a clean checkout the two
    forms coincide, which is why the fresh-clone gate and the pre-commit gate ask the same question.
    """
    if rev != 'WORKTREE':
        return git('rev-parse', rev).strip()
    gitdir = git('rev-parse', '--absolute-git-dir').strip()
    d = tempfile.mkdtemp(prefix='aml-cand-')
    try:
        idx = os.path.join(d, 'index')
        shutil.copyfile(os.path.join(gitdir, 'index'), idx)
        env = dict(os.environ, GIT_INDEX_FILE=idx)
        for args in (['add', '-u'], ['write-tree']):
            r = AR.bounded_run(['git', '-C', REPO] + args, capture_output=True, text=True, env=env)
            if r.returncode != 0:
                raise SystemExit('CANDIDATE-TREE-FAILED: git %s: %s' % (args[0], r.stderr.strip()))
        return r.stdout.strip()
    finally:
        shutil.rmtree(d, ignore_errors=True)


def tree_paths():
    return [b.decode('utf-8') for b in git('ls-tree', '-r', '--name-only', '-z', TREE, binary=True).split(b'\0') if b]


def tree_blob(path):
    """The candidate tree's bytes for PATH, or None if the candidate does not contain it."""
    r = AR.bounded_run(['git', '-C', REPO, 'cat-file', 'blob', '%s:%s' % (TREE, path)], text=False, env=GIT_ENV)
    return r.stdout if r.returncode == 0 else None


def ensure_seat(work):
    """Export the candidate change-proposal subtree once into WORK/cand and return its ARCHITECTURE-MODEL dir."""
    global SEAT
    cand = os.path.join(work, 'cand')
    seat = os.path.join(cand, REL)
    if not os.path.isdir(seat):
        os.makedirs(cand, exist_ok=True)
        tar = AR.checked(['git', '-C', REPO, 'archive', TREE, CPREL], capture_output=True).stdout
        AR.checked(['tar', '-x', '-C', cand], input=tar)
    SEAT = seat
    return seat


# --------------------------------------------------------------------------- model access (candidate only)
# One seat reads the model (SEXP-READER.read_model); this only types its failures for the gate's vocabulary.
def model():
    try:
        return SR.read_model(SEAT)
    except SR.MissingSourceFile as e:                          # Review-2 N-17: typed, never a traceback
        raise SystemExit('MISSING-MODEL-FILE: %s' % e.path)
    except SR.SexpError as e:
        raise SystemExit('UNREADABLE-MODEL-FILE: %s' % e)


def modules():
    m = model()
    return m.modules, m.root


def facts():
    return [(t, i, p) for t, i, p, _mod, _form in model().facts]


def by_type(fs):
    d = {}
    for t, i, p in fs:
        d.setdefault(t, []).append((i, p))
    return d


# --------------------------------------------------------------------------- candidate
def working_tree_difference():
    """Every path where the WORKING TREE differs from the candidate this run judges — measured against the
    candidate tree itself, not against HEAD or the index, so the report cannot claim agreement it does not have.
    Read-only: `git diff` here is a comparison, never a restore."""
    drift = [('%s %s' % (l.split('\t')[0], l.split('\t', 1)[1])).strip()
             for l in git('diff', '--name-status', TREE, '--').splitlines() if l.strip()]
    drift += ['?? %s' % p for p in git('ls-files', '--others', '--exclude-standard').splitlines() if p.strip()]
    return sorted(drift)


def repository_content_state():
    """A CONTENT hash of everything in the repository this run could disturb — the one seat, Review-3 R3-9."""
    return AR.repo_content_state(REPO, candidate_tree('WORKTREE'))


def check_candidate():
    paths = tree_paths()
    drift = working_tree_difference()
    print('CANDIDATE-TREE %s' % TREE)
    print('CANDIDATE-SEAT %s' % SEAT)
    print('CANDIDATE-REL %s' % REL)
    print('  candidate tree: %s (%d paths)' % (TREE, len(paths)))
    if drift:
        print('  the WORKING TREE differs from the candidate in %d path(s); the gate judges the candidate and '
              'changes nothing:' % len(drift))
        for l in drift[:20]:
            print('    %s' % l)
    ok('candidate', 'immutable candidate tree %s pinned; %d tracked paths; working-tree difference measured '
                    'against that very tree and reported, not altered (%d path(s))'
                    % (TREE[:12], len(paths), len(drift)))


# --------------------------------------------------------------------------- toolchain (N-11)
def sha_bytes(b):
    return hashlib.sha256(b).hexdigest()


def coreutils_digest(tool, path):
    r = AR.bounded_run([tool, '--binary', '--', path], capture_output=True)
    return r.stdout[:64].decode('ascii') if r.returncode == 0 else None


def check_toolchain():
    reasons, bt = [], by_type(facts())
    tools = {i: p for i, p in bt.get('tool', [])}
    if not tools:
        fail('toolchain', ['the model declares no tool facts; nothing pins what the verifiers may execute'])
    digest_tool = next((p['path'] for p in tools.values() if p.get('role') == 'DIGEST_PROVIDER'), None)
    if not digest_tool or not os.path.isfile(digest_tool):
        fail('toolchain', ['the declared DIGEST_PROVIDER is absent; the Common Lisp path has no SHA-256 engine'])
    for tid in sorted(tools):
        p = tools[tid]
        path = p['path']
        if not os.path.isfile(path):
            reasons.append('TOOLCHAIN-MISSING: %s declares %s, which does not exist' % (tid, path)); continue
        with open(path, 'rb') as f:
            by_python = sha_bytes(f.read())
        by_coreutils = coreutils_digest(digest_tool, path)
        # each tool is measured by the OTHER path's engine; a tool never certifies itself
        measured = by_python if p.get('verified-by') == 'CHECKER_PATH' else by_coreutils
        if measured is None:
            reasons.append('TOOLCHAIN-UNMEASURED: %s could not be digested by its declared verifier' % tid); continue
        if measured != p['sha256']:
            reasons.append('TOOLCHAIN-IDENTITY-MISMATCH: %s at %s is %s, TOOLCHAIN.sexp pins %s'
                           % (tid, path, measured[:16], p['sha256'][:16]))
        if by_python and by_coreutils and by_python != by_coreutils:
            reasons.append('ENGINE-DISAGREEMENT: the two engines disagree on %s' % path)
        got = observed_version(tid, p)
        if got is not None and p['semantic-version'] not in got:
            reasons.append('TOOLCHAIN-VERSION-MISMATCH: %s reports %r, TOOLCHAIN.sexp requires %s'
                           % (tid, got.strip(), p['semantic-version']))
    # Review-3 R3-3. Measuring the pinned FILE is not the same claim as executing it. The superseded check said
    # "5 declared tools verified" while itself running inside a PATH wrapper, and named nothing about the
    # interpreter that actually ran. What executed is therefore established and PRINTED, not inferred.
    executed = []
    me = os.path.realpath(sys.executable)
    for tid in sorted(tools):
        p = tools[tid]
        if p.get('role') == 'CHECKER_RUNTIME' and me != os.path.realpath(p['path']):
            reasons.append('EXECUTED-IS-NOT-PINNED: this process is running %s, but %s pins %s; a wrapper earlier '
                           'on PATH would otherwise be invisible' % (me, tid, os.path.realpath(p['path'])))
        if p.get('role') == 'ASP_SOLVER':
            r = AR.bounded_run([tool_path('CHECKER_RUNTIME'), '-c',
                                'import clingo, clingo._clingo as c, os; print(os.path.realpath(c.__file__))'],
                               capture_output=True, text=True, timeout=120)
            got = r.stdout.strip()
            if got != os.path.realpath(p['path']):
                reasons.append('EXECUTED-IS-NOT-PINNED: the imported solver extension is %r, but %s pins %s'
                               % (got or r.stderr.strip()[:60], tid, os.path.realpath(p['path'])))
        with open(p['path'], 'rb') as f:
            executed.append('%s realpath=%s sha256=%s version=%s'
                            % (tid, os.path.realpath(p['path']), sha_bytes(f.read())[:16],
                               (observed_version(tid, p) or '?').strip().splitlines()[0][:40]))
    if reasons:
        fail('toolchain', reasons)
    for line in executed:
        print('  EXECUTED %s' % line)
    print('  BOOTSTRAP-TCB (unpinned BY CONSTRUCTION, trusted before this check can run, and an EXTERNAL '
          'ASSUMPTION rather than anything this gate proves): bash, coreutils (mktemp/chmod/sed/grep/awk/cmp/'
          'sha256sum), git, tar, the dynamic loader and every shared library each binary maps. The interpreter '
          'is NOT in this layer when the gate started it: the gate lifts the pinned absolute path out of '
          'TOOLCHAIN.sexp with awk and executes that, so a python3 planted earlier on PATH is not invoked at '
          'all. It IS in this layer when a person runs a program of this seat directly. The mutual '
          'certification of sha256sum and hashlib is a two-cycle: it is consistency, not an external root.')
    ok('toolchain', '%d declared tools verified before any verdict — path, exact executable digest measured by '
                    'the other path\'s engine, semantic version — and the process that is running plus the '
                    'solver extension actually imported are the pinned ones; the bootstrap layer above is '
                    'declared, not claimed to be verified' % len(tools))


def observed_version(tid, p):
    """What the tool ITSELF reports, so a pinned digest and a self-reported version must agree."""
    try:
        if p.get('role') == 'KERNEL_RUNTIME':
            return AR.bounded_run([p['path'], '--version'], capture_output=True, text=True, timeout=60).stdout
        if p.get('role') == 'DIGEST_PROVIDER':
            return AR.bounded_run([p['path'], '--version'], capture_output=True, text=True, timeout=60).stdout
        if p.get('role') == 'CHECKER_RUNTIME':
            return AR.bounded_run([p['path'], '-c', 'import sys;print(sys.version.split()[0])'],
                                  capture_output=True, text=True, timeout=60).stdout
        if p.get('role') == 'ASP_SOLVER':
            return AR.bounded_run([sys.executable, '-c', 'import clingo;print(clingo.__version__)'],
                                  capture_output=True, text=True, timeout=60).stdout
        if p.get('role') == 'CHECKER_DIGEST_PROVIDER':
            return AR.bounded_run([sys.executable, '-c', 'import ssl;print(ssl.OPENSSL_VERSION)'],
                                  capture_output=True, text=True, timeout=60).stdout
    except Exception:
        return None
    return None


# --------------------------------------------------------------------------- generation (N-2, N-3)
PRODUCER_ARGS = {'build_inventory.py': ['--repo', REPO, '--tree', 'CAND', '--out', 'SEAT/files-and-roles.sexp']}


def generation_workspace(work):
    """A PRIVATE copy of the candidate for the ONE check that must run producers.

    Review-2 N-2, applied inside the gate as well as outside it: the shared export every other check reads is
    never written. Without this, `generation` would regenerate the seat that `inventory`, `corpus`, `packet` and
    the ledger verification read afterwards, and each of them would then be inspecting bytes an earlier check
    had just produced rather than the bytes of the candidate under judgement.
    """
    if not SEAT.endswith(REL):
        raise SystemExit('SEAT-LAYOUT: the exported seat %r does not end in %r' % (SEAT, REL))
    cand_root = SEAT[:-(len(REL) + 1)]
    gen_root = os.path.join(work, 'gen')
    shutil.rmtree(gen_root, ignore_errors=True)
    shutil.copytree(cand_root, gen_root)
    return os.path.join(gen_root, REL)


def check_generation(work):
    reasons = []
    seat = generation_workspace(work)
    for producer in producers_in_order(by_type(facts())):
        args = [sys.executable, os.path.join(seat, producer)]
        if producer == 'build_inventory.py':
            args += ['--repo', REPO, '--tree', TREE, '--out', os.path.join(seat, 'files-and-roles.sexp')]
        # CLOSURE-BOUND: gen-step.producer — the only programs run here are the model's declared producers
        r = AR.bounded_run(args, capture_output=True, text=True, cwd=seat)
        if r.returncode != 0:
            fail('generation', ['producer %s exited %d inside the workspace' % (producer, r.returncode)]
                 + ['  %s' % l for l in (r.stdout + r.stderr).strip().splitlines()[-6:]])
    declared = {i: p['path'] for i, p in by_type(facts()).get('gen-artifact', [])}
    for aid in sorted(declared):
        rel = declared[aid]
        produced_path = os.path.join(seat, rel)
        candidate = tree_blob('%s/%s' % (REL, rel))
        if not os.path.isfile(produced_path):
            reasons.append('ARTIFACT-NOT-PRODUCED: %s (%s) was declared but the generation order did not '
                           'produce it' % (aid, rel)); continue
        with open(produced_path, 'rb') as f:
            produced = f.read()
        if candidate is None:
            reasons.append('ARTIFACT-ABSENT-FROM-CANDIDATE: %s (%s) is declared and produced but the candidate '
                           'tree does not contain it' % (aid, rel))
        elif produced != candidate:
            reasons.append('ARTIFACT-DRIFT: %s (%s) regenerates to %d bytes but the candidate holds %d; the '
                           'committed artifact is stale' % (aid, rel, len(produced), len(candidate)))
    if reasons:
        fail('generation', reasons)
    ok('generation', '%d model-declared artifacts regenerated in an isolated workspace and byte-identical to the '
                     'candidate tree; the working tree was neither read for this nor written' % len(declared))


def topological_order(bt):
    steps = {i: p for i, p in bt.get('gen-step', [])}
    edges = [(p['from'], p['to']) for _i, p in bt.get('gen-edge', [])]
    indeg = {s: 0 for s in steps}
    adj = {s: [] for s in steps}
    for a, b in edges:
        if a not in steps or b not in steps:
            raise SystemExit('GEN-EDGE-DANGLING: %s -> %s' % (a, b))
        adj[a].append(b); indeg[b] += 1
    order, ready = [], sorted(s for s in steps if indeg[s] == 0)
    while ready:
        u = ready.pop(0); order.append(u)
        for w in sorted(adj[u]):
            indeg[w] -= 1
            if indeg[w] == 0:
                ready.append(w); ready.sort()
    if len(order) != len(steps):
        raise SystemExit('GEN-ORDER-CYCLIC: %s cannot be sequenced' % sorted(set(steps) - set(order)))
    return order


def producers_in_order(bt):
    steps = {i: p for i, p in bt.get('gen-step', [])}
    return [steps[s]['producer'] for s in topological_order(bt)]


def check_generation_order():
    """The declared order is total, acyclic, and made of programs that exist — checked without running any of
    them, so a broken order is named here rather than discovered as a hang or a half-written artifact."""
    reasons, bt = [], by_type(facts())
    steps = {i: p for i, p in bt.get('gen-step', [])}
    if not steps:
        fail('generation-order', ['the model declares no generation step; nothing derives the artifacts'])
    order = topological_order(bt)          # raises a typed GEN-EDGE-DANGLING / GEN-ORDER-CYCLIC on a bad graph
    seen = {}
    for sid, p in sorted(steps.items()):
        producer = p['producer']
        if not os.path.isfile(os.path.join(SEAT, producer)):
            reasons.append('GEN-PRODUCER-MISSING: step %s declares %s, which the candidate tree does not hold'
                           % (sid, producer))
        if producer in seen:
            reasons.append('GEN-PRODUCER-SHARED: %s is declared by both %s and %s; one producer, one step'
                           % (producer, seen[producer], sid))
        seen[producer] = sid
    produced = {}
    for aid, p in bt.get('gen-artifact', []):
        produced.setdefault(p['step'], []).append(aid)
    for sid in sorted(steps):
        if sid not in produced:
            reasons.append('GEN-STEP-PRODUCES-NOTHING: step %s is declared but no gen-artifact names it; a step '
                           'whose output is undeclared cannot be compared' % sid)
    if len(order) != len(steps):
        reasons.append('GEN-ORDER-INCOMPLETE: %d steps declared, %d orderable' % (len(steps), len(order)))
    if reasons:
        fail('generation-order', reasons)
    ok('generation-order', 'the declared order is total and acyclic over %d steps (%s), every producer exists in '
                           'the candidate tree, no producer is shared, and every step declares its output'
       % (len(steps), ' -> '.join(order)))


# --------------------------------------------------------------------------- artifacts (N-3)
def check_artifacts():
    reasons = []
    declared = {p['path']: i for i, p in by_type(facts()).get('gen-artifact', [])}
    # Review-3 R3-6: a declared destination that is not contained is a named failure BEFORE anything is written
    for rel, aid in sorted(declared.items()):
        try:
            SR.contained_path(SEAT, rel, 'gen-artifact %s :path' % aid)
        except SR.UncontainedPath as e:
            reasons.append('UNCONTAINED-ARTIFACT-PATH: %s' % e)
    # Review-3 R3-11: the generated roots are enumerated WHOLE. The old check filtered on .md/.sexp, so
    # `GENERATED/evil.py` — arbitrary code sitting in the generated seat — was invisible to the very check whose
    # PASS line says "no extra". A root is any directory a declared artifact lives in under the seat.
    roots = sorted({os.path.dirname(p) + '/' for p in declared if '/' in p})
    present = {p[len(REL) + 1:] for p in tree_paths() if p.startswith(REL + '/')}
    derived_present = {p for p in present if any(p.startswith(r) for r in roots)}
    derived_declared = {p for p in declared if any(p.startswith(r) for r in roots)}
    for p in sorted(derived_declared - derived_present):
        reasons.append('GENERATED-ARTIFACT-MISSING: %s is declared by the model but absent from the candidate '
                       'tree' % p)
    for p in sorted(derived_present - derived_declared):
        reasons.append('GENERATED-ARTIFACT-UNDECLARED: %s exists under GENERATED/ but the model declares no '
                       'gen-artifact for it' % p)
    for p in sorted(declared):
        if not p.startswith('GENERATED/') and tree_blob('%s/%s' % (REL, p)) is None:
            reasons.append('DECLARED-ARTIFACT-MISSING: %s is declared but the candidate tree does not hold it' % p)
    if reasons:
        fail('artifacts', reasons)
    ok('artifacts', 'the model declares %d generated artifacts, %d of them under the %d generated root(s) %s, '
                    'and the candidate tree holds exactly those and nothing else there — every file counted '
                    'whatever its extension; every declared destination is contained'
       % (len(declared), len(derived_declared), len(roots), ', '.join(roots)))


# --------------------------------------------------------------------------- corpus (N-4)
def check_corpus():
    reasons, bt = [], by_type(facts())
    declared_fx = {i: p for i, p in bt.get('fixture', [])}
    for fid in sorted(declared_fx):
        rel = declared_fx[fid]['path']
        if tree_blob('%s/%s' % (REL, rel)) is None:
            reasons.append('FIXTURE-MISSING: %s declares %s, absent from the candidate tree' % (fid, rel))
    present_fx = {p[len(REL) + 1:] for p in tree_paths()
                  if p.startswith(REL + '/FIXTURES/') and p.endswith('.sexp')}
    for rel in sorted(present_fx - {p['path'] for p in declared_fx.values()}):
        reasons.append('FIXTURE-UNDECLARED: %s exists but no fixture fact declares it' % rel)
    # The falsifier universe must equal what is actually implemented, PER HARNESS. Which program runs which
    # class is model data (`harness` facts), so renaming or losing a runner is a closed-reference violation
    # rather than a check that quietly inspects a file nobody writes any more.
    harnesses = {i: p['runner'] for i, p in bt.get('harness', [])}
    declared_fl = {}
    for i, p in bt.get('falsifier', []):
        declared_fl.setdefault(p['harness'], set()).add(i.upper())
    for h in sorted(set(declared_fl) | set(harnesses)):
        if h not in harnesses:
            reasons.append('HARNESS-UNDECLARED: falsifiers cite harness %s, which no harness fact declares' % h)
            continue
        runner = harnesses[h]
        if tree_blob('%s/%s' % (REL, runner)) is None:
            reasons.append('HARNESS-RUNNER-MISSING: harness %s declares %s, absent from the candidate tree'
                           % (h, runner))
            continue
        # ids are compared on the CANONICAL rendering (symbols render upper-case), so the model and the runner
        # cannot disagree merely about letter case
        # a falsifier the model declares WITH a mutation is implemented by the runner's driver, not by a
        # function of its own — that is the point of moving the cases into data (Review-3 §15)
        impl = {i.upper() for i in implemented_falsifiers(runner, h)}
        impl |= {i.upper() for i, q in bt.get('falsifier', []) if q.get('mutation') and q['harness'] == h}
        for i in sorted(declared_fl.get(h, set()) - impl):
            reasons.append('FALSIFIER-NOT-IMPLEMENTED: %s is declared for harness %s but %s does not implement '
                           'it' % (i, h, runner))
        for i in sorted(impl - declared_fl.get(h, set())):
            reasons.append('FALSIFIER-UNDECLARED: %s implements %s but the model declares no such falsifier for '
                           'harness %s' % (runner, i, h))
    fams = {i: p for i, p in bt.get('property-family', [])}
    if not fams:
        reasons.append('NO-PROPERTY-FAMILY: the corpus declares no generated property family')
    for fid in sorted(fams):
        if int(fams[fid]['cardinality']) <= 0:
            reasons.append('EMPTY-PROPERTY-FAMILY: %s declares cardinality %s; a family that generates no case '
                           'is not a family' % (fid, fams[fid]['cardinality']))
    if reasons:
        fail('corpus', reasons)
    total = sum(int(p['cardinality']) for p in fams.values())
    nfl = sum(len(v) for v in declared_fl.values())
    ok('corpus', '%d fixtures, %d property families totalling %d generated cases, and %d falsifiers across %d '
                 'declared harnesses (%s) — declared set equals implemented set in both directions'
       % (len(declared_fx), len(fams), total, nfl, len(harnesses),
          ', '.join('%s %d' % (h, len(declared_fl.get(h, ()))) for h in sorted(harnesses))))


def implemented_falsifiers(runner, harness):
    """The falsifier ids RUNNER registers in code for HARNESS, read from its AST — no import, no execution.
    Cases the model declares as a mutation are implemented by the runner's driver and are counted separately."""
    path = os.path.join(SEAT, runner)
    if not os.path.isfile(path):
        return set()
    tree = ast.parse(open(path, encoding='utf-8').read(), filename=runner)
    want = 'CODED_COMPONENT' if harness == 'COMPONENT' else 'COMPOSED'
    out = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign) and any(getattr(t, 'id', None) == want for t in node.targets):
            for elt in getattr(node.value, 'elts', []):
                if isinstance(elt, ast.Tuple) and elt.elts and isinstance(elt.elts[0], ast.Constant):
                    out.add(str(elt.elts[0].value))
    return out


def machinery_set():
    """The acceptance machinery, AS THE MODEL DECLARES IT — every file the inventory classifies
    GOVERNANCE_MACHINERY inside this seat. There is no second, hand-written list to drift from."""
    return sorted(p[len(REL) + 1:] for p, r in role_map().items()
                  if r == 'GOVERNANCE_MACHINERY' and p.startswith(REL + '/'))


def check_provenance():
    """What is JUDGING must be the candidate's own machinery, and it must be bound and shown.

    Review-3 R3-2 (P1). In tree-ish mode the gate judged an immutable candidate with the WORKING TREE's tools:
    tampering `check_artifacts` into an unconditional pass turned a genuinely broken tree into
    `GATECHECK artifacts: PASS`, while `candidate` printed the drift INSIDE that pass. Two things are therefore
    established here, before any other check may report anything:

      * the machinery actually EXECUTING (this copy, resolved from this file's own directory) is byte-identical
        to the candidate's blobs — under ACCEPT.sh that copy IS an export of the candidate tree;
      * the repository's working tree carries the same bytes for that machinery, so an invocation from a
        tampered checkout is a named failure rather than a silent qualifier.

    Missing, extra and different are each named. A drift here can never be reported as informational.
    """
    reasons, rows = [], []
    machinery = machinery_set()
    if not machinery:
        fail('provenance', ['the model classifies no GOVERNANCE_MACHINERY in this seat; nothing could be bound'])
    for rel in machinery:
        blob = tree_blob('%s/%s' % (REL, rel))
        if blob is None:
            reasons.append('VERIFIER-MISSING-FROM-CANDIDATE: %s is machinery but the candidate tree lacks it' % rel)
            continue
        want = hashlib.sha256(blob).hexdigest()
        rows.append('%s %s' % (rel, want))
        for label, base in (('executing', HERE), ('working-tree', os.path.join(REPO, REL))):
            path = os.path.join(base, rel)
            if not os.path.isfile(path):
                reasons.append('VERIFIER-ABSENT: the %s copy has no %s' % (label, rel)); continue
            with open(path, 'rb') as f:
                got = hashlib.sha256(f.read()).hexdigest()
            if got != want:
                reasons.append('VERIFIER-DIFFERS: the %s copy of %s is %s, the candidate holds %s — a mismatched '
                               'verifier/candidate pair must not produce an unqualified PASS'
                               % (label, rel, got[:12], want[:12]))
    for base, label in ((HERE, 'executing'), (os.path.join(REPO, REL), 'working-tree')):
        classified = {p[len(REL) + 1:] for p in role_map() if p.startswith(REL + '/')}
        for f in sorted(os.listdir(base)):
            if f.endswith(('.py', '.sh')) and f not in machinery and f not in classified \
               and os.path.isfile(os.path.join(base, f)):
                reasons.append('VERIFIER-EXTRA: the %s copy holds executable %s, which the model classifies as '
                               'nothing at all' % (label, f))
    verifier_tree = hashlib.sha256('\n'.join(rows).encode('utf-8')).hexdigest()
    print('PROVENANCE candidate_commit %s' % git('rev-parse', 'HEAD').strip())
    print('PROVENANCE candidate_tree   %s' % TREE)
    print('PROVENANCE verifier_tree    %s  (%d machinery files)' % (verifier_tree, len(machinery)))
    for r in rows:
        print('PROVENANCE verifier-file    %s' % r)
    if reasons:
        fail('provenance', reasons)
    ok('provenance', 'the %d acceptance-machinery files the model declares are byte-identical in the candidate '
                     'tree, in the copy that is executing and in the repository working tree; verifier_tree '
                     '%s == candidate_tree %s for that set' % (len(machinery), verifier_tree[:12], TREE[:12]))


def check_universe():
    """No declared family may shrink below its constitutional floor without a typed authorization.

    Review-3 R3-7. An INCOHERENT deletion was already caught in both directions. A COHERENT one — the fact and
    its implementation removed together — was not: dropping a whole property family reported
    `4 property families totalling 75 generated cases` as a PASS, and nothing said the universe had shrunk. The
    floor is model data; going below it is a named failure; lowering the floor is itself a model edit that must
    carry a `universe-authorization` naming who decided it, against which model root, and why.
    """
    reasons, bt = [], by_type(facts())
    floors = {i: p for i, p in bt.get('universe-floor', [])}
    if not floors:
        fail('universe', ['the model declares no universe-floor; a family could shrink to nothing silently'])
    auths = {}
    for i, p in bt.get('universe-authorization', []):
        auths.setdefault(p['family'], []).append((i, p))
    _mods, rootpl = modules()
    root_now = str(rootpl['canonical-model-root-digest'])
    for fid in sorted(floors):
        fam, low = floors[fid]['family'], int(floors[fid]['minimum'])
        actual = len(bt.get(fam.lower(), []))
        if actual < low:
            reasons.append('UNIVERSE-BELOW-FLOOR: family %s holds %d fact(s), below its declared floor of %d '
                           '(%s); a smaller universe is not a smaller success' % (fam, actual, low, fid))
    for fam in sorted(auths):
        for aid, p in auths[fam]:
            if int(p['minimum']) >= int(p['previous-minimum']):
                reasons.append('AUTHORIZATION-NOT-A-REDUCTION: %s records %s -> %s, which is not a reduction'
                               % (aid, p['previous-minimum'], p['minimum']))
            prev = str(p['previous-model-root'])
            if len(prev) != 64 or any(c not in '0123456789abcdef' for c in prev) or prev == root_now:
                reasons.append('AUTHORIZATION-ROOT-SHAPE: %s names :previous-model-root %r, which is not a '
                               'distinct 64-character lower-case model root' % (aid, prev[:16]))
            if fam not in {floors[f]['family'] for f in floors}:
                reasons.append('AUTHORIZATION-UNKNOWN-FAMILY: %s authorizes %s, which declares no floor'
                               % (aid, fam))
    if reasons:
        fail('universe', reasons)
    ok('universe', '%d declared families are at or above their constitutional floor (%s); %d recorded '
                   'universe-authorization(s), each a reduction against a distinct previous model root'
       % (len(floors), ', '.join('%s>=%s' % (floors[f]['family'], floors[f]['minimum']) for f in sorted(floors)),
          sum(len(v) for v in auths.values())))


# --------------------------------------------------------------------------- seats (N-10)
def check_seats():
    reasons, bt = [], by_type(facts())
    tracked = set(tree_paths())
    seats = {i: p for i, p in bt.get('seat', [])}
    resolved = 0
    for sid in sorted(seats):
        p = seats[sid]
        if p['status'] in ('BUILT', 'DOCUMENT_SEAT'):
            path = p.get('path')
            if path not in tracked:
                reasons.append('SEAT-PATH-NOT-TRACKED: %s declares %s = %r, which is not a path of the candidate '
                               'tree' % (sid, p['status'], path))
            else:
                resolved += 1
    referenced = set()
    for _i, p in bt.get('subsystem', []):
        referenced.add(p['owner-seat'])
    for _i, p in bt.get('store', []):
        referenced.add(p['owner']); referenced.add(p['writer'])
    for _i, p in bt.get('req-map', []):
        referenced.add(p['seat'])
    for sid in sorted(set(seats) - referenced):
        reasons.append('SEAT-UNREFERENCED: %s is declared but nothing references it; a seat with no holder is '
                       'not a seat' % sid)
    if reasons:
        fail('seats', reasons)
    ok('seats', '%d declared seats; %d BUILT/DOCUMENT_SEAT paths all resolve in the candidate tree; every seat is '
                'referenced by a subsystem, a store or a req-map' % (len(seats), resolved))


# --------------------------------------------------------------------------- conflict ledger
def ledger_rows():
    rows = []
    with open(os.path.join(SEAT, 'MODEL-MIGRATION-CONFLICT-LEDGER.md'), encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line.startswith('|'):
                continue
            cells = [c.strip() for c in line.strip('|').split('|')]
            if len(cells) < 4 or not cells[0].isdigit():
                continue
            rows.append((cells[1], cells[2], cells[3].strip('`')))
    return rows


def _count_cycles(adj):
    color, found = {}, set()

    def canon(c):
        k = min(range(len(c)), key=lambda i: c[i:] + c[:i])
        r = c[k:] + c[:k]
        return tuple(r + [r[0]])

    def dfs(u, stack):
        color[u] = 1
        stack.append(u)
        for w in sorted(adj.get(u, ())):
            if color.get(w, 0) == 1:
                found.add(canon(stack[stack.index(w):]))
            elif color.get(w, 0) == 0:
                dfs(w, stack)
        color[u] = 2
        stack.pop()

    for u in sorted(adj):
        if color.get(u, 0) == 0:
            dfs(u, [])
    return len(found)


def check_conflict_ledger():
    reasons = []
    bt = by_type(facts())
    rows = ledger_rows()
    subs = {i for i, _ in bt.get('subsystem', [])}
    comps = {i for i, _ in bt.get('component', [])}
    types = {i: p for i, p in bt.get('type', [])}
    adj = {}
    for _i, p in bt.get('consumes', []):
        c, prov = p['consumer'], p['provides']
        o = types.get(prov, {}).get('owner-subsystem')
        if c in subs and o and c != o:
            adj.setdefault(c, set()).add(o)
    wp_per_sub = {}
    for _i, p in bt.get('req-map', []):
        wp_per_sub.setdefault(p['subsystem'], set()).add(p['wp'])
    seen_cycles, seen_wp, seen_comp = set(), set(), set()
    for kind, source, fact in rows:
        if kind == 'DATAFLOW-CYCLE':
            nodes = fact.split('->')
            if len(nodes) < 3 or nodes[0] != nodes[-1]:
                reasons.append('LEDGER-ROW-MALFORMED: %r is not a closed cycle' % fact); continue
            for a, b in zip(nodes, nodes[1:]):
                if b not in adj.get(a, ()):
                    reasons.append('LEDGER-ROW-NOT-IN-MODEL: data-flow edge %s->%s of cycle %r does not exist'
                                   % (a, b, fact))
                    break
            else:
                seen_cycles.add(tuple(nodes))
        elif kind == 'COMPOSITE-WP':
            sid = source.split()[-1]
            tokens = set(fact.split('+'))
            if sid not in subs:
                reasons.append('LEDGER-ROW-NOT-IN-MODEL: composite-WP row names undeclared subsystem %s' % sid)
            elif wp_per_sub.get(sid, set()) != tokens:
                reasons.append('LEDGER-ROW-NOT-IN-MODEL: %s maps to %s in the model but the row records %s'
                               % (sid, sorted(wp_per_sub.get(sid, set())), sorted(tokens)))
            else:
                seen_wp.add(sid)
        elif kind == 'NON-SUBSYSTEM-CONSUMER':
            fact = fact.upper()
            if fact not in comps:
                reasons.append('LEDGER-ROW-NOT-IN-MODEL: %r is not a declared component' % fact)
            else:
                seen_comp.add(fact)
        else:
            reasons.append('LEDGER-ROW-UNKNOWN-KIND: %r' % kind)
    for c in sorted(comps):
        if c not in seen_comp:
            reasons.append('UNRECORDED-NORMALIZATION: component %s has no NON-SUBSYSTEM-CONSUMER row' % c)
    for sid, wps in sorted(wp_per_sub.items()):
        if len(wps) > 1 and sid not in seen_wp:
            reasons.append('UNRECORDED-NORMALIZATION: subsystem %s was split across %d WP tokens with no '
                           'COMPOSITE-WP row' % (sid, len(wps)))
    n_model_cycles = _count_cycles(adj)
    if n_model_cycles != len(seen_cycles):
        reasons.append('UNRECORDED-NORMALIZATION: the model exhibits %d canonical data-flow cycles but %d are '
                       'recorded' % (n_model_cycles, len(seen_cycles)))
    if reasons:
        fail('conflict-ledger', reasons)
    ok('conflict-ledger', '%d rows reconciled against the model in both directions (%d data-flow cycles, '
                          '%d composite-WP splits, %d component declarations)'
       % (len(rows), len(seen_cycles), len(seen_wp), len(seen_comp)))


# --------------------------------------------------------------------------- packet
def packet_block():
    block, inside = {}, False
    with open(os.path.join(SEAT, 'ROOT-OPERATOR-DECISION-PACKET.md'), encoding='utf-8') as f:
        for line in f:
            t = line.strip()
            if t == '<!-- PACKET-RECONCILIATION':
                inside = True; continue
            if inside and t == '-->':
                inside = False; continue
            if inside and t:
                parts = t.split()
                block[' '.join(parts[:-1])] = parts[-1]
    return block


def tool_path(role):
    """The pinned executable for ROLE — one seat, in the reader; the gate never hard-codes a binary name."""
    return SR.tool_path(SEAT, role)


def ensure_commitments(work):
    """Run BOTH verification paths over the EXPORTED CANDIDATE, each writing its fact-set commitment into the
    private workspace, and cache the outcome there.

    One seat: whichever check needs the two commitments gets the same bytes, computed once, over the tree under
    judgement rather than over the working copy. The commitments the decision packet records must equal these —
    a packet reconciled against commitments it produced itself would only be certifying its own arithmetic.
    """
    state = os.path.join(work, 'commitments.json')
    kpath, cpath = os.path.join(work, 'KERNEL-COMMITMENT.txt'), os.path.join(work, 'CHECKER-COMMITMENT.txt')
    if os.path.isfile(state) and os.path.isfile(kpath) and os.path.isfile(cpath):
        with open(state, encoding='utf-8') as f:
            return json.load(f)
    root = os.path.join(SEAT, 'ROOT.sexp')
    k = AR.bounded_run([tool_path('KERNEL_RUNTIME'), '--script', os.path.join(SEAT, 'KERNEL',
                                                                              'model-law-kernel.lisp'),
                        root, '--commitment', kpath], capture_output=True, text=True, cwd=SEAT)
    c = AR.bounded_run([tool_path('CHECKER_RUNTIME'), os.path.join(SEAT, 'CHECKER', 'independent_check.py'),
                        root, '--kernel-commitment', kpath, '--commitment', cpath,
                        '--export', os.path.join(work, 'NEUTRAL-EXPORT.json')],
                       capture_output=True, text=True, cwd=SEAT)
    out = {'kernel': {'code': k.returncode, 'out': (k.stdout + k.stderr)[-4000:]},
           'checker': {'code': c.returncode, 'out': (c.stdout + c.stderr)[-4000:]}}
    with open(state, 'w', encoding='utf-8') as f:
        json.dump(out, f)
    return out


def check_commitments(work):
    """Both paths must reach a verdict over the candidate AND commit to the same fact universe."""
    reasons = []
    r = ensure_commitments(work)
    if r['kernel']['code'] != 0 or 'ARCHITECTURE MODEL LAWS: PASS' not in r['kernel']['out']:
        reasons.append('KERNEL-VERDICT: the Common Lisp model-law kernel did not pass over the candidate')
        reasons += ['    %s' % l for l in r['kernel']['out'].strip().splitlines()[-8:]]
    if r['checker']['code'] != 0 or 'INDEPENDENT ARCHITECTURE INVARIANTS: PASS' not in r['checker']['out']:
        reasons.append('CHECKER-VERDICT: the independent checker did not pass over the candidate')
        reasons += ['    %s' % l for l in r['checker']['out'].strip().splitlines()[-8:]]
    kpath, cpath = os.path.join(work, 'KERNEL-COMMITMENT.txt'), os.path.join(work, 'CHECKER-COMMITMENT.txt')
    kb = open(kpath, 'rb').read() if os.path.isfile(kpath) else None
    cb = open(cpath, 'rb').read() if os.path.isfile(cpath) else None
    if kb is None or cb is None:
        reasons.append('COMMITMENT-ABSENT: %s produced no fact-set commitment'
                       % ('the kernel' if kb is None else 'the checker'))
    elif kb != cb:
        reasons.append('COMMITMENT-MISMATCH: the two paths committed to different fact universes')
    if reasons:
        fail('commitments', reasons)
    n = next((l.split()[-1] for l in kb.decode('utf-8').splitlines() if l.startswith('COMMITMENT total-facts')),
             '?')
    ok('commitments', 'both verification paths reached a verdict over the candidate tree and committed to a '
                      'byte-identical fact universe of %s facts (%d commitment lines, digest %s)'
       % (n, len(kb.decode('utf-8').splitlines()), hashlib.sha256(kb).hexdigest()[:12]))


def check_encoding(work):
    """The commitment is recomputed by a THIRD implementation and must equal the other two, byte for byte.

    Review-3 R3-1. Two verification paths agreeing proves they agree; it does not prove the encoding is
    injective. The specification is CANONICAL-ENCODING.md; the kernel, the independent checker and the reference
    implementation in the reader seat each implement it separately, and this check is where the three meet.
    """
    reasons = []
    ensure_commitments(work)
    sv = str(schema_header().get('version'))
    enc_declared = str(schema_header().get('canonical-encoding'))
    if enc_declared != SR.CANONICAL_ENCODING:
        fail('encoding', ['ENCODING-VERSION: the schema declares :canonical-encoding %r; the reference '
                          'implementation implements %r' % (enc_declared, SR.CANONICAL_ENCODING)])
    per_mod, per_fam, allr = {}, {}, []
    for mod in modules()[0]:
        for form in SR.read_forms_file(os.path.join(SEAT, mod)):
            if SR.head(form) in SR.HEADERS:
                continue
            ftype = str(form[1]).lower()
            fid = SR.canonical_value(form[2], mod, 'fact id')
            r = SR.canonical_fact_render(ftype, fid, SR.plist(form[3:], mod, fid), sv, mod)
            allr.append(r); per_mod.setdefault(mod, []).append(r); per_fam.setdefault(ftype, []).append(r)
    lines = ['COMMITMENT total-facts %d' % len(allr),
             'COMMITMENT total-digest %s' % SR.canonical_digest('TOTAL', allr, sv)]
    for m in sorted(per_mod):
        lines.append('COMMITMENT module %s %d %s'
                     % (m, len(per_mod[m]), SR.canonical_digest('MODULE:' + m, per_mod[m], sv)))
    for f in sorted(per_fam):
        lines.append('COMMITMENT family %s %d %s'
                     % (f, len(per_fam[f]), SR.canonical_digest('FAMILY:' + f, per_fam[f], sv)))
    mine = '\n'.join(lines) + '\n'
    for who in ('KERNEL', 'CHECKER'):
        path = os.path.join(work, '%s-COMMITMENT.txt' % who)
        theirs = open(path, encoding='utf-8').read() if os.path.isfile(path) else None
        if theirs is None:
            reasons.append('ENCODING-UNCOMPARED: %s produced no commitment' % who)
        elif theirs != mine:
            d = next((i for i, (a, b) in enumerate(zip(theirs.splitlines(), lines)) if a != b), None)
            reasons.append('ENCODING-DISAGREEMENT: the %s path and the reference implementation differ%s'
                           % (who, ' first at line %d: %r vs %r' % (d + 1, theirs.splitlines()[d], lines[d])
                              if d is not None else ' in length'))
    if reasons:
        fail('encoding', reasons)
    ok('encoding', 'three independent implementations of %s — the Common Lisp kernel, the independent checker '
                   'and the reference renderer — produce a byte-identical %d-line commitment over %d facts '
                   '(digest %s)' % (enc_declared, len(lines), len(allr),
                                    hashlib.sha256(mine.encode('utf-8')).hexdigest()[:12]))


def schema_header():
    forms = SR.read_forms_file(os.path.join(SEAT, 'MODEL-SCHEMA.sexp'))
    decl = [f for f in forms if SR.head(f) == 'define-model-schema'][0]
    head = []
    for x in decl[2:]:
        if isinstance(x, list):
            break
        head.append(x)
    return {k.lower(): SR.canonical_value(v, 'MODEL-SCHEMA.sexp', k) for k, v in SR.plist(head, 'schema', 'header')}


def check_packet(work):
    reasons = []
    fs = facts()
    bt = by_type(fs)
    block = packet_block()
    if not block:
        fail('packet', ['the decision packet carries no PACKET-RECONCILIATION block to reconcile'])
    expect = {'total-facts': str(len(fs))}
    for t in sorted(bt):
        expect['family %s' % t] = str(len(bt[t]))
    _mods, pl = modules()
    expect['model-root-digest'] = str(pl['canonical-model-root-digest'])
    expect['modules'] = str(len(_mods))
    # Review-2 N-7: the packet must disclose the deferred VOLUME, not only the class count
    src = [p for _i, p in bt.get('source-class', [])]
    expect['deferred-classes'] = str(sum(1 for p in src if p['status'] == 'DEFERRED_DATA_IMPORT'))
    expect['deferred-source-forms'] = str(sum(int(p['source-count']) for p in src
                                              if p['status'] == 'DEFERRED_DATA_IMPORT'))
    expect['imported-classes'] = str(sum(1 for p in src if p['status'] == 'IMPORTED'))
    gp = next((p for i, p in bt.get('promotion', []) if p['scope'] == 'GLOBAL'), None)
    expect['global-promotion'] = gp['state'] if gp else 'ABSENT'
    # Review-2 N-7 mechanized: global source-of-truth cannot be claimed while any class is still authoritative
    # at its declared legacy source. This is the assertion, not the packet's prose.
    still_deferred = sum(1 for p in src if p['authority'] == 'AUTHORITATIVE_AT_SOURCE'
                         and p['status'] == 'DEFERRED_DATA_IMPORT')
    if gp is None:
        reasons.append('PROMOTION-UNDECLARED: the model states no GLOBAL promotion scope')
    elif still_deferred and gp['state'] != 'FORBIDDEN_UNTIL_DDI_COMPLETE':
        reasons.append('GLOBAL-PROMOTION-OVERCLAIM: %d source classes are still authoritative at their declared '
                       'source, but the model declares GLOBAL promotion %s' % (still_deferred, gp['state']))
    for k in sorted(expect):
        if block.get(k) != expect[k]:
            reasons.append('PACKET-MISMATCH: %s = %s in the packet, %s in the model' % (k, block.get(k), expect[k]))
    for k in sorted(block):
        if k not in expect and not k.startswith('commitment '):
            reasons.append('PACKET-EXTRA: %s is claimed by the packet but not derivable from the model' % k)
    ensure_commitments(work)          # the same two commitments every other check sees, computed once
    for who in ('kernel', 'checker'):
        path = os.path.join(work, '%s-COMMITMENT.txt' % who.upper())
        if not os.path.isfile(path):
            reasons.append('PACKET-UNRECONCILED: %s produced no fact-set commitment over the candidate' % who)
            continue
        with open(path, 'rb') as f:
            d = hashlib.sha256(f.read()).hexdigest()
        if block.get('commitment %s' % who) != d:
            reasons.append('PACKET-MISMATCH: commitment %s = %s in the packet, %s on disk'
                           % (who, block.get('commitment %s' % who), d))
    if reasons:
        fail('packet', reasons)
    ok('packet', '%d packet totals recomputed from the model, including the deferred volume and the global '
                 'promotion state, and both verification commitments' % len(expect))


# --------------------------------------------------------------------------- dependency closure (N-13)
def role_map():
    roles = {}
    for form in SR.read_forms_file(os.path.join(SEAT, 'files-and-roles.sexp')):
        if SR.head(form) != 'fact' or str(form[1]).lower() != 'file':
            continue
        fid = SR.canonical_value(form[2], 'files-and-roles.sexp', 'fact id')
        pl = dict(SR.plist(form[3:], 'files-and-roles.sexp', fid))
        roles[fid] = str(pl['role'])
    return roles


# The call shapes that make a file EXECUTE. `open` is deliberately not among them: reading bytes cannot make a
# file an executable dependency, and pretending otherwise would put 79 data reads in a list nobody could use.
# Which argument carries the path is per-shape, because scanning "any argument" would let a mode string like
# 'rb' pass for a resolved path.
CODE_LOADS = {'spec_from_file_location': 1, 'import_module': 0, '__import__': 0, 'run_path': 0, 'run': 0,
              'Popen': 0, 'call': 0, 'check_output': 0, 'system': 0, 'execv': 0, 'execvp': 0,
              'bounded_run': 0, 'checked': 0}
# `AR` is the acceptance runtime: routing execution through it must not make execution invisible to this walk.
SUBPROCESS_OWNERS = ('subprocess', 'os', 'util', 'importlib', 'runpy', 'AR', 'acceptance_runtime')


ENV_SOURCES = ('environ', 'getenv', 'argv', 'stdin')


def constant_strings(node):
    """The string constants of NODE — empty when the expression draws from the environment.

    `os.environ['AML_EXTRA_STEP']` contains the constant 'AML_EXTRA_STEP', which is the NAME of a variable, not a
    path. Counting it as static resolution is exactly how the reported reproducer stayed invisible, so an
    expression reaching into the environment, argv or stdin resolves to nothing here however many constants it
    happens to carry."""
    for x in ast.walk(node):
        if (isinstance(x, ast.Attribute) and x.attr in ENV_SOURCES) or \
           (isinstance(x, ast.Name) and x.id in ('input', 'environ', 'getenv')):
            return []
    return [c.value for c in ast.walk(node) if isinstance(c, ast.Constant) and isinstance(c.value, str)]


def indeterminate_loads(tree, lines, where):
    """Every site that EXECUTES something it cannot name statically (Review-3 R3-5).

    The superseded analyzer collected constants and, when an expression had none, contributed nothing — so a
    load from `os.environ[...]` was not a wildcard, as its own docstring claimed, but INVISIBLE, and a
    HISTORICAL_EVIDENCE program reached that way passed the check. Absence of evidence is now a finding.

    Two things make a dynamic site legitimate, and both are verified rather than asserted:
      * a `# CLOSURE-BOUND: <fact-type>.<field>` marker naming a declared model family, so the possible targets
        are exactly that family's values and the model — not the comment — is what bounds them; or
      * the path is a parameter of the enclosing function and every call to that function in the same module
        passes a constant-bearing argument, which is an ordinary wrapper rather than an unknown.
    """
    bound = {}
    for t, p in by_type(facts()).get('gen-step', []):
        bound.setdefault('gen-step.producer', set()).add(p['producer'])
    for t, p in by_type(facts()).get('harness', []):
        bound.setdefault('harness.runner', set()).add(p['runner'])
    calls = {}
    for n in ast.walk(tree):
        if isinstance(n, ast.Call) and isinstance(n.func, ast.Name):
            calls.setdefault(n.func.id, []).append(n.args)
    out = []
    for n in ast.walk(tree):
        if not isinstance(n, ast.Call):
            continue
        if isinstance(n.func, ast.Attribute):
            owner = getattr(n.func.value, 'id', None) or getattr(getattr(n.func.value, 'value', None), 'id', None)
            if owner not in SUBPROCESS_OWNERS:
                continue
            key = n.func.attr
        elif isinstance(n.func, ast.Name) and n.func.id in ('__import__', 'exec', 'eval'):
            key = n.func.id
        else:
            continue
        i = CODE_LOADS.get(key, 0 if key in ('exec', 'eval') else None)
        if i is None or len(n.args) <= i or constant_strings(n.args[i]):
            continue
        near = (lines[n.lineno - 1], lines[max(0, n.lineno - 2)])
        # CLOSURE-DELEGATED is only honoured where the path really is a parameter of the enclosing function, so
        # a generic execution seat defers to its callers' sites instead of hiding them.
        if any('CLOSURE-DELEGATED' in l for l in near):
            enclosing = [f for f in ast.walk(tree) if isinstance(f, ast.FunctionDef)
                         and f.lineno <= n.lineno <= getattr(f, 'end_lineno', f.lineno)]
            if enclosing and isinstance(n.args[i], ast.Name) and \
               n.args[i].id in {a.arg for a in enclosing[-1].args.args}:
                continue
            out.append('CLOSURE-INDETERMINATE: %s:%d claims :CLOSURE-DELEGATED, but the path is not a parameter '
                       'of the enclosing function' % (where, n.lineno))
            continue
        marker = next((l.split('CLOSURE-BOUND:')[1].strip().split()[0] for l in near if 'CLOSURE-BOUND:' in l), None)
        if marker:
            if marker in bound:
                continue
            out.append('CLOSURE-INDETERMINATE: %s:%d claims :CLOSURE-BOUND %s, which the model does not declare'
                       % (where, n.lineno, marker))
            continue
        arg = n.args[i]
        names = {x.id for x in ast.walk(arg) if isinstance(x, ast.Name)}
        # a plain local name assigned from a constant-bearing expression IS statically resolved
        if any(isinstance(a, ast.Assign) and any(getattr(t, 'id', None) in names for t in a.targets)
               and constant_strings(a.value) for a in ast.walk(tree)):
            continue
        fn = next((f for f in ast.walk(tree) if isinstance(f, ast.FunctionDef)
                   and f.lineno <= n.lineno <= max(getattr(f, 'end_lineno', f.lineno), f.lineno)
                   and names & {a.arg for a in f.args.args}), None)
        if fn and calls.get(fn.name) and all(constant_strings(c[0]) for c in calls[fn.name] if c):
            continue
        out.append('CLOSURE-INDETERMINATE: %s:%d executes a path no static analysis can resolve (%s)'
                   % (where, n.lineno, lines[n.lineno - 1].strip()[:70]))
    return out


def local_closure(entry, seat):
    """The transitive set of seat-local files an entrypoint actually EXECUTES.

    Review-2 N-13 removed the basename tripwire; Review-3 R3-5 removed the two remaining approximations. The
    walk now follows exactly the contexts in which a file can become executable — an import, and the path
    argument of a code-loading or process-starting call — instead of every string constant in the source. A
    constant that merely NAMES a file, such as the classification rule that files a one-time migration under
    HISTORICAL_EVIDENCE, is not an execution and no longer drags that file into the closure. Whatever cannot be
    resolved in those contexts is reported by `indeterminate_loads`, so the gap is a finding, not a silence.
    """
    seen, work, indet = set(), [entry], []
    seatfiles = {f for f in os.listdir(seat) if f.endswith('.py')}
    seatfiles |= {os.path.join(d, f) for d in ('KERNEL', 'CHECKER') if os.path.isdir(os.path.join(seat, d))
                  for f in os.listdir(os.path.join(seat, d)) if f.endswith('.py')}
    while work:
        cur = work.pop()
        if cur in seen:
            continue
        seen.add(cur)
        path = os.path.join(seat, cur)
        if not os.path.isfile(path):
            continue
        text = open(path, encoding='utf-8').read()
        tree, lines = ast.parse(text, filename=cur), text.splitlines()
        indet += indeterminate_loads(tree, lines, cur)
        for node in ast.walk(tree):
            fragments = []
            if isinstance(node, (ast.Import, ast.ImportFrom)):
                fragments = [a.name for a in getattr(node, 'names', [])] + [getattr(node, 'module', None) or '']
            elif isinstance(node, ast.Call):
                key = node.func.attr if isinstance(node.func, ast.Attribute) else getattr(node.func, 'id', None)
                i = CODE_LOADS.get(key)
                if i is not None and len(node.args) > i:
                    fragments = constant_strings(node.args[i])
            for frag in fragments:
                base = os.path.basename(str(frag))
                for cand in seatfiles:
                    if os.path.basename(cand) in (base, base + '.py') and cand not in seen:
                        work.append(cand)
    return seen, indet


def check_dependency_closure():
    reasons = []
    roles = role_map()
    hist = {os.path.basename(p) for p, r in roles.items() if r == 'HISTORICAL_EVIDENCE' and p.endswith('.py')}
    machinery = sorted(p for p, r in roles.items() if r == 'GOVERNANCE_MACHINERY' and p.endswith('.py'))
    entries = [os.path.relpath(os.path.join(REPO, p), os.path.join(REPO, REL)) for p in machinery]
    closure = set()
    indeterminate = []
    for e in entries:
        got, ind = local_closure(e, SEAT)
        closure |= got; indeterminate += ind
    for i in sorted(set(indeterminate)):
        reasons.append(i)
    for c in sorted(closure):
        if os.path.basename(c) in hist:
            reasons.append('HISTORICAL-CODE-IN-CLOSURE: %s is reachable from a GOVERNANCE_MACHINERY entrypoint '
                           'and is classified HISTORICAL_EVIDENCE' % c)
    declared = {os.path.relpath(os.path.join(REPO, p), os.path.join(REPO, REL)) for p in machinery}
    for c in sorted(closure - declared):
        reasons.append('CLOSURE-UNDECLARED: %s is executed by the governance path but is not classified '
                       'GOVERNANCE_MACHINERY' % c)
    if reasons:
        fail('dependency-closure', reasons)
    ok('dependency-closure', '%d governance entrypoints; their transitive seat-local execution closure is %d '
                             'files, every one classified GOVERNANCE_MACHINERY; none of the %d executable '
                             'HISTORICAL_EVIDENCE files is reachable; and every execution site resolves '
                             'statically or is bounded by a declared model family — a path that resolves to '
                             'nothing knowable is a finding, not an absence'
       % (len(entries), len(closure), len(hist)))


# --------------------------------------------------------------------------- hash engines
LISP_PROBE = r'''
(defpackage :probe (:use :cl)) (in-package :probe)
(load (merge-pathnames "hash-provider.lisp" #p"%s"))
(aml-hash:ensure-provider "%s" "%s" "probe")
(dolist (p (cdr sb-ext:*posix-argv*))
  (format t "~a ~a~%%" (aml-hash:sha256-hex-of-file p) p))
'''


def check_hash_engines(work):
    reasons = []
    mods, _pl = modules()
    bt = by_type(facts())
    dt = next(p for _i, p in bt.get('tool', []) if p['role'] == 'DIGEST_PROVIDER')
    cases = {'crlf': b'line one\r\nline two\r\n', 'lf': b'line one\nline two\n',
             'lone-cr': b'line one\rline two\r', 'utf8-bom': b'\xef\xbb\xbfabc\n',
             'invalid-utf8': b'\xff\xfe\x00abc\n', 'empty': b''}
    probes = []
    for name, data in sorted(cases.items()):
        p = os.path.join(work, name + '.bin')
        with open(p, 'wb') as f:
            f.write(data)
        probes.append(p)
    probes += [os.path.join(SEAT, m) for m in mods]
    tcl = os.path.join(work, 'probe.lisp')
    with open(tcl, 'w', encoding='utf-8') as f:
        f.write(LISP_PROBE % (os.path.join(SEAT, 'KERNEL') + '/', dt['path'], dt['sha256']))
    sbcl = next(p['path'] for _i, p in bt.get('tool', []) if p['role'] == 'KERNEL_RUNTIME')
    r = AR.bounded_run([sbcl, '--script', tcl] + probes, capture_output=True, text=True)
    lisp = {}
    for line in r.stdout.splitlines():
        parts = line.split(' ', 1)
        if len(parts) == 2 and len(parts[0]) == 64:
            lisp[parts[1]] = parts[0]
    if not lisp:
        fail('hash-engines', ['the Common Lisp SHA-256 provider produced no digests: %s'
                              % (r.stdout + r.stderr).strip().splitlines()[-3:]])
    for p in probes:
        with open(p, 'rb') as f:
            py = hashlib.sha256(f.read()).hexdigest()
        got = lisp.get(p)
        if got is None:
            reasons.append('ENGINE-GAP: the Common Lisp engine returned no digest for %s' % p)
        elif got != py:
            reasons.append('ENGINE-DISAGREEMENT: %s coreutils=%s hashlib=%s' % (p, got[:16], py[:16]))
    diverged = 0
    for p in probes:
        with open(p, 'rb') as f:
            raw = f.read()
        if hashlib.sha256(raw.decode('utf-8', 'replace').encode('utf-8')).hexdigest() != hashlib.sha256(raw).hexdigest():
            diverged += 1
    if diverged == 0:
        reasons.append('the adversarial probe set does not separate raw-byte hashing from text-decoded hashing; '
                       'the cross-check would not detect a regression')
    if reasons:
        fail('hash-engines', reasons)
    ok('hash-engines', 'coreutils sha256sum and hashlib/OpenSSL agree on %d inputs (%d pinned modules + %d '
                       'adversarial byte cases); %d of those would differ under text-decoded hashing'
       % (len(probes), len(mods), len(cases), diverged))


# --------------------------------------------------------------------------- inventory
def check_inventory():
    reasons = []
    keys, dirrules, seen, named, counted = [], {}, set(), {}, {}
    live = os.path.join(SEAT, 'files-and-roles.sexp')
    for form in SR.read_forms_file(live):
        h = SR.head(form)
        if h != 'fact':
            reasons.append('the inventory contains a non-fact top-level form %r' % h); continue
        ftype = str(form[1]).lower()
        fid = SR.canonical_value(form[2], live, 'fact id')
        pl = dict(SR.plist(form[3:], live, fid))
        if ftype == 'file':
            if fid in seen:
                reasons.append('DUPLICATE-INVENTORY-KEY: %s' % fid)
            seen.add(fid); keys.append(fid); named[fid] = pl
        elif ftype == 'dir-rule':
            dirrules[(str(pl['top']), str(pl['rule']))] = int(pl['count'])
            counted[(str(pl['top']), str(pl['rule']))] = pl
    tr = tree_paths()
    trset, keyset = set(tr), set(keys)
    if len(trset) != len(tr):
        reasons.append('the candidate tree reports the same path more than once')
    for p in sorted(keyset - trset):
        reasons.append('EXTRA-INVENTORY-PATH: %s is in the inventory but not in the candidate tree' % p)
    bi_spec = importlib.util.spec_from_file_location('build_inventory', os.path.join(SEAT, 'build_inventory.py'))
    BI = importlib.util.module_from_spec(bi_spec); bi_spec.loader.exec_module(BI)
    expected, examples = {}, {}
    for p in tr:
        if p in keyset:
            continue
        rid, role, _reason = BI.classify(p)
        if role in BI.QUARANTINE_ROLES:
            reasons.append('%s: %s matches no declared classification rule' % (role, p)); continue
        top = p.split('/')[0] if '/' in p else p
        expected[(top, rid)] = expected.get((top, rid), 0) + 1
        examples.setdefault((top, rid), []).append(p)
    # Review-2 N-15. Every classification in the committed inventory — the individually named ones too, not
    # only the ones a directory rule counts — is RE-DERIVED here by deterministic reapplication of the one
    # classifier seat. Without this an explicit row could be hand-edited to any role and no check would look.
    for fid in sorted(named):
        if fid not in trset:
            continue                                   # already reported as EXTRA-INVENTORY-PATH
        rid, role, reason = BI.classify(fid)
        got = named[fid]
        for what, mine, theirs in (('role', role, str(got.get('role'))), ('rule', rid, str(got.get('rule'))),
                                   ('reason', reason, str(got.get('reason')))):
            if mine != theirs:
                reasons.append('INVENTORY-CLASSIFICATION-DRIFT: %s records %s %r, but reapplying the classifier '
                               'seat yields %r' % (fid, what, theirs, mine))
    # Review-3: a rule that can never fire is a model defect, and it was visible only to the generator's own
    # exit code. The gate names it here, from the classifications the inventory actually cites, so a dead or
    # shadowed rule cannot sit in the canonical table unnoticed. The quarantine rules are the declared
    # exception: a healthy tree is precisely the tree in which they match nothing.
    fired = {str(p.get('rule')) for p in named.values()} | {r for _t, r in dirrules}
    for rid, _expr, role, _reason in BI.RULES:
        if rid not in fired and role not in BI.QUARANTINE_ROLES:
            reasons.append('DEAD RULE: %s is declared in the classification table but classifies no tracked '
                           'path in the candidate (obsolete, or shadowed by an earlier rule)' % rid)
    for k in sorted(set(expected) | set(counted)):
        if k in counted and k in expected:
            rid, role, reason = BI.classify(examples[k][0])
            for what, mine, theirs in (('role', role, str(counted[k].get('role'))),
                                       ('reason', reason, str(counted[k].get('reason')))):
                if mine != theirs:
                    reasons.append('INVENTORY-CLASSIFICATION-DRIFT: directory rule %s under %s records %s %r, '
                                   'but reapplying the classifier seat yields %r' % (k[1], k[0], what, theirs,
                                                                                     mine))
    for k in sorted(set(expected) | set(dirrules)):
        if expected.get(k, 0) != dirrules.get(k, 0):
            named = ', '.join(examples.get(k, [])[:3]) or '(no tracked path)'
            reasons.append('DIRECTORY-RULE-MISCOUNT: %s under %s — %d in the candidate tree, %d recorded; '
                           'unaccounted for: %s' % (k[1], k[0], expected.get(k, 0), dirrules.get(k, 0), named))
    dirsum = sum(dirrules.values())
    if len(keys) + dirsum != len(tr):
        reasons.append('MULTISET-MISMATCH: %d candidate paths but %d file facts + %d counted by directory rules'
                       % (len(tr), len(keys), dirsum))
    if any(k.startswith('"') for k in keys):
        reasons.append('C-QUOTED-INVENTORY-KEY: a key begins with a quotation mark; paths must be exact bytes')
    if reasons:
        fail('inventory', reasons)
    ok('inventory', '%d candidate paths = %d file facts + %d counted by %d directory rules; every role, rule '
                    'and reason — named rows and counted rows alike — re-derived by deterministic reapplication '
                    'of the one classifier seat; 0 quarantined, 0 duplicate, 0 extra'
       % (len(tr), len(keys), dirsum, len(dirrules)))


def check_tcb():
    """The acceptance trusted computing base: re-derived from the candidate, matched against the measurement the
    model records, and held under the AUTHORED cap (Review-3 §15).

    Two separations make the number hard to fake. Membership comes from path kind and file bytes, never from a
    role name, so a file cannot leave the base by being re-classified, renamed, or filed as a helper, a fixture
    or a migration. And the cap is an authored fact in the corpus while the measurement is a generated fact in
    the inventory, so the program that counts the lines is never the program that says how many are allowed.
    """
    fs = by_type(facts())
    budget = fs.get('tcb-budget', [])
    if len(budget) != 1:
        fail('tcb', ['TCB-BUDGET-UNDECLARED: exactly one authored tcb-budget fact is required; the candidate '
                     'declares %d' % len(budget)])
    cap = int(budget[0][1]['cap'])
    declared = {str(p['path']): p for _i, p in fs.get('tcb-file', [])}
    machinery = {p for p, r in role_map().items() if r == 'GOVERNANCE_MACHINERY'}
    blobs = {}
    for path in sorted({p for p in tree_paths() if p.startswith(REL + '/')} | machinery):
        blob = tree_blob(path)
        if blob is None:
            fail('tcb', ['TCB-PATH-ABSENT: %s is classified machinery but the candidate tree holds no blob for '
                         'it' % path])
        blobs[path] = blob
    rows = AR.tcb_measure(blobs)
    reasons = []
    for path, physical, nbnc in rows:
        rec = declared.get(path)
        if rec is None:
            reasons.append('TCB-UNRECORDED: %s is acceptance machinery in the candidate but the model records no '
                           'measurement for it' % path)
        elif (int(rec['physical']), int(rec['nbnc'])) != (physical, nbnc):
            reasons.append('TCB-MISMEASURED: %s measures %d physical / %d nbnc in the candidate; the model '
                           'records %s / %s' % (path, physical, nbnc, rec['physical'], rec['nbnc']))
    for path in sorted(set(declared) - {r[0] for r in rows}):
        reasons.append('TCB-PHANTOM: the model records a measurement for %s, which is not acceptance machinery '
                       'in the candidate' % path)
    total, physical_total = sum(r[2] for r in rows), sum(r[1] for r in rows)
    recorded = fs.get('tcb-total', [])
    if len(recorded) != 1:
        reasons.append('TCB-TOTAL-UNDECLARED: exactly one tcb-total fact is required; the candidate has %d'
                       % len(recorded))
    elif (int(recorded[0][1]['files']), int(recorded[0][1]['physical']), int(recorded[0][1]['nbnc'])) != \
            (len(rows), physical_total, total):
        reasons.append('TCB-TOTAL-MISMATCH: the candidate measures %d files / %d physical / %d nbnc; the model '
                       'records %s / %s / %s' % (len(rows), physical_total, total, recorded[0][1]['files'],
                                                 recorded[0][1]['physical'], recorded[0][1]['nbnc']))
    if total > cap:
        reasons.append('TCB-OVER-CAP: the acceptance base measures %d non-blank/non-comment lines against the '
                       'authored cap of %d (+%d). The cap is not raised to fit the machinery.'
                       % (total, cap, total - cap))
    if reasons:
        fail('tcb', reasons)
    for path, physical, nbnc in rows:
        print('  TCB %-46s %6d %6d' % (path, physical, nbnc))
    ok('tcb', '%d executable files, %d physical, %d non-blank/non-comment against an authored cap of %d '
              '(headroom %d); the file set is derived from the candidate by kind, so no re-classification, '
              'rename or relocation can shrink it' % (len(rows), physical_total, total, cap, cap - total))


CHECKS = {'candidate': check_candidate, 'toolchain': check_toolchain, 'inventory': check_inventory,
          'artifacts': check_artifacts, 'corpus': check_corpus, 'seats': check_seats, 'universe': check_universe,
          'generation-order': check_generation_order, 'conflict-ledger': check_conflict_ledger,
          'dependency-closure': check_dependency_closure, 'provenance': check_provenance,
          'tcb': check_tcb}
WORK_CHECKS = {'generation': check_generation, 'packet': check_packet, 'hash-engines': check_hash_engines,
               'commitments': check_commitments, 'encoding': check_encoding}

if __name__ == '__main__':
    ap = argparse.ArgumentParser(description='model-derived gate checks over an immutable candidate tree')
    # `content-state` is not a check — it prints the content-sensitive measurement the gate compares before and
    # after itself (Review-3 R3-9). It has no verdict, so it is deliberately not in the counted set.
    ap.add_argument('check', choices=sorted(set(CHECKS) | set(WORK_CHECKS) | {'content-state'}))
    ap.add_argument('--tree', default=os.environ.get('AML_CANDIDATE_TREE', 'WORKTREE'),
                    help="a revision naming the immutable tree to judge, or WORKTREE (default) for the tree the "
                         "current state would commit to")
    ap.add_argument('--work', default=None, help='reuse this workspace instead of creating a private one')
    ap.add_argument('--keep-work', action='store_true', help='keep the private workspace for inspection')
    ap.add_argument('--seat', default=None,
                    help='use an ALREADY EXPORTED seat directory instead of exporting the candidate. The check '
                         'logic is identical; only the source of the model differs. Held-out falsifiers use this '
                         'to exercise a real check against a deliberately mutated candidate.')
    a = ap.parse_args()
    # Review-3 R3-8: a scratch root inside the repository under audit is refused before any work is done, and a
    # workspace this process created is removed on success, failure, signal and timeout alike — keeping it is an
    # explicit request, not the default that littered 291 directories into /tmp.
    work = AR.workspace('aml-gatecheck-', REPO, keep=a.keep_work, reuse=a.work)
    if a.check == 'content-state':
        print(repository_content_state()); sys.exit(0)
    TREE = candidate_tree(a.tree)
    if a.seat:
        SEAT = os.path.abspath(a.seat)
    else:
        ensure_seat(work)
    (WORK_CHECKS[a.check](work) if a.check in WORK_CHECKS else CHECKS[a.check]())
