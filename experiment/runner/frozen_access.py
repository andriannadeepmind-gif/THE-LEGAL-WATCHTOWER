#!/usr/bin/env python3
"""ΜΙΑ ΕΔΡΑ ΓΙΑ ΤΗΝ ΠΡΟΣΒΑΣΗ ΣΤΟ ΠΑΓΩΜΕΝΟ ΔΕΝΤΡΟ ΚΑΙ ΤΗ ΜΕΤΡΗΣΗ ΤΟΥ.

Κάθε εργαλείο (generator · resolver · verifier) διαβάζει από ΕΔΩ. Δύο
υλοποιήσεις της ίδιας μέτρησης θα ήταν δύο έδρες και θα μπορούσαν να
αποκλίνουν σιωπηλά.

ΠΡΟΣΒΑΣΗ: openat2(2) με RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS |
RESOLVE_NO_XDEV | RESOLVE_NO_MAGICLINKS. Ο πυρήνας εγγυάται ΑΤΟΜΙΚΑ ότι:
  · καμία ανάλυση δεν βγαίνει έξω από το descriptor της ρίζας,
  · ΚΑΝΕΝΑ symlink δεν ακολουθείται σε ΚΑΝΕΝΑ συστατικό,
  · καμία ανάλυση δεν διασχίζει filesystem.
Δεν υπάρχει παράθυρο μεταξύ ελέγχου και ανοίγματος: ΔΕΝ υπάρχει έλεγχος —
η ιδιότητα επιβάλλεται από τον πυρήνα κατά την ανάλυση. Το fstat και το read
αφορούν ΤΟΝ ΙΔΙΟ descriptor, άρα το ΙΔΙΟ inode.
Αν ο πυρήνας δεν υποστηρίζει openat2 (ENOSYS), υπάρχει ρητά δηλωμένη κάθοδος
με openat+O_NOFOLLOW — ασθενέστερη, και ΣΗΜΑΙΝΕΤΑΙ στα receipts.
"""
import ctypes
import hashlib
import os
import stat

SYS_openat2 = 437
RESOLVE_NO_XDEV = 0x01
RESOLVE_NO_MAGICLINKS = 0x02
RESOLVE_NO_SYMLINKS = 0x04
RESOLVE_BENEATH = 0x08
RESOLVE_STRICT = (RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS
                  | RESOLVE_NO_XDEV | RESOLVE_NO_MAGICLINKS)

MODE_KIND = {"100644": "file", "100755": "executable", "120000": "symlink"}
CITABLE_KINDS = ("file", "executable")
LINES_BINARY = -1
LINES_SYMLINK = -2

IDENTITY_DOMAIN = b"LAWMAX-CORPUS-IDENTITY/1\x00"
LEAF_DOMAIN = b"\x00"
NODE_DOMAIN = b"\x01"

_libc = ctypes.CDLL("libc.so.6", use_errno=True)


class _OpenHow(ctypes.Structure):
    _fields_ = [("flags", ctypes.c_uint64), ("mode", ctypes.c_uint64),
                ("resolve", ctypes.c_uint64)]


class AccessMode:
    OPENAT2 = "openat2/RESOLVE_BENEATH|NO_SYMLINKS|NO_XDEV|NO_MAGICLINKS"
    FALLBACK = "openat-chain/O_NOFOLLOW (ΑΣΘΕΝΕΣΤΕΡΟ — δηλώνεται)"


_mode = None


def access_mode():
    """Ποια υλοποίηση χρησιμοποιήθηκε πραγματικά — μπαίνει στα receipts."""
    return _mode or AccessMode.OPENAT2


def _openat2(dirfd, rel, flags):
    how = _OpenHow(flags, 0, RESOLVE_STRICT)
    fd = _libc.syscall(SYS_openat2, dirfd, rel.encode("utf-8"),
                       ctypes.byref(how), ctypes.sizeof(how))
    if fd < 0:
        raise OSError(ctypes.get_errno(), os.strerror(ctypes.get_errno()), rel)
    return fd


def _openat_chain(dirfd, rel, flags):
    parts = [p for p in rel.split("/") if p]
    if not parts:
        raise OSError(22, "ΚΕΝΗ ΔΙΑΔΡΟΜΗ", rel)
    cur, owned = dirfd, False
    try:
        for comp in parts[:-1]:
            if comp in (".", ".."):
                raise OSError(22, "ΑΚΥΡΟ ΣΥΣΤΑΤΙΚΟ", rel)
            nfd = os.open(comp, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                          dir_fd=cur)
            if owned:
                os.close(cur)
            cur, owned = nfd, True
        if parts[-1] in (".", ".."):
            raise OSError(22, "ΑΚΥΡΟ ΣΥΣΤΑΤΙΚΟ", rel)
        return os.open(parts[-1], flags | os.O_NOFOLLOW, dir_fd=cur)
    finally:
        if owned:
            os.close(cur)


def open_beneath(root_fd, rel, flags=os.O_RDONLY):
    """Άνοιγμα ΑΥΣΤΗΡΑ κάτω από τη ρίζα. Σηκώνει OSError."""
    global _mode
    if _mode != AccessMode.FALLBACK:
        try:
            fd = _openat2(root_fd, rel, flags)
            _mode = AccessMode.OPENAT2
            return fd
        except OSError as e:
            if e.errno != 38:                      # ENOSYS
                raise
            _mode = AccessMode.FALLBACK
    return _openat_chain(root_fd, rel, flags)


def read_beneath(root_fd, rel):
    """Επιστρέφει (bytes, os.stat_result) ΤΟΥ ΙΔΙΟΥ descriptor."""
    fd = open_beneath(root_fd, rel)
    try:
        st = os.fstat(fd)
        if not stat.S_ISREG(st.st_mode):
            raise OSError(21, "ΔΕΝ ΕΙΝΑΙ ΚΑΝΟΝΙΚΟ ΑΡΧΕΙΟ", rel)
        buf = bytearray()
        while True:
            chunk = os.read(fd, 1 << 20)
            if not chunk:
                break
            buf += chunk
        return bytes(buf), st
    finally:
        os.close(fd)


def readlink_beneath(root_fd, rel):
    """Στόχος symlink ΧΩΡΙΣ ακολούθηση κανενός συστατικού. (target, st)."""
    d, _, base = rel.rpartition("/")
    if d:
        dfd = open_beneath(root_fd, d, os.O_RDONLY | os.O_DIRECTORY)
        owned = True
    else:
        dfd, owned = root_fd, False
    try:
        st = os.lstat(base, dir_fd=dfd)
        if not stat.S_ISLNK(st.st_mode):
            raise OSError(22, "ΔΕΝ ΕΙΝΑΙ SYMLINK", rel)
        return os.readlink(base, dir_fd=dfd), st
    finally:
        if owned:
            os.close(dfd)


def lstat_beneath(root_fd, rel):
    d, _, base = rel.rpartition("/")
    if d:
        dfd = open_beneath(root_fd, d, os.O_RDONLY | os.O_DIRECTORY)
        owned = True
    else:
        dfd, owned = root_fd, False
    try:
        return os.lstat(base, dir_fd=dfd)
    finally:
        if owned:
            os.close(dfd)


# ── ΜΕΤΡΗΣΗ ΠΕΡΙΕΧΟΜΕΝΟΥ — ΜΙΑ ΚΑΙ ΜΟΝΗ ΥΛΟΠΟΙΗΣΗ ─────────────────────────
def measure(data, kind):
    """(class, logical_lines, trailing_newline).

    ΚΕΝΟ text αρχείο: 0 γραμμές ΚΑΙ trailing_newline 0 — δεν υπάρχει newline
    που να τερματίζει, άρα η σημαία είναι 0. (Διόρθωση: η προηγούμενη
    κατασκευή δήλωνε 1, που ήταν αναληθές.)
    """
    if kind == "symlink":
        return "symlink", LINES_SYMLINK, 0
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        return "binary", LINES_BINARY, 0
    if "\0" in text:
        return "binary", LINES_BINARY, 0
    if text == "":
        return "text", 0, 0
    trailing = 1 if text.endswith("\n") else 0
    nl = text.count("\n")
    return "text", (nl if trailing else nl + 1), trailing


def git_blob_sha1(data):
    h = hashlib.sha1()
    h.update(b"blob %d\0" % len(data))
    h.update(data)
    return h.hexdigest()


def mode_from_stat(st, kind):
    """Το ΠΡΑΓΜΑΤΙΚΟ git mode που συνεπάγεται ο δίσκος."""
    if kind == "symlink":
        return "120000"
    return "100755" if (st.st_mode & 0o111) else "100644"


# ── ΤΑΥΤΟΤΗΤΑ — DOMAIN-SEPARATED, ΠΕΡΙΛΑΜΒΑΝΕΙ schema/commit/tree ─────────
def _lp(b):
    return len(b).to_bytes(4, "big") + b


def leaf_hash(path, mode, kind, content_sha256_hex, nbytes):
    pre = (_lp(path.encode("utf-8")) + _lp(mode.encode()) + _lp(kind.encode())
           + bytes.fromhex(content_sha256_hex) + nbytes.to_bytes(8, "big"))
    return hashlib.sha256(LEAF_DOMAIN + pre).hexdigest()


def merkle_root(leaves):
    """RFC 6962/9162 §2.1.1 · ΑΥΣΤΗΡΗ δύναμη του 2 · ΠΟΤΕ duplicate-last."""
    if not leaves:
        return hashlib.sha256(b"").hexdigest()
    if len(leaves) == 1:
        return leaves[0]
    k = 1
    while k * 2 < len(leaves):
        k *= 2
    return hashlib.sha256(NODE_DOMAIN + bytes.fromhex(merkle_root(leaves[:k]))
                          + bytes.fromhex(merkle_root(leaves[k:]))).hexdigest()


def corpus_identity(schema, commit_sha1, tree_sha1, leaf_root_hex):
    """ΤΑΥΤΟΤΗΤΑ ΠΟΥ ΔΕΣΜΕΥΕΙ ΚΑΙ ΤΑ ΤΕΣΣΕΡΑ ΜΕΣΑ ΣΤΟ PREIMAGE.

    SHA256( domain ‖ u32be(schema) ‖ commit(20) ‖ tree(20) ‖ leaf-root(32) )

    Η προηγούμενη κατασκευή έδινε ΜΟΝΟ τη leaf root και δήλωνε ότι «δεσμεύει»
    commit και tree — δεν τα δέσμευε: ήταν διπλανά πεδία, όχι μέρος του
    preimage. Τώρα η αλλαγή οποιουδήποτε από τα τέσσερα αλλάζει την ταυτότητα.
    """
    pre = (IDENTITY_DOMAIN + schema.to_bytes(4, "big")
           + bytes.fromhex(commit_sha1) + bytes.fromhex(tree_sha1)
           + bytes.fromhex(leaf_root_hex))
    return hashlib.sha256(pre).hexdigest()
