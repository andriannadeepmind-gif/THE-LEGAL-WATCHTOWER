# STAGE-B QUALITY ADVERSARY — INDEPENDENT VERIFICATION REPORT

Verified against live repo at `/home/user/THE-LEGAL-WATCHTOWER`, HEAD `803113c0` (note: master's B0 was `e621dbe1`; all files below checked at current HEAD).

## Per-claim results (12 claims)

**1. `source/constitutional-gate.lisp` — P0 fail-open supreme gate — CONFIRMED.**
Lines 43-45: `(handler-case (funcall (getf r :predicate)) (error () (values t nil)))` inside `evaluate` — an erroring constitutional rule yields `ok=T`, i.e. the action is allowed. The code even self-documents it: line 45 comment "σφάλμα κανόνα ⇒ ΜΗΝ μπλοκάρεις (fail-open, τίμια)". Master cited lines 44-45; exact.

**2. `source/proposals.lisp` — P0 `approve!` swallows hook, journals approved — CONFIRMED.**
`%transition` line 136: `(when hook (ignore-errors (funcall hook p)))`, then lines 137-139 unconditionally `%append-event` with the new status (`"approved"` via `approve!` line 145). A throwing `on-approve` hook is silently discarded and the proposal is durably journaled approved. `fail-msg` is even `(declare (ignorable fail-msg))` (line 135) — the failure path was designed away.

**3. `source/narrative-provenance.lisp` — P0 fabricated evidence + false-green verify — CONFIRMED.**
Fabricated constants emitted as genuine RDF: hardcoded IPFS CID `QmXoypizjW3WknFiJnKLwHCnL72vedxjQkDDP1mXWo6uco` (line 631), Etherscan tx `0x742d35Cc...` with block 18500000 (lines 838-840), QES verification URL `https://validate.aped.gov.gr/QES-2024-STAV-001` and hash `3f2504e0...` (lines 831-832), fixed signing timestamp `2021-07-01T10:25:00Z` (line 592), invented milestone timeline (lines 677-683), `proc:hash "sha256:abc123..."` (line 809). `verify-provenance-chain` (lines 907-927) only pushes checks `when` present and returns `(every #'cdr checks)` — on an empty narrative, `checks=nil` ⇒ `(every #'cdr nil)` = **T**. Both halves exact.

**4. `source/semantic-authority.lisp` — P0 unconditional `fully_verified` + empty⇒valid — CONFIRMED.**
Line 620: `(format stream "    law:overallStatus \"fully_verified\" ;~%")` — unconditional, no verification precedes it (steps 1-4 above it likewise emit fixed "valid"/"immutable"/"intact" strings). `verify-authority-chain` (lines 730-754) uses the identical push-only-when-present + `(every #'cdr checks)` pattern ⇒ T on an empty assertion (line 754).

**5. `source/legal-audit-system.lisp` — P0 JWS verify wiring inoperative — CONFIRMED.**
Call site lines 548-551: `(orchestrator.jws-authority:verify-jws signature *signing-public-key-path* :expected-payload content)` — but the seat is `(defun verify-jws (jws payload public-key)` at `source/jws-authority.lisp:394`: three positionals, no `&key`. The call passes 4 args with a nonexistent keyword ⇒ program-error on every invocation, caught by the `handler-case` at 546 ⇒ always NIL. Second half also exact: `sign-entry` (lines 308-313) returns `(sign-jws content ...)` directly, and `sign-jws` returns a **plist** `(:jws :header :payload-hash :algorithm)` (`jws-authority.lisp:261`) — so `entry-signature` stores the plist, never the compact JWS string; the format-detection at 541-543 (`count #\.` = 2 on a string) can never match. Crypto verification is structurally impossible to succeed. (Nuance: the failure mode is fail-closed NIL, not fail-open — the master correctly labels it "inoperative", not fail-open.)

**6. `systems/orchestrator-epistemic/primary-anchor.lisp` — P0 undefined hash fns — CONFIRMED.**
Calls `compute-sha256-string` (line 151, 168, 184) and `compute-sha256-file` (lines 167, 183). Repo-wide grep: **zero definitions** of either symbol anywhere. The header (line 23) claims they live in `merkle-tree.lisp, same package` — but `merkle-tree.lisp` (same package `:orchestrator.epistemic`) defines only `build-merkle-tree`, `merkle-tree-root`, `generate-inclusion-proof`, `generate-all-inclusion-proofs`, `verify-inclusion-proof`. Every construct/verify path is a runtime undefined-function error.

**7. `systems/orchestrator-epistemic/release-manifest.lisp` — P0 fabricated stats + CC0 — CONFIRMED.**
Line 240-241: `void:triples` = `(* total-articles 50)` with the comment "Approximate triples per article". Line 243: `void:properties 25` hardcoded ("Approximate distinct properties"). Lines 185 and 330: `total-artifacts` = `(+ (* (length articles) 4) 5 5)` = N×4+10, exactly as the master states. Line 211: `dcterms:license <https://creativecommons.org/publicdomain/zero/1.0/>` hardcoded in the canonical manifest — contradicting the All-Rights-Reserved LICENSE.

**8. `determinism/run{1,2}/latest/verify/verify.lisp` + `verify.ps1` (4 files) — P0 unconditional-pass verifiers — CONFIRMED.**
`run1/.../verify.lisp` read in full (36 lines): all 5 gates are bare `;; TODO:` comments (lines 13, 17, 21, 25, 29); line 31 prints "✓ ALL VERIFICATIONS PASSED"; line 32 returns `t`. `run2/verify.lisp` identical (TODOs at 13/17/21/25/29, PASSED at 31). Both `verify.ps1` files: TODOs at 14/22/30, green "✓ ALL VERIFICATIONS PASSED" at line 33. All four are pure verification theatre.

**9. `systems/orchestrator-cli/autonomy-missions.lisp:49-51` — P0 silent loss of approved knowledge on replay — CONFIRMED.**
Lines 46-51 exactly: the replay loop over approved `:norm-classification` proposals wraps `on-approve` in `(handler-case ... (error () nil))` — a registration that fails on replay vanishes with no count, no report, no red. Line refs in the master are exact.

**10. `systems/orchestrator-engine-sbcl/stages/deploy-epistemic.lisp` — P0 warn-only terminal validation — CONFIRMED.**
Lines 157-159: `(if (orchestrator.epistemic:validate-epistemic-stage ...) (log:info "✓ ...") (log:warn "✗ Epistemic validation failed - some files may be missing"))`, then line 161 returns `context` — the stage succeeds regardless of validation outcome. False-green exactly as claimed.

**11. `systems/orchestrator-epistemic/deploy-epistemic.lisp` — P0 silent signing-key path substitution — CONFIRMED.**
Lines 430-435 and 437-442: if `PRIVATE_KEY_PATH` / `RELEASE_CERT_PATH` contains `..` or `~`, the operator-supplied path is **silently** replaced by the default `keys/private.pem` / `keys/certificate.pem` — no warning, no error. Combined with `ensure-crypto-keys-exist` auto-generation (line 446), a rejected operator key path leads to signing with a different (possibly freshly generated) trust root.

**12. `source/static-site.lisp` — P0 proofs silently omitted — CONFIRMED as structural fail-open, with one currency nuance.**
`%emit-corpus-proofs` resolves 6 functions via `find-symbol` through `%pc` (lines 287-289) and guards the entire proof emission with `(when (and leaf-hash build-root make-proof proof-json corpus-json) ...)` (line 290) — any miss ⇒ all proofs silently skipped while the JSON-LD still links to them; `sign-root` missing ⇒ silently unsigned root (line 295). The wiring contradicts its own docstring (lines 278-280: "αποτυχία εκπομπής proof ΚΟΚΚΙΝΙΖΕΙ το site build"). **Nuance:** all five gating symbols currently resolve in `proof-carrying.lisp` (exports/imports at lines 33-42), so today's builds do emit proofs — the defect is a live fail-open trap (exactly the class the "closed" comment at lines 282-286 claims was killed), not a currently-manifesting omission. If the catalog line is read as "proofs are omitted today," that reading would be OVERSTATED; the §3 P0-2 phrasing ("silently skips ... if find-symbol misses") is exact.

## Bonus spot-check — supreme-form verdict on a writer seat

**`source/proof-carrying.lisp` VERIFIED + "P1 silent signed→unsigned downgrade" — CONFIRMED.**
`sign-root` line 154: `(ignore-errors (funcall fn root private-key))` — a throwing signer returns NIL; `write-provision-proofs` line 212 then emits `corpus-proof.json` unsigned with no diagnostic, even when a private key was explicitly supplied. Also `%jws-fn` returning NIL (package absent) silently degrades to unsigned. The P1 record is accurate; whether a seat with this silent downgrade merits the supreme-form VERIFIED label is arguable, but the debt is honestly carried on the row.

## VERDICT

**12/12 claims CONFIRMED; 0 WRONG; 0 fully OVERSTATED.** One partial-overstatement flag: claim 12 (static-site) is a latent structural fail-open — the catalog's one-line phrasing "proofs silently omitted from published site" overstates current behavior (symbols presently resolve; the debt-register phrasing is the accurate one). One precision note on claim 5: the JWS defect fails closed (always-NIL verification), so it belongs in "broken/inoperative trusted seats" (where the master correctly files it), not among fail-opens. Line references in the master are accurate where given (constitutional-gate 44-45; autonomy-missions 49-51; legal-audit ~549-551). The fabricated-value specifics (N×50 triples, 25 properties, N×4+10 artifacts, CC0 IRI, hardcoded IPFS CID/tx-hash/QES serial, TODO-only verifiers) all reproduce verbatim from the code. The Stage-B master's P0 register is trustworthy for Stage-E planning; the only correction I would apply is annotating P0 static-site as "latent (currently non-firing) fail-open guard".