#!/usr/bin/env python3
# V1.8-VERIFY.py — standalone, re-runnable guard runner for the v1.8 verification harness.
#
# GENERALIZATION PASS: structural verification of the .sexp sources is done with a REAL recursive-descent
# s-expression reader (an AST reader, the same shape as a Lisp reader with *read-eval* nil — it never evaluates,
# only builds a tree). No `.*?`, bounded substring window, or raw substring is used as structural-identity proof.
# The AST preserves nested type expressions, exact top-level form identity, duplicate forms, field ownership and
# cardinality, edge families and endpoints, exact enum membership, and exact reference targets. Regex is used ONLY
# for Markdown prose (the traceability table, .md locators) and for locating line-anchored top-level form opens,
# after which each form is re-read with the AST reader.
#
# Guard = clean (violations==0, exit 0) or rejects (violations>0, exit 3). A crash exits 2. Mutations are produced
# by `mutate`, which writes REAL baseline + REAL mutated bytes to a workspace so the orchestrator can hash the
# actual files and rerun the SAME guard against the mutated bytes.
#
# Usage:
#   V1.8-VERIFY.py list-guards | list-muts <GID>
#   V1.8-VERIFY.py run <GID> [--file KEY=PATH ...]      -> "OK|VIOLATION <reason>"; exit 0/3/2
#   V1.8-VERIFY.py mutate <GID> <MID> --outdir DIR      -> "KEY BASE MUT"
#   V1.8-VERIFY.py aggregate                            -> full 4^N root-authority product result line
#   V1.8-VERIFY.py selftest                             -> baseline 0 for every guard; every mutant flips
#   V1.8-VERIFY.py --selfcrash                          -> deliberate crash (meta-kill hook)
import sys, os, re, hashlib, itertools

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..', '..', '..', '..'))
DEFAULTS = {
    'schema': os.path.join(HERE, 'V1.8-SCHEMAS.sexp'),
    's17':    os.path.join(HERE, 'V1.7-SCHEMAS.sexp'),
    's16':    os.path.join(HERE, 'V1.6-SCHEMAS.sexp'),
    'isr':    os.path.join(HERE, 'INTERFACE-AND-SCHEMA-REGISTRY.sexp'),
    'sub':    os.path.join(HERE, 'SUBSYSTEM-REGISTRY.sexp'),
    'trc':    os.path.join(HERE, 'TRACEABILITY-MATRIX.md'),
    'man':    os.path.join(HERE, 'V1.8-CANDIDATE-MANIFEST.md'),
    'mcp':    os.path.join(ROOT, 'source', 'mcp-server.lisp'),
    'site':   os.path.join(ROOT, 'source', 'static-site.lisp'),
}
BYBASENAME = {os.path.basename(p): k for k, p in DEFAULTS.items()}

def readpath(p):
    with open(p, encoding='utf-8', errors='replace') as f:
        return f.read()

def load(overrides):
    return {k: readpath(overrides.get(k, dp)) for k, dp in DEFAULTS.items()}

def openroot(relpath):
    for base in (os.path.join(ROOT, relpath), os.path.join(HERE, relpath), relpath):
        if os.path.isfile(base):
            try:
                return readpath(base)
            except Exception:
                return None
    return None

def open_or_loaded(relpath, F):
    bn = os.path.basename(relpath)
    if bn in BYBASENAME and BYBASENAME[bn] in F:
        return F[BYBASENAME[bn]]
    return openroot(relpath)

# ============================ REAL s-expression AST reader (no eval, no regex) ============================
class Sym(str):
    __slots__ = ()
class Str(str):
    __slots__ = ()

_ATOM_STOP = set(' \t\r\n\f()";')

class ParseError(ValueError):
    pass

def _skip_ws(text, i, n):
    """skip whitespace, ; line comments, and #| block comments |# — raise on an unterminated block comment."""
    while i < n:
        c = text[i]
        if c == ';':
            while i < n and text[i] != '\n':
                i += 1
        elif c == '#' and i + 1 < n and text[i + 1] == '|':
            depth = 1; i += 2
            while i < n and depth > 0:
                if text[i] == '#' and i + 1 < n and text[i + 1] == '|':
                    depth += 1; i += 2
                elif text[i] == '|' and i + 1 < n and text[i + 1] == '#':
                    depth -= 1; i += 2
                else:
                    i += 1
            if depth > 0:
                raise ParseError('unterminated block comment')
        elif c in ' \t\r\n\f':
            i += 1
        else:
            break
    return i

def _read_one(text, i):
    n = len(text)
    i = _skip_ws(text, i, n)
    if i >= n:
        return None, i
    c = text[i]
    if c == '(':
        i += 1; lst = []
        while True:
            i = _skip_ws(text, i, n)
            if i >= n:
                raise ParseError('unclosed list')
            if text[i] == ')':
                return lst, i + 1
            f, i = _read_one(text, i)
            lst.append(f)
    if c == ')':
        raise ParseError('unexpected )')
    if c == '"':
        i += 1; buf = []
        while i < n:
            d = text[i]
            if d == '\\' and i + 1 < n:
                buf.append(text[i + 1]); i += 2; continue
            if d == '"':
                return Str(''.join(buf)), i + 1
            buf.append(d); i += 1
        raise ParseError('unterminated string')
    if c == '|':                       # |vertical-bar symbol|
        i += 1; buf = []
        while i < n and text[i] != '|':
            buf.append(text[i]); i += 1
        if i >= n:
            raise ParseError('unterminated vertical-bar symbol')
        return Sym('|' + ''.join(buf) + '|'), i + 1
    if c == '#':
        nxt = text[i + 1] if i + 1 < n else ''
        if nxt == '\\':              # #\x character literal
            j = i + 2
            if j < n:
                j += 1
            while j < n and text[j] not in _ATOM_STOP:
                j += 1
            return Sym(text[i:j]), j
        # every other reader-macro dispatch (#. read-eval, #(, #', #+, #-, #b/#x, ...) is UNSUPPORTED and rejected
        raise ParseError('unsupported dispatch #' + (nxt if nxt else '<eof>'))
    j = i
    while j < n and text[j] not in _ATOM_STOP:
        j += 1
    return Sym(text[i:j]), j

def read_all(text):
    """Parse the WHOLE input into top-level forms. Raises ParseError on any malformed or trailing content —
    never silently returns a truncated list. This is the fail-closed reader used for structural verification."""
    out = []; i = 0; n = len(text)
    while True:
        f, i = _read_one(text, i)
        if f is None:
            break
        out.append(f)
    i = _skip_ws(text, i, n)
    if i < n:
        raise ParseError('trailing content at offset %d: %r' % (i, text[i:i + 20]))
    return out

def parse_ok(text):
    try:
        read_all(text); return True, ''
    except ParseError as e:
        return False, str(e)
    except Exception as e:
        return False, type(e).__name__ + ': ' + str(e)

def is_list(x):
    return isinstance(x, list)
def head(f):
    return f[0] if (is_list(f) and f and isinstance(f[0], Sym)) else None
def form_name(f):
    return f[1] if (is_list(f) and len(f) > 1 and isinstance(f[1], Sym)) else None
def forms_by_head(forms, h):
    return [f for f in forms if head(f) is not None and str(head(f)) == h]

def kv_after(form, key):
    """value that immediately follows a bare keyword Sym `key` at the top level of `form`."""
    for idx, el in enumerate(form):
        if isinstance(el, Sym) and str(el) == key and idx + 1 < len(form):
            return form[idx + 1]
    return None

def record_attrs_fields(form):
    attrs = {}; fields = []
    items = form[2:] if (is_list(form) and len(form) > 2) else []
    k = 0
    while k < len(items):
        it = items[k]
        if isinstance(it, Sym) and it.startswith(':'):
            attrs[str(it)] = items[k + 1] if k + 1 < len(items) else None
            k += 2; continue
        if is_list(it):
            fields.append(it)
        k += 1
    return attrs, fields

def field_key(field):
    return str(field[0]) if (is_list(field) and field and isinstance(field[0], Sym)) else None
def field_type_expr(field):
    return kv_after(field, ':type')

def type_refs(node):
    out = []
    if isinstance(node, Sym):
        if node.endswith('/1'):
            out.append(str(node))
    elif is_list(node):
        for x in node:
            out.extend(type_refs(x))
    return out

def type_tokens(s):
    """Whole-word `X/1` type references in a free-text label or in source code (prose/code, not schema structure).
    Used for subsystem :interface labels, canonical type-locator strings, and mcp/static-site source scans."""
    return re.findall(r'(?<![\\w/-])([A-Za-z][A-Za-z0-9_]*/1)(?![\\w/-])', s)

def edge_pairs(node):
    """node is a list of 2-element (src tgt) lists -> [(src,tgt),...] preserving endpoints exactly."""
    out = []
    if is_list(node):
        for e in node:
            if is_list(e) and len(e) >= 2 and isinstance(e[0], Sym) and isinstance(e[1], Sym):
                out.append((str(e[0]), str(e[1])))
    return out

def sym_list(node):
    return [str(x) for x in node if isinstance(x, Sym)] if is_list(node) else []

def top_forms(text):
    # fail-closed: a malformed source raises ParseError (caught by the parse-gate as a VIOLATION, never swallowed)
    return read_all(text)

def top_symbols(text):
    """Names of every top-level def/define-* form. Line-anchored `^(` (prose-level) locates each top-level open;
    each form is then re-read with the AST reader — the identity is proven structurally, never by substring."""
    syms = set()
    for m in re.finditer(r'(?m)^\(', text):
        try:
            f, _ = _read_one(text, m.start())
        except Exception:
            continue
        h = head(f); nm = form_name(f)
        if h is not None and (str(h).startswith('def')) and nm is not None:
            syms.add(str(nm))
    return syms

# ============================ derived type universe (AST) ============================
def all_record_forms(F):
    forms = []
    for key in ('schema', 's17', 's16'):
        forms += forms_by_head(top_forms(F[key]), 'define-record')
    return forms
def all_reference_forms(F):
    forms = []
    for key in ('schema', 's17', 's16'):
        forms += forms_by_head(top_forms(F[key]), 'define-reference')
    return forms
def isr_interface_forms(F):
    return forms_by_head(top_forms(F['isr']), 'define-interface')

def defined_types(F):
    d = set()
    for f in all_record_forms(F) + all_reference_forms(F) + isr_interface_forms(F):
        if form_name(f):
            d.add(str(form_name(f)))
    return d

def private_types(F):
    priv = set()
    for f in all_record_forms(F):
        attrs, _ = record_attrs_fields(f)
        st = attrs.get(':status')
        pd = attrs.get(':public-dependency')
        if (pd is not None and str(pd) == 'nil') or (st is not None and str(st) in
                (':DEFERRED_PRIVATE', ':INTERFACE_ONLY', ':SPECIFICATION_ONLY')):
            if form_name(f):
                priv.add(str(form_name(f)))
    for f in isr_interface_forms(F):
        # interface head keyword attrs
        body = f[2:] if len(f) > 2 else []
        flat = ' '.join(str(x) for x in body if isinstance(x, (Sym, Str)))
        st = kv_after(f, ':status')
        pd = kv_after(f, ':public-dependency')
        cl = kv_after(f, ':classification')
        if ((pd is not None and str(pd) == 'nil') or (st is not None and str(st) in
                (':DEFERRED_PRIVATE', ':INTERFACE_ONLY')) or (cl is not None and str(cl) == ':RESTRICTED')):
            if form_name(f):
                priv.add(str(form_name(f)))
    return priv

def public_interfaces(F, priv):
    roots = {}
    for f in isr_interface_forms(F):
        nm = form_name(f)
        if nm is None or str(nm) in priv:
            continue
        if kv_after(f, ':classification') is not None and str(kv_after(f, ':classification')) == ':NORMATIVE':
            roots[str(nm)] = f
    return roots

def record_field_edges(F):
    adj = {}
    for f in all_record_forms(F):
        nm = form_name(f)
        if nm is None:
            continue
        _, fields = record_attrs_fields(f)
        refs = []
        for fld in fields:
            te = field_type_expr(fld)
            refs += type_refs(te)
        adj[str(nm)] = refs
    return adj

# ============================ GUARDS ============================
PRIM = {'ref', 'id', 'sha256', 'sig', 'instant', 'scope', 'semver', 'text', 'keyword', 'pubkey',
        'kid', 'anchor', 'usc-id', 'duration', 'uncertainty', 'null', 'span', 'mime', 'url', 'bool'}

# ============================ PINNED EXPECTED UNIVERSES (the normative sets the guards enforce) ============================
EXPECTED_CANON = {
    'LegalIR/1':                 ('deployment/LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md', 'lawmax/legal-ir/1', 'Counterproof'),
    'TrustBundle/1':             ('deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md', 'lawmax/trust-bundle/1', 'TrustBundle'),
    'MemoryEvent/1':             ('source/memory.lisp', 'lawmax/memory-event/1', 'record-episode'),
    'CognitionResult/1':         ('deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.6-SCHEMAS.sexp', 'lawmax/cognition-result/1', 'CognitionResult/1'),
    'DeclassificationReceipt/1': ('deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.6-SCHEMAS.sexp', 'lawmax/declassification-receipt/1', 'DeclassificationReceipt/1'),
    'ResolverResult/1':          ('deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.7-SCHEMAS.sexp', 'lawmax/resolver-result/1', 'ResolverResult/1'),
    'DatasetSnapshot/1':         ('deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.7-SCHEMAS.sexp', 'lawmax/dataset-snapshot/1', 'DatasetSnapshot/1'),
    'RightsMatrix/1':            ('deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.7-SCHEMAS.sexp', 'lawmax/rights-matrix/1', 'RightsMatrix/1'),
}
EXPECTED_CAP = {   # capability -> (kind, file, package_or_None, symbol_or_section, subsystem, requirement, test)
    ':RESOLVE_IDENTIFIER':  ('CODE', 'source/canonical-uris.lisp', 'orchestrator.uris', 'get-eli-law-prefix', 'S25', 'RA-I', 'RA-Q-RESOLVE'),
    ':PUBLIC_RETRIEVAL':    ('CODE', 'source/static-site.lisp', 'orchestrator.static-site', 'emit-corpus-site', 'S13', 'RA-R', 'RA-Q-RETRIEVE'),
    ':CITATION_MEASURE':    ('CODE', 'source/ai-citation-strategy.lisp', 'orchestrator.ai-citation', 'export-citation-metrics', 'S15', 'RA-K', 'RA-Q-CITE'),
    ':DATASET_DISTRIBUTE':  ('CODE', 'source/ai-corpus-dump.lisp', 'orchestrator.ai-dump', 'emit-corpus-jsonl', 'S14', 'RA-T', 'RA-Q-DATASET'),
    ':JURIS_RATIO':         ('CODE', 'source/legal-decisions.lisp', 'orchestrator.decisions', 'decision-ratio', 'S07', 'RA-J', 'RA-Q-JURIS'),
    ':RIGHTS_LICENSE':      ('DOCUMENT', 'deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/LAWMAX-LICENSE-POLICY.md', None, 'RightsMatrix/1', 'S25', 'RA-L', 'RA-Q-LICENSE'),
    ':EXPRESSION_TRANSLATE':('DOCUMENT', 'deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md', None, 'lawmax/expression/1', 'S16', 'RA-E', 'RA-Q-TRANSLATE'),
}
EXPECTED_STORES = {   # store -> (owner_string, write_authority_string)
    'journal':               ('WP-03 journal.lisp', 'write-authority.lisp'),
    'memory':                ('memory.lisp', 'write-authority.lisp'),
    'legal-ir':              ('WP-03 legal-ast.lisp', 'write-authority.lisp'),
    'trust-bundle':          ('WP-06 MLTP-root', 'MLTP-threshold-custody'),
    'coverage-ledger':       ('WP-01 coverage-ledger.lisp[design-target]', 'coverage-owner'),
    'citation-observatory':  ('WP-13 citation-authority.lisp', 'observatory-collector'),
    'dataset-distribution':  ('WP-11 ai-corpus-dump.lisp', 'RA-T-signer'),
    'static-site':           ('WP-12 static-site.lisp', 'none'),
    'resolver-dataset':      ('RA-S25 canonical-uris.lisp', 'none'),
    'tenant-profile':        ('RA-S26 [interface-only]', 'none'),
}
EXPECTED_DIMS = {   # dimension -> (class, failure-class)   — the pinned mandatory/advisory + failure policy
    'security':         ('MANDATORY', 'WITHHELD'),
    'proof_integrity':  ('MANDATORY', 'MACHINE_UNVERIFIED'),
    'freshness':        ('MANDATORY', 'ATTRIBUTED_RELIANCE'),
    'rights':           ('MANDATORY', 'WITHHELD'),
    'coverage':         ('MANDATORY', 'ATTRIBUTED_RELIANCE'),
    'availability_ops': ('ADVISORY', 'ATTRIBUTED_RELIANCE'),
    'juris_access':     ('MANDATORY', 'WITHHELD'),
    'qualification':    ('ADVISORY', 'ATTRIBUTED_RELIANCE'),
}
EXPECTED_DFT = set('DFT-%02d' % i for i in range(1, 11))
EXPECTED_RA8 = {'RA8-EPOCH', 'RA8-CONT', 'RA8-CORR', 'RA8-K', 'RA8-SIDE', 'RA8-MARK', 'RA8-FROST'}
EXPECTED_REQ_IDS = EXPECTED_DFT | EXPECTED_RA8
EXPECTED_T8 = {'T8-' + x for x in ('XREF WP CAP OWN PUBPRIV COGLIFE CLARIFY RASTATUS SYM REQ '
                                   'EPOCH CONT CORR K SIDE MARK FROST').split()}
EXPECTED_WPS = {'WP-%02d' % i for i in range(0, 15)}
EXPECTED_SUBSYS = {'S%02d' % i for i in range(1, 27)}
EXPECTED_RA_DELTAS = {   # delta -> (seat_type, owner_subsystem, requirement, test)
    'RA-EPOCH':  ('CanonicalCitationURI/1', 'S25', 'RA8-EPOCH', 'T8-EPOCH'),
    'RA-CONT':   ('ContinuityPolicy/1', 'S11', 'RA8-CONT', 'T8-CONT'),
    'RA-CORR':   ('PublicCorrectionEvent/1', 'S18', 'RA8-CORR', 'T8-CORR'),
    'RA-JUR-NS': ('JurisdictionNamespace/1', 'S25', 'RA8-JURNS', 'T8-JURNS'),
    'RA-MARK':   ('LawmaxStatusVsMark/1', 'S25', 'RA8-MARK', 'T8-MARK'),
    'RA-K':      ('CitationMetricV8/1', 'S15', 'RA8-K', 'T8-K'),
    'RA-SIDE':   ('SidecarSourceProfile/1', 'S26', 'RA8-SIDE', 'T8-SIDE'),
}
DIMSTATE_REQUIRED = {'OK', 'DEGRADED', 'FAILED', 'UNKNOWN'}
CLASS_ENUM = {'MANDATORY', 'ADVISORY'}
PRIM = {'ref', 'id', 'sha256', 'sig', 'instant', 'scope', 'semver', 'text', 'keyword', 'pubkey',
        'kid', 'anchor', 'usc-id', 'duration', 'uncertainty', 'null', 'span', 'mime', 'url', 'bool'}

# ============================ GUARDS ============================
def g_pubpriv(F):
    priv = private_types(F); defined = defined_types(F)
    roots = public_interfaces(F, priv); adj = record_field_edges(F)
    recnames = set(adj)
    v = 0; why = []
    seen = set(); stack = [r for r in roots if r in recnames]
    while stack:
        x = stack.pop()
        if x in seen:
            continue
        seen.add(x)
        if x in priv:
            v += 1; why.append('field-closure-leak:' + x); continue
        stack += adj.get(x, [])
    for f in forms_by_head(top_forms(F['schema']), 'define-canonical-identity'):
        loc = kv_after(f, ':type-locator')
        if isinstance(loc, Str):
            for tk in type_tokens(str(loc)):
                if tk in priv:
                    v += 1; why.append('ref-target-leak->' + tk)
    for name, f in roots.items():
        for tk in type_refs(f):
            if tk in priv:
                v += 1; why.append('interface-io-leak:' + name + '->' + tk)
    for f in forms_by_head(top_forms(F['sub']), 'define-subsystem'):
        owner = kv_after(f, ':owner'); itf = kv_after(f, ':interface')
        ow = str(owner) if owner is not None else ''
        if 'DEFERRED_PRIVATE' in ow or 'INTERFACE_ONLY' in ow:
            continue
        if isinstance(itf, Str):
            for tk in type_tokens(str(itf)):
                if tk in priv:
                    v += 1; why.append('subsystem-dep-leak->' + tk)
    for f in forms_by_head(top_forms(F['schema']), 'define-write-authority'):
        owner = str(kv_after(f, ':owner') or ''); auth = str(kv_after(f, ':write-authority') or '')
        wv = kv_after(f, ':writers'); ro = kv_after(f, ':read-only')
        try:
            wn = int(str(wv))
        except Exception:
            wn = 0
        if any(p in owner or p in auth for p in priv):
            v += 1; why.append('store-owner-leak')
        if ro is not None and str(ro) == 't' and wn != 0:
            v += 1; why.append('store-readonly-writer')
    # api-mcp-schema + publication: the consumed source must EXIST and carry its expected anchor (erasing it fails),
    # and must not name any private type.
    if 'define-mcp-tool' not in F['mcp'] and 'mcp' not in F['mcp'].lower():
        v += 1; why.append('mcp-source-erased')
    if 'emit-corpus-site' not in F['site']:
        v += 1; why.append('site-source-erased')
    for keyf, tag in (('mcp', 'mcp'), ('site', 'site')):
        for tk in type_tokens(F[keyf]):
            if tk in priv:
                v += 1; why.append(tag + '-leak->' + tk)
    for f in all_record_forms(F):
        nm = form_name(f)
        if nm is None or str(nm) in priv or 'DeclassificationReceipt' in str(nm):
            continue
        for tk in adj.get(str(nm), []):
            if tk in priv:
                v += 1; why.append('declass-leak:' + str(nm) + '->' + tk)
    for nm, refs in adj.items():
        for tk in refs:
            if tk not in defined and tk.split('/')[0].lower() not in PRIM:
                v += 1; why.append('undefined-endpoint:' + nm + '->' + tk)
    return v, ('clean:%d roots,%d private' % (len(roots), len(priv))) if v == 0 else '; '.join(why[:6])

def g_xref(F):
    forms = top_forms(F['schema'])
    ci = forms_by_head(forms, 'define-canonical-identity')
    v = 0; why = []; verified = 0
    # exact set of canonical identities (no missing / extra / duplicate)
    names = [str(form_name(f)) for f in ci if form_name(f) is not None]
    if len(names) != len(set(names)):
        v += 1; why.append('duplicate-canonical-identity')
    if set(names) != set(EXPECTED_CANON):
        v += 1; why.append('canon-set!=expected:' + ','.join(sorted(set(names) ^ set(EXPECTED_CANON)))[:60])
    for f in ci:
        nm = str(form_name(f) or '?')
        status = kv_after(f, ':status')
        if status is None or str(status) != 'VERIFIED':
            v += 1; why.append('unresolved:' + nm); continue
        vf = kv_after(f, ':verify-file'); loc = kv_after(f, ':type-locator')
        idn = kv_after(f, ':identity'); ver = kv_after(f, ':version')
        if not (isinstance(vf, Str) and isinstance(loc, Str) and isinstance(idn, Str) and isinstance(ver, Str)):
            v += 1; why.append('incomplete:' + nm); continue
        vftxt = open_or_loaded(str(vf), F)
        if vftxt is None:
            v += 1; why.append('verify-file-missing:' + nm); continue
        refname = str(loc).replace('define-reference', '').strip()
        block = None
        for rf in forms_by_head(top_forms(vftxt), 'define-reference'):
            if form_name(rf) is not None and str(form_name(rf)) == refname:
                block = rf; break
        if block is None:
            v += 1; why.append('reference-target-absent:' + nm); continue
        bidn = kv_after(block, ':identity'); bver = kv_after(block, ':version')
        if not (isinstance(bidn, Str) and str(bidn) == str(idn) and isinstance(bver, Str) and str(bver) == str(ver)):
            v += 1; why.append('identity/version-mismatch:' + nm); continue
        cf = kv_after(block, ':canonical-file'); lc = kv_after(block, ':locator')
        if not (isinstance(cf, Str) and isinstance(lc, Str)):
            v += 1; why.append('no-canonical-anchor:' + nm); continue
        # the resolved (identity, canonical-file, locator) must be EXACTLY the pinned contract for this type
        if nm in EXPECTED_CANON:
            ecf, eidn, eloc = EXPECTED_CANON[nm]
            if str(idn) != eidn or str(cf) != ecf or str(lc) != eloc:
                v += 1; why.append('wrong-contract:' + nm); continue
        cftxt = open_or_loaded(str(cf), F)
        if cftxt is None:
            v += 1; why.append('canonical-file-missing:' + nm); continue
        locator = str(lc); cfl = str(cf).lower()
        if cfl.endswith('.lisp') or cfl.endswith('.sexp'):
            if locator not in top_symbols(cftxt):
                v += 1; why.append('locator-not-top-symbol:' + nm + ':' + locator); continue
        else:
            if not re.search(r'(?<![\w/-])' + re.escape(locator) + r'(?![\w/-])', cftxt):
                v += 1; why.append('locator-not-a-term:' + nm + ':' + locator); continue
        verified += 1
    return v, ('clean:%d verified, 0 unresolved' % verified) if v == 0 else '; '.join(why[:6])

TOPFORMS = r'\(def(?:un|method|generic|class|struct|parameter|var|macro)\s+'
def g_cap(F):
    v = 0; why = []
    entries = forms_by_head(top_forms(F['schema']), 'define-capability-seat')
    got = {}
    for e in entries:
        cap = kv_after(e, ':capability')
        if cap is not None:
            got[str(cap)] = e
    if len(got) != len(entries):
        v += 1; why.append('duplicate-capability')
    if set(got) != set(EXPECTED_CAP):
        v += 1; why.append('cap-set!=expected:' + ','.join(sorted(set(got) ^ set(EXPECTED_CAP)))[:50])
    for cap, exp in EXPECTED_CAP.items():
        e = got.get(cap)
        if e is None:
            v += 1; why.append('cap-missing:' + cap); continue
        ekind, efile, epkg, esym, esub, ereq, etest = exp
        kind = str(kv_after(e, ':kind') or '')
        f = kv_after(e, ':file'); sub = kv_after(e, ':subsystem'); req = kv_after(e, ':requirement'); test = kv_after(e, ':test')
        if kind != ':' + ekind or not isinstance(f, Str) or str(f) != efile \
                or str(sub or '') != esub or str(req or '') != ereq or str(test or '') != etest:
            v += 1; why.append('cap-decl-mismatch:' + cap); continue
        txt = openroot(efile)
        if txt is None:
            v += 1; why.append('cap-file-missing:' + cap); continue
        if ekind == 'CODE':
            pkg = str(kv_after(e, ':package') or ''); sym = str(kv_after(e, ':symbol') or '')
            if pkg != epkg or sym != esym:
                v += 1; why.append('cap-code-decl:' + cap); continue
            if (('defpackage :' + epkg) not in txt and ('defpackage #:' + epkg) not in txt and ('defpackage ' + epkg) not in txt):
                v += 1; why.append('cap-pkg-absent:' + cap)
            if not re.search(TOPFORMS + re.escape(esym) + r'\b', txt):
                v += 1; why.append('cap-sym-not-topform:' + cap)
            ip = txt.find('(in-package :' + epkg); dp = re.search(TOPFORMS + re.escape(esym) + r'\b', txt)
            if not (ip >= 0 and dp and dp.start() > ip):
                v += 1; why.append('cap-pkg-ownership:' + cap)
        else:
            sec = kv_after(e, ':section')
            if not isinstance(sec, Str) or str(sec) != esym or txt.count(esym) < 1:
                v += 1; why.append('cap-doc-section:' + cap)
            if kv_after(e, ':package') is not None:
                v += 1; why.append('cap-doc-has-package:' + cap)
    return v, ('clean:%d seats' % len(entries)) if v == 0 else '; '.join(why[:6])

def _repo_source_files():
    try:
        return set(os.listdir(os.path.join(ROOT, 'source')))
    except Exception:
        return set()
def _wp_ids(F):
    return set(str(form_name(f)) for f in forms_by_head(top_forms(F['sub']), 'define-wp-purpose') if form_name(f))
def _subsystem_ids(F):
    return set(str(form_name(f)) for f in forms_by_head(top_forms(F['sub']), 'define-subsystem') if form_name(f))

def _resolve_authority(s, srcfiles, wps, subs, require_anchor):
    design_target = '[design-target]' in s
    anchor = False
    for t in s.replace('[', ' [').replace(']', '] ').split():
        tt = t.strip('[]')
        if not tt or tt in ('design-target', 'interface-only'):
            continue
        if tt.endswith('.lisp'):
            if tt in srcfiles:
                anchor = True
            elif design_target:
                anchor = True
            else:
                return False, 'ghost-file:' + tt
        elif tt.startswith('WP-') and tt[3:].isdigit():
            if tt in wps:
                anchor = True
            else:
                return False, 'ghost-wp:' + tt
        elif (tt.startswith('S') and tt[1:].isdigit()) or (tt.startswith('RA-S') and tt[4:].isdigit()):
            sid = tt[3:] if tt.startswith('RA-') else tt
            if sid in subs:
                anchor = True
            else:
                return False, 'ghost-subsystem:' + tt
    if require_anchor and not anchor:
        return False, 'no-concrete-anchor'
    return True, 'ok'

def g_own(F):
    v = 0; why = []
    wa = forms_by_head(top_forms(F['schema']), 'define-write-authority')
    srcfiles = _repo_source_files(); wps = _wp_ids(F); subs = _subsystem_ids(F)
    stores = {}
    for f in wa:
        st = str(kv_after(f, ':store') or '')
        stores.setdefault(st, []).append(f)
    # exact store set + no duplicate store
    for st, lst in stores.items():
        if len(lst) > 1:
            v += 1; why.append('dup-store:' + st)
    if set(stores) != set(EXPECTED_STORES):
        v += 1; why.append('store-set!=expected:' + ','.join(sorted(set(stores) ^ set(EXPECTED_STORES)))[:50])
    for f in wa:
        store = str(kv_after(f, ':store') or ''); owner = str(kv_after(f, ':owner') or '')
        auth = str(kv_after(f, ':write-authority') or '')
        wraw = kv_after(f, ':writers'); ro = kv_after(f, ':read-only')
        try:
            wn = int(str(wraw))
        except Exception:
            wn = 0
        if not owner:
            v += 1; why.append('no-owner:' + store)
        if wn > 1:
            v += 1; why.append('two-writers:' + store)
        if ro is not None and str(ro) == 't' and wn != 0:
            v += 1; why.append('ro-writer:' + store)
        ok, r = _resolve_authority(owner, srcfiles, wps, subs, require_anchor=True)
        if not ok:
            v += 1; why.append('owner-unresolved:' + store + '/' + r)
        ok2, r2 = _resolve_authority(auth, srcfiles, wps, subs, require_anchor=False)
        if not ok2:
            v += 1; why.append('writer-unresolved:' + store + '/' + r2)
        # full relation: store -> its pinned owner + write-authority (a real-but-unrelated WP/file/writer fails)
        if store in EXPECTED_STORES:
            eo, ea = EXPECTED_STORES[store]
            if owner != eo:
                v += 1; why.append('owner-relation-mismatch:' + store)
            if auth != ea:
                v += 1; why.append('writer-relation-mismatch:' + store)
    return v, ('clean:%d stores' % len(wa)) if v == 0 else '; '.join(why[:6])

def cog_model(F):
    forms = top_forms(F['schema'])
    graphs = forms_by_head(forms, 'define-cognition-graph')
    nts = forms_by_head(forms, 'define-cognition-node-types')
    g = graphs[0] if graphs else None
    nt = nts[0] if nts else None
    nodes = set(sym_list(kv_after(g, ':nodes'))) if g is not None else set()
    flow = edge_pairs(kv_after(g, ':flow-edges')) if g is not None else []
    branch = edge_pairs(kv_after(g, ':branch-edges')) if g is not None else []
    resume = edge_pairs(kv_after(g, ':resume-edges')) if g is not None else []
    term = edge_pairs(kv_after(g, ':terminal-edges')) if g is not None else []
    terminals = set(sym_list(kv_after(g, ':terminals'))) if g is not None else set()
    entry = str(kv_after(g, ':entry')) if (g is not None and kv_after(g, ':entry') is not None) else None
    nodetypes = {}
    if nt is not None:
        for spec in nt[2:]:
            if is_list(spec) and len(spec) >= 6 and isinstance(spec[1], Sym):
                nodetypes[str(spec[1])] = (str(kv_after(spec, ':in')), str(kv_after(spec, ':out')))
    resp = None
    for f in forms_by_head(forms, 'define-record'):
        if form_name(f) is not None and str(form_name(f)) == 'ClarificationResponse/1':
            resp = f; break
    return len(graphs), len(nts), nodes, nodetypes, flow, branch, resume, term, terminals, entry, resp

def field_by_key(record_form, key):
    _, fields = record_attrs_fields(record_form)
    for fld in fields:
        if field_key(fld) == key:
            return fld
    return None

def g_coglife(F):
    ng, nnt, nodes, nodetypes, flow, branch, resume, term, terminals, entry, resp = cog_model(F)
    v = 0; why = []
    fam = {'flow': flow, 'branch': branch, 'resume': resume, 'terminal': term}
    if ng != 1:
        v += 1; why.append('cognition-graphs!=1:%d' % ng)
    if nnt != 1:
        v += 1; why.append('node-type-defs!=1:%d' % nnt)
    if nodes != set(nodetypes):
        v += 1; why.append('nodes!=node-types')
    for fname, edges in fam.items():
        for a, b in edges:
            if a not in nodes:
                v += 1; why.append('undeclared-endpoint:%s:%s' % (fname, a))
            if b not in nodes:
                v += 1; why.append('undeclared-endpoint:%s:%s' % (fname, b))
    # type compatibility over flow + branch + terminal + resume (every family)
    def tc(edges, fname):
        nonlocal v
        for a, b in edges:
            if a in nodetypes and b in nodetypes:
                out_a = nodetypes[a][1]; in_b = nodetypes[b][0]
                if b in terminals:
                    if in_b != out_a:
                        v += 1; why.append('typed-incompat-terminal:%s->%s' % (a, b))
                elif fname == 'resume':
                    # resume edges bind by transition rule, not plain type-eq, EXCEPT SUSPEND->RESUME which must
                    # carry the request/response binding; RESUME->RESOLVE must be plain type-compatible.
                    if (a, b) == ('CLARIFY-RESUME', 'RESOLVE') and in_b != out_a:
                        v += 1; why.append('typed-incompat-resume:%s->%s' % (a, b))
                else:
                    if in_b != out_a:
                        v += 1; why.append('typed-incompat:%s->%s' % (a, b))
    tc(flow, 'flow'); tc(branch, 'branch'); tc(term, 'terminal'); tc(resume, 'resume')
    # terminals: zero outgoing edges in EVERY family
    for fname, edges in fam.items():
        for a, b in edges:
            if a in terminals and a != 'RESULT':
                v += 1; why.append('terminal-outgoing:%s:%s' % (fname, a))
    incoming = set(b for e in fam.values() for a, b in e)
    for t in terminals:
        if t != 'RESULT' and t not in incoming:
            v += 1; why.append('orphan-terminal:' + t)
    # every declared node reachable from entry (via flow+branch+resume), else terminal — no disconnected node
    reach_edges = flow + branch + resume
    adjm = {}
    for a, b in reach_edges:
        adjm.setdefault(a, []).append(b)
    seen = set(); st = [entry] if entry else []
    while st:
        u = st.pop()
        if u in seen:
            continue
        seen.add(u); st += adjm.get(u, [])
    for nd in nodes:
        if nd not in seen and nd not in terminals:
            v += 1; why.append('disconnected-node:' + nd)
    def has_cycle(edges):
        aa = {}
        for a, b in edges:
            aa.setdefault(a, []).append(b)
        col = {}
        def dfs(u):
            col[u] = 1
            for w in aa.get(u, []):
                if col.get(w, 0) == 1:
                    return True
                if col.get(w, 0) == 0 and dfs(w):
                    return True
            col[u] = 2; return False
        return any(col.get(u, 0) == 0 and dfs(u) for u in list(aa))
    if has_cycle(flow + branch + term):
        v += 1; why.append('illegal-cycle')
    allowed_resume = {('CLARIFY-SUSPEND', 'CLARIFY-RESUME'), ('CLARIFY-RESUME', 'RESOLVE')}
    for e in resume:
        if e not in allowed_resume:
            v += 1; why.append('illegal-resume-transition:%s->%s' % e)
    for req in sorted(allowed_resume):
        if req not in set(resume):
            v += 1; why.append('missing-resume-edge:%s->%s' % req)
    # suspend/request/response/resume binding
    susp_out = nodetypes.get('CLARIFY-SUSPEND', ('', ''))[1]
    resume_in = nodetypes.get('CLARIFY-RESUME', ('', ''))[0]
    if susp_out != 'ClarificationRequest/1':
        v += 1; why.append('suspend-not-request')
    if resume_in != 'ClarificationResponse/1':
        v += 1; why.append('resume-not-response')
    if resp is None or field_by_key(resp, ':resume_binding_ref') is None:
        v += 1; why.append('resume-binding-missing')
    return v, ('clean:%d nodes,%d edges' % (len(nodes), sum(len(e) for e in fam.values()))) if v == 0 else '; '.join(why[:6])

def g_clarify(F):
    forms = top_forms(F['schema'])
    tbls = forms_by_head(forms, 'define-cardinality-table')
    fxs = forms_by_head(forms, 'define-fixtures')
    v = 0; why = []
    if len(tbls) != 1:
        v += 1; why.append('cardinality-tables!=1:%d' % len(tbls))
    if len(fxs) != 1:
        v += 1; why.append('fixture-defs!=1:%d' % len(fxs))
    if v:
        return v, '; '.join(why[:6])
    # parse the ACTUAL declared cardinality table (never a parallel hard-coded rule)
    rules = {}
    for spec in tbls[0][2:]:
        if is_list(spec) and spec and isinstance(spec[0], Sym) and str(spec[0]) == ':when':
            ms = str(spec[1])[1:] if isinstance(spec[1], Sym) else ''
            rules[ms] = (str(kv_after(spec, ':selected')), str(kv_after(spec, ':merged')), str(kv_after(spec, ':input-provenance')))
    if set(rules) != {'ABSTAIN', 'EXPLICIT_SELECTION', 'EXPLICIT_MERGE'}:
        v += 1; why.append('cardinality-modes!=3'); return v, '; '.join(why[:6])
    def table_ok(ms, sel, mrg, prov):
        r = rules.get(ms)
        if r is None:
            return False
        esel, emrg, eprov = r
        sel_ok = (sel == 0) if esel == 'null' else (sel == 1) if esel == 'one' else True
        mrg_ok = (mrg == 0) if emrg == 'null' else (mrg == 1) if emrg == 'one' else True
        prov_ok = prov if eprov == 'all-preserved' else True
        return sel_ok and mrg_ok and prov_ok
    fixtures = []
    for spec in fxs[0][2:]:
        if is_list(spec) and len(spec) >= 2 and isinstance(spec[0], Sym) and str(spec[0]) in (':valid', ':invalid'):
            fixtures.append((str(spec[0]), str(spec[1]), str(kv_after(spec, ':selected')),
                             str(kv_after(spec, ':merged')), str(kv_after(spec, ':provenance-preserved'))))
    if len(fixtures) < 7:
        v += 1; why.append('too-few-fixtures:%d' % len(fixtures))
    for kind, ms, sel, mrg, prov in fixtures:
        ok = table_ok(ms, int(sel), int(mrg), prov == 't')
        if kind == ':valid' and not ok:
            v += 1; why.append('valid-fails-table:' + ms)
        if kind == ':invalid' and ok:
            v += 1; why.append('invalid-passes-table:' + ms)
    return v, ('clean:%d fixtures via table' % len(fixtures)) if v == 0 else '; '.join(why[:6])

def enum_members(F, name):
    for f in forms_by_head(top_forms(F['schema']), 'define-closed-enum'):
        if form_name(f) is not None and str(form_name(f)) == name:
            return [str(x[0])[1:] for x in f[2:] if is_list(x) and x and isinstance(x[0], Sym)]
    return []

def ra_model(F):
    states = enum_members(F, 'DimensionState')
    reliance = set(enum_members(F, 'RelianceClass'))
    dp = None
    for f in forms_by_head(top_forms(F['schema']), 'define-dimension-policy'):
        dp = f; break
    dims = []
    if dp is not None:
        for spec in dp[2:]:
            if is_list(spec):
                dn = kv_after(spec, ':dimension'); cl = kv_after(spec, ':class'); fl = kv_after(spec, ':failure')
                if dn is not None and cl is not None and fl is not None:
                    dims.append((str(dn)[1:], str(cl)[1:], str(fl)[1:]))
    return states, reliance, dims

def g_rastatus(F):
    states, reliance, dims = ra_model(F)
    forms = top_forms(F['schema'])
    ras = relp = None
    for f in forms_by_head(forms, 'define-record'):
        if str(form_name(f) or '') == 'RootAuthorityStatus/1':
            ras = f
        if str(form_name(f) or '') == 'RelianceProjection/1':
            relp = f
    v = 0; why = []
    names = [d[0] for d in dims]
    # schema binding + exact dimension set + pinned class/failure policy
    if ras is None:
        v += 1; why.append('RootAuthorityStatus-missing'); return v, '; '.join(why[:6])
    ras_attrs, ras_fields = record_attrs_fields(ras)
    ras_dim_fields = [field_key(fl)[1:] for fl in ras_fields if str(field_type_expr(fl)) == 'DimensionState']
    if set(ras_dim_fields) != set(EXPECTED_DIMS):
        v += 1; why.append('record-dim-fields!=8-named')
    if len(ras_dim_fields) != len(set(ras_dim_fields)):
        v += 1; why.append('duplicate-record-dim-field')
    cr = field_by_key(ras, ':cause_refs')
    if cr is None:
        v += 1; why.append('cause_refs-missing')
    else:
        te = field_type_expr(cr)
        if not (is_list(te) and len(te) >= 2 and str(te[0]) == 'list' and str(te[1]) == 'ref'):
            v += 1; why.append('cause_refs-bad-cardinality')
    for fld_name, want in ((':blocking_dimensions', True), (':advisory_dimensions', True)):
        fb = field_by_key(relp, fld_name) if relp is not None else None
        if fb is None:
            v += 1; why.append(fld_name[1:] + '-missing')
        else:
            te = field_type_expr(fb)
            if not (is_list(te) and len(te) >= 2 and str(te[0]) == 'list' and str(te[1]) == 'ref'):
                v += 1; why.append(fld_name[1:] + '-bad-cardinality')
    if set(states) != DIMSTATE_REQUIRED:
        v += 1; why.append('dimstate!=OK/DEGRADED/FAILED/UNKNOWN')
    dim_names = [d[0] for d in dims]
    if len(dim_names) != len(set(dim_names)):
        v += 1; why.append('duplicate-dimension')
    if set(dim_names) != set(EXPECTED_DIMS):
        v += 1; why.append('dim-set!=expected')
    if len(states) != len(set(states)):
        v += 1; why.append('duplicate-dimstate-enum-member')
    if len(reliance) != len(enum_members(F, 'RelianceClass')):
        v += 1; why.append('duplicate-reliance-enum-member')
    for dn, cl, fl in dims:
        if cl not in CLASS_ENUM:
            v += 1; why.append('bad-class:%s' % dn)
        if fl not in reliance:
            v += 1; why.append('bad-failure-class:%s:%s' % (dn, fl))
        # pinned classification + failure policy — weakening MANDATORY->ADVISORY (or a changed failure) FAILS
        if dn in EXPECTED_DIMS and (cl, fl) != EXPECTED_DIMS[dn]:
            v += 1; why.append('policy-weakened:%s' % dn)
    # parse + honor the declared reliance-aggregation contract (not a substituted hard-coded rule)
    agg = None
    for f in forms_by_head(forms, 'define-reliance-aggregation'):
        agg = f; break
    if agg is None:
        v += 1; why.append('aggregation-contract-missing'); return v, '; '.join(why[:6])
    order = [str(x) for x in kv_after(agg, ':order')] if is_list(kv_after(agg, ':order')) else []
    if order != ['WITHHELD', 'MACHINE_UNVERIFIED', 'ATTRIBUTED_RELIANCE', 'FULL_RELIANCE']:
        v += 1; why.append('aggregation-order-changed')
    rule = str(kv_after(agg, ':rule') or '')
    for tok in ('min', 'MANDATORY', 'FAILED DEGRADED UNKNOWN', 'FULL_RELIANCE'):
        if tok not in rule:
            v += 1; why.append('aggregation-rule-weakened'); break
    if str(kv_after(agg, ':advisory-never-blocks') or '') != 't':
        v += 1; why.append('advisory-can-block')
    if str(kv_after(agg, ':self-qualification') or '') != ':rejected':
        v += 1; why.append('self-qualification-not-rejected')
    if ':derived :type (member :true)' not in F['schema']:
        v += 1; why.append('derived-not-constant')
    if not (field_by_key(ras, ':proof_integrity') is not None and field_by_key(ras, ':security') is not None):
        v += 1; why.append('proof_integrity-not-separate')
    if v:
        return v, '; '.join(why[:6])
    # execute the aggregation over the FULL 4^8 product using the parsed order
    BAD = {'FAILED', 'DEGRADED', 'UNKNOWN'}
    def project(stt):
        worst = 'FULL_RELIANCE'; blocking = []; advisory = []
        for dn, cl, fl in dims:
            if stt[dn] in BAD:
                if cl == 'MANDATORY':
                    blocking.append(dn)
                    if order.index(fl) < order.index(worst):
                        worst = fl
                else:
                    advisory.append(dn)
        return worst, tuple(sorted(blocking)), tuple(sorted(advisory))
    total = len(states) ** len(names); seen = 0; exercised = set()
    for combo in itertools.product(states, repeat=len(names)):
        stt = dict(zip(names, combo)); p = project(stt); seen += 1; exercised.update(combo)
        eb = tuple(sorted(d for d, c, fl in dims if c == 'MANDATORY' and stt[d] in BAD))
        ea = tuple(sorted(d for d, c, fl in dims if c == 'ADVISORY' and stt[d] in BAD))
        if p[1] != eb:
            v += 1; why.append('blocking-incomplete'); break
        if p[2] != ea:
            v += 1; why.append('advisory-incomplete'); break
    if seen != total:
        v += 1; why.append('coverage:%d!=%d' % (seen, total))
    if not DIMSTATE_REQUIRED.issubset(exercised):
        v += 1; why.append('UNKNOWN/DEGRADED-not-exercised')
    mand = [d for d, c, fl in dims if c == 'MANDATORY']
    for a in mand:
        for b in mand:
            if a == b:
                continue
            stt = {d: ('FAILED' if d in (a, b) else 'OK') for d in names}
            st2 = dict(stt); st2[a] = 'OK'
            if b not in project(st2)[1]:
                v += 1; why.append('recovery-not-independent:%s/%s' % (a, b)); break
        if any('recovery-not-independent' in w for w in why):
            break
    return v, ('clean:%d states, 8 dims' % total) if v == 0 else '; '.join(why[:6])

def g_sym(F):
    forms = top_forms(F['schema'])
    pips = forms_by_head(forms, 'define-pipeline')
    if len(pips) != 1:
        return 1, 'pipelines!=1:%d' % len(pips)
    pip = pips[0]
    def g(key):
        return sym_list(kv_after(pip, key))
    nodesu = g(':nodes'); mand = g(':mandatory-nodes'); propmand = [x for x in g(':proposer-mandatory-nodes') if x]
    symbolic = set(g(':symbolic-only-nodes')); muts = g(':mutations')
    edges = edge_pairs(kv_after(pip, ':edges'))
    entry = str(kv_after(pip, ':entry') or ''); exit_ = str(kv_after(pip, ':exit') or '')
    mc = kv_after(pip, ':mutation-count')
    try:
        mcount = int(str(mc))
    except Exception:
        mcount = -1
    def reach(a, b, eds):
        aa = {}
        for x, y in eds:
            aa.setdefault(x, []).append(y)
        seen = set(); st = [a]
        while st:
            u = st.pop()
            if u in seen:
                continue
            seen.add(u); st += aa.get(u, [])
        return b in seen
    v = 0; why = []
    EXP_NODES = {'ACQUIRE', 'CENSUS', 'ADMIT', 'IR', 'REASON', 'COMPILE', 'PROOF', 'PUBLISH'}
    EXP_MAND = {'ACQUIRE', 'CENSUS', 'IR', 'COMPILE', 'PROOF', 'PUBLISH'}
    if set(nodesu) != EXP_NODES:
        v += 1; why.append('node-universe!=expected')
    if set(mand) != EXP_MAND:
        v += 1; why.append('mandatory-set!=expected')
    if len(muts) != 4 or mcount != 4:
        v += 1; why.append('declared-mutations!=4')
    if entry != 'ACQUIRE' or exit_ != 'PUBLISH':
        v += 1; why.append('entry/exit-changed')
    for mn in mand:
        if not reach(entry, mn, edges):
            v += 1; why.append('mandatory-unreachable:' + mn)
    if entry and exit_ and not reach(entry, exit_, edges):
        v += 1; why.append('exit-unreachable')
    if len(propmand) != 0:
        v += 1; why.append('proposer-mandatory-nonempty')
    # derive proposer removal: symbolic-only subgraph must still connect every mandatory node
    sym_edges = [(a, b) for a, b in edges if a in symbolic and b in symbolic]
    for mn in mand:
        if mn != entry and not reach(entry, mn, sym_edges):
            v += 1; why.append('mandatory-not-symbolic-reachable:' + mn)
    return v, ('clean:%d mand,%d edges' % (len(mand), len(edges))) if v == 0 else '; '.join(why[:6])

def g_wp(F):
    """DFT-02: open each named WP-NN.md and confirm its :evidence string occurs in it; a FUTURE-marked concept
    stays file 'none' and must NOT be mapped to a real WP file."""
    forms = top_forms(F['schema'])
    wprec = None
    for f in forms_by_head(forms, 'define-wp-reconciliation'):
        wprec = f; break
    v = 0; why = []
    if wprec is None:
        return 1, 'wp-reconciliation-missing'
    wpdir = os.path.join(ROOT, 'deployment', 'collab', 'design', 'OMEGA2', 'CHANGE-PROPOSAL',
                         'IMPLEMENTATION-BOOK', 'WORK-PACKETS')
    for spec in wprec[1:]:
        if not is_list(spec):
            continue
        concept = kv_after(spec, ':concept'); wp = kv_after(spec, ':wp')
        fnm = kv_after(spec, ':file'); ev = kv_after(spec, ':evidence')
        if concept is None:
            continue
        wps = str(wp or ''); fns = str(fnm or ''); evs = str(ev or '')
        if wps.startswith('WP-') and wps[3:].isdigit():
            if fns == 'none' or not fns.endswith('.md'):
                v += 1; why.append('wp-file-decl:' + str(concept)); continue
            fp = os.path.join(wpdir, fns)
            if not os.path.isfile(fp):
                v += 1; why.append('wp-file-missing:' + fns); continue
            if evs and evs not in readpath(fp):
                v += 1; why.append('evidence-absent:' + fns); continue
        else:
            # FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED -> must stay file 'none' (never a real WP)
            if fns != 'none':
                v += 1; why.append('future-mapped-to-file:' + str(concept))
    return v, 'clean:wp-reconciliation opens WP files' if v == 0 else '; '.join(why[:6])

def g_req(F):
    trc = F['trc']; s = F['schema']; s17 = F['s17']; s16 = F['s16']
    drec = set(str(form_name(f)) for f in all_record_forms({'schema': s, 's17': s17, 's16': s16}) if form_name(f))
    dref = set(str(form_name(f)) for f in all_reference_forms({'schema': s, 's17': s17, 's16': s16}) if form_name(f))
    isrif = set(str(form_name(f)) for f in isr_interface_forms(F) if form_name(f))
    deftypes = drec | dref | isrif
    schema_forms_names = set()
    for f in top_forms(s):
        if head(f) is not None:
            schema_forms_names.add((str(head(f)), str(form_name(f)) if form_name(f) else ''))
    def ref_resolves(tok):
        tok = tok.strip()
        if tok.endswith('/1'):
            return tok in deftypes
        if tok.startswith('define-'):
            return any(h == tok for h, nm in schema_forms_names)
        return any(nm == tok for h, nm in schema_forms_names)
    wpdir = os.path.join(ROOT, 'deployment', 'collab', 'design', 'OMEGA2', 'CHANGE-PROPOSAL',
                         'IMPLEMENTATION-BOOK', 'WORK-PACKETS')
    v18 = trc.split('§v1.8', 1)[1] if '§v1.8' in trc else ''
    hdr = re.search(r'\|\s*id\s*\|(.+?)\|\s*\n', v18)
    cols = [h.strip().lower() for h in (hdr.group(1).split('|') if hdr else [])]
    def colidx(name):
        for i, c in enumerate(cols):
            if name in c:
                return i
        return -1
    idx = {k: colidx(k) for k in ('owner seat', 'test', 'requirement', 'future wp', 'interface')}
    rows = re.findall(r'\|\s*(RA8-[A-Z0-9-]+|DFT-\d+)\s*\|([^\n]*)', v18)
    v = 0; why = []
    if any(i < 0 for i in idx.values()):
        v += 1; why.append('missing-column')
    ids = [rid for rid, _ in rows]; idset = set(ids)
    if idset != EXPECTED_REQ_IDS:
        v += 1; why.append('id-set!=expected:' + ','.join(sorted(idset ^ EXPECTED_REQ_IDS))[:50])
    if len(ids) != len(idset):
        v += 1; why.append('duplicate-req-id')
    for rid, rest in rows:
        cells = [c.strip() for c in rest.split('|')]
        for k, ix in idx.items():
            if ix < 0 or ix >= len(cells) or not cells[ix].strip():
                v += 1; why.append('blank:%s@%s' % (k, rid))
        ii = idx['interface']
        ifc = cells[ii] if (0 <= ii < len(cells)) else ''
        for tok in re.findall(r'`([^`]+)`', ifc):
            if not ref_resolves(tok):
                v += 1; why.append('unresolved-if:%s@%s' % (tok, rid))
        # test id must be in the declared T8 universe
        ti = idx['test']
        tcell = cells[ti].strip() if (0 <= ti < len(cells)) else ''
        for tk in re.findall(r'T8-[A-Z0-9]+', tcell):
            if tk not in EXPECTED_T8:
                v += 1; why.append('ghost-test:%s@%s' % (tk, rid))
        # every WP-NN token in the future-wp column must have a real WP-NN.md file
        wi = idx['future wp']
        wcell = cells[wi] if (0 <= wi < len(cells)) else ''
        for wk in re.findall(r'WP-\d+', wcell):
            if wk not in EXPECTED_WPS or not os.path.isfile(os.path.join(wpdir, wk + '.md')):
                v += 1; why.append('ghost-wp:%s@%s' % (wk, rid))
    return v, ('clean:%d rows' % len(rows)) if v == 0 else '; '.join(why[:6])

def g_radeltas(F):
    forms = top_forms(F['schema'])
    dsf = None
    for f in forms_by_head(forms, 'define-ra-delta-seats'):
        dsf = f; break
    deltas = []
    if dsf is not None:
        for spec in dsf[1:]:
            if is_list(spec) and spec and isinstance(spec[0], Sym) and str(spec[0]) == ':delta':
                dl = str(spec[1]) if len(spec) > 1 else ''
                deltas.append((dl, kv_after(spec, ':seat'), kv_after(spec, ':owner'),
                               kv_after(spec, ':requirement'), kv_after(spec, ':test')))
    defined = defined_types(F); subs = _subsystem_ids(F)
    got = {d[0] for d in deltas}
    v = 0; why = []
    if got != set(EXPECTED_RA_DELTAS):
        v += 1; why.append('delta-set!=agreed:' + ','.join(sorted(got ^ set(EXPECTED_RA_DELTAS)))[:40])
    if len(deltas) != 7:
        v += 1; why.append('count!=7:%d' % len(deltas))
    seats_seen = {}
    def realval(x):
        return x is not None and not (isinstance(x, Sym) and str(x).startswith(':'))
    for dl, seat, owner, req, test in deltas:
        if not (realval(seat) and realval(owner) and realval(req) and realval(test)):
            v += 1; why.append('incomplete-delta:' + dl); continue
        seatn = str(seat); ownn = str(owner)
        seats_seen.setdefault(seatn, []).append(dl)
        if dl in EXPECTED_RA_DELTAS:
            eseat, eowner, ereq, etest = EXPECTED_RA_DELTAS[dl]
            if seatn != eseat or ownn != eowner or str(req) != ereq or str(test) != etest:
                v += 1; why.append('delta-relation-mismatch:' + dl); continue
        # referential integrity: seat is a registered/defined type, owner a real subsystem
        if seatn not in defined:
            v += 1; why.append('seat-not-registered:' + seatn)
        if ownn not in subs:
            v += 1; why.append('owner-not-a-subsystem:' + ownn)
    for seatn, dls in seats_seen.items():
        if len(dls) > 1:
            v += 1; why.append('shared-seat:' + seatn)
    return v, 'clean:7 deltas' if v == 0 else '; '.join(why[:6])

REQUIRED_SEXP = ('schema', 's17', 's16', 'isr', 'sub')
def parse_gate(F):
    """Every required s-expression source MUST parse successfully before any structural guard runs."""
    for k in REQUIRED_SEXP:
        ok, err = parse_ok(F[k])
        if not ok:
            return 'parse-fail:%s:%s' % (k, err)
    return None

def run_guard(gid, F):
    pg = parse_gate(F)
    if pg is not None:
        return 1, pg
    return GUARDS[gid](F)

GUARDS = {
    'V8-PUBPRIV': g_pubpriv, 'V8-XREF': g_xref, 'V8-CAP': g_cap, 'V8-OWN': g_own,
    'V8-COGLIFE': g_coglife, 'V8-CLARIFY': g_clarify, 'V8-RASTATUS': g_rastatus,
    'V8-SYM': g_sym, 'V8-REQ': g_req, 'V8-RA-DELTAS': g_radeltas, 'V8-WP': g_wp,
}

# ============================ MUTATIONS (real byte edits; each killed by the production guard) ============================
def R(t, a, b):
    return t.replace(a, b, 1)

MUT = {
 'V8-PUBPRIV': {
   'field-type':      ('schema', lambda t: R(t, '(define-record RootAuthorityStatus/1', '(define-record RootAuthorityStatus/1 (:leak :type TenantProfile/1)')),
   'ref-target':      ('schema', lambda t: R(t, ':type-locator "define-reference RightsMatrix/1"', ':type-locator "define-reference TenantProfile/1"')),
   'interface-io':    ('isr',    lambda t: re.sub(r'(\(define-interface\s+RootAuthorityStatus/1[^\n]*\n[^\n]*:consumers \()', r'\1TenantProfile/1 ', t, count=1)),
   'subsystem-dep':   ('sub',    lambda t: R(t, ':interface "CensusSpaceClassification/1 + census-coverage-decision"', ':interface "CensusSpaceClassification/1 + TenantProfile/1"')),
   'store-owner-writer': ('schema', lambda t: R(t, ':store "static-site"           :owner "WP-12 static-site.lisp"            :write-authority "none" :writers 0 :read-only t', ':store "static-site"           :owner "WP-12 static-site.lisp"            :write-authority "none" :writers 1 :read-only t')),
   'api-mcp-schema':  ('mcp',    lambda t: t + '\n(define-mcp-tool leak (:returns TenantProfile/1))\n'),
   'publication':     ('site',   lambda t: t + '\n(defun emit-leak () (publish TenantProfile/1))\n'),
   'declassification':('schema', lambda t: R(t, '(define-record CanonicalCitationURI/1', '(define-record CanonicalCitationURI/1 (:leak :type RestrictedForensicRecord/1)')),
   'undefined-endpoint':('schema', lambda t: R(t, '(define-record RootAuthorityStatus/1', '(define-record RootAuthorityStatus/1 (:leak :type NoSuchType/1)')),
   'held/nested-or-list-type': ('schema', lambda t: R(t, '(define-record RootAuthorityStatus/1', '(define-record RootAuthorityStatus/1 (:leak :type (or (list TenantProfile/1) null))')),
   'held/erase-mcp-source': ('mcp', lambda t: '(defpackage :nothing)\n'),
   'held/erase-site-source': ('site', lambda t: '(defpackage :nothing)\n'),
   'held/malformed-block-comment': ('schema', lambda t: t + '\n#| unterminated block comment'),
   'held/malformed-vbar': ('schema', lambda t: t + '\n(|unterminated'),
 },
 'V8-XREF': {
   'wrong-file':      ('schema', lambda t: R(t, ':verify-file "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.8-SCHEMAS.sexp" :type-locator "define-reference LegalIR/1"', ':verify-file "deployment/NO_SUCH_FILE.sexp" :type-locator "define-reference LegalIR/1"')),
   'wrong-identity':  ('schema', lambda t: R(t, ':type-locator "define-reference LegalIR/1" :identity "lawmax/legal-ir/1"', ':type-locator "define-reference LegalIR/1" :identity "lawmax/WRONG-IDENTITY/9"')),
   'wrong-version':   ('schema', lambda t: R(t, ':type-locator "define-reference LegalIR/1" :identity "lawmax/legal-ir/1" :version "1"', ':type-locator "define-reference LegalIR/1" :identity "lawmax/legal-ir/1" :version "9"')),
   'wrong-reference-target': ('schema', lambda t: R(t, '(define-canonical-identity LegalIR/1               :status VERIFIED :verify-file "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.8-SCHEMAS.sexp" :type-locator "define-reference LegalIR/1"', '(define-canonical-identity LegalIR/1               :status VERIFIED :verify-file "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.8-SCHEMAS.sexp" :type-locator "define-reference NoSuchRef/1"')),
   'locator-absent':  ('schema', lambda t: R(t, '(define-reference MemoryEvent/1 :canonical-file "source/memory.lisp" :identity "lawmax/memory-event/1" :version "1" :locator "record-episode")', '(define-reference MemoryEvent/1 :canonical-file "source/memory.lisp" :identity "lawmax/memory-event/1" :version "1" :locator "ZZZ_NO_SUCH_LOCATOR")')),
   'held/generic-substring-locator': ('schema', lambda t: R(t, '(define-reference MemoryEvent/1 :canonical-file "source/memory.lisp" :identity "lawmax/memory-event/1" :version "1" :locator "record-episode")', '(define-reference MemoryEvent/1 :canonical-file "source/memory.lisp" :identity "lawmax/memory-event/1" :version "1" :locator "memory")')),
   'held/remove-all-canon': ('schema', lambda t: re.sub(r'\(define-canonical-identity[^\n]*\n','',t)),
   'held/remove-one-canon': ('schema', lambda t: re.sub(r'\(define-canonical-identity LegalIR/1[^\n]*\n','',t,count=1)),
   'held/canon-wrong-locator': ('schema', lambda t: t.replace(':version "1" :locator "record-episode")', ':version "1" :locator "episode-id")', 1)),
 },
 'V8-CAP': {
   'nonexistent-symbol':      ('schema', lambda t: R(t, ':symbol "get-eli-law-prefix"', ':symbol "zzz_no_such_symbol"')),
   'wrong-package':           ('schema', lambda t: R(t, ':package "orchestrator.uris"', ':package "orchestrator.NOPE"')),
   'wrong-file':              ('schema', lambda t: R(t, ':file "source/canonical-uris.lisp"', ':file "source/NO_SUCH.lisp"')),
   'symbol-in-other-package': ('schema', lambda t: R(t, ':symbol "get-eli-law-prefix"', ':symbol "defpackage"')),
   'held/cap-unrelated-symbol': ('schema', lambda t: t.replace(':symbol "get-eli-law-prefix"', ':symbol "get-base-uri"', 1)),
 },
 'V8-OWN': {
   'dup-store':            ('schema', lambda t: R(t, '(define-write-authority :store "journal"', '(define-write-authority :store "journal"               :owner "WP-03 journal.lisp" :write-authority "write-authority.lisp" :writers 1)\n(define-write-authority :store "journal"')),
   'two-writers':          ('schema', lambda t: R(t, ':store "journal"               :owner "WP-03 journal.lisp"                :write-authority "write-authority.lisp" :writers 1', ':store "journal"               :owner "WP-03 journal.lisp"                :write-authority "write-authority.lisp" :writers 2')),
   'writer-on-readonly':   ('schema', lambda t: R(t, ':store "static-site"           :owner "WP-12 static-site.lisp"            :write-authority "none" :writers 0 :read-only t', ':store "static-site"           :owner "WP-12 static-site.lisp"            :write-authority "none" :writers 1 :read-only t')),
   'held/ghost-owner':     ('schema', lambda t: R(t, ':store "journal"               :owner "WP-03 journal.lisp"', ':store "journal"               :owner "WP-99 ghost-does-not-exist.lisp"')),
   'held/ghost-writer':    ('schema', lambda t: R(t, ':store "journal"               :owner "WP-03 journal.lisp"                :write-authority "write-authority.lisp"', ':store "journal"               :owner "WP-03 journal.lisp"                :write-authority "ghost-writer-does-not-exist.lisp"')),
   'held/owner-unrelated-real': ('schema', lambda t: t.replace(':store "journal"               :owner "WP-03 journal.lisp"', ':store "journal"               :owner "WP-05 legal-ast.lisp"', 1)),
   'held/writer-unrelated-real': ('schema', lambda t: t.replace(':store "journal"               :owner "WP-03 journal.lisp"                :write-authority "write-authority.lisp"', ':store "journal"               :owner "WP-03 journal.lisp"                :write-authority "memory.lisp"', 1)),
 },
 'V8-COGLIFE': {
   'remove-resume-edge':      ('schema', lambda t: R(t, '(CLARIFY-SUSPEND CLARIFY-RESUME) ', '')),
   'wrong-instance-binding':  ('schema', lambda t: R(t, '(:resume_binding_ref :type ref)', '(:no_binding :type ref)')),
   'incompatible-edge-type':  ('schema', lambda t: R(t, '(:node MORPH             :in TokenStream/1                   :out MorphLattice/1)', '(:node MORPH             :in TokenStream/1                   :out WrongOut/1)')),
   'orphan-terminal':         ('schema', lambda t: R(t, ':terminals (TERM-UNDERDETERMINED TERM-CONFLICTING TERM-ABSTAINED TERM-ERROR RESULT)', ':terminals (TERM-UNDERDETERMINED TERM-CONFLICTING TERM-ABSTAINED TERM-ERROR TERM-ORPHAN RESULT)')),
   'illegal-cycle':           ('schema', lambda t: R(t, '(PROMOTE RESULT))', '(PROMOTE RESULT) (RESULT PERCEIVE))')),
   'held/flow-edge-undeclared-node': ('schema', lambda t: R(t, ':flow-edges ((PERCEIVE SEGMENT)', ':flow-edges ((PERCEIVE GHOSTNODE) (PERCEIVE SEGMENT)')),
   'held/extra-dangling-resume':     ('schema', lambda t: R(t, ':resume-edges ((CLARIFY-SUSPEND CLARIFY-RESUME)', ':resume-edges ((CLARIFY-RESUME DANGLE2) (CLARIFY-SUSPEND CLARIFY-RESUME)')),
   'held/terminal-outgoing-any-family': ('schema', lambda t: R(t, ':terminal-edges ((CLARIFY-DECIDE TERM-UNDERDETERMINED)', ':terminal-edges ((TERM-ERROR PERCEIVE) (CLARIFY-DECIDE TERM-UNDERDETERMINED)')),
   'held/incompatible-terminal-edge': ('schema', lambda t: t.replace('(:node TERM-ERROR        :in PromotionEvidence/1', '(:node TERM-ERROR        :in WrongIn/1', 1)),
   'held/incompatible-resume-edge': ('schema', lambda t: t.replace('(:node CLARIFY-RESUME    :in ClarificationResponse/1         :out ClarificationDecision/1)', '(:node CLARIFY-RESUME    :in ClarificationResponse/1         :out WrongOut/1)', 1)),
   'held/disconnected-node': ('schema', lambda t: t.replace(':nodes (PERCEIVE',':nodes (GHOSTISLAND PERCEIVE',1).replace('(:node PERCEIVE','(:node GHOSTISLAND      :in X/1 :out Y/1)\n  (:node PERCEIVE',1)),
   'held/duplicate-graph': ('schema', lambda t: t.replace('(define-cognition-graph cognition-graph-v8', '(define-cognition-graph dup-graph :nodes (A) :entry A)\n(define-cognition-graph cognition-graph-v8', 1)),
 },
 'V8-CLARIFY': {
   'corrupt-abstain-fixture':   ('schema', lambda t: R(t, '(:valid   ABSTAIN            :selected 0 :merged 0 :provenance-preserved t)', '(:valid   ABSTAIN            :selected 1 :merged 0 :provenance-preserved t)')),
   'corrupt-selection-fixture': ('schema', lambda t: R(t, '(:valid   EXPLICIT_SELECTION :selected 1 :merged 0 :provenance-preserved t)', '(:valid   EXPLICIT_SELECTION :selected 0 :merged 0 :provenance-preserved t)')),
   'corrupt-merge-provenance':  ('schema', lambda t: R(t, '(:invalid EXPLICIT_MERGE     :selected 0 :merged 1 :provenance-preserved nil)', '(:valid   EXPLICIT_MERGE     :selected 0 :merged 1 :provenance-preserved nil)')),
   'held/remove-cardinality-table': ('schema', lambda t: re.sub(r'\(define-cardinality-table[\s\S]*?all-preserved\)\)','',t,count=1)),
 },
 'V8-RASTATUS': {
   'merge-proof-into-security': ('schema', lambda t: R(t, ' (:proof_integrity :type DimensionState)', '')),
   'derived-not-constant':      ('schema', lambda t: R(t, ':derived :type (member :true)', ':derived :type (member :true :false)')),
   'self-qualification-allowed':('schema', lambda t: R(t, ':self-qualification :rejected', ':self-qualification :accepted')),
   'drop-unknown-state':        ('schema', lambda t: R(t, '(define-closed-enum DimensionState (:OK) (:DEGRADED) (:FAILED) (:UNKNOWN))', '(define-closed-enum DimensionState (:OK) (:DEGRADED) (:FAILED))')),
   'advisory-can-block':        ('schema', lambda t: R(t, ':advisory-never-blocks t', ':advisory-never-blocks nil')),
   'held/remove-cause-refs':    ('schema', lambda t: R(t, '  (:cause_refs :type (list ref))                     ; full simultaneous causes, never collapsed\n', '')),
   'held/remove-advisory-dims': ('schema', lambda t: R(t, '(:advisory_dimensions :type (list ref)) ', '')),
   'held/bogus-failure-class':  ('schema', lambda t: R(t, ':failure :WITHHELD          :recovery-evidence "red-team', ':failure :BOGUS_CLASS       :recovery-evidence "red-team')),
   'held/policy-weaken-security': ('schema', lambda t: t.replace('(:dimension :security          :class :MANDATORY', '(:dimension :security          :class :ADVISORY ', 1)),
   'held/duplicate-dimension': ('schema', lambda t: t.replace('  (:dimension :coverage          :class :MANDATORY :failure :ATTRIBUTED_RELIANCE :recovery-evidence "census completeness evidence" :authority "coverage owner")', '  (:dimension :coverage          :class :MANDATORY :failure :ATTRIBUTED_RELIANCE :recovery-evidence "census completeness evidence" :authority "coverage owner")\n  (:dimension :coverage          :class :MANDATORY :failure :ATTRIBUTED_RELIANCE :recovery-evidence "dup" :authority "dup")', 1)),
   'held/record-field-wrong-type': ('schema', lambda t: t.replace('(:coverage :type DimensionState)', '(:coverage :type ref)', 1)),
   'held/blocking-bad-cardinality': ('schema', lambda t: t.replace('(:blocking_dimensions :type (list ref))', '(:blocking_dimensions :type ref)', 1)),
   'held/aggregation-always-full': ('schema', lambda t: t.replace(':rule "reliance = min over', ':rule "reliance = FULL_RELIANCE always ignore', 1)),
   'held/enum-duplicate-state': ('schema', lambda t: t.replace('(define-closed-enum DimensionState (:OK) (:DEGRADED) (:FAILED) (:UNKNOWN))', '(define-closed-enum DimensionState (:OK) (:DEGRADED) (:FAILED) (:UNKNOWN) (:UNKNOWN))', 1)),
 },
 'V8-SYM': {
   'broken-edge':           ('schema', lambda t: R(t, ' (PROOF PUBLISH))', ')')),
   'unreachable-mandatory': ('schema', lambda t: R(t, ' (IR COMPILE)', '')),
   'mandatory-model-node':  ('schema', lambda t: R(t, ':proposer-mandatory-nodes ()', ':proposer-mandatory-nodes (IR)')),
   'proposer-removal-inequiv': ('schema', lambda t: R(t, ':symbolic-only-nodes (ACQUIRE CENSUS ADMIT IR REASON COMPILE PROOF PUBLISH)', ':symbolic-only-nodes (ACQUIRE CENSUS IR REASON COMPILE PROOF PUBLISH)')),
   'held/empty-node-universe': ('schema', lambda t: t.replace(':nodes (ACQUIRE CENSUS ADMIT IR REASON COMPILE PROOF PUBLISH)', ':nodes ()', 1)),
   'held/remove-proof-mandatory': ('schema', lambda t: t.replace(':mandatory-nodes (ACQUIRE CENSUS IR COMPILE PROOF PUBLISH)', ':mandatory-nodes (ACQUIRE CENSUS IR COMPILE PUBLISH)', 1)),
   'held/remove-mutation-list': ('schema', lambda t: t.replace(':mutations (broken-edge unreachable-mandatory-stage mandatory-model-node proposer-removal-inequivalence)', ':mutations ()', 1)),
 },
 'V8-REQ': {
   'blank-requirement':   ('trc', lambda t: _req_blank(t, 'requirement')),
   'blank-owner-seat':    ('trc', lambda t: _req_blank(t, 'owner seat')),
   'blank-test':          ('trc', lambda t: _req_blank(t, 'test')),
   'blank-future-wp':     ('trc', lambda t: _req_blank(t, 'future wp')),
   'blank-interface':     ('trc', lambda t: _req_blank(t, 'interface')),
   'unresolvable-interface-id': ('trc', lambda t: _req_set_if(t, ' `define-public-edge` ')),
   'held/substitute-id-keep-17': ('trc', lambda t: R(t, '| DFT-01 | real public/private closure', '| RA8-FAKE | real public/private closure')),
   'held/traceability-wp99': ('trc', lambda t: t.replace('| T8-PUBPRIV | WP-12 |', '| T8-PUBPRIV | WP-99 |', 1)),
   'held/traceability-ghost-test': ('trc', lambda t: t.replace('| T8-PUBPRIV | WP-12 |', '| T8-NOPE | WP-12 |', 1)),
 },
 'V8-RA-DELTAS': {
   'drop-to-six':           ('schema', lambda t: R(t, '  (:delta RA-SIDE    :seat SidecarSourceProfile/1     :owner S26 :requirement RA8-SIDE  :test T8-SIDE))', '  )')),
   'rename-jurns-to-frost': ('schema', lambda t: R(t, '(:delta RA-JUR-NS  :seat JurisdictionNamespace/1   :owner S25 :requirement RA8-JURNS :test T8-JURNS)', '(:delta RA-FROST   :seat JurisdictionNamespace/1   :owner S25 :requirement RA8-JURNS :test T8-JURNS)')),
   'blank-seat':            ('schema', lambda t: R(t, '(:delta RA-K       :seat CitationMetricV8/1         :owner S15 :requirement RA8-K     :test T8-K)', '(:delta RA-K       :seat  :owner S15 :requirement RA8-K     :test T8-K)')),
   'held/delta-nonexistent-seat': ('schema', lambda t: t.replace('(:delta RA-EPOCH   :seat CanonicalCitationURI/1   :owner S25', '(:delta RA-EPOCH   :seat NoSuchType/1   :owner S25', 1)),
   'held/delta-shared-seat': ('schema', lambda t: t.replace('(:delta RA-CONT    :seat ContinuityPolicy/1', '(:delta RA-CONT    :seat CanonicalCitationURI/1', 1)),
   'held/delta-ghost-owner': ('schema', lambda t: t.replace('(:delta RA-EPOCH   :seat CanonicalCitationURI/1   :owner S25', '(:delta RA-EPOCH   :seat CanonicalCitationURI/1   :owner S999', 1)),
 },
 'V8-WP': {
   'held/wp-evidence-absent': ('schema', lambda t: t.replace(':wp WP-03 :file "WP-03.md" :evidence "Legal IR"', ':wp WP-03 :file "WP-03.md" :evidence "ZZZ_ABSENT_EVIDENCE"', 1)),
   'held/wp-future-mapped-to-file': ('schema', lambda t: t.replace(':concept MEMORY_KERNEL            :wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :file "none"', ':concept MEMORY_KERNEL            :wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :file "WP-11.md"', 1)),
   'held/wp-ghost-file': ('schema', lambda t: t.replace(':concept COGNITION_DAG            :wp WP-08 :file "WP-08.md"', ':concept COGNITION_DAG            :wp WP-08 :file "WP-99.md"', 1)),
 },
}

def _trc_cols(v18):
    hdr = re.search(r'\|\s*id\s*\|(.+?)\|\s*\n', v18)
    return [h.strip().lower() for h in (hdr.group(1).split('|') if hdr else [])]
def _colidx(cols, name):
    for i, c in enumerate(cols):
        if name in c:
            return i
    return -1
def _req_first_row_edit(t, fn):
    head_, _, v18 = t.partition('§v1.8')
    cols = _trc_cols(v18)
    m = re.search(r'(\|\s*(?:RA8-[A-Z0-9-]+|DFT-\d+)\s*\|)([^\n]*)', v18)
    if not m:
        return t
    cells = fn(m.group(2).split('|'), cols)
    v18b = v18[:m.start()] + m.group(1) + '|'.join(cells) + v18[m.end():]
    return head_ + '§v1.8' + v18b
def _req_blank(t, colname):
    def fn(cells, cols):
        ix = _colidx(cols, colname)
        if 0 <= ix < len(cells):
            cells[ix] = '   '
        return cells
    return _req_first_row_edit(t, fn)
def _req_set_if(t, val):
    def fn(cells, cols):
        ix = _colidx(cols, 'interface')
        if 0 <= ix < len(cells):
            cells[ix] = val
        return cells
    return _req_first_row_edit(t, fn)

# ============================ CLI ============================
def do_run(gid, overrides):
    if gid not in GUARDS:
        print('ERROR unknown-guard ' + gid); return 2
    try:
        v, reason = run_guard(gid, load(overrides))
    except Exception as e:
        print('ERROR ' + type(e).__name__ + ': ' + str(e)); return 2
    print(('OK ' if v == 0 else 'VIOLATION ') + reason)
    return 0 if v == 0 else 3

def do_mutate(gid, mid, outdir):
    if gid not in MUT or mid not in MUT[gid]:
        print('ERROR unknown-mutation ' + gid + '/' + mid); return 2
    key, fn = MUT[gid][mid]
    base = readpath(DEFAULTS[key]); mut = fn(base)
    if mut == base:
        print('ERROR mutation-did-not-change-bytes ' + gid + '/' + mid); return 2
    os.makedirs(outdir, exist_ok=True)
    ext = os.path.splitext(DEFAULTS[key])[1] or '.txt'
    bp = os.path.join(outdir, 'baseline' + ext); mp = os.path.join(outdir, 'mutant' + ext)
    open(bp, 'w', encoding='utf-8').write(base)
    open(mp, 'w', encoding='utf-8').write(mut)
    print('%s %s %s' % (key, bp, mp)); return 0

def do_selftest():
    import tempfile
    fails = []
    for gid in GUARDS:
        v, reason = run_guard(gid, load({}))
        if v != 0:
            fails.append('BASELINE %s not clean: %s' % (gid, reason))
    for gid in MUT:
        for mid in MUT[gid]:
            key, fn = MUT[gid][mid]
            base = readpath(DEFAULTS[key]); mut = fn(base)
            if mut == base:
                fails.append('MUT %s/%s did-not-change-bytes' % (gid, mid)); continue
            with tempfile.NamedTemporaryFile('w', suffix=os.path.splitext(DEFAULTS[key])[1], delete=False, encoding='utf-8') as tf:
                tf.write(mut); mp = tf.name
            try:
                v, reason = run_guard(gid, load({key: mp}))
            finally:
                os.unlink(mp)
            if v == 0:
                fails.append('MUT %s/%s SURVIVED: %s' % (gid, mid, reason))
    if fails:
        print('SELFTEST-FAIL')
        for f in fails:
            print('  ' + f)
        return 1
    print('SELFTEST-OK guards=%d mutations=%d' % (len(GUARDS), sum(len(MUT[g]) for g in MUT)))
    return 0

def do_manifest(overrides):
    """Recompute every non-self artifact SHA-256 declared in the manifest and compare to its pin; verify the file
    exists and that no path row is duplicated. A working-tree drift (e.g. MANDATORY->ADVISORY in the schema without
    updating the manifest) makes the real SHA differ from the pin and is REJECTED. --file KEY=PATH overrides one
    artifact so a mutation can be injected. Prints OK/VIOLATION; exit 0/3/2."""
    try:
        F = load(overrides)
        man = F['man']
        rows = re.findall(r'\|\s*`([0-9a-f]{64})`\s*\|\s*`([^`]+)`\s*\|', man)
        self_rows = re.findall(r'\|\s*\(self\)\s*\|\s*`([^`]+)`\s*\|', man)
        v = 0; why = []
        if len(self_rows) != 1:
            v += 1; why.append('self-rows!=1:%d' % len(self_rows))
        seen = set()
        for pin, path in rows:
            if path in seen:
                v += 1; why.append('duplicate-row:' + path)
            seen.add(path)
            bn = os.path.basename(path)
            if bn in BYBASENAME and BYBASENAME[bn] in F:
                content = F[BYBASENAME[bn]]
            else:
                fp = os.path.join(ROOT, path)
                if not os.path.isfile(fp):
                    v += 1; why.append('missing-file:' + path); continue
                content = readpath(fp)
            actual = hashlib.sha256(content.encode('utf-8')).hexdigest()
            if actual != pin:
                v += 1; why.append('SHA-DRIFT:' + bn)
        if not rows:
            v += 1; why.append('no-pinned-rows')
    except Exception as e:
        print('ERROR ' + type(e).__name__ + ': ' + str(e)); return 2
    if v == 0:
        print('OK manifest: %d pinned artifacts match, 1 self' % len(rows)); return 0
    print('VIOLATION ' + '; '.join(why[:8])); return 3

def do_genrun(verbose=False):
    """Property-based mutation families GENERATED from the declared schema/registries (never tied to one literal
    line). For every parsed dimension, canonical identity, RA delta, capability, store, record dimension-field and
    requirement row, derive a deletion / duplication / substitution / type-weakening / policy-downgrade / malformed
    mutation, apply it to the real bytes in a temp file, rerun the SAME guard, and require exit-3 rejection."""
    import tempfile
    base = load({})
    schema = base['schema']; trc = base['trc']
    forms = read_all(schema)
    dims = [d[0] for d in ra_model(base)[2]]
    canon = [str(form_name(f)) for f in forms_by_head(forms, 'define-canonical-identity') if form_name(f)]
    deltas = []
    for f in forms_by_head(forms, 'define-ra-delta-seats'):
        for spec in f[1:]:
            if is_list(spec) and spec and isinstance(spec[0], Sym) and str(spec[0]) == ':delta':
                deltas.append(str(spec[1]))
    caps = [str(kv_after(e, ':symbol')) for e in forms_by_head(forms, 'define-capability-seat')
            if kv_after(e, ':kind') is not None and str(kv_after(e, ':kind')) == ':CODE' and kv_after(e, ':symbol')]
    stores = [(str(kv_after(f, ':store')), str(kv_after(f, ':owner')))
              for f in forms_by_head(forms, 'define-write-authority')]
    ras = None
    for f in forms_by_head(forms, 'define-record'):
        if str(form_name(f) or '') == 'RootAuthorityStatus/1':
            ras = f
    dim_fields = []
    if ras is not None:
        _, flds = record_attrs_fields(ras)
        dim_fields = [field_key(fl)[1:] for fl in flds if str(field_type_expr(fl)) == 'DimensionState']
    reqids = re.findall(r'\|\s*(DFT-\d+|RA8-[A-Z0-9-]+)\s*\|', trc.split('§v1.8', 1)[1] if '§v1.8' in trc else '')

    gens = []   # (family, key, guard, filekey, mutated_text)
    def add(family, name, guard, filekey, mutated):
        gens.append((family, name, guard, filekey, mutated))
    # 1. policy-downgrade: each MANDATORY dimension -> ADVISORY
    for d in dims:
        m = re.sub(r'(\(:dimension\s+:' + re.escape(d) + r'\s+:class\s+:)MANDATORY', r'\1ADVISORY', schema, count=1)
        if m != schema:
            add('policy-downgrade', d, 'V8-RASTATUS', 'schema', m)
    # 2. canon-delete: remove each canonical identity
    for c in canon:
        m = re.sub(r'\(define-canonical-identity ' + re.escape(c) + r'\b[^\n]*\n', '', schema, count=1)
        if m != schema:
            add('canon-delete', c, 'V8-XREF', 'schema', m)
    # 3. delta-ghost-owner: each delta owner -> S999
    for dl in deltas:
        m = re.sub(r'(:delta ' + re.escape(dl) + r'\b[^)]*?:owner )S\d+', r'\g<1>S999', schema, count=1)
        if m != schema:
            add('delta-ghost-owner', dl, 'V8-RA-DELTAS', 'schema', m)
    # 4. cap-symbol-swap: each CODE cap symbol -> another cap's symbol (real but unrelated)
    for i, sym in enumerate(caps):
        other = caps[(i + 1) % len(caps)] if len(caps) > 1 else 'zzz_no'
        if other != sym:
            m = schema.replace(':symbol "' + sym + '"', ':symbol "' + other + '"', 1)
            if m != schema:
                add('cap-symbol-swap', sym, 'V8-CAP', 'schema', m)
    # 5. store-owner-swap: each store owner -> another store's owner (real but unrelated)
    for i, (st, ow) in enumerate(stores):
        oth = stores[(i + 1) % len(stores)][1] if len(stores) > 1 else 'x'
        if oth != ow:
            m = schema.replace(':owner "' + ow + '"', ':owner "' + oth + '"', 1)
            if m != schema:
                add('store-owner-swap', st, 'V8-OWN', 'schema', m)
    # 6. dim-field-weaken: each DimensionState record field -> ref
    for fld in dim_fields:
        m = schema.replace('(:' + fld + ' :type DimensionState)', '(:' + fld + ' :type ref)', 1)
        if m != schema:
            add('dim-field-weaken', fld, 'V8-RASTATUS', 'schema', m)
    # 7. req-id-substitute: each requirement row id -> a fake id
    for rid in reqids:
        m = trc.replace('| ' + rid + ' |', '| RA8-GENFAKE |', 1)
        if m != trc:
            add('req-id-substitute', rid, 'V8-REQ', 'trc', m)
    # 8. malformed-append: syntactic corruption families (parse-gate)
    for fam, suffix in (('unterminated-comment', '\n#| x'), ('unterminated-vbar', '\n(|x'),
                        ('unterminated-string', '\n(a "x'), ('unbalanced-paren', '\n(a b')):
        add('malformed-' + fam, 'schema', 'V8-PUBPRIV', 'schema', schema + suffix)

    fams = {}; survivors = []
    for family, name, guard, filekey, mutated in gens:
        fams[family] = fams.get(family, 0) + 1
        if mutated == base[filekey]:
            survivors.append('%s/%s:did-not-change-bytes' % (family, name)); continue
        with tempfile.NamedTemporaryFile('w', suffix=os.path.splitext(DEFAULTS[filekey])[1], delete=False, encoding='utf-8') as tf:
            tf.write(mutated); mp = tf.name
        try:
            v, reason = run_guard(guard, load({filekey: mp}))
        finally:
            os.unlink(mp)
        if v == 0:
            survivors.append('%s/%s SURVIVED(%s):%s' % (family, name, guard, reason))
    total = len(gens)
    if survivors:
        print('GEN-FAIL families=%d total=%d survivors=%d' % (len(fams), total, len(survivors)))
        for s in survivors[:20]:
            print('  ' + s)
        return 1
    print('GEN-OK families=%d total=%d killed=%d (%s)' % (len(fams), total, total,
          ','.join('%s:%d' % (k, fams[k]) for k in sorted(fams))))
    return 0

def main(argv):
    if not argv:
        print('ERROR no-command'); return 2
    cmd = argv[0]
    if cmd == '--selfcrash':
        raise RuntimeError('deliberate-selfcrash')
    if cmd == 'list-guards':
        for g in GUARDS:
            print(g)
        return 0
    if cmd == 'list-muts':
        for m in MUT.get(argv[1], {}):
            print(m)
        return 0
    if cmd == 'aggregate':
        F = load({}); states, reliance, dims = ra_model(F)
        total = len(states) ** len(dims)
        v, reason = run_guard('V8-RASTATUS', F)
        print('%d/%d states=%d dims=%d %s' % (total if v == 0 else 0, total, len(states), len(dims), 'OK' if v == 0 else 'VIOLATION:' + reason))
        return 0 if v == 0 else 3
    if cmd == 'run':
        gid = argv[1]; overrides = {}; i = 2
        while i < len(argv):
            if argv[i] == '--file':
                k, _, p = argv[i + 1].partition('='); overrides[k] = p; i += 2
            else:
                i += 1
        return do_run(gid, overrides)
    if cmd == 'mutate':
        gid = argv[1]; mid = argv[2]; outdir = None; i = 3
        while i < len(argv):
            if argv[i] == '--outdir':
                outdir = argv[i + 1]; i += 2
            else:
                i += 1
        return do_mutate(gid, mid, outdir)
    if cmd == 'gen-run':
        return do_genrun(verbose=('--verbose' in argv))
    if cmd == 'manifest':
        overrides = {}; i = 1
        while i < len(argv):
            if argv[i] == '--file':
                k, _, pth = argv[i + 1].partition('='); overrides[k] = pth; i += 2
            else:
                i += 1
        return do_manifest(overrides)
    if cmd == 'selftest':
        return do_selftest()
    print('ERROR unknown-command ' + cmd); return 2

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
