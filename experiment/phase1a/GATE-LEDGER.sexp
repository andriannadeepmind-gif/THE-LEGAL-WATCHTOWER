;;;; experiment/phase1a/GATE-LEDGER.sexp
;;;; ΜΗΤΡΩΟ ΠΥΛΩΝ — ΚΑΘΕ αποτέλεσμα δεμένο με το hash του checker που το παρήγαγε.
;;;;
;;;; EARLY CORRECTION §2: ο citation resolver είναι VERSIONED GATE. Κάθε αλλαγή
;;;; του hash του καθιστά κάθε προηγούμενο αποτέλεσμα STALE μέχρι μηχανικό
;;;; re-gating. Τα προηγούμενα ΔΕΝ διαγράφονται — μένουν ως SUPERSEDED.

(:lawmax-gate-ledger/1
 :corpus "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
 :manifest-sha256 "92394c037b1337435adc1d78c719e91a141e7d67d9a14b89e4a3362bdb35b631"

 ;; ── ΕΚΔΟΣΕΙΣ ΤΟΥ RESOLVER ────────────────────────────────────────────────
 :resolver-versions
 ((:version 1 :sha256 "6c41e041aea11aafc6adf0c365ab9ad2ea9a46b78900242f40ddcf56d7427750"
   :limitation "το \\b δεν πιάνει διαδρομές με αρχικό «.» (.github/…)"
   :status :SUPERSEDED)
  (:version 2 :sha256 "79bf79efef764b70bb13f7f738d00e665c5acd0e39fa78ade82a866c93fe852a"
   :delta "αρχικό «.» + ευρετική αφαίρεση 3 mount prefixes"
   :limitation "ΕΥΡΕΤΙΚΗ κανονικοποίηση — δεχόταν /app/ και /frozen/watchtower/,
                χωρίς έλεγχο traversal, χωρίς cluster-root, χωρίς symlink έλεγχο"
   :status :SUPERSEDED)
  (:version 3 :sha256-prefix "d552d4171bc61669"
   :delta "EARLY CORRECTION §4: ΔΗΛΩΜΕΝΗ κανονικοποίηση — ΜΟΝΟ ακριβές
           /frozen/ro/· απόρριψη «..»· απόρριψη κάθε άλλου absolute· απόρριψη
           symlink· cluster-relative ΜΟΝΟ ως προς σφραγισμένο cluster-root·
           εκτύπωση resolver+manifest hash σε ΚΑΘΕ αποτέλεσμα"
   :witnesses (:positive 3 :negative 5
               :negative-cases ("path traversal ..", "absolute /app/",
                                "absolute /frozen/watchtower/",
                                "εκτός manifest υπό /frozen/ro/",
                                "ανύπαρκτο σχετικό"))
   :status :CURRENT))

 ;; ── ΑΠΟΤΕΛΕΣΜΑΤΑ ΑΝΑ DOSSIER, ΜΕ ΤΟΝ ΤΕΛΙΚΟ RESOLVER v3 ──────────────────
 :current-results
 ((:lane "Φ1A-L3" :dossier "experiment/phase1a/authority-v2.sexp"
   :dossier-sha256-prefix "c3bf9ce0fe3dd0db" :resolver 3
   :citations 165 :resolved 165 :problems 0 :exit 0)
  (:lane "Φ1A-L4" :dossier "experiment/phase1a/deployment-specs.sexp"
   :dossier-sha256-prefix "f895deb6721317b7" :resolver 3
   :citations 200 :resolved 200 :problems 0 :exit 0)
  (:lane "Φ1A-L5" :dossier "experiment/phase1a/deployment-state.sexp"
   :dossier-sha256-prefix "27dfbfc852110bea" :resolver 3
   :citations 156 :resolved 156 :problems 0 :exit 0)
  (:lane "Φ1A-L6" :dossier "experiment/phase1a/harness.sexp"
   :dossier-sha256-prefix "9ddd1820acf40205" :resolver 3
   :citations 98 :resolved 98 :problems 0 :exit 0)
  (:lane "Φ1A-L7" :dossier "experiment/phase1a/contracts.sexp"
   :dossier-sha256-prefix "6ab0457e1a7b2993" :resolver 3
   :citations 101 :resolved 101 :problems 0 :exit 0)
  (:lane "Φ1A-L2" :dossier "experiment/phase1a/systems.sexp"
   :dossier-sha256-prefix "8dafb52f355eb458" :resolver 3
   :citations 224 :resolved 175 :problems 49 :exit 1
   :status :RETURNED-TO-LANE
   :note "49 γυμνά ονόματα χωρίς κατάλογο. Επιστράφηκε ΣΤΗ ΔΙΑΔΡΟΜΗ με ρητή
          προειδοποίηση για ομώνυμα αρχεία (deploy-epistemic.lisp υπάρχει σε ΔΥΟ
          θέσεις και το ίδιο της το εύρημα #3 στηρίζεται στη διάκρισή τους).")
  (:lane "Φ1A-L1" :dossier "experiment/phase1a/source.sexp"
   :status :IN-PROGRESS :files-read 98 :of 133))

 ;; ── SUPERSEDED ΑΠΟΤΕΛΕΣΜΑΤΑ (διατηρούνται, δεν διαγράφονται) ────────────
 :superseded-results
 ((:lane "Φ1A-L7" :resolver 1 :dossier-sha256-prefix "3274504db73ffd44"
   :citations 101 :resolved 90 :problems 11 :exit 1
   :why-superseded "resolver v1 limitation + 2 γνήσια ελαττώματα dossier")
  (:lane "Φ1A-L7" :resolver 2 :dossier-sha256-prefix "6ab0457e1a7b2993"
   :citations 101 :resolved 101 :problems 0 :exit 0
   :why-superseded "ο resolver v2 αντικαταστάθηκε από τον v3· το αποτέλεσμα
                    επιβεβαιώθηκε ΞΑΝΑ με v3 (ίδιο 101/101)")
  (:lane "Φ1A-L3" :resolver 2 :citations 154 :resolved 154 :problems 0
   :why-superseded "v2→v3· επιβεβαιώθηκε ξανά, τώρα 165 παραπομπές λόγω
                    διευρυμένου καταλόγου επεκτάσεων του v3 (+cddl/mjs/ts/zip)")
  (:lane "Φ1A-L6" :resolver 2 :citations 98 :resolved 98 :problems 0
   :why-superseded "v2→v3· επιβεβαιώθηκε ξανά, ίδιο αποτέλεσμα")
  (:lane "Φ1A-L5" :resolver 2 :citations 152 :resolved 138 :problems 14
   :why-superseded "πριν από τη διόρθωση της lane· τώρα 156/156 με v3"))

 ;; ── ΣΥΜΦΙΛΙΩΣΗ ΤΩΝ ΑΡΧΙΚΩΝ 11 (§2/§5) — ΑΚΡΙΒΕΣ DISPOSITION ────────────
 :l7-initial-eleven
 (:original-result "resolver v1 × dossier 3274504db73ffd44 ⇒ 101 · 90 λύθηκαν · 11 προβληματικές"
  :reproduced-mechanically t
  :reproduction-command "python3 <resolver-v1> <dossier-pre>"
  :dispositions
  ((:class :resolver-limitation :count 9
    :cause "το \\b δεν ταιριάζει μεταξύ κενού και «.», άρα η σύλληψη ξεκινούσε
            από το «g» και αναζητούσε «github/…» αντί «.github/…»"
    :items (".github/workflows/docker-orchestrator.yml:292-308"
            ".github/workflows/docker-orchestrator.yml:298-299"
            ".github/workflows/docker-orchestrator.yml:359-378"
            ".github/workflows/docker-orchestrator.yml:228-234"
            ".github/workflows/docker-orchestrator.yml:338-346"
            ".github/workflows/docker-orchestrator.yml:306"
            ".github/workflows/docker-orchestrator.yml:371"
            ".github/workflows/provenance.yml:128"
            ".github/workflows/provenance.yml:143-151")
    :fixed-by "resolver v2 (αρχικό «.»)· διατηρείται στον v3"
    :dossier-changed nil)
   (:class :genuine-dossier-defect :count 2
    :cause "γυμνά ονόματα αρχείου χωρίς κατάλογο"
    :items ("article-root-generator-omega.lisp:175 → systems/orchestrator-omega-modules/article-root-generator-omega.lisp:175"
            "hybrid-generator-phase1.lisp:289 → systems/orchestrator-omega-modules/hybrid-generator-phase1.lisp:289")
    :fixed-by "Η ΙΔΙΑ Η ΔΙΑΔΡΟΜΗ Φ1A-L7, με επαλήθευση στο /frozen/ro"
    :dossier-changed t
    :dossier-sha256-before "3274504db73ffd44ea367494a0a29c296bf9d5b1829fc744afbd831c1748b9ee"
    :dossier-sha256-after  "6ab0457e1a7b2993941b95ce8bbf431910876892157e103c7a797d2f4731352d"))
  :arithmetic "9 + 2 = 11 ✓"
  :my-earlier-error "Είχα αναφέρει «7 + 2 = 9». ΛΑΘΟΣ ΜΕΤΡΗΣΗ ΔΙΚΗ ΜΟΥ: διάβασα
                     κομμένη έξοδο (head -8) και δεν επαλήθευσα το άθροισμα.
                     Τα 4 που έλειπαν ονομάζονται παραπάνω."
  :seal-timing "Η διόρθωση των 2 έγινε ΠΡΙΝ από κάθε σφράγιση. Το σφραγισμένο
                hash είναι το ΜΕΤΑ (6ab0457e…). ΚΑΝΕΝΑ σφραγισμένο dossier δεν
                τροποποιήθηκε επιτόπου — §3 τηρήθηκε εξ αρχής.")

 ;; ── ΠΟΛΙΤΙΚΗ ΑΝΑΘΕΩΡΗΣΕΩΝ (§3) ──────────────────────────────────────────
 :revision-policy
 (:rule "ΣΦΡΑΓΙΣΜΕΝΟ dossier ΔΕΝ τροποποιείται ΠΟΤΕ επιτόπου."
  :procedure ("η lane δημιουργεί ΝΕΑ revision"
              "η νέα revision δηλώνει :supersedes-sha256"
              "το παλιό hash ΜΕΝΕΙ σε αυτό το ledger"
              "το LANE-REGISTRY δείχνει ποια revision είναι :current")
  :applies-from :now
  :status-of-past "Καμία παραβίαση: όλες οι διορθώσεις έγιναν σε ΜΗ σφραγισμένα
                   dossiers. Το μόνο σφραγισμένο (L7) σφραγίστηκε ΜΕΤΑ τη
                   διόρθωσή του και δεν έχει αγγιχτεί έκτοτε."))
