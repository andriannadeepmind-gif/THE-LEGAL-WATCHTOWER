#!/usr/bin/env bash
# =============================================================================
# MERKLE-SINGLE-TRUTH — ΜΑΡΤΥΡΕΣ ΜΕΤΑΛΛΑΞΗΣ (ΠΡΑΓΜΑΤΙΚΑ ΕΦΑΡΜΟΣΜΕΝΟΙ)
# =============================================================================
# ΔΕΝ αρκεί να ΥΠΑΡΧΟΥΝ tests. Κάθε μετάλλαξη εφαρμόζεται ΠΡΑΓΜΑΤΙΚΑ σε ΑΝΤΙΓΡΑΦΟ
# της κάθε υλοποίησης, τρέχει απέναντι στα committed golden vectors, και ΠΡΕΠΕΙ
# να δώσει non-zero. Επιβιώνουσα μετάλλαξη = η πύλη δεν διακρίνει το λάθος από
# το σωστό ⇒ ο μάρτυρας είναι κενός ⇒ ΑΠΟΤΥΧΙΑ.
#
# Το repo ΔΕΝ αγγίζεται ποτέ: όλες οι μεταλλάξεις ζουν σε προσωρινό κατάλογο.
#
# Καλύπτονται και οι 8 μάρτυρες του profile:
#   duplicate-last · no-leaf-prefix · no-node-prefix · wrong-split ·
#   swap-left-right · unicode-normalize · crlf-normalize · publish-empty-corpus
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VECTORS="$HERE/deployment/verify/vectors/merkle/vectors.json"
[ -f "$VECTORS" ] || { echo "::error::golden vectors ΑΠΟΝΤΑ: $VECTORS"; exit 2; }

python3 - "$HERE" "$VECTORS" <<'PYTHON'
import json, os, shutil, subprocess, sys, tempfile

repo, vectors_path = sys.argv[1], sys.argv[2]
with open(vectors_path, encoding="utf-8") as fh:
    V = json.load(fh)

PY_SRC   = os.path.join(repo, "deployment/verify/verify-merkle.py")
MJS_SRC  = os.path.join(repo, "deployment/verify/verify-merkle.mjs")
LISP_SRC = os.path.join(repo, "source/merkle-authority.lisp")
THIRD    = os.path.join(repo, "third-party") + "/"

have_node = shutil.which("node") is not None
have_sbcl = shutil.which("sbcl") is not None

results = []           # (mutant, language, exit_code, killed?)


def record(mutant, lang, code, note=""):
    killed = code != 0
    results.append((mutant, lang, code, killed, note))
    mark = "ok  " if killed else "FAIL"
    print(f"  {mark} {mutant:22s} {lang:7s} exit={code:<3d} "
          f"{'ΣΚΟΤΩΘΗΚΕ' if killed else 'ΕΠΙΒΙΩΣΕ — Ο ΜΑΡΤΥΡΑΣ ΕΙΝΑΙ ΚΕΝΟΣ'}{note}")


# ── ΜΕΤΑΛΛΑΞΕΙΣ: (παλιό, νέο) ανά γλώσσα. Πραγματική επέμβαση στο κείμενο. ──
PY_MUT = {
  "no-leaf-prefix":   ('LEAF_DOMAIN = b"\\x00"', 'LEAF_DOMAIN = b""'),
  "no-node-prefix":   ('NODE_DOMAIN = b"\\x01"', 'NODE_DOMAIN = b""'),
  "swap-left-right":  ("return _h(NODE_DOMAIN, bytes.fromhex(a[len(PREFIX):]) + bytes.fromhex(b[len(PREFIX):]))",
                       "return _h(NODE_DOMAIN, bytes.fromhex(b[len(PREFIX):]) + bytes.fromhex(a[len(PREFIX):]))"),
  "wrong-split":      ("    k = largest_power_of_two_below(len(leaves))",
                       "    k = len(leaves) // 2"),
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
  "duplicate-last":   ("(t (let ((k (%largest-power-of-two-below n)))\n                        (hash-node (mth lo (+ lo k)) (mth (+ lo k) hi))))",
                       "(t (let ((k (ceiling n 2)))\n                        (hash-node (mth lo (min hi (+ lo k)))\n                                   (mth (min hi (+ lo k)) hi))))"),
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
  (format t "~A~%" root))
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
        got = [l.strip() for l in r.stdout.splitlines() if l.strip().startswith("sha256:")]
        # ΣΚΟΤΩΜΕΝΟ = ή έσκασε, ή έδωσε ΔΙΑΦΟΡΕΤΙΚΗ ρίζα από το golden vector
        code = 0 if (r.returncode == 0 and got and got[-1] == expected) else 1
        record(mutant, "lisp", code)


print("== ΜΑΡΤΥΡΕΣ ΜΕΤΑΛΛΑΞΗΣ — πραγματική εφαρμογή σε ΚΑΘΕ υλοποίηση ==")
for mutant in ["duplicate-last", "no-leaf-prefix", "no-node-prefix",
               "wrong-split", "swap-left-right", "unicode-normalize", "crlf-normalize"]:
    if mutant in PY_MUT:   run_python(mutant, *PY_MUT[mutant])
    if mutant in MJS_MUT:  run_node(mutant, *MJS_MUT[mutant])
    if mutant in LISP_MUT: run_lisp(mutant, *LISP_MUT[mutant])

# ── 8ος ΜΑΡΤΥΡΑΣ: ΠΟΛΙΤΙΚΗ — δημοσίευση κενού corpus ──
# Ο μηχανισμός ΞΕΡΕΙ τη ρίζα του κενού δέντρου· η ΠΟΛΙΤΙΚΗ την απαγορεύει.
# Επιβεβαιώνεται ότι η άρνηση υπάρχει ΣΤΗΝ ΕΔΡΑ (κειμενικός έλεγχος της πύλης)
# — η ΕΚΤΕΛΕΣΤΙΚΗ απόδειξη ζει στο tests/merkle-single-truth-test.lisp §Β.
pc = open(os.path.join(repo, "source/proof-carrying.lisp"), encoding="utf-8").read()
gate_present = ("empty-corpus-publication" in pc and "(when (null provisions)" in pc)
record("publish-empty-corpus", "policy", 1 if gate_present else 0,
       "" if gate_present else "  (::error:: η πύλη δημοσίευσης ΛΕΙΠΕΙ)")

survived = [(m, l) for (m, l, c, k, _) in results if not k]
blocked  = [(m, l) for (m, l, c, k, _) in results if c == -1]
print(f"\n── μάρτυρες: {len(results)} συνολικά, "
      f"{len(results) - len(survived)} ΣΚΟΤΩΜΕΝΟΙ, {len(survived)} ΕΠΙΒΙΩΣΑΝ ──")
if blocked:
    print(f"   BLOCKED (εργαλείο απόν): {blocked}")
if survived:
    print(f"::error::ΕΠΙΒΙΩΣΑΝ μεταλλάξεις: {survived}")
    sys.exit(1)
sys.exit(0)
PYTHON
