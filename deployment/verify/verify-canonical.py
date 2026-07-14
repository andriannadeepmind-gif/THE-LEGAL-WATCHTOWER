#!/usr/bin/env python3
"""verify-canonical.py — ανεξάρτητη (δεύτερης γλώσσας) υλοποίηση του
LAWMAX Canonical Serialization Spec v1 (canonical-serialization-spec.md).

Επαληθεύει τα vectors/canonical-serialization.json: για κάθε vector,
canonicalize(value) == canonical  ΚΑΙ  sha256(utf8(canonical)) == sha256.
Pure stdlib. Exit 0 μόνο σε πλήρη συμφωνία (fail-closed).
"""
import hashlib
import json
import sys
from pathlib import Path

ESCAPES = {'"': '\\"', "\\": "\\\\", "\b": "\\b", "\f": "\\f",
           "\n": "\\n", "\r": "\\r", "\t": "\\t"}


def canon_string(s: str) -> str:
    out = ['"']
    for ch in s:
        if ch in ESCAPES:
            out.append(ESCAPES[ch])
        elif ord(ch) < 0x20:
            out.append("\\u%04x" % ord(ch))  # πεζά hex (RFC 8785 §3.2.2.2)
        else:
            out.append(ch)
    out.append('"')
    return "".join(out)


def canonicalize(v) -> str:
    if v is None:
        return "null"
    if v is True or v is False:
        raise SystemExit("boolean σε hash-φέρον record — απαγορεύεται από το spec §1.6")
    if isinstance(v, str):
        return canon_string(v)
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        raise SystemExit("float σε hash-φέρον record — απαγορεύεται από το spec §1.5")
    if isinstance(v, list):
        return "[" + ",".join(canonicalize(x) for x in v) + "]"
    if isinstance(v, dict):
        items = sorted(v.items(), key=lambda kv: kv[0])  # code-point order
        return "{" + ",".join(canon_string(k) + ":" + canonicalize(x)
                              for k, x in items) + "}"
    raise SystemExit(f"μη σειριοποιήσιμος τύπος: {type(v)}")


def main() -> int:
    path = Path(__file__).parent / "vectors" / "canonical-serialization.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("schema") != "canonical-serialization-vectors/1":
        print("FAIL: άγνωστο σχήμα vectors")
        return 1
    failures = 0
    for vec in data["vectors"]:
        canon = canonicalize(vec["value"])
        digest = hashlib.sha256(canon.encode("utf-8")).hexdigest()
        ok_c = canon == vec["canonical"]
        ok_h = digest == vec["sha256"]
        status = "ok  " if (ok_c and ok_h) else "FAIL"
        print(f"  {status} {vec['name']}")
        if not ok_c:
            failures += 1
            print(f"       canonical θέλει: {vec['canonical'][:80]}…")
            print(f"       canonical βγήκε: {canon[:80]}…")
        if not ok_h:
            failures += 1
            print(f"       sha256 θέλει: {vec['sha256']}")
            print(f"       sha256 βγήκε: {digest}")
    total = len(data["vectors"])
    print(f"canonical-serialization: {total - failures}/{total} συμφωνίες")
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
