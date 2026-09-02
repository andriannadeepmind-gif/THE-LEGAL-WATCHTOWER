# LAWMAX — THREAT MODEL (P1.4 [0054]#5)
**Specification-only.** Ορίζει ρητά τον αντίπαλο ώστε η «μη-διαψευσιμότητα
εντός πεδίου» να είναι μετρήσιμη, όχι σύνθημα. Πρότυπο: TUF/in-toto attack
taxonomy + Certificate Transparency split-view. Δεμένο στο Σύνταγμα ως
`:threat-model`. Ένας δημόσιος Level-6 verifier χωρίς δηλωμένο αντίπαλο =
ψευδο-βεβαιότητα.

## 0 · Ορισμός νίκης του συστήματος
**Μη-διαψευσιμότητα εντός πεδίου:** για να πείσει τρίτο ότι το LAWMAX είπε
κάτι διαφορετικό/λάθος, ο αντίπαλος πρέπει είτε (α) να σπάσει SHA-256/την
υπογραφή, είτε (β) να αλλάξει τον ίδιο τον δημοσιευμένο νόμο (ΦΕΚ). Καμία
άλλη οδός δεν επιτρέπεται να είναι αόρατη.

## 1 · Περιουσιακά στοιχεία (τι προστατεύουμε)
Α1 ταυτότητα άρθρου · Α2 αυθεντικό κείμενο (ΦΕΚ-δεμένο) · Α3 in-force
κατάσταση σε ημερομηνία · Α4 απόδειξη συλλογισμού (proof object) · Α5
αδιάσπαστο ιστορικό εκδόσεων · Α6 ιδιωτικά κλειδιά · Α7 η ίδια η μηχανή
παραγωγής (23 πύλες, γράφος, temporal engine).

## 2 · Αντίπαλοι
Ε1 εξωτερικός πλαστογράφος (χωρίς κλειδιά) · Ε2 κακόβουλος διανομέας/mirror ·
Ε3 συμβιβασμένο κλειδί · Ε4 κακόβουλος εκδότης (ο ΙΔΙΟΣ ο θεσμός σε split-view) ·
Ε5 κλέφτης-αντιγραφέας (θέλει να ρεπλικάρει το moat) · Ε6 network/proxy MITM.

## 3 · Απειλές × κατάσταση άμυνας

| # | Απειλή (TUF/CT taxonomy) | Άμυνα ΣΗΜΕΡΑ | Κατάσταση |
|---|---|---|---|
| Θ1 | **Arbitrary content** (πλαστό άρθρο) | content-addressed id = Merkle root· recompute-before-trust | ✅ δομικό |
| Θ2 | **Overwrite ιστορικού release** | ταυτότητα = περιεχόμενο ⇒ overwrite αδύνατο· append-only | ✅ δομικό |
| Θ3 | **Rollback** (σερβίρισμα παλιού latest) | promote-latest! θέλει attested | ⚠ ΚΕΝΟ μονοτονίας/φρεσκάδας → TUF timestamp/snapshot (P4) |
| Θ4 | **Freeze** (παγωμένο latest για πάντα) | — | ⚠ ΚΕΝΟ → TUF timestamp λήξης (P4) |
| Θ5 | **Split-view / equivocation** (διαφορετικό ιστορικό σε διαφορετικούς) | git repo (όχι κρυπτογραφικά στα artifacts) | ⚠ → prev-release-root στο census (P1.5) + CT-log (P4+) |
| Θ6 | **Mix-and-match** (ανάμεικτα αρχεία διαφορετικών releases) | Merkle root δένει το canonical set· P1.5 census δένει ΚΑΙ per-article | ◐ πλήρες με P1.5 |
| Θ7 | **Ψευδο-υλικό επαλήθευσης** (fake tsa-ca) | ASN.1 gate + honest note (P1.4#1) | ✅ ΕΓΙΝΕ |
| Θ8 | **Silent key genesis** (per-run trust root) | fail-closed (P1.4#3) | ✅ ΕΓΙΝΕ |
| Θ9 | **Κυκλικό trust bootstrap** (public.jwk μέσα στο release) | — | ⚠ → out-of-band pinned root (P1.5 verify-kit-v2) |
| Θ10 | **Πλαστός χρόνος** (fabricated anchored_at) | require-deterministic-time· RFC-3161 multi-TSA· honest anchored_at (P1.5) | ◐ πλήρες TSR crypto = P4 (δηλωμένο) |
| Θ11 | **Ακανονικοποίητα bytes σφραγισμένα** (NFC) | NFC ⇒ ΣΦΑΛΜΑ και στις 2 έδρες | ✅ ΕΓΙΝΕ ([0052]+[0054]) |
| Θ12 | **Κλοπή moat** (αντιγραφή δεδομένων) | ο κλέφτης ΔΕΝ εκδίδει έγκυρα receipts (χωρίς prover/κλειδιά)· RFC-3161 anchors αποδεικνύουν αρχαιότητα | ✅ σχεδιακό (ισχυρότερο με P4 receipts) |
| Θ13 | **LLM δηλητηρίαση** (μοντέλο στο έμπιστο μονοπάτι) | κανένα LLM στο trusted path (αξίωμα)· τίμια άγνοια | ✅ δομικό |
| Θ14 | **Network MITM** | HTTPS + CA bundle· τα artifacts self-verifying offline | ✅ (η επαλήθευση δεν χρειάζεται δίκτυο) |
| Θ15 | **Αλγοριθμική απαξίωση / harvest-now-forge-later** (Ed25519/SHA-256 σπάνε σε βάθος δεκαετιών· ιστορικά υπογεγραμμένα αντικείμενα γίνονται πλαστογραφήσιμα· long-term evidence forgeability) | versioned suite registry + crypto-policy epochs + hybrid classical/PQ (ML-DSA-65, AND) + downgrade resistance + **archival evidence-renewal chains** (re-anchor ΠΡΙΝ το `sunset_at`) | ⚠ ΚΕΝΟ → MLTP v3 §14 (POST-C2, **design-only**) |
| Θ16 | **Αναδρομική ακύρωση οντολογίας / σιωπηλό schema drift** (shapes του 2027 ακυρώνουν αναδρομικά συμμόρφωση του 2025· ή σιωπηλή μετάλλαξη ιστορικού validation receipt) | content-addressed ontology bundles + receipts δεσμευμένα στο ακριβές `shapes_graph_digest`· revalidation ⇒ **νέο** receipt· καμία σιωπηλή μετάλλαξη ιστορικού | ⚠ ΚΕΝΟ → MLTP v3 §2.11 (POST-C2, **design-only**) |
| Θ17 | **Nation-state single-zone compromise** (κρατικός αντίπαλος καταλαμβάνει μία μηχανή/υπηρεσία/cloud/διαχειριστή/κλειδί και επιχειρεί να παραγάγει canonical public legal authority) | **compromise-tolerant**: threshold owner root (FROST 3-of-5) + n-of-m PQ multisig σε **ανεξάρτητες** custody/failure domains· απομονωμένες security cells· offline/HSM root· proposer-blind M5· dual independent compilers· append-only journal + ≥2 cross-client witnesses· fail-closed publication· πλήρης revocation/recovery/rebuild. **Παραβίαση μίας ζώνης ΔΕΝ παράγει canonical authority· η αλλοίωση είναι ανιχνεύσιμη, περιορισμένη, αναστρέψιμη.** ΟΧΙ «unhackable» (μη αποδείξιμο) | ⚠ ΚΕΝΟ → v1.4 §4.22 + MLTP §10/§14 (POST-C2, **design-only**) |
| Θ18 | **Untrusted input → code execution** (external bytes γίνονται Lisp forms μέσω reader/macro/eval· read-time execution· ontology poisoning) | `SECURE-SEMANTIC-INGRESS-CONTRACT`: external bytes ≠ Lisp forms· διακριτός αγωγός `opaque bytes → sandboxed parser → ingress-envelope/1 (JSON/CBOR) → non-evaluating schema decoder → typed DTO`· **κανένα εξωτερικό byte στον `cl:read`** (`safe-read.lisp` = internal-only)· taint states· SIK-1..9 **UNEXECUTED** | ⚠ ΚΕΝΟ → `LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md` (POST-C2, **design-only**) |

## 4 · Παραδοχές (ρητές, μη-αποδεδειγμένες)
- SHA-256 / RSA-4096 (→Ed25519) δεν σπάνε **εντός του τρέχοντος ορίζοντα** — η
  παραδοχή είναι **χρονικά φραγμένη**: πέρα από τον ορίζοντα ισχύει το Θ15
  (cryptographic agility & long-term evidence preservation, MLTP v3 §14), όχι η
  αιώνια ισχύς της παραδοχής.
- Οι RFC-3161 TSA δεν συμπαιγνιούν ΟΛΕΣ (γι' αυτό ≥3 ανεξάρτητες).
- Ο κυρίαρχος κρατά τα ιδιωτικά κλειδιά ασφαλή (§ key-lifecycle).
- Το ΦΕΚ/η πηγή είναι αυθεντική (αποδεικνύουμε δέσιμο στην πηγή, όχι ότι η
  πηγή λέει αλήθεια — τίμιο όριο, δηλωμένο σε κάθε receipt).

## 5 · Μη-στόχοι (τι ΔΕΝ υποσχόμαστε)
- Δεν αποδεικνύουμε την ΟΥΣΙΑΣΤΙΚΗ ορθότητα ερμηνείας αόριστων εννοιών
  (αποδεικνύουμε υπό δηλωμένο interpretive profile).
- Δεν αποδεικνύουμε αλήθεια πραγματικών περιστατικών (υπό τα δηλωθέντα facts).
- Δεν προστατεύουμε από νομοθετική αλλαγή του ίδιου του νόμου (αυτό ΕΙΝΑΙ η
  νίκη-συνθήκη: για να μας «διαψεύσει» κανείς, αλλάζει τον νόμο).

## 6 · Εκκρεμή κενά → φάσεις (καμία σιωπηλή παράλειψη)
Θ3/Θ4 (rollback/freeze) → TUF timestamp/snapshot ΠΡΙΝ δημόσιο L5 serving.
Θ5 (split-view) → prev-release-root στο P1.5 census + self-hosted CT log P4+.
Θ9 (bootstrap) → out-of-band pinned root στο P1.5 verify-kit-v2.
Θ10 (TSR crypto) → πλήρης RFC-3161 επαλήθευση P4.
Θ15 (αλγοριθμική απαξίωση) → Cryptographic Agility & Long-Term Evidence Preservation
Profile (MLTP v3 §14)· ενεργοποίηση hybrid epoch με ρητή πράξη όταν το threat model το
απαιτεί (POST-C2, design-only, μη υλοποιημένο).
Θ16 (retroactive ontology invalidation) → Temporal Ontology & Validation Governance
(MLTP v3 §2.11· content-addressed bundles + bound receipts· POST-C2, design-only).
Θ17 (nation-state single-zone compromise) → compromise-tolerant zero-trust αρχιτεκτονική
(v1.4 §4.22· απομονωμένες security cells, threshold+n-of-m PQ root σε ανεξάρτητα failure
domains, fail-closed publication, revocation/recovery/rebuild)· POST-C2, design-only. Ο
ισχυρισμός είναι «παραβίαση ζώνης ≠ canonical authority· ανιχνεύσιμη/περιορισμένη/
αναστρέψιμη», ΟΧΙ «unhackable».
Θ18 (untrusted input → code) → `LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md` (external
bytes ≠ Lisp forms· taint states· SIK-1..9)· POST-C2, design-only.
