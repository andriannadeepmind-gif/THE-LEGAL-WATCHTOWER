#!/usr/bin/env python3
"""Deterministic GENERATED views of the canonical model.

Review-2 N-3 — THE OUTPUT UNIVERSE IS NO LONGER A LIST IN THIS FILE. Before this pass the six views existed only
as six literal `w("...")` calls here, `generation-order.sexp` declared merely the directory, and no counted check
enumerated the members of GENERATED/. A view deleted from generator and tree passed the complete gate; an
undeclared extra output was accepted; a generator-only rename orphaned a tracked view that could then be
hand-edited with fabricated content while still stamped "GENERATED — DO NOT EDIT".

Now every artifact is a `gen-artifact` fact. This program looks up the renderer for each DECLARED artifact of the
VIEWS step and refuses to run if the model declares an artifact it cannot render, or if it can render one the
model does not declare. `gate_checks.py artifacts` then asserts exact set equality with the candidate tree.

The module universe comes from ROOT.sexp — there is no second module list here. Facts are read through the
repository's single Python reader seat (SEXP-READER.py), so a fact spanning several lines is read like any other
and cannot be silently lost by a line matcher. Every count printed in a view is derived from the model at
generation time, so no total can go stale.

Review-2 N-2: `--out DIR` renders into another directory and leaves the tracked tree untouched, which is what
lets the gate COMPARE instead of overwrite.
"""
import argparse, importlib.util, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location('sexp_reader', os.path.join(HERE, 'SEXP-READER.py'))
SR = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(SR)
GEN_VERSION = "generate_views.py/3"
HEADERS = SR.HEADERS          # one seat: the reader declares the header vocabulary


def fail(msg):
    sys.stderr.write('FATAL: %s\n' % msg)
    sys.exit(2)


def root_plist():
    forms = SR.read_forms_file(os.path.join(HERE, 'ROOT.sexp'))
    roots = [f for f in forms if SR.head(f) == 'define-model-root']
    if len(roots) != 1 or len(forms) != 1:
        fail('ROOT.sexp must contain exactly one define-model-root form and nothing else')
    return dict(SR.plist(roots[0][2:], 'ROOT.sexp', 'define-model-root'))


def read_facts(modules):
    out = []
    for mod in modules:
        for form in SR.read_forms_file(os.path.join(HERE, mod)):
            h = SR.head(form)
            if h in HEADERS:
                continue
            if h != 'fact' or len(form) < 3:
                fail('%s: unconsumed top-level form %r' % (mod, h))
            ftype = str(form[1]).lower()
            fid = SR.canonical_value(form[2], mod, 'fact id')
            pairs = SR.plist(form[3:], mod, '%s %s' % (ftype, fid))
            out.append((ftype, fid, {k.lower(): SR.canonical_value(v, mod, k) for k, v in pairs}))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--out', help='render into this directory instead of the tracked tree')
    args = ap.parse_args()
    outdir = os.path.abspath(args.out) if args.out else HERE

    pl = root_plist()
    digest = str(pl.get('canonical-model-root-digest', ''))
    modules = [str(dict(SR.plist(e, 'ROOT.sexp', 'composition entry'))['module'])
               for e in pl.get('composition', [])]
    facts = read_facts(modules)
    byt = {}
    for t, i, p in facts:
        byt.setdefault(t, []).append((i, p))
    cmd = "python3 ARCHITECTURE-MODEL/regenerate.py"

    def stamp(title):
        return ("<!-- GENERATED — DO NOT EDIT. Regenerate: %s -->\n# %s (GENERATED VIEW — DO NOT EDIT)\n\n"
                "- generator: `%s`\n- canonical-model-root-digest: `%s`\n- regeneration command: `%s`\n\n"
                % (cmd, title, GEN_VERSION, digest, cmd))

    # ── renderers, keyed by the declared artifact id ───────────────────────────────────────────────────────
    def subsystem_registry():
        s = stamp("Subsystem Registry View")
        s += "| subsystem | classification | owner-seat | seat status | mission | migration |\n|---|---|---|---|---|---|\n"
        seats = {i: p for i, p in byt.get('seat', [])}
        for i, p in sorted(byt.get('subsystem', [])):
            st = seats.get(p.get('owner-seat', ''), {}).get('status', '')
            s += "| %s | %s | %s | %s | %s | %s |\n" % (i, p.get('classification', ''), p.get('owner-seat', ''),
                                                        st, p.get('mission', ''), p.get('migration', ''))
        return s

    def seat_registry():
        s = stamp("Seat Registry View — every declared seat, its status and its artifact")
        s += ("Review-2 N-10: a seat is BUILT or DOCUMENT_SEAT only when it names a tracked path, and a seat that "
              "is not built carries the rationale and the work packet that will build it. No seat is a bare string.\n\n")
        s += "| seat | status | path | packet | rationale |\n|---|---|---|---|---|\n"
        for i, p in sorted(byt.get('seat', [])):
            s += "| %s | %s | %s | %s | %s |\n" % (i, p.get('status', ''), p.get('path', '—'),
                                                   p.get('packet', '—'), p.get('rationale', '—'))
        by_status = {}
        for _i, p in byt.get('seat', []):
            by_status[p.get('status', '?')] = by_status.get(p.get('status', '?'), 0) + 1
        s += "\nSeats: %d total — %s.\n" % (len(byt.get('seat', [])),
                                            ', '.join('%d %s' % (by_status[k], k) for k in sorted(by_status)))
        return s

    def toolchain_identity():
        s = stamp("Toolchain Identity View — what each verification path is allowed to execute")
        s += ("Review-2 N-11: these are executable policy, not prose. `gate_checks.py toolchain` verifies every "
              "row below — path, semantic version and exact executable digest — and refuses to let either "
              "verifier run on a mismatch. No tool proves its own identity: `verified by` names the OTHER path.\n\n")
        s += "| tool | role | semantic version | verified by | path |\n|---|---|---|---|---|\n"
        for i, p in sorted(byt.get('tool', [])):
            s += "| %s | %s | %s | %s | `%s` |\n" % (i, p.get('role', ''), p.get('semantic-version', ''),
                                                     p.get('verified-by', ''), p.get('path', ''))
        return s

    def ownership_matrix():
        s = stamp("Store Ownership / Write-Authority Matrix")
        s += "| store | owner seat | writer seat | writer status |\n|---|---|---|---|\n"
        seats = {i: p for i, p in byt.get('seat', [])}
        for i, p in sorted(byt.get('store', [])):
            s += "| %s | %s | %s | %s |\n" % (i, p.get('owner', ''), p.get('writer', ''),
                                              seats.get(p.get('writer', ''), {}).get('status', ''))
        return s

    def dependency_view():
        s = stamp("Dependency View") + "## Permitted pipeline (acyclic stage DAG — law L4)\n\n"
        for _i, p in sorted(byt.get('stage-edge', [])):
            s += "- %s -> %s\n" % (p['from'], p['to'])
        s += "\n## Declared generation order (acyclic — law L4)\n\n"
        for _i, p in sorted(byt.get('gen-edge', [])):
            s += "- %s -> %s\n" % (p['from'], p['to'])
        s += "\n## Data-flow consumes edges (recorded, not acyclicity-constrained)\n\n"
        for _i, p in sorted(byt.get('consumes', [])):
            s += "- %s consumes %s\n" % (p['consumer'], p['provides'])
        return s

    def traceability():
        s = stamp("Requirement -> Seat -> Test -> WP Traceability View")
        s += "| subsystem | requirement | seat | test | wp |\n|---|---|---|---|---|\n"
        for _i, p in sorted(byt.get('req-map', [])):
            s += "| %s | %s | %s | %s | %s |\n" % (p['subsystem'], p['requirement'], p['seat'], p['test'], p['wp'])
        return s

    def closure_summary():
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
        return s

    def deferred_view():
        s = stamp("Migration-Scope Ledger View (imported vs DEFERRED_DATA_IMPORT)")
        order = {'IMPORTED': 0, 'DEFERRED_DATA_IMPORT': 1, 'OUT_OF_MIGRATION_SCOPE': 2}
        rows = [p for _i, p in byt.get('source-class', [])]
        s += ("Review-2 N-7: `authority` is the column that matters. A DEFERRED class is enumerated and scheduled, "
              "and its DETAIL remains authoritative at its declared legacy source until its batch is complete and "
              "independently reviewed — it is not canonical here merely because it is listed here.\n\n")
        s += "| source-file | fact-class | forms | status | authority | batch | maps-to / reason |\n"
        s += "|---|---|---|---|---|---|---|\n"
        for p in sorted(rows, key=lambda p: (order.get(p.get('status'), 9), p.get('source-file', ''),
                                             p.get('fact-class', ''))):
            s += "| %s | %s | %s | %s | %s | %s | %s |\n" % (
                p.get('source-file', ''), p.get('fact-class', ''), p.get('source-count', ''), p.get('status', ''),
                p.get('authority', ''), p.get('batch', '—'), p.get('maps-to', p.get('reason', '')))
        counts, forms = {}, {}
        for p in rows:
            k = p.get('status', '?')
            counts[k] = counts.get(k, 0) + 1
            forms[k] = forms.get(k, 0) + int(p.get('source-count', 0))
        s += "\nSource classes: %d total — %s.\n" % (
            len(rows), ', '.join('%d %s (%d source forms)' % (counts[k], k, forms[k]) for k in sorted(counts)))
        for i, p in sorted(byt.get('promotion', [])):
            s += "\n- **%s** — scope `%s`, state `%s`: %s\n" % (i, p.get('scope'), p.get('state'), p.get('reason'))
        return s

    RENDER = {'ART-VIEW-SUBSYSTEM-REGISTRY': subsystem_registry,
              'ART-VIEW-SEAT-REGISTRY': seat_registry,
              'ART-VIEW-TOOLCHAIN': toolchain_identity,
              'ART-VIEW-OWNERSHIP-MATRIX': ownership_matrix,
              'ART-VIEW-DEPENDENCY': dependency_view,
              'ART-VIEW-REQUIREMENT-TRACEABILITY': traceability,
              'ART-VIEW-ARCHITECTURE-CLOSURE': closure_summary,
              'ART-VIEW-DEFERRED-DATA-IMPORT': deferred_view}

    declared = {i: p for i, p in byt.get('gen-artifact', []) if p.get('step') == 'VIEWS'}
    missing = sorted(set(declared) - set(RENDER))
    extra = sorted(set(RENDER) - set(declared))
    if missing:
        fail('the model declares generated view(s) this generator cannot render: %s' % ', '.join(missing))
    if extra:
        fail('this generator can render view(s) the model does not declare: %s' % ', '.join(extra))

    written = []
    for aid in sorted(declared):
        rel = declared[aid]['path']
        target = os.path.join(outdir, rel)
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with open(target, 'w', encoding='utf-8', newline='\n') as f:
            f.write(RENDER[aid]())
        written.append(rel)
    print("generated %d model-declared views from %d facts (root-digest %s)" % (len(written), len(facts), digest[:12]))


if __name__ == '__main__':
    main()
