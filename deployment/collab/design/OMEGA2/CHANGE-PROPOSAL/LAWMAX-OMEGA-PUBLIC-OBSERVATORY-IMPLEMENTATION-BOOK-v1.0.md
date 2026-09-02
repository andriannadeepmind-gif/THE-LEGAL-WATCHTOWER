# LAWMAX OMEGA — PUBLIC OBSERVATORY IMPLEMENTATION BOOK v1.0

**ΚΑΤΑΣΤΑΣΗ: `IMPLEMENTATION BOOK COMPLETE — EXECUTION NOT AUTHORIZED`.**

Δεσμευμένο **αποκλειστικά** στο παγωμένο SHA:
```
BOUND_FROZEN_SHA = 88129099be1ad69feb80d40337ede6c286b83223
FREEZE_MANIFEST   = SPEC-FREEZE-MANIFEST-v1.4.md (ίδιος κατάλογος)
BOOK_LEVEL        = IMPLEMENTATION-BOOK (στάδιο 4b· ΜΕΤΑ το SPEC FREEZE, ΠΡΙΝ κάθε refactoring)
```

Αυτό το Βιβλίο **δεν** εισάγει νέα αρχιτεκτονική, νέο axis ή νέο «ανώτερο επίπεδο». Μεταφράζει τα
**NORMATIVE** αρχεία του freeze (`SPEC-FREEZE-MANIFEST-v1.4.md §3`) σε **εκτελέσιμη σειρά work
packets**. Κάθε στοιχείο του ανιχνεύεται πίσω σε παγωμένο Requirement/Seat. **Καμία γραμμή κώδικα
δεν έχει γραφτεί, μετακινηθεί ή αναδιαμορφωθεί.** Η υλοποίηση **δεν** αρχίζει πριν τη χωριστή
εντολή `ΕΓΚΡΙΝΩ IMPLEMENTATION BOOK — ΞΕΚΙΝΑ WORK PACKET 0`.

**Πηγές αλήθειας (single seat ανά έννοια — το Βιβλίο τις αναφέρει, δεν τις αντιγράφει):**
απαιτήσεις `TRACEABILITY-MATRIX.md` (R-01..134)· υποσυστήματα/κλείσιμο `ARCHITECTURE-CLOSURE-MATRIX.md`
(18 subsystems, closure-WP 01..18)· σειρά/πύλες `IMPLEMENTATION-SEQUENCE.md` (βήματα 0–14)· φέτες
`VERTICAL-SLICES.md` (VS-01..15)· inventory/dispositions `PUBLIC-OBSERVATORY-CROSSWALK.md §A`·
capabilities §B (CAP-01..159)· δοκιμές `PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md` (Q01..43, KW-1..109)·
πρωτόκολλο `MACHINE-LEGAL-TRUST-PROTOCOL.md` (MLTP v3)· θεμέλια εμπιστοσύνης manifest §3.2/§3.3.

## §0. ΟΡΙΟ, ΜΗ-ΣΤΟΧΟΙ, ΚΑΝΟΝΕΣ

- **Όριο υλοποίησης:** μόνο ο **CPEI PUBLIC OBSERVATORY PROFILE**. Οι 9 ιδιωτικοί ΤΥΠΟΙ και τα
  `DEFER_PRIVATE` συστατικά **απουσιάζουν δομικά** (μονόδρομο `PUBLIC → PRIVATE`, v1.4 §1.3/§1.4).
- **Μη-στόχοι:** καμία αναζήτηση νέας αρχιτεκτονικής/axis/swarm/destruction· κανένα freeze
  αρχείου· καμία διεκδίκηση βαθμίδας (`SPEC/IMPLEMENTATION/MISSION/SECURITY QUALIFIED` υπογράφονται
  από **ανεξάρτητους** auditors, όχι από τον υλοποιητή, MLTP v3 §3.1).
- **De jure όριο:** η αυθεντία παραμένει **πάντα** στο Κράτος/ΦΕΚ/ΕΕ/δικαστήρια (MIS-8). Το σύστημα
  παρατηρεί, δεν νομοθετεί.
- **Κανόνας κάθε βήματος (μόνιμο συμβόλαιο):** ένας κλάδος ανά WP → plan → ρητή έγκριση δημιουργού →
  υλοποίηση → εσωτερική αντιπαλική επιθεώρηση → κλείσιμο ευρημάτων → πλήρες proof (gates/tests/audits
  με αριθμούς) → owner docker proof → ρητή εντολή merge δημιουργού. `BLOCKED ≠ FAIL`.
- **Νέο counterexample:** μόνο **αναπαραγώγιμο P0** (εσωτερική αδυνατότητα/αντίφαση/κρίσιμο κενό
  ασφαλείας) επιτρέπει αρχιτεκτονική αλλαγή — ως **νέα έκδοση** με ονομαστικό falsifier, ποτέ σιωπηλά.

## §1. ΣΥΝΤΑΓΜΑΤΙΚΗ ΑΡΧΗ ΚΑΙ Ο ΑΓΩΓΟΣ ΠΡΟΑΓΩΓΗΣ

> **«Ελεύθερη διακλάδωση στη νομική σκέψη· μονόδρομη, υπογεγραμμένη και αποδεικτική προαγωγή στην
> κανονική δημόσια κατάσταση.»**

Ο **μοναδικός** αγωγός προαγωγής (μονότονος, μη αναστρέψιμος — καμία κατάσταση δεν παρακάμπτεται·
κάθε μετάβαση journaled στο L1):

```
RAW ──parse──▶ CANDIDATE ──symbolic validate──▶ VALIDATED ──adopt (InstitutionalAct)──▶ ADOPTED ──dual-compile + M5 sign──▶ PUBLISHED
(UNTRUSTED)     (PARSED)                          (VALIDATED)                              (ADOPTED)                          (CANONICAL)
```

| στάδιο | είσοδος | έδρα ελέγχου | τι αποδεικνύεται | ποτέ |
|---|---|---|---|---|
| **RAW** | opaque bytes (PDF/XML/HTML/OCR/JSON/feed) | Secure Semantic Ingress (WP-02) | τίποτα· καμία ικανότητα | ποτέ Lisp form· ποτέ eval |
| **CANDIDATE** | `parser-result/1` ή `neural-candidate/1` | non-evaluating decoder + neural wall (WP-02/03) | δομή· ΟΧΙ εμπιστοσύνη/πρόθεση | ποτέ αυτο-προαγωγή από neural (I-4.3a) |
| **VALIDATED** | typed Legal IR | structural + symbolic validator (WP-04) | schema conformance + δηλωμένο typing/invariants | ΟΧΙ καλόπιστη πρόθεση· ΟΧΙ αυθεντικότητα |
| **ADOPTED** | reviewer/InstitutionalAct | adoption policy + authority/competence (WP-09/12) | εξουσιοδοτημένη υιοθέτηση | ποτέ ratio χωρίς adoption act |
| **PUBLISHED** | signed release | dual compiler + M5 + MLTP v3 (WP-05/06) | provenance + dual-root ισότητα + υπογραφή | ποτέ single-attestation release |

**Αρχή honesty:** VALIDATED **δεν** σημαίνει έμπιστο. Ένα schema-valid κακόβουλο candidate **μπορεί**
να περάσει structural+symbolic validation αλλά **μένει μη-CANONICAL** χωρίς provenance + authority +
adoption policy ⇒ **καμία προαγωγή, μηδενική παρενέργεια** (SECURE-SEMANTIC-INGRESS-CONTRACT §4,
SIK-8/9). Απάντηση χωρίς proof ⇒ `UNKNOWN` (τίμια άγνοια), ποτέ εικασία.

## §2. ΚΑΤΑΛΟΓΟΣ ΥΠΟΣΥΣΤΗΜΑΤΩΝ — ΜΙΑ ΕΔΡΑ, ΜΙΑ ΕΥΘΥΝΗ (18 subsystems)

Πηγή: `ARCHITECTURE-CLOSURE-MATRIX.md §1` (18 γραμμές, καμία ορφανή). Κάθε subsystem = μία ευθύνη,
μία contract-έδρα, μία repository seat, μία closure-WP.

| S | subsystem | ευθύνη (μία) | contract έδρα | closure-WP | Book WP (εκτέλεση) |
|---|---|---|---|---|---|
| S1 | National Legal Census / Radar | απαρίθμηση σύμπαντος + ολική κάλυψη | v1.4 §4.1 + Source-Type Registry | WP-01 | WP-01 |
| S2 | Multimodal acquisition | opaque bytes → σφραγισμένο manifestation | v1.4 §4.2 + Secure Ingress | WP-02 | WP-02, WP-07 |
| S3 | Neuro-symbolic bridge | neural candidate → symbolic gate (epistemic wall) | v1.4 §4.3/§4.4 | WP-03 | WP-07 |
| S4 | Symbolic Common Lisp core | typed Legal IR + WFS + conflict eval | Legal-IR Semantic Contract | WP-04 | WP-03, WP-08 |
| S5 | Bitemporal Legal Digital Twin | valid-time × audit-time κατάσταση | v1.4 §4.5 + MLTP §2.0 | WP-05 | WP-03, WP-10 |
| S6 | Unified legal hypergraph | σχέσεις (explicit-citation) | USC §6 | WP-06 | WP-10 |
| S7 | Jurisprudence evolution plane | τέσσερις τάξεις + line-of-authority | v1.4 §4.9, MLTP §2.5/2.6 | WP-07 | WP-09 |
| S8 | Dual independent compilation | δύο ρίζες, καμία κοινή evaluator | v1.4 §4.6, MLTP §13.4 | WP-08 | WP-04, WP-05 |
| S9 | Proof-carrying query engine | proof-carrying-answer ή UNKNOWN | v1.4 §4.7 | WP-09 | WP-11 |
| S10 | MLTP trust layer + crypto agility | pinned root, profile pinning, epochs | MLTP v3 §13/§14 | WP-10 | WP-06 |
| S11 | Nation-state security cells | single-zone ≠ canonical authority | v1.4 §4.22, MLTP §10.2/§14.4 | WP-11 | WP-06, WP-11(sec) |
| S12 | Cockpit | signed intent → M5 (ποτέ direct-publish) | v1.4 §4.12/§1.4 | WP-12 | WP-12 |
| S13 | Public search + website | ιστότοπος = προβολή, ποτέ δεύτερη πηγή | v1.4 §4.12 (URL topology) | WP-13 | WP-12 |
| S14 | OpenAPI / MCP / SDKs / feeds | citation-bound διεπαφές | v1.4 §4.15/§4.16 | WP-14 | WP-11 |
| S15 | Observatories (citation/security/coverage) | metrics ≠ legal correctness | v1.4 §4.13/§4.14 | WP-15 | WP-13 |
| S16 | Source-type authority registry | ST-01..28 + UNKNOWN + encoding profiles | Source-Type Registry | WP-16 | WP-01, WP-07 |
| S17 | Ontology & validation governance | ontology version binding | MLTP §2.11 | WP-17 | WP-07 |
| S18 | Public→private boundary | 9 απόντες ιδιωτικοί τύποι (structural) | v1.4 §1.3/§1.4 | WP-18 | WP-12 |

### §2.1 Σύνθετα υποσυστήματα (ονομασμένα, χωρίς νέα έδρα — συνθέσεις των S1–S18)
- **CPEI CONSTITUTIONAL CORE** (shared): S18 + οι 12 στρώσεις L1–L12 + InstitutionalAct + Constitutional
  Compiler target. Έδρα: `LAWMAX-CPEI-TARGET-SPEC.{md,sexp}` (frozen). Ο public profile **το εφαρμόζει**,
  δεν το τροποποιεί.
- **PUBLIC OBSERVATORY PROFILE**: το σύνολο S1–S17 όπως ενορχηστρώνονται από τα βήματα 0–14.
- **PUBLIC LEGAL DISCERNMENT ENGINE** (διακριτό end-to-end): S3+S4+S6+S7+S9 — ο αγωγός
  `acquired law → typed Legal IR → WFS/deontic/conflict reasoning → jurisprudence weighting →
  proof-carrying answer ή typed UNKNOWN`. Καμία νέα έδρα· ενορχήστρωση των υπαρχουσών (WP-08/09/11).
  Το «discernment» = **αποδεικτική διάκριση** (IN/OUT/UNKNOWN με proof ή τίμια αποχή), ποτέ εικασία.
- **EVENT LEDGER (L1)**: `journal.lisp` (REUSE) — append-only, κλειστός κατάλογος 15 γεγονότων, κάθε
  μετάβαση taint journaled. Έδρα εγγραφής: **μία** (`write-authority.lisp`).
- **BITEMPORAL LEGAL HYPERGRAPH (L2)**: `version-graph.lisp` + `legal-hypergraph.lisp` (EXTEND) —
  `valid × known`, `rel1:` explicit-citation σχέσεις, line-of-authority.
- **NATIONAL LEGAL DIGITAL TWIN (L7)**: corpus-wide `normative-impact-projection` με `replay_manifest`
  (WP-10) — προβολή, όχι δεύτερη πηγή αλήθειας.

## §3. ΤΟΠΟΛΟΓΙΑ — ΛΟΓΙΚΗ, ΦΥΣΙΚΗ, TRUST BOUNDARIES, ΚΑΤΕΥΘΥΝΣΕΙΣ ΔΕΔΟΜΕΝΩΝ

### §3.1 Planes (επίπεδα εμπιστοσύνης — μονότονη ροή)
```
PLANE-0  vault (bytes + journal, cold)        ── μόνο πηγή αλήθειας· ό,τι χαθεί = UNKNOWN, ποτέ cache-fill
   │  (read)
PLANE-1  derived (projections, IR, releases)  ── αναπαράξιμο από PLANE-0 + journal
   │  (read)
PLANE-2  public services (API/site/feeds)      ── προβολή· ποτέ δεύτερη πηγή
PLANE-3  neural runtime (external, sandboxed)   ── ΜΗ έμπιστο· candidate-only· καμία εγγραφή στο journal
```
**Επιτρεπόμενες κατευθύνσεις (μονόδρομες):** PLANE-3 → (non-evaluating decoder) → CANDIDATE → (symbolic
gate) → PLANE-1· PLANE-0 → PLANE-1 → PLANE-2· **ποτέ** PLANE-2/3 → PLANE-0· **ποτέ** external bytes →
Lisp reader/eval. `write-authority.lisp` = **μία** έδρα εγγραφής στο journal.

### §3.2 Module / process / container / security-cell / public-service (διακριτά)
| επίπεδο | ορισμός | παραδείγματα | απομόνωση |
|---|---|---|---|
| **module** | ένα `.lisp`/`.rs` αρχείο, μία ευθύνη | `legal-ast.lisp`, `version-graph.lisp` | package boundary |
| **process** | ένα εκτελέσιμο (Lisp core, Rust compiler, neural runtime, verifier) | compiler A, compiler B, neural sandbox | OS process· neural = out-of-process, capability-less |
| **container** | hermetic image (Dockerfile + deps.lock + SBOM) | core-runtime, site, cockpit, verifier | byte-ταυτόσημο ×2 (WP-00) |
| **security cell** | ζώνη κλειδιών/custody (single-zone ≠ canonical authority) | HSM/threshold root cell, witness cells | n-of-m + witnesses (WP-06/WP-11sec) |
| **public service** | εκτεθειμένο endpoint (προβολή) | `/lawmax/{path}` site, OpenAPI, MCP, feeds | cell isolation· site breach ≠ legal root |

### §3.3 Φυσικό deployment (λογικό → φυσικό)
- **Ingestion cell** (WP-01/02/07): radar + acquisition + sandboxed parsers + neural runtime (PLANE-3,
  out-of-process). Έξοδος: `ingress-envelope/1` → PLANE-1.
- **Reasoning cell** (WP-03/04/08/09/10): Legal IR, event store, hypergraph, compilers A/B, impact.
- **Trust cell** (WP-06/11sec): MLTP v3 root, HSM/threshold custody, witnesses, logs — **απομονωμένη**·
  single-zone compromise ≠ canonical authority.
- **Public cell** (WP-12/13/14): site `/lawmax/{path}`, cockpit, OpenAPI/MCP/SDK, feeds — προβολή μόνο.
- **Observatory cell** (WP-15): collectors (ή typed UNKNOWN), SLO/DR/incident.

## §4. ΠΛΗΡΕΣ REPOSITORY INVENTORY + DISPOSITION ΑΝΑ ΑΡΧΕΙΟ

**Single seat:** `PUBLIC-OBSERVATORY-CROSSWALK.md §A` απαριθμεί **κάθε** υπάρχον συστατικό με **μία**
disposition (§A.1 arch docs· §A.2 canonical texts· §A.3 `source/` 133 αρχεία· §A.4
`systems/orchestrator-cli/` 48 αρχεία· §A.5 verify/authority/docker/scripts/CI). Το Βιβλίο **δεν**
αντιγράφει τις 181 γραμμές (θα ήταν δεύτερη έδρα)· τις **δεσμεύει** και δίνει τον ισολογισμό +
την αντιστοίχιση λεξιλογίου.

### §4.1 Ισολογισμός disposition (crosswalk §A) → λεξιλόγιο Βιβλίου
| crosswalk disposition | πλήθος | Book vocabulary | σημασία εκτέλεσης |
|---|---|---|---|
| `REUSE` | 155 | **KEEP** | αμετάβλητο· καταναλώνεται ως έχει (μετά επαλήθευση AS-IS) |
| `EXTEND` | 75 | **MODIFY** | επεκτείνεται στην ίδια έδρα· καμία δεύτερη έδρα |
| `REPLACE` | 7 | **REPLACE** | αντικαθίσταται (π.χ. `.github/workflows` μέχρι πράσινο, `/api/publish`) |
| `REMOVE` | 4 | **REMOVE** | αφαιρείται αξίωση/κώδικας (π.χ. `PRIMARY_SEMANTIC_AUTHORITY`) |
| `DEFER_PRIVATE` | 8 | **KEEP (deferred)** | ιδιωτικό profile· **δεν αγγίζεται** στη δημόσια εκτέλεση |
| `MISSING` | (καταγεγραμμένα §B/§A.5) | **NEW** | net-new έδρα (γράφεται στο δηλωμένο WP) |
| — | 0 | **MOVE** | **καμία μετακίνηση** — όλες οι έδρες μένουν στη θέση τους· τα νέα είναι NEW, όχι MOVE |

**Κανόνας inventory:** κανένα υπάρχον αρχείο χωρίς disposition (audit «αρχείο χωρίς classification» =
superseded register· crosswalk 181/181)· κανένα MISSING χωρίς WP ιδιοκτήτη (§10)· `DEFER_PRIVATE`
(`legal-hypo.lisp`, `legal-precedent.lisp`, `legal-casegrammar.lisp`, `legal-strategy.lisp`,
`legal-subsumption.lisp` ιδιωτικών γεγονότων, `case-workspace.lisp`, `draft-commands.lisp`,
`legal-eval.lisp`) = **κανένα WP δεν τα αγγίζει**.

### §4.2 MISSING → NEW έδρα → WP ιδιοκτήτης (net-new, από `IMPLEMENTATION-SEQUENCE §σύνοψη`)
coverage ledger (WP-01)· census `RegistrySnapshot`, `coverage-and-freshness` (WP-01)· `authority-proof/2`,
custody chain, audiovisual manifestation (WP-02)· non-evaluating JSON/CBOR decoder + ingress sandbox
(WP-02)· protocol schema + neural runtime + OCR path (WP-07)· Rust compiler B + differential harness
(WP-05)· threshold signing, δεύτερο log, cross-client witness registry, SCITT projection, Rust verifier
(WP-06)· `proof-carrying-answer/1` type, OpenAPI, SDKs, LegalRuleML emitter, `/audit` endpoint,
conformance suite (WP-11)· ECLI, reviewer registry + adoption act, line-of-authority graph (WP-09)·
`replay_manifest`, `normative-impact-projection` (WP-10)· RBAC/MFA registry, app shell (WP-12)·
revoked-material detector, provider compliance monitor, SLO registry, vulnerability monitoring, DR
runbook, incident feed (WP-13)· provider registry (WP-14 mission).

## §5. ΓΡΑΦΟΣ ΕΞΑΡΤΗΣΕΩΝ (ΑΚΥΚΛΙΚΟΣ) + ΣΕΙΡΑ WORK PACKETS

Πηγή: `IMPLEMENTATION-SEQUENCE §ΓΡΑΦΟΣ`. Οι κόμβοι είναι τα Book WP-00..WP-14 (= βήματα 0–14). Ο
γράφος είναι **DAG** (καμία κυκλική εξάρτηση· επαληθευμένο §11.5).

```
WP-00 ─▶ WP-01 ─▶ WP-02 ─▶ WP-03 ─▶ WP-04 ─▶ WP-05 ─┐
                    │        │        └─▶ WP-10 ─┐   ├─▶ WP-11 ─▶ WP-12 ─▶ WP-13 ─▶ WP-14
                    └─▶ WP-07 ─▶ WP-08 ─▶ WP-09 ─┘   │
                                          WP-06 ─────┘
```
Ρητές ακμές: 0→1→2→3→4→5· 2→7→8→9· 4→10· 4→6· {5,6,10}→11→12→13→14. Παραλληλία: WP-05 ‖ WP-06 ‖ WP-07
(μετά 4/2)· WP-08 ‖ WP-10· WP-09 μετά WP-08. Κρίσιμο μονοπάτι: **0→1→2→3→4→6→11→12→13→14**.
**Μπλοκ από U-n:** WP-01 (U-7 έξοδος, U-1 budgets)· WP-05 (U-5)· WP-06 (U-2)· WP-07 (U-6)· WP-09 (U-3)·
U-4 (πάσο πριν από κάθε WP)· U-8 (έξοδος WP-00).

## §6. SCHEMAS / APIs / MCP / SDK / COCKPIT / WEBSITE (contracts — single seat ανά τύπο)

- **Envelopes/schemas** (κλειστοί τύποι): `ingress-envelope/1`, `parser-result/1`, `neural-candidate/1`
  (Secure Ingress §2)· `legal-timeline/1` (payload) ≠ `audit-timeline/1` (proof)· `proof-carrying-answer/1`
  (11 πεδία §3.F, v1.4 §4.7)· `CertifiedResult` + `citation/1` + `CitationToken` (MLTP §2.10, §4.16)·
  `IssuedClaim`/`TrustBundle`/`VerificationReceipt` (MLTP)· `SourceTypeSchema/1`+`SourceTypeEntry`·
  `ontology-bundle`+`shacl-validation-receipt` (MLTP §2.11)· `PQRootSet`+`crypto-policy-epoch` (§14).
- **API/MCP/SDK** (WP-11): εκδοχοποιημένο OpenAPI· versioned MCP (`mcp-server.lisp` EXTEND: υποχρεωτικό
  `citation`)· λεπτά SDKs (Python/TypeScript/Rust) με **default** rendering διπλής παραπομπής·
  `/audit/{claim_id}`· conformance suite (προαιρετικό `citation` ⇒ conformance FAIL).
- **Cockpit** (WP-12): `cockpit_intent` κλειστό, RBAC/MFA· `/api/publish` → **approval intent στην ουρά
  M5** (REPLACE)· ποτέ direct-publish (VS-14, KW-57).
- **Website** (WP-12): `static-site.lisp` (REUSE)· canonical URL `/lawmax/{path}` (ένα ανά Legal Object)·
  ιστότοπος = προβολή του ίδιου canonical release· site cell isolation (breach ≠ legal root).
- **Standards** (WP-11): ELI, ECLI, Akoma Ntoso, RDF/PROV-O, SHACL, LegalRuleML (μόνο mechanical),
  SCITT· signed delta feeds.

## §7. SOURCE PROFILES ΑΝΑ ΚΑΤΗΓΟΡΙΑ ΔΙΚΑΙΟΥ/ΝΟΜΟΛΟΓΙΑΣ (WP-16 → WP-01/WP-07)

Single seat: `LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md` (ST-01..28 + `ST-UNKNOWN` fail-closed).
Κάθε `SourceTypeEntry` → source-specific collector → profile → compiler → κοινό Legal Object + **μη
εκτελέσιμο** Legal IR. Οι **οκτώ ορθογώνιες** typed διαστάσεις (`normative_tier`·`procedure_kind`·
`binding_force`·`applicability_mode`·`direct_effect_status`·`addressee_scope`·`classification_rule`·
`authority_evidence`) είναι κλειστά enums· κάθε ουσιαστική ταξινόμηση **`PENDING_LEGAL_VALIDATION`**
μέχρι MISSION legal review (evidence κατηγορία [3], **όχι** ο document audit). Profiles-έδρες (EXTEND,
μία ανά profile): `legislation-ingestion.lisp`, `government-source.lisp`, `legal-decisions.lisp`,
`eu-interop-layer.lisp`, `pdf-authority.lisp`, `legal-ast.lisp`. `UNKNOWN_SOURCE_TYPE` = fail-closed
(κάθε μη-ταξινομημένη μορφή επιφαίνεται, ποτέ σιωπηλά χαμένη).

## §8. ΑΣΦΑΛΕΙΑ / RECOVERY / KEY MANAGEMENT / OBSERVABILITY / INCIDENT (WP-06/WP-11/WP-13)

- **Key management** (WP-06): TUF-class roles (`LAWMAX-KEY-LIFECYCLE-SPEC`)· kid/alg/lineage·
  rotation/revocation/succession· owner root ceremony (`LAWMAX-TRUST-BOOTSTRAP-SPEC`)· delegated keys
  ανά scope· **independent n-of-m ML-DSA multisignature** PQ root (`PQRootSet`, ΟΧΙ threshold ML-DSA)·
  classical FROST-Ed25519· hybrid **AND** (valid classical + invalid/missing PQ ⇒ reject, KW-104).
- **Nation-state security** (WP-11sec): single-zone ≠ canonical authority· HSM/threshold custody·
  δύο logs· cross-client witness registry· ΟΧΙ «unhackable» (compromise-tolerant, v1.4 §4.22, Θ17/Θ18).
- **Recovery/DR** (WP-13, VS-15): ψυχρή ανακατασκευή από PLANE-0 + journal ⇒ byte-ταυτόσημο
  `release_root`· απώλεια PLANE-0 = typed `UNKNOWN`, ποτέ cache-fill· RTO/RPO μετρημένα (U-1).
- **Observability** (WP-13): collectors **ή** typed `UNKNOWN` (ποτέ stub που αναφέρει «0»)· SLO registry·
  vulnerability monitoring· δημόσιο incident feed· split-view drill.
- **Crypto agility** (WP-06/§14): suite registry· policy epochs· downgrade resistance· evidence-renewal
  chains· verifier ανά εποχή (`crypto-policy-epoch`, MLTP §14, Θ15).

## §9. MIGRATIONS + ROLLBACK (καθολική στρατηγική· ανά-WP στο §10)

- **Καθολικός κανόνας migration:** κάθε WP που εισάγει τύπο/schema/root κάνει **forward migration μόνο
  προσθετικά** (νέος κλειστός τύπος, νέο event kind, νέα epoch) — ποτέ αναδρομική μετάλλαξη υπάρχοντος
  υπογεγραμμένου record (acyclic id + no retroactive invalidation, MLTP §2.11). Τα παράγωγα PLANE-1
  αναπαράγονται από PLANE-0 + journal.
- **Καθολικός κανόνας rollback:** κάθε WP δουλεύει σε **δικό του κλάδο**· rollback = εγκατάλειψη κλάδου
  πριν το merge (καμία επίδραση σε main). Μετά το merge, rollback = **αντίστροφο** commit + επαναφορά
  του προηγούμενου signed release (PLANE-0 αμετάβλητο· τα PLANE-1 αναπαράγονται). Κανένα rollback δεν
  αγγίζει PLANE-0 bytes ή το append-only journal (μόνο προσθέτει `REVERT`/`QUARANTINE` γεγονός).
- **Reproducible substrate (L11):** hermetic build byte-ταυτόσημο ×2 (WP-00) ⇒ κάθε rollback
  αναπαράγει την προηγούμενη εικόνα από digest.

## §10. ΤΑ WORK PACKETS — WP-00 ΕΩΣ WP-14

Κάθε WP φέρει και τα **δέκα** πεδία. `Requirement` = R-range (`TRACEABILITY-MATRIX`) + closure-WP.
`Seat` = subsystem/contract. `Paths/symbols` = αρχεία (disposition). `Interfaces` = κλειστοί τύποι.
`Changes` = KEEP/MODIFY/REPLACE/REMOVE/NEW. `Tests/kill` = Q + KW + VS. `Migration`/`Rollback` κατά §9.
`Evidence` = μετρήσιμο bundle. `Exit gate` = δυαδικό κριτήριο (η πύλη εισόδου του επόμενου).

---
### WP-00 — Καθαρή αναπαραγώγιμη βάση + γνήσια πράσινο CI
- **Requirement:** AS-IS R-1..R-6 (U-8)· R-85, R-86, R-87, R-88, R-99, R-100 (§4.14 build/CI/SBOM/provenance)· closure: προϋπόθεση όλων.
- **Architecture seat:** S11/S15 (substrate/observability) — reproducible substrate (L11).
- **Paths/symbols:** `.github/workflows` (REPLACE μέχρι πράσινο)· `Dockerfile`+`deps.lock`+`docker/sbom.json`+`docker/cosign.pub` (KEEP)· `authority-v2/run-all.sh` (KEEP πρότυπο)· `semantic-authority.lisp`/`PRIMARY_SEMANTIC_AUTHORITY` (REMOVE αξίωση, CAP-139).
- **Interfaces:** image digest· SBOM· `BLOCKED/FAIL/PASS` κωδικοί.
- **Changes:** REPLACE (workflows)· REMOVE (`PRIMARY_SEMANTIC_AUTHORITY`)· KEEP (docker/deps).
- **Tests/kill:** Q18, Q40· KW-59· VS-15 (προϋπόθεση hermetic).
- **Migration:** καμία (βάση)· καθιστά αναπαράξιμη την εικόνα. **Rollback:** επαναφορά προηγούμενης εικόνας από digest· κλάδος εγκαταλείπεται πριν merge.
- **Evidence:** κάθε workflow PASS ×2 ανεξάρτητες εκτελέσεις· hermetic byte-ταυτόσημο ×2· SBOM· U-8 6/6 CONFIRMED/REFUTED· `PRIMARY_SEMANTIC_AUTHORITY`=0 σε μηχανική έξοδο· SLO baseline U-1· `deployment/self/history.sexp` + `output/.healthy` ανέπαφα.
- **Exit gate:** ό,τι παραπάνω πράσινο ×2· `PRIMARY_SEMANTIC_AUTHORITY`=0· U-8 κλειστό.

### WP-01 — Εθνική απογραφή πηγών/δικαστηρίων + coverage ledger
- **Requirement:** R-01..R-13 (§4.1)· R-132 (§4.20)· closure-WP-01/16· MIS-2.
- **Architecture seat:** S1 (Census/Radar) + S16 (Source-Type Registry).
- **Paths/symbols:** `ingestion-daemon.lisp`, `legislation-ingestion.lisp`, `government-source.lisp`, `document-fetch.lisp` (MODIFY)· `source-profile.lisp` (KEEP)· `capability-registry.lisp`/gap ledger (MODIFY)· **NEW:** coverage ledger (ολική συνάρτηση), census `RegistrySnapshot` (MLTP §2.9), `coverage-and-freshness` claim.
- **Interfaces:** census space `gr/<series>`· `RegistrySnapshot`· `coverage-and-freshness`.
- **Changes:** MODIFY + NEW (ledger/snapshot).
- **Tests/kill:** Q01, Q02, Q29· KW-48· VS-13.
- **Migration:** προσθετικός root-signed snapshot (νέο census universe)· forward-only. **Rollback:** νέος snapshot υπερισχύει· παλιός διατηρείται (versioned)· κλάδος πριν merge.
- **Evidence:** snapshot owner-root-signed (rehearsal)· κάθε θέση ακριβώς μία κατάσταση· δεύτερη ανεξάρτητη απαρίθμηση 0 ανεξήγητες αποκλίσεις· U-7 κλειστό· U-1 budgets· VS-13 pass.
- **Exit gate:** ολική κάλυψη (καμία σιωπηλή απώλεια)· U-7/U-1 κλειστά· VS-13 3/3 μάρτυρες.

### WP-02 — Acquisition, ταυτότητα, provenance, αυθεντικότητα + Secure Ingress sandbox
- **Requirement:** R-14..R-23 (§4.2)· R-133 (§4.21)· closure-WP-02· MIS-1.
- **Architecture seat:** S2 (acquisition) + Secure Semantic Ingress boundary.
- **Paths/symbols:** `pdf-authority.lisp` (KEEP)· `layout-types.lisp`, `validate-layout-graph.lisp`, `typographic-classifier.lisp`, `legal-ast.lisp` (MODIFY)· `text-canonicalizer.lisp` (KEEP)· `corpus-provenance.lisp`, `authority-proof-bundle.lisp`, `legal-authority-receipt.lisp`, `legal-identity.lisp`, `legal-id-registry.lisp`, `x509-authority.lisp`, `asn1-der.lisp`, `timestamp-authority.lisp` (MODIFY)· `safe-read.lisp` (KEEP — **ΕΣΩΤΕΡΙΚΟ-ΜΟΝΟ**, δεν αγγίζει external bytes)· **NEW:** capability-less sandbox host, sandboxed format parsers → `ingress-envelope/1`, **non-evaluating JSON/CBOR schema decoder**, taint-state enforcer, `authority-proof/2`, custody chain, audiovisual manifestation.
- **Interfaces:** `ingress-envelope/1`, `parser-result/1`, `authority-proof/2`, USC 4-level ids.
- **Changes:** MODIFY + NEW (decoder/sandbox)· καμία επέκταση `safe-read.lisp` (external decoder = NEW, χωριστή έδρα).
- **Tests/kill:** Q03, Q07, Q13, Q24, Q30· KW-3/4/26/27/44/45· **SIK-1..9** (UNEXECUTED → εκτελούνται εδώ)· VS-01(1–3), VS-03.
- **Migration:** νέα boundary έδρα· καμία μετάλλαξη υπαρχόντων records. **Rollback:** decoder/sandbox σε δικό τους module· απενεργοποίηση = επιστροφή σε «καμία external ingestion» (fail-closed), ποτέ σε `cl:read` external.
- **Evidence:** 100% σφραγισμένων με 4 provenance στοιχεία· two-channel ⇒ ένα `work_id`· SIK-1..9 μηδενική παρενέργεια (0 fs/net/proc)· VS-03 pass· VS-01 checkpoint.
- **Exit gate:** κανένα external byte σε `cl:read`/eval· SIK-1..9 pass· VS-03 pass.

### WP-03 — Typed Legal IR + bitemporal event store
- **Requirement:** R-31..R-34 (§4.4), R-35..R-38 (§4.5)· closure-WP-04/05· MIS-1/MIS-3. (Το §4.3 R-24..R-30 ανήκει **πρωτεύοντα** στο WP-07· εδώ καταναλώνεται ως IR είσοδος, δευτερεύον.)
- **Architecture seat:** S4 (symbolic core) + S5 (digital twin, event store).
- **Paths/symbols:** `version-graph.lisp` (MODIFY: δικαστικά/ενωσιακά γεγονότα, `known_from`)· `legal-temporal.lisp`, `legal-event-calculus.lisp`, `journal.lisp` (KEEP)· `corpus-eu-links.lisp`, `eu-interop-layer.lisp`, `citation-authority.lisp`, `legal-decisions.lisp`, `legal-ast.lisp` (MODIFY: `norm.determinacy`)· **NEW:** `legal-timeline/1`/`audit-timeline/1` τύποι, `norm.determinacy` τύπος.
- **Interfaces:** κλειστός κατάλογος 15 γεγονότων· `valid × known`· `legal-timeline/1` (payload) / `audit-timeline/1` (proof).
- **Changes:** MODIFY + NEW (timeline τύποι).
- **Tests/kill:** Q05, Q06, Q08, Q41· KW-51, KW-60, KW-61· VS-01(4–6), VS-02(1–4), VS-07(IR).
- **Migration:** προσθετικά event kinds· forward-only· `audit` πεδίο σε payload ⇒ `malformed-envelope`. **Rollback:** νέα event kinds πίσω-συμβατά· revert = προσθήκη `REVERT` γεγονότος, ποτέ διαγραφή journal.
- **Evidence:** κάθε γεγονός με πηγή (KW-51)· `TPKill` εκτελεσμένο ≥1 killed witness· VS-01/02/07 checkpoints.
- **Exit gate:** χρόνος-γνώσης ποτέ δεν κρίνει νομική ισχύ (I5)· KT5 (`TPKill`) executed· checkpoints pass.

### WP-04 — Πρώτος ντετερμινιστικός Legal Compiler (Common Lisp)
- **Requirement:** R-40, R-43 (§4.6 — compiler A: αναπαράξιμη ρίζα + attestation-separation)· closure-WP-08· MIS-5. (R-39/R-41/R-42 ολοκληρώνονται στο WP-05 — DUAL· καμία διπλή υλοποίηση.)
- **Architecture seat:** S8 (dual compilation — έδρα A).
- **Paths/symbols:** `consolidation-engine.lisp`, `consolidation-proof.lisp`, `version-graph.lisp`, `legal-inference-engine.lisp` (KEEP/MODIFY)· `release-authority.lisp`, `release-gate.lisp`, `verify-truth-gate.lisp` (MODIFY: proposer-blind M5)· `deployment/verify/verify-temporal.py` (KEEP τρίτος έλεγχος).
- **Interfaces:** `legal_state_root` + `projection_roots`· `compiler-attestation`.
- **Changes:** MODIFY.
- **Tests/kill:** Q11, Q12· VS-01(7), VS-02(5), VS-09(A).
- **Migration:** αναπαράξιμο root από journal· forward-only. **Rollback:** νέο root σε δικό του κλάδο· απόρριψη = επιστροφή σε προηγούμενο signed root (PLANE-0 αμετάβλητο).
- **Evidence:** δύο εκτελέσεις ⇒ ίδιο `legal_state_root` (Q12)· `compiler-attestation` delegated key (rehearsal)· checkpoints.
- **Exit gate:** ντετερμινισμός ρίζας 2/2· proposer-blind M5.

### WP-05 — Δεύτερος ανεξάρτητος compiler (Rust) + differential verification
- **Requirement:** R-39, R-41, R-42 (§4.6 — DUAL: δεύτερη ανεξάρτητη υλοποίηση + σύγκριση ριζών + quarantine)· closure-WP-08· MIS-5· **U-5**.
- **Architecture seat:** S8 (dual compilation — έδρα B, καμία κοινή evaluator).
- **Paths/symbols:** **NEW:** Rust compiler B, differential harness· `release-gate.lisp` (MODIFY: `QUARANTINED` path)· MLTP §6 `dual_compiler_attestation`.
- **Interfaces:** `legal_state_root_B`· `dual_compiler_attestation`· quarantine record.
- **Changes:** NEW + MODIFY.
- **Tests/kill:** Q33, Q34· KW-52· VS-09, VS-10.
- **Migration:** προσθετικός δεύτερος compiler· καμία αλλαγή τύπων. **Rollback:** compiler B module αφαιρέσιμο· χωρίς αυτόν κανένα release (fail-closed single-attestation ⇒ block), ποτέ single-attestation release.
- **Evidence:** ισότητα ριζών A=B (VS-09)· εγχυμένο σφάλμα ⇒ καραντίνα 1/1 (VS-10)· 0 releases με μία attestation.
- **Exit gate:** VS-09 + VS-10 pass· 0 single-attestation releases.

### WP-06 — MLTP v3, offline verifier (PCL-2), distributed Trust Mesh + crypto agility
- **Requirement:** R-57..R-70 (§4.10), R-89/R-90/R-92/R-94 (§4.14 security cell: release-protection/least-privilege/secret-isolation/tamper), R-125..R-128 (executable closure), R-130 (§4.18 agility), R-134 (§4.22 nation-state)· closure-WP-10/11· **U-2**.
- **Architecture seat:** S10 (MLTP trust layer) + S11 (security cells).
- **Paths/symbols:** `jws-authority.lisp`, `merkle-authority.lisp`, `hash-authority.lisp`, `x509-authority.lisp`, `asn1-der.lisp`, `timestamp-authority.lisp` (MODIFY)· `authority-v2/` (MODIFY: roles, witness-quorum, ceremony)· `deployment/verify/verify.py|.mjs|verify-release.py|verify-authority-bundle.py`, `kernel-verify.lisp` (MODIFY → MLTP v3)· `deployment/verify/vectors/` (MODIFY)· `PROOF-CARRYING-LAW.md` (MODIFY → PCL-2)· `deployment/verify/mltp3/**` (KEEP — εκτελεσμένη αναφορά)· **NEW:** threshold signing, δεύτερο log, cross-client witness registry, SCITT projection, Rust verifier, `crypto-policy-epoch`, `PQRootSet` (ML-DSA n-of-m), `evidence-renewal`.
- **Interfaces:** `IssuedClaim`/`TrustBundle`/`VerificationReceipt`· `crypto-policy-epoch`· `PQRootSet`.
- **Changes:** MODIFY + NEW.
- **Tests/kill:** Q21, Q22, Q23, Q26, Q28, Q43· KW-1/2/5/6/9..47, KW-64..106· VS-11(checkpoint), VS-12.
- **Migration:** policy epochs προσθετικά· hybrid AND (classical+PQ)· evidence-renewal chains (καμία αναδρομική ακύρωση). **Rollback:** νέα epoch αναστρέψιμη σε προηγούμενη signed epoch· verifier ανά εποχή· PLANE-0 αμετάβλητο.
- **Evidence:** 35/35 error names με αρνητικό vector που τρία verifiers αναγνωρίζουν ταυτόσημα· KW vectors `KILLS`· VS-12 pass· U-2 κλειστό.
- **Exit gate:** independent n-of-m ML-DSA (ΟΧΙ threshold)· downgrade resistance (KW-104)· 35/35 vectors· U-2 κλειστό.

### WP-07 — Πολυτροπική acquisition + neural runtime + ontology-alignment plane
- **Requirement:** R-24..R-30 (§4.3 neural), R-131 (§4.19 ontology)· closure-WP-02/03/17· **U-6**.
- **Architecture seat:** S2 (OCR/layout) + S3 (neuro-symbolic bridge) + S17 (ontology governance).
- **Paths/symbols:** **non-evaluating JSON/CBOR decoder** (WP-02 έδρα, μοναδική είσοδος εξωτ. αποκωδικοποίησης· ΟΧΙ `safe-read`)· `safe-read.lisp` (KEEP — ΕΣΩΤΕΡΙΚΟ-ΜΟΝΟ)· `document-fetch.lisp` (KEEP πρότυπο fetcher)· `legal-extraction-verify.lisp` (MODIFY)· `greek-legislation-ontology.lisp`, `knowledge-graph.lisp`, `rdfs-inference.lisp`, `shacl-validator.lisp` (MODIFY: alignment)· `proposals.lisp`, `anomaly-detection.lisp`, `fluid-induction.lisp` (MODIFY: L5 lifecycle)· **NEW:** protocol schema, νευρωνικό runtime (external, out-of-process), OCR manifestation path, `ontology-bundle`+`shacl-validation-receipt`.
- **Interfaces:** `neural-task/1`, `neural-candidate/1` (κλειστά)· `ontology-bundle`.
- **Changes:** MODIFY + NEW· neural runtime **εκτός** trusted path (PLANE-3).
- **Tests/kill:** Q04, Q30, Q31· KW-49, KW-106· VS-04, VS-05, VS-06(checkpoint).
- **Migration:** ontology bundle versioned + shapes digest· revalidation ⇒ νέο receipt (καμία αναδρομική ακύρωση, KW-106). **Rollback:** neural runtime απενεργοποιήσιμο (fail-closed: καμία candidate lane)· ontology epoch αναστρέψιμη.
- **Evidence:** ελεύθερο πεδίο πρωτοκόλλου ⇒ δεν μεταγλωττίζεται (αρνητικό build)· held-out σφάλμα μετρημένο (U-1 κατώφλι)· VS-04/05 pass.
- **Exit gate:** κανένα neural candidate self-promote (I-4.3a)· ontology version-bound· VS-04/05 pass· U-6 κλειστό.

### WP-08 — Νευρο-συμβολικός συλλογισμός + επιστημικό τείχος (Public Legal Discernment core)
- **Requirement:** R-129 (§4.17 semantic contract)· closure-WP-04· MIS-1. (Ασκεί R-24..R-34 ως **καταναλωτής** συλλογισμού· πρωτεύουσα ιδιοκτησία τους: WP-07/WP-03.)
- **Architecture seat:** S4 (symbolic core) — Public Legal Discernment Engine πυρήνας.
- **Paths/symbols:** `legal-inference-engine.lisp`, `legal-deontic.lisp`, `legal-event-calculus.lisp`, `legal-conflict-resolution.lisp`, `legal-dialectic.lisp`, `legal-subsumption.lisp` (μόνο **δημόσιος** συλλογισμός· ιδιωτική υπαγωγή DEFER_PRIVATE), `guard-metaeval.lisp` (KEEP/MODIFY)· `write-authority.lisp` (KEEP — **μία** έδρα εγγραφής)· `advisor.lisp` (KEEP πρότυπο).
- **Interfaces:** typed Legal IR· `UNKNOWN(interpretive)` με typed εναλλακτικές (L5)· conflict = adopted scoped `ConflictPolicyBundle` (ΟΧΙ επινοημένος καθολικός κανόνας).
- **Changes:** MODIFY (καμία ιδιωτική υπαγωγή).
- **Tests/kill:** Q09, Q31, Q32, Q33· KW-7, KW-49, KW-50· VS-06, VS-07.
- **Migration:** conflict policy = adopted, source-anchored· απών ⇒ UNKNOWN, ασύμβατα ⇒ CONFLICTING. **Rollback:** νέα inference rules σε κλάδο· revert χωρίς επίδραση σε journal.
- **Evidence:** PLANE-3 σε release ⇒ compile failure (Q09)· KW-7/49/50 `KILLS`· VS-06/07 pass.
- **Exit gate:** promotion candidate→IR **μόνο** με symbolic validation· ρητή αποχή (typed UNKNOWN)· καμία εικασία.

### WP-09 — Πλήρες jurisprudence-evolution plane
- **Requirement:** R-51..R-56 (§4.9)· closure-WP-07· MIS-4· **U-3**.
- **Architecture seat:** S7 (jurisprudence plane) — τέσσερις τάξεις, line-of-authority.
- **Paths/symbols:** `legal-decisions.lisp`, `decisions.lisp`, `citation-authority.lisp` (MODIFY)· `jurisprudence-judge.lisp` (KEEP)· `version-graph.lisp` (MODIFY: line-of-authority)· `legal-precedent.lisp`, `legal-casegrammar.lisp` (**DEFER_PRIVATE** — δεν αγγίζονται)· **NEW:** ECLI υλοποίηση, reviewer registry + adoption act, line-of-authority graph.
- **Interfaces:** `judgment-identity-and-text`, `jurisprudential-analysis` + `reviewer_adoption_act`, `authority_weight`, `LATER-TREATMENT`.
- **Changes:** MODIFY + NEW· DEFER_PRIVATE αμετάβλητα.
- **Tests/kill:** Q07, Q08, Q25, Q37· KW-3/7/36/44/55· VS-08.
- **Migration:** τάξη-3 analysis μόνο με adoption act· forward-only. **Rollback:** reviewer registry versioned· revert adoption = `REVERT` γεγονός.
- **Evidence:** 0 `later_treatment` χωρίς anchor· 0 ratio χωρίς adoption σε release· ανωνυμοποίηση typed 100%· VS-08 pass.
- **Exit gate:** ποτέ ratio ως θεσμικό γεγονός χωρίς adoption (KW-36)· U-3 κλειστό.

### WP-10 — National Legal Digital Twin + impact engine
- **Requirement:** R-35..R-38 (§4.5), R-48..R-50 (§4.8)· closure-WP-05/06· MIS-3.
- **Architecture seat:** S5 (digital twin) + S6 (hypergraph) — Legal Digital Twin (L7).
- **Paths/symbols:** `graph-reasoning.lisp` (MODIFY: `reason-impact` σε διτεμπορική τομή)· `what-if.lisp`, `legal-counterfactual.lisp`, `legal-references.lisp`, `legal-hypergraph.lisp` (KEEP)· `eu-interop-layer.lisp` (MODIFY: ELI-Impact)· `corpus-diff.lisp` (MODIFY: invalidation set)· **NEW:** `replay_manifest`, `normative-impact-projection` profile.
- **Interfaces:** `normative-impact-projection` + `replay_manifest`· invalidation sets.
- **Changes:** MODIFY + NEW.
- **Tests/kill:** Q36· KW-54· VS-02(ολοκλήρωση).
- **Migration:** impact projections αναπαράξιμα από journal· forward-only. **Rollback:** projection module· revert χωρίς επίδραση σε πηγή.
- **Evidence:** auditor re-run ⇒ ίδιο `impact_root`· τύπος χωρίς πεδίο έκβασης (KW-54 compile failure)· VS-02 complete.
- **Exit gate:** `impact_root` αναπαράξιμο· καμία «έκβαση» στον τύπο.

### WP-11 — Proof-carrying query API / MCP / SDK + Citation-Bound Verification Profile
- **Requirement:** R-44..R-47 (§4.7), R-71..R-73 (§4.11), R-101..R-110 (§4.15), R-119..R-124 (§4.16)· closure-WP-09/14· MIS-5/MIS-6.
- **Architecture seat:** S9 (proof-carrying query) + S14 (API/MCP/SDK/feeds).
- **Paths/symbols:** `legal-qa.lisp`, `legal-reasoning-bridge.lisp` (MODIFY)· `proof-carrying.lisp` (KEEP)· `legal-dialectic.lisp` (MODIFY: counterproof)· `mcp-server.lisp` (MODIFY: υποχρεωτικό `citation`)· `capability-api.lisp` (KEEP)· `canonical-uris.lisp` (MODIFY)· `json-emit.lisp` + `deployment/*.ttl` (MODIFY: JSON-LD)· `akoma-ntoso-emitter.lisp`, `shacl-validator.lisp`, `sparql-endpoint.lisp`, `corpus-sparql.lisp` (KEEP)· `ai-corpus-dump.lisp`, `ai-ingest-manifest.lisp` (MODIFY: feeds)· **NEW:** `proof-carrying-answer/1` type, OpenAPI, SDKs (Py/TS/Rust), LegalRuleML emitter, `/audit/{claim_id}`, conformance suite.
- **Interfaces:** `proof-carrying-answer/1` (11 πεδία)· `CertifiedResult`+`citation/1`+`CitationToken`· OpenAPI/MCP.
- **Changes:** MODIFY + NEW.
- **Tests/kill:** Q14, Q27, Q35, Q38, Q41, Q42· KW-53/56/62/63· VS-01(complete), VS-11.
- **Migration:** versioned OpenAPI/MCP· προαιρετικό `citation` ⇒ conformance FAIL. **Rollback:** API version πίσω-συμβατή· SDK versioned.
- **Evidence:** 18/18 receipts VS-11· default απάντηση χωρίς `acquired_at`· SHACL 0 παραβιάσεις· stripped citation ⇒ `UNVERIFIED_FOR_ATTRIBUTED_RELIANCE`.
- **Exit gate:** proof-carrying ή UNKNOWN (ποτέ εικασία)· citation-bound (KW-62/63)· VS-01/VS-11 complete.

### WP-12 — Ιστότοπος, cockpit, publication workflow + public→private enforcement
- **Requirement:** R-74..R-81 (§4.12), R-111 (public→private· 9 απόντες τύποι), R-91 ≡ R-79 (RBAC/MFA· ίδια έδρα)· §1.3/§1.4· closure-WP-12/13/18· MIS-6/MIS-10.
- **Architecture seat:** S12 (cockpit) + S13 (website) + S18 (public→private boundary).
- **Paths/symbols:** `cockpit.lisp` (MODIFY· `/api/publish` **REPLACE** → approval intent M5)· `http-server.lisp`, `review-service.lisp`, `review-queue.lisp`, `static-site.lisp`, `approval-policy.lisp`, `decisions.lisp`, `corpus-diff.lisp` (KEEP)· **NEW:** RBAC/MFA registry, app shell.
- **Interfaces:** `cockpit_intent` (κλειστό, RBAC/MFA)· canonical URL `/lawmax/{path}`.
- **Changes:** MODIFY + REPLACE (`/api/publish`) + NEW (RBAC/MFA, app shell).
- **Tests/kill:** Q15, Q17, Q20, Q39· KW-38, KW-39, KW-57· VS-14.
- **Migration:** `/api/publish` γίνεται intent producer (καμία release action)· 9 ιδιωτικοί τύποι δομικά απόντες (compile-time). **Rollback:** app shell versioned· cockpit intent ουρά αναστρέψιμη· ποτέ direct-publish path.
- **Evidence:** VS-14 4/4 απόπειρες δομικά αδύνατες· Q15 owner docker proof (οκτώ στοιχεία με τεκμήριο).
- **Exit gate:** 1 release μέσω M5· direct-publish δομικά αδύνατο· ιδιωτικός τύπος ⇒ compile failure (Q20).

### WP-13 — Citation observatory + security/operational observatory
- **Requirement:** R-82..R-84 (§4.13), R-93/R-95/R-96/R-97/R-98 (§4.14 ops/DR/multi-region/incident/SLO)· closure-WP-15· MIS-9.
- **Architecture seat:** S15 (observatories).
- **Paths/symbols:** `ai-citation-strategy.lisp`, `citation-authority.lisp` (MODIFY)· `configs/prometheus-citation.yml`, `deployment/templates/ai-citation-log.ttl` (KEEP)· `LAWMAX-THREAT-MODEL.md` (θεμέλιο· κλείσιμο Θ3/4/5/9/10 στην υλοποίηση)· `circuit-breaker.lisp`, `logging.lisp` (KEEP)· **NEW:** revoked-material detector, provider compliance monitor, SLO registry, vulnerability monitoring, DR runbook, incident feed.
- **Interfaces:** SLO registry· incident feed· split-view drill.
- **Changes:** MODIFY + NEW.
- **Tests/kill:** Q16, Q19, Q40, Q42· KW-58, KW-59, KW-63· VS-15.
- **Migration:** collectors ή typed UNKNOWN (ποτέ stub «0»)· DR runbook. **Rollback:** collector modules αφαιρέσιμα· UNKNOWN αντί σιωπής.
- **Evidence:** VS-15 (R ίσο, RTO/RPO U-1)· 0 stub collectors· split-view drill 1/1· stripped-citation ανιχνεύεται 1/1.
- **Exit gate:** καμία σιωπηλή μηδενική μετρική· DR αναπαράγει byte-ταυτόσημο release· U-1 τελικοί αριθμοί.

### WP-14 — Mission-scale qualification + provider adoption
- **Requirement:** R-112..R-118 (qualification cross-cutting: 12-layer presence/audit/5-grades/dominance/anti-loop/programme) + §5 (MISSION GREECE-1)· closure: qualification gate· MIS-9. (Provider registry = §5 mission artifact· η μορφή adoption R-110 ανήκει στο WP-11.)
- **Architecture seat:** cross-cutting — MLTP §3.1 QSR issuance, provider registry.
- **Paths/symbols:** MLTP v3 §3.1 QSR (KEEP)· **NEW:** provider registry· `LocalTrustState.provider_registry`.
- **Interfaces:** QSR (SPEC/IMPLEMENTATION/SECURITY/MISSION) με `expiry`· `provider-adoption-qualified`.
- **Changes:** NEW (provider registry).
- **Tests/kill:** Q27, Q28 + όλες οι Q01–Q42 ζωντανά· KW-12, KW-13, KW-25, KW-46· όλες οι 15 φέτες ως regression.
- **Migration:** QSR με auto-downgrade στη λήξη· forward-only. **Rollback:** μη έγκυρη QSR ⇒ αυτόματη υποβάθμιση (KW-13/25)· mission abort = καμία κανονικότητα.
- **Evidence:** Μ-1..Μ-6 για 30/30 ημέρες με ≥2 auditor receipts· `provider-adoption-qualified` από ≥2 registered providers· κάθε QSR με `expiry` + auto-downgrade αποδεδειγμένη.
- **Exit gate:** ανεξάρτητοι auditors υπογράφουν· ρητή εντολή δημιουργού για MISSION· καμία συνθήκη ματαίωσης.

## §11. DRY-RUN ΟΛΟΚΛΗΡΗΣ ΣΕΙΡΑΣ — ΕΠΑΛΗΘΕΥΣΗ ΚΑΛΥΨΗΣ (χωρίς κώδικα)

Ξηρή εκτέλεση της σειράς WP-00→WP-14 και έλεγχος των έξι ιδιοτήτων που απαίτησε η εντολή:

### §11.1 Κάθε απαίτηση υλοποιείται **ακριβώς μία φορά** (R-01..R-134 → ένας πρωτεύων WP)
| WP | primary R-ids (disjoint) | §4.x |
|---|---|---|
| WP-00 | AS-IS R-1..6· R-85, R-86, R-87, R-88, R-99, R-100 | §4.14 (build/CI/SBOM), §4.11 |
| WP-01 | R-01..R-13, R-132 | §4.1, §4.20 |
| WP-02 | R-14..R-23, R-133 | §4.2, §4.21 |
| WP-03 | R-31..R-38 | §4.4, §4.5 |
| WP-04 | R-40, R-43 (compiler A: reproducible root + attestation-separation) | §4.6 |
| WP-05 | R-39, R-41, R-42 (dual: δύο υλοποιήσεις + σύγκριση + quarantine) | §4.6 |
| WP-06 | R-57..R-70, R-89, R-90, R-92, R-94, R-125..R-128, R-130, R-134 | §4.10, §4.14 (security), §4.18, §4.22 |
| WP-07 | R-24..R-30, R-131 | §4.3, §4.19 |
| WP-08 | R-129 | §4.17 |
| WP-09 | R-51..R-56 | §4.9 |
| WP-10 | R-48..R-50 | §4.8 |
| WP-11 | R-44..R-47, R-71..R-73, R-101..R-110, R-119..R-124 | §4.7, §4.11, §4.15, §4.16 |
| WP-12 | R-74..R-81, R-111 (R-91 ≡ R-79, ίδια έδρα) | §4.12, §1.3/§1.4 |
| WP-13 | R-82..R-84, R-93, R-95, R-96, R-97, R-98 | §4.13, §4.14 (ops/DR/incident) |
| WP-14 | R-112..R-118 (qualification cross-cutting) + §5 MISSION | §4-εγκάρσια, §5 |

**Έλεγχος disjointness (R-01..R-134 άπαξ):** κάθε R-id εμφανίζεται σε **ακριβώς μία** γραμμή παραπάνω.
Τρεις ρητές, τεκμηριωμένες περιπτώσεις — **όχι** διπλή υλοποίηση:
- **§4.6 R-39..R-43 (DUAL compilers):** η απαίτηση είναι **απαιτητά-διακριτή** — compiler A (Lisp, WP-04:
  R-40/R-43) + compiler B & differential/quarantine (Rust, WP-05: R-39/R-41/R-42). Δύο **ανεξάρτητες**
  υλοποιήσεις είναι το **περιεχόμενο** της απαίτησης (differential verification), **όχι** διπλή έδρα ίδιας
  λειτουργίας (audit H4 unique-ownership αφορά ίδια λειτουργία).
- **§4.14 R-85..R-100:** διασπάται **κατά ανησυχία** σε disjoint υποσύνολα — build/CI/SBOM/provenance
  (WP-00: R-85/86/87/88/99/100)· release-protection/least-privilege/secret-isolation/tamper (WP-06:
  R-89/90/92/94)· RBAC/MFA (WP-12: R-91, που το ίδιο το traceability δηλώνει **`= R-79`** — ίδια έδρα,
  όχι δεύτερη)· vuln/DR/multi-region/incident/SLO (WP-13: R-93/95/96/97/98). Κανένα R δύο φορές.
- **Checkpoints πολλαπλών βημάτων (VS):** είναι **δευτερεύουσες** ασκήσεις της ίδιας απαίτησης, όχι
  δεύτερη πρωτεύουσα ιδιοκτησία (π.χ. R-86 hermetic build: πρωτεύον WP-00· ασκείται ξανά στο VS-15/WP-13).

### §11.2 Κανένας ορφανός κώδικας
Κάθε υπάρχον αρχείο έχει disposition (crosswalk §A, 181/181)· κάθε NEW έδρα έχει WP ιδιοκτήτη (§4.2/§10)·
κάθε `DEFER_PRIVATE` (8) ρητά **δεν** αγγίζεται. ⇒ 0 ορφανά.

### §11.3 Καμία δύο έδρες για την ίδια λειτουργία
Μία έδρα εγγραφής (`write-authority.lisp`)· μία external decoder έδρα (NEW, ΟΧΙ `safe-read`)· μία
census/coverage έδρα· μία source-type registry· μία conflict-policy μηχανισμός (adopted bundle)· audit
H4a/H4b/H4c (unique ownership) + superseded register (μία έδρα ανά profile). ⇒ 0 διπλές έδρες.

### §11.4 Κανένα subsystem δεν λείπει
18/18 subsystems (§2) καλύπτονται από WP-00..WP-14 (στήλη «Book WP»). ⇒ 0 missing subsystem.

### §11.5 Καμία κυκλική ή απαγορευμένη εξάρτηση
Ο γράφος §5 είναι **DAG** (τοπολογική σειρά 0,1,2,3,4,{5,6,7},{8,10},9,11,12,13,14 — καμία ανάστροφη
ακμή)· απαγορευμένες κατευθύνσεις (PLANE-2/3 → PLANE-0, external → eval) δομικά αδύνατες (§3.1). ⇒ 0
κύκλοι, 0 απαγορευμένες.

### §11.6 Κάθε WP έχει rollback + αντικειμενικό exit gate
15/15 WP φέρουν πεδίο **Rollback** (§10, καθολικός κανόνας §9) και δυαδικό **Exit gate** (= πύλη
εισόδου επόμενου). ⇒ 15/15.

### §11.7 Ισολογισμός dry-run
| ιδιότητα | αποτέλεσμα | verdict |
|---|---|---|
| requirements άπαξ | R-01..R-134 → 15 WP, καμία διπλή πρωτεύουσα (134 distinct, 0 dup, 0 missing) | PASS |
| ορφανός κώδικας | 181/181 disposition + κάθε NEW με WP ιδιοκτήτη | 0 · PASS |
| διπλές έδρες | unique ownership (audit H4) | 0 · PASS |
| missing subsystem | 18/18 καλυμμένα | 0 · PASS |
| κυκλικές/απαγορευμένες εξαρτήσεις | DAG + μονόδρομες planes | 0 · PASS |
| rollback + exit gate ανά WP | 15/15 | PASS |

## §12. ΤΙ ΔΕΝ ΚΑΝΕΙ ΤΟ ΒΙΒΛΙΟ

Δεν υλοποιεί κανένα WP· δεν γράφει/μετακινεί/αναδιαμορφώνει κώδικα· δεν κάνει freeze/merge/
qualification· δεν διεκδικεί βαθμίδα· δεν εισάγει παράλληλη αρχιτεκτονική ή νέο axis· δεν αγγίζει
frozen NORMATIVE αρχείο· δεν αγγίζει το `RAW-JOURNAL-PARTIAL.jsonl`. Η αυθεντία μένει στο Κράτος/ΦΕΚ/
ΕΕ/δικαστήρια (MIS-8).

---
**`IMPLEMENTATION BOOK COMPLETE — EXECUTION NOT AUTHORIZED`.**
Καμία εκκίνηση WP-00 χωρίς τη χωριστή εντολή: **`ΕΓΚΡΙΝΩ IMPLEMENTATION BOOK — ΞΕΚΙΝΑ WORK PACKET 0`.**
