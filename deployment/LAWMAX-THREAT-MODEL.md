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
| Θ19 | **Correlated / common-control independence failure** (αντίπαλος ελέγχει πολλαπλούς actors που **φαίνονται** ανεξάρτητοι — distinct `kid` — αλλά μοιράζονται κοινό control domain: ίδιος beneficial owner / cloud / key custodian / infrastructure / privileged admin· ένα mesh «independence quorum» καταρρέει σε **ένα** failure domain· self-signed ή unbound «independence» declarations) | D3 evidence-backed independence (v1.5 candidate): χωριστό `IndependenceAssuranceProfile {IA-0/1/2}` (IA-0 δεν μετρά strict)· `ActorIndependenceEvidence/1` **κρυπτογραφικά** δεμένο (actor_kid+public_key+control_domain_id+evidence_subject_digest)· **versioned/content-addressed `TrustedIssuerRegistry/1` pinned από LocalTrustState** (F4)· `revocation_ref` fail-closed· ντετερμινιστικό `control-domain-partition` (union-find) που καταναλώνει **typed per-dimension `DomainAssertion/1`** (F4· ένα `control_domain_id` δεν αρκεί)· UNKNOWN edge ⇒ union υπό FAIL_CLOSED· quorum μετρά **distinct control-domain components**, ΟΧΙ distinct `kid`· insufficient ⇒ `INDEPENDENCE_UNKNOWN`. V5KW-D3-7..12, V5KW-F4 **UNEXECUTED** | ⚠ ΚΕΝΟ → `CHANGE-PROPOSAL-v1.5.md §3/§11.4/§11.7` + MLTP §15 + `V1.5-SCHEMAS.sexp` (POST-C2, **design-only, CANDIDATE**) |
| Θ20 | **Proposer/adapter substitution & memory-scope leakage** (κακόβουλος ή αντικατεστημένος model/ONNX/OCR/DB proposer επιχειρεί canonical write, self-certification, ή score→νομική αλήθεια· ή external bytes εκτελούνται μέσω reader/eval· ή private (client/matter) datum διαρρέει σε public flow· ή adapter downgrade/expired manifest· ή self-improvement αυτο-εξουσιοδοτείται) | v1.6: κάθε εργαλείο = replaceable adapter χωρίς keys/write-authority (`V6I-04`)· proposer παράγει μόνο typed anchored `CandidateInterpretation/1` μέσω **non-evaluating** ingress decoder (κανένα `cl:read`/eval/compile σε external bytes)· `write-authority.lisp` = η ΜΙΑ έδρα εγγραφής· `SafetyMode :SYMBOLIC_ONLY` πλήρες path όταν λείπουν proposers (`V6I-02/03`)· memory scope isolation `public|user|client|matter|ephemeral`· private→public **μόνο** με valid `DeclassificationReceipt/1` (`V6I-15`)· `CapabilityManifest/1` fail-closed σε downgrade/expiry· self-improvement gated (test+authorization+journaled adoption+rollback, `V6I-08`). V6KW-05/11/16/17/18 **UNEXECUTED** | ⚠ ΚΕΝΟ → `CHANGE-PROPOSAL-v1.6.md §3/§5/§8` + `V1.6-SCHEMAS.sexp` (**design-only, CANDIDATE**) |

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
Θ20 (proposer/adapter substitution & memory-scope leakage) → v1.6: model-agnostic SemanticProposer +
SafetyMode SYMBOLIC_ONLY + non-evaluating ingress + one write authority + memory scope isolation +
DeclassificationReceipt/1 + CapabilityManifest fail-closed + gated self-improvement (`CHANGE-PROPOSAL-v1.6.md`,
`V1.6-SCHEMAS.sexp`)· design-only, CANDIDATE.
Θ19 (correlated/common-control independence) → D3 evidence-backed independence quorums
(`CHANGE-PROPOSAL-v1.5.md §3/§11.4`· MLTP §15· `V1.5-SCHEMAS.sexp`): assurance profiles,
crypto-bound actor evidence, trusted issuer registry, deterministic control-domain partition,
quorum σε distinct control-domain components· POST-C2, **design-only, CANDIDATE** (μη frozen,
μη υλοποιημένο· V5KW-D3-7..12 UNEXECUTED).

## Θ21 — v1.8 pre-freeze threats (design-only)
- **Continuity capture:** a custodian is NOT institutional/approval authority; one person may invoke only a
  temporary time-limited `EmergencyFreeze`; extension/thaw needs quorum (no permanent single-custodian DoS)
  (`:V8I-CONT-separated`).
- **Re-anchoring forgery:** a root signature alone cannot re-anchor; `ReAnchoringManifest/1` requires pre-existing
  pre-transition commitments/timestamps/witnesses/archival bytes; the same versioned citation URI never resolves
  to a different Expression (`:V8I-EPOCH-one-expression`).
- **Correction-privacy leak:** `PublicCorrectionEvent/1` carries no re-published content and no PII; digests may
  be sensitive; the chain verifies with `content unavailable/withdrawn` without retaining withdrawn public content
  (`:V8I-CORR-privacy`).
- **Silent epoch demotion / algorithm downgrade:** an emergency transition creates a new monotonic
  `RECOVERY_EPOCH N+1`, never a demotion; the verifier never silently reverts or accepts a single-algorithm
  fallback (`:V8I-FROST-precise`).
- **Sidecar lawful-basis overreach:** `SidecarSourceProfile/1` is spec-only + creator-gated; lawful basis is
  per source/controller/purpose and `PENDING_LEGAL_VALIDATION`; no source (incl. ΦΕΚ) is zero-GDPR-weight.
