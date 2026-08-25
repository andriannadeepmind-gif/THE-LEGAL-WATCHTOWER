#!/usr/bin/env bash
# END-TO-END ΔΟΚΙΜΗ ΑΠΟΜΟΝΩΣΗΣ — θετικοί ΚΑΙ αρνητικοί μάρτυρες πάνω στην
# ΙΔΙΑ βιβλιοθήκη που χρησιμοποιεί ο πραγματικός runner (μία έδρα).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lane-isolation.sh"
ROOT=$(mktemp -d /tmp/iso-test.XXXXXX)
trap 'rm -rf "$ROOT"' EXIT
cd "$ROOT"
mkdir -p inputs/shared
echo "sealed-input-A" > inputs/shared/a.txt
echo "sealed-input-B" > inputs/shared/b.txt
echo "dossier-L1" > inputs/L1.sexp
echo "dossier-L2" > inputs/L2.sexp
PASS=0; FAIL=0
ok(){ echo "  ✓ $1"; PASS=$((PASS+1)); }
bad(){ echo "  ✗ $1"; FAIL=$((FAIL+1)); }

iso_init "$ROOT/iso"

# ── T1 (Ι1/Ι2): workspace = ΑΚΡΙΒΩΣ η allowlist ─────────────────────────
iso_build_workspace L1 inputs/shared/a.txt inputs/L1.sexp
iso_build_workspace L2 inputs/shared/b.txt inputs/L2.sexp
[ "$(_iso_list "$ROOT/iso/workspaces/L1")" = "$(printf './inputs/L1.sexp\n./inputs/shared/a.txt')" ] \
  && ok "T1 allowlist ΑΚΡΙΒΗΣ: το L1 βλέπει ΜΟΝΟ τα 2 δηλωμένα inputs" \
  || bad "T1 allowlist"

# ── T2 (Ι3): ΚΑΜΙΑ διαδρομή προς output άλλης lane — δομικά ─────────────
iso_run_lane L2 sh -c 'echo "out-L2" > "$ISO_OUT/result.txt"'
iso_run_lane L1 sh -c '
  cat inputs/shared/a.txt inputs/L1.sexp > "$ISO_OUT/result.txt"
  # απόπειρες διαρροής: σχετική, απόλυτη, ΚΑΙ μέσω listing — όλες πρέπει ENOENT
  if cat ../../outbox/L2/result.txt 2>/dev/null \
     || cat "$ISO_ROOT/outbox/L2/result.txt" 2>/dev/null \
     || ls "$ISO_ROOT/workspaces/L2" 2>/dev/null | grep -q .; then
    echo "LEAKED" >> "$ISO_OUT/result.txt"
  fi'
grep -q "LEAKED" "$ROOT/iso/outbox/L1/result.txt" \
  && bad "T2 το L1 ΔΙΑΒΑΣΕ output του L2" \
  || ok "T2 πρόσβαση σε output άλλης lane ⇒ ENOENT (δομικά αδύνατη)"

# ── T3 (Ι2 post): καθαρό workspace περνά τον μετά-έλεγχο ────────────────
iso_verify_workspace L1 post && ok "T3 καθαρό workspace ⇒ PASS" || bad "T3"

# ── T4 (Ι6 αρνητικός): ΞΕΝΟ αρχείο ⇒ CONTAMINATED ───────────────────────
echo "planted" > "$ROOT/iso/workspaces/L1/foreign.leak"
iso_verify_workspace L1 post2 \
  && bad "T4 ξένο αρχείο ΔΕΝ ανιχνεύθηκε" \
  || ok "T4 ξένο αρχείο ⇒ CONTAMINATED (καταγεγραμμένο)"
grep -q "CONTAMINATED lane=L1" "$ROOT/iso/seals/CONTAMINATION.log" \
  && ok "T4b η μόλυνση καταγράφηκε ονομαστικά" || bad "T4b log"

# ── T5 (Ι6 αρνητικός): output ΑΛΛΗΣ lane φυτεμένο ⇒ CONTAMINATED ─────────
iso_build_workspace L1 inputs/shared/a.txt inputs/L1.sexp   # καθαρό ξανά
cp "$ROOT/iso/outbox/L2/result.txt" "$ROOT/iso/workspaces/L1/stolen-L2-output.txt"
iso_verify_workspace L1 post3 \
  && bad "T5 φυτεμένο output άλλης lane ΔΕΝ ανιχνεύθηκε" \
  || ok "T5 output άλλης lane στο workspace ⇒ CONTAMINATED"

# ── T6 (Ι6 αρνητικός): ΜΕΤΑΒΟΛΗ σφραγισμένου input ⇒ CONTAMINATED ────────
iso_build_workspace L1 inputs/shared/a.txt inputs/L1.sexp
echo "tampered" >> "$ROOT/iso/workspaces/L1/inputs/shared/a.txt"
iso_verify_workspace L1 post4 \
  && bad "T6 μεταβολή input ΔΕΝ ανιχνεύθηκε" \
  || ok "T6 μεταβολή σφραγισμένου input ⇒ CONTAMINATED"

# ── T7 (Ι6): επανάληψη ΜΟΝΟ της μολυσμένης lane — το L2 ΔΕΝ ξανατρέχει ──
L2_HASH_BEFORE=$(sha256sum "$ROOT/iso/outbox/L2/result.txt" | cut -d' ' -f1)
iso_build_workspace L1 inputs/shared/a.txt inputs/L1.sexp
iso_run_lane L1 sh -c 'cat inputs/shared/a.txt inputs/L1.sexp > "$ISO_OUT/result.txt"'
iso_verify_workspace L1 post5 || bad "T7 rerun μολύνθηκε ξανά"
L2_HASH_AFTER=$(sha256sum "$ROOT/iso/outbox/L2/result.txt" | cut -d' ' -f1)
[ "$L2_HASH_BEFORE" = "$L2_HASH_AFTER" ] \
  && ok "T7 rerun ΜΟΝΟ της L1 — το output της L2 byte-identical" \
  || bad "T7 το L2 άλλαξε"

# ── T8 (Ι4): σφράγιση outbox με hash ────────────────────────────────────
iso_seal_outbox L1; iso_seal_outbox L2
[ -f "$ROOT/iso/seals/L1.OUTPUT-SEAL.json" ] && ok "T8 OUTPUT-SEAL γράφτηκε" || bad "T8"

# ── T9 (Ι5 αρνητικός): μεταφορά ΠΡΙΝ σφραγιστούν ΟΛΕΣ ⇒ άρνηση ──────────
rm -f "$ROOT/iso/seals/L2.OUTPUT-SEAL.json"
iso_all_sealed L1 L2 \
  && bad "T9 μεταφορά επιτράπηκε με ασφράγιστη lane" \
  || ok "T9 μεταφορά ΑΠΑΓΟΡΕΥΤΗΚΕ όσο η L2 είναι ασφράγιστη"
iso_seal_outbox L2
iso_all_sealed L1 L2 && ok "T9b με όλα τα seals η μεταφορά επιτρέπεται" || bad "T9b"

# ── T10 (Ι4/Ι5 αρνητικός): παραποίηση ΜΕΤΑ το seal ⇒ SEAL-MISMATCH ──────
echo "post-seal-tamper" >> "$ROOT/iso/outbox/L2/result.txt"
iso_transfer L2 "$ROOT/dest/L2" \
  && bad "T10 παραποιημένο outbox ΜΕΤΑΦΕΡΘΗΚΕ" \
  || ok "T10 παραποίηση μετά το seal ⇒ SEAL-MISMATCH, καμία μεταφορά"

# ── T11: καθαρή μεταφορά μετά από έγκυρο seal ───────────────────────────
iso_seal_outbox L2
iso_transfer L1 "$ROOT/dest/L1" && iso_transfer L2 "$ROOT/dest/L2" \
  && ok "T11 ελεγχόμενη μεταφορά με επαλήθευση seal" || bad "T11"

echo
echo "ISOLATION-TEST: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = 0 ] && { echo "ALL-ISOLATION-WITNESSES-PASS"; exit 0; }
exit 1
