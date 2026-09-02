# LAWMAX — SECURE-SEMANTIC-INGRESS-CONTRACT (canonical trust boundary)
# EXTERNAL BYTES ≠ LISP FORMS — ΚΑΜΙΑ ΔΙΑΔΡΟΜΗ EXTERNAL INPUT → LISP READER/EVAL

**ΚΑΤΑΣΤΑΣΗ: `DESIGN-ONLY · ACTIVE SHARED TRUST FOUNDATION`.** Καμία γραμμή κώδικα, κανένα
freeze. Η **κανονική έδρα** (μία ανά έννοια) του trust boundary εισόδου, απαιτούμενη από
`CHANGE-PROPOSAL-v1.4.md §4.3/§4.4` και τον νόμο του repo «ΚΑΝΕΝΑ LLM/untrusted input στο
έμπιστο μονοπάτι». POST-C2 closure §3.H/§4.8.

**Μοντέλο ιδιοκτησίας (ρητό):**
- **Secure Semantic Ingress Contract** = η **κανονική** έδρα-συμβόλαιο του **εξωτερικού
  trust boundary** (αυτό το κείμενο).
- **External non-evaluating JSON/CBOR decoder** = **ΝΕΑ, MISSING** έδρα υλοποίησης
  (**WP-02**) — το μόνο σημείο αποκωδικοποίησης εξωτερικής εισόδου.
- **`source/safe-read.lisp`** = **γειτονικό ΕΣΩΤΕΡΙΚΟ-ΜΟΝΟ primitive** για έμπιστα/
  αυτο-γραμμένα S-expressions· **ούτε επεκτείνεται ούτε χρησιμοποιείται** από την εξωτερική
  ingestion (χρησιμοποιεί `cl:read`· ρητά «ΟΧΙ public ingestion boundary»).

## 0. Ο αμετάκλητος invariant

**External bytes ΔΕΝ γίνονται ποτέ Lisp forms.** Δεν υπάρχει **καμία** διαδρομή
`external input → Lisp reader | reader-macro | macro-expander | compiler | eval`. Το
untrusted υλικό ταξιδεύει **μόνο** ως opaque bytes → constrained parser → **κλειστό typed
AST/Legal IR** (δεδομένα, όχι κώδικας). Παραβίαση ⇒ δομικά αδύνατη, όχι απαγορευμένη.

## 1. Taint states (μονότονη, μη αναστρέψιμη προαγωγή)

```
UNTRUSTED → PARSED → VALIDATED → ADOPTED → CANONICAL
```
- **UNTRUSTED:** opaque bytes (PDF/XML/HTML/OCR/JSON/feed). Καμία ικανότητα.
- **PARSED:** προϊόν sandboxed parser = **κλειστό typed AST** (Legal IR node set), ποτέ
  Lisp form. Μεταπήδηση μόνο μέσω structural validator.
- **VALIDATED:** πέρασε deterministic **symbolic** validator (schema + typing + anchors).
- **ADOPTED:** reviewer/InstitutionalAct adoption όπου θεσμικό (§4.9 τάξη 3).
- **CANONICAL:** μέσα σε υπογεγραμμένο release. **Ποτέ** χωρίς πλήρη αλυσίδα.

Καμία κατάσταση δεν παρακάμπτεται· κάθε μετάβαση journaled (L1). Regressive μετάβαση ⇒
`ingress-nonmonotonic-taint` (fail-closed).

## 2. Ο ΑΓΩΓΟΣ ΕΞΩΤΕΡΙΚΗΣ ΕΙΣΟΔΟΥ (distinct από το `safe-read.lisp`)

**ΔΙΟΡΘΩΣΗ (micro-pass defect 1):** το `source/safe-read.lisp` είναι **ΕΛΑΧΙΣΤΟ ΕΣΩΤΕΡΙΚΟ
primitive** για **έμπιστα, αυτο-γραμμένα data-only S-expressions** (χρησιμοποιεί `cl:read`
με `*read-eval*` NIL, keyword package, data-only readtable· δηλώνει ρητά «ΟΧΙ public
ingestion boundary»). **ΔΕΝ είναι ο decoder δημόσιας νομικής εισόδου** και **κανένα
εξωτερικό byte δεν φτάνει σε αυτό.** Ο εξωτερικός αγωγός είναι **διακριτός** και **δεν
περνά ποτέ από τον Lisp reader**:

```
opaque bytes
  → sandboxed format parser (out-of-process, καμία ικανότητα fs/net/subprocess/clock-write)
  → canonical JSON/CBOR ingress envelope  (`ingress-envelope/1` — RFC 8785 JCS / RFC 8949)
  → non-evaluating schema decoder  (JSON/CBOR → typed DTO· ΟΧΙ `cl:read`, ΟΧΙ eval/macro/compile)
  → typed DTO / Legal IR  (δεδομένα)
```
- **Κανένα εξωτερικό byte** δεν περνά από `cl:read`/`read-from-string`/reader-macro ούτε
  ερμηνεύεται ως Lisp source syntax.
- Το προκύπτον **typed DTO** μπορεί να γίνει εσωτερικό Lisp αντικείμενο, αλλά **ποτέ
  reader-produced source form** και **ποτέ** όρισμα σε `eval`, macro-expansion ή compilation.
- Ο **non-evaluating schema decoder** είναι νέα, χωριστή έδρα (MISSING, Implementation Book
  WP-02) — **ΟΧΙ** το `safe-read.lisp`.

**Τυποποιημένα envelopes — δύο ξεχωριστές διαδρομές:**
```
parser-result/1  = { "kind": <"pdf"|"xml"|"html"|"ocr"|"json"|"feed">, "manifestation_id",
                     "artifact_digest": "sha256:<hex>", "content": <canonical JSON DTO>,
                     "parser_id", "parser_manifest_sha256" }   # ΝΤΕΤΕΡΜΙΝΙΣΤΙΚΟΙ parsers
neural-candidate/1 = (§4.3, PLANE-3)                            # ΜΟΝΟ η νευρωνική λωρίδα
```
**ΔΕΝ** δρομολογείται κάθε ντετερμινιστικός parser μέσω `neural-task/1 ↔ neural-candidate/1`·
οι ντετερμινιστικοί parsers παράγουν `parser-result/1` (`ingress-envelope/1`)· το
`neural-candidate/1` κρατιέται **αποκλειστικά** για τη νευρωνική (μη εξουσιοδοτική) λωρίδα.

## 3. Απαγορεύσεις στο trusted (Lisp) επίπεδο — πολυεπίπεδη άμυνα

- `*read-eval*` **disabled** — αλλά **ΟΧΙ ως μοναδική άμυνα** (defense in depth).
- **Απαγόρευση `read-from-string` / `read` πάνω σε untrusted input** — καμία κλήση reader
  σε external bytes· ο μόνος parser είναι ο constrained grammar parser (όχι ο Lisp reader).
- **Reader-macro / dispatch-macro escape prevention:** custom readtable **χωρίς** ενεργά
  reader macros για untrusted paths· `#.`, `#,`, `#+/#-`, `#(`, `#*` κ.λπ. αδρανή.
- **Package / symbol escape prevention:** καμία `intern`/`find-symbol` από external bytes·
  κανένα `pkg::sym` δεν προκύπτει από untrusted input· symbols του AST είναι **κλειστό,
  προ-δηλωμένο σύνολο keywords** (node kinds), όχι δυναμικά interned.
- **No package qualifier, no `|escaped|`, no `\` escapes** που να αλλάζει symbol resolution.

## 4. Constrained grammar + structural + symbolic validators

- **Constrained grammar:** το untrusted parsing δέχεται **μόνο** τη γλώσσα του τύπου
  (ST-nn profile, source-registry)· ό,τι δεν ανήκει ⇒ `ingress-grammar-violation`.
- **Structural validator:** επιβάλλει το closed AST schema (βάθος, arity, κλειστά kinds).
- **Deterministic symbolic validator:** typing + anchors + no-boolean-in-hash-record.
- **Neural semantic detector:** **μη εξουσιοδοτική ένδειξη** μόνο (`neural-candidate/1`,
  PLANE-3)· ποτέ δεν προάγει μόνο του UNTRUSTED→VALIDATED (I-4.3a).

**Τι ΑΠΟΔΕΙΚΝΥΟΥΝ — και τι ΔΕΝ αποδεικνύουν — οι validators (καμία υπερβολική αξίωση):**
- Ο **structural** validator αποδεικνύει **μόνο** συμμόρφωση με το κλειστό AST schema
  (βάθος/arity/κλειστά kinds) — **schema conformance**, τίποτα παραπάνω.
- Ο **symbolic** validator αποδεικνύει **μόνο** το **δηλωμένο** typing + invariants + anchors.
- **Κανένας** από τους δύο **δεν** αποδεικνύει καλόπιστη **πρόθεση**, ούτε **αυθεντικότητα/
  προέλευση** πηγής. Ένα «semantically valid-looking malicious» candidate **μπορεί να περάσει**
  και τους δύο validators — αυτό **δεν** το καθιστά έμπιστο και **δεν** ανιχνεύεται «μαγικά» ως
  κακόβουλο.
- Ένα candidate που περνά structural + symbolic **παραμένει VALIDATED**, **ΠΟΤΕ** αυτομάτως
  ADOPTED/CANONICAL: η προαγωγή απαιτεί **επιπλέον** (i) **επαληθευμένη προέλευση**
  (provenance), (ii) **εξουσιοδοτημένη πηγή/αρμοδιότητα** (source-registry authority · §4.9
  τάξη 3) και (iii) **εφαρμοστέα adoption policy** (InstitutionalAct). Απόντα, ανεπαρκή ή
  **συγκρουόμενα** ⇒ **καμία CANONICAL προαγωγή** και **μηδενική παρενέργεια** (fail-closed).

## 5. Τρεις ΞΕΧΩΡΙΣΤΕΣ είσοδοι (καμία σύγχυση)

| είσοδος | τι δέχεται | trust path | ποτέ |
|---|---|---|---|
| **Legal ingestion** | opaque legal bytes (ST-nn) | §2 sandbox → AST → validators | ποτέ Lisp form· ποτέ code |
| **Cockpit intent** | typed `cockpit_intent` (§4.12, κλειστό σχήμα, RBAC/MFA) | signed intent → M5 queue | ποτέ direct-publish· ποτέ eval |
| **Code changes** | source diffs | ανθρώπινη έγκριση + gates (L12) | ποτέ από legal/cockpit input |

Η σύγχυση των τριών (π.χ. legal bytes ως code, ή cockpit intent ως legal object) ⇒
`ingress-channel-confusion` (fail-closed).

## 6. Extension error taxonomy (διακριτή από MLTP §4.3)
```
ingress-nonmonotonic-taint · ingress-grammar-violation · ingress-channel-confusion ·
non-canonical-ingress-envelope · schema-decode-failed · reader-reached-external-bytes ·
read-time-execution-attempt · reader-macro-escape · package-symbol-escape ·
excessive-nesting · decompression-bomb · xml-entity-expansion · injected-directive ·
ontology-poisoning-candidate · unvalidated-neural-promotion
```
Κάθε όνομα έχει βήμα εκπομπής (§2/§4/§5). `reader-reached-external-bytes` = δομικό
invariant violation (εξωτερικά bytes έφτασαν σε `cl:read`) ⇒ fail-closed. Καμία boolean σε
hash-record.

## 7. Predeclared kill tests — `UNEXECUTED` (design-only· το boundary ΔΕΝ έχει ακόμη επιβιώσει) — κάθε ένα ΘΑ αποδεικνύει ΜΗΔΕΝΙΚΗ παρενέργεια

| SIK | επίθεση | αναμενόμενο |
|---|---|---|
| **SIK-1** | read-time execution (`#.(delete-file ...)` σε untrusted) | `read-time-execution-attempt`· 0 side effect (no file/proc/net) |
| **SIK-2** | reader macro / dispatch escape | `reader-macro-escape`· inert readtable |
| **SIK-3** | package/symbol escape (`cl-user::*x*`) | `package-symbol-escape`· καμία intern |
| **SIK-4** | excessive nesting (10^6 βάθος) | `excessive-nesting`· bounded, no stack blow |
| **SIK-5** | archive/PDF decompression bomb | `decompression-bomb`· bounded output, sandbox killed |
| **SIK-6** | XML entity expansion (billion laughs) | `xml-entity-expansion`· entities disabled |
| **SIK-7** | prompt injection στο κείμενο εγγράφου | `injected-directive`· neural = μη εξουσιοδοτικό· καμία εντολή εκτελείται |
| **SIK-8** | ontology poisoning (κακόβουλο mapping candidate) | φραγμένο από **υπογεγραμμένη/versioned ontology authority + adoption policy** (ΟΧΙ από «ανίχνευση κακίας» του validator)· ένα schema-valid mapping **μπορεί** να περάσει validation αλλά **μένει μη-CANONICAL** χωρίς εξουσιοδοτημένη ontology έκδοση· απαιτούμενο: **καμία CANONICAL προαγωγή + μηδενική παρενέργεια** |
| **SIK-9** | semantically valid-looking malicious legal candidate | ένα schema-valid candidate **μπορεί** να περάσει structural + symbolic validation· **μένει μη-CANONICAL** όταν provenance/authority/adoption είναι **απόν ή συγκρουόμενο**· απαιτούμενο αποτέλεσμα: **καμία CANONICAL προαγωγή + μηδενική παρενέργεια** (ΟΧΙ «μαγική» ανίχνευση πρόθεσης) |

**Απόδειξη μηδενικής παρενέργειας:** κάθε SIK τρέχει σε sandbox με 0 capabilities· το
harness επιβεβαιώνει καμία εγγραφή fs/net/proc, καμία μεταβολή taint state πέρα από
`UNTRUSTED`. (Implementation Book work package· ΜΗ εκτελεσμένο.)

## 8. Έδρες & τι ΔΕΝ κάνει

**Έδρες:**
- `source/safe-read.lisp` — **ΕΣΩΤΕΡΙΚΟ ΜΟΝΟ**, για έμπιστα/αυτο-γραμμένα data-only
  S-expressions· **ΟΧΙ** έδρα δημόσιας νομικής εισόδου, **ΟΧΙ** external decoder (διατηρείται
  αμετάβλητο· το `cl:read` του δεν αγγίζει ποτέ εξωτερικά bytes).
- `document-fetch.lisp` (external fetcher orchestration πρότυπο: REUSE).
- §4.3/§4.4 neural runtime = sandbox host (νευρωνική λωρίδα μόνο).

**MISSING (Implementation Book, WP-02):** capability-less sandbox host, sandboxed format
parsers ανά ST → `ingress-envelope/1`, **non-evaluating JSON/CBOR schema decoder** (η
ΝΕΑ, χωριστή έδρα εξωτερικής εισόδου — ΟΧΙ `safe-read.lisp`), taint-state enforcer, SIK
harness. **Δεν** υλοποιεί τίποτα· δεν είναι γενική παράγραφος ασφαλείας — είναι **δομικό
trust boundary** με invariant, taint states, κλειστή error taxonomy και **UNEXECUTED**
predeclared kill tests (§7: το boundary **δεν** έχει ακόμη επιβιώσει των SIK-1..9).

## 9. APPENDIX — SPEC v1.5 NARROW-DELTA · D1 INDEPENDENT SEMANTIC ADMISSION (CANDIDATE · NOT FROZEN)

**Additive· το frozen v1.4 περιεχόμενο (§0–§8) είναι αμετάβλητο· frozen commit `88129099` δεν γίνεται
amend.** Machine-readable: `deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.5-SCHEMAS.sexp`. Full
spec: `CHANGE-PROPOSAL-v1.5.md §1`. **Καμία universal N-version processing.**

Στην adoption boundary ορίζεται `SemanticAdmissionAssuranceProfile` (κλειστό): **SA-0 STRUCTURAL**
(schema+anchors), **SA-1 CHECKABLE** (derivation + μικρός ανεξάρτητος checker), **SA-2 STATE_MUTATING**
(ανεξάρτητη source→event derivation + independent check + divergence gate + adoption act). **Type-closed
(v1.5 micro-pass· §11.1):** τα πεδία του `SemanticAdmissionEvidence/1` έχουν **per-profile cardinality**
(R required / F forbidden / C conditional) — π.χ. `transformation_proof_ref` **forbidden** για SA-0 (καμία
transformation)· `independent_derivation_ref` **R μόνο** για SA-2· `derivation_independence_evidence_ref`
XOR `residual_independence_assumption` (SA-2)· `adoption_act_ref` R μόνο για SA-2. Event kinds: SA-0
`ANCHOR/CITATION_ANCHOR/OBSERVATION`· SA-1 `CLASSIFICATION/CROSS_REFERENCE/LATER_TREATMENT_EXTRACTION`·
SA-2 **πλήρης κατάλογος (§11.2)**: `ENACTMENT/AMENDMENT/COMMENCEMENT/REPEAL/SUSPENSION/REVIVAL/ANNULMENT/
CORRECTION/DELEGATED_AUTHORITY_CHANGE/REGIME_EFFECTIVITY_TRANSITION/CONSTITUTIONAL_REVIEW_STATE_CHANGE/
JUDICIAL_REVIEW_STATE_CHANGE/LINE_OF_AUTHORITY_MUTATION`.

Πραγματική diversity μηχανισμού = διακριτό `derivation_family_id` **ΚΑΙ** διακριτό
`derivation_artifact_digest` σε ανεξάρτητη source→event διαδρομή· ίδιο family/artifact ⇒
`INDEPENDENCE_INSUFFICIENT` (αποφυγή «δύο binaries πάνω στο ίδιο σφάλμα/spec»). `DivergenceState`:
`AGREED · DETERMINISTIC_DIVERGENCE (⇒ QUARANTINED) · INTERPRETIVE_DISAGREEMENT (⇒ typed argument L5/L6,
ΟΧΙ error, ΟΧΙ majority vote) · INDEPENDENCE_INSUFFICIENT · UNKNOWN`.

**Invariant V5I-01 (hard):** `SA-2 MUST NOT transition ADOPTED → CANONICAL unless its semantic-admission
evidence obligation is satisfied.` Ένα schema-valid αλλά λάθος state-mutating γεγονός γίνεται
**`QUARANTINED`**, ακόμη κι αν οι downstream compilers συμφωνούν. Kill witnesses (predeclared, ΜΗ
εκτελεσμένα): V5KW-D1-1..5.
