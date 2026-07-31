#!/usr/bin/env bash
# =============================================================================
# Δ2–Δ3 CLOSURE PROOF — οι ΕΞΙ υποχρεώσεις που έθεσε ο δημιουργός
# =============================================================================
# «Πριν χαρακτηρίσει Δ2–Δ3 κλειστές, να αποδείξει:
#   1. μηδέν definitions ΚΑΙ μηδέν calls των %tlog-write* στο production load graph
#   2. μηδέν production writes στο παλιό releases/
#   3. πραγματικό bundle κάτω από candidates/<root>/, όχι marker μόνο
#   4. frozen fixtures με SHA-256 και provenance από το 57c0cd86
#   5. corruption mutants πάνω στα frozen bytes
#   6. καμία fixture-generation συνάρτηση φορτωμένη από production ASDF»
#
# Κάθε υποχρέωση ελέγχεται ΕΚΤΕΛΕΣΤΙΚΑ πάνω στο ΠΡΑΓΜΑΤΙΚΟ load graph, όχι με
# ισχυρισμό. Απουσία εργαλείου ⇒ BLOCKED (exit 2), ΠΟΤΕ pass.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO"
p=0; f=0
ok(){ p=$((p+1)); echo "  ok   $*"; }
no(){ f=$((f+1)); echo "  FAIL $*"; }

command -v sbcl >/dev/null || { echo "::error::BLOCKED — sbcl ΑΠΩΝ"; exit 2; }

echo "== ① ΜΗΔΕΝ definitions ΚΑΙ ΜΗΔΕΝ calls των %tlog-write* στο PRODUCTION LOAD GRAPH =="
# [ΔΙΟΡΘΩΣΗ] Ο load graph ΔΕΝ εξάγεται με parsing κειμένου .asd (χάνει modules
# και δίνει ψευδώς μικρό σύνολο ⇒ κενός έλεγχος). Ρωτάμε ΤΟ ΙΔΙΟ ΤΟ ASDF ποια
# cl-source-file components ανήκουν στα παραγωγικά systems.
ASD_FILES="$(LAWMAX_REPO="$REPO" sbcl --script "$REPO/authority-v2/tests/probe-emit-load-graph.lisp" 2>/dev/null | grep '\.lisp$')"
N_ASD=$(echo "$ASD_FILES" | grep -c . || true)
[ "$N_ASD" -ge 100 ] && ok "ΠΡΑΓΜΑΤΙΚΟΣ load graph από ASDF: $N_ASD source files" \
                     || no "load graph ύποπτα μικρό ($N_ASD) — ο έλεγχος θα ήταν κενός"

DEFS=$(echo "$ASD_FILES" | xargs grep -l "defun %tlog-write" 2>/dev/null | wc -l)
[ "$DEFS" -eq 0 ] && ok "ΜΗΔΕΝ definitions %tlog-write* στο load graph" \
                  || no "ΒΡΕΘΗΚΑΝ $DEFS definitions"
CALLS=$(echo "$ASD_FILES" | xargs grep -n "(%tlog-write" 2>/dev/null | grep -v "defun" | wc -l)
[ "$CALLS" -eq 0 ] && ok "ΜΗΔΕΝ calls %tlog-write* στο load graph" \
                   || no "ΒΡΕΘΗΚΑΝ $CALLS calls"
# Και εκτελεστικά, στη ΦΟΡΤΩΜΕΝΗ εικόνα:
LOADED=$(LAWMAX_REPO="$REPO" sbcl --script "$REPO/authority-v2/tests/probe-load-graph.lisp" 2>/dev/null | tr -d '\r')
case "$LOADED" in
  *"WRITE-ABSENT"*) ok "στη ΦΟΡΤΩΜΕΝΗ εικόνα: %tlog-write* ΔΕΝ είναι fbound";;
  *)                no "στη φορτωμένη εικόνα: $LOADED";;
esac

echo
echo "== ② ΜΗΔΕΝ production writes στο παλιό releases/ =="
WRITES=$(echo "$ASD_FILES" | xargs grep -nE '(with-open-file|ensure-directories-exist|rename-file|delete-file|sb-posix:symlink)' 2>/dev/null \
         | grep -E '"releases/|releases/~A' | grep -v ";;" | wc -l)
[ "$WRITES" -eq 0 ] && ok "καμία εγγραφή προς releases/ στο load graph" \
                    || { no "ΒΡΕΘΗΚΑΝ $WRITES πιθανές εγγραφές"; \
                         echo "$ASD_FILES" | xargs grep -nE '(with-open-file|ensure-directories-exist|rename-file|delete-file|sb-posix:symlink)' 2>/dev/null | grep -E '"releases/|releases/~A' | head -3; }

echo
echo "== ③ ΠΡΑΓΜΑΤΙΚΟ bundle κάτω από candidates/<root>/, όχι marker =="
BUNDLE=$(LAWMAX_REPO="$REPO" sbcl --script "$REPO/authority-v2/tests/probe-candidate-bundle.lisp" 2>/dev/null | tr -d '\r')
case "$BUNDLE" in
  *"BUNDLE-OK"*) ok "candidates/<root>/ περιέχει ΠΛΗΡΕΣ bundle ($BUNDLE)";;
  *)             no "bundle: $BUNDLE";;
esac

echo
echo "== ④ FROZEN FIXTURES: sha256 + provenance από 57c0cd86 =="
python3 - <<'PY'
import hashlib, json, os, sys
man = json.load(open("authority-v2/fixtures/legacy-tlog/MANIFEST.json", encoding="utf-8"))
bad = 0
for f in man["fixtures"]:
    d = hashlib.sha256(open(f["path"], "rb").read()).hexdigest()
    if d != f["sha256"]:
        print("  FAIL %s: sha256 ≠ manifest" % f["path"]); bad += 1
if man.get("provenance_commit") != "57c0cd868c80f87df8e298c9aa75b8ccf2503391":
    print("  FAIL provenance_commit ≠ 57c0cd86…"); bad += 1
if bad == 0:
    print("  ok   %d frozen fixtures: sha256 ΤΑΥΤΙΖΕΤΑΙ + provenance 57c0cd86" % len(man["fixtures"]))
sys.exit(1 if bad else 0)
PY
[ $? -eq 0 ] && p=$((p+1)) || f=$((f+1))

echo
echo "== ⑤ CORRUPTION MUTANTS πάνω στα FROZEN BYTES =="
MUT=$(LAWMAX_REPO="$REPO" sbcl --script "$REPO/authority-v2/tests/probe-frozen-mutants.lisp" 2>/dev/null | tr -d '\r')
case "$MUT" in
  *"MUTANTS-KILLED"*) ok "corruption mutants στα frozen bytes: $MUT";;
  *)                  no "mutants: $MUT";;
esac

echo
echo "== ⑥ ΚΑΜΙΑ fixture-generation συνάρτηση στο production ASDF =="
GEN=$(echo "$ASD_FILES" | xargs grep -ln "fixture-append\|install-frozen-tlog\|defun.*fixture" 2>/dev/null | wc -l)
[ "$GEN" -eq 0 ] && ok "καμία fixture-generation συνάρτηση στο load graph" \
                 || { no "ΒΡΕΘΗΚΑΝ σε $GEN αρχεία"; echo "$ASD_FILES" | xargs grep -ln "fixture" 2>/dev/null | head -3; }
# Και το ιστορικό αντίγραφο ΔΕΝ επιτρέπεται να δηλωθεί σε .asd:
if grep -rn "REMOVED-tlog-writers" ./*.asd 2>/dev/null | grep -q .; then
  no "το ιστορικό αντίγραφο δηλώνεται σε .asd — ΠΑΡΑΒΑΣΗ"
else
  ok "το ιστορικό αντίγραφο ΔΕΝ δηλώνεται σε κανένα .asd"
fi

echo
echo "── Δ2–Δ3 closure proof: $p passed, $f failed ──"
[ "$f" -eq 0 ]
