#!/usr/bin/env bash
# =============================================================================
# Η ΜΙΑ ΕΔΡΑ ΚΡΙΣΗΣ ΤΗΣ ΟΛΟΜΕΛΕΙΑΣ ΠΥΛΩΝ ([audit#1]/CI false-green killer)
# =============================================================================
# ΓΙΑΤΙ ΥΠΑΡΧΕΙ: το authoritative CI έκρινε την ολομέλεια με `docker run … | tee`
# ΧΩΡΙΣ pipefail και ΧΩΡΙΣ έλεγχο exit code — το `tee` επέστρεφε 0 ακόμη κι όταν το
# docker κατέρρεε, και η πολιτική αποδοχής («μόνο advisor-gate κόκκινο») ζούσε ως
# grep ΜΕΣΑ στο YAML: μη-δοκιμάσιμη, εύκολα παρακάμψιμη. Και τα δύο = false-green.
#
# ΤΙ ΚΑΝΕΙ: δέχεται (1) το log της ολομέλειας και (2) το ΠΡΑΓΜΑΤΙΚΟ exit status του
# `docker run --gates` (μέσω ${PIPESTATUS[0]} υπό pipefail). Κρίνει με ΡΗΤΟ συμβόλαιο
# exit code — καμία λογική στο YAML, μία έδρα, δοκιμασμένη από αρνητικό fixture
# (assess-gate-plenary-test.sh). ΚΑΘΕ κλάδος αποτυχίας είναι διακριτός κωδικός.
#
# ΣΥΜΒΟΛΑΙΟ:
#   argv[1] = log path (stdout+stderr της ολομέλειας)
#   argv[2] = docker exit status (ακέραιος· ${PIPESTATUS[0]})
#   env GATE_BASELINE_EXCEPTIONS = whitespace-separated ονόματα πυλών που ΕΠΙΤΡΕΠΕΤΑΙ
#       να είναι κόκκινες σε ΑΥΤΟ το περιβάλλον (default: "advisor-gate").
#
#   exit 0 = ΑΠΟΔΕΚΤΗ ολομέλεια (ολοκληρώθηκε ΚΑΙ καμία μη-εξαιρεμένη πύλη κόκκινη)
#   exit 2 = κακή χρήση (λείπει όρισμα/log)
#   exit 3 = ΜΗ ΟΛΟΚΛΗΡΩΜΕΝΗ ολομέλεια (λείπει η σφραγίδα-footer ⇒ crash/OOM/segv
#            πριν τυπωθεί η ετυμηγορία — ΑΚΡΙΒΩΣ το false-green που σκοτώνουμε)
#   exit 4 = μη-πυλικό docker exit (≠0,≠1 ⇒ crash/OOM/docker infra error)
#   exit 5 = πύλη ΠΕΡΑΝ των δηλωμένων baseline exceptions απέτυχε
#   exit 6 = ΑΝΤΙΦΑΣΗ: docker exit 0 αλλά υπάρχει κόκκινη πύλη στο log (ή το αντίστροφο)
#
# Η σφραγίδα-footer «════ ΟΛΟΜΕΛΕΙΑ ΠΥΛΩΝ (N) ════» τυπώνεται από τον run-all-gates
# (systems/orchestrator-cli/gates-runner.lisp) ΜΟΝΟ αφού τρέξουν ΟΛΕΣ οι πύλες — άρα
# η παρουσία της είναι ΘΕΤΙΚΗ απόδειξη ολοκλήρωσης, όχι απλό string match.
set -u

FOOTER='════ ΟΛΟΜΕΛΕΙΑ ΠΥΛΩΝ'
# Γραμμή αποτυχίας πύλης: ο runner τυπώνει «  <name>: ΑΠΕΤΥΧΕ» (name λήγει σε -gate).
FAIL_RE='gate: ΑΠΕΤΥΧΕ'

log="${1:-}"
status="${2:-}"
exceptions="${GATE_BASELINE_EXCEPTIONS:-advisor-gate}"

if [ -z "$log" ] || [ -z "$status" ]; then
  echo "assess-gate-plenary: χρήση: $0 <log-path> <docker-exit-status>" >&2
  exit 2
fi
if [ ! -f "$log" ]; then
  echo "::error::assess-gate-plenary: το log '$log' δεν υπάρχει." >&2
  exit 2
fi
case "$status" in
  ''|*[!0-9]*) echo "::error::assess-gate-plenary: μη-αριθμητικό status '$status'." >&2; exit 2 ;;
esac

# (1) ΑΠΟΔΕΙΞΗ ΟΛΟΚΛΗΡΩΣΗΣ — η σφραγίδα πρέπει να υπάρχει.
if ! grep -q "$FOOTER" "$log"; then
  echo "::error::Η ολομέλεια ΔΕΝ ολοκληρώθηκε: λείπει η σφραγίδα-footer (crash/OOM πριν την ετυμηγορία· docker exit=$status)." >&2
  exit 3
fi

# (2) INFRA EXIT — μόνο 0/1 είναι πυλικά· καθετί άλλο (125 docker, 137 OOM, 139 segv…) = crash.
if [ "$status" != "0" ] && [ "$status" != "1" ]; then
  echo "::error::Μη-πυλικό docker exit ($status) — crash/OOM/docker infra error, όχι ετυμηγορία πύλης." >&2
  exit 4
fi

# Συλλογή των κόκκινων πυλών από το log.
red_lines="$(grep "$FAIL_RE" "$log" || true)"

# (3) ΠΟΛΙΤΙΚΗ — κάθε κόκκινη πύλη πρέπει να είναι δηλωμένη baseline exception.
offending="$red_lines"
for exc in $exceptions; do
  offending="$(printf '%s\n' "$offending" | grep -v "$exc" || true)"
done
offending="$(printf '%s\n' "$offending" | grep "$FAIL_RE" || true)"
if [ -n "$offending" ]; then
  echo "::error::Πύλη πέραν των baseline exceptions ($exceptions) απέτυχε:" >&2
  printf '%s\n' "$offending" >&2
  exit 5
fi

# (4) ΑΝΤΙΦΑΣΗ — docker exit 0 αλλά κόκκινη πύλη στο log (ή exit 1 χωρίς καμία κόκκινη).
has_red="$(printf '%s' "$red_lines" | grep -c "$FAIL_RE" || true)"
if [ "$status" = "0" ] && [ "$has_red" != "0" ]; then
  echo "::error::ΑΝΤΙΦΑΣΗ: docker exit 0 αλλά $has_red κόκκινη(ες) πύλη(ες) στο log." >&2
  exit 6
fi
if [ "$status" = "1" ] && [ "$has_red" = "0" ]; then
  echo "::error::ΑΝΤΙΦΑΣΗ: docker exit 1 αλλά καμία κόκκινη πύλη στο log (πιθανό μη-πυλικό σφάλμα)." >&2
  exit 6
fi

echo "✓ Ολομέλεια ΑΠΟΔΕΚΤΗ: ολοκληρώθηκε, docker exit=$status, μόνο baseline exceptions ($exceptions) κόκκινες."
exit 0
