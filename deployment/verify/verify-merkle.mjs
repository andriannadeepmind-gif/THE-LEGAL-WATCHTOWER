#!/usr/bin/env node
// MERKLE-SINGLE-TRUTH — independent Node conformance verifier (builtin crypto only).
//
// A THIRD, independent implementation of the canonical profile
// `lawmax-merkle-sha256-v1` (RFC 9162 §2.1.1). Deliberately NOT generated from
// shared code — N-version diversity is the defence against a bug in one
// implementation. Only the DATA (golden vectors) is shared.
//
// Usage: node verify-merkle.mjs [vectors.json]
// Exit:  0 = every vector matches; 1 = ANY divergence; 2 = usage/IO error.

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { createHash } from "node:crypto";

const PREFIX = "sha256:";
const LEAF = Buffer.from([0x00]);
const NODE = Buffer.from([0x01]);

const h = (domain, data) =>
  PREFIX + createHash("sha256").update(Buffer.concat([domain, data])).digest("hex");

const leafHashBytes = (buf) => h(LEAF, buf);

const node = (a, b) =>
  h(NODE, Buffer.concat([
    Buffer.from(a.slice(PREFIX.length), "hex"),
    Buffer.from(b.slice(PREFIX.length), "hex"),
  ]));

function largestPowerOfTwoBelow(n) {          // k < n <= 2k
  let k = 1;
  while (k * 2 < n) k *= 2;
  return k;
}

function mth(leaves) {
  if (leaves.length === 0) return PREFIX + createHash("sha256").update(Buffer.alloc(0)).digest("hex");
  if (leaves.length === 1) return leaves[0];
  const k = largestPowerOfTwoBelow(leaves.length);
  return node(mth(leaves.slice(0, k)), mth(leaves.slice(k)));   // NEVER duplicate-last
}

// Profile rule: leaf data for index i = ASCII bytes of decimal i.
const treeLeaves = (n) =>
  Array.from({ length: n }, (_, i) => leafHashBytes(Buffer.from(String(i), "ascii")));

function verifyInclusion(leaf, path, root) {
  let cur = leaf;
  // side = position of the SIBLING relative to the running hash (same as
  // verify.mjs and source/merkle-authority.lisp): "left" => node(sib, cur).
  for (const step of path) cur = step.side === "left" ? node(step.hash, cur) : node(cur, step.hash);
  return cur === root;
}

// RFC 9162 §2.1.3.1 PATH(m, D[n]) — INDEPENDENT construction outside the Lisp
// TCB (not just fold-verification): the emitted path must be the canonical RFC
// path, element for element.
function pathGen(m, lo, hi, leaves) {
  const n = hi - lo;
  if (n === 1) return [];
  const k = largestPowerOfTwoBelow(n);
  if (m < k)
    return [...pathGen(m, lo, lo + k, leaves),
            { side: "right", hash: mth(leaves.slice(lo + k, hi)) }];
  return [...pathGen(m - k, lo + k, hi, leaves),
          { side: "left", hash: mth(leaves.slice(lo, lo + k)) }];
}

// RFC 9162 §2.1.4.1 PROOF(m, D[n]) = SUBPROOF(m, D[n], true) — independent
// construction of the consistency proof itself.
function proofGen(m, leaves) {
  const sub = (m, lo, hi, complete) => {
    const n = hi - lo;
    if (m === n) return complete ? [] : [mth(leaves.slice(lo, hi))];
    const k = largestPowerOfTwoBelow(n);
    if (m <= k) return [...sub(m, lo, lo + k, complete), mth(leaves.slice(lo + k, hi))];
    return [...sub(m - k, lo + k, hi, false), mth(leaves.slice(lo, lo + k))];
  };
  return m === leaves.length ? [] : sub(m, 0, leaves.length, true);
}

const samePath = (a, b) =>
  a.length === b.length && a.every((s, i) => s.side === b[i].side && s.hash === b[i].hash);
const sameProof = (a, b) => a.length === b.length && a.every((h, i) => h === b[i]);

function verifyConsistency(m, n, oldRoot, newRoot, proof) {
  if (m < 1 || m > n) return false;
  if (m === n) return proof.length === 0 && oldRoot === newRoot;
  let path = [...proof];
  if (path.length === 0) return false;
  if ((m & (m - 1)) === 0) path = [oldRoot, ...path];   // m an exact power of two
  let fn = m - 1, sn = n - 1;
  while (fn & 1) { fn >>= 1; sn >>= 1; }
  let fr = path[0], sr = path[0];
  for (const c of path.slice(1)) {
    if (sn === 0) return false;
    if ((fn & 1) || fn === sn) {
      fr = node(c, fr);
      sr = node(c, sr);
      while (fn !== 0 && (fn & 1) === 0) { fn >>= 1; sn >>= 1; }
    } else {
      sr = node(sr, c);
    }
    fn >>= 1; sn >>= 1;
  }
  return sn === 0 && fr === oldRoot && sr === newRoot;
}

function main(argv) {
  const here = dirname(fileURLToPath(import.meta.url));
  const path = argv[2] || join(here, "vectors", "merkle", "vectors.json");
  let v;
  try { v = JSON.parse(readFileSync(path, "utf8")); }
  catch (e) { process.stderr.write(`::error::vectors unreadable: ${e}\n`); process.exit(2); }

  let ok = 0, failed = 0;
  const check = (name, cond) => { if (cond) ok++; else { failed++; console.log(`  FAIL ${name}`); } };

  check("profile id", v.profile === "lawmax-merkle-sha256-v1");
  check("empty tree root", mth([]) === v.empty_tree_root);

  for (const lv of v.leaves)
    check(`leaf ${lv.id}`, leafHashBytes(Buffer.from(lv.input_hex, "hex")) === lv.leaf);

  for (const t of v.trees) check(`root n=${t.n}`, mth(treeLeaves(t.n)) === t.root);

  for (const inc of v.inclusion) {
    const leaves = treeLeaves(inc.n);
    check(`inclusion n=${inc.n} i=${inc.index}`,
      leaves[inc.index] === inc.leaf &&
      verifyInclusion(inc.leaf, inc.path, inc.root) &&
      mth(leaves) === inc.root);
    check(`inclusion PATH-gen n=${inc.n} i=${inc.index}`,
      samePath(pathGen(inc.index, 0, inc.n, leaves), inc.path));
  }

  for (const c of v.consistency) {
    check(`consistency n=${c.n} m=${c.m}`,
      verifyConsistency(c.m, c.n, c.old_root, c.new_root, c.proof));
    check(`consistency PROOF-gen n=${c.n} m=${c.m}`,
      sameProof(proofGen(c.m, treeLeaves(c.n)), c.proof));
  }

  v.differential.roots.forEach((expected, i) => {
    const n = v.differential.from + i;
    check(`differential n=${n}`, mth(treeLeaves(n)) === expected);
  });

  console.log(`── verify-merkle.mjs: ${ok} ok, ${failed} FAIL ──`);
  process.exit(failed ? 1 : 0);
}

main(process.argv);
