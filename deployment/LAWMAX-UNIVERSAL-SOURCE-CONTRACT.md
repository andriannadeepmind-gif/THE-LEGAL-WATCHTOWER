# LAWMAX — UNIVERSAL SOURCE CONTRACT (Π7-U.1) · **v5 — Π7-U.1B CANONICAL SNAPSHOT AND IDENTITY CLOSURE** · ΑΥΤΟΤΕΛΕΣ

**Κατάσταση:** ΠΡΟΤΑΣΗ προς τελική εξέταση («εγκρίνω Π7-U.1» εκκρεμεί).
Π7-U.2 implementation: ΠΑΓΩΜΕΝΟ. ΚΑΝΕΝΑ download/connector.
**Ιστορικό:** v1 → 2 κριτές [Ν-x]/[Α-x] (REJECTED) → v2 → 9 ευρήματα
δημιουργού [Δ-1..9] → v3 → 2 κριτές [Κ-x]/[Τ-x] → v4 (ΙΣΧΥΡΟΤΑΤΟ CANDIDATE)
→ 7 αποδεικτικά κενά δημιουργού [Β-1..7] → **v5 = παρόν, Π7-U.1B**.
Σύνολο: 6 αντιπαλικές επιθεωρήσεις, 51 ευρήματα, ΟΛΑ κλειστά ονομαστικά·
witnesses: W-Δ1..9, W-K1..11, W-J*, W-Β* (§12).
**ΑΥΤΟΤΕΛΕΙΑ [Β-6]:** το παρόν αρχείο περιέχει ΟΛΑ τα normative schemas και
invariants αυτούσια — ΚΑΜΙΑ αναφορά σε προηγούμενη έκδοση δεν είναι
κανονιστική· υλοποιήσιμο από καθαρό checkout αυτού του commit
(W-SPEC-SELF-CONTAINED). Οι δείκτες [x] είναι ΜΟΝΟ ιστορική απόδοση.
**Εγκεκριμένη βάση:** `b87f7d8b`. **#4A/B/C: CLOSED & FROZEN** (Πράξη
Έγκρισης `eb631750`). GAAF-1 + reasoning layers ΠΑΓΩΜΕΝΑ.

**Θεμελιώδεις αρχές:**
(α) ΚΑΝΕΝΑ hardcoded enum — versioned data registries με projector/key-shape
ΣΤΗΝ εγγραφή· (β) ταυτότητα ≠ ταξινόμηση ≠ τοποθεσία ≠ κατάσταση
επαλήθευσης [Δ-4/Δ-5/Β-4]: ό,τι διορθώνεται/μεταβάλλεται/αναβαθμίζεται
αργότερα ΔΕΝ συμμετέχει ποτέ σε identity hash· (γ) ατομικότητα = δομική
ιδιότητα ΕΝΟΣ framed append σε ΕΝΑ δηλωμένο journal [Δ-6/Τ-C3/Β-7]·
(δ) ΜΙΑ οδός ταυτότητας ανά πραγματική κλάση [Κ-C1]· (ε) τίμια άγνοια:
typed uncertainty πρώτης τάξης, ποτέ μαντεψιά, κανένα LLM στο trusted path.

---

## 0. Θεμέλια, μετάβαση, journal topology, συν-γεννήσεις, έδρα-κλεισίματα

### 0.1 Έδρες που καταναλώνονται ως έχουν

| Έννοια | Έδρα | Χρήση |
|---|---|---|
| Κανονική σειριοποίηση + hash | `canonical-representation` + `deployment/verify/canonical-serialization-spec.md` | ΚΑΘΕ id = canonical-hash επί κλειστού αντικειμένου· ΟΧΙ booleans σε hash-φέροντα (0/1 integers)· §2 text normalization για κάθε content hash |
| Ταυτότητα πράξης/provision | `orchestrator.identity` (make-body, make-provision-id, declared-body) | work ≡ body identity για Rule-A κλάσεις (§1.1) |
| Μητρώα ειδών | `body-kind-registry.sexp`, `instrument-kind-registry.sexp` | επέκταση με εγγραφές + αφαίρεση route-διπλών (§0.2β) |
| Διτεμπορικός γράφος | `orchestrator.version-graph` (per-body journal, admit-edge! replay-then-append, snapshot-at, version-at/TILING, regime/condition/instrument kinds, retract-*) | text-mutating γεγονότα· ο snapshot ορισμός §1.2 δένει στα ΠΡΑΓΜΑΤΙΚΑ types της έδρας [Β-1] |
| Journal πειθαρχία | `journal.lisp` [0086] | ΜΕ τα υποχρεωτικά κλεισίματα §0.5 (framing/CAS/fsync/single-writer) ΠΡΙΝ από κάθε Π7-U.2 κώδικα |
| Raw→text γέφυρα | `lawmax/extraction-receipt/1→/2`, `lawmax/normalization-receipt/1` (#4B) | Η ΜΟΝΗ γέφυρα bytes→κείμενο· /2 προσθέτει manifestation_id (§5.3) |
| Merkle | orchestrator.merkle (RFC-6962: leaf 0x00, node 0x01) | provision_set_root, uncertainty_set_root (§1.2) |
| Απόδειξη εξουσίας | `authority-proof-bundle/1` (CLOSED & FROZEN) | καταναλώνει τα παρόντα ΜΕΣΩ CENSUS — καμία μεταβολή στο frozen statement |

### 0.2 Μερικές έδρες που διαδέχεται — ταξινόμηση [0045]

| Υπάρχουσα | Επικαλύπτει | Ταξινόμηση + φάση θανάτου |
|---|---|---|
| `source-profile.lisp` (acquired-record, channels/authority-ranks, ιδιωτικό %canonical) | acquisition receipt, τυπολογία πηγών, 2η κανονικοποίηση | **B → Π7-U.3**: μετανάστευση σε acquisition-receipts· το %canonical πεθαίνει υπέρ canonical-representation· ranks → authority registry δεδομένα |
| `document-fetch.lisp` (fek-blob-url, enumerate-new-fek, fetch-fek-blob) | acquisition + locations με ΦΕΚ σημασιολογία | **B → Π7-U.2**: ξαναγράφεται ως gr-gazette acquirer· URL patterns → connector registry δεδομένα |
| `government-source.lisp` (feed/diavgeia/fek) | 2η τυπολογία πηγών | **B → Π7-U.3**: πηγές → registry εγγραφές |
| `corpus-provenance.lisp` (PROV-O) | 2ο provenance λεξιλόγιο | **A**: ΕΞΑΓΩΓΙΚΗ προβολή της αλυσίδας receipts — ποτέ πηγή αλήθειας· mapping table Π7-U.3 |
| **β)** body-kind-registry `:ya`, `:eu-reg`, `:eu-dir` | διπλή οδός ταυτότητας [Κ-C1] | **B → Π7-U.2 versioned registry φάση**: αφαιρούνται από τη Rule-A οδό — ΥΑ/ΚΥΑ ⇒ ΜΟΝΟ protocol-register projector (§1.4)· EU ⇒ ΜΟΝΟ {celex}. Μέχρι τη φάση δεν υλοποιείται connector, άρα η διπλή οδός δεν ασκείται |

### 0.3 Journal topology — ΡΗΤΗ [Τ-C3]

Το version-graph journal είναι **per-body**. Records που γεννιούνται ΠΡΙΝ
υπάρξει ταυτοποιημένο body (acquire→parse→identify) δεν χωρούν εκεί.
ΔΥΟ chain-hashed journals, καθένα με δικό του chain domain, ΙΔΙΑ journal.lisp
πειθαρχία (§0.5):

| Journal | Πεδίο | Kinds |
|---|---|---|
| **version-graph journal** (per-body, υπάρχον) | νομική κατάσταση σώματος | text-mutating (amendment/repeal/correction/normative-consolidation), regime (:suspend/:revive/:extend/:expire/:retroact), conditions, instrument (:ratification/:acceptance), relations-με-regime*, `:batch` |
| **corpus journal** (ΕΝΑ, νέο) | κτήση & αταξινόμητη πραγματικότητα | acquisition-receipt, location-observation, media-verification (§4.2), uncertainty + uncertainty-resolution, issuance-fact, work-record, proposal-rejected, relations-χωρίς-regime, mode-decision, `:batch` |

- Το `:batch` (§6.1) ορίζεται ΑΝΑ journal· **cross-journal batch = schema
  reject** — κάθε συν-γέννηση που διασχίζει journals μπαίνει στον πίνακα
  §0.4 με ονομαστικό recovery protocol (W-J-TOPOLOGY).
- *Relations με regime υπο-γεγονός (annuls, suspends-effect,
  declares-unconstitutional erga-omnes) ζουν στο version-graph journal του
  σώματος-στόχου, σε batch με το regime τους.

### 0.4 Πίνακας συν-γεννήσεων — ΕΞΑΝΤΛΗΤΙΚΟΣ [Τ-C4]

| Συν-γέννηση | Μηχανισμός |
|---|---|
| relation + regime event | batch, version-graph journal |
| normative consolidation event + codifies relation | batch, version-graph journal |
| uncertainty + «καραντίνα» artifact | ΕΝΑ corpus-journal record: καραντίνα ≡ ύπαρξη ανοιχτής uncertainty — το store ΔΕΝ κρατά δική του σημαία· δεύτερη κατάσταση δεν υπάρχει δομικά |
| work-record + issuance facts | batch, corpus journal (Ν+1 records = ΕΝΑ append) |
| expression + manifestation | ΔΕΝ είναι γεγονότα — παράγωγες content-addressed ταυτότητες: υπολογίζονται, δεν «συμβαίνουν»· κανένα recovery δεν απαιτείται |
| proposal-rejected + legal-effect-unresolved | batch, corpus journal |
| blob + acquisition receipt | recovery protocol §4.3 — η ΜΟΝΗ αναπόφευκτη δι-store σχέση, με ΟΡΑΤΗ μερικότητα και τυπωμένη ετυμηγορία |

### 0.5 ΥΠΟΧΡΕΩΤΙΚΑ κλεισίματα στην έδρα journal.lisp — BLOCKING πριν από κάθε Π7-U.2 κώδικα

1. **ΥΠΟΧΡΕΩΤΙΚΟ record framing — `lawmax/journal-frame/1` [Τ-C1, Β-7].**
   Το newline-based κριτήριο ΔΕΝ γίνεται δεκτό ως απόδειξη πληρότητας
   record (τα forms περιέχουν multiline strings· η απουσία newline δεν
   αποδεικνύει τίποτα). Κάθε record γράφεται framed:

   ```
   frame := "#F1 " <byte_length: decimal> " " <sha256(payload): hex> "\n"
            <payload: ακριβώς byte_length bytes>
            "\n#C1\n"                       # commit marker
   ```

   Record ΠΛΗΡΕΣ ⟺ (μήκος ✓) ∧ (sha256 payload ✓) ∧ (commit marker ✓).
   Οτιδήποτε άλλο = torn: typed ετυμηγορία προς τον καλούντα (ΟΧΙ μόνο ⚠
   σε *error-output* [Τ-NIT]) + journaled heal (truncate στο τελευταίο
   ΠΛΗΡΕΣ frame, με το heal καταγεγραμμένο ως record). Versioned schema:
   μελλοντική αλλαγή μορφής = frame/2, ποτέ σιωπηλή (W-JOURNAL-FRAME,
   W-JB-TORN). Μετάβαση υπαρχόντων journals: versioned migration φάση
   Π7-U.2 με byte-parity proof του περιεχομένου.
2. **Compare-and-append [Τ-C2]:** το precondition ελέγχεται ΣΤΟ append, ΥΠΟ
   το journal lock: mismatch ⇒ typed `stale-precondition` conflict, ΤΙΠΟΤΑ
   δεν γράφεται. Κλείνει και το προϋπάρχον `%journal!` race (chain
   υπολογισμένο προ-lock — θα χρησιμοποιηθεί το `last` του chained-append).
   Μόνο έτσι το replay δικαιούται να θεωρεί stored mismatch = corruption
   (W-JB-RACE).
3. **Fsync honesty [Τ-S5]:** το `ignore-errors` γύρω από το fsync ΠΕΘΑΙΝΕΙ —
   αποτυχία fsync ⇒ `wrote nil` ⇒ ΟΧΙ :durable ⇒ κανένα id (το «id ⟺
   durable» του [0086] στην πράξη) (W-FSYNC-LIE).
4. **Single-writer [Τ-S8]:** ΕΝΑΣ δηλωμένος συγγραφέας ανά journal
   (cross-process lease/O_EXCL)· δεύτερη διεργασία ⇒ ρητή typed άρνηση,
   όχι fork αλυσίδας. `proposal-rejected` δεσμεύει **digest** πρότασης,
   ποτέ σώμα (W-FLOOD).

---

## 1. Καθολική ταυτότητα — τέσσερα επίπεδα (FRBR-ισομορφικά)

```
WORK → EXPRESSION (sum type §1.2) → MANIFESTATION (§1.3) → ITEM (bytes §4)
```

Καμία ταυτότητα δεν αποδίδεται — κάθε ταυτότητα υπολογίζεται από κλειστό
σύνολο θεσμικών γεγονότων. URL, μορφότυπος-όπως-παρατηρήθηκε, χρόνος λήψης,
connector, κατάσταση επαλήθευσης: ΠΟΤΕ σε identity hash [Β-4].

### 1.1 Work identity — ΜΙΑ οδός ανά κλάση [Δ-3, Κ-C1, Κ-S7]

**Κανόνας Α (κλάσεις με body-kind):** `work identity ≡ body identity`
αυτούσιο (π.χ. `gr/nomos/2019/4619`) — κανένα νέο hash, κανένα prefix.
Εκδότες/συνυπογράφοντες: ΕΚΤΟΣ ταυτότητας, ως issuance facts (κατωτέρω).

**Κανόνας Β (λοιπές):**

```
work_id = "lsw1:" + canonical-hash({
  "schema":   "lawmax/work/1",
  "register": <register-id της εγγραφής source-class registry — ΤΑΥΤΟΤΙΚΟ:
               προσδιορίζει το ΘΕΣΜΙΚΟ ΜΗΤΡΩΟ ΑΡΙΘΜΗΣΗΣ (όχι ταξινόμηση)
               [Κ-S7]· δύο κλάσεις με ίδια key πεδία δεν συγκρούονται>,
  ...projector fields της εγγραφής})
```

**Invariant ΜΙΑΣ οδού [Κ-C1]:** το source-class registry φορτώνει ΜΟΝΟ αν
κάθε κλάση δηλώνει ΑΚΡΙΒΩΣ μία identity-route (body-kind XOR projector).
Body-id string ως Rule-B input ⇒ schema reject.

**Issuance facts [Δ-3, Β-2] — `lawmax/issuance/1`, corpus journal, σε batch
με το work-record (§0.4):**

```
{"schema": "lawmax/issuance/1",
 "work": {"id_type": "body" | "lsw1", "id": ...},
 "role": <registry: issuer | co-signer | countersigner | promulgator>,
 "authority_ids": <ΚΑΝΟΝΙΚΑ ΤΑΞΙΝΟΜΗΜΕΝΟ σύνολο ανά role [Β-2] — οι
                   συνυπογράφοντες ΚΥΑ εδώ, ΠΟΤΕ στην ταυτότητα>,
 "evidence": <provision-pin ή gazette span>, "recorded_at": <legal-instant>}
```

Διόρθωση απόδοσης/συνυπογραφόντων = νέο issuance fact με evidence —
ταυτότητα ΑΜΕΤΑΒΛΗΤΗ (W-Δ3, W-KYA-COISSUERS).

### 1.2 `lawmax/expression/1` — sum type [Δ-1], δεμένο στα ΠΡΑΓΜΑΤΙΚΑ types της έδρας [Β-1]

```
expression_id = "lse1:" + canonical-hash({"schema":"lawmax/expression/1",
                                          "kind": ..., ...kind-specific})
kind ∈ ΚΛΕΙΣΤΟ ΣΤΟ SCHEMA (sum type — η οντολογία επιπέδων είναι δομή του
contract, όχι επεκτάσιμα δεδομένα):
```

**provision-expression** — η υπάρχουσα ταυτότητα έκδοσης διάταξης, αυτούσια:
```
{"provision_id": <make-provision-id>, "tv_version_hash": <hex>,
 "language": <§1.5 — ρητό, default "el">}
```

**work-snapshot-expression** — ενοποιημένο work σε ΠΛΗΡΩΣ προσδιορισμένη
διτεμπορική θέση [Β-1]:
```
{"work": {"id_type": "body"|"lsw1", "id": ...},
 "language": <§1.5>,
 "valid_at": <ΠΛΗΡΕΣ legal-date "YYYY-MM-DD" — typed-partial ΑΠΑΓΟΡΕΥΕΤΑΙ
              εδώ: μερική ημερομηνία δεν επιλέγει μοναδική νομική κατάσταση
              (W-SNAPSHOT-TYPES)>,
 "graph_cut": {"seq": N,
               "chain_root": <chain head hash ΣΤΟ seq>,
               "recorded_through": <legal-instant "YYYY-MM-DDTHH:MM:SSZ" —
                 το known-at όριο ΤΗΣ ΕΔΡΑΣ, όχι το seq (το seq ΔΕΝ είναι
                 known_at [Β-1])>},
 "provision_set_root": <RFC-6962 root>,
 "uncertainty_set_root": <RFC-6962 root | "sha256:EMPTY-SET" — ΑΚΡΙΒΩΣ ποιες
   διατάξεις αποκλείστηκαν και γιατί, ΟΧΙ count [Β-1] (W-UNCERTAINTY-SET)>}
```

**Κανονικός ορισμός συνόλων + υποχρεώσεις verifier [Β-1]:**
```
graph    := load-graph(body, :up-to-seq seq)
ΕΛΕΓΧΟΙ  := graph-chain-head(graph) == chain_root          # W-SNAPSHOT-FORK
            ∧ graph-latest-recorded(graph) <= recorded_through
            ∧ κανένα record του prefix με recorded > recorded_through
snapshot := snapshot-at(graph, :valid-at valid_at,
                               :known-at recorded_through)  # τα ΠΡΑΓΜΑΤΙΚΑ
                                                            # types της έδρας
provision_set_root  := RFC-6962 root επί ΤΑΞΙΝΟΜΗΜΕΝΩΝ leaves
   leaf := canonical-JSON {"provision_id": ..., "tv_version_hash": ...}
uncertainty_set_root := RFC-6962 root επί ΤΑΞΙΝΟΜΗΜΕΝΩΝ leaves
   leaf := canonical-JSON {"provision_id": ..., "kind": <uncertainty kind>,
                           "uncertainty_id": ...}
```
Ο verifier ΑΝΑΫΠΟΛΟΓΙΖΕΙ και τα δύο roots από το prefix replay — δηλωμένα
roots δεν γίνονται πιστευτά (ίδια πειθαρχία με #4B). Το graph_cut.chain_root
κάνει το cut ΑΠΟΔΕΙΞΙΜΟ: ίδιο seq σε forked ιστορία ⇒ chain mismatch ⇒ FAIL.

**single-document-expression** — works με ενιαίο αδιαίρετο κείμενο
(judgment, gazette-issue, authentic treaty text):
```
{"work": {"id_type": ..., "id": ...}, "language": <§1.5>,
 "content_sha256": <sha256(UTF-8(κείμενο κανονικοποιημένο κατά §2 της
   canonical-serialization-spec — Η ΙΔΙΑ normalization των text-versions))
   [Κ-S6]>}
```

- **Rule-B works χωρίς body-kind** (π.χ. ΠΝΠ πριν την κύρωση): ΔΕΝ έχουν
  provision-ids (η provision ταυτότητα απαιτεί legal-body-id — γεγονός της
  έδρας) ⇒ νόμιμη expression ΜΟΝΟ single-document [Κ-S8]. Provision-δόμησή
  τους = δηλωμένο όριο v1 (§11).
- **Μονο-διατακτικά works [Κ-S5]:** provision-expression (μέρος) και
  work-snapshot (όλον) = ΔΙΑΦΟΡΕΤΙΚΑ FRBR αντικείμενα· η ισοδυναμία κειμένου
  ΠΑΡΑΓΩΓΙΜΗ από το μονοσύνολο root — ο verifier την ελέγχει (W-K5).

### 1.3 `manifestation_id` — ΜΟΝΟ κανονικά ταυτοτικά πεδία [Δ-2, Β-4]

```
manifestation_id = "lsm1:" + canonical-hash({
  "schema": "lawmax/manifestation/1",
  "expression_id": <ΥΠΟΧΡΕΩΤΙΚΟ — reject αν λείπει (W-Δ2)>,
  "media_type": <ΚΑΝΟΝΙΚΗ τιμή από media-type registry (§1.5) — ΟΧΙ
                 asserted/verified status, ΟΧΙ detection [Β-4]>,
  "official_variant": <registry: as-published | corrigendum-applied |
                       consolidated-official>,
  "publisher": {"kind": "authority" | "work-self",
                "authority_id": <όταν kind=authority>},
  "edition_key": <ΚΑΝΟΝΙΚΟ string από edition registry ("official-portal",
                  "print", "consolidated-database") — ΚΛΕΙΣΤΟ>})
```

**ΕΚΤΟΣ ταυτότητας [Β-4] — journaled evidence στο corpus journal:**
- URLs / url_hint → location-observations (§5.2) (W-MANIFEST-URL)
- observed content-types → acquisition receipts (§5.1)
- detection method/detector/manifests + asserted→verified αναβάθμιση →
  **`lawmax/media-verification/1`** records: {manifestation_id, method:
  registry(magic-bytes|declared-only|validated-parse), detector_manifest_
  sha256, verdict, artifact_digest, recorded_at} — η αναβάθμιση κατάστασης
  είναι ΓΕΓΟΝΟΣ, όχι νέα ταυτότητα (W-MEDIA-STATUS).

### 1.4 Identity projectors — δεσμευτικά v1 (πλήρης μορφή ΣΤΟ registry)

- `judgment`: `{court: authority_id, registry_number: int, year: int}` +
  `formation` ΜΟΝΟ όταν η εγγραφή δικαστηρίου στο authority registry δηλώνει
  `numbering: per-formation` (keyword από το κλειστό σύνολο formations της
  εγγραφής) [Ν-CRIT5]· judgment/court-order/court-minutes = ταυτοτικό
  series-field (διαφορετικά μητρώα αρίθμησης).
- `emergency-legislative-act` (ΠΝΠ) [Ν-CRIT3, Β-5]: **typed act locator**
  `{"gazette_ref": {"id_type": "lsw1", "id": <work_id του gazette-issue>},
  "act_ordinal": <int — η τάξη της πράξης ΜΕΣΑ στο τεύχος, από την επίσημη
  διάταξη ύλης του>}` — δύο ΠΝΠ ίδιας ημέρας στο ίδιο ΦΕΚ = διακριτά ordinals
  (W-PNP-SAME-ISSUE). Το promulgation_date = classification field
  (evidence-backed, εκτός hash). Byte spans = evidence της manifestation,
  ΠΟΤΕ ταυτότητα work. Κύρωση: :ratification instrument event· μη κύρωση
  εντός προθεσμίας: :expire regime event με evidence.
- `ministerial-decision` / `joint-ministerial-decision` / `administrative-act`
  / `interpretive-circular` [Κ-C1, Β-2/3]: **protocol-register οδός** —
  ```
  {"register_id": <εγγραφή του protocol-register registry — το ΘΕΣΜΙΚΟ
    μητρώο που εκδίδει τον επίσημο αριθμό· η εγγραφή δένει το μητρώο με
    την υπηρεσία/αρχή του ΜΕ EVIDENCE, αλλά η ΑΡΧΗ ΔΕΝ είναι στο hash:
    ο connector δεν διαλέγει ποτέ «issuing authority» [Β-2]>,
   "protocol_number": string, "protocol_date": date}
  ```
  Ο εκδότης + ΟΛΟΙ οι συνυπογράφοντες ΚΥΑ = sorted issuance facts (§1.1)
  (W-KYA-COISSUERS). «Διόρθωση απόδοσης» = νέο issuance fact· «άλλο μητρώο»
  = άλλη πράξη (δηλωμένη σημασιολογία).
- `eu-*`: `{celex}` για ΟΛΕΣ τις eu κλάσεις [Δ-4] — η κλάση είναι
  classification field· αναταξινόμηση δεν αγγίζει ταυτότητα (W-Δ4).
- `international-treaty`: `{parties: sorted-set, conclusion_date: date,
  authentic_title_sha256}` [Ν-S9] — depositary registration = evidence.
- `gazette-issue`: `{gazette_authority_id, series: string, issue: int,
  year: int}`.
- `code` (ΑΚ, ΚΠολΔ): Κανόνας Α μέσω `:kodikas`· **number ΥΠΟΧΡΕΩΤΙΚΟ ΣΤΗΝ
  έδρα make-body** (σήμερα δέχεται NIL για κάθε kind πλην :syntagma — ο
  φρουρός κατεβαίνει στην έδρα, Π7-U.2 προ-παραδοτέο) [Κ-M11]· το number =
  της κυρωτικής πράξης, δηλωμένο στην εγγραφή.

### 1.5 Κλειστοί πίνακες τιμών (στο schema)

- `language`: ISO 639-1 — v1: `"el", "en", "fr", "de"`· «ell»/«gre» ⇒
  reject [Κ-M9] (W-K9).
- `media-type registry`: `"application/pdf", "text/html", "application/xml",
  "text/plain"` — κανονικές τιμές· ο,τιδήποτε άλλο ⇒ uncertainty.
- `edition registry`: `"official-portal", "print", "consolidated-database"`.

---

## 2. Τυπολογίες ως versioned data registries

### 2.1 Source-class registry — `deployment/data/source-class-registry.sexp`

Πρότυπο body-kind-registry: sexp, `*read-eval*` nil, census-καταγεγραμμένο.
Ανά εγγραφή ΥΠΟΧΡΕΩΤΙΚΑ (gated load — εγγραφή χωρίς οποιοδήποτε ΔΕΝ φορτώνει):

```
class                  — όνομα
register-id            — μητρώο αρίθμησης (ταυτοτικό στο Rule-B hash) [Κ-S7]
work-category          — ΕΝΑΣ δείκτης στο tagged sum §3.1 [Δ-7]
identity-route         — body-kind XOR projector [Κ-C1]
projector / key-shape  — τα πεδία ταυτότητας + τύποι τους (string | integer |
                         date | sorted-set-of-string | tagged-ref) [Ν-CRIT1]
classification-fields  — μεταβλητά assertions — ΠΟΤΕ στο hash [Δ-4]
required-evidence      — απόδειξη γέννησης εγγραφής
mutating-capable       — 0/1
```

v1 περιεχόμενο: όλα τα body-kinds (nomos, kodikas, nd, an, psifisma,
syntagma, pd, …) + emergency-legislative-act, ministerial-decision,
joint-ministerial-decision, administrative-act, gazette-issue, judgment,
court-order, court-minutes, eu-treaty, eu-regulation, eu-directive,
eu-decision, eu-judgment, international-treaty, interpretive-circular,
opinion-nsk, parliament-standing-orders, independent-authority-decision.
Άγνωστη κλάση ⇒ `unclassified-source` uncertainty + καραντίνα (≡ ανοιχτή
uncertainty §0.4). Συντακτικές Πράξεις: ΕΚΤΟΣ v1, τίμια unclassified,
δηλωμένη μελλοντική εγγραφή [Κ-NIT12].

**Protocol-register registry** (νέο, ίδιο πρότυπο): ανά εγγραφή
{register_id, owning_authority_id + evidence, series, existence interval} —
τα θεσμικά μητρώα πρωτοκόλλου των ΥΑ/ΚΥΑ/διοικητικών πράξεων [Β-2/3].

### 2.2 Authority registry — `deployment/data/authority-registry.sexp`

```
{"schema": "lawmax/authority/1",
 "authority_id": "auth1:" + canonical-hash({
    "jurisdiction": <§2.3>,
    "founding_locator":
        {"locator_type": "provision-id",
         "value": {"provision_id": ..., "tv_version_hash": <hex>}}
          # ΜΙΑ ΜΟΝΟ μορφή pin [Β-3]: το ζεύγος (provision, έκδοση) —
          # το graph cut είναι PROVENANCE της επίλυσης, ΟΧΙ ταυτότητα
          # (W-AUTH-PIN-DUAL)· επανίδρυση από νέα έκδοση της ίδιας
          # διάταξης (αναθεώρηση: το gr/syntagma είναι άχρονο body) ⇒
          # διακριτό id [Κ-C3] (W-K3)
      | {"locator_type": "span",
         "value": {"artifact_digest": ..., "start": N, "end": N}}
      | {"locator_type": "pre-corpus",
         "value": {"instrument": string, "date": <typed-partial>,
                   "gazette_ref": string}},   # ΑΠ 1834 κ.λπ. [Ν-S10]
    "entity_key": <ΚΑΝΟΝΑΣ: ordinal ΠΑΝΤΑ όταν η ιδρυτική διάταξη
                   αριθμεί/απαριθμεί· κανονική θεσμική ονομασία ΜΟΝΟ
                   αλλιώς — μη-κανονική επιλογή ⇒ reject [Κ-S4] (W-K4)>}),
 "kind": <VERSIONED ASSERTION — ΕΚΤΟΣ hash [Δ-5] (W-Δ5β):
          parliament | president | minister-council | ministry | minister |
          court | prosecutor | independent-authority | central-bank |
          municipality | region | eu-institution | international-org>,
 "names":    [{"name", "valid_from", "valid_to", "evidence": work-ref}...],
 "lineage":  [{"relation": renamed-from | merged-from | split-from |
               abolished | re-established-as | competence-transferred-to,
               "counterpart": authority_id, "effective": date,
               "evidence": work-ref}...],
 "numbering": <courts: unified | per-formation + formations: κλειστό σύνολο
               keywords>,
 "existence": {"from": <date|typed-partial>, "to": <date|null>,
               "evidence": ...}}
```

- Μία πράξη που ιδρύει Ν αρχές ⇒ Ν διακριτά (locator, entity_key) ⇒ Ν ids
  (W-Δ5).
- **Genesis ακολουθία [Α-S7], journaled:** (i) Σύνταγμα (body `:syntagma`) ⇒
  (ii) constitutional-basis αρχές (Βουλή, ΠτΔ, ΣτΕ, ΕλΣυν· ΑΠ pre-corpus) ⇒
  (iii) αναδρομικά evidence-backed. Όχι σιωπηλό seeding.
- Δέσμευση ΜΕΣΩ CENSUS (κανονικό αρχείο) — ΚΑΜΙΑ αλλαγή στο frozen
  authority-statement [Α-S10].

### 2.3 Jurisdiction registry [Ν-M12]

Registry εγγραφών (όχι enum/template): v1 `gr`, `eu`, `int`· ρητές εγγραφές
ανά περιφέρεια/δήμο όταν χρειαστούν (ΟΤΑ εκδίδουν κανονιστικές). Νέα
δικαιοδοσία = εγγραφή με evidence.

---

## 3. Οντολογία — disjoint tagged sum [Δ-7]

### 3.1 `source-work` — ΚΛΕΙΣΤΟ tagged sum (δομή contract, ΟΧΙ registry)

```
source-work
├─ publication-work        (gazette-issue — εκδοτικό τεκμήριο, ΟΧΙ legal act)
├─ normative-act           (νόμοι, ΠΔ, ΥΑ/ΚΥΑ, ΠΝΠ, κώδικες, κανονισμοί)
├─ adjudicative-work       (judgments, βουλεύματα, πρακτικά)
├─ administrative-act      (ατομικές/κανονιστικές διοικητικές πράξεις)
├─ interpretive-instrument (εγκύκλιοι, γνωμοδοτήσεις ΝΣΚ)
└─ treaty-work             (διεθνείς/ενωσιακές συνθήκες)
```

- Κάθε source-class δηλώνει work-category — ΕΝΑ. Type guard δομικός: σχέση/
  γεγονός με λάθος category άκρου = σφάλμα γέννησης record στην έδρα
  (etypecase) — όχι έλεγχος καταναλωτή (W-Δ7).
- **provision, expression, manifestation, artifact = ΕΠΙΠΕΔΑ (§1), ΟΧΙ
  κατηγορίες** — δεν εμφανίζονται στο sum. Judgment/interpretation =
  work-categories του ΙΔΙΟΥ sum, όχι «ισότιμοι τύποι δίπλα στο work».
- ΦΕΚ (publication-work) ΠΕΡΙΕΧΕΙ normative-acts: σχέση `published-in`
  (§6.3) — όχι υπαγωγή τύπων.
- opinion-nsk: δεσμευτικότητα = :acceptance instrument event (νέα εγγραφή
  στο instrument-kind-registry) με evidence την πράξη αποδοχής — ΟΧΙ πεδίο
  status [Ν-S8].

---

## 4. Raw artifact — ΜΟΝΟ εγγενή πεδία [Δ-9, Α-S5]

### 4.1 `lawmax/raw-artifact/1`

```
{"schema": "lawmax/raw-artifact/1",
 "digest_algorithm": "sha256", "digest": <hex>, "byte_length": N}
```

- ΚΑΝΕΝΑ media_type (μη εγγενές — W-Δ9α: πεδίο ⇒ schema reject)· ΚΑΝΕΝΑΣ
  δείκτης receipts (φορά receipt→artifact, many-to-one — ίδια bytes από Ν
  λήψεις = ΕΝΑ record, W-Δ9β).
- Append-only, content-addressed store· read-back verification πριν από
  κάθε δείκτη ([0086] Persistence Receipt πειθαρχία). Κάθε μετασχηματισμός
  (OCR, decompress, re-encode) ⇒ ΝΕΟ artifact + δεσμός ΜΟΝΟ μέσω
  extraction/normalization receipts. Το raw επιζεί ΓΙΑ ΠΑΝΤΑ — και επί
  αποτυχίας parsing (καραντίνα ≡ ανοιχτή uncertainty §0.4).

### 4.2 Media evidence — ΕΚΤΟΣ ταυτότητας [Β-4]

`lawmax/media-verification/1` records στο corpus journal (§1.3): method,
detector manifest, verdict, αναβαθμίσεις asserted→verified — ΓΕΓΟΝΟΤΑ.
Το manifestation φέρει ΜΟΝΟ την κανονική media-type τιμή. Απόκλιση
observed↔verified = τυπωμένο γεγονός + πιθανή uncertainty, ποτέ νέα ταυτότητα.

### 4.3 Blob↔receipt recovery protocol [Δ-9]

Σειρά ΠΑΝΤΑ: (1) blob write + fsync + read-back digest· (2) acquisition
receipt ως framed journaled record (§0.5.1). Recovery:
- Blob χωρίς receipt = ορφανό ⇒ ΚΑΡΑΝΤΙΝΑ (αόρατο)· επανυιοθέτηση ΜΟΝΟ με
  νέο receipt — ποτέ σιωπηλή (W-Δ9γ).
- Receipt χωρίς blob = ΣΚΛΗΡΟ ΣΦΑΛΜΑ κλάσης journal-corruption (W-Δ9δ).
- Artifact «υπάρχει» ΜΟΝΟ ως ζεύγος (blob, ≥1 receipt)· η μερικότητα ΟΡΑΤΗ
  με τυπωμένη ετυμηγορία — η ΜΟΝΗ αναπόφευκτη δι-store σχέση του σχεδίου.

---

## 5. Acquisition, locations, γέφυρες

### 5.1 `lawmax/acquisition-receipt/1` — hash-φέρον, χωρίς booleans [Α-CRIT2]

```
{"schema": "lawmax/acquisition-receipt/1",
 "receipt_id": "acq1:" + canonical-hash(αντικείμενο πλην receipt_id),
 "artifact_digest": <hex>, "digest_algorithm": "sha256",
 "fetched_from": {"url": ..., "protocol": "https", "status": 200,
                  "observed_content_type": ...,        # ΕΔΩ — όχι στο artifact
                  "response_headers_subset": {"content-type", "last-modified",
                                              "etag"}},
 "fetched_at": <ISO UTC — δηλωμένα αναξιόπιστο μόνο του>,
 "anchoring": {"tlog_leaf_index": N, "tsr_sha256": <digest — ΟΧΙ path
               [Α-M12]>} | null,     # μόνο TSA/tlog αποδεικνύει ύπαρξη-πριν
 "acquirer": {"acquirer_id": ..., "manifest_sha256": ...},
 "verification": {"read_back": 1, "digest_recomputed": 1}}   # integers 0/1
```

Manual-deposit (offline artifact) = νόμιμο acquirer είδος στο registry.

### 5.2 Location observations — journaled, ΕΚΤΟΣ κάθε ταυτότητας [Α-M13, Β-4]

`lawmax/location-observation/1` (corpus journal): {work-ref,
manifestation_id, url, observed_at, acquisition_receipt_id, status:
served-bytes | redirect | gone | changed-digest}. History = replay προβολή
— ΟΧΙ hash-φέρον container. `changed-digest` σε επίσημο URL ⇒ υποχρεωτικά
νέο manifestation Ή official-sources-conflict/source-integrity uncertainty
— ποτέ σιωπηλή αντικατάσταση. URLs σε ΚΑΝΕΝΑ identity hash (W-MANIFEST-URL).

### 5.3 Γέφυρα item→manifestation: `lawmax/extraction-receipt/2`

= /1 (#4B, αυτούσιο) + πεδίο `manifestation_id`. Versioned επέκταση: τα /1
των CLOSED #4B bundles παραμένουν έγκυρα — ο Π7-U verifier δέχεται και τις
δύο εκδόσεις δηλωμένα. Η αλυσίδα bytes → extraction → normalization →
graph text κλείνει χωρίς URL [Α-S8].

### 5.4 typed-partial dates [Α-S9]

ΜΟΝΟ strings `"YYYY"` | `"YYYY-MM"` | `"YYYY-MM-DD"` (ISO reduced
precision)· προστίθενται στην canonical spec με conformance vectors
(Π7-U.2, ΠΡΙΝ από κάθε χρήση σε hash). Επιτρεπτά ΜΟΝΟ σε: official keys
(όπου δηλωμένα), pre-corpus citations, uncertainty, existence intervals.
**ΑΠΑΓΟΡΕΥΟΝΤΑΙ σε: valid_at/known_at/recorded_through** — εκεί ΜΟΝΟ τα
πλήρη types της έδρας (legal-date / legal-instant) [Β-1] (W-SNAPSHOT-TYPES).

---

## 6. Journal semantics — batch, consolidation, relations

### 6.1 `lawmax/journal-batch/1` [Δ-6, Τ-C2/M9/M10]

```
journal kind :batch — ΑΝΑ journal (§0.3)· cross-journal ⇒ schema reject
{"schema": "lawmax/journal-batch/1",
 "batch_id": "jb1:" + canonical-hash(περιεχομένου),
 "precondition_root": <chain head — compare-and-append ΥΠΟ το lock (§0.5.2):
                       mismatch ⇒ typed stale-precondition, ΤΙΠΟΤΑ δεν
                       γράφεται (W-JB-RACE)>,
 "ordered_subevents": [<πλήρη semantic records, με τη σειρά>]}
```

- ΕΝΑ seq, ΕΝΑ framed record (§0.5.1), ΜΙΑ chain transition — μερική
  μετάβαση δομικά αδύνατη (W-Δ6). Κανένα `:up-to-seq` cut δεν πέφτει ΜΕΣΑ
  σε batch (δηλωμένο).
- Subevent πειθαρχία [Τ-M9]: κάθε subevent φέρει το δικό του record-id·
  semantic replay checks ΑΝΑ subevent (πλαστό subevent δεν κρύβεται πίσω
  από έγκυρο batch hash — W-JB-SUB-ID)· κατανάλωση από version-at/TILING =
  ως διαδοχικές γραμμές στη θέση του batch· ενδο-batch αναφορές ΜΟΝΟ προς
  προηγούμενο subevent· κοινό `:at` = μία πράξη, μία στιγμή.
- `ordered_subevents` ≥ 1· subevent kind ≠ :batch (W-JB-NEST).
- All-or-nothing replay· άκυρο subevent ⇒ ΟΛΟ το batch απορρίπτεται.

### 6.2 Text-mutating + consolidation split [Δ-8, Τ-S6]

- `amendment, repeal, correction (νομοθετική)`: γεγονότα version-graph
  (υπάρχοντα kinds) μέσω graph-event-proposal + admit-edge!.
- `consolidation` — evidence-backed legal-effect mode, ΟΧΙ όνομα πράξης:
  - **normative** (κωδικοποίηση/κύρωση με κανονιστική ισχύ — evidence: η
    εξουσιοδοτική/κυρωτική διάταξη): γεγονός γράφου ΣΕ BATCH με codifies.
  - **derived** (επίσημη/εκδοτική ενοποίηση χωρίς νέο κανονιστικό
    αποτέλεσμα): ΚΑΝΕΝΑ γεγονός γράφου — work-snapshot-expression +
    manifestation με variant consolidated-official (W-Δ8).
  - Χωρίς mode evidence ⇒ `legal-effect-unresolved` — ΠΟΤΕ default.
- **Mode-decision = journaled record** (corpus journal): {evidence-pin,
  decider: creator, mode} — ο δημιουργός αποφασίζει (κανένα LLM, ο pure
  parser δεν κρίνει), η απόφαση έχει μόνιμη έδρα [Τ-S6].
- **Αντίστροφος φρουρός [Τ-S6]:** derived submission για work του οποίου η
  πηγή φέρει κυρωτική/εξουσιοδοτική citation ήδη στο corpus ⇒ ΥΠΟΧΡΕΩΤΙΚΟ
  legal-effect-unresolved — η σιωπηλή απώλεια κανονιστικού αποτελέσματος
  ΔΕΝ περνά (W-Δ8β).
- Instrument/regime events: `:ratification` (ΠΝΠ/συνθήκες), `:acceptance`
  (ΝΣΚ), `:suspend/:revive/:extend/:expire/:retroact` — υπάρχουσες έδρες.

### 6.3 Non-mutating relations — `lawmax/legal-relation/1` ως journal kind [Α-CRIT3, Ν-S7, Τ-S7]

Record: {relation_id: "rel1:"+canonical-hash, relation: <kind>, from/to:
{type ∈ work-categories §3.1, id}, evidence: {work-ref, provision-pin ή
dispositif-pin}, bitemporal: {valid_from: date|typed-partial, known_at:
legal-instant}, verdict_basis: explicit-citation | operative-part,
relation_registry_digest: <pinned [Τ-S7]>}.

Kinds — registry:

| kind | άκρα (type guard) | βάση |
|---|---|---|
| `interprets` | interpretive-instrument → provision\|normative-act | explicit-citation |
| `annuls`* | adjudicative → administrative-act | operative-part |
| `declares-unconstitutional{erga-omnes\|incidenter}`* | adjudicative → provision | operative-part· ΜΟΝΟ erga-omnes (ΑΕΔ, άρθ. 100 Σ) φέρει regime υπο-γεγονός· incidenter = inter partes, καθαρή σχέση |
| `suspends-effect`* | adjudicative (ΕΑ) → normative-act\|provision | operative-part |
| `authorizes-delegation` | statute provision → pd\|ministerial-decision | explicit-citation (το προοίμιο την τυπώνει) |
| `resolves-pilot-question` | adjudicative (ΟλΣτΕ, ν. 3900/2010) → provision | operative-part — ΤΥΠΙΚΗ δεσμευτικότητα |
| `precedent-follows` / `precedent-distinguishes` | adjudicative → adjudicative | explicit-citation ΜΟΝΟ |
| `codifies{legislative\|administrative}` | code-work → statutes | explicit-citation· administrative = χωρίς αυτοτελή κανονιστική ισχύ |
| `published-in` | κάθε work → publication-work | explicit position |

\* = ΥΠΟΧΡΕΩΤΙΚΑ σε batch με το regime υπο-γεγονός τους, στο version-graph
journal του σώματος-στόχου.
- ΠΟΤΕ inferred — κανένα LLM/similarity στο trusted path.
- **Relation-retract [Τ-S7]:** συμμετρικό με τη γέννηση — σχέση γεννημένη
  σε batch αναιρείται ΜΟΝΟ ως batch (relation-retract + regime-retract
  μαζί)· μερική αναίρεση δομικά αδύνατη (W-REL-RETRACT).
- **Registry pinning [Τ-S7]:** η υποχρέωση «relation ⇒ batch» κρίνεται στο
  replay ΚΑΤΑ το `relation_registry_digest` του record — registry edits δεν
  αλλάζουν αναδρομικά τη νομιμότητα γραμμένων journals (W-REG-PIN).

---

## 7. Connectors — acquirer (impure) / parser (pure) [Α-CRIT1]

### 7.1 `lawmax/acquirer/1`

Emits ΜΟΝΟ: raw-artifact, acquisition-receipt, location-observation.
Impure· ίχνος = receipts· recovery §4.3. Manifest: {acquirer_id, version,
sources, rate policy, manual-deposit capability}.

### 7.2 `lawmax/parser/1`

Καθαρή συνάρτηση (artifacts + receipts) → {work-record, issuance-fact,
expression, manifestation, legal-relation-proposal, graph-event-proposal,
journal-batch-proposal, authority-proposal, uncertainty}. Emits ΞΕΝΟ προς
acquirer. Determinism gate: διπλή εκτέλεση ⇒ byte-ίδια έξοδος
(SOURCE_DATE_EPOCH). Κανένα δίκτυο/ρολόι/connector-ιδιωτικό πεδίο — ό,τι
δεν χωρά στα schemas ⇒ uncertainty με το raw διατηρημένο.

### 7.3 Προτάσεις, όχι εγγραφές [Α-S6, Τ-S8]

- graph-event-proposal ≡ κανονικοποιημένο espec του ΥΠΑΡΧΟΝΤΟΣ admit-edge!
  (schema με παράγωγο id — ίδια σημασιολογία).
- Απόρριψη = journaled `proposal-rejected` (digest πρότασης + αιτία — ΟΧΙ
  σώμα).
- Authority-registry admission gate: ΔΕΝ υπάρχει σήμερα — ΔΗΛΩΜΕΝΟ
  παραδοτέο Π7-U.2 (replay-then-append στο ίδιο πρότυπο).
- **Write authority:** ΕΝΑΣ δηλωμένος συγγραφέας ανά journal (admission
  gate)· connectors ΠΟΤΕ δεν αγγίζουν journal (W-FLOOD).

### 7.4 Κοινή σουίτα συμμόρφωσης

Κάθε acquirer/parser περνά ΤΑ ΙΔΙΑ vectors (golden + αντιπαλικά ⊇ ΟΛΟΙ οι
witnesses §12) — gated στο Docker. Χωρίς πράσινο, δεν εγγράφεται στο
connector registry. Vectors καρφώνουν και τη σειριοποίηση εξόδων από Lisp
δομές (plist/alist/array) [Α-NIT].

---

## 8. Typed uncertainty — `lawmax/uncertainty/1`

```
{"schema": "lawmax/uncertainty/1",
 "uncertainty_id": "unc1:" + canonical-hash(...),
 "kind": <registry — v1:
   source-unverified | identity-ambiguous (candidate_ids ΤΥΠΩΜΕΝΑ) |
   official-key-incomplete | authority-unresolved | relation-unproven |
   date-partial | source-integrity | unclassified-source |
   official-sources-conflict | pending-ratification |
   commencement-unresolved | authenticity-pending | legal-effect-unresolved>,
 "subject": {"artifact_digest" | "work-ref" | "candidate_ids": [...]},
 "evidence": <τι ΞΕΡΟΥΜΕ — ποτέ κενό>,
 "blocking": <τι μπλοκάρεται — π.χ. "work-id-mint" | "relation-record">}
```

Πρώτης τάξης, corpus journal, ορατό στο /as-known στρώμα (υπάρχον pending
μονοπάτι Φ7-Π5). Θάνατος ΜΟΝΟ με νέο evidence ή ρητή απόφαση δημιουργού —
journaled `uncertainty-resolution` με δείκτη στο evidence. Καμία
αυτοεπίλυση. Καραντίνα artifact ≡ ανοιχτή uncertainty (§0.4).

---

## 9. Καμία ΦΕΚ-ειδική δομή [Ν-NIT15, Α-M11]

- ΦΕΚ = ΔΕΔΟΜΕΝΑ: gazette-issue projector + σειρές («Α», «Β», …) στις
  registry εγγραφές της gr δικαιοδοσίας. ΚΑΝΕΝΑ νέο πεδίο σχήματος/
  registry-δομής/connector hook με σημασιολογία «ΦΕΚ».
- **Gate με ρητή λίστα αρχείων** (versioned, ζει στο ίδιο το gate test):
  τα Π7-U registries (source-class, protocol-register, authority,
  jurisdiction, relation-kind) + τα νέα source αρχεία acquirer/parser
  contract — έλεγχος tokens fek/φεκ· επιτρεπτές εμφανίσεις ΜΟΝΟ σε registry
  ΔΕΔΟΜΕΝΑ.
- **Δηλωμένα προϋπάρχοντα υπόλοιπα** (εκτός πεδίου του gate, με φάση):
  `:fek-date` (amendment-edge journal record), `:fek-ref` (instrument
  evidence schema) — προϋπάρχουν στη σπονδυλική στήλη· μετονομασία σε
  gazette-ουδέτερο όρο = μελλοντική versioned φάση (journal format), ΟΧΙ
  σιωπηλή εδώ.
- Τα 9 ΦΕΚ (Π7 benchmark) = ΠΕΛΑΤΗΣ του καθολικού: gazette-issue works
  μέσω gr-gazette acquirer+parser — η ίδια διαδρομή κάθε μελλοντικής πηγής.

---

## 10. Κριτήρια αποδοχής Π7-U.1

1. Ρητή τελική έγκριση δημιουργού («εγκρίνω Π7-U.1»). Ιστορικό: 6
   επιθεωρήσεις (2×v1, δημιουργός×2 [v2: Δ-1..9, v4: Β-1..7], 2×v3), 51
   ευρήματα, ΟΛΑ κλειστά ονομαστικά στο παρόν.
2. Registries: identity-route XOR + projector/classification/evidence/
   key-shape ανά εγγραφή — gated load.
3. Journal topology ρητή (§0.3)· συν-γεννήσεις εξαντλητικές (§0.4)· §0.5
   framing/CAS/fsync/single-writer = BLOCKING προ-παραδοτέα Π7-U.2.
4. Αυτοτέλεια: το παρόν αρχείο πλήρες — μηχανικός όρος
   W-SPEC-SELF-CONTAINED (§12).
5. Ο όρος §9 μηχανικά επαληθεύσιμος.
6. **Π7-U.2 ΠΑΓΩΜΕΝΟ** — παραδοτέα (με σειρά): §0.5 journal fixes + frame
   migration, typed-partial canonical vectors, extraction-receipt/2,
   corpus journal + batch replay, registry route-φάση (§0.2β), make-body
   number guard, authority gate, proposal schemas, conformance vectors
   (⊇ §12), gr-gazette acquirer+parser.

## 11. Δηλωμένα όρια v1 (τίμια)

- Πολυγλωσσία: ισοδυναμία expressions μεταξύ γλωσσών = μελλοντική φάση.
- Provision-δόμηση Rule-B works (άρθρα ΠΝΠ προ κύρωσης) = μελλοντική φάση —
  μέχρι τότε single-document ΜΟΝΟ.
- Συντακτικές Πράξεις: εκτός v1, τίμια unclassified.
- Authority registry: genesis ακολουθία· πληρότητα = μετρήσιμη εκκρεμότητα.
- Blob↔receipt: η ΜΟΝΗ δι-store σχέση — ορατή μερικότητα (§4.3).
- Redaction judgments: typed `parties_redacted`· πολιτική = απόφαση
  δημιουργού.
- Το παρόν δεν επικαλείται καμία ανύπαρκτη υποδομή ως υπάρχουσα (§10.6).

---

## 12. ΟΝΟΜΑΣΤΙΚΟΙ NEGATIVE WITNESSES — υποχρεωτικά αντιπαλικά vectors Π7-U.2

### Δημιουργού v2 [Δ-1..9]
| | Στήνει → Αναμενόμενο |
|---|---|
| W-Δ1 | ίδιο work, δύο cuts, ίδια γλώσσα/μορφότυπος/variant → διαφορετικά manifestation_ids |
| W-Δ2 | manifestation χωρίς expression_id → schema reject |
| W-Δ3 | διόρθωση συνυπογραφόντων make-body νόμου → ταυτότητα ΑΜΕΤΑΒΛΗΤΗ, νέο issuance fact |
| W-Δ4 | CELEX αναταξινόμηση eu-decision→eu-regulation → work_id ΑΜΕΤΑΒΛΗΤΟ |
| W-Δ5/β | μία πράξη ιδρύει 2 αρχές → 2 ids· διόρθωση kind → id ΑΜΕΤΑΒΛΗΤΟ |
| W-Δ6 | ορφανό μισό (relation χωρίς regime όπου απαιτείται batch) → replay FAIL· άκυρο subevent → ΟΛΟ το batch απορρίπτεται |
| W-Δ7 | gazette-issue ως normative-act / λάθος category άκρου → σφάλμα γέννησης |
| W-Δ8/β | editorial-ως-normative → reject· normative-ως-derived → ΟΧΙ σιωπηλή αποδοχή (αντίστροφος φρουρός) |
| W-Δ9α-δ | media_type στο artifact → reject· ίδια bytes 2 content-types → ΕΝΑ artifact/2 receipts· blob χωρίς receipt → καραντίνα· receipt χωρίς blob → σκληρό σφάλμα |

### Κριτή identity/FRBR v3 [Κ-x]
| | |
|---|---|
| W-K1 | ίδια ΚΥΑ από 2 connectors → duplicate-route reject· ΥΑ ως make-body → αδύνατο (οδός αφαιρεμένη) |
| W-K2 | ίδιο cut, 2 valid_at με διαφορετικό ενεργό σύνολο → 2 ΔΙΑΚΡΙΤΕΣ expressions |
| W-K3 | ίδρυση από v1 και v2 της ίδιας συνταγματικής διάταξης → 2 authority_ids |
| W-K4 | δύο νόμιμα entity_keys → το μη-κανονικό reject· locator tags → citation-string ≠ provision-id string |
| W-K5 | μονο-διατακτικό work → ισοδυναμία παραγώγιμη από μονοσύνολο root, αλλιώς FAIL |
| W-K6 | CRLF vs LF judgment → ΕΝΑ expression_id |
| W-K7 | 2 κλάσεις ίδια projector πεδία → διακριτά ids (register)· body-id ως Rule-B input → reject |
| W-K8 | ΠΝΠ 20.3.2020 (Α΄68) από 2 connectors → ΜΙΑ τριάδα byte-ίδια |
| W-K9 | "ell" → reject |
| W-K10 | άγνωστο edition πεδίο → reject |
| W-K11 | make-body :kodikas χωρίς number → σφάλμα ΣΤΗΝ έδρα |

### Κριτή atomicity v3 [Τ-x]
| | |
|---|---|
| W-JB-TORN | torn tail + νέο append → όχι συγκόλληση· typed ετυμηγορία· replay πράσινο στο έγκυρο πρόθεμα |
| W-JB-RACE | 2 ταυτόχρονα appends ίδιου precondition → ακριβώς ένα γράφεται, το άλλο typed stale-precondition |
| W-J-TOPOLOGY | receipt χωρίς body → corpus journal· cross-journal batch → reject |
| W-COBIRTH-SWEEP | crash injection σε ΚΑΘΕ ζεύγος του §0.4 → μερικότητα ορατή ή δομικά αδύνατη |
| W-FSYNC-LIE | mocked fsync failure → ΟΧΙ :durable |
| W-REL-RETRACT | αναίρεση batch-σχέσης → ΜΟΝΟ all-or-nothing |
| W-REG-PIN | registry edit → παλαιό replay ΑΜΕΤΑΒΛΗΤΟ (pinned digest) |
| W-FLOOD | 10⁵ rejects → digests όχι σώματα· 2η διεργασία-συγγραφέας → ρητή άρνηση |
| W-JB-SUB-ID | πλαστό subevent id → corruption παρά το έγκυρο batch hash |
| W-JB-NEST | κενό/nested batch → schema reject |

### Δημιουργού v4 [Β-1..7] — Π7-U.1B
| | |
|---|---|
| **W-SNAPSHOT-TYPES** | work-snapshot με valid_at "2020" ή "2020-03", ή graph_cut χωρίς recorded_through legal-instant → schema reject· snapshot-at καλείται ΜΟΝΟ με (legal-date, legal-instant) — τα types της έδρας |
| **W-SNAPSHOT-FORK** | ίδιο seq σε forked ιστορία (άλλο chain_root) → verifier FAIL στο graph-chain-head check· δηλωμένο root χωρίς recompute → δεν γίνεται πιστευτό |
| **W-UNCERTAINTY-SET** | δύο snapshots με ίδιο πλήθος αλλά ΔΙΑΦΟΡΕΤΙΚΑ αποκλεισμένα provisions → διακριτά uncertainty_set_roots (το count-only θα τα ταύτιζε)· leaf χωρίς kind/uncertainty_id → reject |
| **W-KYA-COISSUERS** | ίδια ΚΥΑ, connector Α θεωρεί «issuing» τον υπουργό Χ, connector Β τον Ψ → ΙΔΙΟ work_id (register+protocol — κανένας authority στο hash)· οι υπογράφοντες ΟΛΟΙ σε sorted issuance facts |
| **W-AUTH-PIN-DUAL** | ίδιο ιδρυτικό γεγονός ως {provision_id, tv_version_hash} ΚΑΙ ως graph-cut pin → η δεύτερη μορφή schema reject (ΜΙΑ μορφή pin)· το cut μόνο ως provenance της επίλυσης |
| **W-MANIFEST-URL** | ίδιο αρχείο σε 2 URLs / με+χωρίς url_hint → ΕΝΑ manifestation_id· URL πεδίο στο manifestation schema → reject |
| **W-MEDIA-STATUS** | αναβάθμιση asserted→verified / αλλαγή detector → manifestation_id ΑΜΕΤΑΒΛΗΤΟ· νέο media-verification record ΜΟΝΟ |
| **W-PNP-SAME-ISSUE** | δύο ΠΝΠ ίδιας ημέρας στο ίδιο ΦΕΚ → διακριτά work_ids (act_ordinal)· ΠΝΠ χωρίς act_ordinal → reject |
| **W-SPEC-SELF-CONTAINED** | μηχανικός έλεγχος του παρόντος αρχείου: καμία κανονιστική αναφορά «όπως v3»/«όπως v2» (grep «όπως v[0-9]» = 0 σε normative θέσεις)· κάθε schema που μνημονεύεται ορίζεται ΜΕΣΑ στο αρχείο |
| **W-JOURNAL-FRAME** | (α) record χωρίς commit marker → typed torn, journaled heal· (β) payload με εσωτερικά newlines/multiline strings → πλήρες frame διαβάζεται σωστά (το newline-κριτήριο θα αποτύγχανε)· (γ) truncation ΜΟΝΟ βάσει newline → ΑΠΑΓΟΡΕΥΜΕΝΗ διαδρομή, δεν υπάρχει στην έδρα· (δ) frame με λάθος sha256 → torn, όχι δεκτό |
