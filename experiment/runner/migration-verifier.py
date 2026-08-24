#!/usr/bin/env python3
"""ΑΝΕΞΑΡΤΗΤΟΣ ΕΠΑΛΗΘΕΥΤΗΣ ΤΗΣ ΜΕΤΑΝΑΣΤΕΥΣΗΣ Φ1A-L1 rev1 → rev2.

ΔΕΝ ΕΙΣΑΓΕΙ ΚΑΙ ΔΕΝ ΚΑΛΕΙ ΚΩΔΙΚΑ ΤΟΥ RESOLVER. Καμία γραμμή του
citation-resolver.py δεν εκτελείται εδώ. Δικός του σαρωτής, δική του
απαρίθμηση corpus (git ls-tree), δική του ανάγνωση αρχείων από το παγωμένο
mount, δική του ταξινόμηση. Αν συμφωνήσει με τον resolver, η συμφωνία είναι
ΑΝΕΞΑΡΤΗΤΗ· αν διαφωνήσει, η διαφωνία είναι ΕΥΡΗΜΑ.

ΤΙ ΔΕΝ ΕΙΝΑΙ: δεν είναι απόδειξη ότι οι ισχυρισμοί του dossier αληθεύουν.
Επαληθεύει ΜΕΤΑΣΧΗΜΑΤΙΣΜΟ και ΑΓΚΥΡΩΣΗ, τίποτε άλλο.
"""
import hashlib
import json
import os
import re
import subprocess
import sys

REPO = "/home/user/THE-LEGAL-WATCHTOWER"
COMMIT = "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
MOUNT = "/frozen/ro"
REV1 = f"{REPO}/experiment/phase1a/source.sexp"
REV2 = f"{REPO}/experiment/phase1a/source-rev2.sexp"
MAP = f"{REPO}/experiment/artifacts/l1-admission-forensics/MIGRATION-MAP.json"
PREFIX = "source/"
LANE_ROOTS = ("source",)

REV1_SHA = "dd3ce7cc6bd973d284dd00adb417afa3e1030bcdca9da32997b435fb4c5e8aef"
EXPECT_REPLACEMENTS = 327
EXPECT_UNIQUE_B = 272
EXPECT_ALREADY_VALID = 3
EXPECT_HELD = 11

# ΔΙΚΟΣ ΤΟΥ σαρωτής — γραμμένος ΑΝΕΞΑΡΤΗΤΑ από αυτόν του resolver.
CIT = re.compile(
    r'(?<![\w./-])'
    r'([0-9A-Za-zΑ-Ωα-ω_./-]+\.'
    r'(?:lisp|asd|md|sexp|sh|py|js|mjs|ts|json|jsonld|yml|yaml|ttl|txt|cddl|zip))'
    r':L?(\d+)(?:-L?(\d+))?(?:@sha256:([0-9a-f]{12}))?')

fail = []
note = []


def check(cond, ok_msg, bad_msg):
    (note if cond else fail).append(ok_msg if cond else bad_msg)
    return cond


def mounted_ro():
    with open("/proc/self/mountinfo", encoding="utf-8") as fh:
        for line in fh:
            f = line.split()
            if len(f) > 5 and f[4] == MOUNT:
                return "ro" in set(f[5].split(","))
    return False


def corpus_paths():
    """ΔΙΚΗ ΤΟΥ απαρίθμηση — git tree, ΟΧΙ το TSV του resolver."""
    out = subprocess.run(["git", "-C", REPO, "ls-tree", "-r", "-z",
                          "--full-tree", COMMIT],
                         capture_output=True, check=True).stdout
    paths = {}
    for rec in out.split(b"\0"):
        if not rec:
            continue
        meta, _, path = rec.partition(b"\t")
        mode = meta.split(b" ")[0].decode()
        paths[path.decode("utf-8")] = mode
    return paths


def logical_lines(full):
    with open(full, "rb") as fh:
        data = fh.read()
    try:
        t = data.decode("utf-8")
    except UnicodeDecodeError:
        return None
    if t == "":
        return 0
    return t.count("\n") if t.endswith("\n") else t.count("\n") + 1


def scan(text):
    seen, out = set(), []
    for m in CIT.finditer(text):
        key = (m.group(1), int(m.group(2)), m.group(3), m.group(4))
        if key in seen:
            continue
        seen.add(key)
        out.append((m.group(0), *key, m.start(1)))
    return out


def main():
    print("ΑΝΕΞΑΡΤΗΤΟΣ ΕΠΑΛΗΘΕΥΤΗΣ ΜΕΤΑΝΑΣΤΕΥΣΗΣ — καμία εισαγωγή κώδικα resolver")
    print("═" * 74)
    if not check(mounted_ro(), f"{MOUNT}: read-only mount επιβεβαιωμένο",
                 f"{MOUNT}: ΔΕΝ είναι read-only mount — καμία επαλήθευση"):
        return report()

    rev1_bytes = open(REV1, "rb").read()
    rev2_bytes = open(REV2, "rb").read()
    rev1 = rev1_bytes.decode("utf-8")
    rev2 = rev2_bytes.decode("utf-8")
    check(hashlib.sha256(rev1_bytes).hexdigest() == REV1_SHA,
          f"rev1 sha256 ταυτίζεται με το σφραγισμένο ({REV1_SHA[:16]}…)",
          "rev1 sha256 ΔΕΝ ταυτίζεται — το πρωτότυπο μεταβλήθηκε")

    mapping = json.load(open(MAP, encoding="utf-8"))["mapping"]
    check(len(mapping) == EXPECT_REPLACEMENTS,
          f"mapping: {len(mapping)} αντικαταστάσεις = αναμενόμενες {EXPECT_REPLACEMENTS}",
          f"mapping: {len(mapping)} ≠ {EXPECT_REPLACEMENTS}")

    # ── ① ΑΝΤΙΣΤΡΟΦΗ ΑΝΑΚΑΤΑΣΚΕΥΗ, ΑΝΕΞΑΡΤΗΤΑ ─────────────────────────────
    recon, prev, offsets_ok = [], 0, True
    for e in mapping:
        o = e["new_char_offset"]
        if rev2[o:o + len(PREFIX)] != PREFIX:
            offsets_ok = False
            break
        recon.append(rev2[prev:o])
        prev = o + len(PREFIX)
    recon.append(rev2[prev:])
    check(offsets_ok, f"και οι {len(mapping)} θέσεις φέρουν ΠΡΑΓΜΑΤΙΚΑ το «{PREFIX}»",
          "ΤΟΥΛΑΧΙΣΤΟΝ ΜΙΑ θέση ΔΕΝ φέρει το πρόθεμα")
    recon_sha = hashlib.sha256("".join(recon).encode("utf-8")).hexdigest()
    check(recon_sha == REV1_SHA,
          f"αντίστροφη ανακατασκευή ⇒ {recon_sha[:16]}… = ΠΡΩΤΟΤΥΠΟ",
          f"αντίστροφη ανακατασκευή ⇒ {recon_sha[:16]}… ≠ ΠΡΩΤΟΤΥΠΟ")
    delta = len(rev2_bytes) - len(rev1_bytes)
    check(delta == len(mapping) * len(PREFIX),
          f"byte delta {delta} = {len(mapping)} × {len(PREFIX)}",
          f"byte delta {delta} ≠ {len(mapping)} × {len(PREFIX)}")

    # ── ② ΔΙΚΗ ΤΟΥ ΤΑΞΙΝΟΜΗΣΗ ΤΩΝ ΠΑΡΑΠΟΜΠΩΝ ΤΟΥ rev1 ────────────────────
    paths = corpus_paths()
    c1 = scan(rev1)
    already, bare_unique, held, other = [], {}, [], []
    for token, raw, start, end, sha12, _off in c1:
        if raw in paths:
            already.append(token)
            continue
        cands = [p for p in paths if p.rsplit("/", 1)[-1] == raw] if "/" not in raw else []
        under = [f"{r}/{raw}" for r in LANE_ROOTS if f"{r}/{raw}" in paths]
        if len(under) == 1 and len(cands) <= 1:
            full = os.path.join(MOUNT, under[0])
            nl = logical_lines(full)
            hi = int(end) if end else start
            if nl is None or start < 1 or hi > nl:
                held.append((token, f"εύρος {start}-{hi} vs {nl} γραμμές"))
            else:
                bare_unique[(raw, start, end, sha12)] = under[0]
        elif len(cands) > 1:
            held.append((token, f"{len(cands)} υποψήφιοι"))
        else:
            other.append(token)

    check(len(already) == EXPECT_ALREADY_VALID,
          f"ήδη έγκυρες παραπομπές: {len(already)} = {EXPECT_ALREADY_VALID}",
          f"ήδη έγκυρες: {len(already)} ≠ {EXPECT_ALREADY_VALID}")
    check(len(bare_unique) == EXPECT_UNIQUE_B,
          f"ΜΟΝΟΣΗΜΑΝΤΑ μεταναστεύσιμα: {len(bare_unique)} = {EXPECT_UNIQUE_B}",
          f"ΜΟΝΟΣΗΜΑΝΤΑ: {len(bare_unique)} ≠ {EXPECT_UNIQUE_B}")
    check(len(held) == EXPECT_HELD,
          f"ΚΡΑΤΟΥΜΕΝΑ (αμφίσημα ή άκυρο εύρος): {len(held)} = {EXPECT_HELD}",
          f"ΚΡΑΤΟΥΜΕΝΑ: {len(held)} ≠ {EXPECT_HELD}")
    check(not other, "καμία παραπομπή εκτός των τριών κλάσεων",
          f"{len(other)} παραπομπές ΕΚΤΟΣ κλάσεων: {other[:5]}")

    # ── ③ ΟΙ ΗΔΗ ΕΓΚΥΡΕΣ ΚΑΙ ΤΑ ΚΡΑΤΟΥΜΕΝΑ ΑΜΕΤΑΒΛΗΤΑ ΣΤΟ rev2 ──────────
    check(all(t in rev2 for t in already),
          f"και οι {len(already)} ήδη έγκυρες ΑΥΤΟΥΣΙΕΣ στο rev2",
          "ΤΟΥΛΑΧΙΣΤΟΝ ΜΙΑ ήδη έγκυρη μεταβλήθηκε")
    check(all(t in rev2 for t, _ in held),
          f"και τα {len(held)} κρατούμενα ΑΥΤΟΥΣΙΑ στο rev2",
          "ΤΟΥΛΑΧΙΣΤΟΝ ΕΝΑ κρατούμενο μεταβλήθηκε")

    # ── ④ ΚΑΘΕ ΜΕΤΑΝΑΣΤΕΥΜΕΝΗ ΛΥΝΕΤΑΙ ΣΕ ΠΡΑΓΜΑΤΙΚΟ ΑΡΧΕΙΟ ΚΑΙ ΕΥΡΟΣ ──
    bad = []
    for (raw, start, end, sha12), target in bare_unique.items():
        full = os.path.join(MOUNT, target)
        if not os.path.isfile(full):
            bad.append((raw, "ΔΕΝ ΥΠΑΡΧΕΙ"))
            continue
        nl = logical_lines(full)
        hi = int(end) if end else start
        if nl is None or start < 1 or hi > nl:
            bad.append((raw, f"εύρος {start}-{hi} vs {nl}"))
            continue
        if sha12:
            real = hashlib.sha256(open(full, "rb").read()).hexdigest()
            if not real.startswith(sha12):
                bad.append((raw, "λάθος hash"))
    check(not bad, f"και οι {len(bare_unique)} μεταναστευμένες λύνονται σε ΠΡΑΓΜΑΤΙΚΟ "
                   f"αρχείο & εύρος στο {MOUNT}",
          f"{len(bad)} ΔΕΝ λύνονται: {bad[:5]}")

    # ── ⑤ Η ΜΕΤΑΝΑΣΤΕΥΣΗ ΑΓΓΙΞΕ ΜΟΝΟ ΤΙΣ ΜΟΝΟΣΗΜΑΝΤΕΣ ───────────────────
    mapped = {(e["old_path"], e["new_path"]) for e in mapping}
    check(all(new == PREFIX + old for old, new in mapped),
          "κάθε αντικατάσταση είναι ΑΚΡΙΒΩΣ πρόθεμα, καμία άλλη μεταβολή διαδρομής",
          "ΤΟΥΛΑΧΙΣΤΟΝ ΜΙΑ αντικατάσταση ΔΕΝ είναι απλό πρόθεμα")
    mapped_raw = {e["old_path"] for e in mapping}
    check(mapped_raw == {k[0] for k in bare_unique},
          f"το σύνολο των {len(mapped_raw)} ονομάτων που μετακινήθηκαν ΤΑΥΤΙΖΕΤΑΙ "
          f"με το ΑΝΕΞΑΡΤΗΤΑ υπολογισμένο",
          "το σύνολο ονομάτων ΔΙΑΦΕΡΕΙ από το ανεξάρτητα υπολογισμένο")
    return report()


def report():
    print()
    for n in note:
        print(f"  ✓ {n}")
    for f in fail:
        print(f"  ✗ {f}")
    print()
    if fail:
        print(f"::error::INDEPENDENT-VERIFICATION-FAIL — {len(fail)} έλεγχοι απέτυχαν")
        return 1
    print(f"INDEPENDENT-MIGRATION-VERIFICATION-PASS — {len(note)} έλεγχοι")
    print("ΕΜΒΕΛΕΙΑ: μετασχηματισμός και αγκύρωση. ΟΧΙ αλήθεια ισχυρισμών.")
    return 0


sys.exit(main())
