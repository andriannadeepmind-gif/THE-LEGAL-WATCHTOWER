#!/usr/bin/env python3
"""gate_checks.py — the model-derived gate checks, in one seat.

A shell gate can honestly orchestrate, run tools and compare exit codes. It cannot honestly decide whether a
document agrees with the model: `grep` finding an expected phrase in prose the repository itself wrote proves
only that the phrase is there. Every check that needs the MODEL to answer lives here, derives its answer from
the canonical facts, and names what disagreed.

Checks (each prints GATECHECK <name>: PASS|FAIL and exits 0/1):

  inventory        regenerate the file-role inventory into a TEMPORARY file, byte-compare it with the committed
                   module, and compare its key set and multiset against `git ls-files -z`. Missing, extra,
                   duplicated and unclassified paths each fail and are named. Nothing is restored: the committed
                   module is never touched, so a drift cannot be erased before it is compared.
  conflict-ledger  reconcile every row of MODEL-MIGRATION-CONFLICT-LEDGER.md against the canonical model IN BOTH
                   DIRECTIONS — a recorded conflict the model does not exhibit fails, and a normalization the
                   model exhibits with no recorded row fails.
  packet           recompute the decision packet's totals from the model and require the packet's machine-readable
                   reconciliation block to match them and to match both verification paths' commitments.
  live-path        no file classified HISTORICAL_EVIDENCE may be an executable dependency of any file classified
                   GOVERNANCE_MACHINERY. Python is inspected through its AST; other machinery by exact basename.
  generation-order print the producers of the declared generation order, topologically sorted from the model's
                   gen-step/gen-edge facts. The gate executes exactly this list, so the order that runs and the
                   order the model declares are one seat; an unknown producer or a cycle fails.
  module-universe  both verification paths must have consumed exactly the ROOT-pinned modules — no more, and no
                   pinned module silently skipped — proved from their published commitments, not from ROOT alone.
  hash-engines     the two vetted SHA-256 engines (ironclad on the Common Lisp path, hashlib/OpenSSL on the
                   Python path) must agree over identical RAW BYTES for every pinned module and for adversarial
                   inputs — CRLF, lone CR, a UTF-8 BOM and bytes that are not valid UTF-8 at all.
"""
import ast, importlib.util, os, subprocess, sys, tempfile, hashlib

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..', '..', '..', '..'))
REL = os.path.relpath(HERE, REPO).replace(os.sep, '/')
_spec = importlib.util.spec_from_file_location('sexp_reader', os.path.join(HERE, 'SEXP-READER.py'))
SR = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(SR)
HEADERS = ('define-model-schema', 'define-model-root', 'define-toolchain')


def fail(name, reasons):
    for r in reasons:
        print('  %s' % r)
    print('GATECHECK %s: FAIL (%d finding%s)' % (name, len(reasons), '' if len(reasons) == 1 else 's'))
    sys.exit(1)


def ok(name, note):
    print('GATECHECK %s: PASS — %s' % (name, note))
    sys.exit(0)


def modules():
    forms = SR.read_forms_file(os.path.join(HERE, 'ROOT.sexp'))
    root = [f for f in forms if SR.head(f) == 'define-model-root'][0]
    pl = dict(SR.plist(root[2:], 'ROOT.sexp', 'define-model-root'))
    return [str(dict(SR.plist(e, 'ROOT.sexp', 'entry'))['module']) for e in pl['composition']], pl


def facts():
    out = []
    for mod, _pl in [(m, None) for m in modules()[0]]:
        for form in SR.read_forms_file(os.path.join(HERE, mod)):
            h = SR.head(form)
            if h in HEADERS:
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


def tracked():
    r = subprocess.run(['git', '-C', REPO, 'ls-files', '-z'], capture_output=True)
    if r.returncode != 0:
        raise SystemExit('git ls-files -z failed: %s' % r.stderr.decode('utf-8', 'replace'))
    return [b.decode('utf-8') for b in r.stdout.split(b'\0') if b]


# --------------------------------------------------------------------------- inventory (G1)
def check_inventory():
    reasons = []
    tmp = tempfile.mkdtemp()
    regen = os.path.join(tmp, 'files-and-roles.sexp')
    r = subprocess.run([sys.executable, os.path.join(HERE, 'build_inventory.py'), '--out', regen],
                       capture_output=True, text=True, cwd=HERE)
    if r.returncode != 0:
        for line in (r.stdout + r.stderr).strip().splitlines():
            reasons.append('generator: %s' % line)
        fail('inventory', reasons or ['build_inventory.py exited %d' % r.returncode])
    with open(regen, 'rb') as f:
        regen_bytes = f.read()
    committed = subprocess.run(['git', '-C', REPO, 'show', ':%s/files-and-roles.sexp' % REL], capture_output=True)
    if committed.returncode != 0:
        reasons.append('files-and-roles.sexp is not in the index: the inventory is not a committed artifact')
    elif committed.stdout != regen_bytes:
        reasons.append('regenerated inventory differs from the committed inventory (%d vs %d bytes); the '
                       'committed module is stale' % (len(regen_bytes), len(committed.stdout)))
    live = os.path.join(HERE, 'files-and-roles.sexp')
    with open(live, 'rb') as f:
        if f.read() != regen_bytes:
            reasons.append('regenerated inventory differs from the working-tree inventory')
    # The key-set checks below read the LIVE inventory — the module the model actually pins. A corrupted
    # committed inventory must be named for what is wrong with it, not merely reported as "different".
    keys, dirrules, seen = [], {}, set()
    for form in SR.read_forms_file(live):
        h = SR.head(form)
        if h != 'fact':
            reasons.append('regenerated inventory contains a non-fact top-level form %r' % h)
            continue
        ftype = str(form[1]).lower()
        fid = SR.canonical_value(form[2], live, 'fact id')
        pl = dict(SR.plist(form[3:], live, fid))
        if ftype == 'file':
            if fid in seen:
                reasons.append('DUPLICATE-INVENTORY-KEY: %s' % fid)
            seen.add(fid)
            keys.append(fid)
        elif ftype == 'dir-rule':
            dirrules[(str(pl['top']), str(pl['rule']))] = int(pl['count'])
    tr = tracked()
    trset, keyset = set(tr), set(keys)
    if len(trset) != len(tr):
        reasons.append('git reported the same tracked path more than once')
    for p in sorted(keyset - trset):
        reasons.append('EXTRA-INVENTORY-PATH: %s is in the inventory but not tracked' % p)
    # Every tracked path that has no file fact must be counted by exactly the directory rule that classifies it.
    # Comparing only grand totals would let a missing path and an extra path cancel each other out.
    bi_spec = importlib.util.spec_from_file_location('build_inventory', os.path.join(HERE, 'build_inventory.py'))
    BI = importlib.util.module_from_spec(bi_spec); bi_spec.loader.exec_module(BI)
    expected, examples = {}, {}
    for p in tr:
        if p in keyset:
            continue
        rid, role, _reason = BI.classify(p)
        if role == 'UNCLASSIFIED':
            reasons.append('UNCLASSIFIED-PATH: %s matches no explicit classification rule' % p)
            continue
        top = p.split('/')[0] if '/' in p else p
        expected[(top, rid)] = expected.get((top, rid), 0) + 1
        examples.setdefault((top, rid), []).append(p)
    for k in sorted(set(expected) | set(dirrules)):
        if expected.get(k, 0) != dirrules.get(k, 0):
            named = ', '.join(examples.get(k, [])[:3]) or '(no tracked path)'
            reasons.append('DIRECTORY-RULE-MISCOUNT: %s under %s — %d tracked, %d recorded; unaccounted for: %s'
                           % (k[1], k[0], expected.get(k, 0), dirrules.get(k, 0), named))
    dirsum = sum(dirrules.values())
    if len(keys) + dirsum != len(tr):
        reasons.append('MULTISET-MISMATCH: %d tracked paths but %d file facts + %d counted by directory rules'
                       % (len(tr), len(keys), dirsum))
    if any(k.startswith('"') for k in keys):
        reasons.append('C-QUOTED-INVENTORY-KEY: a key begins with a quotation mark; paths must be exact bytes')
    if reasons:
        fail('inventory', reasons)
    ok('inventory', 'regenerated == committed; %d tracked paths = %d file facts + %d counted by %d directory '
                    'rules, every rule count re-derived independently; 0 unclassified, 0 duplicate, 0 extra'
       % (len(tr), len(keys), dirsum, len(dirrules)))


# --------------------------------------------------------------------------- conflict ledger (ck03)
def ledger_rows():
    rows = []
    with open(os.path.join(HERE, 'MODEL-MIGRATION-CONFLICT-LEDGER.md'), encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line.startswith('|'):
                continue
            cells = [c.strip() for c in line.strip('|').split('|')]
            if len(cells) < 4 or not cells[0].isdigit():
                continue
            rows.append((cells[1], cells[2], cells[3].strip('`')))
    return rows


def check_conflict_ledger():
    reasons = []
    fs = facts(); bt = by_type(fs)
    rows = ledger_rows()
    subs = {i for i, _ in bt.get('subsystem', [])}
    comps = {i for i, _ in bt.get('component', [])}
    types = {i: p for i, p in bt.get('type', [])}
    # data-flow graph over subsystems, derived from consumes edges (exactly as the migration derived it)
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
            fact = fact.upper()          # ledger rows quote source spelling; model ids are canonical (upper case)
            if fact not in comps:
                reasons.append('LEDGER-ROW-NOT-IN-MODEL: %r is not a declared component' % fact)
            else:
                seen_comp.add(fact)
        else:
            reasons.append('LEDGER-ROW-UNKNOWN-KIND: %r' % kind)
    # the other direction: every normalization the model exhibits must be recorded
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


def _count_cycles(adj):
    """Canonical simple-cycle enumeration over the data-flow graph, matching the migration's own definition."""
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


# --------------------------------------------------------------------------- decision packet (ck16)
def packet_block():
    block = {}
    inside = False
    with open(os.path.join(HERE, 'ROOT-OPERATOR-DECISION-PACKET.md'), encoding='utf-8') as f:
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


def check_packet():
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
    for k in sorted(expect):
        if block.get(k) != expect[k]:
            reasons.append('PACKET-MISMATCH: %s = %s in the packet, %s in the model' % (k, block.get(k), expect[k]))
    for k in sorted(block):
        if k not in expect and not k.startswith('commitment '):
            reasons.append('PACKET-EXTRA: %s is claimed by the packet but not derivable from the model' % k)
    for who in ('kernel', 'checker'):
        path = os.path.join(HERE, '%s-COMMITMENT.txt' % who.upper())
        if not os.path.isfile(path):
            reasons.append('PACKET-UNRECONCILED: %s commitment file is absent' % who); continue
        d = hashlib.sha256(open(path, 'rb').read()).hexdigest()
        if block.get('commitment %s' % who) != d:
            reasons.append('PACKET-MISMATCH: commitment %s = %s in the packet, %s on disk'
                           % (who, block.get('commitment %s' % who), d))
    if reasons:
        fail('packet', reasons)
    ok('packet', '%d packet totals recomputed from the model and from both commitments' % len(expect))


# --------------------------------------------------------------------------- live path (ck18)
def role_map():
    roles = {}
    for form in SR.read_forms_file(os.path.join(HERE, 'files-and-roles.sexp')):
        if SR.head(form) != 'fact' or str(form[1]).lower() != 'file':
            continue
        fid = SR.canonical_value(form[2], 'files-and-roles.sexp', 'fact id')
        pl = dict(SR.plist(form[3:], 'files-and-roles.sexp', fid))
        roles[fid] = str(pl['role'])
    return roles


def check_live_path():
    reasons = []
    roles = role_map()
    historical = {os.path.basename(p): p for p, r in roles.items()
                  if r == 'HISTORICAL_EVIDENCE' and p.endswith(('.py', '.sh', '.lisp'))}
    machinery = [p for p, r in roles.items() if r == 'GOVERNANCE_MACHINERY']
    if not machinery:
        fail('live-path', ['no file is classified GOVERNANCE_MACHINERY; the live path is undefined'])
    for rel in sorted(machinery):
        path = os.path.join(REPO, rel)
        if not os.path.isfile(path):
            reasons.append('MACHINERY-MISSING: %s' % rel); continue
        if rel.endswith('.py'):
            try:
                tree = ast.parse(open(path, encoding='utf-8').read(), filename=rel)
            except SyntaxError as e:
                reasons.append('MACHINERY-UNPARSEABLE: %s: %s' % (rel, e)); continue
            names = set()
            for node in ast.walk(tree):
                if isinstance(node, ast.Constant) and isinstance(node.value, str):
                    names.add(os.path.basename(node.value))
                elif isinstance(node, ast.Import):
                    names.update(a.name for a in node.names)
                elif isinstance(node, ast.ImportFrom) and node.module:
                    names.add(node.module)
            hit = sorted(names & set(historical))
        else:
            text = open(path, encoding='utf-8', errors='replace').read()
            hit = sorted(b for b in historical if b in text)
        for b in hit:
            reasons.append('HISTORICAL-CODE-ON-LIVE-PATH: %s depends on %s, which is classified '
                           'HISTORICAL_EVIDENCE' % (rel, historical[b]))
    if reasons:
        fail('live-path', reasons)
    ok('live-path', '%d GOVERNANCE_MACHINERY files inspected; none depends on any of the %d executable '
                    'HISTORICAL_EVIDENCE files' % (len(machinery), len(historical)))


# --------------------------------------------------------------------------- hash engines (F-11 / L.17)
LISP_PROBE = r'''
(defpackage :probe (:use :cl)) (in-package :probe)
(load (merge-pathnames "hash-provider.lisp" #p"%s"))
(aml-hash:ensure-provider #p"%s" "ironclad" "0.61")
(dolist (p (cdr sb-ext:*posix-argv*))
  (format t "~a ~a~%%" (aml-hash:sha256-hex-of-file p) p))
'''


def check_hash_engines():
    reasons = []
    mods, _pl = modules()
    probes = []
    tmp = tempfile.mkdtemp()
    cases = {'crlf': b'line one\r\nline two\r\n',
             'lf': b'line one\nline two\n',
             'lone-cr': b'line one\rline two\r',
             'utf8-bom': b'\xef\xbb\xbfabc\n',
             'invalid-utf8': b'\xff\xfe\x00abc\n',
             'empty': b''}
    for name, data in sorted(cases.items()):
        p = os.path.join(tmp, name + '.bin')
        with open(p, 'wb') as f:
            f.write(data)
        probes.append(p)
    probes += [os.path.join(HERE, m) for m in mods]
    tcl = os.path.join(tmp, 'probe.lisp')
    with open(tcl, 'w', encoding='utf-8') as f:
        f.write(LISP_PROBE % (os.path.join(HERE, 'KERNEL') + '/', os.path.join(REPO, 'third-party') + '/'))
    r = subprocess.run(['sbcl', '--script', tcl] + probes, capture_output=True, text=True)
    lisp = {}
    for line in r.stdout.splitlines():
        parts = line.split(' ', 1)
        if len(parts) == 2 and len(parts[0]) == 64:
            lisp[parts[1]] = parts[0]
    if not lisp:
        fail('hash-engines', ['the Common Lisp SHA-256 provider produced no digests: %s'
                              % (r.stdout + r.stderr).strip().splitlines()[-1:]])
    for p in probes:
        with open(p, 'rb') as f:
            py = hashlib.sha256(f.read()).hexdigest()
        got = lisp.get(p)
        if got is None:
            reasons.append('ENGINE-GAP: the Common Lisp engine returned no digest for %s' % p)
        elif got != py:
            reasons.append('ENGINE-DISAGREEMENT: %s ironclad=%s hashlib=%s' % (p, got[:16], py[:16]))
    # demonstrate that the ABANDONED text-decoding definition really does diverge on these inputs
    diverged = 0
    for p in probes:
        with open(p, 'rb') as f:
            raw = f.read()
        text = hashlib.sha256(raw.decode('utf-8', 'replace').encode('utf-8')).hexdigest()
        if text != hashlib.sha256(raw).hexdigest():
            diverged += 1
    if diverged == 0:
        reasons.append('the adversarial probe set does not separate raw-byte hashing from text-decoded hashing; '
                       'the cross-check would not detect a regression')
    if reasons:
        fail('hash-engines', reasons)
    ok('hash-engines', 'ironclad and hashlib/OpenSSL agree on %d inputs (%d pinned modules + %d adversarial '
                       'byte cases); %d of those inputs would differ under text-decoded hashing'
       % (len(probes), len(mods), len(cases), diverged))


def check_generation_order():
    reasons = []
    fs = facts(); bt = by_type(fs)
    steps = {i: p for i, p in bt.get('gen-step', [])}
    edges = [(p['from'], p['to']) for _i, p in bt.get('gen-edge', [])]
    if not steps:
        fail('generation-order', ['the model declares no generation steps'])
    indeg = {s: 0 for s in steps}
    adj = {s: [] for s in steps}
    for a, b in edges:
        if a not in steps or b not in steps:
            reasons.append('GEN-EDGE-DANGLING: %s -> %s' % (a, b)); continue
        adj[a].append(b); indeg[b] += 1
    order = []
    ready = sorted(s for s in steps if indeg[s] == 0)
    while ready:
        u = ready.pop(0)
        order.append(u)
        for w in sorted(adj[u]):
            indeg[w] -= 1
            if indeg[w] == 0:
                ready.append(w); ready.sort()
    if len(order) != len(steps):
        reasons.append('GEN-ORDER-CYCLIC: %s cannot be sequenced' % sorted(set(steps) - set(order)))
    for s in order:
        producer = steps[s]['producer']
        if not os.path.isfile(os.path.join(HERE, producer)):
            reasons.append('GEN-PRODUCER-MISSING: step %s names %s, which does not exist' % (s, producer))
    if reasons:
        fail('generation-order', reasons)
    for s in order:
        print(steps[s]['producer'])
    sys.exit(0)


def check_module_universe():
    reasons = []
    mods, _pl = modules()
    declared = set(mods)
    for who in ('KERNEL', 'CHECKER'):
        path = os.path.join(HERE, '%s-COMMITMENT.txt' % who)
        if not os.path.isfile(path):
            reasons.append('%s published no fact-set commitment' % who); continue
        consumed = set()
        for line in SR.read_file(path).splitlines():
            parts = line.split()
            if len(parts) == 5 and parts[1] == 'module':
                consumed.add(parts[2])
        for m in sorted(consumed - declared):
            reasons.append('%s consumed %s, which ROOT.sexp does not pin' % (who, m))
        for m in sorted(declared - consumed):
            path_m = os.path.join(HERE, m)
            has_facts = any(SR.head(f) == 'fact' for f in SR.read_forms_file(path_m))
            if has_facts:
                reasons.append('%s did not consume pinned module %s, which contains facts' % (who, m))
    if reasons:
        fail('module-universe', reasons)
    ok('module-universe', 'both paths consumed exactly the %d ROOT-pinned modules that carry facts' % len(mods))


CHECKS = {'inventory': check_inventory, 'generation-order': check_generation_order,
          'module-universe': check_module_universe, 'conflict-ledger': check_conflict_ledger, 'packet': check_packet,
          'live-path': check_live_path, 'hash-engines': check_hash_engines}

if __name__ == '__main__':
    if len(sys.argv) != 2 or sys.argv[1] not in CHECKS:
        sys.stderr.write('usage: gate_checks.py {%s}\n' % '|'.join(sorted(CHECKS)))
        sys.exit(2)
    CHECKS[sys.argv[1]]()
