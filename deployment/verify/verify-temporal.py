#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""[0088 Φ7 Π6] Ανεξάρτητος verifier της τυπικής χρονικής σημασιολογίας —
ΚΑΘΑΡΗ stdlib python, ΚΑΜΙΑ κοινή γραμμή κώδικα με το Lisp runtime.

Επαναϋλοποιεί από το spec (deployment/LAWMAX-TEMPORAL-SEMANTICS-SPEC.md v3):
  • value-canonical sexp σειριοποίηση (%canon-sexp)
  • date+ κατά ΑΚ 241-243 (μήνες/έτη με τελευταία-του-μήνα, δίσεκτα)
  • σημασιολογική κανονικοποίηση condition AST (flatten/dedupe/sort/collapse)
  • domain-separated condition-id / condition-event-hash / regime-hash
  • denotational sat (min/max at, cid-scoped events, σύμφωνα ⇒ ελάχιστο at,
    αντιφατικά ⇒ σφάλμα)
  • αναπαραγωγή effectivity-attestation canonical + hash

Καταναλώνει vectors που παράγει η Lisp έδρα (tests/temporal-verifier-test.lisp)
— N-version agreement: ΚΑΘΕ διαφωνία = exit 1 με ονομαστικό σημείο.
Δηλωμένο όριο: η επικύρωση μητρώου kinds/evidence είναι Lisp-side gate·
εδώ επαληθεύεται η ΣΗΜΑΣΙΟΛΟΓΙΑ και οι ταυτότητες.

Sexp encoding στα vectors (tagged JSON): {"t":"nil"} | {"t":"kw","v":NAME}
| {"t":"s","v":...} | {"t":"i","v":...} | {"t":"l","v":[...]}.
"""
import sys, json, hashlib, calendar

FAIL = []

def fail(where, msg):
    FAIL.append("%s: %s" % (where, msg))

# ── value-canonical sexp ────────────────────────────────────────────────────
def canon(x):
    t = x["t"]
    if t == "nil": return "NIL"
    if t == "kw":  return ":" + x["v"]
    if t == "i":   return str(x["v"])
    if t == "s":
        s = x["v"].replace("\\", "\\\\").replace('"', '\\"')
        return '"' + s + '"'
    if t == "l":
        return "(" + " ".join(canon(c) for c in x["v"]) + ")"
    raise ValueError("unknown tag %r" % t)

def sha256_hex(s):
    return hashlib.sha256(s.encode("utf-8")).hexdigest()

def kw(v):  return {"t": "kw", "v": v}
def st(v):  return {"t": "s", "v": v}
def lst(*v): return {"t": "l", "v": list(v)}
def nil():  return {"t": "nil"}

# ── date+ (ΑΚ 241-243) ─────────────────────────────────────────────────────
def is_legal_date(d):
    if not (isinstance(d, str) and len(d) == 10 and d[4] == "-" and d[7] == "-"):
        return False
    try:
        y, m, dd = int(d[0:4]), int(d[5:7]), int(d[8:10])
    except ValueError:
        return False
    if not (1 <= m <= 12): return False
    return 1 <= dd <= calendar.monthrange(y, m)[1]

def date_plus(d, unit, n):
    assert is_legal_date(d), "μη legal-date %r" % d
    y, m, dd = int(d[0:4]), int(d[5:7]), int(d[8:10])
    if unit == "days":
        import datetime
        r = datetime.date(y, m, dd) + datetime.timedelta(days=n)
        return "%04d-%02d-%02d" % (r.year, r.month, r.day)
    months = n if unit == "months" else 12 * n
    total = y * 12 + (m - 1) + months
    yy, mm = divmod(total, 12)
    mm += 1
    return "%04d-%02d-%02d" % (yy, mm, min(dd, calendar.monthrange(yy, mm)[1]))

# ── σημασιολογική κανονικοποίηση AST ────────────────────────────────────────
def canon_ast(ast):
    head = ast["v"][0]["v"].lower()
    if head in ("date-reached", "instrument-event"):
        return ast
    if head == "after":
        return lst(ast["v"][0], ast["v"][1], canon_ast(ast["v"][2]))
    if head in ("and", "or"):
        kids = []
        for c in ast["v"][1:]:
            n = canon_ast(c)
            if n["v"][0]["v"] == head:
                kids.extend(n["v"][1:])
            else:
                kids.append(n)
        uniq, seen = [], set()
        for k in kids:
            key = canon(k)
            if key not in seen:
                seen.add(key); uniq.append(k)
        uniq.sort(key=canon)
        if len(uniq) == 1:
            return uniq[0]
        return lst(ast["v"][0], *uniq)
    raise ValueError("άγνωστος κόμβος %r" % head)

def condition_id(cls, ast):
    payload = lst(kw("LAWMAX/EFFECTIVITY-CONDITION/1"), kw(cls.upper()),
                  canon_ast(ast))
    return sha256_hex(canon(payload))

def condition_event_hash(cid, kind, ref, outcome, at, evidence_digest):
    payload = lst(kw("LAWMAX/CONDITION-EVENT/1"), st(cid), kw(kind.upper()),
                  st(ref), kw(outcome.upper()), st(at), st(evidence_digest))
    return sha256_hex(canon(payload))

def regime_hash(op, target, version, span_from, span_until, scope, cid,
                act_ref, act_seq, enacted, fek_date, prior):
    # [Φ7-HARDENING #2/#3] scope = tagged-sexp scope-set (ή None=καθολικό)·
    # span_from δέχεται και "on-satisfaction" (resolutory παραγόμενη αφετηρία)
    def opt(v): return st(v) if v is not None else nil()
    payload = lst(kw("LAWMAX/REGIME-EDGE/1"), kw(op.upper()), st(target),
                  opt(version), st(span_from),
                  st("open") if span_until == "open" else st(span_until),
                  nil() if scope is None
                  else (scope if isinstance(scope, dict) else st(scope)),
                  opt(cid), st(act_ref),
                  {"t": "i", "v": act_seq} if isinstance(act_seq, int)
                  else lst(*[{"t": "i", "v": i} for i in act_seq]),
                  st(enacted), st(fek_date), opt(prior))
    return sha256_hex(canon(payload))

# ── denotational sat ────────────────────────────────────────────────────────
class SatError(Exception): pass

def sat(ast, events, cid=None):
    for e in events:
        if e.get("outcome") not in ("satisfied", "refuted"):
            raise SatError("άκυρο outcome")
        if not is_legal_date(e.get("at", "")):
            raise SatError("άκυρο at")
        if cid is None and e.get("cid") is not None:
            raise SatError("cid event σε μη-scoped αποτίμηση")
    return _sat(ast, events, cid)

def _key(d):  # ολικό κλειδί ημερομηνίας
    return int(d.replace("-", ""))

def _sat(ast, events, cid):
    head = ast["v"][0]["v"].lower()
    if head == "date-reached":
        return ("satisfied", ast["v"][1]["v"])
    if head == "instrument-event":
        kind, ref = ast["v"][1]["v"].lower(), ast["v"][2]["v"]
        hits = []
        for e in events:
            if e["kind"] != kind or e["ref"] != ref:
                continue
            if cid is not None:
                if e.get("cid") is None:
                    raise SatError("event χωρίς cid σε scoped αποτίμηση")
                if e["cid"] != cid:
                    continue
            hits.append(e)
        if not hits:
            return ("pending", None)
        outcomes = {e["outcome"] for e in hits}
        if len(outcomes) > 1:
            raise SatError("αντιφατικά events")
        return (hits[0]["outcome"], min(e["at"] for e in hits))
    if head == "after":
        unit = ast["v"][1]["v"][0]["v"].lower()
        n = ast["v"][1]["v"][1]["v"]
        s, at = _sat(ast["v"][2], events, cid)
        if s == "satisfied":
            return ("satisfied", date_plus(at, unit, n))
        return (s, at)
    subs = [_sat(c, events, cid) for c in ast["v"][1:]]
    if head == "and":
        if any(s == "refuted" for s, _ in subs):
            return ("refuted", min(at for s, at in subs if s == "refuted"))
        if all(s == "satisfied" for s, _ in subs):
            return ("satisfied", max(at for _, at in subs))
        return ("pending", None)
    if head == "or":
        if any(s == "satisfied" for s, _ in subs):
            return ("satisfied", min(at for s, at in subs if s == "satisfied"))
        if all(s == "refuted" for s, _ in subs):
            return ("refuted", max(at for _, at in subs))
        return ("pending", None)
    raise ValueError("άγνωστος κόμβος %r" % head)

# ── attestation αναπαραγωγή ────────────────────────────────────────────────
def attestation_canonical(f):
    # [tra/2 — REVIEW Δ] assurance/anchor/scope ΜΕΣΑ στο hash: αλλαγή
    # provisional→release-anchored ⇒ ΑΛΛΟ TRA hash/ID.
    def sxs(items):  # λίστα από λίστες strings
        return lst(*[lst(*[st(x) for x in row]) for row in items])
    outcome = lst(*[st(x) for x in f["outcome"]])
    ctx = f.get("scope_context")
    payload = lst(kw("LAWMAX/ATTESTATION/2"), st(f["corpus_id"]),
                  st(f["provision"]), st(f["valid_at"]), st(f["known_at"]),
                  nil() if ctx is None else (ctx if isinstance(ctx, dict) else st(ctx)),
                  st(f["scope_mode"]),
                  outcome, sxs(f["condition_states"]),
                  lst(*[st(x) for x in f["regime_edge_ids"]]),
                  st(f["receipt_id"]),
                  st(f["assurance"]), st(f["release_root"]),
                  nil() if not f.get("anchor_reasons")
                  else lst(*[st(x) for x in f["anchor_reasons"]]),
                  {"t": "i", "v": f["tlog_size"]}, st(f["tlog_root"]),
                  st(f["registry_digest"]),
                  st(f["graph_chain_head"]), st(f["verifier_hash"]))
    return canon(payload)

# ── main ────────────────────────────────────────────────────────────────────
def main(path):
    with open(path, encoding="utf-8") as fh:
        V = json.load(fh)

    for i, c in enumerate(V.get("canon", [])):
        got = canon(c["sx"])
        if got != c["expect"]:
            fail("canon[%d]" % i, "%r ≠ %r" % (got, c["expect"]))

    for i, c in enumerate(V.get("dateplus", [])):
        got = date_plus(c["date"], c["unit"], c["n"])
        if got != c["expect"]:
            fail("dateplus[%d]" % i, "%s+%d%s: %s ≠ %s"
                 % (c["date"], c["n"], c["unit"], got, c["expect"]))

    for i, c in enumerate(V.get("condition_id", [])):
        got = condition_id(c["class"], c["ast"])
        if got != c["expect"]:
            fail("condition_id[%d]" % i, "%s ≠ %s" % (got, c["expect"]))
        gcanon = canon(canon_ast(c["ast"]))
        if gcanon != c["canon"]:
            fail("condition_canon[%d]" % i, "%r ≠ %r" % (gcanon, c["canon"]))

    for i, c in enumerate(V.get("sat", [])):
        try:
            s, at = sat(c["ast"], c["events"], c.get("cid"))
            got = [s] if at is None else [s, at]
        except SatError:
            got = ["error"]
        if got != c["expect"]:
            fail("sat[%d]" % i, "%r ≠ %r" % (got, c["expect"]))

    for i, c in enumerate(V.get("event_hash", [])):
        got = condition_event_hash(c["cid"], c["kind"], c["ref"], c["outcome"],
                                   c["at"], c["evidence_digest"])
        if got != c["expect"]:
            fail("event_hash[%d]" % i, "%s ≠ %s" % (got, c["expect"]))

    for i, c in enumerate(V.get("regime_hash", [])):
        got = regime_hash(c["op"], c["target"], c.get("version"),
                          c["span_from"], c["span_until"], c.get("scope"),
                          c.get("cid"), c["act_ref"], c["act_seq"],
                          c["enacted"], c["fek_date"], c.get("prior"))
        if got != c["expect"]:
            fail("regime_hash[%d]" % i, "%s ≠ %s" % (got, c["expect"]))

    for i, c in enumerate(V.get("attestation", [])):
        gc = attestation_canonical(c["fields"])
        if gc != c["canonical"]:
            fail("attestation[%d].canonical" % i, "διαφωνία σειριοποίησης")
        gh = sha256_hex(gc)
        if gh != c["hash"]:
            fail("attestation[%d].hash" % i, "%s ≠ %s" % (gh, c["hash"]))

    total = sum(len(V.get(k, [])) for k in
                ("canon", "dateplus", "condition_id", "sat",
                 "event_hash", "regime_hash", "attestation"))
    if FAIL:
        print("verify-temporal: %d/%d ΔΙΑΦΩΝΙΕΣ" % (len(FAIL), total))
        for f in FAIL:
            print("  ✗ " + f)
        sys.exit(1)
    print("verify-temporal: %d vectors, 0 διαφωνίες — N-version agreement OK" % total)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: verify-temporal.py <vectors.json>"); sys.exit(2)
    main(sys.argv[1])
