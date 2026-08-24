#!/usr/bin/env python3
"""ΠΥΛΗ ΠΑΡΑΠΟΜΠΩΝ — κάθε ισχυρισμός λύνεται στο παγωμένο corpus ή η φάση κοκκινίζει.

ΓΙΑΤΙ ΥΠΑΡΧΕΙ: ένας πράκτορας μπορεί να γράψει οτιδήποτε. Το μόνο που δεν μπορεί
να πλαστογραφήσει είναι μια παραπομπή που ΛΥΝΕΤΑΙ σε αρχείο, γραμμή και hash του
σφραγισμένου manifest. Ό,τι δεν λύνεται ΔΕΝ είναι ισχυρισμός — είναι αφήγηση.

ΤΙΜΙΟ ΟΡΙΟ, ΔΗΛΩΜΕΝΟ: αυτό ΔΕΝ είναι read-ledger. Δεν αποδεικνύει ΤΙ ΔΙΑΒΑΣΕ ο
πράκτορας — αποδεικνύει ότι κάθε ΙΣΧΥΡΙΣΜΟΣ του αγκυρώνεται σε πραγματικό,
υπαρκτό σημείο του παγωμένου δέντρου. Το πρώτο δεν είναι διαθέσιμο για
υποπράκτορες· το δεύτερο είναι, και είναι αυτό που κρίνει.

Μορφές που δέχεται:
    path:123
    path:L10-L42
    path:L10-L42@sha256:0123456789ab
Έξοδος 0 ΜΟΝΟ αν ΚΑΘΕ παραπομπή λύνεται. Κενή είσοδος ⇒ σφάλμα (καμία
«επαληθεύτηκαν 0» ψευδο-επιτυχία).
"""
import os
import re
import sys

MANIFEST = "experiment/artifacts/corpus-manifest.tsv"

CITATION = re.compile(
    # (?<![\w.]) αντί για \b: το \b ΔΕΝ πιάνει διαδρομές που αρχίζουν με «.»
    # (π.χ. .github/workflows/…) — εντοπίστηκε σε πραγματικό dossier της Φ1A-L7.
    r'(?<![\w./-])(\.?[A-Za-z0-9_./\-Ͱ-Ͽ]+\.(?:lisp|asd|md|sexp|sh|py|js|json|yml|yaml|ttl|txt|jsonld))'
    r':L?(\d+)(?:\s*-\s*L?(\d+))?'
    r'(?:@sha256:([0-9a-f]{6,64}))?'
)

def load_manifest(path):
    index = {}
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            if line.startswith("#"):
                continue
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 6:
                continue
            rel, _kind, sha, _bytes, lines, _cls = parts[:6]
            index[rel] = (sha, int(lines))
    return index

def main():
    if not os.path.exists(MANIFEST):
        print(f"::error::ΑΠΩΝ το corpus manifest: {MANIFEST}")
        return 2
    index = load_manifest(MANIFEST)
    targets = [p for p in sys.argv[1:] if os.path.isfile(p)]
    if not targets:
        print("::error::ΚΑΜΙΑ είσοδος — καμία ψευδο-επιτυχία")
        return 2

    total = resolved = 0
    problems = []
    for path in targets:
        text = open(path, encoding="utf-8", errors="replace").read()
        seen = set()
        for m in CITATION.finditer(text):
            rel, start, end, sha12 = m.group(1), int(m.group(2)), m.group(3), m.group(4)
            key = (rel, start, end, sha12)
            if key in seen:
                continue
            seen.add(key)
            total += 1
            if rel not in index:
                problems.append((path, m.group(0), "ΑΓΝΩΣΤΗ ΔΙΑΔΡΟΜΗ στο manifest"))
                continue
            sha, nlines = index[rel]
            # Το manifest μετράει newlines· ένα αρχείο χωρίς τελικό newline έχει
            # μία γραμμή παραπάνω από τα newlines. Δεχόμαστε nlines+1 ως ανώτατο.
            limit = nlines + 1
            hi = int(end) if end else start
            if start < 1 or hi > limit:
                problems.append((path, m.group(0),
                                 f"ΕΚΤΟΣ ΕΥΡΟΥΣ: το αρχείο έχει {nlines} newlines (όριο {limit})"))
                continue
            if end and int(end) < start:
                problems.append((path, m.group(0), "ΑΝΑΠΟΔΟ ΕΥΡΟΣ"))
                continue
            if sha12 and not sha.startswith(sha12):
                problems.append((path, m.group(0), f"ΛΑΘΟΣ HASH: manifest {sha[:12]}"))
                continue
            resolved += 1

    print(f"παραπομπές: {total} · λύθηκαν: {resolved} · ΠΡΟΒΛΗΜΑΤΙΚΕΣ: {len(problems)}")
    for src, cit, why in problems:
        print(f"  ✗ [{src}] {cit} — {why}")
    if total == 0:
        print("::error::ΜΗΔΕΝ παραπομπές βρέθηκαν — ισχυρισμοί χωρίς άγκυρα δεν γίνονται δεκτοί")
        return 2
    return 1 if problems else 0

sys.exit(main())
