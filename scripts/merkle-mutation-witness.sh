#!/usr/bin/env bash
# =============================================================================
# MERKLE-SINGLE-TRUTH — ΜΑΡΤΥΡΕΣ ΜΕΤΑΛΛΑΞΗΣ (ΠΡΑΓΜΑΤΙΚΑ ΕΦΑΡΜΟΣΜΕΝΟΙ)
# =============================================================================
# Στόχος-προφίλ: lawmax-merkle-sha256-v1. ΔΕΝ αρκεί να ΥΠΑΡΧΟΥΝ tests. Κάθε μετάλλαξη εφαρμόζεται ΠΡΑΓΜΑΤΙΚΑ σε ΑΝΤΙΓΡΑΦΟ
# της κάθε υλοποίησης, τρέχει απέναντι στα committed golden vectors, και ΠΡΕΠΕΙ
# να δώσει non-zero. Επιβιώνουσα μετάλλαξη = η πύλη δεν διακρίνει το λάθος από
# το σωστό ⇒ ο μάρτυρας είναι κενός ⇒ ΑΠΟΤΥΧΙΑ.
#
# Το repo ΔΕΝ αγγίζεται ποτέ: όλες οι μεταλλάξεις ζουν σε προσωρινό κατάλογο.
#
# [ΕΥΡΗΜΑ ΚΡΙΤΗ #2] Το ΜΗΤΡΩΟ των μαρτύρων ΔΕΝ είναι λίστα μέσα σε αυτό το
# script: διαβάζεται από το profile (:mutation-witnesses) και απαιτείται
# ΙΣΟΤΗΤΑ ΣΥΝΟΛΩΝ μητρώου/εφαρμοσμένων. Μάρτυρας δηλωμένος-αλλά-ανεφάρμοστος
# ή εφαρμοσμένος-αλλά-αδήλωτος = ΑΠΟΤΥΧΙΑ. Έτσι το πεδίο του profile παύει να
# είναι διακοσμητικό: η αφαίρεση μιας γραμμής του κοκκινίζει αυτό το gate.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VECTORS="$HERE/deployment/verify/vectors/merkle/vectors.json"
[ -f "$VECTORS" ] || { echo "::error::golden vectors ΑΠΟΝΤΑ: $VECTORS"; exit 2; }

python3 - "$HERE" "$VECTORS" <<'PYTHON'
import json, os, re, shutil, subprocess, sys, tempfile

repo, vectors_path = sys.argv[1], sys.argv[2]
with open(vectors_path, encoding="utf-8") as fh:
    V = json.load(fh)

# ── ΜΗΤΡΩΟ ΜΑΡΤΥΡΩΝ: η ΜΙΑ έδρα είναι το profile — ΚΑΜΙΑ δεύτερη λίστα εδώ ──
PROFILE_PATH = os.path.join(repo, "deployment/verify/merkle-profile.sexp")
_ptxt = open(PROFILE_PATH, encoding="utf-8").read()
if ":mutation-witnesses" not in _ptxt:
    print("::error::το profile ΔΕΝ έχει :mutation-witnesses — fail-closed"); sys.exit(2)
REGISTRY = set(re.findall(r'\(:id\s+"([a-z0-9-]+)"',
                          _ptxt.split(":mutation-witnesses", 1)[1]))
if not REGISTRY:
    print("::error::ΚΕΝΟ μητρώο :mutation-witnesses — fail-closed"); sys.exit(2)

PY_SRC   = os.path.join(repo, "deployment/verify/verify-merkle.py")
MJS_SRC  = os.path.join(repo, "deployment/verify/verify-merkle.mjs")
LISP_SRC = os.path.join(repo, "source/merkle-authority.lisp")
THIRD    = os.path.join(repo, "third-party") + "/"

have_node = shutil.which("node") is not None
have_sbcl = shutil.which("sbcl") is not None

results = []           # (mutant, language, exit_code, killed?)


def record(mutant, lang, code, note=""):
    """[ΔΙΟΡΘΩΣΗ ΚΡΙΤΗ] killed = code > 0 ΑΥΣΤΗΡΑ. Πριν ήταν `code != 0`, οπότε
    το -1 (εργαλείο ΑΠΟΝ) καταμετρούνταν ως «σκοτωμένη μετάλλαξη» — false-green.
    Τώρα: -1 = BLOCKED, ΔΕΝ είναι kill, και ρίχνει ΟΛΟ το script."""
    blocked = code < 0
    killed = code > 0
    results.append((mutant, lang, code, killed, blocked, note))
    mark = "ok  " if killed else ("BLK " if blocked else "FAIL")
    state = ("ΣΚΟΤΩΘΗΚΕ" if killed else
             ("BLOCKED — ΔΕΝ ΕΚΤΕΛΕΣΤΗΚΕ (ποτέ PASS)" if blocked else
              "ΕΠΙΒΙΩΣΕ — Ο ΜΑΡΤΥΡΑΣ ΕΙΝΑΙ ΚΕΝΟΣ"))
    print(f"  {mark} {mutant:22s} {lang:7s} exit={code:<3d} {state}{note}")


# ── ΜΕΤΑΛΛΑΞΕΙΣ: (παλιό, νέο) ανά γλώσσα. Πραγματική επέμβαση στο κείμενο. ──
PY_MUT = {
  "no-leaf-prefix":   ('LEAF_DOMAIN = b"\\x00"', 'LEAF_DOMAIN = b""'),
  "no-node-prefix":   ('NODE_DOMAIN = b"\\x01"', 'NODE_DOMAIN = b""'),
  "swap-left-right":  ("return _h(NODE_DOMAIN, bytes.fromhex(a[len(PREFIX):]) + bytes.fromhex(b[len(PREFIX):]))",
                       "return _h(NODE_DOMAIN, bytes.fromhex(b[len(PREFIX):]) + bytes.fromhex(a[len(PREFIX):]))"),
  "wrong-split":      ("    k = largest_power_of_two_below(len(leaves))",
                       "    k = len(leaves) // 2"),
  # ΜΕΤΑΛΛΑΞΗ (ΟΧΙ ο κανόνας): επίπεδο-προς-επίπεδο, περιττός ⇒ ζευγάρι με ΕΑΥΤΟ.
  "duplicate-last":   ("    k = largest_power_of_two_below(len(leaves))\n    return node(mth(leaves[:k]), mth(leaves[k:]))",
                       "    cur = list(leaves)\n"
                       "    while len(cur) > 1:\n"
                       "        if len(cur) % 2: cur = cur + [cur[-1]]\n"
                       "        cur = [node(cur[i], cur[i+1]) for i in range(0, len(cur), 2)]\n"
                       "    return cur[0]"),
  "unicode-normalize":('    return _h(LEAF_DOMAIN, data)',
                       '    import unicodedata\n'
                       '    try: data = unicodedata.normalize("NFC", data.decode("utf-8")).encode("utf-8")\n'
                       '    except Exception: pass\n'
                       '    return _h(LEAF_DOMAIN, data)'),
  "crlf-normalize":   ('    return _h(LEAF_DOMAIN, data)',
                       '    data = data.replace(b"\\r\\n", b"\\n")\n'
                       '    return _h(LEAF_DOMAIN, data)'),
}

MJS_MUT = {
  "no-leaf-prefix":   ("const LEAF = Buffer.from([0x00]);", "const LEAF = Buffer.alloc(0);"),
  "no-node-prefix":   ("const NODE = Buffer.from([0x01]);", "const NODE = Buffer.alloc(0);"),
  "swap-left-right":  ('    Buffer.from(a.slice(PREFIX.length), "hex"),\n    Buffer.from(b.slice(PREFIX.length), "hex"),',
                       '    Buffer.from(b.slice(PREFIX.length), "hex"),\n    Buffer.from(a.slice(PREFIX.length), "hex"),'),
  "wrong-split":      ("  const k = largestPowerOfTwoBelow(leaves.length);",
                       "  const k = Math.floor(leaves.length / 2);"),
  "duplicate-last":   ("  const k = largestPowerOfTwoBelow(leaves.length);\n  return node(mth(leaves.slice(0, k)), mth(leaves.slice(k)));   // NEVER duplicate-last",
                       "  let cur = [...leaves];\n"
                       "  while (cur.length > 1) {\n"
                       "    if (cur.length % 2) cur = [...cur, cur[cur.length - 1]];\n"
                       "    const nx = []; for (let i = 0; i < cur.length; i += 2) nx.push(node(cur[i], cur[i+1]));\n"
                       "    cur = nx;\n  }\n  return cur[0];"),
  "unicode-normalize":("const leafHashBytes = (buf) => h(LEAF, buf);",
                       'const leafHashBytes = (buf) => h(LEAF, Buffer.from(buf.toString("utf8").normalize("NFC"), "utf8"));'),
  "crlf-normalize":   ("const leafHashBytes = (buf) => h(LEAF, buf);",
                       'const leafHashBytes = (buf) => h(LEAF, Buffer.from(buf.toString("latin1").split("\\r\\n").join("\\n"), "latin1"));'),
}

LISP_MUT = {
  "no-leaf-prefix":   ('(defparameter +leaf-prefix+ #(#x00)', '(defparameter +leaf-prefix+ #()'),
  "no-node-prefix":   ('(defparameter +node-prefix+ #(#x01)', '(defparameter +node-prefix+ #()'),
  "swap-left-right":  ("(%sha256-hex (concatenate '(vector (unsigned-byte 8)) +node-prefix+ bl br))",
                       "(%sha256-hex (concatenate '(vector (unsigned-byte 8)) +node-prefix+ br bl))"),
  "wrong-split":      ("(let ((k 1))\n    (loop while (< (* k 2) n) do (setf k (* k 2)))\n    k))",
                       "(floor n 2))"),
  # ΠΡΑΓΜΑΤΙΚΗ ΜΕΤΑΛΛΑΞΗ duplicate-last: επίπεδο-προς-επίπεδο, περιττός ⇒ ζευγάρι με ΕΑΥΤΟ.
  "duplicate-last":   ("(t (let ((k (%largest-power-of-two-below n)))\n                        (hash-node (mth lo (+ lo k)) (mth (+ lo k) hi))))",
                       "(t (let ((cur (coerce (subseq v lo hi) 'list)))\n"
                       "                        (loop while (> (length cur) 1) do\n"
                       "                          (when (oddp (length cur)) (setf cur (append cur (last cur))))\n"
                       "                          (setf cur (loop for (a b) on cur by #'cddr collect (hash-node a b))))\n"
                       "                        (first cur)))"),
  # Οι δύο μεταλλάξεις ΕΙΣΟΔΟΥ έλειπαν εντελώς από τη Lisp (εύρημα κριτή).
  "unicode-normalize":("(defun hash-leaf-bytes (bytes)",
                       "(defun hash-leaf-bytes (bytes)\n  (setf bytes (babel:string-to-octets\n               (sb-unicode:normalize-string (babel:octets-to-string bytes :encoding :utf-8) :nfc)\n               :encoding :utf-8))"),
  "crlf-normalize":   ("(defun hash-leaf-bytes (bytes)",
                       "(defun hash-leaf-bytes (bytes)\n  (setf bytes (babel:string-to-octets\n               (with-output-to-string (o)\n                 (let ((s (babel:octets-to-string bytes :encoding :utf-8)))\n                   (loop for i from 0 below (length s) do\n                     (unless (and (char= (char s i) #\\Return) (< (1+ i) (length s))\n                                  (char= (char s (1+ i)) #\\Newline))\n                       (write-char (char s i) o)))))\n               :encoding :utf-8))"),
}

# ── PYTHON ──
def run_python(mutant, old, new):
    with tempfile.TemporaryDirectory() as d:
        src = open(PY_SRC, encoding="utf-8").read()
        if old not in src:
            record(mutant, "python", 0, "  (::error:: anchor δεν βρέθηκε)")
            return
        dst = os.path.join(d, "m.py")
        open(dst, "w", encoding="utf-8").write(src.replace(old, new, 1))
        r = subprocess.run([sys.executable, dst, vectors_path], capture_output=True, text=True)
        record(mutant, "python", r.returncode)


# ── NODE ──
def run_node(mutant, old, new):
    if not have_node:
        record(mutant, "node", -1, "  (BLOCKED — node ΑΠΩΝ)")
        return
    with tempfile.TemporaryDirectory() as d:
        src = open(MJS_SRC, encoding="utf-8").read()
        if old not in src:
            record(mutant, "node", 0, "  (::error:: anchor δεν βρέθηκε)")
            return
        dst = os.path.join(d, "m.mjs")
        open(dst, "w", encoding="utf-8").write(src.replace(old, new, 1))
        r = subprocess.run(["node", dst, vectors_path], capture_output=True, text=True)
        record(mutant, "node", r.returncode)


# ── LISP: αυτόνομος probe (μόνο ironclad+babel+η μεταλλαγμένη έδρα) ──
LISP_PROBE = r'''
(require :asdf)
(asdf:initialize-source-registry '(:source-registry (:tree #p"{third}") :inherit-configuration))
(handler-bind ((warning #'muffle-warning))
  (asdf:load-system :ironclad) (asdf:load-system :babel)
  (load "{seat}"))
(let* ((leaves (loop for i below 5
                     collect (orchestrator.merkle:hash-leaf-bytes
                              (babel:string-to-octets (format nil "~D" i) :encoding :utf-8))))
       (root (orchestrator.merkle:merkle-tree-hash leaves)))
  (format t "ROOT5 ~A~%" root)
  ;; φύλλα ειδικής εισόδου — ΧΩΡΙΣ αυτά, unicode/crlf μεταλλάξεις είναι αόρατες
  (dolist (spec '(("nfd" "ceb1cc81") ("crlf" "ceb10d0aceb2")))
    (format t "LEAF-~A ~A~%" (first spec)
            (orchestrator.merkle:hash-leaf-bytes
             (ironclad:hex-string-to-byte-array (second spec))))))
(sb-ext:exit :code 0)
'''

def run_lisp(mutant, old, new):
    if not have_sbcl:
        record(mutant, "lisp", -1, "  (BLOCKED — sbcl ΑΠΩΝ)")
        return
    expected = next(t["root"] for t in V["trees"] if t["n"] == 5)
    with tempfile.TemporaryDirectory() as d:
        src = open(LISP_SRC, encoding="utf-8").read()
        if old not in src:
            record(mutant, "lisp", 0, "  (::error:: anchor δεν βρέθηκε)")
            return
        seat = os.path.join(d, "seat.lisp")
        open(seat, "w", encoding="utf-8").write(src.replace(old, new, 1))
        probe = os.path.join(d, "probe.lisp")
        open(probe, "w", encoding="utf-8").write(LISP_PROBE.format(third=THIRD, seat=seat))
        r = subprocess.run(["sbcl", "--script", probe], capture_output=True, text=True)
        out = {}
        for line in r.stdout.splitlines():
            parts = line.strip().split()
            if len(parts) == 2 and parts[1].startswith("sha256:"):
                out[parts[0]] = parts[1]
        golden = {
            "ROOT5":     expected,
            "LEAF-nfd":  next(l["leaf"] for l in V["leaves"] if l["id"] == "nfd-alpha-tonos"),
            "LEAF-crlf": next(l["leaf"] for l in V["leaves"] if l["id"] == "embedded-crlf"),
        }
        # ΣΚΟΤΩΜΕΝΟ = έσκασε, Ή οποιαδήποτε τιμή διαφέρει από το golden vector
        agree = r.returncode == 0 and all(out.get(k) == v for k, v in golden.items())
        record(mutant, "lisp", 0 if agree else 1)


print("== ΜΑΡΤΥΡΕΣ ΜΕΤΑΛΛΑΞΗΣ — πραγματική εφαρμογή σε ΚΑΘΕ υλοποίηση ==")
for mutant in ["duplicate-last", "no-leaf-prefix", "no-node-prefix",
               "wrong-split", "swap-left-right", "unicode-normalize", "crlf-normalize"]:
    if mutant in PY_MUT:   run_python(mutant, *PY_MUT[mutant])
    if mutant in MJS_MUT:  run_node(mutant, *MJS_MUT[mutant])
    if mutant in LISP_MUT: run_lisp(mutant, *LISP_MUT[mutant])

# ── 8ος ΜΑΡΤΥΡΑΣ: ΠΟΛΙΤΙΚΗ — δημοσίευση κενού corpus (ΠΡΑΓΜΑΤΙΚΗ ΜΕΤΑΛΛΑΞΗ) ──
# [ΕΠΙΤΗΡΗΤΗΣ κρ.5] Ήταν χειρόγραφη eval-redefinition (ΟΧΙ μετάλλαξη του
# πραγματικού πηγαίου — ένα ΤΡΙΤΟ σώμα γραμμένο μέσα στο probe). Τώρα, ίδιο
# πρότυπο με census/tlog: το ΙΔΙΟ το source/proof-carrying.lisp μεταλλάσσεται
# κειμενικά σε αντίγραφο (η πύλη νεκρώνεται: when (null provisions) -> when nil)
# και φορτώνεται ΠΑΝΩ στην εικόνα. Αποδεικνύεται ότι:
#   (α) ΜΕ την πύλη   ⇒ κενό corpus ΑΠΟΡΡΙΠΤΕΤΑΙ, και
#   (β) ΧΩΡΙΣ την πύλη ⇒ ΓΙΝΕΤΑΙ ΔΕΚΤΟ (η ΓΡΑΜΜΗ του πηγαίου είναι φέρουσα).
PC_SRC = os.path.join(repo, "source/proof-carrying.lisp")
PC_GUARD_OLD = "  (when (null provisions)\n    (error 'empty-corpus-publication :output-dir (princ-to-string output-dir)))"
PC_GUARD_NEW = "  (when nil\n    (error 'empty-corpus-publication :output-dir (princ-to-string output-dir)))"

POLICY_PROBE = r"""
(require :asdf) (require :sb-posix)
(setf asdf:*central-registry* (append (list #p"{repo}/") (directory #p"{repo}/systems/*/")))
(asdf:initialize-source-registry '(:source-registry (:tree #p"{third}") :inherit-configuration))
(locally (declare (sb-ext:muffle-conditions sb-ext:compiler-note style-warning warning))
  (handler-bind ((warning #'muffle-warning))
    (asdf:load-system :alexandria) (asdf:load-system :log4cl)
    (asdf:load-system :orchestrator-core-runtime)))
(defun probe-publish (dir)
  (handler-case (progn (orchestrator.proof-carrying:write-provision-proofs '() dir) :accepted)
    (orchestrator.proof-carrying:empty-corpus-publication () :rejected)
    (error (e) (progn (format t "DIAG-PC ~A~%" e) :other-error))))
(format t "GUARDED ~A~%" (probe-publish #p"{work}/pc-guarded/"))
;; ΜΕΤΑΛΛΑΞΗ: το ΜΕΤΑΛΛΑΓΜΕΝΟ αντίγραφο του ΠΡΑΓΜΑΤΙΚΟΥ πηγαίου φορτώνεται
;; πάνω στην εικόνα — καμία χειρόγραφη redefinition.
(handler-bind ((warning #'muffle-warning)) (load "{mut_pc}"))
(format t "UNGUARDED ~A~%" (probe-publish #p"{work}/pc-unguarded/"))
(sb-ext:exit :code 0)
"""

if not have_sbcl:
    record("publish-empty-corpus", "policy", -1, "  (BLOCKED — sbcl ΑΠΩΝ)")
else:
    with tempfile.TemporaryDirectory() as d:
        pc_src = open(PC_SRC, encoding="utf-8").read()
        if PC_GUARD_OLD not in pc_src:
            record("publish-empty-corpus", "policy", 0, "  (::error:: anchor δεν βρέθηκε)")
        else:
            mut_pc = os.path.join(d, "mut-proof-carrying.lisp")
            open(mut_pc, "w", encoding="utf-8").write(
                pc_src.replace(PC_GUARD_OLD, PC_GUARD_NEW, 1))
            for sub in ("pc-guarded", "pc-unguarded"):
                os.makedirs(os.path.join(d, sub))
            probe = os.path.join(d, "policy.lisp")
            open(probe, "w", encoding="utf-8").write(
                POLICY_PROBE.format(repo=repo.rstrip("/"), third=THIRD, work=d, mut_pc=mut_pc))
            r = subprocess.run(["sbcl", "--script", probe], capture_output=True, text=True, timeout=1800)
            vals = dict(l.split() for l in r.stdout.splitlines()
                        if len(l.split()) == 2 and l.split()[0] in ("GUARDED", "UNGUARDED"))
            # (~A σε keyword τυπώνει ΧΩΡΙΣ άνω-κάτω τελεία — δεκτές και οι δύο μορφές)
            norm = lambda s: (s or "").lstrip(":").upper()
            killed = norm(vals.get("GUARDED")) == "REJECTED" and norm(vals.get("UNGUARDED")) == "ACCEPTED"
            record("publish-empty-corpus", "policy", 1 if killed else 0,
                   "" if killed else f"  (guarded={vals.get('GUARDED')} unguarded={vals.get('UNGUARDED')} rc={r.returncode})")

# ── PROFILE-DRIFT: το profile ΔΕΝ είναι διακοσμητικό ─────────────────────────
# [ΕΥΡΗΜΑ ΚΡΙΤΗ #2] Αν άλλαζε ΜΟΝΟ το profile (π.χ. leaf-prefix 0x02), ο παλιός
# generator έμενε πράσινος γιατί hardcode-αρε 0x00/0x01/SHA-256. Τώρα ο
# generator διαβάζει τις κρυπτο-παραμέτρους ΑΠΟ το profile και ελέγχει τις
# σταθερές της έδρας απέναντί τους — εδώ αυτό ΑΠΟΔΕΙΚΝΥΕΤΑΙ: το profile
# μεταλλάσσεται ΠΡΑΓΜΑΤΙΚΑ σε ΑΝΤΙΓΡΑΦΟ του repo και ο generator ΠΡΕΠΕΙ να
# σκάσει με το ΑΝΑΜΕΝΟΜΕΝΟ μήνυμα (όχι απλώς non-zero — ένα άσχετο σκάσιμο,
# π.χ. αρχείο που λείπει στο αντίγραφο, ΔΕΝ μετρά ως φόνος).
PROFILE_DRIFTS = {
    "profile-drift-leaf-prefix":
        (':leaf-prefix-byte "0x00"', ':leaf-prefix-byte "0x02"', "ΑΣΥΜΦΩΝΙΑ ΕΔΡΑΣ/PROFILE"),
    "profile-drift-node-prefix":
        (':node-prefix-byte "0x01"', ':node-prefix-byte "0x00"', "ΑΣΥΜΦΩΝΙΑ ΕΔΡΑΣ/PROFILE"),
    "profile-drift-hash-alg":
        (':hash-algorithm "SHA-256"', ':hash-algorithm "SHA-512"', "ΔΕΝ υποστηρίζεται"),
}

if not have_sbcl:
    for m in PROFILE_DRIFTS:
        record(m, "profile", -1, "  (BLOCKED — sbcl ΑΠΩΝ)")
    record("profile-field-drift", "sweep", -1, "  (BLOCKED — sbcl ΑΠΩΝ)")
else:
    drift_root = tempfile.mkdtemp(prefix="lawmax-profile-drift-")
    copy = os.path.join(drift_root, "repo")
    os.makedirs(copy)
    # Αντίγραφο του repo ΧΩΡΙΣ .git/output (μη αναγκαία, βαριά). Ο generator
    # τρέχει με cwd=copy ⇒ το ΠΡΑΓΜΑΤΙΚΟ repo δεν αγγίζεται ποτέ.
    for entry in os.listdir(repo):
        if entry in (".git", "output"):
            continue
        subprocess.run(["cp", "-a", os.path.join(repo, entry), copy], check=True)
    mut_profile = os.path.join(copy, "deployment/verify/merkle-profile.sexp")
    pristine = open(mut_profile, encoding="utf-8").read()
    def drift_case(mutant, lang, old, new, expect):
        """Μία μετάλλαξη profile στο αντίγραφο ⇒ gen --check ΠΡΕΠΕΙ να κοκκινίσει
        με το ΑΝΑΜΕΝΟΜΕΝΟ μήνυμα (άσχετο σκάσιμο ΔΕΝ μετρά ως φόνος)."""
        if old not in pristine:
            record(mutant, lang, 0, "  (::error:: anchor δεν βρέθηκε)")
            return
        open(mut_profile, "w", encoding="utf-8").write(pristine.replace(old, new, 1))
        try:
            r = subprocess.run(["sbcl", "--script", "scripts/gen-merkle-truth.lisp", "--check"],
                               cwd=copy, capture_output=True, text=True, timeout=1800)
            hit = expect in (r.stderr or "") or expect in (r.stdout or "")
            if r.returncode > 0 and hit:
                record(mutant, lang, r.returncode)
            elif r.returncode > 0:
                record(mutant, lang, 0,
                       "  (::error:: σκάσιμο ΧΩΡΙΣ το αναμενόμενο μήνυμα — δεν μετρά)")
            else:
                record(mutant, lang, 0)
        finally:
            open(mut_profile, "w", encoding="utf-8").write(pristine)

    # [ΕΠΙΤΗΡΗΤΗΣ κρ.3] ΚΑΘΕ κανονιστικό πεδίο του profile έχει μάρτυρα:
    # μεταβολή του είτε αλλάζει υποχρεωτικά τα artifacts (⇒ «ΑΠΟΚΛΙΝΕΙ» στο
    # --check) είτε κοκκινίζει τον generator (ασυμφωνία έδρας/oracle). Πεδίο
    # χωρίς μηχανική ισχύ δεν επιτρέπεται να υπάρχει στο profile.
    PROFILE_FIELD_SWEEP = [
        ("profile-id",
         ':profile-id "lawmax-merkle-sha256-v1"',
         ':profile-id "lawmax-merkle-sha256-x9"', "ΑΠΟΚΛΙΝΕΙ"),
        ("normative-ref",
         ':normative-reference "RFC 9162 §2.1.1 (Merkle Tree Hash) — obsoletes RFC 6962"',
         ':normative-reference "RFC 0000 (bogus)"', "ΑΠΟΚΛΙΝΕΙ"),
        # Η αναπαράσταση πιάνεται από την άγκυρα ΔΗΜΟΣΙΕΥΜΕΝΩΝ σταθερών (το
        # FIPS 180-4 KAT τρέχει ΠΡΙΝ τη σύγκριση έδρας/profile) — ισχυρότερο
        # σημείο θανάτου: εξωτερική σταθερά, όχι εσωτερική σύγκριση.
        ("hash-representation",
         ':hash-representation "sha256:<64 lowercase hex>"',
         ':hash-representation "sha512:<64 lowercase hex>"', "FIPS 180-4"),
        ("tree-leaf-rule",
         ':tree-leaf-rule "leaf data for index i = ASCII bytes of the decimal representation of i"',
         ':tree-leaf-rule "leaf data for index i = ASCII bytes of i+1"', "ΑΠΟΚΛΙΝΕΙ"),
        ("tree-sizes",
         ":tree-sizes (0 1 2 3 4 5 6 7 8 15 16 17)",
         ":tree-sizes (0 1 2 3 4 5 6 7 8 15 16 17 18)", "ΑΠΟΚΛΙΝΕΙ"),
        ("leaf-input-hex",
         ':hex "68656c6c6f"', ':hex "68656c6c6e"', "ΑΠΟΚΛΙΝΕΙ"),
        ("inclusion-cases",
         "(:n 17 :index 16)", "(:n 17 :index 15)", "ΑΠΟΚΛΙΝΕΙ"),
        ("consistency-cases",
         "(:n 17 :m 16)", "(:n 17 :m 15)", "ΑΠΟΚΛΙΝΕΙ"),
        ("differential-range",
         ":differential-range (:from 0 :to 64)",
         ":differential-range (:from 0 :to 63)", "ΑΠΟΚΛΙΝΕΙ"),
        ("rule-statement",
         ':statement "duplicate-last ΑΠΑΓΟΡΕΥΕΤΑΙ ΑΠΟΛΥΤΩΣ"',
         ':statement "duplicate-last ΕΠΙΤΡΕΠΕΤΑΙ"', "ΑΠΟΚΛΙΝΕΙ"),
        ("byte-encoding",
         ':statement "ΚΑΜΙΑ μετατροπή LF/CRLF προς οποιαδήποτε κατεύθυνση"',
         ':statement "CRLF κανονικοποιειται σε LF"', "ΑΠΟΚΛΙΝΕΙ"),
        ("publication-policy",
         ':statement "Δημοσίευση/υπογραφή/checkpoint corpus με leaf_count = 0 ΑΠΟΡΡΙΠΤΕΤΑΙ fail-closed"',
         ':statement "Κενο corpus επιτρεπεται"', "ΑΠΟΚΛΙΝΕΙ"),
    ]

    try:
        for mutant, (old, new, expect) in PROFILE_DRIFTS.items():
            drift_case(mutant, "profile", old, new, expect)
        for field, old, new, expect in PROFILE_FIELD_SWEEP:
            drift_case("profile-field-drift", field, old, new, expect)
    finally:
        shutil.rmtree(drift_root, ignore_errors=True)

# ── ΟΙ ΔΥΟ ΑΛΛΟΙ ΔΗΜΟΣΙΕΥΤΕΣ: εκτελέσιμη απόδειξη, όχι substring ─────────────
# [ΕΥΡΗΜΑ ΚΡΙΤΗ #2] Το census παραγωγών ρίζας στο merkle-single-truth-test
# είναι ΚΕΙΜΕΝΙΚΟ (ελέγχει ότι η άμυνα ΥΠΑΡΧΕΙ στο κείμενο). Εδώ οι πύλες των
# άλλων δύο δημοσιευτών ΕΚΤΕΛΟΥΝΤΑΙ και αποδεικνύονται ΦΕΡΟΥΣΕΣ, με το ίδιο
# πρότυπο GUARDED/UNGUARDED του publish-empty-corpus:
#   census-empty-articles: build-artifact-census με ΚΕΝΟ σύνολο άρθρων ⇒
#     ΑΠΟΡΡΙΨΗ· με τον guard μεταλλαγμένο ώστε να δίνει +empty-tree-hash+ ⇒
#     ΔΕΚΤΟ (θα υπέγραφε δέσμευση για ΤΙΠΟΤΑ) ⇒ ο guard είναι φέρων.
#   tlog-invalid-root (ιστορικό stable id): η σημερινή tlog-append-root!
#     είναι ΚΑΤΑΡΓΗΜΕΝΗ και οφείλει να σηματοδοτεί ΑΚΡΙΒΩΣ
#     legacy-authority-seat-removed για ΚΑΘΕ root. Η μετάλλαξη κάνει
#     μόνο την έδρα να επιστρέφει· ΔΕΝ επαναφέρει legacy writer.
CENSUS_SRC = os.path.join(repo, "systems/orchestrator-epistemic/artifact-census.lisp")
TLOG_SRC   = os.path.join(repo, "systems/orchestrator-epistemic/transparency-log.lisp")
CENSUS_GUARD_OLD = '(error "census: κενό σύνολο άρθρων")'
CENSUS_GUARD_NEW = "orchestrator.merkle:+empty-tree-hash+"
TLOG_SEAT_OLD = """  (%seat-removed "tlog-append-root!"
                 (format nil "απόπειρα authoritative log-append root '~A'" release-root)))"""
TLOG_SEAT_NEW = """  ;; MUTANT: η retired έδρα σιωπά, χωρίς να επαναφερθεί writer.
  :mutant-seat-alive)"""

PUBLISHER_PROBE = r"""
(require :asdf) (require :sb-posix)
(setf asdf:*central-registry* (append (list #p"{repo}/") (directory #p"{repo}/systems/*/")))
(asdf:initialize-source-registry '(:source-registry (:tree #p"{third}") :inherit-configuration))
(locally (declare (sb-ext:muffle-conditions sb-ext:compiler-note style-warning warning))
  (handler-bind ((warning #'muffle-warning))
    (asdf:load-system :alexandria) (asdf:load-system :log4cl)
    (asdf:load-system :orchestrator-epistemic)))
(defun probe-census ()
  (handler-case
      (progn (orchestrator.epistemic::build-artifact-census
              '() "probe" #p"{work}/census-artifacts/"
              :temporal-commitment '(:graph-root "sha256:probe-g"
                                     :receipt-set-root "sha256:probe-r"))
             :accepted)
    (error (e) (let ((s (format nil "~A" e)))
                 (if (search "κενό σύνολο άρθρων" s) :rejected
                     (progn (format t "DIAG-CENSUS ~A~%" s) :other))))))
(defun probe-tlog (dir)
  (handler-case
      (progn (orchestrator.epistemic:tlog-append-root! dir "not-a-root") :accepted)
    (orchestrator.epistemic:legacy-authority-seat-removed (e)
      (if (equal (orchestrator.epistemic:legacy-authority-seat-removed-seat e)
                 "tlog-append-root!")
          :retired
          (progn (format t "DIAG-TLOG WRONG-SEAT ~A~%" e) :other)))
    (error (e) (progn (format t "DIAG-TLOG WRONG-CONDITION ~A ~S~%" e (type-of e))
                      :other))))
(format t "C-GUARDED ~A~%" (probe-census))
(format t "T-GUARDED ~A~%" (probe-tlog #p"{work}/tlog-guarded/"))
;; ΜΕΤΑΛΛΑΞΗ: τα μεταλλαγμένα αντίγραφα φορτώνονται ΠΑΝΩ στην εικόνα
(handler-bind ((warning #'muffle-warning))
  (load "{mut_census}")
  (load "{mut_tlog}"))
(format t "C-UNGUARDED ~A~%" (probe-census))
(format t "T-UNGUARDED ~A~%" (probe-tlog #p"{work}/tlog-unguarded/"))
(sb-ext:exit :code 0)
"""

if not have_sbcl:
    record("census-empty-articles", "policy", -1, "  (BLOCKED — sbcl ΑΠΩΝ)")
    record("tlog-invalid-root", "policy", -1, "  (BLOCKED — sbcl ΑΠΩΝ)")
else:
    with tempfile.TemporaryDirectory(prefix="lawmax-publisher-wit-") as d:
        c_src = open(CENSUS_SRC, encoding="utf-8").read()
        t_src = open(TLOG_SRC, encoding="utf-8").read()
        if CENSUS_GUARD_OLD not in c_src:
            record("census-empty-articles", "policy", 0, "  (::error:: anchor δεν βρέθηκε)")
        elif TLOG_SEAT_OLD not in t_src:
            record("tlog-invalid-root", "policy", 0, "  (::error:: retired-seat anchor δεν βρέθηκε)")
        else:
            mut_census = os.path.join(d, "mut-census.lisp")
            mut_tlog = os.path.join(d, "mut-tlog.lisp")
            open(mut_census, "w", encoding="utf-8").write(
                c_src.replace(CENSUS_GUARD_OLD, CENSUS_GUARD_NEW, 1))
            open(mut_tlog, "w", encoding="utf-8").write(
                t_src.replace(TLOG_SEAT_OLD, TLOG_SEAT_NEW, 1))
            for sub in ("census-artifacts", "tlog-guarded", "tlog-unguarded"):
                os.makedirs(os.path.join(d, sub))
            probe = os.path.join(d, "publishers.lisp")
            open(probe, "w", encoding="utf-8").write(
                PUBLISHER_PROBE.format(repo=repo.rstrip("/"), third=THIRD, work=d,
                                       mut_census=mut_census, mut_tlog=mut_tlog))
            r = subprocess.run(["sbcl", "--script", probe],
                               capture_output=True, text=True, timeout=1800)
            vals = dict(l.split(None, 1) for l in r.stdout.splitlines()
                        if l.split(None, 1) and l.split(None, 1)[0] in
                        ("C-GUARDED", "C-UNGUARDED", "T-GUARDED", "T-UNGUARDED"))
            norm = lambda s: (s or "").strip().lstrip(":").upper()
            c_kill = norm(vals.get("C-GUARDED")) == "REJECTED" and norm(vals.get("C-UNGUARDED")) == "ACCEPTED"
            t_kill = norm(vals.get("T-GUARDED")) == "RETIRED" and norm(vals.get("T-UNGUARDED")) == "ACCEPTED"
            record("census-empty-articles", "policy", 1 if c_kill else 0,
                   "" if c_kill else f"  (guarded={vals.get('C-GUARDED')} unguarded={vals.get('C-UNGUARDED')} rc={r.returncode})")
            record("tlog-invalid-root", "policy", 1 if t_kill else 0,
                   "" if t_kill else f"  (guarded={vals.get('T-GUARDED')} unguarded={vals.get('T-UNGUARDED')} rc={r.returncode})")

killed_n  = [r for r in results if r[3]]
blocked_n = [(m, l) for (m, l, c, k, b, _) in results if b]
survived  = [(m, l) for (m, l, c, k, b, _) in results if not k and not b]
print(f"\n── μάρτυρες: {len(results)} συνολικά, {len(killed_n)} ΣΚΟΤΩΜΕΝΟΙ, "
      f"{len(survived)} ΕΠΙΒΙΩΣΑΝ, {len(blocked_n)} BLOCKED ──")

# ── ΙΣΟΤΗΤΑ ΜΗΤΡΩΟΥ/ΕΦΑΡΜΟΣΜΕΝΩΝ: το profile δεν είναι διακοσμητικό ──
applied = {m for (m, l, c, k, b, _) in results}
reg_only = sorted(REGISTRY - applied)
app_only = sorted(applied - REGISTRY)
census_broken = bool(reg_only or app_only)
if census_broken:
    print(f"::error::ΜΗΤΡΩΟ ≠ ΕΦΑΡΜΟΣΜΕΝΟΙ — δηλωμένοι-ανεφάρμοστοι: {reg_only}, "
          f"εφαρμοσμένοι-αδήλωτοι: {app_only}")
else:
    print(f"μητρώο profile ≡ εφαρμοσμένοι μάρτυρες ({len(REGISTRY)} ids)")
if blocked_n:
    print(f"::error::BLOCKED (εργαλείο ΑΠΟΝ — ΔΕΝ μετρά ως kill): {blocked_n}")
if survived:
    print(f"::error::ΕΠΙΒΙΩΣΑΝ μεταλλάξεις: {survived}")
sys.exit(1 if (survived or blocked_n or census_broken) else 0)
PYTHON
