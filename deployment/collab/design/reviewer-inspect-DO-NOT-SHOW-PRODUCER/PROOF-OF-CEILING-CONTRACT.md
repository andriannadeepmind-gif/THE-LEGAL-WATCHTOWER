# WATCHTOWER Proof-of-Ceiling Contract — v2-R3 pre-Phase-2 freeze

Version `2.3.0-R3-PRE-PHASE-2-FROZEN-CANDIDATE`, cutoff 2026-08-27.
The JSON contract is canonical. This companion explains what is fixed now and
what later phases are permitted to populate.

## What is fixed before the fresh Phase 2

- The fresh producer is physically separated from the actual baseline, Phase 1,
  every prior Phase-2 answer and the hidden reviewer capsule.
- The producer may submit a candidate or `PHASE_2_BLOCKED`; it cannot accept its
  own work or authorize Phase 3.
- The Phase-2 artifact and evidence schema is answer-neutral and fixed.
- The independent reviewer gates and negative controls are sealed before the
  producer output exists. A later edit opens a new preserved review epoch and
  cannot retroactively certify the first output.
- FOC-15 fixes when the concrete domain, order, material equivalence, invariants,
  evaluator inputs and TCB must be instantiated: after accepted blind Phase 2,
  before any Phase-3 candidate comparison.
- FOC-16 fixes universal escalation: no number of rounds, candidates, reviewers,
  tokens, time or failed attack attempts can authorize success. Success requires
  the universal proof gate.
- FOC-17 fixes continual proof-carrying evolution: a validated new challenger or
  frontier change suspends the current-ceiling claim, forces a new proof epoch and
  permits a successor only through a monotonic non-regression proof and independent
  reproduction.
- FOC-18 fixes strict commercial superiority: CoCounsel Legal, Lexis+ with
  Protégé and Harvey are separate mandatory lower bounds. For every one of the
  three products and every one of the 22 closed mechanism axes, the final
  executable must be strictly better. Equality, averaging, weighting,
  compensation, trade-off, content advantage or `UNKNOWN` cannot pass.
- T6 requires all 66 product-by-axis cells to be `STRICTLY_BETTER`, universal
  refinement and material improvement of every reachable commercial capability,
  and a proper capability superset for each named product.
- FOC-19 and T7 require the result to become the exact implemented evolutionary
  successor of the Andrianna B0 repository. After the blind result is sealed and
  B0 is revealed, the study must enumerate the precise additions, modifications,
  refactors, moves, replacements and removals at path/package/symbol/store/gate
  level, prove preservation, and implement the approved delta without creating a
  parallel system or second authority.

Later phases may populate predeclared evidence fields, construct candidates and
discharge obligations. They may not change the meaning of success after observing
an answer.

## Exact mathematical target

Let `U_T` contain every executable implementation constructible within the sealed
present-day envelope, independently of any winner. Let `D_T = U_T / approx_T` be
the exact quotient by material equivalence and `F_T` the feasible members that
satisfy all hard invariants and universally refine the actual baseline `B0`.

The success theorem is:

`E_star in F_T` and `for every x in F_T, E_star >=_T x`.

Uniqueness additionally requires:

`for every x in F_T, x >=_T E_star implies x approx_T E_star`.

Pareto non-dominance, a tournament victory or the absence of a new challenger is
strictly weaker and cannot receive the final status.

The additional commercial theorem is:

`for every b in B_COMM and every a in A_BIND, StrictBetter_a(E_star,b)`

and, separately for each named product:

`Capabilities(b) proper-subset Capabilities(E_star)`.

This is componentwise and non-compensatory. Being better on one or most axes is
failure. Equality on one binding axis is failure. A missing or inaccessible
comparison remains `UNKNOWN` and is failure. If a commercial product already
occupies a proved absolute ceiling on an axis, strict improvement is impossible
and the requested commercial-superiority claim remains blocked rather than being
weakened after the fact.

The transformational realization theorem is:

`exists Delta_B0: Apply(B0, Delta_B0) = E_star`,

with every approved increment preserving all still-binding B0 capabilities and
invariants and with a total bidirectional architecture-to-repository crosswalk.

## Honest current state

```
P1          = ACCEPTED
P2          = FRESH_RERUN_PREPARED_NOT_LAUNCHED
P3          = UNAUTHORIZED
FINAL_PROOF = NOT_YET_PRODUCED
COMMERCIAL_SUPERIORITY = NOT_YET_PROVED
B0_TRANSFORMATION = NOT_YET_PLANNED
overall     = FINAL_OPTIMALITY_BLOCKED
```

The original Phase-2 lineage remains blocked because its producer-session
isolation record is irrecoverable. This package prepares a genuinely fresh blind
epoch; it does not rewrite the old history.

The structural validators establish only that this frozen package is internally
consistent and untampered. They do not prove the ceiling. The final positive
status remains available only after FOC-01 through FOC-19 and T1 through T7 are
actually discharged and independently reproduced.
