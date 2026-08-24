#!/usr/bin/env python3
"""ΠΥΛΗ ΑΚΕΡΑΙΟΤΗΤΑΣ ΠΑΡΑΠΟΜΠΩΝ (versioned gate) — v4.

ΤΙ ΑΠΟΔΕΙΚΝΥΕΙ: CITATION-INTEGRITY-PASS — ότι κάθε token παραπομπής μέσα στο
dossier λύνεται σε υπαρκτό αρχείο, υπαρκτό εύρος γραμμών και (όπου δίνεται)
σωστό sha256 του ΠΑΓΩΜΕΝΟΥ manifest.

ΤΙ ΔΕΝ ΑΠΟΔΕΙΚΝΥΕΙ — ΔΗΛΩΜΕΝΟ ΡΗΤΑ:
  · ΔΕΝ είναι CLAIM-ENTAILMENT-PASS. Δεν αποδεικνύει ότι το cited span
    ΣΤΗΡΙΖΕΙ τον ισχυρισμό — μόνο ότι το span ΥΠΑΡΧΕΙ.
  · ΔΕΝ αποδεικνύει ότι κάθε ουσιώδης ισχυρισμός ΕΧΕΙ παραπομπή.
  · ΔΕΝ είναι read-ledger: δεν λέει τι ΔΙΑΒΑΣΕ ο πράκτορας.

ΔΥΟ ΚΑΙ ΜΟΝΟ ΔΥΟ ΜΟΡΦΕΣ ΠΑΡΑΠΟΜΠΗΣ — η βάση επίλυσης ΔΗΛΩΝΕΤΑΙ, δεν μαντεύεται:
  ① MOUNT-ANCHORED   /frozen/ro/<path>:L…   βάση = το δηλωμένο read-only mount
  ② CORPUS-RELATIVE  <path>:L…              βάση = ΠΑΝΤΑ η ρίζα του corpus
Καμία τρίτη ερμηνεία. ΚΑΜΙΑ fallback επίλυση cluster-relative: ένα σχετικό
path ΔΕΝ δοκιμάζεται ποτέ ως cluster-relative αν αποτύχει ως corpus-relative —
αυτό ήταν existence-based guessing και αφαιρέθηκε.

Τα cluster-roots της lane χρησιμοποιούνται ΜΟΝΟ για ΑΝΑΦΟΡΑ ΠΕΡΙΕΚΤΙΚΟΤΗΤΑΣ
(πόσες παραπομπές είναι εντός/εκτός της συστάδας), ΠΟΤΕ για επίλυση.
"""
import hashlib
import os
import re
import sys

RESOLVER_VERSION = "4"
MANIFEST = "experiment/artifacts/corpus-manifest.tsv"
REGISTRY = "experiment/phase1a/LANE-REGISTRY.sexp"
FROZEN_MOUNT = "/frozen/ro/"
VALID_KINDS = {"file", "symlink"}

CITATION = re.compile(
    r'(?<![\w./-])(/?\.?[A-Za-z0-9_./\-Ͱ-Ͽ]+\.'
    r'(?:lisp|asd|md|sexp|sh|py|js|mjs|ts|json|jsonld|yml|yaml|ttl|txt|cddl|zip))'
    r':L?(\d+)(?:\s*-\s*L?(\d+))?'
    r'(?:@sha256:([0-9a-f]{6,64}))?'
)


class GateFailure(Exception):
    pass


# ── DATA-ONLY S-EXPRESSION PARSER (§1: ΟΧΙ regex πάνω σε sexp) ──────────────
def sexp_tokens(text):
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c in " \t\n\r\f":
            i += 1; continue
        if c == ";":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if c == '"':
            i += 1; start = i; out = []
            while i < n:
                if text[i] == "\\":
                    out.append(text[i + 1]); i += 2; continue
                if text[i] == '"':
                    i += 1; break
                out.append(text[i]); i += 1
            yield ("str", "".join(out)); continue
        if c in "()":
            yield ("paren", c); i += 1; continue
        j = i
        while j < n and text[j] not in " \t\n\r\f()\";":
            j += 1
        yield ("atom", text[i:j]); i = j


def sexp_parse(text):
    """Επιστρέφει λίστα από top-level forms. Data-only: καμία αποτίμηση."""
    stack, out = [], []
    for kind, tok in sexp_tokens(text):
        if kind == "paren" and tok == "(":
            new = []
            (stack[-1] if stack else out).append(new)
            stack.append(new)
        elif kind == "paren" and tok == ")":
            if not stack:
                raise GateFailure("REGISTRY: αταίριαστη «)»")
            stack.pop()
        else:
            (stack[-1] if stack else out).append(("S", tok) if kind == "str" else tok)
    if stack:
        raise GateFailure("REGISTRY: μη κλεισμένη παρένθεση")
    return out


def _walk(node):
    if isinstance(node, list):
        yield node
        for x in node:
            yield from _walk(x)


def load_lane_roots(lane_id):
    """§1/§3: ακριβώς ΜΙΑ εγγραφή για το lane· ρητά cluster-roots· αλλιώς αποτυχία."""
    if not os.path.exists(REGISTRY):
        raise GateFailure(f"ΑΠΩΝ το lane registry: {REGISTRY}")
    forms = sexp_parse(open(REGISTRY, encoding="utf-8").read())
    hits = []
    for node in _walk(forms):
        for k in range(len(node) - 1):
            if node[k] == ":lane" and node[k + 1] == ("S", lane_id):
                hits.append(node)
                break
    if len(hits) != 1:
        raise GateFailure(
            f"LANE «{lane_id}»: βρέθηκαν {len(hits)} εγγραφές στο registry — απαιτείται ΑΚΡΙΒΩΣ 1")
    entry = hits[0]
    roots = None
    for k in range(len(entry) - 1):
        if entry[k] == ":cluster-roots":
            val = entry[k + 1]
            if not isinstance(val, list):
                raise GateFailure(f"LANE «{lane_id}»: :cluster-roots δεν είναι λίστα")
            roots = [v[1] for v in val if isinstance(v, tuple) and v[0] == "S"]
            break
    if roots is None:
        raise GateFailure(f"LANE «{lane_id}»: ΑΠΩΝ :cluster-roots")
    if not roots:
        raise GateFailure(f"LANE «{lane_id}»: ΚΕΝΟ :cluster-roots — καμία συστάδα δεν είναι κενή")
    for r in roots:
        if not r or r.startswith("/") or ".." in r.split("/") or r.endswith("/"):
            raise GateFailure(f"LANE «{lane_id}»: ΑΚΥΡΟ cluster-root «{r}»")
    return roots


def root_matcher(roots):
    """§3: ΔΗΛΩΜΕΝΗ σημασιολογία root — δύο μορφές, καμία τρίτη.

    ① χωρίς «*» ⇒ ΚΑΤΑΛΟΓΟΣ: rel == d ή rel αρχίζει με d+"/"
    ② με «*»    ⇒ GLOB σε ΟΛΟΚΛΗΡΟ το rel, όπου «*» ΔΕΝ διασχίζει «/»
    Η σημασιολογία είναι σφραγισμένη στο LANE-REGISTRY :cluster-root-semantics.
    """
    dirs, globs = [], []
    for r in roots:
        if "*" in r:
            globs.append(re.compile(
                "".join("[^/]*" if ch == "*" else re.escape(ch) for ch in r) + r"\Z"))
        else:
            dirs.append(r)

    def matches(rel):
        for d in dirs:
            if rel == d or rel.startswith(d + "/"):
                return True
        return any(g.match(rel) for g in globs)

    return matches


# ── MANIFEST — ΑΥΣΤΗΡΟΣ (§7) ───────────────────────────────────────────────
def load_manifest(path):
    index = {}
    with open(path, encoding="utf-8") as fh:
        for lineno, line in enumerate(fh, 1):
            if line.startswith("#"):
                continue
            parts = line.rstrip("\n").split("\t")
            if len(parts) != 7:
                raise GateFailure(f"MANIFEST γραμμή {lineno}: {len(parts)} πεδία, αναμ. 7")
            rel, kind, sha, nbytes, lines, cls, trailing = parts
            if rel in index:
                raise GateFailure(f"MANIFEST γραμμή {lineno}: ΔΙΠΛΗ διαδρομή «{rel}»")
            if kind not in VALID_KINDS:
                raise GateFailure(f"MANIFEST γραμμή {lineno}: άγνωστο kind «{kind}»")
            if not re.fullmatch(r"[0-9a-f]{64}", sha):
                raise GateFailure(f"MANIFEST γραμμή {lineno}: μη πλήρες SHA-256")
            try:
                nbytes_i, lines_i, trail_i = int(nbytes), int(lines), int(trailing)
            except ValueError:
                raise GateFailure(f"MANIFEST γραμμή {lineno}: μη αριθμητικά πεδία")
            if nbytes_i < 0 or (lines_i < 0 and lines_i != -1):
                raise GateFailure(f"MANIFEST γραμμή {lineno}: ασυνεπή bytes/γραμμές")
            if nbytes_i == 0 and lines_i > 0:
                raise GateFailure(f"MANIFEST γραμμή {lineno}: 0 bytes αλλά {lines_i} γραμμές")
            index[rel] = (sha, lines_i, kind, trail_i)
    if not index:
        raise GateFailure("MANIFEST ΚΕΝΟ — καμία ψευδο-επιτυχία")
    return index


def normalize(raw):
    """Δύο μορφές, καμία τρίτη. Επιστρέφει (canonical, form) ή σφάλμα."""
    if ".." in raw.split("/"):
        return None, None, "PATH TRAVERSAL: περιέχει «..»"
    if raw.startswith("/"):
        if not raw.startswith(FROZEN_MOUNT):
            return None, None, f"ΜΗ ΔΗΛΩΜΕΝΗ ΜΟΡΦΗ: absolute εκτός {FROZEN_MOUNT}"
        return raw[len(FROZEN_MOUNT):], "mount-anchored", None
    return raw, "corpus-relative", None


def main():
    args = list(sys.argv[1:])
    # §3: --lane ΥΠΟΧΡΕΩΤΙΚΟ, ΜΟΝΑΔΙΚΟ
    if args.count("--lane") != 1:
        print(f"::error::--lane ΥΠΟΧΡΕΩΤΙΚΟ και ΜΟΝΑΔΙΚΟ (βρέθηκε {args.count('--lane')}×)")
        return 2
    i = args.index("--lane")
    if i + 1 >= len(args):
        print("::error::--lane χωρίς τιμή")
        return 2
    lane_id = args[i + 1]
    del args[i:i + 2]

    try:
        lane_roots = load_lane_roots(lane_id)
        in_lane_cluster = root_matcher(lane_roots)
        index = load_manifest(MANIFEST)
    except GateFailure as e:
        print(f"::error::{e}")
        return 2

    # §4: ΚΑΘΕ ζητούμενο dossier πρέπει να υπάρχει και να είναι regular file
    missing = [p for p in args if not os.path.isfile(p)]
    if missing:
        for p in missing:
            print(f"::error::ΑΠΩΝ ή ΜΗ ΚΑΝΟΝΙΚΟ ΑΡΧΕΙΟ: {p}")
        return 2
    if not args:
        print("::error::ΚΑΜΙΑ είσοδος — καμία ψευδο-επιτυχία")
        return 2

    manifest_sha = hashlib.sha256(open(MANIFEST, "rb").read()).hexdigest()
    registry_sha = hashlib.sha256(open(REGISTRY, "rb").read()).hexdigest()
    self_sha = hashlib.sha256(open(__file__, "rb").read()).hexdigest()

    total = resolved = in_cluster = 0
    by_form = {"mount-anchored": 0, "corpus-relative": 0}
    problems = []
    dossier_hashes = {}

    for path in args:
        dossier_hashes[path] = hashlib.sha256(open(path, "rb").read()).hexdigest()
        try:
            # §5: STRICT decoding — malformed UTF-8 ⇒ αποτυχία, όχι σιωπηλή αλλοίωση
            text = open(path, encoding="utf-8", errors="strict").read()
        except UnicodeDecodeError as e:
            print(f"::error::MALFORMED UTF-8 στο {path}: {e}")
            return 2
        seen = set()
        for m in CITATION.finditer(text):
            raw, start = m.group(1), int(m.group(2))
            end, sha12 = m.group(3), m.group(4)
            key = (raw, start, end, sha12)
            if key in seen:
                continue
            seen.add(key)
            total += 1

            rel, form, why = normalize(raw)
            if rel is None:
                problems.append((path, m.group(0), why)); continue
            if rel not in index:
                problems.append((path, m.group(0), "ΑΓΝΩΣΤΗ ΔΙΑΔΡΟΜΗ στο manifest")); continue
            sha, nlines, kind, _trailing = index[rel]
            if kind == "symlink":
                problems.append((path, m.group(0), "SYMLINK — δεν παραπέμπουμε σε σύνδεσμο")); continue
            if nlines < 0:
                problems.append((path, m.group(0), "ΔΥΑΔΙΚΟ ΑΡΧΕΙΟ — δεν έχει γραμμές")); continue
            # §6: ΑΚΡΙΒΕΣ όριο — logical line count, ΟΧΙ nlines+1
            hi = int(end) if end else start
            if start < 1 or hi > nlines:
                problems.append((path, m.group(0),
                                 f"ΕΚΤΟΣ ΕΥΡΟΥΣ: το αρχείο έχει {nlines} λογικές γραμμές")); continue
            if end and int(end) < start:
                problems.append((path, m.group(0), "ΑΝΑΠΟΔΟ ΕΥΡΟΣ")); continue
            if sha12 and not sha.startswith(sha12):
                problems.append((path, m.group(0), f"ΛΑΘΟΣ HASH: manifest {sha[:12]}")); continue
            resolved += 1
            by_form[form] += 1
            if in_lane_cluster(rel):
                in_cluster += 1

    print(f"resolver v{RESOLVER_VERSION} sha256:{self_sha}")
    print(f"manifest sha256:{manifest_sha}")
    print(f"registry sha256:{registry_sha}")
    print(f"lane {lane_id} · cluster-roots {lane_roots}")
    for p, h in dossier_hashes.items():
        print(f"dossier {p} sha256:{h}")
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
    print("VERDICT: CITATION-INTEGRITY-PASS "
          "(ΟΧΙ claim-entailment· ΟΧΙ απόδειξη πληρότητας παραπομπών· ΟΧΙ read-ledger)")
    return 0


sys.exit(main())
