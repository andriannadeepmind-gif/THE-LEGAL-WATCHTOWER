#!/usr/bin/env python3
"""ΓΝΗΣΙΟ HASH-CHAINED APPEND-ONLY ΜΗΤΡΩΟ ΓΕΓΟΝΟΤΩΝ.

  append  --what <ΚΩΔΙΚΟΣ> --detail <κείμενο> [--bind k=v ...]
  verify

ΓΙΑΤΙ: η προηγούμενη κατασκευή αυτοαποκαλούνταν «append-only» ενώ ήταν ένα
απλό αρχείο sexp που μπορούσε να ξαναγραφτεί ολόκληρο χωρίς ίχνος. Ο όρος
ήταν αναληθής. Εδώ υπάρχει ΠΡΑΓΜΑΤΙΚΗ αλυσίδα:

    entry_hash(n) = SHA256( "LAWMAX-EVENT/1\\0" ‖ prev_hash(n) ‖ canonical(payload) )
    prev_hash(0)  = 64 μηδενικά

Αλλαγή ή διαγραφή ΟΠΟΙΑΣΔΗΠΟΤΕ εγγραφής σπάει κάθε επόμενο κρίκο, και το
`verify` το εντοπίζει ΟΝΟΜΑΣΤΙΚΑ. Το canonical(payload) είναι JSON με
ταξινομημένα κλειδιά και χωρίς κενά — μία και μόνη σειριοποίηση.
"""
import hashlib
import json
import os
import sys
import time

LEDGER = "/home/user/THE-LEGAL-WATCHTOWER/experiment/phase1a/EVENT-LEDGER.jsonl"
DOMAIN = b"LAWMAX-EVENT/1\x00"
GENESIS = "0" * 64


def canonical(payload):
    return json.dumps(payload, ensure_ascii=False, sort_keys=True,
                      separators=(",", ":")).encode("utf-8")


def entry_hash(prev, payload):
    return hashlib.sha256(DOMAIN + bytes.fromhex(prev) + canonical(payload)).hexdigest()


def read_all():
    if not os.path.exists(LEDGER):
        return []
    return [json.loads(l) for l in open(LEDGER, encoding="utf-8") if l.strip()]


def verify():
    entries, prev, bad = read_all(), GENESIS, []
    for i, e in enumerate(entries):
        if e["seq"] != i:
            bad.append((i, f"seq {e['seq']} ≠ θέση {i}"))
        if e["prev_hash"] != prev:
            bad.append((i, f"prev_hash σπασμένος: {e['prev_hash'][:16]}… "
                           f"≠ {prev[:16]}…"))
        h = entry_hash(e["prev_hash"], e["payload"])
        if h != e["entry_hash"]:
            bad.append((i, f"entry_hash ΔΕΝ ΤΑΙΡΙΑΖΕΙ με το payload "
                           f"({h[:16]}… ≠ {e['entry_hash'][:16]}…)"))
        prev = e["entry_hash"]
    for i, w in bad:
        print(f"::error::ΚΡΙΚΟΣ {i}: {w}")
    if bad:
        print(f"::error::ΑΛΥΣΙΔΑ ΣΠΑΣΜΕΝΗ — {len(bad)} ευρήματα")
        return 1
    print(f"EVENT-LEDGER-CHAIN-VALID: {len(entries)} κρίκοι · "
          f"κεφαλή sha256:{prev}")
    return 0


def append(payload):
    entries = read_all()
    prev = entries[-1]["entry_hash"] if entries else GENESIS
    payload = dict(payload, utc=time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()))
    e = {"seq": len(entries), "prev_hash": prev,
         "entry_hash": entry_hash(prev, payload), "payload": payload}
    with open(LEDGER, "a", encoding="utf-8") as fh:
        fh.write(json.dumps(e, ensure_ascii=False, sort_keys=True) + "\n")
        fh.flush()
        os.fsync(fh.fileno())
    print(f"seq {e['seq']} · entry_hash sha256:{e['entry_hash']}")
    return 0


def main():
    a = sys.argv[1:]
    if not a or a[0] == "verify":
        return verify()
    if a[0] != "append":
        print("::error::append | verify")
        return 2
    def opt(n):
        return a[a.index(n) + 1] if n in a else None
    payload = {"what": opt("--what"), "detail": opt("--detail")}
    binds = {}
    for i, t in enumerate(a):
        if t == "--bind" and i + 1 < len(a) and "=" in a[i + 1]:
            k, _, v = a[i + 1].partition("=")
            binds[k] = v
    if binds:
        payload["binds"] = binds
    if not payload["what"]:
        print("::error::--what ΥΠΟΧΡΕΩΤΙΚΟ")
        return 2
    return append(payload)


sys.exit(main())
