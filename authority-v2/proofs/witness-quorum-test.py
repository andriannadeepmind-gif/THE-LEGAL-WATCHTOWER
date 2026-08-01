#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ΠΥΛΗ: Η ΠΟΛΙΤΙΚΗ ΚΒΟΡΟΥΜ/ΦΡΕΣΚΑΔΑΣ ΕΙΝΑΙ ΦΕΡΟΥΣΑ (απαίτηση 8, μέρος)

Ασκεί την πολιτική με ΤΟΠΙΚΟΥΣ FAKE witnesses. Το κρίσιμο που αποδεικνύεται:
  · fake witnesses ΔΕΝ μετρούν ποτέ στο κβόρουμ (δομικά, όχι κατά σύμβαση)
  · μάρτυρες που μοιράζονται φορέα/υποδομή μετρούν ΩΣ ΕΝΑΣ
  · έγκυρο ΑΛΛΑ παλιό checkpoint ΑΠΟΡΡΙΠΤΕΤΑΙ (anti-freeze)
  · ένας μάρτυρας που βλέπει ΑΝΤΙΦΑΤΙΚΗ εικόνα ρίχνει το κβόρουμ
  · με external_quorum_status=disabled, η πύλη είναι ΑΝΕΝΕΡΓΗ — ΟΧΙ «0-of-3 ok»

ΔΕΝ αγγίζει wire format: τα checkpoints είναι ΑΔΙΑΦΑΝΗ bytes (το C2SP format
παραμένει BLOCKED-SPEC-INPUT).
"""
import sys

MAX_CHECKPOINT_AGE = 86400
MAX_OBSERVATION_LAG = 3600
REQUIRED_SIGNATURES = 3

passed = failed = 0


def ok(m):
    global passed
    passed += 1
    print("  ok   " + m)


def no(m):
    global failed
    failed += 1
    print("  FAIL " + m)


class Witness:
    """Format-agnostic μάρτυρας: δεσμεύεται σε ΑΔΙΑΦΑΝΗ bytes."""

    def __init__(self, wid, operator, network, independent, sees=None):
        self.wid, self.operator, self.network = wid, operator, network
        self.independent = independent          # ΠΡΑΓΜΑΤΙΚΑ ανεξάρτητος;
        self.sees = sees                        # τι εικόνα βλέπει (None = ό,τι του δοθεί)

    def cosign(self, checkpoint_bytes, observed_at, now):
        if self.sees is not None and self.sees != checkpoint_bytes:
            return ("refused-inconsistent", None)
        if now - observed_at > MAX_OBSERVATION_LAG:
            return ("refused-stale", None)
        return ("ok", "sig(%s)" % self.wid)


def evaluate_quorum(witnesses, checkpoint_bytes, checkpoint_age, observed_at, now,
                    external_enabled):
    """Η ΠΟΛΙΤΗ ΚΡΙΣΗ. Επιστρέφει (accepted?, reason)."""
    # 1. Αν το external quorum είναι ανενεργό, η πύλη ΔΕΝ ικανοποιείται — ποτέ
    #    «0-of-3 ok». Αυτό είναι το τρέχον πραγματικό state.
    if not external_enabled:
        return (False, "external_quorum_status=disabled — η πύλη είναι ΑΝΕΝΕΡΓΗ")
    # 2. Anti-freeze: η εγκυρότητα δεν είναι φρεσκάδα.
    if checkpoint_age > MAX_CHECKPOINT_AGE:
        return (False, "checkpoint παλαιότερο του ορίου (%ds)" % checkpoint_age)
    # 3. Συλλογή υπογραφών.
    signed = []
    for w in witnesses:
        status, sig = w.cosign(checkpoint_bytes, observed_at, now)
        if status == "ok":
            signed.append(w)
        elif status == "refused-inconsistent":
            return (False, "μάρτυρας %s είδε ΑΝΤΙΦΑΤΙΚΗ εικόνα" % w.wid)
    # 4. ΜΟΝΟ πραγματικά ανεξάρτητοι μετρούν· κοινός φορέας/δίκτυο ⇒ ΕΝΑΣ.
    groups = set()
    for w in signed:
        if not w.independent:
            continue
        groups.add((w.operator, w.network))
    if len(groups) < REQUIRED_SIGNATURES:
        return (False, "ανεξάρτητοι φορείς %d < %d" % (len(groups), REQUIRED_SIGNATURES))
    return (True, "quorum %d/%d" % (len(groups), REQUIRED_SIGNATURES))


CP = b"opaque-checkpoint-bytes"
NOW = 1_000_000

real = [Witness("w%d" % i, "op%d" % i, "net%d" % i, True) for i in (1, 2, 3)]
fakes = [Witness("f%d" % i, "local", "local", False) for i in (1, 2, 3)]

print("== ΤΟ ΤΡΕΧΟΝ ΠΡΑΓΜΑΤΙΚΟ STATE ==")
acc, why = evaluate_quorum(real, CP, 10, NOW, NOW, external_enabled=False)
(ok if not acc else no)("external disabled ⇒ ΑΝΕΝΕΡΓΗ πύλη, όχι ψευδο-επιτυχία (%s)" % why)

print("\n== FAKE WITNESSES ΔΕΝ ΜΕΤΡΟΥΝ ΠΟΤΕ ==")
acc, why = evaluate_quorum(fakes, CP, 10, NOW, NOW, external_enabled=True)
(ok if not acc else no)("3 fake witnesses ⇒ ΔΕΝ σχηματίζουν κβόρουμ (%s)" % why)
acc, why = evaluate_quorum(real[:2] + fakes, CP, 10, NOW, NOW, external_enabled=True)
(ok if not acc else no)("2 πραγματικοί + 3 fake ⇒ ΔΕΝ φτάνει (%s)" % why)

print("\n== ΑΝΕΞΑΡΤΗΣΙΑ, ΟΧΙ ΠΛΗΘΟΣ ==")
shared = [Witness("s1", "opX", "netX", True), Witness("s2", "opX", "netX", True),
          Witness("s3", "opY", "netY", True)]
acc, why = evaluate_quorum(shared, CP, 10, NOW, NOW, external_enabled=True)
(ok if not acc else no)("3 μάρτυρες αλλά 2 μοιράζονται φορέα ⇒ μετρούν ως 2 (%s)" % why)
acc, why = evaluate_quorum(real, CP, 10, NOW, NOW, external_enabled=True)
(ok if acc else no)("3 ΠΡΑΓΜΑΤΙΚΑ ανεξάρτητοι ⇒ κβόρουμ (%s)" % why)

print("\n== ANTI-FREEZE: η εγκυρότητα ΔΕΝ είναι φρεσκάδα ==")
acc, why = evaluate_quorum(real, CP, MAX_CHECKPOINT_AGE + 1, NOW, NOW, external_enabled=True)
(ok if not acc else no)("έγκυρο ΑΛΛΑ παλιό checkpoint ⇒ ΑΠΟΡΡΙΨΗ (%s)" % why)
acc, why = evaluate_quorum(real, CP, 10, NOW - MAX_OBSERVATION_LAG - 1, NOW, external_enabled=True)
(ok if not acc else no)("παλιά παρατήρηση μάρτυρα ⇒ ΑΠΟΡΡΙΨΗ (%s)" % why)

print("\n== SPLIT VIEW: ένας μάρτυρας που είδε ΑΛΛΟ, ρίχνει τα πάντα ==")
divergent = real[:2] + [Witness("w3", "op3", "net3", True, sees="ΑΛΛΗ-ΕΙΚΟΝΑ".encode("utf-8"))]
acc, why = evaluate_quorum(divergent, CP, 10, NOW, NOW, external_enabled=True)
(ok if not acc else no)("αντιφατική εικόνα ⇒ ΑΠΟΡΡΙΨΗ, όχι 2-of-3 (%s)" % why)

print("\n── witness quorum policy: %d passed, %d failed ──" % (passed, failed))
sys.exit(0 if failed == 0 else 1)
