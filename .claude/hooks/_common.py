#!/usr/bin/env python3
"""LANE-CANARY hook common library.  UNVERIFIED-UNTIL-FRESH-SESSION-CANARY.

Single seat (no duplicate code) for the deterministic, fail-closed helpers that
lane-guard.py and agent-guard.py share: payload parsing, canonical hashing,
append-only receipts and the Claude Code PreToolUse decision contract.

Design law: every code path that cannot PROVE a request is in-policy must DENY.
Stdlib only; no network; no external deps.
"""
import os
import sys
import json
import time
import hashlib

# Receipt sink lives inside the canary's own sealed area (a runtime write target,
# never inside the frozen corpus).
RECEIPT_REL = os.path.join(
    "experiment", "canary", "sealed", "receipts", "hook-receipts.jsonl"
)

# File tools this project guards, and the input key(s) carrying their path(s).
FILE_PATH_KEYS = {
    "Read": ["file_path"],
    "Write": ["file_path"],
    "Edit": ["file_path"],
    "MultiEdit": ["file_path"],
    "NotebookEdit": ["notebook_path"],
    "Glob": ["path"],
    "Grep": ["path"],
    "LS": ["path"],
}


def now_utc():
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def read_payload():
    """Return (raw_bytes, parsed_dict). A malformed payload parses to {} so the
    caller still runs its fail-closed policy rather than crashing open."""
    raw = sys.stdin.buffer.read()
    try:
        parsed = json.loads(raw.decode("utf-8"))
        if not isinstance(parsed, dict):
            parsed = {}
    except Exception:
        parsed = {}
    return raw, parsed


def canonical_hash(obj):
    try:
        s = json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    except Exception:
        s = repr(obj)
    return "sha256:" + hashlib.sha256(s.encode("utf-8")).hexdigest()


def sha256_bytes(b):
    return "sha256:" + hashlib.sha256(b).hexdigest()


def project_base(payload):
    """Resolve the repository/worktree base. Prefer the hook payload's cwd so the
    policy stays correct under isolation:worktree, then $CLAUDE_PROJECT_DIR, then
    the process cwd."""
    for c in (payload.get("cwd"), os.environ.get("CLAUDE_PROJECT_DIR"), os.getcwd()):
        if c:
            try:
                return os.path.realpath(c)
            except Exception:
                continue
    return os.path.realpath(".")


def append_receipt(base, record):
    """Append one canonical JSONL receipt. Returns True on durable success.
    For an ALLOW decision a False return MUST be treated as a reason to DENY
    (we never allow what we cannot prove we logged)."""
    try:
        p = os.path.join(base, RECEIPT_REL)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        line = json.dumps(record, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
        with open(p, "a", encoding="utf-8") as f:
            f.write(line + "\n")
            f.flush()
            os.fsync(f.fileno())
        return True
    except Exception:
        return False


def emit(decision, reason):
    """Emit the Claude Code PreToolUse decision as JSON on stdout and exit 0.
    decision in {allow, deny, ask}."""
    out = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": decision,
            "permissionDecisionReason": reason,
        }
    }
    try:
        sys.stdout.write(json.dumps(out))
        sys.stdout.flush()
    finally:
        sys.exit(0)


def emit_deny_raw(reason):
    """Last-resort deny used from a bare except where helpers may be unusable."""
    try:
        sys.stdout.write(
            '{"hookSpecificOutput":{"hookEventName":"PreToolUse",'
            '"permissionDecision":"deny","permissionDecisionReason":'
            + json.dumps(reason)
            + "}}"
        )
        sys.stdout.flush()
    except Exception:
        pass
    # Non-zero exit is itself a PreToolUse block in Claude Code: double fail-closed.
    sys.exit(2)


def extract_paths(tool_name, tool_input):
    """Candidate path strings for a guarded file tool, or None when the tool
    shape is unrecognized (the caller must DENY on None)."""
    keys = FILE_PATH_KEYS.get(tool_name)
    if keys is None:
        return None
    paths = []
    for k in keys:
        v = tool_input.get(k)
        if isinstance(v, str) and v != "":
            paths.append(v)
    # A dir-scanning tool with no explicit path defaults to cwd — still guarded.
    if not paths and tool_name in ("Glob", "Grep", "LS"):
        paths.append(".")
    if not paths:
        return None
    return paths


def within(base_allowed, candidate, cwd_base):
    """True iff `candidate` resolves strictly within `base_allowed` with no
    traversal or symlink escape. Absolute candidates are honored as given;
    relative candidates resolve against `cwd_base`. realpath collapses
    `..` and follows symlinks, so an escape lands outside and is rejected.
    Any error -> False (deny)."""
    try:
        if os.path.isabs(candidate):
            real = os.path.realpath(candidate)
        else:
            real = os.path.realpath(os.path.join(cwd_base, candidate))
        allowed = os.path.realpath(base_allowed)
        return real == allowed or real.startswith(allowed + os.sep)
    except Exception:
        return False
