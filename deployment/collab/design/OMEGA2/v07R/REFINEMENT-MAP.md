# REFINEMENT MAP — and the honest statement of what is NOT built

The mandate is explicit: properties of an abstract model transfer to an implementation **only**
where a proved correspondence exists. The ladder has five rungs. **Two are built.**

```
INTENT / SECURITY CLAIMS        the 14 breaks, restated as the properties they violate
        ↓  informal, human
ABSTRACT SEMANTIC KERNEL        REDUCED-CONSTITUTION.md — L1 (7 clauses) L2 (6) L3 (3) + OperationEffect (3)
        ↓  BUILT: every clause has an executable model and a mutation battery
EXECUTABLE FORMAL SPEC          kernel/KernelL1.tla (TLC 2.19) · kernel/l1_frontier.py ·
                                kernel/l2_closure.py · kernel/l3_artifact.py · kernel/l0_footprint.py
        ↓  NOT BUILT
REFERENCE IMPLEMENTATION        — absent —
        ↓  NOT BUILT
PRODUCTION IMPLEMENTATION       — absent, and the repository is untouched by design —
        ↓  NOT BUILT
ATTESTED RELEASE / RUNTIME      — absent —
```

## Rung 1 → 2: the correspondence that IS established
| kernel clause | executable model | tool | properties | mutants |
|---|---|---|---|---|
| L1.a · L1.b · L1.e | `KernelL1.tla`, four designs | TLA+ / TLC 2.19, exhaustive | `AuthorisationIsGenuine`, `NoInvalidationBetweenAuthAndLanding`, `OnePerPosition` | design comparison (`local_view` violates, `kernel_L1` holds) |
| L1.d · L1.f · L1.g | `l1_frontier.py` | exhaustive enumeration, 6.000 cases | `SelectionSound`, `NoGuessOnAmbiguity`, `FrontierMonotoneInTime`, `NoUnnecessaryUnknown` | 5/5 caught |
| L2.a–f | `l2_closure.py` | exhaustive enumeration | 6 properties | 6/6 caught |
| L3.a–c | `l3_artifact.py` | exhaustive, differential second implementation | 5 properties | 4/4 caught |
| OperationEffect | `l0_footprint.py` | exhaustive over the domain lattice | 3 properties | 3/3 caught |
| composition (C4) | `adversarial/combined.py` | 9.216 configs × 175 defect combinations | 7 composite properties | no survivors |

Tool choice is per suitability, as permitted: TLA+/TLC where the property is about **order and
concurrency**; exhaustive enumeration where it is about **structure and functions** — and there
the enumeration is genuinely exhaustive within declared bounds, not sampling.

## What the missing three rungs mean
Every number in this experiment is evidence about **the model**. It says nothing yet about any
implementation. Building rungs 3–5 requires: a reference implementation, a machine-readable
refinement map (concrete state → abstract state, concrete transition → abstract transition or
stutter), and a trace-conformance checker that rejects a reference trace with no valid abstract
counterpart. Until those exist, no property proved here may be quoted about running software.
