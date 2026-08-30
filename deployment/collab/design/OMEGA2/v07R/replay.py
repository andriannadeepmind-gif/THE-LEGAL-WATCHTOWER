"""C1 KNOWN-BREAK REPLAY + C2 DELETE-THE-PATCHES.

Every one of the 14 known breaks is replayed against the reduced kernel. For each, the closure
is EXECUTED, not asserted: the run reports which kernel law makes the break unreachable, and
the mutation that proves the law is not vacuous.

C2 is checked mechanically: the kernel sources are scanned for any break-specific guard. If the
safety came from 14 special cases rather than from the laws, those guards would be there.
"""
import re, subprocess, sys, pathlib
HERE = pathlib.Path(__file__).parent
sys.path.insert(0, str(HERE / "kernel")); sys.path.insert(0, str(HERE / "adversarial"))

import l1_frontier as L1, l2_closure as L2, l3_artifact as L3, l0_footprint as L0
import combined as CB

def prop_holds(mod, prop, mutation=None):
    r = mod.run(mutation) if mutation is None else mod.run(mutation)
    return r[prop][0]

def tla(design, inv):
    cfg = HERE / "kernel" / "_replay.cfg"
    cfg.write_text(f'CONSTANTS\n  MaxPos = 4\n  MaxCommits = 2\n  Design = "{design}"\n'
                   f'SPECIFICATION Spec\nCHECK_DEADLOCK FALSE\nINVARIANT {inv}\n')
    out = subprocess.run(["java", "-XX:+UseParallelGC", "-cp", "tla2tools.jar", "tlc2.TLC",
                          "-config", "_replay.cfg", "-workers", "4", "-cleanup", "KernelL1.tla"],
                         cwd=HERE / "kernel", capture_output=True, text=True, timeout=1800).stdout
    cfg.unlink(missing_ok=True)
    return "Model checking completed" in out

BREAKS = [
 ("A-1", "semantic artifact change without differential gate", "R3", "L3.c",
  lambda: prop_holds(L3, "SemanticChangeRequiresImpactClosure") and
          not prop_holds(L3, "SemanticChangeRequiresImpactClosure", "golden_corpus_only")),
 ("A-2", "revocation time-of-check/time-of-use", "R1", "L1.a + L1.e",
  lambda: tla("kernel_L1", "AuthorisationIsGenuine") and
          not tla("local_view", "AuthorisationIsGenuine")),
 ("A-3", "no minimum source corroboration", "R2", "L2 corroboration axis",
  lambda: prop_holds(L2, "CorroborationRequiresEvidencedIndependence") and
          not prop_holds(L2, "CorroborationRequiresEvidencedIndependence", "assume_independence")),
 ("A-4", "answer certificate outlives erasure", "R3", "L3.a + L3.b",
  lambda: prop_holds(L3, "DurableBindsCommitmentNotPlaintext") and
          prop_holds(L3, "ErasureRemovesRecoverableContent") and
          not prop_holds(L3, "DurableBindsCommitmentNotPlaintext", "plaintext_in_durable")),
 ("A-5", "quarantine suppression invisible to freshness", "R2", "L2.b + L2.c",
  lambda: prop_holds(L2, "TerminalDispositionDurable") and prop_holds(L2, "Conservation") and
          not prop_holds(L2, "Conservation", "silent_drop")),
 ("A-6", "civil-time to cut mapping unprotected", "R1", "L1.d",
  lambda: L1.run()["SelectionSound"][0] and not L1.run("nearest_checkpoint")["SelectionSound"][0]),
 ("B-1", "revocation x partition: stale control view", "R1", "L1.a",
  lambda: tla("kernel_L1", "AuthorisationIsGenuine") and
          not tla("local_view", "AuthorisationIsGenuine")),
 ("B-2", "civil time falls between checkpoints", "R1", "L1.d",
  lambda: L1.run()["NoGuessOnAmbiguity"][0] and
          not L1.run("guess_on_ambiguity")["NoGuessOnAmbiguity"][0]),
 ("B-3", "negative disposition suppresses completeness risk", "R2", "L2.c",
  lambda: prop_holds(L2, "TerminalDispositionDurable") and
          not prop_holds(L2, "TerminalDispositionDurable", "sampled_terminal")),
 ("B-4", "query proof vs query semantics mismatch", "R2", "L2.d",
  lambda: prop_holds(L2, "CompletenessOnlyInSupportedSubset") and
          not prop_holds(L2, "CompletenessOnlyInSupportedSubset", "completeness_outside_subset")),
 ("B-5", "golden corpus blind spot", "R3", "L3.c",
  lambda: prop_holds(L3, "SemanticChangeRequiresImpactClosure") and
          not prop_holds(L3, "SemanticChangeRequiresImpactClosure", "golden_corpus_only")),
 ("B-6", "false corroboration independence", "R2", "L2 corroboration axis",
  lambda: prop_holds(L2, "CorroborationRequiresEvidencedIndependence") and
          not prop_holds(L2, "CorroborationRequiresEvidencedIndependence", "assume_independence")),
 ("B-7", "key attribution laundered into human attribution", "R2", "L2 attribution bound",
  lambda: prop_holds(L2, "AttributionWithinBound") and
          not prop_holds(L2, "AttributionWithinBound", "over_attribute")),
 ("B-8", "self-declared composition footprint is a trust root", "method", "OperationEffect (+1)",
  lambda: L0.run()["DeclaredMatchesDerived"][0] and L0.run()["UnknownIsTop"][0] and
          not L0.run("trust_declared")["DeclaredMatchesDerived"][0] and
          not L0.run("unknown_is_bottom")["UnknownIsTop"][0]),
]

if __name__ == "__main__":
    print("C1 — KNOWN-BREAK REPLAY AGAINST THE REDUCED KERNEL\n")
    print(f"{'id':5} {'root':6} {'kernel clause':22} {'result':8} description")
    allok = True
    for bid, desc, root, clause, check in BREAKS:
        try:
            ok = bool(check())
        except Exception as e:
            ok = False; desc += f"  [error: {e}]"
        allok &= ok
        print(f"{bid:5} {root:6} {clause:22} {'CLOSED' if ok else 'OPEN':8} {desc}")

    print("\nC2 — DELETE-THE-PATCHES (mechanical): scanning kernel sources for break-specific guards")
    import c2_scan
    hits = [f"{n}:{i}: {t}" for n, i, t in c2_scan.scan(HERE / "kernel")]
    if hits:
        print("  break-specific guards FOUND in executable code:")
        for h in hits:
            print("   ", h)
        allok = False
    else:
        print("  0 break-specific guards in executable code — safety comes from the general laws")
    print("\nREPLAY:", "PASS" if allok else "FAIL")
