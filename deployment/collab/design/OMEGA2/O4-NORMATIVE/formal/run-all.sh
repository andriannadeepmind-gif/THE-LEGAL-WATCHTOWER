#!/usr/bin/env bash
# Αναπαραγωγή ΟΛΩΝ των ελέγχων. Απαιτεί TLC (tla2tools.jar) και java.
#   TLA_JAR=/path/to/tla2tools.jar ./run-all.sh
# Κάθε μοντέλο τρέχει σε ΔΥΟ τουλάχιστον διαμορφώσεις: μία ασφαλή (πρέπει να
# περάσει) και έναν ΑΡΝΗΤΙΚΟ ΜΑΡΤΥΡΑ (πρέπει να ΣΠΑΣΕΙ). Αναλλοίωτη που δεν
# σπάει σε κανέναν μάρτυρα είναι ΚΕΝΗ — το μάθημα του KernelL1.tla.
set -uo pipefail
JAR="${TLA_JAR:?set TLA_JAR to tla2tools.jar}"
cd "$(dirname "$0")"
fail=0
for spec in TrustState MatterCell Noninterference Migration Admission PublicRoot OfflineConsume; do
  for cfg in ${spec}_*.cfg; do
    c=${cfg#${spec}_}; c=${c%.cfg}
    out=$(java -cp "$JAR" tlc2.TLC -metadir "$(mktemp -d)" -config "$cfg" "$spec.tla" 2>&1)
    if grep -q "No error has been found" <<<"$out"; then r=PASS; else
       if grep -q "Error: Invariant" <<<"$out"; then r=VIOLATED; else r=ERROR; fi; fi
    case "$c" in
      safe|partial_failclosed) want=PASS ;;
      *)                       want=VIOLATED ;;
    esac
    [ "$r" = "$want" ] || { fail=$((fail+1)); }
    printf '%-16s %-20s %-9s (αναμενόμενο %s)\n' "$spec" "$c" "$r" "$want"
  done
done
echo "αποκλίσεις: $fail"; exit $((fail > 0))
