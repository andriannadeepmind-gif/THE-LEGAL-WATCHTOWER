# Roadmap: Europe's reference Greek legal-corpus authority

**Goal.** Not "it runs" — *the* authoritative, self-updating, independently verifiable
semantic corpus of in-force Greek law. No band-aids: every gap is closed at the root,
exploiting Common Lisp (CLOS/MOP, conditions/restarts, deterministic builds) to the hilt.

This document is the engineering program. Each pillar lists the **root problem**, the
**principled solution**, the **concrete modules/files**, the **CL techniques**, and the
**acceptance criteria** that make the claim measurable rather than aspirational.

---

## Where we are (measured, 2026-06)

| Code | Articles | State |
|------|---------:|-------|
| Αστικός (`astikos`) | ~2037 | ✅ materialised |
| Ποιν. Δικονομίας (`kpoinikis`) | ~592 | ✅ materialised |
| Ποινικός (`poinikos`) | ~536 | ✅ materialised |
| Διοικ. Δικονομίας (`kdioikitikis`) | ~300 | ✅ materialised |
| Σύνταγμα (`syntagma`) | ~120 | ✅ materialised |
| **Πολ. Δικονομίας (`kpolitikis`)** | **0** | ❌ empty — scanned-only PDF |

Auto-update: wired (`--run-ingestion`, `--auto-update`, `--discover-fek`) but **inactive**
and has folded **zero** amendments (`state/amendment-laws.json` absent; discovery cached
only ΦΕΚ 2024, last-seen #245).

**Root causes, not symptoms:**
1. Ingestion depends on an operator hand-placing a PDF, and silently fails on scanned PDFs.
2. The "self-updating" claim has never updated anything in production.

---

## Pillar 1 — Source of truth (authoritative, multi-source acquisition)

**Root problem.** The "edge" (networked acquisition, OCR, format quirks) has leaked into
the deterministic core. A single scanned PDF (`kpolitikis`) takes the whole code to 0.

**Principled solution.** Make the **consensus acquisition layer** (already sketched in
`make-consensus-ingestion-source`: *institutional > open-data > eu-cellar > scraper >
manual*) the **primary** path. Every provision carries provenance + a confidence; sources
that agree auto-apply, genuine disagreements go to the review queue. Manual PDF becomes
the *last* resort. OCR (Greek-tuned) is a guarded fallback for genuinely scanned-only
instruments — never the main path — and always human-verified.

**Concrete work**
- **[shipped — increment 1]** Pure-Lisp **Office Open XML (`.docx`) adapter**
  (`systems/orchestrator-engine-sbcl/adapters/docx-adapter.lisp`): ZIP (chipz inflate) →
  `word/document.xml` (cxml-stp DOM) → plain text → the existing raw-text FSM
  (`raw-text->iir-articles`). Unlocks `kpolitikis` from the **Ministry of Justice .docx**
  (real digital text) with no OCR and no duplicated parsing. Wired into the engine ASDF,
  `package.lisp`, and `source-normalize` (`:docx` type).
- A `gov-source` provider per authoritative endpoint: ΕΤ/ΦΕΚ API, e-Nomothesia,
  Isokratis, Διαύγεια, **EU Cellar/ELI**. Uniform `acquire(corpus,as-of) → (text, provenance,
  confidence)` generic.
- A `consensus` combinator: N providers → per-article agreement → `(applied | review)`.
- Decouple edge from core: acquisition writes a *signed source bundle*; the deterministic
  pipeline consumes only that bundle (reproducible regardless of network/IP).

**CL techniques.** Generic-function provider protocol; `restart`-driven provider
fallback (`use-next-source`); conditions per failure mode; feature-guarded backends
(`#+chipz`, `#+cxml-stp`) so the build never breaks when a backend is absent.

**Acceptance.** `kpolitikis` materialises ≥1054 articles from the Ministry source;
every article in every code carries a resolvable `prov:wasDerivedFrom`; a fresh checkout
reproduces byte-identical output offline from the source bundle.

---

## Pillar 2 — Codification correctness (the legal moat)

**Root problem.** Anyone can scrape. The differentiator is **provably correct
consolidation**: applying «τροποποιείται / αντικαθίσταται / καταργείται / προστίθεται»
with correct temporal versioning and point-in-time reconstruction.

**Principled solution.** Treat the amendment language as a **grammar**, not a regex pile,
and measure accuracy against a lawyer-maintained gold standard on every build.

**Concrete work**
- Extend `amendment-extractor` into a full operation grammar (target locus, operation,
  payload, effective date) with an explicit AST.
- `golden/<code>.fingerprint.sexp` maintained by counsel; `--verify-all` compares each
  consolidation to authoritative consolidated text (e.g. Isokratis) and **publishes an
  error rate**.
- Point-in-time API already exists (`consolidate-corpus :as-of-date`) — harden with
  property-based tests over (base × amendment-set × date).

**CL techniques.** CLOS AST for operations; `deftype`/`satisfies` domain invariants;
`handler-bind` warning aggregation (continue past one bad provision, flag it); generators
for property tests.

**Acceptance.** Published, reproducible accuracy ≥ target on the gold set; every applied
amendment is explainable (which ΦΕΚ, which words, which date).

---

## Pillar 3 — Completeness (whole in-force corpus, not 6 configs)

**Root problem.** 6 hand-written YAML configs don't scale to Greek law.

**Principled solution.** A per-instrument model driven by the `legal-id` registry, scaling
to thousands of statutes/PDs/ministerial decisions + **case law (ECLI)** + EuroVoc
concepts — configs generated, not authored.

**Concrete work.** Registry → instrument catalogue; ELI minting per instrument; ECLI
ingestion for jurisprudence; EuroVoc concept tagging for cross-lingual discovery.

**Acceptance.** New instrument onboarded with zero bespoke code; catalogue coverage
tracked as a first-class metric.

---

## Pillar 4 — Autonomy that actually runs

**Root problem.** The daemon is off and has folded zero amendments. A self-updating system
that has never updated is a claim, not a capability.

**Principled solution.** Operate it: a monitored production service that detects a new ΦΕΚ
within hours, routes it via the `legal-id` registry, consolidates, and **gates uncertain
changes to a lawyer** — never auto-publishing a low-confidence change.

**Concrete work.** Take `ingestion` out of the opt-in profile; native ΦΕΚ enumeration with
persisted cursor (exists: `state/fek-last-seen.txt`); a review UI for counsel
(`--serve-review`); alerting + an audit trail per published change.

**CL techniques.** The persistent `review-queue` (sexp state, survives restarts);
condition/restart-based ingest loop; deterministic re-emit so a re-run is a no-op.

**Acceptance.** A newly published amending ΦΕΚ appears in the consolidated text (or the
review queue) within the SLA, with a signed provenance trail — observed end-to-end.

---

## The one principle that unifies all four

**Edge vs. core.** Networked acquisition, OCR and format quirks live at a thin, replaceable
edge that emits a *signed, deterministic source bundle*. The core consumes only that bundle
and is pure, reproducible and provable. Today's fragility is the edge (a hand-placed PDF)
having leaked into the core. Every pillar above pushes it back out.

## Sequence

**#1 → #2 → #4 → #3 → #5(verifiability/standards, cross-cutting).**
Pillar 1 simultaneously fixes `kpolitikis` and lays the foundation the rest stand on —
which is why the `.docx` adapter is increment 1, already in the tree.
