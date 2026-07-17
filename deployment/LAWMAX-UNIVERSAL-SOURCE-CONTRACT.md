# LAWMAX — UNIVERSAL SOURCE CONTRACT (Π7-U.1) · **v6 — Π7-U.1C KNOWLEDGE-CUT AND LEGAL-FORM CLOSURE** · ΑΥΤΟΤΕΛΕΣ

**Κατάσταση:** ΠΡΟΤΑΣΗ προς τελική εξέταση («εγκρίνω Π7-U.1» εκκρεμεί).
Π7-U.2: ΠΑΓΩΜΕΝΟ. ΚΑΝΕΝΑ download/connector/υλοποίηση.
**Ιστορικό:** v1 → 2 κριτές [Ν]/[Α] → v2 → δημιουργός [Δ-1..9] → v3 →
2 κριτές [Κ]/[Τ] → v4 → δημιουργός [Β-1..7] → v5 (ΑΥΤΟΤΕΛΕΣ) → δημιουργός
[Γ-C1..C4, Γ-S1..S3] → **v6 = παρόν, Π7-U.1C**. Πλήρης πίνακας ευρημάτων/
κλεισιμάτων/witnesses: `LAWMAX-UNIVERSAL-SOURCE-CONTRACT-CLOSURE-MATRIX.md`
(συνοδευτικό παραδοτέο — η ακριβής καταμέτρηση ζει ΕΚΕΙ).
**ΑΥΤΟΤΕΛΕΙΑ:** όλα τα normative schemas/invariants αυτούσια εδώ· καμία
κανονιστική αναφορά σε προηγούμενη έκδοση (W-SPEC-SELF-CONTAINED)· οι
δείκτες [x] = ιστορική απόδοση μόνο.
**Εγκεκριμένη βάση:** `b87f7d8b`. **#4A/B/C: CLOSED & FROZEN** (Πράξη
Έγκρισης `eb631750`). GAAF-1 + reasoning layers ΠΑΓΩΜΕΝΑ.

**Θεμελιώδεις αρχές:**
(α) ΚΑΝΕΝΑ hardcoded enum για επεκτάσιμα δεδομένα — versioned registries·
ΚΛΕΙΣΤΑ στο schema μένουν ΜΟΝΟ τα γνήσια οντολογικά sum types (expression
kinds, work_form, origin kinds, locator types) [Γ-S3]· (β) ταυτότητα ≠
ταξινόμηση ≠ τοποθεσία ≠ κατάσταση επαλήθευσης ≠ διοικητική υπαγωγή
[Δ-4/Δ-5/Β-4/Γ-C4]· (γ) ατομικότητα = δομική ιδιότητα ΕΝΟΣ framed append
σε ΕΝΑ δηλωμένο journal· ΚΑΘΕ ισχυρισμός γνώσης δένει ΟΛΕΣ τις αλυσίδες
από τις οποίες εξαρτάται — knowledge-cut/1 [Γ-C1]· (δ) ΜΙΑ οδός ταυτότητας
ανά κλάση [Κ-C1]· (ε) μορφή πράξης ≠ έννομο αποτέλεσμα — δύο ανεξάρτητοι
άξονες [Γ-C3]· (στ) τίμια άγνοια: typed uncertainty, κανένα LLM στο
trusted path.

---

## 0. Θεμέλια, μετάβαση, journal topology, συν-γεννήσεις, έδρα-κλεισίματα

### 0.1 Έδρες που καταναλώνονται ως έχουν

| Έννοια | Έδρα | Χρήση |
|---|---|---|
| Κανονική σειριοποίηση + hash | `canonical-representation` + `deployment/verify/canonical-serialization-spec.md` | ΚΑΘΕ id = canonical-hash επί κλειστού αντικειμένου· ΟΧΙ booleans (0/1 integers)· §2 text normalization για κάθε content hash· ταξινομήσεις leaves κατά canonical bytes |
| Ταυτότητα πράξης/provision | `orchestrator.identity` (make-body, make-provision-id, declared-body) | work ≡ body identity για Rule-A κλάσεις (§1.1) |
| Μητρώα ειδών | `body-kind-registry.sexp`, `instrument-kind-registry.sexp` | επέκταση με εγγραφές + αφαίρεση route-διπλών (§0.2β) |
| Διτεμπορικός γράφος | `orchestrator.version-graph` (per-body journal, admit-edge!, snapshot-at, version-at/TILING, regime/condition/instrument kinds, retract-*) | text-mutating γεγονότα· το version_cut του knowledge-cut δένει στα ΠΡΑΓΜΑΤΙΚΑ types της έδρας (legal-date/legal-instant) |
| Journal πειθαρχία | `journal.lisp` [0086] | ΜΕ τα υποχρεωτικά κλεισίματα §0.5 ΠΡΙΝ από κάθε Π7-U.2 κώδικα |
| Raw→text γέφυρα | `lawmax/extraction-receipt/1→/2`, `normalization-receipt/1` (#4B) | Η ΜΟΝΗ γέφυρα bytes→κείμενο· /2 προσθέτει manifestation_id (§5.3) |
| Merkle | orchestrator.merkle (RFC-6962: leaf 0x00, node 0x01) | provision_set_root, graph/corpus_uncertainty_set_roots (§1.2) |
| Απόδειξη εξουσίας | `authority-proof-bundle/1` (CLOSED & FROZEN) | κατανάλωση ΜΕΣΩ CENSUS — καμία μεταβολή στο frozen statement |

### 0.2 Μερικές έδρες που διαδέχεται — ταξινόμηση [0045]

| Υπάρχουσα | Επικαλύπτει | Ταξινόμηση + φάση θανάτου |
|---|---|---|
| `source-profile.lisp` (acquired-record, channels/ranks, ιδιωτικό %canonical) | acquisition receipt, τυπολογία, 2η κανονικοποίηση | **B → Π7-U.3**: μετανάστευση σε receipts· %canonical πεθαίνει· ranks → authority registry δεδομένα |
| `document-fetch.lisp` (fek-blob-url κ.λπ.) | acquisition/locations με ΦΕΚ σημασιολογία | **B → Π7-U.2**: ξαναγράφεται ως gr-gazette acquirer· patterns → δεδομένα |
| `government-source.lisp` | 2η τυπολογία πηγών | **B → Π7-U.3**: πηγές → registry εγγραφές |
| `corpus-provenance.lisp` (PROV-O) | 2ο provenance λεξιλόγιο | **A**: εξαγωγική προβολή — ποτέ πηγή αλήθειας· mapping Π7-U.3 |
| **β)** body-kind `:ya`/`:eu-reg`/`:eu-dir` | διπλή οδός [Κ-C1] | **B → Π7-U.2 registry φάση**: ΥΑ/ΚΥΑ ⇒ ΜΟΝΟ protocol-register οδός· EU ⇒ ΜΟΝΟ {celex} |

### 0.3 Journal topology — ΡΗΤΗ [Τ-C3]

ΔΥΟ chain-hashed journals, ίδια journal.lisp πειθαρχία (§0.5), δικά τους
chain domains:

| Journal | Πεδίο | Kinds |
|---|---|---|
| **version-graph journal** (per-body, υπάρχον) | νομική κατάσταση σώματος | text-mutating (amendment/repeal/correction/normative-consolidation), regime, conditions, instrument (:ratification/:acceptance), relations-με-regime*, `:batch` |
| **corpus journal** (ΕΝΑ, νέο) | κτήση & πραγματικότητα πηγών | acquisition-receipt, location-observation, media-verification, uncertainty + uncertainty-resolution, issuance-fact, work-record, legal-effect assertion (§3.2), proposal-rejected, relations-χωρίς-regime, mode-decision, `:batch` |

- `:batch` ΑΝΑ journal· cross-journal batch = schema reject (W-J-TOPOLOGY).
- *Relations με regime υπο-γεγονός: στο version-graph journal του
  σώματος-στόχου, σε batch με το regime τους.
- **Κάθε ισχυρισμός που εξαρτάται και από τα δύο journals (snapshots §1.2)
  δένει ΚΑΙ τα δύο μέσω knowledge-cut/1 [Γ-C1] — μονομερές cut δεν υπάρχει.**

### 0.4 Πίνακας συν-γεννήσεων — ΕΞΑΝΤΛΗΤΙΚΟΣ [Τ-C4]

| Συν-γέννηση | Μηχανισμός |
|---|---|
| relation + regime event | batch, version-graph journal |
| normative consolidation event + codifies relation | batch, version-graph journal |
| uncertainty + «καραντίνα» artifact | ΕΝΑ corpus record: καραντίνα ≡ ανοιχτή uncertainty — καμία δεύτερη σημαία |
| work-record + issuance facts (+ αρχική legal-effect assertion) | batch, corpus journal |
| expression + manifestation | παράγωγες content-addressed ταυτότητες — όχι γεγονότα· κανένα recovery |
| proposal-rejected + legal-effect-unresolved | batch, corpus journal |
| blob + acquisition receipt | recovery protocol §4.3 — η ΜΟΝΗ δι-store σχέση, ορατή μερικότητα |

### 0.5 ΥΠΟΧΡΕΩΤΙΚΑ κλεισίματα έδρας journal.lisp — BLOCKING πριν από κάθε Π7-U.2 κώδικα

1. **`lawmax/journal-frame/1` — ΥΠΟΧΡΕΩΤΙΚΟ record framing [Τ-C1, Β-7]:**

   ```
   frame := "#F1 " <byte_length: decimal> " " <sha256(payload): hex> "\n"
            <payload: ακριβώς byte_length bytes>
            "\n#C1\n"
   ```

   Πλήρες ⟺ μήκος ✓ ∧ sha256 ✓ ∧ commit marker ✓. Newline-only truncation =
   ΑΠΑΓΟΡΕΥΜΕΝΗ διαδρομή (multiline strings στα forms). Torn ⇒ typed
   ετυμηγορία προς τον καλούντα + journaled heal (truncate στο τελευταίο
   πλήρες frame). Αλλαγή μορφής = frame/2. Migration υπαρχόντων journals με
   byte-parity proof (W-JOURNAL-FRAME, W-JB-TORN).
2. **Compare-and-append [Τ-C2]:** precondition ελέγχεται ΣΤΟ append ΥΠΟ το
   lock: mismatch ⇒ typed `stale-precondition`, ΤΙΠΟΤΑ δεν γράφεται.
   Κλείνει και το προϋπάρχον `%journal!` race (W-JB-RACE).
3. **Fsync honesty [Τ-S5]:** αποτυχία fsync ⇒ ΟΧΙ :durable ⇒ κανένα id
   (W-FSYNC-LIE).
4. **Single-writer [Τ-S8]:** ΕΝΑΣ συγγραφέας ανά journal (cross-process
   lease)· proposal-rejected δεσμεύει digest, ποτέ σώμα (W-FLOOD).

---

## 1. Καθολική ταυτότητα — τέσσερα επίπεδα (FRBR-ισομορφικά)

```
WORK → EXPRESSION (sum type §1.2) → MANIFESTATION (§1.3) → ITEM (bytes §4)
```

Καμία ταυτότητα δεν αποδίδεται — όλες υπολογίζονται από κλειστά θεσμικά
γεγονότα. URL, observed μορφότυπος, χρόνος λήψης, connector, κατάσταση
επαλήθευσης, διοικητική υπαγωγή: ΠΟΤΕ σε identity hash.

### 1.1 Work identity — ΜΙΑ οδός ανά κλάση [Δ-3, Κ-C1, Κ-S7]

**Κανόνας Α (κλάσεις με body-kind):** `work identity ≡ body identity`
αυτούσιο (π.χ. `gr/nomos/2019/4619`).

**Κανόνας Β (λοιπές):**

```
work_id = "lsw1:" + canonical-hash({
  "schema": "lawmax/work/1",
  "register": <register-id εγγραφής source-class registry — ΤΑΥΤΟΤΙΚΟ:
               το ΜΗΤΡΩΟ ΑΡΙΘΜΗΣΗΣ, όχι ταξινόμηση [Κ-S7]>,
  ...identity-projector fields της εγγραφής})
```

**Invariant ΜΙΑΣ οδού [Κ-C1]:** registry gated load — κάθε κλάση ΑΚΡΙΒΩΣ
μία identity-route (body-kind XOR projector)· body-id string ως Rule-B
input ⇒ reject.

**Issuance facts [Δ-3, Β-2] — `lawmax/issuance/1`, corpus journal, batch με
το work-record:**

```
{"schema": "lawmax/issuance/1",
 "work": {"id_type": "body" | "lsw1", "id": ...},
 "role": <registry: issuer | co-signer | countersigner | promulgator>,
 "authority_ids": <ΚΑΝΟΝΙΚΑ ΤΑΞΙΝΟΜΗΜΕΝΟ σύνολο ανά role>,
 "evidence": <provision-pin ή gazette span>, "recorded_at": <legal-instant>}
```

Διόρθωση απόδοσης/υπογραφόντων = νέο fact — ταυτότητα ΑΜΕΤΑΒΛΗΤΗ
(W-Δ3, W-KYA-COISSUERS).

### 1.2 `lawmax/expression/1` — sum type [Δ-1] με knowledge-cut [Γ-C1/C2]

```
expression_id = "lse1:" + canonical-hash({"schema":"lawmax/expression/1",
                                          "kind": ..., ...kind-specific})
kind ∈ ΚΛΕΙΣΤΟ ΣΤΟ SCHEMA (γνήσιο οντολογικό sum):
```

**provision-expression:**
```
{"provision_id", "tv_version_hash", "language": <language registry §1.5>}
```

**work-snapshot-expression** — ενοποιημένο work σε ΠΛΗΡΩΣ καρφωμένη τομή
ΓΝΩΣΗΣ (όχι μόνο γράφου) [Γ-C1]:
```
{"work": {"id_type": "body"|"lsw1", "id": ...},
 "language": <registry>,
 "valid_at": <ΠΛΗΡΕΣ legal-date "YYYY-MM-DD" — typed-partial ΑΠΑΓΟΡΕΥΕΤΑΙ>,
 "knowledge_cut": <lawmax/knowledge-cut/1 — κατωτέρω>,
 "provision_set_root": <RFC-6962 root>,
 "graph_uncertainty_set_root": <RFC-6962 root | "sha256:EMPTY-SET">,
 "corpus_uncertainty_set_root": <RFC-6962 root | "sha256:EMPTY-SET">}
```

**`lawmax/knowledge-cut/1` [Γ-C1]** — δένει ΚΑΙ τις δύο αλυσίδες:
```
{"schema": "lawmax/knowledge-cut/1",
 "version_cut": {"body_id": ...,
                 "seq": N, "chain_root": <chain head hash ΣΤΟ seq>,
                 "last_record_id": <id του record ΣΤΟ seq>,
                 "last_recorded_at": <legal-instant ΤΟΥ record ΣΤΟ seq>},
 "corpus_cut":  {"seq": N, "chain_root": ...,
                 "last_record_id": ..., "last_recorded_at": ...}}
```

**Transaction-time σημασιολογία [Γ-C2]:** η συντεταγμένη κάθε cut είναι η
τριάδα `(last_recorded_at, seq, chain_root)` — το seq επιλύει την ισοχρονία
(δύο records ίδιου δευτερολέπτου), το chain_root αποκλείει fork, το
timestamp κρατά τη χρονική σημασία. **ΔΕΝ υπάρχει ελεύθερο πεδίο
`recorded_through`:** το transaction όριο ΕΙΝΑΙ το `last_recorded_at` του
record στο seq — παράγωγο, όχι δηλωτέο· τιμή ≠ της πραγματικής ⇒ verifier
FAIL· «διογκωμένο» όριο ανύπαρκτο δομικά (W-CUT-TIME-INFLATION,
W-CUT-SAME-SECOND).

**Κανονικός ορισμός συνόλων + υποχρεώσεις verifier:**
```
vgraph  := load-graph(body_id, :up-to-seq version_cut.seq)
ΕΛΕΓΧΟΙ := chain-head(vgraph) == version_cut.chain_root          # W-SNAPSHOT-FORK
           ∧ record-id@seq == last_record_id
           ∧ recorded-at@seq == last_recorded_at
           (ομοίως για corpus journal prefix @ corpus_cut)
snapshot := snapshot-at(vgraph, :valid-at valid_at,
                        :known-at version_cut.last_recorded_at)
provision_set_root := RFC-6962 root, leaves ΤΑΞΙΝΟΜΗΜΕΝΑ κατά canonical bytes
  leaf := canonical-JSON {"leaf_type": "provision",
                          "provision_id": ..., "tv_version_hash": ...}
graph_uncertainty_set_root := RFC-6962 root — ΟΙ graph-native αβεβαιότητες
  (uncertain provisions του snapshot κατά την έδρα temporal semantics)
  leaf := canonical-JSON {"leaf_type": "graph-uncertainty",
                          "provision_id": ..., "reason": <typed>}
corpus_uncertainty_set_root := RFC-6962 root — ΟΙ ΑΝΟΙΧΤΕΣ uncertainties
  του corpus journal ΣΤΟ corpus_cut με subject επί του work ή provisions του
  leaf := canonical-JSON {"leaf_type": "corpus-uncertainty",
                          "uncertainty_id": ..., "kind": ..., "subject": ...}
```
Ο verifier ΑΝΑΫΠΟΛΟΓΙΖΕΙ και τα τρία roots από τα δύο prefix replays —
δηλωμένα roots δεν γίνονται πιστευτά. Επίλυση/προσθήκη uncertainty στο
corpus journal ΧΩΡΙΣ αλλαγή γράφου ⇒ νέο corpus_cut ⇒ διακριτή expression
— η «ίδια τομή γράφου, άλλη γνώση» σύγχυση αδύνατη
(W-CROSS-JOURNAL-UNCERTAINTY).

**single-document-expression:**
```
{"work": tagged, "language": <registry>,
 "content_sha256": <sha256(UTF-8(κείμενο κανονικοποιημένο κατά §2 της
   canonical-serialization-spec — Η ΙΔΙΑ normalization των text-versions))>}
```

- Rule-B works χωρίς body-kind: provision-ids αδύνατα (απαιτούν
  legal-body-id) ⇒ ΜΟΝΟ single-document [Κ-S8]· provision-δόμησή τους =
  δηλωμένο όριο v1 (§11).
- Μονο-διατακτικά works: provision-expression (μέρος) ≠ work-snapshot
  (όλον)· ισοδυναμία παραγώγιμη από το μονοσύνολο root — ο verifier την
  ελέγχει (W-K5).

### 1.3 `manifestation_id` — ΜΟΝΟ κανονικά ταυτοτικά πεδία [Δ-2, Β-4]

```
manifestation_id = "lsm1:" + canonical-hash({
  "schema": "lawmax/manifestation/1",
  "expression_id": <ΥΠΟΧΡΕΩΤΙΚΟ — reject αν λείπει (W-Δ2)>,
  "media_type": <ΤΙΜΗ από media-type registry §1.5>,
  "official_variant": <official-variant registry: as-published |
                       corrigendum-applied | consolidated-official>,
  "publisher": {"kind": "authority" | "work-self",
                "authority_id": <όταν kind=authority>},
  "edition_key": <ΤΙΜΗ από edition-key registry §1.5>})
```

ΕΚΤΟΣ ταυτότητας — journaled evidence (corpus journal): URLs →
location-observations· observed content-types → receipts· detection/
asserted→verified → `lawmax/media-verification/1` {manifestation_id,
method: media-detection registry(magic-bytes|declared-only|validated-parse),
detector_manifest_sha256, verdict, artifact_digest, recorded_at}
(W-MANIFEST-URL, W-MEDIA-STATUS).

### 1.4 Identity projectors — δεσμευτικά v1 (πλήρης μορφή ΣΤΟ registry)

- `judgment`: `{court: authority_id, registry_number: int, year: int}` +
  formation ΜΟΝΟ όταν η εγγραφή δικαστηρίου δηλώνει numbering:
  per-formation (keyword από το κλειστό σύνολο formations της) [Ν-CRIT5]·
  judgment/court-order/court-minutes = ταυτοτικό series-field.
- `emergency-legislative-act` (ΠΝΠ) [Β-5]: `{"gazette_ref": {"id_type":
  "lsw1", "id": <gazette-issue work_id>}, "act_ordinal": <int — θέση στην
  επίσημη διάταξη ύλης του τεύχους>}` (W-PNP-SAME-ISSUE)· promulgation_date
  = classification field· spans = manifestation evidence· κύρωση:
  :ratification· μη κύρωση: :expire με evidence.
- `ministerial-decision`/`joint-ministerial-decision`/`administrative-act`/
  `interpretive-circular` [Β-2, Γ-C4]: **protocol-register οδός** —
  `{"register_id": <§2.1β — παράγωγο, ΟΧΙ αποδιδόμενο>, "protocol_number":
  string, "protocol_date": date}` — ΚΑΝΕΝΑΣ authority στο hash· ο connector
  δεν διαλέγει «εκδότη» (W-KYA-COISSUERS)· υπογράφοντες = issuance facts.
- `eu-*`: `{celex}` για ΟΛΕΣ τις eu κλάσεις — κλάση = classification field
  (W-Δ4).
- `international-treaty`: `{parties: sorted-set, conclusion_date,
  authentic_title_sha256}` — depositary = evidence [Ν-S9].
- `gazette-issue`: `{gazette_authority_id, series: string, issue: int,
  year: int}`.
- `code`: Κανόνας Α μέσω `:kodikas`· number ΥΠΟΧΡΕΩΤΙΚΟ ΣΤΗΝ έδρα make-body
  (Π7-U.2 προ-παραδοτέο) [Κ-M11]· number = της κυρωτικής πράξης, στην
  εγγραφή.

### 1.5 Επεκτάσιμες τιμές = versioned registries — ΟΧΙ schema enums [Γ-S3]

`deployment/data/`: **language-registry** (ISO 639-1 εγγραφές — v1: el, en,
fr, de· νέα γλώσσα ΕΕ = νέα εγγραφή, ΚΑΜΙΑ schema revision),
**media-type-registry** (v1: application/pdf, text/html, application/xml,
text/plain), **edition-key-registry** (v1: official-portal, print,
consolidated-database), **official-variant-registry**,
**media-detection-registry**. Όλα: sexp, *read-eval* nil, census. Τιμή
εκτός τρέχοντος registry ⇒ reject/uncertainty· προσθήκη εγγραφής ΔΕΝ
αλλάζει υπάρχοντα ids (η ΤΙΜΗ μπαίνει στο hash, όχι το registry)
(W-REGISTRY-EXTENSION). ΚΛΕΙΣΤΑ στο schema μένουν ΜΟΝΟ τα οντολογικά sums:
expression kinds, work_form (§3.1), origin kinds (§5.1), locator types
(§2.2), publisher kinds, id_type tags.

---

## 2. Τυπολογίες ως versioned data registries

### 2.1 Source-class registry — `deployment/data/source-class-registry.sexp`

Ανά εγγραφή ΥΠΟΧΡΕΩΤΙΚΑ (gated load):

```
class | register-id | work_form (§3.1 — ΕΝΑ) | default_legal_effect (§3.2)
identity-route (body-kind XOR projector) [Κ-C1]
identity-projector + key-shape (string | integer | date |
  sorted-set-of-string | tagged-ref) [Ν-CRIT1]
classification-fields (ΠΟΤΕ στο hash) | required-evidence | mutating-capable
```

v1 περιεχόμενο: όλα τα body-kinds + emergency-legislative-act,
ministerial-decision, joint-ministerial-decision, administrative-act,
gazette-issue, judgment, court-order, court-minutes, eu-treaty,
eu-regulation, eu-directive, eu-decision, eu-judgment,
international-treaty, interpretive-circular, opinion-nsk,
parliament-standing-orders, independent-authority-decision. Άγνωστη κλάση
⇒ unclassified-source + καραντίνα. Συντακτικές Πράξεις: εκτός v1, τίμια
unclassified [Κ-NIT12].

### 2.1β Protocol-register registry — ΠΑΡΑΓΩΓΗ ταυτότητα [Γ-C4]

`lawmax/protocol-register/1` — το register_id ΥΠΟΛΟΓΙΖΕΤΑΙ, δεν αποδίδεται:

```
register_id = "preg1:" + canonical-hash({
  "schema": "lawmax/protocol-register/1",
  "jurisdiction": <registry §2.3>,
  "founding_locator": <tagged union ΜΕ version pin — ΙΔΙΕΣ μορφές με §2.2:
      {"locator_type": "provision-id",
       "value": {"provision_id", "tv_version_hash"}}
    | {"locator_type": "span", "value": {"artifact_digest","start","end"}}
    | {"locator_type": "pre-corpus",
       "value": {"instrument","date","gazette_ref"}}>,
  "canonical_register_key": <ο θεσμικός κωδικός/κανονική ονομασία του
      μητρώου ΚΑΤΑ ΤΗΝ ΙΔΡΥΣΗ — κανόνας όπως entity_key §2.2: κωδικός ΠΑΝΤΑ
      όταν η ιδρυτική πράξη ορίζει, ονομασία ΜΟΝΟ αλλιώς>})
```

**ΕΚΤΟΣ identity — versioned διτεμπορικά assertions με evidence:**
owning_authority (η υπαγωγή!), names, series labels, competence transfers,
existence interval, lineage. Μεταφορά μητρώου σε άλλο υπουργείο ⇒
register_id ΑΜΕΤΑΒΛΗΤΟ ⇒ ταυτότητες πράξεων ΑΜΕΤΑΒΛΗΤΕΣ· δύο connectors ⇒
ΙΔΙΟ id (παράγωγο) (W-REGISTER-REASSIGNMENT).

### 2.2 Authority registry

```
"authority_id": "auth1:" + canonical-hash({
   "jurisdiction": ...,
   "founding_locator": <tagged union — ΜΙΑ μορφή pin ανά τύπο [Β-3]:
       {"locator_type": "provision-id",
        "value": {"provision_id", "tv_version_hash"}}   # W-AUTH-PIN-DUAL:
                                                        # cut pin = provenance,
                                                        # ΔΕΝ υπάρχει εδώ
     | {"locator_type": "span", "value": {...}}
     | {"locator_type": "pre-corpus", "value": {...}}>,  # ΑΠ 1834 [Ν-S10]
   "entity_key": <ordinal ΠΑΝΤΑ όταν η διάταξη αριθμεί· κανονική θεσμική
                  ονομασία ΜΟΝΟ αλλιώς — μη-κανονική επιλογή ⇒ reject [Κ-S4]>})
"kind": VERSIONED ASSERTION ΕΚΤΟΣ hash [Δ-5]: parliament | president |
        minister-council | ministry | minister | court | prosecutor |
        independent-authority | central-bank | municipality | region |
        eu-institution | international-org
"names"/"lineage" (renamed-from | merged-from | split-from | abolished |
  re-established-as | competence-transferred-to)/"numbering" (unified |
  per-formation + formations closed set)/"existence" — evidence-backed.
```

Επανίδρυση από νέα ΕΚΔΟΣΗ της ίδιας διάταξης ⇒ διακριτό id (το
tv_version_hash στο pin) [Κ-C3] (W-K3). Genesis ακολουθία journaled:
Σύνταγμα ⇒ constitutional-basis αρχές ⇒ αναδρομικά [Α-S7]. Δέσμευση ΜΕΣΩ
CENSUS [Α-S10].

### 2.3 Jurisdiction registry [Ν-M12]: εγγραφές gr, eu, int + ρητές ανά
περιφέρεια/δήμο με evidence.

---

## 3. Οντολογία — ΔΥΟ ΑΝΕΞΑΡΤΗΤΟΙ ΑΞΟΝΕΣ [Γ-C3]

### 3.1 `work_form` — ΚΛΕΙΣΤΟ οντολογικό sum (ΤΙ ΕΙΝΑΙ η πράξη — ποιο όργανο/διαδικασία τη γέννησε)

```
work_form
├─ publication                        (gazette-issue — εκδοτικό τεκμήριο)
├─ legislative-instrument             (νόμοι, ΠΝΠ, κώδικες, κανονισμοί Βουλής)
├─ executive-administrative-instrument (ΠΔ, ΥΑ/ΚΥΑ, διοικητικές πράξεις,
│                                       αποφάσεις ανεξάρτητων αρχών)
├─ adjudicative-instrument            (αποφάσεις, βουλεύματα, πρακτικά)
├─ treaty                             (διεθνείς/ενωσιακές συνθήκες)
└─ interpretive-instrument            (εγκύκλιοι, γνωμοδοτήσεις ΝΣΚ)
```

### 3.2 `legal_effect` — ΤΙ ΠΑΡΑΓΕΙ η πράξη (ανεξάρτητος άξονας, evidence-backed)

```
legal_effect: normative | individual | adjudicative | interpretive |
              evidentiary | none | unresolved
```

- Κάθε source-class εγγραφή δηλώνει `work_form` (ΕΝΑ, αμετάβλητο — δομή)
  και `default_legal_effect`. Το ΑΝΑ WORK effect = **versioned journaled
  assertion** (corpus journal, evidence-backed, στο batch της γέννησης ή
  μεταγενέστερο) — μπορεί να διαφέρει από το default: κανονιστική ΚΥΑ =
  {form: executive-administrative-instrument, effect: normative}· ατομική
  ΥΑ = {form: executive-administrative-instrument, effect: individual}
  [Γ-C3]. Χωρίς evidence ⇒ effect: unresolved + legal-effect-unresolved
  uncertainty — ποτέ μαντεψιά.
- **Το όργανο ΔΕΝ συγχέεται με το αποτέλεσμα** — δομικά: το form είναι
  schema sum, το effect είναι assertion. provision/expression/manifestation/
  artifact = ΕΠΙΠΕΔΑ (§1), εκτός και των δύο αξόνων.
- ΦΕΚ (publication) ΠΕΡΙΕΧΕΙ works: σχέση `published-in` (§6.3).
- opinion-nsk: δεσμευτικότητα = :acceptance instrument event [Ν-S8].
- Type guards σχέσεων (§6.3): δηλώνουν όρια σε form ΚΑΙ/Η effect — η
  κανονιστική ΚΥΑ ακυρώνεται δικαστικά χωρίς να σπάσει guard
  (W-KYA-ANNULMENT).

---

## 4. Raw artifact — ΜΟΝΟ εγγενή [Δ-9, Α-S5]

### 4.1 `lawmax/raw-artifact/1`

```
{"schema": "lawmax/raw-artifact/1",
 "digest_algorithm": "sha256", "digest": <hex>, "byte_length": N}
```

ΚΑΝΕΝΑ media_type (W-Δ9α)· ΚΑΝΕΝΑΣ δείκτης receipts (φορά receipt→artifact,
many-to-one — W-Δ9β). Append-only content-addressed store, read-back πριν
από κάθε δείκτη [0086]. Μετασχηματισμός ⇒ ΝΕΟ artifact μέσω extraction/
normalization receipts. Το raw επιζεί ΓΙΑ ΠΑΝΤΑ — και επί αποτυχίας parsing.

### 4.2 Media evidence — ΕΚΤΟΣ ταυτότητας [Β-4]

`lawmax/media-verification/1` records (§1.3) — αναβαθμίσεις = γεγονότα.
Απόκλιση observed↔verified = τυπωμένο γεγονός + πιθανή uncertainty.

### 4.3 Blob↔receipt recovery [Δ-9]

Σειρά: (1) blob + fsync + read-back· (2) receipt ως framed journaled record.
Recovery: blob χωρίς receipt = ΚΑΡΑΝΤΙΝΑ, επανυιοθέτηση ΜΟΝΟ με νέο receipt
(W-Δ9γ)· receipt χωρίς blob = ΣΚΛΗΡΟ ΣΦΑΛΜΑ κλάσης journal-corruption
(W-Δ9δ)· artifact «υπάρχει» ΜΟΝΟ ως ζεύγος (blob, ≥1 receipt).

---

## 5. Acquisition, locations, γέφυρες

### 5.1 `lawmax/acquisition-receipt/1` — origin ως ΚΛΕΙΣΤΟ sum [Α-CRIT2, Γ-S2]

```
{"schema": "lawmax/acquisition-receipt/1",
 "receipt_id": "acq1:" + canonical-hash(πλην receipt_id),
 "artifact_digest": <hex>, "digest_algorithm": "sha256",
 "origin":                                      # ΚΛΕΙΣΤΟ οντολογικό sum [Γ-S2]
     {"kind": "network-fetch", "url": ..., "protocol": "https",
      "status": 200, "observed_content_type": ...,
      "response_headers_subset": {"content-type","last-modified","etag"}}
   | {"kind": "manual-deposit", "depositor": <authority_id | typed person-ref>,
      "custody_receipt": <string — αρ. πρωτ./απόδειξη παραλαβής>,
      "medium": <registry: paper-scan | optical-media | usb | court-registry>,
      "deposited_at": <legal-instant>, "observed_content_type": ...}
   | {"kind": "archive-import", "archive_id": <registry εγγραφή>,
      "item_locator": <string>, "import_manifest_sha256": <hex>,
      "observed_content_type": ...},
 "fetched_at": <legal-instant — δηλωμένα αναξιόπιστο μόνο του>,
 "anchoring": {"tlog_leaf_index": N, "tsr_sha256": <digest>} | null,
 "acquirer": {"acquirer_id", "manifest_sha256"},
 "verification": {"read_back": 1, "digest_recomputed": 1}}
```

Manual-deposit/archive-import receipts επικυρώνονται ΧΩΡΙΣ url/status —
network πεδία σε μη-network origin ⇒ reject (W-MANUAL-DEPOSIT).

### 5.2 Location observations — journaled, ΕΚΤΟΣ ταυτότητας [Α-M13, Β-4]

`lawmax/location-observation/1` (corpus journal): {work-ref,
manifestation_id, url, observed_at, acquisition_receipt_id, status:
served-bytes | redirect | gone | changed-digest}. `changed-digest` ⇒ νέο
manifestation Ή official-sources-conflict/source-integrity uncertainty —
ποτέ σιωπηλά. URLs σε ΚΑΝΕΝΑ id (W-MANIFEST-URL).

### 5.3 `lawmax/extraction-receipt/2` = /1 + manifestation_id [Α-S8]
(versioned· τα /1 των CLOSED #4B bundles έγκυρα — ο verifier δέχεται και
τα δύο δηλωμένα).

### 5.4 typed-partial dates [Α-S9]: ΜΟΝΟ "YYYY" | "YYYY-MM" | "YYYY-MM-DD"·
canonical spec vectors (Π7-U.2, πριν από κάθε χρήση σε hash). Επιτρεπτά:
official keys (όπου δηλωμένα), pre-corpus citations, uncertainty, existence.
**ΑΠΑΓΟΡΕΥΜΕΝΑ σε valid_at και σε ΚΑΘΕ πεδίο knowledge-cut** — εκεί ΜΟΝΟ
legal-date/legal-instant της έδρας (W-SNAPSHOT-TYPES).

---

## 6. Journal semantics — batch, consolidation, relations

### 6.1 `lawmax/journal-batch/1` [Δ-6]

```
journal kind :batch — ΑΝΑ journal· cross-journal ⇒ reject
{"schema": "lawmax/journal-batch/1", "batch_id": "jb1:...",
 "precondition_root": <compare-and-append ΥΠΟ το lock (§0.5.2)>,
 "ordered_subevents": [<πλήρη semantic records>]}
```

ΕΝΑ seq, ΕΝΑ framed record, ΜΙΑ chain transition (W-Δ6)· κανένα cut ΜΕΣΑ
σε batch· subevents με δικά τους record-ids + per-subevent semantic replay
checks (W-JB-SUB-ID)· κατανάλωση = ως διαδοχικές γραμμές· ενδο-batch
αναφορές μόνο προς προηγούμενο· ≥1 subevents, kind ≠ :batch (W-JB-NEST)·
all-or-nothing replay.

### 6.2 Text-mutating + consolidation split [Δ-8, Τ-S6]

- amendment, repeal, correction: γεγονότα version-graph μέσω proposal +
  admit-edge!.
- consolidation — evidence-backed legal-effect mode: **normative** ⇒
  γεγονός γράφου ΣΕ BATCH με codifies· **derived** ⇒ work-snapshot-
  expression + manifestation (variant consolidated-official), ΜΗΔΕΝ graph
  mutation (W-Δ8)· χωρίς evidence ⇒ legal-effect-unresolved.
- Mode-decision = journaled record (corpus journal): {evidence-pin,
  decider: creator, mode} [Τ-S6].
- Αντίστροφος φρουρός: derived submission ενώ υπάρχει κυρωτική/
  εξουσιοδοτική citation στο corpus ⇒ ΥΠΟΧΡΕΩΤΙΚΟ legal-effect-unresolved
  (W-Δ8β).
- Instrument/regime: :ratification, :acceptance, :suspend/:revive/:extend/
  :expire/:retroact — υπάρχουσες έδρες.

### 6.3 Non-mutating relations — `lawmax/legal-relation/1` journal kind [Α-CRIT3, Γ-C3/S1]

Record: {relation_id: "rel1:"+hash, relation, from/to: {form, effect?, id},
evidence: {work-ref, provision-pin ή dispositif-pin}, bitemporal:
{valid_from: date|typed-partial, known_at: legal-instant}, verdict_basis:
explicit-citation | operative-part, relation_registry_digest: <pinned>}.

Kinds — registry, guards σε form/effect άξονες [Γ-C3]:

| kind | άκρα (form guard· effect όπου δηλώνεται) | βάση |
|---|---|---|
| `judicially-interprets` [Γ-S1] | adjudicative-instrument → provision \| work | explicit-citation (η απόφαση μνημονεύει ρητά τη διάταξη) — η νομολογιακή ερμηνεία πρώτης τάξης (W-JUDICIAL-INTERPRETATION) |
| `administratively-interprets` [Γ-S1] | interpretive-instrument → provision \| work | explicit-citation — διακριτή authority σημασιολογία (μη δεσμευτική/δεσμευτική μέσω :acceptance) |
| `annuls`* | adjudicative-instrument → executive-administrative-instrument (ΚΑΘΕ effect — και normative ΚΥΑ [Γ-C3]) | operative-part (W-KYA-ANNULMENT) |
| `declares-unconstitutional{erga-omnes\|incidenter}`* | adjudicative-instrument → provision | operative-part· regime υπο-γεγονός ΜΟΝΟ erga-omnes (ΑΕΔ, άρθ. 100 Σ) |
| `suspends-effect`* | adjudicative-instrument → work \| provision | operative-part |
| `authorizes-delegation` | legislative-instrument provision → executive-administrative-instrument | explicit-citation (το προοίμιο την τυπώνει) |
| `resolves-pilot-question` | adjudicative-instrument (ΟλΣτΕ, ν. 3900/2010) → provision | operative-part |
| `precedent-follows` / `precedent-distinguishes` | adjudicative → adjudicative | explicit-citation ΜΟΝΟ |
| `codifies{legislative\|administrative}` | legislative-instrument (code) → statutes | explicit-citation |
| `published-in` | κάθε work → publication | explicit position |

\* = ΥΠΟΧΡΕΩΤΙΚΑ σε batch με το regime υπο-γεγονός τους (version-graph
journal του στόχου). ΠΟΤΕ inferred — κανένα LLM/similarity.
**Relation-retract:** συμμετρικό — batch-σχέση αναιρείται ΜΟΝΟ ως batch
(W-REL-RETRACT). **Registry pinning:** η υποχρέωση batch κρίνεται κατά το
pinned `relation_registry_digest` του record (W-REG-PIN).

---

## 7. Connectors — acquirer (impure) / parser (pure) [Α-CRIT1]

- `lawmax/acquirer/1`: emits ΜΟΝΟ raw-artifact + acquisition-receipt +
  location-observation· origins κατά §5.1 (network/manual/archive).
- `lawmax/parser/1`: καθαρή συνάρτηση → {work-record, issuance-fact,
  legal-effect assertion proposal, expression, manifestation,
  legal-relation-proposal, graph-event-proposal, journal-batch-proposal,
  authority-proposal, uncertainty}. Determinism gate (SOURCE_DATE_EPOCH,
  byte-ίδια έξοδος)· κανένα δίκτυο/ρολόι/ιδιωτικό πεδίο.
- Προτάσεις-όχι-εγγραφές: graph-event-proposal ≡ espec του admit-edge!·
  απόρριψη journaled (digest + αιτία)· authority + protocol-register gates
  = ΔΗΛΩΜΕΝΑ παραδοτέα Π7-U.2· write authority: ΕΝΑΣ συγγραφέας ανά journal
  (W-FLOOD).
- Κοινή σουίτα συμμόρφωσης: golden + αντιπαλικά vectors ⊇ ΟΛΟΙ οι
  witnesses §12 — gated· χωρίς πράσινο, ο connector δεν εγγράφεται.

---

## 8. Typed uncertainty — `lawmax/uncertainty/1`

```
{"schema": "lawmax/uncertainty/1",
 "uncertainty_id": "unc1:" + canonical-hash(...),
 "kind": <registry — v1: source-unverified | identity-ambiguous
   (candidate_ids ΤΥΠΩΜΕΝΑ) | official-key-incomplete | authority-unresolved
   | relation-unproven | date-partial | source-integrity |
   unclassified-source | official-sources-conflict | pending-ratification |
   commencement-unresolved | authenticity-pending | legal-effect-unresolved>,
 "subject": {"artifact_digest" | "work-ref" | "candidate_ids": [...]},
 "evidence": <ποτέ κενό>, "blocking": <τι μπλοκάρεται>}
```

Corpus journal, ορατό στο /as-known. Θάνατος ΜΟΝΟ με evidence ή ρητή
απόφαση δημιουργού — journaled `uncertainty-resolution`. Καραντίνα ≡
ανοιχτή uncertainty (§0.4). Οι ανοιχτές uncertainties συμμετέχουν στο
corpus_uncertainty_set_root κάθε snapshot που τις αφορά (§1.2).

---

## 9. Καμία ΦΕΚ-ειδική δομή [Ν-NIT15, Α-M11]

ΦΕΚ = ΔΕΔΟΜΕΝΑ (gazette-issue projector + σειρές σε registry εγγραφές).
Gate με ρητή λίστα αρχείων (όλα τα Π7-U registries + acquirer/parser
contract αρχεία)· tokens fek/φεκ ΜΟΝΟ σε registry ΔΕΔΟΜΕΝΑ. Δηλωμένα
προϋπάρχοντα υπόλοιπα: `:fek-date`, `:fek-ref` — μετονομασία = μελλοντική
versioned φάση. Τα 9 ΦΕΚ = ΠΕΛΑΤΗΣ του καθολικού μέσω gr-gazette
acquirer+parser.

---

## 10. Κριτήρια αποδοχής Π7-U.1

1. Ρητή τελική έγκριση δημιουργού. Ιστορικό: 7 γύροι επιθεώρησης ([Ν]+[Α],
   [Δ], [Κ]+[Τ], [Β], [Γ]) — ΟΛΑ τα ευρήματα κλειστά ονομαστικά· ακριβής
   καταμέτρηση στο CLOSURE-MATRIX (συνοδευτικό).
2. Registries: identity-route XOR + projector/classification/evidence/
   key-shape — gated load· επεκτάσιμες τιμές ΜΟΝΟ σε registries [Γ-S3].
3. Journal topology ρητή (§0.3)· knowledge-cut/1 για κάθε δι-journal
   ισχυρισμό [Γ-C1]· συν-γεννήσεις εξαντλητικές (§0.4)· §0.5 = BLOCKING
   προ-παραδοτέα Π7-U.2.
4. Αυτοτέλεια: μηχανικός όρος W-SPEC-SELF-CONTAINED.
5. Ο όρος §9 μηχανικά επαληθεύσιμος.
6. **Π7-U.2 ΠΑΓΩΜΕΝΟ** — παραδοτέα (σειρά): §0.5 journal fixes + frame
   migration, typed-partial canonical vectors, extraction-receipt/2,
   corpus journal + knowledge-cut replay, registry route-φάση (§0.2β),
   make-body number guard, authority + protocol-register gates, proposal
   schemas, conformance vectors (⊇ §12), gr-gazette acquirer+parser.

## 11. Δηλωμένα όρια v1 (τίμια)

- Πολυγλωσσία: ισοδυναμία expressions μεταξύ γλωσσών = μελλοντική φάση.
- Provision-δόμηση Rule-B works = μελλοντική φάση — μέχρι τότε
  single-document ΜΟΝΟ.
- Συντακτικές Πράξεις: εκτός v1, τίμια unclassified.
- Authority/protocol-register registries: genesis + μετρήσιμη πληρότητα.
- Blob↔receipt: η ΜΟΝΗ δι-store σχέση — ορατή μερικότητα (§4.3).
- Redaction: typed `parties_redacted`· πολιτική = απόφαση δημιουργού.
- Καμία ανύπαρκτη υποδομή δεν επικαλείται ως υπάρχουσα (§10.6).

---

## 12. ΟΝΟΜΑΣΤΙΚΟΙ NEGATIVE WITNESSES — υποχρεωτικά αντιπαλικά vectors Π7-U.2

### [Δ-1..9] (δημιουργός v2)
| | Στήνει → Αναμενόμενο |
|---|---|
| W-Δ1 | ίδιο work, δύο cuts, ίδια γλώσσα/μορφότυπος/variant → διαφορετικά manifestation_ids |
| W-Δ2 | manifestation χωρίς expression_id → schema reject |
| W-Δ3 | διόρθωση συνυπογραφόντων make-body νόμου → ταυτότητα ΑΜΕΤΑΒΛΗΤΗ, νέο issuance fact |
| W-Δ4 | CELEX αναταξινόμηση → work_id ΑΜΕΤΑΒΛΗΤΟ |
| W-Δ5/β | μία πράξη ιδρύει 2 αρχές → 2 ids· διόρθωση kind → id ΑΜΕΤΑΒΛΗΤΟ |
| W-Δ6 | ορφανό μισό όπου απαιτείται batch → replay FAIL· άκυρο subevent → ΟΛΟ το batch απορρίπτεται |
| W-Δ7 | λάθος form/επίπεδο άκρου → σφάλμα γέννησης record |
| W-Δ8/β | editorial-ως-normative → reject· normative-ως-derived → ΟΧΙ σιωπηλή αποδοχή |
| W-Δ9α-δ | media_type στο artifact → reject· ίδια bytes 2 content-types → ΕΝΑ artifact/2 receipts· blob χωρίς receipt → καραντίνα· receipt χωρίς blob → σκληρό σφάλμα |

### [Κ-x] (κριτής identity/FRBR v3)
| | |
|---|---|
| W-K1 | ίδια ΚΥΑ από 2 connectors → duplicate-route reject· ΥΑ ως make-body → αδύνατο |
| W-K2 | ίδιο version cut, 2 valid_at με διαφορετικό ενεργό σύνολο → 2 ΔΙΑΚΡΙΤΕΣ expressions |
| W-K3 | ίδρυση από v1/v2 της ίδιας διάταξης → 2 authority_ids |
| W-K4 | μη-κανονικό entity_key → reject· locator tags → τύποι δεν συγχέονται |
| W-K5 | μονο-διατακτικό work → ισοδυναμία παραγώγιμη, αλλιώς FAIL |
| W-K6 | CRLF vs LF → ΕΝΑ expression_id |
| W-K7 | 2 κλάσεις ίδια projector πεδία → διακριτά ids (register)· body-id ως Rule-B input → reject |
| W-K8 | ΠΝΠ 20.3.2020 (Α΄68) από 2 connectors → ΜΙΑ τριάδα byte-ίδια |
| W-K9 | γλώσσα εκτός registry («ell») → reject |
| W-K10 | άγνωστο edition πεδίο/τιμή → reject |
| W-K11 | make-body :kodikas χωρίς number → σφάλμα ΣΤΗΝ έδρα |

### [Τ-x] (κριτής atomicity v3)
| | |
|---|---|
| W-JB-TORN | torn tail + νέο append → όχι συγκόλληση· typed ετυμηγορία· replay πράσινο στο πρόθεμα |
| W-JB-RACE | 2 ταυτόχρονα appends ίδιου precondition → ένα γράφεται, το άλλο typed stale-precondition |
| W-J-TOPOLOGY | receipt χωρίς body → corpus journal· cross-journal batch → reject |
| W-COBIRTH-SWEEP | crash injection σε ΚΑΘΕ ζεύγος §0.4 → μερικότητα ορατή ή δομικά αδύνατη |
| W-FSYNC-LIE | mocked fsync failure → ΟΧΙ :durable |
| W-REL-RETRACT | αναίρεση batch-σχέσης → ΜΟΝΟ all-or-nothing |
| W-REG-PIN | registry edit → παλαιό replay ΑΜΕΤΑΒΛΗΤΟ |
| W-FLOOD | 10⁵ rejects → digests όχι σώματα· 2η διεργασία → ρητή άρνηση |
| W-JB-SUB-ID | πλαστό subevent id → corruption παρά έγκυρο batch hash |
| W-JB-NEST | κενό/nested batch → schema reject |

### [Β-1..7] (δημιουργός v4 — Π7-U.1B)
| | |
|---|---|
| W-SNAPSHOT-TYPES | valid_at "2020"/"2020-03" ή knowledge-cut πεδίο χωρίς legal-instant → reject· snapshot-at ΜΟΝΟ με (legal-date, legal-instant) |
| W-SNAPSHOT-FORK | ίδιο seq σε forked ιστορία → chain_root mismatch → FAIL· δηλωμένο root χωρίς recompute → δεν γίνεται πιστευτό |
| W-UNCERTAINTY-SET | ίδιο πλήθος, διαφορετικά αποκλεισμένα provisions → διακριτά roots· leaf χωρίς typed πεδία → reject |
| W-KYA-COISSUERS | connector Α «issuing» τον Χ, connector Β τον Ψ → ΙΔΙΟ work_id (register+protocol)· υπογράφοντες ΟΛΟΙ σε sorted issuance facts |
| W-AUTH-PIN-DUAL | ιδρυτικό γεγονός ως graph-cut pin → schema reject (ΜΙΑ μορφή: provision+tv_version_hash) |
| W-MANIFEST-URL | ίδιο αρχείο 2 URLs / ±url_hint → ΕΝΑ manifestation_id· URL πεδίο στο schema → reject |
| W-MEDIA-STATUS | asserted→verified / άλλος detector → manifestation_id ΑΜΕΤΑΒΛΗΤΟ· μόνο νέο media-verification record |
| W-PNP-SAME-ISSUE | 2 ΠΝΠ ίδιας μέρας/τεύχους → διακριτά ids (act_ordinal)· χωρίς ordinal → reject |
| W-SPEC-SELF-CONTAINED | grep «όπως v[0-9]» = 0 κανονιστικές εμφανίσεις· κάθε μνημονευόμενο schema ορίζεται ΜΕΣΑ στο αρχείο |
| W-JOURNAL-FRAME | χωρίς commit marker → typed torn + heal· multiline payload → σωστή ανάγνωση· newline-truncation → ανύπαρκτη διαδρομή· λάθος sha256 → torn |

### [Γ-C1..S3] (δημιουργός v5 — Π7-U.1C)
| | |
|---|---|
| **W-CROSS-JOURNAL-UNCERTAINTY** | επίλυση/προσθήκη uncertainty στο corpus journal ΧΩΡΙΣ αλλαγή version-graph → νέο corpus_cut → ΔΙΑΚΡΙΤΗ expression· snapshot που δηλώνει ΜΟΝΟ version cut → schema reject (knowledge-cut υποχρεωτικό) |
| **W-CUT-TIME-INFLATION** | knowledge-cut με last_recorded_at ≠ του πραγματικού record στο seq (μελλοντικό/διογκωμένο) → verifier FAIL· δύο «όρια» για το ίδιο prefix → αδύνατο (το πεδίο είναι παράγωγο, όχι δηλωτέο) |
| **W-CUT-SAME-SECOND** | 2 records ίδιου recorded_at, διαφορετικό seq → το cut στο πρώτο και στο δεύτερο = ΔΙΑΚΡΙΤΕΣ συντεταγμένες (seq επιλύει)· wall-clock μόνο του → δεν ορίζει cut |
| **W-KYA-ANNULMENT** | ακυρωτική ΣτΕ κατά ΚΑΝΟΝΙΣΤΙΚΗΣ ΚΥΑ (form: executive-administrative, effect: normative) → annuls relation ΔΕΚΤΗ (ο guard είναι form-based)· στο παλιό μονο-αξονικό sum θα απορριπτόταν — ο witness το αποδεικνύει |
| **W-JUDICIAL-INTERPRETATION** | απόφαση ΣτΕ που ερμηνεύει άρθρο → judicially-interprets ΔΕΚΤΗ (adjudicative → provision)· interpretive-instrument guard ΔΕΝ την μπλοκάρει· administratively-interprets από judgment → reject (διακριτές σχέσεις) |
| **W-REGISTER-REASSIGNMENT** | μεταφορά protocol-register σε άλλο υπουργείο (competence transfer assertion) → register_id ΑΜΕΤΑΒΛΗΤΟ → work ids πράξεων ΑΜΕΤΑΒΛΗΤΑ· 2 connectors → ΙΔΙΟ register_id (παράγωγο από founding+key) |
| **W-MANUAL-DEPOSIT** | receipt με origin manual-deposit (χωρίς url/status) → ΕΓΚΥΡΟ· network πεδία σε manual origin → reject· archive-import ομοίως |
| **W-REGISTRY-EXTENSION** | προσθήκη γλώσσας «es» ως registry εγγραφή → ΚΑΜΙΑ schema revision, υπάρχοντα ids ΑΜΕΤΑΒΛΗΤΑ· τιμή εκτός τρέχοντος registry → reject· ίδιο για media-type/edition-key |
