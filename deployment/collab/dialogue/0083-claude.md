# [0083] AS-BUILT αρχιτεκτονικός έλεγχος — το διάγραμμα-στόχος vs ο πραγματικός κώδικας

**Αφορμή:** ο δημιουργός έδειξε διάγραμμα ροής (SELF/GOVERNANCE → INGESTION→CORPUS→PCL,
NARRATIVE→MORPHOLOGY→CASEGRAMMAR→FACTS→{WFS/JTMS, TEMPORAL/GRAPH}→DEONTIC→SUBSUMPTION→
{DIALECTIC, COUNTERFACTUAL, ANALOGY, STRATEGY}→DRAFT→CAPABILITY-API→{CLI,MCP,COCKPIT,HTTP})
και ρώτησε «το σύστημα έτσι είναι ή όχι;». Απάντηση με ΑΠΟΔΕΙΞΗ: 8 ανεξάρτητοι επιθεωρητές,
ένας ανά περιοχή, διάβασαν τον πραγματικό κώδικα (131 αναγνώσεις, evidence file:line)·
4/4 δειγματοληπτικές επανεπαληθεύσεις από δεύτερο μυαλό (Fable) — όλα στέκουν.

## Ετυμηγορία: το διάγραμμα είναι ο ΣΤΟΧΟΣ (CPEI/Ω∞), όχι η τρέχουσα ροή.
Σχεδόν κάθε κουτί ΥΠΑΡΧΕΙ ως κώδικας (μόνο ANALOGY απούσα ως μηχανή)· τα ΒΕΛΗ όμως
υπερδηλώνονται σε 5/8 περιοχές. Ανά περιοχή:

| Περιοχή | Κρίση | Κλειδί-εύρημα |
|---|---|---|
| INGESTION→CORPUS→PCL | ✅ REAL end-to-end | 2040/1102/595 proofs· ΑΛΛΑ output ΑΝΥΠΟΓΡΑΦΟ, stale `raw-concat`, frozen anchored_at· gr-syntagma=μόνο Σύνταγμα (κώδικες=Isokratis parser) |
| FACTS→WFS/JTMS→DEONTIC→SUBSUMPTION | ✅ REAL — το πετράδι | Γνήσιο well-founded (Van Gelder fixpoint, τρίτιμο, NAF)· υπαγωγή=δεοντικός κύκλος· ρηχό μόνο σε ΔΕΔΟΜΕΝΑ (4 νόρμες) |
| NARRATIVE→MORPH→CASEGRAMMAR→FACTS | ⚠️ άκρα REAL, μέσο ΟΧΙ | Η γραμματική ΔΕΝ διαβάζει μορφολογία-χαρακτηριστικών· ρόλος από *article-table*· morph τροφοδοτεί ΜΟΝΟ 2 concepts (μέσω morph-lemma)· bootstrap: 40 ρήματα/6 classes/2 concepts |
| SELF «ελέγχει όλα» | ⚠️ MISLABELED | Governance πραγματικό ΜΟΝΟ στο μονοπάτι αυτο-τροποποίησης (can-adopt μπλοκάρει adopt-knowledge, decisions.lisp:1352)· add-article/cut-release/fetch: 0 κλήσεις· --gates=παράλληλος on-demand επικυρωτής· «proposals» = ΔΥΟ ασύνδετα μητρώα (orchestrator.proposals.sexp vs whatif in-memory, adoption διαβάζει μόνο το 2ο)· trace/adoption-records session-only (δηλωμένο χρέος) |
| FACTS→TEMPORAL/GRAPH→SUBSUMPTION | ❌ ΑΝΑΚΡΙΒΕΣ | temporal/graph/event-calculus = γνήσια αλλά ΑΠΟΜΟΝΩΜΕΝΑ ΝΗΣΙΑ: in-force-facts/point-in-time/pagerank/ec-holds → 0 εξωτερικοί καλούντες (επανεπαληθευμένο: οι 7 grep-ταιριάσεις = σχόλια)· ζωντανό μόνο FACTS→SUBSUMPTION άμεσο |
| SUBSUMPTION→4 μηχανές | ⚠️ 2/4 | DIALECTIC+COUNTERFACTUAL τρέφονται REAL από subsume/conclusion-status· STRATEGY=γνήσιο STRIPS BFS αλλά ΑΥΤΟΝΟΜΟ· ANALOGY=ΔΕΝ υπάρχει (σχόλιο στο cognition.lisp) |
| DIALECTIC→DRAFT/ADVICE/ACTION | ⚠️ λάθος τοπολογία | draft-commands: 0 αναφορές σε dialectic (επανεπαληθευμένο)· πραγματικός άξονας = ΥΠΑΓΩΓΗ/JTMS fixpoint με DIALECTIC/DRAFT/CF/STRATEGY αδέλφια-αναγνώστες· ADVICE=διπλωμένο στο DRAFT (§VI-VIII)· ACTION μόνο στο --strategy, ΛΕΙΠΕΙ από το Σημείωμα |
| CAPABILITY-API→4 κανάλια | ❌ ~25% | ΤΡΕΙΣ ασύνδετες έδρες: *capabilities* (4 caps, μόνο cockpit), MCP *tools* (4 ΑΛΛΑ tools, δικό του dispatch — επανεπαληθευμένο), CLI register-command (απευθείας)· μόνο COCKPIT(=HTTP) γνήσια προβολή· cockpit.lisp:9 το ομολογεί («μελλοντικά MCP+CLI») |

## Η as-built εικόνα (μία γραμμή)
INGESTION→CORPUS→PCL (αληθινό) ‖ NARRATIVE→CASEGRAMMAR→FACTS→JTMS/WFS→SUBSUMPTION
(ο κόμβος-fixpoint) με DIALECTIC/COUNTERFACTUAL/DRAFT/STRATEGY ως αδέλφια-αναγνώστες·
TEMPORAL/GRAPH/EC = νησιά· Capability-API→μόνο COCKPIT.

## Κλάση σφάλματος: docstring-ψέματα (ίδια με το «ανώτερο παντού» του [0082])
≥3 τεκμηριωμένα σημεία όπου ΤΟ ΣΧΟΛΙΟ υπόσχεται ό,τι Ο ΚΩΔΙΚΑΣ δεν κάνει:
(α) capability-registry.lisp:11 «HTTP/MCP/CLI είναι ΠΡΟΒΟΛΕΣ» — ψευδές για MCP+CLI·
(β) casegrammar *concepts* docstring «μέσω morph-analyze» — ο κώδικας χρησιμοποιεί
morph-lemma, η πτώση ΔΕΝ ρέει από τη μορφολογία· (γ) PCL output με stale algorithm-string.
Ίδια αρχή θεραπείας: η δήλωση ΔΕΝ ξεπερνά την πραγματικότητα — ή διορθώνεται το σχόλιο
ή καλωδιώνεται ο κώδικας. ΚΑΜΙΑ αλλαγή χωρίς ρητή έγκριση εύρους.

## Ονοματολογία ανώτατου σχεδίου (απαντήθηκε στον δημιουργό, από τις έδρες-spec)
Target: **CPEI — Constitutional Proof-Carrying Epistemic Institution** (LAWMAX Ω,
CPEI-TARGET-SPEC)· τελική μορφή: **LAWMAX Ω∞ — Adversarially-Closed Verified Legal
Authority**. Η διάκριση ΠΑΡΟΝ/TARGET του spec είναι ακριβώς αυτό το πρακτικό.

## Εκκρεμείς αποφάσεις δημιουργού (κανένα δεν ξεκινά χωρίς «εγκρίνω»)
Δ1. Κλείσιμο docstring-ψεμάτων (μικρή φάση honesty — σχόλια→αλήθεια, 0 συμπεριφορά).
Δ2. Καλωδίωση ενός νησιού (π.χ. temporal→subsumption: χρονική ισχύ νόρμας στην υπαγωγή).
Δ3. Ενοποίηση capability: MCP+CLI ως προβολές της ΜΙΑΣ έδρας (ο στόχος του ίδιου του κώδικα).
Δ4. proposals→adoption: ένωση των δύο μητρώων σε ΜΙΑ έδρα.
Δ5. As-built vs target διπλό διάγραμμα ως μόνιμο κείμενο.
Επίσης ανοιχτά: Task#34 (ΑΚ/ΚΠολΔ Ν.5221/2025+Ν.5303/2026)· υπόλοιπα γείωσης #15/#16/#29
(PP/VP/NP attachment)· docker-120 constitution (περιβαλλοντικό, owner-side)· ανυπόγραφο
PCL output (αναγέννηση με τρέχουσα έδρα).
