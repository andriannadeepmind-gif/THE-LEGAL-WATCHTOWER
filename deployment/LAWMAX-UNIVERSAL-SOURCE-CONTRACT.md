# LAWMAX — UNIVERSAL SOURCE CONTRACT (Π7-U.1) · `lawmax/legal-source/1`

**Κατάσταση:** ΠΡΟΤΑΣΗ προς έγκριση δημιουργού («εγκρίνω Π7-U.1» εκκρεμεί).
**Εγκεκριμένη βάση:** commit `b87f7d8b` (Πράξη Ολοκλήρωσης #4).
**Παγωμένα:** #4A/#4B/#4C proof protocol (`authority-proof-bundle/1`) — το παρόν
ΣΥΝΘΕΤΕΙ με αυτό, ΔΕΝ το μεταβάλλει. GAAF-1 runtime + κάθε reasoning layer
παγωμένα. ΚΑΝΕΝΑ μαζικό download πριν από ρητή έγκριση connectors.

**Αντικείμενο:** η καθολική, versioned μηχανή εισαγωγής ολόκληρης της έννομης
τάξης — όλα τα ΦΕΚ, δικαστικές αποφάσεις, διοικητικές πράξεις, ενωσιακές και
διεθνείς πηγές, επίσημα ερμηνευτικά τεκμήρια — με ΕΝΑ κανονικό αντικείμενο ανά
έννοια και τυποποιημένη άγνοια όπου η απόδειξη λείπει.

**Κριτήριο σχεδίασης (εντολή δημιουργού):** όχι «καλύτερο από τα άλλα» αλλά
«υπάρχει ανώτερος μηχανισμός που μπορούμε ακόμη να συλλάβουμε;». Οι επιλογές
εδώ προτιμούν ΔΟΜΙΚΗ αδυνατότητα σφάλματος από φρουρούς γύρω από σφάλμα.

---

## 0. Θεμέλια — προϋπάρχουσες έδρες που δεσμεύουν το Π7-U (ΚΑΜΙΑ δεύτερη έδρα)

| Έννοια | Έδρα | Χρήση εδώ |
|---|---|---|
| Κανονική σειριοποίηση + hash | `canonical-representation` / `deployment/verify/canonical-serialization-spec.md` | ΚΑΘΕ id εδώ = `canonical-hash` επί κλειστού αντικειμένου |
| Ταυτότητα provision/body | `orchestrator.identity` (make-provision-id, declared-body) | το contract ΚΑΤΑΝΑΛΩΝΕΙ, δεν επανορίζει |
| Διτεμπορικός γράφος/γεγονότα | `orchestrator.version-graph` (journal kinds, TILING) | text-mutating σχέσεις = ΜΟΝΟ γεγονότα γράφου |
| Extraction/normalization receipts | `lawmax/extraction-receipt/1`, `lawmax/normalization-receipt/1` (#4B) | η ΜΟΝΗ γέφυρα raw→text |
| Απόδειξη εξουσίας | `authority-proof-bundle/1` (#4A/B/C, FROZEN) | καταναλώνει τα παρόντα αντικείμενα ΩΣ ΕΧΟΥΝ |
| Merkle/TSA/tlog | orchestrator.merkle, tsr, transparency-log | acquisition anchoring (§5) |

Κανόνας: αν μια έννοια του παρόντος έχει ήδη έδρα, το schema εδώ ΠΑΡΑΠΕΜΠΕΙ.
Νέο schema εισάγεται ΜΟΝΟ για έννοια χωρίς έδρα.

---

## 1. Καθολική ταυτότητα: τέσσερα επίπεδα (FRBR-ισομορφικό), ΟΛΕΣ οι ταυτότητες ΠΑΡΑΓΩΓΕΣ

Η κλάση σφαλμάτων «ταυτότητα από URL/format/σειρά λήψης» πεθαίνει ΔΟΜΙΚΑ:
καμία ταυτότητα δεν ΑΠΟΔΙΔΕΤΑΙ — κάθε ταυτότητα ΥΠΟΛΟΓΙΖΕΤΑΙ ως
`canonical-hash` επί κλειστού, ελάχιστου συνόλου γεγονότων. Ίδια γεγονότα ⇒
ίδια ταυτότητα, από οποιονδήποτε connector, σε οποιονδήποτε χρόνο.

```
WORK          νομική οντότητα όπως εκδόθηκε (πράξη/απόφαση/συνθήκη)
 └─ EXPRESSION χρονική/γλωσσική εκδοχή κειμένου (version — έδρα: version-graph)
     └─ MANIFESTATION μορφότυπος (PDF, HTML, XML) μιας expression
         └─ ITEM     συγκεκριμένα bytes που αποκτήθηκαν (raw artifact, §4)
```

### 1.1 `work-id` — `lawmax/legal-source/1`

```
work_id = "lsw1:" + canonical-hash({
  "schema":        "lawmax/legal-source/1",
  "jurisdiction":  <closed enum §2.1>,
  "authority_id":  <authority-id §2.2 — ο ΕΚΔΟΤΗΣ, όχι ο δημοσιεύων>,
  "source_class":  <closed enum §2.3>,
  "official_key":  <closed per-class key §1.2 — ο θεσμικός προσδιοριστής>
})
```

- ΟΛΑ τα πεδία υποχρεωτικά. Απόν/αναπόδεικτο πεδίο ⇒ ΔΕΝ γεννιέται work-id ⇒
  typed uncertainty (§8) — ποτέ «προσωρινό» id.
- Το URL, ο μορφότυπος, η ημερομηνία λήψης, ο connector ΔΕΝ συμμετέχουν.

### 1.2 `official_key` — κλειστό ανά source_class (ο θεσμικός τρόπος αναφοράς)

| source_class | official_key πεδία (όλα strings/integers, καν. σειριοποίηση) |
|---|---|
| statute | `{"series": "...", "number": N, "year": YYYY}` π.χ. νόμος: number+year |
| gazette-issue | `{"series": "...", "issue": N, "year": YYYY}` (η σειρά είναι ΔΕΔΟΜΕΝΟ registry, όχι πεδίο σχήματος — §9) |
| judgment | `{"court_registry_number": N, "year": YYYY, "formation": "..."}` |
| eu-act | `{"celex": "..."}` (CELEX = ο θεσμικός προσδιοριστής της ΕΕ) |
| treaty | `{"depositary_registration": "...", "conclusion_date": "YYYY-MM-DD"}` |
| administrative-act / circular | `{"protocol_number": "...", "protocol_date": "YYYY-MM-DD"}` |

Κλειστότητα: άγνωστο source_class ή key-shape ⇒ σφάλμα schema, όχι μαντεψιά.
Επέκταση = ΝΕΑ έκδοση schema (`legal-source/2`), ποτέ ελεύθερο πεδίο.

### 1.3 Επίπεδα κάτω από το work

- **expression**: ΔΕΝ εισάγεται νέο id — expression ≡ text-version κόμβος του
  version-graph (`tv-version-hash`). Το contract δένει `work_id ↔ body/provision`
  μέσω `orchestrator.identity` (declared-body, make-provision-id).
- **manifestation-id** = `lsm1:` + canonical-hash({work_id, media_type,
  language, official_variant}) όπου official_variant ∈ closed enum
  {"as-published","corrigendum-applied","consolidated-official"}.
- **item** ≡ raw artifact (§4): ταυτότητα = sha256 των bytes. ΤΕΛΟΣ.

Δομική συνέπεια: δύο λήψεις του ίδιου PDF από διαφορετικά URLs = ΕΝΑ item.
Το ίδιο κείμενο σε PDF και HTML = ένα work, μία expression, ΔΥΟ manifestations.

---

## 2. Τυπολογία πηγών και εκδουσών αρχών

### 2.1 `jurisdiction` — κλειστό enum

`"gr" | "eu" | "int" | "gr-region/<iso>"` — τίποτα ελεύθερο. Νέα δικαιοδοσία =
νέα εγγραφή στο enum με versioned schema bump.

### 2.2 Authority registry — οι αρχές είναι ΔΙΤΕΜΠΟΡΙΚΕΣ οντότητες

Τα υπουργεία μετονομάζονται/συγχωνεύονται· δικαστήρια ιδρύονται/καταργούνται.
Άρα ο εκδότης ΔΕΝ είναι string — είναι εγγραφή μητρώου `lawmax/authority/1`:

```
{"schema": "lawmax/authority/1",
 "authority_id": "auth1:" + canonical-hash({jurisdiction, kind, founding_act_ref | constitutional_basis}),
 "kind": <closed: parliament | president | minister-council | ministry | court |
          independent-authority | eu-institution | international-org | region>,
 "names": [{"name": "...", "valid_from": d, "valid_to": d|null, "evidence": work_id}...],
 "lineage": [{"relation": "renamed-from"|"merged-from"|"split-from",
              "predecessor": authority_id, "effective": d, "evidence": work_id}...],
 "existence": {"from": d, "to": d|null, "evidence": work_id}}
```

- Ταυτότητα από ΙΔΡΥΤΙΚΟ γεγονός (όχι από τρέχον όνομα) ⇒ μετονομασία ΔΕΝ
  αλλάζει ταυτότητα — η κλάση «ίδιο υπουργείο, δύο ids» πεθαίνει δομικά.
- Κάθε name/lineage/existence ισχυρισμός φέρει evidence = work_id της πράξης
  που τον αποδεικνύει, αλλιώς typed uncertainty (§8). ΚΑΝΕΝΑ LLM στο μητρώο.
- Το μητρώο είναι κανονικό αρχείο του corpus (census-καταγεγραμμένο), με
  δικό του `registry_digest` δεσμεύσιμο στο authority-statement (όπως το
  υπάρχον verifier registry — ίδια τεχνική, χωριστή εγγραφή).

### 2.3 `source_class` — κλειστή τυπολογία (v1)

```
constitution | statute | legislative-decree | presidential-decree |
act-of-ministerial-cabinet | ministerial-decision | administrative-act |
gazette-issue | judgment | eu-treaty | eu-regulation | eu-directive |
eu-decision | international-treaty | interpretive-circular | opinion-nsk
```

Κλειστό: connector που συναντά κάτι εκτός enum ⇒ `unclassified-source`
uncertainty (§8) + καραντίνα raw artifact. ΠΟΤΕ «other».

---

## 3. Οντολογική διάκριση — έξι τύποι κόμβων, type-guarded

| Τύπος | Τι είναι | Έδρα ταυτότητας |
|---|---|---|
| **document** | manifestation+item (bytes ενός μορφότυπου) | §1.3, §4 |
| **legal act** | το work — θεσμική πράξη με εκδότη+official_key | `work_id` §1.1 |
| **provision** | αναφερόμενη μονάδα (άρθρο/παρ.) εντός act | `orchestrator.identity` |
| **version** | expression κειμένου provision σε χρόνο | version-graph `tv` |
| **judgment** | δικαστική απόφαση: work με πρόσθετο τυπικό μέρος `{dispositif, formation, parties-redacted}` | `work_id` (source_class=judgment) |
| **interpretation** | ερμηνευτικό τεκμήριο (εγκύκλιος, γνωμοδότηση) — work που ΔΕΝ μεταβάλλει κείμενο ποτέ | `work_id` (interpretive-*) |

Type guard (δομικός, όχι convention): κάθε σχέση του §6 δηλώνει επιτρεπτούς
τύπους άκρων· εγγραφή σχέσης με λάθος τύπο άκρου = σφάλμα γέννησης του
αντικειμένου σχέσης (etypecase στην έδρα), όχι runtime έλεγχος καταναλωτή.

---

## 4. Immutable raw-artifact contract — `lawmax/raw-artifact/1`

```
{"schema": "lawmax/raw-artifact/1",
 "artifact_sha256": <sha256 των bytes — Η ταυτότητα>,
 "byte_length": N,
 "media_type": <closed enum: application/pdf | text/html | application/xml | text/plain>,
 "acquisition_receipt_id": <§5 — υποχρεωτικό: ΔΕΝ υπάρχει artifact χωρίς απόδειξη κτήσης>}
```

Νόμοι:
1. **Append-only, content-addressed αποθήκευση.** Τα bytes γράφονται ΜΙΑ φορά
   στη διεύθυνση sha256 τους· read-back verification πριν καταγραφεί ο
   δείκτης (Persistence Receipt πειθαρχία [0086]). Μετάλλαξη = αδύνατη:
   αλλαγμένα bytes είναι ΑΛΛΟ artifact.
2. **Καμία επιτόπια μετατροπή.** Κάθε μετασχηματισμός (OCR, decompress,
   re-encode) παράγει ΝΕΟ artifact + `derivation` δεσμό ΜΕΣΩ των υπαρχουσών
   εδρών `extraction-receipt/1` → `normalization-receipt/1` (#4B) — αυτή είναι
   Η γέφυρα raw→text, δεν εισάγεται δεύτερη.
3. **Το raw διατηρείται για πάντα** — ακόμη κι όταν parsing απέτυχε
   (καραντίνα με uncertainty §8): η επανεπεξεργασία αύριο με καλύτερο
   connector είναι δυνατή ΜΟΝΟ αν τα ωμά bytes επιζούν.

---

## 5. Acquisition receipt + official-location history

### 5.1 `lawmax/acquisition-receipt/1`

```
{"schema": "lawmax/acquisition-receipt/1",
 "receipt_id": "acq1:" + canonical-hash(όλο το αντικείμενο πλην receipt_id),
 "artifact_sha256": <δένει ΤΑ bytes>,
 "fetched_from": {"url": "...", "protocol": "https", "status": 200,
                  "response_headers_subset": {"content-type":..., "last-modified":..., "etag":...}},
 "fetched_at": <ISO-8601 UTC — μηχανικό ρολόι, δηλωμένα αναξιόπιστο μόνο του>,
 "anchoring": {"tlog_leaf_index": N | null, "tsr_ref": <path|null>}  # RFC-3161/tlog όταν διαθέσιμο,
 "connector": {"connector_id": "...", "capability_manifest_sha256": "..."},
 "verification": {"read_back": true, "digest_recomputed": true}}
```

- Το `fetched_at` ΔΕΝ αποδεικνύει τίποτα μόνο του (τίμια δήλωση)· απόδειξη
  ύπαρξης-πριν-από-χρόνο δίνει ΜΟΝΟ το anchoring (TSA genTime / tlog inclusion
  — υπάρχουσες έδρες). Fail-open εδώ είναι αποδεκτό ΜΟΝΟ ως δηλωμένο
  `anchoring: null` — ο καταναλωτής βλέπει τη διαφορά τυπωμένη.

### 5.2 Official-location history — append-only, identity-neutral

```
{"schema": "lawmax/official-location/1",
 "work_id": ..., "manifestation_id": ...,
 "observations": [  # append-only· ΠΟΤΕ επανεγγραφή
   {"url": "...", "observed_at": t, "acquisition_receipt_id": ...,
    "status": "served-bytes" | "redirect" | "gone" | "changed-digest"}]}
```

- Τα URLs αλλάζουν· η ιστορία τους καταγράφεται, η ταυτότητα ΔΕΝ τα ακουμπά.
- `changed-digest` (ίδιο επίσημο URL, άλλα bytes) είναι ΓΕΓΟΝΟΣ ΠΡΩΤΗΣ ΤΑΞΗΣ:
  παράγει υποχρεωτικά είτε νέο manifestation (νόμιμη ενημέρωση, π.χ.
  διόρθωση) είτε `source-integrity` uncertainty — ποτέ σιωπηλή αντικατάσταση.

---

## 6. Σχέσεις — ΔΥΟ οικογένειες με διαφορετική οντολογία (δομικός διαχωρισμός)

Η ανώτερη σύλληψη: οι σχέσεις ΔΕΝ είναι ένας ενιαίος πίνακας «links». Υπάρχουν
δύο θεμελιωδώς διαφορετικά είδη, και το contract τα κάνει ΑΔΥΝΑΤΟ να μπερδευτούν:

### 6.1 Text-mutating σχέσεις ⇒ ΜΟΝΟ γεγονότα version-graph (υπάρχουσα έδρα)

`amendment, repeal (total/partial), correction, consolidation`

- Αυτές ΑΛΛΑΖΟΥΝ ποιο κείμενο ισχύει ⇒ είναι εξ ορισμού γεγονότα του
  διτεμπορικού γράφου (admit-edge!/journal kinds — Φ2/Φ7). Το contract ΔΕΝ
  εισάγει δεύτερη αναπαράσταση: ο connector που εντοπίζει τροποποίηση παράγει
  ΠΡΟΤΑΣΗ γεγονότος γράφου με evidence, ποτέ δικό του «amendment record».
- `correction` (διόρθωση σφαλμάτων) και `consolidation` είναι διακριτά kinds
  με τη σημασιολογία τους ήδη στη σπονδυλική στήλη (TILING) — εδώ μόνο
  δένονται με `work_id` προέλευσης + provision-level evidence.

### 6.2 Non-mutating σχέσεις ⇒ `lawmax/legal-relation/1` (νέα έδρα, ΔΕΝ αγγίζει κείμενο)

`interpretation, annulment, precedent`

```
{"schema": "lawmax/legal-relation/1",
 "relation_id": "rel1:" + canonical-hash(...),
 "relation": <closed: interprets | annuls | precedent-follows | precedent-distinguishes>,
 "from": {"type": <allowed types ανά relation — type guard §3>, "id": ...},
 "to":   {"type": ..., "id": ...},
 "evidence": {"work_id": ..., "provision_pin": <make-provision-id | dispositif-pin>},
 "bitemporal": {"valid_from": d|typed-partial, "known_at": d},
 "verdict_basis": "explicit-citation" | "operative-part"}   # ΠΟΤΕ inferred
```

- `annuls` (ακύρωση ΣτΕ): επιτρεπτά άκρα judgment→{legal act | provision}.
  ΣΗΜΑΝΤΙΚΟ: η ακύρωση ΔΕΝ σβήνει κείμενο — παράγει regime γεγονός στον γράφο
  (υπάρχον Π4 kind) ΚΑΙ τη σχέση εδώ· η διπλή εγγραφή είναι ΜΙΑ συναλλαγή
  (είτε και τα δύο είτε τίποτα), με το relation ως evidence-φορέα.
- `precedent-*`: judgment→judgment ΜΟΝΟ, βάση ΜΟΝΟ ρητή μνεία. ΚΑΜΙΑ συναγωγή
  ομοιότητας (κανένα LLM/similarity στο trusted path — τίμια άγνοια).
- `interprets`: interpretation→{provision | legal act}. Δεν επηρεάζει ΠΟΤΕ το
  version-at — ζει σε χωριστό στρώμα ανάγνωσης.

---

## 7. Closed connector contract — `lawmax/connector/1`

Connector = **καθαρή συνάρτηση** `(raw artifacts + acquisition receipts) →
(canonical objects ∪ typed uncertainties)`. Τίποτα άλλο.

```
Capability manifest (δηλωμένο, hashed, δεσμευμένο στο acquisition receipt §5.1):
{"schema": "lawmax/connector/1",
 "connector_id": "...", "version": "...",
 "accepts": {"jurisdictions": [...], "source_classes": [...], "media_types": [...]},
 "emits":   ["legal-source/1","raw-artifact/1","acquisition-receipt/1",
             "official-location/1","legal-relation/1","authority/1-proposal",
             "graph-event-proposal","uncertainty/1"],
 "determinism": "pure"}   # ίδια είσοδος ⇒ byte-ίδια έξοδος (SOURCE_DATE_EPOCH πειθαρχία)
```

Νόμοι:
1. **Μόνο κανονικά αντικείμενα εξόδου.** Κανένα connector-ιδιωτικό πεδίο,
   κανένα passthrough «extra». Ό,τι δεν χωρά στα schemas ⇒ uncertainty με το
   raw διατηρημένο. (Έτσι ΚΑΘΕ πηγή καταλήγει στο ΙΔΙΟ canonical object.)
2. **Κοινή σουίτα συμμόρφωσης**: κάθε connector περνά ΤΑ ΙΔΙΑ contract vectors
   (golden inputs → αναμενόμενα canonical objects, συμπεριλαμβανομένων
   αντιπαλικών: αμφίσημη ταυτότητα, λείπον official_key, αλλαγμένο digest) —
   gated στο Docker όπως κάθε σουίτα. Connector χωρίς πράσινη συμμόρφωση δεν
   υπάρχει στο μητρώο connectors.
3. **Προτάσεις, όχι εγγραφές**: connector ΔΕΝ γράφει στον version-graph ούτε
   στο authority registry — παράγει `*-proposal` αντικείμενα που περνούν από
   τα υπάρχοντα admission gates των εδρών (replay-then-append). Ο connector
   είναι αναγνώστης πραγματικότητας, όχι αρχή.
4. **Determinism gate**: διπλή εκτέλεση στο ίδιο input στο build ⇒ byte-ίδια
   έξοδος, αλλιώς η σουίτα κόκκινη.

---

## 8. Typed uncertainty — `lawmax/uncertainty/1` (η τίμια άγνοια ως αντικείμενο)

```
{"schema": "lawmax/uncertainty/1",
 "uncertainty_id": "unc1:" + canonical-hash(...),
 "kind": <closed:
   source-unverified        # δεν αποδεικνύεται ότι είναι επίσημη πηγή
 | identity-ambiguous       # ≥2 υποψήφια work_id, με τα υποψήφια ΤΥΠΩΜΕΝΑ
 | official-key-incomplete  # λείπει πεδίο του official_key
 | authority-unresolved     # εκδότης δεν αντιστοιχεί σε authority registry
 | relation-unproven        # σχέση χωρίς explicit-citation/operative-part
 | date-partial             # μερική ημερομηνία (typed: year | year-month)
 | source-integrity         # changed-digest στο ίδιο επίσημο URL
 | unclassified-source>,    # εκτός κλειστής τυπολογίας §2.3
 "subject": {"artifact_sha256" | "work_id" | "candidate_ids": [...]},
 "evidence": <τι ΞΕΡΟΥΜΕ — ποτέ κενό>,
 "blocking": <ποια παραγωγή μπλοκάρεται — π.χ. "work-id-mint" | "relation-record">}
```

- Uncertainty = πρώτης τάξης, journaled, ΟΡΑΤΟ στο /as-known στρώμα (υπάρχον
  τυπωμένο pending/uncertainty μονοπάτι Φ7-Π5) — όχι log line.
- Κάθε uncertainty έχει ΘΑΝΑΤΟ: επιλύεται μόνο με νέο evidence (νέο artifact,
  εγγραφή μητρώου, ρητή απόφαση δημιουργού), και η επίλυση είναι journaled
  γεγονός που δείχνει το evidence. Καμία σιωπηλή αυτοεπίλυση.

---

## 9. Καμία ΦΕΚ-ειδική δομή (απόδειξη με μηχανικό όρο)

- Το ΦΕΚ εμφανίζεται ΜΟΝΟ ως ΔΕΔΟΜΕΝΑ: εγγραφές `gazette-issue` με
  `official_key.series ∈ {"Α","Β",...}` από το registry της ελληνικής
  δικαιοδοσίας — ΚΑΝΕΝΑ πεδίο σχήματος, enum branch ή connector hook με
  σημασιολογία «ΦΕΚ».
- Μηχανικός όρος αποδοχής (θα γίνει gate): `grep -riE "fek|φεκ" <schemas &
  connector contract code>` επιστρέφει 0 εκτός από αρχεία ΔΕΔΟΜΕΝΩΝ registry
  και τα ήδη υπάρχοντα ΦΕΚ-parsing tests (που θα γίνουν connector επί του
  παρόντος contract, όχι παράλληλη διαδρομή).
- Το benchmark των 9 ΦΕΚ (Π7) εκτελείται ΩΣ ΠΕΛΑΤΗΣ του καθολικού contract:
  9 gazette-issue works μέσα από τον gr-gazette connector — ίδια διαδρομή που
  θα διανύσει κάθε μελλοντική πηγή.

---

## 10. Κριτήρια αποδοχής Π7-U.1 (πριν από ΚΑΘΕ connector/download)

1. Το παρόν εγκρίνεται ρητά («εγκρίνω Π7-U.1») ΜΕΤΑ από 2 αντιπαλικούς κριτές
   (νομικής ταυτότητας/πηγών + αρχιτεκτονικής/provenance) με ΟΛΑ τα ευρήματα
   κλειστά ή δηλωμένα υπόλοιπα με φάση θανάτου.
2. Schemas κλειστά: κάθε πεδίο typed, κάθε enum κλειστό, κάθε id παράγωγο.
3. Καμία δεύτερη έδρα: text-mutating relations ⇒ version-graph events ΜΟΝΟ·
   raw→text ⇒ extraction/normalization receipts ΜΟΝΟ.
4. Ο όρος §9 (μηδέν ΦΕΚ-ειδικά σχήματα) επαληθεύσιμος μηχανικά.
5. Τα Π7-U.2 (connector conformance vectors + gr-gazette connector) και Π7
   benchmark ΞΕΚΙΝΟΥΝ ΜΟΝΟ μετά από το 1.

## 11. Δηλωμένα όρια v1 (τίμια)

- Πολυγλωσσία expressions (ενωσιακό δίκαιο σε 24 γλώσσες): το schema τη χωρά
  (manifestation.language) αλλά ο κανόνας ισοδυναμίας expressions μεταξύ
  γλωσσών ΔΕΝ ορίζεται εδώ — μελλοντική versioned φάση.
- Redaction κανόνες (προσωπικά δεδομένα σε judgments): typed πεδίο
  `parties-redacted` υπάρχει· η πολιτική redaction είναι απόφαση δημιουργού.
- Το authority registry γεννιέται ΑΔΕΙΟ και γεμίζει ΜΟΝΟ με evidence-backed
  εγγραφές — η πληρότητά του είναι μετρήσιμη εκκρεμότητα, όχι υπόσχεση.
