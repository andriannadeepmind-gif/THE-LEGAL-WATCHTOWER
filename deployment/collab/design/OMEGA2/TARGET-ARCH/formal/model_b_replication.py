"""MODEL B — Commit replication (CommitReplicationProfile: fault model, quorum, fencing
epochs, leader change with lock-adoption rule, partition behaviour).

Covers v0.7 CommitReplicationProfile and invariant I-24 (a deployment may claim only the
fault tolerance its profile actually provides).

Three configurations are explored:
  CFT_3       n=3, quorum=2, no Byzantine replica   -> expected: safe
  CFT_3_BYZ   n=3, quorum=2, one Byzantine replica  -> expected: UNSAFE. This run is the
              evidence for I-24: a crash-fault-tolerant profile must not be claimed under a
              Byzantine threat model. A violation here is the intended demonstration.
  BFT_4       n=4, quorum=3, one Byzantine replica  -> expected: safe (quorum intersection
              2q-n = 2 exceeds f = 1, so an honest witness of any committed value survives
              every view change)

SCOPE LIMITATION (declared, not generalized): a single decision instance (one log position)
is modelled. Multi-position log matching / gap-freedom is NOT covered here and is carried as
an explicit residual; the property SingleAuthoritativeHistory coincides with
NoDualCommittedValue at this scope and is therefore not restated as a separate check.

Properties: NoDualCommittedValue, QuorumSafety, NoAuthorityWithoutRequiredQuorum.
"""

from __future__ import annotations

from itertools import combinations

from harness import Model, Property

VALUES = ("A", "B")
MAX_EPOCH = 2
MAX_PARTITION_CHANGES = 2


def build(n: int, quorum: int, byzantine: frozenset[int], mutation: str | None = None,
          name: str = "") -> Model:
    replicas = tuple(range(n))
    if n == 3:
        SCENARIOS = (frozenset({0, 1, 2}), frozenset({0, 1}), frozenset({1, 2}), frozenset({0}))
    else:
        SCENARIOS = (frozenset({0, 1, 2, 3}), frozenset({0, 1, 2}), frozenset({1, 2, 3}),
                     frozenset({0, 1}))
    eff_quorum = quorum - 1 if mutation == "quorum_off_by_one" else quorum

    # state = (epoch, leader, allowed, proposal, locks, promised, acks, committed, pidx, pch)
    #   acks      : frozenset[(replica, value, epoch, reachable_at_ack)]
    #   committed : frozenset[(value, epoch, ack_count, all_ackers_reachable)]
    init = (0, None, frozenset(VALUES), None,
            tuple(("-", 0) for _ in replicas), tuple(0 for _ in replicas),
            frozenset(), frozenset(), 0, 0)

    def actions(state):
        epoch, leader, allowed, proposal, locks, promised, acks, committed, pidx, pch = state
        partition = SCENARIOS[pidx]
        out = []

        # --- leader election: promise quorum + lock-adoption rule
        if epoch < MAX_EPOCH and len(partition) >= quorum:
            live = sorted(partition)
            for pset in combinations(live, quorum):
                liars = [r for r in pset if r in byzantine]
                for lie_mask in range(2 ** len(liars)):
                    reports = []
                    for r in pset:
                        if r in byzantine and (lie_mask >> liars.index(r)) & 1:
                            reports.append(("-", 0))      # Byzantine replica hides its lock
                        else:
                            reports.append(locks[r])
                    real = [(v, e) for (v, e) in reports if v != "-"]
                    if mutation == "ignore_lock" or not real:
                        new_allowed = frozenset(VALUES)
                    else:
                        new_allowed = frozenset({max(real, key=lambda ve: ve[1])[0]})
                    ne = epoch + 1
                    np = tuple(max(promised[r], ne) if r in pset else promised[r]
                               for r in replicas)
                    for cand in pset:
                        out.append((f"elect(l={cand},e={ne},promise={list(pset)},lie={lie_mask})",
                                    (ne, cand, new_allowed, None, locks, np, acks,
                                     committed, pidx, pch)))

        # --- leader proposes a value permitted by the adoption rule
        if leader is not None and proposal is None:
            for v in sorted(allowed):
                out.append((f"propose({v}@{epoch})",
                            (epoch, leader, allowed, (v, epoch), locks, promised, acks,
                             committed, pidx, pch)))

        # --- replicas acknowledge
        if proposal is not None:
            v, e = proposal
            ackers = replicas if mutation == "ack_from_unreachable" else sorted(partition)
            for r in ackers:
                reachable = r in partition
                if any(a[0] == r and a[1] == v and a[2] == e for a in acks):
                    continue
                if r not in byzantine and promised[r] > e:
                    continue  # fencing: an honest replica never acks a superseded epoch
                nl = tuple((v, e) if i == r and r not in byzantine else locks[i]
                           for i in replicas)
                np = tuple(max(promised[i], e) if i == r and r not in byzantine else promised[i]
                           for i in replicas)
                out.append((f"ack(r{r},{v}@{e},reachable={reachable})",
                            (epoch, leader, allowed, proposal, nl, np,
                             acks | {(r, v, e, reachable)}, committed, pidx, pch)))

            backing = [a for a in acks if a[1] == v and a[2] == e]
            count = len({a[0] for a in backing})
            if count >= eff_quorum:
                all_reach = all(a[3] for a in backing)
                rec = (v, e, count, all_reach)
                if rec not in committed:
                    out.append((f"commit({v}@{e},acks={count})",
                                (epoch, leader, allowed, proposal, locks, promised, acks,
                                 committed | {rec}, pidx, pch)))

        # --- bounded network partition / healing
        if pch < MAX_PARTITION_CHANGES:
            for j, s in enumerate(SCENARIOS):
                if j != pidx:
                    out.append((f"partition({sorted(s)})",
                                (epoch, leader, allowed, proposal, locks, promised, acks,
                                 committed, j, pch + 1)))
        return out

    def no_dual_committed_value(state):
        return len({v for (v, _, _, _) in state[7]}) <= 1

    def quorum_safety(state):
        return all(c >= quorum for (_, _, c, _) in state[7])

    def no_authority_without_quorum(state):
        # authority is exercised only on the strength of a quorum of replicas that were
        # actually reachable at the moment they acknowledged
        return all(c >= quorum and reach for (_, _, c, reach) in state[7])

    return Model(
        name=name or f"MODEL B (n={n}, quorum={quorum}, byzantine={sorted(byzantine)})",
        init=init,
        actions=actions,
        properties=[
            Property("NoDualCommittedValue", no_dual_committed_value),
            Property("QuorumSafety", quorum_safety),
            Property("NoAuthorityWithoutRequiredQuorum", no_authority_without_quorum),
        ],
        bounds={"replicas": n, "quorum": quorum, "byzantine": sorted(byzantine),
                "values": list(VALUES), "max_epochs": MAX_EPOCH,
                "log_positions": 1,
                "partition_scenarios": [sorted(s) for s in SCENARIOS],
                "max_partition_changes": MAX_PARTITION_CHANGES,
                "faults": "bounded partition/heal; Byzantine replicas may equivocate on "
                          "acks and suppress their locks at view change"},
    )


def build_cft(mutation: str | None = None) -> Model:
    return build(3, 2, frozenset(), mutation,
                 name="MODEL B/CFT_3 — crash-fault profile, no Byzantine replica")


def build_cft_byz(mutation: str | None = None) -> Model:
    return build(3, 2, frozenset({2}), mutation,
                 name="MODEL B/CFT_3_BYZ — crash-fault profile under a Byzantine replica")


def build_bft(mutation: str | None = None) -> Model:
    return build(4, 3, frozenset({3}), mutation,
                 name="MODEL B/BFT_4 — Byzantine profile, n=4, quorum=3, f=1")


MUTANTS = {
    "quorum_off_by_one": "QuorumSafety",
    "ignore_lock": "NoDualCommittedValue",
    "ack_from_unreachable": "NoAuthorityWithoutRequiredQuorum",
}
