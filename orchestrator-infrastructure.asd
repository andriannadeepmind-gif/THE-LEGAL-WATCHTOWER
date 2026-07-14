;;;; orchestrator-infrastructure.asd
;;;; ASDF System Definition for Orchestrator Infrastructure Layer
;;;; Cross-cutting concerns: paths, logging, DI, circuit breaker, protocols, session management

(asdf:defsystem #:orchestrator-infrastructure
  :description "Infrastructure layer for Greek Legal Corpus Orchestrator"
  :author "Spyridon Stavropoulos (Athens Bar Association) <ORCID: 0009-0005-2832-2153>"
  :license "All Rights Reserved"
  :version "1.0.0"
  :homepage "https://stavropouloslaw.com"
  
  :depends-on (#:alexandria
               #:serapeum
               #:bordeaux-threads
               #:local-time
               #:ironclad           ; GATE-3: SHA-256/SHA-512/BLAKE2 hashing + secp256k1
               #:babel              ; String-to-octets conversion for hashing
               #:cl-ppcre           ; GATE-5: Regex patterns for validation
               #:drakma             ; HTTP client for blockchain RPC
               #:jonathan           ; JSON encoding/decoding
               #:cl-base64          ; Base64 encoding for Arweave
               #:ieee-floats        ; GATE-10: IEEE 754 float encoding for embeddings
               #:cffi                ; GATE-13: Foreign function interface for libpoppler
               #:usocket             ; Pure-Lisp HTTP server sockets
               #:closer-mop          ; MOP for the corpus service content negotiation
               #:uuid                ; v4 UUIDs for the restored authority/provenance layers
               #:uiop)
  
  :serial t
  :components
  ((:module "source"
    :components
    ((:file "deterministic-time") ; Deterministic timestamp abstraction - MUST be first (used by paths)
     (:file "paths")              ; Path abstraction
     (:file "execution-trace")    ; ΙΧΝΟΣ ΕΚΤΕΛΕΣΗΣ: legal execution provenance πυρήνας — data-only, append-only, προφίλ κόστους
     (:file "canonical-uris")     ; Canonical URI configuration - Phase C
     (:file "eli-temporal-metadata") ; ELI temporal completeness - Phase D
     (:file "consolidation-engine") ; Codification: apply amendments -> in-force consolidated text
     (:file "consolidation-bridge") ; Bridge corpus articles + config amendments -> consolidation
     (:file "consolidation-proof")  ; Level-2: replayable amendment ledger (provably-correct consolidation)
     (:file "akoma-ntoso-emitter") ; Akoma Ntoso (LegalDocML 3.0) serialization of consolidated docs
     (:file "turtle-parser")      ; RDF Turtle -> triples parser (for SHACL)
     (:file "shacl-validator")    ; GATE-5: real SHACL Core validation engine
     (:file "legislation-ingestion") ; Incremental ingestion + scheduler (real-time updates)
     (:file "consolidation-feed") ; Ingestion -> consolidation loop (auto re-codification)
     (:file "ai-corpus-dump")     ; AI consumption layer: JSONL dump + DCAT catalog
     (:file "government-source")  ; Pull each code from its official state source
     (:file "document-fetch")     ; Pure-Lisp orchestration of an external (headless) document fetcher
     (:file "ingestion-daemon")   ; Deployment: source -> feed -> scheduler -> artifacts
     (:file "capability-registry"); Η ΜΙΑ έδρα δυνατοτήτων — HTTP/MCP/CLI είναι προβολές της (trust ως ιδιότητα)
     (:file "capability-api")     ; Transport-agnostic προβολή: /api/<name> → typed coercion → invoke
     (:file "http-server")        ; Pure-Lisp HTTP/1.1 server (usocket)
     (:file "corpus-service")     ; AI-first corpus HTTP service (CLOS + MOP negotiation)
     (:file "corpus-sparql")      ; Live SPARQL over the consolidated corpus (reuses sparql-endpoint)
     (:file "greek-tokenizer-advanced") ; Real Greek tokenizer (used by search)
     (:file "greek-nlp-core")     ; CLOS lexicon/analyzer protocol: tokenize/lemmatize, swappable backends
     (:file "lexicon-neurolingo") ; NeuroLingo-format morphological lexicon loader (file-lexicon backend)
     (:file "orthography-lexicon") ; Learned Greek orthography as a greek-nlp LEXICON backend
     (:file "citation-authority") ; Citation graph analytics: PageRank, TF-IDF, centrality, semantic hubs
     (:file "greek-lemmatizer")   ; Rule-based Greek legal lemmatizer (extends citation-authority)
     (:file "corpus-search")      ; Greek full-text search over the corpus
     (:file "corpus-diff")        ; Point-in-time legal diff (wires semantic-versioning)
     (:file "logging")            ; Structured logging
     (:file "write-authority")    ; GATE-2: Write authority unification
     (:file "hash-authority")     ; GATE-3: Hash authority unification
     (:file "merkle-authority")   ; Η ΜΙΑ έδρα Merkle (RFC 6962): domain-separated leaves/nodes + unbalanced split + audit path — φορτώνεται νωρίς (θεμελιώδης, μόνο ironclad/babel)
     (:file "corpus-fingerprint") ; Correctness guarantee: deterministic fingerprint + invariant gate
     (:file "legal-references")   ; Intelligence: legal cross-reference graph + integrity
     (:file "legal-hypergraph")   ; Level-3+: N-ary legal hypergraph model (CLOS/MOP, polymorphic RDF)
     (:file "guard-metaeval")     ; Ο ΜΕΤΑΚΥΚΛΙΚΟΣ ΑΠΟΤΙΜΗΤΗΣ ΦΡΑΓΜΩΝ: ελάχιστος πυρήνας + πύργος ορισμών ΣΤΗ γλώσσα + ίχνος αναγωγών στην απόδειξη
     (:file "legal-inference-engine") ; BRAIN L1: forward-chaining production system + JTMS + rule DSL (deterministic, proof-carrying reasoning)
     (:file "greek-legislation-ontology") ; BRAIN TBox: formal Greek-legislation domain ontology (CLOS class graph = OWL/RDFS, ELI/Akoma-Ntoso aligned)
     (:file "legal-conflict-resolution") ; BRAIN L2: lex-superior conflict resolution + hierarchy validity (ontology ranks → JTMS proofs)
     (:file "legal-temporal")     ; BRAIN L3: point-in-time law — interval calculus (Allen), version timelines, gaps/overlaps, defeasible ultra-activity
     (:file "legal-event-calculus") ; BRAIN L3β: EVENT CALCULUS — γεγονότα γεννούν/σβήνουν έννομες καταστάσεις, αδράνεια μέσω WFS (η αντίληψη ΙΣΤΟΡΙΑΣ)
     (:file "legal-penalty")      ; Το μέτρο του «επιεικέστερου» (2 ΠΚ): πλέγμα βαρύτητας κυρίων ποινών ΠΚ, ντετερμινιστικό, με λόγο
     (:file "legal-decisions")     ; ΝΟΜΟΛΟΓΙΑ: decisions corpus — structured σύνθεση (δικαστές+ρόλοι), citations with law tags, tempus-regit-actum anchoring
     (:file "legal-precedent")     ; BRAIN L4: δεδικασμένο×χρόνος στον JTMS — defeasible precedent verdicts με δέντρα απόδειξης
     (:file "legal-deontic")       ; BRAIN L5: δεοντικό επίπεδο — τι ΠΡΟΣΤΑΖΕΙ ο κανόνας (O/F/P) + κανονιστική σύγκρουση, γέφυρα στον L2
     (:file "legal-extraction-verify") ; Ο ΕΠΑΛΗΘΕΥΤΗΣ ΕΞΑΓΩΓΗΣ: neural προτείνει / symbolic κρίνει — θεμέλιο του ασφαλούς αυτόνομου βρόχου
     (:file "legal-knowledge")    ; ΕΝΟΠΟΙΗΜΕΝΗ ΓΝΩΣΗ: ένας εγκέφαλος, όλα τα γεγονότα, cross-brain αποδείξεις + μετα-γνώση (τι λείπει)
     (:file "knowledge-packs")    ; ΠΑΚΕΤΑ ΓΝΩΣΗΣ: fingerprinted δηλωτική γνώση (deployment/knowledge/) — hot reload + σκιώδης εκτέλεση για μη-παλινδρόμηση
     (:file "guard-ops-pack")     ; Ο ΚΑΤΑΝΑΛΩΤΗΣ :guard-ops: νέοι τελεστές της γλώσσας φραγμών ΩΣ ΓΝΩΣΗ (στρωμάτωση, σκιά, έγκριση)
     (:file "legal-subsumption")  ; Σ4 ΥΠΑΓΩΓΗ: υπόθεση→κανόνες→απόφανση με απόδειξη + πακέτο :tatbestand + μετα-γνώση «τι λείπει»
     (:file "legal-dialectic")    ; Σ5 ΑΝΤΙΔΙΚΙΑ: θέση↔ένσταση με τρίτιμο well-founded (grounded semantics) — ισοπαλία ΔΗΛΩΝΕΤΑΙ
     (:file "legal-counterfactual") ; Σ6 ΥΠΟΘΕΤΙΚΟΣ ΛΟΓΟΣ: κρίσιμα γεγονότα + ελάχιστα σύνολα φραγής (ablation)
     (:file "legal-strategy")     ; Σ9 ΣΤΡΑΤΗΓΙΚΗ: STRIPS δικονομικοί τελεστές + BFS πλάνο με αποδείξεις εμπροθέσμου
     (:file "legal-casegrammar")
     (:file "legal-hypo")
     (:file "fluid-induction")    ; Σ12-ΡΕΥΣΤΟ: επαγωγή προγραμμάτων από παραδείγματα (ARC-family: DSL+αναζήτηση+ακριβής επαλήθευση)         ; Σ7 HYPO/CATO: παράγοντες, διακρίσεις, κατάταξη, k-NN διατακτικού — Η ΜΙΑ ομοιότητα υποθέσεων  ; Σ4β ΓΡΑΜΜΑΤΙΚΗ ΠΤΩΣΕΩΝ (Fillmore): αφήγηση → γεγονότα υπόθεσης (πακέτο :verb-frames)
     (:file "journal")            ; ΤΟ ΕΝΑ ΙΔΙΩΜΑ ΗΜΕΡΟΛΟΓΙΟΥ: iso-now/sha256-hex/append-line/read-lines — η μία έδρα (βιογραφία/προτάσεις/επεισόδια)
     (:file "deliberation")       ; ΤΟ ΕΓΩ: ο στοχαστής — MOP metaclass σκέψης (καμία σκέψη αόρατη), κύκλος υπόθεση→δοκιμή-σε-απομόνωση→επαλήθευση
     (:file "proposals")          ; ΤΟ ΕΓΩ: γενικό μητρώο προτάσεων→έγκρισης (open/closed) — προσωρινή απόρριψη κατά υπογραφή-αποδείξεων
     (:file "introspection")      ; ΤΟ ΕΓΩ: γενική μηχανή αναστοχασμού — μητρώο παρατηρητών, ορατή σκέψη, ευρήματα→προτάσεις
     (:file "self-history")       ; ΤΟ ΕΓΩ: append-only βιογραφία με SHA-256 αλυσίδα — γένεση από τον δημιουργό, συνέχεια από το σύστημα
     (:file "self-constitution")  ; ΤΟ ΕΓΩ: το σύνταγμα του συστήματος (ποιον υπηρετεί/γιατί) με ταυτότητα + μετρήσιμη αποστολή
     (:file "constitutional-gate") ; ΤΟ ΕΓΩ: ο υπέρτατος φραγμός ως ιδιότητα — μητρώο κανόνων + αποτίμηση + ρητή παράκαμψη (open/closed)
     (:file "cognition")          ; Η ΓΝΩΣΙΑΚΗ ΔΙΑΔΙΚΑΣΙΑ: 5 στάδια (αποδόμηση→σχεδιασμός→επαλήθευση→μνήμη→σύνθεση) — γενικά, με σύμβουλο pluggable
     (:file "memory")             ; ΤΟ ΥΠΟΣΤΡΩΜΑ ΜΝΗΜΗΣ: ένα ρεύμα επεισοδίων (SHA-256 αλυσίδα) → επεισοδιακή/συνομιλιακή/ατζέντα/προθετική/περιπτώσεων
     (:file "legal-identity") ; [0088] Η ΜΙΑ έδρα νομικής ταυτότητας: orchestrator.identity (provision-id/body-id/ordinal) + δηλωμένος adapter orchestrator.article-id (θάνατος Φ6)
     (:file "components")          ; ΜΗΤΡΩΟ ΣΥΣΤΑΤΙΚΩΝ: ταυτότητες + γράφος ακμών — καθαρός πυρήνας
     (:file "institution")        ; ΤΟ ΙΔΡΥΜΑ: LAWMAX Legal Institution + θεσμικοί ρόλοι/αίθουσες (ο orchestrator = όργανο συντονισμού)
     (:file "contracts")          ; ΤΑ ΣΥΜΒΟΛΑΙΑ: μηχανικά ελέγξιμες υποσχέσεις των κρίσιμων λειτουργιών + επικυρωτής + προφίλ κενών
     (:file "self-model")
     (:file "component-scan")      ; ΣΑΡΩΤΗΣ: το μητρώο συστατικών χτίζεται από ASDF/εικόνα/sb-introspect + SHA-256 + επικυρωτής         ; ΤΟ ΖΩΝΤΑΝΟ ΑΥΤΟ-ΜΟΝΤΕΛΟ: ενδοσκόπηση MOP/εικόνας (όχι αφήγηση) + φραγμός ακροατηρίου (μόνο στον δημιουργό)
     (:file "provenance-link")     ; ΔΕΣΜΟΣ ΠΡΟΕΛΕΥΣΗΣ: ίχνη ⋈ συμβόλαια ⋈ συστατικά ⋈ αποδείξεις + επικυρωτής + trace-last-conclusion
     (:file "what-if")             ; ΠΡΟΤΑΣΗ ΑΛΛΑΓΗΣ (first-class) + WHAT-IF προσομοιωτής πάνω στα 5 στρώματα αυτοεπίγνωσης
     (:file "adoption-decision")   ; ΑΠΟΦΑΣΗ ΥΙΟΘΕΤΗΣΗΣ: δομημένη ετυμηγορία + υπογεγραμμένο ledger + ίχνος
     (:file "generation")         ; Η ΓΕΝΕΣΗ ΛΟΓΟΥ: κλιτικά παραδείγματα + συμφωνία + τελικό-ν — συνθέτει, δεν ανασύρει· ΕΝΑ λεξικό, δύο κατευθύνσεις
     (:file "autonomy")           ; Ο ΑΥΤΟΝΟΜΟΣ ΟΔΗΓΟΣ: αποστολή → βήμα-βήμα εκτέλεση με επαλήθευση → ουρά προτάσεων — ορατή σκέψη, ιστορική μαρτυρία
     (:file "knowledge-graph")    ; ΤΟ ΕΝΙΑΙΟ ΥΠΟΣΤΡΩΜΑ: σημασιολογικός meta-graph (CLOS/MOP) — προέλευση εκ κατασκευής + επίπεδα Self/World (anti-confusion)
     (:file "graph-reasoning")    ; Ο ΣΥΛΛΟΓΙΣΤΗΣ ΠΑΝΩ ΣΤΟΝ ΓΡΑΦΟ: explain (δέντρο απόδειξης) + impact (μεταβατική εξάρτηση) — ίδιος για νόμο & εαυτό

     (:file "anomaly-detection")  ; Intelligence: self-detection of extraction-error signatures
     (:file "legal-qa")           ; Intelligence: deterministic legal reasoning over the graph
     (:file "eu-interop-layer")   ; EUR-Lex / CELLAR integration (EU official legal data)
     (:file "canonical-representation") ; GATE-14: Deterministic serialization for JWS
     (:file "version-graph")      ; [0088] Φ2: διτεμπορικός γράφος εκδόσεων — text-version/amendment-edge/quarantined-edge, admit-edge!=replay-then-append, journal+chain-hash, version-at με recorded ΣΤΟ predicate
     (:file "legal-authority-receipt") ; [0088] Φ4: receipt-id = hash ΟΛΟΚΛΗΡΟΥ receipt (ταυτότητα+χρόνοι+γενεαλογία ΜΕΣΑ στη δέσμευση — PCL-01/PROV-01)
     (:file "legal-reasoning-bridge") ; BRAIN wiring: citation graph → engine facts + [0088 Φ5γ] grounded-impact με receipt-ids/διτεμπορική τομή (μετά τον γράφο/receipts — TRUST-01)
     (:file "validation-authority") ; GATE-5: Deterministic contract validation
     (:file "blockchain-authority") ; GATE-6: Pure Lisp blockchain anchoring (Ethereum/Arweave/IPFS)
     (:file "asn1-der")           ; Η ΜΙΑ έδρα ASN.1 DER (X.690): encoders + αυστηρός decoder + PEM↔DER
     (:file "jws-authority")      ; GATE-7: Pure Lisp JWS signing (RFC 7515)
     (:file "timestamp-authority") ; GATE-8: Pure Lisp RFC 3161 timestamps (multi-TSA)
     (:file "archive-authority")  ; GATE-8b: Archive.org 100-year proof
     (:file "x509-authority")     ; Pure Lisp X.509 certificate generation
     ;; CT Log removed: public CT logs require CA-issued certificates (not self-signed)
     (:file "proof-carrying")     ; Proof-Carrying Law: portable per-provision Merkle proof + verifier
     (:file "mcp-server")         ; MCP (JSON-RPC) server: AI agents ask → get law + citation + verifiable proof
     ;; Restored capabilities (never remove functionality) — depend on
     ;; uris/hash/jws/verify/write/time, all loaded above.
     (:file "semantic-authority")        ; Authority assertion RDF layer
     (:file "narrative-provenance")      ; Narrative provenance trail generator
     (:file "legal-audit-system")        ; W3C PROV-O audit trail
     (:file "semantic-versioning-system") ; Semantic version diffs (ELI/PROV-O)
     (:file "ai-citation-strategy")      ; AI citation tracking + reinforcement
     (:file "ai-ingest-manifest")        ; HuggingFace dataset / AI ingest manifest
     (:file "corpus-provenance")         ; PROV-O provenance (wires legal-audit to consolidation)
     (:file "corpus-eu-links")           ; National↔EU linking (CELEX/ELI/EUR-Lex, wires eu-interop)
     (:file "legal-id-registry")         ; Routes a discovered ΦΕΚ/law to the code it amends (autonomy brain)
     (:file "amendment-extractor" :depends-on ("legal-id-registry")) ; nomotechnic formulas -> ops (scope routing μέσω legal-id)
     (:file "static-site")               ; Cloudflare-Pages-ready static site generator (human + AI)
     (:file "review-queue")              ; CLOS/MOP human-in-the-loop review queue (approve/reject)
     (:file "review-service")            ; Web approval screen over the review queue (lawyer UI)
     (:file "source-profile")            ; Source authority: ranked acquisition channels + consensus

     ;; ════════════════════════════════════════════════════════════════════════
     ;; PDF 5-LAYER PIPELINE (NSA-GRADE TRACEABILITY)
     ;; ════════════════════════════════════════════════════════════════════════
     (:file "trace-core")         ; Layer 5: Trace structures & homoiconicity
     (:file "layout-types")       ; Layout structures: bbox, span, line, block, page
     (:file "validate-layout-graph") ; Layer 1 validation
     (:file "typographic-classifier") ; FSM-based typographic classification
     (:file "validate-logical-blocks") ; Layer 2 validation
     (:file "text-canonicalizer") ; Dehyphenation, normalization, Greek handling
     (:file "legal-ast")          ; Legal document AST with homoiconicity
     (:file "validate-ast")       ; Layer 4 validation
     (:file "ast-gate")           ; Intelligence: lift the served corpus into the legal-AST
                                  ; and run the (was-dead) Layer-4 validators over it
     ;; ════════════════════════════════════════════════════════════════════════

     (:file "pdf-authority")      ; GATE-13: Pure Lisp PDF via libpoppler CFFI
     (:file "embeddings-authority") ; GATE-10: Pure Lisp text embeddings
     (:file "signed-embedding-manifest") ; GATE-12: Signed embedding manifests with provenance
     (:file "rdfs-inference")     ; GATE-15: Pure Lisp RDFS inference engine
     (:file "reasoning-authority") ; Pure Lisp OWL 2 RL reasoner + ontology consistency (superset of RDFS)
     (:file "corpus-intelligence") ; CLOS/MOP suite: discovers + runs every analysis layer as one report
     (:file "sparql-endpoint")    ; GATE-16: Pure Lisp SPARQL query processor
     (:file "protocols")          ; Protocol definitions
     (:file "circuit-breaker")    ; Circuit breaker pattern
     (:file "injection")          ; Dependency injection
     (:file "session-handoff"))))) ; Session management
