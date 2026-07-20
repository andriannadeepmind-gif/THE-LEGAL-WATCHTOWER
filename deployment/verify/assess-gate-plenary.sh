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

# [re-review CRITICAL/HIGH] Η σφραγίδα-footer ΔΕΝ είναι πλέον bare substring: απαιτείται
# LINE-ANCHORED με τον αριθμό πυλών «════ ΟΛΟΜΕΛΕΙΑ ΠΥΛΩΝ (N) ════», ΚΑΙ ο N πρέπει να
# ισούται με το πλήθος γραμμών ετυμηγορίας ΚΑΙ να είναι ≥ floor. Έτσι:
#   • zero-gate «(0)» ⇒ απορρίπτεται (δεν έτρεξε καμία πύλη),
#   • footer echoed σε debug/dialogue γραμμή (substring) ⇒ ΔΕΝ ταιριάζει το anchored regex,
#   • truncated/crashed run (footer λέει N αλλά τυπώθηκαν < N ετυμηγορίες) ⇒ mismatch.
FOOTER_RE='^[[:space:]]*════ ΟΛΟΜΕΛΕΙΑ ΠΥΛΩΝ \(([0-9]+)\) ════[[:space:]]*$'
# Γραμμή ετυμηγορίας πύλης: ο runner τυπώνει «  <name>: ΠΕΡΑΣΕ|ΑΠΕΤΥΧΕ» (name λήγει σε -gate).
VERDICT_RE='gate: (ΠΕΡΑΣΕ|ΑΠΕΤΥΧΕ)'
FAIL_RE='gate: ΑΠΕΤΥΧΕ'

log="${1:-}"
status="${2:-}"
exceptions="${GATE_BASELINE_EXCEPTIONS:-advisor-gate}"
# Ελάχιστο πλήθος πυλών ολομέλειας — φράζει το «η ολομέλεια συρρικνώθηκε σιωπηλά».
# Default 1 (καμία μηδενική ολομέλεια)· το CI δένει τον πραγματικό αριθμό.
plenary_min="${GATE_PLENARY_MIN:-1}"
# ΑΝΩΤΕΡΗ επιβολή: ΑΚΡΙΒΗΣ αναμενόμενος αριθμός πυλών. Set ⇒ N πρέπει να ισούται
# ΑΚΡΙΒΩΣ (πιάνει σιωπηλή συρρίκνωση 12→8 όπου όλες περνούν)· κενό ⇒ μόνο floor.
plenary_expect="${GATE_PLENARY_EXPECT:-}"

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

# (1) ΑΠΟΔΕΙΞΗ ΟΛΟΚΛΗΡΩΣΗΣ — anchored footer + N + N==πλήθος ετυμηγοριών + N≥floor.
footer_line="$(grep -E "$FOOTER_RE" "$log" | tail -1 || true)"
if [ -z "$footer_line" ]; then
  echo "::error::Η ολομέλεια ΔΕΝ ολοκληρώθηκε: λείπει η LINE-ANCHORED σφραγίδα «════ ΟΛΟΜΕΛΕΙΑ ΠΥΛΩΝ (N) ════» (crash/OOM/spoof πριν την ετυμηγορία· docker exit=$status)." >&2
  exit 3
fi
declared_n="$(printf '%s\n' "$footer_line" | sed -E "s/$FOOTER_RE/\\1/")"
verdict_n="$(grep -Ec "$VERDICT_RE" "$log" || true)"
if [ "$declared_n" -lt "$plenary_min" ]; then
  echo "::error::Ολομέλεια κάτω από το floor: N=$declared_n < GATE_PLENARY_MIN=$plenary_min — η ολομέλεια συρρικνώθηκε ή δεν έτρεξε καμία πύλη (false-green killer)." >&2
  exit 3
fi
if [ "$verdict_n" != "$declared_n" ]; then
  echo "::error::ΑΝΤΙΦΑΣΗ ΟΛΟΚΛΗΡΩΣΗΣ: footer δηλώνει $declared_n πύλες αλλά τυπώθηκαν $verdict_n γραμμές ετυμηγορίας (truncated/crashed/spoofed plenary)." >&2
  exit 3
fi
if [ -n "$plenary_expect" ] && [ "$declared_n" != "$plenary_expect" ]; then
  echo "::error::Ολομέλεια ≠ αναμενόμενο σύνολο: N=$declared_n ≠ GATE_PLENARY_EXPECT=$plenary_expect — η ολομέλεια συρρικνώθηκε/μεγάλωσε σιωπηλά (silent gate-set drift)." >&2
  exit 3
fi

# (2) INFRA EXIT — μόνο 0/1 είναι πυλικά· καθετί άλλο (125 docker, 137 OOM, 139 segv…) = crash.
if [ "$status" != "0" ] && [ "$status" != "1" ]; then
  echo "::error::Μη-πυλικό docker exit ($status) — crash/OOM/docker infra error, όχι ετυμηγορία πύλης." >&2
  exit 4
fi

# Συλλογή των κόκκινων πυλών από το log.
red_lines="$(grep "$FAIL_RE" "$log" || true)"

# Κανονικοποίηση ονόματος πύλης: αφαίρεσε προπορευόμενα «--» ώστε το τυπωμένο
# «--advisor-gate» και η env-εξαίρεση «advisor-gate» να ταιριάζουν ΑΚΡΙΒΩΣ —
# ΟΧΙ ως substring (αλλιώς μια πύλη «--meta-advisor-gate» θα εξαιρούνταν λαθεμένα).
normalize_gate() {
  local n="$1"
  while [ "${n#--}" != "$n" ]; do n="${n#--}"; done
  printf '%s' "$n"
}

# (3) ΠΟΛΙΤΙΚΗ — κάθε κόκκινη πύλη πρέπει να είναι δηλωμένη baseline exception,
# με ΑΚΡΙΒΗ αντιστοίχιση ΟΝΟΜΑΤΟΣ (όχι whole-line substring).
offending=""
while IFS= read -r line; do
  [ -n "$line" ] || continue
  # Πεδίο ονόματος: κόψε προπορευόμενα κενά, πάρε ό,τι προηγείται του πρώτου «:».
  name="${line#"${line%%[![:space:]]*}"}"   # ltrim
  name="${name%%:*}"                          # token πριν το ':'
  name="${name%"${name##*[![:space:]]}"}"     # rtrim
  norm="$(normalize_gate "$name")"
  exempt=""
  for exc in $exceptions; do
    if [ "$norm" = "$(normalize_gate "$exc")" ]; then exempt=1; break; fi
  done
  [ -n "$exempt" ] || offending="${offending}${line}"$'\n'
done <<EOF
$red_lines
EOF
offending="${offending%$'\n'}"
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
