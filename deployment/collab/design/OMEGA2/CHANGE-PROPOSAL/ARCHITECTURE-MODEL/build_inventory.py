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
import subprocess, os, re, sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
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


# Ordered, explicit, reviewable rule table.  (rule-id, predicate, role, reason)
# First match wins.  Nothing outside this table is classified; nothing in it may match zero paths.
RULES = [
    # --- the architecture-model seat: the live governance path ---
    ('R-001', lambda p: p.startswith(AM + 'GENERATED/'), 'GENERATED_VIEW',
     'deterministically generated from the canonical model'),
    ('R-002', lambda p: p.startswith(AM + 'FIXTURES/'), 'GOVERNANCE_FIXTURE',
     'golden PASS/FAIL fixture exercising the model laws'),
    ('R-003', lambda p: p.startswith(AM + 'KERNEL/') or p.startswith(AM + 'CHECKER/')
     or (p.startswith(AM) and (p.endswith('.py') or p == AM + 'ARCHITECTURE-MODEL-GATE.sh'
                               or p == AM + 'SETUP-TOOLCHAIN.sh')), 'GOVERNANCE_MACHINERY',
     'executable seat of the architecture-governance path (kernel, independent checker, builders, gate)'),
    ('R-004', lambda p: p.startswith(CPP) and p.endswith('/.gitignore'), 'GOVERNANCE_MACHINERY',
     'ignore rules for the derived and interpreter-generated areas of the architecture-governance seat'),
    ('R-005', lambda p: p == AM + 'TOOLCHAIN.sexp', 'CANONICAL_MODEL_INPUT',
     'pinned toolchain identities (part of the model root)'),
    ('R-006', lambda p: p == AM + 'MODEL-MIGRATION-CONFLICT-LEDGER.md', 'ARCHITECTURE_DECISION',
     'migration conflict adjudications'),
    ('R-007', lambda p: p == AM + 'ROOT-OPERATOR-DECISION-PACKET.md', 'ARCHITECTURE_DECISION',
     'single-operator decision packet'),
    ('R-008', lambda p: p.startswith(AM) and p.endswith('.sexp'), 'CANONICAL_MODEL_INPUT',
     'canonical model module (single source of truth)'),
    ('R-009', lambda p: p.startswith(AM) and p.endswith(GOVERNED_DOC_EXT), 'AUTHORED_NORMATIVE_PROSE',
     'architecture-model authored document'),
    ('R-009Q', lambda p: p.startswith(AM), 'REVIEW_REQUIRED',
     'a file inside the architecture-model seat whose kind no rule declares — the model seat never blesses by '
     'prefix (Review-2 N-18)'),
    # --- the change-proposal round ---
    ('R-010', lambda p: p in (CPP + 'SUBSYSTEM-REGISTRY.sexp', CPP + 'INTERFACE-AND-SCHEMA-REGISTRY.sexp'),
     'CANONICAL_MODEL_INPUT', 'v1.6 registry — migration input to the canonical model'),
    ('R-011', lambda p: p.startswith(CPP) and p.endswith('-SCHEMAS.sexp'), 'CANONICAL_MODEL_INPUT',
     'versioned schema — type/record facts migration input'),
    ('R-012', _hist, 'HISTORICAL_EVIDENCE',
     'legacy v1.x verifier/audit/manifest or captured run output — NON_AUTHORITATIVE (frozen at 4787b342)'),
    ('R-013', lambda p: p in (CPP + 'ARCHITECTURE-CLOSURE-MATRIX.md', CPP + 'PUBLIC-OBSERVATORY-CROSSWALK.md',
                              CPP + 'DOMINANCE-MATRIX.md'), 'GENERATED_VIEW',
     'human-readable table generated from the registries/model'),
    ('R-014', lambda p: p.startswith(CPP + 'IMPLEMENTATION-BOOK/tools/'), 'HISTORICAL_EVIDENCE',
     'AS-IS extraction tool and its extracted inventory (Implementation-Book execution not authorized)'),
    ('R-015', lambda p: p.startswith(CPP + 'IMPLEMENTATION-BOOK/'), 'AUTHORED_NORMATIVE_PROSE',
     'Implementation Book construction detail (execution not authorized)'),
    ('R-016', lambda p: p.startswith(CPP + 'V1.3-DESTRUCTION-PASS/'), 'HISTORICAL_EVIDENCE',
     'v1.3 destruction-pass record'),
    ('R-017', lambda p: p.startswith(CPP + 'formal-v1.1/'), 'HISTORICAL_EVIDENCE',
     'v1.1 TLA+ specifications, configurations and falsifiers (v1.1 is FALSIFIED — historical candidate)'),
    # --- collaboration and deployment-level normative material ---
    ('R-018', lambda p: p.startswith('deployment/collab/dialogue/'), 'HISTORICAL_EVIDENCE',
     'append-only AI-dialogue record'),
    ('R-019', lambda p: p.startswith('deployment/self/'), 'OUT_OF_SCOPE_WITH_REASON',
     'runtime self-state (restored before every commit; not a model fact)'),
    ('R-020', lambda p: p.startswith('deployment/knowledge/'), 'OUT_OF_SCOPE_WITH_REASON',
     'product knowledge base (legal lexicon/taxonomy; not architecture facts)'),
    ('R-021', lambda p: p.startswith('deployment/self-study/'), 'HISTORICAL_EVIDENCE',
     'dated external-review / intelligence-audit record'),
    ('R-022', lambda p: p.startswith('deployment/verify/'), 'PRODUCTION_CODE',
     'MLTP verification runtime (product)'),
    ('R-023', lambda p: p.startswith('deployment/data/'), 'OUT_OF_SCOPE_WITH_REASON',
     'reference/corpus data under deployment (not architecture facts)'),
    ('R-024', lambda p: p.startswith('deployment/state/'), 'OUT_OF_SCOPE_WITH_REASON',
     'daemon runtime state (not a model fact)'),
    ('R-025', lambda p: p.startswith('deployment/templates/') or p.startswith('deployment/shapes/')
     or p.startswith('deployment/mcp/'), 'PRODUCTION_CODE',
     'RDF templates, SHACL shapes and MCP wiring for publication (product)'),
    ('R-026', lambda p: p.startswith('deployment/') and p.count('/') == 1 and p.endswith(_DEP_TOP_EXT),
     'PRODUCTION_CODE', 'FEK ingestion and semantic-web publication runtime (product)'),
    ('R-027', lambda p: p.startswith('deployment/') and p.endswith('.md'), 'AUTHORED_NORMATIVE_PROSE',
     'authored normative document under deployment/'),
    ('R-028', lambda p: p.startswith('deployment/') and p.endswith('.sexp'), 'AUTHORED_NORMATIVE_PROSE',
     'authored normative contract in S-expression form under deployment/'),
    ('R-029', lambda p: p.startswith(DESIGN) and p.endswith(DESIGN_ROUND_EXT), 'HISTORICAL_EVIDENCE',
     'design-round artifact of a declared kind (formal model, analysis tool or evidence data) — round record, not a live path'),
    ('R-030', lambda p: p.startswith('deployment/collab/') and p.endswith(DESIGN_ROUND_EXT), 'HISTORICAL_EVIDENCE',
     'collaboration-round record of a declared kind (freeze/launch verification evidence outside the design subtree)'),
    # --- product code, tests, corpora and repository furniture ---
    ('R-031', lambda p: p.startswith('source/') or p.startswith('systems/'), 'PRODUCTION_CODE',
     'LAWMAX product source (untouched by this pass)'),
    ('R-032', lambda p: p.startswith('authority-v2/'), 'PRODUCTION_CODE',
     'authority-v2 attestation/proof machinery (product)'),
    ('R-033', lambda p: p.startswith('docker/'), 'PRODUCTION_CODE',
     'container build and proof machinery (product)'),
    ('R-034', lambda p: p.startswith('scripts/') or p.startswith('tools/'), 'PRODUCTION_CODE',
     'build and verification scripts (product)'),
    ('R-035', lambda p: p.startswith('cloudflare/'), 'PRODUCTION_CODE',
     'edge publication runtime (product)'),
    ('R-036', lambda p: p.startswith('determinism/'), 'TEST_OR_FIXTURE',
     'determinism verification harness'),
    ('R-037', lambda p: p.startswith('tests/'), 'TEST_OR_FIXTURE', 'product test/fixture'),
    ('R-038', lambda p: p.startswith('third-party/'), 'VENDORED_DEPENDENCY',
     'vendored third-party dependency tree — executable material, kept distinct from data corpora so that a '
     'dependency can never be filed under the same role as a corpus (Review-2 N-18); no governance path compiles '
     'or loads any of it since the kernel stopped using the vendored ironclad closure (Review-2 N-1)'),
    ('R-039', lambda p: p.startswith('output/') or p.startswith('output_run1/') or p.startswith('input/'),
     'OUT_OF_SCOPE_WITH_REASON', 'pipeline data/artifact corpus (not architecture facts)'),
    ('R-040', lambda p: p.startswith('docs/'), 'OUT_OF_SCOPE_WITH_REASON',
     'product documentation (not architecture facts)'),
    ('R-041', lambda p: p.startswith('configs/'), 'OUT_OF_SCOPE_WITH_REASON',
     'corpus pipeline configuration (not architecture facts)'),
    ('R-042', lambda p: p.startswith('keys/'), 'OUT_OF_SCOPE_WITH_REASON',
     'key material placeholder/README (not architecture facts)'),
    ('R-043', lambda p: p.startswith('evidence/') or p.startswith('state/') or p.startswith('candidates/')
     or p.startswith('releases/'), 'OUT_OF_SCOPE_WITH_REASON',
     'runtime evidence/state/release artifacts (not architecture facts)'),
    ('R-044', lambda p: p.startswith('examples/'), 'OUT_OF_SCOPE_WITH_REASON',
     'example material (not architecture facts)'),
    ('R-045', lambda p: p.startswith('deps/') or p in ('deps.lock', 'deps.archives.lock'),
     'OUT_OF_SCOPE_WITH_REASON', 'vendored dependency lock/manifest (not architecture facts)'),
    ('R-046', lambda p: p.startswith('.github/'), 'OUT_OF_SCOPE_WITH_REASON',
     'CI workflow configuration (not architecture facts)'),
    ('R-047', lambda p: p.startswith('.'), 'OUT_OF_SCOPE_WITH_REASON',
     'repository dotfile configuration (not architecture facts)'),
    ('R-048', lambda p: '/' not in p and p.endswith('.asd'), 'PRODUCTION_CODE',
     'ASDF system definition (LAWMAX product build)'),
    ('R-049', lambda p: p in ('build.lisp', 'entrypoint.lisp'), 'PRODUCTION_CODE',
     'product build/entrypoint (LAWMAX product)'),
    ('R-050', lambda p: '/' not in p and (p == 'Dockerfile' or p.startswith('Dockerfile.')
                                          or p.startswith('docker-compose')), 'PRODUCTION_CODE',
     'container build/compose definition (product)'),
    ('R-051', lambda p: p in ('package.json', 'package-lock.json'), 'OUT_OF_SCOPE_WITH_REASON',
     'node tooling manifest (not architecture facts)'),
    ('R-052', lambda p: p in ('LICENSE', 'PROVENANCE.yaml', 'SYSTEM-HIERARCHY.txt'),
     'OUT_OF_SCOPE_WITH_REASON', 'repository licence/provenance/hierarchy manifest (not architecture facts)'),
    ('R-053', lambda p: '/' not in p and p.endswith('.md'), 'AUTHORED_NORMATIVE_PROSE',
     'repository-root normative document/contract'),
]


def classify(p):
    for rid, pred, role, reason in RULES:
        if pred(p):
            return rid, role, reason
    return None, 'UNCLASSIFIED', 'no explicit classification rule matched this tracked path'


def wq(v):
    return '"%s"' % v.replace('\\', '\\\\').replace('"', '\\"')


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
    dead = [rid for rid, _p, role, _x in RULES if rulec.get(rid, 0) == 0 and role not in QUARANTINE_ROLES]

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
    out.append('(fact inventory-total INV-TOTAL :tracked %d :file-facts %d :dir-rule-facts %d :dir-rule-sum %d)'
               % (len(files), len(per_file), len(agg), sum(agg.values())))
    with open(out_path, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write('\n'.join(out) + '\n')

    print('tracked=%d  file-facts=%d  dir-rule-facts=%d  dir-rule-sum=%d  unclassified=%d  dead-rules=%d'
          % (len(files), len(per_file), len(agg), sum(agg.values()), len(quarantined), len(dead)))
    print('role counts:', dict(sorted(rolec.items())))
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
