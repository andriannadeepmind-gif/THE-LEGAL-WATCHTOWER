;;;; experiment/artifacts/frozen-runner-reproducibility.sexp
;;;; §8 EARLY CORRECTION: πλήρης ανάλυση αναπαραγωγιμότητας ΧΩΡΙΣ επανάχτισμα.
;;;; Τα metadata εξήχθησαν ΑΠΕΥΘΕΙΑΣ από τις δύο υπάρχουσες εικόνες (docker export).

(:lawmax-frozen-runner-reproducibility/1
 :images ("lawmax-runner:frozen-a" "lawmax-runner:frozen-b")
 :method "docker export ΚΑΙ ΤΩΝ ΔΥΟ σε tar· σύγκριση ανά μέλος του πλήρους tar
          (12.251 εγγραφές η καθεμία), ΟΧΙ επανάχτισμα"

 :dimensions-checked
 ((:dimension :filesystem-content
   :result :IDENTICAL
   :evidence "12.251 αρχεία, sha256 ανά αρχείο, 0 διαφορές (προηγούμενη μέτρηση)")
  (:dimension :file-types
   :result :IDENTICAL :evidence "0 διαφορές type (dir/file/sym/lnk/dev)")
  (:dimension :modes
   :result :IDENTICAL :evidence "0 διαφορές στο octal mode")
  (:dimension :uid-gid
   :result :IDENTICAL :evidence "0 διαφορές uid/gid")
  (:dimension :symlink-targets
   :result :IDENTICAL :evidence "0 διαφορές linkname (συμπεριλαμβάνεται στο tuple σύγκρισης)")
  (:dimension :xattrs-capabilities
   :result :IDENTICAL :evidence "0 διαφορές pax_headers/xattr σε 12.251 μέλη")
  (:dimension :mtimes
   :result :DIVERGENT
   :evidence "1.963 / 12.251 κοινά μέλη με διαφορετικό mtime"
   :distribution "usr 1471 · etc 272 · var 159 · work 49 · root 5 · dev 4 · runner 2 · .dockerenv 1"
   :named-cause "Τα δύο builds έτρεξαν ΔΙΑΔΟΧΙΚΑ (frozen-a, μετά frozen-b), όχι
                 ταυτόχρονα. Τα αρχεία που έγραψε το dpkg/apt φέρουν wall-clock
                 mtime τη στιγμή της εγγραφής. ΔΕΝ ΕΓΙΝΕ ΚΑΝΟΝΙΚΟΠΟΙΗΣΗ mtime
                 (καμία SOURCE_DATE_EPOCH-based normalization στο runner
                 Dockerfile) — δηλωμένο υπόλειμμα, όχι κρυφό."))

 :verdict
 (:filesystem-content-repeatability :PROVED
  :full-image-reproducibility :NOT-PROVED
  :single-remaining-gap :mtimes
  :statement "Επτά διαστάσεις (περιεχόμενο, τύποι, modes, uid/gid, symlinks,
              xattrs) ΤΑΥΤΟΣΗΜΕΣ. Η ΜΟΝΗ απόκλιση είναι τα mtimes, με
              ονομαστική αιτία και χωρίς κανονικοποίηση. Πλήρης bit-for-bit
              image reproducibility ΔΕΝ διεκδικείται. Η repeatability
              περιεχομένου στο ίδιο περιβάλλον ΝΑΙ.")

 :superseded-receipts
 (:files ("experiment/artifacts/rebuild-receipt-FROZEN-A.sexp"
          "experiment/artifacts/rebuild-receipt-FROZEN-B.sexp"
          "experiment/artifacts/rebuild-receipt-A.sexp"
          "experiment/artifacts/rebuild-receipt-B.sexp")
  :reason "Τα πεδία :runtime-package-count / :runtime-package-inventory-sha256 /
           :apt-sbcl-in-runtime έχουν quoting bug (${Status} επεκτάθηκε στο
           κέλυφος του container). SUPERSEDED από την ΑΠΕΥΘΕΙΑΣ μέτρηση εδώ και
           στο s14-closures.sexp. Τα υπόλοιπα πεδία (hashes εικόνας/config/
           context) παραμένουν έγκυρα."))
