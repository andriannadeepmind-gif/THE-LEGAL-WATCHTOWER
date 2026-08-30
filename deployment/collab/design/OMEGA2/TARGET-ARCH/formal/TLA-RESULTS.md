## Industrial formal evidence — TLA+ / TLC

tool: Version 2.19 of 08 August 2024
spec digests: WatchtowerLog.tla `c14371322375aff196e2cd4e2c9b208a27ae6ea55452e69d82867e00bfd8eaea`
              WatchtowerCore.tla `9469b4960ab458bc09b37357cc5e36b35cf237859a031bc5ada9e5f3f7d04231`
              tla2tools.jar `936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88`

| model | configuration | outcome | states (distinct) | depth |
|---|---|---|---|---|
| WatchtowerLog | CFT | Model checking completed. No error has been found. | 24121 states generated, 4975 distinct | 11 |
| WatchtowerLog | CFT_BYZ | Error: Invariant NoTwoValuesAtSamePosition is violated | 26398 states generated, 6392 distinct | 10 |
| WatchtowerLog | BFT | Model checking completed. No error has been found. | 288720 states generated, 37071 distinct | 14 |
| WatchtowerLog | BUG_GAP | Error: Invariant NoCommittedGap is violated | 2244 states generated, 1024 distinct | 8 |
| WatchtowerLog | BUG_ADOPT | Error: Invariant NoTwoValuesAtSamePosition is violated | 14371 states generated, 5022 distinct | 10 |
| WatchtowerLog | BUG_TRUNC | Error: Action property CommittedPrefixMonotonicity is violated | 937 states generated, 555 distinct | 7 |
| WatchtowerCore | NONE | Model checking completed. No error has been found. | 2782321 states generated, 390400 distinct | 16 |
| WatchtowerCore | torn | Error: Invariant NoHalfCommit is violated | 80 states generated, 79 distinct | 4 |
| WatchtowerCore | rewrite | Error: Invariant HistoricalImmutability is violated | 646 states generated, 409 distinct | 6 |
| WatchtowerCore | cutreg | Error: Invariant CutMonotonicity is violated | 494 states generated, 288 distinct | 6 |
| WatchtowerCore | leak | Error: Invariant NoBackdating is violated | 61 states generated, 60 distinct | 5 |
| WatchtowerCore | basisfut | Error: Invariant BasisBackwardOnly is violated | 28 states generated, 28 distinct | 4 |
| WatchtowerCore | basisreg | Error: Invariant BasisMonotonic is violated | 3023 states generated, 1301 distinct | 6 |
| WatchtowerCore | resurrect | Error: Invariant DestroyedKeyCannotReturn is violated | 444 states generated, 285 distinct | 5 |
| WatchtowerCore | selfrec | Error: Invariant NoSelfRecovery is violated | 454 states generated, 276 distinct | 5 |
| WatchtowerCore | signrev | Error: Invariant RevokedKeyCannotAuthorize is violated | 274 states generated, 205 distinct | 5 |
| WatchtowerCore | thresh | Error: Invariant RecoveryRequiresThreshold is violated | 48 states generated, 47 distinct | 4 |
