;;;; experiment/artifacts/s14-closures.sexp — ΚΛΕΙΣΙΜΟ ΤΩΝ ΤΡΙΩΝ ΕΚΚΡΕΜΩΝ §14
;;;; Όλα μετρήθηκαν σε αυτή τη συνεδρία με ζωντανό daemon.

(:lawmax-s14-closures/1

 ;; ── §14.3: ΑΚΡΙΒΕΣ SUBSET MANIFEST ΤΟΥ SBCL 2.4.0 ─────────────────────────
 (:id 3 :status :ΕΚΛΕΙΣΕ
  :measurement "136/136 σουίτες exit≠0 στο lawmax-runner:rebuild-a (SBCL 2.4.0
                από πηγή), με ζωντανό daemon και φρέσκο overlay ανά σουίτα"
  :uniform-cause "ΚΑΙ ΤΑ 136 logs περιέχουν «Lock on package SB-C violated when
                  interning LAMBDA-PARENT while in package LOG4CL-IMPL»
                  — επαληθευμένο με grep -l σε όλα: 136/136, 0 με άλλη αιτία"
  :subset-precision "Η παλαιότερη παρατήρηση «104/104» ήταν ΜΕΡΙΚΗ (η εκτέλεση
                     διακόπηκε στο 104ο). Η πλήρης μέτρηση: 136/136 ομοιόμορφα.
                     Το προηγούμενο τρέξιμο με «Cannot connect to daemon» είχε
                     ήδη ΑΚΥΡΩΘΕΙ ρητά και δεν μετράει."
  :consequence "Το δηλωμένο ARG SBCL_VERSION=2.4.0 (Dockerfile:16) είναι
                ΚΑΘΟΛΙΚΑ ασύμβατο με το vendored log4cl-v1.1.2 — κανένα
                υποσύνολο σουιτών δεν περνά.")

 ;; ── §14.6: ΔΥΟ ΚΑΘΑΡΑ REBUILDS ΤΟΥ ΠΑΓΩΜΕΝΟΥ 2.2.9 ───────────────────────
 (:id 6 :status :ΕΚΛΕΙΣΕ
  :terminology "REPEATABILITY ΣΤΟ ΙΔΙΟ ΠΕΡΙΒΑΛΛΟΝ (ίδιος host/daemon) —
                ΟΧΙ ανεξάρτητη replication. Ορολογία κατά §14."
  :builds ((:label "frozen-a" :exit 0 :receipt "experiment/artifacts/rebuild-receipt-FROZEN-A.sexp")
           (:label "frozen-b" :exit 0 :receipt "experiment/artifacts/rebuild-receipt-FROZEN-B.sexp"))
  :identical (:build-context-tree "aab32b57195dccaa…"
              :config-digest "sha256:66d7b14fcf9cc706…"
              :sbcl-version "SBCL 2.2.9.debian (dpkg 2:2.2.9-1ubuntu2)"
              :package-inventory "226 πακέτα, sha256 a4778b73a9e6bdc1… ΚΑΙ ΣΤΑ ΔΥΟ"
              :full-content "ΠΛΗΡΗΣ ΕΞΑΓΩΓΗ ΚΑΙ ΤΩΝ ΔΥΟ ΕΙΚΟΝΩΝ: 12.251 αρχεία,
                             sha256 ΑΝΑ ΑΡΧΕΙΟ, ΜΗΔΕΝ διαφορές byte-προς-byte")
  :divergent (:oci-image-id ("727db0b7a46f346c…" "4b6a9ceb71145061…")
              :rootfs-layer-diffids "διαφέρουν από το 2ο layer και μετά"
              :named-cause "mtimes αρχείων ΜΕΣΑ στα layer tars: τα δύο builds
                            έτρεξαν ΔΙΑΔΟΧΙΚΑ (όχι ταυτόχρονα όπως το ζεύγος
                            2.4.0), άρα τα dpkg αρχεία φέρουν διαφορετικές
                            χρονοσφραγίδες. Το diffID σφραγίζει το tar ΜΑΖΙ με
                            τα mtimes.")
  :receipt-field-caveat "Τα πεδία runtime-package-* των ΔΥΟ receipts είναι
                         ΑΝΑΞΙΟΠΙΣΤΑ (quoting bug του rebuild-receipt.sh: το
                         \${Status} επεκτάθηκε στο κέλυφος του container).
                         Η παρούσα μέτρηση έγινε ΑΠΕΥΘΕΙΑΣ και υπερισχύει."
  :verdict "REPRODUCIBLE-RUNNER (frozen 2.2.9): NORMALIZED EQUIVALENCE PROVED —
            περιεχόμενο bit-ταυτόσημο· ταυτότητα εικόνας μη ντετερμινιστική,
            με ονομαστική αιτία.")

 ;; ── §14.8: FIVEAM ΑΝΑ TEST — ΕΚΚΡΕΜΕΙ ────────────────────────────────────
 (:id 8 :status :ΕΚΚΡΕΜΕΙ
  :note "Απαιτεί απαρίθμηση των FiveAM tests και εκτέλεση ΚΑΘΕ ΕΝΟΣ σε ξεχωριστή
         SBCL διεργασία. Προγραμματισμένο μετά τα dossiers των διαδρομών —
         δεν μπλοκάρει τη στατική αρχαιολογία."))
