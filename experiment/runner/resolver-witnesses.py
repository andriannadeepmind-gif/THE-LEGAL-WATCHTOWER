#!/usr/bin/env python3
"""ΜΑΡΤΥΡΕΣ ΤΗΣ ΠΥΛΗΣ v6 — ΑΚΡΙΒΗΣ ΣΥΓΚΡΙΣΗ ΕΞΟΔΟΥ.

Κάθε μάρτυρας δηλώνει την ΑΚΡΙΒΗ αναμενόμενη έξοδο. ΔΗΛΩΜΕΝΗ κανονικοποίηση:
οι τιμές sha256 στις γραμμές ταυτότητας γίνονται «<SHA>» (αλλάζουν ανά
στημένο δέντρο). Όλα τα υπόλοιπα συγκρίνονται ΑΥΤΟΛΕΞΕΙ.

Το στημένο δέντρο είναι ΠΡΑΓΜΑΤΙΚΟ tmpfs με ro,nodev,nosuid,noexec — ο v6
δεν κρίνει χωρίς αυτό, άρα ούτε οι μάρτυρές του.

ΚΑΛΥΠΤΕΙ ΡΗΤΑ την αφαίρεση της λίστας επεκτάσεων: extensionless (Dockerfile),
dotfiles (.gitignore), σύνθετα επιθήματα (a.tar.gz), executable leaves.
"""
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = "/home/user/THE-LEGAL-WATCHTOWER"
RESOLVER = os.path.abspath(sys.argv[1] if len(sys.argv) > 1
                           else f"{REPO}/experiment/runner/citation-resolver.py")
COLS = ("path", "git_mode", "kind", "git_blob_sha1", "content_sha256",
        "bytes", "logical_lines", "trailing_newline", "class")
HDR = "#" + "\t".join(COLS)
COMMIT = "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
TREE = "23b7a6f4450f50d151d38e13020bee9872e73bcd"
SCHEMA = 4
DOM = b"LAWMAX-CORPUS-IDENTITY/1\x00"

CORPUS = {
    "alpha/a.lisp":       b"l1\nl2\nl3\n",
    "alpha/nonl.lisp":    b"l1\nl2\nl3",
    "alpha/empty.lisp":   b"",
    "alpha/x.md":         b"x\n",
    "alpha/deep/y.md":    b"y\n",
    "beta/b.lisp":        b"one\ntwo\n",
    "top.md":             b"x\n",
    "Dockerfile":         b"FROM a\nRUN b\n",          # ΧΩΡΙΣ ΕΠΕΚΤΑΣΗ
    ".gitignore":         b"*.o\n*.fasl\n",            # DOTFILE
    "a.tar.gz":           b"not really gz\n",          # ΣΥΝΘΕΤΟ ΕΠΙΘΗΜΑ
}
EXECS = {"beta/run.sh": b"#!/bin/sh\necho hi\n"}       # EXECUTABLE LEAF
SYMLINKS = {"alpha/link.lisp": "a.lisp"}
GHOST = b"ghost\n"


def sha(b):
    return hashlib.sha256(b).hexdigest()


def blob(b):
    h = hashlib.sha1()
    h.update(b"blob %d\0" % len(b))
    h.update(b)
    return h.hexdigest()


def measure(data, kind):
    if kind == "symlink":
        return "symlink", -2, 0
    try:
        t = data.decode("utf-8")
    except UnicodeDecodeError:
        return "binary", -1, 0
    if t == "":
        return "text", 0, 0
    tr = 1 if t.endswith("\n") else 0
    return "text", (t.count("\n") if tr else t.count("\n") + 1), tr


def row_for(rel, data, kind="file"):
    mode = {"file": "100644", "executable": "100755", "symlink": "120000"}[kind]
    cls, lines, tr = measure(data, kind)
    return [rel, mode, kind, blob(data), sha(data), str(len(data)),
            str(lines), str(tr), cls]


def base_rows():
    rows = [row_for(r, d) for r, d in CORPUS.items()]
    rows += [row_for(r, d, "executable") for r, d in EXECS.items()]
    rows += [row_for(r, t.encode(), "symlink") for r, t in SYMLINKS.items()]
    return rows


def lp(b):
    return len(b).to_bytes(4, "big") + b


def identity_of(rows):
    leaves = []
    for r in sorted(rows, key=lambda r: r[0].encode()):
        pre = (lp(r[0].encode()) + lp(r[1].encode()) + lp(r[2].encode())
               + bytes.fromhex(r[4]) + int(r[5]).to_bytes(8, "big"))
        leaves.append(sha(b"\x00" + pre))

    def node(ls):
        if len(ls) == 1:
            return ls[0]
        k = 1
        while k * 2 < len(ls):
            k *= 2
        return sha(b"\x01" + bytes.fromhex(node(ls[:k])) + bytes.fromhex(node(ls[k:])))
    root = node(leaves)
    return "sha256:" + sha(DOM + SCHEMA.to_bytes(4, "big") + bytes.fromhex(COMMIT)
                           + bytes.fromhex(TREE) + bytes.fromhex(root))


AUTH = '''(:lawmax-lane-scope-authority/1
 :read-only-mount "{mount}"
 :identity "{identity}"
 :lanes
 ((:lane "W-DIR"  :cluster-roots ("alpha" "beta"))
  (:lane "W-GLOB" :cluster-roots ("*" "alpha/*.md"))
  (:lane "W-NOROOTS" :dossier "x")
  (:lane "W-EMPTY" :cluster-roots ())
  (:lane "W-BADROOT" :cluster-roots ("/abs"))
  (:lane "W-NONSTRING" :cluster-roots (alpha))
  (:lane "W-DUPROOTS" :cluster-roots ("alpha") :cluster-roots ("beta"))
  (:lane "W-DUPKEY" :dossier "a" :dossier "b" :cluster-roots ("alpha"))
  (:lane "W-DUP" :cluster-roots ("alpha"))
  (:lane "W-DUP" :cluster-roots ("beta"))))
'''


def build_mount(root):
    src, mnt = os.path.join(root, "src"), os.path.join(root, "ro")
    for rel, data in list(CORPUS.items()) + list(EXECS.items()):
        p = os.path.join(src, rel)
        os.makedirs(os.path.dirname(p) or src, exist_ok=True)
        open(p, "wb").write(data)
        if rel in EXECS:
            os.chmod(p, 0o755)
    for rel, target in SYMLINKS.items():
        p = os.path.join(src, rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        os.symlink(target, p)
    os.makedirs(mnt, exist_ok=True)
    subprocess.run(["mount", "--bind", src, mnt], check=True)
    subprocess.run(["mount", "-o", "remount,bind,ro,nodev,nosuid,noexec", mnt],
                   check=True)
    return mnt


NORM = re.compile(r"sha256:[0-9a-f]{64}")
ACCESS = "openat2/RESOLVE_BENEATH|NO_SYMLINKS|NO_XDEV|NO_MAGICLINKS"


def run(work, argv):
    r = subprocess.run([sys.executable, RESOLVER, "--commit", COMMIT,
                        "--tree", TREE] + argv, cwd=work,
                       capture_output=True, text=True)
    return r.returncode, NORM.sub("sha256:<SHA>", r.stdout + r.stderr).strip()


CASES = []


def case(name, kind, exit_code):
    def deco(fn):
        CASES.append((name, kind, exit_code, fn))
        return fn
    return deco


def setup(work, mnt, dossier, rows=None, auth=None, manifest_text=None):
    rows = base_rows() if rows is None else rows
    os.makedirs(os.path.join(work, "experiment/artifacts"), exist_ok=True)
    os.makedirs(os.path.join(work, "experiment/phase1a"), exist_ok=True)
    open(os.path.join(work, "experiment/phase1a/LANE-SCOPE-AUTHORITY.sexp"), "w",
         encoding="utf-8").write(
        auth if auth is not None
        else AUTH.format(mount=mnt, identity=identity_of([r for r in rows if len(r) == 9])))
    mp = os.path.join(work, "experiment/artifacts/corpus-manifest.tsv")
    open(mp, "w", encoding="utf-8").write(
        manifest_text if manifest_text is not None
        else HDR + "\n" + "".join("\t".join(r) + "\n" for r in sorted(rows)))
    if dossier is not None:
        open(os.path.join(work, "d.sexp"), "w", encoding="utf-8").write(dossier)


def C(rel, a, b=None):
    b = a if b is None else b
    body = (SYMLINKS[rel].encode() if rel in SYMLINKS
            else CORPUS.get(rel) or EXECS.get(rel) or GHOST)
    return f"{rel}:L{a}-L{b}@sha256:{sha(body)[:12]}"


A1, A2, A3 = C("alpha/a.lisp", 1), C("alpha/a.lisp", 2), C("alpha/a.lisp", 3)
A4, A0, A31 = C("alpha/a.lisp", 4), C("alpha/a.lisp", 0), C("alpha/a.lisp", 3, 1)
NONL3, XMD, YMD = C("alpha/nonl.lisp", 3), C("alpha/x.md", 1), C("alpha/deep/y.md", 1)
TOP, LINK, GH = C("top.md", 1), C("alpha/link.lisp", 1), C("alpha/ghost.lisp", 1)
DOCKER, GITIG = C("Dockerfile", 1, 2), C(".gitignore", 2)
TARGZ, RUNSH = C("a.tar.gz", 1), C("beta/run.sh", 2)
EMPTY = C("alpha/empty.lisp", 1)
BARE = "a" + A1[len("alpha/a"):]

PASS = "\n".join([
    "VERDICT: RECOGNIZED-CITATION-INTEGRITY",
    "  ΤΙ ΣΗΜΑΙΝΕΙ: κάθε token παραπομπής ΠΟΥ ΑΝΑΓΝΩΡΙΣΤΗΚΕ αντιστοιχεί σε",
    "  πραγματικά bytes και πραγματικό εύρος του παγωμένου snapshot.",
    "  ΤΙ ΔΕΝ ΣΗΜΑΙΝΕΙ: ΔΕΝ αποδεικνύει ότι κάθε claim ΕΧΕΙ παραπομπή",
    "  (CLAIM-CITATION-COVERAGE: ΑΝΟΙΧΤΟ) ούτε ότι το cited span ΣΤΗΡΙΖΕΙ",
    "  τον ισχυρισμό (CLAIM-ENTAILMENT: ΑΝΟΙΧΤΟ). Ούτε είναι read-ledger."])
LEGACY = ("LEGACY-SHORTHAND — ΟΧΙ κανονιστική μορφή "
          "path:L<start>-L<end>@sha256:<12>")
MALF = "ΚΑΚΟΣΧΗΜΑΤΙΣΜΕΝΗ ΠΑΡΑΠΟΜΠΗ — δεν ερμηνεύεται ούτε ως legacy"


def head(mnt, lane, roots, dbytes, fver, tot, res, prob, ma, cr, inc, out):
    return (f"resolver v6 sha256:<SHA>\n"
            f"manifest sha256:<SHA>\n"
            f"scope-authority sha256:<SHA>\n"
            f"frozen mount {mnt} [ro,nodev,nosuid,noexec] · access {ACCESS}\n"
            f"corpus-identity sha256:<SHA> (ξαναϋπολογισμένη από το TSV: ΤΑΥΤΙΖΕΤΑΙ)\n"
            f"lane {lane} · cluster-roots {roots}\n"
            f"dossier d.sexp {dbytes}B sha256:<SHA>\n"
            f"αρχεία επαληθευμένα στο snapshot: {fver}\n"
            f"παραπομπές: {tot} · λύθηκαν: {res} · ΠΡΟΒΛΗΜΑΤΙΚΕΣ: {prob}\n"
            f"μορφές: mount-anchored={ma} corpus-relative={cr} · "
            f"εντός συστάδας={inc} · εκτός={out}")


DIR = "['alpha', 'beta']"
GLOB = "['*', 'alpha/*.md']"


def simple(name, kind, code, dossier, lane, roots, fver, tot, res, prob,
           ma, cr, inc, out, extra=""):
    @case(name, kind, code)
    def _(w, m, _d=dossier, _l=lane, _r=roots, _f=fver, _t=tot, _re=res,
          _p=prob, _ma=ma, _cr=cr, _i=inc, _o=out, _x=extra):
        setup(w, m, _d)
        body = head(m, _l, _r, len(_d.encode()), _f, _t, _re, _p, _ma, _cr, _i, _o)
        return run(w, ["--lane", _l, "d.sexp"]), body + _x


# ═══════════ ΘΕΤΙΚΟΙ — Η ΛΙΣΤΑ ΕΠΕΚΤΑΣΕΩΝ ΕΧΕΙ ΕΞΑΛΕΙΦΘΕΙ ═══════════
simple("P1 corpus-relative", "positive", 0, f'(:x "{A2}")', "W-DIR", DIR,
       1, 1, 1, 0, 0, 1, 1, 0, "\n" + PASS)
simple("P2 ΧΩΡΙΣ ΕΠΕΚΤΑΣΗ — Dockerfile", "positive", 0, f'(:x "{DOCKER}")',
       "W-GLOB", GLOB, 1, 1, 1, 0, 0, 1, 1, 0, "\n" + PASS)
simple("P3 DOTFILE — .gitignore", "positive", 0, f'(:x "{GITIG}")',
       "W-GLOB", GLOB, 1, 1, 1, 0, 0, 1, 1, 0, "\n" + PASS)
simple("P4 ΣΥΝΘΕΤΟ ΕΠΙΘΗΜΑ — a.tar.gz", "positive", 0, f'(:x "{TARGZ}")',
       "W-GLOB", GLOB, 1, 1, 1, 0, 0, 1, 1, 0, "\n" + PASS)
simple("P5 EXECUTABLE LEAF — beta/run.sh (mode 100755)", "positive", 0,
       f'(:x "{RUNSH}")', "W-DIR", DIR, 1, 1, 1, 0, 0, 1, 1, 0, "\n" + PASS)
simple("P6 αρχείο χωρίς τελικό newline", "positive", 0, f'(:x "{NONL3}")',
       "W-DIR", DIR, 1, 1, 1, 0, 0, 1, 1, 0, "\n" + PASS)
simple("P7 glob roots", "positive", 0, f'(:x "{TOP}" "{XMD}" "{YMD}")',
       "W-GLOB", GLOB, 3, 3, 3, 0, 0, 3, 2, 1, "\n" + PASS)
simple("P8 τελεία πρότασης ΔΕΝ είναι σκουπίδι", "positive", 0,
       f'(:x "βλ. {A2}. Επόμενο.")', "W-DIR", DIR, 1, 1, 1, 0, 0, 1, 1, 0, "\n" + PASS)
simple("P9 «path:» χωρίς ψηφίο = πρόζα", "positive", 0,
       f'(:x "στο alpha/a.lisp: κάτι" "{A1}")', "W-DIR", DIR, 1, 1, 1, 0, 0, 1, 1, 0,
       "\n" + PASS)
simple("P10 κόμμα ΣΤΙΞΗΣ", "positive", 0, f'(:x "{A1}, και συνεχίζει")',
       "W-DIR", DIR, 1, 1, 1, 0, 0, 1, 1, 0, "\n" + PASS)


# ═══════════ ΑΡΝΗΤΙΚΟΙ — ΤΕΡΜΑΤΙΚΟΣ ΦΡΑΓΜΟΣ ═══════════
for ch, label in [("/", "κάθετος"), ("%", "τοις εκατό"), ("?", "ερωτηματικό"),
                  ("#", "δίεση"), ("=", "ίσον"), ("%00", "NUL-encoded")]:
    simple(f"N-BOUND «{ch}» ({label}) ΔΕΝ τερματίζει — ΟΛΟ το token πέφτει",
           "negative", 1, f'(:x "{A1}{ch}garbage")', "W-DIR", DIR,
           1, 1, 0, 1, 0, 0, 0, 0, f"\n  ✗ [d.sexp] {A1}{ch}garbage — {MALF}")

# «9» θα έδινε 13 δεκαεξαδικά ⇒ ερμηνεύσιμο ως legacy. Το «z» ΔΕΝ είναι hex,
# άρα το «@sha256:…» δεν κλείνει και το token είναι ΓΝΗΣΙΑ κακοσχηματισμένο.
simple("N-BOUND ουρά με ΜΗ-δεκαεξαδικό γράμμα", "negative", 1,
       f'(:x "{A1}z")', "W-DIR", DIR, 1, 1, 0, 1, 0, 0, 0, 0,
       f"\n  ✗ [d.sexp] {A1}z — {MALF}")
simple("N-BOUND ουρά ψηφίου ⇒ 13 hex ⇒ legacy, ΟΧΙ σιωπηλή αποδοχή",
       "negative", 1, f'(:x "{A1}9")', "W-DIR", DIR, 1, 1, 0, 1, 0, 0, 0, 0,
       f"\n  ✗ [d.sexp] {A1}9 — {LEGACY}")
simple("N-BOUND ΛΙΣΤΑ ΚΟΜΜΑΤΟΣ απαγορευμένη", "negative", 1,
       f'(:x "{A1},L2-L2@sha256:{sha(CORPUS["alpha/a.lisp"])[:12]}")', "W-DIR", DIR,
       1, 1, 0, 1, 0, 0, 0, 0,
       f'\n  ✗ [d.sexp] {A1},L2-L2@sha256:{sha(CORPUS["alpha/a.lisp"])[:12]} — {MALF}')

# ═══════════ ΑΡΝΗΤΙΚΟΙ — ΓΡΑΜΜΑΤΙΚΗ ═══════════
simple("N-GRAM legacy μονή γραμμή", "negative", 1, '(:x "alpha/a.lisp:1")',
       "W-DIR", DIR, 1, 1, 0, 1, 0, 0, 0, 0,
       f"\n  ✗ [d.sexp] alpha/a.lisp:1 — {LEGACY}")
simple("N-GRAM legacy εύρος χωρίς hash", "negative", 1, '(:x "alpha/a.lisp:L1-L3")',
       "W-DIR", DIR, 1, 1, 0, 1, 0, 0, 0, 0,
       f"\n  ✗ [d.sexp] alpha/a.lisp:L1-L3 — {LEGACY}")
simple("N-GRAM χωρίς end", "negative", 1,
       f'(:x "alpha/a.lisp:L1@sha256:{sha(CORPUS["alpha/a.lisp"])[:12]}")',
       "W-DIR", DIR, 1, 1, 0, 1, 0, 0, 0, 0,
       f'\n  ✗ [d.sexp] alpha/a.lisp:L1@sha256:{sha(CORPUS["alpha/a.lisp"])[:12]} — {LEGACY}')
simple("N-GRAM hash 13 hex", "negative", 1,
       f'(:x "alpha/a.lisp:L1-L1@sha256:{sha(CORPUS["alpha/a.lisp"])[:13]}")',
       "W-DIR", DIR, 1, 1, 0, 1, 0, 0, 0, 0,
       f'\n  ✗ [d.sexp] alpha/a.lisp:L1-L1@sha256:{sha(CORPUS["alpha/a.lisp"])[:13]} — {LEGACY}')

# ═══════════ ΑΡΝΗΤΙΚΟΙ — ΕΠΙΛΥΣΗ ═══════════
simple("N-RES γραμμή n+1", "negative", 1, f'(:x "{A4}")', "W-DIR", DIR,
       1, 1, 0, 1, 0, 0, 0, 0,
       f"\n  ✗ [d.sexp] {A4} — ΕΚΤΟΣ ΕΥΡΟΥΣ: το αρχείο έχει 3 λογικές γραμμές")
simple("N-RES γραμμή 0", "negative", 1, f'(:x "{A0}")', "W-DIR", DIR,
       1, 1, 0, 1, 0, 0, 0, 0,
       f"\n  ✗ [d.sexp] {A0} — ΕΚΤΟΣ ΕΥΡΟΥΣ: το αρχείο έχει 3 λογικές γραμμές")
simple("N-RES ανάποδο εύρος", "negative", 1, f'(:x "{A31}")', "W-DIR", DIR,
       1, 1, 0, 1, 0, 0, 0, 0, f"\n  ✗ [d.sexp] {A31} — ΑΝΑΠΟΔΟ ΕΥΡΟΣ")
simple("N-RES ΚΕΝΟ αρχείο δεν έχει γραμμή 1", "negative", 1, f'(:x "{EMPTY}")',
       "W-DIR", DIR, 1, 1, 0, 1, 0, 0, 0, 0,
       f"\n  ✗ [d.sexp] {EMPTY} — ΕΚΤΟΣ ΕΥΡΟΥΣ: το αρχείο έχει 0 λογικές γραμμές")
simple("N-RES symlink", "negative", 1, f'(:x "{LINK}")', "W-DIR", DIR,
       0, 1, 0, 1, 0, 0, 0, 0,
       f"\n  ✗ [d.sexp] {LINK} — ΜΗ ΠΑΡΑΠΕΜΨΙΜΟ kind «symlink»")
simple("N-RES path traversal", "negative", 1, f'(:x "alpha/../{A1}")', "W-DIR", DIR,
       0, 1, 0, 1, 0, 0, 0, 0,
       f"\n  ✗ [d.sexp] alpha/../{A1} — PATH TRAVERSAL: περιέχει «..»")
simple("N-RES ΚΑΜΙΑ cluster-relative fallback", "negative", 1, f'(:x "{BARE}")',
       "W-DIR", DIR, 0, 1, 0, 1, 0, 0, 0, 0,
       f"\n  ✗ [d.sexp] {BARE} — ΑΓΝΩΣΤΗ ΔΙΑΔΡΟΜΗ στο manifest")


def custom():
    @case("N-ARG --lane απών", "negative", 2)
    def _(w, m):
        setup(w, m, f'(:x "{A1}")')
        return run(w, ["d.sexp"]), \
            "::error::--lane ΥΠΟΧΡΕΩΤΙΚΟ και ΜΟΝΑΔΙΚΟ (βρέθηκε 0×)"

    @case("N-ARG --lane διπλό", "negative", 2)
    def _(w, m):
        setup(w, m, f'(:x "{A1}")')
        return run(w, ["--lane", "W-DIR", "--lane", "W-GLOB", "d.sexp"]), \
            "::error::--lane ΥΠΟΧΡΕΩΤΙΚΟ και ΜΟΝΑΔΙΚΟ (βρέθηκε 2×)"

    for lane, msg in [("W-NOSUCH", "0 εγγραφές"), ("W-DUP", "2 εγγραφές")]:
        @case(f"N-AUTH lane «{lane}»", "negative", 2)
        def _(w, m, _l=lane, _s=msg):
            setup(w, m, f'(:x "{A1}")')
            return run(w, ["--lane", _l, "d.sexp"]), \
                (f"::error::LANE «{_l}»: {_s} στο scope authority — "
                 f"απαιτείται ΑΚΡΙΒΩΣ 1")

    for lane, msg in [("W-NOROOTS", "ΑΠΩΝ :cluster-roots"),
                      ("W-EMPTY", "ΚΕΝΟ :cluster-roots"),
                      ("W-BADROOT", "ΑΚΥΡΟ cluster-root «/abs»"),
                      ("W-NONSTRING", "ΜΗ-ΣΥΜΒΟΛΟΣΕΙΡΑ root 'alpha' — "
                                      "τα roots είναι ΠΑΝΤΑ strings"),
                      ("W-DUPROOTS", "ΔΙΠΛΟ κλειδί «:cluster-roots» στην εγγραφή"),
                      ("W-DUPKEY", "ΔΙΠΛΟ κλειδί «:dossier» στην εγγραφή")]:
        @case(f"N-AUTH {lane}", "negative", 2)
        def _(w, m, _l=lane, _s=msg):
            setup(w, m, f'(:x "{A1}")')
            return run(w, ["--lane", _l, "d.sexp"]), f"::error::LANE «{_l}»: {_s}"

    @case("N-IN απών dossier", "negative", 2)
    def _(w, m):
        setup(w, m, f'(:x "{A1}")')
        return run(w, ["--lane", "W-DIR", "d.sexp", "ΛΕΙΠΕΙ.sexp"]), \
            "::error::ΑΠΩΝ ή ΜΗ ΚΑΝΟΝΙΚΟ ΑΡΧΕΙΟ: ΛΕΙΠΕΙ.sexp"

    @case("N-IN καμία είσοδος", "negative", 2)
    def _(w, m):
        setup(w, m, f'(:x "{A1}")')
        return run(w, ["--lane", "W-DIR"]), \
            "::error::ΚΑΜΙΑ είσοδος — καμία ψευδο-επιτυχία"

    @case("N-IN μηδέν παραπομπές", "negative", 2)
    def _(w, m):
        d = '(:x "καμία άγκυρα")'
        setup(w, m, d)
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", DIR, len(d.encode()), 0, 0, 0, 0, 0, 0, 0, 0) +
             "\n::error::ΜΗΔΕΝ παραπομπές — ισχυρισμοί χωρίς άγκυρα δεν γίνονται δεκτοί")

    @case("N-PARSE unterminated string", "negative", 2)
    def _(w, m):
        bad = AUTH.format(mount=m, identity="x").replace(
            '(:lane "W-DIR"  :cluster-roots ("alpha" "beta"))',
            '(:lane "W-DIR"  :cluster-roots ("alpha" "beta)')
        setup(w, m, f'(:x "{A1}")', auth=bad)
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            ('::error::SCOPE-AUTHORITY «experiment/phase1a/LANE-SCOPE-AUTHORITY.sexp»: '
             'UNTERMINATED STRING που άνοιξε στη γραμμή 14')

    @case("N-PARSE dangling escape", "negative", 2)
    def _(w, m):
        setup(w, m, f'(:x "{A1}")',
              auth='(:lanes ((:lane "W-DIR" :cluster-roots ("a"))))\n"\\')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            ('::error::SCOPE-AUTHORITY «experiment/phase1a/LANE-SCOPE-AUTHORITY.sexp»: '
             'DANGLING ESCAPE — «\\» στο τέλος του αρχείου (συμβολοσειρά από γραμμή 2)')

    @case("N-PARSE μη κλεισμένη παρένθεση", "negative", 2)
    def _(w, m):
        setup(w, m, f'(:x "{A1}")',
              auth='(:lanes ((:lane "W-DIR" :cluster-roots ("a"))\n')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            ('::error::SCOPE-AUTHORITY «experiment/phase1a/LANE-SCOPE-AUTHORITY.sexp»: '
             '2 ΜΗ ΚΛΕΙΣΜΕΝΕΣ παρενθέσεις')

    @case("N-ID πειραγμένο TSV ⇒ ταυτότητα δεν ταιριάζει", "negative", 2)
    def _(w, m):
        rows = base_rows()
        ident = identity_of(rows)
        for r in rows:
            if r[0] == "beta/b.lisp":
                r[5] = str(int(r[5]) + 1)
        setup(w, m, f'(:x "{A1}")', rows=rows,
              auth=AUTH.format(mount=m, identity=ident))
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            ("::error::ΤΑΥΤΟΤΗΤΑ MANIFEST ΔΕΝ ΤΑΙΡΙΑΖΕΙ ΜΕ ΤΗ ΣΦΡΑΓΙΣΜΕΝΗ ΑΥΘΕΝΤΙΑ.\n"
             "  ξαναϋπολογισμένη : sha256:<SHA>\n"
             "  σφραγισμένη      : sha256:<SHA>")

    @case("N-FILE ΚΑΤΑΣΚΕΥΑΣΜΕΝΗ εγγραφή για ΑΝΥΠΑΡΚΤΟ αρχείο", "negative", 1)
    def _(w, m):
        rows = base_rows() + [row_for("alpha/ghost.lisp", GHOST)]
        d = f'(:x "{GH}")'
        setup(w, m, d, rows=rows, auth=AUTH.format(mount=m, identity=identity_of(rows)))
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", DIR, len(d.encode()), 0, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] {GH} — ΕΛΕΓΧΟΣ ΑΡΧΕΙΟΥ ΑΠΕΤΥΧΕ: "
             f"ΔΕΝ ΑΝΟΙΓΕΙ ΑΣΦΑΛΩΣ ΣΤΟ SNAPSHOT (errno 2)")

    for field, idx, val, msg in [
            ("bytes", 5, "999", "ΠΡΑΓΜΑΤΙΚΑ BYTES 9 ≠ manifest 999"),
            ("γραμμές", 6, "2", "ΜΕΤΡΗΣΗ ΔΙΣΚΟΥ (text,3,1) ≠ manifest (text,2,1)"),
            ("mode", 1, "100755", None)]:
        @case(f"N-FILE ΛΑΘΟΣ {field} στο manifest", "negative",
              2 if field == "mode" else 1)
        def _(w, m, _i=idx, _v=val, _msg=msg, _f=field):
            rows = base_rows()
            for r in rows:
                if r[0] == "alpha/a.lisp":
                    r[_i] = _v
            d = f'(:x "{A1}")'
            setup(w, m, d, rows=rows,
                  auth=AUTH.format(mount=m, identity=identity_of(rows)))
            if _f == "mode":
                return run(w, ["--lane", "W-DIR", "d.sexp"]), \
                    ("::error::MANIFEST γραμμή 5: mode «100755» ⇒ «executable», "
                     "βρέθηκε kind «file»")
            return run(w, ["--lane", "W-DIR", "d.sexp"]), \
                (head(m, "W-DIR", DIR, len(d.encode()), 0, 1, 0, 1, 0, 0, 0, 0) +
                 f"\n  ✗ [d.sexp] {A1} — ΕΛΕΓΧΟΣ ΑΡΧΕΙΟΥ ΑΠΕΤΥΧΕ: {_msg}")

    @case("N-MAN λάθος κεφαλίδα", "negative", 2)
    def _(w, m):
        setup(w, m, f'(:x "{A1}")', manifest_text="#path\tkind\n")
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            ("::error::MANIFEST: ΛΑΘΟΣ ΚΕΦΑΛΙΔΑ.\n  βρέθηκε: #path\tkind\n"
             f"  αναμ.  : {HDR}")

    @case("N-MAN διπλή διαδρομή", "negative", 2)
    def _(w, m):
        r = "\t".join(row_for("alpha/a.lisp", CORPUS["alpha/a.lisp"]))
        setup(w, m, f'(:x "{A1}")', manifest_text=HDR + "\n" + r + "\n" + r + "\n")
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            "::error::MANIFEST γραμμή 3: ΔΙΠΛΗ διαδρομή «alpha/a.lisp»"

    @case("N-MAN ΚΕΝΟ text με trailing_newline 1", "negative", 2)
    def _(w, m):
        r = row_for("alpha/empty.lisp", b"")
        r[7] = "1"
        setup(w, m, f'(:x "{A1}")', manifest_text=HDR + "\n" + "\t".join(r) + "\n")
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            ("::error::MANIFEST γραμμή 2: ΚΕΝΟ text ⇒ 0 γραμμές ΚΑΙ "
             "trailing_newline 0")

    @case("N-MAN κενό", "negative", 2)
    def _(w, m):
        setup(w, m, f'(:x "{A1}")', manifest_text=HDR + "\n")
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            "::error::MANIFEST ΚΕΝΟ — καμία ψευδο-επιτυχία"

    @case("N-MOUNT mount χωρίς nodev/nosuid/noexec", "negative", 2)
    def _(w, m):
        # ΠΡΟΣΟΧΗ: bind ΑΠΟ το αυστηρό mount ΚΛΗΡΟΝΟΜΕΙ nodev/nosuid/noexec.
        # Χρειάζεται ΞΕΧΩΡΙΣΤΟ tmpfs για να λείπουν πραγματικά.
        plain = os.path.join(w, "plainmnt")
        os.makedirs(plain, exist_ok=True)
        subprocess.run(["mount", "-t", "tmpfs", "-o", "size=1m", "tmpfs", plain],
                       check=True)
        subprocess.run(["mount", "-o", "remount,ro", plain], check=True)
        try:
            setup(w, m, f'(:x "{A1}")',
                  auth=AUTH.format(mount=plain, identity=identity_of(base_rows())))
            rc, out = run(w, ["--lane", "W-DIR", "d.sexp"])
        finally:
            subprocess.run(["umount", plain], capture_output=True)
        return (rc, out), (f"::error::ΤΟ {plain} ΔΕΝ ΕΧΕΙ «nodev»: "
                           f"['relatime', 'ro']")

    @case("N-MOUNT δεν είναι mount", "negative", 2)
    def _(w, m):
        fake = os.path.join(w, "notamount")
        os.makedirs(fake, exist_ok=True)
        setup(w, m, f'(:x "{A1}")',
              auth=AUTH.format(mount=fake, identity=identity_of(base_rows())))
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (f"::error::ΤΟ {fake} ΔΕΝ ΕΙΝΑΙ MOUNT (καμία εγγραφή στο "
             f"/proc/self/mountinfo). Καμία πύλη χωρίς την πηγή.")


custom()


def main():
    print(f"resolver υπό δοκιμή: sha256:{sha(open(RESOLVER,'rb').read())}")
    print(f"μάρτυρες: {len(CASES)}  (ΑΚΡΙΒΗΣ σύγκριση εξόδου)")
    root = tempfile.mkdtemp(prefix="witness-root-")
    try:
        mnt = build_mount(root)
        fails = []
        for name, kind, exp_exit, fn in CASES:
            work = tempfile.mkdtemp(prefix="w-", dir=root)
            (rc, got), expected = fn(work, mnt)
            expected = expected.strip()
            good = (rc == exp_exit) and (got == expected)
            print(f"  {'✓' if good else '✗'} [{kind:8}] {name}  (exit {rc}/{exp_exit})")
            if not good:
                fails.append((name, rc, exp_exit, expected, got))
            shutil.rmtree(work, ignore_errors=True)
        print()
        pos = sum(1 for c in CASES if c[1] == "positive")
        if fails:
            print(f"::error::{len(fails)} ΜΑΡΤΥΡΕΣ ΑΠΕΤΥΧΑΝ")
            for n, rc, ex, e, g in fails:
                print(f"\n── {n}\n   exit {rc} (αναμ. {ex})")
                print("   ΑΝΑΜΕΝΟΜΕΝΟ:"); [print("     |", l) for l in e.split("\n")]
                print("   ΕΛΑΒΑ:");        [print("     |", l) for l in g.split("\n")]
            return 1
        print(f"WITNESS-SUITE-PASS: {pos} θετικοί · {len(CASES)-pos} αρνητικοί · "
              f"{len(CASES)} σύνολο — ΑΚΡΙΒΗΣ ΤΑΥΤΙΣΗ ΕΞΟΔΟΥ")
        return 0
    finally:
        subprocess.run(["umount", os.path.join(root, "ro")], capture_output=True)
        shutil.rmtree(root, ignore_errors=True)


sys.exit(main())
