#!/usr/bin/env bash
# ΜΟΝΑΔΙΚΗ ΑΝΑΠΑΡΑΓΩΓΙΜΗ ΕΚΤΕΛΕΣΗ ΠΥΛΩΝ — ΜΙΑ ΚΛΗΣΗ, ΕΝΑ MOUNT NAMESPACE.
#
# ΓΙΑΤΙ ΕΝΑ SCRIPT ΚΑΙ ΟΧΙ ΑΛΛΗΛΟΥΧΙΑ ΕΝΤΟΛΩΝ: σε αυτό το περιβάλλον τα mounts
# ΔΕΝ επιβιώνουν μεταξύ κλήσεων. Πύλη που στήνεται σε άλλη κλήση από αυτήν που
# κρίνει είναι πύλη χωρίς πηγή. Εδώ mount, επαλήθευση, απογραφή, κρίση και
# unmount συμβαίνουν στην ΙΔΙΑ εκτέλεση.
#
# ΤΟ ΠΑΓΩΜΕΝΟ ΣΗΜΕΙΟ ΕΙΝΑΙ ΡΗΤΟ. ΠΟΤΕ HEAD.
set -euo pipefail

FROZEN_COMMIT=e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03
FROZEN_TREE=23b7a6f4450f50d151d38e13020bee9872e73bcd
EXPECTED_LEAVES=35640
REPO=/home/user/THE-LEGAL-WATCHTOWER
SRC=/frozen/watchtower
DST=/frozen/ro
RECEIPTS="$REPO/experiment/artifacts/gate-receipts"
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
RUN_DIR="$RECEIPTS/$STAMP"

cd "$REPO"
mkdir -p "$RUN_DIR"

MOUNTED_BY_US=0
cleanup() {
  local rc=$?
  if [ "$MOUNTED_BY_US" = 1 ]; then umount "$DST" 2>/dev/null || true; fi
  exit $rc
}
trap cleanup EXIT INT TERM

say() { printf '%s\n' "$*" | tee -a "$RUN_DIR/RUN.log"; }
die() { say "::error::$*"; exit 2; }

say "═══ SINGLE-SHOT CITATION GATE RUN · $STAMP ═══"
say "FROZEN_COMMIT=$FROZEN_COMMIT  (ΠΟΤΕ HEAD)"

# ── ① GIT: commit, tree, πλήθος φύλλων ────────────────────────────────────
git rev-parse --verify "$FROZEN_COMMIT^{commit}" >/dev/null || die "άγνωστο commit"
TREE=$(git rev-parse "$FROZEN_COMMIT^{tree}")
[ "$TREE" = "$FROZEN_TREE" ] || die "tree $TREE ≠ αναμενόμενο $FROZEN_TREE"
LEAVES=$(git ls-tree -r -z --full-tree "$FROZEN_COMMIT" | tr '\0' '\n' | grep -c .)
[ "$LEAVES" = "$EXPECTED_LEAVES" ] || die "$LEAVES φύλλα ≠ $EXPECTED_LEAVES"
say "① git: tree $TREE · $LEAVES φύλλα ✓"

# ── ② ΑΠΟΤΥΠΩΜΑ ΠΗΓΗΣ *ΠΡΙΝ* ──────────────────────────────────────────────
# Το read-only bind ΔΕΝ ακινητοποιεί τη writable πηγή. Το μόνο που αποδεικνύει
# ακινησία είναι ΤΑΥΤΟΣΗΜΟ αποτύπωμα πριν και μετά.
src_receipt() {
  ( cd "$SRC" && find . \( -type f -o -type l \) -printf '%y %m %s %p\n' \
    | LC_ALL=C sort | sha256sum | cut -d' ' -f1 )
}
BEFORE=$(src_receipt)
say "② αποτύπωμα πηγής ΠΡΙΝ: $BEFORE"

# ── ③ MOUNT: ro,nodev,nosuid,noexec ───────────────────────────────────────
# ΕΠΙΒΑΛΛΟΥΜΕ, ΔΕΝ ΥΠΟΘΕΤΟΥΜΕ. Ένα προϋπάρχον mount μπορεί να στήθηκε από
# άλλη διαδρομή με ΑΣΘΕΝΕΣΤΕΡΕΣ σημαίες· το remount εφαρμόζεται ΠΑΝΤΑ.
mkdir -p "$DST"
if ! awk -v d="$DST" '$5==d {found=1} END {exit !found}' /proc/self/mountinfo; then
  mount --bind "$SRC" "$DST"
  MOUNTED_BY_US=1
fi
mount -o remount,bind,ro,nodev,nosuid,noexec "$DST"
OPTS=$(awk -v d="$DST" '$5==d {print $6; exit}' /proc/self/mountinfo)
[ -n "$OPTS" ] || die "$DST δεν εμφανίζεται στο /proc/self/mountinfo"
for o in ro nodev nosuid noexec; do
  case ",$OPTS," in *",$o,"*) ;; *) die "λείπει η επιλογή «$o» (έχω: $OPTS)";; esac
done
say "③ mount: $DST [$OPTS] ✓"
if touch "$DST/.__probe" 2>/dev/null; then rm -f "$DST/.__probe"; die "ΓΡΑΦΗ ΠΕΡΑΣΕ"; fi
say "   αρνητικός μάρτυρας: γραφή ⇒ EROFS ✓"

# ── ④ MANIFEST v3 ΑΠΟ GIT OBJECTS + per-path attestation ──────────────────
python3 experiment/runner/corpus-manifest.py | tee -a "$RUN_DIR/RUN.log"
MAN_SHA=$(sha256sum experiment/artifacts/corpus-manifest.tsv | cut -d' ' -f1)
say "④ manifest v3 sha256:$MAN_SHA"

# ── ⑤ ΚΑΙ ΟΙ ΕΠΤΑ ΠΥΛΕΣ, ΣΤΟ ΙΔΙΟ NAMESPACE ───────────────────────────────
declare -A DOSSIER=(
  [Φ1A-L1]=experiment/phase1a/source-rev3.sexp
  [Φ1A-L2]=experiment/phase1a/systems-rev2.sexp
  [Φ1A-L3]=experiment/phase1a/authority-v2-rev2.sexp
  [Φ1A-L4]=experiment/phase1a/deployment-specs-rev2.sexp
  [Φ1A-L5]=experiment/phase1a/deployment-state-rev2.sexp
  [Φ1A-L6]=experiment/phase1a/harness-rev2.sexp
  [Φ1A-L7]=experiment/phase1a/contracts-rev2.sexp
)
FAILED=0
say "⑤ πύλες:"
for L in Φ1A-L1 Φ1A-L2 Φ1A-L3 Φ1A-L4 Φ1A-L5 Φ1A-L6 Φ1A-L7; do
  f="${DOSSIER[$L]}"
  tmp="$RUN_DIR/.$L.tmp"
  set +e
  python3 experiment/runner/citation-resolver.py --lane "$L" \
     --diagnostic "$RUN_DIR/$L.diagnostic.json" "$f" > "$tmp" 2>&1
  rc=$?
  set -e
  mv -f "$tmp" "$RUN_DIR/$L.receipt.txt"       # ATOMIC: rename, όχι εγγραφή επί τόπου
  line=$(grep '^παραπομπές' "$RUN_DIR/$L.receipt.txt" || echo "—")
  say "   $L exit=$rc  $line"
  [ "$rc" = 0 ] || FAILED=$((FAILED+1))
done

# ── ⑥ ΠΛΗΡΗΣ ΑΤΤΕSTATION *ΜΕΤΑ* ΤΙΣ ΠΥΛΕΣ ────────────────────────────────
python3 experiment/runner/corpus-manifest.py > "$RUN_DIR/attestation-after.txt" 2>&1
MAN_SHA2=$(sha256sum experiment/artifacts/corpus-manifest.tsv | cut -d' ' -f1)
[ "$MAN_SHA" = "$MAN_SHA2" ] || die "το manifest ΑΛΛΑΞΕ κατά τη διάρκεια των πυλών"
say "⑥ attestation ΜΕΤΑ: manifest αμετάβλητο ✓"

# ── ⑦ ΑΠΟΤΥΠΩΜΑ ΠΗΓΗΣ *ΜΕΤΑ* — ΤΑΥΤΟΣΗΜΟ Ή ΑΠΟΤΥΧΙΑ ─────────────────────
AFTER=$(src_receipt)
[ "$BEFORE" = "$AFTER" ] || die "Η ΠΗΓΗ $SRC ΜΕΤΑΒΛΗΘΗΚΕ: $BEFORE → $AFTER"
say "⑦ αποτύπωμα πηγής ΜΕΤΑ: $AFTER — ΤΑΥΤΟΣΗΜΟ ✓"

# ── ⑧ ATOMIC ΣΥΓΚΕΝΤΡΩΤΙΚΟ RECEIPT ───────────────────────────────────────
{
  echo "(:lawmax-gate-run/1"
  echo " :timestamp-utc \"$STAMP\""
  echo " :frozen-commit \"$FROZEN_COMMIT\""
  echo " :frozen-tree \"$TREE\""
  echo " :git-leaves $LEAVES"
  echo " :source-fingerprint-before \"sha256:$BEFORE\""
  echo " :source-fingerprint-after  \"sha256:$AFTER\""
  echo " :source-immobile t"
  echo " :mount-options \"$OPTS\""
  echo " :manifest-sha256 \"sha256:$MAN_SHA\""
  echo " :resolver-sha256 \"sha256:$(sha256sum experiment/runner/citation-resolver.py | cut -d' ' -f1)\""
  echo " :scope-authority-sha256 \"sha256:$(sha256sum experiment/phase1a/LANE-SCOPE-AUTHORITY.sexp | cut -d' ' -f1)\""
  echo " :lanes-failed $FAILED"
  echo " :results ("
  for L in Φ1A-L1 Φ1A-L2 Φ1A-L3 Φ1A-L4 Φ1A-L5 Φ1A-L6 Φ1A-L7; do
    f="${DOSSIER[$L]}"
    n=$(grep '^παραπομπές' "$RUN_DIR/$L.receipt.txt" | grep -oE '[0-9]+' | tr '\n' ' ')
    set -- $n
    echo "  (:lane \"$L\" :dossier \"$f\""
    echo "   :dossier-sha256 \"sha256:$(sha256sum "$f" | cut -d' ' -f1)\""
    echo "   :citations ${1:-0} :resolved ${2:-0} :problems ${3:-0}"
    echo "   :verdict $(grep -q '^VERDICT' "$RUN_DIR/$L.receipt.txt" && echo ':RECOGNIZED-CITATION-INTEGRITY' || echo ':FAIL'))"
  done
  echo " ))"
} > "$RUN_DIR/.RECEIPT.tmp"
mv -f "$RUN_DIR/.RECEIPT.tmp" "$RUN_DIR/RECEIPT.sexp"
ln -sfn "$STAMP" "$RECEIPTS/latest"

say "⑧ receipt: experiment/artifacts/gate-receipts/$STAMP/RECEIPT.sexp"
say "═══ ΔΙΑΔΡΟΜΕΣ ΠΟΥ ΑΠΕΤΥΧΑΝ: $FAILED ═══"
[ "$FAILED" = 0 ] || exit 1
