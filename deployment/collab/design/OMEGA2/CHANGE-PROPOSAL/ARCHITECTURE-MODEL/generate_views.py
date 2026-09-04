#!/usr/bin/env python3
"""Deterministic GENERATED views of the canonical model.

The module universe comes from ROOT.sexp — there is no second module list here. Facts are read through the
repository's single Python reader seat (SEXP-READER.py), so a fact spanning several lines is read like any
other and cannot be silently lost by a line matcher.

Every view is stamped GENERATED — DO NOT EDIT, with the canonical model-root digest, the generator version and
the exact regeneration command. Regenerating twice is byte-identical; a manual edit of a view is detected by
the gate (fresh regeneration != committed file). Every count printed in a view is derived from the model at
generation time — no total is written by hand, so a total cannot go stale.
"""
import importlib.util, os, sys

GEN_VERSION = "generate_views.py/2"
HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location('sexp_reader', os.path.join(HERE, 'SEXP-READER.py'))
SR = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(SR)
HEADERS = ('define-model-schema', 'define-model-root', 'define-toolchain')


def root_plist():
    forms = SR.read_forms_file(os.path.join(HERE, 'ROOT.sexp'))
    roots = [f for f in forms if SR.head(f) == 'define-model-root']
    if len(roots) != 1:
        sys.stderr.write('FATAL: ROOT.sexp must contain exactly one define-model-root form\n'); sys.exit(2)
    return dict(SR.plist(roots[0][2:], 'ROOT.sexp', 'define-model-root'))


def module_universe(pl):
    return [str(dict(SR.plist(e, 'ROOT.sexp', 'composition entry'))['module']) for e in pl.get('composition', [])]


def read_facts(modules):
    """Every fact in every ROOT-pinned module, as (type, id, {key: rendered value})."""
    out = []
    for mod in modules:
        path = os.path.join(HERE, mod)
        for form in SR.read_forms_file(path):
            h = SR.head(form)
            if h in HEADERS:
                continue
            if h != 'fact' or len(form) < 3:
                sys.stderr.write('FATAL: %s: unconsumed top-level form %r\n' % (mod, h)); sys.exit(2)
            ftype = str(form[1]).lower()
            fid = SR.canonical_value(form[2], mod, 'fact id')
            pairs = SR.plist(form[3:], mod, '%s %s' % (ftype, fid))
            out.append((ftype, fid, {k.lower(): SR.canonical_value(v, mod, k) for k, v in pairs}))
    return out


def main():
    pl = root_plist()
    digest = str(pl.get('canonical-model-root-digest', ''))
    facts = read_facts(module_universe(pl))
    byt = {}
    for t, i, p in facts:
        byt.setdefault(t, []).append((i, p))
    cmd = "python3 ARCHITECTURE-MODEL/generate_views.py"

    def stamp(title):
        return ("<!-- GENERATED — DO NOT EDIT. Regenerate: %s -->\n# %s (GENERATED VIEW — DO NOT EDIT)\n\n"
                "- generator: `%s`\n- canonical-model-root-digest: `%s`\n- regeneration command: `%s`\n\n"
                % (cmd, title, GEN_VERSION, digest, cmd))

    written = []

    def w(name, text):
        with open(os.path.join(HERE, 'GENERATED', name), 'w', encoding='utf-8', newline='\n') as f:
            f.write(text)
        written.append(name)

    s = stamp("Subsystem Registry View") + "| subsystem | classification | owner-seat | mission | migration |\n|---|---|---|---|---|\n"
    for i, p in sorted(byt.get('subsystem', [])):
        s += "| %s | %s | %s | %s | %s |\n" % (i, p.get('classification', ''), p.get('owner-seat', ''),
                                               p.get('mission', ''), p.get('migration', ''))
    w("SUBSYSTEM-REGISTRY-VIEW.md", s)

    s = stamp("Store Ownership / Write-Authority Matrix") + "| store | owner | writer |\n|---|---|---|\n"
    for i, p in sorted(byt.get('store', [])):
        s += "| %s | %s | %s |\n" % (i, p.get('owner', ''), p.get('writer', ''))
    w("OWNERSHIP-MATRIX.md", s)

    s = stamp("Dependency View") + "## Permitted pipeline (acyclic stage DAG — law L4)\n\n"
    for i, p in sorted(byt.get('stage-edge', [])):
        s += "- %s -> %s\n" % (p['from'], p['to'])
    s += "\n## Declared generation order (acyclic — law L4)\n\n"
    for i, p in sorted(byt.get('gen-edge', [])):
        s += "- %s -> %s\n" % (p['from'], p['to'])
    s += "\n## Data-flow consumes edges (recorded, not acyclicity-constrained)\n\n"
    for i, p in sorted(byt.get('consumes', [])):
        s += "- %s consumes %s\n" % (p['consumer'], p['provides'])
    w("DEPENDENCY-VIEW.md", s)

    s = stamp("Requirement -> Seat -> Test -> WP Traceability View") + "| subsystem | requirement | test | wp |\n|---|---|---|---|\n"
    for i, p in sorted(byt.get('req-map', [])):
        s += "| %s | %s | %s | %s |\n" % (p['subsystem'], p['requirement'], p['test'], p['wp'])
    w("REQUIREMENT-TRACEABILITY-VIEW.md", s)

    # Closure summary: EVERY fact family present in the model is listed. There is no hand-written family list
    # here, so a new family can never be silently absent and a printed total can never go stale.
    priv = [i for i, p in byt.get('type', []) if p.get('classification') == 'PRIVATE']
    s = stamp("Architecture Closure Summary") + "| entity | count |\n|---|---|\n"
    for t in sorted(byt):
        s += "| %s | %d |\n" % (t, len(byt[t]))
    s += "| **total facts** | **%d** |\n" % len(facts)
    s += "| private-types | %d |\n" % len(priv)
    s += "\nPrivate-bearing types: %s\n" % (', '.join(sorted(priv)))
    inv = byt.get('inventory-total', [])
    if inv:
        p = inv[0][1]
        s += ("\nTracked-file inventory: %s tracked paths = %s per-file facts + %s counted by %s directory-rule "
              "facts.\n" % (p.get('tracked'), p.get('file-facts'), p.get('dir-rule-sum'), p.get('dir-rule-facts')))
    w("ARCHITECTURE-CLOSURE-SUMMARY.md", s)

    s = stamp("Migration-Scope Ledger View (imported vs DEFERRED_DATA_IMPORT)")
    order = {'IMPORTED': 0, 'DEFERRED_DATA_IMPORT': 1, 'OUT_OF_MIGRATION_SCOPE': 2}
    s += "| source-file | fact-class | count | status | batch | maps-to / reason |\n|---|---|---|---|---|---|\n"
    rows = [p for _i, p in byt.get('source-class', [])]
    for p in sorted(rows, key=lambda p: (order.get(p.get('status'), 9), p.get('source-file', ''), p.get('fact-class', ''))):
        s += "| %s | %s | %s | %s | %s | %s |\n" % (p.get('source-file', ''), p.get('fact-class', ''),
                                                    p.get('source-count', ''), p.get('status', ''),
                                                    p.get('batch', '—'), p.get('maps-to', p.get('reason', '')))
    counts = {}
    for p in rows:
        counts[p.get('status', '?')] = counts.get(p.get('status', '?'), 0) + 1
    s += "\nSource classes: %d total — %s.\n" % (len(rows), ', '.join('%d %s' % (counts[k], k) for k in sorted(counts)))
    w("DEFERRED-DATA-IMPORT-VIEW.md", s)

    print("generated %d views from %d facts (root-digest %s)" % (len(written), len(facts), digest[:12]))


if __name__ == '__main__':
    main()
