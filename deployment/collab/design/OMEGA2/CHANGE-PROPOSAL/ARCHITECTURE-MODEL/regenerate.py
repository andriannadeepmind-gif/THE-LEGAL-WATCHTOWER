#!/usr/bin/env python3
"""regenerate.py — the APPLY command. The only thing in this seat that writes derived artifacts into the tree.

Review-2 N-2. `ARCHITECTURE-MODEL-GATE.sh` is a read-only judgement: it exports an immutable candidate tree into
a private workspace, regenerates there, and byte-compares. It never writes to the working tree and it never calls
this program. Applying and judging are separate commands precisely so that "the gate passed" can never mean "the
gate rewrote the thing it was about to inspect".

Run this deliberately, after editing an authored module, to bring the derived artifacts back into agreement:

    python3 ARCHITECTURE-MODEL/regenerate.py

It executes exactly the order the MODEL declares (generation-order.sexp, topologically sorted — this program
carries no private order of its own) over the WORKING TREE, and prints what changed. It issues no verdict: run
the gate afterwards for that.
"""
import argparse, hashlib, importlib.util, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location('sexp_reader', os.path.join(HERE, 'SEXP-READER.py'))
SR = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(SR)


def sha(path):
    if not os.path.isfile(path):
        return None
    with open(path, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()


def declared():
    """The generation steps, edges and artifacts, read from the working tree's own model."""
    steps, edges, artifacts = {}, [], []
    for f in SR.read_forms_file(os.path.join(HERE, 'generation-order.sexp')):
        if SR.head(f) != 'fact':
            continue
        kind = str(f[1])
        if kind == 'gen-step':
            steps[SR.canonical_value(f[2], 'g', 'id')] = str(SR.kv(f, 'producer'))
        elif kind == 'gen-edge':
            edges.append((str(SR.kv(f, 'from')).upper(), str(SR.kv(f, 'to')).upper()))
        elif kind == 'gen-artifact':
            artifacts.append(str(SR.kv(f, 'path')))
    return steps, edges, artifacts


def topological(steps, edges):
    indeg = {s: 0 for s in steps}
    adj = {s: [] for s in steps}
    for a, b in edges:
        if a not in steps or b not in steps:
            sys.stderr.write('REGENERATION-BLOCKED: generation edge %s -> %s names an undeclared step\n' % (a, b))
            sys.exit(2)
        adj[a].append(b); indeg[b] += 1
    order, ready = [], sorted(s for s in steps if indeg[s] == 0)
    while ready:
        u = ready.pop(0); order.append(u)
        for w in sorted(adj[u]):
            indeg[w] -= 1
            if indeg[w] == 0:
                ready.append(w); ready.sort()
    if len(order) != len(steps):
        sys.stderr.write('REGENERATION-BLOCKED: the declared generation order is cyclic (%s)\n'
                         % sorted(set(steps) - set(order)))
        sys.exit(2)
    return [steps[s] for s in order]


def main():
    argparse.ArgumentParser(description=__doc__).parse_args()
    try:
        steps, edges, artifacts = declared()
    except SR.SexpError as e:
        sys.stderr.write('REGENERATION-BLOCKED: %s\n' % e)
        sys.exit(2)
    before = {a: sha(os.path.join(HERE, a)) for a in artifacts}
    for producer in topological(steps, edges):
        path = os.path.join(HERE, producer)
        if not os.path.isfile(path):
            sys.stderr.write('REGENERATION-BLOCKED: declared producer %s does not exist\n' % producer)
            sys.exit(2)
        r = subprocess.run([sys.executable, path], capture_output=True, text=True, cwd=HERE)
        if r.returncode != 0:
            sys.stderr.write('REGENERATION-FAILED: %s exited %d\n%s\n' % (producer, r.returncode, r.stdout + r.stderr))
            sys.exit(2)
        first = r.stdout.strip().splitlines()
        print('  %-28s %s' % (producer, first[0] if first else 'ok'))
    after = {a: sha(os.path.join(HERE, a)) for a in artifacts}
    changed = [a for a in artifacts if before.get(a) != after.get(a)]
    for a in changed:
        print('CHANGED: %s' % a)
    print('regenerate: %d declared artifacts, %d changed. This command issues NO verdict — run '
          'ARCHITECTURE-MODEL-GATE.sh for that.' % (len(artifacts), len(changed)))


if __name__ == '__main__':
    main()
