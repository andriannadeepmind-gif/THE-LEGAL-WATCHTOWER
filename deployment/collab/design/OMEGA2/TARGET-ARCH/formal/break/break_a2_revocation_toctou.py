"""BREAK A-2 — time-of-check/time-of-use on capability revocation.

v0.7 §13.3c validates a committed entry with
    ValidateEntryProof(root_class, object_id, entry_proof_ref, policy_at_basis_cut)
Policy is evaluated at the BASIS cut, which is what makes historical replay deterministic.
But revocation is policy too. A commit whose basis cut predates a revocation, and which lands
AFTER that revocation, is therefore authorised by a capability that is already revoked --
and every downstream proof faithfully certifies it.

Exhaustive over the bounded interleavings.
"""
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))
from harness import Model, Property, explore

MAX_CUT = 3
MAX_COMMITS = 2

# state = (cut, revoked_at | None, prepared_basis | None, committed)
#   committed: tuple of (basis_cut, commit_cut, authorised_under_revoked_capability)
INIT = (0, None, None, ())


def build(evaluate_revocation_at_commit: bool) -> Model:
    def actions(state):
        cut, revoked_at, basis, committed = state
        out = []
        if cut < MAX_CUT:
            out.append((f"advance_cut({cut + 1})", (cut + 1, revoked_at, basis, committed)))
        if revoked_at is None:
            out.append((f"revoke_capability@{cut}", (cut, cut, basis, committed)))
        if basis is None:
            out.append((f"prepare(basis={cut})", (cut, revoked_at, cut, committed)))
        if basis is not None and len(committed) < MAX_COMMITS:
            valid_at_basis = (revoked_at is None) or (basis < revoked_at)
            valid_now = (revoked_at is None) or (cut < revoked_at)
            admit = valid_now if evaluate_revocation_at_commit else valid_at_basis
            if admit:
                used_revoked = (revoked_at is not None) and (cut >= revoked_at)
                out.append((f"commit(basis={basis},at={cut})",
                            (cut, revoked_at, None, committed + ((basis, cut, used_revoked),))))
        return out

    def no_commit_under_revoked_capability(state):
        return all(not bad for (_, _, bad) in state[3])

    return Model(
        name=("policy_at_commit_cut" if evaluate_revocation_at_commit else "policy_at_basis_cut"),
        init=INIT,
        actions=actions,
        properties=[Property("NoCommitUnderRevokedCapability", no_commit_under_revoked_capability)],
        bounds={"max_cut": MAX_CUT, "max_commits": MAX_COMMITS, "revocations": 1},
    )


if __name__ == "__main__":
    spec = explore(build(evaluate_revocation_at_commit=False))   # what v0.7 actually says
    fix = explore(build(evaluate_revocation_at_commit=True))     # proposed closure
    v = spec.violations.get("NoCommitUnderRevokedCapability")
    print("v0.7 as written (revocation evaluated at the basis cut):")
    print(f"  search {spec.status}, {spec.states} states")
    print(f"  NoCommitUnderRevokedCapability: {'VIOLATED' if v else 'holds'}")
    if v:
        print(f"  attack trace: {' -> '.join(v)}")
    print("\nproposed closure (revocation is a monotone kill-predicate evaluated at commit time):")
    print(f"  search {fix.status}, {fix.states} states")
    print(f"  NoCommitUnderRevokedCapability: "
          f"{'VIOLATED' if 'NoCommitUnderRevokedCapability' in fix.violations else 'HOLDS'}")
    print(f"\nBREAK A-2 CONFIRMED: {bool(v)}")
    raise SystemExit(0 if v else 1)
