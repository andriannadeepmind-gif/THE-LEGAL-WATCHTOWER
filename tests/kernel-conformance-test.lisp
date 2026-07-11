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
                          (funcall k-mth (list a b c c))))))

      ;; %pad ≡ pad-article-id: το kernel ανασυνθέτει το file-id από το census
      ;; id (article-uri-id). Vectors: απλά, lettered (5Α/70Α/100Α), δίγραφα (5ΣΤ).
      (format t "~%== %pad ≡ pad-article-id (census id → file id) ==~%")
      (let ((k-pad (k "%PAD")))
        (dolist (v '((5 nil) (70 nil) (100 nil) (5 "Α") (70 "Α") (100 "Α")
                     (5 "ΣΤ") (12 "Β") (299 nil)))
          (destructuring-bind (num suffix) v
            (let* ((uri-id (orchestrator.model:article-uri-id num suffix))
                   (want (orchestrator.model:pad-article-id num suffix)))
              (ck (format nil "%pad(~S) = ~S ≡ έδρα" uri-id want)
                  (string= (funcall k-pad uri-id) want))))))

      ;; b64url: kernel bytes->b64url / b64url->bytes ≡ έδρα jws-authority
      (format t "~%== base64url kernel ≡ jws-authority ==~%")
      (let ((k-enc (k "BYTES->B64URL"))
            (k-dec (k "B64URL->BYTES")))
        (dotimes (n 12)
          (let ((bytes (make-array n :element-type '(unsigned-byte 8))))
            (dotimes (i n) (setf (aref bytes i) (mod (* 73 (1+ i)) 256)))
            (let ((seat (orchestrator.jws-authority:base64url-encode bytes)))
              (ck (format nil "b64url enc |~D| ≡ έδρα" n)
                  (string= (funcall k-enc bytes) seat))
              (ck (format nil "b64url dec |~D| round-trip" n)
                  (equalp (funcall k-dec seat) bytes))))))

      ;; EMSA/JWS: υπογραφή από την έδρα ⇒ ο kernel verify-jws την επαληθεύει
      ;; (ΚΑΙ απορρίπτει λάθος payload + attached-payload token — F1 lock).
      (format t "~%== JWS: έδρα υπογράφει ⇒ kernel επαληθεύει ==~%")
      (let* ((kp (orchestrator.jws-authority:generate-rsa-keypair :bits 2048))
             (priv (getf kp :private-key))
             (pub (getf kp :public-key))
             (payload "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
             (jws (getf (orchestrator.jws-authority:sign-jws
                         payload priv :algorithm :rs256 :detached t) :jws))
             (k-verify (k "VERIFY-JWS")))
        (ck "kernel verify-jws δέχεται υπογραφή της έδρας (detached RS256+EMSA)"
            (funcall k-verify jws payload pub))
        (ck "kernel verify-jws απορρίπτει ΛΑΘΟΣ payload"
            (not (funcall k-verify jws "sha256:0000000000000000000000000000000000000000000000000000000000000000" pub)))
        (ck "kernel verify-jws απορρίπτει attached-payload token (F1)"
            (let* ((dot1 (position #\. jws))
                   (dot2 (position #\. jws :start (1+ dot1)))
                   (attacker-payload
                     (funcall (k "BYTES->B64URL")
                              (babel:string-to-octets "attacker" :encoding :utf-8)))
                   (attached (concatenate 'string (subseq jws 0 (1+ dot1))
                                          attacker-payload (subseq jws dot2))))
              (not (funcall k-verify attached payload pub))))))))

(format t "~%════════════════════════════════════════════~%")
(format t "kernel-conformance: ~D pass, ~D fail~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
