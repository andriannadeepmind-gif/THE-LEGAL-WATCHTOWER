#!/usr/bin/env python3
"""Committed canary journal fixtures — SINGLE SEAT for the REV3.2 regression suite and
the transferred REV3.1 false-PASS witnesses. UNVERIFIED-UNTIL-FRESH-SESSION-CANARY.

Builds a PERFECT ordered-journal fixture that carries EVERY field of the production
contract — the identity triple, worktree topology, monotonic seq + hash chain,
spawn/tool-use binding, exactly-one fully-bound allowed Post, zero denied Posts, complete
output scans, and success flags — plus the plumbing to drive the deterministic
adjudicator against a synthetic journal.  No live canary, subagent, or study is run: the
adjudicator's pure scoring core is exercised over hand-built journals only.

The journal envelopes (seq + prev + hash chain) are built with _common.chain_link and
_common.JOURNAL_GENESIS — the exact functions the live hooks use — so the fixtures prove
the SAME contract the production transport writes, never a weaker one.
"""
import os
import sys
import json
import copy
import tempfile

HERE = os.path.dirname(os.path.realpath(__file__))
REPO = os.path.realpath(os.path.join(HERE, "..", "..", ".."))
SPEC = os.path.join(REPO, "experiment", "canary", "spec")
TOOLS = os.path.join(REPO, "experiment", "canary", "tools")
HOOKS = os.path.join(REPO, ".claude", "hooks")
for _p in (TOOLS, HOOKS):
    if _p not in sys.path:
        sys.path.insert(0, _p)

import _common as C          # noqa: E402  single seat for genesis + chain formula + scan
import adjudicate            # noqa: E402

NOW = "2026-08-25T12:30:00Z"
COMMIT = "a" * 40
TREE = "b" * 40
CTRL_CWD = "/repo/main"
CTRL_GITDIR = "/repo/main/.git"
CTRL_COMMON = "/repo/main/.git"
WT_CWD = "/repo/wt-canary"
WT_GITDIR = "/repo/main/.git/worktrees/wt-canary"
SPAWN_TUID = "tuid-spawn"


def _spec():
    man = json.load(open(os.path.join(SPEC, "MANIFEST.json"), encoding="utf-8"))
    prof = json.load(open(os.path.join(SPEC, "EXPECTED-RESULTS.json"), encoding="utf-8"))
    return man, prof["expected_profile"]["spawn_prompt_sha256"]


def _read_input_hash(path):
    return C.canonical_hash({"file_path": path})


def build_perfect():
    """The exact-profile perfect run as an ordered event list (seq order = list order)."""
    man, pin = _spec()
    attempts = man["attempts"]
    allowed_tok = man["allowed_output_channel_token"]
    forbidden = man["forbidden_output_channel_tokens"]
    ident = {"agent_type": "lane-blind-reader", "agent_id": "aid-1", "session_id": "sid-1"}
    topo = {"cwd_real": WT_CWD, "cwd_head": COMMIT, "cwd_tree": TREE,
            "git_dir": WT_GITDIR, "git_common_dir": CTRL_COMMON, "is_linked_worktree": True}

    events = []
    spawn = {"tool": "Agent", "decision": "allow", "tool_use_id": SPAWN_TUID,
             "requested_subagent_type": "lane-blind-reader", "prompt_sha256": pin}
    events.append(["pretool", spawn])

    start = {"hook": "subagent_start", "tool_use_id": SPAWN_TUID}
    start.update(ident); start.update(topo)
    events.append(["lifecycle", start])

    allowed_tuid = None
    allowed_path = None
    i = 1
    for att in attempts:
        tuid = "tuid-r%d" % i
        rec = {"tool": "Read", "tool_use_id": tuid, "target": att["path"],
               "input_hash": _read_input_hash(att["path"]),
               "decision": "allow" if att["expected"] == "ALLOW" else "deny"}
        rec.update(ident); rec.update(topo)
        events.append(["pretool", rec])
        if att["expected"] == "ALLOW":
            allowed_tuid = tuid
            allowed_path = att["path"]
        i += 1

    allowed_full = "1\tLANE-INBOX (sealed) token: %s\n" % allowed_tok
    allowed_post = {"tool": "Read", "tool_use_id": allowed_tuid, "target": allowed_path,
                    "input_hash": _read_input_hash(allowed_path),
                    "produced_output": True, "is_error": False,
                    "response_text": allowed_full, "output_scan": C.scan_output(allowed_full)}
    allowed_post.update(ident); allowed_post.update(topo)
    events.append(["posttool", allowed_post])

    final_full = ("OK read the allowed inbox: %s. Every forbidden target was DENIED. "
                  "CANARY-SELF-REPORT: ALL-FORBIDDEN-DENIED" % allowed_tok)
    stop = {"hook": "subagent_complete", "tool_use_id": SPAWN_TUID,
            "final_response": final_full, "final_response_len": len(final_full),
            "output_scan": C.scan_output(final_full)}
    stop.update(ident); stop.update(topo)
    events.append(["lifecycle", stop])

    agent_full = ("Subagent finished. Allowed inbox token: %s. All forbidden reads denied. "
                  "CANARY-SELF-REPORT: ALL-FORBIDDEN-DENIED" % allowed_tok)
    agent_post = {"tool": "Agent", "tool_use_id": SPAWN_TUID, "produced_output": True,
                  "is_error": False, "response_text": agent_full,
                  "output_scan": C.scan_output(agent_full)}
    events.append(["posttool", agent_post])

    manifest = {"expected_head": COMMIT, "expected_tree": TREE,
                "controller_cwd_real": CTRL_CWD, "controller_git_dir": CTRL_GITDIR,
                "controller_git_common_dir": CTRL_COMMON}
    return {"events": events, "manifest": manifest,
            "_allowed_tuid": allowed_tuid, "_allowed_path": allowed_path,
            "_spawn_tuid": SPAWN_TUID, "_allowed_token": allowed_tok,
            "_forbidden_tokens": forbidden}


# ---- accessors over the ordered event list (payloads are mutated in place) ----
def _payloads(fx, kind):
    return [p for (k, p) in fx["events"] if k == kind]


def reads(fx):
    return [p for p in _payloads(fx, "pretool") if p.get("tool") == "Read"]


def spawn(fx):
    for p in _payloads(fx, "pretool"):
        if p.get("tool") in ("Agent", "Task"):
            return p
    return None


def allowed_read(fx):
    for p in reads(fx):
        if p.get("tool_use_id") == fx["_allowed_tuid"]:
            return p
    return None


def first_denied_read(fx):
    for p in reads(fx):
        if p.get("decision") == "deny":
            return p
    return None


def allowed_post(fx):
    for p in _payloads(fx, "posttool"):
        if p.get("tool") == "Read" and p.get("tool_use_id") == fx["_allowed_tuid"]:
            return p
    return None


def agent_post(fx):
    for p in _payloads(fx, "posttool"):
        if p.get("tool") in ("Agent", "Task"):
            return p
    return None


def lifecycle(fx, hook):
    for p in _payloads(fx, "lifecycle"):
        if p.get("hook") == hook:
            return p
    return None


def add_event(fx, kind, payload, index=None):
    entry = [kind, payload]
    if index is None:
        fx["events"].append(entry)
    else:
        fx["events"].insert(index, entry)


def drop_events(fx, predicate):
    fx["events"] = [e for e in fx["events"] if not predicate(e[0], e[1])]


# ---- journal envelope construction (mirrors _common.append_journal exactly) ----
def build_envelopes(events):
    envs = []
    prev = C.JOURNAL_GENESIS
    for i, (kind, payload) in enumerate(events, start=1):
        env = {"seq": i, "prev": prev, "kind": kind,
               "ts": "2026-08-25T12:%02d:00Z" % i, "payload": payload}
        env["chain"] = C.chain_link(prev, env)
        prev = env["chain"]
        envs.append(env)
    return envs


def run_adjudicator(fx, envelope_mutator=None):
    """Materialize fx into a journal + manifest and return the adjudicator verdict.
    envelope_mutator (optional) tampers with the finished envelopes — used to build the
    duplicate/non-monotonic seq and broken-hash-chain fixtures."""
    envs = build_envelopes(fx["events"])
    if envelope_mutator is not None:
        envs = envelope_mutator(envs)
    d = tempfile.mkdtemp(prefix="canary-fx-")
    with open(os.path.join(d, "run-manifest.json"), "w") as f:
        json.dump(fx["manifest"], f)
    with open(os.path.join(d, "journal.jsonl"), "w") as f:
        for e in envs:
            f.write(json.dumps(e, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n")
    return adjudicate.adjudicate(d, SPEC, NOW)["verdict"]


# re-export for convenience
deepcopy = copy.deepcopy
