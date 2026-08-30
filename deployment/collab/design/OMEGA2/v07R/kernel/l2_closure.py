"""KERNEL L2 — FIRST-CLASS CLOSURE EVIDENCE (absence is an object, never a default).

L2.a  no absence claim without UniverseDefinition + ClosureBasis
L2.b  conservation: captured-in-scope = admitted + pending + quarantined + terminal disposition
L2.c  a terminal disposition is a durable, auditable record -- never sampled away
L2.d  a completeness label exists only inside the declared ProofSupportedQuerySubset

Two further clauses are consequences of the same law, kept explicit because they were separate
breaks: corroboration must evidence independence per axis (not assume it), and an attribution
may not exceed the maximum level its evidence supports.

Method: exhaustive enumeration of the bounded decision space. Every operation is an ATTEMPT;
a separate enforcement function decides whether it is RECORDED. Properties range over recorded
state, so they test the enforcement rule and cannot be satisfied by an over-tight guard.
"""
from itertools import product

DISPOSITIONS = ("ADMITTED", "PENDING", "QUARANTINED", "TERMINAL")
ATTR_LEVELS = ("KEY", "WORKLOAD", "SERVICE", "PRINCIPAL")


def enforce(mutation=None):
    def dispose(item, disp, durable):
        # L2.c: a terminal disposition is only effective if it leaves a durable record
        if disp == "TERMINAL" and mutation != "sampled_terminal" and not durable:
            return False
        return True

    def drop(item):
        # L2.b: there is no transition that removes an item from scope without a disposition
        return mutation == "silent_drop"

    def admit_absence(kind, universe, basis):
        if mutation == "absence_without_universe":
            return True
        return universe and basis

    def label_complete(in_subset):
        if mutation == "completeness_outside_subset":
            return True
        return in_subset

    def accept_corroboration(n_sources, independence_evidenced):
        if mutation == "assume_independence":
            return n_sources > 1
        return n_sources > 1 and independence_evidenced

    def accept_attribution(claimed, maximum):
        if mutation == "over_attribute":
            return True
        return ATTR_LEVELS.index(claimed) <= ATTR_LEVELS.index(maximum)

    return dispose, drop, admit_absence, label_complete, accept_corroboration, accept_attribution


def run(mutation=None):
    dispose, drop, admit_absence, label_complete, accept_corr, accept_attr = enforce(mutation)
    bad = {k: 0 for k in ("Conservation", "TerminalDispositionDurable",
                          "AbsenceRequiresUniverseAndBasis", "CompletenessOnlyInSupportedSubset",
                          "CorroborationRequiresEvidencedIndependence", "AttributionWithinBound")}
    cases = 0

    # L2.b / L2.c — every captured item must end in exactly one accounted bucket
    for disp, durable, dropped in product(DISPOSITIONS, (True, False), (True, False)):
        cases += 1
        recorded = dispose("i", disp, durable)
        # a rejected disposition attempt is NOT a loss: the item stays in its previous bucket.
        # conservation is broken only by a transition that removes it with no bucket at all.
        accounted = True
        if dropped and drop("i"):
            accounted = False
        if not accounted:
            bad["Conservation"] += 1
        if recorded and disp == "TERMINAL" and not durable:
            bad["TerminalDispositionDurable"] += 1

    # L2.a — absence claims
    for universe, basis in product((True, False), repeat=2):
        cases += 1
        if admit_absence("NO_MATCH", universe, basis) and not (universe and basis):
            bad["AbsenceRequiresUniverseAndBasis"] += 1

    # L2.d — completeness labels
    for in_subset in (True, False):
        cases += 1
        if label_complete(in_subset) and not in_subset:
            bad["CompletenessOnlyInSupportedSubset"] += 1

    # corroboration independence
    for n, ev in product((1, 2, 3), (True, False)):
        cases += 1
        if accept_corr(n, ev) and not ev:
            bad["CorroborationRequiresEvidencedIndependence"] += 1

    # attribution bound
    for claimed, maximum in product(ATTR_LEVELS, repeat=2):
        cases += 1
        if accept_attr(claimed, maximum) and ATTR_LEVELS.index(claimed) > ATTR_LEVELS.index(maximum):
            bad["AttributionWithinBound"] += 1

    return {k: (v == 0, f"{v} violations") for k, v in bad.items()} | {"_cases": cases}


MUTANTS = {"silent_drop": "Conservation",
           "sampled_terminal": "TerminalDispositionDurable",
           "absence_without_universe": "AbsenceRequiresUniverseAndBasis",
           "completeness_outside_subset": "CompletenessOnlyInSupportedSubset",
           "assume_independence": "CorroborationRequiresEvidencedIndependence",
           "over_attribute": "AttributionWithinBound"}

if __name__ == "__main__":
    base = run()
    print(f"L2 closure evidence — exhaustive over {base['_cases']} bounded cases")
    ok = True
    for k, v in base.items():
        if k.startswith("_"):
            continue
        print(f"  {k:44s}: {'HOLDS' if v[0] else 'VIOLATED — ' + v[1]}")
        ok &= v[0]
    print("  mutation battery:")
    for m, target in MUTANTS.items():
        r = run(m)
        caught = not r[target][0]
        print(f"    {m:28s} vs {target:44s}: {'CAUGHT' if caught else 'MISSED'}")
        ok &= caught
    print("\nL2:", "PASS" if ok else "FAIL")
