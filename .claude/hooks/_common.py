#!/usr/bin/env python3
"""LANE-CANARY hook common library — REV3.1.  UNVERIFIED-UNTIL-FRESH-SESSION-CANARY.

Single seat for the deterministic, fail-closed helpers shared by the REV3.1 hooks
(pretool_guard.py, posttool_evidence.py, subagent_start.py, subagent_complete.py)
and read by the controller/adjudicator tools.

REV3.1 changes vs REV3 (pre-canary repair pass — see
experiment/BLIND-AGENT-ISOLATION-REFINED.REV3.1.json):
  * Worktree topology, not just HEAD.  Every receipt now records the canonical cwd,
    the absolute git-dir, the absolute git-common-dir, whether the checkout is a
    LINKED worktree, HEAD, and the HEAD tree.  The adjudicator proves the canary ran
    in a genuinely distinct linked worktree (different cwd + different git-dir sharing
    one common-dir) at the externally-supplied expected commit AND tree — equal HEAD
    alone is no longer accepted.
  * Identity is bound trust-on-first-use as a TRIPLE: agent_type, non-null agent_id,
    and session_id.  A canary event whose identity is missing or inconsistent with the
    first bound identity is DENIED (fail-closed); it can never yield an ALLOW.
  * The identity fail-OPEN is removed.  During an active run every guarded file read
    of anything other than the ONE allowed inbox is DENIED regardless of identity;
    unrelated non-file calls are NEUTRAL (no explicit allow), never broadly allowed.
  * The evidence root is controller-owned, absolute, off-repo and run-specific, found
    via a fixed pointer file.  Its base is overridable with $LAWMAX_CANARY_HOME so the
    committed regression suite can drive the guard deterministically; the default is
    the real ~/.lawmax-canary.

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
def controller_home():
    """Base directory for canary evidence.  Overridable via $LAWMAX_CANARY_HOME so the
    committed regression fixtures can point the guard at a throwaway sink; defaults to
    the real ~/.lawmax-canary for a live run.  Single seat for this path."""
    env = os.environ.get("LAWMAX_CANARY_HOME")
    if env:
        return os.path.realpath(env)
    return os.path.join(os.path.expanduser("~"), ".lawmax-canary")


def active_run_pointer():
    return os.path.join(controller_home(), "ACTIVE-RUN")


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


def sha256_file(path):
    try:
        with open(path, "rb") as f:
            return "sha256:" + hashlib.sha256(f.read()).hexdigest()
    except Exception:
        return None


def project_base(payload):
    for c in (payload.get("cwd"), os.environ.get("CLAUDE_PROJECT_DIR"), os.getcwd()):
        if c:
            try:
                return os.path.realpath(c)
            except Exception:
                continue
    return os.path.realpath(".")


# ---- git worktree topology (repair 2: distinct checkout, not just equal HEAD) ----
def _git(cwd, *args):
    try:
        r = subprocess.run(
            ["git", "-C", cwd or ".", *args],
            capture_output=True, text=True, timeout=5,
        )
        if r.returncode == 0:
            return r.stdout.strip()
    except Exception:
        pass
    return None


def git_head(cwd):
    """Best-effort HEAD of the checkout at cwd (the real worktree). None on error."""
    return _git(cwd, "rev-parse", "HEAD")


def git_topology(cwd):
    """Canonical worktree topology used to prove the canary ran in a genuinely distinct
    linked worktree at the expected commit AND tree.  All paths are absolute realpaths
    so two checkouts can be compared without cwd ambiguity."""
    head = _git(cwd, "rev-parse", "HEAD")
    tree = _git(cwd, "rev-parse", "HEAD^{tree}")
    gd = _git(cwd, "rev-parse", "--absolute-git-dir")
    cd = _git(cwd, "rev-parse", "--git-common-dir")

    def _abs(base, p):
        if not p:
            return None
        try:
            if not os.path.isabs(p):
                p = os.path.join(base or ".", p)
            return os.path.realpath(p)
        except Exception:
            return None

    base = None
    try:
        base = os.path.realpath(cwd) if cwd else os.path.realpath(".")
    except Exception:
        base = None
    git_dir = _abs(base, gd)
    common_dir = _abs(base, cd)
    is_linked = bool(git_dir and common_dir and git_dir != common_dir)
    return {
        "cwd_real": base,
        "cwd_head": head,
        "cwd_tree": tree,
        "git_dir": git_dir,
        "git_common_dir": common_dir,
        "is_linked_worktree": is_linked,
    }


# ---- identity ----
def extract_identity(payload):
    """Pull whatever agent-identity fields the payload provides. Absent fields are
    None; the guard DENIES a canary event whose identity is missing/inconsistent, and
    the adjudicator REQUIRES the triple present and consistent for PASS, so absence can
    never yield a PASS."""
    return {
        "agent_type": payload.get("subagent_type") or payload.get("agent_type"),
        "agent_id": payload.get("agent_id") or payload.get("subagent_id"),
        "session_id": payload.get("session_id"),
    }


def is_canary_identity(ident):
    return ident.get("agent_type") == CANARY_AGENT_TYPE


# ---- run dir / evidence ----
def read_run_dir():
    """Return the active run directory (absolute) or None. The pointer must exist and
    name an existing directory; anything else -> None."""
    try:
        with open(active_run_pointer(), "r", encoding="utf-8") as f:
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


def emit_neutral():
    """No decision: exit 0 with empty stdout so the call continues through the normal
    permission flow.  Per the hooks contract, silence never *approves* a call — it only
    declines to override — so this is the 'neutral, not broadly-allowed' outcome."""
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


# ---- trust-on-first-use identity binding ----
def bind_identity(run_dir, ident):
    """TOFU-bind the canary identity TRIPLE (agent_type, agent_id, session_id) for a
    run.  The first canary event records all three; later events must match all three.
    Returns True only if every field is present (non-null) and matches the bound triple.
    Any missing field, mismatch, or error -> False (caller DENIES for a canary)."""
    try:
        if not run_dir:
            return False
        at = ident.get("agent_type")
        aid = ident.get("agent_id")
        sid = ident.get("session_id")
        if not (at and aid and sid):
            return False
        want = {"agent_type": str(at), "agent_id": str(aid), "session_id": str(sid)}
        p = os.path.join(run_dir, "identity.bind")
        payload = json.dumps(want, sort_keys=True, separators=(",", ":"))
        try:
            fd = os.open(p, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                f.write(payload)
            return True
        except FileExistsError:
            with open(p, "r", encoding="utf-8") as f:
                have = json.loads(f.read().strip() or "{}")
            return have == want
    except Exception:
        return False
