#!/usr/bin/env bash
# ΑΝΑΠΑΡΑΓΩΓΙΜΟ DESTRUCTION EVIDENCE — κάθε falsifier ΠΡΕΠΕΙ να ΣΠΑΣΕΙ (VIOLATED).
# Falsifier που ΔΕΝ σπάει = ψευδής κατάρριψη. TLA_JAR=<jar> ./run-falsifiers.sh
set -uo pipefail
JAR="${TLA_JAR:?set TLA_JAR}"; cd "$(dirname "$0")"; fail=0
chk () { # spec cfg
  local out; out=$(java -cp "$JAR" tlc2.TLC -metadir "$(mktemp -d)" -config "$2" "$1.tla" 2>&1)
  if grep -qE "Error: Invariant .* is violated|is equal to FALSE" <<<"$out"; then r=VIOLATED; else r=$(grep -q "No error" <<<"$out" && echo PASS || echo ERROR); fi
  [ "$r" = VIOLATED ] && ok=ok || { ok=DIFF; fail=$((fail+1)); }
  printf '%-4s %-22s %-26s -> %s (want VIOLATED)\n' "$ok" "$1" "$2" "$r"
}
chk TrustStateSkew    TrustStateSkew.cfg       # KT1 clock skew
chk MigrationRepro    MigrationRepro.cfg       # KT4 tagged proof still fails
chk OfflineConsumeLeak OfflineConsumeLeak.cfg  # KT9 version-pull fingerprint
chk ArgKill           ArgKill_mutual.cfg       # KT6 UNDEC confused with OUT
chk PublicRootKT8     PublicRootKT8.cfg        # KT8 publish without evidence
chk MatterCellSpoliation MatterCellSpoliation.cfg # KT3 legal-hold spoliation (ClearHold unauthorised)
echo "divergences (falsifiers που δεν έσπασαν): $fail"; exit $((fail>0))
