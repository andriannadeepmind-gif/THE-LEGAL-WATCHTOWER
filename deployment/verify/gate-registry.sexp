;;;; deployment/verify/gate-registry.sexp
;;;; ============================================================================
;;;; CANONICAL GATE REGISTRY — η ΜΙΑ πηγή αλήθειας του συνόλου πυλών ([κύκλος-2 #7])
;;;; ============================================================================
;;;; Data-only (safe-read-able). Ο assess-gate-manifest.lisp επιβάλλει ΑΚΡΙΒΗ set-equality
;;;; του gate-plenary manifest (που εκπέμπει το run-all-gates) με ΑΥΤΟ το σύνολο: καμία πύλη
;;;; να μη λείπει (silent removal), καμία επιπλέον, κανένα duplicate. Νέα/αφαιρεμένη πύλη ⇒
;;;; ρητή ενημέρωση ΕΔΩ (ratchet — το σύνολο δεν αλλάζει σιωπηλά).
;;;;
;;;; Παράγεται από τα registered «--*-gate» commands (run-all-gates). Τα ονόματα είναι
;;;; keywords ΧΩΡΙΣ leading dashes (όπως στο manifest: «--advisor-gate» → :advisor-gate).
;;;;
;;;; ΣΗΜΕΙΩΣΗ ΒΑΘΜΟΝΟΜΗΣΗΣ: το σύνολο παρήχθη με στατική απαρίθμηση των register-command
;;;; «*-gate» της πηγής (25 — η :capability-gate προστέθηκε ρητά [ΤΑΒΑΝΙ #1]). Το πρώτο
;;;; owner-side Docker run επικυρώνει ότι ταιριάζει με το runtime *commands* set· τυχόν
;;;; διαφορά = πραγματικό drift προς συμφιλίωση (ο checker το δηλώνει ρητά, δεν το κρύβει).

(:schema :gate-registry/1
 :gates (:advisor-gate
         :architecture-constitution-gate
         :capability-gate
         :component-gate
         :contract-gate
         :deontic-gate
         :dialogue-gate
         :draft-gate
         :event-gate
         :extension-gate
         :external-benchmark-gate
         :fluid-gate
         :generation-gate
         :golden-gate
         :inference-gate
         :iq-gate
         :memory-gate
         :mirror-gate
         :policy-gate
         :provenance-gate
         :release-gate
         :self-evolution-gate
         :subsumption-gate
         :understanding-gate
         :verify-truth-gate))
