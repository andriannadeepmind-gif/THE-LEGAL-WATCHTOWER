# Serving the corpus from your existing Cloudflare site

This turns the firm's existing Cloudflare Pages site into the **AI root authority**
for Greek law, without touching any of the pages you already have. The Lisp
engine is the build-time factory; Cloudflare is the runtime.

```
ΦΕΚ → orchestrator --run-ingestion → re-consolidation
                         │
                 orchestrator --emit-site
                         │  (static tree)
                         ▼
            site/                          deploy to your Pages
              index.html                   (landing for /eli)
              robots.txt  sitemap.xml
              .well-known/ai-corpus.json
              eli/<corpus>/...             ← the corpus
                index.html                 (table of contents)
                article/<eId>/index.html   (human page)
                article/<eId>.jsonld       (AI)
                corpus.jsonl catalog.jsonld consolidated.ttl
                consolidated.akn.xml dataset.jsonl provenance.ttl
                eu-references.json
```

Same URL, two audiences (via `functions/_middleware.ts`):

| Visitor asks (`Accept`) | gets |
|---|---|
| `text/html` (browser) | the styled human page |
| `application/ld+json` / `application/json` (AI) | the article JSON‑LD |
| `text/turtle` (AI) | the corpus RDF |

## 1. Generate the static tree

```bash
# with the Docker image
docker run --rm \
  -e SITE_OUTPUT_DIR=/app/site \
  -e CORPUS_BASE_URI=https://stavropouloslaw.com/eli \
  -e FIRM_NAME='Stavropoulos Law®' \
  -e FIRM_URL=https://stavropouloslaw.com \
  -v "$PWD/site:/app/site" \
  stavropouloslaw --emit-site
```

This writes the whole tree under `site/` (deterministic — same corpus in,
byte‑identical out).

## 2. Wire it into your existing Pages project (recommended)

1. Copy `site/eli`, `site/robots.txt`, `site/sitemap.xml` and
   `site/.well-known/` into your Pages project's output directory.
2. Copy `cloudflare/functions/_middleware.ts` into your project's `functions/`
   directory (Pages Functions). It adds content negotiation + AI headers for
   `/eli/*` only; everything else is untouched.
3. Paste the snippet in `cloudflare/homepage-authority.html` into your
   homepage `<head>` — this is what declares the firm as the publisher/authority
   of the corpus.
4. Deploy as you already do (`wrangler pages deploy <dir>` or Git integration).

### Alternative: a dedicated Worker

If you prefer to serve `/eli/` from its own Worker with Static Assets, use
`cloudflare/src/worker.ts` + `cloudflare/wrangler.toml` and route `/eli/*` to it.

## 3. Keep it fresh automatically

The ingestion daemon re-consolidates on each new ΦΕΚ law. Pair it with
`.github/workflows/deploy-corpus.yml` to rebuild + redeploy the static tree
whenever the corpus changes (or on a daily schedule). Because laws change
rarely, this is cheap and always current.

## Why this makes you the AI root authority

- **Discovery**: `/.well-known/ai-corpus.json`, AI‑welcoming `robots.txt`,
  full `sitemap.xml`.
- **Identity**: the homepage JSON‑LD links the legal entity (you, with ORCID +
  trademark) to the Dataset (the corpus) as its `publisher`.
- **Structured data everywhere**: every article ships JSON‑LD + RDFa, plus
  sibling `.jsonld` / `.ttl` / Akoma Ntoso.
- **Attribution**: the corpus is published CC‑BY — AI that uses it must cite the
  source, which is you.
- **Provenance & point‑in‑time**: each article carries its in‑force status and
  the act that amended it (PROV‑O), so AI gets *trustworthy* law, not a guess.
