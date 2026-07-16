# LAWMAX — UNIVERSAL SOURCE CONTRACT (Π7-U.1) · `lawmax/legal-source/1` · **v4 — Π7-U.1A IDENTITY, EXPRESSION AND ATOMICITY FREEZE**

**Κατάσταση:** ΠΡΟΤΑΣΗ προς τελική έγκριση («εγκρίνω Π7-U.1» εκκρεμεί).
Π7-U.2 implementation: ΠΑΓΩΜΕΝΟ.
**Αναθεωρήσεις:** v1 → 2 κριτές (REJECTED) → v2 → 9 ευρήματα δημιουργού
[Δ-1..Δ-9] → v3 → **2 ΝΕΟΙ κριτές** (identity/FRBR collision: 3 CRIT +
5 SERIOUS + 3 MINOR + 1 NIT, δείκτες [Κ-x]· journal atomicity/legal-effect:
4 CRIT + 4 SERIOUS + 2 MINOR + 1 NIT, δείκτες [Τ-x]) → **v4 = παρόν**: ΟΛΑ
κλειστά ονομαστικά, με witnesses W-Δ1..9 + W-K1..11 + W-J* (§12).
**Εγκεκριμένη βάση:** `b87f7d8b`. **#4A/B/C: CLOSED & FROZEN** (Πράξη
Έγκρισης 2026-07-16). GAAF-1 + reasoning layers παγωμένα. ΚΑΝΕΝΑ download.

**Θεμελιώδεις αρχές:** (α) ΚΑΝΕΝΑ hardcoded enum — versioned registries με
key-shape/projector ΣΤΗΝ εγγραφή· (β) ταυτότητα ≠ ταξινόμηση [Δ-4/Δ-5]·
(γ) ατομικότητα = δομική ιδιότητα ΕΝΟΣ append ΣΤΟ ΙΔΙΟ journal [Δ-6], με
ΡΗΤΗ journal topology [Τ-C3] — η φράση «ένα journal» σημαίνει: κάθε record
ζει σε ΑΚΡΙΒΩΣ ΕΝΑ δηλωμένο chain-hashed journal, και κάθε συν-γέννηση είτε
χωρά σε ΕΝΑ append είτε έχει ονομαστικό recovery protocol (§0.4)·
(δ) ΜΙΑ οδός ταυτότητας ανά πραγματική κλάση — δομικά [Κ-C1].

---

## 0. Θεμέλια, μετάβαση, journal topology, συν-γεννήσεις

### 0.1 Έδρες που καταναλώνονται ως έχουν

| Έννοια | Έδρα | Χρήση |
|---|---|---|
| Κανονική σειριοποίηση + hash | canonical-representation / spec | κάθε id = canonical-hash· ΟΧΙ booleans [Α-CRIT2] |
| Ταυτότητα πράξης/provision | orchestrator.identity | work ≡ body για Rule-A κλάσεις [Δ-3] |
| Μητρώα ειδών | body-kind-registry, instrument-kind-registry | επέκταση με εγγραφές + **αφαίρεση route-διπλών** (§0.2β) [Κ-C1] |
| Διτεμπορικός γράφος | orchestrator.version-graph | text-mutating γεγονότα· batch = kind του per-body journal |
| Journal πειθαρχία | journal.lisp [0086] | **με τα ΥΠΟΧΡΕΩΤΙΚΑ κλεισίματα §0.5 ΠΡΙΝ από κάθε Π7-U.2 κώδικα** [Τ-C1/C2/S5/S8] |
| Raw→text γέφυρα | extraction/normalization receipts | /2 προσθέτει manifestation_id [Α-S8] |
| Merkle | orchestrator.merkle (RFC-6962) | provision_set_root — leaf encoding §1.2 [Κ-C2] |
| Απόδειξη εξουσίας | authority-proof-bundle/1 (FROZEN) | κατανάλωση μέσω census [Α-S10] |

### 0.2 Μερικές έδρες που διαδέχεται — [0045]

| Υπάρχουσα | Ταξινόμηση + φάση |
|---|---|
| source-profile.lisp (acquired-record, ranks, ιδιωτικό %canonical) | **B → Π7-U.3** |
| document-fetch.lisp (ΦΕΚ fetch) | **B → Π7-U.2** (gr-gazette acquirer) |
| government-source.lisp | **B → Π7-U.3** |
| corpus-provenance.lisp (PROV-O) | **A** — εξαγωγική προβολή, ποτέ πηγή αλήθειας |
| **β) body-kind-registry: `:ya`, `:eu-reg`, `:eu-dir`** [Κ-C1] | **B → Π7-U.2 versioned registry φάση**: αφαιρούνται από τη Rule-A οδό — ΥΑ/ΚΥΑ ⇒ ΜΟΝΟ administrative-act projector (ο εκδότης ταυτοτικός, το protocol_number ΔΕΝ είναι integer)· EU ⇒ ΜΟΝΟ {celex}. Μέχρι τη φάση: οι connectors ΔΕΝ υλοποιούνται, άρα καμία διπλή οδός δεν ασκείται |

### 0.3 Journal topology — ΡΗΤΗ [Τ-C3]

Το version-graph journal είναι **per-body** (γεγονός της έδρας). Receipts/
observations/uncertainties/issuance/relations-χωρίς-regime γεννιούνται ΠΡΙΝ
υπάρξει body (acquire→parse→identify) — ΔΕΝ χωρούν σε per-body journal.
Δηλώνονται ΔΥΟ chain-hashed journals, καθένα με δικό του chain domain:

| Journal | Πεδίο | Kinds |
|---|---|---|
| **version-graph journal** (per-body, υπάρχον) | νομική κατάσταση σώματος | text-mutating, regime, conditions, instrument, graph-side relations*, `:batch` |
| **corpus journal** (ΕΝΑ, νέο — ίδια journal.lisp πειθαρχία, δικό του chain) | κτήση & αταξινόμητη πραγματικότητα | acquisition-receipt, location-observation, uncertainty (+resolution), issuance-fact, proposal-rejected, relation-χωρίς-regime, mode-decision [Τ-S6], `:batch` |

- Το `:batch` ορίζεται ΑΝΑ journal· **cross-journal batch ΑΠΑΓΟΡΕΥΕΤΑΙ**
  (schema reject) — συν-γέννηση που διασχίζει journals μπαίνει στον πίνακα
  §0.4 με recovery protocol (W-J-TOPOLOGY).
- *Relations με regime υπο-γεγονός (annuls, suspends-effect, erga-omnes
  declares-unconstitutional) ζουν στο version-graph journal του σώματος-στόχου,
  σε batch με το regime τους (§6).

### 0.4 Πίνακας συν-γεννήσεων — ΕΞΑΝΤΛΗΤΙΚΟΣ [Τ-C4]

Ό,τι δεν είναι εδώ, δεν υπάρχει ως συν-γέννηση:

| Συν-γέννηση | Μηχανισμός |
|---|---|
| relation + regime event | batch, version-graph journal (§6.1) |
| normative consolidation event + codifies relation | batch, version-graph journal |
| uncertainty + καραντίνα artifact | corpus journal record ΠΡΩΤΑ (η καραντίνα ΕΙΝΑΙ η journaled uncertainty — το store δεν κρατά δική του κατάσταση «καραντίνας»: καραντίνα ≡ ύπαρξη ανοιχτής uncertainty· καμία δεύτερη σημαία, καμία μερικότητα δομικά) |
| work γέννηση + issuance facts | batch, corpus journal (work-record + Ν issuance facts = ΕΝΑ append) |
| expression + manifestation | ΔΕΝ είναι journaled γεγονότα — είναι παράγωγες content-addressed ταυτότητες (υπολογίζονται, δεν «συμβαίνουν»)· δηλωμένο ρητά — κανένα recovery δεν χρειάζεται |
| proposal-rejected + legal-effect-unresolved | batch, corpus journal |
| blob + acquisition receipt | recovery protocol §4.3 (τα δύο stores εδώ είναι αναπόφευκτα: bytes ≠ journal· η μερικότητα ΟΡΑΤΗ με τυπωμένη ετυμηγορία) |

### 0.5 ΥΠΟΧΡΕΩΤΙΚΑ κλεισίματα στην έδρα journal.lisp — ΠΡΙΝ από κάθε Π7-U.2 κώδικα [Τ-C1/C2/S5/S8]

Ευρήματα του κριτή ατομικότητας ΣΤΟ ΥΠΑΡΧΟΝ [0086] — προϋποθέσεις, όχι ευχές:

1. **Torn-tail heal [Τ-C1]:** πριν από κάθε append: αν το αρχείο δεν τελειώνει
   σε newline ⇒ τυπωμένη ετυμηγορία + journaled heal (truncate στο τελευταίο
   πλήρες record) — ποτέ σιωπηλή συγκόλληση torn bytes + νέου record. Ανώτερη
   μορφή: hash-terminated record framing (το torn record δομικά αναγνωρίσιμο).
2. **Compare-and-append [Τ-C2]:** το precondition_root ελέγχεται ΣΤΟ append,
   ΥΠΟ το journal lock: mismatch ⇒ typed `stale-precondition` conflict
   (client/retry κλάση — ΤΙΠΟΤΑ δεν γράφεται)· ΜΟΝΟ τότε το replay δικαιούται
   να θεωρεί stored mismatch = journal-corruption. Κλείνει ΚΑΙ το προϋπάρχον
   race του `%journal!` (chain υπολογισμένο προ-lock, `(ignore last)` στο
   build-fn του chained-append — ο μηχανισμός υπάρχει, θα χρησιμοποιηθεί).
3. **Fsync honesty [Τ-S5]:** το `ignore-errors` γύρω από το fsync ΠΕΘΑΙΝΕΙ:
   αποτυχία fsync ⇒ `wrote nil` ⇒ receipt ΟΧΙ :durable ⇒ οι θεσμικοί
   συγγραφείς αρνούνται id. («id ⟺ durable» του [0086] — στην πράξη, όχι στα
   λόγια.)
4. **Single-writer [Τ-S8]:** ένας δηλωμένος συγγραφέας ανά journal
   (cross-process lease/O_EXCL)· δεύτερη διεργασία ⇒ ρητή άρνηση, όχι fork
   αλυσίδας. Τα proposal-rejected records δεσμεύουν **digest** της πρότασης,
   ΟΧΙ το σώμα (καμία αφραγμάτιστη διόγκωση).
5. **Typed torn verdict [Τ-NIT]:** η ετυμηγορία κακής γραμμής επιστρέφεται
   typed στον καλούντα του replay — όχι μόνο ⚠ στο *error-output*.

---

## 1. Καθολική ταυτότητα — τέσσερα επίπεδα

```
WORK → EXPRESSION (expression/1 sum type) → MANIFESTATION → ITEM (bytes)
```

### 1.1 Work identity — ΜΙΑ οδός ανά κλάση, δομικά [Δ-3, Κ-C1, Κ-S7]

**Κανόνας Α (make-body κλάσεις):** `work identity ≡ body identity` αυτούσιο.
Εκδότες = `lawmax/issuance/1` facts (role-typed, evidence-backed, journaled
στο corpus journal — σε batch με τη γέννηση του work-record §0.4) — ΕΚΤΟΣ
ταυτότητας (W-Δ3). Το πεδίο `"work"` του issuance δέχεται body-id Ή lsw1-id
(tagged: `{"id_type": "body" | "lsw1", "id": ...}`) [Κ-S7].

**Κανόνας Β (λοιπές):**

```
work_id = "lsw1:" + canonical-hash({
  "schema":   "lawmax/work/1",
  "register": <register-id ΤΗΣ εγγραφής του source-class registry — ΤΑΥΤΟΤΙΚΟ:
               προσδιορίζει το ΜΗΤΡΩΟ ΑΡΙΘΜΗΣΗΣ, όχι ταξινόμηση — συμβατό με
               Δ-4· δύο projectors με ίδια key-shapes δεν συγκρούονται ποτέ
               [Κ-S7, W-K7]>,
  ...projector fields})
```

**Invariant ΜΙΑΣ οδού [Κ-C1]:** το source-class registry φορτώνει ΜΟΝΟ αν
κάθε πραγματική κλάση έχει ΑΚΡΙΒΩΣ μία οδό (body-kind δείκτης XOR projector)·
τα `:ya`/`:eu-reg`/`:eu-dir` αφαιρούνται από τη Rule-A οδό (§0.2β): ΥΑ/ΚΥΑ ⇒
ΜΟΝΟ administrative-act projector (πρωτόκολλα δεν είναι integers — το
make-body δεν τα χωρά έτσι κι αλλιώς)· EU ⇒ ΜΟΝΟ {celex} (W-K1).
Επίσης: body-id string ως Rule-B input ⇒ schema reject (W-K7β).

### 1.2 `lawmax/expression/1` — sum type [Δ-1] με κλειστές αμφισημίες [Κ-C2/S5/S6/M9]

```
expression_id = "lse1:" + canonical-hash({"schema","kind",...})

provision-expression:  {"provision_id", "tv_version_hash",
                        "language": <default "el" — ρητό πεδίο, μεταφράσεις
                        εκφράσιμες [Κ-S5β]>}

work-snapshot-expression: {"work" (tagged id §1.1), "language",
   "graph_cut_seq": N,                    # per-body seq — δηλωμένο ρητά
   "valid_at": <typed-partial §5.4>,      # [Κ-C2]: το cut καθηλώνει known,
                                          # ΟΧΙ valid — χωρίς valid_at δεν
                                          # υπάρχει μοναδικό σύνολο
   "provision_set_root": <RFC-6962 root· ΣΥΝΟΛΟ = το ακριβές output της
     ΥΠΑΡΧΟΥΣΑΣ snapshot-at στο prefix-replay του cut με το δηλωμένο
     valid_at/known_at=cut· uncertain provisions ΕΚΤΟΣ συνόλου, με τον
     αποκλεισμό δηλωμένο σε συνοδευτικό πεδίο "excluded_uncertain": N·
     leaf = canonical JSON {"provision_id":...,"tv_version_hash":...} —
     conformance vector υποχρεωτικό [Κ-C2, W-K2]>}

single-document-expression: {"work" (tagged), "language",
   "content_sha256": <sha256(UTF-8(κείμενο κανονικοποιημένο κατά §2 της
     canonical-serialization-spec — Η ΙΔΙΑ normalization των text-versions·
     ρητή επίκληση [Κ-S6, W-K6])>}
```

- `language`: ΚΛΕΙΣΤΟΣ πίνακας ISO 639-1 codes στο schema («el», «en», «fr»,
  «de» v1 — επέκταση με schema εγγραφή)· «ell»/«gre» ⇒ reject [Κ-M9, W-K9].
- **Μονο-διατακτικά works [Κ-S5]:** provision-expression (μέρος) και
  work-snapshot (όλον) είναι ΔΙΑΦΟΡΕΤΙΚΑ FRBR αντικείμενα ακόμη κι όταν
  |provisions|=1 — ΔΕΝ είναι collision. Η ισοδυναμία κειμένου τους είναι
  ΠΑΡΑΓΩΓΙΜΗ (το snapshot root του μονοσυνόλου περιέχει το ίδιο
  tv-version-hash) — ο verifier την ελέγχει, δεν την υποθέτει (W-K5).
- **Rule-B works χωρίς body-kind [Κ-S8]:** ΔΕΝ έχουν provision-ids (η
  provision ταυτότητα απαιτεί legal-body-id — γεγονός της έδρας) ⇒ νόμιμη
  expression ΜΟΝΟ single-document. Provision-δόμηση Rule-B works (π.χ. άρθρα
  ΠΝΠ πριν την κύρωση) = ΔΗΛΩΜΕΝΟ όριο v1 με μελλοντική φάση (§11).

### 1.3 `manifestation_id` [Δ-2, Κ-M10]

```
manifestation_id = "lsm1:" + canonical-hash({
  "schema": "lawmax/manifestation/1",
  "expression_id": <ΥΠΟΧΡΕΩΤΙΚΟ — reject αν λείπει (W-Δ2)>,
  "media_type": <asserted/verified + detection §4.2>,
  "official_variant": <registry>,
  "edition": {"publisher": {"kind": "authority" | "work-self",   # tagged [Κ-M10]
                            "authority_id": <όταν kind=authority>},
              # work-self = ο εκδοτικός φορέας ταυτίζεται με τον εκδότη του
              # work (π.χ. et.gr για ΦΕΚ) — δεσμευμένο keyword, όχι string
              "edition_facts": {"print_run": string?, "url_hint": string?,
                                "issue_label": string?}}})  # ΚΛΕΙΣΤΗ απαρίθμηση —
                                                            # άγνωστο πεδίο ⇒ reject (W-K10)
```

### 1.4 Projectors — δεσμευτικά v1 [Ν-CRIT1..5, Δ-4, Κ-C1/S8]

- `judgment`: {court: authority_id, registry_number: int, year: int}
  (+formation per registry [Ν-CRIT5])· judgment/court-order/court-minutes =
  ταυτοτικό series-field (διαφορετικά μητρώα αρίθμησης).
- `emergency-legislative-act` (ΠΝΠ): {promulgation_date: date,
  **gazette_ref: {"id_type": "lsw1", "id": <work_id του gazette-issue>}** —
  typed ref, ΟΧΙ ελεύθερο string [Κ-S8, W-K8]}· κύρωση: :ratification event.
- `eu-*`: {celex} για ΟΛΕΣ τις eu κλάσεις [Δ-4, W-Δ4]· register διακρίνει
  το ΜΗΤΡΩΟ (eur-lex), όχι την κλάση.
- `international-treaty`: {parties: sorted-set, conclusion_date,
  authentic_title_sha256} [Ν-S9].
- `administrative-act`/`circular` (και ΟΛΕΣ οι ΥΑ/ΚΥΑ [Κ-C1]):
  {issuing_authority_id, protocol_number: string, protocol_date,
  registry_series} — ο εκδότης ταυτοτικός ΕΔΩ (δικό του πρωτόκολλο)·
  «διόρθωση απόδοσης» = ΑΛΛΗ πράξη (δηλωμένη σημασιολογία).
- `gazette-issue`: {gazette_authority_id, series, issue: int, year: int}.
- `code`: Κανόνας Α μέσω :kodikas· **number ΥΠΟΧΡΕΩΤΙΚΟ στην έδρα** — το
  make-body σήμερα δέχεται number NIL για κάθε kind πλην :syntagma: ο
  φρουρός κατεβαίνει ΣΤΗΝ έδρα (Π7-U.2 προ-παραδοτέο) [Κ-M11, W-K11]· το
  number του κώδικα = της κυρωτικής πράξης, δηλωμένο ΣΤΗΝ εγγραφή :kodikas.

---

## 2. Τυπολογίες ως registries

### 2.1 Source-class registry — με invariant ΜΙΑΣ οδού [Κ-C1]

Ανά εγγραφή ΥΠΟΧΡΕΩΤΙΚΑ: `class, register-id [Κ-S7], work-category (§3.1),
identity-route (body-kind XOR projector — gated load [Κ-C1]),
classification-fields, required-evidence, key-shape, mutating-capable`.
Άγνωστη κλάση ⇒ unclassified-source + καραντίνα (≡ ανοιχτή uncertainty §0.4).
v1 περιεχόμενο: όπως v3 + ρητό όριο: Συντακτικές Πράξεις (1944/1967/
μεταπολιτευτικές) ΕΚΤΟΣ v1 — πέφτουν τίμια σε unclassified — δηλωμένη
μελλοντική εγγραφή [Κ-NIT12].

### 2.2 Authority registry — collision-free [Δ-5, Κ-C3/S4]

```
"authority_id": "auth1:" + canonical-hash({
   "jurisdiction": ...,
   "founding_locator": {"locator_type": "provision-id" | "span" | "pre-corpus",  # tagged
                        "value": ...,                                            # [Κ-S4]
                        "version_pin": <tv-version-hash ή graph-cut pin της
                          ιδρυτικής διάταξης ΟΤΑΝ locator_type=provision-id —
                          επανίδρυση από νέα έκδοση της ΙΔΙΑΣ διάταξης
                          (αναθεώρηση Συντάγματος: το gr/syntagma είναι
                          άχρονο body!) ⇒ ΔΙΑΚΡΙΤΟ id [Κ-C3, W-K3]>},
   "entity_key": <ΚΑΝΟΝΑΣ ΠΡΟΤΕΡΑΙΟΤΗΤΑΣ [Κ-S4]: ordinal ΠΑΝΤΑ όταν η
                  ιδρυτική διάταξη αριθμεί/απαριθμεί· κανονική θεσμική
                  ονομασία ΜΟΝΟ όταν δεν υπάρχει αρίθμηση — μη-κανονική
                  επιλογή = reject (W-K4)>})
"kind": versioned assertion ΕΚΤΟΣ hash [Δ-5, W-Δ5β]
```

lineage/names/numbering/existence/genesis όπως v3 [Ν-S10, Α-S7]. Δέσμευση
μέσω census [Α-S10].

### 2.3 Jurisdiction registry — όπως v3 [Ν-M12].

---

## 3. Οντολογία — disjoint tagged sum [Δ-7], όπως v3 (publication-work/
normative-act/adjudicative-work/administrative-act/interpretive-instrument/
treaty-work· επίπεδα ≠ κατηγορίες· published-in σχέση· type guards W-Δ7·
opinion-nsk :acceptance [Ν-S8]).

---

## 4. Raw artifact [Δ-9] — όπως v3 (ΜΟΝΟ digest_algorithm/digest/byte_length·
detection στο manifestation §4.2· recovery §4.3 blob↔receipt με ορατή
μερικότητα) — ΣΥΝ:
- Η «καραντίνα» ΔΕΝ είναι κατάσταση του store: καραντίνα ≡ ανοιχτή journaled
  uncertainty στο corpus journal (§0.4) — η δεύτερη σημαία και η cross-store
  μερικότητά της ΔΕΝ υπάρχουν δομικά [Τ-C4].

---

## 5. Acquisition/locations/γέφυρες — όπως v3 [Α-CRIT2/M12/M13/S8/S9]
(receipts integers 0/1· tsr digest· observations journaled στο CORPUS journal
§0.3· extraction-receipt/2· typed-partial dates ISO reduced precision).

---

## 6. Journal semantics — batch, relations, legal-effect

### 6.1 `lawmax/journal-batch/1` [Δ-6] — με κλειστούς περιορισμούς [Τ-C2/M9/M10]

```
journal kind :batch (ορισμένο ΑΝΑ journal §0.3 — cross-journal ΑΠΑΓΟΡΕΥΕΤΑΙ)
{"schema": "lawmax/journal-batch/1", "batch_id": "jb1:...",
 "precondition_root": <chain head — ελέγχεται ΣΤΟ append, ΥΠΟ το lock:
    compare-and-append §0.5.2· mismatch ⇒ typed stale-precondition,
    ΤΙΠΟΤΑ δεν γράφεται [Τ-C2, W-JB-RACE]>,
 "ordered_subevents": [...]}
```

- ΕΝΑ seq, ΕΝΑ payload hash, ΜΙΑ chain transition· κανένα `:up-to-seq` cut
  δεν πέφτει ΜΕΣΑ σε batch (δηλωμένο ρητά) [Τ-M9].
- **Subevent πειθαρχία [Τ-M9, W-JB-SUB-ID]:** κάθε subevent φέρει το πλήρες
  semantic record του (με δικό του record-id)· το replay τρέχει τους
  semantic ελέγχους ΑΝΑ subevent (πλαστό subevent δεν κρύβεται πίσω από
  έγκυρο batch hash)· κατανάλωση από version-at/TILING = ως διαδοχικές
  γραμμές στη θέση του batch· ενδο-batch αναφορές ΜΟΝΟ προς προηγούμενο
  subevent· κοινό `:at` = δηλωμένο όφελος (μία πράξη, μία στιγμή).
- **Περιορισμοί [Τ-M10, W-JB-NEST]:** `ordered_subevents` ≥ 1· subevent
  kind ≠ :batch — schema reject.
- All-or-nothing replay· σημασιολογικά άκυρο subevent ⇒ ΟΛΟ το batch
  απορρίπτεται (W-Δ6).

### 6.2 Consolidation — evidence-backed mode + ΔΙΠΛΟΣ φρουρός [Δ-8, Τ-S6]

- normative ⇒ γεγονός γράφου σε batch με codifies· derived ⇒
  work-snapshot-expression, ΜΗΔΕΝ graph mutation· χωρίς evidence ⇒
  legal-effect-unresolved (W-Δ8).
- **Mode-decision = journaled record [Τ-S6]** στο corpus journal:
  {evidence-pin, decider: creator, mode} — ο κριτής του mode είναι ο
  δημιουργός (κανένα LLM, ο pure parser ΔΕΝ αποφασίζει), η απόφαση έχει
  μόνιμη έδρα — όχι σιωπηλό όρισμα.
- **Αντίστροφος φρουρός [Τ-S6, W-Δ8β]:** derived submission για work του
  οποίου η πηγή φέρει κυρωτική/εξουσιοδοτική citation ήδη στο corpus ⇒
  ΥΠΟΧΡΕΩΤΙΚΟ legal-effect-unresolved — η σιωπηλή απώλεια κανονιστικού
  αποτελέσματος (normative-ως-derived) ΔΕΝ περνά αθόρυβα.

### 6.3 Relations [Α-CRIT3, Ν-S7] — ΣΥΝ retract & pinning [Τ-S7]

- Kinds registry όπως v3 (interprets, annuls*, declares-unconstitutional
  {erga-omnes|incidenter}*, suspends-effect*, authorizes-delegation,
  resolves-pilot-question, precedent-follows/distinguishes, codifies,
  published-in). * = batch με regime υπο-γεγονός.
- **Relation-retract [Τ-S7]:** συμμετρικό με τη γέννηση — retract σχέσης που
  γεννήθηκε σε batch γίνεται ΜΟΝΟ ως batch (relation-retract + regime-retract
  μαζί — τα υπάρχοντα retract-regime-edge!/retract-condition-event! δείχνουν
  το πρότυπο)· μερική αναίρεση δομικά αδύνατη (W-REL-RETRACT).
- **Registry pinning [Τ-S7]:** η υποχρέωση «relation ⇒ batch» κρίνεται στο
  replay ΚΑΤΑ το registry digest που ΔΕΣΜΕΥΤΗΚΕ στο record (πεδίο
  `relation_registry_digest` στο relation record)· επεξεργασία registry ΔΕΝ
  αλλάζει αναδρομικά τη νομιμότητα γραμμένων journals (W-REG-PIN).

---

## 7. Connectors [Α-CRIT1/S6] — acquirer/parser όπως v3, ΣΥΝ:
- **Write authority [Τ-S8]:** ΕΝΑΣ δηλωμένος συγγραφέας ανά journal
  (admission gate)· connectors παράγουν ΜΟΝΟ προτάσεις — ΠΟΤΕ δεν αγγίζουν
  journal· proposal-rejected δεσμεύει digest, όχι σώμα (W-FLOOD).
- Κοινή σουίτα: golden + αντιπαλικά vectors ⊇ ΟΛΟΙ οι witnesses §12.

## 8. Typed uncertainty — όπως v3 (13 kinds [Ν-S11, Δ-8])· καραντίνα ≡
ανοιχτή uncertainty (§0.4)· επίλυση journaled.

## 9. Καμία ΦΕΚ-ειδική δομή — όπως v3 [Ν-NIT15, Α-M11] (ρητό gate πεδίο,
δηλωμένα υπόλοιπα :fek-date/:fek-ref με φάση μετονομασίας).

---

## 10. Κριτήρια αποδοχής Π7-U.1

1. Ρητή τελική έγκριση δημιουργού. Ιστορικό κριτών: 2×v1 (κλειστά v2) + 9
   δημιουργού (κλειστά v3) + 2×v3 identity/atomicity (κλειστά v4 — παρόν).
2. Registry: identity-route XOR invariant + projector/classification/
   evidence/key-shape — gated load.
3. Journal topology ρητή (§0.3)· πίνακας συν-γεννήσεων εξαντλητικός (§0.4)·
   έδρα-κλεισίματα §0.5 = BLOCKING προ-παραδοτέα Π7-U.2.
4. Ο όρος §9 μηχανικά επαληθεύσιμος.
5. **Π7-U.2 ΠΑΓΩΜΕΝΟ** — παραδοτέα: §0.5 journal fixes (ΠΡΩΤΑ), typed-partial
   canonical vectors, extraction-receipt/2, journal-batch replay + corpus
   journal, registry route-φάση (§0.2β), make-body number guard [Κ-M11],
   authority gate, proposal schemas, conformance vectors (⊇ §12), gr-gazette
   acquirer+parser.

## 11. Δηλωμένα όρια v1

- Πολυγλωσσία: ισοδυναμία expressions μεταξύ γλωσσών = μελλοντική φάση.
- Provision-δόμηση Rule-B works (ΠΝΠ άρθρα προ κύρωσης) = μελλοντική φάση
  [Κ-S8] — μέχρι τότε single-document ΜΟΝΟ.
- Συντακτικές Πράξεις: εκτός v1, τίμια unclassified [Κ-NIT12].
- Authority registry: genesis + μετρήσιμη πληρότητα.
- Blob↔receipt: η ΜΟΝΗ αναπόφευκτη δι-store σχέση — ορατή μερικότητα §4.3.
- Redaction πολιτική = απόφαση δημιουργού.

---

## 12. ΟΝΟΜΑΣΤΙΚΟΙ NEGATIVE WITNESSES — υποχρεωτικά vectors Π7-U.2

**W-Δ1..W-Δ9** (ευρήματα δημιουργού — όπως v3, με W-Δ8 διευρυμένο):
W-Δ1 δύο cuts ⇒ διαφορετικά manifestation_ids· W-Δ2 manifestation χωρίς
expression_id ⇒ reject· W-Δ3 διόρθωση συνυπογραφόντων ⇒ ταυτότητα αμετάβλητη·
W-Δ4 CELEX αναταξινόμηση ⇒ id αμετάβλητο· W-Δ5/β ίδρυση Ν αρχών / kind
διόρθωση· W-Δ6 ορφανό μισό ⇒ replay FAIL, άκυρο subevent ⇒ όλο το batch
απορρίπτεται· W-Δ7 λάθος work-category ⇒ σφάλμα γέννησης· W-Δ8 editorial-ως-
normative ⇒ reject, **W-Δ8β normative-ως-derived ⇒ ΟΧΙ σιωπηλή αποδοχή
[Τ-S6]**· W-Δ9α-δ artifact/media/recovery.

**W-K1..W-K11** (identity κριτής):
K1 ίδια ΚΥΑ από 2 connectors ⇒ duplicate-route reject· ΥΑ ως make-body ⇒
αδύνατο (οδός αφαιρεμένη)· K2 ίδιο cut, 2 valid-at ⇒ 2 διακριτές expressions
(με δηλωμένο valid_at)· K3 ίδρυση από v1 και v2 της ίδιας συνταγματικής
διάταξης ⇒ 2 authority_ids· K4 δύο νόμιμα entity_keys ⇒ το μη-κανονικό
reject· locator tag: citation-string ≠ provision-id string· K5 μονο-
διατακτικό work: equivalence παραγώγιμη από snapshot root — απουσία ⇒ FAIL·
K6 CRLF/LF judgment ⇒ ΕΝΑ expression_id· K7 δύο κλάσεις ίδια projector
πεδία ⇒ διακριτά ids (register)· body-id ως Rule-B input ⇒ reject· K8 ΠΝΠ
20.3.2020 από 2 connectors ⇒ ΜΙΑ τριάδα byte-ίδια· K9 «ell» ⇒ reject·
K10 άγνωστο edition_facts πεδίο ⇒ reject· K11 make-body :kodikas χωρίς
number ⇒ σφάλμα ΣΤΗΝ έδρα.

**W-J*** (atomicity κριτής):
W-JB-TORN torn tail + νέο append ⇒ όχι συγκόλληση, τυπωμένη ετυμηγορία,
replay πράσινο στο πρόθεμα· W-JB-RACE δύο ταυτόχρονα appends ίδιου
precondition ⇒ ακριβώς ένα γράφεται, το άλλο typed stale-precondition·
W-J-TOPOLOGY receipt χωρίς body ⇒ corpus journal, όχι «κάπου»· cross-journal
batch ⇒ reject· W-COBIRTH-SWEEP crash injection σε ΚΑΘΕ ζεύγος του §0.4 ⇒
μερικότητα ορατή ή δομικά αδύνατη — ποτέ σιωπηλό μισό· W-FSYNC-LIE mocked
fsync failure ⇒ ΟΧΙ :durable· W-REL-RETRACT αναίρεση batch-σχέσης ΜΟΝΟ
all-or-nothing· W-REG-PIN registry edit ⇒ παλαιό replay ΑΜΕΤΑΒΛΗΤΟ·
W-FLOOD 10⁵ rejects ⇒ digests όχι σώματα· 2η διεργασία-συγγραφέας ⇒ ρητή
άρνηση· W-JB-SUB-ID πλαστό subevent id ⇒ corruption παρά το έγκυρο batch
hash· W-JB-NEST κενό/nested batch ⇒ schema reject.
