(:hash-seat-registry/1
 ;; ==========================================================================
 ;; [audit#13] ΤΟ ΑΠΟΚΛΕΙΣΤΙΚΟ ΜΗΤΡΩΟ ΚΑΘΕ ΕΔΡΑΣ HASHING (ironclad:digest*)
 ;; ==========================================================================
 ;; Ο κριτής: το hash-authority δήλωνε «η ONLY hash» ενώ πολλά αρχεία καλούν
 ;; ironclad:digest απευθείας. Δεν γίνεται (ούτε πρέπει) να ενοποιηθούν πρωτόκολλα
 ;; με ΔΙΑΦΟΡΕΤΙΚΟ συμβόλαιο (RS256, X.509, RFC-3161 TSA, RFC-6962 Merkle,
 ;; keccak/256, digest-file). Αντ' αυτού: ΚΑΘΕ hash-έδρα ΔΗΛΩΝΕΤΑΙ ΕΔΩ με λόγο, και
 ;; το tests/hash-seat-registry-test.lisp επιβάλλει set-ισότητα με το repo — καμία
 ;; ΚΡΥΦΗ ή ΑΔΗΛΩΤΗ hash έδρα (undeclared ⇒ κόκκινο· stale ⇒ κόκκινο).
 ;; «Μία έδρα ανά ΕΝΝΟΙΑ»: η έννοια «γενικό content hash» = hash-authority· κάθε
 ;; πρωτόκολλο είναι ΔΙΑΦΟΡΕΤΙΚΗ έννοια, ρητά δηλωμένη.
 :seats
 ((:file "source/hash-authority.lisp"        :reason "Η ΓΕΝΙΚΗ content-hash έδρα (compute-hash, ρητό algorithm) — content addressing")
  (:file "source/journal.lisp"               :reason "sha256-hex: content hash journal/ταυτότητας (string→hex)")
  (:file "source/merkle-authority.lisp"      :reason "RFC-6962 Merkle tree hashing (raw bytes, domain-separated leaf/node)")
  (:file "source/jws-authority.lisp"         :reason "JWS/RS256 payload digest (RFC 7515/7797) + PKCS#1 EMSA-SHA256")
  (:file "source/x509-authority.lisp"        :reason "X.509 SPKI/cert SHA-256 fingerprint")
  (:file "source/timestamp-authority.lisp"   :reason "RFC-3161 TSA message imprint / cert digest")
  (:file "source/blockchain-authority.lisp"  :reason "keccak/256 (Ethereum) + sha256 anchor")
  (:file "source/canonical-representation.lisp" :reason "canonical manifest-id seed hash")
  (:file "source/self-constitution.lisp"     :reason "digest-file ακεραιότητας constitution artifact")
  (:file "source/knowledge-packs.lisp"       :reason "digest-file ακεραιότητας knowledge pack")
  (:file "source/component-scan.lisp"        :reason "digest-file ακεραιότητας component artifact")
  (:file "source/trace-core.lisp"            :reason "trace event content hash (provenance ίχνος)")
  (:file "source/adoption-decision.lisp"     :reason "hash περιεχομένου απόφασης υιοθεσίας")
  (:file "source/authority-proof-bundle.lisp" :reason "digest statement του proof bundle")
  (:file "source/authority-evidence-replay.lisp" :reason "recompute digest για evidence replay verification")
  (:file "source/consolidation-proof.lisp"   :reason "digest consolidation proof")
  (:file "systems/orchestrator-cli/external-benchmark-gate.lisp" :reason "digest-file fingerprint εξωτερικού benchmark αρχείου")
  (:file "systems/orchestrator-cli/main.lisp" :reason "digest-file fingerprint (CLI artifact integrity)")
  (:file "systems/orchestrator-cli/version-graph-import.lisp" :reason "digest-file verify εισαγόμενου version-graph")
  (:file "systems/orchestrator-engine-sbcl/stages/anchor-blockchain.lisp" :reason "sha256 blockchain anchor stage")
  (:file "systems/orchestrator-engine-sbcl/stages/test-escaping.lisp" :reason "sha256 verification στο escaping stage")
  (:file "systems/orchestrator-epistemic/artifact-census.lisp" :reason "digest artifact census")
  (:file "systems/orchestrator-epistemic/deploy-epistemic.lisp" :reason "digest deploy-epistemic artifact")))
