"""MODEL D — Matter/system namespace causality and modelled-channel noninterference
(composite EvaluationCut, basis_system_cut monotonicity, cross-namespace backward-only
references, and the observation channel available to a foreign matter).

Covers v0.7 composite EvaluationCut rules and the MatterNoninterferenceContract for the
channels that are inside the declared observation model. Physical/timing channels are
outside this model by construction and remain declared assumptions/residuals.

Properties: CrossNamespaceReferencesAreBackwardOnly, MatterBasisCutMonotonic,
NoModelledCrossMatterObservation.
"""

from __future__ import annotations

from harness import Model, Property

MATTERS = ("A", "B")
MAX_SYS = 2
MAX_MATTER_COMMITS = 2

# state = (sys_commits, chains, observable_counter, contribution_of_A)
#   chains : tuple per matter of tuple[(basis_system_cut, sys_at_commit)]
INIT = (0, ((), ()), 0, 0)


def build(mutation: str | None = None) -> Model:

    def accept_basis(basis, sys_commits, chain):
        if mutation != "allow_future_basis" and basis > sys_commits:
            return False
        if mutation != "allow_basis_regression" and chain and basis < chain[-1][0]:
            return False
        return True

    def actions(state):
        sys_commits, chains, counter, a_contrib = state
        out = []
        if sys_commits < MAX_SYS:
            out.append((f"sys_commit(->{sys_commits + 1})",
                        (sys_commits + 1, chains, counter + 1, a_contrib)))
        for mi, m in enumerate(MATTERS):
            chain = chains[mi]
            if len(chain) >= MAX_MATTER_COMMITS:
                continue
            for basis in range(0, MAX_SYS + 1):
                if not accept_basis(basis, sys_commits, chain):
                    continue
                new_chain = chain + ((basis, sys_commits),)
                nc = tuple(new_chain if i == mi else chains[i] for i in range(len(MATTERS)))
                # the system-observable counter must not move because a matter committed
                leak = 1 if mutation == "counter_leak" else 0
                out.append((f"matter_commit({m},basis={basis})",
                            (sys_commits, nc, counter + leak,
                             a_contrib + (leak if m == "A" else 0))))
        return out

    def backward_only(state):
        _, chains, _, _ = state
        return all(basis <= sys_at for chain in chains for (basis, sys_at) in chain)

    def basis_monotonic(state):
        _, chains, _, _ = state
        for chain in chains:
            bases = [b for b, _ in chain]
            if any(y < x for x, y in zip(bases, bases[1:])):
                return False
        return True

    def no_modelled_cross_matter_observation(state):
        """What matter B can observe must be identical to what it would observe in the
        run with every action of matter A removed."""
        _, _, _, a_contrib = state
        return a_contrib == 0

    return Model(
        name="MODEL D — Matter/system causality and modelled-channel noninterference",
        init=INIT,
        actions=actions,
        properties=[
            Property("CrossNamespaceReferencesAreBackwardOnly", backward_only),
            Property("MatterBasisCutMonotonic", basis_monotonic),
            Property("NoModelledCrossMatterObservation", no_modelled_cross_matter_observation),
        ],
        bounds={"matters": list(MATTERS), "max_system_commits": MAX_SYS,
                "max_commits_per_matter": MAX_MATTER_COMMITS,
                "modelled_observation_channel": "system-visible commit counter + own matter chain",
                "outside_model": "timing, contention, storage latency, traffic (declared residuals)"},
    )


MUTANTS = {
    "allow_future_basis": "CrossNamespaceReferencesAreBackwardOnly",
    "allow_basis_regression": "MatterBasisCutMonotonic",
    "counter_leak": "NoModelledCrossMatterObservation",
}
