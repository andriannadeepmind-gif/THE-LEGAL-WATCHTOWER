#!/usr/bin/env python3
"""ΜΙΑ ΕΔΡΑ ΓΙΑ ΤΗ ΓΡΑΜΜΑΤΙΚΗ ΠΑΡΑΠΟΜΠΩΝ.

Ο resolver ΚΑΙ ο canonicalizer διαβάζουν από ΕΔΩ. Δύο υλοποιήσεις του ίδιου
σαρωτή ήταν ακριβώς το σφάλμα που άφησε τη μετανάστευση ατελή: ο resolver
απέκτησε manifest-driven αναγνώριση ενώ ο canonicalizer κρατούσε τη στατική
λίστα επεκτάσεων, οπότε ό,τι δεν είχε «γνωστή» κατάληξη δεν κανονικοποιήθηκε
ποτέ και εμφανίστηκε ως legacy στην πύλη.

Ο ΑΝΕΞΑΡΤΗΤΟΣ ΕΠΑΛΗΘΕΥΤΗΣ ΔΕΝ ΕΙΣΑΓΕΙ ΑΥΤΟ ΤΟ ΑΡΧΕΙΟ. Έχει δική του
υλοποίηση — αυτό είναι το νόημα της ανεξαρτησίας.

ΜΟΡΦΗ (PROTOCOL-EPOCH-2): path:L<start>-L<end>@sha256:<12 πεζά δεκαεξαδικά>
"""
import re

SHA_LEN = 12

# Χαρακτήρες που ΤΕΡΜΑΤΙΖΟΥΝ ένα token. Ό,τι ΔΕΝ είναι εδώ μέσα (και δεν
# είναι τελεία-πρότασης) θεωρείται ΜΕΡΟΣ του token — άρα σκουπίδι που το
# ακυρώνει. «/», «%», «?», «#», «=» ΔΕΝ τερματίζουν.
# ΔΕΞΙΑ (τερματισμός token): το «:» ΔΕΝ τερματίζει όταν ακολουθείται από
# αλφαριθμητικό — αλλιώς θα έκοβε το «@sha256:<hex>». Όταν ακολουθείται από
# στίξη/κενό είναι τερματιστής.
TERMINATORS = set(' \t\n\r\f\v"\'`()[]{}<>;«»·|…')
# ΑΡΙΣΤΕΡΑ (όριο υποψήφιας διαδρομής): εκεί το «:» ΚΑΙ το «,» σταματούν πάντα.
PATH_STOP = TERMINATORS | {',', ':'}

CANONICAL = re.compile(r'\AL(?P<start>\d+)-L(?P<end>\d+)@sha256:(?P<sha>[0-9a-f]{12})\Z')
LEGACY = re.compile(r'\AL?(?P<start>\d+)(?:\s*-\s*L?(?P<end>\d+))?'
                    r'(?:@sha256:(?P<sha>[0-9a-fA-F]+))?\Z')
SPEC_START = re.compile(r'L?\d')
NUMERIC_RUN = re.compile(r'\A\d+(?:\.\d+)*\Z')

CODE_LEGACY = ("LEGACY-SHORTHAND — ΟΧΙ κανονιστική μορφή "
               "path:L<start>-L<end>@sha256:<12>")
CODE_MALFORMED = "ΚΑΚΟΣΧΗΜΑΤΙΣΜΕΝΗ ΠΑΡΑΠΟΜΠΗ — δεν ερμηνεύεται ούτε ως legacy"
CODE_UNKNOWN = "ΑΓΝΩΣΤΗ ΔΙΑΔΡΟΜΗ στο manifest"


# ══ ΑΝΑΓΝΩΡΙΣΗ — MANIFEST-DRIVEN, ΧΩΡΙΣ ΛΙΣΤΑ ΕΠΕΚΤΑΣΕΩΝ ═════════════════
def scan(text, index, basenames, mount):
    """Κάθε «<υποψήφιο>:<L?ψηφίο…>» είναι ΑΠΟΠΕΙΡΑ και κρίνεται.
    Επιστρέφει [(token, run, spec, tail, start_idx)]."""
    found, i, n = [], 0, len(text)
    mount_pre = mount + "/"
    while True:
        c = text.find(":", i)
        if c < 0:
            break
        i = c + 1
        if not SPEC_START.match(text, c + 1):
            continue
        j = c
        while j > 0 and text[j - 1] not in PATH_STOP:
            j -= 1
        run = text[j:c]
        if not run:
            continue
        # ΑΠΟΠΕΙΡΑ ΠΑΡΑΠΟΜΠΗΣ; — manifest-driven κρίση, ΟΧΙ λίστα επεκτάσεων
        base = run.rsplit("/", 1)[-1]
        attempt = (run in index or run.startswith(mount_pre)
                   or base in basenames
                   or ("/" in run and not NUMERIC_RUN.match(run)))
        if not attempt:
            continue
        # ΤΕΡΜΑΤΙΣΜΟΣ: μαζεύουμε ΟΛΟ ό,τι δεν είναι επιτρεπτός τερματιστής
        k, spec_end = c + 1, None
        while k < n:
            ch = text[k]
            if ch == "." and (k + 1 >= n or not text[k + 1].isalnum()):
                break
            if ch == "," and SPEC_START.match(text, k + 1):
                k += 1                       # ΛΙΣΤΑ ΚΟΜΜΑΤΟΣ — μέρος του token
                continue
            if ch == ":" and (k + 1 >= n or not text[k + 1].isalnum()):
                break                        # άνω τελεία στίξης, όχι «@sha256:»
            if ch in TERMINATORS or ch == ",":
                break
            k += 1
        blob = text[c + 1:k]
        m = re.match(r'\AL?\d+(?:\s*-\s*L?\d+)?(?:@sha256:[0-9a-fA-F]+)?', blob)
        spec = m.group(0) if m else blob
        tail = blob[len(spec):]
        found.append((run + ":" + blob, run, spec, tail, j))
    return found


def normalize(run, mount):
    if ".." in run.split("/"):
        return None, None, "PATH TRAVERSAL: περιέχει «..»"
    if run.startswith("/"):
        if not run.startswith(mount + "/"):
            return None, None, f"ΜΗ ΔΗΛΩΜΕΝΗ ΜΟΡΦΗ: absolute εκτός {mount}/"
        rest = run[len(mount) + 1:]
        if not rest:
            return None, None, "ΚΕΝΗ διαδρομή μετά το mount prefix"
        return rest, "mount-anchored", None
    return run, "corpus-relative", None


