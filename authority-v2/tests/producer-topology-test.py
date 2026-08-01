#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Η ΔΗΛΩΜΕΝΗ ΠΑΡΑΓΩΓΙΚΗ ΤΟΠΟΛΟΓΙΑ ΤΟΥ PRODUCER — ΕΛΕΓΜΕΝΗ, ΟΧΙ ΙΣΧΥΡΙΣΜΕΝΗ

ΕΤΥΜΗΓΟΡΙΑ ΔΗΜΙΟΥΡΓΟΥ: «Η πραγματική υπηρεσία εξακολουθεί να έχει ολόκληρο το
output ως rw και δεν ορίζει producer UID. Το authority-v2-proofs είναι μόνο
προνομιούχος εκτελεστής tests, όχι παραγωγική τοπολογία.»

Η υπηρεσία `producer` του docker-compose.yml ΟΦΕΙΛΕΙ να ικανοποιεί:
  ① user = ΚΑΡΦΩΜΕΝΟ uid του lawmax-producer (11002), όχι root, όχι αόριστο
  ② ./output προσαρτάται ΜΟΝΟ ΓΙΑ ΑΝΑΓΝΩΣΗ (άρα ΚΑΘΕ releases/ είναι ro)
  ③ ΚΑΘΕ corpus που έχει releases/ έχει το candidates/ του ως rw — αλλιώς ο
     παραγωγός δεν θα μπορούσε να δουλέψει και η τοπολογία θα ήταν ψευδώς
     «ασφαλής» επειδή δεν κάνει τίποτα (ΘΕΤΙΚΟΣ ΜΑΡΤΥΡΑΣ)
  ④ ΚΑΝΕΝΑ rw mount δεν αγγίζει διαδρομή releases/
  ⑤ ΚΑΝΕΝΑ mount προς τον authority store (/var/lib/lawmax/authority)
  ⑥ read_only rootfs, cap_drop ALL, no-new-privileges

ΤΙΜΙΟ ΟΡΙΟ — ΔΗΛΩΝΕΤΑΙ ΡΗΤΑ: αυτό ελέγχει τη ΔΗΛΩΜΕΝΗ τοπολογία (το αρχείο
compose), ΟΧΙ έναν εκτελούμενο container. Η εκτέλεση απαιτεί docker daemon και
δηλώνεται χωριστά ως BLOCKED όπου δεν υπάρχει. Ένα ψευδές compose δεν μπορεί
πλέον να περάσει σιωπηλά· ένα σωστό compose ΔΕΝ αποδεικνύει από μόνο του
τρέχουσα υπηρεσία.

ΜΗ ΚΕΝΟΤΗΤΑ: ο ΙΔΙΟΣ ελεγκτής τρέχει και πάνω σε ΜΕΤΑΛΛΑΓΜΕΝΑ compose (output
rw / root user / authority store mounted) και ΟΦΕΙΛΕΙ να τα απορρίψει.
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
PRODUCER_UID = "11002"
AUTHORITY_STORE = "/var/lib/lawmax/authority"

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
    """(source, target, mode) για κάθε mount — και οι δύο συντάξεις."""
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


def check(svc, corpora):
    """Επιστρέφει λίστα παραβιάσεων (κενή = συμμορφούμενη τοπολογία)."""
    bad = []
    if str(svc.get("user", "")).split(":")[0] != PRODUCER_UID:
        bad.append("user=%r ≠ %s (lawmax-producer)" % (svc.get("user"), PRODUCER_UID))
    mounts = parse_mounts(svc)
    out_ro = [m for m in mounts if m[1] == "/app/output" and m[2] == "ro"]
    if not out_ro:
        bad.append("το /app/output ΔΕΝ είναι προσαρτημένο read-only")
    for src, tgt, mode in mounts:
        if mode != "ro" and "/releases" in (src + " " + tgt):
            bad.append("rw mount αγγίζει releases: %s→%s" % (src, tgt))
        if AUTHORITY_STORE in src or AUTHORITY_STORE in tgt:
            bad.append("ο authority store είναι προσαρτημένος: %s→%s" % (src, tgt))
    rw_targets = {t for _, t, m in mounts if m != "ro"}
    for c in corpora:
        want = "/app/output/%s/candidates" % c
        if want not in rw_targets:
            bad.append("λείπει rw candidates για το corpus %s" % c)
    if svc.get("read_only") is not True:
        bad.append("read_only rootfs ΔΕΝ δηλώθηκε")
    if svc.get("cap_drop") != ["ALL"]:
        bad.append("cap_drop ≠ [ALL] (got=%r)" % (svc.get("cap_drop"),))
    if "no-new-privileges:true" not in (svc.get("security_opt") or []):
        bad.append("no-new-privileges ΔΕΝ δηλώθηκε")
    return bad


with open(COMPOSE, encoding="utf-8") as fh:
    doc = yaml.safe_load(fh)
svc = doc.get("services", {}).get("producer")
if svc is None:
    print("  FAIL δεν υπάρχει υπηρεσία `producer` στο docker-compose.yml")
    sys.exit(1)

# Τα corpora ΠΑΡΑΓΟΝΤΑΙ από τον δίσκο — καμία χειρόγραφη λίστα που ξεμένει πίσω.
CORPORA = sorted(c for c in os.listdir(os.path.join(REPO, "output"))
                 if os.path.isdir(os.path.join(REPO, "output", c, "releases")))

print("== Η ΔΗΛΩΜΕΝΗ ΤΟΠΟΛΟΓΙΑ ΤΟΥ producer ==")
print("   corpora με releases/ (από τον δίσκο): %s" % ", ".join(CORPORA))
violations = check(svc, CORPORA)
if violations:
    for v in violations:
        no("ΠΑΡΑΒΙΑΣΗ: " + v)
else:
    ok("user=%s · /app/output ro · μόνο candidates rw · κανένα authority store · "
       "read_only+cap_drop ALL+no-new-privileges" % PRODUCER_UID)
    ok("ΘΕΤΙΚΟΣ ΜΑΡΤΥΡΑΣ: και τα %d corpora με releases/ έχουν εγγράψιμο candidates/"
       % len(CORPORA))

print("\n== ΜΗ ΚΕΝΟΤΗΤΑ: ΜΕΤΑΛΛΑΓΜΕΝΕΣ ΤΟΠΟΛΟΓΙΕΣ ΠΡΕΠΕΙ ΝΑ ΑΠΟΡΡΙΠΤΟΝΤΑΙ ==")


def mutate(name, fn, expect_token):
    m = copy.deepcopy(svc)
    fn(m)
    bad = check(m, CORPORA)
    if any(expect_token in b for b in bad):
        ok("%s ⇒ ΑΠΟΡΡΙΨΗ («%s»)" % (name, expect_token))
    else:
        no("%s ⇒ ΕΓΙΝΕ ΔΕΚΤΗ (παραβιάσεις: %s)" % (name, bad))


def _output_rw(m):
    for v in m["volumes"]:
        if isinstance(v, str) and v.endswith("/app/output:ro"):
            m["volumes"][m["volumes"].index(v)] = v[:-3]


mutate("ΟΛΟ το output ως rw", _output_rw, "read-only")
mutate("τρέξιμο ως root", lambda m: m.update(user="0:0"), "user=")
mutate("προσάρτηση authority store",
       lambda m: m["volumes"].append("%s:%s:rw" % (AUTHORITY_STORE, AUTHORITY_STORE)),
       "authority store")
mutate("εγγράψιμο releases",
       lambda m: m["volumes"].append("./output/%s/releases:/app/output/%s/releases:rw"
                                     % (CORPORA[0], CORPORA[0])),
       "rw mount αγγίζει releases")
mutate("χωρίς read_only rootfs", lambda m: m.update(read_only=False), "read_only")
mutate("χωρίς cap_drop ALL", lambda m: m.update(cap_drop=["NET_RAW"]), "cap_drop")
mutate("χωρίς no-new-privileges", lambda m: m.update(security_opt=[]),
       "no-new-privileges")

print("\n── producer topology (ΔΗΛΩΜΕΝΗ· η ΕΚΤΕΛΕΣΗ απαιτεί docker daemon): "
      "%d passed, %d failed ──" % (passed, failed))
sys.exit(0 if failed == 0 else 1)
