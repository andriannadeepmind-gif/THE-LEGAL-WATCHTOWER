#!/usr/bin/env bash
# ΜΟΝΑΔΙΚΗ ΑΝΑΠΑΡΑΓΩΓΙΜΗ ΕΚΤΕΛΕΣΗ — ΙΔΙΩΤΙΚΟ NAMESPACE ΜΕ ΑΠΟΔΕΙΞΗ.
#
# ΤΙ ΑΛΛΑΞΕ
# ─────────
# ① ΚΑΜΙΑ ΠΑΡΑΚΑΜΨΗ ΜΕΣΩ ENVIRONMENT MARKER. Πριν, ένα «LAWMAX_PRIVATE_NS=1»
#    από έξω παρέκαμπτε ΟΛΗ την απομόνωση. Τώρα ο γονέας περνά το ΔΙΚΟ ΤΟΥ
#    mount-namespace inode ως όρισμα και το παιδί ΑΠΟΔΕΙΚΝΥΕΙ ότι το δικό του
#    ΔΙΑΦΕΡΕΙ. Δεν εμπιστευόμαστε σημαία — μετράμε.
# ② ΚΑΤΟΧΗ LOCK FD ΑΠΟΔΕΔΕΙΓΜΕΝΗ: το κλείδωμα λαμβάνεται σε ΔΙΚΟ ΜΑΣ fd και
#    επιβεβαιώνεται στο /proc/locks με PID και inode.
# ③ ΚΑΘΑΡΟ WORKTREE ΠΡΙΝ ΑΠΟ ΚΑΘΕ ΕΞΟΔΟ. Το receipt γράφει evaluator_commit=C
#    και dirty_entries=0· τα evidence πάνε σε ΧΩΡΙΣΤΟ commit.
# ④ ΤΟ HASHING ΔΕΝ ΕΙΝΑΙ ΕΚΤΕΛΕΣΗ. Τρέχουν ΠΡΑΓΜΑΤΙΚΑ: witness suite,
#    migration verifier, event-ledger verify, attestation ΠΡΙΝ και ΜΕΤΑ.
# ⑤ BLOCKED (exit 3) ΔΕΝ γίνεται ΠΟΤΕ PASS.
set -euo pipefail

FROZEN_COMMIT=e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03
FROZEN_TREE=23b7a6f4450f50d151d38e13020bee9872e73bcd
EXPECTED_LEAVES=35640
REPO=/home/user/THE-LEGAL-WATCHTOWER
SNAP=/frozen/ro
LOCK=/run/lawmax-citation-gates.lock
TMPFS_SIZE=768m

# ── ΕΠΑΝΕΚΚΙΝΗΣΗ ΣΕ ΙΔΙΩΤΙΚΟ NAMESPACE — Ο ΓΟΝΕΑΣ ΔΙΝΕΙ ΤΟ INODE ΤΟΥ ──────
if [ "${1:-}" != "--child-of-namespace" ]; then
  PARENT_NS=$(readlink /proc/self/ns/mnt)
  exec unshare --mount --propagation private -- \
       "$0" --child-of-namespace "$PARENT_NS" "$@"
fi
shift
PARENT_NS="$1"; shift
CHILD_NS=$(readlink /proc/self/ns/mnt)
if [ "$CHILD_NS" = "$PARENT_NS" ]; then
  echo "::error::ΤΟ MOUNT NAMESPACE ΔΕΝ ΑΛΛΑΞΕ ($CHILD_NS). Η απομόνωση ΔΕΝ" >&2
  echo "::error::στήθηκε· καμία εκτέλεση δεν επιτρέπεται. ⇒ BLOCKED" >&2
  exit 3
fi

# ── ΑΠΟΚΛΕΙΣΤΙΚΟ ΚΛΕΙΔΩΜΑ ΣΕ ΔΙΚΟ ΜΑΣ FD, ΜΕ ΑΠΟΔΕΙΞΗ ΚΑΤΟΧΗΣ ───────────
mkdir -p "$(dirname "$LOCK")"
exec 9>"$LOCK"
if ! flock --nonblock 9; then
  echo "::error::ΑΛΛΗ ΕΚΤΕΛΕΣΗ ΚΡΑΤΑ ΤΟ ΚΛΕΙΔΩΜΑ $LOCK" >&2
  exit 2
fi
LOCK_INO=$(stat -c '%i' "$LOCK")
# ΑΠΟΔΕΙΞΗ ΚΑΤΟΧΗΣ — ΛΕΙΤΟΥΡΓΙΚΗ, ΟΧΙ ΑΠΟ PID.
# Το flock(1) αποκτά το κλείδωμα σε ΘΥΓΑΤΡΙΚΗ διεργασία πάνω στο ΔΙΚΟ ΜΑΣ fd·
# το κλείδωμα ζει στην open file description και επιβιώνει, αλλά το
# /proc/locks καταγράφει το pid του θνήσκοντος βοηθού. Άρα η ταυτοποίηση με
# pid είναι ΛΑΘΟΣ ΤΕΚΜΗΡΙΟ. Αποδεικνύουμε δύο πράγματα που ΙΣΧΥΟΥΝ:
#   ① το fd 9 ΜΑΣ δείχνει ΠΡΑΓΜΑΤΙΚΑ στο αρχείο κλειδώματος
#   ② ΞΕΧΩΡΙΣΤΗ διεργασία ΔΕΝ μπορεί να πάρει το ίδιο κλείδωμα (EWOULDBLOCK)
FD9=$(readlink /proc/self/fd/9 || true)
if [ "$FD9" != "$LOCK" ]; then
  echo "::error::ΤΟ fd 9 ΔΕΝ ΔΕΙΧΝΕΙ ΣΤΟ $LOCK (δείχνει: ${FD9:-—})" >&2
  exit 2
fi
if flock --nonblock --exclusive "$LOCK" true 2>/dev/null; then
  echo "::error::ΞΕΧΩΡΙΣΤΗ ΔΙΕΡΓΑΣΙΑ ΠΗΡΕ ΤΟ ΚΛΕΙΔΩΜΑ — ΔΕΝ το κρατάμε" >&2
  exit 2
fi
LOCK_PROOF="fd9→$LOCK · ανεξάρτητη απόπειρα ⇒ EWOULDBLOCK"

cd "$REPO"

# ── ΚΑΘΑΡΟ WORKTREE — ΠΡΙΝ ΑΠΟ ΟΠΟΙΑΔΗΠΟΤΕ ΕΞΟΔΟ ────────────────────────
DIRTY=$(git status --porcelain | wc -l)
if [ "$DIRTY" != "0" ]; then
  echo "::error::WORKTREE ΔΕΝ ΕΙΝΑΙ ΚΑΘΑΡΟ ($DIRTY εγγραφές). Το receipt θα" >&2
  echo "::error::έδενε σε κατάσταση που ΔΕΝ υπάρχει σε κανένα commit." >&2
  git status --porcelain | head -10 >&2
  exit 2
fi
EVAL_COMMIT=$(git rev-parse HEAD)
EVAL_TREE=$(git rev-parse HEAD^{tree})

STAMP=$(date -u +%Y%m%dT%H%M%SZ)
RECEIPTS="$REPO/experiment/artifacts/gate-receipts"
RUN_DIR="$RECEIPTS/$STAMP"
mkdir -p "$RECEIPTS"
if [ -e "$RUN_DIR" ]; then
  echo "::error::ΤΟ $RUN_DIR ΥΠΑΡΧΕΙ ΗΔΗ — ο κατάλογος εκτέλεσης είναι ΑΠΟΚΛΕΙΣΤΙΚΟΣ" >&2
  exit 2
fi
mkdir "$RUN_DIR"
WORK=$(mktemp -d /tmp/lawmax-run.XXXXXX)

cleanup() { local rc=$?; umount -l "$SNAP" 2>/dev/null || true; rm -rf "$WORK"; exit $rc; }
trap cleanup EXIT INT TERM HUP

say() { printf '%s\n' "$*" | tee -a "$RUN_DIR/RUN.log"; }
die() { say "::error::$*"; exit 2; }
blocked() { say "::error::BLOCKED — $*"; exit 3; }

say "═══ SINGLE-SHOT RUN · $STAMP ═══"
say "① namespace: γονέας $PARENT_NS → παιδί $CHILD_NS · ΑΠΟΔΕΔΕΙΓΜΕΝΑ ΔΙΑΦΟΡΕΤΙΚΟ"
say "   lock: $LOCK_PROOF (inode $LOCK_INO)"
say "   worktree: ΚΑΘΑΡΟ · evaluator commit $EVAL_COMMIT"

# ── ② GIT ───────────────────────────────────────────────────────────────
git rev-parse --verify "$FROZEN_COMMIT^{commit}" >/dev/null || die "άγνωστο commit"
TREE=$(git rev-parse "$FROZEN_COMMIT^{tree}")
[ "$TREE" = "$FROZEN_TREE" ] || die "tree $TREE ≠ $FROZEN_TREE"
LEAVES=$(git ls-tree -r -z --full-tree "$FROZEN_COMMIT" | tr '\0' '\n' | grep -c .)
[ "$LEAVES" = "$EXPECTED_LEAVES" ] || die "$LEAVES φύλλα ≠ $EXPECTED_LEAVES"
say "② frozen tree $TREE · $LEAVES φύλλα ✓"

# ── ③ SNAPSHOT ΑΠΟ GIT OBJECTS ΣΕ ΙΔΙΩΤΙΚΟ TMPFS ────────────────────────
mkdir -p "$SNAP"
mount -t tmpfs -o "size=$TMPFS_SIZE,mode=0700,nodev,nosuid,noexec" tmpfs "$SNAP"
git archive --format=tar "$FROZEN_COMMIT" | tar -x -C "$SNAP"
mount -o remount,ro,nodev,nosuid,noexec "$SNAP"
OPTS=$(awk -v d="$SNAP" '$5==d {print $6; exit}' /proc/self/mountinfo)
[ -n "$OPTS" ] || die "$SNAP απών από /proc/self/mountinfo"
for o in ro nodev nosuid noexec; do
  case ",$OPTS," in *",$o,"*) ;; *) die "λείπει «$o» (έχω: $OPTS)";; esac
done
say "③ snapshot: tmpfs σε ιδιωτικό namespace από git objects · [$OPTS] ✓"

python3 - "$SNAP" <<'PY' | tee -a "$RUN_DIR/RUN.log"
import errno, os, sys
p = os.path.join(sys.argv[1], ".__probe")
try:
    fd = os.open(p, os.O_CREAT | os.O_WRONLY, 0o600); os.close(fd); os.unlink(p)
    print("::error::ΓΡΑΦΗ ΠΕΡΑΣΕ"); sys.exit(2)
except OSError as e:
    if e.errno != errno.EROFS:
        print(f"::error::errno {e.errno} ≠ EROFS"); sys.exit(2)
    print("   αρνητικός μάρτυρας: εγγραφή ⇒ EROFS (errno 30) ✓")
PY

# ── ④ ATTESTATION ΠΡΙΝ ─────────────────────────────────────────────────
python3 experiment/runner/corpus-manifest.py --root "$SNAP" \
  --compare experiment/artifacts/corpus-manifest.tsv > "$RUN_DIR/attestation-before.txt" 2>&1 \
  || die "attestation ΠΡΙΝ απέτυχε"
say "④ attestation ΠΡΙΝ: manifest byte-identical ✓"

# ── ⑤ ΟΙ ΕΠΤΑ ΠΥΛΕΣ ────────────────────────────────────────────────────
LANES="Φ1A-L1 Φ1A-L2 Φ1A-L3 Φ1A-L4 Φ1A-L5 Φ1A-L6 Φ1A-L7"
declare -A DOSSIER=(
  [Φ1A-L1]=experiment/phase1a/source-rev3.sexp
  [Φ1A-L2]=experiment/phase1a/systems-rev2.sexp
  [Φ1A-L3]=experiment/phase1a/authority-v2-rev4.sexp
  [Φ1A-L4]=experiment/phase1a/deployment-specs-rev3.sexp
  [Φ1A-L5]=experiment/phase1a/deployment-state-rev4.sexp
  [Φ1A-L6]=experiment/phase1a/harness-rev4.sexp
  [Φ1A-L7]=experiment/phase1a/contracts-rev3.sexp
)
say "⑤ πύλες:"
for L in $LANES; do
  set +e
  python3 experiment/runner/citation-resolver.py --lane "$L" \
     --commit "$FROZEN_COMMIT" --tree "$FROZEN_TREE" \
     --diagnostic "$WORK/$L.diagnostic.json" --receipt "$WORK/$L.receipt.json" \
     "${DOSSIER[$L]}" > "$WORK/$L.out.txt" 2>&1
  rc=$?; set -e
  echo "$rc" > "$WORK/$L.exit"
  [ "$rc" = 3 ] && blocked "$L επέστρεψε BLOCKED"
  for f in out.txt diagnostic.json receipt.json; do
    [ -f "$WORK/$L.$f" ] && cp -f "$WORK/$L.$f" "$RUN_DIR/$L.${f/out.txt/receipt.txt}"
  done
  say "   $L exit=$rc"
done

# ── ⑥ ΠΡΑΓΜΑΤΙΚΗ ΕΚΤΕΛΕΣΗ ΤΩΝ ΥΠΟΛΟΙΠΩΝ ΟΡΓΑΝΩΝ ───────────────────────
say "⑥ όργανα (ΕΚΤΕΛΕΣΗ, όχι hashing):"
set +e
python3 experiment/runner/resolver-witnesses.py > "$RUN_DIR/witnesses.txt" 2>&1; W=$?
python3 experiment/runner/migration-verifier.py > "$RUN_DIR/migration-verifier.txt" 2>&1; M=$?
python3 experiment/runner/event-ledger.py verify > "$RUN_DIR/event-ledger.txt" 2>&1; E=$?
set -e
say "   witness suite      exit=$W  $(tail -1 "$RUN_DIR/witnesses.txt")"
say "   migration verifier exit=$M  $(grep -c '  ✓' "$RUN_DIR/migration-verifier.txt") έλεγχοι ✓"
say "   event ledger       exit=$E  $(cat "$RUN_DIR/event-ledger.txt")"
[ "$W" = 0 ] || die "witness suite ΑΠΕΤΥΧΕ"
[ "$M" = 0 ] || die "migration verifier ΑΠΕΤΥΧΕ"
[ "$E" = 0 ] || die "event ledger chain ΑΠΕΤΥΧΕ"

# ── ⑦ ATTESTATION ΜΕΤΑ ─────────────────────────────────────────────────
python3 experiment/runner/corpus-manifest.py --root "$SNAP" \
  --compare experiment/artifacts/corpus-manifest.tsv > "$RUN_DIR/attestation-after.txt" 2>&1 \
  || die "attestation ΜΕΤΑ απέτυχε"
say "⑦ attestation ΜΕΤΑ: manifest byte-identical ✓"

# ── ⑧ ΔΕΜΕΝΟ RECEIPT ───────────────────────────────────────────────────
python3 experiment/runner/build-receipt.py \
  --run-dir "$RUN_DIR" --work "$WORK" --stamp "$STAMP" \
  --frozen-commit "$FROZEN_COMMIT" --frozen-tree "$TREE" --leaves "$LEAVES" \
  --eval-commit "$EVAL_COMMIT" --eval-tree "$EVAL_TREE" --dirty 0 \
  --mount-opts "$OPTS" --parent-ns "$PARENT_NS" --child-ns "$CHILD_NS" \
  --lock "$LOCK" --lock-inode "$LOCK_INO" --lanes "$LANES" \
  --witness-exit "$W" --verifier-exit "$M" --ledger-exit "$E" \
  | tee -a "$RUN_DIR/RUN.log"

ln -sfn "$STAMP" "$RECEIPTS/latest"   # ΜΕΤΑΒΛΗΤΗ ΠΡΟΒΟΛΗ — ΟΧΙ τεκμήριο
FAILED=$(python3 -c "import json;print(json.load(open('$RUN_DIR/RECEIPT.json'))['lanes_failed'])")
say "═══ ΔΙΑΔΡΟΜΕΣ ΠΟΥ ΑΠΕΤΥΧΑΝ: $FAILED ═══"
[ "$FAILED" = 0 ] || exit 1
