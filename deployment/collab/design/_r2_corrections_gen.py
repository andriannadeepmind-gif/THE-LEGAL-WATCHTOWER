import json

d = json.load(open('_ssp_freeze_v2.json'))  # not needed further
bands = json.load(open('_stageC_verdicts.json'))

cells = []
for b in bands:
    for v in b['verdicts']:
        cells.append({'ax': v['ax'], 'cl': v['class_id'], 'v': v['verdict'], 'r': v['adjudicated_rank']})
assert len(cells) == 198, len(cells)

C = 'CONDITIONAL_ON_NAMED_BUILD'
def cond(art, rung): return f"{C}({art}): {rung}"

DEMO4  = "executed structural-enforcement (bypass-impossible) demonstration of the attested origin/admission chain"
REPLAY8 = "past-time replay witness (re-runnable evaluation at a past time point)"
REPLAY13 = "replay demonstration including >=1 decision from every trusted decision class"
REPLAY14 = "divergence-free repeated-replay demonstration under perturbed environments"
CRASH15 = "injected-crash test campaign across all transition classes"
TRACE19 = "independent trace-vs-explanation comparison"

ch = {}  # (ax,cl) -> (verdict, rank, note)

# --- AX-01 (a2, a3, a4, d1) ---
ch[('AX-01','K-CAT')] = ('EXCEED_REFUTED',
  cond("recorded replay of the F* soundness artifact into this tournament's evidence set", "R4; else UNKNOWN with KNOWN_UPPER_BOUND cap"),
  "a2: 'DGFiP-class deployments' STRUCK from the rank basis (VERIFIED_FROM_SECONDARY never grounds a rank); d1: judge-supplied 'superior NL norms' leg STRUCK — refutation stands on vacuous-satisfaction + VFS legs alone.")
ch[('AX-01','K-CBR')] = ('EXCEED_REFUTED',
  "R4 (axis-wide); case-law-cell R5 = " + cond("independent forcing-certificate checker (unbuilt)", "cell property recorded in prose, NOT an axis rank"),
  "a3: 'R5 (cell-relative)' is outside the frozen verdict_schema domain and contradicts the same judge's K-RULES ruling on this axis (domain coverage IS the measured delta); a4: the 'trivially-entailed' checker is an unbuilt artifact. Scoreboard consequence: K-CBR does NOT hold AX-01 at ceiling.")

# --- AX-02 (a4 + regime) ---
ch[('AX-02','K-NSV')] = (C,
  cond("admission machinery on shipped Lean 4 (named unbuilt engineering in the round-1 verdict itself)", "R5; R4 design floor"),
  "a4/regime: AX-02 rider assigns ranks only from independently re-verifiable plan artifacts AND checkers; the kernel exists, the admission machinery does not. Never plain AT_CEILING while the load-bearing artifact is unwritten.")

# --- AX-03 (a2) ---
ch[('AX-03','K-BFT')] = (C,
  cond("recorded replay of >=1 named exclusion-proof artifact (Velisarios / ACL2 / TLA+-Apalache) into this tournament's evidence set", "R5; R3 design floor"),
  "a2: third-party literature artifacts are relayed material until replayed here; the rank may not precede the replay (dischargeable, but not yet discharged). Downstream: E-star-star absorption 3A#3 donor is CONDITIONAL.")

# --- AX-04 (regime: rider is R3+ demonstration) ---
for cl in ['K-SUP','K-CAT','K-CBR','K-BFT']:
    ch[('AX-04',cl)] = (C, cond(DEMO4, "R5 (design-entailed)"),
      "Regime: AX-04 rider demands DEMONSTRATED structural enforcement at R3+; unbuilt composition = CONDITIONAL, not AT (a1).")
ch[('AX-04','K-TLOG')] = ('EXCEED_REFUTED', cond(DEMO4, "R5 (design-entailed)"),
  "Regime retype of the rank; the exceed REFUTATION stands unchanged (clause-(b) no-maximum corroboration argument untouched).")
ch[('AX-04','K-B0-TARGET')] = (C,
  cond("primary-anchor undefined-hash-fns P0 fix + witness enrollment + attested ingestion path (the design's own enumerated completion items)", "R5"),
  "e: '(as designed)' rank retyped per witness_appendix_convention; executing precursors (census-verified) noted as floor evidence, not attainment.")
for cl in ['K-ARG','K-NSV','K-RULES']:
    ch[('AX-04',cl)] = ('BELOW_CEILING', cond(DEMO4, "R4 (design-entailed)"),
      "Uniform regime extension: the AX-04 rider binds at R3+, so the R4 grants carry the same executed-evidence condition (verdict class unchanged: BELOW_CEILING either way).")

# --- AX-06 (e: K-B0 only) ---
ch[('AX-06','K-B0-TARGET')] = (C,
  cond("per-step-hash comparison in the consolidation ledger (today aggregate-only, strictly below ceiling per the two-history lemma) + wired census-totality blocking gate", "R5"),
  "e: '(as designed)' with a named executing-below-ceiling component; retyped from AT_CEILING.")

# --- AX-08 (a1: rider demands past-time replay at R3+) ---
for cl in ['K-SUP','K-ARG','K-CAT','K-CBR','K-NSV']:
    ch[('AX-08',cl)] = (C, cond(REPLAY8, "R5 certified-bitemporal"),
      "a1: the AX-08 rider demands re-runnable past-time evidence for R3+; the K-SUP verdict itself conceded the DE credit 'converts to a tournament rank only after a replay witness exists'. Never plain AT_CEILING.")
ch[('AX-08','K-BFT')] = ('EXCEED_REFUTED', cond(REPLAY8 + " on the transposed legal substrate", "R5 (profile design credit)"),
  "a1 regime retype of the credited rank; the exceed REFUTATION stands unchanged (clause-(a) named realization argument untouched).")
ch[('AX-08','K-B0-TARGET')] = (C,
  cond("single total View(t_legal,t_knowledge) seat (census-confirmed absent) + replay coverage extended to every trusted decision class", "R5; holds the field's ONLY executing partial past-time replay witness"),
  "e + b5: rider satisfied IN PART only ('in part' restored); the identical missing View seat sent K-TLOG to UNKNOWN — uniform treatment required.")

# --- AX-09 (e: K-B0 only) ---
ch[('AX-09','K-B0-TARGET')] = (C,
  cond("stability engine (absent in B0 per the class's own appendix) + P0 register: retire use-default restarts, sum-typed UNKNOWN causes, blocking anomalies", "R5 certified-frontier"),
  "e: the identical absent stability component sent K-CAT to UNKNOWN on this axis; today's B0 floor is below R3 per census. Equalized.")

# --- AX-10 (b5: area restriction made explicit) ---
ch[('AX-10','K-B0-TARGET')] = ('EXCEED_REFUTED',
  "R3 on covered areas ONLY (capture/Merkle mutation-kill, executing, census-verified); axis-level rank UNKNOWN",
  "b5: the area-restricted rank no longer flattened into an axis rank; still the only KNOWN AX-10 evidence in the field.")

# --- AX-12 (d2: prose trim only) ---
ch[('AX-12','K-BFT')] = ('EXCEED_REFUTED',
  "UNKNOWN (claimed R5 self-typed WOULD_NEED_BUILD; structural floor R4 noted)",
  "d2 prose trim: the surplus feasibility assertion ('attainable at the same resource kind in single-writer designs') is STRUCK; the no-frozen-sentence-falsified leg carries the refutation alone. Verdict and rank unchanged.")

# --- AX-13 (a1: rider demands replay demo over every decision class) ---
for cl in ['K-SUP','K-ARG','K-CAT','K-CBR','K-NSV','K-BFT']:
    ch[('AX-13',cl)] = (C, cond(REPLAY13, "R5"),
      "a1: no replay demonstration of ANY decision class exists; rider demands executed evidence — CONDITIONAL, not AT.")
ch[('AX-13','K-B0-TARGET')] = (C,
  cond(REPLAY13 + " + closure-totality fix (wall-clock removed from release identity, per census)", "R5"),
  "a1 + e: closure totality fails today by the verdict's own census citation.")
ch[('AX-13','K-TLOG')] = ('EXCEED_REFUTED', cond(REPLAY13, "R5"),
  "a1 regime retype of the sustained rank; the exceed REFUTATION stands unchanged.")
ch[('AX-13','K-RULES')] = ('BELOW_CEILING', cond(REPLAY13, "R4"),
  "a1: the critic enumerated K-RULES R4 among the replay-less grants; verdict class unchanged (BELOW_CEILING either way).")

# --- AX-14 (a1 + task-enumerated CakeML cell) ---
ch[('AX-14','K-SUP')] = ('EXCEED_REFUTED',
  cond("CakeML-class verified kernel refinement proofs (unwritten per K-SUP's own AX-21 entry) + " + REPLAY14, "R5"),
  "Task-enumerated: AT-rank rode a substrate the same record types WOULD_NEED_BUILD; a1: rider demands perturbed-replay demonstration. Refutation of the exceed claim stands.")
for cl in ['K-CAT','K-NSV']:
    ch[('AX-14',cl)] = (C, cond(REPLAY14, "R5"),
      "a1: R4/R5 by demonstration, not policy assertion — CONDITIONAL, not AT.")
for cl in ['K-ARG','K-CBR','K-RULES','K-TLOG','K-BFT','K-B0-TARGET']:
    ch[('AX-14',cl)] = ('BELOW_CEILING', cond(REPLAY14, "R4"),
      "a1: 'every R4' enumerated — same rider, same condition; verdict class unchanged.")

# --- AX-15 (a1: all R4 grants) ---
for cl in ['K-SUP','K-ARG','K-CAT','K-CBR','K-NSV','K-RULES','K-TLOG','K-B0-TARGET']:
    ch[('AX-15',cl)] = ('BELOW_CEILING', cond(CRASH15, "R4"),
      "a1: zero injected-crash evidence; untested crash classes score UNKNOWN for the axis — rank conditional on the campaign.")
ch[('AX-15','K-BFT')] = ('EXCEED_REFUTED', cond(CRASH15, "R4"),
  "a1 regime retype of the rank; the exceed REFUTATION stands unchanged (replication-outside-declared-model clause is verbatim frozen).")

# --- AX-16 (task-enumerated + b3) ---
ch[('AX-16','K-SUP')] = (C,
  cond("CakeML-class verified kernel — refinement proofs for THIS kernel unwritten (K-SUP's own AX-21 entry)", "R5"),
  "Task-enumerated: AT_CEILING internally inconsistent with the same record's WNB typing of the load-bearing substrate.")
ch[('AX-16','K-NSV')] = (C,
  cond("the committed Lean kernel source (unwritten/uncommitted) whose re-checking IS the claimed offline proof", "R5"),
  "Task-enumerated: the offline re-checkable proof object does not exist until the kernel source does.")
ch[('AX-16','K-ARG')] = ('BELOW_CEILING',
  cond("the class's own conceded WOULD_NEED_BUILD artifact", "R4"),
  "b3: 'Claimed R4 WOULD_NEED_BUILD adjudicated AT the claim' — an assessor-conceded unbuilt claim may never be granted at the claim; uniform WNB treatment.")

# --- AX-17 (correction 4 + b3) ---
ax17_dual = "old (frozen) clause: {old}; raised clause: PENDING_CREATOR_APPROVAL — no rank recorded (adjudication under it occurs only if the creator adopts the amendment)"
ch[('AX-17','K-CAT')] = ('ESCALATION_FILED_PENDING_CREATOR_APPROVAL',
  ax17_dual.format(old="R5 (AT under old bar; the exceed argument survives as a FILED falsification claim)"),
  "Correction 4 / c3: a band judge's EXCEED_VALID is a filed claim, not an amended instrument — S2 refinement belongs to the freeze authority and only the creator approves phase acts; supreme-law note: the escalation RAISES the bar, so it is preserved pending, never silently dropped. Before adoption it must be reconciled with the frozen ladder's own AX-17 R5 'certified-worst-case-envelope' wording. The rank-grade prediction 'K-CAT, K-CBR, K-RULES plausibly attain the raised rung' is STRUCK.")
ch[('AX-17','K-RULES')] = (C,
  cond("the class's own WOULD_NEED_BUILD implementation (proof-carrying cost-certificate machinery)", ax17_dual.format(old="R5")),
  "b3: K-RULES's ONLY at-ceiling cell was a WNB claim 'adjudicated AT the claim' — retyped; plus dual old/raised reporting per correction 4.")
ch[('AX-17','K-SUP')] = ('EXCEED_REFUTED',
  ax17_dual.format(old="R5 (design-stage rank permitted by the AX-17 class-level rider)"),
  "Correction 4: dual reporting added; the VDF exceed refutation stands under the old clause.")
for cl in ['K-CBR','K-NSV']:
    ch[('AX-17',cl)] = ('AT_CEILING',
      ax17_dual.format(old="R5 (design-stage rank permitted by the AX-17 class-level rider)"),
      "Correction 4: AT_CEILING holds relative to the OLD clause only; raised clause pending creator adoption.")
ch[('AX-17','K-ARG')] = ('BELOW_CEILING',
  cond("the class's own conceded WOULD_NEED_BUILD artifact", ax17_dual.format(old="R4")),
  "b3 + correction 4: WNB adjudicated at the claim retyped; dual reporting added.")
ch[('AX-17','K-TLOG')] = ('BELOW_CEILING',
  cond("the class's own conceded WOULD_NEED_BUILD artifact", ax17_dual.format(old="R4")),
  "b3 + correction 4.")
ch[('AX-17','K-B0-TARGET')] = ('BELOW_CEILING',
  cond("the class's own conceded WOULD_NEED_BUILD artifact", ax17_dual.format(old="R3")),
  "b3 + correction 4.")

# --- AX-19 (a1 rider + task-enumerated K-BFT) ---
for cl in ['K-SUP','K-CAT','K-CBR','K-B0-TARGET']:
    ch[('AX-19',cl)] = (C, cond(TRACE19, "R5 certified-explanation"),
      "a1: faithfulness at R3+ must be DEMONSTRATED, not carried by structural-identity argument alone (adopting that argument as a convention is an S2 act for the freeze authority, not a verdict-time judgment).")
ch[('AX-19','K-BFT')] = (C,
  cond("legal-domain state-machine substrate transposition (unbuilt per the class's own inventory and its AX-01/AX-09/AX-12 UNKNOWNs) + " + TRACE19, "R5 certified-explanation"),
  "Task-enumerated: f+1-signature serving of a state machine that exists nowhere; uniform with the other substrate-unwritten retypes.")
ch[('AX-19','K-ARG')] = ('EXCEED_REFUTED', cond(TRACE19, "R5"),
  "a1 regime retype of the rank; d3: the silent pluralization of frozen limit (a) ('trace' -> 'trace(s)') is corrected — the refutation now rests on the R4 what-would-change clause and the more-decisions argument, which suffice. Refutation stands.")
ch[('AX-19','K-NSV')] = ('EXCEED_REFUTED', cond(TRACE19, "R5"),
  "a1 regime retype of the rank; the exceed REFUTATION stands unchanged.")
ch[('AX-19','K-RULES')] = ('BELOW_CEILING', cond(TRACE19, "R4"),
  "a1: the rider binds at R3+; verdict class unchanged.")

# --- apply ---
out = []
n_changed = 0
for c in cells:
    key = (c['ax'], c['cl'])
    if key in ch:
        v, r, note = ch[key]
        out.append({'ax': c['ax'], 'cl': c['cl'], 'verdict': v, 'rank': r, 'changed': True,
                    'was': {'verdict': c['v'], 'rank': c['r']}, 'note': note})
        n_changed += 1
    else:
        out.append({'ax': c['ax'], 'cl': c['cl'], 'verdict': c['v'], 'rank': c['r'], 'changed': False})
print("cells:", len(out), "changed:", n_changed)

json.dump({'regime': 'CONDITIONAL_ON_NAMED_BUILD(X): Rn maps to the frozen verdict_schema as UNKNOWN{design floor as stated; discharged only by artifact X entering the evidence set}. DESIGN_ENTAILMENT supports at most the rung the axis\'s frozen evidence rider permits; where the rider demands executed evidence (AX-03 R4+, AX-04 R3+, AX-08 R3+, AX-10 all, AX-13 replay, AX-14 R4+, AX-15 R4+, AX-19 R3+), unbuilt/unreplayed = CONDITIONAL, never AT. Scoreboard is per-axis descriptive only; no count-of-wins inference is valid.',
           'cells': out}, open('_stageC_verdicts_r2corrected.json','w'), indent=1)

# markdown table
lines = []
cur = None
for c in out:
    if c['ax'] != cur:
        cur = c['ax']
    delta = c.get('note','') if c['changed'] else ''
    was = f" (was: {c['was']['verdict']} / {c['was']['rank']})" if c['changed'] else ''
    lines.append(f"| {c['ax']} | {c['cl']} | {c['verdict']} | {c['rank']} | {(delta + was) if c['changed'] else '—'} |")
open('_r2_table.md','w').write("| ax | class | corrected_verdict | corrected_rank | note-if-changed |\n|---|---|---|---|---|\n" + "\n".join(lines))
print("table rows:", len(lines))

# per-axis unconditional AT holders
from collections import defaultdict
at = defaultdict(list); condl = defaultdict(list)
for c in out:
    if c['verdict'] == 'AT_CEILING' and not c['rank'].startswith(C):
        at[c['ax']].append(c['cl'])
    if C in c['rank'] or c['verdict'] == C:
        condl[c['ax']].append(c['cl'])
for i in range(1,23):
    ax = f"AX-{i:02d}"
    print(ax, "| unconditional AT:", ",".join(at.get(ax,[])) or "NONE", "| conditional:", len(condl.get(ax,[])))
