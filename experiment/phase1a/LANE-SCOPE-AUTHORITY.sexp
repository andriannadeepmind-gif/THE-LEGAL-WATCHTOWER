;;;; experiment/phase1a/LANE-SCOPE-AUTHORITY.sexp
;;;; ΑΜΕΤΑΒΛΗΤΗ ΑΥΘΕΝΤΙΑ ΕΜΒΕΛΕΙΑΣ — ΣΦΡΑΓΙΖΕΤΑΙ ΚΑΙ ΔΕΝ ΑΛΛΑΖΕΙ
;;;;
;;;; ΓΙΑΤΙ ΧΩΡΙΣΤΑ: το παλιό LANE-REGISTRY.sexp κουβαλούσε ΤΑΥΤΟΧΡΟΝΑ
;;;; (α) την αμετάβλητη εμβέλεια που ΕΠΙΛΥΕΙ παραπομπές και
;;;; (β) μεταβλητά statuses/revisions.
;;;; Άρα ΚΑΘΕ αλλαγή κατάστασης άλλαζε το hash της αυθεντίας επίλυσης, και
;;;; κάθε receipt δενόταν σε κινούμενο στόχο. Αυτό είναι ΔΟΜΙΚΟ σφάλμα, όχι
;;;; ατύχημα. Εδώ ζει ΜΟΝΟ ό,τι είναι αμετάβλητο. Η κατάσταση ζει στο
;;;; LANE-STATE-LEDGER.sexp και ΔΕΝ συμμετέχει ΠΟΤΕ στην επίλυση παραπομπών.

(:lawmax-lane-scope-authority/1
 :status :SEALED
 :revision 2
 :mutable nil
 :changes-require "ρητή εντολή δημιουργού — ΟΧΙ γεγονός κατάστασης διαδρομής"
 :revision-2-reason
  "Ρητή εντολή δημιουργού: domain-separated ταυτότητα που περιλαμβάνει
   ΠΡΑΓΜΑΤΙΚΑ schema/commit/tree/leaf-root στο preimage, και διόρθωση του
   trailing_newline για κενά αρχεία. ΚΑΜΙΑ αλλαγή εμβέλειας ή roots."

 ;; ── ΤΟ ΠΑΓΩΜΕΝΟ ΔΕΝΤΡΟ ────────────────────────────────────────────────
 :frozen
 (:commit "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
  :tree-sha1 "23b7a6f4450f50d151d38e13020bee9872e73bcd"
  :read-only-mount "/frozen/ro"
  :mount-lifetime "ΔΕΝ επιβιώνει μεταξύ κλήσεων σε αυτό το περιβάλλον —
                   η πύλη mount μπαίνει ΚΑΘΕ φορά, αλλιώς καμία ανάγνωση")

 ;; ── Η ΤΑΥΤΟΤΗΤΑ ΤΟΥ CORPUS ────────────────────────────────────────────
 :corpus-manifest
 (:schema 4
  :leaves 35640
  :by-kind (:file 35559 :executable 75 :symlink 6)
  :identity-kind :DOMAIN-SEPARATED-PATH-AND-KIND-COMPLETE
  :identity "sha256:99602490aedba5f942413ec2454d189a5ccbc503deb64efdd146f9640e0f03a6"
  :identity-preimage
   "SHA256(\"LAWMAX-CORPUS-IDENTITY/1\\0\" ‖ u32be(schema) ‖ commit(20 raw)
           ‖ tree(20 raw) ‖ leaf-root(32 raw))"
  :leaf-root "sha256:3127f4941b899afcbffcd405b00d9e613fe4732301ba8ed990d22a0685514019"
  :enumeration-authority :GIT-TREE
  :access "openat2 · RESOLVE_BENEATH|RESOLVE_NO_SYMLINKS|RESOLVE_NO_XDEV|RESOLVE_NO_MAGICLINKS"

  :superseded-identities
  ((:schema 2 :root "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b"
    :covered-leaves 35634 :defect "os.walk· έλειπαν 6 symlinks· χωρίς διαδρομή/mode/kind")
   (:schema 3 :root "sha256:3127f4941b899afcbffcd405b00d9e613fe4732301ba8ed990d22a0685514019"
    :covered-leaves 35640
    :defect "ΗΤΑΝ ΜΟΝΟ LEAF ROOT. Δήλωνε ότι «δεσμεύει commit και tree» ενώ
             αυτά ήταν ΕΚΤΟΣ preimage — δύο δέντρα με ίδια φύλλα σε άλλο
             commit έδιναν ΙΔΙΑ ρίζα. Επιπλέον 14 ΚΕΝΑ αρχεία δηλώνονταν
             trailing_newline=1, που είναι αναληθές: δεν υπάρχει newline."))

  :schema-3-to-4-delta
  (:rows-changed 14 :what "ΚΕΝΑ text αρχεία: trailing_newline 1 → 0"
   :corpus-bytes-unchanged t
   :leaf-root-unchanged t
   :why-leaf-root-unchanged "το trailing_newline ΔΕΝ είναι μέρος του leaf preimage"
   :files ("evidence/self/.gitkeep" "evidence/version-graph/.gitkeep"
           "keys/public/.gitkeep" "releases/.gitkeep"
           "third-party/babel-20241012-git/tests/ebcdic-fi.txt"
           "third-party/babel-20241012-git/tests/ebcdic-fi.txt-utf8"
           "… 14 συνολικά, όλα e69de29b (κενό git blob)")))

 ;; ── ΣΗΜΑΣΙΟΛΟΓΙΑ ΔΙΑΔΡΟΜΩΝ — ΔΗΛΩΜΕΝΗ, ΟΧΙ ΕΥΡΕΤΙΚΗ ──────────────────
 :citation-forms
 ((:id :mount-anchored  :shape "/frozen/ro/<path>:L…" :base "το δηλωμένο mount")
  (:id :corpus-relative :shape "<path>:L…"            :base "ΠΑΝΤΑ η ρίζα του corpus"))
 :no-third-form "Καμία τρίτη ερμηνεία. ΚΑΜΙΑ fallback cluster-relative επίλυση."

 :cluster-root-semantics
 "Κάθε στοιχείο :cluster-roots είναι ΜΗ ΚΕΝΟ, ΜΗ απόλυτο, χωρίς «..», χωρίς
  τελικό «/», και ερμηνεύεται με ΑΚΡΙΒΩΣ έναν από δύο τρόπους:
    ① ΧΩΡΙΣ «*» ⇒ ΚΑΤΑΛΟΓΟΣ: rel == d  ή  rel αρχίζει με d+\"/\"  (αναδρομικά)
    ② ΜΕ «*»    ⇒ GLOB σε ΟΛΟΚΛΗΡΟ το rel, όπου «*» ΔΕΝ διασχίζει «/»
  ΤΑ ROOTS ΔΕΝ ΕΠΙΛΥΟΥΝ ΠΑΡΑΠΟΜΠΕΣ — μόνο αναφέρουν περιεκτικότητα."

 ;; ── ΟΙ ΕΠΤΑ ΔΙΑΔΡΟΜΕΣ — ΤΑΥΤΟΤΗΤΑ ΚΑΙ ΕΜΒΕΛΕΙΑ ΜΟΝΟ ──────────────────
 :lanes
 ((:lane "Φ1A-L1" :cluster "source/"
   :cluster-roots ("source")
   :roots-provenance "source.sexp:2 — :cluster \"source\"")
  (:lane "Φ1A-L2" :cluster "systems/"
   :cluster-roots ("systems")
   :roots-provenance "systems.sexp:2")
  (:lane "Φ1A-L3" :cluster "authority-v2/"
   :cluster-roots ("authority-v2")
   :roots-provenance "authority-v2.sexp:2")
  (:lane "Φ1A-L4" :cluster "deployment/ — κανονικές προδιαγραφές"
   :cluster-roots ("deployment/*.md" "deployment/*.sexp" "deployment/*.ttl"
                   "deployment/*.json" "deployment/*.jsonld"
                   "deployment/shapes" "deployment/verify"
                   "deployment/templates" "deployment/mcp")
   :roots-provenance "deployment-specs.sexp:2,6 — ΘΕΤΙΚΗ απαρίθμηση, ΟΧΙ αποκλεισμός")
  (:lane "Φ1A-L5" :cluster "deployment/ — κατάσταση & γνώση"
   :cluster-roots ("deployment/self" "deployment/self-study" "deployment/knowledge"
                   "deployment/data" "deployment/state" "deployment/collab"
                   "deployment/*.js" "deployment/*.sh")
   :roots-provenance "deployment-state.sexp:2")
  (:lane "Φ1A-L6" :cluster "tests/ + docker/ + scripts/"
   :cluster-roots ("tests" "docker" "scripts")
   :roots-provenance "harness.sexp:2")
  (:lane "Φ1A-L7" :cluster "ρίζα + configs + docs + .github + cloudflare + tools"
   :cluster-roots ("*" "configs" "docs" ".github" "cloudflare" "tools")
   :roots-provenance "contracts.sexp:6 — 43 root + configs(9) + docs(18) +
                      .github(3) + cloudflare(5) + tools(1) = 79"))

 :what-lives-elsewhere
 (:statuses "LANE-STATE-LEDGER.sexp — append-only, ΔΕΝ επιλύει παραπομπές"
  :gate-results "GATE-LEDGER.sexp"
  :l1-forensics "L1-ADMISSION-BOUNDARY.sexp"))
