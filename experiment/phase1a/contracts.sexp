(:lawmax-phase1a-cluster/1
 :cluster "ΤΑ ΣΥΜΒΟΛΑΙΑ ΚΑΙ Η ΠΑΡΑΔΟΣΗ"
 :status :complete
 :files-read 79
 :universe 79
 :scope "43 root + configs/(9) + docs/(18) + .github/(3) + cloudflare/(5) + tools/(1). Αναγνώσεις εκτός συστάδας έγιναν ΜΟΝΟ ως άγκυρες επαλήθευσης (source/, systems/, docker/, deployment/, scripts/) κατ' εντολή της ΕΙΔΙΚΗΣ ΕΝΤΟΛΗΣ."
 :method "Για κάθε ΔΗΛΩΣΗ συμβολαίου αναζητήθηκε ο ΜΗΧΑΝΙΣΜΟΣ και χαρακτηρίστηκε :structural (το σφάλμα είναι δομικά αδύνατο) | :guard (φρουρός που μπορεί να κοκκινίσει) | :text-only (καμία εκτέλεση)."

 ;; ══════════════════════════════════════════════════════════════════════
 :capabilities
 ((:name "GATE-4 — Pipeline integrity (no subprocess)"
   :presence :absent
   :domain "Δηλωμένη πύλη CI που επιβάλλει «no subprocess» στον αγωγό."
   :assumptions "Ότι κάθε GATE-N του πίνακα README:300-305 αντιστοιχεί σε εκτελέσιμο guard."
   :guarantees "ΚΑΜΙΑ. Εξαντλητική αναζήτηση σε *.lisp/*.md/*.asd/*.yml/*.yaml: το «GATE-4» με σημασία «pipeline integrity / no subprocess» εμφανίζεται ΜΟΝΟ στο README.md:304. Το μόνο άλλο «GATE-4A» (article-root-generator-omega.lisp:175, hybrid-generator-phase1.lisp:289) είναι ΑΣΧΕΤΟ (Single Emission Law)."
   :failure-semantics "Δεν υπάρχει μηχανισμός να αποτύχει· η δήλωση δεν μπορεί ποτέ να γίνει κόκκινη."
   :operating-model "Μόνο γραμμή πίνακα Markdown."
   :materiality "P1 με άγκυρα: η ΑΠΟΛΥΤΗ δήλωση README:20-21 «The only subprocess is the Lisp runtime itself» δεν φρουρείται από κανέναν μηχανισμό, ΚΑΙ το source/pdf-authority.lisp εκκινεί 5 subprocess χωρίς να το πιάνει τίποτα."
   :mechanism :text-only
   :evidence "README.md:304")

  (:name "Ολομέλεια πυλών --gates (25 εντολές -gate)"
   :presence :present
   :domain "Αυτο-παραγόμενη ολομέλεια από το μητρώο εντολών."
   :assumptions "Κάθε εντολή με επίθημα -gate συμμετέχει (README:185-187)."
   :guarantees "25 ΔΙΑΚΡΙΤΕΣ εντολές -gate υπάρχουν πραγματικά στο μητρώο· η κρίση γίνεται από assess-gate-plenary.sh + assess-gate-manifest.lisp με set-equality έναντι gate-registry.sexp."
   :failure-semantics "fail-closed μέσω PIPESTATUS· baseline exception ΜΟΝΟ advisor-gate."
   :operating-model "docker run orchestrator:test --gates με mounted source."
   :materiality "ΚΑΜΙΑ από τις 25 δεν είναι πύλη subprocess/purity. Η ονοματολογία GATE-1..GATE-5 του README:300-305 ΔΕΝ αντιστοιχίζεται σε καμία από τις 25."
   :mechanism :guard
   :evidence ".github/workflows/docker-orchestrator.yml:292-308 README.md:185-187")

  (:name "Πραγματικά subprocess seats στον κώδικα"
   :presence :present
   :domain "Εκκίνηση εξωτερικών διεργασιών από τον πυρήνα."
   :assumptions "uiop:run-program· εξωτερικά binaries στο PATH."
   :guarantees "Καμία απομόνωση. run-fetch-command περνά ΑΥΘΑΙΡΕΤΟ string σε /bin/sh -c."
   :failure-semantics "pdf-authority: σιωπηλό NIL (:1424)· document-fetch: (values -1 msg), «never throws» (:106)."
   :operating-model "Runtime, ΜΕΣΑ στο production image."
   :materiality "6 call sites σε 2 αρχεία. Τα binaries poppler-utils/tesseract-ocr/tesseract-ocr-ell ΕΓΚΑΘΙΣΤΑΝΤΑΙ ΡΗΤΑ στο runtime stage — η εικόνα παραγωγής κουβαλά τα εργαλεία που η δήλωση αρνείται."
   :mechanism :structural
   :evidence "source/document-fetch.lisp:92-106 source/pdf-authority.lisp:1386-1425 Dockerfile:371-373")

  (:name "Python ως ΥΠΟΧΡΕΩΤΙΚΗ εξάρτηση κατασκευής του runtime"
   :presence :present
   :domain "Κατασκευή της production εικόνας."
   :assumptions "apt δικτυακά διαθέσιμο· python3 + python3-rdflib + nodejs εγκαθίστανται."
   :guarantees "Fail-closed: το runtime ΔΕΝ χτίζεται αν αποτύχει έστω ένα python3 gate (Dockerfile:316 «αλλιώς ΤΟ RUNTIME ΔΕΝ ΧΤΙΖΕΤΑΙ»)."
   :failure-semantics "build red."
   :operating-model "Stage verifier-conformance — ΥΠΟΧΡΕΩΤΙΚΟΣ πρόγονος του runtime μέσω COPY --from=verifier-conformance."
   :materiality "README:18 «Zero Python dependencies». Το runtime ΔΕΝ ΜΠΟΡΕΙ ΝΑ ΠΑΡΑΧΘΕΙ χωρίς python3: 4 ρητά python3 βήματα + 1 node βήμα είναι πύλες."
   :mechanism :structural
   :evidence "Dockerfile:241-245 Dockerfile:259 Dockerfile:284-285 Dockerfile:316 Dockerfile:394")

  (:name "Shell ως έδρα εκτέλεσης ΚΑΙ κρίσης της αποδεικτικής αλυσίδας"
   :presence :present
   :domain "Εκτέλεση των tests/*-test.lisp και ΤΕΛΙΚΗ ΚΡΙΣΗ της ολομέλειας."
   :assumptions "bash με pipefail."
   :guarantees "fail-closed (pipefail + PIPESTATUS)."
   :failure-semantics "sbcl exit != 0 ⇒ build/CI red."
   :operating-model "docker/run-standalone-suites.sh (η ΜΙΑ έδρα εκτέλεσης) και deployment/verify/assess-gate-plenary.sh (η ΜΙΑ έδρα κρίσης)."
   :materiality "README:19 «Zero shell-script orchestration in the trusted path». Η τελική ετυμηγορία ορθότητας αποδίδεται από bash script· Dockerfile:167 θέτει SHELL σε /bin/bash."
   :mechanism :structural
   :evidence "Dockerfile:167 Dockerfile:189-192 Dockerfile:290 .github/workflows/docker-orchestrator.yml:298-299")

  (:name "deps.lock — αμφιμονοσήμαντο κλείδωμα εξαρτήσεων"
   :presence :present
   :domain "Ταυτότητα των 58 vendored βιβλιοθηκών."
   :assumptions "Ο κατάλογος third-party/ είναι πλήρης· ο αλγόριθμος docker/dep-hash.lisp είναι σταθερός."
   :guarantees "ΕΠΑΛΗΘΕΥΜΕΝΗ ΑΜΦΙΜΟΝΟΣΗΜΑΝΤΗ ΑΝΤΙΣΤΟΙΧΙΑ 58↔58 (diff καθαρό: κάθε εγγραφή deps.lock = ένας κατάλογος third-party/, καμία περίσσεια, καμία απουσία)."
   :failure-semantics "Fail-closed: το stage 1 τρέχει ΠΡΙΝ εμπιστευθεί οποιαδήποτε vendored lib (Dockerfile:36-37)."
   :operating-model "Stage deps-verify, ΚΑΘΑΡΟ LISP (verify-deps.lisp + αυτοτελές sha256.lisp, χωρίς third-party)."
   :materiality "Ο ΙΣΧΥΡΟΤΕΡΟΣ δομικός μηχανισμός της συστάδας — δήλωση ΚΑΙ επιβολή συμπίπτουν."
   :mechanism :structural
   :evidence "deps.lock:1-7 Dockerfile:29-48")

  (:name "Διαχωρισμός ρόλων παραγωγού / υπογράφοντα (compose)"
   :presence :present
   :domain "Απομόνωση ιδιωτικού κλειδιού από τον μη-έμπιστο παραγωγό."
   :assumptions "Ο χειριστής τρέχει τα δηλωμένα profiles· το Docker επιβάλλει uid/mount."
   :guarantees "producer/orchestrator/ingestion (11002) βλέπουν ΜΟΝΟ ./keys/public· ΜΟΝΟ ο authority-signer (11001) προσαρτά ./keys/private· η authority store είναι named volume που κανένας παραγωγός δεν προσαρτά."
   :failure-semantics "read_only rootfs + cap_drop ALL + no-new-privileges σε 4 υπηρεσίες· γραφή μόνο σε ρητά δηλωμένα mounts/tmpfs."
   :operating-model "OS/Docker level, ξεχωριστά uid ανά ρόλο."
   :materiality "Δομικός μηχανισμός: η υποκλοπή κλειδιού από τον παραγωγό είναι ΑΔΥΝΑΤΗ, όχι απαγορευμένη."
   :mechanism :structural
   :evidence "docker-compose.yml:29-32 docker-compose.yml:283-312 docker-compose.yml:314-363 docker-compose.yml:399-403")

  (:name "authority-signer / admission kernel"
   :presence :spec-only
   :domain "Υπογραφή release."
   :assumptions "—"
   :guarantees "ΚΑΜΙΑ. Η υπηρεσία ΑΡΝΕΙΤΑΙ ρητά και βγαίνει exit 3."
   :failure-semantics "Πάντα exit 3 με ::error:: μήνυμα· ΔΕΝ προσποιείται ότι υπογράφει."
   :operating-model "entrypoint /bin/sh -c «echo … && exit 3»."
   :materiality "ΤΙΜΙΑ ΑΓΝΟΙΑ δηλωμένη ΣΤΗΝ ΙΔΙΑ ΤΗΝ ΕΔΡΑ: «ο admission kernel (απαίτηση 2/4 του Level-7) ΔΕΝ ΕΧΕΙ ΥΛΟΠΟΙΗΘΕΙ»."
   :mechanism :structural
   :evidence "docker-compose.yml:327-340")

  (:name "Temporal Provenance / Content Immutability (SEMANTIC-CONTRACT §1.2-1.3)"
   :presence :spec-only
   :domain "Απόδειξη ύπαρξης artifact σε χρόνο· ανιχνευσιμότητα αλλοίωσης."
   :assumptions "OpenTimestamps/IPFS/Arweave endpoints ενεργά."
   :guarantees "ΔΗΛΩΝΕΤΑΙ ως «GUARANTEE» ότι κάθε artifact έχει blockchain-anchored timestamp και ότι η αλλοίωση ανιχνεύεται. Ο ΜΗΧΑΝΙΣΜΟΣ ΔΕΝ ΤΟ ΚΑΝΕΙ."
   :failure-semantics "verify-anchor επιστρέφει T σε HTTP 200 ΑΓΝΟΩΝΤΑΣ ΡΗΤΑ το περιεχόμενο: (declare (ignore response)) … (= status 200). Καμία σύγκριση hash."
   :operating-model "drakma HTTP GET/POST."
   :materiality "Δύο έγγραφα του ΙΔΙΟΥ repo λένε τα ΑΝΤΙΘΕΤΑ: SEMANTIC-CONTRACT.md:38,51 δηλώνει GUARANTEE· docs/SECURITY-REDTEAM.md:54-62 το χαρακτηρίζει «verification theatre» και OPEN."
   :mechanism :text-only
   :evidence "SEMANTIC-CONTRACT.md:36-56 docs/SECURITY-REDTEAM.md:54-66 source/blockchain-authority.lisp:927-942")

  (:name "Reproducibility — byte-identical output υπό SOURCE_DATE_EPOCH"
   :presence :unknown
   :domain "Αναπαραγώγιμη κατασκευή."
   :assumptions "SOURCE_DATE_EPOCH=1735689600 σεβαστό από όλα τα στάδια."
   :guarantees "Το epoch ΟΝΤΩΣ διαδίδεται (ENV + proof manifest) και η base image είναι καρφωμένη σε digest."
   :failure-semantics "Δεν βρέθηκε ΚΑΝΕΝΑΣ μηχανισμός που να ΣΥΓΚΡΙΝΕΙ δύο builds· το δηλωμένο εργαλείο scripts/verify-deterministic-build.sh ΔΕΝ ΥΠΑΡΧΕΙ."
   :operating-model "ENV μεταβλητή."
   :materiality "Η αναπαραγωγιμότητα δηλώνεται (README:332) αλλά δεν μετριέται πουθενά· 3× apt-get update χωρίς pinning εκδόσεων την υπονομεύουν δομικά."
   :mechanism :text-only
   :evidence "README.md:332 Dockerfile:17 Dockerfile:64 SEMANTIC-CONTRACT.md:56-62")

  (:name "Έμπιστο μονοπάτι εκκίνησης (entrypoint)"
   :presence :present
   :domain "Από ENTRYPOINT μέχρι orchestrator.cli:main."
   :assumptions "tini ως PID 1· sbcl διαθέσιμο στο runtime."
   :guarantees "Ο πραγματικός entrypoint είναι ΚΑΘΑΡΟ LISP (docker/entrypoint.lisp), ανιχνεύει τύπο artifact από magic bytes, επικυρώνει καταλόγους, ΔΕΝ γράφει health."
   :failure-semantics "exit 127 αν λείπει το artifact· exit 1 αν λείπει δηλωμένος κατάλογος· διαδίδει το exit code του παιδιού."
   :operating-model "tini → sbcl --script entrypoint.lisp → sb-ext:run-program (fork+wait, ΟΧΙ exec) → orchestrator.core (ELF)."
   :materiality "Η δήλωση README:20-21 «execs orchestrator.core» είναι ΑΚΡΙΒΗΣ ως προς την πρόθεση αλλά ο wrapper παραμένει ζωντανός γονέας — δύο διεργασίες Lisp, όχι μία."
   :mechanism :structural
   :evidence "Dockerfile:452 docker/entrypoint.lisp:67-77 docker/entrypoint.lisp:115-154 build.lisp:43-47"))

 ;; ══════════════════════════════════════════════════════════════════════
 :authorities
 ((:name "GIT_COMMIT 40-hex gate"
   :what-it-can-decide "Αν το build προχωρά· «proof χωρίς δεσμευμένο HEAD δεν είναι proof»."
   :who-can-invoke "docker build --build-arg GIT_COMMIT"
   :enforcement :code
   :evidence "Dockerfile:172-173")
  (:name "runtime-assets sha256 self-check"
   :what-it-can-decide "Αν χτίζεται το runtime image: κάθε asset ≡ manifest του verified stage."
   :who-can-invoke "docker build (αυτόματο)"
   :enforcement :code
   :evidence "Dockerfile:320-326 Dockerfile:414")
  (:name "deps-verify (pure Lisp, πριν εμπιστευθεί vendored lib)"
   :what-it-can-decide "Αν οι 58 vendored εξαρτήσεις ταιριάζουν με deps.lock."
   :who-can-invoke "docker build stage 1"
   :enforcement :code
   :evidence "Dockerfile:29-48 deps.lock:1-7")
  (:name "assess-gate-plenary.sh + assess-gate-manifest.lisp"
   :what-it-can-decide "Αν η ολομέλεια είναι πράσινη· απαιτεί ΘΕΤΙΚΗ απόδειξη ολοκλήρωσης + set-equality με gate-registry.sexp."
   :who-can-invoke "CI job build-and-test"
   :enforcement :code
   :evidence ".github/workflows/docker-orchestrator.yml:292-308")
  (:name "verify-proof-manifest.py (totality + suite census)"
   :what-it-can-decide "Αν χτίζεται το runtime: κάθε tests/*-test.lisp πλην δηλωμένων εξαιρέσεων έχει parseable failed=0."
   :who-can-invoke "docker build --target verifier-conformance"
   :enforcement :code
   :evidence "Dockerfile:312-316")
  (:name "Ο δημιουργός (Stavropoulos Law) — έγκριση φάσεων/merge"
   :what-it-can-decide "Τα πάντα· καμία φάση δεν ανοίγει μόνη της."
   :who-can-invoke "μόνο ο δημιουργός"
   :enforcement :convention
   :evidence "CLAUDE.md:1-40")
  (:name "tag-release (αυτόματο git tag σε main)"
   :what-it-can-decide "Δημιουργεί και σπρώχνει tag v1.3.<run_number> χωρίς ανθρώπινη έγκριση."
   :who-can-invoke "CI, αυτόματα σε κάθε πράσινο push στο main"
   :enforcement :code
   :evidence ".github/workflows/docker-orchestrator.yml:359-378"))

 ;; ══════════════════════════════════════════════════════════════════════
 :invariants
 ((:statement "The only subprocess is the Lisp runtime itself"
   :enforced-by :none :mechanism :text-only :evidence "README.md:20-21")
  (:statement "Zero shell-script orchestration in the trusted path"
   :enforced-by :none :mechanism :text-only :evidence "README.md:19")
  (:statement "Zero Python dependencies"
   :enforced-by :none :mechanism :text-only :evidence "README.md:18")
  (:statement "100% Common Lisp / Pure Lisp 100%"
   :enforced-by :none :mechanism :text-only :evidence "README.md:8 README.md:16 README.md:389")
  (:statement "Multi-stage hermetic build"
   :enforced-by :none :mechanism :text-only :evidence "Dockerfile:5")
  (:statement "hermetic: enabled: true / no_network: true (machine-readable)"
   :enforced-by :none :mechanism :text-only :evidence "PROVENANCE.yaml:292-295")
  (:statement "Criterion 2: Hermetic build without network — docker build --network=none ."
   :enforced-by :none :mechanism :text-only :evidence "DEPENDENCY-CONTRACT.md:168-173")
  (:statement "NO Quicklisp"
   :enforced-by :convention :mechanism :guard
   :note "Ο δηλωμένος φρουρός (grep σε source/ systems/) ΕΠΙΣΤΡΕΦΕΙ ΗΔΗ ΕΥΡΗΜΑΤΑ και ΤΑΥΤΟΧΡΟΝΑ αστοχεί να καλύψει το Dockerfile.test."
   :evidence "DEPENDENCY-CONTRACT.md:183-188 Dockerfile:108 build.lisp:11")
  (:statement "Base image pinned by digest (not tag)"
   :enforced-by :code :mechanism :structural :evidence "Dockerfile:23 Dockerfile:29 Dockerfile:53 Dockerfile:333")
  (:statement "Reproducible builds via SOURCE_DATE_EPOCH"
   :enforced-by :code :mechanism :guard :evidence "Dockerfile:17 Dockerfile:64 Dockerfile:206")
  (:statement "Το runtime ΔΕΝ κατασκευάζεται χωρίς να έχουν περάσει standalone-test + verifier-conformance"
   :enforced-by :code :mechanism :structural :evidence "Dockerfile:391-397")
  (:statement "Ο producer ΔΕΝ βλέπει ποτέ ιδιωτικό κλειδί"
   :enforced-by :os :mechanism :structural :evidence "docker-compose.yml:59-61 docker-compose.yml:310 docker-compose.yml:355-357")
  (:statement "deps.lock: every dir under third-party/ is pinned (bijective). No network."
   :enforced-by :code :mechanism :structural
   :note "Το «bijective» ΕΠΑΛΗΘΕΥΤΗΚΕ 58↔58· το «No network» ΔΕΝ ισχύει για το build συνολικά."
   :evidence "deps.lock:7"))

 ;; ══════════════════════════════════════════════════════════════════════
 :defects
 (;; ── Η ΕΙΔΙΚΗ ΕΝΤΟΛΗ ──
  (:what "GATE-4 «Pipeline integrity (no subprocess)» δηλώνεται στον πίνακα πυλών του README αλλά ΔΕΝ ΥΠΑΡΧΕΙ ως κώδικας πουθενά. Εξαντλητική σάρωση *.lisp/*.md/*.asd/*.yml/*.yaml: μοναδική εμφάνιση με αυτή τη σημασία = README.md:304. Οι 25 πραγματικές εντολές -gate δεν περιλαμβάνουν καμία πύλη subprocess/purity, και το source/pdf-authority.lisp ΔΕΝ ΣΑΡΩΝΕΤΑΙ από τίποτα. Μηδέν αναφορές «GATE-4» σε ολόκληρο το deployment/collab/dialogue/ και docs/ ⇒ το κενό δεν είναι καταγεγραμμένο."
   :severity :p1
   :evidence "README.md:304 source/pdf-authority.lisp:1386-1425 README.md:185-187"
   :is-it-in-the-known-defect-list :no)
  (:what "README.md:253 δηλώνει source/gate-guards.lisp («CI/CD guards (Pure Lisp)») στο δέντρο αρχιτεκτονικής· το αρχείο ΔΕΝ ΥΠΑΡΧΕΙ στο source/."
   :severity :p1
   :evidence "README.md:253"
   :is-it-in-the-known-defect-list :yes)
  (:what "source/pdf-authority.lisp:28 δηλώνει «DARPA-GRADE: No Python, no subprocess, direct C library access» ενώ το ΙΔΙΟ αρχείο εκκινεί 5 subprocess (which pdftoppm, which tesseract, tesseract --list-langs, pdftoppm, tesseract) στις γραμμές 1386-1425. Η κεφαλίδα διαψεύδεται από το σώμα του ίδιου αρχείου."
   :severity :p1
   :evidence "source/pdf-authority.lisp:28 source/pdf-authority.lisp:1386-1425"
   :is-it-in-the-known-defect-list :yes)

  ;; ── ΔΗΛΩΣΕΙΣ ΧΩΡΙΣ ΜΗΧΑΝΙΣΜΟ ──
  (:what "«100% Common Lisp» / «Pure Lisp 100%»: το repo περιέχει 59 μη-Lisp αρχεία πηγής εκτός third-party/ και output/ — 22 .py, 27 .sh, 6 .js, 2 .mjs, 2 .ts. Η ΤΕΛΙΚΗ ΚΡΙΣΗ της ολομέλειας πυλών αποδίδεται από bash (deployment/verify/assess-gate-plenary.sh) και το build-gate του proof manifest από Python."
   :severity :p1
   :evidence "README.md:8 README.md:16 README.md:389 .github/workflows/docker-orchestrator.yml:298-299 Dockerfile:316"
   :is-it-in-the-known-defect-list :no)
  (:what "«Multi-stage hermetic build» (Dockerfile:5) + machine-readable «hermetic: enabled: true, no_network: true» (PROVENANCE.yaml:292-295) + «Criterion 2 ✅ docker build --network=none» (DEPENDENCY-CONTRACT.md:168-173): και τα τρία διαψεύδονται από 3× apt-get update && apt-get install χωρίς καθήλωση εκδόσεων. Με --network=none το stage 1 αποτυγχάνει αμέσως."
   :severity :p1
   :evidence "Dockerfile:5 Dockerfile:41-43 Dockerfile:68-77 Dockerfile:363-377 PROVENANCE.yaml:292-295 DEPENDENCY-CONTRACT.md:168-173"
   :is-it-in-the-known-defect-list :no)
  (:what "SEMANTIC-CONTRACT.md §1.2/§1.3 δηλώνουν «GUARANTEE» για blockchain-anchored timestamp και ανιχνευσιμότητα αλλοίωσης, ενώ source/blockchain-authority.lisp:927-942 κάνει (declare (ignore response)) και επιστρέφει (= status 200) — δεν ελέγχει ΠΟΤΕ ότι τα bytes hash-άρουν στην αξιωμένη τιμή. Το ίδιο το repo το ονομάζει «verification theatre» σε ΑΛΛΟ έγγραφο."
   :severity :p1
   :evidence "SEMANTIC-CONTRACT.md:36-56 source/blockchain-authority.lisp:927-942 docs/SECURITY-REDTEAM.md:54-66"
   :is-it-in-the-known-defect-list :yes)
  (:what "SEMANTIC-CONTRACT.md:22-24 δηλώνει ΕΓΓΥΗΣΗ «All releases, commits, and tags are signed with GPG», αλλά το provenance.yml παρακάμπτει σιωπηλά την υπογραφή όταν λείπει το secret (if: secrets.GPG_PRIVATE_KEY == '') με απλό echo warning — η εγγύηση υποβαθμίζεται σε προαιρετική χωρίς κόκκινο."
   :severity :p1
   :evidence "SEMANTIC-CONTRACT.md:22-24 .github/workflows/provenance.yml:128 .github/workflows/provenance.yml:143-151"
   :is-it-in-the-known-defect-list :no)

  ;; ── ΕΝΤΟΛΕΣ ΕΠΑΛΗΘΕΥΣΗΣ ΠΟΥ ΔΕΝ ΕΚΤΕΛΟΥΝΤΑΙ ──
  (:what "ΤΕΣΣΕΡΑ δηλωμένα scripts επαλήθευσης ΔΕΝ ΥΠΑΡΧΟΥΝ: PROVENANCE.yaml:286 «scripts/verify-deps.sh», PROVENANCE.yaml:289 «scripts/generate-deps-lock.sh», DEPENDENCY-CONTRACT.md:194+213 «docker/verify-deps.sh», SEMANTIC-CONTRACT.md:61 «./scripts/verify-deterministic-build.sh». Τα πραγματικά είναι docker/verify-deps.lisp και scripts/gen-deps-lock.lisp — δηλαδή ΤΡΙΑ διαφορετικά ονόματα για την ΙΔΙΑ έδρα σε τρία συμβόλαια."
   :severity :p1
   :evidence "PROVENANCE.yaml:286 PROVENANCE.yaml:289 DEPENDENCY-CONTRACT.md:194 SEMANTIC-CONTRACT.md:61 deps.lock:5-6"
   :is-it-in-the-known-defect-list :no)
  (:what "SEMANTIC-CONTRACT.md:60 διδάσκει «sha256sum -c deps.lock» — δομικά αδύνατο: το deps.lock είναι «<dir> | <sha256>» (deps.lock:2), όχι η μορφή «<hash>  <path>» που δέχεται το sha256sum -c."
   :severity :p2
   :evidence "SEMANTIC-CONTRACT.md:60 deps.lock:2"
   :is-it-in-the-known-defect-list :no)
  (:what "DEPENDENCY-CONTRACT.md:183-188 «Criterion 4: No Quicklisp runtime calls ✅» με grep σε source/ systems/: (α) εκτελούμενο ΣΗΜΕΡΑ ΕΠΙΣΤΡΕΦΕΙ ΕΥΡΗΜΑΤΑ (systems/orchestrator-omega-modules/omega-package.lisp:46 + README.md:116-211) ⇒ το κριτήριο που δηλώνεται ✅ αποτυγχάνει· (β) το πεδίο του grep αποκλείει ΑΚΡΙΒΩΣ τον χώρο της πραγματικής παράβασης (Dockerfile.test:29, MANUAL-STEPS-HERMETIC.md:59). Φρουρός γύρω από λάθος σχήμα."
   :severity :p1
   :evidence "DEPENDENCY-CONTRACT.md:183-188 systems/orchestrator-omega-modules/omega-package.lisp:46 Dockerfile.test:29"
   :is-it-in-the-known-defect-list :no)

  ;; ── ΠΑΡΑΔΟΣΗ / DOCKER ──
  (:what "docker-compose.yml:17 — αδέσποτο εισαγωγικό στο tmpfs option της ΚΥΡΙΑΣ υπηρεσίας: «- /tmp:size=256m,mode=1777\"». Οι άλλες τέσσερις tmpfs γραμμές (133, 210, 299, 348) δεν το έχουν. Είναι η υπηρεσία που τρέχει το τεκμηριωμένο «docker compose up»."
   :severity :p1
   :evidence "docker-compose.yml:17 docker-compose.yml:133 docker-compose.yml:210"
   :is-it-in-the-known-defect-list :no)
  (:what "Το τεκμηριωμένο quickstart «docker compose build && docker compose up» (README:64-65) δεν μπορεί να πετύχει: το compose περνά GIT_COMMIT default «dev» ενώ ο Dockerfile απαιτεί ακριβώς 40-hex αλλιώς FATAL exit 1 — και το target runtime περνά υποχρεωτικά από εκείνο το στάδιο."
   :severity :p1
   :evidence "docker-compose.yml:8 Dockerfile:172-173 README.md:64-65"
   :is-it-in-the-known-defect-list :no)
  (:what "authority-v2-proofs: privileged:true + ΟΛΟΚΛΗΡΟ το repo ως «.:/repo:rw» + bash + apt-get install sbcl python3 util-linux + image debian:bookworm-slim με UNPINNED tag (ενώ ο Dockerfile καρφώνει digest). Είναι η υπηρεσία που παράγει τις αποδείξεις ορίου πυρήνα."
   :severity :p1
   :evidence "docker-compose.yml:376-397 Dockerfile:23"
   :is-it-in-the-known-defect-list :no)
  (:what "Dockerfile.test κατεβάζει Quicklisp από το δίκτυο (curl https://beta.quicklisp.org/quicklisp.lisp) και κάνει ql:quickload :fiveam ως root, ενώ Dockerfile:108, build.lisp:11 και DEPENDENCY-CONTRACT.md:207 δηλώνουν ρητά «NO Quicklisp». Κανένα build/CI/compose αρχείο δεν το αναφέρει."
   :severity :p1
   :evidence "Dockerfile.test:9-30 Dockerfile:108 build.lisp:11 DEPENDENCY-CONTRACT.md:207"
   :is-it-in-the-known-defect-list :yes)
  (:what ".github/workflows/docker-orchestrator.yml:228-234 — «curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh»: εκτέλεση απομακρυσμένου, μη καθηλωμένου κώδικα από το internet μέσα στο CI που παράγει το SBOM εφοδιαστικής αλυσίδας."
   :severity :p1
   :evidence ".github/workflows/docker-orchestrator.yml:228-234"
   :is-it-in-the-known-defect-list :no)
  (:what "CI βήμα «Smoke test orchestrator loading» κάνει asdf:load-asd \"/app/orchestrator.asd\" στο orchestrator:test, αλλά το runtime stage δεν αντιγράφει ΚΑΝΕΝΑ .asd (μηδέν αναφορές asd στις γραμμές 333-453) ΚΑΙ το βήμα δεν κάνει --entrypoint override — σε αντίθεση με τη γραμμή 306 που το κάνει ρητά για τον ίδιο σκοπό."
   :severity :p1
   :evidence ".github/workflows/docker-orchestrator.yml:338-346 Dockerfile:394-410 .github/workflows/docker-orchestrator.yml:306"
   :is-it-in-the-known-defect-list :no)
  (:what "package.json δηλώνει playwright ^1.61.0 (headless Chromium) σε repo που δηλώνει «100% Common Lisp». Η αλυσίδα είναι ΖΩΝΤΑΝΗ και ρυθμισμένη: configs/constitution.yaml:90 fetch_cmd «bash deployment/fetch-fek-by-number.sh Α 111 1975 {{out}}» → run-fetch-command /bin/sh -c → deployment/fetch-fek.sh:16,67 → node + Playwright. (Το .dockerignore:77 αποκλείει το package.json από την εικόνα, όχι το configs/.)"
   :severity :p1
   :evidence "package.json:1-5 configs/constitution.yaml:90 source/document-fetch.lisp:92-106 deployment/fetch-fek.sh:16-23 .dockerignore:77"
   :is-it-in-the-known-defect-list :no)
  (:what "source.fetch_cmd → sh -c είναι RCE-by-design για όποιον μπορεί να επεξεργαστεί ένα corpus YAML· το {{out}} templating είναι αχειραγώγητο/μη-quoted. Το configs/ αντιγράφεται ΜΕΣΑ στο runtime image."
   :severity :p1
   :evidence "docs/SECURITY-REDTEAM.md:84-88 configs/constitution.yaml:90 Dockerfile:400"
   :is-it-in-the-known-defect-list :yes)

  ;; ── .asd / ΕΔΡΕΣ ──
  (:what "orchestrator-tooling.asd: ΠΛΗΡΩΣ ΟΡΦΑΝΟ — μηδέν αναφορές σε ολόκληρο το repo, :components () κενό."
   :severity :p2
   :evidence "orchestrator-tooling.asd:5-20"
   :is-it-in-the-known-defect-list :no)
  (:what "5 .asd δηλώνουν test-op (orchestrator, orchestrator-core-runtime, orchestrator-omega, orchestrator-tests, orchestrator-tests-runtime) αλλά ΚΑΝΕΝΑ Dockerfile / .github/workflows / docker-compose δεν καλεί ποτέ asdf test-op — νεκρές δηλώσεις. Η πραγματική εκτέλεση γίνεται μέσω docker/run-standalone-suites.sh."
   :severity :p2
   :evidence "orchestrator-core-runtime.asd:31 orchestrator.asd:41 orchestrator-tests-runtime.asd:24 orchestrator-omega.asd:139 Dockerfile:189-192"
   :is-it-in-the-known-defect-list :no)
  (:what "3 .asd έχουν κενό :components () — core-runtime, tests-runtime, tooling: είναι καθαροί συναθροιστές μέσω :depends-on, χωρίς δικά τους αρχεία."
   :severity :p2
   :evidence "orchestrator-core-runtime.asd:29 orchestrator-tests-runtime.asd:22 orchestrator-tooling.asd:20"
   :is-it-in-the-known-defect-list :no)
  (:what "orchestrator-epistemic ΔΕΝ φορτώνεται από το build.lisp (φορτώνει ΜΟΝΟ :orchestrator-core-runtime), ενώ README:230 διδάσκει (orchestrator.engine:run-epistemic-pipeline) ως τρόπο εκτέλεσης του αγωγού."
   :severity :p2
   :evidence "build.lisp:34 README.md:227-230"
   :is-it-in-the-known-defect-list :no)

  ;; ── ΠΑΛΙΩΜΕΝΑ ΣΥΜΒΟΛΑΙΑ ──
  (:what "ARG SBCL_VERSION=2.4.0 δηλώνεται ΔΥΟ φορές (16, 56) και ΔΕΝ χρησιμοποιείται πουθενά· η SBCL εγκαθίσταται unpinned μέσω apt σε 3 στάδια. Η δηλωμένη έκδοση είναι διακοσμητική. Από τα 6 δηλωμένα ARG, 5 χρησιμοποιούνται (SOURCE_DATE_EPOCH, DEBIAN_DIGEST, GIT_COMMIT, BUILD_DATE, VERSION) και 1 όχι."
   :severity :p2
   :evidence "Dockerfile:16 Dockerfile:56 Dockerfile:41-43 Dockerfile:68-69 Dockerfile:374"
   :is-it-in-the-known-defect-list :no)
  (:what "MANUAL-STEPS-HERMETIC.md:29 δηλώνει «deps.lock με 48 total dependencies» ενώ το πραγματικό deps.lock έχει 58. Το ίδιο έγγραφο (γραμμή 5) παραδέχεται «~95% hermetic» — που αντιφάσκει με το απόλυτο «hermetic» του Dockerfile:5 και του PROVENANCE.yaml:293. Επίσης διπλή εγγραφή trivial-macroexpand-all (21, 22)."
   :severity :p2
   :evidence "MANUAL-STEPS-HERMETIC.md:5 MANUAL-STEPS-HERMETIC.md:21-22 MANUAL-STEPS-HERMETIC.md:29 deps.lock"
   :is-it-in-the-known-defect-list :no)
  (:what "Απόκλιση έκδοσης: SYSTEM-HIERARCHY.txt:2 «ORCHESTRATOR v1.3»· README.md:6,389 + Dockerfile:338 + orchestrator.asd:13 + CHANGELOG.md:3 «1.2.0»· CI παράγει tags «v1.3.<run_number>»."
   :severity :p2
   :evidence "SYSTEM-HIERARCHY.txt:2 README.md:389 Dockerfile:338 .github/workflows/docker-orchestrator.yml:371"
   :is-it-in-the-known-defect-list :no)
  (:what "SYSTEM-HIERARCHY.txt:5-8 δηλώνει «ΚΟΡΥΦΑΙΟ ΣΗΜΕΙΟ ΕΙΣΟΔΟΥ (ONE ENTRY POINT): unified-frbr-generator.lisp» — τρίτη, ασύμβατη δήλωση «μοναδικής εισόδου» δίπλα στο entrypoint.lisp και το orchestrator.cli:main."
   :severity :p2
   :evidence "SYSTEM-HIERARCHY.txt:5-8 Dockerfile:452 build.lisp:44"
   :is-it-in-the-known-defect-list :no)
  (:what "deps.archives.lock είναι ΚΕΝΟ — περιέχει μόνο τη γραμμή σχολίου «# name sha256(zip)» (20 bytes)."
   :severity :p2
   :evidence "deps.archives.lock:1"
   :is-it-in-the-known-defect-list :no)
  (:what ".env.example δηλώνει POSTGRES_/GRAFANA_/SLACK_WEBHOOK/TELEMETRY_ENDPOINT ενώ το docker-compose.yml δεν έχει καμία τέτοια υπηρεσία (postgres/redis είναι σχολιασμένα στις 409-411)."
   :severity :p2
   :evidence ".env.example:22-29 docker-compose.yml:409-411"
   :is-it-in-the-known-defect-list :no)
  (:what "tools/independent-audit.py: το ΜΟΝΟ αρχείο του tools/ είναι Python που απαιτεί «pip install pymupdf» — μη κλειδωμένο σε deps.lock, μη εκτελούμενο από CI. Τα ευρήματα ορθότητας 4.691 άρθρων (docs/AUDIT-8-QUIRKS.md:3) στηρίζονται σε αυτό."
   :severity :p2
   :evidence "tools/independent-audit.py:1-20 docs/AUDIT-8-QUIRKS.md:3"
   :is-it-in-the-known-defect-list :no)
  (:what "Τα 3 NOT-CI-gated compose test αρχεία χρησιμοποιούν «version: '3.8'» (καταργημένο κλειδί) και target: builder με «.:/workspace:ro» — τρέχουν εκτός της αποδεικτικής αλυσίδας· το README:174-181 τα καταγράφει ρητά ως follow-up χρέος."
   :severity :p2
   :evidence "docker-compose.architecture-tests.yml:1-16 README.md:174-181"
   :is-it-in-the-known-defect-list :yes))

 ;; ══════════════════════════════════════════════════════════════════════
 :hidden-execution-paths
 ((:path "/bin/sh -c <command> (run-fetch-command) → bash deployment/fetch-fek*.sh → node deployment/fetch-fek.js → headless Chromium (Playwright)"
   :trigger "source.fetch_cmd από corpus YAML· ρυθμισμένο ΖΩΝΤΑΝΑ στο configs/constitution.yaml:90"
   :why-hidden "README:19-21 δηλώνει μηδέν shell και μοναδικό subprocess τον Lisp runtime. Το configs/ αντιγράφεται στο runtime image."
   :evidence "source/document-fetch.lisp:92-106 configs/constitution.yaml:90 deployment/fetch-fek.sh:16-23 Dockerfile:400")
  (:path "pdftoppm -r 300 -png → tesseract -l ell → which/--list-langs"
   :trigger "extract-text-any σε σαρωμένο PDF (text layer < 600 chars)"
   :why-hidden "Καμία πύλη δεν το σαρώνει (η δηλωμένη GATE-4 δεν υπάρχει)· τα binaries εγκαθίστανται ρητά στο runtime image."
   :evidence "source/pdf-authority.lisp:1399-1425 Dockerfile:371-373")
  (:path "bash /app/scripts/merkle-mutation-witness.sh + /app/docker/run-standalone-suites.sh"
   :trigger "docker build --target standalone-test / verifier-conformance"
   :why-hidden "Bash μέσα στην ΥΠΟΧΡΕΩΤΙΚΗ αποδεικτική αλυσίδα που παράγει το runtime."
   :evidence "Dockerfile:167 Dockerfile:189-192 Dockerfile:290")
  (:path "python3 verify-canonical.py / verify-merkle.py / verify-proof-manifest.py + node verify-merkle.mjs"
   :trigger "docker build --target verifier-conformance (υποχρεωτικός πρόγονος του runtime)"
   :why-hidden "README:18 «Zero Python dependencies»· εδώ η Python είναι ΠΥΛΗ που μπλοκάρει την παραγωγή του runtime."
   :evidence "Dockerfile:259 Dockerfile:284-285 Dockerfile:316")
  (:path "curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh"
   :trigger "CI job build-and-test, βήμα Generate SBOM"
   :why-hidden "Απομακρυσμένη, μη καθηλωμένη εκτέλεση κώδικα μέσα σε workflow εφοδιαστικής αλυσίδας."
   :evidence ".github/workflows/docker-orchestrator.yml:228-234")
  (:path "docker/entrypoint.lisp run-subprocess (sb-ext:run-program :wait t)"
   :trigger "κάθε εκκίνηση container"
   :why-hidden "fork+wait, ΟΧΙ exec — ο Lisp wrapper παραμένει ζωντανός γονέας, άρα δύο διεργασίες, ενώ το README λέει «execs»."
   :evidence "docker/entrypoint.lisp:67-77 Dockerfile:452")
  (:path "authority-v2-proofs: privileged container, repo rw, apt-get install, bash run-proofs.sh"
   :trigger "docker compose --profile proofs up"
   :why-hidden "Μοναδικό σημείο με privileged:true και εγγράψιμη πρόσβαση σε ΟΛΟ το repo."
   :evidence "docker-compose.yml:376-397")
  (:path "tag-release: αυτόματο git tag + push σε κάθε πράσινο main"
   :trigger "push στο main με πράσινα build-and-test + authority-v2-boundary"
   :why-hidden "Το CLAUDE.md:«Μόνο ο δημιουργός συγχωνεύει/εγκρίνει φάσεις» — εδώ το CI εκδίδει ταυτότητα έκδοσης χωρίς ανθρώπινη πράξη."
   :evidence ".github/workflows/docker-orchestrator.yml:359-378"))

 ;; ══════════════════════════════════════════════════════════════════════
 :duplicate-seats
 ((:concept "container entrypoint"
   :seats ("entrypoint.lisp:1-83 — ΟΡΦΑΝΟ: φορτώνει :orchestrator + :orchestrator-tests και ΤΡΕΧΕΙ ΤΗ ΣΟΥΙΤΑ ΤΕΣΤ· αντιγράφεται στον builder (Dockerfile:104) αλλά ΔΕΝ εκτελείται ποτέ"
           "docker/entrypoint.lisp:1-182 — ΤΟ ΠΡΑΓΜΑΤΙΚΟ (Dockerfile:409 → /app/entrypoint.lisp, Dockerfile:452)"))
  (:concept "aggregate system definition (ίδια 10 υποσυστήματα)"
   :seats ("orchestrator.asd:19-28" "orchestrator-core-runtime.asd:17-26"))
  (:concept "ποιο σύστημα φορτώνεται για να τρέξει ο αγωγός"
   :seats ("build.lisp:34 → :orchestrator-core-runtime" "entrypoint.lisp:16 → :orchestrator" "README.md:227 → :orchestrator-omega"))
  (:concept "όνομα του verifier εξαρτήσεων"
   :seats ("PROVENANCE.yaml:286 scripts/verify-deps.sh (ΑΝΥΠΑΡΚΤΟ)"
           "DEPENDENCY-CONTRACT.md:194+213 docker/verify-deps.sh (ΑΝΥΠΑΡΚΤΟ)"
           "deps.lock:6 + Dockerfile:48 docker/verify-deps.lisp (ΠΡΑΓΜΑΤΙΚΟ)"))
  (:concept "verify-proof-manifest (δύο ΔΙΑΦΟΡΕΤΙΚΑ αρχεία, διαφορετικά sha256)"
   :seats ("docker/verify-proof-manifest.py (295 γραμμές, gate του build)"
           "authority-v2/proofs/verify-proof-manifest.py (95 γραμμές)"))
  (:concept "edge content negotiation για το ίδιο site"
   :seats ("cloudflare/src/worker.ts (standalone Worker)"
           "cloudflare/functions/_middleware.ts (Pages Function — «recommended»)"))
  (:concept "health file path"
   :seats ("Dockerfile:445-447 /run/lawmax/.healthy (HEALTHCHECK)"
           "docker/entrypoint.lisp:162-164 σχόλιο που ακόμη λέει /app/output/.healthy"))
  (:concept "δήλωση «ONE ENTRY POINT»"
   :seats ("SYSTEM-HIERARCHY.txt:5-8 unified-frbr-generator.lisp"
           "Dockerfile:452 /app/entrypoint.lisp"
           "build.lisp:44 orchestrator.cli:main")))

 ;; ══════════════════════════════════════════════════════════════════════
 :unknowns
 ("Αν το docker build πετυχαίνει ΠΡΑΓΜΑΤΙΚΑ σήμερα — καμία εκτέλεση δεν επιτρεπόταν (στατική αρχαιολογία μόνο)."
  "Αν το CI βήμα «Smoke test orchestrator loading» έχει τρέξει ποτέ πράσινο· δεν βρέθηκε αποθηκευμένο log στο /frozen/ro."
  "Αν το GIT_COMMIT περνιέται σωστά σε ΚΑΘΕ τοπική διαδρομή του δημιουργού — μόνο το CI το δίνει ρητά (github.sha)."
  "Ακριβής αριθμός os-exec sites συνολικά: το deployment/collab/dialogue/0094-claude.md:82 δηλώνει 19· η δική μου σάρωση εντόπισε 6 uiop:run-program σε source/ + 1 sb-ext:run-program σε docker/entrypoint.lisp. Η διαφορά δεν συμφιλιώθηκε."
  "Αν τα 5 κενά fetch_cmd (astikos/kdioikitikis/kpoinikis/kpolitikis/poinikoskodikas) σημαίνουν απενεργοποιημένο μονοπάτι ή απλώς αρύθμιστο."
  "Περιεχόμενο 14 από τα 18 docs/ αρχείων διαβάστηκε μόνο σε επίπεδο δομής/επικεφαλίδων, όχι γραμμή-προς-γραμμή (AUDIT-8-QUIRKS, BRAIN, CURRENTNESS-34, ELI-IMPLEMENTATION-PHASES, IMPLEMENTATION-COMPLETE, ROADMAP-EUROPE, και τα 8 docs/history/)."
  "configs/huggingface-dataset.json και configs/prometheus-citation.yml: διαβάστηκαν μόνο ως δομή· δεν κρίθηκε αν οι δηλωμένοι scrape targets/datasets αντιστοιχούν σε κάτι ζωντανό."
  "Αν το «GATE-1/2/3/5» του README:300-305 έχουν υλοποίηση — ελέγχθηκε εξαντλητικά ΜΟΝΟ το GATE-4 κατά την ΕΙΔΙΚΗ ΕΝΤΟΛΗ."))
