#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Ανεξάρτητη διεργασία-αντίπαλος: αλλάζει το candidate ΤΑΥΤΟΧΡΟΝΑ με την capture.
# Τρέχει ώσπου να σκοτωθεί από τον γονέα.
#   sys.argv: <candidate> <kind> <secret> <nfiles> <size>
#
# ΚΡΙΣΙΜΗ ΣΧΕΔΙΑΣΗ (ώστε το harness να ΜΠΟΡΕΙ να διακρίνει μόλυνση):
# κάθε εγγραφή είναι ΟΛΟΚΛΗΡΟΥ αρχείου με ΕΝΑ επαναλαμβανόμενο byte «γενιάς».
# Άρα ΚΑΘΕ νόμιμη κατάσταση του αρχείου είναι ομοιογενής· ΟΠΟΙΟΔΗΠΟΤΕ μείγμα
# δύο γενιών στο συλληφθέν αντίγραφο ΕΙΝΑΙ σχισμένη ανάγνωση — ανιχνεύσιμη.
#
# ΔΥΟ ΕΥΡΗΜΑΤΑ ΤΟΥ ΙΔΙΟΥ ΤΟΥ ΜΑΡΤΥΡΑ ΜΕΤΑΛΛΑΞΕΩΝ (και τα δύο έκαναν το σενάριο
# ΚΕΝΟ — η μετάλλαξη «κατάργηση fingerprint» επιζούσε):
#   ① αρχείο ΜΙΚΡΟΤΕΡΟ του chunk ανάγνωσης (1 MiB) διαβάζεται με ΜΙΑ os.read:
#      σχισμένη ανάγνωση ΦΥΣΙΚΑ αδύνατη. Το μέγεθος δίνεται τώρα από το harness
#      και είναι ΠΟΛΛΑΠΛΑΣΙΟ του chunk.
#   ② round-robin σε N αρχεία ΜΕ fsync: η γενιά ενός αρχείου άλλαζε μία φορά
#      ανά N ολικές εγγραφές, άρα σχεδόν ποτέ ΜΕΣΑ στο παράθυρο ανάγνωσης του
#      ΙΔΙΟΥ αρχείου. Τώρα ο αντίπαλος χτυπά ΕΝΑ «καυτό» αρχείο ασταμάτητα, με
#      ΔΙΑΦΟΡΕΤΙΚΗ γενιά σε κάθε επανάληψη και ΧΩΡΙΣ fsync (μέγιστος ρυθμός) —
#      η σχισμένη ανάγνωση γίνεται σχεδόν βέβαιη αν δεν υπάρχει ανίχνευση.
import os
import sys

c, kind, secret, nf = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
SIZE = int(sys.argv[5])
GENERATIONS = b"ABCDEFGH"
HOT = os.path.join(c, "f0.bin")     # το ΚΑΥΤΟ αρχείο — χτυπιέται σε κάθε γύρο
i = 0
while True:
    gen = GENERATIONS[i % len(GENERATIONS):][:1]
    try:
        if kind == "rewrite":
            # ΕΠΙΤΟΠΟΥ ολική επανεγγραφή: ίδιος inode, αλλάζει mtime/ctime.
            # ΧΩΡΙΣ fsync: ο στόχος είναι ΡΥΘΜΟΣ εναλλαγής, όχι ανθεκτικότητα.
            with open(HOT, "r+b") as fh:
                fh.seek(0)
                fh.write(gen * SIZE)
                fh.flush()
        elif kind == "swap-fifo":
            os.unlink(HOT)
            os.mkfifo(HOT)
            os.unlink(HOT)
            with open(HOT, "wb") as fh:
                fh.write(gen * SIZE)
        elif kind == "swap-hardlink":
            os.unlink(HOT)
            os.link(secret, HOT)        # απόπειρα διαρροής authority secret
            os.unlink(HOT)
            with open(HOT, "wb") as fh:
                fh.write(gen * SIZE)
    except OSError:
        pass
    i += 1
