#!/usr/bin/env bash
# =============================================================================
# fetch-fek-by-number.sh — download a ΦΕΚ PDF by NUMBER, directly from the
# official public Azure blob. NO browser, NO Playwright, NO anti-bot: the URL is
# deterministic and built from the τεύχος/αριθμός/έτος the config already knows.
#
#   bash fetch-fek-by-number.sh <SERIES> <NUMBER> <YEAR> <OUT_PATH>
#   e.g. bash fetch-fek-by-number.sh Α 95 2019 input/poinikos.pdf
#
# URL pattern (confirmed from search.et.gr's own download link):
#   https://ia37rg02wpsa01.blob.core.windows.net/fek/<GG>/<YYYY>/<YYYY><GG><NNNNN>.pdf
#   GG = τεύχος as 2 digits (Α=01, Β=02, Γ=03, Δ=04); NNNNN = αριθμός, 5-digit padded.
# env: FETCH_ATTEMPTS (default 3), FEK_BLOB_BASE (override the blob base URL)
# =============================================================================
set -euo pipefail
SERIES="${1:?series (Α/Β/Γ/Δ)}"; NUMBER="${2:?number}"; YEAR="${3:?year}"; OUT="${4:?out path}"
ATTEMPTS="${FETCH_ATTEMPTS:-3}"
BASE="${FEK_BLOB_BASE:-https://ia37rg02wpsa01.blob.core.windows.net/fek}"

# τεύχος letter → 2-digit group (accept Greek Α-Δ, Latin A, or a numeric group).
case "$SERIES" in
  Α|A|α|a|1|01) GG=01 ;;
  Β|B|β|b|2|02) GG=02 ;;
  Γ|γ|3|03)     GG=03 ;;
  Δ|δ|4|04)     GG=04 ;;
  *)            GG="$SERIES" ;;   # already a 2-digit group
esac
NNNNN=$(printf '%05d' "$NUMBER")
URL="${BASE}/${GG}/${YEAR}/${YEAR}${GG}${NNNNN}.pdf"

mkdir -p "$(dirname "$OUT")"
for i in $(seq 1 "$ATTEMPTS"); do
  echo "[fek] attempt $i/$ATTEMPTS — $URL" >&2
  if curl -fSL --connect-timeout 20 --max-time 180 -o "$OUT" "$URL"; then
    # validate the %PDF magic (reject an anti-bot HTML page or an error body)
    if [ "$(head -c 4 "$OUT" 2>/dev/null)" = '%PDF' ]; then
      echo "ok: ΦΕΚ $SERIES $NUMBER/$YEAR → $OUT ($(wc -c <"$OUT") bytes)" >&2
      exit 0
    fi
    echo "[fek] downloaded but not a PDF (got $(head -c 16 "$OUT" | tr -d '\0'))" >&2
  fi
  [ "$i" -lt "$ATTEMPTS" ] && sleep $(( (2 ** i) + (RANDOM % 3) ))
done
echo "[fek] FAILED — $URL" >&2
exit 1
