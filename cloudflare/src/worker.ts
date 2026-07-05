/**
 * Standalone Cloudflare Worker variant (alternative to the Pages Function).
 * ---------------------------------------------------------------------------
 * Use this if you serve the /eli/ corpus from a DEDICATED Worker with Static
 * Assets (wrangler.toml `[assets]` -> the emitted `site/` tree) rather than as
 * part of the firm's Pages project. Same behaviour as functions/_middleware.ts:
 * content negotiation on article URLs + AI-first headers.
 */

interface Env {
  ASSETS: Fetcher;
}

const ARTICLE = /^\/eli\/([^/]+)\/article\/([^/.]+)\/?$/;

const prefersJsonLd = (a: string) =>
  /application\/(ld\+json|json)/i.test(a) && !/text\/html/i.test(a);
const prefersTurtle = (a: string) =>
  /(text\/turtle|application\/rdf\+xml|application\/n-triples)/i.test(a) && !/text\/html/i.test(a);

function withAiHeaders(res: Response): Response {
  const h = new Headers(res.headers);
  h.set("Access-Control-Allow-Origin", "*");
  h.set("X-Robots-Tag", "all");
  h.append("Vary", "Accept");
  return new Response(res.body, { status: res.status, statusText: res.statusText, headers: h });
}

function rewrite(env: Env, url: URL, pathname: string): Promise<Response> {
  const u = new URL(url.toString());
  u.pathname = pathname;
  return env.ASSETS.fetch(new Request(u.toString()));
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const m = url.pathname.match(ARTICLE);
    if (m && (request.method === "GET" || request.method === "HEAD")) {
      const accept = request.headers.get("Accept") || "";
      const [, corpus, eid] = m;
      if (prefersJsonLd(accept)) return withAiHeaders(await rewrite(env, url, `/eli/${corpus}/article/${eid}.jsonld`));
      if (prefersTurtle(accept)) return withAiHeaders(await rewrite(env, url, `/eli/${corpus}/consolidated.ttl`));
      return withAiHeaders(await rewrite(env, url, `/eli/${corpus}/article/${eid}/index.html`));
    }
    return withAiHeaders(await env.ASSETS.fetch(request));
  },
};
