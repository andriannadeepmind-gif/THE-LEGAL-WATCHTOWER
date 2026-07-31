#!/usr/bin/env bash
# =============================================================================
# ΟΡΙΟ ΠΥΡΗΝΑ — Η ΑΡΝΗΣΗ ΑΠΟΔΙΔΕΤΑΙ ΣΤΟ MOUNT, ΟΧΙ ΣΕ ΔΙΚΑΙΩΜΑΤΑ
# =============================================================================
# ΕΤΥΜΗΓΟΡΙΑ ΔΗΜΙΟΥΡΓΟΥ (P1): «το test ΔΕΝ αποδεικνύει το read-only bind mount:
# τα mount/remount αγνοούν exit codes, το releases/ είναι root-owned και ο
# producer τρέχει με ΑΛΛΟ uid — άρα η άρνηση εξηγείται πλήρως από απλά
# δικαιώματα. Και τίποτα δεν είναι συρματωμένο σε Docker/CI.» ΟΡΘΟ.
#
# Η ΔΟΜΙΚΗ ΑΠΑΝΤΗΣΗ — ΟΧΙ επιπλέον έλεγχος, αλλά ΑΦΑΙΡΕΣΗ ΚΑΘΕ ΑΛΛΗΣ ΕΞΗΓΗΣΗΣ:
#   ① Το releases/ ανήκει ΣΤΟΝ ΙΔΙΟ ΤΟΝ PRODUCER με mode 0700. Με απλά
#      δικαιώματα ο producer ΕΧΕΙ ΠΛΗΡΗ ΕΓΓΡΑΦΗ. Καμία άμυνα από permissions.
#   ② ΘΕΤΙΚΟΣ ΕΛΕΓΧΟΣ ΧΩΡΙΣ MOUNT: ο producer ΓΡΑΦΕΙ όντως. Αν δεν γράψει, ο
#      έλεγχος είναι ΑΚΥΡΟΣ (exit 2) — δεν δηλώνεται ποτέ pass.
#   ③ ΙΔΙΟ path, ΙΔΙΟ uid, ΙΔΙΑ δικαιώματα, ΜΟΝΗ ΔΙΑΦΟΡΑ το ro bind mount ⇒ η
#      εγγραφή ΟΦΕΙΛΕΙ να αποτύχει με **EROFS (30)** — ΟΧΙ EACCES (13). Το
#      errno είναι η υπογραφή του ΜΗΧΑΝΙΣΜΟΥ: 30 = read-only filesystem,
#      13 = δικαιώματα. Ελέγχεται ΑΡΙΘΜΗΤΙΚΑ (καμία εξάρτηση από locale).
#   ④ Τα exit codes των mount/remount ΕΛΕΓΧΟΝΤΑΙ, και η κατάσταση ro
#      επιβεβαιώνεται από το /proc/self/mountinfo. Χωρίς CAP_SYS_ADMIN ⇒
#      BLOCKED (exit 2). ΚΑΜΙΑ σιωπηλή υποβάθμιση σε chmod — αυτό θα ήταν
#      ΑΛΛΟΣ μηχανισμός και ψευδής ισχυρισμός.
#
# Χωρίς root/setpriv/unshare ⇒ exit 2 BLOCKED, ΠΟΤΕ pass.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
p=0; f=0
ok(){ p=$((p+1)); echo "  ok   $*"; }
no(){ f=$((f+1)); echo "  FAIL $*"; }

[ "$(id -u)" -eq 0 ] || { echo "::error::BLOCKED — απαιτείται root"; exit 2; }
command -v setpriv >/dev/null || { echo "::error::BLOCKED — setpriv ΑΠΩΝ"; exit 2; }
command -v unshare >/dev/null || { echo "::error::BLOCKED — unshare ΑΠΩΝ"; exit 2; }
id lawmax-producer >/dev/null 2>&1 || bash "$REPO/authority-v2/capability/identities.sh" >/dev/null 2>&1
id lawmax-producer >/dev/null 2>&1 || { echo "::error::BLOCKED — ταυτότητες δεν δημιουργήθηκαν"; exit 2; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
chmod 0755 "$WORK"

# ── Ο PRODUCER ΕΙΝΑΙ ΙΔΙΟΚΤΗΤΗΣ ΤΟΥ releases/ ─────────────────────────────────
# Επίτηδες: αφαιρούμε ΚΑΘΕ άμυνα από δικαιώματα, ώστε ό,τι απομείνει να είναι
# αποκλειστικά ο μηχανισμός του πυρήνα.
OUT="$WORK/out"
mkdir -p "$OUT/releases/sha256-legacy/temporal-proof" "$OUT/candidates"
echo "LEGACY EVIDENCE" > "$OUT/releases/sha256-legacy/temporal-proof/timestamp.tsr"
BEFORE="$(sha256sum "$OUT/releases/sha256-legacy/temporal-proof/timestamp.tsr" | cut -d' ' -f1)"
chown -R lawmax-producer:lawmax-producer "$OUT"
chmod -R u+rwX "$OUT"
chmod 0755 "$OUT"

as_producer(){ setpriv --reuid=lawmax-producer --regid=lawmax-producer --clear-groups "$@"; }

# Ο ΜΙΚΡΟΣ ΚΡΙΤΗΣ: επιχειρεί εγγραφή και τυπώνει ΑΡΙΘΜΗΤΙΚΟ errno ή WROTE.
PROBE="$WORK/write-probe.py"
cat > "$PROBE" <<'PY'
import os, sys
try:
    fd = os.open(sys.argv[1], os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    os.write(fd, b"PWNED")
    os.close(fd)
    print("WROTE")
except OSError as e:
    print("ERRNO %d" % e.errno)
PY
chmod 0644 "$PROBE"

echo "== ① ΘΕΤΙΚΟΣ ΕΛΕΓΧΟΣ: ΧΩΡΙΣ MOUNT Ο PRODUCER ΓΡΑΦΕΙ ΣΤΟ releases/ =="
R1="$(as_producer python3 "$PROBE" "$OUT/releases/sha256-legacy/temporal-proof/probe.txt")"
if [ "$R1" = "WROTE" ]; then
  ok "χωρίς mount: ο producer ΓΡΑΦΕΙ (άρα τα δικαιώματα ΔΕΝ είναι η άμυνα)"
  rm -f "$OUT/releases/sha256-legacy/temporal-proof/probe.txt"
else
  echo "::error::ΑΚΥΡΟΣ ΕΛΕΓΧΟΣ — ο producer δεν μπορεί να γράψει ούτε χωρίς mount ($R1)"
  exit 2
fi

echo
echo "== ② ΙΔΙΟ PATH/UID/ΔΙΚΑΙΩΜΑΤΑ + ro BIND MOUNT ⇒ EROFS (30), ΟΧΙ EACCES =="
INNER="$WORK/inner.sh"
cat > "$INNER" <<EOF
set -u
R="$OUT/releases"
mount --bind "\$R" "\$R"            || { echo "MOUNT-BIND-FAILED=\$?"; exit 91; }
mount -o remount,bind,ro "\$R"      || { echo "REMOUNT-RO-FAILED=\$?"; exit 92; }
# ΕΠΙΒΕΒΑΙΩΣΗ ΑΠΟ ΤΟΝ ΠΥΡΗΝΑ, όχι από την επιστροφή του mount(8):
if grep -F " \$R " /proc/self/mountinfo | grep -qE '(^| )ro(,|  )'; then
  echo "MOUNTINFO-RO=yes"
else
  echo "MOUNTINFO-RO=no"
fi
echo "WRITE-EXISTING=\$(setpriv --reuid=lawmax-producer --regid=lawmax-producer \
   --clear-groups python3 "$PROBE" "\$R/sha256-legacy/temporal-proof/timestamp.tsr")"
echo "WRITE-NEW=\$(setpriv --reuid=lawmax-producer --regid=lawmax-producer \
   --clear-groups python3 "$PROBE" "\$R/brand-new-release")"
setpriv --reuid=lawmax-producer --regid=lawmax-producer --clear-groups \
   mkdir "\$R/.staging-x" 2>/dev/null && echo "MKDIR=OK" || echo "MKDIR=REFUSED"
# ΘΕΤΙΚΟΣ ΜΑΡΤΥΡΑΣ ΜΕΣΑ ΣΤΟ ΙΔΙΟ NAMESPACE: το candidates/ ΠΑΡΑΜΕΝΕΙ εγγράψιμο
echo "CANDIDATES=\$(setpriv --reuid=lawmax-producer --regid=lawmax-producer \
   --clear-groups python3 "$PROBE" "$OUT/candidates/probe.txt")"
EOF
OUT2="$(unshare -m sh "$INNER" 2>&1)"
echo "$OUT2" | sed 's/^/       │ /'

grep -q "MOUNTINFO-RO=yes" <<<"$OUT2" \
  && ok "το /proc/self/mountinfo ΕΠΙΒΕΒΑΙΩΝΕΙ ro bind mount (όχι μόνο exit code)" \
  || { echo "::error::BLOCKED — το ro bind mount ΔΕΝ επιβεβαιώθηκε (πιθανή έλλειψη CAP_SYS_ADMIN)"; exit 2; }

check_errno(){ # $1=ετικέτα $2=κλειδί
  local v; v="$(sed -n "s/^$2=//p" <<<"$OUT2")"
  case "$v" in
    "ERRNO 30") ok "$1 ⇒ EROFS(30) — η άρνηση ΕΙΝΑΙ ΤΟΥ MOUNT, όχι δικαιωμάτων";;
    "ERRNO 13") no "$1 ⇒ EACCES(13) — η άρνηση εξηγείται από ΔΙΚΑΙΩΜΑΤΑ, ΟΧΙ από το mount";;
    "WROTE")    no "$1 ⇒ Η ΕΓΓΡΑΦΗ ΠΕΡΑΣΕ";;
    *)          no "$1 ⇒ ασαφές αποτέλεσμα: '$v'";;
  esac
}
check_errno "εγγραφή σε ΥΠΑΡΧΟΝ legacy evidence" WRITE-EXISTING
check_errno "δημιουργία ΝΕΟΥ release" WRITE-NEW
grep -q "MKDIR=REFUSED" <<<"$OUT2" && ok "mkdir .staging-x στο releases/ ⇒ ΑΡΝΗΣΗ" \
                                   || no "mkdir στο releases/ ΕΠΕΤΥΧΕ"
grep -q "CANDIDATES=WROTE" <<<"$OUT2" \
  && ok "ΘΕΤΙΚΟΣ ΜΑΡΤΥΡΑΣ: το candidates/ ΠΑΡΑΜΕΝΕΙ εγγράψιμο στο ΙΔΙΟ namespace" \
  || no "ούτε το candidates/ δεν γράφεται — ΚΕΝΟΣ ΜΑΡΤΥΡΑΣ"

AFTER="$(sha256sum "$OUT/releases/sha256-legacy/temporal-proof/timestamp.tsr" | cut -d' ' -f1)"
[ "$BEFORE" = "$AFTER" ] && ok "τα bytes του legacy evidence ΑΘΙΚΤΑ" || no "ΤΑ BYTES ΑΛΛΑΞΑΝ"

echo
echo "== ③ ΤΟ ΠΑΡΑΓΩΓΙΚΟ ENTRYPOINT ΥΠΟ PRODUCER UID, ΜΕΣΑ ΣΤΟ ΙΔΙΟ ΟΡΙΟ =="
# ΑΝΩΤΑΤΗ ΜΟΡΦΗ: το core χτίζεται ΜΙΑ φορά (ως root)· ο producer το ΦΟΡΤΩΝΕΙ σε
# ms. Η μεταγλώττιση ΔΕΝ είναι μέρος του ορίου ασφαλείας — αφαιρείται εντελώς.
CORE="$WORK/authority-cli.core"
LAWMAX_REPO="$REPO" sbcl --script "$REPO/authority-v2/tests/build-authority-core.lisp" "$CORE" >/dev/null 2>&1
[ -s "$CORE" ] || { echo "::error::BLOCKED — core δεν χτίστηκε"; exit 2; }
chmod 0644 "$CORE"

REAL="$WORK/real"
mkdir -p "$REAL/releases/sha256-aaa/temporal-proof" "$REAL/candidates"
echo "EVIDENCE" > "$REAL/releases/sha256-aaa/temporal-proof/existing.txt"
REAL_BEFORE="$(sha256sum "$REAL/releases/sha256-aaa/temporal-proof/existing.txt" | cut -d' ' -f1)"
chown -R lawmax-producer:lawmax-producer "$REAL"   # ΞΑΝΑ: καμία άμυνα από δικαιώματα
chmod 0755 "$REAL"

OUT3="$(unshare -m sh -c "
    mount --bind '$REAL/releases' '$REAL/releases' || exit 91
    mount -o remount,bind,ro '$REAL/releases'      || exit 92
    grep -F ' $REAL/releases ' /proc/self/mountinfo | grep -qE '(^| )ro(,|  )' || exit 93
    cd '$REPO'
    LAWMAX_REPO='$REPO' setpriv --reuid=lawmax-producer --regid=lawmax-producer \
      --clear-groups sbcl --core '$CORE' --script \
      '$REPO/authority-v2/tests/probe-producer-real.lisp' '$REAL/' 2>/dev/null | tail -1
" 2>/dev/null | tr -d '\r')"
case "$OUT3" in
  *"staging=IN-CANDIDATES"*) ok "ΠΡΑΓΜΑΤΙΚΗ create-staging-directory ⇒ candidates/ (producer UID)";;
  *)                         no "staging: $OUT3";;
esac
case "$OUT3" in
  *"attest=SEAT-DELETED"*) ok "η έδρα --attest-release ΔΕΝ ΥΠΑΡΧΕΙ· η ΙΔΙΑ resolve-command του main απαντά ΚΑΤΑΡΓΗΜΕΝΗ (producer UID)";;
  *)                       no "attest: $OUT3";;
esac
case "$OUT3" in
  *"direct-write=REFUSED-BY-KERNEL"*) ok "απευθείας εγγραφή στο ro releases/ ⇒ ΑΡΝΗΣΗ ΠΥΡΗΝΑ";;
  *)                                   no "direct-write: $OUT3";;
esac
REAL_AFTER="$(sha256sum "$REAL/releases/sha256-aaa/temporal-proof/existing.txt" | cut -d' ' -f1)"
[ "$REAL_BEFORE" = "$REAL_AFTER" ] && ok "το legacy evidence ΑΘΙΚΤΟ μετά την πραγματική εκτέλεση" \
                                   || no "ΤΟ LEGACY EVIDENCE ΑΛΛΟΙΩΘΗΚΕ"

echo
echo "── producer OS boundary: $p passed, $f failed ──"
[ "$f" -eq 0 ]
