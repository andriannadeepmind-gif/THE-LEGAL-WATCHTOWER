#!/usr/bin/env python3
"""ΠΥΛΗ ΑΚΕΡΑΙΟΤΗΤΑΣ: κάθε δηλωμένο artifact υπάρχει ΚΑΙ τα bytes επιβεβαιώνουν
το sha256 του. Κενό manifest ⇒ σφάλμα (καμία «επαληθεύτηκαν 0» ψευδο-επιτυχία).
Έξοδος 0 μόνο αν ΟΛΑ περνούν."""
import hashlib, os, re, sys

MANIFEST = sys.argv[1]
CACHE    = sys.argv[2] if len(sys.argv) > 2 else "/var/cache/lawmax-runner"
text     = open(MANIFEST, encoding="utf-8").read()

def section(name):
    i = text.find(f":{name}\n")
    if i < 0:
        return ""
    j = text.find("\n :", i + 1)
    return text[i:j if j > 0 else len(text)]

expected = []
for sec, store, ext in (("runtime-packages", "debs", ".deb"),
                        ("build-packages",   "build-debs", ".deb"),
                        ("source-artifacts", "src", None)):
    body = section(sec)
    for m in re.finditer(r':sha256 "([0-9a-f]{64})"', body):
        expected.append((sec, store, ext, m.group(1)))
    if sec == "source-artifacts":
        names = re.findall(r':name "([^"]+)"', body)
        for n, (_, _, _, d) in zip(names, [e for e in expected if e[0] == sec]):
            pass

if not expected:
    print("::error::ΚΕΝΟ manifest — καμία ψευδο-επιτυχία"); sys.exit(2)

# χάρτης sha256 → πραγματικό αρχείο, ανά αποθήκη
index = {}
for store in ("debs", "build-debs", "src"):
    d = os.path.join(CACHE, store)
    if not os.path.isdir(d):
        continue
    for fn in os.listdir(d):
        p = os.path.join(d, fn)
        if os.path.isfile(p):
            index.setdefault(hashlib.sha256(open(p, "rb").read()).hexdigest(), []).append(p)

missing = [e for e in expected if e[3] not in index]
print(f"toolchain: {len(expected)} δηλωμένα · {len(expected)-len(missing)} επαληθευμένα με bytes · {len(missing)} λείπουν")
for sec, store, _ext, d in missing:
    print(f"  ΛΕΙΠΕΙ [{sec}] {d}")
sys.exit(1 if missing else 0)
