#!/usr/bin/env node
/* =============================================================================
 * fetch-fek.js — robust real-browser fetcher for ΦΕΚ / et.gr (anti-bot bypass).
 * =============================================================================
 * The effective way past anti-bot is to BE a real browser: a genuine Chromium
 * with a realistic context (UA, viewport, locale el-GR, Athens timezone),
 * automation signals masked, that navigates the page, waits for the JS to settle,
 * finds the PDF, and downloads it WITHIN the authenticated session (carrying the
 * cookies the anti-bot set). The Lisp core validates the %PDF magic afterwards,
 * so anything that is not a real PDF is rejected upstream.
 *
 *   node fetch-fek.js <SOURCE_URL> <OUT_PATH>
 *   env: FETCH_TIMEOUT (seconds, default 120)
 *
 * Setup once on the host:
 *   npm i -g playwright   &&   npx playwright install --with-deps chromium
 *
 * NOTE: a real CAPTCHA / Cloudflare-Turnstile challenge is, by design, not
 * solvable by automation — that path needs the institutional ΦΕΚ feed/agreement.
 * ============================================================================= */
'use strict';
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const URL = process.argv[2];
const OUT = process.argv[3];
const TIMEOUT = (parseInt(process.env.FETCH_TIMEOUT || '120', 10)) * 1000;

// Rotate the User-Agent: honour FETCH_UA (set by fetch-fek.sh per attempt),
// otherwise pick one at random from a pool of current desktop browsers.
const UA_POOL = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36 Edg/123.0.0.0',
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
];
const UA = process.env.FETCH_UA || UA_POOL[Math.floor(Math.random() * UA_POOL.length)];
// jitter the viewport a little so the fingerprint is not identical across runs
const VIEWPORT = { width: 1280 + Math.floor(Math.random() * 200), height: 800 + Math.floor(Math.random() * 160) };

if (!URL || !OUT) { console.error('usage: fetch-fek.js <SOURCE_URL> <OUT_PATH>'); process.exit(2); }

const isPdf = (buf) => buf && buf.length >= 5 && buf.slice(0, 5).toString('latin1') === '%PDF-';
const save = (buf) => { fs.mkdirSync(path.dirname(OUT), { recursive: true }); fs.writeFileSync(OUT, buf); };

(async () => {
  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-dev-shm-usage', '--disable-blink-features=AutomationControlled'],
  });
  try {
    const ctx = await browser.newContext({
      userAgent: UA,
      locale: 'el-GR',
      timezoneId: 'Europe/Athens',
      viewport: VIEWPORT,
      acceptDownloads: true,
      extraHTTPHeaders: { 'Accept-Language': 'el-GR,el;q=0.9,en;q=0.8' },
    });
    // mask the usual automation tells
    await ctx.addInitScript(() => {
      Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
      Object.defineProperty(navigator, 'languages', { get: () => ['el-GR', 'el', 'en'] });
      Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3, 4, 5] });
      window.chrome = { runtime: {} };
    });
    const page = await ctx.newPage();
    page.setDefaultTimeout(TIMEOUT);

    // 1) direct navigation: the response itself may be the PDF
    const resp = await page.goto(URL, { waitUntil: 'domcontentloaded' }).catch(() => null);
    if (resp && (resp.headers()['content-type'] || '').includes('pdf')) {
      const buf = await resp.body();
      if (isPdf(buf)) { save(buf); console.log('ok: direct pdf response'); await browser.close(); process.exit(0); }
    }
    await page.waitForLoadState('networkidle').catch(() => {});

    // 2) find the PDF link on the page, fetch it IN-SESSION (cookies carried)
    const pdfHref = await page.evaluate(() => {
      const links = [...document.querySelectorAll('a[href]')];
      const a = links.find((x) => /\.pdf(\?|#|$)/i.test(x.href)) ||
                links.find((x) => /(λήψη|download|pdf|φεκ)/i.test((x.textContent || '') + ' ' + x.href));
      return a ? a.href : null;
    }).catch(() => null);

    if (pdfHref) {
      const arr = await page.evaluate(async (href) => {
        const r = await fetch(href, { credentials: 'include' });
        return Array.from(new Uint8Array(await r.arrayBuffer()));
      }, pdfHref).catch(() => null);
      const buf = arr ? Buffer.from(arr) : null;
      if (isPdf(buf)) { save(buf); console.log('ok: in-session fetch'); await browser.close(); process.exit(0); }

      // 3) otherwise click it and capture the download
      const [dl] = await Promise.all([
        page.waitForEvent('download', { timeout: TIMEOUT }).catch(() => null),
        page.click(`a[href="${pdfHref.replace(/"/g, '\\"')}"]`).catch(() => {}),
      ]);
      if (dl) {
        await dl.saveAs(OUT);
        if (isPdf(fs.readFileSync(OUT))) { console.log('ok: click download'); await browser.close(); process.exit(0); }
      }
    }

    console.error('fetch-fek.js: no PDF obtained (anti-bot challenge or no PDF on page)');
    await browser.close();
    process.exit(1);
  } catch (e) {
    console.error('fetch-fek.js error:', e && e.message);
    try { await browser.close(); } catch (_) { /* ignore */ }
    process.exit(1);
  }
})();
