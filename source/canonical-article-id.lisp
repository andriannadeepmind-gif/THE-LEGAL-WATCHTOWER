;;;; source/canonical-article-id.lisp
;;;; ============================================================================
;;;; ΚΑΝΟΝΙΚΗ ΤΑΥΤΟΤΗΤΑ ΑΡΘΡΟΥ — first-class typed object, όχι ωμός αριθμός
;;;; ============================================================================
;;;;
;;;; Το χρέος που ανέδειξε το συμβόλαιο article-identity-management, ως ΤΥΠΟΣ:
;;;; το «100» και το «100Α» είναι ΔΙΑΦΟΡΕΤΙΚΑ άρθρα· η ετικέτα εμφάνισης ΔΕΝ
;;;; είναι η ταυτότητα· ο ωμός αριθμός ΔΕΝ είναι κλειδί corpus. Εδώ ζει το
;;;; typed αντικείμενο με αυστηρή σημασιολογία ισότητας/hash/σειριοποίησης.
;;;;
;;;; ΣΧΕΔΙΟ ΜΕΤΑΒΑΣΗΣ (δηλωμένο, με τεστ στην πύλη --component-gate):
;;;;   Φάση 1 (ΑΥΤΟ το κύμα): ο τύπος + parsing + ισότητα/hash/σειριοποίηση +
;;;;     εκτελέσιμα τεστ. Η γένεση URI καταναλώνει την ΚΑΝΟΝΙΚΗ σειριοποίηση.
;;;;   Φάση 2 (χρέος, ορατό στον καθρέφτη): το corpus keying καταναλώνει
;;;;     canonical-article-id αντί ωμού αριθμού — αλλαγή υπό το συμβόλαιο
;;;;     (ανθρώπινη-έγκριση + impact report + regression πύλες).
;;;;   Φάση 3 (χρέος): RDF subjects / ELI / citation resolver πάνω στον τύπο.
;;;; Καμία σιωπηλή μετάβαση: κάθε φάση περνά από το adoption μονοπάτι.

(defpackage :orchestrator.article-id
  (:use :cl)
  (:export #:canonical-article-id #:parse-article-id #:article-id-p
           #:article-id-raw #:article-id-base #:article-id-suffix
           #:article-id-context
           #:article-id= #:article-id-hash #:article-id-string
           #:article-id-display))

(in-package :orchestrator.article-id)

(defstruct (canonical-article-id
            (:constructor %make-id)
            (:conc-name article-id-)
            (:predicate article-id-p)
            (:print-object
             (lambda (id s)
               (print-unreadable-object (id s :type nil)
                 (format s "ΑΡΘΡΟ ~A~@[ @~A~]"
                         (article-id-string id) (article-id-context id))))))
  raw       ; η ετικέτα όπως δόθηκε (display label) — ΔΕΝ είναι η ταυτότητα
  base      ; integer — το αριθμητικό θεμέλιο
  suffix    ; string ή NIL — «Α», «ΒΙΣ»… ΜΕΡΟΣ ΤΗΣ ΤΑΥΤΟΤΗΤΑΣ, δεν καταρρέει
  context)  ; string ή NIL — δικαιοδοσία/πηγή (πχ "poinikos")

(defun %canon-suffix (s)
  "Κανονικοποίηση επιθήματος: trim, κεφαλαία, ς→Σ (το string-upcase αφήνει
   το τελικό ς ανέπαφο — γνωστή παγίδα, λυμένη στη ρίζα)."
  (let ((up (substitute #\Σ #\ς (string-upcase (string-trim " ." s)))))
    (if (zerop (length up)) nil up)))

(defun parse-article-id (label &key context)
  "Ετικέτα (string ή integer) → canonical-article-id, ή (values NIL λόγος).
   Δέχεται «100», «100Α», «100 Α», 100, «100α». ΔΕΝ μαντεύει: ό,τι δεν
   είναι ψηφία+προαιρετικά γράμματα απορρίπτεται με λόγο."
  (etypecase label
    (integer
     (if (plusp label)
         (%make-id :raw (format nil "~D" label) :base label :suffix nil
                   :context context)
         (values nil "μη θετικός αριθμός άρθρου")))
    (string
     (let* ((trimmed (string-trim " " label))
            (digits (or (position-if-not #'digit-char-p trimmed)
                        (length trimmed))))
       (cond
         ((zerop (length trimmed)) (values nil "κενή ετικέτα άρθρου"))
         ((zerop digits) (values nil "η ετικέτα δεν αρχίζει από αριθμό"))
         (t (let ((base (parse-integer trimmed :end digits))
                  (suffix (%canon-suffix (subseq trimmed digits))))
              (if (and suffix (notevery #'alpha-char-p suffix))
                  (values nil (format nil "μη γραμματικό επίθημα «~A»" suffix))
                  (%make-id :raw trimmed :base base :suffix suffix
                            :context context)))))))))

(defun article-id-string (id)
  "Η ΚΑΝΟΝΙΚΗ ΣΕΙΡΙΟΠΟΙΗΣΗ — σταθερή, αυτή καταναλώνουν κλειδιά και URIs.
   ΔΕΝ είναι η raw ετικέτα: «100 α» και «100Α» σειριοποιούνται ίδια."
  (check-type id canonical-article-id)
  (format nil "~D~@[~A~]" (article-id-base id) (article-id-suffix id)))

(defun article-id-display (id)
  "Η ετικέτα εμφάνισης (raw) — ΔΙΑΚΡΙΤΗ από την ταυτότητα, μόνο για ανθρώπους."
  (article-id-raw id))

(defun article-id= (a b)
  "Ισότητα ΤΑΥΤΟΤΗΤΩΝ: μόνο μεταξύ canonical-article-id (ωμός αριθμός ⇒ NIL —
   ποτέ σιωπηλή σύγκριση τύπου με μη-τύπο), κατά βάση+επίθημα+context."
  (and (article-id-p a) (article-id-p b)
       (= (article-id-base a) (article-id-base b))
       (equal (article-id-suffix a) (article-id-suffix b))
       (equal (article-id-context a) (article-id-context b))))

(defun article-id-hash (id)
  "Hash συνεπές με το article-id=: ίδια ταυτότητα ⇒ ίδιο hash."
  (check-type id canonical-article-id)
  (sxhash (list (article-id-base id) (article-id-suffix id)
                (article-id-context id))))
