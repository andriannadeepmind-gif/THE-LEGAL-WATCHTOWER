#!/usr/bin/env python3
"""ΑΝΕΞΑΡΤΗΤΟΣ ΕΠΑΛΗΘΕΥΤΗΣ ΤΩΝ ΑΛΥΣΙΔΩΝ ΑΝΑΘΕΩΡΗΣΗΣ.

ΔΕΝ ΕΙΣΑΓΕΙ ΚΑΙ ΔΕΝ ΚΑΛΕΙ citation-resolver, canonicalize-citations,
citation_grammar Ή frozen_access. Δικός του σαρωτής, δική του απαρίθμηση
(git ls-tree), δική του ανάγνωση, δικός του ορισμός ταυτότητας.

ΤΟ ΚΕΝΤΡΙΚΟ ΑΝΑΛΛΟΙΩΤΟ — ΙΣΧΥΡΟΤΕΡΟ ΑΠΟ ΕΛΕΓΧΟ ΧΑΡΤΗ
──────────────────────────────────────────────────────
Δεν εμπιστεύεται τον χάρτη μετασχηματισμού· ΞΑΝΑΠΑΡΑΓΕΙ την ιδιότητα:

    ΣΚΕΛΕΤΟΣ(κείμενο) = το κείμενο με ΚΑΘΕ αναγνωρισμένη παραπομπή
                        αντικατεστημένη από ένα σημάδι, και κάθε ακολουθία
                        σημαδιών χωρισμένων με κενό συμπτυγμένη σε ένα.

Αν ΣΚΕΛΕΤΟΣ(rev_n) == ΣΚΕΛΕΤΟΣ(rev_n+1) BYTE-FOR-BYTE, τότε ΤΙΠΟΤΑ εκτός
των bytes παραπομπής δεν άλλαξε — ανεξάρτητα από το τι λέει οποιοσδήποτε
χάρτης. Η σύμπτυξη επιτρέπει την επέκταση λίστας κόμματος (ένα token γίνεται
πολλά, χωρισμένα με κενό) ΧΩΡΙΣ να επιτρέπει καμία άλλη μεταβολή.

ΕΜΒΕΛΕΙΑ: μετασχηματισμός και αγκύρωση. ΟΧΙ αλήθεια ισχυρισμών.
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import time

REPO = "/home/user/THE-LEGAL-WATCHTOWER"
COMMIT = "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
MOUNT = "/frozen/ro"
MARK = "\x01"

# ΔΙΚΟΣ ΤΟΥ σαρωτής — γραμμένος ανεξάρτητα.
PATH_STOP = set(' \t\n\r\f\v"\'`()[]{}<>;«»·|…,:')   # ΑΡΙΣΤΕΡΑ: «:» σταματά
TERM = set(' \t\n\r\f\v"\'`()[]{}<>;«»·|…')           # ΔΕΞΙΑ: «:» ΟΧΙ (@sha256:)
SPEC = re.compile(r'L?\d')
CANON = re.compile(r'\AL(\d+)-L(\d+)@sha256:([0-9a-f]{12})\Z')

fails, notes = [], []


def ok(cond, good, bad):
    (notes if cond else fails).append(good if cond else bad)
    return cond


def tree_paths():
    out = subprocess.run(["git", "-C", REPO, "ls-tree", "-r", "-z",
                          "--full-tree", COMMIT], capture_output=True,
                         check=True).stdout
    d = {}
    for rec in out.split(b"\0"):
        if not rec:
            continue
        meta, _, path = rec.partition(b"\t")
        mode, _t, sha = (x.decode() for x in meta.split(b" "))
        d[path.decode("utf-8")] = (mode, sha)
    return d


def find_citations(text, paths, basenames):
    """[(start, end, run, blob)] — δική του υλοποίηση."""
    out, i, n = [], 0, len(text)
    while True:
        c = text.find(":", i)
        if c < 0:
            break
        i = c + 1
        if not SPEC.match(text, c + 1):
            continue
        j = c
        while j > 0 and text[j - 1] not in PATH_STOP:
            j -= 1
        run = text[j:c]
        if not run:
            continue
        base = run.rsplit("/", 1)[-1]
        if not (run in paths or run.startswith(MOUNT + "/") or base in basenames
                or ("/" in run and not re.fullmatch(r"\d+(\.\d+)*", run))):
            continue
        k = c + 1
        while k < n:
            ch = text[k]
            if ch == "." and (k + 1 >= n or not text[k + 1].isalnum()):
                break
            if ch == "," and SPEC.match(text, k + 1):
                k += 1
                continue
            if ch == ":":
                if k + 1 >= n or not text[k + 1].isalnum():
                    break                     # άνω τελεία στίξης
                k += 1                        # μέρος του «@sha256:»
                continue
            if ch in TERM or ch == ",":
                break
            k += 1
        out.append((j, k, run, text[c + 1:k]))
    return out


def skeleton(text, paths, basenames):
    cits = find_citations(text, paths, basenames)
    buf, cur = [], 0
    for s, e, _r, _b in cits:
        buf.append(text[cur:s])
        buf.append(MARK)
        cur = e
    buf.append(text[cur:])
    sk = "".join(buf)
    return re.sub(f"{MARK}(?: +{MARK})+", MARK, sk), cits


def read_frozen(rel):
    """Ανάγνωση χωρίς ακολούθηση symlink σε κανένα συστατικό — δική του κάθοδος."""
    parts = rel.split("/")
    dfd = os.open(MOUNT, os.O_RDONLY | os.O_DIRECTORY)
    try:
        for comp in parts[:-1]:
            nfd = os.open(comp, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=dfd)
            os.close(dfd)
            dfd = nfd
        fd = os.open(parts[-1], os.O_RDONLY | os.O_NOFOLLOW, dir_fd=dfd)
    finally:
        os.close(dfd)
    try:
        b = b""
        while True:
            ch = os.read(fd, 1 << 20)
            if not ch:
                break
            b += ch
        return b
    finally:
        os.close(fd)


CHAINS = {
 "Φ1A-L1": ["source.sexp", "source-rev2.sexp", "source-rev3.sexp"],
 "Φ1A-L2": ["systems.sexp", "systems-rev2.sexp"],
 "Φ1A-L3": ["authority-v2.sexp", "authority-v2-rev2.sexp",
            "authority-v2-rev3.sexp", "authority-v2-rev4.sexp"],
 "Φ1A-L4": ["deployment-specs.sexp", "deployment-specs-rev2.sexp",
            "deployment-specs-rev3.sexp"],
 "Φ1A-L5": ["deployment-state.sexp", "deployment-state-rev2.sexp",
            "deployment-state-rev3.sexp", "deployment-state-rev4.sexp"],
 "Φ1A-L6": ["harness.sexp", "harness-rev2.sexp", "harness-rev3.sexp",
            "harness-rev4.sexp"],
 "Φ1A-L7": ["contracts.sexp", "contracts-rev2.sexp", "contracts-rev3.sexp"],
}
L7_SPLIT = ("DEPENDENCY-CONTRACT.md:194+213", "DEPENDENCY-CONTRACT.md", 194, 213)


def main():
    with open("/proc/self/mountinfo", encoding="utf-8") as fh:
        mounted = any(len(l.split()) > 5 and l.split()[4] == MOUNT for l in fh)
    if not ok(mounted, f"{MOUNT}: mount επιβεβαιωμένο",
              f"{MOUNT}: ΔΕΝ είναι mount — καμία επαλήθευση"):
        return report(None)

    paths = tree_paths()
    basenames = {p.rsplit("/", 1)[-1] for p in paths}
    ok(len(paths) == 35640, f"git tree: {len(paths)} φύλλα",
       f"git tree: {len(paths)} ≠ 35640")

    hashes, chain_stats = {}, {}
    for lane, chain in CHAINS.items():
        prev_text = prev_name = None
        canon_total = 0
        for name in chain:
            p = os.path.join(REPO, "experiment/phase1a", name)
            if not os.path.exists(p):
                fails.append(f"{lane}: ΑΠΩΝ {name}")
                break
            raw = open(p, "rb").read()
            hashes[name] = hashlib.sha256(raw).hexdigest()
            text = raw.decode("utf-8")
            sk, cits = skeleton(text, paths, basenames)
            canon_total = sum(1 for _s, _e, _r, b in cits if CANON.match(b))
            if prev_text is not None:
                psk, _ = skeleton(prev_text, paths, basenames)
                ok(psk == sk,
                   f"{lane}: {prev_name} → {name} — ΣΚΕΛΕΤΟΣ ΤΑΥΤΟΣΗΜΟΣ "
                   f"(κανένα byte εκτός παραπομπών)",
                   f"{lane}: {prev_name} → {name} — ΣΚΕΛΕΤΟΣ ΔΙΑΦΕΡΕΙ: "
                   f"ΑΛΛΑΞΑΝ bytes ΕΚΤΟΣ παραπομπών")
            prev_text, prev_name = text, name
        # ── ΤΕΛΙΚΗ ΑΝΑΘΕΩΡΗΣΗ: κάθε ΚΑΝΟΝΙΚΗ παραπομπή στα ΠΡΑΓΜΑΤΙΚΑ bytes
        bad = []
        _sk, cits = skeleton(prev_text, paths, basenames)
        for _s, _e, run, blob in cits:
            m = CANON.match(blob)
            if not m:
                continue
            rel = run[len(MOUNT) + 1:] if run.startswith(MOUNT + "/") else run
            if rel not in paths:
                bad.append((run, "εκτός git tree"))
                continue
            try:
                data = read_frozen(rel)
            except OSError as e:
                bad.append((run, f"errno {e.errno}"))
                continue
            t = data.decode("utf-8", errors="replace")
            nl = 0 if t == "" else (t.count("\n") if t.endswith("\n") else t.count("\n") + 1)
            a, b, sha12 = int(m.group(1)), int(m.group(2)), m.group(3)
            if a < 1 or b > nl or b < a:
                bad.append((f"{run}:L{a}-L{b}", f"εύρος vs {nl} γραμμές"))
            elif not hashlib.sha256(data).hexdigest().startswith(sha12):
                bad.append((f"{run}:L{a}-L{b}", "λάθος hash"))
        ok(not bad, f"{lane}: και οι {canon_total} κανονικές παραπομπές της "
                    f"τελικής αναθεώρησης λύνονται σε ΠΡΑΓΜΑΤΙΚΑ bytes/εύρη",
           f"{lane}: {len(bad)} κανονικές ΔΕΝ λύνονται: {bad[:4]}")
        chain_stats[lane] = {"revisions": chain, "canonical_final": canon_total,
                             "unresolved_canonical": len(bad)}

    # ── ΕΞΟΥΣΙΟΔΟΤΗΜΕΝΟΣ ΔΙΑΧΩΡΙΣΜΟΣ L7 ─────────────────────────────────
    tok, rel, a, b = L7_SPLIT
    r2 = open(os.path.join(REPO, "experiment/phase1a/contracts-rev2.sexp"),
              encoding="utf-8").read()
    r1 = open(os.path.join(REPO, "experiment/phase1a/contracts.sexp"),
              encoding="utf-8").read()
    data = read_frozen(rel)
    lines = data.decode("utf-8").split("\n")
    sha12 = hashlib.sha256(data).hexdigest()[:12]
    ok(tok in r1 and tok not in r2,
       f"L7 split: το «{tok}» υπήρχε στο σφραγισμένο και ΔΕΝ υπάρχει στη rev2",
       f"L7 split: το «{tok}» ΔΕΝ βρέθηκε όπως αναμενόταν")
    ok("docker/verify-deps.sh" in lines[a - 1] and "docker/verify-deps.sh" in lines[b - 1],
       f"L7 split: γραμμές {a} και {b} του {rel} αναφέρουν ΚΑΙ ΟΙ ΔΥΟ "
       f"docker/verify-deps.sh — ΑΝΕΞΑΡΤΗΤΑ επαληθευμένο",
       f"L7 split: οι γραμμές {a}/{b} ΔΕΝ στηρίζουν τον διαχωρισμό")
    for ln in (a, b):
        ok(f"{rel}:L{ln}-L{ln}@sha256:{sha12}" in r2,
           f"L7 split: υπάρχει κανονική παραπομπή L{ln}-L{ln}",
           f"L7 split: ΛΕΙΠΕΙ η κανονική παραπομπή L{ln}-L{ln}")
    ok(f"{rel}:L{a}-L{b}@" not in r2,
       f"L7 split: ΔΕΝ δημιουργήθηκε ψευδές εύρος L{a}-L{b}",
       f"L7 split: ΒΡΕΘΗΚΕ ψευδές εύρος L{a}-L{b} — 20 γραμμές που κανείς "
       f"δεν επικαλέστηκε")

    return report({"chains": chain_stats, "dossier_sha256": hashes})


def report(data):
    for n in notes:
        print(f"  ✓ {n}")
    for f in fails:
        print(f"  ✗ {f}")
    receipt = {
        "kind": "independent-migration-verification/2",
        "utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "verifier_sha256": hashlib.sha256(open(__file__, "rb").read()).hexdigest(),
        "imports_resolver_or_canonicalizer": False,
        "independent_of": ["citation-resolver.py", "canonicalize-citations.py",
                           "citation_grammar.py", "frozen_access.py"],
        "central_invariant": "ΣΚΕΛΕΤΟΣ(rev_n) == ΣΚΕΛΕΤΟΣ(rev_n+1) byte-for-byte",
        "checks_passed": len(notes), "checks_failed": len(fails),
        "result": "PASS" if not fails else "FAIL",
        "scope": "μετασχηματισμός και αγκύρωση· ΟΧΙ αλήθεια ισχυρισμών",
        "data": data,
    }
    out = os.path.join(REPO, "experiment/artifacts/"
                             "INDEPENDENT-VERIFICATION-RECEIPT.json")
    tmp = out + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(receipt, fh, ensure_ascii=False, indent=1)
        fh.flush()
        os.fsync(fh.fileno())
    os.rename(tmp, out)
    print()
    if fails:
        print(f"::error::INDEPENDENT-VERIFICATION-FAIL — {len(fails)} έλεγχοι")
        return 1
    print(f"INDEPENDENT-VERIFICATION-PASS — {len(notes)} έλεγχοι")
    print("ΕΜΒΕΛΕΙΑ: μετασχηματισμός και αγκύρωση. ΟΧΙ αλήθεια ισχυρισμών.")
    return 0


sys.exit(main())
