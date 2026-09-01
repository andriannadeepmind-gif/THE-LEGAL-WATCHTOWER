# IMPLEMENTATION SEQUENCE — ΒΗΜΑΤΑ 0 ΕΩΣ 14 ΜΕΤΑ ΤΟ SPEC FREEZE (ΔΕΝ ΥΛΟΠΟΙΕΙΤΑΙ ΤΩΡΑ)

> **Σειρά (v1.4 §10, διόρθωση #17):** `SPEC QUALIFIED` → ρητό `SPEC FREEZE` →
> **αυτά τα βήματα 0–14** → **οι 15 κάθετες φέτες** (`VERTICAL-SLICES.md`) →
> `IMPLEMENTATION QUALIFIED`. Οι φέτες τρέχουν **μέσα** σε αυτή τη φάση, **μετά** το
> freeze — **δεν** είναι προϋπόθεση του freeze (το παλιό deadlock αίρεται). Ο πυρήνας
> του πρωτοκόλλου έχει ήδη επικυρωθεί εκτελέσιμα πριν το SPEC (MLTP v3 §13,
> `deployment/verify/mltp3/run.sh`).

**ΚΑΤΑΣΤΑΣΗ: ΣΕΙΡΑ ΠΡΟΔΗΛΩΜΕΝΗ — ΚΑΝΕΝΑ ΒΗΜΑ ΔΕΝ ΕΧΕΙ ΕΚΚΙΝΗΣΕΙ. ΚΑΜΙΑ ΓΡΑΜΜΗ ΚΩΔΙΚΑ.**

Έδρα (μία) της σειράς υλοποίησης του `CHANGE-PROPOSAL-v1.4.md §11`. **Τίποτα εδώ δεν
εκκινεί πριν** (α) επιβίωση του προγράμματος επικύρωσης (Q-tests §8), (β) εκτελέσιμες
15 φέτες ως προδιαγραφή (`VERTICAL-SLICES.md`, εκτελούνται **μετά** το freeze, #17), (γ) ρητό «εγκρίνω freeze target» του
δημιουργού (v1.4 §13). **Refactoring αρχίζει μόνο μετά από ρητή έγκριση του παγωμένου
δημόσιου στόχου από τον δημιουργό.**

**Κανόνες κάθε βήματος:**
1. Ένας κλάδος ανά βήμα· plan → ρητή έγκριση δημιουργού → υλοποίηση → εσωτερική
   αντιπαλική επιθεώρηση → κλείσιμο ευρημάτων → πλήρες proof (gates/tests/audits με
   αριθμούς) → owner docker proof → ρητή εντολή merge (πρωτόκολλο συνεργασίας του μόνιμου συμβολαίου δημιουργού).
2. Η πύλη εισόδου ενός βήματος είναι η πύλη εξόδου των προαπαιτούμενων· καμία
   παράκαμψη· `BLOCKED ≠ FAIL` στους κωδικούς εξόδου.
3. Κάθε βήμα κλείνει τα `MISSING` συστατικά που δηλώνει (crosswalk §A/§B), ασκεί τις
   φέτες που δηλώνει, και κάνει πράσινες τις οικογένειες Q που δηλώνει — με
   proposer-blind επαλήθευση, όχι με αυτο-αναφορά.
4. `U-n` που έχει προθεσμία «πριν το βήμα k» **μπλοκάρει** την είσοδο του βήματος k.
5. Κανένα βήμα δεν διεκδικεί βαθμίδα· οι βαθμίδες υπογράφονται από independent
   auditors (MLTP v3 §3.1) και μόνο στο βήμα 14 τίθεται ζήτημα `MISSION`.
6. Η τρέχουσα κλειδωμένη σειρά του δημιουργού (STATE-OF-PLAY: Π7-U.1, FF4 kernel
   freeze, NixOS μετά το Foundation Freeze) **δεν** αντικαθίσταται από αυτή· αυτή
   εντάσσεται σε εκείνη μετά το «εγκρίνω freeze target».

---

## ΓΡΑΦΟΣ ΕΞΑΡΤΗΣΕΩΝ

| βήμα | προαπαιτούμενα | μπλοκάρεται από |
|---|---|---|
| 0 | freeze approval | — |
| 1 | 0 | U-7 (κλείνει στην έξοδό του), U-1 (freshness budgets) |
| 2 | 1 | — |
| 3 | 2 | — |
| 4 | 3 | — |
| 5 | 4 | U-5 |
| 6 | 4 | U-2 |
| 7 | 2 | U-6 |
| 8 | 3, 7 | — |
| 9 | 3, 8 | U-3 |
| 10 | 4 | — |
| 11 | 5, 6, 10 | — |
| 12 | 11 | — |
| 13 | 11, 12 | — |
| 14 | 13 (και όλα) | — |

Παραλληλία επιτρεπτή: 5 ‖ 6 ‖ 7 (μετά το 4/2)· 8 ‖ 10· 9 μετά το 8. Το κρίσιμο
μονοπάτι: 0 → 1 → 2 → 3 → 4 → 6 → 11 → 12 → 13 → 14.

---

## ΤΑ ΒΗΜΑΤΑ

### Βήμα 0 — Καθαρή αναπαραγώγιμη βάση + γνήσια πράσινο CI
**Στόχος:** καμία αξίωση υλοποίησης πάνω σε βάση που δεν χτίζεται αναπαραγώγιμα και
δεν έχει πράσινο CI (AS-IS EV-12: 71 runs, 0 successes).
**Πύλη εισόδου:** ρητό «εγκρίνω freeze target».
**Έδρες / dispositions:** `.github/workflows` (REPLACE μέχρι πράσινο)· Dockerfile +
`deps.lock` + `docker/sbom.json` + `docker/cosign.pub` (REUSE)· `authority-v2/run-all.sh`
(REUSE ως πρότυπο 0/1/3)· `semantic-authority.lisp` / `PRIMARY_SEMANTIC_AUTHORITY`
(REMOVE της αξίωσης — AS-IS EV-11, CAP-139)· AS-IS R-1 έως R-6 (U-8: εκτελέσιμα τεστ).
**Πύλη εξόδου (μετρήσιμη):** κάθε workflow τρέχει και περνά σε δύο ανεξάρτητες
εκτελέσεις· `BLOCKED`/`FAIL`/`PASS` διακριτοί κωδικοί σε κάθε σουίτα· hermetic build
byte-ταυτόσημο ×2 (image digest)· SBOM παράγεται· U-8 κλειστό (6/6 REPORTED →
CONFIRMED ή REFUTED με εκτελέσιμο τεστ)· `PRIMARY_SEMANTIC_AUTHORITY` = 0 εμφανίσεις
σε μηχανικά αναγνώσιμη έξοδο· πρώτη μέτρηση SLO baseline (U-1 αρχικοί αριθμοί)·
`deployment/self/history.sexp` και `output/.healthy` ανέπαφα από την ανθρώπινη ροή.
**Φέτες:** προϋπόθεση VS-15. **Q:** Q18, Q40. **KW:** KW-59.

### Βήμα 1 — Εθνική απογραφή πηγών/δικαστηρίων + coverage ledger
**Στόχος:** δηλωμένο, root-signed census universe και ολική συνάρτηση κάλυψης (§4.1).
**Πύλη εισόδου:** έξοδος 0.
**Έδρες / dispositions:** `ingestion-daemon.lisp`, `legislation-ingestion.lisp`,
`government-source.lisp`, `document-fetch.lisp` (EXTEND: απαριθμητής τεύχος × έτος ×
αριθμός για κάθε σειρά)· `source-profile.lisp` (REUSE)· `capability-registry.lisp`/gap
ledger (EXTEND)· **MISSING:** coverage ledger ως ολική συνάρτηση (journal capability),
census-universe `RegistrySnapshot` (MLTP v3 §2.9), `coverage-and-freshness` claim.
**Πύλη εξόδου:** snapshot υπογεγραμμένο από owner root (ceremony rehearsal, όχι
production root ακόμη)· κάθε θέση με ακριβώς μία κατάσταση· δεύτερη ανεξάρτητη
απαρίθμηση με 0 ανεξήγητες αποκλίσεις· U-7 κλειστό (λίστα δικαστηρίων με νομίμως
δημοσιεύσιμες αποφάσεις)· U-1 freshness budgets ανά space ορισμένα από μέτρηση·
VS-13 περασμένη.
**Φέτες:** VS-13. **Q:** Q01, Q02, Q29. **KW:** KW-48.

### Βήμα 2 — Acquisition, ταυτότητα, provenance, αυθεντικότητα
**Στόχος:** κάθε artifact σφραγισμένο, με USC ids τεσσάρων επιπέδων, `authority-proof/2`,
custody chain, πλήρη RFC-3161, divergence witnesses (§4.2).
**Πύλη εισόδου:** έξοδος 1.
**Έδρες / dispositions:** `pdf-authority.lisp` (REUSE)· `layout-types.lisp`,
`validate-layout-graph.lisp`, `typographic-classifier.lisp`, `legal-ast.lisp` (EXTEND:
πίνακες/παραρτήματα)· `text-canonicalizer.lisp` (REUSE)· `corpus-provenance.lisp`,
`authority-proof-bundle.lisp`, `legal-authority-receipt.lisp` (EXTEND)· `legal-identity.lisp`,
`legal-id-registry.lisp` (EXTEND: manifestation επίπεδο, two-channel invariant)·
`x509-authority.lisp`, `asn1-der.lisp`, `timestamp-authority.lisp` (EXTEND: πλήρης
RFC-3161, PAdES/XAdES ανίχνευση)· **MISSING:** `authority-proof/2`, custody chain,
audiovisual manifestation.
**Πύλη εξόδου:** 100% των σφραγισμένων αντικειμένων με και τα τέσσερα provenance
στοιχεία· two-channel fixture ⇒ ένα `work_id`· VS-03 περασμένη· VS-01 checkpoint (1–3).
**Φέτες:** VS-03· VS-01 (1–3). **Q:** Q03, Q07, Q13, Q24. **KW:** KW-3, KW-4, KW-26,
KW-27, KW-44, KW-45.

### Βήμα 3 — Typed Legal IR + bitemporal event store
**Στόχος:** κλειστός κατάλογος 15 γεγονότων, `valid × known`, `legal-timeline/1` στο
payload, `audit-timeline/1` στο proof, `norm.determinacy` (§4.5, §4.3, MLTP v3 §2.0).
**Πύλη εισόδου:** έξοδος 2.
**Έδρες / dispositions:** `version-graph.lisp` (EXTEND: δικαστικά/ενωσιακά γεγονότα,
known_from ανά γεγονός)· `legal-temporal.lisp`, `legal-event-calculus.lisp`, `journal.lisp`
(REUSE)· `corpus-eu-links.lisp`, `eu-interop-layer.lisp` (EXTEND)· `citation-authority.lisp`,
`legal-decisions.lisp` (EXTEND: LATER-TREATMENT από explicit citations)· `legal-ast.lisp`
(EXTEND: `norm.determinacy`)· **MISSING:** `legal-timeline/1`/`audit-timeline/1` τύποι,
`norm.determinacy` τύπος.
**Πύλη εξόδου:** κάθε γεγονός με πηγή (KW-51 σκοτώνει)· KT5 μοντέλο (`TPKill`)
**εκτελεσμένο** με ≥1 σκοτωμένο witness· payload με audit πεδίο ⇒ `malformed-envelope`
(KW-61)· VS-02 checkpoint (1–4)· VS-01 checkpoint (4–6)· VS-07 checkpoint (IR).
**Φέτες:** VS-01 (4–6), VS-02 (1–4), VS-07 (IR). **Q:** Q05, Q06, Q08, Q41. **KW:**
KW-51, KW-60, KW-61.

### Βήμα 4 — Πρώτος ντετερμινιστικός Legal Compiler (Common Lisp)
**Στόχος:** από το journal ⇒ `legal_state_root` + `projection_roots` (ενοποιημένα
κείμενα, in-force sets, citation graph, line-of-authority), αναπαραγώγιμα (§4.6).
**Πύλη εισόδου:** έξοδος 3.
**Έδρες / dispositions:** `consolidation-engine.lisp`, `consolidation-proof.lisp`,
`version-graph.lisp`, `legal-inference-engine.lisp` (REUSE/EXTEND)· `release-authority.lisp`,
`release-gate.lisp`, `verify-truth-gate.lisp` (EXTEND: proposer-blind M5 πάνω στο νέο
root)· `deployment/verify/verify-temporal.py` (REUSE ως τρίτος έλεγχος).
**Πύλη εξόδου:** δύο εκτελέσεις ⇒ ίδιο `legal_state_root` (Q12)· `compiler-attestation`
με δικό του delegated κλειδί (rehearsal)· VS-01 checkpoint (7)· VS-02 checkpoint (5)·
VS-09 checkpoint (compiler A).
**Φέτες:** VS-01 (7), VS-02 (5), VS-09 (A). **Q:** Q11, Q12. **KW:** —.

### Βήμα 5 — Δεύτερος ανεξάρτητος compiler + differential verification
**Στόχος:** Rust compiler B (U-5), ίδιο journal, ισότητα ριζών πριν την υπογραφή,
αυτόματη καραντίνα (§4.6, §4.4).
**Πύλη εισόδου:** έξοδος 4· U-5 αποφασισμένο.
**Έδρες / dispositions:** **MISSING:** Rust compiler, differential harness· `release-gate.lisp`
(EXTEND: QUARANTINED path)· MLTP v3 §6 `dual_compiler_attestation`.
**Πύλη εξόδου:** VS-09 και VS-10 περασμένες· εγχυμένο σφάλμα ⇒ καραντίνα 1/1· 0
releases με μία attestation.
**Φέτες:** VS-09, VS-10. **Q:** Q33, Q34. **KW:** KW-52.

### Βήμα 6 — MLTP v3, offline verifier (PCL-2), distributed Trust Mesh
**Στόχος:** Layer 0 statements, 8 claim profiles, TrustBundle offline-resolvable,
VerificationReceipt με level ανά claim, verifiers Python/Node/Rust, vectors θετικά +
αρνητικά ανά error, threshold root ceremony, HSM delegated keys, δύο logs,
cross-client witness registry, SCITT προβολή (§4.10, MLTP v3).
**Πύλη εισόδου:** έξοδος 4· U-2 (registries: auditors, witnesses) θεσμικά κλειστό.
**Έδρες / dispositions:** `jws-authority.lisp`, `merkle-authority.lisp`, `hash-authority.lisp`,
`x509-authority.lisp`, `asn1-der.lisp`, `timestamp-authority.lisp` (REUSE/EXTEND:
Ed25519, RFC 7638, TSR επί της υπογραφής)· `authority-v2/` (EXTEND: roles, witness-quorum
test, ceremony)· `deployment/verify/verify.py`, `verify.mjs`, `verify-release.py`,
`verify-authority-bundle.py`, `kernel-verify.lisp` (EXTEND → MLTP v3)· `deployment/verify/vectors/`
(EXTEND)· `PROOF-CARRYING-LAW.md` (EXTEND → PCL-2 delegation-aware)· **MISSING:**
threshold signing, δεύτερο log, cross-client witness registry, SCITT projection, Rust
verifier.
**Πύλη εξόδου:** 35/35 error names με αρνητικό vector που τα τρία verifiers
αναγνωρίζουν ταυτόσημα· KW-1, KW-2, KW-5, KW-6, KW-9 έως KW-47 εκτελεσμένοι ως
vectors (όλοι `KILLS`)· VS-12 περασμένη· VS-11 checkpoint (verifiers, vectors iii/iv)·
VS-03 verifier βήμα· VS-09/VS-10 verifier R4· TLA+ για K2/K3/V/L1/S με σκοτωμένους witnesses.
**Φέτες:** VS-12· VS-11 (checkpoint)· VS-03, VS-09, VS-10 (verifier). **Q:** Q21, Q22,
Q23, Q26, Q28. **KW:** KW-1, KW-2, KW-5, KW-6, KW-9 έως KW-47.

### Βήμα 7 — Πολυτροπική acquisition + ontology-alignment plane
**Στόχος:** νευρωνικό runtime εξωτερικό, closed protocol (`neural-task/1`,
`neural-candidate/1`), OCR/layout candidates, alignment candidates, held-out
μέτρηση (§4.2, §4.3, §4.4).
**Πύλη εισόδου:** έξοδος 2· U-6 (held-out) ορισμένο.
**Έδρες / dispositions:** `safe-read.lisp` (REUSE: μοναδική είσοδος)· `document-fetch.lisp`
(REUSE ως πρότυπο εξωτερικού fetcher)· `legal-extraction-verify.lisp` (EXTEND)·
`greek-legislation-ontology.lisp`, `knowledge-graph.lisp`, `rdfs-inference.lisp`,
`shacl-validator.lisp` (EXTEND: alignment)· `proposals.lisp`, `anomaly-detection.lisp`,
`fluid-induction.lisp` (EXTEND: L5 lifecycle)· **MISSING:** protocol schema, νευρωνικό
runtime (Python/PyTorch/ONNX), OCR manifestation path.
**Πύλη εξόδου:** ελεύθερο πεδίο στο πρωτόκολλο ⇒ δεν μεταγλωττίζεται (αποδεδειγμένο
με αρνητικό build)· held-out σφάλμα μετρημένο (U-1 κατώφλι ορισμένο)· VS-04, VS-05
περασμένες· VS-06 checkpoint.
**Φέτες:** VS-04, VS-05· VS-06 (checkpoint). **Q:** Q04, Q30, Q31. **KW:** KW-49.

### Βήμα 8 — Νευρο-συμβολικός συλλογισμός + επιστημικό τείχος
**Στόχος:** προαγωγή candidate → Legal IR μόνο με συμβολική επικύρωση· determinacy
απαντήσεις· ρητή αποχή· L5 public workspace ζωντανό (§4.3).
**Πύλη εισόδου:** έξοδοι 3, 7.
**Έδρες / dispositions:** `legal-inference-engine.lisp`, `legal-deontic.lisp`,
`legal-event-calculus.lisp`, `legal-conflict-resolution.lisp`, `legal-dialectic.lisp`,
`legal-subsumption.lisp` (μόνο δημόσιος συλλογισμός — η υπαγωγή ιδιωτικών γεγονότων
DEFER_PRIVATE), `guard-metaeval.lisp` (REUSE/EXTEND)· `write-authority.lisp` (REUSE: μία
έδρα εγγραφής)· `advisor.lisp` (REUSE ως πρότυπο).
**Πύλη εξόδου:** VS-06, VS-07 περασμένες· Q09 τύπος-επίπεδο (PLANE-3 σε release ⇒
compile failure αποδεδειγμένο)· KW-7, KW-49, KW-50 `KILLS`.
**Φέτες:** VS-06, VS-07. **Q:** Q09, Q31, Q32, Q33. **KW:** KW-7, KW-49, KW-50.

### Βήμα 9 — Πλήρες jurisprudence-evolution plane
**Στόχος:** όλα τα δικαστήρια του census, ECLI/provisional_id, τέσσερις τάξεις,
reviewer registry + adoption act, line-of-authority γράφος, later treatment,
`authority_weight` μετρημένο (§4.9).
**Πύλη εισόδου:** έξοδοι 3, 8· U-3 (άδειες) κλειστό.
**Έδρες / dispositions:** `legal-decisions.lisp`, `decisions.lisp` (EXTEND)·
`citation-authority.lisp` (EXTEND)· `jurisprudence-judge.lisp` (REUSE)· `version-graph.lisp`
(EXTEND: line-of-authority)· `legal-precedent.lisp`, `legal-casegrammar.lisp`
(DEFER_PRIVATE — δεν αγγίζονται)· **MISSING:** ECLI υλοποίηση, reviewer registry +
adoption act, line-of-authority graph.
**Πύλη εξόδου:** VS-08 περασμένη· 0 `later_treatment` χωρίς anchor· 0 ratio χωρίς
adoption σε release· ανωνυμοποίηση typed 100%.
**Φέτες:** VS-08. **Q:** Q07, Q08, Q25, Q37. **KW:** KW-3, KW-7, KW-36, KW-44, KW-55.

### Βήμα 10 — National Legal Digital Twin + impact engine
**Στόχος:** corpus-wide `normative-impact-projection` με `replay_manifest`, ELI-Impact
προβολή, invalidation sets (§4.8, §4.5).
**Πύλη εισόδου:** έξοδος 4.
**Έδρες / dispositions:** `graph-reasoning.lisp` (EXTEND: `reason-impact` σε διτεμπορική
τομή)· `what-if.lisp`, `legal-counterfactual.lisp`, `legal-references.lisp`,
`legal-hypergraph.lisp` (REUSE)· `eu-interop-layer.lisp` (EXTEND: ELI-Impact)·
`corpus-diff.lisp` (EXTEND: invalidation set)· **MISSING:** replay manifest,
`normative-impact-projection` profile υλοποίηση.
**Πύλη εξόδου:** VS-02 ολοκληρωμένη (6)· auditor re-run ⇒ ίδιο `impact_root`· τύπος
χωρίς πεδίο έκβασης (KW-54 compile failure αποδεδειγμένο).
**Φέτες:** VS-02 (ολοκλήρωση). **Q:** Q36. **KW:** KW-54.

### Βήμα 11 — Proof-carrying query API / MCP / SDK + Citation-Bound Verification Profile
**Στόχος:** `proof-carrying-answer/1` (όλα τα πεδία §4.7), `CertifiedResult` +
`citation/1` + `CitationToken`, εκδοχοποιημένο OpenAPI, versioned MCP, λεπτά SDKs
(Python/TypeScript/Rust) με default rendering της διπλής παραπομπής, `/audit/{claim_id}`,
πρότυπα με επικύρωση (ELI, ECLI, AKN, RDF/PROV-O, SHACL, LegalRuleML για mechanical,
SCITT), signed delta feeds (§4.7, §4.11, §4.15, §4.16).
**Πύλη εισόδου:** έξοδοι 5, 6, 10.
**Έδρες / dispositions:** `legal-qa.lisp`, `legal-reasoning-bridge.lisp` (EXTEND)·
`proof-carrying.lisp` (REUSE)· `legal-dialectic.lisp` (EXTEND: counterproof)·
`mcp-server.lisp` (EXTEND: 4 εργαλεία → πλήρες σετ με υποχρεωτικό `citation`)·
`capability-api.lisp` (REUSE)· `canonical-uris.lisp` (EXTEND: canonical citation URLs)·
`json-emit.lisp` + `deployment/*.ttl` (EXTEND: JSON-LD)· `akoma-ntoso-emitter.lisp`,
`shacl-validator.lisp`, `sparql-endpoint.lisp`, `corpus-sparql.lisp` (REUSE)·
`ai-corpus-dump.lisp`, `ai-ingest-manifest.lisp` (EXTEND: feeds)· `deployment/verify/vectors/`
(EXTEND: citation vectors)· **MISSING:** answer type, OpenAPI, SDKs, LegalRuleML
emitter, `/audit` endpoint, conformance suite.
**Πύλη εξόδου:** VS-01 και VS-11 ολοκληρωμένες· 18/18 receipts της VS-11· σχήμα με
προαιρετικό `citation` ⇒ conformance FAIL αποδεδειγμένο· προεπιλεγμένη απάντηση χωρίς
`acquired_at` (Q41 γ)· SHACL 0 παραβιάσεις σε δημοσιευμένο RDF.
**Φέτες:** VS-01, VS-11 (ολοκλήρωση)· VS-13 (provider όψη). **Q:** Q14, Q27, Q35, Q38,
Q41, Q42. **KW:** KW-53, KW-56, KW-62, KW-63.

### Βήμα 12 — Ιστότοπος, cockpit, publication workflow
**Στόχος:** conversation-first app, `cockpit_intent` με RBAC/MFA, `/api/publish` →
approval intent στην ουρά M5, ιστότοπος από το ίδιο canonical release (§4.12).
**Πύλη εισόδου:** έξοδος 11.
**Έδρες / dispositions:** `cockpit.lisp` (EXTEND· `/api/publish` REPLACE)·
`http-server.lisp`, `review-service.lisp`, `review-queue.lisp`, `static-site.lisp`,
`approval-policy.lisp`, `decisions.lisp`, `corpus-diff.lisp` (REUSE)· **MISSING:** RBAC/MFA
registry, app shell.
**Πύλη εξόδου:** VS-14 περασμένη (4/4 απόπειρες δομικά αδύνατες)· το λειτουργικό
κριτήριο της Q15 (η συνομιλία του δημιουργού δείχνει τα οκτώ στοιχεία με τεκμήριο)
επιδεικνύεται σε owner docker proof.
**Φέτες:** VS-14. **Q:** Q15, Q17, Q20, Q39. **KW:** KW-38, KW-39, KW-57.

### Βήμα 13 — Citation observatory + security/operational observatory
**Στόχος:** πραγματικοί collectors ή typed `UNKNOWN`, ανίχνευση παραπομπής
ανακληθέντος υλικού, παρακολούθηση συμμόρφωσης providers με το citation profile, SLO
registry, vulnerability monitoring, DR runbook, δημόσιο incident feed, split-view drill
(§4.13, §4.14, §4.16).
**Πύλη εισόδου:** έξοδοι 11, 12.
**Έδρες / dispositions:** `ai-citation-strategy.lisp`, `citation-authority.lisp` (EXTEND)·
`configs/prometheus-citation.yml`, `deployment/templates/ai-citation-log.ttl` (REUSE)·
`LAWMAX-THREAT-MODEL.md` (EXTEND: Θ3/Θ4/Θ5/Θ9/Θ10 κλείσιμο)· `circuit-breaker.lisp`,
`logging.lisp` (REUSE)· **MISSING:** revoked-material detector, provider compliance
monitor, SLO registry, vulnerability monitoring, DR runbook, incident feed.
**Πύλη εξόδου:** VS-15 περασμένη (R ίσο, RTO/RPO μετρημένα — U-1 τελικοί αριθμοί)·
0 collectors που αναφέρουν «0» ενώ είναι stub· split-view drill με ανίχνευση 1/1·
stripped-citation κυκλοφορία ανιχνεύεται σε ελεγχόμενο σενάριο 1/1.
**Φέτες:** VS-15. **Q:** Q16, Q19, Q40, Q42 (παρακολούθηση). **KW:** KW-58, KW-59, KW-63.

### Βήμα 14 — Mission-scale qualification + provider adoption
**Στόχος:** `MISSION GREECE-1` (30 ημέρες, Q-tests §4) υπό independent auditors·
provider registry· `provider-adoption-qualified` από ≥2 providers· Root Authority
μόνο με τέσσερα φρέσκα QSR (§5).
**Πύλη εισόδου:** έξοδος 13· `SPEC`, `IMPLEMENTATION`, `SECURITY/OPERATIONS` QSR
υπογεγραμμένα από auditors (όχι από εμάς)· ρητή εντολή δημιουργού για εκκίνηση της
αποστολής.
**Έδρες / dispositions:** MLTP v3 §3.1 QSR issuance· provider registry (MISSING)·
`LocalTrustState.provider_registry`.
**Πύλη εξόδου:** Μ-1 έως Μ-6 για 30/30 ημέρες με ≥2 auditor receipts· καμία συνθήκη
ματαίωσης· `provider-adoption-qualified` υπογεγραμμένο από ≥2 registered providers·
όλα τα QSR με `expiry` και αυτόματη υποβάθμιση αποδεδειγμένη (KW-13, KW-25 σε
ζωντανή λήξη).
**Φέτες:** όλες οι 15 ως regression. **Q:** Q27, Q28 (και όλες οι Q01–Q42 ζωντανά).
**KW:** KW-12, KW-13, KW-25, KW-46.

---

## ΤΙ ΚΛΕΙΝΕΙ ΠΟΥ — ΣΥΝΟΨΗ

| τι | βήμα |
|---|---|
| `MISSING` συστατικά crosswalk §A (coverage ledger, census snapshot, authority-proof/2, custody chain, audiovisual, OCR path, protocol schema, Rust compiler, differential harness, threshold signing, δεύτερο log, witness registry, SCITT projection, answer type, OpenAPI, SDKs, LegalRuleML emitter, `/audit`, conformance suite, ECLI, reviewer registry, line-of-authority, replay manifest, RBAC/MFA, app shell, revoked-material detector, provider monitor, SLO registry, vulnerability monitoring, DR runbook, incident feed, provider registry) | 1, 2, 2, 2, 2, 7, 7, 5, 5, 6, 6, 6, 6, 11, 11, 11, 11, 11, 11, 9, 9, 9, 10, 12, 12, 13, 13, 13, 13, 13, 13, 14 (αντίστοιχα) |
| `REPLACE` (`.github/workflows`, `/api/publish`) | 0, 12 |
| `REMOVE` (`PRIMARY_SEMANTIC_AUTHORITY` αξίωση) | 0 |
| `DEFER_PRIVATE` (`legal-hypo.lisp`, `legal-precedent.lisp`, `legal-casegrammar.lisp`, υπαγωγή ιδιωτικών γεγονότων) | κανένα βήμα — δεν αγγίζονται |
| U-1 | 0 (baseline), 1 (budgets), 7 (OCR κατώφλι), 13 (RTO/RPO) |
| U-2 | πριν το 6 |
| U-3 | πριν το 9 |
| U-4 | πάσο 2 (πριν από κάθε βήμα) |
| U-5 | πριν το 5 |
| U-6 | πριν το 7 |
| U-7 | έξοδος 1 |
| U-8 | έξοδος 0 |
| KW-1 έως KW-63 ως εκτελέσιμα vectors/tests | 0 (59), 1 (48), 2 (3, 4, 26, 27, 44, 45), 3 (51, 60, 61), 5 (52), 6 (1, 2, 5, 6, 9 έως 47), 7 (49), 8 (7, 50), 9 (36, 55), 10 (54), 11 (53, 56, 62, 63), 12 (38, 39, 57), 13 (58, 63), 14 (12, 13, 25, 46) |

**Κανένα βήμα δεν έχει εκκινήσει. Κανένα δεν εκκινεί χωρίς «εγκρίνω freeze target».**
