// verify_a.go — MLTP v3 executable-reference VERIFIER A.
// Backend: Go standard library crypto/ed25519 (pure Go, filippo.io/edwards25519 —
// NOT OpenSSL). Independent of Verifier B (Node, node:crypto/OpenSSL). Shares ONLY
// schemas.json + fixtures with B; no verification code is shared.
// Fail-closed: no fallback ever accepts a signature. Same typed error vocabulary.
//
// Usage: go run verify_a.go <bundle.json> <lts.json> <keys.json> <schemas.json>
// Prints one JSON line: {"verifier":"A","result":...,"reason":...,"certified_results":[...]}
package main

import (
	"crypto/ed25519"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"strings"
)

const US = "\x1f"
const PREFIX = "sha256:"

var resultOrder = []string{"UNVERIFIED_FOR_MACHINE_RELIANCE", "UNVERIFIED_FOR_ATTRIBUTED_RELIANCE", "UNKNOWN", "VERIFIED"}

type mltpErr struct{ name string }

func (e mltpErr) Error() string { return e.name }

// ---- canonical JSON (RFC 8785 JCS, no booleans in hash-bearing records) --------
func canon(v interface{}) (string, error) {
	switch t := v.(type) {
	case nil:
		return "null", nil
	case bool:
		return "", mltpErr{"malformed-envelope"} // spec §1.6
	case json.Number:
		s := t.String()
		if strings.ContainsAny(s, ".eE") {
			return "", mltpErr{"malformed-envelope"} // spec §1.5 (no floats)
		}
		return s, nil
	case string:
		return cstr(t), nil
	case []interface{}:
		parts := make([]string, len(t))
		for i, x := range t {
			s, err := canon(x)
			if err != nil {
				return "", err
			}
			parts[i] = s
		}
		return "[" + strings.Join(parts, ",") + "]", nil
	case map[string]interface{}:
		keys := make([]string, 0, len(t))
		for k := range t {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		parts := make([]string, 0, len(keys))
		for _, k := range keys {
			s, err := canon(t[k])
			if err != nil {
				return "", err
			}
			parts = append(parts, cstr(k)+":"+s)
		}
		return "{" + strings.Join(parts, ",") + "}", nil
	default:
		return "", mltpErr{"malformed-envelope"}
	}
}

func cstr(s string) string {
	var b strings.Builder
	b.WriteByte('"')
	for _, ch := range s {
		switch ch {
		case '"':
			b.WriteString("\\\"")
		case '\\':
			b.WriteString("\\\\")
		case '\b':
			b.WriteString("\\b")
		case '\f':
			b.WriteString("\\f")
		case '\n':
			b.WriteString("\\n")
		case '\r':
			b.WriteString("\\r")
		case '\t':
			b.WriteString("\\t")
		default:
			if ch < 0x20 {
				b.WriteString(fmt.Sprintf("\\u%04x", ch))
			} else {
				b.WriteRune(ch)
			}
		}
	}
	b.WriteByte('"')
	return b.String()
}

func sha256hex(b []byte) string { h := sha256.Sum256(b); return hex.EncodeToString(h[:]) }

func idHash(domain string, body interface{}) (string, error) {
	c, err := canon(body)
	if err != nil {
		return "", err
	}
	return sha256hex(append([]byte(domain+US), []byte(c)...)), nil
}

func digestOf(obj interface{}) (string, error) {
	c, err := canon(obj)
	if err != nil {
		return "", err
	}
	return PREFIX + sha256hex([]byte(c)), nil
}

// ---- merkle lawmax-merkle-sha256-v1 --------------------------------------------
func mh(dom byte, data []byte) string {
	h := sha256.Sum256(append([]byte{dom}, data...))
	return PREFIX + hex.EncodeToString(h[:])
}
func leafOf(b []byte) string { return mh(0x00, b) }
func nodeOf(a, b string) string {
	ra, _ := hex.DecodeString(a[len(PREFIX):])
	rb, _ := hex.DecodeString(b[len(PREFIX):])
	return mh(0x01, append(ra, rb...))
}
func lpow2(n int) int {
	k := 1
	for k*2 < n {
		k *= 2
	}
	return k
}
func mth(leaves []string) string {
	if len(leaves) == 0 {
		h := sha256.Sum256(nil)
		return PREFIX + hex.EncodeToString(h[:])
	}
	if len(leaves) == 1 {
		return leaves[0]
	}
	k := lpow2(len(leaves))
	return nodeOf(mth(leaves[:k]), mth(leaves[k:]))
}
func inclOk(leaf string, path []interface{}, root string) bool {
	cur := leaf
	for _, ps := range path {
		s := ps.(map[string]interface{})
		if s["side"] == "left" {
			cur = nodeOf(s["hash"].(string), cur)
		} else {
			cur = nodeOf(cur, s["hash"].(string))
		}
	}
	return cur == root
}

// ---- vetted Ed25519 (Go stdlib) ------------------------------------------------
func b64u(s string) []byte {
	b, err := base64.RawURLEncoding.DecodeString(strings.TrimRight(s, "="))
	if err != nil {
		return nil
	}
	return b
}

// returns "ok" | "bad" | "malformed-key" | "bad-length" | "malformed-envelope"
func sigVerify(xb64u, context string, objNoSig interface{}, sigb64u string) string {
	raw := b64u(xb64u)
	if len(raw) != 32 {
		return "malformed-key"
	}
	sig := b64u(sigb64u)
	if len(sig) != 64 {
		return "bad-length"
	}
	c, err := canon(objNoSig)
	if err != nil {
		return "malformed-envelope"
	}
	msg := append([]byte(context+US), []byte(c)...)
	if ed25519.Verify(ed25519.PublicKey(raw), msg, sig) {
		return "ok"
	}
	return "bad"
}

// ---- helpers -------------------------------------------------------------------
func containsValue(obj interface{}, val string) bool {
	switch t := obj.(type) {
	case string:
		return t == val
	case []interface{}:
		for _, x := range t {
			if containsValue(x, val) {
				return true
			}
		}
	case map[string]interface{}:
		for _, x := range t {
			if containsValue(x, val) {
				return true
			}
		}
	}
	return false
}

func stripKey(m map[string]interface{}, key string) map[string]interface{} {
	out := map[string]interface{}{}
	for k, v := range m {
		if k != key {
			out[k] = v
		}
	}
	return out
}

func asMap(v interface{}) map[string]interface{} { m, _ := v.(map[string]interface{}); return m }
func asSlice(v interface{}) []interface{}         { s, _ := v.([]interface{}); return s }
func asStr(v interface{}) string                  { s, _ := v.(string); return s }
func numLeq(a interface{}, b int64) bool          { return toInt(a) <= b }
func toInt(v interface{}) int64 {
	if n, ok := v.(json.Number); ok {
		i, _ := n.Int64()
		return i
	}
	return 0
}
func strInSlice(s string, arr []interface{}) bool {
	for _, x := range arr {
		if asStr(x) == s {
			return true
		}
	}
	return false
}

type res struct{ result, reason string }

var TAX map[string]interface{}
var SCH map[string]interface{}

func tax(reason string) string {
	if r, ok := TAX[reason]; ok {
		return asStr(r)
	}
	return "UNVERIFIED_FOR_MACHINE_RELIANCE"
}

func loadJSON(path string) interface{} {
	f, err := os.Open(path)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	defer f.Close()
	dec := json.NewDecoder(f)
	dec.UseNumber()
	var v interface{}
	if err := dec.Decode(&v); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	return v
}

func main() {
	args := os.Args[1:]
	bundle := asMap(loadJSON(args[0]))
	lts := asMap(loadJSON(args[1]))
	_ = args[2] // keys.json (kids also present in bundle.keys); parity with Verifier B signature
	SCH = asMap(loadJSON(args[3]))
	TAX = asMap(SCH["error_taxonomy"])

	out := verify(bundle, lts)
	b, _ := json.Marshal(out)
	fmt.Println(string(b))
}

type output struct {
	Verifier         string                   `json:"verifier"`
	Result           string                   `json:"result"`
	Reason           string                   `json:"reason"`
	CertifiedResults []map[string]interface{} `json:"certified_results"`
}

func verify(bundle, lts map[string]interface{}) output {
	var results []res
	crOut := []map[string]interface{}{}
	push := func(reason string) { results = append(results, res{tax(reason), reason}) }
	fin := func() output {
		idx := len(resultOrder) - 1
		reason := "ok"
		for _, r := range results {
			for i, name := range resultOrder {
				if name == r.result && i < idx {
					idx = i
					reason = r.reason
				}
			}
		}
		if len(results) == 0 {
			return output{"A", "VERIFIED", "ok", crOut}
		}
		return output{"A", resultOrder[idx], reason, crOut}
	}

	keyByKid := map[string]map[string]interface{}{}
	for _, k := range asSlice(bundle["keys"]) {
		km := asMap(k)
		keyByKid[asStr(km["kid"])] = km
	}
	owner := asMap(lts["owner_root"])
	regs := asMap(lts["registries"])

	if asStr(bundle["owner_kid"]) != asStr(owner["kid"]) {
		return output{"A", "UNVERIFIED_FOR_MACHINE_RELIANCE", "untrusted-root", crOut}
	}

	// delegations
	deleg := map[string]map[string]interface{}{}
	for _, dv := range asSlice(bundle["delegations"]) {
		d := asMap(dv)
		r := sigVerify(asStr(owner["x"]), "mltp3:delegation", stripKey(d, "sig"), asStr(d["sig"]))
		if r != "ok" {
			push("delegation-invalid")
			continue
		}
		kobj := keyByKid[asStr(d["delegate_kid"])]
		if kobj == nil || asStr(kobj["x"]) != asStr(d["delegate_x"]) {
			push("key-binding-mismatch")
			continue
		}
		deleg[asStr(d["delegate_kid"])] = d
	}

	// revocations
	revoked := map[string]int64{}
	for _, rv := range asSlice(bundle["revocation_statements"]) {
		rs := asMap(rv)
		if sigVerify(asStr(owner["x"]), "mltp3:revocation", stripKey(rs, "sig"), asStr(rs["sig"])) == "ok" {
			revoked[asStr(rs["revoked_subject"])] = toInt(rs["invalid_from"])
		}
	}

	// time attestations by imprint
	taByImprint := map[string]map[string]interface{}{}
	tsaReg := asSlice(regs["tsa"])
	for _, tv := range asSlice(bundle["time_attestations"]) {
		ta := asMap(tv)
		if !strInSlice(asStr(ta["tsa_kid"]), tsaReg) {
			continue
		}
		kx := keyByKid[asStr(ta["tsa_kid"])]
		if kx == nil {
			continue
		}
		if sigVerify(asStr(kx["x"]), "mltp3:time-attestation", stripKey(ta, "sig"), asStr(ta["sig"])) == "ok" {
			taByImprint[asStr(ta["target_sig_imprint"])] = ta
		}
	}
	tSigBound := func(rawSigB64 string) (int64, string) {
		imprint := PREFIX + sha256hex(b64u(rawSigB64))
		ta := taByImprint[imprint]
		if ta == nil {
			return 0, "no-trusted-signature-time"
		}
		return toInt(ta["gen_time"]) + toInt(ta["accuracy_seconds"]), ""
	}
	issuerOk := func(kidUsed, scope, rawSigB64 string) string {
		d := deleg[kidUsed]
		if d == nil {
			return "untrusted-key"
		}
		if !strInSlice(scope, asSlice(d["scopes"])) {
			return "delegation-scope-violation"
		}
		bound, e := tSigBound(rawSigB64)
		if e != "" {
			return e
		}
		if bound < toInt(d["not_before"]) || bound > toInt(d["not_after"]) {
			return "delegation-expired"
		}
		if iv, ok := revoked[kidUsed]; ok && bound >= iv {
			return "retroactively-revoked"
		}
		return "ok"
	}

	closed := map[string]bool{}
	for _, ct := range asSlice(SCH["claim_types"]) {
		closed[asStr(ct)] = true
	}
	parserVerbs := asSlice(asMap(SCH["legal_relation_verbs"])["parser_certifiable"])

	relRoot := asStr(asMap(bundle["release_attestation"])["release_root"])
	claimResult := map[string]string{}

	for _, cv := range asSlice(bundle["issued_claims"]) {
		c := asMap(cv)
		rr := "ok"
		body := map[string]interface{}{"mltp": c["mltp"], "claim_type": c["claim_type"],
			"schema_id": c["schema_id"], "payload": c["payload"], "proof_material": c["proof_material"]}
		if !closed[asStr(c["claim_type"])] {
			rr = "unknown-claim-type"
		} else if asStr(c["schema_id"]) != "mltp3/"+asStr(c["claim_type"])+"/1" {
			rr = "schema-mismatch"
		} else {
			allowed := map[string]bool{"mltp": true, "claim_type": true, "schema_id": true, "payload": true, "proof_material": true, "claim_id": true, "signer": true, "signature": true}
			for k := range c {
				if !allowed[k] {
					rr = "schema-mismatch"
				}
			}
			if _, err := canon(body); err != nil {
				rr = "malformed-envelope"
			}
		}
		if rr == "ok" {
			expect, err := idHash("mltp3:claim-id", body)
			if err != nil {
				rr = "malformed-envelope"
			} else if containsValue(body, asStr(c["claim_id"])) {
				rr = "self-referential-id"
			} else if asStr(c["claim_id"]) != "clm1:"+expect {
				rr = "id-mismatch"
			}
		}
		if rr == "ok" {
			sigm := asMap(c["signature"])
			kobj := keyByKid[asStr(sigm["kid"])]
			if kobj == nil {
				rr = "untrusted-key"
			} else {
				r := sigVerify(asStr(kobj["x"]), "mltp3:issued-claim", stripKey(c, "signature"), asStr(sigm["sig"]))
				if r == "malformed-key" {
					rr = "key-binding-mismatch"
				} else if r != "ok" {
					rr = "sig-invalid"
				} else {
					rr = issuerOk(asStr(sigm["kid"]), "issued-claim:"+asStr(c["claim_type"]), asStr(sigm["sig"]))
				}
			}
		}
		if rr == "ok" {
			var ip map[string]interface{}
			for _, pv := range asSlice(bundle["inclusion_proofs"]) {
				if asStr(asMap(pv)["claim_id"]) == asStr(c["claim_id"]) {
					ip = asMap(pv)
				}
			}
			if ip == nil {
				rr = "inclusion-failed"
			} else if asStr(ip["release_root"]) != relRoot {
				rr = "root-mismatch"
			} else if asStr(ip["leaf"]) != leafOf([]byte(asStr(c["claim_id"]))) {
				rr = "inclusion-failed"
			} else if !inclOk(asStr(ip["leaf"]), asSlice(ip["path"]), relRoot) {
				rr = "inclusion-failed"
			}
		}
		if rr == "ok" && asStr(c["claim_type"]) == "judgment-identity-and-text" {
			for _, rlv := range asSlice(asMap(c["proof_material"])["legal_relations"]) {
				rel := asMap(rlv)
				if !strInSlice(asStr(rel["verb"]), parserVerbs) {
					if _, ok := rel["reviewer_adoption"]; !ok {
						rr = "misrepresented-treatment"
						break
					}
				}
			}
		}
		claimResult[asStr(c["claim_id"])] = rr
		if rr != "ok" {
			push(rr)
		}
	}

	// release attestation
	{
		ra := asMap(bundle["release_attestation"])
		rr := "ok"
		sigm := asMap(ra["signer"])
		kobj := keyByKid[asStr(sigm["kid"])]
		if kobj == nil {
			rr = "untrusted-key"
		} else if sigVerify(asStr(kobj["x"]), "mltp3:release-root", stripKey(ra, "sig"), asStr(ra["sig"])) != "ok" {
			rr = "sig-invalid"
		} else {
			rr = issuerOk(asStr(sigm["kid"]), "release-signing", asStr(ra["sig"]))
		}
		if rr == "ok" {
			var ids []string
			for _, cv := range asSlice(bundle["issued_claims"]) {
				ids = append(ids, asStr(asMap(cv)["claim_id"]))
			}
			sort.Strings(ids)
			var leaves []string
			for _, id := range ids {
				leaves = append(leaves, leafOf([]byte(id)))
			}
			if mth(leaves) != asStr(ra["release_root"]) {
				rr = "root-mismatch"
			}
		}
		if rr != "ok" {
			push(rr)
		}
	}

	// coverage
	coverage := map[string]map[string]interface{}{}
	for _, cv := range asSlice(bundle["issued_claims"]) {
		c := asMap(cv)
		if asStr(c["claim_type"]) == "coverage-and-freshness" && claimResult[asStr(c["claim_id"])] == "ok" {
			coverage[asStr(c["claim_id"])] = c
		}
	}
	trustedNow := toInt(lts["trusted_now"])
	trustedPolicies := asSlice(lts["trusted_citation_policies"])

	// certified results
	for _, crv := range asSlice(bundle["certified_results"]) {
		cr := asMap(crv)
		rr := "ok"
		body := map[string]interface{}{"mltp": cr["mltp"], "layer": cr["layer"], "answer": cr["answer"],
			"citation": cr["citation"], "citation_digest": cr["citation_digest"], "release_ref": cr["release_ref"]}
		for _, bad := range []string{"result_id", "signature", "signer", "signed_at"} {
			if _, ok := body[bad]; ok {
				rr = "schema-mismatch"
			}
		}
		if rr == "ok" && containsValue(body, asStr(bundle["bundle_id"])) {
			rr = "result-bundle-cycle"
		}
		if rr == "ok" {
			expect, err := idHash("mltp3:result-id", body)
			if err != nil {
				rr = "malformed-envelope"
			} else if containsValue(body, asStr(cr["result_id"])) {
				rr = "self-referential-id"
			} else if asStr(cr["result_id"]) != "res1:"+expect {
				rr = "id-mismatch"
			}
		}
		if rr == "ok" {
			sigm := asMap(cr["signature"])
			kobj := keyByKid[asStr(sigm["kid"])]
			if kobj == nil {
				rr = "untrusted-key"
			} else if sigVerify(asStr(kobj["x"]), "mltp3:certified-result", stripKey(cr, "signature"), asStr(sigm["sig"])) != "ok" {
				rr = "sig-invalid"
			} else {
				rr = issuerOk(asStr(sigm["kid"]), "certified-result", asStr(sigm["sig"]))
			}
		}
		if rr == "ok" {
			a := asMap(cr["answer"])
			if asStr(a["release_root"]) != relRoot {
				rr = "answer-incomplete"
			} else if asStr(a["derivation_proof"]) == "" || a["counterproof"] == nil {
				rr = "answer-incomplete"
			} else {
				for _, dv := range asSlice(a["dependency_set"]) {
					st, ok := claimResult[asStr(dv)]
					if !ok || st != "ok" {
						rr = "dependency-unverified"
						break
					}
				}
			}
		}
		if rr == "ok" {
			a := asMap(cr["answer"])
			cov := coverage[asStr(a["coverage_ref"])]
			if cov == nil {
				rr = "coverage-missing"
			} else if trustedNow-toInt(asMap(cov["payload"])["known_time"]) > int64(3650)*86400 {
				rr = "coverage-stale"
			}
		}
		citReason := "ok"
		if rr == "ok" {
			cit := asMap(cr["citation"])
			cd, _ := digestOf(cit)
			a := asMap(cr["answer"])
			if cd != asStr(cr["citation_digest"]) {
				citReason = "citation-unbound"
			} else if !strInSlice(asStr(cit["claim_id"]), asSlice(a["dependency_set"])) {
				citReason = "citation-unbound"
			} else if !strings.Contains(asStr(cit["watchtower_release_uri"]), relRoot) {
				citReason = "citation-unbound"
			} else if !strInSlice(asStr(cit["citation_policy_id"]), trustedPolicies) {
				citReason = "citation-policy-untrusted"
			} else {
				at := asStr(cit["attribution_text"])
				if (!strings.Contains(at, "ΦΕΚ") && !strings.Contains(at, "Δημοκρατία")) || !strings.Contains(at, "LEGAL WATCHTOWER OF GREECE") {
					citReason = "citation-incomplete-dual"
				} else {
					var tok map[string]interface{}
					for _, tv := range asSlice(bundle["citation_tokens"]) {
						if asStr(asMap(tv)["result_id"]) == asStr(cr["result_id"]) {
							tok = asMap(tv)
						}
					}
					if tok == nil {
						citReason = "citation-unbound"
					} else {
						kobj := keyByKid[asStr(asMap(tok["signer"])["kid"])]
						tobj := map[string]interface{}{"citation": tok["citation"], "result_id": tok["result_id"]}
						r := "bad"
						if kobj != nil {
							r = sigVerify(asStr(kobj["x"]), "mltp3:citation", tobj, asStr(tok["sig"]))
						}
						td, _ := digestOf(tok["citation"])
						if r != "ok" || td != asStr(cr["citation_digest"]) {
							citReason = "citation-unbound"
						}
					}
				}
			}
		}
		var crResult, crReason string
		if rr != "ok" {
			crResult, crReason = tax(rr), rr
			push(rr)
		} else if citReason != "ok" {
			crResult, crReason = tax(citReason), citReason
			push(citReason)
		} else {
			crResult, crReason = "VERIFIED", "ok"
		}
		bound := "false"
		if rr == "ok" && citReason == "ok" {
			bound = "true"
		}
		crOut = append(crOut, map[string]interface{}{"result_id": cr["result_id"], "result": crResult, "reason": crReason, "citation_bound": bound})
	}

	// compiler independence
	cas := asSlice(bundle["compiler_attestations"])
	if len(cas) >= 2 {
		x, y := asMap(cas[0]), asMap(cas[1])
		ok := true
		for _, cav := range cas {
			ca := asMap(cav)
			kobj := keyByKid[asStr(asMap(ca["signer"])["kid"])]
			r := "bad"
			if kobj != nil {
				r = sigVerify(asStr(kobj["x"]), "mltp3:compiler-attestation", stripKey(ca, "sig"), asStr(ca["sig"]))
			}
			if r != "ok" {
				push("sig-invalid")
				ok = false
			}
		}
		if ok {
			if asStr(x["input_journal_root"]) != asStr(y["input_journal_root"]) || asStr(x["output_root"]) != asStr(y["output_root"]) {
				push("compiler-divergence")
			} else if asStr(x["compiler_family_id"]) == asStr(y["compiler_family_id"]) ||
				asStr(x["source_digest"]) == asStr(y["source_digest"]) ||
				asStr(asMap(x["signer"])["kid"]) == asStr(asMap(y["signer"])["kid"]) {
				push("fabricated-compiler-independence")
			}
		}
	}

	// provider conformance
	provReg := asSlice(regs["provider"])
	for _, pv := range asSlice(bundle["provider_conformance"]) {
		pc := asMap(pv)
		if !strInSlice(asStr(pc["provider_kid"]), provReg) {
			push("provider-subject-mismatch")
			continue
		}
		kobj := keyByKid[asStr(pc["provider_kid"])]
		r := "bad"
		if kobj != nil {
			r = sigVerify(asStr(kobj["x"]), "mltp3:provider-conformance", stripKey(pc, "sig"), asStr(pc["sig"]))
		}
		if r != "ok" {
			push("provider-subject-mismatch")
			continue
		}
		if toInt(pc["expiry"]) < trustedNow {
			push("provider-nonconformant")
		}
	}

	// QSR
	auditReg := asSlice(regs["auditor"])
	for _, qv := range asSlice(bundle["qualification_records"]) {
		q := asMap(qv)
		rr := "ok"
		if asStr(asMap(q["subject"])["release_root"]) != relRoot {
			rr = "qualification-subject-mismatch"
		}
		issuerKeys := map[string]bool{asStr(owner["kid"]): true}
		for k := range deleg {
			issuerKeys[k] = true
		}
		seen := map[string]bool{}
		if rr == "ok" {
			for _, sv := range asSlice(q["signers"]) {
				s := asMap(sv)
				if issuerKeys[asStr(s["kid"])] || !strInSlice(asStr(s["kid"]), auditReg) {
					rr = "unauthorized-qualification-issuer"
					break
				}
				kobj := keyByKid[asStr(s["kid"])]
				r := "bad"
				if kobj != nil {
					r = sigVerify(asStr(kobj["x"]), "mltp3:qual-state", stripKey(q, "signers"), asStr(s["sig"]))
				}
				if r != "ok" {
					rr = "unauthorized-qualification-issuer"
					break
				}
				seen[asStr(s["kid"])] = true
			}
			if rr == "ok" && len(seen) < 2 {
				rr = "unauthorized-qualification-issuer"
			}
		}
		if rr != "ok" {
			push(rr)
		}
	}

	// revocation checkpoint
	{
		cp := asMap(bundle["revocation_checkpoint"])
		rr := "ok"
		witReg := asSlice(regs["witness"])
		signers := map[string]bool{}
		for _, sv := range asSlice(cp["signers"]) {
			s := asMap(sv)
			if !strInSlice(asStr(s["kid"]), witReg) {
				continue
			}
			kobj := keyByKid[asStr(s["kid"])]
			if kobj != nil && sigVerify(asStr(kobj["x"]), "mltp3:witness-checkpoint", stripKey(cp, "signers"), asStr(s["sig"])) == "ok" {
				signers[asStr(s["kid"])] = true
			}
		}
		if len(signers) < 2 {
			rr = "unsigned-revocation-checkpoint"
		} else if trustedNow-toInt(cp["checkpoint_at"]) > toInt(lts["max_revocation_staleness_seconds"]) {
			rr = "stale-revocation-state"
		} else {
			included := map[string]bool{}
			for _, rvv := range asSlice(cp["revocations"]) {
				included[asStr(asMap(rvv)["statement_id"])] = true
			}
			for _, rsv := range asSlice(bundle["revocation_statements"]) {
				rid, _ := idHash("mltp3:revocation-id", stripKey(asMap(rsv), "sig"))
				if !included["rev1:"+rid] {
					rr = "omitted-revocation"
					break
				}
			}
			if rr == "ok" {
				for _, rvv := range asSlice(cp["revocations"]) {
					inc := asMap(asMap(rvv)["inclusion"])
					if !inclOk(asStr(inc["leaf"]), asSlice(inc["path"]), asStr(cp["log_root"])) {
						rr = "omitted-revocation"
						break
					}
				}
			}
		}
		if rr != "ok" {
			push(rr)
		}
	}

	// bundle_id acyclic recompute
	{
		expect, err := idHash("mltp3:bundle-id", bundle["manifest"])
		if err != nil {
			push("malformed-envelope")
		} else if containsValue(bundle["manifest"], asStr(bundle["bundle_id"])) {
			push("self-referential-id")
		} else if asStr(bundle["bundle_id"]) != "bnd1:"+expect {
			push("id-mismatch")
		}
	}

	return fin()
}
