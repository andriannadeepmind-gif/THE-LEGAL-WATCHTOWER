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
                    unicode-normalization: NFC δηλωμένο }
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
ταιριάζει ∧ (αν δηλώθηκε TRA) το TRA αναπαράγεται. `POST /verify-citation`
⇒ typed ετυμηγορία {valid | unknown-capsule | ambiguous-prefix |
span-out-of-range | quote-hash-mismatch | stale-known-at} — ΠΟΤΕ boolean.
Η ίδια φράση σε δύο σημεία ΔΕΝ συγχέεται: η ταυτότητα είναι το span.

### 1.4 Proof Bundle (PB) — πλήρης δέσμευση
```
pb/1 := { receipt (πλήρες LegalAuthorityReceipt), merkle-audit-path,
          receipt-set-root, release-root, graph-chain-head,
          transparency: { log-entry, consistency-proof },
          tsa-seal, protocol-version, verifier-hash, signer/key-epoch,
          witness-attestations[] (Φ10 — κενό μέχρι τότε, ΔΗΛΩΜΕΝΟ πεδίο),
          supersession: { superseded-by-avc | null, revoked: bool+λόγος } }
```
Η ανάκληση/υπερκάλυψη είναι ΜΕΣΑ στο proof αντικείμενο — καταναλωτής δεν
μπορεί να επικαλείται AVC αγνοώντας το supersession state.

Ροή: query → TRA → σταθερό AVC → CE στο ακριβές χωρίο → PB αποδεικνύει.

## 2. Πεπερασμένο static dump
Ανά release: ΟΛΑ τα AVCs (πεπερασμένα: μία εγγραφή ανά νομική έκδοση) +
condition/regime events + PBs + **resolution index** (ταξινομημένα
διαστήματα valid×recorded ανά provision ⇒ κάθε μελλοντικό query απαντιέται
offline ντετερμινιστικά χωρίς προ-υλοποίηση όλων των queries). ΚΑΝΕΝΑ
query-παραγόμενο αντικείμενο στο dump.

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
  ⇒ byte-identical pack.
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
Μετρικές ΜΟΝΟ ανά βαθμίδα τεκμηρίωσης: verified-integration (capsule
verification round-trip) > authenticated-client (token) > declared
User-Agent > inferred > unknown. Δήλωση «το μοντέλο Χ χρησιμοποιεί LAWMAX»
επιτρέπεται ΜΟΝΟ από τις δύο πρώτες βαθμίδες· τα User-Agents αναφέρονται
ως «declared», ποτέ ως απόδειξη. Append-only ledger (journal πρότυπο).

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
