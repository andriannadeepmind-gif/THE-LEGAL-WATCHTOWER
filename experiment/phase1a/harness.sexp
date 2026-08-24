(:lawmax-phase1a-cluster/1
 :cluster "harness — ΜΗΧΑΝΙΣΜΟΣ ΕΠΑΛΗΘΕΥΣΗΣ (/frozen/ro/tests 152 · /frozen/ro/docker 16 · /frozen/ro/scripts 8)"
 :status :partial
 :files-read 18

 :capabilities
 ((:name "Απογραφή σουιτών από filesystem (glob) μείον ΜΙΑ δηλωμένη πηγή εξαιρέσεων"
   :presence :present
   :domain "Ποιες tests/*-test.lisp τρέχουν ως gate στο standalone-test stage."
   :assumptions "Το inventory ΤΑΥΤΙΖΕΤΑΙ με το glob TESTS_DIR/*-test.lisp (μη αναδρομικό)· κάθε suite είναι εκτελέσιμη με «sbcl --script RUNNER file»· ο δίσκος του stage έχει το ίδιο σύνολο με το repo."
   :guarantees "Νέα σουίτα με κατάληξη -test.lisp μπαίνει ΑΥΤΟΜΑΤΑ· εξαίρεση απαιτεί ρητή γραμμή· stale/typo εξαίρεση = exit 1· κενό inventory = exit 1· ran=0 = exit 1."
   :failure-semantics "fail-closed exit 1/2· pipefail ⇒ PIPESTATUS[0] του sbcl (όχι του tee)."
   :operating-model "Docker build stage standalone-test, μία RUN γραμμή."
   :materiality "Είναι η ΜΟΝΗ έδρα εκτέλεσης· ό,τι δεν πιάνει ο glob δεν τρέχει ΠΟΤΕ."
   :evidence "docker/run-standalone-suites.sh:L53-102")
  (:name "Totality ταξινόμησης tests/*.lisp (gated | δηλωμένη εξαίρεση | nonsuite)"
   :presence :present
   :domain "Κανένα tests/*.lisp δεν μένει αταξινόμητο."
   :assumptions "os.listdir(tests_dir) — ΜΟΝΟ πρώτο επίπεδο, καμία αναδρομή."
   :guarantees "Αταξινόμητο *.lisp ⇒ FAIL· nonsuite δήλωση για ανύπαρκτο αρχείο ⇒ FAIL."
   :failure-semantics "sys.exit(1) με απαρίθμηση."
   :operating-model "python3 verify-proof-manifest.py μέσα στο verifier-conformance stage."
   :materiality "Έκλεισε το κενό των 8 DARPA-era αρχείων."
   :evidence "docker/verify-proof-manifest.py:L195-207")
  (:name "Ratchet σουιτών με ΠΑΓΩΜΕΝΟ committed μητρώο (suite-census.txt)"
   :presence :present
   :domain "Σιωπηλή συρρίκνωση του gated set (διαγραφή αρχείου Ή νέα εξαίρεση)."
   :assumptions "Το μητρώο ενημερώνεται ΜΟΝΟ με ορατό diff· δεν υπάρχει δεύτερη έδρα που να το παράγει."
   :guarantees "census − expected ⇒ FAIL (σιωπηλή αφαίρεση)· expected − census ⇒ FAIL (αδήλωτη προσθήκη). Επαληθεύτηκε ΑΡΙΘΜΗΤΙΚΑ: 136 tests/*-test.lisp − 1 εξαίρεση (comparison) = 135 ≡ 135 γραμμές μητρώου, 0 απόκλιση."
   :failure-semantics "sys.exit(1)."
   :operating-model "verifier-conformance stage."
   :materiality "Η μόνη άμυνα που επιβιώνει και της διαγραφής και της εξαίρεσης."
   :evidence "docker/verify-proof-manifest.py:L221-236 · docker/suite-census.txt:L2-136")
  (:name "Ratchet verifiers με ΑΝΕΞΑΡΤΗΤΟ committed μητρώο (verifier-census.txt)"
   :presence :spec-only
   :domain "Ποια δημόσια verifier αρχεία δεσμεύονται με sha256 στο verifier-proof.json."
   :assumptions "ΟΤΙ το docker/verifier-census.txt ΥΠΑΡΧΕΙ στο /app/docker/ της εικόνας."
   :guarantees "ΔΗΛΩΜΕΝΕΣ: απόν/κενό/διπλότυπο μητρώο = fail-closed· κλειστό σχήμα JSON (αδήλωτο κλειδί = FAIL)· επανυπολογισμός sha256 από τα πραγματικά αρχεία."
   :failure-semantics "sys.exit(1)."
   :operating-model "verifier-conformance stage."
   :materiality "Ο ίδιος ο μηχανισμός ΔΕΝ μπορεί να εκτελεστεί: το αρχείο δεν αντιγράφεται ΠΟΤΕ στην εικόνα (βλ. defect P0-1)."
   :evidence "docker/verify-proof-manifest.py:L97-119 · Dockerfile:L177 · Dockerfile:L302")
  (:name "Δέσμευση αποτελέσματος ανά σουίτα (parseable, failed=0)"
   :presence :present
   :domain "Κάθε σουίτα του manifest έχει μη κενή, αναγνωρίσιμη γραμμή αποτελέσματος με failed=0."
   :assumptions "Η ΤΕΛΕΥΤΑΙΑ γραμμή του log που ταιριάζει στο grep είναι η γραμμή αποτελέσματος· τα RESULT_PATTERNS εφαρμόζονται με .search() (υποσυμβολοσειρά, ΟΧΙ αγκύρωση)· ΔΕΝ υπάρχει κατώφλι ελάχιστων assertions."
   :guarantees "Κενό/μη parseable ⇒ FAIL· failed≠0 ⇒ FAIL· διπλότυπη σουίτα ⇒ FAIL· manifest set ≡ suites-run.txt set."
   :failure-semantics "sys.exit(1)."
   :operating-model "Dockerfile L197-221 παράγει, L316 επαληθεύει."
   :materiality "«0 passed, 0 failed» ΓΙΝΕΤΑΙ ΔΕΚΤΟ — δεν υπάρχει κάτω φράγμα assertions."
   :evidence "docker/verify-proof-manifest.py:L129-150 · Dockerfile:L213-218")
  (:name "SKIP whitelist"
   :presence :present
   :domain "Ποιες σουίτες επιτρέπεται να δηλώσουν SKIP στο standalone stage."
   :assumptions "Μία και μόνη: cross-language-verifier (ξανατρέχει ως σκληρό gate στο verifier-conformance)."
   :guarantees "SKIP από άλλη σουίτα ⇒ FAIL («μη αναγνωρίσιμη γραμμή αποτελέσματος»)."
   :failure-semantics "sys.exit(1)."
   :operating-model "verifier-conformance stage."
   :materiality "Πιάνει τα εσωτερικά SKIP-with-exit-0 ΜΟΝΟ όταν το SKIP είναι η τελευταία grep-ταιριαστή γραμμή ΚΑΙ μόνο μέσα στην αλυσίδα docker."
   :evidence "docker/verify-proof-manifest.py:L121-125,L147-150"))

 :authorities
 ((:name "run-standalone-suites.sh — Η ΜΙΑ ΕΔΡΑ ΕΚΤΕΛΕΣΗΣ"
   :what-it-can-decide "Ποια σουίτα τρέχει, ποια παρακάμπτεται, αν το build κοκκινίζει."
   :who-can-invoke "Dockerfile standalone-test stage· CI self-check."
   :enforcement :code :evidence "docker/run-standalone-suites.sh:L25-103")
  (:name "standalone-suite-exclusions.txt — Η ΜΙΑ ΔΗΛΩΜΕΝΗ ΠΗΓΗ ΕΞΑΙΡΕΣΕΩΝ"
   :what-it-can-decide "Ποια σουίτα δεν τρέχει ως gate· ποιο tests/*.lisp δεν είναι σουίτα."
   :who-can-invoke "Διαβάζεται από run-standalone-suites.sh ΚΑΙ verify-proof-manifest.py."
   :enforcement :code :evidence "docker/standalone-suite-exclusions.txt:L16,L36-43")
  (:name "verify-proof-manifest.py — δικαστής του proof"
   :what-it-can-decide "Αν το runtime image χτίζεται καθόλου."
   :who-can-invoke "Dockerfile:L316 (verifier-conformance)."
   :enforcement :code :evidence "docker/verify-proof-manifest.py:L159-290")
  (:name "SOURCE_DATE_EPOCH (env) — de facto αρχή χρόνου"
   :what-it-can-decide "Αν το deterministic mode είναι ενεργό ⇒ αν σουίτες που καλούν require-deterministic-time περνούν."
   :who-can-invoke "Οποιοσδήποτε ορίζει το env var· ENV μόνο στο builder stage."
   :enforcement :convention :evidence "source/deterministic-time.lisp:L206-220 · Dockerfile:L61-64"))

 :invariants
 ((:statement "Καμία tests/*-test.lisp δεν μπορεί να ξεχαστεί από το gated set"
   :enforced-by "glob + exclusions + census set-equality"
   :evidence "docker/run-standalone-suites.sh:L53-57 · docker/verify-proof-manifest.py:L209-236")
  (:statement "Καμία «πέρασαν 0 σουίτες» ψευδο-επιτυχία"
   :enforced-by "ran=0 ⇒ exit 1· κενό inventory ⇒ exit 1"
   :evidence "docker/run-standalone-suites.sh:L55-57,L100-102")
  (:statement "stale/typo suite-εξαίρεση = build red"
   :enforced-by "name_exists() πάνω στα πραγματικά basenames"
   :evidence "docker/run-standalone-suites.sh:L64-74")
  (:statement "verifier-proof.json κλειστό σχήμα — αδήλωτο κλειδί = FAIL"
   :enforced-by "allowed_keys = {proof,git_commit,gates} ∪ census keys"
   :evidence "docker/verify-proof-manifest.py:L251-257"))

 :defects
 ((:what "P0 — docker/verifier-census.txt ΔΕΝ αντιγράφεται ΠΟΤΕ στην εικόνα. Διαβάζεται σε ΔΥΟ σημεία ως /app/docker/verifier-census.txt (Dockerfile:L302 για την παραγωγή του verifier-proof.json, verify-proof-manifest.py:L100 για τον έλεγχο), αλλά το μοναδικό COPY docker/... (Dockerfile:L177) δεν το περιλαμβάνει και καμία άλλη COPY δεν φέρνει τον κατάλογο docker/. Η «ΜΙΑ ΕΔΡΑ» που εξήχθη από τον κώδικα ακριβώς για να πεθάνει η κλάση «αόρατη συρρίκνωση ratchet» λείπει από το build context· ο ratchet των verifiers είναι :spec-only."
   :severity :p0 :evidence "Dockerfile:L177 · Dockerfile:L302 · docker/verify-proof-manifest.py:L95-119"
   :is-it-in-the-known-defect-list :no)
  (:what "P0 — ΔΥΟ ΑΝΤΙΦΑΤΙΚΕΣ ΕΔΡΕΣ για τη συμβολοσειρά algorithm του corpus-proof: proof-carrying-test απαιτεί να ΠΕΡΙΕΧΕΙ «sha256-merkle/rfc6962+RS256»· merkle-single-truth-test απαιτεί το source/proof-carrying.lisp να ΜΗΝ περιέχει «sha256-merkle/rfc6962». Αμοιβαία ΜΗ ΙΚΑΝΟΠΟΙΗΣΙΜΕΣ. Ο κώδικας εκπέμπει «lawmax-merkle-sha256-v1+RS256» ⇒ το proof-carrying-test ΑΠΟΤΥΓΧΑΝΕΙ. ΕΛΑΤΤΩΜΑ HARNESS: μη συνταξιοδοτημένη δεύτερη έδρα."
   :severity :p0 :evidence "tests/proof-carrying-test.lisp:L179-182 · tests/merkle-single-truth-test.lisp:L510-513 · source/proof-carrying.lisp:L177"
   :is-it-in-the-known-defect-list :no)
  (:what "P0 — hash-seat-registry: STALE δήλωση. Επαληθεύτηκε με ανεξάρτητη επανεκτέλεση του ΙΔΙΟΥ σαρωτή: 23 πραγματικές hash-έδρες στο repo, 24 δηλωμένες. Περίσσεια = systems/orchestrator-epistemic/deploy-epistemic.lisp, το οποίο έχει ΜΗΔΕΝ εμφανίσεις οποιασδήποτε ironclad digest fn ΚΑΙ μηδέν αναφορές σε hash-authority/compute-hash. ΕΛΑΤΤΩΜΑ CORPUS (το μητρώο deployment/verify/hash-seat-registry.sexp είναι ξεπερασμένο)· ο ελεγκτής λειτουργεί σωστά."
   :severity :p0 :evidence "tests/hash-seat-registry-test.lisp:L110-116 · deployment/verify/hash-seat-registry.sexp:L36"
   :is-it-in-the-known-defect-list :no)
  (:what "P0 — merkle-single-truth: ο δηλωμένος :publisher systems/orchestrator-epistemic/transparency-log.lisp ελέγχεται για «άμυνα κενού συνόλου» με (search \"(list release-root)\" txt). Ο δείκτης έχει 0 εμφανίσεις στο αρχείο ⇒ ΑΠΟΤΥΧΙΑ. Αιτία: η έδρα εγγραφής tlog-append-root! ΚΑΤΑΡΓΗΘΗΚΕ (%seat-removed)· το αρχείο δεν είναι πλέον publisher, μόνο verifier. ΕΛΑΤΤΩΜΑ HARNESS: το +declared-root-callers+ είναι stale ως προς το corpus."
   :severity :p0 :evidence "tests/merkle-single-truth-test.lisp:L519-533,L553-560 · systems/orchestrator-epistemic/transparency-log.lisp:L117-132"
   :is-it-in-the-known-defect-list :no)
  (:what "P0 — mcp-live-resolver: το %mcp-resolve-article καλεί orchestrator.time:require-deterministic-time, που ΣΦΑΛΜΑΤΙΖΕΙ αν το deterministic mode δεν είναι ενεργό. Ενεργοποιείται ΜΟΝΟ από το env var SOURCE_DATE_EPOCH σε (eval-when (:load-toplevel)). Ούτε το run-standalone-suites.sh ούτε το run-standalone-test.lisp το ορίζουν — ορίζεται ΜΟΝΟ ως ENV στο builder stage του Dockerfile. ΕΛΑΤΤΩΜΑ HARNESS: το αποτέλεσμα της σουίτας εξαρτάται από ambient env var· η ίδια η επικεφαλίδα της σουίτας δηλώνει ψευδώς «Pure, offline, deterministic»."
   :severity :p0 :evidence "tests/mcp-live-resolver-test.lisp:L6 · systems/orchestrator-cli/main.lisp:L2214-2216 · source/deterministic-time.lisp:L164-176,L206-220 · Dockerfile:L61-64"
   :is-it-in-the-known-defect-list :no)
  (:what "P1 — ΤΑΥΤΟΛΟΓΙΑ ΜΕ ΟΝΟΜΑΣΤΙΚΗ ΑΙΤΙΟΛΟΓΗΣΗ: η «άμυνα κενού συνόλου» κάθε :publisher επαληθεύεται με (search marker txt) πάνω στο ΠΗΓΑΙΟ ΚΕΙΜΕΝΟ. Για το artifact-census.lisp ο marker είναι ΕΛΛΗΝΙΚΟ ΣΧΟΛΙΟ («κενό σύνολο άρθρων») — επαληθεύεται η ΥΠΑΡΞΗ ΣΧΟΛΙΟΥ, όχι συμπεριφορά."
   :severity :p1 :evidence "tests/merkle-single-truth-test.lisp:L524,L555-560"
   :is-it-in-the-known-defect-list :no)
  (:what "P1 — ΕΛΕΓΧΟΣ DOCSTRING: το hash-seat-registry-test κλείνει με check που κοιτά αν λείπει η φράση «ONLY authorized hash function» από το source/hash-authority.lisp — έλεγχος κειμένου σχολίου ως «τίμια εμβέλεια»."
   :severity :p1 :evidence "tests/hash-seat-registry-test.lisp:L138-141"
   :is-it-in-the-known-defect-list :no)
  (:what "P1 — ΑΝΤΙΦΑΣΗ ΜΕΣΑ ΣΤΟ ΙΔΙΟ ΑΡΧΕΙΟ: check με τίτλο «ο ΜΟΝΟΣ δηλωμένος ΔΗΜΟΣΙΕΥΤΗΣ» ενώ το ίδιο αρχείο δηλώνει ΤΡΕΙΣ :publisher εγγραφές."
   :severity :p1 :evidence "tests/merkle-single-truth-test.lisp:L523-525,L562-565"
   :is-it-in-the-known-defect-list :no)
  (:what "P1 — «0 passed, 0 failed» ΓΙΝΕΤΑΙ ΔΕΚΤΟ: τα RESULT_PATTERNS εφαρμόζονται με .search() και ελέγχουν ΜΟΝΟ group(2)==0. Καμία απαίτηση ελάχιστου αριθμού επιτυχιών ⇒ σουίτα που δεν εκτέλεσε καμία διαβεβαίωση περνά το manifest gate."
   :severity :p1 :evidence "docker/verify-proof-manifest.py:L129-150"
   :is-it-in-the-known-defect-list :no)
  (:what "P1 — Ο ΕΠΑΝΥΠΟΛΟΓΙΣΜΟΣ HASH ΕΙΝΑΙ ΠΡΟΑΙΡΕΤΙΚΟΣ: όλο το σκέλος «επανυπολογισμός από τα ΠΡΑΓΜΑΤΙΚΑ αρχεία» είναι υπό «if app_root:». Με 2 ορίσματα (η υπογραφή το επιτρέπει ρητά) ο verifier ελέγχει ΜΟΝΟ ότι τα πεδία είναι 64-hex — δηλαδή ότι μοιάζουν με hash."
   :severity :p1 :evidence "docker/verify-proof-manifest.py:L261-282,L292-295"
   :is-it-in-the-known-defect-list :no)
  (:what "P1 — source_tree_sha256 ΔΕΝ επανυπολογίζεται ΠΟΤΕ (ούτε καν με app_root): μόνο έλεγχος μορφής 64-hex."
   :severity :p1 :evidence "docker/verify-proof-manifest.py:L170-173,L261-282 · Dockerfile:L200-201"
   :is-it-in-the-known-defect-list :no)
  (:what "P1 — EXPECTED_GATES παραμένει ΣΤΑΘΕΡΑ ΜΕΣΑ ΣΤΟΝ ΚΩΔΙΚΑ, ενώ το ίδιο αρχείο τεκμηριώνει ρητά ότι μια in-code λίστα συρρικνώνεται αόρατα (γι' αυτό εξήχθη το verifier-census.txt). Και δεύτερο αντίγραφο της ίδιας λίστας ζει στο Dockerfile:L308."
   :severity :p1 :evidence "docker/verify-proof-manifest.py:L85-87,L89-95 · Dockerfile:L308"
   :is-it-in-the-known-defect-list :no)
  (:what "P2 — VERIFIER_STAGE_ONLY = set() : νεκρός διακόπτης που αφαιρεί σουίτες από το expected set, χωρίς καμία δηλωμένη πηγή/αιτιολόγηση, εκτός του exclusions αρχείου (δεύτερη, αδήλωτη έδρα εξαιρέσεων)."
   :severity :p2 :evidence "docker/verify-proof-manifest.py:L76-78,L209-210"
   :is-it-in-the-known-defect-list :no))

 :hidden-execution-paths
 ((:path "Σουίτες ΓΡΑΦΟΥΝ ΚΑΙ ΣΒΗΝΟΥΝ μέσα στο ζωντανό corpus: <institution-root>/deployment/data/version-graph/"
   :trigger "Κάθε εκτέλεση των σχετικών σουιτών (και εντός docker και τοπικά)."
   :why-hidden "Το institution-root είναι env-overridable (LAWMAX_ROOT / ORCHESTRATOR_ROOT) και εναλλακτικά η ASDF runtime θέση = η ρίζα του repo. Τα graph-import-parity-test.lisp:L27-30 και legal-authority-receipt-test.lisp:L26-29 κάνουν uiop:delete-directory-tree ΟΛΟΚΛΗΡΟΥ του καταλόγου με :validate (constantly t) — ο φρουρός ακύρωσης είναι ΡΗΤΑ απενεργοποιημένος."
   :evidence "tests/graph-import-parity-test.lisp:L27-30 · tests/legal-authority-receipt-test.lisp:L26-29 · source/version-graph.lisp:L441-444 · source/paths.lisp:L108-129")
  (:path "Το source_tree_sha256 του υπογεγραμμένου proof υπολογίζεται ΜΕΤΑ τη μόλυνση του δέντρου από τις ίδιες τις σουίτες"
   :trigger "Dockerfile:L189 (τρέχουν οι σουίτες) → Dockerfile:L200 (find … /app/deployment/data …)."
   :why-hidden "Το /app/deployment/data περιλαμβάνεται στο SRC hash· ο κατάλογος version-graph/ ΔΕΝ ΥΠΑΡΧΕΙ στο committed δέντρο (επαληθεύτηκε: απών στο /frozen/ro) — δημιουργείται από τις σουίτες. Άρα το «source tree» hash δεν είναι hash του committed source."
   :evidence "Dockerfile:L189,L200-201")
  (:path "SKIP με exit 0 πριν από κάθε assertion"
   :trigger "Απών source/safe-read.lisp"
   :why-hidden "Η σουίτα τυπώνει «SKIP» και κάνει (sb-ext:exit :code 0) — εκτός docker φαίνεται ως επιτυχία."
   :evidence "tests/hash-seat-registry-test.lisp:L18-23")
  (:path "Ο runner δεν απαιτεί (sb-ext:exit) — αρχείο που φορτώνεται χωρίς exit βγαίνει 0"
   :trigger "Σουίτα που δεν φτάνει ποτέ σε (sb-ext:exit)"
   :why-hidden "(load f) στο τέλος του script· καμία επιβολή ρητού exit· επιπλέον handler-bind muffle σε ΟΛΑ τα warnings."
   :evidence "docker/run-standalone-test.lisp:L41-46")
  (:path "fiveam φορτώνεται με (ignore-errors …)"
   :trigger "Απών fiveam"
   :why-hidden "Οι FiveAM σουίτες θα σπάσουν αργότερα με άλλο μήνυμα· η απουσία του framework δεν δηλώνεται."
   :evidence "docker/run-standalone-test.lisp:L36-39"))

 :duplicate-seats
 ((:concept "«τι δηλώνει η algorithm string του corpus-proof»"
   :seats ("tests/proof-carrying-test.lisp:L179" "tests/merkle-single-truth-test.lisp:L510"))
  (:concept "λίστα gates του verifier-proof"
   :seats ("docker/verify-proof-manifest.py:L85" "Dockerfile:L308"))
  (:concept "εξαιρέσεις από το gated set"
   :seats ("docker/standalone-suite-exclusions.txt:L16" "docker/verify-proof-manifest.py:L78"))
  (:concept "ντετερμινιστικός χρόνος"
   :seats ("source/deterministic-time.lisp:L155" "source/deterministic-time.lisp:L164")))

 :unknowns
 ("Δεν έχουν διαβαστεί ακόμη: scripts/ (8), docker/run-standalone-suites-test.sh, docker/verify-proof-manifest-test.py, docker/entrypoint.lisp, docker/sha256.lisp, docker/dep-hash.lisp, docker/verify-deps.lisp, docker/BUILD-ISSUES.md, docker/IMPLEMENTATION-SUMMARY.md, docker/sbom.json, docker/cosign.pub, και ~128 σουίτες.")

 :remaining
 ("scripts/capture-runtime-closure.lisp" "scripts/gen-deps-lock.lisp" "scripts/gen-merkle-truth.lisp"
  "scripts/generate-keys.lisp" "scripts/merkle-mutation-witness.sh" "scripts/verify-gate-5-validation.lisp"
  "scripts/verify-runtime-closure-test.sh" "scripts/verify-runtime-closure.sh"
  "docker/run-standalone-suites-test.sh" "docker/verify-proof-manifest-test.py" "docker/entrypoint.lisp"
  "docker/sha256.lisp" "docker/dep-hash.lisp" "docker/verify-deps.lisp" "docker/BUILD-ISSUES.md"
  "docker/IMPLEMENTATION-SUMMARY.md" "docker/sbom.json" "docker/cosign.pub"
  "tests/: seat-integrity retired-entrypoint capability-registry capability-gate reader-census artifact-census architecture-multiplicity self-identity kernel-conformance release-authority level7-disarm journal-integrity transparency-log corpus-identity + ~114 ακόμη"))
