#!/usr/bin/env bash
# =============================================================================
# ΜΑΡΤΥΡΑΣ ΣΕ ΠΡΑΓΜΑΤΙΚΑ MOUNTPOINTS — bind mount ΚΑΙ ξεχωριστό filesystem
# =============================================================================
# ΕΤΥΜΗΓΟΡΙΑ ΔΗΜΙΟΥΡΓΟΥ (P0): «Η _open_anchor() εφαρμόζει RESOLVE_NO_XDEV
# ξεκινώντας από /. Απορρίπτει ΚΑΘΕ ΝΟΜΙΜΟ mountpoint ως symlink-in-anchor.
# /tmp και /workspace απορρίφθηκαν με EXDEV· 8 passed / 16 failed. Αυτό θα
# χτυπήσει ακριβώς Docker volumes/bind mounts.»
#
# Η αιτία ήταν εννοιολογική: το NO_XDEV απαντά «μένει η διάσχιση στο ΙΔΙΟ
# filesystem;» — σωστή ερώτηση ΜΕΣΑ στο candidate δέντρο, ΛΑΘΟΣ για τη διαδρομή
# προς την άγκυρα, αφού κάθε άγκυρα σε container ΕΙΝΑΙ mountpoint.
#
# ΑΥΤΟ ΤΟ TEST ΦΤΙΑΧΝΕΙ ΠΡΑΓΜΑΤΙΚΑ MOUNTS (δεν προσομοιώνει):
#   ① tmpfs      ⇒ inbox σε ΞΕΧΩΡΙΣΤΟ filesystem
#   ② bind mount ⇒ vault πίσω από bind mount (η ακριβής τοπολογία Docker)
#   ③ ΘΕΤΙΚΟΣ: η capture ΠΕΤΥΧΑΙΝΕΙ και τα δύο mount-id ΔΙΑΦΕΡΟΥΝ (άρα ΟΝΤΩΣ
#      διασχίστηκαν όρια mount — ο έλεγχος δεν είναι τετριμμένος)
#   ④ ΑΡΝΗΤΙΚΟΣ: nested mount ΜΕΣΑ στο candidate ⇒ ΑΡΝΗΣΗ (το NO_XDEV ΚΑΤΩ από
#      την άγκυρα ΠΑΡΑΜΕΝΕΙ — δεν χαλάρωσε τίποτα)
#   ⑤ ΑΡΝΗΤΙΚΟΣ: symlink σε συνιστώσα της άγκυρας ⇒ ΑΡΝΗΣΗ (πάνω σε mountpoint)
#   ⑥ ΠΑΛΙΝΔΡΟΜΗΣΗ: η ΠΑΛΙΑ λογική (NO_XDEV από «/») απορρίπτει το ΙΔΙΟ νόμιμο
#      mountpoint — αποδεικνύει ότι το σφάλμα ήταν ΠΡΑΓΜΑΤΙΚΟ και ότι ο μάρτυρας
#      θα το ξαναπιάσει
#
# Χωρίς root/CAP_SYS_ADMIN ⇒ exit 2 BLOCKED, ΠΟΤΕ pass.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
p=0; f=0
ok(){ p=$((p+1)); echo "  ok   $*"; }
no(){ f=$((f+1)); echo "  FAIL $*"; }

[ "$(id -u)" -eq 0 ] || { echo "::error::BLOCKED — απαιτείται root για mount(2)"; exit 2; }

WORK="$(mktemp -d)"
cleanup(){ umount -l "$WORK/cand-sub" 2>/dev/null; umount -l "$WORK/bind" 2>/dev/null;
           umount -l "$WORK/tmpfs" 2>/dev/null; rm -rf "$WORK"; }
trap cleanup EXIT
mkdir -p "$WORK/tmpfs" "$WORK/real" "$WORK/bind"

mount -t tmpfs -o size=64m tmpfs "$WORK/tmpfs" || { echo "::error::BLOCKED — tmpfs mount απέτυχε"; exit 2; }
mount --bind "$WORK/real" "$WORK/bind"          || { echo "::error::BLOCKED — bind mount απέτυχε"; exit 2; }
chmod 0700 "$WORK/bind"

CANON_JSON="$REPO/authority-v2/capture/canonical-profile.json"
build_candidate() {                 # $1 = κατάλογος candidate
  mkdir -p "$1"
  python3 - "$CANON_JSON" "$1" <<'PY'
import json, os, sys
prof = json.load(open(sys.argv[1], encoding="utf-8"))
for rel in prof["files"]:
    p = os.path.join(sys.argv[2], rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "wb").write(("canonical:" + rel).encode("utf-8"))
PY
}

run_capture() {                     # $1 inbox, $2 name, $3 vault, $4 qname
  python3 "$REPO/authority-v2/capture/capture.py" "$1" "$2" "$3" "$4" 2>&1
}

echo "== ①②③ inbox σε tmpfs (ΞΕΧΩΡΙΣΤΟ fs) → vault πίσω από BIND MOUNT =="
mkdir -p "$WORK/tmpfs/inbox"
build_candidate "$WORK/tmpfs/inbox/cand"
OUT="$(run_capture "$WORK/tmpfs/inbox" cand "$WORK/bind" q1)"
IN_MNT="$(echo "$OUT" | python3 -c 'import json,sys
try: print(json.load(sys.stdin)["inbox"]["mount_id"])
except Exception: print("")' 2>/dev/null)"
VA_MNT="$(echo "$OUT" | python3 -c 'import json,sys
try: print(json.load(sys.stdin)["vault"]["mount_id"])
except Exception: print("")' 2>/dev/null)"
ROOT_MNT="$(python3 -c "
import os
fd=os.open('/',os.O_RDONLY|os.O_DIRECTORY)
print([l.split()[1] for l in open('/proc/self/fdinfo/%d'%fd) if l.startswith('mnt_id')][0])
os.close(fd)")"
if [ -n "$IN_MNT" ] && [ -n "$VA_MNT" ]; then
  ok "capture ΠΕΤΥΧΕ πάνω σε πραγματικά mountpoints (inbox mnt=$IN_MNT, vault mnt=$VA_MNT)"
else
  no "capture ΑΠΕΤΥΧΕ σε νόμιμα mountpoints: $(echo "$OUT" | head -2)"
fi
[ -n "$IN_MNT" ] && [ "$IN_MNT" != "$VA_MNT" ] \
  && ok "τα δύο anchors είναι σε ΔΙΑΦΟΡΕΤΙΚΑ mounts — ο έλεγχος ΔΕΝ είναι τετριμμένος" \
  || no "τα anchors είναι στο ΙΔΙΟ mount ($IN_MNT/$VA_MNT) — ΚΕΝΟΣ ΜΑΡΤΥΡΑΣ"
[ -n "$IN_MNT" ] && [ "$IN_MNT" != "$ROOT_MNT" ] \
  && ok "το inbox ΔΕΝ είναι στο mount της ρίζας (root mnt=$ROOT_MNT) — όντως διασχίστηκε όριο" \
  || no "το inbox είναι στο ΙΔΙΟ mount με τη ρίζα — ΚΕΝΟΣ ΜΑΡΤΥΡΑΣ"

echo
echo "== ④ ΑΡΝΗΤΙΚΟΣ: nested mount ΜΕΣΑ στο candidate ⇒ ΑΡΝΗΣΗ (NO_XDEV ισχύει) =="
mkdir -p "$WORK/tmpfs/inbox/cand2"
build_candidate "$WORK/tmpfs/inbox/cand2"
mkdir -p "$WORK/tmpfs/inbox/cand2/sub" "$WORK/cand-sub"
mount -t tmpfs -o size=8m tmpfs "$WORK/tmpfs/inbox/cand2/sub" 2>/dev/null \
  && echo "hidden" > "$WORK/tmpfs/inbox/cand2/sub/x.txt"
OUT2="$(run_capture "$WORK/tmpfs/inbox" cand2 "$WORK/bind" q2)"
umount -l "$WORK/tmpfs/inbox/cand2/sub" 2>/dev/null
case "$OUT2" in
  *"escapes-root"*|*"open-refused"*) ok "nested mount ΜΕΣΑ στο candidate ⇒ ΑΡΝΗΣΗ (το NO_XDEV ΚΑΤΩ από την άγκυρα ΠΑΡΑΜΕΝΕΙ)";;
  *) no "nested mount ΜΕΣΑ στο candidate ΕΓΙΝΕ ΔΕΚΤΟ: $(echo "$OUT2" | head -1)";;
esac

echo
echo "== ⑤ ΑΡΝΗΤΙΚΟΣ: symlink σε συνιστώσα της άγκυρας ⇒ ΑΡΝΗΣΗ (πάνω σε mount) =="
ln -s "$WORK/tmpfs/inbox" "$WORK/tmpfs/inbox-link"
OUT3="$(run_capture "$WORK/tmpfs/inbox-link" cand "$WORK/bind" q3)"
case "$OUT3" in
  *"symlink-in-anchor"*) ok "symlink στην άγκυρα ⇒ symlink-in-anchor (η άμυνα ΔΕΝ χαλάρωσε)";;
  *) no "symlink στην άγκυρα ΕΓΙΝΕ ΔΕΚΤΟ: $(echo "$OUT3" | head -1)";;
esac

echo
echo "== ⑥ ΠΑΛΙΝΔΡΟΜΗΣΗ: η ΠΑΛΙΑ λογική (NO_XDEV από «/») απορρίπτει νόμιμο mount =="
OLD="$(python3 - "$WORK/tmpfs/inbox" <<'PY'
import ctypes, ctypes.util, errno, os, sys
SYS_openat2, NO_XDEV, NO_SYMLINKS, BENEATH = 437, 0x01, 0x04, 0x08
class H(ctypes.Structure):
    _fields_ = [("flags", ctypes.c_uint64), ("mode", ctypes.c_uint64), ("resolve", ctypes.c_uint64)]
libc = ctypes.CDLL(ctypes.util.find_library("c"), use_errno=True)
def oa2(dirfd, name, resolve):
    h = H(flags=os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, mode=0, resolve=resolve)
    rc = libc.syscall(ctypes.c_long(SYS_openat2), ctypes.c_int(dirfd),
                      ctypes.c_char_p(os.fsencode(name)), ctypes.byref(h),
                      ctypes.c_size_t(ctypes.sizeof(h)))
    return rc if rc >= 0 else -ctypes.get_errno()
fd = os.open("/", os.O_RDONLY | os.O_DIRECTORY)
strict = BENEATH | NO_SYMLINKS | NO_XDEV
for comp in [c for c in sys.argv[1].split("/") if c]:
    nxt = oa2(fd, comp, strict)
    if nxt < 0:
        print("REJECTED %s errno=%d(%s)" % (comp, -nxt, errno.errorcode.get(-nxt, "?")))
        break
    os.close(fd); fd = nxt
else:
    print("ACCEPTED")
PY
)"
case "$OLD" in
  REJECTED*EXDEV*) ok "η ΠΑΛΙΑ λογική ΑΠΟΡΡΙΠΤΕΙ το νόμιμο mountpoint ($OLD) — το σφάλμα ήταν ΠΡΑΓΜΑΤΙΚΟ";;
  ACCEPTED)        no "η παλιά λογική ΔΕΝ απορρίπτει εδώ — ο μάρτυρας ΔΕΝ αποδεικνύει την παλινδρόμηση σε αυτό το περιβάλλον";;
  *)               no "απροσδόκητο: $OLD";;
esac

echo
echo "── capture mountpoint witnesses: $p passed, $f failed ──"
[ "$f" -eq 0 ]
