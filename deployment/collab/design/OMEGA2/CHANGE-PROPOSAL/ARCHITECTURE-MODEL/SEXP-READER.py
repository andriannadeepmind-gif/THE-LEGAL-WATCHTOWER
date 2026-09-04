#!/usr/bin/env python3
"""SEXP-READER.py — the ONE classified Python reader seat for the s-expression grammars of this repository.

Declared users (there is no second Python s-expression reader in the architecture-governance seat):
    CHECKER/independent_check.py   canonical model modules + ROOT.sexp + MODEL-SCHEMA.sexp
    generate_views.py              canonical model modules + ROOT.sexp
    build_decision_packet.py       canonical model modules + ROOT.sexp
    build_model.py                 v1.6-v1.8 migration-source registries
    build_deferred.py              v1.6-v1.8 migration-source registries + the emitted ledger

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
import os

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


def read_file(path):
    """Read PATH as raw bytes decoded strictly as UTF-8. A missing file is a typed result, never a traceback."""
    if not os.path.isfile(path):
        raise MissingSourceFile(path)
    with open(path, 'rb') as f:
        raw = f.read()
    if len(raw) > MAX_BYTES:
        raise SexpSyntaxError(path, 1, 1, 'file exceeds the %d byte limit' % MAX_BYTES)
    try:
        return raw.decode('utf-8')
    except UnicodeDecodeError as e:
        raise SexpSyntaxError(path, 1, 1, 'file is not valid UTF-8 (%s)' % e)


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


def canonical_value(v, source='<text>', what='value'):
    """The ONE canonical rendering of a fact value. See the module docstring for the specification."""
    if isinstance(v, Str):
        return str(v)
    if isinstance(v, Int):
        return str(int(v))
    if isinstance(v, Sym):
        return str(v).upper()
    raise ValueKindError(source, what,
                         'illegal value kind %s (permitted: string, integer, plain symbol)' % type(v).__name__)


def canonical_fact_render(ftype, fid, pairs, source='<text>'):
    """TYPE|ID|KEY=VALUE|... with keys upper-cased and the KEY=VALUE parts sorted. Identical in both paths."""
    what = '%s %s' % (ftype, fid)
    parts = sorted('%s=%s' % (k.upper(), canonical_value(v, source, what)) for k, v in pairs)
    return '%s|%s|%s' % (ftype.upper(), fid, '|'.join(parts)) if parts else '%s|%s|' % (ftype.upper(), fid)
