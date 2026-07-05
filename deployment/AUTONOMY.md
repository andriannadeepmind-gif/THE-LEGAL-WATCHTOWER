# Autonomous updating — from source to signed corpus, no human in the loop

The corpus updates itself **directly from the source**. No manual uploads: the
ΦΕΚ (Government Gazette) is the supplier, the system is the codifier and the
verifiable root of authority. The chain:

```
 discover ──▶ route ──▶ fetch ──▶ codify ──▶ consolidate ──▶ verify(golden) ──▶ sign ──▶ publish
 (ΦΕΚ search) (legal-id)  (PDF)   (PDF→JSON)  (amendments)   (drift check)    (PCL-1)  (static site)
   edge/JS      Lisp      edge/JS    Lisp        Lisp            Lisp           Lisp       Lisp
```

**Network lives at the edge** (headless Chromium, anti-bot), **intelligence
stays pure in Lisp** (deterministic, testable, offline). The two meet through
small JSON/PDF files.

## The pieces

| Step | Component | Notes |
|------|-----------|-------|
| Discover | `deployment/discover-fek.js` | Real browser harvests the ΦΕΚ search page → JSON listing `[{title,url,number,year}]` |
| Route | `--discover-fek` (`source/legal-id-registry.lisp`) | Decides which served code(s) each gazette amends, from the configs (single source of truth) |
| Fetch | `deployment/fetch-fek.sh` + `fetch-fek.js` | Downloads the ΦΕΚ PDF (UA rotation, backoff, headless). `%PDF` magic validated in Lisp |
| Codify | `--materialize-pdf` | `source.pdf` → `source.json` (the real code text) |
| Consolidate | `--run-all-pipelines` | Applies amendments, builds the in-force consolidated document |
| Verify | `--verify-all` | Deterministic fingerprint vs the committed **golden** — catches any drift |
| Sign | `--emit-proofs` | Per-provision Merkle proofs chaining to the **signed** corpus root (PCL-1) |
| Publish | `--emit-site` | Born-cited static site + verifiers (optional) |

`--auto-update` runs **fetch → codify → consolidate → verify → sign** in one
command; `deployment/cron-auto-update.sh` is the scheduled wrapper.

## One scheduled tick

```bash
# crontab (hourly, on the box that has the orchestrator + headless browser)
17 * * * * /app/deployment/cron-auto-update.sh >> /var/log/corpus-update.log 2>&1
```

The wrapper now **harvests discovery itself** — it searches the gazette site like a
user (drives the search.et.gr React SPA and captures its JSON API), writes the
listing, routes it, then runs the loop. One scheduled line is the whole chain:

```bash
PCL_SIGNING_KEY=/app/keys/root.pem PCL_PUBLIC_KEY=/app/keys/root.pub.pem \
AUTO_UPDATE_PUBLISH=1 \
/app/deployment/cron-auto-update.sh
```

Defaults: `DISCOVER_URL=https://search.et.gr/el/search-legislation/`,
`FEK_LISTING_JSON=/app/state/fek-listing.json`. Override the search page or the
typed query (`DISCOVER_URL`, `SEARCH_QUERY`), or set `AUTO_DISCOVER=0` to skip the
harvest and just refresh from source. The harvest needs Node + Playwright on the
box; it degrades gracefully (the loop still runs) if either is missing.

Tune the API field-mapping once from a Greek IP by dumping the raw payload:

```bash
API_DUMP=/app/state/fek-api.json \
node /app/deployment/discover-fek.js "https://search.et.gr/el/search-legislation/" /app/state/fek-listing.json
```

## Environment

| Variable | Meaning |
|----------|---------|
| `ORCHESTRATOR_CMD` | how the wrapper invokes the CLI (default `/app/orchestrator.core`) |
| `FEK_LISTING_JSON` | gazette listing from `discover-fek.js` (enables `--discover-fek`) |
| `AUTO_UPDATE_FETCH` | `0` to reuse existing `source.pdf` (default `1` = fetch from source) |
| `AUTO_UPDATE_PUBLISH` | `1` to also (re)emit the signed static site |
| `PCL_SIGNING_KEY` / `PCL_PUBLIC_KEY` | the root-authority keypair — signs the corpus roots (PEM) |
| `GOLDEN_WRITE` | `1` to (re)establish the golden after a legitimate content change |

## Exit codes & alerting

`--auto-update` (and the wrapper) exit **non-zero** if any code fails
codification **or drifts from its golden**. Wire cron's MAILTO (or the log
monitor) to that signal: a non-zero tick means "a code changed unexpectedly —
review before re-signing." After a **legitimate** change, re-establish the
golden (`GOLDEN_WRITE=1 --verify-all`), commit it, and the next tick is clean.

## Why this is trustworthy

Every tick re-derives the corpus from source and re-issues proofs that chain to
a **signed** Merkle root. The golden gate means the signature is only re-applied
to content that verifies; the public verifiers (`deployment/verify/`) let anyone
confirm the result. Discovery is **conservative** — a code is only routed on a
concrete statutory citation or its distinctive name, never guessed — so the loop
never fabricates an update.
