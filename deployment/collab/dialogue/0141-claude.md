# [0141] — POST-C2 CORRECTION PASS (bounded, design-only)
**2026-09-02 · πάνω στο `2151e168` ([0140]) · design-only · καμία επέκταση scope, κανένα freeze**

Εντολή: «BOUNDED CORRECTION PASS ON COMMIT 2151e168 — DO NOT FREEZE OR EXPAND SCOPE».
Ανεξάρτητη επιθεώρηση βρήκε **έξι δομικά ελαττώματα** που ο presence/count audit (106/106)
δεν ανιχνεύει. Όλη η ιστορία διατηρείται· εκτελέσιμος πυρήνας `mltp3/` **αμετάβλητος**.

## Έξι διορθώσεις
1. **Ακυκλικά ids:** `ontology_bundle_id`/`receipt_id` (και το προϋπάρχον QSR `record_id`)
   έκαναν hash ολόκληρο το record ⇒ self-cycle. Διόρθωση MLTP §4.2 κανόνας 2 + §2.11 + §3:
   `*_id = hex(sha256(id_domain ‖ 0x1F ‖ canonical(BODY)))`, BODY = αντικείμενο **εξαιρώντας
   id + ΚΑΘΕ υπογραφή + detached**. Γενικός ανιχνευτής (audit H1a/H1b).
2. **Κλειστό context registry §4.2:** τα 4 νέα (+`pq-authorization`, `conflict-policy`)
   ήταν απόντα. Registry έγινε canonical versioned (executed-core + extension), κάθε
   context ακριβώς μία φορά· signing target εξαιρεί ΚΑΘΕ υπογραφή (no cross-sig cycle).
   Audit H2a/H2b/H2c/H3.
3. **Formal-semantics honesty:** το `LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md` relabel σε
   **REQUIREMENTS SPEC**· §0.1 απαριθμεί κάθε λείπον machine-readable artifact ως
   **Implementation Book — ΜΗ ΠΑΡΑΧΘΕΝ**· δεν διεκδικείται μηχανοποιημένο κλείσιμο από
   πρόζα. Audit H6a/H6b.
4. **Legal-conflict canons:** **αφαιρέθηκε** ο επινοημένος καθολικός `lex superior ≻
   specialis ≻ posterior` + η σιωπηλή ολικοποίηση. Η αρχιτεκτονική ορίζει **μόνο τον
   μηχανισμό** αξιολόγησης υιοθετημένου, scoped `ConflictPolicyBundle` (jurisdiction/
   authority/competence/subject/time-scoped, source-anchored, versioned, InstitutionalAct-
   approved)· απών ⇒ `UNKNOWN`, ασύμβατα ⇒ `CONFLICTING`· ποτέ επινόηση. Audit H7b/H7c·
   KW-105 reframed.
5. **PQ root:** ρητή επιλογή = **independent n-of-m ML-DSA multisignature** (ΟΧΙ threshold
   — δεν υπάρχει vetted threshold ML-DSA· θα ήταν homemade crypto). Ασύμμετρη: classical =
   FROST-Ed25519· PQ = m ανεξάρτητα κλειδιά, ≥n. Ορίστηκαν `PQRootSet`, acyclic signing
   target, rotation, revocation, downgrade (`pq-authorization-insufficient`), verifier
   rules. MLTP §14.4. Audit H7a/H4c/H5a.
6. **Διαχωρισμός πυλών:** (α) architecture/spec closure — αυτό απαιτεί freeze· (β)
   Implementation Book completion+approval — post-freeze· (γ) product implementation· (δ)
   qualification. Στάδιο 4b (Implementation Book) στο v1.4 §10· **B-1/B-2/B-3 = post-freeze,
   ΟΧΙ freeze blockers** (η προηγούμενη πλαισίωση ήταν κυκλική). Audit επεκτάθηκε (**block
   H**: id-acyclicity, context closure, schema/ref closure, canonical ownership, error-step).

## Αρχεία & audits
1 νέο (`POST-C2-CORRECTION-PASS.md`) + 7 τροπ. (MLTP §4.2/§2.11/§3/§14· semantic-contract·
v1.4 §4.17/§4.18/§10· dominance D-16· Q KW-105· traceability R-129· audit block H)· +
FINAL-DECISION Μέρος 8-ter + reconciliation banner. Audits: v1.4 **124/124** (ήταν 106/106·
+18 δομικοί H-checks), v1.3 **64/64**, exit 0· `run.sh` αμετάβλητο (40/40, interop OK).

## Αναθεωρημένη ετυμηγορία (μη κυκλική)
> **`SPEC FREEZE BLOCKED — SPEC-LEVEL: FB-2 (SPEC QUALIFIED §8 μη εκτελεσμένο)· τα 6 δομικά ελαττώματα ΔΙΟΡΘΩΘΗΚΑΝ`**

Freeze blockers μόνο specification-level: FB-1 (6 δομικά — ΔΙΟΡΘΩΘΗΚΑΝ, επιβάλλονται από
block H)· FB-2 (`SPEC QUALIFIED` §8, KW-1..106 + δομικοί audits + ανεξάρτητοι adjudicators
— μη εκτελεσμένο)· FB-3 (external U-2/U-4/U-7). B-1/B-2/B-3 = Implementation Book
(post-freeze). ΔΕΝ ΕΓΙΝΕ: freeze, qualification, merge, implementation, refactoring,
destruction, agent swarm. Στάση — αναμονή ρητής απόφασης δημιουργού.
RAW-JOURNAL-PARTIAL.jsonl αμετάβλητο/ακατάθετο.
