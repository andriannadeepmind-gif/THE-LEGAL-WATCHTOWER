#!/usr/bin/env node
// Proof-Carrying Law (PCL-1) — independent public verifier (Node.js, builtin crypto only).
//
// A second, independent implementation. You do NOT trust StavropoulosLaw — you
// verify against our signed Merkle root yourself. Matches source/proof-carrying.lisp
// byte-for-byte.
//
// TRUST MODEL:
//   * `inclusion` proves a text is committed under the proof's OWN stated root —
//     a STRUCTURAL check, not proof of authenticity.
//   * `signature`/`full` prove authenticity ONLY against a PINNED key supplied
//     out-of-band (--key FILE | env PCL_TRUSTED_JWK | sibling pcl-public-key.jwk).
//     The key embedded in a proof is NEVER trusted (a forger can embed their own);
//     if present it must match the pinned key by RFC 7638 thumbprint. With no
//     pinned key, `signature`/`full` exit 3 (UNPINNED — not a trust anchor).
//
//   leaf      = "sha256:" + hex(SHA256( 0x00 ‖ UTF-8(text) ))      // RFC 6962 leaf
//   node(a,b) = "sha256:" + hex(SHA256( 0x01 ‖ raw(a) ‖ raw(b) ))  // RFC 6962 node
//
// Usage:
//   node verify.mjs [--key JWK] inclusion <article.proof.json> <text-file>
//   node verify.mjs [--key JWK] signature <corpus-proof.json>
//   node verify.mjs [--key JWK] full      <article.proof.json> <corpus-proof.json> <text-file>
// Exit: 0 authentic/consistent; 1 FAIL; 2 usage; 3 verified but UNPINNED key.

import { readFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { createHash, createPublicKey, verify as cryptoVerify } from "node:crypto";

const PREFIX = "sha256:";
const LEAF = Buffer.from([0x00]);
const NODE = Buffer.from([0x01]);
const MAX_PATH = 64;

const h = (domain, data) => PREFIX + createHash("sha256").update(Buffer.concat([domain, data])).digest("hex");
const leafHash = (text) => h(LEAF, Buffer.from(text, "utf8"));
const node = (a, b) =>
  h(NODE, Buffer.concat([Buffer.from(a.slice(PREFIX.length), "hex"), Buffer.from(b.slice(PREFIX.length), "hex")]));

export function verifyInclusion(text, proof) {
  const path = proof.path || [];
  if (path.length > MAX_PATH) return [false, "path-too-long"];
  const leaf = leafHash(text);
  if (leaf !== proof.leaf) return [false, "text-hash-mismatch"];
  let cur = leaf;
  for (const step of path) cur = step.side === "left" ? node(step.hash, cur) : node(cur, step.hash);
  if (cur !== proof.merkle_root) return [false, "inclusion-failed"];
  return [true, "ok"];
}

const b64url = (buf) => buf.toString("base64url");

function jwkThumbprint(jwk) {
  // RFC 7638: SHA-256 over {"e":..,"kty":"RSA","n":..} (lexicographic, no spaces).
  const canon = JSON.stringify({ e: jwk.e, kty: "RSA", n: jwk.n });
  return createHash("sha256").update(canon).digest("hex");
}

function sigCheck(corpus, jwk) {
  const root = corpus.merkle_root;
  const jws = corpus.signature;
  if (!jws) return [false, "unsigned-root"];
  const parts = jws.split(".");
  if (parts.length !== 3) return [false, "malformed-jws"];
  const [headerB64, , sigB64] = parts;
  let hdr;
  try { hdr = JSON.parse(Buffer.from(headerB64, "base64url").toString("utf8")); }
  catch { return [false, "malformed-header"]; }
  if (hdr.alg !== "RS256") return [false, "bad-alg"];
  const signingInput = Buffer.from(headerB64 + "." + b64url(Buffer.from(root, "utf8")), "ascii");
  const signature = Buffer.from(sigB64, "base64url");
  const key = createPublicKey({ key: { kty: "RSA", n: jwk.n, e: jwk.e }, format: "jwk" });
  return cryptoVerify("RSA-SHA256", signingInput, key, signature) ? [true, "ok"] : [false, "bad-signature"];
}

export function verifySignature(corpus, trusted) {
  const embedded = corpus.public_key;
  if (trusted) {
    if (embedded && jwkThumbprint(embedded) !== jwkThumbprint(trusted)) return [false, "untrusted-key", true];
    const [ok, reason] = sigCheck(corpus, trusted);
    return [ok, reason, true];
  }
  if (!embedded) return [false, "no-public-key", false];
  const [ok, reason] = sigCheck(corpus, embedded);
  return [ok, reason, false];
}

function resolveTrusted(keyArg) {
  const here = dirname(fileURLToPath(import.meta.url));
  const candidates = [keyArg, process.env.PCL_TRUSTED_JWK, join(here, "pcl-public-key.jwk")];
  for (const c of candidates) {
    if (!c) continue;
    try {
      if (typeof c === "string" && c.trim().startsWith("{")) return JSON.parse(c);
      if (existsSync(c)) return JSON.parse(readFileSync(c, "utf8"));
    } catch { /* try next */ }
  }
  return null;
}

const loadJson = (p) => JSON.parse(readFileSync(p, "utf8"));
const readText = (p) => readFileSync(p, "utf8");

function main(argv) {
  let args = argv.slice(2);
  let keyArg = null;
  if (args[0] === "--key" && args.length >= 2) { keyArg = args[1]; args = args.slice(2); }
  const cmd = args[0];
  const trusted = resolveTrusted(keyArg);

  if (cmd === "inclusion" && args.length === 3) {
    const [ok, reason] = verifyInclusion(readText(args[2]), loadJson(args[1]));
    if (ok) { console.log("OK  inclusion: structurally consistent (root UNVERIFIED — use 'full' with a pinned --key)"); process.exit(0); }
    process.stderr.write(`FAIL  inclusion: ${reason}\n`); process.exit(1);
  }

  let ok, reason, pinned;
  if (cmd === "signature" && args.length === 2) {
    [ok, reason, pinned] = verifySignature(loadJson(args[1]), trusted);
  } else if (cmd === "full" && args.length === 4) {
    const proof = loadJson(args[1]), corpus = loadJson(args[2]), text = readText(args[3]);
    const [iok, ireason] = verifyInclusion(text, proof);
    if (!iok) { process.stderr.write(`FAIL  full: ${ireason}\n`); process.exit(1); }
    if (proof.merkle_root !== corpus.merkle_root) { process.stderr.write("FAIL  full: root-mismatch\n"); process.exit(1); }
    [ok, reason, pinned] = verifySignature(corpus, trusted);
  } else {
    process.stderr.write("usage: verify.mjs [--key JWK] <inclusion|signature|full> …\n");
    process.exit(2);
  }

  if (ok && pinned) { console.log(`OK  ${cmd}: AUTHENTIC — signed by the pinned root authority (${reason})`); process.exit(0); }
  if (ok && !pinned) {
    process.stderr.write(`WARN  ${cmd}: signature is internally consistent but NO trusted key was pinned — NOT proof of authenticity. Supply --key / PCL_TRUSTED_JWK / pcl-public-key.jwk.\n`);
    process.exit(3);
  }
  process.stderr.write(`FAIL  ${cmd}: ${reason}\n`); process.exit(1);
}

if (import.meta.url === `file://${process.argv[1]}`) main(process.argv);
