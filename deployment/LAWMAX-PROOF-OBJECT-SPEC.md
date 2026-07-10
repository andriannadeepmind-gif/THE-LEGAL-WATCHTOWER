# LAWMAX — PROOF OBJECT & ARTIFACT CENSUS SCHEMA (P1.4 [0054]#6)
**Specification-only.** Τυπικό, υλοποίηση-ανεξάρτητο σχήμα των αντικειμένων
απόδειξης, ΠΡΙΝ γεννηθεί το P1.5 census (αλλιώς το κενό επαναλαμβάνεται σε
id-δεσμευτικό αρχείο). Πρότυπο: De Bruijn criterion (μικρός ανεξάρτητος
ελεγκτής), proof-carrying code, RFC 6962 inclusion/consistency proofs. Δεμένο
στο Σύνταγμα ως `:proof-object`. Είναι ο σκελετός που θα ελέγχει ο L6 kernel
(P5) και θα δημοσιοποιεί το L7 conformance.

## 0 · Αρχή
Ένα proof object περιέχει **το ίδιο το αντικείμενο απόδειξης** (όχι απλώς
claim+hash+signature): αρκετά ώστε ΤΡΙΤΟΣ να ΞΑΝΑΫΠΟΛΟΓΙΣΕΙ και να
επιβεβαιώσει ΧΩΡΙΣ να μας εμπιστευτεί. Trust ΜΟΝΟ στα μαθηματικά + στο
ΦΕΚ-δέσιμο. Ο ελεγκτής είναι ΜΙΚΡΟΣ (LOC-ceiling gate, P5) ώστε να τον
audit-άρει ο καθένας σε ένα απόγευμα.

## 1 · Merkle criterion (ΜΙΑ έδρα, RFC-6962)
ΟΛΑ τα Merkle δέντρα του συστήματος υπακούν σε ΕΝΑ κανόνα (ενοποίηση στο
P1.5· σήμερα η `proof-carrying.lisp` συμμορφή, η `merkle-tree.lisp` όχι):
- **leaf** = SHA-256( 0x00 ‖ bytes ) — domain separation
- **node** = SHA-256( 0x01 ‖ left ‖ right ) — domain separation
- περιττός κόμβος: **unbalanced split** (RFC-6962), ΟΧΙ duplicate-last
  (η κλάση CVE-2012-2459: διαφορετικά φύλλα ⇒ ίδιο root).
Χωρίς domain separation ένα 64-byte φύλλο είναι second-preimage εσωτερικού
κόμβου — απαράδεκτο όταν εκδίδουμε inclusion proofs σε τρίτους.

## 2 · Artifact Census (9ο κανονικό αρχείο, P1.5) — σχήμα
```
{
  "version": "census-1",
  "corpus": "<short_name>",
  "count": <int>,
  "merkle": { "leaf": "sha256/0x00", "node": "sha256/0x01", "odd": "rfc6962-split" },
  "pcl_text_root": "sha256:<hex>",        // ← ενώνει την text-σπονδυλική
  "prev_release_root": "sha256:<hex>|null", // ← anti-equivocation (hash chain, [0054]Θ5)
  "materials": {                           // ← in-toto-class provenance (P1.5#3)
    "git_commit": "<sha>",
    "deps_lock": "sha256:<hex>",
    "sbcl_version": "<x.y.z>",
    "base_image": "sha256:<digest>|null"
  },
  "articles": [
    { "id": "<canonical π.χ. 5Α>",         // ← article-uri-id (μία έδρα)
      "ttl":   "sha512:<hex>",
      "jsonld":"sha512:<hex>",
      "html":  "sha512:<hex>",
      "text_leaf": "sha256:<hex>" }        // ← ΙΔΙΑ τιμή με το PCL leaf
    , …                                    // articles-in-identity-order (ντετ.)
  ]
}
```
Ο Merkle root του release (canonical set 8→9) δένει το census ⇒ ΚΑΘΕ
per-article artifact + το text-spine + το prev-root αποκτούν RFC-3161 χρόνο
μέσω του attestation του release. Οι δύο σπονδυλικές (RDF + κείμενο) γίνονται
ΜΙΑ.

## 3 · Legal Proof Receipt (P4) — 16 πεδία (από [0040], εδώ τυπικά)
`legal_object_ids` (πρώτο — γι' αυτό το P0/P1b) · `sources` (ΦΕΚ, εκδόσεις,
digests) · `as_of_date` (valid-time) · `recorded_at` (transaction-time —
[0054]#7, ΗΔΗ captured) · `interpretive_profile` · `factual_assumptions` ·
`reasoning_steps` (το proof object) · `merkle_inclusion` (article→census→
release root) · `temporal_anchor` (RFC-3161) · `kid`+`alg`+`key_lineage`
(§ key-lifecycle) · `known_ambiguity` **ΥΠΟΧΡΕΩΤΙΚΟ, ποτέ σιωπηλά κενό** ·
`residual_discretion` · `verifier_ref` (ποιος kernel/έκδοση) · `prev_receipt`
(αλυσίδα) · `signature`.
**Απαγορευμένες διατυπώσεις:** «absolute truth / only source / proves all
cases / X% νίκη». Επιτρεπτή: «machine-checkable legal conclusion under
explicitly declared sources, versions, factual assumptions, interpretive
rules, and proof obligations».

## 4 · Kernel επαλήθευσης (P5) — συμβόλαιο
- Δέχεται: proof object + source bytes + out-of-band pinned root.
- Επαληθεύει: Merkle inclusion (RFC-6962), υπογραφή (kid→pinned key),
  RFC-3161 χρόνο, ΦΕΚ-δέσιμο.
- ΔΕΝ παράγει: μόνο ελέγχει (η παραγωγή = ιδιωτική μηχανή — moat).
- **LOC-ceiling gate**: ο kernel ≤ N γραμμές (auditability)· δεύτερη
  ανεξάρτητη υλοποίηση (kernel diversity) = L7.

## 5 · Ρητή απόρριψη ψευδο-ανωτέρων (αξιώματα αποστολής)
- **ZK-SNARK/STARK**: κρύβουν τον συλλογισμό + trusted setup — η αποστολή
  είναι να ΔΕΙΧΝΕΙ τον συλλογισμό. Το Merkle selective disclosure (αποκάλυψη
  μόνο των αναγκαίων φύλλων) είναι ανώτερο ΓΙΑ ΤΗΝ ΑΠΟΣΤΟΛΗ.
- **W3C VC 2.0/DID ως CORE**: JSON-LD canonicalization στο έμπιστο μονοπάτι
  αντί ελεγκτή λίγων γραμμών — ΜΟΝΟ ως προαιρετικό envelope μεταφοράς (L5/L7).
- **LLM-as-judge / LLM proof generation**: LLM στο trusted path — ΑΠΟΡΡΙΠΤΕΤΑΙ.

## 6 · Κατάσταση
✅ recorded_at captured (P1.4#7) · ✅ ταυτότητα μία έδρα (P0/P1b) · ✅ PCL
RFC-6962-συμμορφή έδρα υπάρχει · ▷ P1.5: census + RFC-6962 ενοποίηση +
prev-root + materials · ▷ P4: Receipts · ▷ P5: kernel extraction + LOC gate.
Υλοποίηση ΜΟΝΟ με ρητό «εγκρίνω» ανά φάση.
