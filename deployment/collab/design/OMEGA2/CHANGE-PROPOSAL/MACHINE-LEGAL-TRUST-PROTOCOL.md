# MACHINE LEGAL TRUST PROTOCOL (MLTP) — WIRE SCHEMAS + OFFLINE VERIFIER
# Υποσύστημα του `CHANGE-PROPOSAL-v1.3.md §3-4` — ΟΧΙ δεύτερη αρχιτεκτονική

**Design only.** Spec των μηχανικά καταναλώσιμων πιστοποιητικών του δημόσιου
στόχου. **Καμία υλοποίηση.** Είναι το πρόσωπο υπαρχουσών εδρών — κάθε πεδίο
ανάγεται σε έδρα (στήλη «seat»)· κανένα νέο primitive, καμία νέα αρχιτεκτονική.

**Κοινές αρχές (δεσμευτικές):**
- **Proof-carrying** (`LAWMAX-PROOF-OBJECT-SPEC.md §0`): κάθε cert περιέχει **το
  αντικείμενο απόδειξης**, όχι μόνο claim+hash+signature. Υπογραφή = *επιπλέον*
  απόδειξης, ποτέ *αντί*.
- **Canonical serialization + hash** (USC §0.1 `canonical-representation`): κάθε
  `*_id` = `canonical-hash(...)`· leaves ταξινομημένα κατά canonical bytes· RFC 9162
  profile `lawmax-merkle-sha256-v1` (leaf `0x00`, node `0x01`, unbalanced split,
  no-duplicate-last).
- **Pinned key out-of-band** (PCL §4· trust-bootstrap §3): κανένα cert δεν
  εμπιστεύεται δικό του `public_key`· μόνο thumbprint-match με pinned root.
- **Τίμια άγνοια:** κάθε cert μπορεί να επιστρέψει `UNKNOWN(typed_reason)`· κανένα
  LLM στο έμπιστο μονοπάτι· `PLANE-3` inference ΠΟΤΕ σε cert.

---

## 0. ΚΟΙΝΟ ENVELOPE — ΥΠΟΧΡΕΩΤΙΚΑ ΠΕΔΙΑ ΚΑΘΕ CERT

```
{ "mltp": "1",
  "cert_type": <SourceAuthenticityReceipt | LegalStateCertificate |
                TemporalProjectionCertificate | CoverageAndFreshnessCertificate |
                JurisprudenceCertificate | CorrectionOrRevocationRecord | TrustBundle>,
  "claim":   <ρητός, ελεγχόμενος ισχυρισμός — string, ΑΠΑΓΟΡΕΥΜΕΝΑ: "absolute
              truth"/"only source"/"proves all cases"/"X% win" (PROOF-OBJECT §3)>,
  "scope":   { "includes": [...], "excludes": [...] },              # τι ΔΕΝ καλύπτει, ρητά
  "valid_time":  <legal-date | {from,to}>,                          # USC legal-date
  "known_time":  <legal-instant>,                                   # USC legal-instant
  "source_roots": { "pcl_text_root"?, "provision_set_root"?,
                    "authority_roots"? },                           # census-2 / attestation
  "coverage_boundary": <ρητό όριο· τι είναι ΕΝΤΟΣ και τι UNKNOWN>,
  "assurance_level":   <spec-qualified | implementation-qualified |
                        mission-qualified | provider-adoption-qualified | none>,
  "expiry":   <legal-instant>,                                      # TUF timestamp/freshness
  "freshness":{ "as_of": <legal-instant>, "max_staleness": <duration> },
  "signer":   { "kid", "alg": <Ed25519|RS256>, "delegation_seq",    # key-lifecycle §3
                "key_lineage": [...] },
  "transparency_log_inclusion": { "log_id", "tree_size", "leaf_index",
                                  "inclusion_proof", "log_root",
                                  "consistency_from"? },             # RFC 9162 §2.1.1/2.1.2
  "verification_result": <VERIFIED | UNVERIFIED_FOR_MACHINE_RELIANCE | UNKNOWN(reason)>,
  "proof_object": <το αναπαραγώγιμο υλικό — ανά cert §1-7> }
```

**Κανόνας κενού πεδίου:** κανένα από τα παραπάνω δεν είναι σιωπηλά κενό· απόν
`known_time`/`expiry`/`coverage_boundary` ⇒ ο verifier επιστρέφει `UNKNOWN`,
ποτέ `VERIFIED`.

---

## 1. `SourceAuthenticityReceipt` — «ποιος εξέδωσε, πώς αποκτήθηκε, πότε»

**Claim:** «τα bytes με digest D προέρχονται από την αρχή A μέσω του μητρώου R,
αποκτήθηκαν με τον τρόπο O, με χρόνο-bytes T.»

| πεδίο | seat |
|---|---|
| `raw_artifact` = `{digest_algorithm:"sha256", digest, byte_length}` | USC §4.1 `raw-artifact/1` |
| `acquisition` = `acquisition-receipt/1` (origin sum: network-fetch \| manual-deposit \| archive-import) | USC §5.1 |
| `authority_id` (`auth1:`) + `institutional_register_id` (`ireg1:`) | USC §2.2 / §2.1β |
| `authority_proof` = consumed `authority-proof-bundle/1` via CENSUS | USC §0.1 |
| `time_anchor` = `{tsr_sha256, tlog_leaf_index}` | RFC-3161 (ΜΟΝΟ χρόνος — v1.3 §2.2) |
| `divergence` = `official-sources-conflict` uncertainty ref \| null | USC §8 |

**Δομικός κανόνας:** RFC-3161 μόνο ⇒ **ΑΝΕΠΑΡΚΕΣ**· χωρίς `authority_proof` **ΚΑΙ**
`institutional_register_id` ⇒ `verification_result = UNKNOWN`. (v1.3 §2.2, εντολή #6.)

---

## 2. `LegalStateCertificate` — «τι κείμενο & νομική κατάσταση σε (valid,known)»

**Claim:** «στο (valid,known), το work W έχει expression E και νομική κατάσταση S.»

| πεδίο | seat |
|---|---|
| `work_id` (`lsw1:`) / `expression_id` (`lse1:`) | USC §1.1 / §1.2 |
| `attestation` = `legal-state-attestation/1` (`lsa1:`) | USC §1.2γ |
| `knowledge_checkpoint` = `knowledge-checkpoint/1` (`kchk1:`) — causally closed cut | USC §1.2β |
| `inclusion` = PCL-1 proof (leaf→merkle_root, path ≤ 64) | PCL §5 |
| `uncertainty_roots` = graph + corpus uncertainty set roots | USC §1.2γ |
| `legal_state` ∈ `IN | OUT | UNDEC` → `UNDEC ⇒ UNKNOWN` | v1.2 M4 (KT6) |

**Δομικός κανόνας:** ο verifier αναϋπολογίζει `provision_set_root` από το checkpoint·
αν η expression δεν προκύπτει ⇒ άκυρο (USC `W-UNCERTAINTY-SET`). «Δύο ανεξάρτητα
prefixes χωρίς κοινό checkpoint» ⇒ reject (`W-INCONSISTENT-VECTOR-CUT`).

---

## 3. `TemporalProjectionCertificate` — «η προβολή σε (valid,known), αναπαραγώγιμα»

**Claim:** «η ενοποιημένη προβολή του σώματος B στο (valid,known) είναι αυτή.»

| πεδίο | seat |
|---|---|
| `snapshot` = `version-graph:snapshot-at(B, valid_at, known_at)` | USC §0.1 version-graph |
| `census_temporal` = census-2 `{body, graph_root, graph_records, receipt_set_root, receipt_count, valid_at, known_at}` | PROOF-OBJECT §2 |
| `per_event_bitemporality` = κάθε γεγονός (αρχικό **και** τερματικό) φέρει `(valid,known)` | v1.3 §5 / AS-IS R-5 |

**Δομικός κανόνας (KT5):** προβολή στο `k` χρησιμοποιεί **μόνο** γεγονότα με
`known_from ≤ k`· «κατάργηση γνωστή αργά» ΔΕΝ εφαρμόζεται αναδρομικά. Το μοντέλο
`TPKill.tla` **ουδέποτε εκτελέστηκε** (AS-IS EV-6) — η ιδιότητα μένει
**`REPORTED`** μέχρι model-check + `version-graph-test ④β`.

---

## 4. `CoverageAndFreshnessCertificate` — «τι καλύπτεται, πόσο φρέσκο, τι λείπει»

**Claim:** «στον χώρο X (π.χ. ΦΕΚ τεύχος×έτος), η κάλυψη είναι C, με φρεσκάδα F·
τα κενά είναι ρητά UNKNOWN.»

| πεδίο | seat |
|---|---|
| `coverage_ledger` = ολική συνάρτηση στον απαριθμημένο χώρο → `{INGESTED, EXPLICITLY-ABSENT, QUARANTINED, UNKNOWN}` | **ΝΕΟ ΚΕΝΟ** (v1.2 §4· AS-IS R-1: καμία εθνική απογραφή σήμερα) |
| `freshness` = census-2 `known_at` + TUF `timestamp` role | PROOF-OBJECT §2 / key-lifecycle §1 |
| `latency_distribution` = ποσοστημόρια `t_ingested − t_published` | v1.2 §4Δ (**ΝΕΟ**) |
| `gaps` = ρητή λίστα `UNKNOWN` θέσεων με ηλικία | v1.2 §4Β |

**Δομικός κανόνας:** θέση χωρίς τιμή στο ledger = **σφάλμα**· «μηδέν κάλυψη» ≠
«άγνωστη κάλυψη» (ο συλλέκτης που επιστρέφει κενό δηλώνει `UNKNOWN`, όχι «0»).
**Αυτό είναι το κύριο μηχανικό κενό του δημόσιου στόχου** (βλ. crosswalk).

---

## 5. `JurisprudenceCertificate` — «απόφαση, σχέσεις, θέση στη γραμμή αυθεντίας»

**Claim:** «η απόφαση J (ECLI/id) έχει αυτό το ratio/holding/disposition, αυτές τις
τυπωμένες σχέσεις και αυτή τη θέση/βάρος στη γραμμή αυθεντίας σε (valid,known).»

| πεδίο | seat |
|---|---|
| `decision_identity` = `work_id` (judgment domain) + ECLI \| provisional id + δικονομικό ιστορικό + ανωνυμοποίηση | USC §1.4 / v1.3 §5 |
| `ratio` / `obiter` / `holding` / `legal_issue` / `disposition` / `separate_opinions` | **Level-7 plane, status ✗** (CEILING-CROSSWALK #7) |
| `typed_relations` = USC §6.3 kinds (`judicially-interprets`, `annuls`, `declares-unconstitutional`, `precedent-follows/distinguishes`, …) | USC §6.3 |
| `authority_weight` — **μετρημένο** (Ολομέλεια>Τμήμα, πλήθος/συνέπεια), ποτέ γνώμη μοντέλου | CEILING-CROSSWALK #15 φρουρός |
| `later_treatment` + `temporal_line_of_authority_graph` (L2 bitemporal) | Level-7 (ΝΕΟ ΚΕΝΟ) + L2 |

**Δομικός κανόνας:** κάθε ratio/holding αγκυρωμένο σε χωρίο `PLANE-0`· απόφαση **δεν**
παράγει νομοθετικό γεγονός (USC §6.3, μη εκφράσιμο)· `UNDEC ⇒ UNKNOWN`.

---

## 6. `CorrectionOrRevocationRecord` — «τι αντικαταστάθηκε/ανακλήθηκε, από ποιον»

**Claim:** «το αντικείμενο O μετέβη σε `SUPERSEDED`/`WITHDRAWN`/διορθώθηκε — με αυτή
την εξουσία, σε αυτόν τον χρόνο· τίποτα δεν διαγράφηκε.»

| πεδίο | seat |
|---|---|
| `transition` ∈ `SUPERSEDED | WITHDRAWN | CORRECTION` | v1.2 §5.2 |
| `uncertainty_resolution` (journaled, evidence ≠ κενό) | USC §8 |
| `relation_retract` = συμμετρικό batch (USC `W-REL-RETRACT`) | USC §6.3 |
| `key_or_delegation_revocation` (αν αφορά υπογραφή) | key-lifecycle §2.5 |
| `superseded_by` / `supersedes` refs (ανακτήσιμα στη διτεμπορική τομή) | v1.2 §5.2 |

**Δομικός κανόνας:** **καμία διαγραφή**· ανακληθέν = ορατό ως ανακληθέν στη τομή του.
Ό,τι υπογράφηκε **πριν** την ανάκληση + έχει ανεξάρτητο RFC-3161 χρόνο παραμένει
έγκυρο (key-lifecycle §2.5) — γι' αυτό ο χρόνος ριζώνει εκτός των κλειδιών μας.

---

## 7. `TrustBundle` — η αυτο-επαληθεύσιμη δέσμη για offline κατανάλωση

**Claim:** «αυτή η δέσμη επαληθεύεται πλήρως offline, μόνο με SHA-256 + pinned root.»

| πεδίο | seat |
|---|---|
| `census` = census-2 (materials in-toto: git_commit, deps_lock, sbcl, base_image) | PROOF-OBJECT §2 |
| `corpus_proof` = PCL `corpus-proof.json` (merkle_root + detached JWS) | PCL §4 |
| `release_anchor` = trust-bootstrap `tra/3` (`owner_root_fingerprint`, `delegation_seq`, `witness_checkpoints`) | trust-bootstrap §5 |
| `delegation_chain` = root→delegate statements (scope, not-before/after, seq) | trust-bootstrap §3 |
| `witnesses` = GitHub commit + ≥2 RFC-3161 TSAs (+ opt. external CT) | trust-bootstrap §4 |
| `included_certs` = οι §1-6 πιστοποιήσεις της τομής | MLTP §1-6 |

**Δομικός κανόνας:** το `public_key` μέσα στο bundle **δεν** γίνεται ποτέ πιστευτό·
μόνο thumbprint-match με τον pinned root που ο καταναλωτής έχει out-of-band.

---

## 8. OFFLINE VERIFIER — ΤΟ ΣΥΜΒΟΛΑΙΟ (μικρός, χωρίς βιβλιοθήκη)

Έδρα: PCL §5-6 + PROOF-OBJECT §4 (LOC-ceiling gate, δεύτερη ανεξάρτητη υλοποίηση
= kernel diversity, L7). Ψευδοκώδικας (επεκτείνει τις 6 γραμμές της PCL):

```
verify_bundle(bundle, PINNED_ROOT):                 # PINNED_ROOT: out-of-band, ΠΟΤΕ από το bundle
  # 1. structural inclusion (RFC 9162)
  for cert in bundle.included_certs:
     require pcl_inclusion(cert.text, cert.proof_object) == OK          # SHA-256 μόνο
  # 2. root authenticity (pinned, μη εμπιστεύσιμο embedded key)
  require thumbprint(bundle.corpus_proof.public_key) == thumbprint(PINNED_ROOT)  # αλλιώς untrusted-key
  require delegation_valid(bundle.delegation_chain, PINNED_ROOT, at=bundle.release_anchor.tsr_time)
  require sig_verify(delegated_key(bundle), bundle.corpus_proof)
  # 3. transparency log + gossip (split-view)
  require tlog_inclusion(bundle) AND consistency(bundle, consumer.last_seen_checkpoint)
  # 4. witnesses
  require witness_agrees(bundle.witnesses, quorum=2)                     # GitHub + ≥2 TSAs
  # 5. freshness / expiry
  if now > bundle.expiry OR staleness(bundle) > max_staleness:
     return UNVERIFIED_FOR_MACHINE_RELIANCE                              # θετική απόδειξη φρεσκάδας
  return VERIFIED
```

**Απορρίψεις (PROOF-OBJECT §5):** ZK-SNARK/STARK, W3C VC/DID ως CORE, LLM στο
trusted path. **Provider-side κανόνας:** αποτυχία οποιουδήποτε βήματος ⇒
`UNVERIFIED_FOR_MACHINE_RELIANCE`/`UNKNOWN` — ποτέ σιωπηλή παρουσίαση ως αυθεντικού
(v1.3 §4.2).

---

## 9. ΤΙ ΔΕΝ ΚΑΝΕΙ ΑΥΤΟ ΤΟ SPEC

Καμία υλοποίηση· κανένα νέο store/primitive/subsystem· κανένα destruction pass·
καμία αξίωση qualification. Η **σύνθεση** των 7 πιστοποιητικών σε ένα εκτελέσιμο
πρωτόκολλο είναι **ΝΕΟ**, δηλωμένο ως τέτοιο· οι επιμέρους έδρες υπάρχουν και
απαριθμούνται στο `V1.3-SEMANTIC-CROSSWALK.md`.
