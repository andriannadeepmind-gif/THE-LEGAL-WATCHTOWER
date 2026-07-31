#!/usr/bin/env bash
# =============================================================================
# LEVEL-7 VCCT-RSM — CEREMONY TOOLING (root/rotation/revocation/recovery)
# =============================================================================
# ΑΠΑΙΤΗΣΗ (διορθωτική §8 της δεύτερης εντολής): «κατασκεύασε ΠΛΗΡΩΣ ceremony
# tooling, rotation, revocation, recovery, fixtures και rehearsal· σταμάτησε
# ΜΟΝΟ πριν από τη δημιουργία/χρήση του πραγματικού production root key.»
#
# ΤΟ ΟΡΙΟ ΕΙΝΑΙ ΔΟΜΙΚΟ, ΟΧΙ ΣΥΣΤΑΣΗ: κάθε εντολή που θα άγγιζε production ρίζα
# απαιτεί LAWMAX_CEREMONY_MODE=production ΚΑΙ αρνείται πάντα σε αυτό το
# περιβάλλον (δεν υπάρχει HSM/air-gap/μάρτυρες). Σε rehearsal mode τα ΠΑΝΤΑ
# εκτελούνται πραγματικά με test keys — ώστε η τελετή να έχει ΠΡΟΒΑΡΕΙ πριν
# γίνει αληθινή.
#
#   ceremony.sh rehearse-genesis   — πλήρης πρόβα γένεσης (test keys)
#   ceremony.sh rehearse-rotation  — πρόβα rotation (old root υπογράφει το new)
#   ceremony.sh rehearse-revocation— πρόβα ανάκλησης κλειδιού
#   ceremony.sh rehearse-recovery  — πρόβα ανάκτησης από απώλεια online ρόλων
#   ceremony.sh production-genesis — ΑΡΝΕΙΤΑΙ (stop point)
set -euo pipefail

MODE="${LAWMAX_CEREMONY_MODE:-rehearsal}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WORK="${LAWMAX_CEREMONY_WORK:-$ROOT/authority-v2/fixtures/ceremony}"

die() { echo "::error::$*" >&2; exit 1; }
say() { echo "  $*"; }

require_rehearsal() {
  if [ "$MODE" = "production" ]; then
    cat >&2 <<'STOP'
::error::STOP POINT — ΠΑΡΑΓΩΓΙΚΗ ΤΕΛΕΤΗ ΡΙΖΑΣ
Η δημιουργία/χρήση ΠΡΑΓΜΑΤΙΚΟΥ production root key ΔΕΝ εκτελείται από αυτή τη
συνεδρία. Απαιτεί ρητή ενέργεια του δημιουργού με:
  · air-gapped μηχάνημα (ποτέ αυτό που τρέχει authority)
  · υλικό φύλαξης (HSM / offline media) και σχέδιο κληρονομιάς
  · καταγεγραμμένο transcript τελετής + μάρτυρες
  · out-of-band δημοσίευση της ρίζας σε ≥2 ανεξάρτητα κανάλια
Το tooling είναι ΕΤΟΙΜΟ και ΠΡΟΒΑΡΙΣΜΕΝΟ (rehearse-*). Η τελετή είναι δική σας.
STOP
    exit 3
  fi
}

new_key() {                    # new_key <name>  → <name>.key + <name>.pub
  local n="$1"
  openssl genpkey -algorithm ed25519 -out "$WORK/$n.key" 2>/dev/null
  openssl pkey -in "$WORK/$n.key" -pubout -out "$WORK/$n.pub"
  chmod 0600 "$WORK/$n.key"
}
sign_file() {                  # sign_file <key> <file> <sigout>
  openssl pkeyutl -sign -rawin -inkey "$1" -in "$2" -out "$3"
}
verify_file() {                # verify_file <pub> <file> <sig>
  openssl pkeyutl -verify -rawin -pubin -inkey "$1" -in "$2" -sigfile "$3" >/dev/null 2>&1
}
keyid() { openssl pkey -pubin -in "$1" -outform DER 2>/dev/null | sha256sum | cut -d' ' -f1; }

cmd="${1:-help}"
mkdir -p "$WORK"

case "$cmd" in
  rehearse-genesis)
    require_rehearsal
    echo "== ΠΡΟΒΑ ΓΕΝΕΣΗΣ (test keys — ΚΑΜΙΑ παραγωγική εξουσία) =="
    new_key root; new_key release; new_key targets; new_key snapshot; new_key timestamp
    say "root keyid      : $(keyid "$WORK/root.pub")"
    # Το root υπογράφει ΤΑ ΚΛΕΙΔΙΑ των άλλων ρόλων (delegation).
    for r in release targets snapshot timestamp; do
      sign_file "$WORK/root.key" "$WORK/$r.pub" "$WORK/$r.pub.rootsig"
      verify_file "$WORK/root.pub" "$WORK/$r.pub" "$WORK/$r.pub.rootsig" \
        || die "delegation $r ΑΠΕΤΥΧΕ"
      say "delegation ✓    : root → $r"
    done
    # Το root υπογράφει τον ΕΑΥΤΟ του (self-binding της εποχής).
    sign_file "$WORK/root.key" "$WORK/root.pub" "$WORK/root.pub.selfsig"
    verify_file "$WORK/root.pub" "$WORK/root.pub" "$WORK/root.pub.selfsig" || die "self-binding ΑΠΕΤΥΧΕ"
    say "self-binding ✓  : root → root"
    echo "✓ πρόβα γένεσης ολοκληρώθηκε (5 ρόλοι, 4 delegations, 1 self-binding)"
    ;;

  rehearse-rotation)
    require_rehearsal
    echo "== ΠΡΟΒΑ ROTATION (το ΠΑΛΙΟ root υπογράφει το ΝΕΟ — αλυσίδα) =="
    [ -f "$WORK/root.key" ] || die "τρέξε πρώτα rehearse-genesis"
    cp "$WORK/root.pub" "$WORK/root.old.pub"; cp "$WORK/root.key" "$WORK/root.old.key"
    new_key root
    sign_file "$WORK/root.old.key" "$WORK/root.pub" "$WORK/root.pub.rotationsig"
    verify_file "$WORK/root.old.pub" "$WORK/root.pub" "$WORK/root.pub.rotationsig" \
      || die "rotation ΑΠΕΤΥΧΕ"
    say "old keyid : $(keyid "$WORK/root.old.pub")"
    say "new keyid : $(keyid "$WORK/root.pub")"
    # ΑΡΝΗΤΙΚΟΣ ΜΑΡΤΥΡΑΣ: το ΝΕΟ root ΔΕΝ επικυρώνει τον εαυτό του χωρίς αλυσίδα.
    if verify_file "$WORK/root.pub" "$WORK/root.pub" "$WORK/root.pub.rotationsig"; then
      die "ΠΑΡΑΒΙΑΣΗ: το νέο root φάνηκε να αυτο-επικυρώνεται — η αλυσίδα θα ήταν κενή"
    fi
    say "αρνητικός μάρτυρας ✓ : χωρίς την αλυσίδα, το νέο root ΔΕΝ στέκει μόνο του"
    echo "✓ πρόβα rotation ολοκληρώθηκε"
    ;;

  rehearse-revocation)
    require_rehearsal
    echo "== ΠΡΟΒΑ ΑΝΑΚΛΗΣΗΣ =="
    [ -f "$WORK/release.pub" ] || die "τρέξε πρώτα rehearse-genesis"
    kid="$(keyid "$WORK/release.pub")"
    printf '{"kind":"lawmax/revocation/1","revoked_keyid":"%s","role":"release","reason":"rehearsal"}\n' \
      "$kid" > "$WORK/revocation.json"
    sign_file "$WORK/root.key" "$WORK/revocation.json" "$WORK/revocation.sig"
    verify_file "$WORK/root.pub" "$WORK/revocation.json" "$WORK/revocation.sig" \
      || die "η ανάκληση ΔΕΝ επαληθεύεται"
    say "ανακλήθηκε keyid: $kid (υπογεγραμμένο από root)"
    grep -q "$kid" "$WORK/revocation.json" || die "η ανάκληση δεν κατονομάζει το κλειδί"
    echo "✓ πρόβα ανάκλησης ολοκληρώθηκε (ρητή εγγραφή, όχι σιωπή)"
    ;;

  rehearse-recovery)
    require_rehearsal
    echo "== ΠΡΟΒΑ ΑΝΑΚΤΗΣΗΣ (απώλεια ΟΛΩΝ των online ρόλων) =="
    [ -f "$WORK/root.key" ] || die "τρέξε πρώτα rehearse-genesis"
    for r in release targets snapshot timestamp; do rm -f "$WORK/$r.key" "$WORK/$r.pub"; done
    say "καταστράφηκαν ΟΛΑ τα online κλειδιά ρόλων"
    # Η ανάκτηση γίνεται ΜΟΝΟ από το offline root — αυτό είναι το νόημά του.
    for r in release targets snapshot timestamp; do
      new_key "$r"
      sign_file "$WORK/root.key" "$WORK/$r.pub" "$WORK/$r.pub.rootsig"
      verify_file "$WORK/root.pub" "$WORK/$r.pub" "$WORK/$r.pub.rootsig" || die "recovery $r ΑΠΕΤΥΧΕ"
    done
    say "ανακτήθηκαν 4 ρόλοι από το offline root"
    echo "✓ πρόβα ανάκτησης ολοκληρώθηκε — η απώλεια online κλειδιών ΔΕΝ είναι καταστροφή"
    ;;

  production-genesis|production-rotation|production-revocation)
    LAWMAX_CEREMONY_MODE=production
    MODE=production
    require_rehearsal      # ΠΑΝΤΑ σταματά — αυτό είναι το stop point
    ;;

  *)
    sed -n '2,30p' "$0"
    ;;
esac
