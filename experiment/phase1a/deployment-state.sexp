(:lawmax-phase1a-cluster/1
 :cluster "ΚΑΤΑΣΤΑΣΗ ΚΑΙ ΓΝΩΣΗ — deployment/{self,self-study,knowledge,data,state,collab} + deployment/*.js *.sh"
 :status :partial
 :files-read 215
 :frozen-mount "/frozen/ro (commit e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03)"

 :capabilities
 ((:name "Αυτοβιογραφική μνήμη (hash-chained self-history)"
   :presence :present
   :domain "Αλυσίδα γεγονότων ζωής του συστήματος, S-expressions, ένα record ανά γραμμή."
   :assumptions "append-only· κάθε record κρατά :PREV = :HASH του προηγούμενου."
   :guarantees "Hash chain SHA-256 (64 hex)· genesis :PREV = 64 μηδενικά."
   :failure-semantics ":unknown — δεν διαβάστηκε (σε αυτή τη διαδρομή) ο κώδικας που επαληθεύει την αλυσίδα."
   :operating-model "3 εγγραφές μόνο: GENESIS/BIRTH/INHERITANCE, ΟΛΕΣ με ίδιο timestamp 2026-07-04T11:10:24."
   :materiality "Είναι η μοναδική «μνήμη ζωής» του συστήματος."
   :evidence "/frozen/ro/deployment/self/history.sexp:L1-L3")

  (:name "Daemon αυτόνομου κύκλου (κατάσταση)"
   :presence :spec-only
   :domain "Κατάσταση αυτόνομου daemon: cycle counter, policy, ουρά προτάσεων."
   :assumptions "Το αρχείο ενημερώνεται από τον daemon σε κάθε κύκλο."
   :guarantees "Καμία ορατή· απλό JSON χωρίς hash/υπογραφή."
   :failure-semantics ":unknown"
   :operating-model "policy=propose, cycle=0, pending_review=0, proposals=[]· utc=2026-07-02T22:22:42Z — ΠΡΙΝ το GENESIS του history.sexp (2026-07-04)."
   :materiality "Αποδεικνύει ότι ο αυτόνομος κύκλος ΔΕΝ έχει τρέξει ποτέ ούτε έναν κύκλο στο παγωμένο commit."
   :evidence "/frozen/ro/deployment/state/daemon-status.json:L1")

  (:name "Δίκτυο: ανάκτηση ΦΕΚ PDF από et.gr (network edge)"
   :presence :present
   :domain "Λήψη PDF ΦΕΚ από https://www.et.gr / search.et.gr / Azure blob."
   :assumptions "Ο host έχει bash, curl, node, playwright chromium· δεν υπάρχει CAPTCHA/Turnstile."
   :guarantees "ΜΟΝΟ magic bytes '%PDF-' στα πρώτα 5 bytes. ΚΑΜΙΑ δέσμευση ότι το PDF είναι ΤΟ ζητούμενο ΦΕΚ."
   :failure-semantics "exit 1 μετά N προσπαθειών· διαγράφει το OUT (fetch-fek.sh:L79)."
   :operating-model "N προσπάθειες με ΕΝΑΛΛΑΣΣΟΜΕΝΟ User-Agent, exponential backoff + jitter, curl → headless Chromium."
   :materiality "Είναι η ΡΙΖΑ του corpus: ό,τι κατεβάσει γίνεται «το γράμμα του νόμου με ταυτότητα SHA-256»."
   :evidence "/frozen/ro/deployment/fetch-fek.sh:L1-L80")

  (:name "Δίκτυο: ντετερμινιστική λήψη ΦΕΚ με αριθμό (Azure blob)"
   :presence :present
   :domain "https://ia37rg02wpsa01.blob.core.windows.net/fek/<GG>/<YYYY>/<YYYY><GG><NNNNN>.pdf"
   :assumptions "Το URL pattern του blob παραμένει σταθερό· τεύχος Α-Δ → 01-04."
   :guarantees "Ντετερμινιστικό URL από (τεύχος, αριθμός, έτος)· έλεγχος '%PDF' magic."
   :failure-semantics "exit 1· ΔΕΝ διαγράφει το μερικό OUT (σε αντίθεση με fetch-fek.sh)."
   :operating-model "curl -fSL, χωρίς browser/Playwright/anti-bot."
   :materiality "Το μόνο μονοπάτι δικτύου χωρίς browser automation."
   :evidence "/frozen/ro/deployment/fetch-fek-by-number.sh:L1-L45")

  (:name "Αυτόνομος κύκλος ενημέρωσης corpus (ΟΛΟΚΛΗΡΗ η ενορχήστρωση)"
   :presence :present
   :domain "discover → fetch → codify → consolidate → verify(golden) → sign, μία φορά ανά cron tick."
   :assumptions "cron· flock· node· ORCHESTRATOR_CMD δείχνει σε /app/orchestrator.core."
   :guarantees "Single-flight μέσω flock -n· μη-μηδενικό exit από --auto-update διαδίδεται στο cron."
   :failure-semantics "ΣΙΩΠΗΛΗ ΥΠΟΒΑΘΜΙΣΗ: ΚΑΘΕ βήμα discovery έχει '|| log ... (continuing)' — αποτυχία δεν σταματά τον κύκλο."
   :operating-model "BASH είναι ο ενορχηστρωτής· ο Lisp πυρήνας είναι υποδιεργασία που καλείται 3 φορές (--discover-fek, --fetch-amendments, --auto-update)."
   :materiality "Το ΑΝΩΤΑΤΟ επίπεδο ελέγχου του «αυτόνομου» συστήματος είναι shell script, όχι Lisp."
   :evidence "/frozen/ro/deployment/cron-auto-update.sh:L32-L86")

  (:name "Ανακάλυψη νέας νομοθεσίας μέσω et.gr JSON API"
   :presence :present
   :domain "POST https://searchetv99.azurewebsites.net/api/searchlegislation μέσα από Playwright browser context."
   :assumptions "Το endpoint σερβίρει 200 χωρίς CAPTCHA· τα πεδία search_* διατηρούν σχήμα."
   :guarantees "Deduplication με key url|number|year· ντετερμινιστική κατασκευή blob URL."
   :failure-semantics "Κάθε σφάλμα έτους → console.error και ΣΥΝΕΧΙΖΕΙ· parseData επιστρέφει [] σε junk. Άδεια λίστα ≡ «τίποτα νέο»."
   :operating-model "Node + Playwright chromium με --disable-blink-features=AutomationControlled· γράφει JSON στο FEK_LISTING_JSON."
   :materiality "Το JSON που γράφει καταναλώνεται από τον Lisp πυρήνα (--discover-fek) ΧΩΡΙΣ υπογραφή/hash."
   :evidence "/frozen/ro/deployment/discover-fek.js:L1-L169")

  (:name "Γνωσιακά πακέτα (knowledge packs) — δικονομία / ταξινομία / διάλογος"
   :presence :present
   :domain "S-expression knowledge packs με version integer, φορτωμένα «ζωντανά»."
   :assumptions "Ο φορτωτής τους ζει στον Lisp πυρήνα (ΔΕΝ διαβάστηκε σε αυτή τη διαδρομή)."
   :guarantees "Κάθε operator φέρει πηγή (π.χ. 'kpolitikis:518') + προθεσμία + αφετηρία."
   :failure-semantics ":unknown"
   :operating-model "Στατικά αρχεία δεδομένων· καμία υπογραφή, κανένα hash μέσα στο αρχείο."
   :materiality "3 μόνο δικονομικοί τελεστές ΚΠολΔ (518, 503, 564)· 12 σχέσεις γένους + 2 διαιρέσεις."
   :evidence "/frozen/ro/deployment/knowledge/procedure-core.sexp:L1-L22 /frozen/ro/deployment/knowledge/taxonomy-core.sexp:L1-L25 /frozen/ro/deployment/knowledge/dialogue.sexp:L1-L7")

  (:name "Provenance sidecars corpus (slw-source-prov/1) — ΕΠΑΛΗΘΕΥΜΕΝΟ ΑΠΟ ΜΕΝΑ"
   :presence :present
   :domain "Ένα .prov.json ανά αρχείο δεδομένων: content_sha256, source_digest, extraction_method, date, errata."
   :assumptions "Το content_sha256 είναι SHA-256 των ΑΚΡΙΒΩΝ bytes του συνοδευόμενου αρχείου."
   :guarantees "ΜΕΤΡΗΜΕΝΟ: 161/161 sidecars areios-pagos επαληθεύουν (match=161 mismatch=0)· επίσης astikos_clean.json."
   :failure-semantics ":unknown — ποιος επαληθεύει και τι γίνεται σε αστοχία δεν φαίνεται σε αυτή τη συστάδα."
   :operating-model "Ομοιόμορφο σχήμα 6 κλειδιών σε ΟΛΑ τα 161 sidecars (καταμετρήθηκε)."
   :materiality "Το ΜΟΝΟ πραγματικά επαληθευμένο αναλλοίωτο ακεραιότητας που μπόρεσα να ΜΕΤΡΗΣΩ σε αυτή τη συστάδα."
   :evidence "/frozen/ro/deployment/data/decisions/areios-pagos/ap_2015_1.json.prov.json:L1 /frozen/ro/deployment/data/astikos_clean.json.prov.json:L1")

  (:name "Errata ledger (χειροκίνητες διορθώσεις text layer PDF)"
   :presence :present
   :domain "Λίστα errata μέσα στο prov sidecar: article, from, to, reason, page."
   :assumptions "Ο άνθρωπος έκρινε την «οπτική σειρά της σελίδας» ως ορθή."
   :guarantees "Κάθε errata φέρει αιτιολογία και σελίδα."
   :failure-semantics ":unknown"
   :operating-model "2 errata στον ΑΚ (άρθρα 216, 1228)· 0 errata σε ΟΛΑ τα 161 decisions."
   :materiality "Ανθρώπινη χειροκίνητη τροποποίηση του «γράμματος του νόμου» ΜΕΤΑ την εξαγωγή — καταγεγραμμένη, αλλά το content_sha256 καλύπτει το ΔΙΟΡΘΩΜΕΝΟ, όχι το πρωτότυπο."
   :evidence "/frozen/ro/deployment/data/astikos_clean.json.prov.json:L1")

  (:name "Γλωσσάρι του εαυτού (self-glossary) — αυτο-περιγραφή προς τον χρήστη"
   :presence :present
   :domain "65 γραμμές, ~20 entries: όροι του πρωτοκόλλου με :match υποστρώματα και :answer/:route."
   :assumptions "Δηλωμένο ρητά στο ίδιο το αρχείο: «⚠ BOOTSTRAP: χειροποίητο περιεχόμενο — σκαλωσιά, ΟΧΙ απόδειξη μάθησης»."
   :guarantees "Καμία· είναι στατικό κείμενο απαντήσεων."
   :failure-semantics "Δεν υπάρχει· η απάντηση επιστρέφεται όπως γράφτηκε."
   :operating-model "Ταίριασμα κανονικοποιημένου υποστρώματος → σταθερό κείμενο."
   :materiality "ΕΔΩ ζουν οι ΔΗΛΩΣΕΙΣ του συστήματος για τον εαυτό του — και εδώ εντοπίστηκε η σοβαρότερη ασυμφωνία δηλωμένης/αποθηκευμένης κατάστασης (βλ. defects)."
   :evidence "/frozen/ro/deployment/knowledge/self-glossary.sexp:L10-L12,L38")

  (:name "Ειδικές υποστάσεις (tatbestand) — ο πυρήνας της υπαγωγής"
   :presence :present
   :domain "Κανόνες με πηγή, προϋποθέσεις με μεταβλητές (:?χ), και λόγους άρσης."
   :assumptions "Η γλώσσα γεγονότων (:γεγονός υποκείμενο κατηγόρημα αντικείμενο) καλύπτει τα πραγματικά περιστατικά."
   :guarantees "Κάθε norm φέρει πηγή (poinikos:372/299/375, astikos:914) και ρητό defeater όπου προβλέπεται."
   :failure-semantics ":unknown"
   :operating-model "ΤΕΣΣΕΡΙΣ (4) κανόνες συνολικά· ο ίδιος ο audit τους αντιπαραβάλλει στα 529 άρθρα ΠΚ."
   :materiality "Η «δικανική πράξη» του συστήματος στηρίζεται σε 4 κανόνες."
   :evidence "/frozen/ro/deployment/knowledge/tatbestand-core.sexp:L1-L41 /frozen/ro/deployment/self-study/INTELLIGENCE-AUDIT-2026-07-05.md:L411")

  (:name "Μητρώο ειδών νομικών σωμάτων (body-kind registry)"
   :presence :present
   :domain "Κλειστό σύνολο 10 ειδών νομικών σωμάτων για την έδρα orchestrator.identity."
   :assumptions "Ο κώδικας ΔΕΝ έχει hard-coded enum· διαβάζει από εδώ."
   :guarantees "Επέκταση μόνο με νέα εγγραφή + receipt + ρητή έγκριση δημιουργού (δηλωμένο, όχι επιβεβλημένο σε αυτό το αρχείο)."
   :failure-semantics ":unknown"
   :operating-model "Στατικό αρχείο δεδομένων."
   :materiality "Ορίζει τι μπορεί να αναγνωριστεί ως νομικό σώμα."
   :evidence "/frozen/ro/deployment/data/body-kind-registry.sexp:L1-L15"))

 :authorities
 ((:name "Δημιουργός (Σταυρόπουλος Σπυρίδων)"
   :what-it-can-decide "Τα πάντα· το σύστημα δηλώνει «Υπακούω μόνο σε εκείνον»."
   :who-can-invoke "Μόνο ο ίδιος."
   :enforcement :convention
   :evidence "/frozen/ro/deployment/self/history.sexp:L1")
  (:name "cron (χρονοδρομολογητής OS)"
   :what-it-can-decide "ΠΟΤΕ τρέχει ολόκληρος ο αυτόνομος κύκλος ενημέρωσης του corpus."
   :who-can-invoke "Όποιος έχει crontab στον host."
   :enforcement :os
   :evidence "/frozen/ro/deployment/cron-auto-update.sh:L11-L12")
  (:name "Περιβαλλοντικές μεταβλητές (env) ως άρχουσα διαμόρφωση"
   :what-it-can-decide "ORCHESTRATOR_CMD (ΠΟΙΟ εκτελέσιμο είναι ο πυρήνας), DISCOVER_CMD, FEK_BLOB_BASE (ΠΟΙΟ URL είναι η πηγή του νόμου), PCL_SIGNING_KEY (ΠΟΙΟ κλειδί υπογράφει)."
   :who-can-invoke "Οποιοσδήποτε μπορεί να ορίσει env στη διεργασία cron."
   :enforcement :none
   :evidence "/frozen/ro/deployment/cron-auto-update.sh:L14-L30 /frozen/ro/deployment/fetch-fek-by-number.sh:L18"))

 :invariants
 ((:statement "Κάθε εγγραφή self-history φέρει :PREV = :HASH της προηγούμενης (hash chain)."
   :enforced-by ":unknown — ο επαληθευτής δεν βρίσκεται σε αυτή τη συστάδα"
   :evidence "/frozen/ro/deployment/self/history.sexp:L1-L3")
  (:statement "Ό,τι κατεβαίνει από το δίκτυο πρέπει να αρχίζει με '%PDF-'."
   :enforced-by ":code (bash is_pdf + node isPdf + δηλωμένος έλεγχος στον Lisp πυρήνα)"
   :evidence "/frozen/ro/deployment/fetch-fek.sh:L42 /frozen/ro/deployment/fetch-fek.js:L45")
  (:statement "Δύο auto-update ticks δεν τρέχουν ποτέ ταυτόχρονα."
   :enforced-by ":os (flock -n σε fd 9)"
   :evidence "/frozen/ro/deployment/cron-auto-update.sh:L40-L44")
  (:statement "Το body-kind registry επεκτείνεται ΜΟΝΟ με εγγραφή + receipt + ρητή έγκριση δημιουργού."
   :enforced-by ":convention (σχόλιο στο ίδιο το αρχείο· κανένας μηχανισμός εδώ)"
   :evidence "/frozen/ro/deployment/data/body-kind-registry.sexp:L3-L4"))

  (:statement "content_sha256(prov) = SHA-256(bytes του συνοδευόμενου αρχείου)."
   :enforced-by ":code (δηλωμένο)· ΕΠΑΛΗΘΕΥΘΗΚΕ ΑΠΟ ΜΕΝΑ: 161/161 match, 0 mismatch"
   :evidence "/frozen/ro/deployment/data/decisions/areios-pagos/*.prov.json")
  (:statement "Η μαθημένη κατάσταση («runtime state») δεν είναι ταυτότητα και δεν μπαίνει στο repository."
   :enforced-by ":code (.gitignore) + :convention (CLAUDE.md: git checkout -- deployment/self/history.sexp πριν από κάθε commit)"
   :evidence "/frozen/ro/.gitignore:L44-L50 /frozen/ro/CLAUDE.md")

 :defects
 ((:what "Η αυτοβιογραφική μνήμη έχει 3 ΜΟΝΟ εγγραφές, όλες με ΤΟ ΙΔΙΟ timestamp — το σύστημα δεν έχει καταγράψει ΚΑΜΙΑ εμπειρία μετά τη γέννησή του, παρότι το repo δείχνει 125 φάσεις διαλόγου."
   :severity :p0 :evidence "/frozen/ro/deployment/self/history.sexp:L1-L3" :is-it-in-the-known-defect-list :unknown)
  (:what "cron-auto-update.sh: ΟΛΗ η ενορχήστρωση του αυτόνομου κύκλου είναι bash — αντιφάσκει με «zero shell orchestration in the trusted path»."
   :severity :p0 :evidence "/frozen/ro/deployment/cron-auto-update.sh:L52-L79" :is-it-in-the-known-defect-list :unknown)
  (:what "Σιωπηλά fallbacks: κάθε βήμα discovery/routing/amendments αποτυγχάνει με '|| log ...(continuing)'· ο κύκλος δηλώνει «tick OK» ενώ η ανακάλυψη μπορεί να έχει αποτύχει ολοσχερώς."
   :severity :p0 :evidence "/frozen/ro/deployment/cron-auto-update.sh:L60,L66,L70,L81-L82" :is-it-in-the-known-defect-list :unknown)
  (:what "ΚΑΜΙΑ δέσμευση μεταξύ ΖΗΤΟΥΜΕΝΟΥ και ΛΗΦΘΕΝΤΟΣ εγγράφου: ο fetcher βρίσκει «οποιοδήποτε <a> που μοιάζει με pdf/λήψη/φεκ» και το μόνο κριτήριο αποδοχής είναι τα magic bytes '%PDF-'."
   :severity :p0 :evidence "/frozen/ro/deployment/fetch-fek.js:L81-L94 /frozen/ro/deployment/fetch-fek-by-number.js:L108-L121" :is-it-in-the-known-defect-list :unknown)
  (:what "Ενεργητική αποφυγή anti-bot σε κρατικό ιστότοπο: εναλλαγή User-Agent, jitter viewport/fingerprint, μασκάρισμα navigator.webdriver/plugins/languages, --disable-blink-features=AutomationControlled."
   :severity :p1 :evidence "/frozen/ro/deployment/fetch-fek.sh:L13-L20,L34-L40 /frozen/ro/deployment/fetch-fek.js:L39-L41,L62-L68 /frozen/ro/deployment/discover-fek.js:L108" :is-it-in-the-known-defect-list :unknown)
  (:what "daemon-status.json: cycle 0, proposals [], timestamp 2026-07-02 — ΠΡΟΓΕΝΕΣΤΕΡΟ της γέννησης (2026-07-04). Ο «αυτόνομος daemon» δεν έχει τρέξει ποτέ."
   :severity :p1 :evidence "/frozen/ro/deployment/state/daemon-status.json:L1 /frozen/ro/deployment/self/history.sexp:L1" :is-it-in-the-known-defect-list :unknown)
  (:what "fetch-fek-by-number.sh ΔΕΝ διαγράφει το μη-PDF αρχείο εξόδου σε αποτυχία (σε αντίθεση με fetch-fek.sh:L79) — αφήνει HTML/error body στη θέση PDF."
   :severity :p1 :evidence "/frozen/ro/deployment/fetch-fek-by-number.sh:L40-L45 /frozen/ro/deployment/fetch-fek.sh:L78-L80" :is-it-in-the-known-defect-list :unknown)
  (:what "discover-fek.test.js: 10 assertions, ΟΛΕΣ πάνω σε hard-coded payload· process.exit(0) άνευ όρων στο τέλος και η γραμμή αναφοράς είναι κυριολεκτικά «0 failed» ως σταθερά string."
   :severity :p1 :evidence "/frozen/ro/deployment/discover-fek.test.js:L42-L43" :is-it-in-the-known-defect-list :unknown))

  (:what "ΤΟ ΓΛΩΣΣΑΡΙ ΛΕΕΙ ΨΕΜΑΤΑ ΣΤΟΝ ΧΡΗΣΤΗ: «Καταγράφηκε» ορίζεται ως «γράφτηκε μόνιμα σε ΔΥΟ μνήμες μου — deployment/state/lessons.jsonl και deployment/self/episodes.sexp». ΚΑΝΕΝΑ από τα δύο αρχεία ΔΕΝ ΥΠΑΡΧΕΙ στο παγωμένο commit (find σε ΟΛΟ το repo: 0 ευρήματα)· και τα δύο είναι ρητά gitignored."
   :severity :p0
   :evidence "/frozen/ro/deployment/knowledge/self-glossary.sexp:L38 /frozen/ro/.gitignore:L40,L47 /frozen/ro/deployment/self-study/INTELLIGENCE-AUDIT-2026-07-05.md:L278"
   :is-it-in-the-known-defect-list :yes)
  (:what "ΟΛΗ η μαθημένη/υιοθετημένη κατάσταση είναι gitignored ως «runtime state (not identity)»: episodes.sexp, proposals.sexp, graph-snapshot.sexp, policies.sexp, adoptions.sexp, lessons.jsonl, failure-ledger.jsonl, amendment-laws.json. Το repository μεταφέρει ΜΟΝΟ τη χειροποίητη σκαλωσιά· ό,τι «έμαθε» το σύστημα δεν επιβιώνει του commit."
   :severity :p0 :evidence "/frozen/ro/.gitignore:L37-L50" :is-it-in-the-known-defect-list :no)
  (:what "Ο ίδιος ο ΕΛΕΓΧΟΣ ΝΟΗΜΟΣΥΝΗΣ δίνει ΤΡΕΙΣ διαφορετικούς αριθμούς για το ΙΔΙΟ σώμα αποφάσεων: «165 αποφάσεις» (11 φορές), «161 αποφάσεις» (5 φορές), «322 αποφάσεις ΑΠ» (1 φορά, στη σύγκριση με Harvey/Lexis+AI). ΜΕΤΡΗΣΑ στον δίσκο: 161 areios-pagos + 2 efeteio-peiraios + 1 protodikeio-athinon = 164. Το «322» είναι 2×161 — μετράει τα .prov.json sidecars ως αποφάσεις."
   :severity :p1
   :evidence "/frozen/ro/deployment/self-study/INTELLIGENCE-AUDIT-2026-07-05.md:L447,L551 /frozen/ro/deployment/data/decisions/"
   :is-it-in-the-known-defect-list :no)
  (:what "Το prov sidecar φέρει source_digest αλλά ΚΑΜΙΑ source_url/ημερομηνία-λήψης/υπογραφή — το digest της πηγής είναι ορφανό: δεν μπορεί να αντιπαραβληθεί με τίποτα εκτός συστήματος."
   :severity :p1 :evidence "/frozen/ro/deployment/data/decisions/areios-pagos/ap_2015_1.json.prov.json:L1" :is-it-in-the-known-defect-list :no)
  (:what "Το content_sha256 σφραγίζει το ΔΙΟΡΘΩΜΕΝΟ (post-errata) κείμενο· δεν υπάρχει hash του προ-errata πρωτοτύπου, άρα οι χειροκίνητες παρεμβάσεις στο «γράμμα του νόμου» δεν είναι ανεξάρτητα ελέγξιμες."
   :severity :p1 :evidence "/frozen/ro/deployment/data/astikos_clean.json.prov.json:L1" :is-it-in-the-known-defect-list :no)
  (:what "Ασυμφωνία ισχυρισμού-κώδικα στην αυτο-περιγραφή (docstrings δηλώνουν αυτονομία δαίμονα που ο κώδικας δεν έχει) — καταγεγραμμένη από τον ίδιο τον audit ως «ακριβώς το είδος απόκλισης που το σύνταγμά του απαγορεύει»."
   :severity :p1 :evidence "/frozen/ro/deployment/self-study/INTELLIGENCE-AUDIT-2026-07-05.md:L517-L523" :is-it-in-the-known-defect-list :yes)

  (:what "ΤΟ ΔΗΜΟΣΙΟ PCL-1 SPEC ΔΙΔΑΣΚΕΙ ΛΑΘΟΣ MERKLE («odd node paired with itself» = η κλάση CVE-2012-2459) που ο κώδικας ΔΕΝ κάνει — όπως και το deployment/verify/README.md. Τρίτος που αναϋπολογίζει τη ρίζα από τα δημόσια κείμενα παίρνει ΛΑΘΟΣ ρίζα, υπονομεύοντας την ίδια την αρχή «recompute without trusting us»."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L415-L420" :is-it-in-the-known-defect-list :yes)
  (:what "Η αλυσίδα SHA-256 του self/history.sexp είναι ΕΝΤΕΛΩΣ ΑΤΕΣΤ: «0 τεστ verify-chain». Το μοναδικό αναλλοίωτο που προστατεύει την ταυτότητα/μνήμη του συστήματος δεν επαληθεύεται από καμία πύλη."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L379 /frozen/ro/deployment/self/history.sexp:L1-L3" :is-it-in-the-known-defect-list :yes)
  (:what "Εγγύηση ανθεκτικότητας ΨΕΥΔΗΣ: μετάλλαξη fsync→no-op ΕΠΙΒΙΩΝΕΙ· το receipt βγαίνει :durable με ΜΟΝΟ κριτήριο την επιτυχία του with-open-file· «0 τεστ σε όλο το tests/ αναφέρουν fsync»."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L365-L368" :is-it-in-the-known-defect-list :yes)
  (:what "Επιβίωση μεταλλάξεων ≈45% (10 από 22 ονομαστικές μεταλλάξεις της μηχανής ΕΠΙΒΙΩΝΟΥΝ) — μετρημένο χάσμα από το «0 λάθος ως μηχανισμός»."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L348-L351,L363-L390" :is-it-in-the-known-defect-list :yes)
  (:what "284 ignore-errors σε 94 αρχεία· 52 στη μορφή σιωπηλού default (or (ignore-errors …) τιμή). Χειρότερο: semantic-authority.lisp εκπέμπει authority RDF με hardcoded fallback URLs σε 6 σημεία αντί σφάλματος — σιωπηλό fallback ΜΕΣΑ στο μονοπάτι αυθεντίας."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L167-L172" :is-it-in-the-known-defect-list :yes)
  (:what "metrics-stub no-op ΜΕΣΑ στο build καταπίνει το record-error-event — τα FRBR error events χάνονται σιωπηλά."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L178-L180" :is-it-in-the-known-defect-list :yes)
  (:what "Ο ΑΡΙΘΜΟΣ ΤΩΝ ΠΥΛΩΝ διαφέρει ανά κείμενο: 18 (OMEGA), 21 (CROSSWALK), 22 (STATE-OF-PLAY πίνακας), 23 (THREAT-MODEL), 25 (κώδικας/0116). Το ίδιο το «μέτρο του 0 λάθος» δεν έχει μία τιμή."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L411-L413 /frozen/ro/deployment/collab/STATE-OF-PLAY.md:L13" :is-it-in-the-known-defect-list :yes)
  (:what "Από 89 δεσμευτικά invariants των 6 specs: 54 ΑΠΟΔΕΔΕΙΓΜΕΝΑ, 14 ΑΝΕΛΕΓΚΤΑ (δηλωμένα χωρίς κανένα τεστ), 3 εκτός αλυσίδας, 18 μελλοντικά — 54/71 ≈ 76% των ΕΝΕΡΓΩΝ δεσμεύσεων αποδεικνύεται μηχανικά."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L344-L348" :is-it-in-the-known-defect-list :yes)
  (:what "Το ευρετήριο AI-DIALOGUE.md ΔΕΝ αντιστοιχεί στα αρχεία: 124 γραμμές ευρετηρίου για 113 αρχεία· ο αριθμός 12 εμφανίζεται ΔΥΟ φορές· η αρίθμηση ευρετηρίου διαφέρει από την αρίθμηση αρχείων (#116 → 0125-claude.md)· χρησιμοποιούνται μη-ακέραια αναγνωριστικά «90+», «92+», «93++++»."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/AI-DIALOGUE.md:L22-L26" :is-it-in-the-known-defect-list :no)
  (:what "12 αριθμοί λείπουν από τον append-only κατάλογο dialogue/: 0085, 0106-0108, 0110-0115, 0117, 0118. Κανένας δεν αναφέρεται στο ευρετήριο. Σειρά/πληρότητα δεν ανακατασκευάζονται από κανένα από τα δύο."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/ /frozen/ro/deployment/collab/AI-DIALOGUE.md" :is-it-in-the-known-defect-list :no)
  (:what "12 αρχεία-νησιά (~5.750 LOC) των οποίων το πακέτο δεν αναφέρεται από ΚΑΝΕΝΑ αρχείο source/ ή systems/ (8 ούτε από tests)· π.χ. source/protocols.lisp με ~41 defgeneric ΧΩΡΙΣ ΚΑΜΙΑ defmethod — και όλα μεταγλωττίζονται μέσα στο build."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L162-L166" :is-it-in-the-known-defect-list :yes)
  (:what "ΑΝΑΚΛΗΣΗ ΔΗΛΩΜΕΝΗΣ ΕΓΓΥΗΣΗΣ: ο ισχυρισμός «Merkle divergence δομικά αδύνατη» ΑΠΟΣΥΡΘΗΚΕ όταν μετάλλαξη πέρασε σε n=18. Η εγγύηση υποβαθμίστηκε σε «ισχυρή ανίχνευση παλινδρόμησης, όχι φέρουσα απόδειξη»."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/STATE-OF-PLAY.md:L378-L381 /frozen/ro/deployment/collab/dialogue/0124-claude.md:L126-L127" :is-it-in-the-known-defect-list :yes)
  (:what "ΑΥΤΟ-ΟΜΟΛΟΓΙΑ ΨΕΥΔΟΚΛΕΙΣΤΩΝ ΔΙΑΔΡΟΜΩΝ [0125]: «Έγραφα ελεγκτές των οποίων ΕΓΩ όριζα το εύρος… Ένας ελεγκτής που διαλέγει πού θα κοιτάξει δεν ελέγχει· επιβεβαιώνει» και «άλλαξα το compose χωρίς να μπορώ να τρέξω τον αγωγό»."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0125-claude.md:L8-L21 /frozen/ro/deployment/collab/dialogue/0124-claude.md:L49-L51" :is-it-in-the-known-defect-list :yes)
  (:what "Η ΤΕΛΕΥΤΑΙΑ δηλωμένη κατάσταση είναι ΡΗΤΑ ΑΤΕΛΗΣ: run-proofs exit 3 = 14 passed / 0 failed / 1 BLOCKED· Docker daemon ΑΠΩΝ· CI 0 runs / workflow_dispatch 403· «Δ2/Δ3 = IMPLEMENTED-NOT-PROVED»· Level-7 gate :not-passed· «ο admission kernel δεν υπάρχει»."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0125-claude.md:L108-L131 /frozen/ro/deployment/collab/STATE-OF-PLAY.md:L420-L422" :is-it-in-the-known-defect-list :yes)
  (:what "ΜΝΗΜΕΙΩΔΗΣ ΑΝΤΙΦΑΣΗ ΜΕ ΤΟ «zero shell / zero Python»: (α) ο αντίπαλος βρήκε «χαμένη κλάση OS shell-exec (document-fetch /bin/sh -c, 19 sites)» ΜΕΣΑ στον Lisp πυρήνα, αναβλημένη σε Phase 5/6· (β) το νεότερο, ανώτατης εμπιστοσύνης στρώμα release/capture είναι Python + Node («εκτός-TCB αυθεντία = py/mjs», capture.py, verify-proof-manifest.py, verify-canonical.py, verify-temporal.py, verify.mjs, run-proofs.sh, ceremony.sh)."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/STATE-OF-PLAY.md:L125-L127,L328-L330,L344-L346 /frozen/ro/deployment/collab/dialogue/0116-claude.md:L358-L360 /frozen/ro/deployment/collab/dialogue/0124-claude.md:L86-L88,L109" :is-it-in-the-known-defect-list :yes)
  (:what "Διπλές/τριπλές έδρες στον κώδικα (μετρημένες): protocols ×2, mod-inverse ×2 (ΚΡΥΠΤΟΓΡΑΦΙΚΟ ΠΡΩΤΟΓΟΝΟ), tokenizer ×3, normalize-greek ×3, Turtle-escaping ×3 (η μία αυτο-τιτλοφορείται «Single source of truth»), JSON ×2, XML ×2· και σε επίπεδο σχεδίου: attestation ×2, γραμματική journal ×2, trust envelope ×2."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0116-claude.md:L173-L177,L421-L432" :is-it-in-the-known-defect-list :yes)
  (:what "Το corpus πιθανόν STALE: ΑΚ/ΚΠολΔ έναντι Ν.5221/2025 (ΦΕΚ Α΄133, ισχύς 1/1/2026) και Ν.5303/2026 (Α΄81, νέο κληρονομικό, ισχύς 16/9/2026) — «ΕΠΙΒΕΒΑΙΩΜΕΝΑ από 2 ανεξάρτητες έρευνες». Ο δαίμονας ΦΕΚ «cycle 0, χωρίς cursor, FEK_ANALYZE off, μόνο τρέχον έτος — γι΄ αυτό δεν ειδοποίησε ΠΟΤΕ»· η όπλισή του «αναβλήθηκε»."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/STATE-OF-PLAY.md:L50-L51 /frozen/ro/deployment/state/daemon-status.json:L1" :is-it-in-the-known-defect-list :yes)

  (:what "ΤΟ CI ΔΕΝ ΕΧΕΙ ΤΡΕΞΕΙ ΠΟΤΕ ΠΡΑΣΙΝΟ: μετρημένο μέσω API — «2 runs, 2026-01-06, main, και τα ΔΥΟ failure»· τα push της συνεδρίας δεν πυροδοτούν Actions (0 runs)· workflow_dispatch ⇒ 403 «Resource not accessible by integration». Όλοι οι αριθμοί των πυλών είναι ΤΟΠΙΚΕΣ εκτελέσεις χωρίς ανεξάρτητη επιβεβαίωση."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0120-claude.md:L114-L117,L160-L178" :is-it-in-the-known-defect-list :yes)
  (:what "Το job ci-integrity-selfcheck καλούσε sbcl ΧΩΡΙΣ να το εγκαθιστά — «τα βήματα Merkle έσκαγαν, η πύλη δεν έτρεξε ΠΟΤΕ πράσινη». Και οι πύλες έτρεχαν ΜΟΝΟ στο main — «κάθε κλάδος έφτανε στη συγχώνευση ΑΝΕΛΕΓΚΤΟΣ»."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0119-claude.md:L93-L97" :is-it-in-the-known-defect-list :yes)
  (:what "ΚΥΚΛΙΚΟ ORACLE: τα golden vectors παράγονταν από την ΙΔΙΑ έδρα (orchestrator.merkle) που επαληθεύουν — «αν η έδρα ήταν λάθος, τα vectors θα κωδικοποιούσαν το λάθος και ΚΑΘΕ έλεγχος θα ήταν πράσινος». Το δεύτερο «ανεξάρτητο» by-segments ήταν ΑΝΤΙΓΡΑΦΟ με ΨΕΥΔΗ docstring «bottom-up»."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0119-claude.md:L18-L21 /frozen/ro/deployment/collab/dialogue/0120-claude.md:L13-L17" :is-it-in-the-known-defect-list :yes)
  (:what "ΨΕΥΔΟ-ΠΡΑΣΙΝΗ ΠΥΛΗ ΜΕΤΑΛΛΑΞΕΩΝ: killed = (code != 0) μετρούσε το -1 (ΑΠΟΝ εργαλείο) ως φόνο — μετάλλαξη που δεν εκτελέστηκε ποτέ καταγραφόταν ως σκοτωμένη."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0119-claude.md:L32-L33" :is-it-in-the-known-defect-list :yes)
  (:what "Το κρυπτογραφικό «profile» ήταν ΑΔΡΑΝΕΣ: :leaf-prefix-byte, :node-prefix-byte, :hash-algorithm, :hash-representation, :mutation-witnesses ΟΛΑ αγνοούνταν — ο generator hardcode-αρε #(0)/#(1)/:sha256. «Άλλαξε μόνο το profile ⇒ έμενε πράσινο»."
   :severity :p0 :evidence "/frozen/ro/deployment/collab/dialogue/0120-claude.md:L41-L43,L53-L58" :is-it-in-the-known-defect-list :yes)
  (:what "23 αρχεία γράφουν φόρμουλα του Merkle αλγορίθμου· 14 ήταν ΑΔΕΣΜΕΥΤΑ από το κανονικό profile — μεταξύ τους η ΙΔΙΑ η έδρα merkle-authority.lisp, kernel-verify.lisp, verify.py/mjs, verify-release.py, verify-authority-bundle.py, transparency-log, LAWMAX-PROOF-OBJECT-SPEC."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0120-claude.md:L69-L79" :is-it-in-the-known-defect-list :yes)
  (:what "ΑΝΟΙΧΤΟ ΥΠΟΛΕΙΜΜΑ: τα εκπεμπόμενα artifacts φέρουν ΑΚΟΜΗ μη-κανονικές ετικέτες αλγορίθμου — census JSON «odd»:«rfc6962-split» (artifact-census.lisp:116), tlog «merkle»:«rfc6962-sha256» (transparency-log.lisp:84) — αντί για lawmax-merkle-sha256-v1."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0120-claude.md:L147-L152" :is-it-in-the-known-defect-list :yes)
  (:what "Η ΠΡΑΞΗ ΕΓΚΡΙΣΗΣ owner proof #5 είναι ΚΕΝΗ ΦΟΡΜΑ: git_head, image_digest, standalone_proof_sha256, verifier_proof_sha256, runtime_assets_sha256, ημερομηνία/υπογραφή — όλα υπογραμμίσεις. Το κείμενο ορίζει «ΜΟΝΟ τότε ξεκινά το #4», ενώ το ευρετήριο δηλώνει το #4 ΟΛΟΚΛΗΡΩΜΕΝΟ."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/APPROVAL-ACT-F7-HARDENING.md:L30-L40 /frozen/ro/deployment/collab/AI-DIALOGUE.md" :is-it-in-the-known-defect-list :no)
  (:what "Το RESERVATION-OF-RIGHTS.md παραβιάζει τον μόνιμο νόμο του δημιουργού «ΠΟΤΕ ονόματα/IDs μοντέλων ή αναφορά AI σε repo artifacts»: περιέχει «Καταγράφηκε από: Claude (AI assistant)», «Claude Fable 5», «Opus 4.8» — και είναι της ίδιας ημερομηνίας (2026-07-21) με την εντολή."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/RESERVATION-OF-RIGHTS.md:L4,L15,L19 /frozen/ro/CLAUDE.md" :is-it-in-the-known-defect-list :no)

  (:what "ΔΕΥΤΕΡΗ ΑΠΟΘΗΚΕΥΜΕΝΗ ΑΛΗΘΕΙΑ ΤΟΥ ΣΥΝΤΑΓΜΑΤΟΣ, ΑΝΕΞΗΓΗΤΗ ΚΑΙ ΑΔΕΣΜΕΥΤΗ. Το deployment/data/syntagma_clean.zip περιέχει ΑΛΛΟ syntagma_clean.json (300.125 bytes έναντι 296.482 του ζωντανού· sha256 74e7c84e… έναντι b64b3cec…). ΜΕΤΡΗΣΑ: 124/124 άρθρα διαφέρουν, 9 τίτλοι διαφέρουν, και η ημερομηνία είναι 14/03/1986 έναντι 11/06/1975 του ζωντανού. ΔΕΝ έχει .prov.json, ΔΕΝ έχει content_sha256, ΔΕΝ έχει errata, και ΔΕΝ αναφέρεται από ΚΑΝΕΝΑ αρχείο σε ΟΛΟΚΛΗΡΟ το παγωμένο repository (grep -rl: 0 ευρήματα). Αντιφάσκει ευθέως με την ετυμηγορία [0109γ] «ΜΗΔΕΝ ανεξήγητο κείμενο σε 4694 άρθρα / 6 σώματα» και με τον «θάνατο της δεύτερης αλήθειας εισόδου» [0110]."
   :severity :p0 :evidence "/frozen/ro/deployment/data/syntagma_clean.zip /frozen/ro/deployment/data/syntagma_clean.json.prov.json:L1 /frozen/ro/deployment/collab/dialogue/0109-claude.md:L103-L105,L108-L113" :is-it-in-the-known-defect-list :no)
  (:what "Ο γράφος εκδόσεων / τα bitemporal journals (deployment/data/version-graph/) είναι gitignored — «ΠΑΡΑΓΩΓΑ runtime stores ανά περιβάλλον… ΟΧΙ δεσμευμένη ιστορία». Η θεσμική χρονική μνήμη του συστήματος δεν υπάρχει στο παγωμένο commit."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0109-claude.md:L74-L77 /frozen/ro/.gitignore:L54" :is-it-in-the-known-defect-list :yes)
  (:what "Επτά αριθμοί του append-only καταλόγου διαλόγου δεν υπάρχουν ΠΟΥΘΕΝΑ στο repo — ούτε ως αρχείο ούτε ως ενότητα μέσα σε άλλο αρχείο: 0085, 0106, 0107, 0111, 0112, 0113, 0114. (Τα 0108/0110 ζουν μέσα στο 0109· τα 0115 στο 0116· τα 0117/0118 στο 0119.) Ο ίδιος ο [0116] αναφέρεται σε «~14 δελτία ([0094]-[0115])» που δεν είναι όλα ανακτήσιμα."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/ /frozen/ro/deployment/collab/dialogue/0116-claude.md:L156-L157" :is-it-in-the-known-defect-list :no)
  (:what "Η capture.py δηλώνεται «υλοποίηση αναφοράς» και «ο production writer παραμένει απενεργοποιημένος» — δηλαδή το στρώμα που παράγει τη Merkle δέσμευση των releases ΔΕΝ είναι ενεργό στην παραγωγή."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0123-claude.md:L100-L101" :is-it-in-the-known-defect-list :yes)
  (:what "Δηλωμένη επιζώσα μετάλλαξη M14: η κατάργηση του fixed point μέσα στην capture() ΔΕΝ σκοτώνεται — «Παραμένει στον κώδικα ως άμυνα, όχι ως ελεγμένη ιδιότητα»."
   :severity :p2 :evidence "/frozen/ro/deployment/collab/dialogue/0123-claude.md:L58-L71" :is-it-in-the-known-defect-list :yes)
  (:what "ΑΝΑΚΛΗΘΗΚΑΝ δηλωμένες εγγυήσεις ακινησίας: οι τίτλοι «IMMUTABLE CANDIDATE» και «IMMUTABLE RELEASE DIRECTORY» + η διατύπωση στο authority-boundary.lisp αποσύρθηκαν· και ο ισχυρισμός «η απόκλιση της Merkle έδρας είναι δομικά αδύνατη» αποσύρθηκε οριστικά (RETRACTED_CLAIMS στον κώδικα)."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0123-claude.md:L12-L23,L54" :is-it-in-the-known-defect-list :yes)
  (:what "ΔΕΝ ΥΠΑΡΧΟΥΝ εξωτερικά παγωμένα test vectors για το Merkle: «BLOCKED… Η πολιτική δικτύου απορρίπτει (403)»· ο oracle «μοιράζεται συγγραφέα με την έδρα»· ο ισχυρισμός «επαληθεύτηκε έναντι τρίτου» ΔΕΝ εκφέρεται."
   :severity :p1 :evidence "/frozen/ro/deployment/collab/dialogue/0121-claude.md:L27-L33,L125-L126 /frozen/ro/deployment/collab/dialogue/0120-claude.md:L144-L145" :is-it-in-the-known-defect-list :yes)

 :hidden-execution-paths
 ((:path "cron → cron-auto-update.sh → node discover-fek.js → Playwright Chromium → POST searchetv99.azurewebsites.net"
   :trigger "crontab entry (π.χ. '17 * * * *')"
   :why-hidden "Εξωτερικό δίκτυο + πλήρης browser runtime ξεκινά χωρίς καμία εντολή χρήστη· δεν φαίνεται πουθενά στα Lisp artifacts."
   :evidence "/frozen/ro/deployment/cron-auto-update.sh:L53-L61 /frozen/ro/deployment/discover-fek.js:L104-L128")
  (:path "discover-fek.js → /app/state/fek-listing.json → orchestrator.core --discover-fek"
   :trigger "Ίδιο tick"
   :why-hidden "ΑΝΥΠΟΓΡΑΦΟ JSON γραμμένο από JS διασχίζει το σύνορο εμπιστοσύνης προς τον Lisp πυρήνα χωρίς hash/υπογραφή/provenance."
   :evidence "/frozen/ro/deployment/discover-fek.js:L56-L60 /frozen/ro/deployment/cron-auto-update.sh:L52,L64-L66")
  (:path "FEK_BLOB_BASE / DISCOVER_URL / ORCHESTRATOR_CMD env override"
   :trigger "Οποιοδήποτε env στη διεργασία"
   :why-hidden "Αλλάζει ΠΟΙΑ είναι η πηγή του νόμου και ΠΟΙΟ εκτελέσιμο είναι ο «πυρήνας», χωρίς κανέναν έλεγχο."
   :evidence "/frozen/ro/deployment/fetch-fek-by-number.sh:L18 /frozen/ro/deployment/cron-auto-update.sh:L34,L53-L54")
  (:path "fek-diagnose.js → screenshot 'fek-debug.png' στο CWD"
   :trigger "Χειροκίνητη εκτέλεση"
   :why-hidden "Γράφει αρχείο σε σχετικό path (CWD), όχι σε ελεγχόμενο κατάλογο."
   :evidence "/frozen/ro/deployment/fek-diagnose.js:L74"))

  (:path "LAWMAX_OVERRIDE=<εντολή,…> + LAWMAX_OVERRIDE_REASON / --force"
   :trigger "Env ή σημαία στη γραμμή εντολών"
   :why-hidden "Παρακάμπτει το «σύνταγμα» ανά εντολή· η παλιά μορφή ήταν καθολική. Το αποτύπωμα γράφεται «στη βιογραφία» — δηλαδή στο history.sexp που το CLAUDE.md επαναφέρει με git checkout πριν από κάθε commit."
   :evidence "/frozen/ro/deployment/self-study/EXTERNAL-REVIEW-2026-07-05.md:L12 /frozen/ro/CLAUDE.md")

 :duplicate-seats
 ((:concept "Λήψη ΦΕΚ PDF από δίκτυο"
   :seats ("/frozen/ro/deployment/fetch-fek.sh:L1" "/frozen/ro/deployment/fetch-fek.js:L1"
           "/frozen/ro/deployment/fetch-fek-by-number.sh:L1" "/frozen/ro/deployment/fetch-fek-by-number.js:L1"))
  (:concept "Δεξαμενή User-Agent (ίδιες κυριολεκτικές συμβολοσειρές, 3 αντίγραφα)"
   :seats ("/frozen/ro/deployment/fetch-fek.sh:L34-L40" "/frozen/ro/deployment/fetch-fek.js:L32-L38"
           "/frozen/ro/deployment/fetch-fek-by-number.js:L31-L35"))
  (:concept "Έλεγχος '%PDF' magic (4 ανεξάρτητες υλοποιήσεις: 2 bash, 2 JS, + δηλωμένη Lisp)"
   :seats ("/frozen/ro/deployment/fetch-fek.sh:L42" "/frozen/ro/deployment/fetch-fek-by-number.sh:L36"
           "/frozen/ro/deployment/fetch-fek.js:L45" "/frozen/ro/deployment/fetch-fek-by-number.js:L43"))
  (:concept "Μασκάρισμα automation (addInitScript webdriver/chrome)"
   :seats ("/frozen/ro/deployment/fetch-fek.js:L63-L68" "/frozen/ro/deployment/fetch-fek-by-number.js:L57-L61"
           "/frozen/ro/deployment/fek-diagnose.js:L29-L32"))
  (:concept "Κατασκευή ντετερμινιστικού blob URL ΦΕΚ"
   :seats ("/frozen/ro/deployment/fetch-fek-by-number.sh:L21-L29" "/frozen/ro/deployment/discover-fek.js:L85-L88")))

  (:concept "Βιωματική μνήμη / «τι έζησα» — δύο δηλωμένες έδρες, η μία ανύπαρκτη"
   :seats ("/frozen/ro/deployment/self/history.sexp:L1 (υπάρχει, 3 εγγραφές)"
           "deployment/self/episodes.sexp (ΔΗΛΩΝΕΤΑΙ στο self-glossary.sexp:L38 και LAWMAX-MEMORY-KERNEL-SPEC.md:L35 — ΔΕΝ ΥΠΑΡΧΕΙ)"))
  (:concept "«Τι δεν κατάλαβα» — έξι κατακερματισμένες αποθήκες χωρίς κοινή διεπαφή (κατά τον ίδιο τον audit)"
   :seats ("deployment/state/lessons.jsonl" "deployment/state/failure-ledger.jsonl"
           "deployment/self/episodes.sexp" "/frozen/ro/deployment/self/history.sexp:L1"
           "deployment/self/proposals.sexp" "deployment/self/graph-snapshot.sexp"
           "/frozen/ro/deployment/self-study/INTELLIGENCE-AUDIT-2026-07-05.md:L321"))

  (:concept "Το ΚΕΙΜΕΝΟ ΤΟΥ ΣΥΝΤΑΓΜΑΤΟΣ — δύο αποθηκευμένα σώματα στον ΙΔΙΟ κατάλογο"
   :seats ("/frozen/ro/deployment/data/syntagma_clean.json (124 άρθρα, sha256 b64b3cec…, date 11/06/1975, prov+2 errata)"
           "/frozen/ro/deployment/data/syntagma_clean.zip → syntagma_clean.json (124 άρθρα, sha256 74e7c84e…, date 14/03/1986, ΚΑΜΙΑ provenance, 0 αναφορές στο repo)"))

 :unknowns
 ("Ο Lisp φορτωτής/επαληθευτής των knowledge packs και του history.sexp — δεν ανήκει σε αυτή τη συστάδα."
  "Αν το orchestrator.core όντως καλεί fetch-fek.sh μέσω source.fetch_cmd (δηλώνεται στο σχόλιο, δεν επαληθεύτηκε εδώ).")

 :remaining
 ("collab/STATE-OF-PLAY.md" "collab/AI-DIALOGUE.md" "collab/APPROVAL-ACT-F7-HARDENING.md"
  "collab/RESERVATION-OF-RIGHTS.md" "collab/dialogue/0001..0125 (113 αρχεία)"
  "collab/APPROVAL-ACT-F7-HARDENING.md" "collab/RESERVATION-OF-RIGHTS.md"
  "collab/dialogue/0095-0105,0109,0119-0123 (πλήρως)"
  "collab/dialogue/0001-0094 (τίτλος+σύνοψη από το ευρετήριο — ΕΓΙΝΕ μερικώς)"))
