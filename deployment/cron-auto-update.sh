#!/usr/bin/env bash
# =============================================================================
# cron-auto-update.sh — the autonomous update tick (run me from cron)
# =============================================================================
# One scheduled run of the full chain: discover (which codes changed) → fetch →
# codify → consolidate → verify(golden) → sign. ZERO manual uploads: the source
# is the supplier. Safe to schedule frequently — a flock prevents overlapping
# runs, and a non-zero exit (codification or golden drift failure) lets cron mail
# you.
#
# Wire it (e.g. hourly) in crontab:
#   17 * * * * /app/deployment/cron-auto-update.sh >> /var/log/corpus-update.log 2>&1
#
# Environment:
#   ORCHESTRATOR_CMD     how to invoke the CLI (default: /app/orchestrator.core)
#                        e.g. "docker compose run --rm orchestrator"
#   FEK_LISTING_JSON     gazette listing the headless discovery wrote (optional;
#                        if set, the run first reports which codes are pending)
#   AUTO_UPDATE_FETCH    0 to reuse existing source.pdf (default 1)
#   AUTO_UPDATE_PUBLISH  1 to also (re)emit the signed static site (default 0)
#   PCL_SIGNING_KEY /
#   PCL_PUBLIC_KEY       sign the corpus roots (Proof-Carrying Law, TIER 1-A)
#   LOCK_FILE            flock path (default /tmp/corpus-auto-update.lock)
#   AUTO_DISCOVER        0 to skip the headless harvest (default 1)
#   DISCOVER_URL         gazette search page to harvest like a user
#                        (default https://search.et.gr/el/search-legislation/)
#   DISCOVER_CMD         how to run the harvester (default: node .../discover-fek.js)
#   SEARCH_QUERY         text typed into the search box (passed through to discovery)
#   FEK_LISTING_JSON     where the harvest writes the listing the router reads
#                        (default /app/state/fek-listing.json)
# =============================================================================
set -euo pipefail

ORCHESTRATOR_CMD="${ORCHESTRATOR_CMD:-/app/orchestrator.core}"
LOCK_FILE="${LOCK_FILE:-/tmp/corpus-auto-update.lock}"

log() { printf '%s  %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }

# Single-flight: never let two ticks run at once.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  log "another auto-update is already running — skipping this tick."
  exit 0
fi

log "=== autonomous update tick start ==="

# 1) Discovery. (a) HARVEST: search the gazette site like a user (headless SPA →
#    its JSON API) into a listing JSON; (b) ROUTE: decide which served code(s)
#    each gazette amends. Both degrade gracefully — a discovery failure never
#    blocks the source refresh below.
export FEK_LISTING_JSON="${FEK_LISTING_JSON:-/app/state/fek-listing.json}"
DISCOVER_URL="${DISCOVER_URL:-https://search.et.gr/el/search-legislation/}"
DISCOVER_CMD="${DISCOVER_CMD:-node /app/deployment/discover-fek.js}"

if [[ "${AUTO_DISCOVER:-1}" != "0" ]] && command -v node >/dev/null 2>&1 \
     && [[ -f /app/deployment/discover-fek.js ]]; then
  log "discovery: searching ${DISCOVER_URL} like a user → ${FEK_LISTING_JSON}"
  ${DISCOVER_CMD} "${DISCOVER_URL}" "${FEK_LISTING_JSON}" \
    || log "discovery harvest failed (continuing with any existing listing)."
fi

export AMENDMENT_LAWS_JSON="${AMENDMENT_LAWS_JSON:-/app/state/amendment-laws.json}"
if [[ -f "${FEK_LISTING_JSON}" ]]; then
  log "discovery: routing ${FEK_LISTING_JSON} to codes…"
  ${ORCHESTRATOR_CMD} --discover-fek || log "discovery routing returned non-zero (continuing)."
  # Fetch each matched amending law's PDF + extract its text → AMENDMENT_LAWS_JSON,
  # which the consolidation below folds in automatically (the closed loop).
  log "amendments: fetching matched laws' text → ${AMENDMENT_LAWS_JSON}"
  ${ORCHESTRATOR_CMD} --fetch-amendments || log "fetch-amendments returned non-zero (continuing)."
else
  log "discovery: no listing (node/discover-fek.js unavailable); refreshing all codes from source."
fi

# 2) The autonomous loop: fetch → codify → consolidate → verify(golden) → sign.
#    A non-zero exit here is meaningful (codification error or golden drift) and
#    propagates so cron alerts.
rc=0
${ORCHESTRATOR_CMD} --auto-update || rc=$?

if [[ "$rc" -eq 0 ]]; then
  log "=== tick OK — all codes clean, signed proofs reissued ==="
else
  log "=== tick FAILED (rc=$rc) — a code failed codification or drifted from golden ==="
fi
exit "$rc"
