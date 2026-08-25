#!/usr/bin/env bash
# ΠΥΛΗ ΠΡΙΝ ΑΠΟ ΚΑΘΕ ΑΝΑΓΝΩΣΗ ΦΑΣΗΣ 1A.
# ΓΕΓΟΝΟΣ ΠΕΡΙΒΑΛΛΟΝΤΟΣ: mounts και daemons ΔΕΝ επιβιώνουν σε αυτή τη συνεδρία.
# Άρα η απομόνωση δεν επιβεβαιώνεται ΜΙΑ φορά — επιβεβαιώνεται ΚΑΘΕ φορά,
# με θετικό και αρνητικό μάρτυρα, αλλιώς καμία ανάγνωση δεν θεωρείται έγκυρη.
set -euo pipefail
SRC="${1:-/frozen/watchtower}"; DST="${2:-/frozen/ro}"
mkdir -p "$DST"
if ! mountpoint -q "$DST"; then
  mount --bind "$SRC" "$DST"
  mount -o remount,ro,bind "$DST"
fi
mountpoint -q "$DST" || { echo "::error::ΤΟ MOUNT ΔΕΝ ΣΤΗΘΗΚΕ"; exit 2; }
[ "$(ls -1 "$DST" | wc -l)" -gt 0 ] || { echo "::error::ΚΕΝΟ mount — καμία ψευδο-επιτυχία"; exit 2; }
head -c 16 "$DST/README.md" >/dev/null || { echo "::error::ΑΝΑΓΝΩΣΗ ΑΠΕΤΥΧΕ"; exit 2; }
if touch "$DST/.__probe" 2>/dev/null; then rm -f "$DST/.__probe"; echo "::error::ΓΡΑΦΗ ΠΕΡΑΣΕ — ΔΕΝ είναι read-only"; exit 1; fi
echo "READ-ONLY MOUNT: OK ($(findmnt -no OPTIONS "$DST" | cut -d, -f1)) · $(ls -1 "$DST" | wc -l) εγγραφές · γραφή ⇒ EROFS"
