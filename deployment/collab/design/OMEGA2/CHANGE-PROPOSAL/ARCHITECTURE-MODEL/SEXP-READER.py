#!/usr/bin/env python3
"""SEXP-READER.py — the ONE classified Python reader seat for the s-expression grammars of this repository.

Declared users (there is no second Python s-expression reader in the architecture-governance seat):
    gate_checks.py                 canonical model modules + ROOT.sexp + the AMC2 reference implementation
    generate_views.py              canonical model modules + ROOT.sexp
    build_decision_packet.py       canonical model modules + ROOT.sexp
    build_deferred.py              v1.6-v1.8 migration-source registries + the emitted ledger
    run_corpus.py                  the declared verification corpus and its mutations
CHECKER/independent_check.py deliberately does NOT appear above: the independent path carries its own reader, so
that the two verification paths share a written specification and no code.

Properties this seat guarantees:
  * BOUNDED GRAMMAR, TWO DECLARED PROFILES — lists, bare symbols, integers, keywords and strings; `;` line
    comments and `#| |#` block comments; explicit byte, depth and list-length limits. Nothing else is accepted.
    CANONICAL is the profile of the architecture model: a bare symbol must match [A-Za-z][A-Za-z0-9_.+/-]* and a
    number must be an integer, so no Lisp reader can read a value as a float or ratio and no value can render
    differently in two languages. REGISTRY is the profile of the inherited v1.6-v1.8 source registries, whose
    symbols predate this model and legitimately contain characters such as `>`; registry values are enumerated
    and migrated, never folded into a cross-language commitment, so they need no rendering guarantee.
    The strictness is a declared parameter of one reader, not a second reader.
  * NO EVALUATION — atoms are returned as typed tokens; nothing is executed, interned, imported or resolved.
  * COMPLETE CONSUMPTION — reading stops only at end of input. Unbalanced or surplus parentheses, unterminated
    strings and unterminated block comments are errors, never silently dropped remainders. A reader that skips
    what it does not recognise cannot be used to prove that nothing was hidden.
  * TYPED ERRORS — SexpSyntaxError / ValueKindError / MissingSourceFile, each naming file, line and column.
  * MULTI-LINE BY CONSTRUCTION — a form may span any number of lines; line structure carries no meaning.

Canonical value rendering (the SPECIFICATION shared with the Common Lisp kernel; the code is not shared):
    string  -> its exact content
    integer -> its decimal form
    symbol  -> its upper-case name
A bare symbol must match [A-Za-z][A-Za-z0-9_.+/-]* so that no Common Lisp reader can ever read it as a number,
and an integer must match [+-]?[0-9]+. Keywords, floats, ratios, nested lists and NIL are not permitted values.
This is what lets two implementations in two languages commit to bit-identical fact digests.
"""
import hashlib, os

MAX_BYTES = 8_000_000
MAX_DEPTH = 40
MAX_LIST = 200_000
SYMBOL_START = set('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')
SYMBOL_REST = SYMBOL_START | set('0123456789_.+/-')
DIGITS = set('0123456789')
ATOM_STOP = set(' \t\r\n\f()";')
CANONICAL = 'CANONICAL'
REGISTRY = 'REGISTRY'


class SexpError(Exception):
    """Base of every typed reader failure."""


class MissingSourceFile(SexpError):
    def __init__(self, path):
        self.path = path
        super().__init__('MISSING-SOURCE-FILE: %s' % path)


class SexpSyntaxError(SexpError):
    def __init__(self, source, line, col, message):
        self.source, self.line, self.col = source, line, col
        super().__init__('SEXP-SYNTAX-ERROR: %s:%d:%d: %s' % (source, line, col, message))


class ValueKindError(SexpError):
    def __init__(self, source, what, message):
        self.source = source
        super().__init__('SEXP-VALUE-KIND-ERROR: %s: %s: %s' % (source, what, message))


class Sym(str):
    """A bare symbol, exactly as written."""
    __slots__ = ()


class Str(str):
    """A string literal's content, escapes already decoded."""
    __slots__ = ()


class Kw(str):
    """A keyword, without its leading colon."""
    __slots__ = ()


class Int(int):
    """An integer literal."""
    __slots__ = ()


def read_bytes(path):
    """The raw bytes of PATH. A missing file is a typed result, never a traceback."""
    if not os.path.isfile(path):
        raise MissingSourceFile(path)
    with open(path, 'rb') as f:
        return f.read()


def decode_text(raw, source):
    """RAW decoded strictly as UTF-8 under the byte limit — the one decoding rule of every source this reader
    accepts, whether the bytes came from a file or from a repository object."""
    if len(raw) > MAX_BYTES:
        raise SexpSyntaxError(source, 1, 1, 'file exceeds the %d byte limit' % MAX_BYTES)
    try:
        return raw.decode('utf-8')
    except UnicodeDecodeError as e:
        raise SexpSyntaxError(source, 1, 1, 'file is not valid UTF-8 (%s)' % e)


def read_file(path):
    """Read PATH as raw bytes decoded strictly as UTF-8. A missing file is a typed result, never a traceback."""
    return decode_text(read_bytes(path), path)


class _Reader:
    def __init__(self, text, source, profile):
        if profile not in (CANONICAL, REGISTRY):
            raise ValueKindError(source, 'profile', 'unknown reader profile %r' % (profile,))
        self.t, self.n, self.i, self.src, self.profile = text, len(text), 0, source, profile

    def pos(self, i=None):
        i = self.i if i is None else i
        line = self.t.count('\n', 0, i) + 1
        col = i - (self.t.rfind('\n', 0, i) + 1) + 1
        return line, col

    def err(self, message, at=None):
        line, col = self.pos(at)
        raise SexpSyntaxError(self.src, line, col, message)

    def skip(self):
        while self.i < self.n:
            c = self.t[self.i]
            if c in ' \t\r\n\f':
                self.i += 1
            elif c == ';':
                j = self.t.find('\n', self.i)
                self.i = self.n if j < 0 else j + 1
            elif c == '#' and self.i + 1 < self.n and self.t[self.i + 1] == '|':
                start = self.i
                depth, self.i = 1, self.i + 2
                while self.i < self.n and depth:
                    if self.t.startswith('#|', self.i):
                        depth += 1; self.i += 2
                    elif self.t.startswith('|#', self.i):
                        depth -= 1; self.i += 2
                    else:
                        self.i += 1
                if depth:
                    self.err('unterminated block comment', start)
            else:
                return

    def read_string(self):
        start = self.i
        self.i += 1
        out = []
        while True:
            if self.i >= self.n:
                self.err('unterminated string', start)
            c = self.t[self.i]
            if c == '\\':
                if self.i + 1 >= self.n:
                    self.err('unterminated string escape', start)
                out.append(self.t[self.i + 1]); self.i += 2
            elif c == '"':
                self.i += 1
                return Str(''.join(out))
            else:
                out.append(c); self.i += 1

    def read_atom(self):
        start = self.i
        while self.i < self.n and self.t[self.i] not in ATOM_STOP:
            self.i += 1
        text = self.t[start:self.i]
        if not text:
            self.err('empty atom')
        if text[0] == ':':
            body = text[1:]
            if not body:
                self.err('empty keyword', start)
            return Kw(body)
        numericish = text[0] in DIGITS or (text[0] in '+-' and len(text) > 1 and text[1] in DIGITS)
        body = text[1:] if text[0] in '+-' else text
        if numericish and body and all(ch in DIGITS for ch in body):
            return Int(int(text))
        if self.profile == CANONICAL:
            if numericish:
                self.err('numeric atom %r is not an integer; the canonical grammar admits integers only' % text, start)
            if text[0] not in SYMBOL_START or any(ch not in SYMBOL_REST for ch in text):
                self.err('symbol %r is outside the canonical grammar [A-Za-z][A-Za-z0-9_.+/-]*' % text, start)
        return Sym(text)

    def read_form(self, depth):
        if depth > MAX_DEPTH:
            self.err('form exceeds the depth limit of %d' % MAX_DEPTH)
        self.skip()
        if self.i >= self.n:
            self.err('unexpected end of input')
        c = self.t[self.i]
        if c == ')':
            self.err('unbalanced closing parenthesis')
        if c == '(':
            open_at = self.i
            self.i += 1
            items = []
            while True:
                self.skip()
                if self.i >= self.n:
                    self.err('unterminated list', open_at)
                if self.t[self.i] == ')':
                    self.i += 1
                    return items
                if len(items) >= MAX_LIST:
                    self.err('list exceeds the length limit of %d' % MAX_LIST, open_at)
                items.append(self.read_form(depth + 1))
        if c == '"':
            return self.read_string()
        return self.read_atom()

    def read_all(self):
        out = []
        while True:
            self.skip()
            if self.i >= self.n:
                return out
            out.append(self.read_form(0))


def read_forms(text, source='<text>', profile=CANONICAL):
    """Every top-level form in TEXT. Reading ends only at end of input; nothing is skipped."""
    return _Reader(text, source, profile).read_all()


def read_forms_file(path, profile=CANONICAL):
    return read_forms(read_file(path), path, profile)


def kv(form, key, default=None):
    """The value following :KEY in FORM's trailing plist, or DEFAULT. Never evaluates, never guesses."""
    for i in range(len(form) - 1):
        if isinstance(form[i], Kw) and str(form[i]) == key:
            return form[i + 1]
    return default


def head(form):
    """The head symbol of a list form, as written; None for an atom or an empty/odd list."""
    if isinstance(form, list) and form and isinstance(form[0], (Sym, Kw)):
        return str(form[0])
    return None


def plist(items, source='<text>', what='form'):
    """Interpret ITEMS as :key value pairs. A dangling key or a non-keyword in key position is a typed error."""
    out = []
    i = 0
    while i < len(items):
        k = items[i]
        if not isinstance(k, Kw):
            raise ValueKindError(source, what, 'expected a :keyword in key position, found %r' % (k,))
        if i + 1 >= len(items):
            raise ValueKindError(source, what, 'key :%s has no value' % k)
        out.append((str(k), items[i + 1]))
        i += 2
    return out


# The complete top-level header vocabulary of a model module: everything else at top level must be a `fact`.
# One seat, because a consumer that carried its own list would silently tolerate a form the laws reject — a
# stale entry here is exactly how `define-toolchain` outlived the schema that declared it.
HEADERS = ('define-model-schema', 'define-model-root')


def canonical_value(v, source='<text>', what='value'):
    """The ONE canonical rendering of a fact value. See the module docstring for the specification."""
    if isinstance(v, Str):
        # A control character inside a string would make a canonical commitment line ambiguous — the render
        # joins fact lines with '\n' — so such a string is not a legal value at all, not a special case.
        bad = next((c for c in str(v) if ord(c) < 32 or ord(c) == 127), None)
        if bad is not None:
            raise ValueKindError(source, what, 'control character U+%04X inside a string value; canonical '
                                               'strings are control-character free' % ord(bad))
        return str(v)
    if isinstance(v, Int):
        return str(int(v))
    if isinstance(v, Sym):
        return str(v).upper()
    raise ValueKindError(source, what,
                         'illegal value kind %s (permitted: control-character-free string, integer, plain '
                         'symbol)' % type(v).__name__)


class UncontainedPath(SexpError):
    """A model-declared output path that does not name a location strictly inside its output root."""

    def __init__(self, what, reason):
        self.what, self.reason = what, reason
        super().__init__('UNCONTAINED-PATH: %s %s' % (what, reason))


def contained_path(root, rel, what='path'):
    """The absolute location ROOT/REL, or a typed refusal — the ONE place a model-declared write target is
    resolved (Review-3 R3-6).

    A `:path` is model data, and model data was able to name `/tmp/h-probe/PWNED.md`: `os.path.join` lets an
    absolute component win outright, and the generator wrote 1231 bytes outside its output root before anything
    compared anything. Rejecting the reported example would not have removed the class, so every hostile shape is
    refused here, BEFORE any filesystem call: absolute paths, drive/UNC-ish roots, `..`, `.`, empty or
    whitespace-only components, backslash separators, and any resolution that leaves the root — including one
    reached through a symlink, which is why the parents are resolved rather than trusted.
    """
    r = str(rel)
    if not r or r != r.strip():
        raise UncontainedPath(what, 'is empty or padded with whitespace: %r' % r)
    if os.path.isabs(r) or r.startswith(('/', '\\')) or (len(r) > 1 and r[1] == ':'):
        raise UncontainedPath(what, 'is absolute: %r' % r)
    parts = r.replace('\\', '/').split('/')
    for c in parts:
        if c in ('', '.', '..') or c != c.strip():
            raise UncontainedPath(what, 'has an empty, relative or padded component: %r' % r)
    root_real = os.path.realpath(root)
    target = os.path.join(root_real, *parts)
    # every existing ancestor must resolve inside the root: a symlinked directory must not become an escape
    probe = target
    while True:
        parent = os.path.dirname(probe)
        if parent == probe:
            break
        if os.path.exists(parent):
            if os.path.realpath(parent) != root_real and not os.path.realpath(parent).startswith(root_real + os.sep):
                raise UncontainedPath(what, 'resolves outside its output root through %r' % parent)
            break
        probe = parent
    if os.path.lexists(target) and os.path.islink(target):
        raise UncontainedPath(what, 'names an existing symlink: %r' % r)
    return target


CANONICAL_ENCODING = 'AMC2'          # must equal MODEL-SCHEMA.sexp's :canonical-encoding


def enc(s):
    """AMC2: <byte-length of the UTF-8 form>:<the UTF-8 form>. See CANONICAL-ENCODING.md.

    Injective by construction. The superseded delimiter encoding let a value containing '|' impersonate a field
    boundary, so two different legal models rendered to identical commitment bytes; here nothing is ever searched
    for, because every component carries its own exact length."""
    return '%d:%s' % (len(str(s).encode('utf-8')), s)


def canonical_fact_render(ftype, fid, pairs, schema_version, source='<text>'):
    """The AMC2 render of one fact — the REFERENCE implementation of the specification the kernel and the
    independent checker each implement separately. `gate_checks.py encoding` requires all three to agree."""
    what = '%s %s' % (ftype, fid)
    kv = sorted(enc(k.upper()) + enc(canonical_value(v, source, what)) for k, v in pairs)
    return ''.join([enc(CANONICAL_ENCODING), enc(schema_version), enc(ftype.upper()), enc(fid),
                    enc(str(len(kv)))] + kv)


def canonical_digest(scope, renders, schema_version):
    """The AMC2 commitment digest of a rendered set, domain-separated by SCOPE and bound to the schema."""
    body = ''.join([enc('AMC2-COMMITMENT'), enc(schema_version), enc(scope), enc(str(len(renders)))]
                   + [enc(r) for r in sorted(renders)])
    return hashlib.sha256(body.encode('utf-8')).hexdigest()


# ─────────────────────────────────────────────────────── the one canonical model read (Review-3 §15)
# Four programs carried the same twenty lines: open ROOT.sexp, take the single define-model-root form, walk its
# composition, then read every module and turn each fact into (type, id, plist). Four copies of one concept is
# four places for the header vocabulary, the value canonicalisation or the error typing to drift. This is that
# seat. The result is cached per directory because the gate, the generators and the packet each read the same
# model several times in one run and the model does not change under them.
#
# The independent checker deliberately does NOT use this: its own reader is what makes it a second path.
_MODEL_CACHE = {}


class Model(object):
    """One canonical model read: the root plist, the ordered module list, every fact of every module, the
    schema declaration and the set of fact types it declares."""

    def __init__(self, root, modules, facts, schema=None, source='<model>'):
        self.root = root
        self.modules = modules
        self.facts = facts
        self.schema = schema
        self.source = source
        self.declared_types = {str(x[1]).lower() for x in (schema[2:] if schema else [])
                               if isinstance(x, list) and head(x) == 'define-fact-type'}
        self.by_type = {}
        for ftype, fid, pairs, _mod, _form in facts:
            self.by_type.setdefault(ftype, []).append((fid, pairs))

    def of(self, ftype):
        return self.by_type.get(ftype, [])


def root_digest(rows):
    """The ONE formula of the canonical model-root digest: SHA-256 over 'module:sha256' lines in composition
    order. build_root.py writes it, the corpus runner re-derives it for mutated copies, and the historical loader
    verifies it — one seat, so no copy can drift."""
    return hashlib.sha256('\n'.join('%s:%s' % (m, h) for m, h in rows).encode('utf-8')).hexdigest()


VERSION_RULE = 'a quoted ASCII decimal string matching [1-9][0-9]* — no leading zero, no unquoted integer, no ' \
               'non-ASCII digit'


def schema_version_of(decl, source='MODEL-SCHEMA.sexp'):
    """The schema's declared :version under the ONE canonical rule (Review-5 §5.2), or a typed error. The value
    is judged as written — an unquoted integer, a leading zero and a non-ASCII digit each fail even though
    Python would happily turn them into the same number."""
    v = kv(decl, 'version')
    if v is None or not isinstance(v, Str):
        raise SexpError('SCHEMA-VERSION-MALFORMED: %s declares :version %r; the version must be %s'
                        % (source, v, VERSION_RULE))
    s = str(v)
    if not s.isascii() or not (s[:1] in '123456789' and all(c in '0123456789' for c in s)):
        raise SexpError('SCHEMA-VERSION-MALFORMED: %s declares :version %r; the version must be %s'
                        % (source, s, VERSION_RULE))
    return s


def schema_declaration(forms, source='MODEL-SCHEMA.sexp'):
    """The single define-model-schema form of a schema module, or a typed error."""
    decls = [f for f in forms if head(f) == 'define-model-schema']
    if len(decls) != 1 or len(forms) != 1:
        raise SexpError('SCHEMA-MALFORMED: %s must carry exactly one define-model-schema form and nothing else '
                        '(found %d declaration(s) among %d form(s))' % (source, len(decls), len(forms)))
    return decls[0]


def read_model_from(load, source, verify=False):
    """The ONE canonical model read over an arbitrary SOURCE of module bytes: LOAD(name) returns the raw bytes
    of module NAME (raising MissingSourceFile when it has none), whether from a directory or from the objects
    of a commit. Nothing here depends on the name or the position of a module: every fact of every pinned
    module is read, and a consumer that wants the facts of one family asks the model, never a file.

    VERIFY is the discipline of a HISTORICAL read (Review-5 R5-1). A live candidate's pins are re-derived by the
    kernel and the independent checker (law L7, ver-01); a base commit has no verifier running over it, so the
    loader itself must establish that what it read is the model that commit committed to: the module set is
    exact and duplicate-free, every module's SHA-256 equals its pin, the root digest equals the composition,
    the root's schema version equals the schema's, no fact is declared twice and every fact type is one the
    schema declares. Each violation is a typed error naming the source.
    """
    forms = read_forms(decode_text(load('ROOT.sexp'), source + ':ROOT.sexp'), source + ':ROOT.sexp')
    roots = [f for f in forms if head(f) == 'define-model-root']
    if len(roots) != 1 or len(forms) != 1:
        raise SexpError('ROOT-MALFORMED: %s: exactly one define-model-root form and nothing else is permitted'
                        % source)
    root = dict(plist(roots[0][2:], source + ':ROOT.sexp', 'define-model-root'))
    entries = [dict(plist(e, source + ':ROOT.sexp', 'composition entry')) for e in root['composition']]
    modules = [str(e['module']) for e in entries]
    if verify and len(set(modules)) != len(modules):
        raise SexpError('ROOT-DUPLICATE-MODULE: %s pins %s more than once'
                        % (source, sorted({m for m in modules if modules.count(m) > 1})))
    if verify and int(root.get('module-count', -1)) != len(modules):
        raise SexpError('ROOT-MODULE-COUNT: %s declares module-count %s for %d pinned modules'
                        % (source, root.get('module-count'), len(modules)))
    facts, seen, rows, schema = [], {}, [], None
    for mod, entry in zip(modules, entries):
        raw = load(mod)
        rows.append((mod, hashlib.sha256(raw).hexdigest()))
        if verify and rows[-1][1] != str(entry.get('sha256', '')):
            raise SexpError('ROOT-PIN-MISMATCH: %s pins %s as %s but its bytes hash to %s'
                            % (source, mod, str(entry.get('sha256', ''))[:12], rows[-1][1][:12]))
        mforms = read_forms(decode_text(raw, source + ':' + mod), source + ':' + mod)
        if mod == 'MODEL-SCHEMA.sexp':
            schema = schema_declaration(mforms, source + ':MODEL-SCHEMA.sexp')
        for form in mforms:
            if head(form) in HEADERS:
                continue
            if head(form) != 'fact' or len(form) < 3:
                raise SexpError('%s: unconsumed top-level form %r' % (mod, head(form)))
            ftype = str(form[1]).lower()
            fid = canonical_value(form[2], mod, 'fact id')
            pairs = plist(form[3:], mod, '%s %s' % (ftype, fid))
            if verify and (ftype, fid) in seen:
                raise SexpError('DUPLICATE-FACT: %s: %s %s is declared in %s and again in %s'
                                % (source, ftype, fid, seen[(ftype, fid)], mod))
            seen[(ftype, fid)] = mod
            facts.append((ftype, fid, {k.lower(): canonical_value(v, mod, k) for k, v in pairs}, mod, form))
    model = Model(root, modules, facts, schema, source)
    if verify:
        if schema is None:
            raise SexpError('SCHEMA-MISSING: %s pins no MODEL-SCHEMA.sexp module' % source)
        if str(root.get('canonical-model-root-digest', '')) != root_digest(rows):
            raise SexpError('ROOT-DIGEST-MISMATCH: %s declares root digest %s but its composition hashes to %s'
                            % (source, str(root.get('canonical-model-root-digest', ''))[:12], root_digest(rows)[:12]))
        if str(root.get('schema-version', '')) != schema_version_of(schema, source + ':MODEL-SCHEMA.sexp'):
            raise SexpError('ROOT-SCHEMA-VERSION: %s binds schema version %r but the schema declares %r'
                            % (source, str(root.get('schema-version', '')), schema_version_of(schema)))
        undeclared = sorted({t for t, _i, _p, _m, _f in facts} - model.declared_types)
        if undeclared:
            raise SexpError('FACT-TYPE-UNDECLARED: %s instantiates %s, which its schema does not declare'
                            % (source, ', '.join(undeclared)))
    return model


def read_model(dirp, cache=True):
    """Read the model rooted at DIRP/ROOT.sexp. A malformed root is a typed error, never a traceback."""
    key = os.path.abspath(dirp)
    if cache and key in _MODEL_CACHE:
        return _MODEL_CACHE[key]
    model = read_model_from(lambda name: read_bytes(os.path.join(key, name)), key)
    if cache:
        _MODEL_CACHE[key] = model
    return model


# ─────────────────────────────────────────────────────── whole-model discovery of the universe facts
# Review-5 R5-1. The floors and the authorizations of a model are found by FACT TYPE across every module the
# root pins — never by the name or the position of a module. Moving them between canonical modules neither hides
# them nor changes their meaning, and a base read through read_model_from sees them wherever they went.
def universe_floors(model):
    """{family: {'id', 'minimum', 'module'}} — exactly ONE active floor per family. A second floor for the same
    family, a family that is no fact type the schema declares, or a minimum that is not a non-negative integer is
    a typed error, never a silent last-write-wins."""
    out = {}
    for ftype, fid, p, mod, form in model.facts:
        if ftype != 'universe-floor':
            continue
        fam = str(p.get('family', '')).lower()
        raw_min = kv(form, 'minimum')
        if not fam or not isinstance(raw_min, Int) or int(raw_min) < 0:
            raise SexpError('UNIVERSE-FLOOR-MALFORMED: %s (%s) must name a :family and a non-negative integer '
                            ':minimum' % (fid, mod))
        if fam not in model.declared_types:
            raise SexpError('UNIVERSE-FLOOR-FAMILY-UNDEFINED: %s (%s) floors family %s, which is no fact type '
                            'the schema declares' % (fid, mod, fam))
        if fam in out:
            raise SexpError('UNIVERSE-FLOOR-DUPLICATE: family %s is floored by %s (%s) and again by %s (%s); '
                            'exactly one active floor per family, never a silent last-write-wins'
                            % (fam, out[fam]['id'], out[fam]['module'], fid, mod))
        out[fam] = {'id': fid, 'minimum': int(raw_min), 'module': mod}
    return out


# Review-6 R6-1. An authorization carries no writable state: what it IS follows from its own immutable fields
# and from the floors of the model that carries it, so no candidate can certify its own record as retired.
#   PROSPECTIVE       the family it names is still floored at exactly its :previous-minimum — it can be consumed
#   CONSUMED          the family is still floored but the floor has moved: it granted its reduction, it cannot be
#                     replayed (a grant is matched on :previous-minimum), and it stays as historical evidence
#   TERMINALLY-SPENT  it authorised :minimum 0 and the family is floored nowhere: the removal it authorised has
#                     happened, so it no longer needs a live floor and never grants again
#   UNDEFINED         it names a family floored nowhere and authorised no removal — there is nothing it applies to
def authorization_state(p, floors):
    """The derived lifecycle state of authorization P against FLOORS, the floor set of the model carrying it."""
    fam = str(p['family']).lower()
    if fam in floors:
        return 'PROSPECTIVE' if int(floors[fam]['minimum']) == int(p['previous-minimum']) else 'CONSUMED'
    return 'TERMINALLY-SPENT' if int(p['minimum']) == 0 else 'UNDEFINED'


def universe_authorizations(model):
    """{id: plist + 'module'} of every universe-authorization the model carries, wherever it lives."""
    out = {}
    for ftype, fid, p, mod, _form in model.facts:
        if ftype != 'universe-authorization':
            continue
        if fid in out:
            raise SexpError('AUTHORIZATION-DUPLICATE: %s is declared in %s and again in %s'
                            % (fid, out[fid]['module'], mod))
        out[fid] = dict(p, module=mod)
    return out


def tool_path(dirp, role):
    """The pinned absolute executable for ROLE, from TOOLCHAIN.sexp. Review-3 R3-3: no program in this seat
    resolves an interpreter by NAME, so a binary planted earlier on PATH is never the thing that runs."""
    for form in read_forms_file(os.path.join(dirp, 'TOOLCHAIN.sexp')):
        if head(form) == 'fact' and str(form[1]).lower() == 'tool' and str(kv(form, 'role') or '') == role:
            return str(kv(form, 'path'))
    raise SexpError('TOOLCHAIN-UNDECLARED: no tool fact declares role %s' % role)
