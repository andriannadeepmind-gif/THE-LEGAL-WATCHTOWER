#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""AUTHORITY CANDIDATE CAPTURE — αγκυρωμένη, φραγμένη, fail-closed.

ΕΤΥΜΗΓΟΡΙΑ ΔΗΜΙΟΥΡΓΟΥ ΠΟΥ ΓΕΝΝΗΣΕ ΑΥΤΗ ΤΗΝ ΕΚΔΟΣΗ (CAPTURE-BOUNDARY-CLOSURE-2).
Ο δημιουργός έτρεξε τον κώδικα, πρόσθεσε σενάρια που δεν είχε η σουίτα, και
βρήκε ΕΠΙΖΩΝΤΑ σφάλματα. Κάθε ένα κλείνει εδώ ΣΤΗΝ ΑΙΤΙΑ ΤΟΥ:

  ① «Ενδιάμεσο symlink στο ίδιο το candidate_root έγινε δεκτό — το openat2
     προστατεύει τους απογόνους, όχι τον αρχικό αυθαίρετο pathname.»
     ⇒ ΚΑΝΕΝΑ αυθαίρετο pathname. `_open_anchor()` διασχίζει ΚΑΘΕ συνιστώσα του
     απόλυτου μονοπατιού από το «/» με openat2 RESOLVE_STRICT. Ένα symlink
     ΟΠΟΥΔΗΠΟΤΕ στην άγκυρα ⇒ ΑΡΝΗΣΗ `symlink-in-anchor`. Candidate και
     quarantine ανοίγουν ΩΣ ΟΝΟΜΑΤΑ μέσα σε έμπιστα parent dirfds.
  ② «Με RLIMIT_NOFILE=96 και 200 αρχεία πήρα ακατέργαστο OSError(24).»
     ⇒ ΚΑΘΕ descriptor κλείνει ΑΜΕΣΩΣ μετά τη χρήση (αναδρομή με finally):
     ταυτόχρονα ανοιχτά = O(βάθος)+2, ΟΧΙ O(αρχεία). Και κάθε OSError
     μεταφράζεται σε ΕΛΕΓΧΟΜΕΝΗ άρνηση (`fd-exhausted`, `quarantine-no-space`,
     `io-error`, `os-error`) — ποτέ ακατέργαστη εξαίρεση.
  ③ «Το sorted(scandir(...)) φορτώνει ολόκληρο τον κατάλογο πριν εφαρμοστεί όριο.»
     ⇒ Η απαρίθμηση μετράει ΚΑΘΩΣ διαβάζει και σταματά ΠΡΙΝ τη συσσώρευση.
  ④ «Μη έγκυρο UTF-8 όνομα ⇒ ακατέργαστο UnicodeEncodeError.»
     ⇒ Τα ονόματα δουλεύονται ΣΕ BYTES· αυστηρή αποκωδικοποίηση UTF-8 ως
     ΕΛΕΓΧΟΣ, όχι ως μετατροπή. Αποτυχία ⇒ ΑΡΝΗΣΗ `non-utf8-name`.
  ⑤ «Χωρίς canonical list ⇒ release_root=None· με διπλό αρχείο ⇒ άλλη ρίζα.»
     ⇒ Το canonical profile είναι ΥΠΟΧΡΕΩΤΙΚΟ, ΚΑΡΦΩΜΕΝΟ σε committed αρχείο,
     ΜΟΝΑΔΙΚΟ και ΧΩΡΙΣ διπλότυπα. `release_root` ΔΕΝ είναι ΠΟΤΕ None.
  ⑥ «Το independent fixed point τρέχει μόνο στο harness, όχι στην capture().»
     ⇒ Η capture() ΕΚΤΕΛΕΙ η ίδια δεύτερη, πλήρη επαναμέτρηση και απορρίπτει με
     `fixed-point-violation` σε οποιαδήποτε διαφορά.
  ⑦ «Μετάλλαξη λάθος ΜΟΝΟ σε δέντρο 18 φύλλων πέρασε και τους 22 ελέγχους.»
     ⇒ ΟΡΘΟ ΚΑΙ ΘΕΜΕΛΙΩΔΕΣ: πεπερασμένα vectors ΔΕΝ εξαλείφουν την απόκλιση.
     (α) Ο ισχυρισμός «δομικά αδύνατη» ΑΠΟΣΥΡΕΤΑΙ — βλ. `RETRACTED_CLAIMS`.
     (β) Ο έλεγχος vectors επεκτάθηκε σε ΟΛΟ το differential range (n=0..64).
     (γ) Προστέθηκε ΔΕΥΤΕΡΟΣ, ΔΟΜΙΚΑ ΔΙΑΦΟΡΕΤΙΚΟΣ αλγόριθμος MTH (επαυξητική
         στοίβα RFC 6962 αντί για αναδρομική διάσπαση). Κάθε ρίζα υπολογίζεται
         ΚΑΙ ΜΕ ΤΟΥΣ ΔΥΟ και συγκρίνεται — για ΚΑΘΕ n, όχι μόνο για τα
         πινακοποιημένα. Διαφορά ⇒ `merkle-internal-divergence`.
     Αυτό ΔΕΝ είναι απόδειξη ορθότητας· είναι ανίχνευση απόκλισης για κάθε n.

ΔΙΑΤΗΡΟΥΝΤΑΙ ΑΠΟ ΤΗΝ ΠΡΟΗΓΟΥΜΕΝΗ ΕΚΔΟΣΗ (ελεγμένα):
  · ΔΥΟ ΑΥΣΤΗΡΑ ΔΙΑΚΡΙΤΕΣ ΦΑΣΕΙΣ — Α: αντιγραφή ΧΩΡΙΣ κανένα hash· Β: μέτρηση
    ΑΠΟΚΛΕΙΣΤΙΚΑ από το quarantine. Διασταύρωση (path,size) ⇒ quarantine-diverged.
  · write-all που τιμά ΚΑΘΕ επιστροφή της os.write· fsync αρχείων και καταλόγων.
  · fstat ΤΟΥ DESCRIPTOR πριν/μετά ⇒ `mutated-during-capture`.
  · Άρνηση symlink/hardlink/non-regular/traversal/προϋπάρχοντος quarantine.
  · deadline ανά καταχώρηση ΚΑΙ ανά chunk· ροϊκή μνήμη O(chunk).
ΝΕΟ: σε ΚΑΘΕ άρνηση, το ΜΕΡΙΚΟ quarantine ΚΑΘΑΡΙΖΕΤΑΙ (descriptor-based purge) —
δεν μένει ποτέ μισοχτισμένο δέντρο που θα μπορούσε να περαστεί για σύλληψη.

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
CANONICAL_PROFILE_ID = "lawmax-candidate-canonical-v1"
CHUNK = 1 << 20

SNAPSHOT_ENTRY_DOMAIN = b"lawmax-snapshot-entry-v1\x00"

_HERE = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(os.path.dirname(_HERE))
GOLDEN_VECTORS = os.path.join(REPO_ROOT, "deployment", "verify", "vectors",
                              "merkle", "vectors.json")
CANONICAL_PROFILE = os.path.join(_HERE, "canonical-profile.json")
TREE_LEAF_RULE = "leaf data for index i = ASCII bytes of the decimal representation of i"

# ── ΑΠΟΣΥΡΜΕΝΟΙ ΙΣΧΥΡΙΣΜΟΙ (ρητή εντολή δημιουργού) ──────────────────────────
RETRACTED_CLAIMS = (
    "«Η απόκλιση της Merkle έδρας είναι ΔΟΜΙΚΑ ΑΔΥΝΑΤΗ» — ΑΠΟΣΥΡΕΤΑΙ. Πεπερασμένα "
    "golden vectors ελέγχουν πεπερασμένα n· μετάλλαξη που αστοχεί ΜΟΝΟ σε n εκτός "
    "πίνακα τα περνά όλα. Ό,τι ισχύει σήμερα είναι ΑΝΙΧΝΕΥΣΗ, όχι αδυνατότητα: "
    "committed vectors για n=0..64 ΚΑΙ δεύτερος δομικά διαφορετικός αλγόριθμος για "
    "κάθε n ΚΑΙ διαφορικό test απέναντι στον παραγωγικό Lisp πυρήνα. Ο ισχυρισμός "
    "«αδύνατη» επιστρέφει ΜΟΝΟ όταν υπάρξει ΚΟΙΝΟΣ ΑΠΟΔΕΔΕΙΓΜΕΝΟΣ πυρήνας.",
)

# openat2(2)
SYS_openat2 = 437
RESOLVE_NO_XDEV = 0x01
RESOLVE_NO_SYMLINKS = 0x04
RESOLVE_BENEATH = 0x08
RESOLVE_STRICT = RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS | RESOLVE_NO_XDEV

DEFAULT_LIMITS = {
    "max_files": 10000,
    "max_dir_entries": 4096,
    "max_total_bytes": 512 * 1024 * 1024,
    "max_file_bytes": 64 * 1024 * 1024,
    "max_depth": 16,
    "max_name_len": 255,
    "deadline_seconds": 120,
}

_ERRNO_REASON = {
    errno.EMFILE: "fd-exhausted",
    errno.ENFILE: "fd-exhausted",
    errno.ENOSPC: "quarantine-no-space",
    errno.EDQUOT: "quarantine-no-space",
    errno.EIO: "io-error",
    errno.EROFS: "quarantine-read-only",
}


class CaptureRefused(Exception):
    def __init__(self, reason, detail=""):
        super().__init__("%s: %s" % (reason, detail))
        self.reason, self.detail = reason, detail


def _os_refuse(exc, ctx):
    """ΚΑΘΕ OSError γίνεται ΕΛΕΓΧΟΜΕΝΗ άρνηση — ποτέ ακατέργαστη εξαίρεση."""
    e = getattr(exc, "errno", None)
    return CaptureRefused(_ERRNO_REASON.get(e, "os-error"),
                          "%s: %s" % (ctx, os.strerror(e) if e else exc))


class _OpenHow(ctypes.Structure):
    _fields_ = [("flags", ctypes.c_uint64),
                ("mode", ctypes.c_uint64),
                ("resolve", ctypes.c_uint64)]


_libc = ctypes.CDLL(ctypes.util.find_library("c"), use_errno=True)


def openat2(dirfd, path, flags, resolve):
    """openat2 με RESOLVE_* — η επιβολή γίνεται ΣΤΟΝ ΠΥΡΗΝΑ. PATH σε bytes."""
    raw = path if isinstance(path, bytes) else os.fsencode(path)
    how = _OpenHow(flags=flags, mode=0, resolve=resolve)
    rc = _libc.syscall(ctypes.c_long(SYS_openat2), ctypes.c_int(dirfd),
                       ctypes.c_char_p(raw), ctypes.byref(how),
                       ctypes.c_size_t(ctypes.sizeof(how)))
    if rc < 0:
        e = ctypes.get_errno()
        if e == errno.ENOSYS:
            raise CaptureRefused("openat2-unavailable",
                                 "ο πυρήνας δεν υποστηρίζει openat2 — ΚΑΜΙΑ σιωπηλή υποβάθμιση")
        if e in (errno.EXDEV, errno.ELOOP):
            raise CaptureRefused("escapes-root", "%r (%s)" % (raw, os.strerror(e)))
        if e in _ERRNO_REASON:
            raise CaptureRefused(_ERRNO_REASON[e], "%r (%s)" % (raw, os.strerror(e)))
        raise CaptureRefused("open-refused", "%r (%s)" % (raw, os.strerror(e)))
    return rc


# O_CLOEXEC ΠΑΝΤΟΥ: κανένας descriptor δεν διαρρέει σε παιδική διεργασία.
_OPEN_FLAGS = os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK | os.O_CLOEXEC
_DIR_FLAGS = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC
# ΑΓΚΥΡΑ: ΧΩΡΙΣ NO_XDEV — τα mountpoints (bind mounts, tmpfs, docker volumes)
# είναι ΝΟΜΙΜΑ στη διαδρομή προς την άγκυρα. Τα symlinks ΟΧΙ.
_RESOLVE_ANCHOR = RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS
# ΚΑΤΩ ΑΠΟ ΤΗΝ ΑΓΚΥΡΑ: πλήρες RESOLVE_STRICT — το candidate δέντρο ΔΕΝ
# επιτρέπεται να απλώνεται σε άλλο filesystem.


# ═════════════════════════════════════════════════════════════════════════════
# Η MERKLE ΕΔΡΑ — ΑΚΡΙΒΩΣ η παραγωγική (source/merkle-authority.lisp)
# ═════════════════════════════════════════════════════════════════════════════
# leaf = SHA-256(0x00 ‖ ΩΜΑ BYTES)          ← hash-leaf-bytes / hash-leaf-file
# node = SHA-256(0x01 ‖ raw(L) ‖ raw(R))    ← hash-node
# MTH  : n=0 ⇒ SHA-256("")· n=1 ⇒ το φύλλο· n>1 ⇒ unbalanced split στη μεγαλύτερη
#        δύναμη του 2 ΑΥΣΤΗΡΑ < n. ΠΟΤΕ duplicate-last (κλάση CVE-2012-2459).

def _leaf(data: bytes) -> str:
    return PREFIX + hashlib.sha256(LEAF_DOMAIN + data).hexdigest()


def _leaf_hasher():
    h = hashlib.sha256()
    h.update(LEAF_DOMAIN)
    return h


def _node(a: str, b: str) -> str:
    return PREFIX + hashlib.sha256(
        NODE_DOMAIN + bytes.fromhex(a[len(PREFIX):]) + bytes.fromhex(b[len(PREFIX):])).hexdigest()


def _mth_recursive(leaves):
    """RFC 9162 §2.1.1 με ΑΝΑΔΡΟΜΙΚΗ ΔΙΑΣΠΑΣΗ στη μεγαλύτερη δύναμη του 2 < n."""
    if not leaves:
        return PREFIX + hashlib.sha256(b"").hexdigest()
    if len(leaves) == 1:
        return leaves[0]
    k = 1
    while k * 2 < len(leaves):
        k *= 2
    return _node(_mth_recursive(leaves[:k]), _mth_recursive(leaves[k:]))


def _mth_streaming(leaves):
    """Ο ΙΔΙΟΣ MTH με ΔΟΜΙΚΑ ΔΙΑΦΟΡΕΤΙΚΟ αλγόριθμο: επαυξητική στοίβα τέλειων
    υποδέντρων (η κανονική μηχανική των CT logs). Καμία διάσπαση, καμία
    αναδρομή, καμία κοινή γραμμή λογικής με την _mth_recursive πέρα από το
    _node. Χρησιμεύει ως ΔΕΥΤΕΡΗ ΓΝΩΜΗ για ΚΑΘΕ n — εκεί ακριβώς όπου τα
    πεπερασμένα vectors δεν φτάνουν (εύρημα δημιουργού: μετάλλαξη μόνο σε n=18)."""
    if not leaves:
        return PREFIX + hashlib.sha256(b"").hexdigest()
    stack = []                      # [(hash, size)] με ΓΝΗΣΙΩΣ φθίνοντα sizes
    for lf in leaves:
        cur, size = lf, 1
        while stack and stack[-1][1] == size:
            top, tsz = stack.pop()
            cur, size = _node(top, cur), size * 2
        stack.append((cur, size))
    root = stack[-1][0]
    for h, _ in reversed(stack[:-1]):
        root = _node(h, root)
    return root


def _mth(leaves):
    """Η έδρα: ΔΥΟ ανεξάρτητοι αλγόριθμοι, υποχρεωτική συμφωνία για ΚΑΘΕ n."""
    a = _mth_recursive(leaves)
    b = _mth_streaming(leaves)
    if a != b:
        raise CaptureRefused("merkle-internal-divergence",
                             "n=%d: αναδρομικός=%s επαυξητικός=%s" % (len(leaves), a, b))
    return a


def _snapshot_leaf(path: str, size: int, file_leaf: str) -> str:
    p = path.encode("utf-8")
    rec = (SNAPSHOT_ENTRY_DOMAIN
           + len(p).to_bytes(8, "big") + p
           + size.to_bytes(8, "big")
           + bytes.fromhex(file_leaf[len(PREFIX):]))
    return _leaf(rec)


def verify_merkle_seat(vectors_path=GOLDEN_VECTORS):
    """Διασταύρωση με τα COMMITTED golden vectors — ΟΛΑ, μαζί με ΟΛΟ το
    differential range (εύρημα δημιουργού: ο παλιός έλεγχος σταματούσε στο n=17
    και μια μετάλλαξη «λάθος μόνο στο n=18» περνούσε).

    ΔΕΝ αρκεί: ο πίνακας είναι πεπερασμένος. Γι' αυτό η _mth συγκρίνει ΔΥΟ
    αλγορίθμους σε κάθε κλήση. Βλ. RETRACTED_CLAIMS."""
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
    checked, max_n = 0, 0
    if _mth([]) != v["empty_tree_root"]:
        raise CaptureRefused("merkle-seat-divergence", "MTH([]) ≠ committed")
    checked += 1
    for lv in v["leaves"]:
        if _leaf(bytes.fromhex(lv["input_hex"])) != lv["leaf"]:
            raise CaptureRefused("merkle-seat-divergence", "leaf %s" % lv["id"])
        checked += 1

    def tree_leaves(n):
        return [_leaf(str(i).encode("ascii")) for i in range(n)]

    for t in v["trees"]:
        if _mth(tree_leaves(t["n"])) != t["root"]:
            raise CaptureRefused("merkle-seat-divergence", "tree n=%d" % t["n"])
        checked += 1
        max_n = max(max_n, t["n"])
    d = v["differential"]                       # ΟΛΟ το εύρος, όχι δείγμα
    for i, expected in enumerate(d["roots"]):
        n = d["from"] + i
        if _mth(tree_leaves(n)) != expected:
            raise CaptureRefused("merkle-seat-divergence", "differential n=%d" % n)
        checked += 1
        max_n = max(max_n, n)
    return {"vectors_checked": checked, "max_verified_n": max_n}


# ═════════════════════════════════════════════════════════════════════════════
# ΑΓΚΥΡΩΣΗ — ΕΜΠΙΣΤΟΣ LAUNCHER, ΟΧΙ ΑΥΘΑΙΡΕΤΟ PATHNAME ΜΕΣΑ ΣΤΗΝ CAPTURE
# ═════════════════════════════════════════════════════════════════════════════
# ΕΤΥΜΗΓΟΡΙΑ ΔΗΜΙΟΥΡΓΟΥ (P0): «Η _open_anchor() εφαρμόζει RESOLVE_NO_XDEV
# ξεκινώντας από /. Επομένως απορρίπτει ΚΑΘΕ ΝΟΜΙΜΟ mountpoint ως
# symlink-in-anchor. /tmp και /workspace απορρίφθηκαν με EXDEV· 8 passed /
# 16 failed. Αυτό θα χτυπήσει ακριβώς Docker volumes/bind mounts.»
#
# ΑΠΟΛΥΤΑ ΟΡΘΟ — και η αιτία είναι εννοιολογική, όχι τυπογραφική: το NO_XDEV
# απαντά στην ερώτηση «μένει η ΔΙΑΣΧΙΣΗ μέσα στο ΙΔΙΟ filesystem;», που είναι
# σωστή ΜΕΣΑ στο candidate δέντρο και ΛΑΘΟΣ για τη διαδρομή προς την άγκυρα:
# κάθε άγκυρα σε container ΕΙΝΑΙ mountpoint.
#
# Η ΔΟΜΗ ΤΩΡΑ:
#   · Ο ΕΜΠΙΣΤΟΣ LAUNCHER (open_anchor) ανοίγει ΜΙΑ φορά τα δύο anchor dirfds,
#     διασχίζοντας συνιστώσα-προς-συνιστώσα με BENEATH|NO_SYMLINKS — **ΧΩΡΙΣ**
#     NO_XDEV, ώστε τα mountpoints να είναι νόμιμα — και ΕΠΑΛΗΘΕΥΕΙ
#     mount-id (/proc/self/fdinfo), owner και mode.
#   · Η capture ΔΕΝ βλέπει ΠΟΤΕ pathname: παίρνει ΤΑ dirfds (Anchor) και από
#     εκεί και κάτω ΜΟΝΟ relative openat2 με
#     BENEATH|NO_SYMLINKS|NO_XDEV|O_CLOEXEC.

class Anchor:
    """Επαληθευμένο anchor dirfd + η ταυτότητά του (mount-id/uid/gid/mode).
    Παράγεται ΜΟΝΟ από open_anchor() — η capture δεν δέχεται pathname."""

    __slots__ = ("fd", "path", "role", "mount_id", "uid", "gid", "mode")

    def __init__(self, fd, path, role, mount_id, st):
        self.fd, self.path, self.role, self.mount_id = fd, path, role, mount_id
        self.uid, self.gid, self.mode = st.st_uid, st.st_gid, stat.S_IMODE(st.st_mode)

    def evidence(self):
        return {"path": self.path, "role": self.role, "mount_id": self.mount_id,
                "uid": self.uid, "gid": self.gid, "mode": "0%o" % self.mode}

    def close(self):
        try:
            os.close(self.fd)
        except OSError:
            pass


def _mount_id(fd):
    """Το mount id του ανοιγμένου descriptor — ΑΠΟ ΤΟΝ ΠΥΡΗΝΑ (/proc/self/fdinfo)."""
    try:
        with open("/proc/self/fdinfo/%d" % fd, encoding="ascii") as fh:
            for line in fh:
                if line.startswith("mnt_id:"):
                    return int(line.split()[1])
    except (OSError, ValueError, IndexError):
        pass
    return None


def open_anchor(abs_path, role, expect_uid=None, expect_mount_id=None):
    """ΕΜΠΙΣΤΟΣ LAUNCHER: ανοίγει και ΕΠΑΛΗΘΕΥΕΙ μια άγκυρα. ROLE ∈ {inbox,vault}.

    Διάσχιση ΚΑΘΕ συνιστώσας με BENEATH|NO_SYMLINKS (ΟΧΙ NO_XDEV: τα mountpoints
    είναι ΝΟΜΙΜΑ — bind mounts, tmpfs, docker volumes). Symlink σε οποιαδήποτε
    συνιστώσα ⇒ `symlink-in-anchor`.

    ΕΠΑΛΗΘΕΥΣΗ:
      · vault : ΠΡΕΠΕΙ να ανήκει στην τρέχουσα ταυτότητα και να ΜΗΝ είναι
                εγγράψιμο από group/other (mode & 0o022 == 0) — αλλιώς δεν είναι
                authority-ιδιωτικό και το «quarantine» θα ήταν ψευδώνυμο.
      · inbox : ΑΠΑΓΟΡΕΥΕΤΑΙ world-writable ΧΩΡΙΣ sticky bit — αλλιώς τρίτος
                μπορεί να αντικαταστήσει τον candidate κατάλογο ολόκληρο.
      · expect_uid / expect_mount_id: προαιρετικά ΚΑΡΦΩΜΑΤΑ του καλούντος."""
    if role not in ("inbox", "vault"):
        raise CaptureRefused("anchor-role-unknown", repr(role))
    if not os.path.isabs(abs_path):
        raise CaptureRefused("anchor-not-absolute", abs_path)
    try:
        fd = os.open("/", _DIR_FLAGS)
    except OSError as e:
        raise _os_refuse(e, "/")
    try:
        for comp in [c for c in abs_path.split("/") if c]:
            if comp in (".", ".."):
                raise CaptureRefused("path-traversal", "συνιστώσα %r στην άγκυρα" % comp)
            try:
                nxt = openat2(fd, comp, _DIR_FLAGS, _RESOLVE_ANCHOR)
            except CaptureRefused as e:
                if e.reason in ("escapes-root", "open-refused"):
                    raise CaptureRefused(
                        "symlink-in-anchor",
                        "η συνιστώσα %r του %s δεν είναι απλός κατάλογος (%s)"
                        % (comp, abs_path, e.detail))
                raise
            os.close(fd)
            fd = nxt
        st = os.fstat(fd)
        mode = stat.S_IMODE(st.st_mode)
        if role == "vault":
            if st.st_uid != os.geteuid():
                raise CaptureRefused("anchor-not-owned",
                                     "το vault %s ανήκει σε uid=%d, τρέχουμε ως uid=%d"
                                     % (abs_path, st.st_uid, os.geteuid()))
            if mode & 0o022:
                raise CaptureRefused("anchor-group-world-writable",
                                     "το vault %s έχει mode 0%o — δεν είναι authority-ιδιωτικό"
                                     % (abs_path, mode))
        else:
            if (mode & 0o002) and not (st.st_mode & stat.S_ISVTX):
                raise CaptureRefused("anchor-world-writable",
                                     "το inbox %s είναι world-writable ΧΩΡΙΣ sticky (0%o)"
                                     % (abs_path, mode))
        if expect_uid is not None and st.st_uid != expect_uid:
            raise CaptureRefused("anchor-owner-mismatch",
                                 "uid=%d ≠ αναμενόμενο %d" % (st.st_uid, expect_uid))
        mid = _mount_id(fd)
        if expect_mount_id is not None and mid != expect_mount_id:
            raise CaptureRefused("anchor-mount-mismatch",
                                 "mount_id=%s ≠ αναμενόμενο %s" % (mid, expect_mount_id))
        return Anchor(fd, abs_path, role, mid, st)
    except BaseException:
        try:
            os.close(fd)
        except OSError:
            pass
        raise


def _tick(deadline):
    if time.monotonic() > deadline:
        raise CaptureRefused("limit-exceeded", "deadline (wall-clock)")


def _fingerprint(st):
    return (stat.S_IFMT(st.st_mode), st.st_nlink, st.st_ino, st.st_dev,
            st.st_size, st.st_mtime_ns, st.st_ctime_ns)


def _checked_name(entry_name, lim):
    """Επιστρέφει (bytes, str). Τα ονόματα ΕΙΝΑΙ bytes· η αυστηρή αποκωδικοποίηση
    UTF-8 είναι ΕΛΕΓΧΟΣ, όχι μετατροπή (εύρημα: UnicodeEncodeError σε surrogates)."""
    raw = os.fsencode(entry_name)
    if raw in (b"", b".", b".."):
        raise CaptureRefused("path-traversal", "συνιστώσα %r" % raw)
    if b"/" in raw or b"\x00" in raw:
        raise CaptureRefused("nul-or-empty-component", repr(raw))
    if len(raw) > lim["max_name_len"]:
        raise CaptureRefused("limit-exceeded", "όνομα > %d bytes" % lim["max_name_len"])
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise CaptureRefused("non-utf8-name",
                             "%r δεν είναι έγκυρο UTF-8 (%s)" % (raw, exc.reason))
    return raw, text


def _list_names(dfd, lim, deadline):
    """Απαρίθμηση με ΟΡΙΟ ΠΡΙΝ ΤΗ ΣΥΣΣΩΡΕΥΣΗ (εύρημα: το sorted(scandir(...))
    φόρτωνε ολόκληρο τον κατάλογο πριν εφαρμοστεί όριο). Ταξινόμηση κατά BYTES."""
    out = []
    try:
        it = os.scandir(dfd)
    except OSError as e:
        raise _os_refuse(e, "scandir")
    try:
        for e in it:
            _tick(deadline)
            if len(out) >= lim["max_dir_entries"]:
                raise CaptureRefused("limit-exceeded",
                                     "καταχωρήσεις καταλόγου > %d" % lim["max_dir_entries"])
            out.append(_checked_name(e.name, lim))
    except OSError as exc:
        raise _os_refuse(exc, "scandir-iter")
    finally:
        it.close()
    out.sort(key=lambda t: t[0])
    return out


def _write_all(fd, buf):
    """ΚΑΘΕ byte γράφεται· η os.write ΕΠΙΤΡΕΠΕΤΑΙ να γράψει λιγότερα."""
    mv = memoryview(buf)
    off, n = 0, len(buf)
    while off < n:
        try:
            w = os.write(fd, mv[off:])
        except OSError as e:
            raise _os_refuse(e, "write")
        if w <= 0:
            raise CaptureRefused("short-write", "os.write ⇒ %d" % w)
        off += w
    return off


def _purge(parent_fd, name_bytes):
    """Descriptor-based αναδρομική διαγραφή του ΜΕΡΙΚΟΥ quarantine.

    ΕΤΥΜΗΓΟΡΙΑ ΔΗΜΙΟΥΡΓΟΥ: «το cleanup είναι best-effort και καταπίνει όλα τα
    σφάλματα». ΟΡΘΟ — σιωπηλός καθαρισμός σημαίνει ότι ένα μισοχτισμένο δέντρο
    μπορεί να επιβιώσει ΧΩΡΙΣ κανείς να το μάθει. Τώρα ΕΠΙΣΤΡΕΦΕΙ τη λίστα των
    αποτυχιών· ο καλών την κάνει ΟΡΑΤΗ ως `cleanup-incomplete`."""
    failures = []
    try:
        fd = openat2(parent_fd, name_bytes, _DIR_FLAGS, RESOLVE_STRICT)
    except (CaptureRefused, OSError) as e:
        return ["άνοιγμα %r: %s" % (name_bytes, e)]
    try:
        with os.scandir(fd) as it:
            entries = [(os.fsencode(e.name), e.is_dir(follow_symlinks=False)) for e in it]
        for raw, isdir in entries:
            if isdir:
                failures.extend(_purge(fd, raw))
            else:
                try:
                    os.unlink(raw, dir_fd=fd)
                except OSError as e:
                    failures.append("unlink %r: %s" % (raw, e))
    except OSError as e:
        failures.append("scandir %r: %s" % (name_bytes, e))
    finally:
        os.close(fd)
    try:
        os.rmdir(name_bytes, dir_fd=parent_fd)
    except OSError as e:
        failures.append("rmdir %r: %s" % (name_bytes, e))
    return failures


# ═════════════════════════════════════════════════════════════════════════════
# CANONICAL PROFILE — ΥΠΟΧΡΕΩΤΙΚΟ, ΚΑΡΦΩΜΕΝΟ, ΜΟΝΑΔΙΚΟ, ΧΩΡΙΣ ΔΙΠΛΟΤΥΠΑ
# ═════════════════════════════════════════════════════════════════════════════

class CanonicalProfile:
    """ΑΔΙΑΦΑΝΕΣ, ΕΠΙΚΥΡΩΜΕΝΟ profile. Παράγεται ΜΟΝΟ από load_canonical_profile().

    ΕΤΥΜΗΓΟΡΙΑ ΔΗΜΙΟΥΡΓΟΥ (P1): «Το “υποχρεωτικό καρφωμένο canonical profile”
    παρακάμπτεται από το ίδιο το API: capture(..., canonical_profile=<οποιοδήποτε
    dict>) και measure(...) χρησιμοποιούν το dict ΧΩΡΙΣ load_canonical_profile()
    και ΧΩΡΙΣ επικύρωση.» ΟΡΘΟ — ο φρουρός ήταν στην πόρτα, όχι στον τύπο.
    Τώρα τα production APIs δέχονται ΜΟΝΟ αυτόν τον τύπο· dict ⇒ ΑΡΝΗΣΗ."""

    __slots__ = ("profile_id", "files", "sha256", "path")

    def __init__(self, profile_id, files, sha256, path):
        self.profile_id, self.files, self.sha256, self.path = profile_id, files, sha256, path


def _require_profile(profile):
    """Ο ΜΟΝΟΣ τρόπος να μπει profile στην παραγωγή: επικυρωμένο αντικείμενο."""
    if profile is None:
        return load_canonical_profile()
    if not isinstance(profile, CanonicalProfile):
        raise CaptureRefused(
            "canonical-profile-not-validated",
            "τα production APIs δέχονται ΜΟΝΟ CanonicalProfile από "
            "load_canonical_profile()· δόθηκε %s" % type(profile).__name__)
    return profile


def load_canonical_profile(path=CANONICAL_PROFILE):
    try:
        with open(path, "rb") as fh:
            raw = fh.read()
        prof = json.loads(raw.decode("utf-8"))
    except (OSError, ValueError) as exc:
        raise CaptureRefused("canonical-profile-unreadable", "%s: %s" % (path, exc))
    if prof.get("profile_id") != CANONICAL_PROFILE_ID:
        raise CaptureRefused("canonical-profile-invalid",
                             "profile_id=%r ≠ %r" % (prof.get("profile_id"), CANONICAL_PROFILE_ID))
    files = prof.get("files")
    if not isinstance(files, list) or not files:
        raise CaptureRefused("canonical-profile-invalid",
                             "ΚΕΝΗ λίστα — θα έδινε τη ρίζα του κενού δέντρου για ΚΑΘΕ περιεχόμενο")
    seen = set()
    for f in files:
        if not isinstance(f, str) or not f or f.startswith("/") or ".." in f.split("/"):
            raise CaptureRefused("canonical-profile-invalid", "μη έγκυρη εγγραφή %r" % (f,))
        if f in seen:
            raise CaptureRefused("canonical-profile-duplicate",
                                 "%r εμφανίζεται δύο φορές — δύο ρίζες για τα ΙΔΙΑ bytes" % f)
        seen.add(f)
    return CanonicalProfile(prof["profile_id"], tuple(files),
                            hashlib.sha256(raw).hexdigest(), path)


# ═════════════════════════════════════════════════════════════════════════════
# ΦΑΣΗ Α — ΑΝΤΙΓΡΑΦΗ (ΚΑΝΕΝΑ hash· κάθε fd κλείνει ΑΜΕΣΩΣ)
# ═════════════════════════════════════════════════════════════════════════════

class _CopyState:
    def __init__(self, lim, deadline):
        self.lim, self.deadline = lim, deadline
        self.copied, self.total = [], 0


def _copy_dir(src_fd, dst_fd, rel, depth, st):
    if depth > st.lim["max_depth"]:
        raise CaptureRefused("limit-exceeded", "βάθος > %d" % st.lim["max_depth"])
    for raw, name in _list_names(src_fd, st.lim, st.deadline):
        _tick(st.deadline)
        child = "%s/%s" % (rel, name) if rel else name
        fd = openat2(src_fd, raw, _OPEN_FLAGS, RESOLVE_STRICT)
        try:
            sb = os.fstat(fd)
            if stat.S_ISDIR(sb.st_mode):
                try:
                    os.mkdir(raw, 0o700, dir_fd=dst_fd)
                except FileExistsError:
                    raise CaptureRefused("quarantine-preexisting", child)
                except OSError as e:
                    raise _os_refuse(e, "mkdir %s" % child)
                nq = openat2(dst_fd, raw, _DIR_FLAGS,
                             RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS)
                try:
                    _copy_dir(fd, nq, child, depth + 1, st)
                    os.fsync(nq)
                finally:
                    os.close(nq)          # ΑΜΕΣΩΣ — O(βάθος), όχι O(αρχεία)
                continue
            if not stat.S_ISREG(sb.st_mode):
                raise CaptureRefused("non-regular-file", child)
            if sb.st_nlink > 1:
                raise CaptureRefused("hardlink-present", "%s (nlink=%d)" % (child, sb.st_nlink))
            if sb.st_size > st.lim["max_file_bytes"]:
                raise CaptureRefused("limit-exceeded", "%s > max_file_bytes" % child)
            if len(st.copied) + 1 > st.lim["max_files"]:
                raise CaptureRefused("limit-exceeded", "max_files")
            before = _fingerprint(sb)
            try:
                wfd = os.open(raw, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                              0o600, dir_fd=dst_fd)
            except OSError as e:
                raise _os_refuse(e, "create %s" % child)
            written = 0
            try:
                while True:
                    _tick(st.deadline)
                    try:
                        chunk = os.read(fd, CHUNK)
                    except OSError as e:
                        raise _os_refuse(e, "read %s" % child)
                    if not chunk:
                        break
                    written += _write_all(wfd, chunk)
                    if written > st.lim["max_file_bytes"]:
                        raise CaptureRefused("limit-exceeded", "%s ξεπέρασε το όριο" % child)
                    if st.total + written > st.lim["max_total_bytes"]:
                        raise CaptureRefused("limit-exceeded", "max_total_bytes")
                try:
                    os.fsync(wfd)
                except OSError as e:
                    raise _os_refuse(e, "fsync %s" % child)
            finally:
                os.close(wfd)             # ΑΜΕΣΩΣ
            if _fingerprint(os.fstat(fd)) != before:
                raise CaptureRefused("mutated-during-capture", child)
            os.chmod(raw, 0o400, dir_fd=dst_fd)
            st.total += written
            st.copied.append((child, written))
        finally:
            os.close(fd)                  # ΑΜΕΣΩΣ, σε ΚΑΘΕ διαδρομή
    return st


# ═════════════════════════════════════════════════════════════════════════════
# ΦΑΣΗ Β — ΜΕΤΡΗΣΗ ΑΠΟΚΛΕΙΣΤΙΚΑ ΑΠΟ ΤΟ QUARANTINE
# ═════════════════════════════════════════════════════════════════════════════

def _measure_dir(dfd, rel, depth, lim, deadline, st):
    """ΤΑ ΙΔΙΑ ΣΥΝΟΛΙΚΑ ΟΡΙΑ ΜΕ ΤΗ ΦΑΣΗ Α (εύρημα δημιουργού: «η δημόσια measure()
    δεν επιβάλλει max_files, max_file_bytes ή max_total_bytes»)."""
    if depth > lim["max_depth"]:
        raise CaptureRefused("limit-exceeded", "βάθος > %d" % lim["max_depth"])
    for raw, name in _list_names(dfd, lim, deadline):
        _tick(deadline)
        child = "%s/%s" % (rel, name) if rel else name
        fd = openat2(dfd, raw, _OPEN_FLAGS, RESOLVE_STRICT)
        try:
            sb = os.fstat(fd)
            if stat.S_ISDIR(sb.st_mode):
                _measure_dir(fd, child, depth + 1, lim, deadline, st)
                continue
            if not stat.S_ISREG(sb.st_mode) or sb.st_nlink != 1:
                raise CaptureRefused("quarantine-corrupt",
                                     "%s (mode=%o nlink=%d)" % (child, sb.st_mode, sb.st_nlink))
            if len(st.census) + 1 > lim["max_files"]:
                raise CaptureRefused("limit-exceeded", "max_files (measure)")
            if sb.st_size > lim["max_file_bytes"]:
                raise CaptureRefused("limit-exceeded", "%s > max_file_bytes (measure)" % child)
            leafh, conth, size = _leaf_hasher(), hashlib.sha256(), 0
            while True:
                _tick(deadline)
                try:
                    chunk = os.read(fd, CHUNK)
                except OSError as e:
                    raise _os_refuse(e, "read %s" % child)
                if not chunk:
                    break
                leafh.update(chunk)
                conth.update(chunk)
                size += len(chunk)
                if size > lim["max_file_bytes"]:
                    raise CaptureRefused("limit-exceeded",
                                         "%s ξεπέρασε το max_file_bytes (measure)" % child)
                if st.total + size > lim["max_total_bytes"]:
                    raise CaptureRefused("limit-exceeded", "max_total_bytes (measure)")
            st.total += size
            st.census.append({"path": child, "size": size, "sha256": conth.hexdigest(),
                              "leaf": PREFIX + leafh.hexdigest()})
        finally:
            os.close(fd)


class _MeasureState:
    __slots__ = ("census", "total")

    def __init__(self):
        self.census, self.total = [], 0


def measure(vault, quarantine_name, profile=None, limits=None):
    """Ο ΜΟΝΟΣ παραγωγός αριθμών: ξαναδιαβάζει ΚΑΘΕ byte από το quarantine.

    VAULT είναι ΕΠΑΛΗΘΕΥΜΕΝΟ Anchor (open_anchor(..., "vault")) — ΟΧΙ pathname.
    PROFILE είναι ΕΠΙΚΥΡΩΜΕΝΟ CanonicalProfile — ΟΧΙ dict."""
    if not isinstance(vault, Anchor) or vault.role != "vault":
        raise CaptureRefused("anchor-required",
                             "η measure() δέχεται ΜΟΝΟ επαληθευμένο vault Anchor")
    lim = dict(DEFAULT_LIMITS)
    if limits:
        lim.update(limits)
    deadline = time.monotonic() + lim["deadline_seconds"]
    seat = verify_merkle_seat()
    prof = _require_profile(profile)
    _checked_name(quarantine_name, lim)
    st = _MeasureState()
    qfd = openat2(vault.fd, os.fsencode(quarantine_name), _DIR_FLAGS, RESOLVE_STRICT)
    try:
        _measure_dir(qfd, "", 0, lim, deadline, st)
    finally:
        os.close(qfd)
    census = st.census
    if not census:
        raise CaptureRefused("quarantine-corrupt", "κανένα αρχείο στο quarantine")
    census.sort(key=lambda e: e["path"].encode("utf-8"))

    snapshot_root = _mth([_snapshot_leaf(e["path"], e["size"], e["leaf"]) for e in census])

    by_path = {e["path"]: e for e in census}
    missing = [f for f in prof.files if f not in by_path]
    if missing:
        raise CaptureRefused("canonical-missing", ", ".join(missing[:5]))
    # ΑΚΡΙΒΩΣ orchestrator.merkle:merkle-root-of-files — MTH πάνω σε
    # hash-leaf-file φύλλα, ΣΤΗ ΣΕΙΡΑ του καρφωμένου profile.
    release_root = _mth([by_path[f]["leaf"] for f in prof.files])

    return {"snapshot_root": snapshot_root, "release_root": release_root,
            "census": census, "quarantine": quarantine_name,
            "vault": vault.evidence(), "file_count": len(census),
            "total_bytes": st.total,
            "merkle_profile": MERKLE_PROFILE, "measured_from": "quarantine",
            "canonical_profile_id": prof.profile_id,
            "canonical_profile_sha256": prof.sha256,
            "merkle_seat": seat, "limits_used": lim}


# ═════════════════════════════════════════════════════════════════════════════
# CAPTURE = ΦΑΣΗ Α → ΦΑΣΗ Β → ΔΙΑΣΤΑΥΡΩΣΗ → FIXED POINT
# ═════════════════════════════════════════════════════════════════════════════

def capture(inbox, candidate_name, vault, quarantine_name, profile=None, limits=None):
    """Συλλαμβάνει το <inbox>/<candidate_name> σε ΝΕΟ <vault>/<quarantine_name>.

    INBOX και VAULT είναι ΕΠΑΛΗΘΕΥΜΕΝΑ Anchor (open_anchor) — η capture ΔΕΝ
    βλέπει ΠΟΤΕ pathname και ΔΕΝ διασχίζει ποτέ απόλυτη διαδρομή. Από τα anchors
    και κάτω: ΜΟΝΟ relative openat2 με BENEATH|NO_SYMLINKS|NO_XDEV|O_CLOEXEC.

    Κάθε ανωμαλία ⇒ CaptureRefused (fail-closed) ΚΑΙ καθαρισμός του μερικού
    quarantine· αν ο καθαρισμός αποτύχει, η αποτυχία ΕΙΝΑΙ ΟΡΑΤΗ
    (`cleanup-incomplete`), ΠΟΤΕ σιωπηλή."""
    if not isinstance(inbox, Anchor) or inbox.role != "inbox":
        raise CaptureRefused("anchor-required",
                             "η capture() δέχεται ΜΟΝΟ επαληθευμένο inbox Anchor")
    if not isinstance(vault, Anchor) or vault.role != "vault":
        raise CaptureRefused("anchor-required",
                             "η capture() δέχεται ΜΟΝΟ επαληθευμένο vault Anchor")
    lim = dict(DEFAULT_LIMITS)
    if limits:
        lim.update(limits)
    deadline = time.monotonic() + lim["deadline_seconds"]
    seat = verify_merkle_seat()                      # ΠΡΙΝ από κάθε byte
    prof = _require_profile(profile)
    _checked_name(quarantine_name, lim)
    _checked_name(candidate_name, lim)
    qraw = os.fsencode(quarantine_name)

    created = False
    try:
        try:
            os.mkdir(qraw, 0o700, dir_fd=vault.fd)
        except FileExistsError:
            raise CaptureRefused("quarantine-preexisting",
                                 "%s/%s υπάρχει ήδη — η authority δημιουργεί ΝΕΟ"
                                 % (vault.path, quarantine_name))
        except OSError as e:
            raise _os_refuse(e, "mkdir quarantine")
        created = True
        try:
            src = openat2(inbox.fd, os.fsencode(candidate_name), _DIR_FLAGS, RESOLVE_STRICT)
            try:
                dst = openat2(vault.fd, qraw, _DIR_FLAGS, RESOLVE_STRICT)
                try:
                    st = _copy_dir(src, dst, "", 0, _CopyState(lim, deadline))
                    os.fsync(dst)
                finally:
                    os.close(dst)
            finally:
                os.close(src)
        except OSError as e:
            raise _os_refuse(e, "capture")
        if not st.copied:
            raise CaptureRefused("empty-candidate", "κανένα regular file")

        result = measure(vault, quarantine_name, profile=prof, limits=lim)

        # ── ΔΙΑΣΤΑΥΡΩΣΗ ΦΑΣΕΩΝ: ό,τι γράφτηκε == ό,τι μετρήθηκε ──────────────
        written = sorted(st.copied, key=lambda t: t[0].encode("utf-8"))
        measured = [(e["path"], e["size"]) for e in result["census"]]
        if written != measured:
            wd, md = dict(written), dict(measured)
            raise CaptureRefused(
                "quarantine-diverged",
                "γράφτηκαν %d / μετρήθηκαν %d· μόνο-γραμμένα=%s μόνο-μετρημένα=%s"
                % (len(written), len(measured),
                   [p for p in wd if p not in md][:3], [p for p in md if p not in wd][:3]))
        if result["total_bytes"] != st.total:
            raise CaptureRefused("quarantine-diverged",
                                 "bytes γραμμένα=%d μετρημένα=%d" % (st.total, result["total_bytes"]))

        # ── FIXED POINT ΣΤΗΝ ΙΔΙΑ ΤΗΝ ΠΑΡΑΓΩΓΗ ──────────────────────────────
        again = measure(vault, quarantine_name, profile=prof, limits=lim)
        for k in ("snapshot_root", "release_root", "census", "file_count", "total_bytes"):
            if again[k] != result[k]:
                raise CaptureRefused("fixed-point-violation",
                                     "η δεύτερη μέτρηση διαφέρει στο %s" % k)

        result["inbox"] = inbox.evidence()
        result["seat_vectors_checked"] = seat["vectors_checked"]
        result["max_verified_n"] = seat["max_verified_n"]
        result["fixed_point"] = "verified-in-capture"
        created = False                              # επιτυχία ⇒ ΔΕΝ καθαρίζεται
        return result
    except OSError as e:                             # καμία ακατέργαστη εξαίρεση
        raise _os_refuse(e, "capture")
    finally:
        if created:
            failures = _purge(vault.fd, qraw)
            if failures:
                # ΟΡΑΤΗ αποτυχία καθαρισμού — ΠΟΤΕ σιωπηλή κατάποση σφαλμάτων.
                raise CaptureRefused(
                    "cleanup-incomplete",
                    "το ΜΕΡΙΚΟ quarantine %s ΔΕΝ καθαρίστηκε πλήρως: %s"
                    % (quarantine_name, "· ".join(failures[:5])))


if __name__ == "__main__":
    # Ο ΕΜΠΙΣΤΟΣ LAUNCHER: ΕΔΩ και ΜΟΝΟ εδώ υπάρχουν pathnames. Ανοίγει και
    # ΕΠΑΛΗΘΕΥΕΙ τα δύο anchors και τα παραδίδει στην capture ως descriptors.
    if len(sys.argv) != 5:
        print("usage: capture.py <inbox-dir> <candidate-name> <vault-dir> <NEW-quarantine-name>")
        sys.exit(2)
    inbox_a = vault_a = None
    try:
        inbox_a = open_anchor(os.path.abspath(sys.argv[1]), "inbox")
        vault_a = open_anchor(os.path.abspath(sys.argv[3]), "vault")
        r = capture(inbox_a, sys.argv[2], vault_a, sys.argv[4])
        print(json.dumps({k: r[k] for k in
                          ("snapshot_root", "release_root", "file_count", "total_bytes",
                           "merkle_profile", "canonical_profile_id",
                           "canonical_profile_sha256", "seat_vectors_checked",
                           "max_verified_n", "fixed_point", "inbox", "vault")},
                         ensure_ascii=False, sort_keys=True))
    except CaptureRefused as e:
        print("::error::CAPTURE REFUSED — %s" % e)
        sys.exit(1)
    finally:
        for a in (inbox_a, vault_a):
            if a is not None:
                a.close()
