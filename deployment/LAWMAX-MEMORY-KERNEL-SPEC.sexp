;;;; deployment/LAWMAX-MEMORY-KERNEL-SPEC.sexp
;;;; ============================================================================
;;;; LAWMAX MEMORY KERNEL — μηχανικά αναγνώσιμη προδιαγραφή (data-only)
;;;; ============================================================================
;;;; Ζεύγος του LAWMAX-MEMORY-KERNEL-SPEC.md. Διαβάζεται με *read-eval* = NIL,
;;;; σε keyword package. SPECIFICATION-ONLY: καμία αλλαγή runtime, κανένα νέο
;;;; store, κανένας Runner, καμία υιοθέτηση. Κάθε εγγραφή φέρει :evidence από
;;;; την πηγή/τα ζωντανά μητρώα — ΟΧΙ αφήγηση. Πηγή αλήθειας: :canonical-stores
;;;; του Συντάγματος, ο κώδικας, το git.

(:lawmax-memory-kernel-spec 1
 :authored-at-commit "191fd15c"
 :status :specification-only
 :source-of-truth (:constitution :canonical-stores :source-code :git)

 :non-negotiables
 ((:one-home-per-memory-kind "καμία έννοια μνήμης δεν έχει δύο σπίτια")
  (:one-writer-per-store     "ένας writer ανά store — επιβεβαιωμένο Π0-D")
  (:no-claim-without-proof   "memory_recorded:true μόνο μετά append+read-back στον ίδιο store")
  (:append-only-where-history "episodes: SHA-256 chain, tamper-evident")
  (:no-implementation-here   "οι φάσεις 1+ απαιτούν ρητό ΟΚ, μία-μία"))

 ;; ── Είδη μνήμης (cognitive taxonomy) ──
 :memory-types
 ((:id :episodic          :store "deployment/self/episodes.sexp"
   :persistence :disk-chained :writer "orchestrator.memory:record-episode"
   :reader "recall/read-lines" :evidence "source/memory.lisp:45,96")
  (:id :biographical      :store "deployment/self/history.sexp"
   :persistence :disk-bootstrap :writer :manual/genesis
   :evidence "constitution:canonical-stores")
  (:id :working           :store "*ask-memory*"
   :persistence :ram-ephemeral-per-process :writer "remember" :reader "recall"
   :evidence "decisions.lisp:1753")
  (:id :failure-dialogue  :store "deployment/state/failure-ledger.jsonl"
   :persistence :disk-append-readback :writer "record-dialogue-failure!"
   :reader "--failures / gap-ledger-frame" :evidence "understanding-learning.lisp:188")
  (:id :reflection-aggregate :store "deployment/state/lessons.jsonl"
   :persistence :disk-append :writer "%lesson" :evidence "constitution:canonical-stores")
  (:id :proposals         :store "deployment/self/proposals.sexp"
   :persistence :disk :writer :adoption-surface :evidence "constitution:canonical-stores")
  (:id :candidates        :store "deployment/self/candidates/"
   :persistence :disk-staging :writer :shadow-staging :evidence "constitution:canonical-stores")
  (:id :policies          :store "deployment/self/policies.sexp"
   :persistence :disk :writer :approval-surface :evidence "approval-policy.lisp")
  (:id :component-identity :store "deployment/self/component-manifest.sexp"
   :persistence :disk-build-artifact :writer "build.lisp:freeze-components!"
   :evidence "build.lisp")
  (:id :graph-snapshot    :store "deployment/self/graph-snapshot.sexp"
   :persistence :disk :writer "save-graph" :evidence "graph-import.lisp:186,223")
  (:id :cursors           :store "deployment/state/<key>-last-seen.txt"
   :persistence :disk-overwrite :writer "%write-cursor" :evidence "cli-util.lisp:55-70")
  (:id :review-queue      :store "review-queue.sexp"
   :persistence :disk :writer :review-surface :evidence "main.lisp:1269")
  (:id :execution-trace   :store "*events*"
   :persistence :ram-ephemeral-per-process :writer "trace" :reader "all-events"
   :evidence "execution-trace.lisp:46"))

 ;; ── Ρητά ΟΧΙ μνήμη (γνώση/σκαλωσιά) ──
 :adjacent-not-memory
 ((:knowledge-packs "deployment/knowledge/*.sexp"
   :why "δηλωτική γνώση/BOOTSTRAP, όχι βιωματική μνήμη — δηλωμένα στο Σύνταγμα :bootstrap-artifacts"))

 ;; ── Υπάρχοντα canonical stores (8 δηλωμένα στο Σύνταγμα) ──
 :existing-canonical-stores
 (("deployment/self/episodes.sexp"        :experiential-stream)
  ("deployment/self/history.sexp"         :biography)
  ("deployment/self/proposals.sexp"       :proposal-queue)
  ("deployment/self/graph-snapshot.sexp"  :graph-snapshot)
  ("deployment/state/lessons.jsonl"       :reflection-aggregate)
  ("deployment/state/failure-ledger.jsonl" :dialogue-failure-ledger)
  ("deployment/self/policies.sexp"        :approval-policies)
  ("deployment/self/candidates/"          :candidate-pack-staging))

 ;; ── Λειτουργικά stores εκτός :canonical-stores (δηλωμένο χρέος δήλωσης) ──
 :operational-stores-undeclared
 (("deployment/self/component-manifest.sexp" :identity-manifest :debt :declare-in-constitution-later)
  ("deployment/state/<key>-last-seen.txt"    :progress-cursor   :debt :declare-in-constitution-later)
  ("review-queue.sexp"                        :review-queue      :debt :declare-in-constitution-later)
  ("*ask-memory*"                             :ephemeral-working :note :ram-by-definition-out-of-canonical)
  ("*events*"                                 :ephemeral-trace   :note :ram-by-definition-out-of-canonical))

 ;; ── Missing stores (χάρτης κενών — ΔΕΝ χτίζονται χωρίς ΟΚ) ──
 :missing-stores
 ((:id :M1 :name :universal-turn-id-root-span
   :lacks "σταθερό id ανά --ask που δένει envelope+episode+ledger+trace"
   :known-from "P1 debt commit 62570e60"
   :consequence "failure_id/episode-id/gap_id χωρίς κοινό γονέα")
  (:id :M2 :name :session-store
   :lacks "εργαζόμενη μνήμη που επιβιώνει process"
   :known-from "decisions.lisp:1753 — *ask-memory* είναι RAM ανά process"
   :consequence "follow-up δένει μόνο εντός process (πύλη Β via internal twin)")
  (:id :M3 :name :recall-index
   :lacks "ευρετήριο ανάκλησης επεισοδίων"
   :known-from "recall = γραμμική σάρωση λημμάτων"
   :consequence "O(n) ανάκληση, δεν κλιμακώνει")
  (:id :M4 :name :consolidation
   :lacks "επεισοδιακή → σημασιολογική μακρά μνήμη"
   :known-from "καμία διεργασία episodes->concepts"
   :consequence "θυμάται συμβάντα, όχι μοτίβα")
  (:id :M5 :name :cross-session-conversation
   :lacks "συνέχεια διαλόγου μεταξύ συνεδριών"
   :known-from "καμία session persistence"
   :consequence "κάθε docker run ξεκινά χωρίς χθες"))

 ;; ── Duplicate risks (τι ΘΑ γινόταν διπλό — γιατί δεν είναι) ──
 :duplicate-risks
 ((:pair (:lessons.jsonl :failure-ledger.jsonl)
   :not-duplicate "aggregate vs δομημένη πρώτη-ύλη· ένας writer καθένας"
   :guard "understanding-gate ⑬ (Π0-D)")
  (:pair (:episodes.sexp :failure-ledger.jsonl)
   :not-duplicate "ρεύμα what-happened vs δομημένο what-gap· διαφορετικά σχήματα"
   :guard "μη-συγχρονισμός — δεν επιτρέπεται κοινός writer")
  (:pair (:working-memory :episode-props-answer)
   :not-duplicate "RAM εφήμερο vs μόνιμο ρεύμα· RAM δεν είναι source of truth")
  (:single :component-manifest.sexp
   :risk "λειτουργικό store εκτός :canonical-stores"
   :resolution :declare-role-later-with-approval))

 ;; ── Gates που φυλάνε τη μνήμη (υπάρχοντα, μετρημένα) ──
 :gates
 ((:gate "--memory-gate" :covers "episode write/read, agenda, recall, SHA-256 chain, ταυτοχρονία" :checks "10/10")
  (:gate "--understanding-gate" :covers "Π0-A/B/C/D: ledger append+recall, negative, ξεχωριστός writer" :checks "14/14")
  (:gate "--provenance-gate" :covers "έμπιστη έξοδος ↔ ίχνος· :off ⇒ καταγγελία" :checks "16/16")
  (:gate "--architecture-constitution-gate" :covers "⑨ ένας ρόλος ανά store, κανένα αδήλωτο store" :checks "part-of-12/12"))

 ;; ── Write / recall policy ──
 :write-recall-policy
 ((:store "episodes.sexp"        :write :chained-append :recall :lemma-linear :tamper :sha256-chain)
  (:store "failure-ledger.jsonl" :write :append-with-readback :recall :--failures :tamper :readback-proof)
  (:store "lessons.jsonl"        :write :append :recall :--lessons)
  (:store "policies.sexp"        :write :overwrite-in-surface :recall :policy-engine :tamper :signed-decision)
  (:store "cursors"              :write :overwrite :recall :read-cursor)
  (:store "graph-snapshot.sexp"  :write :snapshot :recall :load-graph :tamper :serialization-roundtrip)
  (:store "working-memory"       :write :remember :recall :recall :note :ram-ephemeral))

 :durability-invariant
 (:rule "κανένα store δεν λέει «γράφτηκε» χωρίς append ΚΑΙ read-back από το ΙΔΙΟ path"
  :active-since "191fd15c"
  :failure-codes (:ledger_missing :ledger_not_writable :readback_failed
                  :deployment_mount_missing :canonical_store_unavailable))

 ;; ── Trust / provenance policy ──
 :trust-provenance-policy
 ((:every-trusted-output-binds-to-trace "provenance-gate ②③④")
  (:memory-claim-is-computed "memory_recorded = επαληθευμένο append+read-back")
  (:episodic-integrity :sha256-chain)
  (:policy-adoption-changes :signed-with-whatif-and-rollback)
  (:no-llm-in-trusted-memory-path t))

 ;; ── Implementation phases (χάρτης — καμία εκτέλεση χωρίς ΟΚ ανά φάση) ──
 :implementation-phases
 ((:phase 0 :name :inventory-and-honest-failure-memory :status :done
   :note "Π0 accepted, P0 invariant, PASS=30/0 real Docker")
  (:phase 1 :name :universal-turn-id-root-span :addresses :M1 :status :requires-ok
   :gate-goal "κάθε γύρος ρίζα-span που δένει envelope+episode+ledger+trace")
  (:phase 2 :name :session-store :addresses :M2 :status :requires-ok
   :risk "προβολή όχι νέα αλήθεια δίπλα στα episodes")
  (:phase 3 :name :recall-index :addresses :M3 :status :requires-ok
   :risk "index ΠΑΡΑΓΩΓΟ των episodes, ποτέ πηγή")
  (:phase 4 :name :consolidation :addresses :M4 :status :requires-ok
   :risk "μόνο ΠΡΟΤΑΣΕΙΣ προς έγκριση, ποτέ auto-adopt, shadow+human")
  (:phase 5 :name :cross-session :addresses :M5 :status :requires-ok))

 ;; ── Τι ΔΕΝ κάνει (ρητά) ──
 :does-not
 (:runtime-change :new-store :new-writer :new-gate :runner :adoption
  :refactor :new-top-level-subsystem :legal-knowledge-expansion))
