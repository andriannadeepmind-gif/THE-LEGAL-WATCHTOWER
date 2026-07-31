;;;; authority-v2/kernel/admission-model.sexp
;;;; ============================================================================
;;;; PURE STATE-TRANSITION MODEL + ΤΑ 9 ΘΕΩΡΗΜΑΤΑ (απαιτήσεις 2 & 4)
;;;; ============================================================================
;;;; Η ΚΑΘΑΡΗ συνάρτηση αποδοχής, ως ΠΡΟΔΙΑΓΡΑΦΗ — γλωσσικά ουδέτερη, ώστε να
;;;; μεταφερθεί αυτούσια σε F*/Coq όταν υπάρξει toolchain. ΔΕΝ υλοποιείται σε
;;;; Common Lisp: μια CL υλοποίηση θα ήταν δεύτερη έδρα που αργότερα θα
;;;; χρειαζόταν migration (ρητή απαγόρευση).
;;;;
;;;;   K(old_state, candidate, evidence, policy)
;;;;     -> Reject(reasons) | Accept(new_state, transition_certificate)
;;;;
;;;; ΚΛΕΙΣΤΟΤΗΤΑ: η K είναι ΟΛΙΚΗ (total) — για ΚΑΘΕ είσοδο δίνει Reject ή
;;;; Accept, ποτέ σφάλμα/εξαίρεση/αόριστη κατάσταση. Η ολότητα είναι η πρώτη
;;;; γραμμή άμυνας: δεν υπάρχει «τρίτη έξοδος» από την οποία να διαρρεύσει
;;;; authority.

(:lawmax-admission-model/1

 :assurance-status :under-construction
 :implementation-status :specification-only
 :implementation-language-target "F* (verified) — ΟΧΙ Common Lisp"

 ;; ── ΥΠΟΓΡΑΦΗ ──────────────────────────────────────────────────────────────
 :signature
 (:inputs ((:name old-state  :type "authority-state")
           (:name candidate  :type "candidate")
           (:name evidence   :type "evidence")
           (:name policy     :type "policy"))
  :output "Reject([+ rejection-reason]) | Accept(authority-state, transition-certificate)"
  :purity "ΚΑΜΙΑ I/O, κανένα ρολόι, καμία τυχαιότητα, καμία μεταβλητή κατάσταση.
           Ο χρόνος εισέρχεται ΜΟΝΟ ως δεδομένο (TSA genTime μέσα στο evidence)."
  :totality "ΟΛΙΚΗ — καμία εξαίρεση, κανένα undefined")

 ;; ── ΤΑ CONJUNCTS ΤΗΣ ΑΠΟΔΟΧΗΣ (ΟΛΑ πρέπει να ισχύουν) ────────────────────
 ;; Accept ⟺ ΚΑΘΕ conjunct αληθές. Ένα ψευδές ⇒ Reject ΜΕ ΟΛΟΥΣ τους λόγους
 ;; (όχι τον πρώτο — ο τρίτος μαθαίνει την πλήρη εικόνα).
 :conjuncts
 ((:id :authorization
   :statement "η υπογραφή του candidate επαληθεύεται έναντι ΕΝΕΡΓΟΥ ρόλου
               (release/root) του τρέχοντος TUF-class μητρώου, μη ανακληθέντος
               και μη ληγμένου")
  (:id :sequence-monotonic
   :statement "new.sequence = old.sequence + 1 — ΑΚΡΙΒΩΣ, χωρίς κενά")
  (:id :no-rollback
   :statement "το candidate ΔΕΝ είναι πρόγονος ήδη αποδεκτής κατάστασης· η
               ιστορία επεκτείνεται ΜΟΝΟ προς τα εμπρός")
  (:id :profile-continuity
   :statement "το profile του candidate είτε ΤΑΥΤΙΖΕΤΑΙ με το τρέχον, είτε είναι
               νόμιμος διάδοχος (δεσμεύει hash προκατόχου + υπογεγραμμένος
               κανόνας συνέχειας από owner root)")
  (:id :census-completeness
   :statement "το census καλύπτει ΚΑΘΕ artifact του candidate — κανένα αδήλωτο
               αρχείο, κανένα δηλωμένο-ανύπαρκτο")
  (:id :source-binding
   :statement "το source root δεσμεύει τα ΑΥΘΕΝΤΙΚΑ source bytes από τα οποία
               παράχθηκε το candidate")
  (:id :tsa-full-verification
   :statement "ΠΛΗΡΗΣ RFC-3161: exact nonce ταυτίζεται με το αιτηθέν, policy OID
               ταυτίζεται, signer identity ταυτίζεται με pinned, certificate path
               επαληθεύεται ως τη pinned άγκυρα, validity-at-genTime, EKU/KU/
               constraints, revocation evidence ΦΡΕΣΚΟ, algorithm policy τηρείται.
               ΜΟΝΟ :pinned — ΠΟΤΕ :unpinned.")
  (:id :log-consistency
   :statement "το νέο log entry επεκτείνει το προηγούμενο δέντρο (RFC 9162
               consistency) και το checkpoint είναι υπογεγραμμένο με μονοτονικό
               χρόνο")
  (:id :unique-latest
   :statement "μετά την αποδοχή υπάρχει ΑΚΡΙΒΩΣ ΕΝΑΣ latest, και είναι το
               candidate που μόλις έγινε δεκτό"))

 ;; ── ΤΑ 9 ΘΕΩΡΗΜΑΤΑ (η φέρουσα απόδειξη — γραμμή 2 του matrix) ────────────
 ;; ΚΑΘΕ ένα εμφανίζεται στο proof manifest ως PROVED/FAILED/BLOCKED-TOOLCHAIN.
 :theorems
 ((:id :T1-authorization
   :statement "∀ inputs. K(...) = Accept(_,_) ⇒ ο candidate φέρει έγκυρη υπογραφή
               ενεργού, μη ανακληθέντος ρόλου"
   :status :blocked-toolchain)
  (:id :T2-completeness
   :statement "∀ inputs. αν ΚΑΘΕ conjunct ισχύει ⇒ K(...) = Accept
               (καμία σιωπηλή απόρριψη έγκυρου candidate)"
   :status :blocked-toolchain)
  (:id :T3-no-rollback
   :statement "∀ inputs. K(...) = Accept(new,_) ⇒ new.sequence > old.sequence ∧
               το νέο log δέντρο ΕΠΕΚΤΕΙΝΕΙ το παλιό"
   :status :blocked-toolchain)
  (:id :T4-unique-latest
   :statement "∀ state προσβάσιμη από τη γένεση μέσω K. |latest(state)| = 1"
   :status :blocked-toolchain)
  (:id :T5-monotonic-sequence
   :statement "∀ ακολουθία αποδοχών. τα sequence είναι 0,1,2,… χωρίς κενά/επαναλήψεις"
   :status :blocked-toolchain)
  (:id :T6-deterministic-replay
   :statement "∀ inputs. η K είναι συνάρτηση: ίδιες είσοδοι ⇒ ίδια έξοδος,
               byte-for-byte ίδιο certificate"
   :status :blocked-toolchain)
  (:id :T7-rejection-without-state-change
   :statement "∀ inputs. K(...) = Reject(_) ⇒ καμία μεταβολή κατάστασης
               (state hash πριν = state hash μετά)"
   :status :blocked-toolchain)
  (:id :T8-profile-continuity
   :statement "∀ αποδοχή με νέο profile. το νέο profile δεσμεύει το hash του
               προκατόχου ΚΑΙ φέρει υπογραφή owner root"
   :status :blocked-toolchain)
  (:id :T9-certificate-soundness
   :statement "∀ inputs. K(...) = Accept(new,cert) ⇒ ο ανεξάρτητος checker
               δέχεται το cert, ΚΑΙ η αποδοχή του cert από τον checker
               ΣΥΝΕΠΑΓΕΤΑΙ ότι ΚΑΘΕ conjunct ίσχυε
               (soundness ΚΑΙ ΠΡΟΣ ΤΙΣ ΔΥΟ ΚΑΤΕΥΘΥΝΣΕΙΣ — αυτό κάνει το
                certificate γέφυρα μεταξύ proof stacks, όχι FFI boolean)"
   :status :blocked-toolchain))

 ;; ── ΤΙ ΔΕΝ ΑΠΟΔΕΙΚΝΥΟΥΝ ΤΑ ΠΑΡΑΠΑΝΩ (τίμια οριοθέτηση) ───────────────────
 :out-of-scope
 ("ότι η προδιαγραφή εκφράζει τη ΣΩΣΤΗ θεσμική πρόθεση (ανθρώπινη κρίση)"
  "ότι το SHA-256/Ed25519 είναι ασφαλή (εμπειρικές υποθέσεις)"
  "ότι ο δίσκος/kernel τηρεί τα συμβόλαιά του (βλ. residual TCB)"
  "ότι τα ΑΥΘΕΝΤΙΚΑ source bytes είναι όντως ο νόμος (θεσμικό, όχι μαθηματικό)"))
