# WATCHTOWER FORMAL EVIDENCE — REPRODUCIBILITY LOCK

Requested by the Group-T audit: the evidence bundle must pin the tool artifact and the runtime
so a third party can reproduce every result without trusting this session.

## Industrial model checker
| item | value |
|---|---|
| tool | TLA+ TLC, Version 2.19 of 08 August 2024 (rev 5a47802) |
| artifact | `tla2tools.jar` |
| official artifact URI | `https://github.com/tlaplus/tlaplus/releases/download/v1.7.4/tla2tools.jar` |
| artifact sha256 | `936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88` |
| invocation | `java -XX:+UseParallelGC -cp tla2tools.jar tlc2.TLC -config <cfg> -workers 4 -cleanup <spec>.tla` |

The jar is NOT shipped inside this bundle (redistribution is out of scope for an evidence
pack); it is pinned by URI + digest above. Verify with `sha256sum tla2tools.jar` before use.

## Runtime profile
| item | value |
|---|---|
| JVM | OpenJDK 21.0.10+7 (Ubuntu 24.04), 64-bit, x86_64 |
| Python | CPython 3.11.15 (independently reproduced by Reviewer-B on CPython 3.13.5) |
| OS/kernel | Linux 6.18.44 x86_64 |
| determinism | every model is deterministic and single-run; TLC breadth-first, no randomised simulation mode |

## Specification digests
| file | sha256 |
|---|---|
| `tla/WatchtowerLog.tla` | `c14371322375aff196e2cd4e2c9b208a27ae6ea55452e69d82867e00bfd8eaea` |
| `tla/WatchtowerCore.tla` | `9469b4960ab458bc09b37357cc5e36b35cf237859a031bc5ada9e5f3f7d04231` |

Python model digests are covered by the model-set digest printed at the top of `EVIDENCE-PACK.md`.

## How to reproduce
```
sha256sum tla2tools.jar                 # must equal the digest above
./run_tla.sh                            # regenerates TLA-RESULTS.md
python3 run_all.py                      # regenerates EVIDENCE-PACK.md
```
