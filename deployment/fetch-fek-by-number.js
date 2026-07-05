#!/usr/bin/env node
/* =============================================================================
 * fetch-fek-by-number.js — fetch a ΦΕΚ PDF from et.gr by its NUMBER (no scraping
 * of a hand-built URL). The config knows each code's ΦΕΚ (τεύχος/αριθμός/έτος),
 * so this drives the official search.et.gr itself: fill the search form, submit,
 * find the document's download link, and download it IN-SESSION (carrying the
 * anti-bot cookies). A real Chromium with a Greek-looking context — so it has a
 * real chance from a Greek IP, where datacenter IPs are blocked.
 *
 *   node fetch-fek-by-number.js <SERIES> <NUMBER> <YEAR> <OUT_PATH>
 *   e.g. node fetch-fek-by-number.js Α 95 2019 /app/input/poinikos.pdf
 *   env: FETCH_TIMEOUT (seconds, default 180), FEK_SEARCH_URL (override)
 *
 * Setup once on the host:  npm i -g playwright && npx playwright install --with-deps chromium
 *
 * NOTE: selectors for search.et.gr are best-effort heuristics (the form is a JS
 * SPA). If the layout changed, adjust the SELECTOR HEURISTICS block below — open
 * search.et.gr in a browser, inspect the number/year/issue inputs, and update.
 * A real CAPTCHA/Turnstile is, by design, not solvable here — that needs the
 * institutional feed. The Lisp core validates the %PDF magic afterwards.
 * ============================================================================= */
'use strict';
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const [SERIES, NUMBER, YEAR, OUT] = process.argv.slice(2);
const TIMEOUT = (parseInt(process.env.FETCH_TIMEOUT || '180', 10)) * 1000;
const SEARCH_URL = process.env.FEK_SEARCH_URL || 'https://search.et.gr/el/simple-search/';

const UA_POOL = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15',
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
];
const UA = process.env.FETCH_UA || UA_POOL[Math.floor(Math.random() * UA_POOL.length)];

if (!SERIES || !NUMBER || !YEAR || !OUT) {
  console.error('usage: fetch-fek-by-number.js <SERIES> <NUMBER> <YEAR> <OUT_PATH>');
  process.exit(2);
}

const isPdf = (buf) => buf && buf.length >= 5 && buf.slice(0, 5).toString('latin1') === '%PDF-';
const save = (buf) => { fs.mkdirSync(path.dirname(OUT), { recursive: true }); fs.writeFileSync(OUT, buf); };

(async () => {
  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-dev-shm-usage', '--disable-blink-features=AutomationControlled'],
  });
  try {
    const ctx = await browser.newContext({
      userAgent: UA, locale: 'el-GR', timezoneId: 'Europe/Athens',
      viewport: { width: 1366, height: 900 }, acceptDownloads: true,
      extraHTTPHeaders: { 'Accept-Language': 'el-GR,el;q=0.9,en;q=0.8' },
    });
    await ctx.addInitScript(() => {
      Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
      Object.defineProperty(navigator, 'languages', { get: () => ['el-GR', 'el', 'en'] });
      window.chrome = { runtime: {} };
    });
    const page = await ctx.newPage();
    page.setDefaultTimeout(TIMEOUT);
    await page.goto(SEARCH_URL, { waitUntil: 'domcontentloaded' }).catch(() => null);
    await page.waitForLoadState('networkidle').catch(() => {});

    // ---- SELECTOR HEURISTICS (adjust here if search.et.gr changed) -----------
    // Fill the three fields by matching label/placeholder/name text, robustly.
    const fill = async (keywords, value) => {
      const ok = await page.evaluate(({ keywords, value }) => {
        const norm = (s) => (s || '').toLowerCase();
        const inputs = [...document.querySelectorAll('input, select')];
        for (const el of inputs) {
          const hay = norm(el.name) + ' ' + norm(el.id) + ' ' + norm(el.placeholder) + ' ' +
                      norm(el.getAttribute('aria-label')) + ' ' +
                      norm((el.labels && el.labels[0] && el.labels[0].textContent) || '');
          if (keywords.some((k) => hay.includes(k))) {
            if (el.tagName === 'SELECT') {
              const opt = [...el.options].find((o) => norm(o.textContent).includes(value.toLowerCase()));
              if (opt) { el.value = opt.value; el.dispatchEvent(new Event('change', { bubbles: true })); return true; }
            } else {
              el.value = value;
              el.dispatchEvent(new Event('input', { bubbles: true }));
              el.dispatchEvent(new Event('change', { bubbles: true }));
              return true;
            }
          }
        }
        return false;
      }, { keywords, value }).catch(() => false);
      return ok;
    };
    await fill(['τεύχ', 'teuxos', 'issue', 'series'], SERIES);
    await fill(['αριθμ', 'number', 'fek', 'arithm'], String(NUMBER));
    await fill(['έτος', 'etos', 'year', 'χρον'], String(YEAR));
    // Submit: click a button/anchor whose text looks like "Αναζήτηση/Search".
    await page.evaluate(() => {
      const norm = (s) => (s || '').toLowerCase();
      const btn = [...document.querySelectorAll('button, input[type=submit], a')]
        .find((b) => /αναζ|search|υποβ|submit/.test(norm(b.textContent) + ' ' + norm(b.value)));
      if (btn) btn.click();
    }).catch(() => {});
    await page.waitForLoadState('networkidle').catch(() => {});
    // --------------------------------------------------------------------------

    // Find the download link in the results (DownloadFeksApi or a .pdf link) and
    // fetch it in-session so the anti-bot cookies are carried.
    const href = await page.evaluate(() => {
      const links = [...document.querySelectorAll('a[href]')];
      const a = links.find((x) => /DownloadFeksApi|\.pdf(\?|#|$)/i.test(x.href)) ||
                links.find((x) => /(λήψη|download|pdf|φεκ)/i.test((x.textContent || '') + ' ' + x.href));
      return a ? a.href : null;
    }).catch(() => null);

    if (href) {
      const arr = await page.evaluate(async (u) => {
        const r = await fetch(u, { credentials: 'include' });
        return Array.from(new Uint8Array(await r.arrayBuffer()));
      }, href).catch(() => null);
      const buf = arr ? Buffer.from(arr) : null;
      if (isPdf(buf)) { save(buf); console.log(`ok: ΦΕΚ ${SERIES} ${NUMBER}/${YEAR}`); await browser.close(); process.exit(0); }
      const [dl] = await Promise.all([
        page.waitForEvent('download', { timeout: TIMEOUT }).catch(() => null),
        page.click(`a[href="${href.replace(/"/g, '\\"')}"]`).catch(() => {}),
      ]);
      if (dl) { await dl.saveAs(OUT); if (isPdf(fs.readFileSync(OUT))) { console.log('ok: download'); await browser.close(); process.exit(0); } }
    }

    console.error(`fetch-fek-by-number.js: no PDF for ΦΕΚ ${SERIES} ${NUMBER}/${YEAR} ` +
                  `(anti-bot, or the search selectors need adjustment — see SELECTOR HEURISTICS).`);
    await browser.close();
    process.exit(1);
  } catch (e) {
    console.error('fetch-fek-by-number.js error:', e && e.message);
    try { await browser.close(); } catch (_) {}
    process.exit(1);
  }
})();
