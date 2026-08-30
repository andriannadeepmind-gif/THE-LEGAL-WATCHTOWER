"""WATCHTOWER FORMAL ARCHITECTURE EVIDENCE PACK — bounded exhaustive model-checking harness.

Architecture verification only. Not production code, not an implementation of the system.

Method: each model declares an initial state, an enabled-action relation, and a set of
invariant properties. The harness performs exhaustive breadth-first exploration of the
reachable state space up to declared bounds and reports, for every property, either
HOLDS (no reachable violation within bounds) or a concrete counterexample trace.

Discipline enforced by this harness, per invariant I-23:
  * every result carries an explicit BOUNDS STAMP (state cap, depth cap, model constants);
  * an exhausted search is reported as "bounded-exhaustive", never as a universal theorem;
  * a search that hits the state cap is reported as TRUNCATED and is NOT a pass;
  * every model must also pass its MUTATION battery (seeded defects must be caught),
    otherwise its properties are declared VACUOUS and the model result is invalid.
"""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass, field
from typing import Any, Callable, Iterable


@dataclass(frozen=True)
class Property:
    name: str
    check: Callable[[Any], bool]  # state -> True iff the property holds in that state


@dataclass
class Model:
    name: str
    init: Any
    actions: Callable[[Any], Iterable[tuple[str, Any]]]
    properties: list[Property]
    bounds: dict[str, Any] = field(default_factory=dict)


@dataclass
class Result:
    model: str
    status: str  # EXHAUSTED | TRUNCATED
    states: int
    edges: int
    depth: int
    bounds: dict[str, Any]
    holds: list[str]
    violations: dict[str, list[str]]  # property -> counterexample trace


def explore(model: Model, max_states: int = 400_000, max_depth: int = 64) -> Result:
    init = model.init
    seen = {init: None}  # state -> (parent_state, action_label)
    queue = deque([(init, 0)])
    violations: dict[str, list[str]] = {}
    edges = 0
    deepest = 0
    truncated = False

    def trace_to(state: Any) -> list[str]:
        path: list[str] = []
        cur = state
        while seen.get(cur) is not None:
            parent, label = seen[cur]
            path.append(label)
            cur = parent
        return list(reversed(path))

    def audit(state: Any) -> None:
        for prop in model.properties:
            if prop.name in violations:
                continue
            if not prop.check(state):
                violations[prop.name] = trace_to(state)

    audit(init)
    while queue:
        state, depth = queue.popleft()
        deepest = max(deepest, depth)
        if depth >= max_depth:
            continue
        for label, nxt in model.actions(state):
            edges += 1
            if nxt in seen:
                continue
            if len(seen) >= max_states:
                truncated = True
                break
            seen[nxt] = (state, label)
            audit(nxt)
            queue.append((nxt, depth + 1))
        if truncated:
            break

    holds = [p.name for p in model.properties if p.name not in violations]
    if deepest >= max_depth:
        truncated = True  # depth cap reached: successors beyond it were never explored
    return Result(
        model=model.name,
        status="TRUNCATED" if truncated else "EXHAUSTED",
        states=len(seen),
        edges=edges,
        depth=deepest,
        bounds=dict(model.bounds),
        holds=holds,
        violations=violations,
    )


def run_model(build: Callable[[str | None], Model], mutants: dict[str, str],
              max_states: int = 400_000, max_depth: int = 64) -> dict[str, Any]:
    """Baseline run + mutation battery.

    `build(mutation)` returns the model with the named defect seeded (None = baseline).
    `mutants` maps mutation name -> the property that defect MUST violate (teeth check).
    """
    base = explore(build(None), max_states, max_depth)
    report: dict[str, Any] = {
        "model": base.model,
        "baseline": base,
        "mutation_battery": {},
        "teeth_ok": True,
        "verdict": "",
    }
    for mutation, expected_property in mutants.items():
        res = explore(build(mutation), max_states, max_depth)
        caught = expected_property in res.violations
        report["mutation_battery"][mutation] = {
            "expected_property": expected_property,
            "caught": caught,
            "counterexample": res.violations.get(expected_property, []),
            "status": res.status,
        }
        if not caught:
            report["teeth_ok"] = False

    if base.status == "TRUNCATED":
        report["verdict"] = "INVALID — state space truncated; bounds too small to claim exhaustion"
    elif base.violations:
        report["verdict"] = "COUNTEREXAMPLE FOUND — architecture violates a declared property"
    elif not report["teeth_ok"]:
        report["verdict"] = "VACUOUS — mutation battery not fully caught; properties prove nothing"
    else:
        report["verdict"] = "BOUNDED-EXHAUSTIVE PASS"
    return report


def format_report(report: dict[str, Any]) -> str:
    base: Result = report["baseline"]
    lines = [f"### {base.model}", ""]
    lines.append(f"verdict: **{report['verdict']}**")
    lines.append("")
    lines.append(f"bounds stamp: {base.bounds}")
    lines.append(f"search: {base.status}, states={base.states}, transitions={base.edges}, max-depth={base.depth}")
    lines.append("")
    lines.append("properties:")
    for name in base.holds:
        lines.append(f"  - {name}: HOLDS (no reachable violation within bounds)")
    for name, tr in base.violations.items():
        lines.append(f"  - {name}: VIOLATED — trace: {' -> '.join(tr) if tr else '(initial state)'}")
    lines.append("")
    lines.append("mutation battery (teeth — a seeded defect MUST be caught):")
    for mutation, info in report["mutation_battery"].items():
        mark = "CAUGHT" if info["caught"] else "MISSED"
        tr = " -> ".join(info["counterexample"]) if info["counterexample"] else "(initial state)"
        lines.append(f"  - {mutation} vs {info['expected_property']}: {mark}"
                     + (f" — trace: {tr}" if info["caught"] else ""))
    lines.append("")
    return "\n".join(lines)
