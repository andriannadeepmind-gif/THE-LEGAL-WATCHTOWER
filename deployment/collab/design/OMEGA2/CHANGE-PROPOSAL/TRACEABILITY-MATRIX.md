# TRACEABILITY MATRIX — Mission → Capability → Requirement → Seat → Interface → Invariant → Negative Witness → Test → Evidence → Qualification

**Έδρα (μία):** η ιχνηλασιμότητα κάθε απαίτησης του `CHANGE-PROPOSAL-v1.4.md §4`
(R-01 έως R-124). Κάθε γραμμή έχει και τους δέκα κρίκους· γραμμή με κρίκο
`UNKNOWN(U-n)` **δεν είναι πλήρης** και εμφανίζεται ως `UNKNOWN_WITH_OWNER_AND_DEADLINE`
στο `PUBLIC-OBSERVATORY-CROSSWALK.md §B.11`. Design only — τα «Evidence» είναι το
**είδος** τεκμηρίου που θα παραχθεί, όχι ισχυρισμός ότι υπάρχει.

Συντομογραφίες: MIS = v1.4 §0· CAP = crosswalk §B· Seat = αρχείο/§ (crosswalk §A)·
Interface = τύπος/API/claim· Invariant = v1.4 I-ids ή MLTP v3 §· Witness = Q-tests §7
KW ή αρνητικός μάρτυρας οικογένειας· Test = Q οικογένεια / VS φέτα· Evidence = artifact·
Qualification = βαθμίδα στην οποία η γραμμή πρέπει να είναι πράσινη (S = SPEC,
I = IMPLEMENTATION, M = MISSION GREECE, O = SECURITY/OPERATIONS, P = PROVIDER-ADOPTION).

## §4.1 National Legal Census and Source Radar

| R | Mission | CAP | Requirement | Seat | Interface | Invariant | Negative witness | Test | Evidence | Qual |
|---|---|---|---|---|---|---|---|---|---|---|
| R-01 | MIS-2 | CAP-02 | κάθε τεύχος/σειρά ΦΕΚ στο σύμπαν | `legislation-ingestion.lisp` + census snapshot | census space `gr/gazette/<series>` | I-4.1a | KW-48 | Q01, Q29 / VS-13 | census snapshot + ledger root | I |
| R-02 | MIS-2 | CAP-02 | Σύνταγμα, νόμοι, κώδικες, τροποποιήσεις | ίδιο | space `gr/statute` | I-4.1a | KW-48 | Q01, Q05 | ledger inclusion proofs | I |
| R-03 | MIS-2 | CAP-02 | προεδρικά διατάγματα | ίδιο | space `gr/pd` | I-4.1a | KW-48 | Q01 | ledger | I |
| R-04 | MIS-2 | CAP-02 | κανονιστικές/υπουργικές πράξεις | ίδιο + Διαύγεια κανάλι | space `gr/regulatory` | I-4.1a | KW-48 | Q01 | ledger | I |
| R-05 | MIS-2 | CAP-02 | πράξεις ανεξάρτητων αρχών | ίδιο | space `gr/independent-authority` | I-4.1a | KW-48 | Q01 | ledger | I |
| R-06 | MIS-2 | CAP-02, CAP-46 | εφαρμοστέα ενωσιακή νομοθεσία + μεταφορά | `corpus-eu-links.lisp` | space `eu/applicable` + EU-TRANSPOSITION events | I-4.1a, I-4.5d | KW-48, KW-51 | Q01, Q08 | ledger + rel1 records | I |
| R-07 | MIS-2 | CAP-02, CAP-46 | ΔΕΕ/ΕΔΔΑ υλικό που επηρεάζει την ελληνική κατάσταση | `legal-decisions.lisp` | space `eu/cjeu`, `coe/echr` | I-4.1a | KW-48 | Q01, Q07 | ledger | I |
| R-08 | MIS-2, MIS-4 | CAP-02 | όλα τα δικαστήρια, όλες οι νομίμως δημοσιεύσιμες αποφάσεις | `decisions.lisp` (EXTEND) | space `gr/court/<court>` | I-4.1a | KW-48 | Q01, Q07 / VS-13 | ledger· U-7 | I (U-7) |
| R-09 | MIS-2 | CAP-02, CAP-129 | αιτιολογικές εκθέσεις, κοινοβουλευτικό, προπαρασκευαστικά | census space `gr/preparatory` | space + `:legal-purpose` γείωση | I-4.1a | KW-48 | Q01 | ledger | I |
| R-10 | MIS-7 | CAP-07 | εγκύκλιοι/οδηγίες ρητά μη-δεσμευτικές | space attribute `binding:false` | typed space | I-4.1a | Q29 witness: εγκύκλιος ως δεσμευτική ⇒ κοκκίνισμα | Q29 | census snapshot | I |
| R-11 | MIS-7, MIS-8 | CAP-07 | θεωρία μόνο νόμιμη/αδειοδοτημένη, `authoritative:false` | space attribute + U-3 | typed space | I-4.1a | Q29 witness | Q29, Q25 | άδεια + snapshot | I (U-3) |
| R-12 | MIS-2 | CAP-03, CAP-04, CAP-05 | ανά αντικείμενο: state, authority, channel, freshness budget, gap reason, retry/escalation, signed evidence | ledger + `coverage-and-freshness` | MLTP v3 §2.4 | I-4.1a, I-4.1c | KW-48, KW-25 | Q01, Q02, Q29 / VS-13 | signed claim + inclusion | I |
| R-13 | MIS-2, MIS-7 | CAP-01, CAP-06 | «τα πάντα» μόνο έναντι δηλωμένου census· αδιαθέσιμο ρητά απόν | census snapshot + auditor re-enumeration | `universe_declaration_ref` | I-4.1b, I-4.1d | `coverage-not-total` witness (MLTP §8.3 P) | Q29 / VS-13 | δύο απαριθμήσεις + διαφορά | M |

## §4.2 Multimodal Acquisition and Source Authenticity

| R | Mission | CAP | Requirement | Seat | Interface | Invariant | Negative witness | Test | Evidence | Qual |
|---|---|---|---|---|---|---|---|---|---|---|
| R-14 | MIS-1 | CAP-09 | XML/HTML | `document-fetch.lisp` | acquisition-receipt/1 | I-4.2b | Q03 (α) | Q03 / VS-01 | receipt + digest | I |
| R-15 | MIS-1 | CAP-10 | native PDF | `pdf-authority.lisp` | extraction-receipt/2 | I-4.2b | Q04 witness (tool pin) | Q04 | byte-ταυτόσημη έξοδος | I |
| R-16 | MIS-1 | CAP-11 | σαρωμένα PDF/εικόνες | neural OCR → `ocr-text` candidate | neural-candidate/1 | I-4.3b | KW-49 | Q30 / VS-04 | held-out σφάλμα (U-6) | I (U-6) |
| R-17 | MIS-1 | CAP-12 | σελιδοποίηση | `layout-types.lisp` | layout graph | I-4.2b | Q04 | Q30 / VS-04 | validation report | I |
| R-18 | MIS-1 | CAP-12 | πίνακες και παραρτήματα | `typographic-classifier.lisp` (EXTEND) | logical blocks | I-4.2b | Q30 witness: παράρτημα χαμένο σιωπηλά ⇒ κοκκίνισμα | Q30 | block census | I |
| R-19 | MIS-1 | CAP-13 | υπογραφές και σφραγίδες | `x509-authority.lisp` + authority-proof/2 | `official_signature` evidence | I-4.2c | Q30 witness: S0 ως S3 ⇒ κοκκίνισμα | Q03, Q30 | signer cert chain | I |
| R-20 | MIS-1 | CAP-14 | μεταδεδομένα | USC §1.3 manifestation | `lsm1:` | I-4.2b | Q13 (α) | Q13 | manifestation records | I |
| R-21 | MIS-1 | CAP-15 | επίσημο οπτικοακουστικό | media-verification/1 | transcript manifestation | I-4.2b | Q30 witness | Q30 | media record | I |
| R-22 | MIS-1 | CAP-16 | πολλαπλά manifestations του ίδιου work | USC §1.1–§1.3 | `lsw1/lse1/lsm1` | I-4.2b | Q24 | Q24 / VS-03 | ids | I |
| R-23 | MIS-1 | CAP-17 έως CAP-21 | USC ταυτότητα + registry + authority-proof + receipt + custody + χρόνος + divergence· timestamp ≠ αρχή | `legal-identity.lisp`, `corpus-provenance.lisp`, MLTP v3 §2.1 | `source-authenticity` claim | I-4.2a, I-4.2c, I-4.2d | KW-4, KW-26, KW-27, KW-44, KW-45 | Q03, Q07, Q13 / VS-01, VS-03 | claim + registry inclusion + TSR | I |

## §4.3 Neuro-Symbolic Plane

| R | Mission | CAP | Requirement | Seat | Interface | Invariant | Negative witness | Test | Evidence | Qual |
|---|---|---|---|---|---|---|---|---|---|---|
| R-24 | MIS-1, MIS-7 | CAP-23 έως CAP-29, CAP-38 | νευρωνικές εργασίες (8) | εξωτερικό runtime + `legal-extraction-verify.lisp` | neural-task/1 → neural-candidate/1 | I-4.3b, I-4.3c | KW-49 | Q31 / VS-04, VS-05, VS-06 | candidates + provenance | I |
| R-25 | MIS-1 | CAP-22 | typed candidate πεδία (anchors, id, alternatives, uncertainty, evidence, provenance) | v1.4 §4.3 σχήμα | neural-candidate/1 | I-4.3b, I-4.3c | KW-49 | Q31 | schema validation log | S→I |
| R-26 | MIS-1, MIS-8 | CAP-30 | neural never-list (6) | `write-authority.lisp` + Σύνταγμα | κανένα κλειδί/write authority | I-4.3a | Q09 witness (τύπος), KW-7 | Q09, Q31 / VS-06 | gate output | S→I |
| R-27 | MIS-1 | CAP-31 έως CAP-36 | συμβολικές εργασίες (8) | inference/deontic/event/dialectic seats | Legal IR | I-4.3d | Q10, Q32 | Q10, Q32 / VS-07 | proof objects | I |
| R-28 | MIS-7 | CAP-37 | interpretive/discretionary/underdetermined typed | `legal-ast.lisp` `norm.determinacy` | `UNKNOWN(interpretive)` | I-4.3d | KW-50 | Q32 / VS-07 | typed answer | I |
| R-29 | MIS-1 | CAP-22 | επιστημικό τείχος = closed typed protocol | `safe-read.lisp` | neural-candidate/1 μόνο | I-4.3a | Q31 witness | Q31 | journal | S→I |
| R-30 | MIS-1 | CAP-22 | κανένα ελεύθερο κείμενο στο trusted path | κλειστό σχήμα | — | I-4.3a | Q31 witness (free text ⇒ δεν μεταγλωττίζεται) | Q31 | schema | S→I |

## §4.4 Language and Runtime Boundary

| R | Mission | CAP | Requirement | Seat | Interface | Invariant | Negative witness | Test | Evidence | Qual |
|---|---|---|---|---|---|---|---|---|---|---|
| R-31 | MIS-1 | CAP-39 | Common Lisp κανονικός πυρήνας για IR/οντολογία/συλλογισμό/proof/InstitutionalAct/governance/compiler | `systems/orchestrator-*` | — | Σύνταγμα | Q33 witness: trusted λογική εκτός πυρήνα ⇒ κόκκινη πύλη | Q33 | component manifest | S→I |
| R-32 | MIS-1 | CAP-40 | νευρωνικό runtime εξωτερικό (Python/PyTorch/ONNX ή ανώτερο) | v1.4 §4.4 | neural-task/1 | I-4.3a | Q33 | Q33 / VS-06 | runtime manifest | I |
| R-33 | MIS-9 | CAP-41 | δεύτερος compiler σε άλλη γλώσσα/runtime (Rust προτιμώμενο) | v1.4 §4.6 | compiler-attestation | MLTP v3 §8.3 R4 | KW-52 | Q34 / VS-09 | δύο attestations | I (U-5) |
| R-34 | MIS-1 | CAP-22 | closed versioned typed protocol | v1.4 §4.4 | neural-task/1, neural-candidate/1 | I-4.3a | Q31 | Q31 | schema version | S→I |

## §4.5 Bitemporal Digital Twin

| R | Mission | CAP | Requirement | Seat | Interface | Invariant | Negative witness | Test | Evidence | Qual |
|---|---|---|---|---|---|---|---|---|---|---|
| R-35 | MIS-3 | CAP-42 | event-sourced bitemporal graph valid × known | `version-graph.lisp` + `journal.lisp` | events + snapshot-at | I-4.5a | Q06 witness (KT5) | Q06 / VS-01 | replay log | I |
| R-36 | MIS-3 | CAP-43, CAP-46, CAP-47 | 15 τύποι γεγονότων | v1.4 §4.5 | event taxonomy | I-4.5c, I-4.5d | KW-51, Q08 witness (απόφαση τροποποιεί ⇒ δεν μεταγλωττίζεται) | Q05, Q08 / VS-02 | typed events | I |
| R-37 | MIS-3 | CAP-44 | τι ίσχυε σε valid_time | snapshot-at | `(valid_at, known_at)` | I-4.5a | Q06 | Q06 | προβολή | I |
| R-38 | MIS-3 | CAP-45 | τι ήξερε σε known_time | recorded-from predicate | ίδιο | I-4.5b | Q06 (KT5) | Q06 | προβολή | I |

## §4.6 Dual Independent Legal Compilers

| R | Mission | CAP | Requirement | Seat | Interface | Invariant | Negative witness | Test | Evidence | Qual |
|---|---|---|---|---|---|---|---|---|---|---|
| R-39 | MIS-9 | CAP-48 | χωριστές υλοποιήσεις και runtimes | Lisp A + Rust B | ίδιο journal | R4 | KW-52 | Q34 / VS-09 | attestations | I |
| R-40 | MIS-1 | CAP-48 | ανεξάρτητα παραγόμενες legal-state ρίζες | καθένας | `legal_state_root` | R4 | KW-52 | Q34 / VS-09 | ρίζες | I |
| R-41 | MIS-1 | CAP-49 | σύγκριση ριζών και κρίσιμων προβολών | `release-gate.lisp` | `projection_roots` | R4 | Q34 witness | Q34 / VS-10 | diff report | I |
| R-42 | MIS-7 | CAP-49 | αυτόματη καραντίνα σε απόκλιση | `release-gate.lisp` | `compiler-divergence` | R4 | Q34 witness: απόκλιση ⇒ release ⇒ κοκκίνισμα | Q34 / VS-10 | QUARANTINED record | I |
| R-43 | MIS-1 | CAP-50 | κανένας compiler πιστοποιεί τον εαυτό του | χωριστά delegated κλειδιά | compiler-attestation | R4 | KW-52 | Q34 | delegation scope | I |

## §4.7 Proof-Carrying Query Engine

| R | Mission | CAP | Requirement | Seat | Interface | Invariant | Negative witness | Test | Evidence | Qual |
|---|---|---|---|---|---|---|---|---|---|---|
| R-44 | MIS-1, MIS-5 | CAP-51, CAP-52 | 16 πεδία απάντησης (§4.7, μετά τη διευκρίνιση) | `legal-qa.lisp` + v1.4 §4.7 | proof-carrying-answer/1 | I-4.3d | KW-53 | Q35 / VS-01, VS-11 | answer objects | I |
| R-45 | MIS-5 | CAP-53 | τοπική επαλήθευση από provider | MLTP v3 §8 | TrustBundle | §8.3 | KW-2, KW-15 | Q22, Q27 / VS-11 | receipts | I→P |
| R-46 | MIS-7 | CAP-54 | χωρίς έγκυρο φρέσκο τεκμήριο ⇒ UNKNOWN/CONFLICTING/UNVERIFIED | MLTP v3 §7 | result sum | §4.4 | Q27 witness | Q27, Q35 | receipts | I→M |
| R-47 | MIS-7 | CAP-54 | ποτέ απάντηση χωρίς προσδιορισμό | v1.4 §4.7 | τύπος επιστροφής | — | Q14 witness (silent default) | Q14, Q35 | API schema | I |

## §4.8 Public Normative-Impact Simulator

| R | Mission | CAP | Requirement | Seat | Interface | Invariant | Negative witness | Test | Evidence | Qual |
|---|---|---|---|---|---|---|---|---|---|---|
| R-48 | MIS-3 | CAP-55 | 6 corpus-wide ερωτήματα | `graph-reasoning.lisp` | normative-impact-projection | I-4.8a | Q36 witness (μη επαναπαίξιμο ⇒ κοκκίνισμα) | Q36 / VS-02 | replay manifest | I |
| R-49 | MIS-10 | CAP-55 | δημόσιος προσομοιωτής, όχι στρατηγική υπόθεσης | MLTP v3 §2.8 τύπος | — | I-4.8b | KW-54 | Q20, Q36 | schema | S→I |
| R-50 | MIS-5 | CAP-56 | ELI-Impact επαναχρησιμοποίηση | `eu-interop-layer.lisp` | ELI-Impact RDF | — | Q38 | Q38 | SHACL report | I |

## §4.9 Jurisprudence Evolution Plane

| R | Mission | CAP | Requirement | Seat | Interface | Invariant | Negative witness | Test | Evidence | Qual |
|---|---|---|---|---|---|---|---|---|---|---|
| R-51 | MIS-4 | CAP-57, CAP-58, CAP-60, CAP-62 | 15 πεδία ανά απόφαση | MLTP v3 §2.5/§2.6 + `legal-decisions.lisp` | claims | — | KW-7, KW-36, KW-44 | Q07, Q37 / VS-08 | claims | I |
| R-52 | MIS-4, MIS-7 | CAP-59, CAP-63 | τέσσερις χωριστές τάξεις | v1.4 §4.9 πίνακας | 4 τύποι | — | KW-55, Q09 | Q37 | ταξινομημένα records | S→I |
| R-53 | MIS-4 | CAP-61 | later treatment vocabulary (7) | USC §6.3 + events | LATER-TREATMENT | I-4.5d | KW-55 | Q08, Q37 / VS-08 | rel1 records | I |
| R-54 | MIS-4 | CAP-61 | διτεμπορικός line-of-authority γράφος | `version-graph.lisp` (EXTEND) | line ids | I-4.5a | Q37 witness | Q37 / VS-08 | γράφος | I |
| R-55 | MIS-7 | CAP-61 | outliers και ανεπίλυτες διασπάσεις typed | `line-split` uncertainty | USC §8 | — | Q10 witness | Q37 | uncertainty records | I |
| R-56 | MIS-8 | CAP-60 | AI ποτέ αυτόματα θεσμικό ratio | MLTP v3 §8.3 J | reviewer_adoption_act | — | KW-7, KW-36 | Q37 | adoption acts | S→I |

## §4.10 MLTP v3 and Distributed Trust Mesh

| R | Mission | CAP | Requirement | Seat | Interface | Invariant | Negative witness | Test | Evidence | Qual |
|---|---|---|---|---|---|---|---|---|---|---|
| R-57 | MIS-1 | CAP-64 | τρία επίπεδα + Layer 0 | MLTP v3 §0 | IssuedClaim/TrustBundle/VerificationReceipt | — | KW-1, KW-30 | Q21 | receipts | S→I |
| R-58 | MIS-1 | CAP-65 | typed profiles | MLTP v3 §1.1, §2 | `schema_id` | — | KW-34, KW-43 | Q21 (γ) | schema | S→I |
| R-59 | MIS-1 | CAP-66 | πλήρης δέσμευση υπογραφής | MLTP v3 §1.2 | signed_fields | — | KW-17 | Q22 / VS-11 | vectors | S→I |
| R-60 | MIS-1 | CAP-67 | ανεξάρτητα υπογεγραμμένο QSR | MLTP v3 §3 | QualificationStateRecord | — | KW-12, KW-22, KW-23, KW-24 | Q21, Q28 | QSR records | S→I |
| R-61 | MIS-3 | CAP-68 | αυθεντικοποιημένος χρόνος | MLTP v3 §1.3, §8.3 T | time_evidence | — | KW-19 | Q23 / VS-12 | TSR bytes | S→I |
| R-62 | MIS-1 | CAP-69 | delegation έναντι `t_sig` | MLTP v3 §8.3 K2/K3 | DelegationStatement | — | KW-10, KW-20, KW-21 | Q23 / VS-12 | vectors | S→I |
| R-63 | MIS-7 | CAP-70 | qualification/freshness expiry | MLTP v3 §8.3 F/Q | `expired`, `stale` | — | KW-13, KW-25 | Q28 | receipts | S→M |
| R-64 | MIS-1 | CAP-71 | διόρθωση vs ανάκληση κλειδιού χωριστά | MLTP v3 §2.7/§2.9 | δύο τύποι | — | KW-35 | Q26 | records | S→I |
| R-65 | MIS-1 | CAP-72 | `invalid_from` + compromise awareness | MLTP v3 §9 | RevocationStatement | — | KW-6, KW-14, KW-16 | Q23, Q26 / VS-12 | vectors | S→I |
| R-66 | MIS-1 | CAP-73 | μία κανονική release root | MLTP v3 §5 | ReleaseRootSignature | — | KW-33 | Q12, Q22 | vectors | S→I |
| R-67 | MIS-5 | CAP-74 | τοπική επαλήθευση | MLTP v3 §6, §8 | TrustBundle | — | KW-15 | Q22 / VS-11 | receipts | I→P |
| R-68 | MIS-1 | CAP-75 | κανένα issuer self-verdict | MLTP v3 §1.0, §8.3 βήμα 0 | κλειστό schema | — | KW-1, KW-30 | Q21 (α) | schema | S→I |
| R-69 | MIS-9 | CAP-76 έως CAP-82 | trust mesh (threshold, HSM, 2 logs, cross-logging, gossip, witnesses, SCITT, έκτακτη ανάκληση) | MLTP v3 §10 | SignedCheckpoint, Receipts | — | KW-5, KW-40, KW-47 | Q23, Q40 / VS-12 | ceremony records, checkpoints | O |
| R-70 | MIS-9 | CAP-131 έως CAP-133 | κανένα «μοδάτο» μηχανισμός χωρίς κυριαρχία | `DOMINANCE-MATRIX.md` D-11 | — | — | pass 2 witness (εναλλακτική που κυριαρχεί ⇒ απόρριψη επιλογής) | validation pass 2 | dominance record | S |

## §4.11 Standards and Interoperability

| R | Mission | CAP | Requirement | Seat | Interface | Invariant | Negative witness | Test | Evidence | Qual |
|---|---|---|---|---|---|---|---|---|---|---|
| R-71 | MIS-5 | CAP-83 έως CAP-85 | ELI, ELI-Impact, ECLI, AKN, RDF, PROV-O, SHACL, LegalRuleML, SCITT, OpenAPI, MCP, CBOR/JSON | crosswalk §B.6 έδρες | εξαγωγές | — | KW-56 | Q14, Q38 / VS-11 | validation reports | I |
| R-72 | MIS-1 | CAP-83 | εκπομπή ΚΑΙ επικύρωση | `shacl-validator.lisp` + shapes | SHACL | — | Q14 witness (SHACL παραβίαση) | Q38 | report | I |
| R-73 | MIS-1 | CAP-86 | πρότυπα ≠ πηγή αλήθειας | v1.4 §4.11 | — | — | Q38 witness: RDF ως πηγή γεγονότος ⇒ κοκκίνισμα | Q38 | αρχή | S |

## §4.12 App, Website, Cockpit

| R | Mission | CAP | Requirement | Seat | Interface | Invariant | Negative witness | Test | Evidence | Qual |
|---|---|---|---|---|---|---|---|---|---|---|
| R-74 | MIS-6 | CAP-87 | μία ενέργεια ⇒ συνομιλία | `cockpit.lisp` | `/api/ask` | — | Q15 (α) | Q15 / VS-14 | UI + answers | I→M |
| R-75 | MIS-6, MIS-3 | CAP-87 | τι ισχύει τώρα/ιστορικά | `cognition-legal.lisp` | `(valid_at, known_at)` | I-4.5a | Q06 | Q15 | answers | I |
| R-76 | MIS-6, MIS-7 | CAP-88 | πηγές, αποδείξεις, αβεβαιότητα, κάλυψη, αλλαγές, διορθώσεις | proof-carrying answer + `/api/pending` | όψεις | — | Q15 (α) | Q15 | screenshots + answers | I |
| R-77 | MIS-6 | CAP-89 | περιήγηση, σύγκριση, impact, γράφοι | `static-site.lisp` + `corpus-diff.lisp` | όψεις | ιστότοπος = προβολή του ίδιου release (§4.12) | Q36 witness· όψη που δεν ανάγεται στο canonical release ⇒ κοκκίνισμα | Q15, Q36 | site snapshot ↔ release digest σύγκριση | I |
| R-78 | MIS-10, MIS-1 | CAP-90 | signed intent, ποτέ publish, ποτέ παράκαμψη M5 | `cockpit_intent` + M5 | InstitutionalAct public | — | KW-39, Q15 (β)(γ) | Q15 / VS-14 | intent records | S→I |
| R-79 | MIS-9 | CAP-91 | RBAC/MFA | `review-service.lisp` + role registry | mfa_evidence | — | KW-57 | Q17, Q39 | auth log | I→O |
| R-80 | MIS-9 | CAP-92 | κάθε ενέργεια logged/reviewable/revocable | L1 + review-queue + L12 | journal | — | Q39 witness (ενέργεια χωρίς journal ⇒ κοκκίνισμα) | Q39 | journal | I |
| R-81 | MIS-6, MIS-1 | CAP-93 | ιστότοπος από το ίδιο canonical release | `static-site.lisp` + census-2 | προβολή | — | Q12 witness (ιστότοπος ≠ release ⇒ κοκκίνισμα) | Q12, Q15 | digests | I |

## §4.13 Citation Observatory

| R | Mission | CAP | Requirement | Seat | Interface | Invariant | Negative witness | Test | Evidence | Qual |
|---|---|---|---|---|---|---|---|---|---|---|
| R-82 | MIS-5, MIS-6 | CAP-94, CAP-95 | 6 ρεύματα παρακολούθησης | `ai-citation-strategy.lisp`, `citation-authority.lisp` | metrics | — | KW-58 | Q16 | measurements ή typed UNKNOWN | I |
| R-83 | MIS-10 | CAP-94 | νομικά/ηθικά όρια, καμία ιδιωτική παρατήρηση | Q16 κριτήριο | aggregate μόνο | — | Q16 witness (πεδίο ταυτοποίησης ⇒ κοκκίνισμα) | Q16, Q20 | schema | S→I |
| R-84 | MIS-8 | CAP-96 | μετρικές ≠ ορθότητα/αυθεντία | v1.4 §4.13 | εκτός MLTP | — | Q16 | Q16 | αρχή | S |

## §4.14 Security and Operational Observatory

| R | Mission | CAP | Requirement | Seat | Interface | Invariant | Negative witness | Test | Evidence | Qual |
|---|---|---|---|---|---|---|---|---|---|---|
| R-85 | MIS-9 | CAP-97 | supply-chain provenance | census-2 materials + CI | in-toto/SLSA attestations | — | Q18 witness | Q18 | attestations | O |
| R-86 | MIS-9 | CAP-98, CAP-128 | hermetic αναπαραγώγιμα builds | Dockerfile + deps.lock (+ NixOS) | — | — | Q12 witness (byte drift) | Q12, Q19 / VS-15 | digests | O |
| R-87 | MIS-9 | CAP-99 | SBOM | `docker/sbom.json` | SPDX/CycloneDX | — | Q40 witness | Q40 | SBOM | O |
| R-88 | MIS-9 | CAP-99 | υπογεγραμμένα artifacts | cosign | signatures | — | Q12 | Q12 | signatures | O |
| R-89 | MIS-9 | CAP-100 | προστατευμένες διαδικασίες release | M5 + threshold/HSM | — | — | KW-52, Q17 | Q17, Q23 | ceremony/audit trail | O |
| R-90 | MIS-9 | CAP-101 | ελάχιστο προνόμιο | trust boundaries | — | — | Q17 witness (M1 γράφει release ⇒ άρνηση) | Q17 | policy + test | O |
| R-91 | MIS-9 | CAP-102 | RBAC/MFA | = R-79 | — | — | KW-57 | Q17, Q39 | auth log | O |
| R-92 | MIS-9 | CAP-101 | απομόνωση μυστικών | `keys/` custody, HSM | — | — | Q17 | Q17, Q40 | custody record | O |
| R-93 | MIS-9 | CAP-103 | συνεχής παρακολούθηση ευπαθειών | SBOM scan | — | — | Q40 witness | Q40 | scan reports | O |
| R-94 | MIS-9 | CAP-104 | tamper + split-view detection | MLTP v3 §8.3 L | checkpoints | — | KW-5, KW-40, KW-47 | Q23, Q40 / VS-12 | drill record | O |
| R-95 | MIS-9 | CAP-105 | backups + DR | PLANE-0 + journal replay | — | — | Q19 witness | Q19 / VS-15 | replay digests | O |
| R-96 | MIS-9 | CAP-106 | multi-region όπου δικαιολογείται | δύο υποδομές | — | — | Q40 | Q40 | topology record | O |
| R-97 | MIS-7 | CAP-107 | δημόσια διαφάνεια συμβάντων/διορθώσεων | L1 δημόσια γεγονότα + §2.7 | feed | — | Q26 witness | Q26, Q40 | incident feed | O |
| R-98 | MIS-9 | CAP-108 | μετρήσιμα SLOs | SLO registry (U-1) | numbers | — | Q40 witness (SLO χωρίς μέτρηση) | Q40 | measurements | O (U-1) |
| R-99 | MIS-9 | CAP-109 | CI γνήσια πράσινο και αναπαραγώγιμο πριν ισχυρισμούς | `.github/workflows` (REPLACE) | exit codes | — | KW-59, Q18 witness | Q18 | CI runs (API) | I→O |
| R-100 | MIS-7 | CAP-109 | περιβαλλοντικές ≠ κώδικα αποτυχίες | `BLOCKED ≠ FAIL` | exit 0/1/3 | — | Q18 witness (Κ-5) | Q18 | exit code log | I |

## §4.15 AI-Provider Integration

| R | Mission | CAP | Requirement | Seat | Interface | Invariant | Negative witness | Test | Evidence | Qual |
|---|---|---|---|---|---|---|---|---|---|---|
| R-101 | MIS-5 | CAP-110 | ελάχιστος ανοιχτός offline verifier | `deployment/verify/*` + MLTP v3 §8 | CLI | LOC-ceiling | KW-2, KW-9, KW-31, KW-32 | Q22 / VS-11 | receipts + LOC count | I |
| R-102 | MIS-5 | CAP-111 | εκδοχοποιημένο OpenAPI | νέο OpenAPI πάνω στο capability-api | OpenAPI 3.x | — | Q14 witness | Q14, Q27 | spec + validation | I |
| R-103 | MIS-5 | CAP-112 | versioned MCP | `mcp-server.lisp` | MCP tools | — | Q27 witness | Q27 / VS-11 | tool list | I |
| R-104 | MIS-5 | CAP-113 | λεπτά SDKs | περιτυλίγματα verifier | SDK | LOC-ceiling | Q22 witness (λογική εμπιστοσύνης στο SDK ⇒ κοκκίνισμα) | Q22 | SDK tests | I→P |
| R-105 | MIS-5 | CAP-114 | delta/update feeds | `ai-corpus-dump.lisp` κ.λπ. | signed deltas | — | Q12 | Q12, Q27 | feed digests | I |
| R-106 | MIS-5 | CAP-115 | οδηγίες pinned-root/rotation | README + TRUST-BOOTSTRAP §3 | docs | — | Q23 (γ) | Q23 | docs | I |
| R-107 | MIS-5 | CAP-116 | conformance suite | vectors + second impl | — | — | Q21 (δ) | Q21, Q22 | conformance report | I→P |
| R-108 | MIS-5 | CAP-116 | test vectors θετικά/αρνητικά | `deployment/verify/vectors/` | — | — | KW-28 (error χωρίς vector ⇒ κοκκίνισμα) | Q22 | vectors | I |
| R-109 | MIS-5, MIS-7 | CAP-117 | caching/revocation κανόνες | v1.4 §4.15 | TTL ≤ freshness_deadline | — | Q27 witness (cache πέρα από deadline ⇒ κοκκίνισμα) | Q27, Q28 | provider test | P |
| R-110 | MIS-5, MIS-7 | CAP-118 | provider adoption ξεχωριστή, ληξιπρόθεσμη, όχι αυτο-δηλωμένη | MLTP v3 §3.1 | provider attestations | — | KW-46 | Q26, Q28 | attestations | P |

## Εγκάρσια

| R | Mission | CAP | Requirement | Seat | Interface | Invariant | Negative witness | Test | Evidence | Qual |
|---|---|---|---|---|---|---|---|---|---|---|
| R-111 | MIS-10 | CAP-122, CAP-136 | μονόδρομο όριο, 9 απόντες τύποι, καμία ροή πίσω | v1.4 §1.3/§1.4 + MLTP v3 §1.0 | κλειστά σχήματα | — | KW-38, KW-39, Q20 witness | Q20 | schema compile failure | S→I |
| R-112 | MIS-1 | CAP-119, CAP-120, CAP-121, CAP-130 | και οι 12 στρώσεις CPEI παρούσες στο public profile | v1.4 §1.1 | — | — | audit check L1–L12 | contradiction audit | audit output | S |
| R-113 | MIS-7 | (όλες) | κάθε capability μία κατάσταση, κάθε R-id δέκα κρίκοι | crosswalk §B + αυτό | — | — | audit check (γραμμή χωρίς κρίκο ⇒ FAIL) | contradiction audit | audit output | S |
| R-114 | MIS-7 | CAP-123 | 5 ληξιπρόθεσμες βαθμίδες | MLTP v3 §3.1 + v1.4 §10 | QSR level | — | KW-13, Q28 witness | Q28 | QSR records | S→M |
| R-115 | MIS-8 | CAP-123 | Root Authority αυτόματη υποβάθμιση | MLTP v3 §8.3 F/Q | — | — | Q28 witness («για πάντα» ⇒ αποτυχία) | Q28 | receipts | M |
| R-116 | MIS-1 | CAP-124 | dominance ανά κρίσιμη επιλογή | `DOMINANCE-MATRIX.md` | D-01 έως D-13 | — | pass 2 | validation pass 2 | dominance record | S |
| R-117 | MIS-7 | CAP-125 | anti-loop κανόνες | v1.4 §7 + register | — | — | register witness (falsified ως canonical ⇒ FAIL) | contradiction audit | audit | S |
| R-118 | MIS-1 | CAP-126 | προδηλωμένο validation programme | Q-tests §8 | 6 πάσα | — | — (δεν εκτελείται) | — | programme text | S |

## Διευκρίνιση δημιουργού 2026-09-01 — χρονολόγια και Citation-Bound Verification Profile

| R | Mission | CAP | Requirement | Seat | Interface | Invariant | Negative witness | Test | Evidence | Qual |
|---|---|---|---|---|---|---|---|---|---|---|
| R-119 | MIS-7, MIS-3 | CAP-149 | δημόσιο νομικό χρονολόγιο: issued_at, published_at, effective_from, effective_to, ceased_by, cessation_type (κλειστό) στο payload | MLTP v3 §2.0 | `legal-timeline/1` | ceased_by ⇔ cessation_type | KW-61 (audit πεδίο στο payload ⇒ malformed-envelope) | Q41 / VS-01, VS-02 | claims με legal_timeline | S→I |
| R-120 | MIS-7 | CAP-149 | εσωτερικό χρονολόγιο ελέγχου χωριστό· ποτέ δεν κρίνει νομική ισχύ· ποτέ ως μέρος του κανόνα· διτεμπορικότητα εσωτερικά | MLTP v3 §2.0, §8.3 S | `audit-timeline/1` στο proof layer | βήμα S δεν διαβάζει audit-timeline | KW-60 | Q41, Q06 | verifier trace | S→I |
| R-121 | MIS-6, MIS-7 | CAP-150 | συνήθεις απαντήσεις χωρίς χρόνο πρώτης μάθησης· AI επαλήθευση μόνο release/freshness/coverage/revocation/provenance· audit endpoint | v1.4 §4.7 | `/audit/{claim_id}` | — | Q41 witness (acquired_at σε default απάντηση ⇒ κοκκίνισμα) | Q41, Q14 | API schema | I |
| R-122 | MIS-5, MIS-1 | CAP-151 | typed `citation/1` (6 πεδία) μέσα στα υπογεγραμμένα bytes κάθε CertifiedResult· stripped/altered ⇒ `UNVERIFIED_FOR_ATTRIBUTED_RELIANCE` | MLTP v3 §2.10, §8.3 C | CertifiedResult | I-4.16a, I-4.16b | KW-62 | Q42 / VS-11 | receipts + vectors | S→I |
| R-123 | MIS-8 | CAP-151 | διπλή παραπομπή: de jure εκδότης + Watchtower ως πηγή επαληθευμένης αναπαράστασης | `citation_policy_id` registry | `attribution_text` | I-4.16c | KW-63 | Q42 | policy + rendering | S→I |
| R-124 | MIS-5 | CAP-152, CAP-153 | canonical URLs, JSON-LD, CitationToken, υποχρεωτικά πεδία OpenAPI/MCP/SDK, default SDK rendering, conformance vectors, provider monitoring, observatory, downgrade/API-access | v1.4 §4.16 έδρες | SDK/API schemas | I-4.16d | KW-63, Q27 witness | Q42, Q16, Q27 | vectors + monitoring reports | I→P |
| R-125 | MIS-1, MIS-5 | CAP-76, CAP-77 | ακυκλική κατασκευή: κανένα `*_id` στο δικό του preimage· detached time/inclusion | `deployment/verify/mltp3/` (dag_check, build_fixtures) | construction DAG (schemas.json) | MLTP v3 §13.1 | KW-64, KW-66, KW-67, KW-68 | Q43 / dag_check | REPORT.json (dag_acyclic) | εκτελεσμένο (πυρήνας) |
| R-126 | MIS-5 | CAP-78, CAP-79 | δύο ανεξάρτητοι vetted verifiers (Go pure-Go + Node/OpenSSL), ίδιο typed αποτέλεσμα | `verify_a.go` + `verify_b.mjs` | verify_attestation contract | MLTP v3 §13.2 | KW-72, KW-73, KW-74, KW-88 έως KW-94 | Q43 / harness | REPORT.json (backends, negatives 31/31) | εκτελεσμένο (πυρήνας) |
| R-127 | MIS-5, MIS-8 | CAP-151 | εκτελεσμένο citation binding μέσα στην υπογραφή + πλήρης απάντηση | MLTP v3 §13.3 | `CertifiedResult`/`citation/1` | I-4.16a, I-4.16b | KW-75, KW-76, KW-77, KW-78 | Q42, Q43 | REPORT.json (certified VERIFIED) | εκτελεσμένο (πυρήνας) |
| R-128 | MIS-9 | CAP-48, CAP-50 | εκτελεσμένα: compiler independence binding, provider conformance, QSR separation-of-duty, revocation checkpoint | MLTP v3 §13.4/§13.1 | typed records | R4· MLTP v3 §13 | KW-69 έως KW-71, KW-79, KW-82, KW-85, KW-86 | Q43 | REPORT.json | εκτελεσμένο (πυρήνας) |
| R-129 | MIS-1, MIS-5 | CAP-156 | POST-C2 Finding 1: γλωσσο-ανεξάρτητο συμβόλαιο απαιτήσεων (μηχανοποιημένα artifacts = Implementation Book)· δύο compilers χωρίς κοινό evaluator code· conflict = adopted scoped ConflictPolicyBundle (ουσιαστικός κανόνας ΟΧΙ επινοημένος)· απών ⇒ UNKNOWN, ασύμβατα ⇒ CONFLICTING | `LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md`· v1.4 §4.17 | conformance corpus input→derivation | I-4.17a, I-4.17b, I-4.17c | KW-105 | VS-09, VS-10 | SEMANTIC-CONTRACT (design· PARTIALLY CLOSED· Implementation Book pending) | S (design) |
| R-130 | MIS-9, MIS-1 | CAP-154 | POST-C2 Finding 2: crypto agility + long-term evidence — suite registry, policy epochs, hybrid classical/PQ (ML-DSA-65), downgrade resistance, evidence renewal | MLTP v3 §14· v1.4 §4.18 | crypto-policy epoch + evidence-renewal | I-4.18a, I-4.18b, I-4.18c | KW-104 | VS-12 | MLTP §14 (design)· threat Θ15 | S (design) |
| R-131 | MIS-3, MIS-2 | CAP-155 | POST-C2 Finding 3: content-addressed ontology/SHACL lifecycle· receipt δεσμευμένο σε bundle+shapes digest· καμία αναδρομική ακύρωση | MLTP v3 §2.11· `source/shacl-validator.lisp` (EXTEND)· v1.4 §4.19 | ontology-bundle + shacl-validation-receipt | I-4.19a, I-4.19b, I-4.19c | KW-106 | VS-11 | MLTP §2.11 (design)· threat Θ16 | S (design) |

**Ισολογισμός:** 131 απαιτήσεις· 131 γραμμές (R-125 έως R-128 = εκτελέσιμη αναφορά MLTP v3 §13, ΕΚΤΕΛΕΣΜΕΝΑ στον πυρήνα· R-129 έως R-131 = POST-C2 reconciliation, design-only)· γραμμές με κρίκο σε `U-n`: R-08 (U-7),
R-11 (U-3), R-16 (U-6), R-33 (U-5), R-98 (U-1) — **5 μη πλήρεις** (δηλωμένες στο
crosswalk §B.11, όχι σιωπηλές)· R-118 δεν έχει witness επειδή είναι το ίδιο το
πρόγραμμα (δεν εκτελείται — δηλωμένο). Ο audit μετρά τις γραμμές και τα `U-` ίχνη.
