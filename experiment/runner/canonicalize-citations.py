#!/usr/bin/env python3
"""ΝΤΕΤΕΡΜΙΝΙΣΤΙΚΗ ΚΑΝΟΝΙΚΟΠΟΙΗΣΗ ΠΑΡΑΠΟΜΠΩΝ — ΜΙΑ ΕΔΡΑ, ΔΥΟ ΤΡΟΠΟΙ.

  --diagnose  ΜΟΝΟ αναφορά· δεν γράφει τίποτα
  --apply     γράφει νέες revisions + πλήρη χάρτη + ΑΝΤΙΣΤΡΟΦΗ ΑΠΟΔΕΙΞΗ

ΚΑΝΟΝΙΣΤΙΚΗ ΜΟΡΦΗ: path:L<start>-L<end>@sha256:<12 πεζά δεκαεξαδικά>

ΤΙ ΜΕΤΑΣΧΗΜΑΤΙΖΕΤΑΙ (ΜΟΝΟ bytes παραπομπής· ΚΑΝΕΝΑ byte ισχυρισμού):
  ① ΜΟΝΗ ΓΡΑΜΜΗ    «:304»            → «:L304-L304@sha256:<12>»
  ② ΕΥΡΟΣ          «:391-397»        → «:L391-L397@sha256:<12>»
  ③ ΛΙΣΤΑ ΚΟΜΜΑΤΟΣ «:L21-22,L98»     → ΔΥΟ ΧΩΡΙΣΤΕΣ κανονικές παραπομπές
     ΓΙΑΤΙ: ο scanner της πύλης βλέπει ΜΟΝΟ το πρώτο στοιχείο μιας λίστας
     κόμματος. Οι υπόλοιπες αναφορές γραμμών ήταν ΑΟΡΑΤΕΣ — ούτε επαληθευμένες
     ούτε καταμετρημένες. Η επέκταση τις ΦΕΡΝΕΙ ΜΕΣΑ στην πύλη.
  Το hash λαμβάνεται ΠΑΝΤΑ από το ΕΠΑΛΗΘΕΥΜΕΝΟ ΠΡΑΓΜΑΤΙΚΟ αρχείο.

ΤΙ ΔΕΝ ΑΓΓΙΖΕΤΑΙ ΠΟΤΕ:
  · παραπομπές που δεν λύνονται μονοσήμαντα (γυμνά ονόματα της Φ1A-L1)
  · παραπομπές με άκυρο εύρος
  · ΚΑΚΟΣΧΗΜΑΤΙΣΜΕΝΕΣ («L1-8+», «194+213») — απαιτούν κρίση διαδρομής
"""
import hashlib
import json
import os
import re
import sys

REPO = "/home/user/THE-LEGAL-WATCHTOWER"
MOUNT = "/frozen/ro"
MANIFEST = f"{REPO}/experiment/artifacts/corpus-manifest.tsv"
EXT = "lisp|asd|md|sexp|sh|py|js|mjs|ts|json|jsonld|yml|yaml|ttl|txt|cddl|zip"
PATHCHARS = r"A-Za-z0-9_./\-Ͱ-Ͽἀ-῿"

FULL = re.compile(
    rf'(?<![\w./-])(?P<path>/?\.?[{PATHCHARS}]+\.(?:{EXT}))'
    r':(?P<spec>L?\d+(?:\s*-\s*L?\d+)?(?:@sha256:[0-9a-fA-F]+)?'
    r'(?:,\s*L?\d+(?:\s*-\s*L?\d+)?)*)'
    r'(?P<tail>(?:[0-9A-Za-z@:_+\-]|\.(?=[0-9A-Za-z]))*)')
ELEM = re.compile(r'\AL?(\d+)(?:\s*-\s*L?(\d+))?\Z')
CANONICAL = re.compile(r'\AL(\d+)-L(\d+)@sha256:([0-9a-f]{12})\Z')


def load_manifest():
    idx = {}
    with open(MANIFEST, encoding="utf-8") as fh:
        fh.readline()
        for line in fh:
            p = line.rstrip("\n").split("\t")
            if len(p) == 9:
                idx[p[0]] = {"sha256": p[4], "lines": int(p[6]), "class": p[8],
                             "kind": p[2]}
    return idx


def open_anchored(rel):
    parts = rel.split("/")
    dfd = os.open(MOUNT, os.O_RDONLY | os.O_DIRECTORY)
    try:
        for c in parts[:-1]:
            nfd = os.open(c, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=dfd)
            os.close(dfd); dfd = nfd
        return os.open(parts[-1], os.O_RDONLY | os.O_NOFOLLOW, dir_fd=dfd)
    finally:
        os.close(dfd)


_v = {}


def real_file(rel, meta):
    """Επιστρέφει (sha12, lines) από ΤΟΝ ΔΙΣΚΟ, ή None."""
    if rel in _v:
        return _v[rel]
    try:
        fd = open_anchored(rel)
    except OSError:
        _v[rel] = None
        return None
    try:
        data = b""
        while True:
            c = os.read(fd, 1 << 20)
            if not c:
                break
            data += c
    finally:
        os.close(fd)
    if hashlib.sha256(data).hexdigest() != meta["sha256"]:
        _v[rel] = None
        return None
    try:
        t = data.decode("utf-8")
    except UnicodeDecodeError:
        _v[rel] = None
        return None
    lines = 0 if t == "" else (t.count("\n") if t.endswith("\n") else t.count("\n") + 1)
    _v[rel] = (meta["sha256"][:12], lines)
    return _v[rel]


def normalize(raw):
    if ".." in raw.split("/"):
        return None
    if raw.startswith("/"):
        return raw[len(MOUNT) + 1:] if raw.startswith(MOUNT + "/") else None
    return raw


def plan(text, index):
    """Επιστρέφει (edits, stats). edits = [(start, end, old, new, kind)]."""
    edits, stats = [], {"canonical": 0, "single": 0, "range": 0, "comma_expanded": 0,
                        "comma_extra_refs": 0, "malformed": 0, "unresolvable": 0,
                        "bad_range": 0}
    for m in FULL.finditer(text):
        raw, spec, tail = m.group("path"), m.group("spec"), m.group("tail")
        if tail:
            stats["malformed"] += 1
            continue
        rel = normalize(raw)
        meta = index.get(rel) if rel else None
        if meta is None or meta["class"] != "text" or meta["kind"] not in ("file", "executable"):
            stats["unresolvable"] += 1
            continue
        rf = real_file(rel, meta)
        if rf is None:
            stats["unresolvable"] += 1
            continue
        sha12, nlines = rf

        if CANONICAL.match(spec):
            stats["canonical"] += 1
            continue

        head, _, rest = spec.partition(",")
        head_core = head.split("@")[0]
        elems = [head_core] + ([e.strip() for e in rest.split(",")] if rest else [])
        parsed, ok = [], True
        for e in elems:
            em = ELEM.match(e.strip())
            if not em:
                ok = False
                break
            a = int(em.group(1))
            b = int(em.group(2)) if em.group(2) else a
            if a < 1 or b > nlines or b < a:
                ok = False
                break
            parsed.append((a, b))
        if not ok:
            stats["bad_range"] += 1
            continue

        new = " ".join(f"{raw}:L{a}-L{b}@sha256:{sha12}" for a, b in parsed)
        kind = ("comma" if len(parsed) > 1
                else ("single" if parsed[0][0] == parsed[0][1] and "-" not in head_core
                      else "range"))
        if kind == "comma":
            stats["comma_expanded"] += 1
            stats["comma_extra_refs"] += len(parsed) - 1
        else:
            stats[kind] += 1
        edits.append((m.start(), m.end(), m.group(0), new, kind))
    return edits, stats


def apply_edits(text, edits):
    out, cur, rev = [], 0, []
    for s, e, old, new, kind in edits:
        out.append(text[cur:s])
        rev.append({"new_offset": sum(len(x) for x in out), "new": new, "old": old,
                    "kind": kind, "old_offset": s})
        out.append(new)
        cur = e
    out.append(text[cur:])
    return "".join(out), rev


def reverse(newtext, rev):
    out, prev = [], 0
    for r in rev:
        o = r["new_offset"]
        if newtext[o:o + len(r["new"])] != r["new"]:
            return None
        out.append(newtext[prev:o])
        out.append(r["old"])
        prev = o + len(r["new"])
    out.append(newtext[prev:])
    return "".join(out)


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "--diagnose"
    targets = sys.argv[2:]
    index = load_manifest()
    report = {}
    for t in targets:
        src = os.path.join(REPO, t)
        text = open(src, encoding="utf-8").read()
        edits, stats = plan(text, index)
        entry = dict(stats)
        entry["edits"] = len(edits)
        entry["source_sha256"] = hashlib.sha256(open(src, "rb").read()).hexdigest()
        if mode == "--apply" and edits:
            new, rev = apply_edits(text, edits)
            back = reverse(new, rev)
            if back != text:
                print(f"::error::{t}: ΑΝΤΙΣΤΡΟΦΗ ΑΠΟΔΕΙΞΗ ΑΠΕΤΥΧΕ — καμία εγγραφή")
                return 2
            entry["reverse_proof"] = "PASS"
            entry["reconstructed_sha256"] = hashlib.sha256(back.encode()).hexdigest()
            base = os.path.basename(t)
            stem = base[:-5]
            nxt = "-rev3" if stem.endswith("-rev2") else "-rev2"
            stem = stem[:-5] if stem.endswith("-rev2") else stem
            out = os.path.join(os.path.dirname(src), stem + nxt + ".sexp")
            open(out, "w", encoding="utf-8").write(new)
            entry["target"] = os.path.relpath(out, REPO)
            entry["target_sha256"] = hashlib.sha256(new.encode()).hexdigest()
            entry["map"] = rev
        report[t] = entry
    dump = {k: {kk: vv for kk, vv in v.items() if kk != "map"} for k, v in report.items()}
    print(json.dumps(dump, ensure_ascii=False, indent=1))
    if mode == "--apply":
        mp = f"{REPO}/experiment/artifacts/l1-admission-forensics/CANONICALIZATION-MAP.json"
        json.dump(report, open(mp, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        print(f"\nΧΑΡΤΗΣ: {os.path.relpath(mp, REPO)}")
    return 0


sys.exit(main())
