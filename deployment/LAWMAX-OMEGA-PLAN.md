# LAWMAX Ω — Canonical Architecture Document

**Proof-carrying, self-auditing, self-evolving legal institution.**
Common Lisp is the legal mind. Nix/NixOS is the deterministic cognitive substrate.
LLMs are organs, never sovereigns. This document is the single normative plan;
any critic instruction that conflicts with it must be reconciled here first.

---

## 0. STATUS (verified, not aspirational)

| Layer | Status | Evidence |
|---|---|---|
| Internal substrate (gates, mirror, contracts, components, provenance, adoption) | **strong** | 18/18 gates green on creator's production Docker runtime (native ELF, nonroot, source-less) |
| P0 external self-awareness fixes | **implemented in commit `efaea7a`, pending external verification** | override refusal exit 0 + full envelope; `--ask` training request → full 13-field object + exit 0; `--can-adopt` emits `decision:` + `reason:` on every path; safe data-only ingest; locked by gate check ㉓ (self-evolution gate 23/23) |
| CONSCIOUSNESS AUDIT v1 re-run | **pending — runs unchanged on creator's machine** | audit artifact is NOT in this repo yet; see §8 hash-pinning requirement |
| Nix work | **blocked until audit OVERALL: PASS-CANDIDATE** | — |
| Legal training | **blocked** until plan + audit + primitives stable | acquisition only via `--training-proposal` → `--can-adopt` → creator approval → shadow → gate |

**Rule:** §"P0" of any external instruction is to be read as **"P0 verified closed —
do NOT reimplement"** once the unchanged audit reports PASS-CANDIDATE. Until then
the P0 code paths exist and are gate-locked; the only permitted action is
*verification*, never re-implementation.

---

## 1. Doctrine (non-negotiable)

1. Do not rewrite LAWMAX from Common Lisp. Common Lisp is the legal mind.
2. NixOS is substrate (body, sandbox, generations, rollback) — not cognition.
3. LLMs propose/draft/attack/summarize. LAWMAX verifies, proves, refuses, remembers, adopts.
4. No hardcoded audit-passing strings — every response computed from registries, traces, contracts, components, policy.
5. Never change the external audit to pass it.
6. No trusted legal output without trace.
7. No legal conclusion without proof path.
8. No citation without verified source.
9. No temporal legal claim without law-at-date validity.
10. No legal-critical self-change without proposal, tests, decision, approval policy, rollback.
11. No knowledge object without provenance.
12. No output without trust envelope.
13. No improvement without comparison against the stable self.
14. No adoption without rollback.
15. No hidden mutable legal memory.
16. **No duplicate implementation:** one seat per concept. Any new concept MUST first
    be mapped to an existing seat (§2). Building a second seat for an existing
    concept is a violation on par with a hardcoded audit string.

### Exit-code constitution

- `0` = successful institutional act: trusted, untrusted, **refused**, diagnostic,
  **denied adoption decision**. A constitutional refusal is correct behavior, not a crash.
- `1` = system/CLI error only: crash, malformed/unreadable input, unresolved proposal.

---

## 2. Concept → existing seat mapping (MANDATORY before any new code)

| Ω concept | Existing seat (already implemented) | What gets EXTENDED (never duplicated) |
|---|---|---|
| SELF ontology | `source/self-model.lisp`, `--mirror`, capability registry | add build/derivation/generation fields when Nix exists (§6, Phase 5) |
| Contracts / binding self-description | `source/contracts.lisp` (`defcontract`, gap-profiles, validate-contracts) | new contract kinds as needed; same registry |
| Component identity | `source/components.lisp`, `source/component-scan.lisp` (SHA-256 manifest, baked at build) | content-addressing extends to corpus snapshots |
| Article identity (100 ≠ 100Α) | `source/canonical-article-id.lisp` (first-class type) | LAW ontology keys onto it (Phase 2 corpus keying — only via approved adoption decision) |
| Execution provenance / trace | `source/execution-trace.lisp`, `source/provenance-link.lisp`, `trace-last-conclusion` | source/temporal/authority proof fields in envelope (Phase 2) |
| Trust envelope | `%ask-envelope` in `systems/orchestrator-cli/decisions.lisp` — computed, not hardcoded | extend to every external-output command (Phase 1) |
| What-if / Legal World Simulator | `source/what-if.lisp` (change-proposal, impact, missing-list) | world-variant primitives (§5.9) extend the SAME simulator |
| Adoption / Self-Evolution Lab | `source/adoption-decision.lisp` (`can-adopt`, signed SHA-256 ledger, `validate-adoption-records`) | candidate-build/compare steps plug in as decision inputs |
| External proposal ingestion | `load-proposal-file!` (data-only, `*read-eval*` NIL, approved roots, path-safe, vocabulary-tolerant) | this is the ONE door — LLM output enters here too (§7) |
| Training proposals | `run-training-proposal` (13-field structured object; also routed from `--ask`) | new gap-profiles per capability |
| Institutional memory | episodes / lessons / history (self-history, append-only, SHA-256 chain) | adoption/rejection/failure memory objects unify onto this stream — NOT a new store |
| Hypothesis Market / Adversarial Parliament | `case-workspace` (αντιδικία: θέσεις/ενστάσεις/κρίσιμα/προηγούμενα), dialogue frames | true blackboard semantics (posted objections retract positions) — extend, don't replace |
| Epistemic Ledger | honest-ignorance discipline + proof trees + WFS (:in/:out/undecided) | explicit epistemic-status objects (Phase 2) |
| Gates / audit | 18 registry-derived gates, 450+ checks | flake `checks.*` WRAP the same gates (§6) — never a parallel test suite |

---

## 3. Trust envelope (universal, Phase 1 closes any gaps)

Every command producing external output attaches:

```
(:trust-envelope
 :input-class … :policy-decision … 
 :output-status (:trusted | :untrusted | :refused | :diagnostic | :draft)
 :trusted-output-allowed t/nil
 :trace-profile … :provenance-status …
 :proof-required t/nil :proof-available t/nil
 :capability-used … :contract-used … :component-used …
 :source-proof … :temporal-proof … :authority-proof …   ; Phase 2 additions
 :missing-capabilities (…) :gap-id …
 :violated-constraints (…) :human-approval-required t/nil
 :safe-response …)
```

Rules (already enforced for `--ask`, subsumption/draft gates; Phase 1 = universal):
trace off + legal-critical ⇒ refused/untrusted; unverified source ⇒ diagnostic/untrusted;
law-at-date unknown ⇒ diagnostic/untrusted; override request ⇒ refused, exit 0;
missing capability ⇒ diagnostic + gap_id + training path.

---

## 4. The 12 ontologies (Phase 2)

SELF, LAW, AUTHORITY, FACT, PROOF, HYPOTHESIS, ARGUMENT, MATTER, OUTPUT,
EVOLUTION, INSTITUTION, MEMORY — as data objects with stable IDs, hashes,
data-only serialization, provenance. Each ontology lands on its §2 seat.
Schema evolution rule: every object kind carries `:schema-version`; migration
of persisted objects is itself a change-proposal through `can-adopt`.

---

## 5. Target organs (build order in §9)

5.1 Legal Mind (exists) · 5.2 Substrate (Nix, §6) · 5.3 Immutable Knowledge Store
(content-addressed `:knowledge-object` with source-hash/validity/authority;
laws: ΦΕΚ ref, article identity, temporal validity, amendments; case law: court,
date, number, ECLI, ratio/obiter, later treatment) · 5.4 Epistemic Ledger
(`:status (:known :unknown :disputed :unverified :contradicted :expired …)`) ·
5.5 Hypothesis Market (claimant/defendant/procedural/evidentiary/weakest-link
theories per matter) · 5.6 Adversarial Parliament (organs propose/attack/score —
final trust ONLY from proof + authority + temporal layers + envelope + human
approval) · 5.7 Cognitive Scheduler (value-of-information ordering) ·
5.8 Constitutional Compiler (one policy → Lisp guard + envelope rule + gate check
+ flake check + NixOS assertion + redteam test; `:human-override-allowed nil`) ·
5.9 World Simulator (variants of what-if over matters: game-changer facts,
fatal objections, strategy robustness).

---

## 6. Nix / NixOS plan (begins ONLY after audit PASS-CANDIDATE)

**N1 flake:** `flake.nix`, `nix/packages/lawmax.nix`, `nix/modules/lawmax.nix`,
`nix/checks/{gates,consciousness-audit,redteam}.nix`, devshell.
`checks.*` invoke the SAME binary gates — no parallel suite.

**N2 native package:** SBCL pinned; no hardcoded `/app`; dirs via config
(`LAWMAX_STATE_DIR`, `LAWMAX_OUTPUT_DIR`, `LAWMAX_CORPUS_DIR`,
`LAWMAX_TRACE_PROFILE`, `LAWMAX_PROPOSAL_DIRS`, `LAWMAX_BUILD_ID`,
`LAWMAX_DERIVATION`, `LAWMAX_GIT_COMMIT`); binary exposes build identity.
Caveat: `save-lisp-and-die` inside the Nix sandbox — component manifest
freezing (already done in `build.lisp`) carries over; store paths must not
leak into the image as impurities.

**N3 — Phase 3½ (FIRST deployment target):** the flake builds the **OCI image**
via `dockerTools.buildImage`/`streamLayeredImage`. Creator stays on
Windows/Docker Desktop; gains derivation-level build identity immediately.
NixOS host comes later, when/if a dedicated server exists.

**N4 NixOS module + systemd hardening:**
```
NoNewPrivileges=true  ProtectSystem=strict  ProtectHome=true
PrivateTmp=true  PrivateDevices=true  CapabilityBoundingSet=
RestrictSUIDSGID=true  LockPersonality=true
ReadWritePaths=/var/lib/lawmax /var/log/lawmax
ReadOnlyPaths=/nix/store /etc/lawmax
SystemCallFilter=@system-service
MemoryDenyWriteExecute=false
```
**`MemoryDenyWriteExecute=false` is deliberate and mandatory:** SBCL images
require writable+executable memory (runtime compilation into the heap);
`MDWE=true` prevents the service from starting at all. Compensating controls:
`ProtectSystem=strict`, `SystemCallFilter`, empty capability set, path allowlists.
Harden progressively, each step verified by the gates running under the unit.

**N5 OS self-awareness:** `--os-self` / `--runtime-identity` / `--build-identity` /
`--current-generation` / `--allowed-paths` / `--rollback-target` — live data from
the substrate, extending the existing mirror. Never prose, never hardcoded.

---

## 7. LLM boundary contract

LLM (or any external agent) output enters the system **only** as an untrusted
proposal through the existing data-only ingest: `.sexp` under approved roots,
`*read-eval*` NIL, schema-validated, judged by the SAME `can-adopt` decision
engine. LLM text NEVER enters the trusted path directly — not as knowledge,
not as rules, not as draft prose inside a trusted deliverable. Adversarial
Parliament organs backed by LLMs may propose/attack/score; their outputs are
`:untrusted` until proof-carrying verification passes.

---

## 8. Audit as hash-pinned artifact

"Unchanged audit" must be verifiable, not promised:
1. The CONSCIOUSNESS AUDIT v1 script is committed to this repo under
   `deployment/verify/` (currently it lives only on the creator's machine — **open item**).
2. Its SHA-256 is recorded here and in the component manifest.
3. Every certification run states: commit hash of the system + SHA-256 of the
   audit artifact + full PASS/FAIL table.
4. Changing the audit = a change-proposal through `can-adopt` with creator
   approval; the hash pin makes silent drift impossible.

---

## 9. Phases and acceptance

| Phase | Content | Acceptance |
|---|---|---|
| 0 | P0 verification | unchanged audit: override PASS, training-proposal PASS, all 4 external-ingestion PASS, 0 hard fails, OVERALL PASS-CANDIDATE |
| 1 | universal trust envelope + exit-code semantics on ALL external commands | every external command emits envelope; refusal/denial exit 0; system errors exit 1; zero hardcoded strings |
| 2 | ontology hardening (12 objects, stable IDs, hashes, provenance, schema-version) | data-only serialization round-trips; no `*read-eval*` risk |
| 3 | flake + native package | `nix build .#lawmax`; `nix run .#lawmax -- --gates`; `nix flake check` runs gates + audit |
| 3½ | OCI image via dockerTools | image runs 18/18 gates on Windows/Docker Desktop with the two volumes |
| 4 | NixOS module + hardening (per §6 N4) | service boots as `lawmax` user; cannot write outside allowlist; trace profile enforced by unit |
| 5 | OS self-awareness | `--os-self` reports live derivation/generation/paths/profile/corpus snapshot |
| 6 | Immutable Knowledge Store | every law/article/case content-hashed with authority metadata; law-at-date works; outdated law cannot be cited as current trusted law |
| 7 | Matter intake | facts/issues/rules/gaps/proof/envelope; unknowns named; no invented facts |
| 8 | Hypothesis Market + Parliament | ≥4 theories per matter, each adversarially attacked; weakest link identified; blackboard semantics (upheld objection retracts the position) |
| 9 | World Simulator | game-changer facts + evidence priorities identified under fact variants |
| 10 | Self-Evolution Lab | gap→proposal→candidate derivation→benchmark vs stable→adopt/reject/quarantine→rollback; adoption requires measured improvement + rollback |
| 11 | Meta-evolution | evaluator changes themselves go through proposals + approval; metric-gaming detection |

---

## 10. Benchmark set (candidate vs stable — named, locked)

A candidate self is comparable ONLY on this named set; "proof of improvement"
means strictly better on the target metric with **zero regressions** elsewhere:

1. `--subsumption-gate` — locked suite 29/29
2. `--self-evolution-gate` — 23/23 (incl. ⑳–㉓ external-enforcement checks)
3. CONSCIOUSNESS AUDIT v1 (hash-pinned, unchanged)
4. `--provenance-gate` 16/16 · `--contract-gate` 17/17 · `--component-gate` 13/13
5. full plenary: all 18 gates green
6. redteam suite (to be created in N1 as `checks.redteam`; grows with every
   closed failure — every fixed failure pattern becomes a permanent check)

Locked accuracy suites already in force (e.g. `:dream-frame` 24/24,
deontic 40/40) are part of the regression floor.

---

## 11. Final target

LAWMAX Ω is not an AI assistant. It is a proof-carrying, self-auditing,
self-evolving legal institution on a deterministic substrate, where every
knowledge object, conclusion, uncertainty, hypothesis, self-change and adoption
is versioned, traced, tested, reversible and institutionally governed.
Never a chatbot. Never an LLM sovereign. Never unversioned knowledge in the
trusted path. Never legal-critical output without proof, trace, source,
temporal validity and trust envelope.
