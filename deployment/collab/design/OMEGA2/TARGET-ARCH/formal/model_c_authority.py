"""MODEL C — Authority / capability algebra (issuance, bounded delegation, class-specific
Root-write entry proof, egress restriction for privileged data classes).

Covers v0.7 capability model, class-specific EntryProof and the authorization properties
that invariant I-23 requires to be proved rather than only tested.

Every privileged operation is modelled as an ATTEMPT that is always enabled; a separate
enforcement function decides whether the attempt is recorded as an effective event. The
properties are stated over recorded events, so they test the enforcement rule itself and
cannot be satisfied vacuously by an over-restrictive transition guard.

Properties: NoPrivilegeEscalation, DelegationNeverIncreasesAuthority,
NoEgressForRestrictedClasses, RootWriteOnlyWithValidEntryProof.
"""

from __future__ import annotations

from harness import Model, Property

AUTHORITIES = ("WRITE_LEGAL", "WRITE_EPISTEMIC", "EGRESS")
ISSUER_MAX = frozenset(AUTHORITIES)
HOLDERS = ("h1", "h2")
ROOT_CLASSES = ("R_LEGAL", "R_EPISTEMIC")
NEEDED = {"R_LEGAL": "WRITE_LEGAL", "R_EPISTEMIC": "WRITE_EPISTEMIC"}
DATA_CLASSES = ("PUBLIC", "PRIVILEGED")
RESTRICTED = frozenset({"PRIVILEGED"})
MAX_CAPS = 3
MAX_DEPTH = 1

# state = (caps, writes, egresses)
#   caps     : frozenset[(cap_id, holder, authorities, depth, parent_id)]
#   writes   : frozenset[(cap_id, root_class, had_entry_proof, authority_held)]
#   egresses : frozenset[(cap_id, data_class, authority_held)]
INIT = (frozenset(), frozenset(), frozenset())

GRANTS = (frozenset({"WRITE_LEGAL"}), frozenset({"EGRESS"}),
          frozenset({"WRITE_LEGAL", "EGRESS"}))


def build(mutation: str | None = None) -> Model:

    def enforce_delegate(parent_auth, requested):
        if mutation == "delegate_superset":
            return frozenset(requested) & ISSUER_MAX      # parent's bound ignored
        return frozenset(requested) & frozenset(parent_auth)

    def enforce_write(auth, root_class, proof):
        has_authority = NEEDED[root_class] in auth
        if mutation == "write_without_proof":
            return has_authority
        if mutation == "write_without_authority":
            return proof
        return has_authority and proof

    def enforce_egress(auth, data_class):
        if mutation == "egress_restricted":
            return "EGRESS" in auth
        return "EGRESS" in auth and data_class not in RESTRICTED

    def actions(state):
        caps, writes, egresses = state
        out = []
        if len(caps) < MAX_CAPS:
            for h in HOLDERS:
                for g in GRANTS:
                    cid = f"c{len(caps)}"
                    if any(c[0] == cid for c in caps):
                        continue
                    out.append((f"issue({cid},{h},{sorted(g)})",
                                (caps | {(cid, h, frozenset(g), 0, None)}, writes, egresses)))
        for (cid, holder, auth, depth, _parent) in sorted(caps):
            if depth < MAX_DEPTH and len(caps) < MAX_CAPS:
                for h2 in HOLDERS:
                    for g in GRANTS:
                        granted = enforce_delegate(auth, g)
                        ncid = f"{cid}.{len(caps)}"
                        out.append((f"delegate({cid}->{ncid},{h2},{sorted(g)})",
                                    (caps | {(ncid, h2, granted, depth + 1, cid)},
                                     writes, egresses)))
            for rc in ROOT_CLASSES:
                for proof in (True, False):
                    if enforce_write(auth, rc, proof):
                        ev = (cid, rc, proof, NEEDED[rc] in auth)
                        if ev not in writes:
                            out.append((f"write({cid},{rc},proof={proof})",
                                        (caps, writes | {ev}, egresses)))
            for dc in DATA_CLASSES:
                if enforce_egress(auth, dc):
                    ev = (cid, dc, "EGRESS" in auth)
                    if ev not in egresses:
                        out.append((f"egress({cid},{dc})",
                                    (caps, writes, egresses | {ev})))
        return out

    def no_privilege_escalation(state):
        _, writes, egresses = state
        return (all(held for (_, _, _, held) in writes)
                and all(held for (_, _, held) in egresses))

    def delegation_never_increases_authority(state):
        caps, _, _ = state
        by_id = {c[0]: c for c in caps}
        for (cid, _h, auth, _d, parent) in caps:
            if parent is not None and parent in by_id:
                if not auth <= by_id[parent][2]:
                    return False
        return True

    def no_egress_for_restricted(state):
        _, _, egresses = state
        return all(dc not in RESTRICTED for (_, dc, _) in egresses)

    def root_write_only_with_entry_proof(state):
        _, writes, _ = state
        return all(proof for (_, _, proof, _) in writes)

    return Model(
        name="MODEL C — Authority / capability algebra",
        init=INIT,
        actions=actions,
        properties=[
            Property("NoPrivilegeEscalation", no_privilege_escalation),
            Property("DelegationNeverIncreasesAuthority", delegation_never_increases_authority),
            Property("NoEgressForRestrictedClasses", no_egress_for_restricted),
            Property("RootWriteOnlyWithValidEntryProof", root_write_only_with_entry_proof),
        ],
        bounds={"authorities": list(AUTHORITIES), "holders": list(HOLDERS),
                "max_capabilities": MAX_CAPS, "max_delegation_depth": MAX_DEPTH,
                "root_classes": list(ROOT_CLASSES), "data_classes": list(DATA_CLASSES)},
    )


MUTANTS = {
    "delegate_superset": "DelegationNeverIncreasesAuthority",
    "write_without_proof": "RootWriteOnlyWithValidEntryProof",
    "write_without_authority": "NoPrivilegeEscalation",
    "egress_restricted": "NoEgressForRestrictedClasses",
}
