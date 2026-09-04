#!/usr/bin/env python3
"""Generate ROOT-OPERATOR-DECISION-PACKET.md from EVIDENCE + changed facts only (gate 16). It runs the kernel and
the independent checker, records their agreement, summarizes ONLY the changed facts (for the initial import: the
whole model root, with per-family counts) and the affected invariants, and presents APPROVE/REJECT/DEFER. It never
requires the operator to read the whole repository (gate 17): machines processed the full volume; the operator
adjudicates this bounded packet and signs."""
import os, re, subprocess, hashlib
HERE=os.path.dirname(os.path.abspath(__file__))
def sh(cmd):
    r=subprocess.run(cmd,capture_output=True,text=True,cwd=HERE); return r.returncode, (r.stdout+r.stderr).strip()
def rootinfo():
    t=open(os.path.join(HERE,'ROOT.sexp')).read()
    return (re.search(r':canonical-model-root-digest "([0-9a-f]{64})"',t).group(1),
            re.search(r':parent-architecture-commit "([0-9a-f]{40})"',t).group(1),
            len(re.findall(r':module "',t)))
def counts():
    # count EVERY fact family across EVERY module ROOT pins (single source; never drifts from the kernel's total)
    c={}
    mods=re.findall(r':module "([^"]+)"',open(os.path.join(HERE,'ROOT.sexp')).read())
    for mod in mods:
        for l in open(os.path.join(HERE,mod)):
            if l.startswith('(fact '): c[l.split()[1]]=c.get(l.split()[1],0)+1
    return c
def deferred_summary():
    # by status + by finite batch, straight from the ledger the anti-omission gate verifies
    txt=open(os.path.join(HERE,'deferred-imports.sexp')).read()
    st={}; bt={}
    for mm in re.finditer(r':status (\S+)(?:.*?:batch (\S+))?',txt):
        s=mm.group(1); st[s]=st.get(s,0)+1
        if mm.group(2): bt[mm.group(2)]=bt.get(mm.group(2),0)+1
    vc,vo=sh(['python3','build_deferred.py','--verify'])
    return st,bt,('PASS' if vc==0 else 'FAIL'),vo.splitlines()[-1] if vo else ''
def main():
    kc,ko=sh(['sbcl','--script','KERNEL/model-law-kernel.lisp','ROOT.sexp'])
    cc,co=sh(['python3','CHECKER/independent_check.py','ROOT.sexp'])
    fc,fo=sh(['python3','run_fixtures.py'])
    dig,parent,nmod=rootinfo(); c=counts()
    dst,dbt,dver,dline=deferred_summary()
    kernel_verdict='PASS' if 'ARCHITECTURE MODEL LAWS: PASS' in ko else 'FAIL'
    checker_verdict='PASS' if 'INDEPENDENT ARCHITECTURE INVARIANTS: PASS' in co else 'FAIL'
    agree = (kernel_verdict==checker_verdict)
    fixtures_ok = (fc==0)
    m=f"""# ROOT-OPERATOR-DECISION-PACKET — canonical architecture model (initial import)

> SINGLE_OPERATOR_ASSURANCE: machines processed the complete repository volume; this packet is the bounded set of
> changed facts + evidence the Root Operator adjudicates and signs. No gate requires exhaustive human repository review.

## 1. Change summary
Initial import of the canonical ARCHITECTURE-MODEL: {sum(c.values())} facts across {nmod} hash-pinned modules,
migrated from the v1.6–v1.8 registries. Parent architecture commit `{parent}`. Canonical model-root digest
`{dig}`.

## 2. Affected model facts (per family)
| family | count |
|---|---|
""" + '\n'.join('| %s | %d |'%(k,c[k]) for k in sorted(c)) + f"""

## 2b. Migration-scope ledger — imported vs DEFERRED_DATA_IMPORT
Every v1.6–v1.8 source fact class is enumerated exactly once in `deferred-imports.sexp` (mapped to its source
file + a finite migration batch); none is silently omitted and none is left as an open architecture decision.
Anti-omission verification (independent re-scan): **{dver}** — `{dline}`.

| status | source-classes |
|---|---|
""" + '\n'.join('| %s | %d |'%(k,dst[k]) for k in sorted(dst)) + """

Deferred fact classes by finite batch: """ + ', '.join('%s=%d'%(k,dbt[k]) for k in sorted(dbt)) + f""" (batch scopes are declared
in `build_deferred.py`; DEFERRED_DATA_IMPORT means enumerated + scheduled, NOT dropped). This pass imported only
the structural seat/topology classes; the deferred data (records, enums, seats, cognition, invariants, prose) is a
finite, batched follow-up — no freeze claim follows from this pass.

## 3. Invariants affected
All seven model laws (L1 well-formedness+ID-uniqueness, L2 one-seat, L3 closed typed refs, L4 acyclic permitted
pipeline, L5 public/private isolation, L6 complete requirement→seat→test→WP, L7 exact module/hash universe).

## 4. Pass/fail evidence
- SBCL model-law kernel: **{kernel_verdict}** (exit {kc}).
- Independent clingo checker (L3/L4/L5 objective invariants): **{checker_verdict}** (exit {cc}).
- Golden fixtures + generated properties: **{'PASS' if fixtures_ok else 'FAIL'}** — `{fo.splitlines()[-1] if fo else ''}`.

## 5. Independent-checker agreement
Kernel and independent checker **{'AGREE' if agree else 'DISAGREE'}** on the shared objective invariants. A deliberate
disagreement blocks the verdict (gate 15).

## 6. Independent AI review receipts and independence evidence
None attached in this pass. AI reviewers have no canonical-write authority; agreement reduces workload but is not
proof; disagreement auto-escalates; no model/tool/reviewer self-certifies independence. Awaiting one bounded
independent review of the model, generator, kernel and second-checker independence.

## 7. Unresolved / CONFLICTING items
Migration conflicts: see MODEL-MIGRATION-CONFLICT-LEDGER.md (data-flow cycles recorded as a non-invariant; composite
WP tokens split; non-subsystem consumers declared as components). None escalated to creator approval.

## 8. Worst credible consequence
A wrong classification of a file role or a mis-migrated fact could let a real architecture drift pass structurally.
Mitigation: exact hash-pinned modules + independent second checker + golden/property fixtures; this is NOT semantic,
legal or security proof.

## 9. Migration and rollback
Migration: build_model.py + build_inventory.py (one-time, from the registries). Rollback: revert this commit; the
v1.6–v1.8 registries and the legacy v1.8 harness (frozen at {parent}) are preserved unchanged as migration input and
HISTORICAL_EVIDENCE.

## 10. Decision
- **APPROVE** — promote this canonical model root as the architecture source of truth.
- **REJECT** — discard; keep registries as source.
- **DEFER** — request the bounded independent review first.

Final canonical promotion requires the Root Operator's signed approval. This packet asserts NO freeze, NO
qualification, and makes NO claim of perfection/completeness/soundness/freeze-readiness/independent verification.
"""
    open(os.path.join(HERE,'ROOT-OPERATOR-DECISION-PACKET.md'),'w').write(m)
    print("decision packet written (kernel=%s checker=%s agree=%s fixtures=%s)"%(kernel_verdict,checker_verdict,agree,fixtures_ok))
if __name__=='__main__': main()
