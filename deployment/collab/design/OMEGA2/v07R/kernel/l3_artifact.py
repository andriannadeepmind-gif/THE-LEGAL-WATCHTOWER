"""KERNEL L3 — ARTIFACT IMMUTABLE, APPLICABILITY COMPUTED AT A FRONTIER.

L3.a  an issued artifact is immutable forever; its CURRENT applicability is a function
      ArtifactStatus(artifact, frontier) -- never a stored flag, never implicitly inherited
L3.b  a durable proof binds a COMMITMENT to private content, never the plaintext
L3.c  a semantic-influence artifact change is effective only with impact closure over the
      affected scope; a golden corpus is a canary, not a completeness proof
"""
from itertools import product

STATUSES = ("CURRENTLY_APPLICABLE", "VALID_AT_ISSUANCE", "SUPERSEDED", "STALE",
            "CONTENT_ERASED", "DEPENDENCY_INVALIDATED")


def kernel(mutation=None):
    def issue(private_content_present):
        # L3.b: what goes into a durable artifact is a commitment, not the opening
        if mutation == "plaintext_in_durable":
            return {"commitment": True, "plaintext": private_content_present}
        return {"commitment": True, "plaintext": False}

    def status(issued_at, dep_changed_at, erased_at, frontier):
        # L3.a: computed from the artifact's envelope and the queried frontier
        if mutation == "status_frozen_at_issuance":
            return "CURRENTLY_APPLICABLE"
        if erased_at is not None and frontier >= erased_at:
            return "CONTENT_ERASED"
        if dep_changed_at is not None and frontier >= dep_changed_at:
            return "DEPENDENCY_INVALIDATED"
        if frontier >= issued_at:
            return "CURRENTLY_APPLICABLE"
        return "VALID_AT_ISSUANCE"

    def accept_semantic_update(has_impact_closure, golden_corpus_pass):
        if mutation == "golden_corpus_only":
            return golden_corpus_pass
        return has_impact_closure

    def mutate(artifact):
        return mutation == "mutate_artifact"

    return issue, status, accept_semantic_update, mutate


def truth_status(issued, dep, er, f):
    """Independent second implementation of L3.a, written as a timeline scan rather than a
    precedence cascade, so that agreement between the two is a differential check rather than
    a restatement of the kernel."""
    timeline = []
    for g in range(f + 1):
        if er is not None and g == er:
            timeline.append("CONTENT_ERASED")
        elif dep is not None and g == dep:
            timeline.append("DEPENDENCY_INVALIDATED")
    if "CONTENT_ERASED" in timeline:
        return "CONTENT_ERASED"
    if "DEPENDENCY_INVALIDATED" in timeline:
        return "DEPENDENCY_INVALIDATED"
    return "CURRENTLY_APPLICABLE" if f >= issued else "VALID_AT_ISSUANCE"


def run(mutation=None):
    issue, status, accept_update, mutate = kernel(mutation)
    bad = {k: 0 for k in ("ArtifactImmutable", "StatusIsFrontierIndexed",
                          "DurableBindsCommitmentNotPlaintext", "ErasureRemovesRecoverableContent",
                          "SemanticChangeRequiresImpactClosure")}
    cases = 0
    F = range(4)

    for private in (True, False):
        cases += 1
        a = issue(private)
        if a["plaintext"]:
            bad["DurableBindsCommitmentNotPlaintext"] += 1
        if mutate(a):
            bad["ArtifactImmutable"] += 1

    for issued, dep, er in product(F, list(F) + [None], list(F) + [None]):
        for f in F:
            cases += 1
            st = status(issued, dep, er, f)
            # L3.b consequence: once erased, no frontier may still report the content usable
            if er is not None and f >= er and st != "CONTENT_ERASED":
                bad["ErasureRemovesRecoverableContent"] += 1
        # L3.a: the status must actually change across each lifecycle event that falls inside
        # the queried range. (Asserting a change over the whole range was wrong: an artifact
        # erased at the start is legitimately CONTENT_ERASED at every frontier in range.)
        # L3.a as a DIFFERENTIAL property: the computed status must agree, at every frontier,
        # with an independently written reference. A status stored at issuance, or any status
        # that ignores its frontier argument, diverges from the reference.
        for f in F:
            cases += 1
            if status(issued, dep, er, f) != truth_status(issued, dep, er, f):
                bad["StatusIsFrontierIndexed"] += 1

    for closure, golden in product((True, False), repeat=2):
        cases += 1
        if accept_update(closure, golden) and not closure:
            bad["SemanticChangeRequiresImpactClosure"] += 1

    return {k: (v == 0, f"{v} violations") for k, v in bad.items()} | {"_cases": cases}


MUTANTS = {"mutate_artifact": "ArtifactImmutable",
           "status_frozen_at_issuance": "StatusIsFrontierIndexed",
           "plaintext_in_durable": "DurableBindsCommitmentNotPlaintext",
           "golden_corpus_only": "SemanticChangeRequiresImpactClosure"}

if __name__ == "__main__":
    base = run()
    print(f"L3 artifact lifecycle — exhaustive over {base['_cases']} bounded cases")
    ok = True
    for k, v in base.items():
        if k.startswith("_"):
            continue
        print(f"  {k:38s}: {'HOLDS' if v[0] else 'VIOLATED — ' + v[1]}")
        ok &= v[0]
    print("  mutation battery:")
    for m, target in MUTANTS.items():
        r = run(m)
        caught = not r[target][0]
        print(f"    {m:26s} vs {target:38s}: {'CAUGHT' if caught else 'MISSED'}")
        ok &= caught
    print("\nL3:", "PASS" if ok else "FAIL")
