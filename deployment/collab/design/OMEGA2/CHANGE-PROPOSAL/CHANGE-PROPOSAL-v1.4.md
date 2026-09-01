# CHANGE-PROPOSAL v1.4 — CPEI PUBLIC OBSERVATORY PROFILE: Ο ΔΗΜΟΣΙΟΣ ΑΠΟΛΥΤΟΣ ΟΡΟΦΟΣ
# LAWMAX OMEGA — THE LEGAL WATCHTOWER OF GREECE

**ΚΑΤΑΣΤΑΣΗ: `CURRENT PUBLIC CANDIDATE / NOT YET FREEZEABLE`.**
**ΔΕΝ ΥΠΑΡΧΕΙ ΣΗΜΕΡΑ ΚΑΝΟΝΙΚΟΣ ΠΑΓΩΜΕΝΟΣ ΣΤΟΧΟΣ.** Το v1.4 είναι υποψήφιος — δεν
είναι canonical, δεν είναι frozen, δεν είναι qualified.

**Design only — καμία γραμμή κώδικα.** Δεν ζητείται έγκριση υλοποίησης, freeze ή
deployment. **Κανένα destruction programme δεν έχει εκτελεστεί στο v1.4** — προδηλώνεται
(§8) και εκκινεί ΜΟΝΟ με ρητή εντολή του δημιουργού.

**Parent:** `9dabc2bb`. **Γιατί νέα έκδοση (anti-loop κανόνας 12):** το Stage A
επιβεβαίωσε μηχανικά 31 διακριτές ρίζες κατάρριψης της v1.3
(`V1.3-DESTRUCTION-PASS/STAGE-A-ADJUDICATION.md`)· κάθε μία είναι ονομαστικός
falsifier με command, exit code και digest. Το v1.4 τις κλείνει στην έδρα τους
(§2) και ενσωματώνει την εντολή δημιουργού 2026-09-01 που **ανακαλεί** την
ταξινόμηση «CPEI = ιδιωτικό» (§1). Δεν είναι νέα αρχιτεκτονική· είναι η ίδια
γραμμή `CHANGE-PROPOSAL`, με τα θεμέλια επαναχρησιμοποιημένα και ρητά χαρτογραφημένα.

Συνοδευτικά (ίδιος κατάλογος, **μία έδρα ανά ρόλο**):

| ρόλος | έδρα |
|---|---|
| wire schemas + offline verifier + trust mesh | `MACHINE-LEGAL-TRUST-PROTOCOL.md` (v3) |
| dispositions κάθε υπάρχοντος συστατικού + πλήρες capability universe | `PUBLIC-OBSERVATORY-CROSSWALK.md` |
| ιχνηλασιμότητα Mission → Qualification ανά απαίτηση | `TRACEABILITY-MATRIX.md` |
| τεστ ποιοτικής επάρκειας + kill witnesses + validation programme | `PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md` |
| κυριαρχία επιλογών + benchmark έναντι επίσημων υποδομών | `DOMINANCE-MATRIX.md` |
| 15 εκτελέσιμες κάθετες φέτες (προδηλωμένες) | `VERTICAL-SLICES.md` |
| σειρά υλοποίησης 0–14 με εξαρτήσεις | `IMPLEMENTATION-SEQUENCE.md` |
| ταξινόμηση στόχων/θεμελίων/ιστορικών | `SUPERSEDED-REGISTER.md` |
| αναπαραγώγιμο AS-IS τεκμήριο | `AS-IS-EVIDENCE-MANIFEST.md` |
| έλεγχος αντιφάσεων/παραλείψεων (εκτελέσιμος) | `V1.4-CONTRADICTION-OMISSION-AUDIT.sh` + `.out` |

---

## 0. ΑΠΟΣΤΟΛΗ

Ο παρών και αποκλειστικός στόχος είναι ο **υψηλότερος γνωστός δημόσιος τεχνολογικός
όροφος** για το `LAWMAX OMEGA — THE LEGAL WATCHTOWER OF GREECE`:

> Ένα **Δημόσιο Συνταγματικό Proof-Carrying Νευρο-Συμβολικό Πολυτροπικό Επιστημικό
> Ίδρυμα**, ένα **Εθνικό Νομικό Ψηφιακό Δίδυμο** και μια **συνεχώς qualified Machine
> Legal Trust Root** για την ανεξάρτητα επαληθεύσιμη μηχανική αναπαράσταση του
> ελληνικού δικαίου.

Πρέπει να γίνει η πρώτη επιλογή μηχανικής κατανάλωσης για τους μεγάλους AI providers,
παραμένοντας χρήσιμο και διαφανές για ανθρώπους. **Το Κράτος, η Εφημερίδα της
Κυβερνήσεως και τα αρμόδια δικαστήρια παραμένουν ΠΑΝΤΑ οι de jure νομικές αρχές.**
Το Watchtower επιδιώκει de facto μηχανική εμπιστοσύνη **μόνο** για την επαληθευμένη
αναπαράστασή του — ποτέ εξουσία δημιουργίας δικαίου. Κόστος και χρόνος υλοποίησης
δεν χαμηλώνουν τον όροφο· τον χαμηλώνουν μόνο ακρίβεια, πληρότητα, επαληθευσιμότητα,
διαλειτουργικότητα, ανθεκτικότητα και θεσμική τιμιότητα.

Κωδικοί αποστολής (χρησιμοποιούνται στο `TRACEABILITY-MATRIX.md`):

| κωδικός | δέσμευση αποστολής |
|---|---|
| MIS-1 | Ανεξάρτητα επαληθεύσιμη μηχανική αναπαράσταση (κανένα «εμπιστεύσου μας») |
| MIS-2 | Πληρότητα έναντι δηλωμένης εθνικής απογραφής — ποτέ σιωπηλή απώλεια |
| MIS-3 | Διτεμπορική πιστότητα: τι ίσχυε (valid) και τι ήξερε το Ίδρυμα (known) |
| MIS-4 | Νομολογία ως επίπεδο πρώτης τάξης, με εξέλιξη γραμμών αυθεντίας |
| MIS-5 | Πρώτη επιλογή μηχανικής κατανάλωσης από providers, με τοπική επαλήθευση |
| MIS-6 | Χρήσιμο και διαφανές για ανθρώπους (app, ιστότοπος, cockpit) |
| MIS-7 | Θεσμική τιμιότητα: `UNKNOWN`/`CONFLICTING` στον τύπο, ποτέ ψευδοβεβαιότητα |
| MIS-8 | De jure αυθεντία πάντα στο Κράτος/ΦΕΚ/δικαστήρια |
| MIS-9 | Ανθεκτικότητα, ασφάλεια, αναπαραγωγιμότητα σε κλίμακα κράτους |
| MIS-10 | Δομικά μονόδρομο όριο δημόσιου → ιδιωτικού |

---

## 1. CPEI — ΚΟΙΝΗ ΣΥΝΤΑΓΜΑΤΙΚΗ ΑΡΧΙΤΕΚΤΟΝΙΚΗ, ΤΡΙΑ PROFILES (διόρθωση εντολής 2026-09-01)

**Ανακαλείται** η ταξινόμηση της v1.3 §0 και του προηγούμενου μητρώου («CPEI +
CEILING-CROSSWALK = DEFERRED / SEPARATE PRIVATE TARGET»). Το CPEI
(`LAWMAX-CPEI-TARGET-SPEC.{md,sexp}`) είναι η **κοινή συνταγματική θεσμική
αρχιτεκτονική** και **δεν αποκαλείται ξανά ιδιωτικό**. Χωρίζεται σε **profiles**,
όχι σε ανταγωνιστικές αρχιτεκτονικές:

| profile | περιεχόμενο | κατάσταση |
|---|---|---|
| **`CPEI CONSTITUTIONAL CORE`** | τα 13 primitives, οι 12 στρώσεις L1–L12 ως ορισμοί, το InstitutionalAct, ο Constitutional Compiler, το Σύνταγμα (`LAWMAX-ARCHITECTURE-CONSTITUTION.sexp`) και οι ACTIVE SHARED TRUST FOUNDATIONS | **ACTIVE SHARED CORE** — κοινό και για τα δύο profiles |
| **`CPEI PUBLIC OBSERVATORY PROFILE`** | **αυτό το v1.4**: οι 12 στρώσεις εφαρμοσμένες στη δημόσια, επαληθευμένη αναπαράσταση του δικαίου· τα 15 επίπεδα §4 | **CURRENT PUBLIC CANDIDATE** |
| **`CPEI PRIVATE MATTER PROFILE`** | matter-solving πάνω στο `:matter` primitive· καταναλώνει υπογεγραμμένες δημόσιες εκδόσεις | **DEFERRED** — δεν σχεδιάζεται, δεν υλοποιείται τώρα |

### 1.1 Οι 12 στρώσεις CPEI στο PUBLIC OBSERVATORY PROFILE — καμία δεν αφαιρείται

| στρώση | δημόσια σημασία | υπάρχουσα έδρα (CPEI §1) | plane §4 | status εδώ |
|---|---|---|---|---|
| **L1** Immutable Institutional Ledger | κάθε θεσμική πράξη του παρατηρητηρίου (acquisition, event admission, release, correction, revocation, intent) σε ένα append-only ledger με SHA-256 αλυσίδα | `episodes.sexp` + `journal.lisp` + `self-history.lisp` | §4.5, §4.14 | EXTEND |
| **L2** Bitemporal Epistemic Graph | το Εθνικό Νομικό Ψηφιακό Δίδυμο: `valid_time × known_time` ανά γεγονός/κόμβο/ακμή | `version-graph.lisp` + `legal-temporal.lisp` + `legal-event-calculus.lisp` | §4.5, §4.9 | EXTEND |
| **L3** Typed Epistemic Objects | Legal IR: Fact/Proof/Hypothesis/Norm/Claim κλειστοί τύποι· PLANE-0..3 στον τύπο | `legal-ast.lisp` + `layout-types.lisp` + USC typed records | §4.3 | EXTEND |
| **L4** Proof / Counterproof | κάθε κρίσιμη απάντηση φέρει derivation proof ΚΑΙ counterproof/ανοιχτή ένσταση | `legal-inference-engine.lisp` + `proof-carrying.lisp` + `legal-dialectic.lisp` | §4.7 | EXTEND |
| **L5** Public Hypothesis Workspace | υποθέσεις ΜΟΝΟ για πηγές, ταυτότητα, τροποποιήσεις, οντολογία, νομική κατάσταση, νομολογία — με κύκλο ζωής (γέννηση → δοκιμή → λήξη), ποτέ σε release | `proposals.lisp` + `anomaly-detection.lisp` + `fluid-induction.lisp` (το `legal-hypo.lisp` = DEFER_PRIVATE: υποθέσεις έκβασης υπόθεσης) | §4.3 | EXTEND |
| **L6** Public Adversarial Parliament | ανεξάρτητη αντιπαλική επιθεώρηση κρίσιμων πράξεων δημοσίευσης και θεσμικής ανάλυσης (≥N ανεξάρτητοι κριτές με proof obligations, όχι personas) — ενσωματωμένη στην M5 | `legal-dialectic.lisp` + `deliberation.lisp` + M5 proposer-blind | §4.6, §4.9 | EXTEND |
| **L7** Public Legal Digital Twin + Normative-Impact Simulator | corpus-wide δημόσιες προσομοιώσεις κανονιστικής επίδρασης — ποτέ ιδιωτική στρατηγική | `what-if.lisp` + `legal-counterfactual.lisp` + `graph-reasoning.lisp` (`reason-impact`) | §4.8 | EXTEND |
| **L8** Governance / Adoption / Quarantine | can-adopt, shadow, QUARANTINE, signed adoption decisions· καμία αλλαγή κανονικής κατάστασης χωρίς πράξη | `adoption-decision.lisp` + `evolution-gate.lisp` + `review-queue.lisp` | §4.12 | REUSE |
| **L9** Self-Model, Coverage Awareness, Meta-Memory | το σχήμα της άγνοιας: coverage ledger, gap ledger, mission measures, ιστορία δικών του αλλαγών | `self-model.lisp` + `capability-registry.lisp` + gap ledger | §4.1, §4.13 | EXTEND |
| **L10** Constitutional Compiler | από το Σύνταγμα ΠΑΡΑΓΟΝΤΑΙ contracts/gates/tests/policies/trust invariants (roundtrip) | `LAWMAX-ARCHITECTURE-CONSTITUTION.sexp` + `architecture-gate.lisp` | §4.14 | EXTEND (CPEI §3 target) |
| **L11** Reproducible Substrate | hermetic builds, SBOM, cosign, NixOS L1+ όταν ξεμπλοκάρει | Dockerfile + `deps.lock` + `docker/sbom.json` + `LAWMAX-NIXOS-COGNITIVE-SUBSTRATE.md` | §4.14 | EXTEND |
| **L12** Human Sovereignty, Approval, Revocation, Rollback | approve/reject/revoke με υπογραφή· RBAC/MFA· rollback target ανά υιοθέτηση· ο δημιουργός η μόνη αρχή freeze/merge | `approval-policy.lisp` + `decisions.lisp` + `release-authority.lisp` | §4.12, §4.14 | EXTEND |

**Μηχανικός έλεγχος:** ο `V1.4-CONTRADICTION-OMISSION-AUDIT.sh` απαιτεί και τις 12
στρώσεις (L1 έως L12) ονομαστικά σε αυτό το κείμενο και στο crosswalk.

### 1.2 Δημόσια L5–L7 — τι ΕΙΝΑΙ και τι ΔΕΝ είναι

- **L5 (public):** υποθέσεις για **πηγές** (λείπει τεύχος;), **ταυτότητα** (ίδια
  απόφαση;), **τροποποιήσεις** (ποια διάταξη αγγίζει η πράξη;), **οντολογία** (ποια
  έννοια;), **νομική κατάσταση** (IN/OUT/UNDEC υποψήφιο), **νομολογία** (ratio
  υποψήφιο). Κάθε υπόθεση = typed αντικείμενο με `[ΟΧΙ συμπέρασμα]` σήμανση,
  ζει ΜΟΝΟ σε PLANE-3/PLANE-1 χώρο και πεθαίνει είτε σε reviewer adoption είτε σε
  λήξη — ποτέ σε release χωρίς πράξη.
- **L6 (public):** ≥2 ανεξάρτητοι εσωτερικοί κριτές (διακριτά σκεπτικά, proof
  obligations) για κάθε πράξη «δημοσίευση» και «θεσμική ανάλυση». Δεν ψηφίζουν την
  αλήθεια· παράγουν counterproof ή σιωπηλή απουσία ένστασης — και τα δύο τυπωμένα.
- **L7 (public):** corpus-wide κανονιστική προσομοίωση (§4.8). Ο τύπος δεν έχει
  πεδίο για υπόθεση, πελάτη, αντίδικο, πρόβλεψη έκβασης.

### 1.3 Δομικά απόντες ιδιωτικοί τύποι (η ΜΟΝΗ διαφορά public/private)

Οι εννέα τύποι που **δεν υπάρχουν** στο δημόσιο σχήμα: `Matter`, `Client`,
`privileged material`, `case file`, `private strategy`, `opponent modelling`,
`case-specific prediction`, `matter-specific world simulation`, `private use
telemetry`. Ένας μελλοντικός Private Matter Profile μπορεί να **καταναλώνει**
υπογεγραμμένες δημόσιες εκδόσεις· **καμία** ιδιωτική δεδομένη, δραστηριότητα ή
μοτίβο χρήσης δεν ρέει πίσω στο δημόσιο Ίδρυμα.

### 1.4 Το όριο ως ΤΥΠΟΣ, όχι ως φρουρός — διόρθωση της αξίωσης «κανένα πεδίο να γραφτεί» (RC-22, RC-23)

Η v1.3 έγραφε «καμία διαρροή να φρουρηθεί, γιατί κανένα πεδίο να γραφτεί». Το Stage
A απέδειξε ότι υπήρχαν ελεύθερα πεδία (`description`) και ότι το cockpit intent
εδραζόταν σε envelope με untyped matter-solving πεδία. Η ακριβής αξίωση του v1.4:

1. **Κανένα υπογεγραμμένο δημόσιο αντικείμενο δεν έχει ελεύθερο κείμενο.** Το
   `description` αφαιρέθηκε (MLTP v3 §1.0). Θεσμικό κείμενο (ratio/holding) είναι
   typed, passage-anchored, reviewer-adopted (MLTP v3 §2.6).
2. **Public InstitutionalAct profile** (έδρα: CPEI §2 `%ask-envelope` — μία έδρα,
   ΚΛΕΙΣΤΟ δημόσιο υποσύνολο πεδίων): `act_id`, `turn_id`, `jurisdiction`, `mode`
   (ΜΟΝΟ `legal-trusted | general | self-meta`), `authority` (capability/contract
   used), `claim` (typed: `release_ref` + `claim_ids` — όχι «θέσεις υπαγωγής»),
   `facts` (μόνο δημόσια, πηγο-δεμένα), `proof`, `counterproof` (μόνο δημόσιες
   ενστάσεις L6 επί δημοσίευσης/ανάλυσης), `temporal_validity`, `trust_status`,
   `memory_events`, `source_events`, `gate_results`, `system_generation`,
   `rollback_context`, `human_approval_policy`, `cockpit_intent` (§4.12). Τα πεδία
   `weakest_link` (Σ10 draft) και κάθε subsume/draft σημασιολογία **δεν** υπάρχουν
   στο δημόσιο profile — είναι private profile fields.
3. **Αρνητικός μάρτυρας (Q20):** προσθήκη οποιουδήποτε από τους 9 τύπους §1.3 ή
   ελεύθερου πεδίου σε υπογεγραμμένο αντικείμενο ⇒ **δεν μεταγλωττίζεται** (κλειστά
   σχήματα MLTP v3 §1.0 / InstitutionalAct public profile). Φίλτρο αντί δομής ⇒
   αποτυχία οικογένειας.

---

## 2. ΤΙ ΔΙΟΡΘΩΝΕΙ ΤΟ v1.4 — 31 ΡΙΖΕΣ STAGE A → ΜΙΑ ΕΔΡΑ ΚΛΕΙΣΙΜΑΤΟΣ Η ΚΑΘΕΜΙΑ

| ρίζα | τι έσπασε (Stage A, CONFIRMED) | έδρα κλεισίματος | witness |
|---|---|---|---|
| RC-01 | signing input IssuedClaim αόριστο | MLTP v3 §1.2 | KW-17 |
| RC-02 | κανένας φορέας/δέσμευση delegated κλειδιού | MLTP v3 §6 `keys`, §8.3 K1 | KW-18 |
| RC-03 | `issued_at` issuer-written | MLTP v3 §1.3, §6 `time_evidence`, §8.3 T | KW-19 |
| RC-04 | delegation window vs `d.signed_time` | MLTP v3 §8.3 K3 | KW-20 |
| RC-05 | επιλογή delegation/seq αόριστη | MLTP v3 §8.3 K2, V | KW-21 |
| RC-06 | QSR χωρίς sig_verify/registry/quorum | MLTP v3 §3, §8.3 Q1/Q3/Q4 | KW-22 |
| RC-07 | dangling ⇒ VERIFIED, receipt χωρίς level | MLTP v3 §7, §8.3 Q | KW-23 |
| RC-08 | QSR χωρίς id/subject | MLTP v3 §3 `record_id`, §8.3 Q2 | KW-24 |
| RC-09 | φρεσκάδα δεν υπολογίζεται | MLTP v3 §8.3 F | KW-25 |
| RC-10 | κανένα provenance βήμα | MLTP v3 §8.3 P | KW-26 |
| RC-11 | provenance ids χωρίς consumer άγκυρα | MLTP v3 §2.1α, §8.1 registry roots | KW-27 |
| RC-12 | 11 errors χωρίς βήμα | MLTP v3 §4.4 | KW-28 |
| RC-13 | UNDEC ⇒ VERIFIED | MLTP v3 §8.3 S | KW-29 |
| RC-14 | self-verdict αγνοείται | MLTP v3 §8.3 βήμα 0 | KW-30 |
| RC-15 | pinned-key μοντέλο σε PCL/v1.3/Q22 | MLTP v3 §4.5· αυτό το κείμενο §4.15· Q22 (α) διορθωμένο | KW-31 |
| RC-16 | «SHA-256 μόνο» περιγραφέας | `PUBLIC-OBSERVATORY-CROSSWALK.md` γραμμή verifier | KW-32 |
| RC-17 | inclusion ≠ release_root | MLTP v3 §5, §8.3 R | KW-33 |
| RC-18 | `profile` ≠ `claim_type` | MLTP v3 §1.1 `schema_id` | KW-34 |
| RC-19 | ανάκληση: εξουσία/υπογραφή/προτεραιότητα | MLTP v3 §2.9, §8.3 K0/V, §9 | KW-35 |
| RC-20 | reviewer adoption αυτο-υπογράψιμο | MLTP v3 §8.1 `reviewer_registry`, §8.3 J | KW-36 |
| RC-21 | `issuer` ελεύθερο | MLTP v3 §1.0 (αφαίρεση), §2.9 `issuer_name` | KW-37 |
| RC-22 | ελεύθερο `description` | MLTP v3 §1.0· αυτό το κείμενο §1.4 | KW-38 |
| RC-23 | cockpit intent σε untyped envelope | αυτό το κείμενο §1.4, §4.12 | KW-39 |
| RC-24 | καμία μονοτονία/ηλικία checkpoint | MLTP v3 §8.3 L1/L3 | KW-40 |
| RC-25 | δύο μηχανισμοί rotation | MLTP v3 §9.3, §4.5 | KW-41 |
| RC-26 | crypto χωρίς παραμέτρους | MLTP v3 §4.1 | KW-42 |
| RC-27 | proof_material 3/8 | MLTP v3 §2 (8/8) | KW-43 |
| RC-28 | two-channel ταυτότητα | MLTP v3 §2.5· αυτό το κείμενο §4.2· Q13 (γ) διορθωμένο | KW-44 |
| RC-29 | καμία γέφυρα bytes↔αντικείμενο | MLTP v3 §2.1/§2.2/§2.5 | KW-45 |
| RC-30 | provider-adoption αυτο-εκδόσιμο | MLTP v3 §8.1 `provider_registry`, §8.3 Q4 | KW-46 |
| RC-31 | witnesses ≠ μη-equivocation | MLTP v3 §10, §8.3 L2 | KW-47 |

Οι kill witnesses KW-17 έως KW-47 ορίζονται στο `PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md §7`
(**προδηλωμένοι, ΜΗ εκτελεσμένοι**). Οι KW-1 έως KW-16 διορθώθηκαν όπου το Stage A
έδειξε ότι ο δηλωμένος witness δεν σκότωνε τη δηλωμένη μετάλλαξη (KW-3, KW-9).

---

## 3. ΘΕΜΕΛΙΑ ΠΟΥ ΚΑΤΑΝΑΛΩΝΟΝΤΑΙ — ΚΑΝΕΝΑ ΔΕΝ ΑΝΑΔΙΑΤΥΠΩΝΕΤΑΙ

| θεμέλιο | ρόλος στο v1.4 | disposition |
|---|---|---|
| `LAWMAX-ARCHITECTURE-CONSTITUTION.sexp` + `--architecture-constitution-gate` | ο νόμος του repo· 13 primitives· επιβάλλεται τώρα | REUSE (ACTIVE ENFORCED) |
| `LAWMAX-CPEI-TARGET-SPEC.{md,sexp}` | οι 12 στρώσεις, InstitutionalAct, Constitutional Compiler target | REUSE (CORE) — profiles §1 |
| `LAWMAX-CEILING-CROSSWALK.{md,sexp}` | τα 15 επίπεδα ↔ CPEI· επεκτείνεται σε πλήρες capability universe | EXTEND (§5) |
| `LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md` | Work→Expression→Manifestation→Item, registries, receipts, relations, uncertainty | REUSE |
| `PROOF-CARRYING-LAW.md` (PCL-1) | Merkle inclusion RFC 9162· `authentic()` για era-1 | EXTEND → PCL-2 delegation-aware (βήμα 6) |
| `LAWMAX-PROOF-OBJECT-SPEC.md` | proof object (De Bruijn), census-2, Legal Proof Receipt 16 πεδία, kernel LOC-ceiling | REUSE |
| `LAWMAX-TRUST-BOOTSTRAP-SPEC.md` | owner key ceremony, pinned root, delegation, gossip | EXTEND (threshold root, cross-client witnesses — MLTP v3 §10) |
| `LAWMAX-KEY-LIFECYCLE-SPEC.md` | TUF-class roles, kid/alg/lineage, §2.5 | REUSE (με versioned precedence MLTP v3 §4.5/§9) |
| `LAWMAX-TEMPORAL-IDENTITY-DESIGN.md` | LegalAuthorityReceipt, μία ρίζα (PCL-02), version-graph | REUSE |
| `LAWMAX-TEMPORAL-SEMANTICS-SPEC.md` | effectivity conditions AST, condition records, regime edges | REUSE |
| `LAWMAX-THREAT-MODEL.md` | Θ1–Θ14 απειλές· κενά Θ3/Θ4/Θ5/Θ9/Θ10 κλείνουν στο §4.14 | EXTEND |
| `LAWMAX-MEMORY-KERNEL-SPEC.{md,sexp}` | μνήμη L1/L9 | REUSE |
| `LAWMAX-PHASE-1-TURN-ROOT-SPAN-DESIGN.md` | M1 turn_id / root span (ΕΓΚΕΚΡΙΜΕΝΟ design) | REUSE — προαπαιτούμενο L1 |
| `LAWMAX-AUTODIDACTIC-LOOP.md`, `LAWMAX-NIXOS-COGNITIVE-SUBSTRATE.md`, `LAWMAX-OMEGA-PLAN.md` | learning loop, substrate ladder, δρόμος | REUSE (κατά τη σειρά του δημιουργού, Runner/NixOS blocked) |

Πλήρης κατάλογος ΚΑΘΕ υπάρχοντος συστατικού (133 `source/`, 48 CLI, verify, authority-v2,
docker, scripts, docs) με **ακριβώς μία** disposition: `PUBLIC-OBSERVATORY-CROSSWALK.md §A`.

---

## 4. Η ΑΠΑΙΤΟΥΜΕΝΗ ΔΗΜΟΣΙΑ ΑΡΧΙΤΕΚΤΟΝΙΚΗ — 15 ΕΝΟΠΟΙΗΜΕΝΑ ΕΠΙΠΕΔΑ + 1 ΠΡΩΤΗΣ ΤΑΞΗΣ PROFILE (§4.16)

Κάθε επίπεδο: σκοπός · απαιτήσεις (R-ids, πλήρης ιχνηλάτηση στο
`TRACEABILITY-MATRIX.md`) · έδρες (υπάρχουσες → disposition, ή `MISSING`) ·
διεπαφές · invariants · αρνητικοί μάρτυρες · φέτα · βήμα υλοποίησης. Οι μηχανές
M1–M7 της v1.2 **παραμένουν** ως λειτουργικές έδρες (crosswalk §A.1) και
κατανέμονται στα επίπεδα — δεν δημιουργείται δεύτερο σύνολο μηχανών.

### 4.1 National Legal Census and Source Radar (L9 · M1) — R-01 έως R-13

**Σκοπός:** ένα **δηλωμένο, ανεξάρτητα ελέγξιμο σύμπαν** αναμενόμενων ελληνικών
νομικών πηγών, ως **ολική συνάρτηση** θέσεων → κατάσταση, ΠΡΙΝ από το περιεχόμενο.

**Το σύμπαν (κάθε γραμμή = census space με δικό του απαριθμητή):** κάθε τεύχος και
σειρά ΦΕΚ (Α΄, Β΄, Γ΄, Δ΄, ΑΑΠ, ΥΟΔΔ, ΠΡΑ.Δ.Ι.Τ., Α.Σ.Ε.Π., Δ.Δ.Σ. και οι ιστορικές
σειρές — απαρίθμηση τεύχος × έτος × αριθμός)· Σύνταγμα, νόμοι, κώδικες, τροποποιήσεις·
προεδρικά διατάγματα· κανονιστικές/υπουργικές πράξεις (συμπεριλαμβανομένης της
Διαύγειας ως κανάλι, όχι ως αρχή)· πράξεις ανεξάρτητων αρχών· εφαρμοστέα ενωσιακή
νομοθεσία και εθνική μεταφορά (EUR-Lex/Cellar ως κανάλι)· ΔΕΕ/ΕΔΔΑ υλικό που
επηρεάζει την ελληνική νομική κατάσταση· **όλα** τα δικαστήρια και **όλες** οι
νομίμως δημοσιεύσιμες αποφάσεις (απαρίθμηση δικαστήριο × έτος × αύξων)· αιτιολογικές
εκθέσεις, κοινοβουλευτικό υλικό, επίσημες προπαρασκευαστικές εργασίες· εγκύκλιοι/
οδηγίες **ρητά διαχωρισμένες** από δεσμευτικό δίκαιο (δικό τους space,
`binding: false`)· δευτερογενής θεωρία **μόνο** όπου νόμιμο και αδειοδοτημένο,
**πάντα** `authoritative: false`.

**Ανά αναμενόμενο αντικείμενο (ledger entry):** `position` (census key),
`state ∈ {INGESTED, EXPLICITLY-ABSENT, QUARANTINED, UNKNOWN}`, `source_authority`
(`auth1:`), `acquisition_channel` (registry), `freshness_budget` (duration ανά
space), `gap_reason` (ΚΛΕΙΣΤΟ sum, MLTP v3 §2.4), `retry_state`
(attempts/next_at/escalated), `coverage_evidence` = inclusion proof στο
`coverage_ledger_root` που φέρει το υπογεγραμμένο `coverage-and-freshness` claim.

**Έδρες:** `ingestion-daemon.lisp` + `legislation-ingestion.lisp` +
`government-source.lisp` + `document-fetch.lisp` (M1 radar: EXTEND — απαριθμητής
σήμερα 1 τεύχος × 1 έτος, AS-IS R-1)· `source-profile.lisp` (ranked channels:
REUSE)· `capability-registry.lisp`/gap ledger (L9: EXTEND)· **coverage ledger ως
ολική συνάρτηση = `MISSING`** (νέα capability πάνω στο journal, όχι νέο store —
CPEI §4)· **census-universe RegistrySnapshot = `MISSING`** (root-signed, MLTP v3 §2.9).

**Διεπαφές:** `coverage-and-freshness` IssuedClaim ανά space· API `/coverage/{space}`
(§4.15)· cockpit όψη «κενά κάλυψης» (§4.12).

**Invariants:** (I-4.1a) κάθε θέση του δηλωμένου σύμπαντος έχει ακριβώς μία κατάσταση·
(I-4.1b) «τα πάντα» ⇒ μόνο έναντι `universe_declaration_ref`· (I-4.1c) αδιαθέσιμο/
αδημοσίευτο = `EXPLICITLY-ABSENT`/`UNKNOWN` με αιτία, ποτέ `INGESTED`· (I-4.1d)
μια δεύτερη ανεξάρτητη απαρίθμηση συμφωνεί ή οι αποκλίσεις εξηγούνται (Μ-4).

**Μάρτυρες:** Q01, Q02, Q29· KW-48 (θέση χωρίς κατάσταση περνά ⇒ πρέπει να κοκκινίσει).
**Φέτα:** VS-13. **Βήμα:** 1.

### 4.2 Multimodal Acquisition and Source Authenticity (L1/L3 · M2) — R-14 έως R-23

**Σκοπός:** κάθε επίσημο artifact — XML, HTML, native PDF, σαρωμένο PDF/εικόνα,
σελιδοποίηση, πίνακες/παραρτήματα, υπογραφές/σφραγίδες, μεταδεδομένα, επίσημο
οπτικοακουστικό υλικό όπου νομικά σχετικό, πολλαπλά manifestations του ίδιου
work — σφραγίζεται (M2, append-only) και δένεται στο USC μοντέλο
`Work → Expression → Manifestation → Item`. **Τα raw bytes ταυτοποιούν item, όχι
work.** Ένα timestamp αποδεικνύει χρόνο, όχι εκδίδουσα αρχή.

**Αυθεντικότητα πηγής (όλα, όχι κάποια):** `institutional_register_id` (`ireg1:`),
`authority-proof/2` (κρατική προέλευση με βαθμό S1–S3, MLTP v3 §2.1α),
`acquisition_receipt_id` (`acq1:`), custody chain (§2.1β), αυθεντικοποιημένο
χρονικό τεκμήριο (TSR επί των bytes), divergence witnesses όπου επίσημες πηγές
διαφωνούν (`official-sources-conflict` ⇒ `CONFLICTING`, ποτέ σιωπηλός νικητής).

**Ταυτότητα δύο καναλιών (RC-28, διόρθωση Q13 γ):** ίδια απόφαση/διάταξη από
δύο κανάλια ⇒ **ίδιο `work_id`** (ο invariant)· ίδιο κείμενο ⇒ ίδιο `expression_id`·
διαφορετικό κείμενο (π.χ. ανωνυμοποιημένο) ⇒ διακριτές expressions με
`derived_from_expression`· πάντα διαφορετικά `manifestation_id`/receipts.

**Έδρες:** `pdf-authority.lisp` (native PDF: REUSE)· `layout-types.lisp` +
`validate-layout-graph.lisp` + `typographic-classifier.lisp` + `legal-ast.lisp`
(σελιδοποίηση/δομή: EXTEND για πίνακες/παραρτήματα)· `text-canonicalizer.lisp`
(REUSE)· `corpus-provenance.lisp` + `authority-proof-bundle.lisp` +
`legal-authority-receipt.lisp` (receipts: EXTEND)· `legal-identity.lisp` +
`legal-id-registry.lisp` (USC ids: EXTEND — manifestation level)· `x509-authority.lisp`
+ `asn1-der.lisp` + `timestamp-authority.lisp` (TSR/υπογραφές: EXTEND — πλήρης
RFC-3161 επαλήθευση, PAdES/XAdES ανίχνευση)· **OCR/σαρωμένα = `MISSING`** (νευρωνικό
runtime §4.3/§4.4)· **audiovisual = `MISSING`** (transcript ως manifestation με
`media_type`)· **custody chain = `MISSING`**· **authority-proof/2 = `MISSING`**.

**Invariants:** (I-4.2a) κανένα `RELEASED` χωρίς και τα τέσσερα provenance στοιχεία
(MLTP v3 §8.3 P)· (I-4.2b) raw bytes ↔ item, ποτέ ↔ work· (I-4.2c) `S0-declared-only`
⇒ `insufficient-provenance`· (I-4.2d) διαφωνία επίσημων πηγών ⇒ `CONFLICTING`.

**Μάρτυρες:** Q03, Q04, Q07, Q13, Q24, Q30· KW-4, KW-26, KW-27, KW-44, KW-45.
**Φέτες:** VS-01, VS-03, VS-04. **Βήμα:** 2, 7.

### 4.3 Neuro-Symbolic Multimodal Legal Intelligence Plane (L3/L5 · PLANE-1/PLANE-3) — R-24 έως R-30

**Σκοπός:** ενσωμάτωση «Neuro-Symbolic AI + Multi-Modal Ontological Alignment» ΜΕΣΑ
στο Σύνταγμα CPEI, με **επιστημικό τείχος** μεταξύ νευρωνικού και συμβολικού
επιπέδου.

**Το νευρωνικό επίπεδο (PLANE-3, εξωτερικό runtime, §4.4) εκτελεί:** OCR και
κατανόηση σελιδοποίησης· πολυτροπική συμφιλίωση εγγράφων· εξαγωγή οντοτήτων/
σχέσεων· υποψήφιες αντιστοιχίσεις οντολογίας· υποψήφια νομικά γεγονότα· υποψήφια
ανάλυση ratio/holding/issue· σημασιολογική ομοιότητα και ανίχνευση ανωμαλιών·
ανίχνευση κενών πηγών και αντιφάσεων.

**Μπορεί να εξάγει ΜΟΝΟ typed candidates** (`lawmax/neural-candidate/1`, κλειστό
σχήμα):
```
{ "candidate_id": <"cand1:" + canonical-hash(content χωρίς model_provenance)>,   # model-independent
  "kind": <ΚΛΕΙΣΤΟ: ocr-text | layout-block | entity | relation | ontology-mapping | legal-event |
           ratio-candidate | holding-candidate | issue-candidate | similarity | anomaly | source-gap | contradiction>,
  "anchors": [ { "manifestation_id": "lsm1:<hash>", "artifact_digest": "<hex>", "start": <int>, "end": <int>,
                 "page": <int> | null, "bbox": [<int>,<int>,<int>,<int>] | null } ],   # ΥΠΟΧΡΕΩΤΙΚΟ, ≥1
  "content": <typed κατά kind — ΠΟΤΕ ελεύθερο κείμενο εκτός ocr-text/ratio-candidate που είναι ΠΑΝΤΑ anchored>,
  "alternatives": [ { "content": <typed>, "score": <rational 0..1> } ],
  "uncertainty": { "score": <rational 0..1>, "kind": <USC §8 uncertainty kind> },
  "evidence": { "supporting": [ <anchor> ], "contradicting": [ <anchor> ] },
  "transformation_provenance": { "model_id": <string>, "weights_sha256": "<hex>", "runtime_manifest_sha256": "<hex>",
                                  "prompt_or_config_sha256": "<hex>", "produced_at": <legal-instant> } }
```
**Ποτέ:** δεν γράφει κανονική νομική κατάσταση απευθείας· δεν υπογράφει release·
δεν πιστοποιεί τον εαυτό του· δεν μετατρέπει πιθανότητα σε νομική αλήθεια· δεν
δημοσιεύει θεσμικό ratio/holding αυτόματα· δεν παρακάμπτει ανθρώπινες ή συμβολικές
πύλες. Δομικά: το νευρωνικό runtime **δεν έχει** κλειδί, **δεν έχει** write
authority στο journal (write-authority.lisp = μία έδρα εγγραφής), και ο μόνος
τύπος που δέχεται η συμβολική πλευρά από αυτό είναι ο `neural-candidate/1`.

**Το συμβολικό επίπεδο (Common Lisp kernel) εκτελεί:** επικύρωση typed Legal IR·
χρονικό και συλλογισμό γεγονότων· δεοντικό συλλογισμό· defeasible κανόνες και
εξαιρέσεις· επιχειρηματολογία και δομές βάρους απόδειξης· έλεγχο αντιφάσεων και
περιορισμών· παραγωγή proof/counterproof· **ρητή αποχή**.

**Open-textured / διακριτικές / γνήσια ερμηνευτικές διατάξεις** παραμένουν typed ως
`interpretive | discretionary | underdetermined` (Legal IR τύπος `norm.determinacy`)·
το σύστημα **δεν** προσποιείται ότι όλο το δίκαιο είναι μηχανικά αποφασίσιμο —
επιστρέφει `UNKNOWN(interpretive)` με τις ερμηνευτικές εναλλακτικές ως typed υποθέσεις.

**Έδρες:** `legal-extraction-verify.lisp` («neural προτείνει / symbolic κρίνει»:
EXTEND — η πύλη υπάρχει)· `advisor.lisp` (LLM ως προτείνων εκτός εμπιστοσύνης:
REUSE ως πρότυπο)· `legal-inference-engine.lisp`, `legal-deontic.lisp`,
`legal-event-calculus.lisp`, `legal-conflict-resolution.lisp`, `legal-dialectic.lisp`,
`legal-subsumption.lisp`, `guard-metaeval.lisp` (συμβολικός πυρήνας: REUSE/EXTEND)·
`greek-legislation-ontology.lisp` + `knowledge-graph.lisp` + `rdfs-inference.lisp`
+ `shacl-validator.lisp` (οντολογία/επικύρωση: EXTEND για alignment)·
`proposals.lisp` + `fluid-induction.lisp` + `anomaly-detection.lisp` (L5: EXTEND)· **νευρωνικό runtime +
closed protocol = `MISSING`** (§4.4)· **`norm.determinacy` τύπος = `MISSING`**.

**Invariants:** (I-4.3a) κανένα PLANE-3 αντικείμενο σε release artifact — στον
ΤΥΠΟ (Q09)· (I-4.3b) κάθε candidate έχει ≥1 anchor· (I-4.3c) candidate χωρίς
`transformation_provenance` ⇒ απόρριψη· (I-4.3d) η προαγωγή candidate → Legal IR
γίνεται ΜΟΝΟ από συμβολική επικύρωση + (όπου θεσμικό) reviewer adoption.

**Μάρτυρες:** Q09, Q31, Q32· KW-7, KW-49 (candidate χωρίς anchor γίνεται δεκτό ⇒
κοκκίνισμα), KW-50 (interpretive διάταξη επιστρέφεται ως αποφασισμένη ⇒ κοκκίνισμα).
**Φέτες:** VS-04, VS-05, VS-06, VS-07. **Βήματα:** 7, 8.

### 4.4 Language and Runtime Boundary — R-31 έως R-34

| επίπεδο | γλώσσα/runtime | τι |
|---|---|---|
| Κανονικός συμβολικός & θεσμικός πυρήνας | **Common Lisp** (SBCL, υπάρχουσα έδρα) | typed Legal IR, οντολογία και κανόνες ταυτότητας, χρονικός/δεοντικός/defeasible συλλογισμός, proof/counterproof, InstitutionalAct, governance, Constitutional Compiler |
| Νευρωνική/πολυτροπική συμπερασματολογία | εξωτερικό runtime: Python/PyTorch/ONNX (ή ανώτερο ισοδύναμο) — **εκτός** trusted path | OCR/layout, extraction, alignment candidates (§4.3) |
| Δεύτερος ανεξάρτητος Legal Compiler/Verifier | **Rust** (προτιμώμενο· εναλλακτικά OCaml) — διαφορετική γλώσσα ΚΑΙ runtime | §4.6 differential verification + δεύτερη υλοποίηση του MLTP verifier |
| Δημόσιοι verifiers αναφοράς | Python stdlib + Node (υπάρχουν: `deployment/verify/verify.py`, `verify.mjs`) | PCL-1 σήμερα → MLTP v3 (βήμα 6) |

**Closed, versioned, typed protocol** νευρωνικού ↔ συμβολικού: μηνύματα ΜΟΝΟ
`neural-candidate/1` (είσοδος στο symbolic) και `neural-task/1` (`task_id`,
`manifestation_id`, `kind`, `tool_manifest_sha256`, `deadline`) (έξοδος προς
neural)· σειριοποίηση canonical JSON· κάθε μήνυμα journaled· **κανένα ελεύθερο
πεδίο κειμένου εκτός anchored `ocr-text`/`ratio-candidate` content**. Η
`safe-read.lisp` (μία έδρα ασφαλούς αποσειριοποίησης) είναι το μοναδικό σημείο
εισόδου. Έδρες: `safe-read.lisp` (REUSE), `document-fetch.lisp` (πρότυπο
«pure-Lisp ορχήστρωση εξωτερικού fetcher»: REUSE ως πρότυπο), **protocol schema =
`MISSING`**, **Rust compiler = `MISSING`**.

**Μάρτυρες:** Q31 (ελεύθερο κείμενο στο πρωτόκολλο ⇒ δεν μεταγλωττίζεται), Q33.
**Φέτες:** VS-06, VS-09. **Βήματα:** 5, 7.

### 4.5 Event-Sourced Bitemporal National Legal Digital Twin (L2 · M3) — R-35 έως R-38

**Σκοπός:** το νομικό σύστημα ως event-sourced διτεμπορικός γράφος
`valid_time × known_time`. Η ενοποιημένη μορφή είναι **προβολή**, ποτέ πρωτογενές.

**Κλειστός κατάλογος γεγονότων (επέκταση v1.2 M3):** `ENACTMENT`, `COMMENCEMENT`,
`AMENDMENT`, `REPEAL`, `SUSPENSION`, `REVIVAL`, `ANNULMENT` (δικαστικό γεγονός με
δική του διτεμπορικότητα — ποτέ νομοθετική τροποποίηση), `CORRECTION`,
`DELEGATED-AUTHORITY` (authorizes-delegation), `CROSS-REFERENCE`, `EU-TRANSPOSITION`,
`CONSTITUTIONAL-REVIEW` (declares-unconstitutional erga-omnes/incidenter),
`JUDICIAL-INTERPRETATION` (judicially-interprets), `LATER-TREATMENT` (followed /
applied / distinguished / doubted / limited / overruled / annulled),
`UNCERTAINTY` και `SOURCE-CONFLICT` (USC §8 kinds ως γεγονότα με κύκλο ζωής).
Άγνωστος τύπος ⇒ `UNKNOWN`, ποτέ σιωπηλή απόρριψη.

**Δύο ερωτήματα, πάντα:** «τι ίσχυε νομικά σε valid_time v» και «τι ήξερε το
Ίδρυμα σε known_time k» — προβολή στο `(v, k)` χρησιμοποιεί μόνο γεγονότα με
`known_from ≤ k` (Q06, KT5).

**Δημόσιος νομικός χρόνος ≠ εσωτερικός χρόνος ελέγχου (διευκρίνιση δημιουργού
2026-09-01, MLTP v3 §2.0):** το δημόσιο και AI-facing χρονολόγιο **περιγράφει τον
νόμο** — `issued_at`, `published_at`, `effective_from`, `effective_to`, `ceased_by`,
`cessation_type ∈ {repeal, sunset, replacement, suspension, annulment, transition}`
(`lawmax/legal-timeline/1`, στο payload). Το Ίδρυμα διατηρεί **χωριστά** αμετάβλητο
εσωτερικό χρονολόγιο ελέγχου — `acquired_at`, `verified_at`, `released_at`,
`corrected_at`, `revoked_at` (`lawmax/audit-timeline/1`, στο proof/audit layer). Ο
χρόνος απόκτησης/γνώσης **ποτέ** δεν κρίνει νομική ισχύ και **ποτέ** δεν
παρουσιάζεται ως μέρος του νομικού κανόνα· υπάρχει για λογοδοσία, ανίχνευση
καθυστερημένης πηγής, μέτρηση φρεσκάδας, ανακατασκευή ιστορικής απάντησης, διόρθωση
και διερεύνηση συμβάντων. Η διτεμπορικότητα (`valid × known`) διατηρείται εσωτερικά·
το `known_time` που εκτίθεται είναι η τομή γνώσης του release, όχι ο χρόνος πρώτης
μάθησης ανά αντικείμενο.

**Έδρες:** `version-graph.lisp` (διτεμπορικός γράφος: EXTEND — δικαστικά/ενωσιακά
γεγονότα)· `legal-temporal.lisp` + `LAWMAX-TEMPORAL-SEMANTICS-SPEC.md` (effectivity
conditions: REUSE)· `legal-event-calculus.lisp` (REUSE)· `journal.lisp` (event
store: REUSE)· `corpus-eu-links.lisp` + `eu-interop-layer.lisp` (EU transposition:
EXTEND)· `citation-authority.lisp` + `legal-decisions.lisp` (LATER-TREATMENT από explicit citations: EXTEND)· `consolidation-engine.lisp`
/ `consolidation-proof.lisp` (προβολή + replayable amendment proof: REUSE).

**Invariants:** (I-4.5a) ίδια τομή ⇒ ίδιο αποτέλεσμα διαχρονικά· (I-4.5b) τερματικό
γεγονός που έγινε γνωστό αργά δεν εμφανίζεται σε προγενέστερο k· (I-4.5c) απόφαση
δεν παράγει νομοθετικό γεγονός (μη εκφράσιμο στον τύπο)· (I-4.5d) κάθε γεγονός
φέρει πηγή (`manifestation_id` + anchor).

**Μάρτυρες:** Q05, Q06, Q08, Q10· KW-51 (γεγονός χωρίς πηγή γίνεται δεκτό ⇒
κοκκίνισμα). **Φέτες:** VS-01, VS-02. **Βήμα:** 3.

### 4.6 Dual Independent Legal Compilers (L4/L6 · M5) — R-39 έως R-43

**Σκοπός:** ανίχνευση common-mode σφαλμάτων υλοποίησης. Δύο compilers, **χωριστές
υλοποιήσεις ΚΑΙ runtimes** (Common Lisp + Rust), καταναλώνουν την ΙΔΙΑ κανονική
είσοδο γεγονότων (journal) και παράγουν **ανεξάρτητα** `legal_state_root` και
κρίσιμες προβολές (`projection_roots`: consolidated texts, in-force sets, citation
graph, line-of-authority).

**Κανόνες:** σύγκριση ριζών ΠΡΙΝ από υπογραφή release· απόκλιση ⇒ αυτόματο
`QUARANTINED` του release (compiler-divergence), ποτέ επιλογή νικητή· κανένας
compiler δεν πιστοποιεί τον εαυτό του — καθένας υπογράφει το δικό του
`compiler-attestation` με δικό του delegated κλειδί (scope `compiler-attestation`)·
ο verifier απαιτεί ισότητα (MLTP v3 §8.3 R4)· **η συμφωνία N-version ΠΟΤΕ δεν
γίνεται admission predicate** (KT10: συμφωνία = ένδειξη, διαφωνία = `CONFLICTING`).

**Έδρες:** Lisp compiler = `consolidation-engine.lisp` + `version-graph.lisp` +
`legal-inference-engine.lisp` (REUSE)· proposer-blind M5 = `release-authority.lisp`
+ `release-gate.lisp` + `verify-truth-gate.lisp` (EXTEND)· `deployment/verify/verify-temporal.py`
(ανεξάρτητη Python αναπαραγωγή: REUSE ως τρίτος έλεγχος, όχι ως compiler)· **Rust
compiler = `MISSING`**· **differential verification harness = `MISSING`**.

**Μάρτυρες:** Q11, Q34· KW-52 (release με μία μόνο attestation περνά ⇒ κοκκίνισμα).
**Φέτες:** VS-09, VS-10. **Βήματα:** 4, 5.

### 4.7 Proof-Carrying Query Engine (L4 · M6) — R-44 έως R-47

**Σκοπός:** κάθε κρίσιμη απάντηση app/API/MCP μπορεί να επιστρέψει το πλήρες
proof-carrying αντικείμενο και ο provider την επαληθεύει **τοπικά**.

**Τύπος απάντησης (`lawmax/proof-carrying-answer/1`):** `answer` (typed
κατά ερώτημα) · `valid_at` · `known_at` · `official_source_chain` (λίστα
`source-authenticity` claim_ids) · `applied_legal_events` (event ids + inclusion) ·
`derivation_proof` (De Bruijn proof object, PROOF-OBJECT §0) · `counterproof`
(ρητό counterproof αντικείμενο ή `open_objections` — L6) · `coverage_state`
(`coverage-and-freshness` claim_id για κάθε εμπλεκόμενο space) · `uncertainty`
(USC §8 records) · `freshness_deadline` (= `as_of + max_staleness`) ·
`revocation_status` (checkpoint ref) · `dependency_set` (ids των οποίων η αλλαγή
ακυρώνει την απάντηση — invalidation set) · `verifier_profile` (MLTP v3 §8, έκδοση,
`LocalTrustState` απαιτήσεις) · `trust_bundle_ref` (`bnd1:`) · `legal_timeline` (`lawmax/legal-timeline/1` του αντικειμένου — ο νόμος) ·
`citation` (`lawmax/citation/1`, §4.16 — δεσμευμένη μέσα στην υπογραφή του
`CertifiedResult`).

**Χωρίς έγκυρο, φρέσκο τεκμήριο το μηχανικό αποτέλεσμα είναι** `UNKNOWN` |
`CONFLICTING` | `UNVERIFIED_FOR_MACHINE_RELIANCE` — **ποτέ** απάντηση χωρίς
προσδιορισμό. Το `CONFLICTING` είναι typed reason του `UNKNOWN` (official-sources-conflict
ή compiler-divergence). Χωρίς δεσμευμένη παραπομπή ⇒ `UNVERIFIED_FOR_ATTRIBUTED_RELIANCE`
(§4.16).

**Τι βλέπουν άνθρωποι και συνήθεις AI απαντήσεις:** το νομικό χρονολόγιο, τις
πηγές, την απόδειξη, την κάλυψη, την αβεβαιότητα, τη φρεσκάδα, την ανάκληση και την
παραπομπή. **Όχι** πότε το Watchtower έμαθε πρώτη φορά το αντικείμενο. Η AI
επαλήθευση λαμβάνει μόνο release, freshness, coverage, revocation και provenance
τεκμήρια. Η πλήρης χρονική λογοδοσία (`audit-timeline/1`) είναι διαθέσιμη στο
**dedicated audit endpoint** `/audit/{claim_id}` (και μέσα στο proof layer του
TrustBundle) — για διερεύνηση, όχι για την απάντηση.

**Έδρες:** `legal-qa.lisp` + `legal-reasoning-bridge.lisp` («provable answers,
never generated»: EXTEND)· `proof-carrying.lisp` (REUSE)· `legal-dialectic.lisp`
(counterproof: EXTEND)· `corpus-diff.lisp` (invalidation set: EXTEND)· `mcp-server.lisp`
(4 εργαλεία σήμερα: `list_corpora`, `get_article`, `verify_provision`, `audit_corpus` — EXTEND)·
`capability-api.lisp` (transport-agnostic προβολή: REUSE)· **OpenAPI = `MISSING`**
(AS-IS EV-5)· **answer type = `MISSING`**.

**Μάρτυρες:** Q14, Q27, Q35· KW-53 (απάντηση χωρίς `counterproof` slot ⇒ δεν
μεταγλωττίζεται). **Φέτα:** VS-01, VS-11. **Βήμα:** 11.

### 4.8 Public Normative-Impact Simulator (L7 · M3) — R-48 έως R-50

**Σκοπός:** corpus-wide δημόσια ερωτήματα: ποιες διατάξεις επηρεάζει μια
τροποποίηση· ποιες κατ' εξουσιοδότηση πράξεις εξαρτώνται από μια εξουσιοδότηση·
ποιες παραπομπές σπάνε· ποια ενοποιημένα κείμενα αλλάζουν· ποιες σχέσεις
EU-transposition επηρεάζονται· ποιες νομολογιακές γραμμές εξαρτώνται από τον
αλλαγμένο κανόνα. Είναι **δημόσιος προσομοιωτής νομικού συστήματος**, όχι ιδιωτική
στρατηγική υπόθεσης — ο τύπος (MLTP v3 §2.8) δεν έχει πεδίο υπόθεσης.

**Επαναχρησιμοποιεί ELI-Impact** (ELI extension for impact/relations) ως εξωτερική
προβολή αντί για ασύμβατα ισοδύναμα (§4.11)· εσωτερικά τα `rel1:` USC §6.3 records
είναι η πηγή αλήθειας.

**Έδρες:** `graph-reasoning.lisp` (`reason-impact`: EXTEND — διτεμπορική τομή,
TEMPORAL-IDENTITY §1.6)· `what-if.lisp` + `legal-counterfactual.lisp` (REUSE)·
`legal-references.lisp` + `legal-hypergraph.lisp` (REUSE)· CEILING-CROSSWALK
Level 8 (νομοθετική προσομοίωση, status ✗ → HAS_SEAT με αυτό το επίπεδο)·
**replay manifest + `normative-impact-projection` profile = `MISSING`**.

**Invariants:** (I-4.8a) κάθε προβολή επαναπαίξιμη (auditor ξανατρέχει το
`replay_manifest`, ίδιο `impact_root`)· (I-4.8b) καμία πρόβλεψη έκβασης.

**Μάρτυρες:** Q36· KW-54 (impact claim με πεδίο έκβασης υπόθεσης ⇒ δεν μεταγλωττίζεται).
**Φέτα:** VS-02. **Βήμα:** 10.

### 4.9 Complete Jurisprudence Evolution Plane (L2/L6 · M4 · CEILING Level 7) — R-51 έως R-56

**Ανά διαθέσιμη απόφαση:** σταθερή work/expression/manifestation ταυτότητα· ECLI
όπου υπάρχει (ή ντετερμινιστικό `provisional_id` από official key)· δικαστήριο/
τμήμα/σύνθεση· δικονομικό ιστορικό· διάδικοι και κατάσταση ανωνυμοποίησης· νομικά
ζητήματα· διατακτικό· passage-anchored holding· ratio/obiter candidates· χωριστές
γνώμες· παρατιθέμενη νομοθεσία και αποφάσεις· επίπεδο αυθεντίας (plenary/chamber/
single-judge)· μεταγενέστερη μεταχείριση `followed / applied / distinguished /
doubted / limited / overruled / annulled`· διτεμπορικός line-of-authority γράφος·
outliers και ανεπίλυτες διασπάσεις (typed `line-split` uncertainty).

**Τέσσερις χωριστές τάξεις (ποτέ συγχωνεύονται):**

| τάξη | τι | profile / τύπος | ποιος υπογράφει |
|---|---|---|---|
| 1 | source-verifiable ταυτότητα και κείμενο απόφασης | `judgment-identity-and-text` | delegated release key |
| 2 | μηχανικά παραγόμενες σχέσεις παραπομπής/δικονομίας (explicit-citation ΜΟΝΟ, USC §6.3) | `rel1:` records μέσα σε `judgment-identity-and-text` proof_material + `LATER-TREATMENT` events | delegated release key (ντετερμινιστικός parser, pinned) |
| 3 | θεσμικά υιοθετημένη νομολογιακή ανάλυση (ratio/obiter/holding/issue/weight) | `jurisprudential-analysis` με `reviewer_adoption_act` | reviewer ∈ `reviewer_registry` + release key |
| 4 | υποθέσεις AI | `neural-candidate/1` (§4.3), PLANE-3 | κανείς — δεν είναι θεσμική πράξη |

**AI inference δεν πιστοποιείται ποτέ αυτόματα ως θεσμικό ratio** (MLTP v3 §2.6,
§8.3 J). Η `authority_weight` **μετρείται** (plenary-over-chamber, line-count,
line-consistency), ποτέ γνώμη μοντέλου (CEILING Level 15 φρουρός).

**Έδρες:** `legal-decisions.lisp` + `decisions.lisp` (νομολογία intake/ΑΠ: EXTEND —
όλα τα δικαστήρια, ECLI)· `citation-authority.lisp`
(citation graph: EXTEND)· `jurisprudence-judge.lisp` (μετρημένη ικανότητα: REUSE)·
(`legal-precedent.lisp`, `legal-casegrammar.lisp` = DEFER_PRIVATE — ομοιότητα
γεγονότων υπόθεσης, όχι δημόσια γραμμή αυθεντίας)· CEILING Level 7 (`:authority` + L2, status ✗ →
HAS_SEAT με αυτό το επίπεδο)· **ECLI υλοποίηση = `MISSING`** (AS-IS EV-4)·
**reviewer registry + adoption act = `MISSING`**· **line-of-authority graph =
`MISSING`** (EXTEND του version-graph).

**Μάρτυρες:** Q07, Q08, Q25, Q37· KW-7, KW-36, KW-44, KW-55 (`later_treatment`
χωρίς explicit-citation evidence γίνεται δεκτό ⇒ κοκκίνισμα). **Φέτα:** VS-08.
**Βήμα:** 9.

### 4.10 MLTP v2 → v3 και Distributed Trust Mesh — R-57 έως R-70

Έδρα: `MACHINE-LEGAL-TRUST-PROTOCOL.md` v3 — τα τρία επίπεδα `IssuedClaim` /
`TrustBundle` / `VerificationReceipt` **διατηρούνται**· προστίθεται Layer 0
(root-signed statements). Ιδιότητες (όλες με witness):

| ιδιότητα | έδρα MLTP v3 | witness |
|---|---|---|
| typed claim profiles (8, κλειστό sum, `schema_id` παράγωγο) | §1.1, §2 | KW-34, KW-43 |
| πλήρης δέσμευση σημασιολογικών πεδίων στην υπογραφή | §1.2 | KW-17 |
| ανεξάρτητα υπογεγραμμένο QualificationStateRecord (registry allowlist, quorum, subject) | §3 | KW-22, KW-23, KW-24, KW-46 |
| αυθεντικοποιημένος χρόνος (TSR επί της υπογραφής, verifier παράγει `t_sig`) | §1.3, §8.3 T | KW-19 |
| delegation έναντι αυθεντικοποιημένου χρόνου υπογραφής, max-seq | §8.3 K2/K3 | KW-20, KW-21 |
| qualification και freshness expiry | §8.3 F/Q | KW-25, KW-13 |
| διάκριση διόρθωσης (claim) vs ανάκλησης κλειδιού (root statement) | §2.7 vs §2.9 | KW-35 |
| `invalid_from` + compromise awareness, αναδρομική ακύρωση | §9 | KW-6, KW-14, KW-16 |
| μία κανονική release root, υπογεγραμμένη, δεσμευτική για κάθε inclusion | §5, §8.3 R | KW-33 |
| τοπική επαλήθευση, χωρίς δίκτυο | §6, §8 | KW-2, KW-15 |
| κανένα issuer self-verdict (κλειστό schema) | §1.0, §8.3 βήμα 0 | KW-1, KW-30 |

**Distributed Trust Mesh — επιλεγμένη μορφή (MLTP v3 §10.2, ανάλυση κυριαρχίας
`DOMINANCE-MATRIX.md` D-07 έως D-11):** threshold owner root (FROST-Ed25519 3-of-5)·
HSM-backed delegated release keys σε ≥2 ανεξάρτητες υποδομές· δύο transparency
services με cross-logging· gossip + split-view detection· ≥2 ανεξάρτητοι θεσμικοί
cross-client witnesses· SCITT-compatible Signed Statements/Receipts· έκτακτη και
αναδρομική ανάκληση. **Κανένα blockchain, ZK, VC/DID στρώμα** στον πυρήνα — δεν
κυριαρχούν της απλούστερης εναλλακτικής (D-11).

**Έδρες:** `jws-authority.lisp` + `merkle-authority.lisp` + `hash-authority.lisp`
+ `x509-authority.lisp` + `asn1-der.lisp` + `timestamp-authority.lisp` (REUSE/EXTEND:
Ed25519, RFC 7638, πλήρης RFC-3161)· `authority-v2/` (roles model, witness-quorum
test, ceremony rehearsal: EXTEND)· `deployment/verify/*` (verifiers: EXTEND → MLTP v3)·
**threshold signing, δεύτερο log, cross-client witness registry, SCITT προβολή =
`MISSING`**.

**Φέτες:** VS-11, VS-12. **Βήμα:** 6.

### 4.11 Standards and Interoperability (M6) — R-71 έως R-73

Υποστήριξη **εκπομπής ΚΑΙ επικύρωσης** (η εκπομπή χωρίς επικύρωση δεν μετράει):
`ELI` + `ELI-Impact` (νομοθεσία, σχέσεις επίδρασης)· `ECLI` (νομολογία)· `Akoma
Ntoso` (δομή)· `RDF` + `PROV-O` (προέλευση)· `SHACL` (σχήματα επικύρωσης — έξοδος
που παραβιάζει shape ⇒ δεν δημοσιεύεται)· εφαρμοστέα `LegalRuleML` profiles
(κανόνες — μόνο για norms με `determinacy: mechanical`)· `SCITT` (statements/
receipts)· `OpenAPI` (εκδοχοποιημένο)· versioned `MCP`· canonical `CBOR`/`JSON`
προβολές όπου απαιτείται (MLTP v3 §4.1). **Τα πρότυπα είναι επιφάνειες
διαλειτουργικότητας, όχι ανταγωνιστικές εσωτερικές πηγές αλήθειας** — η πηγή
αλήθειας είναι ο διτεμπορικός γράφος + MLTP v3.

**Έδρες:** `akoma-ntoso-emitter.lisp` (REUSE)· `shacl-validator.lisp` +
`deployment/shapes/eli-shapes.ttl`, `legal-shapes.ttl` (REUSE)· `turtle-parser.lisp`,
`rdfs-inference.lisp`, `sparql-endpoint.lisp`, `corpus-sparql.lisp` (REUSE)·
`deployment/*.ttl` (ontology/identity/provenance: REUSE)· `eu-interop-layer.lisp`
(ELI: EXTEND → ELI-Impact)· `canonical-uris.lisp` (REUSE)· **LegalRuleML emitter =
`MISSING`**· **SCITT projection = `MISSING`**· **OpenAPI = `MISSING`**.

**Μάρτυρες:** Q14, Q38· KW-56 (εκπομπή RDF χωρίς SHACL επικύρωση περνά ⇒ κοκκίνισμα).
**Φέτα:** VS-11. **Βήμα:** 11.

### 4.12 Public App, Website and Conversational Cockpit (L8/L12 · M6/M7) — R-74 έως R-81

**Το δημόσιο προϊόν λειτουργεί ως app:** μία ενέργεια ανοίγει συνομιλία με το
Ίδρυμα· ο χρήστης ρωτά τι ισχύει τώρα ή ιστορικά· επιθεωρεί επίσημες πηγές και
αποδείξεις· βλέπει αβεβαιότητα και κάλυψη· βλέπει ανιχνευμένες αλλαγές και
προτεινόμενες διορθώσεις· περιηγείται νομοθεσία και νομολογία· συγκρίνει εκδόσεις·
επιθεωρεί κανονιστική επίδραση (§4.8)· ακολουθεί γράφους παραπομπών και αυθεντίας
(§4.9). Κάθε νομικός ισχυρισμός της εφαρμογής = `proof-carrying-answer/1` (§4.7)
ή `UNKNOWN` — δεν υπάρχει τρίτη δυνατότητα (Q15).

**Cockpit signed intent (μία έδρα: το πεδίο `cockpit_intent` του public
InstitutionalAct profile, §1.4):**
```
cockpit_intent = { "kind": <"proposal" | "approval" | "rejection" | "revocation-request">,
                   "target": <proposal id | release_root | claim_id>,
                   "actor": <actor-ref/1 με registered kid>, "role": <RBAC role ∈ registry>,
                   "mfa_evidence": <hash του MFA assertion — ποτέ το secret>,
                   "issued_at": { "trusted_time", "anchor" }, "sig": <context "mltp3:cockpit-intent"> }
```
- **ποτέ** δεν δημοσιεύει απευθείας· **ποτέ** δεν παρακάμπτει την proposer-blind
  M5 — ο τύπος απόκρισης του cockpit είναι όψη + intent, όχι release action (η
  σημερινή `/api/publish` capability του `cockpit.lisp` **αφαιρείται ως άμεση
  ενέργεια** και γίνεται `approval` intent στην ουρά της M5 — disposition REPLACE
  για αυτό το capability)·
- απαιτεί **RBAC/MFA** (actor kid + role registry + MFA evidence — `MISSING`)·
- κάθε ενέργεια journaled (L1), επιθεωρήσιμη (review-queue) και ανακλητή (L12).

**Ο δημόσιος ιστότοπος** δημοσιεύει ανθρωπο-αναγνώσιμο δίκαιο και νομολογία **από
το ίδιο canonical release** που καταναλώνουν οι μηχανές (`static-site.lisp` +
census-2: ο ιστότοπος είναι προβολή, ποτέ δεύτερη πηγή).

**Έδρες:** `systems/orchestrator-cli/cockpit.lisp` (`/api/ask`, `/api/pending`,
`/api/decide`, `/api/publish`, `/api/catalog`: EXTEND· `/api/publish` → REPLACE)·
`http-server.lisp` (REUSE)· `review-service.lisp` + `review-queue.lisp` (REUSE)·
`static-site.lisp` (REUSE)· `approval-policy.lisp` + `decisions.lisp` (REUSE)·
`corpus-diff.lisp` (σύγκριση εκδόσεων: REUSE)· **RBAC/MFA = `MISSING`**·
**app shell (conversation-first UI) = `MISSING`**.

**Μάρτυρες:** Q15, Q17, Q20, Q39· KW-39, KW-57 (intent χωρίς MFA evidence γίνεται
δεκτό ⇒ κοκκίνισμα). **Φέτα:** VS-14. **Βήμα:** 12.

### 4.13 Citation Observatory (L9 · M6) — R-82 έως R-84

Συνεχής παρακολούθηση, εντός νομικών και ηθικών ορίων: εισερχόμενες παραπομπές/
σύνδεσμοι προς δημοσιεύσεις του Watchtower· παραπομπές από έρευνα, ΜΜΕ, θεσμούς,
δημόσια έγγραφα· μηχανική/API κατανάλωση (aggregate, χωρίς ταυτοποίηση χρήστη)·
υιοθέτηση providers (μέσω provider attestations — §4.15)· σπασμένοι σύνδεσμοι και
ξεπερασμένες αναφορές· κατάχρηση ή παραπομπή ανακληθέντος υλικού· **συμμόρφωση
providers με το Citation-Bound Verification Profile** (§4.16: ανίχνευση επαληθευμένων
αποτελεσμάτων που κυκλοφορούν χωρίς τη δεσμευμένη παραπομπή ⇒ εισήγηση μη-ανανέωσης/
ανάκλησης `provider-adoption-qualified` και, όπου εφαρμόζεται, ενέργεια API-access).
**Μετρικές παραπομπών δεν συγχέονται ποτέ με νομική ορθότητα ή αυθεντία** — ζουν εκτός MLTP
(δεν είναι claim_type), ως L9 μετρήσεις με typed `UNKNOWN` όταν ο συλλέκτης είναι stub.

**Έδρες:** `ai-citation-strategy.lisp` + `citation-authority.lisp` (collectors:
EXTEND — σήμερα stubs, AS-IS EV-9)· `configs/prometheus-citation.yml` +
`deployment/templates/ai-citation-log.ttl` (REUSE)· **revoked-material citation
detector = `MISSING`**.

**Μάρτυρες:** Q16· KW-58 (stub collector αναφέρεται ως «0 παραπομπές» ⇒ κοκκίνισμα).
**Βήμα:** 13.

### 4.14 Security and Operational Observatory (L10/L11/L12) — R-85 έως R-100

Περιλαμβάνει: supply-chain provenance (in-toto class materials στο census-2, SLSA-class
attestation ανά build)· hermetic και αναπαραγώγιμα builds (Docker hermetic σήμερα,
NixOS L1+ όταν ξεμπλοκάρει)· SBOM (`docker/sbom.json`)· υπογεγραμμένα artifacts
(cosign)· προστατευμένες διαδικασίες release (proposer-blind M5, threshold root,
HSM)· ελάχιστο προνόμιο (M1/M2 χωρίς write στο επίπεδο έκδοσης)· RBAC/MFA· απομόνωση
μυστικών (κλειδιά ποτέ σε repo/CI/crawler host)· συνεχής παρακολούθηση ευπαθειών
(`deps.lock` + SBOM scanning)· ανίχνευση παραποίησης και split-view (MLTP v3 §10)·
backups και disaster recovery (Q19: από PLANE-0 + journal byte-ταυτόσημη
ανακατασκευή)· multi-region ανθεκτικότητα όπου δικαιολογείται (δύο ανεξάρτητες
υποδομές ήδη απαιτούνται για HSM/log — η γεωγραφική διασπορά τους είναι η
δικαιολογημένη μορφή)· δημόσια διαφάνεια συμβάντων/διορθώσεων (incident record ως
`legal-object-correction-or-withdrawal` όπου αφορά αντικείμενο, ή ως δημόσιο L1
γεγονός)· **μετρήσιμα SLOs** για φρεσκάδα (ανά space: `max_staleness`), διαθεσιμότητα
και ανάκαμψη (RTO/RPO ως αριθμοί που ορίζονται στο βήμα 0 από μέτρηση, όχι εδώ —
Q-tests §6 «ψευδής ακρίβεια»).

**CI:** πρέπει να γίνει **γνήσια πράσινο και αναπαραγώγιμο** ΠΡΙΝ γίνει δεκτός
οποιοσδήποτε ισχυρισμός υλοποίησης (AS-IS EV-12: 71 runs, 0 successes). Οι
περιβαλλοντικές αποτυχίες διαχωρίζονται από τις αποτυχίες κώδικα με κωδικό
εξόδου (`BLOCKED` ≠ `FAIL`, Κ-5) — `authority-v2/run-all.sh` ήδη διακρίνει 0/1/3.

**Έδρες:** Dockerfile + `deps.lock` + `docker/sbom.json` + `docker/cosign.pub` +
`scripts/verify-runtime-closure.sh` (REUSE)· `LAWMAX-THREAT-MODEL.md` (EXTEND — Θ3/Θ4
κλείνουν με qualification expiry + revocation checkpoint recency, Θ5 με cross-client
witnesses, Θ9 με pinned root, Θ10 με πλήρη RFC-3161)· `authority-v2/` (proof census,
capture, ceremony rehearsal: EXTEND)· `circuit-breaker.lisp`, `logging.lisp` (REUSE)·
`.github/workflows` (docker-orchestrator, provenance, deploy-corpus: REPLACE μέχρι
πράσινο)· **SLO registry, vulnerability monitoring, DR runbook, public incident
feed = `MISSING`**.

**Μάρτυρες:** Q12, Q17, Q18, Q19, Q23, Q40· KW-5, KW-15, KW-40, KW-47, KW-59 (CI
«πράσινο επειδή δεν έτρεξε» ⇒ κοκκίνισμα). **Φέτες:** VS-12, VS-15. **Βήματα:** 0, 13.

### 4.15 AI-Provider Integration (M6) — R-101 έως R-110

Παρέχει: ελάχιστο ανοιχτό offline verifier (MLTP v3 §8 — SHA-256 για inclusion,
Ed25519/RS256 για υπογραφές, RFC-3161 για χρόνο· LOC-ceiling)· εκδοχοποιημένο
OpenAPI· versioned MCP· λεπτά SDKs (Python, TypeScript, Rust — μόνο περιτύλιγμα
του verifier, χωρίς λογική εμπιστοσύνης)· delta/update feeds (signed deltas ανά
release, RSS/Atom + MLTP bundle)· οδηγίες pinned-root και rotation (ceremony record,
≥2 κανάλια, `seq` μονοτονία)· conformance suite (η δεύτερη υλοποίηση πρέπει να
περνά όλα τα test vectors)· test vectors (`deployment/verify/vectors/`: EXTEND σε
MLTP v3 — θετικά και ΑΡΝΗΤΙΚΑ vectors ανά error name §4.3)· κανόνες caching και
ανάκλησης (cache TTL ≤ `freshness_deadline`· revocation checkpoint ≤
`max_revocation_staleness`· αλλιώς `UNKNOWN`)· **citation-bound** παράδοση (§4.16):
υποχρεωτικά πεδία `citation/1` στα OpenAPI/MCP/SDK σχήματα, default rendering της
διπλής παραπομπής στα επίσημα SDKs, `CitationToken`, conformance vectors με
stripped-citation αρνητικά.

**Ο ελεγκτής (διόρθωση v1.3 §4.1 item 2, RC-15):** επαληθεύει (1) Merkle inclusion
στο `release_root`, (2) υπογραφή του `release_root` και κάθε claim με **delegated**
κλειδί εξουσιοδοτημένο από τον pinned owner root (ποτέ «claims υπογεγραμμένα από το
pinned κλειδί»), (3) αλυσίδα delegation στον αυθεντικοποιημένο χρόνο υπογραφής,
(4) tlog inclusion + consistency + μονοτονία, (5) cross-client witness quorum,
(6) ανάκληση, (7) provenance, (8) qualification, (9) freshness, (10) δέσμευση παραπομπής
για κάθε `CertifiedResult` (MLTP v3 §8.3 βήμα C).

**Provider adoption = ξεχωριστή, ληξιπρόθεσμη qualification** (`provider-adoption-qualified`,
MLTP v3 §3.1) — υπογράφεται ΜΟΝΟ από ≥2 registered providers, ποτέ αυτο-δηλωμένη.

**Έδρες:** `deployment/verify/verify.py`, `verify.mjs`, `verify-release.py`,
`verify-temporal.py`, `verify-authority-bundle.py`, `kernel-verify.lisp` (EXTEND →
MLTP v3)· `deployment/verify/vectors/` (EXTEND)· `mcp-server.lisp` (EXTEND)·
`ai-corpus-dump.lisp` + `ai-ingest-manifest.lisp` + `deployment/templates/ai-ingest-manifest.ttl`
(feeds: EXTEND)· `capability-api.lisp` (REUSE)· **OpenAPI, SDKs, conformance suite,
provider registry = `MISSING`**.

**Μάρτυρες:** Q21, Q22, Q26, Q27, Q28· KW-2, KW-9, KW-31, KW-32, KW-46. **Φέτα:**
VS-11. **Βήματα:** 6, 11, 14.

### 4.16 Citation-Bound Verification Profile (πρώτης τάξης · διευκρίνιση δημιουργού 2026-09-01) — R-119 έως R-124

**Σκοπός:** κάθε πιστοποιημένο αποτέλεσμα API/MCP/SDK φέρει typed αντικείμενο
παραπομπής **μέσα στα υπογεγραμμένα bytes**, ώστε κανένας provider να μην μπορεί να
διατηρήσει έγκυρη υπογραφή Watchtower, κατάσταση `VERIFIED` ή
`provider-adoption-qualified` αφού αφαιρέσει ή αλλοιώσει την παραπομπή.

**Το αντικείμενο (`lawmax/citation/1`, MLTP v3 §2.10) — τουλάχιστον:**
`official_source_uri` · `watchtower_release_uri` · `claim_id` · `certificate_uri` ·
`attribution_text` · `citation_policy_id`. Το πλήρες αντικείμενο καλύπτεται από την
υπογραφή του `CertifiedResult` **και** το `citation_digest` του ζει μέσα στην
υπογεγραμμένη απάντηση. Αφαίρεση ή αλλοίωση ⇒ `citation-unbound` ⇒
**`UNVERIFIED_FOR_ATTRIBUTED_RELIANCE`** (MLTP v3 §8.3 βήμα C).

**Διπλή παραπομπή (υποχρεωτική):** το Κράτος / Εφημερίδα της Κυβερνήσεως /
δικαστήριο ως **de jure εκδότης**· το `LAWMAX OMEGA — THE LEGAL WATCHTOWER OF GREECE`
ως **πηγή της επαληθευμένης μηχανικής αναπαράστασης, ενοποίησης, απόδειξης και
πιστοποίησης**. Ποτέ το Watchtower ως εκδότης δικαίου (MIS-8).

**Μηχανισμοί (όλοι απαιτούμενοι, όλοι στο τεχνικά επιβλητό εύρος):** κανονικά
citation URLs σταθερά ανά διτεμπορική τομή· citation-ready JSON και JSON-LD προβολή·
υπογεγραμμένα `CitationToken`· υποχρεωτικά πεδία παραπομπής στα OpenAPI/MCP/SDK
σχήματα· default rendering στα επίσημα SDKs· conformance test vectors (θετικά +
stripped/altered-citation αρνητικά)· παρακολούθηση συμμόρφωσης providers· citation
observatory (§4.13)· υποβάθμιση `provider-adoption-qualified` (μη-ανανέωση ή
ανάκληση QSR) ή ενέργεια API-access όπου εφαρμόζεται.

**Τίμιο όριο:** το σύστημα δεν μπορεί να εμποδίσει φυσικά τη χρήση αντιγραμμένου
δημόσιου κειμένου χωρίς απόδοση αφού φύγει από τον έλεγχό του. Εγγυάται ότι καμία
**επαληθευμένη** αναπαράσταση δεν επιβιώνει χωρίς τη δεσμευμένη παραπομπή. Εμπορικές
συμφωνίες είναι εξωτερικές και **δεν** αποτελούν αρχιτεκτονική εξάρτηση.

**Έδρες:** MLTP v3 §2.10 (CertifiedResult, citation/1, CitationToken, βήμα C)·
`canonical-uris.lisp` (canonical citation URLs: EXTEND)· `json-emit.lisp` +
`deployment/*.ttl` (JSON-LD προβολή: EXTEND)· `mcp-server.lisp` + OpenAPI + SDKs
(σχήματα/rendering: EXTEND/MISSING)· `deployment/verify/vectors/` (EXTEND)·
`ai-citation-strategy.lisp` + `citation-authority.lisp` (συμμόρφωση providers: EXTEND)·
provider registry + QSR (υποβάθμιση: MLTP v3 §3.1).

**Invariants:** (I-4.16a) κάθε `CertifiedResult` έχει citation μέσα στα signed bytes·
(I-4.16b) stripped/altered citation ⇒ `UNVERIFIED_FOR_ATTRIBUTED_RELIANCE`, ποτέ
`VERIFIED`· (I-4.16c) `attribution_text` περιέχει ΚΑΙ τις δύο παραπομπές· (I-4.16d)
provider χωρίς συμμόρφωση δεν διατηρεί `provider-adoption-qualified`.

**Μάρτυρες:** Q42· KW-62, KW-63. **Φέτα:** VS-11 (επέκταση: stripped citation).
**Βήματα:** 11, 13, 14.

---

## 5. ΕΚΤΕΛΕΣΙΜΗ ΠΛΗΡΟΤΗΤΑ — ΤΙΠΟΤΑ ΣΙΩΠΗΛΑ ΠΑΡΑΛΕΙΜΜΕΝΟ

Το `LAWMAX-CEILING-CROSSWALK.md` (15 επίπεδα) επεκτείνεται σε **πλήρες capability
universe** στο `PUBLIC-OBSERVATORY-CROSSWALK.md §B`, παραγόμενο από: τη δημόσια
αποστολή (MIS-1 έως MIS-10)· τις 12 στρώσεις CPEI· τα διεθνή πρότυπα νομικών
δεδομένων (§4.11)· τις κορυφαίες επίσημες υποδομές (`DOMINANCE-MATRIX.md §B`)· τρέχουσα
έρευνα 2026–2027 (neuro-symbolic, transparency/witnessing, SCITT, bitemporal graphs)·
απειλές ασφάλειας και επιστημικές (`LAWMAX-THREAT-MODEL.md` + Stage A ρίζες)·
λειτουργικές απαιτήσεις κλίμακας κράτους (§4.14)· απαιτήσεις ανθρώπινων και AI
καταναλωτών (§4.12, §4.15).

Κάθε capability έχει **ακριβώς μία** κατάσταση: `HAS_SEAT` | `EXCLUDED_WITH_PROOF`
| `UNKNOWN_WITH_OWNER_AND_DEADLINE`. Κάθε απαίτηση (R-01 έως R-124) έχει πλήρες
ίχνος `Mission → Capability → Requirement → Seat → Interface → Invariant →
Negative Witness → Test → Evidence → Qualification` (`TRACEABILITY-MATRIX.md`).
Απαίτηση με λείποντα κρίκο = μη πλήρης (καταγράφεται ως `UNKNOWN_WITH_OWNER_AND_DEADLINE`,
όχι σιωπηλά)· συστατικό χωρίς ιχνηλατημένη απαίτηση = αδικαιολόγητη πολυπλοκότητα
(disposition `REMOVE` ή `DEFER_PRIVATE`).

---

## 6. ΚΥΡΙΑΡΧΙΑ — ΚΑΜΙΑ ΓΝΩΣΤΗ ΚΑΤΩΤΕΡΗ ΕΠΙΛΟΓΗ

Για κάθε κρίσιμη επιλογή, το `DOMINANCE-MATRIX.md` συγκρίνει πραγματικές εναλλακτικές
σε 12 άξονες (ορθότητα· όρια soundness/completeness· ανεξάρτητη επαληθευσιμότητα·
χρονική πιστότητα· διαλειτουργικότητα· ασφάλεια· ανθεκτικότητα· κλιμάκωση·
αναπαραγωγιμότητα· εξελιξιμότητα· θεσμική διακυβέρνηση· ανθρώπινη κυριαρχία) και
δηλώνει: γιατί επιλέχθηκε, ποιες ισχυρότερες-φαινομενικά εναλλακτικές εξετάστηκαν,
γιατί καθεμία δεν κυριαρχεί, ποιο μελλοντικό τεκμήριο θα διέψευδε την επιλογή.
Κανόνας απόρριψης: αν γνωστή επιλογή είναι όχι χειρότερη σε κάθε κρίσιμο άξονα,
αυστηρά καλύτερη σε έναν, και συμβατή με τα αμετάβλητα αξιώματα ⇒ η επιλεγμένη
απορρίπτεται. Benchmark έναντι EUR-Lex/Cellar, legislation.gov.uk, Légifrance,
Finlex, GovInfo: `DOMINANCE-MATRIX.md §B` (με ρητή δήλωση της βάσης των πηγών).

Οι 12 διατηρημένες κρίσιμες επιλογές: D-01 event-sourced bitemporal graph ως πηγή
αλήθειας· D-02 USC FRBR-class ταυτότητα· D-03 Common Lisp πυρήνας + Rust δεύτερος
compiler· D-04 νευρωνικό επίπεδο εκτός trusted path με closed protocol· D-05
MLTP v3 τρία επίπεδα + Layer 0· D-06 RFC 9162 Merkle + Ed25519 + RFC-3161 επί της
υπογραφής· D-07 threshold owner root· D-08 HSM delegated keys ≤90 ημέρες· D-09 δύο
logs + cross-client witnesses· D-10 SCITT ως προβολή· D-11 απόρριψη blockchain/ZK/
VC-DID στον πυρήνα· D-12 proposer-blind M5 + dual compilers αντί N-version voting.

---

## 7. ANTI-LOOP ΚΑΝΟΝΕΣ — ΔΕΣΜΕΥΤΙΚΟΙ ΑΠΟ ΕΔΩ

1. Καμία ανταγωνιστική «τελική αρχιτεκτονική». 2. Καμία μετονομασία στόχου χωρίς
αλλαγή falsified invariant. 3. Καμία επανεγγραφή κλειστών τμημάτων για ύφος. 4.
Κανένα άνοιγμα κλειστής απόφασης χωρίς νέο τεκμήριο ή συγκεκριμένο counterexample.
5. Κανένα agent swarm πριν υπάρξει ο ενοποιημένος υποψήφιος (υπάρχει: αυτό). 6.
Καμία νέα ολική ανάγνωση repo. 7. Το `output/` και το vendored `third-party/` δεν
είναι αρχιτεκτονικό τεκμήριο εκτός αν συγκεκριμένη αξίωση το απαιτεί. 8. Καμία
αξίωση ολοκλήρωσης λόγω μήκους ή εσωτερικής συνέπειας. 9. Κάθε ανοιχτό στοιχείο
τερματίζει ως resolved | falsified | explicitly unknown | deferred private. 10. Μία
κανονική έδρα ανά έννοια. 11. Ιστορικοί υποψήφιοι μένουν στο μητρώο και ποτέ δεν
ανταγωνίζονται τον τρέχοντα. 12. Καμία νέα έκδοση χωρίς ονομαστικό falsifier.

---

## 8. ΣΥΜΒΟΛΑΙΟ ΕΠΙΚΥΡΩΣΗΣ — ΠΡΟΔΗΛΩΝΕΤΑΙ, ΔΕΝ ΕΚΤΕΛΕΙΤΑΙ

Το πρόγραμμα (πλήρης ορισμός: `PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md §8`):

1. **Completeness pass** — κάθε R-id έχει τα 10 ίχνη· κάθε capability μία κατάσταση.
2. **Dominance/superiority pass** — κάθε D-id: εναλλακτικές, μη-κυριαρχία, falsifier.
3. **Cross-layer integration & contradiction pass** — MLTP v3 ↔ v1.4 ↔ Q ↔ crosswalk ↔ foundations.
4. **Security & epistemic-adversarial pass** — KW-1 έως KW-63 + άγνωστοι άξονες.
5. **Operational national-observatory pass** — census, freshness, DR, SLO, CI.
6. **Independent spec-literal adjudication** — burden on the spec.

**Κριτές:** ετερογενείς οικογένειες μοντέλων (φρέσκα contexts της ίδιας οικογένειας
ΔΕΝ είναι πλήρης ανεξαρτησία), ντετερμινιστικοί αναλυτές (οι audits `.sh`), τυπικά
μοντέλα (TLA+ για K2/K3/V/L1 της MLTP v3 §8.3), εκτελέσιμα counterexamples,
ειδικευμένη ανθρώπινη επιθεώρηση (νομικός για §4.9, κρυπτογράφος για §4.10).

**Κλιμακωτή δαπάνη:** δύο πιλοτικοί κριτές → πύλη ποιότητας/καινοτομίας
(ευρήματα με command+output+digest, ≥1 άγνωστος άξονας) → τέσσερις μόνο αν
απαιτηθεί → οκτώ μόνο αν μένουν ακάλυπτοι άξονες· σκληρά όρια context/tokens ανά
κριτή· καμία διπλή ολική ανάγνωση repo· adjudication μόνο για συγκεκριμένα ευρήματα.

---

## 9. ΕΚΤΕΛΕΣΙΜΕΣ ΚΑΘΕΤΕΣ ΦΕΤΕΣ ΠΡΙΝ ΤΟ FREEZE (προδηλωμένες, `VERTICAL-SLICES.md`)

VS-01 πηγή → receipt → Legal IR → γεγονός → bitemporal state → proof-carrying answer ·
VS-02 άμεση και έμμεση τροποποίηση · VS-03 σύγκρουση δύο επίσημων manifestations ·
VS-04 OCR/layout διαφθορά και ανάκαμψη · VS-05 σύγκρουση οντοτήτων οντολογίας και
αποχή · VS-06 νευρωνικός candidate απορριπτόμενος από συμβολικούς περιορισμούς ·
VS-07 open-textured κανόνας ⇒ interpretive/unknown · VS-08 νομολογιακή αλυσίδα
followed/distinguished/overruled · VS-09 δύο ανεξάρτητοι compilers, ίδια ρίζα ·
VS-10 απόκλιση compilers ⇒ quarantine · VS-11 τοπική επαλήθευση provider (και stripped-citation ⇒ `UNVERIFIED_FOR_ATTRIBUTED_RELIANCE`) · VS-12
rotation, ληγμένη delegation, compromise, αναδρομική ανάκληση · VS-13 ελλείπον
αναμενόμενο ΦΕΚ/δικαστικό αντικείμενο ⇒ αποτυχία κάλυψης · VS-14 cockpit πρόταση
αποτυγχάνει να παρακάμψει την M5 · VS-15 disaster recovery αναπαράγει το ίδιο
qualified release. **Σχεδιαστική αξίωση που δεν αποδεικνύεται με εκτελέσιμη φέτα
δεν είναι freezeable.**

---

## 10. ΚΛΙΜΑΚΑ ΠΟΙΟΤΙΚΗΣ ΕΠΑΡΚΕΙΑΣ — ΠΕΝΤΕ ΛΗΞΙΠΡΟΘΕΣΜΕΣ ΚΑΤΑΣΤΑΣΕΙΣ

| βαθμίδα | v1.4 | υπογράφει (MLTP v3 §3.1) |
|---|---|---|
| `SPEC QUALIFIED` | **ΟΧΙ** — κανένα destruction programme στο v1.4 | ≥1 independent-auditor |
| `IMPLEMENTATION QUALIFIED` | **ΟΧΙ** — καμία υλοποίηση | ≥2 independent-auditors |
| `MISSION GREECE QUALIFIED` | **ΟΧΙ** — `MISSION GREECE-1` ορισμένη, μη εκκινημένη | ≥2 independent-auditors |
| `SECURITY/OPERATIONS QUALIFIED` | **ΟΧΙ** — CI 0 successes (EV-12) | ≥2 independent-auditors |
| `PROVIDER-ADOPTION QUALIFIED` | **ΟΧΙ** — κανένας provider | ≥2 registered providers |

Καμία μόνιμη qualification. **Root Authority** υπάρχει μόνο όσο ΟΛΑ τα απαιτούμενα
τεκμήρια είναι φρέσκα και έγκυρα (QSR ανά βαθμίδα, μη ληγμένα, με έγκυρο
`coverage-and-freshness`)· υποβαθμίζεται **αυτόματα** σε `UNKNOWN`/`UNVERIFIED` όταν
οποιαδήποτε qualification λήξει ή τεκμήριο αποτύχει (MLTP v3 §8.3 F/Q). Οι πρώτες
τέσσερις είναι διαδοχικές κατά την εκκίνηση· όλες συνεχείς και ανακλητές μετά.
**Απόλυτο όριο:** de jure αυθεντία πάντα Εφημερίδα της Κυβερνήσεως και δικαστήρια.

---

## 11. ΣΕΙΡΑ ΥΛΟΠΟΙΗΣΗΣ ΜΕΤΑ ΤΟ FREEZE (δεν υλοποιείται τώρα — `IMPLEMENTATION-SEQUENCE.md`)

0 καθαρή αναπαραγώγιμη βάση + γνήσια πράσινο CI · 1 εθνική απογραφή πηγών/δικαστηρίων
+ coverage ledger · 2 acquisition, ταυτότητα, provenance, αυθεντικότητα · 3 typed
Legal IR + bitemporal event store · 4 πρώτος ντετερμινιστικός Legal Compiler · 5
δεύτερος ανεξάρτητος compiler + differential verification · 6 MLTP v3, offline verifier,
distributed Trust Mesh · 7 πολυτροπική acquisition + ontology-alignment plane · 8
νευρο-συμβολικός συλλογισμός + επιστημικό τείχος · 9 πλήρες jurisprudence-evolution
plane · 10 National Legal Digital Twin + impact engine · 11 proof-carrying query
API/MCP/SDK · 12 ιστότοπος, cockpit, publication workflow · 13 citation + security
observatories · 14 mission-scale qualification + provider adoption.
**Refactoring αρχίζει μόνο μετά από ρητή έγκριση του παγωμένου δημόσιου στόχου από
τον δημιουργό.**

---

## 12. ΤΙ ΔΕΝ ΕΧΕΙ ΓΙΝΕΙ / ΑΝΟΙΧΤΑ `UNKNOWN` ΜΕ OWNER ΚΑΙ ΠΡΟΘΕΣΜΙΑ

| # | ανοιχτό | κατάσταση | owner | προθεσμία (σχετική) |
|---|---|---|---|---|
| U-1 | Αριθμητικά κατώφλια (πιστότητα OCR/εξαγωγής, latency, SLO RTO/RPO, `max_staleness` ανά space) | `UNKNOWN_WITH_OWNER_AND_DEADLINE` — ψευδής ακρίβεια αν οριστούν τώρα | δημιουργός + μέτρηση βήματος 0/1 | πριν την έξοδο του βήματος 1 |
| U-2 | Ταυτότητα και απομόνωση των independent auditors, reviewers, cross-client witnesses, providers (τα registries) | `UNKNOWN_WITH_OWNER_AND_DEADLINE` | δημιουργός (θεσμικές συμφωνίες) | πριν το βήμα 6 |
| U-3 | Νομικά ζητήματα άδειας/πνευματικών δικαιωμάτων πλήρων κειμένων νομολογίας τρίτων και δευτερογενούς θεωρίας (Q25) | `UNKNOWN_WITH_OWNER_AND_DEADLINE` | δημιουργός (νομική γνωμοδότηση) | πριν το βήμα 9 |
| U-4 | Επαλήθευση του benchmark πίνακα έναντι ζωντανών πρωτογενών τεχνικών σελίδων των 5 επίσημων υποδομών (η δικτυακή έξοδος προς τις σελίδες τους ήταν αποκλεισμένη κατά τη σύνταξη — `DOMINANCE-MATRIX.md §B` δηλώνει τη βάση) | `UNKNOWN_WITH_OWNER_AND_DEADLINE` | δημιουργός ή validation pass 2 | πριν το validation pass 2 |
| U-5 | Επιλογή Rust vs OCaml για τον δεύτερο compiler (προτίμηση Rust δηλωμένη, D-03) | `UNKNOWN_WITH_OWNER_AND_DEADLINE` | δημιουργός | πριν το βήμα 5 |
| U-6 | Το held-out σύνολο του Q04 και ο ορισμός του | `UNKNOWN_WITH_OWNER_AND_DEADLINE` | δημιουργός | πριν το βήμα 7 |
| U-7 | Διαθεσιμότητα/νομιμότητα δημοσίευσης αποφάσεων δικαστηρίων ουσίας (ποια δικαστήρια εκδίδουν νομίμως δημοσιεύσιμες αποφάσεις) — ορίζει το μέγεθος του census space | `UNKNOWN_WITH_OWNER_AND_DEADLINE` | δημιουργός + census βήμα 1 | πριν την έξοδο του βήματος 1 |
| U-8 | Τα 6 REPORTED / NOT REPRODUCIBLE AS-IS (R-1 έως R-6 του manifest) | παραμένουν REPORTED μέχρι εκτελέσιμο τεστ | βήμα 0 | έξοδος βήματος 0 |

Επιπλέον, ρητά: κανένα destruction programme στο v1.4· καμία υλοποίηση· καμία
βαθμίδα· MISSION GREECE-1 μη εκκινημένη· P0 υπερ-ισχυρισμοί (`PRIMARY_SEMANTIC_AUTHORITY`,
AS-IS EV-11) καταγεγραμμένοι, μη διορθωμένοι (design-only).

---

## 13. ΔΙΑΔΙΚΑΣΙΑ

Δεν ζητείται έγκριση υλοποίησης. Επόμενο βήμα, **μόνο** με ρητή εντολή δημιουργού:
το validation programme §8 (πάσα 1–6) πάνω στο v1.4 με τα προδηλωμένα KW-1 έως
KW-63. Μόνο μετά την επιβίωσή του τίθεται ζήτημα `SPEC QUALIFIED`. Freeze = ρητό
«εγκρίνω freeze target» του δημιουργού μετά από επιβίωση ΚΑΙ 15 εκτελέσιμες φέτες.
Κανένα έγγραφο δεν ονομάζει το v1.4 canonical πριν από αυτό.
