(:lawmax-phase1a-cluster/1
 :cluster "ΚΑΤΑΣΤΑΣΗ ΚΑΙ ΓΝΩΣΗ — /frozen/ro/deployment/{self,self-study,knowledge,data,state,collab} + deployment/*.js *.sh"
 :status :complete
 :files-read 388
 :files-read-breakdown
  ((:directly-opened 66
    :detail "9 σενάρια (.js/.sh) · self/history.sexp · state/daemon-status.json · 7 knowledge/*.sexp · 6 *_clean.json + 6 *.prov.json + 3 registries + syntagma_clean.zip · 2 self-study · 4 collab (AI-DIALOGUE, STATE-OF-PLAY, APPROVAL-ACT, RESERVATION-OF-RIGHTS) · 21 dialogue πλήρως (0095-0105, 0109, 0116, 0119-0125, 0062) · 0088 μερικώς · /frozen/ro/.gitignore · /frozen/ro/source/knowledge-packs.lisp (για την έδρα φόρτωσης γνώσης)")
   (:programmatically-verified 322
    :detail "161 decisions/areios-pagos/*.json + 161 *.prov.json — υπολογίστηκε SHA-256 κάθε αρχείου και αντιπαραβλήθηκε με το content_sha256 του sidecar")
   (:index-only 113
    :detail "collab/dialogue/0001-0094 μέσω τίτλου+σύνοψης στο ευρετήριο AI-DIALOGUE.md, κατά την εντολή"))
 :frozen-mount "/frozen/ro — δηλωμένο ως commit e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"

 ;; ==========================================================================
 ;; ΙΚΑΝΟΤΗΤΕΣ
 ;; ==========================================================================
 :capabilities
 ((:name "Αυτοβιογραφική μνήμη — hash-chained self-history"
   :presence :present
   :domain "Αλυσίδα γεγονότων ζωής του συστήματος· ένα S-expression record ανά γραμμή."
   :assumptions "Append-only· κάθε record κρατά :PREV = :HASH του προηγούμενου· ο γράφων δεν αναδιατάσσει."
   :guarantees "Δομικά: SHA-256 hash chain (64 hex), genesis :PREV = 64 μηδενικά. ΜΗΧΑΝΙΚΑ: ΚΑΜΙΑ — «self-history αλυσίδα: ΕΝΤΕΛΩΣ ατέστ (0 τεστ verify-chain)»."
   :failure-semantics ":unknown — δεν εντοπίστηκε επαληθευτής ούτε πύλη που να κοκκινίζει σε σπασμένη αλυσίδα."
   :operating-model "3 ΜΟΝΟ εγγραφές (:GENESIS :BIRTH :INHERITANCE), ΟΛΕΣ με ταυτόσημο timestamp 2026-07-04T11:10:24· καμία εγγραφή έκτοτε παρά 125 φάσεις διαλόγου."
   :materiality "Είναι η μοναδική «μνήμη ζωής» που ΥΠΑΡΧΕΙ στο commit — και είναι κενή από εμπειρία."
   :evidence "/frozen/ro/deployment/self/history.sexp:L1-L3@sha256:3e0b6766e32d /frozen/ro/deployment/collab/dialogue/0116-claude.md:L379-L379@sha256:2727147538b3")

  (:name "Βιωματικό ρεύμα επεισοδίων (episodes.sexp)"
   :presence :absent
   :domain "Δηλωμένο ως «το βιωματικό μου ρεύμα, με αλυσίδα SHA-256»."
   :assumptions "Δηλώνεται στον χρήστη ως ΜΟΝΙΜΗ αποθήκευση."
   :guarantees "Δηλωμένες: chained-append, recall by lemma, verify-episode-chain. Πραγματικές: ΚΑΜΙΑ — το αρχείο δεν υπάρχει."
   :failure-semantics "Το σύστημα λέει «Καταγράφηκε» ενώ δεν υπάρχει αποδέκτης."
   :operating-model "gitignored ως «LAWMAX runtime state (not identity)»· 0 ευρήματα σε find ΟΛΟΥ του repo."
   :materiality "Το ΜΙΣΟ της δηλωμένης μνήμης του συστήματος δεν υπάρχει στο παραδοτέο."
   :evidence "/frozen/ro/deployment/knowledge/self-glossary.sexp:L38-L38@sha256:c40b7a9d2690 /frozen/ro/.gitignore:L47-L47@sha256:7c8ebc41610b /frozen/ro/deployment/self-study/INTELLIGENCE-AUDIT-2026-07-05.md:L278-L278@sha256:b5a3bb502fcd")

  (:name "Αναστοχαστικό ρεύμα μαθημάτων (lessons.jsonl)"
   :presence :absent
   :domain "Δηλωμένο ως «μαθήματα αναστοχασμού: κάθε αποτυχία κατανόησης, για ριζική διόρθωση με --lessons/--reflect»."
   :assumptions "Ίδιες με πάνω."
   :guarantees "ΚΑΜΙΑ — το αρχείο δεν υπάρχει."
   :failure-semantics "Ίδια — ψευδής δήλωση προς τον χρήστη."
   :operating-model "gitignored· 0 ευρήματα σε find."
   :materiality "Το άλλο μισό της δηλωμένης μνήμης."
   :evidence "/frozen/ro/deployment/knowledge/self-glossary.sexp:L38-L38@sha256:c40b7a9d2690 /frozen/ro/.gitignore:L40-L40@sha256:7c8ebc41610b")

  (:name "Κατάσταση αυτόνομου daemon ΦΕΚ"
   :presence :spec-only
   :domain "Μετρητής κύκλων, πολιτική, ουρά προτάσεων προς έγκριση."
   :assumptions "Ο daemon ενημερώνει το αρχείο σε κάθε κύκλο."
   :guarantees "Καμία· απλό JSON, χωρίς hash, χωρίς υπογραφή, χωρίς αλυσίδα."
   :failure-semantics ":unknown"
   :operating-model "cycle 0, policy propose, pending_review 0, proposals []· utc 2026-07-02T22:22:42Z — ΠΡΟΓΕΝΕΣΤΕΡΟ της γέννησης (2026-07-04). Ο δημιουργός το επιβεβαιώνει: «cycle 0, χωρίς cursor, FEK_ANALYZE off, μόνο τρέχον έτος — γι' αυτό δεν ειδοποίησε ποτέ»· η όπλιση «αναβλήθηκε»."
   :materiality "Ο «αυτόνομος» βρόχος ενημέρωσης του νόμου δεν έχει τρέξει ΠΟΤΕ ούτε έναν κύκλο."
   :evidence "/frozen/ro/deployment/state/daemon-status.json:L1-L1@sha256:486b23c20b2f /frozen/ro/deployment/collab/STATE-OF-PLAY.md:L51-L51@sha256:d8054f835a9d")

  (:name "Σώμα νομικών κειμένων — 6 κώδικες, 4694 άρθρα"
   :presence :present
   :domain "syntagma 124 · poinikoskodikas 529 · astikos 2040 · kpolitikis 1102 · kpoinikis 595 · kdioikitikis 304."
   :assumptions "Το JSON είναι ντετερμινιστική εξαγωγή από hash-δεμένο PDF + δηλωμένα errata."
   :guarantees "ΜΕΤΡΗΣΑ: και τα 6 content_sha256 των sidecars ΤΑΥΤΙΖΟΝΤΑΙ με τα πραγματικά bytes (6/6)· ΜΕΤΡΗΣΑ: 124+529+2040+1102+595+304 = 4694 ✓."
   :failure-semantics ":unknown — ποιος επαληθεύει τα sidecars στο runtime και τι γίνεται σε αστοχία δεν φαίνεται σε αυτή τη συστάδα."
   :operating-model "extraction_method «pdf-adapter+raw-text-fsm@1» και για τα 6· errata: syntagma 2, astikos 2, kpoinikis 1, kdioikitikis 1, poinikos 0, kpolitikis 0."
   :materiality "Είναι «το γράμμα του νόμου» του συστήματος."
   :evidence "/frozen/ro/deployment/data/syntagma_clean.json.prov.json:L1-L1@sha256:ada4e0aa5541 /frozen/ro/deployment/data/astikos_clean.json.prov.json:L1-L1@sha256:88ec4f8cb992 /frozen/ro/deployment/collab/dialogue/0109-claude.md:L94-L106@sha256:422d8e49517c")

  (:name "Σώμα νομολογίας — 164 αποφάσεις"
   :presence :present
   :domain "areios-pagos 161 · efeteio-peiraios 2 · protodikeio-athinon 1."
   :assumptions "Κάθε απόφαση συνοδεύεται από sidecar slw-source-prov/1."
   :guarantees "ΜΕΤΡΗΣΑ: 161/161 sidecars areios-pagos επαληθεύουν (match=161, mismatch=0)· ομοιόμορφο σχήμα 6 κλειδιών σε ΟΛΑ (Counter: 161)."
   :failure-semantics ":unknown"
   :operating-model "extraction_method «decision-adapter@1»· errata: 0 σε ΟΛΕΣ."
   :materiality "Το capability-baseline μετρά «164 αποφάσεις» — συμφωνεί με τη μέτρησή μου."
   :evidence "/frozen/ro/deployment/data/decisions/areios-pagos/ap_2015_1.json.prov.json:L1-L1@sha256:f7fa68b791e2 /frozen/ro/deployment/collab/dialogue/0100-claude.md:L~60")

  (:name "Provenance sidecars (slw-source-prov/1)"
   :presence :present
   :domain "content_sha256 · source_digest · extraction_method · date · errata."
   :assumptions "content_sha256 = SHA-256 των ΑΚΡΙΒΩΝ bytes του συνοδευόμενου αρχείου."
   :guarantees "ΕΠΑΛΗΘΕΥΘΗΚΕ ΑΠΟ ΜΕΝΑ: 167/167 (161 decisions + 6 corpora) match, 0 mismatch."
   :failure-semantics ":unknown"
   :operating-model "Ένα sidecar ανά αρχείο δεδομένων· ΚΑΝΕΝΑ source_url, ΚΑΜΙΑ ημερομηνία λήψης, ΚΑΜΙΑ υπογραφή."
   :materiality "Το ΜΟΝΟ αναλλοίωτο ακεραιότητας που μπόρεσα να ΜΕΤΡΗΣΩ και να επιβεβαιώσω σε αυτή τη συστάδα."
   :evidence "/frozen/ro/deployment/data/astikos_clean.json.prov.json:L1-L1@sha256:88ec4f8cb992 /frozen/ro/deployment/data/decisions/areios-pagos/ap_2015_1.json.prov.json:L1-L1@sha256:f7fa68b791e2")

  (:name "Errata ledger — χειροκίνητη διόρθωση του γράμματος του νόμου"
   :presence :present
   :domain "Λίστα {article, from, to, reason, page} μέσα στο prov sidecar."
   :assumptions "Ο άνθρωπος έκρινε την «οπτική σειρά της σελίδας» ή 600dpi απόδοση ως ορθή."
   :guarantees "Κάθε erratum φέρει αιτιολογία και σελίδα· εφαρμόζεται ΑΚΡΙΒΩΣ-μία-φορά· stale ⇒ ΔΕΝ μαντεύεται· η έδρα μετακόμισε στο ΟΡΙΟ ΕΞΑΓΩΓΗΣ (adapters/errata-boundary.lisp) ώστε κανείς καταναλωτής να μην την παρακάμπτει."
   :failure-semantics "Δηλωμένο: waiver χωρίς εύρημα ⇒ σφάλμα· πλαστό :hygiene ⇒ σφάλμα."
   :operating-model "6 errata συνολικά σε 4694 άρθρα· 2 από αυτά (syntagma art.4) επικυρώθηκαν από τον δημιουργό επί εικόνας 600dpi (2026-07-21)."
   :materiality "Ανθρώπινη παρέμβαση στο κείμενο του νόμου, καταγεγραμμένη — αλλά το content_sha256 σφραγίζει το ΜΕΤΑ-errata κείμενο."
   :evidence "/frozen/ro/deployment/data/astikos_clean.json.prov.json:L1-L1@sha256:88ec4f8cb992 /frozen/ro/deployment/collab/dialogue/0109-claude.md:L17-L50@sha256:422d8e49517c /frozen/ro/deployment/collab/dialogue/0109-claude.md:L108-L120@sha256:422d8e49517c")

  (:name "Πύλη εισδοχής κειμένου (text-hygiene / text-observation)"
   :presence :present
   :domain "Κλειστό σύνολο ευρημάτων: :ascii-quote :unbalanced-guillemets :fek-wrap :replacement-char."
   :assumptions "Κάθε είσοδος κειμένου περνά από make-version-spec."
   :guarantees "Εισδοχή μόνο με :hygiene-waiver που κατονομάζει ΑΚΡΙΒΩΣ τα ευρήματα· blanket waiver απαγορεύεται· τα ευρήματα ΕΠΑΝΥΠΟΛΟΓΙΖΟΝΤΑΙ στο replay (stale παρατήρηση ⇒ journal-corruption)."
   :failure-semantics "Σιωπηλή είσοδος βρώμικου κειμένου δηλώνεται ΜΗ ΑΝΑΠΑΡΑΣΤΑΣΙΜΗ."
   :operating-model "Το ΥΠΑΡΧΟΝ σώμα εισήλθε με bootstrap waiver = τα πραγματικά του ευρήματα — δηλαδή τα ελαττώματα είναι journaled, ΟΧΙ διορθωμένα."
   :materiality "ΜΕΤΡΗΣΑ ΑΝΕΞΑΡΤΗΤΑ στα ίδια αρχεία: 336 άρθρα με ASCII εισαγωγικά (astikos 137 · kpolitikis 130 · kpoinikis 32 · kdioikitikis 25 · poinikos 12 · syntagma 0) — ΤΑΥΤΟΣΗΜΟ με το [0104]· 0 άρθρα με U+FFFD."
   :evidence "/frozen/ro/deployment/collab/dialogue/0104-claude.md:L~10-L45 /frozen/ro/deployment/data/*_clean.json")

  (:name "Γνωσιακά πακέτα (knowledge packs) — hot-reloadable δηλωτική γνώση"
   :presence :present
   :domain "7 πακέτα: verb-frames(40), dialogue(4 entries), lexicon(78), procedure(3 τελεστές), self-glossary(~20 entries), tatbestand(4 norms), taxonomy(12 γένη + 2 διαιρέσεις)."
   :assumptions "Ο φορτωτής σαρώνει deployment/knowledge/*.sexp· ensure-fresh καλείται σε ΚΑΘΕ /ask."
   :guarantees "Ατομικότητα: snapshot ΠΡΙΝ την εγκατάσταση, σφάλμα στη μέση ⇒ ΠΛΗΡΗΣ επαναφορά· άγνωστο kind ⇒ σφάλμα· κάθε entry (keyword …)· *read-eval* NIL μέσω της ΜΙΑΣ safe-read έδρας. ΚΑΜΙΑ εγγύηση ταυτότητας: το pack-sha ΥΠΟΛΟΓΙΖΕΤΑΙ και καταγράφεται αλλά ΔΕΝ αντιπαραβάλλεται με κανένα committed αναμενόμενο."
   :failure-semantics "Άκυρο πακέτο ⇒ τυπώνεται «ΑΠΟΡΡΙΦΘΗΚΕ (κρατιέται η προηγούμενη γνώση)» και ο κύκλος ΣΥΝΕΧΙΖΕΙ — δεν είναι fail-closed προς τον καλούντα."
   :operating-model "Πρώτο φίλτρο (mtime . μέγεθος)· σε αλλαγή, νέο SHA και επανεγκατάσταση. Δύο από τα 7 φέρουν ρητή αυτο-σήμανση «⚠ BOOTSTRAP: χειροποίητο περιεχόμενο — σκαλωσιά, ΟΧΙ απόδειξη μάθησης»."
   :materiality "Εδώ ζει ΟΛΗ η νομική/γλωσσική γνώση που το σύστημα «ξέρει» — 4 tatbestand norms έναντι 529 άρθρων ΠΚ."
   :evidence "/frozen/ro/source/knowledge-packs.lisp:L40-L40@sha256:ea774f532b44 /frozen/ro/source/knowledge-packs.lisp:L59-L83@sha256:ea774f532b44 /frozen/ro/source/knowledge-packs.lisp:L105-L150@sha256:ea774f532b44 /frozen/ro/deployment/knowledge/self-glossary.sexp:L10-L10@sha256:c40b7a9d2690 /frozen/ro/deployment/knowledge/casegrammar-core.sexp:L2-L2@sha256:8d863083fc32 /frozen/ro/deployment/knowledge/tatbestand-core.sexp:L1-L41@sha256:1ce1281267f1")

  (:name "Αποθηκευμένη ΜΑΘΗΜΕΝΗ γνώση (concept-grounding / understanding-rules / decision-grammar / guard-ops)"
   :presence :absent
   :domain "Τα είδη γνώσης που παράγει η ίδια η μάθηση (--self-extend, --learn-understanding)."
   :assumptions "Ο μηχανισμός define-knowledge-kind τα δηλώνει ως έγκυρα είδη."
   :guarantees "ΚΑΜΙΑ — ΜΕΤΡΗΣΑ: 11 δηλωμένα knowledge kinds, 7 πακέτα στον δίσκο. Τα 4 που λείπουν είναι ΑΚΡΙΒΩΣ τα προϊόντα μάθησης."
   :failure-semantics "Δεν υπάρχει· απλώς δεν υπάρχει τίποτα."
   :operating-model "Το ίδιο το STATE-OF-PLAY δηλώνει: «Μάθηση | ΜΗ αποδεδειγμένη — κανένας υιοθετημένος κανόνας από ζωντανή αποτυχία (τίμια δήλωση)»."
   :materiality "Απαντά ευθέως στο «τι έχει μάθει»: ΤΙΠΟΤΑ αποθηκευμένο."
   :evidence "/frozen/ro/source/knowledge-packs.lisp (define-knowledge-kind ×11) /frozen/ro/deployment/knowledge/ (7 αρχεία) /frozen/ro/deployment/collab/STATE-OF-PLAY.md:L18-L18@sha256:d8054f835a9d")

  (:name "Μητρώα κλειστών τύπων (body-kind · instrument-kind · scope-tag)"
   :presence :present
   :domain "10 είδη νομικών σωμάτων· 8 είδη θεσμικών γεγονότων με authority-class + evidence schema· 4 διαστάσεις scope με typed tags."
   :assumptions "Ο κώδικας ΔΕΝ έχει hard-coded enum· διαβάζει από εδώ με *read-eval* NIL."
   :guarantees "Tag/kind εκτός μητρώου ⇒ typed σφάλμα· το γενικό :event απαιτεί ρητή πράξη-πηγή με digest, «ποτέ ελεύθερο κείμενο»· το scope-tag /1 ΑΠΟΣΥΡΘΗΚΕ και ο loader δέχεται ΜΟΝΟ /2."
   :failure-semantics "Δηλωμένο fail-closed."
   :operating-model "Επέκταση «ΜΟΝΟ με νέα εγγραφή εδώ + receipt + ρητή έγκριση δημιουργού» — δηλωμένο σε σχόλιο, ΟΧΙ επιβεβλημένο από μηχανισμό ορατό σε αυτή τη συστάδα."
   :materiality "Ορίζουν τι μπορεί καν να αναγνωριστεί ως νόμος, ως γεγονός ισχύος, ως εμβέλεια."
   :evidence "/frozen/ro/deployment/data/body-kind-registry.sexp:L1-L15@sha256:674e35e92a98 /frozen/ro/deployment/data/instrument-kind-registry.sexp:L1-L34@sha256:07ea6fa4a572 /frozen/ro/deployment/data/scope-tag-registry.sexp:L1-L32@sha256:65e450bf14be")

  (:name "Δίκτυο — ανάκτηση ΦΕΚ PDF από et.gr (network edge)"
   :presence :present
   :domain "https://www.et.gr / search.et.gr / Azure blob του Εθνικού Τυπογραφείου."
   :assumptions "Ο host έχει bash, curl, node, playwright chromium· δεν υπάρχει CAPTCHA/Turnstile· η IP δεν είναι datacenter."
   :guarantees "ΜΟΝΟ magic bytes '%PDF-' στα πρώτα 5 bytes. ΚΑΜΙΑ κρυπτογραφική ή σημασιολογική δέσμευση ότι το PDF είναι ΤΟ ζητούμενο ΦΕΚ."
   :failure-semantics "exit 1 μετά N προσπαθειών· fetch-fek.sh διαγράφει το OUT, fetch-fek-by-number.sh ΟΧΙ."
   :operating-model "N προσπάθειες με ΕΝΑΛΛΑΣΣΟΜΕΝΟ User-Agent, exponential backoff + jitter, curl → headless Chromium με μασκαρισμένα automation signals."
   :materiality "Είναι η ΡΙΖΑ του corpus: ό,τι κατεβάσει γίνεται «το γράμμα του νόμου με ταυτότητα SHA-256»."
   :evidence "/frozen/ro/deployment/fetch-fek.sh:L1-L80@sha256:42acffc89892 /frozen/ro/deployment/fetch-fek.js:L1-L115@sha256:6c92f25b051b /frozen/ro/deployment/fetch-fek-by-number.sh:L1-L45@sha256:c43d47b68d1a /frozen/ro/deployment/fetch-fek-by-number.js:L1-L138@sha256:2889ba9bc0aa")

  (:name "Δίκτυο — ανακάλυψη νέας νομοθεσίας μέσω et.gr JSON API"
   :presence :present
   :domain "POST https://searchetv99.azurewebsites.net/api/searchlegislation μέσα από Playwright browser context."
   :assumptions "Το endpoint σερβίρει 200 χωρίς CAPTCHA· τα πεδία search_* διατηρούν σχήμα."
   :guarantees "Deduplication (url|number|year)· ντετερμινιστική κατασκευή blob URL· 10 assertions parse-test πάνω σε καρφωμένο payload."
   :failure-semantics "ΣΙΩΠΗΛΗ ΥΠΟΒΑΘΜΙΣΗ: σφάλμα ανά έτος ⇒ console.error και ΣΥΝΕΧΙΖΕΙ· parseData επιστρέφει [] σε junk/null. Άδεια λίστα ≡ «τίποτα νέο»."
   :operating-model "Node + Playwright chromium με --disable-blink-features=AutomationControlled· γράφει JSON στο FEK_LISTING_JSON που καταναλώνει ο Lisp πυρήνας."
   :materiality "Είναι το μοναδικό μάτι του συστήματος για νέο νόμο — και είναι δομικά τυφλό στην αποτυχία."
   :evidence "/frozen/ro/deployment/discover-fek.js:L1-L169@sha256:69c52b81a4ea /frozen/ro/deployment/discover-fek.test.js:L1-L43@sha256:a030e60f4ddc")

  (:name "Αυτόνομος κύκλος ενημέρωσης corpus (ΟΛΗ η ενορχήστρωση)"
   :presence :present
   :domain "discover → fetch → codify → consolidate → verify(golden) → sign, ανά cron tick."
   :assumptions "cron· flock· node· ORCHESTRATOR_CMD δείχνει σε /app/orchestrator.core· PCL_SIGNING_KEY διαθέσιμο."
   :guarantees "Single-flight μέσω flock -n· μη-μηδενικό exit από --auto-update διαδίδεται στο cron."
   :failure-semantics "ΣΙΩΠΗΛΗ ΥΠΟΒΑΘΜΙΣΗ σε ΚΑΘΕ βήμα discovery: '|| log …(continuing)' ×3."
   :operating-model "BASH είναι ο ενορχηστρωτής· ο Lisp πυρήνας είναι υποδιεργασία που καλείται 3 φορές."
   :materiality "Το ΑΝΩΤΑΤΟ επίπεδο ελέγχου του «αυτόνομου» συστήματος είναι shell script, όχι Lisp."
   :evidence "/frozen/ro/deployment/cron-auto-update.sh:L32-L86@sha256:01231faab127")

  (:name "Πρακτικά αρχιτεκτόνων (collab dialogue) — η ΜΟΝΗ πλούσια αποθηκευμένη μνήμη"
   :presence :present
   :domain "113 αρχεία dialogue/ + ευρετήριο + STATE-OF-PLAY (443 γραμμές, 105 KB)."
   :assumptions "Append-only, lock-free, ένα αρχείο ανά καταχώρηση, «ΠΟΤΕ edit αρχείου άλλου AI»."
   :guarantees "Καμία μηχανική· «Πηγή αλήθειας παραμένουν τα gates/μητρώα — αυτό είναι ΣΥΝΟΨΗ, όχι απόδειξη» (ρητή αυτο-οριοθέτηση)."
   :failure-semantics "Δεν υπάρχει· κανένας έλεγχος συνέπειας ευρετηρίου↔αρχείων."
   :operating-model "Ρητά «ΔΕΝ είναι store του runtime». Στην πράξη είναι η μόνη θέση όπου ζει η ιστορία του συστήματος, αφού history.sexp/episodes/lessons/journals είναι κενά ή ανύπαρκτα."
   :materiality "Απαντά στο «τι θυμάται»: το σύστημα ΔΕΝ θυμάται· ο ΦΑΚΕΛΟΣ θυμάται, και μόνο σε πρόζα."
   :evidence "/frozen/ro/deployment/collab/AI-DIALOGUE.md:L1-L20@sha256:d1edcd1844bb /frozen/ro/deployment/collab/STATE-OF-PLAY.md:L1-L8@sha256:d8054f835a9d")

  (:name "Ολομέλεια πυλών (gate plenary)"
   :presence :present
   :domain "Ενιαίος runner --gates με machine-readable verdict manifest (:gate-plenary/1) + gate-registry.sexp."
   :assumptions "Το runtime gate-set ταυτίζεται ΑΚΡΙΒΩΣ με το committed registry."
   :guarantees "Exact set-equality, no-dup, one-verdict/gate, :completed, πραγματικό docker-exit· 10/10 synthetic αρνητικά."
   :failure-semantics "Fail-closed στο manifest· ΑΛΛΑ ο αριθμός των πυλών διαφέρει ανά κείμενο (18/21/22/23/24/25)."
   :operating-model "Οι αριθμοί που δηλώνονται είναι ΤΟΠΙΚΕΣ εκτελέσεις — το CI δεν έχει τρέξει ποτέ πράσινο."
   :materiality "Είναι το «0 λάθος ως μηχανισμός» — και το ίδιο του το μέγεθος δεν έχει μία τιμή."
   :evidence "/frozen/ro/deployment/collab/dialogue/0096-claude.md (24) /frozen/ro/deployment/collab/dialogue/0100-claude.md:L~70 (25) /frozen/ro/deployment/collab/STATE-OF-PLAY.md:L13-L13@sha256:d8054f835a9d (22) /frozen/ro/deployment/collab/dialogue/0116-claude.md:L411-L413@sha256:2727147538b3")

  (:name "Μετρημένο μέτρο ικανότητας (capability baseline / ratchet)"
   :presence :present
   :domain "Scorecard :capability-scorecard/1 με content-addressed dataset-stamp· 25η πύλη --capability-gate."
   :assumptions "Ίδιος πληθυσμός + ίδιο dataset-stamp με το baseline, αλλιώς ρητό drift."
   :guarantees "5 νόμοι: απόν baseline ⇒ ΚΟΚΚΙΝΟ· ①μηχανή-σε-gold = 100% ΠΑΝΤΑ· ratchet κάθε μετρική ≥ baseline· η πύλη δεν γράφει ποτέ."
   :failure-semantics "Fail-closed· αποδεδειγμένο με tampered baseline και stamp drift."
   :operating-model "Committed 2026-07-21: ① 13/13=100% · ② end-to-end γείωση 8/13=61.5% · ⊕ απαιτητικό 6/11=54.5% · judge 164 αποφάσεις/1947 δοκιμές/ταβάνι 1628 (83.6%) · hit@1 24.9% · hit@5 40.6% · hit@10 48.6%."
   :materiality "Οι μόνοι αριθμοί ικανότητας που είναι κλειδωμένοι σε ratchet — και είναι μικροί (12 υποθέσεις eval)."
   :evidence "/frozen/ro/deployment/collab/dialogue/0100-claude.md:L~55-L70")

  (:name "Αυτο-περιγραφή προς τον χρήστη (self-glossary)"
   :presence :present
   :domain "~20 entries όρων του πρωτοκόλλου με :match κανονικοποιημένα υποστρώματα και :answer/:route."
   :assumptions "Αυτο-δηλωμένο: «⚠ BOOTSTRAP: χειροποίητο περιεχόμενο — σκαλωσιά, ΟΧΙ απόδειξη μάθησης»."
   :guarantees "Καμία — στατικό κείμενο απαντήσεων που επιστρέφεται όπως γράφτηκε."
   :failure-semantics "Δεν υπάρχει."
   :operating-model "Ταίριασμα υποστρώματος → σταθερό κείμενο."
   :materiality "ΕΔΩ ζουν οι ΔΗΛΩΣΕΙΣ του συστήματος για τον εαυτό του προς τον χρήστη — και εδώ βρέθηκε η πιο ευθεία ασυμφωνία δηλωμένης/αποθηκευμένης κατάστασης."
   :evidence "/frozen/ro/deployment/knowledge/self-glossary.sexp:L10-L12@sha256:c40b7a9d2690 /frozen/ro/deployment/knowledge/self-glossary.sexp:L38-L38@sha256:c40b7a9d2690")

  (:name "Ανεξάρτητος έλεγχος νοημοσύνης (self-study)"
   :presence :present
   :domain "32 ανεξάρτητοι ελεγκτές × 10 διαστάσεις, 21 σκεπτικιστές-αντίλογος, 1 κριτής πληρότητας."
   :assumptions "Κάθε ισχυρισμός φέρει αρχείο:γραμμή ή μετρημένο αριθμό."
   :guarantees "19/21 θεμελιώδη κενά ΕΠΙΒΕΒΑΙΩΘΗΚΑΝ, 2 ΑΝΑΣΚΕΥΑΣΤΗΚΑΝ."
   :failure-semantics "Δεν είναι εκτελέσιμο· είναι κείμενο."
   :operating-model "Ημερομηνία 2026-07-05 — ΠΟΤΕ δεν ενημερώθηκε παρά ~120 φάσεις μετά."
   :materiality "Είναι η πιο τίμια αυτο-καταγραφή στο repo, και τα ευρήματά της παραμένουν ανοιχτά."
   :evidence "/frozen/ro/deployment/self-study/INTELLIGENCE-AUDIT-2026-07-05.md:L1-L9@sha256:b5a3bb502fcd /frozen/ro/deployment/self-study/EXTERNAL-REVIEW-2026-07-05.md:L1-L17@sha256:5bcb7cdc60a9")

  (:name "Θεσμική χρονική μνήμη (bitemporal version-graph journals)"
   :presence :absent
   :domain "deployment/data/version-graph/ — τα append-only journals του γράφου εκδόσεων."
   :assumptions "Δηλώνονται από τον ίδιο τον χειρουργό ως «ΠΑΡΑΓΩΓΑ runtime stores ανά περιβάλλον… ΟΧΙ δεσμευμένη ιστορία»."
   :guarantees "ΚΑΜΙΑ στο commit — ο κατάλογος είναι gitignored· ο νέος τόμος evidence/version-graph/ περιέχει ΜΟΝΟ .gitkeep."
   :failure-semantics "Δεν υπάρχει τίποτα να αστοχήσει."
   :operating-model "Η «αυθεντική ιστορία» δηλώνεται ως git + provenance sidecar."
   :materiality "Το διτεμπορικό «τι ήξερα και πότε» — ο πυρήνας του CPEI — δεν παραδίδεται."
   :evidence "/frozen/ro/deployment/collab/dialogue/0109-claude.md:L74-L77@sha256:422d8e49517c /frozen/ro/.gitignore:L54-L54@sha256:7c8ebc41610b /frozen/ro/evidence/version-graph/.gitkeep")

  (:name "Εργαλεία ανθρώπινης διάγνωσης δικτύου (fek-capture · fek-diagnose)"
   :presence :present
   :domain "Ορατός Chromium που καταγράφει κάθε XHR/fetch API κλήση του search.et.gr· one-shot διαγνωστικό με screenshot."
   :assumptions "Τρέχουν από ελληνική IP του δημιουργού, ΟΧΙ από το build sandbox («I (the build sandbox) get 403 from et.gr»)."
   :guarantees "Καμία — καθαρά διαγνωστικά, καμία κρίση, καμία έξοδος στο corpus."
   :failure-semantics "Σιωπηλή: κάθε evaluate/goto τυλίγεται σε .catch(() => …)."
   :operating-model "ΕΚΤΟΣ παραγωγικού μονοπατιού· καμία αναφορά από cron/orchestrator. Απευθύνονται ρητά σε άνθρωπο («Αντίγραψε ΟΛΑ τα ‹››› blocks και στείλε τα»)."
   :materiality "Τεκμηριώνουν ότι το περιβάλλον ανάπτυξης ΔΕΝ έχει πρόσβαση στην πηγή του νόμου."
   :evidence "/frozen/ro/deployment/fek-capture.js:L1-L79@sha256:f72084e42236 /frozen/ro/deployment/fek-diagnose.js:L1-L78@sha256:766f64c5b557"))

 ;; ==========================================================================
 ;; ΑΡΧΕΣ / ΕΞΟΥΣΙΕΣ
 ;; ==========================================================================
 :authorities
 ((:name "Δημιουργός (Σταυρόπουλος Σπυρίδων / Stavropoulos Law®)"
   :what-it-can-decide "Τα πάντα: εύρος φάσης, έγκριση, merge, re-baseline goldens, ανάκληση ισχυρισμών. «Υπακούω μόνο σε εκείνον»."
   :who-can-invoke "Μόνο ο ίδιος· κάθε φάση απαιτεί ρητό «εγκρίνω X»."
   :enforcement :convention
   :evidence "/frozen/ro/deployment/self/history.sexp:L1-L1@sha256:3e0b6766e32d /frozen/ro/deployment/knowledge/self-glossary.sexp:L16-L16@sha256:c40b7a9d2690 /frozen/ro/deployment/collab/STATE-OF-PLAY.md:L69-L71@sha256:d8054f835a9d")
  (:name "Ο δημιουργός ως ΜΟΝΟΣ εκτελεστής παραγωγικών αποδείξεων"
   :what-it-can-decide "Αν κάτι έχει ΠΡΑΓΜΑΤΙΚΑ αποδειχθεί: μόνο ο owner Docker build και το CI του παράγουν γεγονός."
   :who-can-invoke "Μόνο ο ίδιος — η συνεδρία δεν έχει docker daemon ούτε actions:write (403)."
   :enforcement :os
   :evidence "/frozen/ro/deployment/collab/dialogue/0121-claude.md:L99-L108@sha256:e7a08f0666db /frozen/ro/deployment/collab/dialogue/0101-claude.md:L~10")
  (:name "cron (χρονοδρομολογητής OS)"
   :what-it-can-decide "ΠΟΤΕ τρέχει ολόκληρος ο αυτόνομος κύκλος ενημέρωσης του νόμου."
   :who-can-invoke "Όποιος έχει crontab στον host."
   :enforcement :os
   :evidence "/frozen/ro/deployment/cron-auto-update.sh:L11-L12@sha256:01231faab127 /frozen/ro/deployment/cron-auto-update.sh:L40-L44@sha256:01231faab127")
  (:name "Περιβαλλοντικές μεταβλητές ως άρχουσα διαμόρφωση"
   :what-it-can-decide "ORCHESTRATOR_CMD (ΠΟΙΟ εκτελέσιμο είναι ο πυρήνας)· DISCOVER_CMD· FEK_BLOB_BASE (ΠΟΙΟ URL είναι η πηγή του νόμου)· PCL_SIGNING_KEY (ΠΟΙΟ κλειδί υπογράφει)· AUTO_DISCOVER/AUTO_UPDATE_FETCH (αν θα γίνει καν ανανέωση)."
   :who-can-invoke "Οποιοσδήποτε μπορεί να ορίσει env στη διεργασία."
   :enforcement :none
   :evidence "/frozen/ro/deployment/cron-auto-update.sh:L14-L30@sha256:01231faab127 /frozen/ro/deployment/cron-auto-update.sh:L34-L34@sha256:01231faab127 /frozen/ro/deployment/cron-auto-update.sh:L53-L54@sha256:01231faab127 /frozen/ro/deployment/fetch-fek-by-number.sh:L18-L18@sha256:c43d47b68d1a")
  (:name "LAWMAX_OVERRIDE / --force — παράκαμψη του «Συντάγματος»"
   :what-it-can-decide "Παρακάμπτει τους συνταγματικούς ελέγχους ανά εντολή."
   :who-can-invoke "Οποιοσδήποτε με πρόσβαση στη γραμμή εντολών· απαιτείται LAWMAX_OVERRIDE_REASON."
   :enforcement :code
   :evidence "/frozen/ro/deployment/self-study/EXTERNAL-REVIEW-2026-07-05.md:L12-L12@sha256:5bcb7cdc60a9")
  (:name "Ο κάτοχος εγγραφής στο deployment/knowledge/"
   :what-it-can-decide "ΤΙ ΞΕΡΕΙ ΤΟ ΣΥΣΤΗΜΑ. Ένα αρχείο *.sexp που αλλάζει mtime/μέγεθος επανεγκαθίσταται ΖΩΝΤΑΝΑ στο επόμενο /ask, χωρίς υπογραφή, χωρίς αναμενόμενο hash, χωρίς έγκριση."
   :who-can-invoke "Οποιαδήποτε διεργασία με δικαίωμα εγγραφής στον κατάλογο."
   :enforcement :none
   :evidence "/frozen/ro/source/knowledge-packs.lisp:L105-L150@sha256:ea774f532b44 /frozen/ro/systems/orchestrator-cli/case-workspace.lisp:L40-L40@sha256:0750c6bc50e7")
  (:name "GOLDEN_WRITE — συνειδητή αναγέννηση των golden ριζών"
   :what-it-can-decide "Μεταθέτει το «αμετάβλητο» σημείο αναφοράς του corpus (π.χ. syntagma 153056b5… → 0a5ba296…)."
   :who-can-invoke "Όποιος τρέχει verify-corpus με τη μεταβλητή· δηλώνεται ως πράξη που απαιτεί επιθεώρηση δημιουργού."
   :enforcement :convention
   :evidence "/frozen/ro/deployment/collab/dialogue/0109-claude.md:L48-L50@sha256:422d8e49517c /frozen/ro/deployment/collab/dialogue/0099-claude.md:L~40")
  (:name "authority-signer (uid 11001) — η μόνη κάτοχος ιδιωτικού κλειδιού"
   :what-it-can-decide "Θα υπέγραφε τις δεσμεύσεις release· ΑΛΛΑ «αρνείται ρητά — ο admission kernel δεν υπάρχει»."
   :who-can-invoke "Μόνο η ομώνυμη υπηρεσία compose· ο verifier απορρίπτει την ΥΠΑΡΞΗ ιδιωτικού κλειδιού σε κάθε άλλη υπηρεσία, ακόμη και :ro."
   :enforcement :os
   :evidence "/frozen/ro/deployment/collab/dialogue/0125-claude.md:L47-L60@sha256:f39c3c1ce9fa /frozen/ro/deployment/collab/dialogue/0125-claude.md:L128-L129@sha256:f39c3c1ce9fa"))

 ;; ==========================================================================
 ;; ΑΝΑΛΛΟΙΩΤΑ
 ;; ==========================================================================
 :invariants
 ((:statement "content_sha256 του sidecar = SHA-256 των bytes του συνοδευόμενου αρχείου."
   :enforced-by ":code (δηλωμένο)· ΕΠΑΛΗΘΕΥΘΗΚΕ ΑΠΟ ΜΕΝΑ: 167/167 match, 0 mismatch"
   :evidence "/frozen/ro/deployment/data/decisions/areios-pagos/*.prov.json /frozen/ro/deployment/data/*_clean.json.prov.json")
  (:statement "Κάθε byte κάθε json εξηγείται πλήρως = ντετερμινιστική εξαγωγή από hash-δεμένη πηγή + δηλωμένα errata (ΜΗΔΕΝ ανεξήγητο κείμενο σε 4694 άρθρα / 6 σώματα)."
   :enforced-by ":code (dry-run επανεξαγωγή ανά σώμα)· ΠΑΡΑΒΙΑΖΕΤΑΙ από το syntagma_clean.zip — βλ. defects"
   :evidence "/frozen/ro/deployment/collab/dialogue/0109-claude.md:L90-L106@sha256:422d8e49517c")
  (:statement "Κάθε εγγραφή self-history φέρει :PREV = :HASH της προηγούμενης (SHA-256 chain)."
   :enforced-by ":none μηχανικά — «0 τεστ verify-chain»"
   :evidence "/frozen/ro/deployment/self/history.sexp:L1-L3@sha256:3e0b6766e32d /frozen/ro/deployment/collab/dialogue/0116-claude.md:L379-L379@sha256:2727147538b3")
  (:statement "Ό,τι κατεβαίνει από το δίκτυο πρέπει να αρχίζει με '%PDF-'."
   :enforced-by ":code — 4 ανεξάρτητες υλοποιήσεις (2 bash, 2 JS) + δηλωμένος έλεγχος Lisp"
   :evidence "/frozen/ro/deployment/fetch-fek.sh:L42-L42@sha256:42acffc89892 /frozen/ro/deployment/fetch-fek-by-number.sh:L36-L36@sha256:c43d47b68d1a /frozen/ro/deployment/fetch-fek.js:L45-L45@sha256:6c92f25b051b /frozen/ro/deployment/fetch-fek-by-number.js:L43-L43@sha256:2889ba9bc0aa")
  (:statement "Δύο auto-update ticks δεν τρέχουν ποτέ ταυτόχρονα."
   :enforced-by ":os (flock -n σε fd 9)"
   :evidence "/frozen/ro/deployment/cron-auto-update.sh:L40-L44@sha256:01231faab127")
  (:statement "Νέο είδος σώματος/γεγονότος/scope μπαίνει ΜΟΝΟ με εγγραφή στο μητρώο + receipt + ρητή έγκριση δημιουργού."
   :enforced-by ":convention (σχόλιο στο ίδιο το αρχείο)· ο loader επιβάλλει ΜΟΝΟ το κλειστό σύνολο, όχι τη διαδικασία έγκρισης"
   :evidence "/frozen/ro/deployment/data/body-kind-registry.sexp:L3-L4@sha256:674e35e92a98 /frozen/ro/deployment/data/instrument-kind-registry.sexp:L7-L7@sha256:07ea6fa4a572 /frozen/ro/deployment/data/scope-tag-registry.sexp:L6-L6@sha256:65e450bf14be")
  (:statement "Άκυρο πακέτο γνώσης ⇒ κρατιέται ΠΛΗΡΩΣ η προηγούμενη γνώση (καμία μισο-εγκατεστημένη γνώση)."
   :enforced-by ":code (snapshot πριν την εγκατάσταση + restore σε σφάλμα, εύρημα επιθεώρησης 05-07-2026)"
   :evidence "/frozen/ro/source/knowledge-packs.lisp:L130-L146@sha256:ea774f532b44")
  (:statement "Το ΚΕΙΜΕΝΟ των άρθρων εισέρχεται στο σώμα μόνο μέσω μίας πόρτας, με ονομαστικό waiver ανά εύρημα· blanket waiver = σφάλμα."
   :enforced-by ":code (make-version-spec / %normalize-version-spec· lock text-admission-test 19/19)"
   :evidence "/frozen/ro/deployment/collab/dialogue/0104-claude.md:L~28-L48")
  (:statement "graph fold ≡ consolidated ≡ per-article artifacts (μία και μόνη ροή κειμένου)."
   :enforced-by ":code (ΜΕΤΑΘΕΣΗ ΚΥΡΙΑΡΧΙΑΣ: article-content := in-force κείμενο του consolidated· lock text-sovereignty-test 11/11)"
   :evidence "/frozen/ro/deployment/collab/dialogue/0105-claude.md:L~20-L45")
  (:statement "Η μαθημένη κατάσταση («runtime state») δεν είναι ταυτότητα και δεν μπαίνει στο repository."
   :enforced-by ":code (.gitignore) + :convention (CLAUDE.md: git checkout -- deployment/self/history.sexp πριν από κάθε commit)"
   :evidence "/frozen/ro/.gitignore:L37-L54@sha256:7c8ebc41610b /frozen/ro/CLAUDE.md")
  (:statement "Κάθε υπηρεσία: output ro, μόνο candidates/ rw, κανένα mount του authority store, κανένα ιδιωτικό κλειδί εκτός authority-signer."
   :enforced-by ":code (producer-topology-test σε ΟΛΑ τα services, 17/0, 9 μεταλλάξεις απορρίπτονται)· ΑΛΛΑ ΑΝΕΚΤΕΛΕΣΤΟ σε πραγματικό docker"
   :evidence "/frozen/ro/deployment/collab/dialogue/0124-claude.md:L44-L65@sha256:0aac45bd3140 /frozen/ro/deployment/collab/dialogue/0125-claude.md:L53-L60@sha256:f39c3c1ce9fa")
  (:statement "Κάθε απόδειξη είναι απογεγραμμένη: αρχείο εκτός απογραφής ⇒ σφάλμα, εγγραφή χωρίς αρχείο ⇒ σφάλμα."
   :enforced-by ":code (run-authority-v2-proofs.sh έναντι committed PROOF-CENSUS.txt, αναδρομική σάρωση κάθε regular file)"
   :evidence "/frozen/ro/deployment/collab/dialogue/0122-claude.md:L~95-L105 /frozen/ro/deployment/collab/dialogue/0124-claude.md:L76-L94@sha256:0aac45bd3140")
  (:statement "Το ευρετήριο AI-DIALOGUE.md ≡ τα αρχεία dialogue/."
   :enforced-by ":none — ΜΕΤΡΗΣΑ ΠΑΡΑΒΙΑΣΗ ΚΑΙ ΣΤΙΣ ΔΥΟ ΚΑΤΕΥΘΥΝΣΕΙΣ (βλ. defects)"
   :evidence "/frozen/ro/deployment/collab/AI-DIALOGUE.md /frozen/ro/deployment/collab/dialogue/")
  (:statement "Ο διάλογος είναι append-only με μονοτονική αρίθμηση."
   :enforced-by ":convention — 7 αριθμοί λείπουν παντελώς, 1 αρχείο είναι αδήλωτο, 1 αριθμός ευρετηρίου διπλός"
   :evidence "/frozen/ro/deployment/collab/AI-DIALOGUE.md:L7-L18@sha256:d1edcd1844bb"))

 ;; ==========================================================================
 ;; ΕΛΑΤΤΩΜΑΤΑ
 ;; ==========================================================================
 :defects
 (;; --- Α. ΔΗΛΩΜΕΝΗ vs ΑΠΟΘΗΚΕΥΜΕΝΗ ΚΑΤΑΣΤΑΣΗ ---
  (:what "ΤΟ ΓΛΩΣΣΑΡΙ ΛΕΕΙ ΣΤΟΝ ΧΡΗΣΤΗ ΚΑΤΙ ΨΕΥΔΕΣ. Ο όρος «Καταγράφηκε» ορίζεται ρητά ως «γράφτηκε μόνιμα σε ΔΥΟ μνήμες μου — deployment/state/lessons.jsonl … και deployment/self/episodes.sexp (το βιωματικό μου ρεύμα, με αλυσίδα SHA-256)». ΚΑΝΕΝΑ από τα δύο αρχεία δεν υπάρχει (find σε ΟΛΟ το /frozen/ro: 0 ευρήματα)· και τα δύο είναι ρητά gitignored· και ο νέος τόμος evidence/self/ περιέχει μόνο .gitkeep."
   :severity :p0 :evidence "/frozen/ro/deployment/knowledge/self-glossary.sexp:L38-L38@sha256:c40b7a9d2690 /frozen/ro/.gitignore:L40-L40@sha256:7c8ebc41610b /frozen/ro/.gitignore:L47-L47@sha256:7c8ebc41610b /frozen/ro/evidence/self/.gitkeep /frozen/ro/deployment/self-study/INTELLIGENCE-AUDIT-2026-07-05.md:L278-L278@sha256:b5a3bb502fcd" :is-it-in-the-known-defect-list :yes)

  (:what "ΔΕΥΤΕΡΗ ΑΠΟΘΗΚΕΥΜΕΝΗ ΑΛΗΘΕΙΑ ΤΟΥ ΣΥΝΤΑΓΜΑΤΟΣ, ΑΝΕΞΗΓΗΤΗ ΚΑΙ ΑΔΕΣΜΕΥΤΗ. Το deployment/data/syntagma_clean.zip περιέχει ΑΛΛΟ syntagma_clean.json: 300.125 bytes έναντι 296.482 του ζωντανού, sha256 74e7c84e… έναντι b64b3cec…. ΜΕΤΡΗΣΑ: 124/124 άρθρα διαφέρουν, 9/124 τίτλοι διαφέρουν, και το πεδίο date είναι 14/03/1986 έναντι 11/06/1975 του ζωντανού — άλλη αναθεώρηση του Συντάγματος. ΔΕΝ έχει .prov.json, ΔΕΝ έχει content_sha256, ΔΕΝ έχει errata, ΔΕΝ έχει source_digest, και ΔΕΝ αναφέρεται από ΚΑΝΕΝΑ αρχείο σε ΟΛΟΚΛΗΡΟ το repository (grep -rl: 0 ευρήματα). Αντιφάσκει ευθέως με την ετυμηγορία [0109γ] «ΜΗΔΕΝ ανεξήγητο κείμενο σε 4694 άρθρα / 6 σώματα» και με τον δηλωμένο «θάνατο της δεύτερης αλήθειας εισόδου» [0110]."
   :severity :p0 :evidence "/frozen/ro/deployment/data/syntagma_clean.zip /frozen/ro/deployment/data/syntagma_clean.json.prov.json:L1-L1@sha256:ada4e0aa5541 /frozen/ro/deployment/collab/dialogue/0109-claude.md:L103-L106@sha256:422d8e49517c /frozen/ro/deployment/collab/dialogue/0109-claude.md:L108-L113@sha256:422d8e49517c" :is-it-in-the-known-defect-list :no)

  (:what "Η αυτοβιογραφική μνήμη έχει 3 ΜΟΝΟ εγγραφές, ΟΛΕΣ με ταυτόσημο timestamp — το σύστημα δεν έχει καταγράψει ΚΑΜΙΑ εμπειρία μετά τη γέννησή του, παρότι το repo δείχνει 125 φάσεις διαλόγου, 22-25 πύλες, δεκάδες owner runs. Και ο μόνιμος νόμος του δημιουργού επιβάλλει `git checkout -- deployment/self/history.sexp` ΠΡΙΝ ΑΠΟ ΚΑΘΕ COMMIT — η μνήμη επαναφέρεται δομικά."
   :severity :p0 :evidence "/frozen/ro/deployment/self/history.sexp:L1-L3@sha256:3e0b6766e32d /frozen/ro/CLAUDE.md /frozen/ro/deployment/self-study/INTELLIGENCE-AUDIT-2026-07-05.md:L303-L303@sha256:b5a3bb502fcd" :is-it-in-the-known-defect-list :yes)

  (:what "ΟΛΗ η μαθημένη/υιοθετημένη κατάσταση είναι gitignored ως «LAWMAX runtime state (not identity)»: episodes.sexp, proposals.sexp, graph-snapshot.sexp, policies.sexp, adoptions.sexp, lessons.jsonl, failure-ledger.jsonl, amendment-laws.json, data/version-graph/. Το repository μεταφέρει ΜΟΝΟ τη χειροποίητη σκαλωσιά. ΜΕΤΡΗΣΑ επιπλέον: 11 δηλωμένα knowledge kinds, 7 πακέτα στον δίσκο — τα 4 που λείπουν (:concept-grounding :understanding-rules :decision-grammar :guard-ops) είναι ΑΚΡΙΒΩΣ τα προϊόντα της μάθησης."
   :severity :p0 :evidence "/frozen/ro/.gitignore:L37-L54@sha256:7c8ebc41610b /frozen/ro/source/knowledge-packs.lisp (define-knowledge-kind ×11) /frozen/ro/deployment/knowledge/ (7 αρχεία)" :is-it-in-the-known-defect-list :no)

  (:what "Ο ίδιος ο ΕΛΕΓΧΟΣ ΝΟΗΜΟΣΥΝΗΣ δίνει ΤΡΕΙΣ διαφορετικούς αριθμούς για το ΙΔΙΟ σώμα νομολογίας: «165 αποφάσεις» (11 φορές), «161 αποφάσεις» (5 φορές), «322 αποφάσεις ΑΠ» (1 φορά — ακριβώς στη σύγκριση με Harvey/Lexis+AI). ΜΕΤΡΗΣΑ στον δίσκο: 161 areios-pagos + 2 efeteio-peiraios + 1 protodikeio-athinon = 164. Το «322» = 2×161, δηλαδή μετράει τα .prov.json sidecars ως αποφάσεις — ο αριθμός που φουσκώνει είναι ακριβώς ο αριθμός-βιτρίνα."
   :severity :p1 :evidence "/frozen/ro/deployment/self-study/INTELLIGENCE-AUDIT-2026-07-05.md:L447-L447@sha256:b5a3bb502fcd /frozen/ro/deployment/self-study/INTELLIGENCE-AUDIT-2026-07-05.md:L551-L551@sha256:b5a3bb502fcd /frozen/ro/deployment/data/decisions/" :is-it-in-the-known-defect-list :no)

  (:what "Ο ΑΡΙΘΜΟΣ ΤΩΝ ΠΥΛΩΝ — το ίδιο το μέτρο του «0 λάθος» — δεν έχει μία τιμή: 18 (OMEGA), 21 (CROSSWALK), 22 (STATE-OF-PLAY πίνακας «τελευταία μετρημένη»), 23 (THREAT-MODEL· και ρητό blocking εύρημα [0029] «stale 22 ενώ 23»), 24 (gate-registry στο [0096]), 25 (κώδικας/[0100]/[0116])."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L411-L413@sha256:2727147538b3 /frozen/ro/deployment/collab/STATE-OF-PLAY.md:L13-L13@sha256:d8054f835a9d /frozen/ro/deployment/collab/dialogue/0100-claude.md" :is-it-in-the-known-defect-list :yes)

  (:what "Ασυμφωνία ισχυρισμού-κώδικα στην αυτο-περιγραφή: docstrings δηλώνουν αυτονομία δαίμονα και «η σύνθεση διαβάζει την αρένα» ενώ ο κώδικας δεν το κάνει — «σε σύστημα που καυχιέται ότι το αυτο-μοντέλο ΕΙΝΑΙ ο κώδικας, αυτό είναι ακριβώς το είδος απόκλισης που το σύνταγμά του απαγορεύει»."
   :severity :p1 :evidence "/frozen/ro/deployment/self-study/INTELLIGENCE-AUDIT-2026-07-05.md:L517-L523@sha256:b5a3bb502fcd" :is-it-in-the-known-defect-list :yes)

  (:what "ΚΑΜΙΑ ΠΕΙΘΑΡΧΙΑ SUPERSESSION μεταξύ κειμένων: TEMPORAL-SEMANTICS δηλώνει «Π2-Π7 ΠΑΓΩΜΕΝΑ» ενώ Π2-Π6 είναι υλοποιημένα ΚΑΙ gated· IDENTITY-DESIGN αντιφάσκει με spec+υλοποίηση σε τύπο αλυσίδας (sha256(prev‖record-id) vs sha256(prev‖0x1F‖payload-hash)) ΚΑΙ σε μορφή αρχείου (jsonl vs sexp)· CPEI δηλώνει το transaction-time «λείπει» ενώ το TEMPORAL το θεμελιώνει ως υλοποιημένο· ΕΠΤΑ ασυντόνιστα συστήματα αρίθμησης φάσεων (Φ, Π, P0, L) με συγκρούσεις συμβόλων. Το ίδιο το CPEI L10 ονομάζει αυτόν τον κίνδυνο «διπλή αλήθεια»."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L396-L413@sha256:2727147538b3" :is-it-in-the-known-defect-list :yes)

  ;; --- Β. ΨΕΥΔΕΙΣ / ΑΝΑΚΛΗΘΕΙΣΕΣ ΕΓΓΥΗΣΕΙΣ ---
  (:what "ΤΟ ΔΗΜΟΣΙΟ PCL-1 SPEC ΔΙΔΑΣΚΕΙ ΛΑΘΟΣ MERKLE — «odd node paired with itself», δηλαδή η κλάση CVE-2012-2459 — που ο κώδικας ΔΕΝ κάνει· το ίδιο και το deployment/verify/README.md («the algorithm so you can re-implement it»). Τρίτος που αναϋπολογίζει τη ρίζα από τα δημόσια κείμενα παίρνει ΛΑΘΟΣ ρίζα, υπονομεύοντας την ίδια την αρχή «recompute without trusting us». (Η ίδια κλάση χρησιμοποιείται εσωτερικά ως μετάλλαξη M3 και σκοτώνεται — άρα είναι γνωστή ως λάθος.)"
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L415-L420@sha256:2727147538b3 /frozen/ro/deployment/collab/dialogue/0122-claude.md (M3)" :is-it-in-the-known-defect-list :yes)

  (:what "ΕΓΓΥΗΣΗ ΑΝΘΕΚΤΙΚΟΤΗΤΑΣ ΨΕΥΔΗΣ: η μετάλλαξη fsync→no-op ΕΠΙΒΙΩΝΕΙ· το receipt βγαίνει :durable με ΜΟΝΟ κριτήριο την επιτυχία του with-open-file· «0 τεστ σε όλο το tests/ αναφέρουν fsync»· και το fsync είναι ήδη μέσα σε ignore-errors."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L365-L368@sha256:2727147538b3" :is-it-in-the-known-defect-list :yes)

  (:what "ΑΝΑΚΛΗΣΗ ΘΕΜΕΛΙΩΔΟΥΣ ΕΓΓΥΗΣΗΣ: ο ισχυρισμός «η απόκλιση της Merkle έδρας είναι δομικά αδύνατη» ΑΠΟΣΥΡΘΗΚΕ ΟΡΙΣΤΙΚΑ όταν ο δημιουργός έδειξε μετάλλαξη που κάνει λάθος μόνο σε δέντρο n=18 και πέρασε και τους 22 ελέγχους της verify_merkle_seat(). Καταγράφεται πλέον ως RETRACTED_CLAIMS μέσα στον κώδικα. Υποβαθμίστηκε σε «ισχυρή ανίχνευση, όχι φέρουσα απόδειξη». Μαζί ανακλήθηκαν οι τίτλοι «IMMUTABLE CANDIDATE» / «IMMUTABLE RELEASE DIRECTORY»."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0123-claude.md:L12-L23@sha256:afa8d725693e /frozen/ro/deployment/collab/dialogue/0123-claude.md:L54-L54@sha256:afa8d725693e" :is-it-in-the-known-defect-list :yes)

  (:what "Επιβίωση μεταλλάξεων ≈45%: από 22 ονομαστικές μεταλλάξεις της μηχανής σε 8 κλάσεις, 12 σκοτώνονται και 10 ΕΠΙΒΙΩΝΟΥΝ — μετρημένο χάσμα από το «0 λάθος ως μηχανισμός». Μεταξύ των επιζώντων: αφαίρεση ΟΛΩΝ των semantic-③ ελέγχων του replay· σιωπηλή αφαίρεση σουίτας με ΜΙΑ γραμμή στο standalone-suite-exclusions.txt· verify-canonical.py/verify-temporal.py «return true» (μηδέν αρνητικά fixtures)· payload-hash που «ξεχνά» πεδίο."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L348-L351@sha256:2727147538b3 /frozen/ro/deployment/collab/dialogue/0116-claude.md:L363-L390@sha256:2727147538b3" :is-it-in-the-known-defect-list :yes)

  (:what "Από 89 δεσμευτικά invariants των 6 specs: 54 ΑΠΟΔΕΔΕΙΓΜΕΝΑ, 14 ΑΝΕΛΕΓΚΤΑ (δηλωμένα χωρίς κανένα τεστ), 3 εκτός αλυσίδας, 18 μελλοντικά — 54/71 ≈ 76% των ΕΝΕΡΓΩΝ δεσμεύσεων αποδεικνύεται μηχανικά."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L344-L348@sha256:2727147538b3" :is-it-in-the-known-defect-list :yes)

  ;; --- Γ. ΨΕΥΔΟ-ΠΡΑΣΙΝΑ / ΤΑΥΤΟΛΟΓΙΕΣ ---
  (:what "ΑΥΤΟ-ΟΜΟΛΟΓΙΑ ΨΕΥΔΟΚΛΕΙΣΤΩΝ ΔΙΑΔΡΟΜΩΝ, με τα λόγια του ίδιου του υλοποιητή: «Έγραφα ελεγκτές των οποίων ΕΓΩ όριζα το εύρος. Ο topology verifier κοίταζε services.producer — ακριβώς εκεί όπου ήξερα ότι θα βρω το σωστό… Ένας ελεγκτής που διαλέγει πού θα κοιτάξει δεν ελέγχει· επιβεβαιώνει.» και «άλλαξα το compose χωρίς να μπορώ να τρέξω τον αγωγό… σε αυτό το περιβάλλον δεν μπορώ να επιβεβαιώσω τίποτε παραγωγικό»."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0125-claude.md:L4-L21@sha256:f39c3c1ce9fa /frozen/ro/deployment/collab/dialogue/0124-claude.md:L44-L51@sha256:0aac45bd3140" :is-it-in-the-known-defect-list :yes)

  (:what "ΚΥΚΛΙΚΟ ORACLE: τα golden vectors παράγονταν από την ΙΔΙΑ έδρα (orchestrator.merkle) που επαληθεύουν — «αν η έδρα ήταν λάθος, τα vectors θα κωδικοποιούσαν το λάθος και ΚΑΘΕ έλεγχος θα ήταν πράσινος». Το δεύτερο «ανεξάρτητο» by-segments ήταν ΑΝΤΙΓΡΑΦΟ με ΨΕΥΔΗ docstring «bottom-up»· τα inclusion-path/consistency-proof έβγαιναν ΑΠΟΚΛΕΙΣΤΙΚΑ από την production έδρα."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0119-claude.md:L18-L21@sha256:b74f89bd38f7 /frozen/ro/deployment/collab/dialogue/0120-claude.md:L13-L17@sha256:e1bebfdda643" :is-it-in-the-known-defect-list :yes)

  (:what "ΨΕΥΔΟ-ΠΡΑΣΙΝΗ ΠΥΛΗ ΜΕΤΑΛΛΑΞΕΩΝ: killed = (code != 0) μετρούσε το -1 (ΑΠΟΝ εργαλείο) ως φόνο — μετάλλαξη που δεν εκτελέστηκε ποτέ καταγραφόταν ως σκοτωμένη."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0119-claude.md:L30-L39@sha256:b74f89bd38f7" :is-it-in-the-known-defect-list :yes)

  (:what "ΤΟ ΚΡΥΠΤΟΓΡΑΦΙΚΟ PROFILE ΗΤΑΝ ΑΔΡΑΝΕΣ: :leaf-prefix-byte, :node-prefix-byte, :hash-algorithm, :hash-representation, :mutation-witnesses ΟΛΑ αγνοούνταν — ο generator hardcode-αρε #(0)/#(1)/:sha256 και το harness είχε δική του λίστα μαρτύρων. Το ακριβές σενάριο του κριτή («άλλαξε μόνο το profile ⇒ έμενε πράσινο») ίσχυε."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0120-claude.md:L39-L58@sha256:e1bebfdda643" :is-it-in-the-known-defect-list :yes)

  (:what "ΔΥΟ ΕΔΡΕΣ MERKLE ΦΥΛΛΟΥ ΣΤΟ ΣΤΡΩΜΑ ΑΥΘΕΝΤΙΑΣ (ΙΣΤΟΡΙΚΟ — ΚΛΕΙΣΤΟ ΣΤΟ ΠΑΓΩΜΕΝΟ COMMIT): κατά το δελτίο [0122] η capture.py (γρ. 230 ΤΟΤΕ) υπολόγιζε SHA256(0x00 ‖ SHA256(bytes)) ενώ η παραγωγική hash-leaf-file υπολογίζει SHA256(0x00 ‖ ΩΜΑ BYTES) — ασύμβατο· βρέθηκε από τον δημιουργό, όχι από πύλη. ΕΠΑΛΗΘΕΥΣΑ ΣΤΟ ΠΑΓΩΜΕΝΟ ΑΡΧΕΙΟ: η διόρθωση υπάρχει — ο κανόνας φύλλου δηλώνεται πλέον ρητά ως «leaf = SHA-256(0x00 ‖ ΩΜΑ BYTES)» και η ανάκληση του ισχυρισμού ζει ως RETRACTED_CLAIMS μέσα στον κώδικα. Η γραμμή 230 ΔΕΝ φέρει πλέον το σφάλμα."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0122-claude.md:L~18-L30 /frozen/ro/authority-v2/capture/capture.py:L176-L176@sha256:9593561c6c06 /frozen/ro/authority-v2/capture/capture.py:L85-L85@sha256:9593561c6c06 /frozen/ro/authority-v2/capture/capture.py:L33-L33@sha256:9593561c6c06" :is-it-in-the-known-defect-list :yes)

  (:what "5 ταυτολογικά «deterministic» tests (f(x)=f(x) στην ίδια διεργασία)· και το αρνητικό fixture του ίδιου του verify-proof-manifest.py ΥΠΑΡΧΕΙ αλλά είναι ΟΡΦΑΝΟ (0 αναφορές σε CI/Dockerfile)."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L181-L181@sha256:2727147538b3 /frozen/ro/deployment/collab/dialogue/0116-claude.md:L388-L390@sha256:2727147538b3" :is-it-in-the-known-defect-list :yes)

  ;; --- Δ. ΣΙΩΠΗΛΑ FALLBACKS ---
  (:what "284 ignore-errors σε 94 αρχεία· 52 στη μορφή σιωπηλού default (or (ignore-errors …) τιμή). Χειρότερο: semantic-authority.lisp — αν πέσει η έδρα URIs, εκπέμπεται authority RDF με hardcoded fallback URLs σε 6 σημεία ΑΝΤΙ ΣΦΑΛΜΑΤΟΣ. Σιωπηλό fallback ΜΕΣΑ στο μονοπάτι αυθεντίας."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L167-L172@sha256:2727147538b3" :is-it-in-the-known-defect-list :yes)

  (:what "cron-auto-update.sh: κάθε βήμα discovery/routing/amendments αποτυγχάνει με '|| log …(continuing)' και ο κύκλος τυπώνει «=== tick OK — all codes clean, signed proofs reissued ===» ενώ η ανακάλυψη μπορεί να έχει αποτύχει ολοσχερώς. Η απουσία listing αντιμετωπίζεται ως «refresh όλων», όχι ως σφάλμα."
   :severity :p0 :evidence "/frozen/ro/deployment/cron-auto-update.sh:L59-L73@sha256:01231faab127 /frozen/ro/deployment/cron-auto-update.sh:L81-L82@sha256:01231faab127" :is-it-in-the-known-defect-list :no)

  (:what "metrics-stub no-op ΜΕΣΑ στο build καταπίνει το record-error-event — τα FRBR error events χάνονται σιωπηλά."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L178-L180@sha256:2727147538b3" :is-it-in-the-known-defect-list :yes)

  (:what "Οι πύλες γνώσης δεν είναι fail-closed προς τον καλούντα: άκυρο πακέτο τυπώνει «ΑΠΟΡΡΙΦΘΗΚΕ (κρατιέται η προηγούμενη γνώση)» στο stdout και ο κύκλος συνεχίζει — το σύστημα απαντά με ΣΙΩΠΗΛΑ ΠΑΛΙΑ γνώση."
   :severity :p1 :evidence "/frozen/ro/source/knowledge-packs.lisp:L146-L150@sha256:ea774f532b44" :is-it-in-the-known-defect-list :no)

  ;; --- Ε. ΔΙΚΤΥΟ / CORPUS ΡΙΖΑ ---
  (:what "ΚΑΜΙΑ ΔΕΣΜΕΥΣΗ ΜΕΤΑΞΥ ΖΗΤΟΥΜΕΝΟΥ ΚΑΙ ΛΗΦΘΕΝΤΟΣ ΕΓΓΡΑΦΟΥ: ο fetcher βρίσκει «το πρώτο <a> που μοιάζει με .pdf ή περιέχει λήψη/download/pdf/φεκ» και το μόνο κριτήριο αποδοχής είναι τα magic bytes '%PDF-'. Οποιοδήποτε PDF στη σελίδα γίνεται «το γράμμα του νόμου με ταυτότητα SHA-256»."
   :severity :p0 :evidence "/frozen/ro/deployment/fetch-fek.js:L81-L94@sha256:6c92f25b051b /frozen/ro/deployment/fetch-fek-by-number.js:L108-L121@sha256:2889ba9bc0aa" :is-it-in-the-known-defect-list :no)

  (:what "ΕΝΕΡΓΗΤΙΚΗ ΑΠΟΦΥΓΗ ANTI-BOT ΣΕ ΚΡΑΤΙΚΟ ΙΣΤΟΤΟΠΟ (Εθνικό Τυπογραφείο): εναλλαγή 5 User-Agent ανά προσπάθεια, jitter στο viewport ώστε «το fingerprint να μην είναι ταυτόσημο», μασκάρισμα navigator.webdriver/languages/plugins και window.chrome, --disable-blink-features=AutomationControlled, in-session fetch με credentials:'include' για να «μεταφερθούν τα cookies που έθεσε το anti-bot». Ο σχολιασμός το ονομάζει ρητά «ANTI-BOT STRATEGY» και «anti-bot bypass»."
   :severity :p1 :evidence "/frozen/ro/deployment/fetch-fek.sh:L13-L20@sha256:42acffc89892 /frozen/ro/deployment/fetch-fek.sh:L34-L40@sha256:42acffc89892 /frozen/ro/deployment/fetch-fek.js:L3-L10@sha256:6c92f25b051b /frozen/ro/deployment/fetch-fek.js:L39-L41@sha256:6c92f25b051b /frozen/ro/deployment/fetch-fek.js:L51-L51@sha256:6c92f25b051b /frozen/ro/deployment/fetch-fek.js:L62-L68@sha256:6c92f25b051b /frozen/ro/deployment/fetch-fek.js:L88-L92@sha256:6c92f25b051b /frozen/ro/deployment/discover-fek.js:L108-L108@sha256:69c52b81a4ea /frozen/ro/deployment/fetch-fek-by-number.js:L49-L49@sha256:2889ba9bc0aa /frozen/ro/deployment/fetch-fek-by-number.js:L57-L61@sha256:2889ba9bc0aa /frozen/ro/deployment/fetch-fek-by-number.js:L116-L119@sha256:2889ba9bc0aa" :is-it-in-the-known-defect-list :no)

  (:what "Το corpus πιθανόν STALE ως προς ισχύον δίκαιο: ΑΚ/ΚΠολΔ έναντι Ν.5221/2025 (ΦΕΚ Α΄133, ισχύς ΗΔΗ από 1/1/2026) και Ν.5303/2026 (Α΄81, νέο κληρονομικό, ισχύς 16/9/2026) — «ΕΠΙΒΕΒΑΙΩΜΕΝΑ από 2 ανεξάρτητες έρευνες». Το ΚΕΙΜΕΝΟ δεν ενσωματώθηκε ποτέ: ΟΛΕΣ οι οδοί απόκτησης επιστρέφουν 403 (Azure blob, et.gr, WebFetch). Ο κατάλογος των θιγόμενων άρθρων του 5221 είναι ΑΓΝΩΣΤΟΣ· του 5303/kpolitikis ρητά μερικός («975…»)."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/STATE-OF-PLAY.md:L50-L51@sha256:d8054f835a9d /frozen/ro/deployment/collab/dialogue/0099-claude.md:L~10-L20,L~60-L66" :is-it-in-the-known-defect-list :yes)

  (:what "336 από 4694 άρθρα (7.2%) του αποθηκευμένου νομικού κειμένου φέρουν ASCII εισαγωγικά αντί ελληνικών — ΜΕΤΡΗΣΑ ΑΝΕΞΑΡΤΗΤΑ: astikos 137, kpolitikis 130, kpoinikis 32, kdioikitikis 25, poinikos 12, syntagma 0 (ταυτόσημο με το [0104]). Εισήλθαν με bootstrap waiver: journaled ως παρατήρηση, ΟΧΙ διορθωμένα."
   :severity :p1 :evidence "/frozen/ro/deployment/data/*_clean.json /frozen/ro/deployment/collab/dialogue/0104-claude.md:L~10-L18" :is-it-in-the-known-defect-list :yes)

  (:what "Το prov sidecar φέρει source_digest αλλά ΚΑΜΙΑ source_url, ΚΑΜΙΑ ημερομηνία λήψης, ΚΑΜΙΑ υπογραφή — το digest της πηγής είναι ΟΡΦΑΝΟ: δεν μπορεί να αντιπαραβληθεί με τίποτα εκτός συστήματος. Επιπλέον το content_sha256 σφραγίζει το ΜΕΤΑ-errata κείμενο, άρα οι χειροκίνητες παρεμβάσεις δεν είναι ανεξάρτητα ελέγξιμες."
   :severity :p1 :evidence "/frozen/ro/deployment/data/decisions/areios-pagos/ap_2015_1.json.prov.json:L1-L1@sha256:f7fa68b791e2 /frozen/ro/deployment/data/astikos_clean.json.prov.json:L1-L1@sha256:88ec4f8cb992" :is-it-in-the-known-defect-list :no)

  (:what "fetch-fek-by-number.sh ΔΕΝ διαγράφει το μη-PDF αρχείο εξόδου σε αποτυχία (σε αντίθεση με /frozen/ro/deployment/fetch-fek.sh:L79-L79@sha256:42acffc89892) — αφήνει HTML anti-bot σελίδα ή error body στη θέση του PDF."
   :severity :p1 :evidence "/frozen/ro/deployment/fetch-fek-by-number.sh:L32-L45@sha256:c43d47b68d1a /frozen/ro/deployment/fetch-fek.sh:L78-L80@sha256:42acffc89892" :is-it-in-the-known-defect-list :no)

  ;; --- ΣΤ. SHELL / PYTHON ΣΕ ΣΥΣΤΗΜΑ «100% COMMON LISP» ---
  (:what "ΜΝΗΜΕΙΩΔΗΣ ΑΝΤΙΦΑΣΗ ΜΕ ΤΟ «100% Common Lisp, zero Python, zero shell orchestration in the trusted path», σε ΤΡΙΑ ΑΝΕΞΑΡΤΗΤΑ ΣΤΡΩΜΑΤΑ: (α) cron-auto-update.sh είναι Ο ΕΝΟΡΧΗΣΤΡΩΤΗΣ ολόκληρου του αυτόνομου κύκλου και ο Lisp πυρήνας υποδιεργασία του· (β) ο αντίπαλος βρήκε «χαμένη κλάση OS shell-exec (document-fetch /bin/sh -c, 19 sites)» ΜΕΣΑ στον Lisp πυρήνα, αναβλημένη σε Phase 5/6 και ΜΗ ΚΛΕΙΣΜΕΝΗ· (γ) το νεότερο, ανώτατης εμπιστοσύνης στρώμα release/capture/authority είναι Python + Node: «εκτός-TCB αυθεντία = py/mjs», capture.py (η ίδια η Merkle δέσμευση), verify-proof-manifest.py, verify-canonical.py, verify-temporal.py, verify-release.py, verify-authority-bundle.py, verify-merkle.py/.mjs, verify.py/.mjs, run-proofs.sh, ceremony.sh, legacy-snapshot.py, build-adoption-certificate.py, run-standalone-suites.sh, merkle-mutation-witness.sh."
   :severity :p0 :evidence "/frozen/ro/deployment/cron-auto-update.sh:L46-L86@sha256:01231faab127 /frozen/ro/deployment/collab/STATE-OF-PLAY.md:L125-L127@sha256:d8054f835a9d /frozen/ro/deployment/collab/STATE-OF-PLAY.md:L328-L330@sha256:d8054f835a9d /frozen/ro/deployment/collab/STATE-OF-PLAY.md:L344-L346@sha256:d8054f835a9d /frozen/ro/deployment/collab/dialogue/0124-claude.md:L86-L88@sha256:0aac45bd3140 /frozen/ro/deployment/collab/dialogue/0124-claude.md:L109-L109@sha256:0aac45bd3140 /frozen/ro/deployment/collab/dialogue/0123-claude.md:L79-L88@sha256:afa8d725693e" :is-it-in-the-known-defect-list :yes)

  (:what "Η capture.py — η υλοποίηση που παράγει τη Merkle δέσμευση κάθε release — δηλώνεται «υλοποίηση αναφοράς σε Python, ΟΧΙ ο τελικός formally-verified checker» και «ο production writer παραμένει απενεργοποιημένος»."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0123-claude.md:L100-L101@sha256:afa8d725693e /frozen/ro/deployment/collab/dialogue/0122-claude.md (ΤΙ ΔΕΝ ΔΗΛΩΝΕΤΑΙ)" :is-it-in-the-known-defect-list :yes)

  (:what "CI false-green από shell: το πρότυπο `| tee … || true; ${PIPESTATUS[0]}` αντικαθιστούσε το PIPESTATUS με (0) ΑΚΡΙΒΩΣ όταν το docker αποτύγχανε (materialization + authoritative plenary). Αποδείχθηκε: BUGGY status=0, FIXED status=7."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0095-claude.md:L~66-L72" :is-it-in-the-known-defect-list :yes)

  ;; --- Ζ. ΑΠΟΔΕΙΞΗ / CI ---
  (:what "ΤΟ CI ΔΕΝ ΕΧΕΙ ΤΡΕΞΕΙ ΠΟΤΕ ΠΡΑΣΙΝΟ. Μετρημένο μέσω API: «2 runs, 2026-01-06, main, και τα ΔΥΟ failure»· τα push της συνεδρίας δεν πυροδοτούν Actions (0 runs στον κλάδο)· workflow_dispatch ⇒ 403 «Resource not accessible by integration». ΟΛΟΙ οι αριθμοί όλων των πυλών σε ΟΛΑ τα δελτία είναι ΤΟΠΙΚΕΣ εκτελέσεις χωρίς ανεξάρτητη επιβεβαίωση."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0120-claude.md:L112-L124@sha256:e1bebfdda643 /frozen/ro/deployment/collab/dialogue/0120-claude.md:L160-L178@sha256:e1bebfdda643 /frozen/ro/deployment/collab/dialogue/0121-claude.md:L99-L108@sha256:e7a08f0666db" :is-it-in-the-known-defect-list :yes)

  (:what "Το job ci-integrity-selfcheck καλούσε sbcl ΧΩΡΙΣ να το εγκαθιστά — «τα βήματα Merkle έσκαγαν, η πύλη δεν έτρεξε ΠΟΤΕ πράσινη». Και οι πύλες έτρεχαν ΜΟΝΟ στο main — «κάθε κλάδος έφτανε στη συγχώνευση ΑΝΕΛΕΓΚΤΟΣ»."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0119-claude.md:L93-L97@sha256:b74f89bd38f7" :is-it-in-the-known-defect-list :yes)

  (:what "Η ΤΕΛΕΥΤΑΙΑ δηλωμένη κατάσταση του παγωμένου commit είναι ΡΗΤΑ ΑΤΕΛΗΣ: run-proofs exit 3 = «14 passed / 0 failed / 1 BLOCKED — ΑΤΕΛΕΣ, όχι pass»· Docker daemon ΑΠΩΝ· CI 0 runs· «Δ2/Δ3 = IMPLEMENTED-NOT-PROVED. Ούτε CLOSED ούτε PROVED»· Level-7 gate :not-passed· «Δ4–Δ9 δεν αγγίχτηκαν»· «ο admission kernel δεν υπάρχει»."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0125-claude.md:L106-L131@sha256:f39c3c1ce9fa" :is-it-in-the-known-defect-list :yes)

  (:what "ΔΕΝ ΥΠΑΡΧΟΥΝ εξωτερικά παγωμένα test vectors για το Merkle: «BLOCKED… Η πολιτική δικτύου απορρίπτει (403) rfc-editor/sqlite/github»· ο oracle «μοιράζεται συγγραφέα με την έδρα»· ο ισχυρισμός «επαληθεύτηκε έναντι τρίτου» ΔΕΝ εκφέρεται. Άγκυρα: μόνο 2 δημοσιευμένες σταθερές (FIPS 180-4 KAT, RFC 9162 MTH({}))."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0121-claude.md:L17-L33@sha256:e7a08f0666db /frozen/ro/deployment/collab/dialogue/0121-claude.md:L123-L126@sha256:e7a08f0666db /frozen/ro/deployment/collab/dialogue/0120-claude.md:L142-L145@sha256:e1bebfdda643" :is-it-in-the-known-defect-list :yes)

  (:what "Η ΠΡΑΞΗ ΕΓΚΡΙΣΗΣ owner proof #5 είναι ΚΕΝΗ ΦΟΡΜΑ στο παγωμένο commit: git_head, image_digest, standalone_proof_sha256, verifier_proof_sha256, runtime_assets_sha256, ημερομηνία/υπογραφή — όλα υπογραμμίσεις. Το ίδιο το κείμενο ορίζει «ΜΟΝΟ τότε ξεκινά το #4», ενώ το ευρετήριο δηλώνει το #4 ΟΛΟΚΛΗΡΩΜΕΝΟ («ΠΡΑΣΙΝΟ owner Docker proof @ 478f8708»)."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/APPROVAL-ACT-F7-HARDENING.md:L30-L40@sha256:c2bb4fc84502 /frozen/ro/deployment/collab/AI-DIALOGUE.md (γραμμή 92+)" :is-it-in-the-known-defect-list :no)

  ;; --- Η. ΑΚΕΡΑΙΟΤΗΤΑ ΤΟΥ ΙΔΙΟΥ ΤΟΥ ΑΡΧΕΙΟΥ ΔΙΑΛΟΓΟΥ ---
  (:what "Το ευρετήριο AI-DIALOGUE.md ΔΕΝ αντιστοιχεί στα αρχεία, ΚΑΙ ΣΤΙΣ ΔΥΟ ΚΑΤΕΥΘΥΝΣΕΙΣ. ΜΕΤΡΗΣΑ: 124 γραμμές ευρετηρίου για 113 αρχεία· ο αριθμός 12 εμφανίζεται ΔΥΟ φορές με το ΙΔΙΟ αρχείο και ΔΙΑΦΟΡΕΤΙΚΟ θέμα· το dialogue/0062-claude.md ΥΠΑΡΧΕΙ αλλά ΔΕΝ έχει καμία γραμμή ευρετηρίου (και ο αριθμός 62 λείπει από τη σειρά)· η αρίθμηση ευρετηρίου έχει αποκλίνει από την αρίθμηση αρχείων (γραμμή #116 → αρχείο 0125)· χρησιμοποιούνται μη-ακέραια, μη-ταξινομήσιμα αναγνωριστικά «90+», «92+», «93+», «93++», «93+++», «93++++»."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/AI-DIALOGUE.md:L7-L26@sha256:d1edcd1844bb /frozen/ro/deployment/collab/dialogue/0062-claude.md:L1-L1@sha256:a89d263cc2cd" :is-it-in-the-known-defect-list :no)

  (:what "Επτά αριθμοί του append-only καταλόγου δεν υπάρχουν ΠΟΥΘΕΝΑ — ούτε ως αρχείο, ούτε ως ενότητα μέσα σε άλλο αρχείο, ούτε ως γραμμή ευρετηρίου: 0085, 0106, 0107, 0111, 0112, 0113, 0114. (Έλεγξα: 0108/0110 ζουν μέσα στο 0109· 0115 στο 0116· 0117/0118 στο 0119.) Ο ίδιος ο [0116] αναφέρεται σε «~14 δελτία ([0094]-[0115])» που δεν είναι όλα ανακτήσιμα."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/ /frozen/ro/deployment/collab/dialogue/0116-claude.md:L156-L157@sha256:2727147538b3" :is-it-in-the-known-defect-list :no)

  (:what "Το STATE-OF-PLAY.md, ο δηλωμένος «ζωντανός πίνακας κατάστασης» με ρητό κανόνα «όποιο AI κάνει push, ενημερώνει ΚΑΙ αυτό το αρχείο», φέρει «Τελευταία ενημέρωση: 2026-07-30» ενώ ο πίνακας κατάστασης λέει «22 πύλες» και ο κώδικας έχει 25· ο ίδιος ο [0116] το χαρακτηρίζει «μπαγιάτικο ~14 δελτία»· και το SYSTEM-HIERARCHY.txt περιγράφει ακόμη τον «ORCHESTRATOR v1.3»."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/STATE-OF-PLAY.md:L2-L3@sha256:d8054f835a9d /frozen/ro/deployment/collab/STATE-OF-PLAY.md:L7-L7@sha256:d8054f835a9d /frozen/ro/deployment/collab/STATE-OF-PLAY.md:L13-L13@sha256:d8054f835a9d /frozen/ro/deployment/collab/dialogue/0116-claude.md:L155-L157@sha256:2727147538b3" :is-it-in-the-known-defect-list :yes)

  ;; --- Θ. ΠΑΡΑΒΑΣΕΙΣ ΜΟΝΙΜΩΝ ΝΟΜΩΝ ΤΟΥ ΔΗΜΙΟΥΡΓΟΥ ---
  (:what "ΠΑΡΑΒΙΑΣΗ ΤΟΥ ΜΟΝΙΜΟΥ ΝΟΜΟΥ «ΠΟΤΕ ονόματα/IDs μοντέλων ή αναφορά AI σε repo artifacts» σε τουλάχιστον τρία σημεία της συστάδας: RESERVATION-OF-RIGHTS.md («Καταγράφηκε από: Claude (AI assistant)», «Claude Fable 5», «Opus 4.8» — ίδια ημερομηνία 2026-07-21 με την εντολή)· dialogue/0062-claude.md τίτλος «…wrong-key vector (Fable)»· dialogue/0095-claude.md παραθέτει «το ρεπό θα φέρει την υπογραφή της Anthropic — βαθμολογείται η ίδια η Anthropic». Το ευρετήριο ονομάζει επίσης «GPT-5.5 (Κριτής)» σε 16+ γραμμές."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/RESERVATION-OF-RIGHTS.md:L4-L4@sha256:aa262c4e43af /frozen/ro/deployment/collab/RESERVATION-OF-RIGHTS.md:L15-L15@sha256:aa262c4e43af /frozen/ro/deployment/collab/RESERVATION-OF-RIGHTS.md:L19-L19@sha256:aa262c4e43af /frozen/ro/deployment/collab/dialogue/0062-claude.md:L1-L1@sha256:a89d263cc2cd /frozen/ro/deployment/collab/dialogue/0095-claude.md:L~12 /frozen/ro/CLAUDE.md" :is-it-in-the-known-defect-list :no)

  (:what "ΑΥΤΟ-ΚΑΤΑΓΕΓΡΑΜΜΕΝΗ ΠΑΡΑΒΙΑΣΗ «μία έδρα ανά έννοια» από ταυτόχρονες συνεδρίες: «Δούλεψα L7-A παράλληλα με άλλη συνεδρία (άλλο laptop, ίδιο branch)… ΕΓΩ, χωρίς να το δω, έχτισα ΔΕΥΤΕΡΗ έδρα του ΙΔΙΟΥ concept». Το αρχείο που το καταγράφει είναι ακριβώς αυτό που λείπει από το ευρετήριο."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0062-claude.md:L5-L20@sha256:a89d263cc2cd" :is-it-in-the-known-defect-list :no)

  (:what "12 αρχεία-νησιά (~5.750 LOC) των οποίων το πακέτο δεν αναφέρεται από ΚΑΝΕΝΑ αρχείο source/ ή systems/ (8 ούτε από tests)· π.χ. source/protocols.lisp με ~41 defgeneric ΧΩΡΙΣ ΚΑΜΙΑ defmethod, legal-penalty, blockchain-authority — και ΟΛΑ μεταγλωττίζονται μέσα στο build."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L162-L166@sha256:2727147538b3" :is-it-in-the-known-defect-list :yes)

  (:what "Δηλωμένη επιζώσα μετάλλαξη M14: η κατάργηση του fixed point μέσα στην capture() ΔΕΝ σκοτώνεται — «Παραμένει στον κώδικα ως άμυνα, όχι ως ελεγμένη ιδιότητα»."
   :severity :p2 :evidence "/frozen/ro/deployment/collab/dialogue/0123-claude.md:L58-L71@sha256:afa8d725693e" :is-it-in-the-known-defect-list :yes)

  (:what "ΑΝΟΙΧΤΟ ΥΠΟΛΕΙΜΜΑ (ΜΕΡΙΚΩΣ ΕΠΑΛΗΘΕΥΜΕΝΟ ΑΠΟ ΜΕΝΑ): το census JSON εκπέμπει ΑΚΟΜΗ μη-κανονική ετικέτα αλγορίθμου «odd»:«rfc6962-split» αντί για lawmax-merkle-sha256-v1 — ΤΟ ΕΠΙΒΕΒΑΙΩΣΑ ΖΩΝΤΑΝΟ στη γραμμή 116 της παραγωγικής έδρας. Το δεύτερο σκέλος του δελτίου [0120] (tlog «merkle»:«rfc6962-sha256» στο /frozen/ro/systems/orchestrator-epistemic/transparency-log.lisp:L84-L84@sha256:00dd41938b0e — γραμμή που σήμερα φέρει σχόλιο για τα legacy fixtures, ΟΧΙ τον writer) ΔΕΝ ΕΠΑΛΗΘΕΥΕΤΑΙ στο παγωμένο commit: grep σε ΟΛΟ το repo δίνει το string ΜΟΝΟ σε παγωμένα legacy fixtures και στο αρχείο του αφαιρεμένου writer — οι tlog writers έχουν αφαιρεθεί. Άρα το υπόλειμμα είναι ΖΩΝΤΑΝΟ για το census, ΙΣΤΟΡΙΚΟ για το tlog, και το δελτίο [0120] είναι ως προς αυτό stale."
   :severity :p1 :evidence "/frozen/ro/systems/orchestrator-epistemic/artifact-census.lisp:L116-L116@sha256:bb9159b22802 /frozen/ro/authority-v2/fixtures/legacy-tlog/REMOVED-tlog-writers.lisp.txt:L18-L18@sha256:05b4af8402ac /frozen/ro/authority-v2/fixtures/legacy-tlog/tlog-n1.json:L1-L1@sha256:aba4bad4e347 /frozen/ro/systems/orchestrator-epistemic/transparency-log.lisp:L79-L85@sha256:00dd41938b0e /frozen/ro/deployment/collab/dialogue/0120-claude.md:L147-L152@sha256:e1bebfdda643" :is-it-in-the-known-defect-list :yes)

  (:what "discover-fek.test.js: 10 assertions ΟΛΕΣ πάνω σε ένα καρφωμένο payload· process.exit(0) άνευ όρων στο τέλος και η γραμμή αναφοράς τυπώνει το «0 failed» ως σταθερά κειμένου — δεν μπορεί ποτέ να αναφέρει αποτυχία μέσω exit code παρά μόνο αν πετάξει το assert."
   :severity :p1 :evidence "/frozen/ro/deployment/discover-fek.test.js:L8-L9@sha256:a030e60f4ddc /frozen/ro/deployment/discover-fek.test.js:L42-L43@sha256:a030e60f4ddc" :is-it-in-the-known-defect-list :no))

 ;; ==========================================================================
 ;; ΚΡΥΦΑ ΜΟΝΟΠΑΤΙΑ ΕΚΤΕΛΕΣΗΣ
 ;; ==========================================================================
 :hidden-execution-paths
 ((:path "cron → cron-auto-update.sh → node discover-fek.js → Playwright Chromium → POST searchetv99.azurewebsites.net (και κατέβασμα PDF από Azure blob)"
   :trigger "crontab entry, π.χ. '17 * * * *' — καμία ανθρώπινη εντολή"
   :why-hidden "Εξωτερικό δίκτυο + πλήρης browser runtime ξεκινούν αυτόνομα· τίποτα από αυτά δεν φαίνεται σε κανένα Lisp artifact, ontology ή Σύνταγμα του repo."
   :evidence "/frozen/ro/deployment/cron-auto-update.sh:L46-L61@sha256:01231faab127 /frozen/ro/deployment/discover-fek.js:L104-L136@sha256:69c52b81a4ea")

  (:path "discover-fek.js → /app/state/fek-listing.json → orchestrator.core --discover-fek → --fetch-amendments → --auto-update"
   :trigger "Ίδιο cron tick"
   :why-hidden "ΑΝΥΠΟΓΡΑΦΟ JSON γραμμένο από JavaScript διασχίζει το σύνορο εμπιστοσύνης προς τον Lisp πυρήνα ΧΩΡΙΣ hash, υπογραφή ή provenance sidecar — σε αντίθεση με ΚΑΘΕ άλλο δεδομένο του συστήματος. Το αρχείο επίσης δεν είναι στο repo (gitignored ως amendment-laws.json / state)."
   :evidence "/frozen/ro/deployment/discover-fek.js:L56-L60@sha256:69c52b81a4ea /frozen/ro/deployment/cron-auto-update.sh:L52-L52@sha256:01231faab127 /frozen/ro/deployment/cron-auto-update.sh:L63-L73@sha256:01231faab127 /frozen/ro/.gitignore:L38-L39@sha256:7c8ebc41610b")

  (:path "Εγγραφή σε deployment/knowledge/*.sexp → ensure-fresh σε ΚΑΘΕ /ask → ζωντανή αντικατάσταση της νομικής γνώσης"
   :trigger "Οποιαδήποτε αλλαγή mtime/μεγέθους αρχείου στον κατάλογο"
   :why-hidden "Δεν υπάρχει αναμενόμενο hash, υπογραφή, μητρώο εγκρίσεων ή πύλη. Το pack-sha υπολογίζεται και ΚΑΤΑΓΡΑΦΕΤΑΙ, ποτέ δεν ΑΝΤΙΠΑΡΑΒΑΛΛΕΤΑΙ. Το ίδιο το αρχείο δηλώνει «versioned όπως ο νόμος»."
   :evidence "/frozen/ro/source/knowledge-packs.lisp:L105-L150@sha256:ea774f532b44 /frozen/ro/systems/orchestrator-cli/case-workspace.lisp:L40-L40@sha256:0750c6bc50e7 /frozen/ro/deployment/knowledge/dialogue.sexp:L1-L1@sha256:1f02873ba4fe")

  (:path "ORCHESTRATOR_CMD / DISCOVER_CMD / FEK_BLOB_BASE / DISCOVER_URL / FEK_SEARCH_URL env override"
   :trigger "Οποιοδήποτε env στη διεργασία cron ή στο shell"
   :why-hidden "Αλλάζει ΠΟΙΟ εκτελέσιμο είναι «ο πυρήνας» και ΠΟΙΟ URL είναι «η πηγή του νόμου», χωρίς κανέναν έλεγχο, χωρίς καταγραφή στο receipt."
   :evidence "/frozen/ro/deployment/cron-auto-update.sh:L34-L34@sha256:01231faab127 /frozen/ro/deployment/cron-auto-update.sh:L52-L54@sha256:01231faab127 /frozen/ro/deployment/fetch-fek-by-number.sh:L18-L18@sha256:c43d47b68d1a /frozen/ro/deployment/fetch-fek-by-number.js:L29-L29@sha256:2889ba9bc0aa")

  (:path "LAWMAX_OVERRIDE=<εντολή,…> + LAWMAX_OVERRIDE_REASON, ή --force ανά κλήση"
   :trigger "Env ή σημαία γραμμής εντολών"
   :why-hidden "Παρακάμπτει το «Σύνταγμα» ανά εντολή. Το αποτύπωμα «γράφεται στη βιογραφία» — δηλαδή στο history.sexp, το οποίο ο μόνιμος νόμος επαναφέρει με git checkout πριν από κάθε commit· άρα το ίχνος της παράκαμψης δεν επιβιώνει."
   :evidence "/frozen/ro/deployment/self-study/EXTERNAL-REVIEW-2026-07-05.md:L12-L12@sha256:5bcb7cdc60a9 /frozen/ro/CLAUDE.md")

  (:path "GOLDEN_WRITE=1 μέσω verify-corpus → μετάθεση της golden ρίζας ενός σώματος"
   :trigger "Χειροκίνητη εκτέλεση με τη μεταβλητή"
   :why-hidden "Το «αμετάβλητο» σημείο αναφοράς του corpus μετακινείται με μία μεταβλητή περιβάλλοντος· έγινε τουλάχιστον δύο φορές (syntagma 153056b5→0a5ba296, astikos/kpolitikis νέες ρίζες)."
   :evidence "/frozen/ro/deployment/collab/dialogue/0109-claude.md:L48-L50@sha256:422d8e49517c /frozen/ro/deployment/collab/dialogue/0099-claude.md")

  (:path "OS shell-exec ΜΕΣΑ στον Lisp πυρήνα: document-fetch → /bin/sh -c, 19 sites"
   :trigger "Κάθε ανάκτηση εγγράφου από το pipeline"
   :why-hidden "Ολόκληρη «χαμένη κλάση» εκτέλεσης OS που ΔΕΝ ήταν στην απογραφή του Phase 0 — τη βρήκε ο αντίπαλος. Αναβλήθηκε σε Phase 5/6, δεν έχει κλείσει στο παγωμένο commit."
   :evidence "/frozen/ro/deployment/collab/STATE-OF-PLAY.md:L125-L127@sha256:d8054f835a9d")

  (:path "ΙΣΤΟΡΙΚΟ, ΕΠΑΛΗΘΕΥΜΕΝΑ ΚΛΕΙΣΤΟ: αφύλακτη ανάγνωση κανονικής έδρας στο main.lisp (γρ. 1552 ΤΟΤΕ) → ACE στον daemon· μαζί με eval/load sinks σε legal-ast/trace-core/layout-types/parsing/greek-tokenizer"
   :trigger "Αλλοίωση αρχείου κατάστασης (filesystem tampering) που ο daemon διαβάζει"
   :why-hidden "Ήταν arbitrary code execution μέσω ανάγνωσης δεδομένων, δηλωμένο ως Κ-1 ζωντανό εύρημα. ΕΠΑΛΗΘΕΥΣΑ ΣΤΟ ΠΑΓΩΜΕΝΟ COMMIT ότι η κλάση έχει κλείσει σε αυτή την έδρα: το load-review-queue διαβάζει πλέον μέσω orchestrator.safe-read:read-data-file. Το καταγράφω ως κλειστό μονοπάτι, ΟΧΙ ως ενεργό — η γραμμή 1552 σήμερα είναι απλός format εκτύπωσης. ΔΕΝ επαλήθευσα τα υπόλοιπα sinks (εκτός διαδρομής)."
   :evidence "/frozen/ro/systems/orchestrator-cli/main.lisp:L1504-L1515@sha256:8cf601f197ad /frozen/ro/deployment/collab/STATE-OF-PLAY.md:L~88-L96 /frozen/ro/deployment/collab/dialogue/0096-claude.md:L~28-L36")

  (:path "fek-diagnose.js → page.screenshot({path:'fek-debug.png'}) σε ΣΧΕΤΙΚΟ path (CWD)"
   :trigger "Χειροκίνητη εκτέλεση"
   :why-hidden "Γράφει αρχείο εκτός κάθε ελεγχόμενου καταλόγου· το screenshot μπορεί να περιέχει περιεχόμενο συνεδρίας του ιστότοπου."
   :evidence "/frozen/ro/deployment/fek-diagnose.js:L74-L74@sha256:766f64c5b557")

  (:path "API_DUMP / FEK_HEADFUL — καταγραφή ΟΛΩΝ των request/response bodies του et.gr σε αρχείο"
   :trigger "Env μεταβλητή σε discover-fek.js ή fek-capture.js"
   :why-hidden "Γράφει ακατέργαστα δεδομένα δικτύου (συμπεριλαμβανομένων cookies-bearing responses) σε αυθαίρετο path που δίνει ο χρήστης."
   :evidence "/frozen/ro/deployment/discover-fek.js:L51-L51@sha256:69c52b81a4ea /frozen/ro/deployment/discover-fek.js:L154-L157@sha256:69c52b81a4ea /frozen/ro/deployment/fek-capture.js:L27-L27@sha256:f72084e42236 /frozen/ro/deployment/fek-capture.js:L73-L77@sha256:f72084e42236"))

 ;; ==========================================================================
 ;; ΔΙΠΛΕΣ ΕΔΡΕΣ
 ;; ==========================================================================
 :duplicate-seats
 ((:concept "ΤΟ ΚΕΙΜΕΝΟ ΤΟΥ ΣΥΝΤΑΓΜΑΤΟΣ — δύο αποθηκευμένα σώματα στον ΙΔΙΟ κατάλογο"
   :seats ("/frozen/ro/deployment/data/syntagma_clean.json (124 άρθρα, sha256 b64b3cec…, date 11/06/1975, prov + 2 errata)"
           "/frozen/ro/deployment/data/syntagma_clean.zip → syntagma_clean.json (124 άρθρα, sha256 74e7c84e…, date 14/03/1986, ΚΑΜΙΑ provenance, 0 αναφορές στο repo)"))
  (:concept "ΒΙΩΜΑΤΙΚΗ ΜΝΗΜΗ / «τι έζησα» — δύο δηλωμένες έδρες, η μία ανύπαρκτη"
   :seats ("/frozen/ro/deployment/self/history.sexp:L1-L1@sha256:3e0b6766e32d (υπάρχει, 3 εγγραφές)"
           "deployment/self/episodes.sexp — ΔΕΝ ΥΠΑΡΧΕΙ· ΔΗΛΩΝΕΤΑΙ σε /frozen/ro/deployment/knowledge/self-glossary.sexp:L38-L38@sha256:c40b7a9d2690 και /frozen/ro/deployment/LAWMAX-MEMORY-KERNEL-SPEC.md:L35-L35@sha256:ba0b1d094f92 και /frozen/ro/deployment/LAWMAX-MEMORY-KERNEL-SPEC.md:L62-L62@sha256:ba0b1d094f92"))
  (:concept "«ΤΙ ΔΕΝ ΚΑΤΑΛΑΒΑ» — έξι κατακερματισμένες αποθήκες χωρίς κοινή διεπαφή ερωτήματος"
   :seats ("deployment/state/lessons.jsonl" "deployment/state/failure-ledger.jsonl"
           "deployment/self/episodes.sexp" "/frozen/ro/deployment/self/history.sexp:L1-L1@sha256:3e0b6766e32d"
           "deployment/self/proposals.sexp" "deployment/self/graph-snapshot.sexp"
           "/frozen/ro/deployment/self-study/INTELLIGENCE-AUDIT-2026-07-05.md:L321-L321@sha256:b5a3bb502fcd"))
  (:concept "ΛΗΨΗ ΦΕΚ PDF ΑΠΟ ΔΙΚΤΥΟ — τέσσερα εκτελέσιμα για την ίδια λειτουργία"
   :seats ("/frozen/ro/deployment/fetch-fek.sh:L1-L1@sha256:42acffc89892" "/frozen/ro/deployment/fetch-fek.js:L1-L1@sha256:6c92f25b051b"
           "/frozen/ro/deployment/fetch-fek-by-number.sh:L1-L1@sha256:c43d47b68d1a" "/frozen/ro/deployment/fetch-fek-by-number.js:L1-L1@sha256:2889ba9bc0aa"))
  (:concept "ΔΕΞΑΜΕΝΗ USER-AGENT — ίδιες κυριολεκτικές συμβολοσειρές σε 3 αντίγραφα"
   :seats ("/frozen/ro/deployment/fetch-fek.sh:L34-L40@sha256:42acffc89892" "/frozen/ro/deployment/fetch-fek.js:L32-L38@sha256:6c92f25b051b"
           "/frozen/ro/deployment/fetch-fek-by-number.js:L31-L35@sha256:2889ba9bc0aa"))
  (:concept "ΕΛΕΓΧΟΣ '%PDF' MAGIC — 4 ανεξάρτητες υλοποιήσεις (2 bash, 2 JS) + δηλωμένη 5η στον Lisp"
   :seats ("/frozen/ro/deployment/fetch-fek.sh:L42-L42@sha256:42acffc89892" "/frozen/ro/deployment/fetch-fek-by-number.sh:L36-L36@sha256:c43d47b68d1a"
           "/frozen/ro/deployment/fetch-fek.js:L45-L45@sha256:6c92f25b051b" "/frozen/ro/deployment/fetch-fek-by-number.js:L43-L43@sha256:2889ba9bc0aa"))
  (:concept "ΜΑΣΚΑΡΙΣΜΑ AUTOMATION (addInitScript webdriver/languages/plugins/chrome)"
   :seats ("/frozen/ro/deployment/fetch-fek.js:L62-L68@sha256:6c92f25b051b" "/frozen/ro/deployment/fetch-fek-by-number.js:L57-L61@sha256:2889ba9bc0aa"
           "/frozen/ro/deployment/fek-diagnose.js:L29-L32@sha256:766f64c5b557"))
  (:concept "ΚΑΤΑΣΚΕΥΗ ΝΤΕΤΕΡΜΙΝΙΣΤΙΚΟΥ BLOB URL ΦΕΚ (τεύχος→GG, 5ψήφιο padding)"
   :seats ("/frozen/ro/deployment/fetch-fek-by-number.sh:L21-L29@sha256:c43d47b68d1a" "/frozen/ro/deployment/discover-fek.js:L85-L88@sha256:69c52b81a4ea"))
  (:concept "MERKLE ΦΥΛΛΟ — δύο ασύμβατοι ορισμοί στο στρώμα αυθεντίας (κλεισμένο στο [0122])"
   :seats ("capture.py ΤΟΤΕ SHA256(0x00 ‖ SHA256(bytes)) — /frozen/ro/deployment/collab/dialogue/0122-claude.md:L~18· ΣΗΜΕΡΑ διορθωμένο: /frozen/ro/authority-v2/capture/capture.py:L176-L176@sha256:9593561c6c06"
           "orchestrator.merkle:hash-leaf-file SHA256(0x00 ‖ ΩΜΑ BYTES) — /frozen/ro/deployment/collab/dialogue/0122-claude.md:L~20"))
  (:concept "ΔΙΠΛΕΣ/ΤΡΙΠΛΕΣ ΕΔΡΕΣ ΚΩΔΙΚΑ (μετρημένες από τον έλεγχο ταβανιού)"
   :seats ("protocols ×2 (source/ vs orchestrator-spec)" "mod-inverse ×2 (jws vs blockchain — ΚΡΥΠΤΟΓΡΑΦΙΚΟ ΠΡΩΤΟΓΟΝΟ)"
           "tokenizer ×3" "normalize-greek ×3 (defun σε /frozen/ro/source/greek-lemmatizer.lisp:L41-L41@sha256:12b56d83d333 · /frozen/ro/source/text-canonicalizer.lisp:L409-L409@sha256:747fad14d692 · /frozen/ro/source/legal-id-registry.lisp:L74-L74@sha256:12789d6ba9dd — ΕΠΑΛΗΘΕΥΜΕΝΟ ΑΠΟ ΜΕΝΑ)"
           "Turtle-escaping ×3 (η μία αυτο-τιτλοφορείται «Single source of truth»)" "JSON ×2" "XML ×2"
           "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L173-L177@sha256:2727147538b3"))
  (:concept "ΔΙΠΛΕΣ ΕΔΡΕΣ ΣΕ ΕΠΙΠΕΔΟ ΣΧΕΔΙΟΥ (ασυμφιλίωτες ως έχουν)"
   :seats ("attestation ×2: effectivity-attestation (TEMPORAL §6) vs legal-state-attestation/1 (USC §1.2γ)"
           "γραμματική journal ×2: 0x1F chain (TEMPORAL) vs #F1/#C1 framing (USC §0.5)"
           "trust envelope ×2 (OMEGA §3 vs CPEI §2, διαφορετικά σύνολα πεδίων)"
           "«12 ontologies» vs 13 primitives· ≥3 vs ≥2 TSAs· RSA-4096 vs RSA-3072 για το ΙΔΙΟ root"
           "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L421-L432@sha256:2727147538b3"))
  (:concept "ΚΑΤΑΛΟΓΟΣ ΕΞΟΔΟΥ — δύο δέντρα στη ρίζα"
   :seats ("/frozen/ro/output (304 MB, 6 σώματα × 6 releases — παρόν παρότι .gitignore:L11-L11@sha256:7c8ebc41610b λέει output/)"
           "/frozen/ro/output_run1 (8.6 MB, 484 αρχεία — ΝΟΜΙΜΟ: hash-δεμένο legacy snapshot για το genesis certificate, authority-v2/genesis/genesis-policy.sexp:L35-L35@sha256:9a04b3cd8970)")))

 ;; ==========================================================================
 ;; ΤΙΜΙΑ ΑΓΝΟΙΑ
 ;; ==========================================================================
 :unknowns
 ("Αν ο Lisp πυρήνας ΟΝΤΩΣ επαληθεύει τα prov sidecars στο runtime, και τι κάνει σε mismatch — ο επαληθευτής δεν βρίσκεται σε αυτή τη συστάδα (deployment/verify/ είναι άλλη διαδρομή)."
  "Αν το orchestrator.core όντως καλεί το fetch-fek.sh μέσω source.fetch_cmd — δηλώνεται σε σχόλιο (/frozen/ro/deployment/fetch-fek.sh:L10-L11@sha256:42acffc89892) και σε configs/<corpus>.yaml που δεν ανήκει σε αυτή τη συστάδα."
  "Ποιος γράφει το deployment/self/history.sexp και υπό ποιες συνθήκες — η έδρα εγγραφής δεν διαβάστηκε (source/memory.lisp είναι εκτός διαδρομής)."
  "Αν οι 19 sites του /bin/sh -c στο document-fetch έχουν έκτοτε κλείσει — δηλώνονται αναβλημένα σε Phase 5/6 και δεν βρήκα δελτίο που να τα κλείνει."
  "Γιατί υπάρχει το syntagma_clean.zip και ποια είναι η προέλευσή του — καμία αναφορά, κανένα sidecar, καμία μνεία σε κανένα από τα 113 δελτία διαλόγου που είδα."
  "Το περιεχόμενο 7 δελτίων (0085, 0106, 0107, 0111-0114) — δεν υπάρχουν σε καμία μορφή στο παγωμένο commit."
  "Αν το /frozen/ro αντιστοιχεί όντως στο commit e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03 — δεν μπόρεσα να το επαληθεύσω κρυπτογραφικά από μέσα."
  "Ο ακριβής αριθμός ενεργών πυλών ΤΩΡΑ — τα κείμενα δίνουν 18/21/22/23/24/25 και ο κώδικας δεν διαβάστηκε σε αυτή τη διαδρομή."
  "Αν υπάρχει μηχανισμός που επιβάλλει «receipt + ρητή έγκριση δημιουργού» για επέκταση των μητρώων — τα σχόλια το δηλώνουν, ο loader επιβάλλει μόνο το κλειστό σύνολο."))
