;;;; experiment/artifacts/SUSPENSION-CHECKPOINT.sexp
;;;; §12 ΤΟΥ ΣΥΝΤΑΓΜΑΤΟΣ: εξάντληση πόρου ⇒ SUSPENDED + ΑΚΡΙΒΕΣ CHECKPOINT.
;;;; ΠΟΤΕ FINAL. Καμία μερική εργασία δεν βαφτίζεται αποτέλεσμα.

(:lawmax-suspension-checkpoint/1
 :state :SUSPENDED
 :reason :external-resource-exhaustion
 :NOT-a-corpus-finding t

 :what-happened
 ((:event "Και οι 7 πράκτορες της Φάσης 1A τερματίστηκαν πριν γράψουν artifact"
   :cause "API session limit του λογαριασμού — reset 19:20 UTC"
   :evidence "task notifications: «Agent terminated early due to an API error: You've hit your session limit»"
   :agents ("source" "systems" "authority-v2" "deployment-specs" "deployment-state" "harness" "contracts")
   :artifacts-produced 0)
  (:event "Ο docker daemon τερματίζεται από το περιβάλλον και δεν επανεκκινεί"
   :evidence "dockerd σε foreground ⇒ exit 143 (SIGTERM)· δύο προηγούμενες επανεκκινήσεις επέζησαν, η τρίτη όχι"
   :consequence "κάθε μέτρηση που απαιτεί container είναι ΑΝΕΚΤΕΛΕΣΤΗ, ΟΧΙ αποτυχημένη"))

 ;; ── ΤΙ ΑΚΥΡΩΝΕΤΑΙ ΡΗΤΑ ─────────────────────────────────────────────────────
 :invalidated
 ((:artifact "census SBCL 2.4.0 (136/136 exit≠0)"
   :verdict :ΑΚΥΡΟ
   :why "Ο daemon πέθανε ΚΑΤΑ την εκτέλεση: και τα 136 logs περιέχουν «Cannot connect
         to the Docker daemon», ΟΧΙ το σφάλμα log4cl. ΔΕΝ μετράει ως μέτρηση 2.4.0
         και ΔΕΝ αντικαθιστά την προηγούμενη παρατήρηση των 104/104."
   :correct-status :NOT-EXECUTED))

 ;; ── ΤΙ ΠΑΡΑΜΕΝΕΙ ΕΓΚΥΡΟ (μετρημένο πριν τη διακοπή, κατατεθειμένο) ────────
 :valid-and-committed
 ((:constitution "sha256:5b3ab5bf9561d535adbf5049b975ac2ab8e9a63db32dfb14a07d82d78b729be6" :sealed t)
  (:frozen-corpus "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b"
   :independent-paths 3 :paths ("κανονική Lisp" "ανεξάρτητη υλοποίηση αναφοράς" "καθαρή επανεξαγωγή")
   :mutation-witness "1 byte ⇒ d2ca0862… ≠ ad8fd575…")
  (:suite-census "136 εκτελεσμένες · 132 exit 0 · 4 γνήσιες αποτυχίες · 2839 checks passed · 3 failed")
  (:rebuilds "A/B ταυτόσημα σε layers/config/core/executable/inventory· 7 πεδία build-session διαφέρουν")
  (:asdf-resolution "199 systems· ταυτόσημη επίλυση με και χωρίς cl-dependencies· 0 από εκείνη τη ρίζα")
  (:read-only-mount "/frozen/ro — EROFS σε γραφή και διαγραφή, ρίζα αμετάβλητη")
  (:constitution-checker "θετικός 5/5 artifacts· αρνητικός μάρτυρας ⇒ exit 1")
  (:spin-t14 "errors: 0 — MODEL-CHECKED, ΟΧΙ implementation-proved"))

 ;; ── §14: ΤΙ ΔΙΟΡΘΩΘΗΚΕ ΚΑΙ ΤΙ ΜΕΝΕΙ ──────────────────────────────────────
 :s14-corrections
 ((:id 1 :status :ΔΙΟΡΘΩΘΗΚΕ
   :finding "199 = 170 third-party + 16 central-registry-root + 4 SBCL contribs
             + 1 uiop (:BUILT-IN, χωρίς αρχείο πηγής) + 8. Το άθροισμα 198 παρέλειπε το uiop.")
  (:id 2 :status :ΔΙΟΡΘΩΘΗΚΕ
   :finding "Το tests/comparison-test.lisp μετριόταν ΔΥΟ φορές (ως αρχείο σουίτας ΚΑΙ ως
             εξαίρεση). Πλέον: 136 αρχεία σουιτών, 1 δηλωμένη εξαίρεση, 135 gated.")
  (:id 3 :status :ΕΚΚΡΕΜΕΙ :blocked-by :docker-daemon
   :note "Απαιτεί ΝΕΑ εκτέλεση στο 2.4.0 image με ζωντανό daemon.")
  (:id 4 :status :ΔΙΟΡΘΩΘΗΚΕ
   :finding "Οι «8 ανεπίλυτες» ΔΕΝ ΕΙΝΑΙ SYSTEMS — είναι feature keywords σε
             :if-feature / (:feature …). Ονομαστικές έδρες:
               abcl, allegro, clisp, usocket-iolib → third-party/usocket-*/usocket.asd:35-45
               corman   → third-party/bordeaux-threads-v0.9.4/bordeaux-threads.asd:36,50,77
               darwin   → third-party/cffi-*/cffi.asd
               sbcl     → third-party/alexandria-*/alexandria.asd, introspect-environment.asd
               allegro  → third-party/trivial-cltl2*/trivial-cltl2.asd
               cmucl    → introspect-environment.asd, mgl-pax-test.asd
             ΜΗΔΕΝ επίπτωση στην επίλυση, ανεπίλυτα ΚΑΙ ΣΤΙΣ ΔΥΟ διαμορφώσεις.
             ΕΙΝΑΙ ΕΛΑΤΤΩΜΑ ΤΟΥ ΔΙΚΟΥ ΜΟΥ ΕΡΓΑΛΕΙΟΥ: ο closure walker εκλάμβανε
             feature names ως system names.")
  (:id 5 :status :ΔΙΟΡΘΩΘΗΚΕ
   :finding "Ίδιο .Config και ίδια RootFS.Layers· διαφορετικό .Id επειδή το manifest
             ενσωματώνει BuildKit provenance (Build.CreatedAt, Build.Ref) και LastTagTime.
             Περιεχόμενο ταυτόσημο· ταυτότητα εικόνας μη ντετερμινιστική.")
  (:id 6 :status :ΕΚΚΡΕΜΕΙ :blocked-by :docker-daemon
   :note "Τα δύο rebuilds αφορούν το image ΤΟΥ 2.4.0. Ο ΠΑΓΩΜΕΝΟΣ runner (2.2.9)
          ΔΕΝ έχει δύο καθαρά rebuilds. Ορολογία: repeatability ίδιου περιβάλλοντος,
          ΟΧΙ ανεξάρτητη replication.")
  (:id 7 :status :ΔΙΟΡΘΩΘΗΚΕ
   :finding "census.py: φρέσκο disposable overlay ΑΝΑ σουίτα (upper/ovlwork/tmp).
             Το FASL cache παραμένει κοινό και ΧΩΡΙΣΤΑ προσαρτημένο, δηλωμένο ρητά ως
             ντετερμινιστικό προϊόν μεταγλώττισης με κλειδί τη διαδρομή πηγής,
             ΟΧΙ κατάσταση δοκιμής.")
  (:id 8 :status :ΕΚΚΡΕΜΕΙ :blocked-by :docker-daemon
   :note "Η εκτέλεση FiveAM (31 tests, 7 X) κηρύσσεται ΑΚΥΡΗ λόγω memory fault
          (JONATHAN.ENCODE::%TO-JSON) στο ίδιο Lisp image. Απαιτείται εκτέλεση
          ΑΝΑ TEST σε ξεχωριστή διεργασία.")
  (:id 9 :status :ΔΙΟΡΘΩΘΗΚΕ
   :finding "/frozen/ro OS-level read-only (bind + remount,ro). Οι πράκτορες
             διαβάζουν ΜΟΝΟ από εκεί, με ρητή απαγόρευση /app και /frozen/watchtower.")
  (:id 10 :status :ΔΙΟΡΘΩΘΗΚΕ
   :finding "T14 = MODEL-CHECKED παντού. Λείπουν: refinement relation μοντέλου→runner
             και non-vacuity witness."))

 ;; ── ΑΚΡΙΒΕΣ ΣΗΜΕΙΟ ΕΠΑΝΕΚΚΙΝΗΣΗΣ ─────────────────────────────────────────
 :resume-from
 (:phase :1A
  :prerequisites ("API session limit: reset 19:20 UTC" "docker daemon ζωντανός")
  :first-action "Επανεκκίνηση των 7 πρακτόρων Φάσης 1A με ΤΟ ΙΔΙΟ prompt
                 (experiment/agents/PHASE-1A-PROMPT.md, sha256
                 e0a176a26b5aab4fcf1098aa38227a701e0e002887157061222910501225b3f5),
                 ΤΙΣ ΙΔΙΕΣ επτά συστάδες, ανάγνωση ΜΟΝΟ από /frozen/ro."
  :clusters ((:name "source"            :files 133)
             (:name "systems"           :files 175)
             (:name "authority-v2"      :files 63)
             (:name "deployment-specs"  :files "LAWMAX-*, SYSTEM-CONSTITUTION, PCL, *.ttl, verify/, templates/, mcp/")
             (:name "deployment-state"  :files "self/, self-study/, knowledge/, data/, state/, collab/, *.js, *.sh")
             (:name "harness"           :files "tests/ 152 + docker/ 16 + scripts/ 8")
             (:name "contracts"         :files "ρίζα 43 + configs/ 9 + docs/ 18 + .github/ 3 + cloudflare/ 5 + tools/ 1"))
  :then ("§14.3 census 2.4.0 με ζωντανό daemon"
         "§14.6 δύο καθαρά rebuilds του ΠΑΓΩΜΕΝΟΥ 2.2.9 image"
         "§14.8 FiveAM ανά test σε ξεχωριστή διεργασία")
  :forbidden "ΚΑΜΙΑ μετάβαση σε FINAL. Καμία σύνθεση. Κανένας provisional winner.
              Καμία επιλογή αρχιτεκτονικής. Το preflight ΔΕΝ ξανανοίγει: η ταυτότητα
              του corpus, η ακεραιότητα του runner, η phase isolation και το
              σφραγισμένο Σύνταγμα παραμένουν αμετάβλητα.")

 :constitutional-basis "§12 — token/context exhaustion ΔΕΝ είναι closure certificate.")
