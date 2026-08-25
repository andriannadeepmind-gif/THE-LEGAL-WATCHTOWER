#!/usr/bin/env python3
"""PRETOOL_GUARD — REV3 PreToolUse hook, single decision seat for ALL tools.
UNVERIFIED-UNTIL-FRESH-SESSION-CANARY.

Registered with an ALL-TOOLS matcher so Bash / Web / MCP / Write / Edit can never
pass UNRECORDED if the agent tools-allowlist fails. Three branches:

  1) Agent/Task spawn  -> gate: ALLOW only subagent_type == lane-blind-reader AND
     prompt SHA-256 == pinned. Else DENY. (Applies to every caller: this branch's
     sessions may spawn only the canary.)
  2) Caller IS the canary (agent_type == lane-blind-reader) -> STRICT lane policy:
     require non-null agent_id, a bound/matching session_id, tool == Read, and a
     path resolving to EXACTLY the one allowed inbox file. Anything else DENY.
     Fail-CLOSED: no active run dir / unloggable / any error -> DENY.
  3) Any other caller (controller/main/other) -> AUDIT (best-effort) + ALLOW.
     Fail-OPEN so the controller is never bricked; the adjudicator, not this
     branch, decides PASS and it REQUIRES canary identity to be present.

Evidence is appended to <run_dir>/pretool.jsonl in the controller-owned, absolute,
off-repo run directory (found via the ACTIVE-RUN pointer). Each record carries the
tool_use_id, identity, canonical input hash, cwd (real worktree) and its git HEAD.
"""
import os
import sys
import hashlib

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import _common as C  # noqa: E402

PINNED_PROMPT_SHA256 = "sha256:ec976e07fb8297aaea412d0602bcebbafd42fdb5be4db65e2505bc60119cce08"


def base_record(payload, tool, tool_input, ident, cwd, run_dir):
    return {
        "ts": C.now_utc(),
        "hook": "pretool_guard",
        "event": payload.get("hook_event_name", "PreToolUse"),
        "tool": tool,
        "tool_use_id": payload.get("tool_use_id") or payload.get("toolUseId"),
        "session_id": ident.get("session_id"),
        "agent_type": ident.get("agent_type"),
        "agent_id": ident.get("agent_id"),
        "cwd": payload.get("cwd"),
        "cwd_head": C.git_head(cwd),
        "input_hash": C.canonical_hash(tool_input),
        "run_dir_present": bool(run_dir),
    }


def decide(payload):
    tool = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {}) or {}
    base = C.project_base(payload)
    cwd = payload.get("cwd") or base
    ident = C.extract_identity(payload)
    run_dir = C.read_run_dir()
    rec = base_record(payload, tool, tool_input, ident, cwd, run_dir)

    # ---- branch 1: Agent/Task spawn gate ----
    if tool in C.AGENT_TOOLS:
        subagent = tool_input.get("subagent_type")
        prompt = tool_input.get("prompt")
        prompt_sha = "sha256:" + hashlib.sha256((prompt or "").encode("utf-8")).hexdigest()
        rec["requested_subagent_type"] = subagent
        rec["prompt_sha256"] = prompt_sha
        rec["expected_prompt_sha256"] = PINNED_PROMPT_SHA256
        if subagent != C.CANARY_AGENT_TYPE:
            rec["decision"] = "deny"; rec["reason"] = "subagent-type-not-allowed"
            C.append_evidence(run_dir, "pretool.jsonl", rec)
            return "deny", "pretool_guard: subagent_type not the sealed canary"
        if prompt_sha != PINNED_PROMPT_SHA256:
            rec["decision"] = "deny"; rec["reason"] = "prompt-hash-mismatch"
            C.append_evidence(run_dir, "pretool.jsonl", rec)
            return "deny", "pretool_guard: prompt SHA-256 != pinned"
        rec["decision"] = "allow"; rec["reason"] = "exact-canary-spawn"
        C.append_evidence(run_dir, "pretool.jsonl", rec)
        return "allow", "pretool_guard: exact sealed canary spawn authorized"

    # ---- branch 2: caller IS the canary -> strict, fail-closed ----
    if C.is_canary_identity(ident):
        if not run_dir:
            rec["decision"] = "deny"; rec["reason"] = "canary-without-active-run"
            return "deny", "pretool_guard: canary call with no active run dir"
        if not ident.get("agent_id"):
            rec["decision"] = "deny"; rec["reason"] = "canary-missing-agent-id"
            C.append_evidence(run_dir, "pretool.jsonl", rec)
            return "deny", "pretool_guard: canary missing stable agent_id"
        if not C.bind_session(run_dir, ident.get("session_id")):
            rec["decision"] = "deny"; rec["reason"] = "canary-session-mismatch"
            C.append_evidence(run_dir, "pretool.jsonl", rec)
            return "deny", "pretool_guard: canary session_id mismatch"
        if tool != "Read":
            rec["decision"] = "deny"; rec["reason"] = "canary-non-read-tool"
            C.append_evidence(run_dir, "pretool.jsonl", rec)
            return "deny", "pretool_guard: canary may use only Read"
        paths = C.extract_paths(tool, tool_input)
        if not paths or len(paths) != 1:
            rec["decision"] = "deny"; rec["reason"] = "canary-bad-read-shape"
            C.append_evidence(run_dir, "pretool.jsonl", rec)
            return "deny", "pretool_guard: canary Read shape invalid"
        rec["target"] = paths[0]
        if not C.is_exact_allowed_file(paths[0], cwd):
            rec["decision"] = "deny"; rec["reason"] = "canary-path-not-allowed"
            C.append_evidence(run_dir, "pretool.jsonl", rec)
            return "deny", "pretool_guard: path is not the one allowed inbox file"
        rec["decision"] = "allow"; rec["reason"] = "canary-allowed-inbox"
        if not C.append_evidence(run_dir, "pretool.jsonl", rec):
            return "deny", "pretool_guard: canary allow unloggable; fail-closed deny"
        return "allow", "pretool_guard: canary read of the one allowed inbox file"

    # ---- branch 3: non-canary -> audit + allow (fail-open) ----
    rec["decision"] = "allow"; rec["reason"] = "non-canary-audited"
    C.append_evidence(run_dir, "pretool.jsonl", rec)  # best-effort; ignore failure
    return "allow", "pretool_guard: non-canary caller audited and allowed"


def main():
    _raw, payload = C.read_payload()
    decision, reason = decide(payload)
    C.emit(decision, reason)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception:
        # Fail-closed only makes sense when we might be the canary; but we cannot
        # know identity if we crashed before parsing. Deny is the safe default for
        # a guard; the adjudicator still requires positive canary evidence to PASS.
        C.emit_deny_raw("pretool_guard: exception; fail-closed deny")
