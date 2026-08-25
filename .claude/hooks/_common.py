#!/usr/bin/env python3
"""LANE-CANARY hook common library — REV3.  UNVERIFIED-UNTIL-FRESH-SESSION-CANARY.

Single seat for the deterministic, fail-closed helpers shared by the REV3 hooks
(pretool_guard.py, posttool_evidence.py, subagent_complete.py) and read by the
controller/adjudicator tools.

REV3 changes vs REV1/REV2:
  * Receipts live in a CONTROLLER-OWNED, ABSOLUTE, run-specific directory OUTSIDE
    the repository and outside any lane-readable root, found via a fixed pointer
    file.  Parent and subagent run in DIFFERENT checkouts (worktree isolation), so
    a repo-relative receipt path would split the evidence — this removes that bug.
  * Enforcement is IDENTITY-GATED: the strict lane policy applies ONLY to the
    lane-blind-reader canary; every other caller is AUDITED and allowed
    (fail-OPEN for non-canary so the controller is never bricked; fail-CLOSED for
    the canary so a secret is never reachable).
  * The lane capability may read ONLY the ONE exact allowed inbox file — not the
    whole sealed/ tree, and not receipts/verdict (which now live off-repo).
  * cwd (real worktree path) and its git HEAD are captured on every receipt so the
    adjudicator can prove the subagent ran in a worktree whose HEAD == run HEAD.

Stdlib only; no network; no third-party deps.
"""
import os
import sys
import json
import time
import hashlib
import subprocess

# ---- identity of the sealed capability ----
CANARY_AGENT_TYPE = "lane-blind-reader"

# The ONE file the lane capability may read (repo-relative; resolved per cwd).
ALLOWED_FILE_REL = os.path.join(
    "experiment", "canary", "sealed", "inbox", "LANE-INBOX.txt"
)

# ---- controller-owned evidence root (absolute, off-repo, non-lane-readable) ----
CONTROLLER_HOME = os.path.join(os.path.expanduser("~"), ".lawmax-canary")
ACTIVE_RUN_POINTER = os.path.join(CONTROLLER_HOME, "ACTIVE-RUN")

# ---- file tools this project guards, and the input key(s) carrying their path ----
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
GUARDED_FILE_TOOLS = set(FILE_PATH_KEYS.keys())
AGENT_TOOLS = {"Agent", "Task"}


def now_utc():
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def read_payload():
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
    for c in (payload.get("cwd"), os.environ.get("CLAUDE_PROJECT_DIR"), os.getcwd()):
        if c:
            try:
                return os.path.realpath(c)
            except Exception:
                continue
    return os.path.realpath(".")


def git_head(cwd):
    """Best-effort HEAD of the checkout at cwd (the real worktree). None on error."""
    try:
        r = subprocess.run(
            ["git", "-C", cwd or ".", "rev-parse", "HEAD"],
            capture_output=True, text=True, timeout=5,
        )
        if r.returncode == 0:
            return r.stdout.strip()
    except Exception:
        pass
    return None


# ---- identity ----
def extract_identity(payload):
    """Pull whatever agent-identity fields the payload provides. Absent fields are
    None; the adjudicator REQUIRES them present and consistent for PASS, so their
    absence can never yield a PASS."""
    return {
        "agent_type": payload.get("subagent_type") or payload.get("agent_type"),
        "agent_id": payload.get("agent_id") or payload.get("subagent_id"),
        "session_id": payload.get("session_id"),
    }


def is_canary_identity(ident):
    return ident.get("agent_type") == CANARY_AGENT_TYPE


# ---- run dir / evidence ----
def read_run_dir():
    """Return the active run directory (absolute) or None. The pointer must exist,
    name an existing directory; anything else -> None."""
    try:
        with open(ACTIVE_RUN_POINTER, "r", encoding="utf-8") as f:
            d = f.read().strip()
        if d and os.path.isdir(d):
            return d
    except Exception:
        pass
    return None


def append_evidence(run_dir, filename, record):
    """Append one canonical JSONL record to <run_dir>/<filename>. Returns True on
    durable success. Never raises."""
    try:
        if not run_dir:
            return False
        p = os.path.join(run_dir, filename)
        line = json.dumps(record, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
        # Exclusive-append; create if missing.
        with open(p, "a", encoding="utf-8") as f:
            f.write(line + "\n")
            f.flush()
            os.fsync(f.fileno())
        return True
    except Exception:
        return False


# ---- decision emit ----
def emit(decision, reason):
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
    try:
        sys.stdout.write(
            '{"hookSpecificOutput":{"hookEventName":"PreToolUse",'
            '"permissionDecision":"deny","permissionDecisionReason":'
            + json.dumps(reason) + "}}"
        )
        sys.stdout.flush()
    except Exception:
        pass
    sys.exit(2)


# ---- path policy ----
def extract_paths(tool_name, tool_input):
    keys = FILE_PATH_KEYS.get(tool_name)
    if keys is None:
        return None
    paths = []
    for k in keys:
        v = tool_input.get(k)
        if isinstance(v, str) and v != "":
            paths.append(v)
    if not paths and tool_name in ("Glob", "Grep", "LS"):
        paths.append(".")
    if not paths:
        return None
    return paths


def real_of(candidate, cwd_base):
    try:
        if os.path.isabs(candidate):
            return os.path.realpath(candidate)
        return os.path.realpath(os.path.join(cwd_base, candidate))
    except Exception:
        return None


def is_exact_allowed_file(candidate, cwd_base):
    """True iff candidate resolves to EXACTLY the one allowed inbox file (after
    symlink/.. resolution). Prefix matches, receipts, verdict, other sealed files
    are all rejected."""
    real = real_of(candidate, cwd_base)
    if real is None:
        return False
    allowed = os.path.realpath(os.path.join(cwd_base, ALLOWED_FILE_REL))
    return real == allowed


def bind_session(run_dir, session_id):
    """Trust-on-first-use session binding for a run: first canary event records the
    session_id; later events must match it. Returns True if bound/matching, False
    on mismatch or any error (caller DENIES on False for a canary)."""
    try:
        if not run_dir or not session_id:
            return False
        p = os.path.join(run_dir, "session.bind")
        if os.path.exists(p):
            with open(p, "r", encoding="utf-8") as f:
                return f.read().strip() == str(session_id)
        # Exclusive create; if we lose a race, re-read and compare.
        try:
            fd = os.open(p, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                f.write(str(session_id))
            return True
        except FileExistsError:
            with open(p, "r", encoding="utf-8") as f:
                return f.read().strip() == str(session_id)
    except Exception:
        return False
