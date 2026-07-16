# LAWMAX — UNIVERSAL SOURCE CONTRACT (Π7-U.1) · `lawmax/legal-source/1` · **v2**

**Κατάσταση:** ΠΡΟΤΑΣΗ προς έγκριση δημιουργού («εγκρίνω Π7-U.1» εκκρεμεί).
**Αναθεώρηση:** v2 — μετά από 2 αντιπαλικούς κριτές (νομικής ταυτότητας/πηγών:
5 CRIT + 6 SERIOUS + 3 MINOR + 1 NIT· αρχιτεκτονικής/provenance: 4 CRIT +
6 SERIOUS + 3 MINOR/NIT). ΟΛΑ τα ευρήματα κλεισμένα ονομαστικά — δείκτες
[Ν-x]=νομικός κριτής, [Α-x]=αρχιτεκτονικός, δίπλα σε κάθε κλείσιμο.
**Εγκεκριμένη βάση:** commit `b87f7d8b`. **Παγωμένα:** #4A/#4B/#4C
(`authority-proof-bundle/1`, `authority-statement/1`) — το παρόν ΣΥΝΘΕΤΕΙ,
δεν μεταβάλλει ΚΑΝΕΝΑ παγωμένο schema [Α-S10]. GAAF-1 + reasoning layers
παγωμένα. ΚΑΝΕΝΑ μαζικό download πριν από ρητή έγκριση connectors.

**Αντικείμενο:** καθολική, versioned μηχανή εισαγωγής ολόκληρης της έννομης
τάξης — ΦΕΚ, δικαστικές αποφάσεις, διοικητικές πράξεις, ενωσιακές και διεθνείς
πηγές, επίσημα ερμηνευτικά τεκμήρια — ΕΝΑ κανονικό αντικείμενο ανά έννοια,
τυποποιημένη άγνοια όπου η απόδειξη λείπει.

**Θεμελιώδης αρχή v2 (η ανώτερη σύλληψη που επέβαλαν και οι 2 κριτές):**
ΚΑΝΕΝΑ hardcoded enum. Κάθε τυπολογία (source classes, key-shapes, court
formations, δικαιοδοσίες, relation kinds) είναι **versioned data registry**
κατά το υπάρχον πρότυπο `body-kind-registry.sexp`/`instrument-kind-registry.sexp`.
Η κλάση σφάλματος «enum χωρίς key-shape» [Ν-CRIT1] πεθαίνει δομικά: το
key-shape δηλώνεται ΜΕΣΑ στην εγγραφή του registry — εγγραφή χωρίς key-shape
δεν φορτώνει (σφάλμα registry load, όχι runtime έκπληξη).

---

## 0. Θεμέλια και ΠΙΝΑΚΑΣ ΜΕΤΑΒΑΣΗΣ — καμία δεύτερη έδρα, ΧΩΡΙΣ αποσιωπήσεις [Α-CRIT4]

### 0.1 Έδρες που το παρόν ΚΑΤΑΝΑΛΩΝΕΙ ως έχουν

| Έννοια | Έδρα | Χρήση εδώ |
|---|---|---|
| Κανονική σειριοποίηση + hash | `canonical-representation` / `canonical-serialization-spec.md` | ΚΑΘΕ id = `canonical-hash` επί κλειστού αντικειμένου· ΟΛΟΙ οι κανόνες της (και «ΟΧΙ booleans σε hash-φέροντα» [Α-CRIT2]) δεσμεύουν το παρόν |
| Ταυτότητα πράξης/provision | `orchestrator.identity` (make-body επί body-kind-registry, make-provision-id) | το work_id ΟΡΙΖΕΤΑΙ ΩΣ ΣΥΝΑΡΤΗΣΗ ΤΟΥΣ (§1.1) [Ν-CRIT4] |
| Μητρώα ειδών | `body-kind-registry.sexp`, `instrument-kind-registry.sexp` | επεκτείνονται με versioned εγγραφές — ΔΕΝ αντιγράφονται (§2) |
| Διτεμπορικός γράφος | `orchestrator.version-graph` (journal, admit-edge!, TILING, +regime-ops+) | text-mutating σχέσεις = ΜΟΝΟ γεγονότα γράφου· ΤΟ journal είναι και ο φορέας ατομικότητας του §6 [Α-CRIT3] |
| Raw→text γέφυρα | `extraction-receipt/1`, `normalization-receipt/1` (#4B) | Η ΜΟΝΗ γέφυρα· επεκτείνεται με `manifestation_id` πεδίο σε ΝΕΑ έκδοση `/2` (§5.4) [Α-S8] |
| Απόδειξη εξουσίας | `authority-proof-bundle/1` (FROZEN) | καταναλώνει τα παρόντα αντικείμενα μέσω census — ΚΑΜΙΑ αλλαγή στο statement (§2.2.4) [Α-S10] |
| Merkle/TSA/tlog/census | orchestrator.merkle, tsr, transparency-log, artifact-census | anchoring + δέσμευση μητρώων |

### 0.2 Μερικές έδρες που ΔΙΑΔΕΧΕΤΑΙ το παρόν — ταξινόμηση κατά [0045] [Α-CRIT4]

| Υπάρχουσα μερική έδρα | Τι επικαλύπτει | Ταξινόμηση + φάση θανάτου |
|---|---|---|
| `source-profile.lisp` `acquired-record` + channels/authority-ranks + ιδιωτικό `%canonical`/`%content-hash` | acquisition receipt, τυπολογία πηγών, ΔΕΥΤΕΡΗ κανονικοποίηση (προϋπάρχουσα παραβίαση) | **B → συνταξιοδότηση Π7-U.3**: τα acquired-records μεταναστεύουν σε acquisition-receipts· το `%canonical` πεθαίνει υπέρ canonical-representation· τα authority-ranks γίνονται δεδομένα του authority registry |
| `document-fetch.lisp` (fek-blob-url, enumerate-new-fek, fetch-fek-blob) | acquisition + official-location με σκληροκωδικωμένη ΦΕΚ σημασιολογία | **B → Π7-U.2**: ξαναγράφεται ως ο πρώτος `acquirer/1` (gr-gazette)· τα ΦΕΚ URL patterns γίνονται δεδομένα του connector registry |
| `government-source.lisp` (feed/diavgeia/fek sources) | δεύτερη τυπολογία πηγών | **B → Π7-U.3**: οι πηγές γίνονται εγγραφές του source registry· η έδρα καταναλώνει, δεν ορίζει |
| `corpus-provenance.lisp` (PROV-O) | δεύτερο provenance λεξιλόγιο | **A (συμβιωτικό)**: το PROV-O είναι ΕΞΑΓΩΓΙΚΗ προβολή (RDF serialization) της αλυσίδας receipts — δηλώνεται ρητά προβολή, ποτέ πηγή αλήθειας· mapping table στο Π7-U.3 |

Κανείς connector δεν υλοποιείται πριν ο πίνακας 0.2 εγκριθεί μαζί με το παρόν.

---

## 1. Καθολική ταυτότητα: τέσσερα επίπεδα (FRBR-ισομορφικό), ΟΛΕΣ οι ταυτότητες ΠΑΡΑΓΩΓΕΣ

```
WORK          νομική οντότητα όπως εκδόθηκε (πράξη/απόφαση/συνθήκη)
 └─ EXPRESSION χρονική/γλωσσική εκδοχή κειμένου (≡ version-graph text-version)
     └─ MANIFESTATION μορφότυπος (PDF, HTML, XML) μιας expression
         └─ ITEM     τα bytes που αποκτήθηκαν (raw artifact §4· ταυτότητα = sha256)
```

Καμία ταυτότητα δεν ΑΠΟΔΙΔΕΤΑΙ — κάθε ταυτότητα ΥΠΟΛΟΓΙΖΕΤΑΙ από κλειστό,
ελάχιστο σύνολο θεσμικών γεγονότων. URL, μορφότυπος, χρόνος λήψης, connector,
σειρά επεξεργασίας ΔΕΝ συμμετέχουν ΠΟΤΕ.

### 1.1 `work_id` — ΣΥΝΑΡΤΗΣΗ της υπάρχουσας έδρας ταυτότητας [Ν-CRIT4]

Για κάθε source class που το (επεκταμένο §2.1) body-kind-registry καλύπτει:

```
work_id = "lsw1:" + canonical-hash({
  "schema":       "lawmax/legal-source/1",
  "body_id":      <orchestrator.identity:make-body — Η υπάρχουσα έδρα, αυτούσια>,
  "authority_ids": <ΚΑΝΟΝΙΚΑ ΤΑΞΙΝΟΜΗΜΕΝΟ σύνολο authority-ids [Ν-CRIT2]>})
```

Για classes εκτός πεδίου make-body (judgment, gazette-issue, eu, treaty,
administrative-act):

```
work_id = "lsw1:" + canonical-hash({
  "schema":        "lawmax/legal-source/1",
  "jurisdiction":  <εγγραφή jurisdiction registry §2.3>,
  "source_class":  <εγγραφή source-class registry §2.1>,
  "authority_ids": <sorted set [Ν-CRIT2]>,
  "official_key":  <το key-shape ΤΗΣ ΕΓΓΡΑΦΗΣ του registry §2.1 — 1-1 δομικά [Ν-CRIT1]>})
```

- `authority_ids` = σύνολο, κανονικά ταξινομημένο πριν το hash: οι ΚΥΑ με Ν
  συνυπογράφοντες υπουργούς έχουν ΜΙΑ ταυτότητα ανεξαρτήτως σειράς [Ν-CRIT2].
- Δύο διαδρομές, ΜΙΑ έδρα: η πρώτη μορφή ΔΕΝ επανακωδικοποιεί number/year —
  τα φέρει το body_id. Αμφιμονοσήμαντη απεικόνιση body-kind ↔ source-class
  δηλώνεται ΣΤΟ registry (πεδίο `body-kind` στην εγγραφή source-class §2.1).
- Απόν/αναπόδεικτο συστατικό ⇒ ΔΕΝ γεννιέται work_id ⇒ uncertainty (§8).

### 1.2 Key-shapes — ΜΕΣΑ στο registry, 1-1 με τις κλάσεις δομικά [Ν-CRIT1]

Δεν υπάρχει πίνακας key-shapes στο spec: κάθε εγγραφή του source-class
registry (§2.1) ΠΕΡΙΕΧΕΙ το key-shape της. Εγγραφή χωρίς `key-shape` (ή με
πεδίο εκτός {string, integer, sorted-set-of-string, typed-partial-date §5.5})
δεν φορτώνει — σφάλμα registry load. Μηχανικός όρος: gated test που φορτώνει
το registry και αποτυγχάνει σε οποιαδήποτε εγγραφή χωρίς έγκυρο key-shape.
Ενδεικτικά δεσμευτικά περιεχόμενα v1 (πλήρης απαρίθμηση: ΣΤΟ registry):

- `judgment`: `{court: authority_id, registry_number: int, year: int}` +
  προαιρετικό `formation` ΜΟΝΟ όταν η εγγραφή του δικαστηρίου στο authority
  registry δηλώνει `numbering: per-formation`, οπότε formation = keyword από
  το ΚΛΕΙΣΤΟ σύνολο formations ΤΗΣ εγγραφής του δικαστηρίου — ελεύθερο string
  αδύνατο δομικά [Ν-CRIT5]. Διακριτά sub-classes: `judgment`, `court-order`
  (βούλευμα), `court-minutes` (πρακτικό) — ίδιος αριθμός, άλλη κλάση.
- `emergency-legislative-act` (ΠΝΠ, άρθ. 44§1 Σ): `{promulgation_date: date,
  gazette_ref: string}` [Ν-CRIT3]. Κύρωση/μη-κύρωση: instrument events της
  υπάρχουσας έδρας (`:ratification` ΥΠΑΡΧΕΙ ΗΔΗ στο instrument-kind-registry)·
  η απώλεια ισχύος εφεξής επί μη κύρωσης = regime γεγονός (`:expire`) με
  evidence την παρέλευση της συνταγματικής προθεσμίας.
- `code` (ΑΚ, ΚΠολΔ…): μέσω body_id (`:kodikas` ΥΠΑΡΧΕΙ στο body-kind-registry)
  [Ν-S6]. Κυρωτική πράξη = ΑΛΛΟ work· σχέσεις `ratifies` (instrument event) /
  `codifies` (legal-relation §6.2, με typed διάκριση νομοθετικής vs διοικητικής
  κωδικοποίησης — η δεύτερη χωρίς αυτοτελή κανονιστική ισχύ).
- `eu-*`: για jurisdiction=eu, **CELEX είναι ΤΟ κλειδί για ΟΛΕΣ τις κλάσεις**
  — μία διαδρομή ταυτότητας, η κλάση είναι μεταδεδομένο της εγγραφής [Ν-M14].
- `international-treaty`: `{parties: sorted-set, conclusion_date: date,
  authentic_title_sha256: string}`· depositary registration = μεταγενέστερο
  evidence, ΟΧΙ κλειδί [Ν-S9].
- `administrative-act`/`circular`: `{protocol_number: string, protocol_date:
  date, registry_series: string}` — η σειρά πρωτοκόλλου της εκδούσας
  υπηρεσίας συμμετέχει (τα πρωτόκολλα τηρούνται ανά υπηρεσία) [Ν-M13].
- `statute` κ.λπ. μέσω body_id — ΧΩΡΙΣ series πεδίο [Α-NIT].

### 1.3 Επίπεδα κάτω από το work

- **expression** ≡ version-graph text-version (`tv-version-hash`) — καμία νέα
  ταυτότητα· δέση work ↔ body/provision μέσω orchestrator.identity.
- **manifestation_id** = `lsm1:` + canonical-hash({work_id, media_type,
  language, official_variant}), official_variant ∈ registry
  {"as-published","corrigendum-applied","consolidated-official"}.
- **item** ≡ raw artifact (§4): ταυτότητα = sha256 bytes. Η δέση item →
  manifestation ζει ΣΤΟ extraction-receipt (§5.4) — όχι σε URL [Α-S8].

---

## 2. Τυπολογίες ως versioned data registries (ΟΧΙ enums)

### 2.1 Source-class registry — ΕΠΕΚΤΑΣΗ της υπάρχουσας οικογένειας μητρώων [Ν-CRIT4]

Νέο κανονικό αρχείο `deployment/data/source-class-registry.sexp` (ίδιο πρότυπο
με body-kind-registry: sexp, *read-eval* nil, census-καταγεγραμμένο), με ανά
εγγραφή: `class`, `key-shape` (§1.2), `body-kind` (δείκτης στο
body-kind-registry όταν η ταυτότητα περνά από make-body — αμφιμονοσήμαντη
απεικόνιση δηλωμένη, όχι συναγόμενη), `frbr-role`, `mutating-capable` (αν
πράξεις της κλάσης μπορούν να φέρουν text-mutating γεγονότα). Αρχικό
περιεχόμενο v1: όλα τα body-kinds (nomos, kodikas, nd, an, psifisma, syntagma,
pd…) + `emergency-legislative-act, ministerial-decision, joint-ministerial-
decision, administrative-act, gazette-issue, judgment, court-order,
court-minutes, eu-treaty, eu-regulation, eu-directive, eu-decision, eu-judgment,
international-treaty, interpretive-circular, opinion-nsk, parliament-standing-
orders, independent-authority-decision` [Ν-CRIT1/3, Ν-2].
Άγνωστη κλάση ⇒ `unclassified-source` uncertainty + καραντίνα raw. ΠΟΤΕ «other».

### 2.2 Authority registry — διτεμπορικές αρχές

`lawmax/authority/1` εγγραφές σε `deployment/data/authority-registry.sexp`:

```
{"schema": "lawmax/authority/1",
 "authority_id": "auth1:" + canonical-hash({jurisdiction, kind, founding}),
 "kind": <registry: parliament | president | minister-council | ministry |
          minister (το ΟΡΓΑΝΟ που εκδίδει ΥΑ — διακριτό από ministry) [Ν-S10] |
          court | prosecutor | independent-authority | central-bank |
          municipality | region | eu-institution | international-org>,
 "founding": {"kind": "founding-act", "ref": work_id}
            | {"kind": "constitutional-basis", "ref": provision-id}
            | {"kind": "pre-corpus-founding",           # [Ν-S10: Άρειος Πάγος 1834
               "citation": <typed: instrument, date, gazette-ref strings>},
 "names": [{"name",..., "valid_from", "valid_to", "evidence": work_id}...],
 "lineage": [{"relation": renamed-from | merged-from | split-from |
              abolished | re-established-as | competence-transferred-to [Ν-S10],
              "counterpart": authority_id, "effective": d, "evidence": work_id}],
 "numbering": <για courts: unified | per-formation, + formations: closed set> [Ν-CRIT5],
 "existence": {"from": d|typed-partial, "to": d|null, "evidence": ...}}
```

1. Ταυτότητα από founding γεγονός: μετονομασία ΔΕΝ αλλάζει ταυτότητα·
   κατάργηση+ανασύσταση = ΝΕΟ id ΜΕ ρητό `re-established-as` δεσμό — η νομική
   συζήτηση περί συνέχειας αποτυπώνεται ως ΔΕΔΟΜΕΝΟ του δεσμού, όχι ως
   ταυτοτική μαντεψιά [Ν-S10].
2. `competence-transferred-to`: η συχνότερη ελληνική αναδιάρθρωση (μεταφορά
   αρμοδιοτήτων χωρίς merge/split) — πρώτης τάξης lineage δεσμός [Ν-S10].
3. Κάθε ισχυρισμός φέρει evidence (work_id ή pre-corpus typed citation) —
   αλλιώς uncertainty. ΚΑΝΕΝΑ LLM στο μητρώο.
4. **Genesis ακολουθία (bootstrap, [Α-S7]):** το μητρώο γεννιέται με ρητή
   αρχικοποίηση: (i) Σύνταγμα (body-kind `:syntagma` — year NIL νόμιμο ΗΔΗ) ⇒
   (ii) constitutional-basis αρχές (Βουλή, ΠτΔ, ΣτΕ, ΑΠ*, ΕλΣυν) ⇒
   (iii) ιδρυόμενες με πράξεις αρχές αναδρομικά με evidence. (*ΑΠ:
   pre-corpus-founding.) Η ακολουθία είναι journaled — όχι σιωπηλό seeding.
5. **Δέσμευση [Α-S10]:** το μητρώο δεσμεύεται ΜΕΣΩ CENSUS (είναι κανονικό
   αρχείο· το census root ΗΔΗ μπαίνει στο frozen authority-statement). ΚΑΜΙΑ
   προσθήκη πεδίου στο `authority-statement/1`.

### 2.3 Jurisdiction registry [Ν-M12]

Registry (όχι enum-με-template): εγγραφές `gr`, `eu`, `int`, και ρητές
εγγραφές ανά περιφέρεια/δήμο όταν χρειαστούν (ΟΤΑ εκδίδουν κανονιστικές
πράξεις — kind `municipality` §2.2). Νέα δικαιοδοσία = νέα εγγραφή με evidence.

---

## 3. Οντολογική διάκριση — έξι τύποι κόμβων, type-guarded

| Τύπος | Τι είναι | Έδρα ταυτότητας |
|---|---|---|
| **document** | manifestation+item | §1.3, §4 |
| **legal act** | το work | `work_id` §1.1 |
| **provision** | αναφερόμενη μονάδα εντός act | `orchestrator.identity` |
| **version** | expression κειμένου σε χρόνο | version-graph `tv` |
| **judgment** | δικαστικό work + τυπικό μέρος `{dispositif, formation?, parties_redacted}` | `work_id` (§1.2 judgment) |
| **interpretation** | ερμηνευτικό work — ΔΕΝ μεταβάλλει κείμενο ποτέ | `work_id` |

Type guard δομικός: κάθε σχέση (§6) δηλώνει επιτρεπτούς τύπους άκρων στην
εγγραφή του relation-kind registry· εγγραφή σχέσης με λάθος τύπο άκρου =
σφάλμα γέννησης του record στην έδρα (etypecase), όχι έλεγχος καταναλωτή.

Ειδικά για `opinion-nsk` [Ν-S8]: η δεσμευτικότητα (αποδοχή από υπουργό) είναι
ΔΙΤΕΜΠΟΡΙΚΟ γεγονός — νέα εγγραφή `:acceptance` στο instrument-kind-registry
(υπάρχουσα έδρα γεγονότων), με evidence την πράξη αποδοχής. ΟΧΙ πεδίο status.

---

## 4. Immutable raw-artifact contract — `lawmax/raw-artifact/1`

```
{"schema": "lawmax/raw-artifact/1",
 "artifact_sha256": <sha256 bytes — Η ταυτότητα, injective εξ ορισμού>,
 "byte_length": N,
 "media_type": <registry: application/pdf | text/html | application/xml | text/plain>}
```

- **[Α-S5] Κανένας δείκτης προς receipts μέσα στο artifact**: η φορά είναι
  receipt→artifact (many-to-one). Ίδια bytes από Ν λήψεις = ΕΝΑ record,
  byte-ίδιο, από οποιονδήποτε acquirer. Admission invariant στην έδρα
  αποθήκευσης: artifact ΔΕΝ γίνεται δεκτό χωρίς ≥1 acquisition receipt που το
  δείχνει — ο έλεγχος ζει στο admission, όχι στο σχήμα.
- Append-only, content-addressed, read-back verification πριν την καταγραφή
  δείκτη (Persistence Receipt πειθαρχία [0086]). Μετάλλαξη αδύνατη δομικά.
- Καμία επιτόπια μετατροπή: κάθε μετασχηματισμός ⇒ ΝΕΟ artifact + δεσμός ΜΟΝΟ
  μέσω extraction/normalization receipts (#4B) — Η γέφυρα, όχι δεύτερη.
- Το raw επιζεί για πάντα — και επί αποτυχίας parsing (καραντίνα + §8).

---

## 5. Acquisition, official-location, γέφυρα προς manifestation

### 5.1 `lawmax/acquisition-receipt/1` — hash-φέρον, ΧΩΡΙΣ booleans [Α-CRIT2]

```
{"schema": "lawmax/acquisition-receipt/1",
 "receipt_id": "acq1:" + canonical-hash(αντικείμενο πλην receipt_id),
 "artifact_sha256": ...,
 "fetched_from": {"url": ..., "protocol": "https", "status": 200,
                  "response_headers_subset": {"content-type", "last-modified", "etag"}},
 "fetched_at": <ISO-8601 UTC — δηλωμένα αναξιόπιστο μόνο του>,
 "anchoring": {"tlog_leaf_index": N, "tsr_sha256": <digest, ΟΧΙ path [Α-M12]>} | null,
 "acquirer": {"acquirer_id": ..., "manifest_sha256": ...},
 "verification": {"read_back": 1, "digest_recomputed": 1}}   # integers 0/1 — ΠΟΤΕ boolean
```

Απόδειξη ύπαρξης-πριν-από-χρόνο δίνει ΜΟΝΟ το anchoring (TSA/tlog)· το
`anchoring: null` είναι ΤΥΠΩΜΕΝΗ διαβάθμιση, ορατή στον καταναλωτή.

### 5.2 Official-location history — δηλωμένα ΜΗ hash-φέρον container [Α-M13]

Οι παρατηρήσεις είναι journaled γεγονότα (κάθε μία με δικό της παράγωγο id =
canonical-hash της παρατήρησης)· το «history» είναι ΠΑΡΑΓΩΓΗ ΠΡΟΒΟΛΗ replay
ανά (work, manifestation) — δεν είναι αντικείμενο με ταυτότητα, δεν
ξαναγράφεται, δεν υπογράφεται ως όλον:

```
observation: {"schema": "lawmax/location-observation/1",
  "work_id", "manifestation_id", "url", "observed_at",
  "acquisition_receipt_id",
  "status": "served-bytes" | "redirect" | "gone" | "changed-digest"}
```

`changed-digest` σε επίσημο URL = γεγονός πρώτης τάξης ⇒ υποχρεωτικά είτε νέο
manifestation (νόμιμη διόρθωση) είτε `official-sources-conflict`/
`source-integrity` uncertainty — ποτέ σιωπηλή αντικατάσταση.

### 5.3 Ταυτότητα ≠ τοποθεσία

Τα URLs δεν συμμετέχουν σε ΚΑΜΙΑ ταυτότητα. Η ιστορία τους καταγράφεται·
manual-drop/offline artifacts είναι πλήρως νόμιμα (χωρίς url, με acquisition
receipt είδους `manual-deposit` — εγγραφή στο acquirer registry).

### 5.4 Γέφυρα item→manifestation: ΣΤΟ extraction-receipt [Α-S8]

`lawmax/extraction-receipt/2` = /1 + πεδίο `manifestation_id` (versioned
επέκταση της υπάρχουσας έδρας — το /1 παραμένει έγκυρο για τα υπάρχοντα #4B
bundles· ο verifier του Π7-U δέχεται ΚΑΙ τα δύο με δηλωμένη έκδοση). Έτσι η
αλυσίδα κλείνει ΧΩΡΙΣ URL: bytes → extraction(/2 με manifestation) →
normalization → graph text, όλα content-addressed.

### 5.5 typed-partial dates — κωδικοποίηση ΟΡΙΣΜΕΝΗ [Α-S9]

Κανονική μορφή ΜΟΝΟ ως strings κλειστής μορφής: `"YYYY"`, `"YYYY-MM"`,
`"YYYY-MM-DD"` (ISO-8601 reduced precision) — καμία άλλη. Προστίθεται στην
canonical-serialization-spec ΩΣ ΝΕΟΣ κανόνας με conformance vectors
(παραδοτέο Π7-U.2, ΠΡΙΝ από κάθε χρήση σε hash). Το `legal-date` του
version-graph (πλήρης ημερομηνία) ΔΕΝ αλλάζει — τα typed-partial ζουν ΜΟΝΟ σε
official_keys/uncertainty, ποτέ σε temporal semantics του γράφου.

---

## 6. Σχέσεις — ΔΥΟ οικογένειες, ΕΝΑ journal (ατομικότητα δομική) [Α-CRIT3]

### 6.1 Text-mutating ⇒ ΜΟΝΟ γεγονότα version-graph (υπάρχουσα έδρα)

`amendment, repeal (total/partial), correction, consolidation` + instrument
events (`:ratification` ΠΝΠ/συνθηκών, `:acceptance` ΝΣΚ) + regime events
(`:suspend/:revive/:extend/:expire/:retroact` — ΥΠΑΡΧΟΝΤΑ +regime-ops+).
Ο parser παράγει **graph-event-proposal** (§7.3)· η αποδοχή περνά ΜΟΝΟ από το
υπάρχον admit-edge! (replay-then-append).

### 6.2 Non-mutating ⇒ `legal-relation/1` ΩΣ JOURNAL KIND του ΙΔΙΟΥ journal [Α-CRIT3]

Το relation record είναι νέο journal kind του version-graph journal (ΟΧΙ
χωριστό store): μία εγγραφή = μία atomic append στην υπάρχουσα αλυσίδα
(chain-hash, replay verification δωρεάν). Το «relation store» είναι ΠΑΡΑΓΩΓΗ
ΠΡΟΒΟΛΗ replay. Όπου μια πράξη απαιτεί relation ΚΑΙ regime γεγονός (annul,
suspend), γράφονται ως ΔΙΑΔΟΧΙΚΑ kinds με το relation να φέρει δείκτη στο seq
του regime event — η συνέπεια ελέγχεται στο replay (journal-corruption επί
ορφανού μισού), όχι με cross-store ευχή.

Relation kinds — **registry** (όχι enum), v1 περιεχόμενο [Ν-S7]:

| kind | άκρα (type guard) | βάση |
|---|---|---|
| `interprets` | interpretation → provision\|act | explicit-citation |
| `annuls` | judgment → administrative act | operative-part + regime δείκτης |
| `declares-unconstitutional` | judgment → provision, **scope: erga-omnes (ΑΕΔ άρθ. 100 Σ) \| incidenter (διάχυτος έλεγχος, inter partes)** [Ν-S7] | operative-part· ΜΟΝΟ erga-omnes φέρει regime δείκτη |
| `suspends-effect` | judgment (ΕΑ) → act\|provision | operative-part + regime `:suspend` δείκτης [Ν-S7] |
| `authorizes-delegation` | statute provision → pd\|ministerial-decision | explicit-citation (το προοίμιο την τυπώνει) [Ν-S7] |
| `resolves-pilot-question` | judgment (ΟλΣτΕ, ν. 3900/2010) → provision + question | operative-part — ΤΥΠΙΚΗ δεσμευτικότητα, όχι inferred [Ν-S7] |
| `precedent-follows / precedent-distinguishes` | judgment → judgment | explicit-citation ΜΟΝΟ — καμία συναγωγή ομοιότητας |
| `codifies` | code-work → statutes, typed: legislative\|administrative [Ν-S6] | explicit-citation |

`verdict_basis` κλειστό: `explicit-citation | operative-part`. ΠΟΤΕ inferred·
κανένα LLM/similarity στο trusted path.

---

## 7. Connector contract — ΔΥΟ ρητά συμβόλαια: acquirer (impure) / parser (pure) [Α-CRIT1]

### 7.1 `lawmax/acquirer/1` — ο ΜΟΝΟΣ που αγγίζει τον έξω κόσμο

Emits ΜΟΝΟ: `raw-artifact/1`, `acquisition-receipt/1`,
`location-observation/1`. Δηλώνει: πηγές που προσεγγίζει, rate policy,
`manual-deposit` capability. ΔΕΝ παράγει κανονικά νομικά αντικείμενα, ΔΕΝ
ερμηνεύει bytes. Impure εξ ορισμού — κανένα determinism gate, receipts είναι
το ίχνος του.

### 7.2 `lawmax/parser/1` — καθαρή συνάρτηση, gated determinism

`(artifacts + receipts) → {legal-source/1, location-observation-annotations,
legal-relation-proposal, graph-event-proposal, authority-proposal,
uncertainty/1}` — emits ΞΕΝΟ (disjoint) προς του acquirer [Α-CRIT1].
Determinism gate: διπλή εκτέλεση στο build ⇒ byte-ίδια έξοδος (SOURCE_DATE_EPOCH).
Κανένα δίκτυο, κανένα ρολόι, κανένα connector-ιδιωτικό πεδίο εξόδου: ό,τι δεν
χωρά στα schemas ⇒ uncertainty με το raw διατηρημένο.

### 7.3 Προτάσεις, όχι εγγραφές — με ΥΠΑΡΚΤΑ και ΔΗΛΩΜΕΝΑ gates [Α-S6]

- `graph-event-proposal` ≡ κανονικοποιημένο espec του ΥΠΑΡΧΟΝΤΟΣ admit-edge!
  (τυπώνεται εδώ ως schema με παράγωγο id — ίδια σημασιολογία, όχι νέο gate).
- Η ΑΠΟΡΡΙΨΗ πρότασης είναι journaled γεγονός (kind `proposal-rejected` με
  αιτία) — καμία σιωπηλή απόρριψη.
- **Authority-registry admission gate: ΔΕΝ ΥΠΑΡΧΕΙ ΣΗΜΕΡΑ — δηλωμένο
  παραδοτέο Π7-U.2** (replay-then-append επί του ίδιου journal μηχανισμού),
  όχι επίκληση υπάρχουσας υποδομής [Α-S6].

### 7.4 Κοινή σουίτα συμμόρφωσης

Κάθε acquirer/parser περνά ΤΑ ΙΔΙΑ contract vectors (golden + αντιπαλικά:
αμφίσημη ταυτότητα, λείπον key συστατικό, changed-digest, ΚΥΑ πολλαπλών
εκδοτών, ΠΝΠ+κύρωση, Ολ/Τμήμα) — gated στο Docker. Χωρίς πράσινη συμμόρφωση,
ο connector δεν εγγράφεται στο connector registry. Vectors που καρφώνουν και
τη σειριοποίηση εξόδων από Lisp δομές (plist/alist/array διάκριση) [Α-NIT].

---

## 8. Typed uncertainty — `lawmax/uncertainty/1`

Kinds — registry, v1 περιεχόμενο (κλεισίματα [Ν-S11] σημειωμένα):

```
source-unverified | identity-ambiguous (με candidate_ids ΤΥΠΩΜΕΝΑ)
| official-key-incomplete | authority-unresolved | relation-unproven
| date-partial | source-integrity | unclassified-source
| official-sources-conflict   # δύο ΕΠΙΣΗΜΑ κείμενα διαφέρουν (έντυπο ΦΕΚ vs et.gr) [Ν-S11α]
| pending-ratification        # ΠΝΠ/συνθήκη σε εκκρεμή κύρωση — δείκτης στο condition
                              # μηχανισμό του γράφου (Π2), ΟΧΙ δεύτερη αναπαράσταση [Ν-S11β]
| commencement-unresolved     # vacatio legis: υπολογισμένη default vs ρητή έναρξη [Ν-S11γ]
| authenticity-pending        # στοιχεία απόφασης προ καθαρογραφής [Ν-S11δ]
```

- Πρώτης τάξης, journaled, ορατό στο /as-known στρώμα (υπάρχον pending
  μονοπάτι Φ7-Π5).
- Κάθε uncertainty έχει ΘΑΝΑΤΟ μόνο με νέο evidence ή ρητή απόφαση δημιουργού·
  η επίλυση = journaled γεγονός με δείκτη στο evidence. Καμία αυτοεπίλυση.
- `evidence` ποτέ κενό: καταγράφεται τι ΞΕΡΟΥΜΕ, `blocking` τι μπλοκάρεται.

---

## 9. Καμία ΦΕΚ-ειδική δομή — μηχανικός όρος με ΡΗΤΟ πεδίο εφαρμογής [Ν-NIT15, Α-M11]

- Το ΦΕΚ = ΔΕΔΟΜΕΝΑ (`gazette-issue` εγγραφές, σειρές στο registry της gr
  δικαιοδοσίας). ΚΑΝΕΝΑ νέο πεδίο σχήματος/registry-δομής/connector hook με
  σημασιολογία «ΦΕΚ» στα schemas του παρόντος.
- **Gate με ρητή λίστα αρχείων** (όχι αόριστο grep): τα schema αρχεία του
  Π7-U (source-class/authority/jurisdiction/relation-kind registries, τα νέα
  source αρχεία acquirer/parser contract) ελέγχονται για tokens fek/φεκ·
  επιτρεπόμενες εμφανίσεις ΜΟΝΟ σε ΔΕΔΟΜΕΝΑ (εγγραφές gr registry) — η λίστα
  και οι εξαιρέσεις ζουν στο ίδιο το gate test, versioned.
- **Δηλωμένα προϋπάρχοντα υπόλοιπα** (τίμια, με φάση θανάτου): `:fek-date`
  πεδίο στο amendment-edge journal record και `:fek-ref` evidence schema του
  instrument-kind-registry — προϋπάρχουν του Π7-U στη σπονδυλική στήλη.
  Μετονομασία σε gazette-ουδέτερο όρο = ρητή μελλοντική versioned φάση
  (journal format αλλαγή — ΔΕΝ γίνεται σιωπηλά εδώ)· μέχρι τότε ΔΗΛΩΜΕΝΟ
  υπόλειμμα, εκτός πεδίου του gate [Α-M11].
- Το benchmark των 9 ΦΕΚ (Π7) τρέχει ΩΣ ΠΕΛΑΤΗΣ του καθολικού contract: 9
  gazette-issue works μέσα από τον gr-gazette acquirer+parser — η ίδια
  διαδρομή κάθε μελλοντικής πηγής.

---

## 10. Κριτήρια αποδοχής Π7-U.1

1. Ρητή έγκριση δημιουργού («εγκρίνω Π7-U.1») ΜΕΤΑ τους 2 κριτές — έγιναν
   (v2 κλείνει ΟΛΑ τα ευρήματα ονομαστικά· βλ. δείκτες [Ν-x]/[Α-x]).
2. Κάθε τυπολογία = versioned data registry με key-shape ΣΤΗΝ εγγραφή·
   gated test: εγγραφή χωρίς έγκυρο key-shape δεν φορτώνει.
3. Καμία δεύτερη έδρα: ο πίνακας 0.2 δεσμεύει τη μετάβαση των 4 μερικών
   εδρών· text-mutating ⇒ version-graph events· relations ⇒ journal kinds
   του ΙΔΙΟΥ journal· raw→text ⇒ extraction/normalization receipts.
4. Ο όρος §9 μηχανικά επαληθεύσιμος με ρητό πεδίο εφαρμογής + δηλωμένα
   υπόλοιπα.
5. Π7-U.2 (typed-partial canonical vectors, extraction-receipt/2,
   authority-registry gate, proposal schemas, conformance vectors, gr-gazette
   acquirer+parser) και Π7 benchmark ΞΕΚΙΝΟΥΝ ΜΟΝΟ μετά το 1.

## 11. Δηλωμένα όρια v1 (τίμια)

- Πολυγλωσσία expressions (ΕΕ 24 γλώσσες): manifestation.language υπάρχει· ο
  κανόνας ισοδυναμίας expressions μεταξύ γλωσσών = μελλοντική versioned φάση.
- Redaction judgments: typed `parties_redacted`· η πολιτική = απόφαση δημιουργού.
- Authority registry: γεννιέται με τη genesis ακολουθία §2.2.4 και γεμίζει
  ΜΟΝΟ evidence-backed — η πληρότητα μετρήσιμη εκκρεμότητα, όχι υπόσχεση.
- Cross-store atomicity ΔΕΝ υπάρχει πουθενά στο σχέδιο — εξαλείφθηκε δομικά
  (ένα journal)· όπου μελλοντική φάση χρειαστεί δεύτερο store, οφείλει δικό
  της απόδειξη-φέρον μηχανισμό, όχι ευχή.
- Τα Π7-U.2 παραδοτέα του §10.5 είναι ΠΡΟΫΠΟΘΕΣΕΙΣ υλοποίησης — το παρόν
  δεν επικαλείται καμία ανύπαρκτη υποδομή ως υπάρχουσα.
