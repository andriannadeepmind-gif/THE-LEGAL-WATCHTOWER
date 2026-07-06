# LAWMAX Ω+ — REPO AUDIT
**Repo-grounded status against the Ω+ target: νομογενετικό, αυτοδιδασκόμενο, αυτοαξιολογούμενο, οντολογικά εξελισσόμενο νομικό ίδρυμα σε NixOS substrate.**
Audit date: 2026-07-06 · Auditor: session AI with full repo access · Every claim below is grep/run-verified, not assumed.

---

## 1. Current commit / branch / dirty status

```
HEAD:    f1793e8ed83912e18a7493b9f7f6c35fe1181ba2
branch:  claude/ministry-justice-url-candidates-twghsj
status:  clean (git status --short: empty)
```
History: `f1793e8` (autodidactic loop doc) ← `f15cea5` (Ω plan doc) ← `efaea7a` (P0 fixes: exit-0 refusals, full training object, decision+reason) ← `4be0081` (trust envelope + provenance enforcement).

## 2. Current audit status

- **18/18 gates green** at `efaea7a`+ (verified TWICE: clean cloud build, AND creator's production Docker runtime with both volumes — output included gate check ㉓ which exists only in `efaea7a`).
- `--mirror` live: 27 capabilities, 38 contracts, 489 component identities (271 files SHA-256, 737 edges), 146 commands, 18 gates, 0 violations in contracts/components/provenance/ledger validators.
- `--trace-last-conclusion` live: subsume execution binds contract=`subsume`, capability=`υπαγωγή`, component=`symbol:orchestrator.subsumption::subsume`, proof link ΝΑΙ.
- **CONSCIOUSNESS AUDIT v1: NOT in this repo.** It exists only on the creator's machine. It has NOT been re-run against `efaea7a` yet. Therefore: audit script path — N/A in repo; audit SHA-256 — N/A; PASS/FAIL/WARN totals — last known 10/6/1 at `4be0081` (BEFORE the P0 fixes).
- **REQUIREMENT (blocking):** creator commits the audit script to `deployment/verify/consciousness-audit/`, we pin its SHA-256 in the component manifest, creator runs it unchanged against `efaea7a`+. The 6 previously-failing behaviors are smoke-verified in-cloud (override→rc 0+envelope; training→13-field object+rc 0; 4× external ingestion→`decision:`+`reason:` with exact reasons+rc 0) and gate-locked (⑳–㉓), so P0 are **implemented-and-locked, pending external certification** — not "open".

## 3. Existing modules relevant to Ω+ (inventory: 133 source modules + 37 CLI modules)

Reasoning core: `legal-inference-engine` (WFS, semi-naive, 100k-scale), `legal-deontic` (40/40), `legal-subsumption` (29/29), `legal-dialectic`, `legal-counterfactual`, `legal-strategy`, `legal-event-calculus`, `legal-precedent`, `legal-hypo`, `legal-penalty`, `graph-reasoning`, `guard-metaeval` (certificate-checked arithmetic, De Bruijn), `fluid-induction`, `case-workspace`.
Self-* : `self-model`, `contracts`, `components`+`component-scan`, `execution-trace`+`provenance-link`, `what-if`, `adoption-decision`, `institution`, `self-history`, `self-constitution`, `introspection`, `memory` (hash-chained episodes), `proposals`, `knowledge-packs` (SHA-256 packs, `with-packs-overlay` shadow), CLI: `self-extension`, `self-reflection`, `evolution-gate`, `autonomy-missions`, `jurisprudence-judge`, `approval-policy`, `constitutional-dispatch` (ALL 146 commands through constitutional CLOS :around).
Corpus/authority: 6 clean corpora with `.prov.json` (ΠΚ=529 provisions verified), `deployment/data/decisions/` = **331 court decisions** (322 ΑΠ + 9 lower) + `kat-arthron.json`, `legal-decisions.lisp` (structure/ratio scanners), `corpus-provenance`, `consolidation-engine/-proof`, `legal-temporal`, `eli-temporal-metadata`, `canonical-article-id`, `legal-id-registry`, `canonical-uris`, `greek-legislation-ontology`, `akoma-ntoso-emitter`, `proof-carrying` (PCL-1, `deployment/PROOF-CARRYING-LAW.md`, `deployment/verify/` independent verifiers in JS+Python).
Language: casegrammar, greek-nlp-core, lemmatizer, generation (25/25), cognition frames (67/67 dialogue).

## 4. Mapping: Ω+ concept → existing repo seat → missing extension

| Ω+ Concept | Existing Repo Seat | Current Capability | Missing Extension | File/Function Candidates |
|---|---|---|---|---|
| batch corpus self-study | `--self-extend`, `study-code` | scans ALL corpus provisions, counts readable/unreadable, proposes | nightly scheduled sweep + persistent ignorance map | `systems/orchestrator-cli/self-extension.lisp:292 (study-code), :494 (run-self-extend)` |
| norm candidate generator | `propose-norm-from-provision` | reads real ΠΚ text → conditions+act (verified vs hand-written 372) | N competing strategies per provision | `self-extension.lisp:203` |
| shadow validation | `with-packs-overlay` + full gate run | install→test→restore, zero residue | run per-bundle, matrix of bundles | `self-extension.lisp:110,166`; `knowledge-packs.lisp` |
| adoption engine | `can-adopt` + what-if embedded | verdicts, missing-list, signed ledger | nightly queue object + morning report renderer | `source/adoption-decision.lisp:22` |
| learned-rule genealogy | adoption ledger + pack provenance | signed SHA-256 decision records | genealogy fields (extraction-version, candidate-id) on pack meta | `adoption-decision.lisp:85 (record-adoption!)` |
| ignorance map | lessons stream + `%ungrounded-gaps` | concept-ungrounded lessons consumed by self-extend | first-class map object + retry conditions | `decisions.lisp (%lesson)`, `self-extension.lisp:110` |
| invariant baseline | 18 gates via `--gates` | plenary runner exists | run against candidate (overlay now, derivation later) | `gates-runner.lisp` |
| ratio extraction | **`decision-ratio` — EXISTS, half-asleep** | scanner extracts ratio bridge-sentence per decision | wire to 331-decision corpus, structured ratio objects, binding to articles | `source/legal-decisions.lisp:569`; `legal-precedent.lisp` |
| blind-matter benchmark | subsumption locked suite + `legal-hypo` | 29/29 locked; hypo factors/knn exist (debt: no gate) | creator-authored blind matter set, versioned, never seen by loop | `subsumption-commands.lisp`, `legal-hypo.lisp` |
| evaluator evolution | policy gate (measured-accuracy-before-policy) + Σ11 | accuracy measured per class before policy allowed | benchmark-vacuity checks (mutation witnesses), evaluator proposals via can-adopt | `approval-policy.lisp`, `evolution-gate.lisp` |
| ontology registry | contracts + taxonomy packs + `greek-legislation-ontology` + casegrammar noun-classes | :taxonomy packs adopted via shadow; RDF/ELI ontology for corpus | ontology-revision proposal kind with migration plan (§16 below) | `contracts.lisp`, `taxonomy-core.sexp`, `legal-casegrammar.lisp:47` |
| candidate ecology | what-if proposals (one at a time) | single candidate via overlay | N parallel candidates (needs Nix/OCI isolation) | `what-if.lisp`, future `nix/` |
| nightly trigger | `--autonomous` missions + `deployment/cron-auto-update.sh` | manual missions; cron does corpus updates only | `--self-study-night` mission + timer | `autonomy-missions.lisp:175` |
| trust envelope | `%ask-envelope` | every `--ask` path + refusals | attach to self-study/adoption/queue outputs | `decisions.lisp:1810` |
| LLM boundary | `load-proposal-file!` data-only ingest | path-safe, `*read-eval*` NIL, schema-tolerant, judged by can-adopt | nothing missing structurally — declare it THE LLM door | `what-if.lisp:62` |

## 5. Current self-learning capabilities (verified in code)

- `study-code`: full-corpus sweep, counts readable/unreadable provisions, names top unlock-value verbs.
- `propose-norm-from-provision`: real text → Tatbestand (4 conditions + act for ΠΚ 372, machine-verified against hand-written norm).
- `propose-assimilations`: definitional sentences from corpus → genus-differentia taxonomy packs, full shadow subsumption gate before filing (extension gate 20/20 proves the circuit).
- Dream grammar: verb-lemma hypotheses judged by explanatory power, policy-gated self-approval with measured accuracy (24/24), revocable.
- `run-evolve`: study + groundings + dreams, before/after capability measurement.
- **Gap:** everything runs on manual command, one item at a time; no nightly loop, no competing interpretations, no persistent ignorance map, tatbestand-core has only 4 active norms.

## 6. Current evaluator / benchmark capabilities

450+ checks in 18 gates; locked suites: subsumption 29/29, deontic 40/40, dialogue 67/67, dream-frame 24/24, grammar 28/28, IQ 4/4 (independent-judge pattern), inference 63/63. Policy gate enforces measured-accuracy-before-policy (the seed of evaluator governance). Gate ratchet: no `-gate` command without declared capability. **Missing:** benchmark-vacuity proof (mutation witnesses), benchmark difficulty tracking, blind-matter set, evaluator-change-requires-meta-evaluation rule (today evaluator code changes are ordinary commits).

## 7. Current ontology capabilities

Contracts registry (38, queryable, validated), capability registry (27), component registry (489), canonical-article-id (first-class, 100≠100Α), legal-id-registry, taxonomy packs (:taxonomy kind, genus-differentia, corpus-sourced), casegrammar noun-classes (6 creator-approved bootstrap seeds), `greek-legislation-ontology.lisp` (RDF/ELI), SHACL validator. **Missing:** ontology-revision as a governed proposal kind — today category changes are code edits; no migration-plan object; condition taxonomy is flat (no positive/negative/exception/defeater/burden-shifting/procedural-trigger/evidentiary-threshold/temporal subtypes).

## 8. Current self-evolution / adoption capabilities

Σ11 proposals registry + approval policies (measured, revocable, scoped force-override); Φ5 `can-adopt` with what-if EMBEDDED (bypass impossible by construction), verdicts allowed/requires-human/denied, signed SHA-256 records, ledger validator, adoption traces; external ingestion door with 4-scenario denial reasons; training-proposal generator (13 fields); article-identity migration impossible without human approval (gate ⑬). **Missing:** candidate ecology (N parallel), tournament comparison, quarantine/retry-later states (only 3 verdicts today), genealogy fields, morning queue.

## 9. Current provenance / trust envelope capabilities

Trace core (data-only tevents, profiles off/minimal/legal-critical/full-debug, env-controlled), resolve-event → contract/capability/component binding, conclusion-requires-proof-link validator, stale-source-hash detection (disk OR baked manifest), trace coverage (5 direct + 14 via parent + 0 silent), root-span per command with constitutional verdict, trust envelope on all `--ask` paths + structured refusals + provenance enforcement on subsumption/draft gates. PCL-1: corpus Merkle+Ed25519 with independent JS/Python verifiers in `deployment/verify/`. **Missing:** envelope on non-ask externals (Phase 1 of Ω plan), source/temporal/authority-proof fields, certificate emission for full legal derivations (Ω trust spine #1).

## 10. Current Nix/NixOS readiness

**Zero.** No flake.nix, no nix/ directory, no derivations. Everything below is greenfield: flake, package, OCI via dockerTools, module, checks. Prerequisite refactor identified: `/app` paths are hardcoded (paths.lisp, Dockerfile layout) — must become `LAWMAX_*` env config first (the ONLY Lisp change Nix requires).

## 11. Current Docker/OCI readiness

**Strong.** Multi-stage Dockerfile (deps-verify with locked third-party hashes → builder with `save-lisp-and-die` + frozen component manifest → source-less runtime, nonroot 65532, selective COPY), docker-compose, SBOM, cosign pubkey, entrypoint artifact detection. Creator's Windows/Docker Desktop workflow proven (18/18 in production). dockerTools OCI (Phase N3) replaces the Dockerfile builder while keeping `docker run` UX identical.

## 12. Blocking gaps (honest, ranked)

1. **External certification pending:** audit not re-run on `efaea7a`; audit not in repo, not hash-pinned.
2. **Knowledge scale:** 4 active norms vs 529 ΠΚ provisions; 0 structured ratios vs 331 decisions.
3. **No closed loop:** all learning machinery is manual/one-shot.
4. **No competing interpretations:** one extraction path per provision.
5. **No blind-matter benchmark:** intelligence growth currently unmeasurable end-to-end.
6. **No Nix at all** (but Docker path de-risks transition).
7. Verdict set lacks QUARANTINED/RETRY-LATER; no genealogy fields; no morning queue.
8. Declared capability debts: πρόσληψη-νομολογίας, ταυτότητα-άρθρων, ομοιότητα-υποθέσεων have no gates; 5 functions contract-less (visible in mirror).

## 13. P0 — required before NixOS work

1. Creator runs unchanged CONSCIOUSNESS AUDIT v1 on `efaea7a`+ → PASS-CANDIDATE (code side done; certification external).
2. Audit committed to `deployment/verify/consciousness-audit/` + SHA-256 pinned.
3. Env-config refactor: `LAWMAX_STATE_DIR` etc. replacing hardcoded `/app` (small, testable, no logic change).

## 14. P1 — required for autodidactic loop (Vertical Slice 1, §18)

`--self-study-night` mission (observe→extract→compete→bundle→shadow→decide→queue) on existing seats; ignorance-map object on lessons stream; QUARANTINED/RETRY-LATER verdicts; genealogy fields on pack meta + ledger; morning queue as .sexp + rendered report; envelope on all its outputs.

## 15. P2 — required for evaluator evolution

Mutation-witness harness (each constitutional clause ships a violating variant the gates MUST fail — vacuity = build failure); benchmark difficulty ledger (always-green flags); evaluator-change class in can-adopt with STRICTER rule: meta-evaluation report + human approval mandatory (no policy-class shortcut); blind-matter set as creator-signed, versioned, loop-invisible artifact.

## 16. P3 — required for ontology evolution

New proposal kind `:ontology-revision` in what-if/can-adopt with fields: ontology_gap_id, current_category, proposed_categories, affected capabilities/contracts, migration plan, backward compatibility, tests+negative tests, example provisions/cases, expected improvement, rollback, human approval (ALWAYS). First target: condition taxonomy → {positive, negative, exception, defeater, burden-shifting, procedural-trigger, evidentiary-threshold, temporal-applicability}. Seats: contracts registry + tatbestand pack schema + subsumption engine condition handling. Migration = corpus-wide re-extraction under new categories, shadow-compared against old on locked suites + blind matters.

## 17. P4 — required for candidate legal minds (ecology)

Nix candidate derivations (or OCI variants transitionally): candidate object {candidate-id, parent-stable-id, proposal-id, derivation/image hash, corpus snapshot, changed modules, tests run, improvements, regressions, decision, rollback target}. Ecology roster (extractor-conservative/broad, defeater-, ratio-, temporal-, procedural-focused, defense-biased, court-neutral, plus redteam/judge-sim/citation-auditor/temporal-auditor roles) = SAME binary + different bundle/config, NOT forked code. Tournament = §10 benchmark set of Ω plan; only winners reach the morning queue.

## 18. Exact implementation plan — Vertical Slice 1

**Input:** 8 ΠΚ provisions (372, 374, 375, 380, 299, 302, 308, 386 — θεμελιώδη, ήδη μερικώς μελετημένα) + 3 ΑΠ αποφάσεις εφαρμογής τους.
**Steps (all on existing seats):**
1. `observe`: study-code restricted to the subset → ignorance map .sexp (lessons stream).
2. `extract`: propose-norm-from-provision per provision; decision-ratio per decision.
3. `compete`: 3 strategies v1 (conservative/broad/strict) — parameterization of the ONE extractor, tagged.
4. `bundle`: winners per provision → 1 tatbestand pack + 1 ratio pack (content-addressed, provenance per sentence).
5. `shadow`: with-packs-overlay → FULL plenary (18 gates) + locked suites.
6. `compare`: coverage Δ, norms Δ, zero-regression check vs stable numbers.
7. `decide`: can-adopt per bundle → expected REQUIRES-HUMAN.
8. `queue`: morning report (.sexp + text) with what/where-from/proof/tests/improvement/risks/rollback per bundle. **No automatic adoption. Full provenance. Full envelope.**
New/changed files: `systems/orchestrator-cli/self-study.lisp` (the runner, ~1 file), small extensions in self-extension.lisp (strategy parameter), adoption-decision.lisp (2 new verdicts), what-if.lisp (genealogy fields) — NO new subsystems.
**Acceptance:** one unattended run produces the queue with ≥1 REQUIRES-HUMAN bundle carrying full genealogy; stable self byte-identical; plenary green before and after; a NEW gate `--self-study-gate` locks the loop's honesty (no adoption without signature, no learning without provenance, declared failures).

## 19. Tests to run (every slice iteration)

Clean-cache rebuild → `--gates` (18/18) → `--self-study-gate` (new) → smoke: run the night mission on the subset twice (idempotency: second run learns nothing new, says so honestly) → `git status` clean except intended → creator's Docker: compose build + `--gates` with both volumes → unchanged CONSCIOUSNESS AUDIT v1.

## 20. What we need from you (creator)

1. **Run the unchanged audit** on current image (`efaea7a`+ is already in your built image — ㉓ visible in your last run) and send the summary.
2. **Commit the audit script** to `deployment/verify/consciousness-audit/` so it becomes hash-pinned.
3. **Author/approve the blind-matter set** (even 5 matters to start) — it must come from you, not the loop, or it measures nothing.
4. Approve Vertical Slice 1 scope (§18) and, when it lands, sign (or reject) its first morning queue.
5. Decide the nightly trigger surface for now: host-side scheduler (Windows Task Scheduler / cron on Docker) invoking `--self-study-night`, until systemd timers arrive with NixOS.

---

### Direct answers (§14 of the instruction)

**A. Already exists for Ω+:** the entire trust/governance substrate (traces, contracts, components, what-if, can-adopt, ledger, envelope, gates) AND the learning organs (study-code, propose-norm-from-provision, assimilations, dream-judge, overlay shadow, ratio scanner).
**B. Exists but half-asleep:** `decision-ratio` (never wired to the 331-decision corpus), `legal-hypo` (no gate), autonomy missions (manual), kat-arthron.json (metadata unused for training), jurisprudence-judge (measures, doesn't propose).
**C. Missing entirely:** closed nightly loop, competing extractions, ignorance-map object, morning queue, QUARANTINED/RETRY-LATER, genealogy fields, blind-matter benchmark, mutation witnesses, ontology-revision proposal kind, ALL Nix.
**D. Buildable immediately:** Vertical Slice 1 (§18) — zero new subsystems.
**E. Before NixOS:** audit certification + audit hash-pinning + env-config refactor (§13).
**F. Nix without breaking Docker:** Phase N3 `dockerTools.buildImage` produces the SAME `docker run` UX; Dockerfile retired only after byte-level gate parity.
**G. First minimal vertical slice:** §18.
**H. Files to change:** `self-study.lisp` (new), `self-extension.lisp`, `adoption-decision.lisp`, `what-if.lisp`, `evolution-gate.lisp` or new `self-study-gate`, `orchestrator-cli.asd`.
**I. Tests:** §19.
**J. Needed from you:** §20.

**Shortest path to Ω+ inside NixOS:** certify P0 → Slice 1 on overlays → scale to full ΠΚ + ratios → env-config refactor → flake + OCI (N1–N4) → candidates as derivations (N7) → tournament + timers (N8–N10) → evaluator evolution (P2) → ontology evolution (P3). Each step ships behind the existing gates; nothing waits for everything.
