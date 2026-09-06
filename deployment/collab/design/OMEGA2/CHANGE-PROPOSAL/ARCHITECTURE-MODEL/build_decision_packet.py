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
import re, hashlib, importlib.util, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location('sexp_reader', os.path.join(HERE, 'SEXP-READER.py'))
SR = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(SR)


def sh(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=HERE)
    return r.returncode, (r.stdout + r.stderr).strip()


def last(text):
    """The final reported line of a sub-run, with absolute paths removed.

    Review-3: the packet is a hash-bound generated artifact, so its bytes must not depend on WHERE it was
    generated. An error message quoting an absolute path made the same model produce different packets in a
    checkout, in a workspace and in a clone — a fixed point that is not a fixed point."""
    lines = [l for l in text.splitlines() if l.strip()]
    line = lines[-1] if lines else ''
    return re.sub(r'(/[A-Za-z0-9_.+\-]+)+/([A-Za-z0-9_.+\-]+)', r'<path>/\2', line)


def digest_of(path):
    if not os.path.isfile(path):
        return None
    with open(path, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()


def blocks():
    """The AUTHORED adjudication blocks, read verbatim from their own authored document.

    Review-3 §15 M3. The packet's authored rationale, normative reasoning, risk acceptance and decision text
    are NOT part of the mechanical template and are not generated: they are adjudicated prose that this program
    copies without rewriting. Only the model-derived values inside them are substituted, and the gate recomputes
    every one of those from the model."""
    out, name = {}, None
    with open(os.path.join(HERE, 'PACKET-ADJUDICATION.md'), encoding='utf-8') as fh:
        for line in fh.read().split('\n'):
            m = re.match(r'<!-- BLOCK: ([a-z-]+) -->$', line.strip())
            if m:
                name = m.group(1)
                out[name] = []
            elif name is not None:
                out[name].append(line)
    return {k: '\n'.join(v).strip() for k, v in out.items()}


def render(template, values, authored):
    """Insert the authored blocks, then fill every model-derived placeholder.

    An unknown placeholder and an unused value are both fatal: a packet that silently drops a recomputed total,
    or that carries a placeholder the model no longer supports, is exactly the stale packet this design exists
    to make impossible."""
    seen = set()

    def pick(table, tag):
        def one(m):
            if m.group(1) not in table:
                sys.stderr.write('UNKNOWN-PACKET-%s: %s\n' % (tag, m.group(1)))
                sys.exit(2)
            seen.add(m.group(1))
            return table[m.group(1)]
        return one

    text = re.sub(r'\{\{block:([a-z-]+)\}\}', pick(authored, 'BLOCK'), template)
    text = re.sub(r'\{\{([a-z0-9-]+)\}\}', pick(values, 'VALUE'), text)
    unused = sorted((set(values) | set(authored)) - seen)
    if unused:
        sys.stderr.write('UNUSED-PACKET-VALUE: %s\n' % ' '.join(unused))
        sys.exit(2)
    return text


def main():
    # Review-3 R3-3: every sub-run below is started through the PINNED absolute path from the model, never
    # through a name PATH would resolve.
    py, sbcl = SR.tool_path(HERE, 'CHECKER_RUNTIME'), SR.tool_path(HERE, 'KERNEL_RUNTIME')
    kc, ko = sh([sbcl, '--script', 'KERNEL/model-law-kernel.lisp', 'ROOT.sexp'])
    cc, co = sh([py, 'CHECKER/independent_check.py', 'ROOT.sexp'])
    fc, fo = sh([py, 'run_corpus.py', '--kind', 'fixtures'])
    dvc, dvo = sh([py, 'build_deferred.py', '--verify'])
    model = SR.read_model(HERE)
    pl, mods, fs = model.root, model.modules, model.facts
    fam, permod = {}, {}
    for t, _i, _p, mod, _form in fs:
        fam[t] = fam.get(t, 0) + 1
        permod[mod] = permod.get(mod, 0) + 1
    status, batch, forms, batch_forms = {}, {}, {}, {}
    for t, _i, p, _m, _f in fs:
        if t == 'source-class':
            status[p['status']] = status.get(p['status'], 0) + 1
            forms[p['status']] = forms.get(p['status'], 0) + int(p['source-count'])
            if 'batch' in p:
                batch[p['batch']] = batch.get(p['batch'], 0) + 1
                batch_forms[p['batch']] = batch_forms.get(p['batch'], 0) + int(p['source-count'])
    promo = {p['scope']: p for t, _i, p, _m, _f in fs if t == 'promotion'}
    inv = [p for t, _i, p, _m, _f in fs if t == 'inventory-total']
    tcb = [p for t, _i, p, _m, _f in fs if t == 'tcb-total']
    budget = [p for t, _i, p, _m, _f in fs if t == 'tcb-budget']
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

    # Review-4 R4-6: "fact types" is two numbers, and the packet names both — the types the schema DECLARES and
    # the types the model INSTANTIATES — together with the declared-but-uninstantiated ones, so the two counts
    # can never again be quoted as if they measured the same universe.
    declared_types = [str(x[1]).lower() for x in SR.read_forms_file(os.path.join(HERE, 'MODEL-SCHEMA.sexp'))[0][2:]
                      if isinstance(x, list) and SR.head(x) == 'define-fact-type']
    enums = sum(1 for x in SR.read_forms_file(os.path.join(HERE, 'MODEL-SCHEMA.sexp'))[0][2:]
                if isinstance(x, list) and SR.head(x) == 'define-enum')
    idle = sorted(set(declared_types) - set(fam))
    values = {
        'schema-summary': ('schema version %s: %d schema-declared fact types, %d instantiated fact types, %d '
                           'enums, %d modules; declared but not instantiated: %s.'
                           % (pl['schema-version'], len(declared_types), len(fam), enums, len(mods),
                              ', '.join(idle) if idle else 'none')),
        'reconciliation': '\n'.join(recon),
        'total-facts': str(len(fs)),
        'modules': str(len(mods)),
        'parent-commit': str(pl['parent-architecture-commit']),
        'root-digest': dig,
        'family-table': '\n'.join('| %s | %d |' % (t, fam[t]) for t in sorted(fam)),
        'module-table': '\n'.join('| %s | %d |' % (m, permod[m]) for m in sorted(permod)),
        'ledger-verdict': 'PASS' if dvc == 0 else 'FAIL',
        'ledger-line': last(dvo),
        'status-table': '\n'.join('| %s | %d | %d |' % (k, status[k], forms[k]) for k in sorted(status)),
        'batch-summary': ', '.join('%s=%d classes / %d forms' % (k, batch[k], batch_forms[k])
                                   for k in sorted(batch)),
        'imported-classes': str(status.get('IMPORTED', 0)),
        'imported-forms': str(forms.get('IMPORTED', 0)),
        'deferred-classes': str(status.get('DEFERRED_DATA_IMPORT', 0)),
        'deferred-forms': str(forms.get('DEFERRED_DATA_IMPORT', 0)),
        'out-of-scope-classes': str(status.get('OUT_OF_MIGRATION_SCOPE', 0)),
        'global-promotion': promo['GLOBAL']['state'] if 'GLOBAL' in promo else 'ABSENT',
        'inventory-sentence': ('%s tracked paths are classified exactly once: %s carry an individual `file` fact '
                               'and %s are counted by %s `dir-rule` facts.'
                               % (inv[0]['tracked'], inv[0]['file-facts'], inv[0]['dir-rule-sum'],
                                  inv[0]['dir-rule-facts'])) if inv else 'No inventory-total fact is present.',
        'tcb-sentence': ('The acceptance machinery the operator is asked to trust is %s executable files, %s '
                         'physical and %s non-blank/non-comment lines; the verified baseline %s was %s files / '
                         '%s physical / %s non-blank/non-comment. The size is a measured fact and a complexity '
                         'signal, not a threshold, and every growth over the baseline is attributed to a '
                         'reproduced finding by the acceptance command. The 400/400 Lisp kernel budget is one '
                         'path\'s budget and is not this number.'
                         % (tcb[0]['files'], tcb[0]['physical'], tcb[0]['nbnc'],
                            str(budget[0]['baseline-commit'])[:12], budget[0]['baseline-files'],
                            budget[0]['baseline-physical'], budget[0]['baseline']))
                        if tcb and budget else 'No TCB measurement is present.',
        'kernel-verdict': kernel_verdict,
        'kernel-exit': str(kc),
        'checker-verdict': checker_verdict,
        'checker-exit': str(cc),
        'fixtures-verdict': 'PASS' if fc == 0 else 'FAIL',
        'fixtures-line': last(fo),
        'path-agreement': 'AGREE' if kernel_verdict == checker_verdict else 'DISAGREE',
        'commitment-digest': kdig,
    }
    with open(os.path.join(HERE, 'PACKET-TEMPLATE.md'), encoding='utf-8') as fh:
        template = fh.read()
    body = render(template[template.index('# ROOT-OPERATOR-DECISION-PACKET'):], values, blocks())
    with open(os.path.join(HERE, 'ROOT-OPERATOR-DECISION-PACKET.md'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(body)
    print('decision packet written (kernel=%s checker=%s commitments identical fixtures=%s facts=%d)'
          % (kernel_verdict, checker_verdict, fc == 0, len(fs)))


if __name__ == '__main__':
    main()
