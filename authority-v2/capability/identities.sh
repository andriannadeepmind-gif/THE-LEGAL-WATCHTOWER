#!/usr/bin/env bash
# =============================================================================
# LEVEL-7 VCCT-RSM — OS-ENFORCED WRITE CAPABILITY CLOSURE
# =============================================================================
# ΑΠΑΙΤΗΣΗ 1 (FV-CCT-RSM): «Μία και μοναδική authority process και ΕΝΑ
# OS-enforced write capability. Μόνο αυτή γράφει το authority store. Producer
# και serving processes έχουν candidate-write και authority-read-only. ΔΕΝ
# αρκεί source-code gate.»
#
# Ο διαχωρισμός ΔΕΝ είναι σύμβαση κώδικα: είναι ιδιοκτησία+δικαιώματα του
# πυρήνα. Ένας παραγωγός που ΘΕΛΕΙ να γράψει authority παίρνει EACCES από τον
# kernel, ανεξάρτητα από το τι λέει ο κώδικάς του — ακόμη κι αν ο κώδικας
# αλλάξει, ακόμη κι αν καλέσει απευθείας write(2).
#
#   ΤΑΥΤΟΤΗΤΕΣ                ΔΙΚΑΙΩΜΑΤΑ
#   lawmax-authority          authority store: rwx (ΜΟΝΟΣ writer)
#   lawmax-producer           candidates: rwx · authority store: ΚΑΝΕΝΑ (0750)
#   lawmax-reader             authority store: r-x (serving) · candidates: r-x
#
# ΥΛΟΠΟΙΗΣΗ: ο authority store ανήκει σε lawmax-authority:lawmax-authority με
# mode 0750. Η ομάδα lawmax-readers έχει read μέσω ACL/ομάδας. Ο producer ΔΕΝ
# ανήκει σε καμία από τις δύο ⇒ ούτε διάβασμα ούτε γράψιμο του store.
#
# ΤΙΜΙΟ ΟΡΙΟ: αυτό απαιτεί root για να στηθεί (useradd/chown). Το
# verify-capability-closure.sh αποδεικνύει ΕΚΤΕΛΕΣΤΙΚΑ την απαγόρευση με
# πραγματικές προσπάθειες εγγραφής ως κάθε ταυτότητα (setpriv), και δηλώνει
# BLOCKED αν δεν υπάρχει προνόμιο — ποτέ PASS χωρίς εκτέλεση.
set -euo pipefail

AUTHORITY_USER="${LAWMAX_AUTHORITY_USER:-lawmax-authority}"
PRODUCER_USER="${LAWMAX_PRODUCER_USER:-lawmax-producer}"
READER_USER="${LAWMAX_READER_USER:-lawmax-reader}"
READERS_GROUP="${LAWMAX_READERS_GROUP:-lawmax-readers}"

STORE_ROOT="${1:-/var/lib/lawmax/authority}"
CAND_ROOT="${2:-/var/lib/lawmax/candidates}"

die() { echo "::error::$*" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || die "identities.sh: απαιτείται root για τη δημιουργία ταυτοτήτων/δικαιωμάτων"

ensure_group() { getent group "$1" >/dev/null || groupadd --system "$1"; }
ensure_user() {
  local u="$1"; shift
  getent passwd "$u" >/dev/null || useradd --system --no-create-home --shell /usr/sbin/nologin "$@" "$u"
}

ensure_group "$READERS_GROUP"
ensure_user "$AUTHORITY_USER"
ensure_user "$PRODUCER_USER"
ensure_user "$READER_USER" --groups "$READERS_GROUP"
usermod -a -G "$READERS_GROUP" "$READER_USER" >/dev/null 2>&1 || true

mkdir -p "$STORE_ROOT" "$CAND_ROOT"

# AUTHORITY STORE: writer = ΜΟΝΟ authority· readers = ομάδα readers· άλλοι = ΤΙΠΟΤΑ.
chown -R "$AUTHORITY_USER":"$READERS_GROUP" "$STORE_ROOT"
chmod -R 0750 "$STORE_ROOT"

# CANDIDATES: writer = producer· authority+readers διαβάζουν.
chown -R "$PRODUCER_USER":"$READERS_GROUP" "$CAND_ROOT"
chmod -R 0750 "$CAND_ROOT"
# Ο authority ΠΡΕΠΕΙ να μπορεί να διαβάσει candidates ⇒ readers group.
usermod -a -G "$READERS_GROUP" "$AUTHORITY_USER" >/dev/null 2>&1 || true

echo "✓ capability closure εγκαταστάθηκε"
echo "  authority store : $STORE_ROOT  ($AUTHORITY_USER:$READERS_GROUP 0750)"
echo "  candidates      : $CAND_ROOT   ($PRODUCER_USER:$READERS_GROUP 0750)"
