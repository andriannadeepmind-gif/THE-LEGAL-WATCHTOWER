;;;; source/legal-identity.lisp
;;;; ============================================================================
;;;; Η ΜΙΑ ΕΔΡΑ ΚΑΝΟΝΙΚΗΣ ΝΟΜΙΚΗΣ ΤΑΥΤΟΤΗΤΑΣ — [0088] Temporal/Identity Φ1
;;;; ============================================================================
;;;;
;;;; Typed ταυτότητα για: νομικό σώμα (legal-body-id), διάταξη σε οποιοδήποτε
;;;; βάθος (provision-id: άρθρο/παράγραφος/περίπτωση/εδάφιο). Η ισότητα, το
;;;; hash, η διάταξη και ΚΑΘΕ προβολή (eId, URI id, file id) πηγάζουν από εδώ
;;;; και μόνο από εδώ. Κανείς δεν ξαναϋλοποιεί κανόνα επιθήματος/padding.
;;;;
;;;; Ιστορία εδρών (AUTH-01, κλείσιμο): προϋπήρχαν ΔΥΟ ζωντανές έδρες —
;;;;  (S5) orchestrator.article-id (αυτό το αρχείο, πρώην canonical-article-id):
;;;;       typed αλλά ΧΑΛΑΡΟ parsing («ΒΙΣ», πεζά, λατινικά, «100 α» δεκτά)
;;;;       και sxhash-λίστας· καταναλωνόταν ΜΟΝΟ από gates.
;;;;  (S2) orchestrator.model article.lisp: αυστηρή νομοθετική ακολουθία
;;;;       επιθημάτων + pad/uri/file κανόνες· καταναλωνόταν από το corpus path.
;;;; Εδώ: η S2 αυστηρότητα ΜΕΤΑΚΟΜΙΣΕ ως ο πυρήνας του orchestrator.identity,
;;;; η S5 χαλαρότητα ΠΕΘΑΝΕ, και [0088 Φ6β] ο adapter orchestrator.article-id
;;;; ΔΙΑΓΡΑΦΗΚΕ ΟΡΙΣΤΙΚΑ — gates/μητρώα/συμβόλαια δείχνουν πλέον ΑΠΕΥΘΕΙΑΣ
;;;; εδώ (κατά deployment/LAWMAX-TEMPORAL-IDENTITY-DESIGN.md §2).
;;;;
;;;; Fail-closed παντού: ό,τι δεν αναγνωρίζεται ⇒ identity-parse-error με
;;;; αιτία — ΠΟΤΕ σιωπηλή κανονικοποίηση, ΠΟΤΕ ψευδοταυτότητα (τίμια άγνοια).

(defpackage :orchestrator.identity
  (:use :cl)
  (:export
   ;; συνθήκες
   #:identity-parse-error #:identity-error-input #:identity-error-reason
   ;; τακτική ακολουθία επιθημάτων (η ΜΙΑ έδρα — δύο δηλωμένες σειρές)
   #:suffix-ordinal #:ordinal-suffix
   ;; νομικό σώμα
   #:legal-body-id #:make-body #:body-id-p
   #:body-jurisdiction #:body-kind #:body-year #:body-number #:body-slug
   #:body-id-string #:body-kinds #:declared-body
   ;; διάταξη
   #:provision-id #:make-provision-id #:provision-id-p
   #:provision-body #:provision-path
   #:article-segment #:paragraph-segment #:point-segment #:edafio-segment
   #:provision-id-string #:parse-provision-designator
   #:provision-id= #:provision-id-hash #:provision-order-key #:provision-id<
   ;; άρθρο-επίπεδο κατασκευή + προβολές
   #:parse-article-label #:article-provision-id
   #:eid<-provision-id #:uri-id<-provision-id #:file-id<-provision-id))

(in-package :orchestrator.identity)

;;; ----------------------------------------------------------------------------
;;; Συνθήκη — κάθε αποτυχία αναγνώρισης ταυτότητας περνά από εδώ
;;; ----------------------------------------------------------------------------

(define-condition identity-parse-error (error)
  ((input  :initarg :input  :reader identity-error-input)
   (reason :initarg :reason :reader identity-error-reason))
  (:report (lambda (c s)
             (format s "Άκυρη νομική ταυτότητα ~S — ~A"
                     (identity-error-input c) (identity-error-reason c)))))

(defun %die (input reason &rest args)
  (error 'identity-parse-error :input input
         :reason (apply #'format nil reason args)))

;;; ----------------------------------------------------------------------------
;;; Η ΜΙΑ έδρα της τακτικής ακολουθίας επιθημάτων — ΔΥΟ δηλωμένες σειρές:
;;;   :upper  Α,Β,Γ,Δ,Ε,ΣΤ,Ζ,Η,Θ,Ι,ΙΑ,…,ΠΘ   (άρθρα — «110Α», «370ΣΤ»)
;;;   :lower  α,β,γ,δ,ε,στ,ζ,η,θ,ι,ια,…,πθ   (παράγραφοι «4α», περιπτώσεις «β»)
;;; Ελληνικός αριθμητικός τρόπος (ΣΤ=6, δίγραμμα)· λεξικογραφική προσέγγιση
;;; και λατινικά ομόγλυφα = γνωστές θανατωμένες κλάσεις ([0052]).
;;; ΔΗΛΩΜΕΝΟ ΟΡΙΟ: δεκάδες ως Π/π (=80) ⇒ μέγιστο ΠΘ/πθ = 89.
;;; ----------------------------------------------------------------------------

(defparameter +suffix-units+
  '((:upper . (("Α" . 1) ("Β" . 2) ("Γ" . 3) ("Δ" . 4) ("Ε" . 5)
               ("ΣΤ" . 6) ("Ζ" . 7) ("Η" . 8) ("Θ" . 9)))
    (:lower . (("α" . 1) ("β" . 2) ("γ" . 3) ("δ" . 4) ("ε" . 5)
               ("στ" . 6) ("ζ" . 7) ("η" . 8) ("θ" . 9)))))

(defparameter +suffix-tens+
  '((:upper . ((#\Ι . 10) (#\Κ . 20) (#\Λ . 30) (#\Μ . 40)
               (#\Ν . 50) (#\Ξ . 60) (#\Ο . 70) (#\Π . 80)))
    (:lower . ((#\ι . 10) (#\κ . 20) (#\λ . 30) (#\μ . 40)
               (#\ν . 50) (#\ξ . 60) (#\ο . 70) (#\π . 80)))))

(defun suffix-ordinal (suffix &key (sequence :upper))
  "Τακτική θέση του SUFFIX στη νομοθετική ακολουθία της SEQUENCE (:upper/:lower):
   \"\" ⇒ 0, «Α» ⇒ 1, «ΣΤ» ⇒ 6, «ΙΑ» ⇒ 11, «ΠΘ» ⇒ 89. Άγνωστο / λάθος σειρά /
   λατινικό ομόγλυφο / μικτό ⇒ identity-parse-error (τίμια άγνοια)."
  (let ((s (string suffix))
        (units (cdr (assoc sequence +suffix-units+)))
        (tens  (cdr (assoc sequence +suffix-tens+))))
    (unless (and units tens) (%die sequence "άγνωστη ακολουθία επιθημάτων"))
    (cond
      ((zerop (length s)) 0)
      ((string= s (if (eq sequence :upper) "ΣΤ" "στ")) 6)
      (t (let* ((ten (cdr (assoc (char s 0) tens)))
                (unit-part (if ten (subseq s 1) s)))
           (cond
             ((and ten (zerop (length unit-part))) ten)
             (t (let ((unit (cdr (assoc unit-part units :test #'string=))))
                  (unless unit
                    (%die s "εκτός νομοθετικής ακολουθίας ~(~A~) (Α..Ε,ΣΤ,Ζ..Θ,Ι,ΙΑ,…· ελληνικά, όχι λατινικά ομόγλυφα/λάθος πεζότητα)" sequence))
                  (+ (or ten 0) unit)))))))))

(defun ordinal-suffix (n &key (sequence :upper))
  "Αντίστροφη προβολή: 0 ⇒ \"\", 1 ⇒ «Α», 6 ⇒ «ΣΤ», 11 ⇒ «ΙΑ». Πεδίο 0..89."
  (unless (and (integerp n) (<= 0 n 89))
    (%die n "τακτική θέση εκτός πεδίου 0..89"))
  (if (zerop n)
      ""
      (let* ((units (cdr (assoc sequence +suffix-units+)))
             (tens  (cdr (assoc sequence +suffix-tens+)))
             (ten (* 10 (floor n 10)))
             (unit (mod n 10))
             (ten-char (car (rassoc ten tens)))
             (unit-str (car (rassoc unit units))))
        (when (and (plusp ten) (null ten-char)) (%die n "δεκάδα εκτός πίνακα"))
        (when (and (plusp unit) (null unit-str)) (%die n "μονάδα εκτός πίνακα"))
        (format nil "~@[~C~]~@[~A~]"
                (and (plusp ten) ten-char)
                (and (plusp unit) unit-str)))))

;;; ----------------------------------------------------------------------------
;;; Νομικό σώμα — kind από ΜΗΤΡΩΟ δεδομένων (όχι κλειστό enum στον κώδικα):
;;; deployment/data/body-kind-registry.sexp, επεκτάσιμο ΜΟΝΟ με receipt +
;;; έγκριση δημιουργού (σχέδιο §1.1 — θεραπεία «στενού doctype»).
;;; ----------------------------------------------------------------------------

(defvar *body-kinds-cache* nil)

(defun body-kinds ()
  "Τα δηλωμένα είδη σωμάτων από το μητρώο. Απόν/άκυρο μητρώο ⇒ ΣΦΑΛΜΑ
   (fail-closed — καμία ταυτότητα σώματος χωρίς τη δηλωμένη οντολογία)."
  (or *body-kinds-cache*
      (setf *body-kinds-cache*
            (let ((path (orchestrator.paths:institution-dir
                         "deployment/data/body-kind-registry.sexp")))
              (unless (probe-file path)
                (%die (namestring path) "το μητρώο ειδών σωμάτων ΑΠΟΥΣΙΑΖΕΙ"))
              (let ((form (with-open-file (in path :external-format :utf-8)
                            (let ((*read-eval* nil)
                                  (*package* (find-package :keyword)))
                              (read in nil nil)))))
                (let ((kinds (getf form :kinds)))
                  (unless (and (eq (getf form :schema) :body-kind-registry/1)
                               (consp kinds) (every #'keywordp kinds))
                    (%die (namestring path) "άκυρο σχήμα μητρώου ειδών σωμάτων"))
                  kinds))))))

(defstruct (legal-body-id
            (:constructor %make-body)
            (:conc-name body-)
            (:predicate body-id-p))
  jurisdiction   ; keyword — :gr
  kind           ; keyword ∈ (body-kinds)
  year           ; integer | NIL (NIL μόνο για :syntagma)
  number         ; integer | NIL
  slug)          ; string | NIL — ΜΟΝΟ εμφάνιση, ποτέ κλειδί

(defun make-body (jurisdiction kind &key year number slug)
  "Fail-closed κατασκευή ταυτότητας σώματος."
  (unless (keywordp jurisdiction) (%die jurisdiction "μη-keyword δικαιοδοσία"))
  (unless (member kind (body-kinds))
    (%die kind "είδος σώματος εκτός μητρώου ~S" (body-kinds)))
  (unless (or (eq kind :syntagma) (integerp year))
    (%die (list kind year) "το έτος είναι ΥΠΟΧΡΕΩΤΙΚΟ για κάθε είδος πλην :syntagma"))
  (when (and number (not (integerp number))) (%die number "μη ακέραιος αριθμός"))
  (%make-body :jurisdiction jurisdiction :kind kind
              :year year :number number :slug slug))

(defun declared-body ()
  "[0088 Φ6γ-Δ³] Η ΜΙΑ config→typed-body αντιστοίχιση για το ΕΝΕΡΓΟ corpus
   config: document_type «const» ⇒ (:gr :syntagma)· κάθε άλλο σώμα απαιτεί
   ΔΗΛΩΜΕΝΟ body_identity (kind/year/number της κυρωτικής πράξης) — ΠΟΤΕ
   παραγωγή από publication dates ή ELI strings. Καταναλωτές: version-graph
   import ΚΑΙ orchestrator.model corpus — μία έδρα, καμία απόκλιση."
  (if (equal (orchestrator.spec:config-get "corpus.document_type") "const")
      (make-body :gr :syntagma)
      (let ((kind (orchestrator.spec:config-get "body_identity.kind"))
            (year (orchestrator.spec:config-get "body_identity.year"))
            (number (orchestrator.spec:config-get "body_identity.number"))
            (slug (orchestrator.spec:config-get "corpus.short_name")))
        (unless (and kind year number)
          (error "ενεργό corpus χωρίς δηλωμένο body_identity (kind/year/number) — δεν κατασκευάζεται ταυτότητα σώματος"))
        (make-body :gr (intern (string-upcase (string kind)) :keyword)
                   :year year :number number :slug slug))))

(defun body-id-string (body)
  "Κανονική σειριοποίηση σώματος: «gr/syntagma», «gr/nomos/2019/4619»."
  (check-type body legal-body-id)
  (format nil "~(~A~)/~(~A~)~@[/~D~]~@[/~D~]"
          (body-jurisdiction body) (body-kind body)
          (body-year body) (body-number body)))

;;; ----------------------------------------------------------------------------
;;; Τμήματα διαδρομής διάταξης — typed, με ιεραρχική τάξη:
;;;   :article(0) < :paragraph(1) < :point(2) < :edafio(3), αυστηρά αύξουσα.
;;; Αναρίθμητα εδάφια/παράγραφοι ΔΕΝ αποκτούν ταυτότητα (τίμια άγνοια) —
;;; ο καλών δηλώνει unresolved αντί να εφεύρει θεσιακό index (σχέδιο §1.1).
;;; ----------------------------------------------------------------------------

(defun article-segment (base &optional (suffix-ord 0))
  (unless (and (integerp base) (<= 1 base 9999)) (%die base "βάση άρθρου εκτός 1..9999"))
  (unless (and (integerp suffix-ord) (<= 0 suffix-ord 89)) (%die suffix-ord "επίθημα εκτός 0..89"))
  (list :article base suffix-ord))

(defun paragraph-segment (base &optional (suffix-ord 0))
  (unless (and (integerp base) (<= 1 base 999)) (%die base "αριθμός παραγράφου εκτός 1..999"))
  (unless (and (integerp suffix-ord) (<= 0 suffix-ord 89)) (%die suffix-ord "επίθημα εκτός 0..89"))
  (list :paragraph base suffix-ord))

(defun point-segment (letter-ord)
  (unless (and (integerp letter-ord) (<= 1 letter-ord 89)) (%die letter-ord "περίπτωση εκτός 1..89"))
  (list :point letter-ord))

(defun edafio-segment (n)
  (unless (and (integerp n) (plusp n)) (%die n "μη θετικός αριθμός εδαφίου"))
  (list :edafio n))

(defparameter +segment-rank+ '((:article . 0) (:paragraph . 1) (:point . 2) (:edafio . 3)))

(defstruct (provision-id
            (:constructor %make-provision-id)
            (:conc-name provision-)
            (:predicate provision-id-p)
            (:print-object
             (lambda (id s)
               (print-unreadable-object (id s :type nil)
                 (format s "ΔΙΑΤΑΞΗ ~A" (provision-id-string id))))))
  body    ; legal-body-id
  path)   ; λίστα segments, αυστηρά αύξον rank, κεφαλή :article

(defun make-provision-id (body path)
  "Fail-closed: BODY typed, PATH μη κενή λίστα έγκυρων segments με κεφαλή
   :article και αυστηρά αύξουσα ιεραρχική τάξη."
  (unless (body-id-p body) (%die body "μη-typed σώμα"))
  (unless (and (consp path) (consp (first path)) (eq (first (first path)) :article))
    (%die path "η διαδρομή πρέπει να αρχίζει από :article"))
  (loop for (a b) on path while b
        for ra = (cdr (assoc (first a) +segment-rank+))
        for rb = (cdr (assoc (first b) +segment-rank+))
        do (unless (and ra rb (< ra rb))
             (%die path "μη αύξουσα ιεραρχία τμημάτων (~A → ~A)" (first a) (first b))))
  ;; επανεπικύρωση κάθε τμήματος μέσω των constructors (καμία ωμή λίστα)
  (dolist (seg path)
    (ecase (first seg)
      (:article   (apply #'article-segment (rest seg)))
      (:paragraph (apply #'paragraph-segment (rest seg)))
      (:point     (apply #'point-segment (rest seg)))
      (:edafio    (apply #'edafio-segment (rest seg)))))
  (%make-provision-id :body body :path path))

(defun %segment-string (seg)
  (ecase (first seg)
    (:article   (format nil "art:~D~A" (second seg)
                        (ordinal-suffix (third seg) :sequence :upper)))
    (:paragraph (format nil "par:~D~A" (second seg)
                        (ordinal-suffix (third seg) :sequence :lower)))
    (:point     (format nil "point:~A" (ordinal-suffix (second seg) :sequence :lower)))
    (:edafio    (format nil "ed:~D" (second seg)))))

(defun provision-id-string (id)
  "Η ΚΑΝΟΝΙΚΗ σειριοποίηση διάταξης — αυτή και μόνο αυτή είναι κλειδί:
   «gr/syntagma#art:110Α/par:3/point:β»."
  (check-type id provision-id)
  (format nil "~A#~{~A~^/~}"
          (body-id-string (provision-body id))
          (mapcar #'%segment-string (provision-path id))))

(defun provision-id= (a b)
  (and (provision-id-p a) (provision-id-p b)
       (string= (provision-id-string a) (provision-id-string b))))

(defun provision-id-hash (id)
  (sxhash (provision-id-string id)))

(defun provision-order-key (id)
  "Ολική διάταξη: (body-string, [rank base ord]…) — ΠΟΤΕ συνθετικοί αριθμοί,
   ΠΟΤΕ λεξικογραφικό string< επιθημάτων."
  (check-type id provision-id)
  (cons (body-id-string (provision-body id))
        (loop for seg in (provision-path id)
              append (ecase (first seg)
                       (:article   (list 0 (second seg) (third seg)))
                       (:paragraph (list 1 (second seg) (third seg)))
                       (:point     (list 2 (second seg) 0))
                       (:edafio    (list 3 (second seg) 0))))))

(defun provision-id< (a b)
  (let ((ka (provision-order-key a)) (kb (provision-order-key b)))
    (or (string< (car ka) (car kb))
        (and (string= (car ka) (car kb))
             (loop for x in (cdr ka) for y in (cdr kb)
                   when (< x y) return t
                   when (> x y) return nil
                   finally (return (< (length ka) (length kb))))))))

;;; ----------------------------------------------------------------------------
;;; Ο ΜΟΝΑΔΙΚΟΣ parser πλήρους προσδιοριστή — αντίστροφος του provision-id-string
;;; ----------------------------------------------------------------------------

(defun %parse-decorated (s input sequence what)
  "«110Α»/«4α»/«3» ⇒ (values βάση τακτική-θέση) — ψηφία + προαιρετικό επίθημα
   της SEQUENCE, τίποτα άλλο."
  (let ((digits (or (position-if-not #'digit-char-p s) (length s))))
    (when (zerop digits) (%die input "~A χωρίς αριθμό: ~S" what s))
    (values (parse-integer s :end digits)
            (suffix-ordinal (subseq s digits) :sequence sequence))))

(defun parse-provision-designator (string)
  "«gr/syntagma#art:110Α/par:3/point:β» ⇒ provision-id. Αυστηρά ο αντίστροφος
   της κανονικής σειριοποίησης· οτιδήποτε άλλο ⇒ identity-parse-error."
  (let* ((hash (or (position #\# string)
                   (%die string "λείπει το «#» σώματος/διαδρομής")))
         (body-str (subseq string 0 hash))
         (path-str (subseq string (1+ hash)))
         (bparts (uiop:split-string body-str :separator "/")))
    (unless (<= 2 (length bparts) 4) (%die string "άκυρο σώμα «~A»" body-str))
    (let* ((jur (intern (string-upcase (first bparts)) :keyword))
           (kind (intern (string-upcase (second bparts)) :keyword))
           (year (when (third bparts)
                   (or (parse-integer (third bparts) :junk-allowed t)
                       (%die string "μη αριθμητικό έτος «~A»" (third bparts)))))
           (number (when (fourth bparts)
                     (or (parse-integer (fourth bparts) :junk-allowed t)
                         (%die string "μη αριθμητικός αριθμός «~A»" (fourth bparts)))))
           (body (make-body jur kind :year year :number number))
           (segs (loop for part in (uiop:split-string path-str :separator "/")
                       collect
                       (let ((colon (or (position #\: part)
                                        (%die string "τμήμα χωρίς «:» — «~A»" part))))
                         (let ((tag (subseq part 0 colon))
                               (val (subseq part (1+ colon))))
                           (cond
                             ((string= tag "art")
                              (multiple-value-bind (b o) (%parse-decorated val string :upper "άρθρο")
                                (article-segment b o)))
                             ((string= tag "par")
                              (multiple-value-bind (b o) (%parse-decorated val string :lower "παράγραφος")
                                (paragraph-segment b o)))
                             ((string= tag "point")
                              (point-segment (suffix-ordinal val :sequence :lower)))
                             ((string= tag "ed")
                              (edafio-segment (or (parse-integer val :junk-allowed t)
                                                  (%die string "μη αριθμητικό εδάφιο «~A»" val))))
                             (t (%die string "άγνωστο είδος τμήματος «~A»" tag))))))))
      (make-provision-id body segs))))

;;; ----------------------------------------------------------------------------
;;; Άρθρο-επίπεδο: ο αυστηρός parser ετικέτας + οι κανονικές προβολές
;;; (η S2 αλήθεια του article.lisp, πλέον ΕΔΩ — το article.lisp αντιπροσωπεύει)
;;; ----------------------------------------------------------------------------

(defun parse-article-label (label)
  "«5», «5Α», «370ΣΤ» ⇒ (values βάση τακτική-θέση). Κενά/πεζά/λατινικά/«Α5»
   ⇒ identity-parse-error — καμία σιωπηλή επανερμηνεία ([0052] ㉑).
   [0088 Φ6β]: κάθε επιτυχής αναγνώριση αφήνει :identity ίχνος ΑΠΟ ΤΗΝ ΕΔΡΑ
   (ο adapter orchestrator.article-id που το εξέπεμπε ΠΕΘΑΝΕ)."
  (let ((s (string label)))
    (when (zerop (length s)) (%die label "κενή ετικέτα άρθρου"))
    (when (find #\Space s) (%die label "η ετικέτα περιέχει κενό — κανονική μορφή «5Α»"))
    (multiple-value-bind (base ord) (%parse-decorated s label :upper "άρθρο")
      (orchestrator.trace:emit! :identity
       :symbol "parse-article-label" :package "orchestrator.identity"
       :source "source/legal-identity.lisp"
       :data (list :base base :ordinal ord :raw s))
      (values base ord))))

(defun article-provision-id (body label)
  "Ετικέτα άρθρου + σώμα ⇒ provision-id (η κανονική είσοδος των adapters)."
  (multiple-value-bind (base ord) (parse-article-label label)
    (make-provision-id body (list (article-segment base ord)))))

(defun %article-head (id what)
  (let ((head (first (provision-path id))))
    (unless (and head (eq (first head) :article))
      (%die id "~A ορίζεται μόνο για διαδρομή με κεφαλή :article" what))
    head))

(defun eid<-provision-id (id)
  "Προβολή eId (AKN-συμβατή με το υπάρχον corpus): «art_5Α»,
   «art_1__para_2», «…__point_β», «…__ed_2»."
  (check-type id provision-id)
  (with-output-to-string (s)
    (loop for seg in (provision-path id)
          do (ecase (first seg)
               (:article   (format s "art_~D~A" (second seg)
                                   (ordinal-suffix (third seg) :sequence :upper)))
               (:paragraph (format s "__para_~D~A" (second seg)
                                   (ordinal-suffix (third seg) :sequence :lower)))
               (:point     (format s "__point_~A" (ordinal-suffix (second seg) :sequence :lower)))
               (:edafio    (format s "__ed_~D" (second seg)))))))

(defun uri-id<-provision-id (id)
  "Προβολή URI/ELI path id ΑΡΘΡΟΥ (χωρίς padding): «5Α»."
  (let ((head (%article-head id "uri-id")))
    (format nil "~D~A" (second head) (ordinal-suffix (third head) :sequence :upper))))

(defun file-id<-provision-id (id)
  "Προβολή filesystem id ΑΡΘΡΟΥ (3ψήφιο padding): «005Α». ΜΟΝΟΔΡΟΜΗ —
   δεν parse-άρεται ποτέ πίσω σε ταυτότητα (σχέδιο §1.1)."
  (let ((head (%article-head id "file-id")))
    (format nil "~3,'0D~A" (second head) (ordinal-suffix (third head) :sequence :upper))))
