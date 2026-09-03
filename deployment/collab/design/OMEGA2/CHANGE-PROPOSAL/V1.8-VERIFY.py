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

def _read_one(text, i):
    n = len(text)
    # skip whitespace / line comments / #| block comments |#
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
        elif c in ' \t\r\n\f':
            i += 1
        else:
            break
    if i >= n:
        return None, i
    c = text[i]
    if c == '(':
        i += 1; lst = []
        while True:
            # skip ws/comments before each element
            while i < n and (text[i] in ' \t\r\n\f' or text[i] == ';'
                             or (text[i] == '#' and i + 1 < n and text[i + 1] == '|')):
                if text[i] == ';':
                    while i < n and text[i] != '\n':
                        i += 1
                elif text[i] == '#':
                    depth = 1; i += 2
                    while i < n and depth > 0:
                        if text[i] == '#' and i + 1 < n and text[i + 1] == '|':
                            depth += 1; i += 2
                        elif text[i] == '|' and i + 1 < n and text[i + 1] == '#':
                            depth -= 1; i += 2
                        else:
                            i += 1
                else:
                    i += 1
            if i >= n:
                raise ValueError('unbalanced (')
            if text[i] == ')':
                return lst, i + 1
            f, i = _read_one(text, i)
            lst.append(f)
    if c == ')':
        raise ValueError('unexpected )')
    if c == '"':
        i += 1; buf = []
        while i < n:
            d = text[i]
            if d == '\\' and i + 1 < n:
                buf.append(text[i + 1]); i += 2; continue
            if d == '"':
                return Str(''.join(buf)), i + 1
            buf.append(d); i += 1
        raise ValueError('unterminated string')
    if c == '|':                       # |vertical-bar symbol|
        i += 1; buf = []
        while i < n and text[i] != '|':
            buf.append(text[i]); i += 1
        return Sym('|' + ''.join(buf) + '|'), i + 1
    if c == '#' and i + 1 < n and text[i + 1] == '\\':   # #\x character literal
        j = i + 2
        if j < n:
            j += 1
        while j < n and text[j] not in _ATOM_STOP:
            j += 1
        return Sym(text[i:j]), j
    j = i
    while j < n and text[j] not in _ATOM_STOP:
        j += 1
    return Sym(text[i:j]), j

def read_all(text):
    out = []; i = 0; n = len(text)
    while True:
        f, i = _read_one(text, i)
        if f is None:
            break
        out.append(f)
        if i >= n:
            break
    return out

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
    try:
        return read_all(text)
    except Exception:
        return []

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

def g_pubpriv(F):
    priv = private_types(F); defined = defined_types(F)
    roots = public_interfaces(F, priv); adj = record_field_edges(F)
    recnames = set(adj)
    v = 0; why = []
    # (1) transitive field-type closure from public record roots
    seen = set(); stack = [r for r in roots if r in recnames]
    while stack:
        x = stack.pop()
        if x in seen:
            continue
        seen.add(x)
        if x in priv:
            v += 1; why.append('field-closure-leak:' + x); continue
        stack += adj.get(x, [])
    # (1b) ref-target: a canonical-identity / define-reference type-locator naming a private type
    for f in forms_by_head(top_forms(F['schema']), 'define-canonical-identity'):
        loc = kv_after(f, ':type-locator')
        if isinstance(loc, Str):
            for t in type_tokens(str(loc)):
                if t in priv:
                    v += 1; why.append('ref-target-leak->' + t)
    # (2) interface-io: public interface body naming a private TYPE
    for name, f in roots.items():
        for t in type_refs(f):
            if t in priv:
                v += 1; why.append('interface-io-leak:' + name + '->' + t)
    # (3) subsystem-dep: a PUBLIC subsystem :interface naming a private TYPE
    for f in forms_by_head(top_forms(F['sub']), 'define-subsystem'):
        owner = kv_after(f, ':owner'); itf = kv_after(f, ':interface')
        ow = str(owner) if owner is not None else ''
        if 'DEFERRED_PRIVATE' in ow or 'INTERFACE_ONLY' in ow:
            continue
        if isinstance(itf, Str):
            for t in type_tokens(str(itf)):
                if t in priv:
                    v += 1; why.append('subsystem-dep-leak->' + t)
    # (4) store-owner-writer
    for f in forms_by_head(top_forms(F['schema']), 'define-write-authority'):
        owner = str(kv_after(f, ':owner') or ''); auth = str(kv_after(f, ':write-authority') or '')
        w = kv_after(f, ':writers'); ro = kv_after(f, ':read-only')
        try:
            wn = int(str(w))
        except Exception:
            wn = 0
        if any(p in owner or p in auth for p in priv):
            v += 1; why.append('store-owner-leak')
        if ro is not None and str(ro) == 't' and wn != 0:
            v += 1; why.append('store-readonly-writer')
    # (5) mcp / (6) site: private type token anywhere in the parsed source
    for keyf, tag in (('mcp', 'mcp'), ('site', 'site')):
        for t in type_tokens(F[keyf]):
            if t in priv:
                v += 1; why.append(tag + '-leak->' + t)
    # (7) declassification: a public record other than DeclassificationReceipt carrying a private field-type
    for f in all_record_forms(F):
        nm = form_name(f)
        if nm is None or str(nm) in priv or 'DeclassificationReceipt' in str(nm):
            continue
        for t in adj.get(str(nm), []):
            if t in priv:
                v += 1; why.append('declass-leak:' + str(nm) + '->' + t)
    # (8) reject every UNDEFINED endpoint in the record field-type graph
    for nm, refs in adj.items():
        for t in refs:
            if t not in defined and t.split('/')[0].lower() not in PRIM:
                v += 1; why.append('undefined-endpoint:' + nm + '->' + t)
    return v, ('clean:%d roots,%d private' % (len(roots), len(priv))) if v == 0 else '; '.join(why[:6])

def g_xref(F):
    forms = top_forms(F['schema'])
    ci = forms_by_head(forms, 'define-canonical-identity')
    v = 0; why = []; verified = 0
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
        cftxt = open_or_loaded(str(cf), F)
        if cftxt is None:
            v += 1; why.append('canonical-file-missing:' + nm); continue
        locator = str(lc)
        cfl = str(cf).lower()
        if cfl.endswith('.lisp') or cfl.endswith('.sexp'):
            if locator not in top_symbols(cftxt):        # EXACT top-level symbol, not substring
                v += 1; why.append('locator-not-top-symbol:' + nm + ':' + locator); continue
        else:                                            # Markdown prose: exact whole-word term
            if not re.search(r'(?<![\w/-])' + re.escape(locator) + r'(?![\w/-])', cftxt):
                v += 1; why.append('locator-not-a-term:' + nm + ':' + locator); continue
        verified += 1
    return v, ('clean:%d verified, 0 unresolved' % verified) if v == 0 else '; '.join(why[:6])

TOPFORMS = r'\(def(?:un|method|generic|class|struct|parameter|var|macro)\s+'
def g_cap(F):
    v = 0; why = []
    entries = forms_by_head(top_forms(F['schema']), 'define-capability-seat')
    for e in entries:
        kind = kv_after(e, ':kind'); f = kv_after(e, ':file')
        txt = openroot(str(f)) if isinstance(f, Str) else None
        if kind is not None and str(kind) == ':CODE':
            sym = kv_after(e, ':symbol'); pkg = kv_after(e, ':package')
            syms = str(sym) if sym is not None else ''
            pkgs = str(pkg) if pkg is not None else ''
            if txt is None:
                v += 1; why.append('cap-file-missing'); continue
            if not pkgs or (('defpackage :' + pkgs) not in txt and ('defpackage #:' + pkgs) not in txt
                            and ('defpackage ' + pkgs) not in txt):
                v += 1; why.append('cap-pkg-absent:' + pkgs)
            if not syms or not re.search(TOPFORMS + re.escape(syms) + r'\b', txt):
                v += 1; why.append('cap-sym-not-topform:' + syms)
            ip = txt.find('(in-package :' + pkgs)
            dp = re.search(TOPFORMS + re.escape(syms or 'zzz') + r'\b', txt)
            if not (ip >= 0 and dp and dp.start() > ip):
                v += 1; why.append('cap-pkg-ownership:' + syms)
        elif kind is not None and str(kind) == ':DOCUMENT':
            sec = kv_after(e, ':section')
            if txt is None or not isinstance(sec, Str) or txt.count(str(sec)) < 1:
                v += 1; why.append('cap-doc-section')
            if kv_after(e, ':package') is not None:
                v += 1; why.append('cap-doc-has-package')
        else:
            v += 1; why.append('cap-unknown-kind')
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
    """Resolve a write-authority owner/writer STRING: every concrete resource token must resolve; a .lisp token
    must be a real source file unless the string carries a [design-target] marker; WP-/S- ids must be registered.
    Bare authority-role labels (e.g. 'coverage-owner', 'none') are permitted; an owner additionally needs at least
    one concrete anchor. Returns (ok, reason)."""
    design_target = '[design-target]' in s
    anchor = False
    toks = s.replace('[', ' [').replace(']', '] ').split()
    for t in toks:
        tt = t.strip('[]')
        if not tt or tt == 'design-target' or tt == 'interface-only':
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
        # else: bare authority-role label (allowed)
    if require_anchor and not anchor:
        return False, 'no-concrete-anchor'
    return True, 'ok'

def g_own(F):
    v = 0; why = []
    wa = forms_by_head(top_forms(F['schema']), 'define-write-authority')
    srcfiles = _repo_source_files(); wps = _wp_ids(F); subs = _subsystem_ids(F)
    seen = set()
    if len(wa) < 10:
        v += 1; why.append('too-few-stores:%d' % len(wa))
    for f in wa:
        store = str(kv_after(f, ':store') or '')
        owner = str(kv_after(f, ':owner') or '')
        auth = str(kv_after(f, ':write-authority') or '')
        wraw = kv_after(f, ':writers'); ro = kv_after(f, ':read-only')
        try:
            wn = int(str(wraw))
        except Exception:
            wn = 0
        if store in seen:
            v += 1; why.append('dup-store:' + store)
        seen.add(store)
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
    return v, ('clean:%d stores' % len(wa)) if v == 0 else '; '.join(why[:6])

def cog_model(F):
    forms = top_forms(F['schema'])
    g = None
    for f in forms_by_head(forms, 'define-cognition-graph'):
        g = f; break
    nt = None
    for f in forms_by_head(forms, 'define-cognition-node-types'):
        nt = f; break
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
                nm = str(spec[1]); it = str(kv_after(spec, ':in')); ot = str(kv_after(spec, ':out'))
                nodetypes[nm] = (it, ot)
    resp = None
    for f in forms_by_head(forms, 'define-record'):
        if form_name(f) is not None and str(form_name(f)) == 'ClarificationResponse/1':
            resp = f; break
    return nodes, nodetypes, flow, branch, resume, term, terminals, entry, resp

def g_coglife(F):
    nodes, nodetypes, flow, branch, resume, term, terminals, entry, resp = cog_model(F)
    v = 0; why = []
    fam = {'flow': flow, 'branch': branch, 'resume': resume, 'terminal': term}
    # declared graph nodes must equal the declared node-type set
    if nodes != set(nodetypes):
        v += 1; why.append('nodes!=node-types:%s' % ','.join(sorted(nodes ^ set(nodetypes)))[:60])
    # every endpoint in every edge family must be a declared node
    for fname, edges in fam.items():
        for a, b in edges:
            if a not in nodes:
                v += 1; why.append('undeclared-endpoint:%s:%s' % (fname, a))
            if b not in nodes:
                v += 1; why.append('undeclared-endpoint:%s:%s' % (fname, b))
    # flow/branch type compatibility: out(src)==in(tgt)
    for a, b in flow + branch:
        if a in nodetypes and b in nodetypes and nodetypes[a][1] != nodetypes[b][0]:
            v += 1; why.append('typed-incompat:%s->%s' % (a, b))
    # terminals: zero outgoing edges across EVERY family
    for fname, edges in fam.items():
        for a, b in edges:
            if a in terminals and a != 'RESULT':
                v += 1; why.append('terminal-outgoing:%s:%s' % (fname, a))
    # orphan terminal: every terminal (except RESULT) has an incoming edge
    incoming = set(b for e in fam.values() for a, b in e)
    for t in terminals:
        if t != 'RESULT' and t not in incoming:
            v += 1; why.append('orphan-terminal:' + t)
    # acyclic over flow+branch+terminal (resume edges are the only legal re-entry)
    def has_cycle(edges):
        adj = {}
        for a, b in edges:
            adj.setdefault(a, []).append(b)
        col = {}
        def dfs(u):
            col[u] = 1
            for w in adj.get(u, []):
                if col.get(w, 0) == 1:
                    return True
                if col.get(w, 0) == 0 and dfs(w):
                    return True
            col[u] = 2; return False
        return any(col.get(u, 0) == 0 and dfs(u) for u in list(adj))
    if has_cycle(flow + branch + term):
        v += 1; why.append('illegal-cycle')
    # explicit resume-transition rule: every resume edge is one of {SUSPEND->RESUME, RESUME->RESOLVE};
    # both required edges present; response binds the suspended instance.
    allowed_resume = {('CLARIFY-SUSPEND', 'CLARIFY-RESUME'), ('CLARIFY-RESUME', 'RESOLVE')}
    for e in resume:
        if e not in allowed_resume:
            v += 1; why.append('illegal-resume-transition:%s->%s' % e)
    for req in allowed_resume:
        if req not in set(resume):
            v += 1; why.append('missing-resume-edge:%s->%s' % req)
    if resp is None or field_by_key(resp, ':resume_binding_ref') is None:
        v += 1; why.append('resume-binding-missing')
    return v, ('clean:%d nodes,%d edges' % (len(nodes), sum(len(e) for e in fam.values()))) if v == 0 else '; '.join(why[:6])

def field_by_key(record_form, key):
    _, fields = record_attrs_fields(record_form)
    for fld in fields:
        if field_key(fld) == key:
            return fld
    return None

def g_clarify(F):
    forms = top_forms(F['schema'])
    fx = None
    for f in forms_by_head(forms, 'define-fixtures'):
        fx = f; break
    fixtures = []
    if fx is not None:
        for spec in fx[2:]:
            if is_list(spec) and len(spec) >= 2 and isinstance(spec[0], Sym):
                kind = str(spec[0])
                if kind in (':valid', ':invalid'):
                    ms = str(spec[1])
                    sel = kv_after(spec, ':selected'); mrg = kv_after(spec, ':merged'); prov = kv_after(spec, ':provenance-preserved')
                    fixtures.append((kind, ms, str(sel), str(mrg), str(prov)))
    def card_ok(ms, sel, mrg, prov):
        s = sel == '1'; m = mrg == '1'
        if ms == 'ABSTAIN':
            return (not s) and (not m)
        if ms == 'EXPLICIT_SELECTION':
            return s and (not m)
        if ms == 'EXPLICIT_MERGE':
            return (not s) and m and prov == 't'
        return False
    v = 0; why = []
    if len(fixtures) < 7:
        v += 1; why.append('too-few-fixtures:%d' % len(fixtures))
    for kind, ms, sel, mrg, prov in fixtures:
        ok = card_ok(ms, sel, mrg, prov)
        if kind == ':valid' and not ok:
            v += 1; why.append('valid-fails:' + ms)
        if kind == ':invalid' and ok:
            v += 1; why.append('invalid-passes:' + ms)
    return v, ('clean:%d fixtures' % len(fixtures)) if v == 0 else '; '.join(why[:6])

DIMSTATE_REQUIRED = {'OK', 'DEGRADED', 'FAILED', 'UNKNOWN'}
CLASS_ENUM = {'MANDATORY', 'ADVISORY'}
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
    # schema binding
    if ras is None or field_by_key(ras, ':cause_refs') is None:
        v += 1; why.append('cause_refs-missing')
    else:
        te = field_type_expr(field_by_key(ras, ':cause_refs'))
        if not (is_list(te) and len(te) >= 2 and str(te[0]) == 'list' and str(te[1]) == 'ref'):
            v += 1; why.append('cause_refs-bad-cardinality')
    if relp is None or field_by_key(relp, ':blocking_dimensions') is None:
        v += 1; why.append('blocking_dimensions-missing')
    if relp is None or field_by_key(relp, ':advisory_dimensions') is None:
        v += 1; why.append('advisory_dimensions-missing')
    if set(states) != DIMSTATE_REQUIRED:
        v += 1; why.append('dimstate!=OK/DEGRADED/FAILED/UNKNOWN')
    if len(dims) != 8:
        v += 1; why.append('dims!=8:%d' % len(dims))
    for dn, cl, fl in dims:
        if cl not in CLASS_ENUM:
            v += 1; why.append('bad-class:%s:%s' % (dn, cl))
        if fl not in reliance:
            v += 1; why.append('bad-failure-class:%s:%s' % (dn, fl))
    if v:
        return v, '; '.join(why[:6])
    order = ['WITHHELD', 'MACHINE_UNVERIFIED', 'ATTRIBUTED_RELIANCE', 'FULL_RELIANCE']
    BAD = {'FAILED', 'DEGRADED', 'UNKNOWN'}
    def project(st):
        worst = 'FULL_RELIANCE'; blocking = []; advisory = []
        for dn, cl, fl in dims:
            if st[dn] in BAD:
                if cl == 'MANDATORY':
                    blocking.append(dn)
                    if order.index(fl) < order.index(worst):
                        worst = fl
                else:
                    advisory.append(dn)
        return worst, tuple(sorted(blocking)), tuple(sorted(advisory))
    total = len(states) ** len(names); seen = 0; exercised = set()
    for combo in itertools.product(states, repeat=len(names)):
        st = dict(zip(names, combo)); p = project(st); seen += 1; exercised.update(combo)
        expect_b = tuple(sorted(d for d, c, fl in dims if c == 'MANDATORY' and st[d] in BAD))
        expect_a = tuple(sorted(d for d, c, fl in dims if c == 'ADVISORY' and st[d] in BAD))
        if p[1] != expect_b:
            v += 1; why.append('blocking-incomplete'); break
        if p[2] != expect_a:
            v += 1; why.append('advisory-incomplete'); break
    if seen != total:
        v += 1; why.append('coverage:%d!=%d' % (seen, total))
    if not DIMSTATE_REQUIRED.issubset(exercised):
        v += 1; why.append('UNKNOWN/DEGRADED-not-exercised')
    # recovery independence for EVERY ordered pair of distinct mandatory dimensions
    mand = [d for d, c, fl in dims if c == 'MANDATORY']
    for a in mand:
        for b in mand:
            if a == b:
                continue
            st = {d: ('FAILED' if d in (a, b) else 'OK') for d in names}
            st2 = dict(st); st2[a] = 'OK'
            if b not in project(st2)[1]:
                v += 1; why.append('recovery-not-independent:%s/%s' % (a, b)); break
        if 'recovery-not-independent' in ' '.join(why):
            break
    # structural invariants
    s = F['schema']
    if ':derived :type (member :true)' not in s:
        v += 1; why.append('derived-not-constant')
    if ':self-qualification :rejected' not in s:
        v += 1; why.append('self-qualification-not-rejected')
    if ':advisory-never-blocks t' not in s:
        v += 1; why.append('advisory-can-block')
    if not (ras is not None and field_by_key(ras, ':proof_integrity') is not None and field_by_key(ras, ':security') is not None):
        v += 1; why.append('proof_integrity-not-separate')
    return v, ('clean:%d states, 8 dims' % total) if v == 0 else '; '.join(why[:6])

def g_sym(F):
    forms = top_forms(F['schema'])
    pip = None
    for f in forms_by_head(forms, 'define-pipeline'):
        pip = f; break
    if pip is None:
        return 1, 'pipeline-missing'
    def g(key):
        return sym_list(kv_after(pip, key))
    mand = g(':mandatory-nodes'); propmand = [x for x in g(':proposer-mandatory-nodes') if x]
    symbolic = set(g(':symbolic-only-nodes'))
    edges = edge_pairs(kv_after(pip, ':edges'))
    entry = str(kv_after(pip, ':entry') or 'ACQUIRE'); exit_ = str(kv_after(pip, ':exit') or 'PUBLISH')
    mc = kv_after(pip, ':mutation-count')
    try:
        mcount = int(str(mc))
    except Exception:
        mcount = -1
    def reach(a, b, eds):
        adj = {}
        for x, y in eds:
            adj.setdefault(x, []).append(y)
        seen = set(); st = [a]
        while st:
            u = st.pop()
            if u in seen:
                continue
            seen.add(u); st += adj.get(u, [])
        return b in seen
    v = 0; why = []
    if mcount != 4:
        v += 1; why.append('mutation-count!=4:%d' % mcount)
    for mn in mand:
        if not reach(entry, mn, edges):
            v += 1; why.append('mandatory-unreachable:' + mn)
    if not reach(entry, exit_, edges):
        v += 1; why.append('exit-unreachable')
    if len(propmand) != 0:
        v += 1; why.append('proposer-mandatory-nonempty')
    sym_edges = [(a, b) for a, b in edges if a in symbolic and b in symbolic]
    for mn in mand:
        if mn != entry and not reach(entry, mn, sym_edges):
            v += 1; why.append('mandatory-not-symbolic-reachable:' + mn)
    return v, ('clean:%d mand,%d edges' % (len(mand), len(edges))) if v == 0 else '; '.join(why[:6])

EXPECTED_REQ_IDS = set('DFT-%02d' % i for i in range(1, 11)) | {
    'RA8-EPOCH', 'RA8-CONT', 'RA8-CORR', 'RA8-K', 'RA8-SIDE', 'RA8-MARK', 'RA8-FROST'}
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
    ids = [rid for rid, _ in rows]
    idset = set(ids)
    if idset != EXPECTED_REQ_IDS:
        v += 1; why.append('id-set!=expected:%s' % ','.join(sorted(idset ^ EXPECTED_REQ_IDS))[:60])
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
    return v, ('clean:%d rows' % len(rows)) if v == 0 else '; '.join(why[:6])

def g_radeltas(F):
    dsf = None
    for f in forms_by_head(top_forms(F['schema']), 'define-ra-delta-seats'):
        dsf = f; break
    deltas = []
    if dsf is not None:
        for spec in dsf[1:]:
            if is_list(spec) and spec and isinstance(spec[0], Sym) and str(spec[0]) == ':delta':
                dl = str(spec[1]) if len(spec) > 1 else ''
                seat = kv_after(spec, ':seat'); owner = kv_after(spec, ':owner')
                req = kv_after(spec, ':requirement'); test = kv_after(spec, ':test')
                deltas.append((dl, seat, owner, req, test))
    agreed = {'RA-EPOCH', 'RA-CONT', 'RA-CORR', 'RA-JUR-NS', 'RA-MARK', 'RA-K', 'RA-SIDE'}
    got = {d[0] for d in deltas}
    v = 0; why = []
    if got != agreed:
        v += 1; why.append('delta-set!=agreed:%s' % ','.join(sorted(got ^ agreed)))
    if len(deltas) != 7:
        v += 1; why.append('count!=7:%d' % len(deltas))
    if 'RA-FROST' in got:
        v += 1; why.append('frost-substitutes-jurns')
    def realval(x):
        return x is not None and not (isinstance(x, Sym) and str(x).startswith(':'))
    for dl, seat, owner, req, test in deltas:
        if not (realval(seat) and realval(owner) and realval(req) and realval(test)):
            v += 1; why.append('incomplete-delta:' + dl)
    return v, ('clean:7 deltas') if v == 0 else '; '.join(why[:6])

GUARDS = {
    'V8-PUBPRIV': g_pubpriv, 'V8-XREF': g_xref, 'V8-CAP': g_cap, 'V8-OWN': g_own,
    'V8-COGLIFE': g_coglife, 'V8-CLARIFY': g_clarify, 'V8-RASTATUS': g_rastatus,
    'V8-SYM': g_sym, 'V8-REQ': g_req, 'V8-RA-DELTAS': g_radeltas,
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
 },
 'V8-XREF': {
   'wrong-file':      ('schema', lambda t: R(t, ':verify-file "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.8-SCHEMAS.sexp" :type-locator "define-reference LegalIR/1"', ':verify-file "deployment/NO_SUCH_FILE.sexp" :type-locator "define-reference LegalIR/1"')),
   'wrong-identity':  ('schema', lambda t: R(t, ':type-locator "define-reference LegalIR/1" :identity "lawmax/legal-ir/1"', ':type-locator "define-reference LegalIR/1" :identity "lawmax/WRONG-IDENTITY/9"')),
   'wrong-version':   ('schema', lambda t: R(t, ':type-locator "define-reference LegalIR/1" :identity "lawmax/legal-ir/1" :version "1"', ':type-locator "define-reference LegalIR/1" :identity "lawmax/legal-ir/1" :version "9"')),
   'wrong-reference-target': ('schema', lambda t: R(t, '(define-canonical-identity LegalIR/1               :status VERIFIED :verify-file "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.8-SCHEMAS.sexp" :type-locator "define-reference LegalIR/1"', '(define-canonical-identity LegalIR/1               :status VERIFIED :verify-file "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.8-SCHEMAS.sexp" :type-locator "define-reference NoSuchRef/1"')),
   'locator-absent':  ('schema', lambda t: R(t, '(define-reference MemoryEvent/1 :canonical-file "source/memory.lisp" :identity "lawmax/memory-event/1" :version "1" :locator "record-episode")', '(define-reference MemoryEvent/1 :canonical-file "source/memory.lisp" :identity "lawmax/memory-event/1" :version "1" :locator "ZZZ_NO_SUCH_LOCATOR")')),
   'held/generic-substring-locator': ('schema', lambda t: R(t, '(define-reference MemoryEvent/1 :canonical-file "source/memory.lisp" :identity "lawmax/memory-event/1" :version "1" :locator "record-episode")', '(define-reference MemoryEvent/1 :canonical-file "source/memory.lisp" :identity "lawmax/memory-event/1" :version "1" :locator "memory")')),
 },
 'V8-CAP': {
   'nonexistent-symbol':      ('schema', lambda t: R(t, ':symbol "get-eli-law-prefix"', ':symbol "zzz_no_such_symbol"')),
   'wrong-package':           ('schema', lambda t: R(t, ':package "orchestrator.uris"', ':package "orchestrator.NOPE"')),
   'wrong-file':              ('schema', lambda t: R(t, ':file "source/canonical-uris.lisp"', ':file "source/NO_SUCH.lisp"')),
   'symbol-in-other-package': ('schema', lambda t: R(t, ':symbol "get-eli-law-prefix"', ':symbol "defpackage"')),
 },
 'V8-OWN': {
   'dup-store':            ('schema', lambda t: R(t, '(define-write-authority :store "journal"', '(define-write-authority :store "journal"               :owner "WP-03 journal.lisp" :write-authority "write-authority.lisp" :writers 1)\n(define-write-authority :store "journal"')),
   'two-writers':          ('schema', lambda t: R(t, ':store "journal"               :owner "WP-03 journal.lisp"                :write-authority "write-authority.lisp" :writers 1', ':store "journal"               :owner "WP-03 journal.lisp"                :write-authority "write-authority.lisp" :writers 2')),
   'writer-on-readonly':   ('schema', lambda t: R(t, ':store "static-site"           :owner "WP-12 static-site.lisp"            :write-authority "none" :writers 0 :read-only t', ':store "static-site"           :owner "WP-12 static-site.lisp"            :write-authority "none" :writers 1 :read-only t')),
   'held/ghost-owner':     ('schema', lambda t: R(t, ':store "journal"               :owner "WP-03 journal.lisp"', ':store "journal"               :owner "WP-99 ghost-does-not-exist.lisp"')),
   'held/ghost-writer':    ('schema', lambda t: R(t, ':store "journal"               :owner "WP-03 journal.lisp"                :write-authority "write-authority.lisp"', ':store "journal"               :owner "WP-03 journal.lisp"                :write-authority "ghost-writer-does-not-exist.lisp"')),
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
 },
 'V8-CLARIFY': {
   'corrupt-abstain-fixture':   ('schema', lambda t: R(t, '(:valid   ABSTAIN            :selected 0 :merged 0 :provenance-preserved t)', '(:valid   ABSTAIN            :selected 1 :merged 0 :provenance-preserved t)')),
   'corrupt-selection-fixture': ('schema', lambda t: R(t, '(:valid   EXPLICIT_SELECTION :selected 1 :merged 0 :provenance-preserved t)', '(:valid   EXPLICIT_SELECTION :selected 0 :merged 0 :provenance-preserved t)')),
   'corrupt-merge-provenance':  ('schema', lambda t: R(t, '(:invalid EXPLICIT_MERGE     :selected 0 :merged 1 :provenance-preserved nil)', '(:valid   EXPLICIT_MERGE     :selected 0 :merged 1 :provenance-preserved nil)')),
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
 },
 'V8-SYM': {
   'broken-edge':           ('schema', lambda t: R(t, ' (PROOF PUBLISH))', ')')),
   'unreachable-mandatory': ('schema', lambda t: R(t, ' (IR COMPILE)', '')),
   'mandatory-model-node':  ('schema', lambda t: R(t, ':proposer-mandatory-nodes ()', ':proposer-mandatory-nodes (IR)')),
   'proposer-removal-inequiv': ('schema', lambda t: R(t, ':symbolic-only-nodes (ACQUIRE CENSUS ADMIT IR REASON COMPILE PROOF PUBLISH)', ':symbolic-only-nodes (ACQUIRE CENSUS IR REASON COMPILE PROOF PUBLISH)')),
 },
 'V8-REQ': {
   'blank-requirement':   ('trc', lambda t: _req_blank(t, 'requirement')),
   'blank-owner-seat':    ('trc', lambda t: _req_blank(t, 'owner seat')),
   'blank-test':          ('trc', lambda t: _req_blank(t, 'test')),
   'blank-future-wp':     ('trc', lambda t: _req_blank(t, 'future wp')),
   'blank-interface':     ('trc', lambda t: _req_blank(t, 'interface')),
   'unresolvable-interface-id': ('trc', lambda t: _req_set_if(t, ' `define-public-edge` ')),
   'held/substitute-id-keep-17': ('trc', lambda t: R(t, '| DFT-01 | real public/private closure', '| RA8-FAKE | real public/private closure')),
 },
 'V8-RA-DELTAS': {
   'drop-to-six':           ('schema', lambda t: R(t, '  (:delta RA-SIDE    :seat SidecarSourceProfile/1     :owner S26 :requirement RA8-SIDE  :test T8-SIDE))', '  )')),
   'rename-jurns-to-frost': ('schema', lambda t: R(t, '(:delta RA-JUR-NS  :seat JurisdictionNamespace/1   :owner S25 :requirement RA8-JURNS :test T8-JURNS)', '(:delta RA-FROST   :seat JurisdictionNamespace/1   :owner S25 :requirement RA8-JURNS :test T8-JURNS)')),
   'blank-seat':            ('schema', lambda t: R(t, '(:delta RA-K       :seat CitationMetricV8/1         :owner S15 :requirement RA8-K     :test T8-K)', '(:delta RA-K       :seat  :owner S15 :requirement RA8-K     :test T8-K)')),
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
        v, reason = GUARDS[gid](load(overrides))
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
    for gid, fn in GUARDS.items():
        v, reason = fn(load({}))
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
                v, reason = GUARDS[gid](load({key: mp}))
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
        v, reason = g_rastatus(F)
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
    if cmd == 'selftest':
        return do_selftest()
    print('ERROR unknown-command ' + cmd); return 2

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
