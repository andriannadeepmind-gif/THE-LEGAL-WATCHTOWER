;;;; experiment/phase1a/CHARGES-PHASE-1A.sexp
;;;; ΟΙ ΤΡΕΙΣ ΕΝΤΟΛΕΣ — ΣΚΛΗΡΥΜΕΝΕΣ, ΜΗ ΕΚΚΙΝΗΜΕΝΕΣ
;;;;
;;;; Κάθε εντολή δεσμεύεται σε ΑΚΡΙΒΗ tokens, ΑΚΡΙΒΗ byte offsets και ΑΚΡΙΒΗ
;;;; claim blocks. Δεν περιγράφει «περιοχή ενδιαφέροντος» — ορίζει ΣΥΝΟΛΟ.

(:lawmax-phase1a-charges/1
 :status :PREPARED-NOT-DISPATCHED
 :targets "experiment/artifacts/CHARGE-TARGETS.json"
 :targets-sha256 "6b7082fd1628a9ed5ccf3c1ee2906b2f6fdba28fc51a1a397af5082056436035"
 :gate "experiment/runner/citation-resolver.py"

 ;; ── ΤΙ ΕΠΙΤΡΕΠΕΤΑΙ ΚΑΙ ΤΙ ΟΧΙ — ΚΟΙΝΟ ΓΙΑ ΚΑΙ ΤΙΣ ΤΡΕΙΣ ──────────────
 :permitted-change-regions
  "ΑΠΟΚΛΕΙΣΤΙΚΑ τα claim blocks που απαριθμούνται στο CHARGE-TARGETS.json
   με τα byte spans τους. Καμία μεταβολή εκτός αυτών των spans."
 :permitted-actions
 ((:action :correct-citation
   :when "η πραγματική πηγή ταυτοποιείται ΚΑΙ στηρίζει τον ισχυρισμό"
   :form "κανονική: path:L<start>-L<end>@sha256:<12>")
  (:action :downgrade-claim
   :when "η πηγή στηρίζει ΜΕΡΟΣ του ισχυρισμού"
   :requires "ρητή δήλωση ΤΙ αφαιρέθηκε και ΓΙΑΤΙ")
  (:action :retract-claim
   :when "η πηγή ΔΕΝ στηρίζει τον ισχυρισμό"
   :requires "ο ισχυρισμός ΑΝΑΚΑΛΕΙΤΑΙ ρητά — ΠΟΤΕ σιωπηλή διαγραφή")
  (:action :anchor-lost
   :when "καμία πηγή δεν ταυτοποιείται"
   :form ":anchor-lost t με ονομαστική εξήγηση"))
 :mandatory-when-unsupported
  "Αν το ΠΡΑΓΜΑΤΙΚΟ span ΔΕΝ στηρίζει τον ισχυρισμό, η υποβάθμιση, ανάκληση ή
   σήμανση :anchor-lost είναι ΥΠΟΧΡΕΩΤΙΚΗ. ΑΠΑΓΟΡΕΥΕΤΑΙ η διατήρηση
   αστήρικτου ισχυρισμού με διορθωμένη παραπομπή."
 :forbidden
 ("επανάγνωση ολόκληρης της συστάδας"
  "οποιαδήποτε νέα αρχαιολογία"
  "μεταβολή claim block εκτός του δηλωμένου συνόλου"
  "μεταβολή οποιασδήποτε ήδη λυμένης παραπομπής"
  "πρόσβαση σε dossier άλλης διαδρομής")
 :permitted-sources
  "ΜΟΝΟ το παγωμένο snapshot μέσω της πύλης. Καμία ανάγνωση εκτός αυτού,
   κανένα δίκτυο, κανένα άλλο αρχείο του repo."
 :deliverable
  "νέα revision με :supersedes-sha256, exact citation diff, exact claim-status
   diff, read ledger ΜΟΝΟ για τους υποψηφίους των επηρεαζόμενων tokens, και
   απόδειξη ότι ΚΑΝΕΝΑ άλλο claim block δεν άλλαξε (αναλλοίωτο σκελετού +
   αντιστοιχία στόχων)."

 ;; ── ΟΙ ΤΡΕΙΣ ───────────────────────────────────────────────────────
 :charges
 ((:lane "Φ1A-L1" :dossier "experiment/phase1a/source-rev3.sexp"
   :tokens 12 :claim-blocks 3
   :classes (:AMBIGUOUS-PATH 11 :INVALID-RANGE 1)
   :question-ambiguous
    "Για καθένα από τα 11 γυμνά ονόματα (config.lisp ×4 · memory.lisp ×4 ·
     protocols.lisp ×3): ΠΟΙΟ αρχείο διαβάστηκε ΠΡΑΓΜΑΤΙΚΑ όταν γράφτηκε ο
     ισχυρισμός; Το καθένα έχει ΠΟΛΛΑΠΛΟΥΣ υποψηφίους (source/ · systems/ ·
     third-party/). Η επιλογή γίνεται ΑΠΟ ΤΟ ΠΕΡΙΕΧΟΜΕΝΟ που θεμελιώνει τον
     ισχυρισμό — ΠΟΤΕ από basename ή από εμβέλεια συστάδας."
   :question-invalid-range
    "capability-registry.lisp:40-207 σε αρχείο 206 γραμμών. ΜΗΝ το αλλάξεις
     μηχανικά σε 40-206: μόνο αν το ΠΡΑΓΜΑΤΙΚΟ περιεχόμενο έως τη 206
     στηρίζει ΟΛΟΚΛΗΡΟ τον ισχυρισμό. Αλλιώς στένεψε το εύρος ή δήλωσε
     :anchor-lost.")
  (:lane "Φ1A-L4" :dossier "experiment/phase1a/deployment-specs-rev3.sexp"
   :tokens 5 :claim-blocks 3
   :classes (:SEMANTIC-DECISION 5)
   :question
    "«L1-8+» σε αρχείο 127 γραμμών και «L79+» σε αρχείο 351 γραμμών. Το «+»
     σημαίνει «και εξής» — ΑΦΡΑΓΜΑΤΟ. ΠΟΙΟ είναι το ΠΡΑΓΜΑΤΙΚΟ τέλος του
     εύρους που θεμελιώνει τον ισχυρισμό; Αν ο ισχυρισμός απαιτεί ΟΛΟ το
     αρχείο, γράψε ΟΛΟ το αρχείο. Αν δεν προσδιορίζεται, :anchor-lost."
   :note "3 από τα 5 tokens (L9-37 · L40-76 · L28-29) είναι ΕΓΚΥΡΑ αλλά
          συνυπάρχουν στο ΙΔΙΟ token με το «L79+»· λύνονται μαζί του.")
  (:lane "Φ1A-L7" :dossier "experiment/phase1a/contracts-rev3.sexp"
   :tokens 10 :claim-blocks 6
   :classes (:AMBIGUOUS-PATH 10)
   :question
    "Δέκα «README:NNN». ΜΗΧΑΝΙΚΑ ΕΠΑΛΗΘΕΥΜΕΝΟ: ΔΕΝ υπάρχει «README» στη ρίζα
     του corpus. Υπάρχει «README.md» (389 γραμμές) και 47 «third-party/*/README».
     Η αντιστοίχιση σε README.md είναι ΠΙΘΑΝΗ αλλά ΟΧΙ μηχανική: επιβεβαίωσε
     ότι το ΠΕΡΙΕΧΟΜΕΝΟ κάθε εύρους θεμελιώνει τον αντίστοιχο ισχυρισμό."))

 :after-completion
 ("επαναπύλωση ΜΟΝΟ των τριών — οι L2/L3/L5/L6 ΔΕΝ ξανατρέχουν"
  "μετά: claim coverage · claim entailment · read ledger · macro layer"
  "μετά: σφράγιση Φ1A"
  "μετά: Φ2 ΧΩΡΙΣ επανασχεδίαση evaluator, εκτός αν αποτύχει ΣΥΓΚΕΚΡΙΜΕΝΟ
   ήδη δηλωμένο acceptance predicate"))
