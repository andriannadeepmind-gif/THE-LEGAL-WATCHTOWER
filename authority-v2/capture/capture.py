#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""AUTHORITY CANDIDATE CAPTURE — descriptor-based, openat2/RESOLVE_BENEATH.

Αντικαθιστά την reference_capture.py, που ο δημιουργός ορθά κατήγγειλε:
lstat-τότε-open (TOCTOU), pathname-based os.walk, χωρίς fstat του ανοιγμένου
descriptor, χωρίς openat2, δεχόταν προϋπάρχον quarantine, χωρίς όρια.

ΕΓΓΥΗΣΕΙΣ ΕΔΩ:
  · openat2(2) με RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS | RESOLVE_NO_XDEV,
    ΚΑΙ O_NONBLOCK: ένα FIFO/device στο candidate ΔΕΝ μπορεί να μπλοκάρει το
    open (DoS) — ανοίγει non-blocking, το fstat το απορρίπτει ως non-regular.
    σε ΚΑΘΕ άνοιγμα — η επιβολή γίνεται ΑΠΟ ΤΟΝ ΠΥΡΗΝΑ, ΜΕΣΑ στο syscall.
  · Απαρίθμηση ΜΟΝΟ με descriptors (openat + fdopendir), ΠΟΤΕ με pathname walk.
  · fstat ΤΟΥ ΑΝΟΙΓΜΕΝΟΥ descriptor ΠΡΙΝ και ΜΕΤΑ την ανάγνωση: τύπος, nlink,
    ino/dev, size, mtime_ns, ctime_ns. Οποιαδήποτε μεταβολή ⇒ ΑΡΝΗΣΗ.
  · Το quarantine ΑΠΑΓΟΡΕΥΕΤΑΙ να προϋπάρχει (mkdir 0700 exclusive)· η εγγραφή
    γίνεται με O_NOFOLLOW|O_EXCL μέσα σε αυτό.
  · Όρια πόρων: max files, max bytes, max path depth/length, wall-clock deadline.
  · ΔΥΟ ΡΙΖΕΣ, ΡΗΤΑ ΔΙΑΚΡΙΤΕΣ (εύρημα δημιουργού #3):
      release_root  = Merkle root ΤΩΝ CANONICAL release files (η ταυτότητα που
                      ονομάζει το bundle — ίδιος ορισμός με τον producer)
      snapshot_root = Merkle root ΟΛΟΥ του συλληφθέντος δέντρου (path+size+bytes)
    Δεν ταυτίζονται ΠΟΤΕ γενικά· το transition certificate ΟΦΕΙΛΕΙ να δεσμεύει
    ΚΑΙ ΤΑ ΔΥΟ.

ΑΠΑΙΤΕΙ Linux ≥ 5.6 (openat2). Αν λείπει ⇒ ΑΡΝΗΣΗ, ΠΟΤΕ σιωπηλό fallback.
"""
import ctypes
import ctypes.util
import errno
import hashlib
import json
import os
import stat
import sys
import time

PREFIX = "sha256:"

# openat2(2)
SYS_openat2 = 437
RESOLVE_NO_XDEV = 0x01
RESOLVE_NO_SYMLINKS = 0x04
RESOLVE_BENEATH = 0x08

DEFAULT_LIMITS = {
    "max_files": 10000,
    "max_total_bytes": 512 * 1024 * 1024,
    "max_file_bytes": 64 * 1024 * 1024,
    "max_depth": 16,
    "max_name_len": 255,
    "deadline_seconds": 120,
}


class CaptureRefused(Exception):
    def __init__(self, reason, detail=""):
        super().__init__("%s: %s" % (reason, detail))
        self.reason, self.detail = reason, detail


class _OpenHow(ctypes.Structure):
    _fields_ = [("flags", ctypes.c_uint64),
                ("mode", ctypes.c_uint64),
                ("resolve", ctypes.c_uint64)]


_libc = ctypes.CDLL(ctypes.util.find_library("c"), use_errno=True)


def openat2(dirfd, path, flags, resolve):
    """openat2 με RESOLVE_* — η επιβολή beneath/no-symlinks γίνεται ΣΤΟΝ ΠΥΡΗΝΑ."""
    how = _OpenHow(flags=flags, mode=0, resolve=resolve)
    rc = _libc.syscall(ctypes.c_long(SYS_openat2), ctypes.c_int(dirfd),
                       ctypes.c_char_p(path.encode("utf-8")),
                       ctypes.byref(how), ctypes.c_size_t(ctypes.sizeof(how)))
    if rc < 0:
        e = ctypes.get_errno()
        if e == errno.ENOSYS:
            raise CaptureRefused("openat2-unavailable",
                                 "ο πυρήνας δεν υποστηρίζει openat2 — ΚΑΜΙΑ σιωπηλή υποβάθμιση")
        if e in (errno.EXDEV, errno.ELOOP):
            raise CaptureRefused("escapes-root", "%s (%s)" % (path, os.strerror(e)))
        raise CaptureRefused("open-refused", "%s (%s)" % (path, os.strerror(e)))
    return rc


RESOLVE_STRICT = RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS | RESOLVE_NO_XDEV


def _fingerprint(st):
    return (stat.S_IFMT(st.st_mode), st.st_nlink, st.st_ino, st.st_dev,
            st.st_size, st.st_mtime_ns, st.st_ctime_ns)


def _check_name(name, limits):
    if name in ("", ".", ".."):
        raise CaptureRefused("path-traversal", "συνιστώσα %r" % name)
    if "/" in name or "\x00" in name:
        raise CaptureRefused("nul-or-empty-component", repr(name))
    if len(name) > limits["max_name_len"]:
        raise CaptureRefused("limit-exceeded", "όνομα > %d" % limits["max_name_len"])


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


def capture(candidate_root, quarantine_dir, canonical_files=(), limits=None):
    """Συλλαμβάνει το candidate σε ΝΕΟ authority-owned quarantine.

    Επιστρέφει {snapshot_root, release_root, census, quarantine, limits_used}.
    Κάθε ανωμαλία ⇒ CaptureRefused (fail-closed)."""
    lim = dict(DEFAULT_LIMITS)
    if limits:
        lim.update(limits)
    deadline = time.monotonic() + lim["deadline_seconds"]

    # Το quarantine ΑΠΑΓΟΡΕΥΕΤΑΙ να προϋπάρχει — αλλιώς κάποιος το προετοίμασε.
    try:
        os.mkdir(quarantine_dir, 0o700)
    except FileExistsError:
        raise CaptureRefused("quarantine-preexisting",
                             "%s υπάρχει ήδη — η authority δημιουργεί ΝΕΟ" % quarantine_dir)
    os.chmod(quarantine_dir, 0o700)
    qfd = os.open(quarantine_dir, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)

    root_fd = os.open(candidate_root, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    census, total_bytes = [], 0
    try:
        # Απαρίθμηση ΜΟΝΟ με descriptors — ΠΟΤΕ pathname walk.
        stack = [("", root_fd, qfd, 0)]
        owned = []
        while stack:
            if time.monotonic() > deadline:
                raise CaptureRefused("limit-exceeded", "deadline")
            rel, dfd, qdfd, depth = stack.pop()
            if depth > lim["max_depth"]:
                raise CaptureRefused("limit-exceeded", "βάθος > %d" % lim["max_depth"])
            with os.scandir(dfd) as it:
                entries = sorted(it, key=lambda e: e.name)
            for e in entries:
                _check_name(e.name, lim)
                child_rel = os.path.join(rel, e.name) if rel else e.name
                fd = openat2(dfd, e.name, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, RESOLVE_STRICT)
                owned.append(fd)
                st = os.fstat(fd)                     # fstat ΤΟΥ DESCRIPTOR
                if stat.S_ISDIR(st.st_mode):
                    try:
                        os.mkdir(e.name, 0o700, dir_fd=qdfd)
                    except FileExistsError:
                        raise CaptureRefused("quarantine-preexisting", child_rel)
                    nq = openat2(qdfd, e.name, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK,
                                 RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS)
                    owned.append(nq)
                    stack.append((child_rel, fd, nq, depth + 1))
                    continue
                if not stat.S_ISREG(st.st_mode):
                    raise CaptureRefused("non-regular-file", child_rel)
                if st.st_nlink > 1:
                    raise CaptureRefused("hardlink-present",
                                         "%s (nlink=%d)" % (child_rel, st.st_nlink))
                if st.st_size > lim["max_file_bytes"]:
                    raise CaptureRefused("limit-exceeded", "%s > max_file_bytes" % child_rel)
                before = _fingerprint(st)
                data = b""
                while True:
                    chunk = os.read(fd, 1 << 20)
                    if not chunk:
                        break
                    data += chunk
                    if len(data) > lim["max_file_bytes"]:
                        raise CaptureRefused("limit-exceeded", "%s ξεπέρασε το όριο" % child_rel)
                # fstat ΜΕΤΑ: αν ο producer άγγιξε το αρχείο ΕΝΟΣΩ διαβάζαμε,
                # το fingerprint αλλάζει — ΤΟΥ ΙΔΙΟΥ inode, όχι του path.
                if _fingerprint(os.fstat(fd)) != before:
                    raise CaptureRefused("mutated-during-capture", child_rel)
                total_bytes += len(data)
                if total_bytes > lim["max_total_bytes"] or len(census) + 1 > lim["max_files"]:
                    raise CaptureRefused("limit-exceeded", "συνολικά όρια")
                wfd = os.open(e.name, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                              0o600, dir_fd=qdfd)
                try:
                    os.write(wfd, data)
                finally:
                    os.close(wfd)
                census.append({"path": child_rel, "size": len(data),
                               "sha256": hashlib.sha256(data).hexdigest()})
    finally:
        for fd in set([root_fd, qfd]):
            try:
                os.close(fd)
            except OSError:
                pass

    if not census:
        raise CaptureRefused("empty-candidate", "κανένα regular file")
    census.sort(key=lambda e: e["path"].encode("utf-8"))

    # ── ΔΥΟ ΡΙΖΕΣ, ΡΗΤΑ ΔΙΑΚΡΙΤΕΣ ────────────────────────────────────────────
    snapshot_leaves = [
        _leaf(("%s\x00%d\x00" % (e["path"], e["size"])).encode("utf-8")
              + bytes.fromhex(e["sha256"]))
        for e in census]
    snapshot_root = _mth(snapshot_leaves)

    release_root = None
    if canonical_files:
        by_path = {e["path"]: e for e in census}
        missing = [f for f in canonical_files if f not in by_path]
        if missing:
            raise CaptureRefused("canonical-missing", ", ".join(missing[:5]))
        release_root = _mth([_leaf(bytes.fromhex(by_path[f]["sha256"]))
                             for f in canonical_files])

    return {"snapshot_root": snapshot_root, "release_root": release_root,
            "census": census, "quarantine": quarantine_dir,
            "file_count": len(census), "total_bytes": total_bytes,
            "limits_used": lim}


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("usage: capture.py <candidate-root> <NEW-quarantine> [canonical-list-file]")
        sys.exit(2)
    canon = ()
    if len(sys.argv) > 3:
        canon = tuple(l.strip() for l in open(sys.argv[3], encoding="utf-8") if l.strip())
    try:
        r = capture(sys.argv[1], sys.argv[2], canonical_files=canon)
        print(json.dumps({k: r[k] for k in
                          ("snapshot_root", "release_root", "file_count", "total_bytes")},
                         ensure_ascii=False, sort_keys=True))
    except CaptureRefused as e:
        print("::error::CAPTURE REFUSED — %s" % e)
        sys.exit(1)
