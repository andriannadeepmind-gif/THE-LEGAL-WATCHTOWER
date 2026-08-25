#!/usr/bin/env python3
"""POSTTOOL_EVIDENCE — REV3.1 PostToolUse hook (ALL tools).
UNVERIFIED-UNTIL-FRESH-SESSION-CANARY.

PreToolUse receipts prove intent/decision only. This records the ACTUAL OUTCOME of
each executed tool call, bound to the same tool_use_id, so the adjudicator can:
  * distinguish a real allowed success from a merely-intended one;
  * FAIL on ANY PostToolUse event that follows a DENIED read — a denied call does not
    execute, so any post record bound to a denied read (INCLUDING one carrying
    is_error:true) is an anomaly (repair 9);
  * scan the final Agent/Task response — a real output channel — for a forbidden decoy
    token (repair 10).  The raw response text is recorded for Agent/Task spawns and for
    Read outputs, off-repo in the run dir.

REV3.2: the ENTIRE output is scanned BEFORE any truncation (output_scan block: full
length, full SHA-256, allowed-token presence, and the FULL set of forbidden tokens
found), eliminating the truncation blind spot — a forbidden token past the storage cap
can no longer escape.  Records are appended (kind="posttool") to the single ordered,
locked, hash-chained journal.  Advisory only: never blocks.
"""
import os
import sys
import json
import hashlib

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import _common as C  # noqa: E402

MAX_RESPONSE_TEXT = 262144  # cap stored final-response text (chars)


def main():
    _raw, payload = C.read_payload()
    tool = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {}) or {}
    ident = C.extract_identity(payload)
    run_dir = C.read_run_dir()
    cwd = payload.get("cwd") or C.project_base(payload)
    topo = C.git_topology(cwd)

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
        "cwd_real": topo.get("cwd_real"),
        "cwd_head": topo.get("cwd_head"),
        "cwd_tree": topo.get("cwd_tree"),
        "git_dir": topo.get("git_dir"),
        "git_common_dir": topo.get("git_common_dir"),
        "is_linked_worktree": topo.get("is_linked_worktree"),
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
    # Record raw returned text for the channels the adjudicator must inspect by content:
    #   * Agent/Task spawn -> the final subagent response (output channel, repair 10);
    #   * Read            -> so the ALLOWED read can be verified to carry the exact
    #                        allowed decoy token, not merely a non-error output
    #                        (repair 9). Denied reads never execute, so no forbidden
    #                        content is ever stored here.
    if tool in C.AGENT_TOOLS or tool == "Read":
        full = resp_text or ""
        # Complete scan of the FULL output before truncation (REV3.2, sec.4.6).
        rec["output_scan"] = C.scan_output(full)
        # Truncated copy retained for human debugging only; the adjudicator trusts the
        # output_scan block, never this capped text.
        rec["response_text"] = full[:MAX_RESPONSE_TEXT]
        rec["response_truncated"] = len(full) > MAX_RESPONSE_TEXT

    C.append_journal(run_dir, "posttool", rec)
    sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception:
        # Advisory hook: never block on failure.
        sys.exit(0)
