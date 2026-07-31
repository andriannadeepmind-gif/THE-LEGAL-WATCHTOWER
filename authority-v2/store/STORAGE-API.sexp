;;;; authority-v2/store/STORAGE-API.sexp
;;;; ============================================================================
;;;; AUTHORITY STORE — ΔΙΕΠΑΦΗ ΚΑΙ ΥΠΟΧΡΕΩΣΕΙΣ (απαίτηση 7)
;;;; ============================================================================
;;;; ΡΗΤΗ ΕΝΤΟΛΗ ΔΗΜΙΟΥΡΓΟΥ: «Απαγορεύεται νέα χειροποίητη append/intent-log
;;;; authority με crash tests ως τελικό υπόστρωμα... Μην βάλεις προσωρινό
;;;; intent-log πίσω από το τελικό interface.»
;;;;
;;;; ΤΙ ΧΤΙΖΕΤΑΙ ΤΩΡΑ (ρητά επιτρεπτό όταν η toolchain λείπει): schema, pure
;;;; state-transition model, certificate format, ΑΥΤΟ ΤΟ storage API, αρνητικά
;;;; fixtures, hermetic build.
;;;; ΤΙ ΔΕΝ ΧΤΙΖΕΤΑΙ: ΚΑΜΙΑ υλοποίηση πίσω από το API. Το production writer
;;;; είναι ΑΠΕΝΕΡΓΟΠΟΙΗΜΕΝΟ και κάθε κλήση fail-closed.
;;;;
;;;; Η ΜΙΑ ΣΥΝΑΛΛΑΓΗ: τα έξι παρακάτω γράφονται ΟΛΑ ΜΑΖΙ ή ΤΙΠΟΤΑ.

(:lawmax-authority-store-api/1

 :assurance-status :under-construction
 :implementation-status :absent-by-design
 :production-writer :disabled
 :substrate-requirement "Perennial 2.0 / GoTxn με απόδειξη atomicity+recovery"
 :substrate-status :externally-blocked
 :forbidden-substitutes
 ("χειροποίητο intent-log / append-log με fsync"
  "SQLite ή άλλο DB χωρίς την απόδειξη"
  "atomic rename ως 'commit point' με crash tests αντί απόδειξης")

 ;; ── Η ΜΟΝΑΔΙΚΗ ΜΕΤΑΒΑΤΙΚΗ ΠΡΑΞΗ ──────────────────────────────────────────
 ;; ΟΛΑ σε ΜΙΑ συναλλαγή. Μερική εγγραφή = αδύνατη (όχι «απίθανη»).
 :commit-transaction
 (:name "commit-accepted-transition!"
  :atomic-set
  ((:item :accepted-transition   :desc "το transition certificate ΩΜΟ (CBOR)")
   (:item :state-sequence        :desc "νέα authority-state με sequence = prev+1")
   (:item :release-reference     :desc "αναφορά στο content-addressed release blob")
   (:item :log-entry             :desc "C2SP log entry (leaf) του νέου root")
   (:item :signed-checkpoint     :desc "υπογεγραμμένο checkpoint {size,root,time}")
   (:item :authoritative-latest  :desc "ο ΜΟΝΑΔΙΚΟΣ latest δείκτης"))
  :obligations
  ((:id :atomicity
    :statement "είτε ΚΑΙ ΤΑ ΕΞΙ είναι ορατά, είτε ΚΑΝΕΝΑ — καμία ενδιάμεση κατάσταση"
    :discharged-by "Perennial/GoTxn θεώρημα" :status :blocked-toolchain)
   (:id :recovery
    :statement "μετά από crash σε ΟΠΟΙΟΔΗΠΟΤΕ σημείο, το recovery δίνει κατάσταση
                που είναι ΕΙΤΕ η πριν ΕΙΤΕ η μετά — ποτέ υβρίδιο"
    :discharged-by "Perennial/GoTxn θεώρημα" :status :blocked-toolchain)
   (:id :single-writer
    :statement "καμία δεύτερη διεργασία δεν γράφει ταυτόχρονα"
    :discharged-by "OS capability closure (απαίτηση 1)" :status :implemented-not-proved)))

 ;; ── ΑΝΑΓΝΩΣΗ ──────────────────────────────────────────────────────────────
 :read-api
 ((:name "current-state"      :returns "authority-state" :side-effects nil)
  (:name "state-at-sequence"  :returns "authority-state" :side-effects nil)
  (:name "certificate-at"     :returns "transition-certificate (ΩΜΟ CBOR)" :side-effects nil)
  (:name "checkpoint-latest"  :returns "signed-checkpoint" :side-effects nil))

 ;; ── ΕΚΚΙΝΗΣΗ / ΑΝΑΚΑΜΨΗ (απαίτηση 10) ────────────────────────────────────
 :startup-obligation
 (:statement "Πριν σερβιριστεί ΟΤΙΔΗΠΟΤΕ, επαναλέγχεται ΟΛΟΚΛΗΡΗ η αλυσίδα:
              κάθε certificate επαληθεύεται, κάθε state hash επανυπολογίζεται,
              κάθε checkpoint επαληθεύεται, η ακολουθία sequence είναι συνεχής
              και μονοτονική, και το latest προκύπτει από αποδεκτή μετάβαση."
  :on-failure "ΚΛΕΙΣΤΟ — δεν σερβίρεται τίποτα (fail-closed, ποτέ 'degraded mode')"
  :status :not-started)

 ;; ── ΤΑ DERIVED CACHES ΔΕΝ ΕΙΝΑΙ ΠΟΤΕ AUTHORITY ───────────────────────────
 :derived-caches
 (:items ("releases/latest symlink" "releases/latest.json" "site/*" "proofs/*")
  :rule "ΠΑΡΑΓΟΝΤΑΙ από committed accepted state. Διαγραφή τους ΔΕΝ αλλάζει την
         αλήθεια· ανακατασκευή τους ΠΡΕΠΕΙ να δίνει byte-for-byte το ίδιο."
  :status :not-started))
