#!/usr/bin/env node
/* =============================================================================
 * fek-capture.js — capture the et.gr SEARCH API call (run on YOUR Greek IP).
 * =============================================================================
 * search.et.gr is a React SPA backed by a JSON API. The build sandbox gets 403;
 * you get 200. This opens a VISIBLE browser and logs EVERY data/API call the page
 * makes — its method, URL, and a snippet of the JSON body — regardless of host
 * (the API host can change). You perform ONE search in the window; the exact
 * search endpoint + result shape appear here, and I rebuild discovery to hit that
 * API directly (no browser, no form, no anti-bot).
 *
 *   node deployment/fek-capture.js [URL]
 *     URL default: https://search.et.gr/el/search-legislation/  (or FEK_URL env)
 *
 * → a Chrome window opens. Do ONE search (e.g. a recent law, or Τεύχος Α' 95/2019),
 *   click a result / its PDF. Watch this terminal — copy ALL the ">>>" blocks and
 *   send them to me. Window stays open ~5 min (CAPTURE_SECONDS to change), or close it.
 *   API_DUMP=path also writes every captured call (url+body) as JSON for tuning.
 * ============================================================================= */
'use strict';
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const START = process.argv[2] || process.env.FEK_URL || 'https://search.et.gr/el/search-legislation/';
const CAPTURE_MS = (parseInt(process.env.CAPTURE_SECONDS || '300', 10)) * 1000;
const API_DUMP = process.env.API_DUMP || '';

// What counts as a "data/API" call worth showing: a JSON content-type, or a URL
// that looks like an API/search/document endpoint — on ANY host (XHR/fetch only,
// so we skip the HTML/JS/CSS/image noise).
const URLY = /(\/api\/|search|fek|query|elastic|advanced|simple|result|document|download|legislation|nomos)/i;

(async () => {
  const browser = await chromium.launch({
    headless: false,                       // VISIBLE so you can search
    args: ['--no-sandbox', '--disable-blink-features=AutomationControlled', '--start-maximized'],
  });
  const ctx = await browser.newContext({ locale: 'el-GR', timezoneId: 'Europe/Athens', viewport: null });
  const page = await ctx.newPage();

  const seen = new Set();
  const dump = [];
  page.on('response', async (r) => {
    try {
      const u = r.url();
      const req = r.request();
      const rt = req.resourceType();             // xhr | fetch | document | script | …
      const ct = (r.headers()['content-type'] || '');
      const isData = (rt === 'xhr' || rt === 'fetch') && (/json/i.test(ct) || URLY.test(u));
      if (!isData) return;
      if (seen.has(u)) return; seen.add(u);
      let body = '';
      try { body = (await r.text()).slice(0, 2500); } catch (_) {}
      const post = (req.method() === 'POST') ? (req.postData() || '') : '';
      console.error(`\n>>> ${r.status()} ${req.method()} ${u}`);
      if (post) console.error('REQUEST BODY: ' + post.slice(0, 1500));
      if (body) console.error('RESPONSE: ' + body);
      if (API_DUMP) dump.push({ status: r.status(), method: req.method(), url: u, requestBody: post, body });
    } catch (_) { /* ignore */ }
  });

  console.error('\n============================================================');
  console.error(' Άνοιξε το παράθυρο. Κάνε ΜΙΑ αναζήτηση (π.χ. πρόσφατος νόμος, ή Τεύχος Α΄ 95/2019).');
  console.error(' Πάτησε ένα αποτέλεσμα / το PDF. Αντίγραψε ΟΛΑ τα ">>>" blocks από εδώ και στείλε τα.');
  console.error(' (Συλλαμβάνει ΚΑΘΕ data/API call, σε οποιονδήποτε host.)');
  console.error('============================================================\n');
  console.error(`START: ${START}\n`);

  await page.goto(START, { waitUntil: 'domcontentloaded' }).catch(() => {});

  await page.waitForTimeout(CAPTURE_MS).catch(() => {});
  if (API_DUMP && dump.length) {
    fs.mkdirSync(path.dirname(API_DUMP), { recursive: true });
    fs.writeFileSync(API_DUMP, JSON.stringify(dump, null, 2));
    console.error(`\nfek-capture.js: wrote ${dump.length} call(s) → ${API_DUMP}`);
  }
  await browser.close().catch(() => {});
})();
