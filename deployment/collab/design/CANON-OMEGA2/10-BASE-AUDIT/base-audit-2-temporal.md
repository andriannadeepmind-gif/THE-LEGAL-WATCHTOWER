# BASE AUDIT — LAYER 2: TEMPORAL / AUTHORITY / VERSION SPINE

**Auditor stance:** adversarial, uncharitable. Every "KEEP" the prior transformation
assigned is treated as a hypothesis to falsify. Claims tagged
THEOREM / DESIGN-ENTAILED / IMPLEMENTED / DEMONSTRATED / EMPIRICAL / HYPOTHESIS / UNKNOWN.
Read = the real code (Read/Grep), not `output/`.

**Mission frame under test:** "top legal OBSERVATORY of Greece" spine — "what Greek law
was in force when," across thousands of interlinked, amended, EU-affected norms. The
question is not "does it run" but "is it correct" and "is it top."

---

## 0. HEADLINE FINDING (the single most serious foundational defect)

**THERE ARE THREE RIVAL TEMPORAL/VERSION SEATS FOR THE SAME CONCEPT, ENCODING
CONTRADICTORY LEGAL-TIME SEMANTICS, AND THE ONE THAT IS ACTUALLY WIRED INTO THE
SERVING CORPUS IS THE CRUDEST ONE.** `[DEMONSTRATED]`

1. `source/version-graph.lisp` — a genuinely rigorous **bitemporal** graph (2614 LOC,
   valid-time × record-time, hash-chained journal, conditions/regimes/scope/Allen
   algebra, integer `%time-key` comparison that *explicitly forbids* lexical date
   compare). This is the seat the brief calls "the heart."
2. `source/consolidation-engine.lisp` — a **single-time** tree-consolidation engine whose
   own header states "ISO-8601 date strings … are **compared lexically**" (line 25-26)
   and whose act order (`act<`, line 404) uses `string<`. It is bitemporal *in the
   docstring of `amending-act`* only: the `recorded` slot exists but **no query path
   ever reads it** — `select-acts`/`consolidate` filter solely on `effective`.
3. `source/semantic-versioning-system.lisp` — a **semver (major.minor.patch)** corpus
   versioner with its own `semantic-anchor` hash and `version-lineage`.

Wiring reality (`grep`): the **serving layer** — `legal-qa`, `legal-references`,
`corpus-eu-links`, `akoma-ntoso-emitter`, `legal-audit-system`, `corpus-diff`,
`corpus-provenance`, `corpus-service`, `static-site`, `corpus-sparql`, `corpus-search`,
`corpus-fingerprint`, `ingestion-daemon`, `ai-*` (≈16 seats) — all answer point-in-time
through **consolidation-engine** (the lexical, single-time one). `version-graph` is
reachable from only ~6 files, four of which are its own satellites. Worse, the bridge
`systems/orchestrator-cli/version-graph-import.lisp` populates the bitemporal graph by
`submit-genesis!`-ing the **already-consolidated CURRENT snapshot** per article, plus
fabricated `:unknown-text` knowledge-gaps for history it cannot reconstruct (line 128,
146) — it does **not** replay real amendment edges from the acts. So the 114-defun
bitemporal machinery is a **parallel cathedral fed from, and subordinate to, the cruder
engine**; where it is populated it holds genesis nodes + gaps, not the amendment/repeal
chain it was built to hold.

**Consequence for the mission:** the operative answer to "what did Article 5 say on date
D" is produced by lexical-string date comparison over an `effective`-only total order —
single-time, no record-time, no re-enactment/suspension/retroactivity/scope, split/merge
unsupported. The bitemporal correctness the project's identity rests on is **built but
not on the load path.** This is a RESTRUCTURE-grade defect: "μία έδρα ανά έννοια" is
violated at the most load-bearing concept in the repo. `[DEMONSTRATED that the seats are
disjoint and the crude one is wired; DESIGN-ENTAILED that this caps correctness]`

---

## 1. PER-SEAT VERDICTS

### 1.1 `source/version-graph.lisp` — VERDICT: **UPGRADE-IN-PLACE** (the seat is strong; its scope and wiring are not)
- **Status of the code itself:** the single best-engineered seat in this layer.
  `[DEMONSTRATED]` It is genuinely bitemporal (`%live-at-p`, `version-at :valid-at
  :known-at`, `%supersede-validity` writes a new record and closes `recorded-until`
  rather than mutating — lines 590-601, 1030-1185). Time is compared via integer
  `%time-key` with real Gregorian validation (`legal-date-p`/`%days-in-month`, leap
  years — lines 106-146), and it *deliberately rejects* `digit-char-p`'s Unicode
  equivocation surface (line 116-121). Identity is domain-separated canonical-hash
  (`%version-hash-2`, `%canon-sexp` fail-closed on non-serializable types — line 471-497).
  Chain is real: `%payload-hash` over the whole record + `%chain-next`, re-verified on
  `load-graph` two ways (payload + chain) and semantically per-kind (record-id must
  re-derive from fields — lines 1209-1459). This is the level the rest of the repo is
  *not* at.
- **Does "law as of date across amendment/repeal/re-enactment chains" actually work, or
  only toy cases?** Partially. `admit-edge!` (line 825) is `replay-then-append`: it
  enforces `from`=current open version hash, replays `to-specs` to exact `to-hashes`,
  quarantines on mismatch (`:conflicted-before-hash`). Chains of
  `:insert/:replace/:repeal/:restore/:correct/:restate` compose correctly with
  bitemporal supersession. Re-enactment is representable via `:restore`. **BUT:**
  - **`:renumber`, `:split`, `:merge`, `:delete` are NOT supported** — `+supported-ops+`
    excludes them (line 239) and `admit-edge!` quarantines them `:unsupported-op` (line
    835-837). Deferred to "Φ3 (import)", which per `autopsy.md`/ground state is **unbuilt**.
    For a *Greek* observatory this is not a corner case: recodifications (new ΚΠολΔ, tax
    code, renumbered articles), article splits and merges are routine. **A seat that
    cannot represent renumber/split/merge cannot map "thousands of interlinked, amended"
    norms.** `[DEMONSTRATED gap; needs it to be TOP, arguably to WORK for real corpora]`
  - **Single-meaning per intersection.** `version-at` returns exactly one winning version
    or raises `temporal-uncertainty`; two versions with the same `from` ⇒ error (line
    1115-1118), >1 overlapping ⇒ error (line 1184). This is correct *hygiene* but it
    means the seat **cannot represent conflicting authorities / competing construals as
    a first-class multi-world object** (see §2). Contested procedure is an error, not a
    typed `DISPUTED`. `[DEMONSTRATED]`
- **God-file / accretion?** 114 defuns, 2614 LOC, but it is **not** an incoherent god-file
  — it has one coherent responsibility (the bitemporal journal-projection) with clean
  sub-modules (types → hashing → journal → queries → conditions → regimes → attestation),
  each guarded. The size is warranted by the domain (Allen algebra, sum-type commencement,
  resolutory conditions). Verdict: **do not RESTRUCTURE the file**; the accretion risk is
  low. The defect is *around* it (scope + wiring), not *inside* it. `[EMPIRICAL, from full read]`
- **Substrate contradiction (see §3.1):** it is built on `orchestrator.journal` — the
  hand-rolled append-log that `authority-v2/store/STORAGE-API.sexp` **explicitly forbids
  as a final substrate**. `[DEMONSTRATED]`
- **Upgrade required (to be TOP):** (a) implement renumber/split/merge/delete replay
  semantics on-seat (close the Φ3 gap) — needed for real Greek corpora; (b) make it the
  *primary* point-in-time seat and demote consolidation-engine to an importer/renderer
  (§0); (c) add the multi-world typing the epistemic layer needs (§2); (d) migrate off the
  forbidden substrate or retire the store doctrine (§3.1).

### 1.2 `source/consolidation-engine.lisp` — VERDICT: **RESTRUCTURE** (demote to renderer; it must not be the point-in-time authority)
- **Concrete defect:** point-in-time correctness rests on **lexical string date
  comparison**. Header line 24-26 ("compared lexically, which coincides with chronological
  order"); `act<` line 404-408 (`string<`); `select-acts` line 410-418 (`string> e
  as-of-date`). This is true only for well-formed, zero-padded, same-format ISO dates —
  the *exact* fragility `version-graph.lisp` spent a whole `%time-key` seat to eliminate.
  A malformed or differently-formatted `effective` silently mis-orders amendments ⇒ wrong
  in-force text with **no error**. `[DEMONSTRATED]`
- **"Bitemporal" is docstring-only.** `amending-act` documents EFFECTIVE/ENACTED/RECORDED
  as "διτεμπορικοί άξονες" (line 117-124), but `recorded` is never consulted by any query;
  `consolidate` is single-time on `effective`. So "as-of" answers cannot distinguish "what
  we knew then" from "what we know now" — the core bitemporal question the observatory
  must answer for audit/liability. `[DEMONSTRATED]`
- **`:if-missing :skip` silent no-op** (line 293-301): an amendment whose target article
  is absent can be *tolerated and silently dropped* (used for "auto-derived" ops). In a
  serving corpus this is a silent completeness hole — an amendment that "didn't apply"
  leaves no surfaced trace at the consolidation layer. `[DEMONSTRATED]`
- **needs-it-to-WORK vs TOP:** the engine *runs* and is deterministic; it is *not correct*
  as a legal-time authority (lexical time, single-time, silent skip). For a TOP
  observatory this cannot be the seat that answers in-force questions.
- **Upgrade:** stop using it as the point-in-time authority; route in-force queries through
  `version-graph`; keep this engine only as a **renderer** of a resolved snapshot. If kept
  at all, replace `string<`/`string>` with the `%time-key` seat (do not have two date
  orders in one repo).

### 1.3 `source/consolidation-proof.lisp` — VERDICT: **REPLACE** (the "proof" is a tautology; the header oversells it)
- **The verifier does not do what its header claims.** Header (line 8-12): "A third party
  (or --verify) can then **REPLAY the ledger on the base** and confirm the exact
  consolidated result. Truth derived by a verifiable function … not asserted." The actual
  `verify-consolidation-ledger` (line 113-123) **does not replay the ledger**. It calls
  `build-consolidation-ledger` again — i.e. **re-runs `consolidate` (the same code)** — and
  compares the *fresh* run to the stored one. This proves **determinism**, not correctness,
  and it is **not independent** (same function, same process). `[DEMONSTRATED — this is a
  test tautology, a finding, not assurance]`
- **It checks step COUNT, not step content.** Line 120-122 compares base-hash, result-hash,
  and `(/= (length steps) (length steps))`. The per-step `before-hash`/`after-hash` (the
  only thing that would make the ledger a *replayable proof*) are **never compared**. A
  stored ledger with entirely fabricated per-step hashes but a matching step-count and
  final result passes `:ok`. `[DEMONSTRATED]`
- **needs-it-to-WORK vs TOP:** this is worse than absent — it is **false assurance**. A
  reviewer trusting a green `verify-consolidation-ledger` believes the consolidation was
  independently replayed; it was not.
- **Upgrade/replace:** write a *true* replayer that takes the stored ledger + the base and
  applies **only the recorded steps** (op-by-op, checking each `before-hash` against the
  running text and each `after-hash` after applying), independent of `consolidate`. Better:
  bind consolidation proof to the `version-graph` `admit-edge!` replay (which already is a
  real replay-then-append with hash binding) and retire this seat.

### 1.4 `source/legal-conflict-resolution.lisp` — VERDICT: **RESTRUCTURE** (single-world toy meta-law; this is exactly `reject-A #1`)
- **It produces single winners, not a multi-world position.** Rules derive
  `(:prevails …)` / `(:invalid-override …)` (lines 76-112). lex-superior / specialis /
  posterior are encoded as JTMS rules with **hardcoded priority** — e.g. lex-specialis
  beats lex-posterior via a bare `:unless (:more-specific …)` (line 111). When the
  meta-norms *themselves* conflict, the code silently applies one hardcoded resolution
  instead of **surfacing the meta-conflict**. This is precisely the "unvalidated,
  silently-privileged construal of contested Greek/EU meta-law" the CANON's `reject-A`
  KILL-SHOT #1 rates FATAL. `[DEMONSTRATED single-world; DESIGN-ENTAILED it is the flagged flaw]`
- **No EU/ECHR meta-order.** There is *no* representation of CJEU primacy, conforming
  interpretation, *contra legem* disapplication, or ECtHR cross-order effect. For a system
  whose binding is "EU/ECHR inside the Greek order," the norm-conflict seat models **only**
  the domestic source pyramid (Σύνταγμα ‹ νόμος ‹ π.δ. ‹ υπ.απόφαση). `[DEMONSTRATED absence]`
- **Rank comes from an ontology it reflectively pokes** (`find-symbol "CONCEPT-RANK"` etc.,
  lines 50-60) — the meta-law priority is data in another package, unvalidated here; a
  wrong rank silently produces a wrong `:prevails` with a JTMS "proof" attached (proof of
  derivation, not of legal correctness). `[DEMONSTRATED]`
- **needs-it-to-WORK vs TOP:** works as a domestic lex-superior demo; nowhere near TOP for
  Greek/EU reality. It cannot represent "AP chamber split, both live," "directive vs statute
  pending CJEU," or competing construals — the multi-world requirement.
- **Upgrade:** re-seat conflict as **edges in a multi-world position** (conflicts
  first-class, emit the *set* of resolutions per meta-norm ordering + UNDECIDED where
  meta-norms clash), add EU/ECHR cross-order attack/support edges, and subject the priority
  calculus itself to formalization-fidelity review (it is F≤F3, never THEOREM).

### 1.5 `source/authority-evidence-replay.lisp` — VERDICT: **KEEP-AS-IS** (strong; genuinely recompute-and-compare)
- This is the second-tier verifier done *right*. `[DEMONSTRATED]` It rejects declared roots
  and recomputes: closed bundle schema with duplicate-key reject (line 66-80); `bundle-id`
  binds **all** components (line 133-155); hermetic graph reconstruction in a nonce body with
  cleanup on failure (line 345-359); source→spans→extraction→normalization→graph-text
  byte-equivalence (`%apply-spans` forbids scatter/drop forgery by requiring **exactly one
  contiguous span**, line 253-269 — a real anti-tamper insight); verifier-set exact equality
  (line 579-584); external delegation anti-rollback/equivocation/compromise (line 587-609);
  the TRA anchor is *derived from the verified envelope, not from the TRA itself* (line
  316-329, kills circularity).
- **Honest limits (not defects):** `%normalize-legal-text` is only whitespace-trim (line
  271-274) — declared as "the one seat, extensible"; multi-span excerpting explicitly
  deferred with a stated reason. These are disclosed scope limits, not silent gaps.
- **One coupling risk (UPGRADE-later, not blocking):** it depends on `vg::%make-verified-anchor`
  (a private cross-package internal, line 322) — reaching into `version-graph` internals
  couples the two seats at a private boundary. `[DEMONSTRATED — brittleness, not a
  correctness bug]`
- **needs-it-to-WORK vs TOP:** already near TOP for what it covers. Its value is only as
  large as what feeds it — and today the amendment edges it would replay are mostly not
  present in the wired graph (§0).

### 1.6 `source/corpus-provenance.lisp` — VERDICT: **UPGRADE-IN-PLACE** (a fabrication-adjacent silent fallback)
- **Silent date fabrication.** `%ts` (line 35-39): "**fall back to a fixed deterministic
  epoch when absent/malformed**" — a malformed `effective`/`source-date` becomes
  `2025-01-01` silently, and it is wrapped in `ignore-errors`. A provision with a bad date
  gets a **fabricated timestamp** in its PROV-O provenance document. This violates
  "no fabrication" and "τίμια άγνοια": the honest behavior is UNKNOWN/refuse, not a
  plausible-looking fake epoch. `[DEMONSTRATED]` (Contrast `consolidation-engine`'s own
  `legal-document` docstring line 107: "NIL = τίμια άγνωστη ⇒ ο emitter αρνείται
  fail-closed (ποτέ πλαστή 1970-01-01)" — this seat does the *opposite* of that stated
  discipline.)
- **needs-it-to-WORK vs TOP:** works; the fallback is a correctness/honesty defect that a
  TOP observatory (and the no-fabrication binding) forbids.
- **Upgrade:** on malformed/absent date, emit no `date_applicability` (as the sibling TTL
  emitter already does via `%xsd-date-or-nil`) or raise — never a synthetic epoch.

### 1.7 `source/provenance-link.lisp` — VERDICT: **KEEP-AS-IS** (honest, real coverage accounting)
- This is a *good* honesty seat. `[DEMONSTRATED]` `validate-provenance` returns real
  violations (missing contract, unresolved component, conclusion-without-proof-link, stale
  source hash — lines 52-89); `trace-coverage` splits legal-critical fns into
  traced/via/debts/**silent**, where `silent` (neither trace nor declared debt) is the
  named unacceptable set (line 91-106); `*trace-debts*` makes un-instrumented functions
  *explicit*, not hidden. No overclaim. Minor: this is coverage *bookkeeping*, not a proof
  the traces are correct — but it does not claim to be.

### 1.8 `source/semantic-versioning-system.lisp` — VERDICT: **RESTRUCTURE / candidate REPLACE** (mediocre; duplicates the versioning concept with weaker discipline)
- **Category error:** legal corpus versions modeled as **semver** (major.minor.patch).
  `generate-version-template` (line 664): "patch = Bug fixes and minor updates," "major =
  Breaking changes"; `previous-version-string` decrements semver (line 715). Legal versions
  are amendment-indexed temporal facts, not software releases. `[DEMONSTRATED]`
- **Weak hashing / equivocation surface:** `compute-anchor-hash` (line 750) hashes a
  `format "~A|~A|~A|~A|~A|~A"` pipe-joined string with **no domain separation and no field
  escaping** — any field containing `|` collides. This is the exact class `version-graph`
  eliminated with `%canon-sexp`. `[DEMONSTRATED]`
- **Non-determinism baked in:** `semantic-anchor` timestamp initform =
  `get-current-timestamp` (line 185); `generate-version-template` emits `(local-time:today)`
  and `get-current-timestamp` into RDF (line 700-712). `corpus-provenance` worked hard for
  byte-identical output; this seat throws determinism away. `[DEMONSTRATED]`
- **Brittle parse:** `(parse-integer (subseq version-string 0 1))` (line 669) assumes a
  single-digit major — "10.2.3" silently parses as major=1. `[DEMONSTRATED]`
- **Banner self-grading:** "World-class implementation" (line 3) — the kind of unearned
  supremacy language the mission's honesty regime forbids.
- **needs-it-to-WORK vs TOP:** it runs; it is a **third versioning seat** with weaker
  discipline than `version-graph` and duplicates the identity/lineage concept — a "μία έδρα"
  violation. Restructure to consume `version-graph` version-hashes/lineage rather than
  compute its own; drop semver; remove wall-clock from identity/emit.

### 1.9 `source/narrative-provenance.lisp` — VERDICT: **UPGRADE-IN-PLACE** (its `verify-provenance-chain` is cosmetic)
- **`verify-provenance-chain` is a tautology.** (line 907) It "verifies" by checking that
  the activities/steps/reviews **lists are non-empty** and `start-time < end-time`, then
  `(every #'cdr checks)`. It verifies **no hash, no cryptographic linkage, no
  tamper-evidence** — yet is named `verify-provenance-chain` and exported. It would return
  T on a fully tampered narrative as long as the lists are populated. `[DEMONSTRATED — false
  assurance, contrast `version-graph:verify-chain`'s real sha256 replay]`
- **needs-it-to-WORK vs TOP:** the narrative/PROV-O emission is fine as documentation; the
  *verifier* is decorative and must be renamed (`summary`/`completeness-check`) or made real.
- **Upgrade:** either hash-chain the narrative steps and verify the chain, or stop calling a
  presence-check "verify."

### 1.10 `source/trace-core.lisp` — VERDICT: **UPGRADE-IN-PLACE** (sound core; banner overclaim)
- Header claims "NSA-GRADE AUDITABILITY," "ZERO-LEVEL TRUST FOUNDATION," "≥90% CL features"
  (self-grading banners the honesty regime forbids). The described invariants (deterministic
  trace-id, no orphan nodes, immutable records) are the right ones; not re-audited line-by-line
  here (out of the temporal core), flagged for the banner and for confirming immutability is
  structural not merely commented. `[EMPIRICAL from header; body UNKNOWN in this pass]`

### 1.11 `authority-v2/` store dirs (store/log/capability/genesis/schema/roles) — VERDICT: **RESTRUCTURE the doctrine** (spec-only, and it condemns the substrate the live seat uses)
- **No implementation exists, by design.** `store/STORAGE-API.sexp`:
  `:implementation-status :absent-by-design`, `:production-writer :disabled`,
  `:substrate-status :externally-blocked` (needs "Perennial 2.0 / GoTxn με απόδειξη
  atomicity+recovery"). Every call is fail-closed. `[DEMONSTRATED]` `grep` finds **no Lisp
  seat** referencing STORAGE-API / admission-model / witness-policy — these are `.sexp`/`.cddl`/`.sh`
  declarations (schema, state model, witness policy, roles ceremony, capability shell), not
  running trusted-path code.
- **The doctrine contradicts the live seat.** `STORAGE-API.sexp` `:forbidden-substitutes`
  explicitly forbids "χειροποίητο intent-log / append-log με fsync" as a *final* substrate.
  But the **operative** bitemporal seat (`version-graph.lisp`) commits through
  `orchestrator.journal` — a hand-rolled append-only sexp journal with `require-durable!`.
  So the authority-v2 doctrine has already **condemned as non-final the exact substrate the
  live temporal spine runs on.** Either the store doctrine is aspirational and should say so
  about `version-graph`, or `version-graph`'s substrate is a declared-interim that must carry
  a phase-death — today it carries neither. `[DEMONSTRATED contradiction]`
- **Honest part:** declaring the store absent rather than shipping a crash-tested append-log
  behind a "done" interface is exactly the honesty the mission demands. The finding is the
  *unreconciled contradiction*, not the honesty.

---

## 2. THE MULTI-WORLD QUESTION (can it represent conflicting authorities / competing construals AT ALL today?)

**Answer: NO — the layer is single-meaning today.** `[DEMONSTRATED]`
- `version-graph.version-at` yields exactly one version or errors on overlap/tie (lines
  1115-1185). Conflicting equal-rank authorities, plural admissible construals of one norm,
  alternative factual worlds, and *contested* (vs derived) procedure have **no type**. The
  CANON architecture (§4) and `autopsy` Claim 10 both require a **labelled multi-world
  authority store**; the code implements a **single-world** store where conflict is an
  *error condition*, not a first-class object.
- `legal-conflict-resolution` collapses conflicts to a single `:prevails` winner (§1.4),
  with hardcoded meta-norm priority and no EU/ECHR order — the opposite of surfacing
  competing construals.
- **This matches the CANON's own BLOCKING items** (autopsy Claim 10 / P-E "no, no, no, no";
  reject-A #1). It is a KNOWN required restructure, not implemented anywhere in this layer.
- **Verdict:** the multi-world requirement is **UNIMPLEMENTED**. A `Position(Q)=⟨AF,W,A,Λ⟩`
  typing must be added over `version-graph` + a re-seated conflict engine. `[HYPOTHESIS that
  version-graph's bitemporal core is a suitable substrate for it — plausible, unproven]`

---

## 3. CROSS-CUTTING DEFECTS

### 3.1 Substrate contradiction (repeated for weight)
`version-graph` runs on the append-log the `authority-v2` store forbids as final. Unreconciled.
Must be resolved on-seat (implement the proven substrate, or explicitly declare
`version-graph`'s journal an interim with a phase-death). `[DEMONSTRATED]` **BLOCKING-adjacent.**

### 3.2 Two date orders in one repo
`version-graph` (`%time-key`, integer, Gregorian-validated) vs `consolidation-engine` /
`version-graph-import` / `legal-qa` (`string<`/`string>`, lexical). A single repo must not
hold two contradictory "legal time" comparisons. The lexical one is wired to serving.
`[DEMONSTRATED]`

### 3.3 Proof/verify seats that don't verify
Two seats named "verify"/"proof" are tautological or cosmetic: `consolidation-proof`
(re-runs the same function, checks step-count not step-content) and
`narrative-provenance:verify-provenance-chain` (checks list non-emptiness). These are
*false assurance*, the most dangerous kind — a reader trusts a green check that proves
nothing. `version-graph:verify-chain` and `authority-evidence-replay` show the seat *can*
be done right; these two must be brought to that bar or renamed. `[DEMONSTRATED]`

### 3.4 Silent fabrication fallbacks
`corpus-provenance %ts` → synthetic `2025-01-01` on bad dates (§1.6). Against the
no-fabrication binding. `[DEMONSTRATED]`

---

## 4. IS THIS CORE ADEQUATE FOR A TOP GREEK OBSERVATORY?

**No — deep restructuring required, but NOT a rewrite of the best seat.** `[DESIGN-ENTAILED]`
The engineering *ceiling* is high: `version-graph.lisp` and `authority-evidence-replay.lisp`
are top-tier and correct within scope. The problem is **composition and wiring**, not raw
capability:

1. **Wrong seat on the load path** (§0): promote `version-graph` to the point-in-time
   authority; demote `consolidation-engine` to a renderer/importer. (RESTRUCTURE)
2. **Structural op gap** (§1.1): implement renumber/split/merge/delete — mandatory for real
   Greek recodifications. (UPGRADE-IN-PLACE on the strong seat)
3. **Single-world → multi-world** (§2): the mission's competing-construal / conflicting-
   authority / EU-ECHR requirement is unimplemented. (new typing + conflict re-seat)
4. **Kill the false-assurance verifiers** (§3.3) and the fabrication fallback (§3.4).
5. **Reconcile the substrate contradiction** (§3.1) and the dual date order (§3.2).

Distinguishing the three levels the brief demands:
- **Exists-and-runs:** all eleven seats. `[DEMONSTRATED]`
- **Correct:** `version-graph`, `authority-evidence-replay`, `provenance-link`. The rest
  have correctness defects (lexical time, tautological proofs, single-world collapse,
  fabricated dates, weak hashing). `[DEMONSTRATED per seat above]`
- **Top-level:** only `version-graph` and `authority-evidence-replay` — and even they are
  undercut by not being the wired spine / by empty inputs. `[EMPIRICAL]`

**The prior "KEEP/light-REFACTOR" assumption is FALSIFIED** for the temporal spine: the
seat that answers the observatory's defining question is the lexical single-time
consolidation engine, guarded by a consolidation "proof" that proves nothing, while the
rigorous bitemporal seat sits off the load path holding genesis nodes and gaps.
