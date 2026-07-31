#!/usr/bin/env bash
# =============================================================================
# Η ΜΙΑ ΕΔΡΑ ΚΡΙΣΗΣ ΤΟΥ RUNTIME CLOSURE ([RATCHET-5])
# =============================================================================
# ΓΙΑΤΙ ΥΠΑΡΧΕΙ: το CI καλούσε αυτό το script («Verify Bijective Closure») ενώ
# ΔΕΝ ΥΠΗΡΧΕ σε κανένα commit της ιστορίας — άρα το πρώτο job έσκαγε και ΟΛΑ τα
# υπόλοιπα (needs: dependency-policy-gate) δεν έτρεχαν ΠΟΤΕ. Παράλληλα, το
# committed artifact ήταν ΚΕΝΟ ("closure": []), οπότε ο μόνος πραγματικός
# έλεγχος (layer separation, ως inline jq μέσα στο YAML) περνούσε ΤΕΤΡΙΜΜΕΝΑ:
# jq πάνω σε κενό array δεν βρίσκει ποτέ παράβαση. Δηλαδή «απόδειξη» χωρίς
# περιεχόμενο — ακριβώς η κλάση ψευδο-πράσινου που το ratchet σκοτώνει.
#
# ΑΡΧΗ: ΜΙΑ έδρα κρίσης (καμία πολιτική σε YAML), FAIL-CLOSED σε κάθε ασάφεια,
# και ΔΙΚΟ ΤΗΣ αντιπαλικό fixture (verify-runtime-closure-test.sh) που αποδεικνύει
# ότι απορρίπτει ΚΑΘΕ false-green σενάριο — αλλιώς η ίδια η έδρα είναι ανεπαλήθευτη.
#
# ΣΥΜΒΟΛΑΙΟ:  verify-runtime-closure.sh [artifact] [deps.lock]
#   env VERIFY_HASHES=true|false (default true) — αντιπαραβολή pins με deps.lock
#   exit 0 = ΟΛΟΙ οι έλεγχοι πέρασαν · exit 1 = παράβαση · exit 2 = κακή χρήση
set -euo pipefail

ARTIFACT="${1:-deps/orchestrator-core-runtime.closure.json}"
DEPS_LOCK="${2:-deps.lock}"
VERIFY_HASHES="${VERIFY_HASHES:-true}"

[ -f "$ARTIFACT" ]  || { echo "::error::closure artifact '$ARTIFACT' ΑΝΥΠΑΡΚΤΟ (καμία σιωπηλή παράλειψη)"; exit 1; }
[ -f "$DEPS_LOCK" ] || { echo "::error::deps.lock '$DEPS_LOCK' ΑΝΥΠΑΡΚΤΟ"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "::error::python3 ΑΠΩΝ — ο έλεγχος ΔΕΝ μπορεί να εκτελεστεί (ποτέ πράσινο χωρίς έλεγχο)"; exit 2; }

python3 - "$ARTIFACT" "$DEPS_LOCK" "$VERIFY_HASHES" <<'PYTHON'
import json, re, sys

artifact_path, deps_lock_path, verify_hashes = sys.argv[1], sys.argv[2], sys.argv[3] == "true"
failures, checks = [], 0

def check(name, ok, detail=""):
    global checks
    checks += 1
    if ok:
        print(f"  ok   {name}")
    else:
        print(f"  FAIL {name}{(' — ' + detail) if detail else ''}")
        failures.append(name)

# ── 1. Το artifact είναι αναγνώσιμο JSON γνωστού σχήματος ──
try:
    with open(artifact_path, encoding="utf-8") as fh:
        doc = json.load(fh)
except Exception as exc:                       # corrupt/partial ⇒ ΠΟΤΕ πράσινο
    print(f"::error::το artifact δεν είναι έγκυρο JSON: {exc}")
    sys.exit(1)

check("το artifact είναι JSON αντικείμενο", isinstance(doc, dict))
check("format_version δηλωμένο και γνωστό", doc.get("format_version") == "1.0",
      f"βρέθηκε {doc.get('format_version')!r}")
check("δηλώνεται το σύστημα-στόχος", bool(doc.get("system")))
check("δηλώνεται η έκδοση SBCL", bool(doc.get("sbcl_version")))

closure = doc.get("closure")
graph = doc.get("graph")
check("το closure είναι λίστα", isinstance(closure, list))
check("ο graph είναι αντικείμενο", isinstance(graph, dict))
if failures:
    print(f"\n── runtime-closure: {checks - len(failures)} ok, {len(failures)} FAIL ──")
    sys.exit(1)

# ── 2. ΚΕΝΟ CLOSURE = ΨΕΥΔΗΣ ΑΠΟΔΕΙΞΗ (το ακριβές false-green που συνέβη) ──
check("το closure ΔΕΝ είναι κενό (κενή απόδειξη = ψευδής απόδειξη)", len(closure) > 0,
      "closure: [] — κάθε έλεγχος από κάτω θα περνούσε τετριμμένα")
if not closure:
    print(f"\n── runtime-closure: {checks - len(failures)} ok, {len(failures)} FAIL ──")
    sys.exit(1)

# ── 3. Πληρότητα πεδίων ανά εγγραφή ──
REQUIRED = ("name", "version", "source_id", "hash", "origin", "layer")
incomplete = [e.get("name", "<ΑΝΩΝΥΜΟ>") for e in closure
              if not all(isinstance(e.get(f), str) and e.get(f) for f in REQUIRED)]
check("κάθε εγγραφή φέρει ΟΛΑ τα πεδία", not incomplete, f"ελλιπείς: {incomplete[:5]}")

names = {e.get("name") for e in closure}
check("κανένα διπλό όνομα στο closure", len(names) == len(closure))

# ── 4. ΔΙΑΧΩΡΙΣΜΟΣ ΣΤΡΩΜΑΤΩΝ (ήταν inline jq στο YAML — τώρα στην έδρα) ──
tainted = [e["name"] for e in closure if e.get("layer") in ("test", "tooling")]
check("καμία test/tooling εξάρτηση στο runtime closure", not tainted, f"{tainted}")
check("κάθε layer είναι δηλωμένης τιμής",
      all(e.get("layer") in ("runtime", "test", "tooling") for e in closure))

# ── 5. ΚΑΤΑΓΩΓΗ: καμία εγγραφή «unknown» (τίμια ταξινόμηση, όχι κουβάς) ──
VALID_ORIGINS = ("third-party", "first-party", "sbcl-contrib")
bad_origin = [e["name"] for e in closure if e.get("origin") not in VALID_ORIGINS]
check("κάθε εγγραφή έχει ταξινομημένη καταγωγή", not bad_origin, f"{bad_origin[:5]}")

# ── 6. ΑΜΦΙΜΟΝΟΣΗΜΑΝΤΟ (αυτό που το βήμα του CI υποσχόταν ονομαστικά) ──
graph_keys = set(graph)
dangling_keys = graph_keys - names
check("κάθε κόμβος του γράφου υπάρχει στο closure", not dangling_keys,
      f"{sorted(dangling_keys)[:5]}")

edge_targets = {v for vs in graph.values() for v in vs}
dangling_edges = edge_targets - names
check("κάθε ακμή του γράφου δείχνει σε υπαρκτή εγγραφή", not dangling_edges,
      f"{sorted(dangling_edges)[:5]}")

# ── 7. PINS: κάθε third-party εξάρτηση καρφωμένη ΚΑΙ σύμφωνη με το deps.lock ──
pins = {}
with open(deps_lock_path, encoding="utf-8") as fh:
    for line in fh:
        line = line.strip()
        if not line or line.startswith("#") or "|" not in line:
            continue
        dirname, digest = (part.strip() for part in line.split("|", 1))
        pins[dirname] = digest

third_party = [e for e in closure if e.get("origin") == "third-party"]
check("υπάρχουν third-party εξαρτήσεις προς επαλήθευση", len(third_party) > 0)

unpinned = [e["name"] for e in third_party if not re.fullmatch(r"[0-9a-f]{64}", e["hash"])]
check("κάθε third-party εγγραφή φέρει sha256 (64 hex)", not unpinned, f"{unpinned[:5]}")

def pinned_dir(source_id):
    parts = [p for p in source_id.split("/") if p]
    if not parts:
        return None
    return parts[1] if parts[0] == "third-party" and len(parts) > 1 else parts[0]

if verify_hashes:
    mismatched, absent = [], []
    for entry in third_party:
        directory = pinned_dir(entry["source_id"])
        if directory not in pins:
            absent.append(f"{entry['name']}→{directory}")
        elif pins[directory] != entry["hash"]:
            mismatched.append(entry["name"])
    check("κάθε third-party κατάλογος υπάρχει στο deps.lock", not absent, f"{absent[:5]}")
    check("κάθε pin ΣΥΜΦΩΝΕΙ με το deps.lock", not mismatched, f"{mismatched[:5]}")
else:
    print("  --   αντιπαραβολή hashes ΠΑΡΑΛΕΙΦΘΗΚΕ (VERIFY_HASHES=false) — δηλωμένο όριο")

# ── 8. Οι μη-third-party φέρουν ΡΗΤΗ σήμανση, ποτέ ψευδο-hash ──
EXPECTED_MARKS = {"first-party": "n/a-first-party", "sbcl-contrib": "n/a-sbcl-contrib"}
mismarked = [e["name"] for e in closure
             if e.get("origin") in EXPECTED_MARKS and e["hash"] != EXPECTED_MARKS[e["origin"]]]
check("first-party/sbcl-contrib φέρουν ρητή σήμανση αντί ψευδο-hash", not mismarked,
      f"{mismarked[:5]}")

passed = checks - len(failures)
print(f"\n── runtime-closure: {passed} ok, {len(failures)} FAIL "
      f"({len(closure)} εξαρτήσεις, {len(third_party)} third-party καρφωμένες) ──")
sys.exit(1 if failures else 0)
PYTHON
