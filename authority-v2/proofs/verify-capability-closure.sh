#!/usr/bin/env bash
# =============================================================================
# LEVEL-7 VCCT-RSM — ΕΚΤΕΛΕΣΤΙΚΗ ΑΠΟΔΕΙΞΗ ΤΟΥ CAPABILITY CLOSURE
# =============================================================================
# ΔΕΝ ελέγχει ότι «ο κώδικας λέει ότι δεν γράφει». Εκτελεί ΠΡΑΓΜΑΤΙΚΕΣ
# προσπάθειες εγγραφής ως ΚΑΘΕ ταυτότητα (setpriv) και απαιτεί τον kernel να
# τις απορρίψει. Αρνητικός μάρτυρας: ο authority ΠΡΕΠΕΙ να πετύχει — αλλιώς
# το τεστ είναι κενό (θα περνούσε και σε read-only filesystem).
#
# ΕΞΟΔΟΣ: 0 = όλα τα capability όρια αποδείχθηκαν εκτελεστικά
#         1 = ΠΑΡΑΒΙΑΣΗ (κάποιος έγραψε εκεί που δεν επιτρέπεται, ή ο
#             authority ΔΕΝ μπόρεσε να γράψει ⇒ κενός μάρτυρας)
#         2 = BLOCKED (χωρίς root/setpriv δεν εκτελείται — ΠΟΤΕ PASS)
set -uo pipefail

AUTHORITY_USER="${LAWMAX_AUTHORITY_USER:-lawmax-authority}"
PRODUCER_USER="${LAWMAX_PRODUCER_USER:-lawmax-producer}"
READER_USER="${LAWMAX_READER_USER:-lawmax-reader}"
STORE_ROOT="${1:-/var/lib/lawmax/authority}"
CAND_ROOT="${2:-/var/lib/lawmax/candidates}"

pass=0; fail=0
ok()   { pass=$((pass+1)); echo "  ok   $*"; }
no()   { fail=$((fail+1)); echo "  FAIL $*"; }

if [ "$(id -u)" -ne 0 ] || ! command -v setpriv >/dev/null 2>&1; then
  echo "::error::BLOCKED — NOT EXECUTED: απαιτείται root + setpriv για να δοκιμαστούν οι ταυτότητες"
  exit 2
fi
for u in "$AUTHORITY_USER" "$PRODUCER_USER" "$READER_USER"; do
  getent passwd "$u" >/dev/null || { echo "::error::BLOCKED — ταυτότητα $u ΑΠΟΥΣΑ (τρέξε identities.sh)"; exit 2; }
done

# Τρέχει εντολή ως χρήστη, ΜΕ τις συμπληρωματικές του ομάδες.
as_user() {
  local u="$1"; shift
  setpriv --reuid="$(id -u "$u")" --regid="$(id -g "$u")" --init-groups -- "$@"
}

try_write() {                       # try_write <user> <path>  -> 0 έγραψε, 1 όχι
  as_user "$1" /bin/sh -c "printf x > '$2' 2>/dev/null" >/dev/null 2>&1
}
try_read_dir() {                    # try_read_dir <user> <dir>
  as_user "$1" /bin/sh -c "ls '$2' >/dev/null 2>&1" >/dev/null 2>&1
}

echo "== ΘΕΤΙΚΟΣ ΜΑΡΤΥΡΑΣ: ο authority ΠΡΕΠΕΙ να γράφει (αλλιώς το τεστ είναι κενό) =="
if try_write "$AUTHORITY_USER" "$STORE_ROOT/.cap-probe-authority"; then
  ok "authority ΓΡΑΦΕΙ στο authority store"
  as_user "$AUTHORITY_USER" /bin/sh -c "rm -f '$STORE_ROOT/.cap-probe-authority'" || true
else
  no "authority ΔΕΝ μπορεί να γράψει — ΚΕΝΟΣ ΜΑΡΤΥΡΑΣ (ο έλεγχος δεν αποδεικνύει τίποτα)"
fi

echo "== ΑΡΝΗΣΗ: κανένας άλλος δεν γράφει authority =="
if try_write "$PRODUCER_USER" "$STORE_ROOT/.cap-probe-producer"; then
  no "Ο PRODUCER ΕΓΡΑΨΕ στο authority store — ΠΑΡΑΒΙΑΣΗ CAPABILITY"
  rm -f "$STORE_ROOT/.cap-probe-producer"
else
  ok "producer ⇒ EACCES στο authority store"
fi
if try_write "$READER_USER" "$STORE_ROOT/.cap-probe-reader"; then
  no "Ο READER ΕΓΡΑΨΕ στο authority store — ΠΑΡΑΒΙΑΣΗ CAPABILITY"
  rm -f "$STORE_ROOT/.cap-probe-reader"
else
  ok "reader (serving) ⇒ EACCES στο authority store"
fi

echo "== CANDIDATE ΖΩΝΗ: ο παραγωγός γράφει ΜΟΝΟ εκεί =="
if try_write "$PRODUCER_USER" "$CAND_ROOT/.cap-probe-cand"; then
  ok "producer ΓΡΑΦΕΙ candidates"
  as_user "$PRODUCER_USER" /bin/sh -c "rm -f '$CAND_ROOT/.cap-probe-cand'" || true
else
  no "producer ΔΕΝ γράφει candidates — το pipeline θα ήταν νεκρό"
fi

echo "== SERVING: ο reader ΔΙΑΒΑΖΕΙ authority (read-only) =="
if try_read_dir "$READER_USER" "$STORE_ROOT"; then
  ok "reader ΔΙΑΒΑΖΕΙ το authority store"
else
  no "reader ΔΕΝ διαβάζει το authority store — το serving θα ήταν νεκρό"
fi

echo
echo "── capability closure: $pass ok, $fail FAIL ──"
[ "$fail" -eq 0 ] || exit 1
