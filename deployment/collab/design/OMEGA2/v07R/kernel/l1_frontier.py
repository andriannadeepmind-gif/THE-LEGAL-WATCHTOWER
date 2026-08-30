"""KERNEL L1.d — civil time selects a frontier only through a selection proof, else UNKNOWN.

Exhaustive over every admission-interval configuration and every query time within bounds.
Each admission carries TRUSTED TIME BOUNDS [lo, hi] (I-34): the true admission time is known
only to lie inside them. A civil-time query t must select the unique maximal causally-closed
frontier k with: every admission at or before k certainly happened at or before t, and every
admission after k certainly happened after t. If any admission straddles t, no unique frontier
exists and the kernel must answer UNKNOWN{TEMPORAL_AMBIGUITY} -- never guess.
"""
from itertools import product

MAXT = 4


def propagate(adm):
    """L1.d clause discovered by the model itself: trusted time bounds attached to a
    linearization order must be tightened to their strongest form consistent with that order,
    because the order already asserts that earlier positions happened no later than later ones.
    Raw per-item bounds are NOT sound on their own: an item late in the order may carry a loose
    early bound and destroy frontier soundness. Returns None if the bounds contradict the order."""
    los, cur = [], 0
    for lo, hi in adm:
        cur = max(cur, lo); los.append(cur)
    his, cur = [], MAXT + 1
    for lo, hi in reversed(adm):
        cur = min(cur, hi); his.insert(0, cur)
    out = list(zip(los, his))
    return None if any(lo > hi for lo, hi in out) else out


def select_frontier(adm, t, mutation=None):
    """adm: tuple of (lo, hi) in admission order. Returns k, or None for UNKNOWN."""
    if mutation == "always_unknown":
        return None                                    # degenerate kernel: refuses to answer
    if mutation != "raw_bounds":
        adm = propagate(adm)
        if adm is None:
            return None                                # inconsistent time evidence -> UNKNOWN
    if mutation == "wall_clock":                      # ignore uncertainty, use hi as the truth
        k = 0
        for i, (lo, hi) in enumerate(adm, start=1):
            if hi <= t:
                k = i
        return k
    straddles = any(lo <= t < hi for (lo, hi) in adm)
    if straddles and mutation != "guess_on_ambiguity":
        return None                                    # UNKNOWN{TEMPORAL_AMBIGUITY}
    k = 0
    for i, (lo, hi) in enumerate(adm, start=1):
        if hi <= t:
            k = i
        else:
            break
    if mutation == "nearest_checkpoint" and k > 0:      # snap to a coarser checkpoint grid
        k = (k // 2) * 2
    return k


def sound(adm, t, k):
    a = propagate(adm)
    if a is None:
        return True                                    # inconsistent chains must return UNKNOWN
    return (all(hi <= t for (lo, hi) in a[:k]) and all(lo > t for (lo, hi) in a[k:]))


def run(mutation=None, n_adm=3):
    intervals = [(lo, hi) for lo in range(MAXT) for hi in range(lo + 1, MAXT + 1)]
    bad_sound = bad_guess = bad_mono = bad_unknown = 0
    total = 0
    for adm in product(intervals, repeat=n_adm):
        prev = None
        for t in range(MAXT + 2):
            total += 1
            k = select_frontier(adm, t, mutation)
            if k is not None and not sound(adm, t, k):
                bad_sound += 1
            pa = propagate(adm)
            if pa is not None and any(lo <= t < hi for (lo, hi) in pa) and k is not None:
                bad_guess += 1
            if k is not None and prev is not None and k < prev:
                bad_mono += 1
            # SPECIFICATION-GAMING GUARD (§10): every other property here is satisfied by a
            # kernel that always answers UNKNOWN. Refusal must therefore itself be constrained:
            # when a unique sound frontier exists, the kernel must return it.
            pa2 = propagate(adm)
            answerable = pa2 is not None and not any(lo <= t < hi for (lo, hi) in pa2)
            if answerable and k is None:
                bad_unknown += 1
            if k is not None:
                prev = k
    return {"SelectionSound": (bad_sound == 0, f"{bad_sound} unsound selections"),
            "NoGuessOnAmbiguity": (bad_guess == 0, f"{bad_guess} guesses under ambiguity"),
            "FrontierMonotoneInTime": (bad_mono == 0, f"{bad_mono} non-monotone"),
            "NoUnnecessaryUnknown": (bad_unknown == 0, f"{bad_unknown} refusals where a unique "
                                     f"sound frontier existed"),
            "_cases": total}


MUTANTS = {"guess_on_ambiguity": "NoGuessOnAmbiguity",
           "nearest_checkpoint": "SelectionSound",
           "wall_clock": "NoGuessOnAmbiguity",
           "raw_bounds": "NoUnnecessaryUnknown",
           "always_unknown": "NoUnnecessaryUnknown"}

if __name__ == "__main__":
    base = run()
    print(f"L1.d civil-time frontier selection — exhaustive over {base['_cases']} (config, t) cases")
    ok = True
    for k, v in base.items():
        if k.startswith("_"):
            continue
        print(f"  {k:26s}: {'HOLDS' if v[0] else 'VIOLATED — ' + v[1]}")
        ok &= v[0]
    print("  mutation battery:")
    for m, target in MUTANTS.items():
        r = run(m)
        caught = not r[target][0]
        print(f"    {m:20s} vs {target:22s}: {'CAUGHT' if caught else 'MISSED'}"
              f"{' — ' + r[target][1] if caught else ''}")
        ok &= caught
    print("\nL1.d:", "PASS" if ok else "FAIL")
