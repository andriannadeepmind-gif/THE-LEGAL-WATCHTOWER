#!/usr/bin/env bash
# =============================================================================
# ΑΝΑΠΑΡΑΓΩΓΙΜΟ EVIDENCE PACK v1.1 — μία εντολή, ντετερμινιστικό αποτέλεσμα.
#   TLA_JAR=/path/to/tla2tools.jar ./run-pack.sh
# Απόδειξη = ΑΥΤΟ, όχι αριθμός agents. Κάθε μοντέλο τρέχει σε ΔΥΟ διαμορφώσεις:
# ασφαλή (ΠΡΕΠΕΙ να περάσει) + αρνητικό μάρτυρα (ΠΡΕΠΕΙ να σπάσει). Αναλλοίωτη
# που δεν σπάει σε κανέναν μάρτυρα = ΚΕΝΗ (το μάθημα του KernelL1.tla).
# =============================================================================
set -uo pipefail
JAR="${TLA_JAR:?set TLA_JAR to tla2tools.jar}"
cd "$(dirname "$0")"
O4="../../O4-NORMATIVE/formal"
echo "tool: $(java -cp "$JAR" tlc2.TLC 2>&1 | grep -oE 'Version [0-9.]+ of [0-9]+ [A-Za-z]+ [0-9]+' | head -1)"
echo "jar-sha256: $(sha256sum "$JAR" | cut -d' ' -f1)"
echo
fail=0
check () {  # <dir> <spec> <cfg-suffix> <expect: PASS|VIOLATED>
  local dir="$1" spec="$2" suf="$3" want="$4"
  local out; out=$(java -cp "$JAR" tlc2.TLC -metadir "$(mktemp -d)" -config "$dir/${spec}_${suf}.cfg" "$dir/${spec}.tla" 2>&1)
  local r
  if grep -q "No error has been found" <<<"$out"; then r=PASS
  elif grep -q "Error: Invariant" <<<"$out"; then r=VIOLATED
  else r=ERROR; fi
  local dig; dig=$(sha256sum "$dir/${spec}.tla" | cut -c1-12)
  [ "$r" = "$want" ] && ok="ok  " || { ok="DIFF"; fail=$((fail+1)); }
  printf '%s  %-20s %-8s %-9s (want %-8s) sha=%s\n' "$ok" "$spec" "$suf" "$r" "$want" "$dig"
}
echo "── v1.1 NEW TARGET MODELS ──"
check . TemporalProjection safe     PASS
check . TemporalProjection unsafe   VIOLATED
check . ArgumentEval       safe     PASS
check . ArgumentEval       unsafe   VIOLATED
echo "── O4 §5 + admission + isolation + migration (from Round 3) ──"
check "$O4" TrustState     safe                PASS
check "$O4" TrustState     unsafe              VIOLATED
check "$O4" Admission      safe                PASS
check "$O4" Admission      partial_failclosed  PASS
check "$O4" Admission      asis                VIOLATED
check "$O4" MatterCell     safe                PASS
check "$O4" MatterCell     unsafe              VIOLATED
check "$O4" Noninterference safe               PASS
check "$O4" Noninterference unsafe             VIOLATED
check "$O4" Migration      safe                PASS
check "$O4" Migration      unsafe              VIOLATED
check "$O4" PublicRoot     safe                PASS
check "$O4" PublicRoot     unsafe              VIOLATED
check "$O4" OfflineConsume safe                PASS
check "$O4" OfflineConsume unsafe              VIOLATED
echo
echo "divergences: $fail"
exit $((fail>0))
