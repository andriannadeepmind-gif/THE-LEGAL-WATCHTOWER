#!/usr/bin/env node
// verify_b.mjs — MLTP v3 executable-reference VERIFIER B.
// Backend: Node built-in node:crypto (OpenSSL 3.5.5). Independent of Verifier A
// (Go, pure-Go crypto/ed25519). Shares ONLY schemas.json + fixtures with A — no
// verification code is shared. Fail-closed: if the crypto backend cannot verify,
// emits CRYPTO_BACKEND_UNAVAILABLE and never accepts a signature.
//
// Usage: node verify_b.mjs <bundle.json> <lts.json> <keys.json> [schemas.json]
// Prints one JSON line: {"verifier":"B","result":...,"reason":...,"certified_results":[...]}
// Exit 0 always (the verdict is in the JSON; run.sh compares verdicts).

import { readFileSync } from "node:fs";
import { createHash, createPublicKey, verify as edVerify } from "node:crypto";

const RESULT_ORDER = ["UNVERIFIED_FOR_MACHINE_RELIANCE", "UNVERIFIED_FOR_ATTRIBUTED_RELIANCE", "UNKNOWN", "VERIFIED"];
const US = "\x1f";

// ---- independent canonical JSON (RFC 8785 JCS, no booleans in hash-bearing) ----
function canon(v) {
  if (v === null) return "null";
  if (v === true || v === false) throw { mltp: "malformed-envelope" };  // spec §1.6
  if (typeof v === "number") {
    if (!Number.isInteger(v)) throw { mltp: "malformed-envelope" };     // spec §1.5
    return String(v);
  }
  if (typeof v === "string") return cstr(v);
  if (Array.isArray(v)) return "[" + v.map(canon).join(",") + "]";
  if (typeof v === "object") {
    const keys = Object.keys(v).sort();
    return "{" + keys.map(k => cstr(k) + ":" + canon(v[k])).join(",") + "}";
  }
  throw { mltp: "malformed-envelope" };
}
const ESC = { '"': '\\"', "\\": "\\\\", "\b": "\\b", "\f": "\\f", "\n": "\\n", "\r": "\\r", "\t": "\\t" };
function cstr(s) {
  let out = '"';
  for (const ch of s) {
    if (ESC[ch] !== undefined) out += ESC[ch];
    else if (ch.codePointAt(0) < 0x20) out += "\\u" + ch.codePointAt(0).toString(16).padStart(4, "0");
    else out += ch;
  }
  return out + '"';
}
const sha256hex = (buf) => createHash("sha256").update(buf).digest("hex");
function idHash2(domain, body) { return sha256hex(Buffer.concat([Buffer.from(domain + US, "utf8"), Buffer.from(canon(body), "utf8")])); }

// ---- merkle lawmax-merkle-sha256-v1 --------------------------------------------
const PREFIX = "sha256:";
const mh = (dom, data) => PREFIX + createHash("sha256").update(Buffer.concat([dom, data])).digest("hex");
const leafOf = (buf) => mh(Buffer.from([0x00]), buf);
const nodeOf = (a, b) => mh(Buffer.from([0x01]), Buffer.concat([Buffer.from(a.slice(PREFIX.length), "hex"), Buffer.from(b.slice(PREFIX.length), "hex")]));
function lpow2(n) { let k = 1; while (k * 2 < n) k *= 2; return k; }
function mth(leaves) {
  if (leaves.length === 0) return PREFIX + createHash("sha256").update(Buffer.alloc(0)).digest("hex");
  if (leaves.length === 1) return leaves[0];
  const k = lpow2(leaves.length);
  return nodeOf(mth(leaves.slice(0, k)), mth(leaves.slice(k)));
}
function inclOk(leaf, path, root) {
  let cur = leaf;
  for (const s of path) cur = s.side === "left" ? nodeOf(s.hash, cur) : nodeOf(cur, s.hash);
  return cur === root;
}
function digestOf(obj) { return PREFIX + sha256hex(Buffer.from(canon(obj), "utf8")); }

// ---- vetted Ed25519 verify (OpenSSL via node:crypto) ---------------------------
let BACKEND_OK = true;
function b64uToBuf(s) { return Buffer.from(s.replace(/-/g, "+").replace(/_/g, "/"), "base64"); }
function edKeyFromX(xb64u) {
  const raw = b64uToBuf(xb64u);
  if (raw.length !== 32) return null;
  const spki = Buffer.concat([Buffer.from("302a300506032b6570032100", "hex"), raw]);
  try { return createPublicKey({ key: spki, format: "der", type: "spki" }); } catch { return null; }
}
function sigVerify(xb64u, context, objNoSig, sigb64u) {
  const key = edKeyFromX(xb64u);
  if (!key) return "malformed-key";
  const sig = b64uToBuf(sigb64u);
  if (sig.length !== 64) return "bad-length";
  let msg;
  try { msg = Buffer.concat([Buffer.from(context + US, "utf8"), Buffer.from(canon(objNoSig), "utf8")]); }
  catch { return "malformed-envelope"; }
  let ok;
  try { ok = edVerify(null, msg, key, sig); }
  catch { BACKEND_OK = false; return "backend"; }
  return ok ? "ok" : "bad";
}


// ---- C1.1 profile manifest pinning -------------------------------------------
function sha256hexBytes(buf){ return createHash("sha256").update(buf).digest("hex"); }
function verifyProfile(profile, schemasBytes, schemas, lts){
  // returns "ok" | "untrusted-profile"
  try{
    const owner = lts.owner_root;
    if(!profile || profile.layer!=="MLTPProfileManifest") return "untrusted-profile";
    if(profile.profile_id!=="mltp3-executable-reference/1") return "untrusted-profile";
    if(profile.owner_kid!==owner.kid) return "untrusted-profile";
    const noSig={...profile}; delete noSig.sig;
    if(sigVerify(owner.x,"mltp3:profile-manifest",noSig,profile.sig)!=="ok") return "untrusted-profile";
    if(profile.schemas_sha256!==sha256hexBytes(schemasBytes)) return "untrusted-profile";
    if(profile.signature_contexts_digest!==sha256hexBytes(Buffer.from(canon([...schemas.sig_contexts].sort()),"utf8"))) return "untrusted-profile";
    if(profile.id_domains_digest!==sha256hexBytes(Buffer.from(canon(schemas.id_domains),"utf8"))) return "untrusted-profile";
    if(Number(profile.min_verifier_version) > Number(schemas.profile_manifest.verifier_version)) return "untrusted-profile";
    if(profile.error_taxonomy_version!=="1"||profile.qualification_policy_version!=="1") return "untrusted-profile";
    if(profile.revoked==="true") return "untrusted-profile";
    const now=lts.trusted_now;
    if(now<profile.activation||now>profile.expiry) return "untrusted-profile";
    return "ok";
  }catch(e){ return "untrusted-profile"; }
}

// ---- verification --------------------------------------------------------------
function verify(bundle, lts, TAX, overrideCap) {
  const results = [];
  if (overrideCap) results.push({ result: "UNKNOWN", reason: "profile-override-active" });                    // list of {result,reason}
  const push = (reason) => results.push({ result: TAX[reason] || "UNVERIFIED_FOR_MACHINE_RELIANCE", reason });
  const crOut = [];

  const keyByKid = {};
  for (const k of bundle.keys) keyByKid[k.kid] = k;
  const owner = lts.owner_root;

  // K0 owner root pinned
  if (bundle.owner_kid !== owner.kid) return final([{ result: "UNVERIFIED_FOR_MACHINE_RELIANCE", reason: "untrusted-root" }], crOut);

  // helper: verify a signed object via a resolved public x
  function att(xb64u, context, obj) {
    const noSig = { ...obj }; delete noSig.sig; delete noSig.signature; delete noSig.signers;
    // For objects carrying `signature`, the signed body includes signer fields but not sig.
    let body = noSig;
    if (obj.signature) { body = { ...obj }; body.signature = undefined; delete body.signature; }
    const r = sigVerify(xb64u, context, obj.signature ? stripSig(obj) : noSig, (obj.sig || (obj.signature && obj.signature.sig)));
    return r;
  }
  function stripSig(o) { const c = JSON.parse(JSON.stringify(o)); delete c.signature; return c; }

  // K1 delegations root-signed; build delegation table
  const deleg = {};
  for (const d of bundle.delegations) {
    const noSig = { ...d }; delete noSig.sig;
    const r = sigVerify(owner.x, "mltp3:delegation", noSig, d.sig);
    if (r === "backend") return backendFail(crOut);
    if (r !== "ok") { push("delegation-invalid"); continue; }
    const kobj = keyByKid[d.delegate_kid];
    if (!kobj || kobj.x !== d.delegate_x) { push("key-binding-mismatch"); continue; }
    deleg[d.delegate_kid] = d;
  }

  // revocation lookup (by subject kid) with invalid_from
  const revoked = {};
  for (const rs of (bundle.revocation_statements || [])) {
    const noSig = { ...rs }; delete noSig.sig;
    const r = sigVerify(owner.x, "mltp3:revocation", noSig, rs.sig);
    if (r === "ok") revoked[rs.revoked_subject] = rs.invalid_from;
  }

  // time attestation lookup by target sig imprint
  const taByImprint = {};
  for (const ta of bundle.time_attestations) {
    const noSig = { ...ta }; delete noSig.sig;
    if (!lts.registries.tsa.includes(ta.tsa_kid)) { continue; }
    const kx = keyByKid[ta.tsa_kid];
    if (!kx) continue;
    const r = sigVerify(kx.x, "mltp3:time-attestation", noSig, ta.sig);
    if (r === "backend") return backendFail(crOut);
    if (r === "ok") taByImprint[ta.target_sig_imprint] = ta;
  }

  // t_sig upper bound from a claim/result's signature via detached TA
  function tSigBound(rawSigB64) {
    const imprint = PREFIX + sha256hex(b64uToBuf(rawSigB64));
    const ta = taByImprint[imprint];
    if (!ta) return { err: "no-trusted-signature-time" };
    return { bound: ta.gen_time + ta.accuracy_seconds };
  }

  // scope + window + revocation check for an issuer signature
  function issuerOk(kidUsed, scopeToken, rawSigB64, purposeReason) {
    const d = deleg[kidUsed];
    if (!d) return "untrusted-key";
    if (!d.scopes.includes(scopeToken)) return "delegation-scope-violation";
    const tb = tSigBound(rawSigB64);
    if (tb.err) return tb.err;
    if (tb.bound < d.not_before || tb.bound > d.not_after) return "delegation-expired";
    if (revoked[kidUsed] !== undefined && tb.bound >= revoked[kidUsed]) return "retroactively-revoked";
    return "ok";
  }

  // ---- claims ----
  const claimResult = {};
  const CLOSED = new Set(SCHEMAS.claim_types);
  const FORBIDDEN_CLAIM_KEYS = ["claim_id", "signature", "signer", "signed_at", "release_root", "release_ref", "inclusion_proof"];
  for (const c of bundle.issued_claims) {
    let rr = "ok";
    const body = { mltp: c.mltp, claim_type: c.claim_type, schema_id: c.schema_id, payload: c.payload, proof_material: c.proof_material };
    // schema / envelope
    const ALLOWED_CLAIM = new Set(["mltp","claim_type","schema_id","payload","proof_material","claim_id","signer","signature"]);
    if (!CLOSED.has(c.claim_type)) rr = "unknown-claim-type";
    else if (c.schema_id !== "mltp3/" + c.claim_type + "/1") rr = "schema-mismatch";
    else {
      for (const k of Object.keys(c)) if (!ALLOWED_CLAIM.has(k)) rr = "schema-mismatch";  // forbids signed_at/release_root/inclusion in the signed envelope
      try { canon(body); } catch { rr = "malformed-envelope"; }
    }
    // self-referential id: does the id-preimage body contain the id value anywhere?
    if (rr === "ok") {
      let expect;
      try { expect = "clm1:" + idHash2("mltp3:claim-id", body); } catch { rr = "malformed-envelope"; }
      if (rr === "ok") {
        if (containsValue(body, c.claim_id)) rr = "self-referential-id";
        else if (c.claim_id !== expect) rr = "id-mismatch";
      }
    }
    // signature (verify_attestation)
    if (rr === "ok") {
      const kobj = keyByKid[c.signature.kid];
      if (!kobj) rr = "untrusted-key";
      else {
        const signed = { ...c }; delete signed.signature;
        const r = sigVerify(kobj.x, "mltp3:issued-claim", signed, c.signature.sig);
        if (r === "backend") return backendFail(crOut);
        if (r === "malformed-key") rr = "key-binding-mismatch";
        else if (r === "bad-length") rr = "sig-invalid";
        else if (r !== "ok") rr = "sig-invalid";
        else {
          const scope = "issued-claim:" + c.claim_type;
          rr = issuerOk(c.signature.kid, scope, c.signature.sig, "claim");
        }
      }
    }
    // inclusion in release_root
    if (rr === "ok") {
      const relRoot = bundle.release_attestation.release_root;
      const ip = bundle.inclusion_proofs.find(p => p.claim_id === c.claim_id);
      if (!ip) rr = "inclusion-failed";
      else if (ip.release_root !== relRoot) rr = "root-mismatch";
      else if (ip.leaf !== leafOf(Buffer.from(c.claim_id, "utf8"))) rr = "inclusion-failed";
      else if (!inclOk(ip.leaf, ip.path, relRoot)) rr = "inclusion-failed";
    }
    // treatment verbs (correction #15)
    if (rr === "ok" && c.claim_type === "judgment-identity-and-text") {
      for (const rel of (c.proof_material.legal_relations || [])) {
        if (!SCHEMAS.legal_relation_verbs.parser_certifiable.includes(rel.verb)) {
          if (!rel.reviewer_adoption) { rr = "misrepresented-treatment"; break; }
        }
      }
    }
    claimResult[c.claim_id] = rr;
    if (rr !== "ok") push(rr);
  }

  // ---- release attestation ----
  {
    const ra = bundle.release_attestation;
    const noSig = { ...ra }; delete noSig.sig;
    const kobj = keyByKid[ra.signer.kid];
    let rr = "ok";
    if (!kobj) rr = "untrusted-key";
    else {
      const r = sigVerify(kobj.x, "mltp3:release-root", noSig, ra.sig);
      if (r === "backend") return backendFail(crOut);
      if (r !== "ok") rr = "sig-invalid";
      else rr = issuerOk(ra.signer.kid, "release-signing", ra.sig, "release");
    }
    if (rr === "ok") {
      const ids = bundle.issued_claims.map(c => c.claim_id).sort();
      const root = mth(ids.map(i => leafOf(Buffer.from(i, "utf8"))));
      if (root !== ra.release_root) rr = "root-mismatch";
    }
    if (rr !== "ok") push(rr);
  }

  // ---- coverage index ----
  const coverage = {};
  for (const c of bundle.issued_claims) if (c.claim_type === "coverage-and-freshness" && claimResult[c.claim_id] === "ok") coverage[c.claim_id] = c;

  // ---- certified results ----
  const relRoot = bundle.release_attestation.release_root;
  for (const cr of bundle.certified_results) {
    let rr = "ok";
    const body = { mltp: cr.mltp, layer: cr.layer, answer: cr.answer, citation: cr.citation, citation_digest: cr.citation_digest, release_ref: cr.release_ref };
    for (const bad of ["result_id", "signature", "signer", "signed_at"]) if (bad in body) rr = "schema-mismatch";
    // result/bundle cycle: body must not embed bundle_id
    if (rr === "ok" && containsValue(body, bundle.bundle_id)) rr = "result-bundle-cycle";
    if (rr === "ok") {
      let expect; try { expect = "res1:" + idHash2("mltp3:result-id", body); } catch { rr = "malformed-envelope"; }
      if (rr === "ok") {
        if (containsValue(body, cr.result_id)) rr = "self-referential-id";
        else if (cr.result_id !== expect) rr = "id-mismatch";
      }
    }
    if (rr === "ok") {
      const kobj = keyByKid[cr.signature.kid];
      if (!kobj) rr = "untrusted-key";
      else {
        const signed = { ...cr }; delete signed.signature;
        const r = sigVerify(kobj.x, "mltp3:certified-result", signed, cr.signature.sig);
        if (r === "backend") return backendFail(crOut);
        if (r !== "ok") rr = "sig-invalid";
        else rr = issuerOk(cr.signature.kid, "certified-result", cr.signature.sig, "result");
      }
    }
    // full-answer verification (correction #7)
    if (rr === "ok") {
      const a = cr.answer;
      if (a.release_root !== relRoot) rr = "answer-incomplete";
      else if (!a.derivation_proof || a.counterproof === undefined) rr = "answer-incomplete";
      else {
        for (const dep of a.dependency_set) {
          if (claimResult[dep] === undefined) { rr = "dependency-unverified"; break; }
          if (claimResult[dep] !== "ok") { rr = "dependency-unverified"; break; }
        }
      }
    }
    // coverage binding + freshness (correction #11)
    if (rr === "ok") {
      const cov = coverage[cr.answer.coverage_ref];
      if (!cov) rr = "coverage-missing";
      else {
        const known = cov.payload.known_time;
        if (lts.trusted_now - known > 3650 * 86400) rr = "coverage-stale"; // demo freshness budget
      }
    }
    // citation binding (correction #8) -> UFAR class
    let citReason = "ok";
    if (rr === "ok") {
      const cit = cr.citation;
      if (digestOf(cit) !== cr.citation_digest) citReason = "citation-unbound";
      else if (!cr.answer.dependency_set.includes(cit.claim_id)) citReason = "citation-unbound";
      else if (!cit.watchtower_release_uri.includes(relRoot)) citReason = "citation-unbound";
      else if (!lts.trusted_citation_policies.includes(cit.citation_policy_id)) citReason = "citation-policy-untrusted";
      else if (!(cit.attribution_text.includes("ΦΕΚ") || cit.attribution_text.includes("Δημοκρατία")) ||
               !cit.attribution_text.includes("LEGAL WATCHTOWER OF GREECE")) citReason = "citation-incomplete-dual";
      else {
        // CitationToken verifies
        const tok = (bundle.citation_tokens || []).find(t => t.result_id === cr.result_id);
        if (!tok) citReason = "citation-unbound";
        else {
          const kobj = keyByKid[tok.signer.kid];
          const r = kobj ? sigVerify(kobj.x, "mltp3:citation", { citation: tok.citation, result_id: tok.result_id }, tok.sig) : "bad";
          if (r === "backend") return backendFail(crOut);
          if (r !== "ok" || digestOf(tok.citation) !== cr.citation_digest) citReason = "citation-unbound";
        }
      }
    }
    let crResult;
    if (rr !== "ok") { crResult = TAX[rr]; push(rr); }
    else if (citReason !== "ok") { crResult = TAX[citReason]; push(citReason); }
    else crResult = "VERIFIED";
    crOut.push({ result_id: cr.result_id, result: crResult, reason: rr !== "ok" ? rr : citReason,
                 citation_bound: (rr === "ok" && citReason === "ok") ? "true" : "false" });
  }

  // ---- compiler independence (correction #12) ----
  {
    const cas = bundle.compiler_attestations || [];
    if (cas.length >= 2) {
      const [x, y] = cas;
      let ok = true;
      for (const ca of cas) {
        const noSig = { ...ca }; delete noSig.sig;
        const kobj = keyByKid[ca.signer.kid];
        const r = kobj ? sigVerify(kobj.x, "mltp3:compiler-attestation", noSig, ca.sig) : "bad";
        if (r === "backend") return backendFail(crOut);
        if (r !== "ok") { push("sig-invalid"); ok = false; }
      }
      if (ok) {
        if (x.input_journal_root !== y.input_journal_root) push("compiler-divergence");
        else if (x.output_root !== y.output_root) push("compiler-divergence");
        else if (x.compiler_family_id === y.compiler_family_id || x.source_digest === y.source_digest || x.signer.kid === y.signer.kid)
          push("fabricated-compiler-independence");
      }
    }
  }

  // ---- provider conformance (correction #9) ----
  for (const pc of (bundle.provider_conformance || [])) {
    const noSig = { ...pc }; delete noSig.sig;
    if (!lts.registries.provider.includes(pc.provider_kid)) { push("provider-subject-mismatch"); continue; }
    const kobj = keyByKid[pc.provider_kid];
    const r = kobj ? sigVerify(kobj.x, "mltp3:provider-conformance", noSig, pc.sig) : "bad";
    if (r === "backend") return backendFail(crOut);
    if (r !== "ok") { push("provider-subject-mismatch"); continue; }
    if (pc.expiry < lts.trusted_now) push("provider-nonconformant");
  }

  // ---- QSR (mechanism: issuer-disjoint, quorum, subject binding) ----
  for (const q of (bundle.qualification_records || [])) {
    let rr = "ok";
    if (q.subject.release_root !== relRoot) rr = "qualification-subject-mismatch";
    const issuerKeys = new Set([owner.kid, ...Object.keys(deleg)]);
    const seen = new Set();
    if (rr === "ok") {
      for (const s of q.signers) {
        if (issuerKeys.has(s.kid)) { rr = "unauthorized-qualification-issuer"; break; }
        if (!lts.registries.auditor.includes(s.kid)) { rr = "unauthorized-qualification-issuer"; break; }
        const kobj = keyByKid[s.kid];
        const body = { ...q }; delete body.signers;
        const r = kobj ? sigVerify(kobj.x, "mltp3:qual-state", body, s.sig) : "bad";
        if (r === "backend") return backendFail(crOut);
        if (r !== "ok") { rr = "unauthorized-qualification-issuer"; break; }
        seen.add(s.kid);
      }
      if (rr === "ok" && seen.size < 2) rr = "unauthorized-qualification-issuer";
    }
    if (rr !== "ok") push(rr);
  }

  // ---- revocation checkpoint (correction #5) ----
  {
    const cp = bundle.revocation_checkpoint;
    let rr = "ok";
    const body = { ...cp }; delete body.signers;
    const signers = new Set();
    for (const s of (cp.signers || [])) {
      if (!lts.registries.witness.includes(s.kid)) continue;
      const kobj = keyByKid[s.kid];
      const r = kobj ? sigVerify(kobj.x, "mltp3:witness-checkpoint", body, s.sig) : "bad";
      if (r === "backend") return backendFail(crOut);
      if (r === "ok") signers.add(s.kid);
    }
    if (signers.size < 2) rr = "unsigned-revocation-checkpoint";
    else if (cp.tree_size < (lts.last_revocation_checkpoint ? lts.last_revocation_checkpoint.tree_size : 0)) rr = "nonmonotonic-revocation-state";
    else if (lts.trusted_now - cp.checkpoint_at > lts.max_revocation_staleness_seconds) rr = "stale-revocation-state";
    else {
      // every revocation statement in the bundle must be included in the checkpoint tree
      const included = new Set((cp.revocations || []).map(r => r.statement_id));
      for (const rs of (bundle.revocation_statements || [])) {
        const rid = "rev1:" + idHash2("mltp3:revocation-id", stripSigObj(rs));
        if (!included.has(rid)) { rr = "omitted-revocation"; break; }
      }
      // and each included revocation's inclusion proof must verify against log_root
      if (rr === "ok") for (const r of (cp.revocations || [])) {
        if (!inclOk(r.inclusion.leaf, r.inclusion.path, cp.log_root)) { rr = "omitted-revocation"; break; }
      }
    }
    if (rr !== "ok") push(rr);
  }

  // ---- bundle_id acyclic recompute ----
  {
    const expect = "bnd1:" + idHash2("mltp3:bundle-id", bundle.manifest);
    if (containsValue(bundle.manifest, bundle.bundle_id)) push("self-referential-id");
    else if (bundle.bundle_id !== expect) push("id-mismatch");
  }

  return final(results.length ? results : [{ result: "VERIFIED", reason: "ok" }], crOut);
}

function stripSigObj(o) { const c = { ...o }; delete c.sig; return c; }
function containsValue(obj, val) {
  if (obj === val) return true;
  if (Array.isArray(obj)) return obj.some(x => containsValue(x, val));
  if (obj && typeof obj === "object") return Object.values(obj).some(x => containsValue(x, val));
  return false;
}
function minResult(list) {
  let idx = RESULT_ORDER.length - 1, reason = "ok";
  for (const r of list) { const i = RESULT_ORDER.indexOf(r.result); if (i < idx) { idx = i; reason = r.reason; } }
  return { result: RESULT_ORDER[idx], reason };
}
function final(list, crOut) { const m = minResult(list); return { verifier: "B", result: m.result, reason: m.reason, certified_results: crOut }; }
function backendFail(crOut) { return { verifier: "B", result: "UNVERIFIED_FOR_MACHINE_RELIANCE", reason: "CRYPTO_BACKEND_UNAVAILABLE", certified_results: crOut }; }

let SCHEMAS, TAX;
function main() {
  const [bundleP, ltsP, keysP, schemasP, profileP] = process.argv.slice(2);
  const bundle = JSON.parse(readFileSync(bundleP, "utf8"));
  const lts = JSON.parse(readFileSync(ltsP, "utf8"));
  const schemasPath = schemasP || new URL("./schemas.json", import.meta.url);
  const schemasBytes = readFileSync(schemasPath);
  SCHEMAS = JSON.parse(schemasBytes.toString("utf8"));
  TAX = SCHEMAS.error_taxonomy;
  const profilePath = profileP || new URL("./fixtures/profile.json", import.meta.url);
  let profile = null;
  try { profile = JSON.parse(readFileSync(profilePath, "utf8")); } catch { profile = null; }
  const pr = verifyProfile(profile, schemasBytes, SCHEMAS, lts);
  const devOverride = process.env.MLTP_DEV_OVERRIDE === "1";
  let out;
  if (pr !== "ok" && !devOverride) {
    out = { verifier: "B", result: "UNVERIFIED_FOR_MACHINE_RELIANCE", reason: "untrusted-profile", certified_results: [] };
  } else {
    try { out = verify(bundle, lts, TAX, pr !== "ok"); }
    catch (e) { out = { verifier: "B", result: "UNVERIFIED_FOR_MACHINE_RELIANCE", reason: (e && e.mltp) || "malformed-envelope", certified_results: [] }; }
  }
  process.stdout.write(JSON.stringify(out) + "\n");
}
main();
