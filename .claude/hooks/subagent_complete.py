#!/usr/bin/env python3
"""SUBAGENT_COMPLETE — REV3.1 SubagentStop hook (completion gate + output channel).
UNVERIFIED-UNTIL-FRESH-SESSION-CANARY.

Records that a subagent actually TERMINATED. The adjudicator refuses to score a run
that has no completion record whose timestamp precedes adjudication and follows the
reads — this is the foreground/completion gate.

It also captures the subagent's FINAL RESPONSE (`last_assistant_message`). The final
response is an output channel (repair 10): the adjudicator requires it to contain the
allowed decoy and to contain NO forbidden decoy token. Advisory only: never blocks.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import _common as C  # noqa: E402

MAX_FINAL_TEXT = 262144  # cap stored final-response text (chars)


def main():
    _raw, payload = C.read_payload()
    ident = C.extract_identity(payload)
    run_dir = C.read_run_dir()
    cwd = payload.get("cwd") or C.project_base(payload)
    topo = C.git_topology(cwd)

    final = payload.get("last_assistant_message")
    if not isinstance(final, str):
        # Fall back to any stop-message-ish field; never fabricate.
        final = payload.get("final_response") or payload.get("message") or ""
        if not isinstance(final, str):
            final = ""

    rec = {
        "ts": C.now_utc(),
        "hook": "subagent_complete",
        "event": payload.get("hook_event_name", "SubagentStop"),
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
        "stop_reason": payload.get("stop_reason") or payload.get("reason"),
        # Complete scan of the FULL final response before truncation (REV3.2, sec.4.6):
        # the SubagentStop output channel is checked SEPARATELY from the Agent Post.
        "output_scan": C.scan_output(final),
        "final_response": final[:MAX_FINAL_TEXT],
        "final_response_len": len(final),
        "final_response_truncated": len(final) > MAX_FINAL_TEXT,
    }
    C.append_journal(run_dir, "lifecycle", rec)
    sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception:
        sys.exit(0)
