#!/bin/sh
# Runs the industrial (TLA+/TLC) part of the evidence pack and writes TLA-RESULTS.md
cd "$(dirname "$0")/tla" || exit 1
OUT=../TLA-RESULTS.md
{
  echo "## Industrial formal evidence — TLA+ / TLC"
  echo
  echo "tool: $(java -cp tla2tools.jar tlc2.TLC -help 2>/dev/null | grep -o 'Version [0-9.]* of [0-9]* [A-Za-z]* [0-9]*' | head -1)"
  echo "spec digests: WatchtowerLog.tla \`$(sha256sum WatchtowerLog.tla | cut -d' ' -f1)\`"
  echo "              WatchtowerCore.tla \`$(sha256sum WatchtowerCore.tla | cut -d' ' -f1)\`"
  echo "              tla2tools.jar \`$(sha256sum tla2tools.jar | cut -d' ' -f1)\`"
  echo
  echo "| model | configuration | outcome | states (distinct) | depth |"
  echo "|---|---|---|---|---|"
  for c in CFT CFT_BYZ BFT BUG_GAP BUG_ADOPT BUG_TRUNC; do
    R=$(java -XX:+UseParallelGC -cp tla2tools.jar tlc2.TLC -config Log_$c.cfg -workers 4 -cleanup WatchtowerLog.tla 2>&1)
    ST=$(echo "$R" | grep -oE "Error: (Invariant|Action property) [A-Za-z]+ is violated" | head -1)
    [ -z "$ST" ] && ST=$(echo "$R" | grep -o "Model checking completed. No error has been found." | head -1)
    N=$(echo "$R" | grep -oE "^[0-9]+ states generated, [0-9]+ distinct" | head -1)
    D=$(echo "$R" | grep -oE "depth of the complete state graph search is [0-9]+" | grep -oE "[0-9]+$")
    echo "| WatchtowerLog | $c | $ST | $N | $D |"
  done
  for c in NONE torn rewrite cutreg leak basisfut basisreg resurrect selfrec signrev thresh; do
    R=$(java -XX:+UseParallelGC -cp tla2tools.jar tlc2.TLC -config Core_$c.cfg -workers 4 -cleanup WatchtowerCore.tla 2>&1)
    ST=$(echo "$R" | grep -oE "Error: Invariant [A-Za-z]+ is violated" | head -1)
    [ -z "$ST" ] && ST=$(echo "$R" | grep -o "Model checking completed. No error has been found." | head -1)
    N=$(echo "$R" | grep -oE "^[0-9]+ states generated, [0-9]+ distinct" | head -1)
    D=$(echo "$R" | grep -oE "depth of the complete state graph search is [0-9]+" | grep -oE "[0-9]+$")
    echo "| WatchtowerCore | $c | $ST | $N | $D |"
  done
} > $OUT
echo "wrote $OUT"
