#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CANDIDATE CAPTURE — ΥΛΟΠΟΙΗΣΗ ΑΝΑΦΟΡΑΣ ΓΙΑ ΑΝΤΙΠΑΛΙΚΟ ΕΛΕΓΧΟ

ΔΕΝ ΕΙΝΑΙ PRODUCTION WRITER. Είναι η εκτελέσιμη έκφραση του CAPTURE-PROTOCOL,
ώστε οι επιθέσεις να ΑΠΟΔΕΙΚΝΥΕΤΑΙ ότι απορρίπτονται αντί να δηλώνεται.
Η παραγωγική capture θα είναι μέρος του imperative shell της authority process.

Επιβάλλει, με openat(..., O_NOFOLLOW) σε ΚΑΘΕ συνιστώσα:
  · καμία symlink, κανένα hardlink (nlink>1), κανένα non-regular file
  · καμία «..»/απόλυτη/κενή συνιστώσα, κανένα NUL
  · κάθε άνοιγμα ΜΟΝΟ beneath του candidate root
  · αντιγραφή σε ιδιωτικό quarantine ΠΡΙΝ από κάθε κρίση
  · επανυπολογισμός census/root ΜΕΣΑ στο quarantine
  · ανίχνευση μεταβολής κατά τη σύλληψη (δύο περάσματα)
"""
import hashlib
import os
import stat
import sys

PREFIX = "sha256:"


class CaptureRefused(Exception):
    def __init__(self, reason, detail=""):
        super().__init__("%s: %s" % (reason, detail))
        self.reason, self.detail = reason, detail


def _leaf(data: bytes) -> str:
    return PREFIX + hashlib.sha256(b"\x00" + data).hexdigest()


def _node(a: str, b: str) -> str:
    return PREFIX + hashlib.sha256(
        b"\x01" + bytes.fromhex(a[len(PREFIX):]) + bytes.fromhex(b[len(PREFIX):])).hexdigest()


def _mth(leaves):
    if not leaves:
        return PREFIX + hashlib.sha256(b"").hexdigest()
    if len(leaves) == 1:
        return leaves[0]
    k = 1
    while k * 2 < len(leaves):
        k *= 2
    return _node(_mth(leaves[:k]), _mth(leaves[k:]))


def _check_component(c):
    if c in ("", ".", ".."):
        raise CaptureRefused("path-traversal", "συνιστώσα %r" % c)
    if "\x00" in c:
        raise CaptureRefused("nul-or-empty-component", repr(c))


def _open_beneath(root_fd, rel):
    """Ανοίγει `rel` ΜΟΝΟ beneath του root_fd, με O_NOFOLLOW σε ΚΑΘΕ συνιστώσα.
    Η επιβολή γίνεται στο syscall — όχι με έλεγχο string πριν (TOCTOU)."""
    if os.path.isabs(rel):
        raise CaptureRefused("path-traversal", "απόλυτο path %r" % rel)
    parts = rel.split(os.sep)
    for c in parts:
        _check_component(c)
    cur = os.dup(root_fd)
    try:
        for c in parts[:-1]:
            nxt = os.open(c, os.O_RDONLY | os.O_NOFOLLOW | os.O_DIRECTORY, dir_fd=cur)
            os.close(cur)
            cur = nxt
        fd = os.open(parts[-1], os.O_RDONLY | os.O_NOFOLLOW, dir_fd=cur)
        return fd
    except OSError as e:
        raise CaptureRefused("escapes-root", "%s (%s)" % (rel, e.strerror))
    finally:
        os.close(cur)


def _walk(root):
    """Απαρίθμηση ΧΩΡΙΣ να ακολουθεί symlink· κάθε ανωμαλία ⇒ άρνηση."""
    out = []
    for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
        for d in list(dirnames):
            full = os.path.join(dirpath, d)
            if os.path.islink(full):
                raise CaptureRefused("symlink-present", os.path.relpath(full, root))
        for f in sorted(filenames):
            full = os.path.join(dirpath, f)
            rel = os.path.relpath(full, root)
            st = os.lstat(full)
            if stat.S_ISLNK(st.st_mode):
                raise CaptureRefused("symlink-present", rel)
            if not stat.S_ISREG(st.st_mode):
                raise CaptureRefused("non-regular-file", rel)
            if st.st_nlink > 1:
                raise CaptureRefused("hardlink-present", "%s (nlink=%d)" % (rel, st.st_nlink))
            out.append(rel)
        dirnames.sort()
    return sorted(out)


def _read_all(root_fd, rel):
    fd = _open_beneath(root_fd, rel)
    try:
        chunks = []
        while True:
            b = os.read(fd, 1 << 20)
            if not b:
                break
            chunks.append(b)
        return b"".join(chunks)
    finally:
        os.close(fd)


def capture(candidate_root, quarantine_dir, declared_root=None):
    """Συλλαμβάνει το candidate σε ιδιωτικό quarantine και επανυπολογίζει.
    Επιστρέφει {census, root, quarantine} ή σηκώνει CaptureRefused."""
    if not os.path.isdir(candidate_root):
        raise CaptureRefused("escapes-root", "ανύπαρκτο candidate root")
    rels = _walk(candidate_root)
    if not rels:
        raise CaptureRefused("declared-root-mismatch", "ΚΕΝΟ candidate")

    root_fd = os.open(candidate_root, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        first = {rel: _read_all(root_fd, rel) for rel in rels}
        # Δεύτερο πέρασμα: αν κάτι άλλαξε ενόσω διαβάζαμε, ο producer επενέβη.
        for rel in rels:
            if _read_all(root_fd, rel) != first[rel]:
                raise CaptureRefused("mutated-during-capture", rel)
    finally:
        os.close(root_fd)

    # Ιδιωτικό quarantine: 0700, εκτός κάθε producer-writable μονοπατιού.
    os.makedirs(quarantine_dir, mode=0o700, exist_ok=True)
    os.chmod(quarantine_dir, 0o700)
    census = []
    for rel in rels:
        dst = os.path.join(quarantine_dir, rel)
        os.makedirs(os.path.dirname(dst), mode=0o700, exist_ok=True)
        with open(dst, "wb") as fh:
            fh.write(first[rel])
        census.append({"path": rel, "size": len(first[rel]),
                       "sha256": hashlib.sha256(first[rel]).hexdigest()})

    # ΕΠΑΝΥΠΟΛΟΓΙΣΜΟΣ ΜΕΣΑ στο quarantine — από τα αντιγραμμένα bytes.
    leaves = []
    for e in census:
        with open(os.path.join(quarantine_dir, e["path"]), "rb") as fh:
            data = fh.read()
        if hashlib.sha256(data).hexdigest() != e["sha256"]:
            raise CaptureRefused("mutated-during-capture", e["path"])
        leaves.append(_leaf(("%s\x00%d\x00" % (e["path"], e["size"])).encode("utf-8") + data))
    root = _mth(leaves)
    if declared_root is not None and declared_root != root:
        raise CaptureRefused("declared-root-mismatch",
                             "δηλωμένο %s ≠ επανυπολογισμένο %s" % (declared_root, root))
    return {"census": census, "root": root, "quarantine": quarantine_dir}


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("usage: reference_capture.py <candidate-root> <quarantine> [declared-root]")
        sys.exit(2)
    try:
        r = capture(sys.argv[1], sys.argv[2],
                    sys.argv[3] if len(sys.argv) > 3 else None)
        print("captured: %d αρχεία, root %s" % (len(r["census"]), r["root"]))
    except CaptureRefused as e:
        print("::error::CAPTURE REFUSED — %s" % e)
        sys.exit(1)
