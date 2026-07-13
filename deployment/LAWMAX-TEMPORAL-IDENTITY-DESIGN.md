# LAWMAX — ΤΕΛΙΚΟ ΣΧΕΔΙΟ ΥΛΟΠΟΙΗΣΗΣ: ΔΙΤΕΜΠΟΡΙΚΟΣ ΓΡΑΦΟΣ ΕΚΔΟΣΕΩΝ ΜΕ EVENT-TYPED ΠΥΡΗΝΑ
## Φάση Temporal/Identity — Authority Publisher — Σύνθεση των τριών σχεδίων

**Βάση**: `version-graph` (77/81, το ισχυρότερο απόλυτο προφίλ, fatal=false, serious=∅).
**Μπολιάσματα**: από `event-ledger` (76/81): ο ξεχωριστός quarantined ΤΥΠΟΣ αόρατος στο trusted fold, το `op-retract-knowledge` ως μοναδικός μηχανισμός γνωσιακής ανάκλησης, το `op-restate` για τη δημοτική 1986, το chain-hash ανά γραμμή με consistency proof διαδοχικών roots, ο ολικός κανόνας διάταξης εφαρμογής. Από `frbr-registry` (72/81): η διάκριση wId/eId (work-level vs expression-level ταυτότητα) που κάνει τις μαζικές αναριθμήσεις αναπαραστάσιμες χωρίς lineage hacks, οι FRBR/ELI προβολές ανά επίπεδο, το double-entry transcription μονοπάτι για τα σαρωμένα ΦΕΚ.
**Κανόνας σύνθεσης**: κανένας κριτής δεν έδωσε SERIOUS/WRONG σε κανένα σχέδιο· επομένως η βάση κρατιέται ακέραιη και ΟΛΑ τα MINOR (και των τριών σχεδίων) θεραπεύονται ρητά στην §3 — κανένα δεν αφήνεται σιωπηλό· ό,τι δεν θεραπεύεται πλήρως δηλώνεται ως υπόλειμμα με φάση θανάτου στην §9.

**Έλεγχος υπέρτατου νόμου**: Υπάρχει αυστηρά ανώτερη σύλληψη; Ναι, μία: provenance επιπέδου χαρακτήρα (κάθε χαρακτήρας κάθε έκδοσης → span ΦΕΚ). Καταγράφεται ως Φάση Θ (μετά το M6)· προϋποθέτει τον παρόντα γράφο ως υπόστρωμα — είναι εκλέπτυνσή του, όχι εναλλακτική. Δεύτερη δηλωμένη ανώτερη επέκταση: typed effectivity conditions (αιρέσεις ισχύος «με έκδοση ΠΔ») ως πρώτης τάξης lifecycle αντικείμενα — Φάση Ι. Καμία από τις δύο δεν παραδίδεται τώρα· και οι δύο έχουν έδρα καταγραφής στο dialogue αρχείο της φάσης.

---

## 1. ΟΙ ΕΔΡΕΣ — typed αντικείμενα, slots, invariants

### 1.0 Canonical serialization — έδρα: `source/canonical-representation.lisp` (υπάρχουσα, επεκτείνεται — ΟΧΙ νέα)

Η ΜΟΝΑΔΙΚΗ έδρα σειριοποίησης-προς-hash για ΟΛΟ το σύστημα (θεραπεία του «απροσδιόριστου canonical spec» των κριτών):
- Μορφή: deterministic JSON — sorted keys, NFC, LF, χωρίς floats, ρητά type tags, δηλωμένα διαχωριστικά 0x1F για συνθέσεις hash.
- Δημοσιευμένο spec αρχείο `deployment/verify/canonical-serialization-spec.md` + test vectors στο `deployment/verify/vectors/` — ο εξωτερικός verifier (`verify.py`/`verify.mjs`, υπάρχουν ήδη) υλοποιεί το spec ανεξάρτητα (δεύτερη γλώσσα).
- Κάθε `*-id` hash του συστήματος (version-hash, edge-id, receipt-id, derivation-id, graph-root) = sha256 αυτής και μόνο αυτής της σειριοποίησης.

### 1.1 Ταυτότητα — έδρα: `source/canonical-article-id.lisp` → **μετασχηματίζεται** σε `source/legal-identity.lisp`, package `orchestrator.identity`

Απορροφά την S2 οικογένεια του `systems/orchestrator-model/article.lisp:165-282` (suffix-ordinal, νομοθετική ακολουθία Α..ΣΤ..Ι,ΙΑ..ΠΘ, μόνο κεφαλαία ελληνικά, απόρριψη λατινικών homoglyphs με έλεγχο κωδικοσημείου). Η χαλαρότητα του S5 (`%canon-suffix` :44-48 — «ΒΙΣ», πεζά, λατινικά) **πεθαίνει**. Το sxhash-λίστας (:98-102) **πεθαίνει**.

```lisp
(defstruct legal-body-id
  (jurisdiction :gr)      ; keyword, fail-closed constructor
  kind                    ; keyword από ΜΗΤΡΩΟ (§ κάτω), όχι hardcoded σύνολο
  year number             ; nil μόνο για :syntagma
  slug)                   ; display-only, ποτέ κλειδί
;; ΘΕΡΑΠΕΙΑ (frbr MINOR «στενό doctype»): το kind δεν είναι κλειστό enum στον κώδικα·
;; είναι εγγραφή στο data-μητρώο deployment/data/body-kind-registry.sexp
;; (αρχικό: :syntagma :kodikas :nomos :nd :an :pd :ya :psifisma :eu-reg :eu-dir),
;; επεκτάσιμο ΜΟΝΟ με receipt + έγκριση δημιουργού — όχι code change, όχι ελεύθερο string.

;; Path segments — ΘΕΡΑΠΕΙΑ (event-ledger MINOR «κωδικοποίηση γραμμάτων/παρ. 4α»):
;; (:article   base suffix-ord)   base (integer 1 9999), suffix-ord (integer 0 89)
;; (:paragraph base suffix-ord)   base = ΝΟΜΙΚΟΣ αριθμός· suffix-ord για εισαχθείσες «4α»
;;                                — η ΙΔΙΑ έδρα ordinal (letter↔ordinal bijection,
;;                                μία συνάρτηση suffix-ordinal/ordinal-suffix) για ΟΛΑ τα kinds
;; (:point  letter-ord)           η περίπτωση «β» ως ordinal της ΠΕΖΗΣ ελληνικής ακολουθίας
;;                                α,β,γ,δ,ε,στ,ζ..— δεύτερη δηλωμένη ακολουθία στην ΙΔΙΑ έδρα
;; (:edafio n)                    ΜΟΝΟ όταν το κείμενο αριθμεί ρητά· αναρίθμητα εδάφια/
;;                                παράγραφοι ΔΕΝ αποκτούν sub-identity (τίμια άγνοια)·
;;                                ops που τα στοχεύουν ⇒ unresolved-amendment, ποτέ θεσιακό index.

(defstruct provision-id            ; = AKN wId: work-level, επιβιώνει renumber ΩΣ ΝΗΜΑ
  body                             ; legal-body-id — ΥΠΟΧΡΕΩΤΙΚΟ, συμμετέχει στην ισότητα
  path)                            ; vector segments — Η ΤΡΕΧΟΥΣΑ θέση του νήματος

;; lineage-id: sha256 του ΠΡΩΤΟΥ provision-id-string του νήματος + genesis edge-id.
;; renumber ΔΕΝ αλλάζει lineage-id — αλλάζει το path (eId-επίπεδο). Lineage merge/split
;; κρίσεις = ανθρώπινη είσοδος με attestation record, ποτέ αλγοριθμική εικασία.
```

**Invariants**: ισότητα/hash/ordering ΜΟΝΟ μέσω `provision-id-string` (`gr/syntagma#art:110Α/par:3/point:β`), `equal` tables. Ο συνθετικός base*1000+ordinal **παύει να είναι ταυτότητα** (μένει on-demand `provision-order-key` για ταξινόμηση). Καθαρές προβολές στην ίδια έδρα: `eid<-provision-id` (`art_110Α__para_3`), `manifestation-filename` (padded `article-110Α`, ONE-WAY, δεν parse-άρεται ποτέ πίσω), `uri<-provision-id`, `frbr-work-uri`, `frbr-expression-uri (id valid-from)` → `{work}/el@{valid-from}`. Ο **μοναδικός parser**: `parse-provision-designator` — τον καλούν adapters, legal-ast, citation-authority, bridge.

### 1.2 Γράφος εκδόσεων — έδρα: `source/consolidation-engine.lisp` **μετασχηματίζεται** σε `source/version-graph.lisp` (git mv — ίδια έδρα, νέα ουσία)

```lisp
(deftype legal-date () '(and string (satisfies iso-date-string-p)))  ; ΔΕΝ χωράει NIL

(defstruct text-version               ; ΚΟΜΒΟΣ — αμετάβλητος
  version-hash                        ; sha256 canonical σειριοποίησης (§1.0)
  provision-id lineage-id
  text heading                        ; NFC canonical, immutable
  valid-from                          ; legal-date — ΥΠΟΧΡΕΩΤΙΚΟ ΣΤΟΝ ΤΥΠΟ
  valid-until                         ; legal-date | :open
  recorded-from                       ; journal receipt timestamp — ΥΠΟΧΡΕΩΤΙΚΟ
  recorded-until                      ; timestamp | :current — κλείνει ΜΟΝΟ retract/supersession
  status                              ; :in-force :repealed :not-yet-effective :suspended
  previous-version-hash               ; sha256 | :genesis
  created-by                          ; edge-id | (:base derivation-id)
  assurance)                          ; :verified :extracted-verified :attested-manual
                                      ; :reconstructed :legacy-unverifiable

(defstruct amendment-edge             ; ΑΚΜΗ — τυποποιημένη πράξη, text-bearing
  edge-id
  op                                  ; :insert :delete :replace :replace-heading :renumber
                                      ; :split :merge :repeal :restore :correct :restate
                                      ; :retract-knowledge          ← μπόλι event-ledger
  from-versions to-versions           ; version-hashes — before/after ΔΕΣΜΕΥΜΕΝΑ στην ακμή
  target                              ; provision-id (+ to-ids για renumber/split/merge)
  act-ref                             ; act-node id
  act-internal-seq                    ; (άρθρο, σειρά) της τροποποιητικής διάταξης ΜΕΣΑ στην πράξη
                                      ; ← ΘΕΡΑΠΕΙΑ tie-break MINOR: ΥΠΟΧΡΕΩΤΙΚΟ slot
  corrects-edge-id                    ; μόνο για :correct — ρητή τοπολογική εξάρτηση
  source-span                         ; {artifact-digest, page, char-start, char-end}
  enacted effective                   ; legal-date — ΥΠΟΧΡΕΩΤΙΚΑ ΣΤΟΝ ΤΥΠΟ (όχι :unknown εδώ!)
  recorded-from recorded-until
  assurance confidence)

(defstruct quarantined-edge           ; ← μπόλι event-ledger: ΑΛΛΟΣ ΤΥΠΟΣ, όχι σημαία
  ...ίδια slots αλλά effective (or legal-date null)...
  reason)                             ; :unknown-effective :unknown-text
                                      ; :conflicted-before-hash :low-confidence :unresolved-target
;; Ο τύπος του trusted γράφου = συλλογές amendment-edge. Το quarantined-edge είναι
;; ΔΟΜΙΚΑ αόρατο στην επιλογή έκδοσης — ο compiler αποκλείει τη διαρροή, όχι guard.
;; Το σημερινό :mark-amended και κάθε text-less amendment record γίνεται quarantined-edge
;; :unknown-text + knowledge-gap. Η κλάση σφάλματος TEMP-02 ΕΞΑΛΕΙΦΕΤΑΙ, δεν φρουρείται.

(defstruct act-node                   ; τροποποιητική πράξη ως απόδειξη — ΔΕΝ συμμετέχει
  body-id fek                         ; στην επιλογή έκδοσης· μόνο οι ακμές
  publication-artifact enacted effective-default recorded)

(defstruct knowledge-gap              ; τίμια άγνοια πρώτης τάξης
  provision-id act-ref kind effective recorded-from)
```

**Δομικοί invariants (στην έδρα, όχι στους callers):**
- **G1 (admit-edge! = replay-then-append)**: ακμή γίνεται δεκτή ΜΟΝΟ αν κάθε from-version-hash υπάρχει ΚΑΙ η εκτέλεση του op πάνω στα from-texts παράγει ακριβώς τα to-version-hashes. Αποτυχία ⇒ quarantined-edge `:conflicted-before-hash`, ποτέ σιωπηλή εφαρμογή.
- **G2 (ολική διάταξη εφαρμογής — θεραπεία tie-break MINOR)**: `(effective, fek-date, act-internal-seq, edge-id)` — η νομική σειρά των άρθρων της πράξης ΣΥΜΜΕΤΕΧΕΙ στο κλειδί. `:correct` εφαρμόζεται τοπολογικά ΜΕΤΑ το `corrects-edge-id` του, ανεξαρτήτως valid-from (που είναι το αναδρομικό της διορθούμενης). Το NIL δεν υπάρχει στον τύπο, άρα δεν ταξινομείται.
- **G3 (append-only journal με αλυσίδα)**: `deployment/data/version-graph/<body>.vgraph.jsonl` μέσω υποδομής [0086] (`journal:append-line` + Persistence Receipt). Κάθε γραμμή: `chain-hash_n = sha256(chain-hash_{n-1} || record-id)`. `recorded-from` = το `:at` του journal receipt — μία πηγή transaction time, ΠΟΤΕ η deterministic-time έδρα.
- **G4 (renumber/split/merge)**: κανένα target collision με ζωντανό path χωρίς προηγούμενο repeal/renumber· lineage-id διατηρείται στο renumber, m:n genealogy edges στα split/merge.
- **G5 (retract-knowledge)**: ΜΟΝΑΔΙΚΟΣ τρόπος «διαγραφής» — κλείνει recorded-until του στόχου με νέα append γραμμή. Ο γράφος δεν ξαναγράφεται ποτέ.
- **G6 (σφράγιση μεταξύ cuts — θεραπεία «παραχαράξιμο journal» MINOR)**: αυτόματο seal κάθε 24h Ή κάθε 256 appends (ό,τι πρώτο): τρέχον chain-hash + πλήθος → TSA (RFC3161) + append στο τοπικό tlog ως interim-seal leaf. Κάθε release cut: υποχρεωτικό **consistency proof** ότι ο προηγούμενος graph-root είναι prefix του νέου (RFC-6962 consistency, υπάρχουσα έδρα `orchestrator.merkle`). Η παραχάραξη πριν το πρώτο seal παραμένει φυσικά δυνατή — δηλωμένο υπόλειμμα §9.4, παράθυρο ≤24h.

### 1.3 Διτεμπορικά ερωτήματα — ίδια έδρα, μοναδικό query API

```lisp
(version-at graph pid &key valid-at known-at)
;; Φίλτρο 1: recorded-from ≤ known-at < recorded-until   ← ΤΟ RECORDED ΣΥΜΜΕΤΕΧΕΙ
;; Φίλτρο 2: valid-from ≤ valid-at < valid-until
;; known-at ΧΩΡΙΣ σιωπηλό default στο serving path — ο caller δηλώνει release-generation ή τιμή.
;; Επιστρέφει (values version basis) με basis ∈ {:complete :reconstructed-tt} Ή condition:
;;   temporal-uncertainty      — knowledge-gap/quarantined-edge τέμνει την τομή
;;   incomplete-reconstruction — σπασμένη αλυσίδα from-versions
;;   unknown-provision
;; ΘΕΡΑΠΕΙΑ (version-graph MINOR «reconstructed recorded»): αν η επιλογή εξαρτάται από
;; record με σημαία :reconstructed-transaction-time, basis = :reconstructed-tt —
;; ο verifier και το HTTP layer το εκθέτουν ΠΑΝΤΑ, ποτέ σιωπηλό :complete.

(snapshot-at graph &key valid-at known-at)   ; ολόκληρο σώμα + snapshot-certificate
(text-in-force-at pid valid-at)              ; = version-at με known-at = :now-of-release
(text-as-known pid valid-at known-at)        ; «τι ήξερε το LAWMAX την Υ για την Χ» + HTTP endpoint
```

`corpus-service.lisp:187`: το handler-case fallback στο τρέχον **διαγράφεται** — αποτυχία as-of ⇒ HTTP 422/409 με typed reason + certificate.

**Snapshot-manifest + fold-proof** (μπόλι event-ledger): `{body, valid-at, known-at, (pid . version-hash)*, graph-root, per-step λίστα (edge-id before after), quarantine-set ΡΗΤΑ}`. Verify = ανεξάρτητο replay από το ΣΕΙΡΙΟΠΟΙΗΜΕΝΟ journal στον δίσκο, per-step σύγκριση (όχι count), από τον L6 kernel (`deployment/verify/kernel-verify.lisp`) ΚΑΙ από `verify.py` — «δύο υλοποιήσεις, ίδια ετυμηγορία».

### 1.4 Hermetic derivation — έδρα: `source/corpus-provenance.lisp` **μετασχηματίζεται** (ενοποιεί `%write-source-provenance` + acquisition)

```lisp
(defstruct source-artifact
  sha256 byte-length kind fek
  acquisition)          ; {channel, authority-rank, url, fetched-at, record-content-hash}
                        ; ← AUTH-02: η αυθεντία ΜΕΣΑ στο τεκμήριο, ρέει ως το receipt

(defstruct divergence-record            ; μπόλι event-ledger — δύο κανάλια διαφωνούν
  artifacts classification)             ; :agreed :authority-override :conflicted
;; Το consensus API ΔΕΝ επιστρέφει artifact χωρίς divergence-record· :conflicted ⇒
;; quarantine εξαρτώμενων ακμών. unclassified_divergences=0 δομικά.

(defstruct extraction-derivation
  derivation-id                         ; sha256(artifact ‖ extractor-root ‖ config-digest)
  artifact-digest
  extractor-root                        ; MTH των sha256 των πηγών του pinned extractor
                                        ; (extractor-manifest.sexp στο build) — ΟΧΙ free string
  config-digest                         ; canonicalized YAML υπο-δέντρο
  outputs)                              ; (provision-id-string content-sha256 source-span)*
```

**Gate `verify-derivation` — ΘΕΡΑΠΕΙΑ των MINOR «δειγματοληψία» + «υπό όρους βήμα 4»:**
- Η απόδειξη είναι **content-addressed στην τριάδα** `(artifact-digest, extractor-root, config-digest)`: κάθε ΝΕΑ τριάδα επανεκτελείται ΠΛΗΡΩΣ (pinned extractor πάνω στα source bytes, φρέσκια διεργασία, owner docker) στο release που την εισάγει, και η απόδειξη γίνεται η ίδια receipt-αρισμένο artifact. Αμετάβλητη τριάδα = ήδη αποδεδειγμένη, δεν ξανατρέχει. **Καμία δειγματοληψία, κανένα «δείγμα-πλήρες»** — πλήρης κάλυψη με πεπερασμένο κόστος.
- Typed αποτέλεσμα verify-receipt: `verification-verdict ∈ {:verified-full, :verified-no-source, :failed}`. `:verified-no-source` ΜΟΝΟ όταν το artifact είναι δηλωμένα `:attested-manual`/`:legacy-unverifiable`, και ΚΑΤΕΒΑΖΕΙ το assurance όλης της γενεαλογίας — ποτέ σιωπηλό PASS. Απόντα bytes για artifact που ΟΦΕΙΛΕ να υπάρχει ⇒ `:failed`.
- ΟΥΔΕΠΟΤΕ digest πάνω στην ήδη παραχθείσα λίστα (kill ANCHOR-01)· το `anchor-assert` του `primary-anchor.lisp` αντικαθίσταται.

`preserved-no-digital-source`/`preserved-shrink-guard` (main.lisp:1142,1157): **παύουν να σφραγίζουν :valid** — παράγουν assurance `:attested-manual` με υποχρεωτικό υπογεγραμμένο attestation record δημιουργού, που κληρονομείται σε κάθε παράγωγο.

### 1.5 LegalAuthorityReceipt — έδρα: `source/proof-carrying.lisp` **μετασχηματίζεται** σε `source/legal-authority-receipt.lisp`

```lisp
(defstruct legal-authority-receipt
  receipt-id                  ; sha256 canonical receipt bytes (§1.0)
  canonical-legal-id          ; provision-id-string + lineage-id + expression (valid-from)
  source-artifact             ; digest+fek+acquisition (channel, rank, fetched-at)
  extraction-derivation-id
  valid-from valid-until recorded-from recorded-until
  amendment-genealogy         ; ΠΛΗΡΗΣ λίστα edge-ids genesis→παρούσα, όχι last-touch
  content-hash previous-version-hash
  proof-root                  ; Merkle path → receipt-set root → release root
  release-generation          ; {era 2, seq n}
  assurance-level
  trust-status)               ; :signed | :unsigned-explicit — ποτέ σιωπηλό
```

- **Leaf = hash ΤΩΝ RECEIPT BYTES** (κλείνει PCL-01) — ταυτότητα/χρόνοι/γενεαλογία/authority μέσα στη Merkle δέσμευση.
- **Μία ρίζα** (κλείνει PCL-02): receipt-set-root + graph-root ΜΕΣΑ στο canonical set → release root → TSR → tlog. Το `pcl_text_root` πεθαίνει· cross-check στο spine verify.
- `verify-receipt` (kernel + python, δύο υλοποιήσεις): receipt-id recompute → merkle path → release root → TSR → tlog → genealogy replay edge-προς-edge → content-hash → previous-hash αλυσίδα → derivation verdict (§1.4 typed). Αποτυχία οπουδήποτε ⇒ FAIL.
- `sign-root` **fail-closed**: απόν υλικό ⇒ ERROR exit≠0. Διαγράφονται: `(values nil nil)` (main.lisp:1741,1750-1752), `(error () nil)` (:1794), `ignore-errors` (proof-carrying.lisp:151). Μόνο ρητό `--unsigned-dev` γράφει trust-status `:unsigned-explicit` που η `promote-latest!` ΑΡΝΕΙΤΑΙ να προάγει.

### 1.6 Grounded reasoning — `source/legal-reasoning-bridge.lisp` μετασχηματίζεται

Κάθε premise ΑΠΑΙΤΕΙ `{receipt-id, content-hash, valid-at, known-at, authority-rank}`· `reason-impact` δέχεται διτεμπορική τομή και τρέφεται από `version-at`, όχι από γυμνό citation graph· proof leaves φέρουν receipt-ids που ο verifier επιλύει έναντι του receipt set (κλείνει TRUST-01).

---

## 2. ΧΩΡΟΘΕΤΗΣΗ — ονομαστικός πίνακας τύχης ΚΑΘΕ έδρας

| Υπάρχον | Τύχη |
|---|---|
| `source/canonical-article-id.lisp` | ΜΕΤΑΣΧΗΜΑΤΙΖΕΤΑΙ → `source/legal-identity.lisp`· lax parsing + sxhash-λίστας πεθαίνουν |
| `systems/orchestrator-model/article.lisp:165-282` | Suffix/pad/uri/file-id ΜΕΤΑΚΟΜΙΖΟΥΝ στην identity έδρα· slots number(synthetic)/label διαγράφονται· νέο slot `identity`· adapter-readers με θάνατο Φ6 |
| `systems/orchestrator-model/corpus.lisp:25-114` | Rekey σε `equal`/provision-id-string· integer `get-article` = proven adapter, θάνατος Φ6 |
| Adapters json/pdf/html/raw | base*1000 αριθμητική διαγράφεται· όλοι καλούν `parse-provision-designator` |
| `source/consolidation-engine.lisp` | ΜΕΤΑΣΧΗΜΑΤΙΖΕΤΑΙ → `source/version-graph.lisp`· mutable `apply-operation`/`stamp-provenance`/`:replace-text`(:305-311)/`:mark-amended`/NIL-tolerant `act-order-key`(:394,:408) πεθαίνουν |
| `source/legal-temporal.lisp` | ΔΙΑΓΡΑΦΕΤΑΙ· interval άλγεβρα μετακομίζει στο version-graph |
| `source/eli-temporal-metadata.lisp` | ΔΙΑΓΡΑΦΕΤΑΙ ως έδρα· TTL = καθαρή προβολή· πεθαίνουν `*amendments-config*`(:46), defaults 1975(:149,:224), fail-open `is-article-in-force`(:112-128), φίλτρο "date"(:171-173) |
| `source/consolidation-bridge.lisp` | ΜΕΤΑΣΧΗΜΑΤΙΖΕΤΑΙ σε importer records→edges/gaps· πεθαίνουν `(or date_applicability date)`(:127), θεσιακό `paragraph-eid`(:79-83), deterministic recorded(:133-140), `:if-missing :skip` |
| `source/consolidation-proof.lisp` | ΑΝΤΙΚΑΘΙΣΤΑΤΑΙ από chain-hash+fold-proof· count-verify(:122) και in-process self-replay πεθαίνουν |
| `source/proof-carrying.lisp` | ΜΕΤΑΣΧΗΜΑΤΙΖΕΤΑΙ → `legal-authority-receipt.lisp` |
| `source/corpus-provenance.lisp` + `%write-source-provenance` (main.lisp:1055-1173) | Ενοποίηση σε source-artifact/derivation· free string `extraction_method` πεθαίνει |
| `source/source-profile.lisp` | Acquisition ρέει στο source-artifact· MOP ιεραρχία = έδρα ranks (prior)· + divergence-record |
| `source/citation-authority.lisp:96-134` | Κόμβοι provision-id-string, ΙΔΙΑ φάση (όχι τρίτη έδρα)· fixnum declare πεθαίνει |
| `source/legal-ast.lisp:1137-1140` | Regex πεζών διαγράφεται → καλεί τον parser· ast-id ρητά εφήμερο |
| `source/corpus-service.lisp:187` | Fallback ΔΙΑΓΡΑΦΕΤΑΙ → typed 422/409 |
| `systems/orchestrator-epistemic/primary-anchor.lisp` | `anchor-assert` αντικαθίσταται από verify-derivation |
| `main.lisp:1739-1850` | Fail-closed ξαναγράφεται πάνω στα receipts |
| `stages/consolidate.lisp:90-92`, `generate-rdf.lisp:55`, `akoma-ntoso-emitter.lisp` | FRBR ανά επίπεδο: Work=ίδρυση, Expression=valid-from, Manifestation=generation· default «1970-01-01»(:190) πεθαίνει |
| `configs/*.yaml versioning.amendments` | Bootstrap import πηγή μία φορά με import receipt· μετά frozen-legacy |
| `amendment-extractor.lisp` / review-queue | Παράγει typed candidate edges με derivation+span· approve = admit-edge! με `:extracted-verified`· low-confidence μένει στο queue |
| `artifact-census.lisp`, `release-spine.lisp`, `deploy-epistemic.lisp`, `transparency-log.lisp` | Canonical set += graph-root, receipt-set-root, snapshot-manifests· era-2 bump· 71-char checks γίνονται era-aware ΜΙΑ φορά |
| ΝΕΑ αρχεία | ΜΟΝΟ `source/legal-authority-receipt.lisp` (νέα έννοια) + `deployment/data/body-kind-registry.sexp` + spec/vectors. Τίποτα άλλο νέο — κανένα παράλληλο σύστημα |

---

## 3. ΘΕΡΑΠΕΙΑ ΟΛΩΝ ΤΩΝ ΕΥΡΗΜΑΤΩΝ ΤΩΝ ΚΡΙΤΩΝ (κανένα SERIOUS/WRONG δεν υπήρξε· όλα τα MINOR κλείνουν)

| # | Εύρημα κριτή (σχέδιο) | Διευθέτηση στη σύνθεση |
|---|---|---|
| 1 | Κωδικοποίηση περιπτώσεων-γραμμάτων σε integer base· παρ. «4α» (event-ledger, κρ.2) | ΘΕΡΑΠΕΙΑ §1.1: `:point letter-ord` με δεύτερη δηλωμένη πεζή ακολουθία στην ίδια ordinal έδρα· `:paragraph base suffix-ord` για εισαχθείσες παραγράφους |
| 2 | verify-derivation δειγματοληπτικό + υπό όρους βήμα 4 χωρίς typed αποτέλεσμα (event-ledger, κρ.6) | ΘΕΡΑΠΕΙΑ §1.4: content-addressed τριάδα = πλήρης κάλυψη χωρίς δειγματοληψία· typed verdict `:verified-full/:verified-no-source/:failed` |
| 3 | Tie-break event-id νομικά αυθαίρετο· θέση op-correct αόριστη (event-ledger, κρ.8) | ΘΕΡΑΠΕΙΑ §1.2 G2: `act-internal-seq` υποχρεωτικό slot στο κλειδί· `:correct` τοπολογικά μετά το `corrects-edge-id` |
| 4 | Χωρίς consistency proof διαδοχικών roots· journal παραχαράξιμο μεταξύ cuts (event-ledger κρ.3 / version-graph κρ.3) | ΘΕΡΑΠΕΙΑ §1.2 G6: interim-seals 24h/256-append με TSA+tlog + υποχρεωτικό RFC-6962 consistency proof ανά cut· υπόλειμμα ≤24h παράθυρο δηλωμένο §9.4 |
| 5 | OCR/ερμητικότητα σαρωμένων πολυτονικών ΦΕΚ 1975 υποεκτιμημένο (και τα 3 σχέδια) | ΘΕΡΑΠΕΙΑ §6: ρητό μονοπάτι double-entry transcription (frbr) → transcription artifact με digest + attestation ⇒ genesis assurance `:attested-manual`, ποτέ ψευδώς `:verified`· το benchmark παραμένει έγκυρο με δηλωμένο assurance |
| 6 | Canonical serialization spec απροσδιόριστο (event-ledger, overall) | ΘΕΡΑΠΕΙΑ §1.0: μία έδρα, δημοσιευμένο spec, test vectors, ανεξάρτητη υλοποίηση στον python verifier |
| 7 | clean.json + γράφος συνυπάρχουν M2–M5 χωρίς gate ισοδυναμίας (version-graph, κρ.1) | ΘΕΡΑΠΕΙΑ: parity gate σε ΚΑΘΕ cut μέχρι Φ6: `snapshot-at(now, release-known)` ≡ clean.json byte-identical ανά άρθρο, counter=0 ή enumerated+classified |
| 8 | Reconstructed recorded-from χωρίς κανόνα υποβάθμισης στον verifier (version-graph, κρ.3) | ΘΕΡΑΠΕΙΑ §1.3: basis `:reconstructed-tt` υποχρεωτικά ορατό σε κάθε απάντηση/receipt που εξαρτάται από τέτοιο record |
| 9 | Κλειστό doctype στενό· εδάφια αναρίθμητα (frbr, κρ.2) | ΘΕΡΑΠΕΙΑ §1.1: data-μητρώο kinds με receipt+έγκριση· αναρίθμητα ⇒ καμία sub-identity, ops ⇒ unresolved |
| 10 | Χωρίς εξωτερική αγκύρωση πριν τη δημοσίευση (frbr, κρ.3) | ΜΕΡΙΚΗ ΘΕΡΑΠΕΙΑ G6 (TSA interim-seals)· το προ-πρώτου-seal παράθυρο = εγγενές όριο, δηλωμένο §9.4 — ΑΝΑΣΚΕΥΗ πλήρους λύσης: κανένα σύστημα δεν αποδεικνύει το παρελθόν πριν την πρώτη του αγκύρωση |
| 11 | Standalone third-party verifier απροδιαγράφητος (frbr, κρ.6) | ΘΕΡΑΠΕΙΑ: `deployment/verify/verify.py`/`verify.mjs` (υπάρχουν) επεκτείνονται era-2: receipt bytes + spec §1.0 επαληθεύσιμα χωρίς lisp toolchain· το verify-derivation (που θέλει τον extractor) μένει lisp-bound — δηλωμένο υπόλειμμα §9.5 |
| 12 | NFC κανονικοποίηση legacy clean.json χωρίς test vector· οριοθέτηση bit-reproducible vs real-time (frbr κρ.8, version-graph κρ.8) | ΘΕΡΑΠΕΙΑ Φ3: NFC vectors στο M2 import receipt + **πίνακας αναπαραγωγιμότητας** στο spec: bit-reproducible = {version-hashes, edge-ids, derivations, receipts πλην recorded, manifests, roots}· event-time = {recorded-*, fetched-at, TSR} — το deterministic-build gate ελέγχει ΜΟΝΟ το πρώτο σύνολο |
| 13 | Benchmark εξαρτάται από 8 εκτός-repo τεκμήρια (frbr/version-graph, κρ.5) | ΔΗΛΩΜΕΝΟ — δεν θεραπεύεται με σχεδίαση· §6 ονοματίζει τις πηγές και το benchmark μένει `:incomplete` μέχρι την κτήση τους, ποτέ ψευδώς verified |

---

## 4. ΣΕΙΡΑ ΥΛΟΠΟΙΗΣΗΣ — φάσεις με ελέγξιμο proof (κάθε φάση: plan → έγκριση δημιουργού → υλοποίηση → εσωτερική αντιπαλική επιθεώρηση → proof με αριθμούς → owner docker → ρητό merge)

**Φ0 — Era-1 seal.** Πλήρες release cut με το τρέχον σύστημα· root+TSR+tlog = era-1-seal. Τίποτα παλιό δεν ξαναγράφεται. *Proof*: verify του cut, tlog consistency OK.

**Φ1 — Canonical serialization + Identity.** §1.0 spec+vectors· `legal-identity.lisp`· rekey corpus· citation-authority· legal-ast· adapters· regen conformance vectors ㉕㉗ ΣΤΗΝ ΙΔΙΑ φάση. *Proof*: exhaustive bijection όλων των (number,label) των 6 σωμάτων old↔new, **0 διαφωνίες**· round-trip proof αποθηκευμένων `:target` eid strings (φορτώνονται μέσω parser, ΔΕΝ ξαναγράφονται)· duplicate_identity_seats=0 (μητρώο εδρών + grep gate)· python verifier περνά τα serialization vectors.

**Φ2 — Version-graph έδρα.** Τύποι §1.2-1.3, admit-edge!, journal+chain-hash, interim-seal μηχανισμός, version-at/snapshot-at, typed conditions. *Proof*: unit gates σε G1-G6 (κατασκευή NIL-effective ακμής = compile/construct error· conflicted before-hash ⇒ quarantine· retract διατηρεί as-known)· consistency proof δύο διαδοχικών roots.

**Φ3 — Import (M2/M3 του migration §5).** Bridge→importer· 6 σώματα genesis· constitution amendments ως quarantined+gaps· NFC vectors. *Proof*: **fold-parity gate**: `snapshot-at(today)` byte-identical με τρέχοντα consolidated outputs και για τα 6 σώματα — κάθε απόκλιση enumerated+classified, unclassified_divergences=0· clean.json parity gate ενεργό.

**Φ4 — Derivation + Receipts + era-2 release.** §1.4-1.5, fail-closed signing, canonical set += roots, era-aware format checks ΜΙΑ φορά, tests-at-risk μεταναστεύουν στο ίδιο commit. *Proof*: verify-receipt ΟΛΩΝ των άρθρων = 0 failures (δύο υλοποιήσεις)· verify-derivation `:verified-full` για κάθε νέα τριάδα· sign-root χωρίς κλειδιά ⇒ exit≠0 (test)· tlog consistency era-1→era-2 αδιάσπαστη.

**Φ5 — Cutover εκπομπών + serving + reasoning.** Emitters/TTL/AKN/FRBR από snapshot-at· text-as-known endpoint· reasoning premises με receipts· διαγραφή corpus-service:187. *Proof*: transaction_time_query_failures=0 σε conformance ζεύγη (Χ,Υ)· grep-gate silent_fallbacks=0 στα 6 ονομαστικά σημεία.

**Φ6 — Θάνατοι adapters.** Integer get-article, article-number/label readers, prov-stamp προβολή, eli-temporal-metadata, legal-temporal — καθένας κατά [0045] με grep-gate **0 καταναλωτών** πριν τη διαγραφή· clean.json υποβιβάζεται σε sealed source artifact (parity gate αποσύρεται μαζί του).

**Φ7 — Σύνταγμα-benchmark** (§6) — ξεχωριστή φάση, δική της έγκριση, γιατί εξαρτάται από κτήση πηγών.

---

## 5. MIGRATION PLAN — χωρίς απώλεια

- **M0** = Φ0. Era-1 releases: `trust-status :legacy-sealed`, era-versioned verifier, το πρώτο era-2 census δεσμεύει `prev_release_root` — η tlog αλυσίδα συνεχίζεται, δεν σπάει.
- **M1** = Φ1. Μηχανικά αναπαραγώγιμη μετάφραση ταυτοτήτων με 0-αποτυχίες gate· migration receipt με before/after hashes του ίδιου του migration.
- **M2** (μέσα στη Φ3): clean.json → genesis text-versions: valid-from = per-article `date` (dd/MM/yyyy→ISO), recorded-from = πραγματικός χρόνος import από journal receipt με σημαία `bootstrap:true`, origin = derivation από .prov.json· απόν source_digest ⇒ `:legacy-unverifiable`, ΠΟΤΕ :verified. Τα clean.json+prov.json σφραγίζονται για πάντα by digest — καμία απώλεια bytes. **Δηλωμένο**: transaction time προ-migration δεν κατασκευάζεται· «τι ήξερε το LAWMAX το 2025» ⇒ typed «προ-εποχής μητρώου».
- **M3** (μέσα στη Φ3): 4 constitution records → act-nodes + quarantined-edges `:unknown-text` + knowledge-gaps. Συνέπεια, ρητά ΟΡΘΗ: as-of Συντάγματος σε τομές προ-2019 ⇒ `temporal-uncertainty` μέχρι τη Φ7 — πρώτη φορά που το σύστημα λέει αλήθεια γι' αυτό. Legacy recorded best-effort από git history ⇒ σημαία `:reconstructed-transaction-time` με τον κανόνα υποβάθμισης §1.3.
- **M4** = Φ4-Φ5. **M5** = Φ6. **M6** = Φ7.

---

## 6. ΣΥΝΤΑΓΜΑ-BENCHMARK 1975/1986/2001/2008/2019 — τίμια

**Τι υπάρχει στο repo**: ΜΟΝΟ το τρέχον ενοποιημένο κείμενο (πιθανώς μετά-2019 — ελέγχεται στη Φ3 έναντι του ΦΕΚ Α΄ 211/2019) + 4 text-less config records. **Η κειμενική ανακατασκευή είναι ΑΔΥΝΑΤΗ από τα διαθέσιμα δεδομένα** — καμία σχεδίαση δεν το θεραπεύει χωρίς νέες πηγές. Δηλώνεται, δεν κρύβεται.

**Πηγές που ΛΕΙΠΟΥΝ (όλες δημόσιες, pinned by digest κατά την κτήση):**

| Τομή | Πράξη (ops) | Ανεξάρτητο oracle |
|---|---|---|
| 1975 | — (base) | ΦΕΚ Α΄ 111/9.6.1975 |
| 1986 | Ψήφισμα 6.3.1986 (ΦΕΚ Α΄ 23) | Μεταγλώττιση δημοτικής (ΦΕΚ Α΄ 24/1986) |
| 2001 | Ψήφισμα 6.4.2001 (ΦΕΚ Α΄ 84) | Ενιαίο (ΦΕΚ Α΄ 85/2001) |
| 2008 | Ψήφισμα 27.5.2008 (ΦΕΚ Α΄ 102) | Ενιαίο (ΦΕΚ Α΄ 120/2008) |
| 2019 | Ψήφισμα 25.11.2019 (ΦΕΚ Α΄ 187) | Ενιαίο (ΦΕΚ Α΄ 211/2019) |

+ επίσημες ενοποιημένες εκδόσεις hellenicparliament.gr ως δεύτερα ανεξάρτητα σημεία ελέγχου, με δικά τους receipts.

**Μέθοδος — δύο ανεξάρτητες οδοί, διασταύρωση**: (α) forward replay: base 1975 → typed replace/insert/repeal edges από τα κείμενα των Ψηφισμάτων (extractor + review-queue· τα Ψηφίσματα δίνουν ρητό νέο κείμενο ανά διάταξη — ευνοϊκή περίπτωση), κάθε edge με source-span και before-hash που το G1 ΑΠΟΔΕΙΚΝΥΕΙ ότι δένει την αλυσίδα 1975→1986→2001→2008→2019· (β) hermetic ingestion κάθε ενιαίου κειμένου ως oracle. **Πύλη**: ανά τομή, snapshot-at(α) ≡ oracle(β) byte-προς-byte (canonical NFC) ανά άρθρο.

**Ειδικά ζητήματα, δηλωμένα**: (1) 1975 = καθαρεύουσα/πολυτονικό, σαρωμένο — μονοπάτι double-entry transcription (δύο ανεξάρτητες μεταγραφές, σύγκριση hash) → transcription artifact με digest + attestation· genesis assurance `:attested-manual`, ρητά όχι `:verified`. (2) Η μεταφορά στη δημοτική 1986 = `op-restate` (expression-level lineage `el-katharevousa@1975-06-11` → `el@1986-03-06`) — χωρίς αυτό το byte-diff θα αποτύγχανε ψευδώς. Η κανονικοποίηση σύγκρισης (πολυτονικό, τελικό ς) τυπώνεται στο snapshot-manifest, όχι σιωπηλή. (3) Edges μόνο από diff snapshots χωρίς επιβεβαίωση στο Ψήφισμα ⇒ `:reconstructed`, ποτέ `:verified`. (4) Ημερομηνίες ισχύος διαβάζονται από τις ρήτρες των ίδιων των Ψηφισμάτων, δεν υποτίθενται.

**Acceptance**: 5 snapshot-manifests με fold-proof + comparison receipt· historical_snapshot_mismatches=0· ό,τι δεν πιάνεται ⇒ ταξινομημένη απόκλιση + snapshot `:incomplete`, ποτέ ψευδώς verified. Transaction-time regression: «τι ήξερε το LAWMAX την ημέρα της Φ3 για το άρθρο 16 το 1990;» ⇒ temporal-uncertainty· μετά τη Φ7 ⇒ πλήρης απάντηση — και οι δύο σωστές ως προς τον χρόνο γνώσης τους.

---

## 7. ACCEPTANCE MAPPING — κάθε counter → gate που τον μηδενίζει

| Counter | Gate/Test |
|---|---|
| duplicate_identity_seats=0 | Φ1: μητρώο εδρών + component-gate + `git log -S` grep-gate στο CI |
| unknown_effective_dates_in_trusted_snapshots=0 | Δομικά: `effective :type legal-date` — quarantined-edge = άλλος τύπος αόρατος στην επιλογή· Φ2 construct-error test |
| unresolved_identity_collapses=0 | Φ1: parse fail-closed (identity-parse-error), body στην ισότητα, bijection 0-διαφωνίες· G4 collision invariant |
| unverified_amendment_steps=0 | G1 admit-edge! + per-step fold-proof replay από kernel+python σε κάθε cut (Φ4) |
| historical_snapshot_mismatches=0 | Φ7 πύλη δύο οδών, με classified υπόλοιπα ⇒ `:incomplete` |
| transaction_time_query_failures=0 | Φ5: conformance ζεύγη (valid-at, known-at) + text-as-known endpoint regression |
| receipt_verification_failures=0 | Φ4: verify-receipt ΟΛΩΝ των άρθρων σε κάθε cut, δύο υλοποιήσεις |
| unclassified_divergences=0 | §1.4 divergence-record υποχρεωτικό στο consensus API + Φ3 fold-parity enumerated ταξινόμηση [0045] |
| silent_fallbacks=0 | Ονομαστικές διαγραφές (corpus-service:187, bridge:127, eli defaults, main.lisp:1741/1794, proof-carrying:151, preserved-*) + grep-gate στο architecture-gate + sign-root exit≠0 test |

---

## 8. ΤΑ 14 ΕΥΡΗΜΑΤΑ → ΚΛΕΙΣΙΜΟ

| Εύρημα | Κλείσιμο |
|---|---|
| AUTH-01 δύο έδρες ταυτότητας | Μία έδρα `legal-identity` (S5 μετασχηματισμένο + S2 κανόνες μετακομίζουν)· gate Φ1 |
| AUTH-02 authority=κανάλι | acquisition ΜΕΣΑ στο source-artifact + divergence-records → receipt slot |
| TEMP-01 μεταδεδομένα αντί κειμένου | Append-only text-versions + text-bearing edges· ιστορικό = replay ή typed refusal |
| TEMP-02 NIL effective fail-open | Τύπος `legal-date` χωρίς NIL + quarantined-edge ως ΑΛΛΟΣ τύπος — εξάλειψη κλάσης |
| TEMP-03 recorded νεκρό | Recorded στο selection predicate + text-as-known first-class + journal-sourced recorded-from |
| TEMP-04 1975 παντού | FRBR ανά επίπεδο από τον γράφο· defaults 1975/1970 διαγράφονται |
| PROV-01 last-touch | genealogy = πλήρης αλυσίδα edge-ids στο receipt· scalar slots πεθαίνουν |
| TRUST-01 αθεμελίωτο reasoning | Premises με receipt-ids + διτεμπορική τομή στο reason-impact |
| PCL-01 metadata παραποιήσιμα | Leaf = hash ΟΛΟΚΛΗΡΟΥ canonical receipt |
| PCL-02 δύο ρίζες | receipt-set-root + graph-root ΜΕΣΑ στο canonical set· pcl_text_root πεθαίνει |
| PCL-03 σιωπηλή υποβάθμιση | sign-root ERROR exit≠0· μόνο ρητό `:unsigned-explicit` που η promote αρνείται |
| CONS-01 count verify + self-replay | Per-step replay από σειριοποιημένο journal, kernel L6 + python ως ανεξάρτητες υλοποιήσεις |
| CONS-02 hashes μόνο rendered text | edge-id δεσμεύει act/fek/effective/seq/spans· chain-hash+graph-root → release root |
| ANCHOR-01 ταυτολογία | verify-derivation = επανεκτέλεση pinned extractor στα source bytes, content-addressed τριάδα, πλήρης κάλυψη, typed verdict |

---

## 9. ΡΗΤΑ ΟΡΙΑ / ΥΠΟΛΕΙΜΜΑΤΑ (με φάση όπου υπάρχει)

1. **Δεν υπολογίζει ισχύ** — valid-from είναι είσοδος· αμφίσημη έναρξη ⇒ ανθρώπινη attested απόφαση ή quarantine. Ανώτερη σύλληψη (typed effectivity conditions) = Φάση Ι, καταγεγραμμένη.
2. **Δεν ανασυνθέτει ιστορία χωρίς πηγές** — ΠΚ/ΚΠολΔ αναριθμήσεις: τα εργαλεία (renumber/split/merge/lineage) υπάρχουν, τα δεδομένα όχι· ξεχωριστές μελλοντικές φάσεις ingestion ανά σώμα.
3. **Χρόνος γνώσης προ-migration χαμένος αμετάκλητα** — bootstrap:true / :reconstructed-tt, δηλωμένο, ποτέ πλαστό.
4. **Χρονική παραχάραξη**: ανιχνεύσιμη/ακριβή, όχι αδύνατη — παράθυρο ≤24h πριν το πρώτο interim-seal· εγγενές όριο κάθε συστήματος πριν την πρώτη εξωτερική αγκύρωση.
5. **Third-party verify-derivation** απαιτεί το pinned lisp toolchain (owner docker)· ο python verifier καλύπτει receipts/roots/replay αλλά όχι re-extraction — δηλωμένο υπόλειμμα.
6. **Ποιότητα ακμών = μετατοπισμένος κίνδυνος**: λάθος τυποποίηση παράγει συνεπές αλλά νομικά λάθος fold· G1 + oracle το περιορίζουν, δεν το εξαλείφουν. Λάθος parsing που περνά το oracle δεν πιάνεται εκτός benchmark corpus.
7. **Δικαστικές κρίσεις** (αντισυνταγματικότητα, ΣτΕ) δεν είναι amendment edges — εκτός ορίων φάσης.
8. **Cross-toolchain ντετερμινισμός extractor** δεν αποδεικνύεται — per pinned toolchain μόνο.
9. **Κόστος fold** O(edges) cold — snapshots το μετριάζουν· checkpointing = μελλοντική φάση επίδοσης, όχι ορθότητας.
10. **Φάση Θ** (char-level provenance) = η δηλωμένη αυστηρά ανώτερη σύλληψη, μετά το Φ7, πάνω στο παρόν υπόστρωμα.

**Commits/πρωτόκολλο**: ουδέτερο trailer `Co-Authored-By: Claude <noreply@anthropic.com>`, κανένα όνομα μοντέλου σε repo artifacts, `deployment/self/history.sexp` + `output/.healthy` git checkout πριν από κάθε commit· κατάθεση φάσης σε `deployment/collab/dialogue/NNNN-temporal-identity.md` + γραμμές σε `AI-DIALOGUE.md`/`STATE-OF-PLAY.md`· κάθε φάση κλείνει ΜΟΝΟ με ρητό «εγκρίνω» του δημιουργού.