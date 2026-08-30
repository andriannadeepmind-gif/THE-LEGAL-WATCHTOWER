# BASE-VERDICT — the honest re-scoped verdict on the EXISTING base

**Role:** Synthesizer. Inputs reconciled: the six adversarial base-audits
(`base-audit-1-integrity` … `base-audit-6-overall`), `DELIVERABLE-6-path-transformation`
(which *assumed the base sound*), `repo-paths.md` (verified inventory),
`CANON-OMEGA2-ARCHITECTURE.md` (target seats), `autopsy.md`.
**Stance:** uncharitable. No seat is credited for existing. `output/`, `output_run1/` by path only.
**Claim tags per statement:** THEOREM / DESIGN-ENTAILED / IMPLEMENTED / DEMONSTRATED / EMPIRICAL /
HYPOTHESIS / UNKNOWN. `exists-and-runs ≠ correct ≠ top`. `proof-checking ≠ formalization correctness`.
A test that asserts only what the code already does is a finding, not assurance. Unresolved
contradictions stay **BLOCKING** and are not wordsmithed away.

---

## 1. THE HONEST HEADLINE

**Does the existing repo base need restructuring/upgrade at all levels before the legal-practice
layer is added? — YES, at ≥3 architectural levels plus one BLOCKING inherited defect. Not "partly."
Not additive-only.** `[DESIGN-ENTAILED conclusion; DEMONSTRATED on every structural fact below]`

The weight of evidence is not one loud finding — it is **six independent adversarial reads, each on a
different layer, each with fresh context and no access to the others, converging on the SAME structural
pattern**: the base's real, genuinely production-grade assurance investment (Ironclad crypto, RFC-6962
Merkle, RFC-3161 multi-TSA, the append-only journal's single-writer/compare-and-append core, the
N-version + golden-vector + mutation-witness harness) is spent protecting **self-metadata and a static
publisher pipeline**, while **every seat that carries the mission's actual trust is off the load path,
spec-only, fail-open, unverified-against-source, or self-contradictory.** Each layer names it in its own
words:

- L1 integrity: *"the spine protects the wrong thing"* — the corpus writer (`emit-graph`) has NONE of
  the integrity properties advertised; append-only/hash-chain/Merkle/fsync guard only biography+episodes.
- L2 temporal: *"wrong seat on the load path"* — the crude lexical single-time consolidation engine
  answers "what was the law on date D," while the rigorous bitemporal `version-graph` sits off the load
  path holding genesis nodes + fabricated gaps.
- L3 admission: *"the runtime admission spine is a fiction"* — the kernel is spec-only prose (0/9),
  the one live gate is **fail-OPEN** with one rule over three commands, mediating names not effects.
- L4 ingestion: *"extraction is TRUSTED, never verified against the authoritative source"* — the seat
  that advertises "codifies PERFECTLY, PROVES it" only proves no-drift from a human-committed golden.
- L5 proof-harness: *"the verification is real; it points almost entirely away from where legal
  correctness is decided"* — 0/17 theorems discharged, no kernel, fail-open live path.
- L6 epistemic: *"a Layer-1 self-model that describes only the publisher and denies the observatory"* —
  the cryptographically-anchored ontology commits `doesNotResolveConflicts=true`,
  `doesNotSelectInterpretation=true` while 25 shipped `legal-*` reasoners do exactly that work.

`convergence-audit`'s warning ("three teams converging is not evidence — it echoes the shared prompt")
is honored and *does not blunt this*: this is not three planners agreeing on a design; it is six
adversarial auditors, each attacking a **different seat**, each independently reproducing the same
failure shape on the code they read. Six distinct DEMONSTRATED instances of one structural defect is
strictly stronger than an echo. `[DEMONSTRATED that the six defects are on disjoint seats; DESIGN-
ENTAILED that they are one pattern]`

**What the base is NOT:** it is not a demo (the publisher/attestation spine is real,
production-quality). It is not greenfield (version-graph's temporal core, the inference family, the
Machine-A harness, and the crypto stack are salvageable). It is **not** a sound foundation that only
needs legal-practice features bolted on. The prior "KEEP most seats / small refactor" assumption is
**FALSIFIED at the trusted spine specifically** — precisely the seats a legal super-system stands on.

---

## 2. CORRECTED DISPOSITION ROLL-UP — where the base-audit re-classifies the path-transformation

`DELIVERABLE-6` mapped seats to targets on the assumption the foundations were sound; it marked the
load-bearing seats **KEEP** or **REFACTOR(light/guard)** and even cited *their existing verifiers as
discharge tests*. The base-audits, reading the real code, re-classify **≈13 seats the path-transformation
had marked KEEP (or grouped-KEEP) and ≈3 it marked light-REFACTOR** to UPGRADE / RESTRUCTURE / REPLACE /
DELETE. Roll-up (D6 = DELIVERABLE-6 disposition; AUDIT = base-audit verdict):

| seat | D6 said | AUDIT says | why the re-classification (DEMONSTRATED) |
|---|---|---|---|
| **`meta-ontology.lisp`** | **KEEP** (discharge: "ontology-live-dump reproducible") | **REPLACE** | The seat's committed axioms (`doesNotResolveConflicts/SelectInterpretation/ModelIntent=true`, `nonNormativeNature=true`) are folded into the anchored `system-commit-hash`, yet 25 `legal-*` seats resolve conflicts and select construals. The self-model **structurally forbids** the CANON §4 multi-world store the observatory is *for*, and contradicts the code already shipped. **The single biggest re-classification.** |
| **`write-authority.lisp` (`emit-graph`)** | **REFACTOR** ("guard the single writer") | **REPLACE** | Not a guarding gap. The corpus writer is `:if-exists :supersede` truncate-overwrite, **no fsync, no atomic tmp+rename, no lock, no chain, no journal record** — the antithesis of the append-only spine, governing the records the observatory exists to hold. "Guard the writer" understates it: the writer must be re-seated onto the journaled/atomic/anchored path. |
| **`consolidation-proof.lisp`** | **KEEP** (cited *as* the "replay-consolidation" discharge test) | **REPLACE** | `verify-consolidation-ledger` does **not** replay the ledger — it re-runs `consolidate` (the same code) and compares step **count**, never per-step before/after hashes. Proves determinism, not correctness, and is not independent. D6 trusted this seat to be the discharge test for the whole consolidation concept. **False assurance.** |
| **`consolidation-engine.lisp`** | **KEEP** (grouped "versioning core") | **RESTRUCTURE** (demote to renderer) | Point-in-time correctness rests on **lexical `string<` date comparison** over an `effective`-only order; `recorded` (bitemporal axis) is never read by any query; `:if-missing :skip` silently drops amendments. It is the seat actually wired to ~16 serving seats — and it must not be the in-force authority. |
| **`ai-citation-strategy.lisp`** | **KEEP/REFACTOR** (grouped ingest) | **DELETE from trusted core** | Citation-farming SEO: beacons inviting public AIs to cite, Prometheus POST to a public endpoint (ungated egress), fabricated DOIs, `schema:license by/4.0` (vs All-Rights-Reserved), `dotimes 120` hardcode. Diametrically opposed to the *internal-private* binding. |
| **`validation-authority.lisp`** | **KEEP** (the "validate-before-emit" gate) | **RESTRUCTURE** | The FRBR "structure contract" is **substring presence** (`(search "eli:LegalResource" ttl)` …) — it asserts the emitter's own tokens appear somewhere in the string. Tautology-adjacent; not an RDF/Turtle parse. D6 leaned on it as the pre-emit correctness gate. |
| **`semantic-versioning-system.lisp`** | **KEEP** (grouped "versioning core") | **RESTRUCTURE/REPLACE** | A **third** versioning seat (μία-έδρα violation): semver category error, pipe-join hash with no domain separation/escaping, wall-clock in identity/emit (kills determinism), single-digit-major parse bug. |
| **`corpus-fingerprint.lisp`** | **KEEP** | **UPGRADE** | Best-engineered seat in its layer, but its headline claim ("codifies PERFECTLY, PROVES it") is unearned: it proves **golden→served no-drift**, never **golden→ΦΕΚ fidelity**. A first mis-read is enshrined and then "certified correct forever." |
| **`corpus-provenance.lisp`** | **KEEP** | **UPGRADE** | `%ts` silently fabricates `2025-01-01` on a malformed date inside `ignore-errors` — a synthetic epoch in a PROV-O document. Violates *no-fabrication* / τίμια άγνοια. |
| **`narrative-provenance.lisp`** | **KEEP** | **UPGRADE** | `verify-provenance-chain` checks only that lists are non-empty and start<end — no hash, no linkage. Returns T on a fully tampered narrative. Exported under "verify." |
| **`provenance-model.lisp`** | **KEEP** | **RESTRUCTURE** | Named "the provenance model," models **build-pipeline** stages (`:parse→:generate-rdf→:anchor`), not legal-authority provenance (source→ΦΕΚ→amendment-chain→premise-trust). Plus a Blake2-labeled-Blake3 hash divergence. |
| **`journal.lisp`** | **KEEP** | **UPGRADE** | Genuinely strong (structural single-writer, compare-and-append), but **no external anchor on the write path** (a whole-file offline rewrite recomputing hashes passes `verify-chain`) and a **torn-create window** (`%fsync-directory` never called in `append-line`) that can lose a genesis record after a `:durable` receipt. |
| **`self-history.lisp`** | **KEEP** | **UPGRADE** | `%entry-hash` = naive `"SEQ|AT|KIND|TEXT|PREV"` join — the delimiter-injection class `memory.lisp` already killed with `canon-sexp`. Same class, hardened one file over, live here. |
| **`witness-quorum-test.py`** | **KEEP** (grouped proof-CI) | **REPLACE** | Defines `evaluate_quorum` *inside the test* and asserts the toy behaves — zero coupling to any deployed seat (none exists). The clearest tautology in the harness. |
| **`admission-model.sexp`** | **REFACTOR** (Phase-2 "refactor to admit→COMMIT\|REJECT") | **RESTRUCTURE / build the decider** | D6 treats it as refactorable code; on disk it is `:specification-only` prose, **never loaded**, 0/9 theorems, `:implementation-language-target "F* — ΟΧΙ Common Lisp"`. There is **no executable admission decider anywhere in the trusted path.** |
| **`deploy.lisp`** | **KEEP** | **UPGRADE + telos limit** | Single-writer discipline sound, but its telos is a publisher's endgame — "write 5 formats/article to a directory" as the deliverable — not a served/watched observatory. |
| **`version-graph.lisp`** | **REFACTOR** (extend to multi-world) | **UPGRADE-IN-PLACE, but the DEFECT is re-diagnosed** | D6 saw a strong seat needing multi-world typing. The audit confirms the seat is the best in the repo **and** that it is **off the load path** (populated by `submit-genesis!`-ing already-consolidated snapshots + fabricated `:unknown-text` gaps, not real amendment edges) and cannot represent `:renumber/:split/:merge/:delete` — routine for Greek recodifications. |

**Named biggest re-classifications (by mission weight):** (1) `meta-ontology.lisp` KEEP→REPLACE — the
anchored self-definition denies the mission; (2) `emit-graph` REFACTOR→REPLACE — the corpus is not on
the spine at all; (3) `consolidation-proof.lisp` KEEP→REPLACE — D6's own discharge test for
consolidation is a tautology; (4) the temporal **wiring inversion** — the crude seat serves, the
rigorous seat is dark. `[all DEMONSTRATED per the cited audits]`

---

## 3. FOUNDATIONAL RESTRUCTURING PLAN — work on the EXISTING base, honestly scoped

Each item is base work (not a new legal-practice feature), with a **machine-checkable discharge test**.
Ordering is the corrected dependency order from the audits (proof-CI first; fail-closed before anything
trusts the gate; the false-assurance verifiers replaced before their green is cited).
**Governance (CLAUDE.md):** every item is a *proposal*; nothing is touched without a per-phase creator
«εγκρίνω X». This plan does not authorize mutation.

### (a) BEFORE the legal-practice layer — the base must reach these bars first

| # | layer | base work | discharge test (machine-checkable) | tag |
|---|---|---|---|---|
| B0 | proof-CI | Stand up `deployment/verify/assess-gate-plenary.sh` + `authority-v2/run-proofs.sh` green in owner Docker on the **frozen** tree; record the baseline (expected: fail-open present, 0/17). | `ci-comes-up` green; baseline record produced. No seat touched until green. | DEMONSTRATED-harness-exists |
| B1 | admission (F2, **BLOCKING R-4**) | `constitutional-gate.lisp:43–47` fail-OPEN → **fail-CLOSED**: predicate error/timeout/UNKNOWN ⇒ REJECT, error surfaced not swallowed; make ALLOW **unrepresentable** on the error path. | `fail-closed-fuzz`: inject an unconditional-`(error)` predicate ⇒ decision ≠ ALLOW for every covered command; property test over all rules. | DEMONSTRATED defect |
| B2 | integrity | Re-seat corpus emission (`emit-graph`) onto the journaled/atomic/anchored write path; retire naive supersede I/O for records of record; add `%fsync-directory` on genesis append; wire an external anchor (TSA/Merkle leaf) into the append path. | `corpus-crash-test`: crash mid-write ⇒ no torn TTL as record-of-law; `orphan-effect`=0; `offline-rewrite` recomputing all hashes ⇒ external-anchor mismatch flags it. | DEMONSTRATED defect |
| B3 | temporal (wiring inversion) | Promote `version-graph` to the point-in-time authority; demote `consolidation-engine` to a renderer of a resolved snapshot; eliminate the **second date order** (no `string<`/`string>` on legal time — one `%time-key`). | `single-date-order`: grep + property test — 0 lexical date comparisons on the in-force path; in-force query routes through `version-graph`; a malformed `effective` ⇒ error, never silent mis-order. | DEMONSTRATED |
| B4 | proof/verify (false assurance) | REPLACE the tautological verifiers: `consolidation-proof` (real op-by-op replay, independent of `consolidate`), `narrative-provenance:verify-provenance-chain` (hash-chain or rename), `witness-quorum-test.py` (delete or test a real seat); relabel `authority-v2/proofs/` ledger-gates so green ≠ "proofs pass". | `mutation-witness` on each renamed verifier: a fabricated per-step/tampered input ⇒ REJECT; positive witness that clean passes. | DEMONSTRATED |
| B5 | ingestion (root of trust) | Add a **source-fidelity admission gate** that *earns* the golden: an independent re-derivation from the authenticated source must agree byte-for-byte (or a recorded human diff sign-off) before ratification. De-hardcode citation (`≤120` clamp gone, drive `*greek-citation-patterns*`, typed cross-corpus edges). | `golden-earned`: seed a mis-read at golden-commit ⇒ ratification refuses; `cite-536`: a reference to article 536 on the Penal Code ⇒ edge retained (currently dropped). | DEMONSTRATED |
| B6 | epistemic (F1) | Re-seat Layer-1 `meta-ontology` as the labelled multi-world authority ontology (drop the `doesNotResolveConflicts/SelectInterpretation` axioms; reconcile with the 25 reasoners); recompute the `system-commit-hash` over the corrected self-model. | `self-model-consistency`: the ontology can type a conflict / DISPUTED procedure as first-class, and its capability axioms do not contradict the shipped `legal-*` reasoners (automated cross-check). | DEMONSTRATED |

### (b) ALONGSIDE the new legal-practice pieces — base work that runs concurrently

| # | base work (on existing seats) | pairs with new piece | discharge test | tag |
|---|---|---|---|---|
| A1 | Extend `version-graph` with `:renumber/:split/:merge/:delete` replay semantics; add multi-world typing (`Position(Q)=⟨AF,W,A,Λ⟩`). | epistemic-store / multi-world | `no-silent-collapse`; recodification (renumber) replays to exact hashes. | DEMONSTRATED gap |
| A2 | Partition `memory.lisp` per-matter (isolation is *absence of a handle*, not a `WHERE`); re-seat `legal-conflict-resolution` as multi-world edges + EU/ECHR cross-order. | matter-isolation / compliance-seat | `cross-matter-read`=0 bytes; `meta-norm-enumeration` emits the *set* + UNDECIDED. | DEMONSTRATED |
| A3 | Build the executable admission decider K (verified toolchain, or a total CL decider + N-version cross-check as declared interim); discharge or downgrade T1–T9. | K-adm / K-typ / K-prf | `bypass-fuzz` 0 orphan COMMITs; `determinism-replay` bit-identical; N-version diff. | DEMONSTRATED (0/9 today) |
| A4 | Populate ≥2 authoritative acquisition channels (institutional ΦΕΚ + EU-CELLAR); deploy the daemon as an always-on unit; make amendment-extraction misses first-class review events (not silent pass-through); add a content-hash to `seen` so a *διόρθωση σφάλματος* re-issue is not dropped. | observatory feeds | `two-channel-consensus` real; `daemon-alive`; corrected-reissue not skipped. | EMPIRICAL (unconfigured today) |
| A5 | BUILD decision + judge-registry + **doctrine** intake feeds (Άρειος Πάγος/ΣτΕ/ΔΕΕ/ΕΔΔΑ) routed to `parse-decision-text`, not the legislation feed (models exist, intake is NEW). | named-judge / doctrine axis | `decision-feed`: a fetched decision yields a `kind "decision"` item + judge-with-role record. | IMPLEMENTED parser / MISSING intake |
| A6 | Deploy-telos: `deploy.lisp` "filesystem truth" → served/watched observatory as the terminal; key custody → HSM/KMS + rotation/revocation (deployment layer). | serve+watch surface | `served-query`; `key-rotation` exercised. | DESIGN-ENTAILED |
| A7 | Sub-package the 133-flat `source/`; split the god-files (`version-graph` storage/model/parsing; `syntagma/parsing` 151 defuns; `legal-ast`); one admission door (retire the v1/v2/17-gate smear). | scaling of the tree | `seat-uniqueness` (`git log -S` + hash-seat-registry); `system-load` clean. | DEMONSTRATED |

---

## 4. REVISED EFFORT PICTURE — correcting the record I gave the founder

**Earlier framing (DELIVERABLE-6, and what I implied to the founder): "the base is largely sound —
KEEP most seats, light-REFACTOR a few, then add the legal-practice layer." That was wrong, and I correct
it here.** `[the correction is DESIGN-ENTAILED from the six audits]`

The base is **materially more than a small refactor** — but it is **not a rewrite**. Precisely:

- **NOT small-refactor:** the work is **base restructuring at ≥3 architectural levels** — the epistemic
  self-model (identity-only → multi-world), the provenance/root-of-trust layer (pipeline-provenance +
  golden-vs-served → legal-authority provenance + source-fidelity gate), and the deploy telos
  (publish → observe) — **plus** closing the BLOCKING fail-open gate, **plus** re-seating the corpus
  writer onto the spine, **plus** re-wiring the temporal authority (rigorous seat onto the load path),
  **plus** replacing four false-assurance verifiers, **plus** building the admission decider that does
  not exist. ~13 seats the prior map marked KEEP move to UPGRADE/RESTRUCTURE/REPLACE/DELETE (§2). This
  is not "add features on a sound base"; it is "make the base sound, then add features."
- **NOT a rewrite:** the salvageable spines are real and top-tier — `merkle-authority`,
  `timestamp-authority`, `jws-authority`, `legal-authority-receipt`, the journal's single-writer core,
  `version-graph`'s bitemporal engine, `authority-evidence-replay`, and the whole Machine-A
  (N-version + golden-vector + mutation-witness) harness are KEEP and are the correct *template* to
  extend to the mission surface. The failure is **composition and wiring**, not raw capability.

Honest one-line effort correction: **what I called a small refactor is, at minimum, six pre-requisite
base-restructuring workstreams (one BLOCKING) before the legal-practice layer can stand on the base,
running concurrently with seven alongside-workstreams — on a salvageable but mis-wired foundation, not a
sound one.** `[DESIGN-ENTAILED]`

---

## 5. THE SINGLE MOST IMPORTANT HONEST SENTENCE FOR THE FOUNDER

**What the repo REALLY is today is a production-grade, cryptographically-attested *static publisher of
the Greek Constitution* whose own anchored self-model formally declares that it holds no conflicts and
no interpretations — with a genuine but *unwired* observatory/reasoning substrate bolted alongside and
contradicted by that self-model; and "the top legal observatory of Greece" requires the opposite of what
the base currently protects: its real integrity, temporal, admission, and proof machinery must be moved
off self-metadata and the publisher pipeline and onto the load-bearing legal seats — the corpus writer,
the point-in-time authority, the admission decider, the source→ΦΕΚ root of trust, and a self-model that
can hold conflicting authorities and competing construals as first-class objects — before, not after, a
legal-practice layer is added.**

---

## BLOCKING residuals carried, not wordsmithed away

- **R-4 / F2 — fail-OPEN admission gate** (`constitutional-gate.lisp:43–47`). BLOCKING until B1 discharges. `[DEMONSTRATED]`
- **F1 — anchored non-normative self-model vs 25 shipped reasoners.** Base-architecture contradiction. BLOCKING until B6. `[DEMONSTRATED]`
- **Root-of-trust hole — ΦΕΚ→text edge has no verifier.** The whole downstream guarantee chain anchors to an unverified first extraction. BLOCKING for a "trusted spine" claim until B5. `[DESIGN-ENTAILED / DEMONSTRATED code paths]`
- **Substrate contradiction** — `version-graph` runs on the append-log `authority-v2/store` explicitly forbids as final; unreconciled (interim-with-phase-death, or build the proven substrate). `[DEMONSTRATED]`
- **0/17 theorems discharged; no executable K.** The trusted-spine's root seat does not exist as code. `[DEMONSTRATED]`
- Carried from the path-transformation and unclosed by base work: R-1 (novel-at-speed), R-2 (honesty-tax/advocacy register), R-3 (shared-population blind spot), R-5 (verifier-calculus F≤F3), R-6 (e-filing deadline hole), R-7 (AI-Act/GDPR/privilege retention), R-8 (convergence≠evidence), R-9 (DLP-classifier-in-TCB). Contained-and-disclosed or structurally open, never claimed closed. `[per DELIVERABLE-6 §residual]`
