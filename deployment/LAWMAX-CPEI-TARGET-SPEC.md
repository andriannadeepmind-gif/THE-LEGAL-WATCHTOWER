# LAWMAX Ω — CONSTITUTIONAL PROOF-CARRYING EPISTEMIC INSTITUTION (CPEI)
**Η δεσμευτική μηχανική μορφή του τελικού στόχου. Specification-only — ΚΑΜΙΑ υλοποίηση.**
Ζεύγος: `LAWMAX-CPEI-TARGET-SPEC.sexp`. Authored-at-commit: **11bd9a6c**.
Ιεραρχία κειμένων: αυτό ΟΡΙΖΕΙ το target· το `LAWMAX-OMEGA-PLAN.md` τον δρόμο·
το `LAWMAX-MEMORY-KERNEL-SPEC.md` τη μνήμη· το Σύνταγμα (`.sexp` + gate) το παρόν.

## Ο τελικός στόχος, αυστηρά

Το «ψηφιακό νομικό Ίδρυμα» ΔΕΝ είναι μεταφορά. Υλοποιείται ως:

> **Constitutional Proof-Carrying Epistemic Institution** — θεσμός του οποίου
> ΚΑΘΕ έξοδος είναι θεσμική πράξη (InstitutionalAct) που κουβαλά την απόδειξή
> της, την αντίκρουσή της, τη χρονική της ισχύ, την προέλευσή της, τη μνήμη
> της και το καθεστώς κυριαρχίας του δημιουργού — μηχανικά, όχι ρητορικά.

Τα σταθερά αξιώματα ΔΕΝ αλλάζουν: 0 λάθος ως μηχανισμός (πύλες) · τίμια άγνοια ·
μία έδρα ανά έννοια · κανένα LLM στο έμπιστο μονοπάτι · ανθρώπινη κυριαρχία
αναπαλλοτρίωτη · καμία ψευδο-ολοκλήρωση.

## Τα 12 στρώματα — δεμένα στο ΠΑΡΟΝ (έδρα ή δηλωμένο κενό)

Status: ✅ υπάρχει με πύλη · ◐ μερικό (υπάρχει έδρα, λείπει η πλήρης μορφή) ·
✗ δηλωμένο κενό (δεν χτίζεται χωρίς ΟΚ).

| # | Στρώμα CPEI | Παρούσα έδρα | Status | Τι λείπει για την πλήρη μορφή |
|---|---|---|---|---|
| 1 | **Immutable Experience Ledger** | episodes.sexp (SHA-256 chain) + failure-ledger (append+read-back P0) | ◐ | ενοποίηση κάτω από universal turn id (M1)· ledger ΟΛΩΝ των θεσμικών πράξεων, όχι μόνο επεισοδίων/αποτυχιών |
| 2 | **Bitemporal Epistemic Graph** | graph-reasoning + legal-temporal + graph-snapshot | ◐ | δεύτερος χρονικός άξονας: valid-time × transaction-time (πότε ίσχυε ο νόμος × πότε το έμαθε το σύστημα) |
| 3 | **Typed Epistemic / Memory Objects** | Memory Kernel Spec (13 τύποι) + typed article-id + trace events | ◐ | ενιαία τυποθεωρία epistemic αντικειμένων: Fact/Proof/Hypothesis/Norm/Claim ως κλειστοί τύποι με μετατροπές-μόνο-με-απόδειξη |
| 4 | **Proof / Disproof Layer** | inference WFS + proof-carrying (De Bruijn) + subsumption trees + defeaters | ✅ | επέκταση: ρητό counterproof αντικείμενο σε ΚΑΘΕ πράξη (σήμερα μόνο στην αντιδικία) |
| 5 | **Hypothesis & Counterfactual Workspace** | advisor dreams + legal-hypo + counterfactual + fluid-induction | ✅ | σήμανση [ΟΧΙ συμπέρασμα] υπάρχει· λείπει μόνιμος χώρος υποθέσεων με κύκλο ζωής |
| 6 | **Adversarial Parliament** | legal-dialectic (θέσεις↔ενστάσεις, burden) | ◐ | πολυ-εδρικό: N ανεξάρτητοι εσωτερικοί κριτές ανά πράξη (σήμερα: μία διαλεκτική μηχανή) |
| 7 | **Legal World Simulator** | what-if + event-calculus + strategy | ◐ | σύνθεση σε ενιαίο simulator: «τι θα ίσχυε αν…» πάνω σε ΟΛΟ το corpus με χρονικές γραμμές |
| 8 | **Governance / Adoption / Quarantine** | adoption engine (can-adopt) + shadow + policies + QUARANTINE verdicts | ✅ | ήδη: what-if υποχρεωτικό, rollback υποχρεωτικό, requires-human ανώτατο |
| 9 | **Self-Model & Meta-Memory** | self-model + mirror + Memory Kernel + gap ledger + mission measures | ✅ | ήδη μετρημένο· λείπει meta-memory των ΔΙΚΩΝ του αλλαγών ως πρώτης τάξης ιστορία (M4 consolidation) |
| 10 | **Constitutional Compiler** | ARCHITECTURE-CONSTITUTION.sexp + gate 12/12 (read-only ratchet) | ◐ | από ΕΛΕΓΚΤΗΣ → ΜΕΤΑΓΛΩΤΤΙΣΤΗΣ: το Σύνταγμα να ΠΑΡΑΓΕΙ δεσμεύσεις (envelope απαιτήσεις, gates, stores) αντί μόνο να τις επαληθεύει |
| 11 | **Reproducible Substrate** | Docker (deps.lock, hermetic, SBOM) — NixOS LEVEL 0-8 σχεδιασμένο | ◐ | L1+ flake/derivations/generations (ΜΠΛΟΚΑΡΙΣΜΕΝΟ μέχρι PASS-CANDIDATE) |
| 12 | **Human Sovereignty Interface** | --thoughts/--approve/--reject + policies (μετρημένη ακρίβεια) + signed decisions | ✅ | ήδη: εξουσία ανακαλείται, override μόνο αιτιολογημένο ανά κλήση |

**Σύνολο: 4 ✅ · 8 ◐ · 0 στρώμα χωρίς καμία έδρα.** Το target ΔΕΝ απαιτεί νέο
top-level subsystem — απαιτεί την ΩΡΙΜΑΝΣΗ των υπαρχουσών εδρών. Κανένα ◐ δεν
προχωρά χωρίς ρητό ΟΚ, ένα-ένα, με πύλη.

## InstitutionalAct — το σχήμα κάθε εξόδου (target)

Κάθε έξοδος του Ιδρύματος = **θεσμική πράξη** με τα εξής πεδία. Δίπλα: τι από
αυτά ΗΔΗ εκπέμπεται στο TRUST ENVELOPE (υπολογισμένο, όχι στατικό) και τι είναι
δηλωμένο κενό.

| Πεδίο | Σήμερα στο envelope | Status |
|---|---|---|
| `act_id` | — | ✗ κενό (ταυτίζεται με M1: παράγωγο του turn id) |
| `turn_id` | — | ✗ κενό (M1 universal turn id / root span — P1 debt 62570e60) |
| `jurisdiction` | — (σιωπηρά: ελληνικό δίκαιο) | ✗ κενό: ρητή δήλωση δικαιοδοσίας ανά πράξη |
| `authority` | `capability_used / contract_used / component_used` | ◐ μερικό: λείπει η νομιμοποιητική αλυσίδα (ποιος κανόνας του Συντάγματος εξουσιοδοτεί την πράξη) |
| `facts` | γεγονότα υπαγωγής με πηγές (draft-gate: κάθε γεγονός φέρει πηγή) | ✅ |
| `proof` | δέντρα απόδειξης + πιστοποιητικά De Bruijn + `proof_required/available` | ✅ |
| `counterproof` | ενστάσεις αντιδικίας (μόνο σε subsume/draft) | ◐ όχι σε κάθε πράξη |
| `temporal_validity` | legal-temporal σε corpus επίπεδο | ◐ όχι ανά πράξη (bitemporal κενό) |
| `trust_status` | `output_status: trusted/untrusted/refused/diagnostic` + `mode` | ✅ |
| `weakest_link` | ασθενέστερος κρίκος στο παραδοτέο (Σ10) | ◐ μόνο στο draft, όχι σε κάθε πράξη |
| `memory_events` | `failure_id / memory_recorded / gap_id / gap_created` (P0 επαληθευμένα) | ✅ |
| `source_events` | `trace_id` + provenance δεσμοί | ✅ |
| `gate_results` | ολομέλεια on-demand (όχι ανά πράξη) | ◐ ανά πράξη: ποιες πύλες κάλυπταν τη διαδρομή της |
| `system_generation` | `--version` / manifest | ◐ πλήρες μόνο με NixOS generations (L4+) |
| `rollback_context` | μόνο σε adoption decisions | ◐ όχι σε κάθε πράξη |
| `human_approval_policy` | `policy_decision` + requires-human + signed decisions | ✅ |

**Σύνολο: 6 ✅ · 7 ◐ · 3 ✗.** Το TRUST ENVELOPE είναι το ΕΜΒΡΥΟ του
InstitutionalAct — δεν αντικαθίσταται, ΩΡΙΜΑΖΕΙ. Απαγορεύεται δεύτερο
παράλληλο envelope: μία έδρα (`%ask-envelope`), μία εξέλιξη.

## Δεσμεύσεις αυτής της αναβάθμισης

1. **Καμία υλοποίηση τώρα.** Τα ✗ και ◐ είναι δηλωμένα χρέη — κάθε ένα απαιτεί
   ρητό ΟΚ, δικό του σχέδιο, δική του πύλη, rollback.
2. **Πρώτο βήμα-κλειδί όταν εγκριθεί: M1 (turn_id)** — τα `act_id/turn_id`
   είναι ο γονέας που ενοποιεί ledger+proof+trace+envelope. Χωρίς αυτό, το
   InstitutionalAct δεν έχει ραχοκοκαλιά. (Ήδη Φ1 στο Memory Kernel Spec.)
3. **Ιεραρχία μπλοκαρίσματος αμετάβλητη:** Runner blocked · refactor blocked ·
   Code Witness blocked · NixOS L1+ blocked (PASS-CANDIDATE) · legal expansion
   frozen. Αυτό το κείμενο ΔΕΝ ξεμπλοκάρει τίποτα.
4. **Μετρησιμότητα:** η πρόοδος προς CPEI μετριέται ως: πόσα πεδία του
   InstitutionalAct εκπέμπονται υπολογισμένα (σήμερα 6/16 πλήρη) και πόσα
   στρώματα είναι ✅ (σήμερα 4/12). Ο καθρέφτης θα μάθει να το απαντά όταν
   (και μόνο όταν) εγκριθεί αντίστοιχη φάση.
