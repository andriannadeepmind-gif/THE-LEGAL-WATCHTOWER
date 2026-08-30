"""Runs the WATCHTOWER FORMAL ARCHITECTURE EVIDENCE PACK and emits EVIDENCE-PACK.md."""

from __future__ import annotations

import datetime
import hashlib
import pathlib
import sys

from harness import explore, format_report, run_model

import model_a_commit
import model_b_replication
import model_c_authority
import model_d_matter
import model_e_keys
import model_d2_channels
import model_f_answers
import model_g_accountability
import model_h_continuity
import model_i_encoding

HERE = pathlib.Path(__file__).parent


def digest_of_models() -> str:
    h = hashlib.sha256()
    for f in sorted(HERE.glob("*.py")):
        h.update(f.read_bytes())
    return h.hexdigest()


def main() -> int:
    out: list[str] = []
    ok = True

    out.append("# WATCHTOWER FORMAL ARCHITECTURE EVIDENCE PACK — results\n")
    out.append(f"model-set digest (sha256 over all model sources): `{digest_of_models()}`\n")
    out.append(f"executed: {datetime.date.today().isoformat()} · "
               f"python {sys.version.split()[0]}\n")
    out.append("Bounded exhaustive state-space exploration. A result is evidence ONLY within "
               "its bounds stamp; no result below is a universal theorem.\n")

    for module in (model_a_commit, model_c_authority, model_d_matter, model_e_keys,
                   model_h_continuity):
        rep = run_model(module.build, module.MUTANTS)
        out.append(format_report(rep))
        if rep["verdict"] != "BOUNDED-EXHAUSTIVE PASS":
            ok = False

    # Model B is explored in three replication profiles.
    out.append("## Model B — replication profiles\n")
    rep = run_model(model_b_replication.build_cft, model_b_replication.MUTANTS)
    out.append(format_report(rep))
    if rep["verdict"] != "BOUNDED-EXHAUSTIVE PASS":
        ok = False

    byz = explore(model_b_replication.build_cft_byz())
    out.append(f"### {byz.model}\n")
    out.append("EXPECTED OUTCOME: a safety violation. This run is the executable evidence for "
               "invariant I-24 — a crash-fault-tolerant profile may not be claimed under a "
               "Byzantine threat model. A violation here is the intended demonstration.\n")
    out.append(f"bounds stamp: {byz.bounds}")
    out.append(f"search: {byz.status}, states={byz.states}, transitions={byz.edges}\n")
    for name, tr in byz.violations.items():
        out.append(f"  - {name}: VIOLATED — trace: {' -> '.join(tr)}")
    for name in byz.holds:
        out.append(f"  - {name}: holds")
    if "NoDualCommittedValue" not in byz.violations:
        out.append("\n**UNEXPECTED: no violation found — the CFT/BFT distinction is NOT "
                   "demonstrated by this run.**")
        ok = False
    out.append("")

    bft = explore(model_b_replication.build_bft())
    out.append(f"### {bft.model}\n")
    out.append("EXPECTED OUTCOME: safe. Quorum intersection 2q-n = 2 exceeds f = 1, so every "
               "committed value retains an honest witness across a view change.\n")
    out.append(f"bounds stamp: {bft.bounds}")
    out.append(f"search: {bft.status}, states={bft.states}, transitions={bft.edges}\n")
    for name in bft.holds:
        out.append(f"  - {name}: HOLDS (no reachable violation within bounds)")
    for name, tr in bft.violations.items():
        out.append(f"  - {name}: VIOLATED — trace: {' -> '.join(tr)}")
        ok = False
    out.append("")

    # D2 — per-channel noninterference over the full declared channel set
    out.append("## Model D2 — noninterference per declared channel\n")
    d2ok = True
    for ch in model_d2_channels.CHANNELS:
        b = explore(model_d2_channels.build_channel(ch, leak=False))
        m = explore(model_d2_channels.build_channel(ch, leak=True))
        caught = "NoModelledCrossMatterObservation" in m.violations
        good = b.status == "EXHAUSTED" and not b.violations and caught
        d2ok &= good
        out.append(f"  - {ch}: baseline {b.status} ({b.states} states) HOLDS={not b.violations}"
                   f" · seeded leak {'CAUGHT' if caught else 'MISSED'}")
    out.append("")
    if not d2ok:
        ok = False

    # F/G/I — counter-challenge evidence (I-41, I-42, I-44)
    out.append("## Counter-challenge evidence (I-41, I-42, I-44)\n")
    f = model_f_answers.run()
    fok = f["positive_conformance"][0] and all(v[0] for v in f["attacks"].values()) and f["wrong_root"][0]
    out.append(f"  - MODEL F (I-41 verifiable answers): {'PASS' if fok else 'FAIL'} — honest answer verifies;"
               f" rejected attacks: {', '.join(f['attacks'].keys())}, wrong_root")
    g, gok = model_g_accountability.run()
    out.append(f"  - MODEL G (I-42 typed accountability): {'PASS' if gok else 'FAIL'} — "
               f"{'; '.join(k + '=' + ('ok' if v[0] else 'FAIL') for k, v in g.items())}")
    ib = model_i_encoding.run()
    iok = all(bool(v[0]) for v in ib.values())
    for m, target in model_i_encoding.MUTANTS.items():
        iok &= not model_i_encoding.run(m)[target][0]
    out.append(f"  - MODEL I (I-44 canonical encoding): {'PASS' if iok else 'FAIL'} — "
               f"round-trip, canonical acceptance, injectivity, domain separation, differential;"
               f" {len(model_i_encoding.MUTANTS)}/{len(model_i_encoding.MUTANTS)} malleability mutants caught")
    out.append("")
    ok = ok and fok and gok and iok

    out.append("## OVERALL\n")
    out.append(f"**{'ALL MODELS: BOUNDED-EXHAUSTIVE PASS' if ok else 'FAILURE — see above'}**\n")
    out.append("Scope not covered by these models (declared, not silently generalized): "
               "runtime/hardware integrity, physical and timing side channels, cryptographic "
               "primitive strength, supply-chain and update mechanics, long-term validation, "
               "human identity assurance, and every property whose enforcement lives outside "
               "the modelled state machines. Those remain contract + assumption-ledger items "
               "and empirical falsifiers.\n")

    text = "\n".join(out)
    (HERE / "EVIDENCE-PACK.md").write_text(text, encoding="utf-8")
    print(text)
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
