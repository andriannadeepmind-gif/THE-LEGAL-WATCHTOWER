#!/usr/bin/env node
/* =============================================================================
 * fek-diagnose.js — one-shot diagnostic for search.et.gr (run on YOUR Greek IP).
 * =============================================================================
 * I (the build sandbox) get 403 from et.gr, so I cannot see the search form.
 * This opens the page in a real Chromium and prints everything I need to fix the
 * fetcher: the network API calls the SPA makes, the form fields, any CAPTCHA/
 * challenge, and a screenshot. Send me the console output + say what fek-debug.png
 * shows.
 *
 *   node deployment/fek-diagnose.js
 *   env: FEK_URL (default https://search.et.gr/el/fek/), FEK_HEADFUL=1 to watch
 * ============================================================================= */
'use strict';
const { chromium } = require('playwright');

const URL = process.env.FEK_URL || 'https://search.et.gr/el/fek/';
const HEADFUL = process.env.FEK_HEADFUL === '1';

(async () => {
  const browser = await chromium.launch({
    headless: !HEADFUL,
    args: ['--no-sandbox', '--disable-blink-features=AutomationControlled'],
  });
  const ctx = await browser.newContext({
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    locale: 'el-GR', timezoneId: 'Europe/Athens', viewport: { width: 1366, height: 900 },
  });
  await ctx.addInitScript(() => {
    Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
    window.chrome = { runtime: {} };
  });
  const page = await ctx.newPage();

  // 1) Capture interesting network calls (the SPA's search API is the gold).
  const api = [];
  page.on('response', (r) => {
    const u = r.url();
    if (/api|search|fek|download|elastic|query/i.test(u)) api.push(`${r.status()}  ${r.request().method()}  ${u}`);
  });

  console.error(`\n=== opening ${URL} ===`);
  const resp = await page.goto(URL, { waitUntil: 'domcontentloaded', timeout: 60000 }).catch((e) => { console.error('goto error:', e.message); return null; });
  await page.waitForLoadState('networkidle').catch(() => {});

  // 2) Page identity + challenge detection.
  console.error('STATUS:', resp ? resp.status() : 'n/a');
  console.error('FINAL URL:', page.url());
  console.error('TITLE:', await page.title().catch(() => '?'));
  const bodyText = (await page.evaluate(() => document.body ? document.body.innerText.slice(0, 600) : '').catch(() => '')) || '';
  const challenge = /captcha|cloudflare|verify you are human|είστε άνθρωπος|δεν είστε ρομπότ|turnstile|recaptcha/i.test(bodyText);
  console.error('CHALLENGE/CAPTCHA detected:', challenge ? 'YES ⚠' : 'no');

  // 3) Form fields (so I can fix the selectors).
  const fields = await page.evaluate(() =>
    [...document.querySelectorAll('input, select, textarea')].map((el) => ({
      tag: el.tagName, type: el.type || '', name: el.name || '', id: el.id || '',
      placeholder: el.placeholder || '', ariaLabel: el.getAttribute('aria-label') || '',
      label: (el.labels && el.labels[0] && el.labels[0].textContent.trim()) || '',
    }))).catch(() => []);
  console.error(`\n=== FORM FIELDS (${fields.length}) ===`);
  fields.forEach((f, i) => console.error(`  [${i}] <${f.tag} type=${f.type}> name="${f.name}" id="${f.id}" placeholder="${f.placeholder}" aria="${f.ariaLabel}" label="${f.label}"`));

  // 4) Buttons (so I know how to submit).
  const buttons = await page.evaluate(() =>
    [...document.querySelectorAll('button, input[type=submit], a[role=button]')].map((b) => (b.textContent || b.value || '').trim()).filter(Boolean).slice(0, 25)
  ).catch(() => []);
  console.error('\n=== BUTTONS ===\n  ' + buttons.join(' | '));

  // 5) The network API calls (the most useful — a clean search API beats forms).
  console.error('\n=== NETWORK (api/search/fek/download) ===');
  if (api.length) api.forEach((a) => console.error('  ' + a)); else console.error('  (none captured)');

  await page.screenshot({ path: 'fek-debug.png', fullPage: true }).catch(() => {});
  console.error('\n=== screenshot → fek-debug.png (πες μου τι δείχνει) ===');

  if (!HEADFUL) await browser.close();
})();
