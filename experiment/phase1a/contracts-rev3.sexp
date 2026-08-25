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
   :guarantees "ΚΑΜΙΑ. Εξαντλητική αναζήτηση σε *.lisp/*.md/*.asd/*.yml/*.yaml: το «GATE-4» με σημασία «pipeline integrity / no subprocess» εμφανίζεται ΜΟΝΟ στο README.md:L304-L304@sha256:97c747e9aa82. Το μόνο άλλο «GATE-4A» (systems/orchestrator-omega-modules/article-root-generator-omega.lisp:L175-L175@sha256:dfe99cf68b63, systems/orchestrator-omega-modules/hybrid-generator-phase1.lisp:L289-L289@sha256:1c4aba67d9a5) είναι ΑΣΧΕΤΟ (Single Emission Law)."
   :failure-semantics "Δεν υπάρχει μηχανισμός να αποτύχει· η δήλωση δεν μπορεί ποτέ να γίνει κόκκινη."
   :operating-model "Μόνο γραμμή πίνακα Markdown."
   :materiality "P1 με άγκυρα: η ΑΠΟΛΥΤΗ δήλωση README:20-21 «The only subprocess is the Lisp runtime itself» δεν φρουρείται από κανέναν μηχανισμό, ΚΑΙ το source/pdf-authority.lisp εκκινεί 5 subprocess χωρίς να το πιάνει τίποτα."
   :mechanism :text-only
   :evidence "README.md:L304-L304@sha256:97c747e9aa82")

  (:name "Ολομέλεια πυλών --gates (25 εντολές -gate)"
   :presence :present
   :domain "Αυτο-παραγόμενη ολομέλεια από το μητρώο εντολών."
   :assumptions "Κάθε εντολή με επίθημα -gate συμμετέχει (README:185-187)."
   :guarantees "25 ΔΙΑΚΡΙΤΕΣ εντολές -gate υπάρχουν πραγματικά στο μητρώο· η κρίση γίνεται από assess-gate-plenary.sh + assess-gate-manifest.lisp με set-equality έναντι gate-registry.sexp."
   :failure-semantics "fail-closed μέσω PIPESTATUS· baseline exception ΜΟΝΟ advisor-gate."
   :operating-model "docker run orchestrator:test --gates με mounted source."
   :materiality "ΚΑΜΙΑ από τις 25 δεν είναι πύλη subprocess/purity. Η ονοματολογία GATE-1..GATE-5 του README:300-305 ΔΕΝ αντιστοιχίζεται σε καμία από τις 25."
   :mechanism :guard
   :evidence ".github/workflows/docker-orchestrator.yml:L292-L308@sha256:f1a4bb69e6e4 README.md:L185-L187@sha256:97c747e9aa82")

  (:name "Πραγματικά subprocess seats στον κώδικα"
   :presence :present
   :domain "Εκκίνηση εξωτερικών διεργασιών από τον πυρήνα."
   :assumptions "uiop:run-program· εξωτερικά binaries στο PATH."
   :guarantees "Καμία απομόνωση. run-fetch-command περνά ΑΥΘΑΙΡΕΤΟ string σε /bin/sh -c."
   :failure-semantics "pdf-authority: σιωπηλό NIL (:1424)· document-fetch: (values -1 msg), «never throws» (:106)."
   :operating-model "Runtime, ΜΕΣΑ στο production image."
   :materiality "6 call sites σε 2 αρχεία. Τα binaries poppler-utils/tesseract-ocr/tesseract-ocr-ell ΕΓΚΑΘΙΣΤΑΝΤΑΙ ΡΗΤΑ στο runtime stage — η εικόνα παραγωγής κουβαλά τα εργαλεία που η δήλωση αρνείται."
   :mechanism :structural
   :evidence "source/document-fetch.lisp:L92-L106@sha256:bb114b83fd80 source/pdf-authority.lisp:L1386-L1425@sha256:c4e2054c0e4f Dockerfile:L371-L373@sha256:9280f921e1a7")

  (:name "Python ως ΥΠΟΧΡΕΩΤΙΚΗ εξάρτηση κατασκευής του runtime"
   :presence :present
   :domain "Κατασκευή της production εικόνας."
   :assumptions "apt δικτυακά διαθέσιμο· python3 + python3-rdflib + nodejs εγκαθίστανται."
   :guarantees "Fail-closed: το runtime ΔΕΝ χτίζεται αν αποτύχει έστω ένα python3 gate (Dockerfile:L316-L316@sha256:9280f921e1a7 «αλλιώς ΤΟ RUNTIME ΔΕΝ ΧΤΙΖΕΤΑΙ»)."
   :failure-semantics "build red."
   :operating-model "Stage verifier-conformance — ΥΠΟΧΡΕΩΤΙΚΟΣ πρόγονος του runtime μέσω COPY --from=verifier-conformance."
   :materiality "README:18 «Zero Python dependencies». Το runtime ΔΕΝ ΜΠΟΡΕΙ ΝΑ ΠΑΡΑΧΘΕΙ χωρίς python3: 4 ρητά python3 βήματα + 1 node βήμα είναι πύλες."
   :mechanism :structural
   :evidence "Dockerfile:L241-L245@sha256:9280f921e1a7 Dockerfile:L259-L259@sha256:9280f921e1a7 Dockerfile:L284-L285@sha256:9280f921e1a7 Dockerfile:L316-L316@sha256:9280f921e1a7 Dockerfile:L394-L394@sha256:9280f921e1a7")

  (:name "Shell ως έδρα εκτέλεσης ΚΑΙ κρίσης της αποδεικτικής αλυσίδας"
   :presence :present
   :domain "Εκτέλεση των tests/*-test.lisp και ΤΕΛΙΚΗ ΚΡΙΣΗ της ολομέλειας."
   :assumptions "bash με pipefail."
   :guarantees "fail-closed (pipefail + PIPESTATUS)."
   :failure-semantics "sbcl exit != 0 ⇒ build/CI red."
   :operating-model "docker/run-standalone-suites.sh (η ΜΙΑ έδρα εκτέλεσης) και deployment/verify/assess-gate-plenary.sh (η ΜΙΑ έδρα κρίσης)."
   :materiality "README:19 «Zero shell-script orchestration in the trusted path». Η τελική ετυμηγορία ορθότητας αποδίδεται από bash script· Dockerfile:L167-L167@sha256:9280f921e1a7 θέτει SHELL σε /bin/bash."
   :mechanism :structural
   :evidence "Dockerfile:L167-L167@sha256:9280f921e1a7 Dockerfile:L189-L192@sha256:9280f921e1a7 Dockerfile:L290-L290@sha256:9280f921e1a7 .github/workflows/docker-orchestrator.yml:L298-L299@sha256:f1a4bb69e6e4")

  (:name "deps.lock — αμφιμονοσήμαντο κλείδωμα εξαρτήσεων"
   :presence :present
   :domain "Ταυτότητα των 58 vendored βιβλιοθηκών."
   :assumptions "Ο κατάλογος third-party/ είναι πλήρης· ο αλγόριθμος docker/dep-hash.lisp είναι σταθερός."
   :guarantees "ΕΠΑΛΗΘΕΥΜΕΝΗ ΑΜΦΙΜΟΝΟΣΗΜΑΝΤΗ ΑΝΤΙΣΤΟΙΧΙΑ 58↔58 (diff καθαρό: κάθε εγγραφή deps.lock = ένας κατάλογος third-party/, καμία περίσσεια, καμία απουσία)."
   :failure-semantics "Fail-closed: το stage 1 τρέχει ΠΡΙΝ εμπιστευθεί οποιαδήποτε vendored lib (Dockerfile:L36-L37@sha256:9280f921e1a7)."
   :operating-model "Stage deps-verify, ΚΑΘΑΡΟ LISP (verify-deps.lisp + αυτοτελές sha256.lisp, χωρίς third-party)."
   :materiality "Ο ΙΣΧΥΡΟΤΕΡΟΣ δομικός μηχανισμός της συστάδας — δήλωση ΚΑΙ επιβολή συμπίπτουν."
   :mechanism :structural
   :evidence "deps.lock:L1-L7@sha256:c4b43d610f97 Dockerfile:L29-L48@sha256:9280f921e1a7")

  (:name "Διαχωρισμός ρόλων παραγωγού / υπογράφοντα (compose)"
   :presence :present
   :domain "Απομόνωση ιδιωτικού κλειδιού από τον μη-έμπιστο παραγωγό."
   :assumptions "Ο χειριστής τρέχει τα δηλωμένα profiles· το Docker επιβάλλει uid/mount."
   :guarantees "producer/orchestrator/ingestion (11002) βλέπουν ΜΟΝΟ ./keys/public· ΜΟΝΟ ο authority-signer (11001) προσαρτά ./keys/private· η authority store είναι named volume που κανένας παραγωγός δεν προσαρτά."
   :failure-semantics "read_only rootfs + cap_drop ALL + no-new-privileges σε 4 υπηρεσίες· γραφή μόνο σε ρητά δηλωμένα mounts/tmpfs."
   :operating-model "OS/Docker level, ξεχωριστά uid ανά ρόλο."
   :materiality "Δομικός μηχανισμός: η υποκλοπή κλειδιού από τον παραγωγό είναι ΑΔΥΝΑΤΗ, όχι απαγορευμένη."
   :mechanism :structural
   :evidence "docker-compose.yml:L29-L32@sha256:ff93c313b8fe docker-compose.yml:L283-L312@sha256:ff93c313b8fe docker-compose.yml:L314-L363@sha256:ff93c313b8fe docker-compose.yml:L399-L403@sha256:ff93c313b8fe")

  (:name "authority-signer / admission kernel"
   :presence :spec-only
   :domain "Υπογραφή release."
   :assumptions "—"
   :guarantees "ΚΑΜΙΑ. Η υπηρεσία ΑΡΝΕΙΤΑΙ ρητά και βγαίνει exit 3."
   :failure-semantics "Πάντα exit 3 με ::error:: μήνυμα· ΔΕΝ προσποιείται ότι υπογράφει."
   :operating-model "entrypoint /bin/sh -c «echo … && exit 3»."
   :materiality "ΤΙΜΙΑ ΑΓΝΟΙΑ δηλωμένη ΣΤΗΝ ΙΔΙΑ ΤΗΝ ΕΔΡΑ: «ο admission kernel (απαίτηση 2/4 του Level-7) ΔΕΝ ΕΧΕΙ ΥΛΟΠΟΙΗΘΕΙ»."
   :mechanism :structural
   :evidence "docker-compose.yml:L327-L340@sha256:ff93c313b8fe")

  (:name "Temporal Provenance / Content Immutability (SEMANTIC-CONTRACT §1.2-1.3)"
   :presence :spec-only
   :domain "Απόδειξη ύπαρξης artifact σε χρόνο· ανιχνευσιμότητα αλλοίωσης."
   :assumptions "OpenTimestamps/IPFS/Arweave endpoints ενεργά."
   :guarantees "ΔΗΛΩΝΕΤΑΙ ως «GUARANTEE» ότι κάθε artifact έχει blockchain-anchored timestamp και ότι η αλλοίωση ανιχνεύεται. Ο ΜΗΧΑΝΙΣΜΟΣ ΔΕΝ ΤΟ ΚΑΝΕΙ."
   :failure-semantics "verify-anchor επιστρέφει T σε HTTP 200 ΑΓΝΟΩΝΤΑΣ ΡΗΤΑ το περιεχόμενο: (declare (ignore response)) … (= status 200). Καμία σύγκριση hash."
   :operating-model "drakma HTTP GET/POST."
   :materiality "Δύο έγγραφα του ΙΔΙΟΥ repo λένε τα ΑΝΤΙΘΕΤΑ: SEMANTIC-CONTRACT.md:L38-L38@sha256:260308c8e7ee SEMANTIC-CONTRACT.md:L51-L51@sha256:260308c8e7ee δηλώνει GUARANTEE· docs/SECURITY-REDTEAM.md:L54-L62@sha256:489f6a4c7a31 το χαρακτηρίζει «verification theatre» και OPEN."
   :mechanism :text-only
   :evidence "SEMANTIC-CONTRACT.md:L36-L56@sha256:260308c8e7ee docs/SECURITY-REDTEAM.md:L54-L66@sha256:489f6a4c7a31 source/blockchain-authority.lisp:L927-L942@sha256:caadc9c75a98")

  (:name "Reproducibility — byte-identical output υπό SOURCE_DATE_EPOCH"
   :presence :unknown
   :domain "Αναπαραγώγιμη κατασκευή."
   :assumptions "SOURCE_DATE_EPOCH=1735689600 σεβαστό από όλα τα στάδια."
   :guarantees "Το epoch ΟΝΤΩΣ διαδίδεται (ENV + proof manifest) και η base image είναι καρφωμένη σε digest."
   :failure-semantics "Δεν βρέθηκε ΚΑΝΕΝΑΣ μηχανισμός που να ΣΥΓΚΡΙΝΕΙ δύο builds· το δηλωμένο εργαλείο scripts/verify-deterministic-build.sh ΔΕΝ ΥΠΑΡΧΕΙ."
   :operating-model "ENV μεταβλητή."
   :materiality "Η αναπαραγωγιμότητα δηλώνεται (README:332) αλλά δεν μετριέται πουθενά· 3× apt-get update χωρίς pinning εκδόσεων την υπονομεύουν δομικά."
   :mechanism :text-only
   :evidence "README.md:L332-L332@sha256:97c747e9aa82 Dockerfile:L17-L17@sha256:9280f921e1a7 Dockerfile:L64-L64@sha256:9280f921e1a7 SEMANTIC-CONTRACT.md:L56-L62@sha256:260308c8e7ee")

  (:name "Έμπιστο μονοπάτι εκκίνησης (entrypoint)"
   :presence :present
   :domain "Από ENTRYPOINT μέχρι orchestrator.cli:main."
   :assumptions "tini ως PID 1· sbcl διαθέσιμο στο runtime."
   :guarantees "Ο πραγματικός entrypoint είναι ΚΑΘΑΡΟ LISP (docker/entrypoint.lisp), ανιχνεύει τύπο artifact από magic bytes, επικυρώνει καταλόγους, ΔΕΝ γράφει health."
   :failure-semantics "exit 127 αν λείπει το artifact· exit 1 αν λείπει δηλωμένος κατάλογος· διαδίδει το exit code του παιδιού."
   :operating-model "tini → sbcl --script entrypoint.lisp → sb-ext:run-program (fork+wait, ΟΧΙ exec) → orchestrator.core (ELF)."
   :materiality "Η δήλωση README:20-21 «execs orchestrator.core» είναι ΑΚΡΙΒΗΣ ως προς την πρόθεση αλλά ο wrapper παραμένει ζωντανός γονέας — δύο διεργασίες Lisp, όχι μία."
   :mechanism :structural
   :evidence "Dockerfile:L452-L452@sha256:9280f921e1a7 docker/entrypoint.lisp:L67-L77@sha256:b4f283f2abed docker/entrypoint.lisp:L115-L154@sha256:b4f283f2abed build.lisp:L43-L47@sha256:baa3527f5cf6"))

 ;; ══════════════════════════════════════════════════════════════════════
 :authorities
 ((:name "GIT_COMMIT 40-hex gate"
   :what-it-can-decide "Αν το build προχωρά· «proof χωρίς δεσμευμένο HEAD δεν είναι proof»."
   :who-can-invoke "docker build --build-arg GIT_COMMIT"
   :enforcement :code
   :evidence "Dockerfile:L172-L173@sha256:9280f921e1a7")
  (:name "runtime-assets sha256 self-check"
   :what-it-can-decide "Αν χτίζεται το runtime image: κάθε asset ≡ manifest του verified stage."
   :who-can-invoke "docker build (αυτόματο)"
   :enforcement :code
   :evidence "Dockerfile:L320-L326@sha256:9280f921e1a7 Dockerfile:L414-L414@sha256:9280f921e1a7")
  (:name "deps-verify (pure Lisp, πριν εμπιστευθεί vendored lib)"
   :what-it-can-decide "Αν οι 58 vendored εξαρτήσεις ταιριάζουν με deps.lock."
   :who-can-invoke "docker build stage 1"
   :enforcement :code
   :evidence "Dockerfile:L29-L48@sha256:9280f921e1a7 deps.lock:L1-L7@sha256:c4b43d610f97")
  (:name "assess-gate-plenary.sh + assess-gate-manifest.lisp"
   :what-it-can-decide "Αν η ολομέλεια είναι πράσινη· απαιτεί ΘΕΤΙΚΗ απόδειξη ολοκλήρωσης + set-equality με gate-registry.sexp."
   :who-can-invoke "CI job build-and-test"
   :enforcement :code
   :evidence ".github/workflows/docker-orchestrator.yml:L292-L308@sha256:f1a4bb69e6e4")
  (:name "verify-proof-manifest.py (totality + suite census)"
   :what-it-can-decide "Αν χτίζεται το runtime: κάθε tests/*-test.lisp πλην δηλωμένων εξαιρέσεων έχει parseable failed=0."
   :who-can-invoke "docker build --target verifier-conformance"
   :enforcement :code
   :evidence "Dockerfile:L312-L316@sha256:9280f921e1a7")
  (:name "Ο δημιουργός (Stavropoulos Law) — έγκριση φάσεων/merge"
   :what-it-can-decide "Τα πάντα· καμία φάση δεν ανοίγει μόνη της."
   :who-can-invoke "μόνο ο δημιουργός"
   :enforcement :convention
   :evidence "CLAUDE.md:L1-L40@sha256:b9d6ce92e217")
  (:name "tag-release (αυτόματο git tag σε main)"
   :what-it-can-decide "Δημιουργεί και σπρώχνει tag v1.3.<run_number> χωρίς ανθρώπινη έγκριση."
   :who-can-invoke "CI, αυτόματα σε κάθε πράσινο push στο main"
   :enforcement :code
   :evidence ".github/workflows/docker-orchestrator.yml:L359-L378@sha256:f1a4bb69e6e4"))

 ;; ══════════════════════════════════════════════════════════════════════
 :invariants
 ((:statement "The only subprocess is the Lisp runtime itself"
   :enforced-by :none :mechanism :text-only :evidence "README.md:L20-L21@sha256:97c747e9aa82")
  (:statement "Zero shell-script orchestration in the trusted path"
   :enforced-by :none :mechanism :text-only :evidence "README.md:L19-L19@sha256:97c747e9aa82")
  (:statement "Zero Python dependencies"
   :enforced-by :none :mechanism :text-only :evidence "README.md:L18-L18@sha256:97c747e9aa82")
  (:statement "100% Common Lisp / Pure Lisp 100%"
   :enforced-by :none :mechanism :text-only :evidence "README.md:L8-L8@sha256:97c747e9aa82 README.md:L16-L16@sha256:97c747e9aa82 README.md:L389-L389@sha256:97c747e9aa82")
  (:statement "Multi-stage hermetic build"
   :enforced-by :none :mechanism :text-only :evidence "Dockerfile:L5-L5@sha256:9280f921e1a7")
  (:statement "hermetic: enabled: true / no_network: true (machine-readable)"
   :enforced-by :none :mechanism :text-only :evidence "PROVENANCE.yaml:L292-L295@sha256:bce8df3c6d34")
  (:statement "Criterion 2: Hermetic build without network — docker build --network=none ."
   :enforced-by :none :mechanism :text-only :evidence "DEPENDENCY-CONTRACT.md:L168-L173@sha256:65a3f5df825c")
  (:statement "NO Quicklisp"
   :enforced-by :convention :mechanism :guard
   :note "Ο δηλωμένος φρουρός (grep σε source/ systems/) ΕΠΙΣΤΡΕΦΕΙ ΗΔΗ ΕΥΡΗΜΑΤΑ και ΤΑΥΤΟΧΡΟΝΑ αστοχεί να καλύψει το Dockerfile.test."
   :evidence "DEPENDENCY-CONTRACT.md:L183-L188@sha256:65a3f5df825c Dockerfile:L108-L108@sha256:9280f921e1a7 build.lisp:L11-L11@sha256:baa3527f5cf6")
  (:statement "Base image pinned by digest (not tag)"
   :enforced-by :code :mechanism :structural :evidence "Dockerfile:L23-L23@sha256:9280f921e1a7 Dockerfile:L29-L29@sha256:9280f921e1a7 Dockerfile:L53-L53@sha256:9280f921e1a7 Dockerfile:L333-L333@sha256:9280f921e1a7")
  (:statement "Reproducible builds via SOURCE_DATE_EPOCH"
   :enforced-by :code :mechanism :guard :evidence "Dockerfile:L17-L17@sha256:9280f921e1a7 Dockerfile:L64-L64@sha256:9280f921e1a7 Dockerfile:L206-L206@sha256:9280f921e1a7")
  (:statement "Το runtime ΔΕΝ κατασκευάζεται χωρίς να έχουν περάσει standalone-test + verifier-conformance"
   :enforced-by :code :mechanism :structural :evidence "Dockerfile:L391-L397@sha256:9280f921e1a7")
  (:statement "Ο producer ΔΕΝ βλέπει ποτέ ιδιωτικό κλειδί"
   :enforced-by :os :mechanism :structural :evidence "docker-compose.yml:L59-L61@sha256:ff93c313b8fe docker-compose.yml:L310-L310@sha256:ff93c313b8fe docker-compose.yml:L355-L357@sha256:ff93c313b8fe")
  (:statement "deps.lock: every dir under third-party/ is pinned (bijective). No network."
   :enforced-by :code :mechanism :structural
   :note "Το «bijective» ΕΠΑΛΗΘΕΥΤΗΚΕ 58↔58· το «No network» ΔΕΝ ισχύει για το build συνολικά."
   :evidence "deps.lock:L7-L7@sha256:c4b43d610f97"))

 ;; ══════════════════════════════════════════════════════════════════════
 :defects
 (;; ── Η ΕΙΔΙΚΗ ΕΝΤΟΛΗ ──
  (:what "GATE-4 «Pipeline integrity (no subprocess)» δηλώνεται στον πίνακα πυλών του README αλλά ΔΕΝ ΥΠΑΡΧΕΙ ως κώδικας πουθενά. Εξαντλητική σάρωση *.lisp/*.md/*.asd/*.yml/*.yaml: μοναδική εμφάνιση με αυτή τη σημασία = README.md:L304-L304@sha256:97c747e9aa82. Οι 25 πραγματικές εντολές -gate δεν περιλαμβάνουν καμία πύλη subprocess/purity, και το source/pdf-authority.lisp ΔΕΝ ΣΑΡΩΝΕΤΑΙ από τίποτα. Μηδέν αναφορές «GATE-4» σε ολόκληρο το deployment/collab/dialogue/ και docs/ ⇒ το κενό δεν είναι καταγεγραμμένο."
   :severity :p1
   :evidence "README.md:L304-L304@sha256:97c747e9aa82 source/pdf-authority.lisp:L1386-L1425@sha256:c4e2054c0e4f README.md:L185-L187@sha256:97c747e9aa82"
   :is-it-in-the-known-defect-list :no)
  (:what "README.md:L253-L253@sha256:97c747e9aa82 δηλώνει source/gate-guards.lisp («CI/CD guards (Pure Lisp)») στο δέντρο αρχιτεκτονικής· το αρχείο ΔΕΝ ΥΠΑΡΧΕΙ στο source/."
   :severity :p1
   :evidence "README.md:L253-L253@sha256:97c747e9aa82"
   :is-it-in-the-known-defect-list :yes)
  (:what "source/pdf-authority.lisp:L28-L28@sha256:c4e2054c0e4f δηλώνει «DARPA-GRADE: No Python, no subprocess, direct C library access» ενώ το ΙΔΙΟ αρχείο εκκινεί 5 subprocess (which pdftoppm, which tesseract, tesseract --list-langs, pdftoppm, tesseract) στις γραμμές 1386-1425. Η κεφαλίδα διαψεύδεται από το σώμα του ίδιου αρχείου."
   :severity :p1
   :evidence "source/pdf-authority.lisp:L28-L28@sha256:c4e2054c0e4f source/pdf-authority.lisp:L1386-L1425@sha256:c4e2054c0e4f"
   :is-it-in-the-known-defect-list :yes)

  ;; ── ΔΗΛΩΣΕΙΣ ΧΩΡΙΣ ΜΗΧΑΝΙΣΜΟ ──
  (:what "«100% Common Lisp» / «Pure Lisp 100%»: το repo περιέχει 59 μη-Lisp αρχεία πηγής εκτός third-party/ και output/ — 22 .py, 27 .sh, 6 .js, 2 .mjs, 2 .ts. Η ΤΕΛΙΚΗ ΚΡΙΣΗ της ολομέλειας πυλών αποδίδεται από bash (deployment/verify/assess-gate-plenary.sh) και το build-gate του proof manifest από Python."
   :severity :p1
   :evidence "README.md:L8-L8@sha256:97c747e9aa82 README.md:L16-L16@sha256:97c747e9aa82 README.md:L389-L389@sha256:97c747e9aa82 .github/workflows/docker-orchestrator.yml:L298-L299@sha256:f1a4bb69e6e4 Dockerfile:L316-L316@sha256:9280f921e1a7"
   :is-it-in-the-known-defect-list :no)
  (:what "«Multi-stage hermetic build» (Dockerfile:L5-L5@sha256:9280f921e1a7) + machine-readable «hermetic: enabled: true, no_network: true» (PROVENANCE.yaml:L292-L295@sha256:bce8df3c6d34) + «Criterion 2 ✅ docker build --network=none» (DEPENDENCY-CONTRACT.md:L168-L173@sha256:65a3f5df825c): και τα τρία διαψεύδονται από 3× apt-get update && apt-get install χωρίς καθήλωση εκδόσεων. Με --network=none το stage 1 αποτυγχάνει αμέσως."
   :severity :p1
   :evidence "Dockerfile:L5-L5@sha256:9280f921e1a7 Dockerfile:L41-L43@sha256:9280f921e1a7 Dockerfile:L68-L77@sha256:9280f921e1a7 Dockerfile:L363-L377@sha256:9280f921e1a7 PROVENANCE.yaml:L292-L295@sha256:bce8df3c6d34 DEPENDENCY-CONTRACT.md:L168-L173@sha256:65a3f5df825c"
   :is-it-in-the-known-defect-list :no)
  (:what "SEMANTIC-CONTRACT.md §1.2/§1.3 δηλώνουν «GUARANTEE» για blockchain-anchored timestamp και ανιχνευσιμότητα αλλοίωσης, ενώ source/blockchain-authority.lisp:L927-L942@sha256:caadc9c75a98 κάνει (declare (ignore response)) και επιστρέφει (= status 200) — δεν ελέγχει ΠΟΤΕ ότι τα bytes hash-άρουν στην αξιωμένη τιμή. Το ίδιο το repo το ονομάζει «verification theatre» σε ΑΛΛΟ έγγραφο."
   :severity :p1
   :evidence "SEMANTIC-CONTRACT.md:L36-L56@sha256:260308c8e7ee source/blockchain-authority.lisp:L927-L942@sha256:caadc9c75a98 docs/SECURITY-REDTEAM.md:L54-L66@sha256:489f6a4c7a31"
   :is-it-in-the-known-defect-list :yes)
  (:what "SEMANTIC-CONTRACT.md:L22-L24@sha256:260308c8e7ee δηλώνει ΕΓΓΥΗΣΗ «All releases, commits, and tags are signed with GPG», αλλά το provenance.yml παρακάμπτει σιωπηλά την υπογραφή όταν λείπει το secret (if: secrets.GPG_PRIVATE_KEY == '') με απλό echo warning — η εγγύηση υποβαθμίζεται σε προαιρετική χωρίς κόκκινο."
   :severity :p1
   :evidence "SEMANTIC-CONTRACT.md:L22-L24@sha256:260308c8e7ee .github/workflows/provenance.yml:L128-L128@sha256:9eec887461e4 .github/workflows/provenance.yml:L143-L151@sha256:9eec887461e4"
   :is-it-in-the-known-defect-list :no)

  ;; ── ΕΝΤΟΛΕΣ ΕΠΑΛΗΘΕΥΣΗΣ ΠΟΥ ΔΕΝ ΕΚΤΕΛΟΥΝΤΑΙ ──
  (:what "ΤΕΣΣΕΡΑ δηλωμένα scripts επαλήθευσης ΔΕΝ ΥΠΑΡΧΟΥΝ: PROVENANCE.yaml:L286-L286@sha256:bce8df3c6d34 «scripts/verify-deps.sh», PROVENANCE.yaml:L289-L289@sha256:bce8df3c6d34 «scripts/generate-deps-lock.sh», DEPENDENCY-CONTRACT.md:L194-L194@sha256:65a3f5df825c DEPENDENCY-CONTRACT.md:L213-L213@sha256:65a3f5df825c «docker/verify-deps.sh», SEMANTIC-CONTRACT.md:L61-L61@sha256:260308c8e7ee «./scripts/verify-deterministic-build.sh». Τα πραγματικά είναι docker/verify-deps.lisp και scripts/gen-deps-lock.lisp — δηλαδή ΤΡΙΑ διαφορετικά ονόματα για την ΙΔΙΑ έδρα σε τρία συμβόλαια."
   :severity :p1
   :evidence "PROVENANCE.yaml:L286-L286@sha256:bce8df3c6d34 PROVENANCE.yaml:L289-L289@sha256:bce8df3c6d34 DEPENDENCY-CONTRACT.md:L194-L194@sha256:65a3f5df825c SEMANTIC-CONTRACT.md:L61-L61@sha256:260308c8e7ee deps.lock:L5-L6@sha256:c4b43d610f97"
   :is-it-in-the-known-defect-list :no)
  (:what "SEMANTIC-CONTRACT.md:L60-L60@sha256:260308c8e7ee διδάσκει «sha256sum -c deps.lock» — δομικά αδύνατο: το deps.lock είναι «<dir> | <sha256>» (deps.lock:L2-L2@sha256:c4b43d610f97), όχι η μορφή «<hash>  <path>» που δέχεται το sha256sum -c."
   :severity :p2
   :evidence "SEMANTIC-CONTRACT.md:L60-L60@sha256:260308c8e7ee deps.lock:L2-L2@sha256:c4b43d610f97"
   :is-it-in-the-known-defect-list :no)
  (:what "DEPENDENCY-CONTRACT.md:L183-L188@sha256:65a3f5df825c «Criterion 4: No Quicklisp runtime calls ✅» με grep σε source/ systems/: (α) εκτελούμενο ΣΗΜΕΡΑ ΕΠΙΣΤΡΕΦΕΙ ΕΥΡΗΜΑΤΑ (systems/orchestrator-omega-modules/omega-package.lisp:L46-L46@sha256:6e4e14e66418 + README.md:L116-L211@sha256:97c747e9aa82) ⇒ το κριτήριο που δηλώνεται ✅ αποτυγχάνει· (β) το πεδίο του grep αποκλείει ΑΚΡΙΒΩΣ τον χώρο της πραγματικής παράβασης (Dockerfile.test:L29-L29@sha256:af607b4c7c5e, MANUAL-STEPS-HERMETIC.md:L59-L59@sha256:cfd4fd227483). Φρουρός γύρω από λάθος σχήμα."
   :severity :p1
   :evidence "DEPENDENCY-CONTRACT.md:L183-L188@sha256:65a3f5df825c systems/orchestrator-omega-modules/omega-package.lisp:L46-L46@sha256:6e4e14e66418 Dockerfile.test:L29-L29@sha256:af607b4c7c5e"
   :is-it-in-the-known-defect-list :no)

  ;; ── ΠΑΡΑΔΟΣΗ / DOCKER ──
  (:what "docker-compose.yml:L17-L17@sha256:ff93c313b8fe — αδέσποτο εισαγωγικό στο tmpfs option της ΚΥΡΙΑΣ υπηρεσίας: «- /tmp:size=256m,mode=1777\"». Οι άλλες τέσσερις tmpfs γραμμές (133, 210, 299, 348) δεν το έχουν. Είναι η υπηρεσία που τρέχει το τεκμηριωμένο «docker compose up»."
   :severity :p1
   :evidence "docker-compose.yml:L17-L17@sha256:ff93c313b8fe docker-compose.yml:L133-L133@sha256:ff93c313b8fe docker-compose.yml:L210-L210@sha256:ff93c313b8fe"
   :is-it-in-the-known-defect-list :no)
  (:what "Το τεκμηριωμένο quickstart «docker compose build && docker compose up» (README:64-65) δεν μπορεί να πετύχει: το compose περνά GIT_COMMIT default «dev» ενώ ο Dockerfile απαιτεί ακριβώς 40-hex αλλιώς FATAL exit 1 — και το target runtime περνά υποχρεωτικά από εκείνο το στάδιο."
   :severity :p1
   :evidence "docker-compose.yml:L8-L8@sha256:ff93c313b8fe Dockerfile:L172-L173@sha256:9280f921e1a7 README.md:L64-L65@sha256:97c747e9aa82"
   :is-it-in-the-known-defect-list :no)
  (:what "authority-v2-proofs: privileged:true + ΟΛΟΚΛΗΡΟ το repo ως «.:/repo:rw» + bash + apt-get install sbcl python3 util-linux + image debian:bookworm-slim με UNPINNED tag (ενώ ο Dockerfile καρφώνει digest). Είναι η υπηρεσία που παράγει τις αποδείξεις ορίου πυρήνα."
   :severity :p1
   :evidence "docker-compose.yml:L376-L397@sha256:ff93c313b8fe Dockerfile:L23-L23@sha256:9280f921e1a7"
   :is-it-in-the-known-defect-list :no)
  (:what "Dockerfile.test κατεβάζει Quicklisp από το δίκτυο (curl https://beta.quicklisp.org/quicklisp.lisp) και κάνει ql:quickload :fiveam ως root, ενώ Dockerfile:L108-L108@sha256:9280f921e1a7, build.lisp:L11-L11@sha256:baa3527f5cf6 και DEPENDENCY-CONTRACT.md:L207-L207@sha256:65a3f5df825c δηλώνουν ρητά «NO Quicklisp». Κανένα build/CI/compose αρχείο δεν το αναφέρει."
   :severity :p1
   :evidence "Dockerfile.test:L9-L30@sha256:af607b4c7c5e Dockerfile:L108-L108@sha256:9280f921e1a7 build.lisp:L11-L11@sha256:baa3527f5cf6 DEPENDENCY-CONTRACT.md:L207-L207@sha256:65a3f5df825c"
   :is-it-in-the-known-defect-list :yes)
  (:what ".github/workflows/docker-orchestrator.yml:L228-L234@sha256:f1a4bb69e6e4 — «curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh»: εκτέλεση απομακρυσμένου, μη καθηλωμένου κώδικα από το internet μέσα στο CI που παράγει το SBOM εφοδιαστικής αλυσίδας."
   :severity :p1
   :evidence ".github/workflows/docker-orchestrator.yml:L228-L234@sha256:f1a4bb69e6e4"
   :is-it-in-the-known-defect-list :no)
  (:what "CI βήμα «Smoke test orchestrator loading» κάνει asdf:load-asd \"/app/orchestrator.asd\" στο orchestrator:test, αλλά το runtime stage δεν αντιγράφει ΚΑΝΕΝΑ .asd (μηδέν αναφορές asd στις γραμμές 333-453) ΚΑΙ το βήμα δεν κάνει --entrypoint override — σε αντίθεση με τη γραμμή 306 που το κάνει ρητά για τον ίδιο σκοπό."
   :severity :p1
   :evidence ".github/workflows/docker-orchestrator.yml:L338-L346@sha256:f1a4bb69e6e4 Dockerfile:L394-L410@sha256:9280f921e1a7 .github/workflows/docker-orchestrator.yml:L306-L306@sha256:f1a4bb69e6e4"
   :is-it-in-the-known-defect-list :no)
  (:what "package.json δηλώνει playwright ^1.61.0 (headless Chromium) σε repo που δηλώνει «100% Common Lisp». Η αλυσίδα είναι ΖΩΝΤΑΝΗ και ρυθμισμένη: configs/constitution.yaml:L90-L90@sha256:c2daf8934d68 fetch_cmd «bash deployment/fetch-fek-by-number.sh Α 111 1975 {{out}}» → run-fetch-command /bin/sh -c → deployment/fetch-fek.sh:L16-L16@sha256:42acffc89892 deployment/fetch-fek.sh:L67-L67@sha256:42acffc89892 → node + Playwright. (Το .dockerignore:L77-L77@sha256:d6f658bdd2a1 αποκλείει το package.json από την εικόνα, όχι το configs/.)"
   :severity :p1
   :evidence "package.json:L1-L5@sha256:8c4d176620ed configs/constitution.yaml:L90-L90@sha256:c2daf8934d68 source/document-fetch.lisp:L92-L106@sha256:bb114b83fd80 deployment/fetch-fek.sh:L16-L23@sha256:42acffc89892 .dockerignore:L77-L77@sha256:d6f658bdd2a1"
   :is-it-in-the-known-defect-list :no)
  (:what "source.fetch_cmd → sh -c είναι RCE-by-design για όποιον μπορεί να επεξεργαστεί ένα corpus YAML· το {{out}} templating είναι αχειραγώγητο/μη-quoted. Το configs/ αντιγράφεται ΜΕΣΑ στο runtime image."
   :severity :p1
   :evidence "docs/SECURITY-REDTEAM.md:L84-L88@sha256:489f6a4c7a31 configs/constitution.yaml:L90-L90@sha256:c2daf8934d68 Dockerfile:L400-L400@sha256:9280f921e1a7"
   :is-it-in-the-known-defect-list :yes)

  ;; ── .asd / ΕΔΡΕΣ ──
  (:what "orchestrator-tooling.asd: ΠΛΗΡΩΣ ΟΡΦΑΝΟ — μηδέν αναφορές σε ολόκληρο το repo, :components () κενό."
   :severity :p2
   :evidence "orchestrator-tooling.asd:L5-L20@sha256:e8d7e64f5a71"
   :is-it-in-the-known-defect-list :no)
  (:what "5 .asd δηλώνουν test-op (orchestrator, orchestrator-core-runtime, orchestrator-omega, orchestrator-tests, orchestrator-tests-runtime) αλλά ΚΑΝΕΝΑ Dockerfile / .github/workflows / docker-compose δεν καλεί ποτέ asdf test-op — νεκρές δηλώσεις. Η πραγματική εκτέλεση γίνεται μέσω docker/run-standalone-suites.sh."
   :severity :p2
   :evidence "orchestrator-core-runtime.asd:L31-L31@sha256:dba3a133277b orchestrator.asd:L41-L41@sha256:21f72d016312 orchestrator-tests-runtime.asd:L24-L24@sha256:4d44073cbf6f orchestrator-omega.asd:L139-L139@sha256:6c6f2d597908 Dockerfile:L189-L192@sha256:9280f921e1a7"
   :is-it-in-the-known-defect-list :no)
  (:what "3 .asd έχουν κενό :components () — core-runtime, tests-runtime, tooling: είναι καθαροί συναθροιστές μέσω :depends-on, χωρίς δικά τους αρχεία."
   :severity :p2
   :evidence "orchestrator-core-runtime.asd:L29-L29@sha256:dba3a133277b orchestrator-tests-runtime.asd:L22-L22@sha256:4d44073cbf6f orchestrator-tooling.asd:L20-L20@sha256:e8d7e64f5a71"
   :is-it-in-the-known-defect-list :no)
  (:what "orchestrator-epistemic ΔΕΝ φορτώνεται από το build.lisp (φορτώνει ΜΟΝΟ :orchestrator-core-runtime), ενώ README:230 διδάσκει (orchestrator.engine:run-epistemic-pipeline) ως τρόπο εκτέλεσης του αγωγού."
   :severity :p2
   :evidence "build.lisp:L34-L34@sha256:baa3527f5cf6 README.md:L227-L230@sha256:97c747e9aa82"
   :is-it-in-the-known-defect-list :no)

  ;; ── ΠΑΛΙΩΜΕΝΑ ΣΥΜΒΟΛΑΙΑ ──
  (:what "ARG SBCL_VERSION=2.4.0 δηλώνεται ΔΥΟ φορές (16, 56) και ΔΕΝ χρησιμοποιείται πουθενά· η SBCL εγκαθίσταται unpinned μέσω apt σε 3 στάδια. Η δηλωμένη έκδοση είναι διακοσμητική. Από τα 6 δηλωμένα ARG, 5 χρησιμοποιούνται (SOURCE_DATE_EPOCH, DEBIAN_DIGEST, GIT_COMMIT, BUILD_DATE, VERSION) και 1 όχι."
   :severity :p2
   :evidence "Dockerfile:L16-L16@sha256:9280f921e1a7 Dockerfile:L56-L56@sha256:9280f921e1a7 Dockerfile:L41-L43@sha256:9280f921e1a7 Dockerfile:L68-L69@sha256:9280f921e1a7 Dockerfile:L374-L374@sha256:9280f921e1a7"
   :is-it-in-the-known-defect-list :no)
  (:what "MANUAL-STEPS-HERMETIC.md:L29-L29@sha256:cfd4fd227483 δηλώνει «deps.lock με 48 total dependencies» ενώ το πραγματικό deps.lock έχει 58. Το ίδιο έγγραφο (γραμμή 5) παραδέχεται «~95% hermetic» — που αντιφάσκει με το απόλυτο «hermetic» του Dockerfile:L5-L5@sha256:9280f921e1a7 και του PROVENANCE.yaml:L293-L293@sha256:bce8df3c6d34. Επίσης διπλή εγγραφή trivial-macroexpand-all (21, 22)."
   :severity :p2
   :evidence "MANUAL-STEPS-HERMETIC.md:L5-L5@sha256:cfd4fd227483 MANUAL-STEPS-HERMETIC.md:L21-L22@sha256:cfd4fd227483 MANUAL-STEPS-HERMETIC.md:L29-L29@sha256:cfd4fd227483 deps.lock"
   :is-it-in-the-known-defect-list :no)
  (:what "Απόκλιση έκδοσης: SYSTEM-HIERARCHY.txt:L2-L2@sha256:d5665164bce2 «ORCHESTRATOR v1.3»· README.md:L6-L6@sha256:97c747e9aa82 README.md:L389-L389@sha256:97c747e9aa82 + Dockerfile:L338-L338@sha256:9280f921e1a7 + orchestrator.asd:L13-L13@sha256:21f72d016312 + CHANGELOG.md:L3-L3@sha256:3d1f519e64dd «1.2.0»· CI παράγει tags «v1.3.<run_number>»."
   :severity :p2
   :evidence "SYSTEM-HIERARCHY.txt:L2-L2@sha256:d5665164bce2 README.md:L389-L389@sha256:97c747e9aa82 Dockerfile:L338-L338@sha256:9280f921e1a7 .github/workflows/docker-orchestrator.yml:L371-L371@sha256:f1a4bb69e6e4"
   :is-it-in-the-known-defect-list :no)
  (:what "SYSTEM-HIERARCHY.txt:L5-L8@sha256:d5665164bce2 δηλώνει «ΚΟΡΥΦΑΙΟ ΣΗΜΕΙΟ ΕΙΣΟΔΟΥ (ONE ENTRY POINT): unified-frbr-generator.lisp» — τρίτη, ασύμβατη δήλωση «μοναδικής εισόδου» δίπλα στο entrypoint.lisp και το orchestrator.cli:main."
   :severity :p2
   :evidence "SYSTEM-HIERARCHY.txt:L5-L8@sha256:d5665164bce2 Dockerfile:L452-L452@sha256:9280f921e1a7 build.lisp:L44-L44@sha256:baa3527f5cf6"
   :is-it-in-the-known-defect-list :no)
  (:what "deps.archives.lock είναι ΚΕΝΟ — περιέχει μόνο τη γραμμή σχολίου «# name sha256(zip)» (20 bytes)."
   :severity :p2
   :evidence "deps.archives.lock:L1-L1@sha256:af1f9d2642ca"
   :is-it-in-the-known-defect-list :no)
  (:what ".env.example δηλώνει POSTGRES_/GRAFANA_/SLACK_WEBHOOK/TELEMETRY_ENDPOINT ενώ το docker-compose.yml δεν έχει καμία τέτοια υπηρεσία (postgres/redis είναι σχολιασμένα στις 409-411)."
   :severity :p2
   :evidence ".env.example:L22-L29@sha256:645f4518c145 docker-compose.yml:L409-L411@sha256:ff93c313b8fe"
   :is-it-in-the-known-defect-list :no)
  (:what "tools/independent-audit.py: το ΜΟΝΟ αρχείο του tools/ είναι Python που απαιτεί «pip install pymupdf» — μη κλειδωμένο σε deps.lock, μη εκτελούμενο από CI. Τα ευρήματα ορθότητας 4.691 άρθρων (docs/AUDIT-8-QUIRKS.md:L3-L3@sha256:a11ee92c0e39) στηρίζονται σε αυτό."
   :severity :p2
   :evidence "tools/independent-audit.py:L1-L20@sha256:69a9dc8dc288 docs/AUDIT-8-QUIRKS.md:L3-L3@sha256:a11ee92c0e39"
   :is-it-in-the-known-defect-list :no)
  (:what "Τα 3 NOT-CI-gated compose test αρχεία χρησιμοποιούν «version: '3.8'» (καταργημένο κλειδί) και target: builder με «.:/workspace:ro» — τρέχουν εκτός της αποδεικτικής αλυσίδας· το README:174-181 τα καταγράφει ρητά ως follow-up χρέος."
   :severity :p2
   :evidence "docker-compose.architecture-tests.yml:L1-L16@sha256:08805212b09e README.md:L174-L181@sha256:97c747e9aa82"
   :is-it-in-the-known-defect-list :yes))

 ;; ══════════════════════════════════════════════════════════════════════
 :hidden-execution-paths
 ((:path "/bin/sh -c <command> (run-fetch-command) → bash deployment/fetch-fek*.sh → node deployment/fetch-fek.js → headless Chromium (Playwright)"
   :trigger "source.fetch_cmd από corpus YAML· ρυθμισμένο ΖΩΝΤΑΝΑ στο configs/constitution.yaml:L90-L90@sha256:c2daf8934d68"
   :why-hidden "README:19-21 δηλώνει μηδέν shell και μοναδικό subprocess τον Lisp runtime. Το configs/ αντιγράφεται στο runtime image."
   :evidence "source/document-fetch.lisp:L92-L106@sha256:bb114b83fd80 configs/constitution.yaml:L90-L90@sha256:c2daf8934d68 deployment/fetch-fek.sh:L16-L23@sha256:42acffc89892 Dockerfile:L400-L400@sha256:9280f921e1a7")
  (:path "pdftoppm -r 300 -png → tesseract -l ell → which/--list-langs"
   :trigger "extract-text-any σε σαρωμένο PDF (text layer < 600 chars)"
   :why-hidden "Καμία πύλη δεν το σαρώνει (η δηλωμένη GATE-4 δεν υπάρχει)· τα binaries εγκαθίστανται ρητά στο runtime image."
   :evidence "source/pdf-authority.lisp:L1399-L1425@sha256:c4e2054c0e4f Dockerfile:L371-L373@sha256:9280f921e1a7")
  (:path "bash /app/scripts/merkle-mutation-witness.sh + /app/docker/run-standalone-suites.sh"
   :trigger "docker build --target standalone-test / verifier-conformance"
   :why-hidden "Bash μέσα στην ΥΠΟΧΡΕΩΤΙΚΗ αποδεικτική αλυσίδα που παράγει το runtime."
   :evidence "Dockerfile:L167-L167@sha256:9280f921e1a7 Dockerfile:L189-L192@sha256:9280f921e1a7 Dockerfile:L290-L290@sha256:9280f921e1a7")
  (:path "python3 verify-canonical.py / verify-merkle.py / verify-proof-manifest.py + node verify-merkle.mjs"
   :trigger "docker build --target verifier-conformance (υποχρεωτικός πρόγονος του runtime)"
   :why-hidden "README:18 «Zero Python dependencies»· εδώ η Python είναι ΠΥΛΗ που μπλοκάρει την παραγωγή του runtime."
   :evidence "Dockerfile:L259-L259@sha256:9280f921e1a7 Dockerfile:L284-L285@sha256:9280f921e1a7 Dockerfile:L316-L316@sha256:9280f921e1a7")
  (:path "curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh"
   :trigger "CI job build-and-test, βήμα Generate SBOM"
   :why-hidden "Απομακρυσμένη, μη καθηλωμένη εκτέλεση κώδικα μέσα σε workflow εφοδιαστικής αλυσίδας."
   :evidence ".github/workflows/docker-orchestrator.yml:L228-L234@sha256:f1a4bb69e6e4")
  (:path "docker/entrypoint.lisp run-subprocess (sb-ext:run-program :wait t)"
   :trigger "κάθε εκκίνηση container"
   :why-hidden "fork+wait, ΟΧΙ exec — ο Lisp wrapper παραμένει ζωντανός γονέας, άρα δύο διεργασίες, ενώ το README λέει «execs»."
   :evidence "docker/entrypoint.lisp:L67-L77@sha256:b4f283f2abed Dockerfile:L452-L452@sha256:9280f921e1a7")
  (:path "authority-v2-proofs: privileged container, repo rw, apt-get install, bash run-proofs.sh"
   :trigger "docker compose --profile proofs up"
   :why-hidden "Μοναδικό σημείο με privileged:true και εγγράψιμη πρόσβαση σε ΟΛΟ το repo."
   :evidence "docker-compose.yml:L376-L397@sha256:ff93c313b8fe")
  (:path "tag-release: αυτόματο git tag + push σε κάθε πράσινο main"
   :trigger "push στο main με πράσινα build-and-test + authority-v2-boundary"
   :why-hidden "Το CLAUDE.md:«Μόνο ο δημιουργός συγχωνεύει/εγκρίνει φάσεις» — εδώ το CI εκδίδει ταυτότητα έκδοσης χωρίς ανθρώπινη πράξη."
   :evidence ".github/workflows/docker-orchestrator.yml:L359-L378@sha256:f1a4bb69e6e4"))

 ;; ══════════════════════════════════════════════════════════════════════
 :duplicate-seats
 ((:concept "container entrypoint"
   :seats ("entrypoint.lisp:L1-L83@sha256:779402eaf674 — ΟΡΦΑΝΟ: φορτώνει :orchestrator + :orchestrator-tests και ΤΡΕΧΕΙ ΤΗ ΣΟΥΙΤΑ ΤΕΣΤ· αντιγράφεται στον builder (Dockerfile:L104-L104@sha256:9280f921e1a7) αλλά ΔΕΝ εκτελείται ποτέ"
           "docker/entrypoint.lisp:L1-L182@sha256:b4f283f2abed — ΤΟ ΠΡΑΓΜΑΤΙΚΟ (Dockerfile:L409-L409@sha256:9280f921e1a7 → /app/entrypoint.lisp, Dockerfile:L452-L452@sha256:9280f921e1a7)"))
  (:concept "aggregate system definition (ίδια 10 υποσυστήματα)"
   :seats ("orchestrator.asd:L19-L28@sha256:21f72d016312" "orchestrator-core-runtime.asd:L17-L26@sha256:dba3a133277b"))
  (:concept "ποιο σύστημα φορτώνεται για να τρέξει ο αγωγός"
   :seats ("build.lisp:L34-L34@sha256:baa3527f5cf6 → :orchestrator-core-runtime" "entrypoint.lisp:L16-L16@sha256:779402eaf674 → :orchestrator" "README.md:L227-L227@sha256:97c747e9aa82 → :orchestrator-omega"))
  (:concept "όνομα του verifier εξαρτήσεων"
   :seats ("PROVENANCE.yaml:L286-L286@sha256:bce8df3c6d34 scripts/verify-deps.sh (ΑΝΥΠΑΡΚΤΟ)"
           "DEPENDENCY-CONTRACT.md:L194-L194@sha256:65a3f5df825c DEPENDENCY-CONTRACT.md:L213-L213@sha256:65a3f5df825c docker/verify-deps.sh (ΑΝΥΠΑΡΚΤΟ)"
           "deps.lock:L6-L6@sha256:c4b43d610f97 + Dockerfile:L48-L48@sha256:9280f921e1a7 docker/verify-deps.lisp (ΠΡΑΓΜΑΤΙΚΟ)"))
  (:concept "verify-proof-manifest (δύο ΔΙΑΦΟΡΕΤΙΚΑ αρχεία, διαφορετικά sha256)"
   :seats ("docker/verify-proof-manifest.py (295 γραμμές, gate του build)"
           "authority-v2/proofs/verify-proof-manifest.py (95 γραμμές)"))
  (:concept "edge content negotiation για το ίδιο site"
   :seats ("cloudflare/src/worker.ts (standalone Worker)"
           "cloudflare/functions/_middleware.ts (Pages Function — «recommended»)"))
  (:concept "health file path"
   :seats ("Dockerfile:L445-L447@sha256:9280f921e1a7 /run/lawmax/.healthy (HEALTHCHECK)"
           "docker/entrypoint.lisp:L162-L164@sha256:b4f283f2abed σχόλιο που ακόμη λέει /app/output/.healthy"))
  (:concept "δήλωση «ONE ENTRY POINT»"
   :seats ("SYSTEM-HIERARCHY.txt:L5-L8@sha256:d5665164bce2 unified-frbr-generator.lisp"
           "Dockerfile:L452-L452@sha256:9280f921e1a7 /app/entrypoint.lisp"
           "build.lisp:L44-L44@sha256:baa3527f5cf6 orchestrator.cli:main")))

 ;; ══════════════════════════════════════════════════════════════════════
 :unknowns
 ("Αν το docker build πετυχαίνει ΠΡΑΓΜΑΤΙΚΑ σήμερα — καμία εκτέλεση δεν επιτρεπόταν (στατική αρχαιολογία μόνο)."
  "Αν το CI βήμα «Smoke test orchestrator loading» έχει τρέξει ποτέ πράσινο· δεν βρέθηκε αποθηκευμένο log στο /frozen/ro."
  "Αν το GIT_COMMIT περνιέται σωστά σε ΚΑΘΕ τοπική διαδρομή του δημιουργού — μόνο το CI το δίνει ρητά (github.sha)."
  "Ακριβής αριθμός os-exec sites συνολικά: το deployment/collab/dialogue/0094-claude.md:L82-L82@sha256:3bbb04c93d56 δηλώνει 19· η δική μου σάρωση εντόπισε 6 uiop:run-program σε source/ + 1 sb-ext:run-program σε docker/entrypoint.lisp. Η διαφορά δεν συμφιλιώθηκε."
  "Αν τα 5 κενά fetch_cmd (astikos/kdioikitikis/kpoinikis/kpolitikis/poinikoskodikas) σημαίνουν απενεργοποιημένο μονοπάτι ή απλώς αρύθμιστο."
  "Περιεχόμενο 14 από τα 18 docs/ αρχείων διαβάστηκε μόνο σε επίπεδο δομής/επικεφαλίδων, όχι γραμμή-προς-γραμμή (AUDIT-8-QUIRKS, BRAIN, CURRENTNESS-34, ELI-IMPLEMENTATION-PHASES, IMPLEMENTATION-COMPLETE, ROADMAP-EUROPE, και τα 8 docs/history/)."
  "configs/huggingface-dataset.json και configs/prometheus-citation.yml: διαβάστηκαν μόνο ως δομή· δεν κρίθηκε αν οι δηλωμένοι scrape targets/datasets αντιστοιχούν σε κάτι ζωντανό."
  "Αν το «GATE-1/2/3/5» του README:300-305 έχουν υλοποίηση — ελέγχθηκε εξαντλητικά ΜΟΝΟ το GATE-4 κατά την ΕΙΔΙΚΗ ΕΝΤΟΛΗ."))
