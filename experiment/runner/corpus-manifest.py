#!/usr/bin/env python3
"""ΑΚΙΝΗΤΟ CORPUS ΕΙΣΟΔΟΥ — manifest + Merkle root.

Ο αλγόριθμος ΔΕΝ είναι δικός μου: αντιγράφει ΑΚΡΙΒΩΣ το
source/merkle-authority.lisp του ίδιου του corpus (RFC 6962/9162 §2.1.1):
  φύλλο         = sha256(0x00 ‖ ΩΜΑ BYTES)
  εσωτερικός    = sha256(0x01 ‖ raw(αριστερό) ‖ raw(δεξί))
  n>1           ⇒ k = μεγαλύτερη δύναμη του 2 ΑΥΣΤΗΡΑ < n  (ΠΟΤΕ duplicate-last)
  n=1           ⇒ το ίδιο το φύλλο· n=0 ⇒ sha256("")
Έτσι η ρίζα είναι ΑΝΕΞΑΡΤΗΤΑ ΕΠΑΝΑΫΠΟΛΟΓΙΣΙΜΗ από τον κώδικα του συστήματος.
"""
import hashlib, os, sys

ROOT   = sys.argv[1]
OUTDIR = sys.argv[2]
COMMIT = sys.argv[3]

def sha256(b): return hashlib.sha256(b).hexdigest()
def leaf(b):   return "sha256:" + sha256(b"\x00" + b)
def node(l, r):
    return "sha256:" + sha256(b"\x01" + bytes.fromhex(l[7:]) + bytes.fromhex(r[7:]))
def lp2(n):
    k = 1
    while k * 2 < n: k *= 2
    return k
def mth(leaves):
    if not leaves: return "sha256:" + sha256(b"")
    if len(leaves) == 1: return leaves[0]
    k = lp2(len(leaves))
    return node(mth(leaves[:k]), mth(leaves[k:]))

DATA_ROOTS = ("input/", "output/", "output_run1/", "evidence/", "releases/",
              "candidates/", "keys/", "determinism/", "deps/", "state/", "examples/")
def klass(rel):
    if rel.startswith("third-party/"): return "third-party"
    for d in DATA_ROOTS:
        if rel.startswith(d): return "data"
    return "first-party"

rows = []
for dirpath, dirnames, filenames in os.walk(ROOT):
    dirnames.sort()
    for fn in sorted(filenames):
        full = os.path.join(dirpath, fn)
        rel  = os.path.relpath(full, ROOT)
        if os.path.islink(full):
            data = os.readlink(full).encode()
            kind = "symlink"
        else:
            data = open(full, "rb").read()
            kind = "file"
        # §6 ΑΚΡΙΒΕΣ LOGICAL LINE COUNT (όχι απλό count("\n")):
        #   "a\nb\n" ⇒ 2 λογικές γραμμές · "a\nb" ⇒ 2 · "" ⇒ 0
        # Το παλιό σχήμα αποθήκευε newlines και ο resolver δεχόταν πάντα
        # nlines+1 — σε αρχείο που ΤΕΛΕΙΩΝΕΙ σε newline αυτό δεχόταν ΑΝΥΠΑΡΚΤΗ
        # επόμενη γραμμή. Τώρα το όριο είναι ΑΚΡΙΒΩΣ το logical count.
        try:
            text = data.decode("utf-8")
            nl = text.count("\n")
            trailing = 1 if (text.endswith("\n") or text == "") else 0
            lines = nl if trailing else nl + 1
            if text == "":
                lines = 0
        except UnicodeDecodeError:
            lines, trailing = -1, -1        # δυαδικό: ΔΕΝ προσποιούμαστε γραμμές
        rows.append((rel, kind, sha256(data), len(data), lines, klass(rel), trailing))

rows.sort(key=lambda r: r[0].encode())      # ντετερμινιστική σειρά bytes
root = mth([leaf(open(os.path.join(ROOT, r[0]), "rb").read()
                 if r[1] == "file" else os.readlink(os.path.join(ROOT, r[0])).encode())
            for r in rows])

os.makedirs(OUTDIR, exist_ok=True)
tsv = os.path.join(OUTDIR, "corpus-manifest.tsv")
with open(tsv, "w", encoding="utf-8") as fh:
    fh.write("# path\tkind\tsha256\tbytes\tlogical_lines\tclass\ttrailing_newline\n")
    for r in rows:
        fh.write("\t".join(str(x) for x in r) + "\n")
tsv_sha = sha256(open(tsv, "rb").read())

counts = {}
for r in rows: counts[r[5]] = counts.get(r[5], 0) + 1
tbytes = sum(r[3] for r in rows)

with open(os.path.join(OUTDIR, "corpus-manifest.sexp"), "w", encoding="utf-8") as fh:
    fh.write(";;;; experiment/artifacts/corpus-manifest.sexp — ΤΟ ΑΚΙΝΗΤΟ CORPUS\n")
    fh.write(";;;; ΠΑΡΑΓΟΜΕΝΟ από experiment/runner/corpus-manifest.py\n\n")
    fh.write("(:lawmax-frozen-corpus/1\n")
    fh.write(f' :commit "{COMMIT}"\n')
    fh.write(f' :file-count {len(rows)}\n :total-bytes {tbytes}\n')
    fh.write(" :class-counts (")
    fh.write(" ".join(f'(:{k} {v})' for k, v in sorted(counts.items())))
    fh.write(")\n")
    fh.write(' :merkle-algorithm "RFC 6962/9162 §2.1.1 — ΑΚΡΙΒΩΣ source/merkle-authority.lisp του corpus"\n')
    fh.write(f' :merkle-root "{root}"\n')
    fh.write(f' :schema-version 2\n :detail-file "experiment/artifacts/corpus-manifest.tsv"\n')
    fh.write(f' :detail-sha256 "{tsv_sha}"\n')
    fh.write(' :rule "Ό,τι ΔΕΝ είναι σε αυτό το manifest ΔΕΝ υπάρχει για το πείραμα.")\n')

print(f"files={len(rows)} bytes={tbytes} classes={counts}")
print(f"merkle-root={root}")
print(f"tsv-sha256={tsv_sha}")
