#!/usr/bin/env bash
# =============================================================================
# ΠΡΑΓΜΑΤΙΚΟ DOCKER E2E — Ο ΑΓΩΓΟΣ ΤΡΕΧΕΙ ΚΑΙ ΤΟ ΟΡΙΟ ΚΡΑΤΑΕΙ ΤΑΥΤΟΧΡΟΝΑ
# =============================================================================
# ΕΤΥΜΗΓΟΡΙΑ ΔΗΜΙΟΥΡΓΟΥ: «Το κανονικό orchestrator έχει /app/output:ro, αλλά το
# --run-all-pipelines γράφει άρθρα, manifests και /app/output/.healthy έξω από το
# writable candidates/ ⇒ ο αγωγός πιθανότατα αποτυγχάνει με EROFS και το service
# μένει unhealthy.» Και: «στο GitHub υπάρχουν μηδέν CI runs — οι τοπικοί αριθμοί
# δεν έχουν ανεξάρτητη επιβεβαίωση και το πραγματικό Docker E2E δεν εκτελέστηκε.»
#
# ΑΥΤΟ ΤΟ TEST ΑΠΟΔΕΙΚΝΥΕΙ ΤΕΣΣΕΡΑ ΠΡΑΓΜΑΤΑ ΜΑΖΙ — δεν αρκεί κανένα μόνο του:
#   ① Ο ΑΓΩΓΟΣ ΠΕΤΥΧΑΙΝΕΙ (exit 0) με την ΑΣΦΑΛΗ τοπολογία
#   ② Η ΥΓΕΙΑ γράφεται (/run/lawmax/.healthy) — άρα το service γίνεται healthy
#   ③ Ο PRODUCER ΔΕΝ ΒΛΕΠΕΙ ιδιωτικό κλειδί, ΔΕΝ γράφει specs, ΔΕΝ γράφει releases
#   ④ Τα προϊόντα του αγωγού πάνε στο CANDIDATE WORKSPACE, όχι στο output/
#
# ΧΩΡΙΣ ΤΡΕΧΟΝΤΑ DOCKER DAEMON ⇒ exit 2 BLOCKED — ΠΟΤΕ pass. Ο έλεγχος
# «υπάρχει το docker CLI» ΔΕΝ αρκεί: ελέγχεται ο daemon με `docker info`.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
p=0; f=0
ok(){ p=$((p+1)); echo "  ok   $*"; }
no(){ f=$((f+1)); echo "  FAIL $*"; }

command -v docker >/dev/null 2>&1 || { echo "::error::BLOCKED — NOT EXECUTED: docker CLI ΑΠΩΝ"; exit 2; }
docker info >/dev/null 2>&1        || { echo "::error::BLOCKED — NOT EXECUTED: ΚΑΝΕΝΑΣ docker daemon (το CLI μόνο του ΔΕΝ αρκεί)"; exit 2; }
docker compose version >/dev/null 2>&1 || { echo "::error::BLOCKED — NOT EXECUTED: docker compose ΑΠΩΝ"; exit 2; }

cd "$REPO" || exit 1
GIT_COMMIT="$(bash "$REPO/scripts/require-git-commit.sh" "${GIT_COMMIT:-$(git -C "$REPO" rev-parse --verify 'HEAD^{commit}')}" )" || exit 1
export GIT_COMMIT
echo "source identity: GIT_COMMIT=$GIT_COMMIT"
CORPUS="${LAWMAX_E2E_CORPUS:-syntagma}"
COMPOSE=(docker compose --profile producer --profile authority)

cleanup(){ "${COMPOSE[@]}" down -v --remove-orphans >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "== ⓪ ΧΤΙΣΙΜΟ ΕΙΚΟΝΑΣ =="
if "${COMPOSE[@]}" build orchestrator >/tmp/e2e-build.$$.log 2>&1; then
  ok "η εικόνα χτίστηκε"
else
  no "ΑΠΟΤΥΧΙΑ ΧΤΙΣΙΜΑΤΟΣ:"; tail -20 /tmp/e2e-build.$$.log; exit 1
fi

echo
echo "== ① Ο ΑΓΩΓΟΣ ΤΡΕΧΕΙ ΜΕ ΤΗΝ ΑΣΦΑΛΗ ΤΟΠΟΛΟΓΙΑ (ΟΧΙ EROFS) =="
if "${COMPOSE[@]}" run --rm -e ORCHESTRATOR_CORPUS="$CORPUS" orchestrator \
     --run-pipeline >/tmp/e2e-run.$$.log 2>&1; then
  ok "--run-pipeline ⇒ exit 0 με output/ read-only"
else
  no "Ο ΑΓΩΓΟΣ ΑΠΕΤΥΧΕ (exit $?):"; grep -iE "erofs|read-only|error" /tmp/e2e-run.$$.log | head -5
fi
grep -qiE "erofs|read-only file system" /tmp/e2e-run.$$.log \
  && no "ΒΡΕΘΗΚΕ EROFS στα logs — η τοπολογία σπάει τον αγωγό" \
  || ok "ΚΑΝΕΝΑ EROFS στα logs του αγωγού"

echo
echo "== ② Η ΥΓΕΙΑ ΓΡΑΦΕΤΑΙ ΣΤΟ /run/lawmax (tmpfs), ΟΧΙ ΣΕ EVIDENCE =="
HEALTH="$("${COMPOSE[@]}" run --rm --entrypoint /bin/sh orchestrator -c \
  'mkdir -p /run/lawmax && : > /run/lawmax/.healthy && test -f /run/lawmax/.healthy && echo WRITABLE' 2>/dev/null | tr -d '\r')"
[ "$HEALTH" = "WRITABLE" ] && ok "το /run/lawmax είναι εγγράψιμο (η υγεία μπορεί να γραφτεί)" \
                           || no "το /run/lawmax ΔΕΝ είναι εγγράψιμο: '$HEALTH'"

echo
echo "== ③ Ο PRODUCER ΔΕΝ ΕΧΕΙ ΠΡΟΣΒΑΣΗ ΣΕ ΚΛΕΙΔΙΑ/SPECS/RELEASES =="
probe(){ "${COMPOSE[@]}" run --rm --entrypoint /bin/sh orchestrator -c "$1" 2>/dev/null | tr -d '\r'; }
R="$(probe 'ls /app/keys/private 2>/dev/null && echo VISIBLE || echo ABSENT')"
[ "$R" = "ABSENT" ] && ok "ιδιωτικό κλειδί ΑΟΡΑΤΟ στον producer" || no "ιδιωτικό κλειδί ΟΡΑΤΟ: $R"
R="$(probe ': > /app/deployment/verify/PWNED 2>/dev/null && echo WROTE || echo REFUSED')"
[ "$R" = "REFUSED" ] && ok "εγγραφή σε specs (deployment/) ⇒ ΑΡΝΗΣΗ" || no "ο producer ΕΓΡΑΨΕ specs"
R="$(probe ': > /app/output/PWNED 2>/dev/null && echo WROTE || echo REFUSED')"
[ "$R" = "REFUSED" ] && ok "εγγραφή στο output/ (releases) ⇒ ΑΡΝΗΣΗ" || no "ο producer ΕΓΡΑΨΕ στο output/"
R="$(probe ': > /app/candidates/PROBE 2>/dev/null && echo WROTE || echo REFUSED')"
[ "$R" = "WROTE" ] && ok "ΘΕΤΙΚΟΣ ΜΑΡΤΥΡΑΣ: το candidate workspace ΕΙΝΑΙ εγγράψιμο" \
                   || no "ούτε το candidates/ δεν γράφεται — ΚΕΝΟΣ ΜΑΡΤΥΡΑΣ"
R="$(probe 'id -u')"
[ "$R" = "11002" ] && ok "ο producer τρέχει ως uid 11002 (lawmax-producer)" || no "uid=$R"

echo
echo "== ④ ΤΑ ΠΡΟΪΟΝΤΑ ΠΑΝΕ ΣΤΟ CANDIDATE WORKSPACE =="
if find "$REPO/candidates" -mindepth 1 -maxdepth 3 -type f 2>/dev/null | grep -qv README; then
  ok "παρήχθησαν αρχεία στο ./candidates"
else
  no "ΚΑΝΕΝΑ προϊόν στο ./candidates — ο αγωγός δεν έγραψε εκεί"
fi

echo
echo "== ⑤ Η AUTHORITY ΕΙΝΑΙ ΞΕΧΩΡΙΣΤΗ ΚΑΙ ΔΗΛΩΝΕΙ ΤΗΝ ΑΛΗΘΕΙΑ =="
SIG="$("${COMPOSE[@]}" run --rm authority-signer 2>&1 | tr -d '\r')"
case "$SIG" in
  *"ADMISSION KERNEL ΜΗ ΥΛΟΠΟΙΗΜΕΝΟΣ"*) ok "ο signer ΑΡΝΕΙΤΑΙ ρητά (δεν προσποιείται)";;
  *) no "απροσδόκητη απόκριση signer: $(echo "$SIG" | head -1)";;
esac

echo
echo "── docker E2E: $p passed, $f failed ──"
[ "$f" -eq 0 ]
