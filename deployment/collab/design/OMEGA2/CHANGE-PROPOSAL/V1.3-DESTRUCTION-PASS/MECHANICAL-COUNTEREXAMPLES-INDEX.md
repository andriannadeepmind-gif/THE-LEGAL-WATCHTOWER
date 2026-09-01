# ΟΛΟΚΛΗΡΩΜΕΝΑ ΑΝΑΠΑΡΑΓΩΓΙΜΑ (MECHANICAL) ΕΥΡΗΜΑΤΑ — ΕΥΡΕΤΗΡΙΟ (ΜΗ adjudicated, ΜΗ επανεκτελεσμένα)

> **ΕΤΙΚΕΤΑ 2026-09-01: REPORTED / ΙΣΤΟΡΙΚΟ ΕΥΡΕΤΗΡΙΟ.** Όπως κατατέθηκε πριν το Stage A. Η κατάσταση κάθε ευρήματος (CONFIRMED / DUPLICATE_OF / REFUTED_FALSE_POSITIVE / UNREPRODUCIBLE) και οι επανεκτελέσεις με digest είναι στο `STAGE-A-ADJUDICATION.md` και `STAGE-A-RERUN-EVIDENCE.json`. Ετυμηγορία πλήρους pass: `NO FULL-PASS VERDICT`.

**Κατάσταση:** ισχυρισμοί αντιπάλων A1–A4 όπως κατατέθηκαν. ΔΕΝ επανεκτελέστηκαν, ΔΕΝ έχουν digest, ΔΕΝ πέρασαν adjudication. `REPORTED` μόνο.


## A1 — ['KW-1', 'KW-9'] — 13 ευρήματα

### [A1-F1] P1 KW-1 — Issuer self-verdict field is not rejected by the verifier contract — it is ignored
- **claim:** An IssuedClaim carrying issuer-signed `verification_result: "VERIFIED"` is rejected (KW-1 want; Q21(α)).
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-KILL-WITNESSES.md:9, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-KILL-WITNESSES.md:18, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:49, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:56, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:57, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:244
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; Q=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md; sed -n '56,57p' $M; sed -n '383,423p' $M | grep -cE 'verification_result|schema|validate'; sed -n '244,250p' $M | grep -ciE 'self|schema|forbidden|envelope|malformed'; sed -n '263,264p' $Q; sed -n '340,342p' $M
```
### [A1-F2] P0 NEW — IssuedClaim signing input is undefined — no context string, no declared target; envelope fields that drive scope/revocation/qualification checks may be unsigned
- **claim:** The IssuedClaim signature binds the fields the verifier relies on (claim_type, issued_at, qualification_state_ref, issuer, kid).
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:35, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:41, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:57, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:232, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:240, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:394
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; grep -n 'mltp2:' $M; sed -n '35p;41p' $M
```
### [A1-F3] P0 NEW — 'Trusted signature time' is issuer-written: the verifier reads issued_at.trusted_time directly and never verifies the RFC-3161/tlog anchor — retroactive revocation (§9) keys off a self-declared field
- **claim:** Revocation is checked against a TRUSTED (anchored, non-self-declared) signature time (MLTP §1.0:50-53, §9:455-459), closing KW-6/KW-14/KW-16.
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:43, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:50, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:293, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:308, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:354, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:364
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; grep -n 'tsr' $M; sed -n '383,423p' $M | grep -cE 'tsr|TSR|TSA'; sed -n '293,308p' $M | grep -ciE 'tsr|timestamp'; sed -n '409p' $M
```
### [A1-F4] P1 KW-9 — The 'wrong verifier' (thumbprint(embedded key) == pinned root; root signature verified directly against pinned key) is still prescribed by an ACTIVE foundation (PCL §5), by v1.3 §4.1 item 2, and by qualification witness Q22(α)
- **claim:** The design's verifier does NOT compare the delegated key's thumbprint to the pinned owner root; the chain is root → signed delegation → delegated key → claim (KW-9 want; MLTP §8.2).
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-KILL-WITNESSES.md:26, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:348, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:355, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:372, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:375, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:465
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && D=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL; grep -n 'thumbprint' deployment/PROOF-CARRYING-LAW.md $D/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md $D/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '185,186p' $D/CHANGE-PROPOSAL-v1.3.md; sed -n '28,29p' deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md; sed -n '80p' $D/V1.3-CONSISTENCY-AUDIT.sh; grep -c 'PROOF-CARRYING-LAW' $D/V1.3-CONSISTENCY-AUDIT.sh
```
### [A1-F5] P1 NEW — Delegated-key binding is missing: delegations carry fingerprints, LocalTrustState carries a fingerprint, sig_verify is written against fingerprints, and no step binds an embedded delegated public key to the delegation's fingerprint; kid↔fingerprint join undefined
- **claim:** The chain root → signed delegation → delegated key → claim is closed: the key that verifies a claim is the key the root delegated.
- **refs:** deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md:38, deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md:39, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:259, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:262, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:351, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:355
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '38,39p' deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md; sed -n '355p;390p;393p;395p' $M; grep -n 'thumbprint' $M
```
### [A1-F6] P1 NEW — Delegation validity window is never compared to the claim's signature time; seq-supersession and revocation-by-delegation_seq are not enforced — expired or superseded delegations verify
- **claim:** A claim signed under an expired or superseded delegation is rejected (delegation-expired / delegation-invalid / revoked); Q23: delegation chain valid at TSR genTime.
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:161, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:248, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:391, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:411, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md:283, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md:286
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '391p;411p;161p' $M; sed -n '283p' deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md; sed -n '383,423p' $M | grep -c 'seq'; sed -n '383,423p' $M | grep -c 'delegation-expired'
```
### [A1-F7] P0 NEW — Self-verdict leaks through the QualificationStateRecord layer: its signature is never verified, its role is self-declared, 'release-authority kid' is undefined, the signer is not required to be a registered auditor, evidence receipts may be unsigned, and q.subject is never bound to the claim
- **claim:** Assurance level cannot be self-certified: only independent-auditor / auditor-quorum / provider-registry can issue a QualificationStateRecord, and the release issuer can never qualify itself (MLTP §3:190-209; §8.3-H; KW-12).
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:178, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:186, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:187, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:200, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:205, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:220
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '412,418p' $M | grep -c 'sig_verify'; sed -n '383,423p' $M | grep -n 'sig_verify'; sed -n '186,187p;338p' $M; grep -n 'release-authority kid' $M
```
### [A1-F8] P1 NEW — Self-adoption: reviewer_adoption_act may be signed by the issuer's own key — no reviewer registry, `unadopted()` undefined, attribution self-named
- **claim:** Interpretive ratio is institutionally certified only via an independent reviewer adoption act; AI inference never becomes institutional ratio (MLTP §2.6; v1.3 §5; KW-7).
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:138, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:140, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:143, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:147, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:250, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:354
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '354,364p' $M | grep -ci 'reviewer'; sed -n '420p' $M; sed -n '383,423p' $M | grep -c 'unadopted-analysis'
```
### [A1-F9] P1 NEW — `issuer` is unbound to the signing key and typed as a USC de-jure authority id — a signed claim can present itself as issued by a court or the Gazette
- **claim:** The identity model prevents the machine trust root from presenting as, or being confused with, the de jure authority (v1.3 §7:299-302, §10:345; Q-tests §5:378-381).
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:38, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:383, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:423, deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md:350, deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md:355, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md:299
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '38p' $M; sed -n '383,423p' $M | grep -cE 'c\.issuer|issuer\.'
```
### [A1-F10] P2 NEW — 14 of 23 taxonomy errors are never raised by the verifier contract (incl. insufficient-provenance, unknown-claim-type, unknown-alg, delegation-expired, root-mismatch, unadopted-analysis); the contract returns values outside the closed `result` sum
- **claim:** The offline verifier contract (§8.3) is complete enough that two independent implementations produce identical VerificationReceipts (Q21 δ, kernel diversity), and every declared closure (e.g. §2.1 insufficient-provenance, KW-4) is a step of the contract.
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:90, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:91, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:238, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:244, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:250, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:283
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; TAX=$(sed -n '245,250p' $M | tr -d '`' | tr '·' '\n' | sed 's/^[ \t]*//;s/[ \t]*$//' | grep -v '^$'); echo "$TAX" | wc -l; for n in $TAX; do echo "$n => $(sed -n '383,423p' $M | grep -cF -- "$n")"; done; sed -n '334p;411p;422p' $M
```
### [A1-F11] P2 NEW — Public→private boundary at the schema level: the public cockpit's signed intent is seated inside the PRIVATE target's InstitutionalAct envelope (CPEI §2), whose sibling fields carry matter-solving content  *(ARGUMENT-ONLY)*
### [A1-F12] P2 NEW — Revocation freshness is unbounded: a bundle omitting a newer revocation and carrying an older 'current' revocation checkpoint verifies as long as its tlog view is consistent with the consumer's last checkpoint  *(ARGUMENT-ONLY)*
### [A1-F13] P2 NEW — Two incompatible rotation mechanisms: KEY-LIFECYCLE §2.4 / v1.3 §4.1 continuity statements signed by the OLD key vs MLTP §8.3-B 'ONLY the root signs delegations'
- **claim:** Key rotation of the release/claim-signing key preserves an unbroken, verifier-accepted chain (v1.3 §4.1:196-198; KEY-LIFECYCLE §2.4).
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md:196, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md:198, deployment/LAWMAX-KEY-LIFECYCLE-SPEC.md:49, deployment/LAWMAX-KEY-LIFECYCLE-SPEC.md:50, deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md:41, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:40
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && sed -n '49p' deployment/LAWMAX-KEY-LIFECYCLE-SPEC.md; sed -n '197,198p' deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md; sed -n '390p' deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '383,423p' deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md | grep -c 'key_lineage'
```

## A2 — ['KW-2', 'KW-10'] — 14 ευρήματα

### [A2-01] P0 KW-2 — IssuedClaim signature has no defined message and no defined verification-key carrier; hash-only seat still REUSED
- **claim:** MLTP §4/§8(B) deliver a real RS256/Ed25519 signature check for every IssuedClaim, so a SHA-only verifier is caught with `sig-invalid`.
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:39-41, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:232-242, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:293-308, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:354-364, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:393-395, deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md:38-42
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; grep -o 'mltp2:[a-z-]*' $M | sort -u; grep -c -i 'jwk\|public_key\|pubkey' $M; sed -n '39,40p' deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md; grep -n 'SHA-256 μόνο' deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-SEMANTIC-CROSSWALK.md
```
### [A2-02] P0 KW-2 — verify_bundle never binds claim inclusion proofs to release_root and never verifies the release-root signature — a pure SHA-256 acceptance path for claim content
- **claim:** 'One authority root (release_root)' plus RS256/Ed25519 signature means every accepted claim's content is bound to the signed, tlog-published release root; inclusion alone is never sufficient (KW-2 want).
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:385-387, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:396-397, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:401-403, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:273-283, deployment/PROOF-CARRYING-LAW.md:126-133, deployment/PROOF-CARRYING-LAW.md:136-139
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '383,423p' $M | grep -n 'root-mismatch\|merkle_root\|release_root\|release-root'
```
### [A2-03] P0 KW-10 — Scope is checked against `claim_type` but payload semantics follow `profile`; no binding check ⇒ out-of-scope analysis passes under an in-scope label
- **claim:** A delegated key with scope {release-signing} that signs a `jurisprudential-analysis` IssuedClaim is rejected with `delegation-scope-violation` (KW-10 want).
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:33-35, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:244-253, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:376-378, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:392-395, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:419-420, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:143-147
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '33,35p' $M; grep -c 'profile-mismatch\|claim-type-mismatch\|profile ≠ claim_type\|profile != claim_type' $M
```
### [A2-04] P1 KW-10 — Stale broader-scope delegation replay: `delegation_for(kid)` selection unspecified, `delegation_seq` self-declared, delegation-level revocation never consulted
- **claim:** The scope in force for a delegated key is the one the verifier checks; a narrowed/superseded delegation cannot be resurrected to widen scope.
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:40, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:161, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:389-395, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:407-411, deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md:38-42
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; grep -n 'delegation_for\|revoked(c' $M; grep -n 'μεγαλύτερο seq' deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md; grep -c 'max(seq)\|highest seq\|μέγιστο seq\|νεότερο seq\|μεγαλύτερο seq' $M
```
### [A2-05] P0 NEW — Delegation validity window is checked against the delegation's own signing time, never against the claim's signing time — `delegation-expired` is unreachable
- **claim:** A claim signed after the delegation's `not_after` (or before `not_before`) is rejected (`delegation-expired`), i.e. delegation is time-bounded as trust-bootstrap §3 (≤1 year) and Q23 ('valid στο genTime του TSR') require.
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:389-391, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:407-409, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:246, deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md:38-44, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md:283
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; grep -n 'signed_time\|not_after' $M; grep -n 'genTime' deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md
```
### [A2-06] P0 NEW — `issued_at` is a hash pointer to a TSR that is not in the bundle; the verifier reads `trusted_time` without verifying it ⇒ signature time is attacker-declared, defeating retroactive revocation offline
- **claim:** `issued_at` is a trusted, anchored signature time ('ΟΧΙ self-declared'); revocation with `invalid_from` is judged against it; the bundle is fully offline-resolvable.
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:42-43, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:49-53, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:293-308, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:313-321, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:354-364, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:401-411
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; grep -n -o -i 'tsr[a-z_0-9]*' $M; sed -n '293,308p' $M | grep -c -i 'tsr\|timestamp_token\|rfc3161\|rfc-3161'; sed -n '409p' $M
```
### [A2-07] P0 NEW — With a trusted `now`, freshness is never computed: coverage `freshness` is never compared, an expired QualificationStateRecord degrades `level` but the result is still VERIFIED, and the receipt has no `level` field
- **claim:** Provider rule: without valid, fresh certification the answer is UNVERIFIED_FOR_MACHINE_RELIANCE/UNKNOWN; Q28: expired qualification ⇒ automatic downgrade; 'positive proof of freshness'.
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:110-116, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:205-209, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:247, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:331-338, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:404-406, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:412-423
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; grep -n 'freshness_verdict\|max_staleness' $M; sed -n '383,423p' $M | grep -c 'coverage-and-freshness\|max_staleness\|as_of'; sed -n '421,423p' $M; sed -n '331,338p' $M | grep -c '"level"'
```
### [A2-08] P1 NEW — QualificationStateRecord signer signature is never verified; `role` is self-declared; issuer check is a kid-denylist; auditor receipts may be unsigned — independence/quorum unenforced
- **claim:** Only independent auditors / auditor-quorum / provider-registry can confer a level; the release issuer can never qualify itself (KW-12 want) and evidence resolves to receipts of registered independent auditors.
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:176-188, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:200-206, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:220, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:338, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:398-400, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:412-418
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; grep -n 'sig_verify' $M; sed -n '412,418p' $M | grep -c 'sig_verify\|signer.sig'; sed -n '338p' $M
```
### [A2-09] P1 NEW — Revocation authority contradiction: a root-signed revocation IssuedClaim is rejected as `untrusted-key`, while a delegated revocation is scope-bound only by claim_type, not by `revoked_subject`
- **claim:** Revocations are issued by the root (key-lifecycle §2.5, trust-bootstrap §2.3) and published as `trust-key-or-delegation-revocation` IssuedClaims (MLTP §9); a compromised delegate cannot revoke keys it does not own.
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:159-167, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:376-378, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:392-395, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:407-411, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:448-453, deployment/LAWMAX-KEY-LIFECYCLE-SPEC.md:55-56
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '28,29p' deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md; sed -n '55,56p' deployment/LAWMAX-KEY-LIFECYCLE-SPEC.md; sed -n '392,393p' $M; sed -n '161p' $M
```
### [A2-10] P1 NEW — v1.3 §4.1 item 2 states 'root/claims signed by the pinned key' — the KW-9 wrong model inside the v1.3 main text, contradicting MLTP §8.2 and trust-bootstrap §2.3
- **claim:** KW-8/KW-9: no active document applies the 'claims verified against the pinned key' model; the chain is root → signed delegation → delegated key → claim.
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md:184-188, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:370-375, deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md:28-29, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-KILL-WITNESSES.md:25-26, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-CONSISTENCY-AUDIT.sh:77-81
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; awk 'NR>=184 && NR<=186 {print NR": "$0}' deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md; sed -n '372,373p' deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '29p' deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md
```
### [A2-11] P1 NEW — PCL §5 (ACTIVE SHARED TRUST FOUNDATION and the cited seat of MLTP §8) hard-pins `alg == "RS256"` and `thumbprint(public_key) == thumbprint(PINNED_KEY)` — algorithm/anchor confusion with MLTP; the consistency audit never reads PCL
- **claim:** Two ACTIVE specs never give opposite verdicts for the same signature (KW-16 principle); the crypto profile admits Ed25519 and a delegated release key.
- **refs:** deployment/PROOF-CARRYING-LAW.md:94-97, deployment/PROOF-CARRYING-LAW.md:104-109, deployment/PROOF-CARRYING-LAW.md:126-133, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:219-226, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:348, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:355-356
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '129,132p' deployment/PROOF-CARRYING-LAW.md; grep -n -o 'corpus-proof JWS\|Ed25519' $M | sed -n '1,4p'; grep -c 'PROOF-CARRYING-LAW' deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-CONSISTENCY-AUDIT.sh
```
### [A2-12] P1 NEW — 'Every IssuedClaim is proof-carrying' is false for 5 of 8 profiles — no `proof_material` is defined for source-authenticity, coverage-and-freshness, jurisprudential-analysis, correction/withdrawal, or revocation; step A is undefined for them
- **claim:** v1.3 §3: each IssuedClaim contains the proof object (De Bruijn); signature is in addition to proof, never instead.
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md:162-164, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:36-37, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:79-91, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:110-116, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:129-147, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:149-170
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; grep -n 'proof_material' $M; grep -c '^### 2\.' $M
```
### [A2-13] P2 NEW — tlog rollback: consistency against `last_accepted_tlog` accepts any older consistent prefix; no tree_size monotonicity ⇒ replay of a pre-revocation bundle passes split-view detection  *(ARGUMENT-ONLY)*
### [A2-14] P2 NEW — Crypto profile underspecified: no RSA modulus floor, no Ed25519 verification-variant pin, no fingerprint/key-encoding rule, no alg↔key-type binding — Q21 'identical result across independent verifiers' is unattainable on edge inputs  *(ARGUMENT-ONLY)*

## A3 — ['KW-3', 'KW-11'] — 9 ευρήματα

### [A3-F1] P0 KW-11 — Dangling qualification_state_ref yields result VERIFIED; VerificationReceipt has no field to carry 'level none'
- **claim:** MLTP guarantees that a dangling qualification_state_ref is never silently accepted (level none, typed error dangling-qualification-ref).
- **refs:** /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:414, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:422, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:423, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:330, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:339, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:431
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && F=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md && sed -n '414p;422,423p' $F && echo "level-fields-in-VerificationReceipt(§7 330-339): $(sed -n '330,339p' $F | grep -c level)" && sed -n '431,432p' $F
```
### [A3-F2] P0 NEW — QualificationStateRecord is never signature-verified; signer role is self-declared; signer kid is never bound to LocalTrustState.auditor_registry; 'auditor-quorum' is unrepresentable with one {kid,sig}
- **claim:** The qualification chain (§3 + §8.3 H) prevents the release issuer from qualifying itself and admits only records issued by independent auditors / an auditor quorum / a provider registry.
- **refs:** /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:390, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:395, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:413, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:418, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:186, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:187
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && F=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md && grep -n "sig_verify" $F && sed -n '415,417p' $F && sed -n '186,187p' $F
```
### [A3-F3] P1 KW-11 — Qualification reference resolution is undefined: record has no id, subject is never compared to the claim, and §6's tlog-inclusion path contradicts §8.3 and is not offline-resolvable
- **claim:** A qualification_state_ref that resolves is a correct, subject-bound, offline-checkable qualification of the claim that carries it.
- **refs:** /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:44, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:151, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:161, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:174, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:178, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:210
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && F=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md && grep -n "subject" $F && echo "id-fields-in-§3-record(174-210): $(sed -n '174,210p' $F | grep -c '\"id\"\|record_id')" && sed -n '314,315p;414p' $F
```
### [A3-F4] P1 KW-3 — Same judgment from two channels yields two expression_ids by construction (judgments are single-document ⇒ content digest); Q13/Q07 count expression_id as identity and demand zero duplicates; KW-3's cited witness tests a different mutation
- **claim:** v1.3 §2.1 delivers 'one legal identity, many items' for a decision delivered by two channels, and the declared witness W-UNRELATED-CORPUS-IDENTITY-CHURN kills a design that mints a second identity from the second channel's bytes.
- **refs:** /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-KILL-WITNESSES.md:9, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-KILL-WITNESSES.md:12, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-KILL-WITNESSES.md:20, /home/user/THE-LEGAL-WATCHTOWER/deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md:164, /home/user/THE-LEGAL-WATCHTOWER/deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md:166, /home/user/THE-LEGAL-WATCHTOWER/deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md:176
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && D=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL && sed -n '20p' $D/V1.3-KILL-WITNESSES.md && sed -n '642p' deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md && sed -n '164,166p;176p' deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md && sed -n '100p' $D/CHANGE-PROPOSAL-v1.3.md && sed -n '169,170p;176,177p' $D/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md && sed -n '34,36p' deployment/verify/canonical-serialization-spec.md
```
### [A3-F5] P1 NEW — Bytes↔legal-object binding is unexpressible in MLTP: source-authenticity names no work/expression, legal-state and judgment-identity-and-text name no artifact/receipt, and the manifestation level is absent from every profile
- **claim:** The MLTP typed profiles let an offline verifier (or auditor reading the bundle) establish that a RELEASED legal object's text derives from bytes whose official provenance is attested (CP §2.2 'ενισχυμένο Σ-1', Q03).
- **refs:** /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:81, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:88, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:95, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:99, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:120, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:125
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && F=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md && echo "manifestation_id|lsm1 in MLTP: $(grep -c 'lsm1\|manifestation_id' $F)" && echo "work/expression fields in §2.1 source-authenticity (81-88): $(sed -n '81,88p' $F | grep -c 'work_id\|expression_id\|lsw1\|lse1')" && echo "artifact/receipt fields in §2.2 legal-state (95-99): $(sed -n '95,99p' $F | grep -c 'raw_artifact\|acq1\|acquisition\|digest')" && echo "digest/expression fields in §2.5 judgment (120-125): $(sed -n '120,125p' $F | grep -c 'expression_id\|lse1\|digest\|acq1\|content_sha256')" && sed -n '386,387p' $F
```
### [A3-F6] P1 NEW — IssuedClaim signature coverage is undefined (no context string, payload declared the only input) and the RFC-3161 imprint target is unspecified — issued_at, proof_material, qualification_state_ref and claim_type may be unsigned; §9 retroactive revocation depends on an unstated binding
- **claim:** An IssuedClaim's signature and its issued_at anchor bind the whole claim (payload, proof_material, claim_type, qualification_state_ref) and the anchor proves when the SIGNATURE existed.
- **refs:** /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:35, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:43, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:50, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:53, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:57, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:232
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && F=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md && grep -n "mltp2:" $F && sed -n '35p;43p;240p' $F && echo "TSR-imprint statements: $(grep -c 'imprint\|messageImprint' $F)"
```
### [A3-F7] P1 NEW — legal_state UNDEC: §2.2 says the local verifier returns UNKNOWN, §8.3 has no UNDEC branch and returns VERIFIED (KT6 regression, kernel-diversity violated by construction)
- **claim:** A legal-state IssuedClaim with legal_state UNDEC is never returned as VERIFIED by the local verifier.
- **refs:** /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:97, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:383, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:423, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md:248, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md:146, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md:147
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && F=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md && grep -n "UNDEC" $F && echo "UNDEC-in-§8.3(383-423): $(sed -n '383,423p' $F | grep -c UNDEC)" && sed -n '423p' $F
```
### [A3-F8] P2 NEW — Every public IssuedClaim carries an untyped free-text 'description' — the one-way boundary's 'no field to write' claim is false as written; protection is a verifier-ignores-it guard, which Q20 classifies as failure
- **claim:** The public schema is structurally incapable of carrying private matter/client material (CP §0: 'καμία διαρροή να φρουρηθεί, γιατί κανένα πεδίο να γραφτεί'; Q20: structural, not a guard).
- **refs:** /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:45, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:56, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:57, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:132, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:157, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md:46
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && D=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL && sed -n '45p' $D/MACHINE-LEGAL-TRUST-PROTOCOL.md && sed -n '46,48p' $D/CHANGE-PROPOSAL-v1.3.md
```
### [A3-F9] P2 NEW — Work identity and provenance are offline-unverifiable: LocalTrustState pins no authority/institutional-register registry, authority_proof_ref is presence-checked only, and 'provisional_id' (counted as identity by Q07) is never defined
- **claim:** An offline consumer can detect two work_ids for one judgment (Q07/Q24) and can distinguish genuine institutional provenance from a well-formed but issuer-invented auth1:/ireg1:/authority-proof triple (KW-4 want).
- **refs:** /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:90, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:91, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:120, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:354, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:364, /home/user/THE-LEGAL-WATCHTOWER/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:383
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && D=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL && F=$D/MACHINE-LEGAL-TRUST-PROTOCOL.md && echo "authority/register registry in LocalTrustState(354-364): $(sed -n '354,364p' $F | grep -c 'authority\|register')" && echo "authority_proof checks in §8.3(383-423): $(sed -n '383,423p' $F | grep -c authority_proof)" && grep -rn "provisional" $D/CHANGE-PROPOSAL-v1.3.md $F $D/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md
```

## A4 — ['KW-4', 'KW-12'] — 10 ευρήματα

### [A4-1] P1 KW-4 — Verifier contract (§8.3) has no provenance step: `insufficient-provenance` is declared but never emitted
- **claim:** A bundle whose source-authenticity claim lacks authority_proof_ref+institutional_register_id (or lacks a source-authenticity claim entirely) yields `insufficient-provenance`/UNKNOWN from the local verifier (KW-4 want; MLTP §2.1 rule; v1.3 §2.2; Q03 β).
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:90-91, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:244-250, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:382-424, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md:124-127, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md:78-87, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-KILL-WITNESSES.md:21
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; for t in insufficient-provenance authority_proof_ref institutional_register_id source-authenticity; do printf '%-28s %s\n' "$t" "$(sed -n '382,424p' $M | grep -cE "$t")"; done; sed -n '90,91p' $M
```
### [A4-2] P0 NEW — Forged provenance with valid time anchor: provenance refs are unresolved, issuer-authored content-addresses; the reused authority-proof-bundle/1 seat proves the Watchtower's own delegation, not state-authority issuance
- **claim:** v1.3 §1 row B / §2.2 claim that the origin gap ('RFC-3161 proves TIME not ORIGIN') is closed by authority registry + institutional register + authority-proof-bundle + acquisition receipt + divergence witnesses, such that the verifier can distinguish official bytes from issuer-labelled bytes.
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md:64, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md:113-127, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md:153, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:79-91, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:313-321, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:353-365
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; for t in authority_proof_ref institutional_register_id acquisition_receipt_id; do printf '%-28s %s\n' "$t" "$(sed -n '293,321p' $M | grep -cE "$t")"; done; printf 'LTS authority/register registry: %s\n' "$(sed -n '353,365p' $M | grep -ciE 'authority_registry|institutional')"; sed -n '46,52p' source/authority-evidence-replay.lisp
```
### [A4-3] P0 NEW — 'Trusted signature time' is an unverifiable hash reference: no TSR bytes in the TrustBundle and no TSA trust store in LocalTrustState — retroactive revocation (§9) and freshness rest on issuer-declared time
- **claim:** MLTP §1.0/§9: issued_at is a trusted, anchored signature time (TSR or tlog leaf), 'ΟΧΙ self-declared timestamp'; revocation is judged against it; for key-compromise only signatures with independent RFC-3161 time before invalid_from survive (KW-6/KW-14 closure).
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:42-43, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:50-53, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:87, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:184, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:293-308, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:354-364
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; printf 'TSR bytes in TrustBundle: %s\n' "$(sed -n '293,321p' $M | grep -ciE 'tsr')"; printf 'TSA/TSR in LocalTrustState: %s\n' "$(sed -n '353,365p' $M | grep -ciE 'tsa|tsr')"; sed -n '362p' $M; sed -n '409p' $M
```
### [A4-4] P0 KW-12 — Self-qualification via sibling key: QualificationStateRecord signer is never signature-verified, never required to be in auditor_registry, role is self-declared, exclusion is a one-kid blacklist, and auditor receipts may be unsigned
- **claim:** Only independent-auditor / auditor-quorum / provider-registry may issue a QualificationStateRecord; the release issuer can never qualify itself (KW-12 want: unauthorized-qualification-issuer; MLTP §3, §8.3 H).
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:177-187, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:190-209, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:331-338, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:358, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:390, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:395
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '414,417p' $M; printf 'sig_verify in 8.3 (abs lines): %s\n' "$(sed -n '382,424p' $M | grep -n sig_verify | cut -d: -f1 | awk '{print $1+381}' | tr '\n' ' ')"; grep -n 'local_signature' $M; printf 'definitions of evidence_resolves/quorum_for: %s\n' "$(grep -c 'evidence_resolves\s*(\S*)\s*:=\|def evidence_resolves\|quorum_for\s*:=' $M)"
```
### [A4-5] P1 NEW — provider-adoption-qualified is self-issuable: no provider registry in LocalTrustState and provider_attestations are never checked by the verifier
- **claim:** PROVIDER-ADOPTION QUALIFIED is an externally measured, separate tier signed only by an external provider-registry with provider attestations 'όχι δικές μας' (v1.3 §7-8, MLTP §3, Q28).
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:183, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:197, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:353-364, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:412-418, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md:295-297, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md:318
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; printf 'provider in LTS: %s\n' "$(sed -n '353,365p' $M | grep -ci provider)"; printf 'provider_attestations in 8.3: %s\n' "$(sed -n '382,424p' $M | grep -c provider_attestations)"; sed -n '197p' $M
```
### [A4-6] P1 NEW — QualificationStateRecord transplant: `subject` and auditor-receipt `bundle_digest` are never bound to the claim/release being verified
- **claim:** A qualification_state_ref conveys the assurance level of the specific claim/release it accompanies (MLTP §3 'subject: τι αφορά'; v1.3 §8).
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:178, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:181-185, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:209, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:332, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:412-418
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; for t in subject bundle_digest; do printf '%-14s %s\n' "$t" "$(sed -n '382,424p' $M | grep -c "$t")"; done; sed -n '178p' $M; sed -n '332p' $M
```
### [A4-7] P1 NEW — Delegation validity window is checked against an undefined `d.signed_time` instead of the claim's signature time — expired delegations keep validating claims; `delegation-expired` is never emitted
- **claim:** Delegated keys are time-bounded (not-before/not-after ≤ 1 year) and the chain is 'valid στο genTime του TSR' of the claim (TRUST-BOOTSTRAP §3, Q23, v1.3 §4.1 item 3).
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:247, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:389-395, deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md:38-45, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md:283, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md:187-188
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; grep -rn "signed_time" deployment/ --include=*.md; printf 'delegation-expired in 8.3: %s\n' "$(sed -n '382,424p' $M | grep -c delegation-expired)"; sed -n '38,40p' deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md
```
### [A4-8] P1 NEW — Revocation authority is contradictory and revocation records in the bundle are never signature-verified; precedence between conflicting revocation records for one kid is undefined
- **claim:** Revocations are root-signed (TRUST-BOOTSTRAP §2, KEY-LIFECYCLE §2.5); MLTP §2.8/§9 revocation records are fail-closed and consumed 'resolved, checkpointed' in §8.3 G.
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:159-167, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:304-305, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:316-317, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:389-395, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:407-411, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:448-453
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '304p' $M; sed -n '392p' $M; sed -n '410p' $M; sed -n '28,29p' deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md
```
### [A4-9] P2 NEW — Envelope `issuer.authority_id` is unbound to the signing key and collides with the USC `auth1:` state-authority namespace — a claim can name a state authority as its issuer
- **claim:** IssuedClaim identifies its issuer; the key chain binds issuer identity (MLTP §1.0, §8.2).
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:38, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:83, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:153, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:367-378, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:382-424, deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md:350-354
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; grep -n '"issuer"' $M; printf 'c.issuer / issuer. in 8.3: %s\n' "$(sed -n '382,424p' $M | grep -c 'c\.issuer\|issuer\.')"; sed -n '83p' $M
```
### [A4-10] P1 NEW — RFC-3161 TSAs are credited with proving non-equivocation while the same design holds 'RFC-3161 = time only'; the witness quorum of GitHub + TSAs is owner-satisfiable on both forks
- **claim:** Transparency witnesses prove 'consistency/μη-equivocation (split-view)' and `witness_quorum(..., quorum=2)` over GitHub + ≥2 TSAs closes split-view (MLTP §10, §8.3 E, v1.3 §4.1 item 5, TRUST-BOOTSTRAP §4).
- **refs:** deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:401-403, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:475, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md:121, deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md:189-193, deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md:14, deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md:51-62
- **command (ως κατατέθηκε από τον αντίπαλο):**
```
M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '121p' deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md; sed -n '475p' $M | cut -c1-140; sed -n '403p' $M
```

---
**Σύνολο A1–A4:** 46 ευρήματα · MECHANICAL 42 · ARGUMENT-ONLY 4 · P0 14 / P1 23 / P2 9 · υποχρεωτικά-KW 11 / NEW-axis 35
