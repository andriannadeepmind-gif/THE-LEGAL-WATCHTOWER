#!/usr/bin/env python3
"""ΝΤΕΤΕΡΜΙΝΙΣΤΙΚΗ ΚΑΝΟΝΙΚΟΠΟΙΗΣΗ ΠΑΡΑΠΟΜΠΩΝ — ΜΙΑ ΕΔΡΑ, ΔΥΟ ΤΡΟΠΟΙ.

  --root <dir> --diagnose <αρχεία…>   ΜΟΝΟ αναφορά
  --root <dir> --apply <αρχεία…>      νέες revisions + χάρτης + ΑΝΤΙΣΤΡΟΦΗ ΑΠΟΔΕΙΞΗ

ΚΑΝΟΝΙΣΤΙΚΗ ΜΟΡΦΗ: path:L<start>-L<end>@sha256:<12 πεζά δεκαεξαδικά>

Η ΑΝΑΓΝΩΡΙΣΗ ΕΙΝΑΙ MANIFEST-DRIVEN — ΚΟΙΝΗ ΕΔΡΑ ΜΕ ΤΗΝ ΠΥΛΗ
(citation_grammar). Η προηγούμενη κατασκευή είχε ΔΙΚΗ ΤΗΣ στατική λίστα
επεκτάσεων, οπότε Dockerfile, .gitignore, .dockerignore, .env.example,
deps.lock, MANIFEST.sha256 και κάθε extensionless/dotfile/σύνθετο επίθημα ΔΕΝ
κανονικοποιήθηκαν ΠΟΤΕ — και εμφανίστηκαν ως legacy στην πύλη. Μία γραμματική,
μία συμπεριφορά.

ΤΙ ΜΕΤΑΣΧΗΜΑΤΙΖΕΤΑΙ (ΜΟΝΟ bytes παραπομπής· ΚΑΝΕΝΑ byte ισχυρισμού):
  ① «:304» → «:L304-L304@sha256:<12>»
  ② «:391-397» → «:L391-L397@sha256:<12>»
  ③ «:L21-22,L98» → ΔΥΟ ΧΩΡΙΣΤΕΣ κανονικές παραπομπές
Το hash λαμβάνεται ΠΑΝΤΑ από το ΕΠΑΛΗΘΕΥΜΕΝΟ ΠΡΑΓΜΑΤΙΚΟ αρχείο του snapshot.

ΤΙ ΔΕΝ ΑΓΓΙΖΕΤΑΙ ΠΟΤΕ: μη μονοσήμαντα (γυμνά ονόματα), άκυρα εύρη, και
ΚΑΘΕ κακοσχηματισμένο token — μαζί με τα έγκυρα στοιχεία που συνυπάρχουν
μέσα του: ποτέ δεν γίνεται δεκτό έγκυρο ΠΡΟΘΕΜΑ κακοσχηματισμένου token.
"""
import hashlib
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import frozen_access as fa
import citation_grammar as cg

REPO = "/home/user/THE-LEGAL-WATCHTOWER"
MANIFEST = f"{REPO}/experiment/artifacts/corpus-manifest.tsv"
ELEM = re.compile(r'\AL?(\d+)(?:\s*-\s*L?(\d+))?\Z')
REV = re.compile(r'\A(?P<stem>.+?)(?:-rev(?P<n>\d+))?\.sexp\Z')


def load_manifest():
    idx = {}
    with open(MANIFEST, encoding="utf-8") as fh:
        fh.readline()
        for line in fh:
            p = line.rstrip("\n").split("\t")
            if len(p) == 9:
                idx[p[0]] = {"mode": p[1], "kind": p[2], "sha256": p[4],
                             "bytes": int(p[5]), "lines": int(p[6]),
                             "trailing": int(p[7]), "class": p[8]}
    return idx


def plan(text, index, basenames, mount, rfd, cache):
    edits = []
    stats = dict(canonical=0, single=0, range=0, comma_expanded=0,
                 comma_extra_refs=0, malformed=0, unresolvable=0, bad_range=0)
    COMMA_TAIL = re.compile(r'\A(?:,\s*L?\d+(?:\s*-\s*L?\d+)?)+\Z')
    for token, run, spec, tail, off in cg.scan(text, index, basenames, mount):
        if tail:
            # ΛΙΣΤΑ ΚΟΜΜΑΤΟΣ: ο σαρωτής της πύλης δίνει ΜΟΝΟ το πρώτο στοιχείο
            # ως spec και τα υπόλοιπα ως tail — σωστά, γιατί για την ΠΥΛΗ το
            # token είναι ΟΛΟΚΛΗΡΟ κακοσχηματισμένο. Ο ΚΑΝΟΝΙΚΟΠΟΙΗΤΗΣ όμως
            # ΠΡΕΠΕΙ να τις επεκτείνει, αλλιώς οι αναφορές μένουν αόρατες για
            # πάντα. Ενώνουμε ΜΟΝΟ όταν το tail είναι ΑΚΡΙΒΩΣ λίστα κόμματος.
            if COMMA_TAIL.match(tail):
                spec = spec + tail
            else:
                stats["malformed"] += 1
                continue
        if cg.CANONICAL.match(spec):
            stats["canonical"] += 1
            continue
        rel, form, why = cg.normalize(run, mount)
        meta = index.get(rel) if rel else None
        if (meta is None or meta["class"] != "text"
                or meta["kind"] not in fa.CITABLE_KINDS):
            stats["unresolvable"] += 1
            continue
        if rel not in cache:
            try:
                data, st = fa.read_beneath(rfd, rel)
            except OSError:
                cache[rel] = None
            else:
                ok = (hashlib.sha256(data).hexdigest() == meta["sha256"]
                      and len(data) == meta["bytes"]
                      and fa.mode_from_stat(st, meta["kind"]) == meta["mode"])
                cls, lines, trailing = fa.measure(data, meta["kind"])
                cache[rel] = ((meta["sha256"][:cg.SHA_LEN], lines)
                              if ok and (cls, lines, trailing) ==
                              (meta["class"], meta["lines"], meta["trailing"]) else None)
        if cache[rel] is None:
            stats["unresolvable"] += 1
            continue
        sha12, nlines = cache[rel]

        head, _, rest = spec.partition(",")
        head = head.split("@")[0]
        elems = [head] + ([e.strip() for e in rest.split(",")] if rest else [])
        parsed, ok = [], True
        for e in elems:
            em = ELEM.match(e)
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

        new = " ".join(f"{run}:L{a}-L{b}@sha256:{sha12}" for a, b in parsed)
        if len(parsed) > 1:
            stats["comma_expanded"] += 1
            stats["comma_extra_refs"] += len(parsed) - 1
            kind = "comma"
        elif parsed[0][0] == parsed[0][1] and "-" not in head:
            stats["single"] += 1
            kind = "single"
        else:
            stats["range"] += 1
            kind = "range"
        edits.append((off, off + len(token), token, new, kind))
    return edits, stats


def apply_edits(text, edits):
    out, cur, rev = [], 0, []
    for s, e, old, new, kind in sorted(edits):
        out.append(text[cur:s])
        rev.append({"new_offset": sum(len(x) for x in out), "new": new,
                    "old": old, "kind": kind, "old_offset": s})
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


def next_revision(path):
    m = REV.match(os.path.basename(path))
    n = int(m.group("n") or 1) + 1
    return os.path.join(os.path.dirname(path), f"{m.group('stem')}-rev{n}.sexp")


def main():
    a = sys.argv[1:]
    root = a[a.index("--root") + 1] if "--root" in a else None
    if not root:
        print("::error::--root ΥΠΟΧΡΕΩΤΙΚΟ")
        return 2
    apply_mode = "--apply" in a
    flag = "--apply" if apply_mode else "--diagnose"
    targets = a[a.index(flag) + 1:]
    index = load_manifest()
    basenames = {r.rsplit("/", 1)[-1] for r in index}
    rfd = os.open(root, os.O_RDONLY | os.O_DIRECTORY)
    cache, report = {}, {}
    try:
        for t in targets:
            src = os.path.join(REPO, t)
            raw = open(src, "rb").read()
            text = raw.decode("utf-8")
            edits, stats = plan(text, index, basenames, root, rfd, cache)
            e = dict(stats)
            e["edits"] = len(edits)
            e["source_sha256"] = hashlib.sha256(raw).hexdigest()
            if apply_mode and edits:
                new, rev = apply_edits(text, edits)
                if reverse(new, rev) != text:
                    print(f"::error::{t}: ΑΝΤΙΣΤΡΟΦΗ ΑΠΟΔΕΙΞΗ ΑΠΕΤΥΧΕ — καμία εγγραφή")
                    return 2
                e["reverse_proof"] = "PASS"
                out = next_revision(src)
                open(out, "w", encoding="utf-8").write(new)
                e["target"] = os.path.relpath(out, REPO)
                e["target_sha256"] = hashlib.sha256(new.encode()).hexdigest()
                e["map"] = rev
            report[t] = e
    finally:
        os.close(rfd)
    print(json.dumps({k: {kk: vv for kk, vv in v.items() if kk != "map"}
                      for k, v in report.items()}, ensure_ascii=False, indent=1))
    if apply_mode:
        mp = f"{REPO}/experiment/artifacts/l1-admission-forensics/CANONICALIZATION-MAP.json"
        json.dump(report, open(mp, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    return 0


sys.exit(main())
