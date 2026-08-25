#!/usr/bin/env python3
"""ΑΠΟΓΡΑΦΗ ΠΑΓΩΜΕΝΟΥ CORPUS — schema 4. ΜΙΑ ΕΔΡΑ ΓΙΑ ΤΗΝ ΤΑΥΤΟΤΗΤΑ.

  --root <dir>     η ρίζα του παγωμένου snapshot (ΥΠΟΧΡΕΩΤΙΚΟ)
  --out <path>     γράψε εκεί την απογραφή
  --compare <path> ΜΗΝ γράψεις· παρήγαγε στη μνήμη και σύγκρινε BYTE-FOR-BYTE

ΤΙ ΑΛΛΑΞΕ ΑΠΟ ΤΟ schema 3 — ΤΡΕΙΣ ΔΙΟΡΘΩΣΕΙΣ ΚΑΤΑΣΚΕΥΗΣ
─────────────────────────────────────────────────────────
① DESCRIPTOR-ANCHORED. Το schema 3 έκανε lstat(path) και μετά open(path):
   δύο ξεχωριστές αναλύσεις της ΙΔΙΑΣ συμβολοσειράς, άρα παράθυρο μεταβολής
   ΚΑΙ κενό ενδιάμεσου symlink. Τώρα η πρόσβαση περνά από το frozen_access,
   που χρησιμοποιεί openat2 με RESOLVE_BENEATH|NO_SYMLINKS|NO_XDEV: η
   ιδιότητα επιβάλλεται ΑΠΟ ΤΟΝ ΠΥΡΗΝΑ κατά την ανάλυση, δεν ελέγχεται μετά.
② ΤΟ ΠΡΑΓΜΑΤΙΚΟ EXECUTABLE BIT ΕΛΕΓΧΕΤΑΙ. Το git mode του tree λέει
   100644/100755· ο δίσκος μπορεί να λέει άλλο. Απαιτείται ταύτιση.
③ ΤΑΥΤΟΤΗΤΑ DOMAIN-SEPARATED. Η ρίζα φύλλων ΔΕΝ είναι ταυτότητα: δεν
   δεσμεύει schema/commit/tree. Η ταυτότητα είναι
   SHA256(domain ‖ schema ‖ commit ‖ tree ‖ leaf-root) — και τα τέσσερα ΜΕΣΑ
   στο preimage.
Επίσης: ΚΕΝΟ text αρχείο ⇒ logical_lines=0 ΚΑΙ trailing_newline=0.

Η ΚΑΝΟΝΙΚΗ ΑΥΘΕΝΤΙΑ ΔΕΝ ΞΑΝΑΓΡΑΦΕΤΑΙ ΑΠΟ ΕΔΩ. Ο runner παράγει run-local
αντίγραφο και το συγκρίνει byte-for-byte με το σφραγισμένο.
"""
import hashlib
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import frozen_access as fa

SCHEMA = 4
COMMIT = "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
REPO = "/home/user/THE-LEGAL-WATCHTOWER"
COLUMNS = ("path", "git_mode", "kind", "git_blob_sha1", "content_sha256",
           "bytes", "logical_lines", "trailing_newline", "class")
HEADER = "#" + "\t".join(COLUMNS)


def die(msg):
    print(f"::error::{msg}", file=sys.stderr)
    sys.exit(2)


def enumerate_tree():
    out = subprocess.run(["git", "-C", REPO, "ls-tree", "-r", "-z",
                          "--full-tree", COMMIT],
                         capture_output=True, check=True).stdout
    entries = []
    for rec in out.split(b"\0"):
        if not rec:
            continue
        meta, _, path = rec.partition(b"\t")
        mode, otype, sha = (x.decode() for x in meta.split(b" "))
        if otype != "blob":
            die(f"ΜΗ ΑΝΑΜΕΝΟΜΕΝΟΣ ΤΥΠΟΣ «{otype}» στο {path!r}")
        if mode not in fa.MODE_KIND:
            die(f"ΑΓΝΩΣΤΟ git mode «{mode}» στο {path!r}")
        entries.append((path.decode("utf-8"), mode, sha))
    entries.sort(key=lambda e: e[0].encode("utf-8"))
    return entries


def build(root):
    rfd = os.open(root, os.O_RDONLY | os.O_DIRECTORY)
    try:
        rows, leaves, problems = [], [], []
        counts = {"file": 0, "executable": 0, "symlink": 0}
        for rel, mode, blob_sha in enumerate_tree():
            kind = fa.MODE_KIND[mode]
            counts[kind] += 1
            try:
                if kind == "symlink":
                    target, st = fa.readlink_beneath(rfd, rel)
                    data = target.encode("utf-8")
                else:
                    data, st = fa.read_beneath(rfd, rel)
            except OSError as e:
                problems.append((rel, f"ΔΕΝ ΑΝΑΓΝΩΣΤΗΚΕ (errno {e.errno})"))
                continue
            # ② ΤΟ ΠΡΑΓΜΑΤΙΚΟ MODE ΤΟΥ ΔΙΣΚΟΥ ΕΝΑΝΤΙ ΤΟΥ TREE
            disk_mode = fa.mode_from_stat(st, kind)
            if disk_mode != mode:
                problems.append((rel, f"git mode {mode} αλλά ο δίσκος λέει {disk_mode}"))
                continue
            recomputed = fa.git_blob_sha1(data)
            if recomputed != blob_sha:
                problems.append((rel, f"blob sha1 {recomputed} ≠ tree {blob_sha}"))
                continue
            csha = hashlib.sha256(data).hexdigest()
            cls, lines, trailing = fa.measure(data, kind)
            rows.append((rel, mode, kind, blob_sha, csha, len(data), lines,
                         trailing, cls))
            leaves.append(fa.leaf_hash(rel, mode, kind, csha, len(data)))
        return rows, leaves, counts, problems
    finally:
        os.close(rfd)


def render_tsv(rows):
    return HEADER + "\n" + "".join(
        "\t".join(str(x) for x in r) + "\n" for r in rows)


def render_sexp(rows, leaves, counts, tree_sha, leaf_root, identity):
    return f""";;;; experiment/artifacts/corpus-manifest.sexp
;;;; ΤΑΥΤΟΤΗΤΑ ΠΑΓΩΜΕΝΟΥ CORPUS — schema {SCHEMA}
;;;; ΠΑΡΑΓΩΓΟΣ: experiment/runner/corpus-manifest.py — ΜΗΝ γράφεται με το χέρι.

(:lawmax-corpus-manifest/{SCHEMA}
 :schema {SCHEMA}
 :enumeration-authority :GIT-TREE
 :enumeration-command "git ls-tree -r -z --full-tree {COMMIT}"
 :commit "{COMMIT}"
 :tree-sha1 "{tree_sha}"
 :leaves {len(rows)}
 :by-kind (:file {counts['file']} :executable {counts['executable']} :symlink {counts['symlink']})

 :access
 (:mechanism "{fa.access_mode()}"
  :guarantee "Ο ΠΥΡΗΝΑΣ επιβάλλει κατά την ανάλυση: καμία έξοδος από τη ρίζα,
              κανένα symlink σε κανένα συστατικό, καμία διάσχιση filesystem.
              ΔΕΝ υπάρχει έλεγχος-και-μετά-άνοιγμα, άρα ΔΕΝ υπάρχει παράθυρο."
  :same-descriptor "fstat και read στον ΙΔΙΟ descriptor — ΤΟ ΙΔΙΟ inode")

 :identity
 (:kind :DOMAIN-SEPARATED-PATH-AND-KIND-COMPLETE
  :value "sha256:{identity}"
  :preimage "LAWMAX-CORPUS-IDENTITY/1\\\\0 ‖ u32be(schema) ‖ commit(20 raw)
             ‖ tree(20 raw) ‖ leaf-root(32 raw)"
  :binds-inside-preimage ("schema" "commit sha1" "tree sha1" "leaf root")
  :leaf-root "sha256:{leaf_root}"
  :leaf-preimage "0x00 ‖ u32be(len path)‖path ‖ u32be(len mode)‖mode
                  ‖ u32be(len kind)‖kind ‖ content_sha256(32) ‖ u64be(bytes)"
  :node "0x01 ‖ L ‖ R"
  :split "ΑΥΣΤΗΡΗ δύναμη του 2 (RFC 6962/9162 §2.1.1)· ΠΟΤΕ duplicate-last"
  :order "ταξινόμηση κατά ΩΜΑ BYTES διαδρομής"
  :correction-over-schema-3
   "Το schema 3 δήλωνε ότι η leaf root «δεσμεύει commit και tree». ΔΕΝ τα
    δέσμευε: ήταν διπλανά πεδία, εκτός preimage. Δύο δέντρα με ίδια φύλλα σε
    διαφορετικό commit έδιναν ΙΔΙΑ ρίζα. Τώρα είναι μέσα στο preimage.")

 :legacy-roots
 ((:root "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b"
   :schema 2 :covered-leaves 35634 :status :LEGACY-CONTENT-ONLY
   :why "os.walk· έλειπαν 6 symlinks· καμία δέσμευση διαδρομής/mode/kind")
  (:root "sha256:3127f4941b899afcbffcd405b00d9e613fe4732301ba8ed990d22a0685514019"
   :schema 3 :covered-leaves 35640 :status :LEGACY-LEAF-ROOT-ONLY
   :why "σωστά φύλλα, αλλά η ρίζα ΔΕΝ δέσμευε schema/commit/tree στο preimage,
         και το κενό text αρχείο δηλωνόταν trailing_newline=1 (αναληθές)"))
 :corpus-bytes-unchanged-across-all-schemas t

 :line-encoding
 (:text "logical_lines ≥ 0· αρχείο χωρίς τελικό newline μετρά και την τελευταία
         ημιτελή γραμμή· ΚΕΝΟ αρχείο ⇒ 0 γραμμές ΚΑΙ trailing_newline 0"
  :binary "logical_lines = {fa.LINES_BINARY}"
  :symlink "logical_lines = {fa.LINES_SYMLINK}· περιεχόμενο = ο στόχος· ΔΕΝ ακολουθείται")
 :columns {str(COLUMNS).replace("'", '"').replace(",", "")}
 :tsv "experiment/artifacts/corpus-manifest.tsv")
"""


def main():
    a = sys.argv[1:]
    def opt(name):
        return a[a.index(name) + 1] if name in a and a.index(name) + 1 < len(a) else None
    root = opt("--root")
    if not root:
        die("--root ΥΠΟΧΡΕΩΤΙΚΟ — η απογραφή δεν μαντεύει πηγή")
    out, compare = opt("--out"), opt("--compare")
    if bool(out) == bool(compare):
        die("ΑΚΡΙΒΩΣ ΕΝΑ από --out | --compare")

    rows, leaves, counts, problems = build(root)
    if problems:
        for r, w in problems[:20]:
            print(f"::error::{r} — {w}", file=sys.stderr)
        die(f"{len(problems)} ΑΠΟΚΛΙΣΕΙΣ snapshot ↔ tree")

    tree_sha = subprocess.run(["git", "-C", REPO, "rev-parse", f"{COMMIT}^{{tree}}"],
                              capture_output=True, text=True, check=True).stdout.strip()
    leaf_root = fa.merkle_root(leaves)
    identity = fa.corpus_identity(SCHEMA, COMMIT, tree_sha, leaf_root)
    tsv = render_tsv(rows)
    sexp = render_sexp(rows, leaves, counts, tree_sha, leaf_root, identity)

    if compare:
        sealed = open(compare, "rb").read()
        made = tsv.encode("utf-8")
        if sealed != made:
            die(f"ΤΟ ΣΦΡΑΓΙΣΜΕΝΟ MANIFEST ΔΕΝ ΕΙΝΑΙ BYTE-IDENTICAL ΜΕ ΤΟ "
                f"RUN-LOCAL: σφραγισμένο {len(sealed)}B "
                f"sha256:{hashlib.sha256(sealed).hexdigest()[:16]}… · "
                f"run-local {len(made)}B "
                f"sha256:{hashlib.sha256(made).hexdigest()[:16]}…")
        print(f"MANIFEST-BYTE-IDENTICAL: {len(rows)} leaves · "
              f"sha256:{hashlib.sha256(made).hexdigest()}")
    else:
        with open(out, "w", encoding="utf-8") as fh:
            fh.write(tsv)
        with open(out.replace(".tsv", ".sexp"), "w", encoding="utf-8") as fh:
            fh.write(sexp)
        print(f"schema {SCHEMA} · leaves {len(rows)} "
              f"(file {counts['file']} · exec {counts['executable']} · "
              f"symlink {counts['symlink']})")
    print(f"access    {fa.access_mode()}")
    print(f"commit    {COMMIT}")
    print(f"tree      {tree_sha}")
    print(f"leaf-root sha256:{leaf_root}")
    print(f"IDENTITY  sha256:{identity}   (DOMAIN-SEPARATED)")
    return 0


sys.exit(main())
