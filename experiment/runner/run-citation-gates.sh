#!/usr/bin/env bash
# ΜΟΝΑΔΙΚΗ ΑΝΑΠΑΡΑΓΩΓΙΜΗ ΕΚΤΕΛΕΣΗ ΠΥΛΩΝ — ΙΔΙΩΤΙΚΟ MOUNT NAMESPACE.
#
# ΤΙ ΑΛΛΑΞΕ ΚΑΙ ΓΙΑΤΙ
# ───────────────────
# ① ΓΝΗΣΙΟ ΑΜΕΤΑΒΛΗΤΟ SNAPSHOT, ΟΧΙ ΣΥΓΚΡΙΣΗ ΔΥΟ ΑΚΡΩΝ.
#    Η προηγούμενη κατασκευή έκανε read-only bind πάνω στο ΕΓΓΡΑΨΙΜΟ
#    /frozen/watchtower και «αποδείκνυε» ακινησία συγκρίνοντας αποτύπωμα πριν
#    και μετά. Αυτό αποδεικνύει ΙΣΟΔΥΝΑΜΙΑ ΑΚΡΩΝ, όχι ακινησία: μια μεταβολή
#    και επαναφορά στο ενδιάμεσο θα περνούσε.
#    Τώρα το snapshot υλοποιείται σε tmpfs ΜΕΣΑ σε ιδιωτικό mount namespace,
#    γεμίζει από ΤΑ ΙΔΙΑ ΤΑ GIT OBJECTS (content-addressed), επαληθεύεται ανά
#    διαδρομή και μετά γίνεται read-only. Καμία διεργασία εκτός του namespace
#    ΔΕΝ ΜΠΟΡΕΙ να το φτάσει — δεν υπάρχει διαδρομή προς αυτό.
# ② FLOCK: αποκλείει παράλληλες εκτελέσεις που θα μοιράζονταν διαδρομές.
# ③ TRAP: ανεξαίρετο umount· και το ίδιο το namespace πεθαίνει με τη διεργασία.
# ④ EROFS ΑΚΡΙΒΩΣ: δεν αρκεί «απέτυχε η εγγραφή» — απαιτείται errno EROFS.
# ⑤ ΚΑΜΙΑ ΕΤΥΜΗΓΟΡΙΑ ΜΕ grep: κάθε πύλη γράφει JSON receipt· το συγκεντρωτικό
#    συντίθεται από αυτά, με τα ΠΡΑΓΜΑΤΙΚΑ exit codes.
set -euo pipefail

FROZEN_COMMIT=e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03
FROZEN_TREE=23b7a6f4450f50d151d38e13020bee9872e73bcd
EXPECTED_LEAVES=35640
REPO=/home/user/THE-LEGAL-WATCHTOWER
SNAP=/frozen/ro
LOCK=/run/lawmax-citation-gates.lock
TMPFS_SIZE=768m

# ── ΑΥΤΟ-ΕΠΑΝΕΚΚΙΝΗΣΗ ΣΕ ΙΔΙΩΤΙΚΟ NAMESPACE, ΥΠΟ ΑΠΟΚΛΕΙΣΤΙΚΟ ΚΛΕΙΔΩΜΑ ──
if [ "${LAWMAX_PRIVATE_NS:-}" != "1" ]; then
  mkdir -p "$(dirname "$LOCK")"
  exec flock --nonblock "$LOCK" \
       unshare --mount --propagation private \
       env LAWMAX_PRIVATE_NS=1 "$0" "$@"
fi

cd "$REPO"
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
RECEIPTS="$REPO/experiment/artifacts/gate-receipts"
RUN_DIR="$RECEIPTS/$STAMP"
WORK=$(mktemp -d /tmp/lawmax-run.XXXXXX)
mkdir -p "$RUN_DIR"

cleanup() {
  local rc=$?
  umount -l "$SNAP" 2>/dev/null || true
  rm -rf "$WORK"
  exit $rc
}
trap cleanup EXIT INT TERM HUP

say() { printf '%s\n' "$*" | tee -a "$RUN_DIR/RUN.log"; }
die() { say "::error::$*"; exit 2; }

say "═══ SINGLE-SHOT CITATION GATE RUN · $STAMP ═══"
say "namespace: ΙΔΙΩΤΙΚΟ (unshare --mount --propagation private) · lock $LOCK"
say "FROZEN_COMMIT=$FROZEN_COMMIT  (ΠΟΤΕ HEAD)"

# ── ① GIT ────────────────────────────────────────────────────────────────
git rev-parse --verify "$FROZEN_COMMIT^{commit}" >/dev/null || die "άγνωστο commit"
TREE=$(git rev-parse "$FROZEN_COMMIT^{tree}")
[ "$TREE" = "$FROZEN_TREE" ] || die "tree $TREE ≠ $FROZEN_TREE"
LEAVES=$(git ls-tree -r -z --full-tree "$FROZEN_COMMIT" | tr '\0' '\n' | grep -c .)
[ "$LEAVES" = "$EXPECTED_LEAVES" ] || die "$LEAVES φύλλα ≠ $EXPECTED_LEAVES"
EVAL_COMMIT=$(git rev-parse HEAD)
EVAL_TREE=$(git rev-parse HEAD^{tree})
WORKTREE_DIRTY=$(git status --porcelain | wc -l)
say "① git: frozen tree $TREE · $LEAVES φύλλα ✓"
say "   evaluator: commit $EVAL_COMMIT · tree $EVAL_TREE · dirty entries $WORKTREE_DIRTY"

# ── ② SNAPSHOT ΑΠΟ GIT OBJECTS ΣΕ ΙΔΙΩΤΙΚΟ TMPFS ─────────────────────────
mkdir -p "$SNAP"
mount -t tmpfs -o "size=$TMPFS_SIZE,mode=0700,nodev,nosuid,noexec" tmpfs "$SNAP"
git archive --format=tar "$FROZEN_COMMIT" | tar -x -C "$SNAP"
say "② snapshot: tmpfs ΜΕΣΑ στο ιδιωτικό namespace, γεμισμένο από git objects"

mount -o remount,ro,nodev,nosuid,noexec "$SNAP"
OPTS=$(awk -v d="$SNAP" '$5==d {print $6; exit}' /proc/self/mountinfo)
[ -n "$OPTS" ] || die "$SNAP δεν εμφανίζεται στο /proc/self/mountinfo"
for o in ro nodev nosuid noexec; do
  case ",$OPTS," in *",$o,"*) ;; *) die "λείπει «$o» (έχω: $OPTS)";; esac
done
say "   επιλογές: $OPTS ✓"

# ── ③ ΑΡΝΗΤΙΚΟΣ ΜΑΡΤΥΡΑΣ: ΑΚΡΙΒΩΣ EROFS ─────────────────────────────────
python3 - "$SNAP" <<'PY' | tee -a "$RUN_DIR/RUN.log"
import errno, os, sys
p = os.path.join(sys.argv[1], ".__probe")
try:
    fd = os.open(p, os.O_CREAT | os.O_WRONLY, 0o600)
    os.close(fd); os.unlink(p)
    print("::error::ΓΡΑΦΗ ΠΕΡΑΣΕ — ΔΕΝ είναι read-only"); sys.exit(2)
except OSError as e:
    if e.errno != errno.EROFS:
        print(f"::error::εγγραφή απέτυχε με errno {e.errno} "
              f"({errno.errorcode.get(e.errno)}) — απαιτείται ΑΚΡΙΒΩΣ EROFS")
        sys.exit(2)
    print("③ αρνητικός μάρτυρας: εγγραφή ⇒ EROFS (errno 30) ✓")
PY

# ── ④ MANIFEST: RUN-LOCAL, ΣΥΓΚΡΙΣΗ BYTE-FOR-BYTE ΜΕ ΤΟ ΣΦΡΑΓΙΣΜΕΝΟ ─────
SEALED=experiment/artifacts/corpus-manifest.tsv
python3 experiment/runner/corpus-manifest.py --root "$SNAP" --out "$WORK/manifest.tsv" \
  | tee -a "$RUN_DIR/RUN.log"
python3 experiment/runner/corpus-manifest.py --root "$SNAP" --compare "$SEALED" \
  | tee -a "$RUN_DIR/RUN.log"
say "④ manifest: run-local ΤΑΥΤΟΣΗΜΟ με το σφραγισμένο ✓"

# ── ⑤ ΟΙ ΕΠΤΑ ΠΥΛΕΣ ─────────────────────────────────────────────────────
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
  f="${DOSSIER[$L]}"
  set +e
  python3 experiment/runner/citation-resolver.py --lane "$L" \
     --commit "$FROZEN_COMMIT" --tree "$FROZEN_TREE" \
     --diagnostic "$WORK/$L.diagnostic.json" \
     --receipt "$WORK/$L.receipt.json" \
     "$f" > "$WORK/$L.out.txt" 2>&1
  rc=$?
  set -e
  echo "$rc" > "$WORK/$L.exit"
  cp -f "$WORK/$L.out.txt" "$RUN_DIR/.$L.out.tmp"; mv -f "$RUN_DIR/.$L.out.tmp" "$RUN_DIR/$L.receipt.txt"
  [ -f "$WORK/$L.diagnostic.json" ] && { cp -f "$WORK/$L.diagnostic.json" "$RUN_DIR/.$L.d.tmp"; mv -f "$RUN_DIR/.$L.d.tmp" "$RUN_DIR/$L.diagnostic.json"; }
  [ -f "$WORK/$L.receipt.json" ] && { cp -f "$WORK/$L.receipt.json" "$RUN_DIR/.$L.r.tmp"; mv -f "$RUN_DIR/.$L.r.tmp" "$RUN_DIR/$L.receipt.json"; }
  say "   $L exit=$rc  $(python3 -c "
import json,sys
try:
    d=json.load(open('$WORK/$L.receipt.json'))
    print(f\"παραπομπές {d['citations']} · λύθηκαν {d['resolved']} · προβλήματα {d['problems']}\")
except Exception: print('(χωρίς receipt)')")"
done

# ── ⑥ ΕΠΑΝΑΛΗΨΗ ΤΑΥΤΟΤΗΤΑΣ SNAPSHOT ΜΕΤΑ ΤΙΣ ΠΥΛΕΣ ──────────────────────
python3 experiment/runner/corpus-manifest.py --root "$SNAP" --compare "$SEALED" \
  > "$RUN_DIR/attestation-after.txt" 2>&1 || die "attestation ΜΕΤΑ απέτυχε"
say "⑥ attestation ΜΕΤΑ τις πύλες: snapshot ΤΑΥΤΟΣΗΜΟ ✓"

# ── ⑦ ΣΥΓΚΕΝΤΡΩΤΙΚΟ RECEIPT — ΧΩΡΙΣ grep, ΜΕ ATOMIC WRITE + fsync ────────
python3 - "$RUN_DIR" "$WORK" "$STAMP" "$FROZEN_COMMIT" "$TREE" "$LEAVES" \
         "$EVAL_COMMIT" "$EVAL_TREE" "$WORKTREE_DIRTY" "$OPTS" "$LANES" <<'PY'
import hashlib, json, os, sys
run_dir, work, stamp, commit, tree, leaves, ec, et, dirty, opts, lanes = sys.argv[1:12]
REPO = "/home/user/THE-LEGAL-WATCHTOWER"

def h(p):
    return "sha256:" + hashlib.sha256(open(os.path.join(REPO, p), "rb").read()).hexdigest()

results, failed = [], 0
for L in lanes.split():
    rc = int(open(f"{work}/{L}.exit").read().strip())
    r = json.load(open(f"{work}/{L}.receipt.json"))
    if rc != 0:
        failed += 1
    if rc != r["exit_code"]:
        print(f"::error::{L}: exit shell {rc} ≠ receipt {r['exit_code']}")
        sys.exit(2)
    results.append({"lane": L, "exit_code": rc, **r})

receipt = {
 "kind": "lawmax-gate-run/2", "timestamp_utc": stamp,
 "isolation": {"mount_namespace": "private (unshare --mount --propagation private)",
               "exclusive_lock": "/run/lawmax-citation-gates.lock (flock --nonblock)",
               "snapshot": "tmpfs ΜΕΣΑ στο ιδιωτικό namespace, από git objects",
               "snapshot_reachable_from_outside": False,
               "mount_options": opts,
               "write_probe": "EROFS (errno 30) — ΑΚΡΙΒΗΣ έλεγχος",
               "unmount": "trap EXIT INT TERM HUP + θάνατος namespace"},
 "frozen": {"commit": commit, "tree": tree, "git_leaves": int(leaves)},
 "evaluator": {"commit": ec, "tree": et, "worktree_dirty_entries": int(dirty)},
 "construction": {
    "runner": h("experiment/runner/run-citation-gates.sh"),
    "resolver": h("experiment/runner/citation-resolver.py"),
    "manifest_generator": h("experiment/runner/corpus-manifest.py"),
    "frozen_access": h("experiment/runner/frozen_access.py"),
    "canonicalizer": h("experiment/runner/canonicalize-citations.py"),
    "migration_verifier": h("experiment/runner/migration-verifier.py"),
    "witnesses": h("experiment/runner/resolver-witnesses.py"),
    "protocol_epoch_2": h("experiment/PROTOCOL-EPOCH-2.sexp"),
    "scope_authority": h("experiment/phase1a/LANE-SCOPE-AUTHORITY.sexp"),
    "manifest_tsv": h("experiment/artifacts/corpus-manifest.tsv"),
    "canonicalization_map": h("experiment/artifacts/l1-admission-forensics/CANONICALIZATION-MAP.json"),
 },
 "lanes_failed": failed, "results": results,
 "verdict_scope": {
   "proves": "RECOGNIZED-CITATION-INTEGRITY — τα ΑΝΑΓΝΩΡΙΣΜΕΝΑ tokens δείχνουν "
             "σε πραγματικά bytes και εύρη",
   "does_not_prove": ["CLAIM-CITATION-COVERAGE", "CLAIM-ENTAILMENT", "read-ledger"]},
}
for L in lanes.split():
    for suf in ("receipt.txt", "diagnostic.json", "receipt.json"):
        p = f"{run_dir}/{L}.{suf}"
        if os.path.exists(p):
            receipt.setdefault("artifact_hashes", {})[f"{L}.{suf}"] = \
                "sha256:" + hashlib.sha256(open(p, "rb").read()).hexdigest()

tmp = f"{run_dir}/.RECEIPT.json.tmp"
with open(tmp, "w", encoding="utf-8") as fh:
    json.dump(receipt, fh, ensure_ascii=False, indent=1)
    fh.flush(); os.fsync(fh.fileno())
os.rename(tmp, f"{run_dir}/RECEIPT.json")
d = os.open(run_dir, os.O_RDONLY | os.O_DIRECTORY); os.fsync(d); os.close(d)
print(f"⑦ receipt: {os.path.relpath(run_dir, REPO)}/RECEIPT.json · "
      f"διαδρομές που απέτυχαν: {failed}")
sys.exit(0)
PY

ln -sfn "$STAMP" "$RECEIPTS/latest"
FAILED=$(python3 -c "import json;print(json.load(open('$RUN_DIR/RECEIPT.json'))['lanes_failed'])")
say "═══ ΔΙΑΔΡΟΜΕΣ ΠΟΥ ΑΠΕΤΥΧΑΝ: $FAILED ═══"
[ "$FAILED" = 0 ] || exit 1
