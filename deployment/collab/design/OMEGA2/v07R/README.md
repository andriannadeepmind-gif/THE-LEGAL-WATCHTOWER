# WATCHTOWER TARGET v0.7-R — PROOF-REFINED ADVERSARIAL REDUCTION EXPERIMENT

**NOT a freeze candidate. NOT migration. NOT production. The repository is untouched.**

An experiment in whether the constitution can be REDUCED — 44 free-standing invariants replaced
by a small semantic kernel from which the composition properties follow — instead of patched.

## Read in this order
1. `KERNEL-SIZE-PREDECLARATION.md` — sealed before any attack, so the growth number is honest
2. `REDUCED-CONSTITUTION.md` — the kernel: 9 primitives, L1/L2/L3, Strata A/B/C
3. `CONVERGENCE-REPORT.md` — **the verdict, with the numbers that did not come out clean**
4. `REFINEMENT-MAP.md` — what is proved, and the three ladder rungs that do not exist
5. `KNOWN-BREAK-REPLAY.txt` · `KERNEL-RESULTS.txt` · `ADVERSARIAL-C4.txt` · `HOLDOUT-EVAL.txt`

## Run everything
```
cd kernel && python3 l1_frontier.py && python3 l2_closure.py && python3 l3_artifact.py && python3 l0_footprint.py
cd .. && python3 replay.py && python3 holdout.py
cd adversarial && python3 combined.py
# TLA+: place tla2tools.jar (pinned by URI+sha256 in ../TARGET-ARCH/formal/REPRODUCIBILITY-LOCK.md) in kernel/
cd kernel && java -XX:+UseParallelGC -cp tla2tools.jar tlc2.TLC -config K1_kernel_L1.cfg -workers 4 KernelL1.tla
```

## One-line result
14/14 known breaks close as consequences of general laws with **0** break-specific guards —
at a cost of **+1 primitive and +7 clauses** against a sealed budget of 8 and 12, so the sealed
criterion is **not strictly met**. C6 (are new breaks out-of-class?) **cannot be self-certified**
and awaits the independent adversary.
