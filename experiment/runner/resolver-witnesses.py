#!/usr/bin/env python3
"""ΜΑΡΤΥΡΕΣ ΤΗΣ ΠΥΛΗΣ ΠΑΡΑΠΟΜΠΩΝ v5 — ΑΚΡΙΒΗΣ ΣΥΓΚΡΙΣΗ ΕΞΟΔΟΥ.

ΤΙ ΑΛΛΑΞΕ: οι μάρτυρες του v4 έλεγχαν exit code + υποσυμβολοσειρά. Αυτό
δεχόταν ΛΑΘΟΣ έξοδο αρκεί να περιείχε τη σωστή λέξη. Τώρα κάθε μάρτυρας
δηλώνει την ΑΚΡΙΒΗ αναμενόμενη έξοδο και συγκρίνεται ΓΡΑΜΜΗ ΠΡΟΣ ΓΡΑΜΜΗ.

ΔΗΛΩΜΕΝΗ ΚΑΝΟΝΙΚΟΠΟΙΗΣΗ (η ΜΟΝΗ επιτρεπτή χαλάρωση): οι τιμές sha256 στις
γραμμές ταυτότητας αντικαθίστανται με «<SHA>», επειδή αλλάζουν ανά στημένο
δέντρο. ΟΛΑ τα υπόλοιπα — πλήθη, μορφές, κωδικοί σφάλματος, σειρά, ετυμηγορία
— συγκρίνονται ΑΥΤΟΛΕΞΕΙ.

ΤΟ ΣΤΗΜΕΝΟ ΔΕΝΤΡΟ ΕΙΝΑΙ ΠΡΑΓΜΑΤΙΚΟ read-only bind mount: ο v5 ΔΕΝ κρίνει
χωρίς επαληθευμένο mount, άρα ούτε οι μάρτυρές του.
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

CORPUS = {                                   # ΤΟ ΣΥΝΘΕΤΙΚΟ ΠΑΓΩΜΕΝΟ ΔΕΝΤΡΟ
    "alpha/a.lisp":        b"l1\nl2\nl3\n",
    "alpha/nonl.lisp":     b"l1\nl2\nl3",
    "alpha/empty.lisp":    b"",
    "alpha/x.md":          b"x\n",
    "alpha/deep/y.md":     b"y\n",
    "alpha/deep/deeper/c.lisp": b"x\n",
    "beta/b.lisp":         b"one\ntwo\n",
    "top.md":              b"x\n",
}
SYMLINKS = {"alpha/link.lisp": "a.lisp"}

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


def sha(b):
    return hashlib.sha256(b).hexdigest()


def blob(b):
    h = hashlib.sha1()
    h.update(b"blob %d\0" % len(b))
    h.update(b)
    return h.hexdigest()


def classify(data, kind):
    if kind == "symlink":
        return "symlink", -2, 0
    try:
        t = data.decode("utf-8")
    except UnicodeDecodeError:
        return "binary", -1, 0
    if t == "":
        return "text", 0, 1
    tr = 1 if t.endswith("\n") else 0
    return "text", (t.count("\n") if tr else t.count("\n") + 1), tr


def row_for(rel, data, kind="file"):
    mode = {"file": "100644", "executable": "100755", "symlink": "120000"}[kind]
    cls, lines, tr = classify(data, kind)
    return [rel, mode, kind, blob(data), sha(data), str(len(data)),
            str(lines), str(tr), cls]


def identity_of(rows):
    def lp(b):
        return len(b).to_bytes(4, "big") + b
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
    return "sha256:" + node(leaves)


def base_rows():
    rows = [row_for(rel, data) for rel, data in CORPUS.items()]
    for rel, target in SYMLINKS.items():
        rows.append(row_for(rel, target.encode(), "symlink"))
    return rows


def build_mount(root):
    src = os.path.join(root, "src")
    mnt = os.path.join(root, "ro")
    for rel, data in CORPUS.items():
        p = os.path.join(src, rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        open(p, "wb").write(data)
    for rel, target in SYMLINKS.items():
        p = os.path.join(src, rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        os.symlink(target, p)
    os.makedirs(mnt, exist_ok=True)
    subprocess.run(["mount", "--bind", src, mnt], check=True)
    subprocess.run(["mount", "-o", "remount,ro,bind", mnt], check=True)
    return mnt


NORM = re.compile(r"sha256:[0-9a-f]{64}")


def run(work, argv):
    r = subprocess.run([sys.executable, RESOLVER] + argv, cwd=work,
                       capture_output=True, text=True)
    out = NORM.sub("sha256:<SHA>", r.stdout + r.stderr)
    return r.returncode, out.strip()


CASES = []


def case(name, kind, exit_code, expected):
    def deco(fn):
        CASES.append((name, kind, exit_code, expected.strip(), fn))
        return fn
    return deco


def setup(work, mnt, dossier, rows=None, auth=None, manifest_text=None):
    rows = base_rows() if rows is None else rows
    os.makedirs(os.path.join(work, "experiment/artifacts"), exist_ok=True)
    os.makedirs(os.path.join(work, "experiment/phase1a"), exist_ok=True)
    ident = identity_of([r for r in rows if len(r) == 9])
    open(os.path.join(work, "experiment/phase1a/LANE-SCOPE-AUTHORITY.sexp"), "w",
         encoding="utf-8").write(auth if auth is not None
                                 else AUTH.format(mount=mnt, identity=ident))
    mp = os.path.join(work, "experiment/artifacts/corpus-manifest.tsv")
    if manifest_text is not None:
        open(mp, "w", encoding="utf-8").write(manifest_text)
    else:
        open(mp, "w", encoding="utf-8").write(
            HDR + "\n" + "\n".join("\t".join(r) for r in rows) + "\n")
    if dossier is not None:
        open(os.path.join(work, "d.sexp"), "w", encoding="utf-8").write(dossier)
    return ident


def head(mnt, lane, roots, files_verified, total, res, prob, ma, cr, inc, out):
    return (f"resolver v5 sha256:<SHA>\n"
            f"manifest sha256:<SHA>\n"
            f"scope-authority sha256:<SHA>\n"
            f"frozen mount {mnt} (read-only, επαληθευμένο στο /proc/self/mountinfo)\n"
            f"corpus-identity sha256:<SHA> (ξαναϋπολογισμένη από το TSV: ΤΑΥΤΙΖΕΤΑΙ)\n"
            f"lane {lane} · cluster-roots {roots}\n"
            f"dossier d.sexp sha256:<SHA>\n"
            f"αρχεία επαληθευμένα στο mount: {files_verified}\n"
            f"παραπομπές: {total} · λύθηκαν: {res} · ΠΡΟΒΛΗΜΑΤΙΚΕΣ: {prob}\n"
            f"μορφές: mount-anchored={ma} corpus-relative={cr} · "
            f"εντός συστάδας={inc} · εκτός={out}")


GHOST_BODY = b"ghost\n"      # ΔΕΝ υπάρχει στο δέντρο — μόνο σε κατασκευασμένο manifest


def C(rel, a, b=None):
    """Κανονική παραπομπή: path:L<a>-L<b>@sha256:<12> — ΠΑΝΤΑ πλήρης."""
    b = a if b is None else b
    if rel in SYMLINKS:
        body = SYMLINKS[rel].encode()
    elif rel in CORPUS:
        body = CORPUS[rel]
    else:
        body = GHOST_BODY
    return f"{rel}:L{a}-L{b}@sha256:{sha(body)[:12]}"



# ΠΡΟΫΠΟΛΟΓΙΣΜΕΝΑ ΚΑΝΟΝΙΚΑ TOKENS — χωρίς εισαγωγικά μέσα σε f-strings
A1 = C('alpha/a.lisp', 1, 1)
A2 = C('alpha/a.lisp', 2, 2)
A3 = C('alpha/a.lisp', 3, 3)
A4 = C('alpha/a.lisp', 4, 4)
A0 = C('alpha/a.lisp', 0, 0)
A31 = C('alpha/a.lisp', 3, 1)
NONL3 = C('alpha/nonl.lisp', 3, 3)
XMD = C('alpha/x.md', 1, 1)
YMD = C('alpha/deep/y.md', 1, 1)
CDEEP = C('alpha/deep/deeper/c.lisp', 1, 1)
TOP = C('top.md', 1, 1)
LINK = C('alpha/link.lisp', 1, 1)
GHOST = C('alpha/ghost.lisp', 1, 1)
BARE = "a" + A1[len("alpha/a"):]   # «a.lisp:L1-L1@…» — γυμνό όνομα

PASS = "\n".join([
    "VERDICT: RECOGNIZED-CITATION-INTEGRITY",
    "  ΤΙ ΣΗΜΑΙΝΕΙ: κάθε token παραπομπής ΠΟΥ ΑΝΑΓΝΩΡΙΣΤΗΚΕ αντιστοιχεί σε",
    "  πραγματικά bytes και πραγματικό εύρος του παγωμένου δέντρου.",
    "  ΤΙ ΔΕΝ ΣΗΜΑΙΝΕΙ: ΔΕΝ αποδεικνύει ότι κάθε claim ΕΧΕΙ παραπομπή",
    "  (CLAIM-CITATION-COVERAGE: ΑΝΟΙΧΤΟ) ούτε ότι το cited span ΣΤΗΡΙΖΕΙ",
    "  τον ισχυρισμό (CLAIM-ENTAILMENT: ΑΝΟΙΧΤΟ). Ούτε είναι read-ledger."])
PROTO = "ΚΑΚΟΣΧΗΜΑΤΙΣΜΕΝΗ ΠΑΡΑΠΟΜΠΗ — δεν ερμηνεύεται ούτε ως legacy"
LEGACY = ("LEGACY-SHORTHAND — ΟΧΙ κανονιστική μορφή "
          "path:L<start>-L<end>@sha256:<12>")


# ═══════════════════ ΘΕΤΙΚΟΙ ═══════════════════
@case("P1 corpus-relative", "positive", 0, "")
def _(w, m):
    setup(w, m, f'(:x "{A2}")')
    return run(w, ["--lane", "W-DIR", "d.sexp"]), \
        head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 1, 0, 0, 1, 1, 0) + "\n" + PASS


@case("P2 mount-anchored", "positive", 0, "")
def _(w, m):
    setup(w, m, f'(:x "{m}/{A3}")')
    return run(w, ["--lane", "W-DIR", "d.sexp"]), \
        head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 1, 0, 1, 0, 1, 0) + "\n" + PASS


@case("P3 τελευταία γραμμή· αρχείο χωρίς τελικό newline", "positive", 0, "")
def _(w, m):
    setup(w, m, f'(:x "{NONL3}")')
    return run(w, ["--lane", "W-DIR", "d.sexp"]), \
        head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 1, 0, 0, 1, 1, 0) + "\n" + PASS


@case("P4 glob «*» = μόνο ρίζα· «alpha/*.md» δεν διασχίζει «/»", "positive", 0, "")
def _(w, m):
    setup(w, m, f'(:x "{TOP}" "{XMD}" "{YMD}")')
    return run(w, ["--lane", "W-GLOB", "d.sexp"]), \
        head(m, "W-GLOB", "['*', 'alpha/*.md']", 3, 3, 3, 0, 0, 3, 2, 1) + "\n" + PASS


@case("P5 dir root αναδρομικό", "positive", 0, "")
def _(w, m):
    setup(w, m, f'(:x "{CDEEP}")')
    return run(w, ["--lane", "W-DIR", "d.sexp"]), \
        head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 1, 0, 0, 1, 1, 0) + "\n" + PASS


@case("P6 πλήρης κανονική μορφή με ΑΚΡΙΒΩΣ 12 hex", "positive", 0, "")
def _(w, m):
    setup(w, m, f'(:x "{A1}")')
    return run(w, ["--lane", "W-DIR", "d.sexp"]), \
        head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 1, 0, 0, 1, 1, 0) + "\n" + PASS


@case("P7 τελεία πρότασης ΔΕΝ είναι σκουπίδι", "positive", 0, "")
def _(w, m):
    setup(w, m, f'(:x "βλ. {A2}. Το επόμενο.")')
    return run(w, ["--lane", "W-DIR", "d.sexp"]), \
        head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 1, 0, 0, 1, 1, 0) + "\n" + PASS


@case("P8 «path:» χωρίς ψηφίο = πρόζα, ΔΕΝ μετριέται", "positive", 0, "")
def _(w, m):
    setup(w, m, f'(:x "στο alpha/a.lisp: γράφεται κάτι" "{A1}")')
    return run(w, ["--lane", "W-DIR", "d.sexp"]), \
        head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 1, 0, 0, 1, 1, 0) + "\n" + PASS


# ═══════════════════ ΑΡΝΗΤΙΚΟΙ ═══════════════════
def neg(name, argv_or_none, dossier, expect_exit, expect, **kw):
    @case(name, "negative", expect_exit, "")
    def _(w, m, _d=dossier, _a=argv_or_none, _e=expect, _kw=kw):
        setup(w, m, _d, **_kw)
        return run(w, _a or ["--lane", "W-DIR", "d.sexp"]), _e


D1 = f'(:x "{A1}")'
neg("N1 --lane απών", ["d.sexp"], D1, 2,
    "::error::--lane ΥΠΟΧΡΕΩΤΙΚΟ και ΜΟΝΑΔΙΚΟ (βρέθηκε 0×)")
neg("N2 --lane διπλό", ["--lane", "W-DIR", "--lane", "W-GLOB", "d.sexp"], D1, 2,
    "::error::--lane ΥΠΟΧΡΕΩΤΙΚΟ και ΜΟΝΑΔΙΚΟ (βρέθηκε 2×)")
neg("N3 lane άγνωστο", ["--lane", "W-NOSUCH", "d.sexp"], D1, 2,
    "::error::LANE «W-NOSUCH»: 0 εγγραφές στο scope authority — απαιτείται ΑΚΡΙΒΩΣ 1")
neg("N4 lane διπλοεγγεγραμμένο", ["--lane", "W-DUP", "d.sexp"], D1, 2,
    "::error::LANE «W-DUP»: 2 εγγραφές στο scope authority — απαιτείται ΑΚΡΙΒΩΣ 1")
neg("N5 απών :cluster-roots", ["--lane", "W-NOROOTS", "d.sexp"], D1, 2,
    "::error::LANE «W-NOROOTS»: ΑΠΩΝ :cluster-roots")
neg("N6 κενό :cluster-roots", ["--lane", "W-EMPTY", "d.sexp"], D1, 2,
    "::error::LANE «W-EMPTY»: ΚΕΝΟ :cluster-roots")
neg("N7 root απόλυτο", ["--lane", "W-BADROOT", "d.sexp"], D1, 2,
    "::error::LANE «W-BADROOT»: ΑΚΥΡΟ cluster-root «/abs»")
neg("N8 root ΜΗ-ΣΥΜΒΟΛΟΣΕΙΡΑ", ["--lane", "W-NONSTRING", "d.sexp"], D1, 2,
    "::error::LANE «W-NONSTRING»: ΜΗ-ΣΥΜΒΟΛΟΣΕΙΡΑ root 'alpha' — "
    "τα roots είναι ΠΑΝΤΑ strings")
neg("N9 ΔΙΠΛΟ :cluster-roots", ["--lane", "W-DUPROOTS", "d.sexp"], D1, 2,
    "::error::LANE «W-DUPROOTS»: ΔΙΠΛΟ κλειδί «:cluster-roots» στην εγγραφή")
neg("N10 ΔΙΠΛΟ κλειδί στην εγγραφή", ["--lane", "W-DUPKEY", "d.sexp"], D1, 2,
    "::error::LANE «W-DUPKEY»: ΔΙΠΛΟ κλειδί «:dossier» στην εγγραφή")
neg("N11 απών dossier", ["--lane", "W-DIR", "d.sexp", "ΛΕΙΠΕΙ.sexp"], D1, 2,
    "::error::ΑΠΩΝ ή ΜΗ ΚΑΝΟΝΙΚΟ ΑΡΧΕΙΟ: ΛΕΙΠΕΙ.sexp")
neg("N12 καμία είσοδος", ["--lane", "W-DIR"], D1, 2,
    "::error::ΚΑΜΙΑ είσοδος — καμία ψευδο-επιτυχία")


def _cases_needing_custom():
    @case("N13 μηδέν παραπομπές", "negative", 2, "")
    def _(w, m):
        setup(w, m, '(:x "καμία άγκυρα")')
        exp = head(m, "W-DIR", "['alpha', 'beta']", 0, 0, 0, 0, 0, 0, 0, 0) + \
            "\n::error::ΜΗΔΕΝ παραπομπές — ισχυρισμοί χωρίς άγκυρα δεν γίνονται δεκτοί"
        return run(w, ["--lane", "W-DIR", "d.sexp"]), exp

    @case("N14 UNTERMINATED STRING στην αυθεντία", "negative", 2, "")
    def _(w, m):
        bad = AUTH.format(mount=m, identity="x").replace(
            '(:lane "W-DIR"  :cluster-roots ("alpha" "beta"))',
            '(:lane "W-DIR"  :cluster-roots ("alpha" "beta)')
        setup(w, m, D1, auth=bad)
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            ('::error::SCOPE-AUTHORITY «experiment/phase1a/LANE-SCOPE-AUTHORITY.sexp»: '
             'UNTERMINATED STRING που άνοιξε στη γραμμή 14')
        # ΣΗΜΕΙΩΣΗ: το ανοιχτό «"beta)» της γραμμής 5 ΚΑΤΑΠΙΝΕΙ ως συμβολοσειρά
        # ό,τι ακολουθεί ώσπου να βρει το επόμενο εισαγωγικό. Έτσι ΟΛΑ τα
        # ζευγάρια μετατοπίζονται κατά ένα και αυτό που μένει ΑΤΕΡΜΑΤΙΣΤΟ είναι
        # της γραμμής 14. Ο parser αναφέρει το ΠΡΑΓΜΑΤΙΚΑ ατερμάτιστο, όχι το
        # πρώτο χαλασμένο — αυτό είναι σωστό και ο μάρτυρας το κλειδώνει.

    @case("N15 DANGLING ESCAPE στην αυθεντία", "negative", 2, "")
    def _(w, m):
        setup(w, m, D1, auth='(:lanes ((:lane "W-DIR" :cluster-roots ("a"))))\n"\\')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            ('::error::SCOPE-AUTHORITY «experiment/phase1a/LANE-SCOPE-AUTHORITY.sexp»: '
             'DANGLING ESCAPE — «\\» στο τέλος του αρχείου (συμβολοσειρά από γραμμή 2)')

    @case("N16 ΜΗ ΚΛΕΙΣΜΕΝΗ παρένθεση στην αυθεντία", "negative", 2, "")
    def _(w, m):
        setup(w, m, D1, auth='(:lanes ((:lane "W-DIR" :cluster-roots ("a"))\n')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            ('::error::SCOPE-AUTHORITY «experiment/phase1a/LANE-SCOPE-AUTHORITY.sexp»: '
             '2 ΜΗ ΚΛΕΙΣΜΕΝΕΣ παρενθέσεις')

    @case("N17 ΤΑΥΤΟΤΗΤΑ MANIFEST ΔΕΝ ΤΑΙΡΙΑΖΕΙ (πειραγμένο TSV)", "negative", 2, "")
    def _(w, m):
        rows = base_rows()
        ident = identity_of(rows)
        for r in rows:                                   # αλλάζουμε ΕΝΑ μέγεθος
            if r[0] == "beta/b.lisp":
                r[5] = str(int(r[5]) + 1)
        setup(w, m, D1, rows=rows,
              auth=AUTH.format(mount=m, identity=ident))
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            ("::error::ΤΑΥΤΟΤΗΤΑ MANIFEST ΔΕΝ ΤΑΙΡΙΑΖΕΙ ΜΕ ΤΗ ΣΦΡΑΓΙΣΜΕΝΗ ΑΥΘΕΝΤΙΑ.\n"
             "  ξαναϋπολογισμένη από το TSV : sha256:<SHA>\n"
             "  σφραγισμένη στην αυθεντία   : sha256:<SHA>")

    @case("N18 ΚΑΤΑΣΚΕΥΑΣΜΕΝΗ εγγραφή για ΑΝΥΠΑΡΚΤΟ αρχείο", "negative", 1, "")
    def _(w, m):
        rows = base_rows() + [row_for("alpha/ghost.lisp", GHOST_BODY)]
        setup(w, m, f'(:x "{GHOST}")', rows=rows,
              auth=AUTH.format(mount=m, identity=identity_of(rows)))
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 0, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] {GHOST} — ΕΛΕΓΧΟΣ ΑΡΧΕΙΟΥ ΑΠΕΤΥΧΕ: "
             "ΔΕΝ ΑΝΟΙΓΕΙ ΣΤΟ ΠΑΓΩΜΕΝΟ MOUNT (errno 2)")

    @case("N19 ΛΑΘΟΣ bytes στο manifest", "negative", 1, "")
    def _(w, m):
        rows = base_rows()
        for r in rows:
            if r[0] == "alpha/a.lisp":
                r[5] = "999"
        setup(w, m, D1, rows=rows, auth=AUTH.format(mount=m, identity=identity_of(rows)))
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 0, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] {A1} — ΕΛΕΓΧΟΣ ΑΡΧΕΙΟΥ ΑΠΕΤΥΧΕ: "
             "ΠΡΑΓΜΑΤΙΚΑ BYTES 9 ≠ manifest 999")

    @case("N20 ΛΑΘΟΣ sha256 στο manifest", "negative", 1, "")
    def _(w, m):
        rows = base_rows()
        for r in rows:
            if r[0] == "alpha/a.lisp":
                r[4] = "0" * 64
        setup(w, m, D1, rows=rows, auth=AUTH.format(mount=m, identity=identity_of(rows)))
        real = sha(CORPUS["alpha/a.lisp"])[:16]
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 0, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] {A1} — ΕΛΕΓΧΟΣ ΑΡΧΕΙΟΥ ΑΠΕΤΥΧΕ: "
             f"ΠΡΑΓΜΑΤΙΚΟ SHA-256 {real}… ≠ manifest 0000000000000000…")

    @case("N21 ΛΑΘΟΣ πλήθος γραμμών στο manifest", "negative", 1, "")
    def _(w, m):
        rows = base_rows()
        for r in rows:
            if r[0] == "alpha/a.lisp":
                r[6] = "2"
        setup(w, m, D1, rows=rows, auth=AUTH.format(mount=m, identity=identity_of(rows)))
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 0, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] {A1} — ΕΛΕΓΧΟΣ ΑΡΧΕΙΟΥ ΑΠΕΤΥΧΕ: "
             "ΠΡΑΓΜΑΤΙΚΕΣ ΓΡΑΜΜΕΣ 3 ≠ manifest 2")

    @case("N22 ΠΑΡΑΛΕΙΨΗ από το manifest", "negative", 1, "")
    def _(w, m):
        rows = [r for r in base_rows() if r[0] != "alpha/a.lisp"]
        setup(w, m, D1, rows=rows, auth=AUTH.format(mount=m, identity=identity_of(rows)))
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 0, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] {A1} — ΑΓΝΩΣΤΗ ΔΙΑΔΡΟΜΗ στο manifest")

    @case("N23 SYMLINK — δεν παραπέμπουμε σε σύνδεσμο", "negative", 1, "")
    def _(w, m):
        setup(w, m, f'(:x "{LINK}")')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 0, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] {LINK} — ΜΗ ΠΑΡΑΠΕΜΨΙΜΟ kind «symlink»")

    @case("N24 PATH TRAVERSAL", "negative", 1, "")
    def _(w, m):
        setup(w, m, f'(:x "alpha/../{A1}")')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 0, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] alpha/../{A1} — PATH TRAVERSAL: περιέχει «..»")

    @case("N25 absolute εκτός mount", "negative", 1, "")
    def _(w, m):
        setup(w, m, f'(:x "/app/{A1}")')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 0, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] /app/{A1} — ΜΗ ΔΗΛΩΜΕΝΗ ΜΟΡΦΗ: absolute εκτός {m}/")

    @case("N26 γραμμή n+1 — off-by-one", "negative", 1, "")
    def _(w, m):
        setup(w, m, f'(:x "{A4}")')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] {A4} — ΕΚΤΟΣ ΕΥΡΟΥΣ: το αρχείο έχει 3 λογικές γραμμές")

    @case("N27 γραμμή 0", "negative", 1, "")
    def _(w, m):
        setup(w, m, f'(:x "{A0}")')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] {A0} — ΕΚΤΟΣ ΕΥΡΟΥΣ: το αρχείο έχει 3 λογικές γραμμές")

    @case("N28 ανάποδο εύρος", "negative", 1, "")
    def _(w, m):
        setup(w, m, f'(:x "{A31}")')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] {A31} — ΑΝΑΠΟΔΟ ΕΥΡΟΣ")

    @case("N29 λάθος sha256 prefix", "negative", 1, "")
    def _(w, m):
        setup(w, m, '(:x "alpha/a.lisp:L1-L1@sha256:abcdef123456")')
        real = sha(CORPUS["alpha/a.lisp"])[:12]
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] alpha/a.lisp:L1-L1@sha256:abcdef123456 — ΛΑΘΟΣ HASH: manifest {real}")

    @case("N30 sha256 ΜΗΚΟΥΣ 13 — το protocol ορίζει 12", "negative", 1, "")
    def _(w, m):
        s13 = sha(CORPUS["alpha/a.lisp"])[:13]
        setup(w, m, f'(:x "alpha/a.lisp:L1-L1@sha256:{s13}")')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] alpha/a.lisp:L1-L1@sha256:{s13} — {LEGACY}")

    @case("N31 TRAILING GARBAGE μετά την παραπομπή", "negative", 1, "")
    def _(w, m):
        setup(w, m, f'(:x "{A1}+3")')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] {A1}+3 — {PROTO}")

    @case("N32 ΚΑΜΙΑ cluster-relative fallback", "negative", 1, "")
    def _(w, m):
        setup(w, m, f'(:x "a{C("alpha/a.lisp", 1)[len("alpha/a"):]}")')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 0, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] {BARE} — ΑΓΝΩΣΤΗ ΔΙΑΔΡΟΜΗ στο manifest")

    @case("N33 manifest: λάθος κεφαλίδα", "negative", 2, "")
    def _(w, m):
        setup(w, m, D1, manifest_text="#path\tkind\tsha\n")
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            ("::error::MANIFEST: ΛΑΘΟΣ ΚΕΦΑΛΙΔΑ.\n"
             "  βρέθηκε: #path\tkind\tsha\n"
             f"  αναμ.  : {HDR}")

    @case("N34 manifest: διπλή διαδρομή", "negative", 2, "")
    def _(w, m):
        r = row_for("alpha/a.lisp", CORPUS["alpha/a.lisp"])
        txt = HDR + "\n" + "\t".join(r) + "\n" + "\t".join(r) + "\n"
        setup(w, m, D1, manifest_text=txt)
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            "::error::MANIFEST γραμμή 3: ΔΙΠΛΗ διαδρομή «alpha/a.lisp»"

    @case("N35 manifest: mode ≠ kind", "negative", 2, "")
    def _(w, m):
        r = row_for("alpha/a.lisp", CORPUS["alpha/a.lisp"])
        r[1] = "100755"
        setup(w, m, D1, manifest_text=HDR + "\n" + "\t".join(r) + "\n")
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            ("::error::MANIFEST γραμμή 2: mode «100755» ⇒ «executable», "
             "βρέθηκε kind «file»")

    @case("N36 manifest: ασυνεπές text (bytes>0, γραμμές 0)", "negative", 2, "")
    def _(w, m):
        r = row_for("alpha/a.lisp", CORPUS["alpha/a.lisp"])
        r[6] = "0"
        setup(w, m, D1, manifest_text=HDR + "\n" + "\t".join(r) + "\n")
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            "::error::MANIFEST γραμμή 2: 9 bytes αλλά 0 γραμμές"

    @case("N37 manifest: γραμμές > bytes", "negative", 2, "")
    def _(w, m):
        r = row_for("alpha/a.lisp", CORPUS["alpha/a.lisp"])
        r[6] = "99"
        setup(w, m, D1, manifest_text=HDR + "\n" + "\t".join(r) + "\n")
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            "::error::MANIFEST γραμμή 2: 99 γραμμές > 9 bytes"

    @case("N38 manifest: ασυνεπές symlink", "negative", 2, "")
    def _(w, m):
        r = row_for("alpha/link.lisp", b"a.lisp", "symlink")
        r[6] = "1"
        setup(w, m, D1, manifest_text=HDR + "\n" + "\t".join(r) + "\n")
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            "::error::MANIFEST γραμμή 2: ασυνεπές symlink"

    @case("N39 manifest κενό", "negative", 2, "")
    def _(w, m):
        setup(w, m, D1, manifest_text=HDR + "\n")
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            "::error::MANIFEST ΚΕΝΟ — καμία ψευδο-επιτυχία"

    @case("N40 mount ΔΕΝ είναι mount", "negative", 2, "")
    def _(w, m):
        fake = os.path.join(w, "notamount")
        os.makedirs(fake, exist_ok=True)
        setup(w, m, D1, auth=AUTH.format(mount=fake, identity=identity_of(base_rows())))
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (f"::error::ΤΟ {fake} ΔΕΝ ΕΙΝΑΙ MOUNT (καμία εγγραφή στο "
             f"/proc/self/mountinfo). Τρέξε ensure-ro-mount.sh. Καμία πύλη δεν "
             f"κρίνει χωρίς την πηγή.")

    @case("N41 LEGACY μονή γραμμή χωρίς end/hash", "negative", 1, "")
    def _(w, m):
        setup(w, m, '(:x "alpha/a.lisp:1")')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] alpha/a.lisp:1 — {LEGACY}")

    @case("N42 LEGACY εύρος ΧΩΡΙΣ hash", "negative", 1, "")
    def _(w, m):
        setup(w, m, '(:x "alpha/a.lisp:L1-L3")')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] alpha/a.lisp:L1-L3 — {LEGACY}")

    @case("N43 ΧΩΡΙΣ end — το protocol απαιτεί start ΚΑΙ end", "negative", 1, "")
    def _(w, m):
        s12 = sha(CORPUS["alpha/a.lisp"])[:12]
        setup(w, m, f'(:x "alpha/a.lisp:L1@sha256:{s12}")')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] alpha/a.lisp:L1@sha256:{s12} — {LEGACY}")

    @case("N44 ΛΙΣΤΑ ΚΟΜΜΑΤΟΣ — ΑΠΑΓΟΡΕΥΜΕΝΗ, απορρίπτεται ΟΛΟΚΛΗΡΗ", "negative", 1, "")
    def _(w, m):
        s12 = sha(CORPUS["alpha/a.lisp"])[:12]
        tok = f"alpha/a.lisp:L1-L1@sha256:{s12},L2-L2@sha256:{s12}"
        setup(w, m, f'(:x "{tok}")')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] {tok} — {PROTO}")

    @case("N45 ΛΙΣΤΑ ΚΟΜΜΑΤΟΣ legacy «:L21-22,L98»", "negative", 1, "")
    def _(w, m):
        setup(w, m, '(:x "alpha/a.lisp:L1-2,L3")')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            (head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 0, 1, 0, 0, 0, 0) +
             f"\n  ✗ [d.sexp] alpha/a.lisp:L1-2,L3 — {PROTO}")

    @case("N46 κόμμα ΣΤΙΞΗΣ ΔΕΝ επηρεάζει έγκυρη παραπομπή", "positive", 0, "")
    def _(w, m):
        setup(w, m, f'(:x "{A1}, και συνεχίζει η πρόταση")')
        return run(w, ["--lane", "W-DIR", "d.sexp"]), \
            head(m, "W-DIR", "['alpha', 'beta']", 1, 1, 1, 0, 0, 1, 1, 0) + "\n" + PASS


_cases_needing_custom()


def main():
    print(f"resolver υπό δοκιμή: sha256:{sha(open(RESOLVER,'rb').read())}")
    print(f"μάρτυρες: {len(CASES)}  (ΑΚΡΙΒΗΣ σύγκριση εξόδου)")
    root = tempfile.mkdtemp(prefix="witness-root-")
    try:
        mnt = build_mount(root)
        fails = []
        for name, kind, exp_exit, _unused, fn in CASES:
            work = tempfile.mkdtemp(prefix="witness-", dir=root)
            (rc, got), expected = fn(work, mnt)
            expected = expected.strip()
            ok = (rc == exp_exit) and (got == expected)
            print(f"  {'✓' if ok else '✗'} [{kind:8}] {name}  (exit {rc}/{exp_exit})")
            if not ok:
                fails.append((name, rc, exp_exit, expected, got))
            shutil.rmtree(work, ignore_errors=True)
        print()
        pos = sum(1 for c in CASES if c[1] == "positive")
        if fails:
            print(f"::error::{len(fails)} ΜΑΡΤΥΡΕΣ ΑΠΕΤΥΧΑΝ")
            for n, rc, ex, expected, got in fails:
                print(f"\n── {n}\n   exit {rc} (αναμ. {ex})")
                print("   ΑΝΑΜΕΝΟΜΕΝΟ:"); [print("     |", l) for l in expected.split("\n")]
                print("   ΕΛΑΒΑ:");        [print("     |", l) for l in got.split("\n")]
            return 1
        print(f"WITNESS-SUITE-PASS: {pos} θετικοί · {len(CASES)-pos} αρνητικοί · "
              f"{len(CASES)} σύνολο — ΑΚΡΙΒΗΣ ΤΑΥΤΙΣΗ ΕΞΟΔΟΥ")
        return 0
    finally:
        subprocess.run(["umount", os.path.join(root, "ro")], capture_output=True)
        shutil.rmtree(root, ignore_errors=True)


sys.exit(main())
