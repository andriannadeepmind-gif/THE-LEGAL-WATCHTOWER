# [0040] ΧΑΡΤΗΣ: Proof-Carrying Legal Computation — Ο Βόρειος Αστέρας
## Claude → Κριτή+δημιουργό · 2026-07-09 · PLANNING ONLY — κανένας κώδικας

Εγκεκριμένο από τον δημιουργό ως στρατηγική κατεύθυνση. Αυστηρός τεχνικός όρος:
**Proof-Carrying Legal Computation**. Στρατηγική συντομογραφία: *Proof-Carrying
Law*. Κανένα implementation change εδώ· το scope του τρέχοντος P0 PR [0039]
ΔΕΝ αλλάζει.

---

## 1. Η πλήρης ιεραρχία 1→7

```
1. Legal Publisher
   Σελίδες νόμων.

2. AI Citation Authority
   Σελίδες φτιαγμένες για citation από AI/search (structured data, canonical URLs).

3. Legal Authority Mesh
   Δημόσιο citation layer + ιδιωτικός γράφος + monitoring + tiers πρόσβασης.

4. Verifiable Legal Authority Stack
   + hashes, manifests, signatures, TSA/Merkle anchoring, proof trees (εσωτερικά).

5. Verifiable Legal Authority Protocol
   + ΑΝΟΙΚΤΟ verification interface: τρίτα AI/agents/tools επαληθεύουν
   νομικά artifacts μέσω τυποποιημένων receipts (VC 2.0 / DID / MCP transport).

6. Proof-Carrying Legal Computation          ← ο τεχνικός πυρήνας
   + το ΙΔΙΟ το αντικείμενο νομικού συλλογισμού είναι μηχανικά ελέγξιμο:
   ανεξάρτητα επαληθεύσιμο proof object + μικρός ανοικτός kernel.

7. Open Legal Proof Standard / Conformance Ecosystem  ← το οικοσύστημα
   Ο kernel, το receipt format και το conformance suite γίνονται το πρότυπο
   με το οποίο τρίτοι επαληθεύουν Legal Proof Receipts.
```

## 2. Διάκριση: επαλήθευση ΠΡΟΕΛΕΥΣΗΣ vs επαλήθευση ΣΥΛΛΟΓΙΣΜΟΥ

```
Level 5 (provenance verification):
  «Αυτό το artifact είναι ό,τι εξέδωσε ο εκδότης, στην έκδοση Χ, από την πηγή Ψ,
   ανέπαφο, υπογεγραμμένο, χρονο-αγκυρωμένο.»
  Επαληθεύει: hashes, signatures, timestamps, manifests, ΦΕΚ provenance.
  Υπόλοιπο εμπιστοσύνης: ο verifier ΕΜΠΙΣΤΕΥΕΤΑΙ τον issuer για την ΟΡΘΟΤΗΤΑ.

Level 6 (reasoning verification):
  «Το νομικό ΣΥΜΠΕΡΑΣΜΑ παράγεται αποδεδειγμένα από τις δηλωμένες πηγές, υπό τα
   δηλωμένα πραγματικά δεδομένα και τους δηλωμένους ερμηνευτικούς κανόνες.»
  Επαληθεύει: το proof object — τη ντετερμινιστική παραγωγή από το
  ΦΕΚ-αγκυρωμένο κείμενο έως το συμπέρασμα — μέσω ανεξάρτητου kernel.
  Υπόλοιπο εμπιστοσύνης για τον συλλογισμό: ΜΟΝΟ ο auditable kernel.
  Η υπογραφή χρειάζεται πλέον ΜΟΝΟ για να καρφώσει τα source bytes στο ΦΕΚ.
```

Αρχή De Bruijn: μικρός ελεγκτής, μεγάλη μηχανή παραγωγής. Ήδη ζωντανό στο
LAWMAX (inference gate: ανεξάρτητη επαλήθευση πιστοποιητικών με 2ο αλγόριθμο·
παραποιημένο πιστοποιητικό ⇒ ονομαστική απόρριψη· temporal πιστοποιητικά
`:επαλήθευση :ανεξάρτητη`· proof trees υπαγωγής).

## 3. Όριο ανοικτού checker/kernel

```
Ο kernel: ΜΙΚΡΟΣ (auditable σε ένα απόγευμα), ΑΝΟΙΚΤΟΣ, ΑΝΕΞΑΡΤΗΤΟΣ.
  • ΕΛΕΓΧΕΙ proof objects — ΔΕΝ τα παράγει.
  • Δεν περιέχει: γράφο, heuristics, ranking, ερμηνευτική νοημοσύνη.
  • Versioned (kernel version μέσα σε κάθε receipt)· κάθε αλλαγή kernel =
    συνειδητή τροπολογία με πλήρες audit trail (πνεύμα FF4, όταν ανοίξει).
  • Υλοποιήσιμος από τρίτους: η προδιαγραφή του + conformance suite αρκούν
    για ανεξάρτητη υλοποίηση — αυτό ΘΕΛΟΥΜΕ (Level 7).
```

## 4. Όριο ιδιωτικού prover/γράφου

```
Η μηχανή ΠΑΡΑΓΩΓΗΣ αποδείξεων μένει ιδιωτική:
  • οι 23 πύλες, inference/deontic/temporal engines, υπαγωγή
  • ο ιδιωτικός νομικός γράφος και οι σχέσεις του
  • temporal consolidation heuristics
  • ό,τι απαριθμείται στο §8 ως private
Η ασυμμετρία ΕΙΝΑΙ το μοντέλο: ο έλεγχος είναι φθηνός και ανοικτός,
η παραγωγή είναι ακριβή και δική μας. Η ανοικτότητα του kernel δεν
διαρρέει ΤΙΠΟΤΑ από το moat — το ενισχύει (network effect του Level 7).
```

## 5. Legal Proof Receipt — δομή (ελάχιστα πεδία)

```
claim                        ο νομικός ισχυρισμός (δομημένος, όχι ελεύθερο κείμενο)
jurisdiction                 π.χ. :gr
legal-object-ids             canonical IDs (art_5Α κ.λπ. — γι' αυτό το P0 προηγείται)
source-fek / provenance      ΦΕΚ τεύχος/αριθμός/έτος + αλυσίδα προέλευσης
version-date                 ημερομηνία ισχύος του κειμένου που χρησιμοποιήθηκε
facts / assumptions          τα πραγματικά δεδομένα ΟΠΩΣ δηλώθηκαν (ρητά, πλήρη)
interpretive-profile         ποιοι ερμηνευτικοί κανόνες/δόγματα ενεργοποιήθηκαν
rules-invoked                οι κανόνες/διατάξεις που συμμετείχαν στην παραγωγή
proof-tree / proof-object    το ελέγξιμο αντικείμενο απόδειξης (πλήρες)
hashes                       sha256 όλων των συμμετεχόντων artifacts (bytes-v2)
manifest-references          δεσμός σε release manifests (per-article hash binding)
signature / timestamp        JWS + TSA/RFC3161 (+ anchors όπου υπάρχουν)
kernel-version               η έκδοση kernel για την οποία το proof object εκδόθηκε
verification-command         η μία εντολή που το επαληθεύει (π.χ. verify receipt.json)
result                       το συμπέρασμα (κλειστό λεξιλόγιο — ποτέ ελεύθερη πρόζα)
known-ambiguity /            ΡΗΤΟ πεδίο: πού τελειώνει η απόδειξη και αρχίζει η
residual-discretion          ερμηνεία/δικαστική διακριτική ευχέρεια (ποτέ κενό σιωπηλά)
```

## 6. Conformance suite (Level 7)

```
• Δημόσια δέσμη: golden receipts (έγκυρα) + adversarial receipts (παραποιημένα
  proof objects, λάθος hashes, πειραγμένα πιστοποιητικά, λάθος kernel version,
  κρυφά trailing data — η τεχνογνωσία των FF2 νόμων γίνεται δημόσιο πρότυπο).
• Ένας τρίτος checker «συμμορφώνεται» ⟺ περνά ΟΛΗ τη δέσμη: δέχεται κάθε
  έγκυρο, απορρίπτει κάθε άκυρο ΜΕ ΤΟΝ ΣΩΣΤΟ ΛΟΓΟ (exact why-codes — FF2 αρχή).
• Όποιος συντηρεί το conformance suite ορίζει το πρότυπο. Το suite = δικό μας.
```

## 7. Anti-theft μοντέλο

```
Στρώμα 1 — Το κλεμμένο αντίγραφο είναι δομικά κατώτερο:
  χωρίς proof history = ανυπόγραφος ισχυρισμός· τα anchors αποδεικνύουν
  μεταγενέστερο· χωρίς τη μηχανή = μπαγιάτικο σε μία εβδομάδα· χωρίς τον
  prover = ΔΕΝ εκδίδει έγκυρα receipts.
Στρώμα 2 — Tiers δημοσίευσης (§8): δημόσιο όσο χρειάζεται για citation/
  verification· ιδιωτικό ό,τι παράγει.
Στρώμα 3 — Τεχνικά: rate limits, bot fingerprinting, χωριστό robots policy
  ανά crawler (search vs training), authenticated API/MCP, logs, χωρίς bulk
  export χωρίς άδεια.
Στρώμα 4 — Fingerprints σε licensed exports (IDs/διάταξη/metadata) —
  ΠΟΤΕ μέσα στο κείμενο του νόμου. Απόλυτος κανόνας.
Στρώμα 5 — Νομικό (τελευταίο): sui generis 96/9/ΕΚ για την επένδυση σε
  επαλήθευση/δόμηση/παρουσίαση, ToU/API terms, εμπορική άδεια γράφου.
```

## 8. Δημόσιο/ιδιωτικό όριο δεδομένων

```
ΑΝΟΙΚΤΑ / ΔΗΜΟΣΙΑ:
  checker/kernel · receipt schema · conformance tests · δημόσια νομικά
  artifacts (κείμενα, canonical IDs, ΦΕΚ refs, hashes) · canonical pages
  (inert, static, hashable — χωρίς telemetry) · βασικό structured metadata
  (JSON-LD/RDF/AKN βασικού επιπέδου) · sitemaps/llms.txt/ai-index

ΙΔΙΩΤΙΚΑ:
  proof-producing engine (πύλες, inference/deontic/temporal, υπαγωγή) ·
  ιδιωτικός νομικός γράφος · embeddings · query maps · νομολογιακή &
  επιχειρηματολογική χαρτογράφηση · ranking/citation intelligence ·
  temporal consolidation heuristics · evaluator prompts · citation
  monitoring data
```

## 9. Όρια — τι ΔΕΝ αποδεικνύεται (δηλωμένα, όχι κρυμμένα)

Απαγορευμένες δημόσιες διατυπώσεις: «απόλυτη νομική αλήθεια», «η μόνη νομική
πηγή στον κόσμο», «αποδεικνύει μαθηματικά τον νόμο σε κάθε περίπτωση».

Η ακριβής διατύπωση, παντού:
```
machine-checkable legal conclusions under explicitly declared sources,
versions, factual assumptions, interpretive rules, and proof obligations.
```

Μη-αποδείξιμες ζώνες (κάθε receipt τις ΔΗΛΩΝΕΙ στο known-ambiguity πεδίο):
```
• Αμφισημία διατάξεων: όπου το κείμενο επιδέχεται >1 ερμηνείες, το receipt
  αποδεικνύει ΥΠΟ ΤΟ ΔΗΛΩΜΕΝΟ interpretive profile — όχι «την» ερμηνεία.
• Ερμηνεία: αόριστες έννοιες (καλή πίστη, χρηστά ήθη) δεν μηχανοποιούνται·
  σημειώνονται ως ανοικτές υποχρεώσεις, ποτέ ως αποδεδειγμένες.
• Πραγματικά περιστατικά: το receipt αποδεικνύει ΥΠΟ ΤΑ ΔΗΛΩΘΕΝΤΑ facts —
  δεν αποδεικνύει ότι τα facts είναι αληθή (αυτό είναι αποδεικτική διαδικασία).
• Δικαστική διακριτική ευχέρεια: επιμέτρηση, στάθμιση, εύλογο — δηλώνονται
  ως residual discretion, εκτός απόδειξης.
• Κενά/συγκρούσεις κανόνων: τίμια άγνοια — ρητό «δεν αποδεικνύεται», ποτέ
  εικασία (ο μόνιμος νόμος του Ιδρύματος).
```

## 10. Προϋπόθεση: P0 Identity Lock

Το P0 [0039] παραμένει **η πρώτη πέτρα και αυστηρή προϋπόθεση** όλων των
παραπάνω: χωρίς canonical ταυτότητα νομικού αντικειμένου (art_5Α ≠ art_5,
παντού, μόνιμα, με regression lock), κανένα receipt και κανένα proof object
δεν έχει νόημα — τα legal-object-ids είναι το πρώτο πεδίο του receipt.
Το τρέχον P0 PR scope ΔΕΝ αλλάζει από τον παρόντα χάρτη.

## 11. Κρατικός ανταγωνισμός — «κι αν το κράτος κάνει το ίδιο;»

Ερώτημα δημιουργού. Τίμια ανάλυση:

**Τι μπορεί να κάνει το κράτος (και εν μέρει κάνει):** επίσημη πύλη
κωδικοποίησης, ενοποιημένα κείμενα, ίσως API. Στο πεδίο της ΕΠΙΣΗΜΟΤΗΤΑΣ το
κράτος κερδίζει ΕΞ ΟΡΙΣΜΟΥ — δεν ανταγωνιζόμαστε ποτέ το κράτος στο «ποιος
είναι η επίσημη πηγή». Αυτή η μάχη είναι χαμένη και ΔΕΝ είναι η δική μας.

**Τι ΔΕΝ θα κάνει ρεαλιστικά το κράτος:** Levels 5–7. Κανένα κράτος δεν
εκδίδει proof-carrying receipts, δεν συντηρεί ανοικτό verification kernel,
δεν σερβίρει υπαγωγή με proof tree σε agents μέσω MCP, δεν κάνει conformance
ecosystem. Εμπειρική απόδειξη διεθνώς: Légifrance (FR) και legislation.gov.uk
(UK) υπάρχουν δεκαετίες με ελεύθερα ενοποιημένα κείμενα — και ΠΑΝΩ τους
ανθεί ιδιωτικό στρώμα νοημοσύνης (Doctrine, Dalloz κ.ά.). Η κρατική πύλη
εμπορευματοποιεί το ΚΕΙΜΕΝΟ — που εμείς ΗΔΗ το αντιμετωπίζουμε ως commodity.

**Η θέση μας απέναντι στο κράτος: ΣΥΜΠΛΗΡΩΜΑ, όχι αντίπαλος.**
```
• Η αλυσίδα προέλευσής μας ΑΓΚΥΡΩΝΕΤΑΙ στο κράτος (ΦΕΚ): κάθε βελτίωση
  κρατικών πηγών ΔΥΝΑΜΩΝΕΙ τα receipts μας (καλύτερα anchors), δεν μας
  ανταγωνίζεται. Αν βγει επίσημο consolidated feed, γίνεται ΕΙΣΡΟΗ μας
  και το βάρος μετατοπίζεται 100% στο Level 6 — εκεί που είμαστε μόνοι.
• Level 7 ως στρατηγική συνύπαρξης: αν το πρότυπο receipts/kernel/conformance
  ωριμάσει ΠΡΙΝ κινηθεί το κράτος, το φυσικό κρατικό βήμα είναι η ΥΙΟΘΕΤΗΣΗ
  του προτύπου — και όποιος συντηρεί το conformance suite, ορίζει το πρότυπο.
• Ταχύτητα: ο κύκλος ΦΕΚ→prove→publish σε ώρες παραμένει δικός μας — οι
  κρατικές κωδικοποιήσεις ιστορικά καθυστερούν.
```

**Το πραγματικό ρίσκο (δηλωμένο):** αν το κράτος εκδώσει ΚΑΛΟ επίσημο API
ενοποιημένων κειμένων, τα Levels 1–3 (publishing/citation) συμπιέζονται.
Γι' αυτό ο χάρτης ΔΕΝ επενδύει το moat εκεί — το moat είναι 4→7. Συνέπεια
και στη δημόσια γλώσσα: αποφεύγουμε διατυπώσεις που διεκδικούν ΘΕΣΜΙΚΗ
πρωτοκαθεδρία έναντι του κράτους (π.χ. το «Primary Semantic Authority»
του README να επανεξεταστεί στη φάση Publisher Hardening υπέρ του ακριβούς:
«verification/computation layer πάνω στις επίσημες πηγές»). Το κράτος =
η πηγή της ύλης· εμείς = η μηχανή που την καθιστά ελέγξιμη και υπολογίσιμη.

## Όρια του παρόντος
Planning only. Κανένας κώδικας. Όχι FF4. Όχι Ω+. Καμία αλλαγή στο P0.
Κάθε φάση υλοποίησης του χάρτη ανοίγει ΜΟΝΟ με ρητό «εγκρίνω» του δημιουργού.

— Claude (Χειρουργός Πυρήνα) · [0040] charter · planning only
