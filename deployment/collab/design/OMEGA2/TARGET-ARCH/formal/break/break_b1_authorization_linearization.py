"""B-1 CONFIRMATION + structural closure test.

Reviewer-B is right: the A-2 fix ("revocation is a monotone kill-predicate evaluated at the
commit cut") is sound only in a single total order. The VLT deliberately has SEPARATE namespace
chains and forbids distributed atomic transactions across them, so a matter writer evaluates
the kill-predicate against its OWN, possibly stale, view of the control chain.

Three designs are compared exhaustively:

  D1 local_view_check   what v0.7.2 + the A-2 fix actually says: the writer checks revocation
                        against the control state IT has seen.
  D2 linearized_grant   authority is exercised through a CommitAuthorizationGrant issued BY the
                        control quorum, so grant and revoke sit in one total control order.
                        Semantics: "granted before revoke" = already-authorised transaction.
  D3 grant_plus_window  D2 plus: the grant expires unless the commit lands before the next
                        control position, so a revoke can also stop already-granted work.

Two properties, to expose the real trade-off rather than hide it:
  NoCommitAuthorisedAtOrAfterRevoke  (weak, what D2 buys)
  NoCommitLandsAfterRevoke           (strong, what D3 buys -- at an availability cost)
"""
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))
from harness import Model, Property, explore

MAX_CONTROL = 3
MAX_COMMITS = 2


def build(design: str) -> Model:
    # state = (ctrl, revoked_at|None, matter_view, grant|None, committed)
    #   grant     : control position at which the grant was issued
    #   committed : tuple of (authorised_at_control_pos, landed_at_control_pos)
    init = (0, None, 0, None, ())

    def actions(state):
        ctrl, revoked, view, grant, committed = state
        out = []
        # every authority-bearing control action occupies its OWN position in the single
        # total control order -- otherwise the order between a grant and a revoke that share
        # a position is undefined and no property about them is provable.
        if ctrl < MAX_CONTROL:
            out.append((f"control_tick({ctrl + 1})", (ctrl + 1, revoked, view, grant, committed)))
        if revoked is None and ctrl < MAX_CONTROL:
            out.append((f"revoke@{ctrl + 1}", (ctrl + 1, ctrl + 1, view, grant, committed)))
        if view < ctrl:
            out.append((f"matter_syncs_view({view}->{view + 1})",
                        (ctrl, revoked, view + 1, grant, committed)))
        if design in ("linearized_grant", "grant_plus_window") and grant is None:
            # the control quorum issues the grant; it refuses once the capability is revoked
            if (revoked is None or ctrl + 1 < revoked) and ctrl < MAX_CONTROL:
                out.append((f"control_issues_grant@{ctrl + 1}",
                            (ctrl + 1, revoked, view, ctrl + 1, committed)))
        if len(committed) < MAX_COMMITS:
            if design == "local_view_check":
                # the writer checks revocation against its own (possibly stale) view
                if revoked is None or view < revoked:
                    out.append((f"matter_commit(view={view},at={ctrl})",
                                (ctrl, revoked, view, grant, committed + ((view, ctrl),))))
            elif design == "linearized_grant":
                if grant is not None:
                    out.append((f"matter_commit(grant@{grant},at={ctrl})",
                                (ctrl, revoked, view, None, committed + ((grant, ctrl),))))
            elif design == "grant_plus_window":
                if grant is not None and grant == ctrl:      # one-shot window: must land now
                    out.append((f"matter_commit(grant@{grant},at={ctrl})",
                                (ctrl, revoked, view, None, committed + ((grant, ctrl),))))
        return out

    def no_commit_authorised_at_or_after_revoke(state):
        revoked = state[1]
        return revoked is None or all(a < revoked for (a, _) in state[4])

    def no_commit_lands_after_revoke(state):
        revoked = state[1]
        return revoked is None or all(l < revoked for (_, l) in state[4])

    return Model(name=design, init=init, actions=actions,
                 properties=[Property("NoCommitAuthorisedAtOrAfterRevoke",
                                      no_commit_authorised_at_or_after_revoke),
                             Property("NoCommitLandsAfterRevoke", no_commit_lands_after_revoke)],
                 bounds={"control_positions": MAX_CONTROL, "max_commits": MAX_COMMITS,
                         "namespaces": "control + one matter", "partition": "matter view may lag"})


if __name__ == "__main__":
    for d in ("local_view_check", "linearized_grant", "grant_plus_window"):
        r = explore(build(d))
        print(f"\n--- {d} ({r.status}, {r.states} states) ---")
        for p in ("NoCommitAuthorisedAtOrAfterRevoke", "NoCommitLandsAfterRevoke"):
            if p in r.violations:
                print(f"  {p}: VIOLATED — {' -> '.join(r.violations[p])}")
            else:
                print(f"  {p}: HOLDS")
