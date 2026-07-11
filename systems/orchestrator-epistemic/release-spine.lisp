;;;; systems/orchestrator-epistemic/release-spine.lisp
;;;; ============================================================================
;;;; RELEASE SPINE VERIFICATION — η ΜΙΑ παραγωγική έδρα πλήρους επαλήθευσης
;;;; ενός δημοσιευμένου release ([P1.5-D] release-gate v2).
;;;; ============================================================================
;;;;
;;;; Επαληθεύει ό,τι και ο L6 πυρήνας (deployment/verify/kernel-verify.lisp),
;;;; αλλά μέσα από τις ΕΔΡΕΣ του συστήματος (orchestrator.merkle, jws-authority,
;;;; pad-article-id) — kernel diversity: δύο ανεξάρτητες υλοποιήσεις, ίδια
;;;; ετυμηγορία. Read-only. Κάθε αστοχία ονοματίζεται· ΠΟΤΕ σιωπηλό πράσινο.
;;;;
;;;; census-1 release (census.json παρόν):
;;;;   1. Census self-consistency: per-article ttl/jsonld/html sha512 ≡ τα
;;;;      in-release bytes· text_leaf ≡ RFC-6962 φύλλο του .txt·
;;;;      pcl_text_root ≡ MTH(text leaves).
;;;;   2. prev_release_root: κλειδί ΥΠΟΧΡΕΩΤΙΚΟ· null = τίμιο πρώτο της
;;;;      αλυσίδας· αλλιώς μορφή sha256:<64hex>.
;;;;   3. JWS detached RS256 πάνω στο RECOMPUTED root — απούσα υπογραφή =
;;;;      ΑΠΟΤΥΧΙΑ (F2: όχι «unsigned» downgrade). ΣΗΜ: consistency, όχι
;;;;      authenticity — το κλειδί είναι in-release· η αυθεντικότητα ζει στο
;;;;      out-of-band pinned root + owner TSR attestation (βλ. %spine-jws-check).
;;;;
;;;; Προ-census release (ιστορικό δεσμευμένο, 8 canonical): ΔΕΝ κρίνεται με
;;;; μεταγενέστερο σχήμα — ελέγχεται ΜΟΝΟ η JWS αν υπάρχει (ιστορική
;;;; σημασιολογία)· το root≡όνομα το φράζει ήδη η πύλη.
;;;; ============================================================================

(in-package :orchestrator.epistemic)

(defun %census-id->file-id (id)
  "Census id (article-uri-id, π.χ. «5Α»/«70») → canonical file-id («005Α»/«070»)
   ΜΕΣΩ της έδρας pad-article-id — όχι δεύτερη υλοποίηση pad."
  (let* ((pos (position-if-not #'digit-char-p id))
         (digits (if pos (subseq id 0 pos) id))
         (suffix (and pos (subseq id pos))))
    (orchestrator.model:pad-article-id (parse-integer digits) suffix)))

(defun %spine-jws-check (dir root fail-fn &key fail-closed)
  "JWS έλεγχος του release: detached RS256 πάνω στο ROOT μέσω της έδρας
   jws-authority (F1-σκληρυμένη: ενσωματωμένο payload ≠ αναμενόμενο ⇒ σφάλμα).
   FAIL-CLOSED: απόντα αρχεία υπογραφής = αποτυχία (census-1 σχήμα).

   ΤΙΜΙΑ ΕΜΒΕΛΕΙΑ (κλείσιμο κριτή P1.5-D#2): το public.jwk διαβάζεται ΜΕΣΑ
   από το ίδιο το release — άρα αυτός ο έλεγχος αποδεικνύει ΣΥΝΕΠΕΙΑ (όποιος
   συνάρμοσε το release υπέγραψε το recomputed root του), ΟΧΙ αυθεντικότητα.
   Η ΑΥΘΕΝΤΙΚΟΤΗΤΑ στηρίζεται σε out-of-band άγκυρα: το PINNED root που δίνει
   ο ελεγκτής (kernel-verify.lisp <dir> <pinned>) + το owner attestation
   (RFC-3161 TSR). Χωρίς pinned root/TSR, ένας κατασκευαστής μπορεί να φτιάξει
   αυτο-συνεπές release με δικό του κλειδί — γι' αυτό το latest απαιτεί
   attestation και η δημόσια ταυτότητα δηλώνεται out-of-band."
  (let ((jp (merge-pathnames "temporal-proof/signature.jws" dir))
        (kp (merge-pathnames "verify/public.jwk" dir)))
    (cond
      ((not (and (probe-file jp) (probe-file kp)))
       (when fail-closed
         (funcall fail-fn "signature.jws/public.jwk απόντα (signature stripping)")))
      ((null root)
       (funcall fail-fn "JWS: αδύνατη επαλήθευση χωρίς recomputed root"))
      (t (handler-case
             (let* ((jwk (jonathan:parse (uiop:read-file-string kp) :as :hash-table))
                    (pub (ironclad:make-public-key
                          :rsa
                          :n (ironclad:octets-to-integer
                              (orchestrator.jws-authority:base64url-decode (gethash "n" jwk)))
                          :e (ironclad:octets-to-integer
                              (orchestrator.jws-authority:base64url-decode (gethash "e" jwk))))))
               (orchestrator.jws-authority:verify-jws
                (string-trim '(#\Space #\Newline #\Return)
                             (uiop:read-file-string jp))
                root pub))
           (error (e) (funcall fail-fn "JWS ΑΚΥΡΗ πάνω στο recomputed root: ~A" e)))))))

(defun verify-release-spine (release-dir &key root)
  "Πλήρης spine επαλήθευση του RELEASE-DIR. ROOT: το recomputed release root
   («sha256:<hex>») — αν NIL υπολογίζεται εδώ από τα canonical bytes.
   Επιστρέφει (values ok failures) όπου FAILURES λίστα ονοματισμένων string."
  (let* ((dir (uiop:ensure-directory-pathname release-dir))
         (failures '())
         (root (or root (handler-case (%release-recomputed-root dir)
                          (error (e)
                            (push (format nil "recompute root: ~A" e) failures)
                            nil)))))
    (flet ((fail (fmt &rest args) (push (apply #'format nil fmt args) failures)))
      (let ((cpath (merge-pathnames "census.json" dir)))
        (if (not (probe-file cpath))
            ;; Προ-census ιστορικό σχήμα: μόνο JWS-αν-υπάρχει.
            (%spine-jws-check dir root #'fail :fail-closed nil)
            (progn
              ;; 1+2. Census self-consistency + αλυσίδα
              (handler-case
                  (let* ((c (jonathan:parse (uiop:read-file-string cpath) :as :hash-table))
                         (arts (gethash "articles" c))
                         (adir (merge-pathnames "articles/" dir))
                         (leaves '())
                         (bad 0))
                    (dolist (a arts)
                      (let* ((fid (%census-id->file-id (gethash "id" a)))
                             (tl (gethash "text_leaf" a)))
                        (push tl leaves)
                        (dolist (ext '("ttl" "jsonld" "html"))
                          (let ((p (merge-pathnames (format nil "article-~A.~A" fid ext) adir)))
                            (unless (and (probe-file p)
                                         (string= (%sha512-file-prefixed p) (gethash ext a)))
                              (incf bad))))
                        (let ((tp (merge-pathnames (format nil "article-~A.txt" fid) adir)))
                          (unless (and (probe-file tp)
                                       (string= (orchestrator.merkle:hash-leaf-file tp) tl))
                            (incf bad)))))
                    (when (plusp bad)
                      (fail "census: ~D per-article αναντιστοιχίες (ttl/jsonld/html/txt)" bad))
                    (unless (and arts
                                 (string= (orchestrator.merkle:merkle-tree-hash (nreverse leaves))
                                          (gethash "pcl_text_root" c)))
                      (fail "census: pcl_text_root ≠ MTH(text leaves)"))
                    (multiple-value-bind (prev presentp) (gethash "prev_release_root" c)
                      (cond ((not presentp) (fail "census: κλειδί prev_release_root απόν"))
                            ((null prev) nil) ; τίμιο πρώτο της αλυσίδας
                            ((not (and (stringp prev) (= 71 (length prev))
                                       (string= "sha256:" (subseq prev 0 7))
                                       (every (lambda (ch) (digit-char-p ch 16))
                                              (subseq prev 7))))
                             (fail "census: prev_release_root άκυρης μορφής: ~S" prev)))))
                (error (e) (fail "census: μη αναγνώσιμο: ~A" e)))
              ;; 3. JWS fail-closed (census-1 σχήμα)
              (%spine-jws-check dir root #'fail :fail-closed t)))))
    (values (null failures) (nreverse failures))))
