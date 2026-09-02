# PUBLIC OBSERVATORY CROSSWALK — ΚΑΘΕ ΥΠΑΡΧΟΝ ΣΥΣΤΑΤΙΚΟ → ΜΙΑ DISPOSITION · ΚΑΘΕ CAPABILITY → ΜΙΑ ΚΑΤΑΣΤΑΣΗ

**Έδρα (μία):** ο σημασιολογικός/capability crosswalk του `CHANGE-PROPOSAL-v1.4.md`.
Αντικαθιστά το `V1.3-SEMANTIC-CROSSWALK.md` (HISTORICAL) και **επεκτείνει** το
`LAWMAX-CEILING-CROSSWALK.md §1` (15 επίπεδα) στο πλήρες capability universe του
PUBLIC OBSERVATORY PROFILE (v1.4 §5). Design only.

**Dispositions (§A) — ακριβώς μία ανά συστατικό:** `REUSE` (καταναλώνεται ως έχει)
· `EXTEND` (η έδρα μένει, χρειάζεται επέκταση) · `REPLACE` (αντικαθίσταται από
ονομαζόμενη έδρα· το παλιό μένει ως ιστορικό/τεκμήριο) · `REMOVE` (αφαιρείται από
την αρχιτεκτονική — αδικαιολόγητη πολυπλοκότητα ή απορριφθείσα επιλογή) · `MISSING`
(η έδρα δεν υπάρχει — ονομάζεται) · `DEFER_PRIVATE` (ανήκει στο PRIVATE MATTER PROFILE).
**Κανένα συστατικό δεν διατηρείται επειδή υπάρχει.**

**Καταστάσεις capability (§B) — ακριβώς μία ανά capability:** `HAS_SEAT` (κανονική
έδρα ονομασμένη· η στήλη «υλοποίηση» λέει αν υπάρχει) · `EXCLUDED_WITH_PROOF` (δεν
είναι capability του δημόσιου στόχου, με απόδειξη/αναφορά) ·
`UNKNOWN_WITH_OWNER_AND_DEADLINE` (ανοιχτή απόφαση με owner και προθεσμία —
`CHANGE-PROPOSAL-v1.4.md §12`).

---

## A. DISPOSITIONS — ΟΛΑ ΤΑ ΥΠΑΡΧΟΝΤΑ ΣΥΣΤΑΤΙΚΑ

### A.1 Αρχιτεκτονικά έγγραφα και οι επτά μηχανές

| συστατικό | ρόλος | plane / layer | disposition | λόγος |
|---|---|---|---|---|
| `CHANGE-PROPOSAL-v1.4.md` | ο τρέχων δημόσιος υποψήφιος | όλα | (ο στόχος) | — |
| `CHANGE-PROPOSAL-v1.3.md` | προηγούμενος δημόσιος υποψήφιος | — | REPLACE | 31 ρίζες CONFIRMED (Stage A)· HISTORICAL / SUPERSEDED |
| `CHANGE-PROPOSAL-v1.2.md` | ιστορικός | — | REPLACE | HISTORICAL / SUPERSEDED (από v1.3) |
| `CHANGE-PROPOSAL-v1.1.md` | falsified | — | REPLACE | HISTORICAL / FALSIFIED — ποτέ target |
| `CHANGE-PROPOSAL-v1.0.md` | πρόταση Π1–Π11 | — | REPLACE | HISTORICAL |
| `MACHINE-LEGAL-TRUST-PROTOCOL.md` (v3) | wire schemas, verifier, trust mesh | §4.10 | (έδρα v1.4) | v2 → v3 στην ίδια έδρα |
| `V1.3-SEMANTIC-CROSSWALK.md` | crosswalk v1.3 | — | REPLACE | από αυτό το αρχείο (γραμμή 54 «SHA-256 μόνο» = RC-16) |
| `V1.3-KILL-WITNESSES.md` | KW-1 έως KW-16 | — | REPLACE | από `PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md §7` (KW-1 έως KW-63) |
| `V1.3-CONSISTENCY-AUDIT.sh` + `.md` + `.out` | 64 έλεγχοι v1.3 | — | REUSE | regression floor: εξακολουθεί να τρέχει· ο v1.4 audit τον περιλαμβάνει |
| `V1.1-DESTRUCTION-PASS-RECORD.md` | ιστορικό τεκμήριο | — | REUSE | τεκμήριο, όχι προδιαγραφή |
| `AS-IS-EVIDENCE-MANIFEST.md` | αναπαραγώγιμο AS-IS | — | EXTEND | R-1 έως R-6 παραμένουν REPORTED μέχρι εκτελέσιμο τεστ (βήμα 0) |
| `V1.3-DESTRUCTION-PASS/` (A1–A4, Stage A record) | τεκμήριο κατάρριψης v1.3 | — | REUSE | είσοδος του v1.4 §2 |
| `PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md` | Q01–Q40 + KW + validation programme | όλα | (έδρα v1.4) | ενημερώθηκε στη θέση της |
| `SUPERSEDED-REGISTER.md` | ταξινόμηση | — | (έδρα v1.4) | διόρθωση CPEI |
| `formal-v1.1/` (TLA+ μοντέλα, falsifiers, run-pack) | τεκμήριο v1.1 | — | REUSE | αρχειακό τεκμήριο· `TPKill` ουδέποτε εκτελέστηκε (EV-6) — μελλοντικό μοντέλο K2/K3/V |
| **M1** National Legal Radar (v1.2 §7) | απαρίθμηση πριν από περιεχόμενο, coverage ledger | §4.1 | EXTEND | ο απαριθμητής είναι 1 τεύχος × 1 έτος (AS-IS R-1) |
| **M2** Immutable Official Source Vault | σφράγιση bytes, append-only | §4.2 | EXTEND | + custody chain, authority-proof/2, πολυτροπικά |
| **M3** Legislation Event Compiler | typed γεγονότα, προβολή | §4.5, §4.8 | EXTEND | + 15 τύποι γεγονότων, δικαστικά/ενωσιακά |
| **M4** National Jurisprudence and ECLI Engine | νομολογία πρώτης τάξης | §4.9 | EXTEND | + τέσσερις τάξεις, reviewer adoption, line-of-authority |
| **M5** Independent Verification and Release Fabric | proposer-blind, υπογραφή | §4.6, §4.10 | EXTEND | + dual compilers, L6 parliament, threshold/HSM |
| **M6** Human/AI Distribution Machine | ιστότοπος, API, πρότυπα, παρατήρηση παραπομπών | §4.7, §4.11, §4.13, §4.15 | EXTEND | + proof-carrying answer, OpenAPI, SDKs |
| **M7** Conversational Mission Control | cockpit | §4.12 | EXTEND | + signed intent χωρίς direct publish, RBAC/MFA |

### A.2 Κανονικά κείμενα (`deployment/*.md`, `.sexp`, `.ttl`)

| συστατικό | ρόλος | plane / layer | disposition | λόγος |
|---|---|---|---|---|
| `LAWMAX-ARCHITECTURE-CONSTITUTION.sexp` | ο νόμος του repo, 13 primitives, gate | CORE | REUSE | ACTIVE ENFORCED· καμία νέα κορυφαία έννοια απαιτείται |
| `LAWMAX-CPEI-TARGET-SPEC.md` + `.sexp` | 12 στρώσεις, InstitutionalAct, Constitutional Compiler | CORE | REUSE | profiles ορίζονται στο v1.4 §1 — το CPEI δεν αναδιατυπώνεται |
| `LAWMAX-CEILING-CROSSWALK.md` + `.sexp` | 15 επίπεδα ↔ CPEI, πρωτόκολλο Ν μυαλών | CORE | EXTEND | §1β δείκτης προς το §B αυτού του αρχείου· Level 7/8 αποκτούν έδρα (§4.9/§4.8) |
| `LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md` + `-CLOSURE-MATRIX.md` | ταυτότητα, registries, receipts, relations, uncertainty | §4.2, §4.5, §4.9 | REUSE | καταναλώνεται ως έχει |
| `PROOF-CARRYING-LAW.md` | PCL-1 Merkle + authentic() | §4.10, §4.15 | EXTEND | PCL-2 delegation-aware/Ed25519 (βήμα 6)· era-1 verifier παραμένει (RC-15) |
| `LAWMAX-PROOF-OBJECT-SPEC.md` | proof object, census-2, Legal Proof Receipt | §4.7, §4.10 | REUSE | — |
| `LAWMAX-TRUST-BOOTSTRAP-SPEC.md` | ceremony, pinned root, delegation, gossip | §4.10 | EXTEND | threshold root, cross-client witnesses, fingerprint = RFC 7638 (MLTP v3 §4.5) |
| `LAWMAX-KEY-LIFECYCLE-SPEC.md` | roles, kid/alg/lineage, §2.5 | §4.10 | REUSE | versioned precedence MLTP v3 §4.5/§9 (§2.4 continuity = πληροφοριακό) |
| `LAWMAX-TEMPORAL-IDENTITY-DESIGN.md` | receipts, μία ρίζα, version-graph | §4.5, §4.10 | REUSE | — |
| `LAWMAX-TEMPORAL-SEMANTICS-SPEC.md` | effectivity conditions, regime edges | §4.5 | REUSE | — |
| `LAWMAX-THREAT-MODEL.md` | Θ1–Θ14 | §4.14 | EXTEND | Θ3/Θ4/Θ5/Θ9/Θ10 κλείνουν με MLTP v3· + Stage A ρίζες ως απειλές |
| `LAWMAX-MEMORY-KERNEL-SPEC.md` + `.sexp` | μνήμη | L1/L9 | REUSE | — |
| `LAWMAX-PHASE-1-TURN-ROOT-SPAN-DESIGN.md` + `.sexp` | M1 turn_id (ΕΓΚΕΚΡΙΜΕΝΟ design) | L1 | REUSE | προαπαιτούμενο ενιαίου ledger |
| `LAWMAX-AUTODIDACTIC-LOOP.md` | learning loop | CORE (evolution) | REUSE | Runner blocked κατά σειρά δημιουργού |
| `LAWMAX-NIXOS-COGNITIVE-SUBSTRATE.md` | L11 ladder | L11 | REUSE | blocked μέχρι σειρά δημιουργού |
| `LAWMAX-OMEGA-PLAN.md`, `LAWMAX-CONSOLIDATION-PLAN.md` | δρόμος / consolidation | — | REUSE | περιγραφικά, ποτέ κανονιστικός στόχος |
| `LAWMAX-DATASET-PACKAGE-PROJECTION.md` | dataset projection | §4.15 | REUSE | delta feeds εδράζονται εδώ |
| `LAWMAX-REPO-ONTOLOGY-MAP.md`, `LAWMAX-OMEGA-PLUS-REPO-AUDIT.md` | αναφορές απογραφής | — | REUSE | τεκμήριο |
| `LAWMAX-UNDERSTANDING-LEARNING-SCHEMA.md` | learning substrate σχήματα | L9 | REUSE | — |
| `ΧΑΡΤΗΣ-ΝΟΗΣΗΣ.md` | Σ4–Σ11 κλιμάκωση | CORE | REUSE | Σ4–Σ9 (υπαγωγή/αντιδικία/στρατηγική) = private profile· Σ10–Σ11 = core |
| `AUTONOMY.md` | αυτόνομη ενημέρωση από ΦΕΚ | §4.1 | EXTEND | + census ledger, gap reasons |
| `deployment/*.ttl` (ontology, identity, manifest, provenance-narrative, authority, ai-feedback) | RDF οντολογίες | §4.11 | REUSE | — |
| `deployment/shapes/eli-shapes.ttl`, `legal-shapes.ttl` | SHACL | §4.11 | REUSE | επικύρωση πριν δημοσίευση |
| `deployment/templates/*.ttl` | ai-citation-log, ai-ingest-manifest, graph-delta, semanticBeacon, version-lineage | §4.13, §4.15 | REUSE | — |
| `deployment/collab/design/**` (OMEGA2 blueprints, CANON, TARGET-ARCH, v07R, CENSUS-SCOPE, SSP deliverables, phase1/phase2) | ιστορικοί υποψήφιοι/τεκμήρια | — | REMOVE | από την αρχιτεκτονική· παραμένουν αρχειακά στο μητρώο (ποτέ ανταγωνιστές) |
| `deployment/collab/dialogue/0001–0136`, `AI-DIALOGUE.md`, `STATE-OF-PLAY.md` | πρακτικά | — | REUSE | ιστορικό, όχι προδιαγραφή |

### A.3 `source/` (133 αρχεία — ένα ανά γραμμή)

| αρχείο | ρόλος | plane / layer | disposition | λόγος |
|---|---|---|---|---|
| `adoption-decision.lisp` | what-if governed adoption | L8 | REUSE | — |
| `ai-citation-strategy.lisp` | citation collectors | §4.13 | EXTEND | stubs σήμερα (EV-9) → πραγματική συλλογή ή typed UNKNOWN |
| `ai-corpus-dump.lisp` | AI corpus dump | §4.15 | EXTEND | → signed delta feeds |
| `ai-ingest-manifest.lisp` | ingest manifest για AI | §4.15 | EXTEND | → MLTP v3 bundle refs |
| `akoma-ntoso-emitter.lisp` | Akoma Ntoso | §4.11 | REUSE | + επικύρωση σχήματος (Q38) |
| `amendment-extractor.lisp` | Διαύγεια → consolidation link | §4.5 | EXTEND | → typed AMENDMENT γεγονότα με πηγή |
| `anomaly-detection.lisp` | αυτο-ανίχνευση ανωμαλιών | L5/L9 | REUSE | — |
| `archive-authority.lisp` | archive authority | §4.2 | REUSE | archive-import origin |
| `asn1-der.lisp` | ASN.1 DER (μία έδρα) | §4.10 | EXTEND | πλήρης RFC-3161 TSR + TSA chain |
| `ast-gate.lisp` | AST structural gate | §4.2 | REUSE | — |
| `authority-evidence-replay.lisp` | authority-proof-bundle/1 replay + freeze | §4.10 | EXTEND | ρόλος = `release-authority-proof` (MLTP v3 §2.1α) — όχι κρατική προέλευση |
| `authority-proof-bundle.lisp` | εκπομπή bundle/1 | §4.10 | EXTEND | ομοίως |
| `autonomy.lisp` | αυτόνομος οδηγός | §4.1 | REUSE | — |
| `blockchain-authority.lisp` | blockchain anchoring | — | REMOVE | απορριφθείσα επιλογή (D-11)· καμία απαίτηση R-id |
| `canonical-representation.lisp` | ντετερμινιστική σειριοποίηση | §4.10 | REUSE | canonical-serialization-spec |
| `canonical-uris.lisp` | canonical URIs | §4.11 | REUSE | URI ανά διτεμπορική τομή |
| `capability-api.lisp` | transport-agnostic προβολή | §4.7, §4.12 | REUSE | — |
| `capability-registry.lisp` | μία έδρα ικανοτήτων | L9 | REUSE | — |
| `circuit-breaker.lisp` | circuit breaker | §4.14 | REUSE | — |
| `citation-authority.lisp` | citation graph analysis | §4.9, §4.13 | EXTEND | explicit-citation relations, revoked-material detection |
| `cognition.lisp` | 5 γνωσιακά στάδια | CORE | REUSE | — |
| `component-scan.lisp` | σαρωτής συστατικών | L9 | REUSE | — |
| `components.lisp` | μητρώο συστατικών | L9 | REUSE | — |
| `config.lisp` | configuration | — | REUSE | — |
| `consolidation-bridge.lisp` | consolidation bridge | §4.5 | REUSE | — |
| `consolidation-engine.lisp` | Lisp Legal Compiler (προβολή) | §4.5, §4.6 | REUSE | compiler A |
| `consolidation-feed.lisp` | ingestion → codification loop | §4.5 | REUSE | — |
| `consolidation-proof.lisp` | replayable amendment proof | §4.5, §4.7 | REUSE | — |
| `constitutional-gate.lisp` | συνταγματικός φραγμός | L10 | REUSE | — |
| `contracts.lisp` | μηχανικά ελέγξιμα συμβόλαια | L10 | REUSE | — |
| `corpus-diff.lisp` | «τι άλλαξε» | §4.7, §4.12 | EXTEND | invalidation set |
| `corpus-eu-links.lisp` | εθνικό ↔ ενωσιακό | §4.5 | EXTEND | EU-TRANSPOSITION γεγονότα |
| `corpus-fingerprint.lisp` | fingerprint + invariant gate | §4.14 | EXTEND | ενοποίηση Merkle (PROOF-OBJECT §1: odd→self-pair) |
| `corpus-intelligence.lisp` | MOP suite ανάλυσης | §4.3 | REUSE | — |
| `corpus-provenance.lisp` | acquisition provenance | §4.2 | EXTEND | + custody chain |
| `corpus-search.lisp` | αναζήτηση | §4.12 | REUSE | — |
| `corpus-service.lisp` | AI-first content negotiation | §4.15 | REUSE | — |
| `corpus-sparql.lisp` | live SPARQL | §4.11 | REUSE | — |
| `deliberation.lisp` | στοχαστής (εσωτερικός διάλογος) | L6 | EXTEND | ≥N ανεξάρτητοι κριτές με proof obligations |
| `deterministic-time.lisp` | deterministic timestamp | §4.10 | REUSE | ποτέ ως `now` του verifier |
| `document-fetch.lisp` | ορχήστρωση εξωτερικού fetcher | §4.2, §4.4 | REUSE | πρότυπο closed protocol |
| `embeddings-authority.lisp` | embeddings | PLANE-3 | EXTEND | μόνο ως neural-candidate είσοδος· εκτός trusted path |
| `eu-interop-layer.lisp` | ELI | §4.11 | EXTEND | ELI-Impact |
| `execution-trace.lisp` | legal execution provenance | L1 | REUSE | — |
| `fluid-induction.lisp` | επαγωγή προγραμμάτων | L5 | REUSE | — |
| `generation.lisp` | γένεση λόγου | §4.12 | EXTEND | ΜΟΝΟ ανθρωπο-αναγνώσιμη απόδοση typed απαντήσεων· ποτέ νομικός ισχυρισμός |
| `government-source.lisp` | government source fetcher | §4.1, §4.2 | EXTEND | census spaces, gap reasons |
| `graph-reasoning.lisp` | «γιατί/τι επηρεάζεται» | §4.8 | EXTEND | reason-impact με διτεμπορική τομή |
| `greek-legislation-ontology.lisp` | TBox | §4.3, §4.11 | EXTEND | alignment candidates → επικύρωση |
| `greek-lemmatizer.lisp` | lemmatizer | §4.3 (symbolic NLP) | REUSE | — |
| `greek-nlp-core.lisp` | NLP core | §4.3 | REUSE | — |
| `greek-tokenizer-advanced.lisp` | tokenizer | §4.3 | REUSE | — |
| `guard-metaeval.lisp` | αποτιμητής φραγμών | L4 | REUSE | — |
| `guard-ops-pack.lisp` | τελεστές φραγμών ως γνώση | L4 | REUSE | — |
| `hash-authority.lisp` | hash unification | §4.10 | EXTEND | διαγραφή tombstone `merkle-root` (PROOF-OBJECT §1) |
| `http-server.lisp` | HTTP server | §4.12 | REUSE | — |
| `ingestion-daemon.lisp` | daemon | §4.1 | EXTEND | retry/escalation state |
| `injection.lisp` | dependency injection | — | REUSE | — |
| `institution.lisp` | το Ίδρυμα | CORE | REUSE | — |
| `introspection.lisp` | introspection | L9 | REUSE | — |
| `journal.lisp` | append-only journal | L1, §4.5 | REUSE | event store |
| `json-emit.lisp` | έγκυρο JSON | §4.10 | REUSE | — |
| `jws-authority.lisp` | JWS | §4.10 | EXTEND | Ed25519 (EdDSA), context strings |
| `knowledge-graph.lisp` | meta-knowledge graph | §4.3 | EXTEND | alignment |
| `knowledge-packs.lisp` | πακέτα γνώσης | CORE | REUSE | — |
| `layout-types.lisp` | layout graph L1 | §4.2 | EXTEND | πίνακες/παραρτήματα/σφραγίδες |
| `legal-ast.lisp` | Legal AST L4 | §4.3 (Legal IR) | EXTEND | `norm.determinacy` |
| `legal-audit-system.lisp` | audit system | §4.14 | EXTEND | ενοποίηση Merkle (SHA-512 → profile) |
| `legal-authority-receipt.lisp` | LegalAuthorityReceipt | §4.2, §4.7 | EXTEND | manifestation refs |
| `legal-casegrammar.lisp` | αφήγηση → γεγονότα υπόθεσης | private | DEFER_PRIVATE | case facts = private type |
| `legal-conflict-resolution.lisp` | lex superior | §4.3 | REUSE | — |
| `legal-counterfactual.lisp` | counterfactual | §4.8 | REUSE | ΜΟΝΟ corpus-level (public L7) |
| `legal-decisions.lisp` | corpus αποφάσεων | §4.9 | EXTEND | όλα τα δικαστήρια, ECLI |
| `legal-deontic.lisp` | δεοντικό | §4.3 | REUSE | — |
| `legal-dialectic.lisp` | θέσεις/ενστάσεις | L6 | EXTEND | μηχανισμός ενστάσεων επί δημοσίευσης/ανάλυσης· ΟΧΙ αντιδικία υπόθεσης |
| `legal-event-calculus.lisp` | event calculus | §4.5 | REUSE | — |
| `legal-extraction-verify.lisp` | «neural προτείνει / symbolic κρίνει» | §4.3 | EXTEND | η πύλη του επιστημικού τείχους |
| `legal-hypergraph.lisp` | N-ary knowledge | §4.8 | REUSE | — |
| `legal-hypo.lisp` | ποια γεγονότα κρίνουν την έκβαση | private | DEFER_PRIVATE | case-outcome hypotheticals |
| `legal-id-registry.lisp` | ποιον κώδικα αγγίζει ΦΕΚ | §4.2 | EXTEND | manifestation level |
| `legal-identity.lisp` | μία έδρα ταυτότητας | §4.2 | EXTEND | lsm1 + derived_from_expression |
| `legal-inference-engine.lisp` | L1 συλλογισμού (JTMS) | §4.3, §4.7 | REUSE | — |
| `legal-knowledge.lisp` | ενοποιημένη γνώση | CORE | REUSE | — |
| `legal-penalty.lisp` | επιεικέστερος νόμος (άρθρο 2 ΠΚ) | §4.5 | REUSE | norm-level, δημόσιο |
| `legal-precedent.lisp` | ομοιότητα ΓΕΓΟΝΟΤΩΝ (HYPO/CATO) | private | DEFER_PRIVATE | analogical reasoning επί υπόθεσης |
| `legal-qa.lisp` | provable answers | §4.7 | EXTEND | proof-carrying-answer/1 |
| `legal-reasoning-bridge.lisp` | corpus → engine facts | §4.7 | EXTEND | premises με receipt-ids |
| `legal-references.lisp` | reference graph | §4.5, §4.8 | REUSE | — |
| `legal-strategy.lisp` | δικονομική στρατηγική | private | DEFER_PRIVATE | private strategy type |
| `legal-subsumption.lisp` | υπαγωγή γεγονότων υπόθεσης | private | DEFER_PRIVATE | matter-solving |
| `legal-temporal.lisp` | legal-temporal | §4.5 | REUSE | — |
| `legislation-ingestion.lisp` | ingestion + scheduler | §4.1 | EXTEND | census enumerators |
| `lexicon-neurolingo.lisp` | μορφολογικό λεξικό | §4.3 | REUSE | — |
| `logging.lisp` | logging | — | REUSE | — |
| `mcp-server.lisp` | MCP (4 εργαλεία) | §4.7, §4.15 | EXTEND | versioned MCP + proof-carrying answers |
| `memory.lisp` | υπόστρωμα μνήμης | L1/L9 | REUSE | — |
| `merkle-authority.lisp` | η ΜΙΑ έδρα Merkle | §4.10 | REUSE | profile lawmax-merkle-sha256-v1 |
| `narrative-provenance.lisp` | narrative provenance | §4.2 | REUSE | — |
| `orthography-lexicon.lisp` | ορθογραφική αυθεντία | §4.3 | REUSE | — |
| `paths.lisp` | paths | — | REUSE | — |
| `pdf-authority.lisp` | PDF text extraction | §4.2 | REUSE | native PDF· σαρωμένα = OCR (MISSING) |
| `proof-carrying.lisp` | PCL-1 | §4.10, §4.15 | EXTEND | PCL-2 |
| `proposals.lisp` | κύκλος πρότασης → έγκρισης | L5/L8 | REUSE | δημόσιος hypothesis lifecycle εδράζεται εδώ |
| `protocols.lisp` | protocols | — | REUSE | — |
| `provenance-link.lisp` | ίχνη ⋈ συμβόλαια ⋈ αποδείξεις | L1 | REUSE | — |
| `rdfs-inference.lisp` | RDFS | §4.11 | REUSE | — |
| `reasoning-authority.lisp` | OWL/RDFS reasoning | §4.11 | REUSE | — |
| `review-queue.lisp` | review queue | L8 | REUSE | — |
| `review-service.lisp` | οθόνη έγκρισης | §4.12 | EXTEND | RBAC/MFA |
| `safe-read.lisp` | ασφαλής αποσειριοποίηση | §4.4 | REUSE | το μοναδικό σημείο εισόδου neural-candidate |
| `self-constitution.lisp` | ανάγνωση Συντάγματος | L10 | REUSE | — |
| `self-history.lisp` | βιογραφία (append-only) | L1 | REUSE | — |
| `self-model.lisp` | ζωντανό αυτο-μοντέλο | L9 | REUSE | — |
| `semantic-authority.lisp` | semantic authority | §4.11 | EXTEND | θάνατος ψευδο-Merkle `compute-merkle-root` (PROOF-OBJECT §1) |
| `semantic-versioning-system.lisp` | versioning | §4.15 | REUSE | — |
| `shacl-validator.lisp` | SHACL core | §4.11 | REUSE | — |
| `signed-embedding-manifest.lisp` | provenance AI artifacts | PLANE-3 | EXTEND | transformation_provenance των candidates |
| `source-profile.lisp` | ranked channels, consensus | §4.2 | REUSE | divergence witnesses |
| `sparql-endpoint.lisp` | SPARQL | §4.11 | REUSE | — |
| `static-site.lisp` | static site (Pages) | §4.12 | REUSE | προβολή του canonical release |
| `text-canonicalizer.lisp` | text normalization L3 | §4.2 | REUSE | — |
| `timestamp-authority.lisp` | RFC-3161 | §4.10 | EXTEND | πλήρης επαλήθευση TSR, imprint επί υπογραφής |
| `trace-core.lisp` | traceability foundation | L1 | REUSE | — |
| `turtle-parser.lisp` | Turtle | §4.11 | REUSE | — |
| `typographic-classifier.lisp` | logical block FSM | §4.2 | EXTEND | πίνακες/παραρτήματα |
| `validate-ast.lisp` | AST validation | §4.2 | REUSE | — |
| `validate-layout-graph.lisp` | layout validation | §4.2 | REUSE | — |
| `validate-logical-blocks.lisp` | block validation | §4.2 | REUSE | — |
| `validation-authority.lisp` | contract validation | L10 | REUSE | — |
| `version-graph.lisp` | διτεμπορικός γράφος εκδόσεων | §4.5, §4.9 | EXTEND | δικαστικά/ενωσιακά γεγονότα, line-of-authority |
| `what-if.lisp` | what-if governed change | §4.8 | REUSE | — |
| `write-authority.lisp` | η ΜΙΑ έδρα εγγραφής | §4.3 | REUSE | το neural runtime δεν την έχει |
| `x509-authority.lisp` | X.509 | §4.2, §4.10 | EXTEND | TSA chains, PAdES/XAdES signer certs |

### A.4 `systems/orchestrator-cli/` (48 αρχεία)

| αρχείο | ρόλος | plane / layer | disposition | λόγος |
|---|---|---|---|---|
| `advisor.lisp` | LLM ως προτείνων εκτός εμπιστοσύνης | §4.3 | REUSE | το πρότυπο του neural plane |
| `approval-policy.lisp` | πολιτικές έγκρισης | L12 | REUSE | — |
| `architecture-gate.lisp` | συνταγματική πύλη | L10 | REUSE | — |
| `autonomy-missions.lisp` | αποστολές οδηγού | §4.1 | REUSE | — |
| `builtin-commands.lisp` | εντολές μητρώου | — | REUSE | — |
| `capability-gate.lisp` | capability ratchet | L9 | REUSE | — |
| `case-workspace.lisp` | χώρος υπόθεσης (blackboard) | private | DEFER_PRIVATE | Matter type |
| `cli-util.lisp` | βοηθοί | — | REUSE | — |
| `cockpit.lisp` | cockpit (`/api/ask`, `/api/pending`, `/api/decide`, `/api/publish`, `/api/catalog`) | §4.12 | EXTEND | `/api/publish` ως άμεση ενέργεια → REPLACE από `approval` intent στην ουρά M5 (v1.4 §4.12) |
| `cognition-legal.lisp` | νομικός διάλογος | §4.12 | EXTEND | proof-carrying answers |
| `cognition-self.lisp` | διάλογος εαυτού | L9 | REUSE | — |
| `commands.lisp` | TOMBSTONE υπό απόσυρση ([0115]) | — | REMOVE | ολοκλήρωση απόσυρσης |
| `component-gate.lisp` | πύλη συστατικών | L9 | REUSE | — |
| `config-loader.lisp` | config | — | REUSE | — |
| `constitutional-dispatch.lisp` | φραγμός ως ιδιότητα | L10 | REUSE | — |
| `content-validation.lisp` | content-sanity gate | §4.2 | REUSE | — |
| `contract-gate.lisp` | πύλη συμβολαίων | L10 | REUSE | — |
| `decisions.lisp` | εντολές νομολογίας (ΑΠ intake) | §4.9 | EXTEND | όλα τα δικαστήρια |
| `deontic-gate.lisp` | δεοντική πύλη | §4.3 | REUSE | — |
| `dialogue-gate.lisp` | πύλη διαλόγου | §4.12 | REUSE | — |
| `draft-commands.lisp` | Σημείωμα Υπαγωγής | private | DEFER_PRIVATE | matter deliverable |
| `event-gate.lisp` | πύλη ιστορίας | §4.5 | REUSE | — |
| `evolution-gate.lisp` | αυτοεξέλιξη | L8 | REUSE | — |
| `external-benchmark-gate.lisp` | εξωτερικό benchmark (L11 attestation) | §4.14 | REUSE | — |
| `fluid-gate.lisp` | ρευστή νόηση | L5 | REUSE | — |
| `gates-runner.lisp` | ολομέλεια πυλών | L10 | REUSE | — |
| `generation-gate.lisp` | γραμματική | §4.12 | REUSE | — |
| `golden-gate.lisp` | golden ratchet | §4.14 | REUSE | — |
| `graph-import.lisp` | εισαγωγή γράφου | §4.5 | REUSE | — |
| `inference-gate.lisp` | πύλη συμπερασμού | §4.3 | REUSE | — |
| `ingestion-commands.lisp` | εντολές ΦΕΚ/δαίμονα | §4.1 | EXTEND | census |
| `iq-gate.lisp` | IQ πύλη | §4.3 | REUSE | — |
| `jurisprudence-judge.lisp` | μετρημένη ικανότητα νομολογίας | §4.9 | REUSE | — |
| `legal-eval.lisp` | benchmark αφήγηση → διατακτικό | private | DEFER_PRIVATE | μετρά ιδιωτική ικανότητα (υπαγωγή) |
| `log.lisp` | logging | — | REUSE | — |
| `main.lisp` | entrypoint | — | REUSE | — |
| `memory-commands.lisp` | εντολές μνήμης | L1 | REUSE | — |
| `package.lisp` | package | — | REUSE | — |
| `provenance-gate.lisp` | πύλη προέλευσης | L1 | REUSE | — |
| `release-authority.lisp` | content-addressed release authority | §4.6, §4.10 | EXTEND | dual attestation, threshold/HSM |
| `release-gate.lisp` | πύλη αμετάβλητων εκδόσεων | §4.6 | EXTEND | compiler-divergence ⇒ quarantine |
| `reporting.lisp` | reports | — | REUSE | — |
| `self-extension.lisp` | Σ11 αυτο-επέκταση | L8 | REUSE | — |
| `self-reflection.lisp` | εσωτερικός βρόχος | L9 | REUSE | — |
| `subsumption-commands.lisp` | `--subsume` / `--argue` / `--what-if` | §4.8 + private | EXTEND | `--what-if` δημόσιο (L7)· `--subsume`/`--argue` προσβάσιμα ΜΟΝΟ στο private profile |
| `understanding-learning.lisp` | learning substrate | L9 | REUSE | — |
| `verify-truth-gate.lisp` | docs ≡ CI | §4.14 | EXTEND | πράσινο CI ως προϋπόθεση |
| `version-graph-import.lisp` | import σωμάτων στον γράφο | §4.5 | REUSE | — |

### A.5 `deployment/verify/`, `authority-v2/`, `docker/`, `scripts/`, CI, λοιποί κατάλογοι

| συστατικό | ρόλος | plane / layer | disposition | λόγος |
|---|---|---|---|---|
| `deployment/verify/verify.py`, `verify.mjs` | δημόσιοι PCL-1 verifiers (Python stdlib, Node) | §4.15 | EXTEND | → MLTP v3 verifier (era-1 διαδρομή παραμένει) |
| `deployment/verify/verify-release.py`, `verify-temporal.py`, `verify-authority-bundle.py`, `verify-canonical.py`, `verify-merkle.py/.mjs` | ανεξάρτητοι έλεγχοι release/temporal/bundle/canonical/merkle | §4.6, §4.15 | EXTEND | τρίτος έλεγχος (όχι compiler B) |
| `deployment/verify/kernel-verify.lisp` | kernel verifier | §4.15 | EXTEND | MLTP v3 §8.3 |
| `deployment/verify/vectors/` | test vectors (θετικά + tampered) | §4.15 | EXTEND | + αρνητικά vectors ανά error name |
| `deployment/verify/README.md`, `canonical-serialization-spec.md` | τεκμηρίωση, canonical spec | §4.10 | REUSE | README: EXTEND για MLTP v3 |
| `deployment/verify/mltp3/` (schemas, build_fixtures, crypto_libsodium, verify_a.go, verify_b.mjs, mutate, dag_check, harness, run.sh, fixtures) | **εκτελέσιμη αναφορά MLTP v3** — ακυκλική κατασκευή, δύο vetted verifiers (Go/pure-Go + Node/OpenSSL), 31 kill witnesses | §4.10, §4.15, MLTP v3 §13 | **present** (EXTEND → 15 επίπεδα) | `EXECUTABLE PROTOCOL CLOSURE PASSED`· δεν είναι qualification/freeze |
| `deployment/verify/gate-registry.sexp`, `hash-seat-registry.sexp`, `merkle-profile.sexp`, `capability-baseline.sexp`, `assess-gate-*`, `census-execution-constructs.sh`, `blind-failure-test.sh`, `golden/`, `consciousness-audit/`, `self-understanding-audit/`, `ontology-raw-live-dump.sexp` | μητρώα πυλών/εδρών, audits | L10, §4.14 | REUSE | — |
| `authority-v2/roles/ROLES-MODEL.sexp`, `ceremony.sh` | roles model, ceremony | §4.10 | EXTEND | threshold owner root, HSM roles |
| `authority-v2/proofs/witness-quorum-test.py` | witness quorum | §4.10 | EXTEND | cross-client witnesses |
| `authority-v2/proofs/*` (λοιπά 14), `run-all.sh`, `run-proofs.sh`, `PROOF-CENSUS.txt`, `proof-manifest.sexp`, `LEVEL7-COMPLETION-MATRIX.sexp` | απογραφή αποδείξεων, exit 0/1/3 | §4.14 | REUSE | το πρότυπο `BLOCKED ≠ FAIL` |
| `authority-v2/schema/state.cddl`, `transition-certificate.cddl` | CDDL/CBOR σχήματα | §4.11 | REUSE | βάση CBOR προβολής (SCITT) |
| `authority-v2/kernel/`, `capability/`, `capture/`, `fixtures/`, `genesis/`, `log/`, `store/`, `tests/`, `toolchain/` | authority kernel v2 | §4.10, §4.14 | REUSE | — |
| `Dockerfile`, `Dockerfile.test`, `docker-compose*.yml`, `docker/entrypoint.lisp`, `docker/dep-hash.lisp`, `docker/sha256.lisp`, `docker/verify-deps.lisp`, `docker/run-standalone-*`, `docker/suite-census.txt`, `docker/verifier-census.txt`, `docker/standalone-suite-exclusions.txt`, `deps.lock`, `deps.archives.lock` | hermetic build | L11, §4.14 | REUSE | — |
| `docker/sbom.json`, `docker/cosign.pub` | SBOM, cosign | §4.14 | EXTEND | συνεχής SBOM scan, key rotation |
| `docker/verify-proof-manifest.py` (+ test), `docker/BUILD-ISSUES.md`, `docker/IMPLEMENTATION-SUMMARY.md` | proof manifest verify, τεκμήρια | §4.14 | REUSE | — |
| `scripts/generate-keys.lisp` | γένεση κλειδιών | §4.10 | EXTEND | Ed25519, threshold ceremony |
| `scripts/*` (λοιπά 7: capture-runtime-closure, gen-deps-lock, gen-merkle-truth, merkle-mutation-witness, verify-gate-5-validation, verify-runtime-closure*) | εργαλεία κλεισίματος/επαλήθευσης | §4.14 | REUSE | — |
| `.github/workflows/*` (docker-orchestrator, provenance, deploy-corpus) | CI | §4.14 | REPLACE | 71 runs / 0 successes (EV-12)· γνήσια πράσινο, `BLOCKED ≠ FAIL` |
| `tools/independent-audit.py` | ανεξάρτητος έλεγχος | §4.14 | REUSE | — |
| `systems/orchestrator-core`, `orchestrator-ai-core`, `orchestrator-engine-sbcl` (πλην `stages/anchor-blockchain.lisp`) | runtime systems | CORE | REUSE | — |
| `systems/orchestrator-engine-sbcl/stages/anchor-blockchain.lisp` | blockchain anchor (duplicate-last Merkle) | — | REMOVE | D-11 + PROOF-OBJECT §1 (CVE-2012-2459 κλάση) |
| `systems/orchestrator-epistemic/` merkle-tree (PROOF-OBJECT §1) | release Merkle (μη domain-separated) | §4.10 | EXTEND | ενοποίηση στο profile |
| `tests/`, `determinism/`, `examples/`, `docs/`, `configs/`, `cloudflare/`, `evidence/`, `input/`, `state/`, `candidates/`, `releases/`, `output/`, `output_run1/` | τεστ, δεδομένα, artifacts, λειτουργικά | — | REUSE | δεδομένα/λειτουργικά· όχι αρχιτεκτονικό τεκμήριο (anti-loop 7) |
| `deps/`, `third-party/`, `package.json`, `package-lock.json`, `*.asd`, `build.lisp`, `entrypoint.lisp` | vendored εξαρτήσεις, systems | L11 | REUSE | pinned |
| `keys/` (untracked) | ιδιωτικά κλειδιά | §4.10 | EXTEND | HSM/threshold custody· ποτέ σε repo |

**Πληρότητα §A (μηχανικά ελέγξιμη):** κάθε `source/*.lisp` (133) και κάθε
`systems/orchestrator-cli/*.lisp` (48) έχει ακριβώς μία γραμμή· ο audit
`V1.4-CONTRADICTION-OMISSION-AUDIT.sh` συγκρίνει τα ονόματα με το filesystem.

---

## B. CAPABILITY UNIVERSE — ΚΑΘΕ CAPABILITY ΜΙΑ ΚΑΤΑΣΤΑΣΗ (επέκταση CEILING-CROSSWALK §1)

Στήλες: capability · κατάσταση · έδρα (για HAS_SEAT) ή απόδειξη (για EXCLUDED) ή
owner+προθεσμία (για UNKNOWN) · υλοποίηση σήμερα (`present` / `partial` /
`missing`) · απαιτήσεις (R-ids) · CEILING επίπεδο όπου υπάρχει.

### B.0 Ευρετήριο στρώσεων CPEI L1–L12 → capabilities (καμία στρώση χωρίς έδρα στο public profile)

| στρώση | capabilities (§B) | plane v1.4 |
|---|---|---|
| **L1** Immutable Institutional Ledger | CAP-08, CAP-42, CAP-92, CAP-107, CAP-119 | §4.5, §4.14 |
| **L2** Bitemporal Epistemic Graph | CAP-42, CAP-43, CAP-44, CAP-45, CAP-46, CAP-47, CAP-61, CAP-149 | §4.5, §4.9 |
| **L3** Typed Epistemic Objects | CAP-14, CAP-17, CAP-22, CAP-31, CAP-37, CAP-65, CAP-122 | §4.3 |
| **L4** Proof / Counterproof | CAP-36, CAP-51, CAP-52, CAP-53, CAP-151 | §4.7, §4.16 |
| **L5** Public Hypothesis Workspace | CAP-28, CAP-29, CAP-38 | §4.3 |
| **L6** Public Adversarial Parliament | CAP-34, CAP-48, CAP-49, CAP-50, CAP-60 | §4.6, §4.9 |
| **L7** Public Legal Digital Twin + Normative-Impact Simulator | CAP-55, CAP-56 | §4.8 |
| **L8** Governance / Adoption / Quarantine | CAP-49, CAP-90, CAP-121 | §4.12 |
| **L9** Self-Model, Coverage Awareness, Meta-Memory | CAP-01, CAP-02, CAP-03, CAP-04, CAP-05, CAP-06, CAP-07, CAP-94, CAP-95, CAP-96, CAP-130, CAP-153 | §4.1, §4.13 |
| **L10** Constitutional Compiler | CAP-120, CAP-125 | §4.14 |
| **L11** Reproducible Substrate | CAP-97, CAP-98, CAP-99, CAP-109, CAP-128 | §4.14 |
| **L12** Human Sovereignty, Approval, Revocation, Rollback | CAP-90, CAP-91, CAP-121, CAP-123 | §4.12, §4.14 |

Ο `V1.4-CONTRADICTION-OMISSION-AUDIT.sh` απαιτεί και τις 12 γραμμές εδώ και στο v1.4 §1.1.

### B.1 §4.1 Census / Radar (MIS-2)

| id | capability | κατάσταση | έδρα / απόδειξη / owner | υλοποίηση | R-ids | CEILING |
|---|---|---|---|---|---|---|
| CAP-01 | δηλωμένο census universe (root-signed `RegistrySnapshot kind=census-universe`) | HAS_SEAT | MLTP v3 §2.9 + M1 | missing | R-01 έως R-11, R-13 | 10 |
| CAP-02 | απαριθμητές ανά space (ΦΕΚ σειρές, δικαστήρια, ΕΕ, ανεξάρτητες αρχές, κοινοβούλιο, εγκύκλιοι, θεωρία) | HAS_SEAT | `legislation-ingestion.lisp` + `government-source.lisp` | partial (1 τεύχος × 1 έτος) | R-01 έως R-11 | 10 |
| CAP-03 | coverage ledger ως ολική συνάρτηση | HAS_SEAT | journal capability (CPEI §4) + MLTP v3 §2.4 | missing | R-12, R-13 | 10 |
| CAP-04 | gap reason / retry / escalation state | HAS_SEAT | `ingestion-daemon.lisp` | missing | R-12 | 10 |
| CAP-05 | υπογεγραμμένο coverage evidence ανά space | HAS_SEAT | `coverage-and-freshness` claim | missing | R-12 | 10 |
| CAP-06 | ανεξάρτητη δεύτερη απαρίθμηση (Μ-4) | HAS_SEAT | auditor re-derivation (M5) | missing | R-13 | 10 |
| CAP-07 | διαχωρισμός δεσμευτικού/μη-δεσμευτικού (εγκύκλιοι, θεωρία) στον τύπο | HAS_SEAT | census space attributes `binding`/`authoritative` | missing | R-10, R-11 | — |

### B.2 §4.2 Acquisition / Authenticity (MIS-1, MIS-2)

| id | capability | κατάσταση | έδρα / απόδειξη / owner | υλοποίηση | R-ids | CEILING |
|---|---|---|---|---|---|---|
| CAP-08 | immutable source vault (append-only, content-addressed) | HAS_SEAT | M2: `corpus-provenance.lisp` + `journal.lisp` | present | R-14 έως R-22 | — |
| CAP-09 | XML/HTML acquisition | HAS_SEAT | `document-fetch.lisp` + `government-source.lisp` | present | R-14 | — |
| CAP-10 | native PDF extraction | HAS_SEAT | `pdf-authority.lisp` | present | R-15 | — |
| CAP-11 | σαρωμένα PDF/εικόνες (OCR) | HAS_SEAT | neural runtime §4.4 → `neural-candidate/1 kind=ocr-text` | missing | R-16 | — |
| CAP-12 | σελιδοποίηση, πίνακες, παραρτήματα | HAS_SEAT | `layout-types.lisp` + `typographic-classifier.lisp` | partial | R-17, R-18 | — |
| CAP-13 | ανίχνευση/επαλήθευση υπογραφών και σφραγίδων (PAdES/XAdES) | HAS_SEAT | `x509-authority.lisp` + `asn1-der.lisp` + authority-proof/2 | missing | R-19 | — |
| CAP-14 | μεταδεδομένα manifestation | HAS_SEAT | USC §1.3 + `legal-identity.lisp` | partial | R-20 | — |
| CAP-15 | επίσημο οπτικοακουστικό (transcript manifestation) | HAS_SEAT | USC §1.3 `media_type` + `media-verification/1` | missing | R-21 | — |
| CAP-16 | πολλαπλά manifestations του ίδιου work | HAS_SEAT | USC §1.1–§1.3 | partial | R-22 | — |
| CAP-17 | USC ταυτότητα 4 επιπέδων + two-channel invariant | HAS_SEAT | `legal-identity.lisp` (EXTEND) | partial | R-23 | 2 |
| CAP-18 | acquisition receipts + custody chain | HAS_SEAT | `corpus-provenance.lisp` + MLTP v3 §2.1β | partial | R-23 | — |
| CAP-19 | authority-proof/2 (κρατική προέλευση, βαθμοί S0–S3) | HAS_SEAT | MLTP v3 §2.1α | missing | R-23 | — |
| CAP-20 | divergence witnesses (official-sources-conflict) | HAS_SEAT | `source-profile.lisp` + USC §8 | partial | R-23 | — |
| CAP-21 | αυθεντικοποιημένο χρονικό τεκμήριο (πλήρης RFC-3161) | HAS_SEAT | `timestamp-authority.lisp` (EXTEND) | partial | R-23 | — |

### B.3 §4.3 / §4.4 Neuro-symbolic plane και runtime boundary (MIS-1, MIS-7)

| id | capability | κατάσταση | έδρα / απόδειξη / owner | υλοποίηση | R-ids | CEILING |
|---|---|---|---|---|---|---|
| CAP-22 | closed typed protocol `neural-candidate/1` / `neural-task/1` | HAS_SEAT | v1.4 §4.3/§4.4 + `safe-read.lisp` | missing | R-25, R-29, R-30, R-34 | — |
| CAP-23 | OCR + layout understanding (neural) | HAS_SEAT | εξωτερικό runtime | missing | R-24 | — |
| CAP-24 | πολυτροπική συμφιλίωση εγγράφων | HAS_SEAT | εξωτερικό runtime → candidates | missing | R-24 | — |
| CAP-25 | εξαγωγή οντοτήτων/σχέσεων (candidates) | HAS_SEAT | εξωτερικό runtime + `legal-extraction-verify.lisp` | partial (symbolic) | R-24 | 2 |
| CAP-26 | υποψήφιες αντιστοιχίσεις οντολογίας | HAS_SEAT | εξωτερικό runtime + `greek-legislation-ontology.lisp` | missing | R-24 | — |
| CAP-27 | υποψήφια νομικά γεγονότα | HAS_SEAT | εξωτερικό runtime + `amendment-extractor.lisp` | partial | R-24 | — |
| CAP-28 | υποψήφια ratio/holding/issue | HAS_SEAT | εξωτερικό runtime (PLANE-3) | missing | R-24 | 7 |
| CAP-29 | ομοιότητα, ανωμαλίες, κενά, αντιφάσεις (discovery) | HAS_SEAT | εξωτερικό runtime + `anomaly-detection.lisp` | partial | R-24 | — |
| CAP-30 | neural never-list ως δομή (κανένα κλειδί, καμία write authority, ένας τύπος εισόδου) | HAS_SEAT | `write-authority.lisp` + Σύνταγμα `:no-llm-trusted-path` | present (κανόνας) | R-26 | 11 |
| CAP-31 | typed Legal IR validation | HAS_SEAT | `legal-ast.lisp` + `validate-ast.lisp` | partial | R-27 | 2 |
| CAP-32 | temporal/event reasoning | HAS_SEAT | `legal-temporal.lisp` + `legal-event-calculus.lisp` | present | R-27 | 1 |
| CAP-33 | deontic reasoning | HAS_SEAT | `legal-deontic.lisp` | present | R-27 | 11 |
| CAP-34 | defeasible rules/exceptions, argumentation/burden (norm-level) | HAS_SEAT | `legal-inference-engine.lisp` + `legal-dialectic.lisp` | present | R-27 | 3, 4 |
| CAP-35 | contradiction/constraint checking | HAS_SEAT | `legal-conflict-resolution.lisp` + `guard-metaeval.lisp` | present | R-27 | — |
| CAP-36 | proof/counterproof generation | HAS_SEAT | `proof-carrying.lisp` + `legal-dialectic.lisp` | partial (counterproof slot) | R-27 | 4 |
| CAP-37 | ρητή αποχή + `norm.determinacy` (interpretive/discretionary/underdetermined) | HAS_SEAT | `legal-ast.lisp` (EXTEND) | missing | R-27, R-28 | 13 |
| CAP-38 | δημόσιος hypothesis workspace με κύκλο ζωής (L5) | HAS_SEAT | `proposals.lisp` + `anomaly-detection.lisp` + `fluid-induction.lisp` | partial | R-24 | 5 |
| CAP-39 | Common Lisp κανονικός πυρήνας | HAS_SEAT | `systems/orchestrator-*` | present | R-31 | — |
| CAP-40 | εξωτερικό νευρωνικό runtime (Python/PyTorch/ONNX) | HAS_SEAT | v1.4 §4.4 (εκτός trusted path) | missing | R-32 | — |
| CAP-41 | δεύτερος compiler σε διαφορετική γλώσσα/runtime | HAS_SEAT | v1.4 §4.6 (Rust προτιμώμενο) | missing | R-33 | — |

### B.4 §4.5 / §4.6 / §4.7 / §4.8 Digital twin, compilers, query engine, impact (MIS-3, MIS-1)

| id | capability | κατάσταση | έδρα / απόδειξη / owner | υλοποίηση | R-ids | CEILING |
|---|---|---|---|---|---|---|
| CAP-42 | event-sourced bitemporal store | HAS_SEAT | `version-graph.lisp` + `journal.lisp` | present | R-35 | 1 |
| CAP-43 | κλειστή ταξινομία 15 γεγονότων | HAS_SEAT | v1.4 §4.5 + `version-graph.lisp` | partial (7 τύποι v1.2) | R-36 | 1 |
| CAP-44 | ερώτημα valid_time | HAS_SEAT | `version-graph.lisp` snapshot-at | present | R-37 | 1 |
| CAP-45 | ερώτημα known_time | HAS_SEAT | `version-graph.lisp` (recorded-from) | present | R-38 | 1 |
| CAP-46 | EU transposition / ΔΕΕ / ΕΔΔΑ γεγονότα | HAS_SEAT | `corpus-eu-links.lisp` + `eu-interop-layer.lisp` | partial | R-36 | 8 |
| CAP-47 | constitutional review / annulment ως δικαστικά γεγονότα | HAS_SEAT | USC §6.3 kinds + `version-graph.lisp` | missing | R-36 | 7 |
| CAP-48 | δύο ανεξάρτητοι compilers, ίδια είσοδος | HAS_SEAT | Lisp compiler A + Rust compiler B | missing (B) | R-39, R-40 | — |
| CAP-49 | σύγκριση ριζών/προβολών + αυτόματη καραντίνα | HAS_SEAT | `release-gate.lisp` (EXTEND) + MLTP v3 §8.3 R4 | missing | R-41, R-42 | — |
| CAP-50 | καμία αυτο-πιστοποίηση compiler (χωριστά delegated κλειδιά) | HAS_SEAT | MLTP v3 §6 `dual_compiler_attestation` | missing | R-43 | — |
| CAP-51 | proof-carrying answer type (16 πεδία, v1.4 §4.7) | HAS_SEAT | v1.4 §4.7 + `legal-qa.lisp` | missing | R-44 | 4 |
| CAP-52 | dependency/invalidation set | HAS_SEAT | `corpus-diff.lisp` (EXTEND) | partial | R-44 | — |
| CAP-53 | τοπική επαλήθευση από provider χωρίς τυφλή εμπιστοσύνη | HAS_SEAT | MLTP v3 §8 verifier | partial (PCL-1) | R-45 | — |
| CAP-54 | τυπωμένο `UNKNOWN`/`CONFLICTING`/`UNVERIFIED_FOR_MACHINE_RELIANCE` — ποτέ απάντηση χωρίς προσδιορισμό | HAS_SEAT | v1.4 §4.7 + MLTP v3 §7 | partial | R-46, R-47 | 10 |
| CAP-55 | corpus-wide normative-impact simulator | HAS_SEAT | `graph-reasoning.lisp` + `what-if.lisp` + MLTP v3 §2.8 | partial | R-48, R-49 | 8 |
| CAP-56 | ELI-Impact προβολή | HAS_SEAT | `eu-interop-layer.lisp` (EXTEND) | missing | R-50 | 8 |

### B.5 §4.9 Jurisprudence evolution (MIS-4)

| id | capability | κατάσταση | έδρα / απόδειξη / owner | υλοποίηση | R-ids | CEILING |
|---|---|---|---|---|---|---|
| CAP-57 | σταθερή ταυτότητα απόφασης + ECLI/provisional_id | HAS_SEAT | `legal-decisions.lisp` + USC §1.4 | partial (ECLI missing, EV-4) | R-51 | 7 |
| CAP-58 | δικαστήριο/τμήμα/σύνθεση, δικονομικό ιστορικό, διάδικοι/ανωνυμοποίηση | HAS_SEAT | MLTP v3 §2.5 + `decisions.lisp` | partial | R-51 | 7 |
| CAP-59 | μηχανικές σχέσεις παραπομπής/δικονομίας (explicit-citation) | HAS_SEAT | `citation-authority.lisp` + USC §6.3 | partial | R-52 | 7 |
| CAP-60 | θεσμική ανάλυση (ratio/obiter/holding/issue/disposition/weight) με reviewer adoption | HAS_SEAT | MLTP v3 §2.6 + reviewer registry | missing | R-51, R-52, R-56 | 7 |
| CAP-61 | later treatment (7 σχέσεις) + διτεμπορικός line-of-authority γράφος + splits/outliers | HAS_SEAT | `version-graph.lisp` (EXTEND) + USC §6.3 | missing | R-53, R-54, R-55 | 7 |
| CAP-62 | authority weight μετρημένο | HAS_SEAT | MLTP v3 §2.6 `authority_weight.basis` | missing | R-51 | 7, 15 |
| CAP-63 | τέσσερις τάξεις χωριστές (source / mechanical / institutional / AI) | HAS_SEAT | v1.4 §4.9 πίνακας | partial | R-52 | 7 |

### B.6 §4.10 / §4.11 MLTP v3, trust mesh, standards (MIS-1, MIS-5)

| id | capability | κατάσταση | έδρα / απόδειξη / owner | υλοποίηση | R-ids | CEILING |
|---|---|---|---|---|---|---|
| CAP-64 | τρία επίπεδα + Layer 0 | HAS_SEAT | MLTP v3 §0–§3 | missing | R-57 | — |
| CAP-65 | typed profiles με `schema_id` παράγωγο | HAS_SEAT | MLTP v3 §1.1, §2 | missing | R-58 | — |
| CAP-66 | πλήρης δέσμευση υπογραφής | HAS_SEAT | MLTP v3 §1.2 | missing | R-59 | — |
| CAP-67 | ανεξάρτητα υπογεγραμμένο QSR | HAS_SEAT | MLTP v3 §3 | missing | R-60 | — |
| CAP-68 | αυθεντικοποιημένος χρόνος υπογραφής | HAS_SEAT | MLTP v3 §1.3 + `timestamp-authority.lisp` | partial | R-61 | — |
| CAP-69 | delegation έναντι `t_sig`, max-seq, revocation κατά kid/seq | HAS_SEAT | MLTP v3 §8.3 K2/K3/V | missing | R-62 | — |
| CAP-70 | qualification/freshness expiry | HAS_SEAT | MLTP v3 §8.3 F/Q | missing | R-63 | — |
| CAP-71 | διάκριση διόρθωσης vs ανάκλησης κλειδιού | HAS_SEAT | MLTP v3 §2.7 / §2.9 | missing | R-64 | — |
| CAP-72 | `invalid_from` / compromise / αναδρομική ανάκληση | HAS_SEAT | MLTP v3 §9 | missing | R-65 | — |
| CAP-73 | μία release root, υπογεγραμμένη, δεσμευτική | HAS_SEAT | MLTP v3 §5 + `release-authority.lisp` | partial | R-66 | — |
| CAP-74 | τοπική επαλήθευση (offline bundle) | HAS_SEAT | MLTP v3 §6, §8 | partial | R-67 | — |
| CAP-75 | κανένα issuer self-verdict (κλειστό schema) | HAS_SEAT | MLTP v3 §1.0, §8.3 βήμα 0 | missing | R-68 | — |
| CAP-76 | threshold owner root (FROST 3-of-5) | HAS_SEAT | MLTP v3 §10.2 + `authority-v2/roles` | missing | R-69 | — |
| CAP-77 | HSM-backed delegated keys σε ≥2 υποδομές | HAS_SEAT | MLTP v3 §10.2 + `keys/` custody | missing | R-69 | — |
| CAP-78 | δύο transparency services + cross-logging | HAS_SEAT | MLTP v3 §10.2 | missing | R-69 | — |
| CAP-79 | gossip + split-view detection + μονοτονία | HAS_SEAT | MLTP v3 §8.3 L | partial (tlog-verify) | R-69 | — |
| CAP-80 | ανεξάρτητοι θεσμικοί cross-client witnesses | HAS_SEAT | MLTP v3 §10.1 | missing | R-69 | — |
| CAP-81 | SCITT-compatible statements/receipts | HAS_SEAT | MLTP v3 §11 + `authority-v2/schema/*.cddl` | missing | R-69, R-71 | — |
| CAP-82 | έκτακτη/αναδρομική ανάκληση | HAS_SEAT | MLTP v3 §9.4 | missing | R-69 | — |
| CAP-83 | ELI / ECLI / Akoma Ntoso / RDF / PROV-O / SHACL εκπομπή ΚΑΙ επικύρωση | HAS_SEAT | `akoma-ntoso-emitter.lisp`, `shacl-validator.lisp`, `deployment/shapes`, `eu-interop-layer.lisp` | partial | R-71, R-72 | — |
| CAP-84 | LegalRuleML profile (μόνο mechanical norms) | HAS_SEAT | νέος emitter πάνω στο Legal IR (MISSING συστατικό) | missing | R-71 | — |
| CAP-85 | OpenAPI / MCP / CBOR-JSON προβολές | HAS_SEAT | `mcp-server.lisp` + `capability-api.lisp` + MLTP v3 §4.1 | partial | R-71, R-102, R-103 | — |
| CAP-86 | πρότυπα ≠ πηγή αλήθειας | HAS_SEAT | v1.4 §4.11 κανόνας + διτεμπορικός γράφος | present (αρχή) | R-73 | — |

### B.7 §4.12 / §4.13 App, cockpit, website, citation (MIS-6)

| id | capability | κατάσταση | έδρα / απόδειξη / owner | υλοποίηση | R-ids | CEILING |
|---|---|---|---|---|---|---|
| CAP-87 | conversation-first app (μία ενέργεια) | HAS_SEAT | `cockpit.lisp` + `cognition-legal.lisp` | partial (4 capabilities) | R-74, R-75 | — |
| CAP-88 | επιθεώρηση πηγών/αποδείξεων/αβεβαιότητας/κάλυψης/αλλαγών/διορθώσεων | HAS_SEAT | proof-carrying answer + `/api/pending` | partial | R-76 | — |
| CAP-89 | περιήγηση, σύγκριση εκδόσεων, impact, γράφοι παραπομπών/αυθεντίας | HAS_SEAT | `static-site.lisp` + `corpus-diff.lisp` + `graph-reasoning.lisp` | partial | R-77 | — |
| CAP-90 | cockpit signed intent (proposal/approval), ποτέ direct publish, ποτέ παράκαμψη M5 | HAS_SEAT | public InstitutionalAct `cockpit_intent` + M5 queue | missing (`/api/publish` άμεσο σήμερα) | R-78 | — |
| CAP-91 | RBAC/MFA | HAS_SEAT | `review-service.lisp` (EXTEND) + role registry | missing | R-79 | — |
| CAP-92 | κάθε ενέργεια journaled/επιθεωρήσιμη/ανακλητή | HAS_SEAT | L1 journal + `review-queue.lisp` + L12 | partial | R-80 | — |
| CAP-93 | ιστότοπος από το ίδιο canonical release | HAS_SEAT | `static-site.lisp` + census-2 | present | R-81 | — |
| CAP-94 | citation observatory (6 ρεύματα) εντός ορίων, aggregate | HAS_SEAT | `ai-citation-strategy.lisp` + `citation-authority.lisp` | partial (stubs) | R-82, R-83 | — |
| CAP-95 | παραπομπή ανακληθέντος υλικού — ανίχνευση | HAS_SEAT | `citation-authority.lisp` (EXTEND) | missing | R-82 | — |
| CAP-96 | μετρικές ≠ αυθεντία (εκτός MLTP) | HAS_SEAT | v1.4 §4.13 κανόνας | present (αρχή) | R-84 | — |

### B.8 §4.14 / §4.15 Security, operations, provider integration (MIS-9, MIS-5)

| id | capability | κατάσταση | έδρα / απόδειξη / owner | υλοποίηση | R-ids | CEILING |
|---|---|---|---|---|---|---|
| CAP-97 | supply-chain provenance (in-toto materials, SLSA-class) | HAS_SEAT | census-2 `materials` + `.github/workflows` (REPLACE) | partial | R-85 | — |
| CAP-98 | hermetic/αναπαραγώγιμα builds | HAS_SEAT | Dockerfile + `deps.lock` + NixOS L1+ | partial | R-86 | — |
| CAP-99 | SBOM + υπογεγραμμένα artifacts | HAS_SEAT | `docker/sbom.json` + cosign | partial | R-87, R-88 | — |
| CAP-100 | προστατευμένες διαδικασίες release | HAS_SEAT | M5 + threshold/HSM + `release-authority.lisp` | partial | R-89 | — |
| CAP-101 | ελάχιστο προνόμιο, απομόνωση μυστικών | HAS_SEAT | v1.2 §8 trust boundaries + `keys/` custody | partial | R-90, R-92 | — |
| CAP-102 | RBAC/MFA (ops) | HAS_SEAT | = CAP-91 | missing | R-91 | — |
| CAP-103 | συνεχής παρακολούθηση ευπαθειών | HAS_SEAT | SBOM scan στο CI | missing | R-93 | — |
| CAP-104 | tamper + split-view detection | HAS_SEAT | MLTP v3 §8.3 L + witnesses | partial | R-94 | — |
| CAP-105 | backups + disaster recovery (byte-ταυτόσημη ανακατασκευή) | HAS_SEAT | Q19 + PLANE-0 vault + journal | partial | R-95 | — |
| CAP-106 | multi-region όπου δικαιολογείται | HAS_SEAT | δύο ανεξάρτητες υποδομές (HSM/log) γεωγραφικά χωριστές | missing | R-96 | — |
| CAP-107 | δημόσια διαφάνεια συμβάντων/διορθώσεων | HAS_SEAT | L1 δημόσια γεγονότα + §2.7 claims | missing | R-97 | — |
| CAP-108 | μετρήσιμα SLOs (φρεσκάδα, διαθεσιμότητα, ανάκαμψη) | HAS_SEAT | SLO registry (MISSING συστατικό)· τιμές = U-1 | missing | R-98 | — |
| CAP-109 | γνήσια πράσινο, αναπαραγώγιμο CI· `BLOCKED ≠ FAIL` | HAS_SEAT | `.github/workflows` (REPLACE) + `authority-v2/run-all.sh` πρότυπο | missing (EV-12) | R-99, R-100 | — |
| CAP-110 | ελάχιστος ανοιχτός offline verifier | HAS_SEAT | `deployment/verify/*` + `kernel-verify.lisp` (EXTEND) | partial | R-101 | — |
| CAP-111 | εκδοχοποιημένο OpenAPI | HAS_SEAT | νέο αρχείο OpenAPI πάνω στο `capability-api.lisp` (MISSING συστατικό) | missing (EV-5) | R-102 | — |
| CAP-112 | versioned MCP | HAS_SEAT | `mcp-server.lisp` | partial | R-103 | — |
| CAP-113 | λεπτά SDKs (Python, TypeScript, Rust) | HAS_SEAT | περιτύλιγμα verifier (MISSING συστατικό) | missing | R-104 | — |
| CAP-114 | delta/update feeds (signed) | HAS_SEAT | `ai-corpus-dump.lisp` + `ai-ingest-manifest.lisp` + DATASET-PACKAGE-PROJECTION | partial | R-105 | — |
| CAP-115 | οδηγίες pinned-root/rotation | HAS_SEAT | TRUST-BOOTSTRAP §3 + MLTP v3 §9.3 + `deployment/verify/README.md` | partial | R-106 | — |
| CAP-116 | conformance suite + test vectors (θετικά/αρνητικά ανά error) | HAS_SEAT | `deployment/verify/vectors/` (EXTEND) | partial | R-107, R-108 | — |
| CAP-117 | κανόνες caching/ανάκλησης για providers | HAS_SEAT | v1.4 §4.15 | missing | R-109 | — |
| CAP-118 | provider-adoption qualification (ξεχωριστή, ληξιπρόθεσμη, όχι αυτο-δηλωμένη) | HAS_SEAT | MLTP v3 §3.1 + provider registry | missing | R-110 | — |

### B.9 Εγκάρσιες CORE capabilities (MIS-7, MIS-8, MIS-10)

| id | capability | κατάσταση | έδρα / απόδειξη / owner | υλοποίηση | R-ids | CEILING |
|---|---|---|---|---|---|---|
| CAP-119 | ενιαίο L1 ledger υπό turn_id / root span | HAS_SEAT | `LAWMAX-PHASE-1-TURN-ROOT-SPAN-DESIGN.md` (ΕΓΚΕΚΡΙΜΕΝΟ) | missing | R-112 | 14 |
| CAP-120 | Constitutional Compiler roundtrip (L10) | HAS_SEAT | CPEI §3 target + `architecture-gate.lisp` | partial (ratchet μόνο) | R-112 | — |
| CAP-121 | L12 approve/reject/revoke/rollback με υπογραφή | HAS_SEAT | `approval-policy.lisp` + `decisions.lisp` + `adoption-decision.lisp` | present | R-112 | 11 |
| CAP-122 | μονόδρομο όριο ως τύπος (9 απόντες τύποι, κλειστά σχήματα) | HAS_SEAT | v1.4 §1.3/§1.4 + MLTP v3 §1.0 | partial | R-111 | — |
| CAP-123 | 5 ληξιπρόθεσμες qualification καταστάσεις + αυτόματη υποβάθμιση Root Authority | HAS_SEAT | MLTP v3 §3.1 + §8.3 F/Q + v1.4 §10 | missing | R-114, R-115 | — |
| CAP-124 | dominance ανά κρίσιμη επιλογή | HAS_SEAT | `DOMINANCE-MATRIX.md` | present (design) | R-116 | — |
| CAP-125 | anti-loop πειθαρχία | HAS_SEAT | v1.4 §7 + `SUPERSEDED-REGISTER.md` | present (κανόνας) | R-117 | — |
| CAP-126 | προδηλωμένο validation programme | HAS_SEAT | Q-tests §8 | present (design) | R-118 | — |
| CAP-127 | autodidactic learning loop (evolution) | HAS_SEAT | `LAWMAX-AUTODIDACTIC-LOOP.md` + Σ11 | partial (learning ΜΗ αποδεδειγμένη) | — | 9 |
| CAP-128 | NixOS cognitive substrate L1+ | HAS_SEAT | `LAWMAX-NIXOS-COGNITIVE-SUBSTRATE.md` | blocked (σειρά δημιουργού) | R-86 | — |
| CAP-129 | τελεολογία γειωμένη σε πηγές (CEILING 15) | HAS_SEAT | `:legal-purpose` concept υπό `:law`, ΜΟΝΟ από αιτιολογικές εκθέσεις/προπαρασκευαστικές (census space R-09) | missing | R-09 | 15 |
| CAP-130 | γενεαλογία γνώσης (CEILING 14) | HAS_SEAT | L9 meta-memory + signed adoptions | partial | R-112 | 14 |

### B.9β Διευκρίνιση δημιουργού 2026-09-01 — χρονολόγια και Citation-Bound Verification Profile (MIS-5, MIS-7, MIS-8)

| id | capability | κατάσταση | έδρα / απόδειξη / owner | υλοποίηση | R-ids | CEILING |
|---|---|---|---|---|---|---|
| CAP-149 | δημόσιο νομικό χρονολόγιο `legal-timeline/1` (issued_at, published_at, effective_from, effective_to, ceased_by, cessation_type) στο payload — χωριστό από το εσωτερικό `audit-timeline/1` | HAS_SEAT | MLTP v3 §2.0 + `legal-temporal.lisp` + `version-graph.lisp` | missing | R-119, R-120 | 1 |
| CAP-150 | audit endpoint `/audit/{claim_id}` για πλήρη χρονική λογοδοσία (acquired/verified/released/corrected/revoked) — εκτός συνήθους απάντησης | HAS_SEAT | v1.4 §4.7 + `capability-api.lisp` | missing | R-121 | — |
| CAP-151 | `CertifiedResult` με `citation/1` μέσα στην υπογραφή· `citation-unbound` ⇒ `UNVERIFIED_FOR_ATTRIBUTED_RELIANCE`· διπλή παραπομπή | HAS_SEAT | MLTP v3 §2.10, §8.3 C | missing | R-122, R-123 | — |
| CAP-152 | canonical citation URLs, JSON-LD προβολή, `CitationToken`, υποχρεωτικά πεδία σε OpenAPI/MCP/SDK, default SDK rendering, conformance vectors (stripped-citation) | HAS_SEAT | `canonical-uris.lisp`, `json-emit.lisp`, `mcp-server.lisp`, `deployment/verify/vectors/` (EXTEND) | missing | R-124 | — |
| CAP-153 | παρακολούθηση συμμόρφωσης providers + υποβάθμιση `provider-adoption-qualified` / API-access ενέργεια | HAS_SEAT | `ai-citation-strategy.lisp` + `citation-authority.lisp` + MLTP v3 §3.1 | missing | R-124 | — |
| CAP-154 | POST-C2 Finding 2: cryptographic agility & long-term evidence — suite registry, crypto-policy epochs, hybrid classical/PQ (ML-DSA-65), downgrade resistance, evidence-renewal chains | UNKNOWN_WITH_OWNER_AND_DEADLINE | MLTP v3 §14 + v1.4 §4.18 | missing | R-130 | owner δημιουργός· hybrid epoch με ρητή πράξη (πριν βήμα 6) |
| CAP-155 | POST-C2 Finding 3: temporal ontology & validation governance — content-addressed bundles, receipts δεσμευμένα σε `ontology_bundle_id`+`shapes_graph_digest`, καμία αναδρομική ακύρωση | UNKNOWN_WITH_OWNER_AND_DEADLINE | MLTP v3 §2.11 + `shacl-validator.lisp` (EXTEND) + v1.4 §4.19 | missing | R-131 | owner δημιουργός· πριν βήμα 11 |
| CAP-156 | POST-C2 Finding 1: formal Legal-IR semantic contract — γλωσσο-ανεξάρτητο, conformance corpus input→derivation, δύο compilers χωρίς κοινό evaluator code | UNKNOWN_WITH_OWNER_AND_DEADLINE | `LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md` + v1.4 §4.17 | missing | R-129 | owner δημιουργός· πριν βήμα 5 (PARTIALLY CLOSED) |
| CAP-157 | POST-C2 closure: Public Source-Type Authority Registry — απαριθμήσιμο δημόσιο νομικό σύμπαν ST-01..21 + source-specific profiles/compilers | UNKNOWN_WITH_OWNER_AND_DEADLINE | `LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md` + v1.4 §4.20 | missing | R-132 | owner δημιουργός· census βήμα 1 (U-7 εύρος) |
| CAP-158 | POST-C2 closure: Secure Semantic Ingress — external bytes ≠ Lisp forms· taint states· sandboxed parsing· SIK-1..9 | UNKNOWN_WITH_OWNER_AND_DEADLINE | `LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md` + `safe-read.lisp` (EXTEND) + v1.4 §4.21 | missing | R-133 | owner δημιουργός· βήμα 2/7 |
| CAP-159 | POST-C2 closure: Nation-state compromise-tolerant security — single-zone compromise ≠ canonical authority· ανιχνεύσιμη/περιορισμένη/αναστρέψιμη | UNKNOWN_WITH_OWNER_AND_DEADLINE | MLTP v3 §10.2/§14.4 + v1.4 §4.22/§4.14 | missing | R-134 | owner δημιουργός· βήμα 6 |

### B.10 EXCLUDED_WITH_PROOF — τι ΔΕΝ είναι capability του δημόσιου στόχου

| id | capability | κατάσταση | απόδειξη |
|---|---|---|---|
| CAP-131 | blockchain anchoring/consensus στον πυρήνα | EXCLUDED_WITH_PROOF | `DOMINANCE-MATRIX.md` D-11: δεν κυριαρχεί των witnessed logs σε κανέναν άξονα, χειρότερο σε αναπαραγωγιμότητα/διακυβέρνηση· PROOF-OBJECT §5 |
| CAP-132 | ZK-SNARK/STARK proofs | EXCLUDED_WITH_PROOF | κρύβουν τον συλλογισμό — αντίθετο στο proof-carrying αξίωμα (PROOF-OBJECT §5)· D-11 |
| CAP-133 | W3C VC/DID ως CORE trust layer | EXCLUDED_WITH_PROOF | JSON-LD canonicalization στο trusted path· δεν κυριαρχεί του MLTP v3 + SCITT (D-10/D-11)· επιτρεπτό μόνο ως προαιρετικό envelope |
| CAP-134 | LLM στο trusted path (μνήμη, κανόνας, οντολογία, release) | EXCLUDED_WITH_PROOF | Σύνταγμα `:no-llm-trusted-path`· CPEI αξίωμα· v1.4 §4.3 never-list |
| CAP-135 | πρόβλεψη έκβασης υπόθεσης («Χ% νίκη») | EXCLUDED_WITH_PROOF | CEILING Level 13 δόγμα (δεσμευτικό)· ιδιωτικός τύπος `case-specific prediction` (v1.4 §1.3) |
| CAP-136 | Matter / Client / case file / privileged material / private strategy / opponent modelling / matter-specific simulation / private use telemetry | EXCLUDED_WITH_PROOF | δομικά απόντες τύποι (v1.4 §1.3)· Q20 witness «δεν μεταγλωττίζεται» |
| CAP-137 | N-version agreement ως admission predicate | EXCLUDED_WITH_PROOF | KT10 φρουρός (v1.2 M5)· Q11 (β)· D-12 |
| CAP-138 | παραγωγή νομικής συμβουλής / υπαγωγή ιδιωτικών γεγονότων στο δημόσιο προϊόν | EXCLUDED_WITH_PROOF | private profile (Σ4–Σ9 του ΧΑΡΤΗ-ΝΟΗΣΗΣ)· `legal-subsumption.lisp` κ.λπ. DEFER_PRIVATE |
| CAP-139 | «Primary Semantic Authority» / μηχανικά αναγνώσιμο `PRIMARY_SEMANTIC_AUTHORITY` | EXCLUDED_WITH_PROOF | ασύμβατο με MIS-8 (AS-IS EV-11, P0 εύρημα τιμιότητας — προς αποκατάσταση στο βήμα 0) |
| CAP-140 | παρατήρηση ιδιωτικής δραστηριότητας χρηστών/providers (τηλεμετρία ταυτοποίησης) | EXCLUDED_WITH_PROOF | Q16/Q20· private use telemetry = απών τύπος |

### B.11 UNKNOWN_WITH_OWNER_AND_DEADLINE — οι ανοιχτές αποφάσεις (ίδιες με v1.4 §12)

| id | capability / απόφαση | κατάσταση | owner | προθεσμία |
|---|---|---|---|---|
| CAP-141 | αριθμητικά κατώφλια (OCR/εξαγωγή, latency, SLO, `max_staleness`) — U-1 | UNKNOWN_WITH_OWNER_AND_DEADLINE | δημιουργός + μέτρηση βήματος 0/1 | έξοδος βήματος 1 |
| CAP-142 | ταυτότητα registries (auditors, reviewers, cross-client witnesses, providers) — U-2 | UNKNOWN_WITH_OWNER_AND_DEADLINE | δημιουργός | πριν το βήμα 6 |
| CAP-143 | άδεια/πνευματικά δικαιώματα νομολογίας τρίτων και θεωρίας — U-3 | UNKNOWN_WITH_OWNER_AND_DEADLINE | δημιουργός (νομική γνωμοδότηση) | πριν το βήμα 9 |
| CAP-144 | επαλήθευση benchmark έναντι ζωντανών πρωτογενών πηγών — U-4 | UNKNOWN_WITH_OWNER_AND_DEADLINE | δημιουργός ή validation pass 2 | πριν το pass 2 |
| CAP-145 | Rust vs OCaml για compiler B — U-5 | UNKNOWN_WITH_OWNER_AND_DEADLINE | δημιουργός | πριν το βήμα 5 |
| CAP-146 | held-out σύνολο Q04 — U-6 | UNKNOWN_WITH_OWNER_AND_DEADLINE | δημιουργός | πριν το βήμα 7 |
| CAP-147 | ποια δικαστήρια εκδίδουν νομίμως δημοσιεύσιμες αποφάσεις (μέγεθος census) — U-7 | UNKNOWN_WITH_OWNER_AND_DEADLINE | δημιουργός + census | έξοδος βήματος 1 |
| CAP-148 | AS-IS R-1 έως R-6 (REPORTED) — U-8 | UNKNOWN_WITH_OWNER_AND_DEADLINE | βήμα 0 | έξοδος βήματος 0 |

**Ισολογισμός §B:** 159 capabilities · HAS_SEAT **135** · EXCLUDED_WITH_PROOF **10** ·
UNKNOWN_WITH_OWNER_AND_DEADLINE **14** · καμία χωρίς κατάσταση (POST-C2: +CAP-154/155/156,
+CAP-157/158/159· UNKNOWN 8→14). Υλοποίηση σήμερα
(επί των 135 HAS_SEAT): `present` **19** · `partial` **51** · `missing` **64** ·
`blocked` **1**. Η καταμέτρηση επαληθεύεται μηχανικά από τον
`V1.4-CONTRADICTION-OMISSION-AUDIT.sh`.

---

## C. ΔΙΟΡΘΩΣΗ ΤΟΥ ΣΤΑΣΙΜΟΥ ΠΕΡΙΓΡΑΦΕΑ (RC-16)

Η γραμμή του v1.3 crosswalk «minimal offline verifier (6 γραμμές, SHA-256 μόνο) |
PCL §5-6 | REUSE» **αντικαθίσταται** από: «offline verifier = PCL §5 `inclusion()`
(SHA-256, RFC 9162) **+** `authentic()` (RS256, era-1) **+** MLTP v3 §8.3 (Ed25519/RS256
signatures, RFC-3161 time, delegation, witnesses, revocation, qualification) |
`PROOF-CARRYING-LAW.md` + `MACHINE-LEGAL-TRUST-PROTOCOL.md` | **EXTEND**». Ο
ελεγκτής είναι μικρός (LOC-ceiling) αλλά **δεν είναι hash-only**.
