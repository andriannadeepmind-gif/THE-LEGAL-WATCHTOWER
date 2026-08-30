"""MODEL I — I-44 Canonical Encoding Assurance (architecture evidence).

The whole trust chain -- semantic object -> canonical bytes -> domain-separated ObjectId ->
signature/root -- is only as strong as its first arrow. This is an executable assurance suite
over a bounded typed domain with a strict decoder, a differential second decoder, and seeded
malleability mutants that must be caught.

Properties (exhaustive within the declared bounds):
  RoundTrip            decode(encode(x)) = x                 for every object
  CanonicalAcceptance  accepted(b) => encode(decode(b)) = b   for every symbol string |b| <= 5
  Injectivity          encode(x) = encode(y) => x = y         over all object pairs
  DomainSeparation     an encoding of one typed domain never decodes in another
  Differential         an independent decoder agrees on accept/reject and on the value
Non-canonical input is REJECTED, never "accepted then normalized".
"""
from __future__ import annotations
from itertools import product

ALPHABET = range(5)
MAXLEN = 5
DOM_LEGAL, DOM_CLAIM = 0, 1          # domain tags
TYPE_A, TYPE_B = 1, 2

def objects():
    for x in range(3):
        for opt in (None, 0, 1):
            yield ("A", x, opt)
    for y in range(3):
        yield ("B", y, None)

def encode(o, domain=DOM_LEGAL, mutation=None):
    kind, v, opt = o
    out = [] if mutation == "drop_domain_tag" else [domain]
    if mutation != "drop_type_tag":
        out.append(TYPE_A if kind == "A" else TYPE_B)
    out.append(v)
    if mutation == "conflate_types" and kind == "A" and opt is None:
        return tuple([domain, TYPE_B, v])      # type confusion: A-without-option looks like B
    if kind == "A":
        if mutation == "drop_optional_entirely":
            pass                               # optional field silently dropped: A(x,*) collide
        else:
            out.append(1 if opt is not None else 0)
            if opt is not None:
                out.append(opt)
    return tuple(out)

def decode(b, domain=DOM_LEGAL, mutation=None):
    """Strict decoder: any deviation is a rejection, never a repair."""
    i = 0
    if mutation != "drop_domain_tag":
        if i >= len(b) or b[i] != domain:
            return None
        i += 1
    if mutation == "drop_type_tag":
        return None
    if i >= len(b) or b[i] not in (TYPE_A, TYPE_B):
        return None
    t = b[i]; i += 1
    if i >= len(b) or b[i] > 2:
        return None
    v = b[i]; i += 1
    if t == TYPE_A:
        if mutation == "drop_optional_entirely":
            opt = None
        else:
            if i >= len(b) or b[i] not in (0, 1):
                return None
            has = b[i]; i += 1
            opt = None
            if has:
                if i >= len(b) or b[i] > 1:
                    return None
                opt = b[i]; i += 1
        obj = ("A", v, opt)
    else:
        obj = ("B", v, None)
    if i != len(b) and mutation != "allow_trailing":
        return None                                   # trailing symbols: reject
    return obj

def decode_alt(b, domain=DOM_LEGAL):
    """Independent table-driven decoder for the differential check."""
    b = list(b)
    if not b or b[0] != domain:
        return None
    rest = b[1:]
    if not rest or rest[0] not in (TYPE_A, TYPE_B):
        return None
    if rest[0] == TYPE_B:
        return ("B", rest[1], None) if len(rest) == 2 and rest[1] <= 2 else None
    if len(rest) == 3 and rest[1] <= 2 and rest[2] == 0:
        return ("A", rest[1], None)
    if len(rest) == 4 and rest[1] <= 2 and rest[2] == 1 and rest[3] <= 1:
        return ("A", rest[1], rest[3])
    return None

def all_strings():
    for n in range(MAXLEN + 1):
        yield from product(ALPHABET, repeat=n)

def run(mutation=None):
    objs = list(objects())
    rt = all(decode(encode(o, mutation=mutation), mutation=mutation) == o for o in objs)
    canon, canon_why = True, ""
    for b in all_strings():
        d = decode(b, mutation=mutation)
        if d is not None and encode(d, mutation=mutation) != b:
            canon, canon_why = False, f"non-canonical accepted: {b} re-encodes to {encode(d, mutation=mutation)}"
            break
    enc = {}
    inj, inj_why = True, ""
    for o in objs:
        e = encode(o, mutation=mutation)
        if e in enc and enc[e] != o:
            inj, inj_why = False, f"collision: {enc[e]} and {o} both encode to {e}"
            break
        enc[e] = o
    dom = all(decode(encode(o, DOM_LEGAL, mutation), DOM_CLAIM, mutation) is None for o in objs)
    diff = all(decode(b) == decode_alt(b) for b in all_strings()) if mutation is None else None
    return {"RoundTrip": (rt, ""), "CanonicalAcceptance": (canon, canon_why),
            "Injectivity": (inj, inj_why), "DomainSeparation": (dom, ""),
            "Differential": (diff, "")}

MUTANTS = {"allow_trailing": "CanonicalAcceptance", "drop_type_tag": "RoundTrip",
           "drop_domain_tag": "DomainSeparation", "drop_optional_entirely": "Injectivity",
           "conflate_types": "Injectivity"}

if __name__ == "__main__":
    base = run()
    print(f"bounded domain: {len(list(objects()))} objects · symbol strings checked: "
          f"{sum(1 for _ in all_strings())} (alphabet {len(list(ALPHABET))}, |b| <= {MAXLEN})")
    ok = True
    for k, (v, why) in base.items():
        print(f"  {k:20s}: {'HOLDS' if v else 'VIOLATED'}{(' — ' + why) if why else ''}")
        ok &= bool(v)
    print("  mutation battery (seeded malleability must be caught):")
    for m, target in MUTANTS.items():
        r = run(m)
        caught = not r[target][0]
        print(f"    {m:20s} vs {target:20s}: {'CAUGHT' if caught else 'MISSED'}"
              f"{(' — ' + r[target][1]) if caught and r[target][1] else ''}")
        ok &= caught
    print("\nMODEL I:", "PASS" if ok else "FAIL")
