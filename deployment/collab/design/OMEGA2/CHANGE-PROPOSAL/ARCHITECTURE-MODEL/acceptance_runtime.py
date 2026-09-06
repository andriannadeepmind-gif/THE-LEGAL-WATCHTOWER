#!/usr/bin/env python3
"""acceptance_runtime.py — the ONE seat for how acceptance programs run things and hold a workspace.

The properties the acceptance battery needs, in one place (Review-3 R3-8, R3-9, R3-10, §15; Review-4 R4-2, R4-3, R4-4):

  * BOUNDED EXECUTION. Every subprocess an acceptance program starts has a deadline and is killed as a PROCESS
    GROUP, so a producer that hangs — or that leaves a hung child behind — ends as a typed TIMEOUT rather than
    as a gate that never reaches a verdict. Before this there were 35 unbounded `subprocess.run` calls across
    the three runners and not one `timeout=`.
  * TYPED TOOL FAILURE (R4-2). A pinned tool that is missing, not a regular file, not executable, a broken
    symlink, unreadable, or that vanishes between the pre-check and the spawn — ENOENT, EACCES, ENOEXEC — is a
    typed ToolUnavailable with a closed reason, never a Python traceback. The reason vocabulary is
    TOOLCHAIN-MISSING, TOOLCHAIN-UNEXECUTABLE and TOOLCHAIN-SPAWN-FAILED, and every seat program turns it into
    one printed line and a non-zero exit.
  * OWN-CHILD CLEANUP (R4-3). This seat keeps an exact registry of the children IT started; on SIGINT, SIGTERM
    or SIGHUP they are terminated as process groups and the workspace is removed. Nothing else is touched: no
    glob over a scratch root, no other execution's workspace, because a concurrent independent run may own it.
    Nothing is promised for SIGKILL, which no process can handle.
  * ONE GIT LOCK POLICY (R4-4). Every git subprocess started through this seat carries an EXPLICIT
    GIT_OPTIONAL_LOCKS=0, overriding whatever the environment inherited, so a read never creates .git/index.lock
    in the repository under audit. A hostile inherited GIT_OPTIONAL_LOCKS=1 changes nothing.
  * WORKSPACE LIFECYCLE. A private workspace is removed on success, failure, signal and timeout alike; keeping
    it is an explicit request. A scratch root inside the repository under audit is refused before any work.
  * ONE TCB MEASUREMENT. "How much machinery does acceptance trust" has exactly one definition here, used both
    by the generator that records the measurement in the model and by the gate check that re-derives it from the
    candidate tree. Its file set comes from path kind and file bytes, never from a role name, so no
    re-classification and no rename can shrink the measured base.
  * CONTENT-SENSITIVE REPOSITORY STATE. `git status --porcelain` names untracked paths but never looks inside
    them, so replacing an untracked file's contents left the old read-only measurement bit-identical. Tracked
    content is measured as the tree the current state would commit to; untracked content is hashed.
"""
import atexit, errno, hashlib, os, shutil, signal, stat, subprocess, sys, tempfile

DEFAULT_TIMEOUT = 1800
_LIVE = {}                       # pid -> Popen, exactly the children THIS process started and has not reaped


class Timeout(Exception):
    """A bounded execution that did not finish. Typed, so a hang is a verdict rather than a hang."""


class ToolUnavailable(Exception):
    """A tool that could not be executed, with a CLOSED reason. Typed, so an absent host binary is a printed
    line and a non-zero exit, never a traceback (Review-4 R4-2)."""

    def __init__(self, reason, path, detail):
        Exception.__init__(self, '%s: %s — %s' % (reason, path, detail))
        self.reason = reason


def tool_defect(path):
    """The typed reason PATH cannot be executed, or None. Checked before a spawn; the spawn checks again."""
    if not os.path.lexists(path):
        return 'TOOLCHAIN-MISSING', 'the path does not exist'
    if not os.path.exists(path):
        return 'TOOLCHAIN-MISSING', 'the path is a symbolic link whose target does not exist'
    if not stat.S_ISREG(os.stat(path).st_mode):
        return 'TOOLCHAIN-UNEXECUTABLE', 'the path is not a regular file'
    if not os.access(path, os.X_OK | os.R_OK):
        return 'TOOLCHAIN-UNEXECUTABLE', 'the file is not readable and executable by this process'
    return None


def git_env(**extra):
    """The environment of EVERY git subprocess: GIT_OPTIONAL_LOCKS forced to 0, whatever was inherited."""
    env = dict(os.environ, **extra)
    env['GIT_OPTIONAL_LOCKS'] = '0'
    return env


def bounded_run(cmd, timeout=DEFAULT_TIMEOUT, **kw):
    """Run CMD in its own process group with a deadline; on expiry kill the whole group and raise Timeout."""
    # Semantics are subprocess.run's, deliberately: a bounded call must be a drop-in for the call it replaces,
    # or the conversion silently changes bytes into str at 50 call sites.
    kw.setdefault('capture_output', True)
    data = kw.pop('input', None)
    if data is not None:
        kw['stdin'] = subprocess.PIPE
    if os.path.basename(str(cmd[0])) == 'git':
        kw['env'] = git_env(**{k: v for k, v in kw.get('env', os.environ).items() if k != 'GIT_OPTIONAL_LOCKS'})
    try:
        # CLOSURE-DELEGATED: cmd is this function's own parameter; every caller's argument is analysed there
        proc = subprocess.Popen(cmd, start_new_session=True, **_popen_kw(kw))
    except OSError as e:
        raise ToolUnavailable(_spawn_reason(e), cmd[0], '%s (%s)' % (e.strerror, errno.errorcode.get(e.errno, e.errno)))
    _LIVE[proc.pid] = proc
    try:
        out, err = proc.communicate(data, timeout=timeout)
    except subprocess.TimeoutExpired:
        _kill_group(proc)
        proc.communicate()
        raise Timeout('TIMEOUT: %s exceeded %ss and its process group was terminated'
                      % (' '.join(str(c) for c in cmd)[:120], timeout))
    finally:
        _LIVE.pop(proc.pid, None)
    return subprocess.CompletedProcess(cmd, proc.returncode, out, err)


def _spawn_reason(e):
    if e.errno == errno.ENOENT:
        return 'TOOLCHAIN-MISSING'
    if e.errno in (errno.EACCES, errno.EPERM, errno.ENOEXEC, errno.EISDIR):
        return 'TOOLCHAIN-UNEXECUTABLE'
    return 'TOOLCHAIN-SPAWN-FAILED'


def terminate_children():
    """Terminate, as process groups, exactly the children this process started and still owns."""
    for proc in list(_LIVE.values()):
        _kill_group(proc)


def _popen_kw(kw):
    kw = dict(kw)
    if kw.pop('capture_output', False):
        kw.setdefault('stdout', subprocess.PIPE); kw.setdefault('stderr', subprocess.PIPE)
    if kw.pop('text', False):
        kw['universal_newlines'] = True
    kw.pop('check', None)
    return kw


def checked(cmd, **kw):
    """bounded_run that raises on a non-zero exit, the way subprocess.run(check=True) does."""
    r = bounded_run(cmd, **kw)
    if r.returncode != 0:
        raise subprocess.CalledProcessError(r.returncode, cmd, r.stdout, r.stderr)
    return r


def _kill_group(proc):
    for sig in (signal.SIGTERM, signal.SIGKILL):
        try:
            os.killpg(os.getpgid(proc.pid), sig)
        except (ProcessLookupError, PermissionError):
            return
        try:
            proc.wait(timeout=5)
            return
        except subprocess.TimeoutExpired:
            continue


def _delegated(_marker='CLOSURE-DELEGATED'):
    """Marker anchor: the path this seat executes is its caller's argument, analysed at the caller's own site."""


def refuse_hostile_tmpdir(repo):
    tmp = os.path.realpath(tempfile.gettempdir())
    if tmp == os.path.realpath(repo) or tmp.startswith(os.path.realpath(repo) + os.sep):
        raise SystemExit('HOSTILE-TMPDIR: the scratch root %s is inside the repository under audit' % tmp)


def _on_signal(*_):
    terminate_children()
    sys.exit(130)


def workspace(prefix, repo, keep=False, reuse=None):
    """A private workspace that is cleaned up unless KEEP, on every exit path including a catchable signal.

    On SIGINT, SIGTERM and SIGHUP the children this process started are terminated as process groups first,
    then the interpreter exits and the atexit hook removes THIS workspace — never any other."""
    refuse_hostile_tmpdir(repo)
    for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, _on_signal)
    if reuse:
        os.makedirs(reuse, exist_ok=True)
        return reuse
    d = tempfile.mkdtemp(prefix=prefix)
    if not keep:
        atexit.register(shutil.rmtree, d, True)
    return d


def git_object_dir(repo):
    """The COMMON object store.

    A linked worktree has its own git directory and NO objects directory of its own: the objects live in the
    common directory the worktree points at. Deriving the store from the per-worktree git dir produced an
    alternates path that does not exist, and three falsifiers then died of "failed to unpack tree object"
    instead of testing anything. The common directory is what holds objects, in a worktree and outside one."""
    return os.path.join(_rev_parse(repo, '--git-common-dir'), 'objects')


def _rev_parse(repo, what):
    return checked(['git', '-C', repo, 'rev-parse', '--path-format=absolute', what], text=True,
                   timeout=120).stdout.strip()


def repo_content_state(repo, worktree_tree):
    """A content hash of everything in REPO this run could disturb: the tracked tree plus untracked bytes."""
    others = bounded_run(['git', '-C', repo, 'ls-files', '--others', '--exclude-standard'], text=True,
                         timeout=600).stdout.splitlines()
    parts = [worktree_tree]
    for rel in sorted(p for p in others if p.strip()):
        try:
            with open(os.path.join(repo, rel), 'rb') as f:
                parts.append('%s %s' % (rel, hashlib.sha256(f.read()).hexdigest()))
        except OSError as e:
            parts.append('%s UNREADABLE %s' % (rel, e.__class__.__name__))
    return hashlib.sha256('\n'.join(parts).encode('utf-8')).hexdigest()


# ─────────────────────────────────────────────────────────── the acceptance TCB measurement (Review-3 §15)
# The one counting rule, stated once and implemented once: TCB-BASELINE-RECONCILIATION.md §1. Physical lines are
# the UTF-8 text split on newline with one trailing empty element dropped; NBNC lines are those whose stripped
# form is non-empty and does not begin with the kind's line-comment marker. Nothing else is excluded — not
# docstrings, not shebangs, not closing brackets — and packing lines to lower the number is a defect, not a fix.
TCB_MARKER = {'.py': '#', '.sh': '#', '.lisp': ';', '.lp': '%'}


def tcb_marker(path):
    return TCB_MARKER.get(os.path.splitext(path)[1])


def is_tcb_file(path, blob):
    """Membership in the acceptance base: a declared executable kind, or an explicit interpreter line."""
    return tcb_marker(path) is not None or blob[:2] == b'#!'


def count_lines(blob, marker):
    """(physical, nbnc) for one file under the single counting rule."""
    lines = blob.decode('utf-8').split('\n')
    if lines and lines[-1] == '':
        lines.pop()
    return len(lines), sum(1 for line in lines
                           if line.strip() and not (marker and line.strip().startswith(marker)))


def tcb_measure(blobs):
    """[(path, physical, nbnc)] sorted by path, over exactly those BLOBS that are acceptance machinery."""
    rows = []
    for path in sorted(blobs):
        blob = blobs[path]
        if is_tcb_file(path, blob):
            physical, nbnc = count_lines(blob, tcb_marker(path))
            rows.append((path, physical, nbnc))
    return rows
