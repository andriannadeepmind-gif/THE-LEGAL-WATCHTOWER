;;;; tests/kernel-conformance-test.lisp
;;;; ============================================================================
;;;; ANTI-DRIFT CONFORMANCE — L6 kernel RFC-6962 ≡ orchestrator.merkle (L7 seed)
;;;; ============================================================================
;;;;
;;;; Ο L6 πυρήνας (deployment/verify/kernel-verify.lisp) υλοποιεί ΑΝΕΞΑΡΤΗΤΑ την
;;;; RFC-6962 Merkle — αυτό ΕΙΝΑΙ ο σκοπός (kernel diversity, De Bruijn: ο
;;;; ελεγκτής δεν μοιράζεται κώδικα με το σύστημα παραγωγής). Το τίμημα της
;;;; διαφορετικότητας είναι το drift: αν αποκλίνει η μία υλοποίηση, τα δύο
;;;; μονοπάτια θα διαφωνούσαν σιωπηλά. Αυτό το test ΑΠΟΔΕΙΚΝΥΕΙ ότι, φύλλο-προς-
;;;; φύλλο και ρίζα-προς-ρίζα, η ανεξάρτητη υλοποίηση του πυρήνα συμφωνεί ΑΚΡΙΒΩΣ
;;;; με τη ΜΙΑ έδρα orchestrator.merkle σε ντετερμινιστικά διανύσματα (μεγέθη
;;;; bytes 0..N, πλήθη φύλλων 1..M — που ασκούν το unbalanced split).
;;;;
;;;; Φόρτωση του πυρήνα ΧΩΡΙΣ το entry-point του (που θα καλούσε sb-ext:exit):
;;;; διαβάζουμε form-προς-form (ώστε το (in-package :lawmax-kernel) να ισχύει για
;;;; τα επόμενα reads, όπως ο κανονικός loader) και παραλείπουμε ΜΟΝΟ το τελικό
;;;; top-level (let …*posix-argv*…). Οι top-level (require)/(asdf:load-system)
;;;; είναι idempotent. ΚΑΜΙΑ αντιγραφή του κώδικα του πυρήνα εδώ.
;;;; ============================================================================

(in-package :cl-user)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro ck (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

;;; --- Φόρτωση των ΚΑΘΑΡΩΝ ορισμών του πυρήνα (χωρίς entry-point) ---
(let ((kernel-path (orchestrator.paths:institution-dir
                    "deployment/verify/kernel-verify.lisp")))
  (unless (probe-file kernel-path)
    (format t "~%FAIL: δεν βρέθηκε ο πυρήνας ~A~%" kernel-path)
    (sb-ext:exit :code 1))
  (with-open-file (s kernel-path)
    (loop with *package* = (find-package :cl-user)
          for f = (read s nil :eof)
          until (eq f :eof)
          ;; Παράλειψε ΜΟΝΟ το top-level entry-point: (let (...) …*posix-argv*…)
          unless (and (consp f) (eq (car f) 'let)
                      (search "POSIX-ARGV" (format nil "~S" f)))
            do (handler-bind ((warning #'muffle-warning)) (eval f)))))

(let ((kpkg (find-package :lawmax-kernel)))
  (unless kpkg
    (format t "~%FAIL: το πακέτο :lawmax-kernel δεν ορίστηκε~%")
    (sb-ext:exit :code 1))

  (labels ((k (name) (symbol-function (find-symbol name kpkg)))
           (kbytes (fn b) (funcall (k fn) b)))
    (let ((k-leaf (k "HASH-LEAF-BYTES"))
          (k-node (k "HASH-NODE"))
          (k-mth  (k "MTH")))

      (format t "~%== Πρωτόγονα: leaf(0x00) & node(0x01) ==~%")
      ;; Ντετερμινιστικά byte-vectors μεγέθους 0..40 (και το κενό φύλλο).
      (dotimes (n 41)
        (let ((bytes (make-array n :element-type '(unsigned-byte 8))))
          (dotimes (i n) (setf (aref bytes i) (mod (* 37 (1+ i)) 256)))
          (ck (format nil "leaf ≡ έδρα (|bytes|=~D)" n)
              (string= (funcall k-leaf bytes)
                       (orchestrator.merkle:hash-leaf-bytes bytes)))))

      (format t "~%== node(l,r) ≡ έδρα ==~%")
      (let ((a (orchestrator.merkle:hash-leaf-string "α"))
            (b (orchestrator.merkle:hash-leaf-string "β")))
        (ck "node(a,b) ≡ έδρα"
            (string= (funcall k-node a b) (orchestrator.merkle:hash-node a b)))
        (ck "node(b,a) ≡ έδρα (μη-μεταθετικό, ίδιο και στα δύο)"
            (string= (funcall k-node b a) (orchestrator.merkle:hash-node b a)))
        (ck "node(a,b) ≠ node(b,a) (θέση μετράει, και στις δύο υλοποιήσεις)"
            (and (not (string= (funcall k-node a b) (funcall k-node b a)))
                 (not (string= (orchestrator.merkle:hash-node a b)
                               (orchestrator.merkle:hash-node b a))))))

      (format t "~%== MTH ≡ merkle-tree-hash (πλήθος φύλλων 1..24, split) ==~%")
      (loop for m from 1 to 24 do
        (let ((leaves (loop for i from 1 to m
                            collect (orchestrator.merkle:hash-leaf-string
                                     (format nil "leaf-~D" i)))))
          (ck (format nil "MTH ≡ έδρα (~D φύλλα)" m)
              (string= (funcall k-mth leaves)
                       (orchestrator.merkle:merkle-tree-hash leaves)))))

      ;; Το κρίσιμο σημείο διαφωνίας: CVE-2012-2459. Και οι ΔΥΟ πρέπει να
      ;; δίνουν ΔΙΑΦΟΡΕΤΙΚΗ ρίζα για [a,b,c] vs [a,b,c,c] — και μεταξύ τους ίδια.
      (format t "~%== CVE-2012-2459: kernel ≡ έδρα ΚΑΙ split (όχι duplicate-last) ==~%")
      (let* ((a (orchestrator.merkle:hash-leaf-string "a"))
             (b (orchestrator.merkle:hash-leaf-string "b"))
             (c (orchestrator.merkle:hash-leaf-string "c")))
        (ck "MTH([a,b,c]) kernel ≡ έδρα"
            (string= (funcall k-mth (list a b c))
                     (orchestrator.merkle:merkle-tree-hash (list a b c))))
        (ck "MTH([a,b,c,c]) kernel ≡ έδρα"
            (string= (funcall k-mth (list a b c c))
                     (orchestrator.merkle:merkle-tree-hash (list a b c c))))
        (ck "kernel: MTH([a,b,c]) ≠ MTH([a,b,c,c]) (ανθεκτικό στο CVE)"
            (not (string= (funcall k-mth (list a b c))
                          (funcall k-mth (list a b c c)))))))))

(format t "~%════════════════════════════════════════════~%")
(format t "kernel-conformance: ~D pass, ~D fail~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
