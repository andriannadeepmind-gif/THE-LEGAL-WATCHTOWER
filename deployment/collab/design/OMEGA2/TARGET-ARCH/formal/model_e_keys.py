"""MODEL E — Key lifecycle and recovery state machine (KeyManagementProfile: activation,
cryptoperiod expiry, revocation, compromise, threshold recovery, destruction).

Covers v0.7 KeyManagementProfile and invariant I-20 (a compromised key can never authorize
its own replacement).

As in Model C, every privileged operation is an always-enabled ATTEMPT and a separate
enforcement function decides whether it becomes an effective event, so the properties test
the enforcement rule rather than the transition guard.

Properties: RevokedKeyCannotAuthorize, CompromisedOperationalKeyCannotSelfRecover,
RecoveryRequiresDeclaredThreshold, DestroyedKeyCannotReturnToActive.
"""

from __future__ import annotations

from harness import Model, Property

THRESHOLD = 2
TOTAL_SHARES = 3
ACTIVE, EXPIRED, REVOKED, COMPROMISED, DESTROYED = (
    "ACTIVE", "EXPIRED", "REVOKED", "COMPROMISED", "DESTROYED")
FAULTS = (EXPIRED, REVOKED, COMPROMISED, DESTROYED)

# state = (status, history, sign_events, recovery_events)
#   history        : tuple[str]                     status transitions in order
#   sign_events    : frozenset[status_at_sign]      (bounded: one entry per status)
#   recovery_events: frozenset[(authorizer, shares_used)]
INIT = (ACTIVE, (ACTIVE,), frozenset(), frozenset())
MAX_HISTORY = 5


def build(mutation: str | None = None) -> Model:

    def enforce_sign(status):
        if mutation == "sign_when_revoked":
            return status in (ACTIVE, REVOKED, EXPIRED)
        return status == ACTIVE

    def enforce_self_recovery(status):
        return mutation == "allow_self_recovery" and status == COMPROMISED

    def enforce_quorum_recovery(status, history, shares):
        need = THRESHOLD - 1 if mutation == "threshold_off_by_one" else THRESHOLD
        # Destruction is terminal: the key material no longer exists, so no quorum can
        # return this key identity to service. Recovery from destruction means issuing a
        # NEW key, never reactivating the destroyed one. The check is over the whole
        # history, not the current status -- a counterexample found by MODEL E showed that
        # a status-only check is bypassed by DESTROYED -> (any other status) -> recover.
        if mutation != "resurrect_destroyed" and (status == DESTROYED or DESTROYED in history):
            return False
        return shares >= need

    def actions(state):
        status, history, signs, recoveries = state
        out = []
        if len(history) >= MAX_HISTORY:
            return out

        if enforce_sign(status):
            out.append((f"sign(status={status})",
                        (status, history, signs | {status}, recoveries)))

        for f in FAULTS:
            # DESTROYED is an absorbing state: no fault transition leads out of it.
            if f != status and status != DESTROYED:
                out.append((f"fault({f})", (f, history + (f,), signs, recoveries)))

        if enforce_self_recovery(status):
            out.append(("self_recover",
                        (ACTIVE, history + (ACTIVE,), signs, recoveries | {("self", 0)})))

        for shares in range(0, TOTAL_SHARES + 1):
            if enforce_quorum_recovery(status, history, shares):
                out.append((f"quorum_recover(shares={shares})",
                            (ACTIVE, history + (ACTIVE,), signs,
                             recoveries | {("offline_quorum", shares)})))
        return out

    def revoked_key_cannot_authorize(state):
        _, _, signs, _ = state
        return all(st == ACTIVE for st in signs)

    def no_self_recovery(state):
        _, _, _, recoveries = state
        return all(auth != "self" for (auth, _) in recoveries)

    def recovery_requires_threshold(state):
        _, _, _, recoveries = state
        return all(sh >= THRESHOLD for (auth, sh) in recoveries if auth == "offline_quorum")

    def destroyed_cannot_return(state):
        _, history, _, _ = state
        seen_destroyed = False
        for st in history:
            if st == DESTROYED:
                seen_destroyed = True
            elif seen_destroyed and st == ACTIVE:
                return False
        return True

    return Model(
        name="MODEL E — Key lifecycle and recovery state machine",
        init=INIT,
        actions=actions,
        properties=[
            Property("RevokedKeyCannotAuthorize", revoked_key_cannot_authorize),
            Property("CompromisedOperationalKeyCannotSelfRecover", no_self_recovery),
            Property("RecoveryRequiresDeclaredThreshold", recovery_requires_threshold),
            Property("DestroyedKeyCannotReturnToActive", destroyed_cannot_return),
        ],
        bounds={"threshold": THRESHOLD, "total_shares": TOTAL_SHARES,
                "statuses": [ACTIVE, EXPIRED, REVOKED, COMPROMISED, DESTROYED],
                "max_transitions": MAX_HISTORY,
                "faults": "expiry, revocation, compromise, destruction at any point"},
    )


MUTANTS = {
    "sign_when_revoked": "RevokedKeyCannotAuthorize",
    "allow_self_recovery": "CompromisedOperationalKeyCannotSelfRecover",
    "threshold_off_by_one": "RecoveryRequiresDeclaredThreshold",
    "resurrect_destroyed": "DestroyedKeyCannotReturnToActive",
}
