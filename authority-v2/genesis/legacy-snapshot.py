#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""LEVEL-7 VCCT-RSM — ΝΤΕΤΕΡΜΙΝΙΣΤΙΚΟΣ LEGACY SNAPSHOT (sequence 0 evidence)

ΑΠΑΙΤΗΣΗ (διορθωτική εντολή §1): η νέα authority epoch ξεκινά με
`sequence 0 = LEGACY-ADOPTION-CERTIFICATE` που δεσμεύει ΟΛΟΚΛΗΡΗ την παλιά
ιστορία ως **evidence-only**: κανένα legacy release δεν γίνεται accepted state,
καμία authority/attestation/conformance δεν κληρονομείται.

Αυτό το εργαλείο ΔΕΝ αγγίζει τίποτα: μόνο ΔΙΑΒΑΖΕΙ και παράγει ντετερμινιστικό
snapshot. Τα legacy δεδομένα δεν διαγράφονται, δεν μετακινούνται, δεν
ξαναγράφονται — παραμένουν read-only στο legacy namespace.

ΝΤΕΤΕΡΜΙΝΙΣΜΟΣ: sorted manifest (LC_ALL=C byte order στο repo-relative path),
per-file {path,type,size,sha256} και για symlinks το ΑΚΡΙΒΕΣ target (χωρίς
resolve — ο δεσμός είναι το δεδομένο). Καμία ώρα, κανένα mtime, καμία τυχαιότητα.

Το legacy archive root = MTH του καταλόγου με το κανονικό profile
lawmax-merkle-sha256-v1 (leaf = SHA-256(0x00 || canonical-entry-bytes)).

[Δ1] ΔΙΟΡΘΩΘΗΚΕ: η προηγούμενη έκδοση μετρούσε ΜΟΝΟ sha256-* (18). Τα canonical
είναι 24 = 18 content-addressed + 6 timestamp-named· τα 7 output_run1 artifacts
καταγράφονται ΧΩΡΙΣΤΑ ως historical-run. Το παλιό σχόλιο έλεγε: η εντολή ανέμενε 24· ο snapshot
καταγράφει τον ΠΡΑΓΜΑΤΙΚΟ αριθμό που ανακαλύπτει και δηλώνει τη διαφορά στο
known_divergences. Ο αριθμός ΔΕΝ κατασκευάζεται για να ταιριάξει.

Χρήση:  legacy-snapshot.py <repo-root> [--out <path.json>]
Έξοδος: 0 = ok · 2 = σφάλμα εισόδου
"""
import hashlib
import json
import re
import os
import sys

PREFIX = "sha256:"
LEAF_DOMAIN = b"\x00"
NODE_DOMAIN = b"\x01"

# Οι διαδρομές που συνιστούν την ΠΑΛΙΑ ΙΣΤΟΡΙΑ (evidence-only namespace).
LEGACY_ROOTS = ["output", "releases", "output_run1"]


def _h(domain: bytes, data: bytes) -> str:
    return PREFIX + hashlib.sha256(domain + data).hexdigest()


def leaf_hash(data: bytes) -> str:
    return _h(LEAF_DOMAIN, data)


def node(a: str, b: str) -> str:
    return _h(NODE_DOMAIN,
              bytes.fromhex(a[len(PREFIX):]) + bytes.fromhex(b[len(PREFIX):]))


def largest_power_of_two_below(n: int) -> int:
    k = 1
    while k * 2 < n:
        k *= 2
    return k


def mth(leaves):
    """RFC 9162 §2.1.1 (profile lawmax-merkle-sha256-v1) — NEVER duplicate-last."""
    if not leaves:
        return PREFIX + hashlib.sha256(b"").hexdigest()
    if len(leaves) == 1:
        return leaves[0]
    k = largest_power_of_two_below(len(leaves))
    return node(mth(leaves[:k]), mth(leaves[k:]))


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return PREFIX + h.hexdigest()


def entry_bytes(e):
    """ΚΑΝΟΝΙΚΑ bytes μιας εγγραφής manifest — η είσοδος του Merkle φύλλου.
    Ρητή, χωρίς JSON αμφισημίες: NUL-separated πεδία σε σταθερή σειρά."""
    parts = [e["path"], e["type"], str(e["size"]), e.get("sha256") or "",
             e.get("symlink_target") or ""]
    return "\x00".join(parts).encode("utf-8")


def scan(repo_root):
    entries = []
    for root_name in LEGACY_ROOTS:
        base = os.path.join(repo_root, root_name)
        if not os.path.exists(base):
            continue
        for dirpath, dirnames, filenames in os.walk(base, followlinks=False):
            dirnames.sort()
            for name in sorted(filenames + [d for d in dirnames
                                            if os.path.islink(os.path.join(dirpath, d))]):
                full = os.path.join(dirpath, name)
                rel = os.path.relpath(full, repo_root)
                if os.path.islink(full):
                    entries.append({"path": rel, "type": "symlink",
                                    "size": 0, "sha256": None,
                                    "symlink_target": os.readlink(full)})
                elif os.path.isfile(full):
                    entries.append({"path": rel, "type": "file",
                                    "size": os.path.getsize(full),
                                    "sha256": sha256_file(full),
                                    "symlink_target": None})
    entries.sort(key=lambda e: e["path"].encode("utf-8"))
    return entries


# [Δ1 — ΠΡΑΓΜΑΤΙΚΟ ΕΥΡΗΜΑ ΤΗΣ ΑΠΟΓΡΑΦΗΣ] Τα timestamp-named legacy releases ΔΕΝ
# περιέχουν ASCII άνω-κάτω τελεία: περιέχουν U+F03A (Private Use Area) —
# «2025-01-01T00\uf03a00\uf03a00Z». Γι' αυτό αστοχούσε και το πρώτο μου regex
# ΚΑΙ το `find -name`. Το ΔΕΧΟΜΑΣΤΕ ως γεγονός των legacy bytes (evidence-only),
# το ΚΑΤΑΓΡΑΦΟΥΜΕ ρητά, και ΔΕΝ το κανονικοποιούμε: τα legacy bytes μένουν όπως
# είναι. Ο ταξινομητής δέχεται ΟΠΟΙΟΝΔΗΠΟΤΕ διαχωριστή στη θέση της τελείας και
# καταγράφει τα code points που βρέθηκαν.
TS_SEP_CODEPOINTS = {"\uf03a", ":"}
TS_NAME = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}(.)\d{2}(.)\d{2}Z$", re.S)


def _release_naming(name):
    """Η ονοματοδοσία ΤΑΞΙΝΟΜΕΙΤΑΙ ρητά — δεν αγνοείται.
       content-addressed : sha256-<64hex>  (η νέα εποχή)
       timestamp-named   : 2025-01-01T000000Z (η ΠΑΛΙΑ εποχή — ΕΞΙΣΟΥ release)
    """
    if name.startswith("sha256-"):
        return "content-addressed"
    m = TS_NAME.match(name)
    if m and set(m.groups()) <= TS_SEP_CODEPOINTS:
        return "timestamp-named"
    return None


def collect_releases(repo_root, entries):
    """[ΔΙΟΡΘΩΣΗ ΔΗΜΙΟΥΡΓΟΥ Δ1] Η προηγούμενη έκδοση μετρούσε ΜΟΝΟ sha256-*
    και βρήκε 18, ενώ τα canonical είναι 24: 18 content-addressed + 6
    timestamp-named. Η παράλειψη ΔΕΝ ήταν «τίμια απόκλιση» — ήταν ΛΑΘΟΣ
    ΚΡΙΤΗΡΙΟ: τα timestamp-named είναι εξίσου releases της παλιάς εποχής και
    ΟΦΕΙΛΟΥΝ να δεσμευτούν ως evidence.

    ΧΩΡΙΣΤΑ (και ΟΧΙ ως canonical): τα artifacts του output_run1, που είναι
    historical RUN, όχι δημοσιευμένη εποχή — καταγράφονται ρητά ώστε να μην
    εξαφανιστούν ούτε να προσμετρηθούν λαθεμένα.

    Επιστρέφει (canonical, historical_run) — κάθε στοιχείο με path+naming.
    """
    canonical, historical = {}, {}
    for e in entries:
        parts = e["path"].split(os.sep)
        for i in range(len(parts) - 1):
            if parts[i] != "releases":
                continue
            name = parts[i + 1]
            naming = _release_naming(name)
            if naming is None:          # π.χ. `latest` — δείκτης, όχι release
                continue
            rel = os.sep.join(parts[:i + 2])
            rec = {"path": rel, "naming": naming, "dir_name": name}
            if naming == "timestamp-named":
                rec["separator_codepoints"] = sorted(
                    {"U+%04X" % ord(c) for c in name if not (c.isalnum() or c == "-")})
            if parts[0] == "output_run1":
                historical[rel] = rec
            else:
                canonical[rel] = rec
    key = lambda r: r["path"]
    return (sorted(canonical.values(), key=key), sorted(historical.values(), key=key))


def collect_latest_pointers(repo_root, entries):
    out = []
    for e in entries:
        b = os.path.basename(e["path"])
        if b in ("latest", "latest.json") and os.sep + "releases" + os.sep in os.sep + e["path"]:
            out.append({"path": e["path"], "type": e["type"],
                        "sha256": e.get("sha256"),
                        "symlink_target": e.get("symlink_target")})
    return sorted(out, key=lambda x: x["path"])


def collect_evidence(entries, suffixes):
    return sorted([{"path": e["path"], "sha256": e["sha256"]}
                   for e in entries
                   if e["type"] == "file" and e["path"].endswith(suffixes)],
                  key=lambda x: x["path"])


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    repo_root = os.path.abspath(argv[1])
    out_path = None
    if "--out" in argv:
        out_path = argv[argv.index("--out") + 1]

    entries = scan(repo_root)
    releases, historical = collect_releases(repo_root, entries)
    latest = collect_latest_pointers(repo_root, entries)
    tsa = collect_evidence(entries, (".tsr",))
    jws = collect_evidence(entries, (".jws",))
    archive_root = mth([leaf_hash(entry_bytes(e)) for e in entries])

    snapshot = {
        "kind": "lawmax/legacy-snapshot/1",
        "merkle_profile": "lawmax-merkle-sha256-v1",
        "assurance_status": "under-construction",
        "adoption_mode": "evidence-only",
        "inherited_authority": False,
        "inherited_attestation": False,
        "legacy_roots": LEGACY_ROOTS,
        "file_count": len(entries),
        "legacy_archive_root": archive_root,
        "legacy_releases": releases,
        "legacy_release_count": len(releases),
        "legacy_release_count_by_naming": {
            "content-addressed": sum(1 for r in releases if r["naming"] == "content-addressed"),
            "timestamp-named": sum(1 for r in releases if r["naming"] == "timestamp-named"),
        },
        # ΧΩΡΙΣΤΑ: historical run artifacts — ΔΕΝ είναι canonical releases, αλλά
        # ΔΕΝ εξαφανίζονται από το evidence.
        "historical_run_artifacts": historical,
        "historical_run_artifact_count": len(historical),
        "legacy_latest_pointers": latest,
        "tsa_evidence": tsa,
        "jws_evidence": jws,
        "manifest": entries,
    }
    text = json.dumps(snapshot, ensure_ascii=False, sort_keys=True,
                      separators=(",", ":"), indent=None) + "\n"
    if out_path:
        with open(out_path, "w", encoding="utf-8") as fh:
            fh.write(text)
        ca = sum(1 for r in releases if r["naming"] == "content-addressed")
        tn = sum(1 for r in releases if r["naming"] == "timestamp-named")
        print("legacy-snapshot: %d αρχεία, %d canonical releases "
              "(%d content-addressed + %d timestamp-named), %d historical-run, "
              "%d latest pointers, %d tsr, %d jws"
              % (len(entries), len(releases), ca, tn, len(historical),
                 len(latest), len(tsa), len(jws)))
        print("legacy_archive_root: %s" % archive_root)
        print("→ %s" % out_path)
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
