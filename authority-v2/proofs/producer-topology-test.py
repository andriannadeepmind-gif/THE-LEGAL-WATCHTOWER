#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Η ΔΗΛΩΜΕΝΗ ΤΟΠΟΛΟΓΙΑ **ΚΑΘΕ** SERVICE — ΕΛΕΓΜΕΝΗ, ΟΧΙ ΙΣΧΥΡΙΣΜΕΝΗ

ΕΤΥΜΗΓΟΡΙΑ ΔΗΜΙΟΥΡΓΟΥ (P0): «Το ασφαλές producer προστέθηκε, αλλά είναι
προαιρετικό profile. Το κανονικό orchestrator και το ingestion εξακολουθούν να
έχουν ολόκληρο το /app/output:rw. Το topology test εξετάζει ΜΟΝΟ το
services.producer. Άρα η ασφαλής διαδρομή υπάρχει, αλλά ΔΕΝ είναι η ΜΟΝΑΔΙΚΗ
δυνατή διαδρομή.» ΟΡΘΟ — και είναι το χειρότερο είδος ψευδο-πράσινου: ο
ελεγκτής κοίταζε ακριβώς εκεί όπου ήξερε ότι θα βρει το σωστό.

ΤΩΡΑ Η ΑΠΟΓΡΑΦΗ ΕΙΝΑΙ ΚΑΘΟΛΙΚΗ: κάθε service του docker-compose.yml εξετάζεται.
ΑΠΑΓΟΡΕΥΜΕΝΑ ΓΙΑ ΚΑΘΕ SERVICE (ό,τι κι αν λέγεται, σε όποιο profile κι αν ζει):
  · εγγράψιμο /app/output ολόκληρο ή οποιαδήποτε διαδρομή releases/
  · εγγράψιμα ιδιωτικά κλειδιά (/app/keys ή *.pem/*.key)
  · οποιοδήποτε mount του authority store (/var/lib/lawmax/authority)
ΓΙΑ ΤΑ SERVICES ΤΟΥ RUNTIME IMAGE επιπλέον:
  · ΠΡΕΠΕΙ να δηλώνουν ΚΑΡΦΩΜΕΝΟ μη-root uid (11002 producer ή 11003 reader)
  · ΠΡΕΠΕΙ να έχουν το /app/output προσαρτημένο read-only

ΕΞΑΙΡΕΣΗ ΜΕ ΟΝΟΜΑ ΚΑΙ ΑΙΤΙΑ: το `authority-v2-proofs` ΕΙΝΑΙ ο προνομιούχος
εκτελεστής αποδείξεων (privileged, όλο το repo rw). ΔΕΝ είναι παραγωγική
υπηρεσία και ΔΕΝ τρέχει το runtime image· δηλώνεται ΡΗΤΑ εδώ ως εξαίρεση, με
ΕΛΕΓΧΟ ότι όντως δεν χρησιμοποιεί το runtime image (αλλιώς η εξαίρεση θα ήταν
κερκόπορτα).

ΤΙΜΙΟ ΟΡΙΟ: ελέγχεται η ΔΗΛΩΜΕΝΗ τοπολογία (το αρχείο compose), ΟΧΙ εκτελούμενος
container. Η εκτέλεση απαιτεί docker daemon και δηλώνεται χωριστά ως BLOCKED.

ΜΗ ΚΕΝΟΤΗΤΑ: ο ΙΔΙΟΣ ελεγκτής τρέχει πάνω σε ΜΕΤΑΛΛΑΓΜΕΝΑ services και ΟΦΕΙΛΕΙ
να τα απορρίψει.
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
RUNTIME_IMAGE = "orchestrator:latest"
PRODUCER_UID, READER_UID = "11002", "11003"
AUTHORITY_STORE = "/var/lib/lawmax/authority"
# Εξαίρεση ΜΕ ΟΝΟΜΑ, ΑΙΤΙΑ και ΕΛΕΓΧΟ (δεν επιτρέπεται να τρέχει το runtime image).
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


def parse_mounts(svc):
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


def check_service(name, svc, corpora):
    """Παραβιάσεις για ΟΠΟΙΟΔΗΠΟΤΕ service. Κενή λίστα = συμμορφούμενο."""
    bad = []
    runtime = svc.get("image") == RUNTIME_IMAGE
    mounts = parse_mounts(svc)

    for src, tgt, mode in mounts:
        both = src + " " + tgt
        if mode != "ro":
            if tgt.rstrip("/") == "/app/output":
                bad.append("ΕΓΓΡΑΨΙΜΟ ΟΛΟ το /app/output")
            if "/releases" in both:
                bad.append("rw mount αγγίζει releases: %s→%s" % (src, tgt))
            if "/app/keys" in tgt or tgt.endswith(".pem") or tgt.endswith(".key"):
                bad.append("ΕΓΓΡΑΨΙΜΑ ιδιωτικά κλειδιά: %s" % tgt)
        if AUTHORITY_STORE in both:
            bad.append("mount του authority store: %s→%s" % (src, tgt))

    if runtime:
        uid = str(svc.get("user", "")).split(":")[0]
        if uid not in (PRODUCER_UID, READER_UID):
            bad.append("runtime service ΧΩΡΙΣ καρφωμένο uid (user=%r)" % svc.get("user"))
        if not any(t.rstrip("/") == "/app/output" and m == "ro" for _, t, m in mounts):
            bad.append("το /app/output ΔΕΝ είναι προσαρτημένο read-only")
        # Θετική απαίτηση ΜΟΝΟ για producers: πρέπει να μπορούν να γράψουν candidates.
        if uid == PRODUCER_UID:
            rw_t = {t for _, t, m in mounts if m != "ro"}
            for c in corpora:
                if "/app/output/%s/candidates" % c not in rw_t:
                    bad.append("λείπει rw candidates για το corpus %s" % c)
    return bad


with open(COMPOSE, encoding="utf-8") as fh:
    doc = yaml.safe_load(fh)
services = doc.get("services", {})
CORPORA = sorted(c for c in os.listdir(os.path.join(REPO, "output"))
                 if os.path.isdir(os.path.join(REPO, "output", c, "releases")))

print("== ΚΑΘΟΛΙΚΗ ΑΠΟΓΡΑΦΗ: %d services, corpora με releases/: %s =="
      % (len(services), ", ".join(CORPORA)))

runtime_services = [n for n, s in services.items() if s.get("image") == RUNTIME_IMAGE]
if not runtime_services:
    no("ΚΕΝΟΣ ΜΑΡΤΥΡΑΣ: κανένα service με το runtime image")
else:
    ok("services με το runtime image: %s" % ", ".join(sorted(runtime_services)))

for name in sorted(services):
    svc = services[name]
    if name == PROOF_RUNNER:
        if svc.get("image") == RUNTIME_IMAGE:
            no("η ΔΗΛΩΜΕΝΗ ΕΞΑΙΡΕΣΗ %s τρέχει το runtime image — ΚΕΡΚΟΠΟΡΤΑ" % name)
        else:
            ok("%s: ΔΗΛΩΜΕΝΗ ΕΞΑΙΡΕΣΗ (εκτελεστής αποδείξεων, ΟΧΙ runtime image)" % name)
        continue
    bad = check_service(name, svc, CORPORA)
    if bad:
        for b in bad:
            no("%s: %s" % (name, b))
    else:
        u = svc.get("user", "—")
        ok("%s: συμμορφώνεται (user=%s· output ro· κανένα releases/keys/authority rw)"
           % (name, u))

print("\n== ΜΗ ΚΕΝΟΤΗΤΑ: ΜΕΤΑΛΛΑΓΜΕΝΑ SERVICES ΠΡΕΠΕΙ ΝΑ ΑΠΟΡΡΙΠΤΟΝΤΑΙ ==")
BASE = copy.deepcopy(services["producer"])


def mutate(name, fn, expect_token):
    m = copy.deepcopy(BASE)
    fn(m)
    bad = check_service("μεταλλαγμένο", m, CORPORA)
    if any(expect_token in b for b in bad):
        ok("%s ⇒ ΑΠΟΡΡΙΨΗ («%s»)" % (name, expect_token))
    else:
        no("%s ⇒ ΕΓΙΝΕ ΔΕΚΤΟ (παραβιάσεις: %s)" % (name, bad))


def _output_rw(m):
    m["volumes"] = [v.replace(":/app/output:ro", ":/app/output:rw")
                    if isinstance(v, str) else v for v in m["volumes"]]


mutate("ΟΛΟ το output ως rw", _output_rw, "ΕΓΓΡΑΨΙΜΟ ΟΛΟ")
mutate("τρέξιμο ως root", lambda m: m.update(user="0:0"), "καρφωμένο uid")
mutate("χωρίς user", lambda m: m.pop("user"), "καρφωμένο uid")
mutate("προσάρτηση authority store",
       lambda m: m["volumes"].append("%s:%s:rw" % (AUTHORITY_STORE, AUTHORITY_STORE)),
       "authority store")
mutate("εγγράψιμο releases",
       lambda m: m["volumes"].append("./output/%s/releases:/app/output/%s/releases:rw"
                                     % (CORPORA[0], CORPORA[0])),
       "rw mount αγγίζει releases")
mutate("εγγράψιμα κλειδιά",
       lambda m: m["volumes"].append("./keys:/app/keys:rw"), "ιδιωτικά κλειδιά")
mutate("λείπει candidates corpus",
       lambda m: m["volumes"].remove("./output/%s/candidates:/app/output/%s/candidates:rw"
                                     % (CORPORA[0], CORPORA[0])),
       "λείπει rw candidates")

print("\n── topology ΟΛΩΝ των services (ΔΗΛΩΜΕΝΗ· η ΕΚΤΕΛΕΣΗ απαιτεί docker daemon): "
      "%d passed, %d failed ──" % (passed, failed))
sys.exit(0 if failed == 0 else 1)
