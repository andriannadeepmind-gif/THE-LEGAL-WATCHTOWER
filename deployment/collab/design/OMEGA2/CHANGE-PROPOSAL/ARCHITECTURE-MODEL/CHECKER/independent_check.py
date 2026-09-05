#!/usr/bin/env python3
"""INDEPENDENT second verification path.

Independence is defined against the Common Lisp kernel: this path shares NO parsing code and NO
invariant-evaluation code with it. The invariants are derived by clingo (a stock ASP/Datalog-family solver) from
a declarative encoding, and the model is read by the reader in THIS file.

Review-2 §3.3 — WHY THIS FILE CARRIES ITS OWN READER. Ordinary Python consumers of canonical `.sexp` data use the
one classified reader seat, SEXP-READER.py; that is what makes "one reader seat" true of the governance tooling.
This program is the deliberate exception, and the exception is the point: a second verification path that imported
the first path's reader would inherit every one of its bugs and could not contradict it. The reader below is a
separate implementation — a table-driven scanner rather than a recursive-descent one — written to the same WRITTEN
SPECIFICATION (MODEL-SCHEMA.sexp and the canonical value/fact rendering it defines). Sharing a specification is
what makes two implementations comparable; sharing code is what makes them one implementation with two names.

What this path establishes, in order, failing closed at the first step it cannot complete:
  1. its SHA-256 engine (hashlib/OpenSSL) reproduces the FIPS 180-4 known-answer vectors;
  2. ROOT.sexp is the sole module universe AND is held to the full structural discipline of Review-2 N-9 —
     exactly one top-level form, no duplicate plist key, a schema version that must equal the schema's own, a
     well-formed parent commit; every pinned module is hashed over RAW BYTES and compared to its pin; no
     undeclared *.sexp exists beside them; and the model-root digest is RECOMPUTED from the ordered pins;
  3. every ROOT-pinned module is read completely; every top-level form is a fact or a declared header; the CLOSED
     FIELD SET, declared value kinds, id-spaces, conditional field rules and uniqueness laws of the schema are
     enforced; duplicate seats and duplicate keys are detected before anything is folded into a dictionary;
  4. its fact-set commitment (total, per-module and per-family counts and digests) is byte-identical to the
     kernel's commitment — a PASS is not issued, and verdicts are not compared, if the two universes differ;
  5. the model laws are derived by clingo and reported as typed violations.
"""
import argparse, hashlib, json, os, sys

import clingo

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHECKER_VERSION = 'independent_check.py/3 (clingo %s, hashlib/%s)' % (clingo.__version__, hashlib.sha256(b'').name)
HEADERS = ('define-model-schema', 'define-model-root')
FIPS = {'': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        'abc': 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
        'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq':
            '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1'}
MILLION_A = 'cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0'
TOKEN_CHARS = set('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.+/-')


def die(code, *lines):
    for l in lines:
        print(l)
    print('; (independent ASP check of objective invariants only — NOT semantic/legal/security proof)')
    sys.exit(code)


# ══════════════════════════════════════════════════════════ this path's own reader (no shared code)
class Atom:
    """A read token: kind is 'sym', 'str', 'int' or 'kw'. Kept typed so nothing is guessed later."""
    __slots__ = ('kind', 'text')

    def __init__(self, kind, text):
        self.kind, self.text = kind, text

    def __repr__(self):
        return '%s(%r)' % (self.kind, self.text)


class ReadError(Exception):
    pass


def scan(text, src):
    """Table-driven scan of TEXT into a flat token stream. Comments and whitespace are consumed here so the
    assembler below never sees them; '(' and ')' are emitted as bare markers."""
    toks, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c in ' \t\r\n\f':
            i += 1
        elif c == ';':
            j = text.find('\n', i)
            i = n if j < 0 else j + 1
        elif c == '#' and i + 1 < n and text[i + 1] == '|':
            depth, j = 1, i + 2
            while j < n and depth:
                if text.startswith('#|', j):
                    depth += 1; j += 2
                elif text.startswith('|#', j):
                    depth -= 1; j += 2
                else:
                    j += 1
            if depth:
                raise ReadError('%s: unterminated block comment' % src)
            i = j
        elif c in '()':
            toks.append(c); i += 1
        elif c == '"':
            j, buf = i + 1, []
            while True:
                if j >= n:
                    raise ReadError('%s: unterminated string' % src)
                if text[j] == '\\':
                    if j + 1 >= n:
                        raise ReadError('%s: unterminated string escape' % src)
                    buf.append(text[j + 1]); j += 2
                elif text[j] == '"':
                    j += 1; break
                else:
                    buf.append(text[j]); j += 1
            toks.append(Atom('str', ''.join(buf))); i = j
        else:
            j = i
            while j < n and text[j] not in ' \t\r\n\f()";':
                j += 1
            word = text[i:j]
            if not word:
                raise ReadError('%s: empty atom' % src)
            if word[0] == ':':
                if len(word) == 1:
                    raise ReadError('%s: empty keyword' % src)
                toks.append(Atom('kw', word[1:]))
            else:
                body = word[1:] if word[0] in '+-' else word
                numericish = word[0].isdigit() or (word[0] in '+-' and len(word) > 1 and word[1].isdigit())
                if numericish and body and body.isdigit():
                    toks.append(Atom('int', word))
                elif numericish:
                    raise ReadError('%s: numeric atom %r is not an integer; the canonical grammar admits '
                                    'integers only' % (src, word))
                elif word[0] not in TOKEN_CHARS or any(ch not in TOKEN_CHARS for ch in word):
                    raise ReadError('%s: symbol %r is outside the canonical grammar' % (src, word))
                else:
                    toks.append(Atom('sym', word))
            i = j
    return toks


def assemble(toks, src):
    """Fold the token stream into nested lists. Reading ends only at end of input: a surplus ')' or an unclosed
    '(' is an error, never a silently dropped remainder."""
    stack, out = [], []
    for t in toks:
        if t == '(':
            stack.append([])
        elif t == ')':
            if not stack:
                raise ReadError('%s: unbalanced closing parenthesis' % src)
            done = stack.pop()
            (stack[-1] if stack else out).append(done)
        else:
            (stack[-1] if stack else out).append(t)
    if stack:
        raise ReadError('%s: unterminated list' % src)
    return out


def read_file(path, what='model file'):
    if not os.path.isfile(path):
        die(3, 'MISSING-MODEL-FILE: %s (%s)' % (path, what))
    with open(path, 'rb') as f:
        raw = f.read()
    try:
        text = raw.decode('utf-8')
    except UnicodeDecodeError as e:
        die(3, 'UNREADABLE-MODEL-FILE: %s is not valid UTF-8 (%s)' % (path, e))
    try:
        return assemble(scan(text, os.path.basename(path)), os.path.basename(path))
    except ReadError as e:
        die(3, 'MODEL-UNREADABLE: %s' % e)


def head(form):
    return form[0].text if isinstance(form, list) and form and isinstance(form[0], Atom) \
        and form[0].kind in ('sym', 'kw') else None


def plist(items, what):
    """:key value pairs. A dangling key or a non-keyword in key position is a typed error, and the DUPLICATE
    KEYS are returned rather than folded away, because a dict here would destroy the very thing L2 must see."""
    out = []
    i = 0
    while i < len(items):
        k = items[i]
        if not isinstance(k, Atom) or k.kind != 'kw':
            raise ReadError('%s: expected a :keyword in key position' % what)
        if i + 1 >= len(items):
            raise ReadError('%s: key :%s has no value' % (what, k.text))
        out.append((k.text, items[i + 1]))
        i += 2
    return out


def render(a, what):
    """The ONE canonical rendering: string -> content, integer -> decimal, symbol -> UPPER-CASE name.

    A control character inside a string is NOT a legal value: the commitment joins rendered fact lines with a
    newline, so a value that may contain one makes two different fact sets renderable to the same bytes. The
    ambiguity is removed from the grammar rather than guarded against downstream.
    """
    if not isinstance(a, Atom) or a.kind == 'kw':
        raise ReadError('%s: illegal value kind (permitted: control-character-free string, integer, plain '
                        'symbol)' % what)
    if a.kind == 'str':
        bad = next((c for c in a.text if ord(c) < 32 or ord(c) == 127), None)
        if bad is not None:
            raise ReadError('%s: control character U+%04X inside a string value; canonical strings are '
                            'control-character free' % (what, ord(bad)))
    return a.text.upper() if a.kind == 'sym' else (str(int(a.text)) if a.kind == 'int' else a.text)


def kind_of(a):
    return {'str': 'STRING', 'int': 'INTEGER', 'sym': 'SYMBOL'}.get(a.kind if isinstance(a, Atom) else '', '?')


# ══════════════════════════════════════════════════════════ hashing (this path's own engine)
def self_test_hash():
    for msg, want in FIPS.items():
        if hashlib.sha256(msg.encode('ascii')).hexdigest() != want:
            die(4, 'TOOLCHAIN-FAILURE: hashlib failed FIPS 180-4 vector %r' % msg,
                'SHA-256 PROVIDER: UNAVAILABLE — no model hash was computed and no verdict is issued.')
    if hashlib.sha256(b'a' * 1000000).hexdigest() != MILLION_A:
        die(4, "TOOLCHAIN-FAILURE: hashlib failed the 1,000,000 x 'a' vector",
            'SHA-256 PROVIDER: UNAVAILABLE — no model hash was computed and no verdict is issued.')


def sha_file(path):
    with open(path, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()


def sha_text(s):
    return hashlib.sha256(s.encode('utf-8')).hexdigest()


# ══════════════════════════════════════════════════════════ schema
def read_schema(dirp):
    forms = read_file(os.path.join(dirp, 'MODEL-SCHEMA.sexp'), 'schema')
    decls = [f for f in forms if head(f) == 'define-model-schema']
    if len(decls) != 1 or len(forms) != 1:
        die(3, 'SCHEMA-MALFORMED: expected exactly one define-model-schema form and nothing else, found %d '
               'declaration(s) among %d top-level form(s)' % (len(decls), len(forms)))
    version = None
    for k, v in plist(decls[0][2:4] if len(decls[0]) > 3 else [], 'schema header'):
        if k == 'version':
            version = render(v, 'schema :version')
    enums, spaces, ftypes, conds, uniques = {}, {}, {}, [], []
    for sub in decls[0]:
        if not isinstance(sub, list):
            continue
        h = head(sub)
        if h == 'define-enum':
            enums[sub[1].text.upper()] = [render(v, 'enum value') for v in sub[2]]
        elif h == 'define-id-space':
            pl = dict(plist(sub[2:], 'id-space'))
            spaces[sub[1].text.upper()] = (render(pl['charset'], 'charset'),
                                           pl['prefix'].text if 'prefix' in pl else None,
                                           int(pl['min'].text) if 'min' in pl else 1,
                                           int(pl['max'].text) if 'max' in pl else 1000)
        elif h == 'define-conditional':
            pl = dict(plist(sub[2:], 'conditional'))
            conds.append((render(pl['type'], 't').upper(), render(pl['when-key'], 'k').upper(),
                          render(pl['when-value'], 'v').upper(),
                          [render(x, 'r').upper() for x in pl.get('require', [])],
                          [render(x, 'f').upper() for x in pl.get('forbid', [])], sub[1].text.upper()))
        elif h == 'define-unique':
            pl = dict(plist(sub[2:], 'unique'))
            uniques.append((render(pl['type'], 't').upper(), render(pl['field'], 'f').upper(), sub[1].text.upper()))
        elif h == 'define-fact-type':
            name = sub[1].text.lower()
            pl = dict(plist(sub[2:], 'fact type %s' % name))
            ftypes[name] = dict(
                required=[render(x, 'req').lower() for x in pl.get('required', [])],
                optional=[render(x, 'opt').lower() for x in pl.get('optional', [])],
                types={render(p[0], 't').lower(): render(p[1], 't').upper() for p in pl.get('types', [])},
                enum={render(p[0], 'e').lower(): render(p[1], 'e').upper() for p in pl.get('enum', [])},
                ref={render(r[0], 'r').lower(): [render(t, 'r').lower() for t in r[1:]] for r in pl.get('ref', [])},
                id_space=render(pl['id-space'], 'id-space').upper() if 'id-space' in pl else None)
    return version, enums, spaces, ftypes, conds, uniques


def id_space_reason(spaces, space, ident):
    if space not in spaces:
        return 'cites undeclared id-space %s' % space
    charset, prefix, lo, hi = spaces[space]
    if not lo <= len(ident) <= hi:
        return 'is %d characters, outside the %s range %d..%d' % (len(ident), space, lo, hi)
    if prefix and not ident.startswith(prefix):
        return 'does not start with the %s prefix %r' % (space, prefix)
    if charset == 'TOKEN' and any(c not in TOKEN_CHARS for c in ident):
        return 'contains a character outside the %s token charset' % space
    if charset == 'PATH' and any(ord(c) < 32 for c in ident):
        return 'contains a control character, which the %s charset forbids' % space
    return None


# ══════════════════════════════════════════════════════════ ROOT
def read_root(dirp):
    forms = read_file(os.path.join(dirp, 'ROOT.sexp'), 'model root')
    roots = [f for f in forms if head(f) == 'define-model-root']
    if len(roots) != 1 or len(forms) != 1:
        die(3, 'ROOT-MALFORMED: ROOT.sexp must hold exactly one define-model-root form and nothing else; '
               'found %d root form(s) among %d top-level form(s)' % (len(roots), len(forms)))
    pairs = plist(roots[0][2:], 'define-model-root')
    seen, dup = set(), []
    for k, _v in pairs:
        (dup.append(k) if k in seen else seen.add(k))
    if dup:
        die(3, 'ROOT-MALFORMED: ROOT.sexp declares %s more than once' % ', '.join(':' + d for d in sorted(set(dup))))
    pl = dict(pairs)
    comp = []
    for entry in pl.get('composition', []):
        e = dict(plist(entry, 'composition entry'))
        comp.append((render(e['module'], 'module'), render(e['sha256'], 'sha256')))
    return pl, comp


def verify_root(dirp, pl, comp, schema_version, viol):
    rows = []
    for name, pin in comp:
        path = os.path.join(dirp, name)
        if len(pin) != 64 or any(c not in '0123456789abcdef' for c in pin):
            viol.append(('L7', 'module', name, 'sha256', 'MALFORMED-PIN'))
        if not os.path.isfile(path):
            rows.append('%s:MISSING' % name)
            viol.append(('L7', 'module', name, 'sha256', 'MISSING-ON-DISK'))
            continue
        actual = sha_file(path)
        rows.append('%s:%s' % (name, actual))
        if actual != pin:
            viol.append(('L7', 'module', name, 'sha256', '%s!=%s' % (actual[:12], pin[:12])))
    declared = {n for n, _ in comp}
    for fn in sorted(os.listdir(dirp)):
        if fn.endswith('.sexp') and fn != 'ROOT.sexp' and fn not in declared:
            viol.append(('L7', 'module', fn, 'composition', 'UNDECLARED-EXTRA-MODULE'))
    count = pl.get('module-count')
    if count is None or kind_of(count) != 'INTEGER' or int(count.text) != len(comp):
        viol.append(('L7', 'root', 'ROOT.sexp', 'module-count',
                     '%s!=%d' % (count.text if count is not None else 'ABSENT', len(comp))))
    sv = pl.get('schema-version')
    if sv is None or render(sv, 'schema-version') != schema_version:
        viol.append(('L7', 'root', 'ROOT.sexp', 'schema-version',
                     '%s!=%s' % (render(sv, 's') if sv is not None else 'ABSENT', schema_version)))
    parent = pl.get('parent-architecture-commit')
    ptxt = render(parent, 'parent') if parent is not None else ''
    if len(ptxt) != 40 or any(c not in '0123456789abcdef' for c in ptxt):
        viol.append(('L7', 'root', 'ROOT.sexp', 'parent-architecture-commit', 'MALFORMED-COMMIT-ID'))
    recomputed = sha_text('\n'.join(rows))
    stated = render(pl['canonical-model-root-digest'], 'digest') if 'canonical-model-root-digest' in pl else ''
    if recomputed != stated:
        viol.append(('L7', 'root', 'ROOT.sexp', 'canonical-model-root-digest',
                     '%s!=%s' % (recomputed[:16], stated[:16])))
    return recomputed


# ══════════════════════════════════════════════════════════ facts
def read_facts(dirp, comp, schema, viol):
    version, enums, spaces, ftypes, conds, uniques = schema
    facts, seen, owner = [], {}, {}
    for name, _pin in comp:
        path = os.path.join(dirp, name)
        if not os.path.isfile(path):
            continue
        for form in read_file(path, 'model module'):
            h = head(form)
            if h in HEADERS:
                continue
            if h != 'fact':
                die(3, 'UNCONSUMED-CANONICAL-SYNTAX: %s: top-level form %r is neither a fact nor a declared '
                       'header — the model universe would be incomplete' % (name, h))
            if len(form) < 3:
                die(3, 'MALFORMED-FACT: %s: a fact needs a type and an id' % name)
            ftype = form[1].text.lower()
            try:
                fid = render(form[2], 'fact id')
                pairs = plist(form[3:], '%s %s' % (ftype, fid))
                # Render every value HERE, where the fact enters the universe. A value that has no canonical
                # rendering must never reach the commitment or the solver: it would surface as a traceback from
                # deep inside a later stage instead of a named rejection at the point of reading.
                for k, v in pairs:
                    render(v, '%s %s :%s' % (ftype, fid, k))
            except ReadError as e:
                die(3, 'MALFORMED-FACT: %s: %s' % (name, e))
            spec = ftypes.get(ftype)
            if spec is None:
                viol.append(('L1', ftype, fid, 'fact-type', 'UNDECLARED-FACT-TYPE'))
            else:
                r = id_space_reason(spaces, spec['id_space'], fid)
                if r:
                    viol.append(('L1', ftype, fid, 'id', 'ID-SPACE: the id %s' % r))
                allowed = set(spec['required']) | set(spec['optional'])
                keys = [k.lower() for k, _ in pairs]
                for k in sorted(set(keys)):
                    if keys.count(k) > 1:
                        viol.append(('L2', ftype, fid, k, 'DUPLICATE-KEY'))
                    if k not in allowed:
                        viol.append(('L1', ftype, fid, k, 'UNDECLARED-FIELD (permitted: %s)'
                                     % ' '.join(sorted(allowed)) if allowed else 'UNDECLARED-FIELD (none permitted)'))
                for k, v in pairs:
                    want = spec['types'].get(k.lower())
                    if want and kind_of(v) != want:
                        viol.append(('L1', ftype, fid, k.lower(), 'WRONG-VALUE-KIND %s!=%s' % (kind_of(v), want)))
                have = {k.lower() for k, _ in pairs}
                for c_type, c_key, c_val, c_req, c_forbid, c_name in conds:
                    if c_type != ftype.upper():
                        continue
                    cur = next((render(v, 'c') for k, v in pairs if k.lower() == c_key.lower()), None)
                    if cur is None or cur.upper() != c_val:
                        continue
                    for k in c_req:
                        if k.lower() not in have:
                            viol.append(('L1', ftype, fid, k.lower(), 'CONDITIONAL-REQUIRES (%s)' % c_name))
                    for k in c_forbid:
                        if k.lower() in have:
                            viol.append(('L1', ftype, fid, k.lower(), 'CONDITIONAL-FORBIDS (%s)' % c_name))
            if (ftype, fid) in seen:
                viol.append(('L2', ftype, fid, 'seat', 'DUPLICATE-SEAT-ALSO-IN-%s' % seen[(ftype, fid)]))
            else:
                seen[(ftype, fid)] = name
            if fid in owner and owner[fid] != ftype:
                viol.append(('L2', ftype, fid, 'id', 'ALSO-DECLARED-UNDER-%s' % owner[fid]))
            owner.setdefault(fid, ftype)
            facts.append((name, ftype, fid, pairs))
    for u_type, u_field, u_name in uniques:
        first = {}
        for _m, ftype, fid, pairs in facts:
            if ftype.upper() != u_type:
                continue
            v = next((render(v, 'u') for k, v in pairs if k.lower() == u_field.lower()), None)
            if v is None:
                continue
            if v in first:
                viol.append(('L2', ftype, fid, u_field.lower(), '%s: ALSO-CLAIMED-BY-%s' % (u_name, first[v])))
            else:
                first[v] = fid
    return facts


def canonical_fact_render(ftype, fid, pairs):
    parts = sorted('%s=%s' % (k.upper(), render(v, '%s %s :%s' % (ftype, fid, k))) for k, v in pairs)
    return '%s|%s|%s' % (ftype.upper(), fid, '|'.join(parts))


def commitment_lines(facts):
    per_mod, per_fam, allr = {}, {}, []
    for mod, ftype, fid, pairs in facts:
        r = canonical_fact_render(ftype, fid, pairs)
        allr.append(r); per_mod.setdefault(mod, []).append(r); per_fam.setdefault(ftype, []).append(r)
    dig = lambda rs: sha_text('\n'.join(sorted(rs)))
    out = ['COMMITMENT total-facts %d' % len(allr), 'COMMITMENT total-digest %s' % dig(allr)]
    for m in sorted(per_mod):
        out.append('COMMITMENT module %s %d %s' % (m, len(per_mod[m]), dig(per_mod[m])))
    for f in sorted(per_fam):
        out.append('COMMITMENT family %s %d %s' % (f, len(per_fam[f]), dig(per_fam[f])))
    return out, per_mod, per_fam


def compare_commitments(path, mine):
    if not os.path.isfile(path):
        die(3, 'COMMITMENT-UNAVAILABLE: %s does not exist — the kernel universe cannot be compared, so no '
               'verdict is issued by this path' % path)
    with open(path, encoding='utf-8') as f:
        theirs = f.read().splitlines()
    if theirs != mine:
        only_k = [l for l in theirs if l not in mine]
        only_c = [l for l in mine if l not in theirs]
        die(3, 'COMMITMENT-MISMATCH: the kernel and this checker consumed different fact universes',
            *(['  kernel-only: %s' % l for l in only_k[:12]] + ['  checker-only: %s' % l for l in only_c[:12]]))


# ══════════════════════════════════════════════════════════ clingo encoding
def q(s):
    """An ASP string literal. A control character can never reach here from a model that satisfies the value
    grammar; when one does, it is rendered visibly instead of being handed to the solver, so the run ends in a
    named verdict rather than a lexer traceback."""
    t = str(s).replace('\\', '\\\\').replace('"', '\\"')
    return '"%s"' % ''.join(c if 32 <= ord(c) != 127 else '<U+%04X>' % ord(c) for c in t)


RULES = r'''
% ---------- L1 well-formedness: declared type, required keys, closed enum domains
haskey(T,I,K) :- kv(T,I,K,_).
violation("L1",T,I,"fact-type","UNDECLARED-FACT-TYPE") :- decl(T,I), not ftype(T).
violation("L1",T,I,K,"MISSING-REQUIRED-KEY") :- decl(T,I), reqkey(T,K), not haskey(T,I,K).
violation("L1",T,I,K,V) :- kv(T,I,K,V), enumkey(T,K,E), not enumdom(E,V).
% ---------- L3 closed typed references: the value must be a declared id of one permitted target type
resolved(T,I,K) :- kv(T,I,K,V), refkey(T,K,G), decl(G,V).
violation("L3",T,I,K,V) :- kv(T,I,K,V), refkey(T,K,_), not resolved(T,I,K).
% ---------- L4 acyclicity of EVERY declared from/to relation over a single node type
multi(T,K) :- refkey(T,K,A), refkey(T,K,B), A!=B.
edgerel(T,N) :- refkey(T,"from",N), refkey(T,"to",N), not multi(T,"from"), not multi(T,"to").
edge(T,X,Y) :- edgerel(T,_), kv(T,I,"from",X), kv(T,I,"to",Y).
reach(T,X,Y) :- edge(T,X,Y).
reach(T,X,Z) :- reach(T,X,Y), edge(T,Y,Z).
violation("L4",T,X,"cycle",X) :- edgerel(T,_), reach(T,X,X).
% ---------- L5 public/private isolation, failing closed on any consumer of undecidable kind
subkind(S,"PUBLIC")  :- kv("subsystem",S,"classification","PUBLIC").
subkind(S,"PRIVATE") :- kv("subsystem",S,"classification","PRIVATE").
consumer(C) :- kv("consumes",_,"consumer",C).
ckind(C,K) :- consumer(C), decl("subsystem",C), subkind(C,K).
ckind(C,K) :- consumer(C), decl("component",C), kv("component",C,"owner-subsystem",O), subkind(O,K).
ckind(C,K) :- consumer(C), decl("type",C), haskey("type",C,"consumer-role"), kv("type",C,"classification",K).
unpermitted(C) :- consumer(C), decl("type",C), not haskey("type",C,"consumer-role").
violation("L5","consumes",C,"consumer","TYPE-CONSUMER-WITHOUT-CONSUMER-ROLE") :- unpermitted(C).
violation("L5","consumes",C,"consumer","UNKNOWN-CONSUMER-KIND") :-
    consumer(C), not unpermitted(C), not ckind(C,"PUBLIC"), not ckind(C,"PRIVATE").
privtype(P) :- kv("type",P,"classification","PRIVATE").
violation("L5","consumes",I,"provides",P) :-
    kv("consumes",I,"consumer",C), kv("consumes",I,"provides",P), privtype(P), ckind(C,"PUBLIC").
% ---------- L6 requirement -> SEAT -> test -> WP: coverage AND seat agreement (Review-2 N-10)
covered(S) :- kv("req-map",_,"subsystem",S).
violation("L6","subsystem",S,"req-map","UNMAPPED-SUBSYSTEM") :- decl("subsystem",S), not covered(S).
violation("L6","req-map",I,"seat",M) :-
    kv("req-map",I,"subsystem",S), kv("req-map",I,"seat",M), kv("subsystem",S,"owner-seat",O), M!=O.
#show violation/5.
'''


def build_program(facts, enums, ftypes):
    L = []
    for _mod, ftype, fid, pairs in facts:
        L.append('decl(%s,%s).' % (q(ftype), q(fid)))
        for k, v in pairs:
            L.append('kv(%s,%s,%s,%s).' % (q(ftype), q(fid), q(k.lower()),
                                           q(render(v, '%s %s :%s' % (ftype, fid, k)))))
    for name, vals in sorted(enums.items()):
        for v in vals:
            L.append('enumdom(%s,%s).' % (q(name.lower()), q(v)))
    for t, spec in sorted(ftypes.items()):
        L.append('ftype(%s).' % q(t))
        for k in spec['required']:
            L.append('reqkey(%s,%s).' % (q(t), q(k)))
        for k, e in sorted(spec['enum'].items()):
            L.append('enumkey(%s,%s,%s).' % (q(t), q(k), q(e.lower())))
        for k, tgts in sorted(spec['ref'].items()):
            for g in tgts:
                L.append('refkey(%s,%s,%s).' % (q(t), q(k), q(g)))
    return '\n'.join(L) + '\n' + RULES


def run(program):
    ctl = clingo.Control(['--warn=none'])
    ctl.add('base', [], program)
    ctl.ground([('base', [])])
    out = set()
    with ctl.solve(yield_=True) as h:
        for mdl in h:
            for a in mdl.symbols(shown=True):
                if a.name == 'violation':
                    out.add(tuple(str(x).strip('"') for x in a.arguments))
            break
    return out


def main():
    ap = argparse.ArgumentParser(description='independent second verification path')
    ap.add_argument('root', nargs='?', help='path to the ROOT.sexp of the model directory to check')
    ap.add_argument('--kernel-commitment', help='the kernel commitment file to compare against')
    ap.add_argument('--commitment', help='write this path\'s commitment here instead of into the model directory')
    ap.add_argument('--export', help='write the neutral JSON export here')
    args = ap.parse_args()

    self_test_hash()
    dirp = os.path.dirname(os.path.abspath(args.root)) if args.root else HERE
    viol = []
    schema = read_schema(dirp)
    version, enums, spaces, ftypes, conds, uniques = schema
    pl, comp = read_root(dirp)
    recomputed = verify_root(dirp, pl, comp, version, viol)
    facts = read_facts(dirp, comp, schema, viol)
    lines, per_mod, per_fam = commitment_lines(facts)

    mine_path = args.commitment or os.path.join(dirp, 'CHECKER-COMMITMENT.txt')
    with open(mine_path, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(lines) + '\n')
    compare_commitments(args.kernel_commitment or os.path.join(dirp, 'KERNEL-COMMITMENT.txt'), lines)

    viol = sorted(set(viol) | run(build_program(facts, enums, ftypes)))
    exp = {'checker': CHECKER_VERSION,
           'module-universe': [n for n, _ in comp],
           'schema-version': version,
           'recomputed-model-root-digest': recomputed,
           'declared-model-root-digest': render(pl['canonical-model-root-digest'], 'd'),
           'total-facts': len(facts),
           'module-counts': {m: len(v) for m, v in sorted(per_mod.items())},
           'module-digests': {m: sha_text('\n'.join(sorted(v))) for m, v in sorted(per_mod.items())},
           'family-counts': {t: len(v) for t, v in sorted(per_fam.items())},
           'family-digests': {t: sha_text('\n'.join(sorted(v))) for t, v in sorted(per_fam.items())},
           'violations': [list(v) for v in viol]}
    export_path = args.export or os.path.join(dirp, 'CHECKER', 'NEUTRAL-EXPORT.json')
    os.makedirs(os.path.dirname(export_path), exist_ok=True)
    with open(export_path, 'w', encoding='utf-8') as f:
        json.dump(exp, f, indent=1, sort_keys=True)

    laws = sorted({v[0] for v in viol})
    for law in ('L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7'):
        print('INDEPENDENT %s: %s' % (law, 'FAIL' if law in laws else 'PASS'))
    if viol:
        for v in viol:
            print('INDEPENDENT VIOLATION %s: %s %s :%s = %s' % v)
        die(3, 'INDEPENDENT ARCHITECTURE INVARIANTS: FAIL (%s)' % ','.join(laws))
    die(0, 'INDEPENDENT ARCHITECTURE INVARIANTS: PASS (facts=%d, modules=%d, schema-version %s, fact-set '
           'commitment identical to the kernel, model-root %s recomputed)'
        % (len(facts), len(comp), version, recomputed[:12]))


if __name__ == '__main__':
    main()
