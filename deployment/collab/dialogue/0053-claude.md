# [0053] Claude — ΣΧΕΔΙΟ P1.5 «Proof Spine» (planning only — καμία υλοποίηση χωρίς ρητό «εγκρίνω P1.5»)

**Ημερομηνία:** 2026-07-10 · Εντολή δημιουργού: «προχωρά στο επόμενο βήμα με
βλέμμα στον στόχο επίπεδο 7 εγγυημένα». Κατά την κλίμακα του [0040]:
P0✅ → P1✅ → P1R✅ → P1b✅(cloud) → **P1.5 Proof Spine** → … → P4 Receipt v0
→ P5 Kernel → **P7 Conformance (Level 7)**. Το P1.5 είναι Η σπονδυλική στήλη
πάνω στην οποία θα σταθούν τα Receipts (L6) και το ανοιχτό πρότυπο (L7).

## 0 · Προαπαιτούμενο (ΔΕΝ είναι μέρος του P1.5)
Το P1b εκκρεμεί owner-side: docker proof + `--attest-release <corpus> <ρητό-id>`
×6 (ids στο [0052]) + ρητή ετυμηγορία merge. Το P1.5 υλοποιείται ΜΟΝΟ πάνω σε
merged P1b.

## 1 · Το ΑΚΡΙΒΕΣ αποτυγχάνον proof στο τρέχον HEAD (683f43d9)

1. **Per-article μέλος-του-release**: το `article-005Α.jsonld` και το
   `article-005Α.html` δεν έχουν ΚΑΜΙΑ κρυπτογραφική σύνδεση με κανένα
   release — μόνο το TTL δένεται ΕΜΜΕΣΑ (SHA-512 → lineage-graph.ttl
   identityHash → Merkle root). Κανείς δεν μπορεί να αποδείξει offline
   «αυτό το jsonld/html ανήκει στο attested release Χ».
2. **Verify kit**: απαντά μόνο «το release είναι ακέραιο» (manifest/JWS/TSR/
   Merkle των 8 canonical) — ΔΕΝ απαντά «ανήκει ΤΟ ΑΡΘΡΟ Ψ στο release Χ;»
   (README-VERIFY: «basic checks» για shell, per-file inclusion μόνο για τα 8).
3. **PCL text spine ΑΔΕΤΟ**: το `corpus-proof.json` (Merkle root των in-force
   κειμένων, 124 leaves) ΔΕΝ συμμετέχει στο canonical set ⇒ δεν αποκτά ποτέ
   RFC-3161 χρόνο· και φέρει hardcoded `anchored_at "2025-01-01T00:00:00Z"`
   (πλαστός σταθερός χρόνος — ίδια κλάση με όσα σκοτώσαμε στο P1b).
4. **Δύο ασύνδετες σπονδυλικές**: text-spine (PCL: text→leaf→corpus root) και
   RDF-spine (TTL→lineage→release root) δεν αποδεικνύουν πουθενά ότι μιλούν
   για ΤΟ ΙΔΙΟ σώμα δικαίου στην ΙΔΙΑ στιγμή.

## 2 · Σχεδίαση (η ανώτατη σύλληψη — δομική, όχι φρουροί)

**Αρχή:** ΕΝΑ αντικείμενο-απογραφή δένει ΟΛΑ τα per-article artifacts στο
release id· ό,τι δένεται, επαληθεύεται offline από τον καθένα.

**(α) Artifact Census — νέο 9ο κανονικό αρχείο `artifact-census.json`**
Ντετερμινιστικό (jonathan, κανονική διάταξη articles-in-identity-order):
ανά άρθρο {canonical id, SHA-512(ttl), SHA-512(jsonld), SHA-512(html),
SHA-256 text-leaf (η ΙΔΙΑ τιμή με το PCL leaf)} + κεφαλίδα {corpus,
πλήθος, PCL corpus root, PCL algorithm}. Παράγεται στο deploy-epistemic
staging από τις ΙΔΙΕΣ έδρες (article-file-id, hash-authority, PCL
leaf-hash). Μπαίνει στο `+epistemic-canonical-files+` (8→9) ⇒ ο Merkle
root του release ΔΕΝΕΙ πλέον κάθε per-article artifact ΚΑΙ το text spine.
⇒ Το «ανήκει στο release» γίνεται ΔΟΜΙΚΑ αποδείξιμο, το PCL αποκτά
RFC-3161 χρόνο μέσω του attestation του release, και οι δύο σπονδυλικές
ενώνονται σε ΜΙΑ (ίδιο census = ίδιο σώμα δικαίου, ίδια στιγμή).

**(β) Θάνατος του hardcoded PCL χρόνου**: `anchored_at` στο corpus-proof/
MCP receipts → από require-deterministic-time· η ΧΡΟΝΙΚΗ ΑΠΟΔΕΙΞΗ όμως
δηλώνεται ρητά ως «μέσω release attestation» (το PCL δεν ξανα-ισχυρίζεται
δικό του χρόνο — μία αρχή χρόνου).

**(γ) Verify kit v2 — per-article verification (offline, Ironclad-only)**
`verify.lisp <release-dir> --article <path>`: recompute SHA-512/leaf →
εύρεση στο census → inclusion proof census→root → root ≡ dirname ≡
merkle-tree.json → TSR imprint binding. Έξοδος: ΜΕΛΟΣ/ΟΧΙ + πλήρης
αλυσίδα. Αυτό είναι το πρώτο δημόσιο πρόσωπο του Level 6 ελεγκτή — ο
πυρήνας που το P5 θα εξαγάγει αυτούσιο.

**(δ) Πύλες**: release-gate v2 — για ΚΑΘΕ sha256-release με census:
πλήρης επαλήθευση ΟΛΩΝ των per-article δεσμών (όχι δείγμα — ο ΥΠΕΡΤΑΤΟΣ
δεν δειγματοληπτεί)· legacy releases χωρίς census: δηλωμένα ως
προ-spine, ποτέ σιωπηλά πράσινα. + Νέο `proof-spine` lock στο standalone
loop (census ↔ αρχεία ↔ root ↔ tsr, με ΣΥΝΘΕΤΙΚΟ corpus).

**(ε) Ρητά όρια (δηλωμένα, με φάση θανάτου)**: πλήρης κρυπτογραφική
επαλήθευση TSR chain παραμένει P4+ (υπάρχον residual [0047])· τα
Receipts καθαυτά = P4· kernel ως αυτόνομο artifact = P5.

## 3 · Έδρες που αγγίζονται (ΜΙΑ ανά έννοια)
- `orchestrator-epistemic/release-manifest.lisp`: +census στο canonical set
  (Η έδρα του set — καμία δεύτερη λίστα).
- `orchestrator-epistemic/deploy-epistemic.lisp`: παραγωγή census στο staging
  (καταναλώνει hash-authority + PCL leaf-hash — όχι δικό της hashing).
- `source/proof-carrying.lisp`: leaf-hash μένει Η έδρα text-leaf· anchored_at
  → δηλωμένη αρχή.
- `orchestrator-cli/release-gate.lisp`: spine verification.
- `releases/*/verify/verify.lisp`: per-article mode.
- Tests: `tests/proof-spine-test.lisp` + επέκταση release-authority-test.

## 4 · Επιπτώσεις στα artifacts
Νέα releases ×6 με ΝΕΑ ids (το canonical set αλλάζει σύνθεση — τα υπάρχοντα
αμετάβλητα, append-only)· κανένα per-article artifact δεν αλλάζει byte.
Απόφαση χρόνου: τα τωρινά P1b commitments μπορεί (i) να attest-αριστούν πριν
(ιστορικός σταθμός) ή (ii) να μείνουν unattested-honest και να attest-αριστεί
απευθείας η γενιά census — **προτείνω (i)**: το ιστορικό αποκτά αδιάλειπτη
χρονική αλυσίδα.

## 5 · Αποδείξεις ολοκλήρωσης (θα κατατεθούν με αριθμούς)
Build/loop/πύλες όλα πράσινα · proof-spine lock N/N · release-gate: κάθε νέο
release πλήρως spine-verified · verify kit: θετικό ΚΑΙ αρνητικό (πειραγμένο
artifact ⇒ ΟΧΙ-ΜΕΛΟΣ ονομαστικά) · cross-path: pipeline ≡ cut-release ίδιο id
με census · determinism ×2.

## 6 · Αποφάσεις που ζητούνται από τον δημιουργό
1. «εγκρίνω P1.5» (μετά το P1b merge) — ή διορθώσεις στο σχέδιο.
2. Επιλογή (i)/(ii) του §4 για τη χρονική αλυσίδα.
3. Επιβεβαίωση: census μορφή JSON (πρόταση: ναι — jonathan, μία σειρά,
   μηχανικά ελέγξιμο από το kit χωρίς TTL parser).

Rollback: revert commit — κανένα υπάρχον release δεν πειράζεται (append-only
εκ κατασκευής). Δεν ανοίγει: P2/P3/P4/P5/FF4/Ω+ — μόνο ό,τι περιγράφεται εδώ.
