;;;; experiment/PROTOCOL-EPOCH-2.sexp
;;;; ΔΕΥΤΕΡΗ ΕΠΟΧΗ ΠΡΩΤΟΚΟΛΛΟΥ — ΥΠΕΡΚΕΡΑΣΗ, ΟΧΙ ΑΛΛΟΙΩΣΗ
;;;;
;;;; Το PROTOCOL.sexp της πρώτης εποχής ΔΕΝ τροποποιήθηκε. Δήλωνε 35.634
;;;; αρχεία και content-only Merkle root. Και τα δύο ήταν ΕΛΛΙΠΗ, όχι ψευδή:
;;;; τα bytes του corpus ΔΕΝ ΑΛΛΑΞΑΝ — διορθώθηκε η ΠΕΡΙΓΡΑΦΗ της ταυτότητάς
;;;; τους. Σιωπηλή επιτόπια διόρθωση θα κατέστρεφε τη δυνατότητα τρίτου να
;;;; ελέγξει υπό ποιο πρωτόκολλο εκδόθηκε κάθε παλιά απόδειξη.

(:lawmax-protocol/2
 :epoch 2
 :supersedes "experiment/PROTOCOL.sexp"
 :supersedes-sha256 "33a8f59108a757da70deb5875c3eab65b083a3ff90e0fbd1763c57d94f68bd22"
 :supersession-reason
  "Η πρώτη εποχή απαριθμούσε το corpus με os.walk, που ΕΞΑΦΑΝΙΖΕΙ
   symlink-προς-κατάλογο. Έλειπαν 6 εγγραφές. Η ταυτότητα ήταν content-only:
   δεν δέσμευε διαδρομές, modes ή kinds."

 ;; ── ΤΟ ΠΑΓΩΜΕΝΟ ΔΕΝΤΡΟ ──────────────────────────────────────────────
 :frozen-commit "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
 :frozen-tree-sha1 "23b7a6f4450f50d151d38e13020bee9872e73bcd"
 :never-uses-head "Καμία εντολή του πρωτοκόλλου δεν αναφέρεται σε HEAD."
 :git-leaves 35640
 :by-kind (:file 35559 :executable 75 :symlink 6)
 :enumeration-authority :GIT-TREE
 :enumeration-command "git ls-tree -r -z --full-tree e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"

 ;; ── ΤΑΥΤΟΤΗΤΑ ──────────────────────────────────────────────────────
 :corpus-identity
 (:kind :PATH-AND-KIND-COMPLETE
  :manifest-schema 3
  :root "sha256:3127f4941b899afcbffcd405b00d9e613fe4732301ba8ed990d22a0685514019"
  :binds ("commit sha1" "tree sha1" "κάθε διαδρομή" "git mode" "kind"
          "content sha256" "μέγεθος")
  :leaf "SHA256(0x00 ‖ u32be(len path)‖path ‖ u32be(len mode)‖mode ‖
         u32be(len kind)‖kind ‖ content_sha256 ‖ u64be(bytes))"
  :node "SHA256(0x01 ‖ L ‖ R)"
  :split "ΑΥΣΤΗΡΗ δύναμη του 2 (RFC 6962/9162 §2.1.1)· ΠΟΤΕ duplicate-last")

 :legacy-identity
 (:kind :CONTENT-ONLY-ORDER-ROOT
  :root "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b"
  :covered-leaves 35634
  :status :LEGACY
  :must-not-be-called "ταυτότητα corpus"
  :corpus-bytes-unchanged t
  :clarification
   "ΤΑ BYTES ΤΟΥ CORPUS ΔΕΝ ΑΛΛΑΞΑΝ ΜΕΤΑΞΥ ΤΩΝ ΔΥΟ ΕΠΟΧΩΝ. Η παλιά ρίζα
    παραμένει ορθή ως προς ό,τι κάλυπτε: τα περιεχόμενα 35.634 αρχείων σε
    δηλωμένη σειρά. Δεν κάλυπτε τα 6 symlinks και δεν δέσμευε διαδρομές/modes.")

 ;; ── ΚΑΝΟΝΙΣΤΙΚΗ ΜΟΡΦΗ ΠΑΡΑΠΟΜΠΗΣ ───────────────────────────────────
 :citation-format "path:L<start>-L<end>@sha256:<12 πεζά δεκαεξαδικά>"
 :citation-rules
 ("ΑΠΑΙΤΟΥΝΤΑΙ start ΚΑΙ end. Μονή γραμμή γράφεται L<n>-L<n>."
  "ΑΠΑΙΤΟΥΝΤΑΙ ΑΚΡΙΒΩΣ 12 πεζά δεκαεξαδικά. ΟΧΙ 6-64. ΟΧΙ παράλειψη."
  "Ο validator κάνει FULLMATCH ΟΛΟΚΛΗΡΟΥ του token. Δεν γίνεται ΠΟΤΕ δεκτό
   έγκυρο ΠΡΟΘΕΜΑ κακοσχηματισμένου token."
  "ΤΕΡΜΑΤΙΚΟΣ ΦΡΑΓΜΟΣ: trailing garbage ΑΠΟΡΡΙΠΤΕΙ ΟΛΟΚΛΗΡΟ το token."
  "ΛΙΣΤΕΣ ΚΟΜΜΑΤΟΣ ΑΠΑΓΟΡΕΥΟΝΤΑΙ. Κάθε αναφορά γραμμής είναι ΧΩΡΙΣΤΗ
   παραπομπή. ΑΙΤΙΑ: στην πρώτη εποχή ο σαρωτής έβλεπε ΜΟΝΟ το πρώτο
   στοιχείο μιας λίστας — 506 αναφορές γραμμών ήταν ΑΟΡΑΤΕΣ στην πύλη."
  "Legacy μορφές ΑΝΙΧΝΕΥΟΝΤΑΙ και ΟΝΟΜΑΖΟΝΤΑΙ, αλλά ΔΕΝ γίνονται δεκτές.")
 :two-and-only-two-bases
 ((:id :mount-anchored  :shape "/frozen/ro/<path>:L…")
  (:id :corpus-relative :shape "<path>:L…"))

 ;; ── ΤΙ ΑΠΟΔΕΙΚΝΥΕΙ Η ΠΥΛΗ — ΚΑΙ ΤΙ ΟΧΙ ─────────────────────────────
 :gate-verdict :RECOGNIZED-CITATION-INTEGRITY
 :verdict-means
  "Κάθε token παραπομπής ΠΟΥ ΑΝΑΓΝΩΡΙΣΤΗΚΕ αντιστοιχεί σε πραγματικά bytes
   και πραγματικό εύρος του παγωμένου δέντρου, επαληθευμένα με
   descriptor-anchored ανάγνωση."
 :verdict-does-not-mean
 ("ΔΕΝ αποδεικνύει ότι κάθε claim ΕΧΕΙ παραπομπή"
  "ΔΕΝ αποδεικνύει ότι το cited span ΣΤΗΡΙΖΕΙ τον ισχυρισμό"
  "ΔΕΝ είναι read-ledger")
 :separately-open
 ((:id :CLAIM-CITATION-COVERAGE :status :OPEN
   :requires "μητρώο claim-id → citation IDs, ΤΟΥΛΑΧΙΣΤΟΝ μία έγκυρη
              παραπομπή ανά claim block"
   :gate-on-phase-seal t)
  (:id :CLAIM-ENTAILMENT :status :OPEN
   :requires "απόδειξη ότι το cited span ΣΤΗΡΙΖΕΙ τον ισχυρισμό"
   :gate-on-phase-seal t)
  (:id :READ-LEDGER :status :OPEN)
  (:id :MACRO-LAYER :status :OPEN))
 :forbidden-phrasing
  "ΑΠΑΓΟΡΕΥΕΤΑΙ η φράση «citation gates passed» με την ευρύτερη έννοια πριν
   υπάρξει το μητρώο CLAIM-CITATION-COVERAGE."

 :single-shot-runner "experiment/runner/run-citation-gates-v5.sh"
 :scope-authority "experiment/phase1a/LANE-SCOPE-AUTHORITY.sexp")
