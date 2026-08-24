;;;; experiment/phase1a/PARTIAL-FINDINGS.sexp
;;;; ΦΑΣΗ 1A — ΜΕΡΙΚΑ ΕΥΡΗΜΑΤΑ ΑΠΟ ΤΟ ΜΗΧΑΝΙΚΟ ΣΤΡΩΜΑ
;;;;
;;;; ΤΙΜΙΟ ΕΥΡΟΣ: αυτό ΔΕΝ είναι η Φάση 1A. Είναι ΜΟΝΟ η ΠΡΟΣΘΕΤΗ κεντρική
;;;; μηχανική διαδρομή (Φ1A-C0). Οι επτά ανεξάρτητες διαδρομές Φ1A-L1..L7 είναι
;;;; ΥΠΟΧΡΕΩΤΙΚΕΣ και τρέχουν χωριστά — βλ. LANE-REGISTRY.sexp. Η Φάση 1A ΔΕΝ
;;;; σφραγίζεται χωρίς τα επτά dossiers τους, με χωριστά hashes και χωρίς
;;;; μεταξύ τους πρόσβαση. Η σημασιολογική ανάγνωση ΕΚΚΡΕΜΕΙ σε εκείνες.

(:lawmax-phase1a-partial/1
 :status :PARTIAL
 :layer :mechanical-only
 :corpus "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
 :read-from "/frozen/ro (OS-level read-only· πύλη πριν από κάθε σάρωση)"
 :files-scanned 552
 :scan-scope-honest
  "552 αρχεία ΜΟΝΟ με κατάληξη .lisp/.asd/.sh/.py/.js, εκτός third-party/ και
   εκτός data roots. ΔΕΝ είναι ανάγνωση των 35.634 αρχείων του corpus· ΔΕΝ είναι
   ανάγνωση των 1.365 first-party· ΔΕΝ είναι σημασιολογική ανάγνωση κανενός
   αρχείου. Είναι απογραφή ΣΥΓΚΕΚΡΙΜΕΝΗΣ ΕΠΙΦΑΝΕΙΑΣ με regex."
 :lane-status "ΠΡΟΣΘΕΤΗ κεντρική διαδρομή (Φ1A-C0). ΔΕΝ αντικαθιστά καμία από τις
               επτά ανεξάρτητες — βλ. experiment/phase1a/LANE-REGISTRY.sexp"
 :packages-defined 183

 ;; ── ΕΥΡΗΜΑ 1A-01 ─────────────────────────────────────────────────────────
 (:id "1A-01"
  :severity :p1-PROVISIONAL
  :status :MEASURED-NOT-YET-PROVEN
  :upgrade-condition "Γίνεται εύρημα ΜΟΝΟ αφού αποδειχθούν ρόλος, authority,
                      inputs, outputs και failure semantics. Ανατέθηκε στις
                      ανεξάρτητες διαδρομές Φ1A-L1 (source), Φ1A-L2 (καλών) και
                      Φ1A-L7 (GATE-4). Η κεντρική διαδρομή ΔΕΝ το κρίνει μόνη."
  :class :claim-precision-drift
  :claim "README.md:20 — «The only subprocess is the Lisp runtime itself»
          (απόλυτη διατύπωση, χωρίς επιφύλαξη)"
  :reality "source/pdf-authority.lisp:1409 εκκινεί `pdftoppm` και
            source/pdf-authority.lisp:1419 εκκινεί `tesseract` — εξωτερικά
            εκτελέσιμα, ΜΕΣΑ στο source/, μέσω uiop:run-program."
  :evidence ("README.md:20" "README.md:304"
             "source/pdf-authority.lisp:1409" "source/pdf-authority.lisp:1419")
  :correction-to-earlier-count
   "ΔΕΝ είναι δύο θέσεις αλλά ΠΕΝΤΕ: το ίδιο το ocr-available-p εκκινεί
    `which pdftoppm`, `which tesseract` και `tesseract --list-langs`
    (source/pdf-authority.lisp περί τις 1386-1396) πριν καν φτάσει στο OCR."
  :callers-measured ("source/pdf-authority.lisp:1435 — εσωτερικός καλών"
                     "systems/orchestrator-cli/decisions.lisp:181 — καλεί ocr-available-p")
  :exported-surface ("#:ocr-available-p — source/pdf-authority.lisp:77"
                     "#:extract-text-via-ocr — source/pdf-authority.lisp:78")
  :mitigating-facts
   ("Η διαδρομή είναι ΥΠΟ ΣΥΝΘΗΚΗ: (unless (ocr-available-p) (return-from … nil))
     — source/pdf-authority.lisp:1403."
    "Επιστρέφει NIL σε αποτυχία και το docstring λέει ρητά «ο καλών αποφασίζει
     ΤΙΜΙΑ τι δηλώνει» — σχεδιασμένη τίμια άγνοια, ΟΧΙ σιωπηλό ψέμα."
    "Ο κατάλογος /tmp καθαρίζεται σε unwind-protect.")
  :aggravating-facts
   ("README.md:304 δηλώνει «GATE-4 Pipeline integrity (no subprocess)» —
     εκκρεμεί να ελεγχθεί αν η πύλη καλύπτει το pdf-authority.")
  :verdict "Ο ισχυρισμός του README είναι ΑΠΟΛΥΤΟΣ ενώ ο κώδικας είναι ΥΠΟ ΣΥΝΘΗΚΗ.
            Δεν είναι κρυφή κερκόπορτα· είναι ΑΝΑΚΡΙΒΕΙΑ ΔΗΜΟΣΙΟΥ ΙΣΧΥΡΙΣΜΟΥ.
            Σε σύστημα που πουλάει μη-διαψευσιμότητα, αυτό μετράει."
  :disposition :defect-obligation)

 ;; ── ΕΥΡΗΜΑ 1A-02 ─────────────────────────────────────────────────────────
 (:id "1A-02"
  :severity :informational
  :class :second-measurement-same-author
  :RETRACTION "Το χαρακτήρισα «ανεξάρτητο μαντείο». ΥΠΕΡΔΗΛΩΣΗ — ανακαλείται.
               Είναι ΔΕΥΤΕΡΗ ΜΕΤΡΗΣΗ ΤΟΥ ΙΔΙΟΥ ΣΥΓΓΡΑΦΕΑ και μπορεί να μοιράζεται
               τις ίδιες παραδοχές (τι είναι first-party, τι os-exec, τι εξαιρείται)."
  :finding "Το corpus διαθέτει ΗΔΗ ΔΙΚΟ ΤΟΥ ντετερμινιστικό census αυτής ακριβώς
            της κλάσης: deployment/verify/census-execution-constructs.sh
            ([0094] «trusted/untrusted plane separation»). ΔΕΝ είναι ανεξάρτητο
            από το corpus — είναι ΜΕΡΟΣ του."
  :executed-today t
  :its-own-counts ((:sexp-readers 37) (:eval 12) (:load/compile 31)
                   (:reader-macro 14) (:with-std-io 8) (:os-exec 20)
                   (:dyn-resolve 492) (:read-eval-binds 62)
                   (:third-party-count-only 326))
  :cross-check "ΔΥΟ ΜΕΤΡΗΣΕΙΣ ΣΥΜΦΩΝΟΥΝ ότι η κλάση os-exec δεν είναι κενή στον
                first-party κώδικα (δικό τους census: os-exec 20· δική μου σάρωση:
                ίδιες έδρες σε pdf-authority και entrypoint). Η συμφωνία ΕΝΙΣΧΥΕΙ,
                ΔΕΝ ΑΠΟΔΕΙΚΝΥΕΙ: κοινός συγγραφέας, πιθανώς κοινές παραδοχές.
                Ανεξάρτητη θα ήταν μέτρηση από άλλη οικογένεια εργαλείων ΚΑΙ άλλον
                ορισμό, γραμμένη χωρίς πρόσβαση στην πρώτη."
  :value "Το σύστημα ΞΕΡΕΙ και ΕΛΕΓΧΕΙ αυτή την κλάση. Το κενό είναι στη
          ΔΙΑΤΥΠΩΣΗ του δημόσιου ισχυρισμού, όχι στην επίγνωση.")

 ;; ── ΜΕΤΡΗΣΕΙΣ ΠΡΟΣ ΣΗΜΑΣΙΟΛΟΓΙΚΗ ΑΞΙΟΛΟΓΗΣΗ (ΟΧΙ ΑΚΟΜΗ ΕΥΡΗΜΑΤΑ) ────────
 ;; ΚΑΝΟΝΑΣ: ωμός αριθμός ΔΕΝ είναι ελάττωμα. Κάθε έδρα χρειάζεται ανάγνωση
 ;; πριν χαρακτηριστεί. Καταγράφονται με άγκυρες στο mechanical-map.sexp.
 :pending-semantic-review
 ((:class :silent-ignore   :count-in-source-systems 160
   :why "ignore-errors που καταπίνει σφάλμα = υποψήφιο σιωπηλό fallback,
         ευθεία σύγκρουση με H1 (μηδέν μαντεψιά) και gate 7 (κανένα silent fallback)")
  (:class :http-egress     :count-in-source-systems 58
   :why "έξοδος στο δίκτυο από το έμπιστο μονοπάτι — ποιες είναι η υποδοχή
         συμβούλου, ποιες πρόσληψη ΦΕΚ, ποιες κάτι άλλο")
  (:class :write-seat      :count-in-source-systems 53 :count-in-authority-v2 4
   :why "έδρες εγγραφής — ποιες γράφουν authoritative state")
  (:class :destructive     :count-in-source-systems 29
   :why "delete-file στο έμπιστο μονοπάτι")
  (:class :dyn-resolve     :count-corpus-own-census 492
   :why "δυναμική επίλυση συμβόλου = επιφάνεια μη στατικά ελέγξιμης ροής"))

 ;; ── ΓΕΓΟΝΟΣ ΠΕΡΙΒΑΛΛΟΝΤΟΣ ΠΟΥ ΕΠΗΡΕΑΖΕΙ ΤΗ ΜΕΘΟΔΟ ───────────────────────
 :environment-volatility
 (:observed "Το read-only mount /frozen/ro ΧΑΘΗΚΕ μεταξύ δύο εντολών, μαζί με
             τον docker daemon. Το περιβάλλον καθαρίζει mounts και διεργασίες."
  :consequence "Η απομόνωση ΔΕΝ επιβεβαιώνεται μία φορά — επιβεβαιώνεται ΠΡΙΝ
                ΑΠΟ ΚΑΘΕ ΑΝΑΓΝΩΣΗ, αλλιώς το αποτέλεσμα δεν είναι έγκυρο."
  :structural-fix "experiment/runner/ensure-ro-mount.sh — πύλη με θετικό μάρτυρα
                   (ανάγνωση, μη-κενότητα) και αρνητικό (γραφή ⇒ EROFS)."
  :first-victim "Μια σάρωση επέστρεψε 0 αρχεία επειδή το mount είχε χαθεί.
                 Χωρίς την πύλη θα καταγραφόταν ως «κενό corpus».")

 :what-remains
 ("Σημασιολογική ανάγνωση 1.365 first-party αρχείων από ανεξάρτητους πράκτορες"
  "Χαρακτηρισμός των 160 ignore-errors, 58 http, 53 write seats, 29 delete"
  "Επαλήθευση αν το GATE-4 καλύπτει το source/pdf-authority.lisp"
  "Τα εκκρεμή §14.3, §14.6, §14.8 — μπλοκαρισμένα στον docker daemon")

 :not-claimed
 "ΚΑΜΙΑ ολοκλήρωση Φάσης 1A. Κανένα capability contract δεν συμπληρώθηκε.
  Κανένας provisional winner. Καμία αρχιτεκτονική επιλογή.")
