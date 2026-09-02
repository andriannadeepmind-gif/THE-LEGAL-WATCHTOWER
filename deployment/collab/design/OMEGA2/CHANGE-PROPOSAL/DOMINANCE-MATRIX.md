# DOMINANCE MATRIX — ΚΑΜΙΑ ΓΝΩΣΤΗ ΚΑΤΩΤΕΡΗ ΕΠΙΛΟΓΗ · BENCHMARK ΕΝΑΝΤΙ ΕΠΙΣΗΜΩΝ ΥΠΟΔΟΜΩΝ

**ΚΑΤΑΣΤΑΣΗ: ΙΣΧΥΡΙΣΜΟΙ ΚΥΡΙΑΡΧΙΑΣ — ΔΙΑΨΕΥΣΙΜΟΙ, ΜΗ ΕΠΙΚΥΡΩΜΕΝΟΙ.** Κάθε D-id
είναι ένας ισχυρισμός που το πάσο 2 του προγράμματος επικύρωσης
(`PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md §8`) καλείται να ανατρέψει. Η επιβίωση
δεν έχει αποδειχθεί. Design only.

**Έδρα (μία):** η ανάλυση κυριαρχίας κάθε κρίσιμης επιλογής του
`CHANGE-PROPOSAL-v1.4.md` (§6) και του `MACHINE-LEGAL-TRUST-PROTOCOL.md` v3 (§10.2),
και ο benchmark έναντι των πέντε κορυφαίων επίσημων υποδομών (§B). Το v1.4 §6
συνοψίζει· εδώ η πλήρης ανάλυση.

---

## 0. ΚΑΝΟΝΑΣ ΑΠΟΡΡΙΨΗΣ ΚΑΙ ΟΙ 12 ΑΞΟΝΕΣ

**Κανόνας:** αν για μια επιλογή υπάρχει γνωστή εναλλακτική που είναι **όχι χειρότερη
σε κάθε κρίσιμο άξονα, αυστηρά καλύτερη σε τουλάχιστον έναν, και συμβατή με τα
αμετάβλητα αξιώματα** (Σύνταγμα· κανένα LLM στο trusted path· de jure αυθεντία στο
Κράτος· `UNKNOWN` στον τύπο· μονόδρομο όριο), τότε η επιλογή **απορρίπτεται** και η
εναλλακτική παίρνει τη θέση της. Ισοπαλία σε όλους τους άξονες ⇒ απλούστερη νικά
(λιγότερος κώδικας στο trusted path, LOC-ceiling).

| άξονας | τι μετρά | πώς κρίνεται στο πάσο 2 |
|---|---|---|
| A1 ορθότητα | το αποτέλεσμα είναι ο νόμος όπως εκδόθηκε, στην τομή που ζητήθηκε | counterexample με πηγή ΦΕΚ/δικαστηρίου |
| A2 όρια soundness/completeness | τι μπορεί να αποδείξει και τι δηλώνει ως `UNKNOWN`· ποτέ ψευδοβεβαιότητα | ύπαρξη διαδρομής που επιστρέφει βεβαιότητα χωρίς απόδειξη |
| A3 ανεξάρτητη επαληθευσιμότητα | τρίτος επαληθεύει offline, χωρίς «εμπιστεύσου μας» | ύπαρξη βήματος που απαιτεί εμπιστοσύνη στον εκδότη |
| A4 χρονική πιστότητα | valid × known· νομικός χρόνος ≠ χρόνος ελέγχου | KT5 counterexample· Q41 witness |
| A5 διαλειτουργικότητα | πρότυπα εκπομπής ΚΑΙ επικύρωσης (ELI/ECLI/AKN/RDF/SCITT/OpenAPI/MCP) | προβολή που δεν επικυρώνεται ανεξάρτητα |
| A6 ασφάλεια | κλειδιά, ανάκληση, split-view, stripped citation, σε κλίμακα κράτους | KW-1 έως KW-63 |
| A7 ανθεκτικότητα | απώλεια κλειδιού/log/υποδομής χωρίς απώλεια αλήθειας | DR replay (Q19), compromise (Q26) |
| A8 κλιμάκωση | εθνικό census (όλα τα ΦΕΚ, όλα τα δικαστήρια) και providers | μετρήσεις βήματος 1 (U-1, U-7) |
| A9 αναπαραγωγιμότητα | byte-ταυτόσημη ανακατασκευή από PLANE-0 + journal | Q12, Q19 |
| A10 εξελιξιμότητα | αλλαγή σχήματος χωρίς σπάσιμο παλιών αποδείξεων | Q13 |
| A11 θεσμική διακυβέρνηση | ποιος υπογράφει τι, registries, quorum, καμία αυτο-πιστοποίηση | KW-12, KW-22, KW-46 |
| A12 ανθρώπινη κυριαρχία | ο δημιουργός η μόνη αρχή freeze/merge· reviewer adoption· RBAC/MFA | Q15, Q39 |

Σύμβαση στους πίνακες: **+** η εναλλακτική είναι καλύτερη στον άξονα· **=** ίση·
**−** χειρότερη. Μια εναλλακτική κυριαρχεί μόνο αν δεν έχει κανένα **−** και έχει
τουλάχιστον ένα **+**.

---

## A. ΟΙ 13 ΔΙΑΤΗΡΗΜΕΝΕΣ ΚΡΙΣΙΜΕΣ ΕΠΙΛΟΓΕΣ

### D-01 — Event-sourced διτεμπορικός γράφος (`valid × known`) ως πηγή αλήθειας· ενοποιημένο κείμενο = προβολή
**Έδρα:** v1.4 §4.5· `version-graph.lisp`, `journal.lisp`, `legal-temporal.lisp`.

| εναλλακτική | A1 | A2 | A3 | A4 | A5 | A6 | A7 | A8 | A9 | A10 | A11 | A12 | γιατί δεν κυριαρχεί |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| (a) versioned consolidated-text store με point-in-time κατά ημερομηνία (η τάξη του legislation.gov.uk) | = | − | = | − | = | = | = | + | − | − | = | = | χωρίς known-time δεν απαντά «τι ήξερε το Ίδρυμα στο k» και δεν αποκλείει τερματικό γεγονός που έγινε γνωστό αργά (KT5)· η ενοποίηση δεν είναι επαναπαίξιμη από γεγονότα |
| (b) document store + textual diffs (git-class) | − | − | = | − | − | = | = | + | + | − | = | = | οι τροποποιήσεις ως text diffs χάνουν τη νομική σημασιολογία (τύπος γεγονότος, στόχος, όρος ισχύος)· κανένα typed `CONFLICTING` |
| (c) RDF triple store ως πρωτογενές (η τάξη του Cellar) | = | = | − | − | + | = | = | = | − | = | = | = | χωρίς reified διτεμπορικότητα δεν υπάρχει known-time· με reification χάνει A8/A9· κανένα per-event proof object |

**Falsifier:** επίδειξη υποδομής με known-time ερωτήματα, typed νομικά γεγονότα και
επαναπαίξιμες προβολές σε εθνική κλίμακα με λιγότερη πολυπλοκότητα trusted path.
**Witness:** Q06, Q41, KW-51, KW-60.

### D-02 — USC FRBR-class ταυτότητα (`Work → Expression → Manifestation → Item`)
**Έδρα:** `LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md`· v1.4 §4.2· MLTP v3 §2.5.

| εναλλακτική | A1 | A2 | A3 | A4 | A5 | A6 | A7 | A8 | A9 | A10 | A11 | A12 | γιατί δεν κυριαρχεί |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| (a) content-addressed ταυτότητα (raw digest = id) | − | = | = | = | − | = | = | + | + | − | = | = | δύο κανάλια ⇒ δύο ταυτότητες (RC-28)· επανα-κανονικοποίηση ⇒ churn (KT4)· διατηρείται **μόνο** στο επίπεδο item |
| (b) ELI/ECLI URI ως μοναδική ταυτότητα | = | − | = | = | + | = | = | = | = | = | = | = | Ελλάδα: μερική κάλυψη ECLI (AS-IS EV-4, U-7), ανύπαρκτη για προ-ELI/ακατάγραφες πράξεις· κανένα manifestation επίπεδο ⇒ αδύνατη η δέσμευση bytes ↔ αντικείμενο (RC-29)· διατηρείται ως **προβολή** (§4.11) |
| (c) surrogate ids βάσης δεδομένων | = | = | − | = | − | = | = | + | − | − | = | = | μη ανεξάρτητα ανασυγκροτήσιμα· μη διαλειτουργικά |

**Falsifier:** πλήρης κρατική κάλυψη ELI/ECLI με manifestation-level δέσμευση bytes
— τότε το (b) εξισώνεται και το USC γίνεται προφίλ του.
**Witness:** Q07, Q13, Q24, KW-3, KW-44, KW-45.

### D-03 — Common Lisp πυρήνας + Rust δεύτερος ανεξάρτητος compiler
**Έδρα:** v1.4 §4.4, §4.6· U-5.

| εναλλακτική | A1 | A2 | A3 | A4 | A5 | A6 | A7 | A8 | A9 | A10 | A11 | A12 | γιατί δεν κυριαρχεί |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| (a) μία γλώσσα, ένας compiler | − | = | − | = | = | − | = | + | = | = | = | = | common-mode σφάλματα υλοποίησης μη ανιχνεύσιμα· η N-version συμφωνία δεν είναι αλήθεια, αλλά η διαφωνία **είναι** ανίχνευση (KT10) |
| (b) Python πυρήνας | = | = | = | = | = | = | = | = | − | − | = | = | μη ντετερμινισμός runtime/εξαρτήσεων· η υπάρχουσα έδρα (133 + 48 αρχεία, Σύνταγμα enforced) είναι Lisp — μετανάστευση = αδικαιολόγητη πολυπλοκότητα χωρίς όφελος σε A1 |
| (c) OCaml δεύτερος compiler | = | = | = | = | = | = | = | = | = | = | = | = | **ισοπαλία** σε όλους τους άξονες — δεν κυριαρχεί, δεν κυριαρχείται· η επιλογή Rust (memory safety χωρίς GC στον verifier, HSM/FFI οικοσύστημα) είναι **απόφαση δημιουργού U-5**, όχι κυριαρχία |
| (d) ένας τυπικά επαληθευμένος compiler (Coq extraction) | + | = | = | = | = | = | = | − | = | − | = | = | κλείνει σφάλματα υλοποίησης έναντι της τυπικής προδιαγραφής, **όχι** παρερμηνείες της ίδιας της προδιαγραφής· η νομική σημασιολογία αλλάζει μηνιαία (A10)· δεν αφαιρεί την ανάγκη δεύτερης ανεξάρτητης ανάγνωσης της spec |

**Falsifier:** επίδειξη ότι ένας verified compiler ανιχνεύει όλες τις τάξεις
σφαλμάτων παρερμηνείας spec που ανιχνεύουν οι δύο ανεξάρτητοι compilers.
**Witness:** Q33, Q34, KW-52.

### D-04 — Νευρωνικό επίπεδο εκτός trusted path με κλειστό typed πρωτόκολλο
**Έδρα:** v1.4 §4.3, §4.4· Σύνταγμα `:no-llm-trusted-path`.

| εναλλακτική | A1 | A2 | A3 | A4 | A5 | A6 | A7 | A8 | A9 | A10 | A11 | A12 | γιατί δεν κυριαρχεί |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| (a) LLM-in-the-loop με guardrails | − | − | − | = | = | − | = | + | − | = | − | − | φρουρός αντί δομής· μη αναπαραγώγιμο· η κανονική κατάσταση γράφεται από συμπερασμό |
| (b) fine-tuned extractor που γράφει απευθείας PLANE-1 | − | − | − | = | = | − | = | + | − | = | = | = | καμία ανεξάρτητη επαναπαραγωγή· η πύλη «neural προτείνει / symbolic κρίνει» (`legal-extraction-verify.lisp`) υπάρχει ήδη και είναι ανώτερη |
| (c) κανένα νευρωνικό (μόνο κανόνες/OCR-engines) | = | − | = | = | = | + | = | − | + | = | = | = | πληρότητα σε σαρωμένο ιστορικό ΦΕΚ και layout (MIS-2) μη επιτεύξιμη· **διατηρείται** ως διαδρομή όπου επαρκεί (native PDF/XML) — το νευρωνικό δεν είναι υποχρεωτικό, είναι επιτρεπτό μόνο ως candidate |

**Falsifier:** νευρωνικό συστατικό με αποδεδειγμένο ντετερμινισμό και
επαληθεύσιμες παραγωγές (derivations) — δεν υπάρχει γνωστό.
**Witness:** Q09, Q31, Q32, Q33, KW-7, KW-49, KW-50.

### D-05 — MLTP v3: Layer 0 + IssuedClaim / TrustBundle / VerificationReceipt (+ CertifiedResult)
**Έδρα:** `MACHINE-LEGAL-TRUST-PROTOCOL.md` v3.

| εναλλακτική | A1 | A2 | A3 | A4 | A5 | A6 | A7 | A8 | A9 | A10 | A11 | A12 | γιατί δεν κυριαρχεί |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| (a) X.509/PKIX πιστοποιητικά ανά claim | = | − | − | − | = | = | = | = | = | − | − | = | κανένα typed νομικό payload· CRL/OCSP σημασιολογία online· καμία διάκριση qualification από ταυτότητα κλειδιού |
| (b) W3C VC/DID ως πυρήνας | = | = | − | − | + | − | = | = | − | = | = | = | JSON-LD canonicalization στο trusted path (A6/A9)· κανένα bitemporal/legal profile· **επιτρεπτό ως προαιρετικό envelope** (CAP-133) |
| (c) plain JWS ανά έγγραφο, χωρίς bundle | = | − | − | = | = | = | = | + | = | = | − | = | καμία offline επίλυση registries/qualification/revocation (RC-06 έως RC-09)· κανένα `UNKNOWN_FRESHNESS` |
| (d) SCITT-only | − | − | = | − | + | = | = | = | = | = | = | = | κανένα νομικό payload/profile· διατηρείται ως **προβολή** (D-10) |

**Falsifier:** πρότυπο που παρέχει typed νομικά claims + offline-resolvable trust
state + διαχωρισμό qualification — τότε το MLTP v3 γίνεται profile του.
**Witness:** Q21, Q22, KW-1, KW-17 έως KW-47.

### D-06 — RFC 9162 Merkle (SHA-256) για inclusion + Ed25519/RS256 για υπογραφές + RFC-3161 TSR επί της υπογραφής
**Έδρα:** MLTP v3 §1.3, §4.1, §5.

| εναλλακτική | A1 | A2 | A3 | A4 | A5 | A6 | A7 | A8 | A9 | A10 | A11 | A12 | γιατί δεν κυριαρχεί |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| (a) «SHA-256 μόνο» | − | − | − | = | = | − | = | + | = | = | = | = | inclusion ≠ αυθεντικοποίηση (RC-16)· κανένα κλειδί = καμία εξουσία |
| (b) RS256 μόνο | = | = | = | = | = | = | = | − | = | = | = | = | ίσο σε A1, χειρότερο σε μέγεθος/ταχύτητα· **διατηρείται** για era-1 (PCL-1) |
| (c) blockchain anchoring για χρόνο | = | = | − | = | − | = | = | − | − | = | − | = | ο χρόνος του block δεν είναι αυθεντικοποιημένος από θεσμό· βλ. D-11 |
| (d) Roughtime/NTS για χρόνο | = | = | = | = | = | = | = | = | = | = | = | = | αποδεικνύει **τρέχοντα** χρόνο στον καταναλωτή (`LocalTrustState.trusted_time` evidence) — **συμπληρωματικό**, όχι υποκατάστατο του TSR επί της υπογραφής |

**Falsifier:** τυποποιημένη offline-επαληθεύσιμη μαρτυρία χρόνου με ευρύτερη
ανεξαρτησία TSA από την RFC-3161 — τότε αντικαθιστά το anchor `kind`.
**Witness:** Q22, Q23, KW-2, KW-19, KW-42.

### D-07 — Threshold owner root (FROST-Ed25519 3-of-5)
**Έδρα:** MLTP v3 §10.2· `LAWMAX-TRUST-BOOTSTRAP-SPEC.md` (EXTEND).

| εναλλακτική | A1 | A2 | A3 | A4 | A5 | A6 | A7 | A8 | A9 | A10 | A11 | A12 | γιατί δεν κυριαρχεί |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| (a) ένα offline owner κλειδί | = | = | = | = | = | − | − | + | = | = | − | = | μία συμβιβασμένη ή χαμένη συσκευή = απώλεια/κατάληψη root |
| (b) n-of-m ξεχωριστές υπογραφές (λίστα υπογραφών) | = | = | = | = | − | = | = | − | = | = | = | = | ίσο σε ασφάλεια· μεγαλύτερα statements και πολυπλοκότερος verifier· **fallback** αν το FROST δεν τυποποιηθεί |
| (c) ένα HSM-held root | = | = | = | = | = | = | − | + | = | = | − | = | vendor/single-custody εξάρτηση· καμία διασπορά εξουσίας |

**Falsifier:** αστάθεια/απόσυρση της τυποποίησης FROST ⇒ μετάπτωση στο (b) με την
**ίδια** πολιτική 3-of-5 (ο μηχανισμός αλλάζει, η πολιτική όχι).
**Witness:** Q17, Q23, KW-9.

### D-08 — HSM-backed delegated release keys με μέγιστη διάρκεια 90 ημερών
**Έδρα:** MLTP v3 §8.3 K3, §10.2· `LAWMAX-KEY-LIFECYCLE-SPEC.md`.

| εναλλακτική | A1 | A2 | A3 | A4 | A5 | A6 | A7 | A8 | A9 | A10 | A11 | A12 | γιατί δεν κυριαρχεί |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| (a) delegated κλειδιά 1 έτους | = | = | = | = | = | − | = | + | = | = | = | = | μεγαλύτερο παράθυρο κατάχρησης μετά από compromise |
| (b) εφήμερο κλειδί ανά release | = | = | = | = | = | + | = | − | = | = | − | = | συχνότητα ceremonies και αύξηση του delegation log· η θεσμική διακυβέρνηση δεν αντέχει ceremony ανά ημέρα |
| (c) καμία delegation (root υπογράφει τα πάντα) | = | = | = | = | = | − | − | = | = | = | − | = | το threshold root online = αντίφαση με D-07 |

**Falsifier:** μετρημένο κόστος ceremony που καθιστά τις 90 ημέρες ανέφικτες ⇒
αλλάζει το παράθυρο (αριθμός, U-1), όχι ο μηχανισμός.
**Witness:** Q26, KW-20, KW-41.

### D-09 — Δύο transparency logs με cross-logging + gossip + ≥2 cross-client θεσμικοί witnesses
**Έδρα:** MLTP v3 §10, §8.3 L1–L3.

| εναλλακτική | A1 | A2 | A3 | A4 | A5 | A6 | A7 | A8 | A9 | A10 | A11 | A12 | γιατί δεν κυριαρχεί |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| (a) ένα log (Sigstore-class) | = | = | = | = | = | − | − | + | = | = | − | = | equivocation του log operator μη ανιχνεύσιμη· GitHub/TSA «witnesses» ελεγχόμενοι από τον ίδιο owner (RC-31) |
| (b) log + gossip χωρίς witnesses | = | = | − | = | = | − | = | + | = | = | = | = | first-time consumer απροστάτευτος· split-view ανιχνεύσιμο μόνο εκ των υστέρων |
| (c) blockchain | βλ. D-11 | | | | | | | | | | | | |

**Falsifier:** μη διαθεσιμότητα ανεξάρτητων θεσμικών witnesses (U-2) ⇒ τεκμηριωμένη
υποβάθμιση σε `split-view-unverifiable` ⇒ `UNKNOWN` — ποτέ σε `VERIFIED`.
**Witness:** Q23, KW-5, KW-15, KW-40, KW-47.

### D-10 — SCITT ως προβολή (Signed Statements / Receipts), όχι ως πυρήνας
**Έδρα:** MLTP v3 §11· v1.4 §4.11.

| εναλλακτική | A1 | A2 | A3 | A4 | A5 | A6 | A7 | A8 | A9 | A10 | A11 | A12 | γιατί δεν κυριαρχεί |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| (a) SCITT ως πυρήνας | − | − | = | − | + | = | = | = | = | = | = | = | κανένα νομικό profile, καμία διτεμπορικότητα, καμία qualification σημασιολογία |
| (b) καμία SCITT προβολή | = | = | = | = | − | = | = | + | = | = | = | = | χάνεται διαλειτουργικότητα με γενικούς transparency verifiers |

**Falsifier:** SCITT profiles που ισοδυναμούν με τα 8 MLTP v3 claim types ⇒ το MLTP
v3 γίνεται SCITT profile (διαδρομή εξελιξιμότητας, όχι απόρριψη).
**Witness:** Q38.

### D-11 — Απόρριψη blockchain / ZK proofs / VC-DID στον πυρήνα (CAP-131, CAP-132, CAP-133)
**Έδρα:** crosswalk §B.10· `LAWMAX-PROOF-OBJECT-SPEC.md §5`.

| απορριφθέν | A1 | A2 | A3 | A4 | A5 | A6 | A7 | A8 | A9 | A10 | A11 | A12 | γιατί δεν κυριαρχεί των witnessed logs + MLTP v3 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| blockchain anchoring/consensus | = | = | − | = | − | = | = | − | − | − | − | = | ο consensus δεν είναι θεσμική εξουσία· κόστος/latency· μη αναπαραγώγιμο χωρίς το δίκτυο· διακυβέρνηση εκτός Ιδρύματος |
| ZK-SNARK/STARK proofs | = | − | − | = | − | = | = | − | = | − | = | = | κρύβουν τον συλλογισμό — αντίθετο στο proof-carrying αξίωμα (η απόδειξη πρέπει να **διαβάζεται**) |
| VC/DID ως trust layer | = | = | − | − | + | − | = | = | − | = | = | = | JSON-LD canonicalization στο trusted path· κανένα legal/bitemporal profile· επιτρεπτό μόνο ως προαιρετικό envelope |

**Falsifier:** επίδειξη ότι ένα από τα τρία είναι όχι χειρότερο σε **κάθε** άξονα
έναντι D-05/D-06/D-09 — τότε αίρεται η απόρριψη για εκείνο μόνο.
**Witness:** πάσο 2· R-70.

### D-12 — Proposer-blind M5 + dual compilers αντί N-version voting
**Έδρα:** v1.4 §4.6· v1.2 M5 (KT10)· Q11.

| εναλλακτική | A1 | A2 | A3 | A4 | A5 | A6 | A7 | A8 | A9 | A10 | A11 | A12 | γιατί δεν κυριαρχεί |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| (a) N-version majority ως admission predicate | − | − | = | = | = | − | = | + | = | = | − | = | συμφωνία ≠ αλήθεια (KT10)· κοινές παρερμηνείες περνούν με πλειοψηφία |
| (b) ένας ανθρώπινος reviewer ως πύλη | = | = | − | = | = | − | − | − | − | = | = | + | μη κλιμακώσιμο σε εθνικό census· μη αναπαραγώγιμο· διατηρείται **μόνο** για τάξη 3 (jurisprudential analysis, reviewer adoption) |
| (c) τυπική επαλήθευση ενός compiler | βλ. D-03 (d) | | | | | | | | | | | | |

**Falsifier:** counterexample όπου η διαφωνία δύο ανεξάρτητων compilers δεν
ανιχνεύει σφάλμα που η N-version πλειοψηφία ανιχνεύει — δεν υπάρχει γνωστό (η
διαφωνία περιέχει την πλειοψηφική πληροφορία).
**Witness:** Q11, Q34, KW-52.

### D-13 — Παραπομπή ΜΕΣΑ στα υπογεγραμμένα bytes (`CertifiedResult` + `citation/1`), όχι έξω από την υπογραφή
**Έδρα:** MLTP v3 §2.10, §8.3 C· v1.4 §4.16.

| εναλλακτική | A1 | A2 | A3 | A4 | A5 | A6 | A7 | A8 | A9 | A10 | A11 | A12 | γιατί δεν κυριαρχεί |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| (a) παραπομπή σε HTTP headers / metadata εκτός υπογραφής | = | = | = | = | = | − | = | + | = | = | − | = | αφαιρείται ενώ η υπογραφή μένει έγκυρη ⇒ ο provider κρατά `VERIFIED` χωρίς απόδοση — ακριβώς η αποτυχία που η διευκρίνιση απαγορεύει |
| (b) μόνο άδεια/σύμβαση | = | = | = | = | = | − | = | + | = | = | − | = | μηδενική τεχνική επιβολή· εκτός αρχιτεκτονικής (δηλωμένο εξωτερικό) |
| (c) watermarking του κειμένου | − | = | − | = | − | = | = | = | − | = | = | = | αλλοιώνει το κείμενο του νόμου· εύθραυστο· μη επαληθεύσιμο offline |
| (d) μόνο ξεχωριστό `CitationToken` | = | = | = | = | + | − | = | = | = | = | = | = | ο token αφαιρείται από το αποτέλεσμα· **διατηρείται ως φορητό συμπλήρωμα** του δεσμευμένου citation, όχι ως μόνη έδρα |

**Falsifier:** επίδειξη αφαίρεσης του `citation` που αφήνει την υπογραφή του
`CertifiedResult` έγκυρη — αυτό είναι ο KW-62· αν συμβεί, η έδρα §2.10 είναι λάθος.
**Τίμιο όριο (όχι falsifier):** το σύστημα δεν εμποδίζει αντιγραφή δημόσιου
κειμένου χωρίς απόδοση εκτός του ελέγχου του· εγγυάται μόνο ότι καμία
**επαληθευμένη** αναπαράσταση δεν επιβιώνει χωρίς παραπομπή.
**Witness:** Q42, KW-62, KW-63.

### D-14 — Cryptographic agility & long-term evidence preservation (POST-C2 Finding 2)
**Έδρα:** MLTP v3 §14· v1.4 §4.18.

| εναλλακτική | γιατί δεν κυριαρχεί |
|---|---|
| (a) πινάρισμα μιας suite για πάντα (μόνο Ed25519/SHA-256) | αποτυγχάνει μακροπρόθεσμα: αλγοριθμική απαξίωση + harvest-now-forge-later· ένα δημόσιο νομικό αρχείο πρέπει να επιβιώνει δεκαετίες |
| (b) rip-and-replace migration (επανεγγραφή ιστορικών αντικειμένων στη νέα suite) | καταστρέφει την ακεραιότητα content-addressing και την ιστορική αποδεικτική αλυσίδα· τα `*_id` αλλάζουν |
| (c) επιβολή SHA-3 / PQ **τώρα** ανεπιφύλακτα | πρόωρο (κανένα threat σήμερα), σπάει interop, «ψευδο-ασφάλεια» χωρίς πολιτική |
| (d) OR-σύνθεση classical/PQ (αρκεί μία υπογραφή) | ο αντίπαλος που σπάει τη μία επιλέγει την ασθενέστερη ⇒ καμία downgrade resistance |

**Επιλογή:** versioned suite registry + root-signed policy epochs + hybrid **AND** +
evidence-renewal chains + verifier ανά εποχή. Κυριαρχεί: ιστορικά αντικείμενα αμετάβλητα
**ΚΑΙ** επιβίωση αλγοριθμικού σπασίματος (renewal) **ΚΑΙ** downgrade-resistant (root-pinned
epoch). **Falsifier:** object που στηρίζεται σε `sunset` suite μετά το `sunset_at` και
επιστρέφει `VERIFIED` χωρίς renewal chain ⇒ το προφίλ είναι λάθος. **Witness:** KW-104.
**Τίμιο όριο:** το χρονοδιάγραμμα US/NSS **δεν** δεσμεύει· η πολιτική epochs είναι
απόφαση ελληνικής διακυβέρνησης.

### D-15 — Temporal ontology & validation governance (POST-C2 Finding 3)
**Έδρα:** MLTP v3 §2.11· v1.4 §4.19.

| εναλλακτική | γιατί δεν κυριαρχεί |
|---|---|
| (a) μετάλλαξη shapes επί τόπου + επαναεπικύρωση όλων | αναδρομικά ακυρώνει ιστορική συμμόρφωση ⇒ παραβιάζει διτεμπορική τιμιότητα (MIS-3) |
| (b) `valid × known` σε κάθε SHACL shape | συγχέει τρεις χρονικούς άξονες — ρητό anti-pattern του δημιουργού |
| (c) καμία έκδοση (ένα shapes graph) | αλλαγή του 2027 σπάει σιωπηλά τα receipts του 2025 |

**Επιλογή:** content-addressed ontology bundles + receipts δεσμευμένα στο ακριβές
`ontology_bundle_id` + `shapes_graph_digest` + typed migration + καμία σιωπηλή αναδρομική
ακύρωση. **Falsifier:** object του 2025 απορρίπτεται αναδρομικά από 2027 shapes ⇒ λάθος.
**Witness:** KW-106.

### D-16 — Formal semantic contract για ανεξάρτητους compilers (POST-C2 Finding 1)
**Έδρα:** `LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md`· v1.4 §4.17.

| εναλλακτική | γιατί δεν κυριαρχεί |
|---|---|
| (a) παραγωγή αμφότερων compilers από κοινό evaluator | **common-mode failure** — ακυρώνει τον σκοπό του §4.6 (differential verification) |
| (b) υλοποίηση αμφότερων «κατά την πρόζα» | σιωπηλή διάσταση σε προτεραιότητα εξαίρεσης (lex specialis vs posterior) — KW-105 |
| (c) ένας compiler + εξωτερικός έλεγχος | καμία N-version διαφορετικότητα υλοποίησης |

**Επιλογή:** γλωσσο-ανεξάρτητο κανονιστικό συμβόλαιο + conformance corpus
input→derivation + δέσμευση ανεξαρτησίας· μηχανοποιημένο μοντέλο = **oracle μόνο**, ποτέ
κοινή υλοποίηση. **Falsifier:** δύο compilers σιωπηλά διαφορετική προτεραιότητα και
αμφότεροι περνούν ⇒ το συμβόλαιο είναι υποπροσδιορισμένο. **Witness:** KW-105. Επιλογή
Rust/OCaml = implementation decision.

**Ισολογισμός §A:** 16 επιλογές (D-01 έως D-13 + POST-C2 D-14, D-15, D-16)· 0 `DOMINATED`
κατά τη σύνταξη· 1 ισοπαλία που είναι απόφαση δημιουργού (D-03 c, U-5)· κάθε D με
ονομαστικό falsifier.

---

## B. BENCHMARK ΕΝΑΝΤΙ ΤΩΝ ΠΕΝΤΕ ΚΟΡΥΦΑΙΩΝ ΕΠΙΣΗΜΩΝ ΥΠΟΔΟΜΩΝ

### B.0 Βάση τεκμηρίου — ρητή δήλωση (U-4)

Κατά τη σύνταξη (2026-09-01) η δικτυακή έξοδος προς τις πρωτογενείς τεχνικές σελίδες
και των πέντε υποδομών ήταν **αποκλεισμένη** (`EGRESS_BLOCKED` για `op.europa.eu`,
`legislation.gov.uk`, `legifrance.gouv.fr`, `data.finlex.fi`, `govinfo.gov`). Κάθε
κελί του πίνακα B.1 στηρίζεται **μόνο** σε αποσπάσματα αναζήτησης ιστού της ίδιας
ημέρας, με τη σελίδα-πηγή που ονομάζεται στη στήλη «τεκμήριο». Κελί που τα
αποσπάσματα δεν καλύπτουν γράφεται **`UNKNOWN(U-4)`** — όχι εικασία. Ο πίνακας
επαληθεύεται έναντι των ζωντανών πρωτογενών σελίδων στο πάσο 2 (owner: δημιουργός ή
πάσο 2· v1.4 §12 U-4)· κάθε γραμμή τότε γίνεται `CONFIRMED` ή `CORRECTED`.

### B.1 Ο πίνακας

| άξονας | EUR-Lex / Cellar | legislation.gov.uk | Légifrance (DILA) | Finlex / Semantic Finlex | GovInfo (GPO) | v1.4 (στόχος, μη υλοποιημένος) |
|---|---|---|---|---|---|---|
| ταυτότητα | ELI· CDM ευθυγραμμισμένο με ELI/ELI-DL | URI scheme ως πυρήνας του API | `UNKNOWN(U-4)` (ELI δεν αναφέρεται στα αποσπάσματα) | ELI + ECLI | `UNKNOWN(U-4)` | USC work/expression/manifestation/item + ELI/ECLI προβολές (D-02) |
| μοντέλο δεδομένων | CDM: FRBR-compliant OWL οντολογία (Work/Expression/Manifestation/Item + Agent/Dossier/Event) | CLML XML σε native XML βάση· Akoma Ntoso (`/data.akn`) | XML ανά βάση με γενικές/ειδικές DTD (LEGI, JORF, KALI, CASS, JADE, CONSTIT, INCA, CAPP, DOLE, DEBATS) | RDF κατά ELI· consolidated + original acts | USLM XML (beta) σε bulk· «self-describing packages» | typed Legal IR + event-sourced διτεμπορικός γράφος (D-01)· AKN/RDF ως προβολές |
| point-in-time (valid) | `UNKNOWN(U-4)` | ναι — versioned URI με ημερομηνία (π.χ. `/ukpga/1981/54/resources/1999-09-27/data.xml`) | LEGI = consolidated κείμενα· εκδοχές: `UNKNOWN(U-4)` | consolidated legislation (~2.800) | `UNKNOWN(U-4)` | ναι, ανά γεγονός |
| known-time (τι ήξερε το Ίδρυμα) | `UNKNOWN(U-4)` — τα αποσπάσματα δεν το τεκμηριώνουν | `UNKNOWN(U-4)` — τα αποσπάσματα τεκμηριώνουν «changes/effects» λίστες, όχι known-time | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | ναι — `valid × known` (Q06)· νομικός χρόνος ≠ χρόνος ελέγχου (Q41) |
| μηχανικές μορφές / API | δημόσιο SPARQL endpoint επί του CDM | RESTful API· `/data.xml`, `/data.akn`, `/data.feed` (Atom)· λίστες αλλαγών («effects») | PISTE API (σταθερή από 2023-04-04, Swagger)· open data HTTPS/FTPS (`echanges.dila.gouv.fr`) | SPARQL endpoint (Linked Data Finland)· RDF datasets | API πακέτων/μεταδεδομένων· bulk data repository | εκδοχοποιημένο OpenAPI + versioned MCP + SDKs + signed delta feeds + SPARQL (Q14) |
| αυθεντικότητα / υπογραφές | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | ψηφιακές υπογραφές σε PDF με «Seal of Authenticity»· **τα XML (ατομικά ή bulk) ΔΕΝ υπογράφονται** («GPO cannot vouch for the authenticity of data that is not under GPO's control») | **κάθε** claim (JSON/CBOR, όχι μόνο PDF) υπογεγραμμένο με delegated κλειδί υπό threshold root, TSR επί της υπογραφής (D-05, D-06) |
| offline επαλήθευση τρίτου | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | PDF: Acrobat signature validation (blue ribbon)· XML: όχι | ναι — `verify_bundle(bundle, LocalTrustState)` χωρίς δίκτυο, δύο ανεξάρτητες υλοποιήσεις (Q21, Q22) |
| transparency log / witnesses | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | δύο logs, cross-logging, cross-client witnesses, SCITT προβολή (D-09, D-10) |
| citation binding μέσα στην υπογραφή | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | ναι — `CertifiedResult` + `citation/1` (D-13, Q42) |
| typed `UNKNOWN` / `CONFLICTING` στο API | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | `UNKNOWN(U-4)` | ναι, στον τύπο (Q10, Q14) |
| νομολογία ως πρώτης τάξης | δικαστικές αποφάσεις στο Cellar (RDF) | `UNKNOWN(U-4)` | CASS/JADE/CONSTIT/INCA/CAPP βάσεις | Supreme Court (~5.400) + Supreme Administrative Court (~7.000) αποφάσεις ως RDF | `UNKNOWN(U-4)` | τέσσερις τάξεις, line-of-authority, later treatment (Q37) |
| τεκμήριο (αποσπάσματα 2026-09-01) | `eur-lex.europa.eu/eli-register/technical_information.html`· `op.europa.eu/en/web/cellar/cellar-data`· `op.europa.eu/en/web/eu-vocabularies/cdm` | `legislation.github.io/data-documentation/api/overview.html`· `legislation.gov.uk/pdfs/projects/technology-choices-factsheet.pdf` | `legifrance.gouv.fr/contenu/pied-de-page/open-data-et-api`· `data.gouv.fr/datasets/legi-codes-lois-et-reglements-consolides`· `dila.gouv.fr/home/open-data-et-api` | `seco.cs.aalto.fi/projects/lawlod/en/`· `finlex.fi/en/open-data/integration-quick-guide`· `eur-lex.europa.eu/eli-register/finland.html` | `govinfo.gov/media/authenticationoverview.pdf`· `govinfo.gov/features/beta-uslm-xml`· `govinfo.gov/developers` | — |

### B.2 Τι πρέπει να κυριαρχήσει το v1.4 — ανά άξονα, με το ισχυρότερο γνωστό σημείο κάθε υποδομής

| ισχυρό σημείο υποδομής (τεκμηριωμένο) | τι απαιτεί από το v1.4 για να μην είναι κατώτερο | έδρα v1.4 | witness |
|---|---|---|---|
| Cellar: FRBR-compliant CDM οντολογία + δημόσιο SPARQL | ίδια τάξη ταυτότητας (USC) **και** ανά-αντικείμενο proof object· SPARQL προβολή επικυρωμένη με SHACL | D-02· §4.11 (`sparql-endpoint.lisp`, `shacl-validator.lisp`) | Q13, Q38 |
| legislation.gov.uk: point-in-time versioned URIs + Akoma Ntoso + λίστες effects | point-in-time **και** known-time· canonical URI ανά διτεμπορική τομή· effects ως typed γεγονότα με πηγή | D-01· §4.5, §4.7 | Q06, Q14, KW-51 |
| Légifrance: σταθερό εκδοχοποιημένο API + πλήρη open data datasets από 1945 | εκδοχοποιημένο OpenAPI/MCP **και** offline verifier· census universe δηλωμένο (όχι μόνο «εξαντλητικό από 1945» ως ισχυρισμός) | §4.1, §4.15 | Q01, Q29, Q27 |
| Semantic Finlex: ELI + ECLI ως RDF με SPARQL, consolidated + original + case law | ίδιες προβολές **και** επικύρωση, με νομολογία σε τέσσερις τάξεις και line-of-authority | §4.9, §4.11 | Q37, Q38 |
| GovInfo: ψηφιακή υπογραφή με Seal of Authenticity σε PDF | υπογραφή σε **κάθε** μηχανική μορφή (όχι μόνο PDF), offline επαληθεύσιμη, με ανάκληση, qualification και **citation binding** — ακριβώς εκεί που το GovInfo δηλώνει ότι τα XML δεν υπογράφονται | D-05, D-06, D-13 | Q21, Q22, Q42 |

### B.3 Τι ΔΕΝ ισχυρίζεται ο benchmark

- Δεν ισχυρίζεται ότι οι πέντε υποδομές **δεν** έχουν τα χαρακτηριστικά που
  σημειώνονται `UNKNOWN(U-4)` — μόνο ότι τα αποσπάσματα δεν τα τεκμηριώνουν.
- Δεν ισχυρίζεται κυριαρχία του v1.4 **ως υλοποίηση** — το v1.4 δεν έχει υλοποίηση.
  Ισχυρίζεται ότι ο **στόχος** δεν είναι κατώτερος σε κανέναν τεκμηριωμένο άξονα
  και είναι αυστηρά ανώτερος σε known-time, offline επαλήθευση κάθε μορφής,
  typed `UNKNOWN`, και citation binding — ισχυρισμοί προς έλεγχο στο πάσο 2.
- Δεν συγκρίνει νομική αυθεντία: όλες οι πέντε είναι ή εκπροσωπούν de jure πηγές·
  το Watchtower δεν είναι και δεν γίνεται (MIS-8).
