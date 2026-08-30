"""HOLDOUT EVALUATION (§11) — fixtures the kernel was NOT designed against.

Discipline: the seed is fixed and its digest is printed BEFORE any result, so the fixture set
is committed in advance. The fixtures are deliberately drawn from structurally different
classes than the enumerated design space -- longer chains, wider time ranges, non-monotone raw
bounds, repeated erasures, several artifacts, larger source counts -- so that passing the
design-time batteries cannot be mistaken for passing here.
"""
import hashlib, random, sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).parent / "kernel"))
sys.path.insert(0, str(pathlib.Path(__file__).parent / "adversarial"))

SEED_PHRASE = "watchtower-v0.7R-holdout-sealed-2026-08-29"
SEED = int(hashlib.sha256(SEED_PHRASE.encode()).hexdigest()[:16], 16)

import l1_frontier as L1
import l2_closure as L2
import l3_artifact as L3
import l0_footprint as L0
import combined as CB


def holdout_l1(rng, n=4000):
    """Long chains, wide time range, deliberately non-monotone raw bounds."""
    bad_sound = bad_guess = bad_unknown = 0
    for _ in range(n):
        m = rng.randint(6, 10)
        adm = tuple(sorted((rng.randint(0, 12), rng.randint(0, 12)))[:2] for _ in range(m))
        adm = tuple((lo, hi if hi > lo else lo + 1) for lo, hi in adm)
        t = rng.randint(0, 13)
        k = L1.select_frontier(adm, t)
        pa = L1.propagate(adm)
        if k is not None and not L1.sound(adm, t, k):
            bad_sound += 1
        if pa is not None and any(lo <= t < hi for lo, hi in pa) and k is not None:
            bad_guess += 1
        if pa is not None and not any(lo <= t < hi for lo, hi in pa) and k is None:
            bad_unknown += 1
    return {"SelectionSound": bad_sound, "NoGuessOnAmbiguity": bad_guess,
            "NoUnnecessaryUnknown": bad_unknown, "_n": n}


def holdout_l3(rng, n=4000):
    """Several artifacts, repeated erasures and dependency changes, wider frontier range."""
    issue, status, _, _ = L3.kernel(None)
    bad = 0
    for _ in range(n):
        issued = rng.randint(0, 9)
        dep = rng.choice([None] + list(range(0, 10)))
        er = rng.choice([None] + list(range(0, 10)))
        f = rng.randint(0, 9)
        if status(issued, dep, er, f) != L3.truth_status(issued, dep, er, f):
            bad += 1
    return {"StatusIsFrontierIndexed": bad, "_n": n}


def holdout_combined(rng, n=6000):
    """Wider parameter ranges than the enumerated composite space, defect-free."""
    bad = 0
    for _ in range(n):
        cfg = (rng.choice([None, 0, 1, 2, 3]), rng.randint(0, 3), rng.choice([True, False]),
               rng.choice([None, 0, 1, 2, 3]), rng.randint(0, 3), rng.randint(0, 3),
               rng.choice([True, False]), rng.choice([True, False]), rng.choice([True, False]),
               rng.randint(1, 5), rng.choice([True, False]), rng.choice([True, False]))
        if CB.evaluate(cfg, frozenset()):
            bad += 1
    return {"CompositeSafety": bad, "_n": n}


def holdout_combined_defects(rng, n=400):
    """The same wider space, but with random defect sets: each must still be detected."""
    missed = []
    for _ in range(n):
        k = rng.randint(1, 3)
        muts = frozenset(rng.sample(CB.MUTANTS, k))
        hit = set()
        for _ in range(400):
            cfg = (rng.choice([None, 0, 1, 2, 3]), rng.randint(0, 3), rng.choice([True, False]),
                   rng.choice([None, 0, 1, 2, 3]), rng.randint(0, 3), rng.randint(0, 3),
                   rng.choice([True, False]), rng.choice([True, False]),
                   rng.choice([True, False]), rng.randint(1, 5),
                   rng.choice([True, False]), rng.choice([True, False]))
            hit |= CB.evaluate(cfg, muts)
        if not hit:
            missed.append(tuple(sorted(muts)))
    return {"AllRandomDefectSetsDetected": len(missed), "_n": n, "_missed": missed}


if __name__ == "__main__":
    print(f"holdout seed phrase digest: "
          f"{hashlib.sha256(SEED_PHRASE.encode()).hexdigest()}")
    print(f"seed: {SEED}\n")
    rng = random.Random(SEED)
    ok = True
    for name, fn in (("L1.d frontier selection", holdout_l1),
                     ("L3 artifact status", holdout_l3),
                     ("composite safety (defect-free)", holdout_combined),
                     ("composite defect detection", holdout_combined_defects)):
        r = fn(rng)
        n = r.pop("_n")
        missed = r.pop("_missed", None)
        print(f"{name} — {n} holdout fixtures")
        for k, v in r.items():
            print(f"    {k:34s}: {'PASS' if v == 0 else f'FAIL ({v} violations)'}")
            ok &= (v == 0)
        if missed:
            for mm in missed[:5]:
                print(f"       undetected defect set: {' + '.join(mm)}")
    print("\nHOLDOUT:", "PASS" if ok else "FAIL")
