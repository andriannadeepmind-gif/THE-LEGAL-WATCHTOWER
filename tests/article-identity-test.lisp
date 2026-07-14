;;;; tests/article-identity-test.lisp
;;;; THE lettered-article guarantee, locked: a lettered article (100Α) must NEVER
;;;; collapse onto its base number (100) in ANY identifier the system builds —
;;;; padded file/eId, URI/ELI path, or the FRBR Work it threads everywhere.
;;;; All identity now flows from the single source of truth in orchestrator.model
;;;; (pad-article-id / article-uri-id); this test fails if any of them diverge.

(in-package :orchestrator.model)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(format t "~%== pad-article-id: padded id, suffix preserved ==~%")
(check "plain number zero-padded to 3"        (string= "070" (pad-article-id 70)))
(check "bare suffix preserved"                (string= "070Α" (pad-article-id 70 "Α")))
(check "full label accepted as suffix source" (string= "070Α" (pad-article-id 70 "70Α")))
(check "three-digit number unchanged"         (string= "100" (pad-article-id 100)))
(check "nil suffix == no suffix"              (string= "100" (pad-article-id 100 nil)))
(check "100 and 100Α PAD to DISTINCT ids"     (not (string= (pad-article-id 100)
                                                            (pad-article-id 100 "Α"))))

(format t "~%== article-uri-id: unpadded URI-path id, suffix preserved ==~%")
(check "plain number, no padding"             (string= "70" (article-uri-id 70)))
(check "suffix preserved, no padding"         (string= "70Α" (article-uri-id 70 "Α")))
(check "full label accepted"                  (string= "100Α" (article-uri-id 100 "100Α")))
(check "100 and 100Α give DISTINCT uri ids"   (not (string= (article-uri-id 100)
                                                            (article-uri-id 100 "Α"))))

(format t "~%== article-file-id (on real article objects) ==~%")
(let ((base (make-instance 'article))
      (lettered (make-instance 'article)))
  (setf (article-number base) 100 (article-label base) "100")
  (setf (article-number lettered) 100 (article-label lettered) "100Α")
  (check "base 100 file-id"          (string= "100" (article-file-id base)))
  (check "lettered 100Α file-id"     (string= "100Α" (article-file-id lettered)))
  (check "file-ids are DISTINCT"     (not (string= (article-file-id base)
                                                   (article-file-id lettered)))))

(format t "~%== build-eli-article-uri: suffix-safe (was numeric-only) ==~%")
(let ((prefix "https://stavropouloslaw.com/eli/gr/const/1975"))
  (check "base article URI"
         (string= (concatenate 'string prefix "/art/100")
                  (build-eli-article-uri prefix 100)))
  (check "lettered article URI keeps the suffix"
         (string= (concatenate 'string prefix "/art/100Α")
                  (build-eli-article-uri prefix 100 "Α")))
  (check "full label also accepted"
         (string= (concatenate 'string prefix "/art/100Α")
                  (build-eli-article-uri prefix 100 "100Α")))
  (check "base and lettered ELI URIs are DISTINCT"
         (not (string= (build-eli-article-uri prefix 100)
                       (build-eli-article-uri prefix 100 "Α")))))

(format t "~%== FRBR Work stores the suffix (threads it everywhere downstream) ==~%")
;; NOTE: do not pass :article-root-uri — let the Work derive it from the prefix
;; (in production it comes suffix-safe from the Article Root), so the URI actually
;; exercises the suffix threading.
(let ((base (make-frbr-work :article-number 100 :article-suffix ""
                            :eli-prefix "https://stavropouloslaw.com/eli/gr/const/1975"
                            :document-type "const" :law-year "1975"
                            :issued-date "1975-06-11"))
      (lettered (make-frbr-work :article-number 100 :article-suffix "Α"
                                :eli-prefix "https://stavropouloslaw.com/eli/gr/const/1975"
                                :document-type "const" :law-year "1975"
                                :issued-date "1975-06-11")))
  (check "work stores the letter suffix"
         (string= "Α" (article-letter-suffix lettered)))
  (check "base work has empty suffix"
         (string= "" (article-letter-suffix base)))
  (check "base and lettered Work URIs are DISTINCT"
         (not (string= (resource-uri base) (resource-uri lettered))))
  (check "base and lettered Work eIds are DISTINCT"
         (not (string= (eli-identifier base) (eli-identifier lettered))))
  (check "the lettered Work URI actually contains the suffix"
         (search "100Α" (resource-uri lettered)))
  ;; the wikidata owl:sameAs refs the generators emit are built from exactly this
  (check "wikidata-style id from the work is suffix-safe"
         (not (string= (article-uri-id (article-number base)
                                       (article-letter-suffix base))
                       (article-uri-id (article-number lettered)
                                       (article-letter-suffix lettered))))))

(format t "~%== [0088 Φ6γ-Δ] identity ΑΠΟ ΤΗ ΓΕΝΝΗΣΗ + FRBR χωρίς raw else-branches ==~%")
(let ((a (make-instance 'article :number 5 :label "5Α")))
  (check "make-instance ΧΩΡΙΣ builder ⇒ typed segment υπολογισμένο στη γέννηση"
         (equal '(:article 5 1) (article-identity a)))
  (check "article-uri από το segment"  (string= "5Α" (article-uri a)))
  (check "article-file-id από το segment" (string= "005Α" (article-file-id a))))
(let ((debt (make-instance 'article :number 272005)))
  (check "συνθετικός >9999 χωρίς label ⇒ ΔΗΛΩΜΕΝΟ debt (NIL segment)"
         (null (article-identity debt)))
  (check "debt-προβολή: γυμνή βάση, χωρίς raw επανερμηνεία"
         (string= "272005" (article-uri debt))))
(let ((prefix "https://stavropouloslaw.com/eli/gr/const/1975"))
  (let ((w-raw (make-frbr-work :article-number 100 :article-suffix "Α"
                               :eli-prefix prefix :document-type "const"
                               :law-year "1975" :issued-date "1975-06-11"))
        (w-seg (make-frbr-work :article-number 100 :article-suffix "Α"
                               :identity-segment '(:article 100 1)
                               :eli-prefix prefix :document-type "const"
                               :law-year "1975" :issued-date "1975-06-11")))
    (check "FRBR Work: raw ζεύγος και ρητό segment ⇒ BYTE-IDENTICAL uri+eli-id"
           (and (string= (resource-uri w-raw) (resource-uri w-seg))
                (string= (eli-identifier w-raw) (eli-identifier w-seg)))))
  (check "FRBR Work: άκυρο label ⇒ typed σφάλμα (fail-closed, όχι σιωπηλό URI)"
         (handler-case
             (progn (make-frbr-work :article-number 5 :article-suffix "5 Α"
                                    :eli-prefix prefix :document-type "const"
                                    :law-year "1975" :issued-date "1975-06-11")
                    nil)
           (orchestrator.spec:validation-error () t)))
  (check "FRBR Article Root: raw ζεύγος περνά από την έδρα segment (uid «5Α»)"
         (let ((r (make-frbr-article-root :article-number 5 :article-suffix "Α"
                                          :article-title "T" :eli-prefix prefix
                                          :document-type "const" :law-year "1975"
                                          :issued-date "1975-06-11")))
           (search "/art/5Α" (resource-uri r)))))

(format t "~%== [0088 κριτής A1/A2/B4] μετάλλαξη number + golden strings ==~%")
(let ((a (make-instance 'article :number 5)))
  (setf (article-number a) 7)
  (check "A1: (setf article-number) ⇒ η ταυτότητα ΠΑΡΑΚΟΛΟΥΘΕΙ (uri «7», όχι «5»)"
         (and (equal '(:article 7 0) (article-identity a))
              (string= "7" (article-uri a)))))
(let ((a (make-instance 'article)))
  (setf (article-number a) 5)
  (check "A2: number δοσμένο ΜΕΤΑ τη γέννηση ⇒ segment υπολογίζεται (όχι μόνιμο NIL)"
         (equal '(:article 5 0) (article-identity a))))
(check "A2β: γέννηση με label «» ⇒ typed σφάλμα (δηλωμένο fail-closed, όχι σιωπηλό «005»)"
       (handler-case (progn (make-instance 'article :number 5 :label "") nil)
         (orchestrator.spec:validation-error () t)))
(let ((prefix "https://stavropouloslaw.com/eli/gr/const/1975"))
  (let ((w (make-frbr-work :article-number 100 :article-suffix "Α"
                           :eli-prefix prefix :document-type "const"
                           :law-year "1975" :issued-date "1975-06-11")))
    (check "B4: GOLDEN Work uri (προ-commit raw έξοδος, κλειδωμένη ως string)"
           (string= (resource-uri w)
                    "https://stavropouloslaw.com/eli/gr/const/1975/art/100Α/work"))
    (check "B4β: GOLDEN Work eli-id"
           (string= (eli-identifier w) "gr-const-1975-art-100Α-work")))
  (let ((r (make-frbr-article-root :article-number 5 :article-suffix "Α"
                                   :article-title "T" :eli-prefix prefix
                                   :document-type "const" :law-year "1975"
                                   :issued-date "1975-06-11")))
    (check "B4γ: GOLDEN Root uri"
           (string= (resource-uri r)
                    "https://stavropouloslaw.com/eli/gr/const/1975/art/5Α"))
    (check "B4δ: GOLDEN Root eli-id"
           (string= (eli-identifier r) "gr-const-1975-art-005Α"))))
(check "B1: segment-uri-id/segment-file-id = ΟΙ έδρες προβολής"
       (and (string= "5Α" (segment-uri-id '(:article 5 1)))
            (string= "005Α" (segment-file-id '(:article 5 1)))
            (string= "70" (segment-uri-id '(:article 70 0)))
            (string= "070" (segment-file-id '(:article 70 0)))))

(format t "~%== [0088 κριτής-δημιουργού #3/#4] clone invariants + πλήρης provision identity ==~%")
(let* ((a (make-article :number 5 :label "5Α" :title "T"))
       (c (clone-article a 'label "5Β")))
  (check "#3: clone override label ΜΕΣΩ accessor ⇒ identity επανυπολογισμένη (5Β)"
         (and (equal '(:article 5 2) (article-identity c))
              (string= "5Β" (article-uri c))))
  (check "#3β: clone override number ⇒ identity παρακολουθεί"
         (let ((n (clone-article (make-article :number 7) 'number 9)))
           (and (equal '(:article 9 0) (article-identity n))
                (string= "9" (article-uri n)))))
  (check "#3γ: clone override του ΠΑΡΑΓΩΓΟΥ identity-segment ⇒ typed σφάλμα"
         (handler-case (progn (clone-article a 'identity-segment '(:article 99 0)) nil)
           (orchestrator.spec:validation-error () t))))
(let ((syntagma (make-corpus :name "Σύνταγμα" :short-name "constitution"
                             :eli-prefix "https://stavropouloslaw.com/eli/gr/const/1975"))
      (pk (make-corpus :name "Ποινικός Κώδικας" :short-name "poinikos"
                       :eli-prefix "https://stavropouloslaw.com/eli/gr/l/pk"))
      (a5 (make-article :number 5)))
  (check "#4: legal-body-id default = eli-prefix (παγκοσμίως μοναδικό)"
         (string= (corpus-legal-body-id syntagma)
                  "https://stavropouloslaw.com/eli/gr/const/1975"))
  (check "#4β: ΙΔΙΟ άρθρο 5, ΑΛΛΟ σώμα ⇒ ΔΙΑΦΟΡΕΤΙΚΟ provision-id ΚΑΙ uri"
         (and (not (equal (provision-id syntagma a5) (provision-id pk a5)))
              (not (string= (provision-uri syntagma a5) (provision-uri pk a5)))))
  (check "#4γ: provision-uri = {eli-prefix}/art/{segment}"
         (string= "https://stavropouloslaw.com/eli/gr/const/1975/art/5"
                  (provision-uri syntagma a5)))
  (check "#4δ: provision-id για άρθρο χωρίς νόμιμη ταυτότητα ⇒ typed σφάλμα"
         (handler-case
             (progn (provision-id syntagma (make-instance 'article :number 272005)) nil)
           (orchestrator.spec:validation-error () t))))

(format t "~%========================================~%")
(format t "Article identity tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
