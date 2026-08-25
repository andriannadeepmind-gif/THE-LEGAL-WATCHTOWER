#!/usr/bin/env python3
"""POSTTOOL_EVIDENCE — REV3 PostToolUse hook (ALL tools).
UNVERIFIED-UNTIL-FRESH-SESSION-CANARY.

PreToolUse receipts prove intent/decision only. This records the ACTUAL OUTCOME of
each executed tool call, bound to the same tool_use_id, so the adjudicator can
distinguish a real allowed success from a merely-intended one and confirm no
forbidden read produced content. A DENIED call does not execute, so it yields no
PostToolUse record — the asymmetry is itself evidence. Advisory only: never blocks.
"""
import os
import sys
import json
import hashlib

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import _common as C  # noqa: E402


def main():
    _raw, payload = C.read_payload()
    tool = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {}) or {}
    ident = C.extract_identity(payload)
    run_dir = C.read_run_dir()
    cwd = payload.get("cwd") or C.project_base(payload)

    resp = payload.get("tool_response")
    if resp is None:
        resp = payload.get("tool_result")
    try:
        resp_text = resp if isinstance(resp, str) else json.dumps(
            resp, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    except Exception:
        resp_text = repr(resp)
    resp_bytes = (resp_text or "").encode("utf-8", "replace")

    is_error = False
    if isinstance(resp, dict):
        is_error = bool(resp.get("is_error") or resp.get("error"))

    rec = {
        "ts": C.now_utc(),
        "hook": "posttool_evidence",
        "event": payload.get("hook_event_name", "PostToolUse"),
        "tool": tool,
        "tool_use_id": payload.get("tool_use_id") or payload.get("toolUseId"),
        "session_id": ident.get("session_id"),
        "agent_type": ident.get("agent_type"),
        "agent_id": ident.get("agent_id"),
        "cwd": payload.get("cwd"),
        "cwd_head": C.git_head(cwd),
        "input_hash": C.canonical_hash(tool_input),
        "produced_output": len(resp_bytes) > 0,
        "response_len": len(resp_bytes),
        "response_hash": "sha256:" + hashlib.sha256(resp_bytes).hexdigest(),
        "is_error": is_error,
    }
    # For a file tool, record the resolved target so the adjudicator can bind the
    # outcome to a specific path.
    if tool in C.GUARDED_FILE_TOOLS:
        paths = C.extract_paths(tool, tool_input)
        if paths:
            rec["target"] = paths[0]
    C.append_evidence(run_dir, "posttool.jsonl", rec)
    sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception:
        # Advisory hook: never block on failure.
        sys.exit(0)
