# [0090] GAAF-1 — Global AI Authority Fabric (αναθεώρηση του GAAF-0 κατά την ετυμηγορία δημιουργού)

Κατάθεση: Claude, 2026-07-14. Καθεστώς: ΣΧΕΔΙΟ — «design baseline δεκτό,
υλοποίηση ΔΕΝ εγκρίνεται» ισχύει μέχρι ρητό «εγκρίνω GAAF-1». Αντικαθιστά
το GAAF-0 (0089) ως προς την αρχιτεκτονική· το 0089 μένει ως ιστορικό.

## 1. Η θεμελιώδης διόρθωση: ΤΕΣΣΕΡΑ αντικείμενα, όχι ένα query-capsule

Το GAAF-0 όριζε ένα content-addressed capsule ανά (διάταξη × valid-at ×
known-at) — ασταθές id, άπειρο dump, καμία μόνιμη αναφορά. Το GAAF-1 το
αντικαθιστά με τέσσερα ΧΩΡΙΣΤΑ αντικείμενα:

### 1.1 Authority Version Capsule (AVC) — ΑΜΕΤΑΒΛΗΤΟ
Ένα ανά (νομική έκδοση × release). ΔΕΝ περιέχει query χρόνους.
```
avc/1 := {
  protocol      : "gaaf/1"
  provision     : { provision-id (typed, orchestrator.identity κανονική
                    σειριοποίηση «gr/nomos/2019/4619#art:5/par:2»),
                    provision-uri, lang }
                  ; Φ8-ready: το provision-id ΕΙΝΑΙ path-based (article→
                  ; paragraph→point→edafio ήδη στην έδρα)· ΟΧΙ article-only
  version       : { version-id (semantic hash έδρας), valid-from,
                    valid-until|open, effective (date | (:conditional cid)) }
  text          : { content, content-hash sha256, canonicalization: JCS,
                    unicode-normalization: NFC ΕΠΙΒΕΒΛΗΜΕΝΟ — πύλη
                    κατασκευής content == NFC(content), counter
                    non_nfc_content=0 (κλείσιμο Α3-2)·
                    unicode-version: καρφωμένη στο protocol + ίδια στον
                    ανεξάρτητο verifier μέσω conformance vectors (Α3-3) }
  provenance    : { source (ΦΕΚ ref), source-digest, import-commit }
                  ; επεκτάσιμο πεδίο provenance/2 όταν κλείσει το Φ8:
                  ; artifact-id, page, bbox, byte/unicode span, extractor-hash,
                  ; ocr-engine-hash, normalization transforms, correction receipts
  rights        : rights-manifest/1 (βλ. §5 — ΑΝΑ ΣΥΣΤΑΤΙΚΟ, όχι ενιαίο)
  avc-id        : sha256(JCS όλων των ανωτέρω)   ; σταθερό για πάντα
}
```
### 1.2 Temporal Resolution Attestation (TRA) — ανά ερώτημα, ΧΩΡΙΣ νέο κλειδί
```
tra/1 := { protocol, corpus-id, valid-at, known-at, resolved-avc-id,
           in_force: true|false, basis, sat-καταστάσεις ανά condition-id,
           τέμνοντα regime-edge-ids, scoped δηλώσεις,
           release-root, graph-chain-head, verifier-hash, tra-hash }
```
Deterministic certificate (Φ7 spec v3 §6): ΚΑΝΕΝΑ online private key —
ο ανεξάρτητος verifier ΑΝΑΠΑΡΑΓΕΙ το TRA από το offline-υπογεγραμμένο
release root + τον journaled γράφο + τον canonical verifier και συγκρίνει
byte-wise. Το TRA ΔΕΙΧΝΕΙ στο σταθερό AVC — δεν το αντιγράφει.
**Αγκύρωση/φρεσκάδα/βήμα-0 (κλείσιμο κριτή Β Α1-1/Α1-2/Α1-3)**: έγκυρο
TRA ⇔ graph-chain-head = census-δεσμευμένο graph_root ΥΠΟΓΕΓΡΑΜΜΕΝΟΥ
release στο transparency log (unsigned journal suffix ⇒ απόρριψη)· typed
`assurance: release-anchored | provisional-unanchored` (το δεύτερο ΠΟΤΕ
«verified»)· το tra/1 αποκτά πεδία `transparency-entry` +
`consistency-proof` + `max-age`· ΥΠΟΧΡΕΩΤΙΚΟ βήμα 0: verifier-hash κατά
το canonical set του υπογεγραμμένου release (αλλιώς κυκλική βεβαίωση =
ΑΚΥΡΗ). **Αρνητικές εκβάσεις (Β-3)**: tra/1 φέρει ΠΑΝΤΑ `provision` +
`outcome ∈ {resolved(avc-id), no-version-in-force,
not-yet-effective(cid,since), uncertain(λόγος)}` — resolved-avc-id
nullable ΜΟΝΟ εκτός resolved· και οι αρνητικές απαντήσεις δεσμεύονται
στο release root. Επίσης: `tra-id = sha256(JCS tra)` και πεδίο protocol.

### 1.3 Citation Envelope (CE) — ακριβές χωρίο, όχι substring
```
ce/1 := { avc-id (ΠΛΗΡΕΣ hash — prefix ΜΟΝΟ ως display, resolver απαιτεί
          μοναδικότητα αλλιώς 409-κλάση άρνηση),
          span: { unicode-scalar-start, unicode-scalar-end },
          quote-hash: sha256(NFC bytes του span),
          context-before/after (προαιρετικά, k scalars),
          tra-hash (ποια χρονική επίλυση το θεμελίωσε) }
```
Έγκυρη παράθεση ⇔ resolver βρίσκει το AVC ∧ το span υπάρχει ∧ quote-hash
ταιριάζει ∧ (αν δηλώθηκε TRA) το TRA αναπαράγεται ∧ **το supersession
state του AVC κατά το ΝΕΟΤΕΡΟ γνωστό release είναι καθαρό (κλείσιμο Β
Α2-1 — ο έλεγχος PB/supersession είναι ΜΕΡΟΣ του ορισμού εγκυρότητας,
όχι προαιρετικός)**. `POST /verify-citation` ⇒ typed ετυμηγορία
{valid | unknown-capsule | ambiguous-prefix | span-out-of-range |
quote-hash-mismatch | stale-known-at | **superseded | revoked**} +
πεδίο `checked-against-root` (κατά ποιο release κρίθηκε) — ΠΟΤΕ boolean.
`stale-known-at` ⇔ νεότερο γνωστό release περιέχει
supersession/retract που αλλάζει την απάντηση για τη δηλωμένη τομή.
**quote-hash — ΑΚΡΙΒΗΣ ορισμός (κλείσιμο Α3-1)**: sha256 των UTF-8 bytes
του scalar range [start,end) ΟΠΩΣ ΚΕΙΤΑΙ στο AVC content (in situ) — ο
verifier ΔΕΝ επανακανονικοποιεί ΠΟΤΕ το απόσπασμα (το NFC substring δεν
είναι NFC-σταθερό)· η καθολική NFC μορφή εξασφαλίζεται ΜΙΑ φορά, στην
πύλη κατασκευής του AVC. ce/1 αποκτά πεδία `protocol` + `ce-id =
sha256(JCS ce)` (κλείσιμο Β-5)· context-before/after: ≤64 scalars ανά
πλευρά, ΕΚΤΟΣ hash — μόνο display. Η ίδια φράση σε δύο σημεία ΔΕΝ
συγχέεται: η ταυτότητα είναι το span.

### 1.4 Proof Bundle (PB) — πλήρης δέσμευση
```
pb/1 := { receipt (πλήρες LegalAuthorityReceipt), merkle-audit-path,
          receipt-set-root, release-root, graph-chain-head,
          transparency: { log-entry, consistency-proof },
          tsa-seal, protocol-version, verifier-hash, signer/key-epoch,
          witness-attestations[] (Φ10 — κενό μέχρι τότε, ΔΗΛΩΜΕΝΟ πεδίο),
          supersession: { superseded-by-avc | null, revoked: bool+λόγος } }
```
Η ανάκληση/υπερκάλυψη είναι ΜΕΣΑ στο proof αντικείμενο ΚΑΙ μέσα στον
ορισμό εγκυρότητας παράθεσης (§1.3). **Φρεσκάδα (κλείσιμο Α2-2)**: το
pb/1 αποκτά `pb-id = sha256(JCS pb)` + `as-of-release-root` — δύο PB
ίδιου receipt σε διαδοχικά releases είναι διακριτά, διευθυνσιοδοτήσιμα
αντικείμενα· το supersession state ισχύει ΡΗΤΑ «κατά το as-of-release»,
ποτέ ως απόλυτο· καταναλωτές οφείλουν σύγκριση με το νεότερο γνωστό
checkpoint (≥1 ανεξάρτητο κανάλι), τα offline dumps συνοδεύονται από
append-only **revocation/supersession feed** ανά release + max-age
πολιτική. Δηλωμένο όριο: απόλυτη offline φρεσκάδα μη αποφασίσιμη —
δηλώνεται, δεν αποσιωπάται.

Ροή: query → TRA → σταθερό AVC → CE στο ακριβές χωρίο → PB αποδεικνύει.

## 2. Πεπερασμένο static dump
Ανά release: ΟΛΑ τα AVCs (πεπερασμένα: μία εγγραφή ανά νομική έκδοση) +
condition/regime events + PBs + revocation feed + **resolution index**
(ταξινομημένα διαστήματα valid×recorded ανά provision). ΚΑΝΕΝΑ
query-παραγόμενο αντικείμενο στο dump. **Όρια/κριτήρια (κλείσιμο Α4-1)**:
(α) ο index είναι ΠΡΟΒΟΛΗ, όχι δεύτερη έδρα — δεσμευτικό κριτήριο
αποδοχής (gate): «index-απάντηση ≡ canonical fold-απάντηση για ΚΑΘΕ
ορθογώνιο (valid-at × known-at)», με property tests σε τυχαία
δειγματοληψία + πλήρη κάλυψη οριακών σημείων· (β) καλύπτει τις
scope-ΑΝΕΞΑΡΤΗΤΕΣ απαντήσεις — scoped ερωτήματα απαιτούν την πλήρη
verifier λογική + τα scope δεδομένα, που ΠΕΡΙΛΑΜΒΑΝΟΝΤΑΙ στο dump
(δηλωμένο, όχι σιωπηλό)· (γ) το dump φέρει typed `knowledge-horizon`
(= τέλος journal του release): query με known-at > horizon ⇒ typed
`beyond-horizon`, ΠΟΤΕ σιωπηλό «τρέχον».

## 3. Universal Retrieval Surface (πλήρης — έλειπε από το GAAF-0)
- **HTML χωρίς JavaScript** ανά provision/version — canonical URLs, το
  κείμενο ΣΤΟ HTML, ELI/Schema.org/citation metadata, εσωτερικά links
  act→article→version→amendment→source.
- **Content negotiation** από ΜΙΑ typed projection έδρα: JSON (AVC/TRA),
  JSON-LD, RDF/Turtle, Akoma Ntoso, JSONL/Parquet dumps, plain text,
  Markdown. Ίδιο αντικείμενο, προβολές — ποτέ δεύτερη παραγωγή.
- **OpenAPI 3.1** πλήρες συμβόλαιο + δημοσιευμένα JSON Schemas των
  avc/1, tra/1, ce/1, pb/1 (protocol versioning ρητό σε ΚΑΘΕ αντικείμενο).
- **MCP server**: resources `lawmax://gr/{body}/{provision}[/at/{date}]`,
  tools resolve_legal_reference / get_provision_at / get_as_known /
  diff_versions / trace_amendment / verify_receipt / verify_citation /
  build_citation, subscriptions στο changes feed.
- **AI Context Packs**: deterministic πακέτα ανά (provision, budget) —
  compact/standard/complete/proof/change· ίδια inputs + ίδιο release root
  ⇒ byte-identical pack. **Η συνάρτηση επιλογής ΟΡΙΖΕΤΑΙ (κλείσιμο Β-8)**:
  σταθερή λίστα πεδίων ανά βαθμίδα + κανόνας περικοπής σε όρια προτάσεων
  κατά δηλωμένη σειρά προτεραιότητας — spec στο GAAF-Π4 με gate:
  byte-identity ΚΑΙ field-list conformance, όχι μόνο ντετερμινισμός.
- **Sync**: append-only changes feed με robust cursor = (release-root,
  journal-seq) — όχι timestamps· WebSub/IndexNow/sitemaps/Atom στο publish.
- **Distribution**: κάθε release ταυτόχρονα σε canonical domain + GitHub
  release + dataset mirrors (HF/Zenodo/DOI για major) + content-addressed
  mirror — ΟΛΑ με το ΙΔΙΟ release-root (mirror root parity gate = 0 αποκλίσεις).
- **SDK/adapters** (Π-φάση μετά τα πρωτόκολλα): λεπτά clients που
  ΔΙΑΤΗΡΟΥΝ το AVC/CE μέχρι την τελική απάντηση — «text-only» απόσπαση
  δεν είναι δυνατή μέσω των δικών μας SDKs (το evidence object είναι η
  μονάδα, όχι το string).

## 4. Crawler policy (τυποποιημένη κατά σκοπό)
robots.txt + ai-policy.json: search bots (OAI-SearchBot, Claude-SearchBot,
Googlebot, Bingbot) = allow· user-retrieval (ChatGPT-User, Claude-User) =
allow· training bots (GPTBot, ClaudeBot) = ΑΠΟΦΑΣΗ ΔΗΜΙΟΥΡΓΟΥ (στρατηγικό
trade-off, δεν προαποφασίζεται εδώ)· aggressive scrapers = throttle.
Κάθε response: Link rel=license + rel=verify.

## 5. Rights manifest — ΑΝΑ ΣΥΣΤΑΤΙΚΟ (τέλος το ενιαίο «All Rights Reserved»)
```
rights-manifest/1 := ανά συστατικό {official-text, verified-consolidation,
  temporal-reconstruction, provenance-data, ontology, commentary,
  benchmark-material} → { origin, license: ΕΚΚΡΕΜΕΙ-ΑΠΟΦΑΣΗ|συγκεκριμένη,
  attribution (official πάντα εμφανές· editorial: Δαυίδ Σπυρίδων
  Σταυρόπουλος), citation-terms }
```
Καμία τιμή license δεν παγιώνεται εδώ — δένει με τη Deferred License
Policy Decision του δημιουργού (η υπερ-περιοριστική άδεια είναι ΚΑΙ
στρατηγικός κίνδυνος υιοθέτησης — δηλωμένο trade-off προς απόφαση).

## 6. Benchmark — ΔΥΟ στρώματα (τέλος η κυκλικότητα)
- **Protocol Conformance Benchmark**: καταναλώνει το AI σωστά τα
  αντικείμενα GAAF; (resolve, temporal query, citation validity,
  abstention) — ground truth = τα δικά μας receipts, ΔΗΛΩΜΕΝΑ κυκλικό ως
  προς τη νομική αλήθεια, μετρά ΜΟΝΟ κατανάλωση.
- **Independent Legal Truth Benchmark**: ground truth από official source
  bytes + ΔΙΠΛΗ ανεξάρτητη νομική επισήμανση + adjudication τρίτου +
  hidden held-out set — ανεξάρτητο από LAWMAX outputs· ο LAWMAX
  βαθμολογείται ΚΑΙ ο ίδιος σε αυτό (μπορεί να αποτύχει — αυτό είναι το
  νόημα). Απαιτεί τα 9 ΦΕΚ + νομικούς επισημειωτές (απόφαση δημιουργού).

## 7. Observatory — evidence-tiered
Μετρικές ΜΟΝΟ ανά βαθμίδα τεκμηρίωσης: verified-integration =
**authenticated client ΠΟΥ ΚΑΙ επαληθεύει** (το round-trip χωρίς
αυθεντικοποίηση αποδεικνύει ότι ΚΑΠΟΙΟΣ επαλήθευσε, όχι ΠΟΙΟΣ — κλείσιμο
Β-9) > authenticated-client (token, χωρίς verification) > declared
User-Agent > inferred > unknown. Δήλωση «το μοντέλο Χ χρησιμοποιεί
LAWMAX» επιτρέπεται ΜΟΝΟ από τις δύο αυθεντικοποιημένες βαθμίδες· τα
User-Agents αναφέρονται ως «declared», ποτέ ως απόδειξη ταυτότητας
δράστη. Append-only ledger (journal πρότυπο).

## 8. Ακολουθία (μετά από «εγκρίνω GAAF-1», ανά φάση, επταπλό συμβόλαιο)
GAAF-Π1 πρωτόκολλα avc/tra/ce/pb + schemas + verifier επέκταση →
Π2 AVC παραγωγή + resolution index + dump → Π3 retrieval surface
(HTML/negotiation/OpenAPI) → Π4 MCP + context packs → Π5 feeds/mirrors →
Π6 citation contract runtime → Π7 crawler/rights (μετά license απόφαση) →
Π8 benchmarks → Π9 observatory. Προαπαιτούμενα: Φ7 Π2-Π7 (in_force/sat),
Φ8 για provenance/2 και sub-article spans (τα σχήματα είναι ΕΤΟΙΜΑ να τα
δεχθούν — τίποτα δεν παγιώνει article-only), Deferred License Policy.

## 9. Κλείσιμο των 11 σημείων της ετυμηγορίας (ονομαστικά)
1 ασταθές capsule-id → AVC αμετάβλητο + TRA χωριστό (§1). 2 άπειρο dump →
resolution index (§2). 3 article-only identity → typed provision-id
path-based από την έδρα (§1.1)· Φ8-ready. 4 substring citation → CE με
unicode spans + quote-hash + full-hash resolver (§1.3). 5 ελλιπές proof
binding → pb/1 με release/graph/consistency/key-epoch/witness/supersession
(§1.4). 6 ενιαία άδεια → rights-manifest/1 ανά συστατικό, license
ΕΚΚΡΕΜΕΙ-ΑΠΟΦΑΣΗ (§5). 7 κυκλικό benchmark → δύο στρώματα (§6).
8 observatory ταυτότητες ≠ αποδείξεις → βαθμίδες τεκμηρίωσης (§7).
9 ελλιπές retrieval/distribution → §3 πλήρες. 10 protocol versioning →
ρητό πεδίο σε κάθε αντικείμενο + domain-separated ids. 11 online release
key → ΔΕΝ υπάρχει: TRA deterministic certificate (§1.2, Φ7 v3 §6).
