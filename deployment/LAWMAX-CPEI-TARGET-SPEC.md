# LAWMAX Ω — CONSTITUTIONAL PROOF-CARRYING EPISTEMIC INSTITUTION (CPEI) · v2
**Specification-only. ΚΑΜΙΑ υλοποίηση, καμία αλλαγή runtime.**
Ζεύγος: `LAWMAX-CPEI-TARGET-SPEC.sexp` (data-only, `*read-eval*` NIL, keyword package).
Authored-at-commit: **47bae07d** (v1) → v2 κατά την οδηγία «APPROVE / PROCEED — SPEC ONLY».
Ιεραρχία κειμένων: **αυτό = target** · OMEGA-PLAN = δρόμος · MEMORY-KERNEL-SPEC = μνήμη ·
ARCHITECTURE-CONSTITUTION.sexp + gate = **παρόν, επιβαλλόμενο**.

> **Διάκριση που διατρέχει ΟΛΟ το κείμενο:** ό,τι σημαίνεται «ΠΑΡΟΝ» είναι
> απογραφή από την πηγή/τα ζωντανά μητρώα (evidence ανά γραμμή). Ό,τι
> σημαίνεται «TARGET» είναι αρχιτεκτονική βούληση — ΔΕΝ υπάρχει ακόμη και ΔΕΝ
> χτίζεται χωρίς ρητό ΟΚ ανά φάση. Τα δύο δεν αναμειγνύονται ποτέ.

**ΜΙΑ ΕΔΡΑ — ρητή σύνδεση με το Memory Kernel Spec:** η απογραφή μνήμης
(13 τύποι, 8 canonical stores, M1-M5 κενά, write/recall policy, φάσεις Φ0-Φ5)
έχει ΜΙΑ έδρα: `LAWMAX-MEMORY-KERNEL-SPEC.{md,sexp}`. Αυτό το κείμενο ΔΕΝ την
επαναλαμβάνει και ΔΕΝ ιδρύει δεύτερη αρχιτεκτονική μνήμης — την **παραπέμπει**
και χτίζει το target ΠΑΝΩ της. Τα πέντε επίπεδα του συνολικού spec, με τις
έδρες τους:

| Επίπεδο | Έδρα |
|---|---|
| 1. Current inventory (stores/μνήμη ως έχει) | MEMORY-KERNEL-SPEC §1-2 + Σύνταγμα `:canonical-stores` |
| 2. Memory Kernel (πολιτική/κενά/φάσεις) | MEMORY-KERNEL-SPEC §3-8 |
| 3. Ultimate target architecture (12 στρώματα) | ΑΥΤΟ το κείμενο, §1 |
| 4. Full Agentic Memory Coverage Map | ΑΥΤΟ το κείμενο, §5 (appendix) |
| 5. CPEI / InstitutionalAct layer | ΑΥΤΟ το κείμενο, §2-3 |

---

## 1 · ULTIMATE TARGET — EXECUTABLE EPISTEMIC INSTITUTION

Το τελικό LAWMAX Ω **δεν είναι memory system, δεν είναι agent**. Είναι:

> **Εκτελέσιμο ψηφιακό νομικό Ίδρυμα που παράγει ΚΑΘΕ έξοδο ως θεσμική πράξη
> γνώσης — με απόδειξη, αντίλογο, χρονική ισχύ, μνήμη, provenance, governance
> και rollback.**

Αξιώματα αμετάβλητα: 0 λάθος ως μηχανισμός · τίμια άγνοια · μία έδρα ανά
έννοια · κανένα LLM στο έμπιστο μονοπάτι · ανθρώπινη κυριαρχία αναπαλλοτρίωτη ·
καμία ψευδο-ολοκλήρωση. **Κάθε στρώμα δένεται στα 13 κλειδωμένα primitives —
κανένα δεν εισάγει νέο primitive, κανένα δεν είναι top-level subsystem εκτός
Συντάγματος.**

### Τα 12 στρώματα (πλήρης χάρτης: seat / coverage / primitive / evidence / phase / gate / risk)

**L1 · Immutable Experience Ledger** — primitive: `:memory`
- Existing seat: `episodes.sexp` (SHA-256 chain), `failure-ledger.jsonl` (append+read-back P0)
- Coverage: **partial** — δύο ρεύματα χωρίς κοινό γονέα· δεν καλύπτει ΟΛΕΣ τις πράξεις
- Evidence: `source/memory.lisp:96` (chained-append) · `understanding-learning.lisp:188` (P0)
- Future phase: **Φ1 (M1 turn_id)** → ενοποίηση κάτω από root span
- Gate required: `--memory-gate` (υπάρχει 10/10) + νέος έλεγχος «κάθε πράξη στο ledger» (μελλοντικός)
- Risk if absent: εμπειρία χωρίς ενιαία ραχοκοκαλιά — πράξεις μη ανασυστάσιμες

**L2 · Bitemporal Epistemic Graph** — primitives: `:law` `:fact`
- Existing seat: graph-reasoning + legal-temporal + `graph-snapshot.sexp`
- Coverage: **partial** — ένας χρονικός άξονας (valid-time corpus)· λείπει transaction-time
- Evidence: `graph-import.lisp:186,223` · legal-temporal έδρα (ontology map)
- Future phase: **Ω2** (μετά Φ1) — valid-time × transaction-time ανά κόμβο/ακμή
- Gate required: επέκταση `--inference-gate` (σειριοποίηση bitemporal roundtrip)
- Risk if absent: «τι ίσχυε όταν κρίθηκε» ≠ «τι ήξερε το σύστημα όταν έκρινε» — αδύνατος δίκαιος αναδρομικός έλεγχος

**L3 · Typed Epistemic / Memory Objects** — primitives: `:fact` `:proof` `:hypothesis`
- Existing seat: Memory Kernel taxonomy (13 τύποι) + typed article-id + trace events
- Coverage: **partial** — τύποι απογεγραμμένοι, όχι κλειστή τυποθεωρία
- Evidence: MEMORY-KERNEL-SPEC `:memory-types` · component-gate ⑥⑦⑧ (typed ids)
- Future phase: **Ω3** — Fact/Proof/Hypothesis/Norm/Claim κλειστοί τύποι, μετατροπές ΜΟΝΟ με απόδειξη
- Gate required: νέος έλεγχος «καμία σιωπηλή μετατροπή τύπου» (πρότυπο: component-gate ⑧)
- Risk if absent: υπόθεση μεταμφιέζεται σε γεγονός — μόλυνση του έμπιστου μονοπατιού

**L4 · Proof / Disproof Layer** — primitive: `:proof`
- Existing seat: inference WFS + proof-carrying (De Bruijn) + subsumption trees + defeaters
- Coverage: **present-gated** ✅
- Evidence: `--inference-gate` 63/63 · `--subsumption-gate` 29/29 · `--iq-gate` 4/4
- Future phase: **Ω4** — ρητό counterproof αντικείμενο σε ΚΑΘΕ πράξη (σήμερα μόνο αντιδικία)
- Gate required: υπάρχοντα + έλεγχος «πράξη χωρίς counterproof slot ⇒ κόκκινο»
- Risk if absent: μονομερής απόδειξη — θεσμός χωρίς αντίλογο δεν είναι δικαιικός

**L5 · Hypothesis & Counterfactual Workspace** — primitive: `:hypothesis`
- Existing seat: advisor dreams + legal-hypo + counterfactual + fluid-induction
- Coverage: **present-gated** ✅ (σήμανση [ΟΧΙ συμπέρασμα] επιβεβλημένη)
- Evidence: `--advisor-gate` · draft-gate Ε14 (εικασία δεν μολύνει υπαγωγή)
- Future phase: **Ω5** — μόνιμος χώρος υποθέσεων με κύκλο ζωής (γέννηση→δοκιμή→λήξη)
- Gate required: υπάρχοντα + κύκλος ζωής υπόθεσης
- Risk if absent: υποθέσεις είτε χάνονται είτε λιμνάζουν αθάνατες

**L6 · Adversarial Parliament** — primitive: `:argument`
- Existing seat: legal-dialectic (θέσεις↔ενστάσεις, burden)
- Coverage: **partial** — ΜΙΑ διαλεκτική μηχανή, όχι N ανεξάρτητοι κριτές
- Evidence: subsumption-gate (αντιδικία: ένσταση κερδίζει/θέση πίπτει)
- Future phase: **Ω6** — πολυ-εδρικό: ανεξάρτητοι εσωτερικοί κριτές ανά πράξη, ψηφοφορία με αιτιολογία
- Gate required: νέος: «κάθε legal-critical πράξη πέρασε από ≥N κριτές με ανεξάρτητα σκεπτικά»
- Risk if absent: ομοφωνία-εκ-κατασκευής — τυφλά σημεία ενός μονοπατιού συλλογισμού

**L7 · Legal World Simulator** — primitives: `:hypothesis` `:matter`
- Existing seat: what-if + event-calculus + strategy
- Coverage: **partial** — what-if σε αλλαγές συστήματος + event-calculus σε υποθέσεις· όχι ενιαίος κόσμος
- Evidence: `--event-gate` 8/8 · self-evolution-gate ①-④ (what-if)
- Future phase: **Ω7** — «τι θα ίσχυε αν…» πάνω σε ΟΛΟ το corpus με χρονικές γραμμές
- Gate required: επέκταση event-gate σε corpus-wide σενάρια
- Risk if absent: συμβουλή χωρίς προσομοίωση συνεπειών — στρατηγική στα τυφλά

**L8 · Governance / Adoption / Quarantine Layer** — primitives: `:evolution` `:institution`
- Existing seat: adoption engine (can-adopt) + shadow + policies + QUARANTINE verdicts
- Coverage: **present-gated** ✅
- Evidence: `--self-evolution-gate` 23/23 · `--policy-gate` 12/12 · understanding-gate ⑤⑧
- Future phase: — (ώριμο· επεκτείνεται μόνο όταν νέα στρώματα φέρουν νέα αντικείμενα προς υιοθέτηση)
- Gate required: υπάρχοντα
- Risk if absent: — (υπάρχει· η απουσία του θα σήμαινε ανεξέλεγκτη αυτο-τροποποίηση)

**L9 · Self-Model & Meta-Memory** — primitives: `:self` `:memory`
- Existing seat: self-model + mirror + Memory Kernel + gap ledger + mission measures
- Coverage: **present-gated** ✅ (self-model)· meta-memory **partial**
- Evidence: `--mirror-gate` 9/9 · gap-ledger-frame · signed adoption decisions
- Future phase: **Φ4 (M4 consolidation)** — η ιστορία των ΔΙΚΩΝ του αλλαγών ως πρώτης τάξης μνήμη
- Gate required: mirror-gate + μελλοντικός έλεγχος meta-ιστορίας
- Risk if absent: σύστημα που δεν θυμάται ΠΩΣ έγινε αυτό που είναι — τυφλή εξέλιξη

**L10 · Constitutional Compiler** — primitives: `:institution` `:substrate`
- Existing seat: ARCHITECTURE-CONSTITUTION.sexp + `--architecture-constitution-gate` 12/12
- Coverage: **partial** — το Σύνταγμα ΕΛΕΓΧΕΙ (ratchet)· ΔΕΝ παράγει
- Evidence: architecture-gate ①-⑫ (read-only επιβολή)
- Future phase: **Ω10** — βλ. §3 Constitutional Compiler target
- Gate required: «ό,τι παράγεται από το Σύνταγμα ταυτίζεται με ό,τι επιβάλλεται» (roundtrip)
- Risk if absent: διπλή αλήθεια — Σύνταγμα και πραγματικότητα αποκλίνουν σιωπηλά

**L11 · Reproducible Substrate** — primitive: `:substrate`
- Existing seat: Docker hermetic (deps.lock, source-less runtime, SBOM, cosign) · NixOS L0 ΖΕΙ (acceptance run έγινε σε αυτό το μονοπάτι)· L1-8 σχεδιασμένα
- Coverage: **partial**
- Evidence: Dockerfile multi-stage · NIXOS-COGNITIVE-SUBSTRATE.md (LEVEL ladder)
- Future phase: **L1+** — ΜΠΛΟΚΑΡΙΣΜΕΝΟ μέχρι CONSCIOUSNESS AUDIT PASS-CANDIDATE
- Gate required: nix flake check = πύλες ως build invariant (N4)
- Risk if absent: «έμαθε» που δεν ξαναχτίζεται = ανέκδοτο, όχι γνώση

**L12 · Human Sovereignty Interface** — primitives: `:institution` `:authority`
- Existing seat: --thoughts/--approve/--reject + policies μετρημένης ακρίβειας + signed decisions + revocation
- Coverage: **present-gated** ✅
- Evidence: `--policy-gate` 12/12 (ανάκληση, force-με-αιτιολογία, όχι καθολικό override) · extension-gate
- Future phase: — (ώριμο· κάθε νέο στρώμα ΥΠΟΧΡΕΟΥΤΑΙ να περνά από εδώ)
- Gate required: υπάρχοντα
- Risk if absent: — (η απουσία του ακυρώνει ΟΛΟ το οικοδόμημα — γι' αυτό είναι αναπαλλοτρίωτο)

**Σύνοψη: 4 present-gated · 8 partial · 0 χωρίς έδρα.** Το target είναι
ωρίμανση υπαρχουσών εδρών — ΟΧΙ νέα top-level subsystems.

---

## 2 · InstitutionalAct — το σχήμα κάθε εξόδου (TARGET schema concept)

Κάθε έξοδος του Ιδρύματος = θεσμική πράξη γνώσης. Το ΠΑΡΟΝ TRUST ENVELOPE
είναι το **έμβρυο** του InstitutionalAct: ωριμάζει, δεν αντικαθίσταται.
**Απαγορεύεται δεύτερο παράλληλο envelope — μία έδρα: `%ask-envelope`.**

| Πεδίο | Παρόν (envelope, υπολογισμένο) | Status |
|---|---|---|
| `act_id` | — | ✗ gap (παράγωγο M1) |
| `turn_id` | — | ✗ gap (M1 — P1 debt 62570e60) |
| `jurisdiction` | σιωπηρά ελληνικό δίκαιο | ✗ gap (ρητή δήλωση ανά πράξη) |
| `mode` | `mode: legal-trusted/…/self-meta/general/conversation-reference` | ✅ |
| `authority` | `capability_used/contract_used/component_used` | ◐ λείπει νομιμοποιητική αλυσίδα από Σύνταγμα |
| `claim` | το σώμα απάντησης + θέσεις υπαγωγής | ◐ όχι δομημένο Claim αντικείμενο ανά πράξη |
| `facts` | γεγονότα με πηγές (draft-gate: κάθε γεγονός φέρει πηγή) | ✅ |
| `proof` | δέντρα απόδειξης + De Bruijn + `proof_required/available` | ✅ |
| `counterproof` | ενστάσεις αντιδικίας (μόνο subsume/draft) | ◐ |
| `temporal_validity` | legal-temporal σε corpus επίπεδο | ◐ (δένει με L2) |
| `trust_status` | `output_status` + `trusted_output_allowed` | ✅ |
| `weakest_link` | ασθενέστερος κρίκος (Σ10, μόνο draft) | ◐ |
| `memory_events` | `failure_id/memory_recorded/gap_id/gap_created` (P0 επαληθευμένα) | ✅ |
| `source_events` | `trace_id` + provenance δεσμοί | ✅ |
| `gate_results` | ολομέλεια on-demand, όχι ανά πράξη | ◐ |
| `system_generation` | `--version`/manifest· πλήρες με NixOS generations (L4+) | ◐ |
| `rollback_context` | μόνο σε adoption decisions | ◐ |
| `human_approval_policy` | `policy_decision` + requires-human + signed | ✅ |

**7 ✅ · 8 ◐ · 3 ✗ (act_id, turn_id, jurisdiction).** Keystone όταν εγκριθεί:
**M1 turn_id** — ο γονέας που δένει ledger+proof+trace+envelope.

---

## 3 · Constitutional Compiler — TARGET

ΠΑΡΟΝ: το Σύνταγμα είναι δηλωτικό κείμενο + read-only gate που το **επιβάλλει**
(ratchet — αποδείχθηκε όταν κοκκίνισε στη δική του αχαρτογράφητη εντολή).

TARGET: το Σύνταγμα **μεταγλωττίζεται** — από αυτό ΠΑΡΑΓΟΝΤΑΙ:

1. **contracts** — τα συμβόλαια ικανοτήτων γεννιούνται από τις συνταγματικές δηλώσεις
2. **gates** — οι έλεγχοι μη-παλινδρόμησης παράγονται από τους κανόνες
3. **tests** — κάθε συνταγματική απαίτηση φέρει εκτελέσιμο τεστ εκ γενετής
4. **memory policies** — write/recall/durability πολιτικές ανά store από το `:canonical-stores`
5. **trust invariants** — τα envelope invariants (π.χ. P0 memory_recorded) ως παραγόμενοι έλεγχοι
6. **approval policies** — τα όρια αυτο-έγκρισης ως μεταγλωττισμένη πολιτική
7. **rollback constraints** — κάθε υιοθέτηση με παραγόμενο rollback target
8. **runtime constraints** — paths/permissions/profiles (δένει με NixOS module L6)

Αρχή ορθότητας: **roundtrip** — ό,τι παράγει ο compiler ταυτίζεται με ό,τι
επιβάλλει η πύλη· απόκλιση = κόκκινο build, όχι warning. Μέχρι το Ω10, το
παρόν καθεστώς (χειρόγραφα gates + read-only ratchet) παραμένει η αλήθεια.

---

## 4 · ΚΡΙΣΙΜΗ ΑΡΧΗ: memory types ≠ stores

> **Τα (έως 50) είδη μνήμης ΔΕΝ γίνονται 50 stores. Γίνονται cognitive memory
> CAPABILITIES πάνω σε ΕΝΙΑΙΟ epistemic substrate:**
> **events + epistemic graph + typed objects + projections + governance.**

Συνέπειες (δεσμευτικές για κάθε μελλοντική φάση):
- Νέο είδος μνήμης ⇒ νέα **ικανότητα** (με πύλη, στο μητρώο ικανοτήτων) πάνω
  στο υπόστρωμα — ΟΧΙ νέο αρχείο-store, εκτός αν το Σύνταγμα αποκτήσει ρητή
  εγγραφή `:canonical-stores` με έγκριση δημιουργού.
- **Projections** (ευρετήρια, aggregates, working sets) είναι ΠΑΡΑΓΩΓΑ των
  events — ξαναχτίζονται από το ledger, ΔΕΝ είναι source of truth, ΠΟΤΕ δεν
  αποκτούν δικό τους writer αλήθειας.
- Ο έλεγχος «ένας ρόλος ανά store, κανένα αδήλωτο store» (architecture-gate ⑨)
  είναι ο μηχανικός φρουρός αυτής της αρχής — ήδη ενεργός.

---

## 5 · APPENDIX — FULL AGENTIC MEMORY COVERAGE MAP

Κατηγορίες target: **event** (append-only συμβάν) · **object** (typed
αντικείμενο) · **projection** (παράγωγο/ξαναχτίσιμο) · **policy** (κανόνας
διακυβέρνησης) · **graph-relation** (ακμή/σχέση στον epistemic graph).

Coverage: ✅ existing · ◐ partial · ✗ missing. Phases: Φ1-Φ5 = Memory Kernel ·
Ω2-Ω10 = CPEI στρώματα · όλα `:requires-ok`.

| Memory type | Category | Coverage | Παρόν store | Future source of truth | Provenance | Gate | Phase | Risk if absent |
|---|---|---|---|---|---|---|---|---|
| Episodic (αλληλεπιδράσεις) | event | ✅ | episodes.sexp | unified event ledger (Φ1) | SHA-256 chain | memory-gate | Φ0 done | καμία εμπειρία |
| Dialogue failures (Π0) | event | ✅ | failure-ledger.jsonl | ίδιο, υπό turn_id | append+read-back | understanding-gate | Φ0 done | ψευδής μνήμη (ο trust bug) |
| Adoption decisions | event | ✅ | signed decision files | ίδιο, υπό turn_id | SHA-256 υπογραφή | self-evolution-gate | Φ0 done | ανιστόρητη εξέλιξη |
| Execution trace | event | ◐ (RAM) | `*events*` | persisted spans ανά πράξη | provenance links | provenance-gate | Φ1 | πράξη χωρίς ίχνος |
| Biographical / genesis | object | ✅ | history.sexp | ίδιο | bootstrap-tracked | (Σύνταγμα ⑨) | — | απώλεια ταυτότητας |
| Component identity | object | ✅ | component-manifest.sexp | ίδιο + δήλωση ρόλου στο Σύνταγμα | SHA-256 ανά αρχείο | component-gate | δηλ. χρέος | αταυτοποίητη ύλη |
| Proposals (υποψήφια γνώση) | object | ✅ | proposals.sexp | ίδιο | shadow results | extension/evolution | — | ανεξέλεγκτη γνώση |
| Candidate packs | object | ✅ | candidates/ | ίδιο | shadow + revert | extension-gate | — | μόλυνση σταθερού εαυτού |
| Hypothesis workspace state | object | ◐ | dreams εκκρεμή σε proposals | typed Hypothesis objects (Ω3/Ω5) | judge verdicts | advisor-gate | Ω5 | αθάνατες/χαμένες υποθέσεις |
| Semantic (μαθημένες έννοιες) | object | ✗ | — (knowledge packs = ΓΝΩΣΗ/bootstrap, ΟΧΙ μνήμη) | consolidation από events (Φ4) | προτάσεις+έγκριση | νέος (Φ4) | Φ4 | θυμάται συμβάντα, όχι μοτίβα |
| Procedural (μαθημένες δεξιότητες) | object | ◐ | capabilities registry (δηλωμένες, όχι μαθημένες) | adopted rules μέσω governance | shadow+signature | understanding-gate | Φ4+ | δεξιότητα μόνο χειροποίητη |
| Prospective (προθέσεις/agenda) | object | ✅ | agenda/intentions (memory subsystem) | ίδιο, υπό turn_id | episode δεσμός | memory-gate | — | ξεχνά τι σκόπευε |
| Working (last-answer/question) | projection | ✅ (RAM) | `*ask-memory*` | projection του event ledger | — (εφήμερο) | dialogue-gate Β | Φ2 | κανένα follow-up |
| Session continuity | projection | ✗ | — | session projection (Φ2) | rebuild από events | νέος (Φ2) | Φ2 | κάθε run «χωρίς χθες» |
| Recall index | projection | ✗ | — (recall = γραμμική σάρωση) | index ΠΑΡΑΓΩΓΟ episodes (Φ3) | rebuild-verified | νέος (Φ3) | Φ3 | O(n) ανάκληση |
| Reflection aggregate | projection | ✅ | lessons.jsonl | παράγωγο του ledger (μακροπρόθεσμα) | ένας writer (%lesson) | understanding-gate ⑬ | — | χωρίς αναστοχασμό |
| Progress cursors | projection | ✅ | *-last-seen.txt | ίδιο + δήλωση ρόλου | idempotent overwrite | (Σύνταγμα ⑨) | δηλ. χρέος | δαίμονας ξεχνά πού έμεινε |
| Meta-memory (πώς άλλαξα) | projection | ◐ | mirror + decisions | ιστορία αλλαγών ως προβολή decisions (Φ4/L9) | signed decisions | mirror-gate | Φ4 | τυφλή εξέλιξη |
| Approval policies | policy | ✅ | policies.sexp | compiled από Σύνταγμα (Ω10) | signed + accuracy-measured | policy-gate | Ω10 | ανεξέλεγκτη αυτο-έγκριση |
| Review queue | policy | ✅ | review-queue.sexp | ίδιο + δήλωση ρόλου | — | (Σύνταγμα ⑨) | δηλ. χρέος | εκκρεμότητες χάνονται |
| Memory write/recall policies | policy | ◐ | MEMORY-KERNEL-SPEC (κείμενο) | compiled από Σύνταγμα (Ω10) | roundtrip check | arch-gate | Ω10 | πολιτική = αφήγηση |
| Source memory (από πού το ξέρω) | graph-relation | ◐ | provenance links + pack hashes | epistemic graph edges (Ω2) | hash-δεμένο | provenance-gate | Ω2 | γνώση χωρίς καταγωγή |
| Temporal validity (bitemporal) | graph-relation | ◐ | legal-temporal (corpus) | bitemporal graph (Ω2) | dual timestamps | inference-gate ext | Ω2 | άδικος αναδρομικός έλεγχος |
| Concept grounding relations | graph-relation | ✅ | concept-grounding packs + graph-snapshot | epistemic graph (Ω2) | άρθρο-δεσμός | extension-gate | — | αγείωτοι ορισμοί |
| Cross-act relations (ποια πράξη στηρίζει ποια) | graph-relation | ✗ | — | act-graph υπό act_id (μετά Φ1) | proof links | νέος | μετά Φ1 | νομολογία του εαυτού του χαμένη |

**Απαρίθμηση: 25 memory types → 5 κατηγορίες → ΚΑΝΕΝΑ νέο store πέραν των
δηλωμένων.** Τα ✗/◐ είναι capabilities-to-be πάνω στο υπόστρωμα, όχι αρχεία.

---

## 6 · Απαγορεύσεις & έλεγχος συμμόρφωσης αυτού του κειμένου

Αυτό το spec ΔΕΝ: γράφει runtime code · αλλάζει behavior · ανοίγει Runner ·
φτιάχνει store/writer/gate · κάνει refactor · κάνει Code Witness · κάνει NixOS ·
επεκτείνει νομική γνώση · **ισχυρίζεται learning** (κανένας υιοθετημένος
κανόνας από ζωντανή αποτυχία δεν υπάρχει ακόμη — η μάθηση παραμένει ΜΗ
αποδεδειγμένη).

Κριτήρια αποδοχής (τα 5 του δημιουργού):
1. current inventory / target architecture: ρητά διαχωρισμένα (ΠΑΡΟΝ/TARGET σε κάθε τμήμα)
2. memory ≠ knowledge: knowledge packs ρητά ΕΚΤΟΣ μνήμης (semantic row + kernel §1)
3. memory types ≠ stores: §4 δεσμευτική αρχή + appendix χωρίς κανένα νέο store
4. δέσιμο στα 13 primitives: κάθε στρώμα φέρει primitive mapping (κανένα νέο primitive)
5. κανένα νέο top-level subsystem εκτός Συντάγματος: όλα τα στρώματα = ωρίμανση υπαρχουσών εδρών, υπό architecture-gate
