#!/usr/bin/env python3
"""Content-addressed toolchain manifest — ΚΑΘΕ transitive artifact ονομαστικά.

ΤΙΜΙΟ ΟΡΙΟ (δηλώνεται, δεν κρύβεται): η GPG επαλήθευση του apt αποδεικνύει την
προέλευση των ΜΕΤΑΔΕΔΟΜΕΝΩΝ του αποθετηρίου τη στιγμή της απόκτησης. ΔΕΝ παγώνει
από μόνη της ούτε εκδόσεις ούτε bytes. Το πάγωμα το κάνει ΑΥΤΟ το manifest:
από εδώ και πέρα η ταυτότητα κάθε artifact ΕΙΝΑΙ το sha256 του, και καμία
κατασκευή δεν ξαναρωτά το δίκτυο.
"""
import hashlib, os, subprocess, sys, datetime, json

CACHE = "/var/cache/lawmax-runner"
OUT   = sys.argv[1]

BASE_IMAGE = "ubuntu@sha256:33ceb71981b602c1a7443a53469e4dba065f7503eab3078a2d7a57a2ab987517"
SBCL_FROZEN = "2.4.0"

def load_uris(path):
    m = {}
    if not os.path.exists(path):
        return m
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            p = line.split()
            if len(p) >= 2:
                m[p[1]] = p[0].strip("'")
    return m

def field(deb, name):
    return subprocess.run(["dpkg-deb", "-f", deb, name],
                          capture_output=True, text=True, check=True).stdout.strip()

def ingest_debs(raw_dir, store_dir, uris):
    os.makedirs(store_dir, exist_ok=True)
    rows = []
    for fn in sorted(os.listdir(raw_dir)):
        if not fn.endswith(".deb"):
            continue
        src = os.path.join(raw_dir, fn)
        data = open(src, "rb").read()
        d = hashlib.sha256(data).hexdigest()
        dst = os.path.join(store_dir, d + ".deb")
        if not os.path.exists(dst):
            open(dst, "wb").write(data)
        rows.append({"package": field(src, "Package"), "version": field(src, "Version"),
                     "arch": field(src, "Architecture"), "sha256": d, "bytes": len(data),
                     "url": uris.get(fn, "ΑΓΝΩΣΤΟ")})
    rows.sort(key=lambda r: (r["package"], r["sha256"]))
    return rows

runtime = ingest_debs(f"{CACHE}/debs-raw",       f"{CACHE}/debs",       load_uris(f"{CACHE}/uris.txt"))
build   = ingest_debs(f"{CACHE}/build-debs-raw", f"{CACHE}/build-debs", load_uris(f"{CACHE}/uris-build.txt"))

sources = []
srcdir = f"{CACHE}/src"
for fn in sorted(os.listdir(srcdir)):
    data = open(os.path.join(srcdir, fn), "rb").read()
    sources.append({"name": fn, "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data),
                    "url": f"https://downloads.sourceforge.net/project/sbcl/sbcl/{SBCL_FROZEN}/{fn}"})

allhashes = [r["sha256"] for r in runtime] + [r["sha256"] for r in build] + [s["sha256"] for s in sources]
closure = hashlib.sha256(("".join(sorted(allhashes)) + BASE_IMAGE).encode()).hexdigest()

def emit_pkgs(fh, rows):
    fh.write("  (")
    for i, r in enumerate(rows):
        pre = "" if i == 0 else "   "
        fh.write(f'{pre}(:package "{r["package"]}" :version "{r["version"]}" :arch "{r["arch"]}"\n')
        fh.write(f'    :sha256 "{r["sha256"]}" :bytes {r["bytes"]} :url "{r["url"]}")\n')
    fh.write("  )\n")

with open(OUT, "w", encoding="utf-8") as fh:
    fh.write(";;;; experiment/runner/toolchain.manifest.sexp\n")
    fh.write(";;;; ΠΑΡΑΓΟΜΕΝΟ από gen-toolchain-manifest.py — μην το γράψεις στο χέρι.\n\n")
    fh.write("(:lawmax-runner-toolchain/2\n")
    fh.write(f' :acquired-at "{datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}"\n')
    fh.write(f' :base-image "{BASE_IMAGE}"\n')
    fh.write(f' :sbcl-frozen-version "{SBCL_FROZEN}"\n')
    fh.write(' :sbcl-version-decision\n')
    fh.write('  "ΣΥΝΕΙΔΗΤΗ ΕΠΙΛΟΓΗ: το apt της noble δίνει 2.2.9· το repository ΔΗΛΩΝΕΙ\n')
    fh.write('   ARG SBCL_VERSION=2.4.0 (Dockerfile:16) και ΔΕΝ το επιβάλλει (γραμμή 69,\n')
    fh.write('   apt χωρίς έκδοση). Το 2.2.9 ΔΕΝ παρουσιάζεται ως εκπλήρωση του pin.\n')
    fh.write('   Παγώνουμε το ΔΗΛΩΜΕΝΟ 2.4.0, χτισμένο ΑΠΟ ΠΗΓΗ με bootstrap το 2.2.9,\n')
    fh.write('   και η συμβατότητα αποδεικνύεται με ΠΛΗΡΗ census σουιτών πάνω σε αυτό."\n')
    fh.write(' :acquisition-stage\n')
    fh.write('  (:network :required :script "experiment/runner/fetch-toolchain.sh"\n')
    fh.write('   :verification "apt/GPG στα υπογεγραμμένα InRelease+Packages του archive.ubuntu.com\n')
    fh.write('                  ΓΙΑ ΤΑ .deb· ΓΙΑ ΤΟΝ ΠΗΓΑΙΟ SBCL μόνο sha256 των ληφθέντων bytes")\n')
    fh.write(' :construction-stage (:network :disabled :script "experiment/runner/build-runner.sh")\n')
    fh.write(' :residual-assumptions\n')
    fh.write('  ("Ο πηγαίος SBCL ΔΕΝ επαληθεύτηκε με ανεξάρτητη υπογραφή: το .asc του\n')
    fh.write('    sourceforge επιστρέφει HTML σφάλμα και οι keyservers είναι φραγμένοι.\n')
    fh.write('    Άγκυρα = sha256 των ΑΚΡΙΒΩΝ bytes + το URL. ΔΗΛΩΜΕΝΟ ΥΠΟΛΕΙΜΜΑ."\n')
    fh.write('   "Το base image είναι καρφωμένο σε digest· ο mirror.gcr.io δεν μπορεί να το\n')
    fh.write('    νοθεύσει (content-addressed), αλλά η ΕΠΙΛΟΓΗ του digest έγινε σήμερα.")\n')
    fh.write(f' :runtime-package-count {len(runtime)}\n :runtime-packages\n')
    emit_pkgs(fh, runtime)
    fh.write(f' :build-package-count {len(build)}\n :build-packages\n')
    emit_pkgs(fh, build)
    fh.write(' :source-artifacts\n  (')
    for i, s in enumerate(sources):
        pre = "" if i == 0 else "   "
        fh.write(f'{pre}(:name "{s["name"]}" :sha256 "{s["sha256"]}" :bytes {s["bytes"]}\n')
        fh.write(f'    :url "{s["url"]}" :signature-verified nil)\n')
    fh.write('  )\n')
    fh.write(f' :closure-sha256 "{closure}")\n')

print(json.dumps({"runtime": len(runtime), "build": len(build), "sources": len(sources),
                  "closure": closure}))
