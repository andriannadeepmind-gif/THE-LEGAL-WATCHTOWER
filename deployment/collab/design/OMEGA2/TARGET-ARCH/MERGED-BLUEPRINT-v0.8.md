# MERGED-BLUEPRINT v0.8 — WATCHTOWER ARCHITECTURE (draft for second Reviewer-B pass)

**Status:** v0.8 — incorporates Reviewer-B verdict «ACCEPT WITH MAJOR MODIFICATIONS — NOT READY TO
FREEZE» επί του v0.7, σημείο-προς-σημείο. Δεν είναι frozen contract· γίνεται v1.0 ΜΟΝΟ μετά τον
δεύτερο pass του Reviewer-B και το «εγκρίνω freeze» του δημιουργού. Καμία production αλλαγή πριν.
**Κανόνας αποδείξεων:** αμετάβλητος. `[V]` = επαληθευμένο path+γραμμή σε session· `[D]` = ρητή
design assumption/decision ή open-audit item· **κανένα design-critical `[A]` δεν παραμένει** —
βλ. §5 conversion table (περιλαμβάνει 3 διορθώσεις ΚΑΤΑ των δικών μου προηγούμενων audit claims).

## RESPONSE MAP (Reviewer-B item → πού απαντήθηκε)
| B-item | Απάντηση |
|---|---|
| 1 Invariants ACCEPT | §0 αμετάβλητο |
| 2 Claim Contract schema | §0.1 πλήρεις taxonomies + transitions |
| 3 System inventory 11↔12 | §1 canonical inventory — **12 systems** (το «11» του B6 ήταν λάθος μου· διορθωμένο) |
| 4 B0a critical-gate ορισμός + falsifiability≠independence | §2·B0a |
| 5 B0-2 security model | §2·B0-2 (issuance/expiry/scope/delegation/revocation/replay/audit/break-glass/SoD) |
| 6 B1 isolation surface + G-pub rollback REJECT + measurable stego | §2·B1 (rollback=publication-disabled· πλήρης λίστα surfaces· M-grade test spec) |
| 7 B2 split | §2·B2a/B2b/B2c |
| 8 B3 contracted dynamic resolution | §2·B3 |
| 9 B4 AND-τριάδα | §2·B4 (Falsifiability ∧ Independence ∧ Positive-Conformance για high-assurance) |
| 10 B5/D2 overlap | §2·B5 (shadow-only) / §3·D3 (production store) — μία γέννηση |
| 11 B6 deps | §2·B6 (εξαρτάται από B5 contract + §1 inventory) |
| 12 Downstream reorder | §3 — D0 Evidence Model → D1 Source Mesh Protocol πριν από κάθε semantic layer |
| 13 Normative IR schema + acceptance | §3·D2 (πλήρες σχήμα· serialize→parse→ίδιο IR· atom→source-span· round-trip demoted) |
| 14 Proof naming | §3·D8 — τρία artifacts· η λέξη «proof» ΜΟΝΟ για machine-checkable |
| M1–M10 | §4 — κανονικά sections |
| [A]-facts | §5 conversion table |
| Global discharge standard | §0.3 |
| Disposition provisional | §6 |

---

## 0. ARCHITECTURAL CONSTITUTION — I-1…I-10 (ACCEPTED, αμετάβλητα, μη διαπραγματεύσιμα)
1. Κανένα LLM δεν αποτελεί trust root. 2. Κανένας verifier αξιόπιστος επειδή ελέγχει output του
ίδιου implementation. 3. Κανένα subsystem με implicit authority. 4. Κανένα confidence δεν
μετατρέπει interpretation σε fact. 5. Κανένα derived conclusion χωρίς evidence/dependency state.
6. Κανένα external AI/provider call δεν παρακάμπτει matter/privilege/egress policy. 7. Καμία
production απόφαση legal temporal state έξω από τη μοναδική canonical temporal authority.
8. Boundaries machine-enforced. 9. Κάθε phase με executable discharge condition. 10. Νέα μηχανή
πρώτα σε shadow/differential όπου εφικτό.

## 0.1 CLAIM CONTRACT — implementation-grade schema (κλειστό)

**Claim (canonical record):**
```
Claim := ⟨ claim_id            : content-addressed id (hash της canonical μορφής) — ΑΜΕΤΑΒΛΗΤΟ
         , claim_type          : {legal-state, in-force, subsumption, deadline, conflict,
                                  interpretation, prediction, impact, meta}
         , statement           : typed proposition (όχι free text στο trusted layer)
         , epistemic_class     : EpistemicClass (κάτω)
         , lifecycle           : {ACTIVE, STALE, SUPERSEDED, REJECTED}
         , confidence_in_class : [0,1] ή ∅ — ΜΟΝΟ εντός class· ποτέ promotion (I-4)
         , derivation_assurance: A-level (κάτω)
         , formalization_fid   : F-level (κάτω)
         , coverage_stamp      : Coverage (κάτω)
         , world_context       : InterpretationWorld id (fact-world × construal-set × forum)
         , valid_time          : [t₁,t₂) legal validity την οποία αφορά
         , known_time          : t_known (record-time της γνώσης)
         , evidence_set        : {EvidenceRef…} — ≥1 ή το claim ΔΕΝ υπάρχει (I-5)
         , dependency_set      : {claim_id | authority_ref | provision@version …}
         , created_by          : principal (human/agent/engine + version)
         , supersedes          : claim_id | ∅ ⟩
```
**Αμεταβλητότητα (ADR-4):** claims δεν μεταλλάσσονται· νέα γνώση = νέο claim με `supersedes`.

**EpistemicClass (κλειστό enum + επιτρεπτές είσοδοι):**
- `AUTHORITATIVE_TEXT` — μόνο μέσω K-src admission (recompute-from-authentic-source).
- `VERIFIED_OBSERVATION` — capture+receipt+hash επιβεβαιωμένο (π.χ. «η απόφαση Χ δημοσιεύθηκε»).
- `DETERMINISTIC_DERIVATION` — παράγωγο με A≥A2 από premises κλάσεων {AUTH, VERIF, DET}.
- `LEGAL_INTERPRETATION` — προτεινόμενη ερμηνεία/υπαγωγή με κρίση· πάντα ανατρέψιμη.
- `DISPUTED_INTERPRETATION` — interpretation με καταγεγραμμένη ενεργή αντίκρουση.
- `PREDICTION` — forecast (conformal/στατιστικό)· ποτέ νομική «αλήθεια».
- `UNKNOWN` — τίμια άγνοια· first-class.
**Απαγορευμένες μεταβάσεις (CC-1):** καμία ανοδική αλλαγή class μέσω confidence/votes/επανάληψης/
LLM-consensus. `INTERPRETATION→DETERMINISTIC` ΔΕΝ υπάρχει ως μετάβαση: μόνο ΝΕΟ claim με δική του
A≥A2 derivation μπορεί να γεννηθεί ως DETERMINISTIC (και supersedes το παλιό). `→AUTHORITATIVE_TEXT`
μόνο από K-src, από τίποτα άλλο. Lifecycle: dependency change ⇒ STALE (αυτόματο, I-5/D4)· STALE
claim δεν σερβίρεται ως ACTIVE.

**A-levels — Derivation Assurance (κλειστή κλίμακα, διάταξη A0<…<A4):**
- **A0** unchecked assertion — μη-εκπεμπόμενο ως trusted.
- **A1** mechanically re-run από ΤΟ ΙΔΙΟ implementation (determinism replay) — ΟΧΙ independence.
- **A2** certificate ελεγμένο από ΑΝΕΞΑΡΤΗΤΟ checker (χωριστή υλοποίηση/θεμέλιο).
- **A3** A2 + N-version/differential συμφωνία ανεξάρτητων checkers.
- **A4** A3 + machine-checked θεώρημα για τον ίδιο τον checker (verified-kernel class).
Άνοδος ΜΟΝΟ με προσθήκη evidence artifact του αντίστοιχου είδους· ποτέ με ψήφους (I-2/I-4).

**F-levels — Formalization Fidelity (κλειστή κλίμακα, ceiling F3):**
- **F0** μηχανική εξαγωγή, μη-επικυρωμένη.
- **F1** επικύρωση από έναν ειδικό· χωρίς scope/ημερομηνία δέσμευσης.
- **F2** διπλή ανεξάρτητη φορμαλοποίηση reconciled + back-translation review + scoped+dated.
- **F3** F2 + contrastive test suite (near-boundary pairs) + re-attestation trigger δεμένο σε
  source changes. **F3 = ταβάνι· EMPIRICAL πάντα· ποτέ THEOREM.**
**Expiry:** οποιαδήποτε in-scope πηγή αλλάξει ⇒ το F πέφτει (artifact STALE) μέχρι re-attestation.
**Anti-laundering:** A-level ΠΟΤΕ δεν αναβαθμίζει F-level· συνολική ισχύς claim = min των αξόνων
στο πεδίο που αφορά.

**Coverage stamp (κλειστή δομή):**
`Coverage := ⟨C: construal-set id+hash, S: source-set ids@versions, T: time-window,
W: world-set, G: generator-manifest (ποιοι proposers/versions έτρεξαν)⟩`
Κάθε ισχυρισμός πληρότητας είναι ΠΑΝΤΑ σχετικός με stamp· stamp ελλιπές ⇒ K-typ REJECT (I-3).

## 0.2 ΑΞΟΝΕΣ ΩΡΙΜΟΤΗΤΑΣ
`kernel maturity / semantic coverage / operational maturity / production assurance` ∈
{ABSENT, SEED, PARTIAL, HIGH} — υποχρεωτικοί και οι 4 σε κάθε αναφορά ωριμότητας.

## 0.3 DISCHARGE-TEST STANDARD (GLOBAL — δεσμευτικό για ΚΑΘΕ μη-δυαδικό test)
Κάθε μη-δυαδικό discharge test δηλώνει: `fixture universe (πηγή+μέγεθος+ανανέωση)` ·
`metric` · `threshold` · `tolerance/στατιστικός κανόνας` · `failure action`.
«Μετρήθηκε» ΔΕΝ είναι acceptance condition. Πρότυπο παράδειγμα (χρησιμοποιείται στο B1):
`stego-exfil-redteam`: universe = ≥250 adversarial release-candidates σε 5 κλάσεις εξαγωγής
(paraphrastic, unicode/whitespace, metadata-channel, format-channel, semantic-steg) ×≥50,
ανανέωση κάθε release cycle· metric = miss-rate (per-class + overall)· thresholds: canaries
0 misses (hard), overall ≤2%, per-class ≤5%, Wilson 95% upper ≤8%· failure action = BLOCK
publication channel + incident + τα misses γίνονται μόνιμα fixtures + re-run υποχρεωτικό.
---

## 1. CANONICAL SYSTEM INVENTORY — **12 domain systems** (διορθώνει την ασυνέπεια 11↔12 του v0.7)

Στήλες: authoritative(A)/derived(D) · trust level (R1 trusted / R2 record / R3 untrusted /
CP control-plane) · state ownership · allowed→ / forbidden✗ dependencies. Public API: μία
δηλωμένη exported διεπαφή ανά system (ονομαστικά εδώ· πλήρη signatures στο M1/M5).

| System | Ευθύνη | A/D | Trust | State ownership | Deps → | ✗ Forbidden |
|---|---|---|---|---|---|---|
| `watchtower-kernel` | identity types, safe serialization, journal, hashes, merkle, signatures, certificate checking, capability issuance/verification | A | R1 | journal, receipts, capability ledger | (τίποτα εσωτερικό) | ΟΛΑ τα ανώτερα· **δεν γνωρίζει LLM** |
| `watchtower-canonical` | canonicalization, document/structural AST, references, identity resolution | A | R1/R2 | canonical documents, identities | kernel | temporal+, intelligence |
| `watchtower-temporal` | version-graph (**sole temporal authority**), legal events, commencement, regimes, resolve API | A | R1/R2 | version graph, temporal state | canonical, kernel | normative+, intelligence |
| `watchtower-normative` | Normative IR, inference JTMS/WFS, deontic, conflicts, event calculus | A(IR)/D(συμπεράσματα) | R2 | norm store, rule packs | temporal, canonical, kernel | intelligence, api |
| `watchtower-case` | subsumption, precedent, dialectic, case counterfactual, strategy, QA | D | R2/R3 | case analyses (ως Claims) | normative↓ | intelligence, api |
| `watchtower-twin` | claim/dependency/epistemic graph, impact propagation, invalidation, scenario branches, legislative counterfactual | D | R2 | claim+dependency store, sim branches | case↓ | intelligence ως authority |
| `watchtower-acquisition` | source adapters, fetch, capture, raw snapshots, receipts, diff→candidate events | A(evidence)/D(parse) | R3→R2 μέσω admission | raw blobs, captures, receipts | canonical, kernel | temporal decision-paths, intelligence |
| `watchtower-intelligence` | model registry, provider adapters, roles (extractor/researcher/counsel±/critic/citation-checker/synthesizer), adversarial reasoning, retrieval accelerators | D | **R3 μόνο** | ΚΑΝΕΝΑ authoritative state· μόνο proposals/scratch | twin↓ (read), G-inf για egress | **κάθε write σε A-store· κάθε direct egress** |
| `watchtower-practice` | matter isolation, ethical walls, privilege/data classes, deadlines/procedural calendars, conflicts, publication gateway (G-pub), egress gateway (G-inf) | A(policy) | R1(gates)/R2 | matter compartments, policy state, publication staging | kernel, temporal (resolve), case (read) | intelligence ως authority |
| `watchtower-governance` | proposals/review queues, capabilities policy, autonomy sandbox, SEV/upgrade ceremony (G-sev), ADRs, roles/SoD | CP | CP | proposal queues, upgrade records | kernel | trusted runtime writes εκτός ceremony |
| `watchtower-api` | HTTP/MCP/SPARQL/projections (RDF, JSON-LD, Akoma Ntoso, hypergraph), deploy/serve | D | R3-facing | **κανένα** — projections μόνο | twin↓ (read) | κάθε write σε A-store |
| `watchtower-observability` | traces, metrics, evaluation harness, golden-case runner, drift monitors | D | CP | telemetry (matter-tagged, access-controlled) | read-only παντού | κάθε write/side-effect σε A-store |

**Κανόνες DAG:** `intelligence → twin → case → normative → temporal → canonical → kernel`
(ποτέ ανάποδα)· πλάγιες: `acquisition→canonical/kernel`, `practice→{kernel,temporal,case-read}`,
`api/observability` read-only, `governance` μόνο μέσω ceremonies. Enforcement: §2·B3 (I-8).

### 1.1 Αντιστοίχιση 13-βάθμιας αλυσίδας → systems
1 Source Mesh→acquisition · 2 Evidence Layer→kernel(+acquisition blobs) · 3 Canonical→canonical ·
4 Bitemporal State→temporal · 5 Normative IR→normative · 6 Executable Normative→normative ·
7 Claim/Dep Graph→twin · 8 Impact→twin · 9 Counterfactual Twin→twin · 10 Adversarial
Intelligence→intelligence · 11 Practice/Matter/Privilege→practice · 12 Proof-Carrying
Outputs→kernel+normative+twin · 13 Attestation/Federation→governance+kernel.
(Το v0.7 §1 state assessment με maturity τετράδες παραμένει έγκυρο ως ΑΦΕΤΗΡΙΑ· βλ. v0.7 §1/§5.)
---

## 2. ENGINEERING CONTRACT — revised phases (B0a→B6). 9-field, όπου αλλάζει από v0.7.

### B0a — Baseline & Harness Qualification (falsifiability **≠** independence — B-item 4)
- **CRITICAL GATE (formal def):** ένα gate είναι *critical* iff το πράσινό του χρησιμοποιείται ως
  discharge evidence για migration item ή ως admission predicate στο trusted path. Κάθε critical
  gate απαριθμείται ρητά στο B0a inventory (όχι «όποιο κρίνει ο εκτελεστής»).
- **ΔΥΟ ΞΕΧΩΡΙΣΤΕΣ ΙΔΙΟΤΗΤΕΣ:** (i) **Falsifiability** — ∃ mutated fixture: gate=RED. (ii)
  **Independence** — ο verifier ΔΕΝ μοιράζεται implementation/conceptual bug με τον producer
  (χωριστός builder ή χωριστό θεμέλιο). Το B0a αποδεικνύει (i) για όλα· σημειώνει ρητά ποια gates
  ΔΕΝ έχουν (ii) → λίστα εισόδου για B4. **DISCHARGE:** πίνακας gate→{red-fixture, green-hash,
  independence: yes/no}· 0 critical gates χωρίς red-fixture (BLOCKED αλλιώς)· gates με
  independence=no περνούν υποχρεωτικά στο B4.

### B0-1 — Fail-closed constitutional gate — αμετάβλητο [V]. **DISCHARGE `fail-closed-fuzz`** (δυαδικό).

### B0-2 — emit-graph scope fail-open → **issued capability με πλήρες security model** (B-item 5)
- **CURRENT:** `write-authority:emit-graph` scope check `(when *current-write-authority* …)` [V]·
  capability primitives υπάρχουν ήδη: `capability-registry.lisp` — `:trust ∈ {:trusted,:advisor}`,
  «Άγνωστος τύπος ⇒ ΑΠΟΡΡΙΨΗ (fail-closed)» [V:46,57,94,114]. Άρα ΔΕΝ ξεκινάμε από μηδέν.
- **TARGET (capability security model, κλειστό):** το write context είναι capability object με
  `{issuer, holder, scope (matter/authority-class), expiry, delegation-chain (bounded),
  revocation-hook, replay-nonce, audit-binding (journal id), SoD-tag}`. **Break-glass:** emergency
  authority = χωριστός capability τύπος με (α) 2-person issuance, (β) ρητό expiry, (γ) υποχρεωτικό
  loud incident + auto-review, (δ) καμία delegation. Απουσία έγκυρου, μη-ληγμένου, in-scope,
  non-replayed capability ⇒ REJECT.
- **DISCHARGE `emit-guard+`:** (1) γυμνή κλήση ⇒ 0 bytes· (2) expired/out-of-scope/replayed
  capability ⇒ REJECT· (3) forged token ⇒ REJECT· (4) break-glass χωρίς 2ο issuer ⇒ REJECT +
  incident. (**Independence ∧ Falsifiability ∧ Positive-conformance** — έγκυρη capability ⇒ PASS.)

### B1 — Publication + Information Security Boundary (B-item 6, MAJOR)
- **Matter isolation surface (πλήρης, ρητή):** isolation = absence of handle σε ΟΛΑ τα εξής —
  canonical stores, vector indexes, caches, embeddings, temp files, logs, traces, exception dumps,
  backups, snapshots, agent memory, model context windows, exported artifacts, analytics/telemetry.
  Κάθε ένα: per-matter compartment ή structurally unreachable από άλλο matter.
- **G-pub rollback = REJECTED weaker path.** Σε failure του Publication Gateway: **publication
  disabled / fail-closed. ΚΑΝΕΝΑ production emergency bypass σε weaker boundary.** (Το v0.7 rollback
  «read-partition σε emergency» ΔΙΑΓΡΑΦΕΤΑΙ.)
- **Data classes** {PUBLIC, INTERNAL, CLIENT_CONFIDENTIAL, PRIVILEGED, WORK_PRODUCT, RESTRICTED}·
  PRIVILEGED/RESTRICTED ⇒ external backend capability structurally απών.
- **DISCHARGE:** `cross-matter-read`/`egress-privileged`/`route-audit` (δυαδικά, 0 bytes) +
  `stego-exfil-redteam` (πλήρες spec §0.3) + `publication-canary` (canaries 0 misses hard).

### B2 — Temporal Single Authority → **SPLIT B2a/B2b/B2c** (B-item 7, MAJOR)
- **B2a Canonical Temporal Query API:** μία typed είσοδος `resolve(provision, valid_at, known_at,
  context) → resolved-state | UNKNOWN`. Κάθε production in-force query περνά ΜΟΝΟ από αυτή.
  *DEFECT:* σήμερα σερβίρει το `consolidation-engine.lisp:406-415` (lexical) [V]· `:if-missing
  :skip` no-op υπάρχει (296-297) [V] και πρέπει να γίνει surfaced review event.
  *DISCHARGE `inforce-through-api`:* 0 in-force queries εκτός `resolve`· `no-silent-skip`.
- **B2b Historical Migration & Reconciliation:** legacy consolidation history ↔ version-graph, με
  **differential evidence** ότι καμία ιστορική κατάσταση δεν χάθηκε. *DISCHARGE `history-diff`:*
  ∀ (provision,date) στο golden corpus, legacy-result == vg-result ή καταγεγραμμένη εξήγηση·
  0 unexplained divergence.
- **B2c Structural Amendment Semantics:** `renumber, split, merge, delete, repeal, revive,
  correction, conditional-commencement, retroactivity`. *DISCHARGE `structural-replay`:* κάθε τύπος
  replays σε exact hashes σε golden recodification set.
- Το single-authority invariant (I-7) ικανοποιείται στο τέλος του B2a· B2c δεν το μπλοκάρει.

### B3 — Boundary Enforcement (B-item 8): **0 UNCONTRACTED dynamic cross-domain resolution**
- Απαγόρευση: cross-domain `pkg::private`, και `FIND-SYMBOL/INTERN/FDEFINITION/SYMBOL-CALL` που
  δεν περνούν από **δηλωμένο** generic protocol / typed registry / plugin interface.
- Νόμιμο runtime polymorphism ΕΠΙΤΡΕΠΕΤΑΙ μέσω registered protocols (whitelist με contract).
- *CURRENT:* `ingestion-daemon.lisp` κάνει σχεδόν όλες τις cross-package κλήσεις με `find-symbol`
  strings (30,43,45,47,49,51,66,84,94,96) [V]. *DISCHARGE `boundary-lint`:* 0 uncontracted dynamic
  cross-domain· contracted registry entries whitelisted+tested· `dag-acyclic`.

### B4 — Verifier Independence (B-item 9, MAJOR): **Falsifiability ∧ Independence ∧ Positive-Conformance**
- Για κάθε **critical/high-assurance** verifier απαιτούνται ΚΑΙ ΤΑ ΤΡΙΑ (όχι OR):
  (a) mutation fixture (βρίσκει το error class), (b) independent/differential implementation
  (μειώνει common-mode), (c) positive conformance (έγκυρα artifacts → PASS).
- **Verified defects (fixtures έτοιμα):** `consolidation-proof.lisp:113` re-uses builder + per-step
  before/after hashes serialized αλλά ΔΕΝ συγκρίνονται [V]· `narrative-provenance:verify-
  provenance-chain` κενό narrative ⇒ T [V]· `witness-quorum-test.py` evaluate_quorum in-test [V].
- **DISCHARGE:** ανά verifier `{mutation RED, independent-impl diff=0 σε clean, positive PASS}`.

### B5 — Claim Contract (SHADOW only) — (B-item 10, ξεμπλέκει από D3)
- **B5 = ΜΟΝΟ:** canonical Claim types (§0.1) + A/F/coverage taxonomies + anti-laundering enforcement
  + lifecycle + **shadow emission** (γράφει claims παράλληλα, ΔΕΝ σερβίρει) + self-model reconcile.
- *CURRENT:* `meta-ontology.lisp` axioms `doesNotResolveConflicts/SelectInterpretation/
  nonNormativeNature=true` anchored [V] vs 25 `legal-*` reasoners [V]. *MIGRATION:* REPLACE axioms
  (multi-world) + recompute commit hash. *DISCHARGE:* `no-laundering` (property) + `self-model-
  consistency` (axioms↔reasoners) + `shadow-claim-parity` (κάθε trusted output έχει shadow Claim).
- **Ο production claim/dependency STORE + indexing/query + propagation = D3, ΟΧΙ εδώ.**

### B6 — Runtime decomposition — εξαρτάται ρητά από **§1 inventory + B5 τελικό contract**
- move-not-rewrite· `behavior-invariance` (identical outputs) + `boundary-lint` GREEN + `system-load`.
- `autonomy/self-model/cognition` → governance sandbox· `omega` αποσυναρμολόγηση (FRBR→domains).
---

## 3. DOWNSTREAM BUILD — **reordered** (B-item 12): evidence/source contract FIRST

Νέα σειρά (η απαίτηση ήταν: παγωμένο source/evidence contract πριν τα υψηλά semantic layers — ΟΧΙ
όλες οι πηγές συνδεδεμένες). Κάθε νέο system shadow-first (I-10, operational contract §4·M10).

| # | System | TARGET INVARIANT (κύριο) | DISCHARGE (spec κατά §0.3 όπου μη-δυαδικό) | DEPS |
|---|---|---|---|---|
| **D0** Canonical Evidence Model | acquisition/kernel | `source→capture→receipt→hash` ΠΡΙΝ κάθε parse· immutable raw evidence· κανένα legal fact χωρίς προηγούμενο capture (I-5) | `evidence-before-parse` (δυαδικό: 0 parsed facts χωρίς receipt) | B0-2,B1,B2a |
| **D1** Source Mesh Protocol | acquisition | κοινό adapter contract DISCOVER/FETCH/SNAPSHOT/VERIFY/PARSE/NORMALIZE/IDENTIFY/DIFF/EMIT· νέα πηγή = plugin, kernel αμετάβλητος (I-8) | `adapter-conformance` (κάθε adapter περνά τα 9 βήματα σε golden fixtures)· `source-authority-policy` (M6) | D0 |
| **D2** Normative IR | normative | full normative schema (κάτω)· extraction admission μόνο μετά schema+source-align+symbolic-validate+review (I-1)· **acceptance: `serialize(IR)→parse→identical IR` + κάθε semantic atom→exact source span+provenance** (round-trip text diff REJECTED ως primary — B-item 13) | `ir-roundtrip` (serialize/parse idempotent)· `atom-source-span` (0 atoms χωρίς span)· `ir-admission` (χωρίς source-align ⇒ REJECT) | D1,B5 |
| **D3** Claim/Dependency Graph (PRODUCTION) | twin | production store + indexing + query + dependency propagation + invalidation integration· `P:v superseded ⇒ dependents STALE` (I-5) — **η παραγωγική έδρα του B5 shadow contract** | `impact-stale` (supersede ⇒ όλα dependents STALE, 0 τυφλά)· `query-consistency` | D2, B5 |
| **D4** Continuous Impact & Invalidation | twin | αυτόματο invalidation/recompute σε κάθε source change | `auto-invalidate` (injected amendment ⇒ recompute-required στα σωστά nodes, precision/recall=1 σε golden) | D3 |
| **D5** Legislative Change Simulator | twin | ephemeral branch· apply proposed act· recompute· impact report· ΧΩΡΙΣ μόλυνση production graph | `ephemeral-isolation` (production hashes αμετάβλητα)· `sim-reproducible` | D4 |
| **D6** Adversarial Intelligence Plane | intelligence | roles/registry· AI = proposal μόνο (I-1)· provider call = policy decision (I-6)· model IDs όχι hardcoded | `ai-no-authority` (AI output → authoritative μόνο μέσω symbolic+human gate)· `provider-policy` (call χωρίς egress-policy ⇒ DENY) | B1,D3 |
| **D7** Practice/Matter Plane (deadlines full) | practice | deadline kernel + εργάσιμες/διακοπές/ΚΠολΔ/suspension/service/e-filing/timezone· conflicts· evidence lifecycle | `deadline-corpus` (golden ελληνικές προθεσμίες: universe ≥200 cases incl. Αύγουστος/αργίες/ένδικα μέσα· exact match· 0 tolerance· fail=BLOCK)· dual-engine agree | B1,D3 |
| **D8** Reasoning Evidence/Proof Outputs — **ΤΡΙΑ artifacts** (B-item 14) | kernel+normative+twin | (i) **Source Authenticity Proof** (machine-checkable)· (ii) **Computation/Derivation Proof** (machine-checkable, όπου formal computation)· (iii) **Legal Reasoning Evidence Bundle** (structured evidence όπου interpretive judgment) — η λέξη «proof» ΜΟΝΟ για (i)/(ii) | `proof-vs-bundle-typing` (interpretive conclusion δεν φέρει «proof»)· `bundle-complete`· `independent-reverify` | D3,D6 |
| **D9** Attestation/Federation | governance+kernel | independent witnesses· verifier federation | `independent-repro` (2ο party ξαναχτίζει checker+re-verifies bundle corpus· divergence=fail) | D8 |
| **D10** Continuous Legal Evaluation | observability | historical replay + golden legal cases + auto re-eval σε κάθε change + νέα CI class gates | `legal-regression` (κάθε change re-runs golden· regression=block· thresholds κατά M9) | D3,D8 |

**Normative IR full schema (D2) — B-item 13:** constitutive rules · definitions · obligations ·
prohibitions · permissions · powers · liabilities · immunities · conditions · exceptions ·
defeaters · quantification · temporal applicability · territorial/personal/material scope ·
authority hierarchy · sanctions/remedies · procedural effects · cross-references · open-textured
concepts (typed ως τέτοια, όχι resolved) · alternative/disputed interpretations (first-class).

---

## 4. M1–M10 — MISSING SECTIONS (τώρα κανονικά· skeleton-grade, προς πλήρωση/κρίση)

- **M1 Canonical Domain/Data Model.** Exact schema + identity + lifecycle για: SourceCapture,
  SourceReceipt, Document, Provision, Version, LegalEvent, Norm, Claim, Evidence, Dependency,
  Matter, Publication, InterpretationWorld, Proof/EvidenceBundle. *Rule:* κάθε entity content-
  addressed· identity ποτέ mutable· lifecycle enum κλειστό. *(Claim/Coverage/A/F ήδη κλειστά §0.1.)*
- **M2 Storage & Transaction Architecture.** Layers: immutable raw blobs (WORM object store) ·
  append logs (journal) · canonical state · graph state · derived indexes · simulations ·
  caches. *Guarantees:* atomicity (single-writer commit boundary), idempotency (content-addressed
  writes), partial-failure/crash-recovery (WAL + fsync — σημ. journal ήδη έχει τίμιο fsync path,
  `*fsync-fault*` μόνο για tests [V]), snapshot/replay, ρητά commit boundaries. *ADR:* graph vs
  relational vs log-structured — προς ADR-storage (M7).
- **M3 Threat Model + Crypto Key Lifecycle.** Attacker classes: external, poisoned source, malicious
  provider/model, insider (single & colluding), supply-chain, side-channel. Keys: generation,
  storage (HSM/KMS), rotation, revocation, recovery, delegation, signer separation, witness
  compromise, break-glass. Trust boundaries = §1 trust levels. *Discharge:* red-team per class.
- **M4 Scale/Operations.** Targets (τάξεις): documents 10⁴–10⁵· provisions 10⁵–10⁶· versions 10⁶·
  claims 10⁶–10⁷· events/deps 10⁷. Incremental recomputation (dependency-driven, όχι full),
  indexing, caching, performance budgets, SLOs, backup/restore, RPO(=0 authoritative)/RTO,
  DR drills. **`watchtower-observability` = πραγματικό design εδώ, όχι μόνο όνομα.**
- **M5 Protocol/Schema Versioning.** Normative IR v1→v2, Claim schema, source protocol, proof/
  bundle formats· compatibility windows, migrations, upgrade proofs, deprecation· semver +
  machine-checked migration.
- **M6 Source Authority & Jurisdiction Policy.** Ποια πηγή authoritative για ποιο document/
  jurisdiction· επίλυση: source conflict, correction, late discovery, republication, official vs
  derivative, court/reporting discrepancies· official > derivative· conflict ⇒ DISPUTED claim.
- **M7 Architecture Decision Records.** ADR ανά foundational απόφαση (sole temporal authority,
  RDF projection-only, AI advisor-only, claim immutability, storage choice, federation model,
  matter isolation model), format `context/decision/alternatives/reason/consequences/supersession`.
- **M8 Human Governance / SoD.** Ρόλοι+rights: source-policy maintainer, ontology/rule author,
  reviewer, publisher, security officer, key custodian, emergency authority· καμία critical αλλαγή
  χωρίς explicit governance path· author≠reviewer by construction.
- **M9 Evaluation Governance.** Golden legal cases: creation, expert adjudication, versioning,
  disagreement resolution, coverage, contamination control, thresholds, regression policy,
  calibration. *Rule:* golden set υπό M8 governance· contamination = disqualifies case.
- **M10 Upgrade Contract (I-10 operationalized).** `old → new-shadow → differential-evaluation →
  promotion → rollback-window → retirement/death-record`, καθένα με ρητό discharge + audit.

## 5. `[A]` → `[V]`/`[D]` CONVERSION (B-item: no design-critical `[A]` at freeze)

| Πρώην `[A]` claim | Νέα κατάσταση | Απόδειξη / σημείωση |
|---|---|---|
| capability primitives υπάρχουν | **[V]** | `capability-registry.lisp:46,57,94,114` (:trusted/:advisor, fail-closed) |
| journal fsync gap «missing» | **[V→ΑΝΑΚΛΗΣΗ]** | Λάθος μου: το journal έχει τίμιο fsync path· `*fsync-fault*` είναι test-only injection [V:203-207]. Το «fsync gap» ΑΠΟΣΥΡΕΤΑΙ· μένει μόνο genesis-append edge να επιβεβαιωθεί ξεχωριστά → **[D]** open-audit |
| corpus-provenance fabricated `2025-01-01` | **[V→ΑΝΑΚΛΗΣΗ]** | 0 occurrences σήμερα· το claim ΑΠΟΣΥΡΕΤΑΙ (πιθανώς διορθωμένο ή σε άλλο seat) |
| self-history naive `SEQ|AT|KIND|TEXT|PREV` hash | **[V]** | `self-history.lisp:36-37` — delimiter-injection class· UPGRADE σε canon-sexp |
| provenance-model = build-pipeline (`:parse/:generate-rdf/:anchor`, Blake2) | **[V]** | `provenance-model.lisp:15,160,223,230,246` — legal-provenance refactor· blake label να ελεγχθεί |
| ai-citation-strategy SEO/beacon egress | **[V]** (μερικώς) | beacons/beacon-hits/external base-uri [V:8,31,49-51]· DOI/CC-BY να επιβεβαιωθούν ξεχωριστά → RETIRE από trusted core παραμένει |
| consolidation `:if-missing :skip` silent | **[V]** | `consolidation-engine.lisp:296-297` |
| 25 legal-* reasoners vs anchored non-normative self-model | **[V]** | `ls source/legal-*.lisp` = 25· meta-ontology axioms [V] |
| omega «DARPA/ORCHESTRATORSUPER» semantic debt | **[V]** | `DEPENDENCY-CONTRACT.md` + omega tests αναφέρουν· ARCHIVE/regenerate |
| authority-v2 store «forbids append-log as final» (substrate αντίφαση) | **[D]** open-audit | δεν επιβεβαιώθηκε γραμμή σε αυτό το pass· παραμένει προς Reviewer-B verification πριν disposition |

**Κανόνας:** κανένα item σε §2/§3/§6 δεν εξαρτάται από εναπομείναν `[A]`. Τα δύο εναπομείναντα
`[D]` open-audit (genesis-fsync edge, authority-v2 substrate) ΔΕΝ είναι phase-blockers· σημειώνονται
για verification πριν το αντίστοιχο disposition οριστικοποιηθεί.

## 6. DISPOSITION TABLE — provisional· κάθε row αποκτά (B-item) 4 επιπλέον πεδία πριν v1.0
Ο πίνακας του v0.7 §4 ισχύει ως ΒΑΣΗ. Πριν το freeze, κάθε disposition επεκτείνεται με:
`destination API` · `state migration` · `dependency delta` · `retirement condition`.
Rows που εξαρτώνταν από `[A]` → τώρα `[V]` (πίνακας §5) εκτός των 2 `[D]` open-audit, που μένουν
**PROVISIONAL** μέχρι Reviewer-B verification.

## 7. FREEZE GATE
v1.0 = μετά: (α) 2ος Reviewer-B pass ACCEPT σε §0.1 taxonomies, §1 inventory, §2 B2a/b/c & B4-τριάδα,
§3 reorder & IR acceptance & D8 τριάδα, §4 M1–M10 πλήρη, §5 μηδέν design-critical `[A]`· (β) οι 4
disposition πεδία συμπληρωμένα· (γ) «εγκρίνω freeze» δημιουργού. ΜΟΝΟ τότε αρχίζει B0a.
