"""C4 — HIGHER-ORDER COMPOSITION BATTERY over a combined kernel model.

The six triples named in the mandate are modelled together so that mutants can MASK one
another. Every single, pair and triple of seeded defects must still be caught by at least one
composite safety property. A combination that survives is a genuine new finding: it means two
defects cancel each other's symptom while the underlying danger remains.
"""
from itertools import product, combinations

MUTANTS = ("local_view_authority", "ignore_attestation", "plaintext_in_cert",
           "ltv_renews_erased", "backlog_invisible", "guess_on_straddle",
           "status_frozen", "golden_only", "assume_independence", "admit_single_source")

PROPS = ("NoWriteWithoutLiveAuthority", "NoErasedPlaintextProvable",
         "NoCompleteAnswerWithBacklog", "NoFrontierGuess",
         "NoStaleCertificateAsCurrent", "NoCurrentLawFromUncorroborated",
         "NoUpdateWithoutImpactClosure")


def evaluate(cfg, muts):
    """Returns the set of properties violated in this configuration under these defects."""
    (revoke, lag, attest, erase, cert, backlog, probes, straddle,
     closure, nsrc, indep, sem_update) = cfg
    bad = set()

    # --- revocation x partition x runtime attestation
    live_truth = (revoke is None) or (cert < revoke)
    live_seen = (revoke is None) or (max(cert - lag, 0) < revoke)
    live = live_seen if "local_view_authority" in muts else live_truth
    attested = True if "ignore_attestation" in muts else attest
    write_recorded = live and attested
    if write_recorded and not (live_truth and attest):
        bad.add("NoWriteWithoutLiveAuthority")

    # --- erasure x answer certificate x long-term validation
    cert_holds_plaintext = "plaintext_in_cert" in muts
    erased = erase is not None and cert >= erase
    revalidated = "ltv_renews_erased" in muts
    if (cert_holds_plaintext or revalidated) and erased:
        bad.add("NoErasedPlaintextProvable")

    # --- freshness x quarantine x answer completeness
    complete_label = probes and (backlog == 0 or "backlog_invisible" in muts)
    if complete_label and backlog > 0:
        bad.add("NoCompleteAnswerWithBacklog")

    # --- civil time x time uncertainty x frontier selection
    frontier_returned = (not straddle) or ("guess_on_straddle" in muts)
    if frontier_returned and straddle:
        bad.add("NoFrontierGuess")

    # --- semantic artifact update x old certificate x reconstruction assurance
    update_effective = closure or ("golden_only" in muts)
    old_cert_status = ("CURRENTLY_APPLICABLE" if "status_frozen" in muts
                       else ("SUPERSEDED" if update_effective else "CURRENTLY_APPLICABLE"))
    if sem_update and update_effective and old_cert_status == "CURRENTLY_APPLICABLE":
        bad.add("NoStaleCertificateAsCurrent")
    # the composite property set was INCOMPLETE without this: a defect that makes a semantic
    # update effective without impact closure was invisible to every other composite property.
    if sem_update and update_effective and not closure:
        bad.add("NoUpdateWithoutImpactClosure")

    # --- source corroboration x quarantine x current-law answer
    corroborated = (nsrc > 1 and indep) or ("assume_independence" in muts and nsrc > 1) \
        or ("admit_single_source" in muts)
    current_law_served = corroborated and probes and backlog == 0
    if current_law_served and not (nsrc > 1 and indep):
        bad.add("NoCurrentLawFromUncorroborated")
    return bad


def configs():
    return product([None, 0, 1], [0, 1], [True, False], [None, 0, 1], [0, 1], [0, 1],
                   [True, False], [True, False], [True, False], [1, 2],
                   [True, False], [True, False])


ALL_CFGS = list(configs())


def battery(muts):
    hit = set()
    for cfg in ALL_CFGS:
        hit |= evaluate(cfg, muts)
        if len(hit) == len(PROPS):
            break
    return hit


if __name__ == "__main__":
    clean = battery(frozenset())
    print(f"config space: {len(ALL_CFGS)} configurations · properties: {len(PROPS)}")
    print(f"baseline (no defects): violations = {sorted(clean) if clean else 'NONE'}")
    survivors = []
    counts = {1: 0, 2: 0, 3: 0}
    for k in (1, 2, 3):
        for combo in combinations(MUTANTS, k):
            counts[k] += 1
            if not battery(frozenset(combo)):
                survivors.append(combo)
    total = sum(counts.values())
    print(f"combinations tested: singles={counts[1]} pairs={counts[2]} triples={counts[3]} "
          f"total={total}")
    if survivors:
        print(f"\nSURVIVORS ({len(survivors)}) — defect combinations no property detects:")
        for s in survivors:
            print("   ", " + ".join(s))
    else:
        print("\nno survivors: every single, pair and triple of seeded defects is detected")
    print("\nC4:", "PASS" if not clean and not survivors else "FINDINGS PRESENT")
