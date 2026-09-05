#!/usr/bin/env python3
"""Generate ROOT-OPERATOR-DECISION-PACKET.md from evidence and changed facts only.

Every number in this packet is RECOMPUTED from the canonical model at generation time, through the repository's
single reader seat — never counted by matching lines, never copied forward from a previous run. The packet also
carries a machine-readable PACKET-RECONCILIATION block, and the gate recomputes that block from the model and
from both verification paths' commitments (`gate_checks.py packet`). A packet whose totals do not reconcile
fails the gate; the gate does not check that the packet CONTAINS expected words.

The packet never requires the operator to read the whole repository: machines processed the full volume; the
operator adjudicates this bounded set of facts and signs.
"""
import hashlib, importlib.util, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location('sexp_reader', os.path.join(HERE, 'SEXP-READER.py'))
SR = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(SR)
HEADERS = SR.HEADERS          # one seat: the reader declares the header vocabulary


def sh(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=HERE)
    return r.returncode, (r.stdout + r.stderr).strip()


def last(text):
    lines = [l for l in text.splitlines() if l.strip()]
    return lines[-1] if lines else ''


def root():
    forms = SR.read_forms_file(os.path.join(HERE, 'ROOT.sexp'))
    r = [f for f in forms if SR.head(f) == 'define-model-root'][0]
    pl = dict(SR.plist(r[2:], 'ROOT.sexp', 'define-model-root'))
    mods = [str(dict(SR.plist(e, 'ROOT.sexp', 'entry'))['module']) for e in pl['composition']]
    return pl, mods


def facts(mods):
    out = []
    for mod in mods:
        for form in SR.read_forms_file(os.path.join(HERE, mod)):
            h = SR.head(form)
            if h in HEADERS:
                continue
            ftype = str(form[1]).lower()
            fid = SR.canonical_value(form[2], mod, 'fact id')
            pairs = SR.plist(form[3:], mod, '%s %s' % (ftype, fid))
            out.append((mod, ftype, fid, {k.lower(): SR.canonical_value(v, mod, k) for k, v in pairs}))
    return out


def digest_of(path):
    if not os.path.isfile(path):
        return None
    with open(path, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()


def main():
    kc, ko = sh(['sbcl', '--script', 'KERNEL/model-law-kernel.lisp', 'ROOT.sexp'])
    cc, co = sh(['python3', 'CHECKER/independent_check.py', 'ROOT.sexp'])
    fc, fo = sh(['python3', 'run_fixtures.py'])
    dvc, dvo = sh(['python3', 'build_deferred.py', '--verify'])
    pl, mods = root()
    fs = facts(mods)
    fam, permod = {}, {}
    for mod, t, _i, _p in fs:
        fam[t] = fam.get(t, 0) + 1
        permod[mod] = permod.get(mod, 0) + 1
    status, batch, forms, batch_forms = {}, {}, {}, {}
    for _m, t, _i, p in fs:
        if t == 'source-class':
            status[p['status']] = status.get(p['status'], 0) + 1
            forms[p['status']] = forms.get(p['status'], 0) + int(p['source-count'])
            if 'batch' in p:
                batch[p['batch']] = batch.get(p['batch'], 0) + 1
                batch_forms[p['batch']] = batch_forms.get(p['batch'], 0) + int(p['source-count'])
    promo = {p['scope']: p for _m, t, _i, p in fs if t == 'promotion'}
    inv = [p for _m, t, _i, p in fs if t == 'inventory-total']
    kdig, cdig = digest_of(os.path.join(HERE, 'KERNEL-COMMITMENT.txt')), digest_of(os.path.join(HERE, 'CHECKER-COMMITMENT.txt'))
    if kdig is None or cdig is None:
        sys.stderr.write('FATAL: a verification path produced no fact-set commitment; the packet cannot be '
                         'reconciled and is not written\n')
        sys.exit(2)
    if kdig != cdig:
        sys.stderr.write('FATAL: the kernel and the independent checker committed to different fact universes; '
                         'the packet is not written\n')
        sys.exit(2)
    kernel_verdict = 'PASS' if 'ARCHITECTURE MODEL LAWS: PASS' in ko else 'FAIL'
    checker_verdict = 'PASS' if 'INDEPENDENT ARCHITECTURE INVARIANTS: PASS' in co else 'FAIL'
    dig = str(pl['canonical-model-root-digest'])

    recon = ['total-facts %d' % len(fs), 'modules %d' % len(mods), 'model-root-digest %s' % dig]
    recon += ['family %s %d' % (t, fam[t]) for t in sorted(fam)]
    # Review-2 N-7: the packet must disclose the deferred VOLUME, not only the class count, and must state the
    # promotion state the model itself computes. The gate recomputes every one of these from the model.
    recon += ['deferred-classes %d' % status.get('DEFERRED_DATA_IMPORT', 0),
              'deferred-source-forms %d' % forms.get('DEFERRED_DATA_IMPORT', 0),
              'imported-classes %d' % status.get('IMPORTED', 0),
              'global-promotion %s' % (promo['GLOBAL']['state'] if 'GLOBAL' in promo else 'ABSENT')]
    recon += ['commitment kernel %s' % kdig, 'commitment checker %s' % cdig]

    m = """# ROOT-OPERATOR-DECISION-PACKET — canonical architecture model (initial import)

> SINGLE_OPERATOR_ASSURANCE: machines processed the complete repository volume; this packet is the bounded set of
> changed facts + evidence the Root Operator adjudicates and signs. No gate requires exhaustive human repository review.

<!-- PACKET-RECONCILIATION
%s
-->

## 1. Change summary
Initial import of the canonical ARCHITECTURE-MODEL: %d facts across %d hash-pinned modules, migrated from the
v1.6-v1.8 registries. Parent architecture commit `%s`. Canonical model-root digest `%s`, RECOMPUTED from the
ordered module pins by both verification paths rather than read from the file.

## 2. Affected model facts (per family)
| family | count |
|---|---|
%s
| **total** | **%d** |

Per pinned module:

| module | facts |
|---|---|
%s

## 2b. Migration-scope ledger — imported vs DEFERRED_DATA_IMPORT
Every v1.6-v1.8 source fact class is enumerated exactly once in `deferred-imports.sexp` (mapped to its source
file + a finite migration batch); none is silently omitted and none is left as an open architecture decision.
Ledger verification (multiset-aware re-derivation from the sources): **%s** — `%s`.

| status | source-classes | source forms |
|---|---|---|
%s

Deferred fact classes by finite batch, with the number of SOURCE FORMS each batch actually carries: %s
(batch scopes are declared in `build_deferred.py`; DEFERRED_DATA_IMPORT means enumerated + scheduled, NOT
dropped). This pass imported only the structural seat/topology classes. None of those batches has been started.

### 2b-i. Typed authority split — what this model is, and is not, authoritative for
| authority | applies to | meaning |
|---|---|---|
| `CANONICAL_IN_MODEL` | the %d IMPORTED classes (%d source forms) | the detail lives here; this model is the source of truth for them |
| `AUTHORITATIVE_AT_SOURCE` | the %d DEFERRED classes (%d source forms) and the %d out-of-scope classes | the detail still lives in the declared legacy registry and is authoritative THERE until that class's DDI batch is complete AND independently reviewed |

The split is not prose: `authority` is a required, enum-constrained field of every `source-class` fact, both
verification paths enforce it, and the gate recomputes the totals above from the model. The model additionally
carries a `promotion` fact whose GLOBAL scope is **%s** — a machine-checkable statement that global
single-source-of-truth status is withheld while any class remains authoritative at its source.

## 2c. Tracked-file inventory
%s

## 3. Invariants affected
All model laws: L1 well-formedness (declared fact type, required keys, permitted value kinds, closed enum
domains), L2 one seat (duplicate seat, duplicate key, id owned by one type), L3 closed typed references against
each field's declared target universe, L4 acyclicity of every declared from/to relation, L5 public/private
isolation with every consumer of undecidable kind failing closed, L6 complete requirement->seat->test->WP
mapping, L7 exact module/hash universe with the model-root digest recomputed from the ordered pins.

## 4. Pass/fail evidence
- SBCL model-law kernel: **%s** (exit %d). SHA-256 from a vetted external provider over raw bytes.
- Independent clingo checker (derives every model law from its own reading of the model): **%s** (exit %d).
- Golden fixtures + generated property families, each run through BOTH paths: **%s** — `%s`.

## 5. Independent-checker agreement
The two paths **%s**. Agreement is not asserted from two verdict strings: each path publishes a fact-set
commitment (total, per-module and per-family counts and digests) and the checker refuses to issue a verdict
unless its commitment is byte-identical to the kernel's. Commitment digest: `%s`.

## 6. Independent AI review receipts and independence evidence
None attached in this pass. AI reviewers have no canonical-write authority; agreement reduces workload but is not
proof; disagreement auto-escalates; no model/tool/reviewer self-certifies independence. This model has been
through one external independent review, which FAILED it and required correction; a fresh independent review of
the corrected model, generator, kernel and second-checker independence is awaited.

## 7. Unresolved / CONFLICTING items
Migration conflicts: see MODEL-MIGRATION-CONFLICT-LEDGER.md — every row of that ledger is reconciled against
this model by the gate in both directions. None escalated to creator approval.

## 8. Worst credible consequence
A wrong classification of a file role or a mis-migrated fact could let a real architecture drift pass
structurally. Mitigation: exact hash-pinned modules, a recomputed model root, an independent second path bound
to an identical fact-set commitment, and golden/property/held-out fixtures. This is NOT semantic, legal,
security, operational or qualification proof.

## 9. Migration and rollback
Migration: build_model.py + build_deferred.py + build_inventory.py, in the order declared by
`generation-order.sexp`. Rollback: revert this commit; the v1.6-v1.8 registries and the legacy v1.8 harness
(frozen at %s) are preserved unchanged as migration input and HISTORICAL_EVIDENCE, and the harness is no longer
a dependency of anything on the live path.

## 10. Decision
The options below are bounded by the authority split in §2b-i. There is deliberately NO option to promote this
model as the global architecture source of truth, because %d source classes covering %d source forms are still
authoritative at their declared legacy sources; the model's own `promotion` fact records that state as **%s**,
and it is the gate, not this prose, that enforces it.

- **APPROVE (bounded)** — accept this canonical model root as the source of truth **for the imported classes
  only**, leaving every deferred class authoritative at its declared legacy source. This authorizes a fresh
  independent review; it does NOT authorize DDI-1, and it does not make this model globally canonical.
- **REJECT** — discard; keep the registries as source.
- **DEFER** — request the fresh independent review before deciding anything.

Global single-source-of-truth status becomes available only after DDI-1…DDI-4 are complete and each has been
independently reviewed. Final canonical promotion requires the Root Operator's signed approval. This packet
asserts NO freeze, NO qualification, and NO independent verification: an internal PASS authorizes a fresh
independent review and nothing else.
""" % ('\n'.join(recon), len(fs), len(mods), str(pl['parent-architecture-commit']), dig,
       '\n'.join('| %s | %d |' % (t, fam[t]) for t in sorted(fam)), len(fs),
       '\n'.join('| %s | %d |' % (m, permod[m]) for m in sorted(permod)),
       'PASS' if dvc == 0 else 'FAIL', last(dvo),
       '\n'.join('| %s | %d | %d |' % (k, status[k], forms[k]) for k in sorted(status)),
       ', '.join('%s=%d classes / %d forms' % (k, batch[k], batch_forms[k]) for k in sorted(batch)),
       status.get('IMPORTED', 0), forms.get('IMPORTED', 0),
       status.get('DEFERRED_DATA_IMPORT', 0), forms.get('DEFERRED_DATA_IMPORT', 0),
       status.get('OUT_OF_MIGRATION_SCOPE', 0),
       promo['GLOBAL']['state'] if 'GLOBAL' in promo else 'ABSENT',
       ('%s tracked paths are classified exactly once: %s carry an individual `file` fact and %s are counted by '
        '%s `dir-rule` facts.' % (inv[0]['tracked'], inv[0]['file-facts'], inv[0]['dir-rule-sum'],
                                  inv[0]['dir-rule-facts'])) if inv else 'No inventory-total fact is present.',
       kernel_verdict, kc, checker_verdict, cc, 'PASS' if fc == 0 else 'FAIL', last(fo),
       'AGREE' if kernel_verdict == checker_verdict else 'DISAGREE', kdig,
       str(pl['parent-architecture-commit']),
       status.get('DEFERRED_DATA_IMPORT', 0), forms.get('DEFERRED_DATA_IMPORT', 0),
       promo['GLOBAL']['state'] if 'GLOBAL' in promo else 'ABSENT')
    with open(os.path.join(HERE, 'ROOT-OPERATOR-DECISION-PACKET.md'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(m)
    print('decision packet written (kernel=%s checker=%s commitments identical fixtures=%s facts=%d)'
          % (kernel_verdict, checker_verdict, fc == 0, len(fs)))


if __name__ == '__main__':
    main()
