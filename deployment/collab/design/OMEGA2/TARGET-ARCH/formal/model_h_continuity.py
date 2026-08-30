"""MODEL H — I-43 Matter State Continuity / Rollback Resistance (architecture evidence).

Bounded state machine over: advance the matter chain, persist the continuity anchor, roll the
STORAGE back (the adversary's power), restart and re-attest, serve. Two properties are checked
by exhaustive exploration:

  NoStaleHighAssuranceServe  a high-assurance serve never happens on a chain head that is less
                             fresh than continuity state held outside the rollback adversary's
                             control (hardware monotonic state, client receipts, or an
                             activity-hiding external anchor -- the mechanism is PROFILED, not
                             hardcoded, per Reviewer-B).
  PublicAnchorRevealsNothing what is published for third parties is a function of the epoch
                             alone -- never of matter identity or matter activity (composition
                             with I-35 / R-i).

Mutants: continuity check disabled; anchor published per matter advance (activity-revealing).
"""
from __future__ import annotations
from harness import Model, Property

MAX_HEAD, MAX_EPOCHS = 3, 2

# state = (head, anchor, epoch, published, served_stale, leaked)
#   head      : chain head currently in storage (the adversary may lower it)
#   anchor    : monotonic continuity value outside the adversary's control
#   published : tuple of public anchor items, each an epoch tag (no matter data) or a leak tag
INIT = (0, 0, 0, (), False, False)


def build(mutation: str | None = None) -> Model:
    def actions(state):
        head, anchor, epoch, published, stale, leaked = state
        out = []
        if head < MAX_HEAD:
            nh = head + 1
            na = max(anchor, nh)                      # continuity state advances monotonically
            npub, nleak = published, leaked
            if mutation == "publish_on_activity":     # activity-revealing anchor
                npub = published + (("matter-advance", nh),)
                nleak = True
            out.append((f"advance(head={nh})", (nh, na, epoch, npub, stale, nleak)))
        if head < anchor:
            out.append((f"rollback(head {head}->{max(head - 1, 0)})",
                        (max(head - 1, 0), anchor, epoch, published, stale, leaked)))
        elif head > 0:
            out.append((f"rollback(head {head}->{head - 1})",
                        (head - 1, anchor, epoch, published, stale, leaked)))
        if epoch < MAX_EPOCHS:
            # fixed-rate publication: one opaque item per epoch, independent of activity
            out.append((f"publish_epoch({epoch + 1})",
                        (head, anchor, epoch + 1, published + (("epoch", epoch + 1),),
                         stale, leaked)))
        fresh_ok = (head >= anchor)
        if mutation == "no_continuity_check" or fresh_ok:
            out.append((f"serve_high_assurance(head={head},anchor={anchor})",
                        (head, anchor, epoch, published, stale or not fresh_ok, leaked)))
        return out

    def no_stale_serve(state):
        return not state[4]

    def anchor_reveals_nothing(state):
        published = state[3]
        return all(kind == "epoch" for kind, _ in published) and not state[5]

    return Model(
        name="MODEL H — matter state continuity / rollback resistance",
        init=INIT,
        actions=actions,
        properties=[Property("NoStaleHighAssuranceServe", no_stale_serve),
                    Property("PublicAnchorRevealsNothing", anchor_reveals_nothing)],
        bounds={"max_head": MAX_HEAD, "max_epochs": MAX_EPOCHS,
                "adversary": "may lower the stored chain head arbitrarily (rollback), may restart",
                "continuity_mechanism": "PROFILED: hardware monotonic state | client receipts | "
                                        "privacy-preserving external anchor | rollback-resistant "
                                        "ledger | hybrid",
                "outside_model": "physical extraction of the continuity state itself"},
    )


MUTANTS = {"no_continuity_check": "NoStaleHighAssuranceServe",
           "publish_on_activity": "PublicAnchorRevealsNothing"}
