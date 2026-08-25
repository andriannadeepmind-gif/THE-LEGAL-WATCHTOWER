;;;; experiment/artifacts/architecture-family-census.sexp
;;;; ΑΠΟΓΡΑΦΗ ΑΡΧΙΤΕΚΤΟΝΙΚΩΝ ΟΙΚΟΓΕΝΕΙΩΝ — ΠΡΙΝ οριστεί οποιοδήποτε D.
;;;;
;;;; ΣΚΟΠΟΣ: να μην οριστεί το τυπικό πεδίο ταυτολογικά γύρω από ό,τι τυχαίνει
;;;; να σκεφτούν οι πράκτορες. Η απογραφή γίνεται ΑΝΕΞΑΡΤΗΤΑ και ΠΡΙΝ, ώστε
;;;; κάθε οικογένεια να έχει ρητή τύχη: χαρτογραφημένη ή αποκλεισμένη ΜΕ ΛΟΓΟ.
;;;; ΑΥΤΗ Η ΑΠΟΓΡΑΦΗ ΔΕΝ ΕΙΝΑΙ ΠΛΗΡΗΣ ΕΞ ΟΡΙΣΜΟΥ — είναι το ΚΑΤΩ ΦΡΑΓΜΑ που
;;;; οι omission challengers της Φάσης 3 οφείλουν να επιτεθούν.

(:lawmax-architecture-family-census/1
 :status :draft-pre-phase-1
 :completeness-claim :none
 :challenge-protocol "Κάθε omission challenger που προσθέτει οικογένεια ΑΚΥΡΩΝΕΙ κάθε coverage certificate που εκδόθηκε πριν."

 :families
 ((:id F01 :name "Ντετερμινιστικός μονολιθικός αγωγός + υπογεγραμμένες εκδόσεις"
   :exemplars ("η ΣΗΜΕΡΙΝΗ κατάσταση του corpus") :status :baseline
   :buys "απλότητα, μικρό TCB, πλήρης ντετερμινισμός" :costs "καμία εξωτερική μαρτυρία· ο εκδότης πρέπει να είναι έμπιστος")
  (:id F02 :name "Transparency log με ανεξάρτητους μάρτυρες (CT/Sigstore/C2SP)"
   :exemplars ("Certificate Transparency" "Sigstore Rekor" "Go checksum db") :status :partially-present
   :buys "μη-διαψευσιμότητα χωρίς εμπιστοσύνη στον εκδότη· ανίχνευση split-view" :costs "απαιτεί ΠΡΑΓΜΑΤΙΚΑ ανεξάρτητους μάρτυρες σε διαφορετικές δικαιοδοσίες")
  (:id F03 :name "Proof-carrying data / επαληθεύσιμος υπολογισμός (SNARK/STARK)"
   :exemplars ("Cairo" "RISC Zero" "Nova") :status :unmapped
   :buys "ο τρίτος επαληθεύει ΤΟΝ ΥΠΟΛΟΓΙΣΜΟ, όχι μόνο το αποτέλεσμα" :costs "τεράστιο TCB κρυπτογραφίας· κόστος απόδειξης· ώριμο για μικρά κυκλώματα, όχι για νομική ενοποίηση")
  (:id F04 :name "BFT replicated state machine"
   :exemplars ("Tendermint" "HotStuff" "PBFT") :status :unmapped
   :buys "ζωντάνια και συμφωνία υπό βυζαντινούς κόμβους" :costs "απαιτεί ΠΟΛΛΟΥΣ θεσμικούς φορείς — δεν υπάρχουν σήμερα (§4: δεν απαιτούνται κρατικοί φορείς)")
  (:id F05 :name "Αγκύρωση σε δημόσιο ledger"
   :exemplars ("Ethereum" "Bitcoin OTS" "Arweave") :status :partially-present
   :buys "χρονική αγκύρωση χωρίς έμπιστο τρίτο" :costs "εξωτερική διαθεσιμότητα/κόστος· δεν αποδεικνύει ορθότητα, μόνο ύπαρξη σε χρόνο")
  (:id F06 :name "Τυπικά επαληθευμένος πυρήνας + ανεπαλήθευτη περιφέρεια"
   :exemplars ("seL4" "CompCert" "Project Everest") :status :target-of-corpus
   :buys "ελάχιστο αποδεδειγμένο TCB" :costs "κόστος απόδειξης· ΕΔΩ: δεν υπάρχει επαληθευμένος CL μεταγλωττιστής")
  (:id F07 :name "Supply-chain certificates (TUF / in-toto)"
   :exemplars ("TUF v1.0.35" "in-toto attestations") :status :partially-present
   :buys "ρόλοι κλειδιών, rotation, revocation, rollback-freeze" :costs "τελετές κλειδιών· offline root· ανθρώπινη διαδικασία")
  (:id F08 :name "Capability-secure αντικειμενικό σύστημα"
   :exemplars ("E" "Joe-E" "seL4 caps" "OS uid/gid capabilities") :status :partially-present
   :buys "εξουσία ως αντικείμενο, όχι ως έλεγχος· ambient authority εξαλείφεται" :costs "απαιτεί καθολική τήρηση· διαρροή μιας capability σπάει το μοντέλο")
  (:id F09 :name "Information-flow typing"
   :exemplars ("Jif" "FlowCaml" "IFC monads") :status :unmapped
   :buys "εμπιστευτικότητα/ακεραιότητα αποδεδειγμένη στο σύστημα τύπων" :costs "δεν υπάρχει ώριμο IFC για Common Lisp")
  (:id F10 :name "CRDT / τελικά συνεπής κατανεμημένη γνώση"
   :exemplars ("Automerge" "Riak") :status :excluded
   :exclusion-reason "Συγκρούεται με H2 (ντετερμινισμός) και με τη θεσμική απαίτηση ΜΙΑΣ υπογεγραμμένης αλήθειας σε δεδομένη στιγμή.")
  (:id F11 :name "Bitemporal αμετάβλητο log ως θεμέλιο"
   :exemplars ("Datomic" "XTDB" "event log + as-of queries") :status :partially-present
   :buys "χρόνος συναλλαγής vs χρόνος ισχύος — κρίσιμο για δίκαιο" :costs "εξωτερική μηχανή = δεύτερη έδρα αλήθειας αν δεν οριοθετηθεί (H10)")
  (:id F12 :name "Λογικός προγραμματισμός / defeasible νομική λογική"
   :exemplars ("Prolog" "Datalog" "Defeasible Deontic Logic" "Catala") :status :partially-present
   :buys "υπαγωγή και αντιδικία ως ΥΠΟΛΟΓΙΣΜΟΣ με ίχνος" :costs "μοντελοποίηση κάθε κανόνα· ημιτελής κάλυψη ⇒ σιωπηλά κενά")
  (:id F13 :name "Περιγραφική λογική (OWL 2 DL) + SHACL"
   :exemplars ("το ΣΗΜΕΡΙΝΟ οντολογικό στρώμα") :status :present
   :buys "τυπική οντολογία, μεταβατική συμπερασματολογία, ELI/ECLI διαλειτουργικότητα" :costs "DL δεν εκφράζει defeasible κανόνες ούτε χρονική ισχύ επαρκώς")
  (:id F14 :name "Ο νόμος ΩΣ ΤΥΠΟΙ σε θεωρηματολόγο"
   :exemplars ("Isabelle/HOL νομικά μοντέλα" "Coq encodings" "Catala→Coq") :status :unmapped
   :buys "μηχανικά ελεγμένη συνέπεια νομικών κανόνων" :costs "τεράστιο κόστος κωδικοποίησης· ο νόμος αλλάζει· ασυμβατότητα με H10 αν ο πυρήνας φύγει από CL")
  (:id F15 :name "Νευροσυμβολικό με LLM ΕΚΤΟΣ εμπιστοσύνης"
   :exemplars ("το ΣΗΜΕΡΙΝΟ *advisor* — source/cognition.lisp:19-21") :status :present
   :buys "κατανόηση επιπέδου LLM με ντετερμινιστική, αποδεδειγμένη απάντηση" :costs "η υποδοχή πρέπει να παραμείνει ΑΠΟΛΥΤΩΣ εκτός trusted path (H3)")
  (:id F16 :name "Πολυπρακτορικό θεσμικό (κοινοβούλιο/διαλεκτική)"
   :exemplars ("Ω6 Parliament του corpus" "argumentation frameworks") :status :partially-present
   :buys "πολλές φωνές, μία υπογραφή· proof obligations αντί personas" :costs "κίνδυνος «ψηφοφορίας για την αλήθεια» — απαγορευμένο ρητά")
  (:id F17 :name "Μηδενικής γνώσης δημοσίευση"
   :exemplars ("zk-SNARK selective disclosure") :status :unmapped
   :buys "δημοσίευση με προστασία προσωπικών δεδομένων αποφάσεων" :costs "ώριμο μόνο για περιορισμένα κατηγορήματα")
  (:id F18 :name "Content-addressed αμετάβλητη αποθήκη"
   :exemplars ("Merkle DAG" "IPFS" "git object store") :status :present
   :buys "ταυτότητα = περιεχόμενο· εξαλείφει κλάση σιωπηλής μεταβολής" :costs "χρειάζεται πολιτική διατήρησης/ανάκτησης")
  (:id F19 :name "Event sourcing + CQRS"
   :exemplars ("classic ES") :status :partially-present
   :buys "πλήρης ιστορία, ανακατασκευάσιμη κατάσταση" :costs "ο διαχωρισμός read/write model γεννά δεύτερη έδρα αν δεν οριοθετηθεί")
  (:id F20 :name "Μακροχρόνια διατήρηση (ERS RFC 4998 / OAIS)"
   :exemplars ("evidence records" "algorithm agility") :status :spec-only
   :buys "η απόδειξη επιβιώνει της γήρανσης αλγορίθμων" :costs "αλυσίδα ανανέωσης· δεν αλλάζει την αρχική κανονική μορφή")
  (:id F21 :name "Επαληθευμένο crash-safe storage"
   :exemplars ("Perennial 2.0 / GoTxn" "FSCQ") :status :externally-blocked
   :buys "ατομικότητα/ανάκτηση ΑΠΟΔΕΔΕΙΓΜΕΝΑ, όχι δοκιμασμένα" :costs "Coq + πηγές μη προσβάσιμες σήμερα (δίκτυο)")
  (:id F22 :name "Αποδεδειγμένος κώδικας ΣΤΟ ΙΔΙΟ κείμενο με τον εκτελούμενο (ACL2 υποσύνολο CL)"
   :exemplars ("ACL2 books ως εκτελέσιμη Common Lisp") :status :candidate
   :buys "εξαφανίζει το χάσμα εξαγωγής spec→κώδικα ΓΙΑ ΤΟΝ ΠΥΡΗΝΑ, μένοντας εντός H10"
   :costs "ΥΠΟ ΔΙΕΡΕΥΝΗΣΗ: περιορισμοί σε CLOS/MOP, conditions/restarts, concurrency, persistence, επιδόσεις, επιφάνεια επέκτασης — ΔΕΝ έχει εγκριθεί ως έδρα"))

 :mapping-obligation
 "Κάθε οικογένεια πρέπει είτε να αντιστοιχηθεί σε όρους του G_today^v1 είτε να
  μπει στο exclusion ledger ΜΕ ΛΟΓΟ που αντέχει αντιπαλική επίθεση. Οικογένεια
  χωρίς τύχη = το πεδίο είναι FORMAL-DOMAIN-INCOMPLETE και ΚΑΝΕΝΑ theorem
  μεγιστότητας δεν εκδίδεται.")
