(:lawmax-phase1a-cluster/1
 :cluster "ΤΑ ΣΥΜΒΟΛΑΙΑ ΚΑΙ Η ΠΑΡΑΔΟΣΗ"
 :status :partial
 :files-read 5
 :universe 79
 :capabilities
 ((:name "GATE-4 / pipeline-integrity-no-subprocess"
   :presence :absent
   :domain "Δήλωση README ότι υπάρχει πύλη CI που επιβάλλει «no subprocess» στο pipeline."
   :assumptions "Ότι κάθε GATE-N του πίνακα README:300-305 αντιστοιχεί σε εκτελέσιμο guard."
   :guarantees "ΚΑΜΙΑ. Δεν βρέθηκε υλοποίηση."
   :failure-semantics "Δεν υπάρχει μηχανισμός να αποτύχει· η δήλωση δεν μπορεί να γίνει κόκκινη."
   :operating-model "Μόνο κείμενο πίνακα."
   :materiality "Η ΑΠΟΛΥΤΗ δήλωση README.md:20-21 «The only subprocess is the Lisp runtime itself» δεν φρουρείται από τίποτα."
   :evidence "README.md:304")
  (:name "Πραγματικά subprocess seats (αντίθετα στη δήλωση)"
   :presence :present
   :domain "Εκκίνηση εξωτερικών διεργασιών από τον κώδικα."
   :assumptions "uiop:run-program διαθέσιμο· εξωτερικά binaries στο PATH."
   :guarantees "Καμία απομόνωση· document-fetch περνά ΑΥΘΑΙΡΕΤΟ string σε /bin/sh -c."
   :failure-semantics "pdf-authority: σιωπηλό NIL σε error (:1424)· ocr-available-p επιστρέφει NIL. document-fetch: (values -1 msg), never throws (:106)."
   :operating-model "Runtime, εντός εικόνας."
   :materiality "6 call sites run-program σε 2 αρχεία· ΚΑΝΕΝΑ δεν καλύπτεται από πύλη."
   :evidence "source/document-fetch.lisp:92-106 source/pdf-authority.lisp:1386-1425"))
 :authorities ()
 :invariants
 ((:statement "The only subprocess is the Lisp runtime itself"
   :enforced-by :none
   :evidence "README.md:20-21")
  (:statement "Zero shell-script orchestration in the trusted path"
   :enforced-by :none
   :evidence "README.md:19"))
 :defects
 ((:what "GATE-4 «Pipeline integrity (no subprocess)» δηλώνεται στον πίνακα πυλών αλλά ΔΕΝ ΥΠΑΡΧΕΙ πουθενά ως κώδικας: το string GATE-4 με αυτή τη σημασία εμφανίζεται ΜΟΝΟ στο README.md:304 σε ολόκληρο το repo."
   :severity :p1
   :evidence "README.md:304"
   :is-it-in-the-known-defect-list :no)
  (:what "README.md:253 δηλώνει αρχείο source/gate-guards.lisp («CI/CD guards (Pure Lisp)») που ΔΕΝ ΥΠΑΡΧΕΙ στο source/."
   :severity :p1
   :evidence "README.md:253"
   :is-it-in-the-known-defect-list :no))
 :hidden-execution-paths
 ((:path "/bin/sh -c <command> από run-fetch-command"
   :trigger "network-edge fetch"
   :why-hidden "Το README δηλώνει «Zero shell-script orchestration in the trusted path»· εδώ εκτελείται ΚΕΛΥΦΟΣ με string interpolation."
   :evidence "source/document-fetch.lisp:92-106"))
 :duplicate-seats ()
 :unknowns ("Dockerfile" ".asd x17" "docker-compose*.yml" ".github/workflows" "deps.lock" "entrypoint.lisp" "configs/" "docs/" "cloudflare/" "tools/")
 :remaining ("ΟΛΑ πλην README.md, source/document-fetch.lisp, source/pdf-authority.lisp, systems/orchestrator-cli/architecture-gate.lisp"))
