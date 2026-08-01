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

# ── ΚΑΡΦΩΜΕΝΑ UID/GID ────────────────────────────────────────────────────────
# ΕΤΥΜΗΓΟΡΙΑ ΔΗΜΙΟΥΡΓΟΥ: «η πραγματική υπηρεσία … δεν ορίζει producer UID».
# Για να μπορεί ΤΟ COMPOSE/DOCKER να δηλώσει `user:` ντετερμινιστικά, τα uid/gid
# ΔΕΝ μπορούν να είναι ό,τι δώσει ο useradd. Καρφώνονται εδώ, ΜΙΑ φορά, και
# αναφέρονται αυτούσια στο docker-compose.yml.
LAWMAX_AUTHORITY_UID="${LAWMAX_AUTHORITY_UID:-11001}"
LAWMAX_PRODUCER_UID="${LAWMAX_PRODUCER_UID:-11002}"
LAWMAX_READER_UID="${LAWMAX_READER_UID:-11003}"
LAWMAX_READERS_GID="${LAWMAX_READERS_GID:-11010}"

ensure_group() {                     # ensure_group <name> [gid]
  getent group "$1" >/dev/null || groupadd --system ${2:+--gid "$2"} "$1"
}
ensure_user() {                      # ensure_user <name> <uid> [extra useradd args…]
  local u="$1" uid="$2"; shift 2
  if ! getent passwd "$u" >/dev/null; then
    # Το ΙΔΙΟ uid ⇒ ΙΔΙΑ ταυτότητα σε host και container. Αν το uid είναι ήδη
    # πιασμένο από άλλον, ΣΦΑΛΜΑ — καμία σιωπηλή αντικατάσταση ταυτότητας.
    if getent passwd "$uid" >/dev/null; then
      die "identities.sh: το uid $uid είναι ήδη πιασμένο από $(getent passwd "$uid" | cut -d: -f1) — καμία σιωπηλή επαναχρήση"
    fi
    useradd --system --no-create-home --shell /usr/sbin/nologin \
            --uid "$uid" --user-group "$@" "$u"
  fi
}

ensure_group "$READERS_GROUP" "$LAWMAX_READERS_GID"
ensure_user "$AUTHORITY_USER" "$LAWMAX_AUTHORITY_UID"
ensure_user "$PRODUCER_USER"  "$LAWMAX_PRODUCER_UID"
ensure_user "$READER_USER"    "$LAWMAX_READER_UID" --groups "$READERS_GROUP"
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
echo "  ΚΑΡΦΩΜΕΝΑ uid   : authority=$LAWMAX_AUTHORITY_UID producer=$LAWMAX_PRODUCER_UID reader=$LAWMAX_READER_UID readers-gid=$LAWMAX_READERS_GID"
