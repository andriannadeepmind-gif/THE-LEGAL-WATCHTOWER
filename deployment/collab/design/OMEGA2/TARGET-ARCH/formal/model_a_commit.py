"""MODEL A — Commit / Cut state machine (RootCommit, prepared state, crash, recovery,
committed entries, transaction coordinates, checkpoint cuts, admission corrections).

Covers v0.7 sections: Root Commit Law (prepare/commit atomicity, intrinsic committed
entries, tx_coord derived from the committed RootCommit), TRANSIENT_PRECOMMIT,
CheckpointCut chain, AdmissionCorrection cut semantics, causal certificate order.

Properties checked: NoHalfCommit, NoObjectCommitCycle, HistoricalImmutability,
CutMonotonicity, NoBackdating, NoSelfCertification.
"""

from __future__ import annotations

from harness import Model, Property

OBJS = ("o1", "o2")          # substantive objects (e.g. legal effect event payloads)
PCS = ("p1",)                # projection certificates (must reference a causal prefix)
MAX_COMMITS = 3
MAX_CUTS = 2
MAX_PREPARED = 2

# state = (prepared, ids, pcref, txs, applied, corrected, cuts, crashed)
#   prepared  : frozenset[str]                      staged, TRANSIENT_PRECOMMIT
#   ids       : frozenset[(name, id_value)]         object identity, assigned at prepare
#   pcref     : frozenset[(pc_name, referenced_head)]
#   txs       : tuple[tuple[str, ...], ...]         intended transaction per commit
#   applied   : tuple[tuple[str, ...], ...]         entries actually made effective
#   corrected : tuple[tuple[str, ...], ...]         admission corrections per commit
#   cuts      : tuple[(control_head, view_at_creation), ...]
#   crashed   : bool
INIT = (frozenset(), frozenset(), frozenset(), (), (), (), (), False)


def prepare_time_id(name: str) -> str:
    """Baseline identity: a pure function of the object payload alone."""
    return f"id({name})"


def build(mutation: str | None = None) -> Model:

    def view(applied, corrected, head):
        add, rem = set(), set()
        for i in range(head):
            if i < len(applied):
                add |= set(applied[i])
                rem |= set(corrected[i])
        return tuple(sorted(add - rem))

    def actions(state):
        prepared, ids, pcref, txs, applied, corrected, cuts, crashed = state
        out = []
        committed_names = {n for c in applied for n in c}

        if crashed:
            # Recovery: deterministic cleanup of TRANSIENT_PRECOMMIT state.
            out.append(("recover", (frozenset(), frozenset(
                (n, v) for (n, v) in ids if n in committed_names),
                pcref, txs, applied, corrected, cuts, False)))
            return out

        # prepare a substantive object (identity fixed here, before any commit exists)
        for o in OBJS:
            if o in prepared or o in committed_names or len(prepared) >= MAX_PREPARED:
                continue
            out.append((f"prepare({o})", (prepared | {o}, ids | {(o, prepare_time_id(o))},
                                          pcref, txs, applied, corrected, cuts, False)))
        # prepare a projection certificate referencing the current control prefix
        for p in PCS:
            if p in prepared or p in committed_names or len(prepared) >= MAX_PREPARED:
                continue
            ref = len(applied) + 1 if mutation == "pc_future_ref" else len(applied)
            out.append((f"prepare_pc({p},ref={ref})",
                        (prepared | {p}, ids | {(p, prepare_time_id(p))},
                         pcref | {(p, ref)}, txs, applied, corrected, cuts, False)))

        # commit the prepared transaction
        if prepared and len(applied) < MAX_COMMITS:
            tx = tuple(sorted(prepared))
            if mutation == "torn_commit" and len(tx) > 1:
                eff = tx[:-1]          # a strict subset becomes effective: torn transaction
            else:
                eff = tx
            new_ids = ids
            if mutation == "id_from_commit":
                # identity re-derived from the commit that carries it -> construction cycle
                new_ids = frozenset(
                    ((n, f"id({n}@{len(applied)})") if n in tx else (n, v))
                    for (n, v) in ids)
            out.append((f"commit({','.join(tx)})",
                        (frozenset(), new_ids, pcref, txs + (tx,), applied + (eff,),
                         corrected + ((),), cuts, False)))

        # commit an admission correction for an already effective object
        for o in sorted(committed_names & set(OBJS)):
            if len(applied) < MAX_COMMITS:
                out.append((f"correct({o})",
                            (prepared, ids, pcref, txs + ((),), applied + ((),),
                             corrected + ((o,),), cuts, False)))

        # take a checkpoint cut
        if len(cuts) < MAX_CUTS:
            head = len(applied)
            stored = view(applied, corrected, head)
            if mutation == "leak_pending_into_cut":
                # quarantined / not-yet-committed material made visible as if it were
                # already admitted knowledge at this cut
                stored = tuple(sorted(set(stored) | set(prepared)))
            if not cuts or head >= cuts[-1][0]:
                out.append((f"cut(head={head})",
                            (prepared, ids, pcref, txs, applied, corrected,
                             cuts + ((head, stored),), False)))
            if mutation == "cut_regression" and cuts and head >= 1:
                bad = cuts[-1][0] - 1
                if bad >= 0:
                    out.append((f"cut_regress(head={bad})",
                                (prepared, ids, pcref, txs, applied, corrected,
                                 cuts + ((bad, view(applied, corrected, bad)),), False)))

        # rewrite an already committed entry (only reachable in the mutated model)
        if mutation == "rewrite_history" and applied and applied[0]:
            rewritten = applied[:0] + (applied[0][:-1],) + applied[1:]
            out.append(("rewrite_commit0", (prepared, ids, pcref, txs, rewritten,
                                            corrected, cuts, False)))

        if not crashed:
            out.append(("crash", (prepared, ids, pcref, txs, applied, corrected, cuts, True)))
        return out

    # ---- properties (the specification; deliberately independent of the mechanism above)

    def no_half_commit(state):
        _, _, _, txs, applied, _, _, _ = state
        # all-or-nothing: every committed transaction is applied exactly as intended
        return all(set(t) == set(a) for t, a in zip(txs, applied))

    def no_object_commit_cycle(state):
        _, ids, _, _, _, _, _, _ = state
        # object identity must be computable from the payload alone, before any commit
        return all(v == prepare_time_id(n) for (n, v) in ids)

    def historical_immutability(state):
        _, _, _, _, applied, corrected, cuts, _ = state
        return all(stored == view(applied, corrected, head) for head, stored in cuts)

    def cut_monotonicity(state):
        *_, cuts, _ = state
        heads = [h for h, _ in cuts]
        return all(b >= a for a, b in zip(heads, heads[1:]))

    def no_backdating(state):
        _, _, _, _, applied, corrected, cuts, _ = state
        for head, stored in cuts:
            legitimate = set()
            for i in range(head):
                if i < len(applied):
                    legitimate |= set(applied[i])
            if not set(stored) <= legitimate:
                return False
        return True

    def no_self_certification(state):
        _, _, pcref, _, applied, _, _, _ = state
        refs = dict(pcref)
        for idx, entries in enumerate(applied):
            for name in entries:
                if name in refs and refs[name] > idx:
                    return False  # certificate binds a control prefix that includes itself
        return True

    return Model(
        name="MODEL A — Commit/Cut state machine",
        init=INIT,
        actions=actions,
        properties=[
            Property("NoHalfCommit", no_half_commit),
            Property("NoObjectCommitCycle", no_object_commit_cycle),
            Property("HistoricalImmutability", historical_immutability),
            Property("CutMonotonicity", cut_monotonicity),
            Property("NoBackdating", no_backdating),
            Property("NoSelfCertification", no_self_certification),
        ],
        bounds={"objects": len(OBJS), "certificates": len(PCS), "max_commits": MAX_COMMITS,
                "max_cuts": MAX_CUTS, "max_prepared": MAX_PREPARED,
                "faults": "crash+recovery at any point"},
    )


MUTANTS = {
    "torn_commit": "NoHalfCommit",
    "id_from_commit": "NoObjectCommitCycle",
    "rewrite_history": "HistoricalImmutability",
    "cut_regression": "CutMonotonicity",
    "leak_pending_into_cut": "NoBackdating",
    "pc_future_ref": "NoSelfCertification",
}
