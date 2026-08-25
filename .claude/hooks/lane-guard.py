#!/usr/bin/env python3
"""LANE-GUARD — PreToolUse hook: file-tool path sandbox for the sealed canary.
UNVERIFIED-UNTIL-FRESH-SESSION-CANARY.

Policy (deterministic, default-DENY, fail-closed):
  * Applies to every guarded file tool (Read/Write/Edit/MultiEdit/NotebookEdit/
    Glob/Grep/LS).
  * ALLOW only when EVERY target path resolves strictly within the canary's own
    sealed area  <base>/experiment/canary/sealed  (inbox + receipts + verdict).
  * DENY everything else: other lanes, .git, /root/.claude, /proc, env, absolute
    escapes, `..` traversal and symlink escape (realpath is resolved before the
    containment test).
  * Unrecognized tool shape, missing path, receipt-write failure, or ANY
    exception -> DENY.

Note on scope: this hook contains any file-tool call, orchestrator or subagent
alike. In the dedicated canary session that is the intended, strictly-stronger
behavior — the session runs only the canary. Whether Claude Code delivers the
subagent's calls to this hook at all is exactly what the fresh-session canary
verifies; a hook that never fires yields FAIL, never PASS.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import _common as C  # noqa: E402

SEALED_REL = os.path.join("experiment", "canary", "sealed")
GUARDED = set(C.FILE_PATH_KEYS.keys())


def main():
    raw, payload = C.read_payload()
    tool = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {}) or {}
    base = C.project_base(payload)
    sealed_root = os.path.join(base, SEALED_REL)
    cwd_base = payload.get("cwd") or base

    record = {
        "ts": C.now_utc(),
        "hook": "lane-guard",
        "event": payload.get("hook_event_name", "PreToolUse"),
        "session_id": payload.get("session_id"),
        "cwd": payload.get("cwd"),
        # Any subagent-identifying fields the payload happens to carry are logged
        # verbatim so the canary can report whether subagent scoping is possible.
        "agent_type": payload.get("subagent_type") or payload.get("agent_type"),
        "agent_id": payload.get("agent_id") or payload.get("subagent_id"),
        "tool": tool,
        "input_hash": C.canonical_hash(tool_input),
        "payload_hash": C.sha256_bytes(raw),
        "sealed_root": sealed_root,
    }

    if tool not in GUARDED:
        record["decision"] = "deny"
        record["reason"] = "unexpected-non-file-tool-on-file-matcher"
        C.append_receipt(base, record)
        C.emit("deny", "lane-guard: unexpected non-file tool; deny")

    paths = C.extract_paths(tool, tool_input)
    if paths is None:
        record["decision"] = "deny"
        record["reason"] = "unrecognized-tool-shape"
        C.append_receipt(base, record)
        C.emit("deny", "lane-guard: unrecognized tool shape; deny")

    resolved = []
    all_within = True
    for p in paths:
        w = C.within(sealed_root, p, cwd_base)
        resolved.append({"path": p, "within_sealed": w})
        if not w:
            all_within = False
    record["targets"] = resolved

    if all_within:
        record["decision"] = "allow"
        record["reason"] = "within-sealed-area"
        if not C.append_receipt(base, record):
            # Cannot prove/log an allow -> fail closed.
            C.emit("deny", "lane-guard: receipt write failed; fail-closed deny")
        C.emit("allow", "lane-guard: target within sealed area")
    else:
        record["decision"] = "deny"
        record["reason"] = "outside-sealed-area"
        C.append_receipt(base, record)
        C.emit("deny", "lane-guard: target outside sealed area; deny")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception:
        C.emit_deny_raw("lane-guard: exception; fail-closed deny")
