# V1.3 DESTRUCTION PASS — OPPONENT → TEST MAPPING

**Στόχος υπό επίθεση:** το πλήρες δημόσιο v1.3 target στο commit
`9dabc2bb0cb0c3d04fcda5071578bd0f0084f63b` (errata commit, post-push audit 64/64).
**Design only** — καμία υλοποίηση υπάρχει· οι αντίπαλοι επιτίθενται στις προδιαγραφές
όπως είναι γραμμένες.

## Πρωτόκολλο (δεσμευτικό, CLAUDE.md + εντολή δημιουργού)

- Οκτώ **ανεξάρτητοι** αντίπαλοι, **φρέσκο πλαίσιο**, **χωρίς** πρόσβαση στο σκεπτικό
  του συντάκτη — διαβάζουν τα έγγραφα μόνοι τους από το repo.
- Δύο άξονες πρωτοκόλλου: **(α)** επίθεση στο μοντέλο/ασφάλεια (A1–A4)· **(β)** κυνήγι
  μετριότητας — μπαλώματα, φρουροί αντί δομικής αδυναμίας, διπλές έδρες, σιωπηλά
  fallbacks, τεστ-ταυτολογίες, dangling refs (A5–A8).
- **KW-1…KW-16 = υποχρεωτική βάση**, όχι ολόκληρη η επίθεση· κάθε αντίπαλος έχει
  και ανοιχτή εντολή για **άγνωστους νέους άξονες**.
- **Default verdict: `FALSIFIED`** όταν η επιβίωση δεν αποδεικνύεται με ακριβές
  κείμενο προδιαγραφής.
- Κάθε `FALSIFIED` εύρημα αποδίδεται σε **ανεξάρτητο spec-literalist adjudicator**
  με κανόνα «uphold εκτός αν ακριβές κείμενο κλείνει την επίθεση» — το βάρος στο SPEC.
- `MECHANICAL` = αναπαραγώγιμο με εντολή + raw output (επανεκτελείται από τον
  συντάκτη για digest)· `ARGUMENT-ONLY` = χωριστή σήμανση.
- Ο αριθμός agents/tool calls **δεν** είναι evidence.

## Ανάθεση

| αντίπαλος | άξονας | υποχρεωτικά KW | εστίαση άγνωστων αξόνων |
|---|---|---|---|
| **A1** | (α) security | KW-1 (issuer self-verdict), KW-9 (delegated ≡ root) | διαρροή self-verdict σε οποιοδήποτε layer· σύγχυση delegated/root στον verifier |
| **A2** | (α) security | KW-2 (SHA-only vs RS256/Ed25519), KW-10 (out-of-scope key) | κενά crypto profile· algorithm confusion· επιβολή scope έναντι `claim_type` |
| **A3** | (α) security | KW-3 (raw-byte identity churn), KW-11 (dangling qualification ref) | ταυτότητα Work/Expression/Manifestation/Item υπό εχθρικά manifestations |
| **A4** | (α) security | KW-4 (RFC-3161 fake provenance), KW-12 (self-qualified issuer) | πλαστή προέλευση με έγκυρους χρόνους· παράκαμψη issuer-role |
| **A5** | (β) mediocrity | KW-5 (split-view + embedded witnesses), KW-13 (stopped/rewound clock) | witness μοντέλο· `UNKNOWN_FRESHNESS` χειρισμός |
| **A6** | (β) mediocrity | KW-6 (pre-revocation/retroactive), KW-14 (revocation στο effective-time) | revocation: signature-time vs effective-time, fail-closed defaults |
| **A7** | (β) mediocrity | KW-7 (interpretive ratio ως source fact), KW-15 (πλαστό embedded registry) | νομολογία· πλαστά auditor/witness registries |
| **A8** | (β) mediocrity | KW-8 (stale v1.2), KW-16 (KEY-LIFECYCLE ↔ MLTP v2) | κατάλοιπα v1.2· αντιφάσεις ACTIVE foundations ↔ MLTP v2 |

**Κάλυψη:** 8 × 2 = **16/16** υποχρεωτικά KW, το καθένα σε ακριβώς έναν αντίπαλο.

## Έγγραφα που δόθηκαν (μόνο διαδρομές — καμία ανάλυση του συντάκτη)

Target: `CHANGE-PROPOSAL-v1.3.md`, `MACHINE-LEGAL-TRUST-PROTOCOL.md`,
`PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md`, `V1.3-KILL-WITNESSES.md`,
`V1.3-SEMANTIC-CROSSWALK.md`, `SUPERSEDED-REGISTER.md`, `AS-IS-EVIDENCE-MANIFEST.md`.
Foundations: `LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md`, `PROOF-CARRYING-LAW.md`,
`LAWMAX-PROOF-OBJECT-SPEC.md`, `LAWMAX-TRUST-BOOTSTRAP-SPEC.md`,
`LAWMAX-KEY-LIFECYCLE-SPEC.md`, `LAWMAX-TEMPORAL-IDENTITY-DESIGN.md`.

## Κατάθεση

`PROMPTS.md` (verbatim πρότυπα) · `RAW-FINDINGS.json` (πλήρης δομημένη έξοδος κάθε
αντιπάλου + adjudicator, αυτούσια) · `MECHANICAL-ARTIFACTS.md` (επανεκτέλεση κάθε
μηχανικού ευρήματος από τον συντάκτη: command, raw output, sha256) ·
`ADJUDICATION.md` (τελική κρίση ανά εύρημα) · `VERDICT.md` (η μία τελική ετυμηγορία).
