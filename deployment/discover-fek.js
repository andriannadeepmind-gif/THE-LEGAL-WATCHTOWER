#!/usr/bin/env node
/* =============================================================================
 * discover-fek.js — query the et.gr legislation API DIRECTLY (no form scraping).
 * =============================================================================
 * The search.et.gr "Αναζήτηση Νομοθεσίας" page is a React SPA that calls one JSON
 * endpoint:
 *
 *   POST https://searchetv99.azurewebsites.net/api/searchlegislation
 *   body: {"legislationCatalogues":"1","legislationNumber":"<n|empty>",
 *          "selectYear":["2024", ...]}                 // catalogues 1 = Νόμος
 *   resp: {"status":"ok","data":"<JSON-STRING array of search_* records>"}
 *
 * Each record carries everything we need:
 *   search_LawProtocolNumber (the law number → routing), search_DocumentNumber +
 *   search_IssueGroupID + year (→ the deterministic ΦΕΚ blob PDF url),
 *   search_Description (what it amends, e.g. «…ΠΟΙΝΙΚΟ ΚΩΔΙΚΑ…»), search_ID (fekId).
 *
 * We call that API directly through a browser CONTEXT (so the request carries the
 * site's cookies/headers from a real session — no anti-bot, no CAPTCHA was present)
 * and print a JSON array [{title,url,number,year,fek,fekId,description}] that the
 * Lisp core consumes via `--discover-fek` (FEK_LISTING_JSON) to route each gazette
 * to the served code(s) it amends. Network at the edge; routing pure in Lisp.
 *
 *   node discover-fek.js <SEARCH_URL> [OUT_PATH]      # OUT_PATH default: stdout
 *   env:
 *     SEARCH_YEARS    comma list of years to scan (default: current year)
 *     LEGISLATION_TYPE  catalogue id (default 1 = Νόμος)
 *     SEARCH_NUMBER   a specific law number, or '' (default) for the whole annual
 *                     catalogue of each year
 *     API_DUMP        path to also write the raw API payloads (for auditing)
 *     FETCH_TIMEOUT   seconds (default 120)
 *     FEK_HEADFUL=1   visible browser (debug)
 *
 * Setup once: npm i -g playwright && npx playwright install --with-deps chromium
 * A hard CAPTCHA/Turnstile would defeat automation by design (needs the
 * institutional feed) — but this endpoint served 200 with none.
 * ============================================================================= */
'use strict';
const fs = require('fs');
const path = require('path');

const SEARCH_URL = process.argv[2] || 'https://search.et.gr/el/search-legislation/';
const OUT = process.argv[3];
const TIMEOUT = (parseInt(process.env.FETCH_TIMEOUT || '120', 10)) * 1000;
const API = 'https://searchetv99.azurewebsites.net/api/searchlegislation';
const BLOB = 'https://ia37rg02wpsa01.blob.core.windows.net/fek';
const CATALOGUES = process.env.LEGISLATION_TYPE || '1';        // 1 = Νόμος
const NUMBER = process.env.SEARCH_NUMBER || '';                // '' = whole year
const YEARS = (process.env.SEARCH_YEARS || String(new Date().getFullYear()))
  .split(',').map((s) => s.trim()).filter(Boolean);
const API_DUMP = process.env.API_DUMP || '';

const UA = process.env.FEK_UA ||
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

const emit = (items) => {
  const json = JSON.stringify(items, null, 2);
  if (OUT) { fs.mkdirSync(path.dirname(OUT), { recursive: true }); fs.writeFileSync(OUT, json); }
  else { process.stdout.write(json + '\n'); }
};

// {status, data:"<json string>"} → [{title,url,number,year,fek,fekId,description}]
function parseData(json) {
  const out = [];
  if (!json || !json.data) return out;
  let arr;
  try { arr = (typeof json.data === 'string') ? JSON.parse(json.data) : json.data; } catch (_) { return out; }
  if (!Array.isArray(arr)) return out;
  for (const r of arr) {
    const lawNo = r.search_LawProtocolNumber || null;
    const fekNo = r.search_DocumentNumber || null;
    const grp = String(r.search_IssueGroupID || '1');
    const label = (r.search_PrimaryLabel || '').trim();                 // "Α 30/2024"
    const desc = (r.search_Description || '').replace(/\s+/g, ' ').trim();
    const ym = label.match(/((?:19|20)\d{2})/) ||
      String(r.search_PublicationDate || r.search_IssueDate || '').match(/((?:19|20)\d{2})/);
    const year = ym ? parseInt(ym[1], 10) : null;
    // Publication date as ISO yyyy-mm-dd (the API gives mm/dd/yyyy) — the effective
    // date the consolidation applies the amendment from.
    let date = null;
    const dm = String(r.search_PublicationDate || r.search_IssueDate || '')
      .match(/(\d{1,2})\/(\d{1,2})\/((?:19|20)\d{2})/);
    if (dm) date = `${dm[3]}-${String(dm[1]).padStart(2, '0')}-${String(dm[2]).padStart(2, '0')}`;
    let url = '';
    if (fekNo && year) {
      const GG = grp.padStart(2, '0');
      const NNNNN = String(fekNo).padStart(5, '0');
      url = `${BLOB}/${GG}/${year}/${year}${GG}${NNNNN}.pdf`;           // deterministic blob PDF
    }
    out.push({
      title: desc ? `${desc} (Ν. ${lawNo}/${year}, ΦΕΚ ${label})` : `Ν. ${lawNo}/${year} (ΦΕΚ ${label})`,
      url,
      number: lawNo ? parseInt(lawNo, 10) : null,
      year,
      date,
      fek: label,
      fekId: r.search_ID || null,
      description: desc,
    });
  }
  return out;
}

if (require.main === module) (async () => {
  const { chromium } = require('playwright');
  const browser = await chromium.launch({
    headless: !process.env.FEK_HEADFUL,
    args: ['--no-sandbox', '--disable-dev-shm-usage', '--disable-blink-features=AutomationControlled'],
  });
  const dumps = [];
  try {
    const ctx = await browser.newContext({
      userAgent: UA, locale: 'el-GR', timezoneId: 'Europe/Athens',
      extraHTTPHeaders: { 'Accept-Language': 'el-GR,el;q=0.9,en;q=0.8' },
    });
    // Establish a real session (cookies/origin) the API call will reuse.
    const page = await ctx.newPage();
    page.setDefaultTimeout(TIMEOUT);
    await page.goto(SEARCH_URL, { waitUntil: 'domcontentloaded' }).catch(() => null);
    await page.waitForLoadState('networkidle').catch(() => {});

    const all = [];
    const seen = new Set();
    for (const year of YEARS) {
      const body = { legislationCatalogues: CATALOGUES, legislationNumber: NUMBER, selectYear: [String(year)] };
      let json = null;
      try {
        const resp = await ctx.request.post(API, {
          headers: {
            'content-type': 'application/json',
            origin: 'https://search.et.gr',
            referer: SEARCH_URL,
          },
          data: body,
          timeout: TIMEOUT,
        });
        const status = resp.status();
        json = await resp.json().catch(() => null);
        if (API_DUMP) dumps.push({ year, status, request: body, response: json });
        if (status !== 200) console.error(`discover-fek.js: year ${year} → HTTP ${status}`);
      } catch (e) {
        console.error(`discover-fek.js: year ${year} request failed: ${e && e.message}`);
      }
      const items = parseData(json);
      for (const it of items) {
        const key = (it.url || '') + '|' + it.number + '|' + it.year;
        if (seen.has(key)) continue;
        seen.add(key);
        all.push(it);
      }
      console.error(`discover-fek.js: year ${year} → ${items.length} record(s)`);
    }

    if (API_DUMP && dumps.length) {
      fs.mkdirSync(path.dirname(API_DUMP), { recursive: true });
      fs.writeFileSync(API_DUMP, JSON.stringify(dumps, null, 2));
    }
    emit(all);
    console.error(`discover-fek.js: ${all.length} unique entr${all.length === 1 ? 'y' : 'ies'} across ${YEARS.length} year(s)`);
    await browser.close();
    process.exit(0);
  } catch (e) {
    console.error('discover-fek.js error:', e && e.message);
    try { await browser.close(); } catch (_) { /* ignore */ }
    process.exit(1);
  }
})();

module.exports = { parseData };
