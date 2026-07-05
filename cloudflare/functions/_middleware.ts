/**
 * Cloudflare Pages Function — content negotiation + AI-first headers.
 * ---------------------------------------------------------------------------
 * Drop this file into the `functions/` directory of the SAME Pages project that
 * hosts the firm site. It runs at the edge for every request and makes one URL
 * serve the right thing to each visitor, without touching the existing pages:
 *
 *   GET /eli/<corpus>/article/<eId>
 *        Accept: text/html        -> the human page   (.../<eId>/index.html)
 *        Accept: application/ld+json | application/json
 *                                 -> machine JSON-LD  (.../<eId>.jsonld)
 *        Accept: text/turtle      -> the corpus RDF   (.../consolidated.ttl)
 *
 * Everything else falls through untouched to the static site. AI-first response
 * headers (CORS, X-Robots-Tag, Vary) are added to corpus responses so AI
 * systems are explicitly welcomed and can cache/cite correctly.
 *
 * The static tree under /eli/ is produced by the orchestrator:
 *   orchestrator --emit-site   (SITE_OUTPUT_DIR -> deploy to Pages)
 */

interface Env {
  ASSETS: Fetcher;
}

const ARTICLE = /^\/eli\/([^/]+)\/article\/([^/.]+)\/?$/;

function prefersJsonLd(accept: string): boolean {
  return /application\/(ld\+json|json)/i.test(accept) && !/text\/html/i.test(accept);
}
function prefersTurtle(accept: string): boolean {
  return /(text\/turtle|application\/rdf\+xml|application\/n-triples)/i.test(accept)
    && !/text\/html/i.test(accept);
}

function withAiHeaders(res: Response, isCorpus: boolean): Response {
  if (!isCorpus) return res;
  const h = new Headers(res.headers);
  h.set("Access-Control-Allow-Origin", "*");
  h.set("X-Robots-Tag", "all");
  h.append("Vary", "Accept");
  return new Response(res.body, { status: res.status, statusText: res.statusText, headers: h });
}

async function serveAsset(env: Env, url: URL, pathname: string): Promise<Response> {
  const u = new URL(url.toString());
  u.pathname = pathname;
  return env.ASSETS.fetch(new Request(u.toString()));
}

export const onRequest: PagesFunction<Env> = async (context) => {
  const { request, env, next } = context;
  const url = new URL(request.url);
  const path = url.pathname;
  const isCorpus = path.startsWith("/eli/") || path === "/.well-known/ai-corpus.json";

  if (request.method === "GET" || request.method === "HEAD") {
    const m = path.match(ARTICLE);
    if (m) {
      const accept = request.headers.get("Accept") || "";
      const [, corpus, eid] = m;
      if (prefersJsonLd(accept)) {
        return withAiHeaders(await serveAsset(env, url, `/eli/${corpus}/article/${eid}.jsonld`), true);
      }
      if (prefersTurtle(accept)) {
        return withAiHeaders(await serveAsset(env, url, `/eli/${corpus}/consolidated.ttl`), true);
      }
      // Default (browsers, and anything asking for HTML): the human page.
      return withAiHeaders(await serveAsset(env, url, `/eli/${corpus}/article/${eid}/index.html`), true);
    }
  }

  return withAiHeaders(await next(), isCorpus);
};
