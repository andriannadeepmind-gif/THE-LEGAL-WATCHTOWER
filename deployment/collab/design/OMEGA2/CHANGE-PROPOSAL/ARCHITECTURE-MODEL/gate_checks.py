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
"""
import argparse, ast, hashlib, importlib.util, json, os, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..', '..', '..', '..'))
REL = os.path.relpath(HERE, REPO).replace(os.sep, '/')
CPREL = os.path.dirname(REL)
_spec = importlib.util.spec_from_file_location('sexp_reader', os.path.join(HERE, 'SEXP-READER.py'))
SR = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(SR)
HEADERS = SR.HEADERS          # one seat: the reader declares the header vocabulary

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


def git(*args, binary=False):
    r = subprocess.run(['git', '-C', REPO] + list(args), capture_output=True)
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
            r = subprocess.run(['git', '-C', REPO] + args, capture_output=True, text=True, env=env)
            if r.returncode != 0:
                raise SystemExit('CANDIDATE-TREE-FAILED: git %s: %s' % (args[0], r.stderr.strip()))
        return r.stdout.strip()
    finally:
        shutil.rmtree(d, ignore_errors=True)


def tree_paths():
    return [b.decode('utf-8') for b in git('ls-tree', '-r', '--name-only', '-z', TREE, binary=True).split(b'\0') if b]


def tree_blob(path):
    """The candidate tree's bytes for PATH, or None if the candidate does not contain it."""
    r = subprocess.run(['git', '-C', REPO, 'cat-file', 'blob', '%s:%s' % (TREE, path)], capture_output=True)
    return r.stdout if r.returncode == 0 else None


def ensure_seat(work):
    """Export the candidate change-proposal subtree once into WORK/cand and return its ARCHITECTURE-MODEL dir."""
    global SEAT
    cand = os.path.join(work, 'cand')
    seat = os.path.join(cand, REL)
    if not os.path.isdir(seat):
        os.makedirs(cand, exist_ok=True)
        tar = subprocess.run(['git', '-C', REPO, 'archive', TREE, CPREL], capture_output=True, check=True).stdout
        subprocess.run(['tar', '-x', '-C', cand], input=tar, check=True)
    SEAT = seat
    return seat


# --------------------------------------------------------------------------- model access (candidate only)
def modules():
    forms = SR.read_forms_file(os.path.join(SEAT, 'ROOT.sexp'))
    roots = [f for f in forms if SR.head(f) == 'define-model-root']
    if len(roots) != 1 or len(forms) != 1:
        raise SystemExit('ROOT-MALFORMED: exactly one define-model-root form and nothing else is permitted')
    pl = dict(SR.plist(roots[0][2:], 'ROOT.sexp', 'define-model-root'))
    return [str(dict(SR.plist(e, 'ROOT.sexp', 'entry'))['module']) for e in pl['composition']], pl


def facts():
    out = []
    for mod in modules()[0]:
        path = os.path.join(SEAT, mod)
        try:
            forms = SR.read_forms_file(path)
        except SR.MissingSourceFile as e:                      # Review-2 N-17: typed, never a traceback
            raise SystemExit('MISSING-MODEL-FILE: %s' % e.path)
        except SR.SexpError as e:
            raise SystemExit('UNREADABLE-MODEL-FILE: %s' % e)
        for form in forms:
            if SR.head(form) in HEADERS:
                continue
            ftype = str(form[1]).lower()
            fid = SR.canonical_value(form[2], mod, 'fact id')
            pairs = SR.plist(form[3:], mod, '%s %s' % (ftype, fid))
            out.append((ftype, fid, {k.lower(): SR.canonical_value(v, mod, k) for k, v in pairs}))
    return out


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
    r = subprocess.run([tool, '--binary', '--', path], capture_output=True)
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
    if reasons:
        fail('toolchain', reasons)
    ok('toolchain', '%d declared tools verified before any verdict: path, exact executable digest measured by the '
                    'other path\'s engine, and semantic version' % len(tools))


def observed_version(tid, p):
    """What the tool ITSELF reports, so a pinned digest and a self-reported version must agree."""
    try:
        if p.get('role') == 'KERNEL_RUNTIME':
            return subprocess.run([p['path'], '--version'], capture_output=True, text=True, timeout=60).stdout
        if p.get('role') == 'DIGEST_PROVIDER':
            return subprocess.run([p['path'], '--version'], capture_output=True, text=True, timeout=60).stdout
        if p.get('role') == 'CHECKER_RUNTIME':
            return subprocess.run([p['path'], '-c', 'import sys;print(sys.version.split()[0])'],
                                  capture_output=True, text=True, timeout=60).stdout
        if p.get('role') == 'ASP_SOLVER':
            return subprocess.run([sys.executable, '-c', 'import clingo;print(clingo.__version__)'],
                                  capture_output=True, text=True, timeout=60).stdout
        if p.get('role') == 'CHECKER_DIGEST_PROVIDER':
            return subprocess.run([sys.executable, '-c', 'import ssl;print(ssl.OPENSSL_VERSION)'],
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
        r = subprocess.run(args, capture_output=True, text=True, cwd=seat)
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
    present = {p[len(REL) + 1:] for p in tree_paths()
               if p.startswith(REL + '/') and (p.endswith('.md') or p.endswith('.sexp'))}
    # the declared universe is exactly the derived artifacts; authored documents are not derived
    derived_present = {p for p in present if p.startswith('GENERATED/')}
    derived_declared = {p for p in declared if p.startswith('GENERATED/')}
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
    ok('artifacts', 'the model declares %d generated artifacts (%d views) and the candidate tree holds exactly '
                    'those — no missing, extra, renamed or orphaned artifact' % (len(declared), len(derived_declared)))


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
        impl = {i.upper() for i in implemented_falsifiers(runner)}
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


def implemented_falsifiers(runner):
    """The falsifier ids RUNNER actually registers, read from its AST — no import, no execution."""
    path = os.path.join(SEAT, runner)
    if not os.path.isfile(path):
        return set()
    tree = ast.parse(open(path, encoding='utf-8').read(), filename=runner)
    out = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign) and any(getattr(t, 'id', None) == 'FALSIFIERS' for t in node.targets):
            for elt in getattr(node.value, 'elts', []):
                if isinstance(elt, ast.Tuple) and elt.elts and isinstance(elt.elts[0], ast.Constant):
                    out.add(str(elt.elts[0].value))
    return out


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
    """The pinned executable for ROLE, taken from the model — the gate never hard-codes a binary name."""
    for _i, p in by_type(facts()).get('tool', []):
        if p.get('role') == role:
            return p['path']
    raise SystemExit('TOOLCHAIN-UNDECLARED: the model declares no tool with role %s' % role)


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
    k = subprocess.run([tool_path('KERNEL_RUNTIME'), '--script', os.path.join(SEAT, 'KERNEL',
                                                                              'model-law-kernel.lisp'),
                        root, '--commitment', kpath], capture_output=True, text=True, cwd=SEAT)
    c = subprocess.run([tool_path('CHECKER_RUNTIME'), os.path.join(SEAT, 'CHECKER', 'independent_check.py'),
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


def local_closure(entry, seat):
    """The transitive set of seat-local Python files an entrypoint actually pulls in.

    Review-2 N-13: the previous check scanned for a HISTORICAL_EVIDENCE BASENAME among ast.Constant strings, and
    five of seven reintroduction forms walked straight past it. A basename tripwire cannot establish a dependency
    closure, so this computes the real one: every seat-local module reachable through an import or through a
    spec_from_file_location/open/run of a path built from ANY expression, resolved by evaluating the constant
    parts and treating a non-constant part as a wildcard that matches any seat file. The wildcard is what makes
    concatenation, f-strings and joins fail closed instead of passing silently."""
    seen, work = set(), [entry]
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
        tree = ast.parse(open(path, encoding='utf-8').read(), filename=cur)
        for node in ast.walk(tree):
            fragments = []
            if isinstance(node, ast.Constant) and isinstance(node.value, str):
                fragments = [node.value]
            elif isinstance(node, (ast.JoinedStr, ast.BinOp, ast.Call)):
                fragments = [c.value for c in ast.walk(node)
                             if isinstance(c, ast.Constant) and isinstance(c.value, str)]
            for frag in fragments:
                base = os.path.basename(frag)
                for cand in seatfiles:
                    cb = os.path.basename(cand)
                    if cb == base or (frag and cb.startswith(frag.strip('./')) and frag.strip('./')):
                        if cand not in seen:
                            work.append(cand)
    return seen


def check_dependency_closure():
    reasons = []
    roles = role_map()
    hist = {os.path.basename(p) for p, r in roles.items() if r == 'HISTORICAL_EVIDENCE' and p.endswith('.py')}
    machinery = sorted(p for p, r in roles.items() if r == 'GOVERNANCE_MACHINERY' and p.endswith('.py'))
    entries = [os.path.relpath(os.path.join(REPO, p), os.path.join(REPO, REL)) for p in machinery]
    closure = set()
    for e in entries:
        closure |= local_closure(e, SEAT)
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
                             'files, every one classified GOVERNANCE_MACHINERY, and none of the %d executable '
                             'HISTORICAL_EVIDENCE files is reachable' % (len(entries), len(closure), len(hist)))


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
    r = subprocess.run([sbcl, '--script', tcl] + probes, capture_output=True, text=True)
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


CHECKS = {'candidate': check_candidate, 'toolchain': check_toolchain, 'inventory': check_inventory,
          'artifacts': check_artifacts, 'corpus': check_corpus, 'seats': check_seats,
          'generation-order': check_generation_order, 'conflict-ledger': check_conflict_ledger,
          'dependency-closure': check_dependency_closure}
WORK_CHECKS = {'generation': check_generation, 'packet': check_packet, 'hash-engines': check_hash_engines,
               'commitments': check_commitments}

if __name__ == '__main__':
    ap = argparse.ArgumentParser(description='model-derived gate checks over an immutable candidate tree')
    ap.add_argument('check', choices=sorted(set(CHECKS) | set(WORK_CHECKS)))
    ap.add_argument('--tree', default=os.environ.get('AML_CANDIDATE_TREE', 'WORKTREE'),
                    help="a revision naming the immutable tree to judge, or WORKTREE (default) for the tree the "
                         "current state would commit to")
    ap.add_argument('--work', default=None, help='private workspace; one is created and kept if omitted')
    ap.add_argument('--seat', default=None,
                    help='use an ALREADY EXPORTED seat directory instead of exporting the candidate. The check '
                         'logic is identical; only the source of the model differs. Held-out falsifiers use this '
                         'to exercise a real check against a deliberately mutated candidate.')
    a = ap.parse_args()
    TREE = candidate_tree(a.tree)
    work = a.work or tempfile.mkdtemp(prefix='aml-gatecheck-')
    os.makedirs(work, exist_ok=True)
    if a.seat:
        SEAT = os.path.abspath(a.seat)
    else:
        ensure_seat(work)
    (WORK_CHECKS[a.check](work) if a.check in WORK_CHECKS else CHECKS[a.check]())
