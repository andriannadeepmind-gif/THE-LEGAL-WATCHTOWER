#!/usr/bin/env bash
# =============================================================================
# ΑΝΤΙΠΑΛΙΚΟ FIXTURE ΤΗΣ ΕΔΡΑΣ CLOSURE ([RATCHET-5])
# =============================================================================
# Η έδρα κρίσης δεν γίνεται εμπιστευτή προτού αποδειχθεί ότι ΑΠΟΡΡΙΠΤΕΙ κάθε
# false-green σενάριο. Πρότυπο: deployment/verify/assess-gate-plenary-test.sh και
# docker/run-standalone-suites-test.sh (η ίδια αρχή που το repo ήδη εφαρμόζει).
#
# ΓΙΑΤΙ ΕΙΝΑΙ ΑΠΑΡΑΙΤΗΤΟ: το προηγούμενο καθεστώς είχε ΚΕΝΟ artifact + inline jq
# στο YAML· κανείς δεν είχε αποδείξει ποτέ ότι ο έλεγχος μπορεί να ΑΠΟΤΥΧΕΙ. Ένας
# verifier χωρίς αρνητικό μάρτυρα είναι ισχυρισμός, όχι απόδειξη.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEAT="$HERE/verify-runtime-closure.sh"
[ -x "$SEAT" ] || chmod +x "$SEAT" 2>/dev/null || true

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0

LOCK="$TMP/deps.lock"
cat > "$LOCK" <<'EOF'
# test lock
alexandria-20241012-git | 1111111111111111111111111111111111111111111111111111111111111111
ironclad-20241012-git | 2222222222222222222222222222222222222222222222222222222222222222
EOF

# Το ΥΓΙΕΣ artifact: κάθε αρνητικό σενάριο είναι μια ΕΛΑΧΙΣΤΗ διαφορά από αυτό.
healthy() {
cat <<'EOF'
{
  "format_version": "1.0",
  "system": "orchestrator-core-runtime",
  "sbcl_version": "2.2.9",
  "closure": [
    {"name":"alexandria","version":"20241012-git","source_id":"third-party/alexandria-20241012-git","hash":"1111111111111111111111111111111111111111111111111111111111111111","origin":"third-party","layer":"runtime"},
    {"name":"ironclad","version":"20241012-git","source_id":"third-party/ironclad-20241012-git","hash":"2222222222222222222222222222222222222222222222222222222222222222","origin":"third-party","layer":"runtime"},
    {"name":"orchestrator-core","version":"1.0.0","source_id":".","hash":"n/a-first-party","origin":"first-party","layer":"runtime"},
    {"name":"sb-posix","version":"unpinned","source_id":"sb-posix","hash":"n/a-sbcl-contrib","origin":"sbcl-contrib","layer":"runtime"}
  ],
  "graph": {
    "orchestrator-core": ["alexandria", "ironclad", "sb-posix"]
  }
}
EOF
}

expect() {                       # expect <όνομα> <αναμενόμενο-exit> <αρχείο>
  local name="$1" want="$2" file="$3"
  VERIFY_HASHES=true bash "$SEAT" "$file" "$LOCK" >"$TMP/out.log" 2>&1
  local got=$?
  if [ "$got" -eq "$want" ]; then
    pass=$((pass+1)); echo "  ok   $name (exit $got)"
  else
    fail=$((fail+1)); echo "  FAIL $name — αναμενόταν exit $want, ελήφθη $got"
    sed 's/^/        /' "$TMP/out.log" | tail -6
  fi
}

echo "== ΘΕΤΙΚΟΣ ΜΑΡΤΥΡΑΣ: υγιές artifact πρέπει να ΠΕΡΝΑΕΙ =="
healthy > "$TMP/healthy.json"
expect "υγιές closure ⇒ exit 0" 0 "$TMP/healthy.json"

echo
echo "== ΑΡΝΗΤΙΚΟΙ ΜΑΡΤΥΡΕΣ: κάθε false-green ΠΡΕΠΕΙ να κοκκινίζει =="

# Ν1 — ΤΟ ΠΡΑΓΜΑΤΙΚΟ ΣΥΜΒΑΝ: κενό closure (ο inline jq περνούσε τετριμμένα)
python3 -c "
import json,sys
d=json.load(open('$TMP/healthy.json')); d['closure']=[]; d['graph']={}
json.dump(d,open('$TMP/empty.json','w'))"
expect "Ν1 ΚΕΝΟ closure ⇒ ΑΠΟΡΡΙΨΗ" 1 "$TMP/empty.json"

# Ν2 — test-layer εξάρτηση μέσα στο runtime closure
python3 -c "
import json
d=json.load(open('$TMP/healthy.json'))
d['closure'].append({'name':'fiveam','version':'x','source_id':'third-party/fiveam-1','hash':'3'*64,'origin':'third-party','layer':'test'})
json.dump(d,open('$TMP/testlayer.json','w'))"
expect "Ν2 test-layer στο runtime ⇒ ΑΠΟΡΡΙΨΗ" 1 "$TMP/testlayer.json"

# Ν3 — ακμή γράφου προς ανύπαρκτη εγγραφή (σπασμένο αμφιμονοσήμαντο)
python3 -c "
import json
d=json.load(open('$TMP/healthy.json'))
d['graph']['orchestrator-core'].append('φάντασμα')
json.dump(d,open('$TMP/dangling.json','w'))"
expect "Ν3 ακμή προς ανύπαρκτο ⇒ ΑΠΟΡΡΙΨΗ" 1 "$TMP/dangling.json"

# Ν4 — κόμβος γράφου εκτός closure
python3 -c "
import json
d=json.load(open('$TMP/healthy.json'))
d['graph']['αδήλωτο-σύστημα']=['alexandria']
json.dump(d,open('$TMP/ghostkey.json','w'))"
expect "Ν4 κόμβος γράφου εκτός closure ⇒ ΑΠΟΡΡΙΨΗ" 1 "$TMP/ghostkey.json"

# Ν5 — pin που ΔΕΝ συμφωνεί με το deps.lock (υποκατάσταση εξάρτησης)
python3 -c "
import json
d=json.load(open('$TMP/healthy.json'))
d['closure'][0]['hash']='9'*64
json.dump(d,open('$TMP/badpin.json','w'))"
expect "Ν5 pin ασύμφωνο με deps.lock ⇒ ΑΠΟΡΡΙΨΗ" 1 "$TMP/badpin.json"

# Ν6 — third-party χωρίς καρφωμένο hash
python3 -c "
import json
d=json.load(open('$TMP/healthy.json'))
d['closure'][1]['hash']='unknown'
json.dump(d,open('$TMP/unpinned.json','w'))"
expect "Ν6 third-party χωρίς pin ⇒ ΑΠΟΡΡΙΨΗ" 1 "$TMP/unpinned.json"

# Ν7 — third-party κατάλογος απών από το deps.lock
python3 -c "
import json
d=json.load(open('$TMP/healthy.json'))
d['closure'].append({'name':'λαθραίο','version':'x','source_id':'third-party/lathraio-1','hash':'4'*64,'origin':'third-party','layer':'runtime'})
d['graph']['orchestrator-core'].append('λαθραίο')
json.dump(d,open('$TMP/notinlock.json','w'))"
expect "Ν7 εξάρτηση εκτός deps.lock ⇒ ΑΠΟΡΡΙΨΗ" 1 "$TMP/notinlock.json"

# Ν8 — ελλιπές πεδίο
python3 -c "
import json
d=json.load(open('$TMP/healthy.json'))
del d['closure'][0]['origin']
json.dump(d,open('$TMP/missingfield.json','w'))"
expect "Ν8 ελλιπές πεδίο ⇒ ΑΠΟΡΡΙΨΗ" 1 "$TMP/missingfield.json"

# Ν9 — first-party με ψευδο-hash αντί ρητής σήμανσης
python3 -c "
import json
d=json.load(open('$TMP/healthy.json'))
d['closure'][2]['hash']='5'*64
json.dump(d,open('$TMP/fakepin.json','w'))"
expect "Ν9 first-party με ψευδο-hash ⇒ ΑΠΟΡΡΙΨΗ" 1 "$TMP/fakepin.json"

# Ν10 — κατεστραμμένο JSON (μερική εγγραφή/crash)
printf '{"format_version": "1.0", "closure": [' > "$TMP/corrupt.json"
expect "Ν10 κατεστραμμένο JSON ⇒ ΑΠΟΡΡΙΨΗ" 1 "$TMP/corrupt.json"

# Ν11 — άγνωστο format_version (σιωπηλή αλλαγή σχήματος)
python3 -c "
import json
d=json.load(open('$TMP/healthy.json')); d['format_version']='9.9'
json.dump(d,open('$TMP/badver.json','w'))"
expect "Ν11 άγνωστο format_version ⇒ ΑΠΟΡΡΙΨΗ" 1 "$TMP/badver.json"

# Ν12 — απόν artifact
expect "Ν12 ανύπαρκτο artifact ⇒ ΑΠΟΡΡΙΨΗ" 1 "$TMP/δεν-υπάρχει.json"

echo
echo "──────── closure seat fixture: $pass ok, $fail FAIL ────────"
[ "$fail" -eq 0 ] || exit 1
echo "✓ η έδρα κρίσης closure απορρίπτει ΚΑΘΕ δοκιμασμένο false-green"
