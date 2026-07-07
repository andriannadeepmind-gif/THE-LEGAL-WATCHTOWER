;;;; deployment/LAWMAX-PHASE-1-TURN-ROOT-SPAN-DESIGN.sexp
;;;; ============================================================================
;;;; Φ1 — UNIVERSAL TURN ID / ROOT SPAN · DESIGN ONLY (μηχανικά αναγνώσιμο)
;;;; ============================================================================
;;;; Ζεύγος του LAWMAX-PHASE-1-TURN-ROOT-SPAN-DESIGN.md. Data-only:
;;;; *read-eval* NIL, keyword package. ΚΑΜΙΑ υλοποίηση από αυτό το αρχείο —
;;;; η υλοποίηση είναι το βήμα 3 της κλειδωμένης σειράς, με ρητό ΟΚ.

(:lawmax-phase-1-turn-root-span-design 1
 :status :design-only
 :origin (:memory-kernel :M1 :p1-debt "62570e60" :cpei-keystone (:act_id :turn_id))

 :problem
 (:statement "ένας --ask γύρος γεννά envelope/episode/failure-record/root-span/gap με ΠΕΝΤΕ ασύνδετες ταυτότητες — κανένα κοινό κλειδί, ο γύρος δεν ανασυστήνεται"
  :evidence ((:envelope :stdout :id :none)
             (:episode "episodes.sexp" :id "eid=sha(kind|text|at|prev)")
             (:failure "failure-ledger.jsonl" :id "fid=sha(input|context)")
             (:trace "*events*" :id :monotonic-integer)
             (:gap :envelope+ledger :id "gid=sha(q)")))

 :locked-principle
 "το turn_id είναι ΠΕΔΙΟ που διατρέχει τις ΥΠΑΡΧΟΥΣΕΣ έδρες — ΟΧΙ νέο store, ΟΧΙ νέο αρχείο, ΟΧΙ νέο subsystem· τα υπάρχοντα ids (eid/fid/gid/span-id) ΔΕΝ αλλάζουν"

 :identities
 ((:name :turn_id
   :format "turn:<sha256-12>"
   :derivation "sha256(input ‖ iso-timestamp ‖ process-nonce ‖ αύξων-μετρητής-γύρου)"
   :birth "είσοδος του run-ask, ΠΡΙΝ από κάθε ταξινόμηση — και το «δεν κατάλαβα» το φέρει"
   :scope :dynamic-var-per-turn)
  (:name :root_span_id
   :format :existing-trace-event-id
   :note "το ΥΠΑΡΧΟΝ ρίζα-span (provenance-gate ⑨) — δεν αντικαθίσταται· αποκτά :turn-id στο data plist"
   :relation "1 turn_id ↔ 1 root_span_id ανά γύρο")
  (:name :act_id :status :out-of-scope :note "CPEI παράγωγο του turn_id — ΟΧΙ σε αυτή τη φάση"))

 ;; ── τα 8 δεσίματα ──
 :links
 ((:n 1 :link :turn_id          :seat "run-ask (decisions.lisp)"
   :how "γέννηση στην είσοδο· δέσμευση *current-turn-id* για τον γύρο")
  (:n 2 :link :root_span_id     :seat "execution-trace / exec-provenance"
   :how "root-span data += :turn-id· αμφίδρομη αντιστοίχιση turn_id ↔ tevent-id")
  (:n 3 :link :envelope         :seat "%ask-envelope"
   :how "νέες γραμμές turn_id: + root_span_id: σε ΚΑΘΕ έξοδο (answered/not-understood/refused)")
  (:n 4 :link :episode          :seat "record-episode :props"
   :how ":turn-id στο props plist του :interaction — το σχήμα δεν αλλάζει (props ανοιχτό)")
  (:n 5 :link :failure-ledger   :seat "record-dialogue-failure!"
   :how "νέο JSON πεδίο \"turn_id\"· optional στο read — παλιές γραμμές έγκυρες")
  (:n 6 :link :trace            :seat "child spans"
   :how "κληρονομιά μέσω root-span γονέα — καμία αλλαγή στα child events")
  (:n 7 :link :gap_id           :seat "gap δημιουργία στο run-ask"
   :how "gap record/envelope φέρουν και turn_id· το gid μένει σταθερό-ανά-ερώτηση ΣΚΟΠΙΜΑ")
  (:n 8 :link :recall           :seat "gap-ledger-frame + «δείξε μου τον γύρο <turn_id>»"
   :how "join πάνω στο turn_id: input+mode+eid+fid+gid+root_span — ή τίμιο «δεν βρέθηκε»"))

 ;; ── αναλλοίωτα = οι έλεγχοι του gate της υλοποίησης (βήμα 3) ──
 :invariants
 ((:i 1 "κάθε --ask γύρος εκπέμπει turn_id στο envelope — ΠΑΝΤΑ")
  (:i 2 "ΙΔΙΟ turn_id σε envelope ∧ episode ∧ ledger(αν γράφτηκε) ∧ root-span — grep και στα 4")
  (:i 3 "διαδοχικοί γύροι ⇒ διαφορετικά turn_ids, ακόμη και με ίδια ερώτηση")
  (:i 4 "backward-compat: εγγραφές χωρίς turn_id διαβάζονται κανονικά (πεδίο προσθετικό)")
  (:i 5 "P0 invariant άθικτο: memory_recorded = append+read-back, το turn_id απλώς συμμετέχει")
  (:i 6 "κανένα νέο αρχείο στον δίσκο — architecture-gate ⑨ αμετάβλητα πράσινο")
  (:i 7 "recall γύρου: joined στοιχεία ή τίμιο «δεν βρέθηκε»"))

 :does-not
 (:new-store :new-file :new-subsystem :id-migration :session-persistence
  :act-id :jurisdiction :runner :learning-claim :behavior-change-in-this-doc)

 :implementation-plan-step-3
 (:touches ("decisions.lisp (γέννηση+envelope+gap)"
            "record-episode caller (1 prop)"
            "understanding-learning.lisp (1 JSON πεδίο)"
            "execution-trace/exec-provenance (root-span data)"
            "cognition-self.lisp (recall γύρου)")
  :gates "νέοι έλεγχοι στα ΥΠΑΡΧΟΝΤΑ understanding/provenance/dialogue gates"
  :constitution "χαρτογράφηση ό,τι νέου εκτεθεί"
  :rollback "revert ενός commit — optional πεδία δεν σπάνε αναγνώστες"
  :requires :explicit-creator-ok))
