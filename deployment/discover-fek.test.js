#!/usr/bin/env node
/* discover-fek.test.js — lock the et.gr searchlegislation response → listing mapping.
 * Run: node deployment/discover-fek.test.js   (no network; pure parse of a real payload) */
'use strict';
const assert = require('assert');
const { parseData } = require('./discover-fek.js');

let pass = 0;
const ok = (name, cond) => { assert.ok(cond, name); pass++; console.log('  ok   ' + name); };

// The exact record the live API returned for Ν. 5090/2024 (data is a JSON STRING).
const records = [{
  search_ID: '762228', search_DocumentNumber: '30', search_IssueGroupID: '1',
  search_IssueDate: '02/23/2024 00:00:00', search_PublicationDate: '02/24/2024 00:00:00',
  search_PrimaryLabel: 'Α 30/2024', search_LawProtocolNumber: '5090',
  search_Description: 'ΠΑΡΕΜΒΑΣΕΙΣ ΣΤΟΝ ΠΟΙΝΙΚΟ ΚΩΔΙΚΑ ΚΑΙ ΤΟΝ ΚΩΔΙΚΑ ΠΟΙΝΙΚΗΣ ΔΙΚΟΝΟΜΙΑΣ',
}];
const out = parseData({ status: 'ok', data: JSON.stringify(records) });

ok('one entry parsed', out.length === 1);
ok('law number → routing key', out[0].number === 5090);
ok('year parsed from label', out[0].year === 2024);
ok('deterministic ΦΕΚ blob URL built',
  out[0].url === 'https://ia37rg02wpsa01.blob.core.windows.net/fek/01/2024/20240100030.pdf');
ok('description carried for the router', /ΠΟΙΝΙΚΟ ΚΩΔΙΚΑ/.test(out[0].title) && /ΠΟΙΝΙΚΗΣ ΔΙΚΟΝΟΜΙΑΣ/.test(out[0].title));
ok('fekId kept', out[0].fekId === '762228');

// Robust to junk / empty.
ok('empty data → []', parseData({ status: 'ok', data: '[]' }).length === 0);
ok('missing data → []', parseData({ status: 'ok' }).length === 0);
ok('null → []', parseData(null).length === 0);
ok('data as real array (not string) also works',
  parseData({ status: 'ok', data: records }).length === 1);

// A Β-τεύχος (group 2) maps to /02/ and pads the ΦΕΚ number.
const b = parseData({ status: 'ok', data: JSON.stringify([{
  search_DocumentNumber: '7', search_IssueGroupID: '2', search_PrimaryLabel: 'Β 7/2023',
  search_LawProtocolNumber: '123', search_Description: 'δοκιμή',
}]) });
ok('Β-τεύχος → /02/ and 5-digit pad', b[0].url === 'https://ia37rg02wpsa01.blob.core.windows.net/fek/02/2023/20230200007.pdf');

console.log(`\ndiscover-fek parse tests: ${pass} passed, 0 failed`);
process.exit(0);
