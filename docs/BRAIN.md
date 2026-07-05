# The reasoning brain — architecture, theory, use, verification

This is the maintainer reference for the deterministic reasoning layer of the corpus:
what it is, the modules that implement it, the theory it rests on, how to run it, and
how it was verified. Every conclusion the brain produces carries a **machine-checkable
proof** — the point of the whole design.

> **Why symbolic, not statistical.** A court does not accept "probably". The brain is a
> deterministic symbolic reasoner (knowledge + rules + inference), the discipline Common
> Lisp was built for. It never guesses; it derives, and it shows its work. An LLM, at any
> layer here, would only ever be an untrusted *scout* whose suggestions a deterministic
> gate must verify.

---

## Architecture

```
                       ┌────────────────────────────────────────────┐
   new ΦΕΚ / change →  │  facts  (:references / :changed / :repealed │
                       │          / :conflict / :in-force …)         │
                       └───────────────┬────────────────────────────┘
                                       │
   TBox ─ greek-legislation-ontology   │   (ranked sources, structural units,
     (the schema: what the law IS)     │    norm typology) → compiled to facts
                                       ▼
   L1 ─ legal-inference-engine   ── consequences of a change (defeasible)
        (well-founded JTMS)            │
   L2 ─ legal-conflict-resolution ── which provision prevails; hierarchy validity
   L3 ─ legal-temporal            ── what was in force on date D; ultra-activity
                                       │
   wiring ─ legal-reasoning-bridge ─ lifts the LIVE citation graph into facts,
                                     runs the engine  →  CLI  --reason
                                       ▼
                         conclusions + JTMS PROOF TREES
```

Everything above the facts line is **pure**: it reasons over fact tuples (lists like
`(:references "astikos" "1417" "astikos" "15")`). Thin adapters lift the real corpus
(citation graph, consolidation ledger, ontology) into those facts — no legal structure
is re-implemented in the reasoner.

---

## TBox — `source/greek-legislation-ontology.lisp`

A formal domain ontology of Greek law, built the maximal-CL way: **the CLOS class graph
IS the `rdfs:subClassOf` hierarchy** (homoiconic — one truth for the taxonomy).

- **`defconcept`** — one macro form declares the class, bilingual (EL/EN) `rdfs:label`s,
  an authority `rank`, and alignment (`skos:closeMatch`) to **ELI** and **Akoma Ntoso**.
- Four axes: **sources of law with RANK** (Σύνταγμα 1 ‹ διεθνής/ενωσιακό 2 ‹ τυπικός
  νόμος 3 ‹ π.δ. 4 ‹ υπ. απόφαση 5 ‹ κανονιστική 6 — the substrate of *lex superior*);
  **structural units** (Βιβλίο…περίπτωση, Akoma-Ntoso aligned); **norm typology**
  (obligation/prohibition/permission/definition/sanction/… — substrate for deontic L4);
  **legal events** (enactment/amendment/repeal/entry-into-force).
- Concepts are discovered from the MOP class graph (`all-concepts`); `emit-ontology-ttl`
  serialises the whole TBox to **OWL 2 / RDFS Turtle** so `reasoning-authority` (OWL 2 RL)
  and any triplestore consume it. `rank<=` / `overriding-source` expose the ranks to L2.
- **Extend:** a new `defconcept` appears in the emitted OWL and is reasoned over
  automatically — nothing else changes.

---

## L1 — `source/legal-inference-engine.lisp`

A **non-monotonic truth-maintenance system with well-founded semantics** — the golden
standard for defeasible reasoning, which law *is* (a rule holds UNLESS an exception
applies; *lex specialis derogat legi generali*).

- **Justifications carry an IN-list (support) and an OUT-list (defeaters)** — real
  negation as failure. A fact is believed iff a justification has all IN-list nodes IN
  and all OUT-list nodes OUT.
- **Belief = the canonical well-founded model**, computed by the **Van Gelder alternating
  fixpoint** (`A(S)` antimonotone; `K0=∅`, `U=A(K)`, `K'=A(U)`, to convergence). It is
  **deterministic, order-independent, always terminating, and correct on paradoxical odd
  loops** (they resolve to OUT — never a hang, never an arbitrary stable model).
- **`defrule`** — the DSL: `:when` (support patterns), `:unless` (safe defeaters, vars
  bound by `:when`), `:then` (consequent). Rules are `legal-rule` subclasses discovered
  via the MOP class graph.
- **Proofs are DATA** (homoiconic): `explain` returns the derivation as a nested
  s-expression; `explanation->string` prints it, including `∤ εφόσον ΔΕΝ ισχύει …` — the
  defeaters that had to be OUT and correctly are.
- L1 rule set: `consequential-amendment` (who cites a changed article — UNLESS repealed),
  `cascade-amendment-impact` (transitive closure), `dangling-reference` (citation to a
  repealed provision).

---

## L2 — `source/legal-conflict-resolution.lisp`

Which of two conflicting provisions prevails, and whether a purported amendment is even
valid — with a proof. **Reuse, no engine change:** the ontology's ranks are *compiled
into facts* (`:outranks SUPERIOR INFERIOR`), so the rules stay pure declarative patterns.

- `conflict-is-symmetric` — derives the reverse pair so resolution fires in either order.
- `lex-superior-resolves` — the higher-ranked source prevails.
- `lex-specialis-resolves` — the more specific prevails, UNLESS repealed (defeasible).
- `lex-posterior-resolves` — the later prevails, UNLESS the earlier is more specific
  (encodes *lex specialis derogat legi posteriori generali* directly in its `:unless`).
- `invalid-subordinate-override` — a subordinate act purporting to amend a higher source
  (e.g. a ministerial decision amending a formal law) is **void**, not merely lower —
  a real validity check.
- Entry points: `seed-hierarchy`, `resolve-conflicts`, `hierarchy-violations` (each
  returns verdicts with proof trees).

---

## L3 — `source/legal-temporal.lisp`

Point-in-time law: what was in force on date D, and which version governs an act.

- **Interval calculus** — half-open validity intervals `[from, to)` so consecutive
  versions tile time with neither gap nor overlap; the thirteen **Allen relations**
  (`allen-relation`). ISO-8601 dates compared as strings (lexicographic = chronological)
  — no lossy date parsing in the trusted path; NIL bounds mean −∞/+∞.
- `point-in-time` / `point-in-time-proof` — the AS-OF snapshot and, per provision, the
  interval that selects its in-force version (or a `:temporal-gap` / `:temporal-overlap`
  anomaly).
- `temporal-anomalies` — gaps (a period governed by no version) and overlaps (two
  versions in force at once) across all timelines — real consistency checks.
- `ultra-activity-governs-past-act` — a defeasible rule (*tempus regit actum*): a
  provision in force when an act occurred governs it UNLESS retroactively abolished.

---

## Wiring — `source/legal-reasoning-bridge.lisp` + CLI `--reason`

The one place that turns the **live** corpus into facts and runs the brain, so the engine
stays pure and nothing is duplicated:

- `reference-facts` — the existing citation graph (`orchestrator.references`) →
  `(:references …)` facts (edges never recomputed).
- `reason-impact` / `impact-report` — seed `(:changed CODE ART)`, run, return every
  transitively-affected provision with its proof tree.
- **CLI:** `--reason <corpus> <article>` — impact analysis on the real corpus.

```
docker compose run --rm orchestrator --reason astikos 15
── ΑΝΑΛΥΣΗ ΕΠΙΠΤΩΣΗΣ: astikos άρθρο 15 — 21 επηρεαζόμενα ──
  • άρθρο 1417
        ⇐ κανόνας CONSEQUENTIAL-AMENDMENT
        ∤ εφόσον ΔΕΝ ισχύει (:REPEALED "astikos" "1417")
      • [δεδομένο] (:CHANGED "astikos" "15")
      • [δεδομένο] (:REFERENCES "astikos" "1417" "astikos" "15")
  …
```

---

## Extensibility (open/closed via MOP)

A new capability is a subclass, never an edit to the core:

| Add… | …by | discovered via |
|------|-----|----------------|
| an inference / conflict / temporal rule | `defrule` (`:when`/`:unless`/`:then`) | MOP class graph (`all-legal-rules`) |
| an ontology concept | `defconcept` | MOP class graph (`all-concepts`) |
| a source type (→ lex superior) | `defconcept … :rank N` | ranks compiled to `:outranks` facts |

---

## Verification (all run under SBCL 2.2.9, real vendored deps)

- **Algorithm correctness** (isolated + simulation): monotone consequence; defeasible
  defeat; defeater-absent-holds; **even-loop paradox → both OUT**; stratified negation;
  **order-independence**; JTMS retraction withdraws belief.
- **L2** live: lex-superior, lex-specialis, hierarchy validity (a live test caught and
  fixed a real conflict-symmetry bug).
- **L3** live: point-in-time selection across amendment boundaries; gap after repeal;
  overlap detection; Allen `MEETS`.
- **Ontology** live: 33 concepts, OWL/Turtle emission.
- **Scale:** real poinikos citation graph (536 articles, 394 edges) — impact analysis in
  **116 ms** with the naive matcher + full well-founded fixpoint.
- **Full build:** `orchestrator-infrastructure` and `orchestrator-cli` both build cleanly
  with the vendored dependencies (≈200 files) — the Docker build reproduced.
- **End-to-end:** `--reason astikos 15` → 21 affected provisions, each with its proof.

---

## Deliberately deferred (performance & scope, not correctness)

- **RETE matching** and **incremental belief propagation** — pure performance. The naive
  nested-loop join + full well-founded recompute handle real corpus scale in ~0.1 s;
  RETE would be premature. They do not change any result.
- **L4 (deontic reasoning)** — obligation/permission/prohibition over the norm typology.
  The defeasible well-founded base is the prerequisite and is now in place.

---

## Module & command reference

| Module | Layer | Key entry points | CLI |
|--------|-------|------------------|-----|
| `greek-legislation-ontology.lisp` | TBox | `all-concepts`, `emit-ontology-ttl`, `rank<=` | — |
| `legal-inference-engine.lisp` | L1 | `make-inference-engine`, `defrule`, `run-inference`, `explain` | — |
| `legal-conflict-resolution.lisp` | L2 | `seed-hierarchy`, `resolve-conflicts`, `hierarchy-violations` | — |
| `legal-temporal.lisp` | L3 | `point-in-time`, `temporal-anomalies`, `allen-relation` | — |
| `legal-reasoning-bridge.lisp` | wiring | `reason-impact`, `impact-report` | `--reason <corpus> <article>` |
