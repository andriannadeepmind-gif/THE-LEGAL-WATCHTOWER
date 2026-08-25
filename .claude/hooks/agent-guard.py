#!/usr/bin/env python3
"""AGENT-GUARD — PreToolUse hook: parent-level gate on the Agent/Task tool.
UNVERIFIED-UNTIL-FRESH-SESSION-CANARY.

Policy (deterministic, default-DENY, fail-closed):
  * ALLOW a subagent spawn ONLY when BOTH hold:
      - tool_input.subagent_type == "lane-blind-reader"  (exact), AND
      - sha256(tool_input.prompt UTF-8 bytes) == PINNED_PROMPT_SHA256.
  * DENY any other subagent_type, any prompt whose hash differs, any other tool
    reaching this matcher, a receipt-write failure, or ANY exception.

The pin is the SHA-256 of the exact bytes of
  experiment/canary/spec/canary-task-prompt.txt
so the fresh-session orchestrator must pass that file's content verbatim as the
Agent prompt; a mutated prompt is denied (safe) and surfaces as a finding.
"""
import os
import sys
import hashlib

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import _common as C  # noqa: E402

ALLOWED_SUBAGENT = "lane-blind-reader"
# Pin over the UTF-8 bytes of experiment/canary/spec/canary-task-prompt.txt.
PINNED_PROMPT_SHA256 = "sha256:bb1736a06658d6c6284a74e69e6ae0a6fca4d097733dd739546d7337b6a45521"


def main():
    raw, payload = C.read_payload()
    tool = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {}) or {}
    base = C.project_base(payload)

    subagent = tool_input.get("subagent_type")
    prompt = tool_input.get("prompt")
    prompt_sha = "sha256:" + hashlib.sha256((prompt or "").encode("utf-8")).hexdigest()

    record = {
        "ts": C.now_utc(),
        "hook": "agent-guard",
        "event": payload.get("hook_event_name", "PreToolUse"),
        "session_id": payload.get("session_id"),
        "cwd": payload.get("cwd"),
        "tool": tool,
        "requested_subagent_type": subagent,
        "expected_subagent_type": ALLOWED_SUBAGENT,
        "prompt_sha256": prompt_sha,
        "expected_prompt_sha256": PINNED_PROMPT_SHA256,
        "input_hash": C.canonical_hash(tool_input),
        "payload_hash": C.sha256_bytes(raw),
    }

    if tool not in ("Agent", "Task"):
        record["decision"] = "deny"
        record["reason"] = "unexpected-tool-on-agent-matcher"
        C.append_receipt(base, record)
        C.emit("deny", "agent-guard: unexpected tool; deny")

    if subagent != ALLOWED_SUBAGENT:
        record["decision"] = "deny"
        record["reason"] = "subagent-type-not-allowed"
        C.append_receipt(base, record)
        C.emit("deny", "agent-guard: subagent_type not the sealed canary; deny")

    if prompt_sha != PINNED_PROMPT_SHA256:
        record["decision"] = "deny"
        record["reason"] = "prompt-hash-mismatch"
        C.append_receipt(base, record)
        C.emit("deny", "agent-guard: prompt SHA-256 != pinned; deny")

    record["decision"] = "allow"
    record["reason"] = "exact-subagent-and-pinned-prompt"
    if not C.append_receipt(base, record):
        C.emit("deny", "agent-guard: receipt write failed; fail-closed deny")
    C.emit("allow", "agent-guard: exact sealed canary spawn authorized")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception:
        C.emit_deny_raw("agent-guard: exception; fail-closed deny")
