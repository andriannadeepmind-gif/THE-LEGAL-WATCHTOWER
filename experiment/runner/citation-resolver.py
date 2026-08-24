#!/usr/bin/env python3
"""ΠΥΛΗ ΑΚΕΡΑΙΟΤΗΤΑΣ ΠΑΡΑΠΟΜΠΩΝ — v6.

ΕΤΥΜΗΓΟΡΙΑ: RECOGNIZED-CITATION-INTEGRITY. Κάθε token παραπομπής ΠΟΥ
ΑΝΑΓΝΩΡΙΣΤΗΚΕ λύνεται σε πραγματικά bytes και πραγματικό εύρος του παγωμένου
snapshot. ΔΕΝ αποδεικνύει ότι κάθε claim έχει παραπομπή (CLAIM-CITATION-
COVERAGE) ούτε ότι το span στηρίζει τον ισχυρισμό (CLAIM-ENTAILMENT).

ΤΙ ΑΛΛΑΞΕ ΑΠΟ ΤΟΝ v5 — ΤΡΕΙΣ ΔΙΟΡΘΩΣΕΙΣ ΚΑΤΑΣΚΕΥΗΣ
────────────────────────────────────────────────────
① ΑΝΑΓΝΩΡΙΣΗ MANIFEST-DRIVEN. Ο v5 είχε ΣΤΑΤΙΚΗ λίστα επεκτάσεων. Αγνοούσε
   σιωπηλά ό,τι δεν είχε «γνωστή» κατάληξη: Dockerfile, .gitignore,
   .dockerignore, .env.example, deps.lock, MANIFEST.sha256,
   everparse.Dockerfile — πραγματικές διαδρομές του σφραγισμένου manifest.
   Η λίστα ΑΦΑΙΡΕΘΗΚΕ ΟΛΟΚΛΗΡΩΤΙΚΑ. Υποψήφια διαδρομή είναι ό,τι στέκεται
   αριστερά της άνω τελείας· η ΕΠΙΛΥΣΗ γίνεται με ΑΚΡΙΒΗ αντιστοίχιση στο
   manifest — καμία ευρετική, κανένα ταίριασμα επιθήματος. Extensionless,
   dotfiles, σύνθετα επιθήματα και executable leaves καλύπτονται εξ ορισμού.
② ΑΣΦΑΛΗΣ ΤΕΡΜΑΤΙΣΜΟΣ. Ο v5 μπορούσε να δεχθεί ΠΡΟΘΕΜΑ token: το
   «file.md:L1-L1@sha256:<12>/garbage» περνούσε ως έγκυρο. Τώρα ό,τι
   ακολουθεί μέχρι τον πρώτο ΕΠΙΤΡΕΠΤΟ τερματιστή είναι μέρος του token, και
   αν δεν είναι κενό το token ΑΠΟΡΡΙΠΤΕΤΑΙ ΟΛΟΚΛΗΡΟ. «/», «%», «?», «#»,
   «=» και κάθε άλλο byte ΔΕΝ τερματίζουν.
③ ΕΝΑ BUFFER. Το dossier διαβάζεται ΜΙΑ φορά σε bytes. Το hash, η
   αποκωδικοποίηση και η κρίση εφαρμόζονται στα ΙΔΙΑ bytes — κανένα reopen.

ΜΟΡΦΗ (PROTOCOL-EPOCH-2): path:L<start>-L<end>@sha256:<12 πεζά δεκαεξαδικά>
ΔΥΟ ΒΑΣΕΙΣ: mount-anchored «<mount>/<path>» · corpus-relative «<path>».
"""
import hashlib
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import frozen_access as fa

RESOLVER_VERSION = "6"
MANIFEST = "experiment/artifacts/corpus-manifest.tsv"
AUTHORITY = "experiment/phase1a/LANE-SCOPE-AUTHORITY.sexp"
MANIFEST_COLUMNS = ("path", "git_mode", "kind", "git_blob_sha1", "content_sha256",
                    "bytes", "logical_lines", "trailing_newline", "class")
HEADER = "#" + "\t".join(MANIFEST_COLUMNS)
SHA_LEN = 12
SCHEMA = 4

import citation_grammar as cg
from citation_grammar import (
    TERMINATORS, PATH_STOP, CANONICAL, LEGACY, SPEC_START, NUMERIC_RUN,
    CODE_LEGACY, CODE_MALFORMED, CODE_UNKNOWN, scan, normalize)


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
            line = text.count("\n", 0, i) + 1
            i += 1
            out, closed = [], False
            while i < n:
                if text[i] == "\\":
                    if i + 1 >= n:
                        raise GateFailure(f"{where}: DANGLING ESCAPE — «\\» στο "
                                          f"τέλος του αρχείου (συμβολοσειρά από "
                                          f"γραμμή {line})")
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
                raise GateFailure(f"{where}: UNTERMINATED STRING που άνοιξε "
                                  f"στη γραμμή {line}")
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


_AUTH_FORMS = None


def _authority():
    global _AUTH_FORMS
    if _AUTH_FORMS is None:
        if not os.path.isfile(AUTHORITY):
            raise GateFailure(f"ΑΠΩΝ το scope authority: {AUTHORITY}")
        _AUTH_FORMS = sexp_parse(
            open(AUTHORITY, encoding="utf-8", errors="strict").read(),
            f"SCOPE-AUTHORITY «{AUTHORITY}»")
    return _AUTH_FORMS


def authority_string(key):
    where = f"SCOPE-AUTHORITY «{AUTHORITY}»"
    hits = [n[k + 1][1] for n in _walk(_authority()) for k in range(len(n) - 1)
            if n[k] == key and isinstance(n[k + 1], tuple) and n[k + 1][0] == "S"]
    if len(hits) != 1:
        raise GateFailure(f"{where}: {len(hits)} τιμές για «{key}» — απαιτείται ΑΚΡΙΒΩΣ 1")
    return hits[0]


def plist_keys(node):
    keys, k = [], 0
    while k < len(node) - 1:
        tok = node[k]
        if isinstance(tok, str) and tok.startswith(":"):
            keys.append(tok)
            k += 2
        else:
            k += 1
    return keys


def load_lane_roots(lane_id):
    where = f"SCOPE-AUTHORITY «{AUTHORITY}»"
    hits = [n for n in _walk(_authority())
            if any(n[k] == ":lane" and n[k + 1] == ("S", lane_id)
                   for k in range(len(n) - 1))]
    if len(hits) != 1:
        raise GateFailure(f"LANE «{lane_id}»: {len(hits)} εγγραφές στο scope "
                          f"authority — απαιτείται ΑΚΡΙΒΩΣ 1")
    entry = hits[0]
    seen = set()
    for key in plist_keys(entry):
        if key in seen:
            raise GateFailure(f"LANE «{lane_id}»: ΔΙΠΛΟ κλειδί «{key}» στην εγγραφή")
        seen.add(key)
    idx = [k for k in range(len(entry) - 1) if entry[k] == ":cluster-roots"]
    if not idx:
        raise GateFailure(f"LANE «{lane_id}»: ΑΠΩΝ :cluster-roots")
    val = entry[idx[0] + 1]
    if not isinstance(val, list):
        raise GateFailure(f"LANE «{lane_id}»: :cluster-roots δεν είναι λίστα")
    if not val:
        raise GateFailure(f"LANE «{lane_id}»: ΚΕΝΟ :cluster-roots")
    roots = []
    for v in val:
        if not (isinstance(v, tuple) and v[0] == "S"):
            raise GateFailure(f"LANE «{lane_id}»: ΜΗ-ΣΥΜΒΟΛΟΣΕΙΡΑ root {v!r} — "
                              f"τα roots είναι ΠΑΝΤΑ strings")
        r = v[1]
        if not r or r.startswith("/") or ".." in r.split("/") or r.endswith("/"):
            raise GateFailure(f"LANE «{lane_id}»: ΑΚΥΡΟ cluster-root «{r}»")
        roots.append(r)
    if len(set(roots)) != len(roots):
        raise GateFailure(f"LANE «{lane_id}»: ΔΙΠΛΟΤΥΠΟ root")
    return roots


def root_matcher(roots):
    dirs, globs = [], []
    for r in roots:
        if "*" in r:
            globs.append(re.compile(
                "".join("[^/]*" if ch == "*" else re.escape(ch) for ch in r) + r"\Z"))
        else:
            dirs.append(r)
    return lambda rel: (any(rel == d or rel.startswith(d + "/") for d in dirs)
                        or any(g.match(rel) for g in globs))


# ══ MANIFEST ══════════════════════════════════════════════════════════════
def load_manifest(path):
    if not os.path.isfile(path):
        raise GateFailure(f"ΑΠΩΝ manifest: {path}")
    raw = open(path, "rb").read()
    text = raw.decode("utf-8")
    lines = text.split("\n")
    if lines[0] != HEADER:
        raise GateFailure(f"MANIFEST: ΛΑΘΟΣ ΚΕΦΑΛΙΔΑ.\n  βρέθηκε: {lines[0]}\n"
                          f"  αναμ.  : {HEADER}")
    if lines[-1] != "":
        raise GateFailure("MANIFEST: ΔΕΝ τερματίζει με newline")
    index, order = {}, []
    for lineno, line in enumerate(lines[1:-1], 2):
        parts = line.split("\t")
        if len(parts) != len(MANIFEST_COLUMNS):
            raise GateFailure(f"MANIFEST γραμμή {lineno}: {len(parts)} πεδία, "
                              f"αναμ. {len(MANIFEST_COLUMNS)}")
        rel, mode, kind, blob, csha, nb, nl, tr, cls = parts
        if rel in index:
            raise GateFailure(f"MANIFEST γραμμή {lineno}: ΔΙΠΛΗ διαδρομή «{rel}»")
        if not rel or rel.startswith("/") or ".." in rel.split("/"):
            raise GateFailure(f"MANIFEST γραμμή {lineno}: ΑΚΥΡΗ διαδρομή «{rel}»")
        if mode not in fa.MODE_KIND:
            raise GateFailure(f"MANIFEST γραμμή {lineno}: ΑΓΝΩΣΤΟ git mode «{mode}»")
        if fa.MODE_KIND[mode] != kind:
            raise GateFailure(f"MANIFEST γραμμή {lineno}: mode «{mode}» ⇒ "
                              f"«{fa.MODE_KIND[mode]}», βρέθηκε kind «{kind}»")
        if not re.fullmatch(r"[0-9a-f]{40}", blob):
            raise GateFailure(f"MANIFEST γραμμή {lineno}: ΑΚΥΡΟ git blob sha1")
        if not re.fullmatch(r"[0-9a-f]{64}", csha):
            raise GateFailure(f"MANIFEST γραμμή {lineno}: μη πλήρες content sha256")
        try:
            nb_i, nl_i, tr_i = int(nb), int(nl), int(tr)
        except ValueError:
            raise GateFailure(f"MANIFEST γραμμή {lineno}: μη αριθμητικά πεδία")
        if nb_i < 0 or tr_i not in (0, 1):
            raise GateFailure(f"MANIFEST γραμμή {lineno}: ασυνεπή αριθμητικά")
        if cls not in ("text", "binary", "symlink"):
            raise GateFailure(f"MANIFEST γραμμή {lineno}: ΑΓΝΩΣΤΗ class «{cls}»")
        if kind == "symlink":
            if cls != "symlink" or nl_i != fa.LINES_SYMLINK or tr_i != 0:
                raise GateFailure(f"MANIFEST γραμμή {lineno}: ασυνεπές symlink")
        else:
            if cls == "symlink":
                raise GateFailure(f"MANIFEST γραμμή {lineno}: class symlink σε μη-symlink")
            if cls == "binary" and (nl_i != fa.LINES_BINARY or tr_i != 0):
                raise GateFailure(f"MANIFEST γραμμή {lineno}: ασυνεπές binary")
            if cls == "text":
                if nl_i < 0:
                    raise GateFailure(f"MANIFEST γραμμή {lineno}: text με αρνητικές γραμμές")
                if nb_i == 0 and (nl_i != 0 or tr_i != 0):
                    raise GateFailure(f"MANIFEST γραμμή {lineno}: ΚΕΝΟ text ⇒ "
                                      f"0 γραμμές ΚΑΙ trailing_newline 0")
                if nb_i > 0 and nl_i == 0:
                    raise GateFailure(f"MANIFEST γραμμή {lineno}: {nb_i} bytes αλλά 0 γραμμές")
                if nl_i > nb_i:
                    raise GateFailure(f"MANIFEST γραμμή {lineno}: {nl_i} γραμμές > {nb_i} bytes")
        index[rel] = {"mode": mode, "kind": kind, "blob": blob, "sha256": csha,
                      "bytes": nb_i, "lines": nl_i, "trailing": tr_i, "class": cls}
        order.append((rel, mode, kind, csha, nb_i))
    if not index:
        raise GateFailure("MANIFEST ΚΕΝΟ — καμία ψευδο-επιτυχία")
    return index, order, raw


def manifest_identity(order, commit, tree):
    leaves = [fa.leaf_hash(rel, mode, kind, csha, nb)
              for rel, mode, kind, csha, nb in
              sorted(order, key=lambda e: e[0].encode("utf-8"))]
    return "sha256:" + fa.corpus_identity(SCHEMA, commit, tree, fa.merkle_root(leaves))


def main():
    args = list(sys.argv[1:])

    def take(flag):
        if flag not in args:
            return None
        i = args.index(flag)
        if i + 1 >= len(args):
            print(f"::error::{flag} χωρίς τιμή")
            sys.exit(2)
        v = args[i + 1]
        del args[i:i + 2]
        return v

    if args.count("--lane") != 1:
        print(f"::error::--lane ΥΠΟΧΡΕΩΤΙΚΟ και ΜΟΝΑΔΙΚΟ "
              f"(βρέθηκε {args.count('--lane')}×)")
        return 2
    lane_id = take("--lane")
    diag_out = take("--diagnostic")
    receipt_out = take("--receipt")
    commit = take("--commit") or "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
    tree = take("--tree") or "23b7a6f4450f50d151d38e13020bee9872e73bcd"

    try:
        mount = authority_string(":read-only-mount")
        with open("/proc/self/mountinfo", encoding="utf-8") as fh:
            opts = next((set(l.split()[5].split(","))
                         for l in fh if len(l.split()) > 5 and l.split()[4] == mount), None)
        if opts is None:
            raise GateFailure(f"ΤΟ {mount} ΔΕΝ ΕΙΝΑΙ MOUNT (καμία εγγραφή στο "
                              f"/proc/self/mountinfo). Καμία πύλη χωρίς την πηγή.")
        for need in ("ro", "nodev", "nosuid", "noexec"):
            if need not in opts:
                raise GateFailure(f"ΤΟ {mount} ΔΕΝ ΕΧΕΙ «{need}»: {sorted(opts)}")
        sealed_identity = authority_string(":identity")
        lane_roots = load_lane_roots(lane_id)
        in_cluster_p = root_matcher(lane_roots)
        index, order, manifest_raw = load_manifest(MANIFEST)
        recomputed = manifest_identity(order, commit, tree)
        if recomputed != sealed_identity:
            raise GateFailure(
                "ΤΑΥΤΟΤΗΤΑ MANIFEST ΔΕΝ ΤΑΙΡΙΑΖΕΙ ΜΕ ΤΗ ΣΦΡΑΓΙΣΜΕΝΗ ΑΥΘΕΝΤΙΑ.\n"
                f"  ξαναϋπολογισμένη : {recomputed}\n"
                f"  σφραγισμένη      : {sealed_identity}")
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

    basenames = {r.rsplit("/", 1)[-1] for r in index}
    rfd = os.open(mount, os.O_RDONLY | os.O_DIRECTORY)
    filecache = {}

    def verify(rel, meta):
        if rel in filecache:
            return filecache[rel]
        try:
            data, st = fa.read_beneath(rfd, rel)
        except OSError as e:
            r = (False, f"ΔΕΝ ΑΝΟΙΓΕΙ ΑΣΦΑΛΩΣ ΣΤΟ SNAPSHOT (errno {e.errno})", None)
            filecache[rel] = r
            return r
        if fa.mode_from_stat(st, meta["kind"]) != meta["mode"]:
            r = (False, f"MODE ΔΙΣΚΟΥ ≠ manifest {meta['mode']}", None)
        elif len(data) != meta["bytes"]:
            r = (False, f"ΠΡΑΓΜΑΤΙΚΑ BYTES {len(data)} ≠ manifest {meta['bytes']}", None)
        elif hashlib.sha256(data).hexdigest() != meta["sha256"]:
            r = (False, f"ΠΡΑΓΜΑΤΙΚΟ SHA-256 "
                        f"{hashlib.sha256(data).hexdigest()[:16]}… ≠ manifest "
                        f"{meta['sha256'][:16]}…", None)
        else:
            cls, lines, trailing = fa.measure(data, meta["kind"])
            if cls != meta["class"] or lines != meta["lines"] or trailing != meta["trailing"]:
                r = (False, f"ΜΕΤΡΗΣΗ ΔΙΣΚΟΥ ({cls},{lines},{trailing}) ≠ manifest "
                            f"({meta['class']},{meta['lines']},{meta['trailing']})", None)
            else:
                r = (True, None, lines)
        filecache[rel] = r
        return r

    total = resolved = in_cluster = 0
    by_form = {"mount-anchored": 0, "corpus-relative": 0}
    problems, diagnostic, dossiers = [], [], []

    for path in args:
        raw = open(path, "rb").read()                    # ③ ΕΝΑ ΚΑΙ ΜΟΝΟ BUFFER
        dsha = hashlib.sha256(raw).hexdigest()
        try:
            text = raw.decode("utf-8")
        except UnicodeDecodeError as e:
            print(f"::error::MALFORMED UTF-8 στο {path}: {e}")
            os.close(rfd)
            return 2
        dossiers.append({"path": path, "bytes": len(raw), "sha256": dsha})
        seen = set()
        for token, run, spec, tail, off in scan(text, index, basenames, mount):
            key = (run, spec, tail)
            if key in seen:
                continue
            seen.add(key)
            total += 1
            rec = {"dossier": path, "token": token, "path": run, "spec": spec,
                   "tail": tail, "offset": off,
                   "line": text.count("\n", 0, off) + 1}

            cm = CANONICAL.match(spec) if not tail else None
            if not cm:
                lm = LEGACY.match(spec) if not tail else None
                rec["form"] = "legacy" if lm else "malformed"
                rec["code"] = CODE_LEGACY if lm else CODE_MALFORMED
                if lm:
                    rec["legacy_start"] = int(lm.group("start"))
                    rec["legacy_end"] = int(lm.group("end")) if lm.group("end") else None
                r2, _, _ = normalize(run, mount)
                if r2 and r2 in index:
                    rec["resolves_to"] = r2
                    rec["real_sha12"] = index[r2]["sha256"][:SHA_LEN]
                    ok, why, rl = verify(r2, index[r2])
                    rec["real_lines"] = rl
                    rec["file_ok"] = ok
                diagnostic.append(rec)
                problems.append((path, token, rec["code"]))
                continue

            rec["form"] = "canonical"
            start, end, sha12 = int(cm.group("start")), int(cm.group("end")), cm.group("sha")
            rel, form, why = normalize(run, mount)
            if rel is None:
                rec["code"] = why
            elif rel not in index:
                rec["code"] = CODE_UNKNOWN
            else:
                meta = index[rel]
                rec["resolves_to"] = rel
                if meta["kind"] not in fa.CITABLE_KINDS:
                    rec["code"] = f"ΜΗ ΠΑΡΑΠΕΜΨΙΜΟ kind «{meta['kind']}»"
                elif meta["class"] != "text":
                    rec["code"] = f"class «{meta['class']}» — δεν έχει γραμμές"
                else:
                    ok, w, real_lines = verify(rel, meta)
                    rec["real_lines"] = real_lines
                    rec["real_sha12"] = meta["sha256"][:SHA_LEN]
                    if not ok:
                        rec["code"] = f"ΕΛΕΓΧΟΣ ΑΡΧΕΙΟΥ ΑΠΕΤΥΧΕ: {w}"
                    elif end < start:
                        rec["code"] = "ΑΝΑΠΟΔΟ ΕΥΡΟΣ"
                    elif start < 1 or end > real_lines:
                        rec["code"] = (f"ΕΚΤΟΣ ΕΥΡΟΥΣ: το αρχείο έχει "
                                       f"{real_lines} λογικές γραμμές")
                    elif not meta["sha256"].startswith(sha12):
                        rec["code"] = (f"ΛΑΘΟΣ HASH: manifest "
                                       f"{meta['sha256'][:SHA_LEN]}")
                    else:
                        rec["code"] = None
                        resolved += 1
                        by_form[form] += 1
                        if in_cluster_p(rel):
                            in_cluster += 1
            diagnostic.append(rec)
            if rec["code"]:
                problems.append((path, token, rec["code"]))

    os.close(rfd)
    self_sha = hashlib.sha256(open(__file__, "rb").read()).hexdigest()
    auth_sha = hashlib.sha256(open(AUTHORITY, "rb").read()).hexdigest()
    man_sha = hashlib.sha256(manifest_raw).hexdigest()
    exit_code = 2 if total == 0 else (1 if problems else 0)

    print(f"resolver v{RESOLVER_VERSION} sha256:{self_sha}")
    print(f"manifest sha256:{man_sha}")
    print(f"scope-authority sha256:{auth_sha}")
    print(f"frozen mount {mount} [ro,nodev,nosuid,noexec] · access {fa.access_mode()}")
    print(f"corpus-identity {sealed_identity} (ξαναϋπολογισμένη από το TSV: ΤΑΥΤΙΖΕΤΑΙ)")
    print(f"lane {lane_id} · cluster-roots {lane_roots}")
    for d in dossiers:
        print(f"dossier {d['path']} {d['bytes']}B sha256:{d['sha256']}")
    print(f"αρχεία επαληθευμένα στο snapshot: "
          f"{sum(1 for v in filecache.values() if v[0])}")
    print(f"παραπομπές: {total} · λύθηκαν: {resolved} · ΠΡΟΒΛΗΜΑΤΙΚΕΣ: {len(problems)}")
    print(f"μορφές: mount-anchored={by_form['mount-anchored']} "
          f"corpus-relative={by_form['corpus-relative']} · "
          f"εντός συστάδας={in_cluster} · εκτός={resolved - in_cluster}")
    for src, cit, why in problems:
        print(f"  ✗ [{src}] {cit} — {why}")

    if diag_out:
        with open(diag_out, "w", encoding="utf-8") as fh:
            json.dump(diagnostic, fh, ensure_ascii=False, indent=1)
    if receipt_out:
        with open(receipt_out, "w", encoding="utf-8") as fh:
            json.dump({"lane": lane_id, "cluster_roots": lane_roots,
                       "resolver_sha256": self_sha, "manifest_sha256": man_sha,
                       "scope_authority_sha256": auth_sha,
                       "corpus_identity": sealed_identity,
                       "access_mechanism": fa.access_mode(),
                       "mount": mount, "dossiers": dossiers,
                       "citations": total, "resolved": resolved,
                       "problems": len(problems),
                       "files_verified": sum(1 for v in filecache.values() if v[0]),
                       "forms": by_form, "in_cluster": in_cluster,
                       "exit_code": exit_code,
                       "verdict": ("RECOGNIZED-CITATION-INTEGRITY" if exit_code == 0
                                   else "FAIL"),
                       "problem_list": [{"dossier": s, "token": t, "code": w}
                                        for s, t, w in problems]}, fh,
                      ensure_ascii=False, indent=1)

    if total == 0:
        print("::error::ΜΗΔΕΝ παραπομπές — ισχυρισμοί χωρίς άγκυρα δεν γίνονται δεκτοί")
        return 2
    if problems:
        return 1
    print("VERDICT: RECOGNIZED-CITATION-INTEGRITY")
    print("  ΤΙ ΣΗΜΑΙΝΕΙ: κάθε token παραπομπής ΠΟΥ ΑΝΑΓΝΩΡΙΣΤΗΚΕ αντιστοιχεί σε")
    print("  πραγματικά bytes και πραγματικό εύρος του παγωμένου snapshot.")
    print("  ΤΙ ΔΕΝ ΣΗΜΑΙΝΕΙ: ΔΕΝ αποδεικνύει ότι κάθε claim ΕΧΕΙ παραπομπή")
    print("  (CLAIM-CITATION-COVERAGE: ΑΝΟΙΧΤΟ) ούτε ότι το cited span ΣΤΗΡΙΖΕΙ")
    print("  τον ισχυρισμό (CLAIM-ENTAILMENT: ΑΝΟΙΧΤΟ). Ούτε είναι read-ledger.")
    return 0


sys.exit(main())
