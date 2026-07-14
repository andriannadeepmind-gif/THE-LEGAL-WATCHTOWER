;;;; tests/legal-identity-test.lisp
;;;; ============================================================================
;;;; [0088] Φ1 — Η ΜΙΑ έδρα νομικής ταυτότητας (orchestrator.identity):
;;;; τακτική ακολουθία (2 σειρές, bijection 0..89), σώμα από μητρώο, provision-id
;;;; round-trip, fail-closed parsing, προβολές eId/URI/file, adapter αυστηρός,
;;;; και ΤΟ BIJECTION PROOF: κάθε ταυτότητα άρθρου των 6 σωμάτων old↔new με
;;;; ΜΗΔΕΝ διαφωνίες (acceptance: unresolved_identity_collapses=0).
;;;; Τρέχει κάτω από docker/run-standalone-test.lisp (self-exit 0/1).
;;;; ============================================================================

(in-package :orchestrator.cli)

(defvar *li-pass* 0)
(defvar *li-fail* 0)

(defmacro li-check (name form)
  `(handler-case
       (if ,form
           (progn (incf *li-pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *li-fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e)
       (incf *li-fail*)
       (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

(format t "~%── [0088] Φ1 LEGAL IDENTITY: η ΜΙΑ έδρα ταυτότητας ──~%")

;;; ① Τακτική ακολουθία — ΠΛΗΡΗΣ bijection 0..89 και στις ΔΥΟ σειρές
(li-check "① bijection :upper — ordinal↔suffix ταυτοτικό σε ΟΛΟ το 0..89"
          (loop for n from 0 to 89
                always (= n (orchestrator.identity:suffix-ordinal
                             (orchestrator.identity:ordinal-suffix n :sequence :upper)
                             :sequence :upper))))
(li-check "①β bijection :lower — ordinal↔suffix ταυτοτικό σε ΟΛΟ το 0..89"
          (loop for n from 0 to 89
                always (= n (orchestrator.identity:suffix-ordinal
                             (orchestrator.identity:ordinal-suffix n :sequence :lower)
                             :sequence :lower))))
(li-check "①γ σταθερές θέσεις: Α=1, ΣΤ=6, Ι=10, ΙΑ=11, ΙΣΤ=16, ΠΘ=89· στ=6 πεζό"
          (and (= 1 (orchestrator.identity:suffix-ordinal "Α"))
               (= 6 (orchestrator.identity:suffix-ordinal "ΣΤ"))
               (= 10 (orchestrator.identity:suffix-ordinal "Ι"))
               (= 11 (orchestrator.identity:suffix-ordinal "ΙΑ"))
               (= 16 (orchestrator.identity:suffix-ordinal "ΙΣΤ"))
               (= 89 (orchestrator.identity:suffix-ordinal "ΠΘ"))
               (= 6 (orchestrator.identity:suffix-ordinal "στ" :sequence :lower))))
(li-check "①δ fail-closed: λατινικό «A», πεζό σε :upper, «Α5», «ΒΙΣ», 90 ⇒ ΣΦΑΛΜΑ"
          (flet ((dies (thunk) (handler-case (progn (funcall thunk) nil)
                                 (orchestrator.identity:identity-parse-error () t))))
            (and (dies (lambda () (orchestrator.identity:suffix-ordinal "A")))
                 (dies (lambda () (orchestrator.identity:suffix-ordinal "α")))
                 (dies (lambda () (orchestrator.identity:suffix-ordinal "Α5")))
                 (dies (lambda () (orchestrator.identity:suffix-ordinal "ΒΙΣ")))
                 (dies (lambda () (orchestrator.identity:ordinal-suffix 90))))))

;;; ② Σώμα — μητρώο ειδών, fail-closed
(li-check "② make-body: gr/syntagma χωρίς έτος ΟΚ· gr/nomos ΧΩΡΙΣ έτος ⇒ ΣΦΑΛΜΑ· άγνωστο είδος ⇒ ΣΦΑΛΜΑ"
          (and (orchestrator.identity:body-id-p
                (orchestrator.identity:make-body :gr :syntagma))
               (handler-case (progn (orchestrator.identity:make-body :gr :nomos) nil)
                 (orchestrator.identity:identity-parse-error () t))
               (handler-case (progn (orchestrator.identity:make-body :gr :tweet :year 2020) nil)
                 (orchestrator.identity:identity-parse-error () t))))
(li-check "②β body-id-string: «gr/syntagma» και «gr/nomos/2019/4619»"
          (and (equal "gr/syntagma"
                      (orchestrator.identity:body-id-string
                       (orchestrator.identity:make-body :gr :syntagma)))
               (equal "gr/nomos/2019/4619"
                      (orchestrator.identity:body-id-string
                       (orchestrator.identity:make-body :gr :nomos :year 2019 :number 4619)))))

;;; ③ provision-id — κατασκευή, σειριοποίηση, round-trip, ιεραρχία
(defparameter *li-syntagma* (orchestrator.identity:make-body :gr :syntagma))
(li-check "③ «gr/syntagma#art:110Α/par:3/point:β» — string ↔ parse round-trip"
          (let* ((id (orchestrator.identity:make-provision-id
                      *li-syntagma*
                      (list (orchestrator.identity:article-segment 110 1)
                            (orchestrator.identity:paragraph-segment 3)
                            (orchestrator.identity:point-segment 2))))
                 (s (orchestrator.identity:provision-id-string id))
                 (back (orchestrator.identity:parse-provision-designator s)))
            (and (equal "gr/syntagma#art:110Α/par:3/point:β" s)
                 (orchestrator.identity:provision-id= id back)
                 (= (orchestrator.identity:provision-id-hash id)
                    (orchestrator.identity:provision-id-hash back)))))
(li-check "③β παράγραφος με πεζό επίθημα: «par:4α» round-trip (εισαχθείσα 4α)"
          (let* ((id (orchestrator.identity:make-provision-id
                      *li-syntagma*
                      (list (orchestrator.identity:article-segment 21 0)
                            (orchestrator.identity:paragraph-segment 4 1))))
                 (s (orchestrator.identity:provision-id-string id)))
            (and (search "par:4α" s)
                 (orchestrator.identity:provision-id=
                  id (orchestrator.identity:parse-provision-designator s)))))
(li-check "③γ ιεραρχία fail-closed: point πριν από paragraph ⇒ ΣΦΑΛΜΑ· κεφαλή ≠ article ⇒ ΣΦΑΛΜΑ"
          (flet ((dies (path) (handler-case
                                  (progn (orchestrator.identity:make-provision-id *li-syntagma* path) nil)
                                (orchestrator.identity:identity-parse-error () t))))
            (and (dies (list (orchestrator.identity:article-segment 5 0)
                             (orchestrator.identity:point-segment 2)
                             (orchestrator.identity:paragraph-segment 3)))
                 (dies (list (orchestrator.identity:paragraph-segment 3))))))
(li-check "③δ άκυροι προσδιοριστές ⇒ identity-parse-error (όχι σιωπηλό NIL)"
          (flet ((dies (s) (handler-case
                               (progn (orchestrator.identity:parse-provision-designator s) nil)
                             (orchestrator.identity:identity-parse-error () t))))
            (and (dies "gr/syntagma")                          ; χωρίς #
                 (dies "gr/syntagma#par:3")                    ; κεφαλή ≠ art
                 (dies "gr/syntagma#art:5A")                   ; λατινικό
                 (dies "gr/tweet/2020#art:5")                  ; είδος εκτός μητρώου
                 (dies "gr/syntagma#art:5Α/xx:3"))))           ; άγνωστο τμήμα
(li-check "③ε provision-id< : art:5 < art:5Α < art:5Ε < art:5ΣΤ < art:5Ζ < art:6 (νομική σειρά)"
          (flet ((aid (label) (orchestrator.identity:article-provision-id *li-syntagma* label)))
            (let ((sorted (sort (mapcar #'aid (list "6" "5Ζ" "5Α" "5ΣΤ" "5" "5Ε"))
                                #'orchestrator.identity:provision-id<)))
              (equal '("5" "5Α" "5Ε" "5ΣΤ" "5Ζ" "6")
                     (mapcar #'orchestrator.identity:uri-id<-provision-id sorted)))))

;;; ④ Προβολές — eId / URI / file (οι κανόνες του corpus ΑΥΤΟΥΣΙΟΙ)
(li-check "④ προβολές άρθρου 5Α: eid=art_5Α, uri=5Α, file=005Α"
          (let ((id (orchestrator.identity:article-provision-id *li-syntagma* "5Α")))
            (and (equal "art_5Α" (orchestrator.identity:eid<-provision-id id))
                 (equal "5Α" (orchestrator.identity:uri-id<-provision-id id))
                 (equal "005Α" (orchestrator.identity:file-id<-provision-id id)))))
(li-check "④β eid παραγράφου: art_1__para_2 (σύμβαση corpus ΑΘΙΚΤΗ)"
          (equal "art_1__para_2"
                 (orchestrator.identity:eid<-provision-id
                  (orchestrator.identity:make-provision-id
                   *li-syntagma*
                   (list (orchestrator.identity:article-segment 1 0)
                         (orchestrator.identity:paragraph-segment 2))))))

;;; ⑤ [Φ6β] Ο adapter orchestrator.article-id ΠΕΘΑΝΕ — η αυστηρή αλήθεια
;;; κλειδώνεται ΑΠΕΥΘΕΙΑΣ στην έδρα, και ο νεκρός δεν ανασταίνεται.
(li-check "⑤ parse-article-label: «100Α» ΟΚ· «100 α»/«100α»/«100A»(λατ.)/«100ΒΙΣ» ⇒ typed σφάλμα+λόγος"
          (multiple-value-bind (base ord)
              (orchestrator.identity:parse-article-label "100Α")
            (and (= 100 base)
                 (equal "Α" (orchestrator.identity:ordinal-suffix ord :sequence :upper))
                 (loop for bad in '("100 α" "100α" "100A" "100ΒΙΣ")
                       always (handler-case
                                  (progn (orchestrator.identity:parse-article-label bad) nil)
                                (orchestrator.identity:identity-parse-error (e)
                                  (stringp (orchestrator.identity:identity-error-reason e))))))))
(li-check "⑤β provision-id-hash: συνάρτηση της κανονικής σειριοποίησης, συνεπές με provision-id="
          (let* ((a (orchestrator.identity:article-provision-id *li-syntagma* "100Α"))
                 (b (orchestrator.identity:article-provision-id *li-syntagma* "100Α"))
                 (c (orchestrator.identity:article-provision-id *li-syntagma* "100")))
            (and (orchestrator.identity:provision-id= a b)
                 (= (orchestrator.identity:provision-id-hash a)
                    (orchestrator.identity:provision-id-hash b))
                 (/= (orchestrator.identity:provision-id-hash a)
                     (orchestrator.identity:provision-id-hash c)))))
(li-check "⑤γ ΘΑΝΑΤΟΣ Φ6β: το πακέτο orchestrator.article-id ΔΕΝ υπάρχει πια"
          (not (find-package :orchestrator.article-id)))

;;; ⑥ Ο adapter του article.lisp (S2) — ΙΔΙΑ ετυμηγορία με τον πυρήνα
(li-check "⑥ article-suffix-ordinal ≡ identity:suffix-ordinal σε ΟΛΟ το 0..89 + ίδιο συμβόλαιο σφάλματος"
          (and (loop for n from 0 to 89
                     for sfx = (orchestrator.identity:ordinal-suffix n)
                     always (= n (orchestrator.model:article-suffix-ordinal sfx)))
               (handler-case (progn (orchestrator.model:article-suffix-ordinal "A") nil)
                 (error () t))))

;;; ⑦ ΤΟ BIJECTION PROOF — κάθε ταυτότητα άρθρου των 6 σωμάτων, old↔new,
;;; ΜΗΔΕΝ διαφωνίες σε file-id ΚΑΙ uri-id (καμία σιωπηλή απόκλιση στρωμάτων).
(format t "~%── ⑦ BIJECTION: 6 σώματα, κάθε ετικέτα άρθρου, old(S2) ↔ new(identity) ──~%")
(let ((total 0) (mismatches '()) (unparsed 0))
  (dolist (cid '("syntagma" "poinikos" "kpoinikis" "astikos" "kpolitikis" "kdioikitikis"))
    (orchestrator.spec:select-corpus cid)
    (let* ((json-path (or (orchestrator.spec:resolve-config-path "source.json")
                          (error "χωρίς source.json για ~A" cid)))
           (objs (jonathan:parse (uiop:read-file-string json-path :external-format :utf-8)
                                 :as :alist))
           (body (if (equal cid "syntagma")
                     (orchestrator.identity:make-body :gr :syntagma)
                     (orchestrator.identity:make-body :gr :kodikas :year 0
                                                      :slug cid))))
      (dolist (o objs)
        (let ((label (orchestrator.cli::%parse-article-title
                      (cdr (assoc "title" o :test #'string=)))))
          (if (null label)
              (incf unparsed)
              (let* ((old-file (orchestrator.model:pad-article-id 0 label))
                     (old-uri  (orchestrator.model:article-uri-id 0 label))
                     (new-id   (orchestrator.identity:article-provision-id body label))
                     (new-file (orchestrator.identity:file-id<-provision-id new-id))
                     (new-uri  (orchestrator.identity:uri-id<-provision-id new-id)))
                (incf total)
                (unless (and (equal old-file new-file) (equal old-uri new-uri))
                  (push (list cid label old-file new-file old-uri new-uri) mismatches))))))))
  (format t "  σύνολο ταυτοτήτων: ~D · αδιάγνωστοι τίτλοι: ~D · διαφωνίες: ~D~%"
          total unparsed (length mismatches))
  (dolist (m (subseq mismatches 0 (min 5 (length mismatches))))
    (format t "    ✗ ~S~%" m))
  (li-check (format nil "⑦ bijection ~D ταυτοτήτων old↔new: 0 διαφωνίες (file-id ΚΑΙ uri-id)" total)
            (and (> total 4000) (null mismatches)))
  (li-check "⑦β κανένας αδιάγνωστος τίτλος στα 6 σώματα (καμία ταυτότητα εκτός έδρας)"
            (zerop unparsed)))

(format t "~%========================================~%")
(format t "LEGAL-IDENTITY [0088 Φ1]: ~D passed, ~D failed~%" *li-pass* *li-fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *li-fail*) 0 1))
