# LAWMAX AUTODIDACTIC LOOP
## Nightly Self-Teaching Legal Cognition over Nix Candidate Generations

**Companion of `LAWMAX-OMEGA-PLAN.md`.** That document is the trust spine
(trace, proof, provenance, rollback, adoption, envelope, generations).
THIS document is the learning brain that runs ON that spine. Neither replaces
the other: the spine makes it safe to let the loop run unattended; the loop is
the reason the spine exists.

**Definition — what "AI" means here.** Not an LLM. AI here is the closed,
proof-carrying, reversible self-teaching cycle:

> Corpus → Extraction → Competing Norms → Candidate Self → Shadow Trial →
> Stable Comparison → Human Approval → Adoption → Memory → Better Extraction

NixOS is not merely safety. It is the laboratory in which every nightly
learning attempt becomes a clean, reproducible, disposable-or-adoptable
generation. The stable self is never touched by an experiment.

**The supreme requirement:** LAWMAX is never fed rules by hand, article by
article. It learns alone, knows what it learned, knows what it did not
understand, tests candidate better selves, and asks the human ONLY for the
institutional signature of adoption.

---

## 0. STATUS & PRIORITIES (ordered, blocking)

1. **Verify** that commit `efaea7a` passes the unchanged CONSCIOUSNESS AUDIT v1
   (runs on the creator's machine; P0 code paths are implemented and gate-locked
   — verification only, NO reimplementation).
2. No new architecture manifesto. This document closes the design phase.
3. This file (`LAWMAX-AUTODIDACTIC-LOOP.md`) — done by its existence.
4. Implement the **Nightly Self-Study Runner** (§3) on the existing seats.
5. **Goal 1:** full self-teaching of the Penal Code (ΠΚ) from corpus.
6. **Goal 2:** case-law ratio extraction.
7. **Goal 3:** blind-matter benchmark demonstrating REAL growth of legal
   intelligence (§5.7).

Legal training remains blocked until (1) is green. The loop's first nightly
run IS the beginning of legal training and therefore requires PASS-CANDIDATE
plus creator authorization of the runner itself (the runner is adopted through
`can-adopt` like any other legal-critical change).

---

## 1. MANDATORY SEAT MAPPING (extend, never duplicate — doctrine #16)

| Existing seat | Today's role | Loop extension |
|---|---|---|
| `--self-extend` / self-extension.lisp | provision-to-norm extraction, one gap at a time, on command | **batch corpus self-study**: nightly sweep over ALL provisions |
| `propose-norm-from-provision` | single norm candidate generator | **competing norm bundles**: N interpretations per provision (§2.3) |
| what-if simulator (`source/what-if.lisp`) | legal scenario / change-impact evaluator | **shadow validation of learned rules**: every learned norm judged as a change-proposal |
| `--can-adopt` (`source/adoption-decision.lisp`) | adoption decision engine | **nightly candidate adoption queue**: verdicts computed at night, signatures in the morning |
| adoption ledger (signed SHA-256 records) | institutional memory of decisions | **learned-rule genealogy**: every rule traces to source, extraction version, candidate, tests, verdict |
| episodes / lessons / history (append-only, hash-chained) | failure memory | **ignorance map + retry planning**: what was not understood, why, when to retry |
| 18/18 gates | invariant baseline | every learned candidate MUST pass all of them — non-negotiable floor |
| subsumption suite 29/29 | legal reasoning baseline | no candidate may degrade υπαγωγή — hard regression barrier |
| dream-frame 24/24 / grammar suites (deontic 40/40, γραμματική 28/28, dialogue 67/67) | language/cognition baseline | no corpus-learning patch may break language or cognition frames |
| knowledge packs (`ensure-fresh`, SHA-256, shadow overlay) | declarative knowledge carrier | learning bundles ARE knowledge packs — same format, same shadow gate, same loader |
| autonomy missions / cron surface | manual missions | the Nightly Runner is a mission with a schedule — same seat, now closed-loop |

Any implementation step that creates a second seat for one of these concepts
is rejected on arrival.

---

## 2. THE LOOP (12 stages, one night)

### 2.1 NIGHTLY OBSERVE
Corpus sweep producing a structured **ignorance map** (data, not prose):
readable provisions · unreadable provisions · articles without extracted norm ·
decisions without ratio extraction · concepts without definition ·
conflicts / contradictions / unknowns. Baseline metric: "X/529 readable" —
already computed by αυτομελέτη; the map persists to the lessons stream with
per-item reasons.

### 2.2 EXTRACT
For each provision/case, structured extraction targets:
norm · conditions (προϋποθέσεις) · legal object · act/result · mental element
(where present) · exceptions · defeaters · sanctions/consequences · procedural
dependencies · temporal validity · source/provenance (article identity +
content hash — no knowledge object without provenance).

### 2.3 COMPETE
Never a single extraction. N competing interpretations per provision:
conservative · broader · stricter · defendant-friendly ·
claimant/prosecution-friendly · court-neutral.
All deterministic (distinct extraction strategies, not sampling). Each carries
its strategy tag — the tag is what meta-learning (§2.12) scores.

### 2.4 BUNDLE
Extractions aggregate into learning bundles (= knowledge packs):
Penal Code bundle · Civil Code bundle · procedural bundle · concept dictionary
bundle · case-law ratio bundle · defeater bundle. Each bundle is
content-addressed, carries its provenance list, and is a `change-proposal`.

### 2.5 BUILD CANDIDATE SELF
Each bundle (or bundle combination) becomes a candidate LAWMAX:
Nix derivation — transitionally an OCI image via `dockerTools.buildImage`
(Phase 3½ of the Ω plan). Content-addressing shares everything unchanged;
ten candidates cost one build plus ten packs. **The stable self is untouched.**

### 2.6 SHADOW TEST
Every candidate must pass, hermetically, in full:
18/18 gates · self-evolution gate (23/23 incl. ⑳–㉓) · provenance gate ·
contract/component gates · subsumption 29/29 · dream-frame/grammar suites ·
hash-pinned CONSCIOUSNESS AUDIT · fake-law refusal · trace-off enforcement ·
legal redteam · corpus-specific tests · **synthetic blind matters** (§5.7).

### 2.7 COMPARE (stable vs candidate — numbers, not impressions)
- more extracted VALID norms
- greater corpus coverage (X/529 ↑)
- zero regression on any gate/suite
- zero hallucinated citations (every citation resolves to a hashed source)
- better subsumption on blind matters
- better defeater recognition
- better uncertainty labeling (honest «δεν κατάλαβα» where warranted)
- better temporal validity handling

"Proof of improvement" = strictly better on declared target metrics with zero
regressions elsewhere; coverage bounds stated explicitly.

### 2.8 DECIDE
Per candidate, computed by the SAME `can-adopt` engine:
`ADOPTABLE` · `REJECTED` · `QUARANTINED` · `REQUIRES-HUMAN` · `RETRY-LATER`.
Learning is legal-critical ⇒ in practice every ADOPTABLE lands as
REQUIRES-HUMAN: nothing self-adopts.

### 2.9 HUMAN MORNING QUEUE
The creator wakes to a structured report:

> «Χθες το βράδυ έμαθα: 37 νέες διατάξεις · 112 νέες προϋποθέσεις ·
> 18 defeaters · 9 ratio decidendi · 4 έννοιες που παραμένουν άγνωστες ·
> 2 candidates rejected · 1 candidate requires approval»

Per proposal: what it learned · from where (source + hash) · with what proof ·
which tests it passed · what it improved (numbers) · what risks · rollback
target. All fields computed from the decision object and trace — never prose
without data behind it.

### 2.10 APPROVE / REJECT
The human signs adoption ONLY. No manual article-by-article teaching, ever.
Approval uses the existing creator-approval path; adoption writes the signed
ledger record and (in the Nix era) produces the next generation with rollback
target set.

### 2.11 MEMORY
Every learned object carries genealogy: source · extraction version ·
candidate id · tests passed · adopted/rejected · why · regression warnings.
Rejections are memory too: `RETRY-LATER` items carry their retry condition
(e.g. "blocked on unknown concept «διακεκριμένη περίπτωση» — retry when
defined"). The ignorance map shrinks monotonically or the loop must say why.

### 2.12 META-LEARNING
The system learns HOW it learns:
- which extraction strategy (§2.3 tags) makes fewer errors
- which redteam checks find the most real problems
- which benchmarks are too easy (always-green ⇒ candidate for hardening —
  through proposal + approval, per Ω Phase 11)
- which candidate strategies lead to regressions
Evaluator changes are themselves proposals through `can-adopt` — the loop may
recommend, never self-modify its own judges.

---

## 3. NIGHTLY SELF-STUDY RUNNER (first implementation target)

A single scheduled mission (`--self-study-night` on the autonomy-mission seat):

```
observe → extract → compete → bundle → shadow(what-if + gates) → decide →
write morning queue + memory
```

- Transitional substrate (pre-Nix): shadow overlays (`with-packs-overlay`) in
  one process, exactly like `run-evolve` today — same guarantees, less
  isolation. Nix candidate builds replace the overlay when Phase 3½ lands;
  the runner's interface does not change.
- Every night run leaves a trace root-span; every stage emits events; the
  morning queue is data (`.sexp`) + rendered report.
- Failure of any stage = honest declaration in the morning report, never a
  silent skip.
- The runner itself enters service through `can-adopt` with creator approval.

**Acceptance (Runner v1):** one unattended night over the ΠΚ corpus produces:
an ignorance map, ≥2 competing bundles, shadow-tested with full plenary,
a morning queue with ≥1 decision carrying proof/tests/risks/rollback, zero
mutations of the stable self, and complete genealogy records.

---

## 4. WHAT THE LOOP MAY NEVER DO

- Never adopt without human signature (legal-critical, always).
- Never touch the stable self during experiments.
- Never learn from unprovenanced text (no source hash ⇒ not learnable).
- Never let an LLM into the extraction→adoption path (LLM output may only
  arrive as an untrusted external proposal via the data-only ingest — Ω §7).
- Never report learning as achieved because a pack loads — only because the
  benchmark numbers moved with zero regressions (no pseudo-completion).
- Never hide a failure: unlearned = declared, with reason and retry plan.

---

## 5. GOALS & MEASURES

### 5.1 Goal 1 — ΠΚ full self-study
From "4 active norms" to: every readable ΠΚ provision attempted, each either
(a) extracted as norm with conditions/defeaters and adopted through the queue,
or (b) on the ignorance map with a named blocker. Measure: adopted-norm count,
coverage X/529, blind-matter subsumption score.

### 5.2 Goal 2 — case-law ratio extraction
Structured ratio/obiter objects from the decisions corpus (165+), each hashed
to its source, bound to the articles it applies. Measure: ratios extracted &
adopted, precedent-binding hit-rate on the existing κρίσιμα/προηγούμενα
machinery.

### 5.7 Goal 3 — blind-matter benchmark (the intelligence measure)
A locked, versioned set of synthetic matters (facts + expected verdicts +
expected named gaps) authored/approved by the creator, NEVER seen by the loop
during learning. Growth of legal intelligence = monotone improvement of the
stable self's blind-matter score across adopted generations, with the score
history welded into institutional memory. This is the number that answers
"did it actually get smarter" — everything else is means.

---

*One line to remember:* **Feed it nothing. Let it study, prove, and ask for a
signature.** That is LAWMAX Ω — not merely trusted legal AI, but a
self-teaching, proof-carrying, reversible legal institution.
