(:lawmax-phase1a-cluster/1
 :cluster "ΤΑ ΣΥΜΒΟΛΑΙΑ ΚΑΙ Η ΠΑΡΑΔΟΣΗ"
 :status :partial
 :files-read 48
 :universe 79
 :capabilities
 ((:name "GATE-4 / pipeline-integrity-no-subprocess"
   :presence :absent
   :domain "Δηλωμένη πύλη CI που επιβάλλει «no subprocess» στον αγωγό."
   :assumptions "Ότι κάθε GATE-N του πίνακα README:300-305 αντιστοιχεί σε εκτελέσιμο guard."
   :guarantees "ΚΑΜΙΑ — δεν βρέθηκε υλοποίηση πουθενά στο repo."
   :failure-semantics "Δεν υπάρχει μηχανισμός να αποτύχει· η δήλωση δεν μπορεί να γίνει κόκκινη."
   :operating-model "Μόνο κείμενο πίνακα."
   :materiality "Η ΑΠΟΛΥΤΗ δήλωση README:20-21 δεν φρουρείται από τίποτα."
   :evidence "README.md:304")
  (:name "Πραγματικά subprocess seats"
   :presence :present
   :domain "Εκκίνηση εξωτερικών διεργασιών από τον κώδικα."
   :assumptions "uiop:run-program· εξωτερικά binaries στο PATH."
   :guarantees "Καμία απομόνωση· document-fetch περνά ΑΥΘΑΙΡΕΤΟ string σε /bin/sh -c."
   :failure-semantics "pdf-authority: σιωπηλό NIL· document-fetch: (values -1 msg), never throws."
   :operating-model "Runtime, εντός production image."
   :materiality "6 call sites σε 2 αρχεία· τα binaries (poppler-utils, tesseract-ocr) ΕΓΚΑΘΙΣΤΑΝΤΑΙ ΡΗΤΑ στο runtime image."
   :evidence "source/document-fetch.lisp:92-106 source/pdf-authority.lisp:1386-1425 Dockerfile:371-373")
  (:name "Python ως υποχρεωτική εξάρτηση build"
   :presence :present
   :domain "Κατασκευή του runtime image."
   :assumptions "apt-get δικτυακά διαθέσιμο· python3 + rdflib + nodejs εγκαθίστανται."
   :guarantees "Το runtime ΔΕΝ χτίζεται αν αποτύχει έστω ένα python3 gate."
   :failure-semantics "Fail-closed: build red."
   :operating-model "Stage verifier-conformance, υποχρεωτικός πρόγονος του runtime (COPY --from)."
   :materiality "README:18 «Zero Python dependencies» — ο runtime ΔΕΝ ΜΠΟΡΕΙ να παραχθεί χωρίς python3."
   :evidence "Dockerfile:241-245 Dockerfile:259 Dockerfile:284 Dockerfile:316 Dockerfile:394")
  (:name "Shell ως έδρα εκτέλεσης της gated σουίτας"
   :presence :present
   :domain "Εκτέλεση των tests/*-test.lisp."
   :assumptions "bash με pipefail."
   :guarantees "fail-closed (pipefail)."
   :failure-semantics "sbcl exit != 0 ⇒ build red."
   :operating-model "docker/run-standalone-suites.sh — η ΜΙΑ δηλωμένη έδρα εκτέλεσης."
   :materiality "README:19 «Zero shell-script orchestration in the trusted path»· η ΑΠΟΔΕΙΚΤΙΚΗ αλυσίδα τρέχει ΜΕΣΑ σε bash."
   :evidence "Dockerfile:167 Dockerfile:189-192 Dockerfile:290")
  (:name "Διαχωρισμός ρόλων παραγωγού/υπογράφοντα (compose)"
   :presence :present
   :domain "Απομόνωση ιδιωτικού κλειδιού από τον παραγωγό."
   :assumptions "Ο χρήστης τρέχει τα δηλωμένα profiles."
   :guarantees "producer(11002) βλέπει ΜΟΝΟ keys/public· authority-signer(11001) ΜΟΝΟ αυτός keys/private."
   :failure-semantics "read_only rootfs + cap_drop ALL + no-new-privileges σε 4 υπηρεσίες."
   :operating-model "Docker/OS-level, ξεχωριστά uid ανά ρόλο."
   :materiality "Δομικός μηχανισμός, όχι κείμενο."
   :evidence "docker-compose.yml:283-312 docker-compose.yml:330-363")
  (:name "authority-signer (admission kernel)"
   :presence :spec-only
   :domain "Υπογραφή release."
   :assumptions "—"
   :guarantees "ΚΑΜΙΑ — η υπηρεσία ΑΡΝΕΙΤΑΙ ρητά και βγαίνει exit 3."
   :failure-semantics "Πάντα exit 3 με ::error:: μήνυμα· ΔΕΝ προσποιείται."
   :operating-model "/bin/sh -c echo && exit 3."
   :materiality "ΤΙΜΙΑ ΑΓΝΟΙΑ δηλωμένη στην ίδια την έδρα (Level-7 απαίτηση 2/4 μη υλοποιημένη)."
   :evidence "docker-compose.yml:327-340"))
 :authorities
 ((:name "GIT_COMMIT 40-hex gate"
   :what-it-can-decide "Αν το build προχωρά· proof χωρίς δεσμευμένο HEAD δεν είναι proof."
   :who-can-invoke "docker build --build-arg GIT_COMMIT"
   :enforcement :code
   :evidence "Dockerfile:172-173")
  (:name "runtime-assets sha256 self-check"
   :what-it-can-decide "Αν το runtime image χτίζεται· κάθε asset ≡ manifest του verified stage."
   :who-can-invoke "docker build (αυτόματο)"
   :enforcement :code
   :evidence "Dockerfile:320-326 Dockerfile:414")
  (:name "deps-verify (pure-Lisp, πριν από κάθε vendored lib)"
   :what-it-can-decide "Αν οι vendored εξαρτήσεις ταιριάζουν με deps.lock."
   :who-can-invoke "docker build stage 1"
   :enforcement :code
   :evidence "Dockerfile:29-48"))
 :invariants
 ((:statement "The only subprocess is the Lisp runtime itself"
   :enforced-by :none
   :evidence "README.md:20-21")
  (:statement "Zero shell-script orchestration in the trusted path"
   :enforced-by :none
   :evidence "README.md:19")
  (:statement "Zero Python dependencies"
   :enforced-by :none
   :evidence "README.md:18")
  (:statement "Multi-stage hermetic build"
   :enforced-by :none
   :evidence "Dockerfile:5")
  (:statement "Reproducible builds via SOURCE_DATE_EPOCH"
   :enforced-by :code
   :evidence "Dockerfile:17 Dockerfile:64 Dockerfile:206")
  (:statement "Base image pinned by digest (not tag)"
   :enforced-by :code
   :evidence "Dockerfile:23"))
 :defects
 ((:what "GATE-4 «Pipeline integrity (no subprocess)» δηλώνεται στον πίνακα πυλών αλλά ΔΕΝ ΥΠΑΡΧΕΙ ως κώδικας: με αυτή τη σημασία το string εμφανίζεται ΜΟΝΟ στο README.md:304 σε ολόκληρο το repo. Οι 25 πραγματικές εντολές -gate δεν περιλαμβάνουν καμία πύλη subprocess/purity. Το source/pdf-authority.lisp ΔΕΝ σαρώνεται από τίποτα."
   :severity :p1
   :evidence "README.md:304 source/pdf-authority.lisp:1386-1425"
   :is-it-in-the-known-defect-list :no)
  (:what "README.md:253 δηλώνει source/gate-guards.lisp («CI/CD guards (Pure Lisp)») που ΔΕΝ ΥΠΑΡΧΕΙ."
   :severity :p1
   :evidence "README.md:253"
   :is-it-in-the-known-defect-list :no)
  (:what "source/pdf-authority.lisp:28 δηλώνει «No Python, no subprocess, direct C library access» και το ΙΔΙΟ αρχείο εκκινεί 5 subprocess (which/tesseract/pdftoppm) στις 1386-1425. Η κεφαλίδα διαψεύδεται από το σώμα του ίδιου αρχείου."
   :severity :p1
   :evidence "source/pdf-authority.lisp:28 source/pdf-authority.lisp:1386-1425"
   :is-it-in-the-known-defect-list :no)
  (:what "docker-compose.yml:17 — αδέσποτο εισαγωγικό στο tmpfs option της ΚΥΡΙΑΣ υπηρεσίας: «/tmp:size=256m,mode=1777\"». Οι άλλες 4 tmpfs γραμμές (133,210,299,348) δεν το έχουν."
   :severity :p1
   :evidence "docker-compose.yml:17"
   :is-it-in-the-known-defect-list :no)
  (:what "Το τεκμηριωμένο quickstart «docker compose build && docker compose up» (README:64-65) δεν μπορεί να πετύχει: το compose δίνει GIT_COMMIT default «dev» ενώ το Dockerfile απαιτεί ακριβώς 40-hex αλλιώς FATAL."
   :severity :p1
   :evidence "docker-compose.yml:8 Dockerfile:172-173 README.md:64-65"
   :is-it-in-the-known-defect-list :no)
  (:what "ARG SBCL_VERSION=2.4.0 δηλώνεται ΔΥΟ φορές (16, 56) και ΔΕΝ χρησιμοποιείται πουθενά· η SBCL εγκαθίσταται unpinned μέσω apt (41-43, 68-69, 374). Η δηλωμένη έκδοση είναι διακοσμητική."
   :severity :p2
   :evidence "Dockerfile:16 Dockerfile:56 Dockerfile:41-43")
  (:what "«hermetic build» (Dockerfile:5) με 3× apt-get update && apt-get install χωρίς pinning εκδόσεων — δικτυακή, μη αναπαραγώγιμη εγκατάσταση."
   :severity :p1
   :evidence "Dockerfile:5 Dockerfile:41-43 Dockerfile:68-77 Dockerfile:363-377")
  (:what "authority-v2-proofs: privileged:true + ΟΛΟΚΛΗΡΟ το repo ως .:/repo:rw + bash + apt-get install python3 + image debian:bookworm-slim (UNPINNED tag, ενώ ο Dockerfile καρφώνει digest)."
   :severity :p1
   :evidence "docker-compose.yml:376-397")
  (:what "orchestrator-tooling.asd: ΟΡΦΑΝΟ — μηδέν αναφορές σε όλο το repo, :components () κενό."
   :severity :p2
   :evidence "orchestrator-tooling.asd:5-20")
  (:what "5 .asd δηλώνουν test-op (orchestrator, orchestrator-core-runtime, orchestrator-omega, orchestrator-tests, orchestrator-tests-runtime) αλλά ΚΑΝΕΝΑ Dockerfile/CI/compose δεν καλεί ποτέ asdf test-op — νεκρές δηλώσεις."
   :severity :p2
   :evidence "orchestrator-core-runtime.asd:31 orchestrator.asd:41 orchestrator-tests-runtime.asd:24")
  (:what "Dockerfile.test κατεβάζει Quicklisp από το δίκτυο (curl https://beta.quicklisp.org/quicklisp.lisp) και κάνει ql:quickload :fiveam, ενώ Dockerfile:108, build.lisp:11 και DEPENDENCY-CONTRACT.md:207 δηλώνουν ρητά «NO Quicklisp». Τρέχει ως root. Κανένα αρχείο build/CI δεν το αναφέρει."
   :severity :p1
   :evidence "Dockerfile.test:9-30 Dockerfile:108 build.lisp:11 DEPENDENCY-CONTRACT.md:207"
   :is-it-in-the-known-defect-list :yes)
  (:what "package.json δηλώνει playwright ^1.61.0 (headless Chromium) σε repo που δηλώνει «100% Common Lisp». Η αλυσίδα είναι ζωντανή: configs/constitution.yaml:90 fetch_cmd «bash deployment/fetch-fek-by-number.sh …» → run-fetch-command /bin/sh -c → deployment/fetch-fek.sh:16,67 → node + Playwright/Chromium."
   :severity :p1
   :evidence "package.json:1-5 configs/constitution.yaml:90 source/document-fetch.lisp:92-106 deployment/fetch-fek.sh:16-23"
   :is-it-in-the-known-defect-list :no)
  (:what "SEMANTIC-CONTRACT.md:60 διδάσκει «sha256sum -c deps.lock» — αδύνατο: το deps.lock είναι «<dir> | <sha256>» (deps.lock:2), όχι η μορφή που δέχεται το sha256sum -c. Ο πραγματικός verifier είναι sbcl --script docker/verify-deps.lisp (deps.lock:6)."
   :severity :p2
   :evidence "SEMANTIC-CONTRACT.md:60 deps.lock:2 deps.lock:6"
   :is-it-in-the-known-defect-list :no)
  (:what "SEMANTIC-CONTRACT.md:61 διδάσκει «./scripts/verify-deterministic-build.sh» — ΔΕΝ ΥΠΑΡΧΕΙ στο scripts/ (8 αρχεία, κανένα με αυτό το όνομα). Είναι εντολή επαλήθευσης δηλωμένης ΕΓΓΥΗΣΗΣ αναπαραγωγιμότητας."
   :severity :p1
   :evidence "SEMANTIC-CONTRACT.md:56-62"
   :is-it-in-the-known-defect-list :no)
  (:what "SEMANTIC-CONTRACT.md:22-24 δηλώνει ΕΓΓΥΗΣΗ «All releases, commits, and tags are signed with GPG», αλλά το provenance.yml παρακάμπτει σιωπηλά την υπογραφή όταν λείπει το secret (if: secrets.GPG_PRIVATE_KEY == '') με απλό echo warning — η «εγγύηση» υποβαθμίζεται σε προαιρετική χωρίς κόκκινο."
   :severity :p1
   :evidence "SEMANTIC-CONTRACT.md:22-24 .github/workflows/provenance.yml:128 .github/workflows/provenance.yml:143-151"
   :is-it-in-the-known-defect-list :no)
  (:what ".github/workflows/docker-orchestrator.yml:231 — «curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh»: εκτέλεση απομακρυσμένου, μη καρφωμένου κώδικα από το internet μέσα στο CI που παράγει το SBOM."
   :severity :p1
   :evidence ".github/workflows/docker-orchestrator.yml:228-234"
   :is-it-in-the-known-defect-list :no)
  (:what "CI βήμα «Smoke test orchestrator loading» κάνει asdf:load-asd \"/app/orchestrator.asd\" στο orchestrator:test — το runtime stage ΔΕΝ αντιγράφει ΚΑΝΕΝΑ .asd (0 αναφορές στις γραμμές 333-453) και το βήμα ΔΕΝ κάνει --entrypoint override (σε αντίθεση με τη γραμμή 306 που το κάνει ρητά)."
   :severity :p1
   :evidence ".github/workflows/docker-orchestrator.yml:338-346 Dockerfile:394-410")
  (:what "deps.archives.lock είναι ΚΕΝΟ — περιέχει μόνο τη γραμμή σχολίου «# name sha256(zip)» (20 bytes)."
   :severity :p2
   :evidence "deps.archives.lock:1"
   :is-it-in-the-known-defect-list :no)
  (:what "tools/independent-audit.py: το ΜΟΝΟ αρχείο του tools/ είναι Python που απαιτεί pip install pymupdf — μη κλειδωμένο σε deps.lock, μη εκτελούμενο από CI. Τα ευρήματα ορθότητας corpus (docs/AUDIT-8-QUIRKS.md:3) στηρίζονται σε αυτό."
   :severity :p2
   :evidence "tools/independent-audit.py:1-20 docs/AUDIT-8-QUIRKS.md:3"
   :is-it-in-the-known-defect-list :no)
  (:what "orchestrator-epistemic ΔΕΝ φορτώνεται από το build.lisp, ενώ README:230 διδάσκει (orchestrator.engine:run-epistemic-pipeline)."
   :severity :p2
   :evidence "build.lisp:34 README.md:230"))
 :hidden-execution-paths
 ((:path "/bin/sh -c <command> από run-fetch-command"
   :trigger "network-edge fetch"
   :why-hidden "README:19 δηλώνει «Zero shell-script orchestration in the trusted path»· εδώ εκτελείται ΚΕΛΥΦΟΣ με string interpolation."
   :evidence "source/document-fetch.lisp:92-106")
  (:path "pdftoppm / tesseract / which / tesseract --list-langs"
   :trigger "extract-text-any σε σαρωμένο PDF (<600 chars text layer)"
   :why-hidden "Καλύπτεται από καμία πύλη· τα binaries εγκαθίστανται ρητά στο runtime image."
   :evidence "source/pdf-authority.lisp:1399-1425 Dockerfile:371-373")
  (:path "bash /app/scripts/merkle-mutation-witness.sh"
   :trigger "docker build --target verifier-conformance"
   :why-hidden "Bash μέσα στην αποδεικτική αλυσίδα που παράγει το runtime."
   :evidence "Dockerfile:290")
  (:path "docker/entrypoint.lisp run-subprocess (sb-ext:run-program)"
   :trigger "κάθε εκκίνηση container"
   :why-hidden "fork+wait, ΟΧΙ exec — ο wrapper παραμένει ζωντανός ως γονέας."
   :evidence "docker/entrypoint.lisp:67-77 Dockerfile:452"))
 :duplicate-seats
 ((:concept "container entrypoint"
   :seats ("entrypoint.lisp:1-83 (ΟΡΦΑΝΟ: φορτώνει :orchestrator + :orchestrator-tests, ΔΕΝ τρέχει ποτέ)"
           "docker/entrypoint.lisp:1-182 (ΤΟ ΠΡΑΓΜΑΤΙΚΟ — Dockerfile:409,452)"))
  (:concept "aggregate system definition (ίδια 10 subsystems)"
   :seats ("orchestrator.asd:19-28" "orchestrator-core-runtime.asd:17-26"))
  (:concept "ποιο σύστημα φορτώνεται"
   :seats ("build.lisp:34 :orchestrator-core-runtime" "entrypoint.lisp:16 :orchestrator" "README.md:227 :orchestrator-omega"))
  (:concept "health file path"
   :seats ("Dockerfile:445-447 /run/lawmax/.healthy" "docker/entrypoint.lisp:163 /app/output/.healthy")))
 :unknowns ("Dockerfile.test" "docker-compose.{architecture,citation,tokenizer}-tests.yml" ".github/workflows x3" "deps.lock vs third-party" "PROVENANCE.yaml" "SEMANTIC-CONTRACT.md" "DEPENDENCY-CONTRACT.md" "SYSTEM-HIERARCHY.txt" "CHANGELOG.md" "LICENSE" "CLAUDE.md" "MANUAL-STEPS-HERMETIC.md" "DEPLOY-PRODUCTION.md" "RUN-DOCKER.md" "configs/ x9" "docs/ x18" "cloudflare/ x5" "tools/independent-audit.py")
 :remaining ("τα 57 αρχεία της λίστας :unknowns"))
