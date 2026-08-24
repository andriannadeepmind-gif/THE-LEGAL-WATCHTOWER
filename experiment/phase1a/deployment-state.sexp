(:lawmax-phase1a-cluster/1
 :cluster "ΚΑΤΑΣΤΑΣΗ ΚΑΙ ΓΝΩΣΗ — deployment/{self,self-study,knowledge,data,state,collab} + deployment/*.js *.sh"
 :status :partial
 :files-read 16
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

 :unknowns
 ("Ο Lisp φορτωτής/επαληθευτής των knowledge packs και του history.sexp — δεν ανήκει σε αυτή τη συστάδα."
  "Αν το orchestrator.core όντως καλεί fetch-fek.sh μέσω source.fetch_cmd (δηλώνεται στο σχόλιο, δεν επαληθεύτηκε εδώ).")

 :remaining
 ("collab/STATE-OF-PLAY.md" "collab/AI-DIALOGUE.md" "collab/APPROVAL-ACT-F7-HARDENING.md"
  "collab/RESERVATION-OF-RIGHTS.md" "collab/dialogue/0001..0125 (113 αρχεία)"
  "self-study/INTELLIGENCE-AUDIT-2026-07-05.md" "self-study/EXTERNAL-REVIEW-2026-07-05.md"
  "knowledge/self-glossary.sexp" "knowledge/legal-lexicon.sexp" "knowledge/casegrammar-core.sexp"
  "knowledge/tatbestand-core.sexp" "data/astikos_clean.json(+prov)" "data/decisions/** (340 αρχεία)"))
