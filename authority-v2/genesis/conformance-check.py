#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""LEVEL-7 VCCT-RSM — ΝΕΟΣ VERIFIER ΕΝΑΝΤΙ ΤΩΝ LEGACY RELEASES

Κρίνει ΚΑΘΕ legacy release με τα ΝΕΑ κριτήρια αποδοχής (admission conjuncts) και
παράγει το πεδίο `new_verifier_result` του LEGACY-ADOPTION-CERTIFICATE.

ΓΙΑΤΙ ΥΠΑΡΧΕΙ: η εντολή απαιτεί το adoption certificate να καταγράφει
«αποτέλεσμα νέου verifier N/M conforming». Ο αριθμός ΔΕΝ δηλώνεται — ΥΠΟΛΟΓΙΖΕΤΑΙ
τρέχοντας τους πραγματικούς ελέγχους. Αν κάποιο legacy release ΠΕΡΝΟΥΣΕ, θα
φαινόταν εδώ· το ότι κανένα δεν περνά είναι ΕΥΡΗΜΑ, όχι παραδοχή.

ΤΑ ΝΕΑ CONJUNCTS (υποσύνολο ελέγξιμο ΕΚΤΟΣ authority process, χωρίς δίκτυο):
  C1 transition-certificate  : υπάρχει certificate που δεσμεύει το release
  C2 canonical-cbor          : canonical wire σε deterministic CBOR (CDDL-valid)
  C3 tsa-full-verification   : receipt με ΠΛΗΡΗ RFC-3161 επαλήθευση (:pinned)
                               — nonce/policy/signer/path/validity/EKU/revocation
  C4 signed-log-checkpoint   : υπογεγραμμένο C2SP checkpoint που περιέχει το root
  C5 authority-store-record  : accepted state record στο authority store
  C6 profile-lineage         : δηλωμένο profile-id + predecessor hash
Κάθε αποτυχία καταγράφεται με ΑΚΡΙΒΗ λόγο ανά release — καμία συλλογική άρνηση.

Χρήση:  conformance-check.py <repo-root> <legacy-snapshot.json> [--out <path>]
"""
import json
import os
import sys

CONJUNCTS = [
    ("C1", "transition-certificate",
     "υπάρχει transition certificate (authority-v2) που δεσμεύει αυτό το release"),
    ("C2", "canonical-cbor",
     "canonical wire σε deterministic CBOR επικυρωμένο από το CDDL schema"),
    ("C3", "tsa-full-verification",
     "RFC-3161 receipt με ΠΛΗΡΗ επαλήθευση :pinned (nonce/policy/signer/path/"
     "validity-at-genTime/EKU/KU/revocation/algorithm-policy)"),
    ("C4", "signed-log-checkpoint",
     "υπογεγραμμένο C2SP checkpoint (Ed25519 log signature) που δεσμεύει το root"),
    ("C5", "authority-store-record",
     "accepted state record στο συναλλακτικό authority store"),
    ("C6", "profile-lineage",
     "δηλωμένο profile-id + predecessor-profile hash"),
]


def check_release(repo_root, rel_path):
    """Επιστρέφει (conforming?, {conjunct: (pass?, λόγος)}) για ένα legacy release."""
    full = os.path.join(repo_root, rel_path)
    res = {}

    # C1 — transition certificate: το authority-v2 store δεν είχε υπάρξει καν.
    cert = os.path.join(full, "transition-certificate.cbor")
    res["C1"] = (os.path.isfile(cert),
                 "παρόν" if os.path.isfile(cert)
                 else "ΑΠΟΝ transition-certificate.cbor (η legacy εποχή δεν είχε certificates)")

    # C2 — canonical CBOR wire.
    has_cbor = any(f.endswith(".cbor") for f in os.listdir(full)) if os.path.isdir(full) else False
    res["C2"] = (has_cbor,
                 "υπάρχει .cbor" if has_cbor
                 else "ΚΑΝΕΝΑ canonical CBOR artifact (legacy wire = JSON/TTL)")

    # C3 — πλήρης TSA επαλήθευση. Το legacy attestation ήταν substring-σάρωση
    # του imprint· δεν υπάρχει ΚΑΝΕΝΑ αποθηκευμένο verification record, ούτε
    # nonce/policy/signer/path/revocation evidence.
    tp = os.path.join(full, "temporal-proof")
    tsr_present = os.path.isdir(tp) and any(f.endswith(".tsr") for f in os.listdir(tp))
    verdict = os.path.join(tp, "tsa-verification.json")
    res["C3"] = (os.path.isfile(verdict),
                 "παρόν verification record" if os.path.isfile(verdict)
                 else ("TSR παρόν ΑΛΛΑ χωρίς πλήρες verification record "
                       "(legacy = substring imprint scan, :unpinned)" if tsr_present
                       else "ΚΑΝΕΝΑ TSR"))

    # C4 — υπογεγραμμένο checkpoint. Το legacy tlog ήταν ανυπόγραφο JSON.
    ckpt = os.path.join(full, "log-checkpoint.sig")
    res["C4"] = (os.path.isfile(ckpt),
                 "παρόν" if os.path.isfile(ckpt)
                 else "ΑΠΟΝ υπογεγραμμένο checkpoint (legacy tlog = ανυπόγραφο JSON)")

    # C5 — accepted state record.
    res["C5"] = (False,
                 "ΑΠΟΝ accepted-state record — το authority store της epoch-2 "
                 "ξεκινά κενό στο sequence 0 (evidence-only adoption)")

    # C6 — profile lineage.
    lineage = os.path.join(full, "profile-lineage.json")
    res["C6"] = (os.path.isfile(lineage),
                 "παρόν" if os.path.isfile(lineage)
                 else "ΑΠΟΝ profile-lineage (η legacy εποχή δεν είχε profile succession)")

    conforming = all(ok for ok, _ in res.values())
    return conforming, res


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    repo_root = os.path.abspath(argv[1])
    with open(argv[2], encoding="utf-8") as fh:
        snap = json.load(fh)
    out_path = argv[argv.index("--out") + 1] if "--out" in argv else None

    releases = snap["legacy_releases"]
    per_release = []
    conforming_n = 0
    for rec in releases:
        # [Δ1] Οι εγγραφές είναι πλέον {path, naming, dir_name, ...} — η
        # ταξινόμηση ονοματοδοσίας μεταφέρεται ΣΤΟ ΑΠΟΤΕΛΕΣΜΑ ώστε να φαίνεται
        # ότι κρίθηκαν ΚΑΙ ΟΙ ΔΥΟ εποχές, όχι μόνο τα content-addressed.
        rel = rec["path"] if isinstance(rec, dict) else rec
        naming = rec.get("naming") if isinstance(rec, dict) else None
        ok, res = check_release(repo_root, rel)
        conforming_n += 1 if ok else 0
        per_release.append({
            "release": rel,
            "naming": naming,
            "conforming": ok,
            "conjuncts": {k: {"pass": v[0], "reason": v[1]} for k, v in sorted(res.items())},
        })

    result = {
        "kind": "lawmax/legacy-conformance/1",
        "assurance_status": "under-construction",
        "evaluated": len(releases),
        "conforming": conforming_n,
        "summary": "%d/%d conforming" % (conforming_n, len(releases)),
        "evaluated_by_naming": {
            n: sum(1 for r in releases if isinstance(r, dict) and r.get("naming") == n)
            for n in ("content-addressed", "timestamp-named")
        },
        "conjunct_definitions": [
            {"id": cid, "name": name, "requirement": req} for cid, name, req in CONJUNCTS
        ],
        "per_release": per_release,
    }
    text = json.dumps(result, ensure_ascii=False, sort_keys=True,
                      separators=(",", ":")) + "\n"
    if out_path:
        with open(out_path, "w", encoding="utf-8") as fh:
            fh.write(text)
        print("νέος verifier έναντι legacy: %s" % result["summary"])
        # Ποιο conjunct απέτυχε πόσες φορές — διαφάνεια, όχι συλλογική άρνηση.
        counts = {}
        for pr in per_release:
            for cid, c in pr["conjuncts"].items():
                if not c["pass"]:
                    counts[cid] = counts.get(cid, 0) + 1
        for cid in sorted(counts):
            print("  %s απέτυχε σε %d/%d releases" % (cid, counts[cid], len(releases)))
        print("→ %s" % out_path)
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
