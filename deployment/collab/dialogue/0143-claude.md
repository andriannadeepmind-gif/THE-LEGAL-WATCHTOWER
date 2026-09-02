# [0143] — CORRECTIVE MICRO-PASS (exactly three defects, no new architecture)
**2026-09-02 · πάνω στο `5351baed` ([0142]) · design-only · bounded · καμία νέα αρχιτεκτονική/υλοποίηση/refactoring**

Εντολή: «CORRECTIVE MICRO-PASS BEFORE SPEC FREEZE — EXACTLY THREE DEFECTS». Ανεξάρτητη
επιθεώρηση των committed files βρήκε τρία αναπαραγώγιμα ελαττώματα. Ιστορία διατηρείται·
`mltp3/` αμετάβλητος· RAW-JOURNAL εκτός commit. Καμία αναζήτηση νέων αξόνων.

## Defect 1 — Secure Ingress αντίφαση (safe-read ≠ external decoder)
**Πριν:** το `SECURE-SEMANTIC-INGRESS-CONTRACT` όριζε το `source/safe-read.lisp` ως external
deserialization seat, ενώ το `safe-read.lisp` **χρησιμοποιεί `cl:read`**, parseάρει data-only
S-expressions (ΟΧΙ JSON), και **ρητά δηλώνει** (γρ. 28-31) «ΕΛΑΧΙΣΤΟ ΕΣΩΤΕΡΙΚΟ primitive —
ΟΧΙ public ingestion boundary· ΑΠΑΓΟΡΕΥΕΤΑΙ Internet/HTML/PDF/OCR/LLM input».
**Μετά:** `safe-read.lisp` = **ΕΣΩΤΕΡΙΚΟ-ΜΟΝΟ** (έμπιστα self-written data-only S-expr,
αμετάβλητο). Διακριτός εξωτερικός αγωγός: `opaque bytes → sandboxed capability-less parser →
canonical JSON/CBOR ingress-envelope/1 → non-evaluating schema decoder → typed DTO/Legal IR`·
**κανένα εξωτερικό byte στον `cl:read`/eval/macro/compile**. `parser-result/1` (ντετερμινιστικοί)
ξεχωριστό από `neural-candidate/1` (νευρωνική λωρίδα μόνο· δεν δρομολογείται κάθε parser μέσω
neural-task). Διορθώθηκαν και v1.4 §4.4 + traceability R-29 (το εξωτερικό/untrusted νευρωνικό
runtime → non-evaluating decoder, ΟΧΙ safe-read). Νέα errors `reader-reached-external-bytes`,
`non-canonical-ingress-envelope`, `schema-decode-failed`. Έδρα external decoder = **ΝΕΑ,
MISSING** (Impl-Book WP-02).

## Defect 2 — Source-Type Registry (schema/entry + evidence + νομικές διορθώσεις)
Διακριτό `SourceTypeSchema/1` (αρχιτεκτονικό) από versioned `SourceTypeEntry` (περιεχόμενο)·
κάθε entry φέρει `authority_citation`/`evidence_state`/`review_state`/`valid_from`/`valid_to`
και μένει **`PENDING_LEGAL_VALIDATION`** (ΟΧΙ πιστοποιημένη νομική αλήθεια). Νομικές διορθώσεις:
**ΠΝΠ (44§1)** = 40 ημέρες υποβολή στη Βουλή + 3 μήνες κύρωση· αποτυχία ⇒ **prospective**
(ex nunc) παύση (αφαιρέθηκε το «λήγει αν δεν κυρωθεί σε 40 ημέρες»)· **EU** Κανονισμός/Οδηγία/
Απόφαση = **secondary/derived** με διακριτά primary/secondary, legislative/non-legislative,
δεσμευτικότητα, άμεση εφαρμογή, direct effect, αποδέκτη (§2.1)· **ΔΕΕ vs ΕΔΔΑ** = διακριτά
effect profiles (άρ.267 vs άρ.46 ΕΣΔΑ)· **εγκύκλιος** = δεσμευτικότητα παραγόμενη από issuer/
competence/addressee/content, ΟΧΙ από τίτλο. Προστέθηκαν **Κανονισμός Βουλής, ΠΥΣ, αναγκαστικοί
νόμοι, νομοθετικά διατάγματα, βασιλικά διατάγματα** (ιστορικά, δυνητικά ισχύοντα). `bindingness`
= κλειστό typed sum. **`UNKNOWN_SOURCE_TYPE`** fail-closed. Το μητρώο **ιεραρχικό, επεκτάσιμο,
versioned** — ΟΧΙ «21 επίπεδες γραμμές = αιώνια πλήρες». (28 SourceTypeEntry + UNKNOWN.)

## Defect 3 — Τιμιότητα audit
Ο `V1.4-...AUDIT.sh` πλέον δηλώνει **`DOCUMENT/REFERENCE CONSISTENCY PASS`** μόνο (header +
scope + exit line). ΔΕΝ αποδεικνύει semantic/legal/security correctness ή source-universe
completeness. Πέντε διακριτές κατηγορίες τεκμηρίου: [1] deterministic doc/reference· [2]
executable protocol (run.sh)· [3] legal-content review (MISSION gate· entries
PENDING_LEGAL_VALIDATION)· [4] security implementation (SIK-1..9 **UNEXECUTED**)· [5]
specification qualification (§8). Ο ισχυρισμός νομικός/ασφάλειας απαιτεί πρωτογενή πηγή +
review gate.

## Αρχεία & regressions
Τροπ.: `LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md`, `LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md`,
`LAWMAX-THREAT-MODEL.md`, `CHANGE-PROPOSAL-v1.4.md` (§4.4/§4.20/§4.21), `ARCHITECTURE-CLOSURE-MATRIX.md`,
`PUBLIC-OBSERVATORY-CROSSWALK.md` (CAP-157/158), `TRACEABILITY-MATRIX.md` (R-29/R-132/R-133),
`FINAL-PUBLIC-CEILING-DECISION.md`, `V1.4-CONTRADICTION-OMISSION-AUDIT.sh` (I1 reworked, I3d-g,
header/scope/exit), + index/state. **v1.4 154/154 (document/reference), v1.3 64/64, run.sh
PASSED· core αμετάβλητος. Καμία υλοποίηση/refactoring.**

## ΕΤΥΜΗΓΟΡΙΑ
> **`SPEC FREEZE CANDIDATE CORRECTED — AWAITING CREATOR APPROVAL`**

Τα τρία ακριβή ελαττώματα έκλεισαν. Στάση — αναμονή ρητού `ΕΓΚΡΙΝΩ SPEC FREEZE` (ακολουθεί
Implementation Book pinned στο διορθωμένο SHA). Καμία αναζήτηση νέων αξόνων.
