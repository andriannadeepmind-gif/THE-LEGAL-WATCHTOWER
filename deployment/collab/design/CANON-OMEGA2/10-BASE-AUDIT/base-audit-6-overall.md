# BASE AUDIT — LAYER 6: EPISTEMIC / META LAYER + OVERALL FOUNDATIONAL VERDICT

**Stance:** adversarial, uncharitable. The prior transformation assumed the existing foundations sound and
marked seats KEEP/light-REFACTOR without a quality audit. This layer FALSIFIES that assumption at the base.
**Method:** read the 5 named epistemic/meta seats verbatim; surveyed the 11 `systems/` subsystems, all root
`.asd`, and a sample of `source/` (133 flat seats). `output/`, `output_run1/` read by path only.
**Claim tags:** THEOREM / DESIGN-ENTAILED / IMPLEMENTED / DEMONSTRATED / EMPIRICAL / HYPOTHESIS / UNKNOWN.
`proof-checking ≠ formalization correctness`; a test that asserts what code already does is a finding.

---

## PART A — PER-SEAT VERDICTS (the 5 named files)

### A1. `systems/orchestrator-epistemic/meta-ontology.lisp` — **REPLACE** (as the epistemic layer of an observatory)

**(a) Concrete defect (quoted).** This is Layer 1 — the system's *own formal self-definition*, OWL 2 DL,
emitted and then folded into the anchored `system-commit-hash` (`deploy-epistemic.lisp:136` →
`compute-system-commit-hash` at `:236`). Its committed self-model declares the system **identity-only /
non-normative**:

- L62–63: `"This system represents IDENTITY only, not normative content. It does not resolve conflicts,
  select interpretations, or model intent."`
- L122–141 + L166–169, all asserted `true` on the canonical system instance:
  `slw:doesNotAnswerWhy true ; slw:doesNotResolveConflicts true ; slw:doesNotSelectInterpretation true ;
  slw:doesNotModelIntent true ; slw:nonNormativeNature true ; slw:identityOnlySemantics true`.

Meanwhile the repo ships **25 `source/legal-*.lisp` reasoning seats** that do exactly the disclaimed work:
`legal-conflict-resolution`, `legal-deontic`, `legal-dialectic`, `legal-subsumption`, `legal-precedent`,
`legal-counterfactual`, `legal-event-calculus`, `legal-strategy`, and the JTMS core
`legal-inference-engine.lisp` ("NON-MONOTONIC truth-maintenance … lex specialis derogat legi generali …
Van Gelder alternating fixpoint"). **The cryptographically-anchored Layer-1 ontology formally denies the
capability its own Layer-3 code implements.** `DEMONSTRATED` (both files read; the anchoring path traced).

**(b) WORK vs TOP.** This is **"needs it just to WORK as an observatory,"** not merely a TOP gap. The mission
("watch/ingest/**map** Greek law, decisions, **doctrine**") and the CANON-Ω2 target (§4 labelled multi-world
authority store: conflicts as *edges not deletions*, competing construals, `DiscretionNode`) both **require a
first-class representation of conflict and interpretation.** An ontology whose committed axioms are
`doesNotResolveConflicts=true, doesNotSelectInterpretation=true` is **structurally incapable of hosting the
store the target demands** — and it is internally inconsistent with the shipped reasoners. A watchtower whose
foundational self-model asserts it holds no conflicts and no interpretations is not a watchtower.

**(c) Upgrade required.** Re-seat Layer 1 as the **labelled multi-world authority ontology** (CANON §4:
`Position(Q)=⟨AF,W,A,Λ⟩`): norms carry a *set* of admitted construals with authority weight/forum/interval;
conflicts and DISPUTED procedure are first-class typed objects; discretion is irreducible and surfaced. The
current identity-only ontology is *honest and adequate for a static linked-data publisher of the
Constitution* — so scoped to that telos it is KEEP. Scoped to the **stated mission** it is **REPLACE**: it is
the wrong altitude and self-contradictory.

### A2. `systems/orchestrator-epistemic/temporal-proof.lisp` — **KEEP-AS-IS**

**(a) Finding.** Genuinely top-level for its scope. Pure-Lisp RFC-3161 multi-TSA + JWS (no `openssl`/`curl`
subprocess), **one seat** (L20–30: the 2nd DER encoder / 2nd TimeStampReq / duplicated `*tsa-endpoints*` were
removed under [0057]), correct delegation to `orchestrator.timestamp-authority`, RFC-7638 thumbprint `kid`
derived from the *actual signing key* (L85–89, not a brand string), and an **honest deletion** of CT-log
submission with the real reason stated (L162–166: public CT logs reject self-signed certs). `IMPLEMENTED`.

**(b/c)** Not a foundational defect. Minor UPGRADE-IN-PLACE candidates only: `%public-pem-sibling` (L36–48)
does fragile in-string `"private"→"public"` surgery — bounded, but a structural sibling-key resolver would
eliminate the class. No action required at base level.

### A3. `systems/orchestrator-ai-core/provenance-model.lisp` — **RESTRUCTURE**

**(a) Concrete defect.** Named `provenance-model` (i.e. *the* model of provenance) but it models **build-pipeline
provenance, not legal-authority provenance.** The activity vocabulary is emit-stage-shaped (L220–249):
`:parse → :generate-rdf → :generate-jsonld → :anchor-blockchain`. It answers *"how was this artifact file
produced,"* never *"which gazette/FEK enacted this norm, through which amendment chain, and who is trusted for
this fact."* Second defect: docstring L144 says **"Blake3"** but L160 calls `:algorithm :blake2` — a
correctness/labeling divergence in a hash-authority path (`DEMONSTRATED`; grep confirms only `:blake2` exists).

**(b) WORK vs TOP.** "**Needs it to be TOP**" (and for the trusted-spine claim, closer to WORK): the observatory's
load-bearing provenance is *source-authority + amendment-chain + premise-trust* (CANON §5.1 premise-trust
ledger). That content is scattered into `version-graph` amendment-edges and `legal-decisions`, while the seat
literally named provenance is about file production. Misnamed, wrong-altitude foundation.

**(c) Upgrade.** Rename/rescope this to `pipeline-provenance` (PROV-O over the emit run — keep it, it is fine),
and stand up a **separate legal-authority-provenance seat** = the CANON premise-trust manifest
(fact-confirmations-by-whom, formalization-fidelity artifact + status, coverage stamp, enumerated unchecked
trust deps). Fix the Blake2/Blake3 label on-seat.

### A4. `systems/orchestrator-engine-sbcl/stages/deploy.lisp` ("SINGLE FILESYSTEM TRUTH") — **UPGRADE-IN-PLACE** (engineering) / **telos is a foundational limit**

**(a) Finding.** The single-writer discipline is *sound* (L133–139: `write-corpus-files` the one writer;
byte-identity guarantee; explicit `validate-artifact-contract` gate at L107 before manifest). But the seat's
**telos is a publisher's endgame**: "Deploy = write 5 formats/article + 3 dataset files to a directory"
(L83–92). The terminal state of the flagship deploy path is a **static filesystem dump of the Constitution
corpus**, not a live queryable/continuously-re-emitting observatory service.

**(b) WORK vs TOP.** "Needs it to be TOP." An observatory's deploy target is a *served, queryable, continuously
updated* surface (the `ingestion-daemon` Diavgeia→re-consolidate loop exists but is peripheral "runnable glue,"
not the proof/deploy spine). The single-writer core: KEEP. The "filesystem truth = the deliverable" framing:
RESTRUCTURE toward serve+watch as the terminal.

### A5. `systems/` overall coherence (11 subsystems, 16 root `.asd`) — **RESTRUCTURE** ("one seat per concept" only half-honored)

Verdict detailed in Part D. The subsystem partition is real and mostly sane (core/model/spec/engine/cli/
epistemic/ai-core/gr-syntagma/meta/omega-modules/tests), but the "μία έδρα ανά έννοια" law is honored at the
*file-per-broad-area* level while multiple *concepts* are conflated inside single files (god-files).

---

## PART B — IS THE BASE SOUND (additive work) OR DOES IT NEED MULTI-LEVEL RESTRUCTURING?

**Honest answer: the base needs restructuring at the epistemic/telos level, not merely additive work — but it
is not greenfield.** `DEMONSTRATED` for the structural facts; `DESIGN-ENTAILED` for the "needs restructuring"
conclusion.

The repo contains **two architectures cohabiting, unreconciled at the epistemic layer:**

- **Architecture P — the STATIC LINKED-DATA PUBLISHER (dominant, mature, load-bearing, wired to CI/deploy/
  proof).** `deploy.lisp` "SINGLE FILESYSTEM TRUTH", `meta-ontology.lisp` (identity-only), `provenance-model`
  (pipeline provenance), the timestamp/JWS/Merkle/hash-chain attestation stack. Production-grade engineering
  whose **committed self-model is explicitly non-normative.** This spine's job is: take Constitution articles,
  emit provenance-sealed TTL/JSON-LD/HTML, anchor them. It does this well.

- **Architecture O — the OBSERVATORY / REASONING SUBSTRATE (ambitious, partially built, peripherally wired).**
  `version-graph` (bitemporal, consumed by 10+ seats), the JTMS `legal-inference-engine` + 24 sibling
  `legal-*` reasoners (consumed across the family), `legal-decisions` (judge-with-role extraction — the
  "named judges" mission — consumed by the CLI cognition cluster), `authority-v2` admission model,
  `ingestion-daemon` (Diavgeia feed). Real code, but at prototype-to-partial maturity and **not routed through
  the flagship proof/deploy spine.**

These are **not reconciled.** Architecture P's Layer-1 ontology *formally disclaims* what Architecture O does.
There is no single composition seat that makes the observatory the system and the publisher a downstream
egress. The CANON-Ω2 target (multi-world authority store, split-verifier family, victory-condition organs)
**cannot be reached by adding files on top of P** — its foundational ontology structurally forbids the store.
That is a base-architecture change at the epistemic level, cascading into provenance, deploy-telos, and the
admission gate. Conclusion: **RESTRUCTURE the base before large additive feature work.** Not a rewrite — the
crypto/attestation stack, the version-graph temporal core, and the inference family are salvageable spines —
but the *organizing epistemic layer and the deploy telos must be re-seated.*

---

## PART C — WHAT THE REPO IS TODAY, REALLY

**A partial-production STATIC LEGAL-CORPUS PUBLISHER, with a prototype-to-partial observatory bolted alongside.**
`DEMONSTRATED / EMPIRICAL`.

- The **emission + provenance + timestamp + merkle + hash-chain path is production-quality**: real Ironclad
  crypto, real RFC-3161 multi-TSA, single-writer determinism, gate-guarded contracts, three CI workflows.
  This part is *not* a demo. `IMPLEMENTED/DEMONSTRATED`.
- The **reasoning/observatory path is real code at prototype-to-partial maturity**: a genuine JTMS with
  well-founded semantics, a bitemporal graph with structural quarantine and replay-then-append, decisions/
  judge analytics, a Diavgeia ingestion daemon described as offline-verifiable "runnable glue." There is
  **no evidence in the base of a continuously-running live watch** serving queries; the daemon is injectable
  glue, not a demonstrated running observatory. `EMPIRICAL` (code present) / `UNKNOWN` (live operation).
- It is **not** a running observatory, **not** a "trusted spine" whose trust is discharged (the admission gate
  is fail-open — see F2), and **not** a mere demo (the publisher spine is real).

**Net:** research-hardened publisher (production-ish) + research-prototype observatory (partial), fused only
loosely, with a Layer-1 self-model that describes only the publisher and denies the observatory.

---

## PART D — THE "EVERYTHING LOADED IN ONE" PATTERN BEYOND THE GOD-KERNEL

**Confirmed: the pattern is systemic, not isolated to K.** `DEMONSTRATED` (line/defun counts run against tree).

- **`source/version-graph.lisp` — 2613 lines, 114 defuns/methods (the verdict's cited candidate).** Self-titled
  "Η ΜΙΑ έδρα νομικού χρόνου" (the ONE seat of legal time). More coherent than the god-kernel (one broad
  concept), but it still **conflates ≥4 trust/concern foundations under one name**: the temporal *model*
  (versions/edges/bitemporal intervals), the *storage journal* (append-only sexp lines, G3), the *hash-chain*
  (payload-hash/chain, K2), *commencement text-parsing* (`parse-commencement`, a NL→struct concern), and
  *scope-uncertainty reasoning* (`scope-uncertain`). Storage substrate + temporal semantics + parsing in one
  seat. **RESTRUCTURE** (split the journal/hash-chain substrate from the temporal model from commencement
  parsing).
- **`systems/orchestrator-gr-syntagma/parsing.lisp` — 151 defuns (the single highest defun-count file in the
  whole tree).** A parsing god-file.
- **`source/legal-ast.lisp` — 2359 lines / 68 defuns; `source/layout-types.lisp` — 1324 lines / 77 defuns;
  `source/typographic-classifier.lisp` — 1488 lines.** Large conflated seats in the ingest/typesetting path.
- **`systems/orchestrator-cli/main.lisp` — 85 defuns**, plus a `cognition-self` / `cognition-legal` /
  `understanding-learning` / `self-reflection` cluster in the CLI — dispatch + "cognition" conflated into the
  CLI layer rather than a reasoning subsystem.

So "everything in one" recurs as **multi-concept god-files** (version-graph, syntagma/parsing, legal-ast) and
as **layer-conflation** (reasoning "cognition" living inside the CLI; storage journal living inside the
temporal model). The creator law "μία έδρα ανά έννοια / μία είσοδος ανά λειτουργία" is honored as *one file per
broad area* but violated at the *one seat per concept* granularity it actually demands.

---

## PART E — THE 3–5 MOST SERIOUS FOUNDATIONAL PROBLEMS (existing base, not the features gap)

**F1 (SINGLE MOST SERIOUS) — The anchored Layer-1 epistemic self-model is non-normative and self-contradictory.**
`meta-ontology.lisp` commits `doesNotResolveConflicts / doesNotSelectInterpretation / doesNotModelIntent /
nonNormativeNature = true` into the `system-commit-hash`, while 25 `legal-*` seats resolve conflicts, select
defeasible conclusions, and do deontic reasoning. The base's *cryptographically-attested definition of itself*
(a) contradicts its own shipped code, and (b) is structurally incapable of hosting the CANON multi-world
authority store the observatory requires. **An observatory founded on an ontology that formally denies holding
conflicts and interpretations cannot be the top observatory.** Base-architecture defect. `DEMONSTRATED`.

**F2 — Fail-OPEN admission gate (inherited BLOCKING, `repo-paths` §2a).** `source/constitutional-gate.lisp`
L43–47: a rule predicate that *signals an error* returns `(values t nil)` = ALLOW ("fail-open, τίμια"). The
"trusted spine" property "cannot admit a wrong authority" is **undischarged**; a crashing predicate is a silent
admission. Directly opposes the creator law "εξάλειψη της κλάσης σφάλματος" and the fail-closed posture the
whole CANON assumes. `DEMONSTRATED`. **BLOCKING.**

**F3 — Provenance is at the wrong altitude / misnamed.** The seat named `provenance-model` models emit-pipeline
stages, not legal-source authority; the observatory's real provenance (source→FEK→amendment-chain→fact-trust)
has no single seat (scattered across version-graph/decisions). Plus the Blake2-labeled-Blake3 hash defect.
"Needs it to WORK as a trusted spine." `DEMONSTRATED`.

**F4 — Two unreconciled spines; the flagship telos is "publish," not "observe."** `deploy.lisp` "SINGLE
FILESYSTEM TRUTH" makes a static filesystem dump the deliverable; the observatory organs (ingestion daemon,
inference family, decisions analytics) are wired peripherally, not through the proof/deploy spine. No
composition seat elevates the observatory to *the* system. `DEMONSTRATED`.

**F5 — Systemic god-file / layer-conflation (Part D).** version-graph (114 defuns, storage+model+parsing),
syntagma/parsing (151), legal-ast (68), CLI-embedded "cognition". "One seat per concept" only half-honored.
`DEMONSTRATED`.

---

## OVERALL FOUNDATIONAL VERDICT

The base is **NOT a sound foundation that only needs additive work.** It is a production-ish **static
linked-data publisher** whose anchored Layer-1 self-model is **explicitly non-normative and identity-only**,
with a **partial observatory/reasoning substrate bolted alongside and contradicted by that self-model.** Before
the top-observatory features are added, the base needs restructuring at **≥3 levels**: (1) the epistemic layer
(identity-only ontology → labelled multi-world authority store), (2) the provenance layer (pipeline-provenance
→ a real legal-authority/premise-trust seat), and (3) the deploy telos (filesystem publish → served/watched
observatory) — **on top of** closing the inherited fail-open admission gate (F2). The single most serious
defect is **F1**: the system's cryptographically-committed definition of itself formally disclaims the
conflict/interpretation modeling an observatory is *for*, and contradicts the 25 reasoners it already ships.
The salvageable spines (crypto/attestation stack `KEEP`; version-graph temporal core `RESTRUCTURE`; inference
family `KEEP/integrate`) mean this is restructuring, not a rewrite — but it is base restructuring, not
additive.
