# REVIEW-6 RESIDUAL CORRECTION ADJUDICATION — the two P3 residuals, closed at their seats

**Governing evidence.** The independent report *FINAL TARGETED INDEPENDENT RE-VERIFICATION #6 — STRICTLY
READ-ONLY* over candidate `720452ab…` (unique parent `4ee2b58a…`, tree `092904c8…`), verdict
`OPTION-2 INDEPENDENT RE-VERIFICATION #6 PASSED — VERIFIER INFRASTRUCTURE LOCK ELIGIBLE`, and the creator's
*POST-REVIEW-6 TWO-RESIDUAL PRE-LOCK CLOSURE* order. Two findings, both P3, both outside the verifier lock
boundary, both reproduced before anything changed. Nothing else in the architecture is touched.

**What this document is not.** Not a semantic, legal, security, behavioural, operational or qualification proof;
nothing here freezes, locks or qualifies anything; no verifier, kernel or model is perfect, sound, complete or
freeze-ready; no independent human approval is proven by any PASS.

---

## The two findings

| id | pri | the class, as the report states it | the seat it is closed at | state |
|---|---|---|---|---|
| **R6-1** | P3 (liveness, fail-closed) | after a *fully authorised* removal of a floor (`minimum 0` plus the self-floor reduction it costs), **every** later edge failed permanently: carrying the spent record gave `AUTHORIZATION-FAMILY-UNDEFINED`, dropping it gave `AUTHORIZATION-TAMPERED`, and even an edge that changed nothing failed. The two rules "an authorization is carried unchanged forever" and "every base authorization names a family the base floors" were jointly unsatisfiable once a floor was gone | the lifecycle is **derived**, never written: `SEXP-READER.authorization_state(p, floors)` reads a record's own immutable fields against the floors of the model carrying it and yields exactly one of PROSPECTIVE, CONSUMED, TERMINALLY-SPENT, UNDEFINED. `uni-01` exempts only TERMINALLY-SPENT records from needing a live floor, and only when history put them there | **closed** |
| **R6-2** | P3 (informational only) | the command counted the composed battery with `grep -c ':harness COMPOSED_GATE' …/verification-corpus.sexp` — the one executable lookup by module name the Review-5 correction had not reached. With those facts relocated it printed `0` while the battery still ran all twelve | the informational note takes its number from `run_corpus.py --count COMPOSED_GATE`, which is `SR.read_model(HERE)` — the same whole-model, ROOT-composed read the battery itself uses — over **distinct ids**, so a duplicate is a model-law failure rather than a double count | **closed** |

## R6-1 — the lifecycle, stated exactly

An authorization carries **no state field**. What it is follows from its own immutable fields and from the floor
set of the model that carries it, so no candidate can certify its own record as retired:

| state | when | what it may do |
|---|---|---|
| **PROSPECTIVE** | its family is still floored at exactly its `:previous-minimum` | it can be consumed on the next edge, and only there |
| **CONSUMED** | its family is still floored, but the floor has moved | nothing: a grant is matched on `:previous-minimum`, so it can never be replayed. It stays as historical evidence |
| **TERMINALLY-SPENT** | it authorised `:minimum 0` and its family is floored nowhere | nothing: the removal it authorised has happened. It no longer needs a live floor, and it is still immutable |
| **UNDEFINED** | it names a family floored nowhere and authorised no removal | nothing exists for it to have applied to — `AUTHORIZATION-FAMILY-UNDEFINED`, unchanged |

Three rules keep the exemption from becoming a hole:

* **Only history reaches the spent state.** A record present in the base but **absent from the base's parent**
  was never prospective anywhere: `AUTHORIZATION-SPENT-WITHOUT-HISTORY`. A removal nobody authorised therefore
  cannot be cured after the fact by a record that claims, later, to have authorised it.
* **A spent record is never revived.** While a terminally spent record names a family, that family may not be
  floored again: `AUTHORIZATION-SPENT-FAMILY-REVIVED`. A revived floor would put the record back into
  PROSPECTIVE and hand the same permission out a second time. Re-flooring such a family is a separate creator
  decision; this mechanism does not grant it, and does not pretend to.
* **Everything else is unchanged.** Tampering with or dropping any base record, whatever its state, is still
  `AUTHORIZATION-TAMPERED`; a candidate-introduced record naming an unfloored family is still refused
  (`AUTHORIZATION-MALFORMED-PROSPECTIVE` over `AUTHORIZATION-FAMILY-UNDEFINED`); consumption is still
  per-lineage and per-edge; `:approver` and `:rationale` still attribute a decision and are still not a
  cryptographic or externally validated approval; and the Root Authority still decides which sibling acquires
  canonical standing. No external governance protocol was added and no protection was relaxed.

`uni-01` now prints `UNIVERSE-AUTHORIZATIONS-TERMINALLY-SPENT` beside the base floors, the candidate floors, the
reductions, the consumed records and the prospective ones, so the state of every record is visible before the
verdict rather than inferable from it.

## The fourteen held-out cases

A history cannot be expressed as a corpus row, so these are coded: each builds a real chain of commits in a
throwaway object store — the repository gains no object and no ref — and judges the last edge with the deployed
check. Four are positive controls; without them every refusal beside them would be vacuous.

`X116` prospective removal introduced, nothing reduced (**control**) · `X117` the next edge removes the floor and
consumes the record (**control**) · `X118` a no-op edge after the removal (**control**) · `X119` a second no-op
edge, so the state is a state and not a one-off exemption (**control**) · `X120` the spent record dropped ·
`X121` the spent record altered · `X122` the spent record replayed for a further reduction · `X123` a candidate
writing itself a record that merely looks spent · `X124` a record that authorised no removal used to excuse one ·
`X125` the removed family floored again · `X126` two siblings of one authorised base gaining no authority beyond
the grant · `X127` an unauthorised removal cured after the fact · `X128` the composed count with every such fact
relocated · `X129` the composed count with those facts split across two modules.

The falsifier floor rises from **104 to 118** (106 COMPONENT + 12 COMPOSED_GATE). The schema version rises from
**5 to 6**: the closed `finding-id` set gains `R6-1` and `R6-2`, and the `universe-authorization` declaration
carries the lifecycle. No fact type, field or enum value was removed.

## Scope

Not touched: DDI-1…DDI-4, the archived PRE-DDI artifacts, the original Option-A gates, production code, frozen
v1.4, the Implementation Book, WP-00, the Root Authority, any independent verification path or protection, and
the numeric TCB ceiling, which stays withdrawn. No second authorization system exists. Nothing here locks or
freezes the verifier: this correction awaits an independent two-finding confirmation.
