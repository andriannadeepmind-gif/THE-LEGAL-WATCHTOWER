#!/usr/bin/env bash
# LAWMAX SELF-UNDERSTANDING / DIALOGUE AUDIT v1
# External audit: functional self-understanding & dialogue cognition (A–G),
# per the creator's directive of 2026-07-07. Runs the SAME image the user runs.
# Internal twin: the ΑΥΤΟΚΑΤΑΝΟΗΣΗ section of --dialogue-gate (73 checks).
#
# Usage (NixOS):  ROOT=~/STAVROPOULOSLAWCORPUS bash self-understanding-audit-v1.sh
set -u
ROOT="${ROOT:-$HOME/STAVROPOULOSLAWCORPUS}"
IMAGE="${IMAGE:-orchestrator:latest}"
OUT="$ROOT/output/self-understanding-audit-v1"
mkdir -p "$OUT"
SUMMARY="$OUT/SUMMARY.txt"
: > "$SUMMARY"
PASS=0; FAIL=0

run() { # label args...
  local label="$1"; shift
  docker run --rm \
    -v "$ROOT/output:/app/output" -v "$ROOT/deployment:/app/deployment" \
    "$IMAGE" "$@" > "$OUT/$label.txt" 2>&1
  echo "EXIT:$?" >> "$OUT/$label.txt"
}

check() { # name file must-contain... (ALL must match; prefix pattern with ! to REQUIRE ABSENCE)
  local name="$1" file="$2"; shift 2
  local ok=1 p
  for p in "$@"; do
    if [[ "$p" == !* ]]; then
      grep -qF -- "${p#!}" "$OUT/$file.txt" && ok=0
    else
      grep -qF -- "$p" "$OUT/$file.txt" || ok=0
    fi
  done
  if [[ $ok == 1 ]]; then echo "[PASS] $name" | tee -a "$SUMMARY"; PASS=$((PASS+1))
  else echo "[FAIL] $name (log: $OUT/$file.txt)" | tee -a "$SUMMARY"; FAIL=$((FAIL+1)); fi
}

echo "LAWMAX SELF-UNDERSTANDING AUDIT v1 — $(date -Is)" | tee -a "$SUMMARY"

# A. Self/meta — answered from the self-model, never via corpus keyword scan
run a1 --ask "ποιος είσαι;"
check "A1 identity from self-model"            a1 "LAWMAX" "mode: self-meta"
run a2 --ask "τι σκέφτεσαι τώρα;"
check "A2 live cognitive state (not refusal)"  a2 "γνωσιακή" "στόχοι" "mode: self-meta" '!δεν έχω ακόμη δομημένη'
run a3 --ask "τι σημαίνει δομημένη απάντηση;"
check "A3/G own term via self-glossary, no corpus scan" a3 "ΠΡΟΘΕΣΗ" "mode: self-meta" '!ΟΡΙΖΕΤΑΙ στα κείμενα'
run a4 --ask "τι μπορείς να κάνεις;"
check "A4 capabilities"                        a4 "mode: self-meta"
run a5 --ask "τι δεν μπορείς να κάνεις;"
check "A5 declared limits/debts"               a5 "ΧΡΕΟΣ" "Συνταγματικά αδύνατα" "mode: self-meta"

# C. Existing capability exposure — guard-metaeval, non-legal envelope
run c1 --ask "1+1=?"
check "C arithmetic via guard-metaeval"        c1 "= 2" "guard-metaeval" "mode: general" "trusted_legal_output: false"

# D. General/non-legal — language understood, capability honestly absent
run d1 --ask "πόσα γράμματα έχει η ελληνική αλφαβήτα;"
check "D general question ≠ «δεν κατάλαβα»"    d1 "ΓΕΝΙΚΗΣ γνώσης" "mode: general" '!Δεν κατάλαβα την ερώτηση'

# F. Mode envelope on every answer (legal too)
run f1 --ask "τι λέει το άρθρο 372 του ποινικού κώδικα;"
check "F legal answer carries mode+corpus"     f1 "mode: legal-trusted" "corpus_used: true" "trusted_legal_output: true"

# E. Gap ledger is inspectable (fresh process ⇒ ledger paths & counters shown)
run e1 --ask "πού το κατέγραψες;"
check "E gap ledger inspectable"               e1 "lessons" "επεισόδια" "προτάσεις"

# B. Follow-up — needs one PROCESS with two turns: exercised by the internal
# twin (--dialogue-gate check Β with shared working-memory) since each docker
# run is a fresh process. Verify the twin here:
run b1 --dialogue-gate
check "B follow-up binding (internal twin gate green)" b1 "ΠΥΛΗ ΔΙΑΛΟΓΟΥ: 73/73"

echo | tee -a "$SUMMARY"
echo "PASS: $PASS  FAIL: $FAIL" | tee -a "$SUMMARY"
if [[ $FAIL -eq 0 ]]; then echo "OVERALL: PASS" | tee -a "$SUMMARY"; exit 0
else echo "OVERALL: FAIL" | tee -a "$SUMMARY"; exit 1; fi
