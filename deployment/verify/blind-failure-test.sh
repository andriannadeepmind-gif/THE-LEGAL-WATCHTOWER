#!/usr/bin/env bash
# LAWMAX BLIND FAILURE-MEMORY TEST (Π0 verification) — πλήρως ΕΡΜΗΤΙΚΟ:
# τρέχει σε προσωρινά αντίγραφα deployment+output. Η παραγωγική μνήμη
# (episodes/history/lessons/failure-ledger) ΔΕΝ αγγίζεται ποτέ.
# Χρήση:  bash deployment/verify/blind-failure-test.sh   (από τη ρίζα του repo)
set -u
D="${D:-$PWD}"
IMAGE="${IMAGE:-orchestrator:latest}"
STAMP=$(date +%s)
TESTDEPLOY="/tmp/lawmax-blind-deployment-$STAMP"
TESTOUT="/tmp/lawmax-blind-output-$STAMP"

echo "═ 1. Αντιγραφή σε προσωρινό test περιβάλλον (η παραγωγή μένει άθικτη)"
cp -r "$D/deployment" "$TESTDEPLOY"
cp -r "$D/output"     "$TESTOUT"
echo "   TESTDEPLOY=$TESTDEPLOY"
echo "   TESTOUT=$TESTOUT"

ask() {  # γράφει ΜΟΝΟ στα προσωρινά αντίγραφα
  docker run --rm \
    -v "$TESTOUT:/app/output" \
    -v "$TESTDEPLOY:/app/deployment" \
    "$IMAGE" --ask "$*"
}
ledger() { cat "$TESTDEPLOY/state/failure-ledger.jsonl" 2>/dev/null; }

echo "═ 2. Ledger ΠΡΙΝ: $(ledger | wc -l) εγγραφές"
echo
echo "═ 3. ΤΩΡΑ τρέξε τις blind ερωτήσεις σου, μία-μία:"
echo '     ask "…η άγνωστη ερώτηση 1…"'
echo '     ask "…η άγνωστη ερώτηση 2…"   κ.ο.κ.'
echo "   Σε καθεμία έλεγξε στο envelope: failure_id / gap_id / memory_recorded: true"
echo
echo "═ 4. Μετά τις blind ερωτήσεις, έλεγχοι:"
echo '   ledger | wc -l                        # πλήθος ΜΕΤΑ (πρέπει +N)'
echo '   ledger | tail -5                      # οι νέες γραμμές'
echo '   ledger | grep "fail:XXXXXXXX"         # το fid από κάθε envelope → ΙΔΙΟ input, "status":"open"'
echo '   ask "δείξε μου τι κατέγραψες"         # ανάκληση: πλήρες record'
echo
echo "═ 5. Αρνητικό τεστ:"
echo '   B=$(ledger | wc -l); ask "ποιος είσαι;" >/dev/null; A=$(ledger | wc -l); echo "πριν=$B μετά=$A (πρέπει ίσα)"'
echo
echo "═ 6. Κανένα δεύτερο ledger (σωστό find με παρενθέσεις):"
echo "   find \"$TESTDEPLOY/self\" \"$TESTDEPLOY/state\" \\( -name '*failure*' -o -name '*ledger*' \\) -print"
echo "   # πρέπει: ΜΟΝΟ $TESTDEPLOY/state/failure-ledger.jsonl"
echo
echo "═ 7. Gates πάνω στο TEST περιβάλλον:"
echo "   docker run --rm -v $TESTOUT:/app/output -v $TESTDEPLOY:/app/deployment $IMAGE --understanding-gate"
echo "   docker run --rm -v $TESTOUT:/app/output -v $TESTDEPLOY:/app/deployment $IMAGE --architecture-constitution-gate"
echo "   docker run --rm -v $TESTOUT:/app/output -v $TESTDEPLOY:/app/deployment $IMAGE --gates"
echo
echo "═ 8. Καθάρισμα (ΜΟΝΟ τα προσωρινά — η παραγωγή δεν αγγίχτηκε ποτέ):"
echo "   rm -rf $TESTDEPLOY $TESTOUT"
echo
echo "Έτοιμο. Οι συναρτήσεις ask/ledger είναι ενεργές σε ΑΥΤΟ το shell αν το"
echo "έτρεξες με:  source deployment/verify/blind-failure-test.sh"
