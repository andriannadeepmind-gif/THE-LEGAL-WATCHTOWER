#!/usr/bin/env python3
"""ΜΑΡΤΥΡΕΣ ΤΗΣ ΠΥΛΗΣ ΠΑΡΑΠΟΜΠΩΝ v4 — ΘΕΤΙΚΟΙ ΚΑΙ ΑΡΝΗΤΙΚΟΙ.

Μια πύλη που δεν έχει αποδεδειγμένο ΑΡΝΗΤΙΚΟ μάρτυρα δεν είναι πύλη: δεν
ξέρουμε αν μπορεί ΠΟΤΕ να κοκκινίσει. Εδώ κάθε μονοπάτι απόρριψης του v4
εκτελείται σε ΣΥΝΘΕΤΙΚΟ στημένο δέντρο και το αποτέλεσμα ελέγχεται ΑΚΡΙΒΩΣ
(exit code + υπογραφή αιτίας).

Ο resolver διαβάζει MANIFEST/REGISTRY με ΣΧΕΤΙΚΕΣ διαδρομές, άρα οι μάρτυρες
τρέχουν με cwd = προσωρινό δέντρο. ΚΑΜΙΑ αλλαγή στον resolver γι' αυτούς.
"""
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile

RESOLVER = os.path.abspath(sys.argv[1] if len(sys.argv) > 1
                           else "experiment/runner/citation-resolver.py")

REGISTRY_OK = '''(:lawmax-phase1a-lane-registry/1
 :lanes
 ((:lane "W-DIR"  :cluster-roots ("alpha" "beta"))
  (:lane "W-GLOB" :cluster-roots ("*" "alpha/*.md"))
  (:lane "W-NOROOTS" :dossier "x")
  (:lane "W-EMPTY" :cluster-roots ())
  (:lane "W-BADROOT" :cluster-roots ("/abs"))
  (:lane "W-TRAV" :cluster-roots ("../x"))
  (:lane "W-DUP" :cluster-roots ("alpha"))
  (:lane "W-DUP" :cluster-roots ("beta"))))
'''


def sha(b):
    return hashlib.sha256(b).hexdigest()


def build(tmp, files, registry=REGISTRY_OK, manifest_rows=None, manifest_text=None):
    os.makedirs(os.path.join(tmp, "experiment/artifacts"), exist_ok=True)
    os.makedirs(os.path.join(tmp, "experiment/phase1a"), exist_ok=True)
    with open(os.path.join(tmp, "experiment/phase1a/LANE-REGISTRY.sexp"), "w",
              encoding="utf-8") as fh:
        fh.write(registry)
    mpath = os.path.join(tmp, "experiment/artifacts/corpus-manifest.tsv")
    if manifest_text is not None:
        open(mpath, "w", encoding="utf-8").write(manifest_text)
    else:
        rows = manifest_rows if manifest_rows is not None else []
        for rel, data in files.items():
            if any(r.split("\t")[0] == rel for r in rows):
                continue
            text = data.decode("utf-8", errors="replace")
            nl = text.count("\n")
            trail = 1 if (text.endswith("\n") or text == "") else 0
            lines = 0 if text == "" else (nl if trail else nl + 1)
            rows.append(f"{rel}\tfile\t{sha(data)}\t{len(data)}\t{lines}\ttext\t{trail}")
        open(mpath, "w", encoding="utf-8").write("\n".join(rows) + "\n")
    for rel, data in files.items():
        p = os.path.join(tmp, "corpus", rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        open(p, "wb").write(data)
    return mpath


def run(tmp, argv):
    return subprocess.run([sys.executable, RESOLVER] + argv, cwd=tmp,
                          capture_output=True, text=True)


CASES = []


def case(name, kind, expect_exit, expect_sig):
    def deco(fn):
        CASES.append((name, kind, expect_exit, expect_sig, fn))
        return fn
    return deco


# ─────────────────────── ΘΕΤΙΚΟΙ ΜΑΡΤΥΡΕΣ ────────────────────────────────
@case("P1 corpus-relative λύνεται", "positive", 0, "CITATION-INTEGRITY-PASS")
def _(tmp):
    files = {"alpha/a.lisp": b"l1\nl2\nl3\n"}
    build(tmp, files)
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:2\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("P2 mount-anchored λύνεται", "positive", 0, "mount-anchored=1")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\nl2\nl3\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"/frozen/ro/alpha/a.lisp:3\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("P3 ΤΕΛΕΥΤΑΙΑ γραμμή δεκτή (όριο)", "positive", 0, "λύθηκαν: 1")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\nl2\nl3\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:3\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("P4 αρχείο ΧΩΡΙΣ τελικό newline: 3 λογικές γραμμές", "positive", 0, "λύθηκαν: 1")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\nl2\nl3"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:3\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("P5 glob root «*» = ΜΟΝΟ αρχείο ρίζας", "positive", 0,
      "εντός συστάδας=1 · εκτός=1")
def _(tmp):
    build(tmp, {"top.md": b"x\n", "alpha/deep/b.md": b"y\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"top.md:1\" \"alpha/deep/b.md:1\")")
    return run(tmp, ["--lane", "W-GLOB", "d.sexp"])


@case("P6 glob «alpha/*.md» ΔΕΝ διασχίζει «/»", "positive", 0,
      "εντός συστάδας=1 · εκτός=1")
def _(tmp):
    build(tmp, {"alpha/x.md": b"x\n", "alpha/deep/y.md": b"y\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/x.md:1\" \"alpha/deep/y.md:1\")")
    return run(tmp, ["--lane", "W-GLOB", "d.sexp"])


@case("P7 dir root είναι ΑΝΑΔΡΟΜΙΚΟ", "positive", 0, "εντός συστάδας=1 · εκτός=0")
def _(tmp):
    build(tmp, {"alpha/deep/deeper/c.lisp": b"x\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/deep/deeper/c.lisp:1\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("P8 σωστό sha256 prefix δεκτό", "positive", 0, "λύθηκαν: 1")
def _(tmp):
    data = b"l1\n"
    build(tmp, {"alpha/a.lisp": data})
    open(f"{tmp}/d.sexp", "w").write(f"(:x \"alpha/a.lisp:1@sha256:{sha(data)[:12]}\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


# ─────────────────────── ΑΡΝΗΤΙΚΟΙ ΜΑΡΤΥΡΕΣ ─────────────────────────────
@case("N1 --lane ΑΠΩΝ", "negative", 2, "--lane ΥΠΟΧΡΕΩΤΙΚΟ")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:1\")")
    return run(tmp, ["d.sexp"])


@case("N2 --lane ΔΙΠΛΟ", "negative", 2, "--lane ΥΠΟΧΡΕΩΤΙΚΟ")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:1\")")
    return run(tmp, ["--lane", "W-DIR", "--lane", "W-GLOB", "d.sexp"])


@case("N3 lane ΑΓΝΩΣΤΟ στο registry", "negative", 2, "βρέθηκαν 0 εγγραφές")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:1\")")
    return run(tmp, ["--lane", "W-NOSUCH", "d.sexp"])


@case("N4 lane ΔΙΠΛΟΕΓΓΕΓΡΑΜΜΕΝΟ", "negative", 2, "βρέθηκαν 2 εγγραφές")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:1\")")
    return run(tmp, ["--lane", "W-DUP", "d.sexp"])


@case("N5 ΑΠΩΝ :cluster-roots", "negative", 2, "ΑΠΩΝ :cluster-roots")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:1\")")
    return run(tmp, ["--lane", "W-NOROOTS", "d.sexp"])


@case("N6 ΚΕΝΟ :cluster-roots", "negative", 2, "ΚΕΝΟ :cluster-roots")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:1\")")
    return run(tmp, ["--lane", "W-EMPTY", "d.sexp"])


@case("N7 root ΑΠΟΛΥΤΟ", "negative", 2, "ΑΚΥΡΟ cluster-root")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:1\")")
    return run(tmp, ["--lane", "W-BADROOT", "d.sexp"])


@case("N8 root με «..»", "negative", 2, "ΑΚΥΡΟ cluster-root")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:1\")")
    return run(tmp, ["--lane", "W-TRAV", "d.sexp"])


@case("N9 ΑΠΩΝ dossier — ΟΧΙ σιωπηλή παράλειψη", "negative", 2, "ΑΠΩΝ ή ΜΗ ΚΑΝΟΝΙΚΟ")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:1\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp", "ΔΕΝ-ΥΠΑΡΧΕΙ.sexp"])


@case("N10 ΚΑΜΙΑ είσοδος", "negative", 2, "ΚΑΜΙΑ είσοδος")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"})
    return run(tmp, ["--lane", "W-DIR"])


@case("N11 ΜΗΔΕΝ παραπομπές", "negative", 2, "ΜΗΔΕΝ παραπομπές")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"καμία άγκυρα εδώ\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("N12 ΚΑΚΟΣΧΗΜΑΤΙΣΜΕΝΟ UTF-8 — ΟΧΙ σιωπηλή αλλοίωση", "negative", 2, "MALFORMED UTF-8")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"})
    open(f"{tmp}/d.sexp", "wb").write(b"(:x \"alpha/a.lisp:1\" \"\xff\xfe\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("N13 manifest: ΛΑΘΟΣ ΠΛΗΘΟΣ ΠΕΔΙΩΝ", "negative", 2, "πεδία, αναμ. 7")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"},
          manifest_text="alpha/a.lisp\tfile\t" + "0" * 64 + "\t3\t1\n")
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:1\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("N14 manifest: ΔΙΠΛΗ ΔΙΑΔΡΟΜΗ", "negative", 2, "ΔΙΠΛΗ διαδρομή")
def _(tmp):
    row = "alpha/a.lisp\tfile\t" + "0" * 64 + "\t3\t1\ttext\t1"
    build(tmp, {"alpha/a.lisp": b"l1\n"}, manifest_text=row + "\n" + row + "\n")
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:1\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("N15 manifest: ΑΓΝΩΣΤΟ kind", "negative", 2, "άγνωστο kind")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"},
          manifest_text="alpha/a.lisp\tfifo\t" + "0" * 64 + "\t3\t1\ttext\t1\n")
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:1\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("N16 manifest: ΚΟΜΜΕΝΟ sha256", "negative", 2, "μη πλήρες SHA-256")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"},
          manifest_text="alpha/a.lisp\tfile\tdeadbeef\t3\t1\ttext\t1\n")
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:1\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("N17 manifest: 0 bytes αλλά >0 γραμμές", "negative", 2, "0 bytes αλλά")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"},
          manifest_text="alpha/a.lisp\tfile\t" + "0" * 64 + "\t0\t5\ttext\t1\n")
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:1\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("N18 manifest ΚΕΝΟ", "negative", 2, "MANIFEST ΚΕΝΟ")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"}, manifest_text="")
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:1\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("N19 παραπομπή με «..» — PATH TRAVERSAL", "negative", 1, "PATH TRAVERSAL")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/../alpha/a.lisp:1\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("N20 absolute ΕΚΤΟΣ /frozen/ro/", "negative", 1, "ΜΗ ΔΗΛΩΜΕΝΗ ΜΟΡΦΗ")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"/app/alpha/a.lisp:1\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("N21 ΑΓΝΩΣΤΗ διαδρομή", "negative", 1, "ΑΓΝΩΣΤΗ ΔΙΑΔΡΟΜΗ")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/ghost.lisp:1\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("N22 SYMLINK", "negative", 1, "SYMLINK")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"},
          manifest_rows=["alpha/a.lisp\tsymlink\t" + "0" * 64 + "\t3\t1\ttext\t1"])
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:1\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("N23 ΔΥΑΔΙΚΟ (lines = -1)", "negative", 1, "ΔΥΑΔΙΚΟ ΑΡΧΕΙΟ")
def _(tmp):
    build(tmp, {"alpha/a.zip": b"PK\x03\x04"},
          manifest_rows=["alpha/a.zip\tfile\t" + "0" * 64 + "\t4\t-1\tbinary\t0"])
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.zip:1\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("N24 ΓΡΑΜΜΗ n+1 — off-by-one ΑΠΟΡΡΙΠΤΕΤΑΙ", "negative", 1, "ΕΚΤΟΣ ΕΥΡΟΥΣ")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\nl2\nl3\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:4\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("N25 ΤΕΛΟΣ ΕΥΡΟΥΣ εκτός ορίου", "negative", 1, "ΕΚΤΟΣ ΕΥΡΟΥΣ")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\nl2\nl3\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:2-9\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("N26 ΓΡΑΜΜΗ 0", "negative", 1, "ΕΚΤΟΣ ΕΥΡΟΥΣ")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\nl2\nl3\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:0\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("N27 ΛΑΘΟΣ sha256 prefix", "negative", 1, "ΛΑΘΟΣ HASH")
def _(tmp):
    build(tmp, {"alpha/a.lisp": b"l1\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"alpha/a.lisp:1@sha256:abcdef123456\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


@case("N28 ΚΑΜΙΑ cluster-relative fallback επίλυση", "negative", 1, "ΑΓΝΩΣΤΗ ΔΙΑΔΡΟΜΗ")
def _(tmp):
    # «a.lisp» ΥΠΑΡΧΕΙ ως alpha/a.lisp. Ο v3 θα το μάντευε· ο v4 ΟΧΙ.
    build(tmp, {"alpha/a.lisp": b"l1\n"})
    open(f"{tmp}/d.sexp", "w").write("(:x \"a.lisp:1\")")
    return run(tmp, ["--lane", "W-DIR", "d.sexp"])


def main():
    print(f"resolver υπό δοκιμή: sha256:{sha(open(RESOLVER,'rb').read())}")
    print(f"μάρτυρες: {len(CASES)}")
    fails = []
    for name, kind, exp_exit, exp_sig, fn in CASES:
        tmp = tempfile.mkdtemp(prefix="witness-")
        try:
            r = fn(tmp)
            blob = r.stdout + r.stderr
            ok = (r.returncode == exp_exit) and (exp_sig in blob)
            mark = "✓" if ok else "✗"
            print(f"  {mark} [{kind:8}] {name}  (exit {r.returncode}, αναμ. {exp_exit})")
            if not ok:
                fails.append((name, r.returncode, exp_exit, exp_sig, blob.strip()[:400]))
        finally:
            shutil.rmtree(tmp, ignore_errors=True)
    print()
    pos = sum(1 for c in CASES if c[1] == "positive")
    neg = len(CASES) - pos
    if fails:
        print(f"::error::{len(fails)} ΜΑΡΤΥΡΕΣ ΑΠΕΤΥΧΑΝ")
        for n, got, exp, sig, blob in fails:
            print(f"\n── {n}: exit {got} ≠ {exp}, ζητούμενη υπογραφή «{sig}»\n{blob}")
        return 1
    print(f"WITNESS-SUITE-PASS: {pos} θετικοί · {neg} αρνητικοί · {len(CASES)} σύνολο")
    print("Η πύλη ΑΠΟΔΕΔΕΙΓΜΕΝΑ κοκκινίζει σε κάθε δηλωμένο μονοπάτι απόρριψης.")
    return 0


sys.exit(main())
