#!/usr/bin/env bash
# ΕΔΡΑ ΑΠΟΜΟΝΩΣΗΣ LANES — sourced από τον runner ΚΑΙ από το isolation test.
# ΜΙΑ υλοποίηση· δύο υλοποιήσεις θα μπορούσαν να αποκλίνουν σιωπηλά.
#
# ΕΓΓΥΗΣΕΙΣ (καθεμία με αρνητικό μάρτυρα στο isolation-test.sh):
#  Ι1 FRESH CONTEXT: κάθε lane τρέχει ως ΝΕΑ διεργασία σε ΝΕΟ workspace.
#  Ι2 ΑΚΡΙΒΗΣ ALLOWLIST: το workspace περιέχει ΑΚΡΙΒΩΣ τα δηλωμένα inputs —
#     ούτε ένα αρχείο παραπάνω, ούτε ένα λιγότερο (έλεγχος πριν ΚΑΙ μετά).
#  Ι3 ΜΗΔΕΝΙΚΗ ΠΡΟΣΒΑΣΗ σε outputs άλλων lanes πριν από τη σφράγιση:
#     τα outboxes ζουν ΕΚΤΟΣ κάθε workspace· κανένα μονοπάτι δεν οδηγεί εκεί.
#  Ι4 HASH-SEALED OUTPUTS: κάθε outbox σφραγίζεται με OUTPUT-SEAL.json
#     (sha256 ανά αρχείο + σύνολο) ΠΡΙΝ από κάθε μεταφορά.
#  Ι5 ΕΛΕΓΧΟΜΕΝΗ ΜΕΤΑΦΟΡΑ: μόνο ΜΕΤΑ τη σφράγιση ΟΛΩΝ των lanes, με
#     επαλήθευση seal κατά τη μεταφορά.
#  Ι6 CONTAMINATED/ABORT: κάθε απόκλιση allowlist ή μεταβολή input ⇒ η lane
#     σημαίνεται CONTAMINATED, το workspace καταστρέφεται, επαναλαμβάνεται
#     ΜΟΝΟ η επηρεασμένη lane μία φορά· δεύτερη μόλυνση ⇒ ABORT όλου του run.

ISO_ROOT=""

iso_init() {                       # iso_init <root>
  ISO_ROOT="$1"
  mkdir -p "$ISO_ROOT/workspaces" "$ISO_ROOT/outbox" "$ISO_ROOT/seals"
}

_iso_list() {                      # κανονικοποιημένη λίστα αρχείων ενός δέντρου
  ( cd "$1" && find . -type f | LC_ALL=C sort )
}

_iso_hashes() {
  ( cd "$1" && find . -type f -print0 | LC_ALL=C sort -z \
    | xargs -0 sha256sum 2>/dev/null )
}

iso_build_workspace() {            # iso_build_workspace <lane> <file>...
  local lane="$1"; shift
  local ws="$ISO_ROOT/workspaces/$lane"
  rm -rf "$ws"; mkdir -p "$ws"
  : > "$ISO_ROOT/seals/$lane.allowlist"
  local f
  for f in "$@"; do
    mkdir -p "$ws/$(dirname "$f")"
    cp -p "$f" "$ws/$f"
    sha256sum "$f" >> "$ISO_ROOT/seals/$lane.allowlist"
  done
  _iso_hashes "$ws" > "$ISO_ROOT/seals/$lane.pre"
}

iso_verify_workspace() {           # πριν ή μετά· επιστρέφει 0 καθαρό, 1 ΜΟΛΥΝΣΗ
  local lane="$1" phase="$2"
  local ws="$ISO_ROOT/workspaces/$lane"
  local now; now="$ISO_ROOT/seals/$lane.$phase.now"
  _iso_hashes "$ws" > "$now"
  if ! diff -q "$ISO_ROOT/seals/$lane.pre" "$now" >/dev/null 2>&1; then
    {
      echo "CONTAMINATED lane=$lane phase=$phase"
      diff "$ISO_ROOT/seals/$lane.pre" "$now" | sed 's/^/  /'
    } >> "$ISO_ROOT/seals/CONTAMINATION.log"
    return 1
  fi
  return 0
}

iso_run_lane() {                   # iso_run_lane <lane> <cmd...>
  # Ι1+Ι3 ΔΟΜΙΚΑ: η lane τρέχει σε ΔΙΚΟ ΤΗΣ mount namespace όπου tmpfs
  # καλύπτει ΟΛΟ το ISO_ROOT και ξαναδένονται ΜΟΝΟ το δικό της workspace και
  # το δικό της outbox. Τα outputs των άλλων lanes ΔΕΝ ΥΠΑΡΧΟΥΝ στο namespace
  # της — όχι «απαγορεύονται»: δεν υπάρχει inode να ανοίξει, ούτε για root.
  local lane="$1"; shift
  local ws="$ISO_ROOT/workspaces/$lane"
  local ob="$ISO_ROOT/outbox/$lane"
  mkdir -p "$ob"
  unshare --mount --propagation private \
    env ISO_ROOT="$ISO_ROOT" LANE_WS="$ws" LANE_OB="$ob" \
    bash -c '
      set -e
      hold=$(mktemp -d /tmp/iso-hold.XXXXXX)
      mkdir "$hold/ws" "$hold/ob"
      mount --bind "$LANE_WS" "$hold/ws"
      mount --bind "$LANE_OB" "$hold/ob"
      mount -t tmpfs -o size=1m,mode=0700 tmpfs "$ISO_ROOT"
      mkdir -p "$LANE_WS" "$LANE_OB"
      mount --bind "$hold/ws" "$LANE_WS"
      mount --bind "$hold/ob" "$LANE_OB"
      cd "$LANE_WS"
      ISO_OUT="$LANE_OB" exec "$@"
    ' bash "$@" > "$ob/.stdout" 2>&1
  local rc=$?
  echo "$rc" > "$ob/.exit"
  return $rc
}

iso_seal_outbox() {                # Ι4 — σφράγιση ΠΡΙΝ από κάθε μεταφορά
  local lane="$1"
  local ob="$ISO_ROOT/outbox/$lane"
  # το manifest σφράγισης ζει στο seals/, ΟΧΙ μέσα στο outbox — αλλιώς το
  # ίδιο το manifest θα άλλαζε το hash που πιστοποιεί
  ( cd "$ob" && find . -type f -print0 | LC_ALL=C sort -z \
    | xargs -0 sha256sum 2>/dev/null ) > "$ISO_ROOT/seals/$lane.files.sha"
  local total
  total=$(sha256sum "$ISO_ROOT/seals/$lane.files.sha" | cut -d' ' -f1)
  printf '{"lane":"%s","seal_sha256":"%s","files":"%s"}\n' \
    "$lane" "$total" "seals/$lane.files.sha" \
    > "$ISO_ROOT/seals/$lane.OUTPUT-SEAL.json"
}

iso_all_sealed() {                 # Ι5 προϋπόθεση μεταφοράς
  local lane
  for lane in "$@"; do
    [ -f "$ISO_ROOT/seals/$lane.OUTPUT-SEAL.json" ] || return 1
  done
  return 0
}

iso_transfer() {                   # iso_transfer <lane> <dest> — μόνο μετά τα seals
  local lane="$1" dest="$2"
  local ob="$ISO_ROOT/outbox/$lane"
  local want got tmp
  want=$(python3 -c "import json;print(json.load(open('$ISO_ROOT/seals/$lane.OUTPUT-SEAL.json'))['seal_sha256'])")
  tmp=$(mktemp)
  ( cd "$ob" && find . -type f -print0 | LC_ALL=C sort -z \
    | xargs -0 sha256sum 2>/dev/null ) > "$tmp"
  got=$(sha256sum "$tmp" | cut -d' ' -f1)
  rm -f "$tmp"
  if [ "$want" != "$got" ]; then
    echo "SEAL-MISMATCH lane=$lane want=$want got=$got" \
      >> "$ISO_ROOT/seals/CONTAMINATION.log"
    return 1
  fi
  mkdir -p "$dest"
  ( cd "$ob" && find . -type f -exec cp -p --parents {} "$dest"/ \; )
  cp -p "$ISO_ROOT/seals/$lane.OUTPUT-SEAL.json" "$dest/"
  return 0
}
