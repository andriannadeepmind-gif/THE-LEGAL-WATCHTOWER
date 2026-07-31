#!/usr/bin/env python3
# Ανεξάρτητη διεργασία-αντίπαλος: αλλάζει το candidate ΤΑΥΤΟΧΡΟΝΑ με την capture.
# Τρέχει ώσπου να σκοτωθεί από τον γονέα. sys.argv: <candidate> <kind> <secret> <nfiles>
import os, sys, time
c, kind, secret, nf = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
i = 0
while True:
    t = os.path.join(c, "f%d.bin" % (i % nf))
    try:
        if kind == "rewrite":
            with open(t, "r+b") as fh:
                fh.seek(0); fh.write(b"Z" * 8192); fh.flush(); os.fsync(fh.fileno())
        elif kind == "swap-fifo":
            os.unlink(t); os.mkfifo(t); os.unlink(t)
            with open(t, "wb") as fh: fh.write(b"A" * 300_000)
        elif kind == "swap-hardlink":
            os.unlink(t); os.link(secret, t); os.unlink(t)
            with open(t, "wb") as fh: fh.write(b"A" * 300_000)
    except OSError:
        pass
    i += 1
