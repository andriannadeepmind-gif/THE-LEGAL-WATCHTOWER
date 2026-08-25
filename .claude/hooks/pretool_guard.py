#!/usr/bin/env python3
"""PRETOOL_GUARD — REV3.1 PreToolUse hook, single decision seat for ALL tools.
UNVERIFIED-UNTIL-FRESH-SESSION-CANARY.

Registered with an ALL-TOOLS matcher so Bash / Web / MCP / Write / Edit can never
pass UNRECORDED if the agent tools-allowlist fails. Three branches:

  1) Agent/Task spawn  -> gate: ALLOW only subagent_type == lane-blind-reader AND
     prompt SHA-256 == pinned. Else DENY. (Applies to every caller: this branch's
     sessions may spawn only the canary.)
  2) Caller IS the canary (agent_type == lane-blind-reader) -> STRICT lane policy,
     FAIL-CLOSED: require an active run dir, the bound identity triple
     (agent_type + non-null agent_id + session_id), tool == Read, and a path
     resolving to EXACTLY the one allowed inbox file. Anything else DENY.
  3) Any OTHER caller during an active run -> the identity fail-OPEN is REMOVED:
     * a guarded file read of anything but the one allowed inbox is DENIED regardless
       of identity (a protected forbidden target is never reachable while a canary
       run is active, even by an identity-less or mislabeled caller);
     * a guarded file read of exactly the allowed inbox by a non-canary is NEUTRAL
       (only the bound canary is positively allowed);
     * every other call (the controller's own Bash/python, etc.) is NEUTRAL — audited
       but never broadly, explicitly allowed.
     With no active run the guard is dormant for non-canary callers (NEUTRAL).

Evidence is appended to <run_dir>/pretool.jsonl in the controller-owned, absolute,
off-repo run directory (found via the ACTIVE-RUN pointer). Each record carries the
tool_use_id, identity triple, canonical input hash, and full worktree topology
(cwd, git-dir, git-common-dir, linked-worktree flag, HEAD, tree).
"""
import os
import sys
import hashlib

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import _common as C  # noqa: E402

# Pinned SHA-256 of experiment/canary/spec/canary-task-prompt.txt (exact bytes).
PINNED_PROMPT_SHA256 = "sha256:f9831b6c62a5bdeeb4d9990dc6d77d9222bed04de052ac2dc533bafb99d61146"


def base_record(payload, tool, tool_input, ident, cwd, run_dir):
    topo = C.git_topology(cwd)
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
        "cwd_real": topo.get("cwd_real"),
        "cwd_head": topo.get("cwd_head"),
        "cwd_tree": topo.get("cwd_tree"),
        "git_dir": topo.get("git_dir"),
        "git_common_dir": topo.get("git_common_dir"),
        "is_linked_worktree": topo.get("is_linked_worktree"),
        "input_hash": C.canonical_hash(tool_input),
        "run_dir_present": bool(run_dir),
    }


def decide(payload):
    """Returns (action, reason) where action in {'allow','deny','neutral'}."""
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
        if not C.bind_identity(run_dir, ident):
            rec["decision"] = "deny"; rec["reason"] = "canary-identity-unbound-or-mismatch"
            C.append_evidence(run_dir, "pretool.jsonl", rec)
            return "deny", "pretool_guard: canary identity triple unbound/mismatched"
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

    # ---- branch 3: any other caller (identity fail-open REMOVED) ----
    if not run_dir:
        # No active canary run: nothing to protect; do not rubber-stamp.
        rec["decision"] = "neutral"; rec["reason"] = "no-active-run-neutral"
        return "neutral", ""

    if tool in C.GUARDED_FILE_TOOLS:
        paths = C.extract_paths(tool, tool_input) or []
        rec["target"] = paths[0] if paths else None
        # Any guarded file path that is not EXACTLY the one allowed inbox is a
        # protected forbidden target while a run is active -> DENY, any identity.
        if paths and all(C.is_exact_allowed_file(p, cwd) for p in paths):
            rec["decision"] = "neutral"; rec["reason"] = "non-canary-inbox-neutral"
            C.append_evidence(run_dir, "pretool.jsonl", rec)
            return "neutral", ""
        rec["decision"] = "deny"; rec["reason"] = "protected-forbidden-any-identity"
        C.append_evidence(run_dir, "pretool.jsonl", rec)
        return "deny", "pretool_guard: protected forbidden target denied for any identity during active run"

    # Non-file tool during an active run (controller Bash/python, etc.): neutral+audit.
    rec["decision"] = "neutral"; rec["reason"] = "non-canary-nonfile-neutral"
    C.append_evidence(run_dir, "pretool.jsonl", rec)
    return "neutral", ""


def main():
    _raw, payload = C.read_payload()
    action, reason = decide(payload)
    if action == "neutral":
        C.emit_neutral()
    else:
        C.emit(action, reason)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception:
        # We cannot know identity if we crashed before parsing; DENY is the safe default
        # for a guard (a canary forbidden read must never fall open on a crash). The
        # adjudicator still requires positive canary evidence to PASS, so a crash-denied
        # run scores INCONCLUSIVE, never PASS.
        C.emit_deny_raw("pretool_guard: exception; fail-closed deny")
