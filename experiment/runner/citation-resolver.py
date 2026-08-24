#!/usr/bin/env python3
"""ΠΥΛΗ ΑΚΕΡΑΙΟΤΗΤΑΣ ΠΑΡΑΠΟΜΠΩΝ (versioned gate) — v5.

ΤΙ ΑΠΟΔΕΙΚΝΥΕΙ: CITATION-INTEGRITY-PASS — ότι κάθε παραπομπή του dossier
λύνεται σε ΠΡΑΓΜΑΤΙΚΟ αρχείο του ΠΑΓΩΜΕΝΟΥ read-only mount, με πραγματικό
sha256, πραγματικό μέγεθος, πραγματικό πλήθος λογικών γραμμών, και ότι το
ζητούμενο εύρος υπάρχει ΠΡΑΓΜΑΤΙΚΑ μέσα σε αυτό το αρχείο.

ΤΙ ΔΕΝ ΑΠΟΔΕΙΚΝΥΕΙ — ΔΗΛΩΜΕΝΟ ΡΗΤΑ:
  · ΔΕΝ είναι CLAIM-ENTAILMENT-PASS. Το span ΥΠΑΡΧΕΙ· δεν αποδεικνύεται ότι
    ΣΤΗΡΙΖΕΙ τον ισχυρισμό.
  · ΔΕΝ αποδεικνύει ότι κάθε ουσιώδης ισχυρισμός ΕΧΕΙ παραπομπή.
  · ΔΕΝ είναι read-ledger: δεν λέει τι ΔΙΑΒΑΣΕ ο πράκτορας.

ΤΙ ΑΛΛΑΞΕ ΑΠΟ ΤΟΝ v4 — ΤΡΕΙΣ ΔΟΜΙΚΕΣ ΤΟΜΕΣ
────────────────────────────────────────────
① ΤΟ TSV ΔΕΝ ΕΙΝΑΙ ΠΛΕΟΝ ΑΥΘΕΝΤΙΑ. Ο v4 εμπιστευόταν το manifest: μια
   κατασκευασμένη γραμμή για ΑΝΥΠΑΡΚΤΟ αρχείο περνούσε. Τώρα κάθε αρχείο που
   παραπέμπεται ΕΛΕΓΧΕΤΑΙ ΣΤΟΝ ΔΙΣΚΟ (lstat · κανονικό αρχείο · κανένα
   symlink component · containment μετά από canonical resolution · πραγματικό
   sha256 · πραγματικά bytes · πραγματικές λογικές γραμμές).
② Η ΤΑΥΤΟΤΗΤΑ ΤΟΥ MANIFEST ΞΑΝΑΫΠΟΛΟΓΙΖΕΤΑΙ από τις ΙΔΙΕΣ τις γραμμές του TSV
   και αντιπαραβάλλεται με τη σφραγισμένη αυθεντία. Πείραγμα του TSV αλλάζει
   τη ρίζα ⇒ η πύλη κοκκινίζει ΠΡΙΝ κοιτάξει έστω μία παραπομπή.
③ FAIL-CLOSED ΓΡΑΜΜΑΤΙΚΗ. Ο v4 ανίχνευε παραπομπές με έναν regex: ό,τι δεν
   ταίριαζε ΔΕΝ ΥΠΗΡΧΕ. Τώρα η ανίχνευση είναι ΕΠΙΤΡΕΠΤΙΚΗ και η επικύρωση
   ΑΥΣΤΗΡΗ: κακοσχηματισμένη παραπομπή ΑΝΑΦΕΡΕΤΑΙ, δεν αγνοείται σιωπηλά.

ΔΥΟ ΚΑΙ ΜΟΝΟ ΔΥΟ ΜΟΡΦΕΣ — η βάση ΔΗΛΩΝΕΤΑΙ, δεν μαντεύεται:
  ① MOUNT-ANCHORED   /frozen/ro/<path>:L…
  ② CORPUS-RELATIVE  <path>:L…
ΚΑΜΙΑ fallback cluster-relative επίλυση.

ΣΥΝΤΑΞΗ ΠΑΡΑΠΟΜΠΗΣ — PROTOCOL.sexp:35 «path:Lstart-Lend@sha256:<12>»
Το hash είναι ΑΚΡΙΒΩΣ 12 δεκαεξαδικά. ΟΧΙ 6-64. ΟΧΙ trailing garbage.
"""
import hashlib
import json
import os
import re
import stat
import sys

RESOLVER_VERSION = "5"
MANIFEST = "experiment/artifacts/corpus-manifest.tsv"
AUTHORITY = "experiment/phase1a/LANE-SCOPE-AUTHORITY.sexp"

# Η ΔΙΑΔΡΟΜΗ ΤΟΥ MOUNT ΔΕΝ ΕΙΝΑΙ ΣΤΑΘΕΡΑ ΚΩΔΙΚΑ. Δηλώνεται στη ΣΦΡΑΓΙΣΜΕΝΗ
# αυθεντία εμβέλειας, μαζί με commit/tree/ταυτότητα/roots — μία έδρα. Αυτό ΔΕΝ
# είναι κερκόπορτα: κάθε receipt δένεται στο sha256 της αυθεντίας, άρα αλλαγή
# του mount ΑΛΛΑΖΕΙ το hash και γίνεται ΟΡΑΤΗ σε κάθε απόδειξη.
MOUNT = None
MOUNT_REAL = None

MANIFEST_COLUMNS = ("path", "git_mode", "kind", "git_blob_sha1", "content_sha256",
                    "bytes", "logical_lines", "trailing_newline", "class")
MODE_KIND = {"100644": "file", "100755": "executable", "120000": "symlink"}
CITABLE_KINDS = {"file", "executable"}
LINES_BINARY = -1
LINES_SYMLINK = -2
SHA_PREFIX_LEN = 12                      # PROTOCOL.sexp:35 — ΑΚΡΙΒΩΣ 12

EXT = ("lisp|asd|md|sexp|sh|py|js|mjs|ts|json|jsonld|yml|yaml|ttl|txt|cddl|zip")
PATHCHARS = r"A-Za-z0-9_./\-Ͱ-Ͽἀ-῿"

# ΣΤΑΔΙΟ 1 — ΑΝΙΧΝΕΥΣΗ ΑΠΟΠΕΙΡΑΣ ΠΑΡΑΠΟΜΠΗΣ.
# «path:» ακολουθούμενο από ψηφίο Ή από literal «L»+ψηφίο ΕΙΝΑΙ απόπειρα και
# ΚΡΙΝΕΤΑΙ. Οτιδήποτε άλλο («…verify-deps.sh: το σενάριο…») είναι πρόζα και
# ΔΕΝ μετριέται. Το <rest> μαζεύει ΟΛΟ το token μαζί με τυχόν σκουπίδι, ώστε
# ο validator να κρίνει ΟΛΟΚΛΗΡΟ — ποτέ μόνο το έγκυρο πρόθεμά του.
# Τελεία μετριέται ΜΟΝΟ αν ακολουθείται από αλφαριθμητικό (αλλιώς είναι
# τελεία πρότασης). ΚΟΜΜΑ μετριέται ΜΟΝΟ αν ακολουθείται από L/ψηφίο — τότε
# είναι ΛΙΣΤΑ ΚΟΜΜΑΤΟΣ, που το πρωτόκολλο ΑΠΑΓΟΡΕΥΕΙ και η πύλη ΠΡΕΠΕΙ να
# απορρίψει ΟΛΟΚΛΗΡΗ. Χωρίς αυτό, ο σαρωτής θα δεχόταν το πρώτο στοιχείο και
# θα ΑΓΝΟΟΥΣΕ σιωπηλά τα υπόλοιπα — η ακριβής τυφλότητα που έκρυβε 506
# αναφορές γραμμών. Το κόμμα ως στίξη πρότασης ΔΕΝ επηρεάζεται.
SCAN = re.compile(
    rf'(?<![\w./-])(?P<path>/?\.?[{PATHCHARS}]+\.(?:{EXT}))'
    rf':(?P<rest>(?:L(?=\d)|(?=\d))'
    rf'(?:[0-9A-Za-z@:_+\-]|\.(?=[0-9A-Za-z])|,(?=\s*L?\d))+)')

# ΣΤΑΔΙΟ 2 — ΚΑΝΟΝΙΣΤΙΚΗ ΜΟΡΦΗ. FULLMATCH ΟΛΟΚΛΗΡΟΥ του token.
# PROTOCOL: path:L<start>-L<end>@sha256:<12 πεζά δεκαεξαδικά>
# ΑΠΑΙΤΟΥΝΤΑΙ start ΚΑΙ end ΚΑΙ ακριβώς 12 hex. Καμία παράλειψη.
CANONICAL = re.compile(r'\AL(?P<start>\d+)-L(?P<end>\d+)@sha256:(?P<sha>[0-9a-f]{12})\Z')

# ΣΤΑΔΙΟ 3 — ΔΙΑΓΝΩΣΗ ΜΟΝΟ. Ό,τι πιάνεται εδώ ΑΠΟΡΡΙΠΤΕΤΑΙ ως legacy
# shorthand· δεν γίνεται ΠΟΤΕ δεκτό. Χρησιμεύει για να ονομαστεί το σφάλμα
# και να τροφοδοτηθεί η ντετερμινιστική κανονικοποίηση.
LEGACY = re.compile(
    r'\AL?(?P<start>\d+)(?:\s*-\s*L?(?P<end>\d+))?'
    r'(?:@sha256:(?P<sha>[0-9a-fA-F]+))?\Z')

CODE_LEGACY = "LEGACY-SHORTHAND — ΟΧΙ κανονιστική μορφή path:L<start>-L<end>@sha256:<12>"
CODE_MALFORMED = "ΚΑΚΟΣΧΗΜΑΤΙΣΜΕΝΗ ΠΑΡΑΠΟΜΠΗ — δεν ερμηνεύεται ούτε ως legacy"


class GateFailure(Exception):
    pass


# ══ FAIL-CLOSED S-EXPRESSION PARSER ═══════════════════════════════════════
def sexp_tokens(text, where):
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c in " \t\n\r\f":
            i += 1
            continue
        if c == ";":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if c == '"':
            start_line = text.count("\n", 0, i) + 1
            i += 1
            out, closed = [], False
            while i < n:
                if text[i] == "\\":
                    if i + 1 >= n:
                        raise GateFailure(
                            f"{where}: DANGLING ESCAPE — «\\» στο τέλος του αρχείου "
                            f"(συμβολοσειρά από γραμμή {start_line})")
                    out.append(text[i + 1])
                    i += 2
                    continue
                if text[i] == '"':
                    i += 1
                    closed = True
                    break
                out.append(text[i])
                i += 1
            if not closed:
                raise GateFailure(
                    f"{where}: UNTERMINATED STRING που άνοιξε στη γραμμή {start_line}")
            yield ("str", "".join(out))
            continue
        if c in "()":
            yield ("paren", c)
            i += 1
            continue
        j = i
        while j < n and text[j] not in " \t\n\r\f()\";":
            j += 1
        yield ("atom", text[i:j])
        i = j


def sexp_parse(text, where):
    stack, out = [], []
    for kind, tok in sexp_tokens(text, where):
        if kind == "paren" and tok == "(":
            new = []
            (stack[-1] if stack else out).append(new)
            stack.append(new)
        elif kind == "paren" and tok == ")":
            if not stack:
                raise GateFailure(f"{where}: αταίριαστη «)»")
            stack.pop()
        else:
            (stack[-1] if stack else out).append(("S", tok) if kind == "str" else tok)
    if stack:
        raise GateFailure(f"{where}: {len(stack)} ΜΗ ΚΛΕΙΣΜΕΝΕΣ παρενθέσεις")
    return out


def _walk(node):
    if isinstance(node, list):
        yield node
        for x in node:
            yield from _walk(x)


def plist_keys(node):
    """Κλειδιά «:foo» σε θέση κλειδιού μιας plist-like λίστας."""
    keys = []
    k = 0
    while k < len(node) - 1:
        tok = node[k]
        if isinstance(tok, str) and tok.startswith(":"):
            keys.append((tok, k))
            k += 2
        else:
            k += 1
    return keys


def load_lane_roots(lane_id):
    where = f"SCOPE-AUTHORITY «{AUTHORITY}»"
    if not os.path.isfile(AUTHORITY):
        raise GateFailure(f"ΑΠΩΝ το scope authority: {AUTHORITY}")
    forms = sexp_parse(open(AUTHORITY, encoding="utf-8", errors="strict").read(), where)
    hits = [node for node in _walk(forms)
            if any(node[k] == ":lane" and node[k + 1] == ("S", lane_id)
                   for k in range(len(node) - 1))]
    if len(hits) != 1:
        raise GateFailure(
            f"LANE «{lane_id}»: {len(hits)} εγγραφές στο scope authority — απαιτείται ΑΚΡΙΒΩΣ 1")
    entry = hits[0]

    seen = {}
    for key, _ in plist_keys(entry):
        if key in seen:
            raise GateFailure(f"LANE «{lane_id}»: ΔΙΠΛΟ κλειδί «{key}» στην εγγραφή")
        seen[key] = True

    idx = [k for k in range(len(entry) - 1) if entry[k] == ":cluster-roots"]
    if len(idx) == 0:
        raise GateFailure(f"LANE «{lane_id}»: ΑΠΩΝ :cluster-roots")
    if len(idx) > 1:
        raise GateFailure(f"LANE «{lane_id}»: {len(idx)}× :cluster-roots — απαιτείται ΑΚΡΙΒΩΣ 1")
    val = entry[idx[0] + 1]
    if not isinstance(val, list):
        raise GateFailure(f"LANE «{lane_id}»: :cluster-roots δεν είναι λίστα")
    if not val:
        raise GateFailure(f"LANE «{lane_id}»: ΚΕΝΟ :cluster-roots")
    roots = []
    for v in val:
        if not (isinstance(v, tuple) and v[0] == "S"):
            raise GateFailure(
                f"LANE «{lane_id}»: ΜΗ-ΣΥΜΒΟΛΟΣΕΙΡΑ root {v!r} — τα roots είναι ΠΑΝΤΑ strings")
        r = v[1]
        if not r or r.startswith("/") or ".." in r.split("/") or r.endswith("/"):
            raise GateFailure(f"LANE «{lane_id}»: ΑΚΥΡΟ cluster-root «{r}»")
        roots.append(r)
    if len(set(roots)) != len(roots):
        raise GateFailure(f"LANE «{lane_id}»: ΔΙΠΛΟΤΥΠΟ root στο :cluster-roots")
    return roots


def _authority_string(key):
    where = f"SCOPE-AUTHORITY «{AUTHORITY}»"
    if not os.path.isfile(AUTHORITY):
        raise GateFailure(f"ΑΠΩΝ το scope authority: {AUTHORITY}")
    forms = sexp_parse(open(AUTHORITY, encoding="utf-8", errors="strict").read(), where)
    hits = [node[k + 1][1] for node in _walk(forms) for k in range(len(node) - 1)
            if node[k] == key and isinstance(node[k + 1], tuple) and node[k + 1][0] == "S"]
    if len(hits) != 1:
        raise GateFailure(f"{where}: {len(hits)} τιμές για «{key}» — απαιτείται ΑΚΡΙΒΩΣ 1")
    return hits[0]


def load_authority_identity():
    return _authority_string(":identity")


def load_authority_mount():
    m = _authority_string(":read-only-mount")
    if not m.startswith("/") or m.endswith("/"):
        raise GateFailure(f"SCOPE-AUTHORITY: ΑΚΥΡΟ :read-only-mount «{m}»")
    return m


def root_matcher(roots):
    dirs, globs = [], []
    for r in roots:
        if "*" in r:
            globs.append(re.compile(
                "".join("[^/]*" if ch == "*" else re.escape(ch) for ch in r) + r"\Z"))
        else:
            dirs.append(r)

    def matches(rel):
        return (any(rel == d or rel.startswith(d + "/") for d in dirs)
                or any(g.match(rel) for g in globs))
    return matches


# ══ MANIFEST — ΑΥΣΤΗΡΗ ΣΥΝΟΧΗ ═════════════════════════════════════════════
def load_manifest(path):
    if not os.path.isfile(path):
        raise GateFailure(f"ΑΠΩΝ manifest: {path}")
    index, order = {}, []
    with open(path, encoding="utf-8", errors="strict") as fh:
        header = fh.readline().rstrip("\n")
        expect = "#" + "\t".join(MANIFEST_COLUMNS)
        if header != expect:
            raise GateFailure(f"MANIFEST: ΛΑΘΟΣ ΚΕΦΑΛΙΔΑ.\n  βρέθηκε: {header}\n  αναμ.  : {expect}")
        for lineno, line in enumerate(fh, 2):
            if line.endswith("\n"):
                line = line[:-1]
            if not line:
                raise GateFailure(f"MANIFEST γραμμή {lineno}: ΚΕΝΗ ΓΡΑΜΜΗ")
            parts = line.split("\t")
            if len(parts) != len(MANIFEST_COLUMNS):
                raise GateFailure(
                    f"MANIFEST γραμμή {lineno}: {len(parts)} πεδία, αναμ. {len(MANIFEST_COLUMNS)}")
            rel, mode, kind, blob, csha, nb, nl, tr, cls = parts
            if rel in index:
                raise GateFailure(f"MANIFEST γραμμή {lineno}: ΔΙΠΛΗ διαδρομή «{rel}»")
            if not rel or rel.startswith("/") or ".." in rel.split("/"):
                raise GateFailure(f"MANIFEST γραμμή {lineno}: ΑΚΥΡΗ διαδρομή «{rel}»")
            if mode not in MODE_KIND:
                raise GateFailure(f"MANIFEST γραμμή {lineno}: ΑΓΝΩΣΤΟ git mode «{mode}»")
            if MODE_KIND[mode] != kind:
                raise GateFailure(
                    f"MANIFEST γραμμή {lineno}: mode «{mode}» ⇒ «{MODE_KIND[mode]}», βρέθηκε kind «{kind}»")
            if not re.fullmatch(r"[0-9a-f]{40}", blob):
                raise GateFailure(f"MANIFEST γραμμή {lineno}: ΑΚΥΡΟ git blob sha1")
            if not re.fullmatch(r"[0-9a-f]{64}", csha):
                raise GateFailure(f"MANIFEST γραμμή {lineno}: μη πλήρες content sha256")
            try:
                nb_i, nl_i, tr_i = int(nb), int(nl), int(tr)
            except ValueError:
                raise GateFailure(f"MANIFEST γραμμή {lineno}: μη αριθμητικά πεδία")
            if nb_i < 0:
                raise GateFailure(f"MANIFEST γραμμή {lineno}: αρνητικά bytes")
            if tr_i not in (0, 1):
                raise GateFailure(f"MANIFEST γραμμή {lineno}: trailing_newline ∉ {{0,1}}")
            if cls not in ("text", "binary", "symlink"):
                raise GateFailure(f"MANIFEST γραμμή {lineno}: ΑΓΝΩΣΤΗ class «{cls}»")
            # ── ΣΥΝΟΧΗ kind × class × γραμμές × μέγεθος ──
            if kind == "symlink":
                if cls != "symlink" or nl_i != LINES_SYMLINK or tr_i != 0:
                    raise GateFailure(f"MANIFEST γραμμή {lineno}: ασυνεπές symlink")
            else:
                if cls == "symlink":
                    raise GateFailure(f"MANIFEST γραμμή {lineno}: class symlink σε μη-symlink")
                if cls == "binary" and (nl_i != LINES_BINARY or tr_i != 0):
                    raise GateFailure(f"MANIFEST γραμμή {lineno}: ασυνεπές binary")
                if cls == "text":
                    if nl_i < 0:
                        raise GateFailure(f"MANIFEST γραμμή {lineno}: text με αρνητικές γραμμές")
                    if nb_i == 0 and (nl_i != 0 or tr_i != 1):
                        raise GateFailure(f"MANIFEST γραμμή {lineno}: κενό text ⇒ 0 γραμμές, trailing 1")
                    if nb_i > 0 and nl_i == 0:
                        raise GateFailure(f"MANIFEST γραμμή {lineno}: {nb_i} bytes αλλά 0 γραμμές")
                    if nl_i > nb_i:
                        raise GateFailure(f"MANIFEST γραμμή {lineno}: {nl_i} γραμμές > {nb_i} bytes")
            index[rel] = {"mode": mode, "kind": kind, "blob": blob, "sha256": csha,
                          "bytes": nb_i, "lines": nl_i, "trailing": tr_i, "class": cls}
            order.append((rel, mode, kind, csha, nb_i))
    if not index:
        raise GateFailure("MANIFEST ΚΕΝΟ — καμία ψευδο-επιτυχία")
    return index, order


def manifest_identity(order):
    """ΞΑΝΑΫΠΟΛΟΓΙΣΜΟΣ της PATH-AND-KIND-COMPLETE ρίζας ΑΠΟ ΤΟ ΙΔΙΟ ΤΟ TSV.
    Ίδιος ορισμός με τον παραγωγό: length-prefixed preimage, RFC 6962/9162,
    αυστηρή δύναμη του 2, ΠΟΤΕ duplicate-last."""
    def lp(b):
        return len(b).to_bytes(4, "big") + b
    leaves = []
    for rel, mode, kind, csha, nb in sorted(order, key=lambda e: e[0].encode("utf-8")):
        pre = (lp(rel.encode("utf-8")) + lp(mode.encode()) + lp(kind.encode())
               + bytes.fromhex(csha) + nb.to_bytes(8, "big"))
        leaves.append(hashlib.sha256(b"\x00" + pre).hexdigest())

    def node(ls):
        if len(ls) == 1:
            return ls[0]
        k = 1
        while k * 2 < len(ls):
            k *= 2
        return hashlib.sha256(b"\x01" + bytes.fromhex(node(ls[:k]))
                              + bytes.fromhex(node(ls[k:]))).hexdigest()
    return "sha256:" + (node(leaves) if leaves else hashlib.sha256(b"").hexdigest())


# ══ ΠΥΛΗ MOUNT ════════════════════════════════════════════════════════════
def require_frozen_mount():
    """ΑΥΘΕΝΤΙΚΗ πηγή: /proc/self/mountinfo. ΟΧΙ os.path.ismount — αυτό
    συγκρίνει st_dev γονέα/παιδιού και ΑΠΟΤΥΓΧΑΝΕΙ σε bind mount στο ΙΔΙΟ
    filesystem, που είναι ακριβώς η περίπτωση του παγωμένου corpus."""
    with open("/proc/self/mountinfo", encoding="utf-8") as fh:
        for line in fh:
            f = line.split()
            if len(f) > 5 and f[4] == MOUNT:
                if "ro" not in set(f[5].split(",")):
                    raise GateFailure(f"ΤΟ {MOUNT} ΕΙΝΑΙ MOUNT ΑΛΛΑ ΟΧΙ read-only")
                return
    raise GateFailure(
        f"ΤΟ {MOUNT} ΔΕΝ ΕΙΝΑΙ MOUNT (καμία εγγραφή στο /proc/self/mountinfo). "
        f"Τρέξε ensure-ro-mount.sh. Καμία πύλη δεν κρίνει χωρίς την πηγή.")


# ══ ΠΡΑΓΜΑΤΙΚΟΣ ΕΛΕΓΧΟΣ ΑΡΧΕΙΟΥ — ΤΟ TSV ΔΕΝ ΕΙΝΑΙ ΑΥΘΕΝΤΙΑ ══════════════
_filecache = {}


def open_anchored(rel):
    """DESCRIPTOR-ANCHORED ΑΝΟΙΓΜΑ. ΟΧΙ «lstat → realpath → open»: εκείνο
    αφήνει παράθυρο μεταβολής ΑΝΑΜΕΣΑ στον έλεγχο και στην ανάγνωση (TOCTOU),
    και ελέγχει ΑΛΛΟ αντικείμενο από αυτό που τελικά διαβάζει.

    Εδώ κατεβαίνουμε συστατικό-συστατικό με openat(2) και O_NOFOLLOW:
      · κάθε ενδιάμεσο συστατικό ανοίγει ως ΚΑΤΑΛΟΓΟΣ, χωρίς ακολούθηση
      · το τελικό ανοίγει χωρίς ακολούθηση
    Άρα symlink traversal είναι ΔΟΜΙΚΑ αδύνατο — ούτε απαγορευμένο ούτε
    ελεγχόμενο εκ των υστέρων — και containment προκύπτει από την κατασκευή:
    ποτέ δεν φεύγουμε από το descriptor του mount. Το fstat και το read
    αφορούν ΤΟΝ ΙΔΙΟ descriptor, άρα ΤΟ ΙΔΙΟ inode.
    Επιστρέφει fd ή σηκώνει OSError.
    """
    parts = rel.split("/")
    dfd = os.open(MOUNT, os.O_RDONLY | os.O_DIRECTORY)
    try:
        for comp in parts[:-1]:
            if comp in ("", ".", ".."):
                raise OSError(22, "ΑΚΥΡΟ ΣΥΣΤΑΤΙΚΟ ΔΙΑΔΡΟΜΗΣ")
            nfd = os.open(comp, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=dfd)
            os.close(dfd)
            dfd = nfd
        return os.open(parts[-1], os.O_RDONLY | os.O_NOFOLLOW, dir_fd=dfd)
    finally:
        os.close(dfd)


def verify_file(rel, meta):
    """Επιστρέφει (ok, why, real_lines). ΟΛΑ ελέγχονται ΣΤΟΝ ΙΔΙΟ descriptor."""
    if rel in _filecache:
        return _filecache[rel]

    def out(ok, why, lines=None):
        _filecache[rel] = (ok, why, lines)
        return _filecache[rel]

    try:
        fd = open_anchored(rel)
    except OSError as e:
        if e.errno == 40:      # ELOOP — O_NOFOLLOW χτύπησε symlink
            return out(False, "SYMLINK ΣΤΗ ΔΙΑΔΡΟΜΗ — δομικά απορρίπτεται (O_NOFOLLOW)")
        if e.errno == 20:      # ENOTDIR
            return out(False, "ΣΥΣΤΑΤΙΚΟ ΔΙΑΔΡΟΜΗΣ ΔΕΝ ΕΙΝΑΙ ΚΑΤΑΛΟΓΟΣ")
        return out(False, f"ΔΕΝ ΑΝΟΙΓΕΙ ΣΤΟ ΠΑΓΩΜΕΝΟ MOUNT (errno {e.errno})")
    try:
        st = os.fstat(fd)
        if not stat.S_ISREG(st.st_mode):
            return out(False, "ΔΕΝ ΕΙΝΑΙ ΚΑΝΟΝΙΚΟ ΑΡΧΕΙΟ")
        data = b""
        while True:
            chunk = os.read(fd, 1 << 20)
            if not chunk:
                break
            data += chunk
    finally:
        os.close(fd)

    if len(data) != meta["bytes"]:
        return out(False, f"ΠΡΑΓΜΑΤΙΚΑ BYTES {len(data)} ≠ manifest {meta['bytes']}")
    real_sha = hashlib.sha256(data).hexdigest()
    if real_sha != meta["sha256"]:
        return out(False, f"ΠΡΑΓΜΑΤΙΚΟ SHA-256 {real_sha[:16]}… ≠ manifest {meta['sha256'][:16]}…")
    if meta["class"] == "text":
        try:
            text = data.decode("utf-8")
        except UnicodeDecodeError:
            return out(False, "manifest λέει text αλλά ΔΕΝ αποκωδικοποιείται ως UTF-8")
        real_lines = 0 if text == "" else (
            text.count("\n") if text.endswith("\n") else text.count("\n") + 1)
        if real_lines != meta["lines"]:
            return out(False, f"ΠΡΑΓΜΑΤΙΚΕΣ ΓΡΑΜΜΕΣ {real_lines} ≠ manifest {meta['lines']}")
        return out(True, None, real_lines)
    return out(True, None, meta["lines"])


def normalize(raw):
    if ".." in raw.split("/"):
        return None, None, "PATH TRAVERSAL: περιέχει «..»"
    if raw.startswith("/"):
        if not raw.startswith(FROZEN_MOUNT_PREFIX):
            return None, None, f"ΜΗ ΔΗΛΩΜΕΝΗ ΜΟΡΦΗ: absolute εκτός {FROZEN_MOUNT_PREFIX}"
        rest = raw[len(FROZEN_MOUNT_PREFIX):]
        if not rest:
            return None, None, "ΚΕΝΗ διαδρομή μετά το mount prefix"
        return rest, "mount-anchored", None
    return raw, "corpus-relative", None


def main():
    global MOUNT, MOUNT_REAL, FROZEN_MOUNT_PREFIX
    args = list(sys.argv[1:])
    if args.count("--lane") != 1:
        print(f"::error::--lane ΥΠΟΧΡΕΩΤΙΚΟ και ΜΟΝΑΔΙΚΟ (βρέθηκε {args.count('--lane')}×)")
        return 2
    i = args.index("--lane")
    if i + 1 >= len(args):
        print("::error::--lane χωρίς τιμή")
        return 2
    lane_id = args[i + 1]
    del args[i:i + 2]

    diag_out = None
    if "--diagnostic" in args:
        j = args.index("--diagnostic")
        if j + 1 >= len(args):
            print("::error::--diagnostic χωρίς τιμή")
            return 2
        diag_out = args[j + 1]
        del args[j:j + 2]

    try:
        MOUNT = load_authority_mount()
        FROZEN_MOUNT_PREFIX = MOUNT + "/"
        require_frozen_mount()
        MOUNT_REAL = os.path.realpath(MOUNT)
        lane_roots = load_lane_roots(lane_id)
        in_cluster_p = root_matcher(lane_roots)
        sealed_identity = load_authority_identity()
        index, order = load_manifest(MANIFEST)
        recomputed = manifest_identity(order)
        if recomputed != sealed_identity:
            raise GateFailure(
                "ΤΑΥΤΟΤΗΤΑ MANIFEST ΔΕΝ ΤΑΙΡΙΑΖΕΙ ΜΕ ΤΗ ΣΦΡΑΓΙΣΜΕΝΗ ΑΥΘΕΝΤΙΑ.\n"
                f"  ξαναϋπολογισμένη από το TSV : {recomputed}\n"
                f"  σφραγισμένη στην αυθεντία   : {sealed_identity}")
    except GateFailure as e:
        print(f"::error::{e}")
        return 2

    missing = [p for p in args if not os.path.isfile(p)]
    if missing:
        for p in missing:
            print(f"::error::ΑΠΩΝ ή ΜΗ ΚΑΝΟΝΙΚΟ ΑΡΧΕΙΟ: {p}")
        return 2
    if not args:
        print("::error::ΚΑΜΙΑ είσοδος — καμία ψευδο-επιτυχία")
        return 2

    self_sha = hashlib.sha256(open(__file__, "rb").read()).hexdigest()
    manifest_sha = hashlib.sha256(open(MANIFEST, "rb").read()).hexdigest()
    authority_sha = hashlib.sha256(open(AUTHORITY, "rb").read()).hexdigest()

    total = resolved = in_cluster = 0
    by_form = {"mount-anchored": 0, "corpus-relative": 0}
    problems, dossier_hashes, diagnostic = [], {}, []

    for path in args:
        dossier_hashes[path] = hashlib.sha256(open(path, "rb").read()).hexdigest()
        try:
            text = open(path, encoding="utf-8", errors="strict").read()
        except UnicodeDecodeError as e:
            print(f"::error::MALFORMED UTF-8 στο {path}: {e}")
            return 2
        seen = set()
        for m in SCAN.finditer(text):
            raw, rest = m.group("path"), m.group("rest")
            token = m.group(0)
            if (raw, rest) in seen:
                continue
            seen.add((raw, rest))
            total += 1

            rec = {"dossier": path, "token": token, "path": raw, "rest": rest,
                   "offset": m.start(1), "line": text.count("\n", 0, m.start(1)) + 1}

            cm = CANONICAL.match(rest)
            lm = None if cm else LEGACY.match(rest)
            if not cm:
                rec["form"] = "legacy" if lm else "malformed"
                rec["code"] = CODE_LEGACY if lm else CODE_MALFORMED
                if lm:
                    rec["legacy_start"] = int(lm.group("start"))
                    rec["legacy_end"] = int(lm.group("end")) if lm.group("end") else None
                    rec["legacy_sha"] = lm.group("sha")
                rel, form, why = normalize(raw)
                if rel is not None and rel in index:
                    meta = index[rel]
                    rec["resolves_to"] = rel
                    rec["real_sha12"] = meta["sha256"][:SHA_PREFIX_LEN]
                    ok, w, rl = verify_file(rel, meta)
                    rec["real_lines"] = rl
                    rec["file_ok"] = ok
                    if not ok:
                        rec["file_why"] = w
                diagnostic.append(rec)
                problems.append((path, token, rec["code"]))
                continue

            rec["form"] = "canonical"
            start, end, sha12 = int(cm.group("start")), int(cm.group("end")), cm.group("sha")

            rel, form, why = normalize(raw)
            if rel is None:
                rec["code"] = why
                diagnostic.append(rec)
                problems.append((path, token, why))
                continue
            rec["resolves_to"] = rel
            meta = index.get(rel)
            if meta is None:
                rec["code"] = "ΑΓΝΩΣΤΗ ΔΙΑΔΡΟΜΗ στο manifest"
                diagnostic.append(rec)
                problems.append((path, token, rec["code"]))
                continue
            if meta["kind"] not in CITABLE_KINDS:
                rec["code"] = f"ΜΗ ΠΑΡΑΠΕΜΨΙΜΟ kind «{meta['kind']}»"
                diagnostic.append(rec)
                problems.append((path, token, rec["code"]))
                continue
            if meta["class"] != "text":
                rec["code"] = f"class «{meta['class']}» — δεν έχει γραμμές"
                diagnostic.append(rec)
                problems.append((path, token, rec["code"]))
                continue

            ok, why, real_lines = verify_file(rel, meta)
            rec["real_lines"] = real_lines
            rec["real_sha12"] = meta["sha256"][:SHA_PREFIX_LEN]
            if not ok:
                rec["code"] = f"ΕΛΕΓΧΟΣ ΑΡΧΕΙΟΥ ΑΠΕΤΥΧΕ: {why}"
                diagnostic.append(rec)
                problems.append((path, token, rec["code"]))
                continue
            if end < start:
                rec["code"] = "ΑΝΑΠΟΔΟ ΕΥΡΟΣ"
                diagnostic.append(rec)
                problems.append((path, token, rec["code"]))
                continue
            if start < 1 or end > real_lines:
                rec["code"] = f"ΕΚΤΟΣ ΕΥΡΟΥΣ: το αρχείο έχει {real_lines} λογικές γραμμές"
                diagnostic.append(rec)
                problems.append((path, token, rec["code"]))
                continue
            if not meta["sha256"].startswith(sha12):
                rec["code"] = f"ΛΑΘΟΣ HASH: manifest {meta['sha256'][:SHA_PREFIX_LEN]}"
                diagnostic.append(rec)
                problems.append((path, token, rec["code"]))
                continue

            rec["code"] = None
            diagnostic.append(rec)
            resolved += 1
            by_form[form] += 1
            if in_cluster_p(rel):
                in_cluster += 1

    if diag_out:
        with open(diag_out, "w", encoding="utf-8") as fh:
            json.dump(diagnostic, fh, ensure_ascii=False, indent=1)

    print(f"resolver v{RESOLVER_VERSION} sha256:{self_sha}")
    print(f"manifest sha256:{manifest_sha}")
    print(f"scope-authority sha256:{authority_sha}")
    print(f"frozen mount {MOUNT} (read-only, επαληθευμένο στο /proc/self/mountinfo)")
    print(f"corpus-identity {sealed_identity} (ξαναϋπολογισμένη από το TSV: ΤΑΥΤΙΖΕΤΑΙ)")
    print(f"lane {lane_id} · cluster-roots {lane_roots}")
    for p, h in dossier_hashes.items():
        print(f"dossier {p} sha256:{h}")
    print(f"αρχεία επαληθευμένα στο mount: {sum(1 for v in _filecache.values() if v[0])}")
    print(f"παραπομπές: {total} · λύθηκαν: {resolved} · ΠΡΟΒΛΗΜΑΤΙΚΕΣ: {len(problems)}")
    print(f"μορφές: mount-anchored={by_form['mount-anchored']} "
          f"corpus-relative={by_form['corpus-relative']} · "
          f"εντός συστάδας={in_cluster} · εκτός={resolved - in_cluster}")
    for src, cit, why in problems:
        print(f"  ✗ [{src}] {cit} — {why}")
    if total == 0:
        print("::error::ΜΗΔΕΝ παραπομπές — ισχυρισμοί χωρίς άγκυρα δεν γίνονται δεκτοί")
        return 2
    if problems:
        return 1
    print("VERDICT: RECOGNIZED-CITATION-INTEGRITY")
    print("  ΤΙ ΣΗΜΑΙΝΕΙ: κάθε token παραπομπής ΠΟΥ ΑΝΑΓΝΩΡΙΣΤΗΚΕ αντιστοιχεί σε")
    print("  πραγματικά bytes και πραγματικό εύρος του παγωμένου δέντρου.")
    print("  ΤΙ ΔΕΝ ΣΗΜΑΙΝΕΙ: ΔΕΝ αποδεικνύει ότι κάθε claim ΕΧΕΙ παραπομπή")
    print("  (CLAIM-CITATION-COVERAGE: ΑΝΟΙΧΤΟ) ούτε ότι το cited span ΣΤΗΡΙΖΕΙ")
    print("  τον ισχυρισμό (CLAIM-ENTAILMENT: ΑΝΟΙΧΤΟ). Ούτε είναι read-ledger.")
    return 0


sys.exit(main())
