;;;; experiment/PROTOCOL-EPOCH-3.sexp
;;;; ΤΡΙΤΗ ΕΠΟΧΗ — ΥΠΕΡΚΕΡΑΣΗ, ΟΧΙ ΑΛΛΟΙΩΣΗ
;;;; Το PROTOCOL-EPOCH-2 ΔΕΝ τροποποιήθηκε.

(:lawmax-protocol/3
 :epoch 3
 :supersedes "experiment/PROTOCOL-EPOCH-2.sexp"
 :supersedes-sha256 "aacd64895d8e7e5312ab55a5e51cc1727274c348a56f542e909d02f7a86e9814"
 :supersession-reason
  "Η δεύτερη εποχή δήλωνε schema 3 και σαρωτή με ΣΤΑΤΙΚΗ λίστα επεκτάσεων.
   Η λίστα αγνοούσε σιωπηλά πραγματικές διαδρομές του manifest. Επίσης η
   ταυτότητα ήταν leaf-root χωρίς schema/commit/tree στο preimage, και το
   κενό text αρχείο δηλωνόταν trailing_newline=1."

 :frozen-commit "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
 :frozen-tree-sha1 "23b7a6f4450f50d151d38e13020bee9872e73bcd"
 :git-leaves 35640
 :manifest-schema 4
 :corpus-identity "sha256:99602490aedba5f942413ec2454d189a5ccbc503deb64efdd146f9640e0f03a6"
 :identity-preimage "SHA256(domain ‖ u32be(schema) ‖ commit(20) ‖ tree(20) ‖ leaf-root(32))"

 :recognition
 (:kind :MANIFEST-DRIVEN
  :extension-whitelist :REMOVED
  :rule "Υποψήφια διαδρομή είναι ό,τι στέκεται αριστερά της άνω τελείας·
         η ΕΠΙΛΥΣΗ γίνεται με ΑΚΡΙΒΗ αντιστοίχιση στο manifest."
  :covers ("extensionless" "dotfiles" "σύνθετα επιθήματα" "executable leaves"))

 :citation-format "path:L<start>-L<end>@sha256:<12 πεζά δεκαεξαδικά>"
 :terminal-boundary
  "«/», «%», «?», «#», «=» ΔΕΝ τερματίζουν. Κάθε μη επιτρεπτό byte ακυρώνει
   ΟΛΟΚΛΗΡΟ το token. ΚΑΜΙΑ αποδοχή έγκυρου προθέματος."
 :comma-lists :FORBIDDEN

 :access
 (:mechanism "openat2 · RESOLVE_BENEATH|RESOLVE_NO_SYMLINKS|RESOLVE_NO_XDEV|RESOLVE_NO_MAGICLINKS"
  :weaker-fallback :NONE
  :enosys-or-unenforced-flags :BLOCKED
  :blocked-never-passes t
  :enforcement-probe "δύο ανοίγματα που ΠΡΕΠΕΙ να αποτύχουν, σε ΚΑΘΕ πύλη")

 :isolation
 (:mount-namespace "ΙΔΙΩΤΙΚΟ· αλλαγή inode ΑΠΟΔΕΔΕΙΓΜΕΝΗ, ΟΧΙ environment marker"
  :lock "ίδιο fd· κατοχή αποδεδειγμένη λειτουργικά"
  :snapshot "tmpfs από git objects, απρόσιτο εκτός namespace"
  :clean-worktree-required t)

 :counted-units
 ((:unit :unique-citation-keys :meaning "διακριτά (path, spec, tail) ανά dossier")
  (:unit :textual-occurrences :meaning "εγγραφές διαγνωστικού")
  (:unit :comma-expanded-anchors :count 437 :in-tokens 290
   :note "ΜΗΧΑΝΙΚΑ ΕΠΑΛΗΘΕΥΜΕΝΟ με τη γραμματική που κρίνει. Το προηγούμενο
          «506» είχε παραχθεί με ευρετικό regex εκτός πύλης και ανακλήθηκε.")
  (:unit :revision-transitions :meaning "αμετάβλητοι χάρτες ανά μετάβαση"))

 :residual-taxonomy
 ((:class :SYNTAX-ONLY :count 0)
  (:class :AMBIGUOUS-PATH :count 21 :breakdown (:Φ1A-L1 11 :Φ1A-L7 10))
  (:class :INVALID-RANGE :count 1 :breakdown (:Φ1A-L1 1))
  (:class :SEMANTIC-DECISION :count 5 :breakdown (:Φ1A-L4 5))
  (:class :ENTAILMENT-FAILURE :count :NOT-DETERMINABLE-BY-THIS-GATE))
 :residual-total 27

 :gate-verdict :RECOGNIZED-CITATION-INTEGRITY
 :separately-open (:CLAIM-CITATION-COVERAGE :CLAIM-ENTAILMENT :READ-LEDGER :MACRO-LAYER)
 :forbidden-phrasing "«citation gates passed» με την ευρύτερη έννοια"

 :permitted-final-claims
 ((:claim :PROVED-GLOBAL-MAXIMAL-WITHIN-SEALED-D_TODAY
   :requires ("πιστοποιημένη πληρότητα αναζήτησης"
              "μηχανικά ελέγξιμο maximality certificate"
              "ολοκληρωμένο Pareto frontier"
              "μοναδικός νικητής ΜΟΝΟ μέσω σφραγισμένης λεξικογραφικής διάταξης"))
  (:claim :CEILING-PROOF-BLOCKED
   :requires ("ΑΚΡΙΒΕΣ, ΕΛΑΧΙΣΤΟ, ΟΝΟΜΑΣΤΙΚΟ σύνολο μη αποδειχθεισών υποχρεώσεων")))
 :open-world-note
  "Το OPEN-WORLD-ABSOLUTE-NOT-DECIDABLE ΔΕΝ είναι άδεια απλούστευσης. Είναι
   ΜΟΝΟ ακριβές όριο της ΕΞΩΤΕΡΙΚΗΣ αξίωσης. ΕΝΤΟΣ του σφραγισμένου πεδίου
   απαιτείται ΠΛΗΡΗΣ ΕΞΑΝΤΛΗΣΗ."

 :progress-measurement
 (:catalogue "experiment/OBLIGATIONS.json" :sealed t
  :tool "experiment/runner/progress.py"
  :receipt "experiment/artifacts/PROGRESS-RECEIPT.json"
  :rule "ΜΟΝΟ VERIFIED συνεισφέρει· καμία λεκτική εκτίμηση")

 :instrument-freeze
  "Ο evaluator είναι ΑΝΑΛΩΣΙΜΟ ΑΠΟΔΕΙΚΤΙΚΟ ΟΡΓΑΝΟ αυτής της μελέτης, ΟΧΙ
   προϊόν προς ατέρμονη τελειοποίηση. Μετά από αυτή την εποχή ΠΑΓΩΝΕΙ:
   καμία επανασχεδίαση χωρίς αποτυχία ΣΥΓΚΕΚΡΙΜΕΝΟΥ ήδη δηλωμένου
   acceptance predicate.")
