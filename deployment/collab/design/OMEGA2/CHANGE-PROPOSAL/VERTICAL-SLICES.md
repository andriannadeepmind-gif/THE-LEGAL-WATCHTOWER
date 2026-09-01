# VERTICAL SLICES — 15 ΕΚΤΕΛΕΣΙΜΕΣ ΚΑΘΕΤΕΣ ΦΕΤΕΣ ΠΡΙΝ ΤΟ FREEZE (ΠΡΟΔΗΛΩΜΕΝΕΣ)

**ΚΑΤΑΣΤΑΣΗ: ΠΡΟΔΗΛΩΜΕΝΕΣ — ΚΑΜΙΑ ΔΕΝ ΕΧΕΙ ΕΚΤΕΛΕΣΤΕΙ. ΚΑΜΙΑ ΥΛΟΠΟΙΗΣΗ.**

Κανόνας του `CHANGE-PROPOSAL-v1.4.md §9`: **σχεδιαστική αξίωση που δεν αποδεικνύεται
με εκτελέσιμη φέτα δεν είναι freezeable.** Κάθε φέτα εδώ είναι μια πλήρης, κάθετη
διαδρομή από πραγματική είσοδο μέχρι επαληθεύσιμη έξοδο, με **ορισμένη** είσοδο,
**ορισμένα** βήματα, **τυπωμένη** αναμενόμενη έξοδο, **αρνητικό μάρτυρα**, **evidence
bundle** και **δυαδικό κριτήριο εξόδου**. Οι φέτες εκτελούνται στα βήματα του
`IMPLEMENTATION-SEQUENCE.md` που δηλώνει κάθε μία· η ολοκλήρωση και των 15 είναι
προϋπόθεση του `IMPLEMENTATION QUALIFIED` (Q-tests §2) και της πρότασης freeze (v1.4 §13).

**Κοινοί κανόνες κάθε φέτας:**
- Η είσοδος είναι πραγματικό επίσημο υλικό ήδη γνωστό στο repo ή στο census, ποτέ
  συνθετικό «παράδειγμα» — εκτός από τις μεταλλάξεις των αρνητικών μαρτύρων, που
  δηλώνονται ως τέτοιες.
- Το evidence bundle είναι κατάλογος αρχείων με SHA-256 και ένα `run.log` με
  command + exit code ανά βήμα· κατατίθεται σε `V1.4-SLICES/VS-nn/` όταν εκτελεστεί.
- Η φέτα περνά **μόνο** αν και το θετικό σενάριο και ο αρνητικός μάρτυρας δίνουν το
  αναμενόμενο· «πέρασε το θετικό» χωρίς μάρτυρα = `BLOCKED — NOT EXECUTED` (Κ-5).
- Κανένα LLM στη διαδρομή της φέτας εκτός από τον ρόλο `neural-candidate/1` όπου
  δηλώνεται (VS-04, VS-05, VS-06).
- Κάθε φέτα ονομάζει τα Q και KW της (`PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md`).

---

### VS-01 — Πηγή → receipt → Legal IR → γεγονός → διτεμπορική κατάσταση → proof-carrying answer
**Αποστολή / επίπεδα:** MIS-1, MIS-3 · §4.2, §4.5, §4.7, §4.16.
**Έδρες:** `document-fetch.lisp`, `pdf-authority.lisp`, `corpus-provenance.lisp`,
`legal-identity.lisp`, `legal-ast.lisp`, `version-graph.lisp`, `journal.lisp`,
`consolidation-engine.lisp`, `legal-qa.lisp`, `proof-carrying.lisp`, MLTP v3 §2.1/§2.2/§2.10.
**Είσοδος (ορισμένη):** το ήδη attested PDF του Συντάγματος (άρθρο 4) της φάσης
Π7-U.1 Φ1 (STATE-OF-PLAY: pdf `fd72ebd5`, σελ. 29, text-layer αποδεδειγμένο) — ένα
manifestation, ένα work, μία expression.
**Βήματα:** (1) acquisition με `acq1:` receipt, custody chain, TSR επί των bytes·
(2) `authority-proof/2` βαθμού ≥ S1 + `ireg1:` register id· (3) USC ids: `work_id`,
`expression_id`, `manifestation_id`, item digest· (4) Legal IR του άρθρου με
`norm.determinacy`· (5) γεγονός `ENACTMENT` με `manifestation_id` + anchor στο journal·
(6) `legal-timeline/1` στο payload (`issued_at`, `published_at`, `effective_from`,
`effective_to: null`, `ceased_by: null`, `cessation_type: null`)· `audit-timeline/1`
στο `proof_material`· (7) compile ⇒ `legal_state_root`· (8) ερώτημα «τι ισχύει στο
`(v, k)`» ⇒ `proof-carrying-answer/1` με όλα τα πεδία του §4.7· (9) `CertifiedResult`
με `citation/1` και `citation_digest`· (10) τοπική επαλήθευση με `verify.py` **και**
`verify.mjs`.
**Αναμενόμενη έξοδος:** δύο ταυτόσημα `VerificationReceipt` με `result: VERIFIED`
για τα claims `source-authenticity`, `legal-state`, `CertifiedResult`· η απάντηση
δείχνει `legal_timeline` και `citation`, **όχι** `acquired_at`.
**Αρνητικός μάρτυρας:** (α) αφαίρεση του `authority_proof_ref` ⇒ `insufficient-provenance`
⇒ `UNKNOWN` (KW-4)· (β) `acquired_at` μέσα στο payload ⇒ `malformed-envelope` (KW-61)·
(γ) αλλοίωση ενός byte του `proof_material` ⇒ `sig-invalid` (KW-17).
**Evidence bundle:** receipts, claims, bundle, δύο receipts, run.log, digests.
**Κριτήριο εξόδου:** θετικό = 2/2 verifiers `VERIFIED`· μάρτυρες α/β/γ = 3/3 typed
αποτυχίες· αλλιώς `FAIL`.
**Βήμα υλοποίησης:** checkpoints στα βήματα 2 (1–3), 3 (4–6), 4 (7)· **ολοκλήρωση στο 11** (8–10).
**Q / KW:** Q03, Q06, Q35, Q41, Q42 · KW-4, KW-17, KW-61.

### VS-02 — Άμεση και έμμεση τροποποίηση με μελλοντική έναρξη ισχύος
**Αποστολή / επίπεδα:** MIS-3 · §4.5, §4.8.
**Έδρες:** `amendment-extractor.lisp`, `version-graph.lisp`, `legal-temporal.lisp`,
`consolidation-engine.lisp`, `consolidation-proof.lisp`, `graph-reasoning.lisp` (`reason-impact`).
**Είσοδος (ορισμένη):** Ν. 5221/2025 (ΦΕΚ Α΄ 133) — τροποποιήσεις ΑΚ/ΚΠολΔ με έναρξη
ισχύος 1/1/2026 (άμεση τροποποίηση + μεταβατική διάταξη = έμμεση επίδραση σε
εκκρεμείς σχέσεις)· και Ν. 5303/2026 (ΦΕΚ Α΄ 81) — νέο κληρονομικό δίκαιο με έναρξη
16/9/2026 (`cessation_type: replacement` για τις αντικαθιστώμενες διατάξεις).
Και τα δύο καταγεγραμμένα ως εκκρεμότητα ουσίας στο STATE-OF-PLAY.
**Βήματα:** (1) γεγονότα `AMENDMENT` (άμεση) με στόχο υπάρχουσα διάταξη· (2)
γεγονός `COMMENCEMENT` με `effective_from` μεταγενέστερο του `published_at`· (3)
έμμεση επίδραση ως `CROSS-REFERENCE` + `UNCERTAINTY(kind=transitional)` όπου η
μεταβατική διάταξη δεν αποφασίζεται μηχανικά· (4) `REPEAL`/`replacement` με
`ceased_by` = work_id του νέου νόμου· (5) προβολές σε τρεις τομές: `(v=2025-12-31,
k=τώρα)`, `(v=2026-01-01, k=τώρα)`, `(v=2026-01-01, k=2025-12-01)`· (6)
`normative-impact-projection` με `replay_manifest`.
**Αναμενόμενη έξοδος:** η τομή (v=2025-12-31) δείχνει το παλιό κείμενο· η
(v=2026-01-01, k=τώρα) το νέο· η (v=2026-01-01, k=2025-12-01) δείχνει το κείμενο
**όπως ήταν γνωστό** τότε — δηλαδή χωρίς γεγονότα με `known_from > k`· το
`impact_root` αναπαράγεται από auditor.
**Αρνητικός μάρτυρας:** (α) αφαίρεση του ενδιάμεσου `AMENDMENT` ⇒ η αλυσίδα σπάει
ορατά (`CONFLICTING`, ανύπαρκτος στόχος), όχι γεφύρωση (Q05)· (β) γεγονός χωρίς
`manifestation_id` ⇒ απόρριψη στην admission (KW-51)· (γ) `ceased_by` χωρίς
`cessation_type` ⇒ `schema-mismatch` (Q41 δ)· (δ) impact claim με πεδίο έκβασης ⇒
δεν μεταγλωττίζεται (KW-54)· (ε) verifier που κρίνει ισχύ από `verified_at` ⇒
κοκκίνισμα (KW-60).
**Evidence bundle:** journal excerpt, τρεις προβολές με digests, impact claim +
replay manifest, auditor re-run log.
**Κριτήριο εξόδου:** 3/3 προβολές σωστές έναντι του ΦΕΚ· `impact_root` ίσο σε δύο
εκτελέσεις· 5/5 μάρτυρες typed.
**Βήμα υλοποίησης:** checkpoints 3 (1–4), 4 (5)· **ολοκλήρωση στο 10** (6).
**Q / KW:** Q05, Q06, Q08, Q36, Q41 · KW-51, KW-54, KW-60.

### VS-03 — Σύγκρουση δύο επίσημων manifestations του ίδιου work
**Αποστολή / επίπεδα:** MIS-1, MIS-7 · §4.2.
**Έδρες:** `source-profile.lisp` (ranked channels), `legal-identity.lisp`,
`corpus-provenance.lisp`, USC §8 `SOURCE-CONFLICT`, MLTP v3 §2.1 `divergence_ref`.
**Είσοδος (ορισμένη):** η ίδια υπουργική απόφαση από δύο επίσημα κανάλια — ΦΕΚ Β΄ PDF
(Εθνικό Τυπογραφείο) και ανάρτηση στη Διαύγεια (κανάλι, όχι αρχή) — με **πραγματική**
διαφορά κειμένου (τουλάχιστον ένας χαρακτήρας σε αριθμό/ημερομηνία), εντοπισμένη
στο βήμα 2 από τον radar· αν δεν βρεθεί πραγματική διαφορά, η φέτα δηλώνεται
`BLOCKED — NO FIXTURE`, όχι «πέρασε».
**Βήματα:** (1) acquisition και των δύο με χωριστά `manifestation_id` + receipts·
(2) ίδιο `work_id`· (3) σύγκριση κανονικοποιημένων κειμένων ⇒ δύο `expression_id`·
(4) `divergence_ref` (`official-sources-conflict`) ⇒ `legal-state` payload `UNDEC`·
(5) verifier βήμα S.
**Αναμενόμενη έξοδος:** `CONFLICTING` (typed reason του `UNKNOWN`) και στον εκδότη
και στον local verifier (`undecided-legal-state`)· κανένα «νικητής» κανάλι.
**Αρνητικός μάρτυρας:** (α) ranked-channel λογική που επιλέγει σιωπηλά το ΦΕΚ ⇒
κοκκίνισμα (Q03 δ)· (β) verifier που δέχεται `UNDEC` ως `VERIFIED` ⇒ KW-29· (γ)
σχεδίαση που δίνει δύο `work_id` ⇒ KW-3.
**Evidence bundle:** δύο manifestations, receipts, divergence record, receipt του
verifier.
**Κριτήριο εξόδου:** `UNKNOWN(official-sources-conflict)` σε 2/2 verifiers· 3/3
μάρτυρες.
**Βήμα υλοποίησης:** **ολοκλήρωση στο 2** (βήματα 1–4)· ο verifier έλεγχος (5) στο 6.
**Q / KW:** Q03, Q10, Q13, Q24 · KW-3, KW-29.

### VS-04 — OCR/layout διαφθορά και ανάκαμψη
**Αποστολή / επίπεδα:** MIS-2, MIS-7 · §4.2, §4.3, §4.4.
**Έδρες:** νευρωνικό runtime (εξωτερικό), `safe-read.lisp`, `legal-extraction-verify.lisp`,
`layout-types.lisp`, `validate-layout-graph.lisp`.
**Είσοδος (ορισμένη):** μία σαρωμένη σελίδα ιστορικού ΦΕΚ (προ-2000, χωρίς text
layer) από το census· και η **δηλωμένη μετάλλαξή** της (σελίδα περιστραμμένη 90°,
bit-flip σε 1% των bytes της εικόνας).
**Βήματα:** (1) `neural-task/1 kind=ocr-text` με καρφωμένο `runtime_manifest_sha256`·
(2) `neural-candidate/1` με page/bbox anchors, `uncertainty`, `alternatives`· (3)
συμβολική επικύρωση: layout graph, τυπογραφικός ταξινομητής, σύγκριση με held-out
αλήθεια (U-6) όπου υπάρχει· (4) προαγωγή σε PLANE-1 **μόνο** αν σφάλμα < κατώφλι
(U-1)· αλλιώς `UNKNOWN(ocr-below-threshold)`.
**Αναμενόμενη έξοδος:** καθαρή σάρωση ⇒ PLANE-1 κείμενο με anchors· διεφθαρμένη ⇒
`UNKNOWN` typed, ποτέ PLANE-1· ίδια είσοδος + ίδιο manifest ⇒ ίδιο `candidate_id`.
**Αρνητικός μάρτυρας:** (α) διεφθαρμένη σάρωση που προάγεται ⇒ κοκκίνισμα (Q30 α)·
(β) candidate χωρίς anchor που γίνεται δεκτό ⇒ KW-49· (γ) αλλαγή runtime manifest
χωρίς αλλαγή pin ⇒ κοκκίνισμα (Q04).
**Evidence bundle:** task/candidate JSON, layout validation log, δύο εκτελέσεις
με ίδιο `candidate_id`, held-out μέτρηση.
**Κριτήριο εξόδου:** ντετερμινισμός 2/2· διεφθαρμένη ⇒ `UNKNOWN`· 3/3 μάρτυρες.
**Βήμα υλοποίησης:** **ολοκλήρωση στο 7**.
**Q / KW:** Q04, Q30, Q31 · KW-49. **Ανοιχτά:** U-1, U-6.

### VS-05 — Σύγκρουση οντοτήτων οντολογίας και αποχή
**Αποστολή / επίπεδα:** MIS-7 · §4.3.
**Έδρες:** `greek-legislation-ontology.lisp`, `knowledge-graph.lisp`, `rdfs-inference.lisp`,
`shacl-validator.lisp`, `proposals.lisp` (L5).
**Είσοδος (ορισμένη):** ο όρος «επιχείρηση» σε δύο διατάξεις διαφορετικών κλάδων
(φορολογική και εργατική νομοθεσία) όπου η οντολογία έχει δύο διακριτές έννοιες·
ο νευρωνικός aligner προτείνει `ontology-mapping` candidates και για τις δύο.
**Βήματα:** (1) candidates με anchors· (2) συμβολικός έλεγχος συνέπειας (SHACL +
περιορισμοί κλάδου)· (3) όπου η αντιστοίχιση δεν αποφασίζεται ⇒ L5 υπόθεση με
κύκλο ζωής + `UNKNOWN(ontology-conflict)` typed· (4) καμία εγγραφή στον γράφο
χωρίς επικύρωση.
**Αναμενόμενη έξοδος:** μία αντιστοίχιση επικυρωμένη όπου οι περιορισμοί το
αποδεικνύουν· `UNKNOWN` typed αλλού· η υπόθεση L5 λήγει ή υιοθετείται με πράξη.
**Αρνητικός μάρτυρας:** (α) mapping με `score` υψηλό αλλά χωρίς συμβολική επικύρωση
που γράφεται στον γράφο ⇒ κοκκίνισμα (I-4.3d)· (β) υπόθεση L5 που εμφανίζεται σε
release ⇒ δεν μεταγλωττίζεται (Q09)· (γ) σιωπηλή επιλογή της «πιθανότερης» έννοιας ⇒
κοκκίνισμα (Q10).
**Evidence bundle:** candidates, SHACL report, L5 record με lifecycle, γράφος diff.
**Κριτήριο εξόδου:** 0 εγγραφές γράφου χωρίς επικύρωση· 3/3 μάρτυρες.
**Βήμα υλοποίησης:** **ολοκλήρωση στο 7**.
**Q / KW:** Q09, Q10, Q31 · KW-7, KW-49.

### VS-06 — Νευρωνικός candidate απορριπτόμενος από συμβολικούς περιορισμούς
**Αποστολή / επίπεδα:** MIS-1, MIS-7 · §4.3, §4.4, §4.5.
**Έδρες:** `legal-extraction-verify.lisp`, `amendment-extractor.lisp`, `version-graph.lisp`,
`write-authority.lisp`, `safe-read.lisp`.
**Είσοδος (ορισμένη):** `neural-candidate/1 kind=legal-event` που ισχυρίζεται
τροποποίηση **ανύπαρκτου** άρθρου (π.χ. αναφορά σε αριθμό άρθρου πέραν του τελευταίου
του νόμου-στόχου) — παραγόμενος από το runtime πάνω σε πραγματικό ΦΕΚ με λάθος
ανάγνωση αριθμού.
**Βήματα:** (1) candidate μέσω `safe-read.lisp`· (2) συμβολικός έλεγχος: ο στόχος
δεν υπάρχει στη διτεμπορική κατάσταση ⇒ απόρριψη με typed αιτία· (3) καταγραφή της
απόρριψης στο journal ως L5 συμβάν (όχι ως γεγονός νόμου)· (4) απόπειρα του runtime
να γράψει απευθείας στο journal.
**Αναμενόμενη έξοδος:** κανένα γεγονός στο journal· απόρριψη typed· η απόπειρα
εγγραφής αποτυγχάνει στη μία έδρα εγγραφής (`write-authority.lisp`).
**Αρνητικός μάρτυρας:** (α) candidate που γίνεται γεγονός χωρίς επικύρωση ⇒
κοκκίνισμα· (β) runtime με διαδρομή εγγραφής ⇒ Q33 α· (γ) PLANE-3 αντικείμενο σε
release artifact ⇒ αποτυχία τύπου (Q09).
**Evidence bundle:** candidate, rejection record, journal diff (κενό), write
attempt log.
**Κριτήριο εξόδου:** 0 γεγονότα· 3/3 μάρτυρες.
**Βήμα υλοποίησης:** checkpoint 7· **ολοκλήρωση στο 8**.
**Q / KW:** Q09, Q31, Q33 · KW-7, KW-49.

### VS-07 — Open-textured κανόνας ⇒ `UNKNOWN(interpretive)` με typed εναλλακτικές
**Αποστολή / επίπεδα:** MIS-7 · §4.3.
**Έδρες:** `legal-ast.lisp` (`norm.determinacy`), `legal-inference-engine.lisp`,
`legal-deontic.lisp`, `legal-dialectic.lisp`, `legal-qa.lisp`.
**Είσοδος (ορισμένη):** ΑΚ άρθρο 281 (κατάχρηση δικαιώματος — «καλή πίστη», «χρηστά
ήθη», «κοινωνικός ή οικονομικός σκοπός του δικαιώματος») ως Legal IR με
`determinacy: interpretive`· ερώτημα «απαγορεύεται η άσκηση του δικαιώματος Χ;» με
δημόσια, πηγο-δεμένα γεγονότα.
**Βήματα:** (1) IR με `determinacy`· (2) συλλογισμός: καμία μηχανική απόφαση· (3)
απάντηση `UNKNOWN(interpretive)` με τις ερμηνευτικές εναλλακτικές ως typed
υποθέσεις (L5), με counterproof slot γεμάτο από `open_objections`· (4) LegalRuleML
εκπομπή **δεν** παράγεται για τη διάταξη.
**Αναμενόμενη έξοδος:** typed αποχή· καμία τιμή `IN/OUT`· η απάντηση περνά τον
verifier ως `UNKNOWN(undecided-legal-state)`.
**Αρνητικός μάρτυρας:** (α) `IN/OUT` για interpretive διάταξη ⇒ KW-50· (β)
εναλλακτικές ως ελεύθερο κείμενο ⇒ κοκκίνισμα (Q32)· (γ) LegalRuleML που εκπέμπεται
για τη διάταξη ⇒ κοκκίνισμα (Q38).
**Evidence bundle:** IR, answer object, verifier receipt, emitter log (καμία εκπομπή).
**Κριτήριο εξόδου:** `UNKNOWN(interpretive)` typed· 3/3 μάρτυρες.
**Βήμα υλοποίησης:** checkpoint 3 (IR)· **ολοκλήρωση στο 8**.
**Q / KW:** Q10, Q32, Q38 · KW-50.

### VS-08 — Νομολογιακή αλυσίδα followed / distinguished / overruled
**Αποστολή / επίπεδα:** MIS-4 · §4.9.
**Έδρες:** `legal-decisions.lisp`, `decisions.lisp`, `citation-authority.lisp`,
`version-graph.lisp` (line-of-authority), `jurisprudence-judge.lisp`, reviewer registry.
**Είσοδος (ορισμένη):** τρεις αποφάσεις του Αρείου Πάγου του ίδιου νομικού
ζητήματος, όπου η δεύτερη **ρητά** παραπέμπει και ακολουθεί την πρώτη, και η τρίτη
(Ολομέλεια) **ρητά** την ανατρέπει — επιλεγμένες από το census στο βήμα 9 με
κριτήριο την ύπαρξη explicit citations στο κείμενο· δύο κανάλια για τη μία (πρωτότυπο
+ ανωνυμοποιημένο).
**Βήματα:** (1) τρία `judgment-identity-and-text` claims με USC ids, ECLI ή
`provisional_id`, κατάσταση ανωνυμοποίησης· (2) τάξη 2: `rel1:` records από explicit
citations με passage anchors· `LATER-TREATMENT` γεγονότα `followed`, `overruled`· (3)
line-of-authority γράφος με `authority_weight` μετρημένο (plenary-over-chamber)· (4)
τάξη 3: ένα `jurisprudential-analysis` claim με `reviewer_adoption_act` από kid του
`reviewer_registry`· (5) τάξη 4: ratio candidates του runtime **εκτός** release.
**Αναμενόμενη έξοδος:** ένα `work_id` ανά απόφαση (δύο κανάλια ⇒ δύο expressions
με `derived_from_expression`)· γράφος με `overruled` ακμή· weight της Ολομέλειας >
τμήματος· ο verifier δίνει `VERIFIED` στα claims τάξης 1/2/3 και δεν βλέπει τάξη 4.
**Αρνητικός μάρτυρας:** (α) `later_treatment` χωρίς citation anchor ⇒ KW-55· (β)
ratio candidate χωρίς adoption σε claim ⇒ `unadopted-analysis` (KW-7, KW-36)· (γ)
δύο `work_id` για την ίδια απόφαση ⇒ KW-3· (δ) όνομα διαδίκου σε hash-φέρον
αντικείμενο ⇒ κοκκίνισμα (Q25).
**Evidence bundle:** claims, rel1 records, γράφος export, adoption act, receipts.
**Κριτήριο εξόδου:** 1 work/απόφαση· 4/4 μάρτυρες.
**Βήμα υλοποίησης:** **ολοκλήρωση στο 9**. **Ανοιχτό:** U-3.
**Q / KW:** Q07, Q08, Q25, Q37 · KW-3, KW-7, KW-36, KW-55.

### VS-09 — Δύο ανεξάρτητοι compilers, ίδια ρίζα
**Αποστολή / επίπεδα:** MIS-1, MIS-9 · §4.4, §4.6.
**Έδρες:** Lisp compiler (`consolidation-engine.lisp` + `version-graph.lisp` +
`legal-inference-engine.lisp`), Rust compiler B (MISSING → βήμα 5), `release-gate.lisp`,
MLTP v3 §6 `dual_compiler_attestation`, §8.3 R4.
**Είσοδος (ορισμένη):** το journal των VS-01 και VS-02 (ίδια κανονική είσοδος γεγονότων).
**Βήματα:** (1) compiler A ⇒ `legal_state_root_A`, `projection_roots_A`· (2)
compiler B ⇒ `_B`· (3) σύγκριση **πριν** την υπογραφή· (4) δύο `compiler-attestation`
με διακριτά delegated κλειδιά scope `compiler-attestation`· (5) release με release
key· (6) verifier R4.
**Αναμενόμενη έξοδος:** ρίζες ίσες· bundle `VERIFIED`· δύο attestations με
διαφορετικά `kid`.
**Αρνητικός μάρτυρας:** (α) release με μία attestation ⇒ KW-52· (β) δύο attestations
από το ίδιο kid ⇒ `delegation-scope-violation`· (γ) η συμφωνία ως admission predicate
(χωρίς proposer-blind M5) ⇒ κοκκίνισμα (Q11 β).
**Evidence bundle:** δύο ρίζες, attestations, bundle, receipt.
**Κριτήριο εξόδου:** ισότητα ριζών· 3/3 μάρτυρες.
**Βήμα υλοποίησης:** checkpoint 4 (compiler A)· **ολοκλήρωση στο 5**· verifier R4 στο 6.
**Q / KW:** Q11, Q33, Q34 · KW-52. **Ανοιχτό:** U-5.

### VS-10 — Απόκλιση compilers ⇒ quarantine
**Αποστολή / επίπεδα:** MIS-1, MIS-9 · §4.6.
**Έδρες:** όπως VS-09 + `release-gate.lisp` (QUARANTINED path).
**Είσοδος (ορισμένη):** το journal της VS-09 + **δηλωμένο** εγχυμένο σφάλμα σε έναν
compiler (λάθος όριο ημερομηνίας: `effective_from` συγκρίνεται με `<=` αντί `<`).
**Βήματα:** (1) compile A και B· (2) ρίζες διαφέρουν· (3) `QUARANTINED` αυτόματα·
(4) κανένα release· (5) bundle με τις δύο attestations παρουσιάζεται στον verifier.
**Αναμενόμενη έξοδος:** `compiler-divergence` (R4) ⇒ `UNVERIFIED_FOR_MACHINE_RELIANCE`
για ολόκληρο το bundle· κανένα «νικητής»· η καραντίνα journaled.
**Αρνητικός μάρτυρας:** (α) release που επιλέγει τη ρίζα του A ⇒ κοκκίνισμα· (β)
verifier που δέχεται bundle με άνισες ρίζες ⇒ κοκκίνισμα (R4)· (γ) καραντίνα που δεν
καταγράφεται στο L1 ⇒ κοκκίνισμα.
**Evidence bundle:** δύο ρίζες (διαφορετικές), quarantine record, receipt.
**Κριτήριο εξόδου:** 0 releases· `compiler-divergence` typed· 3/3 μάρτυρες.
**Βήμα υλοποίησης:** **ολοκλήρωση στο 5**· verifier στο 6.
**Q / KW:** Q34 · KW-52.

### VS-11 — Τοπική επαλήθευση provider (και stripped citation ⇒ `UNVERIFIED_FOR_ATTRIBUTED_RELIANCE`)
**Αποστολή / επίπεδα:** MIS-5, MIS-8 · §4.7, §4.10, §4.11, §4.15, §4.16.
**Έδρες:** `deployment/verify/verify.py`, `verify.mjs` (→ MLTP v3), Rust verifier
(δεύτερη υλοποίηση), `deployment/verify/vectors/`, `mcp-server.lisp`, OpenAPI, SDKs,
MLTP v3 §2.10, §8.3.
**Είσοδος (ορισμένη):** το `TrustBundle` της VS-01 + ο `CertifiedResult` της VS-01·
`LocalTrustState` με pinned root, registries, τελευταίο checkpoint, trusted-time
evidence· **και** τα conformance vectors: (i) stripped citation, (ii) altered
`official_source_uri`, (iii) ληγμένο QSR, (iv) `LocalTrustState` χωρίς trusted time,
(v) `CitationToken` επί άλλου `result_id`.
**Βήματα:** (1) verify offline (δίκτυο απενεργοποιημένο, μετρήσιμο)· (2) τρεις
υλοποιήσεις (Python, Node, Rust) ⇒ receipts· (3) vectors i–v· (4) SDK default rendering
της διπλής παραπομπής· (5) MCP εργαλείο επιστρέφει `CertifiedResult` με υποχρεωτικό
`citation`.
**Αναμενόμενη έξοδος:** θετικό: 3/3 `VERIFIED`, ταυτόσημα receipts· (i) ⇒
`citation-unbound` ⇒ `UNVERIFIED_FOR_ATTRIBUTED_RELIANCE`· (ii) ⇒ `citation-unbound`
(digest) ή `sig-invalid`· (iii) ⇒ `expired` ⇒ `UNKNOWN`· (iv) ⇒ `UNKNOWN_FRESHNESS`·
(v) ⇒ `sig-invalid`· bundle result = `min` κατά την ορισμένη διάταξη.
**Αρνητικός μάρτυρας:** (α) verifier που δίνει `VERIFIED` στο (i) ⇒ KW-62· (β)
rendering με μία μόνο παραπομπή ⇒ KW-63· (γ) δύο verifiers που διαφωνούν σε
οποιοδήποτε vector ⇒ Q21 ε· (δ) σχήμα με προαιρετικό `citation` ⇒ Q42 ζ.
**Evidence bundle:** vectors, 3 × 6 receipts, network-off proof (strace/log), SDK
render snapshot, digests.
**Κριτήριο εξόδου:** 18/18 receipts όπως αναμένεται και ταυτόσημα ανά vector· 4/4 μάρτυρες.
**Βήμα υλοποίησης:** checkpoint 6 (verifiers + vectors iii/iv)· **ολοκλήρωση στο 11**
(CertifiedResult, vectors i/ii/v, SDK, MCP).
**Q / KW:** Q14, Q21, Q22, Q27, Q35, Q38, Q42 · KW-2, KW-13, KW-25, KW-62, KW-63.

### VS-12 — Rotation, ληγμένη delegation, compromise, αναδρομική ανάκληση
**Αποστολή / επίπεδα:** MIS-9 · §4.10, §4.14.
**Έδρες:** MLTP v3 §2.9, §8.3 K0–K4, V, L1–L3, §9· `authority-v2/` (ceremony rehearsal,
witness-quorum test)· `jws-authority.lisp`, `timestamp-authority.lisp`.
**Είσοδος (ορισμένη):** ceremony rehearsal του `authority-v2/`: DelegationStatement
seq n (κλειδί K1, 90 ημέρες), seq n+1 (K2, rotation), RevocationStatement για K1 με
`reason: key-compromise`, `invalid_from` = 10 ημέρες πριν το `revoked_at`· claims
υπογεγραμμένα από K1 σε τρεις στιγμές: πριν το `invalid_from` (με TSR), μεταξύ
`invalid_from` και `revoked_at` (με TSR), μετά το `revoked_at`· ένα claim από K1 μετά
το `not_after`· δύο checkpoints όπου το δεύτερο έχει μικρότερο `tree_size`.
**Βήματα:** verify κάθε συνδυασμό με `LocalTrustState` που φέρει το τρέχον
revocation checkpoint.
**Αναμενόμενη έξοδος:** claim πριν `invalid_from` με TSR ⇒ `VERIFIED`· μεταξύ ⇒
`retroactively-revoked`· μετά `revoked_at` ⇒ `revoked`· μετά `not_after` ⇒
`delegation-expired`· K2 claims ⇒ `VERIFIED` μόνο με root-signed seq n+1·
rollback checkpoint ⇒ `split-view`.
**Αρνητικός μάρτυρας:** (α) continuity statement από K1 ως rotation ⇒ απόρριψη
(KW-41)· (β) ανάκληση ως IssuedClaim από K2 ⇒ απόρριψη K0 (KW-35)· (γ) verifier που
κρίνει ανάκληση έναντι `valid_time` ⇒ KW-14· (δ) checkpoint με μικρότερο tree_size
που περνά ⇒ KW-40· (ε) revocation checkpoint παλαιότερο του `max_revocation_staleness`
που δίνει `VERIFIED` ⇒ `stale-revocation-state`.
**Evidence bundle:** statements, claims, checkpoints, receipts ανά συνδυασμό.
**Κριτήριο εξόδου:** κάθε συνδυασμός δίνει το ορισμένο typed αποτέλεσμα (0 αποκλίσεις)·
5/5 μάρτυρες.
**Βήμα υλοποίησης:** **ολοκλήρωση στο 6**. **Ανοιχτό:** U-2 (witness registry).
**Q / KW:** Q17, Q23, Q26 · KW-6, KW-14, KW-16, KW-20, KW-21, KW-35, KW-40, KW-41.

### VS-13 — Ελλείπον αναμενόμενο ΦΕΚ/δικαστικό αντικείμενο ⇒ αποτυχία κάλυψης, όχι σιωπή
**Αποστολή / επίπεδα:** MIS-2 · §4.1.
**Έδρες:** `ingestion-daemon.lisp`, `legislation-ingestion.lisp`, coverage ledger,
`coverage-and-freshness` claim, census `RegistrySnapshot`.
**Είσοδος (ορισμένη):** το census space `gr/gazette/A` για το έτος 2025 (αριθμοί
τευχών ως συνεχής απαρίθμηση από τον root-signed snapshot)· **δηλωμένη μετάλλαξη**:
ένα τεύχος αφαιρείται από το κανάλι λήψης (mock του καναλιού, όχι του ledger).
**Βήματα:** (1) απαρίθμηση από το snapshot· (2) λήψη· (3) ledger ως ολική
συνάρτηση· (4) `coverage-and-freshness` claim· (5) provider ερώτημα που αγγίζει το
τεύχος· (6) δεύτερη ανεξάρτητη απαρίθμηση (Μ-4).
**Αναμενόμενη έξοδος:** η θέση του τεύχους = `UNKNOWN` με `gap_reason` και
`retry_state`, εντός `freshness_budget`· η απάντηση του provider φέρει
`coverage_state` που το δείχνει· καμία σιωπή· η δεύτερη απαρίθμηση συμφωνεί.
**Αρνητικός μάρτυρας:** (α) ledger παραγόμενο από τα ληφθέντα (η θέση απλώς
λείπει) ⇒ KW-48· (β) claim «κάλυψη 100%» χωρίς `universe_declaration_ref` ⇒
κοκκίνισμα (Q29 γ)· (γ) `UNKNOWN` χωρίς `gap_reason` ⇒ `schema-mismatch`.
**Evidence bundle:** snapshot, ledger, claim, provider answer, δεύτερη απαρίθμηση.
**Κριτήριο εξόδου:** θέση `UNKNOWN` εντός budget· 3/3 μάρτυρες.
**Βήμα υλοποίησης:** **ολοκλήρωση στο 1**· provider όψη (5) στο 11.
**Q / KW:** Q01, Q02, Q29 · KW-48. **Ανοιχτά:** U-1, U-7.

### VS-14 — Cockpit πρόταση αποτυγχάνει να παρακάμψει την M5
**Αποστολή / επίπεδα:** MIS-6, MIS-10 · §4.12, §1.4.
**Έδρες:** `cockpit.lisp` (`/api/decide`, `/api/publish` → REPLACE), `review-service.lisp`,
`review-queue.lisp`, `release-authority.lisp` (M5), `approval-policy.lisp`, RBAC/MFA
registry (MISSING → βήμα 12).
**Είσοδος (ορισμένη):** μια πρόταση διόρθωσης πηγής (η ήδη attested διόρθωση του
Π7-U.1 Φ1) υποβαλλόμενη από το cockpit ως `cockpit_intent kind=proposal`, μετά
`kind=approval` από actor με role `reviewer` και `mfa_evidence`.
**Βήματα:** (1) intent journaled στο L1· (2) ουρά M5· (3) proposer-blind
επαλήθευση· (4) release μόνο από M5· (5) **απόπειρες** παράκαμψης: κλήση του παλιού
`/api/publish` (πρέπει να μην υπάρχει ως release action), intent χωρίς
`mfa_evidence`, intent από kid εκτός registry, intent με πεδίο `weakest_link`.
**Αναμενόμενη έξοδος:** `RELEASED` μόνο μέσω M5· και οι τέσσερις απόπειρες
αποτυγχάνουν **δομικά** (δεν υπάρχει διαδρομή / δεν μεταγλωττίζεται / `untrusted-key`).
**Αρνητικός μάρτυρας:** (α) direct-publish bypass που επιτυγχάνει ⇒ κοκκίνισμα
(Q15 β)· (β) intent χωρίς MFA που γίνεται δεκτό ⇒ KW-57· (γ) matter-solving πεδίο που
μεταγλωττίζεται ⇒ KW-39· (δ) φίλτρο αντί δομής (η απόπειρα μεταγλωττίζεται και
απορρίπτεται σε runtime) ⇒ αποτυχία οικογένειας (Q20).
**Evidence bundle:** intents, journal, M5 receipt, τα τέσσερα attempt logs.
**Κριτήριο εξόδου:** 1 release μέσω M5· 4/4 απόπειρες δομικά αδύνατες.
**Βήμα υλοποίησης:** **ολοκλήρωση στο 12**.
**Q / KW:** Q11, Q15, Q17, Q20, Q39 · KW-38, KW-39, KW-57.

### VS-15 — Disaster recovery αναπαράγει το ίδιο qualified release
**Αποστολή / επίπεδα:** MIS-9 · §4.14.
**Έδρες:** PLANE-0 vault (`corpus-provenance.lisp`), `journal.lisp`, Dockerfile +
`deps.lock` + `docker/sbom.json`, `scripts/verify-runtime-closure.sh`, DR runbook
(MISSING → βήμα 13).
**Είσοδος (ορισμένη):** το release των VS-09/VS-11 (release_root R, QSR refs)· ψυχρό
περιβάλλον (νέο container από το hermetic image) με **μόνο** PLANE-0 bytes + journal.
**Βήματα:** (1) καταστροφή όλων των παραγώγων (PLANE-1, προβολές, bundles)· (2)
ανακατασκευή από PLANE-0 + journal με τους δύο compilers· (3) σύγκριση
`release_root` και όλων των digests του bundle· (4) επαλήθευση ότι τα υπάρχοντα QSR
(που δεσμεύουν το subject R) ακόμη επιλύονται· (5) μέτρηση RTO/RPO (αριθμοί: U-1)·
(6) δεύτερο σενάριο: καταστροφή μέρους του PLANE-0.
**Αναμενόμενη έξοδος:** byte-ταυτόσημο release (ίδιο R, ίδια digests)· QSR έγκυρα·
στο δεύτερο σενάριο δηλωμένη **απώλεια** με typed λίστα θέσεων ⇒ `UNKNOWN`, ποτέ
σιωπηλή αναπλήρωση.
**Αρνητικός μάρτυρας:** (α) ανακατασκευή με διαφορετικό R που παρουσιάζεται ως το
ίδιο release ⇒ κοκκίνισμα (Q12)· (β) απώλεια PLANE-0 που «γεμίζει» από cache ⇒
κοκκίνισμα (Q19)· (γ) build μη hermetic (διαφορετικό image digest σε δύο builds) ⇒
κοκκίνισμα (Q40).
**Evidence bundle:** image digests ×2, R ×2, bundle digests, QSR resolution log,
RTO/RPO μέτρηση, loss report.
**Κριτήριο εξόδου:** R ίσο· απώλεια typed· 3/3 μάρτυρες.
**Βήμα υλοποίησης:** προϋπόθεση βήμα 0 (hermetic build)· **ολοκλήρωση στο 13**.
**Q / KW:** Q12, Q19, Q40 · KW-59. **Ανοιχτό:** U-1.

---

## ΙΣΟΛΟΓΙΣΜΟΣ

15 φέτες· κάθε μία με ορισμένη είσοδο, βήματα, αναμενόμενη έξοδο, αρνητικό μάρτυρα
(3 έως 5 μεταλλάξεις), evidence bundle, δυαδικό κριτήριο εξόδου, βήμα ολοκλήρωσης.
Κάλυψη επιπέδων v1.4 §4: §4.1 (VS-13)· §4.2 (VS-01, VS-03, VS-04)· §4.3/§4.4 (VS-04,
VS-05, VS-06, VS-07, VS-09)· §4.5 (VS-01, VS-02)· §4.6 (VS-09, VS-10)· §4.7 (VS-01,
VS-11)· §4.8 (VS-02)· §4.9 (VS-08)· §4.10 (VS-11, VS-12)· §4.11 (VS-11)· §4.12 (VS-14)·
§4.13 (καμία φέτα — το citation observatory ελέγχεται από την Q16 ζωντανά, όχι από
φέτα, γιατί απαιτεί εξωτερική κίνηση που δεν ορίζεται ως fixture — δηλωμένο κενό, όχι
σιωπηλό)· §4.14 (VS-12, VS-15)· §4.15 (VS-11)· §4.16 (VS-01, VS-11).
**Καμία φέτα δεν έχει εκτελεστεί.**
