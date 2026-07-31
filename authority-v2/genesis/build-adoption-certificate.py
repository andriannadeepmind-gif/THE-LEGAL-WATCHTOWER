#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""LEVEL-7 VCCT-RSM — LEGACY-ADOPTION-CERTIFICATE (sequence 0), UNSIGNED DRAFT

Συνθέτει το sequence-0 certificate από τα ΠΑΡΑΓΟΜΕΝΑ evidence (deterministic
legacy snapshot + conformance result + genesis policy). ΟΛΑ τα υποχρεωτικά
πεδία της διορθωτικής εντολής §1 παρόντα — απόν πεδίο = ΑΚΥΡΟ (fail-closed
έλεγχος εδώ ΚΑΙ στον ανεξάρτητο checker).

ΚΑΤΑΣΤΑΣΗ ΥΠΟΓΡΑΦΗΣ: unsigned-draft. Η παραγωγική υπογραφή + TSA receipt
απαιτούν την owner-root ceremony (πραγματικό ιδιωτικό κλειδί) — ΣΤΑΜΑΤΗΜΕΝΟ
fail-closed κατά την εντολή. Το test-key fixture υπογράφει ΜΟΝΟ αντίγραφο στο
fixtures namespace, ποτέ το production draft.

Wire σημείωση: το ΤΕΛΙΚΟ canonical wire είναι deterministic CBOR υπό το CDDL
schema, επικυρωμένο από EverParse (BLOCKED-TOOLCHAIN). Αυτό το JSON είναι
ΑΝΘΡΩΠΙΝΗ ΠΡΟΒΟΛΗ + σταθερή βάση hash μέχρι το EverParse gate — φέρει
canonical_encoding=PENDING-EVERPARSE ώστε να μην παγιωθεί ως δεύτερη έδρα.
"""
import hashlib
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return "sha256:" + h.hexdigest()


REQUIRED_FIELDS = [
    "source_commit", "legacy_manifest_digest", "legacy_archive_root",
    "legacy_releases", "legacy_latest_pointers", "tsa_evidence", "jws_evidence",
    "new_verifier_result", "known_divergences", "adoption_mode",
    "inherited_authority", "inherited_attestation", "genesis_policy_hash",
]


def main(argv):
    repo_root = os.path.abspath(argv[1]) if len(argv) > 1 else os.getcwd()
    out_dir = os.path.join(HERE, "out")
    snap_path = os.path.join(out_dir, "legacy-snapshot.json")
    conf_path = os.path.join(out_dir, "legacy-conformance.json")
    policy_path = os.path.join(HERE, "genesis-policy.sexp")
    for p, what in ((snap_path, "legacy snapshot"), (conf_path, "conformance"),
                    (policy_path, "genesis policy")):
        if not os.path.isfile(p):
            print("::error::ΑΠΟΝ %s (%s) — fail-closed" % (what, p))
            return 1

    with open(snap_path, encoding="utf-8") as fh:
        snap = json.load(fh)
    with open(conf_path, encoding="utf-8") as fh:
        conf = json.load(fh)

    # Πραγματικό source commit — από το git, όχι δηλωμένο.
    commit = subprocess.run(["git", "-C", repo_root, "rev-parse", "HEAD"],
                            capture_output=True, text=True, check=True).stdout.strip()

    cert = {
        "kind": "lawmax/legacy-adoption-certificate/1",
        "sequence": 0,
        "assurance_status": "under-construction",
        "signature_status": "unsigned-draft (fail-closed μέχρι owner-root ceremony)",
        "canonical_encoding": "PENDING-EVERPARSE (deterministic CBOR gate = BLOCKED-TOOLCHAIN)",
        "source_commit": commit,
        "legacy_manifest_digest": sha256_file(snap_path),
        "legacy_archive_root": snap["legacy_archive_root"],
        "legacy_file_count": snap["file_count"],
        "legacy_releases": snap["legacy_releases"],
        "legacy_latest_pointers": snap["legacy_latest_pointers"],
        "tsa_evidence": snap["tsa_evidence"],
        "jws_evidence": snap["jws_evidence"],
        "new_verifier_result": {
            "summary": conf["summary"],
            "evaluated": conf["evaluated"],
            "conforming": conf["conforming"],
            "detail_digest": sha256_file(conf_path),
        },
        "known_divergences": [
            {"id": "release-count",
             "expected": "24 legacy releases (εντολή)",
             "observed": "%d top-level releases (ντετερμινιστικός snapshot)" % len(snap["legacy_releases"]),
             "resolution": "ο ΠΡΑΓΜΑΤΙΚΟΣ αριθμός δεσμεύεται· κανένας αριθμός δεν κατασκευάζεται"},
            {"id": "canonical-wire", "status": "BLOCKED-TOOLCHAIN",
             "detail": "EverCBOR/EverCDDL/EverParse απόντα (F* ΑΠΩΝ, δίκτυο 403)"},
            {"id": "store-substrate", "status": "BLOCKED-TOOLCHAIN",
             "detail": "Perennial/GoTxn απόντα (Coq ΑΠΩΝ, δίκτυο 403)"},
        ],
        "adoption_mode": "evidence-only",
        "inherited_authority": False,
        "inherited_attestation": False,
        "inherited_conformance": False,
        "first_authoritative_sequence": 1,
        "external_quorum_status": "disabled",
        "genesis_policy_hash": sha256_file(policy_path),
    }

    missing = [f for f in REQUIRED_FIELDS if f not in cert or cert[f] is None]
    if missing:
        print("::error::ΑΚΥΡΟ certificate — απόντα υποχρεωτικά πεδία: %s" % missing)
        return 1

    out = os.path.join(out_dir, "legacy-adoption-certificate.unsigned.json")
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(json.dumps(cert, ensure_ascii=False, sort_keys=True,
                            separators=(",", ":")) + "\n")
    print("✓ sequence-0 LEGACY-ADOPTION-CERTIFICATE (unsigned draft)")
    print("  source_commit        : %s" % commit)
    print("  legacy_archive_root  : %s" % cert["legacy_archive_root"])
    print("  releases δεσμευμένα  : %d" % len(cert["legacy_releases"]))
    print("  new_verifier_result  : %s" % cert["new_verifier_result"]["summary"])
    print("  υποχρεωτικά πεδία    : %d/%d παρόντα" % (len(REQUIRED_FIELDS), len(REQUIRED_FIELDS)))
    print("→ %s" % out)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
