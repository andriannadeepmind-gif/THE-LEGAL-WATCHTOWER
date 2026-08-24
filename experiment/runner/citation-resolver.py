#!/usr/bin/env python3
"""ΠΥΛΗ ΠΑΡΑΠΟΜΠΩΝ (versioned gate) — κάθε ισχυρισμός λύνεται στο παγωμένο
corpus ή η φάση κοκκινίζει.

ΓΙΑΤΙ ΥΠΑΡΧΕΙ: ένας πράκτορας μπορεί να γράψει οτιδήποτε. Το μόνο που δεν
μπορεί να πλαστογραφήσει είναι μια παραπομπή που ΛΥΝΕΤΑΙ σε αρχείο, γραμμή και
hash του σφραγισμένου manifest. Ό,τι δεν λύνεται ΔΕΝ είναι ισχυρισμός.

ΤΙΜΙΟ ΟΡΙΟ, ΔΗΛΩΜΕΝΟ: ΔΕΝ είναι read-ledger. Δεν αποδεικνύει ΤΙ ΔΙΑΒΑΣΕ ο
πράκτορας — αποδεικνύει ότι κάθε ΙΣΧΥΡΙΣΜΟΣ αγκυρώνεται σε υπαρκτό σημείο.

ΚΑΝΟΝΙΚΟΠΟΙΗΣΗ ΔΙΑΔΡΟΜΩΝ — ΔΗΛΩΜΕΝΗ, ΟΧΙ ΕΥΡΕΤΙΚΗ (EARLY CORRECTION §4):
  ① Το ΜΟΝΟ αποδεκτό absolute πρόθεμα είναι ΑΚΡΙΒΩΣ "/frozen/ro/" — το
     δηλωμένο read-only mount του παγωμένου commit. Κάθε άλλο absolute
     (/app/, /frozen/watchtower/, /tmp/, /etc/…) ΑΠΟΡΡΙΠΤΕΤΑΙ ονομαστικά.
  ② Κάθε διαδρομή με ".." ΑΠΟΡΡΙΠΤΕΤΑΙ (path traversal) πριν από κάθε άλλη
     επεξεργασία.
  ③ Cluster-relative επίλυση ΜΟΝΟ ως προς το ΣΦΡΑΓΙΣΜΕΝΟ cluster_root της
     συγκεκριμένης lane (--lane). ΠΟΤΕ με μαντεψιά προθέματος.
  ④ Το canonical path ΠΡΕΠΕΙ να υπάρχει στο frozen manifest. Symlink escape
     είναι δομικά αδύνατο: το manifest απαριθμεί ΜΟΝΟ πραγματικά μέλη του
     παγωμένου δέντρου, με τα symlinks σημασμένα — και απορρίπτονται ρητά.

Μορφές: path:123 · path:L10-L42 · path:L10-L42@sha256:0123456789ab
Έξοδος 0 ΜΟΝΟ αν ΚΑΘΕ παραπομπή λύνεται. Κενή είσοδος ⇒ σφάλμα.
"""
import hashlib
import os
import re
import sys

RESOLVER_VERSION = "3"
MANIFEST = "experiment/artifacts/corpus-manifest.tsv"
REGISTRY = "experiment/phase1a/LANE-REGISTRY.sexp"

# ΤΟ ΕΝΑ ΚΑΙ ΜΟΝΟ αποδεκτό absolute πρόθεμα.
FROZEN_MOUNT = "/frozen/ro/"

CITATION = re.compile(
    # (?<![\w./-]) αντί για \b: το \b δεν πιάνει διαδρομές με αρχικό «.»
    # (π.χ. .github/workflows/…) — εντοπίστηκε σε πραγματικό dossier.
    r'(?<![\w./-])(/?\.?[A-Za-z0-9_./\-Ͱ-Ͽ]+\.'
    r'(?:lisp|asd|md|sexp|sh|py|js|mjs|ts|json|jsonld|yml|yaml|ttl|txt|cddl|zip))'
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
            rel, kind, sha, _bytes, lines, _cls = parts[:6]
            index[rel] = (sha, int(lines), kind)
    return index


def load_cluster_root(lane_id):
    """Το cluster_root ΔΙΑΒΑΖΕΤΑΙ από το σφραγισμένο registry — δεν μαντεύεται."""
    if not os.path.exists(REGISTRY):
        return None
    text = open(REGISTRY, encoding="utf-8").read()
    m = re.search(r':lane\s+"' + re.escape(lane_id) + r'".*?:cluster-root\s+"([^"]*)"',
                  text, re.S)
    return m.group(1) if m else None


def normalize(raw):
    """Επιστρέφει (canonical_path | None, reason_if_rejected). Δηλωμένοι κανόνες."""
    if ".." in raw.split("/"):
        return None, "PATH TRAVERSAL: περιέχει «..»"
    if raw.startswith("/"):
        if not raw.startswith(FROZEN_MOUNT):
            return None, f"ΜΗ ΑΠΟΔΕΚΤΟ ABSOLUTE ΠΡΟΘΕΜΑ (μόνο {FROZEN_MOUNT})"
        return raw[len(FROZEN_MOUNT):], None
    return raw, None


def main():
    if not os.path.exists(MANIFEST):
        print(f"::error::ΑΠΩΝ το corpus manifest: {MANIFEST}")
        return 2
    args = list(sys.argv[1:])
    lane_id = None
    if "--lane" in args:
        i = args.index("--lane")
        lane_id = args[i + 1] if i + 1 < len(args) else None
        del args[i:i + 2]
    cluster_root = load_cluster_root(lane_id) if lane_id else None

    index = load_manifest(MANIFEST)
    manifest_sha = hashlib.sha256(open(MANIFEST, "rb").read()).hexdigest()
    self_sha = hashlib.sha256(open(__file__, "rb").read()).hexdigest()
    targets = [p for p in args if os.path.isfile(p)]
    if not targets:
        print("::error::ΚΑΜΙΑ είσοδος — καμία ψευδο-επιτυχία")
        return 2

    total = resolved = 0
    problems = []
    for path in targets:
        text = open(path, encoding="utf-8", errors="replace").read()
        seen = set()
        for m in CITATION.finditer(text):
            raw, start = m.group(1), int(m.group(2))
            end, sha12 = m.group(3), m.group(4)
            key = (raw, start, end, sha12)
            if key in seen:
                continue
            seen.add(key)
            total += 1

            rel, why = normalize(raw)
            if rel is None:
                problems.append((path, m.group(0), why))
                continue
            if rel not in index and cluster_root:
                cand = f"{cluster_root.rstrip('/')}/{rel}"
                if cand in index:
                    rel = cand
            if rel not in index:
                problems.append((path, m.group(0), "ΑΓΝΩΣΤΗ ΔΙΑΔΡΟΜΗ στο manifest"))
                continue
            sha, nlines, kind = index[rel]
            if kind == "symlink":
                problems.append((path, m.group(0), "SYMLINK — δεν παραπέμπουμε σε σύνδεσμο"))
                continue
            # Το manifest μετράει newlines· αρχείο χωρίς τελικό newline έχει μία
            # γραμμή παραπάνω. Ανώτατο αποδεκτό: nlines+1.
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

    print(f"resolver v{RESOLVER_VERSION} sha256:{self_sha[:16]} · "
          f"manifest sha256:{manifest_sha[:16]} · lane={lane_id or '—'}")
    print(f"παραπομπές: {total} · λύθηκαν: {resolved} · ΠΡΟΒΛΗΜΑΤΙΚΕΣ: {len(problems)}")
    for src, cit, why in problems:
        print(f"  ✗ [{src}] {cit} — {why}")
    if total == 0:
        print("::error::ΜΗΔΕΝ παραπομπές — ισχυρισμοί χωρίς άγκυρα δεν γίνονται δεκτοί")
        return 2
    return 1 if problems else 0


sys.exit(main())
