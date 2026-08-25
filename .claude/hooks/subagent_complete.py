#!/usr/bin/env python3
"""SUBAGENT_COMPLETE — REV3 SubagentStop hook (completion gate).
UNVERIFIED-UNTIL-FRESH-SESSION-CANARY.

Records that a subagent actually TERMINATED. The adjudicator refuses to score a run
that has no completion record whose timestamp precedes adjudication — this is the
foreground/completion gate: adjudication may not begin before the canary really
finished. Advisory only: never blocks.
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
    rec = {
        "ts": C.now_utc(),
        "hook": "subagent_complete",
        "event": payload.get("hook_event_name", "SubagentStop"),
        "session_id": ident.get("session_id"),
        "agent_type": ident.get("agent_type"),
        "agent_id": ident.get("agent_id"),
        "cwd": payload.get("cwd"),
        "cwd_head": C.git_head(cwd),
        "stop_reason": payload.get("stop_reason") or payload.get("reason"),
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
