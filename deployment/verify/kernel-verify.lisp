;;;; kernel-verify.lisp — LAWMAX L6 VERIFICATION KERNEL (verify-kit v2)
;;;; ============================================================================
;;;; Ο ΑΝΕΞΑΡΤΗΤΟΣ, ΜΙΚΡΟΣ ελεγκτής ενός content-addressed release. Τρέχει με
;;;; ΜΟΝΟ ironclad + babel + cl-base64 + yason — ΚΑΜΙΑ εξάρτηση από το σύστημα
;;;; παραγωγής. Ένας τρίτος τον διαβάζει σε ένα απόγευμα και τον τρέχει:
;;;;
;;;;   sbcl --script kernel-verify.lisp <release-dir> [pinned-root-hex]
;;;;
;;;; Επαληθεύει, ΧΩΡΙΣ να εμπιστεύεται κανέναν — μόνο μαθηματικά + το ΦΕΚ-δέσιμο:
;;;;   1. Release root ≡ όνομα καταλόγου: RFC-6962 MTH των 10 canonical αρχείων
;;;;      (συμπεριλαμβανομένου ΑΥΤΟΥ του αρχείου — ο verifier μέσα στην ταυτότητα).
;;;;   2. Census self-consistency: pcl_text_root ≡ MTH των text-leaves· κάθε
;;;;      per-article ttl/jsonld/html sha512 ≡ το πραγματικό αρχείο του release·
;;;;      κάθε text_leaf ≡ hash-leaf του article-*.txt (self-contained release).
;;;;   3. JWS υπογραφή του RELEASE ROOT (detached RS256, ΠΛΗΡΕΣ EMSA padding)·
;;;;      απούσα υπογραφή = ΑΠΟΤΥΧΙΑ (όχι «unsigned» downgrade).
;;;;   4. prev_release_root παρόν (αλυσίδα anti-equivocation).
;;;;   5. (προαιρετικά) release root ≡ out-of-band PINNED-ROOT.
;;;;
;;;; RFC-3161 χρονική επαλήθευση = δηλωμένη φάση P4 (εδώ ελέγχεται ΥΠΑΡΞΗ).
;;;; Είναι ΑΝΕΞΑΡΤΗΤΗ υλοποίηση της RFC-6962 Merkle (kernel diversity, L7): η
;;;; conformance test αποδεικνύει ισοδυναμία με την έδρα orchestrator.merkle.
;;;; ============================================================================

(require :asdf)
(handler-case
    (progn (asdf:load-system :ironclad) (asdf:load-system :babel)
           (asdf:load-system :cl-base64) (asdf:load-system :yason))
  (error (e)
    (format t "ERROR: λείπουν εξαρτήσεις (ironclad babel cl-base64 yason): ~A~%" e)
    (sb-ext:exit :code 2)))

(defpackage :lawmax-kernel (:use :cl))
(in-package :lawmax-kernel)

;;; --- RFC 6962 (ανεξάρτητη υλοποίηση· conformance-tested έναντι της έδρας) ---
(defun sha256-hex (bytes)
  (format nil "sha256:~(~{~2,'0x~}~)"
          (coerce (ironclad:digest-sequence :sha256 bytes) 'list)))
(defun hash-leaf-bytes (bytes)
  (sha256-hex (concatenate '(vector (unsigned-byte 8)) #(#x00) bytes)))
(defun hash-node (l r)
  (sha256-hex (concatenate '(vector (unsigned-byte 8)) #(#x01)
                           (ironclad:hex-string-to-byte-array (subseq l 7))
                           (ironclad:hex-string-to-byte-array (subseq r 7)))))
(defun largest-pow2-below (n) (let ((k 1)) (loop while (< (* k 2) n) do (setf k (* k 2))) k))
(defun mth (leaves)
  (let ((v (coerce leaves 'vector)))
    (labels ((m (lo hi) (let ((n (- hi lo)))
                          (if (= n 1) (aref v lo)
                              (let ((k (largest-pow2-below n)))
                                (hash-node (m lo (+ lo k)) (m (+ lo k) hi)))))))
      (m 0 (length v)))))

(defun read-bytes (path)
  (with-open-file (s path :element-type '(unsigned-byte 8))
    (let ((b (make-array (file-length s) :element-type '(unsigned-byte 8))))
      (read-sequence b s) b)))
(defun read-str (path)
  ;; file-length = bytes, όχι chars: με UTF-8 πολυβυτικά (ελληνικά ids) το
  ;; buffer περισσεύει — κόβεται στο ΠΡΑΓΜΑΤΙΚΟ πλήθος chars που διαβάστηκαν.
  (with-open-file (s path :external-format :utf-8)
    (let ((str (make-string (file-length s))))
      (subseq str 0 (read-sequence str s)))))
(defun sha512-hex (path)
  (format nil "sha512:~(~{~2,'0x~}~)"
          (coerce (ironclad:digest-sequence :sha512 (read-bytes path)) 'list)))

(defparameter +canonical+
  '("census.json" "lineage-graph.ttl" "meta-ontology.ttl" "negation.ttl"
    "shapes/article-shape.ttl" "shapes/lineage-shape.ttl" "shapes/manifest-shape.ttl"
    "stability-policy.md" "stability-policy.ttl" "verify/verify.lisp")
  "Τα 10 canonical αρχεία, ΤΑΞΙΝΟΜΗΜΕΝΑ (string<) — η ΙΔΙΑ διάταξη με την έδρα.
   Το verify/verify.lisp είναι ΑΥΤΟΣ ο πυρήνας (διανέμεται μέσα στο release):
   η ταυτότητα δεσμεύει και τον verifier — καμία κυκλικότητα, hashάρονται τα
   bytes του αρχείου, όχι το αποτέλεσμά του.")

;;; --- JWS RS256 (πλήρες EMSA-PKCS1-v1_5, ΟΧΙ raw) ---
(defun b64url->bytes (s)
  (let* ((pad (make-string (mod (- 4 (mod (length s) 4)) 4) :initial-element #\=))
         (std (map 'string (lambda (c) (case c (#\- #\+) (#\_ #\/) (t c)))
                   (concatenate 'string s pad))))
    (cl-base64:base64-string-to-usb8-array std)))
(defun bytes->b64url (bytes)
  (string-right-trim "=." (cl-base64:usb8-array-to-base64-string bytes :uri t)))
(defparameter +sha256-digestinfo+
  #(#x30 #x31 #x30 #x0d #x06 #x09 #x60 #x86 #x48 #x01 #x65 #x03 #x04 #x02 #x01 #x05 #x00 #x04 #x20))
(defun emsa (msg k)
  (let* ((d (ironclad:digest-sequence :sha256 msg))
         (tt (concatenate '(vector (unsigned-byte 8)) +sha256-digestinfo+ d))
         (ps (- k 3 (length tt))))
    (when (< ps 8) (error "modulus too small"))
    (concatenate '(vector (unsigned-byte 8)) #(#x00 #x01)
                 (make-array ps :element-type '(unsigned-byte 8) :initial-element #xFF)
                 #(#x00) tt)))
(defun verify-jws (jws payload-string pub)
  "Επαλήθευση JWS RS256. Detached (RFC 7797): το payload ΔΕΝ είναι στο token —
   είναι ΠΑΝΤΑ το PAYLOAD-STRING (εδώ: το release root που υπέγραψε ο εκδότης).
   Token με ΜΗ-ΚΕΝΟ payload segment ΑΠΟΡΡΙΠΤΕΤΑΙ: αλλιώς ένας επιτιθέμενος θα
   έβαζε δικό του (έγκυρα υπογεγραμμένο αλλού) payload και η υπογραφή δεν θα
   δενόταν ποτέ στο root αυτού του release."
  (let* ((p (loop for a = 0 then (1+ b) for b = (position #\. jws :start a)
                  collect (subseq jws a (or b (length jws))) while b))
         (payload-b64 (if (plusp (length (second p)))
                          (return-from verify-jws nil) ; attached-payload token: ΑΚΥΡΟ εδώ
                          (bytes->b64url (babel:string-to-octets payload-string :encoding :utf-8))))
         (si (format nil "~A.~A" (first p) payload-b64))
         (k (ceiling (integer-length (ironclad:rsa-key-modulus pub)) 8))
         (em (emsa (babel:string-to-octets si :encoding :utf-8) k)))
    (handler-case (ironclad:verify-signature pub em (b64url->bytes (third p)))
      (error () nil))))

;;; --- κύρια επαλήθευση ---
(defun fail (fmt &rest a) (format t "  ✗ ~A~%" (apply #'format nil fmt a)) nil)
(defun ok (fmt &rest a) (format t "  ✓ ~A~%" (apply #'format nil fmt a)) t)

(defun verify-release (dir &optional pinned)
  (let* ((dir (uiop:ensure-directory-pathname dir))
         (leaf (car (last (pathname-directory dir))))
         (errors 0)
         (root nil))                     ; το release root (payload της υπογραφής)
    (flet ((chk (v) (unless v (incf errors))))
      (format t "~%═══ LAWMAX L6 KERNEL — VERIFY ~A ═══~%" leaf)

      ;; 1. release root ≡ όνομα καταλόγου
      (format t "[1] Release root (RFC-6962, 10 canonical)...~%")
      (let* ((paths (mapcar (lambda (r) (merge-pathnames r dir)) +canonical+))
             (missing (remove-if #'probe-file paths)))
        (if missing (chk (fail "λείπουν canonical: ~{~A ~}" (mapcar #'file-namestring missing)))
            (let* ((leaves (mapcar (lambda (p) (hash-leaf-bytes (read-bytes p))) paths))
                   (id (progn (setf root (mth leaves)) (format nil "sha256-~A" (subseq root 7)))))
              (chk (if (string= id leaf) (ok "root ≡ όνομα: ~A" id)
                       (fail "root ~A ≠ όνομα ~A" id leaf)))
              (when pinned
                (chk (if (string= (subseq root 7) (string-downcase pinned))
                         (ok "root ≡ out-of-band pinned")
                         (fail "root ≠ pinned ~A" pinned)))))))

      ;; 2. census self-consistency
      (format t "[2] Census (per-article membership + text-spine)...~%")
      (let ((cpath (merge-pathnames "census.json" dir)))
        (if (not (probe-file cpath)) (chk (fail "census.json απών"))
            (let* ((c (yason:parse (read-str cpath)))
                   (arts (gethash "articles" c))
                   (adir (merge-pathnames "articles/" dir))
                   (bad 0))
              ;; Αλυσίδα anti-equivocation: το ΚΛΕΙΔΙ πρέπει να υπάρχει στο census.
              ;; Τιμή null = ΤΙΜΙΟ πρώτο release της αλυσίδας (όχι αποτυχία)·
              ;; τιμή sha256:<64hex> = δείκτης στο προηγούμενο attested latest.
              (multiple-value-bind (prev presentp) (gethash "prev_release_root" c)
                (chk (cond ((not presentp) (fail "κλειδί prev_release_root απών από το census"))
                           ((null prev) (ok "prev_release_root: null (πρώτο της αλυσίδας)"))
                           ((and (stringp prev) (= 71 (length prev))
                                 (string= "sha256:" (subseq prev 0 7)))
                            (ok "prev_release_root παρόν (αλυσίδα): ~A…" (subseq prev 0 19)))
                           (t (fail "prev_release_root άκυρης μορφής: ~S" prev)))))
              (let ((leaves '()))
                (dolist (a arts)
                  (let* ((id (gethash "id" a))
                         (fid (%pad id))
                         (tl (gethash "text_leaf" a)))
                    (push tl leaves)
                    (flet ((cmp (ext key)
                             (let ((p (merge-pathnames (format nil "article-~A.~A" fid ext) adir)))
                               (unless (and (probe-file p) (string= (sha512-hex p) (gethash key a)))
                                 (incf bad)))))
                      (cmp "ttl" "ttl") (cmp "jsonld" "jsonld") (cmp "html" "html"))
                    (let ((tp (merge-pathnames (format nil "article-~A.txt" fid) adir)))
                      (unless (and (probe-file tp) (string= (hash-leaf-bytes (read-bytes tp)) tl))
                        (incf bad)))))
                (chk (if (zerop bad) (ok "~D άρθρα: κάθε ttl/jsonld/html/txt ≡ census" (length arts))
                         (fail "~D per-article αναντιστοιχίες" bad)))
                (chk (if (string= (mth (nreverse leaves)) (gethash "pcl_text_root" c))
                         (ok "pcl_text_root ≡ MTH(text leaves)")
                         (fail "pcl_text_root αναντιστοιχία")))))))

      ;; 3. JWS
      (format t "[3] JWS υπογραφή (RS256, πλήρες padding)...~%")
      (let ((jp (merge-pathnames "temporal-proof/signature.jws" dir))
            (kp (merge-pathnames "verify/public.jwk" dir)))
        (if (not (and (probe-file jp) (probe-file kp)))
            ;; FAIL-CLOSED: το σβήσιμο της υπογραφής ΔΕΝ είναι downgrade σε
            ;; «unsigned» — είναι αποτυχία. Κάθε release αυτού του σχήματος
            ;; εκδίδεται υπογεγραμμένο· απουσία = παραποίηση ή ακρωτηριασμός.
            (chk (fail "signature.jws/public.jwk απόντα (signature stripping)"))
            (let* ((jwk (yason:parse (read-str kp)))
                   (pub (ironclad:make-public-key :rsa
                          :n (ironclad:octets-to-integer (b64url->bytes (gethash "n" jwk)))
                          :e (ironclad:octets-to-integer (b64url->bytes (gethash "e" jwk))))))
              ;; Το υπογεγραμμένο payload είναι το RELEASE ROOT (detached JWS),
              ;; όχι το manifest — ο εκδότης υπογράφει την ταυτότητα του release.
              (chk (if (and root (verify-jws (string-trim '(#\Space #\Newline #\Return) (read-str jp))
                                             root pub))
                       (ok "JWS έγκυρη (payload = release root)") (fail "JWS ΑΚΥΡΗ"))))))

      ;; 4. RFC-3161 (ύπαρξη· πλήρης crypto = P4)
      (format t "[4] RFC-3161 receipt (ύπαρξη· crypto-verify = P4)...~%")
      (if (probe-file (merge-pathnames "temporal-proof/timestamp.tsr" dir))
          (ok "timestamp.tsr παρόν (attested)")
          (format t "  ⚠ timestamp.tsr απών (unattested commitment)~%"))

      (format t "═══ ~A ═══~%" (if (zerop errors) "✓ ΕΠΑΛΗΘΕΥΣΗ ΠΕΡΑΣΕ" (format nil "✗ ΑΠΕΤΥΧΕ (~D)" errors)))
      (zerop errors))))

(defun %pad (id)
  "Canonical file-id από το census id (π.χ. «5Α»→«005Α», «70»→«070»): 3-ψήφια
   ζώνη βάσης + τυχόν γράμμα (ΙΔΙΑ λογική με article-file-id/pad-article-id)."
  (let* ((pos (position-if-not #'digit-char-p id))
         (digits (if pos (subseq id 0 pos) id))
         (suffix (if pos (subseq id pos) "")))
    (format nil "~3,'0D~A" (parse-integer digits) suffix)))

(let ((args (rest sb-ext:*posix-argv*)))
  (if (null args)
      (progn (format t "χρήση: kernel-verify.lisp <release-dir> [pinned-root-hex]~%")
             (sb-ext:exit :code 2))
      (sb-ext:exit :code (if (verify-release (first args) (second args)) 0 1))))
