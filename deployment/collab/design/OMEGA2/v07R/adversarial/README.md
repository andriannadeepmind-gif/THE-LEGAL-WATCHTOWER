# ADVERSARIAL EVOLUTION — generator / evaluator split

The rule from the mandate: **the generator proposes, the evaluator decides.** No model, agent or
author may declare a design safe; only a deterministic checker may.

- **Generators** — the defect space (`combined.py:MUTANTS`) and the configuration space
  (`combined.py:configs`); the holdout generator (`../holdout.py`) draws from structurally
  different fixture classes under a seed committed before execution.
- **Evaluators — the only authority** — `harness.explore` (bounded exhaustive state search),
  TLC 2.19 (TLA+ invariants), and the per-law exhaustive property checkers. A defect is
  "caught" only when a named property reports a violation, with a trace.
- **Selection** — a defect combination that survives every property is retained as a **finding**,
  not discarded as noise. The first C4 run produced exactly one such survivor and it was a real
  hole in the composite property set, now closed.

Anti-vacuity is enforced at every level: a law whose mutation battery is not fully caught is
declared VACUOUS and its result void; a property satisfiable by refusing to answer is itself a
defect (L1.g).
