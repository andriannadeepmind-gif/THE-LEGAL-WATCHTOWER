#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ΔΙΑΧΩΡΙΣΜΟΣ ΡΟΛΩΝ ΣΕ ΚΑΘΕ SERVICE — ΕΛΕΓΜΕΝΟΣ, ΟΧΙ ΙΣΧΥΡΙΣΜΕΝΟΣ

ΕΤΥΜΗΓΟΡΙΕΣ ΔΗΜΙΟΥΡΓΟΥ ΠΟΥ ΚΛΕΙΝΟΥΝ ΕΔΩ:
  P0 «Ο producer λαμβάνει ολόκληρο το ./keys και PRIVATE_KEY_PATH=…private.pem.
      Το read-only εμποδίζει ΑΛΛΟΙΩΣΗ, όχι ΑΝΑΓΝΩΣΗ ή ΥΠΟΚΛΟΠΗ.»
      ⇒ Απαγορεύεται η ΥΠΑΡΞΗ ιδιωτικού κλειδιού σε μη-authority υπηρεσία, ακόμη
        και :ro, ακόμη και ως env μεταβλητή.
  P0 «Το ./deployment παραμένει writable στον producer ⇒ μπορεί να αλλοιώσει
      specs, vectors και verification inputs.»
      ⇒ Το /app/deployment ΠΡΕΠΕΙ να είναι read-only· εγγράψιμο επιτρέπεται ΜΟΝΟ
        ο ΔΗΛΩΜΕΝΟΣ evidence υποτόμος, και ΜΟΝΟ αν η πηγή του είναι ΕΚΤΟΣ του
        ./deployment (ξεχωριστός host τόμος).
  P1 «Ο verifier αναγνωρίζει runtime μόνο με image == "orchestrator:latest".
      Αλλαγή tag ή alias παρακάμπτει τους ελέγχους.»
      ⇒ Runtime = ΟΠΟΙΑΔΗΠΟΤΕ υπηρεσία χτίζεται από ΤΟ Dockerfile ΤΟΥ ΕΡΓΟΥ Ή
        χρησιμοποιεί image που κάποια υπηρεσία του αρχείου χτίζει από αυτό. Το
        tag ΔΕΝ είναι κριτήριο.

ΚΑΘΕ υπηρεσία ταξινομείται ΑΚΡΙΒΩΣ ΜΙΑ ΦΟΡΑ σε ρόλο (producer/reader/authority/
proof-runner). Αταξινόμητη υπηρεσία ⇒ ΣΦΑΛΜΑ (καμία σιωπηλή εξαίρεση).

ΤΙΜΙΟ ΟΡΙΟ: ελέγχεται η ΔΗΛΩΜΕΝΗ τοπολογία. Η ΕΚΤΕΛΕΣΗ απαιτεί docker daemon και
δηλώνεται χωριστά (authority-v2/proofs/docker-e2e-test.sh).
"""
import copy
import os
import sys

try:
    import yaml
except ImportError:
    print("::error::BLOCKED — NOT EXECUTED: το PyYAML απουσιάζει (δεν δηλώνεται pass)")
    sys.exit(2)

_HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(_HERE))
COMPOSE = os.path.join(REPO, "docker-compose.yml")

PRODUCER_UID, READER_UID, AUTHORITY_UID = "11002", "11003", "11001"
AUTHORITY_STORE = "/var/lib/lawmax/authority"
PRIVATE_MARKERS = ("keys/private", "/private.pem", "private.key", "/app/keys/private")
# Ρόλοι: ΚΑΘΕ υπηρεσία ταξινομείται ΑΚΡΙΒΩΣ ΜΙΑ φορά.
ROLE_BY_UID = {PRODUCER_UID: "producer", READER_UID: "reader", AUTHORITY_UID: "authority"}
PROOF_RUNNER = "authority-v2-proofs"

passed = failed = 0


def ok(m):
    global passed
    passed += 1
    print("  ok   " + m)


def no(m):
    global failed
    failed += 1
    print("  FAIL " + m)


def mounts_of(svc):
    out = []
    for v in svc.get("volumes", []):
        if isinstance(v, str):
            parts = v.split(":")
            src, tgt = parts[0], parts[1] if len(parts) > 1 else parts[0]
            mode = parts[2] if len(parts) > 2 else "rw"
        else:
            src, tgt = v.get("source", ""), v.get("target", "")
            mode = "ro" if v.get("read_only") else "rw"
        out.append((src, tgt, mode))
    return out


def env_of(svc):
    e = svc.get("environment", {})
    if isinstance(e, list):
        return dict(x.split("=", 1) for x in e if "=" in x)
    return {k: ("" if v is None else str(v)) for k, v in e.items()}


def build_images(doc):
    """Images που ΧΤΙΖΟΝΤΑΙ από το Dockerfile του έργου — το tag ΔΕΝ είναι κριτήριο."""
    imgs = set()
    for svc in doc.get("services", {}).values():
        b = svc.get("build")
        if not b:
            continue
        df = b.get("dockerfile", "Dockerfile") if isinstance(b, dict) else "Dockerfile"
        if df == "Dockerfile" and svc.get("image"):
            imgs.add(svc["image"])
    return imgs


def is_runtime(svc, built):
    b = svc.get("build")
    if b:
        df = b.get("dockerfile", "Dockerfile") if isinstance(b, dict) else "Dockerfile"
        if df == "Dockerfile":
            return True
    return svc.get("image") in built


def check(name, svc, corpora, built):
    bad = []
    runtime = is_runtime(svc, built)
    ms, env = mounts_of(svc), env_of(svc)
    uid = str(svc.get("user", "")).split(":")[0]
    role = ROLE_BY_UID.get(uid)

    if runtime and role is None:
        bad.append("runtime service ΧΩΡΙΣ ΤΑΞΙΝΟΜΗΜΕΝΟ ρόλο (user=%r)" % svc.get("user"))

    # ── ΙΔΙΩΤΙΚΟ ΚΛΕΙΔΙ: ΥΠΑΡΞΗ, όχι εγγραψιμότητα ─────────────────────────
    if role != "authority":
        for src, tgt, _mode in ms:
            if any(m in (src + " " + tgt) for m in PRIVATE_MARKERS):
                bad.append("ΒΛΕΠΕΙ ιδιωτικό κλειδί (έστω :ro): %s→%s" % (src, tgt))
        for k, v in env.items():
            if "PRIVATE_KEY" in k or any(m in v for m in PRIVATE_MARKERS):
                bad.append("δηλώνει ιδιωτικό κλειδί σε env: %s=%s" % (k, v))
        for src, tgt, _m in ms:
            if AUTHORITY_STORE in (src + " " + tgt):
                bad.append("προσαρτά authority store: %s→%s" % (src, tgt))

    for src, tgt, mode in ms:
        if mode == "ro":
            continue
        t = tgt.rstrip("/")
        if t == "/app/output":
            bad.append("ΕΓΓΡΑΨΙΜΟ ΟΛΟ το /app/output")
        if "/releases" in (src + " " + tgt):
            bad.append("rw mount αγγίζει releases: %s→%s" % (src, tgt))
        # deployment: εγγράψιμο ΜΟΝΟ αν η ΠΗΓΗ είναι ΕΚΤΟΣ του ./deployment
        if t.startswith("/app/deployment"):
            if src.replace("./", "").startswith("deployment"):
                bad.append("ΕΓΓΡΑΨΙΜΟ deployment ΑΠΟ ΤΟ ΙΔΙΟ ΤΟ deployment: %s→%s" % (src, tgt))

    if runtime:
        if not any(t.rstrip("/") == "/app/output" and m == "ro" for _s, t, m in ms):
            bad.append("το /app/output ΔΕΝ είναι προσαρτημένο read-only")
        if not any(t.rstrip("/") == "/app/deployment" and m == "ro" for _s, t, m in ms):
            bad.append("το /app/deployment ΔΕΝ είναι προσαρτημένο read-only")
        tm = " ".join(svc.get("tmpfs", []) or [])
        if "/run/lawmax" not in tm:
            bad.append("καμία tmpfs για /run/lawmax (η υγεία θα έγραφε σε evidence)")
        if role == "producer":
            if env.get("ORCHESTRATOR_OUTPUT_DIR", "").rstrip("/") != "/app/candidates":
                bad.append("ORCHESTRATOR_OUTPUT_DIR=%r — ο παραγωγός ΠΡΕΠΕΙ να γράφει στο candidate workspace"
                           % env.get("ORCHESTRATOR_OUTPUT_DIR"))
            if env.get("LAWMAX_RUNTIME_DIR", "").rstrip("/") != "/run/lawmax":
                bad.append("LAWMAX_RUNTIME_DIR=%r" % env.get("LAWMAX_RUNTIME_DIR"))
            if not any(t.rstrip("/") == "/app/candidates" and m != "ro" for _s, t, m in ms):
                bad.append("ο παραγωγός ΔΕΝ έχει εγγράψιμο /app/candidates — ΚΕΝΗ τοπολογία")
        if role == "reader":
            if any(m != "ro" and not t.startswith("/app/deployment") for _s, t, m in ms):
                bad.append("ο reader έχει εγγράψιμο mount εκτός evidence")
        if svc.get("read_only") is not True:
            bad.append("read_only rootfs ΔΕΝ δηλώθηκε")
        if svc.get("cap_drop") != ["ALL"]:
            bad.append("cap_drop ≠ [ALL] (got=%r)" % (svc.get("cap_drop"),))
        if "no-new-privileges:true" not in (svc.get("security_opt") or []):
            bad.append("no-new-privileges ΔΕΝ δηλώθηκε")
    return bad, role, runtime


with open(COMPOSE, encoding="utf-8") as fh:
    doc = yaml.safe_load(fh)
services = doc.get("services", {})
BUILT = build_images(doc)
CORPORA = sorted(c for c in os.listdir(os.path.join(REPO, "output"))
                 if os.path.isdir(os.path.join(REPO, "output", c, "releases")))

print("== ΤΑΞΙΝΟΜΗΣΗ ΡΟΛΩΝ: %d services· images από ΤΟ Dockerfile: %s =="
      % (len(services), ", ".join(sorted(BUILT)) or "—"))
if not BUILT:
    no("ΚΕΝΟΣ ΜΑΡΤΥΡΑΣ: καμία υπηρεσία δεν χτίζεται από το Dockerfile")

classified = {}
for name in sorted(services):
    svc = services[name]
    if name == PROOF_RUNNER:
        if is_runtime(svc, BUILT):
            no("η ΔΗΛΩΜΕΝΗ ΕΞΑΙΡΕΣΗ %s τρέχει το runtime image — ΚΕΡΚΟΠΟΡΤΑ" % name)
        else:
            classified[name] = "proof-runner"
            ok("%s: proof-runner (ΔΗΛΩΜΕΝΗ εξαίρεση, ΟΧΙ runtime image)" % name)
        continue
    bad, role, runtime = check(name, svc, CORPORA, BUILT)
    classified[name] = role or ("runtime-unclassified" if runtime else "non-runtime")
    if bad:
        for b in bad:
            no("%s [%s]: %s" % (name, role or "—", b))
    else:
        ok("%s: ρόλος=%s · output ro · deployment ro · κανένα ιδιωτικό κλειδί · tmpfs /run/lawmax"
           % (name, role or "non-runtime"))

# ΚΑΘΕ υπηρεσία ΑΚΡΙΒΩΣ ΜΙΑ φορά — καμία αταξινόμητη.
unclassified = [n for n, r in classified.items() if r in (None, "runtime-unclassified")]
(ok if not unclassified else no)(
    "ΚΑΘΕ υπηρεσία ταξινομήθηκε ΑΚΡΙΒΩΣ ΜΙΑ φορά (αταξινόμητες: %s)"
    % (unclassified or "καμία"))
roles = sorted(set(classified.values()))
(ok if "authority" in roles and "producer" in roles and "reader" in roles else no)(
    "υπάρχουν ΚΑΙ ΟΙ ΤΡΕΙΣ διακριτοί ρόλοι (βρέθηκαν: %s)" % ", ".join(roles))

print("\n== ΜΗ ΚΕΝΟΤΗΤΑ: ΜΕΤΑΛΛΑΓΜΕΝΕΣ ΤΟΠΟΛΟΓΙΕΣ ΠΡΕΠΕΙ ΝΑ ΑΠΟΡΡΙΠΤΟΝΤΑΙ ==")
BASE = copy.deepcopy(services["producer"])


def mutate(name, fn, token, base=None, built=None):
    m = copy.deepcopy(base if base is not None else BASE)
    fn(m)
    bad, _r, _rt = check("μεταλλαγμένο", m, CORPORA, built if built is not None else BUILT)
    (ok if any(token in b for b in bad) else no)(
        "%s ⇒ %s" % (name, ("ΑΠΟΡΡΙΨΗ («%s»)" % token) if any(token in b for b in bad)
                     else "ΕΓΙΝΕ ΔΕΚΤΗ (%s)" % bad))


mutate("ΑΝΑΓΝΩΣΙΜΟ ιδιωτικό κλειδί (:ro)",
       lambda m: m["volumes"].append("./keys/private:/app/keys/private:ro"),
       "ΒΛΕΠΕΙ ιδιωτικό κλειδί")
mutate("PRIVATE_KEY_PATH σε env",
       lambda m: m["environment"].update({"PRIVATE_KEY_PATH": "/app/keys/private.pem"}),
       "ιδιωτικό κλειδί σε env")
mutate("ΕΓΓΡΑΨΙΜΟ deployment από το ίδιο το deployment",
       lambda m: m["volumes"].append("./deployment/self:/app/deployment/self:rw"),
       "ΕΓΓΡΑΨΙΜΟ deployment ΑΠΟ ΤΟ ΙΔΙΟ")
mutate("ΟΛΟ το output ως rw",
       lambda m: m["volumes"].__setitem__(
           m["volumes"].index("./output:/app/output:ro"), "./output:/app/output:rw"),
       "ΕΓΓΡΑΨΙΜΟ ΟΛΟ")
mutate("output workspace πίσω στο /app/output",
       lambda m: m["environment"].update({"ORCHESTRATOR_OUTPUT_DIR": "/app/output"}),
       "ΠΡΕΠΕΙ να γράφει στο candidate workspace")
mutate("χωρίς tmpfs /run/lawmax (health σε evidence)",
       lambda m: m.pop("tmpfs"), "καμία tmpfs")
mutate("τρέξιμο ως root", lambda m: m.update(user="0:0"), "ΤΑΞΙΝΟΜΗΜΕΝΟ ρόλο")
mutate("προσάρτηση authority store",
       lambda m: m["volumes"].append("%s:%s:rw" % (AUTHORITY_STORE, AUTHORITY_STORE)),
       "authority store")
# ΤΟ ΑΚΡΙΒΕΣ P1: αλλαγή tag ΔΕΝ πρέπει να παρακάμπτει τους ελέγχους.
mutate("IMAGE-TAG BYPASS (άλλο tag, ίδιο Dockerfile)",
       lambda m: (m.update(image="orchestrator:sneaky"),
                  m["volumes"].__setitem__(
                      m["volumes"].index("./output:/app/output:ro"),
                      "./output:/app/output:rw")),
       "ΕΓΓΡΑΨΙΜΟ ΟΛΟ")

print("\n── ρόλοι/τοπολογία ΟΛΩΝ των services (ΔΗΛΩΜΕΝΗ· η ΕΚΤΕΛΕΣΗ απαιτεί daemon): "
      "%d passed, %d failed ──" % (passed, failed))
sys.exit(0 if failed == 0 else 1)
