#!/usr/bin/env python3
"""SUBAGENT_START — REV3.1 SubagentStart hook (lifecycle boundary).
UNVERIFIED-UNTIL-FRESH-SESSION-CANARY.

Records that a subagent actually STARTED, so the adjudicator can require the exact
lifecycle (repair 7):

  Agent Pre ALLOW -> one SubagentStart -> eight Read Pre events -> exactly one
  successful Post for the allowed Read and zero Post for every denied Read ->
  one matching SubagentStop after the reads -> one matching Agent Post result.

Advisory only: never blocks.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import _common as C  # noqa: E402


def main():
    _raw, payload = C.read_payload()
    ident = C.extract_identity(payload)
    run_dir = C.read_run_dir()
    cwd = payload.get("cwd") or C.project_base(payload)
    topo = C.git_topology(cwd)
    rec = {
        "ts": C.now_utc(),
        "hook": "subagent_start",
        "event": payload.get("hook_event_name", "SubagentStart"),
        "tool_use_id": payload.get("tool_use_id") or payload.get("toolUseId"),
        "session_id": ident.get("session_id"),
        "agent_type": ident.get("agent_type"),
        "agent_id": ident.get("agent_id"),
        "cwd": payload.get("cwd"),
        "cwd_real": topo.get("cwd_real"),
        "cwd_head": topo.get("cwd_head"),
        "cwd_tree": topo.get("cwd_tree"),
        "git_dir": topo.get("git_dir"),
        "git_common_dir": topo.get("git_common_dir"),
        "is_linked_worktree": topo.get("is_linked_worktree"),
    }
    C.append_evidence(run_dir, "lifecycle.jsonl", rec)
    sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception:
        sys.exit(0)
