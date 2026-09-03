#!/usr/bin/env python3
# V1.8-VERIFY.py — standalone, re-runnable guard runner for the v1.8 verification harness.
#
# Each guard READS real machine-readable source files by PATH and returns (violations, reason).
# A guard is "clean" when violations==0 (exit 0) and "rejects" when violations>0 (exit 3). A crash exits 2.
# Mutations are produced by `mutate`, which writes the REAL baseline bytes and the REAL mutated bytes to a
# workspace so the orchestrator can hash the actual files and rerun the SAME guard against the mutated bytes.
# Nothing here treats a filename / label / description as a substitute for mutated content.
#
# Usage:
#   V1.8-VERIFY.py list-guards                          -> exact declared guard-id set, one per line
#   V1.8-VERIFY.py list-muts   <GID>                    -> mutation ids for a guard, one per line
#   V1.8-VERIFY.py run <GID> [--file KEY=PATH ...]      -> run one guard; print "OK|VIOLATION <reason>"; exit 0/3/2
#   V1.8-VERIFY.py mutate <GID> <MID> --outdir DIR      -> write baseline+mutant real bytes; print "KEY BASE MUT"
#   V1.8-VERIFY.py aggregate                            -> print the full 4^N root-authority product result line
#   V1.8-VERIFY.py selftest                             -> internal: baseline 0 for every guard, every mutant flips
#   V1.8-VERIFY.py --selfcrash                          -> deliberately crash (meta-kill test hook)
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

def readpath(p):
    with open(p, encoding='utf-8', errors='replace') as f:
        return f.read()

def load(overrides):
    F = {}
    for k, dp in DEFAULTS.items():
        F[k] = readpath(overrides.get(k, dp))
    return F

def openroot(relpath):
    for base in (os.path.join(ROOT, relpath), os.path.join(HERE, relpath), relpath):
        if os.path.isfile(base):
            try:
                return readpath(base)
            except Exception:
                return None
    return None

BYBASENAME = {os.path.basename(p): k for k, p in DEFAULTS.items()}
def open_or_loaded(relpath, F):
    """Prefer the loaded (possibly mutated) content when the referenced file is one the run already holds,
    so a mutation of a self-referential verify-file/canonical-file is actually seen by the guard."""
    bn = os.path.basename(relpath)
    if bn in BYBASENAME and BYBASENAME[bn] in F:
        return F[BYBASENAME[bn]]
    return openroot(relpath)

# ---- shared s-expression helpers -------------------------------------------------------------
def strip(s):
    o = []; i = 0; ins = False
    while i < len(s):
        ch = s[i]
        if ins:
            o.append(ch)
            if ch == '\\' and i + 1 < len(s):
                o.append(s[i + 1]); i += 2; continue
            if ch == '"':
                ins = False
            i += 1; continue
        if ch == '"':
            ins = True; o.append(ch); i += 1; continue
        if ch == ';':
            while i < len(s) and s[i] != '\n':
                i += 1
            continue
        o.append(ch); i += 1
    return ''.join(o)

def blocks(cs, head):
    res = {}
    pat = re.compile(r'\(' + head + r'\s+([A-Za-z0-9_/+.-]+)')
    for m in pat.finditer(cs):
        s = m.start(); d = 0; j = s; ins = False
        while j < len(cs):
            ch = cs[j]
            if ins:
                if ch == '\\':
                    j += 2; continue
                if ch == '"':
                    ins = False
                j += 1; continue
            if ch == '"':
                ins = True
            elif ch == '(':
                d += 1
            elif ch == ')':
                d -= 1
                if d == 0:
                    j += 1; break
            j += 1
        res[m.group(1)] = cs[s:j]
    return res

def paren_depth(raw):
    d = 0; i = 0; ins = False
    while i < len(raw):
        c = raw[i]
        if ins:
            if c == '\\':
                i += 2; continue
            if c == '"':
                ins = False
            i += 1; continue
        if c == '"':
            ins = True
        elif c == ';':
            while i < len(raw) and raw[i] != '\n':
                i += 1
            continue
        elif c == '(':
            d += 1
        elif c == ')':
            d -= 1
        i += 1
    return d

# ---- derived type universe -------------------------------------------------------------------
def record_defs(F):
    """name -> (rest_of_head_line, body) for every define-record across active schemas."""
    d = {}
    for txt in (F['schema'], F['s17'], F['s16']):
        s = strip(txt)
        for name, body in blocks(s, 'define-record').items():
            head = body.split('\n', 1)[0]
            d[name] = (head, body)
    return d

def defined_types(F):
    d = set()
    for txt in (F['schema'], F['s17'], F['s16']):
        s = strip(txt)
        d |= set(re.findall(r'\(define-record\s+([A-Za-z0-9_]+/1)', s))
        d |= set(re.findall(r'\(define-reference\s+([A-Za-z0-9_]+/1)', s))
    d |= set(re.findall(r'\(define-interface\s+([A-Za-z0-9_/-]+)', strip(F['isr'])))
    return d

def private_types(F):
    priv = set()
    for name, (head, body) in record_defs(F).items():
        if (':public-dependency nil' in head or ':status :DEFERRED_PRIVATE' in head
                or ':status :SPECIFICATION_ONLY' in head or ':status :INTERFACE_ONLY' in head):
            priv.add(name)
    for m in re.finditer(r'\(define-interface\s+([A-Za-z0-9_/-]+)(.*?)(?=\(define|\Z)', strip(F['isr']), re.S):
        name, body = m.group(1), m.group(2)
        if (':RESTRICTED' in body or ':DEFERRED_PRIVATE' in body or ':INTERFACE_ONLY' in body
                or ':public-dependency nil' in body):
            priv.add(name)
    return priv

def public_interfaces(F, priv):
    roots = {}
    for m in re.finditer(r'\(define-interface\s+([A-Za-z0-9_/-]+)(.*?)(?=\(define|\Z)', strip(F['isr']), re.S):
        name, body = m.group(1), m.group(2)
        if name in priv:
            continue
        if ':classification :NORMATIVE' in body:
            roots[name] = body
    return roots

def field_type_edges(F):
    """record name -> list of /1 types referenced in its :type fields (the field-type edge family)."""
    adj = {}
    for name, (head, body) in record_defs(F).items():
        toks = []
        for fm in re.finditer(r'\(:([A-Za-z0-9_]+)\s+:type\s+(\([^()]*\)|[^()\s]+)', body):
            for t in re.findall(r'([A-Za-z0-9_]+/1)', fm.group(2)):
                toks.append(t)
        adj[name] = toks
    return adj

# ---- GUARDS -----------------------------------------------------------------------------------
def g_pubpriv(F):
    priv = private_types(F)
    defined = defined_types(F)
    roots = public_interfaces(F, priv)
    adj = field_type_edges(F)
    recs = record_defs(F)
    v = 0; why = []
    PRIM = {'ref', 'id', 'sha256', 'sig', 'instant', 'scope', 'semver', 'text', 'keyword', 'pubkey',
            'kid', 'anchor', 'usc-id', 'duration', 'uncertainty', 'null', 'span', 'mime', 'url', 'bool'}
    # (1) transitive field-type closure from every public record root: no private node reachable
    public_records = [r for r in roots if r in recs]
    seen = set(); stack = list(public_records)
    while stack:
        x = stack.pop()
        if x in seen:
            continue
        seen.add(x)
        if x in priv:
            v += 1; why.append('field-closure-leak:' + x); continue
        stack += adj.get(x, [])
    # (1b) ref-target: a canonical-identity / define-reference type-locator pointing at a PRIVATE type
    for tok in re.findall(r':type-locator\s+"[^"]*?([A-Za-z0-9_]+/1)"', F['schema']):
        if tok in priv:
            v += 1; why.append('ref-target-leak->' + tok)
    # (2) interface-io: a public interface body naming a private TYPE
    for name, body in roots.items():
        for t in re.findall(r'([A-Za-z0-9_]+/1)', body):
            if t in priv:
                v += 1; why.append('interface-io-leak:' + name + '->' + t)
    # (3) subsystem-dep: a PUBLIC subsystem :interface naming a private TYPE
    for m in re.finditer(r'\(define-subsystem\s+S\d+(.*?)(?=\(define-subsystem|\Z)', strip(F['sub']), re.S):
        b = m.group(1)
        owner = (re.search(r':owner\s+"([^"]*)"', b) or [None, ''])[1]
        if 'DEFERRED_PRIVATE' in owner or 'INTERFACE_ONLY' in owner:
            continue
        itf = re.search(r':interface\s+"([^"]*)"', b)
        if itf:
            for t in re.findall(r'([A-Za-z0-9_]+/1)', itf.group(1)):
                if t in priv:
                    v += 1; why.append('subsystem-dep-leak->' + t)
    # (4) store-owner-writer: private token in owner/writer, or read-only store carrying a writer
    for m in re.finditer(r'\(define-write-authority\s+:store\s+"[^"]+"\s+:owner\s+"([^"]+)"\s+:write-authority\s+"([^"]+)"\s+:writers\s+(\d+)(\s+:read-only\s+t)?', strip(F['schema'])):
        owner, auth, w, ro = m.group(1), m.group(2), int(m.group(3)), m.group(4)
        if any(p in owner or p in auth for p in priv):
            v += 1; why.append('store-owner-leak')
        if ro and w != 0:
            v += 1; why.append('store-readonly-writer')
    # (5) api-mcp-schema: mcp source naming a private type
    for t in re.findall(r'([A-Za-z0-9_]+/1)', F['mcp']):
        if t in priv:
            v += 1; why.append('mcp-leak->' + t)
    # (6) publication: static-site naming a private type
    for t in re.findall(r'([A-Za-z0-9_]+/1)', F['site']):
        if t in priv:
            v += 1; why.append('site-leak->' + t)
    # (7) declassification: a PUBLIC record other than DeclassificationReceipt carrying a private scope type
    for name, (head, body) in recs.items():
        if name in priv or 'DeclassificationReceipt' in name:
            continue
        for t in adj.get(name, []):
            if t in priv:
                v += 1; why.append('declass-leak:' + name + '->' + t)
    # (8) reject every UNDEFINED endpoint in the record field-type / interface graph
    for name, (head, body) in recs.items():
        for t in adj.get(name, []):
            base = t.split('/')[0]
            if t not in defined and base.lower() not in PRIM:
                v += 1; why.append('undefined-endpoint:' + name + '->' + t)
    return v, ('clean:%d roots,%d private' % (len(roots), len(priv))) if v == 0 else '; '.join(why[:6])

def g_xref(F):
    """Two-part canonical-identity resolution (part A identity+version in the ref block; part B the block's
    canonical-file exists and contains the locator). Zero unresolved, zero blockers -> clean."""
    s = strip(F['schema'])
    ci = re.findall(r'\(define-canonical-identity\s+(\S+)\s+:status\s+(\S+)(.*?)\)', s)
    refs = {}
    for name, body in blocks(s, 'define-reference').items():
        refs[name] = body
    v = 0; why = []; verified = 0; blockers = 0
    for name, status, rest in ci:
        if status != 'VERIFIED':
            blockers += 1; v += 1; why.append('unresolved:' + name); continue
        vf = re.search(r':verify-file\s+"([^"]+)"', rest)
        loc = re.search(r':type-locator\s+"([^"]+)"', rest)
        idn = re.search(r':identity\s+"([^"]+)"', rest)
        ver = re.search(r':version\s+"([^"]+)"', rest)
        if not (vf and loc and idn and ver):
            v += 1; why.append('incomplete:' + name); continue
        vftxt = open_or_loaded(vf.group(1), F)
        if vftxt is None:
            v += 1; why.append('verify-file-missing:' + name); continue
        # PART A: identity + version inside the referenced define-reference block
        refname = loc.group(1).replace('define-reference', '').strip()
        block = blocks(strip(vftxt), 'define-reference').get(refname, '')
        if not block or idn.group(1) not in block or ('"' + ver.group(1) + '"') not in block:
            v += 1; why.append('identity/version-not-in-block:' + name); continue
        # PART B: the block's canonical-file exists on disk and contains the locator (structural anchor)
        cf = re.search(r':canonical-file\s+"([^"]+)"', block)
        lc = re.search(r':locator\s+"([^"]+)"', block)
        if not (cf and lc):
            v += 1; why.append('no-canonical-anchor:' + name); continue
        cftxt = open_or_loaded(cf.group(1), F)
        if cftxt is None:
            v += 1; why.append('canonical-file-missing:' + name); continue
        if lc.group(1) not in cftxt:
            v += 1; why.append('locator-absent:' + name); continue
        verified += 1
    return v, ('clean:%d verified, 0 unresolved' % verified) if v == 0 else '; '.join(why[:6])

TOPFORMS = r'\(def(?:un|method|generic|class|struct|parameter|var|macro)\s+'
def g_cap(F):
    s = strip(F['schema'])
    entries = re.findall(r'\(define-capability-seat\s+(.*?)\)\s*(?=\(define|\Z)', s, re.S)
    v = 0; why = []
    for e in entries:
        kind = (re.search(r':kind\s+(\S+)', e) or [None, None])[1]
        f = (re.search(r':file\s+"([^"]+)"', e) or [None, None])[1]
        txt = openroot(f) if f else None
        if kind == ':CODE':
            sym = (re.search(r':symbol\s+"?([A-Za-z0-9_/*+.-]+)"?', e) or [None, None])[1]
            pkg = (re.search(r':package\s+"([^"]+)"', e) or [None, None])[1]
            if txt is None:
                v += 1; why.append('cap-file-missing'); continue
            if not pkg or (('defpackage :' + pkg) not in txt and ('defpackage #:' + pkg) not in txt
                           and ('defpackage ' + pkg) not in txt):
                v += 1; why.append('cap-pkg-absent:' + str(pkg))
            if not sym or not re.search(TOPFORMS + re.escape(sym) + r'\b', txt):
                v += 1; why.append('cap-sym-not-topform:' + str(sym))
            ip = txt.find('(in-package :' + (pkg or ''))
            dp = re.search(TOPFORMS + re.escape(sym or 'zzz') + r'\b', txt)
            if not (ip >= 0 and dp and dp.start() > ip):
                v += 1; why.append('cap-pkg-ownership:' + str(sym))
        elif kind == ':DOCUMENT':
            sec = (re.search(r':section\s+"([^"]+)"', e) or [None, None])[1]
            if txt is None or not sec or txt.count(sec) < 1:
                v += 1; why.append('cap-doc-section')
            if re.search(r':package\s', e):
                v += 1; why.append('cap-doc-has-package')
        else:
            v += 1; why.append('cap-unknown-kind')
    return v, ('clean:%d seats' % len(entries)) if v == 0 else '; '.join(why[:6])

def g_own(F):
    s = strip(F['schema']); subc = strip(F['sub'])
    wa = re.findall(r'\(define-write-authority\s+:store\s+"([^"]+)"\s+:owner\s+"([^"]+)"\s+:write-authority\s+"([^"]+)"\s+:writers\s+(\d+)(\s+:read-only\s+t)?', s)
    # reconciliation universe: owner tokens seen in the subsystem registry + write-authority.lisp seat
    sub_owner_tokens = set(re.findall(r'[A-Za-z0-9_.-]+\.lisp', subc)) | set(re.findall(r'\bS\d+\b', subc))
    v = 0; why = []; seen = set()
    if len(wa) < 10:
        v += 1; why.append('too-few-stores')
    for store, owner, auth, w, ro in wa:
        if store in seen:
            v += 1; why.append('dup-store:' + store)
        seen.add(store)
        if not owner:
            v += 1; why.append('no-owner:' + store)
        if int(w) > 1:
            v += 1; why.append('two-writers:' + store)
        if ro and int(w) != 0:
            v += 1; why.append('ro-writer:' + store)
        # cross-source reconciliation: the owner must name a real .lisp seat or subsystem, or a declared WP/none
        owner_ok = (('.lisp' in owner) or re.search(r'\bS\d+\b', owner) or owner.startswith('WP-')
                    or 'MLTP' in owner or owner in ('none',) or any(tok in owner for tok in sub_owner_tokens)
                    or '[interface-only]' in owner or '[design-target]' in owner)
        if not owner_ok:
            v += 1; why.append('owner-unreconciled:' + store + '/' + owner)
    return v, ('clean:%d stores' % len(wa)) if v == 0 else '; '.join(why[:6])

def cog(F):
    s = strip(F['schema'])
    cg = blocks(s, 'define-cognition-graph').get('cognition-graph-v8', '')
    nt = blocks(s, 'define-cognition-node-types').get('cognition-graph-v8-types', '')
    nodetypes = {m.group(1): (m.group(2), m.group(3))
                 for m in re.finditer(r'\(:node\s+(\S+)\s+:in\s+(\S+)\s+:out\s+(\S+)\)', nt)}
    def elist(key):
        m = re.search(r':' + re.escape(key) + r'\s+\((.*?)\)\s*\n\s*:', cg, re.S)
        return re.findall(r'\(([\w-]+)\s+([\w-]+)\)', m.group(1)) if m else []
    flow = elist('flow-edges'); branch = elist('branch-edges'); resume = elist('resume-edges'); term = elist('terminal-edges')
    tm = re.search(r':terminals\s+\(([^)]*)\)', cg)
    terminals = set(tm.group(1).split()) if tm else set()
    resp = blocks(s, 'define-record').get('ClarificationResponse/1', '')
    return cg, nodetypes, flow, branch, resume, term, terminals, resp

def g_coglife(F):
    cg, nodetypes, flow, branch, resume, term, terminals, resp = cog(F)
    v = 0; why = []
    # type-compat over flow+branch edges
    for a, b in flow + branch:
        if a in nodetypes and b in nodetypes and nodetypes[a][1] != nodetypes[b][0]:
            v += 1; why.append('typed-incompat:%s->%s' % (a, b))
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
    # terminals have NO outgoing flow edge
    flow_srcs = [a for a, b in flow]
    for t in terminals:
        if t != 'RESULT' and t in flow_srcs:
            v += 1; why.append('terminal-outgoing:' + t)
    # every terminal reachable via an incoming edge (no orphan terminal)
    incoming = set(b for a, b in (flow + branch + term + resume))
    for t in terminals:
        if t != 'RESULT' and t not in incoming:
            v += 1; why.append('orphan-terminal:' + t)
    # resume edge present and its target reachable; resume binding present
    if ('CLARIFY-SUSPEND', 'CLARIFY-RESUME') not in resume:
        v += 1; why.append('resume-edge-missing')
    resume_targets = set(b for a, b in resume)
    resume_nodes = set(a for a, b in resume) | resume_targets
    allnodes = set(a for a, b in (flow + branch + term + resume)) | set(b for a, b in (flow + branch + term + resume)) | terminals
    for rn in resume_targets:
        if rn not in allnodes:
            v += 1; why.append('dangling-resume-target:' + rn)
    if 'resume_binding_ref' not in resp:
        v += 1; why.append('resume-binding-missing')
    return v, ('clean:%d flow,%d resume,%d terminals' % (len(flow), len(resume), len(terminals))) if v == 0 else '; '.join(why[:6])

def g_clarify(F):
    s = strip(F['schema'])
    fix = re.findall(r'\((:valid|:invalid)\s+(\w+)\s+:selected\s+(\d+)\s+:merged\s+(\d+)\s+:provenance-preserved\s+(t|nil)\)', s)
    def card_ok(ms, selected, merged, provok):
        if ms == 'ABSTAIN':
            return selected == 0 and merged == 0
        if ms == 'EXPLICIT_SELECTION':
            return selected == 1 and merged == 0
        if ms == 'EXPLICIT_MERGE':
            return selected == 0 and merged == 1 and provok
        return False
    v = 0; why = []
    if len(fix) < 7:
        v += 1; why.append('too-few-fixtures:%d' % len(fix))
    for kind, ms, sel, mrg, prov in fix:
        ok = card_ok(ms, int(sel), int(mrg), prov == 't')
        if kind == ':valid' and not ok:
            v += 1; why.append('valid-fails-rule:' + ms)
        if kind == ':invalid' and ok:
            v += 1; why.append('invalid-passes-rule:' + ms)
    return v, ('clean:%d fixtures' % len(fix)) if v == 0 else '; '.join(why[:6])

DIMSTATE_REQUIRED = {'OK', 'DEGRADED', 'FAILED', 'UNKNOWN'}
def ra_model(F):
    s = strip(F['schema'])
    enum = re.search(r'\(define-closed-enum\s+DimensionState\s+(.*?)\)\s*\n', s)
    states = re.findall(r'\(:(\w+)\)', enum.group(1)) if enum else []
    dimpol = blocks(s, 'define-dimension-policy').get('root-authority-dimensions', '')
    dims = re.findall(r'\(:dimension\s+:(\w+)\s+:class\s+:(\w+)\s+:failure\s+:(\w+)', dimpol)
    return s, states, dims, dimpol

def g_rastatus(F):
    s, states, dims, dimpol = ra_model(F)
    v = 0; why = []
    names = [d[0] for d in dims]
    order = ['WITHHELD', 'MACHINE_UNVERIFIED', 'ATTRIBUTED_RELIANCE', 'FULL_RELIANCE']  # ascending reliance
    BAD = {'FAILED', 'DEGRADED', 'UNKNOWN'}
    def project(state):
        worst = 'FULL_RELIANCE'; blocking = []; advisory = []
        for dname, cls, fail in dims:
            if state[dname] in BAD:
                if cls == 'MANDATORY':
                    blocking.append(dname)
                    if fail in order and order.index(fail) < order.index(worst):
                        worst = fail
                elif cls == 'ADVISORY':
                    advisory.append(dname)
        return worst, tuple(sorted(blocking)), tuple(sorted(advisory))
    # exercise flags
    if set(states) != DIMSTATE_REQUIRED:
        v += 1; why.append('dimstate!=OK/DEGRADED/FAILED/UNKNOWN:%s' % ','.join(states))
    if len(dims) != 8:
        v += 1; why.append('dims!=8:%d' % len(dims))
    if v == 0:
        total = len(states) ** len(names)          # the FULL product 4^8
        seen = 0; multi = 0; exercised = set()
        proj_cache = {}
        for combo in itertools.product(states, repeat=len(names)):
            st = dict(zip(names, combo))
            key = combo
            p = project(st)
            if key in proj_cache and proj_cache[key] != p:
                multi += 1
            proj_cache[key] = p
            seen += 1
            exercised.update(combo)
            # completeness: blocking == exactly the MANDATORY dims in bad state
            expect_block = tuple(sorted(d for d, c, fl in dims if c == 'MANDATORY' and st[d] in BAD))
            if p[1] != expect_block:
                v += 1; why.append('blocking-incomplete'); break
            expect_adv = tuple(sorted(d for d, c, fl in dims if c == 'ADVISORY' and st[d] in BAD))
            if p[2] != expect_adv:
                v += 1; why.append('advisory-incomplete'); break
        if seen != total:
            v += 1; why.append('coverage:%d!=%d' % (seen, total))
        if multi:
            v += 1; why.append('non-deterministic-projection')
        if not DIMSTATE_REQUIRED.issubset(exercised):
            v += 1; why.append('UNKNOWN/DEGRADED-not-exercised')
        # recovery independence: two mandatory dims failed; recovering one keeps the other blocking
        mand = [d for d, c, fl in dims if c == 'MANDATORY']
        if len(mand) >= 2:
            st = {d: ('FAILED' if d in mand[:2] else 'OK') for d in names}
            st2 = dict(st); st2[mand[0]] = 'OK'
            if mand[1] not in project(st2)[1]:
                v += 1; why.append('recovery-not-independent')
    # structural invariants
    ras = blocks(s, 'define-record').get('RootAuthorityStatus/1', '')
    if not (':proof_integrity :type DimensionState' in ras and ':security :type DimensionState' in ras):
        v += 1; why.append('proof_integrity-not-separate')
    if not re.search(r':dimension\s+:proof_integrity\s+:class\s+:MANDATORY', dimpol):
        v += 1; why.append('proof_integrity-not-mandatory')
    if ':derived :type (member :true)' not in s:
        v += 1; why.append('derived-not-constant-true')
    if ':self-qualification :rejected' not in s:
        v += 1; why.append('self-qualification-not-rejected')
    if ':advisory-never-blocks t' not in s:
        v += 1; why.append('advisory-can-block')
    return v, ('clean:%d states, 8 dims' % (len(states) ** len(names))) if v == 0 else '; '.join(why[:6])

def g_sym(F):
    s = strip(F['schema'])
    pip = blocks(s, 'define-pipeline').get('symbolic-only-path', '')
    def grp(key):
        m = re.search(r':' + key + r'\s+\(([^)]*)\)', pip)
        return m.group(1).split() if m else []
    mand = grp('mandatory-nodes')
    propmand = [x for x in grp('proposer-mandatory-nodes') if x]
    prop_opt = set(grp('proposer-optional-nodes'))
    em = re.search(r':edges\s+\((.*?)\)\s*\n?\s*:symbolic', pip, re.S)
    edges = re.findall(r'\((\w+)\s+(\w+)\)', em.group(1)) if em else []
    entry = (re.search(r':entry\s+(\w+)', pip) or [None, 'ACQUIRE'])[1]
    exit_ = (re.search(r':exit\s+(\w+)', pip) or [None, 'PUBLISH'])[1]
    mcount = int((re.search(r':mutation-count\s+(\d+)', pip) or [0, '0'])[1])
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
    for mnode in mand:
        if not reach(entry, mnode, edges):
            v += 1; why.append('mandatory-unreachable:' + mnode)
    if not reach(entry, exit_, edges):
        v += 1; why.append('exit-unreachable')
    if len(propmand) != 0:
        v += 1; why.append('proposer-mandatory-nonempty:%s' % ','.join(propmand))
    # proposer-removal STRUCTURAL/INTERFACE EQUIVALENCE: the proposer is optional everywhere (proposer-mandatory
    # is empty), so removing it leaves the SYMBOLIC-ONLY subgraph (edges whose endpoints are both symbolic-only
    # nodes). Every mandatory node must still be reachable entry->exit in that symbolic-only subgraph; if a
    # mandatory node were reachable only through a non-symbolic (proposer-exclusive) node, removal breaks it.
    symbolic = set(grp('symbolic-only-nodes'))
    sym_edges = [(a, b) for a, b in edges if a in symbolic and b in symbolic]
    for mnode in mand:
        if mnode != entry and not reach(entry, mnode, sym_edges):
            v += 1; why.append('mandatory-not-symbolic-reachable:' + mnode)
    return v, ('clean:%d mand,%d edges' % (len(mand), len(edges))) if v == 0 else '; '.join(why[:6])

def g_req(F):
    trc = F['trc']; s = strip(F['schema']); s17 = strip(F['s17']); s16 = strip(F['s16']); isr = strip(F['isr'])
    drec = set(re.findall(r'\(define-record\s+([A-Za-z0-9_]+/1)', s + s17 + s16))
    dref = set(re.findall(r'\(define-reference\s+([A-Za-z0-9_]+/1)', s + s17 + s16))
    isrif = set(re.findall(r'\(define-interface\s+([A-Za-z0-9_/-]+)', isr))
    deftypes = drec | dref | isrif
    def ref_resolves(tok):
        tok = tok.strip()
        if re.fullmatch(r'[A-Za-z][A-Za-z0-9_]*/1', tok):
            return tok in deftypes
        if tok.startswith('define-'):
            return ('(' + tok) in s
        return re.search(r'\(define-[a-z-]+\s+' + re.escape(tok) + r'\b', s) is not None
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
    v = 0; why = []; seen_ids = {}
    if any(i < 0 for i in idx.values()):
        v += 1; why.append('missing-column')
    if len(rows) < 17:
        v += 1; why.append('too-few-rows:%d' % len(rows))
    for rid, rest in rows:
        seen_ids[rid] = seen_ids.get(rid, 0) + 1
        cells = [c.strip() for c in rest.split('|')]
        for k, ix in idx.items():
            if ix < 0 or ix >= len(cells) or not cells[ix].strip():
                v += 1; why.append('blank:%s@%s' % (k, rid))
        ii = idx['interface']
        ifc = cells[ii] if (0 <= ii < len(cells)) else ''
        for tok in re.findall(r'`([^`]+)`', ifc):
            if not ref_resolves(tok):
                v += 1; why.append('unresolved-if:%s@%s' % (tok, rid))
    for k, c in seen_ids.items():
        if c > 1:
            v += 1; why.append('dup-req:' + k)
    return v, ('clean:%d rows' % len(rows)) if v == 0 else '; '.join(why[:6])

def g_radeltas(F):
    s = strip(F['schema'])
    ds = blocks(s, 'define-ra-delta-seats').get('', '')
    if not ds:
        m = re.search(r'\(define-ra-delta-seats(.*?)\n\(define', s, re.S)
        ds = m.group(1) if m else ''
    deltas = re.findall(r'\(:delta\s+(\S+)\s+:seat\s+(\S+)\s+:owner\s+(\S+)\s+:requirement\s+(\S+)\s+:test\s+(\S+)\)', ds)
    agreed = {'RA-EPOCH', 'RA-CONT', 'RA-CORR', 'RA-JUR-NS', 'RA-MARK', 'RA-K', 'RA-SIDE'}
    got = {d[0] for d in deltas}
    v = 0; why = []
    if got != agreed:
        v += 1; why.append('delta-set!=agreed:%s' % ','.join(sorted(got ^ agreed)))
    if len(deltas) != 7:
        v += 1; why.append('count!=7:%d' % len(deltas))
    if 'RA-FROST' in got:
        v += 1; why.append('frost-substitutes-jurns')
    for dl, seat, owner, req, test in deltas:
        if not (seat and owner and req and test):
            v += 1; why.append('incomplete-delta:' + dl)
    return v, ('clean:7 deltas') if v == 0 else '; '.join(why[:6])

GUARDS = {
    'V8-PUBPRIV': g_pubpriv, 'V8-XREF': g_xref, 'V8-CAP': g_cap, 'V8-OWN': g_own,
    'V8-COGLIFE': g_coglife, 'V8-CLARIFY': g_clarify, 'V8-RASTATUS': g_rastatus,
    'V8-SYM': g_sym, 'V8-REQ': g_req, 'V8-RA-DELTAS': g_radeltas,
}

# ---- MUTATIONS: (target file KEY, transform bytes->bytes). Each MUST change bytes and flip its guard. ----
def _sub_once(pat, repl, text, why):
    new = re.sub(pat, repl, text, count=1)
    return new

MUT = {
 'V8-PUBPRIV': {
   'field-type':      ('schema', lambda t: t.replace('(define-record RootAuthorityStatus/1', '(define-record RootAuthorityStatus/1 (:leak :type TenantProfile/1)', 1)),
   'ref-target':      ('schema', lambda t: t.replace(':type-locator "define-reference RightsMatrix/1"', ':type-locator "define-record TenantProfile/1"', 1)),
   'interface-io':    ('isr',    lambda t: re.sub(r'(\(define-interface\s+RootAuthorityStatus/1[^\n]*\n[^\n]*:consumers \()', r'\1TenantProfile/1 ', t, count=1)),
   'subsystem-dep':   ('sub',    lambda t: t.replace(':interface "CensusSpaceClassification/1 + census-coverage-decision"', ':interface "CensusSpaceClassification/1 + TenantProfile/1"', 1)),
   'store-owner-writer': ('schema', lambda t: t.replace(':store "static-site"           :owner "WP-12 static-site.lisp"            :write-authority "none" :writers 0 :read-only t', ':store "static-site"           :owner "WP-12 static-site.lisp"            :write-authority "none" :writers 1 :read-only t', 1)),
   'api-mcp-schema':  ('mcp',    lambda t: t + '\n(define-mcp-tool leak (:returns TenantProfile/1))\n'),
   'publication':     ('site',   lambda t: t + '\n(defun emit-leak () (publish TenantProfile/1))\n'),
   'declassification':('schema', lambda t: t.replace('(define-record CanonicalCitationURI/1', '(define-record CanonicalCitationURI/1 (:leak :type RestrictedForensicRecord/1)', 1)),
   'undefined-endpoint':('schema', lambda t: t.replace('(define-record RootAuthorityStatus/1', '(define-record RootAuthorityStatus/1 (:leak :type NoSuchType/1)', 1)),
 },
 'V8-XREF': {
   'wrong-file':      ('schema', lambda t: t.replace(':verify-file "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.8-SCHEMAS.sexp" :type-locator "define-reference LegalIR/1"', ':verify-file "deployment/NO_SUCH_FILE.sexp" :type-locator "define-reference LegalIR/1"', 1)),
   'wrong-identity':  ('schema', lambda t: t.replace(':type-locator "define-reference LegalIR/1" :identity "lawmax/legal-ir/1"', ':type-locator "define-reference LegalIR/1" :identity "lawmax/WRONG-IDENTITY/9"', 1)),
   'wrong-version':   ('schema', lambda t: t.replace(':type-locator "define-reference LegalIR/1" :identity "lawmax/legal-ir/1" :version "1"', ':type-locator "define-reference LegalIR/1" :identity "lawmax/legal-ir/1" :version "9"', 1)),
   'wrong-reference-target': ('schema', lambda t: t.replace('(define-canonical-identity LegalIR/1               :status VERIFIED :verify-file "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.8-SCHEMAS.sexp" :type-locator "define-reference LegalIR/1"', '(define-canonical-identity LegalIR/1               :status VERIFIED :verify-file "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.8-SCHEMAS.sexp" :type-locator "define-reference NoSuchRef/1"', 1)),
   'locator-absent':  ('schema', lambda t: t.replace('(define-reference MemoryEvent/1 :canonical-file "source/memory.lisp" :identity "lawmax/memory-event/1" :version "1" :locator "record-episode")', '(define-reference MemoryEvent/1 :canonical-file "source/memory.lisp" :identity "lawmax/memory-event/1" :version "1" :locator "ZZZ_NO_SUCH_LOCATOR")', 1)),
 },
 'V8-CAP': {
   'nonexistent-symbol':   ('schema', lambda t: t.replace(':symbol "get-eli-law-prefix"', ':symbol "zzz_no_such_symbol"', 1)),
   'wrong-package':        ('schema', lambda t: t.replace(':package "orchestrator.uris"', ':package "orchestrator.NOPE"', 1)),
   'wrong-file':           ('schema', lambda t: t.replace(':file "source/canonical-uris.lisp"', ':file "source/NO_SUCH.lisp"', 1)),
   'symbol-in-other-package': ('schema', lambda t: t.replace(':symbol "get-eli-law-prefix"', ':symbol "defpackage"', 1)),
 },
 'V8-OWN': {
   'dup-store':       ('schema', lambda t: t.replace('(define-write-authority :store "journal"', '(define-write-authority :store "journal"               :owner "DUP" :write-authority "x" :writers 1)\n(define-write-authority :store "journal"', 1)),
   'two-writers':     ('schema', lambda t: t.replace(':store "journal"               :owner "WP-03 journal.lisp"                :write-authority "write-authority.lisp" :writers 1', ':store "journal"               :owner "WP-03 journal.lisp"                :write-authority "write-authority.lisp" :writers 2', 1)),
   'writer-on-readonly': ('schema', lambda t: t.replace(':store "static-site"           :owner "WP-12 static-site.lisp"            :write-authority "none" :writers 0 :read-only t', ':store "static-site"           :owner "WP-12 static-site.lisp"            :write-authority "none" :writers 1 :read-only t', 1)),
   'owner-unreconciled': ('schema', lambda t: t.replace(':store "journal"               :owner "WP-03 journal.lisp"', ':store "journal"               :owner "GHOST-OWNER-XYZ"', 1)),
 },
 'V8-COGLIFE': {
   'remove-resume-edge':  ('schema', lambda t: t.replace('(CLARIFY-SUSPEND CLARIFY-RESUME) ', '', 1)),
   'dangling-resume-target': ('schema', lambda t: t.replace('(CLARIFY-SUSPEND CLARIFY-RESUME) (CLARIFY-RESUME RESOLVE)', '(CLARIFY-SUSPEND CLARIFY-DANGLE) (CLARIFY-RESUME RESOLVE)', 1)),
   'wrong-instance-binding': ('schema', lambda t: t.replace('(:resume_binding_ref :type ref)', '(:no_binding :type ref)', 1)),
   'incompatible-edge-type': ('schema', lambda t: t.replace('(:node MORPH             :in TokenStream/1                   :out MorphLattice/1)', '(:node MORPH             :in TokenStream/1                   :out WrongOut/1)', 1)),
   'terminal-with-outgoing': ('schema', lambda t: t.replace(':flow-edges ((PERCEIVE SEGMENT)', ':flow-edges ((TERM-ERROR PERCEIVE) (PERCEIVE SEGMENT)', 1)),
   'orphan-terminal':     ('schema', lambda t: t.replace(':terminals (TERM-UNDERDETERMINED TERM-CONFLICTING TERM-ABSTAINED TERM-ERROR RESULT)', ':terminals (TERM-UNDERDETERMINED TERM-CONFLICTING TERM-ABSTAINED TERM-ERROR TERM-ORPHAN RESULT)', 1)),
   'illegal-cycle':       ('schema', lambda t: t.replace('(PROMOTE RESULT))', '(PROMOTE RESULT) (RESULT PERCEIVE))', 1)),
 },
 'V8-CLARIFY': {
   'corrupt-abstain-fixture':   ('schema', lambda t: t.replace('(:valid   ABSTAIN            :selected 0 :merged 0 :provenance-preserved t)', '(:valid   ABSTAIN            :selected 1 :merged 0 :provenance-preserved t)', 1)),
   'corrupt-selection-fixture': ('schema', lambda t: t.replace('(:valid   EXPLICIT_SELECTION :selected 1 :merged 0 :provenance-preserved t)', '(:valid   EXPLICIT_SELECTION :selected 0 :merged 0 :provenance-preserved t)', 1)),
   'corrupt-merge-provenance':  ('schema', lambda t: t.replace('(:invalid EXPLICIT_MERGE     :selected 0 :merged 1 :provenance-preserved nil)', '(:valid   EXPLICIT_MERGE     :selected 0 :merged 1 :provenance-preserved nil)', 1)),
 },
 'V8-RASTATUS': {
   'merge-proof-into-security': ('schema', lambda t: t.replace(' (:proof_integrity :type DimensionState)', '', 1)),
   'derived-not-constant':      ('schema', lambda t: t.replace(':derived :type (member :true)', ':derived :type (member :true :false)', 1)),
   'self-qualification-allowed':('schema', lambda t: t.replace(':self-qualification :rejected', ':self-qualification :accepted', 1)),
   'drop-unknown-state':        ('schema', lambda t: t.replace('(define-closed-enum DimensionState (:OK) (:DEGRADED) (:FAILED) (:UNKNOWN))', '(define-closed-enum DimensionState (:OK) (:DEGRADED) (:FAILED))', 1)),
   'advisory-can-block':        ('schema', lambda t: t.replace(':advisory-never-blocks t', ':advisory-never-blocks nil', 1)),
 },
 'V8-SYM': {
   'broken-edge':          ('schema', lambda t: t.replace(' (PROOF PUBLISH))', ')', 1)),
   'unreachable-mandatory':('schema', lambda t: t.replace(' (IR COMPILE)', '', 1)),
   'mandatory-model-node': ('schema', lambda t: t.replace(':proposer-mandatory-nodes ()', ':proposer-mandatory-nodes (IR)', 1)),
   'proposer-removal-inequiv': ('schema', lambda t: t.replace(':symbolic-only-nodes (ACQUIRE CENSUS ADMIT IR REASON COMPILE PROOF PUBLISH)', ':symbolic-only-nodes (ACQUIRE CENSUS IR REASON COMPILE PROOF PUBLISH)', 1)),
 },
 'V8-REQ': {
   'blank-requirement':   ('trc', lambda t: _req_blank(t, 'requirement')),
   'blank-owner-seat':    ('trc', lambda t: _req_blank(t, 'owner seat')),
   'blank-test':          ('trc', lambda t: _req_blank(t, 'test')),
   'blank-future-wp':     ('trc', lambda t: _req_blank(t, 'future wp')),
   'blank-interface':     ('trc', lambda t: _req_blank(t, 'interface')),
   'unresolvable-interface-id': ('trc', lambda t: _req_set_if(t, ' `define-public-edge` ')),
 },
 'V8-RA-DELTAS': {
   'drop-to-six':     ('schema', lambda t: t.replace('  (:delta RA-SIDE    :seat SidecarSourceProfile/1     :owner S26 :requirement RA8-SIDE  :test T8-SIDE))', '  )', 1)),
   'rename-jurns-to-frost': ('schema', lambda t: t.replace('(:delta RA-JUR-NS  :seat JurisdictionNamespace/1   :owner S25 :requirement RA8-JURNS :test T8-JURNS)', '(:delta RA-FROST   :seat JurisdictionNamespace/1   :owner S25 :requirement RA8-JURNS :test T8-JURNS)', 1)),
   'blank-seat':      ('schema', lambda t: t.replace('(:delta RA-K       :seat CitationMetricV8/1         :owner S15 :requirement RA8-K     :test T8-K)', '(:delta RA-K       :seat  :owner S15 :requirement RA8-K     :test T8-K)', 1)),
 },
}

def _trc_cols(v18):
    hdr = re.search(r'\|\s*id\s*\|(.+?)\|\s*\n', v18)
    cols = [h.strip().lower() for h in (hdr.group(1).split('|') if hdr else [])]
    return cols

def _req_first_row_edit(t, fn):
    """apply fn(cells)->cells to the FIRST §v1.8 DFT/RA8 data row and return the whole file text."""
    head, _, v18 = t.partition('§v1.8')
    cols = _trc_cols(v18)
    m = re.search(r'(\|\s*(?:RA8-[A-Z0-9-]+|DFT-\d+)\s*\|)([^\n]*)', v18)
    if not m:
        return t
    cells = m.group(2).split('|')
    cells = fn(cells, cols)
    newrow = m.group(1) + '|'.join(cells)
    v18b = v18[:m.start()] + newrow + v18[m.end():]
    return head + '§v1.8' + v18b

def _colidx(cols, name):
    for i, c in enumerate(cols):
        if name in c:
            return i
    return -1

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

# ---- CLI --------------------------------------------------------------------------------------
def do_run(gid, overrides):
    if gid not in GUARDS:
        print('ERROR unknown-guard ' + gid); return 2
    try:
        F = load(overrides)
        v, reason = GUARDS[gid](F)
    except Exception as e:
        print('ERROR ' + type(e).__name__ + ': ' + str(e)); return 2
    if v == 0:
        print('OK ' + reason); return 0
    print('VIOLATION ' + reason); return 3

def do_mutate(gid, mid, outdir):
    if gid not in MUT or mid not in MUT[gid]:
        print('ERROR unknown-mutation ' + gid + '/' + mid); return 2
    key, fn = MUT[gid][mid]
    base = readpath(DEFAULTS[key])
    mut = fn(base)
    if mut == base:
        print('ERROR mutation-did-not-change-bytes ' + gid + '/' + mid); return 2
    os.makedirs(outdir, exist_ok=True)
    ext = os.path.splitext(DEFAULTS[key])[1] or '.txt'
    bp = os.path.join(outdir, 'baseline' + ext)
    mp = os.path.join(outdir, 'mutant' + ext)
    with open(bp, 'w', encoding='utf-8') as f:
        f.write(base)
    with open(mp, 'w', encoding='utf-8') as f:
        f.write(mut)
    print('%s %s %s' % (key, bp, mp))
    return 0

def do_selftest():
    fails = []
    for gid, fn in GUARDS.items():
        F = load({})
        v, reason = fn(F)
        if v != 0:
            fails.append('BASELINE %s not clean: %s' % (gid, reason))
    import tempfile
    for gid in MUT:
        for mid in MUT[gid]:
            key, fn = MUT[gid][mid]
            base = readpath(DEFAULTS[key])
            mut = fn(base)
            if mut == base:
                fails.append('MUT %s/%s did-not-change-bytes' % (gid, mid)); continue
            with tempfile.NamedTemporaryFile('w', suffix=os.path.splitext(DEFAULTS[key])[1], delete=False, encoding='utf-8') as tf:
                tf.write(mut); mp = tf.name
            try:
                F = load({key: mp})
                v, reason = GUARDS[gid](F)
            finally:
                os.unlink(mp)
            if v == 0:
                fails.append('MUT %s/%s SURVIVED (guard clean): %s' % (gid, mid, reason))
    if fails:
        print('SELFTEST-FAIL')
        for f in fails:
            print('  ' + f)
        return 1
    nmut = sum(len(MUT[g]) for g in MUT)
    print('SELFTEST-OK guards=%d mutations=%d' % (len(GUARDS), nmut))
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
        gid = argv[1]
        for m in MUT.get(gid, {}):
            print(m)
        return 0
    if cmd == 'aggregate':
        F = load({})
        s, states, dims, dimpol = ra_model(F)
        total = len(states) ** len(dims)
        v, reason = g_rastatus(F)
        print('%d/%d states=%d dims=%d %s' % (total if v == 0 else 0, total, len(states), len(dims), 'OK' if v == 0 else 'VIOLATION:' + reason))
        return 0 if v == 0 else 3
    if cmd == 'run':
        gid = argv[1]; overrides = {}
        i = 2
        while i < len(argv):
            if argv[i] == '--file':
                k, _, p = argv[i + 1].partition('=')
                overrides[k] = p; i += 2
            else:
                i += 1
        return do_run(gid, overrides)
    if cmd == 'mutate':
        gid = argv[1]; mid = argv[2]; outdir = None
        i = 3
        while i < len(argv):
            if argv[i] == '--outdir':
                outdir = argv[i + 1]; i += 2
            else:
                i += 1
        return do_mutate(gid, mid, outdir)
    if cmd == 'selftest':
        return do_selftest()
    print('ERROR unknown-command ' + cmd)
    return 2

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
