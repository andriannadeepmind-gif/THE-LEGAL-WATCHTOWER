#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""AUTHORITY CANDIDATE CAPTURE — descriptor-based, openat2/RESOLVE_BENEATH.

ΕΤΥΜΗΓΟΡΙΑ ΔΗΜΙΟΥΡΓΟΥ ΠΟΥ ΓΕΝΝΗΣΕ ΑΥΤΟ ΤΟ ΑΡΧΕΙΟ (P0/P0/P1):
  · «λάθος αλγόριθμος ρίζας»: το προηγούμενο release_root υπολόγιζε
    SHA256(0x00 ‖ SHA256(bytes)) — ΔΕΝ είναι η παραγωγική έδρα. Η παραγωγική
    έδρα (source/merkle-authority.lisp · hash-leaf-file) είναι
    SHA256(0x00 ‖ ΩΜΑ BYTES ΑΡΧΕΙΟΥ).
  · «τίποτα δεν επανυπολογίζεται από το quarantine»: τα hash υπολογίζονταν από
    τα bytes της ΕΧΘΡΙΚΗΣ πηγής, με μία os.write χωρίς έλεγχο επιστροφής.
  · διαρροή descriptors· deadline μία φορά ανά κατάλογο.

Η ΔΟΜΙΚΗ ΑΠΑΝΤΗΣΗ — ΟΧΙ φρουρός γύρω από το λάθος σχήμα, αλλά εξάλειψη της
κλάσης σφάλματος: **ΔΥΟ ΑΥΣΤΗΡΑ ΔΙΑΚΡΙΤΕΣ ΦΑΣΕΙΣ**.

  ΦΑΣΗ Α — ΑΝΤΙΓΡΑΦΗ (copy).  Διαβάζει από την εχθρική πηγή και γράφει στο
      quarantine με write-all. **ΚΑΝΕΝΑ hash δεν υπολογίζεται εδώ.** Τίποτα από
      όσα διαβάστηκαν από το candidates/ δεν συμμετέχει σε καμία δέσμευση.
      Άρα η κλάση «hash από εχθρικά bytes» δεν υπάρχει ως δυνατότητα.
  ΦΑΣΗ Β — ΜΕΤΡΗΣΗ (measure).  Ανοίγει ΕΚ ΝΕΟΥ το quarantine και ΞΑΝΑΔΙΑΒΑΖΕΙ
      ΚΑΘΕ byte από το ΑΝΤΙΓΡΑΦΟ. Ο census, το snapshot_root και το
      release_root παράγονται ΑΠΟΚΛΕΙΣΤΙΚΑ εδώ.
  ΔΙΑΣΤΑΥΡΩΣΗ ΦΑΣΕΩΝ.  Τα σύνολα (path, size) των δύο φάσεων ΟΦΕΙΛΟΥΝ να
      ταυτίζονται· αλλιώς `quarantine-diverged` (πιάνει μερική εγγραφή, ENOSPC,
      αλλοίωση του ίδιου του authority store).

Η MERKLE ΕΔΡΑ ΔΕΝ ΜΠΟΡΕΙ ΝΑ ΑΠΟΚΛΙΝΕΙ ΣΙΩΠΗΛΑ: πριν αγγιχτεί ΕΝΑ byte, η
`verify_merkle_seat()` ελέγχει τα πρωτόγονα αυτής της υλοποίησης απέναντι στα
committed golden vectors (deployment/verify/vectors/merkle/vectors.json) —
κενή ρίζα, κάθε leaf vector, κάθε δέντρο n=0..17 (unbalanced split). Απόκλιση ή
απουσία vectors ⇒ ΑΡΝΗΣΗ, ποτέ σιωπηλή συνέχεια.

ΕΓΓΥΗΣΕΙΣ ΠΡΟΣΒΑΣΗΣ:
  · openat2(2) με RESOLVE_BENEATH|RESOLVE_NO_SYMLINKS|RESOLVE_NO_XDEV ΚΑΙ
    O_NONBLOCK (FIFO ⇒ ΚΑΝΕΝΑ blocking open· DoS αδύνατο) σε ΚΑΘΕ άνοιγμα —
    η επιβολή γίνεται ΑΠΟ ΤΟΝ ΠΥΡΗΝΑ, ΜΕΣΑ στο syscall.
  · Απαρίθμηση ΜΟΝΟ με descriptors (scandir(fd)), ΠΟΤΕ με pathname walk.
  · fstat ΤΟΥ ΑΝΟΙΓΜΕΝΟΥ descriptor ΠΡΙΝ και ΜΕΤΑ την ανάγνωση.
  · Το quarantine ΑΠΑΓΟΡΕΥΕΤΑΙ να προϋπάρχει· εγγραφή με O_EXCL|O_NOFOLLOW.
  · ΟΛΟΙ οι descriptors κλείνονται σε `finally` (κλειστό σύνολο `_Fds`).
  · Ο deadline ελέγχεται ανά καταχώρηση ΚΑΙ ανά ανάγνωση/εγγραφή chunk.
  · Ροϊκή αντιγραφή/μέτρηση: η μνήμη είναι O(chunk), όχι O(μέγεθος αρχείου).

ΟΡΙΟΘΕΤΗΣΗ ΙΣΧΥΡΙΣΜΟΥ (τίμια άγνοια): η capture ΔΕΝ ισχυρίζεται ότι το
candidates/ είχε αυτό το περιεχόμενο σε ΜΙΑ στιγμή. Ισχυρίζεται ΜΟΝΟ ότι το
quarantine περιέχει ΑΥΤΑ ΑΚΡΙΒΩΣ τα bytes και ότι οι ρίζες τα δεσμεύουν. Η K
κρίνει το quarantine — το candidates/ δεν είναι είσοδος καμίας απόφασης.

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
LEAF_DOMAIN = b"\x00"
NODE_DOMAIN = b"\x01"
MERKLE_PROFILE = "lawmax-merkle-sha256-v1"
CHUNK = 1 << 20

# Το ΜΟΝΟ σχήμα εγγραφής snapshot — αναμφίσημο (length-prefixed), domain-separated
# σε ΔΥΟ επίπεδα, και δεσμεύει ΑΚΡΙΒΩΣ το ίδιο per-file φύλλο με το release_root.
SNAPSHOT_ENTRY_DOMAIN = b"lawmax-snapshot-entry-v1\x00"

_HERE = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(os.path.dirname(_HERE))
GOLDEN_VECTORS = os.path.join(REPO_ROOT, "deployment", "verify", "vectors",
                              "merkle", "vectors.json")
TREE_LEAF_RULE = "leaf data for index i = ASCII bytes of the decimal representation of i"

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
_OPEN_FLAGS = os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK


# ═════════════════════════════════════════════════════════════════════════════
# Η MERKLE ΕΔΡΑ — ΑΚΡΙΒΩΣ η παραγωγική (source/merkle-authority.lisp)
# ═════════════════════════════════════════════════════════════════════════════
# leaf = SHA-256(0x00 ‖ ΩΜΑ BYTES)          ← hash-leaf-bytes / hash-leaf-file
# node = SHA-256(0x01 ‖ raw(L) ‖ raw(R))    ← hash-node
# MTH  : n=0 ⇒ SHA-256("")· n=1 ⇒ το φύλλο· n>1 ⇒ unbalanced split στη μεγαλύτερη
#        δύναμη του 2 ΑΥΣΤΗΡΑ < n. ΠΟΤΕ duplicate-last (κλάση CVE-2012-2459).

def _leaf(data: bytes) -> str:
    """hash-leaf-bytes: το φύλλο των ΩΜΩΝ bytes — ΟΧΙ hash-of-hash."""
    return PREFIX + hashlib.sha256(LEAF_DOMAIN + data).hexdigest()


def _leaf_hasher():
    """Ροϊκή μορφή του ΙΔΙΟΥ φύλλου: hasher ήδη τροφοδοτημένος με το 0x00."""
    h = hashlib.sha256()
    h.update(LEAF_DOMAIN)
    return h


def _node(a: str, b: str) -> str:
    return PREFIX + hashlib.sha256(
        NODE_DOMAIN + bytes.fromhex(a[len(PREFIX):]) + bytes.fromhex(b[len(PREFIX):])).hexdigest()


def _mth(leaves):
    if not leaves:
        return PREFIX + hashlib.sha256(b"").hexdigest()
    if len(leaves) == 1:
        return leaves[0]
    k = 1
    while k * 2 < len(leaves):
        k *= 2
    return _node(_mth(leaves[:k]), _mth(leaves[k:]))


def _snapshot_leaf(path: str, size: int, file_leaf: str) -> str:
    """Φύλλο snapshot: αναμφίσημη (length-prefixed) εγγραφή που δεσμεύει
    path ‖ size ‖ ΤΟ ΙΔΙΟ per-file φύλλο που δεσμεύει και το release_root."""
    p = path.encode("utf-8")
    rec = (SNAPSHOT_ENTRY_DOMAIN
           + len(p).to_bytes(8, "big") + p
           + size.to_bytes(8, "big")
           + bytes.fromhex(file_leaf[len(PREFIX):]))
    return _leaf(rec)


def verify_merkle_seat(vectors_path=GOLDEN_VECTORS):
    """Διασταύρωση ΑΥΤΩΝ των πρωτογόνων με τα COMMITTED golden vectors.

    Εκτελείται ΠΡΙΝ από κάθε capture. Απόκλιση ή απουσία ⇒ ΑΡΝΗΣΗ. Έτσι η
    κλάση «η capture χρησιμοποιεί άλλη Merkle έδρα από την παραγωγή» παύει να
    είναι δυνατή — δεν φυλάσσεται, εξαλείφεται."""
    try:
        with open(vectors_path, encoding="utf-8") as fh:
            v = json.load(fh)
    except (OSError, ValueError) as exc:
        raise CaptureRefused("merkle-seat-unverified",
                             "golden vectors μη αναγνώσιμα (%s): %s" % (vectors_path, exc))
    if v.get("profile") != MERKLE_PROFILE:
        raise CaptureRefused("merkle-seat-unverified",
                             "profile=%r ≠ %r" % (v.get("profile"), MERKLE_PROFILE))
    if v.get("tree_leaf_rule") != TREE_LEAF_RULE:
        raise CaptureRefused("merkle-seat-unverified",
                             "ο κανόνας φύλλου των vectors άλλαξε — ΚΑΜΙΑ σιωπηλή αποδοχή")
    checked = 0
    if _mth([]) != v["empty_tree_root"]:
        raise CaptureRefused("merkle-seat-divergence", "MTH([]) ≠ committed")
    checked += 1
    for lv in v["leaves"]:
        if _leaf(bytes.fromhex(lv["input_hex"])) != lv["leaf"]:
            raise CaptureRefused("merkle-seat-divergence", "leaf %s" % lv["id"])
        checked += 1
    for t in v["trees"]:
        leaves = [_leaf(str(i).encode("ascii")) for i in range(t["n"])]
        if _mth(leaves) != t["root"]:
            raise CaptureRefused("merkle-seat-divergence", "tree n=%d" % t["n"])
        checked += 1
    return checked


# ═════════════════════════════════════════════════════════════════════════════
# ΔΙΑΣΧΙΣΗ ΜΟΝΟ ΜΕ DESCRIPTORS — ΜΙΑ ΕΔΡΑ, ΔΥΟ ΚΑΤΑΝΑΛΩΤΕΣ (copy, measure)
# ═════════════════════════════════════════════════════════════════════════════

class _Fds:
    """Κλειστό σύνολο descriptors: ΟΤΙ ανοίγει, κλείνει — ΠΑΝΤΑ, σε finally."""

    def __init__(self):
        self._fds = []

    def add(self, fd):
        self._fds.append(fd)
        return fd

    def close_all(self):
        for fd in reversed(self._fds):
            try:
                os.close(fd)
            except OSError:
                pass
        self._fds = []


def _tick(deadline):
    if time.monotonic() > deadline:
        raise CaptureRefused("limit-exceeded", "deadline (wall-clock)")


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


def _walk(root_fd, lim, deadline, fds):
    """DFS ΜΟΝΟ με descriptors. Δίνει (kind, rel, fd, st) — kind ∈ {dir,file}.

    Ο κατάλογος δίνεται ΠΡΙΝ από τα παιδιά του (ο καταναλωτής μπορεί να χτίσει
    το κάτοπτρο πριν χρειαστεί). Ο deadline ελέγχεται ΑΝΑ ΚΑΤΑΧΩΡΗΣΗ."""
    stack = [("", root_fd, 0)]
    while stack:
        rel, dfd, depth = stack.pop()
        _tick(deadline)
        if depth > lim["max_depth"]:
            raise CaptureRefused("limit-exceeded", "βάθος > %d" % lim["max_depth"])
        with os.scandir(dfd) as it:
            entries = sorted(it, key=lambda e: e.name)
        for e in entries:
            _tick(deadline)
            _check_name(e.name, lim)
            child = os.path.join(rel, e.name) if rel else e.name
            fd = fds.add(openat2(dfd, e.name, _OPEN_FLAGS, RESOLVE_STRICT))
            st = os.fstat(fd)
            if stat.S_ISDIR(st.st_mode):
                stack.append((child, fd, depth + 1))
                yield ("dir", child, fd, st)
            else:
                yield ("file", child, fd, st)


def _write_all(fd, buf):
    """ΚΑΘΕ byte γράφεται. Η os.write ΕΠΙΤΡΕΠΕΤΑΙ να γράψει λιγότερα — η
    προηγούμενη υλοποίηση αγνοούσε την επιστροφή (εύρημα δημιουργού P0)."""
    mv = memoryview(buf)
    off, n = 0, len(buf)
    while off < n:
        w = os.write(fd, mv[off:])
        if w <= 0:
            raise CaptureRefused("short-write", "os.write ⇒ %d" % w)
        off += w
    return off


# ═════════════════════════════════════════════════════════════════════════════
# ΦΑΣΗ Α — ΑΝΤΙΓΡΑΦΗ (ΚΑΝΕΝΑ hash· τίποτα από την εχθρική πηγή δεν δεσμεύεται)
# ═════════════════════════════════════════════════════════════════════════════

def _phase_copy(root_fd, qfd, lim, deadline, fds):
    copied, total = [], 0
    qdirs = {"": qfd}
    for kind, rel, fd, st in _walk(root_fd, lim, deadline, fds):
        name = os.path.basename(rel)
        qparent = qdirs[os.path.dirname(rel)]
        if kind == "dir":
            try:
                os.mkdir(name, 0o700, dir_fd=qparent)
            except FileExistsError:
                raise CaptureRefused("quarantine-preexisting", rel)
            qdirs[rel] = fds.add(openat2(qparent, name, _OPEN_FLAGS,
                                         RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS))
            continue
        if not stat.S_ISREG(st.st_mode):
            raise CaptureRefused("non-regular-file", rel)
        if st.st_nlink > 1:
            raise CaptureRefused("hardlink-present", "%s (nlink=%d)" % (rel, st.st_nlink))
        if st.st_size > lim["max_file_bytes"]:
            raise CaptureRefused("limit-exceeded", "%s > max_file_bytes" % rel)
        if len(copied) + 1 > lim["max_files"]:
            raise CaptureRefused("limit-exceeded", "max_files")
        before = _fingerprint(st)
        wfd = os.open(name, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                      0o600, dir_fd=qparent)
        written = 0
        try:
            while True:
                _tick(deadline)                    # deadline ΑΝΑ ΑΝΑΓΝΩΣΗ
                chunk = os.read(fd, CHUNK)
                if not chunk:
                    break
                written += _write_all(wfd, chunk)
                if written > lim["max_file_bytes"]:
                    raise CaptureRefused("limit-exceeded", "%s ξεπέρασε το όριο" % rel)
                if total + written > lim["max_total_bytes"]:
                    raise CaptureRefused("limit-exceeded", "max_total_bytes")
            os.fsync(wfd)                          # το quarantine είναι το ΑΡΧΕΙΟ
        finally:
            os.close(wfd)
        # fstat ΜΕΤΑ: αν ο producer άγγιξε τον ΙΔΙΟ inode ενόσω διαβάζαμε, το
        # fingerprint αλλάζει. Άρνηση — ΠΟΤΕ σιωπηλή αποδοχή σχισμένης ανάγνωσης.
        if _fingerprint(os.fstat(fd)) != before:
            raise CaptureRefused("mutated-during-capture", rel)
        os.chmod(name, 0o400, dir_fd=qparent)
        total += written
        copied.append((rel, written))
    if not copied:
        raise CaptureRefused("empty-candidate", "κανένα regular file")
    for rel in sorted(qdirs):                      # durability του ίδιου του δέντρου
        if rel:
            os.fsync(qdirs[rel])
    os.fsync(qfd)
    return copied, total


# ═════════════════════════════════════════════════════════════════════════════
# ΦΑΣΗ Β — ΜΕΤΡΗΣΗ ΑΠΟΚΛΕΙΣΤΙΚΑ ΑΠΟ ΤΟ QUARANTINE
# ═════════════════════════════════════════════════════════════════════════════

def measure(quarantine_dir, canonical_files=(), limits=None):
    """Ο ΜΟΝΟΣ παραγωγός αριθμών: διαβάζει ΚΑΘΕ byte από το ΣΦΡΑΓΙΣΜΕΝΟ
    quarantine και υπολογίζει census + snapshot_root + release_root.

    Είναι ΔΗΜΟΣΙΑ έδρα: την καλεί η capture ΚΑΙ κάθε μεταγενέστερος verifier
    (fixed-point). Ίδια είσοδος ⇒ ίδια έξοδος, πάντα."""
    lim = dict(DEFAULT_LIMITS)
    if limits:
        lim.update(limits)
    deadline = time.monotonic() + lim["deadline_seconds"]
    verify_merkle_seat()
    fds = _Fds()
    census, total = [], 0
    try:
        qroot = fds.add(os.open(quarantine_dir,
                                os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW))
        for kind, rel, fd, st in _walk(qroot, lim, deadline, fds):
            if kind == "dir":
                continue
            if not stat.S_ISREG(st.st_mode) or st.st_nlink != 1:
                raise CaptureRefused("quarantine-corrupt",
                                     "%s (mode=%o nlink=%d)" % (rel, st.st_mode, st.st_nlink))
            leafh, conth, size = _leaf_hasher(), hashlib.sha256(), 0
            while True:
                _tick(deadline)                    # deadline ΑΝΑ ΑΝΑΓΝΩΣΗ
                chunk = os.read(fd, CHUNK)
                if not chunk:
                    break
                leafh.update(chunk)
                conth.update(chunk)
                size += len(chunk)
            total += size
            census.append({"path": rel, "size": size,
                           "sha256": conth.hexdigest(),
                           "leaf": PREFIX + leafh.hexdigest()})
    finally:
        fds.close_all()
    if not census:
        raise CaptureRefused("quarantine-corrupt", "κανένα αρχείο στο quarantine")
    census.sort(key=lambda e: e["path"].encode("utf-8"))

    snapshot_root = _mth([_snapshot_leaf(e["path"], e["size"], e["leaf"]) for e in census])

    release_root = None
    if canonical_files:
        by_path = {e["path"]: e for e in census}
        missing = [f for f in canonical_files if f not in by_path]
        if missing:
            raise CaptureRefused("canonical-missing", ", ".join(missing[:5]))
        # ΑΚΡΙΒΩΣ orchestrator.merkle:merkle-root-of-files — MTH πάνω σε
        # hash-leaf-file φύλλα, ΣΤΗ ΣΕΙΡΑ των canonical_files (η σειρά ΕΙΝΑΙ
        # μέρος της δέσμευσης).
        release_root = _mth([by_path[f]["leaf"] for f in canonical_files])

    return {"snapshot_root": snapshot_root, "release_root": release_root,
            "census": census, "quarantine": quarantine_dir,
            "file_count": len(census), "total_bytes": total,
            "merkle_profile": MERKLE_PROFILE, "measured_from": "quarantine",
            "limits_used": lim}


# ═════════════════════════════════════════════════════════════════════════════
# CAPTURE = ΦΑΣΗ Α → ΣΦΡΑΓΙΣΗ → ΦΑΣΗ Β → ΔΙΑΣΤΑΥΡΩΣΗ
# ═════════════════════════════════════════════════════════════════════════════

def capture(candidate_root, quarantine_dir, canonical_files=(), limits=None):
    """Συλλαμβάνει το candidate σε ΝΕΟ authority-owned quarantine και μετρά
    ΜΟΝΟ το αντίγραφο. Κάθε ανωμαλία ⇒ CaptureRefused (fail-closed)."""
    lim = dict(DEFAULT_LIMITS)
    if limits:
        lim.update(limits)
    deadline = time.monotonic() + lim["deadline_seconds"]
    seat_checks = verify_merkle_seat()             # ΠΡΙΝ από κάθε byte

    try:
        os.mkdir(quarantine_dir, 0o700)
    except FileExistsError:
        raise CaptureRefused("quarantine-preexisting",
                             "%s υπάρχει ήδη — η authority δημιουργεί ΝΕΟ" % quarantine_dir)
    os.chmod(quarantine_dir, 0o700)

    fds = _Fds()
    try:
        qfd = fds.add(os.open(quarantine_dir,
                              os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW))
        root_fd = fds.add(os.open(candidate_root,
                                  os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW))
        copied, copied_bytes = _phase_copy(root_fd, qfd, lim, deadline, fds)
    finally:
        fds.close_all()                            # ΟΛΟΙ, όχι μόνο δύο

    result = measure(quarantine_dir, canonical_files=canonical_files, limits=lim)

    # ── ΔΙΑΣΤΑΥΡΩΣΗ ΦΑΣΕΩΝ: ό,τι γράφτηκε == ό,τι μετρήθηκε ──────────────────
    written = sorted(copied, key=lambda t: t[0].encode("utf-8"))
    measured = [(e["path"], e["size"]) for e in result["census"]]
    if written != measured:
        only_w = [p for p, _ in written if p not in dict(measured)]
        only_m = [p for p, _ in measured if p not in dict(written)]
        raise CaptureRefused(
            "quarantine-diverged",
            "γράφτηκαν %d / μετρήθηκαν %d· μόνο-γραμμένα=%s μόνο-μετρημένα=%s"
            % (len(written), len(measured), only_w[:3], only_m[:3]))
    if result["total_bytes"] != copied_bytes:
        raise CaptureRefused("quarantine-diverged",
                             "bytes γραμμένα=%d μετρημένα=%d"
                             % (copied_bytes, result["total_bytes"]))
    result["seat_vectors_checked"] = seat_checks
    return result


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
                          ("snapshot_root", "release_root", "file_count", "total_bytes",
                           "merkle_profile", "seat_vectors_checked")},
                         ensure_ascii=False, sort_keys=True))
    except CaptureRefused as e:
        print("::error::CAPTURE REFUSED — %s" % e)
        sys.exit(1)
