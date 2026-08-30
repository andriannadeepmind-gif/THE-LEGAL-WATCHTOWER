"""KERNEL — OperationEffect and the composition-obligation rule (closes B-8).

HONEST ACCOUNTING: `OperationEffect` is NOT in the sealed pre-declaration of 8 primitives.
Closing B-8 required adding it. This is counted as kernel growth (+1 primitive) in the
convergence report, not hidden.

B-8 broke the earlier proposal because a MANUALLY DECLARED footprint is itself a trust root:
an author who forgets to declare `capability_revocation` in `authority_domains` causes the
composition analysis to see no overlap and generate no test, while the interaction is real.

Kernel rule: the effect of an operation is DERIVED from independent sources and cross-checked
against the declaration. Mismatch REJECTS. Unknown access is TOP (overlaps everything), never
bottom.
"""
from itertools import product, combinations

DOMAINS = ("legal", "epistemic", "control", "artifact")
SOURCES = ("formal_transition_relation", "schema_graph", "static_extraction",
           "capability_graph", "runtime_traces")
TOP = frozenset(DOMAINS)


def admit_operation(declared, derived_per_source, has_unknown, mutation=None):
    """Returns (admitted, effective_footprint)."""
    if mutation == "trust_declared":
        return True, frozenset(declared)                 # no cross-check at all
    derived = frozenset().union(*derived_per_source) if derived_per_source else frozenset()
    if has_unknown:
        derived = frozenset() if mutation == "unknown_is_bottom" else TOP
    if frozenset(declared) != derived:
        return False, frozenset()                        # declared vs derived mismatch: REJECT
    return True, derived


def composition_obligations(footprints, mutation=None):
    """Every pair of operations whose effective footprints overlap generates an obligation."""
    if mutation == "skip_overlap_test":
        return set()
    return {(i, j) for (i, a), (j, b) in combinations(list(enumerate(footprints)), 2)
            if a & b}


def run(mutation=None):
    bad = {"DeclaredMatchesDerived": 0, "UnknownIsTop": 0, "OverlapGeneratesObligation": 0}
    cases = 0
    subsets = [frozenset(s) for r in range(len(DOMAINS) + 1)
               for s in combinations(DOMAINS, r)]
    for declared in subsets:
        for real in subsets:
            for unknown in (False, True):
                cases += 1
                admitted, eff = admit_operation(declared, [real], unknown, mutation)
                truth = TOP if unknown else real
                if admitted and frozenset(declared) != truth:
                    bad["DeclaredMatchesDerived"] += 1
                if admitted and unknown and eff != TOP:
                    bad["UnknownIsTop"] += 1
    # obligation generation over overlapping footprints
    for a, b in product(subsets[:8], repeat=2):
        cases += 1
        obs = composition_obligations([a, b], mutation)
        if (a & b) and not obs:
            bad["OverlapGeneratesObligation"] += 1
    return {k: (v == 0, f"{v} violations") for k, v in bad.items()} | {"_cases": cases}


MUTANTS = {"trust_declared": "DeclaredMatchesDerived",
           "unknown_is_bottom": "UnknownIsTop",
           "skip_overlap_test": "OverlapGeneratesObligation"}

if __name__ == "__main__":
    base = run()
    print(f"OperationEffect / composition obligations — exhaustive over {base['_cases']} cases")
    ok = True
    for k, v in base.items():
        if k.startswith("_"):
            continue
        print(f"  {k:32s}: {'HOLDS' if v[0] else 'VIOLATED — ' + v[1]}")
        ok &= v[0]
    print("  mutation battery:")
    for m, target in MUTANTS.items():
        r = run(m)
        caught = not r[target][0]
        print(f"    {m:20s} vs {target:32s}: {'CAUGHT' if caught else 'MISSED'}")
        ok &= caught
    print("\nFOOTPRINT:", "PASS" if ok else "FAIL")
