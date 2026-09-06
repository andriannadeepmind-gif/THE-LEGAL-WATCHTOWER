#!/usr/bin/env python3
"""Emit files-and-roles.sexp: classify EVERY tracked file exactly once (no-loss), from EXPLICIT rules only.

Correction of the three reported inventory defects, at their source rather than around their examples:

  * PATH TRUTH.  Paths come from `git ls-files -z` (NUL-separated).  git C-quotes only when it must delimit
    with whitespace/newlines; with -z it never quotes and never escapes, so the exact stored bytes survive.
    Bytes that are not valid UTF-8 are REJECTED explicitly (exit 2) — never mangled, never replaced.
    The former `p.startswith('"output')` guard is deleted: the error class is removed, not guarded.

  * NO CATCH-ALL.  Every classification is produced by a named rule and cites its rule id.  A path matching
    no rule becomes UNCLASSIFIED, is named on stderr, and makes this program exit non-zero.  There is no
    terminal rule that accepts anything, so "silently swallowed" is not a reachable state.

  * NO BROAD BLESSING INSIDE A GOVERNED SUBTREE (Review-2 N-18).  The terminal catch-all was removed in the
    previous pass, but broad prefix rules still absorbed anything newly added under an already-governed
    subtree: a brand-new binary dropped into deployment/collab/design/ was silently labelled
    HISTORICAL_EVIDENCE, and a new document in the change-proposal round was silently labelled authored prose.
    Inside the governed, normative, model and toolchain subtrees the rules now match declared EXTENSIONS only;
    anything else there becomes REVIEW_REQUIRED, which is named and fails the build exactly like UNCLASSIFIED.
    A prefix may still classify in bulk where the subtree is genuinely out of architectural scope (vendored
    dependencies, corpora, runtime state) — and `third-party/` is now a role of its own, VENDORED_DEPENDENCY,
    so an executable dependency tree is never filed under the same word as a data corpus.

  * NO DEAD RULES.  Every classifying rule must match at least one tracked path.  A rule that matches nothing —
    whether because it is obsolete or because an earlier rule shadows it — makes this program exit non-zero
    (exit 3).  A rule that cannot fire is therefore not merely unused: it is a build failure.  The QUARANTINE
    rules are the one declared exception: they exist to fire only when an undeclared kind appears, so a healthy
    tree is exactly the tree in which they match nothing.

  * REPRESENTATION IS DERIVED, NOT LISTED.  Whether a path gets its own `file` fact or is folded into a
    counted `dir-rule` fact follows from its ROLE alone (PER_FILE_ROLES below).  There is no second,
    hand-maintained list of "governed" paths that can drift out of step with the rule table — that drift is
    what previously hid authored Greek-named documents inside a bulk aggregate.

Determinism: paths sorted by exact code point sequence; rule order is the file order below; first match wins.
Exit 0 only when every tracked path is classified by a named rule and every rule fired.
"""
import importlib.util, subprocess, os, re, sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
_aspec = importlib.util.spec_from_file_location('acceptance_runtime', os.path.join(HERE, 'acceptance_runtime.py'))
AR = importlib.util.module_from_spec(_aspec); _aspec.loader.exec_module(AR)
_sspec = importlib.util.spec_from_file_location('sexp_reader', os.path.join(HERE, 'SEXP-READER.py'))
SR = importlib.util.module_from_spec(_sspec); _sspec.loader.exec_module(SR)
ROOT = os.path.abspath(os.path.join(HERE, '..', '..', '..', '..', '..', '..'))
CPP = 'deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/'
AM = CPP + 'ARCHITECTURE-MODEL/'
DESIGN = 'deployment/collab/design/'

# Roles the architecture model names individually -> one `file` fact each.
PER_FILE_ROLES = {'CANONICAL_MODEL_INPUT', 'GENERATED_VIEW', 'ARCHITECTURE_DECISION', 'AUTHORED_NORMATIVE_PROSE',
                  'HISTORICAL_EVIDENCE', 'DEFERRED_PRIVATE', 'GOVERNANCE_MACHINERY', 'GOVERNANCE_FIXTURE'}
# Roles the model never names individually -> counted `dir-rule` facts (exact counts, no loss).
AGGREGATE_ROLES = {'PRODUCTION_CODE', 'TEST_OR_FIXTURE', 'OUT_OF_SCOPE_WITH_REASON', 'VENDORED_DEPENDENCY'}
# Quarantine roles: reachable, named, and fatal. Neither may ever appear in a committed inventory.
QUARANTINE_ROLES = {'UNCLASSIFIED', 'REVIEW_REQUIRED'}
ROLES = PER_FILE_ROLES | AGGREGATE_ROLES | QUARANTINE_ROLES

# Declared extensions inside the governed subtrees. Anything else there is REVIEW_REQUIRED, never blessed.
GOVERNED_DOC_EXT = ('.md',)
GOVERNED_MODEL_EXT = ('.sexp',)
# Every kind a design/collaboration round is allowed to contain, enumerated. Adding a kind is a reviewable edit
# here; a kind that is not listed quarantines instead of being blessed by the prefix it happens to sit under.
DESIGN_ROUND_EXT = ('.md', '.sexp', '.json', '.jsonl', '.html', '.txt', '.tsv', '.csv', '.yml', '.yaml',
                    '.tla', '.cfg', '.py', '.sh', '.js', '.mjs')
_HIST_RE = re.compile(r'/V1\.\d.*(AUDIT|VERIFY|EVIDENCE|MANIFEST|BOOTSTRAP|CONSISTENCY|KILL-WITNESSES'
                      r'|SEMANTIC-CROSSWALK|DESTRUCTION-PASS-RECORD|NARROW-DELTA)')
_DEP_TOP_EXT = ('.ttl', '.jsonld', '.json', '.js', '.sh')


REPO = None            # bound by --repo when the generator runs against an exported candidate workspace


def tracked_paths(tree=None):
    """Exact tracked paths as git stores them.  -z => no quoting, no escaping, no ambiguity.

    With TREE the universe is enumerated from an IMMUTABLE git tree object rather than from the mutable index
    (Review-2 N-2/N-14): the read-only gate pins the candidate it is judging, so nothing a concurrent process
    stages can change what the inventory is compared against."""
    repo = REPO or ROOT
    cmd = (['git', '-C', repo, 'ls-tree', '-r', '--name-only', '-z', tree] if tree
           else ['git', '-C', repo, 'ls-files', '-z'])
    r = subprocess.run(cmd, capture_output=True)
    if r.returncode != 0:
        sys.stderr.write('FATAL: %s failed: %s\n' % (' '.join(cmd[3:]), r.stderr.decode('utf-8', 'replace')))
        sys.exit(2)
    ok, undecodable = [], []
    for b in r.stdout.split(b'\0'):
        if not b:
            continue
        try:
            ok.append(b.decode('utf-8'))
        except UnicodeDecodeError:
            undecodable.append(b)
    return ok, undecodable


def _hist(p):
    return bool(_HIST_RE.search(p)) or p.endswith('.out')


# --------------------------------------------------------------------------- the classification table
# Review-3 §15 M2. The table is DATA, in one canonical seat (classification-rules.sexp), read here and read by
# both verification paths. There is no second hand-written copy to drift out of step with the model, and a rule
# can no longer be silently added to the generator without appearing in the facts the verifiers check.
def atom_matches(a, p):
    """One match atom against one path. An atom outside the declared vocabulary is fatal, never a false."""
    kind, _, arg = a.strip().partition(':')
    if kind == 'prefix':
        return p.startswith(arg)
    if kind == 'suffix':
        return p.endswith(arg)
    if kind == 'equals':
        return p == arg
    if kind == 'depth':
        return p.count('/') == int(arg)
    if kind == 'pattern':
        return re.search(arg, p) is not None
    sys.stderr.write('UNKNOWN-MATCH-ATOM: %r is not prefix/suffix/equals/depth/pattern\n' % a)
    sys.exit(2)


def rule_matches(expr, p):
    """The :match grammar: a disjunction of conjunctions, '|' between terms and '&' between atoms."""
    return any(all(atom_matches(a, p) for a in term.split('&')) for term in expr.split('|'))


def rules():
    """The classification table from its one canonical seat, ordered, with every degenerate shape named."""
    seen, table = {}, []
    for form in SR.read_forms_file(os.path.join(HERE, 'classification-rules.sexp')):
        if SR.head(form) != 'fact' or str(form[1]).lower() != 'classification-rule':
            continue
        rid = str(form[2])
        pl = dict(SR.plist(form[3:], 'classification-rules.sexp', rid))
        table.append((int(str(pl['order'])), rid, str(pl['match']), str(pl['role']), str(pl['reason'])))
    for field, index in (('id', 1), ('order', 0), ('match expression', 2)):
        dupes = [k for k, n in Counter(row[index] for row in table).items() if n > 1]
        if dupes:
            sys.stderr.write('DUPLICATE-RULE-%s: %s\n' % (field.split()[0].upper(), ' '.join(map(str, dupes))))
            sys.exit(3)
    if not table:
        sys.stderr.write('EMPTY-RULE-TABLE: classification-rules.sexp declares no classification-rule fact\n')
        sys.exit(3)
    for _order, rid, _m, role, _r in table:
        if role not in ROLES:
            sys.stderr.write('UNDECLARED-RULE-ROLE: %s assigns %r, which is not a declared role\n' % (rid, role))
            sys.exit(3)
    return [(rid, expr, role, reason) for _order, rid, expr, role, reason in sorted(table)]


RULES = rules()


def classify(p):
    for rid, expr, role, reason in RULES:
        if rule_matches(expr, p):
            return rid, role, reason
    return None, 'UNCLASSIFIED', 'no explicit classification rule matched this tracked path'


def wq(v):
    return '"%s"' % v.replace('\\', '\\\\').replace('"', '\\"')


def tcb_blobs(paths, tree):
    """Exact candidate bytes for PATHS.

    With a pinned TREE the bytes come from that tree object. Without one the candidate is what the current state
    would commit, so a tracked path present in the working tree is read from there and one that is only staged
    is read from the index. A path that is in neither is named and fatal: dropping it would understate the
    acceptance base by exactly the amount an attacker most wants understated."""
    repo = REPO or ROOT
    blobs = {}
    for p in paths:
        rev = '%s:%s' % (tree, p) if tree else ':%s' % p
        if not tree and os.path.isfile(os.path.join(repo, p)):
            with open(os.path.join(repo, p), 'rb') as fh:                 # the working tree IS the candidate
                blobs[p] = fh.read()
            continue
        r = subprocess.run(['git', '-C', repo, 'cat-file', 'blob', rev], capture_output=True)
        if r.returncode != 0:
            sys.stderr.write('FATAL: no blob for %s at %s\n' % (p, rev))
            sys.exit(2)
        blobs[p] = r.stdout
    return blobs


def main():
    # --out <path> writes the regenerated inventory somewhere else and leaves the committed module untouched.
    # The gate uses it to COMPARE regenerated against committed; nothing is ever restored before comparison.
    global REPO
    out_path = os.path.join(HERE, 'files-and-roles.sexp')
    tree = None
    argv = sys.argv[1:]
    while argv:
        if argv[0] == '--out' and len(argv) > 1:
            out_path = os.path.abspath(argv[1]); argv = argv[2:]
        elif argv[0] == '--tree' and len(argv) > 1:
            tree = argv[1]; argv = argv[2:]
        elif argv[0] == '--repo' and len(argv) > 1:
            REPO = os.path.abspath(argv[1]); argv = argv[2:]
        else:
            sys.stderr.write('usage: build_inventory.py [--out PATH] [--tree TREE-ISH] [--repo DIR]\n')
            sys.exit(2)
    files, undecodable = tracked_paths(tree)
    if undecodable:
        sys.stderr.write('UNDECODABLE-PATH: %d tracked path(s) are not valid UTF-8; rejected:\n' % len(undecodable))
        for b in undecodable[:20]:
            sys.stderr.write('  %r\n' % b)
        sys.exit(2)
    files = sorted(files)

    per_file, bulk, rolec, rulec, quarantined = [], [], Counter(), Counter(), []
    for p in files:
        rid, role, reason = classify(p)
        if role not in ROLES:
            sys.stderr.write('FATAL: rule %s produced undeclared role %r\n' % (rid, role))
            sys.exit(2)
        rolec[role] += 1
        rulec[rid] += 1
        if role in QUARANTINE_ROLES:
            quarantined.append((role, p))
        elif role in PER_FILE_ROLES:
            per_file.append((p, rid, role, reason))
        else:
            bulk.append((p, rid, role, reason))

    # A rule that matches nothing is obsolete or shadowed, and that is a build failure — EXCEPT for the
    # quarantine rules, whose whole purpose is to fire only when something undeclared appears. A healthy tree is
    # precisely the tree in which they match nothing, so requiring them to fire would invert their meaning.
    dead = [rid for rid, _m, role, _x in RULES if rulec.get(rid, 0) == 0 and role not in QUARANTINE_ROLES]

    out = [';;;; files-and-roles.sexp — every tracked file classified exactly once (no-loss).',
           ';;;; GENERATED by build_inventory.py.  Do not edit by hand.',
           ';;;; Paths are the exact bytes reported by `git ls-files -z` (git never C-quotes with -z).',
           ';;;; Every classification cites the rule id that produced it; there is no catch-all rule.',
           ';;;; Roles named individually (one `file` fact each): ' + ' '.join(sorted(PER_FILE_ROLES)),
           ';;;; Roles counted in bulk (one `dir-rule` fact per top-level directory and rule): '
           + ' '.join(sorted(AGGREGATE_ROLES)),
           ';;;; Invariant: (count of file facts) + (sum of dir-rule :count) = (count of tracked paths).',
           ';;;; A path whose kind no rule declares becomes UNCLASSIFIED or, inside a governed subtree,',
           ';;;; REVIEW_REQUIRED; both are named on stderr and both fail this build (Review-2 N-2, N-18).', '']
    for p, rid, role, reason in sorted(per_file):
        out.append('(fact file %s :role %s :rule %s :reason %s)' % (wq(p), role, rid, wq(reason)))
    out.append('')
    agg = Counter()
    meta = {}
    for p, rid, role, reason in bulk:
        top = p.split('/')[0] if '/' in p else p
        agg[(top, rid)] += 1
        meta[(top, rid)] = (role, reason)
    for i, ((top, rid), cnt) in enumerate(sorted(agg.items()), 1):
        role, reason = meta[(top, rid)]
        out.append('(fact dir-rule DR-%04d :top %s :role %s :rule %s :count %d :reason %s)'
                   % (i, wq(top), role, rid, cnt, wq(reason)))
    out.append('')
    # The acceptance trusted computing base, measured from the candidate's own bytes by the ONE rule in
    # acceptance_runtime.py. The set is every executable KIND in the seat plus every GOVERNANCE_MACHINERY file
    # wherever it sits, so neither moving a file out of the seat nor re-classifying it removes it from the count.
    machinery = {p for p, rid, role, reason in per_file if role == 'GOVERNANCE_MACHINERY'}
    tcb = AR.tcb_measure(tcb_blobs(sorted({p for p in files if p.startswith(AM)} | machinery), tree))
    out.append(';;;; The acceptance TCB, measured by the one rule in acceptance_runtime.py'
               ' (TCB-BASELINE-RECONCILIATION.md §1).')
    out.append(';;;; Membership follows from path kind and file bytes, never from a role name, so no'
               ' re-classification and no')
    out.append(';;;; rename can shrink it. The ceiling is authored elsewhere (tcb-budget, verification-corpus)'
               ' and `gate_checks.py tcb`')
    out.append(';;;; re-derives every number below from the candidate tree before letting the gate reach a'
               ' verdict.')
    for n, (p, physical, nbnc) in enumerate(tcb, 1):
        out.append('(fact tcb-file TCB-%04d :path %s :physical %d :nbnc %d)' % (n, wq(p), physical, nbnc))
    out.append('(fact tcb-total TCB-TOTAL :files %d :physical %d :nbnc %d)'
               % (len(tcb), sum(r[1] for r in tcb), sum(r[2] for r in tcb)))
    out.append('')
    out.append('(fact inventory-total INV-TOTAL :tracked %d :file-facts %d :dir-rule-facts %d :dir-rule-sum %d)'
               % (len(files), len(per_file), len(agg), sum(agg.values())))
    with open(out_path, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write('\n'.join(out) + '\n')

    print('tracked=%d  file-facts=%d  dir-rule-facts=%d  dir-rule-sum=%d  unclassified=%d  dead-rules=%d'
          % (len(files), len(per_file), len(agg), sum(agg.values()), len(quarantined), len(dead)))
    print('role counts:', dict(sorted(rolec.items())))
    print('acceptance TCB: %d executable files, %d physical, %d non-blank/non-comment'
          % (len(tcb), sum(r[1] for r in tcb), sum(r[2] for r in tcb)))
    if quarantined:
        sys.stderr.write('QUARANTINED — %d tracked path(s) need an explicit decision:\n' % len(quarantined))
        for role, p in quarantined:
            sys.stderr.write('  %-16s %s\n' % (role, p))
        sys.exit(1)
    if len(per_file) + sum(agg.values()) != len(files):
        sys.stderr.write('FATAL: inventory does not reconcile with the tracked path multiset\n')
        sys.exit(2)
    if dead:
        sys.stderr.write('DEAD RULE — %d rule(s) matched no tracked path (obsolete or shadowed): %s\n'
                         % (len(dead), ' '.join(dead)))
        sys.exit(3)


if __name__ == '__main__':
    main()
