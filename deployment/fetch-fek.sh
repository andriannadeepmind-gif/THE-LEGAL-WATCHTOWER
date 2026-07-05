#!/usr/bin/env bash
# =============================================================================
# fetch-fek.sh — REFERENCE network-edge fetcher for the ΦΕΚ / et.gr source.
# =============================================================================
# The ONE component outside the pure-Lisp core (like libpoppler): the
# orchestrator invokes it via source.fetch_cmd to download a code's PDF DIRECTLY
# from source, so the corpus updates with zero manual uploads. The Lisp side
# validates the result (%PDF magic), so this only has to produce a real PDF.
#
# CONTRACT:  fetch-fek.sh <SOURCE_URL> <OUT_PATH>   (exit 0 on success)
#   in configs/<corpus>.yaml:  fetch_cmd: "deployment/fetch-fek.sh '<URL>' {{out}}"
#
# ANTI-BOT STRATEGY — N attempts, ROTATING User-Agent, exponential backoff + jitter:
#   each attempt picks a different real browser UA and tries
#     1. a browser-like HTTPS GET (curl, no browser runtime), then
#     2. a REAL headless Chromium (deployment/fetch-fek.js via Playwright) that
#        behaves like a user (masks automation, navigates, downloads in-session).
#   Rotating the UA + jitter makes simple rate/fingerprint anti-bot far harder to
#   trip. (A real CAPTCHA / Cloudflare-Turnstile remains unsolvable by automation
#   and needs the institutional ΦΕΚ feed.)
#
# Tunables (env): FETCH_TIMEOUT (s, def 120), FETCH_ATTEMPTS (def 3).
# Setup for step 2 on the host:  npx playwright install --with-deps chromium
# =============================================================================
set -euo pipefail

URL="${1:?usage: fetch-fek.sh <SOURCE_URL> <OUT_PATH>}"
OUT="${2:?usage: fetch-fek.sh <SOURCE_URL> <OUT_PATH>}"
TIMEOUT="${FETCH_TIMEOUT:-120}"
ATTEMPTS="${FETCH_ATTEMPTS:-3}"
HERE="$(cd "$(dirname "$0")" && pwd)"

# Pool of current, realistic desktop browser User-Agents (rotated per attempt).
UAS=(
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36 Edg/123.0.0.0"
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
)

is_pdf() { [ -s "$1" ] && [ "$(head -c 5 "$1" 2>/dev/null)" = "%PDF-" ]; }
jitter()  { awk "BEGIN{srand(); printf \"%.2f\", $1 + rand()*$1}"; }   # base + up to base

mkdir -p "$(dirname "$OUT")"

n="${#UAS[@]}"
for attempt in $(seq 1 "$ATTEMPTS"); do
  UA="${UAS[$(( (attempt - 1) % n ))]}"
  JAR="$(mktemp)"
  echo "[fetch-fek] attempt ${attempt}/${ATTEMPTS}  UA=…${UA: -28}"

  # --- 1) browser-like curl with the rotated UA ------------------------------
  curl -sSL --compressed --max-time "$TIMEOUT" --retry 2 --retry-delay 2 \
       -A "$UA" \
       -H "Accept: application/pdf,text/html;q=0.9,*/*;q=0.8" \
       -H "Accept-Language: el-GR,el;q=0.9,en;q=0.8" \
       -H "Referer: https://www.et.gr/" \
       -c "$JAR" -b "$JAR" -o "$OUT" "$URL" || true
  if is_pdf "$OUT"; then echo "[fetch-fek] ✓ PDF via curl (attempt ${attempt}) → $OUT"; rm -f "$JAR"; exit 0; fi

  # --- 2) real headless Chromium with the same rotated UA --------------------
  if command -v node >/dev/null 2>&1 && [ -f "$HERE/fetch-fek.js" ]; then
    FETCH_TIMEOUT="$TIMEOUT" FETCH_UA="$UA" node "$HERE/fetch-fek.js" "$URL" "$OUT" || true
    if is_pdf "$OUT"; then echo "[fetch-fek] ✓ PDF via headless browser (attempt ${attempt}) → $OUT"; rm -f "$JAR"; exit 0; fi
  elif [ "$attempt" -eq 1 ]; then
    echo "[fetch-fek] node/Playwright not installed — install once: npx playwright install --with-deps chromium" >&2
  fi

  rm -f "$JAR"
  if [ "$attempt" -lt "$ATTEMPTS" ]; then
    back="$(jitter "$(awk "BEGIN{print 2 ^ ($attempt - 1)}")")"   # 1·, 2·, 4·… + jitter
    echo "[fetch-fek] no PDF yet; backing off ${back}s before next UA…"
    sleep "$back"
  fi
done

echo "[fetch-fek] ✗ could not obtain a PDF from $URL after ${ATTEMPTS} attempts (anti-bot challenge?)" >&2
rm -f "$OUT"
exit 1
