# LAWMAX — UNIVERSAL SOURCE CONTRACT (Π7-U.1) · `lawmax/legal-source/1` · **v3 — Π7-U.1A IDENTITY, EXPRESSION AND ATOMICITY FREEZE**

**Κατάσταση:** ΠΡΟΤΑΣΗ προς τελική έγκριση («εγκρίνω Π7-U.1» εκκρεμεί).
Π7-U.2 implementation: ΠΑΓΩΜΕΝΟ μέχρι την έγκριση.
**Αναθεωρήσεις:** v1 → 2 κριτές (REJECTED) → v2 (ΙΣΧΥΡΟ DESIGN CANDIDATE,
ετυμηγορία δημιουργού) → **v3 = Π7-U.1A**: κλείσιμο των 9 ευρημάτων δημιουργού
[Δ-1..Δ-9], ΚΑΘΕΝΑ με ονομαστικό negative witness (W-Δ1..W-Δ9, §12) —
υποχρεωτικά αντιπαλικά conformance vectors του Π7-U.2. Οι δείκτες [Ν-x]/[Α-x]
των 2 πρώτων κριτών διατηρούνται όπου τα κλεισίματά τους επιζούν στο v3.
**Εγκεκριμένη βάση:** `b87f7d8b`. **#4A/B/C: CLOSED & FROZEN** (Πράξη Έγκρισης
δημιουργού 2026-07-16 — καμία μεταβολή proof protocol χωρίς νέα versioned
φάση). GAAF-1 + reasoning layers παγωμένα. ΚΑΝΕΝΑ download.

**Θεμελιώδεις αρχές:** (α) ΚΑΝΕΝΑ hardcoded enum — versioned data registries
με το key-shape ΣΤΗΝ εγγραφή· (β) **η ταυτότητα διαχωρίζεται δομικά από την
ταξινόμηση** [Δ-4/Δ-5]: ό,τι μπορεί να διορθωθεί αργότερα (class, kind,
authority attribution) ΔΕΝ συμμετέχει ποτέ σε identity hash· (γ) ΕΝΑ journal,
ατομικότητα ως δομική ιδιότητα ΕΝΟΣ append [Δ-6].

---

## 0. Θεμέλια και ΠΙΝΑΚΑΣ ΜΕΤΑΒΑΣΗΣ [Α-CRIT4]

### 0.1 Έδρες που καταναλώνονται ως έχουν

| Έννοια | Έδρα | Χρήση |
|---|---|---|
| Κανονική σειριοποίηση + hash | `canonical-representation` / spec | κάθε id = canonical-hash· ΟΧΙ booleans σε hash-φέροντα [Α-CRIT2] |
| Ταυτότητα πράξης/provision | `orchestrator.identity` (make-body, make-provision-id) | work identity ≡ body identity για τις make-body κλάσεις [Δ-3] |
| Μητρώα ειδών | body-kind-registry, instrument-kind-registry | επεκτείνονται με εγγραφές — δεν αντιγράφονται |
| Διτεμπορικός γράφος | `orchestrator.version-graph` (journal, admit-edge!, TILING) | text-mutating ⇒ ΜΟΝΟ γεγονότα γράφου· journal-batch/1 = ΝΕΟ kind ΤΟΥ ΙΔΙΟΥ journal [Δ-6] |
| Raw→text γέφυρα | extraction/normalization receipts (#4B) | Η ΜΟΝΗ γέφυρα· /2 προσθέτει manifestation_id [Α-S8] |
| Merkle | orchestrator.merkle (RFC-6962) | provision_set_root του work-snapshot-expression [Δ-1] |
| Απόδειξη εξουσίας | authority-proof-bundle/1 (CLOSED & FROZEN) | κατανάλωση μέσω census ΜΟΝΟ [Α-S10] |

### 0.2 Μερικές έδρες που διαδέχεται — [0045]

| Υπάρχουσα | Επικαλύπτει | Ταξινόμηση + φάση θανάτου |
|---|---|---|
| source-profile.lisp (acquired-record, channels/ranks, ιδιωτικό %canonical) | acquisition receipt, τυπολογία, 2η κανονικοποίηση | **B → Π7-U.3**: μετανάστευση σε receipts· %canonical πεθαίνει· ranks → authority registry δεδομένα |
| document-fetch.lisp (fek-blob-url κ.λπ.) | acquisition + location με ΦΕΚ σημασιολογία | **B → Π7-U.2**: ξαναγράφεται ως gr-gazette acquirer· patterns → δεδομένα |
| government-source.lisp | 2η τυπολογία πηγών | **B → Π7-U.3**: πηγές → registry εγγραφές |
| corpus-provenance.lisp (PROV-O) | 2ο provenance λεξιλόγιο | **A**: ΕΞΑΓΩΓΙΚΗ προβολή της αλυσίδας receipts — ποτέ πηγή αλήθειας· mapping Π7-U.3 |

---

## 1. Καθολική ταυτότητα — τέσσερα επίπεδα, ταυτότητα ≠ ταξινόμηση

```
WORK          νομική/εκδοτική οντότητα όπως εκδόθηκε
 └─ EXPRESSION  expression/1 sum type [Δ-1] — χρονική/γλωσσική εκδοχή κειμένου
     └─ MANIFESTATION μορφότυπος ΣΥΓΚΕΚΡΙΜΕΝΗΣ expression [Δ-2]
         └─ ITEM     bytes (raw artifact §4· ταυτότητα = digest) [Δ-9]
```

### 1.1 Work identity — ΔΥΟ κανόνες, ΚΑΜΙΑ δεύτερη ταυτότητα [Δ-3]

**Κανόνας Α — κλάσεις που καλύπτει το make-body:**

```
work identity ≡ body identity      (το body-id ΕΙΝΑΙ το work id — αυτούσιο,
                                    κανένα νέο hash, κανένα wrapper prefix)
```

Οι εκδότες/συνυπογράφοντες ΔΕΝ συμμετέχουν στην ταυτότητα: καταγράφονται ως
**issuance facts** — `lawmax/issuance/1`, role-typed & evidence-backed,
journaled, διορθώσιμα με νέο evidence ΧΩΡΙΣ μεταβολή ταυτότητας [Δ-3, W-Δ3]:

```
{"schema": "lawmax/issuance/1", "work": <body-id>,
 "role": <registry: issuer | co-signer | countersigner | promulgator>,
 "authority_id": ..., "evidence": <provision-pin ή gazette span>,
 "recorded_at": d}
```

**Κανόνας Β — λοιπές κλάσεις:** το work_id υπολογίζεται ΑΠΟΚΛΕΙΣΤΙΚΑ από τον
**identity-projector** της εγγραφής του registry (§2.1, [Δ-4]) — ποτέ από
καθολικό τύπο. Κανένα classification field (source_class, kind, authority
attribution) δεν συμμετέχει σε ΚΑΝΕΝΑ identity hash — εκτός αν ο projector
μιας κλάσης το δηλώνει ΡΗΤΑ ταυτοτικό με δηλωμένη σημασιολογία (§1.4
administrative-act: το πρωτόκολλο είναι ΤΟΥ εκδότη).

### 1.2 `lawmax/expression/1` — ρητό sum type [Δ-1]

```
expression_id = "lse1:" + canonical-hash({"schema":"lawmax/expression/1",
                                          "kind": ..., ...kind-specific})
kind ∈ (ΚΛΕΙΣΤΟ ΣΤΟ SCHEMA — sum type, όχι registry: η οντολογία επιπέδων
        είναι δομή του contract, όχι επεκτάσιμα δεδομένα):

  provision-expression:      {"provision_id", "tv_version_hash"}
     — η ΥΠΑΡΧΟΥΣΑ ταυτότητα έκδοσης διάταξης, αυτούσια. Το tv-version-hash
       είναι per-provision (το text-version φέρει tv-provision-id) — ΔΕΝ
       εκπροσωπεί ολόκληρο work [Δ-1].

  work-snapshot-expression:  {"work", "language",
                              "graph_cut_seq": N,
                              "provision_set_root": <RFC-6962 root επί του
                                ΤΑΞΙΝΟΜΗΜΕΝΟΥ συνόλου ζευγών (provision-id,
                                tv-version-hash) στο cut>}
     — ενοποιημένος νόμος/κώδικας σε συγκεκριμένο cut: δεσμεύει graph cut ΚΑΙ
       Merkle root ΟΛΩΝ των provision versions — όχι ένα tv-version-hash.

  single-document-expression: {"work", "language", "content_sha256"}
     — works με ενιαίο αδιαίρετο κείμενο (judgment, gazette-issue, authentic
       treaty text).
```

### 1.3 `manifestation_id` — δεσμεύει ΥΠΟΧΡΕΩΤΙΚΑ expression [Δ-2]

```
manifestation_id = "lsm1:" + canonical-hash({
  "schema": "lawmax/manifestation/1",
  "expression_id": <ΥΠΟΧΡΕΩΤΙΚΟ — schema reject αν λείπει (W-Δ2)>,
  "media_type": <asserted/verified, με detection evidence §4.2 [Δ-9]>,
  "official_variant": <registry: as-published | corrigendum-applied |
                       consolidated-official>,
  "edition": {"publisher": authority_id | "self", "edition_facts": <closed>}})
```

Δύο διαφορετικά cuts του ίδιου work ⇒ διαφορετικά expression_ids ⇒
διαφορετικά manifestation_ids — η σύγκρουση του v2 αδύνατη δομικά (W-Δ1).
Language: ζει ΣΤΗΝ expression (γλωσσική εκδοχή = FRBR expression επίπεδο).

### 1.4 Projectors — ΜΕΣΑ στο registry [Ν-CRIT1, Δ-4]

Δεσμευτικά v1 περιεχόμενα (πλήρης απαρίθμηση ΣΤΟ registry):
- `judgment`: projector {court: authority_id, registry_number, year}
  (+formation ΜΟΝΟ όταν η εγγραφή δικαστηρίου δηλώνει numbering:
  per-formation, keyword από το κλειστό σύνολο formations της [Ν-CRIT5])·
  sub-classes judgment/court-order/court-minutes = ΤΑΥΤΟΤΙΚΟ series-field
  του projector (διαφορετικά μητρώα αρίθμησης), ρητά δηλωμένο.
- `emergency-legislative-act` (ΠΝΠ): projector {promulgation_date,
  gazette_ref} [Ν-CRIT3]· κύρωση μέσω ΥΠΑΡΧΟΝΤΟΣ :ratification event·
  μη κύρωση ⇒ :expire regime γεγονός με evidence την προθεσμία.
- `eu-*`: projector {celex} — ΓΙΑ ΟΛΕΣ τις eu κλάσεις· η κλάση είναι
  classification field: αναταξινόμηση δεν αγγίζει ταυτότητα [Δ-4, W-Δ4].
- `international-treaty`: projector {parties: sorted-set, conclusion_date,
  authentic_title_sha256}· depositary registration = evidence, όχι κλειδί [Ν-S9].
- `administrative-act`/`circular`: projector {issuing_authority_id,
  protocol_number, protocol_date, registry_series} [Ν-M13] — εδώ ο εκδότης
  ΕΙΝΑΙ ρητά ταυτοτικός (το πρωτόκολλο είναι δικό του μητρώο)· «διόρθωση
  απόδοσης» σημαίνει ΑΛΛΗ πράξη — δηλωμένη σημασιολογία, όχι εξαίρεση.
- `gazette-issue`: projector {gazette_authority_id, series, issue, year}.
- `code` (ΑΚ, ΚΠολΔ): Κανόνας Α μέσω :kodikas [Ν-S6]· ratifies/codifies §6.

---

## 2. Τυπολογίες ως registries — identity/classification ΔΙΑΧΩΡΙΣΜΕΝΑ [Δ-4]

### 2.1 Source-class registry

`deployment/data/source-class-registry.sexp` — ανά εγγραφή, ΥΠΟΧΡΕΩΤΙΚΑ:

```
class                  — όνομα
work-category          — δείκτης στο tagged sum §3.1 (ΕΝΑ) [Δ-7]
identity-projector     — ΠΟΙΑ πεδία μπαίνουν στο work_id hash (ή body-kind
                         δείκτης ⇒ Κανόνας Α §1.1) [Δ-4]
classification-fields  — μεταβλητά assertions (ΠΟΤΕ στο hash) [Δ-4]
required-evidence      — τι απόδειξη απαιτεί η γέννηση εγγραφής
key-shape              — τύποι πεδίων projector (gated load [Ν-CRIT1])
mutating-capable       — αν πράξεις της κλάσης φέρουν text-mutating γεγονότα
```

Εγγραφή χωρίς οποιοδήποτε από αυτά ΔΕΝ φορτώνει. Άγνωστη κλάση ⇒
`unclassified-source` uncertainty + καραντίνα. v1 περιεχόμενο: όλα τα
body-kinds + emergency-legislative-act, ministerial-decision,
joint-ministerial-decision, administrative-act, gazette-issue, judgment,
court-order, court-minutes, eu-treaty, eu-regulation, eu-directive,
eu-decision, eu-judgment, international-treaty, interpretive-circular,
opinion-nsk, parliament-standing-orders, independent-authority-decision.

### 2.2 Authority registry — collision-free, kind ΕΚΤΟΣ hash [Δ-5]

```
{"schema": "lawmax/authority/1",
 "authority_id": "auth1:" + canonical-hash({
    "jurisdiction":     <registry §2.3>,
    "founding_locator": <provision-id ΤΗΣ ιδρυτικής διάταξης | ακριβές
                         source span | pre-corpus typed citation [Ν-S10]>,
    "entity_key":       <ordinal εντός της ιδρυτικής διάταξης | κανονική
                         θεσμική ονομασία κατά την ίδρυση>}),
 "kind": <VERSIONED ASSERTION — classification, ΕΚΤΟΣ ταυτότητας [Δ-5]:
          parliament | president | minister-council | ministry | minister |
          court | prosecutor | independent-authority | central-bank |
          municipality | region | eu-institution | international-org>,
 "names": [...evidence-backed...],
 "lineage": [renamed-from | merged-from | split-from | abolished |
             re-established-as | competence-transferred-to [Ν-S10]],
 "numbering": <courts: unified | per-formation + formations closed set>,
 "existence": {...}}
```

- Μία πράξη που ιδρύει Ν αρχές ⇒ Ν διακριτά founding_locators/entity_keys ⇒
  Ν διακριτά ids — σύγκρουση αδύνατη δομικά (W-Δ5).
- Διόρθωση kind = νέα έκδοση assertion, ταυτότητα ΑΜΕΤΑΒΛΗΤΗ (W-Δ5β).
- Genesis ακολουθία [Α-S7]: Σύνταγμα ⇒ constitutional-basis αρχές (Βουλή,
  ΠτΔ, ΣτΕ, ΕλΣυν· ΑΠ: pre-corpus-founding 1834) ⇒ αναδρομικά
  evidence-backed· journaled — όχι σιωπηλό seeding.
- Δέσμευση ΜΕΣΩ CENSUS — ΚΑΜΙΑ αλλαγή στο frozen authority-statement [Α-S10].

### 2.3 Jurisdiction registry [Ν-M12]: εγγραφές gr, eu, int + ρητές ανά
περιφέρεια/δήμο όταν χρειαστούν. Νέα δικαιοδοσία = εγγραφή με evidence.

---

## 3. Οντολογία — disjoint tagged sum· τα επίπεδα ΔΕΝ είναι κατηγορίες [Δ-7]

### 3.1 `source-work` — κλειστό tagged sum (δομή contract, ΟΧΙ registry)

```
source-work
├─ publication-work        (gazette-issue — εκδοτικό τεκμήριο, ΟΧΙ legal act)
├─ normative-act           (νόμοι, ΠΔ, ΥΑ/ΚΥΑ, ΠΝΠ, κώδικες, κανονισμοί)
├─ adjudicative-work       (judgments, βουλεύματα, πρακτικά)
├─ administrative-act      (ατομικές/κανονιστικές διοικητικές πράξεις)
├─ interpretive-instrument (εγκύκλιοι, γνωμοδοτήσεις ΝΣΚ)
└─ treaty-work             (διεθνείς/ενωσιακές συνθήκες)
```

- Κάθε source-class δηλώνει work-category — ΕΝΑ. Type guard δομικός: σχέση ή
  γεγονός με λάθος category άκρου = σφάλμα γέννησης record (W-Δ7).
- **provision, expression, manifestation, artifact = ΕΠΙΠΕΔΑ της ιεραρχίας
  §1, ΟΧΙ κατηγορίες work** — δεν εμφανίζονται στο sum type. Judgment/
  interpretation δεν είναι «ισότιμοι τύποι δίπλα στο work»: είναι
  work-categories του ΙΔΙΟΥ sum [Δ-7].
- Ένα ΦΕΚ (publication-work) ΠΕΡΙΕΧΕΙ normative-acts: σχέση `published-in`
  (§6.3) — όχι υπαγωγή τύπων.
- opinion-nsk δεσμευτικότητα: :acceptance instrument event [Ν-S8].

---

## 4. Raw artifact — ΜΟΝΟ εγγενή πεδία + recovery protocol [Δ-9]

### 4.1 `lawmax/raw-artifact/1`

```
{"schema": "lawmax/raw-artifact/1",
 "digest_algorithm": "sha256",
 "digest": <hex>,
 "byte_length": N}
```

- ΚΑΝΕΝΑ media_type — μη εγγενές των bytes (W-Δ9α: πεδίο ⇒ schema reject).
  Observed content-type ⇒ acquisition receipt (§5.1)· asserted/verified media
  type + detection evidence ⇒ manifestation (§4.2).
- ΚΑΝΕΝΑΣ δείκτης receipts [Α-S5]: φορά receipt→artifact, many-to-one·
  ίδια bytes από Ν λήψεις = ΕΝΑ record (W-Δ9β).
- Append-only, content-addressed, read-back πριν από κάθε δείκτη [0086].
- Το raw επιζεί για πάντα — και επί αποτυχίας parsing (καραντίνα + §8).

### 4.2 Media detection (στο manifestation [Δ-9])

`"media_detection": {"method": registry(magic-bytes | declared-only |
validated-parse), "observed_content_types": [...από τα receipts...],
"detector_manifest_sha256": ...}` — απόκλιση observed↔detected = τυπωμένο
γεγονός, ποτέ σιωπηλή επιλογή.

### 4.3 Blob↔receipt recovery protocol [Δ-9]

Σειρά εγγραφής ΠΑΝΤΑ: (1) blob στο content-addressed store + fsync +
read-back digest· (2) acquisition receipt ως journaled record. Recovery:
- **Blob χωρίς receipt** = ορφανό ⇒ ΚΑΡΑΝΤΙΝΑ (αόρατο στο σύστημα)·
  επανυιοθέτηση ΜΟΝΟ με νέο receipt — ποτέ σιωπηλή υιοθεσία (W-Δ9γ).
- **Receipt χωρίς blob** = ΣΚΛΗΡΟ ΣΦΑΛΜΑ κλάσης journal-corruption — το
  receipt υπόσχεται bytes που λείπουν· τίποτα δεν συνεχίζει σιωπηλά (W-Δ9δ).
- Admission invariant: artifact «υπάρχει» ΜΟΝΟ ως ζεύγος (blob, ≥1 receipt)·
  η μερικότητα είναι ΟΡΑΤΗ κατάσταση με τυπωμένη ετυμηγορία — καμία
  cross-store συναλλαγή δεν επικαλείται πουθενά.

---

## 5. Acquisition, locations, γέφυρες

### 5.1 `lawmax/acquisition-receipt/1` [Α-CRIT2, Δ-9]

```
{"schema": "lawmax/acquisition-receipt/1",
 "receipt_id": "acq1:" + canonical-hash(πλην receipt_id),
 "artifact_digest": <hex>, "digest_algorithm": "sha256",
 "fetched_from": {"url", "protocol", "status",
                  "observed_content_type",        # [Δ-9] ΕΔΩ — όχι στο artifact
                  "response_headers_subset": {...}},
 "fetched_at": <ISO UTC — δηλωμένα αναξιόπιστο μόνο του>,
 "anchoring": {"tlog_leaf_index": N, "tsr_sha256": <digest [Α-M12]>} | null,
 "acquirer": {"acquirer_id", "manifest_sha256"},
 "verification": {"read_back": 1, "digest_recomputed": 1}}   # integers 0/1
```

### 5.2 Location observations — journaled· container ΜΗ hash-φέρον [Α-M13]

`lawmax/location-observation/1` (url, observed_at, receipt_id, status:
served-bytes | redirect | gone | changed-digest)· history = replay προβολή.
`changed-digest` ⇒ νέο manifestation ή uncertainty — ποτέ σιωπηλά. URLs σε
ΚΑΝΕΝΑ id. Manual-deposit νόμιμο (acquirer registry είδος).

### 5.3 Γέφυρα item→manifestation: `extraction-receipt/2` = /1 +
manifestation_id [Α-S8] (versioned επέκταση· τα /1 των CLOSED #4B bundles
παραμένουν έγκυρα — ο Π7-U verifier δέχεται και τις δύο εκδόσεις δηλωμένα).

### 5.4 typed-partial dates [Α-S9]: ΜΟΝΟ "YYYY" | "YYYY-MM" | "YYYY-MM-DD"
(ISO reduced precision strings)· προστίθεται στην canonical spec με vectors
(Π7-U.2, ΠΡΙΝ από κάθε χρήση σε hash). Το legal-date του γράφου ΔΕΝ αλλάζει.

---

## 6. Σχέσεις — ΕΝΑ journal, ΠΡΑΓΜΑΤΙΚΗ ατομικότητα [Δ-6]

### 6.1 `lawmax/journal-batch/1` — η έδρα της ατομικότητας [Δ-6]

Πολυ-μεταβατικές πράξεις (annul: relation+regime· suspension: relation+
regime· normative consolidation: event+relation) γράφονται ΩΣ ΕΝΑ record:

```
journal kind :batch
{"schema": "lawmax/journal-batch/1",
 "batch_id": "jb1:" + canonical-hash(περιεχομένου),
 "precondition_root": <αναμενόμενο chain head hash ΠΡΙΝ την εφαρμογή>,
 "ordered_subevents": [<πλήρη payloads υπο-γεγονότων, με τη σειρά>]}
```

- **ΕΝΑ sequence, ΕΝΑ payload hash, ΜΙΑ chain transition.** Crash πριν το
  append ⇒ τίποτα· μετά ⇒ όλα. «Δύο διαδοχικά appends» δεν υπάρχουν για να
  τα χωρίσει crash — η μερική μετάβαση είναι ΔΟΜΙΚΑ αδύνατη (W-Δ6).
- Replay: all-or-nothing· precondition_root mismatch ⇒ journal-corruption
  (η υπάρχουσα fail-closed κλάση)· σημασιολογικά άκυρο subevent ⇒ ΟΛΟ το
  batch απορρίπτεται — κανένα μερικό αποτέλεσμα.
- Μονο-γεγονός appends παραμένουν ως έχουν — το batch υπάρχει για ό,τι
  ΑΠΑΙΤΕΙ συν-γέννηση, δεν είναι γενικό transaction wrapper.

### 6.2 Text-mutating ⇒ γεγονότα γράφου· consolidation ΔΙΑΣΠΑΤΑΙ [Δ-8]

- `amendment, repeal, correction (νομοθετική διόρθωση)`: γεγονότα γράφου
  (υπάρχοντα kinds) μέσω graph-event-proposal + admit-edge!.
- **`consolidation` — evidence-backed legal-effect mode, ΟΧΙ όνομα [Δ-8]:**
  - `normative` (νομοθετική κωδικοποίηση/κύρωση με κανονιστική ισχύ —
    evidence: η εξουσιοδοτική/κυρωτική διάταξη): γεγονός γράφου, ΣΕ BATCH με
    τη σχέση codifies.
  - `derived` (επίσημη ή εκδοτική ενοποίηση ΧΩΡΙΣ νέο κανονιστικό
    αποτέλεσμα): ΚΑΝΕΝΑ γεγονός γράφου — παράγει work-snapshot-expression
    (§1.2) + manifestation με official_variant consolidated-official. Η
    παρουσίαση ΔΕΝ μεταβάλλει τη νομική πραγματικότητα (W-Δ8).
  - Χωρίς evidence για mode ⇒ `legal-effect-unresolved` uncertainty (§8) —
    ΠΟΤΕ default σε γεγονός γράφου.
- Instrument/regime: :ratification (ΠΝΠ/συνθήκες), :acceptance (ΝΣΚ),
  :suspend/:revive/:extend/:expire/:retroact — υπάρχουσες έδρες.

### 6.3 Non-mutating ⇒ `legal-relation/1` ως journal kind [Α-CRIT3]

Kinds — registry [Ν-S7]: `interprets, annuls*, declares-unconstitutional
{erga-omnes | incidenter}*, suspends-effect*, authorizes-delegation,
resolves-pilot-question, precedent-follows, precedent-distinguishes,
codifies{legislative | administrative}, published-in [Δ-7]`.
(* = ΥΠΟΧΡΕΩΤΙΚΑ μέσα σε journal-batch με το regime υπο-γεγονός τους [Δ-6]·
μόνο το erga-omnes declares-unconstitutional φέρει regime υπο-γεγονός — το
incidenter είναι inter partes, καθαρή σχέση.)
Βάση ΜΟΝΟ explicit-citation | operative-part — ΠΟΤΕ inferred, κανένα LLM.
Type guards από work-categories §3.1.

---

## 7. Connectors — acquirer (impure) / parser (pure) [Α-CRIT1]

- `lawmax/acquirer/1`: emits ΜΟΝΟ raw-artifact + acquisition-receipt +
  location-observation. Impure· ίχνος = receipts· recovery §4.3.
- `lawmax/parser/1`: καθαρή συνάρτηση (artifacts+receipts) → {legal-source,
  expression, manifestation, issuance-fact, legal-relation-proposal,
  graph-event-proposal, journal-batch-proposal, authority-proposal,
  uncertainty}. Determinism gate: διπλή εκτέλεση ⇒ byte-ίδια έξοδος
  (SOURCE_DATE_EPOCH). Κανένα δίκτυο/ρολόι/ιδιωτικό πεδίο — ό,τι δεν χωρά
  στα schemas ⇒ uncertainty με το raw διατηρημένο.
- Προτάσεις-όχι-εγγραφές [Α-S6]: graph-event-proposal ≡ κανονικοποιημένο
  espec του admit-edge!· απόρριψη journaled (`proposal-rejected` + αιτία)·
  authority-registry gate = ΔΗΛΩΜΕΝΟ παραδοτέο Π7-U.2 — όχι «υπάρχον».
- Κοινή σουίτα συμμόρφωσης: golden + αντιπαλικά vectors (⊇ ΟΛΟΙ οι W-Δ
  witnesses §12) — gated. Χωρίς πράσινο, ο connector δεν εγγράφεται.

---

## 8. Typed uncertainty — `lawmax/uncertainty/1`

Kinds (registry): `source-unverified | identity-ambiguous (candidate_ids
τυπωμένα) | official-key-incomplete | authority-unresolved | relation-unproven
| date-partial | source-integrity | unclassified-source |
official-sources-conflict | pending-ratification | commencement-unresolved |
authenticity-pending [Ν-S11] | legal-effect-unresolved [Δ-8]`.
Πρώτης τάξης, journaled, ορατό στο /as-known· θάνατος ΜΟΝΟ με νέο evidence ή
ρητή απόφαση δημιουργού (journaled επίλυση)· evidence ποτέ κενό.

---

## 9. Καμία ΦΕΚ-ειδική δομή [Ν-NIT15, Α-M11]

ΦΕΚ = δεδομένα (gazette-issue projector + σειρές στο gr registry). Gate με
ρητή λίστα αρχείων (registries + νέα source αρχεία Π7-U)· επιτρεπτά tokens
ΜΟΝΟ σε registry ΔΕΔΟΜΕΝΑ. Δηλωμένα προϋπάρχοντα υπόλοιπα: `:fek-date`
(amendment-edge record), `:fek-ref` (instrument evidence) — μετονομασία =
μελλοντική versioned φάση (journal format), ΟΧΙ σιωπηλή εδώ. Τα 9 ΦΕΚ (Π7) =
πελάτης του καθολικού: gazette-issue works μέσω gr-gazette acquirer+parser.

---

## 10. Κριτήρια αποδοχής Π7-U.1

1. Ρητή τελική έγκριση δημιουργού μετά από: 2 κριτές v1 (κλειστά στο v2) +
   9 ευρήματα δημιουργού (κλειστά στο v3 με W-Δ1..9) + **2 ΝΕΟΙ ανεξάρτητοι
   κριτές v3** (identity/FRBR/expression collision + journal atomicity/
   legal-effect) με όλα τα ευρήματα κλειστά ή δηλωμένα υπόλοιπα με φάση
   θανάτου.
2. Κάθε registry εγγραφή: identity-projector + classification-fields +
   required-evidence + key-shape — gated load.
3. Καμία δεύτερη έδρα (0.2)· work ≡ body για make-body κλάσεις [Δ-3]· ΕΝΑ
   journal με journal-batch/1 για κάθε συν-γέννηση [Δ-6].
4. Ο όρος §9 μηχανικά επαληθεύσιμος.
5. **Π7-U.2 ΠΑΓΩΜΕΝΟ** μέχρι το 1 — δηλωμένα παραδοτέα του: typed-partial
   canonical vectors, extraction-receipt/2, journal-batch replay, authority
   gate, proposal schemas, conformance vectors (⊇ W-Δ1..9), gr-gazette
   acquirer+parser.

## 11. Δηλωμένα όρια v1

- Πολυγλωσσία: language στην expression· ισοδυναμία μεταξύ γλωσσών =
  μελλοντική φάση. Redaction πολιτική = απόφαση δημιουργού.
- Authority registry: genesis ακολουθία· πληρότητα = μετρήσιμη εκκρεμότητα.
- ΚΑΝΕΝΑ cross-store transaction πουθενά: συν-γέννηση ⇒ journal-batch/1·
  blob↔receipt = ορατή μερικότητα με τυπωμένη ετυμηγορία (§4.3).
- Το παρόν δεν επικαλείται καμία ανύπαρκτη υποδομή ως υπάρχουσα (§10.5).

---

## 12. ΟΝΟΜΑΣΤΙΚΟΙ NEGATIVE WITNESSES [Δ-1..Δ-9] — υποχρεωτικά vectors Π7-U.2

| Witness | Στήνει | Πρέπει να αποτύχει/απορριφθεί ΜΕ ΤΟΝ ΔΗΛΩΜΕΝΟ ΤΡΟΠΟ |
|---|---|---|
| **W-Δ1** | Ίδιο work, δύο graph cuts, ίδια γλώσσα/μορφότυπος/variant | manifestation_ids ΔΙΑΦΟΡΕΤΙΚΑ (το v2 θα έδινε ίδια)· provision_set_root αλλάζει με το cut |
| **W-Δ2** | manifestation χωρίς expression_id | schema reject — όχι default, όχι null |
| **W-Δ3** | Νόμος make-body· διόρθωση συνόλου συνυπογραφόντων | work identity ΑΜΕΤΑΒΛΗΤΗ· ΝΕΟ issuance fact με evidence· ΚΑΝΕΝΑ νέο work |
| **W-Δ4** | eu work με CELEX· αναταξινόμηση eu-decision→eu-regulation | work_id ΑΜΕΤΑΒΛΗΤΟ· classification assertion = νέα έκδοση |
| **W-Δ5** | Μία πράξη ιδρύει 2 αρχές ίδιου kind | 2 ΔΙΑΚΡΙΤΑ authority_ids (locators/entity_keys)· **W-Δ5β**: διόρθωση kind ⇒ id ΑΜΕΤΑΒΛΗΤΟ |
| **W-Δ6** | (α) Χειροποίητο journal με relation-χωρίς-regime ως χωριστά records όπου το registry απαιτεί batch· (β) batch με σημασιολογικά άκυρο subevent | (α) replay FAIL — το ορφανό μισό δεν περνά· (β) ΟΛΟ το batch απορρίπτεται — κανένα μερικό αποτέλεσμα |
| **W-Δ7** | gazette-issue με work-category normative-act· relation με λάθος category άκρου | σφάλμα γέννησης record — type guard στην έδρα |
| **W-Δ8** | Εκδοτική ενοποίηση ως graph-event-proposal ΧΩΡΙΣ normative-effect evidence | proposal-rejected (journaled)· ως derived expression ⇒ δεκτή με ΜΗΔΕΝ graph mutation· χωρίς mode evidence ⇒ legal-effect-unresolved |
| **W-Δ9** | (α) raw-artifact με media_type πεδίο· (β) ίδια bytes, δύο observed content-types· (γ) blob χωρίς receipt στο recovery· (δ) receipt χωρίς blob | (α) schema reject· (β) ΕΝΑ artifact, 2 receipts, απόκλιση τυπωμένη στο manifestation detection· (γ) καραντίνα — όχι υιοθεσία· (δ) σκληρό σφάλμα κλάσης journal-corruption |
