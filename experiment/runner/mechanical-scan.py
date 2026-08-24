#!/usr/bin/env python3
"""ΦΑΣΗ 1A — ΜΗΧΑΝΙΚΟ ΠΕΡΑΣΜΑ πάνω στο ΠΑΓΩΜΕΝΟ corpus.

ΓΙΑΤΙ ΜΗΧΑΝΙΚΟ ΠΡΩΤΑ: ό,τι μπορεί να μετρηθεί ντετερμινιστικά ΔΕΝ επιτρέπεται
να κριθεί από μάτι ή από πράκτορα. Κάθε γραμμή εδώ είναι εύρημα με άγκυρα
path:LINE — επαληθεύσιμο από τρίτον χωρίς εμπιστοσύνη σε κανέναν.

ΔΙΑΒΑΖΕΙ ΜΟΝΟ από /frozen/ro (OS-level read-only).
"""
import os, re, json, sys, collections

RO = "/frozen/ro"
OUT = sys.argv[1]

# Κλάσεις ευρημάτων: (ετικέτα, regex, γιατί μας ενδιαφέρει)
PATTERNS = [
    ("package",        r"^\(defpackage\s+[:#]*([\w.\-*+/]+)",        "έδρα ονομάτων"),
    ("subprocess",     r"(sb-ext:run-program|uiop:run-program|uiop:launch-program)",
                       "ΥΠΟΔΙΕΡΓΑΣΙΑ — το README δηλώνει «the only subprocess is the Lisp runtime itself»"),
    ("env-dependent",  r"(uiop:getenv|sb-posix:getenv|sb-ext:posix-getenv)",
                       "συμπεριφορά που αλλάζει από μεταβλητή περιβάλλοντος = κρυφό μονοπάτι"),
    ("dynamic-eval",   r"(?<!\*)\beval\b(?!-when)",                  "δυναμική αποτίμηση"),
    ("dynamic-intern", r"\b(intern|find-symbol)\b",                  "δυναμική αναζήτηση συμβόλου"),
    ("silent-ignore",  r"\bignore-errors\b",                         "πιθανό σιωπηλό fallback"),
    ("write-file",     r":direction\s+:output",                      "ΕΔΡΑ ΕΓΓΡΑΦΗΣ"),
    ("delete-file",    r"\b(delete-file|sb-posix:unlink)\b",         "καταστροφική πράξη"),
    ("http",           r"(drakma:|dexador|http-request|:https?://)",  "έξοδος στο δίκτυο"),
    ("gate",           r"(defun\s+[\w\-]*gate[\w\-]*|\bGATE\b)",     "πύλη"),
    ("todo",           r"\b(TODO|FIXME|XXX|HACK|ΠΡΟΣΩΡΙΝ)\b",        "δηλωμένο υπόλειμμα"),
]
COMPILED = [(lab, re.compile(rx, re.I | re.M), why) for lab, rx, why in PATTERNS]

FIRST_PARTY_ROOTS = ("source/", "systems/", "authority-v2/", "tests/", "docker/",
                     "scripts/", "deployment/", "tools/", "configs/", "cloudflare/")
SKIP_ROOTS = ("third-party/", "input/", "output/", "output_run1/", "evidence/",
              "releases/", "candidates/", "keys/", "determinism/", "deps/", "state/", "examples/")

hits = collections.defaultdict(list)
files_scanned = 0
packages = []

for dirpath, dirnames, filenames in os.walk(RO):
    dirnames.sort()
    rel_dir = os.path.relpath(dirpath, RO)
    if rel_dir == ".":
        rel_dir = ""
    if any((rel_dir + "/").startswith(s) for s in SKIP_ROOTS):
        dirnames[:] = []
        continue
    for fn in sorted(filenames):
        rel = os.path.join(rel_dir, fn) if rel_dir else fn
        if not fn.endswith((".lisp", ".asd", ".sh", ".py", ".js")):
            continue
        if any(rel.startswith(s) for s in SKIP_ROOTS):
            continue
        try:
            text = open(os.path.join(dirpath, fn), encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        files_scanned += 1
        lines = text.split("\n")
        for lab, rx, _why in COMPILED:
            for m in rx.finditer(text):
                line_no = text.count("\n", 0, m.start()) + 1
                src = lines[line_no - 1].strip()
                if src.startswith(";") or src.startswith("#"):
                    continue                      # σχόλιο, όχι κώδικας
                hits[lab].append((rel, line_no, src[:110]))
                if lab == "package" and m.lastindex:
                    packages.append((m.group(1), rel, line_no))

with open(OUT, "w", encoding="utf-8") as fh:
    fh.write(";;;; experiment/phase1a/mechanical-map.sexp — ΦΑΣΗ 1A, ΜΗΧΑΝΙΚΟ ΠΕΡΑΣΜΑ\n")
    fh.write(";;;; ΠΑΡΑΓΟΜΕΝΟ από experiment/runner/mechanical-scan.py πάνω στο /frozen/ro\n")
    fh.write(";;;; Κάθε γραμμή φέρει άγκυρα path:LINE. Καμία κρίση, μόνο μέτρηση.\n\n")
    fh.write("(:lawmax-phase1a-mechanical/1\n")
    fh.write(' :corpus "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"\n')
    fh.write(f" :files-scanned {files_scanned}\n")
    fh.write(f" :packages-defined {len(packages)}\n")
    fh.write(" :counts (" + " ".join(f"(:{k} {len(v)})" for k, v in sorted(hits.items())) + ")\n")
    for lab, _rx, why in COMPILED:
        rows = hits.get(lab, [])
        fh.write(f"\n ;; ── {lab}: {why} — {len(rows)} ευρήματα\n")
        fh.write(f" :{lab}\n  (")
        for rel, ln, src in rows:
            esc = src.replace("\\", "\\\\").replace('"', '\\"')
            fh.write(f'("{rel}:{ln}" "{esc}")\n   ')
        fh.write(")\n")
    fh.write(")\n")

print(json.dumps({"files_scanned": files_scanned, "packages": len(packages),
                  **{k: len(v) for k, v in sorted(hits.items())}}, ensure_ascii=False))
