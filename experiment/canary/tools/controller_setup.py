#!/usr/bin/env python3
"""CONTROLLER_SETUP — REV3 canary run bootstrap (controller-owned).
UNVERIFIED-UNTIL-FRESH-SESSION-CANARY.

Creates the absolute, off-repo, run-specific evidence directory the hooks write to,
with a random run_id and EXCLUSIVE creation, and refuses if a run is already active
(a stale pointer or dir ⇒ hard error, never reuse). Run this in the fresh session
BEFORE spawning the canary.

  python3 experiment/canary/tools/controller_setup.py setup   # create run + pointer
  python3 experiment/canary/tools/controller_setup.py teardown # remove pointer only

Evidence root:  ~/.lawmax-canary/
Pointer file:   ~/.lawmax-canary/ACTIVE-RUN   (contains the absolute run dir)
Run dir:        ~/.lawmax-canary/run-<random>/ (created 0700, exclusive)
"""
import os
import sys
import json
import time
import secrets
import subprocess

HOME_DIR = os.path.join(os.path.expanduser("~"), ".lawmax-canary")
POINTER = os.path.join(HOME_DIR, "ACTIVE-RUN")
PROMPT_REL = os.path.join("experiment", "canary", "spec", "canary-task-prompt.txt")


def git_head():
    try:
        r = subprocess.run(["git", "rev-parse", "HEAD"], capture_output=True, text=True, timeout=5)
        if r.returncode == 0:
            return r.stdout.strip()
    except Exception:
        pass
    return None


def prompt_pin():
    try:
        import hashlib
        with open(PROMPT_REL, "rb") as f:
            return "sha256:" + hashlib.sha256(f.read()).hexdigest()
    except Exception:
        return None


def setup():
    os.makedirs(HOME_DIR, exist_ok=True)
    # Refuse if a run is already active: pointer present ⇒ stale/concurrent run.
    if os.path.exists(POINTER):
        sys.stderr.write(
            "REFUSING: an active run pointer already exists at %s. "
            "Adjudicate and teardown the previous run first.\n" % POINTER
        )
        sys.exit(2)
    run_id = secrets.token_hex(16)
    run_dir = os.path.join(HOME_DIR, "run-" + run_id)
    # Exclusive creation: error if the dir somehow exists.
    os.makedirs(run_dir, mode=0o700, exist_ok=False)
    manifest = {
        "run_id": run_id,
        "created": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "expected_head": git_head(),
        "prompt_pin": prompt_pin(),
        "cwd": os.path.realpath("."),
        "note": "UNVERIFIED-UNTIL-FRESH-SESSION-CANARY",
    }
    with open(os.path.join(run_dir, "run-manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, sort_keys=True, indent=1)
    # Pointer: exclusive create so two setups cannot both claim the active run.
    fd = os.open(POINTER, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write(run_dir)
    print(json.dumps({"run_dir": run_dir, "run_id": run_id,
                      "expected_head": manifest["expected_head"],
                      "prompt_pin": manifest["prompt_pin"]}))


def teardown():
    # Remove only the pointer; keep the run dir + receipts as durable evidence.
    try:
        os.remove(POINTER)
        print("pointer removed")
    except FileNotFoundError:
        print("no active pointer")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "setup"
    if cmd == "setup":
        setup()
    elif cmd == "teardown":
        teardown()
    else:
        sys.stderr.write("usage: controller_setup.py [setup|teardown]\n")
        sys.exit(2)
