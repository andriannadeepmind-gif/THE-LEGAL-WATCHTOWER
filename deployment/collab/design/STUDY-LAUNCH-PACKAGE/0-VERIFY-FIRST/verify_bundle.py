#!/usr/bin/env python3
"""Verify the outer pre-Phase-2 freeze and both role-separated capsules.

This establishes transport integrity, inventory and capsule commitment only.
It is not a mathematical optimality proof.
"""
from __future__ import annotations

import hashlib
import json
import os
import stat
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
MANIFEST = "PRE-PHASE-2-FREEZE-MANIFEST.json"
OUTER_SEAL = "OUTER-SEAL.json"
BLIND = "PHASE-2-BLIND-PRODUCER-INPUT.zip"
REVIEWER = "PHASE-2-REVIEWER-FROZEN-GATES.zip"
VERSION = "2.3.0-R3-PRE-PHASE-2-FROZEN-CANDIDATE"
FINAL_STATUS = "FINAL_B0_SUCCESSOR_GREATEST_ELEMENT_AND_STRICT_ALL_AXIS_COMMERCIAL_SUPERIORITY_VERIFIED_UNDER_HASHED_TCB"
EXPECTED_ROOT = {
    "CREATOR-APPROVAL-RECEIPT-TEMPLATE.json",
    "PHASE-2-BLIND-PRODUCER-INPUT.zip",
    "PHASE-2-REVIEWER-FROZEN-GATES.zip",
    "PRE-PHASE-2-FREEZE-MANIFEST.json",
    "README-FIRST.md",
    "verify_bundle.py",
}
EXPECTED_BLIND = {
    "ALL-AXIS-DOMINANCE-SPEC.json",
    "COMMERCIAL-FRONTIER-BASELINES.json",
    "PHASE-2-ANSWER-NEUTRAL-ACCEPTANCE-SPEC.json",
    "PHASE-2-ISOLATION-POLICY.json",
    "PHASE-2-OUTPUT-CONTRACT.json",
    "REVIEWER-CAPSULE-COMMITMENT.json",
    "START-FRESH-PHASE-2.md",
    "UNIVERSAL-ESCALATION-PROTOCOL.json",
}
EXPECTED_REVIEWER = {
    "ALL-AXIS-DOMINANCE-SPEC.json",
    "B0-TRANSFORMATION-AND-REPOSITORY-DELTA-SPEC.json",
    "B7-PRODUCER-SESSION-EVIDENCE-RECOVERY.md",
    "COMMERCIAL-FRONTIER-BASELINES.json",
    "COORDINATOR-LAUNCH-POLICY.json",
    "NEGATIVE-CONTROLS.json",
    "PHASE-2-ANSWER-NEUTRAL-ACCEPTANCE-SPEC.json",
    "PHASE-2-ISOLATION-POLICY.json",
    "PHASE-2-OUTPUT-CONTRACT.json",
    "PROOF-OBLIGATIONS.jsonl",
    "PROOF-OF-CEILING-CONTRACT.json",
    "PROOF-OF-CEILING-CONTRACT.md",
    "REVIEW-RUNBOOK.md",
    "ROLE-SEPARATION.json",
    "UNIVERSAL-ESCALATION-PROTOCOL.json",
    "verify_freeze.mjs",
    "verify_freeze.py",
}


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def load(name: str):
    with open(os.path.join(HERE, name), encoding="utf-8") as handle:
        return json.load(handle)


def safe_zip(path: str) -> list[str]:
    problems = []
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        if names != sorted(names):
            problems.append(os.path.basename(path) + ": entries not sorted")
        if len(names) != len(set(names)):
            problems.append(os.path.basename(path) + ": duplicate entries")
        for info in archive.infolist():
            name = info.filename.replace("\\", "/")
            parts = [p for p in name.split("/") if p]
            if name.startswith("/") or any(p == ".." for p in parts) or (len(name) >= 2 and name[1] == ":"):
                problems.append(os.path.basename(path) + ": unsafe path " + name)
            mode = (info.external_attr >> 16) & 0o170000
            if mode == stat.S_IFLNK:
                problems.append(os.path.basename(path) + ": symlink " + name)
            if info.date_time != (1980, 1, 1, 0, 0, 0):
                problems.append(os.path.basename(path) + ": nonfixed timestamp " + name)
        bad = archive.testzip()
        if bad:
            problems.append(os.path.basename(path) + ": CRC failure " + bad)
    return problems


def verify_inner(path: str, seal_name: str, inventory_key: str, expected: set[str]) -> list[str]:
    problems = safe_zip(path)
    with zipfile.ZipFile(path) as archive:
        names = set(archive.namelist())
        if seal_name not in names:
            return problems + [os.path.basename(path) + ": missing " + seal_name]
        seal = json.loads(archive.read(seal_name))
        inventory = {row["file"]: row for row in seal[inventory_key]}
        actual = names - {seal_name}
        if actual != expected:
            problems.append(os.path.basename(path) + ": required file set mismatch")
        if set(inventory) != actual:
            problems.append(os.path.basename(path) + ": seal inventory mismatch")
        for name, row in inventory.items():
            if name not in names:
                continue
            data = archive.read(name)
            if len(data) != row["byte_length"] or sha(data) != row["sha256"]:
                problems.append(os.path.basename(path) + ": inner hash mismatch " + name)
    return problems


def main() -> int:
    problems = []
    manifest = load(MANIFEST)
    seal = load(OUTER_SEAL) if os.path.exists(os.path.join(HERE, OUTER_SEAL)) else None
    actual = {name for name in os.listdir(HERE) if os.path.isfile(os.path.join(HERE, name)) and name != OUTER_SEAL}
    if actual != EXPECTED_ROOT:
        problems.append("outer file set mismatch")
    if manifest.get("version") != VERSION:
        problems.append("manifest version mismatch")
    if manifest.get("repository_writes") != 0 or manifest.get("phase_3_started") is not False:
        problems.append("manifest phase/repository state")
    if manifest.get("permitted_final_status") != FINAL_STATUS:
        problems.append("manifest final status")
    entries = {row["file"]: row for row in manifest.get("capsules", [])}
    for name in (BLIND, REVIEWER):
        path = os.path.join(HERE, name)
        if not os.path.isfile(path) or name not in entries:
            problems.append("missing capsule " + name)
            continue
        data = open(path, "rb").read()
        row = entries[name]
        if len(data) != row["byte_length"] or sha(data) != row["sha256"]:
            problems.append("capsule binding mismatch " + name)
    if seal is None:
        problems.append("OUTER-SEAL.json missing")
    else:
        if seal.get("version") != VERSION:
            problems.append("outer seal version")
        sealed = {row["file"]: row for row in seal.get("sealed_files", [])}
        if set(sealed) != actual:
            problems.append("outer seal inventory mismatch")
        for name, row in sealed.items():
            path = os.path.join(HERE, name)
            if not os.path.isfile(path):
                continue
            data = open(path, "rb").read()
            if len(data) != row["byte_length"] or sha(data) != row["sha256"]:
                problems.append("outer hash mismatch " + name)
    problems.extend(verify_inner(os.path.join(HERE, BLIND), "BLIND-INPUT-SEAL.json", "files", EXPECTED_BLIND))
    problems.extend(verify_inner(os.path.join(HERE, REVIEWER), "REVIEWER-SEAL.json", "sealed_files", EXPECTED_REVIEWER))
    with zipfile.ZipFile(os.path.join(HERE, BLIND)) as blind_zip:
        commitment = json.loads(blind_zip.read("REVIEWER-CAPSULE-COMMITMENT.json"))
        reviewer_bytes = open(os.path.join(HERE, REVIEWER), "rb").read()
        if commitment.get("byte_length") != len(reviewer_bytes) or commitment.get("sha256") != sha(reviewer_bytes):
            problems.append("blind reviewer commitment mismatch")
    if problems:
        print("OUTER_FREEZE_INVALID")
        for problem in problems:
            print("  -", problem)
        return 1
    print("OUTER_FREEZE_VALID")
    print("BLIND_CAPSULE_SHA256=" + entries[BLIND]["sha256"])
    print("REVIEWER_CAPSULE_SHA256=" + entries[REVIEWER]["sha256"])
    print("RULE=UNIVERSAL_PROOF_ONLY")
    print("COMMERCIAL_RULE=EVERY_PRODUCT_EVERY_AXIS_STRICTLY_BETTER")
    print("B0_RULE=EXACT_VERIFIED_REPOSITORY_TRANSFORMATION")
    print("CURRENT=FINAL_OPTIMALITY_BLOCKED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
