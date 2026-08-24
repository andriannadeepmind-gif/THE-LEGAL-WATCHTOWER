#!/usr/bin/env python3
"""ΑΠΟΓΡΑΦΗ ΠΑΓΩΜΕΝΟΥ CORPUS — schema 3. ΜΙΑ ΕΔΡΑ ΓΙΑ ΤΗΝ ΤΑΥΤΟΤΗΤΑ ΤΟΥ CORPUS.

ΤΙ ΑΛΛΑΞΕ ΑΠΟ ΤΟ schema 2 ΚΑΙ ΓΙΑΤΙ
────────────────────────────────────
Το schema 2 απαριθμούσε με os.walk. Το os.walk ΔΕΝ αποδίδει symlink-προς-
κατάλογο ούτε ως αρχείο ούτε ως κατάλογο-προς-κάθοδο: τα ΕΞΑΦΑΝΙΖΕΙ. Έτσι
έλειπαν ΕΞΙ εγγραφές (35.634 αντί 35.640) — και οι έξι mode 120000:
    output/{astikos,constitution,kdioikitikis,kpoinikis,kpolitikis,poinikos}/releases/latest
Η απαρίθμηση ΔΕΝ γίνεται πλέον από το filesystem. Γίνεται από το ΙΔΙΟ ΤΟ GIT
TREE του παγωμένου commit, που είναι η μόνη αυθεντική λίστα.

ΤΡΙΠΛΟ ΔΕΣΙΜΟ ΑΝΑ ΕΓΓΡΑΦΗ
─────────────────────────
  ① ΑΠΑΡΙΘΜΗΣΗ : git ls-tree -r -z --full-tree <commit>  (path, mode, blob sha1)
  ② ΠΕΡΙΕΧΟΜΕΝΟ: διαβάζεται από το ΠΑΓΩΜΕΝΟ read-only mount, ΟΧΙ από το git
  ③ ΤΑΥΤΙΣΗ    : από το περιεχόμενο του mount ΞΑΝΑΫΠΟΛΟΓΙΖΕΤΑΙ το git blob sha1
                 (sha1("blob <len>\\0" + bytes)) και απαιτείται να ΤΑΥΤΙΖΕΤΑΙ
                 με αυτό του tree. Άρα αποδεικνύεται ΑΝΑ ΔΙΑΔΡΟΜΗ ότι το mount
                 ΕΙΝΑΙ ο παγωμένος commit — χωρίς να εμπιστευόμαστε το git για
                 το περιεχόμενο ούτε το mount για την πληρότητα.

ΤΑ SYMLINKS ΔΕΝ ΑΚΟΛΟΥΘΟΥΝΤΑΙ. Καταγράφονται ως symlink με ΣΤΟΧΟ, και το
περιεχόμενό τους (κατά git) ΕΙΝΑΙ η συμβολοσειρά του στόχου.

ΤΑΥΤΟΤΗΤΑ: PATH-AND-KIND-COMPLETE. Το φύλλο δεσμεύεται σε path + mode + kind +
content hash + μέγεθος — ΟΧΙ μόνο σε περιεχόμενο. Δύο δέντρα με ίδια αρχεία σε
διαφορετικές διαδρομές, ή με αρχείο μετατραπέν σε symlink, ΔΙΝΟΥΝ ΑΛΛΗ ΡΙΖΑ.
"""
import hashlib
import os
import subprocess
import sys

SCHEMA = 3
COMMIT = "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
MOUNT = "/frozen/ro"
REPO = "/home/user/THE-LEGAL-WATCHTOWER"
COLUMNS = ("path", "git_mode", "kind", "git_blob_sha1", "content_sha256",
           "bytes", "logical_lines", "trailing_newline", "class")

MODE_KIND = {"100644": "file", "100755": "executable", "120000": "symlink"}
LINES_BINARY = -1
LINES_SYMLINK = -2


def die(msg):
    print(f"::error::{msg}", file=sys.stderr)
    sys.exit(2)


def git_blob_sha1(data):
    h = hashlib.sha1()
    h.update(b"blob %d\0" % len(data))
    h.update(data)
    return h.hexdigest()


def enumerate_tree():
    """① Η ΑΥΘΕΝΤΙΚΗ απαρίθμηση — το git tree, όχι το filesystem."""
    out = subprocess.run(
        ["git", "-C", REPO, "ls-tree", "-r", "-z", "--full-tree", COMMIT],
        capture_output=True, check=True).stdout
    entries = []
    for rec in out.split(b"\0"):
        if not rec:
            continue
        meta, _, path = rec.partition(b"\t")
        mode, otype, sha = meta.split(b" ")
        mode, otype, sha = mode.decode(), otype.decode(), sha.decode()
        if otype != "blob":
            die(f"ΜΗ ΑΝΑΜΕΝΟΜΕΝΟΣ ΤΥΠΟΣ «{otype}» στο {path!r} — "
                f"το schema 3 δηλώνει ΜΟΝΟ blobs· submodule/commit θα απαιτούσε ρητή απόφαση")
        if mode not in MODE_KIND:
            die(f"ΑΓΝΩΣΤΟ git mode «{mode}» στο {path!r}")
        entries.append((path, mode, sha))
    entries.sort(key=lambda e: e[0])          # ΔΗΛΩΜΕΝΗ σειρά: raw path bytes
    return entries


def classify(data, kind):
    if kind == "symlink":
        return "symlink", LINES_SYMLINK, 0
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        return "binary", LINES_BINARY, 0
    if "\0" in text:
        return "binary", LINES_BINARY, 0
    if text == "":
        return "text", 0, 1
    trailing = 1 if text.endswith("\n") else 0
    nl = text.count("\n")
    return "text", (nl if trailing else nl + 1), trailing


def leaf_preimage(path_b, mode, kind, content_sha256_hex, nbytes):
    """ΜΗΚΟΣ-ΠΡΟΘΕΜΑΤΙΣΜΕΝΗ κωδικοποίηση — καμία αμφισημία ακόμη κι αν μια
    διαδρομή περιέχει διαχωριστικά. Δεσμεύει path ΚΑΙ mode ΚΑΙ kind."""
    def lp(b):
        return len(b).to_bytes(4, "big") + b
    return (lp(path_b) + lp(mode.encode()) + lp(kind.encode())
            + bytes.fromhex(content_sha256_hex) + nbytes.to_bytes(8, "big"))


def merkle(leaves):
    """RFC 6962/9162 §2.1.1. ΑΥΣΤΗΡΗ δύναμη του 2 στο σπάσιμο.
    ΠΟΤΕ duplicate-last (CVE-2012-2459)."""
    if not leaves:
        return hashlib.sha256(b"").hexdigest()
    if len(leaves) == 1:
        return leaves[0]
    k = 1
    while k * 2 < len(leaves):
        k *= 2
    left = bytes.fromhex(merkle(leaves[:k]))
    right = bytes.fromhex(merkle(leaves[k:]))
    return hashlib.sha256(b"\x01" + left + right).hexdigest()


def mount_options(target):
    """ΑΥΘΕΝΤΙΚΗ πηγή: /proc/self/mountinfo. ΟΧΙ os.path.ismount — αυτό συγκρίνει
    st_dev γονέα/παιδιού και ΑΠΟΤΥΓΧΑΝΕΙ σε bind mount στο ΙΔΙΟ filesystem,
    που είναι ακριβώς η περίπτωσή μας. Επιστρέφει το σύνολο επιλογών ή None."""
    with open("/proc/self/mountinfo", encoding="utf-8") as fh:
        for line in fh:
            f = line.split()
            if len(f) > 5 and f[4] == target:
                return set(f[5].split(","))
    return None


def require_frozen_mount():
    opts = mount_options(MOUNT)
    if opts is None:
        die(f"ΤΟ {MOUNT} ΔΕΝ ΕΙΝΑΙ MOUNT (καμία εγγραφή στο /proc/self/mountinfo). "
            f"Τρέξε πρώτα ensure-ro-mount.sh. Τα mounts ΔΕΝ επιβιώνουν μεταξύ "
            f"κλήσεων σε αυτό το περιβάλλον — η πύλη μπαίνει ΚΑΘΕ φορά.")
    if "ro" not in opts:
        die(f"ΤΟ {MOUNT} ΕΙΝΑΙ MOUNT ΑΛΛΑ ΟΧΙ read-only: {sorted(opts)}")
    return opts


def main():
    require_frozen_mount()
    entries = enumerate_tree()
    rows, leaves = [], []
    counts = {"file": 0, "executable": 0, "symlink": 0}
    mismatches = []

    for path_b, mode, blob_sha in entries:
        kind = MODE_KIND[mode]
        counts[kind] += 1
        rel = path_b.decode("utf-8", errors="surrogateescape")
        full = os.path.join(MOUNT, rel)
        st = os.lstat(full)                    # ΠΟΤΕ stat — δεν ακολουθούμε symlink

        if kind == "symlink":
            data = os.readlink(full).encode("utf-8")
            if not (st.st_mode & 0o170000) == 0o120000:
                mismatches.append((rel, "ΤΟ TREE ΛΕΕΙ symlink, ΤΟ MOUNT ΟΧΙ"))
        else:
            if (st.st_mode & 0o170000) != 0o100000:
                mismatches.append((rel, "ΤΟ TREE ΛΕΕΙ κανονικό αρχείο, ΤΟ MOUNT ΟΧΙ"))
                continue
            with open(full, "rb") as fh:
                data = fh.read()

        # ③ ΤΑΥΤΙΣΗ mount ↔ tree, ΑΝΑ ΔΙΑΔΡΟΜΗ
        recomputed = git_blob_sha1(data)
        if recomputed != blob_sha:
            mismatches.append((rel, f"blob sha1 {recomputed} ≠ tree {blob_sha}"))
            continue

        csha = hashlib.sha256(data).hexdigest()
        cls, lines, trailing = classify(data, kind)
        rows.append((rel, mode, kind, blob_sha, csha, len(data), lines, trailing, cls))
        leaves.append(hashlib.sha256(
            b"\x00" + leaf_preimage(path_b, mode, kind, csha, len(data))).hexdigest())

    if mismatches:
        for r, w in mismatches[:20]:
            print(f"::error::{r} — {w}", file=sys.stderr)
        die(f"{len(mismatches)} ΑΠΟΚΛΙΣΕΙΣ mount ↔ tree — καμία απογραφή δεν γράφεται")

    root = merkle(leaves)
    tree_sha = subprocess.run(["git", "-C", REPO, "rev-parse", f"{COMMIT}^{{tree}}"],
                              capture_output=True, text=True, check=True).stdout.strip()

    tsv = os.path.join(REPO, "experiment/artifacts/corpus-manifest.tsv")
    with open(tsv, "w", encoding="utf-8") as fh:
        fh.write("#" + "\t".join(COLUMNS) + "\n")
        for r in rows:
            fh.write("\t".join(str(x) for x in r) + "\n")

    sexp = os.path.join(REPO, "experiment/artifacts/corpus-manifest.sexp")
    with open(sexp, "w", encoding="utf-8") as fh:
        fh.write(f""";;;; experiment/artifacts/corpus-manifest.sexp
;;;; ΤΑΥΤΟΤΗΤΑ ΠΑΓΩΜΕΝΟΥ CORPUS — schema {SCHEMA}, PATH-AND-KIND-COMPLETE
;;;; ΠΑΡΑΓΩΓΟΣ: experiment/runner/corpus-manifest.py — ΜΗΝ γράφεται με το χέρι.

(:lawmax-corpus-manifest/{SCHEMA}
 :schema {SCHEMA}
 :enumeration-authority :GIT-TREE
 :enumeration-command "git ls-tree -r -z --full-tree {COMMIT}"
 :why-not-filesystem
  "Το os.walk του schema 2 ΕΞΑΦΑΝΙΖΕ τα symlink-προς-κατάλογο: ούτε ως αρχεία
   ούτε ως κατάλογοι προς κάθοδο. Έλειπαν 6 εγγραφές (35.634 αντί 35.640).
   Το filesystem ΔΕΝ είναι αυθεντία πληρότητας· το git tree είναι."

 :commit "{COMMIT}"
 :tree-sha1 "{tree_sha}"
 :leaves {len(rows)}
 :by-kind (:file {counts['file']} :executable {counts['executable']} :symlink {counts['symlink']})

 :identity
 (:kind :PATH-AND-KIND-COMPLETE
  :root "sha256:{root}"
  :leaf-preimage
   "u32be(len(path))‖path ‖ u32be(len(mode))‖mode ‖ u32be(len(kind))‖kind
    ‖ content_sha256(32 raw bytes) ‖ u64be(bytes)"
  :leaf-hash "SHA256(0x00 ‖ preimage)"
  :node-hash "SHA256(0x01 ‖ left ‖ right)"
  :split "ΑΥΣΤΗΡΗ δύναμη του 2 (RFC 6962/9162 §2.1.1)· ΠΟΤΕ duplicate-last (CVE-2012-2459)"
  :order "ταξινόμηση κατά ΩΜΑ BYTES διαδρομής"
  :binds ("commit sha1" "tree sha1" "κάθε διαδρομή" "κάθε git mode" "κάθε kind"
          "κάθε content sha256" "κάθε μέγεθος")
  :what-it-catches
   "Μετακίνηση αρχείου, μετατροπή αρχείου σε symlink, αλλαγή δικαιώματος
    εκτέλεσης, ΚΑΙ αλλαγή περιεχομένου. Η ρίζα ΑΛΛΑΖΕΙ σε κάθε μία.")

 :legacy-identity
 (:kind :CONTENT-ONLY
  :root "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b"
  :status :LEGACY-ARTIFACT
  :must-not-be-called "πλήρης ταυτότητα corpus"
  :why "Δεσμευόταν ΜΟΝΟ σε περιεχόμενα 35.634 αρχείων. ΔΕΝ περιείχε τα 6
        symlinks, ΔΕΝ δέσμευε διαδρομές, ΔΕΝ δέσμευε modes/kinds. Διατηρείται
        ως ιστορικό τεκμήριο των αποδείξεων που εκδόθηκαν υπό αυτόν.")

 :mount-attestation
 (:mount "{MOUNT}" :verified-per-path t
  :method "Για ΚΑΘΕ leaf: ανάγνωση από το mount (lstat, χωρίς ακολούθηση
           symlink), επανυπολογισμός του git blob sha1 από τα ΠΡΑΓΜΑΤΙΚΑ bytes,
           απαίτηση ταύτισης με το sha1 του tree."
  :paths-verified {len(rows)} :mismatches 0
  :establishes "Το mount ΕΙΝΑΙ ο παγωμένος commit — ανά διαδρομή, όχι συνολικά.")

 :columns {str(COLUMNS).replace("'", '"').replace(",", "")}
 :line-encoding
 (:text "logical_lines ≥ 0 · αρχείο χωρίς τελικό newline μετρά και την
         τελευταία ημιτελή γραμμή · κενό αρχείο = 0"
  :binary "logical_lines = {LINES_BINARY} — καμία σημασία γραμμών"
  :symlink "logical_lines = {LINES_SYMLINK} — καμία σημασία γραμμών· το
            «περιεχόμενο» είναι η συμβολοσειρά του στόχου, ΔΕΝ ακολουθείται")
 :tsv "experiment/artifacts/corpus-manifest.tsv")
""")
    print(f"schema {SCHEMA} · leaves {len(rows)} "
          f"(file {counts['file']} · exec {counts['executable']} · symlink {counts['symlink']})")
    print(f"commit    {COMMIT}")
    print(f"tree      {tree_sha}")
    print(f"IDENTITY  sha256:{root}   (PATH-AND-KIND-COMPLETE)")
    print(f"mount attestation: {len(rows)} διαδρομές, 0 αποκλίσεις")


main()
