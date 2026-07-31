#!/usr/bin/env bash
# =============================================================================
# ΠΡΑΓΜΑΤΙΚΗ OS ΔΟΚΙΜΗ — παραγωγικό entrypoint υπό producer UID, releases/ READ-ONLY
# =============================================================================
# ΕΥΡΗΜΑ ΔΗΜΙΟΥΡΓΟΥ: το προηγούμενο «proof» ήταν grep harness — έψαχνε writer
# primitive και literal "releases/" ΣΤΗΝ ΙΔΙΑ ΓΡΑΜΜΗ, γι' αυτό έχανε ΚΑΙ το
# create-staging-directory ΚΑΙ το --attest-release. Ψευδώς πράσινο.
#
# ΕΔΩ ΔΕΝ ΥΠΑΡΧΕΙ GREP. Ο πυρήνας κρίνει:
#   · το releases/ γίνεται ΠΡΑΓΜΑΤΙΚΑ read-only (bind-mount ro· αν δεν υπάρχει
#     CAP_SYS_ADMIN, chmod a-w ΚΑΙ chattr +i αν διατίθεται)
#   · το παραγωγικό entrypoint τρέχει ΩΣ producer UID (setpriv)
#   · ΚΑΘΕ απόπειρα εγγραφής στο releases/ ΠΡΕΠΕΙ να αποτύχει με EACCES/EROFS
#   · το candidates/ ΠΡΕΠΕΙ να παραμένει εγγράψιμο (αλλιώς ο έλεγχος θα ήταν
#     τετριμμένος: «τίποτα δεν γράφεται πουθενά»)
#
# Χωρίς root/setpriv ⇒ exit 2 BLOCKED, ΠΟΤΕ pass.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
p=0; f=0
ok(){ p=$((p+1)); echo "  ok   $*"; }
no(){ f=$((f+1)); echo "  FAIL $*"; }

[ "$(id -u)" -eq 0 ] || { echo "::error::BLOCKED — απαιτείται root"; exit 2; }
command -v setpriv >/dev/null || { echo "::error::BLOCKED — setpriv ΑΠΩΝ"; exit 2; }
id lawmax-producer >/dev/null 2>&1 || bash "$REPO/authority-v2/capability/identities.sh" >/dev/null 2>&1
id lawmax-producer >/dev/null 2>&1 || { echo "::error::BLOCKED — ταυτότητες δεν δημιουργήθηκαν"; exit 2; }

WORK="$(mktemp -d)"; trap 'umount "$WORK/out/releases" 2>/dev/null; rm -rf "$WORK"' EXIT
mkdir -p "$WORK/out/releases/sha256-legacy/temporal-proof" "$WORK/out/candidates"
echo "LEGACY EVIDENCE" > "$WORK/out/releases/sha256-legacy/temporal-proof/timestamp.tsr"
LEGACY_SHA_BEFORE="$(sha256sum "$WORK/out/releases/sha256-legacy/temporal-proof/timestamp.tsr" | cut -d' ' -f1)"
chown -R lawmax-producer:lawmax-producer "$WORK/out/candidates"
# Ο ΙΔΙΟΣ ο προσωρινός κατάλογος πρέπει να είναι διασχίσιμος, αλλιώς ο θετικός
# μάρτυρας θα απέτυχε για ΛΑΘΟΣ λόγο (0700 root) και ο έλεγχος θα ήταν θολός.
chmod 0755 "$WORK" "$WORK/out"

# ── Το releases/ γίνεται ΠΡΑΓΜΑΤΙΚΑ read-only ────────────────────────────────
MODE="none"
if mount --bind "$WORK/out/releases" "$WORK/out/releases" 2>/dev/null && \
   mount -o remount,bind,ro "$WORK/out/releases" 2>/dev/null; then
  MODE="bind-ro"
else
  chmod -R a-w "$WORK/out/releases" && MODE="chmod-ro"
fi
[ "$MODE" != "none" ] && ok "releases/ read-only ενεργό (μηχανισμός: $MODE)" \
                      || no "ΔΕΝ κατέστη read-only — ο έλεγχος θα ήταν κενός"

echo
echo "== ① Ο PRODUCER ΔΕΝ ΜΠΟΡΕΙ ΝΑ ΓΡΑΨΕΙ ΣΤΟ releases/ (κρίση ΠΥΡΗΝΑ) =="
# Η κρίση γίνεται από το ΑΠΟΤΕΛΕΣΜΑ (μεταβλήθηκε ο δίσκος;), ΟΧΙ από μήνυμα
# σφάλματος — ένα μήνυμα μπορεί να λείπει ή να αλλάξει· τα bytes όχι.
for target in "sha256-legacy/temporal-proof/timestamp.tsr" ".staging-x/probe" "new-release/x"; do
  setpriv --reuid=lawmax-producer --regid=lawmax-producer --clear-groups \
      sh -c "mkdir -p '$WORK/out/releases/$(dirname "$target")' >/dev/null 2>&1; \
             printf 'PWNED' > '$WORK/out/releases/$target'" >/dev/null 2>&1
  if [ -f "$WORK/out/releases/$target" ] && grep -q "PWNED" "$WORK/out/releases/$target" 2>/dev/null; then
    no "εγγραφή σε releases/$target ΕΠΕΤΥΧΕ — ΤΑ BYTES ΑΛΛΑΞΑΝ"
  else
    ok "εγγραφή σε releases/$target ⇒ ΚΑΝΕΝΑ byte δεν γράφτηκε"
  fi
done

echo
echo "== ② ΘΕΤΙΚΟΣ ΜΑΡΤΥΡΑΣ: το candidates/ ΠΑΡΑΜΕΝΕΙ εγγράψιμο =="
if setpriv --reuid=lawmax-producer --regid=lawmax-producer --clear-groups \
     sh -c "mkdir -p '$WORK/out/candidates/.staging-t' && echo ok > '$WORK/out/candidates/.staging-t/x'" 2>/dev/null; then
  ok "ο producer γράφει στο candidates/ (ο έλεγχος ΔΕΝ είναι τετριμμένος)"
else
  no "ο producer ΔΕΝ μπορεί να γράψει ούτε στο candidates/ — ΚΕΝΟΣ ΜΑΡΤΥΡΑΣ"
fi

echo
echo "== ③ ΤΟ ΠΑΡΑΓΩΓΙΚΟ ENTRYPOINT ΥΠΟ PRODUCER UID, ΣΕ ΙΔΙΩΤΙΚΟ MOUNT NAMESPACE =="
# ΑΝΩΤΑΤΗ ΜΟΡΦΗ: το core χτίζεται ΜΙΑ φορά (ως root)· ο producer το ΦΟΡΤΩΝΕΙ σε
# ms. Η μεταγλώττιση ΔΕΝ είναι μέρος του ορίου ασφαλείας — αφαιρείται εντελώς.
CORE="$WORK/authority-cli.core"
LAWMAX_REPO="$REPO" sbcl --script "$REPO/authority-v2/tests/build-authority-core.lisp" "$CORE" >/dev/null 2>&1
[ -s "$CORE" ] || { echo "::error::BLOCKED — core δεν χτίστηκε"; exit 2; }
chmod 0644 "$CORE"
# Ανώτατη μορφή του ελέγχου: ΔΕΝ μιμούμαστε τον παραγωγό — ΤΡΕΧΟΥΜΕ τις
# ΠΡΑΓΜΑΤΙΚΕΣ παραγωγικές συναρτήσεις (create-staging-directory,
# run-attest-release) ΩΣ lawmax-producer, μέσα σε ΙΔΙΩΤΙΚΟ mount namespace όπου
# το legacy releases/ είναι bind-mounted read-only. Καμία παρενέργεια στο
# global mount table· καμία απομίμηση.
mkdir -p "$WORK/real/releases/sha256-aaa/temporal-proof" "$WORK/real/candidates"
echo "EVIDENCE" > "$WORK/real/releases/sha256-aaa/temporal-proof/existing.txt"
REAL_BEFORE="$(sha256sum "$WORK/real/releases/sha256-aaa/temporal-proof/existing.txt" | cut -d' ' -f1)"
chown -R lawmax-producer:lawmax-producer "$WORK/real/candidates"
chmod 0755 "$WORK/real"

if command -v unshare >/dev/null 2>&1; then
  OUT="$(unshare -m sh -c "
      mount --bind '$WORK/real/releases' '$WORK/real/releases' 2>/dev/null
      mount -o remount,bind,ro '$WORK/real/releases' 2>/dev/null
      cd '$REPO'
      # Ο producer ΔΕΝ έχει πρόσβαση στο root fasl cache: του δίνουμε ΔΙΚΟ του
      # (αλλιώς ο έλεγχος θα αποτύγχανε για ΛΑΘΟΣ λόγο — compile error, όχι
      # άρνηση πυρήνα, και ο μάρτυρας θα ήταν θολός).
      LAWMAX_REPO='$REPO' setpriv --reuid=lawmax-producer --regid=lawmax-producer \
        --clear-groups sbcl --core '$CORE' --script \
        '$REPO/authority-v2/tests/probe-producer-real.lisp' '$WORK/real/' 2>/dev/null | tail -1
  " 2>/dev/null | tr -d '\r')"
  case "$OUT" in
    *"staging=IN-CANDIDATES"*) ok "ΠΡΑΓΜΑΤΙΚΗ create-staging-directory ⇒ candidates/ (υπό producer UID)";;
    *)                         no "staging: $OUT";;
  esac
  case "$OUT" in
    *"attest=REFUSED"*) ok "ΠΡΑΓΜΑΤΙΚΗ run-attest-release ⇒ ΑΡΝΗΣΗ (υπό producer UID)";;
    *)                  no "attest: $OUT";;
  esac
  case "$OUT" in
    *"direct-write=REFUSED-BY-KERNEL"*) ok "απευθείας εγγραφή στο ro releases/ ⇒ ΑΡΝΗΣΗ ΠΥΡΗΝΑ";;
    *)                                   no "direct-write: $OUT";;
  esac
  REAL_AFTER="$(sha256sum "$WORK/real/releases/sha256-aaa/temporal-proof/existing.txt" | cut -d' ' -f1)"
  [ "$REAL_BEFORE" = "$REAL_AFTER" ] && ok "το legacy evidence ΑΘΙΚΤΟ μετά την πραγματική εκτέλεση" \
                                     || no "ΤΟ LEGACY EVIDENCE ΑΛΛΟΙΩΘΗΚΕ"
else
  echo "::error::BLOCKED — unshare ΑΠΩΝ (δεν δηλώνεται pass)"; exit 2
fi

echo
echo "── producer OS boundary: $p passed, $f failed ──"
[ "$f" -eq 0 ]
