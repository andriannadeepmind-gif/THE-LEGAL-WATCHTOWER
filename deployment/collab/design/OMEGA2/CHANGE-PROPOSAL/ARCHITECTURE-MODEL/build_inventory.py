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

  * NO DEAD RULES.  Every rule must match at least one tracked path.  A rule that matches nothing — whether
    because it is obsolete or because an earlier rule shadows it — makes this program exit non-zero (exit 3).
    A rule that cannot fire is therefore not merely unused: it is a build failure.

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
AGGREGATE_ROLES = {'PRODUCTION_CODE', 'TEST_OR_FIXTURE', 'OUT_OF_SCOPE_WITH_REASON'}
ROLES = PER_FILE_ROLES | AGGREGATE_ROLES | {'UNCLASSIFIED'}

_HIST_RE = re.compile(r'/V1\.\d.*(AUDIT|VERIFY|EVIDENCE|MANIFEST|BOOTSTRAP|CONSISTENCY|KILL-WITNESSES'
                      r'|SEMANTIC-CROSSWALK|DESTRUCTION-PASS-RECORD|NARROW-DELTA)')
_DEP_TOP_EXT = ('.ttl', '.jsonld', '.json', '.js', '.sh')


def tracked_paths():
    """Exact tracked paths as git stores them.  -z => no quoting, no escaping, no ambiguity."""
    r = subprocess.run(['git', '-C', ROOT, 'ls-files', '-z'], capture_output=True)
    if r.returncode != 0:
        sys.stderr.write('FATAL: git ls-files -z failed: %s\n' % r.stderr.decode('utf-8', 'replace'))
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
    ('R-009', lambda p: p.startswith(AM) and p.endswith('.md'), 'AUTHORED_NORMATIVE_PROSE',
     'architecture-model authored document'),
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
    ('R-029', lambda p: p.startswith(DESIGN), 'HISTORICAL_EVIDENCE',
     'design-round artifact (formal model, analysis tool or evidence data) — round record, not a live path'),
    ('R-030', lambda p: p.startswith('deployment/collab/'), 'HISTORICAL_EVIDENCE',
     'collaboration-round record (freeze/launch verification evidence outside the design subtree)'),
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
    ('R-038', lambda p: p.startswith('third-party/'), 'OUT_OF_SCOPE_WITH_REASON',
     'vendored third-party sources (not architecture facts)'),
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
    out_path = os.path.join(HERE, 'files-and-roles.sexp')
    if len(sys.argv) == 3 and sys.argv[1] == '--out':
        out_path = os.path.abspath(sys.argv[2])
    elif len(sys.argv) != 1:
        sys.stderr.write('usage: build_inventory.py [--out PATH]\n')
        sys.exit(2)
    files, undecodable = tracked_paths()
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
        if role == 'UNCLASSIFIED':
            quarantined.append(p)
        elif role in PER_FILE_ROLES:
            per_file.append((p, rid, role, reason))
        else:
            bulk.append((p, rid, role, reason))

    dead = [rid for rid, _p, _r, _x in RULES if rulec.get(rid, 0) == 0]

    out = [';;;; files-and-roles.sexp — every tracked file classified exactly once (no-loss).',
           ';;;; GENERATED by build_inventory.py.  Do not edit by hand.',
           ';;;; Paths are the exact bytes reported by `git ls-files -z` (git never C-quotes with -z).',
           ';;;; Every classification cites the rule id that produced it; there is no catch-all rule.',
           ';;;; Roles named individually (one `file` fact each): ' + ' '.join(sorted(PER_FILE_ROLES)),
           ';;;; Roles counted in bulk (one `dir-rule` fact per top-level directory and rule): '
           + ' '.join(sorted(AGGREGATE_ROLES)),
           ';;;; Invariant: (count of file facts) + (sum of dir-rule :count) = (count of tracked paths).', '']
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
        sys.stderr.write('UNCLASSIFIED — %d tracked path(s) matched no explicit rule:\n' % len(quarantined))
        for p in quarantined:
            sys.stderr.write('  %s\n' % p)
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
